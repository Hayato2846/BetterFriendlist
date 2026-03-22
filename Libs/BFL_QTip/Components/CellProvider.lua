--------------------------------------------------------------------------------
---- BFL_QTip CellProvider (forked from LibQTip-2.0)
---- Original: Copyright (c) 2023, James D. Callahan III - BSD 3-Clause License
---- See QTip.lua for full license text.
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local CellProvider = QTip.CellProviderPrototype

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function CellProvider:AcquireCell()
	local cell = tremove(self.CellHeap)

	if not cell then
		cell = setmetatable(CreateFrame("Frame", nil, UIParent, "BackdropTemplate"), self.CellMetatable)

		Mixin(cell, ColorMixin)

		if type(cell.OnCreation) == "function" then
			cell:OnCreation()
		end
	end

	cell.CellProvider = self

	self.Cells[cell] = true

	return cell
end

function CellProvider:CellPairs()
	return pairs(self.Cells)
end

function CellProvider:GetCellPrototype()
	return self.CellPrototype, self.CellMetatable
end

function CellProvider:ReleaseCell(cell)
	if not self.Cells[cell] then
		return
	end

	if type(cell.OnRelease) == "function" then
		cell:OnRelease()
	end

	self.Cells[cell] = nil
	tinsert(self.CellHeap, cell)
end
