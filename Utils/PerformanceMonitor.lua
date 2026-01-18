--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua"); --[[
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
function PerformanceMonitor:Start(operation) Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:Start file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:40:0");
	self.activeTimers[operation] = debugprofilestop()
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Start file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:40:0"); end

--[[
	Stop timing an operation and record statistics
]]
function PerformanceMonitor:Stop(operation) Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:Stop file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:47:0");
	local startTime = self.activeTimers[operation]
	if not startTime then Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Stop file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:47:0"); return end
	
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
		print(string.format("|cffff0000[Performance Warning]|r %s took %.2f ms (threshold: 50ms)", operation, elapsed))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Stop file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:47:0"); end

--[[
	Record a single measurement without start/stop
]]
function PerformanceMonitor:Record(operation, elapsedTime) Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:Record file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:76:0");
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
		print(string.format("|cffff0000[Performance Warning]|r %s took %.2f ms (threshold: 50ms)", operation, elapsedTime))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Record file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:76:0"); end

--[[
	Sample current memory usage
]]
function PerformanceMonitor:SampleMemory() Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:SampleMemory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:96:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:SampleMemory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:96:0"); end

--[[
	Get average time for an operation
]]
function PerformanceMonitor:GetAverage(operation) Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:GetAverage file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:116:0");
	local stat = self.stats[operation]
	if not stat or stat.count == 0 then Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:GetAverage file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:116:0"); return 0 end
	return Perfy_Trace_Passthrough("Leave", "PerformanceMonitor:GetAverage file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:116:0", stat.totalTime / stat.count)
end

--[[
	Reset all statistics
]]
function PerformanceMonitor:Reset() Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:Reset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:125:0");
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
	print(BFL.L.PERF_HEADER_PREFIX .. " " .. BFL.L.PERF_STATS_RESET)
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Reset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:125:0"); end

--[[
	Print performance report
]]
function PerformanceMonitor:Report() Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:Report file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:142:0");
	print(BFL.L.PERF_REPORT_HEADER)
	print("")
	
	-- QuickJoin operations
	print(BFL.L.PERF_QJ_OPS)
	self:PrintOperation("quickjoin_update", "Update()")
	self:PrintOperation("quickjoin_getgroupinfo", "GetGroupInfo()")
	self:PrintOperation("quickjoin_getentries", "GetEntries()")
	self:PrintOperation("quickjoin_applytoframe", "ApplyToFrame()")
	print("")
	
	-- Friends List operations (for comparison)
	print(BFL.L.PERF_FRIENDS_OPS)
	self:PrintOperation("friendslist_update", "UpdateDisplay()")
	print("")
	
	-- Memory usage
	print(BFL.L.PERF_MEMORY)
	UpdateAddOnMemoryUsage()
	local currentMemory = GetAddOnMemoryUsage("BetterFriendlist") or 0
	print(string.format("  Current: %.2f KB", currentMemory))
	print(string.format("  Peak: %.2f KB", self.stats.memory_max))
	
	if #self.stats.memory_samples > 0 then
		local totalMemory = 0
		for _, sample in ipairs(self.stats.memory_samples) do
			totalMemory = totalMemory + sample.memory
		end
		local sampleCount = #self.stats.memory_samples
		if sampleCount > 0 then
			local avgMemory = totalMemory / sampleCount
			print(string.format("  Average (last %d samples): %.2f KB", sampleCount, avgMemory))
		end
	end
	print("")
	
	-- Performance targets
	print(BFL.L.PERF_TARGETS)
	print(BFL.L.PERF_FPS_60)
	print(BFL.L.PERF_FPS_30)
	print(BFL.L.PERF_WARNING)
	print("")
	
	-- Overall assessment
	local quickJoinAvg = self:GetAverage("quickjoin_update")
	if quickJoinAvg and quickJoinAvg > 0 then
		local fps = 1000 / quickJoinAvg
		local status = quickJoinAvg < 16.6 and "|cff00ff00EXCELLENT|r" 
			or quickJoinAvg < 33.3 and "|cffffff00GOOD|r"
			or quickJoinAvg < 50 and "|cffffaa00OK|r"
			or "|cffff0000NEEDS OPTIMIZATION|r"
		
		print(string.format("|cffffd700Overall Assessment:|r %s (%.1f FPS)", status, fps))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:Report file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:142:0"); end

