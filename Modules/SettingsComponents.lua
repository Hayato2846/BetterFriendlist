-- SettingsComponents.lua
-- Reusable UI components for Settings panel

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
-- We no longer use percentage based labels to avoid clipping on narrow items
local CONTROL_GAP = 10       -- Gap between Label and Control
local FIXED_CONTROL_WIDTH = 170 -- Standard width for Dropdowns and Sliders to ensure alignment
local CHECKBOX_X_OFFSET = 4  -- Push checkboxes slightly right to align visual box with Dropdown/Slider edges

-- Alignment Tweaks (Visual Correction)
local DROPDOWN_X_OFFSET = -8 -- Shift Classic Dropdowns left to align visually
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
-- CHECKBOX (Label Left, Checkbox Right - Aligned Right)
-- ========================================
function Components:CreateCheckbox(parent, labelText, initialValue, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT)
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Choose template based on game version
	local template = "SettingsCheckboxTemplate"
	if BFL.IsClassic then
		template = "InterfaceOptionsCheckButtonTemplate"
	end
	
	-- Checkbox dynamic positioning (RIGHT ALIGNED)
	local checkBox = CreateFrame("CheckButton", nil, holder, template)
	-- Default size for these templates is usually 26x26 or 30x29
	-- We anchor it to the RIGHT to ensure alignment across all indented items
	checkBox:SetPoint("RIGHT", holder, "RIGHT", CHECKBOX_X_OFFSET, 0)
	
	-- Label: Fills remaining space
	local label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetPoint("RIGHT", checkBox, "LEFT", -CONTROL_GAP - CHECKBOX_X_OFFSET, 0)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(false) -- Prevent vertical clipping in fixed height row
	label:SetText(labelText)
	
	-- Clean text
	if checkBox.Text then
		checkBox.Text:SetText("")
	else
		local regions = {checkBox:GetRegions()}
		for _, region in ipairs(regions) do
			if region:GetObjectType() == "FontString" then
				region:SetText("")
			end
		end
	end
	if checkBox.SetText then checkBox:SetText("") end
	
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
	
	-- Label
	holder.Label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.Label:SetJustifyH("LEFT")
	holder.Label:SetText(labelText)
	
	-- Slider: Dynamic positioning
	holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
	holder.Slider:SetHeight(16) -- Slightly smaller height for better look
	holder.Slider:SetWidth(FIXED_CONTROL_WIDTH) -- Set initial width immediately to avoid layout issues
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		-- Sliders now use FIXED_CONTROL_WIDTH to align with Dropdowns
		holder.Slider:ClearAllPoints()
		holder.Slider:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		holder.Slider:SetWidth(FIXED_CONTROL_WIDTH)
		
		-- Label takes remaining space
		holder.Label:ClearAllPoints()
		holder.Label:SetPoint("LEFT", self, "LEFT", 0, 0)
		holder.Label:SetPoint("RIGHT", holder.Slider, "LEFT", -CONTROL_GAP, 0)
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	holder.Slider:Init(initialValue, min, max, max - min, {
		[MinimalSliderWithSteppersMixin.Label.Right] = formatter
	})
	
	holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not holder.isUpdatingStep then
			callback(value)
		end
	end)
	
	function holder:SetValue(value)
		holder.Slider:SetValue(value)
	end
	
	function holder:GetValue()
		return holder.Slider:GetValue()
	end
	
	function holder:SetStep(step)
		-- Block callback to prevent unwanted updates during re-init
		holder.isUpdatingStep = true
		
		-- Use current value or initial value if current is unavailable/zero/bad
		local currentVal = holder.Slider:GetValue()
		if not currentVal or (currentVal == 0 and min > 0) then
			currentVal = initialValue
		end
		
		-- Re-Initialize with correct step count to fix buttons and drag snapping
		local steps = (max - min) / step
		holder.Slider:Init(currentVal, min, max, steps, {
			[MinimalSliderWithSteppersMixin.Label.Right] = formatter
		})
		
		if holder.Slider.SetValueStep then
			holder.Slider:SetValueStep(step)
		end
		if holder.Slider.SetObeyStepOnDrag then
			holder.Slider:SetObeyStepOnDrag(true)
		end
		holder.Slider.stepSize = step
		
		-- Restore callback processing
		holder.isUpdatingStep = false
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
	
	-- Classic + ElvUI: Expand clickable button area
	if BFL.IsClassic then
		local isElvUIActive = _G.ElvUI and BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin ~= false
		if isElvUIActive then
			local button = _G[dropdownName.."Button"]
			if button then
				-- Make button fill the entire dropdown width (150px base + padding)
				button:SetSize(150, 24)
				button:ClearAllPoints()
				button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
			end
		end
	end
	
	return dropdown
