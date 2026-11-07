-- Utils/ClassicCompat.lua
-- Compatibility Layer for Classic Era and MoP Classic
-- Provides wrapper functions for APIs that differ between Retail and Classic
-- Version 1.0 - December 2025

local ADDON_NAME, BFL = ...

-- Create Compat namespace
BFL.Compat = {}
local Compat = BFL.Compat

local function HasFrameMethod(frame, methodName)
	return frame ~= nil and type(frame[methodName]) == "function"
end

local SAFE_FRAME_STRATA = {
	BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true,
	DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true,
}

-- Never propagate a secret Blizzard frame property into addon-owned overlays.
function Compat.GetSafeFrameStrata(frame, fallback)
	if (BFL.IsSecret and BFL:IsSecret(fallback)) or type(fallback) ~= "string" or not SAFE_FRAME_STRATA[fallback] then
		fallback = "HIGH"
	end
	if not HasFrameMethod(frame, "GetFrameStrata") then
		return fallback
	end
	local ok, strata = pcall(frame.GetFrameStrata, frame)
	if not ok or (BFL.IsSecret and BFL:IsSecret(strata)) then
		return fallback
	end
	return type(strata) == "string" and SAFE_FRAME_STRATA[strata] and strata or fallback
end

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

local function ApplyIconProfileToClassicMenuItem(item, profile)
	if not (item and type(profile) == "table") or profile.iconType == "none" then
		return false
	end

	local texture = profile.texture
	if not texture and profile.iconType ~= "atlas" then
		texture = profile.iconValue or profile.icon
	end
	if not texture or texture == "" then
		return false
	end

	item.icon = texture
	local texCoord = profile.texCoord
	if type(texCoord) == "table" and #texCoord >= 4 then
		item.tCoordLeft = texCoord[1]
		item.tCoordRight = texCoord[2]
		item.tCoordTop = texCoord[3]
		item.tCoordBottom = texCoord[4]
	else
		local zoom = tonumber(profile.iconZoom) or 0
		zoom = math.max(0, math.min(0.45, zoom))
		item.tCoordLeft = zoom
		item.tCoordRight = 1 - zoom
		item.tCoordTop = zoom
		item.tCoordBottom = 1 - zoom
	end
	return true
end

local SIMPLE_MENU_CHECKED_ATLASES = {
	"common-dropdown-icon-checkmark-yellow-classic",
	"common-dropdown-icon-checkmark-yellow-classic-2",
	"common-dropdown-icon-checkmark-yellow",
}
local SIMPLE_MENU_UNCHECKED_ATLASES = {
	"common-dropdown-ticksquare-classic",
	"common-dropdown-ticksquare",
}

