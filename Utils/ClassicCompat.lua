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

local function GetMenuTooltipFrame(tooltip)
	return tooltip or _G.BFL_Tooltip or GameTooltip
end

function Compat.ShowMenuTooltip(owner, tooltip, func, ...)
	if type(tooltip) == "function" then
		return Compat.ShowMenuTooltip(owner, nil, tooltip, func, ...)
	end
	if not owner or type(func) ~= "function" then
		return false
	end

	local argCount = select("#", ...)
	local args = { ... }
	local tooltipFrame = GetMenuTooltipFrame(tooltip)
	if not tooltipFrame then
		return false
	end

	if MenuUtil and MenuUtil.ShowTooltipEx then
		local ok = pcall(MenuUtil.ShowTooltipEx, owner, tooltipFrame, func, unpack(args, 1, argCount))
		if ok then
			return true
		end
	end
	if MenuUtil and MenuUtil.ShowTooltip then
		local ok = pcall(MenuUtil.ShowTooltip, owner, func, unpack(args, 1, argCount))
		if ok then
			return true
		end
	end
	if tooltipFrame.SetOwner and tooltipFrame.Show then
		local ok = pcall(function()
			tooltipFrame:SetOwner(owner, "ANCHOR_RIGHT")
			func(tooltipFrame, unpack(args, 1, argCount))
			tooltipFrame:Show()
		end)
		return ok
	end
	return false
end

function Compat.HideMenuTooltip(owner, tooltip)
	if not owner then
		return false
	end

	local tooltipFrame = GetMenuTooltipFrame(tooltip)
	if MenuUtil and MenuUtil.HideTooltipEx and tooltipFrame then
		local ok = pcall(MenuUtil.HideTooltipEx, owner, tooltipFrame)
		if ok then
			return true
		end
	end
	if MenuUtil and MenuUtil.HideTooltip then
		local ok = pcall(MenuUtil.HideTooltip, owner)
		if ok then
			return true
		end
	end
	if tooltipFrame and tooltipFrame.Hide then
		if not tooltipFrame.GetOwner or tooltipFrame:GetOwner() == owner then
			tooltipFrame:Hide()
			return true
		end
	end
	return false
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
	-- Mark BFL-created menu contexts directly. Global flags are fragile because
	-- Menu.ModifyMenu callbacks may run in an order we do not control.
	if contextData then
		contextData.bflOrigin = ADDON_NAME
	end

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
					-- IMPORTANT: Do NOT overwrite contextData.name!
					-- Blizzard's Whisper action uses contextData.name as the target
					-- for ChatFrame_SendBNetTell. Overwriting it with the display name
					-- (which may contain color codes, character names, etc.) breaks whisper.
					-- Store safe name in separate field for display-only use.
					contextData.bfl_streamerDisplayName = safeName
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

		-- Classic: Use safe display name for title, keep contextData.name for whisper
		local displayName = contextData.bfl_streamerDisplayName or contextData.name or ""
		local unit = contextData.unit

		-- UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
		if UnitPopup_ShowMenu then
			UnitPopup_ShowMenu(dropdown, menuType, unit, displayName, contextData)
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
		local dropdown =
			CreateFrame("Frame", name or ("BFLDropdown" .. dropdownCounter), parent, "UIDropDownMenuTemplate")
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
-- @param scrollHeight: Optional max pixel height before the dropdown scrolls (Retail only)
function Compat.InitializeDropdown(dropdown, options, getter, setter, scrollHeight)
	if BFL.HasModernDropdown and dropdown.SetupMenu then
		-- Retail: Modern API
		dropdown:SetupMenu(function(dropdown, rootDescription)
			if scrollHeight then
				rootDescription:SetScrollMode(scrollHeight)
			end
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
				local capturedValue = options.values[i]
				local capturedLabel = label
				info.value = capturedValue
				info.checked = getter(capturedValue)
				info.func = function()
					-- Use closured values, NOT self.value/self:GetText()
					-- (setter may call UIDropDownMenu_Initialize on another dropdown,
					-- which overwrites DropDownList1 buttons, corrupting self)
					setter(capturedValue)
					UIDropDownMenu_SetSelectedValue(dropdown, capturedValue)
					UIDropDownMenu_SetText(dropdown, capturedLabel)
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

-- Initialize dropdown with multi-select checkboxes
-- @param dropdown: The dropdown frame
-- @param options: Table with { labels = {...}, values = {...} }
-- @param getter: Function(value) -> boolean (is this value currently selected?)
-- @param setter: Function(value, checked) called when a checkbox is toggled
-- @param textFunc: Function() -> string (returns the display text for the dropdown)
function Compat.InitializeMultiSelectDropdown(dropdown, options, getter, setter, textFunc)
	if BFL.HasModernDropdown and dropdown.SetupMenu then
		-- Retail: Modern API with checkboxes
		dropdown:SetupMenu(function(dropdown, rootDescription)
			for i, label in ipairs(options.labels) do
				local value = options.values[i]
				rootDescription:CreateCheckbox(label, function()
					return getter(value)
				end, function()
					setter(value, not getter(value))
				end)
			end
		end)
		-- Use SetDefaultText as fallback, and SetSelectionText for dynamic updates
		dropdown:SetDefaultText(textFunc())
		dropdown:SetSelectionText(function()
			return textFunc()
		end)
	else
		-- Classic: UIDropDownMenu with checkboxes
		UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
			level = level or 1
			for i, label in ipairs(options.labels) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = label
				local capturedValue = options.values[i]
				info.value = capturedValue
				info.isNotRadio = true
				info.keepShownOnClick = true
				info.checked = function()
					return getter(capturedValue)
				end
				info.func = function(self)
					local newChecked = not getter(capturedValue)
					setter(capturedValue, newChecked)
					UIDropDownMenu_SetText(dropdown, textFunc())
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end)

		-- Set initial text
		UIDropDownMenu_SetText(dropdown, textFunc())
	end
