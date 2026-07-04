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

local function CreateClassicMenuDescription(parentItem, rootItems)
	rootItems = rootItems or {}

	local rootDescription = {}

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
		table.insert(GetTargetItems(), item)
		return CreateClassicMenuDescription(item)
	end

	function rootDescription:SetEnabled(enabled)
		if parentItem then
			parentItem.disabled = not enabled
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

	function rootDescription:CreateCheckbox(text, isSelected, onSelected)
		local item = {
			text = text or "",
			notCheckable = false,
			isNotRadio = true,
			keepShownOnClick = true,
		}
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
			elseif GetSimpleMenuChildren(item) then
				local element = rootDescription:CreateButton(item.text or "")
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
				if item.disabled ~= nil or item.enabled ~= nil then
					local enabled = item.enabled
					if enabled == nil then
						enabled = not item.disabled
					end
					SetSimpleMenuElementEnabled(element, enabled)
				end
			else
				local element = rootDescription:CreateButton(item.text or "", function()
					return RunSimpleMenuItem(item, item.value)
				end)
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
					info.checked = function()
						return IsSimpleMenuItemChecked(item, item.value)
					end
				else
					info.notCheckable = true
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

-- Initialize dropdown with options
-- @param dropdown: The dropdown frame
-- @param options: Table with { labels = {...}, values = {...} }
-- @param getter: Function(value) -> boolean (is this value selected?)
-- @param setter: Function(value) called when selection changes
-- @param scrollHeight: Optional max pixel height before the dropdown scrolls (Retail only)
function Compat.InitializeDropdown(dropdown, options, getter, setter, scrollHeight)
	options = options or {}
	if Compat.IsModernDropdown(dropdown) then
		if dropdown.SetSelectionTranslator then
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
function Compat.InitializeMultiSelectDropdown(dropdown, options, getter, setter, textFunc)
	if Compat.IsModernDropdown(dropdown) then
		dropdown:SetupMenu(function(dropdown, rootDescription)
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

function Compat.IsBattleNetFriendsListSupported()
	if not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
		return false
	end
	if C_BattleNet.IsBattleNetFriendsListSupported then
		return C_BattleNet.IsBattleNetFriendsListSupported()
	end
	return true
end

function Compat.IsBattleNetFriendsListEnabled()
	if not Compat.IsBattleNetFriendsListSupported() then
		return false
	end
	if C_BattleNet.IsBattleNetFriendsListEnabled then
		return C_BattleNet.IsBattleNetFriendsListEnabled()
	end
	return true
end

function Compat.AreBattleNetFriendTagsEnabled()
	if not Compat.IsBattleNetFriendsListEnabled() then
		return false
	end
	if not (BFL.IsRetail == true and C_BattleNet and type(C_BattleNet.AreFriendTagsEnabled) == "function") then
		return false
	end
	local ok, enabled = pcall(C_BattleNet.AreFriendTagsEnabled)
	return ok and enabled == true or false
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
-- Recruit-A-Friend Compatibility
------------------------------------------------------------
-- 12.0.7: C_RecruitAFriend.IsEnabled()
-- 12.1+:  C_RecruitAFriend.IsSystemSupported() / IsSystemEnabled()

function Compat.IsRAFSystemSupported()
	if not BFL.IsRetail or not C_RecruitAFriend then
		return false
	end
	if C_RecruitAFriend.IsSystemSupported then
		return C_RecruitAFriend.IsSystemSupported()
	end
	return C_RecruitAFriend.IsEnabled ~= nil
end

function Compat.IsRAFSystemEnabled()
	if not BFL.IsRetail or not C_RecruitAFriend then
		return false
	end
	if C_RecruitAFriend.IsSystemEnabled then
		return C_RecruitAFriend.IsSystemEnabled()
	end
	if C_RecruitAFriend.IsEnabled then
		return C_RecruitAFriend.IsEnabled()
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
	if not BFL.IsRetail or not C_SocialQueue then
		return false
	end
	if C_SocialQueue.IsSystemSupported then
		return C_SocialQueue.IsSystemSupported()
	end
	return C_SocialQueue.GetAllGroups ~= nil
end

function Compat.IsSocialQueueEnabled()
	if not Compat.IsSocialQueueSupported() then
		return false
	end
	if C_SocialQueue.IsSystemEnabled then
		return C_SocialQueue.IsSystemEnabled()
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
	["socialqueuing-icon-group"] = "Interface\\AddOns\\BetterFriendlist\\Icons\\users",

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
}

local ATLAS_AVAILABILITY = {}

local function HasAtlas(atlasName)
	if not atlasName or not (C_Texture and type(C_Texture.GetAtlasInfo) == "function") then
		return false
	end

	if ATLAS_AVAILABILITY[atlasName] ~= nil then
		return ATLAS_AVAILABILITY[atlasName]
	end

	local ok, info = pcall(C_Texture.GetAtlasInfo, atlasName)
	local available = ok and info ~= nil
	ATLAS_AVAILABILITY[atlasName] = available
	return available
end