local function GetFirstAvailableMenuAtlas(candidates)
	local getAtlasInfo = (C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo
	if type(getAtlasInfo) ~= "function" then
		return nil
	end
	for _, atlas in ipairs(candidates) do
		local ok, info = pcall(getAtlasInfo, atlas)
		if ok and info then
			return atlas
		end
	end
	return nil
end

local function ApplyClassicCheckboxMenuItemStyle(item)
	if not (BFL.IsClassic and item) then
		return
	end
	local checkedAtlas = GetFirstAvailableMenuAtlas(SIMPLE_MENU_CHECKED_ATLASES)
	local uncheckedAtlas = GetFirstAvailableMenuAtlas(SIMPLE_MENU_UNCHECKED_ATLASES)
	if checkedAtlas and uncheckedAtlas then
		item.customCheckIconAtlas = checkedAtlas
		item.customUncheckIconAtlas = uncheckedAtlas
	end
end

local function CreateClassicMenuDescription(parentItem, rootItems)
	rootItems = rootItems or {}

	local rootDescription = {}
	local queuedItems

	local function GetTargetItems()
		if parentItem then
			parentItem.hasArrow = true
			parentItem.notCheckable = true
			parentItem.func = nil
			parentItem.menuList = parentItem.menuList or {}
			return parentItem.menuList
		end
		return rootItems
	end

	local function AddItem(item)
		local items = GetTargetItems()
		if queuedItems then
			for _, queuedItem in ipairs(queuedItems) do
				table.insert(items, queuedItem)
			end
			queuedItems = nil
		end
		table.insert(items, item)
		return CreateClassicMenuDescription(item)
	end

	local function QueueItem(item, clearQueue)
		if clearQueue or not queuedItems then
			queuedItems = {}
		end
		table.insert(queuedItems, item)
	end

	-- Match Blizzard's deferred sections: only commit a heading when an action
	-- follows it, and discard an empty section when the next section is queued.
	function rootDescription:ClearQueuedDescriptions()
		queuedItems = nil
	end

	function rootDescription:QueueTitle(text, _color, clearQueue)
		QueueItem({ text = text or "", isTitle = true, notCheckable = true }, clearQueue)
	end

	function rootDescription:QueueDivider(clearQueue)
		QueueItem({ text = "", disabled = true, notCheckable = true }, clearQueue)
	end

	function rootDescription:SetEnabled(enabled)
		if parentItem then
			parentItem.disabled = not enabled
		end
	end

	function rootDescription:SetTag()
		-- Menu tags are metadata used by the Retail menu system only.
	end

	function rootDescription:SetScrollMode()
		-- UIDropDownMenu has no equivalent scroll-mode description API.
	end

	function rootDescription:SetIconProfile(profile)
		if parentItem then
			ApplyIconProfileToClassicMenuItem(parentItem, profile)
		end
	end

	function rootDescription:SetCloseOnClick(closeOnClick)
		if parentItem then
			parentItem.keepShownOnClick = closeOnClick == false
		end
	end

	function rootDescription:CreateTitle(text)
		return AddItem({
			text = text or "",
			isTitle = true,
			notCheckable = true,
		})
	end

	function rootDescription:CreateDivider()
		return AddItem({
			text = "",
			disabled = true,
			notCheckable = true,
		})
	end

	function rootDescription:CreateButton(text, onSelected)
		local item = {
			text = text or "",
			notCheckable = true,
		}
		if type(onSelected) == "function" then
			item.func = onSelected
		end
		return AddItem(item)
	end

	function rootDescription:CreateRedHighlightButton(text, onSelected)
		-- UIDropDownMenu has no destructive-button variant. Keep the action
		-- available and let Retail/Forever use the native red presentation.
		return self:CreateButton(text, onSelected)
	end

	function rootDescription:CreateCheckbox(text, isSelected, onSelected)
		local item = {
			text = text or "",
			notCheckable = false,
			isNotRadio = true,
			keepShownOnClick = true,
		}
		ApplyClassicCheckboxMenuItemStyle(item)
		if type(isSelected) == "function" then
			item.checked = function()
				return isSelected() == true
			end
		else
			item.checked = isSelected == true
		end
		if type(onSelected) == "function" then
			item.func = onSelected
		end
		return AddItem(item)
	end

	function rootDescription:CreateRadio(text, isSelected, onSelected, value)
		local item = {
			text = text or "",
			arg1 = value,
			notCheckable = false,
		}
		if type(isSelected) == "function" then
			item.checked = function()
				return isSelected(value) == true
			end
		else
			item.checked = isSelected == true
		end
		if type(onSelected) == "function" then
			item.func = function(_, selectedValue)
				return onSelected(selectedValue)
			end
		end
		return AddItem(item)
	end

	return rootDescription, rootItems
end

-- Create a context menu (right-click menus)
-- @param owner: Frame that owns the menu
-- @param menuGenerator: Function that returns menu items
-- @param menuGenerator: Retail rootDescription generator or EasyMenu-compatible table factory
function Compat.CreateContextMenu(owner, menuGenerator)
	if MenuUtil and MenuUtil.CreateContextMenu then
		-- Retail: Modern Menu API
		return MenuUtil.CreateContextMenu(owner, menuGenerator)
	else
		-- Classic: UIDropDownMenu fallback
		local menuFrame = CreateFrame("Frame", "BFLContextMenu" .. dropdownCounter, UIParent, "UIDropDownMenuTemplate")
		dropdownCounter = dropdownCounter + 1

		local classicRootDescription, classicMenuTable = CreateClassicMenuDescription()
		local menuTable = menuGenerator(owner, classicRootDescription)
		if not menuTable and #classicMenuTable > 0 then
			menuTable = classicMenuTable
		end
		if menuTable then
			EasyMenu(menuTable, menuFrame, owner or "cursor", 0, 0, "MENU")
		end
		return menuFrame
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

local function GetSimpleMenuItems(itemsOrFactory)
	if type(itemsOrFactory) == "function" then
		return itemsOrFactory() or {}
	end
	return itemsOrFactory or {}
end

local function GetSimpleMenuChildren(item)
	if not item then
		return nil
	end
	return item.children or item.items or item.menuList
end

local function SetSimpleMenuElementEnabled(element, enabled)
	if not element then
		return
	end
	if element.SetEnabled then
		element:SetEnabled(enabled)
	else
		element.enabled = enabled
	end
end

local function ResolveSimpleMenuTooltip(item)
	if not item then
		return nil
	end
	local tooltip = item.tooltip
	if type(tooltip) == "function" then
		local ok, value = pcall(tooltip, item)
		tooltip = ok and value or nil
	end
	if type(tooltip) ~= "string" or tooltip == "" then
		return nil
	end
	return tooltip
end

local function ApplySimpleMenuItemTooltip(element, item)
	local tooltip = ResolveSimpleMenuTooltip(item)
	if not (element and tooltip and element.SetTooltip) then
		return
	end
	element:SetTooltip(function(menuTooltip)
		menuTooltip:SetText(item.tooltipTitle or item.text or "", 1, 1, 1)
		local color = item.tooltipIsWarning == false and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR
		if color then
			menuTooltip:AddLine(tooltip, color.r, color.g, color.b, true)
		else
			menuTooltip:AddLine(tooltip, 1, 0.25, 0.25, true)
		end
	end)
end

function Compat.CreateMenuButton(rootDescription, text, callback, options)
	if not (rootDescription and rootDescription.CreateButton) then
		return nil
	end
	options = options or {}
	local createButton = options.destructive and rootDescription.CreateRedHighlightButton
		or rootDescription.CreateButton
	local element = createButton(rootDescription, text or "", callback)
	if options.enabled ~= nil then
		SetSimpleMenuElementEnabled(element, options.enabled == true)
	end
	ApplySimpleMenuItemTooltip(element, {
		text = text,
		tooltipTitle = options.tooltipTitle,
		tooltip = options.tooltip,
		tooltipIsWarning = options.tooltipIsWarning,
	})
	return element
end

function Compat.SupportsNativeMenuExtensions()
	return Menu and type(Menu.ModifyMenu) == "function" and MenuUtil
		and type(MenuUtil.GetElementText) == "function" and type(MenuUtil.SetElementText) == "function"
end

function Compat.GetMenuElementText(element)
	if not (MenuUtil and MenuUtil.GetElementText) then return element.text end
	return MenuUtil.GetElementText(element)
end

function Compat.SetMenuElementText(element, text)
	MenuUtil.SetElementText(element, text)
end

function Compat.StyleSimpleMenuCheckbox(element)
	if not (BFL.IsClassic and element and element.AddInitializer) then
		return
	end

	element:AddInitializer(function(button, description)
		local marker = button and button.leftTexture1
		if not (marker and marker.GetTexture and marker.SetTexture) then
			return
		end
		local selected = false
		if description and description.IsSelected then
			local ok, value = pcall(description.IsSelected, description)
			selected = ok and value == true
		end
		local atlas = GetFirstAvailableMenuAtlas(selected and SIMPLE_MENU_CHECKED_ATLASES or SIMPLE_MENU_UNCHECKED_ATLASES)
		if atlas and marker.SetAtlas then
			local ok = pcall(marker.SetAtlas, marker, atlas, true)
			if ok then
				return
			end
		end
		local ok, assignedTexture = pcall(marker.GetTexture, marker)
		if not selected and ok and assignedTexture == nil then
			marker:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
			marker:SetTexCoord(0, 1, 0, 1)
			marker:SetSize(20, 20)
		end
	end)
end

local function ApplySimpleMenuItemIcon(element, item)
	local profile = item and item.iconProfile
	if not (element and type(profile) == "table") then
		return
	end
	if element.SetIconProfile then
		element:SetIconProfile(profile)
		return
	end
	if not element.AddInitializer then
		return
	end

	element:AddInitializer(function(button)
		if not (button and button.AttachTexture) then
			return
		end
		local texture = button:AttachTexture()
		texture:SetSize(16, 16)
		if button.leftTexture1 then
			texture:SetPoint("LEFT", button.leftTexture1, "RIGHT", 2, 0)
		else
			texture:SetPoint("LEFT", button, "LEFT", 4, 0)
		end
		if button.fontString then
			button.fontString:SetPoint("LEFT", texture, "RIGHT", 3, 0)
		end
		if Compat.ApplyIconProfile then
			Compat.ApplyIconProfile(texture, profile)
		end
	end)
end

local function IsSimpleMenuItemChecked(item, value)
	if type(item.checked) == "function" then
		return item.checked(value)
	end
	if type(item.isSelected) == "function" then
		return item.isSelected(value)
	end
	return item.checked == true
end

local function RunSimpleMenuItem(item, value)
	if type(item.func) == "function" then
		return item.func(value)
	end
	if item.type == "whisper" then
		local friendMenu = BFL:GetModule("NativeFriendMenu")
		if friendMenu then friendMenu:ShowWhisperUnavailable() end
	end
end

function Compat.PopulateSimpleMenu(rootDescription, itemsOrFactory)
	if not (rootDescription and rootDescription.CreateButton) then
		return false
	end

	for _, item in ipairs(GetSimpleMenuItems(itemsOrFactory)) do
		if not item.hidden then
			local itemType = item.type or "button"
			if itemType == "divider" then
				if rootDescription.CreateDivider then
					rootDescription:CreateDivider()
				end
			elseif itemType == "title" then
				if rootDescription.CreateTitle then
					rootDescription:CreateTitle(item.text or "")
				else
					local title = rootDescription:CreateButton(item.text or "", function() end)
					SetSimpleMenuElementEnabled(title, false)
				end
			elseif itemType == "whisper" then
				local friendMenu = BFL:GetModule("NativeFriendMenu")
				if friendMenu then
					friendMenu:AddCharacterWhisperMenuItem(rootDescription, item.whisperTarget, item.text)
				end
			elseif GetSimpleMenuChildren(item) then
				local element = rootDescription:CreateButton(item.text or "")
				ApplySimpleMenuItemIcon(element, item)
				ApplySimpleMenuItemTooltip(element, item)
				Compat.PopulateSimpleMenu(element, GetSimpleMenuChildren(item))
				if item.disabled ~= nil or item.enabled ~= nil then
					local enabled = item.enabled
					if enabled == nil then
						enabled = not item.disabled
					end
					SetSimpleMenuElementEnabled(element, enabled)
				end
			elseif itemType == "radio" and rootDescription.CreateRadio then
				local element = rootDescription:CreateRadio(item.text or "", function(value)
					return IsSimpleMenuItemChecked(item, value)
				end, function(value)
					return RunSimpleMenuItem(item, value)
				end, item.value)
				ApplySimpleMenuItemIcon(element, item)
				ApplySimpleMenuItemTooltip(element, item)
				if item.disabled ~= nil or item.enabled ~= nil then
					local enabled = item.enabled
					if enabled == nil then
						enabled = not item.disabled
					end
					SetSimpleMenuElementEnabled(element, enabled)
				end
			elseif itemType == "checkbox" and rootDescription.CreateCheckbox then
				local element = rootDescription:CreateCheckbox(item.text or "", function()
					return IsSimpleMenuItemChecked(item, item.value)
				end, function()
					return RunSimpleMenuItem(item, item.value)
				end)
				Compat.StyleSimpleMenuCheckbox(element)
				ApplySimpleMenuItemIcon(element, item)
				ApplySimpleMenuItemTooltip(element, item)
				if item.disabled ~= nil or item.enabled ~= nil then
					local enabled = item.enabled
					if enabled == nil then
						enabled = not item.disabled
					end
					SetSimpleMenuElementEnabled(element, enabled)
				end
			else
				local createButton = item.destructive and rootDescription.CreateRedHighlightButton
					or rootDescription.CreateButton
				local element = createButton(rootDescription, item.text or "", function()
					return RunSimpleMenuItem(item, item.value)
				end)
				ApplySimpleMenuItemIcon(element, item)
				ApplySimpleMenuItemTooltip(element, item)
				if item.disabled ~= nil or item.enabled ~= nil then
					local enabled = item.enabled
					if enabled == nil then
						enabled = not item.disabled
					end
					SetSimpleMenuElementEnabled(element, enabled)
				end
			end
		end
	end
	return true
end

function Compat.OpenSimpleContextMenu(owner, name, itemsOrFactory)
	if type(name) ~= "string" then
		itemsOrFactory = name
		name = nil
	end

	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(owner or UIParent, function(_, rootDescription)
			Compat.PopulateSimpleMenu(rootDescription, itemsOrFactory)
		end)
		return true
	end

	if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then
		return false
	end

	if not name or name == "" then
		name = "BFLSimpleContextMenu" .. dropdownCounter
		dropdownCounter = dropdownCounter + 1
	end
	local menuFrame = _G[name]
	if not menuFrame then
		menuFrame = CreateFrame("Frame", name, UIParent, "UIDropDownMenuTemplate")
	end

	UIDropDownMenu_Initialize(menuFrame, function(_, level, menuList)
		level = level or 1
		local items = level == 1 and GetSimpleMenuItems(itemsOrFactory) or GetSimpleMenuItems(menuList)
		for _, item in ipairs(items) do
			if not item.hidden and item.type ~= "divider" then
				local itemType = item.type or "button"
				local children = GetSimpleMenuChildren(item)
				local info = UIDropDownMenu_CreateInfo()
				info.text = item.text or ""
				info.isTitle = itemType == "title"
				info.disabled = item.disabled or item.enabled == false
				if children then
					info.notCheckable = true
					info.hasArrow = true
					info.menuList = children
				elseif itemType == "radio" or itemType == "checkbox" then
					info.notCheckable = false
					info.isNotRadio = itemType == "checkbox"
					info.keepShownOnClick = item.keepShownOnClick == true
					if itemType == "checkbox" then
						ApplyClassicCheckboxMenuItemStyle(info)
					end
					info.checked = function()
						return IsSimpleMenuItemChecked(item, item.value)
					end
				else
					info.notCheckable = true
				end
				ApplyIconProfileToClassicMenuItem(info, item.iconProfile)
				local tooltip = ResolveSimpleMenuTooltip(item)
				if tooltip then
					info.tooltipTitle = item.tooltipTitle or item.text or ""
					info.tooltipText = tooltip
					info.tooltipWhileDisabled = true
					info.tooltipOnButton = true
				end
				if itemType ~= "title" and not children then
					info.func = function()
						RunSimpleMenuItem(item, item.value)
					end
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end, "MENU")

	ToggleDropDownMenu(1, nil, menuFrame, owner or "cursor", 0, 0)
	return true
end

------------------------------------------------------------
-- UnitPopup Compatibility
------------------------------------------------------------
-- Retail 11.0+: UnitPopup_OpenMenu(menuType, contextData)
-- Classic: UnitPopup_ShowMenu(dropdown, which, unit, name, userData)

local function PrepareUnitPopupContext(menuType, contextData)
	-- Mark BFL-created menu contexts directly. Global flags are fragile because
	-- Menu.ModifyMenu callbacks may run in an order we do not control.
	if contextData then
		contextData.bflOrigin = ADDON_NAME
	end

	-- Streamer Mode Interception for Context Menu Header (Added 2026-02-01)
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() and contextData then
		if menuType == "BN_FRIEND" or menuType == "BN_FRIEND_OFFLINE" then
			contextData.bfl_streamerDisplayName = UNKNOWN or "Unknown"
		end
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.friendsList then
			local friend = nil

			-- 1. Try BNet ID (Most reliable for BNet)
			local bnetIDAccount = contextData.bnetIDAccount
			if not BFL:IsSecret(bnetIDAccount) and bnetIDAccount then
				for _, f in ipairs(FriendsList.friendsList) do
					if f.type == "bnet" and not BFL:IsSecret(f.bnetAccountID) and f.bnetAccountID == bnetIDAccount then
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

end

function Compat.OpenUnitPopupMenu(menuType, contextData)
	PrepareUnitPopupContext(menuType, contextData)
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
-- @param preferModern: Optional opt-in for modern dropdowns, or { forceLegacy = true }
-- @return dropdown frame
function Compat.CreateDropdown(parent, name, width, preferModern)
	width = width or 150
	local forceLegacy = type(preferModern) == "table" and preferModern.forceLegacy == true
	local shouldUseModern = not forceLegacy and (BFL.HasModernDropdown or preferModern == true)

	if shouldUseModern and Compat.CanCreateModernDropdown() then
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

function Compat.CanCreateModernDropdown()
	local capabilities = BFL.Capabilities
	return (capabilities ~= nil and capabilities.ModernDropdown == true)
		or (type(DropdownButtonMixin) == "table" and type(DropdownButtonMixin.SetupMenu) == "function")
end

function Compat.IsModernDropdown(dropdown)
	return HasFrameMethod(dropdown, "SetupMenu")
end

function Compat.ShouldUseLegacyDropdown(dropdown)
	return not Compat.IsModernDropdown(dropdown)
end

function Compat.SetDropdownText(dropdown, text)
	if not dropdown then
		return false
	end
	text = text or ""
	if Compat.IsModernDropdown(dropdown) then
		if dropdown.SetText then
			dropdown:SetText(text)
			return true
		elseif dropdown.Text and dropdown.Text.SetText then
			dropdown.Text:SetText(text)
			return true
		end
	elseif UIDropDownMenu_SetText then
		UIDropDownMenu_SetText(dropdown, text)
		return true
	end
	return false
end

function Compat.SetDropdownWidth(dropdown, width)
	if not (dropdown and width) then
		return false
	end
	if Compat.IsModernDropdown(dropdown) then
		if dropdown.SetWidth then
			dropdown:SetWidth(width)
			return true
		end
	elseif UIDropDownMenu_SetWidth then
		UIDropDownMenu_SetWidth(dropdown, width)
		return true
	end
	return false
end

function Compat.JustifyDropdownText(dropdown, justify)
	if not dropdown then
		return false
	end
	justify = justify or "LEFT"
	if Compat.IsModernDropdown(dropdown) then
		local textRegion = dropdown.Text or dropdown.TextRegion or dropdown.SelectionText
		if textRegion and textRegion.SetJustifyH then
			textRegion:SetJustifyH(justify)
			return true
		end
	elseif UIDropDownMenu_JustifyText then
		UIDropDownMenu_JustifyText(dropdown, justify)
		return true
	end
	return false
end

function Compat.SetDropdownSelectedValue(dropdown, value)
	if not dropdown or Compat.IsModernDropdown(dropdown) then
		return false
	end
	if UIDropDownMenu_SetSelectedValue then
		UIDropDownMenu_SetSelectedValue(dropdown, value)
		return true
	end
	return false
end

local function GetDropdownSelectionText(options, value, fallbackLabel)
	if options and type(options.getSelectionText) == "function" then
		local text = options.getSelectionText(value)
		if text ~= nil then
			return text
		end
	end
	return fallbackLabel or tostring(value or "")
end

local function IsDropdownOptionEnabled(options, value, index)
	if options and type(options.isOptionEnabled) == "function" then
		local ok, enabled = pcall(options.isOptionEnabled, value, index)
		return not ok or enabled ~= false
	end
	return true
end

local function GetDropdownOptionTooltip(options, value, index)
	if options and type(options.getOptionTooltip) == "function" then
		local ok, tooltip = pcall(options.getOptionTooltip, value, index)
		if ok and type(tooltip) == "string" and tooltip ~= "" then
			return tooltip
		end
	end
	return nil
end

-- Initialize dropdown with options
-- @param dropdown: The dropdown frame
-- @param options: Table with { labels = {...}, values = {...} }
--   Optional isOptionEnabled(value, index) and getOptionTooltip(value, index)
--   keep unavailable entries visible but non-interactive with an explanation.
-- @param getter: Function(value) -> boolean (is this value selected?)
-- @param setter: Function(value) called when selection changes
-- @param scrollHeight: Optional max pixel height before the dropdown scrolls (Retail only)
function Compat.InitializeDropdown(dropdown, options, getter, setter, scrollHeight)
	options = options or {}
	if Compat.IsModernDropdown(dropdown) then
		if options.getCombinedSelectionText and dropdown.SetSelectionText then
			dropdown:SetSelectionText(options.getCombinedSelectionText)
		elseif dropdown.SetSelectionTranslator then
			dropdown:SetSelectionTranslator(function(selection)
				return GetDropdownSelectionText(options, selection and selection.data, selection and selection.text)
			end)
		end
		dropdown:SetupMenu(function(dropdown, rootDescription)
			if scrollHeight and rootDescription.SetScrollMode then
				rootDescription:SetScrollMode(scrollHeight)
			end
			if type(options.populateRootDescription) == "function" then
				options.populateRootDescription(rootDescription, dropdown)
			else
				local labels = options.labels or {}
				local values = options.values or {}
				for i, label in ipairs(labels) do
					local value = values[i]
					if not (type(options.isOptionHidden) == "function" and options.isOptionHidden(value, i)) then
						local element = rootDescription:CreateRadio(label, getter, setter, value)
						local enabled = IsDropdownOptionEnabled(options, value, i)
						if element and element.SetEnabled then
							element:SetEnabled(enabled)
						end
						local tooltip = not enabled and GetDropdownOptionTooltip(options, value, i) or nil
						if tooltip and element and element.SetTooltip then
							element:SetTooltip(function(menuTooltip)
								menuTooltip:SetText(label, 1, 1, 1)
								menuTooltip:AddLine(tooltip, 1, 0.25, 0.25, true)
							end)
						end
						if type(options.getItemFontObject) == "function" and element and element.AddInitializer then
							local fontObject = options.getItemFontObject(value, i)
							if fontObject then
								element:AddInitializer(function(button)
									if button.fontString then
										button.fontString:SetFontObject(fontObject)
									end
								end)
							end
						end
					end
				end
			end
		end)
	else
		-- Classic: UIDropDownMenu
		UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
			level = level or 1
			if type(options.populateRootDescription) == "function" then
				local menuItems = menuList
				if level == 1 then
					local rootDescription
					rootDescription, menuItems = CreateClassicMenuDescription()
					options.populateRootDescription(rootDescription, dropdown)
				end
				for _, item in ipairs(menuItems or {}) do
					local info = UIDropDownMenu_CreateInfo()
					for key, value in pairs(item) do
						info[key] = value
					end
					UIDropDownMenu_AddButton(info, level)
				end
				return
			end
			local labels = options.labels or {}
			local values = options.values or {}
			for i, label in ipairs(labels) do
				local capturedValue = values[i]
				if not (options and type(options.isOptionHidden) == "function" and options.isOptionHidden(capturedValue, i)) then
					local info = UIDropDownMenu_CreateInfo()
					info.text = label
					local capturedLabel = label
					info.value = capturedValue
					info.checked = getter(capturedValue)
					if options and type(options.getItemFontObject) == "function" then
						info.fontObject = options.getItemFontObject(capturedValue, i)
					end
					local enabled = IsDropdownOptionEnabled(options, capturedValue, i)
					if not enabled then
						info.disabled = true
						local tooltip = GetDropdownOptionTooltip(options, capturedValue, i)
						if tooltip then
							info.tooltipTitle = label
							info.tooltipText = tooltip
							info.tooltipWhileDisabled = true
							info.tooltipOnButton = true
						end
					end
					info.func = function()
						-- Use closured values, NOT self.value/self:GetText()
						-- (setter may call UIDropDownMenu_Initialize on another dropdown,
						-- which overwrites DropDownList1 buttons, corrupting self)
						setter(capturedValue)
						Compat.SetDropdownSelectedValue(dropdown, capturedValue)
						Compat.SetDropdownText(dropdown, GetDropdownSelectionText(options, capturedValue, capturedLabel))
						CloseDropDownMenus()
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end)

		if type(options.populateRootDescription) == "function" then
			Compat.SetDropdownText(dropdown, GetDropdownSelectionText(options, nil, FILTER or "Filter"))
			return
		end

		-- Set initial selection
		for i, value in ipairs(options.values or {}) do
			if getter(value) and not (options and type(options.isOptionHidden) == "function" and options.isOptionHidden(value, i)) then
				Compat.SetDropdownSelectedValue(dropdown, value)
				Compat.SetDropdownText(dropdown, GetDropdownSelectionText(options, value, options.labels[i]))
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
-- @param scrollHeight: Optional max pixel height before the dropdown scrolls (Retail only)
function Compat.InitializeMultiSelectDropdown(dropdown, options, getter, setter, textFunc, scrollHeight)
	if Compat.IsModernDropdown(dropdown) then
		dropdown:SetupMenu(function(dropdown, rootDescription)
			if scrollHeight and rootDescription.SetScrollMode then
				rootDescription:SetScrollMode(scrollHeight)
			end
			for i, label in ipairs(options.labels) do
				local value = options.values[i]
				local element = rootDescription:CreateCheckbox(label, function()
					return getter(value)
				end, function()
					setter(value, not getter(value))
				end)
				if element then
					if element.SetCloseOnClick then
						element:SetCloseOnClick(false)
					end
					if options and type(options.getItemFontObject) == "function" and element.AddInitializer then
						local fontObject = options.getItemFontObject(value, i)
						if fontObject then
							element:AddInitializer(function(button)
								if button.fontString then
									button.fontString:SetFontObject(fontObject)
								end
							end)
						end
					end
				end
			end
		end)
		-- Use SetDefaultText as fallback, and SetSelectionText for dynamic updates.
		if dropdown.SetDefaultText then
			dropdown:SetDefaultText(textFunc())
		end
		if dropdown.SetSelectionText then
			dropdown:SetSelectionText(function()
				return textFunc()
			end)
		end
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
				if options and type(options.getItemFontObject) == "function" then
					info.fontObject = options.getItemFontObject(capturedValue, i)
				end
				info.checked = function()
					return getter(capturedValue)
				end
				info.func = function(self)
					local newChecked = not getter(capturedValue)
					setter(capturedValue, newChecked)
					Compat.SetDropdownText(dropdown, textFunc())
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end)

		-- Set initial text
		Compat.SetDropdownText(dropdown, textFunc())
	end
