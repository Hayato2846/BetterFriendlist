--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua"); -- SettingsComponents.lua
-- Reusable UI components for Settings panel (Platynator-style)

local ADDON_NAME, BFL = ...
BFL.SettingsComponents = {}

local Components = BFL.SettingsComponents
local L = BFL.L or BFL_L

-- ========================================
-- Constants
-- ========================================
local COMPONENT_HEIGHT = 15
local PADDING_LEFT = 5
local PADDING_RIGHT = 5
local SPACING_SECTION = -10
local SPACING_OPTION = -10

-- ========================================
-- HEADERS
-- ========================================
function Components:CreateHeader(parent, text) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateHeader file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:22:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	holder.text = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormalLarge")
	holder.text:SetText(text)
	holder.text:SetPoint("LEFT", 0, 0)
	holder.text:SetJustifyH("LEFT")
	holder:SetHeight(COMPONENT_HEIGHT)
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateHeader file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:22:0"); return holder
end

-- ========================================
-- CHECKBOX (Label left, Checkbox right)
-- Classic uses InterfaceOptionsCheckButtonTemplate, Retail uses SettingsCheckboxTemplate
-- ========================================
function Components:CreateCheckbox(parent, labelText, initialValue, callback) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateCheckbox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:38:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Choose template based on game version
	local template = "SettingsCheckboxTemplate"
	if BFL.IsClassic then
		-- Classic: Use InterfaceOptionsCheckButtonTemplate or ChatConfigCheckButtonTemplate
		template = "InterfaceOptionsCheckButtonTemplate"
	end
	
	-- Checkbox: links positioniert
	local checkBox = CreateFrame("CheckButton", nil, holder, template)
	checkBox:SetPoint("LEFT", holder, "LEFT", 0, 0)
	
	-- Handle label differently based on template
	if BFL.IsClassic then
		-- Classic template uses Text child
		if checkBox.Text then
			checkBox.Text:SetText(labelText)
		else
			-- Fallback: Create font string manually
			local text = checkBox:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
			text:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)
			text:SetText(labelText)
			checkBox.Text = text
		end
	else
		-- Retail: Use SetText method
		checkBox:SetText(labelText)
		checkBox:SetNormalFontObject("BetterFriendlistFontHighlight")
		
		-- Label: rechts neben der Checkbox
		local label = checkBox:GetFontString()
		label:ClearAllPoints()
		label:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)
		label:SetJustifyH("LEFT")
		label:SetWidth(300)
	end
	
	checkBox:SetChecked(initialValue)
	checkBox:SetScript("OnClick", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:81:31");
		callback(self:GetChecked())
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:81:31"); end)
	
	-- Fix for ugly hover effect when no tooltip is present
	checkBox:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:86:31"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:86:31"); end)
	checkBox:SetScript("OnLeave", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:87:31"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:87:31"); end)
	
	-- Tooltip support
	holder.SetTooltip = function(_, title, desc) Perfy_Trace(Perfy_GetTime(), "Enter", "holder.SetTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:90:21");
		checkBox:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:91:32");
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc then
				GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true)
			end
			GameTooltip:Show()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:91:32"); end)
		checkBox:SetScript("OnLeave", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:99:32");
			GameTooltip:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:99:32"); end)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder.SetTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:90:21"); end
	
	function holder:SetValue(value) Perfy_Trace(Perfy_GetTime(), "Enter", "holder:SetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:104:1");
		checkBox:SetChecked(value)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder:SetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:104:1"); end
	
	function holder:GetValue() Perfy_Trace(Perfy_GetTime(), "Enter", "holder:GetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:108:1");
		return Perfy_Trace_Passthrough("Leave", "holder:GetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:108:1", checkBox:GetChecked())
	end
	
	holder.checkBox = checkBox
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateCheckbox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:38:0"); return holder
end

