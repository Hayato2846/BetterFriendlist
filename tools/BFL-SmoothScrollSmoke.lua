-- Lua 5.4: lua tools/BFL-SmoothScrollSmoke.lua <repo> <WoW UI reference directory>
-- Loads the complete FriendsList module and Blizzard's actual interpolation /
-- scroll-percentage methods. Frame layout and the native ticker are mocked.
local repo = assert(arg[1], "repository root required")
local references = assert(arg[2], "WoW UI reference directory is required")
local function read(path)
	local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local setupSource = read(repo .. "/tools/BFL-FriendsListStartupSmoke.lua")
local boundary = assert(setupSource:find("-- A layout switch replaces the view", 1, true))
local body = [=[
local function between(text, first, last)
	local start = assert(text:find(first, 1, true))
	return text:sub(start, assert(text:find(last, start + #first, true)) - 1)
end
local function absoluteRead(path)
	local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
for _, flavor in ipairs({ "live", "forever", "classic" }) do
	local root = REFERENCE_ROOT .. "/wow-ui-source-" .. flavor
	local shared = root .. "/Interface/AddOns/Blizzard_SharedXML/"
	local context = setup({}, { classic = flavor == "classic" })
	local env, ticks = context.env, {}
	env.CreateFromMixins = function(...)
		local result = {}; for i = 1, select("#", ...) do
			for key, value in pairs(select(i, ...)) do result[key] = value end
		end; return result
	end
	env.Saturate = function(value) return math.max(0, math.min(1, value)) end
	env.ApproximatelyEqual = function(a, b) return math.abs(a - b) < 0.000001 end
	env.GetTickTime = function() return .02 end
	env.C_Timer.NewTicker = function(_, callback)
		local ticker = { callback = callback }; function ticker:Cancel() self.cancelled = true end
		ticks[#ticks + 1] = ticker; return ticker
	end
	local function execute(text, label) return assert(load(text, "@" .. label, "t", env))() end
	execute(absoluteRead(shared .. "Interpolator.lua"), flavor .. "/Interpolator.lua")
	execute(absoluteRead(shared .. "Shared/Scroll/ScrollController.lua"), flavor .. "/ScrollController.lua")
	env.ScrollBoxBaseMixin, env.ScrollBarMixin = {}, { Event = { OnScroll = "OnScroll" } }
	execute(between(absoluteRead(shared .. "Shared/Scroll/ScrollBox.lua"),
		"function ScrollBoxBaseMixin:SetScrollPercentage(", "function ScrollBoxBaseMixin:GetPanExtent("), flavor .. "/ScrollBox percentages")
	execute(between(absoluteRead(shared .. "Shared/Scroll/ScrollBar.lua"),
		"function ScrollBarMixin:SetScrollPercentage(", "function ScrollBarMixin:HasScrollableExtent("), flavor .. "/ScrollBar percentages")
	local box = env.CreateFromMixins(env.ScrollControllerMixin, env.ScrollBoxBaseMixin)
	local bar = env.CreateFromMixins(env.ScrollControllerMixin, env.ScrollBarMixin)
	box.scrollPercentage, bar.scrollPercentage = .1, .1
	box.scrollInternal = function(value) box:SetScrollPercentageInternal(value) end
	bar.scrollInternal = function(value) bar:SetScrollPercentageInternal(value) end
	-- Mirror the native ScrollUtil links, which always propagate immediately.
	box.Update = function(self) bar:SetScrollPercentage(self:GetScrollPercentage(), true) end
	bar.Update = function() end
	bar.TriggerEvent = function(_, _, percentage) box:SetScrollPercentage(percentage, true) end
	box.SetView = function(self, view) self.view = view end
	context.env.BetterFriendsFrame.ScrollFrame = { ScrollBox = box }
	context.env.BetterFriendsFrame.MinimalScrollBar = bar
	local bindings, expected = 0, false
	env.CreateScrollBoxListLinearView = function()
		return { SetElementFactory = function() end, SetElementExtentCalculator = function() end }
	end
	env.ScrollUtil = { InitScrollBoxListWithScrollBar = function(scrollBox, scrollBar, view)
		equal(scrollBox:CanInterpolateScroll(), expected, flavor .. ": box preference before binding")
		equal(scrollBar:CanInterpolateScroll(), expected, flavor .. ": bar preference before binding")
		bindings = bindings + 1; scrollBox:SetView(view)
	end }
	if flavor == "classic" then
		box:SetInterpolateScroll(true); bar:SetInterpolateScroll(true)
		equal(context.list:ApplyScrollInterpolation(), false, "Classic callback does not enable the Mainline feature")
		check(box:CanInterpolateScroll() and bar:CanInterpolateScroll(), "Classic callback does not mutate native controls")
		local classicCalls = 0
		context.list.InitializeClassicScrollFrame = function() classicCalls = classicCalls + 1 end
		context.list:InitializeScrollBox()
		equal(classicCalls, 1, "Classic keeps its existing FauxScrollFrame backend")
		equal(bindings, 0, "Classic does not bind the Mainline scrolling pair")
	else
		context.BFL.HasModernScrollBox = true
		context.list:InitializeScrollBox()
		box:SetScrollPercentage(.8)
		equal(box:GetScrollPercentage(), .8, flavor .. ": absent preference retains pre-3.0.0 immediate movement")
		equal(box.interpolator, nil, flavor .. ": default mode allocates no interpolator")
		context.BFL.modules.DB:Set("enableSmoothScrolling", true)
		equal(context.list:ApplyScrollInterpolation(), true, flavor .. ": explicit live opt-in")
		box:SetScrollPercentage(.2)
		bar:SetScrollPercentage(.6)
		check(box.interpolator.timer and bar.interpolator.timer, flavor .. ": native animations are active on both controls")
		local visible, boxTicker, barTicker = box:GetScrollPercentage(), box.interpolator.timer, bar.interpolator.timer
		context.BFL.modules.DB:Set("enableSmoothScrolling", false)
		equal(context.list:ApplyScrollInterpolation(), false, flavor .. ": live opt-out")
		check(boxTicker.cancelled and barTicker.cancelled, flavor .. ": opt-out cancels both real native interpolation tickers")
		equal(box.interpolator:GetInterpolateTo(), nil, flavor .. ": box animation has no remaining target")
		equal(bar.interpolator:GetInterpolateTo(), nil, flavor .. ": bar animation has no remaining target")
		equal(box:GetScrollPercentage(), visible, flavor .. ": opt-out preserves visible content position")
		equal(bar:GetScrollPercentage(), visible, flavor .. ": opt-out aligns the thumb without interpolation")
		for _ = 1, 20 do for _, ticker in ipairs(ticks) do if not ticker.cancelled then ticker.callback() end end end
		equal(box:GetScrollPercentage(), visible, flavor .. ": no old animation continues after opt-out")
		box:SetScrollPercentage(.9)
		equal(box:GetScrollPercentage(), .9, flavor .. ": subsequent wheel movement is immediate")
		context.BFL.modules.DB:Set("enableSmoothScrolling", true)
		context.list:ApplyScrollInterpolation()
		local previousView = box.view
		context.list:InitializeScrollBox()
		check(box.view ~= previousView, flavor .. ": Modern/Legacy switch installs its new view")
		check(box:CanInterpolateScroll() and bar:CanInterpolateScroll(), flavor .. ": explicit opt-in survives layout switches")
		equal(bindings, 1, flavor .. ": layout and live preference changes retain existing native links")
		equal(context.list:ApplyScrollInterpolation({}, bar), false, flavor .. ": missing native capability is harmless")
	end
	local version = absoluteRead(root .. "/version.txt"):match("[^\r\n]+")
	io.write("[OK] native scrolling source " .. flavor .. " " .. version .. "\n")
end
io.write("[OK] smooth scroll smoke: " .. assertions .. " assertions using production/native methods\n")
]=]
local env = setmetatable({ REFERENCE_ROOT = references }, { __index = _G })
assert(load(setupSource:sub(1, boundary - 1) .. body, "@native smooth scroll smoke", "t", env))()
