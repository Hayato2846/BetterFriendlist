--[[
	Performance Monitor Utility
	
	Provides performance profiling for BetterFriendlist operations.
	
	Usage:
	/bfl perf - Show performance statistics
	/bfl perf reset - Reset statistics
	/bfl perf start <operation> - Start timing operation
	/bfl perf stop <operation> - Stop timing operation
]]

local addonName, BFL = ...

local PerformanceMonitor = {}
BFL.PerformanceMonitor = PerformanceMonitor

-- Statistics storage
PerformanceMonitor.stats = {
	-- QuickJoin operations
	quickjoin_update = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge },
	quickjoin_getgroupinfo = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge },
	quickjoin_getentries = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge },
	quickjoin_applytoframe = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge },
	
	-- Friends List operations (for comparison)
	friendslist_update = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge },
	
	-- Memory tracking
	memory_samples = {},
	memory_max = 0,
}

-- Active timers
PerformanceMonitor.activeTimers = {}

--[[
	Start timing an operation
]]
function PerformanceMonitor:Start(operation)
	self.activeTimers[operation] = debugprofilestop()
end

--[[
	Stop timing an operation and record statistics
]]
function PerformanceMonitor:Stop(operation)
	local startTime = self.activeTimers[operation]
	if not startTime then return end
	
	local elapsed = debugprofilestop() - startTime
	self.activeTimers[operation] = nil
	
	-- Get or create stat entry
	local stat = self.stats[operation]
	if not stat then
		stat = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge }
		self.stats[operation] = stat
	end
	
	-- Update statistics
	stat.count = stat.count + 1
	stat.totalTime = stat.totalTime + elapsed
	stat.maxTime = math.max(stat.maxTime, elapsed)
	stat.minTime = math.min(stat.minTime, elapsed)
	
	-- Warn if operation is slow
	if elapsed > 50 then -- 50ms threshold (= 20 FPS)
		BFL:DebugPrint(string.format("[Performance Warning] %s took %.2f ms (threshold: 50ms)", operation, elapsed))
	end
end

--[[
	Record a single measurement without start/stop
]]
function PerformanceMonitor:Record(operation, elapsedTime)
	local stat = self.stats[operation]
	if not stat then
		stat = { count = 0, totalTime = 0, maxTime = 0, minTime = math.huge }
		self.stats[operation] = stat
	end
	
	stat.count = stat.count + 1
	stat.totalTime = stat.totalTime + elapsedTime
	stat.maxTime = math.max(stat.maxTime, elapsedTime)
	stat.minTime = math.min(stat.minTime, elapsedTime)
	
	if elapsedTime > 50 then
		BFL:DebugPrint(string.format("[Performance Warning] %s took %.2f ms (threshold: 50ms)", operation, elapsedTime))
	end
end

--[[
	Sample current memory usage
]]
function PerformanceMonitor:SampleMemory()
	UpdateAddOnMemoryUsage()
	local memory = GetAddOnMemoryUsage("BetterFriendlist") or 0
	
	table.insert(self.stats.memory_samples, {
		time = GetTime(),
		memory = memory
	})
	
	self.stats.memory_max = math.max(self.stats.memory_max, memory)
	
	-- Keep only last 100 samples
	if #self.stats.memory_samples > 100 then
		table.remove(self.stats.memory_samples, 1)
	end
end

--[[
	Get average time for an operation
]]
function PerformanceMonitor:GetAverage(operation)
	local stat = self.stats[operation]
	if not stat or stat.count == 0 then return 0 end
	return stat.totalTime / stat.count
end

--[[
	Reset all statistics
]]
function PerformanceMonitor:Reset()
	for operation, stat in pairs(self.stats) do
		if type(stat) == "table" and stat.count then
			stat.count = 0
			stat.totalTime = 0
			stat.maxTime = 0
			stat.minTime = math.huge
		end
	end
	self.stats.memory_samples = {}
	self.stats.memory_max = 0
	BFL:DebugPrint(BFL.L.PERF_HEADER_PREFIX .. " " .. BFL.L.PERF_STATS_RESET)
end

