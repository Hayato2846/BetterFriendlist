local ADDON_NAME, BFL = ...
local SettingsScroll = BFL:RegisterModule("SettingsScroll", {})
local frames = {}

local function GetRange(frame)
	local range = frame:GetVerticalScrollRange()
	if frame.BFL_SettingsContentHeight then
		range = math.min(range, math.max(0, frame.BFL_SettingsContentHeight - frame:GetHeight()))
	end
	return range
end

local function Stop(state)
	if state.interpolator then state.interpolator:Cancel() end
	state.target = nil
end

local function ApplyPreference(state)
	local db = BFL:GetModule("DB")
	state.enabled = db and db:Get("enableSettingsSmoothScrolling", false) == true or false
	if not state.enabled then Stop(state) end
end

-- Only addon-owned Settings scrollframes are registered here. Native scrollbar
-- bindings remain responsible for keeping the thumb aligned with the content.
function SettingsScroll:Register(frame, step)
	if not frame then return end
	local state = frames[frame]
	if state then
		ApplyPreference(state)
		return
	end
	state = { step = step or 30 }
	frames[frame] = state
	ApplyPreference(state)
	local function Wheel(wheelFrame, original)
		wheelFrame:SetScript("OnMouseWheel", function(owner, delta)
			if not state.enabled or not CreateInterpolator then
				if original then original(owner, delta) end
				return
			end
			local current = frame:GetVerticalScroll()
			local target = math.max(0, math.min(GetRange(frame), (state.target or current) - delta * state.step))
			if math.abs(target - current) < 0.01 then
				Stop(state)
				return
			end
			state.target = target
			state.interpolator = state.interpolator or CreateInterpolator()
			state.interpolator:Interpolate(current, target, 0.11, function(value)
				state.writing = true
				frame:SetVerticalScroll(value)
				state.writing = nil
			end, function() state.target = nil end)
		end)
	end
	Wheel(frame, frame:GetScript("OnMouseWheel"))
	local bar = frame.ScrollBar
	if bar then
		if bar.SetInterpolateScroll then bar:SetInterpolateScroll(false) end
		Wheel(bar, bar:GetScript("OnMouseWheel"))
	end
	-- A page change, a focused search result or thumb drag takes precedence over
	-- an unfinished wheel gesture, even when it sets the existing scroll offset.
	hooksecurefunc(frame, "SetVerticalScroll", function()
		if not state.writing then Stop(state) end
	end)
	frame:HookScript("OnHide", function() Stop(state) end)
	frame:HookScript("OnScrollRangeChanged", function() Stop(state) end)
	frame:HookScript("OnSizeChanged", function() Stop(state) end)
end

function SettingsScroll:Refresh()
	for _, state in pairs(frames) do ApplyPreference(state) end
end