-- ========================================
-- SLIDER (Label left, Slider right)
-- ========================================
function Components:CreateSlider(parent, labelText, min, max, initialValue, formatter, callback) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateSlider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:119:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label (left side, right-justified)
	holder.Label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.Label:SetJustifyH("RIGHT")
	holder.Label:SetPoint("LEFT", 20, 0)
	holder.Label:SetPoint("RIGHT", holder, "CENTER", -50, 0)
	holder.Label:SetText(labelText)
	
	-- Slider (right side)
	holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
	holder.Slider:SetPoint("LEFT", holder, "CENTER", -32, 0)
	holder.Slider:SetPoint("RIGHT", -45, 0)
	holder.Slider:SetHeight(20)
	holder.Slider:Init(initialValue, min, max, max - min, {
		[MinimalSliderWithSteppersMixin.Label.Right] = formatter
	})
	
	holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:141:85");
		callback(value)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:141:85"); end)
	
	function holder:SetValue(value) Perfy_Trace(Perfy_GetTime(), "Enter", "holder:SetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:145:1");
		holder.Slider:SetValue(value)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder:SetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:145:1"); end
	
	function holder:GetValue() Perfy_Trace(Perfy_GetTime(), "Enter", "holder:GetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:149:1");
		return Perfy_Trace_Passthrough("Leave", "holder:GetValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:149:1", holder.Slider:GetValue())
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateSlider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:119:0"); return holder
end

-- ========================================
-- DROPDOWN (Label left, Dropdown right)
-- Classic uses UIDropDownMenuTemplate, Retail uses WowStyle1DropdownTemplate
-- ========================================

-- Classic dropdown counter for unique names
local classicDropdownCounter = 0

-- Create Classic-style dropdown using UIDropDownMenu
local function CreateClassicDropdown(parent, entries, isSelectedCallback, onSelectionCallback) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateClassicDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:165:6");
	classicDropdownCounter = classicDropdownCounter + 1
	local dropdownName = "BFLSettingsDropdown" .. classicDropdownCounter
	
	local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	dropdown:SetWidth(180)
	
	local entryLabels = entries.labels
	local entryValues = entries.values
	
	-- Store callbacks for later use
	dropdown.isSelectedCallback = isSelectedCallback
	dropdown.onSelectionCallback = onSelectionCallback
	dropdown.entryLabels = entryLabels
	dropdown.entryValues = entryValues
	
	-- Initialize the dropdown
	UIDropDownMenu_Initialize(dropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:182:37");
		level = level or 1
		for i = 1, #entryLabels do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entryLabels[i]
			info.value = entryValues[i]
			info.checked = isSelectedCallback(entryValues[i])
			info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:189:15");
				onSelectionCallback(entryValues[i])
				UIDropDownMenu_SetText(dropdown, entryLabels[i])
				CloseDropDownMenus()
			Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:189:15"); end
			UIDropDownMenu_AddButton(info, level)
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:182:37"); end)
	
	-- Set initial text
	for i = 1, #entryValues do
		if isSelectedCallback(entryValues[i]) then
			UIDropDownMenu_SetText(dropdown, entryLabels[i])
			break
		end
	end
	
	UIDropDownMenu_SetWidth(dropdown, 150)
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreateClassicDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:165:6"); return dropdown
end

function Components:CreateDropdown(parent, labelText, entries, isSelectedCallback, onSelectionCallback) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:211:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label (left side, right-justified)
	local label = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetPoint("LEFT", holder, "LEFT", 0, 0)
	label:SetJustifyH("RIGHT")
	label:SetText(labelText)
	
	local dropdown
	
	-- Classic mode: Use UIDropDownMenuTemplate
	if BFL.IsClassic or not BFL.HasModernMenu then
		dropdown = CreateClassicDropdown(holder, entries, isSelectedCallback, onSelectionCallback)
		dropdown:SetPoint("LEFT", holder, "LEFT", 140, 0)
	else
		-- Retail: Use modern WowStyle1DropdownTemplate
		dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
		dropdown:SetWidth(180)
		dropdown:SetPoint("LEFT", holder, "LEFT", 150, 0) -- Doubled from 75 to 150
		
		-- Apply BetterFriendlist styling (Use STRINGS to ensure they are found)
		dropdown:SetNormalFontObject("BetterFriendlistFontHighlightSmall")
		dropdown:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
		dropdown:SetDisabledFontObject("BetterFriendlistFontDisableSmall")
		
		-- Force update the text if it exists
		if dropdown.Text then
			dropdown.Text:SetFontObject("BetterFriendlistFontHighlightSmall")
		end
		
		-- Initialize with provided entries using modern API
		if entries and entries.labels and entries.values then
			local entryLabels = entries.labels
			local entryValues = entries.values
			
			-- Setup the dropdown menu using modern API
			dropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:252:22");
				for i = 1, #entryLabels do
					local radio = rootDescription:CreateButton(entryLabels[i], function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:254:64"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:254:64"); end, entryValues[i])
					radio:SetIsSelected(function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:255:25"); return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:255:25", isSelectedCallback(value)) end)
					radio:SetResponder(function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:256:24"); onSelectionCallback(value) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:256:24"); end)
					
					-- Force font for dropdown items
					radio:AddInitializer(function(button, description, menu) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:259:26");
						local fontString = button.fontString or button.Text
						if fontString then
							fontString:SetFontObject("BetterFriendlistFontNormalSmall")
						end
					Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:259:26"); end)
				end
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:252:22"); end)
			
			-- SetSelectionTranslator: Shows the label of the selected value
			dropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:269:35");
				for i = 1, #entryValues do
					if entryValues[i] == selection.data then
						return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:269:35", entryLabels[i])
					end
				end
				return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:269:35", entryLabels[1]) -- Fallback
			end)
			
			-- Set initial text based on selected value
			for i = 1, #entryValues do
				if isSelectedCallback(entryValues[i]) then
					dropdown:SetText(entryLabels[i])
					break
				end
			end
		end
	end
	
	holder.Label = label
	holder.DropDown = dropdown
	
	-- Tooltip support
	holder.SetTooltip = function(_, title, desc) Perfy_Trace(Perfy_GetTime(), "Enter", "holder.SetTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:292:21");
		dropdown:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:293:32");
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc then
				GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true)
			end
			GameTooltip:Show()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:293:32"); end)
		dropdown:SetScript("OnLeave", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:301:32");
			GameTooltip:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:301:32"); end)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder.SetTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:292:21"); end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:211:0"); return holder