end

-- Refresh a dropdown's displayed text after programmatic value change
-- @param dropdown: The dropdown frame
-- @param text: The text to display
function Compat.RefreshDropdown(dropdown, text)
	if BFL.HasModernDropdown and dropdown.Update then
		dropdown:Update()
	else
		UIDropDownMenu_SetText(dropdown, text)
		UIDropDownMenu_SetSelectedValue(dropdown, "")
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
			ColorPickerFrame.opacity = 1 - a -- Classic uses inverted opacity
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
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR =
			BNGetFriendInfo(friendIndex)

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
		local hasFocus, characterName, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText, broadcastTime, isOnline, gameAccountID, bnetAccountID, isGameAFK, isGameBusy, playerGuid, wowProjectID, isWowMobile, canSoR, characterDisplayName, displayNameOverride =
			BNGetFriendGameAccountInfo(friendIndex, gameAccountIndex)

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

local scrollBoxRegistrations = setmetatable({}, { __mode = "k" })
local scrollBarRegistrations = setmetatable({}, { __mode = "k" })

local function DebugCompatWarning(message)
	if BFL.DebugPrint then
		BFL:DebugPrint("|cffffcc00BFL Compat:|r " .. tostring(message))
	end
end

function Compat.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
	if not (ScrollUtil and ScrollUtil.InitScrollBoxListWithScrollBar and scrollBox and scrollBar and view) then
		return false
	end

	local existing = scrollBoxRegistrations[scrollBox]
	if existing then
		if existing.scrollBar == scrollBar then
			return true
		end
		DebugCompatWarning("ScrollBox is already registered with another ScrollBar; skipping duplicate initialization.")
		return false
	end

	local existingScrollBox = scrollBarRegistrations[scrollBar]
	if existingScrollBox and existingScrollBox ~= scrollBox then
		DebugCompatWarning("ScrollBar is already registered with another ScrollBox; skipping duplicate initialization.")
		return false
	end

	local ok, err = pcall(ScrollUtil.InitScrollBoxListWithScrollBar, scrollBox, scrollBar, view)
	if not ok then
		DebugCompatWarning(err or "ScrollBox initialization failed.")
		return false
	end

	scrollBoxRegistrations[scrollBox] = {
		scrollBar = scrollBar,
		view = view,
	}
	scrollBarRegistrations[scrollBar] = scrollBox
	return true
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
	if not texture then
		return
	end

	if BFL.IsRetail and texture.SetAtlas then
		-- Retail: Try atlas first
		local success = pcall(function()
			texture:SetAtlas(atlasName)
		end)
		if success then
			return
		end
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
	return _G[templateName] ~= nil
		or (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(templateName) ~= nil)
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
	-- BFL:DebugPrint(BFL.L.CORE_CLASSIC_COMPAT_HEADER)
	-- BFL:DebugPrint(string.format("TOC Version: |cffffffff%d|r", BFL.TOCVersion))
	-- BFL:DebugPrint("")
	-- BFL:DebugPrint(BFL.L.COMPAT_GAME_VERSION)
	-- BFL:DebugPrint(string.format("  Is Classic Era: %s", BFL.IsClassicEra and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Is MoP Classic: %s", BFL.IsMoPClassic and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Is Retail: %s", BFL.IsRetail and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Is TWW: %s", BFL.IsTWW and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint("")
	-- BFL:DebugPrint(BFL.L.CORE_FEATURE_AVAILABILITY)
	-- BFL:DebugPrint(string.format("  Modern ScrollBox: %s", BFL.HasModernScrollBox and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Modern Menu API: %s", BFL.HasModernMenu and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Modern Dropdown: %s", BFL.HasModernDropdown and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Recent Allies: %s", BFL.HasRecentAllies and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Edit Mode: %s", BFL.HasEditMode and "|cff00ff00Yes|r" or "|cffff0000No|r"))
	-- BFL:DebugPrint(string.format("  Modern ColorPicker: %s", BFL.HasModernColorPicker and "|cff00ff00Yes|r" or "|cffff0000No|r"))
end

-- Register slash command for classic info
SLASH_BFLCOMPAT1 = "/bflcompat"
SlashCmdList["BFLCOMPAT"] = function(msg)
	Compat.PrintInfo()
end

------------------------------------------------------------
-- Battle.net Status Compatibility
------------------------------------------------------------
-- Retail 12.0.1+ removed BNSetAFK/BNSetDND
-- Support modern C_BattleNet.GetMyAccountInfo

function Compat.GetMyBNetStatus()
	if C_BattleNet and C_BattleNet.GetMyAccountInfo then
		local info = C_BattleNet.GetMyAccountInfo()
		if info then
			return info.isAFK, info.isDND
		end
	elseif BNGetInfo then
		return select(5, BNGetInfo())
	end
	return false, false
end

function Compat.SetMyBNetStatus(status)
	-- status: "online", "afk", "dnd"
	if status == "online" then
		-- Modern API (12.0.1+)
		if C_BattleNet and C_BattleNet.SetAFK then
			C_BattleNet.SetAFK(false)
			C_BattleNet.SetDND(false)
		-- Legacy/Classic API
		elseif BNSetAFK then
			BNSetAFK(false)
			if BNSetDND then
				BNSetDND(false)
			end
		end
	elseif status == "afk" then
		if C_BattleNet and C_BattleNet.SetAFK then
			C_BattleNet.SetAFK(true)
		elseif BNSetAFK then
			BNSetAFK(true)
		end
	elseif status == "dnd" then
		if C_BattleNet and C_BattleNet.SetDND then
			C_BattleNet.SetDND(true)
		elseif BNSetDND then
			BNSetDND(true)
		end
	end
end

------------------------------------------------------------
-- Friend/Group Management Compatibility
------------------------------------------------------------
-- APIs for adding/removing friends and inviting to group

-- Add a WoW friend
function Compat.AddFriend(name, notes)
	if C_FriendList and C_FriendList.AddFriend then
		C_FriendList.AddFriend(name, notes or "")
	elseif AddFriend then
		AddFriend(name)
		if notes and notes ~= "" and SetFriendNotes then
			-- Note setting might be async in old API, but we try
			SetFriendNotes(name, notes)
		end
	end
end

-- Remove a WoW friend
function Compat.RemoveFriend(nameOrID)
	if C_FriendList and C_FriendList.RemoveFriend then
		C_FriendList.RemoveFriend(nameOrID)
	elseif RemoveFriend then
		RemoveFriend(nameOrID)
	end
end

-- Remove friend by index (Classic/Retail variance)
function Compat.RemoveFriendByIndex(index)
	if C_FriendList and C_FriendList.RemoveFriendByIndex then
		C_FriendList.RemoveFriendByIndex(index)
	elseif RemoveFriend then
		-- Classic: Need to get name first
		local name = GetFriendInfo(index)
		if name then
			RemoveFriend(name)
		end
	end
end

-- Set friend notes
function Compat.SetFriendNotes(name, notes)
	if C_FriendList and C_FriendList.SetFriendNotes then
		C_FriendList.SetFriendNotes(name, notes)
	elseif SetFriendNotes then
		SetFriendNotes(name, notes)
	end
end

-- Invite a unit to party
function Compat.InviteUnit(name)
	if C_PartyInfo and C_PartyInfo.InviteUnit then
		C_PartyInfo.InviteUnit(name)
	elseif InviteUnit then
		InviteUnit(name)
	end
end

-- Convert party to raid
function Compat.ConvertToRaid()
	if C_PartyInfo and C_PartyInfo.ConvertToRaid then
		C_PartyInfo.ConvertToRaid()
	elseif ConvertToRaid then
		ConvertToRaid()
	end
end

-- Convert raid to party
function Compat.ConvertToParty()
	if C_PartyInfo and C_PartyInfo.ConvertToParty then
		C_PartyInfo.ConvertToParty()
	elseif ConvertToParty then
		ConvertToParty()
	end
end

-- Request invite from unit (Retail only usually)
function Compat.RequestInviteFromUnit(target)
	if C_PartyInfo and C_PartyInfo.RequestInviteFromUnit then
		C_PartyInfo.RequestInviteFromUnit(target)
		return true
	else
		-- Feature not available in Classic
		-- We could whisper them, but that's intrusive.
		-- Just return false.
		-- BFL:DebugPrint("RequestInviteFromUnit not available in this version")
		return false
	end
end

-- Invite Battle.net friend
function Compat.BNInviteFriend(gameAccountID)
	if C_BattleNet and C_BattleNet.InviteFriend then
		C_BattleNet.InviteFriend(gameAccountID)
		return true
	elseif BNInviteFriend then
		BNInviteFriend(gameAccountID)
		return true
	end
	return false
end

function Compat.DoReadyCheck()
	if C_PartyInfo and C_PartyInfo.DoReadyCheck then
		C_PartyInfo.DoReadyCheck()
		return true
	elseif DoReadyCheck then
		DoReadyCheck()
		return true
	end
	return false
end

function Compat.ConfirmReadyCheck(isReady)
	if isReady == nil then
		isReady = false
	end

	if C_PartyInfo and C_PartyInfo.ConfirmReadyCheck then
		C_PartyInfo.ConfirmReadyCheck(isReady)
		return true
	elseif ConfirmReadyCheck then
		ConfirmReadyCheck(isReady)
		return true
	end
	return false
end

function Compat.PromoteToAssistant(name, exactNameMatch)
	if C_PartyInfo and C_PartyInfo.PromoteToAssistant then
		C_PartyInfo.PromoteToAssistant(name, exactNameMatch)
		return true
	elseif PromoteToAssistant then
		PromoteToAssistant(name, exactNameMatch)
		return true
	end
	return false
end

function Compat.PromoteToLeader(name, exactNameMatch)
	if C_PartyInfo and C_PartyInfo.PromoteToLeader then
		C_PartyInfo.PromoteToLeader(name, exactNameMatch)
		return true
	elseif PromoteToLeader then
		PromoteToLeader(name, exactNameMatch)
		return true
	end
	return false
end

function Compat.DemoteAssistant(name, exactNameMatch)
	if C_PartyInfo and C_PartyInfo.DemoteAssistant then
		C_PartyInfo.DemoteAssistant(name, exactNameMatch)
		return true
	elseif DemoteAssistant then
		DemoteAssistant(name, exactNameMatch)
		return true
	end
	return false
end

function Compat.SetEveryoneIsAssistant(isAssistant)
	isAssistant = not not isAssistant
	if C_PartyInfo and C_PartyInfo.SetEveryoneIsAssistant then
		C_PartyInfo.SetEveryoneIsAssistant(isAssistant)
		return true
	elseif SetEveryoneIsAssistant then
		SetEveryoneIsAssistant(isAssistant)
		return true
	end
	return false
end

function Compat.UninviteUnit(name, reason, exactNameMatch)
	if C_PartyInfo and C_PartyInfo.UninviteUnit then
		C_PartyInfo.UninviteUnit(name, reason, exactNameMatch)
		return true
	elseif UninviteUnit then
		UninviteUnit(name, reason, exactNameMatch)
		return true
	end
	return false
end

function Compat.IsGUIDInGroup(guid, category)
	if C_PartyInfo and C_PartyInfo.IsGUIDInGroup then
		return C_PartyInfo.IsGUIDInGroup(guid, category)
	elseif IsGUIDInGroup then
		return IsGUIDInGroup(guid, category)
	end
	return false
end

function Compat.GetAutoCompletePresenceID(name)
	if C_AutoComplete and C_AutoComplete.GetAutoCompletePresenceID then
		return C_AutoComplete.GetAutoCompletePresenceID(name)
	elseif GetAutoCompletePresenceID then
		return GetAutoCompletePresenceID(name)
	end
	return nil
end

function Compat.GetAutoCompleteRealms()
	if C_AutoComplete and C_AutoComplete.GetAutoCompleteRealms then
		return C_AutoComplete.GetAutoCompleteRealms()
	elseif GetAutoCompleteRealms then
		return GetAutoCompleteRealms()
	end
	return {}
end

local function GetAutoCompleteIncludeFlags(includeFlags)
	return includeFlags or AUTOCOMPLETE_FLAG_ALL or 0xffffffff
end

local function GetAutoCompleteExcludeFlags(excludeFlags)
	return excludeFlags or AUTOCOMPLETE_FLAG_NONE or 0
end

function Compat.GetAutoCompleteResults(name, numResults, cursorPosition, allowFullMatch, includeFlags, excludeFlags)
	includeFlags = GetAutoCompleteIncludeFlags(includeFlags)
	excludeFlags = GetAutoCompleteExcludeFlags(excludeFlags)

	if C_AutoComplete and C_AutoComplete.GetAutoCompleteResults then
		return C_AutoComplete.GetAutoCompleteResults(
			name or "",
			numResults or AUTOCOMPLETE_MAX_BUTTONS or 5,
			cursorPosition or 0,
			not not allowFullMatch,
			includeFlags,
			excludeFlags
		)
	elseif GetAutoCompleteResults then
		return GetAutoCompleteResults(
			name or "",
			numResults or AUTOCOMPLETE_MAX_BUTTONS or 5,
			cursorPosition or 0,
			not not allowFullMatch,
			includeFlags,
			excludeFlags
		)
	end
	return {}
end

function Compat.IsRecognizedName(name, includeFlags, excludeFlags)
	includeFlags = GetAutoCompleteIncludeFlags(includeFlags)
	excludeFlags = GetAutoCompleteExcludeFlags(excludeFlags)

	if C_AutoComplete and C_AutoComplete.IsRecognizedName then
		return C_AutoComplete.IsRecognizedName(
			name or "",
			includeFlags,
			excludeFlags
		)
	elseif IsRecognizedName then
		return IsRecognizedName(name or "", includeFlags, excludeFlags)
	end
	return false
end

function Compat.MakeModifiers()
	if MakeModifiers then
		local ok, modifiers = pcall(MakeModifiers)
		if ok then
			return modifiers
		end
	elseif C_ClickBindings and C_ClickBindings.MakeModifiers then
		local ok, modifiers = pcall(C_ClickBindings.MakeModifiers)
		if ok then
			return modifiers
		end
	end
	return 0
end

function Compat.GetStringFromModifiers(modifiers)
	modifiers = modifiers or 0
	if GetStringFromModifiers then
		local ok, modifierString = pcall(GetStringFromModifiers, modifiers)
		if ok then
			return modifierString
		end
	elseif C_ClickBindings and C_ClickBindings.GetStringFromModifiers then
		local ok, modifierString = pcall(C_ClickBindings.GetStringFromModifiers, modifiers)
		if ok then
			return modifierString
		end
	end
	return ""
end

local function EscapeControlCharacter(character)
	local byte = string.byte(character)
	if byte == 10 or byte == 13 or byte == 9 then
		return character
	end
	return "\\" .. tostring(byte)
end

function Compat.EscapeDebugString(text)
	if text == nil then
		return ""
	end

	if StringUtil and StringUtil.EscapeDecimalNonPrintables then
		local ok, escapedText = pcall(StringUtil.EscapeDecimalNonPrintables, tostring(text))
		if ok and escapedText then
			return escapedText
		end
	end

	return tostring(text):gsub("[%z\001-\031\127]", EscapeControlCharacter)
end

local function GetPerformanceFunction(functionName)
	if C_Performance and C_Performance[functionName] then
		return C_Performance[functionName]
	end
	return _G[functionName]
end

local function GetPerformanceUsage(functionName)
	local getter = GetPerformanceFunction(functionName)
	if getter then
		local ok, value1, value2 = pcall(getter)
		if ok then
			return value1, value2
		end
	end
	return nil
end

function Compat.GetEventCPUUsage()
	return GetPerformanceUsage("GetEventCPUUsage")
end

function Compat.GetFunctionCPUUsage()
	return GetPerformanceUsage("GetFunctionCPUUsage")
end

function Compat.GetScriptCPUUsage()
	return GetPerformanceUsage("GetScriptCPUUsage")
end

------------------------------------------------------------
-- Level / Expansion Compatibility
------------------------------------------------------------

-- Get absolute max level for the current expansion context
function Compat.GetMaxLevel()
	-- Retail / Modern API
	if GetMaxLevelForPlayerExpansion then
		return GetMaxLevelForPlayerExpansion()
	end

	-- Fallbacks based on game version flags (defined in Core.lua)
	if BFL.IsTWW then
		return 80
	end
	if BFL.IsRetail then
		return 70
	end -- Dragonflight fallback
	if BFL.IsMoPClassic then
		return 90
	end
	if BFL.IsCataClassic then
		return 85
	end
	if BFL.IsWrathClassic then
		return 80
	end
	if BFL.IsTBCClassic then
		return 70
	end
	if BFL.IsClassicEra then
		return 60
	end

	-- Last resort default (Vanilla)
	return 60
end

------------------------------------------------------------
-- Guild Roster Compatibility
------------------------------------------------------------

-- Request guild roster update (triggers GUILD_ROSTER_UPDATE)
function Compat.GuildRoster()
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	elseif GuildRoster then
		GuildRoster()
	end
end

-- Get guild roster member info (unified return table across versions)
-- Returns: { fullName, rankName, rankIndex, level, classDisplayName, zone,
--            note, officerNote, online, isAFK, isDND, classFileName,
--            achievementPoints, achievementRank, isMobile, isSoREligible,
--            standingID, guid }
function Compat.GetGuildRosterInfo(index)
	return GetGuildRosterInfo(index)
end

-- Get guild roster last online time
-- Returns: years, months, days, hours
function Compat.GetGuildRosterLastOnline(index)
	if GetGuildRosterLastOnline then
		return GetGuildRosterLastOnline(index)
	end
	return 0, 0, 0, 0
end

local guildMOTDCache = ""
local guildMOTDCacheValid = false
local guildMOTDChatUtilHookInstalled = false
local guildMOTDChatGlobalHookInstalled = false

local function NormalizeGuildMOTD(motd)
	if BFL.HasSecretValues and BFL.IsSecret and BFL:IsSecret(motd) then
		return "", false
	end
	if motd == nil then
		return "", false
	end

	return tostring(motd):gsub("|n", "\n"):gsub("\\n", "\n"), true
end

function BFL.CacheGuildMOTD(motd)
	local normalized, canCache = NormalizeGuildMOTD(motd)
	if not canCache then
		return guildMOTDCache
	end

	guildMOTDCache = normalized
	guildMOTDCacheValid = true
	return guildMOTDCache
end

function BFL.ClearGuildMOTDCache()
	guildMOTDCache = ""
	guildMOTDCacheValid = false
end

function BFL.GetGuildMOTD()
	if guildMOTDCacheValid then
		return guildMOTDCache
	end

	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		return ""
	end
	if IsInGuild then
		local okInGuild, inGuild = pcall(IsInGuild)
		if okInGuild and not inGuild then
			return ""
		end
	end

	local getter = C_GuildInfo and C_GuildInfo.GetMOTD or GetGuildRosterMOTD
	if not getter then
		return ""
	end

	local ok, motd
	if BFL.HasSecretValues and securecallfunction then
		ok, motd = pcall(securecallfunction, getter)
	elseif BFL.HasSecretValues then
		return ""
	else
		ok, motd = pcall(getter)
	end
	if not ok then
		return ""
	end
	return BFL.CacheGuildMOTD(motd)
end

local function CacheGuildMOTDFromChatFrame(_, motd)
	BFL.CacheGuildMOTD(motd)
end

local function InstallGuildMOTDChatHooks()
	if not hooksecurefunc then
		return
	end

	if not guildMOTDChatUtilHookInstalled and ChatFrameUtil and ChatFrameUtil.DisplayGMOTD then
		local ok = pcall(hooksecurefunc, ChatFrameUtil, "DisplayGMOTD", CacheGuildMOTDFromChatFrame)
		guildMOTDChatUtilHookInstalled = ok or guildMOTDChatUtilHookInstalled
	end

	if not guildMOTDChatGlobalHookInstalled and type(ChatFrame_DisplayGMOTD) == "function" then
		local ok = pcall(hooksecurefunc, "ChatFrame_DisplayGMOTD", CacheGuildMOTDFromChatFrame)
		guildMOTDChatGlobalHookInstalled = ok or guildMOTDChatGlobalHookInstalled
	end
end

if BFL.RegisterEventCallback then
	InstallGuildMOTDChatHooks()

	BFL:RegisterEventCallback("GUILD_MOTD", function(motd)
		BFL.CacheGuildMOTD(motd)
	end, 5)

	BFL:RegisterEventCallback("PLAYER_LOGIN", function()
		InstallGuildMOTDChatHooks()
	end, 5)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function(unitTarget)
		if unitTarget and unitTarget ~= "player" then
			return
		end
		BFL.ClearGuildMOTDCache()
	end, 5)
end

------------------------------------------------------------
-- Global Aliases for Convenience
------------------------------------------------------------
-- These aliases allow direct access via BFL.FunctionName instead of BFL.Compat.FunctionName

-- Context Menu (UnitPopup) - Used by many modules
BFL.OpenContextMenu = function(button, menuType, contextData, name)
	if contextData then
		contextData.bflOrigin = ADDON_NAME
	end
	if BFL.HasSecretValues and BFL.OpenBetterFriendlistContextMenu then
		if BFL:OpenBetterFriendlistContextMenu(button, menuType, contextData, name) then
			return
		end
	end
	Compat.OpenUnitPopupMenu(menuType, contextData)
end

-- Dropdown Creation
BFL.CreateDropdown = Compat.CreateDropdown
BFL.InitializeDropdown = Compat.InitializeDropdown
BFL.InitializeMultiSelectDropdown = Compat.InitializeMultiSelectDropdown
BFL.RefreshDropdown = Compat.RefreshDropdown
BFL.ShowMenuTooltip = Compat.ShowMenuTooltip
BFL.HideMenuTooltip = Compat.HideMenuTooltip

-- ColorPicker
BFL.ShowColorPicker = Compat.ShowColorPicker

-- BNet Status
BFL.GetMyBNetStatus = Compat.GetMyBNetStatus
BFL.SetMyBNetStatus = Compat.SetMyBNetStatus

-- Friend/Group Operations
BFL.AddFriend = Compat.AddFriend
BFL.RemoveFriend = Compat.RemoveFriend
BFL.RemoveFriendByIndex = Compat.RemoveFriendByIndex
BFL.SetFriendNotes = Compat.SetFriendNotes
BFL.InviteUnit = Compat.InviteUnit
BFL.ConvertToRaid = Compat.ConvertToRaid
BFL.ConvertToParty = Compat.ConvertToParty
BFL.RequestInviteFromUnit = Compat.RequestInviteFromUnit
BFL.BNInviteFriend = Compat.BNInviteFriend
BFL.DoReadyCheck = Compat.DoReadyCheck
BFL.ConfirmReadyCheck = Compat.ConfirmReadyCheck
BFL.PromoteToAssistant = Compat.PromoteToAssistant
BFL.PromoteToLeader = Compat.PromoteToLeader
BFL.DemoteAssistant = Compat.DemoteAssistant
BFL.SetEveryoneIsAssistant = Compat.SetEveryoneIsAssistant
BFL.UninviteUnit = Compat.UninviteUnit
BFL.IsGUIDInGroup = Compat.IsGUIDInGroup
BFL.GetAutoCompletePresenceID = Compat.GetAutoCompletePresenceID
BFL.GetAutoCompleteRealms = Compat.GetAutoCompleteRealms
BFL.GetAutoCompleteResults = Compat.GetAutoCompleteResults
BFL.IsRecognizedName = Compat.IsRecognizedName
BFL.MakeModifiers = Compat.MakeModifiers
BFL.GetStringFromModifiers = Compat.GetStringFromModifiers
BFL.InitScrollBoxListWithScrollBar = Compat.InitScrollBoxListWithScrollBar
BFL.EscapeDebugString = Compat.EscapeDebugString
BFL.GetEventCPUUsage = Compat.GetEventCPUUsage
BFL.GetFunctionCPUUsage = Compat.GetFunctionCPUUsage
BFL.GetScriptCPUUsage = Compat.GetScriptCPUUsage
BFL.GetMaxLevel = Compat.GetMaxLevel

-- Guild Operations
BFL.GuildRoster = Compat.GuildRoster
BFL.GetGuildRosterInfo = Compat.GetGuildRosterInfo
BFL.GetGuildRosterLastOnline = Compat.GetGuildRosterLastOnline
