--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua"); -- Utils/ClassicCompat.lua
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

function Compat.GetAddOnMetadata(addon, field) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetAddOnMetadata file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:18:0");
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetAddOnMetadata file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:18:0", C_AddOns.GetAddOnMetadata(addon, field))
    elseif GetAddOnMetadata then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetAddOnMetadata file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:18:0", GetAddOnMetadata(addon, field))
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.GetAddOnMetadata file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:18:0"); return nil
end

function Compat.GetAddOnInfo(addon) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetAddOnInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:27:0");
    if C_AddOns and C_AddOns.GetAddOnInfo then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetAddOnInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:27:0", C_AddOns.GetAddOnInfo(addon))
    elseif GetAddOnInfo then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetAddOnInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:27:0", GetAddOnInfo(addon))
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.GetAddOnInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:27:0"); return nil
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
function Compat.CreateContextMenu(owner, menuGenerator) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.CreateContextMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:50:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateContextMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:50:0"); end

-- Hook into UnitPopup menus
-- @param tag: Menu tag (e.g., "FRIEND", "BN_FRIEND")
-- @param callback: Function to call when menu opens
function Compat.ModifyMenu(tag, callback) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.ModifyMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:70:0");
    if Menu and Menu.ModifyMenu then
        -- Retail: Direct hook
        Menu.ModifyMenu(tag, callback)
    else
        -- Classic: No direct equivalent
        -- Must use hooksecurefunc on specific functions
        -- This is handled per-case in individual modules
        -- BFL:DebugPrint("|cffffcc00BFL Compat:|r Menu.ModifyMenu not available in Classic")
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.ModifyMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:70:0"); end

-- Convert Retail menu generator to Classic EasyMenu format
-- Helper for modules that need to support both
function Compat.CreateEasyMenuTable(items) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.CreateEasyMenuTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:84:0");
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
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateEasyMenuTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:84:0"); return menuTable
end

------------------------------------------------------------
-- UnitPopup Compatibility
------------------------------------------------------------
-- Retail 11.0+: UnitPopup_OpenMenu(menuType, contextData)
-- Classic: UnitPopup_ShowMenu(dropdown, which, unit, name, userData)

function Compat.OpenUnitPopupMenu(menuType, contextData) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.OpenUnitPopupMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:110:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.OpenUnitPopupMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:110:0"); end

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
function Compat.CreateDropdown(parent, name, width) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:142:0");
    width = width or 150
    
    if BFL.HasModernDropdown then
        -- Retail: Modern dropdown
        local dropdown = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(width)
        Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:142:0"); return dropdown
    else
        -- Classic: UIDropDownMenu
        local dropdown = CreateFrame("Frame", name or ("BFLDropdown" .. dropdownCounter), parent, "UIDropDownMenuTemplate")
        dropdownCounter = dropdownCounter + 1
        UIDropDownMenu_SetWidth(dropdown, width)
        Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:142:0"); return dropdown
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:142:0"); end

-- Initialize dropdown with options
-- @param dropdown: The dropdown frame
-- @param options: Table with { labels = {...}, values = {...} }
-- @param getter: Function(value) -> boolean (is this value selected?)
-- @param setter: Function(value) called when selection changes
function Compat.InitializeDropdown(dropdown, options, getter, setter) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.InitializeDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:164:0");
    if BFL.HasModernDropdown and dropdown.SetupMenu then
        -- Retail: Modern API
        dropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:167:27");
            for i, label in ipairs(options.labels) do
                local value = options.values[i]
                rootDescription:CreateRadio(label, getter, setter, value)
            end
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:167:27"); end)
    else
        -- Classic: UIDropDownMenu
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:175:44");
            level = level or 1
            for i, label in ipairs(options.labels) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = label
                info.value = options.values[i]
                info.checked = getter(options.values[i])
                info.func = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:182:28");
                    setter(self.value)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    CloseDropDownMenus()
                Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:182:28"); end
                UIDropDownMenu_AddButton(info, level)
            end
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:175:44"); end)
        
        -- Set initial selection
        for i, value in ipairs(options.values) do
            if getter(value) then
                UIDropDownMenu_SetSelectedValue(dropdown, value)
                UIDropDownMenu_SetText(dropdown, options.labels[i])
                break
            end
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.InitializeDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:164:0"); end

------------------------------------------------------------
-- ColorPicker Compatibility
------------------------------------------------------------
-- Retail 10.1+: ColorPickerFrame:SetupColorPickerAndShow(info)
-- Classic: ColorPickerFrame.func = ..., ColorPickerFrame:Show()

