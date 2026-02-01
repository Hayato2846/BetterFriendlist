-- Utils/ClassicCompat.lua
-- Compatibility Layer for Classic Era and MoP Classic
-- Provides wrapper functions for APIs that differ between Retail and Classic
-- Version 1.0 - December 2025

local ADDON_NAME, BFL = ...

-- Create Compat namespace
BFL.Compat = {}
local Compat = BFL.Compat

------------------------------------------------------------
-- C_AddOns Compatibility
------------------------------------------------------------
-- Retail 11.0+: C_AddOns.GetAddOnMetadata(addon, field)
-- Classic: GetAddOnMetadata(addon, field) (global function)

function Compat.GetAddOnMetadata(addon, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addon, field)
    elseif GetAddOnMetadata then
        return GetAddOnMetadata(addon, field)
    end
    return nil
end

function Compat.GetAddOnInfo(addon)
    if C_AddOns and C_AddOns.GetAddOnInfo then
        return C_AddOns.GetAddOnInfo(addon)
    elseif GetAddOnInfo then
        return GetAddOnInfo(addon)
    end
    return nil
end

------------------------------------------------------------
-- Menu System Compatibility
------------------------------------------------------------
-- Retail 11.0+: MenuUtil.CreateContextMenu, Menu.ModifyMenu
-- Classic: UIDropDownMenu API (EasyMenu, ToggleDropDownMenu)

-- Internal dropdown counter for unique naming
local dropdownCounter = 1

-- Create a context menu (right-click menus)
-- @param owner: Frame that owns the menu
-- @param menuGenerator: Function that returns menu items
--   For Retail: Standard MenuUtil generator function
--   For Classic: Should return a table in EasyMenu format
function Compat.CreateContextMenu(owner, menuGenerator)
    if MenuUtil and MenuUtil.CreateContextMenu then
        -- Retail: Modern Menu API
        MenuUtil.CreateContextMenu(owner, menuGenerator)
    else
        -- Classic: UIDropDownMenu fallback
        local menuFrame = CreateFrame("Frame", "BFLContextMenu" .. dropdownCounter, UIParent, "UIDropDownMenuTemplate")
        dropdownCounter = dropdownCounter + 1
        
        -- menuGenerator should return EasyMenu-compatible table for Classic
        local menuTable = menuGenerator()
        if menuTable then
            EasyMenu(menuTable, menuFrame, owner or "cursor", 0, 0, "MENU")
        end
    end
end

-- Hook into UnitPopup menus
-- @param tag: Menu tag (e.g., "FRIEND", "BN_FRIEND")
-- @param callback: Function to call when menu opens
function Compat.ModifyMenu(tag, callback)
    if Menu and Menu.ModifyMenu then
        -- Retail: Direct hook
        Menu.ModifyMenu(tag, callback)
    else
        -- Classic: No direct equivalent
        -- Must use hooksecurefunc on specific functions
        -- This is handled per-case in individual modules
        -- BFL:DebugPrint("|cffffcc00BFL Compat:|r Menu.ModifyMenu not available in Classic")
    end
end

-- Convert Retail menu generator to Classic EasyMenu format
-- Helper for modules that need to support both
function Compat.CreateEasyMenuTable(items)
    local menuTable = {}
    for _, item in ipairs(items) do
        local menuItem = {
            text = item.text or item.label,
            isTitle = item.isTitle,
            notCheckable = not item.isCheckable,
            checked = item.checked,
            func = item.onClick or item.func,
            disabled = item.disabled,
            hasArrow = item.hasArrow,
            menuList = item.menuList,
        }
        table.insert(menuTable, menuItem)
    end
    -- Add cancel button
    table.insert(menuTable, { text = CANCEL, notCheckable = true })
    return menuTable
end

------------------------------------------------------------
-- UnitPopup Compatibility
------------------------------------------------------------
-- Retail 11.0+: UnitPopup_OpenMenu(menuType, contextData)
-- Classic: UnitPopup_ShowMenu(dropdown, which, unit, name, userData)

