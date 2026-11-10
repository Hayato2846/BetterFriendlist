-- Lua 5.4: lua tools/BFL-ProfileDialogsSmoke.lua <repo>
-- Runs production Create/Show/button callbacks and BufferedEditBox. Native
-- clipboard delivery, frame layout and the profile codec are separate boundaries.
local repo = arg[1] or "."
local function read(path)
	local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local fixture = read(repo .. "/tools/BFL-BufferedEditBoxSmoke.lua")
local boundary = assert(fixture:find("local box = EditBox()", 1, true))
local body = [=[
local L = setmetatable({}, { __index = function(_, key) return key end })
local settings, exported, imported = {}, string.rep("A", 193708), nil
function settings:ExportSettings() return exported end
function settings:ImportSettings(text) imported = text; return not self.reject, "test rejection" end
BFL.DebugPrint = function() end
env.StaticPopupDialogs, env.UIParent = {}, {}
local errors = 0
env.StaticPopup_Show = function() errors = errors + 1 end
local function Widget(kind, parent)
	local widget = EditBox(""); widget.kind, widget.children, widget.parent = kind, {}, parent
	if parent and parent.children then parent.children[#parent.children + 1] = widget end
	for _, name in ipairs({ "SetSize", "SetPoint", "SetFrameStrata", "EnableMouse", "SetMovable", "RegisterForDrag", "SetJustifyH",
		"SetMultiLine", "SetFontObject", "SetWidth", "SetAutoFocus", "SetNormalFontObject", "SetHighlightFontObject", "StartMoving", "StopMovingOrSizing" }) do
		widget[name] = function() end
	end
	function widget:SetMaxLetters(value) self.maxLetters = value end
	function widget:SetMaxBytes(value) self.maxBytes = value end
	function widget:CreateFontString() return Widget("FontString", self) end
	function widget:SetScrollChild(child) self.scrollChild = child end
	function widget:Show() self.shown = true end
	function widget:IsShown() return self.shown == true end
	function widget:Hide()
		self.shown = false; self:Fire("OnHide")
		for _, child in ipairs(self.children) do child:Hide() end
	end
	return widget
end
env.CreateFrame = function(kind, _, parent) return Widget(kind, parent) end
env.Components = { GetActionButtonTemplate = function(_, fallback) return fallback end }
-- Scrollbar construction is covered by the settings style smoke. These dialogs
-- exercise the edit box attached to the scroll frame and its action callbacks.
function settings:CreateSettingsScrollFrame(parent) return env.CreateFrame("ScrollFrame", nil, parent) end
local file = assert(io.open(repo .. "/Modules/Settings.lua", "rb"))
local source = file:read("*a"); file:close()
local first = assert(source:find("function Settings:ShowExportDialog()", 1, true))
local last = assert(source:find("-- CALLBACK FUNCTIONS", first, true))
assert(load("local Settings, BFL, L, UI = ...\n" .. source:sub(first, last - 1), "@production profile dialogs", "t", env))(
	settings, BFL, L, { SPACING_MEDIUM = 15 })
local function Button(frame, text)
	for _, child in ipairs(frame.children) do if child.kind == "Button" and child.text == text then return child end end
	error("production button missing")
end
settings:ShowExportDialog()
local exportFrame, exportBox = settings.exportFrame, settings.exportFrame.scrollFrame.editBox
equal(exportBox.text, exported, "ShowExportDialog uses full controller replacement")
equal(exportBox.maxLetters, 0, "export has no native letter limit")
equal(exportBox.maxBytes, 0, "export has no independent native byte limit")
equal(exportFrame.pasteBuffer, BFL.BufferedEditBox.Attach(exportBox), "export controller is idempotent")
local originalCopy, originalEscape = exportBox:GetScript("OnKeyUp"), exportBox:GetScript("OnEscapePressed")
modifiers = { control = true }
exportBox:Fire("OnKeyDown", "C")
local copied = exportBox.selection and exportBox.text:sub(exportBox.selection[1] + 1, exportBox.selection[2])
exportBox:Fire("OnKeyUp", "C"); modifiers = {}
equal(copied, exported, "native Ctrl+C can read the fully highlighted export")
equal(exportFrame:IsShown(), false, "existing export Ctrl+C handler still closes the dialog")
settings:ShowImportDialog()
local importFrame, importBox = settings.importFrame, settings.importFrame.scrollFrame.editBox
equal(importBox.maxLetters, 0, "import has no native letter limit")
equal(importBox.maxBytes, 0, "import has no independent native byte limit")
equal(importFrame.pasteBuffer ~= exportFrame.pasteBuffer, true, "dialogs own independent controllers")
Paste(importBox, exported, nil, true)
equal(importBox.maxInserted <= 256, true, "actual import dialog paste keeps native intermediate buffer bounded")
Button(importFrame, L.SETTINGS_IMPORT_BTN):Fire("OnClick")
equal(imported, exported, "actual import callback reads all 193708 bytes before deferred finish")
equal(importFrame:IsShown(), false, "successful import callback still closes its dialog")
settings:ShowImportDialog(); Flush()
equal(importBox.text, "", "ShowImportDialog clears pending generations when reused")

settings:ShowExportDialog()
Paste(exportBox, string.rep("e", 513), nil, true)
Paste(importBox, string.rep("i", 600), nil, true)
Button(exportFrame, L.SETTINGS_EXPORT_BTN):Fire("OnClick")
equal(exportBox.text, string.rep("e", 513), "Copy All callback finishes buffered export before selecting")
equal(exportBox.selection[2], 513, "Copy All highlights complete committed text")
Button(importFrame, L.SETTINGS_IMPORT_BTN):Fire("OnClick"); Flush()
equal(imported, string.rep("i", 600), "independent import callback sees only its own chunks")
equal(exportBox:GetScript("OnKeyUp"), originalCopy, "Attach/reuse never replaces the copy script")
equal(exportBox:GetScript("OnEscapePressed"), originalEscape, "Attach/reuse never replaces Escape")

settings:ShowImportDialog()
Paste(importBox, string.rep("x", 300), nil, true)
importBox:Fire("OnKeyDown", "ESCAPE"); importBox:Fire("OnEscapePressed")
equal(importFrame:IsShown(), false, "existing import Escape handler still runs")
equal(importBox.text, string.rep("x", 300), "Escape/hide finishes pending paste without losing content")
settings:ShowImportDialog(); Flush()
equal(importBox.text, "", "old Escape paste callback cannot repopulate reopened import")
settings:ShowExportDialog(); Paste(exportBox, string.rep("z", 300), nil, true)
exported = "replacement export"
settings:ShowExportDialog(); Flush()
equal(exportBox.text, exported, "programmatic export reuse supersedes old pending input")
settings:ShowImportDialog(); settings.reject = true
Paste(importBox, "short profile")
Button(importFrame, L.SETTINGS_IMPORT_BTN):Fire("OnClick")
equal(imported, "short profile", "KeyUp finishes before the real import reader")
equal(errors, 1, "existing import validation error popup remains connected")
io.write("[OK] Profile dialogs smoke: " .. checks .. " checks using production Create/Show/button callbacks\n")
]=]
assert(load(fixture:sub(1, boundary - 1) .. body, "@profile dialogs smoke", "t", _G))()