function Compat.ShowColorPicker(r, g, b, a, callback, cancelCallback) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.ShowColorPicker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:208:0");
    if BFL.HasModernColorPicker and ColorPickerFrame.SetupColorPickerAndShow then
        -- Retail: Modern API
        local info = {
            swatchFunc = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.swatchFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:212:25");
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                callback(newR, newG, newB, newA)
            Perfy_Trace(Perfy_GetTime(), "Leave", "info.swatchFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:212:25"); end,
            cancelFunc = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.cancelFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:217:25");
                if cancelCallback then
                    cancelCallback(r, g, b, a)
                end
            Perfy_Trace(Perfy_GetTime(), "Leave", "info.cancelFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:217:25"); end,
            opacityFunc = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.opacityFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:222:26");
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                callback(newR, newG, newB, newA)
            Perfy_Trace(Perfy_GetTime(), "Leave", "info.opacityFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:222:26"); end,
            r = r,
            g = g,
            b = b,
            opacity = a,
            hasOpacity = (a ~= nil),
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        -- Classic: Legacy API
        ColorPickerFrame.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "ColorPickerFrame.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:236:32");
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            callback(newR, newG, newB, a)
        Perfy_Trace(Perfy_GetTime(), "Leave", "ColorPickerFrame.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:236:32"); end
        ColorPickerFrame.cancelFunc = function() Perfy_Trace(Perfy_GetTime(), "Enter", "ColorPickerFrame.cancelFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:240:38");
            if cancelCallback then
                cancelCallback(r, g, b, a)
            end
        Perfy_Trace(Perfy_GetTime(), "Leave", "ColorPickerFrame.cancelFunc file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:240:38"); end
        ColorPickerFrame.hasOpacity = (a ~= nil)
        if a then
            ColorPickerFrame.opacity = 1 - a  -- Classic uses inverted opacity
            ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
        ColorPickerFrame:Show()
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.ShowColorPicker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:208:0"); end

------------------------------------------------------------
-- C_BattleNet Compatibility
------------------------------------------------------------
-- GOOD NEWS: C_BattleNet.GetFriendAccountInfo etc. exists in ALL versions!
-- But return value structures may differ slightly

-- Get BNet friend info with consistent return format
-- @param friendIndex: 1-based friend index
-- @return accountInfo table (Retail format)
function Compat.GetBNetFriendInfo(friendIndex) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetBNetFriendInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:265:0");
    if C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        -- Modern API (available in Retail AND Classic)
        return Perfy_Trace_Passthrough("Leave", "Compat.GetBNetFriendInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:265:0", C_BattleNet.GetFriendAccountInfo(friendIndex))
    elseif BNGetFriendInfo then
        -- Legacy Classic API (fallback, rarely needed)
        local presenceID, presenceName, battleTag, isBattleTagPresence, 
              toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, 
              messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo(friendIndex)
        
        -- Convert to Retail-style table
        return Perfy_Trace_Passthrough("Leave", "Compat.GetBNetFriendInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:265:0", {
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
        })
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.GetBNetFriendInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:265:0"); return nil
end

-- Get game account info for a BNet friend
function Compat.GetBNetFriendGameAccountInfo(friendIndex, gameAccountIndex) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetBNetFriendGameAccountInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:298:0");
    if C_BattleNet and C_BattleNet.GetFriendGameAccountInfo then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetBNetFriendGameAccountInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:298:0", C_BattleNet.GetFriendGameAccountInfo(friendIndex, gameAccountIndex))
    elseif BNGetFriendGameAccountInfo then
        -- Legacy API
        local hasFocus, characterName, client, realmName, realmID, faction, race, class, 
              guild, zoneName, level, gameText, broadcastText, broadcastTime, isOnline,
              gameAccountID, bnetAccountID, isGameAFK, isGameBusy, playerGuid, wowProjectID, 
              isWowMobile, canSoR, characterDisplayName, displayNameOverride = BNGetFriendGameAccountInfo(friendIndex, gameAccountIndex)
        
        return Perfy_Trace_Passthrough("Leave", "Compat.GetBNetFriendGameAccountInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:298:0", {
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
        })
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.GetBNetFriendGameAccountInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:298:0"); return nil
end