function Compat.OpenUnitPopupMenu(menuType, contextData)
    -- Streamer Mode Interception for Context Menu Header (Added 2026-02-01)
    if BFL.StreamerMode and BFL.StreamerMode:IsActive() and contextData then
        local FriendsList = BFL:GetModule("FriendsList")
        if FriendsList and FriendsList.friendsList then
            local friend = nil
            
            -- 1. Try BNet ID (Most reliable for BNet)
            if contextData.bnetIDAccount then
                for _, f in ipairs(FriendsList.friendsList) do
                    if f.type == "bnet" and f.bnetAccountID == contextData.bnetIDAccount then
                        friend = f
                        break
                    end
                end
            end
            
            -- 2. Try Friend Index (Most reliable for WoW)
            -- contextData.friendsList is the index for WoW friends in UnitPopup (confusing name by Blizz)
            if not friend and contextData.friendsList and type(contextData.friendsList) == "number" then
                 for _, f in ipairs(FriendsList.friendsList) do
                    if f.type == "wow" and f.index == contextData.friendsList then
                        friend = f
                        break
                    end
                end
            end

            -- 3. Try GUID (WoW fallback)
            if not friend and contextData.guid then
                for _, f in ipairs(FriendsList.friendsList) do
                    if f.type == "wow" and f.guid == contextData.guid then
                        friend = f
                        break
                    end
                end
            end
            
            -- 4. Try Name (Last resort fallback)
            if not friend and contextData.name then
                for _, f in ipairs(FriendsList.friendsList) do
                    if f.type == "wow" and (f.name == contextData.name or f.characterName == contextData.name) then
                         friend = f
                         break
                    end
                end
            end

            if friend then
                -- Get the safe masked name (Nickname or Note or BattleTag)
                local safeName = FriendsList:GetDisplayName(friend)
                if safeName and safeName ~= "" then
                    contextData.name = safeName
                end
            end
        end
    end

    if UnitPopup_OpenMenu then
        -- Retail: Modern API
        UnitPopup_OpenMenu(menuType, contextData)
    else
        -- Classic: Legacy API with dropdown frame
        local dropdown = _G["BFLUnitPopupDropdown"]
        if not dropdown then
            dropdown = CreateFrame("Frame", "BFLUnitPopupDropdown", UIParent, "UIDropDownMenuTemplate")
        end
        
        local name = contextData.name or ""
        local unit = contextData.unit
        
        -- UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
        if UnitPopup_ShowMenu then
            UnitPopup_ShowMenu(dropdown, menuType, unit, name, contextData)
        end
    end
end

------------------------------------------------------------
-- Dropdown Compatibility
------------------------------------------------------------
-- Retail 11.0+: WowStyle1DropdownTemplate with :SetupMenu()
-- Classic: UIDropDownMenuTemplate with UIDropDownMenu_Initialize()

-- Create a dropdown menu frame
-- @param parent: Parent frame
-- @param name: Unique name for the dropdown
-- @param width: Dropdown width
-- @return dropdown frame
function Compat.CreateDropdown(parent, name, width)
    width = width or 150
    
    if BFL.HasModernDropdown then
        -- Retail: Modern dropdown
        local dropdown = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(width)
        return dropdown
    else
        -- Classic: UIDropDownMenu
        local dropdown = CreateFrame("Frame", name or ("BFLDropdown" .. dropdownCounter), parent, "UIDropDownMenuTemplate")
        dropdownCounter = dropdownCounter + 1
        UIDropDownMenu_SetWidth(dropdown, width)
        return dropdown
    end
end

-- Initialize dropdown with options
-- @param dropdown: The dropdown frame
-- @param options: Table with { labels = {...}, values = {...} }
-- @param getter: Function(value) -> boolean (is this value selected?)
-- @param setter: Function(value) called when selection changes
function Compat.InitializeDropdown(dropdown, options, getter, setter)
    if BFL.HasModernDropdown and dropdown.SetupMenu then
        -- Retail: Modern API
        dropdown:SetupMenu(function(dropdown, rootDescription)
            for i, label in ipairs(options.labels) do
                local value = options.values[i]
                rootDescription:CreateRadio(label, getter, setter, value)
            end
        end)
    else
        -- Classic: UIDropDownMenu
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            level = level or 1
            for i, label in ipairs(options.labels) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = label
                info.value = options.values[i]
                info.checked = getter(options.values[i])
                info.func = function(self)
                    setter(self.value)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        
        -- Set initial selection
        for i, value in ipairs(options.values) do
            if getter(value) then
                UIDropDownMenu_SetSelectedValue(dropdown, value)
                UIDropDownMenu_SetText(dropdown, options.labels[i])
                break
            end
        end
    end
end

------------------------------------------------------------
-- ColorPicker Compatibility
------------------------------------------------------------
-- Retail 10.1+: ColorPickerFrame:SetupColorPickerAndShow(info)
-- Classic: ColorPickerFrame.func = ..., ColorPickerFrame:Show()

