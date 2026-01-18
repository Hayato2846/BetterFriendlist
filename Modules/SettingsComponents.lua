-- SettingsComponents.lua
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
function Components:CreateHeader(parent, text)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	holder.text = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormalLarge")
	holder.text:SetText(text)
	holder.text:SetPoint("LEFT", 0, 0)
	holder.text:SetJustifyH("LEFT")
	holder:SetHeight(COMPONENT_HEIGHT)
	return holder
end

-- ========================================
-- CHECKBOX (Label left, Checkbox right)
-- Classic uses InterfaceOptionsCheckButtonTemplate, Retail uses SettingsCheckboxTemplate
-- ========================================
function Components:CreateCheckbox(parent, labelText, initialValue, callback)
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
	checkBox:SetScript("OnClick", function(self)
		callback(self:GetChecked())
	end)
	
	-- Fix for ugly hover effect when no tooltip is present
	checkBox:SetScript("OnEnter", function() end)
	checkBox:SetScript("OnLeave", function() end)
	
	-- Tooltip support
	holder.SetTooltip = function(_, title, desc)
		checkBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc then
				GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true)
			end
			GameTooltip:Show()
		end)
		checkBox:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	function holder:SetValue(value)
		checkBox:SetChecked(value)
	end
	
	function holder:GetValue()
		return checkBox:GetChecked()
	end
	
	holder.checkBox = checkBox
	return holder
end

-- ========================================
-- SLIDER (Label left, Slider right)
-- ========================================
function Components:CreateSlider(parent, labelText, min, max, initialValue, formatter, callback)
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
	
	holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		callback(value)
	end)
	
	function holder:SetValue(value)
		holder.Slider:SetValue(value)
	end
	
	function holder:GetValue()
		return holder.Slider:GetValue()
	end
	
	return holder
end

-- ========================================
-- DROPDOWN (Label left, Dropdown right)
-- Classic uses UIDropDownMenuTemplate, Retail uses WowStyle1DropdownTemplate
-- ========================================

-- Classic dropdown counter for unique names
local classicDropdownCounter = 0

-- Create Classic-style dropdown using UIDropDownMenu
local function CreateClassicDropdown(parent, entries, isSelectedCallback, onSelectionCallback)
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
	UIDropDownMenu_Initialize(dropdown, function(self, level)
		level = level or 1
		for i = 1, #entryLabels do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entryLabels[i]
			info.value = entryValues[i]
			info.checked = isSelectedCallback(entryValues[i])
			info.func = function()
				onSelectionCallback(entryValues[i])
				UIDropDownMenu_SetText(dropdown, entryLabels[i])
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	
	-- Set initial text
	for i = 1, #entryValues do
		if isSelectedCallback(entryValues[i]) then
			UIDropDownMenu_SetText(dropdown, entryLabels[i])
			break
		end
	end
	
	UIDropDownMenu_SetWidth(dropdown, 150)
	
	return dropdown
end

function Components:CreateDropdown(parent, labelText, entries, isSelectedCallback, onSelectionCallback)
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
			dropdown:SetupMenu(function(dropdown, rootDescription)
				for i = 1, #entryLabels do
					local radio = rootDescription:CreateButton(entryLabels[i], function() end, entryValues[i])
					radio:SetIsSelected(function(value) return isSelectedCallback(value) end)
					radio:SetResponder(function(value) onSelectionCallback(value) end)
					
					-- Force font for dropdown items
					radio:AddInitializer(function(button, description, menu)
						local fontString = button.fontString or button.Text
						if fontString then
							fontString:SetFontObject("BetterFriendlistFontNormalSmall")
						end
					end)
				end
			end)
			
			-- SetSelectionTranslator: Shows the label of the selected value
			dropdown:SetSelectionTranslator(function(selection)
				for i = 1, #entryValues do
					if entryValues[i] == selection.data then
						return entryLabels[i]
					end
				end
				return entryLabels[1] -- Fallback
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
	holder.SetTooltip = function(_, title, desc)
		dropdown:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc then
				GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true)
			end
			GameTooltip:Show()
		end)
		dropdown:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	return holder
end

-- ========================================
-- INSET SECTION (Visual grouping)
-- InsetFrameTemplate may not exist in Classic - create manual fallback
-- ========================================
function Components:CreateInsetSection(parent, height)
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
	return inset
end

-- ========================================
-- SPACER (Empty frame for spacing)
-- ========================================
function Components:CreateSpacer(parent, height)
	local spacer = CreateFrame("Frame", nil, parent)
	spacer:SetHeight(height or math.abs(SPACING_SECTION))
	spacer:SetPoint("LEFT")
	spacer:SetPoint("RIGHT")
	return spacer
end

-- ========================================
-- ROW WITH TWO BUTTONS (For Arrow Up/Down controls)
-- ========================================
function Components:CreateButtonRow(parent, leftText, rightText, leftCallback, rightCallback)
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
	
	return holder
end

-- ========================================
-- Helper: Anchor chain for vertical stacking
-- ========================================
function Components:AnchorChain(frames, startY)
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
end

-- ========================================
-- LIST ITEM (With Up/Down arrows for reordering)
-- ========================================
function Components:CreateListItem(parent, itemText, orderIndex, onMoveUp, onMoveDown, onRename, onColor, onDelete)
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
		
		holder.deleteButton:SetScript("OnClick", function()
			if onDelete then onDelete() end
		end)
		holder.deleteButton:SetScript("OnEnter", function(self)
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_DELETE_GROUP, 1, 0.1, 0.1)
			GameTooltip:AddLine(L.SETTINGS_DELETE_GROUP_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		holder.deleteButton:SetScript("OnLeave", function(self)
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		end)
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
	holder.colorButton:SetScript("OnClick", function()
		if onColor then onColor(holder.colorSwatch) end
	end)
	holder.colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_GROUP_COLOR, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	holder.colorButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
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
		
		holder.renameButton:SetScript("OnClick", function()
			if onRename then onRename() end
		end)
		holder.renameButton:SetScript("OnEnter", function(self)
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_RENAME_GROUP, 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		holder.renameButton:SetScript("OnLeave", function(self)
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		end)
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
	
	holder.downButton:SetScript("OnClick", function()
		if onMoveDown then onMoveDown() end
	end)
	holder.downButton:SetScript("OnEnter", function(self)
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_MOVE_DOWN, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_MOVE_DOWN_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	holder.downButton:SetScript("OnLeave", function(self)
		self.icon:SetVertexColor(1, 0.82, 0)
		GameTooltip:Hide()
	end)
	
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
	
	holder.upButton:SetScript("OnClick", function()
		if onMoveUp then onMoveUp() end
	end)
	holder.upButton:SetScript("OnEnter", function(self)
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_MOVE_UP, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_MOVE_UP_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	holder.upButton:SetScript("OnLeave", function(self)
		self.icon:SetVertexColor(1, 0.82, 0)
		GameTooltip:Hide()
	end)
	
	-- Store order index
	holder.orderIndex = orderIndex
	
	-- Function to update order display
	function holder:SetOrderIndex(newIndex)
		holder.orderIndex = newIndex
		holder.orderText:SetText(newIndex)
	end
	
	-- Function to enable/disable arrow buttons
	function holder:SetArrowState(canMoveUp, canMoveDown)
		holder.upButton:SetEnabled(canMoveUp)
		holder.downButton:SetEnabled(canMoveDown)
	end
	
	return holder
end

-- ========================================
-- CreateButton
-- ========================================
function Components:CreateButton(parent, text, onClick, tooltip)
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
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end
	
	return button
end

-- ========================================
-- Export
-- ========================================
return Components

