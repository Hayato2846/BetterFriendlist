--------------------------------------------------------------------------------
---- BFL_QTip Tooltip (forked from LibQTip-2.0)
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local ScriptManager = QTip.ScriptManager
local TooltipManager = QTip.TooltipManager

local Tooltip = TooltipManager.TooltipPrototype

--------------------------------------------------------------------------------
---- Constants
--------------------------------------------------------------------------------

local SliderBackdrop = BACKDROP_SLIDER_8_8
	or {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 },
		tile = true,
		tileEdge = true,
		tileSize = 8,
	}

--------------------------------------------------------------------------------
---- Validators
--------------------------------------------------------------------------------

local function ValidateFont(font, level, silent)
	local bad = false

	if not font then
		bad = true
	elseif type(font) == "string" then
		local ref = _G[font]

		if not ref or type(ref) ~= "table" or type(ref.IsObjectType) ~= "function" or not ref:IsObjectType("Font") then
			bad = true
		end
	elseif type(font) ~= "table" or type(font.IsObjectType) ~= "function" or not font:IsObjectType("Font") then
		bad = true
	end

	if bad then
		if silent then
			return false
		end

		error(
			("Font must be a FontInstance or a string matching the name of a global FontInstance, not: %s"):format(
				tostring(font)
			),
			level + 1
		)
	end

	return true
end

local function ValidateJustification(justification, level, silent)
	if justification ~= "LEFT" and justification ~= "CENTER" and justification ~= "RIGHT" then
		if silent then
			return false
		end

		error("invalid justification, must one of LEFT, CENTER or RIGHT, not: " .. tostring(justification), level + 1)
	end

	return true
end

local function ValidateRowIndex(tooltip, rowIndex, level)
	local callerLevel = level + 1
	local rowIndexType = type(rowIndex)

	if rowIndexType ~= "number" then
		error(("The rowIndex must be a number, not '%s'"):format(rowIndexType), callerLevel)
	end

	return true
end

--------------------------------------------------------------------------------
---- Internal Functions
--------------------------------------------------------------------------------

local function BaseAddRow(tooltip, isHeading, ...)
	if #tooltip.Columns == 0 then
		error("Column layout should be defined before adding a Row", 3)
	end

	local rowIndex = #tooltip.Rows + 1
	local row = tooltip.Rows[rowIndex] or TooltipManager:AcquireRow(tooltip, rowIndex)

	tooltip.Rows[rowIndex] = row

	row.IsHeading = isHeading

	for columnIndex = 1, #tooltip.Columns do
		local value = select(columnIndex, ...)

		if value ~= nil then
			row:GetCell(columnIndex):SetText(value)
		end
	end

	return row
end

local function GetTooltipAnchor(frame)
	local x, y = frame:GetCenter()

	if not x or not y then
		return "TOPLEFT", "BOTTOMLEFT"
	end

	local horizontalHalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT"
		or (x < UIParent:GetWidth() / 3) and "LEFT"
		or ""

	local verticalHalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"

	return verticalHalf .. horizontalHalf, frame, (verticalHalf == "TOP" and "BOTTOM" or "TOP") .. horizontalHalf
end

--------------------------------------------------------------------------------
---- Scripts
--------------------------------------------------------------------------------

local function AutoHideTimerFrame_OnUpdate(timer, elapsed)
	timer.CheckElapsed = timer.CheckElapsed + elapsed

	if timer.CheckElapsed > 0.1 then
		if timer.Tooltip:IsMouseOver() or (timer.AlternateFrame and timer.AlternateFrame:IsMouseOver()) then
			timer.Elapsed = 0
		else
			timer.Elapsed = timer.Elapsed + timer.CheckElapsed

			if timer.Elapsed >= timer.Delay then
				QTip:ReleaseTooltip(timer.Tooltip)
			end
		end

		timer.CheckElapsed = 0
	end
end

local function Slider_OnValueChanged(slider)
	slider.ScrollFrame:SetVerticalScroll(slider:GetValue())
end

local function Tooltip_OnMouseWheel(self, delta)
	local slider = self.Slider
	local currentValue = slider:GetValue()
	local minValue, maxValue = slider:GetMinMaxValues()
	local stepValue = self.ScrollStep

	if delta < 0 and currentValue < maxValue then
		slider:SetValue(min(maxValue, currentValue + stepValue))
	elseif delta > 0 and currentValue > minValue then
		slider:SetValue(max(minValue, currentValue - stepValue))
	end
end

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function Tooltip:AddColumn(horizontalJustification)
	horizontalJustification = horizontalJustification or "LEFT"
	ValidateJustification(horizontalJustification, 2)

	local columnIndex = #self.Columns + 1
	local column = self.Columns[columnIndex] or TooltipManager:AcquireColumn(self, columnIndex, horizontalJustification)

	self.Columns[columnIndex] = column

	return column