function Compat.ShowColorPicker(r, g, b, a, callback, cancelCallback)
    if BFL.HasModernColorPicker and ColorPickerFrame.SetupColorPickerAndShow then
        -- Retail: Modern API
        local info = {
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                callback(newR, newG, newB, newA)
            end,
            cancelFunc = function()
                if cancelCallback then
                    cancelCallback(r, g, b, a)
                end
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                callback(newR, newG, newB, newA)
            end,
            r = r,
            g = g,
            b = b,
            opacity = a,
            hasOpacity = (a ~= nil),
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        -- Classic: Legacy API
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            callback(newR, newG, newB, a)
        end
        ColorPickerFrame.cancelFunc = function()
            if cancelCallback then
                cancelCallback(r, g, b, a)
            end
        end
        ColorPickerFrame.hasOpacity = (a ~= nil)
        if a then
            ColorPickerFrame.opacity = 1 - a  -- Classic uses inverted opacity
            ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
        ColorPickerFrame:Show()
    end
end

------------------------------------------------------------
-- C_BattleNet Compatibility
------------------------------------------------------------
-- GOOD NEWS: C_BattleNet.GetFriendAccountInfo etc. exists in ALL versions!
-- But return value structures may differ slightly

-- Get BNet friend info with consistent return format
-- @param friendIndex: 1-based friend index
-- @return accountInfo table (Retail format)
function Compat.GetBNetFriendInfo(friendIndex)
    if C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        -- Modern API (available in Retail AND Classic)
        return C_BattleNet.GetFriendAccountInfo(friendIndex)
    elseif BNGetFriendInfo then
        -- Legacy Classic API (fallback, rarely needed)
        local presenceID, presenceName, battleTag, isBattleTagPresence, 
              toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, 
              messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo(friendIndex)
        
        -- Convert to Retail-style table
        return {
            bnetAccountID = presenceID,
            accountName = presenceName,
            battleTag = battleTag,
            isBattleTagFriend = isBattleTagPresence,
            gameAccountInfo = {
                characterName = toonName,
                gameAccountID = toonID,
                clientProgram = client,
                isOnline = isOnline,
            },
            lastOnlineTime = lastOnline,
            isAFK = isAFK,
            isDND = isDND,
            customMessage = messageText,
            note = noteText,
        }
    end
    return nil
end

-- Get game account info for a BNet friend
function Compat.GetBNetFriendGameAccountInfo(friendIndex, gameAccountIndex)
    if C_BattleNet and C_BattleNet.GetFriendGameAccountInfo then
        return C_BattleNet.GetFriendGameAccountInfo(friendIndex, gameAccountIndex)
    elseif BNGetFriendGameAccountInfo then
        -- Legacy API
        local hasFocus, characterName, client, realmName, realmID, faction, race, class, 
              guild, zoneName, level, gameText, broadcastText, broadcastTime, isOnline,
              gameAccountID, bnetAccountID, isGameAFK, isGameBusy, playerGuid, wowProjectID, 
              isWowMobile, canSoR, characterDisplayName, displayNameOverride = BNGetFriendGameAccountInfo(friendIndex, gameAccountIndex)
        
        return {
            hasFocus = hasFocus,
            characterName = characterName,
            clientProgram = client,
            realmName = realmName,
            realmID = realmID,
            factionName = faction,
            raceName = race,
            className = class,
            guildName = guild,
            areaName = zoneName,
            characterLevel = level,
            richPresence = gameText,
            isOnline = isOnline,
            gameAccountID = gameAccountID,
            bnetAccountID = bnetAccountID,
            isGameAFK = isGameAFK,
            isGameBusy = isGameBusy,
            playerGuid = playerGuid,
            wowProjectID = wowProjectID,
            isWowMobile = isWowMobile,
        }
    end
    return nil
end

------------------------------------------------------------
-- C_RecentAllies Compatibility (TWW-only!)
------------------------------------------------------------
-- This API exists ONLY in TWW (11.0.7+)
-- In Classic/MoP: Return empty/disabled

function Compat.IsRecentAlliesAvailable()
    return C_RecentAllies ~= nil and C_RecentAllies.IsSystemEnabled ~= nil
end

function Compat.IsRecentAlliesSystemEnabled()
    if Compat.IsRecentAlliesAvailable() then
        return C_RecentAllies.IsSystemEnabled()
    end
    return false
end

function Compat.GetRecentAllies()
    if Compat.IsRecentAlliesAvailable() and C_RecentAllies.GetRecentAllies then
        return C_RecentAllies.GetRecentAllies()
    end
    return {} -- Empty in Classic
end

function Compat.IsRecentAllyDataReady()
    if Compat.IsRecentAlliesAvailable() and C_RecentAllies.IsRecentAllyDataReady then
        return C_RecentAllies.IsRecentAllyDataReady()
    end
    return true -- Return true so we don't show loading spinner forever
end

------------------------------------------------------------
-- ScrollBox Compatibility Helpers
------------------------------------------------------------
-- Retail 10.0+: ScrollBox, CreateScrollBoxListLinearView, ScrollUtil
-- Classic: FauxScrollFrame, HybridScrollFrame
--
-- NOTE: Full ScrollBox abstraction is complex and handled in individual modules
-- These are helper utilities

function Compat.HasModernScrollBox()
    return CreateScrollBoxListLinearView ~= nil and ScrollUtil ~= nil
end

-- Create button pool for Classic scroll frames
-- @param parent: Parent scroll frame
-- @param templateName: Button template name
-- @param numButtons: Number of buttons to create
-- @param buttonHeight: Height of each button
-- @return table of button frames
function Compat.CreateButtonPool(parent, templateName, numButtons, buttonHeight)
    local pool = {}
    for i = 1, numButtons do
        local button = CreateFrame("Button", parent:GetName() .. "Button" .. i, parent, templateName)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((i - 1) * buttonHeight))
        button:SetHeight(buttonHeight)
        button.index = i
        pool[i] = button
    end
    return pool
