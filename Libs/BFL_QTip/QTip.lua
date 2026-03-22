--------------------------------------------------------------------------------
---- BFL_QTip: Private fork of LibQTip-2.0 for BetterFriendlist
---- Eliminates LibStub dependency to avoid taint attribution in Midnight (12.0+)
---- Original: LibQTip-2.0 v1
----
---- Original license (BSD 3-Clause):
---- Copyright (c) 2023, James D. Callahan III
---- All rights reserved.
----
---- Redistribution and use in source and binary forms, with or without
---- modification, are permitted provided that the following conditions are met:
----
---- 1. Redistributions of source code must retain the above copyright notice,
----    this list of conditions and the following disclaimer.
---- 2. Redistributions in binary form must reproduce the above copyright
----    notice, this list of conditions and the following disclaimer in the
----    documentation and/or other materials provided with the distribution.
---- 3. Neither the name of the copyright holder nor the names of its
----    contributors may be used to endorse or promote products derived from
----    this software without specific prior written permission.
----
---- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
---- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
---- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
---- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
---- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
---- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
---- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
---- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
---- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
---- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
---- POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...

---@class BFL_QTip
local QTip = {}

QTip.FrameMetatable = { __index = CreateFrame("Frame") }

QTip.CallbackRegistry = BFL.CallbackHandler:New(QTip)

QTip.CellProviderPrototype = {}
QTip.CellProviderMetatable = { __index = QTip.CellProviderPrototype }

QTip.CellPrototype = setmetatable({}, QTip.FrameMetatable)
QTip.CellMetatable = { __index = QTip.CellPrototype }

QTip.DefaultCellPrototype = setmetatable({}, QTip.CellMetatable)
QTip.DefaultCellProvider = setmetatable({
	CellHeap = {},
	CellMetatable = { __index = QTip.DefaultCellPrototype },
	CellPrototype = QTip.DefaultCellPrototype,
	Cells = {},
}, QTip.CellProviderMetatable)

QTip.CellProviderKeys = { "LibQTip-2.0 Default" }
QTip.CellProviderRegistry = {
	["LibQTip-2.0 Default"] = QTip.DefaultCellProvider,
}

QTip.ScriptManager = {}
QTip.TooltipManager = CreateFrame("Frame")

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

local TooltipManager = QTip.TooltipManager

-- Create or retrieve the Tooltip with the given key.
---@param key string The Tooltip key. A key unique to this Tooltip should be provided to avoid conflicts.
---@param numColumns? number Minimum number of Columns
---@param ... JustifyHorizontal Column horizontal justifications ("CENTER", "LEFT" or "RIGHT"). Defaults to "LEFT".
---@return LibQTip-2.0.Tooltip
function QTip:AcquireTooltip(key, numColumns, ...)
	if type(key) ~= "string" then
		error(("Parameter 'key' must be of type 'string', not '%s'"):format(type(key)), 2)
	end

	local tooltip = TooltipManager.ActiveTooltips[key]

	if not tooltip then
		tooltip = TooltipManager:AcquireTooltip(key)
		TooltipManager.ActiveTooltips[key] = tooltip
	end

	local isOk, message = pcall(tooltip.SetColumnLayout, tooltip, numColumns, ...)

	if not isOk then
		error(message, 2)
	end

	return tooltip
end

-- Return an iterator on the registered CellProviders.
function QTip:CellProviderPairs()
	return pairs(self.CellProviderRegistry)
end

do
	local function GetCellPrototype(templateCellProvider)
		if not templateCellProvider then
			return QTip.DefaultCellProvider:GetCellPrototype()
		end

		if not templateCellProvider.GetCellPrototype then
			error("The supplied CellProvider has no 'GetCellPrototype' method.", 3)
		end

		return templateCellProvider:GetCellPrototype()
	end

	function QTip:CreateCellProvider(templateCellProvider)
		local baseCellPrototype, baseCellMetatable = GetCellPrototype(templateCellProvider)

		local newCellPrototype = setmetatable({}, baseCellMetatable)

		return {
			newCellProvider = setmetatable({
				CellHeap = {},
				Cells = {},
				CellPrototype = newCellPrototype,
				CellMetatable = { __index = newCellPrototype },
			}, self.CellProviderMetatable),
			newCellPrototype = newCellPrototype,
			baseCellPrototype = baseCellPrototype,
		}
	end
end

function QTip:GetCellProvider(key)
	if type(key) ~= "string" then
		error(("Parameter 'key' must be of type 'string', not '%s'"):format(type(key)), 2)
	end

	return self.CellProviderRegistry[key]
end

function QTip:GetCellProviderKeys()
	return self.CellProviderKeys
end

function QTip:IsAcquiredTooltip(key)
	if type(key) ~= "string" then
		error(("Parameter 'key' must be of type 'string', not '%s'"):format(type(key)), 2)
	end

	return not not TooltipManager.ActiveTooltips[key]
end

function QTip:RegisterCellProvider(key, cellProvider)
	if type(key) ~= "string" then
		error(("Parameter 'key' must be of type 'string', not '%s'"):format(type(key)), 2)
	end

	local registry = self.CellProviderRegistry

	if registry[key] then
		return false
	end

	registry[key] = cellProvider

	local list = self.CellProviderKeys

	table.wipe(list)

	for registryKey in pairs(registry) do
		table.insert(list, registryKey)
	end

	table.sort(list)

	self.CallbackRegistry:Fire("OnRegisterCellProvider", key)

	return true
end

function QTip:ReleaseTooltip(tooltip)
	local key = tooltip and tooltip.Key

	if not key or TooltipManager.ActiveTooltips[key] ~= tooltip then
		return
	end

	TooltipManager:ReleaseTooltip(tooltip)
end

function QTip:TooltipPairs()
	return pairs(TooltipManager.ActiveTooltips)
end

-- Publish on BFL namespace
BFL.QTip = QTip