end

-- ========================================
-- INSET SECTION (Visual grouping)
-- InsetFrameTemplate may not exist in Classic - create manual fallback
-- ========================================
function Components:CreateInsetSection(parent, height) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateInsetSection file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:313:0");
	local inset
	
	-- Check if InsetFrameTemplate exists (may not be in all Classic versions)
	if BFL.IsClassic then
		-- Classic: Create simple bordered frame manually
		inset = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		inset:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		inset:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	else
		-- Retail: Use standard InsetFrameTemplate
		inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
	end
	
	inset:SetPoint("LEFT", 20, 0)
	inset:SetPoint("RIGHT", -20, 0)
	inset:SetHeight(height or 100)
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateInsetSection file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:313:0"); return inset
end

-- ========================================
-- SPACER (Empty frame for spacing)
-- ========================================
function Components:CreateSpacer(parent, height) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateSpacer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:343:0");
	local spacer = CreateFrame("Frame", nil, parent)
	spacer:SetHeight(height or math.abs(SPACING_SECTION))
	spacer:SetPoint("LEFT")
	spacer:SetPoint("RIGHT")
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateSpacer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:343:0"); return spacer
end

-- ========================================
-- ROW WITH TWO BUTTONS (For Arrow Up/Down controls)
-- ========================================
function Components:CreateButtonRow(parent, leftText, rightText, leftCallback, rightCallback) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateButtonRow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:354:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Left Button
	local leftButton = CreateFrame("Button", nil, holder, "UIPanelDynamicResizeButtonTemplate")
	leftButton:SetText(leftText)
	DynamicResizeButton_Resize(leftButton)
	leftButton:SetPoint("LEFT", 20, 0)
	leftButton:SetScript("OnClick", leftCallback)
	holder.LeftButton = leftButton
	
	-- Right Button (if provided)
	if rightText and rightCallback then
		local rightButton = CreateFrame("Button", nil, holder, "UIPanelDynamicResizeButtonTemplate")
		rightButton:SetText(rightText)
		DynamicResizeButton_Resize(rightButton)
		rightButton:SetPoint("LEFT", leftButton, "RIGHT", 10, 0)
		rightButton:SetScript("OnClick", rightCallback)
		holder.RightButton = rightButton
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateButtonRow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:354:0"); return holder
end