end

function Tooltip:AddHeadingRow(...)
	local row = BaseAddRow(self, true, ...)

	return row
end

function Tooltip:AddRow(...)
	return BaseAddRow(self, false, ...)
end

function Tooltip:AddSeparator(height, r, g, b, a)
	local row = self:AddRow()
	local color = NORMAL_FONT_COLOR

	height = height or 1

	TooltipManager:SetTooltipSize(self, self.Width, self.Height + height)

	row.Height = height
	row:SetHeight(height)
	row:SetBackdrop(TooltipManager.DefaultBackdrop)
	row:SetBackdropColor(r or color.r, g or color.g, b or color.b, a or 1)

	return row
end

function Tooltip:Clear()
	for _, row in pairs(self.Rows) do
		TooltipManager:ReleaseRow(row)
	end

	wipe(self.Rows)

	for _, column in ipairs(self.Columns) do
		column.Width = 0
		column:SetWidth(1)

		wipe(column.Cells)
	end

	wipe(self.ColSpanWidths)

	self.HorizontalCellMargin = nil
	self.VerticalCellMargin = nil

	TooltipManager:AdjustTooltipSize(self)

	return self
end

function Tooltip:GetColumn(columnIndex)
	ValidateRowIndex(self, columnIndex, 2)

	local column = self.Columns[columnIndex]

	if not column then
		error(("There is no column at index %d"):format(columnIndex), 2)
	end

	return column
end

function Tooltip:GetColumnCount()
	return #self.Columns
end

function Tooltip:GetDefaultCellProvider()
	return self.DefaultCellProvider
end

function Tooltip:GetDefaultFont()
	return self.DefaultFont
end

function Tooltip:GetDefaultHeadingFont()
	return self.DefaultHeadingFont
end

function Tooltip:GetHighlightTexCoord()
	return self.HighlightTexture:GetTexCoord()
end

function Tooltip:GetHighlightTexture()
	return self.HighlightTexture:GetTexture()
end

function Tooltip:GetRow(rowIndex)
	ValidateRowIndex(self, rowIndex, 2)

	local row = self.Rows[rowIndex]

	if not row then
		error(("There is no Row at index %d"):format(rowIndex), 2)
	end

	return row
end

function Tooltip:GetRowCount()
	return #self.Rows
end

function Tooltip:GetScrollStep()
	return self.ScrollStep
end

function Tooltip:HookScript()
	geterrorhandler()(":HookScript is not allowed on LibQTip tooltips")
end

function Tooltip:IsAcquiredBy(key)
	return key ~= nil and self.Key == key
end

function Tooltip:Release()
	QTip:ReleaseTooltip(self)
end

function Tooltip:SetAutoHideDelay(delay, alternateFrame)
	local timerFrame = self.AutoHideTimerFrame
	delay = tonumber(delay) or 0

	if delay > 0 then
		if not timerFrame then
			timerFrame = TooltipManager:AcquireTimer(self)
			timerFrame:SetScript("OnUpdate", AutoHideTimerFrame_OnUpdate)

			self.AutoHideTimerFrame = timerFrame
		end

		timerFrame.AlternateFrame = alternateFrame
		timerFrame.CheckElapsed = 0
		timerFrame.Delay = delay
		timerFrame.Elapsed = 0
		timerFrame.Tooltip = self

		timerFrame:Show()
	elseif timerFrame then
		self.AutoHideTimerFrame = nil

		TooltipManager:ReleaseTimer(timerFrame)
	end

	return self
end

function Tooltip:SetCellMarginH(size)
	if #self.Rows > 0 then
		error("Unable to set horizontal margin while the Tooltip has Rows.", 2)
	end

	if not size or type(size) ~= "number" or size < 0 then
		error("Margin size must be a positive number or zero.", 2)
	end

	self.HorizontalCellMargin = size

	return self
end

function Tooltip:SetCellMarginV(size)
	if #self.Rows > 0 then
		error("Unable to set vertical margin while the Tooltip has Rows.", 2)
	end

	if not size or type(size) ~= "number" or size < 0 then
		error("Margin size must be a positive number or zero.", 2)
	end

	self.VerticalCellMargin = size

	return self
end

function Tooltip:SetColumnLayout(columnCount, ...)
	if type(columnCount) ~= "number" or columnCount < 1 then
		error(("columnCount must be a positive number, not '%s'"):format(tostring(columnCount)), 2)
	end

	for columnIndex = 1, columnCount do
		local horizontalJustification = select(columnIndex, ...) or "LEFT"

		ValidateJustification(horizontalJustification, 2)

		if self.Columns[columnIndex] then
			self.Columns[columnIndex].HorizontalJustification = horizontalJustification
		else
			self:AddColumn(horizontalJustification)
		end
	end

	return self
