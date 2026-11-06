-- Lua 5.4: lua tools/BFL-BufferedEditBoxSmoke.lua <repo>
-- Native character insertion is simulated before OnChar. Actual C++ clipboard
-- delivery/latency still requires client QA; these are deterministic data tests.
local repo = arg[1] or "."
local checks, deferred, modifiers = 0, {}, {}
local secret = setmetatable({}, { __tostring = function() error("secret stringified") end })
local BFL = {}
function BFL:IsSecret(value) return value == secret end
local env = setmetatable({
	C_Timer = { After = function(_, callback) deferred[#deferred + 1] = callback end },
	IsControlKeyDown = function() return modifiers.control == true end,
	IsMetaKeyDown = function() return modifiers.meta == true end,
	IsShiftKeyDown = function() return modifiers.shift == true end,
	IsAltKeyDown = function() return modifiers.alt == true end,
	IsMacClient = function() return modifiers.mac == true end,
}, { __index = _G })
assert(loadfile(repo .. "/Utils/BufferedEditBox.lua", "t", env))("BetterFriendlist", BFL)
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. " (values withheld)")
end
local function Flush()
	local queue = deferred; deferred = {}
	for _, callback in ipairs(queue) do callback() end
end
local function EditBox(text)
	local box = { text = text or "", cursor = #(text or ""), scripts = {}, hooks = {}, sets = 0, clears = 0, maxInserted = 0 }
	function box:SetScript(name, callback) self.scripts[name] = callback end
	function box:GetScript(name) return self.scripts[name] end
	function box:HookScript(name, callback)
		self.hooks[name] = self.hooks[name] or {}; self.hooks[name][#self.hooks[name] + 1] = callback
	end
	function box:HasScript() return true end
	function box:Fire(name, ...)
		if self.scripts[name] then self.scripts[name](self, ...) end
		for _, callback in ipairs(self.hooks[name] or {}) do callback(self, ...) end
	end
	function box:GetText() return self.secretText and secret or self.text end
	function box:GetCursorPosition() return self.secretCursor and secret or self.cursor end
	function box:SetCursorPosition(position) self.cursor = position; self.selection = nil end
	function box:SetText(value)
		self.text, self.cursor, self.selection = value, #value, nil
		self.sets = self.sets + 1
		if value == "" then self.clears = self.clears + 1 end
		self:Fire("OnTextSet"); self:Fire("OnTextChanged", false)
	end
	function box:HighlightText(first, last)
		self.selection = { first or 0, last or #self.text }
	end
	function box:SetFocus() self.focused = true end
	function box:ClearFocus() self.focused = false; self:Fire("OnEditFocusLost") end
	function box:Hide() self:Fire("OnHide") end
	function box:NativeInsert(character, reported)
		local first, last = self.cursor, self.cursor
		if self.selection then first, last = self.selection[1], self.selection[2] end
		self.text = self.text:sub(1, first) .. character .. self.text:sub(last + 1)
		self.cursor, self.selection = first + #character, nil
		self.maxInserted = math.max(self.maxInserted, #self.text)
		self:Fire("OnTextChanged", true); self:Fire("OnChar", reported or character)
	end
	return box
end
local function Characters(text, callback)
	for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do callback(character) end
end
local function Paste(box, text, keys, noKeyUp)
	modifiers = keys or { control = true }
	box:Fire("OnKeyDown", modifiers.shift and "INSERT" or "V")
	Characters(text, function(character) box:NativeInsert(character) end)
	if not noKeyUp then box:Fire("OnKeyUp", modifiers.shift and "INSERT" or "V") end
	modifiers = {}
end

local box = EditBox()
local controller = BFL.BufferedEditBox.Attach(box)
equal(BFL.BufferedEditBox.Attach(box), controller, "Attach is idempotent")
equal(#box.hooks.OnChar, 1, "idempotent Attach adds no duplicate char hook")
local payload = string.rep("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", 5381):sub(1, 193708)
equal(#payload, 193708, "large fixture has exactly requested byte count")
Paste(box, payload, nil, true)
equal(box.maxInserted <= 256, true, "native character-insertion buffer remains bounded")
equal(box.sets - box.clears, 0, "large text has not been rebuilt before deferred completion")
equal(controller:GetText(), payload, "GetText finishes full large paste synchronously before timer")
equal(box.sets - box.clears, 1, "large paste has exactly one full-text reconstruction")
equal(box.cursor, #payload, "large paste preserves byte cursor")
Flush(); equal(box.text, payload, "old deferred callback cannot change committed paste")

for _, length in ipairs({ 0, 1, 255, 256, 257, 512, 513 }) do
	box = EditBox("before::after"); box.cursor = #"before:"
	controller = BFL.BufferedEditBox.Attach(box)
	local text = string.rep("x", length)
	Paste(box, text); Flush()
	equal(box.text, "before:" .. text .. ":after", "block boundary preserves prefix and suffix")
	equal(box.cursor, #"before:" + #text, "block boundary preserves insertion cursor")
end
box = EditBox("prefix SELECTED suffix"); box:HighlightText(7, 15)
controller = BFL.BufferedEditBox.Attach(box)
local unicode = string.rep("\233\155\170\240\159\144\177\195\164\n\r\n", 180)
Paste(box, unicode, { meta = true, mac = true }); Flush()
equal(box.text, "prefix " .. unicode .. " suffix", "Cmd paste preserves UTF-8, CRLF/newlines and native selection replacement")
equal(box.cursor, #"prefix " + #unicode, "UTF-8 cursor is restored in bytes")
box = EditBox("head::tail"); box.cursor = #"head:"
controller = BFL.BufferedEditBox.Attach(box)
modifiers = { control = true }; box:Fire("OnKeyDown", "V")
for _ = 1, 1025 do box:NativeInsert("\n", "\r\n") end
modifiers = {}; box:Fire("OnKeyUp", "V"); Flush()
equal(box.text, "head:" .. string.rep("\n", 1025) .. ":tail", "native normalization is preserved independently of OnChar argument bytes")
equal(box.cursor, #"head:" + 1025, "normalized insertion still uses native byte cursor")
equal(box.maxInserted <= #"head::tail" + 256, true, "normalization cannot defeat bounded native block capture")
box = EditBox("replace everything"); box:HighlightText()
controller = BFL.BufferedEditBox.Attach(box)
Paste(box, payload, { shift = true }); Flush()
equal(box.text, payload, "Shift Insert supports select-all replacement")

box = EditBox("base"); controller = BFL.BufferedEditBox.Attach(box)
Paste(box, string.rep("a", 300), nil, true) -- First KeyDown callback remains queued.
Paste(box, string.rep("b", 300), nil, true)
Flush(); equal(box.text, "base" .. string.rep("a", 300) .. string.rep("b", 300), "second paste finishes old state before beginning its own")
Paste(box, string.rep("c", 300), nil, true); controller:SetText("replacement")
Flush(); equal(box.text, "replacement", "controller SetText invalidates pending chunks and timers")
Paste(box, string.rep("d", 300), nil, true); box:SetText("external")
Flush(); equal(box.text, "external", "external native SetText discards pending paste")
Paste(box, string.rep("e", 300), nil, true); box:ClearFocus()
equal(box.text, "external" .. string.rep("e", 300), "focus loss finishes synchronously")
Paste(box, string.rep("f", 300), nil, true); box:Hide(); controller:SetText("reuse")
Flush(); equal(box.text, "reuse", "hide and dialog reuse invalidate older deferred callbacks")

box = EditBox(); controller = BFL.BufferedEditBox.Attach(box)
local escapeCalls, copyCalls = 0, 0
local escape = function() escapeCalls = escapeCalls + 1 end
local keyUp = function(_, key) if key == "C" then copyCalls = copyCalls + 1 end end
box:SetScript("OnEscapePressed", escape); box:SetScript("OnKeyUp", keyUp)
equal(box:GetScript("OnEscapePressed"), escape, "original Escape script is preserved")
equal(box:GetScript("OnKeyUp"), keyUp, "original copy script is preserved")
Paste(box, string.rep("k", 300), nil, true)
box:Fire("OnKeyDown", "LEFT")
equal(box.text, string.rep("k", 300), "every new key finishes old paste before native key behavior")
box:Fire("OnEscapePressed"); box:Fire("OnKeyUp", "C"); Flush()
equal(escapeCalls, 1, "existing Escape callback still runs")
equal(copyCalls, 1, "existing copy callback still runs")
local ordinary = EditBox(); BFL.BufferedEditBox.Attach(ordinary)
Paste(ordinary, string.rep("n", 300), {})
Flush(); equal(ordinary.clears, 0, "ordinary V typing is not treated as paste")
for _, keys in ipairs({ { control = true, alt = true }, { meta = true }, { control = true, mac = true } }) do
	ordinary = EditBox(); BFL.BufferedEditBox.Attach(ordinary)
	Paste(ordinary, string.rep("n", 300), keys); Flush()
	equal(ordinary.clears, 0, "AltGr and other-platform shortcuts do not start paste buffering")
end
box = EditBox(); controller = BFL.BufferedEditBox.Attach(box)
Paste(box, string.rep("t", 600), nil, true); Flush()
equal(box.text, string.rep("t", 600), "KeyDown schedules completion even when no KeyUp arrives")
Paste(box, string.rep("u", 300))
equal(box.text, string.rep("t", 600) .. string.rep("u", 300), "KeyUp completes synchronously before any reader")

-- Existing scripts can synchronously inspect/reset content during internal SetText.
box = EditBox(); controller = BFL.BufferedEditBox.Attach(box)
local inspected
box:SetScript("OnTextSet", function(self)
	if self.text == "" and not inspected then inspected = controller:GetText() end
end)
Paste(box, string.rep("r", 256)); Flush()
equal(inspected, string.rep("r", 256), "reentrant GetText sees logical complete chunk")
equal(box.text, string.rep("r", 256), "reentrant finish neither loses nor duplicates a chunk")
equal(box.cursor, 256, "outer clear cannot reset cursor after reentrant finish")
box = EditBox(); controller = BFL.BufferedEditBox.Attach(box)
local resetDuringClear = false
box:SetScript("OnTextSet", function(self)
	if self.text == "" and not resetDuringClear then resetDuringClear = true; self:SetText("authoritative reset") end
end)
Paste(box, string.rep("z", 256)); Flush()
equal(box.text, "authoritative reset", "nested external SetText wins over internal clear")
box = EditBox(); controller = BFL.BufferedEditBox.Attach(box)
resetDuringClear = false
box:SetScript("OnTextSet", function(self)
	if not resetDuringClear then resetDuringClear = true; self:SetText("") end
end)
Paste(box, string.rep("z", 256)); Flush()
equal(box.text, "", "nested external empty reset also discards old chunks")

local left, right = EditBox("left:"), EditBox("right:")
local leftBuffer, rightBuffer = BFL.BufferedEditBox.Attach(left), BFL.BufferedEditBox.Attach(right)
Paste(left, string.rep("l", 300), nil, true); Paste(right, string.rep("r", 600), nil, true)
rightBuffer:SetText("right replacement"); Flush()
equal(leftBuffer:GetText(), "left:" .. string.rep("l", 300), "independent edit boxes never share chunks or generations")
equal(rightBuffer:GetText(), "right replacement", "one edit box reset does not revive another box's callback")
box = EditBox("readable"); controller = BFL.BufferedEditBox.Attach(box)
box.secretText = true
equal(controller:GetText(), nil, "restricted text is never inspected or returned")
box.secretText = false; box.secretCursor = true
Paste(box, string.rep("s", 300)); Flush()
equal(box.text, "readable" .. string.rep("s", 300), "unreadable cursor does not cause truncation")

io.write("[OK] Buffered EditBox smoke: " .. checks .. " checks; exact 193708-byte paste preserved with <=256-byte native insertion buffer\n")