end

-- Refresh a dropdown's menu state or displayed text after programmatic value change
-- @param dropdown: The dropdown frame
-- @param text: Optional text to display
function Compat.RefreshDropdown(dropdown, text)
	if not dropdown then
		return false
	end

	if Compat.IsModernDropdown(dropdown) then
		if text ~= nil then
			Compat.SetDropdownText(dropdown, text)
		end
		if dropdown.Update then
			dropdown:Update()
			return true
		elseif dropdown.GenerateMenu then
			dropdown:GenerateMenu()
			return true
		elseif dropdown.UpdateSelections then
			dropdown:UpdateSelections()
			return true
		end
		return text ~= nil
	elseif text ~= nil then
		Compat.SetDropdownText(dropdown, text)
		Compat.SetDropdownSelectedValue(dropdown, "")
		return true
	else
		if UIDropDownMenu_Refresh then
			UIDropDownMenu_Refresh(dropdown)
			return true
		elseif UIDropDownMenu_RefreshAll then
			UIDropDownMenu_RefreshAll(dropdown)
			return true
		end
	end
	return false
end

------------------------------------------------------------
-- ColorPicker Compatibility
------------------------------------------------------------
-- Supported Retail and Classic clients: ColorPickerFrame:SetupColorPickerAndShow(info)
-- Legacy fallback: ColorPickerFrame.func = ..., ColorPickerFrame:Show()

function Compat.ShowColorPicker(r, g, b, a, callback, cancelCallback)
	if not ColorPickerFrame then
		return
	end

	if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
		-- Shared modern color picker API exists on current Retail and Classic clients.
		local info = {
			swatchFunc = function()
				local newR, newG, newB = ColorPickerFrame:GetColorRGB()
				local newA = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or a
				callback(newR, newG, newB, newA)
			end,
			cancelFunc = function()
				if cancelCallback then
					cancelCallback(r, g, b, a)
				end
			end,
			opacityFunc = function()
				local newR, newG, newB = ColorPickerFrame:GetColorRGB()
				local newA = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or a
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
		-- Legacy fallback for clients without SetupColorPickerAndShow.
		ColorPickerFrame.func = function()
			local newR, newG, newB = ColorPickerFrame:GetColorRGB()
			local newA = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or a
			callback(newR, newG, newB, newA)
		end
		ColorPickerFrame.cancelFunc = function()
			if cancelCallback then
				cancelCallback(r, g, b, a)
			end
		end
		ColorPickerFrame.hasOpacity = (a ~= nil)
		if a then
			ColorPickerFrame.opacity = a
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

local function SafeBooleanAPICall(apiFunction, fallback, ...)
	if type(apiFunction) ~= "function" then
		return fallback == true
	end
	local ok, value = pcall(apiFunction, ...)
	if not ok or (BFL.IsSecret and BFL:IsSecret(value)) then
		return fallback == true
	end
	return value == true
end

-- These checks do not grant secure execution or a hardware event. Callers must
-- still satisfy each API's restrictions; this helper never queues an action.
function Compat.IsSocialActionRestricted()
	if InCombatLockdown and InCombatLockdown() then
		return true
	end
	if BFL.IsActionRestricted then
		local ok, restricted = pcall(BFL.IsActionRestricted, BFL)
		return not ok or (BFL.IsSecret and BFL:IsSecret(restricted)) or restricted == true
	end
	return false
end

function Compat.IsRaidListSupported()
	local api = C_PartyInfo and C_PartyInfo.IsRaidListSupported
	return type(api) ~= "function" or SafeBooleanAPICall(api, false)
end

function Compat.IsRaidListEnabled()
	local api = C_PartyInfo and C_PartyInfo.IsRaidListEnabled
	return type(api) ~= "function" or SafeBooleanAPICall(api, false)
end

function Compat.CanPromoteToLeader()
	local api = C_PartyInfo and C_PartyInfo.CanPromoteToLeader
	return type(api) ~= "function" or SafeBooleanAPICall(api, false)
end

function Compat.AreRealIDFriendsEnabled()
	if C_BattleNet and type(C_BattleNet.AreRealIDFriendsEnabled) == "function" then
		return SafeBooleanAPICall(C_BattleNet.AreRealIDFriendsEnabled, false)
	end
	-- BNGetInfo's seventh return is the legacy Real ID capability.
	if type(BNGetInfo) == "function" then
		local ok, _, _, _, _, _, _, enabled = pcall(BNGetInfo)
		return ok and not (BFL.IsSecret and BFL:IsSecret(enabled)) and enabled == true
	end
	return false
end

function Compat.GetBNetFriendLevelLabel(friendLevel)
	if BFL.IsSecret and BFL:IsSecret(friendLevel) then
		return nil
	end
	local levels = Enum and Enum.BattleNetFriendLevel
	if type(friendLevel) ~= "number" or not levels then
		return nil
	end
	if levels.Title and friendLevel == levels.Title then
		return BFL.L.FRIEND_TYPE_WOW
	elseif levels.BattleTag and friendLevel == levels.BattleTag then
		return BFL.L.FRIEND_TYPE_BATTLETAG
	elseif levels.RealID and friendLevel == levels.RealID then
		return BFL.L.FRIEND_TYPE_REAL_ID
	end
	return nil
end

-- Forever moved Battle.net block mutations into C_BattleNet. Keep the legacy
-- global only as an older-client fallback and contain restricted/secret input.
function Compat.CanSetBNetBlocked()
	return (C_BattleNet and type(C_BattleNet.SetBlocked) == "function")
		or type(BNSetBlocked) == "function"
end

function Compat.SetBNetBlocked(bnetIDAccount, blocked)
	if Compat.IsSocialActionRestricted()
		or (BFL.IsSecret and (BFL:IsSecret(bnetIDAccount) or BFL:IsSecret(blocked)))
		or bnetIDAccount == nil
	then
		return false
	end
	if type(bnetIDAccount) == "string" then
		bnetIDAccount = tonumber(bnetIDAccount)
	end
	if type(bnetIDAccount) ~= "number" or bnetIDAccount <= 0 or bnetIDAccount % 1 ~= 0 then
		return false
	end
	local setter = C_BattleNet and C_BattleNet.SetBlocked or BNSetBlocked
	if type(setter) ~= "function" then
		return false
	end
	local ok = pcall(setter, bnetIDAccount, blocked == true)
	return ok == true
end

-- Native Classic FriendsFrame forbids cross-realm invites in every Classic
-- flavor. Camelot uses Mainline rules instead, so it must not inherit that gate.
function Compat.IsBNetInviteRealmRestricted(gameAccountInfo, playerRealmID)
	if not gameAccountInfo or not playerRealmID then
		return false
	end
	return BFL.IsClassic == true and gameAccountInfo.realmID ~= playerRealmID
end

-- Older FriendsFrame helpers depend on faction/realm locals initialized by
-- its OnShow. BFL keeps that frame hidden, so prefer the stateless native API.
local IsReadableGameAccountInfo
function Compat.GetBNetInviteTooltipInfo(friendIndex)
	local util = FriendsListUtil
	local restrictionTypes = BattleNetFriendPartyInviteRestrictionType
	local restrictionPriority = BattleNetFriendPartyInviteRestrictionPriority
	if not util or type(util.GetBattleNetFriendInviteInfo) ~= "function"
		or type(util.GetGameAccountPartyInviteRestriction) ~= "function"
		or type(util.GetBattleNetFriendPartyInviteRestrictionText) ~= "function"
		or not restrictionTypes or not restrictionPriority
		or not C_BattleNet or not C_BattleNet.GetFriendNumGameAccounts or not C_BattleNet.GetFriendGameAccountInfo
	then
		return nil
	end
	local ok, info = pcall(util.GetBattleNetFriendInviteInfo, friendIndex)
	local restrictionOK, restrictionText, selectedAccount = pcall(function()
		-- A valid account wins; otherwise show the highest-priority native reason.
		-- Do not seed with None: Retail's aggregate helper can mask real blocks.
		local restriction = restrictionTypes.NoGameAccounts
		local selectedText
		local priority = restrictionPriority[restriction] or 0
		for accountIndex = 1, C_BattleNet.GetFriendNumGameAccounts(friendIndex) do
			local accountInfo = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)
			local accountRestriction = util.GetGameAccountPartyInviteRestriction(accountInfo)
			local customReason
			if BFL.IsForever and IsReadableGameAccountInfo(accountInfo) then
				local faction = accountInfo.factionName
				local playerOK, playerFaction = false, nil
				if type(UnitFactionGroup) == "function" then playerOK, playerFaction = pcall(UnitFactionGroup, "player") end
				local readableFactions = playerOK and not (BFL.IsSecret and (BFL:IsSecret(faction) or BFL:IsSecret(playerFaction)))
					and type(faction) == "string" and type(playerFaction) == "string"
					and faction ~= "" and playerFaction ~= ""
				if accountRestriction == restrictionTypes.None and readableFactions and faction ~= playerFaction then
					accountRestriction = restrictionTypes.Faction
				end
				if accountRestriction == restrictionTypes.None then
					customReason = Compat.GetForeverRulesetInviteRestriction(accountInfo)
					if customReason then accountRestriction = BFL.INVITE_RESTRICTION_RULESET end
				end
			end
			if accountRestriction == restrictionTypes.None then
				return "", accountInfo
			end
			local accountPriority = customReason and (restrictionPriority[restrictionTypes.IncompatibleGameMode] or 12)
				or (restrictionPriority[accountRestriction] or 0)
			if accountPriority > priority then
				restriction = accountRestriction
				priority, selectedText = accountPriority, customReason
			end
		end
		return selectedText or util.GetBattleNetFriendPartyInviteRestrictionText(restriction)
	end)
	if not ok or not IsReadableGameAccountInfo(info) or not restrictionOK then
		return nil
	end
	if BFL.IsForever and IsReadableGameAccountInfo(selectedAccount) then
		-- The native selector only prefers faction. Choose the account that also
		-- passed the ruleset check, without modifying its native snapshot or info.
		local guid, faction = selectedAccount.playerGuid, selectedAccount.factionName
		if BFL.IsSecret and (BFL:IsSecret(guid) or BFL:IsSecret(faction)) then return nil end
		local inviteType
		if type(GetDisplayedInviteType) == "function" then
			local typeOK, value = pcall(GetDisplayedInviteType, guid)
			if typeOK and not (BFL.IsSecret and BFL:IsSecret(value)) and type(value) == "string" then inviteType = value end
		end
		local nativeGUID, nativeType = info.playerGUID, info.inviteType
		if not inviteType and not (BFL.IsSecret and (BFL:IsSecret(nativeGUID) or BFL:IsSecret(nativeType)))
			and nativeGUID == guid and type(nativeType) == "string"
		then inviteType = nativeType end
		info = { inviteType = inviteType, playerGUID = guid, factionName = faction,
			isCrossFaction = false, gameAccountID = selectedAccount.gameAccountID }
	end
	return info, restrictionText
end

function Compat.CanBlockBNetFriendInvite(friendLevel)
	if BFL.IsSecret and BFL:IsSecret(friendLevel) then
		return false
	end
	local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
	if titleLevel == nil then
		return true -- Older clients do not publish friend-level metadata.
	end
	return type(friendLevel) == "number" and friendLevel ~= titleLevel
end

function Compat.CanBlockBNetAccount(accountInfo)
	if not accountInfo or (BFL.IsSecret and BFL:IsSecret(accountInfo.bnetAccountID)) then
		return false
	end
	return accountInfo.bnetAccountID ~= nil and Compat.CanBlockBNetFriendInvite(accountInfo.friendLevel)
end

-- Revalidate the index and ID when a menu action runs: request indices can
-- move while the menu is open, and cached metadata must not authorize a block.
function Compat.CanBlockBNetFriendInviteByIndex(inviteIndex, expectedInviteID)
	if (BFL.IsSecret and (BFL:IsSecret(inviteIndex) or BFL:IsSecret(expectedInviteID)))
		or not inviteIndex or not expectedInviteID
	then
		return false
	end
	local ok, info = pcall(Compat.GetBNetFriendInviteInfo, inviteIndex)
	if not ok or not info or (BFL.IsSecret and BFL:IsSecret(info.inviteID)) then
		return false
	end
	return info.inviteID == expectedInviteID and Compat.CanBlockBNetFriendInvite(info.friendLevel)
end

function Compat.IsAgeVerificationRestricted()
	local api = C_SocialRestrictions and C_SocialRestrictions.IsAgeVerificationRestricted
	if type(api) ~= "function" then
		return false
	end
	local ok, restricted = pcall(api)
	if not ok or (BFL.IsSecret and BFL:IsSecret(restricted)) then
		-- The capability exists, so an unreadable restriction state must not
		-- open a communication path that Blizzard may have disabled.
		return true
	end
	return restricted == true
end

function Compat.IsAgeVerificationRestrictedMinor()
	if not Compat.IsAgeVerificationRestricted() then
		return false
	end
	local api = C_SocialRestrictions and C_SocialRestrictions.IsAgeVerificationRestrictedMinor
	return SafeBooleanAPICall(api, false)
end

function Compat.GetAgeVerificationRestrictionTooltip()
	if not Compat.IsAgeVerificationRestricted() then
		return nil
	end
	if Compat.IsAgeVerificationRestrictedMinor() then
		return AGE_RESTRICTED_CHAT_MINOR_TOOLTIP or CHAT_DISABLED
	end
	return AGE_RESTRICTED_CHAT_UNVERIFIED_TOOLTIP or CHAT_DISABLED
