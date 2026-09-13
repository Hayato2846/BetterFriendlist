-- Utils/TimerCompat.lua
-- Keyed debounce scheduling with a 12.1.5 TimedSignalMap fast path.

local ADDON_NAME, BFL = ...

local TimerCompat = {}
BFL.TimerCompat = TimerCompat

local KeyedDebouncerMixin = {}

local function GetTimerAPI()
	if TimerCompat._testAPI ~= nil then
		return TimerCompat._testAPI or nil
	end
	return C_Timer
end

function TimerCompat.CanUseTimedSignalMap()
	local api = GetTimerAPI()
	return api ~= nil and type(api.NewTimedSignalMap) == "function"
end

function KeyedDebouncerMixin:Dispatch(key)
	self.pending[key] = nil
	self.callback(key)
end

function KeyedDebouncerMixin:DisableSignalMap()
	self.signalMap = nil
	self.usesTimedSignalMap = false
end

function KeyedDebouncerMixin:Schedule(key, delay)
	if type(key) ~= "number" then
		return false
	end
	delay = math.max(0, tonumber(delay) or 0)

	if self.signalMap then
		local ok = pcall(self.signalMap.SignalAfter, self.signalMap, key, delay)
		if ok then
			return true
		end
		self:DisableSignalMap()
	end

	local generation = (self.generations[key] or 0) + 1
	self.generations[key] = generation
	self.pending[key] = true
	local api = GetTimerAPI()
	if api and type(api.After) == "function" then
		api.After(delay, function()
			if self.generations[key] == generation and self.pending[key] then
				self:Dispatch(key)
			end
		end)
	else
		self:Dispatch(key)
	end
	return false
end

function KeyedDebouncerMixin:Cancel(key)
	if type(key) ~= "number" then
		return false
	end
	self.generations[key] = (self.generations[key] or 0) + 1
	self.pending[key] = nil
	if self.signalMap then
		local ok = pcall(self.signalMap.CancelSignal, self.signalMap, key)
		if not ok then
			self:DisableSignalMap()
		end
		return ok
	end
	return true
end

function KeyedDebouncerMixin:IsPending(key)
	if self.signalMap and type(self.signalMap.HasSignal) == "function" then
		local ok, result = pcall(self.signalMap.HasSignal, self.signalMap, key)
		if ok then
			return result == true
		end
		self:DisableSignalMap()
	end
	return self.pending[key] == true
end

function KeyedDebouncerMixin:UsesTimedSignalMap()
	return self.usesTimedSignalMap == true
end

function TimerCompat.CreateKeyedDebouncer(callback)
	assert(type(callback) == "function", "callback must be a function")
	local debouncer = setmetatable({
		callback = callback,
		generations = {},
		pending = {},
		usesTimedSignalMap = false,
	}, { __index = KeyedDebouncerMixin })

	if TimerCompat.CanUseTimedSignalMap() then
		local api = GetTimerAPI()
		local ok, signalMap = pcall(api.NewTimedSignalMap, function(key)
			debouncer:Dispatch(key)
		end)
		if ok and signalMap and type(signalMap.SignalAfter) == "function" then
			debouncer.signalMap = signalMap
			debouncer.usesTimedSignalMap = true
		end
	end
	return debouncer
end

return TimerCompat