--[[
	Print single operation statistics
]]
function PerformanceMonitor:PrintOperation(operation, displayName) Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:PrintOperation file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:202:0");
	local stat = self.stats[operation]
	if not stat or stat.count == 0 then
		print(string.format("  %s: No data", displayName))
		Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:PrintOperation file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:202:0"); return
	end
	
	if stat.count == 0 then Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:PrintOperation file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:202:0"); return end
	local avg = stat.totalTime / stat.count
	local status = avg < 16.6 and "✓" or avg < 50 and "⚠" or "✗"
	
	print(string.format("  %s %s:", status, displayName))
	print(string.format("    Calls: %d", stat.count))
	print(string.format("    Avg: %.2f ms", avg))
	print(string.format("    Min: %.2f ms", stat.minTime == math.huge and 0 or stat.minTime))
	print(string.format("    Max: %.2f ms", stat.maxTime))
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:PrintOperation file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:202:0"); end

--[[
	Enable automatic performance monitoring
]]
function PerformanceMonitor:EnableAutoMonitoring() Perfy_Trace(Perfy_GetTime(), "Enter", "PerformanceMonitor:EnableAutoMonitoring file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:223:0");
	-- Hook into QuickJoin:Update
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin then
		local originalUpdate = QuickJoin.Update
		QuickJoin.Update = function(self, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickJoin.Update file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:228:21");
			PerformanceMonitor:Start("quickjoin_update")
			local result = originalUpdate(self, ...)
			PerformanceMonitor:Stop("quickjoin_update")
			Perfy_Trace(Perfy_GetTime(), "Leave", "QuickJoin.Update file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:228:21"); return result
		end
		
		local originalGetGroupInfo = QuickJoin.GetGroupInfo
		QuickJoin.GetGroupInfo = function(self, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickJoin.GetGroupInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:236:27");
			PerformanceMonitor:Start("quickjoin_getgroupinfo")
			local result = originalGetGroupInfo(self, ...)
			PerformanceMonitor:Stop("quickjoin_getgroupinfo")
			Perfy_Trace(Perfy_GetTime(), "Leave", "QuickJoin.GetGroupInfo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:236:27"); return result
		end
		
		local originalGetEntries = QuickJoin.GetEntries
		QuickJoin.GetEntries = function(self, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickJoin.GetEntries file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:244:25");
			PerformanceMonitor:Start("quickjoin_getentries")
			local result = originalGetEntries(self, ...)
			PerformanceMonitor:Stop("quickjoin_getentries")
			Perfy_Trace(Perfy_GetTime(), "Leave", "QuickJoin.GetEntries file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:244:25"); return result
		end
	end
	
	-- Memory sampling timer
	C_Timer.NewTicker(5, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:253:22");
		PerformanceMonitor:SampleMemory()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:253:22"); end)
	
	print(BFL.L.PERF_HEADER_PREFIX .. " " .. BFL.L.PERF_AUTO_ENABLED)
Perfy_Trace(Perfy_GetTime(), "Leave", "PerformanceMonitor:EnableAutoMonitoring file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:223:0"); end

-- Legacy slash command (redirects to /bfl perf)
-- Kept for backwards compatibility
SLASH_BFLPERF1 = "/bflperf"
SlashCmdList["BFLPERF"] = function(msg) Perfy_Trace(Perfy_GetTime(), "Enter", "SlashCmdList.BFLPERF file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:263:26");
	-- Redirect to main /bfl command
	local cmd = msg and msg:lower():trim() or ""
	if cmd == "" then cmd = "report" end
	SlashCmdList["BETTERFRIENDLIST"]("perf " .. cmd)
Perfy_Trace(Perfy_GetTime(), "Leave", "SlashCmdList.BFLPERF file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua:263:26"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/PerformanceMonitor.lua");