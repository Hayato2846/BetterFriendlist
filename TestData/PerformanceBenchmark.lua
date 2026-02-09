-- TestData/PerformanceBenchmark.lua
-- Performance Benchmarking System for BetterFriendlist Testing
-- Version 1.0 - February 2026
--
-- Purpose:
-- Run structured performance benchmarks with baselines and thresholds.
-- Detect performance regressions through automated comparison.
--
-- Features:
-- - Define benchmarks with expected baselines
-- - Run benchmarks with configurable iterations
-- - Compare results against thresholds
-- - Store historical results for trend analysis
-- - Integration with existing PerformanceMonitor
--
-- Usage:
--   /bfl test bench list           - List available benchmarks
--   /bfl test bench run <name>     - Run specific benchmark
--   /bfl test bench all            - Run all benchmarks
--   /bfl test bench history        - Show benchmark history

local ADDON_NAME, BFL = ...

-- Ensure TestData namespace exists
BFL.TestData = BFL.TestData or {}

-- Create PerformanceBenchmark module
local PerformanceBenchmark = {}
BFL.PerformanceBenchmark = PerformanceBenchmark

-- ============================================
-- CONSTANTS
-- ============================================

local BENCHMARK_VERSION = 1
local MAX_HISTORY_ENTRIES = 20
local DEFAULT_ITERATIONS = 10
local DEFAULT_WARMUP = 2

-- Severity thresholds (percentage over baseline)
local THRESHOLD_WARNING = 20   -- 20% slower = warning
local THRESHOLD_FAIL = 50      -- 50% slower = fail

-- ============================================
-- STATE
-- ============================================

-- Registered benchmarks
PerformanceBenchmark.benchmarks = {}

-- Current run results
PerformanceBenchmark.currentResults = nil

-- Historical results (stored in SavedVariables)
PerformanceBenchmark.history = nil

-- ============================================
-- BENCHMARK DEFINITION
-- ============================================

--- Register a new benchmark
-- @param config table with fields:
--   id: string (REQUIRED) - Unique identifier
--   name: string - Display name
--   description: string - What it tests
--   category: string - Category (ui, data, render, etc.)
--   baseline: number - Expected time in ms (optional)
--   threshold: number - Max allowed time in ms (optional)
--   iterations: number - How many times to run (default: 10)
--   warmup: number - Warmup runs before measuring (default: 2)
--   setup: function - Called before benchmark (optional)
--   teardown: function - Called after benchmark (optional)
--   run: function (REQUIRED) - The actual benchmark code
function PerformanceBenchmark:RegisterBenchmark(config)
    if not config.id or not config.run then
        BFL:DebugPrint("|cffff0000PerformanceBenchmark:|r Invalid benchmark config (need id and run)")
        return false
    end
    
    local benchmark = {
        id = config.id,
        name = config.name or config.id,
        description = config.description or "",
        category = config.category or "general",
        baseline = config.baseline,
        threshold = config.threshold,
        iterations = config.iterations or DEFAULT_ITERATIONS,
        warmup = config.warmup or DEFAULT_WARMUP,
        setup = config.setup,
        teardown = config.teardown,
        run = config.run,
    }
    
    self.benchmarks[config.id] = benchmark
    return true
end

-- ============================================
-- BENCHMARK EXECUTION
-- ============================================

--[[
    Run a single benchmark
    @param benchmarkId string: Benchmark ID
    @param options table: Override options (iterations, etc.)
    @return table: Result {passed, time, iterations, ...}
]]
function PerformanceBenchmark:RunBenchmark(benchmarkId, options)
    local benchmark = self.benchmarks[benchmarkId]
    if not benchmark then
        return {error = "Benchmark not found: " .. tostring(benchmarkId)}
    end
    
    options = options or {}
    local iterations = options.iterations or benchmark.iterations
    local warmup = options.warmup or benchmark.warmup
    
    -- Setup
    if benchmark.setup then
        local success, err = pcall(benchmark.setup)
        if not success then
            return {error = "Setup failed: " .. tostring(err)}
        end
    end
    
    -- Warmup runs (not measured)
    for i = 1, warmup do
        pcall(benchmark.run)
    end
    
    -- Collect garbage before measuring
    collectgarbage("collect")
    
    -- Measured runs
    local times = {}
    local memBefore = collectgarbage("count")
    
    for i = 1, iterations do
        local startTime = debugprofilestop()
        local success, err = pcall(benchmark.run)
        local endTime = debugprofilestop()
        
        if success then
            table.insert(times, endTime - startTime)
        else
            -- Record error but continue
            BFL:DebugPrint("|cffff0000Benchmark error:|r " .. tostring(err))
        end
    end
    
    local memAfter = collectgarbage("count")
    
    -- Teardown
    if benchmark.teardown then
        pcall(benchmark.teardown)
    end
    
    -- Calculate statistics
    local result = self:CalculateStats(times)
    result.id = benchmarkId
    result.name = benchmark.name
    result.category = benchmark.category
    result.iterations = iterations
    result.baseline = benchmark.baseline
    result.threshold = benchmark.threshold
    result.memoryDelta = memAfter - memBefore
    result.timestamp = time()
    
    -- Determine pass/fail
    result.status = self:EvaluateResult(result)
    
    return result