end

function Tooltip:SetDefaultCellProvider(cellProvider)
	if cellProvider then
		self.DefaultCellProvider = cellProvider
	end

	return self
end

function Tooltip:SetDefaultFont(font)
	ValidateFont(font, 2)

	self.DefaultFont = type(font) == "string" and _G[font] or font

	return self
end

function Tooltip:SetDefaultHeadingFont(font)
	ValidateFont(font, 2)

	self.DefaultHeadingFont = type(font) == "string" and _G[font] or font

	return self
end

function Tooltip:SetHighlightTexCoord(...)
	self.HighlightTexture:SetTexCoord(...)

	return self
end

function Tooltip:SetHighlightTexture(filePath, horizontalWrap, verticalWrap, filterMode)
	self.HighlightTexture:SetTexture(filePath, horizontalWrap, verticalWrap, filterMode)

	return self
end

function Tooltip:SetMaxHeight(height)
	self.MaxHeight = height

	return self
end

function Tooltip:SetScript(scriptType, handler)
	ScriptManager:RawSetScript(self, scriptType, handler)

	self.Scripts[scriptType] = handler and true or nil

	return self
end

function Tooltip:SetScrollStep(step)
	self.ScrollStep = step

	return self
end

function Tooltip:SmartAnchorTo(frame)
	if not frame then
		error("Invalid frame provided.", 2)
	end

	self:ClearAllPoints()
	self:SetClampedToScreen(true)
	self:SetPoint(GetTooltipAnchor(frame))

	return self
end

function Tooltip:UpdateLayout()
	self:SetClampedToScreen(false)

	TooltipManager:AdjustCellSizes(self)
	TooltipManager.LayoutRegistry[self] = nil

	local scale = self:GetScale()
	local topOffset = self:GetTop()
	local bottomOffset = self:GetBottom()
	local screenSize = UIParent:GetHeight() / scale
	local tooltipSize = (topOffset - bottomOffset)
	local maxHeight = self.MaxHeight

	if bottomOffset < 0 or topOffset > screenSize or (maxHeight and tooltipSize > maxHeight) then
		local shrink = (bottomOffset < 0 and (5 - bottomOffset) or 0)
			+ (topOffset > screenSize and (topOffset - screenSize + 5) or 0)

		if maxHeight and tooltipSize - shrink > maxHeight then
			shrink = tooltipSize - maxHeight
		end

		self:SetHeight(2 * TooltipManager.PixelSize.CellPadding + self.Height - shrink)
		self:SetWidth(2 * TooltipManager.PixelSize.CellPadding + self.Width + 20)

		self.ScrollFrame:SetPoint("RIGHT", self, "RIGHT", -(TooltipManager.PixelSize.CellPadding + 20), 0)

		if not self.Slider then
			local slider = CreateFrame("Slider", nil, self, "BackdropTemplate")
			slider.ScrollFrame = self.ScrollFrame

			slider:SetOrientation("VERTICAL")
			slider:SetPoint(
				"TOPRIGHT",
				self,
				"TOPRIGHT",
				-TooltipManager.PixelSize.CellPadding,
				-TooltipManager.PixelSize.CellPadding
			)
			slider:SetPoint(
				"BOTTOMRIGHT",
				self,
				"BOTTOMRIGHT",
				-TooltipManager.PixelSize.CellPadding,
				TooltipManager.PixelSize.CellPadding
			)
			slider:SetBackdrop(SliderBackdrop)
			slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
			slider:SetMinMaxValues(0, 1)
			slider:SetValueStep(1)
			slider:SetWidth(12)
			slider:SetScript("OnValueChanged", Slider_OnValueChanged)
			slider:SetValue(0)

			self.Slider = slider
		end

		self.Slider:SetMinMaxValues(0, shrink)
		self.Slider:Show()

		self:EnableMouseWheel(true)
		self:SetScript("OnMouseWheel", Tooltip_OnMouseWheel)
	else
		self:SetHeight(2 * TooltipManager.PixelSize.CellPadding + self.Height)
		self:SetWidth(2 * TooltipManager.PixelSize.CellPadding + self.Width)

		self.ScrollFrame:SetPoint("RIGHT", self, "RIGHT", -TooltipManager.PixelSize.CellPadding, 0)

		if self.Slider then
			self.Slider:SetValue(0)
			self.Slider:Hide()

			self:EnableMouseWheel(false)
			self:SetScript("OnMouseWheel", nil)
		end
	end

	return self
end