-- ========================================
-- Helper: Anchor chain for vertical stacking
-- ========================================
function Components:AnchorChain(frames, startY) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:AnchorChain file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:384:0");
	startY = startY or 0
	for i, frame in ipairs(frames) do
		if i == 1 then
			frame:SetPoint("TOP", 0, startY)
		else
			-- Check if previous frame is a header or spacer for different spacing
			local prevFrame = frames[i-1]
			local spacing = SPACING_OPTION
			
			-- Headers get more spacing before them
			if frame.text and frame:GetHeight() == COMPONENT_HEIGHT then
				-- This is likely a header
				spacing = SPACING_SECTION
			end
			
			frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, spacing)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Components:AnchorChain file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:384:0"); end

-- ========================================
-- LIST ITEM (With Up/Down arrows for reordering)
-- ========================================
function Components:CreateListItem(parent, itemText, orderIndex, onMoveUp, onMoveDown, onRename, onColor, onDelete) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateListItem file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:408:0");
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(40)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Background
	holder.bg = holder:CreateTexture(nil, "BACKGROUND")
	holder.bg:SetAllPoints()
	holder.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
	
	-- Order number
	holder.orderText = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	holder.orderText:SetPoint("LEFT", 10, 0)
	holder.orderText:SetText(orderIndex)
	holder.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Item text
	holder.nameText = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	holder.nameText:SetPoint("LEFT", holder.orderText, "RIGHT", 15, 0)
	holder.nameText:SetText(itemText)
	holder.nameText:SetTextColor(1, 0.82, 0)
	
	-- Delete button (fixed position, optional)
	if onDelete then
		holder.deleteButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
		holder.deleteButton:SetSize(28, 28)
		holder.deleteButton:SetPoint("RIGHT", -10, 0)
		
		-- Icon texture
		local deleteIcon = holder.deleteButton:CreateTexture(nil, "ARTWORK")
		deleteIcon:SetSize(18, 18)
		deleteIcon:SetPoint("CENTER")
		deleteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\trash-2")
		deleteIcon:SetVertexColor(1, 0.82, 0)
		holder.deleteButton.icon = deleteIcon
		
		holder.deleteButton:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:445:43");
			if onDelete then onDelete() end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:445:43"); end)
		holder.deleteButton:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:448:43");
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_DELETE_GROUP, 1, 0.1, 0.1)
			GameTooltip:AddLine(L.SETTINGS_DELETE_GROUP_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:448:43"); end)
		holder.deleteButton:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:455:43");
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:455:43"); end)
	end
	
	-- Color button (fixed position, always visible)
	holder.colorButton = CreateFrame("Button", nil, holder)
	holder.colorButton:SetSize(28, 28)
	holder.colorButton:SetPoint("RIGHT", -45, 0)
	
	holder.colorBorder = holder.colorButton:CreateTexture(nil, "BACKGROUND")
	holder.colorBorder:SetAllPoints(holder.colorButton)
	holder.colorBorder:SetColorTexture(0, 0, 0, 1)
	
	holder.colorSwatch = holder.colorButton:CreateTexture(nil, "ARTWORK")
	holder.colorSwatch:SetPoint("TOPLEFT", holder.colorButton, "TOPLEFT", 3, -3)
	holder.colorSwatch:SetPoint("BOTTOMRIGHT", holder.colorButton, "BOTTOMRIGHT", -3, 3)
	holder.colorSwatch:SetColorTexture(1, 0.82, 0)
	
	holder.colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	holder.colorButton:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:476:41");
		if onColor then onColor(holder.colorSwatch) end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:476:41"); end)
	holder.colorButton:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:479:41");
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_GROUP_COLOR, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:479:41"); end)
	holder.colorButton:SetScript("OnLeave", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:485:41");
		GameTooltip:Hide()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:485:41"); end)
	
	-- Rename button (fixed position, optional)
	if onRename then
		holder.renameButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
		holder.renameButton:SetSize(28, 28)
		holder.renameButton:SetPoint("RIGHT", -80, 0)
		
		-- Icon texture
		local renameIcon = holder.renameButton:CreateTexture(nil, "ARTWORK")
		renameIcon:SetSize(18, 18)
		renameIcon:SetPoint("CENTER")
		renameIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\edit")
		renameIcon:SetVertexColor(1, 0.82, 0)
		holder.renameButton.icon = renameIcon
		
		holder.renameButton:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:503:43");
			if onRename then onRename() end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:503:43"); end)
		holder.renameButton:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:506:43");
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_RENAME_GROUP, 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:506:43"); end)
		holder.renameButton:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:513:43");
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:513:43"); end)
	end
	
	-- Down Arrow button (fixed position)
	holder.downButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
	holder.downButton:SetSize(28, 28)
	holder.downButton:SetPoint("RIGHT", -115, 0)
	
	-- Icon texture
	local downIcon = holder.downButton:CreateTexture(nil, "ARTWORK")
	downIcon:SetSize(18, 18)
	downIcon:SetPoint("CENTER")
	downIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-down")
	downIcon:SetVertexColor(1, 0.82, 0)
	holder.downButton.icon = downIcon
	
	holder.downButton:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:532:40");
		if onMoveDown then onMoveDown() end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:532:40"); end)
	holder.downButton:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:535:40");
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_MOVE_DOWN, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_MOVE_DOWN_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:535:40"); end)
	holder.downButton:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:542:40");
		self.icon:SetVertexColor(1, 0.82, 0)
		GameTooltip:Hide()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:542:40"); end)
	
	-- Up Arrow button (fixed position)
	holder.upButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
	holder.upButton:SetSize(28, 28)
	holder.upButton:SetPoint("RIGHT", -150, 0)
	
	-- Icon texture
	local upIcon = holder.upButton:CreateTexture(nil, "ARTWORK")
	upIcon:SetSize(18, 18)
	upIcon:SetPoint("CENTER")
	upIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-up")
	upIcon:SetVertexColor(1, 0.82, 0)
	holder.upButton.icon = upIcon
	
	holder.upButton:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:560:38");
		if onMoveUp then onMoveUp() end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:560:38"); end)
	holder.upButton:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:563:38");
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_MOVE_UP, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_MOVE_UP_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:563:38"); end)
	holder.upButton:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:570:38");
		self.icon:SetVertexColor(1, 0.82, 0)
		GameTooltip:Hide()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:570:38"); end)
	
	-- Store order index
	holder.orderIndex = orderIndex
	
	-- Function to update order display
	function holder:SetOrderIndex(newIndex) Perfy_Trace(Perfy_GetTime(), "Enter", "holder:SetOrderIndex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:579:1");
		holder.orderIndex = newIndex
		holder.orderText:SetText(newIndex)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder:SetOrderIndex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:579:1"); end
	
	-- Function to enable/disable arrow buttons
	function holder:SetArrowState(canMoveUp, canMoveDown) Perfy_Trace(Perfy_GetTime(), "Enter", "holder:SetArrowState file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:585:1");
		holder.upButton:SetEnabled(canMoveUp)
		holder.downButton:SetEnabled(canMoveDown)
	Perfy_Trace(Perfy_GetTime(), "Leave", "holder:SetArrowState file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:585:1"); end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateListItem file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:408:0"); return holder
end

-- ========================================
-- CreateButton
-- ========================================
function Components:CreateButton(parent, text, onClick, tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "Components:CreateButton file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:596:0");
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(180, 24)
	button:SetText(text)
	
	-- Apply BetterFriendlist styling
	button:SetNormalFontObject("BetterFriendlistFontNormal")
	button:SetHighlightFontObject("BetterFriendlistFontHighlight")
	button:SetDisabledFontObject("BetterFriendlistFontDisable")
	
	if onClick then
		button:SetScript("OnClick", onClick)
	end
	
	if tooltip then
		button:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:611:30");
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:611:30"); end)
		button:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:616:30");
			GameTooltip:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:616:30"); end)
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Components:CreateButton file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua:596:0"); return button
end

-- ========================================
-- Export
-- ========================================
Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/SettingsComponents.lua"); return Components