------------------------------------------------------------
-- C_RecentAllies Compatibility (TWW-only!)
------------------------------------------------------------
-- This API exists ONLY in TWW (11.0.7+)
-- In Classic/MoP: Return empty/disabled

function Compat.IsRecentAlliesAvailable() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.IsRecentAlliesAvailable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:340:0");
    return Perfy_Trace_Passthrough("Leave", "Compat.IsRecentAlliesAvailable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:340:0", C_RecentAllies ~= nil and C_RecentAllies.IsSystemEnabled ~= nil)
end

function Compat.IsRecentAlliesSystemEnabled() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.IsRecentAlliesSystemEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:344:0");
    if Compat.IsRecentAlliesAvailable() then
        return Perfy_Trace_Passthrough("Leave", "Compat.IsRecentAlliesSystemEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:344:0", C_RecentAllies.IsSystemEnabled())
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.IsRecentAlliesSystemEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:344:0"); return false
end

function Compat.GetRecentAllies() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetRecentAllies file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:351:0");
    if Compat.IsRecentAlliesAvailable() and C_RecentAllies.GetRecentAllies then
        return Perfy_Trace_Passthrough("Leave", "Compat.GetRecentAllies file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:351:0", C_RecentAllies.GetRecentAllies())
    end
    return Perfy_Trace_Passthrough("Leave", "Compat.GetRecentAllies file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:351:0", {}) -- Empty in Classic
end

function Compat.IsRecentAllyDataReady() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.IsRecentAllyDataReady file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:358:0");
    if Compat.IsRecentAlliesAvailable() and C_RecentAllies.IsRecentAllyDataReady then
        return Perfy_Trace_Passthrough("Leave", "Compat.IsRecentAllyDataReady file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:358:0", C_RecentAllies.IsRecentAllyDataReady())
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.IsRecentAllyDataReady file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:358:0"); return true -- Return true so we don't show loading spinner forever
end

------------------------------------------------------------
-- ScrollBox Compatibility Helpers
------------------------------------------------------------
-- Retail 10.0+: ScrollBox, CreateScrollBoxListLinearView, ScrollUtil
-- Classic: FauxScrollFrame, HybridScrollFrame
--
-- NOTE: Full ScrollBox abstraction is complex and handled in individual modules
-- These are helper utilities

function Compat.HasModernScrollBox() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.HasModernScrollBox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:374:0");
    return Perfy_Trace_Passthrough("Leave", "Compat.HasModernScrollBox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:374:0", CreateScrollBoxListLinearView ~= nil and ScrollUtil ~= nil)
end

-- Create button pool for Classic scroll frames
-- @param parent: Parent scroll frame
-- @param templateName: Button template name
-- @param numButtons: Number of buttons to create
-- @param buttonHeight: Height of each button
-- @return table of button frames
function Compat.CreateButtonPool(parent, templateName, numButtons, buttonHeight) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.CreateButtonPool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:384:0");
    local pool = {}
    for i = 1, numButtons do
        local button = CreateFrame("Button", parent:GetName() .. "Button" .. i, parent, templateName)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((i - 1) * buttonHeight))
        button:SetHeight(buttonHeight)
        button.index = i
        pool[i] = button
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.CreateButtonPool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:384:0"); return pool
end