end

function Compat.CanSendWhisper()
	return not Compat.IsAgeVerificationRestricted()
end

function Compat.AreRegionalUniqueNamesEnabled()
	return SafeBooleanAPICall(RegionalUniqueNamesEnabled, false)
end

local function IsSafeNameValue(value)
	return not (BFL.IsSecret and BFL:IsSecret(value))
		and type(value) == "string"
		and value ~= ""
end

IsReadableGameAccountInfo = function(info)
	if (BFL.IsSecret and BFL:IsSecret(info)) or type(info) ~= "table" then
		return false
	end
	if type(issecrettable) == "function" then
		local ok, secret = pcall(issecrettable, info)
		if not ok or (BFL.IsSecret and BFL:IsSecret(secret)) or secret then
			return false
		end
	end
	return true
end

-- Camelot's ProjectConstants.lua defines 18. Retail does not necessarily load
-- WOW_PROJECT_CAMELOT, but can still receive a Forever friend's game account.
local FOREVER_PROJECT_ID = WOW_PROJECT_CAMELOT or 18
local FOREVER_RULESET_TOKENS = { "PVP", "PVE", "RP" }
local FOREVER_RULESET_LABEL_KEYS = {
	PVE = "RULESET_TYPE_NORMAL", PVP = "RULESET_TYPE_PVP",
	RP = "RULESET_TYPE_RP", RPPVP = "RULESET_TYPE_RPPVP",
}
local FOREVER_PRESENCE_RULESET_TOKENS = {
	NORMAL = "PVE", PVE = "PVE", PVP = "PVP", RP = "RP",
	RPPVP = "RPPVP", ["RP-PVP"] = "RPPVP", ["RP PVP"] = "RPPVP",
}
-- BFL's own restriction values 0..13 are used by its invite UI. Do not extend
-- Blizzard's BattleNetFriendPartyInviteRestrictionType or priority tables.
BFL.INVITE_RESTRICTION_RULESET = 14

local function HasForeverRulesetToken(text, token)
	return text:find("%f[%w_]" .. token .. "%f[^%w_]") ~= nil
end

function Compat.IsWoWAccountRulesetLocation(gameAccountInfo)
	if not IsReadableGameAccountInfo(gameAccountInfo) then
		return BFL.IsForever == true
	end
	local projectID = gameAccountInfo.wowProjectID
	if (BFL.IsSecret and BFL:IsSecret(projectID)) or projectID == nil then
		return BFL.IsForever == true
	end
	return projectID == FOREVER_PROJECT_ID
end

local function GetForeverRealmRuleset(realmName)
	if not IsSafeNameValue(realmName) then
		return nil
	end
	local text = realmName:upper()
	-- GetNormalizedRealmName removes spaces, including those around the type.
	-- Accept only the observed CAMWOW + region/shard + Realm + number shape.
	local normalizedType = text:match("^CAMWOW[A-Z]+%d+REALM%d+([A-Z]+)$")
	if normalizedType == "RPPVP" or normalizedType == "PVP"
		or normalizedType == "PVE" or normalizedType == "RP"
	then
		return normalizedType
	end
	-- Match the complete combined token before the shorter RP/PVP tokens.
	if HasForeverRulesetToken(text, "RPPVP") or HasForeverRulesetToken(text, "RP%-PVP")
		or HasForeverRulesetToken(text, "RP%s+PVP")
	then
		return "RPPVP"
	end
	local result
	for _, token in ipairs(FOREVER_RULESET_TOKENS) do
		if HasForeverRulesetToken(text, token) then
			if result then return nil end -- Conflicting types are not evidence.
			result = token
		end
	end
	return result
end

local function GetForeverPresenceRuleset(richPresence)
	if not IsSafeNameValue(richPresence) then return nil end
	-- Retail also receives the user-observed "Forever · Normal · Ashenvale"
	-- form without any realm fields. Read only its explicit ruleset segment.
	if #richPresence <= 2048 and not richPresence:find("[%c]") then
		local normalized = richPresence:gsub("%s+·%s+", " - ")
		local prefix, ruleset, area = normalized:match("^%s*(.-)%s+%-%s+(.-)%s+%-%s+(.+)$")
		if prefix and prefix:upper() == "FOREVER" and not area:find(" - ", 1, true) then
			ruleset = ruleset:match("^%s*(.-)%s*$")
			area = area:match("^%s*(.-)%s*$")
			local token = FOREVER_PRESENCE_RULESET_TOKENS[ruleset:upper()]
			if token and area ~= "" then return token, ruleset, area end
		end
	end
	-- FriendsList already reads "Zone - Realm" from this target's own native
	-- rich presence. Accept only a CAMWOW realm suffix, never arbitrary PvP text
	-- in an area/status or a caller's fallback realm (which may be unrelated).
	local start, _, normalizedRealm = richPresence:upper():find(" %- (CAMWOW.+)$")
	if normalizedRealm and (normalizedRealm:match("^CAMWOW%s+[A-Z]+%d+%s+REALM%s+%d+%s+")
		or normalizedRealm:match("^CAMWOW[A-Z]+%d+REALM%d+"))
	then
		local token = GetForeverRealmRuleset(normalizedRealm)
		if token then return token, richPresence:sub(start + 3) end
	end
	return nil
end

local function GetForeverAccountRuleset(gameAccountInfo)
	local realm = gameAccountInfo.realmName
	local token = GetForeverRealmRuleset(realm)
	local area
	if not token then
		realm = gameAccountInfo.realmDisplayName
		token = GetForeverRealmRuleset(realm)
	end
	if not token then
		token, realm, area = GetForeverPresenceRuleset(gameAccountInfo.richPresence)
	end
	return token, realm, area
end

-- Display only. Ignore a recognized Forever status when the account's project
-- already identifies another WoW client, even if its area is still missing.
function Compat.GetGameAccountRichPresence(gameAccountInfo)
	if not IsReadableGameAccountInfo(gameAccountInfo) then return nil end
	local presence = gameAccountInfo.richPresence
	if not IsSafeNameValue(presence) then return nil end
	local project, client = gameAccountInfo.wowProjectID, gameAccountInfo.clientProgram
	if BFL.IsSecret and (BFL:IsSecret(project) or BFL:IsSecret(client)) then return nil end
	if client == (BNET_CLIENT_WOW or "WoW") and type(project) == "number"
		and project ~= FOREVER_PROJECT_ID and GetForeverPresenceRuleset(presence)
	then return nil end
	return presence
end

local function GetForeverRulesetLabel(gameAccountInfo)
	local token, realm, area = GetForeverAccountRuleset(gameAccountInfo)
	-- RealmList's native labels belong to GlueXML and are not guaranteed in
	-- the in-game addon environment. Use BFL's always-loaded locale catalog.
	local key = token and FOREVER_RULESET_LABEL_KEYS[token]
	local label = key and BFL.L and BFL.L[key]
	if IsSafeNameValue(label) then return label, realm, area end
	return "", nil
end

local function IsReadableAccountID(value)
	return not (BFL.IsSecret and BFL:IsSecret(value)) and type(value) == "number"
		and value > 0 and value < math.huge and value % 1 == 0
end

local function ReadPlayerForeverRuleset(getter)
	if type(getter) ~= "function" then return nil end
	local ok, realm = pcall(getter)
	return ok and GetForeverRealmRuleset(realm) or nil
end

local function GetPlayerForeverRuleset()
	return ReadPlayerForeverRuleset(GetRealmName) or ReadPlayerForeverRuleset(GetNormalizedRealmName)
end

-- Default calls only inspect the supplied target snapshot. Dispatch callers
-- request a fresh account record and must use its fourth return for identity
-- and native restrictions; a missing record is not proof of availability.
function Compat.GetForeverRulesetInviteRestriction(gameAccountInfo, refresh)
	if BFL.IsForever ~= true then return nil, nil, nil, gameAccountInfo end
	if not IsReadableGameAccountInfo(gameAccountInfo) then return nil end
	local current = gameAccountInfo
	if refresh then
		local id = current.gameAccountID
		local getter = C_BattleNet and C_BattleNet.GetGameAccountInfoByID
		if not IsReadableAccountID(id) or type(getter) ~= "function" then return nil end
		local ok, record = pcall(getter, id)
		if not ok or not IsReadableGameAccountInfo(record) then return nil end
		local currentID = record.gameAccountID
		if not IsReadableAccountID(currentID) or currentID ~= id then return nil end
		current = record
	end
	local project, client = current.wowProjectID, current.clientProgram
	if (BFL.IsSecret and (BFL:IsSecret(project) or BFL:IsSecret(client)))
		or client ~= (BNET_CLIENT_WOW or "WoW")
		or (project ~= nil and project ~= FOREVER_PROJECT_ID)
	then return nil, nil, nil, current end
	local targetToken = GetForeverAccountRuleset(current)
	if not targetToken then return nil, nil, nil, current end
	local playerToken = GetPlayerForeverRuleset()
	if not playerToken or targetToken == playerToken then return nil, targetToken, playerToken, current end
	local L = BFL.L or {}
	return L.INVITE_RESTRICTION_RULESET, targetToken, playerToken, current
end

-- Additional BFL guard, not server authorization. Never switch a captured
-- character to another character that has since occupied its game account.
function Compat.ValidateForeverInviteTarget(gameAccountInfo)
	if BFL.IsForever ~= true then return true, nil, gameAccountInfo end
	local noInfo = IsSafeNameValue(ERR_TRAVEL_PASS_NO_INFO) and ERR_TRAVEL_PASS_NO_INFO or nil
	if not IsReadableGameAccountInfo(gameAccountInfo) then return false, noInfo end
	local reason, _, _, current = Compat.GetForeverRulesetInviteRestriction(gameAccountInfo, true)
	if not current then return false, noInfo end
	local capturedGUID, currentGUID = gameAccountInfo.playerGuid, current.playerGuid
	if BFL.IsSecret and (BFL:IsSecret(capturedGUID) or BFL:IsSecret(currentGUID)) then return false, noInfo end
	if not IsSafeNameValue(capturedGUID) or currentGUID ~= capturedGUID then return false, noInfo end
	local client, project, online = current.clientProgram, current.wowProjectID, current.isOnline
	if (BFL.IsSecret and (BFL:IsSecret(client) or BFL:IsSecret(project) or BFL:IsSecret(online)))
		or client ~= (BNET_CLIENT_WOW or "WoW")
		or online ~= true
		or (project ~= nil and project ~= FOREVER_PROJECT_ID)
	then return false, noInfo end
	local capturedProject = gameAccountInfo.wowProjectID
	if not (BFL.IsSecret and BFL:IsSecret(capturedProject)) and capturedProject ~= nil
		and project ~= nil and project ~= capturedProject
	then return false, noInfo end
	local faction = current.factionName
	local ok, playerFaction
	if type(UnitFactionGroup) == "function" then ok, playerFaction = pcall(UnitFactionGroup, "player") end
	if ok and not (BFL.IsSecret and (BFL:IsSecret(faction) or BFL:IsSecret(playerFaction)))
		and IsSafeNameValue(faction) and IsSafeNameValue(playerFaction) and faction ~= playerFaction
	then
		return false, IsSafeNameValue(ERR_TRAVEL_PASS_NOT_ALLIED) and ERR_TRAVEL_PASS_NOT_ALLIED or nil, current
	end
	if reason then return false, reason, current end
	if type(BFL.GetModule) == "function" then
		local modelOK, model = pcall(BFL.GetModule, BFL, "FriendsList")
		if not modelOK or (BFL.IsSecret and BFL:IsSecret(model)) then return false, noInfo, current end
		if model ~= nil then
			if not IsReadableGameAccountInfo(model) then return false, noInfo, current end
			local checker = model.GetGameAccountInviteRestriction
			if type(checker) == "function" then
				-- This production checker uses the pure ruleset helper, not this
				-- validator. Reapply native eligibility to the refreshed account.
				local checked, restriction, detail = pcall(checker, model, current)
				if not checked or (BFL.IsSecret and BFL:IsSecret(restriction)) or type(restriction) ~= "number" then
					return false, noInfo, current
				end
				if restriction ~= 0 then
					local text = IsSafeNameValue(detail) and detail or nil
					if not text and type(BFL.GetInviteRestrictionText) == "function" then
						local textOK, value = pcall(BFL.GetInviteRestrictionText, restriction)
						if textOK and IsSafeNameValue(value) then text = value end
					end
					return false, text or noInfo, current
				end
			end
		end
	end
	return true, nil, current
end

-- Display only: never substitute this result for a realm in character names,
-- contact keys, invites or account identity. Forever publishes no target
-- ruleset field; recognize the user-verified type tokens in that account's
-- own realm or structured presence text instead. The optional fourth result
-- is that presence's area. Unknown text stays empty, without player-rule data.
function Compat.GetWoWAccountLocation(gameAccountInfo, fallbackRealm)
	local kind = Compat.IsWoWAccountRulesetLocation(gameAccountInfo) and "ruleset" or "realm"
	if BFL.IsSecret and BFL:IsSecret(gameAccountInfo) then
		return "", kind
	end
	if gameAccountInfo ~= nil then
		if not IsReadableGameAccountInfo(gameAccountInfo) then
			return "", kind
		end
		local projectID, client = gameAccountInfo.wowProjectID, gameAccountInfo.clientProgram
		if (BFL.IsSecret and (BFL:IsSecret(projectID) or BFL:IsSecret(client)))
			or (projectID ~= nil and type(projectID) ~= "number")
			or (client ~= nil and client ~= (BNET_CLIENT_WOW or "WoW"))
		then
			return "", kind
		end
	end
	if kind == "ruleset" then
		local label, realm, area
		if gameAccountInfo then label, realm, area = GetForeverRulesetLabel(gameAccountInfo) end
		return label or "", kind, realm, area
	end
	if gameAccountInfo then
		if IsSafeNameValue(gameAccountInfo.realmDisplayName) then
			return gameAccountInfo.realmDisplayName, kind
		end
		if IsSafeNameValue(gameAccountInfo.realmName) then
			return gameAccountInfo.realmName, kind
		end
	end
	return IsSafeNameValue(fallbackRealm) and fallbackRealm or "", kind
end

-- Display only; do not use this to rewrite GUIDs, contact keys or whisper IDs.
function Compat.FormatPlayerDisplayName(name, realmName, separator)
	if not IsSafeNameValue(name) then
		return nil
	end
	if Compat.AreRegionalUniqueNamesEnabled() or not IsSafeNameValue(realmName) then
		return name
	end
	if separator then
		return name .. separator .. realmName
	end
	local ok, fullName = pcall(string.format, FULL_PLAYER_NAME or "%s-%s", name, realmName)
	return ok and fullName or name
