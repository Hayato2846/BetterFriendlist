-- SettingsComponents.lua
-- Reusable UI components for Settings panel (Platynator-style)

local ADDON_NAME, BFL = ...
BFL.SettingsComponents = {}

local Components = BFL.SettingsComponents

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
	holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	holder.text:SetText(text)
	holder.text:SetPoint("LEFT", 0, 0)
	holder.text:SetJustifyH("LEFT")
	holder:SetHeight(COMPONENT_HEIGHT)
	return holder
end

-- ========================================
-- CHECKBOX (Label left, Checkbox right)
-- ========================================
function Components:CreateCheckbox(parent, labelText, initialValue, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Checkbox: links positioniert
	local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")
	checkBox:SetPoint("LEFT", holder, "LEFT", 0, 0)
	checkBox:SetText(labelText)
	checkBox:SetNormalFontObject(GameFontHighlight)
	
	-- Label: rechts neben der Checkbox
	local label = checkBox:GetFontString()
	label:ClearAllPoints()
	label:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)
	label:SetJustifyH("LEFT")
	label:SetWidth(300)
	
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
	holder.Label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
-- ========================================
function Components:CreateDropdown(parent, labelText, entries, isSelectedCallback, onSelectionCallback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label (left side, right-justified)
	local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetPoint("LEFT", holder, "LEFT", 0, 0)
	label:SetJustifyH("RIGHT")
	label:SetText(labelText)
	
	-- Dropdown (right side)
	local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(180)
	dropdown:SetPoint("LEFT", holder, "LEFT", 150, 0) -- Doubled from 75 to 150
	
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
	
	holder.Label = label
	holder.DropDown = dropdown
	
	return holder
end

-- ========================================
-- INSET SECTION (Visual grouping)
-- ========================================
function Components:CreateInsetSection(parent, height)
	local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
	inset:SetPoint("LEFT", 20, 0)
	inset:SetPoint("RIGHT", -20, 0)
	inset:SetHeight(height or 100)
	return inset
end

-- ========================================
-- BUTTON (Dynamic resize, centered or anchored)
-- ========================================
function Components:CreateButton(parent, text, callback)
	local button = CreateFrame("Button", nil, parent, "UIPanelDynamicResizeButtonTemplate")
	button:SetText(text)
	DynamicResizeButton_Resize(button)
	button:SetScript("OnClick", callback)
	return button
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
-- LIST ITEM WITH ARROW BUTTONS (For Group ordering)
-- ========================================
function Components:CreateListItem(parent, text, upCallback, downCallback, editCallback, deleteCallback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(32)
	holder:SetPoint("LEFT")
	holder:SetPoint("RIGHT")
	
	-- Background
	holder.bg = holder:CreateTexture(nil, "BACKGROUND")
	holder.bg:SetAllPoints()
	holder.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
	
	-- Text Label (left side)
	holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	holder.text:SetPoint("LEFT", 10, 0)
	holder.text:SetText(text)
	holder.text:SetTextColor(1, 1, 1)
	
	-- Button container (right side)
	local btnX = -10
	local btnSpacing = 28
	
	-- Delete Button (rightmost)
	if deleteCallback then
		local deleteBtn = CreateFrame("Button", nil, holder)
		deleteBtn:SetSize(24, 24)
		deleteBtn:SetPoint("RIGHT", btnX, 0)
		deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		deleteBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		deleteBtn:SetScript("OnClick", deleteCallback)
		deleteBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Delete", 1, 1, 1)
			GameTooltip:Show()
		end)
		deleteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		holder.DeleteButton = deleteBtn
		btnX = btnX - btnSpacing
	end
	
	-- Edit Button
	if editCallback then
		local editBtn = CreateFrame("Button", nil, holder)
		editBtn:SetSize(24, 24)
		editBtn:SetPoint("RIGHT", btnX, 0)
		editBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		editBtn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		editBtn:SetScript("OnClick", editCallback)
		editBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Edit", 1, 1, 1)
			GameTooltip:Show()
		end)
		editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		holder.EditButton = editBtn
		btnX = btnX - btnSpacing
	end
	
	-- Down Arrow
	if downCallback then
		local downBtn = CreateFrame("Button", nil, holder)
		downBtn:SetSize(24, 24)
		downBtn:SetPoint("RIGHT", btnX, 0)
		downBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
		downBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
		downBtn:SetScript("OnClick", downCallback)
		downBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Move Down", 1, 1, 1)
			GameTooltip:Show()
		end)
		downBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		holder.DownButton = downBtn
		btnX = btnX - btnSpacing
	end
	
	-- Up Arrow
	if upCallback then
		local upBtn = CreateFrame("Button", nil, holder)
		upBtn:SetSize(24, 24)
		upBtn:SetPoint("RIGHT", btnX, 0)
		upBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		upBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		upBtn:SetScript("OnClick", upCallback)
		upBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Move Up", 1, 1, 1)
			GameTooltip:Show()
		end)
		upBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		holder.UpButton = upBtn
	end
	
	function holder:SetText(newText)
		holder.text:SetText(newText)
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
	holder.orderText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	holder.orderText:SetPoint("LEFT", 10, 0)
	holder.orderText:SetText(orderIndex)
	holder.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Item text
	holder.nameText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
			GameTooltip:SetText("Delete Group", 1, 0.1, 0.1)
			GameTooltip:AddLine("Remove this custom group", 0.8, 0.8, 0.8, true)
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
		GameTooltip:SetText("Group Color", 1, 1, 1)
		GameTooltip:AddLine("Click to change the group color", 0.8, 0.8, 0.8, true)
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
			GameTooltip:SetText("Rename Group", 1, 1, 1)
			GameTooltip:AddLine("Change the group name", 0.8, 0.8, 0.8, true)
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
		GameTooltip:SetText("Move Down", 1, 1, 1)
		GameTooltip:AddLine("Move this group down in the list", 0.8, 0.8, 0.8, true)
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
		GameTooltip:SetText("Move Up", 1, 1, 1)
		GameTooltip:AddLine("Move this group up in the list", 0.8, 0.8, 0.8, true)
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