end

-- Update FauxScrollFrame display
-- @param scrollFrame: The FauxScrollFrame
-- @param numItems: Total number of items
-- @param buttonPool: Table of button frames
-- @param buttonHeight: Height of each button
-- @param updateFunc: Function(button, dataIndex, data) to update button display
-- @param dataList: List of data items
function Compat.UpdateFauxScrollFrame(scrollFrame, numItems, buttonPool, buttonHeight, updateFunc, dataList)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    local numButtons = #buttonPool
    
    FauxScrollFrame_Update(scrollFrame, numItems, numButtons, buttonHeight)
    
    for i, button in ipairs(buttonPool) do
        local dataIndex = offset + i
        if dataIndex <= numItems then
            local data = dataList[dataIndex]
            updateFunc(button, dataIndex, data)
            button:Show()
        else
            button:Hide()
        end
    end
end

------------------------------------------------------------
-- Atlas/Texture Compatibility
------------------------------------------------------------
-- Many modern atlases don't exist in Classic
-- Provide fallback textures

local ATLAS_FALLBACKS = {
    -- Travel Pass / Invite Button
    ["friendslist-invitebutton-default-normal"] = "Interface\\FriendsFrame\\TravelPass-Invite",
    ["friendslist-invitebutton-default-pressed"] = "Interface\\FriendsFrame\\TravelPass-Invite",
    ["friendslist-invitebutton-default-disabled"] = "Interface\\FriendsFrame\\TravelPass-Invite",
    ["friendslist-invitebutton-highlight"] = "Interface\\FriendsFrame\\TravelPass-Invite",
    
    -- Group Header Arrows
    ["friendslist-categorybutton-arrow-right"] = "Interface\\Buttons\\UI-PlusButton-Up",
    ["friendslist-categorybutton-arrow-down"] = "Interface\\Buttons\\UI-MinusButton-Up",
    
    -- Recent Allies Pin (not available in Classic anyway)
    ["friendslist-recentallies-pin"] = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon",
    ["friendslist-recentallies-pin-yellow"] = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon",
    
    -- Clock icon
    ["icon-clock"] = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    
    -- Recruit-a-Friend
    ["recruitafriend_friendslist_v3_icon"] = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
}

-- Set texture with atlas fallback support
-- @param texture: Texture object
-- @param atlasName: Atlas name to try
-- @param fallbackFile: Optional explicit fallback file path
function Compat.SetTextureOrAtlas(texture, atlasName, fallbackFile)
    if not texture then return end
    
    if BFL.IsRetail and texture.SetAtlas then
        -- Retail: Try atlas first
        local success = pcall(function()
            texture:SetAtlas(atlasName)
        end)
        if success then return end
    end
    
    -- Classic or atlas failed: Use fallback
    local fallback = fallbackFile or ATLAS_FALLBACKS[atlasName]
    if fallback then
        texture:SetTexture(fallback)
    else
        -- Last resort: try as direct texture path
        texture:SetTexture(atlasName)
    end
end