end

function Compat.GetCopyCharacterName(name, realmName, surname)
	if not IsSafeNameValue(name) then
		return nil
	end
	if Compat.AreRegionalUniqueNamesEnabled() then
		if IsSafeNameValue(surname) and not name:find("-", 1, true) then
			if NameUtil and type(NameUtil.GetFullNameWithoutRealm) == "function" then
				local ok, fullName = pcall(NameUtil.GetFullNameWithoutRealm, name, surname)
				if ok and IsSafeNameValue(fullName) and fullName ~= name then
					return fullName
				end
			end
			return name .. "-" .. surname
		end
		return name
	end
	if name:find("-", 1, true) then
		return name
	end
	return Compat.FormatPlayerDisplayName(name, realmName)
end

function Compat.GetBNetRemoveFriendPrompt(accountInfo, displayName)
	if not IsSafeNameValue(displayName) then
		return nil
	end
	local confirmation = BFL.L.DIALOG_REMOVE_FRIEND_CONFIRMATION
	if accountInfo and not (BFL.IsSecret and BFL:IsSecret(accountInfo)) then
		local levels = Enum and Enum.BattleNetFriendLevel
		local level = accountInfo.friendLevel
		local isBattleTag = accountInfo.isBattleTagFriend
		local safeLevel = not (BFL.IsSecret and BFL:IsSecret(level)) and type(level) == "number"
		local safeBattleTag = not (BFL.IsSecret and BFL:IsSecret(isBattleTag)) and type(isBattleTag) == "boolean"
		if safeLevel and levels and levels.Title and level == levels.Title then
			confirmation = REMOVE_TITLE_FRIEND_CONFIRMATION or confirmation
		elseif (safeLevel and levels and levels.BattleTag and level == levels.BattleTag)
			or (safeBattleTag and isBattleTag)
		then
			confirmation = BATTLETAG_REMOVE_FRIEND_CONFIRMATION or confirmation
		elseif (safeLevel and levels and levels.RealID and level == levels.RealID)
			or (safeBattleTag and not isBattleTag and not (levels and levels.Title))
		then
			confirmation = REMOVE_FRIEND_CONFIRMATION or confirmation
		end
	end
	local ok, prompt = pcall(string.format, confirmation, displayName)
	return ok and prompt or displayName
end

local function TrimNameValue(value)
	if not IsSafeNameValue(value) then
		return nil
	end
	value = value:match("^%s*(.-)%s*$")
	return value ~= "" and value or nil
end

local function GetSurnameSeparator()
	local separators = Constants and Constants.CharacterNameSeparatorConsts
	local separator = separators and separators.CHARACTERNAME_SURNAME_SEPARATOR
	return IsSafeNameValue(separator) and separator or "-"
end

-- Use the client's surname separator, including when callers pass a display
-- name with whitespace or an older manually stored First-Last spelling.
local function NormalizeRegionalName(name, surname)
	local firstName, lastName = name:match("^([^%s%-]+)%s+([^%s%-]+)$")
	if not firstName then
		firstName, lastName = name:match("^([^%s%-]+)%-([^%s%-]+)$")
	end
	if firstName then
		name, surname = firstName, lastName
	elseif name:find("%s") or name:find("-", 1, true) then
		return name
	end
	if surname then
		if NameUtil and type(NameUtil.GetFullNameWithoutRealm) == "function" then
			local ok, fullName = pcall(NameUtil.GetFullNameWithoutRealm, name, surname)
			if ok and IsSafeNameValue(fullName) and fullName ~= name then
				return fullName
			end
		end
		return name .. GetSurnameSeparator() .. surname
	end
	return name
end

function Compat.GetUnmodifiedUnitFullName(unit)
	if NameUtil and type(NameUtil.GetUnmodifiedUnitFullName) == "function" then
		local ok, fullName = pcall(NameUtil.GetUnmodifiedUnitFullName, unit)
		if ok and IsSafeNameValue(fullName) then
			return fullName
		end
	end
	if type(UnitNameUnmodified) ~= "function" then
		return nil
	end
	local ok, name, realmOrSurname = pcall(UnitNameUnmodified, unit)
	if not ok or not IsSafeNameValue(name) then
		return nil
	end
	if IsSafeNameValue(realmOrSurname) then
		return Compat.NormalizePlayerName(name, realmOrSurname)
	end
	return name
end

-- Return only an actual realm as the second value. On regional-unique-name
-- clients the second name part is a surname, so the full identity stays intact.
function Compat.SplitPlayerName(fullName)
	fullName = TrimNameValue(fullName)
	if not fullName then
		return nil, nil
	end
	if Compat.AreRegionalUniqueNamesEnabled() then
		return NormalizeRegionalName(fullName), nil
	end
	if NameUtil and type(NameUtil.SplitPlayerNameIntoParts) == "function" then
		local ok, name, realm = pcall(NameUtil.SplitPlayerNameIntoParts, fullName)
		if ok and IsSafeNameValue(name) and IsSafeNameValue(realm) then
			return name, realm
		end
	end
	local name, realm = fullName:match("^(.-)%-(.+)$")
	return name or fullName, realm
end

function Compat.GetPlayerNameWithoutRealm(fullName)
	local name = Compat.SplitPlayerName(fullName)
	return name
end

function Compat.ReplaceSurnameSeparatorWithLinkSeparator(fullName)
	fullName = TrimNameValue(fullName)
	if not fullName then
		return nil
	end
	local api = C_NameUtil and C_NameUtil.ReplaceSurnameSeparatorWithLinkSeparator
	if type(api) == "function" then
		local ok, converted = pcall(api, fullName)
		if ok and IsSafeNameValue(converted) then
			return converted
		end
	end
	return fullName
end

function Compat.NormalizePlayerName(name, realmOrSurname, fallbackRealm)
	name = TrimNameValue(name)
	realmOrSurname = TrimNameValue(realmOrSurname)
	if not name then
		return nil
	end

	if Compat.AreRegionalUniqueNamesEnabled() then
		return NormalizeRegionalName(name, realmOrSurname)
	end

	if name:find("-", 1, true) then
		local characterName, realmName = name:match("^(.-)%-(.+)$")
		if characterName and realmName then
			return characterName .. "-" .. realmName:gsub("%s+", "")
		end
		return name
	end

	local realm = realmOrSurname or TrimNameValue(fallbackRealm)
	if not realm and type(GetNormalizedRealmName) == "function" then
		local ok, currentRealm = pcall(GetNormalizedRealmName)
		realm = ok and TrimNameValue(currentRealm) or nil
	end
	if realm then
		return name .. "-" .. realm:gsub("%s+", "")
	end
	return name
end

function Compat.IsBattleNetFriendsListSupported()
	if not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
		return false
	end
	if C_BattleNet.IsBattleNetFriendsListSupported then
		return SafeBooleanAPICall(C_BattleNet.IsBattleNetFriendsListSupported, false)
	end
	return true
end

function Compat.IsBattleNetFriendsListEnabled()
	if not Compat.IsBattleNetFriendsListSupported() then
		return false
	end
	if C_BattleNet.IsBattleNetFriendsListEnabled then
		return SafeBooleanAPICall(C_BattleNet.IsBattleNetFriendsListEnabled, false)
	end
	return true
end

function Compat.CanSearchBattleNetFriends()
	return BFL.IsMainline == true
		and C_BattleNet ~= nil
		and type(C_BattleNet.SearchFriends) == "function"
end

function Compat.SearchBattleNetFriends(searchInfo)
	if not Compat.CanSearchBattleNetFriends() or type(searchInfo) ~= "table" then
		return nil
	end
	local ok, result = pcall(C_BattleNet.SearchFriends, searchInfo)
	if not ok or type(result) ~= "table" then
		return nil
	end
	return result
end

function Compat.AreBattleNetFriendTagsEnabled()
	if not Compat.IsBattleNetFriendsListEnabled() then
		return false
	end
	if not (BFL.IsMainline == true and C_BattleNet and type(C_BattleNet.AreFriendTagsEnabled) == "function") then
		return false
	end
	return SafeBooleanAPICall(C_BattleNet.AreFriendTagsEnabled, false)
end

function Compat.GetBNetFriendInviteInfo(inviteIndex)
	if C_BattleNet and C_BattleNet.GetFriendInviteInfo then
		return C_BattleNet.GetFriendInviteInfo(inviteIndex)
	end
	if BNGetFriendInviteInfo then
		local inviteID, accountName = BNGetFriendInviteInfo(inviteIndex)
		if inviteID then
			return {
				inviteID = inviteID,
				accountName = accountName,
			}
		end
	end
	return nil
end

------------------------------------------------------------
-- C_RecentAllies Compatibility (capability-gated Mainline)
------------------------------------------------------------
-- Midnight Standard and Forever may expose different search schemas.
-- Classic clients return empty/disabled values.

function Compat.IsRecentAlliesAvailable()
	return BFL.IsMainline == true
		and C_RecentAllies ~= nil
		and type(C_RecentAllies.IsSystemEnabled or C_RecentAllies.IsRecentAlliesEnabled) == "function"
end

function Compat.IsRecentAlliesSystemEnabled()
	if Compat.IsRecentAlliesAvailable() then
		return SafeBooleanAPICall(C_RecentAllies.IsSystemEnabled or C_RecentAllies.IsRecentAlliesEnabled, false)
	end
	return false
end

function Compat.GetRecentAllies()
	if Compat.IsRecentAlliesAvailable() and C_RecentAllies.GetRecentAllies then
		local ok, result = pcall(C_RecentAllies.GetRecentAllies)
		if ok and not (BFL.IsSecret and BFL:IsSecret(result)) and type(result) == "table" then
			return result
		end
	end
	return {} -- Empty in Classic
end

function Compat.IsRecentAllyDataReady()
	if Compat.IsRecentAlliesAvailable() and C_RecentAllies.IsRecentAllyDataReady then
		return SafeBooleanAPICall(C_RecentAllies.IsRecentAllyDataReady, true)
	end
	return true -- Return true so we don't show loading spinner forever
end

------------------------------------------------------------
-- Recruit-A-Friend Compatibility
------------------------------------------------------------
-- 12.0.7: C_RecruitAFriend.IsEnabled()
-- 12.1+:  C_RecruitAFriend.IsSystemSupported() / IsSystemEnabled()

function Compat.IsRAFSystemSupported()
	if not BFL.IsMainline or not C_RecruitAFriend then
		return false
	end
	if C_RecruitAFriend.IsSystemSupported then
		return SafeBooleanAPICall(C_RecruitAFriend.IsSystemSupported, false)
	end
	return C_RecruitAFriend.IsEnabled ~= nil
end

function Compat.IsRAFSystemEnabled()
	if not BFL.IsMainline or not C_RecruitAFriend then
		return false
	end
	if C_RecruitAFriend.IsSystemEnabled then
		return SafeBooleanAPICall(C_RecruitAFriend.IsSystemEnabled, false)
	end
	if C_RecruitAFriend.IsEnabled then
		return SafeBooleanAPICall(C_RecruitAFriend.IsEnabled, false)
	end
	return false
end

function Compat.CanSummonRAFFriend(guid)
	if not guid or not Compat.IsRAFSystemEnabled() or not (C_RecruitAFriend and C_RecruitAFriend.CanSummonFriend) then
		return false
	end
	local canSummon, reason = C_RecruitAFriend.CanSummonFriend(guid)
	return canSummon == true, reason
end

------------------------------------------------------------
-- Social Queue / Quick Join Compatibility
------------------------------------------------------------
-- 12.0.7: namespace presence means available.
-- 12.1+: use explicit system support/enabled checks.

function Compat.IsSocialQueueSupported()
	if not BFL.IsMainline or not C_SocialQueue then
		return false
	end
	if C_SocialQueue.IsSystemSupported then
		return SafeBooleanAPICall(C_SocialQueue.IsSystemSupported, false)
	end
	return C_SocialQueue.GetAllGroups ~= nil
end

function Compat.GetQuickJoinGroupFinderAccess()
	if not BFL.IsForever or not C_LFGInfo then
		return true
	end

	-- Match Blizzard's LFD micro button on Forever's premade-only Group Finder.
	local canUseGroupFinder = C_LFGInfo.CanPlayerUseGroupFinder
	local vanillaStyle = Enum and Enum.PremadeGroupFinderStyle and Enum.PremadeGroupFinderStyle.Vanilla
	if vanillaStyle ~= nil and C_LFGList and C_LFGList.GetPremadeGroupFinderStyle then
		local ok, style = pcall(C_LFGList.GetPremadeGroupFinderStyle)
		if not ok or (BFL.IsSecret and BFL:IsSecret(style)) then
			return false
		end
		if style == vanillaStyle then
			canUseGroupFinder = C_LFGInfo.CanPlayerUsePremadeGroup
		end
	end
	if not canUseGroupFinder then
		return true
	end
	local ok, canUse, reason = pcall(canUseGroupFinder)
	if not ok or (BFL.IsSecret and BFL:IsSecret(canUse)) then
		return false
	end
	return canUse == true, reason
end

function Compat.IsSocialQueueEnabled()
	if not Compat.IsSocialQueueSupported() or not Compat.GetQuickJoinGroupFinderAccess() then
		return false
	end
	if C_SocialQueue.IsSystemEnabled then
		return SafeBooleanAPICall(C_SocialQueue.IsSystemEnabled, false)
	end
	return true
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
	local capabilities = BFL.Capabilities
	if capabilities and capabilities.ModernScrollBox ~= nil then
		return capabilities.ModernScrollBox
	end
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
-- Prefer atlases only when the active client confirms they exist, then fall back
-- to file textures. This avoids XML/load-time atlas warnings in Classic while
-- still allowing modern Classic flavors to use newer art when available.

