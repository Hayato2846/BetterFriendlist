--------------------------------------------------------------------------------
---- BFL_QTip Cell (forked from LibQTip-2.0)
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local ScriptManager = QTip.ScriptManager
local TooltipManager = QTip.TooltipManager

local Cell = QTip.DefaultCellPrototype

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function Cell:GetColor()
	return self:GetBackdropColor()
end

function Cell:GetColSpan()
	return self.ColSpan
end

function Cell:GetContentHeight()
	local fontString = self.FontString
	fontString:SetWidth(self:GetWidth() - (self.LeftPadding + self.RightPadding))

	local height = self.FontString:GetHeight()
	fontString:SetWidth(0)

	return height
end

function Cell:GetFont()
	return self.FontString:GetFont()
end

function Cell:GetFontObject()
	return self.FontString:GetFontObject()
end

function Cell:GetJustifyH()
	return self.HorizontalJustification
end

function Cell:GetLeftPadding()
	return self.LeftPadding
end

function Cell:GetMaxWidth()
	return self.MaxWidth
end

function Cell:GetMinWidth()
	return self.MinWidth
end

function Cell:GetPosition()
	return self.RowIndex, self.ColumnIndex
end

function Cell:GetRightPadding()
	return self.RightPadding
end

function Cell:GetSize()
	local fontString = self.FontString

	fontString:ClearAllPoints()

	local leftPadding = self.LeftPadding
	local rightPadding = self.RightPadding

	local width = fontString:GetStringWidth() + leftPadding + rightPadding
	local minWidth = self.MinWidth
	local maxWidth = self.MaxWidth

	if minWidth and width < minWidth then
		width = minWidth
	end

	if maxWidth and maxWidth < width then
		width = maxWidth
	end

	fontString:SetWidth(width - (leftPadding + rightPadding))

	local height = fontString:GetHeight()

	fontString:SetWidth(0)
	fontString:SetPoint("TOPLEFT", self, "TOPLEFT", leftPadding, 0)
	fontString:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -rightPadding, 0)

	return width, height
end

function Cell:GetText()
	return self.FontString:GetText()
end

function Cell:GetTextColor()
	return self.FontString:GetTextColor()
end

function Cell:OnCreation()
	self.ColSpan = 1
	self.LeftPadding = 0
	self.RightPadding = 0
	self.FontString = self:CreateFontString()
	self.FontString:SetFontObject(GameTooltipText)
	self:SetJustifyH("LEFT")
end

function Cell:OnContentChanged()
	local tooltip = self.Tooltip
	local row = tooltip:GetRow(self.RowIndex)
	local columnIndex = self.ColumnIndex
	local column = tooltip:GetColumn(columnIndex)
	local width, height = self:GetSize()
	local colSpan = self.ColSpan

	if colSpan > 1 then
		local columnRange = ("%d-%d"):format(columnIndex, columnIndex + colSpan - 1)

		tooltip.ColSpanWidths[columnRange] = max(tooltip.ColSpanWidths[columnRange] or 0, width)
		TooltipManager:RegisterForCleanup(tooltip)
	else
		TooltipManager:AdjustColumnWidth(column, width)
	end

	if height > row.Height then
		TooltipManager:SetTooltipSize(tooltip, tooltip.Width, tooltip.Height + height - row.Height)

		row.Height = height
		row:SetHeight(height)
	end
end

function Cell:OnRelease()
	self:SetJustifyH("LEFT")
	self:ClearAllPoints()
	self:SetParent(nil)

	self.FontString:SetFontObject(GameTooltipText)
	self:SetText("")

	if self.r then
		self.FontString:SetTextColor(self.r, self.g, self.b, self.a)
	end

	self.ColSpan = 1
	self.ColumnIndex = 0
	self.HorizontalJustification = "LEFT"
	self.RowIndex = 0
	self.LeftPadding = 0
	self.MaxWidth = nil
	self.MinWidth = nil
	self.RightPadding = 0
	self.Tooltip = nil
end

