--------------------------------------------------------------------------------
---- BFL_QTip Column (forked from LibQTip-2.0)
---- Original: Copyright (c) 2023, James D. Callahan III - BSD 3-Clause License
---- See QTip.lua for full license text.
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local ScriptManager = QTip.ScriptManager
local TooltipManager = QTip.TooltipManager

local Column = TooltipManager.ColumnPrototype

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function Column:GetCell(rowIndex, cellProvider)
	return self.Tooltip:GetRow(rowIndex):GetCell(self.Index, cellProvider)
end

function Column:GetColor()
	return self:GetBackdropColor()
end

function Column:SetColor(r, g, b, a)
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

function Column:SetScript(scriptType, handler, arg)
	ScriptManager:SetScript(self, scriptType, handler, arg)

	return self
end

function Column:SetTextColor(r, g, b, a)
	for rowIndex = 1, #self.Tooltip.Rows do
		self:GetCell(rowIndex):SetTextColor(r, g, b, a)
	end

	return self
end