------------------------------------------------------------
-- Frame Template Compatibility
------------------------------------------------------------
-- Some templates have different names or don't exist in Classic

local TEMPLATE_MAPPINGS = {
    -- Retail Template -> Classic Equivalent
    ["WowStyle1DropdownTemplate"] = "UIDropDownMenuTemplate",
    ["WowScrollBoxList"] = nil, -- No direct equivalent, needs manual handling
    ["MinimalScrollBar"] = nil, -- Use FauxScrollFrame instead
    ["SpinnerTemplate"] = nil, -- Create manually
    ["DialogBorderOpaqueTemplate"] = "DialogBorderTemplate",
    ["PanelTopTabButtonTemplate"] = "CharacterFrameTabButtonTemplate",
    ["SquareIconButtonTemplate"] = "UIPanelSquareButton",
}

-- Get the appropriate template name for the current game version
function Compat.GetTemplateName(retailTemplate)
    if BFL.IsRetail then
        return retailTemplate
    end
    return TEMPLATE_MAPPINGS[retailTemplate] or retailTemplate
end

-- Check if a template exists
function Compat.TemplateExists(templateName)
    -- This is a rough check - some templates may exist but not be detected
    return _G[templateName] ~= nil or 
           (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(templateName) ~= nil)
end

------------------------------------------------------------
-- Event Compatibility
------------------------------------------------------------
-- Some events only exist in certain versions

local RETAIL_ONLY_EVENTS = {
    "RECENT_ALLIES_CACHE_UPDATE",
    -- Add more as discovered
}

local CLASSIC_ONLY_EVENTS = {
    -- Add any Classic-only events here
}

-- Check if an event exists in the current game version
function Compat.EventExists(eventName)
    -- Events in the retail-only list
    for _, event in ipairs(RETAIL_ONLY_EVENTS) do
        if event == eventName then
            return BFL.IsRetail
        end
    end
    
    -- Events in the classic-only list
    for _, event in ipairs(CLASSIC_ONLY_EVENTS) do
        if event == eventName then
            return BFL.IsClassic
        end
    end
    
    -- Assume event exists in all versions
    return true
end

-- Safe event registration
function Compat.RegisterEvent(frame, eventName)
    if Compat.EventExists(eventName) then
        frame:RegisterEvent(eventName)
        return true
    end
    return false
end

------------------------------------------------------------
-- Debug / Info Commands
------------------------------------------------------------

-- Print Classic compatibility info
function Compat.PrintInfo()
    BFL:DebugPrint(BFL.L.CORE_CLASSIC_COMPAT_HEADER)
    BFL:DebugPrint(string.format("TOC Version: |cffffffff%d|r", BFL.TOCVersion))
    BFL:DebugPrint("")
    BFL:DebugPrint(BFL.L.COMPAT_GAME_VERSION)
    BFL:DebugPrint(string.format("  Is Classic Era: %s", BFL.IsClassicEra and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Is MoP Classic: %s", BFL.IsMoPClassic and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Is Retail: %s", BFL.IsRetail and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Is TWW: %s", BFL.IsTWW and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint("")
    BFL:DebugPrint(BFL.L.CORE_FEATURE_AVAILABILITY)
    BFL:DebugPrint(string.format("  Modern ScrollBox: %s", BFL.HasModernScrollBox and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Modern Menu API: %s", BFL.HasModernMenu and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Modern Dropdown: %s", BFL.HasModernDropdown and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Recent Allies: %s", BFL.HasRecentAllies and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Edit Mode: %s", BFL.HasEditMode and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    BFL:DebugPrint(string.format("  Modern ColorPicker: %s", BFL.HasModernColorPicker and "|cff00ff00Yes|r" or "|cffff0000No|r"))
end

-- Register slash command for classic info
SLASH_BFLCOMPAT1 = "/bflcompat"
SlashCmdList["BFLCOMPAT"] = function(msg)
    Compat.PrintInfo()
end

------------------------------------------------------------
-- Global Aliases for Convenience
------------------------------------------------------------
-- These aliases allow direct access via BFL.FunctionName instead of BFL.Compat.FunctionName

-- Context Menu (UnitPopup) - Used by many modules
BFL.OpenContextMenu = function(button, menuType, contextData, name)
    Compat.OpenUnitPopupMenu(menuType, contextData)
end

-- Dropdown Creation
BFL.CreateDropdown = Compat.CreateDropdown
BFL.InitializeDropdown = Compat.InitializeDropdown

-- ColorPicker
BFL.ShowColorPicker = Compat.ShowColorPicker
