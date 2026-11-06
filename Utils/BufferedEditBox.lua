local _, BFL = ...

-- Keep native paste insertion buffers small; build the complete text only once.
local BufferedEditBox = {}
BFL.BufferedEditBox = BufferedEditBox
local controllers = setmetatable({}, { __mode = "k" })
local BLOCK_CHARACTERS = 256

local function Readable(value, expectedType)
	return not (BFL.IsSecret and BFL:IsSecret(value)) and type(value) == expectedType
end

local function PasteShortcut(key)
	if not Readable(key, "string") then return false end
	if IsAltKeyDown and IsAltKeyDown() then return false end
	if key == "V" then
		if IsMacClient and IsMacClient() then return IsMetaKeyDown and IsMetaKeyDown() end
		return IsControlKeyDown and IsControlKeyDown()
	end
	return (key == "INSERT" or key == "Insert") and IsShiftKeyDown and IsShiftKeyDown()
		and not (IsControlKeyDown and IsControlKeyDown()) and not (IsMetaKeyDown and IsMetaKeyDown())
end

local Controller = {}

function Controller:Discard()
	self.generation = self.generation + 1
	self.active, self.deferred = false, nil
	self.chunks, self.suffix = nil, nil
	self.characters, self.chunkBytes = 0, 0
end

function Controller:WriteNative(text, cursor, kind)
	local write = { generation = self.generation, text = text, handled = false, kind = kind }
	local stack = self.writes
	stack[#stack + 1] = write
	local ok, err = pcall(function()
		self.editBox:SetText(text)
		-- A pre-existing script may replace text or finish this paste reentrantly.
		if self.generation == write.generation and cursor ~= nil then self.editBox:SetCursorPosition(cursor) end
	end)
	stack[#stack] = nil
	if not ok then error(err, 0) end
end

function Controller:Finish()
	if not self.active then return true end
	if not self.chunks then self:Discard(); return true end
	local write = self.writes[#self.writes]
	local remainder = write and write.kind == "clear" and "" or self.editBox:GetText()
	if not Readable(remainder, "string") then return false end
	local cursor = self.editBox:GetCursorPosition()
	if not Readable(cursor, "number") or cursor < 0 or cursor > #remainder or cursor % 1 ~= 0 then cursor = #remainder end
	local text = table.concat(self.chunks) .. remainder .. self.suffix
	local position = self.chunkBytes + cursor
	self:Discard()
	self:WriteNative(text, position, "commit")
	return true
end

function Controller:SetText(text)
	-- Programmatic replacement has priority over old paste work and callbacks.
	self:Discard()
	self:WriteNative(text, nil, "replace")
end

function Controller:GetText()
	if not self:Finish() then return nil end
	local text = self.editBox:GetText()
	return Readable(text, "string") and text or nil
end

function Controller:Start()
	self:Discard()
	self.active = true
	self:DeferFinish()
end

function Controller:OnChar()
	if not self.active or #self.writes > 0 then return end
	self.characters = self.characters + 1
	if self.characters < BLOCK_CHARACTERS then return end
	local text, cursor = self.editBox:GetText(), self.editBox:GetCursorPosition()
	if not Readable(text, "string") or not Readable(cursor, "number") then return end
	if cursor < 0 or cursor > #text or cursor % 1 ~= 0 then return end
	local chunk
	if not self.chunks then
		-- The first native insertion has already performed any selection replacement.
		-- Keep the native prefix in this first chunk. Do not infer insertion
		-- bytes from OnChar arguments: native input may normalize their text.
		self.suffix = text:sub(cursor + 1)
		self.chunks = {}
		chunk = text:sub(1, cursor)
	else
		chunk = text
	end
	self.chunks[#self.chunks + 1] = chunk
	self.chunkBytes = self.chunkBytes + #chunk
	self.characters = 0
	self:WriteNative("", 0, "clear")
end

function Controller:OnTextSet()
	local write = self.writes[#self.writes]
	if write and not write.handled and write.generation == self.generation then
		local text = self.editBox:GetText()
		if Readable(text, "string") and text == write.text then write.handled = true; return end
	end
	-- Also catches external resets nested inside an existing OnTextSet handler.
	self:Discard()
end

function Controller:DeferFinish()
	if not self.active or self.deferred == self.generation then return end
	local generation = self.generation
	self.deferred = generation
	C_Timer.After(0, function()
		if self.active and self.generation == generation then self:Finish() end
	end)
end

function BufferedEditBox.Attach(editBox)
	if controllers[editBox] then return controllers[editBox] end
	local controller = setmetatable({ editBox = editBox, generation = 0, writes = {} }, { __index = Controller })
	controllers[editBox] = controller
	controller:Discard()
	editBox:HookScript("OnKeyDown", function(_, key)
		if not controller:Finish() then return end
		if PasteShortcut(key) then controller:Start() end
	end)
	editBox:HookScript("OnChar", function() controller:OnChar() end)
	editBox:HookScript("OnKeyUp", function() controller:Finish() end)
	editBox:HookScript("OnEditFocusLost", function() controller:Finish() end)
	editBox:HookScript("OnHide", function() controller:Finish() end)
	if not editBox.HasScript or editBox:HasScript("OnTextSet") then
		editBox:HookScript("OnTextSet", function() controller:OnTextSet() end)
	end
	return controller
end