end

--[[
    Calculate statistics from timing data
    @param times table: Array of timing values (ms)
    @return table: Statistics
]]
function PerformanceBenchmark:CalculateStats(times)
    if not times or #times == 0 then
        return {
            count = 0,
            total = 0,
            min = 0,
            max = 0,
            mean = 0,
            median = 0,
            stddev = 0,
        }
    end
    
    -- Sort for median
    local sorted = {}
    for _, v in ipairs(times) do
        table.insert(sorted, v)
    end
    table.sort(sorted)
    
    -- Basic stats
    local count = #times
    local total = 0
    local min = times[1]
    local max = times[1]
    
    for _, t in ipairs(times) do
        total = total + t
        if t < min then min = t end
        if t > max then max = t end
    end
    
    local mean = total / count
    
    -- Median
    local median
    if count % 2 == 0 then
        median = (sorted[count/2] + sorted[count/2 + 1]) / 2
    else
        median = sorted[math.ceil(count/2)]
    end
    
    -- Standard deviation
    local sumSqDiff = 0
    for _, t in ipairs(times) do
        sumSqDiff = sumSqDiff + (t - mean)^2
    end
    local stddev = math.sqrt(sumSqDiff / count)
    
    return {
        count = count,
        total = total,
        min = min,
        max = max,
        mean = mean,
        median = median,
        stddev = stddev,
        times = times,
    }
end

--[[
    Evaluate benchmark result against baseline/threshold
    @param result table: Benchmark result
    @return string: "pass", "warning", or "fail"
]]
function PerformanceBenchmark:EvaluateResult(result)
    -- If explicit threshold set, use it
    if result.threshold and result.mean > result.threshold then
        return "fail"
    end
    
    -- If baseline set, compare against it
    if result.baseline then
        local percentOver = ((result.mean - result.baseline) / result.baseline) * 100
        
        if percentOver > THRESHOLD_FAIL then
            return "fail"
        elseif percentOver > THRESHOLD_WARNING then
            return "warning"
        end
    end
    
    return "pass"
end

--[[
    Run all benchmarks
    @param options table: Options (category filter, etc.)
    @return table: Overall results
]]
function PerformanceBenchmark:RunAll(options)
    options = options or {}
    local categoryFilter = options.category
    
    local results = {
        timestamp = time(),
        benchmarks = {},
        passed = 0,
        warnings = 0,
        failed = 0,
        errors = 0,
        totalTime = 0,
    }
    
    local startTime = debugprofilestop()
    
    for id, benchmark in pairs(self.benchmarks) do
        -- Filter by category if specified
        if not categoryFilter or benchmark.category == categoryFilter then
            local result = self:RunBenchmark(id, options)
            results.benchmarks[id] = result
            
            if result.error then
                results.errors = results.errors + 1
            elseif result.status == "pass" then
                results.passed = results.passed + 1
            elseif result.status == "warning" then
                results.warnings = results.warnings + 1
            else
                results.failed = results.failed + 1
            end
        end
    end
    
    results.totalTime = debugprofilestop() - startTime
    
    self.currentResults = results
    self:SaveToHistory(results)
    
    return results
end

--[[
    Run benchmarks by category
    @param category string: Category name
    @return table: Results
]]
function PerformanceBenchmark:RunCategory(category)
    return self:RunAll({category = category})
end

