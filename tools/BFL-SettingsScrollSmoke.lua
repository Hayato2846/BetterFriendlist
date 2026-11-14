-- lua tools/BFL-SettingsScrollSmoke.lua <repo> [wow-ui-source root]
-- Real Blizzard interpolation with isolated scrollframes and a deterministic clock.
local root = arg[1] or "."
local uiRoot = arg[2] or "C:/Users/hofer/Documents/BFL/references/wow-ui-source-live"
local checks, ticks, timers = 0, {}, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(math.abs(actual - expected) < 0.001, message .. ": " .. tostring(actual))
end
local enabled = false
local BFL = { modules = {} }
function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
function BFL:GetModule(name) return self.modules[name] end
BFL.modules.DB = { Get = function(_, key, default)
	if key == "enableSettingsSmoothScrolling" then return enabled end
	return default
end }
local env = setmetatable({}, { __index = _G })
function env.CreateFromMixins(...)
	local result = {}; for _, mixin in ipairs({ ... }) do for key, value in pairs(mixin) do result[key] = value end end
	return result
end
function env.Saturate(value) return math.max(0, math.min(1, value)) end
function env.ApproximatelyEqual(a, b) return math.abs(a - b) < 0.0001 end
function env.GetTickTime() return 1 / 60 end
env.C_Timer = { NewTicker = function(_, callback)
	timers = timers + 1
	local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
	ticks[#ticks + 1] = timer
	return timer
end }
function env.hooksecurefunc(owner, method, callback)
	local original = owner[method]
	owner[method] = function(...) original(...); callback(...) end
end
local function Advance()
	for _ = 1, 20 do
		for _, timer in ipairs(ticks) do if not timer.cancelled then timer.callback() end end
	end
end
local function Frame(step)
	local frame = { offset = 0, range = 300, scripts = {}, height = 100 }
	function frame:GetScript(event) return self.scripts[event] end
	function frame:SetScript(event, callback) self.scripts[event] = callback end
	function frame:HookScript(event, callback)
		local original = self.scripts[event]
		self.scripts[event] = function(...) if original then original(...) end; callback(...) end
	end
	function frame:GetVerticalScroll() return self.offset end
	function frame:GetVerticalScrollRange() return self.range end
	function frame:GetHeight() return self.height end
	function frame:SetVerticalScroll(value) self.offset = math.max(0, math.min(self.range, value)) end
	frame:SetScript("OnMouseWheel", function(self, delta) self:SetVerticalScroll(self.offset - delta * step) end)
	frame.ScrollBar = { scripts = {}, SetScript = frame.SetScript, GetScript = frame.GetScript,
		SetInterpolateScroll = function(self, value) self.interpolate = value end }
	return frame
end
assert(loadfile(uiRoot .. "/Interface/AddOns/Blizzard_SharedXML/Interpolator.lua", "t", env))()
assert(loadfile(root .. "/Modules/SettingsScroll.lua", "t", env))("BetterFriendlist", BFL)
local scrolling = BFL.modules.SettingsScroll
local frame = Frame(30)
scrolling:Register(frame)
local function Wheel(delta, owner)
	owner = owner or frame
	owner:GetScript("OnMouseWheel")(owner, delta)
end
Wheel(-1)
equal(frame.offset, 30, "default scrolling is immediate")
equal(timers, 0, "disabled scrolling creates no ticker")
local wheel = frame:GetScript("OnMouseWheel")
scrolling:Register(frame)
check(wheel == frame:GetScript("OnMouseWheel"), "re-registering does not stack wheel handlers")
enabled = true; scrolling:Refresh(); frame:SetVerticalScroll(0)
Wheel(-1)
check(frame.offset > 0 and frame.offset < 30, "enabled scrolling interpolates the wheel movement")
Wheel(-1); Wheel(-1); Advance()
equal(frame.offset, 90, "fast wheel gestures accumulate their full distance")
Wheel(1); Advance()
equal(frame.offset, 60, "reverse scrolling reaches the expected offset")
Wheel(-1)
enabled = false; scrolling:Refresh()
local stopped = frame.offset; Advance()
equal(frame.offset, stopped, "disabling during motion cancels the ticker")
Wheel(-1)
equal(frame.offset, stopped + 30, "disabling restores immediate scrolling")
enabled = true; scrolling:Refresh()
for _, event in ipairs({ "OnHide", "OnScrollRangeChanged", "OnSizeChanged" }) do
	frame:SetVerticalScroll(0); Wheel(-1)
	frame:GetScript(event)(frame)
	stopped = frame.offset; Advance()
	equal(frame.offset, stopped, event .. " stops an old gesture")
end
frame:SetVerticalScroll(0); Wheel(-1); frame:SetVerticalScroll(0); Advance()
equal(frame.offset, 0, "navigation reset takes precedence over an animated gesture")
Wheel(-1); frame:SetVerticalScroll(123); Advance()
equal(frame.offset, 123, "search focus and thumb dragging keep their exact offset")
frame:SetVerticalScroll(0); Wheel(-1, frame.ScrollBar); Advance()
equal(frame.offset, 30, "wheel scrolling over the scrollbar also animates the content")
check(frame.ScrollBar.interpolate == false, "native and host interpolation do not run together")
Wheel(-100); Advance(); equal(frame.offset, 300, "scrolling clamps at the lower boundary")
Wheel(100); Advance(); equal(frame.offset, 0, "scrolling clamps at the upper boundary")
frame.BFL_SettingsContentHeight = 160
Wheel(-100); Advance(); equal(frame.offset, 60, "hidden legacy controls do not add blank scroll space")
frame.BFL_SettingsContentHeight = 100; frame:SetVerticalScroll(0)
Wheel(-1); Advance(); equal(frame.offset, 0, "a page without overflow does not move")
local center = Frame(64); scrolling:Register(center, 64)
center:GetScript("OnMouseWheel")(center, -1); Advance()
equal(center.offset, 64, "Settings Center keeps its own wheel step")
env.CreateInterpolator = nil
center:GetScript("OnMouseWheel")(center, -1)
equal(center.offset, 128, "clients without an interpolator retain immediate wheel input")
for _, timer in ipairs(ticks) do check(timer.cancelled, "an animation ticker was left running") end
io.write(string.format("PASS: Settings wheel animation and lifecycle (%d checks) using %s\n", checks, uiRoot))