--[[
	Print performance report
]]
function PerformanceMonitor:Report()
	BFL:DebugPrint(BFL.L.PERF_REPORT_HEADER)
	BFL:DebugPrint("")
	
	-- QuickJoin operations
	BFL:DebugPrint(BFL.L.PERF_QJ_OPS)
	self:PrintOperation("quickjoin_update", "Update()")
	self:PrintOperation("quickjoin_getgroupinfo", "GetGroupInfo()")
	self:PrintOperation("quickjoin_getentries", "GetEntries()")
	self:PrintOperation("quickjoin_applytoframe", "ApplyToFrame()")
	BFL:DebugPrint("")
	
	-- Friends List operations (for comparison)
	BFL:DebugPrint(BFL.L.PERF_FRIENDS_OPS)
	self:PrintOperation("friendslist_update", "UpdateDisplay()")
	BFL:DebugPrint("")
	
	-- Memory usage
	BFL:DebugPrint(BFL.L.PERF_MEMORY)
	UpdateAddOnMemoryUsage()
	local currentMemory = GetAddOnMemoryUsage("BetterFriendlist") or 0
	BFL:DebugPrint(string.format("  Current: %.2f KB", currentMemory))
	BFL:DebugPrint(string.format("  Peak: %.2f KB", self.stats.memory_max))
	
	if #self.stats.memory_samples > 0 then
		local totalMemory = 0
		for _, sample in ipairs(self.stats.memory_samples) do
			totalMemory = totalMemory + sample.memory
		end
		local sampleCount = #self.stats.memory_samples
		if sampleCount > 0 then
			local avgMemory = totalMemory / sampleCount
			BFL:DebugPrint(string.format("  Average (last %d samples): %.2f KB", sampleCount, avgMemory))
		end
	end
	BFL:DebugPrint("")
	
	-- Performance targets
	BFL:DebugPrint(BFL.L.PERF_TARGETS)
	BFL:DebugPrint(BFL.L.PERF_FPS_60)
	BFL:DebugPrint(BFL.L.PERF_FPS_30)
	BFL:DebugPrint(BFL.L.PERF_WARNING)
	BFL:DebugPrint("")
	
	-- Overall assessment
	local quickJoinAvg = self:GetAverage("quickjoin_update")
	if quickJoinAvg and quickJoinAvg > 0 then
		local fps = 1000 / quickJoinAvg
		local status = quickJoinAvg < 16.6 and "|cff00ff00EXCELLENT|r" 
			or quickJoinAvg < 33.3 and "|cffffff00GOOD|r"
			or quickJoinAvg < 50 and "|cffffaa00OK|r"
			or "|cffff0000NEEDS OPTIMIZATION|r"
		
		BFL:DebugPrint(string.format("Overall Assessment: %s (%.1f FPS)", status, fps))
	end
end

--[[
	Print single operation statistics
]]
function PerformanceMonitor:PrintOperation(operation, displayName)
	local stat = self.stats[operation]
	if not stat or stat.count == 0 then
		BFL:DebugPrint(string.format("  %s: No data", displayName))
		return
	end
	
	if stat.count == 0 then return end
	local avg = stat.totalTime / stat.count
	local status = avg < 16.6 and "✓" or avg < 50 and "⚠" or "✗"
	
	BFL:DebugPrint(string.format("  %s %s:", status, displayName))
	BFL:DebugPrint(string.format("    Calls: %d", stat.count))
	BFL:DebugPrint(string.format("    Avg: %.2f ms", avg))
	BFL:DebugPrint(string.format("    Min: %.2f ms", stat.minTime == math.huge and 0 or stat.minTime))
	BFL:DebugPrint(string.format("    Max: %.2f ms", stat.maxTime))
end

--[[
	Enable automatic performance monitoring
]]
function PerformanceMonitor:EnableAutoMonitoring()
	-- Hook into QuickJoin:Update
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin then
		local originalUpdate = QuickJoin.Update
		QuickJoin.Update = function(self, ...)
			PerformanceMonitor:Start("quickjoin_update")
			local result = originalUpdate(self, ...)
			PerformanceMonitor:Stop("quickjoin_update")
			return result
		end
		
		local originalGetGroupInfo = QuickJoin.GetGroupInfo
		QuickJoin.GetGroupInfo = function(self, ...)
			PerformanceMonitor:Start("quickjoin_getgroupinfo")
			local result = originalGetGroupInfo(self, ...)
			PerformanceMonitor:Stop("quickjoin_getgroupinfo")
			return result
		end
		
		local originalGetEntries = QuickJoin.GetEntries
		QuickJoin.GetEntries = function(self, ...)
			PerformanceMonitor:Start("quickjoin_getentries")
			local result = originalGetEntries(self, ...)
			PerformanceMonitor:Stop("quickjoin_getentries")
			return result
		end
	end
	
	-- Memory sampling timer
	if self.memorySampleTicker then
		self.memorySampleTicker:Cancel()
		self.memorySampleTicker = nil
	end

	self.memorySampleTicker = C_Timer.NewTicker(5, function()
		PerformanceMonitor:SampleMemory()
	end)
	
	BFL:DebugPrint(BFL.L.PERF_HEADER_PREFIX .. " " .. BFL.L.PERF_AUTO_ENABLED)
end

-- Legacy slash command (redirects to /bfl perf)
-- Kept for backwards compatibility
SLASH_BFLPERF1 = "/bflperf"
SlashCmdList["BFLPERF"] = function(msg)
	-- Redirect to main /bfl command
	local cmd = msg and msg:lower():trim() or ""
	if cmd == "" then cmd = "report" end
	SlashCmdList["BETTERFRIENDLIST"]("perf " .. cmd)
end