-- ============================================
-- HISTORY MANAGEMENT
-- ============================================

--[[
    Get benchmark history from SavedVariables
    @return table: History entries
]]
function PerformanceBenchmark:GetHistory()
    if not BetterFriendlistDB then
        return {}
    end
    
    BetterFriendlistDB.benchmarkHistory = BetterFriendlistDB.benchmarkHistory or {}
    return BetterFriendlistDB.benchmarkHistory
end

--[[
    Save results to history
    @param results table: Benchmark results
]]
function PerformanceBenchmark:SaveToHistory(results)
    if not BetterFriendlistDB then return end
    
    BetterFriendlistDB.benchmarkHistory = BetterFriendlistDB.benchmarkHistory or {}
    local history = BetterFriendlistDB.benchmarkHistory
    
    -- Create summary for storage (don't store raw times)
    local summary = {
        timestamp = results.timestamp,
        passed = results.passed,
        warnings = results.warnings,
        failed = results.failed,
        errors = results.errors,
        totalTime = results.totalTime,
        benchmarks = {},
    }
    
    for id, result in pairs(results.benchmarks) do
        summary.benchmarks[id] = {
            mean = result.mean,
            median = result.median,
            min = result.min,
            max = result.max,
            status = result.status,
        }
    end
    
    table.insert(history, summary)
    
    -- Trim old entries
    while #history > MAX_HISTORY_ENTRIES do
        table.remove(history, 1)
    end
end

--[[
    Get historical trend for a specific benchmark
    @param benchmarkId string: Benchmark ID
    @param count number: How many history entries to include
    @return table: Array of {timestamp, mean, status}
]]
function PerformanceBenchmark:GetTrend(benchmarkId, count)
    local history = self:GetHistory()
    count = count or 10
    
    local trend = {}
    local start = math.max(1, #history - count + 1)
    
    for i = start, #history do
        local entry = history[i]
        if entry.benchmarks and entry.benchmarks[benchmarkId] then
            table.insert(trend, {
                timestamp = entry.timestamp,
                mean = entry.benchmarks[benchmarkId].mean,
                status = entry.benchmarks[benchmarkId].status,
            })
        end
    end
    
    return trend
end

--[[
    Compare current results with previous run
    @return table: Comparison data
]]
function PerformanceBenchmark:CompareWithPrevious()
    local history = self:GetHistory()
    if #history < 2 then
        return {error = "Need at least 2 history entries for comparison"}
    end
    
    local current = history[#history]
    local previous = history[#history - 1]
    
    local comparison = {
        currentTimestamp = current.timestamp,
        previousTimestamp = previous.timestamp,
        improvements = {},
        regressions = {},
        unchanged = {},
    }
    
    for id, currResult in pairs(current.benchmarks) do
        local prevResult = previous.benchmarks and previous.benchmarks[id]
        
        if prevResult then
            local percentChange = ((currResult.mean - prevResult.mean) / prevResult.mean) * 100
            
            local entry = {
                id = id,
                currentMean = currResult.mean,
                previousMean = prevResult.mean,
                percentChange = percentChange,
            }
            
            if percentChange < -10 then
                table.insert(comparison.improvements, entry)
            elseif percentChange > 10 then
                table.insert(comparison.regressions, entry)
            else
                table.insert(comparison.unchanged, entry)
            end
        end
    end
    
    return comparison
end

-- ============================================
-- BUILT-IN BENCHMARKS
-- ============================================

function PerformanceBenchmark:RegisterBuiltinBenchmarks()
    -- UI Rendering Benchmarks
    self:RegisterBenchmark({
        id = "render_friendlist",
        name = "Friend List Render",
        description = "Time to render the friends list with current data",
        category = "ui",
        baseline = 50,  -- 50ms expected
        threshold = 200, -- 200ms max
        iterations = 5,
        run = function()
            local FriendsList = BFL:GetModule("FriendsList")
            if FriendsList and FriendsList.RefreshUI then
                FriendsList:RefreshUI()
            end
        end,
    })
    
    self:RegisterBenchmark({
        id = "render_raidframe",
        name = "Raid Frame Render",
        description = "Time to update raid frame display",
        category = "ui",
        baseline = 30,
        iterations = 10,
        run = function()
            local RaidFrame = BFL:GetModule("RaidFrame")
            if RaidFrame and RaidFrame.UpdateDisplay then
                RaidFrame:UpdateDisplay()
            end
        end,
    })
    
    -- Data Processing Benchmarks
    self:RegisterBenchmark({
        id = "sort_friends_100",
        name = "Sort 100 Friends",
        description = "Time to sort friends list with 100 entries",
        category = "data",
        baseline = 5,
        iterations = 20,
        setup = function()
            -- Ensure we have mock data
            local MockDataProvider = BFL.MockDataProvider
            if MockDataProvider then
                local data = MockDataProvider:GenerateFriends(100, {
                    bnetRatio = 0.8,
                    onlineRatio = 0.5,
                })
                local PreviewMode = BFL:GetModule("PreviewMode")
                if PreviewMode then
                    PreviewMode.enabled = true
                    PreviewMode.mockData = PreviewMode.mockData or {}
                    PreviewMode.mockData.friends = data
                end
            end
        end,
        run = function()
            local FriendsList = BFL:GetModule("FriendsList")
            if FriendsList and FriendsList.SortFriends then
                FriendsList:SortFriends()
            end
        end,
        teardown = function()
            local PreviewMode = BFL:GetModule("PreviewMode")
            if PreviewMode then
                PreviewMode.enabled = false
            end
        end,
    })
    
    self:RegisterBenchmark({
        id = "sort_friends_500",
        name = "Sort 500 Friends",
        description = "Time to sort friends list with 500 entries (stress test)",
        category = "data",
        baseline = 25,
        threshold = 100,
        iterations = 10,
        setup = function()
            local MockDataProvider = BFL.MockDataProvider
            if MockDataProvider then
                local data = MockDataProvider:GenerateFriends(500, {
                    bnetRatio = 0.8,
                    onlineRatio = 0.5,
                })
                local PreviewMode = BFL:GetModule("PreviewMode")
                if PreviewMode then
                    PreviewMode.enabled = true
                    PreviewMode.mockData = PreviewMode.mockData or {}
                    PreviewMode.mockData.friends = data
                end
            end
        end,
        run = function()
            local FriendsList = BFL:GetModule("FriendsList")
            if FriendsList and FriendsList.SortFriends then
                FriendsList:SortFriends()
            end
        end,
        teardown = function()
            local PreviewMode = BFL:GetModule("PreviewMode")
            if PreviewMode then
                PreviewMode.enabled = false
            end
        end,
    })
    
    self:RegisterBenchmark({
        id = "filter_friends",
        name = "Filter Friends",
        description = "Time to apply filters to friends list",
        category = "data",
        baseline = 10,
        iterations = 20,
        run = function()
            local QuickFilters = BFL:GetModule("QuickFilters")
            if QuickFilters and QuickFilters.ApplyFilter then
                QuickFilters:ApplyFilter("online")
            end
        end,
    })
    
    -- Group Operations
    self:RegisterBenchmark({
        id = "group_assignment",
        name = "Group Assignment Lookup",
        description = "Time to look up group assignments for all friends",
        category = "data",
        baseline = 5,
        iterations = 50,
        run = function()
            local Groups = BFL:GetModule("Groups")
            if Groups and Groups.GetFriendGroup then
                -- Simulate looking up 100 friends
                for i = 1, 100 do
                    Groups:GetFriendGroup("TestFriend" .. i)
                end
            end
        end,
    })
    
    -- Event Handling
    self:RegisterBenchmark({
        id = "event_friendlist_update",
        name = "FRIENDLIST_UPDATE Event",
        description = "Time to process FRIENDLIST_UPDATE event",
        category = "events",
        baseline = 100,
        threshold = 500,
        iterations = 5,
        run = function()
            if BFL.FireEventCallbacks then
                BFL:FireEventCallbacks("FRIENDLIST_UPDATE")
            end
        end,
    })
    
    -- Mock Data Generation
    self:RegisterBenchmark({
        id = "generate_mock_100",
        name = "Generate 100 Mock Friends",
        description = "Time to generate 100 mock friends",
        category = "mock",
        baseline = 20,
        iterations = 10,
        run = function()
            local MockDataProvider = BFL.MockDataProvider
            if MockDataProvider then
                MockDataProvider:GenerateFriends(100)
            end
        end,
    })
    
    self:RegisterBenchmark({
        id = "generate_mock_500",
        name = "Generate 500 Mock Friends",
        description = "Time to generate 500 mock friends (stress)",
        category = "mock",
        baseline = 100,
        iterations = 5,
        run = function()
            local MockDataProvider = BFL.MockDataProvider
            if MockDataProvider then
                MockDataProvider:GenerateFriends(500)
            end
        end,
    })
    
    -- Memory Benchmarks
    self:RegisterBenchmark({
        id = "memory_snapshot",
        name = "State Snapshot Memory",
        description = "Memory impact of taking a state snapshot",
        category = "memory",
        baseline = 50,  -- KB
        iterations = 5,
        run = function()
            local StateValidator = BFL.StateValidator
            if StateValidator then
                StateValidator:TakeSnapshot("BenchmarkTest")
            end
        end,
    })
    
    -- Database Access
    self:RegisterBenchmark({
        id = "db_read_settings",
        name = "Read All Settings",
        description = "Time to read all settings from database",
        category = "data",
        baseline = 2,
        iterations = 50,
        run = function()
            local DB = BFL:GetModule("DB")
            if DB and DB.GetAllSettings then
                DB:GetAllSettings()
            elseif BetterFriendlistDB and BetterFriendlistDB.settings then
                -- Direct access fallback
                local _ = BetterFriendlistDB.settings
            end
        end,
    })
    
    BFL:DebugPrint("|cff00ff00PerformanceBenchmark:|r Registered " .. self:GetBenchmarkCount() .. " built-in benchmarks")
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

--[[
    Get count of registered benchmarks
    @return number: Count
]]
function PerformanceBenchmark:GetBenchmarkCount()
    local count = 0
    for _ in pairs(self.benchmarks) do
        count = count + 1
    end
    return count
end

--[[
    List all registered benchmarks
    @return table: Array of {id, name, category, description}
]]
function PerformanceBenchmark:ListBenchmarks()
    local list = {}
    
    for id, benchmark in pairs(self.benchmarks) do
        table.insert(list, {
            id = id,
            name = benchmark.name,
            category = benchmark.category,
            description = benchmark.description,
            baseline = benchmark.baseline,
        })
    end
    
    -- Sort by category then name
    table.sort(list, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end
        return a.name < b.name
    end)
    
    return list
end

--[[
    Get unique categories
    @return table: Array of category names
]]
function PerformanceBenchmark:GetCategories()
    local categories = {}
    local seen = {}
    
    for _, benchmark in pairs(self.benchmarks) do
        if not seen[benchmark.category] then
            table.insert(categories, benchmark.category)
            seen[benchmark.category] = true
        end
    end
    
    table.sort(categories)
    return categories
end

-- ============================================
-- REPORTING
-- ============================================

--[[
    Print single benchmark result
    @param result table: Benchmark result
]]
function PerformanceBenchmark:PrintResult(result)
    if result.error then
        print("|cffff0000ERROR:|r " .. result.error)
        return
    end
    
    local statusColor = result.status == "pass" and "|cff00ff00" or 
                       (result.status == "warning" and "|cffffff00" or "|cffff0000")
    local statusIcon = result.status == "pass" and "[+]" or 
                      (result.status == "warning" and "[!]" or "[x]")
    
    print(statusColor .. statusIcon .. "|r " .. result.name)
    print(string.format("    Mean: %.2fms | Median: %.2fms | StdDev: %.2fms", 
        result.mean, result.median, result.stddev))
    print(string.format("    Min: %.2fms | Max: %.2fms | Iterations: %d", 
        result.min, result.max, result.iterations))
    
    if result.baseline then
        local percentDiff = ((result.mean - result.baseline) / result.baseline) * 100
        local diffStr = percentDiff >= 0 and ("+" .. string.format("%.1f", percentDiff)) or string.format("%.1f", percentDiff)
        print(string.format("    Baseline: %.2fms (%s%%)", result.baseline, diffStr))
    end
    
    if result.memoryDelta > 0 then
        print(string.format("    Memory: +%.2f KB", result.memoryDelta))
    end
end

--[[
    Print all results from a run
    @param results table: RunAll results
]]
function PerformanceBenchmark:PrintResults(results)
    print("|cff00ff00=== Benchmark Results ===|r")
    print(string.format("Time: %s | Total: %.2fms", 
        date("%Y-%m-%d %H:%M:%S", results.timestamp), results.totalTime))
    print(string.format("Passed: |cff00ff00%d|r | Warnings: |cffffff00%d|r | Failed: |cffff0000%d|r | Errors: %d",
        results.passed, results.warnings, results.failed, results.errors))
    print("")
    
    -- Group by category
    local byCategory = {}
    for id, result in pairs(results.benchmarks) do
        local cat = result.category or "general"
        byCategory[cat] = byCategory[cat] or {}
        table.insert(byCategory[cat], result)
    end
    
    for category, benchmarks in pairs(byCategory) do
        print("|cffffd200[" .. category:upper() .. "]|r")
        for _, result in ipairs(benchmarks) do
            self:PrintResult(result)
        end
        print("")
    end
end

--[[
    Print benchmark list
]]
function PerformanceBenchmark:PrintBenchmarkList()
    local list = self:ListBenchmarks()
    local categories = self:GetCategories()
    
    print("|cff00ff00=== Available Benchmarks ===|r")
    print("Total: " .. #list .. " benchmarks in " .. #categories .. " categories")
    print("")
    
    for _, category in ipairs(categories) do
        print("|cffffd200[" .. category:upper() .. "]|r")
        for _, bench in ipairs(list) do
            if bench.category == category then
                local baselineStr = bench.baseline and string.format(" (baseline: %.1fms)", bench.baseline) or ""
                print("  * |cffffffff" .. bench.id .. "|r - " .. bench.description .. baselineStr)
            end
        end
    end
end

--[[
    Print comparison with previous run
    @param comparison table: Comparison data
]]
function PerformanceBenchmark:PrintComparison(comparison)
    if comparison.error then
        print("|cffff0000" .. comparison.error .. "|r")
        return
    end
    
    print("|cff00ff00=== Benchmark Comparison ===|r")
    print("Previous: " .. date("%Y-%m-%d %H:%M", comparison.previousTimestamp))
    print("Current:  " .. date("%Y-%m-%d %H:%M", comparison.currentTimestamp))
    print("")
    
    if #comparison.regressions > 0 then
        print("|cffff0000Regressions:|r")
        for _, entry in ipairs(comparison.regressions) do
            print(string.format("  * %s: %.2fms -> %.2fms (+%.1f%%)", 
                entry.id, entry.previousMean, entry.currentMean, entry.percentChange))
        end
        print("")
    end
    
    if #comparison.improvements > 0 then
        print("|cff00ff00Improvements:|r")
        for _, entry in ipairs(comparison.improvements) do
            print(string.format("  * %s: %.2fms -> %.2fms (%.1f%%)", 
                entry.id, entry.previousMean, entry.currentMean, entry.percentChange))
        end
        print("")
    end
    
    print("|cff888888Unchanged: " .. #comparison.unchanged .. " benchmarks|r")
end

--[[
    Print history summary
]]
function PerformanceBenchmark:PrintHistory()
    local history = self:GetHistory()
    
    if #history == 0 then
        print("|cff888888No benchmark history available.|r")
        return
    end
    
    print("|cff00ff00=== Benchmark History ===|r")
    print("Entries: " .. #history .. "/" .. MAX_HISTORY_ENTRIES)
    print("")
    
    for i, entry in ipairs(history) do
        local statusStr = string.format("|cff00ff00%d|r/|cffffff00%d|r/|cffff0000%d|r",
            entry.passed, entry.warnings, entry.failed)
        print(string.format("%2d. %s - %s (%.1fms)", 
            i, date("%m-%d %H:%M", entry.timestamp), statusStr, entry.totalTime))
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

--[[
    Initialize the benchmark system
]]
function PerformanceBenchmark:Initialize()
    self:RegisterBuiltinBenchmarks()
end

--[[
    Reset everything
]]
function PerformanceBenchmark:Reset()
    self.currentResults = nil
    BFL:DebugPrint("|cff00ff00PerformanceBenchmark:|r Reset complete")
end

--[[
    Clear history
]]
function PerformanceBenchmark:ClearHistory()
    if BetterFriendlistDB then
        BetterFriendlistDB.benchmarkHistory = {}
    end
    BFL:DebugPrint("|cff00ff00PerformanceBenchmark:|r History cleared")
end

-- Auto-initialize when loaded
PerformanceBenchmark:Initialize()

return PerformanceBenchmark