local ATLAS_FALLBACKS = {
	-- Travel Pass / Invite Button
	["friendslist-invitebutton-default-normal"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-default-pressed"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-default-disabled"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-highlight"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-horde-normal"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-horde-pressed"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-horde-disabled"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-alliance-normal"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-alliance-pressed"] = "Interface\\FriendsFrame\\TravelPass-Invite",
	["friendslist-invitebutton-alliance-disabled"] = "Interface\\FriendsFrame\\TravelPass-Invite",

	-- Group Header Arrows
	["friendslist-categorybutton-arrow-left"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-left",
	["friendslist-categorybutton-arrow-right"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right",
	["friendslist-categorybutton-arrow-down"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down",

	-- Recent Allies Pin (not available in Classic anyway)
	["friendslist-recentallies-pin"] = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon",
	["friendslist-recentallies-pin-yellow"] = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon",

	-- Modern social UI
	["communities-icon-invitemail"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\mail",
	["NewCharacter-Alliance"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\star",
	["CharacterCreate-NewLabel"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\star",
	["socialqueuing-icon-eye"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\eye",
	["friends-icon-eye"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\eye",
	["socialqueuing-icon-group"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\users",
	["friends-icon-addFriend"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-plus",
	["friends-icon-addFriend-logo-battleNet"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\star",

	-- Clock icon
	["icon-clock"] = "Interface\\Icons\\INV_Misc_PocketWatch_01",

	-- Recruit-a-Friend
	["recruitafriend_friendslist_v3_icon"] = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
	["RecruitAFriend_ClaimPane_GoldRing"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\award",
	["RecruitAFriend_ClaimPane_SepiaRing"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\circle",
	["RecruitAFriend_RecruitedFriends_CursorOverChecked"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle",
	["RecruitAFriend_RecruitedFriends_CursorOver"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\gift",
	["RecruitAFriend_RecruitedFriends_ActiveChest"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\gift",
	["RecruitAFriend_RecruitedFriends_OpenChest"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\package",
	["RecruitAFriend_RecruitedFriends_ClaimedChest"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle",
	["friends-RAF-chest-locked"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\lock",
	["friends-RAF-chest-claimed-hover"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle",
	["friends-RAF-chest-default-hover"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\gift",
	["friends-raf-chest-default"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\gift",
	["friends-raf-chest-ready"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\package",
	["friends-RAF-chest-claimed"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle",
}

local ATLAS_INFO_CACHE = {}

local function GetAtlasInfo(atlasName)
	if not atlasName or not (C_Texture and type(C_Texture.GetAtlasInfo) == "function") then
		return nil
	end
	if ATLAS_INFO_CACHE[atlasName] ~= nil then
		return ATLAS_INFO_CACHE[atlasName] or nil
	end
	local ok, info = pcall(C_Texture.GetAtlasInfo, atlasName)
	ATLAS_INFO_CACHE[atlasName] = ok and info or false
	return ok and info or nil
end

local function HasAtlas(atlasName)
	return GetAtlasInfo(atlasName) ~= nil
end

function Compat.HasAtlas(atlasName)
	return HasAtlas(atlasName)
end

function Compat.GetAtlasInfo(atlasName)
	return GetAtlasInfo(atlasName)
end

local function GetSetTextureForbiddenAspect()
	if Compat._testSetTextureForbiddenAspect ~= nil then
		return Compat._testSetTextureForbiddenAspect or nil
	end
	return Enum and Enum.ForbiddenAspect and Enum.ForbiddenAspect.SetTexture or nil
end

-- Safely mutate textures that may be owned by Blizzard or another addon.
-- Retail 12.1.0 can forbid SetTexture-family operations per object; older
-- clients do not expose the aspect and continue through the protected call.
function Compat.TrySetColorTexture(texture, r, g, b, a)
	if not texture or type(texture.SetColorTexture) ~= "function" then
		return false
	end

	local setTextureAspect = GetSetTextureForbiddenAspect()
	if setTextureAspect ~= nil and type(texture.HasAnyForbiddenAspects) == "function" then
		local ok, isForbidden = pcall(texture.HasAnyForbiddenAspects, texture, setTextureAspect)
		if not ok or (BFL.IsSecret and BFL:IsSecret(isForbidden)) or isForbidden == true then
			return false
		end
	end

	return pcall(texture.SetColorTexture, texture, r, g, b, a)
end

-- Set texture with atlas fallback support
-- @param texture: Texture object
-- @param atlasName: Atlas name to try
-- @param fallbackFile: Optional explicit fallback file path
-- @param useAtlasSize: Optional SetAtlas useAtlasSize flag
-- @return boolean: true when an atlas was applied, false when a fallback texture was used
function Compat.SetTextureOrAtlas(texture, atlasName, fallbackFile, useAtlasSize)
	if not texture then
		return false
	end

	if texture.SetAtlas and HasAtlas(atlasName) then
		local success
		if useAtlasSize ~= nil then
			success = pcall(texture.SetAtlas, texture, atlasName, useAtlasSize)
		else
			success = pcall(texture.SetAtlas, texture, atlasName)
		end
		if success then
			return true
		end
	end

	local fallback = fallbackFile or ATLAS_FALLBACKS[atlasName]
	if fallback then
		texture:SetTexture(fallback)
	else
		-- Last resort: try as direct texture path
		texture:SetTexture(atlasName)
	end
	return false
end

function Compat.GetAtlasOrTextureMarkup(atlasName, fallbackFile, width, height)
	width = tonumber(width) or 16
	height = tonumber(height) or width
	if HasAtlas(atlasName) then
		return string.format("|A:%s:%d:%d|a", atlasName, width, height)
	end
	local texturePath = fallbackFile or ATLAS_FALLBACKS[atlasName]
	if texturePath and texturePath ~= "" then
		return string.format("|T%s:%d:%d|t", texturePath, width, height)
	end
	return ""
end

function Compat.GetAtlasMarkup(atlasName, width, height, offsetX, offsetY, rVertexColor, gVertexColor, bVertexColor)
	width = tonumber(width) or 16
	height = tonumber(height) or width
	offsetX = tonumber(offsetX) or 0
	offsetY = tonumber(offsetY) or 0

	if not HasAtlas(atlasName) then
		return ""
	end

	if type(CreateAtlasMarkup) == "function" then
		return CreateAtlasMarkup(
			atlasName,
			width,
			height,
			offsetX,
			offsetY,
			rVertexColor,
			gVertexColor,
			bVertexColor
		)
	end

	if rVertexColor ~= nil or gVertexColor ~= nil or bVertexColor ~= nil then
		return string.format(
			"|A:%s:%d:%d:%d:%d:%d:%d:%d|a",
			atlasName,
			height,
			width,
			offsetX,
			offsetY,
			tonumber(rVertexColor) or 0,
			tonumber(gVertexColor) or 0,
			tonumber(bVertexColor) or 0
		)
	end

	return string.format("|A:%s:%d:%d:%d:%d|a", atlasName, height, width, offsetX, offsetY)
end

function Compat.GetClientSubIcon(subIcon)
	if (BFL.IsSecret and BFL:IsSecret(subIcon)) or type(subIcon) ~= "string" or subIcon == "" then
		return nil
	end
	return subIcon
end

function Compat.GetClientProgramIconPrefix(clientProgram, iconSize, subIcon)
	if type(clientProgram) ~= "string" or clientProgram == "" then
		return ""
	end

	iconSize = tonumber(iconSize) or 32
	subIcon = Compat.GetClientSubIcon(subIcon)
	local textureAPI = C_Texture
	local titleIconVersions = Enum and Enum["TitleIconVersion"]
	local titleIconVersion = titleIconVersions and titleIconVersions.Small
	if not (
		textureAPI
		and type(textureAPI.IsTitleIconTextureReady) == "function"
		and type(textureAPI.GetTitleIconTexture) == "function"
		and titleIconVersion
		and type(BNet_GetClientEmbeddedTexture) == "function"
	) then
		return ""
	end

	local readyOK, ready = pcall(textureAPI.IsTitleIconTextureReady, clientProgram, titleIconVersion, subIcon)
	if not (readyOK and ready) then
		return ""
	end

	local text = ""
	local fetchOK = pcall(textureAPI.GetTitleIconTexture, clientProgram, titleIconVersion, function(success, texture)
		if success and texture then
			text = BNet_GetClientEmbeddedTexture(texture, iconSize, iconSize, 0) .. " "
		end
	end, subIcon)
	if not fetchOK then
		return ""
	end
	return text
end

local ROLE_ICON_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
local ROLE_ICON_DATA = {
	TANK = {
		atlas = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-tank",
		texCoord = { 0, 19 / 64, 22 / 64, 41 / 64 },
	},
	HEALER = {
		atlas = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-heal",
		texCoord = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 },
	},
	DAMAGER = {
		atlas = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-dps",
		texCoord = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
	},
}

local ROLE_ALIASES = {
	DAMAGE = "DAMAGER",
	DPS = "DAMAGER",
	DAMAGER = "DAMAGER",
	HEAL = "HEALER",
	HEALER = "HEALER",
	TANK = "TANK",
}

local function NormalizeRole(role)
	if type(role) ~= "string" then
		return nil
	end
	return ROLE_ALIASES[role:upper()]
end

local function GetRoleIconData(role)
	return ROLE_ICON_DATA[NormalizeRole(role)]
end

local function CopyTexCoord(texCoord)
	if type(texCoord) ~= "table" then
		return nil
	end
	return {
		tonumber(texCoord[1]) or 0,
		tonumber(texCoord[2]) or 1,
		tonumber(texCoord[3]) or 0,
		tonumber(texCoord[4]) or 1,
	}
end

local function ResetTexCoord(texture)
	if texture and texture.SetTexCoord then
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function ApplyTexCoord(texture, texCoord)
	if texture and texture.SetTexCoord and type(texCoord) == "table" then
		texture:SetTexCoord(
			tonumber(texCoord[1]) or 0,
			tonumber(texCoord[2]) or 1,
			tonumber(texCoord[3]) or 0,
			tonumber(texCoord[4]) or 1
		)
	end
end

local function TrySetIconAtlas(texture, atlas, useAtlasSize)
	if not (texture and texture.SetAtlas and atlas and atlas ~= "") then
		return false
	end
	if not HasAtlas(atlas) then
		return false
	end
	local width = texture.GetWidth and texture:GetWidth() or nil
	local height = texture.GetHeight and texture:GetHeight() or nil
	ResetTexCoord(texture)
	if useAtlasSize == nil then
		useAtlasSize = false
	end
	local ok = pcall(texture.SetAtlas, texture, atlas, useAtlasSize)
	if ok then
		if width and height and width > 0 and height > 0 and texture.SetSize then
			texture:SetSize(width, height)
		end
		texture:Show()
		return true
	end
	return false
end

function Compat.ApplyIconProfile(texture, profile)
	if not texture then
		return false
	end
	profile = type(profile) == "table" and profile or {}
	local iconType = profile.iconType
	local iconValue = profile.iconValue or profile.icon
	if not iconValue or iconValue == "" or iconType == "none" then
		texture:Hide()
		return false
	end
	if iconType == "atlas" then
		if TrySetIconAtlas(texture, iconValue, false)
			or TrySetIconAtlas(texture, profile.atlas, false)
			or TrySetIconAtlas(texture, profile.fallbackAtlas, false) then
			return true
		end
	end

	local texturePath = profile.texture or profile.icon or (iconType ~= "atlas" and iconValue) or nil
	if not texturePath or texturePath == "" then
		texture:Hide()
		return false
	end
	ResetTexCoord(texture)
	texture:SetTexture(texturePath)
	ApplyTexCoord(texture, profile.texCoord)
	texture:Show()
	return true
end

function Compat.GetRoleIconAtlas(role)
	local data = GetRoleIconData(role)
	return data and data.atlas or nil
end

function Compat.GetRoleIconProfile(role)
	local data = GetRoleIconData(role)
	if not data then
		return nil
	end
	return {
		iconType = "atlas",
		iconValue = data.atlas,
		icon = data.atlas,
		atlas = data.atlas,
		fallbackAtlas = data.fallbackAtlas,
		texture = ROLE_ICON_TEXTURE,
		texCoord = CopyTexCoord(data.texCoord),
	}
end

function Compat.GetRoleIconMarkup(role, size)
	local data = GetRoleIconData(role)
	if not data then
		return ""
	end
	size = tonumber(size) or 16
	if HasAtlas(data.atlas) and type(CreateAtlasMarkup) == "function" then
		return CreateAtlasMarkup(data.atlas, size, size)
	end
	local texCoord = data.texCoord
	return string.format(
		"|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t",
		ROLE_ICON_TEXTURE,
		size,
		size,
		texCoord[1] * 64,
		texCoord[2] * 64,
		texCoord[3] * 64,
		texCoord[4] * 64
	)
end

function Compat.SetRoleIconTexture(texture, role, useAtlasSize)
	local data = GetRoleIconData(role)
	if not texture or not data then
		return false
	end
	local usedAtlas = Compat.SetTextureOrAtlas(texture, data.atlas, ROLE_ICON_TEXTURE, useAtlasSize)
	if not usedAtlas then
		ApplyTexCoord(texture, data.texCoord)
	end
	return true, usedAtlas
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
-- LFG Compatibility
------------------------------------------------------------

local function GetLFGInfoAPI()
	if Compat._testLFGInfo ~= nil then
		return Compat._testLFGInfo or nil
	end
	return C_LFGInfo
end

function Compat.ShouldDisplayMainTankAndAssist()
	local lfgInfo = GetLFGInfoAPI()
	local api = lfgInfo and lfgInfo.IsInMatchmadeRaidWithoutRoleRequirements
	if type(api) ~= "function" then
		return true
	end
	local ok, isRestrictedMatchmadeRaid = pcall(api)
	if not ok or (BFL.IsSecret and BFL:IsSecret(isRestrictedMatchmadeRaid)) then
		return true
	end
	return isRestrictedMatchmadeRaid ~= true
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
	if type(eventName) ~= "string" or eventName == "" then
		return false
	end

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

	-- Prefer the client's event registry when available. Events can differ by
	-- flavor and may be added or removed between builds.
	if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
		local ok, exists = pcall(C_EventUtils.IsEventValid, eventName)
		if ok then
			return exists == true
		end
	end

	-- Older clients do not expose event validation. Registration still uses
	-- pcall below so an unknown event cannot abort addon initialization.
	return true
end

-- Safe event registration
function Compat.RegisterEvent(frame, eventName)
	local frameType = type(frame)
	if
		(frameType ~= "table" and frameType ~= "userdata")
		or type(frame.RegisterEvent) ~= "function"
		or not Compat.EventExists(eventName)
	then
		return false
	end

	local ok, result = pcall(frame.RegisterEvent, frame, eventName)
	return ok and result ~= false
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
		local ok, info = pcall(C_BattleNet.GetMyAccountInfo)
		if not ok then
			info = nil
		end
		if info then
			return info.isAFK, info.isDND, info.appearOffline or info.isAppearOffline
		end
	elseif BNGetInfo then
		local ok, _, _, _, _, isAFK, isDND, _, isAppearOffline = pcall(BNGetInfo)
		if ok then
			return isAFK, isDND, isAppearOffline
		end
	end
	return false, false, false
end

function Compat.CanSetAppearOffline()
	return C_BattleNet and C_BattleNet.SetAppearOffline and true or false
end

function Compat.SetMyBNetStatus(status)
	-- status: "online", "afk", "dnd", "appear_offline"
	if status == "online" then
		-- Modern API (12.0.1+)
		if C_BattleNet and (C_BattleNet.SetAFK or C_BattleNet.SetDND or C_BattleNet.SetAppearOffline) then
			local didSet = false
			if C_BattleNet.SetAFK then
				pcall(C_BattleNet.SetAFK, false)
				didSet = true
			end
			if C_BattleNet.SetDND then
				pcall(C_BattleNet.SetDND, false)
				didSet = true
			end
			if C_BattleNet.SetAppearOffline then
				pcall(C_BattleNet.SetAppearOffline, false)
				didSet = true
			end
			return didSet
		-- Legacy/Classic API
		elseif BNSetAFK then
			pcall(BNSetAFK, false)
			if BNSetDND then
				pcall(BNSetDND, false)
			end
			return true
		end
	elseif status == "appear_offline" then
		if C_BattleNet and C_BattleNet.SetAppearOffline then
			local ok = pcall(C_BattleNet.SetAppearOffline, true)
			return ok == true
		end
	elseif status == "afk" then
		if C_BattleNet and C_BattleNet.SetAFK then
			local ok = pcall(C_BattleNet.SetAFK, true)
			return ok == true
		elseif BNSetAFK then
			local ok = pcall(BNSetAFK, true)
			return ok == true
		end
	elseif status == "dnd" then
		if C_BattleNet and C_BattleNet.SetDND then
			local ok = pcall(C_BattleNet.SetDND, true)
			return ok == true
		elseif BNSetDND then
			local ok = pcall(BNSetDND, true)
			return ok == true
		end
	end
	return false
end

------------------------------------------------------------
-- Friend/Group Management Compatibility
------------------------------------------------------------
-- APIs for adding/removing friends and inviting to group

function Compat.IsLegacyFriendSystemEnabled()
	if C_FriendList and C_FriendList.IsLegacyFriendSystemEnabled then
		local ok, enabled = pcall(C_FriendList.IsLegacyFriendSystemEnabled)
		return ok and enabled == true
	end
	return true
end

function Compat.CanUseWoWFriendList()
	if C_FriendList then
		return Compat.IsLegacyFriendSystemEnabled()
	end
	return GetNumFriends ~= nil
		or GetFriendInfo ~= nil
		or AddFriend ~= nil
		or RemoveFriend ~= nil
		or SetFriendNotes ~= nil
end

function Compat.GetNumWoWFriends()
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.GetNumFriends then
		return C_FriendList.GetNumFriends() or 0
	elseif Compat.CanUseWoWFriendList() and GetNumFriends then
		return GetNumFriends() or 0
	end
	return 0
end

function Compat.GetNumOnlineWoWFriends()
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.GetNumOnlineFriends then
		return C_FriendList.GetNumOnlineFriends() or 0
	elseif Compat.CanUseWoWFriendList() and GetNumOnlineFriends then
		return GetNumOnlineFriends() or 0
	end
	return 0
end

function Compat.GetWoWFriendInfoByIndex(index)
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.GetFriendInfoByIndex then
		return C_FriendList.GetFriendInfoByIndex(index)
	elseif Compat.CanUseWoWFriendList() and GetFriendInfo then
		return GetFriendInfo(index)
	end
	return nil
end

function Compat.GetWoWFriendInfo(name)
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.GetFriendInfo then
		return C_FriendList.GetFriendInfo(name)
	elseif Compat.CanUseWoWFriendList() and GetFriendInfo then
		return GetFriendInfo(name)
	end
	return nil
end

function Compat.IsWoWFriend(guid)
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.IsFriend then
		return C_FriendList.IsFriend(guid)
	elseif Compat.CanUseWoWFriendList() and IsFriend then
		return IsFriend(guid)
	end
	return false
end

function Compat.ShowFriends()
	if C_FriendList and Compat.CanUseWoWFriendList() and C_FriendList.ShowFriends then
		C_FriendList.ShowFriends()
		return true
	elseif Compat.CanUseWoWFriendList() and ShowFriends then
		ShowFriends()
		return true
	end
	return false
end

-- Add a WoW friend
function Compat.AddFriend(name, notes)
	if not Compat.CanUseWoWFriendList() then
		return false
	end
	if C_FriendList and C_FriendList.AddFriend then
		C_FriendList.AddFriend(name, notes or "")
		return true
	elseif AddFriend then
		AddFriend(name)
		if notes and notes ~= "" and SetFriendNotes then
			-- Note setting might be async in old API, but we try
			SetFriendNotes(name, notes)
		end
		return true
	end
	return false
end

-- Remove a WoW friend
function Compat.RemoveFriend(nameOrID)
	if not Compat.CanUseWoWFriendList() then
		return false
	end
	if C_FriendList and C_FriendList.RemoveFriend then
		C_FriendList.RemoveFriend(nameOrID)
		return true
	elseif RemoveFriend then
		RemoveFriend(nameOrID)
		return true
	end
	return false
end

-- Remove friend by index (Classic/Retail variance)
function Compat.RemoveFriendByIndex(index)
	if not Compat.CanUseWoWFriendList() then
		return false
	end
	if C_FriendList and C_FriendList.RemoveFriendByIndex then
		C_FriendList.RemoveFriendByIndex(index)
		return true
	elseif RemoveFriend then
		-- Classic: Need to get name first
		local name = GetFriendInfo(index)
		if name then
			RemoveFriend(name)
			return true
		end
	end
	return false
end

-- Set friend notes
function Compat.SetFriendNotes(name, notes)
	if not Compat.CanUseWoWFriendList() then
		return false
	end
	if C_FriendList and C_FriendList.SetFriendNotes then
		C_FriendList.SetFriendNotes(name, notes)
		return true
	elseif SetFriendNotes then
		SetFriendNotes(name, notes)
		return true
	end
	return false
end

function Compat.AreTitleFriendsEnabled()
	if C_BattleNet and C_BattleNet.AreTitleFriendsEnabled then
		return SafeBooleanAPICall(C_BattleNet.AreTitleFriendsEnabled, false)
	end
	return false
end

local function IsAddOnLoadedCompat(addOnName)
	local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
	if not isLoaded then
		return false
	end
	local ok, loadedOrLoading, loaded = pcall(isLoaded, addOnName)
	if not ok then
		return false
	end
	if loaded ~= nil then
		return loaded == true
	end
	return loadedOrLoading == true
end

local function EnsureAddOnLoadedCompat(addOnName)
	if IsAddOnLoadedCompat(addOnName) then
		return true
	end
	local loadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
	if not loadAddOn then
		return false
	end
	pcall(loadAddOn, addOnName)
	return IsAddOnLoadedCompat(addOnName)
end

local function RequestTitleFriendInviteConfirmation(name, requireIdleDialog)
	if not BFL.IsRetail
		or not EventRegistry
		or not EventRegistry.TriggerEvent
		or not EnsureAddOnLoadedCompat("Blizzard_AddFriend")
		or not BattleNetInviteFrame
		or not BattleNetInviteFrame.OnTitleFriendInviteByNameRequested
	then
		return false
	end
	if requireIdleDialog and ((BattleNetInviteFrame.IsForbidden and BattleNetInviteFrame:IsForbidden())
		or BattleNetInviteFrame:IsShown())
	then
		return false
	end

	local ok = pcall(
		EventRegistry.TriggerEvent,
		EventRegistry,
		"BattleNetInviteFrame.TitleFriendInviteByNameRequested",
		name
	)
	if requireIdleDialog then
		return ok == true and BattleNetInviteFrame:IsShown() and BattleNetInviteFrame or false
	end
	return ok == true
end

-- Opens only the Blizzard confirmation. The native Send button owns the invite.
function Compat.RequestTitleFriendInviteConfirmation(name)
	if IsSafeNameValue(name) and Compat.AreTitleFriendsEnabled() then
		return RequestTitleFriendInviteConfirmation(name, true)
	end
	return false
end

local function RequestBattleTagFriendInviteByIDConfirmation(bnetIDAccount, accountName)
	if not BFL.IsRetail
		or not EventRegistry
		or not EventRegistry.TriggerEvent
		or not EnsureAddOnLoadedCompat("Blizzard_AddFriend")
		or not BattleNetInviteFrame
		or not BattleNetInviteFrame.OnBattleTagFriendInviteByIDRequested
	then
		return false
	end

	local ok = pcall(
		EventRegistry.TriggerEvent,
		EventRegistry,
		"BattleNetInviteFrame.BattleTagFriendInviteByIDRequested",
		bnetIDAccount,
		accountName
	)
	return ok == true
end

-- Send a title-friend invite on Retail 12.1+ through Blizzard's confirmation
-- frame. Older Retail builds and Classic retain the direct/legacy fallbacks.
-- This wrapper must only be called from a hardware-event path because the
-- title-friend API is restricted and only accepts untainted arguments.
function Compat.SendTitleFriendInviteByName(name)
	if not IsSafeNameValue(name) then
		return false
	end
	if Compat.AreTitleFriendsEnabled() and C_BattleNet and C_BattleNet.SendTitleFriendInviteByName then
		if RequestTitleFriendInviteConfirmation(name) then
			return true
		end
		local ok = pcall(C_BattleNet.SendTitleFriendInviteByName, name)
		return ok == true
	end
	return Compat.AddFriend(name)
end

-- Delegate opening, input handling and request selection to Blizzard. The
-- display/link surname format does not define the API's accepted input format.
function Compat.ShowAddFriendDialog()
	if BFL.IsRetail and type(AddFriendFrame_Show) ~= "function" then
		EnsureAddOnLoadedCompat("Blizzard_AddFriend")
	end
	if type(AddFriendFrame_Show) == "function" then
		AddFriendFrame_Show()
		return true
	end
	if not BFL.IsRetail and type(FriendsFrameAddFriendButton_OnClick) == "function" then
		FriendsFrameAddFriendButton_OnClick()
		return true
	end
	if Compat.CanUseWoWFriendList() and type(StaticPopup_Show) == "function" then
		StaticPopup_Show("ADD_FRIEND")
		return true
	end
	return false
end

-- Upgrade a Forever Title friend through Blizzard's confirmation surface.
-- This wrapper must be invoked from a hardware-event menu callback.
function Compat.SendBattleTagFriendInviteByID(bnetIDAccount, accountName)
	if bnetIDAccount == nil
		or (BFL.IsSecret and (BFL:IsSecret(bnetIDAccount) or BFL:IsSecret(accountName)))
	then
		return false
	end
	if type(bnetIDAccount) == "string" then
		bnetIDAccount = tonumber(bnetIDAccount)
	end
	if type(bnetIDAccount) ~= "number" then
		return false
	end
	if RequestBattleTagFriendInviteByIDConfirmation(bnetIDAccount, accountName) then
		return true
	end
	if type(BNSendFriendInviteByID) == "function" then
		local ok = pcall(BNSendFriendInviteByID, bnetIDAccount)
		return ok == true
	end
	return false
end

function Compat.AreTitleFriendCustomNamesEnabled()
	if C_BattleNet and C_BattleNet.AreTitleFriendCustomNamesEnabled then
		local ok, enabled = pcall(C_BattleNet.AreTitleFriendCustomNamesEnabled)
		return ok and not (BFL.IsSecret and BFL:IsSecret(enabled)) and enabled == true
	end
	return false
end

function Compat.IsTitleFriend(accountInfo)
	if (BFL.IsSecret and BFL:IsSecret(accountInfo)) or type(accountInfo) ~= "table" then return false end
	if BFL.IsSecret and BFL:IsSecret(accountInfo.friendLevel) then
		return false
	end
	local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
	return titleLevel ~= nil and accountInfo.friendLevel == titleLevel
end

function Compat.IsOfflineTitleFriend(accountInfoOrFriend, isOffline)
	if (BFL.IsSecret and (BFL:IsSecret(accountInfoOrFriend) or BFL:IsSecret(isOffline))) or type(accountInfoOrFriend) ~= "table" then
		return false
	end
	local accountInfo = accountInfoOrFriend.accountInfo
	if BFL.IsSecret and BFL:IsSecret(accountInfo) then return false end
	accountInfo = accountInfo or accountInfoOrFriend
	if type(accountInfo) ~= "table" then return false end
	if BFL.IsSecret and (BFL:IsSecret(accountInfoOrFriend.friendLevel) or BFL:IsSecret(accountInfo.friendLevel)) then
		return false
	end
	local friendLevel = accountInfoOrFriend.friendLevel or accountInfo.friendLevel
	local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
	if not titleLevel or friendLevel ~= titleLevel then
		return false
	end
	if isOffline ~= nil then
		return isOffline == true
	end
	if BFL.IsSecret and (BFL:IsSecret(accountInfoOrFriend.connected) or BFL:IsSecret(accountInfoOrFriend.isOnline)) then
		return false
	end
	if accountInfoOrFriend.connected ~= nil then
		return accountInfoOrFriend.connected == false
	end
	if accountInfoOrFriend.isOnline ~= nil then
		return accountInfoOrFriend.isOnline == false
	end
	local gameAccountInfo = accountInfo.gameAccountInfo
	if (BFL.IsSecret and BFL:IsSecret(gameAccountInfo)) or type(gameAccountInfo) ~= "table" then return false end
	return not (BFL.IsSecret and BFL:IsSecret(gameAccountInfo.isOnline)) and gameAccountInfo.isOnline == false
end

function Compat.GetCustomTitleFriendName(id)
	if C_BattleNet and C_BattleNet.GetCustomTitleFriendName and id then
		local ok, customName = pcall(C_BattleNet.GetCustomTitleFriendName, id)
		if ok then
			return customName
		end
	end
	return nil
end

function Compat.SetCustomTitleFriendName(id, customName)
	if C_BattleNet and C_BattleNet.SetCustomTitleFriendName and id then
		local ok = pcall(C_BattleNet.SetCustomTitleFriendName, id, customName or "")
		return ok == true
	end
	return false
end

-- Invite a unit to party
function Compat.InviteUnit(name)
	if (BFL.IsSecret and BFL:IsSecret(name))
		or type(name) ~= "string" or name == ""
	then
		return false
	end
	if C_PartyInfo and C_PartyInfo.InviteUnit then
		C_PartyInfo.InviteUnit(name)
		return true
	elseif InviteUnit then
		InviteUnit(name)
		return true
	end
	return false
end

-- Convert party to raid
function Compat.ConvertToRaid()
	if Compat.IsSocialActionRestricted() then return false end
	if C_PartyInfo and C_PartyInfo.ConvertToRaid then
		C_PartyInfo.ConvertToRaid()
		return true
	elseif ConvertToRaid then
		ConvertToRaid()
		return true
	end
	return false
end

-- Convert raid to party
function Compat.ConvertToParty()
	if Compat.IsSocialActionRestricted() then return false end
	if C_PartyInfo and C_PartyInfo.ConvertToParty then
		C_PartyInfo.ConvertToParty()
		return true
	elseif ConvertToParty then
		ConvertToParty()
		return true
	end
	return false
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

local function GetExactPlayerNameForPartyAction(nameOrUnit)
	if (BFL.IsSecret and BFL:IsSecret(nameOrUnit)) or type(nameOrUnit) ~= "string" or nameOrUnit == "" then
		return nil, false
	end
	local exists = false
	if type(UnitExists) == "function" then
		local ok, value = pcall(UnitExists, nameOrUnit)
		if not ok or (BFL.IsSecret and BFL:IsSecret(value)) or type(value) ~= "boolean" then
			return nil, false
		end
		exists = value
	end
	if not exists then
		return Compat.AreRegionalUniqueNamesEnabled() and Compat.NormalizePlayerName(nameOrUnit) or nameOrUnit, false
	end
	if Compat.AreRegionalUniqueNamesEnabled() then
		local fullName = Compat.GetUnmodifiedUnitFullName(nameOrUnit)
		return fullName and Compat.NormalizePlayerName(fullName) or nil, true
	end

	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(nameOrUnit)
	end
	if BFL.IsSecret and (BFL:IsSecret(name) or BFL:IsSecret(realm)) then return nil, false end
	if not name and UnitName then
		name, realm = UnitName(nameOrUnit)
	end
	if BFL.IsSecret and (BFL:IsSecret(name) or BFL:IsSecret(realm)) then return nil, false end
	if type(name) ~= "string" or name == "" or name == UNKNOWN or name == UNKNOWNOBJECT then
		return nil, false
	end
	if not realm or realm == "" then
		if GetNormalizedRealmName then realm = GetNormalizedRealmName() end
	end
	if (BFL.IsSecret and BFL:IsSecret(realm)) or (realm ~= nil and type(realm) ~= "string") then return nil, false end

	local isSameRealm = false
	if UnitRealmRelationship and LE_REALM_RELATION_SAME then
		local relationship = UnitRealmRelationship(nameOrUnit)
		if BFL.IsSecret and BFL:IsSecret(relationship) then return nil, false end
		isSameRealm = relationship == LE_REALM_RELATION_SAME
	elseif realm and GetNormalizedRealmName then
		local playerRealm = GetNormalizedRealmName()
		if BFL.IsSecret and BFL:IsSecret(playerRealm) then return nil, false end
		isSameRealm = realm == playerRealm
	end

	if realm and realm ~= "" and not isSameRealm then
		return name .. "-" .. realm, true
	end
	return name, true
end

function Compat.PromoteToAssistant(name, exactNameMatch)
	if Compat.IsSocialActionRestricted() or (BFL.IsSecret and BFL:IsSecret(exactNameMatch)) then return false end
	local exactName, exactFromUnit = GetExactPlayerNameForPartyAction(name)
	if exactName == nil or exactName == "" then
		return false
	end
	if exactNameMatch == nil and exactFromUnit then
		exactNameMatch = true
	end
	if C_PartyInfo and C_PartyInfo.PromoteToAssistant then
		C_PartyInfo.PromoteToAssistant(exactName, exactNameMatch)
		return true
	elseif PromoteToAssistant then
		PromoteToAssistant(exactName, exactNameMatch)
		return true
	end
	return false
end

function Compat.PromoteToLeader(name, exactNameMatch)
	if Compat.IsSocialActionRestricted() or not Compat.CanPromoteToLeader()
		or (BFL.IsSecret and BFL:IsSecret(exactNameMatch))
	then
		return false
	end
	local exactName, exactFromUnit = GetExactPlayerNameForPartyAction(name)
	if exactName == nil or exactName == "" then
		return false
	end
	if exactNameMatch == nil and exactFromUnit then
		exactNameMatch = true
	end
	if C_PartyInfo and C_PartyInfo.PromoteToLeader then
		C_PartyInfo.PromoteToLeader(exactName, exactNameMatch)
		return true
	elseif PromoteToLeader then
		PromoteToLeader(exactName, exactNameMatch)
		return true
	end
	return false
end

function Compat.DemoteAssistant(name, exactNameMatch)
	if Compat.IsSocialActionRestricted() or (BFL.IsSecret and BFL:IsSecret(exactNameMatch)) then return false end
	local exactName, exactFromUnit = GetExactPlayerNameForPartyAction(name)
	if exactName == nil or exactName == "" then
		return false
	end
	if exactNameMatch == nil and exactFromUnit then
		exactNameMatch = true
	end
	if C_PartyInfo and C_PartyInfo.DemoteAssistant then
		C_PartyInfo.DemoteAssistant(exactName, exactNameMatch)
		return true
	elseif DemoteAssistant then
		DemoteAssistant(exactName, exactNameMatch)
		return true
	end
	return false
end

function Compat.SetEveryoneIsAssistant(isAssistant)
	if Compat.IsSocialActionRestricted() or (BFL.IsSecret and BFL:IsSecret(isAssistant)) then return false end
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
		local ok, level = pcall(GetMaxLevelForPlayerExpansion)
		if ok and type(level) == "number" and level > 0 then
			return level
		end
	end
	if GetMaxPlayerLevel then
		local ok, level = pcall(GetMaxPlayerLevel)
		if ok and type(level) == "number" and level > 0 then
			return level
		end
	end

	-- Fallbacks based on game version flags (defined in Core.lua)
	if BFL.IsTWW then
		return 80
	end
	if BFL.IsMainline then
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

	-- This is a read-only getter. Broad action restrictions must not hide the
	-- header text; restricted clients are handled by the secure call below.
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

	-- These callbacks run inside Blizzard's chat event pipeline. On clients with
	-- secret chat values, entering an AddOn callback here taints the remaining
	-- dispatch and can make later ChatHistory string/table operations fail. The
	-- separate GUILD_MOTD event callback below still maintains the BFL cache.
	if BFL.HasSecretValues or issecretvalue then
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
BFL.CreateContextMenu = Compat.CreateContextMenu
BFL.OpenContextMenu = function(button, menuType, contextData, name)
	if contextData then
		contextData.bflOrigin = ADDON_NAME
		contextData.ownerFrame = contextData.ownerFrame or button
	end
	if (BFL.HasSecretValues or BFL.IsForever) and BFL.OpenBetterFriendlistContextMenu then
		PrepareUnitPopupContext(menuType, contextData)
		if BFL:OpenBetterFriendlistContextMenu(button, menuType, contextData, name) then
			return
		end
	end
	Compat.OpenUnitPopupMenu(menuType, contextData)
end

-- Dropdown Creation
BFL.CreateDropdown = Compat.CreateDropdown
BFL.CanCreateModernDropdown = Compat.CanCreateModernDropdown
BFL.IsModernDropdown = Compat.IsModernDropdown
BFL.ShouldUseLegacyDropdown = Compat.ShouldUseLegacyDropdown
BFL.SetDropdownText = Compat.SetDropdownText
BFL.SetDropdownWidth = Compat.SetDropdownWidth
BFL.JustifyDropdownText = Compat.JustifyDropdownText
BFL.SetDropdownSelectedValue = Compat.SetDropdownSelectedValue
BFL.InitializeDropdown = Compat.InitializeDropdown
BFL.InitializeMultiSelectDropdown = Compat.InitializeMultiSelectDropdown
BFL.RefreshDropdown = Compat.RefreshDropdown
BFL.HasAtlas = Compat.HasAtlas
BFL.GetAtlasInfo = Compat.GetAtlasInfo
BFL.TrySetColorTexture = Compat.TrySetColorTexture
BFL.SetTextureOrAtlas = Compat.SetTextureOrAtlas
BFL.GetAtlasMarkup = Compat.GetAtlasMarkup
BFL.GetAtlasOrTextureMarkup = Compat.GetAtlasOrTextureMarkup
BFL.GetClientProgramIconPrefix = Compat.GetClientProgramIconPrefix
BFL.ApplyIconProfile = Compat.ApplyIconProfile
BFL.GetRoleIconAtlas = Compat.GetRoleIconAtlas
BFL.GetRoleIconProfile = Compat.GetRoleIconProfile
BFL.GetRoleIconMarkup = Compat.GetRoleIconMarkup
BFL.SetRoleIconTexture = Compat.SetRoleIconTexture
BFL.ShowMenuTooltip = Compat.ShowMenuTooltip
BFL.HideMenuTooltip = Compat.HideMenuTooltip
BFL.CreateMenuButton = Compat.CreateMenuButton
BFL.PopulateSimpleMenu = Compat.PopulateSimpleMenu
BFL.OpenSimpleContextMenu = Compat.OpenSimpleContextMenu
BFL.StyleSimpleMenuCheckbox = Compat.StyleSimpleMenuCheckbox

-- ColorPicker
BFL.ShowColorPicker = Compat.ShowColorPicker

-- BNet Status
BFL.GetMyBNetStatus = Compat.GetMyBNetStatus
BFL.CanSetAppearOffline = Compat.CanSetAppearOffline
BFL.SetMyBNetStatus = Compat.SetMyBNetStatus
BFL.GetBNetFriendInfo = Compat.GetBNetFriendInfo
BFL.GetBNetFriendGameAccountInfo = Compat.GetBNetFriendGameAccountInfo
BFL.IsWoWAccountRulesetLocation = Compat.IsWoWAccountRulesetLocation
BFL.GetWoWAccountLocation = Compat.GetWoWAccountLocation
BFL.GetGameAccountRichPresence = Compat.GetGameAccountRichPresence
BFL.GetForeverRulesetInviteRestriction = Compat.GetForeverRulesetInviteRestriction
BFL.ValidateForeverInviteTarget = Compat.ValidateForeverInviteTarget
Compat.IsReadableGameAccountInfo = IsReadableGameAccountInfo
BFL.IsReadableGameAccountInfo = IsReadableGameAccountInfo
BFL.GetSafeFrameStrata = Compat.GetSafeFrameStrata
BFL.IsBNetInviteRealmRestricted = Compat.IsBNetInviteRealmRestricted
BFL.GetBNetInviteTooltipInfo = Compat.GetBNetInviteTooltipInfo
BFL.IsBattleNetFriendsListSupported = Compat.IsBattleNetFriendsListSupported
BFL.IsBattleNetFriendsListEnabled = Compat.IsBattleNetFriendsListEnabled
BFL.CanSearchBattleNetFriends = Compat.CanSearchBattleNetFriends
BFL.SearchBattleNetFriends = Compat.SearchBattleNetFriends
BFL.AreBattleNetFriendTagsEnabled = Compat.AreBattleNetFriendTagsEnabled
BFL.GetBNetFriendInviteInfo = Compat.GetBNetFriendInviteInfo
BFL.CanSetBNetBlocked = Compat.CanSetBNetBlocked
BFL.IsSocialActionRestricted = Compat.IsSocialActionRestricted
BFL.IsRaidListSupported = Compat.IsRaidListSupported
BFL.IsRaidListEnabled = Compat.IsRaidListEnabled
BFL.CanPromoteToLeader = Compat.CanPromoteToLeader
BFL.AreRealIDFriendsEnabled = Compat.AreRealIDFriendsEnabled
BFL.GetBNetFriendLevelLabel = Compat.GetBNetFriendLevelLabel
BFL.SetBNetBlocked = Compat.SetBNetBlocked
BFL.CanBlockBNetFriendInvite = Compat.CanBlockBNetFriendInvite
BFL.CanBlockBNetAccount = Compat.CanBlockBNetAccount
BFL.CanBlockBNetFriendInviteByIndex = Compat.CanBlockBNetFriendInviteByIndex
BFL.IsAgeVerificationRestricted = Compat.IsAgeVerificationRestricted
BFL.IsAgeVerificationRestrictedMinor = Compat.IsAgeVerificationRestrictedMinor
BFL.GetAgeVerificationRestrictionTooltip = Compat.GetAgeVerificationRestrictionTooltip
BFL.CanSendWhisper = Compat.CanSendWhisper
BFL.AreRegionalUniqueNamesEnabled = Compat.AreRegionalUniqueNamesEnabled
BFL.FormatPlayerDisplayName = Compat.FormatPlayerDisplayName
BFL.GetCopyCharacterName = Compat.GetCopyCharacterName
BFL.GetBNetRemoveFriendPrompt = Compat.GetBNetRemoveFriendPrompt
BFL.ShowAddFriendDialog = Compat.ShowAddFriendDialog
BFL.GetUnmodifiedUnitFullName = Compat.GetUnmodifiedUnitFullName
BFL.SplitPlayerName = Compat.SplitPlayerName
BFL.GetPlayerNameWithoutRealm = Compat.GetPlayerNameWithoutRealm
BFL.ReplaceSurnameSeparatorWithLinkSeparator = Compat.ReplaceSurnameSeparatorWithLinkSeparator
BFL.NormalizePlayerIdentityName = Compat.NormalizePlayerName
BFL.AreTitleFriendsEnabled = Compat.AreTitleFriendsEnabled
BFL.SendTitleFriendInviteByName = Compat.SendTitleFriendInviteByName
BFL.RequestTitleFriendInviteConfirmation = Compat.RequestTitleFriendInviteConfirmation
BFL.SendBattleTagFriendInviteByID = Compat.SendBattleTagFriendInviteByID
BFL.AreTitleFriendCustomNamesEnabled = Compat.AreTitleFriendCustomNamesEnabled
BFL.IsTitleFriend = Compat.IsTitleFriend
BFL.IsOfflineTitleFriend = Compat.IsOfflineTitleFriend
BFL.GetCustomTitleFriendName = Compat.GetCustomTitleFriendName
BFL.SetCustomTitleFriendName = Compat.SetCustomTitleFriendName
BFL.IsRAFSystemSupported = Compat.IsRAFSystemSupported
BFL.IsRAFSystemEnabled = Compat.IsRAFSystemEnabled
BFL.CanSummonRAFFriend = Compat.CanSummonRAFFriend
BFL.IsSocialQueueSupported = Compat.IsSocialQueueSupported
BFL.IsSocialQueueEnabled = Compat.IsSocialQueueEnabled
BFL.GetQuickJoinGroupFinderAccess = Compat.GetQuickJoinGroupFinderAccess

-- Friend/Group Operations
BFL.IsLegacyFriendSystemEnabled = Compat.IsLegacyFriendSystemEnabled
BFL.CanUseWoWFriendList = Compat.CanUseWoWFriendList
BFL.GetNumWoWFriends = Compat.GetNumWoWFriends
BFL.GetNumOnlineWoWFriends = Compat.GetNumOnlineWoWFriends
BFL.GetWoWFriendInfoByIndex = Compat.GetWoWFriendInfoByIndex
BFL.GetWoWFriendInfo = Compat.GetWoWFriendInfo
BFL.IsWoWFriend = Compat.IsWoWFriend
BFL.ShowFriends = Compat.ShowFriends
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