function Cell:SetColor(r, g, b, a)
	local red, green, blue, alpha

	if r and g and b and a then
		red, green, blue, alpha = r, g, b, a
	else
		red, green, blue, alpha = self.Tooltip:GetBackdropColor()
	end

	self:SetBackdrop(TooltipManager.DefaultBackdrop)
	self:SetBackdropColor(red, green, blue, alpha)

	return self
end

function Cell:SetColSpan(size)
	local row = self.Tooltip:GetRow(self.RowIndex)
	local colSpanCells = row.ColSpanCells
	local rowCells = row.Cells

	local columnIndex = self.ColumnIndex

	size = size or 1

	for cellIndex = columnIndex + 1, columnIndex + self.ColSpan - 1 do
		rowCells[cellIndex] = nil
		colSpanCells[cellIndex] = nil
	end

	local columnCount = #self.Tooltip.Columns
	local rightColumnIndex

	if size > 0 then
		rightColumnIndex = columnIndex + size - 1

		if rightColumnIndex > columnCount then
			error("ColSpan too big: Cell extends beyond right-most Column", 3)
		end
	else
		rightColumnIndex = max(columnIndex, columnCount + size)
		size = 1 + rightColumnIndex - columnIndex
	end

	for cellIndex = columnIndex + 1, rightColumnIndex do
		if colSpanCells[cellIndex] then
			error(("Overlapping Cells at column %d"):format({ cellIndex }), 3)
		end

		local columnCell = rowCells[cellIndex]

		if columnCell then
			TooltipManager:ReleaseCell(columnCell)
		end

		colSpanCells[cellIndex] = true
	end

	self.ColSpan = size

	self:SetPoint("RIGHT", self.Tooltip.Columns[rightColumnIndex])

	return self
end

function Cell:SetFont(path, height, flags)
	self.FontString:SetFont(path, height, flags)

	return self
end

function Cell:SetFontObject(font)
	self.FontString:SetFontObject(
		type(font) == "string" and _G[font]
			or font
			or (
				self.Tooltip:GetRow(self.RowIndex).IsHeading and self.Tooltip:GetDefaultHeadingFont()
				or self.Tooltip:GetDefaultFont()
			)
	)

	return self
end

function Cell:SetFormattedText(format, ...)
	self.FontString:SetFormattedText(tostring(format), ...)
	self:OnContentChanged()

	return self
end

function Cell:SetJustifyH(horizontalJustification)
	self.HorizontalJustification = horizontalJustification
	self.FontString:SetJustifyH(horizontalJustification)

	return self
end

function Cell:SetLeftPadding(pixels)
	self.LeftPadding = pixels

	return self
end

function Cell:SetMaxWidth(maxWidth)
	local minWidth = self.MinWidth

	if maxWidth and minWidth and (maxWidth < minWidth) then
		error(("maxWidth (%d) cannot be less than the Cell's MinWidth (%d)"):format(maxWidth, minWidth), 2)
	end

	if maxWidth and (maxWidth < (self.LeftPadding + self.RightPadding)) then
		error(
			("maxWidth (%d) cannot be less than the sum of the Cell's LeftPadding (%d) and RightPadding (%d)"):format(
				maxWidth,
				self.LeftPadding,
				self.RightPadding
			),
			2
		)
	end

	self.MaxWidth = maxWidth

	return self
end

function Cell:SetMinWidth(minWidth)
	local maxWidth = self.MaxWidth

	if maxWidth and minWidth and (minWidth > maxWidth) then
		error(("minWidth (%d) cannot be greater than the Cell's MaxWidth (%d)"):format(minWidth, maxWidth), 2)
	end

	self.MinWidth = minWidth

	return self
end

function Cell:SetRightPadding(pixels)
	self.RightPadding = pixels

	return self
end

function Cell:SetScript(scriptType, handler, arg)
	ScriptManager:SetScript(self, scriptType, handler, arg)

	return self
end

function Cell:SetText(text)
	self.FontString:SetText(tostring(text))
	self:OnContentChanged()

	return self
end

function Cell:SetTextColor(r, g, b, a)
	if not self.r then
		self:SetRGBA(self.FontString:GetTextColor())
	end

	if not r then
		r, g, b, a = self:GetRGBA()
	end

	self.FontString:SetTextColor(r or 0, g or 0, b or 0, a or 1)

	return self
end