end

function Components:CreateDropdown(parent, labelText, entries, isSelectedCallback, onSelectionCallback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT + 8) -- Dropdowns are taller
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label
	local label = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	label:SetJustifyH("LEFT")
	label:SetText(labelText)
	
	local dropdown
	
	if BFL.IsClassic or not BFL.HasModernMenu then
		dropdown = CreateClassicDropdown(holder, entries, isSelectedCallback, onSelectionCallback)
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
				-- 300px height limit to ensure scrolling for long lists (e.g. Fonts)
				if rootDescription.SetScrollMode then
					rootDescription:SetScrollMode(300) 
				end
				
				for i = 1, #entryLabels do
					local radio = rootDescription:CreateRadio(entryLabels[i], isSelectedCallback, onSelectionCallback, entryValues[i])
					
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
		-- Valid dropdown width
		local dropdownWidth = FIXED_CONTROL_WIDTH
		
		-- Dropdown positioning (Right Aligned)
		if BFL.IsClassic or not BFL.HasModernMenu then
			dropdown:ClearAllPoints()
			dropdown:SetPoint("RIGHT", self, "RIGHT", DROPDOWN_X_OFFSET, 0)
			UIDropDownMenu_SetWidth(dropdown, dropdownWidth)
		else
			dropdown:ClearAllPoints()
			dropdown:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			dropdown:SetWidth(dropdownWidth)
		end
		
		-- Label (Left Aligned, Fills remaining)
		label:ClearAllPoints()
		label:SetPoint("LEFT", 0, 0)
		label:SetPoint("RIGHT", self, "RIGHT", -dropdownWidth - CONTROL_GAP - 5, 0) -- Adjusted padding
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
	label:SetJustifyH("LEFT")
	label:SetText(labelText)
	
	-- Color Button anchored RIGHT
	local colorButton = CreateFrame("Button", nil, holder)
	colorButton:SetSize(28, 28)
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		-- Anchor ColorButton to RIGHT edge
		colorButton:ClearAllPoints()
		colorButton:SetPoint("RIGHT", self, "RIGHT", 0, 0)

		-- Anchor Label Left and Right (to ColorButton)
		label:ClearAllPoints()
		label:SetPoint("LEFT", self, "LEFT", 0, 0)
		label:SetPoint("RIGHT", colorButton, "LEFT", -CONTROL_GAP, 0)
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
	-- Removed by user request to prevent color distortion
	-- colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	-- Tooltip
	colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_FONT_COLOR or "Font Color", 1, 0.82, 0)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 1, 1, 1, true)
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
				local na = 1
				if ColorPickerFrame.GetColorAlpha then
					na = ColorPickerFrame:GetColorAlpha()
				elseif ColorPickerFrame.GetOpacity then
					na = ColorPickerFrame:GetOpacity()
				end
				holder:SetColor(nr, ng, nb, na)
				if callback then callback(nr, ng, nb, na) end
			end,
			opacityFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = 1
				if ColorPickerFrame.GetColorAlpha then
					na = ColorPickerFrame:GetColorAlpha()
				elseif ColorPickerFrame.GetOpacity then
					na = ColorPickerFrame:GetOpacity()
				end
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
	-- Removed by user request to prevent color distortion
	-- colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	-- Tooltip
	colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_FONT_COLOR or "Font Color", 1, 0.82, 0)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 1, 1, 1, true)
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
	holder.Slider:SetHeight(16)
	
	-- Value Label (Centered in gap)
	holder.ValueLabel = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	holder.ValueLabel:SetJustifyH("CENTER")
	
	-- Layout Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		-- Color Button hard anchored Right
		colorButton:ClearAllPoints()
		colorButton:SetPoint("RIGHT", 0, 0)
		
		-- Value Label Left of ColorButton
		holder.ValueLabel:SetWidth(30)
		holder.ValueLabel:ClearAllPoints()
		holder.ValueLabel:SetPoint("RIGHT", colorButton, "LEFT", -5, 0)
		
		-- Slider Left of ValueLabel
		-- Width: Dynamic (50% max 200 min 150)
		local maxWidth = 200
		local minWidth = 150
		local sliderWidth = math.max(minWidth, math.min(maxWidth, width * 0.4))
		
		holder.Slider:ClearAllPoints()
		holder.Slider:SetPoint("RIGHT", holder.ValueLabel, "LEFT", -5, 0)
		holder.Slider:SetWidth(sliderWidth)
		
		-- Label fills remaining space
		holder.Label:ClearAllPoints()
		holder.Label:SetPoint("LEFT", 0, 0)
		-- Anchor Label Right to Slider Left
		holder.Label:SetPoint("RIGHT", holder.Slider, "LEFT", -CONTROL_GAP, 0)
	end)

	-- Trigger Layout
	-- Force initial width on slider in case layout trigger fails (default to minWidth)
	holder.Slider:SetWidth(150)
	
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	-- Init slider without built-in label (we use our own)
	holder.Slider:Init(initialValue, min, max, max - min, {})
	
	-- Set initial text
	holder.ValueLabel:SetText(formatter(initialValue))
	
	holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not holder.isUpdatingStep then
			sliderCallback(value)
			holder.ValueLabel:SetText(formatter(value))
		end
	end)
	
	function holder:SetValue(value)
		holder.Slider:SetValue(value)
		holder.ValueLabel:SetText(formatter(value))
	end
	
	function holder:GetValue()
		return holder.Slider:GetValue()
	end
	
	function holder:SetStep(step)
		-- Block callback to prevent unwanted updates during re-init
		holder.isUpdatingStep = true
		
		-- Use current value or initial value if current is unavailable/zero/bad
		local currentVal = holder.Slider:GetValue()
		if not currentVal or (currentVal == 0 and min > 0) then
			currentVal = initialValue
		end
		
		-- Re-Initialize with correct step count to fix buttons and drag snapping
		local steps = (max - min) / step
		holder.Slider:Init(currentVal, min, max, steps, {})

		if holder.Slider.SetValueStep then
			holder.Slider:SetValueStep(step)
		end
		if holder.Slider.SetObeyStepOnDrag then
			holder.Slider:SetObeyStepOnDrag(true)
		end
		-- Fix for MinimalSliderWithSteppersMixin buttons and internal logic
		holder.Slider.stepSize = step
		
		-- Restore callback processing
		holder.isUpdatingStep = false
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
-- LIST ITEM (With Drag Handle for reordering)
-- ========================================
function Components:CreateListItem(parent, itemText, orderIndex, onDragStart, onDragStop, onRename, onColor, onDelete, onCountColor, onArrowColor, initialColors)
	-- Use a Button for better click/drag handling
	local holder = CreateFrame("Button", nil, parent)
	holder:SetHeight(40)
	-- Use negative padding to maximize width further
	holder:SetPoint("LEFT", -2, 0)
	holder:SetPoint("RIGHT", 5, 0)
	
	-- Enable Drag
	holder:RegisterForDrag("LeftButton")
	
	-- Drag Scripts
	if onDragStart and onDragStop then
		holder:SetScript("OnDragStart", function(self)
			-- Init Ghost
			local ghost = BFL:GetDragGhost()
			ghost.text:SetText(itemText)
			
			-- Calculate width based on text length + padding
			local width = ghost.text:GetStringWidth() + 50
			ghost:SetSize(width, self:GetHeight())
			
			-- Reset Text Color to Gold (Precludes residue from other drags like RaidFrames)
			ghost.text:SetTextColor(1, 0.82, 0)
			
			-- Apply Color to Stripe
			if initialColors and initialColors.fallback then
				ghost.stripe:SetColorTexture(initialColors.fallback.r, initialColors.fallback.g, initialColors.fallback.b)
			else
				ghost.stripe:SetColorTexture(1, 0.82, 0) -- Default Gold
			end
			
			ghost:Show()
			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
			
			-- Dim original
			self:SetAlpha(0.0)
			
			-- Start moving ghost
			ghost:SetScript("OnUpdate", function(g)
				local cX, cY = GetCursorPosition()
				local s = UIParent:GetEffectiveScale()
				
				-- Ensure ghost stays within reasonable bounds or just follows cursor
				g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cX / s, cY / s)
			end)
			
			-- Call external handler (logic)
			onDragStart(self)
		end)
		
		holder:SetScript("OnDragStop", function(self)
			-- Hide Ghost
			local ghost = BFL:GetDragGhost()
			ghost:Hide()
			ghost:SetScript("OnUpdate", nil)
			ghost:ClearAllPoints()
			
			-- Restore original
			self:SetAlpha(1.0)
			
			-- Call external handler (logic)
			onDragStop(self)
		end)
	end
	
	-- Background
	holder.bg = holder:CreateTexture(nil, "BACKGROUND")
	holder.bg:SetAllPoints()
	holder.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
	
	-- Drag Handle (:::)
	holder.dragHandle = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	holder.dragHandle:SetPoint("LEFT", 5, 0)
	holder.dragHandle:SetText(":::")
	holder.dragHandle:SetTextColor(0.5, 0.5, 0.5)
	
	-- Order number
	holder.orderText = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	holder.orderText:SetPoint("LEFT", holder.dragHandle, "RIGHT", 5, 0)
	holder.orderText:SetText(orderIndex)
	holder.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Item text
	holder.nameText = holder:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	holder.nameText:SetPoint("LEFT", holder.orderText, "RIGHT", 15, 0)
	holder.nameText:SetText(itemText)
	holder.nameText:SetTextColor(1, 0.82, 0)
	
	local rightOffset = -10
	
	-- Delete button (optional)
	if onDelete then
		holder.deleteButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
		holder.deleteButton:SetSize(28, 28)
		holder.deleteButton:SetPoint("RIGHT", rightOffset, 0)
		
		local texturePath = "Interface\\AddOns\\BetterFriendlist\\Icons\\trash-2"
		
		-- Create 8 shadows for outline effect to match Group Arrow style
		for x = -1, 1 do
			for y = -1, 1 do
				if not (x == 0 and y == 0) then
					local shadow = holder.deleteButton:CreateTexture(nil, "ARTWORK")
					shadow:SetSize(18, 18)
					shadow:SetPoint("CENTER", x, y)
					shadow:SetTexture(texturePath)
					shadow:SetDesaturated(true)
					shadow:SetVertexColor(0, 0, 0, 1)
				end
			end
		end
		
		-- Icon texture
		local deleteIcon = holder.deleteButton:CreateTexture(nil, "OVERLAY")
		deleteIcon:SetSize(18, 18)
		deleteIcon:SetPoint("CENTER")
		deleteIcon:SetTexture(texturePath)
		deleteIcon:SetVertexColor(1, 0.82, 0)
		holder.deleteButton.icon = deleteIcon
		
		holder.deleteButton:SetScript("OnClick", function()
			if onDelete then onDelete() end
		end)
		holder.deleteButton:SetScript("OnEnter", function(self)
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_DELETE_GROUP or "Delete Group", 1, 0.1, 0.1)
			GameTooltip:AddLine(L.SETTINGS_DELETE_GROUP_DESC or "Delete this custom group", 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		holder.deleteButton:SetScript("OnLeave", function(self)
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		end)
	end
	
	-- Reserve space to keep alignment with rows that have a delete button
	rightOffset = rightOffset - 30
	
	-- Rename button (optional)
	if onRename then
		holder.renameButton = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
		holder.renameButton:SetSize(28, 28)
		holder.renameButton:SetPoint("RIGHT", rightOffset, 0)
		rightOffset = rightOffset - 35 -- Extra gap
		
		local texturePath = "Interface\\AddOns\\BetterFriendlist\\Icons\\edit"
		
		-- Create 8 shadows for outline effect to match Group Arrow style
		for x = -1, 1 do
			for y = -1, 1 do
				if not (x == 0 and y == 0) then
					local shadow = holder.renameButton:CreateTexture(nil, "ARTWORK")
					shadow:SetSize(18, 18)
					shadow:SetPoint("CENTER", x, y)
					shadow:SetTexture(texturePath)
					shadow:SetDesaturated(true)
					shadow:SetVertexColor(0, 0, 0, 1)
				end
			end
		end
		
		-- Icon texture
		local renameIcon = holder.renameButton:CreateTexture(nil, "OVERLAY")
		renameIcon:SetSize(18, 18)
		renameIcon:SetPoint("CENTER")
		renameIcon:SetTexture(texturePath)
		renameIcon:SetVertexColor(1, 0.82, 0)
		holder.renameButton.icon = renameIcon
		
		holder.renameButton:SetScript("OnClick", function()
			if onRename then onRename() end
		end)
		holder.renameButton:SetScript("OnEnter", function(self)
			self.icon:SetVertexColor(1, 1, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_RENAME_GROUP or "Rename", 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC or "Rename this group", 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		holder.renameButton:SetScript("OnLeave", function(self)
			self.icon:SetVertexColor(1, 0.82, 0)
			GameTooltip:Hide()
		end)
	end

	-- Arrow Color Button (New)
	if onArrowColor then
		holder.arrowColorButton = CreateFrame("Button", nil, holder)
		holder.arrowColorButton:SetSize(28, 28)
		holder.arrowColorButton:SetPoint("RIGHT", rightOffset, 0)
		rightOffset = rightOffset - 35
		
		holder.arrowColorBorder = holder.arrowColorButton:CreateTexture(nil, "BACKGROUND")
		holder.arrowColorBorder:SetAllPoints(holder.arrowColorButton)
		holder.arrowColorBorder:SetColorTexture(0, 0, 0, 1)
		
		holder.arrowColorSwatch = holder.arrowColorButton:CreateTexture(nil, "ARTWORK")
		holder.arrowColorSwatch:SetPoint("TOPLEFT", holder.arrowColorButton, "TOPLEFT", 3, -3)
		holder.arrowColorSwatch:SetPoint("BOTTOMRIGHT", holder.arrowColorButton, "BOTTOMRIGHT", -3, 3)
		if initialColors and initialColors.arrow then
			holder.arrowColorSwatch:SetColorTexture(initialColors.arrow.r, initialColors.arrow.g, initialColors.arrow.b)
		elseif initialColors and initialColors.fallback then
			holder.arrowColorSwatch:SetColorTexture(initialColors.fallback.r, initialColors.fallback.g, initialColors.fallback.b)
		else
			holder.arrowColorSwatch:SetColorTexture(0.5, 0.5, 0.5, 0.5) -- Grey for "Inherited/None"
		end
		
		-- Removed highlight to prevent color distortion
		-- holder.arrowColorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		holder.arrowColorButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		holder.arrowColorButton:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				-- Reset to nil (Inherit)
				if onArrowColor then onArrowColor(nil, true) end
			else
				if onArrowColor then onArrowColor(holder.arrowColorSwatch) end
			end
		end)
		holder.arrowColorButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_GROUP_ARROW_COLOR or "Arrow Color", 1, 0.82, 0)
			GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 1, 1, 1, true)
			GameTooltip:AddLine(L.TOOLTIP_RIGHT_CLICK_INHERIT or "Right-click to inherit from Group", 0.6, 0.6, 0.6)
			GameTooltip:Show()
		end)
		holder.arrowColorButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
		
		-- Small Icon overlay to indicate function
		-- Multiple shadows in 8 directions to simulate a full OUTLINE effect
		
		-- Helper to create a shadow texture
		local function CreateShadow(x, y)
			local shadow = holder.arrowColorButton:CreateTexture(nil, "OVERLAY")
			shadow:SetSize(12, 12)
			shadow:SetPoint("CENTER", x, y)
			shadow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-down")
			shadow:SetDesaturated(true) -- Ensure no color bleed from original texture
			shadow:SetVertexColor(0, 0, 0, 1)
			return shadow
		end

		-- Create shadows in all 8 directions + directly behind for thickness
		CreateShadow(1, 0)
		CreateShadow(-1, 0)
		CreateShadow(0, 1)
		CreateShadow(0, -1)
		CreateShadow(1, 1)
		CreateShadow(1, -1)
		CreateShadow(-1, 1)
		CreateShadow(-1, -1)

		local icon = holder.arrowColorButton:CreateTexture(nil, "OVERLAY", nil, 7) -- Draw on top of all shadows (subLevel > 0)
		icon:SetSize(12, 12)
		icon:SetPoint("CENTER")
		
		-- Use flat icon for clean white look
		icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-down")
		icon:SetDesaturated(true) -- Remove original color (e.g. yellow) to allow pure white
		icon:SetVertexColor(1, 1, 1)
	end
	
	-- Count Color Button (New)
	if onCountColor then
		holder.countColorButton = CreateFrame("Button", nil, holder)
		holder.countColorButton:SetSize(28, 28)
		holder.countColorButton:SetPoint("RIGHT", rightOffset, 0)
		rightOffset = rightOffset - 35 -- Gap
		
		holder.countColorBorder = holder.countColorButton:CreateTexture(nil, "BACKGROUND")
		holder.countColorBorder:SetAllPoints(holder.countColorButton)
		holder.countColorBorder:SetColorTexture(0, 0, 0, 1)
		
		holder.countColorSwatch = holder.countColorButton:CreateTexture(nil, "ARTWORK")
		holder.countColorSwatch:SetPoint("TOPLEFT", holder.countColorButton, "TOPLEFT", 3, -3)
		holder.countColorSwatch:SetPoint("BOTTOMRIGHT", holder.countColorButton, "BOTTOMRIGHT", -3, 3)
		if initialColors and initialColors.count then
			holder.countColorSwatch:SetColorTexture(initialColors.count.r, initialColors.count.g, initialColors.count.b)
		elseif initialColors and initialColors.fallback then
			holder.countColorSwatch:SetColorTexture(initialColors.fallback.r, initialColors.fallback.g, initialColors.fallback.b)
		else
			holder.countColorSwatch:SetColorTexture(0.5, 0.5, 0.5, 0.5)
		end
		
		-- Removed highlight to prevent color distortion
		-- holder.countColorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		holder.countColorButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		holder.countColorButton:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				-- Reset to nil (Inherit)
				if onCountColor then onCountColor(nil, true) end
			else
				if onCountColor then onCountColor(holder.countColorSwatch) end
			end
		end)
		holder.countColorButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SETTINGS_GROUP_COUNT_COLOR or "Count Color", 1, 0.82, 0)
			GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 1, 1, 1, true)
			GameTooltip:AddLine(L.TOOLTIP_RIGHT_CLICK_INHERIT or "Right-click to inherit from Group", 0.6, 0.6, 0.6)
			GameTooltip:Show()
		end)
		holder.countColorButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
		
		-- Text overlay "123"
		local text = holder.countColorButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("CENTER")
		text:SetText("123")
		
		-- Use White text with Outline for universal readability on any color background
		local font, size, flags = text:GetFont()
		text:SetFont(font, size, "OUTLINE")
		text:SetTextColor(1, 1, 1)
	end
	
	-- Color button (Main Group Color)
	holder.colorButton = CreateFrame("Button", nil, holder)
	holder.colorButton:SetSize(28, 28)
	holder.colorButton:SetPoint("RIGHT", rightOffset, 0)
	rightOffset = rightOffset - 35
	
	holder.colorBorder = holder.colorButton:CreateTexture(nil, "BACKGROUND")
	holder.colorBorder:SetAllPoints(holder.colorButton)
	holder.colorBorder:SetColorTexture(0, 0, 0, 1)
	
	holder.colorSwatch = holder.colorButton:CreateTexture(nil, "ARTWORK")
	holder.colorSwatch:SetPoint("TOPLEFT", holder.colorButton, "TOPLEFT", 3, -3)
	holder.colorSwatch:SetPoint("BOTTOMRIGHT", holder.colorButton, "BOTTOMRIGHT", -3, 3)
	holder.colorSwatch:SetColorTexture(1, 0.82, 0)
	
	-- Removed highlight to prevent color distortion
	-- holder.colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	holder.colorButton:SetScript("OnClick", function()
		if onColor then onColor(holder.colorSwatch) end
	end)
	holder.colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_GROUP_COLOR or "Group Color", 1, 0.82, 0)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC or "Click to change color", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	holder.colorButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Text overlay "Abc" (Group Name)
	local nameIcon = holder.colorButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameIcon:SetPoint("CENTER")
	nameIcon:SetText("Abc")
	
	-- Use White text with Outline for universal readability on any color background
	local font, size, flags = nameIcon:GetFont()
	nameIcon:SetFont(font, size, "OUTLINE")
	nameIcon:SetTextColor(1, 1, 1)
	
	-- Store order index
	holder.orderIndex = orderIndex
	
	-- Function to update order display
	function holder:SetOrderIndex(newIndex)
		holder.orderIndex = newIndex
		holder.orderText:SetText(newIndex)
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
	
	-- Expose Checkboxes for Skinning
	holder.LeftCheckbox = leftCheck
	holder.RightCheckbox = rightCheck
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		-- Divide into two columns
		-- Left Checkbox at 50% width
		-- Right Checkbox at 100% width
		
		-- Position Left Pair
		if leftLabel and leftCheck then
			leftCheck:ClearAllPoints()
			-- Center of Left Column (width/2) -> Right Align relative to that center point?
			-- User wants alignment. 
			-- If "Right" Checkbox is at Right Edge + Offset, Left Checkbox should be at Center + Offset?
			leftCheck:SetPoint("RIGHT", self, "LEFT", (width/2) + CHECKBOX_X_OFFSET, 0)
			
			leftLabel:ClearAllPoints()
			leftLabel:SetPoint("LEFT", self, "LEFT", 0, 0)
			leftLabel:SetPoint("RIGHT", leftCheck, "LEFT", -CONTROL_GAP - CHECKBOX_X_OFFSET, 0)
		end
		
		-- Position Right Pair
		if rightLabel and rightCheck then
			rightCheck:ClearAllPoints()
			rightCheck:SetPoint("RIGHT", self, "RIGHT", CHECKBOX_X_OFFSET, 0)
			
			rightLabel:ClearAllPoints()
			rightLabel:SetPoint("LEFT", self, "LEFT", (width/2) + (CONTROL_GAP*2), 0)
			rightLabel:SetPoint("RIGHT", rightCheck, "LEFT", -CONTROL_GAP - CHECKBOX_X_OFFSET, 0)
		end
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	return holder
end

