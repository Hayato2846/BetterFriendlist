--------------------------------------------------------------------------------
---- BFL_QTip ScriptManager (forked from LibQTip-2.0)
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

---@class LibQTip-2.0.ScriptManager
local ScriptManager = QTip.ScriptManager

ScriptManager.FrameScriptMetadata = ScriptManager.FrameScriptMetadata or {}

---@type table<LibQTip-2.0.ScriptType, fun(frame: LibQTip-2.0.ScriptFrame, ...)>
local FrameScriptHandler = {
	OnEnter = function(frame, ...)
		local highlightFrame = frame.Tooltip.HighlightFrame

		highlightFrame:SetParent(frame)
		highlightFrame:SetAllPoints(frame)
		highlightFrame:Show()

		ScriptManager:CallScriptHandler(frame, "OnEnter", ...)
	end,
	OnLeave = function(frame, ...)
		local highlightFrame = frame.Tooltip.HighlightFrame

		highlightFrame:Hide()
		highlightFrame:ClearAllPoints()
		highlightFrame:SetParent(nil)

		ScriptManager:CallScriptHandler(frame, "OnLeave", ...)
	end,
	OnMouseDown = function(frame, ...)
		ScriptManager:CallScriptHandler(frame, "OnMouseDown", ...)
	end,
	OnMouseUp = function(frame, ...)
		ScriptManager:CallScriptHandler(frame, "OnMouseUp", ...)
	end,
	OnReceiveDrag = function(frame, ...)
		ScriptManager:CallScriptHandler(frame, "OnReceiveDrag", ...)
	end,
}

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function ScriptManager:CallScriptHandler(frame, scriptType, ...)
	local scriptMetadata = ScriptManager.FrameScriptMetadata[frame][scriptType]

	if scriptMetadata then
		scriptMetadata.Handler(frame, unpack(scriptMetadata.Parameters), ...)
	end
end

function ScriptManager:ClearScripts(frame)
	for scriptType in pairs(FrameScriptHandler) do
		self:RawSetScript(frame, scriptType, nil)
	end

	local scriptTypeMetadata = self.FrameScriptMetadata[frame]

	if not scriptTypeMetadata then
		return
	end

	if
		scriptTypeMetadata.OnEnter
		or scriptTypeMetadata.OnLeave
		or scriptTypeMetadata.OnMouseDown
		or scriptTypeMetadata.OnMouseUp
		or scriptTypeMetadata.OnReceiveDrag
	then
		frame:EnableMouse(false)
	end

	self.FrameScriptMetadata[frame] = nil
end

function ScriptManager:RawSetScript(frame, scriptType, handler)
	QTip.FrameMetatable.__index.SetScript(frame, scriptType, handler)
end

function ScriptManager:SetScript(frame, scriptType, handler, ...)
	if not FrameScriptHandler[scriptType] then
		return
	end

	local scriptTypeMetadata = self.FrameScriptMetadata[frame]

	if not scriptTypeMetadata then
		scriptTypeMetadata = {}

		self.FrameScriptMetadata[frame] = scriptTypeMetadata
	end

	if handler then
		scriptTypeMetadata[scriptType] = {
			Handler = handler,
			Parameters = { ... },
		}
	else
		scriptTypeMetadata[scriptType] = nil
	end

	if scriptType == "OnMouseDown" or scriptType == "OnMouseUp" or scriptType == "OnReceiveDrag" then
		if handler then
			self:RawSetScript(frame, scriptType, FrameScriptHandler[scriptType])
		else
			self:RawSetScript(frame, scriptType, nil)
		end
	end

	if
		scriptTypeMetadata.OnEnter
		or scriptTypeMetadata.OnLeave
		or scriptTypeMetadata.OnMouseDown
		or scriptTypeMetadata.OnMouseUp
		or scriptTypeMetadata.OnReceiveDrag
	then
		frame:EnableMouse(true)

		self:RawSetScript(frame, "OnEnter", FrameScriptHandler.OnEnter)
		self:RawSetScript(frame, "OnLeave", FrameScriptHandler.OnLeave)
	else
		frame:EnableMouse(false)

		self:RawSetScript(frame, "OnEnter", nil)
		self:RawSetScript(frame, "OnLeave", nil)
	end
end
