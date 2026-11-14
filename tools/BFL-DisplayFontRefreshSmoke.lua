-- lua tools/BFL-DisplayFontRefreshSmoke.lua <repo> [<before snapshot>]
-- Production event scheduling/font recovery; native rendering is modeled.
local root, before = arg[1] or ".", arg[2]
local checks, now, combat, queue = 0, 0, false, {}
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local callbacks, settings, order = {}, {}, {}
local BFL = { modules = {}, L = {}, UI = { CONSTANTS = {} } }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterEventCallback(event, callback)
	callbacks[event] = callbacks[event] or {}; table.insert(callbacks[event], callback)
end
function BFL:IsSecret(value) return value == "unreadable" end
local env = setmetatable({
	InCombatLockdown = function() return combat end,
	GetLocale = function() return "enUS" end,
	STANDARD_TEXT_FONT = "Native.ttf",
	UIParent = { GetEffectiveScale = function() return 1 end },
	C_Timer = { After = function(delay, callback) queue[#queue + 1] = { at = now + delay, callback = callback } end },
}, { __index = _G })
env._G = env
local function Load(path) return assert(loadfile((before or root) .. "/" .. path, "t", env))("BetterFriendlist", BFL) end
local function Advance(to)
	local iterations = 0
	while true do
		table.sort(queue, function(a, b) return a.at < b.at end)
		if not queue[1] or queue[1].at > to then break end
		iterations = iterations + 1; assert(iterations < 100, "Unbounded display refresh timers")
		local timer = table.remove(queue, 1); now = timer.at; timer.callback()
	end
	now = to
end
local function Fire(event, ...)
	for _, callback in ipairs(callbacks[event] or {}) do callback(...) end
end
local database = { Get = function(_, key, fallback) if settings[key] ~= nil then return settings[key] end; return fallback end }
BFL.modules.DB = database
Load("Modules/FrameSettings.lua")
local frameSettings = BFL.modules.FrameSettings
frameSettings.db = { useUIPanelSystem = false }
local scales, positions, fonts, headers = 0, 0, 0, 0
function frameSettings:ApplyScale() scales = scales + 1; order[#order + 1] = "scale"; self.scaleRefreshAfterCombat = combat or nil end
function frameSettings:ApplyPosition() positions = positions + 1 end
function frameSettings:ApplyClamping() end
BFL.FontManager = { RefreshDisplayFonts = function() assert(not combat); fonts = fonts + 1; order[#order + 1] = "fonts" end }
BFL.modules.FriendsList = { RefreshGroupHeadersAfterDisplayChange = function() assert(not combat); headers = headers + 1; order[#order + 1] = "headers" end }
frameSettings:OnPlayerLogin()
Advance(0)
Fire("DISPLAY_SIZE_CHANGED"); Fire("UI_SCALE_CHANGED")
Advance(0.05)
equal(fonts, 0, "Font refresh waits for native metrics")
Fire("CVAR_UPDATE", "gxMaximize")
Advance(0.16)
equal(fonts, 0, "The newest event supersedes the first pending refresh")
Advance(0.3)
equal(fonts, 1, "One event burst refreshes button fonts once")
equal(headers, 1, "One event burst refreshes group counters once")
equal(order[#order - 1], "fonts", "Fonts are rebound before counter measurement")
equal(order[#order], "headers", "Counter measurement follows font rebinding")
local oldScales = scales
Fire("CVAR_UPDATE", "Sound_MasterVolume"); Fire("CVAR_UPDATE", "unreadable"); Fire("CVAR_UPDATE", {})
Advance(0.6)
equal(scales, oldScales, "Unrelated or unreadable CVars do not trigger refreshes")
combat = true
Fire("DISPLAY_SIZE_CHANGED"); Advance(0.9)
equal(fonts, 1, "Display changes never mutate fonts in combat")
equal(headers, 1, "Display changes never mutate group headers in combat")
equal(frameSettings.displayTextRefreshAfterCombat, true, "Combat retains one pending text refresh")
combat = false
Fire("PLAYER_REGEN_ENABLED"); Advance(1.2)
equal(fonts, 2, "Leaving combat restores the deferred fonts")
equal(headers, 2, "Leaving combat restores the deferred counters")
Fire("CVAR_UPDATE", "uiScale"); Advance(1.5)
equal(fonts, 3, "Explicit UI-scale changes also refresh fonts")
equal(frameSettings.referenceUIScale, 1, "UI-scale reference behavior is preserved")

-- Native state/font objects are immutable here. Only BFL-owned instances may
-- be rebound, preserving a skin's direct size/face override and its colors.
Load("Utils/FontManager.lua")
local manager = BFL.FontManager
local function Font(path, size)
	return { path = path, size = size, GetFont = function(self) return self.path, self.size, "" end,
		SetFont = function() error("Shared font objects must never be mutated") end }
end
local function Label(object)
	local text = { object = object, path = object.path, size = object.size, flags = "", color = { 0.2, 0.6, 0.9, 0.7 }, shadow = { 1, -1 }, shadowColor = { 0, 0, 0, 0.8 }, setFontCalls = 0, justifyH = "LEFT", justifyV = "TOP", spacing = 2 }
	function text:GetFont() return self.path, self.size, self.flags end
	function text:GetFontObject() return self.object end
	function text:SetFontObject(value)
		if self.object == value then return end -- Model native same-object fast paths.
		self.object, self.path, self.size, self.flags, self.renderedSize = value, value.path, value.size, "", value.size
		self.justifyH, self.justifyV, self.spacing = "CENTER", "MIDDLE", 0
	end
	function text:SetFont(path, size, flags) self.path, self.size, self.flags, self.renderedSize = path, size, flags, size; self.setFontCalls = self.setFontCalls + 1; return true end
	function text:GetTextColor() return table.unpack(self.color) end
	function text:SetTextColor(...) self.color = { ... } end
	function text:GetShadowOffset() return table.unpack(self.shadow) end
	function text:SetShadowOffset(...) self.shadow = { ... } end
	function text:GetShadowColor() return table.unpack(self.shadowColor) end
	function text:SetShadowColor(...) self.shadowColor = { ... } end
	function text:GetJustifyH() return self.justifyH end
	function text:SetJustifyH(value) self.justifyH = value end
	function text:GetJustifyV() return self.justifyV end
	function text:SetJustifyV(value) self.justifyV = value end
	function text:GetSpacing() return self.spacing end
	function text:SetSpacing(value) self.spacing = value end
	return text
end
local function Button(override)
	local states = { Normal = Font("Native.ttf", 12), Highlight = Font("Native.ttf", 12), Disabled = Font("Native.ttf", 12) }
	local button = { label = Label(states.Normal), rebound = {} }
	if override then button.label.path, button.label.size = "Skin.ttf", 18 end
	function button:GetFontString() return self.label end
	function button:GetWidth() return 100 end
	function button:GetHeight() return 26 end
	function button:GetChildren() return end
	for _, state in ipairs({ "Normal", "Highlight", "Disabled" }) do
		button["Get" .. state .. "FontObject"] = function() return states[state] end
		button["Set" .. state .. "FontObject"] = function(self, object)
			equal(object, states[state], "Native state font identity is preserved")
			self.rebound[state] = (self.rebound[state] or 0) + 1
			if state == "Normal" then self.label:SetFontObject(object) end
		end
	end
	return button
end
local custom, native = Button(true), Button(false)
native.label.renderedSize = 6 -- Renderer cache is stale; declared font remains 12.
local family = { path = "AlphabetFallback.ttf", size = 18 }
local multilingual = Button(false)
multilingual.label = Label(family) -- FontFamily has no Font:GetFont method.
local foreign = Button(false)
foreign.IsForbidden = function() return true end
foreign.GetFontString = function() error("Forbidden controls must not be read") end
local rootFrame = { GetChildren = function() return custom, native, multilingual, foreign end }
BFL.MainFrame = rootFrame
BFL.modules.FriendTagEditor = { frame = rootFrame }
local refreshed = manager:RefreshDisplayFonts()
equal(refreshed, 3, "Overlapping BFL roots are visited only once")
equal(custom.rebound.Normal, 1, "Normal font state is rebound")
equal(custom.rebound.Highlight, 1, "Dormant hover state is rebound")
equal(custom.rebound.Disabled, 1, "Disabled font state is rebound")
equal(custom.label.path, "Skin.ttf", "A theme's direct font face survives")
equal(custom.label.size, 18, "A custom button size survives")
equal(custom.label.color[3], 0.9, "Theme text color survives")
equal(custom.label.color[4], 0.7, "Theme text alpha survives")
equal(custom.label.shadowColor[4], 0.8, "Theme shadow alpha survives")
equal(custom.label.justifyH, "LEFT", "Button label alignment survives font rebinding")
equal(custom.label.justifyV, "TOP", "Button vertical alignment survives font rebinding")
equal(custom.label.spacing, 2, "Button text spacing survives font rebinding")
equal(native.label.setFontCalls, 0, "Inherited font families do not acquire direct font overrides")
equal(native.label.renderedSize, 12, "A different binding invalidates a stale cache even with same-object native fast paths")
equal(multilingual.label:GetFontObject(), family, "Alphabet fallback family identity survives rebinding")
equal(multilingual.label.size, 18, "Alphabet fallback family size survives rebinding")
equal(multilingual.label.setFontCalls, 0, "Alphabet fallback families retain inheritance")
combat = true
equal(manager:RefreshDisplayFonts(), false, "Font-manager callers also honor combat lockdown")
equal(custom.rebound.Normal, 1, "A combat refresh leaves font states untouched")
combat = false

-- Both native ScrollBox layouts and the Classic header pool dispatch only
-- headers, without rebuilding friend data, changing selection or scrolling.
Load("Modules/FriendsList.lua")
local list, calls = BFL.modules.FriendsList, 0
local function Header(shown, kind)
	return { IsShown = function() return shown end, elementData = { buttonType = kind or 2 } }
end
local visible, hidden, friend = Header(true), Header(false), Header(true, 1)
function list:UpdateGroupHeaderButton(button, data) equal(button.elementData, data, "Existing provider data is retained"); calls = calls + 1 end
function list:UpdateFriendsList() error("Display text recovery must not rescan friend data") end
local provider = {}
list.activeProviderDisplayList, list.selectedFriendUID = provider, "friend-42"
BFL.HasModernScrollBox = true
list.scrollBox = { ForEachFrame = function(_, callback) for _, button in ipairs({ visible, hidden, friend }) do callback(button, button.elementData) end end }
equal(list:RefreshGroupHeadersAfterDisplayChange(), 1, "ScrollBox refreshes only shown group headers")
equal(calls, 1, "Friend rows and hidden headers are untouched")
BFL.HasModernScrollBox = false
list.classicHeaderPool = { visible, hidden }
equal(list:RefreshGroupHeadersAfterDisplayChange(), 1, "Classic refreshes its header pool")
equal(list.activeProviderDisplayList, provider, "Provider identity survives display recovery")
equal(list.selectedFriendUID, "friend-42", "Selection survives display recovery")
combat = true
equal(list:RefreshGroupHeadersAfterDisplayChange(), 0, "Header callers also honor combat lockdown")
io.write("PASS: display font recovery scheduling, state preservation and header dispatch (" .. checks .. " checks; mocked engine)\n")