-- Update FauxScrollFrame display
-- @param scrollFrame: The FauxScrollFrame
-- @param numItems: Total number of items
-- @param buttonPool: Table of button frames
-- @param buttonHeight: Height of each button
-- @param updateFunc: Function(button, dataIndex, data) to update button display
-- @param dataList: List of data items
function Compat.UpdateFauxScrollFrame(scrollFrame, numItems, buttonPool, buttonHeight, updateFunc, dataList) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.UpdateFauxScrollFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:403:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.UpdateFauxScrollFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:403:0"); end

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
function Compat.SetTextureOrAtlas(texture, atlasName, fallbackFile) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.SetTextureOrAtlas file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:453:0");
    if not texture then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.SetTextureOrAtlas file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:453:0"); return end
    
    if BFL.IsRetail and texture.SetAtlas then
        -- Retail: Try atlas first
        local success = pcall(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:458:30");
            texture:SetAtlas(atlasName)
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:458:30"); end)
        if success then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.SetTextureOrAtlas file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:453:0"); return end
    end
    
    -- Classic or atlas failed: Use fallback
    local fallback = fallbackFile or ATLAS_FALLBACKS[atlasName]
    if fallback then
        texture:SetTexture(fallback)
    else
        -- Last resort: try as direct texture path
        texture:SetTexture(atlasName)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.SetTextureOrAtlas file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:453:0"); end

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
function Compat.GetTemplateName(retailTemplate) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.GetTemplateName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:491:0");
    if BFL.IsRetail then
        Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.GetTemplateName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:491:0"); return retailTemplate
    end
    return Perfy_Trace_Passthrough("Leave", "Compat.GetTemplateName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:491:0", TEMPLATE_MAPPINGS[retailTemplate] or retailTemplate)
end

-- Check if a template exists
function Compat.TemplateExists(templateName) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.TemplateExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:499:0");
    -- This is a rough check - some templates may exist but not be detected
    return Perfy_Trace_Passthrough("Leave", "Compat.TemplateExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:499:0", _G[templateName] ~= nil or 
           (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(templateName) ~= nil))
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
function Compat.EventExists(eventName) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.EventExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:520:0");
    -- Events in the retail-only list
    for _, event in ipairs(RETAIL_ONLY_EVENTS) do
        if event == eventName then
            return Perfy_Trace_Passthrough("Leave", "Compat.EventExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:520:0", BFL.IsRetail)
        end
    end
    
    -- Events in the classic-only list
    for _, event in ipairs(CLASSIC_ONLY_EVENTS) do
        if event == eventName then
            return Perfy_Trace_Passthrough("Leave", "Compat.EventExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:520:0", BFL.IsClassic)
        end
    end
    
    -- Assume event exists in all versions
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.EventExists file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:520:0"); return true
end

-- Safe event registration
function Compat.RegisterEvent(frame, eventName) Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.RegisterEvent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:540:0");
    if Compat.EventExists(eventName) then
        frame:RegisterEvent(eventName)
        Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.RegisterEvent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:540:0"); return true
    end
    Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.RegisterEvent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:540:0"); return false
end

------------------------------------------------------------
-- Debug / Info Commands
------------------------------------------------------------

-- Print Classic compatibility info
function Compat.PrintInfo() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat.PrintInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:553:0");
    print(BFL.L.CORE_CLASSIC_COMPAT_HEADER)
    print(string.format("TOC Version: |cffffffff%d|r", BFL.TOCVersion))
    print("")
    print(BFL.L.COMPAT_GAME_VERSION)
    print(string.format("  Is Classic Era: %s", BFL.IsClassicEra and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Is MoP Classic: %s", BFL.IsMoPClassic and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Is Retail: %s", BFL.IsRetail and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Is TWW: %s", BFL.IsTWW and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print("")
    print(BFL.L.CORE_FEATURE_AVAILABILITY)
    print(string.format("  Modern ScrollBox: %s", BFL.HasModernScrollBox and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Modern Menu API: %s", BFL.HasModernMenu and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Modern Dropdown: %s", BFL.HasModernDropdown and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Recent Allies: %s", BFL.HasRecentAllies and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Edit Mode: %s", BFL.HasEditMode and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    print(string.format("  Modern ColorPicker: %s", BFL.HasModernColorPicker and "|cff00ff00Yes|r" or "|cffff0000No|r"))
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat.PrintInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:553:0"); end

-- Register slash command for classic info
SLASH_BFLCOMPAT1 = "/bflcompat"
SlashCmdList["BFLCOMPAT"] = function(msg) Perfy_Trace(Perfy_GetTime(), "Enter", "SlashCmdList.BFLCOMPAT file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:574:28");
    Compat.PrintInfo()
Perfy_Trace(Perfy_GetTime(), "Leave", "SlashCmdList.BFLCOMPAT file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:574:28"); end

------------------------------------------------------------
-- Global Aliases for Convenience
------------------------------------------------------------
-- These aliases allow direct access via BFL.FunctionName instead of BFL.Compat.FunctionName

-- Context Menu (UnitPopup) - Used by many modules
BFL.OpenContextMenu = function(button, menuType, contextData, name) Perfy_Trace(Perfy_GetTime(), "Enter", "BFL.OpenContextMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:584:22");
    Compat.OpenUnitPopupMenu(menuType, contextData)
Perfy_Trace(Perfy_GetTime(), "Leave", "BFL.OpenContextMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua:584:22"); end

-- Dropdown Creation
BFL.CreateDropdown = Compat.CreateDropdown
BFL.InitializeDropdown = Compat.InitializeDropdown

-- ColorPicker
BFL.ShowColorPicker = Compat.ShowColorPicker

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ClassicCompat.lua");