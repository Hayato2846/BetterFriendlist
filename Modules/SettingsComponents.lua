-- SettingsComponents.lua
-- Reusable UI components for Settings panel (Platynator-style)

local ADDON_NAME, BFL = ...
BFL.SettingsComponents = {}

local Components = BFL.SettingsComponents
local L = BFL.L or BFL_L

-- ========================================
-- Constants
-- ========================================
local COMPONENT_HEIGHT = 24 -- Taller for better touch targets/readability
local FIELD_WIDTH = 140      -- Default button width
local PADDING_LEFT = 20
local PADDING_RIGHT = 20
local SPACING_SECTION = -15
local SPACING_OPTION = -10

-- Layout Grid Constants (Dynamic)
-- We use percentages for responsiveness
local LABEL_PCT = 0.30       -- Label takes 30% of available width
local CONTROL_GAP = 10       -- Gap between Label and Control

-- Alignment Tweaks (Visual Correction)
local DROPDOWN_X_OFFSET = -8 -- Shift Dropdowns left to align visually with Checkboxes
local DROPDOWN_WIDTH_BONUS = 8 -- Add the shift back as width

-- ========================================
-- HEADERS
-- ========================================
function Components:CreateHeader(parent, text)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetPoint("LEFT", 5, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	holder.text = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormalLarge")
	holder.text:SetText(text)
	holder.text:SetPoint("LEFT", 0, 0)
	holder.text:SetPoint("RIGHT", 0, 0)
	holder.text:SetJustifyH("LEFT")
	holder:SetHeight(COMPONENT_HEIGHT + 5) -- More breathing room
	return holder
end

-- ========================================
-- CHECKBOX (Label Left, Checkbox Right - Grid Aligned)
-- ========================================
function Components:CreateCheckbox(parent, labelText, initialValue, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label: Dynamic Width, Left Aligned
	local label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(labelText)

	-- Choose template based on game version
	local template = "SettingsCheckboxTemplate"
	if BFL.IsClassic then
		template = "InterfaceOptionsCheckButtonTemplate"
	end
	
	-- Checkbox dynamic positioning
	local checkBox = CreateFrame("CheckButton", nil, holder, template)
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		label:SetWidth(labelWidth)
		-- Checkbox starts after label
		checkBox:SetPoint("LEFT", self, "LEFT", labelWidth + CONTROL_GAP, 0)
	end)
	
	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	-- Standardize text cleaning (we use external label now)
	if checkBox.Text then
		checkBox.Text:SetText("")
	else
		-- Try to find fontstring region if .Text alias doesn't exist
		local regions = {checkBox:GetRegions()}
		for _, region in ipairs(regions) do
			if region:GetObjectType() == "FontString" then
				region:SetText("")
			end
		end
	end
	
	-- For Retail, SetText might work directly
	if checkBox.SetText then
		checkBox:SetText("")
	end
	
	checkBox:SetChecked(initialValue)
	checkBox:SetScript("OnClick", function(self)
		callback(self:GetChecked())
	end)
	
	-- Clean tooltip handling
	checkBox:SetScript("OnEnter", function() end)
	checkBox:SetScript("OnLeave", function() end)
	
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
	
	holder.Label = label -- Expose label
	holder.checkBox = checkBox
	return holder
end

-- ========================================
-- SLIDER (Label Left, Slider Right - Grid Aligned)
-- ========================================
function Components:CreateSlider(parent, labelText, min, max, initialValue, formatter, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label: Dynamic Width, Left Aligned
	holder.Label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.Label:SetJustifyH("LEFT")
	holder.Label:SetPoint("LEFT", 0, 0)
	holder.Label:SetText(labelText)
	
	-- Slider: Dynamic positioning
	holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
	holder.Slider:SetHeight(20)
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		holder.Label:SetWidth(labelWidth)
		
		holder.Slider:ClearAllPoints()
		holder.Slider:SetPoint("LEFT", self, "LEFT", labelWidth + CONTROL_GAP, 0)
		holder.Slider:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
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
-- DROPDOWN (Label Left, Dropdown Right - Grid Aligned)
-- ========================================
-- Classic dropdown counter
local classicDropdownCounter = 0

local function CreateClassicDropdown(parent, entries, isSelectedCallback, onSelectionCallback)
	classicDropdownCounter = classicDropdownCounter + 1
	local dropdownName = "BFLSettingsDropdown" .. classicDropdownCounter
	
	local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	-- Note: UIDropDownMenu widths are quirky. 150 width + padding buttons ~ 180 total
	
	local entryLabels = entries.labels
	local entryValues = entries.values
	
	dropdown.isSelectedCallback = isSelectedCallback
	dropdown.onSelectionCallback = onSelectionCallback
	
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
	
	for i = 1, #entryValues do
		if isSelectedCallback(entryValues[i]) then
			UIDropDownMenu_SetText(dropdown, entryLabels[i])
			break
		end
	end
	
	UIDropDownMenu_SetWidth(dropdown, 150)
	UIDropDownMenu_JustifyText(dropdown, "LEFT")
	
	return dropdown
end

function Components:CreateDropdown(parent, labelText, entries, isSelectedCallback, onSelectionCallback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT + 8) -- Dropdowns are taller
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label: Dynamic Width, Left Aligned
	local label = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(labelText)
	
	local dropdown
	
	if BFL.IsClassic or not BFL.HasModernMenu then
		dropdown = CreateClassicDropdown(holder, entries, isSelectedCallback, onSelectionCallback)
		-- Classic dropdown dynamic positioning handled in OnSizeChanged below
	else
		-- Retail WowStyle1DropdownTemplate
		dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
		
		dropdown:SetNormalFontObject("BetterFriendlistFontHighlightSmall")
		dropdown:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
		dropdown:SetDisabledFontObject("BetterFriendlistFontDisableSmall")
		
		if dropdown.Text then
			dropdown.Text:SetFontObject("BetterFriendlistFontHighlightSmall")
			dropdown.Text:SetJustifyH("LEFT")
		end
		
		if entries and entries.labels and entries.values then
			local entryLabels = entries.labels
			local entryValues = entries.values
			
			dropdown:SetupMenu(function(dropdown, rootDescription)
				for i = 1, #entryLabels do
					local radio = rootDescription:CreateButton(entryLabels[i], function() end, entryValues[i])
					radio:SetIsSelected(function(value) return isSelectedCallback(value) end)
					radio:SetResponder(function(value) onSelectionCallback(value) end)
					
					radio:AddInitializer(function(button)
						if button.fontString then
							button.fontString:SetFontObject("BetterFriendlistFontNormalSmall")
						end
					end)
				end
			end)
			
			dropdown:SetSelectionTranslator(function(selection)
				for i = 1, #entryValues do
					if entryValues[i] == selection.data then
						return entryLabels[i]
					end
				end
				return entryLabels[1]
			end)
			
			-- Initial text
			for i = 1, #entryValues do
				if isSelectedCallback(entryValues[i]) then
					dropdown:SetText(entryLabels[i])
					break
				end
			end
		end
	end
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		label:SetWidth(labelWidth)
		
		local dropdownStart = labelWidth + CONTROL_GAP
		
		-- Dropdown positioning
		if BFL.IsClassic or not BFL.HasModernMenu then
			dropdown:ClearAllPoints()
			dropdown:SetPoint("LEFT", self, "LEFT", dropdownStart - 15 + DROPDOWN_X_OFFSET, 0)
			-- Calculate remaining width for Classic dropdown (adjusting for its padding quirk)
			local remainingWidth = width - dropdownStart - 20 - PADDING_RIGHT -- approximate
			UIDropDownMenu_SetWidth(dropdown, remainingWidth + DROPDOWN_WIDTH_BONUS)
		else
			dropdown:ClearAllPoints()
			dropdown:SetPoint("LEFT", self, "LEFT", dropdownStart + DROPDOWN_X_OFFSET, 0)
			-- Retail dropdowns behave better with anchors
			dropdown:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		end
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	holder.Label = label
	holder.DropDown = dropdown
	
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
-- COLOR PICKER (Label Left, Button Right - Grid Aligned)
-- ========================================
function Components:CreateColorPicker(parent, labelText, initialColor, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label
	local label = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(labelText)
	
	-- Color Button starts at CONTROL_OFFSET
	local colorButton = CreateFrame("Button", nil, holder)
	colorButton:SetSize(28, 28)
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		label:SetWidth(labelWidth)
		colorButton:SetPoint("LEFT", self, "LEFT", labelWidth + CONTROL_GAP, 0)
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	local colorBorder = colorButton:CreateTexture(nil, "BACKGROUND")
	colorBorder:SetAllPoints(colorButton)
	colorBorder:SetColorTexture(0, 0, 0, 1) -- Black border
	
	local colorSwatch = colorButton:CreateTexture(nil, "ARTWORK")
	colorSwatch:SetPoint("TOPLEFT", colorButton, "TOPLEFT", 3, -3)
	colorSwatch:SetPoint("BOTTOMRIGHT", colorButton, "BOTTOMRIGHT", -3, 3)
	
	-- Highlight
	colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	-- Tooltip
	colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_FONT_COLOR or "Font Color", 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	colorButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	if initialColor then
		colorSwatch:SetColorTexture(initialColor.r, initialColor.g, initialColor.b, initialColor.a or 1)
	else
		colorSwatch:SetColorTexture(1, 1, 1, 1)
	end
	
	-- Expose update method
	function holder:SetColor(r, g, b, a)
		holder.currentColor = {r=r, g=g, b=b, a=a or 1}
		colorSwatch:SetColorTexture(r, g, b, a or 1)
	end
	
	-- Store initial
	holder:SetColor(initialColor and initialColor.r or 1, initialColor and initialColor.g or 1, initialColor and initialColor.b or 1, initialColor and initialColor.a or 1)
	
	colorButton:SetScript("OnClick", function()
		local r, g, b, a = holder.currentColor.r, holder.currentColor.g, holder.currentColor.b, holder.currentColor.a or 1
		
		local info = {
			r = r, g = g, b = b, opacity = a, hasOpacity = true,
			swatchFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = ColorPickerFrame:GetOpacity()
				holder:SetColor(nr, ng, nb, na)
				if callback then callback(nr, ng, nb, na) end
			end,
			opacityFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = ColorPickerFrame:GetOpacity()
				holder:SetColor(nr, ng, nb, na)
				if callback then callback(nr, ng, nb, na) end
			end,
			cancelFunc = function(prev)
				holder:SetColor(prev.r, prev.g, prev.b, prev.opacity)
				if callback then callback(prev.r, prev.g, prev.b, prev.opacity) end
			end
		}
		
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			ColorPickerFrame.func = info.swatchFunc
			ColorPickerFrame.opacityFunc = info.opacityFunc
			ColorPickerFrame.cancelFunc = info.cancelFunc
			ColorPickerFrame.hasOpacity = info.hasOpacity
			ColorPickerFrame.opacity = info.opacity
			ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
			ColorPickerFrame:Show()
		end
	end)
	
	return holder
end

-- ========================================
-- SLIDER WITH COLOR PICKER (Combined Row)
-- ========================================
function Components:CreateSliderWithColorPicker(parent, labelText, min, max, initialValue, formatter, sliderCallback, initialColor, colorCallback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label
	holder.Label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.Label:SetJustifyH("LEFT")
	holder.Label:SetPoint("LEFT", 0, 0)
	holder.Label:SetText(labelText)
	
	-- Color Button (Right aligned)
	local colorButton = CreateFrame("Button", nil, holder)
	colorButton:SetSize(28, 28)
	
	local colorBorder = colorButton:CreateTexture(nil, "BACKGROUND")
	colorBorder:SetAllPoints(colorButton)
	colorBorder:SetColorTexture(0, 0, 0, 1) -- Black border
	
	local colorSwatch = colorButton:CreateTexture(nil, "ARTWORK")
	colorSwatch:SetPoint("TOPLEFT", colorButton, "TOPLEFT", 3, -3)
	colorSwatch:SetPoint("BOTTOMRIGHT", colorButton, "BOTTOMRIGHT", -3, 3)
	
	-- Highlight
	colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	-- Tooltip
	colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_FONT_COLOR or "Font Color", 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	colorButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Color Logic
	holder.currentColor = initialColor or {r=1, g=1, b=1, a=1}
	colorSwatch:SetColorTexture(holder.currentColor.r, holder.currentColor.g, holder.currentColor.b, holder.currentColor.a or 1)
	
	colorButton:SetScript("OnClick", function()
		local r, g, b, a = holder.currentColor.r, holder.currentColor.g, holder.currentColor.b, holder.currentColor.a or 1
		
		local info = {
			r = r, g = g, b = b, opacity = a, hasOpacity = true,
			swatchFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				-- Retail 11.x uses GetColorAlpha, not GetOpacity for ColorPickerFrame when using new API mixin
				local na = 1
				if ColorPickerFrame.GetColorAlpha then
					na = ColorPickerFrame:GetColorAlpha()
				elseif ColorPickerFrame.GetOpacity then
					na = ColorPickerFrame:GetOpacity()
				end
				
				holder.currentColor = {r=nr, g=ng, b=nb, a=na}
				colorSwatch:SetColorTexture(nr, ng, nb, na)
				if colorCallback then colorCallback(nr, ng, nb, na) end
			end,
			opacityFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				-- Retail 11.x uses GetColorAlpha, not GetOpacity for ColorPickerFrame when using new API mixin
				local na = 1
				if ColorPickerFrame.GetColorAlpha then
					na = ColorPickerFrame:GetColorAlpha()
				elseif ColorPickerFrame.GetOpacity then
					na = ColorPickerFrame:GetOpacity()
				end
				
				holder.currentColor = {r=nr, g=ng, b=nb, a=na}
				colorSwatch:SetColorTexture(nr, ng, nb, na)
				if colorCallback then colorCallback(nr, ng, nb, na) end
			end,
			cancelFunc = function(prev)
				holder.currentColor = {r=prev.r, g=prev.g, b=prev.b, a=prev.opacity}
				colorSwatch:SetColorTexture(prev.r, prev.g, prev.b, prev.opacity)
				if colorCallback then colorCallback(prev.r, prev.g, prev.b, prev.opacity) end
			end
		}
		
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			ColorPickerFrame.func = info.swatchFunc
			ColorPickerFrame.opacityFunc = info.opacityFunc
			ColorPickerFrame.cancelFunc = info.cancelFunc
			ColorPickerFrame.hasOpacity = info.hasOpacity
			ColorPickerFrame.opacity = info.opacity
			ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
			ColorPickerFrame:Show()
		end
	end)

	-- Slider (Left of Color Button)
	holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
	holder.Slider:SetHeight(20)
	
	-- Value Label (Centered in gap)
	holder.ValueLabel = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.ValueLabel:SetJustifyH("CENTER")
	
	-- Layout Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		holder.Label:SetWidth(labelWidth)
		
		-- Color Button hard anchored Right
		colorButton:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		
		-- Value Label centered between Slider and ColorButton
		-- Reserve ~40px for value
		holder.ValueLabel:SetWidth(30)
		holder.ValueLabel:ClearAllPoints()
		holder.ValueLabel:SetPoint("RIGHT", colorButton, "LEFT", -5, 0)
		
		-- Slider fills space between Label and ValueLabel
		holder.Slider:ClearAllPoints()
		holder.Slider:SetPoint("LEFT", self, "LEFT", labelWidth + CONTROL_GAP, 0)
		holder.Slider:SetPoint("RIGHT", holder.ValueLabel, "LEFT", -5, 0)
	end)

	-- Trigger Layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	-- Init slider without built-in label (we use our own)
	holder.Slider:Init(initialValue, min, max, max - min, {})
	
	-- Set initial text
	holder.ValueLabel:SetText(formatter(initialValue))
	
	holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		sliderCallback(value)
		holder.ValueLabel:SetText(formatter(value))
	end)
	
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
	button:SetSize(FIELD_WIDTH, 24)
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
-- DOUBLE CHECKBOX ROW (Two columns, Dynamic)
-- ========================================
function Components:CreateDoubleCheckbox(parent, leftData, rightData)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	local template = "SettingsCheckboxTemplate"
	if BFL.IsClassic then
		template = "InterfaceOptionsCheckButtonTemplate"
	end
	
	-- Create Left Pair (Label + Checkbox)
	local leftLabel, leftCheck
	if leftData then
		leftLabel = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
		leftLabel:SetJustifyH("LEFT")
		leftLabel:SetText(leftData.label)
		
		leftCheck = CreateFrame("CheckButton", nil, holder, template)
		
		if leftCheck.Text then leftCheck.Text:SetText("") end
		if leftCheck.SetText then leftCheck:SetText("") end
		local regions = {leftCheck:GetRegions()}
		for _, region in ipairs(regions) do
			if region:GetObjectType() == "FontString" then region:SetText("") end
		end
		
		leftCheck:SetChecked(leftData.initialValue)
		leftCheck:SetScript("OnClick", function(self) if leftData.callback then leftData.callback(self:GetChecked()) end end)
		leftCheck:SetScript("OnEnter", function(self)
			if leftData.tooltipTitle then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(leftData.tooltipTitle, 1, 1, 1)
				if leftData.tooltipDesc then GameTooltip:AddLine(leftData.tooltipDesc, 0.8, 0.8, 0.8, true) end
				GameTooltip:Show()
			end
		end)
		leftCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	
	-- Create Right Pair (Label + Checkbox)
	local rightLabel, rightCheck
	if rightData then
		rightLabel = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
		rightLabel:SetJustifyH("LEFT")
		rightLabel:SetText(rightData.label)
		
		rightCheck = CreateFrame("CheckButton", nil, holder, template)
		
		if rightCheck.Text then rightCheck.Text:SetText("") end
		if rightCheck.SetText then rightCheck:SetText("") end
		local regions = {rightCheck:GetRegions()}
		for _, region in ipairs(regions) do
			if region:GetObjectType() == "FontString" then region:SetText("") end
		end
		
		rightCheck:SetChecked(rightData.initialValue)
		rightCheck:SetScript("OnClick", function(self) if rightData.callback then rightData.callback(self:GetChecked()) end end)
		rightCheck:SetScript("OnEnter", function(self)
			if rightData.tooltipTitle then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(rightData.tooltipTitle, 1, 1, 1)
				if rightData.tooltipDesc then GameTooltip:AddLine(rightData.tooltipDesc, 0.8, 0.8, 0.8, true) end
				GameTooltip:Show()
			end
		end)
		rightCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		local labelWidth = width * LABEL_PCT
		
		-- Position Left Pair
		if leftLabel and leftCheck then
			leftLabel:SetWidth(labelWidth)
			leftLabel:SetPoint("LEFT", self, "LEFT", 0, 0)
			leftCheck:SetPoint("LEFT", self, "LEFT", labelWidth + CONTROL_GAP, 0)
		end
		
		-- Position Right Pair
		if rightLabel and rightCheck then
			-- Align Right Column: Checkbox right edge matches frame right edge (flush with Dropdowns)
			rightCheck:ClearAllPoints()
			rightCheck:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			
			rightLabel:ClearAllPoints()
			rightLabel:SetPoint("RIGHT", rightCheck, "LEFT", -CONTROL_GAP, 0)
			rightLabel:SetWidth(labelWidth) -- Optional: Force width for consistency or let it flow
			-- For visual symmetry, we might want to justify Right? Or keep Left?
			-- User asked for alignment. If we keep Left Justify but anchor Right, it might look odd if text is short.
			-- Let's stick to Left Justify for reading, but the block is anchored Right.
		end
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	return holder
end

-- ========================================
-- Export
-- ========================================
return Components

