--------------------------------------------------------------------------------
---- BFL_QTip Row (forked from LibQTip-2.0)
---- Original: Copyright (c) 2023, James D. Callahan III - BSD 3-Clause License
---- See QTip.lua for full license text.
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local ScriptManager = QTip.ScriptManager
local TooltipManager = QTip.TooltipManager

local Row = TooltipManager.RowPrototype

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function Row:GetCell(columnIndex, cellProvider)
	if self.ColSpanCells[columnIndex] then
		error(("Overlapping Cells at column %d"):format(columnIndex), 3)
	end

	local existingCell = self.Cells[columnIndex]

	if existingCell then
		if cellProvider == nil or existingCell.CellProvider == cellProvider then
			return existingCell
		end

		TooltipManager:ReleaseCell(existingCell)
		self.Cells[columnIndex] = nil
	end

	return TooltipManager:AcquireCell(
		self.Tooltip,
		self,
		self.Tooltip:GetColumn(columnIndex),
		cellProvider or self.Tooltip:GetDefaultCellProvider()
	)
end

function Row:GetColor()
	return self:GetBackdropColor()
end

function Row:SetColor(r, g, b, a)
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

function Row:SetScript(scriptType, handler, arg)
	ScriptManager:SetScript(self, scriptType, handler, arg)

	return self
end

function Row:SetTextColor(r, g, b, a)
	if not r then
		r, g, b, a = self.Tooltip:GetDefaultFont():GetTextColor()
	end

	for cellIndex = 1, #self.Cells do
		self.Cells[cellIndex]:SetTextColor(r, g, b, a)
	end

	return self
end