-- ========================================
-- INPUT BOX (Label Left, EditBox Right - Grid Aligned)
-- ========================================
function Components:CreateInput(parent, labelText, initialValue, callback)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(COMPONENT_HEIGHT + 6) -- Input boxes need a bit more height
	holder:SetPoint("LEFT", PADDING_LEFT, 0)
	holder:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	
	-- Label
	local label = holder:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(labelText)
	
	-- Input Box
	local inputBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
	inputBox:SetHeight(20)
	inputBox:SetAutoFocus(false)
	inputBox:SetFontObject("BetterFriendlistFontHighlight")
	
	-- Dynamic Resizing Handler
	holder:SetScript("OnSizeChanged", function(self, width, height)
		-- Use fixed width for alignment consistency
		local inputWidth = FIXED_CONTROL_WIDTH
		
		inputBox:ClearAllPoints()
		inputBox:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		inputBox:SetWidth(inputWidth)
		
		label:ClearAllPoints()
		label:SetPoint("LEFT", self, "LEFT", 0, 0)
		label:SetPoint("RIGHT", inputBox, "LEFT", -CONTROL_GAP, 0)
	end)

	-- Trigger initial layout
	if holder:GetWidth() > 0 then
		holder:GetScript("OnSizeChanged")(holder, holder:GetWidth(), holder:GetHeight())
	end
	
	inputBox:SetText(initialValue or "")
	
	inputBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if callback then callback(self:GetText(), self) end
	end)
	
	inputBox:SetScript("OnEscapePressed", function(self)
		self:SetText(initialValue or "") -- Reset on escape? Or just clear focus?
		self:ClearFocus()
	end)
	
	inputBox:SetScript("OnEditFocusLost", function(self)
		if callback then callback(self:GetText(), self) end
	end)
	
	holder.Label = label
	holder.Input = inputBox
	
	holder.SetTooltip = function(_, title, desc)
		inputBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc then
				GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true)
			end
			GameTooltip:Show()
		end)
		inputBox:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	return holder
end

-- ========================================
-- LABEL / DESCRIPTION (Full Width or Grid Aligned)
-- ========================================
function Components:CreateLabel(parent, text, isSmall, color)
	local label = parent:CreateFontString(nil, "ARTWORK", isSmall and "BetterFriendlistFontHighlightSmall" or "BetterFriendlistFontHighlight")
	label:SetPoint("LEFT", PADDING_LEFT, 0)
	label:SetPoint("RIGHT", -PADDING_RIGHT, 0)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(true)
	label:SetText(text)
	
	if color then
		label:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
	end
	
	return label
end

-- ========================================
-- Export
-- ========================================
return Components