function Compat.HasAtlas(atlasName)
	return HasAtlas(atlasName)
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
		local success = pcall(function()
			if useAtlasSize ~= nil then
				texture:SetAtlas(atlasName, useAtlasSize)
			else
				texture:SetAtlas(atlasName)
			end
		end)
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

function Compat.GetAtlasMarkup(atlasName, width, height, offsetX, offsetY)
	width = tonumber(width) or 16
	height = tonumber(height) or width
	offsetX = tonumber(offsetX) or 0
	offsetY = tonumber(offsetY) or 0

	if not HasAtlas(atlasName) then
		return ""
	end

	if type(CreateAtlasMarkup) == "function" then
		return CreateAtlasMarkup(atlasName, width, height, offsetX, offsetY)
	end

	return string.format("|A:%s:%d:%d:%d:%d|a", atlasName, height, width, offsetX, offsetY)
end

function Compat.GetClientProgramIconPrefix(clientProgram, iconSize)
	if type(clientProgram) ~= "string" or clientProgram == "" then
		return ""
	end

	iconSize = tonumber(iconSize) or 32
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

	local readyOK, ready = pcall(textureAPI.IsTitleIconTextureReady, clientProgram, titleIconVersion)
	if not (readyOK and ready) then
		return ""
	end

	local text = ""
	local fetchOK = pcall(textureAPI.GetTitleIconTexture, clientProgram, titleIconVersion, function(success, texture)
		if success and texture then
			text = BNet_GetClientEmbeddedTexture(texture, iconSize, iconSize, 0) .. " "
		end
	end)
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
		local ok, enabled = pcall(C_BattleNet.AreTitleFriendsEnabled)
		return ok and enabled == true
	end
	return false
end

function Compat.AreTitleFriendCustomNamesEnabled()
	if C_BattleNet and C_BattleNet.AreTitleFriendCustomNamesEnabled then
		local ok, enabled = pcall(C_BattleNet.AreTitleFriendCustomNamesEnabled)
		return ok and enabled == true
	end
	return false
end

function Compat.IsTitleFriend(accountInfo)
	return accountInfo
		and Enum
		and Enum.BattleNetFriendLevel
		and accountInfo.friendLevel == Enum.BattleNetFriendLevel.Title
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

local function GetExactPlayerNameForPartyAction(nameOrUnit)
	if type(nameOrUnit) ~= "string" or nameOrUnit == "" then
		return nameOrUnit, false
	end
	if not (UnitExists and UnitExists(nameOrUnit)) then
		return nameOrUnit, false
	end

	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(nameOrUnit)
	end
	if not name and UnitName then
		name, realm = UnitName(nameOrUnit)
	end
	if not name or name == "" then
		return nameOrUnit, false
	end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
	end

	local isSameRealm = false
	if UnitRealmRelationship and LE_REALM_RELATION_SAME then
		isSameRealm = UnitRealmRelationship(nameOrUnit) == LE_REALM_RELATION_SAME
	elseif realm and GetNormalizedRealmName then
		isSameRealm = realm == GetNormalizedRealmName()
	end

	if realm and realm ~= "" and not isSameRealm then
		return name .. "-" .. realm, true
	end
	return name, true
end

function Compat.PromoteToAssistant(name, exactNameMatch)
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
BFL.CreateContextMenu = Compat.CreateContextMenu
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
BFL.PopulateSimpleMenu = Compat.PopulateSimpleMenu
BFL.OpenSimpleContextMenu = Compat.OpenSimpleContextMenu

-- ColorPicker
BFL.ShowColorPicker = Compat.ShowColorPicker

-- BNet Status
BFL.GetMyBNetStatus = Compat.GetMyBNetStatus
BFL.CanSetAppearOffline = Compat.CanSetAppearOffline
BFL.SetMyBNetStatus = Compat.SetMyBNetStatus
BFL.GetBNetFriendInfo = Compat.GetBNetFriendInfo
BFL.GetBNetFriendGameAccountInfo = Compat.GetBNetFriendGameAccountInfo
BFL.IsBattleNetFriendsListSupported = Compat.IsBattleNetFriendsListSupported
BFL.IsBattleNetFriendsListEnabled = Compat.IsBattleNetFriendsListEnabled
BFL.AreBattleNetFriendTagsEnabled = Compat.AreBattleNetFriendTagsEnabled
BFL.GetBNetFriendInviteInfo = Compat.GetBNetFriendInviteInfo
BFL.AreTitleFriendsEnabled = Compat.AreTitleFriendsEnabled
BFL.AreTitleFriendCustomNamesEnabled = Compat.AreTitleFriendCustomNamesEnabled
BFL.IsTitleFriend = Compat.IsTitleFriend
BFL.GetCustomTitleFriendName = Compat.GetCustomTitleFriendName
BFL.SetCustomTitleFriendName = Compat.SetCustomTitleFriendName
BFL.IsRAFSystemSupported = Compat.IsRAFSystemSupported
BFL.IsRAFSystemEnabled = Compat.IsRAFSystemEnabled
BFL.CanSummonRAFFriend = Compat.CanSummonRAFFriend
BFL.IsSocialQueueSupported = Compat.IsSocialQueueSupported
BFL.IsSocialQueueEnabled = Compat.IsSocialQueueEnabled

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
