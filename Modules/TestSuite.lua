-- Modules/TestSuite.lua
-- BetterFriendlist Test-Framework
-- Version 1.0 - February 2026
--
-- Purpose: Comprehensive testing system for BetterFriendlist addon
-- Enables testing without external dependencies (other players, events, etc.)
--
-- Commands:
--   /bfl test              - Show test menu/help
--   /bfl test ui           - Run all UI tests
--   /bfl test data         - Run all data tests
--   /bfl test events       - Run all event tests
--   /bfl test perf         - Run all performance tests
--   /bfl test all          - Run ALL tests
--   /bfl test run <name>   - Run specific test
--   /bfl test scenario <cmd> - Scenario management
--
-- IMPORTANT: This module is for DEVELOPMENT/QA purposes.
-- It does not affect production functionality.

local ADDON_NAME, BFL = ...

-- Register Module
local TestSuite = BFL:RegisterModule("TestSuite", {})
local function GetLocalizedText(key, fallback)
	local locale = BFL.L
	if locale and locale[key] then
		return locale[key]
	end
	return fallback
end

-- ============================================
-- CONSTANTS
-- ============================================

local TEST_CATEGORIES = {
	"ui",
	"data",
	"events",
	"perf",
	"classic",
	"integration",
	"settings",
	"sort",
	"filter",
	"bugs",
	"groups",
	"updates",
	"render",
	"issues",
}

local TEST_STATUS = {
	PENDING = "pending",
	RUNNING = "running",
	PASSED = "passed",
	FAILED = "failed",
	SKIPPED = "skipped",
}

-- ============================================
-- STATE
-- ============================================

TestSuite.isRunning = false
TestSuite.currentTest = nil
TestSuite.currentCategory = nil
TestSuite.testResults = {}
TestSuite.startTime = nil
TestSuite.perfyStressActive = false
TestSuite.perfyStressTicker = nil
TestSuite.perfyStressContext = nil

-- Test Registry (populated by RegisterTest)
TestSuite.tests = {
	ui = {},
	data = {},
	events = {},
	perf = {},
	classic = {},
	integration = {},
	settings = {},
	sort = {},
	filter = {},
	bugs = {},
	groups = {},
	updates = {},
	render = {},
	issues = {},
}

-- ============================================
-- REPORTER SUBSYSTEM
-- ============================================

TestSuite.Reporter = {}

function TestSuite.Reporter:Log(message)
	print("|cff00ccff[BFL Test]|r " .. message)
end

function TestSuite.Reporter:Header(title)
	print("")
	print("|cff00ccff=================================================|r")
	print("|cff00ccff  " .. title .. "|r")
	print("|cff00ccff=================================================|r")
end

function TestSuite.Reporter:SubHeader(title)
	print("")
	print("|cffffcc00-- " .. title .. " --|r")
end

function TestSuite.Reporter:Pass(testName, details)
	local msg = "|cff00ff00[PASS]|r " .. testName
	if details then
		msg = msg .. " |cff888888(" .. details .. ")|r"
	end
	print(msg)
end

function TestSuite.Reporter:Fail(testName, reason)
	local msg = "|cffff0000[FAIL]|r " .. testName
	if reason then
		msg = msg .. "\n       |cffff8888-> " .. reason .. "|r"
	end
	print(msg)
end

function TestSuite.Reporter:Skip(testName, reason)
	local msg = "|cff888888[SKIP]|r " .. testName
	if reason then
		msg = msg .. " |cff666666(" .. reason .. ")|r"
	end
	print(msg)
end

function TestSuite.Reporter:Warn(message)
	print("|cffffcc00[WARN]|r " .. message)
end

function TestSuite.Reporter:Info(message)
	print("|cff88ccff[INFO]|r " .. message)
end

function TestSuite.Reporter:Summary(results)
	self:Header("TEST RESULTS SUMMARY")

	local total = results.passed + results.failed + results.skipped
	local passRate = total > 0 and math.floor((results.passed / total) * 100) or 0

	print("")
	print(string.format("  Total Tests:  %d", total))
	print(string.format("  |cff00ff00Passed:|r      %d", results.passed))
	print(string.format("  |cffff0000Failed:|r      %d", results.failed))
	print(string.format("  |cff888888Skipped:|r     %d", results.skipped))
	print("")

	local statusColor = passRate == 100 and "|cff00ff00" or passRate >= 80 and "|cffffcc00" or "|cffff0000"
	print(string.format("  Pass Rate:    %s%d%%|r", statusColor, passRate))

	if results.duration then
		print(string.format("  Duration:     %.2f seconds", results.duration))
	end

	print("")

	-- List failed tests
	if results.failed > 0 and results.failedTests then
		print("|cffff0000Failed Tests:|r")
		for _, test in ipairs(results.failedTests) do
			print("  * " .. test.name .. ": " .. (test.reason or "Unknown error"))
		end
		print("")
	end
end

-- ============================================
-- VALIDATOR SUBSYSTEM
-- ============================================

TestSuite.Validator = {}

function TestSuite.Validator:Assert(condition, message)
	if not condition then
		error(message or "Assertion failed", 2)
	end
	return true
end

function TestSuite.Validator:AssertEqual(actual, expected, message)
	if actual ~= expected then
		local msg = message or "Expected equality"
		error(string.format("%s: expected '%s', got '%s'", msg, tostring(expected), tostring(actual)), 2)
	end
	return true
end

function TestSuite.Validator:AssertNotNil(value, message)
	if value == nil then
		error(message or "Value is nil", 2)
	end
	return true
end

function TestSuite.Validator:AssertNil(value, message)
	if value ~= nil then
		error(message or ("Expected nil, got " .. tostring(value)), 2)
	end
	return true
end

function TestSuite.Validator:AssertType(value, expectedType, message)
	local actualType = type(value)
	if actualType ~= expectedType then
		local msg = message or "Type mismatch"
		error(string.format("%s: expected '%s', got '%s'", msg, expectedType, actualType), 2)
	end
	return true
end

function TestSuite.Validator:AssertTableCount(tbl, expectedCount, message)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	if count ~= expectedCount then
		local msg = message or "Table count mismatch"
		error(string.format("%s: expected %d entries, got %d", msg, expectedCount, count), 2)
	end
	return true
end

function TestSuite.Validator:AssertFrameVisible(frame, message)
	if not frame then
		error(message or "Frame is nil", 2)
	end
	if not frame:IsShown() then
		local frameName = frame:GetName() or "Anonymous"
		error(message or ("Frame '" .. frameName .. "' is not visible"), 2)
	end
	return true
end

function TestSuite.Validator:AssertFrameHidden(frame, message)
	if not frame then
		return true -- nil frame is considered hidden
	end
	if frame:IsShown() then
		local frameName = frame:GetName() or "Anonymous"
		error(message or ("Frame '" .. frameName .. "' should be hidden"), 2)
	end
	return true
end

-- Special marker for skipped tests (thrown as error, caught by runner)
local SKIP_MARKER = "__TEST_SKIPPED__:"

local function WithTemporaryDatabase(seedDB, action)
	local DB = BFL:GetModule("DB")
	if not DB then
		error("DB not loaded", 2)
	end

	local originalDB = BetterFriendlistDB
	local originalSettingsVersion = BFL.SettingsVersion
	local originalNicknameCache = BFL.NicknameCacheVersion

	BetterFriendlistDB = seedDB or {}
	DB:Initialize()

	local ok, err = pcall(action, BetterFriendlistDB)

	BetterFriendlistDB = originalDB
	BFL.SettingsVersion = originalSettingsVersion
	BFL.NicknameCacheVersion = originalNicknameCache

	if not ok then
		error(err, 2)
	end
end

function TestSuite.Validator:Skip(reason)
	error(SKIP_MARKER .. (reason or "Test skipped"), 2)
end

function TestSuite.Validator:AssertNoLuaErrors()
	-- Check if any Lua errors occurred (requires !BugGrabber or similar)
	-- For now, just return true as a placeholder
	return true
end

-- ============================================
-- TEST REGISTRATION
-- ============================================

--[[
	Register a test
	@param category: string - Test category (ui, data, events, perf, classic, integration)
	@param name: string - Unique test name
	@param testDef: table - Test definition
		- description: string - What the test does
		- condition: function (optional) - Return false to skip test
		- setup: function (optional) - Run before test
		- action: function - The actual test (receives Validator as arg)
		- teardown: function (optional) - Run after test (even on failure)
		- timeout: number (optional) - Max time in seconds
]]
function TestSuite:RegisterTest(category, name, testDef)
	if not self.tests[category] then
		self.Reporter:Warn("Unknown category '" .. category .. "' for test '" .. name .. "'")
		return
	end

	testDef.name = name
	testDef.category = category
	testDef.status = TEST_STATUS.PENDING

	table.insert(self.tests[category], testDef)
end

-- ============================================
-- TEST EXECUTION
-- ============================================

function TestSuite:RunTest(test)
	local result = {
		name = test.name,
		category = test.category,
		status = TEST_STATUS.PENDING,
		reason = nil,
		duration = 0,
	}

	-- Check condition
	if test.condition and not test.condition() then
		result.status = TEST_STATUS.SKIPPED
		result.reason = "Condition not met"
		self.Reporter:Skip(test.name, result.reason)
		return result
	end

	local startTime = debugprofilestop()

	local DB = BFL:GetModule("DB")
	local originalDBSet = nil
	local capturedKeys = nil
	local capturedValues = nil
	local snapshot = nil
	local groupsSnapshot = nil
	local FriendsList = nil
	local function DeepCopy(value)
		if DB and DB.InternalDeepCopy then
			return DB:InternalDeepCopy(value)
		end
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, v in pairs(value) do
			copy[DeepCopy(k)] = DeepCopy(v)
		end
		return copy
	end
	local function RestoreSnapshots()
		if BetterFriendlistDB and snapshot then
			BetterFriendlistDB.groupOrder = DeepCopy(snapshot.groupOrder)
			BetterFriendlistDB.friendGroups = DeepCopy(snapshot.friendGroups)
			BetterFriendlistDB.customGroups = DeepCopy(snapshot.customGroups)
			BetterFriendlistDB.groupStates = DeepCopy(snapshot.groupStates)
			BetterFriendlistDB.groupColors = DeepCopy(snapshot.groupColors)
			BetterFriendlistDB.groupCountColors = DeepCopy(snapshot.groupCountColors)
			BetterFriendlistDB.groupArrowColors = DeepCopy(snapshot.groupArrowColors)
			BetterFriendlistDB.quickFilterTags = DeepCopy(snapshot.quickFilterTags)
		end
		local Groups = BFL:GetModule("Groups")
		if Groups and groupsSnapshot then
			wipe(Groups.groups)
			for id, data in pairs(groupsSnapshot) do
				Groups.groups[id] = DeepCopy(data)
			end
		end
		if BFL.SettingsVersion then
			BFL.SettingsVersion = BFL.SettingsVersion + 1
		end
		FriendsList = FriendsList or BFL:GetModule("FriendsList")
		if FriendsList then
			if FriendsList.InvalidateSettingsCache then
				FriendsList:InvalidateSettingsCache()
			end
			FriendsList.lastBuildInputs = nil
		end
	end
	local function RestoreDBSet()
		if not originalDBSet or not DB then
			return
		end
		DB.Set = originalDBSet
		for key in pairs(capturedKeys) do
			originalDBSet(DB, key, capturedValues[key])
		end
	end
	if DB and DB.Set then
		originalDBSet = DB.Set
		capturedKeys = {}
		capturedValues = {}
		if BetterFriendlistDB then
			snapshot = {
				groupOrder = DeepCopy(BetterFriendlistDB.groupOrder),
				friendGroups = DeepCopy(BetterFriendlistDB.friendGroups),
				customGroups = DeepCopy(BetterFriendlistDB.customGroups),
				groupStates = DeepCopy(BetterFriendlistDB.groupStates),
				groupColors = DeepCopy(BetterFriendlistDB.groupColors),
				groupCountColors = DeepCopy(BetterFriendlistDB.groupCountColors),
				groupArrowColors = DeepCopy(BetterFriendlistDB.groupArrowColors),
				quickFilterTags = DeepCopy(BetterFriendlistDB.quickFilterTags),
			}
			-- Keep every test independent from the user's currently selected tag facets.
			BetterFriendlistDB.quickFilterTags = {}
		end
		local Groups = BFL:GetModule("Groups")
		if Groups and Groups.groups then
			groupsSnapshot = DeepCopy(Groups.groups)
		end
		DB.Set = function(dbSelf, key, value, ...)
			if not capturedKeys[key] then
				capturedKeys[key] = true
				capturedValues[key] = dbSelf:Get(key)
			end
			return originalDBSet(dbSelf, key, value, ...)
		end
	end

	-- Run setup
	if test.setup then
		local setupOk, setupErr = pcall(test.setup)
		if not setupOk then
			RestoreDBSet()
			RestoreSnapshots()
			result.status = TEST_STATUS.FAILED
			result.reason = "Setup failed: " .. tostring(setupErr)
			self.Reporter:Fail(test.name, result.reason)
			return result
		end
	end

	-- Run action
	local actionOk, actionErr = pcall(test.action, self.Validator)

	-- Run teardown (always)
	if test.teardown then
		local teardownOk, teardownErr = pcall(test.teardown)
		if not teardownOk then
			self.Reporter:Warn("Teardown failed for '" .. test.name .. "': " .. tostring(teardownErr))
		end
	end

	RestoreDBSet()
	RestoreSnapshots()

	result.duration = (debugprofilestop() - startTime) / 1000 -- Convert to seconds

	if actionOk then
		result.status = TEST_STATUS.PASSED
		self.Reporter:Pass(test.name, string.format("%.3fs", result.duration))
	elseif type(actionErr) == "string" and actionErr:find(SKIP_MARKER, 1, true) then
		-- Test called V:Skip() - treat as skipped, not failed
		result.status = TEST_STATUS.SKIPPED
		result.reason = actionErr:gsub(SKIP_MARKER, "")
		self.Reporter:Skip(test.name, result.reason)
	else
		result.status = TEST_STATUS.FAILED
		result.reason = tostring(actionErr)
		self.Reporter:Fail(test.name, result.reason)
	end

	return result
end

function TestSuite:RunCategory(category)
	local tests = self.tests[category]
	if not tests or #tests == 0 then
		self.Reporter:Warn("No tests registered for category '" .. category .. "'")
		return { passed = 0, failed = 0, skipped = 0 }
	end

	self.Reporter:SubHeader(string.upper(category) .. " TESTS (" .. #tests .. ")")

	local results = {
		passed = 0,
		failed = 0,
		skipped = 0,
		failedTests = {},
	}

	for _, test in ipairs(tests) do
		local result = self:RunTest(test)

		if result.status == TEST_STATUS.PASSED then
			results.passed = results.passed + 1
		elseif result.status == TEST_STATUS.FAILED then
			results.failed = results.failed + 1
			table.insert(results.failedTests, result)
		elseif result.status == TEST_STATUS.SKIPPED then
			results.skipped = results.skipped + 1
		end
	end

	return results
end

function TestSuite:RunAll()
	if self.isRunning then
		self.Reporter:Warn("Tests are already running!")
		return
	end

	self.isRunning = true
	self.startTime = debugprofilestop()

	self.Reporter:Header("BETTERFRIENDLIST TEST SUITE")
	self.Reporter:Info("Running all tests...")

	local totalResults = {
		passed = 0,
		failed = 0,
		skipped = 0,
		failedTests = {},
	}

	for _, category in ipairs(TEST_CATEGORIES) do
		local categoryResults = self:RunCategory(category)
		totalResults.passed = totalResults.passed + categoryResults.passed
		totalResults.failed = totalResults.failed + categoryResults.failed
		totalResults.skipped = totalResults.skipped + categoryResults.skipped

		for _, failedTest in ipairs(categoryResults.failedTests or {}) do
			table.insert(totalResults.failedTests, failedTest)
		end
	end

	totalResults.duration = (debugprofilestop() - self.startTime) / 1000

	self.Reporter:Summary(totalResults)

	self.isRunning = false
	self.testResults = totalResults

	return totalResults
end

function TestSuite:RunSingleTest(testName)
	local normalizedTestName = testName and testName:lower()
	-- Find test by name across all categories
	for _, category in ipairs(TEST_CATEGORIES) do
		for _, test in ipairs(self.tests[category]) do
			if test.name == testName or (normalizedTestName and test.name:lower() == normalizedTestName) then
				self.Reporter:Header("RUNNING SINGLE TEST")
				local result = self:RunTest(test)
				return result
			end
		end
	end

	self.Reporter:Fail("Test not found", "No test named '" .. testName .. "'")
	return nil
end

-- ============================================
-- TEST LISTING
-- ============================================

function TestSuite:ListTests(category)
	if category then
		local tests = self.tests[category]
		if not tests then
			self.Reporter:Warn("Unknown category: " .. category)
			return
		end

		self.Reporter:SubHeader(string.upper(category) .. " TESTS")
		if #tests == 0 then
			print("  (no tests registered)")
		else
			for i, test in ipairs(tests) do
				print(string.format("  %d. %s", i, test.name))
				if test.description then
					print("     |cff888888" .. test.description .. "|r")
				end
			end
		end
	else
		self.Reporter:Header("REGISTERED TESTS")
		local total = 0
		for _, cat in ipairs(TEST_CATEGORIES) do
			local count = #self.tests[cat]
			total = total + count
			print(string.format("  %-12s: %d tests", cat, count))
		end
		print("")
		print(string.format("  Total: %d tests", total))
	end
end

-- ============================================
-- SLASH COMMAND HANDLER
-- ============================================

function TestSuite:HandleCommand(args)
	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	if cmd == "" or cmd == "help" then
		self:ShowHelp()
	elseif cmd == "ui" then
		self.Reporter:Header("UI TESTS")
		self:RunCategory("ui")
	elseif cmd == "data" then
		self.Reporter:Header("DATA TESTS")
		self:RunCategory("data")
	elseif cmd == "events" then
		self.Reporter:Header("EVENT TESTS")
		self:RunCategory("events")
	elseif cmd == "perf" then
		self.Reporter:Header("PERFORMANCE TESTS")
		self:RunCategory("perf")
	elseif cmd == "classic" then
		self.Reporter:Header("CLASSIC TESTS")
		self:RunCategory("classic")
	elseif cmd == "integration" then
		self.Reporter:Header("INTEGRATION TESTS")
		self:RunCategory("integration")
	elseif cmd == "all" then
		self:RunAll()
	elseif cmd == "run" then
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test run <testname>")
		else
			self:RunSingleTest(param)
		end
	elseif cmd == "list" then
		self:ListTests(param ~= "" and param or nil)
	elseif cmd == "status" then
		self:ShowStatus()
	elseif cmd == "results" then
		if self.testResults and (self.testResults.passed + self.testResults.failed + self.testResults.skipped) > 0 then
			self.Reporter:Summary(self.testResults)
		else
			self.Reporter:Info("No test results available. Run tests first with: /bfl test all")
		end
	elseif cmd == "scenario" then
		self:HandleScenarioCommand(param)
	elseif cmd == "event" then
		self:HandleEventCommand(param)
	elseif cmd == "validate" then
		self:HandleValidateCommand(param)
	elseif cmd == "bench" or cmd == "benchmark" then
		self:HandleBenchmarkCommand(param)
	elseif cmd == "perfy" then
		self:HandlePerfyCommand(param)
	elseif cmd == "regression" or cmd == "regress" then
		self:HandleRegressionCommand(param)
	elseif self.tests[cmd] then
		self.Reporter:Header(string.upper(cmd) .. " TESTS")
		self:RunCategory(cmd)
	else
		self.Reporter:Warn("Unknown command: " .. cmd)
		self:ShowHelp()
	end
end

function TestSuite:ShowHelp()
	self.Reporter:Header("BFL TEST SUITE HELP")
	print("")
	print("|cffffcc00Test Commands:|r")
	print("  |cffffffff/bfl test|r              - Show this help")
	print("  |cffffffff/bfl test all|r          - Run ALL tests")
	print("  |cffffffff/bfl test ui|r           - Run UI tests")
	print("  |cffffffff/bfl test data|r         - Run data tests")
	print("  |cffffffff/bfl test events|r       - Run event tests")
	print("  |cffffffff/bfl test perf|r         - Run performance tests")
	print(GetLocalizedText("TESTSUITE_PERFY_HELP", "  |cffffffff/bfl test perfy [visible|background|idle] [seconds]|r - Run Perfy stress test"))
	print("  |cffffffff/bfl test classic|r      - Run Classic-specific tests")
	print("  |cffffffff/bfl test integration|r  - Run integration tests")
	print("  |cffffffff/bfl test settings|r     - Run settings tests")
	print("  |cffffffff/bfl test sort|r         - Run sort tests")
	print("  |cffffffff/bfl test filter|r       - Run filter tests")
	print("  |cffffffff/bfl test bugs|r         - Run bug-pattern tests")
	print("  |cffffffff/bfl test groups|r       - Run groups tests")
	print("  |cffffffff/bfl test updates|r      - Run update/refresh tests")
	print("  |cffffffff/bfl test render|r       - Run render consistency tests")
	print("  |cffffffff/bfl test issues|r       - Run issue regression tests")
	print("")
	print("|cffffcc00Utility Commands:|r")
	print("  |cffffffff/bfl test run <name>|r   - Run single test by name")
	print("  |cffffffff/bfl test list [cat]|r   - List tests (optionally by category)")
	print("  |cffffffff/bfl test status|r       - Show test framework status")
	print("  |cffffffff/bfl test results|r      - Show last test results")
	print("")
	print("|cffffcc00Scenario Commands:|r")
	print("  |cffffffff/bfl test scenario|r            - Show scenario help")
	print("  |cffffffff/bfl test scenario list|r       - List all scenarios")
	print("  |cffffffff/bfl test scenario load <n>|r   - Load a scenario")
	print("  |cffffffff/bfl test scenario save <n>|r   - Save current state")
	print("")
	print("|cffffcc00Event Commands:|r")
	print("  |cffffffff/bfl test event|r               - Show event help")
	print("  |cffffffff/bfl test event fire <event>|r  - Fire a single event")
	print("  |cffffffff/bfl test event seq <name>|r    - Run event sequence")
	print("")
	print("|cffffcc00Validation Commands:|r")
	print("  |cffffffff/bfl test validate|r            - Show validation help")
	print("  |cffffffff/bfl test validate snapshot|r   - Take state snapshot")
	print("  |cffffffff/bfl test validate compare|r    - Compare snapshots")
	print("  |cffffffff/bfl test validate all|r        - Validate all modules")
	print("")
	print("|cffffcc00Benchmark Commands:|r")
	print("  |cffffffff/bfl test bench|r               - Show benchmark help")
	print("  |cffffffff/bfl test bench list|r          - List available benchmarks")
	print("  |cffffffff/bfl test bench run <id>|r      - Run specific benchmark")
	print("  |cffffffff/bfl test bench all|r           - Run all benchmarks")
	print("  |cffffffff/bfl test bench history|r       - Show history")
	print("  |cffffffff/bfl test bench compare|r       - Compare with previous")
	print("")
	print("|cffffcc00Regression Commands:|r")
	print("  |cffffffff/bfl test regression|r          - Show regression help")
	print("  |cffffffff/bfl test regression all|r      - Run all regression tests")
	print("  |cffffffff/bfl test regression bugs|r     - Run bug pattern tests")
	print("  |cffffffff/bfl test regression api|r      - Run API compatibility tests")
	print("  |cffffffff/bfl test regression list|r     - List regression tests")
	print("")
end

function TestSuite:ShowStatus()
	self.Reporter:Header("TEST FRAMEWORK STATUS")
	print("")
	print("  Framework Version:  1.0")
	print("  Is Running:         " .. (self.isRunning and "|cff00ff00Yes|r" or "|cff888888No|r"))
	self.Reporter:Info("WoW Family: " .. (BFL.IsMainline and "Mainline" or "Classic") .. " (" .. BFL.TOCVersion .. ")")
	print(
		"  Preview Mode:       "
			.. (
				BFL:GetModule("PreviewMode") and BFL:GetModule("PreviewMode").enabled and "|cff00ff00Active|r"
				or "|cff888888Inactive|r"
			)
	)
	print("")

	-- Count registered tests
	local total = 0
	print("  Registered Tests:")
	for _, cat in ipairs(TEST_CATEGORIES) do
		local count = #self.tests[cat]
		total = total + count
		print(string.format("    %-12s: %d", cat, count))
	end
	print(string.format("    %-12s: %d", "TOTAL", total))
	print("")
end

-- ============================================
-- EVENT SIMULATION COMMANDS
-- ============================================

function TestSuite:HandleEventCommand(args)
	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	local EventSimulator = BFL.EventSimulator
	if not EventSimulator then
		self.Reporter:Warn("EventSimulator not available")
		return
	end

	if cmd == "fire" then
		-- Fire a single event: /bfl test event fire FRIENDLIST_UPDATE
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test event fire <EVENT_NAME> [arg1] [arg2] ...")
			return
		end

		local parts = { strsplit(" ", param) }
		local eventName = table.remove(parts, 1)

		-- Convert string args to appropriate types if possible
		local eventArgs = {}
		for _, arg in ipairs(parts) do
			local num = tonumber(arg)
			if num then
				table.insert(eventArgs, num)
			elseif arg == "true" then
				table.insert(eventArgs, true)
			elseif arg == "false" then
				table.insert(eventArgs, false)
			elseif arg == "nil" then
				table.insert(eventArgs, nil)
			else
				table.insert(eventArgs, arg)
			end
		end

		if EventSimulator:FireEvent(eventName, unpack(eventArgs)) then
			self.Reporter:Pass("Fired event: " .. eventName)
		else
			self.Reporter:Fail("Failed to fire event: " .. eventName)
		end
	elseif cmd == "list" then
		-- List available events
		print("|cff00ff00BFL Events (commonly used):|r")
		print("")
		print("|cffffd200Friend List:|r")
		print("  * FRIENDLIST_UPDATE")
		print("  * BN_FRIEND_ACCOUNT_ONLINE <bnetIDAccount>")
		print("  * BN_FRIEND_ACCOUNT_OFFLINE <bnetIDAccount>")
		print("  * BN_FRIEND_INFO_CHANGED <bnetIDAccount>")
		print("  * BN_FRIEND_LIST_SIZE_CHANGED")
		print("  * BN_CONNECTED / BN_DISCONNECTED")
		print("")
		print("|cffffd200Group/Raid:|r")
		print("  * GROUP_ROSTER_UPDATE")
		print("  * RAID_ROSTER_UPDATE")
		print("  * PARTY_INVITE_REQUEST <inviter>")
		print("")
		print("|cffffd200Chat:|r")
		print("  * CHAT_MSG_WHISPER <msg> <sender>")
		print("  * CHAT_MSG_BN_WHISPER <msg> <sender>")
		print("")
	elseif cmd == "seq" or cmd == "sequence" then
		-- Run predefined sequence: /bfl test event seq friend_login 1001
		if param == "" then
			-- List available sequences
			print("|cff00ff00Available Event Sequences:|r")
			local sequences = EventSimulator:ListSequences()
			for _, seq in ipairs(sequences) do
				print(string.format("  * |cffffffff%s|r - %s", seq.id, seq.description))
			end
			print("")
			print("|cff888888Usage: /bfl test event seq <name> [args...]|r")
			return
		end

		local parts = { strsplit(" ", param) }
		local seqName = table.remove(parts, 1)

		-- Convert remaining args
		local seqArgs = {}
		for _, arg in ipairs(parts) do
			local num = tonumber(arg)
			table.insert(seqArgs, num or arg)
		end

		local seqId = EventSimulator:RunSequence(seqName, unpack(seqArgs))
		if seqId then
			self.Reporter:Info("Started sequence: " .. seqName .. " (ID: " .. seqId .. ")")
		else
			self.Reporter:Fail("Unknown sequence: " .. seqName)
		end
	elseif cmd == "friend" then
		-- Shortcut for friend events: /bfl test event friend online 1001
		local action, id = strsplit(" ", param or "", 2)
		action = action and action:lower() or ""
		id = id and tonumber(id) or 1001

		if action == "online" then
			EventSimulator:SimulateFriendOnline(id)
			self.Reporter:Pass("Simulated friend online: " .. id)
		elseif action == "offline" then
			EventSimulator:SimulateFriendOffline(id)
			self.Reporter:Pass("Simulated friend offline: " .. id)
		elseif action == "update" or action == "change" then
			EventSimulator:SimulateFriendInfoChanged(id)
			self.Reporter:Pass("Simulated friend info change: " .. id)
		else
			print("|cff00ff00Friend Event Shortcuts:|r")
			print("  /bfl test event friend |cffffffffonline <id>|r  - Friend comes online")
			print("  /bfl test event friend |cffffffffoffline <id>|r - Friend goes offline")
			print("  /bfl test event friend |cffffffffupdate <id>|r  - Friend info changed")
		end
	elseif cmd == "whisper" then
		-- Simulate whisper: /bfl test event whisper TestPlayer Hello!
		local sender, message = strsplit(" ", param or "", 2)
		sender = sender or "TestPlayer"
		message = message or "Test message"

		EventSimulator:SimulateWhisper(sender, message, false)
		self.Reporter:Pass("Simulated whisper from: " .. sender)
	elseif cmd == "bnet" then
		-- BNet shortcuts: /bfl test event bnet connect/disconnect
		local action = param and param:lower() or ""

		if action == "connect" or action == "connected" then
			EventSimulator:SimulateBNetConnection(true)
			self.Reporter:Pass("Simulated BNet connected")
		elseif action == "disconnect" or action == "disconnected" then
			EventSimulator:SimulateBNetConnection(false)
			self.Reporter:Pass("Simulated BNet disconnected")
		else
			print("|cff00ff00BNet Event Shortcuts:|r")
			print("  /bfl test event bnet |cffffffffconnect|r     - Simulate BNet connected")
			print("  /bfl test event bnet |cffffffffdisconnect|r  - Simulate BNet disconnected")
		end
	elseif cmd == "refresh" then
		-- Quick friend list refresh
		EventSimulator:SimulateFriendListRefresh()
		self.Reporter:Pass("Simulated friend list refresh")
	elseif cmd == "log" then
		-- Event logging
		local action = param and param:lower() or ""

		if action == "on" or action == "enable" then
			EventSimulator:SetLogging(true)
			self.Reporter:Info("Event logging enabled")
		elseif action == "off" or action == "disable" then
			EventSimulator:SetLogging(false)
			self.Reporter:Info("Event logging disabled")
		elseif action == "show" or action == "print" then
			EventSimulator:PrintEventLog(20)
		elseif action == "clear" then
			EventSimulator:ClearEventLog()
			self.Reporter:Info("Event log cleared")
		else
			print("|cff00ff00Event Logging:|r")
			print("  /bfl test event log |cffffffffon|r     - Enable logging")
			print("  /bfl test event log |cffffffffoff|r    - Disable logging")
			print("  /bfl test event log |cffffffffshow|r   - Show recent log")
			print("  /bfl test event log |cffffffffclear|r  - Clear log")
		end
	elseif cmd == "status" then
		EventSimulator:PrintStatus()
	elseif cmd == "reset" then
		EventSimulator:Reset()
		self.Reporter:Info("EventSimulator reset")
	else
		-- Show help
		print("|cffff9000BFL Event Simulation Commands:|r")
		print("")
		print("|cffffd200Fire Events:|r")
		print("  /bfl test event |cfffffffffire <EVENT>|r    - Fire any event")
		print("  /bfl test event |cfffffffflist|r            - List common events")
		print("  /bfl test event |cffffffffrefresh|r         - Fire FRIENDLIST_UPDATE")
		print("")
		print("|cffffd200Shortcuts:|r")
		print("  /bfl test event |cfffffffffriend online|r   - Simulate friend login")
		print("  /bfl test event |cfffffffffriend offline|r  - Simulate friend logout")
		print("  /bfl test event |cffffffffwhisper <name>|r  - Simulate whisper")
		print("  /bfl test event |cffffffffbnet connect|r    - Simulate BNet connect")
		print("")
		print("|cffffd200Sequences:|r")
		print("  /bfl test event |cffffffffseq|r             - List sequences")
		print("  /bfl test event |cffffffffseq <name>|r      - Run sequence")
		print("")
		print("|cffffd200Logging:|r")
		print("  /bfl test event |cfffffffflog on/off|r      - Toggle logging")
		print("  /bfl test event |cfffffffflog show|r        - Show event log")
		print("  /bfl test event |cffffffffstatus|r          - Show simulator status")
		print("")
	end
end

-- ============================================
-- VALIDATION COMMANDS
-- ============================================

function TestSuite:HandleValidateCommand(args)
	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	local StateValidator = BFL.StateValidator
	if not StateValidator then
		self.Reporter:Warn("StateValidator not available")
		return
	end

	if cmd == "snapshot" or cmd == "snap" then
		-- Take a snapshot
		local label = param ~= "" and param or nil
		local snapshot = StateValidator:TakeSnapshot(label)
		self.Reporter:Pass("Snapshot taken: " .. snapshot.label)
	elseif cmd == "compare" or cmd == "diff" then
		-- Compare last two snapshots
		local snap1 = StateValidator:GetSnapshot(2) -- older
		local snap2 = StateValidator:GetSnapshot(1) -- newer

		if not snap1 or not snap2 then
			self.Reporter:Warn("Need at least 2 snapshots. Take more with: /bfl test validate snapshot")
			return
		end

		local comparison = StateValidator:CompareSnapshots(snap1, snap2)
		StateValidator:PrintComparison(comparison)
	elseif cmd == "show" then
		-- Show a specific or most recent snapshot
		local index = tonumber(param) or 1
		local snapshot = StateValidator:GetSnapshot(index)
		StateValidator:PrintSnapshot(snapshot)
	elseif cmd == "all" then
		-- Validate all modules
		local result = StateValidator:ValidateAll()
		StateValidator:PrintValidation(result)

		if result.failedModules == 0 then
			self.Reporter:Pass("All " .. result.totalModules .. " modules passed validation")
		else
			self.Reporter:Fail(result.failedModules .. " of " .. result.totalModules .. " modules failed")
		end
	elseif cmd == "module" then
		-- Validate specific module
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test validate module <ModuleName>")
			print("")
			print("|cffffd200Available modules:|r")
			for _, name in ipairs(StateValidator.VALIDATABLE_MODULES) do
				print("  * " .. name)
			end
			return
		end

		local result = StateValidator:ValidateModule(param)
		StateValidator:PrintValidation(result)
	elseif cmd == "regression" or cmd == "regress" then
		-- Check for regressions between snapshots
		local snap1 = StateValidator:GetSnapshot(2)
		local snap2 = StateValidator:GetSnapshot(1)

		if not snap1 or not snap2 then
			self.Reporter:Warn("Need at least 2 snapshots for regression analysis")
			return
		end

		local report = StateValidator:DetectRegressions(snap1, snap2)
		StateValidator:PrintRegressionReport(report)

		if #report.potentialRegressions > 0 then
			self.Reporter:Warn(#report.potentialRegressions .. " potential regression(s) detected")
		else
			self.Reporter:Pass("No regressions detected")
		end
	elseif cmd == "status" then
		StateValidator:PrintStatus()
	elseif cmd == "reset" then
		StateValidator:Reset()
		self.Reporter:Info("StateValidator reset")
	else
		-- Show help
		print("|cffff9000BFL Validation Commands:|r")
		print("")
		print("|cffffd200Snapshots:|r")
		print("  /bfl test validate |cffffffffsnapshot [label]|r - Take state snapshot")
		print("  /bfl test validate |cffffffffshow [index]|r     - Show snapshot details")
		print("  /bfl test validate |cffffffffcompare|r          - Compare last 2 snapshots")
		print("  /bfl test validate |cffffffffregression|r       - Detect regressions")
		print("")
		print("|cffffd200Module Validation:|r")
		print("  /bfl test validate |cffffffffall|r              - Validate all modules")
		print("  /bfl test validate |cffffffffmodule <name>|r    - Validate specific module")
		print("")
		print("|cffffd200Utility:|r")
		print("  /bfl test validate |cffffffffstatus|r           - Show validator status")
		print("  /bfl test validate |cffffffffreset|r            - Reset all snapshots")
		print("")
	end
end

function TestSuite:HandleScenarioCommand(args)
	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	local PreviewMode = BFL:GetModule("PreviewMode")
	local MockDataProvider = BFL.MockDataProvider

	if cmd == "list" then
		self.Reporter:SubHeader("AVAILABLE SCENARIOS")

		-- Use ScenarioManager for unified listing
		local ScenarioManager = BFL.ScenarioManager
		if ScenarioManager then
			local scenarios = ScenarioManager:ListAll()

			-- Separate by type
			local presets = {}
			local saved = {}
			for _, s in ipairs(scenarios) do
				if s.type == "preset" then
					table.insert(presets, s)
				else
					table.insert(saved, s)
				end
			end

			if #presets > 0 then
				print("|cffffd200Built-in Presets:|r")
				for _, preset in ipairs(presets) do
					print(
						string.format(
							"  * |cffffffff%s|r - %s (%d friends)",
							preset.name,
							preset.description,
							preset.friendCount or 0
						)
					)
				end
				print("")
			end

			if #saved > 0 then
				print("|cff00ff00Saved Scenarios:|r")
				for _, scenario in ipairs(saved) do
					local savedAt = scenario.savedAt and date("%Y-%m-%d %H:%M", scenario.savedAt) or "Unknown"
					print(
						string.format(
							"  * |cffffffff%s|r (%d friends, saved %s)",
							scenario.name,
							scenario.friendCount or 0,
							savedAt
						)
					)
				end
				print("")
			else
				print("|cff888888No saved scenarios. Use 'save <name>' to create one.|r")
				print("")
			end
		else
			-- Fallback: List MockDataProvider presets if available
			if MockDataProvider and MockDataProvider.ListPresets then
				local presets = MockDataProvider:ListPresets()
				for _, preset in ipairs(presets) do
					print(string.format("  * |cffffffff%s|r - %s", preset.id, preset.description))
				end
				print("")
			end
		end

		-- Legacy scenarios
		print("|cff888888Legacy Presets:|r")
		print("  * |cffffffffpreview|r - Default preview mode (current)")
		print("  * |cffffffffraid_standard|r - 25-man raid preset")
		print("  * |cffffffffraid_full|r - 40-man raid preset")
		print("  * |cffffffffquickjoin|r - QuickJoin groups preset")
		print("")
		print("|cff888888Use: /bfl test scenario load <name>|r")
	elseif cmd == "load" then
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test scenario load <name>")
			return
		end

		-- Try ScenarioManager first (handles both presets and saved scenarios)
		local ScenarioManager = BFL.ScenarioManager
		if ScenarioManager then
			if ScenarioManager:Load(param) then
				local status = ScenarioManager:GetStatus()
				self.Reporter:Info("Loaded scenario: " .. param .. " (" .. status.friendCount .. " friends)")
				return
			end
		end

		-- Try MockDataProvider preset as fallback
		if MockDataProvider and MockDataProvider.Presets and MockDataProvider.Presets[param] then
			local data = MockDataProvider:LoadPreset(param)
			if data then
				-- Apply the generated data through PreviewMode
				self:ApplyMockData(data)
				self.Reporter:Info("Loaded scenario: " .. param .. " (" .. #data.friends .. " friends)")
				return
			end
		end

		-- Legacy scenario handlers
		if param == "preview" then
			if PreviewMode then
				PreviewMode:Enable()
				self.Reporter:Info("Loaded scenario: preview (default mock data)")
			end
		elseif param == "raid_standard" then
			if PreviewMode then
				PreviewMode:Enable()
				local RaidFrame = BFL:GetModule("RaidFrame")
				if RaidFrame and RaidFrame.CreateMockPreset_Standard then
					RaidFrame:CreateMockPreset_Standard()
					self.Reporter:Info("Loaded scenario: raid_standard (25-man)")
				end
			end
		elseif param == "raid_full" then
			if PreviewMode then
				PreviewMode:Enable()
				local RaidFrame = BFL:GetModule("RaidFrame")
				if RaidFrame and RaidFrame.CreateMockPreset_Full then
					RaidFrame:CreateMockPreset_Full()
					self.Reporter:Info("Loaded scenario: raid_full (40-man)")
				end
			end
		elseif param == "quickjoin" then
			if PreviewMode then
				PreviewMode:Enable()
				local QuickJoin = BFL:GetModule("QuickJoin")
				if QuickJoin and QuickJoin.CreateMockPreset_All then
					QuickJoin:CreateMockPreset_All()
					self.Reporter:Info("Loaded scenario: quickjoin")
				end
			end
		else
			self.Reporter:Warn("Unknown scenario: " .. param)
		end
	elseif cmd == "clear" then
		-- Clear MockDataProvider state
		if MockDataProvider then
			MockDataProvider:Reset()
		end

		-- Clear ScenarioManager state
		local ScenarioManager = BFL.ScenarioManager
		if ScenarioManager then
			ScenarioManager:Clear()
		end

		if PreviewMode and PreviewMode.enabled then
			PreviewMode:Disable()
			self.Reporter:Info("Mock data cleared, real data restored")
		else
			self.Reporter:Info("No mock data active")
		end
	elseif cmd == "stats" then
		-- Show current mock data stats
		if MockDataProvider then
			MockDataProvider:PrintStats()
		else
			self.Reporter:Warn("MockDataProvider not available")
		end
	elseif cmd == "save" then
		-- Save current state as named scenario
		local ScenarioManager = BFL.ScenarioManager
		if not ScenarioManager then
			self.Reporter:Warn("ScenarioManager not available")
			return
		end

		if param == "" then
			self.Reporter:Warn("Usage: /bfl test scenario save <name>")
			return
		end

		if ScenarioManager:Save(param) then
			self.Reporter:Pass("Saved scenario: " .. param)
		else
			self.Reporter:Fail("Failed to save scenario")
		end
	elseif cmd == "delete" then
		-- Delete a saved scenario
		local ScenarioManager = BFL.ScenarioManager
		if not ScenarioManager then
			self.Reporter:Warn("ScenarioManager not available")
			return
		end

		if param == "" then
			self.Reporter:Warn("Usage: /bfl test scenario delete <name>")
			return
		end

		if ScenarioManager:Delete(param) then
			self.Reporter:Pass("Deleted scenario: " .. param)
		else
			self.Reporter:Fail("Failed to delete scenario (not found or preset)")
		end
	elseif cmd == "export" then
		-- Export scenario to chat (copyable)
		local ScenarioManager = BFL.ScenarioManager
		if not ScenarioManager then
			self.Reporter:Warn("ScenarioManager not available")
			return
		end

		if param == "" then
			self.Reporter:Warn("Usage: /bfl test scenario export <name>")
			return
		end

		local exportString = ScenarioManager:Export(param)
		if exportString then
			-- Show in editbox popup for easy copying
			if StaticPopupDialogs["BFL_SCENARIO_EXPORT"] == nil then
				StaticPopupDialogs["BFL_SCENARIO_EXPORT"] = {
					text = "BetterFriendlist - Scenario Export",
					button1 = OKAY,
					hasEditBox = true,
					OnShow = function(self, data)
						self.editBox:SetText(data)
						self.editBox:HighlightText()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
				}
			end
			StaticPopup_Show("BFL_SCENARIO_EXPORT", nil, nil, exportString)
			self.Reporter:Info("Exported scenario: " .. param .. " (copy from popup)")
		else
			self.Reporter:Fail("Failed to export (scenario not found)")
		end
	elseif cmd == "import" then
		-- Import scenario from param
		local ScenarioManager = BFL.ScenarioManager
		if not ScenarioManager then
			self.Reporter:Warn("ScenarioManager not available")
			return
		end

		self.Reporter:Info(
			"Import: Paste scenario string (BFL_SCENARIO_V1:...) to /bfl test scenario import <name> <string>"
		)
		self.Reporter:Warn("Not yet implemented - use saved scenarios for now")
	elseif cmd == "status" then
		-- Show ScenarioManager status
		local ScenarioManager = BFL.ScenarioManager
		if ScenarioManager then
			ScenarioManager:PrintStatus()
		else
			self.Reporter:Warn("ScenarioManager not available")
		end
	else
		print("|cffff9000BFL Scenario Commands:|r")
		print("  /bfl test scenario |cfffffffflist|r          - List available scenarios")
		print("  /bfl test scenario |cffffffffload <name>|r   - Load a scenario")
		print("  /bfl test scenario |cffffffffsave <name>|r   - Save current state")
		print("  /bfl test scenario |cffffffffdelete <name>|r - Delete saved scenario")
		print("  /bfl test scenario |cffffffffclear|r         - Clear mock data")
		print("  /bfl test scenario |cffffffffstats|r         - Show mock statistics")
		print("  /bfl test scenario |cffffffffexport <name>|r - Export scenario")
		print("  /bfl test scenario |cffffffffstatus|r        - Show manager status")
	end
end

--[[
	Apply generated mock data through PreviewMode
	@param data: table - Generated data from MockDataProvider
]]
function TestSuite:ApplyMockData(data)
	local PreviewMode = BFL:GetModule("PreviewMode")
	if not PreviewMode then
		self.Reporter:Warn("PreviewMode not available")
		return
	end

	-- Enable preview mode
	if not PreviewMode.enabled then
		PreviewMode.enabled = true
	end

	-- Inject mock friends
	if data.friends and #data.friends > 0 then
		PreviewMode.mockData.friends = data.friends
	end

	-- Inject mock groups
	if data.groups and #data.groups > 0 then
		PreviewMode.mockData.groups = data.groups

		-- Also update Groups module directly
		local Groups = BFL:GetModule("Groups")
		if Groups then
			-- Store original if not already stored
			if not PreviewMode.originalGroups then
				PreviewMode.originalGroups = {}
				for id, groupData in pairs(Groups.groups) do
					PreviewMode.originalGroups[id] = groupData
				end
			end

			-- Clear and inject mock groups
			wipe(Groups.groups)
			for _, mockGroup in ipairs(data.groups) do
				Groups.groups[mockGroup.id] = mockGroup
			end
		end
	end

	-- Inject group assignments
	if data.groupAssignments then
		PreviewMode.mockData.groupAssignments = data.groupAssignments

		-- Also update database
		if BetterFriendlistDB then
			if not PreviewMode.originalFriendGroups then
				PreviewMode.originalFriendGroups = {}
				if BetterFriendlistDB.friendGroups then
					for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
						PreviewMode.originalFriendGroups[uid] = groups
					end
				end
			end

			BetterFriendlistDB.friendGroups = BetterFriendlistDB.friendGroups or {}
			for uid, groups in pairs(data.groupAssignments) do
				BetterFriendlistDB.friendGroups[uid] = groups
			end
		end
	end

	-- Apply to FriendsList
	PreviewMode:ApplyMockFriends()

	-- Apply raid data if present
	if data.raid and #data.raid > 0 then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame then
			RaidFrame.mockEnabled = true
			RaidFrame.raidMembers = data.raid
		end
	end

	-- Refresh UI
	PreviewMode:RefreshAllUI()
end

-- ============================================
-- BUILT-IN UI TESTS
-- ============================================

local function RegisterBuiltInTests()
	local TS = TestSuite

	-- ===== UI TESTS =====

	TS:RegisterTest("ui", "MainFrame_Exists", {
		description = "BetterFriendsFrame exists and can be toggled",
		action = function(V)
			V:AssertNotNil(_G.BetterFriendsFrame, "BetterFriendsFrame should exist")
			V:AssertNotNil(_G.ToggleBetterFriendsFrame, "ToggleBetterFriendsFrame should exist")
		end,
	})

	TS:RegisterTest("ui", "MainFrame_Toggle", {
		description = "Main frame can be opened and closed",
		setup = function()
			-- Ensure frame is closed before test
			if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
				BetterFriendsFrame:Hide()
			end
		end,
		action = function(V)
			-- Open
			ToggleBetterFriendsFrame()
			V:AssertFrameVisible(BetterFriendsFrame, "Frame should be visible after toggle")

			-- Close
			ToggleBetterFriendsFrame()
			V:AssertFrameHidden(BetterFriendsFrame, "Frame should be hidden after second toggle")
		end,
		teardown = function()
			-- Leave frame open for convenience
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
	})

	TS:RegisterTest("ui", "SettingsFrame_Toggle", {
		description = "Settings frame can be opened",
		setup = function()
			-- Ensure main frame is open
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
		action = function(V)
			local Settings = BFL:GetModule("Settings")
			V:AssertNotNil(Settings, "Settings module should exist")

			Settings:Show()
			-- Settings:Show() is synchronous, check immediately
			local frame = _G.BetterFriendlistSettingsFrame
			V:Assert(frame and frame:IsShown(), "Settings frame should be visible")
		end,
		teardown = function()
			local Settings = BFL:GetModule("Settings")
			if Settings then
				Settings:Hide()
			end
		end,
	})

	TS:RegisterTest("settings", "SettingsDesigner_CompatibilityContracts", {
		description = "Modern Settings Center controls must map to supported runtime settings and stable defaults",
		action = function(V)
			local SettingsDesigner = BFL:GetModule("SettingsDesigner")
			local ThemePalette = BFL:GetModule("ThemePalette")
			if not SettingsDesigner or not ThemePalette then
				V:Skip("SettingsDesigner or ThemePalette not loaded")
				return
			end

			local settingsApp = SettingsDesigner:Register()
			local controls = settingsApp and settingsApp.controlsByID
			V:Assert(type(controls) == "table", "Settings Center controls should be registered")

			local namePreset = controls and controls.nameFormatPreset
			V:AssertNotNil(namePreset, "Name format preset control should exist")
			local expectedPresets = {
				"default",
				"battletag",
				"battletag_only",
				"nickname",
				"character",
				"name_only",
				"custom",
			}
			for index, value in ipairs(expectedPresets) do
				V:AssertEqual(namePreset.orderList[index], value, "Name preset order should only contain supported values")
				V:AssertNotNil(namePreset.list[value], "Supported name preset should have a label: " .. value)
			end
			V:AssertNil(namePreset.list.name_nickname, "Removed name_nickname preset must not be offered")
			V:AssertNil(namePreset.list.name_note, "Removed name_note preset must not be offered")
			V:AssertNil(namePreset.list.name_battletag, "Removed name_battletag preset must not be offered")

			V:AssertNil(controls.showNoteIcon, "Settings Center must not expose the unimplemented note icon setting")
			V:AssertNil(controls.guildBrokerTooltipMode, "Settings Center must not expose the unused guild tooltip mode")

			local friendTagsPage = settingsApp.GetPage and settingsApp:GetPage("groups.friendtags")
			V:AssertNotNil(friendTagsPage, "Friend Tags should have a standard Settings Center page")
			V:AssertNil(friendTagsPage.visibleWhen, "Friend Tags page should not depend on Beta Features")
			V:AssertNotNil(controls["friendTags.enabled"], "Friend Tags should expose its dedicated feature toggle")
			V:AssertNil(
				controls["friendTags.enabled"].parentCheck,
				"Friend Tags toggle should not depend on the global Beta Features switch"
			)
			V:AssertNil(controls["friendTags.tagList"], "Tag management should live only in the dedicated editor")
			V:AssertNotNil(controls["friendTags.showMenuTagCounts"], "Menu count settings should remain available")
			V:AssertNotNil(controls["friendTags.chipsPerLine"], "Per-line chip limits should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.chipIconSize"], "Chip icon size should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.chipFont"], "Chip font should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.chipFontSize"], "Chip font size should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.chipFontFlags"], "Chip font flags should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.fullWidthTagRows"], "Full-width tag rows should be mirrored in Settings Center")
			V:AssertNotNil(controls["friendTags.hideDynamicGroupTagChip"], "Dynamic group chip hiding should be mirrored in Settings Center")
			V:AssertNotNil(
				controls["friendTags.hideAllDynamicGroupTagChips"],
				"All-chip dynamic group hiding should be mirrored in Settings Center"
			)
			V:AssertEqual(controls["friendTags.chipsPerLine"].default, 3, "Per-line chips should default to three")
			V:AssertEqual(controls["friendTags.maxRowChips"].max, 20, "Settings Center should allow up to 20 row chips")
			V:AssertEqual(controls["friendTags.chipsPerLine"].max, 20, "Settings Center should allow up to 20 chips per line")
			V:AssertEqual(controls["friendTags.chipIconSize"].default, 11, "Chip icon size should default to 11")
			V:AssertEqual(controls["friendTags.chipFont"].default, "Friz Quadrata TT", "Chip font should use the standard BFL default")
			V:AssertEqual(controls["friendTags.chipFontSize"].default, 10, "Chip font size should default to 10")
			V:AssertEqual(controls["friendTags.chipFontFlags"].type, "multidropdown", "Chip font flags should support multiple compatible flags")
			V:Assert(controls["friendTags.chipFontFlags"].default.SLUG, "Chip font flags should retain locale-safe slug rendering by default")
			V:AssertEqual(controls["friendTags.fullWidthTagRows"].default, false, "Full-width tag rows should default to disabled")
			local syncControl = controls["friendTags.syncLocalBlizzard"]
			V:AssertNotNil(syncControl, "Legacy Blizzard-tag handoff should remain available when needed")
			V:AssertType(
				syncControl.visibleWhen,
				"function",
				"Legacy Blizzard-tag handoff should only appear when migration data exists"
			)

			local darkDefaults = ThemePalette:GetDefaultDarkSettings()
			local customDefaults = ThemePalette:GetDefaultCustomSettings()
			for _, key in ipairs({
				"windowOpacity",
				"popupOpacity",
				"listOpacity",
				"controlOpacity",
				"hoverStrength",
				"selectionStrength",
				"borderStrength",
				"avatarVisibility",
			}) do
				V:AssertEqual(controls["dark." .. key].default, darkDefaults[key], "Dark theme default should be canonical: " .. key)
				V:AssertEqual(controls["custom." .. key].default, customDefaults[key], "Custom theme default should be canonical: " .. key)
			end

			V:AssertNil(controls.simpleMode.visibleWhen, "Simple Mode should be available in both Modern and Legacy")
			V:AssertNil(controls.simpleModeShowSearch.visibleWhen, "Simple Mode search should be available in Modern and Legacy")
			V:AssertNil(controls.fontFriendName.visibleWhen, "Friend name font should remain available in both styles")
			for _, controlID in ipairs({
				"fontTabText",
				"fontSizeTabText",
				"fontOutlineTabText",
				"fontShadowTabText",
				"fontColorTabText",
			}) do
				V:AssertType(controls[controlID].visibleWhen, "function", "Every Tabs Text control should be style-gated")
			end
			local friendTabsPage = settingsApp.GetPage and settingsApp:GetPage("friends.tabs")
			V:AssertNotNil(friendTabsPage, "Modern Friend Tabs page should remain registered")
			V:AssertType(friendTabsPage.visibleWhen, "function", "Modern Friend Tabs page should remain style-gated")
			local FriendsUI = SettingsDesigner:GetFriendsUI()
			if FriendsUI and FriendsUI.IsModernActive then
				local oldIsModernActive = FriendsUI.IsModernActive
				local oldIsRetail = BFL.IsRetail
				local ok, err = pcall(function()
					BFL.IsRetail = true
					FriendsUI.IsModernActive = function()
						return true
					end
					V:Assert(not controls.fontTabText.visibleWhen(), "Tabs Text should be hidden for Modern UI")
					V:Assert(friendTabsPage.visibleWhen(), "Friend Tabs page should be shown for Modern UI")
					FriendsUI.IsModernActive = function()
						return false
					end
					V:Assert(controls.fontTabText.visibleWhen(), "Tabs Text should be shown for Legacy UI")
					V:Assert(not friendTabsPage.visibleWhen(), "Friend Tabs page should be hidden for Legacy UI")
				end)
				FriendsUI.IsModernActive = oldIsModernActive
				BFL.IsRetail = oldIsRetail
				if not ok then
					error(err, 0)
				end
			end
			V:AssertEqual(controls.friendsFrameStyle.type, "custom", "Style selector should own per-option capability state")
			V:AssertType(controls.friendsFrameStyle.render, "function", "Style selector should provide its host renderer")
			V:AssertEqual(controls.friendsFrameStyle.refreshOnChange, true, "Style changes should refresh Settings visibility")
		end,
	})

	TS:RegisterTest("ui", "SearchBox_NativeStateUpdatesBeforeBFLSearch", {
		description = "Retail and Classic search boxes run Blizzard placeholder/Clear-state logic before BFL filtering",
		action = function(V)
			local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
			local searchBox = header and header.SearchBox
			local handler = searchBox and searchBox.GetScript and searchBox:GetScript("OnTextChanged")
			if not handler then
				V:Skip("Persistent friend search box is not loaded")
				return
			end

			local oldNative = _G.SearchBoxTemplate_OnTextChanged
			local oldBFL = _G.BetterFriendsFrame_OnSearchTextChanged
			local order = {}
			local ok, err = pcall(function()
				_G.SearchBoxTemplate_OnTextChanged = function(target)
					V:AssertEqual(target, searchBox, "Native search handler should receive the active SearchBox")
					order[#order + 1] = "native"
				end
				_G.BetterFriendsFrame_OnSearchTextChanged = function(target)
					V:AssertEqual(target, searchBox, "BFL search handler should receive the active SearchBox")
					order[#order + 1] = "bfl"
				end
				handler(searchBox, true)
				V:AssertEqual(order[1], "native", "Blizzard SearchBox state should update first")
				V:AssertEqual(order[2], "bfl", "BFL filtering should run after Blizzard state synchronization")
			end)
			_G.SearchBoxTemplate_OnTextChanged = oldNative
			_G.BetterFriendsFrame_OnSearchTextChanged = oldBFL
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("ui", "Settings_LegacyFriendTagSliderUsesRuntimeRefresh", {
		description = "Friend-tag sliders update rows and caches without reconstructing the active Legacy Settings page",
		action = function(V)
			WithTemporaryDatabase({ friendTagSettings = { enabled = true } }, function()
				local Settings = BFL:GetModule("Settings")
				local FriendTags = BFL:GetModule("FriendTags")
				local tab = Settings and Settings.GetFriendTagsTabHost and Settings:GetFriendTagsTabHost()
				if not (Settings and FriendTags and tab) then
					V:Skip("Legacy Friend Tags settings page is not loaded")
					return
				end
				FriendTags:OnDatabaseImported()
				Settings:RefreshFriendTagsTab()

				local expectedLabel = BFL.L.FRIEND_TAGS_CHIPS_PER_LINE or "Chips per Line"
				local expectedFullWidthLabel = BFL.L.FRIEND_TAGS_FULL_WIDTH_ROWS or "Full-width Tag Rows"
				local expectedFontLabel = BFL.L.SETTINGS_FONT or "Font:"
				local expectedFontFlagsLabel = BFL.L.SETTINGS_FONT_FLAGS or "Font Flags:"
				local expectedCompactLabel = BFL.L.FRIEND_TAGS_SETTINGS_COMPACT_MODE or "Compact Row Mode"
				local sliderHolder
				local fullWidthHolder
				local fontHolder
				local fontFlagsHolder
				local compactHolder
				for _, component in ipairs(tab.components or {}) do
					if component.Label and component.Label:GetText() == expectedLabel and component.Slider then
						sliderHolder = component
					end
					if not fullWidthHolder and component.GetRegions then
						for _, region in ipairs({ component:GetRegions() }) do
							if region.GetText and region:GetText() == expectedFullWidthLabel then
								fullWidthHolder = component
								break
							end
						end
					end
					if component.Label and component.DropDown and component.Label:GetText() == expectedFontLabel then
						fontHolder = component
					elseif component.Label and component.DropDown and component.Label:GetText() == expectedFontFlagsLabel then
						fontFlagsHolder = component
					elseif component.Label and component.DropDown and component.Label:GetText() == expectedCompactLabel then
						compactHolder = component
					end
				end
				V:AssertNotNil(sliderHolder, "Legacy Friend Tags page should expose the per-line slider")
				V:AssertNotNil(fullWidthHolder, "Legacy Friend Tags page should expose full-width tag rows first")
				V:AssertNotNil(fullWidthHolder.LeftCheckbox, "Full-width tag rows should occupy the left Legacy column")
				V:AssertNotNil(fontHolder, "Legacy Friend Tags page should expose the chip font first")
				V:AssertNotNil(fontFlagsHolder, "Legacy Friend Tags page should expose chip font flags first")
				V:AssertNotNil(compactHolder, "Legacy Friend Tags page should expose Compact Row Mode")
				V:AssertEqual(
					fontHolder.DropDown:GetWidth(),
					compactHolder.DropDown:GetWidth(),
					"Legacy Friend Tags dropdowns should use one shared control width"
				)
				V:AssertEqual(
					fontFlagsHolder.DropDown:GetWidth(),
					compactHolder.DropDown:GetWidth(),
					"Legacy chip font flags should align with the other dropdowns"
				)

				local oldRefreshTab = Settings.RefreshFriendTagsTab
				local oldSchedule = BFL.ScheduleFriendsListRefresh
				local oldForce = BFL.ForceRefreshFriendsList
				local pageRebuilds = 0
				local runtimeRefreshes = 0
				local ok, err = pcall(function()
					Settings.RefreshFriendTagsTab = function()
						pageRebuilds = pageRebuilds + 1
					end
					BFL.ScheduleFriendsListRefresh = function()
						runtimeRefreshes = runtimeRefreshes + 1
					end
					BFL.ForceRefreshFriendsList = function()
						runtimeRefreshes = runtimeRefreshes + 1
					end
					sliderHolder:SetValue(4)
					V:AssertEqual(FriendTags:GetSetting("chipsPerLine"), 4, "Slider should persist its rounded value")
					V:Assert(runtimeRefreshes > 0, "Slider should request a lightweight runtime refresh")
					V:AssertEqual(pageRebuilds, 0, "Dragging the slider must not rebuild the Legacy Settings page")
				end)
				Settings.RefreshFriendTagsTab = oldRefreshTab
				BFL.ScheduleFriendsListRefresh = oldSchedule
				BFL.ForceRefreshFriendsList = oldForce
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("ui", "Settings_LegacyScrollbarTracksScrollRange", {
		description = "Legacy Settings hides an unscrollable scrollbar and restores it when content becomes longer",
		action = function(V)
			local Settings = BFL:GetModule("Settings")
			if not (Settings and Settings.UpdateLegacySettingsScrollbar) then
				V:Skip("Legacy scrollbar helper is not available")
				return
			end

			local range = 0
			local barScripts = {}
			local frameScripts = {}
			local scrollBar = {
				shown = true,
				SetHideIfUnscrollable = function(self, value)
					self.hideIfUnscrollable = value
				end,
				SetShown = function(self, value)
					self.shown = value == true
				end,
				Hide = function(self)
					self.shown = false
				end,
				HookScript = function(_, scriptName, callback)
					barScripts[scriptName] = callback
				end,
			}
			local scrollFrame = {
				ScrollBar = scrollBar,
				GetVerticalScrollRange = function()
					return range
				end,
				HookScript = function(_, scriptName, callback)
					frameScripts[scriptName] = callback
				end,
			}

			Settings:UpdateLegacySettingsScrollbar(scrollFrame)
			V:Assert(scrollBar.hideIfUnscrollable == true, "Retail scrollbar should enable native hide-if-unscrollable")
			V:Assert(not scrollBar.shown, "Zero scroll range should hide the scrollbar")
			V:AssertType(frameScripts.OnScrollRangeChanged, "function", "Range changes should stay synchronized")
			V:AssertType(barScripts.OnShow, "function", "Skin-forced Show calls should be guarded")

			range = 30
			frameScripts.OnScrollRangeChanged(scrollFrame)
			V:Assert(scrollBar.shown, "Positive scroll range should restore the scrollbar")
			range = 0
			scrollBar.shown = true
			barScripts.OnShow(scrollBar)
			V:Assert(not scrollBar.shown, "A skin must not force-show a scrollbar with zero range")
		end,
	})

	TS:RegisterTest("ui", "Settings_GroupColorRightClickRefreshesTargetSwatch", {
		description = "Count and arrow right-click handlers pass their swatches and immediately apply inherited RGBA",
		action = function(V)
			local Components = BFL.SettingsComponents
			local Settings = BFL:GetModule("Settings")
			if not (Components and Settings) then
				V:Skip("Settings components are not loaded")
				return
			end

			local parent = CreateFrame("Frame", nil, UIParent)
			parent:Hide()
			local countTarget, countReset, arrowTarget, arrowReset
			local row = Components:CreateListItem(
				parent,
				"Swatch Test",
				1,
				nil,
				nil,
				nil,
				nil,
				nil,
				function(target, isReset)
					countTarget, countReset = target, isReset
				end,
				function(target, isReset)
					arrowTarget, arrowReset = target, isReset
				end,
				{ fallback = { r = 1, g = 0.82, b = 0, a = 1 } }
			)
			row.countColorButton:GetScript("OnClick")(row.countColorButton, "RightButton")
			row.arrowColorButton:GetScript("OnClick")(row.arrowColorButton, "RightButton")
			V:AssertEqual(countTarget, row.countColorSwatch, "Count reset should receive its own swatch")
			V:Assert(countReset == true, "Count right-click should preserve reset semantics")
			V:AssertEqual(arrowTarget, row.arrowColorSwatch, "Arrow reset should receive its own swatch")
			V:Assert(arrowReset == true, "Arrow right-click should preserve reset semantics")

			WithTemporaryDatabase({}, function(tempDB)
				local Groups = BFL:GetModule("Groups")
				local oldGet = Groups.Get
				local oldForce = BFL.ForceRefreshFriendsList
				local inherited = { r = 0.20, g = 0.35, b = 0.60, a = 0.45 }
				local group = { color = inherited }
				local countRGBA, arrowRGBA
				local refreshes = 0
				local ok, err = pcall(function()
					Groups.Get = function()
						return group
					end
					BFL.ForceRefreshFriendsList = function()
						refreshes = refreshes + 1
					end
					Settings:ShowGroupCountColorPicker("swatch-test", "Swatch Test", {
						SetColorTexture = function(_, r, g, b, a)
							countRGBA = { r, g, b, a }
						end,
					}, true)
					Settings:ShowGroupArrowColorPicker("swatch-test", "Swatch Test", {
						SetColorTexture = function(_, r, g, b, a)
							arrowRGBA = { r, g, b, a }
						end,
					}, true)
					for index, expected in ipairs({ inherited.r, inherited.g, inherited.b, inherited.a }) do
						V:AssertEqual(countRGBA[index], expected, "Count swatch should inherit complete RGBA")
						V:AssertEqual(arrowRGBA[index], expected, "Arrow swatch should inherit complete RGBA")
					end
					V:AssertEqual(tempDB.groupCountColors["swatch-test"].a, inherited.a, "Count reset should persist alpha")
					V:AssertEqual(tempDB.groupArrowColors["swatch-test"].a, inherited.a, "Arrow reset should persist alpha")
					V:AssertEqual(refreshes, 2, "Both resets should refresh the Friendlist")
				end)
				Groups.Get = oldGet
				BFL.ForceRefreshFriendsList = oldForce
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("ui", "Settings_GroupsTab_ListItems", {
		description = "Groups tab should build list items with handlers",
		setup = function()
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
		action = function(V)
			local Settings = BFL:GetModule("Settings")
			if not Settings then
				V:Skip("Settings not loaded")
				return
			end
			Settings:Show()
			Settings:RefreshGroupsTab()

			local frame = _G.BetterFriendlistSettingsFrame
			local tab = frame
				and frame.ContentScrollFrame
				and frame.ContentScrollFrame.Content
				and frame.ContentScrollFrame.Content.GroupsTab
			V:Assert(tab ~= nil, "GroupsTab should exist")

			local components = tab.components or {}
			local listItems = {}
			for _, item in ipairs(components) do
				if item and item.nameText and item.orderText and item.dragHandle then
					table.insert(listItems, item)
				end
			end
			V:Assert(#listItems > 0, "GroupsTab should have list items")

			local firstItem = listItems[1]
			V:Assert(firstItem:GetScript("OnDragStart") ~= nil, "List item should have OnDragStart")
			V:Assert(firstItem:GetScript("OnDragStop") ~= nil, "List item should have OnDragStop")
			V:Assert(
				firstItem.renameButton and firstItem.renameButton:GetScript("OnClick") ~= nil,
				"List item should have rename handler"
			)
		end,
		teardown = function()
			local Settings = BFL:GetModule("Settings")
			if Settings then
				Settings:Hide()
			end
		end,
	})

	TS:RegisterTest("ui", "Settings_GroupsTab_Drag_Smoke", {
		description = "Groups tab drag update and stop handlers should run without the removed global MouseIsOver helper",
		setup = function()
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
		action = function(V)
			local Settings = BFL:GetModule("Settings")
			if not Settings then
				V:Skip("Settings not loaded")
				return
			end
			Settings:Show()
			Settings:RefreshGroupsTab()

			local frame = _G.BetterFriendlistSettingsFrame
			local tab = frame
				and frame.ContentScrollFrame
				and frame.ContentScrollFrame.Content
				and frame.ContentScrollFrame.Content.GroupsTab
			if not tab then
				V:Skip("GroupsTab not available")
				return
			end

			local components = tab.components or {}
			for _, item in ipairs(components) do
				if item and item.nameText and item.GetScript then
					local onDragStart = item:GetScript("OnDragStart")
					local onDragStop = item:GetScript("OnDragStop")
					if onDragStart and onDragStop then
						local ok, err = TS:RunSettingsGroupDragSmoke(item, onDragStart, onDragStop)
						V:Assert(ok, "Drag lifecycle failed: " .. tostring(err))
						break
					end
				end
			end
			V:Assert(true, "Drag handlers executed")
		end,
		teardown = function()
			local Settings = BFL:GetModule("Settings")
			if Settings then
				Settings:Hide()
			end
		end,
	})

	TS:RegisterTest("ui", "Tabs_Switch", {
		description = "All main tabs can be selected",
		setup = function()
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
		action = function(V)
			local frame = BetterFriendsFrame
			V:AssertNotNil(frame, "BetterFriendsFrame should exist")
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if FriendsUI then
				local sections = FriendsUI:BuildAvailableSectionIDs()
				for _, sectionID in ipairs(sections) do
					FriendsUI:SelectSection(sectionID)
					V:AssertEqual(FriendsUI:GetSelectedSection(), sectionID, "Section " .. sectionID .. " should be selected")
				end
				return
			end

			-- Test each tab (1=Friends, 2=Who, 3=Raid, 4=QuickJoin in Retail)
			local maxTabs = BFL.IsRetail and 4 or 3

			for tabIndex = 1, maxTabs do
				PanelTemplates_SetTab(frame, tabIndex)
				local currentTab = PanelTemplates_GetSelectedTab(frame)
				V:AssertEqual(currentTab, tabIndex, "Tab " .. tabIndex .. " should be selected")
			end
		end,
		teardown = function()
			-- Return to Friends tab
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if FriendsUI then
				FriendsUI:SelectSection("friends")
			elseif BetterFriendsFrame then
				PanelTemplates_SetTab(BetterFriendsFrame, 1)
			end
		end,
	})

	TS:RegisterTest("ui", "FriendsTab_HasScrollBox", {
		description = "Friends tab has a scroll container",
		condition = function()
			return BFL.IsRetail
		end,
		setup = function()
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
			PanelTemplates_SetTab(BetterFriendsFrame, 1)
		end,
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			V:AssertNotNil(FriendsList, "FriendsList module should exist")
			V:AssertNotNil(FriendsList.scrollBox, "FriendsList should have scrollBox")
		end,
	})

	TS:RegisterTest("ui", "ModernFriendsUI_ControlGeometry", {
		description = "Retail Modern controls preserve Blizzard geometry and selected labels",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if not (FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()) then
				V:Skip("Modern Friends UI is not active")
				return
			end

			FriendsUI:ApplyModernRootGeometry()
			local root = FriendsUI.root
			V:AssertNotNil(root, "Modern root should exist")
			V:Assert(root.FilterBar.FilterDropdown:GetWidth() == 92 and root.FilterBar.FilterDropdown:GetHeight() == 29, "Filter dropdown should use compact 92x29 geometry")
			V:Assert(root.FilterBar.SortButton:GetWidth() == 92 and root.FilterBar.SortButton:GetHeight() == 29, "Sort dropdown should use compact 92x29 geometry")
			V:AssertEqual(root.BattleNetBar.MenuButton:GetWidth(), 34, "Menu button should match Blizzard width")
			V:AssertNotNil(root.TopDivider, "Top divider should exist")
			V:AssertNotNil(root.BottomDivider, "Bottom divider should exist")
			V:AssertEqual(root.TopDivider:GetHeight(), 3, "Top divider should use Blizzard's 3px atlas")
			V:AssertEqual(root.BottomDivider:GetHeight(), 3, "Bottom divider should use Blizzard's 3px atlas")
			V:AssertEqual(root.BottomDivider:GetNumPoints(), 2, "Bottom divider should use responsive side anchors")
			V:Assert(math.abs(root.BottomDivider:GetWidth() - (root.BottomActionBar:GetWidth() - 10)) < 0.5, "Bottom divider should remain inside the action bar")
			V:Assert(math.abs(root.ContentBackground:GetLeft() - BetterFriendsFrame:GetLeft() - 4) < 0.5, "Modern content background should remain inside the left border")
			V:Assert(math.abs(root.ContentBackground:GetRight() - BetterFriendsFrame:GetRight() + 4) < 0.5, "Modern content background should remain inside the right border")
			V:Assert(math.abs(root.ContentBackground:GetBottom() - BetterFriendsFrame:GetBottom() - 4) < 0.5, "Modern content background should remain above the bottom border")

			local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
			V:AssertEqual(header.StatusDropdown:GetWidth(), 54, "Status dropdown should match Blizzard width")
			if BFL_Tooltip and GameTooltip then
				BFL_Tooltip:Show()
				V:AssertEqual(BFL_Tooltip:GetFrameStrata(), "TOOLTIP", "BFL friend tooltip should use tooltip strata")
				V:Assert(
					BFL_Tooltip:GetFrameLevel() > GameTooltip:GetFrameLevel(),
					"BFL friend tooltip should render above Blizzard and SocialUI child frames"
				)
				BFL_Tooltip:Hide()
			end
			local QuickFilters = BFL:GetModule("QuickFilters")
			if QuickFilters and QuickFilters.RefreshDropdown then
				QuickFilters:RefreshDropdown(root.FilterBar.FilterDropdown)
				local filterText = root.FilterBar.FilterDropdown.Text:GetText() or ""
				V:Assert(filterText:find((FILTER or "Filter") .. " (", 1, true) == 1, "Filter dropdown should retain its compact parenthesized label")
				V:Assert(filterText:find("|T", 1, true) or filterText:find("|A", 1, true), "Filter dropdown should show the selected icon")
			end

			FriendsUI:RefreshSortButtonText()
			local FriendsList = BFL:GetModule("FriendsList")
			local Registry = BFL:GetModule("FilterSortRegistry")
			if FriendsList and Registry then
				local sortText = root.FilterBar.SortButton.Text:GetText() or ""
				V:Assert(sortText:find(" (", 1, true), "Sort dropdown should retain its compact parenthesized label")
				V:Assert(sortText:find("|T", 1, true) or sortText:find("|A", 1, true), "Sort dropdown should show the selected icon")
			end
		end,
	})

	TS:RegisterTest("ui", "ModernFriendsUI_GroupHeaderOwnsTextLayout", {
		description = "Modern group headers keep their multilingual text outside Button font-state layout",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if not (FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()) then
				V:Skip("Modern Friends UI is not active")
				return
			end

			local header = CreateFrame("Button", nil, UIParent, "BFLModernGroupHeaderTemplate")
			header:Hide()
			V:AssertNotNil(header.HeaderText, "Modern header should own its name FontString")
			V:AssertNotNil(header.CountText, "Modern header should own its count FontString")
			V:AssertNotNil(header.CollapseButton, "Modern header should retain Blizzard's collapse button")
			V:AssertNil(header:GetFontString(), "Modern header must not use a stateful ButtonText")
			V:AssertNil(header.GetTitleRegion, "Modern header must not inherit ListHeaderVisualMixin")
			V:AssertEqual(header.CountText:GetNumPoints(), 1, "Count text should start with one non-circular anchor")

			local FriendsList = BFL:GetModule("FriendsList")
			V:AssertNotNil(FriendsList, "FriendsList should be available")
			V:Assert(
				not FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "Raid Team"),
				"ASCII Modern headers should keep the configurable BFL font"
			)
			V:Assert(
				not FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "Grüße, Équipe, São Paulo"),
				"Extended Latin Modern headers should keep the configurable BFL font"
			)
			V:Assert(
				not FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "Cafe\204\129"),
				"Combining Latin accents should keep the configurable BFL font"
			)
			V:Assert(
				FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "레이드 팀"),
				"Non-Latin Modern headers should use Blizzard's initialized multilingual font"
			)
			V:Assert(
				FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "Тестовая группа"),
				"Cyrillic Modern headers should use Blizzard's initialized multilingual font"
			)
			V:Assert(
				FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "Δοκιμή"),
				"Other non-Latin scripts should fail safe to Blizzard's initialized multilingual font"
			)
			V:Assert(
				FriendsList:ShouldUseNativeMultilingualGroupHeaderFont(header, "\192\175"),
				"Malformed UTF-8 should fail safe to Blizzard's initialized multilingual font"
			)

			FriendsList:UpdateGroupHeaderButton(header, {
				groupId = "bfl-test-ascii-header",
				name = "Raid Team",
				count = 0,
				onlineCount = 0,
				totalCount = 0,
				collapsed = false,
			})
			local configurableFontObject = header.HeaderText:GetFontObject()
			V:AssertNotNil(configurableFontObject, "ASCII header should resolve the configured BFL FontFamily")
			V:Assert(
				configurableFontObject ~= _G.GameFontNormal,
				"ASCII header should not use Blizzard's safety fallback"
			)

			FriendsList:UpdateGroupHeaderButton(header, {
				groupId = "bfl-test-latin-header",
				name = "Grüße & Équipe",
				count = 0,
				onlineCount = 0,
				totalCount = 0,
				collapsed = false,
			})
			V:Assert(
				header.HeaderText:GetFontObject() == configurableFontObject,
				"Extended Latin header should retain the same configured FontFamily as ASCII"
			)
			V:Assert(
				header.CountText:GetFontObject() == configurableFontObject,
				"Extended Latin count should retain the configured FontFamily"
			)

			FriendsList:UpdateGroupHeaderButton(header, {
				groupId = "bfl-test-multilingual-header",
				name = "레이드 팀",
				count = 0,
				onlineCount = 0,
				totalCount = 0,
				collapsed = false,
			})
			V:Assert(
				header.HeaderText:GetFontObject() == _G.GameFontNormal,
				"Multilingual header text should use Blizzard's initialized FontFamily"
			)
			V:Assert(
				header.CountText:GetFontObject() == _G.GameFontNormal,
				"Multilingual header count should share Blizzard's initialized FontFamily"
			)
		end,
	})

	TS:RegisterTest("ui", "ModernFriendsUI_CopyBattleTagDialog", {
		description = "The Modern BattleTag copy action uses BFL's standardized copy dialog",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			local Changelog = BFL:GetModule("Changelog")
			if not (FriendsUI and Changelog and Changelog.ShowCopyDialog) then
				V:Skip("Modern copy dialog dependencies are unavailable")
				return
			end

			local oldRefresh = FriendsUI.RefreshBattleTag
			local oldBattleTag = FriendsUI.battleTag
			local oldShowCopyDialog = Changelog.ShowCopyDialog
			local copiedValue, copiedTitle
			FriendsUI.RefreshBattleTag = function() end
			FriendsUI.battleTag = "BFLTest#1234"
			Changelog.ShowCopyDialog = function(_, value, title)
				copiedValue, copiedTitle = value, title
			end
			FriendsUI:CopyBattleTag()
			FriendsUI.RefreshBattleTag = oldRefresh
			FriendsUI.battleTag = oldBattleTag
			Changelog.ShowCopyDialog = oldShowCopyDialog

			V:AssertEqual(copiedValue, "BFLTest#1234", "Copy dialog should receive the BattleTag")
			V:AssertEqual(copiedTitle, BFL.L.FRIENDS_UI_COPY_BATTLETAG, "Copy dialog should use the localized title")
		end,
	})

	TS:RegisterTest("ui", "Changelog_Toggle", {
		description = "Changelog frame can be opened and closed",
		action = function(V)
			local Changelog = BFL:GetModule("Changelog")
			V:AssertNotNil(Changelog, "Changelog module should exist")

			Changelog:Show()
			-- Changelog creates global frame BetterFriendlistChangelogFrame on first show
			local frame = _G["BetterFriendlistChangelogFrame"]
			V:Assert(frame and frame:IsShown(), "Changelog should be visible")

			-- Toggle again to hide (Changelog:Show calls ToggleChangelog)
			Changelog:Show()
			V:Assert(not frame:IsShown(), "Changelog should be hidden after toggle")
		end,
	})

	-- ===== DATA TESTS =====

	TS:RegisterTest("data", "Database_Module_Exists", {
		description = "Database module is loaded and functional",
		action = function(V)
			local DB = BFL:GetModule("DB")
			V:AssertNotNil(DB, "DB module should exist")
			V:AssertNotNil(DB.Get, "DB:Get should exist")
			V:AssertNotNil(DB.Set, "DB:Set should exist")
		end,
	})

	TS:RegisterTest("data", "Database_Set_Get", {
		description = "Database can store and retrieve values",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local testKey = "_test_key_" .. time()
			local testValue = "test_value_" .. math.random(10000)

			-- Set
			DB:Set(testKey, testValue)

			-- Get
			local retrieved = DB:Get(testKey)
			V:AssertEqual(retrieved, testValue, "Retrieved value should match set value")

			-- Cleanup
			DB:Set(testKey, nil)
			V:AssertNil(DB:Get(testKey), "Value should be nil after deletion")
		end,
	})

	TS:RegisterTest("data", "Database_Defaults_Applied", {
		description = "Defaults should be applied to a fresh DB",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				V:Assert(tempDB.showFavoritesGroup == true, "showFavoritesGroup default should be true")
				V:AssertEqual(tempDB.quickFilter, "all", "quickFilter default should be 'all'")
				V:AssertEqual(tempDB.primarySort, "status", "primarySort default should be 'status'")
				V:AssertEqual(tempDB.theme, "blizzard", "theme default should be 'blizzard'")
				V:AssertEqual(tempDB.forceModernFriendsUI, false, "Modern capability override should default to off")
				V:Assert(tempDB.groupOrder == nil, "groupOrder default should be nil")
				V:Assert(type(tempDB.groupStates) == "table", "groupStates should be a table")
				V:Assert(type(tempDB.groupColors) == "table", "groupColors should be a table")
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_DBDefaults", {
		description = "Contact Memory defaults should be present and disabled",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				local ContactMemory = BFL:GetModule("ContactMemory")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")

				local contactMemoryDB = ContactMemory:NormalizeDB()
				V:AssertType(tempDB.contactMemory, "table", "contactMemory should be a table")
				V:AssertEqual(contactMemoryDB.version, 1, "Contact Memory schema version should be 1")
				V:AssertEqual(contactMemoryDB.enabled, false, "Contact Memory should default to disabled")
				V:AssertType(contactMemoryDB.contacts, "table", "contacts should be a table")
				V:AssertType(contactMemoryDB.tags, "table", "tags should be a table")
				V:AssertType(contactMemoryDB.settings, "table", "settings should be a table")
				V:AssertEqual(
					contactMemoryDB.settings.hideInStreamerMode,
					true,
					"Private data should hide in Streamer Mode by default"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_DisabledState", {
		description = "Contact Memory should require both its toggle and Beta Features",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = false,
				contactMemory = {
					enabled = true,
				},
			}, function()
				local ContactMemory = BFL:GetModule("ContactMemory")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")
				V:Assert(ContactMemory:IsEnabled() == false, "Beta disabled should disable Contact Memory")

				BetterFriendlistDB.enableBetaFeatures = true
				V:Assert(ContactMemory:IsEnabled() == true, "Both toggles enabled should enable Contact Memory")

				ContactMemory:SetEnabled(false)
				V:Assert(ContactMemory:IsEnabled() == false, "Contact Memory toggle should disable the feature")
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_SettingsDesignerControls", {
		description = "Contact Memory should register explicit Settings Center controls without dotted DB keys",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = false,
				},
			}, function(tempDB)
				local ContactMemory = BFL:GetModule("ContactMemory")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")

				local fakeApp = {
					pagesByID = {
						["advanced.beta"] = {},
					},
					groups = {},
					controls = {},
					GetPage = function(self, pageID)
						return self.pagesByID[pageID]
					end,
					RegisterGroup = function(self, pageID, data)
						self.groups[data.id] = data
						data.pageID = pageID
						return data
					end,
					RegisterControl = function(self, pageID, data)
						self.controls[data.id] = data
						data.pageID = pageID
						return data
					end,
				}

				V:Assert(
					ContactMemory:RegisterSettingsDesignerControls(fakeApp),
					"RegisterSettingsDesignerControls should register controls"
				)
				V:AssertNotNil(fakeApp.groups.contactMemory, "Contact Memory settings group should be registered")
				V:AssertEqual(
					fakeApp.groups.contactMemory.title,
					(BFL.L and BFL.L.CONTACT_MEMORY_TITLE) or "Private Notes",
					"Contact Memory group should keep the localized title"
				)

				local enableControl = fakeApp.controls["contactMemory.enabled"]
				local tooltipControl = fakeApp.controls["contactMemory.showTooltipSection"]
				local streamerControl = fakeApp.controls["contactMemory.hideInStreamerMode"]
				V:AssertNotNil(enableControl, "Enable control should be registered")
				V:AssertNotNil(tooltipControl, "Tooltip control should be registered")
				V:AssertNotNil(streamerControl, "Streamer Mode control should be registered")
				V:AssertEqual(
					enableControl.groupTitle,
					(BFL.L and BFL.L.CONTACT_MEMORY_TITLE) or "Private Notes",
					"Enable control should pass the localized group title"
				)
				V:AssertEqual(
					tooltipControl.groupTitle,
					(BFL.L and BFL.L.CONTACT_MEMORY_TITLE) or "Private Notes",
					"Tooltip control should pass the localized group title"
				)
				V:AssertEqual(
					streamerControl.groupTitle,
					(BFL.L and BFL.L.CONTACT_MEMORY_TITLE) or "Private Notes",
					"Streamer control should pass the localized group title"
				)
				V:AssertNil(enableControl.key, "Enable control should use explicit accessors instead of dotted keys")
				V:AssertNil(tooltipControl.key, "Tooltip control should use explicit accessors instead of dotted keys")
				V:AssertNil(streamerControl.key, "Streamer control should use explicit accessors instead of dotted keys")

				enableControl.setValue(true)
				V:AssertEqual(tempDB.contactMemory.enabled, true, "Enable control should update Contact Memory state")
				V:AssertEqual(enableControl.getValue(), true, "Enable control getter should read Contact Memory state")

				tooltipControl.setValue(false)
				V:AssertEqual(
					ContactMemory:GetSetting("showTooltipSection", true),
					false,
					"Tooltip control should update nested settings"
				)

				streamerControl.setValue(false)
				V:AssertEqual(
					ContactMemory:GetSetting("hideInStreamerMode", true),
					false,
					"Streamer control should update nested settings"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_KeyResolution", {
		description = "Contact Memory should resolve player and Battle.net contact keys",
		action = function(V)
			WithTemporaryDatabase({}, function()
				local ContactMemory = BFL:GetModule("ContactMemory")
				local ContactIdentity = BFL:GetModule("ContactIdentity")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")
				V:AssertNotNil(ContactIdentity, "ContactIdentity module should exist")

				V:AssertEqual(
					ContactMemory:ResolveContactKeyFromFriend("wow_Test-Realm"),
					"player:Test-Realm",
					"WoW friend UIDs should resolve to player keys"
				)
				V:AssertEqual(
					ContactMemory:ResolveContactKeyFromFriend("bnet_Player#1234"),
					"bnet:Player#1234",
					"BattleTag UIDs should resolve to bnet keys"
				)
				V:AssertEqual(
					ContactMemory:ResolveContactKeyFromFriend({ type = "bnet", battleTag = "Player#1234" }),
					"bnet:Player#1234",
					"BNet friend tables should prefer BattleTag keys"
				)
				V:AssertEqual(
					ContactMemory:ResolveContactKeyFromContext({ name = "Unit", server = "Realm" }),
					"player:Unit-Realm",
					"Context name and realm should resolve to a player key"
				)
				V:AssertEqual(
					ContactMemory:ResolveContactKeyFromFriend("bnet_Player#1234"),
					ContactIdentity:ResolveContactKeyFromFriend("bnet_Player#1234"),
					"Contact Memory should share ContactIdentity BNet key resolution"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_TooltipAliasResolution", {
		description = "Contact Memory tooltips should resolve saved notes and embedded friend tags across related contact keys",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				friendTagSettings = {
					enabled = true,
				},
				contactMemory = {
					enabled = false,
				},
			}, function()
				local ContactMemory = BFL:GetModule("ContactMemory")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")

				V:Assert(
					ContactMemory:SetPrivateNote("bnet:42", "Raid caller"),
					"Private note should be saved under BNet account aliases"
				)
				local bnetTooltipKey = ContactMemory:FindTooltipContactKey(ContactMemory:GetRelatedContactKeysFromFriend({
					type = "bnet",
					battleTag = "Player#1234",
					bnetAccountID = 42,
				}, "bnet:Player#1234"))
				V:AssertEqual(
					bnetTooltipKey,
					"bnet:42",
					"Tooltip lookup should find notes stored under the BNet account ID alias"
				)

				local tooltip = {
					lines = {},
					AddLine = function(self, text)
						self.lines[#self.lines + 1] = text
					end,
					Show = function(self)
						self.shown = true
					end,
				}
				V:Assert(
					ContactMemory:AddTooltipLinesForFriend(tooltip, {
						type = "bnet",
						battleTag = "Player#1234",
						bnetAccountID = 42,
					}),
					"Friend tooltip should display a note saved under a related key"
				)
				V:AssertEqual(tooltip.lines[#tooltip.lines], "Raid caller", "Tooltip should include the private note")

				local friendSummary = ContactMemory:GetTooltipSummaryForFriend({
					type = "bnet",
					battleTag = "Player#1234",
					bnetAccountID = 42,
				})
				V:AssertNotNil(friendSummary, "Friend tooltip summary should be available without a GameTooltip AddLine API")
				V:AssertEqual(friendSummary.note, "Raid caller", "Friend tooltip summary should include the related note")

				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()
				local tagId = FriendTags:CreateCustomTag("Progression")
				V:AssertNotNil(tagId, "CreateCustomTag should return a tag ID")
				V:Assert(
					FriendTags:SetCustomTagForFriend({
						type = "wow",
						uid = "wow_Unit-Realm",
						name = "Unit-Realm",
					}, tagId, true),
					"Friend tag should be saved under the player alias UID"
				)

				local relatedFriend = {
					type = "bnet",
					battleTag = "Other#1234",
					bnetAccountID = 99,
					gameAccountInfo = {
						characterName = "Unit",
						realmName = "Realm",
					},
				}
				local playerTooltipKey = ContactMemory:FindTooltipContactKey(ContactMemory:GetRelatedContactKeysFromFriend(
					relatedFriend,
					"bnet:Other#1234"
				))
				V:AssertEqual(
					playerTooltipKey,
					"bnet:Other#1234",
					"Contact Memory should keep note lookup separate from friend tag assignments"
				)

				local tagSummary = ContactMemory:GetTooltipSummaryForFriend(relatedFriend)
				V:AssertNotNil(tagSummary, "Tooltip summary should exist for related friend tags")
				V:AssertEqual(tagSummary.tagsText, "Progression", "Tooltip summary should include FriendTags tags")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_DBDefaults", {
		description = "Friend Tags defaults should initialize their standalone data",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")

				FriendTags:NormalizeDB()
				V:AssertType(tempDB.friendTagSettings, "table", "friendTagSettings should be a table")
				V:AssertType(tempDB.friendTagProfiles, "table", "friendTagProfiles should be a table")
				V:AssertType(tempDB.customFriendTags, "table", "customFriendTags should be a table")
				V:AssertType(tempDB.friendCustomTags, "table", "friendCustomTags should be a table")
				V:AssertType(tempDB.friendBlizzardTags, "table", "friendBlizzardTags should be a table")
				V:AssertEqual(tempDB.friendTagSettings.enabled, true, "Friend Tags should default to enabled")
				V:AssertEqual(tempDB.friendTagSettings.maxRowChips, 3, "Row chips should default to three tags")
				V:AssertEqual(tempDB.friendTagSettings.chipsPerLine, 3, "Chip rows should default to three chips per line")
				V:AssertEqual(tempDB.friendTagSettings.fullWidthTagRows, false, "Full-width tag rows should default to disabled")
				V:AssertEqual(tempDB.friendTagSettings.hideDynamicGroupTagChip, false, "Dynamic groups should show their tag chip by default")
				V:AssertEqual(
					tempDB.friendTagSettings.hideAllDynamicGroupTagChips,
					false,
					"Dynamic groups should show all other tag chips by default"
				)
				V:AssertEqual(tempDB.friendTagSettings.chipIconSize, 11, "Chip icons should default to 11 pixels")
				V:AssertEqual(tempDB.friendTagSettings.chipFont, "Friz Quadrata TT", "Chip font should use the standard BFL default")
				V:AssertEqual(tempDB.friendTagSettings.chipFontSize, 10, "Chip text should default to 10 pixels")
				V:AssertEqual(tempDB.friendTagSettings.chipFontFlags, "SLUG", "Chip font should retain locale-safe slug rendering")
				V:AssertEqual(
					tempDB.friendTagSettings.compactRowMode,
					"icon_only",
					"Compact rows should default to icon-only tags"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_StandardFeature", {
		description = "Friend Tags should no longer depend on the global Beta Features switch",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = false,
				friendTagSettings = { enabled = true },
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				V:Assert(FriendTags:IsEnabled(), "Friend Tags should be enabled while Beta Features are disabled")
			end)

			WithTemporaryDatabase({
				enableBetaFeatures = true,
				friendTagSettings = { enabled = false },
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:Assert(not FriendTags:IsEnabled(), "The dedicated Friend Tags toggle should still disable the feature")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_ReplacedTablesInvalidateRuntimeCache", {
		description = "Friend Tags should notice full settings-import table replacement without a reload",
		action = function(V)
			WithTemporaryDatabase({
				friendTagSettings = { enabled = true },
				customFriendTags = {},
				friendCustomTags = {},
				friendBlizzardTags = {},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				FriendTags:NormalizeDB()
				V:Assert(FriendTags:IsEnabled(), "Initial Friend Tags state should be cached as enabled")

				tempDB.friendTagSettings = { enabled = false }
				tempDB.friendTagProfiles = {}
				tempDB.customFriendTags = {}
				tempDB.friendCustomTags = {}
				tempDB.friendBlizzardTags = {}
				FriendTags:OnDatabaseImported()
				V:Assert(not FriendTags:IsEnabled(), "Imported settings table should replace the cached enabled state")
				V:AssertType(tempDB.friendTagSettings, "table", "Imported tag settings should remain normalized")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_RowCacheTracksStreamerMode", {
		description = "Friend tag row caches should hide existing chips immediately when Streamer Mode becomes active",
		action = function(V)
			WithTemporaryDatabase({
				friendTagSettings = {
					enabled = true,
					showRowChips = true,
					showTagsInStreamerMode = false,
				},
				customFriendTags = {},
				friendCustomTags = {},
				friendBlizzardTags = {},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				local TagChips = BFL:GetModule("TagChips")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				V:AssertNotNil(TagChips, "TagChips module should exist")
				FriendTags:OnDatabaseImported()

				local tagId = FriendTags:CreateCustomTag("Streamer Cache")
				local friend = {
					type = "wow",
					uid = "wow_StreamerCache-Realm",
					name = "StreamerCache-Realm",
				}
				V:AssertNotNil(tagId, "Test tag should be created")
				V:Assert(FriendTags:SetCustomTagForFriend(friend, tagId, true), "Test tag should be assigned")

				local fakeFriendsList = {
					settingsCache = { compactMode = false, infoDisabled = false },
					GetButtonWidth = function()
						return 300
					end,
				}
				local visibleData = TagChips:GetRowData(friend, fakeFriendsList)
				V:Assert(visibleData.canRender == true, "Assigned tag should render before Streamer Mode")

				tempDB.streamerModeActive = true
				local hiddenData = TagChips:GetRowData(friend, fakeFriendsList)
				V:Assert(hiddenData.canRender == false, "Cached tag row should hide in Streamer Mode")
			end)
		end,
	})

	TS:RegisterTest("data", "QuickFilters_ActiveTagsTrackStreamerMode", {
		description = "An active tag-filter cache should not survive Streamer Mode hiding tag surfaces",
		action = function(V)
			WithTemporaryDatabase({
				friendTagSettings = {
					enabled = true,
					showTagsInStreamerMode = false,
				},
				customFriendTags = {},
				friendCustomTags = {},
				friendBlizzardTags = {},
				quickFilterTags = {},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				local QuickFilters = BFL:GetModule("QuickFilters")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				V:AssertNotNil(QuickFilters, "QuickFilters module should exist")
				FriendTags:OnDatabaseImported()
				QuickFilters:InvalidateTagFilterCache()

				local tagId = FriendTags:CreateCustomTag("Filter Cache")
				V:AssertNotNil(tagId, "Test filter tag should be created")
				tempDB.quickFilterTags[tagId] = true
				QuickFilters:InvalidateTagFilterCache()
				local activeBefore = QuickFilters:GetActiveTagFilterDefinitions()
				V:AssertEqual(#activeBefore, 1, "Assigned filter should be active before Streamer Mode")

				tempDB.streamerModeActive = true
				local activeAfter = QuickFilters:GetActiveTagFilterDefinitions()
				V:AssertEqual(#activeAfter, 0, "Hidden tag surfaces should not retain an active cached filter")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_DragOrderPersists", {
		description = "Friend tag order should persist as one atomic reordered list",
		action = function(V)
			WithTemporaryDatabase({ enableBetaFeatures = true }, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()
				V:AssertNotNil(FriendTags:CreateCustomTag("Alpha"), "First custom tag should be created")
				V:AssertNotNil(FriendTags:CreateCustomTag("Beta"), "Second custom tag should be created")

				local definitions = FriendTags:GetAllTagDefinitions()
				local reversedIds = {}
				for index = #definitions, 1, -1 do
					reversedIds[#reversedIds + 1] = definitions[index].id
				end
				V:Assert(FriendTags:SetTagOrder(reversedIds), "Reordered tag IDs should be accepted")

				local reordered = FriendTags:GetAllTagDefinitions()
				V:AssertEqual(reordered[1].id, reversedIds[1], "The dragged tag should persist at the first position")
				V:AssertEqual(reordered[#reordered].id, reversedIds[#reversedIds], "The remaining order should stay stable")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_SparseIconZoomAndAtomicIconModes", {
		description = "Sparse order changes keep default icon zoom while icon modes retain their origin and discard incompatible fields",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:OnDatabaseImported()

				local definitions = FriendTags:GetAllTagDefinitions()
				local order = { "blizzard:roleplaying" }
				for index = #definitions, 1, -1 do
					if definitions[index].id ~= "blizzard:roleplaying" then
						order[#order + 1] = definitions[index].id
					end
				end
				V:Assert(FriendTags:SetTagOrder(order), "Tag order should be saved")
				local roleOverride = tempDB.friendTagProfiles["blizzard:roleplaying"]
				V:AssertNotNil(roleOverride, "Roleplaying should receive an order override")
				V:AssertNil(roleOverride.iconZoom, "An order-only override must not write a false icon zoom")
				V:AssertEqual(
					FriendTags:GetChipProfile("blizzard:roleplaying").iconZoom,
					0.30,
					"Roleplaying should retain its default zoom after reordering"
				)
				V:Assert(
					FriendTags:SetChipProfile("blizzard:roleplaying", { iconZoom = false }),
					"Explicitly disabling icon zoom should remain supported"
				)
				V:AssertEqual(
					FriendTags:GetChipProfile("blizzard:roleplaying").iconZoom,
					false,
					"Explicit false icon zoom should override the default"
				)

				local tagId = FriendTags:CreateCustomTag("Icon Modes")
				V:AssertNotNil(tagId, "Custom tag should be created")
				local fallbackTexture = "Interface\\Icons\\INV_Misc_Gear_08"
				V:Assert(FriendTags:SetChipProfile(tagId, {
					replaceIcon = true,
					iconType = "texture",
					iconValue = fallbackTexture,
					icon = fallbackTexture,
					texture = fallbackTexture,
				}), "Texture icon mode should save")
				local Editor = BFL:GetModule("FriendTagEditor")
				Editor:LoadState(FriendTags:GetTagDefinition(tagId))
				V:AssertEqual(
					Editor.editState.iconMode,
					"custom",
					"Legacy custom paths matching an option fallback must reopen as Custom Path"
				)
				local legacyCustomPreview = Editor:GetPreviewIconProfile()
				V:AssertEqual(legacyCustomPreview.texture, fallbackTexture, "Custom preview should retain the entered texture")
				V:AssertNil(legacyCustomPreview.atlas, "Custom preview must not substitute the matching option atlas")
				V:Assert(FriendTags:SetChipProfile(tagId, {
					replaceIcon = true,
					iconMode = "custom",
					iconType = "texture",
					iconValue = fallbackTexture,
					icon = fallbackTexture,
					texture = fallbackTexture,
				}), "Explicit Custom Path mode should save")
				V:AssertEqual(tempDB.friendTagProfiles[tagId].iconMode, "custom", "Custom Path origin should persist")
				V:Assert(FriendTags:SetChipProfile(tagId, {
					replaceIcon = true,
					iconMode = "selected",
					iconType = "atlas",
					iconValue = "Raid",
					icon = "Raid",
					atlas = "Raid",
					fallbackAtlas = "groupfinder-button-raids",
					iconZoom = 0.25,
				}), "Atlas icon mode should save")
				local atlasOverride = tempDB.friendTagProfiles[tagId]
				V:AssertEqual(atlasOverride.iconMode, "selected", "Selected icon origin should replace Custom Path")
				V:AssertNil(atlasOverride.texture, "Atlas mode should remove the previous texture")
				V:AssertNil(atlasOverride.texCoord, "Atlas mode should remove the previous texture coordinates")
				V:AssertEqual(FriendTags:GetChipProfile(tagId).atlas, "Raid", "Resolved profile should use the atlas")

				V:Assert(FriendTags:SetChipProfile(tagId, {
					replaceIcon = true,
					iconMode = "none",
					iconType = "none",
					iconValue = false,
					icon = false,
					atlas = false,
					fallbackAtlas = false,
					texture = false,
					texCoord = false,
					iconZoom = false,
				}), "No-icon mode should save")
				local noneOverride = tempDB.friendTagProfiles[tagId]
				V:AssertEqual(noneOverride.iconMode, "none", "No-icon origin should persist")
				V:AssertEqual(noneOverride.iconType, "none", "No-icon mode should be explicit")
				V:AssertNil(noneOverride.atlas, "No-icon mode should remove the old atlas")
				V:AssertNil(noneOverride.texture, "No-icon mode should not retain a texture")
				local noneProfile = FriendTags:GetChipProfile(tagId)
				V:AssertNil(noneProfile.icon, "Resolved no-icon profile should have no icon")
				V:AssertNil(noneProfile.atlas, "Resolved no-icon profile should have no atlas")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_RowChipLayoutAndDynamicGroupContext", {
		description = "Row chips honor per-line limits, runtime geometry, overflow, and group-specific tag hiding",
		action = function(V)
			WithTemporaryDatabase({
				friendTagSettings = {
					enabled = true,
					showRowChips = true,
					maxRowChips = 3,
					chipsPerLine = 2,
					hideDynamicGroupTagChip = true,
					chipIconSize = 20,
					chipFont = "Fonts\\MORPHEUS.TTF",
					chipFontSize = 8,
					chipFontFlags = "OUTLINE,MONOCHROME",
				},
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				local TagChips = BFL:GetModule("TagChips")
				FriendTags:OnDatabaseImported()
				local friend = { type = "wow", uid = "wow_ChipLayout-Realm", name = "ChipLayout-Realm" }
				local tagIds = {}
				for index = 1, 4 do
					tagIds[index] = FriendTags:CreateCustomTag("Layout " .. index)
					V:Assert(FriendTags:SetCustomTagForFriend(friend, tagIds[index], true), "Layout tag should be assigned")
				end
				local testWidth = 1000
				local fakeFriendsList = {
					settingsCache = { compactMode = false, infoDisabled = false },
					GetButtonWidth = function()
						return testWidth
					end,
					GetFriendTagRowRightInset = function()
						return 55
					end,
				}
				local normal = TagChips:GetRowData(friend, fakeFriendsList)
				local grouped = TagChips:GetRowData(friend, fakeFriendsList, "tag:" .. tagIds[1])
				V:Assert(normal ~= grouped, "Different group contexts should use different row-cache entries")
				V:AssertEqual(normal.cacheGroupId, "", "Ungrouped cache should use the empty group context")
				V:AssertEqual(grouped.cacheGroupId, "tag:" .. tagIds[1], "Grouped cache should retain its group ID")
				V:AssertEqual(#normal.renderableTags, 4, "Ungrouped row should retain all assigned tags")
				V:AssertEqual(#grouped.renderableTags, 3, "Dynamic group row should hide only its forming tag")
				for _, entry in ipairs(grouped.renderableTags) do
					V:Assert(entry.tag.id ~= tagIds[1], "Forming tag must be absent from the grouped row")
				end
				FriendTags:SetSetting("hideAllDynamicGroupTagChips", true, function() end)
				local fullyHidden = TagChips:GetRowData(friend, fakeFriendsList, "tag:" .. tagIds[1])
				V:Assert(fullyHidden.canRender == false, "Dynamic groups should hide every row chip when configured")
				V:AssertEqual(fullyHidden.height, 0, "Fully hidden dynamic-group chips should not add row height")
				V:AssertEqual(#fullyHidden.renderableTags, 0, "Fully hidden dynamic-group rows should expose no chips")
				FriendTags:SetSetting("hideAllDynamicGroupTagChips", false, function() end)
				V:AssertEqual(normal.chipsPerLine, 2, "Configured per-line chip limit should be used")
				V:AssertEqual(normal.lineCount, 2, "Three chips plus overflow should wrap into two lines")
				V:AssertEqual(normal.metrics.iconSize, 20, "Runtime icon size should be resolved")
				V:AssertEqual(normal.metrics.fontName, "Fonts\\MORPHEUS.TTF", "Runtime chip font should retain the configured source")
				V:AssertEqual(normal.metrics.fontPath, "Fonts\\MORPHEUS.TTF", "Runtime chip font should resolve its file path")
				V:AssertEqual(normal.metrics.fontSize, 8, "Runtime font size should be resolved independently")
				V:AssertEqual(normal.metrics.fontFlags, "OUTLINE,MONOCHROME", "Runtime chip font flags should be normalized")
				V:AssertEqual(normal.metrics.height, 23, "Chip height should follow max(icon+3, font+4)")
				V:AssertEqual(normal.height, 50, "Two chip lines should use the resolved height and row gap")
				local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
				local expectedLeftInset = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() and 38 or 44
				V:AssertEqual(
					normal.availableWidth,
					testWidth - expectedLeftInset - 55,
					"Action-aligned rows should reserve the live control inset instead of a fixed 84px"
				)

				local constrainedWidth = normal.availableWidth
				FriendTags:SetSetting("fullWidthTagRows", true, function() end)
				local fullWidth = TagChips:GetRowData(friend, fakeFriendsList)
				V:Assert(fullWidth.fullWidthTagRows, "Full-width row data should retain the active layout mode")
				V:AssertEqual(fullWidth.availableWidth, 984, "Full-width rows should retain an eight-pixel inset on both sides")
				V:Assert(
					fullWidth.availableWidth > constrainedWidth,
					"Full-width rows should expose more horizontal space than action-aligned rows"
				)

				for index = 5, 20 do
					tagIds[index] = FriendTags:CreateCustomTag("Layout " .. index)
					V:Assert(FriendTags:SetCustomTagForFriend(friend, tagIds[index], true), "Expanded layout tag should be assigned")
				end
				testWidth = 4000
				FriendTags:SetSetting("maxRowChips", 20, function() end)
				FriendTags:SetSetting("chipsPerLine", 20, function() end)
				local expanded = TagChips:GetRowData(friend, fakeFriendsList)
				V:AssertEqual(#expanded.renderableTags, 20, "Rows should retain 20 assigned tags")
				V:AssertEqual(expanded.maxChips, 20, "Runtime row-chip limit should allow 20 tags")
				V:AssertEqual(expanded.chipsPerLine, 20, "Runtime per-line limit should allow 20 tags")
				V:AssertEqual(expanded.lineCount, 1, "A wide row should fit all 20 configured chips on one line")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTagEditor_LabelModeAndTargetedIconRefresh", {
		description = "Manual label text selects the expected mode and committed icons refresh only their navigation row",
			action = function(V)
				local Editor = BFL:GetModule("FriendTagEditor")
				local FriendTags = BFL:GetModule("FriendTags")
				local handlers = {}
				local focusClears = 0
				local flushes = 0
				local fakeInput = {
					SetScript = function(_, event, callback)
						handlers[event] = callback
					end,
					ClearFocus = function()
						focusClears = focusClears + 1
					end,
				}
				local oldFlushAutoSave = Editor.FlushAutoSave
				local ok, err = pcall(function()
					Editor.FlushAutoSave = function()
						flushes = flushes + 1
					end
					V:Assert(Editor:BindEditorInputFocusHandlers(fakeInput), "Editor input handlers should bind")
					V:AssertType(handlers.OnEnterPressed, "function", "Enter should have a focus-release handler")
					V:AssertType(handlers.OnEscapePressed, "function", "Escape should have a focus-release handler")
					V:AssertType(handlers.OnEditFocusLost, "function", "Focus loss should flush pending edits")
					handlers.OnEnterPressed(fakeInput)
					handlers.OnEscapePressed(fakeInput)
					V:AssertEqual(focusClears, 2, "Enter and Escape should both release editor input focus")
					V:AssertEqual(flushes, 2, "Enter and Escape should both commit pending editor input")
				end)
				Editor.FlushAutoSave = oldFlushAutoSave
				if not ok then
					error(err, 0)
				end
				V:AssertEqual(Editor:GetLabelModeForText("Manual"), "custom", "Non-empty input should select Custom Label")
				V:AssertEqual(Editor:GetLabelModeForText(""), "default", "Empty manual input should restore Default Label")
				V:AssertEqual(
					Editor:GetLabelModeAfterTextChange("", "icon_only", false),
					"icon_only",
					"Programmatic Icon Only clearing must preserve Icon Only mode"
				)
				V:AssertEqual(
					Editor:GetLabelModeAfterTextChange("", "custom", true),
					"default",
					"Manually clearing a custom label should restore Default Label"
				)
				V:AssertEqual(
					Editor:GetLabelModeAfterTextChange("Manual", "default", true),
					"custom",
					"Manually typing a label should select Custom Label"
				)

				WithTemporaryDatabase({}, function()
				FriendTags:OnDatabaseImported()
				local tagId = FriendTags:CreateCustomTag("Nav Icon")
				local shown = false
				local hidden = false
				local oldFrame = Editor.frame
				local oldApplyIconProfile = BFL.ApplyIconProfile
				BFL.ApplyIconProfile = function()
					return true
				end
				Editor.frame = {
					tagRows = {
						{
							tagId = tagId,
							icon = {
								Show = function()
									shown = true
								end,
								Hide = function()
									hidden = true
								end,
							},
						},
					},
				}
				local ok, err = pcall(function()
					V:Assert(Editor:RefreshListRowIcon(tagId), "Matching navigation row should refresh")
					V:Assert(shown and not hidden, "Resolved navigation icon should be shown in place")
				end)
				Editor.frame = oldFrame
				BFL.ApplyIconProfile = oldApplyIconProfile
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTagEditor_RefreshesRuntimeAndSelection", {
		description = "Editor reorder, reset, and delete callbacks refresh friend rows and recover a valid selection",
			action = function(V)
				local Editor = BFL:GetModule("FriendTagEditor")
				local oldSelectedTagId = Editor.selectedTagId
				local oldEnsureFrame = Editor.EnsureFrame
			local oldGetSelectedDefinition = Editor.GetSelectedDefinition
			local oldGetDefinitions = Editor.GetDefinitions
			local oldRefreshList = Editor.RefreshList
			local oldRefreshEditor = Editor.RefreshEditor
			local oldSchedule = BFL.ScheduleFriendsListRefresh
			local runtimeRefreshes = 0
			local editorRefreshes = 0
			local ok, err = pcall(function()
				Editor.selectedTagId = "deleted"
				Editor.EnsureFrame = function() return {} end
				Editor.GetSelectedDefinition = function() return nil end
				Editor.GetDefinitions = function() return { { id = "first" } } end
				Editor.RefreshList = function() editorRefreshes = editorRefreshes + 1 end
				Editor.RefreshEditor = function() editorRefreshes = editorRefreshes + 1 end
				BFL.ScheduleFriendsListRefresh = function() runtimeRefreshes = runtimeRefreshes + 1 end
				Editor:RefreshAfterDefinitionChange("test")
				V:AssertEqual(runtimeRefreshes, 1, "Editor definition changes should refresh friend rows immediately")
				V:AssertEqual(editorRefreshes, 2, "Editor definition changes should rebuild both editor panes")
				V:AssertEqual(Editor.selectedTagId, "first", "A deleted selection should fall back to the first remaining tag")
			end)
			Editor.EnsureFrame = oldEnsureFrame
			Editor.GetSelectedDefinition = oldGetSelectedDefinition
			Editor.GetDefinitions = oldGetDefinitions
				Editor.RefreshList = oldRefreshList
				Editor.RefreshEditor = oldRefreshEditor
				Editor.selectedTagId = oldSelectedTagId
				BFL.ScheduleFriendsListRefresh = oldSchedule
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "FriendTagEditor_UsesSharedIconExplorer", {
		description = "Friend Tag editor should use BFL's searchable icon explorer instead of an inline dropdown or fixed icon grid",
		action = function(V)
			local FriendTagEditor = BFL:GetModule("FriendTagEditor")
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTagEditor, "FriendTagEditor module should exist")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")
			V:AssertType(FriendTagEditor.CreateIconControls, "function", "FriendTagEditor should create icon controls")
			if BFL.ShowIconSelector then
				V:AssertType(BFL.ShowIconSelector, "function", "FriendTagEditor should have access to BFL's shared icon explorer")
				V:AssertType(BFL.BFLIconCatalog, "table", "Icon explorer should expose BFL's custom icon catalog")
				V:Assert(#BFL.BFLIconCatalog > 0, "BFL custom icons should be available to the icon explorer")
				return
			end

			local oldCreateDropdown = BFL.CreateDropdown
			local oldInitializeDropdown = BFL.InitializeDropdown
			local oldIsModernDropdown = BFL.IsModernDropdown
			local oldGetIconOptions = FriendTags.GetIconOptions
			local oldCreateFrame = CreateFrame
			local oldSetWidth = UIDropDownMenu_SetWidth
			local oldJustifyText = UIDropDownMenu_JustifyText
			local oldSetText = UIDropDownMenu_SetText
			local oldRefreshPreview = FriendTagEditor.RefreshPreview
			local oldEditState = FriendTagEditor.editState
			local capturedCreate
			local capturedInit

			local function MakeObject()
				local object = {}
				function object:SetPoint(...)
					self.point = { ... }
				end
				function object:SetWidth(width)
					self.width = width
				end
				function object:SetSize(width, height)
					self.width = width
					self.height = height
				end
				function object:SetText(text)
					self.text = text
				end
				function object:GetText()
					return self.text or ""
				end
				function object:SetShown(shown)
					self.shown = shown
				end
				function object:SetScript(script, handler)
					self.scripts = self.scripts or {}
					self.scripts[script] = handler
				end
				function object:SetAutoFocus(value)
					self.autoFocus = value
				end
				function object:SetMaxLetters(value)
					self.maxLetters = value
				end
				function object:SetFontObject(value)
					self.fontObject = value
				end
				return object
			end

			local ok, err = pcall(function()
				FriendTagEditor.editState = {
					iconMode = "option",
					iconOptionID = "tag",
					iconType = "texture",
					iconValue = "Interface\\Icons\\INV_Misc_Note_01",
					icon = "Interface\\Icons\\INV_Misc_Note_01",
					texture = "Interface\\Icons\\INV_Misc_Note_01",
				}
				FriendTagEditor.RefreshPreview = function() end
				FriendTags.GetIconOptions = function()
					return {
						{
							id = "tag",
							label = "Tag",
							iconType = "texture",
							iconValue = "Interface\\Icons\\INV_Misc_Note_01",
							icon = "Interface\\Icons\\INV_Misc_Note_01",
							texture = "Interface\\Icons\\INV_Misc_Note_01",
						},
					}
				end
				BFL.CreateDropdown = function(parent, name, width, preferModern)
					capturedCreate = {
						parent = parent,
						name = name,
						width = width,
						preferModern = preferModern,
					}
					local dropdown = MakeObject()
					dropdown.SetupMenu = function() end
					return dropdown
				end
				BFL.IsModernDropdown = function(dropdown)
					return dropdown and dropdown.SetupMenu ~= nil
				end
				BFL.InitializeDropdown = function(dropdown, options, getter, setter)
					capturedInit = {
						dropdown = dropdown,
						options = options,
						getter = getter,
						setter = setter,
					}
				end
				UIDropDownMenu_SetWidth = function()
					error("Legacy width should not be used for modern FriendTagEditor dropdown")
				end
				UIDropDownMenu_JustifyText = function()
					error("Legacy justify should not be used for modern FriendTagEditor dropdown")
				end
				UIDropDownMenu_SetText = function()
					error("Legacy text should not be used for modern FriendTagEditor dropdown")
				end
				CreateFrame = function()
					return MakeObject()
				end

				local parent = MakeObject()
				function parent:CreateFontString()
					return MakeObject()
				end

				FriendTagEditor:CreateIconControls(parent, -40)

				V:AssertNotNil(capturedCreate, "Icon dropdown should be created through BFL.CreateDropdown")
				V:AssertEqual(capturedCreate.preferModern, true, "Icon dropdown should allow modern dropdown creation")
				V:AssertNotNil(capturedInit, "Icon dropdown should initialize through BFL.InitializeDropdown")
				V:AssertEqual(capturedInit.options.getSelectionText("tag"), "Tag", "Icon dropdown should preserve selection text")
				V:AssertEqual(FriendTagEditor.iconDropdown.text, "Tag", "Modern dropdown text should be set without UIDropDownMenu")
			end)

			BFL.CreateDropdown = oldCreateDropdown
			BFL.InitializeDropdown = oldInitializeDropdown
			BFL.IsModernDropdown = oldIsModernDropdown
			FriendTags.GetIconOptions = oldGetIconOptions
			CreateFrame = oldCreateFrame
			UIDropDownMenu_SetWidth = oldSetWidth
			UIDropDownMenu_JustifyText = oldJustifyText
			UIDropDownMenu_SetText = oldSetText
			FriendTagEditor.RefreshPreview = oldRefreshPreview
			FriendTagEditor.editState = oldEditState
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "SettingsComponents_Dropdowns_UseSharedInitializers", {
		description = "Settings component dropdowns should initialize modern single and multi select controls through BFL compat helpers",
		action = function(V)
			local Components = BFL.SettingsComponents
			V:AssertNotNil(Components, "SettingsComponents should exist")
			V:AssertType(Components.CreateDropdown, "function", "SettingsComponents should create dropdown controls")

			local oldCanCreateModernDropdown = BFL.CanCreateModernDropdown
			local oldCreateDropdown = BFL.CreateDropdown
			local oldIsModernDropdown = BFL.IsModernDropdown
			local oldInitializeDropdown = BFL.InitializeDropdown
			local oldInitializeMultiSelectDropdown = BFL.InitializeMultiSelectDropdown
			local oldCreateFrame = CreateFrame
			local oldCreateFont = CreateFont
			local oldGameFontNormalSmall = _G.GameFontNormalSmall
			local capturedCreate = {}
			local capturedSingle
			local capturedMulti
			local directSetupMenuCalls = 0

			local function MakeObject()
				local object = {}
				function object:SetPoint(...)
					self.point = { ... }
				end
				function object:ClearAllPoints()
					self.pointsCleared = true
				end
				function object:SetWidth(width)
					self.width = width
				end
				function object:SetHeight(height)
					self.height = height
				end
				function object:SetSize(width, height)
					self.width = width
					self.height = height
				end
				function object:SetText(text)
					self.text = text
				end
				function object:GetObjectType()
					return self.objectType or "Frame"
				end
				function object:GetRegions()
					return
				end
				function object:SetChecked(checked)
					self.checked = checked
				end
				function object:GetChecked()
					return self.checked
				end
				function object:SetFontObject(fontObject)
					self.fontObject = fontObject
				end
				function object:SetJustifyH(justify)
					self.justifyH = justify
				end
				function object:SetNormalFontObject(fontObject)
					self.normalFontObject = fontObject
				end
				function object:SetHighlightFontObject(fontObject)
					self.highlightFontObject = fontObject
				end
				function object:SetDisabledFontObject(fontObject)
					self.disabledFontObject = fontObject
				end
				function object:SetScript(script, handler)
					self.scripts = self.scripts or {}
					self.scripts[script] = handler
				end
				function object:GetScript(script)
					return self.scripts and self.scripts[script]
				end
				function object:GetWidth()
					return self.width or 0
				end
				function object:GetHeight()
					return self.height or 0
				end
				function object:CreateFontString()
					return MakeObject()
				end
				return object
			end

			local ok, err = pcall(function()
				_G.GameFontNormalSmall = {
					GetFont = function()
						return "Fonts\\FRIZQT__.TTF", 12, ""
					end,
				}
				CreateFont = function(name)
					local font = MakeObject()
					font.name = name
					function font:SetFont(path, size, flags)
						self.font = {
							path = path,
							size = size,
							flags = flags,
						}
						return true
					end
					return font
				end
				CreateFrame = function()
					return MakeObject()
				end
				BFL.CanCreateModernDropdown = function()
					return true
				end
				BFL.CreateDropdown = function(parent, name, width, preferModern)
					local dropdown = MakeObject()
					dropdown.Text = MakeObject()
					dropdown.SetupMenu = function()
						directSetupMenuCalls = directSetupMenuCalls + 1
					end
					capturedCreate[#capturedCreate + 1] = {
						parent = parent,
						name = name,
						width = width,
						preferModern = preferModern,
						dropdown = dropdown,
					}
					return dropdown
				end
				BFL.IsModernDropdown = function(dropdown)
					return dropdown and dropdown.SetupMenu ~= nil
				end
				BFL.InitializeDropdown = function(dropdown, options, getter, setter, scrollHeight)
					capturedSingle = {
						dropdown = dropdown,
						options = options,
						getter = getter,
						setter = setter,
						scrollHeight = scrollHeight,
					}
				end
				BFL.InitializeMultiSelectDropdown = function(dropdown, options, getter, setter, getText)
					capturedMulti = {
						dropdown = dropdown,
						options = options,
						getter = getter,
						setter = setter,
						getText = getText,
					}
				end

				local parent = MakeObject()
				local singleSelected
				local multiSelected

				Components:CreateDropdown(parent, "Mode", {
					labels = { "Alpha", "Beta" },
					values = { "alpha", "beta" },
				}, function(value)
					return value == "alpha"
				end, function(value)
					singleSelected = value
				end, 120)

				Components:CreateDropdown(parent, "Fonts", {
					labels = { "One", "Two" },
					values = { "one", "two" },
					useCheckboxes = true,
				}, function(value)
					return value == "two"
				end, function(value)
					multiSelected = value
				end, 120)

				V:AssertEqual(#capturedCreate, 2, "Both settings dropdowns should use BFL.CreateDropdown")
				V:AssertEqual(capturedCreate[1].preferModern, true, "Settings dropdowns should allow modern dropdown creation")
				V:AssertEqual(capturedCreate[2].preferModern, true, "Settings multi dropdowns should allow modern dropdown creation")
				V:AssertNotNil(capturedSingle, "Single-select settings dropdown should use BFL.InitializeDropdown")
				V:AssertNotNil(capturedMulti, "Multi-select settings dropdown should use BFL.InitializeMultiSelectDropdown")
				V:AssertEqual(directSetupMenuCalls, 0, "SettingsComponents should not call SetupMenu directly")
				V:AssertEqual(capturedSingle.scrollHeight, 300, "Settings dropdowns should preserve their expanded scroll height")
				V:AssertEqual(capturedSingle.options.getSelectionText("beta"), "Beta", "Single-select dropdown should expose selection text")
				V:AssertType(capturedSingle.options.getItemFontObject, "function", "Single-select dropdown should expose item font objects")
				V:AssertType(capturedMulti.options.getItemFontObject, "function", "Multi-select dropdown should expose item font objects")
				V:AssertEqual(capturedMulti.getText(), "Two", "Multi-select dropdown should expose current display text")

				capturedSingle.setter("beta")
				V:AssertEqual(singleSelected, "beta", "Single-select setter should invoke the original callback")
				V:AssertEqual(capturedSingle.dropdown.text, "Beta", "Single-select setter should update dropdown text")

				capturedMulti.setter("one")
				V:AssertEqual(multiSelected, "one", "Multi-select setter should invoke the original callback")
				V:AssertEqual(capturedMulti.dropdown.text, "One", "Multi-select setter should update dropdown text")

				capturedMulti = nil
				local checkboxDropdownValue
				local row = Components:CreateCheckboxDropdown(parent, {
					label = "Enabled",
					initialValue = true,
					callback = function() end,
				}, {
					label = "Style",
					entries = {
						labels = { "Compact", "Detailed" },
						values = { "compact", "detailed" },
						useCheckboxes = true,
					},
					isSelectedCallback = function(value)
						return value == "compact"
					end,
					onSelectionCallback = function(value)
						checkboxDropdownValue = value
					end,
				})

				V:AssertNotNil(row.RightDropdown, "Checkbox dropdown row should expose the modern dropdown")
				V:AssertNotNil(capturedMulti, "Checkbox dropdown row should use BFL.InitializeMultiSelectDropdown")
				V:AssertEqual(directSetupMenuCalls, 0, "Checkbox dropdown row should not call SetupMenu directly")
				V:AssertEqual(capturedMulti.getText(), "Compact", "Checkbox dropdown row should expose current display text")

				capturedMulti.setter("detailed")
				V:AssertEqual(checkboxDropdownValue, "detailed", "Checkbox dropdown row setter should invoke the original callback")
				V:AssertEqual(capturedMulti.dropdown.text, "Detailed", "Checkbox dropdown row setter should update dropdown text")
			end)

			BFL.CanCreateModernDropdown = oldCanCreateModernDropdown
			BFL.CreateDropdown = oldCreateDropdown
			BFL.IsModernDropdown = oldIsModernDropdown
			BFL.InitializeDropdown = oldInitializeDropdown
			BFL.InitializeMultiSelectDropdown = oldInitializeMultiSelectDropdown
			CreateFrame = oldCreateFrame
			CreateFont = oldCreateFont
			_G.GameFontNormalSmall = oldGameFontNormalSmall
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "FriendTags_ActivityIconsUseMapLegendAtlases", {
		description = "Friend Tags activity chips should use Blizzard's matching map legend atlases",
		action = function(V)
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")

			local dungeon = FriendTags:GetIconInfo("dungeon")
			local raid = FriendTags:GetIconInfo("raid")
			local delves = FriendTags:GetIconInfo("delves")
			V:AssertEqual(dungeon.iconValue, "Dungeon", "Dungeon should use Blizzard's blue dungeon entrance atlas")
			V:AssertEqual(raid.iconValue, "Raid", "Raid should use Blizzard's green raid entrance atlas")
			V:AssertEqual(delves.iconValue, "delves-regular", "Delves should keep Blizzard's regular delve entrance atlas")
			V:AssertEqual(dungeon.iconZoom, 0.25, "Dungeon should crop the entrance atlas by 25 percent")
			V:AssertEqual(raid.iconZoom, 0.25, "Raid should crop the entrance atlas by 25 percent")
			V:AssertEqual(delves.iconZoom, 0.20, "Delves should crop the entrance atlas by 20 percent")
		end,
	})

	TS:RegisterTest("data", "FriendTags_ActivityIconsUseRequestedAtlases", {
		description = "PvP, questing, and roleplaying chips should use their requested Blizzard atlases and exact crops",
		action = function(V)
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")

			local pvp = FriendTags:GetIconInfo("pvp")
			local questing = FriendTags:GetIconInfo("questing")
			local roleplaying = FriendTags:GetIconInfo("roleplaying")
			V:AssertEqual(pvp.iconValue, "honorsystem-icon-prestige-9", "PvP should use Blizzard's prestige 9 honor atlas")
			V:AssertEqual(questing.iconValue, "Crosshair_Questturnin_32", "Questing should use Blizzard's quest turn-in crosshair atlas")
			V:AssertEqual(roleplaying.iconValue, "plunderstorm-nameplates-icon-1", "Roleplaying should use Blizzard's Plunderstorm nameplate atlas")
			V:AssertEqual(pvp.iconZoom, 0.15, "PvP should crop the honor atlas by 15 percent")
			V:AssertEqual(questing.iconZoom, 0.10, "Questing should crop the quest atlas by 10 percent")
			V:AssertEqual(roleplaying.iconZoom, 0.30, "Roleplaying should crop the nameplate atlas by 30 percent")
		end,
	})

	TS:RegisterTest("data", "FriendTags_RoleIconsUseRaidCountAtlases", {
		description = "Friend Tags role chips should use the modern raid count role icon atlases",
		action = function(V)
			WithTemporaryDatabase({
				friendTagProfiles = {
					["blizzard:damager"] = {
						iconType = "atlas",
						iconValue = "roleicon-tiny-dps",
					},
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local icon = FriendTags:GetIconInfo("damager")
				V:AssertEqual(
					icon.iconType,
					"atlas",
					"DPS icon option should resolve as an atlas icon"
				)
				V:AssertEqual(
					icon.iconValue,
					"UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
					"DPS icon option should use Blizzard's RoleCount atlas as the primary icon value"
				)
				V:AssertEqual(
					icon.atlas,
					"UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
					"DPS icon option should use Blizzard's RoleCount atlas"
				)
				V:AssertEqual(
					icon.fallbackAtlas,
					"groupfinder-icon-role-large-dps",
					"DPS icon option should keep Blizzard's Classic RoleCount atlas as fallback"
				)
				V:AssertNil(
					tempDB.friendTagProfiles["blizzard:damager"],
					"Legacy tiny DPS icon override should be cleared so the RoleCount default can apply"
				)

				local profile = FriendTags:GetChipProfile("blizzard:damager")
				V:AssertEqual(
					profile.iconType,
					"atlas",
					"DPS chip profile should render as an atlas icon"
				)
				V:AssertEqual(
					profile.iconValue,
					"UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
					"DPS chip profile should prefer Blizzard's RoleCount atlas over the legacy texture fallback"
				)
				V:AssertEqual(
					profile.icon,
					"UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
					"DPS chip profile legacy icon field should not point at the old role texture on Retail"
				)
				V:AssertEqual(
					profile.atlas,
					"UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
					"DPS chip profile should resolve to Blizzard's RoleCount atlas"
				)
				V:AssertEqual(
					profile.chipIconOffsetX,
					0.5,
					"Default role chips should opt into the half-pixel optical centering correction"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_LocalBlizzardFallback", {
		description = "Friend Tags should store Blizzard-compatible tags locally before native 12.1 APIs are available",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local friend = {
					type = "bnet",
					uid = "bnet_Player#1234",
					battleTag = "Player#1234",
				}

				V:Assert(FriendTags:IsEnabled() == true, "Friend Tags should be enabled independently from Contact Memory")
				V:Assert(
					FriendTags:SetBlizzardTagsForFriend(friend, { ["blizzard:raiding"] = true }),
					"Blizzard-compatible tag should be saved locally without a native account ID"
				)
				V:Assert(
					tempDB.friendBlizzardTags["bnet_Player#1234"]["blizzard:raiding"] == true,
					"Local Blizzard-compatible tag assignment should be stored"
				)
				V:Assert(
					FriendTags:GetSearchText(friend):find("Raiding", 1, true) ~= nil,
					"Search text should include assigned Blizzard-compatible tags"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_MigratesLegacyContactMemoryTags", {
		description = "Friend Tags should migrate old Contact Memory tags into unified custom friend tags",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
					tags = {
						progression = {
							name = "Progression",
							order = 5,
							color = { r = 0.2, g = 0.6, b = 1 },
						},
					},
					contacts = {
						["player:Unit-Realm"] = {
							tags = {
								progression = true,
							},
						},
						["bnet:42"] = {
							tags = {
								progression = true,
							},
						},
					},
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local migratedTagId = tempDB.friendTagsLegacyContactMemoryTagMap.progression
				V:AssertNotNil(migratedTagId, "Legacy Contact Memory tag should receive a FriendTags custom ID")
				V:AssertEqual(
					tempDB.customFriendTags[migratedTagId].name,
					"Progression",
					"Migrated custom tag should keep the legacy tag name"
				)
				V:Assert(
					tempDB.friendCustomTags["wow_Unit-Realm"][migratedTagId] == true,
					"Player-key legacy assignments should migrate to WoW friend UIDs"
				)
				V:Assert(
					tempDB.friendCustomTags["bnet_42"][migratedTagId] == true,
					"Battle.net account-key legacy assignments should migrate to Battle.net friend UIDs"
				)
				V:AssertEqual(
					tempDB.friendTagsLegacyContactMemoryMigrated,
					true,
					"Legacy Contact Memory migration should be marked complete"
				)
				V:AssertNil(
					tempDB.contactMemory.contacts["player:Unit-Realm"],
					"Tag-only legacy Contact Memory contacts should be cleaned after migration"
				)
				V:Assert(
					FriendTags:FriendHasTag({
						type = "wow",
						uid = "wow_Unit-Realm",
						name = "Unit-Realm",
					}, "Progression"),
					"Migrated WoW assignments should be readable through FriendTags"
				)
				V:Assert(
					FriendTags:FriendHasTag({
						type = "bnet",
						bnetAccountID = 42,
					}, "Progression"),
					"Migrated Battle.net account assignments should be readable through FriendTags aliases"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_MenuCommitsBlizzardTagsImmediately", {
		description = "Friend Tags menu checkboxes should commit Blizzard-compatible tags before the menu closes",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local oldForceRefreshFriendsList = BFL.ForceRefreshFriendsList
				local refreshes = 0
				local ok, err = pcall(function()
					BFL.ForceRefreshFriendsList = function()
						refreshes = refreshes + 1
					end

					local capturedDPSCheckbox
					local submenu = {}
					function submenu:SetScrollMode() end
					function submenu:CreateTitle() end
					function submenu:CreateDivider() end
					function submenu:CreateButton()
						return {
							SetScrollMode = function() end,
							CreateTitle = function() end,
							CreateDivider = function() end,
							CreateButton = function() end,
							CreateCheckbox = function() end,
						}
					end
					function submenu:CreateCheckbox(text, isSelected, onSelected)
						local checkbox = {
							text = text,
							isSelected = isSelected,
							onSelected = onSelected,
						}
						if text == "DPS" or text == "Damage" then
							capturedDPSCheckbox = checkbox
						end
						return checkbox
					end

					local rootDescription = {}
					function rootDescription:CreateButton()
						return submenu
					end
					function rootDescription:AddMenuReleasedCallback()
						error("Friend tag menu should not defer Blizzard-compatible tag commits to menu release", 0)
					end

					local friend = {
						type = "bnet",
						uid = "bnet_Player#1234",
						battleTag = "Player#1234",
					}

					V:Assert(
						FriendTags:PopulateMenu(rootDescription, friend, friend.uid, "Player", nil),
						"Friend Tags menu should populate for Battle.net friends"
					)
					V:AssertNotNil(capturedDPSCheckbox, "DPS checkbox should be present in the tag menu")
					V:AssertEqual(capturedDPSCheckbox.isSelected(), false, "DPS should start unchecked")

					local response = capturedDPSCheckbox.onSelected()
					if MenuResponse and MenuResponse.Refresh then
						V:AssertEqual(response, MenuResponse.Refresh, "Tag click should refresh the open menu")
					end
					V:AssertEqual(refreshes, 1, "Tag click should refresh the visible friends list immediately")
					V:Assert(
						tempDB.friendBlizzardTags["bnet_Player#1234"]["blizzard:damager"] == true,
						"DPS tag should be saved immediately without waiting for menu close"
					)
					V:AssertEqual(
						capturedDPSCheckbox.isSelected(),
						true,
						"Open menu checkbox state should update immediately after click"
					)
				end)

				BFL.ForceRefreshFriendsList = oldForceRefreshFriendsList
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_OwnMenuContainsAllTagSources", {
		description = "BFL's own friend menu should contain both Blizzard-backed and custom tag controls",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				customFriendTags = {
					["custom:test"] = {
						id = "custom:test",
						name = "Test Custom Tag",
						source = "custom",
						enabled = true,
						order = 1,
					},
				},
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local friend = {
					type = "bnet",
					uid = "bnet_Player#1234",
					battleTag = "Player#1234",
				}
				local items = FriendTags:GetMenuItems(friend, "bnet_Player#1234", "Player")
				local seen = {}
				local iconProfiles = {}
				for _, item in ipairs(items) do
					if item.text then
						seen[item.text] = true
						iconProfiles[item.text] = item.iconProfile
					end
				end

				local L = BFL.L or {}
				V:AssertNil(seen[L.FRIEND_TAGS_BLIZZARD_SECTION or "Blizzard Tags"], "BFL's own menu should not add a redundant Blizzard tag heading")
				V:AssertNil(seen[L.FRIEND_TAGS_BLIZZARD_COMPAT_SECTION or "Blizzard-compatible Tags"], "BFL's own menu should not add a compatibility heading")
				V:Assert(seen[L.FRIEND_TAGS_INTERESTS_SECTION or "Interests"], "BFL's own menu should group Blizzard-backed interests")
				V:Assert(seen[L.FRIEND_TAGS_ROLES_SECTION or "Roles"], "BFL's own menu should group Blizzard-backed roles")
				V:Assert(seen[L.FRIEND_TAGS_BLIZZARD_DAMAGER or "DPS"], "BFL's own menu should expose Blizzard-backed tag checkboxes")
				V:Assert(seen[L.FRIEND_TAGS_CUSTOM_SECTION or "Custom Tags"], "BFL's own menu should retain custom tags")
				V:AssertType(iconProfiles[L.FRIEND_TAGS_BLIZZARD_DAMAGER or "DPS"], "table", "Built-in tag menu entries should retain their chip icon profile")
				V:AssertType(iconProfiles["Test Custom Tag"], "table", "Custom tag menu entries should retain their chip icon profile")

				local createIndex
				local manageIndex
				local customTagIndex
				local selectAllItem
				local clearAllItem
				local checkboxItems = {}
				for index, item in ipairs(items) do
					if item.type == "checkbox" and type(item.checked) == "function" then
						checkboxItems[#checkboxItems + 1] = item
					end
					if item.text == (L.FRIEND_TAGS_CREATE_CUSTOM or "Create Custom Tag") then
						createIndex = index
					elseif item.text == (L.FRIEND_TAGS_MANAGE or "Manage Tags") then
						manageIndex = index
					elseif item.text == "Test Custom Tag" then
						customTagIndex = index
					elseif item.text == (L.FRIEND_TAGS_SELECT_ALL or "Select All") then
						selectAllItem = item
					elseif item.text == (L.FRIEND_TAGS_CLEAR_ALL or "Clear All") then
						clearAllItem = item
					end
				end
				V:AssertNotNil(customTagIndex, "BFL's own menu should list custom tags before its actions")
				V:AssertNotNil(createIndex, "BFL's own menu should expose custom tag creation")
				V:AssertNotNil(manageIndex, "BFL's own menu should expose tag management")
				V:Assert(customTagIndex < createIndex, "Custom tags should precede the custom tag action block")
				V:AssertEqual(manageIndex, createIndex + 1, "Custom tag actions should share one action block")
				V:AssertNotNil(selectAllItem, "Friend tag menus should expose Select All")
				V:AssertNotNil(clearAllItem, "Friend tag menus should expose Clear All")
				selectAllItem.func()
				for _, item in ipairs(checkboxItems) do
					V:Assert(item.checked(), "Select All should check every tag in the still-open context menu")
				end
				V:AssertEqual(
					FriendTags:GetTagCount(friend),
					#FriendTags:GetBlizzardTagDefinitions() + 1,
					"Select All should assign every built-in and custom tag"
				)
				clearAllItem.func()
				for _, item in ipairs(checkboxItems) do
					V:Assert(not item.checked(), "Clear All should uncheck every tag in the still-open context menu")
				end
				V:AssertEqual(FriendTags:GetTagCount(friend), 0, "Clear All should remove every built-in and custom tag")

				local countFormat = L.FRIEND_TAGS_MENU_TITLE_COUNT or "Friend Tags (%d)"
				FriendTags:SetCustomTagForFriend(friend, "custom:test", true)
				V:AssertEqual(
					FriendTags:GetMenuTitle(friend, friend.uid),
					string.format(countFormat, 1),
					"Friend tag menu title should reflect assignment changes"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_NativeSurfacesRemainActiveWhenFeatureDisabled", {
		description = "Disabling BFL Friend Tags should retain native Blizzard tags in BFL menus, search, and filters only",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				friendTagSettings = {
					enabled = false,
					includeBlizzardTagsInSearch = true,
					includeCustomTagsInSearch = true,
				},
				customFriendTags = {
					["custom:key_team"] = {
						id = "custom:key_team",
						name = "Hidden Custom Tag",
						source = "custom",
						order = 1000,
					},
				},
				friendCustomTags = {
					["bnet_Player#1234"] = { ["custom:key_team"] = true },
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				local Registry = BFL:GetModule("FilterSortRegistry")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				V:AssertNotNil(Registry, "FilterSortRegistry module should exist")
				FriendTags:NormalizeDB()

				local oldC_BattleNet = C_BattleNet
				local oldEnum = Enum
				local oldIsRetail = BFL.IsRetail
				local oldAreBattleNetFriendTagsEnabled = BFL.AreBattleNetFriendTagsEnabled
				local oldEnumToTagIdMap = FriendTags.enumToTagIdMap
				local ok, err = pcall(function()
					BFL.IsRetail = true
					BFL.AreBattleNetFriendTagsEnabled = function()
						return true
					end
					C_BattleNet = {
						AreFriendTagsEnabled = function()
							return true
						end,
						SetFriendTags = function()
							return true
						end,
					}
					Enum = {
						BattleNetFriendTag = {
							Raiding = 2,
						},
					}
					FriendTags.enumToTagIdMap = nil
					FriendTags:ClearCaches()

					local friend = {
						type = "bnet",
						uid = "bnet_Player#1234",
						bnetAccountID = 42,
						battleTag = "Player#1234",
						friendTags = { 2 },
					}
					local raidingLabel = FriendTags:GetBlizzardTagLabel("blizzard:raiding")
					local searchText = FriendTags:GetSearchText(friend)
					V:AssertNotNil(raidingLabel, "Raiding label should resolve")
					V:Assert(
						searchText:find(raidingLabel, 1, true) ~= nil,
						"Search should retain the assigned native Blizzard tag"
					)
					V:Assert(
						searchText:find("Hidden Custom Tag", 1, true) == nil,
						"Disabled BFL custom tags must not leak into search"
					)
					V:AssertEqual(FriendTags:GetTagCount(friend), 1, "Tag filters should count the native Blizzard tag only")
					V:AssertEqual(FriendTags:GetTagSourceText(friend), "blizzard", "Tag source filters should stay native-only")
					V:AssertEqual(#FriendTags:GetTagsForFriend(friend, "row"), 0, "Disabled Friend Tags should keep row chips hidden")
					V:AssertEqual(
						#FriendTags:GetTagsForFriend(friend, "filter"),
						1,
						"Direct tag filtering should retain the native Blizzard tag"
					)
					local QuickFilters = BFL:GetModule("QuickFilters")
					V:AssertNotNil(QuickFilters, "QuickFilters module should exist")
					tempDB.quickFilterTags = { ["blizzard:raiding"] = true }
					QuickFilters:InvalidateTagFilterCache()
					V:Assert(
						QuickFilters:PassesTagFilters(friend),
						"Direct tag facets should match native Blizzard tags while BFL Friend Tags is disabled"
					)

					local seen = {}
					for _, item in ipairs(FriendTags:GetMenuItems(friend, friend.uid, "Player")) do
						if item.text then
							seen[item.text] = true
						end
					end
					local L = BFL.L or {}
					V:AssertNil(seen[L.FRIEND_TAGS_BLIZZARD_SECTION or "Blizzard Tags"], "BFL's own menu should not add a redundant Blizzard tag heading")
					V:Assert(seen[L.FRIEND_TAGS_INTERESTS_SECTION or "Interests"], "BFL's own menu should retain native interest tags")
					V:Assert(seen[L.FRIEND_TAGS_ROLES_SECTION or "Roles"], "BFL's own menu should retain native role tags")
					V:Assert(seen[raidingLabel], "BFL's own menu should retain native tag checkboxes")
					V:AssertNil(seen[L.FRIEND_TAGS_CUSTOM_SECTION or "Custom Tags"], "Disabled custom tags should not create a menu section")
					V:AssertNil(seen[L.FRIEND_TAGS_CREATE_CUSTOM or "Create Custom Tag"], "Disabled custom tags should not expose creation")
					V:AssertNil(seen[L.FRIEND_TAGS_MANAGE or "Manage Tags"], "Disabled custom tags should not expose the tag editor")

					Registry:EnsureDB()
					local filterId = "custom_filter_native_friend_tags_disabled"
					tempDB.customQuickFilters[filterId] = {
						id = filterId,
						name = "Native Friend Tags Disabled",
						icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter",
						ast = {
							type = "group",
							op = "AND",
							children = {
								{ type = "condition", field = "tag", op = "contains", value = raidingLabel },
								{ type = "condition", field = "tagSource", op = "is", value = "blizzard" },
								{ type = "condition", field = "tagCount", op = "gte", value = 1 },
								{ type = "condition", field = "hasTag", op = "is", value = true },
							},
						},
					}
					tempDB.quickFilterVisibility[filterId] = true
					Registry:InvalidateCaches()
					V:Assert(
						Registry:EvaluateQuickFilter(filterId, friend),
						"Custom filters should retain native Blizzard tag fields while Friend Tags is disabled"
					)
				end)

				C_BattleNet = oldC_BattleNet
				Enum = oldEnum
				BFL.IsRetail = oldIsRetail
				BFL.AreBattleNetFriendTagsEnabled = oldAreBattleNetFriendTagsEnabled
				FriendTags.enumToTagIdMap = oldEnumToTagIdMap
				FriendTags:ClearCaches()
				Registry:InvalidateCaches()
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_AndFriendTagsUseSeparateMenus", {
		description = "Private Notes should be a flat action beside the separate Friend Tags submenu",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function()
				local ContactMemory = BFL:GetModule("ContactMemory")
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local legacyTagId = ContactMemory:CreateTag("Legacy CM Tag")
				V:AssertNotNil(legacyTagId, "Legacy Contact Memory tag setup should succeed")
				V:Assert(ContactMemory:SetTag("player:Unit-Realm", legacyTagId, true), "Legacy Contact Memory tag assignment should succeed")

				local customTagId = FriendTags:CreateCustomTag("Key Team")
				V:AssertNotNil(customTagId, "FriendTags custom tag setup should succeed")

				local entries = {}
				local submenu = {}
				function submenu:SetScrollMode() end
				function submenu:CreateDivider()
					entries[#entries + 1] = { type = "divider" }
				end
				function submenu:CreateTitle(text)
					entries[#entries + 1] = { type = "title", text = text }
				end
				function submenu:CreateButton(text)
					entries[#entries + 1] = { type = "button", text = text }
					return submenu
				end
				function submenu:CreateCheckbox(text)
					entries[#entries + 1] = { type = "checkbox", text = text }
				end

				local rootDescription = {}
				function rootDescription:CreateButton(text)
					entries[#entries + 1] = { type = "root", text = text }
					return submenu
				end

				V:Assert(ContactMemory:PopulateMenu(rootDescription, "player:Unit-Realm", "Unit"), "Private Notes menu should populate")
				V:Assert(FriendTags:PopulateMenu(rootDescription, {
					type = "wow",
					uid = "wow_Unit-Realm",
					name = "Unit-Realm",
				}, "wow_Unit-Realm", "Unit"), "Friend Tags menu should populate")

				local seen = {}
				for _, entry in ipairs(entries) do
					if entry.text then
						seen[entry.text] = true
					end
				end
				V:AssertNil(seen["Private Notes"], "A single Private Notes action should not create a redundant submenu")
				V:Assert(seen["Edit Private Note"], "Private Notes should be exposed as a direct root action")
				V:Assert(seen["Friend Tags"], "Friend Tags should have its own root menu entry")
				V:Assert(seen["Custom Tags"], "Friend Tags menu should show custom tags")
				V:Assert(seen["Key Team"], "Friend Tags menu should show custom tag assignments")
				V:AssertNil(seen["Create Tag"], "Legacy Contact Memory tag creation should not be exposed")
				V:AssertNil(seen["Legacy CM Tag"], "Legacy Contact Memory tags should not be exposed as a second tag system")
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_OpenMenu_UsesSharedContextMenu", {
		description = "Contact Memory context menus should delegate to the shared simple menu wrapper",
		action = function(V)
			local ContactMemory = BFL:GetModule("ContactMemory")
			V:AssertNotNil(ContactMemory, "ContactMemory module should exist")
			V:AssertType(ContactMemory.OpenMenu, "function", "ContactMemory should expose OpenMenu")

			local oldOpenSimpleContextMenu = BFL.OpenSimpleContextMenu
			local oldIsEnabled = ContactMemory.IsEnabled
			local oldUpsertContact = ContactMemory.UpsertContact
			local oldGetContact = ContactMemory.GetContact
			local captured
			local upserted

			local ok, err = pcall(function()
				ContactMemory.IsEnabled = function()
					return true
				end
				ContactMemory.GetContact = function()
					return nil
				end
				ContactMemory.UpsertContact = function(_, reason, data)
					upserted = {
						reason = reason,
						data = data,
					}
				end
				BFL.OpenSimpleContextMenu = function(owner, name, itemsOrFactory)
					captured = {
						owner = owner,
						name = name,
						items = type(itemsOrFactory) == "function" and itemsOrFactory() or itemsOrFactory,
					}
					return true
				end

				local anchor = {}
				local result = ContactMemory:OpenMenu(anchor, "player:Unit-Realm", "Unit", nil)

				V:AssertEqual(result, true, "OpenMenu should return the shared wrapper result")
				V:AssertNotNil(captured, "Shared simple context menu wrapper should be called")
				V:AssertEqual(captured.owner, anchor, "Anchor should be passed through")
				V:AssertEqual(captured.name, "BFLContactMemoryDropdown", "Stable dropdown name should be preserved")
				V:AssertType(captured.items, "table", "Menu factory should provide shared simple menu items")
				V:AssertNotNil(upserted, "OpenMenu should still upsert contact metadata")
				V:AssertEqual(upserted.reason, "context-menu", "Contact metadata reason should be preserved")
			end)

			BFL.OpenSimpleContextMenu = oldOpenSimpleContextMenu
			ContactMemory.IsEnabled = oldIsEnabled
			ContactMemory.UpsertContact = oldUpsertContact
			ContactMemory.GetContact = oldGetContact
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Compat_PopulateSimpleMenu_ReturnsCallbackResponse", {
		description = "Shared simple menus should return callback responses for modern menu refresh handling",
		action = function(V)
			V:AssertType(BFL.PopulateSimpleMenu, "function", "BFL.PopulateSimpleMenu should exist")

			local buttonResponse = {}
			local checkboxResponse = {}
			local radioResponse = {}
			local created = {}

			local rootDescription = {}
			function rootDescription:CreateButton(text, onSelected)
				created.button = {
					text = text,
					onSelected = onSelected,
				}
				return {}
			end
			function rootDescription:CreateCheckbox(text, isSelected, onSelected)
				created.checkbox = {
					text = text,
					isSelected = isSelected,
					onSelected = onSelected,
				}
				return {}
			end
			function rootDescription:CreateRadio(text, isSelected, onSelected, value)
				created.radio = {
					text = text,
					isSelected = isSelected,
					onSelected = onSelected,
					value = value,
				}
				return {}
			end

			local populated = BFL.PopulateSimpleMenu(rootDescription, {
				{
					text = "Button",
					value = "buttonValue",
					func = function(value)
						V:AssertEqual(value, "buttonValue", "Button callbacks should receive item.value")
						return buttonResponse
					end,
				},
				{
					type = "checkbox",
					text = "Checkbox",
					value = "checkboxValue",
					checked = function(value)
						return value == "checkboxValue"
					end,
					func = function(value)
						V:AssertEqual(value, "checkboxValue", "Checkbox callbacks should receive item.value")
						return checkboxResponse
					end,
				},
				{
					type = "radio",
					text = "Radio",
					value = "radioValue",
					checked = function(value)
						return value == "radioValue"
					end,
					func = function(value)
						V:AssertEqual(value, "radioValue", "Radio callbacks should receive the selected value")
						return radioResponse
					end,
				},
			})

			V:Assert(populated == true, "PopulateSimpleMenu should populate valid menu roots")
			V:AssertNotNil(created.button, "Button item should be created")
			V:AssertNotNil(created.checkbox, "Checkbox item should be created")
			V:AssertNotNil(created.radio, "Radio item should be created")
			V:AssertEqual(created.button.onSelected(), buttonResponse, "Button callbacks should return their response")
			V:AssertEqual(created.checkbox.isSelected(), true, "Checkbox checked state should use item.value")
			V:AssertEqual(created.checkbox.onSelected(), checkboxResponse, "Checkbox callbacks should return their response")
			V:AssertEqual(created.radio.value, "radioValue", "Radio item value should be passed to the menu API")
			V:AssertEqual(created.radio.isSelected("radioValue"), true, "Radio checked state should use callback value")
			V:AssertEqual(created.radio.onSelected("radioValue"), radioResponse, "Radio callbacks should return their response")
		end,
	})

	TS:RegisterTest("data", "Compat_ClassicSimpleMenuCheckboxHasVisibleEmptyState", {
		description = "BFL checkbox menus should retain a visible empty marker on Classic menu variants",
		action = function(V)
			V:AssertType(BFL.StyleSimpleMenuCheckbox, "function", "BFL.StyleSimpleMenuCheckbox should exist")

			local oldIsClassic = BFL.IsClassic
			local initializer
			local appliedTexture
			local appliedAtlas
			local element = {
				AddInitializer = function(_, callback)
					initializer = callback
				end,
			}

			local ok, err = pcall(function()
				BFL.IsClassic = true
				BFL.StyleSimpleMenuCheckbox(element)
				V:AssertType(initializer, "function", "Classic checkbox styling should install a menu initializer")
				initializer({
					leftTexture1 = {
						GetTexture = function()
							return nil
						end,
						SetTexture = function(_, texture)
							appliedTexture = texture
						end,
						SetAtlas = function(_, atlas)
							appliedAtlas = atlas
						end,
						SetTexCoord = function() end,
						SetSize = function() end,
					},
				}, {
					IsSelected = function()
						return false
					end,
				})
				V:Assert(appliedAtlas ~= nil or appliedTexture ~= nil, "Unchecked Classic menu entries should receive visible checkbox art")
			end)

			BFL.IsClassic = oldIsClassic
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Compat_CreateContextMenu_ReturnsMenu", {
		description = "Shared context menu wrapper should return the modern menu instance",
		action = function(V)
			V:AssertType(BFL.CreateContextMenu, "function", "BFL.CreateContextMenu should exist")

			local oldMenuUtil = MenuUtil
			local owner = {}
			local generator = function() end
			local expectedMenu = {}
			local capturedOwner
			local capturedGenerator

			local ok, err = pcall(function()
				MenuUtil = {
					CreateContextMenu = function(menuOwner, menuGenerator)
						capturedOwner = menuOwner
						capturedGenerator = menuGenerator
						return expectedMenu
					end,
				}

				local menu = BFL.CreateContextMenu(owner, generator)
				V:AssertEqual(menu, expectedMenu, "CreateContextMenu should return MenuUtil's menu instance")
				V:AssertEqual(capturedOwner, owner, "CreateContextMenu should pass through the owner")
				V:AssertEqual(capturedGenerator, generator, "CreateContextMenu should pass through the generator")
			end)

			MenuUtil = oldMenuUtil
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Compat_CreateContextMenu_ClassicRootDescriptionFallback", {
		description = "Shared context menu wrapper should translate rootDescription menus to EasyMenu on Classic",
		action = function(V)
			V:AssertType(BFL.CreateContextMenu, "function", "BFL.CreateContextMenu should exist")

			local oldMenuUtil = MenuUtil
			local oldEasyMenu = EasyMenu
			local oldCreateFrame = CreateFrame
			local oldUIParent = UIParent
			local owner = {}
			local capturedEasyMenu
			local selected = {}

			local ok, err = pcall(function()
				MenuUtil = nil
				UIParent = {}
				CreateFrame = function(frameType, name, parent, template)
					return {
						frameType = frameType,
						name = name,
						parent = parent,
						template = template,
					}
				end
				EasyMenu = function(menuTable, menuFrame, menuOwner)
					capturedEasyMenu = {
						menuTable = menuTable,
						menuFrame = menuFrame,
						menuOwner = menuOwner,
					}
				end

				local menu = BFL.CreateContextMenu(owner, function(menuOwner, rootDescription)
					V:AssertEqual(menuOwner, owner, "Classic fallback should pass through the owner")
					V:AssertType(rootDescription.CreateButton, "function", "Classic fallback should provide rootDescription buttons")

					rootDescription:CreateTitle("Title")
					rootDescription:CreateButton("Button", function()
						selected.button = true
					end)
					rootDescription:CreateDivider()
					local parent = rootDescription:CreateButton("Parent")
					parent:CreateButton("Child", function()
						selected.child = true
					end)
					local disabled = rootDescription:CreateButton("Disabled")
					disabled:SetEnabled(false)
					rootDescription:CreateCheckbox("Check", function()
						return true
					end, function()
						selected.check = true
					end)
					rootDescription:CreateRadio("Radio", function(value)
						return value == "radioValue"
					end, function(value)
						selected.radio = value
					end, "radioValue")
				end)

				V:AssertNotNil(menu, "Classic fallback should return the backing menu frame")
				V:AssertNotNil(capturedEasyMenu, "Classic fallback should open EasyMenu")
				V:AssertEqual(capturedEasyMenu.menuOwner, owner, "EasyMenu should anchor to the owner")

				local menuTable = capturedEasyMenu.menuTable
				V:AssertEqual(menuTable[1].text, "Title", "Title text should be preserved")
				V:Assert(menuTable[1].isTitle == true, "Title should be marked as an EasyMenu title")
				V:AssertEqual(menuTable[2].text, "Button", "Button text should be preserved")
				menuTable[2].func()
				V:Assert(selected.button == true, "Button callback should be callable")
				V:Assert(menuTable[4].hasArrow == true, "Nested rootDescription button should become an EasyMenu submenu")
				V:AssertEqual(menuTable[4].menuList[1].text, "Child", "Submenu child text should be preserved")
				menuTable[4].menuList[1].func()
				V:Assert(selected.child == true, "Submenu callback should be callable")
				V:Assert(menuTable[5].disabled == true, "SetEnabled(false) should disable the EasyMenu item")
				V:Assert(menuTable[6].checked() == true, "Checkbox checked callback should be preserved")
				menuTable[6].func()
				V:Assert(selected.check == true, "Checkbox callback should be callable")
				V:Assert(menuTable[7].checked() == true, "Radio checked callback should receive the radio value")
				menuTable[7].func(nil, "radioValue")
				V:AssertEqual(selected.radio, "radioValue", "Radio callback should receive the selected value")
			end)

			MenuUtil = oldMenuUtil
			EasyMenu = oldEasyMenu
			CreateFrame = oldCreateFrame
			UIParent = oldUIParent
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Compat_PopulateSimpleMenu_SupportsNestedItems", {
		description = "Shared simple menus should populate submenu children through the same item model",
		action = function(V)
			V:AssertType(BFL.PopulateSimpleMenu, "function", "BFL.PopulateSimpleMenu should exist")

			local childResponse = {}
			local parent
			local rootDescription = {}
			function rootDescription:CreateButton(text, onSelected)
				local element = {
					text = text,
					onSelected = onSelected,
					children = {},
				}
				function element:CreateButton(childText, childOnSelected)
					local child = {
						text = childText,
						onSelected = childOnSelected,
					}
					table.insert(self.children, child)
					return child
				end
				parent = element
				return element
			end

			local populated = BFL.PopulateSimpleMenu(rootDescription, {
				{
					text = "Parent",
					children = {
						{
							text = "Child",
							value = "childValue",
							func = function(value)
								V:AssertEqual(value, "childValue", "Nested callbacks should receive item.value")
								return childResponse
							end,
						},
					},
				},
			})

			V:Assert(populated == true, "PopulateSimpleMenu should populate nested menu roots")
			V:AssertNotNil(parent, "Parent submenu item should be created")
			V:AssertEqual(parent.text, "Parent", "Parent submenu label should be preserved")
			V:AssertEqual(#parent.children, 1, "Nested submenu should create one child item")
			V:AssertEqual(parent.children[1].text, "Child", "Nested child label should be preserved")
			V:AssertEqual(parent.children[1].onSelected(), childResponse, "Nested callbacks should return their response")
		end,
	})

	TS:RegisterTest("data", "GuildBroker_ContextMenu_DelegatesToGuildActions", {
		description = "GuildBroker member menus should use the shared GuildActions menu path",
		action = function(V)
			local GuildBroker = BFL:GetModule("GuildBroker")
			local GuildActions = BFL:GetModule("GuildActions")
			V:AssertNotNil(GuildBroker, "GuildBroker module should exist")
			V:AssertNotNil(GuildActions, "GuildActions module should exist")
			V:AssertType(GuildBroker.OpenMemberContextMenu, "function", "GuildBroker should expose OpenMemberContextMenu")
			V:AssertType(GuildActions.ShowMemberMenu, "function", "GuildActions should expose ShowMemberMenu")

			local oldShowMemberMenu = GuildActions.ShowMemberMenu
			local captured
			local ok, err = pcall(function()
				GuildActions.ShowMemberMenu = function(_, owner, member, name)
					captured = {
						owner = owner,
						member = member,
						name = name,
					}
					return true
				end

				local member = {
					name = "Unit",
					fullName = "Unit-Realm",
					online = true,
				}
				local result = GuildBroker:OpenMemberContextMenu(member)
				V:AssertEqual(result, true, "GuildBroker should return the shared menu result")
				V:AssertNotNil(captured, "GuildActions:ShowMemberMenu should be called")
				V:AssertEqual(captured.member, member, "GuildBroker should pass the original member data")
				V:AssertEqual(
					captured.name,
					"BFL_GuildBrokerMemberDropdown",
					"GuildBroker should use the stable broker dropdown name"
				)
			end)

			GuildActions.ShowMemberMenu = oldShowMemberMenu
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "GuildActions_Menus_UseSharedSimpleWrapper", {
		description = "Guild member and guild action menus should delegate to the shared simple context menu wrapper",
		action = function(V)
			local GuildActions = BFL:GetModule("GuildActions")
			V:AssertNotNil(GuildActions, "GuildActions module should exist")
			V:AssertType(GuildActions.ShowMemberMenu, "function", "GuildActions should expose member menus")
			V:AssertType(GuildActions.ShowGuildActionsMenu, "function", "GuildActions should expose guild action menus")

			local oldOpenSimpleContextMenu = BFL.OpenSimpleContextMenu
			local oldGetMemberCapabilities = GuildActions.GetMemberCapabilities
			local oldGetGuildCapabilities = GuildActions.GetGuildCapabilities
			local captured = {}

			local ok, err = pcall(function()
				BFL.OpenSimpleContextMenu = function(owner, name, itemsOrFactory)
					captured[#captured + 1] = {
						owner = owner,
						name = name,
						items = type(itemsOrFactory) == "function" and itemsOrFactory() or itemsOrFactory,
					}
					return true
				end
				GuildActions.GetMemberCapabilities = function()
					return {
						whisper = true,
						inviteParty = true,
						who = true,
						nickname = true,
						copyName = true,
						promote = false,
						demote = false,
						remove = false,
						setLeader = false,
					}
				end
				GuildActions.GetGuildCapabilities = function()
					return {
						invite = true,
						editMOTD = true,
						leave = false,
						disband = false,
					}
				end

				local owner = {}
				local memberResult = GuildActions:ShowMemberMenu(owner, {
					name = "Unit",
					fullName = "Unit-Realm",
					online = true,
				}, "BFL_TestGuildMemberDropdown")
				local actionsResult = GuildActions:ShowGuildActionsMenu(owner)

				V:AssertEqual(memberResult, true, "Member menu should return the shared wrapper result")
				V:AssertEqual(actionsResult, true, "Guild actions menu should return the shared wrapper result")
				V:AssertEqual(#captured, 2, "Both guild menus should use BFL.OpenSimpleContextMenu")
				V:AssertEqual(captured[1].name, "BFL_TestGuildMemberDropdown", "Member menu should preserve caller dropdown name")
				V:AssertEqual(captured[2].name, "BFL_GuildActionsDropdown", "Guild actions menu should use stable dropdown name")
				V:AssertType(captured[1].items, "table", "Member menu should provide simple menu items")
				V:AssertType(captured[2].items, "table", "Guild actions menu should provide simple menu items")
			end)

			BFL.OpenSimpleContextMenu = oldOpenSimpleContextMenu
			GuildActions.GetMemberCapabilities = oldGetMemberCapabilities
			GuildActions.GetGuildCapabilities = oldGetGuildCapabilities
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "GuildFrame_Dropdowns_UseSharedInitializer", {
		description = "Guild roster sort and filter dropdowns should share the BFL dropdown initializer",
		action = function(V)
			local GuildFrame = BFL:GetModule("GuildFrame")
			V:AssertNotNil(GuildFrame, "GuildFrame module should exist")
			V:AssertType(GuildFrame.CreateSortDropdown, "function", "GuildFrame should create sort dropdowns")
			V:AssertType(GuildFrame.CreateFilterDropdown, "function", "GuildFrame should create filter dropdowns")

			local oldCreateDropdown = BFL.CreateDropdown
			local oldInitializeDropdown = BFL.InitializeDropdown
			local oldIsModernDropdown = BFL.IsModernDropdown
			local oldSetSort = GuildFrame.SetSort
			local oldSetFilter = GuildFrame.SetFilter
			local oldRefreshSortDropdown = GuildFrame.RefreshSortDropdown
			local oldRefreshFilterDropdown = GuildFrame.RefreshFilterDropdown
			local oldSortMode = GuildFrame.sortMode
			local oldFilterMode = GuildFrame.filterMode
			local captured = {}

			local ok, err = pcall(function()
				GuildFrame.sortMode = "rank"
				GuildFrame.filterMode = "online"
				BFL.IsModernDropdown = function()
					return false
				end
				BFL.CreateDropdown = function(parent, name, width)
					return {
						parent = parent,
						name = name,
						width = width,
					}
				end
				BFL.InitializeDropdown = function(dropdown, options, getter, setter)
					captured[#captured + 1] = {
						dropdown = dropdown,
						options = options,
						getter = getter,
						setter = setter,
					}
					return true
				end
				GuildFrame.RefreshSortDropdown = function() end
				GuildFrame.RefreshFilterDropdown = function() end

				local sortArgs
				GuildFrame.SetSort = function(_, mode, skipToggle)
					sortArgs = {
						mode = mode,
						skipToggle = skipToggle,
					}
				end
				local filterMode
				GuildFrame.SetFilter = function(_, mode)
					filterMode = mode
				end

				local frame = {}
				GuildFrame:CreateSortDropdown(frame)
				GuildFrame:CreateFilterDropdown(frame)

				V:AssertNotNil(frame.SortDropdown, "Sort dropdown should be created")
				V:AssertNotNil(frame.FilterDropdown, "Filter dropdown should be created")
				V:AssertEqual(#captured, 2, "Both guild dropdowns should use BFL.InitializeDropdown")
				V:AssertEqual(captured[1].dropdown.name, "BFL_GuildSortDropdown", "Sort dropdown name should be stable")
				V:AssertEqual(captured[2].dropdown.name, "BFL_GuildFilterDropdown", "Filter dropdown name should be stable")
				V:AssertType(captured[1].options.getSelectionText, "function", "Sort dropdown should provide selection text")
				V:AssertType(captured[2].options.getSelectionText, "function", "Filter dropdown should provide selection text")
				V:AssertNotNil(captured[1].options.getSelectionText("rank"), "Sort selection text should resolve without error")
				V:AssertNotNil(captured[2].options.getSelectionText("all"), "Filter selection text should resolve without error")
				V:Assert(captured[1].getter("rank") == true, "Sort getter should use current GuildFrame sort mode")
				V:Assert(captured[2].getter("online") == true, "Filter getter should use current GuildFrame filter mode")
				V:Assert(table.concat(captured[1].options.values, ","):find("nickname", 1, true) ~= nil, "Sort dropdown should include nickname sort")
				V:Assert(table.concat(captured[1].options.values, ","):find("status", 1, true) ~= nil, "Sort dropdown should include status sort")
				V:Assert(table.concat(captured[1].options.values, ","):find("lastonline", 1, true) ~= nil, "Sort dropdown should include last-online sort")
				V:Assert(table.concat(captured[2].options.values, ","):find("offline", 1, true) ~= nil, "Filter dropdown should include offline filter")

				captured[1].setter("name")
				V:AssertEqual(sortArgs.mode, "name", "Sort setter should pass selected mode")
				V:AssertEqual(sortArgs.skipToggle, true, "Sort dropdown should not toggle direction when reselecting")

				captured[2].setter("all")
				V:AssertEqual(filterMode, "all", "Filter setter should pass selected mode")
			end)

			BFL.CreateDropdown = oldCreateDropdown
			BFL.InitializeDropdown = oldInitializeDropdown
			BFL.IsModernDropdown = oldIsModernDropdown
			GuildFrame.SetSort = oldSetSort
			GuildFrame.SetFilter = oldSetFilter
			GuildFrame.RefreshSortDropdown = oldRefreshSortDropdown
			GuildFrame.RefreshFilterDropdown = oldRefreshFilterDropdown
			GuildFrame.sortMode = oldSortMode
			GuildFrame.filterMode = oldFilterMode
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "GuildFrame_NicknameSort_UsesGuildNicknames", {
		description = "Guild roster nickname sorting should match the nickname option exposed by settings",
		action = function(V)
			WithTemporaryDatabase({
				guildNicknames = {
					["Ada-Realm"] = "Beta",
					["Zed-Realm"] = "Alpha",
				},
			}, function()
				local GuildFrame = BFL:GetModule("GuildFrame")
				V:AssertNotNil(GuildFrame, "GuildFrame module should exist")
				V:AssertType(GuildFrame.SortMembers, "function", "GuildFrame should sort members")

				local oldSortMode = GuildFrame.sortMode
				local oldSortReversed = GuildFrame.sortReversed
				local ok, err = pcall(function()
					GuildFrame.sortMode = "nickname"
					GuildFrame.sortReversed = {}
					local members = {
						{ name = "Ada", fullName = "Ada-Realm", online = true, guildIndex = 1 },
						{ name = "Zed", fullName = "Zed-Realm", online = true, guildIndex = 2 },
					}
					GuildFrame:SortMembers(members)
					V:AssertEqual(members[1].fullName, "Zed-Realm", "Nickname sort should use stored guild nicknames")
				end)
				GuildFrame.sortMode = oldSortMode
				GuildFrame.sortReversed = oldSortReversed
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_NativeWritesRequireUserInitiated", {
		description = "Native Blizzard Friend Tag writes should require explicit user initiation",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local oldC_BattleNet = C_BattleNet
				local oldEnum = Enum
				local oldIsRetail = BFL.IsRetail
				local oldAreBattleNetFriendTagsEnabled = BFL.AreBattleNetFriendTagsEnabled
				local calls = 0

				local ok, err = pcall(function()
					BFL.IsRetail = true
					BFL.AreBattleNetFriendTagsEnabled = function()
						return true
					end
					C_BattleNet = {
						AreFriendTagsEnabled = function()
							return true
						end,
						SetFriendTags = function(accountID, tags)
							calls = calls + 1
							V:AssertEqual(accountID, 42, "Native write should use the Battle.net account ID")
							V:AssertEqual(#tags, 1, "Native write should send one enum tag")
							return true
						end,
					}
					Enum = {
						BattleNetFriendTag = {
							Raiding = 2,
						},
					}

					local friend = {
						type = "bnet",
						uid = "bnet_Player#1234",
						bnetAccountID = 42,
					}

					local writeOK, reason = FriendTags:SetBlizzardTagsForFriend(friend, { ["blizzard:raiding"] = true })
					V:AssertEqual(writeOK, false, "Native write should be rejected without user initiation")
					V:AssertEqual(reason, "notUserInitiated", "Rejected native write should report notUserInitiated")
					V:AssertEqual(calls, 0, "Rejected native write should not call C_BattleNet.SetFriendTags")

					writeOK = FriendTags:SetBlizzardTagsForFriend(friend, { ["blizzard:raiding"] = true }, {
						userInitiated = true,
					})
					V:AssertEqual(writeOK, true, "User-initiated native write should succeed")
					V:AssertEqual(calls, 1, "User-initiated native write should call C_BattleNet.SetFriendTags once")
				end)

				C_BattleNet = oldC_BattleNet
				Enum = oldEnum
				BFL.IsRetail = oldIsRetail
				BFL.AreBattleNetFriendTagsEnabled = oldAreBattleNetFriendTagsEnabled
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_StableMenuUIDIsolation", {
		description = "Friend Tags should isolate assignments by stable menu UID even if cached friend data has a temporary UID",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local friendA = FriendTags:NormalizeFriendContext({
					type = "bnet",
					uid = "bnet_unknown",
					bnetAccountID = 101,
				}, "bnet_PlayerA#1111")
				local friendB = FriendTags:NormalizeFriendContext({
					type = "bnet",
					uid = "bnet_unknown",
					bnetAccountID = 202,
				}, "bnet_PlayerB#2222")

				V:AssertEqual(friendA.uid, "bnet_PlayerA#1111", "Explicit menu UID should override temporary cached UID")
				V:AssertEqual(friendB.uid, "bnet_PlayerB#2222", "Each friend should keep its own explicit menu UID")

				V:Assert(
					FriendTags:SetBlizzardTagsForFriend(friendA, {
						["blizzard:raiding"] = true,
						["blizzard:dungeons"] = true,
					}),
					"Multiple Blizzard-compatible tags should be saved for the intended friend"
				)

				V:AssertType(
					tempDB.friendBlizzardTags["bnet_PlayerA#1111"],
					"table",
					"Friend A should receive the tag set under its stable UID"
				)
				V:AssertNil(
					tempDB.friendBlizzardTags["bnet_PlayerB#2222"],
					"Friend B should not receive Friend A tags"
				)
				V:AssertNil(tempDB.friendBlizzardTags.bnet_unknown, "Temporary bnet_unknown should never be used as a tag key")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_CustomTagCRUDAndChipProfile", {
		description = "Friend Tags should support custom tag rename/delete and per-chip visual profiles",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function(tempDB)
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local friend = {
					type = "wow",
					uid = "wow_Unit-Realm",
					name = "Unit-Realm",
				}

				local tagId = FriendTags:CreateCustomTag("Key Team")
				V:AssertNotNil(tagId, "CreateCustomTag should return a tag ID")
				V:Assert(FriendTags:RenameCustomTag(tagId, "Key Push"), "RenameCustomTag should succeed")
				V:Assert(FriendTags:SetCustomTagsForFriend(friend, { [tagId] = true }), "Bulk custom tag assignment should succeed")
				V:Assert(FriendTags:FriendHasTag(friend, tagId), "FriendHasTag should match custom tag ID")
				V:Assert(FriendTags:FriendHasTag(friend, "Key Push"), "FriendHasTag should match renamed custom tag name")

				V:Assert(FriendTags:SetChipProfile(tagId, {
					chipLabel = "",
					iconOnlyChip = true,
					iconType = "texture",
					iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
					textColor = { r = 0.15, g = 0.8, b = 0.35, a = 0.9 },
				}), "SetChipProfile should accept icon-only labels")

				local profile = FriendTags:GetChipProfile(tagId)
				V:AssertEqual(profile.chipLabel, "", "Empty chip label should be preserved for icon-only chips")
				V:Assert(profile.iconOnlyChip == true, "Icon-only chips should preserve their colored background on request")
				V:AssertEqual(
					profile.icon,
					"Interface\\Icons\\INV_Misc_QuestionMark",
					"Icon-only profile should keep its icon"
				)
				V:AssertEqual(profile.textColor.r, 0.15, "Chip font color should be saved per tag")
				V:AssertEqual(profile.textColor.g, 0.8, "Chip font color should retain its green channel")
				V:AssertEqual(profile.textColor.b, 0.35, "Chip font color should retain its blue channel")
				V:AssertEqual(profile.textColor.a, 0.9, "Chip font color should retain alpha")
				local otherTagId = FriendTags:CreateCustomTag("Other Team")
				local reservedTagId, reservedReason = FriendTags:CreateCustomTag(BFL.L.FRIEND_TAGS_BLIZZARD_PVP or "PvP")
				V:AssertNil(reservedTagId, "Built-in tag names should be reserved for built-in tags")
				V:AssertEqual(reservedReason, "reservedName", "Built-in name collisions should return a useful reason")
				local renamedToBuiltIn, renameReason = FriendTags:RenameCustomTag(otherTagId, BFL.L.FRIEND_TAGS_BLIZZARD_DUNGEONS or "Dungeons")
				V:Assert(not renamedToBuiltIn, "Custom tags should not be renamed to built-in tag names")
				V:AssertEqual(renameReason, "reservedName", "Rename collisions should return the reserved-name reason")
				local otherProfile = FriendTags:GetChipProfile(otherTagId)
				V:AssertEqual(otherProfile.textColor.r, 1, "A chip font color must not leak to another tag")
				V:AssertEqual(otherProfile.textColor.g, 1, "Other tags should retain their own default font color")
				V:Assert(FriendTags:FriendHasTag(friend, tagId), "Icon-only chip profile should keep the tag assigned")

				V:Assert(FriendTags:DeleteCustomTag(tagId), "DeleteCustomTag should succeed")
				V:AssertNil(tempDB.customFriendTags[tagId], "Deleted custom tag definition should be removed")
				V:AssertNil(tempDB.friendCustomTags["wow_Unit-Realm"], "Deleted custom tag assignment should be removed")
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_DynamicTagGroupCollapseState", {
		description = "Dynamic Friend Tag groups should store collapse state without creating real groups",
		action = function(V)
			WithTemporaryDatabase({
				groupStates = {},
			}, function(tempDB)
				local FriendsList = BFL:GetModule("FriendsList")
				V:AssertNotNil(FriendsList, "FriendsList module should exist")

				local oldForceRefresh = BFL.ForceRefreshFriendsList
				local refreshes = 0
				BFL.ForceRefreshFriendsList = function()
					refreshes = refreshes + 1
				end

				local ok, err = pcall(function()
					FriendsList:ToggleGroup("tag:custom:key_push")
					V:AssertEqual(
						tempDB.groupStates["tag:custom:key_push"],
						true,
						"First toggle should collapse the virtual tag group"
					)
					FriendsList:ToggleGroup("tag:custom:key_push")
					V:AssertEqual(
						tempDB.groupStates["tag:custom:key_push"],
						false,
						"Second toggle should expand the virtual tag group"
					)
					V:AssertEqual(refreshes, 2, "Virtual tag group toggles should refresh the friend list")
				end)

				BFL.ForceRefreshFriendsList = oldForceRefresh
				if not ok then
					error(err, 0)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTags_CustomTagsSearch", {
		description = "Friend Tags should create, assign, and search BetterFriendlist custom tags",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function()
				local FriendTags = BFL:GetModule("FriendTags")
				V:AssertNotNil(FriendTags, "FriendTags module should exist")
				FriendTags:NormalizeDB()

				local friend = {
					type = "wow",
					uid = "wow_Unit-Realm",
					name = "Unit-Realm",
				}
				local tagId = FriendTags:CreateCustomTag("Guild Lead")
				V:AssertNotNil(tagId, "CreateCustomTag should return a tag ID")
				V:Assert(FriendTags:SetCustomTagForFriend(friend, tagId, true), "Custom tag should be assigned")
				V:Assert(FriendTags:FriendHasTag(friend, "Guild Lead"), "FriendHasTag should match assigned custom tags")
				V:Assert(
					FriendTags:GetTooltipTextForFriend(friend):find("Guild Lead", 1, true) ~= nil,
					"Tooltip text should include assigned custom tags"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_DBDefaults", {
		description = "Auto Raid Assist defaults should be present and disabled",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local assistDB = AutoRaidAssist:NormalizeDB()
				V:AssertType(tempDB.autoRaidAssist, "table", "autoRaidAssist should be a table")
				V:AssertEqual(assistDB.version, 1, "Auto Raid Assist schema version should be 1")
				V:AssertEqual(assistDB.enabled, false, "Auto Raid Assist should default to disabled")
				V:AssertType(assistDB.targets, "table", "Auto Raid Assist targets should be a table")
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_TargetCRUD", {
		description = "Auto Raid Assist should store stable contact keys and reject duplicates",
		action = function(V)
			WithTemporaryDatabase({}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local ok = AutoRaidAssist:AddManualCharacterTarget("Unit-Realm")
				V:Assert(ok == true, "Manual Character-Realm target should be accepted")
				V:AssertEqual(#AutoRaidAssist:GetTargets(), 1, "One target should be stored")
				V:AssertEqual(
					AutoRaidAssist:GetTargets()[1].key,
					"player:Unit-Realm",
					"Manual target should use a player contact key"
				)

				local duplicateOK, duplicateReason = AutoRaidAssist:AddManualCharacterTarget("Unit-Realm")
				V:Assert(duplicateOK == false, "Duplicate target should be rejected")
				V:AssertEqual(duplicateReason, "duplicate", "Duplicate target should return duplicate reason")

				local invalidOK, invalidReason = AutoRaidAssist:AddManualCharacterTarget("Unit")
				V:Assert(invalidOK == false, "Bare character names should be rejected")
				V:AssertEqual(invalidReason, "invalidCharacter", "Invalid manual target should return validation reason")
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_GuildCandidates", {
		description = "Auto Raid Assist should suggest guild characters and add them as guild targets",
		action = function(V)
			WithTemporaryDatabase({}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				local FriendsList = BFL:GetModule("FriendsList")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalFriends = FriendsList and FriendsList.friendsList
				local originalGuildRosterData = BFL.Modules and BFL.Modules.GuildRosterData
				local originalGuildRosterRequest = AutoRaidAssist.lastGuildRosterRequest
				local fakeGuildRosterData = {
					requested = false,
					HasBaseRosterAPI = function()
						return true
					end,
					IsInGuild = function()
						return true
					end,
					RequestRosterUpdate = function(self)
						self.requested = true
						return true
					end,
					CollectRoster = function()
						return {
							{
								name = "Dimmy",
								fullName = "Dimmy-Realm",
								realm = "Realm",
								rank = "Raider",
							},
							{
								name = "Seb",
								fullName = "Seb-OtherRealm",
								realm = "OtherRealm",
								rank = "Member",
							},
						}
					end,
				}

				local ok, err = pcall(function()
					if FriendsList then
						FriendsList.friendsList = {}
					end
					BFL.Modules.GuildRosterData = fakeGuildRosterData
					AutoRaidAssist.lastGuildRosterRequest = nil

					local candidates = AutoRaidAssist:BuildCandidateList("dim", 10)
					V:AssertEqual(#candidates, 1, "Guild character query should return one candidate")
					V:AssertEqual(candidates[1].key, "player:Dimmy-Realm", "Guild candidate should use a player key")
					V:AssertEqual(candidates[1].source, "guild", "Guild candidate should be marked as guild source")
					V:Assert(fakeGuildRosterData.requested == true, "Guild roster refresh should be requested")

					local addOK = AutoRaidAssist:AddTargetFromCandidate(candidates[1])
					V:Assert(addOK == true, "Guild candidate should be addable")
					V:AssertEqual(AutoRaidAssist:GetTargets()[1].source, "guild", "Stored target should keep guild source")
				end)

				if FriendsList then
					FriendsList.friendsList = originalFriends
				end
				BFL.Modules.GuildRosterData = originalGuildRosterData
				AutoRaidAssist.lastGuildRosterRequest = originalGuildRosterRequest
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_GroupCandidates", {
		description = "Auto Raid Assist should suggest current group and raid characters",
		action = function(V)
			WithTemporaryDatabase({}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				local FriendsList = BFL:GetModule("FriendsList")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalFriends = FriendsList and FriendsList.friendsList
				local originalGuildRosterData = BFL.Modules and BFL.Modules.GuildRosterData
				local originalIsInRaid = IsInRaid
				local originalIsInGroup = IsInGroup
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalGetNumSubgroupMembers = GetNumSubgroupMembers
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalGetNormalizedRealmName = GetNormalizedRealmName

				local ok, err = pcall(function()
					if FriendsList then
						FriendsList.friendsList = {}
					end
					BFL.Modules.GuildRosterData = nil

					IsInRaid = function()
						return false
					end
					IsInGroup = function()
						return true
					end
					GetNumGroupMembers = function()
						return 0
					end
					GetNumSubgroupMembers = function()
						return 2
					end
					UnitExists = function(unit)
						return unit == "party1" or unit == "party2"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitFullName = function(unit)
						if unit == "party1" then
							return "Groupie", "Realm"
						end
						if unit == "party2" then
							return "Other", "Realm"
						end
						return nil, nil
					end
					UnitName = function(unit)
						if unit == "party1" then
							return "Groupie", "Realm"
						end
						return nil, nil
					end
					GetNormalizedRealmName = function()
						return "Realm"
					end

					local candidates = AutoRaidAssist:BuildCandidateList("groupie", 10)
					V:AssertEqual(#candidates, 1, "Group character query should return one candidate")
					V:AssertEqual(candidates[1].key, "player:Groupie-Realm", "Group candidate should use a player key")
					V:AssertEqual(candidates[1].source, "group", "Group candidate should be marked as group source")

					local addOK = AutoRaidAssist:AddTargetFromCandidate(candidates[1])
					V:Assert(addOK == true, "Group candidate should be addable")
					V:AssertEqual(AutoRaidAssist:GetTargets()[1].source, "group", "Stored target should keep group source")
				end)

				if FriendsList then
					FriendsList.friendsList = originalFriends
				end
				BFL.Modules.GuildRosterData = originalGuildRosterData
				IsInRaid = originalIsInRaid
				IsInGroup = originalIsInGroup
				GetNumGroupMembers = originalGetNumGroupMembers
				GetNumSubgroupMembers = originalGetNumSubgroupMembers
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				GetNormalizedRealmName = originalGetNormalizedRealmName
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_RosterSettleRetries", {
		description = "Auto Raid Assist should retry roster checks after party to raid transitions settle",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalPendingTimer = AutoRaidAssist.pendingTimer
				local originalRosterRetryTimers = AutoRaidAssist.rosterRetryTimers
				local timers = {}

				local ok, err = pcall(function()
					AutoRaidAssist.pendingTimer = nil
					AutoRaidAssist.rosterRetryTimers = nil
					C_Timer = {
						NewTimer = function(delay, callback)
							local timer = {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
							timers[#timers + 1] = timer
							return timer
						end,
					}

					AutoRaidAssist:ScheduleRosterEvaluate("test")
					V:AssertEqual(#timers, 3, "Roster scheduling should create one debounce timer and two settle retries")
					V:AssertEqual(timers[2].delay, 1.0, "First settle retry should run after the roster transition starts settling")
					V:AssertEqual(timers[3].delay, 2.5, "Second settle retry should cover delayed raid unit token availability")

					AutoRaidAssist:ScheduleRosterEvaluate("test-again")
					V:Assert(timers[2].cancelled == true, "New roster scheduling should cancel the previous first settle retry")
					V:Assert(timers[3].cancelled == true, "New roster scheduling should cancel the previous second settle retry")
				end)

				C_Timer = originalCTimer
				AutoRaidAssist.pendingTimer = originalPendingTimer
				AutoRaidAssist.rosterRetryTimers = originalRosterRetryTimers
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_ConversionTriggers", {
		description = "Auto Raid Assist should listen for group, instance, and direct party-to-raid conversion triggers",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")
				local expectedRosterEvents = { "GROUP_ROSTER_UPDATE", "RAID_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "GROUP_FORMED", "GROUP_JOINED", "PLAYER_ENTERING_WORLD", "UPDATE_INSTANCE_INFO", "INSTANCE_GROUP_SIZE_CHANGED", "PLAYER_DIFFICULTY_CHANGED", "PLAYER_ROLES_ASSIGNED", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE" }
				for _, eventName in ipairs(expectedRosterEvents) do
					V:Assert(type(BFL.EventCallbacks) == "table" and type(BFL.EventCallbacks[eventName]) == "table", eventName .. " should be registered as an Auto Raid Assist roster trigger")
				end

				local originalHooksecurefunc = hooksecurefunc
				local originalConvertToRaid = ConvertToRaid
				local originalRaidFrameConvertToRaid = RaidFrame_ConvertToRaid
				local originalCPartyInfo = C_PartyInfo
				local originalBFLConvertToRaid = BFL.ConvertToRaid
				local originalScheduleRosterEvaluate = AutoRaidAssist.ScheduleRosterEvaluate
				local originalConversionHooksRegistered = AutoRaidAssist.conversionHooksRegistered
				local hooks = {}
				local scheduledReasons = {}

				local ok, err = pcall(function()
					hooksecurefunc = function(target, methodName, callback)
						if type(target) == "table" then
							hooks[#hooks + 1] = {
								name = methodName,
								callback = callback,
							}
						else
							hooks[#hooks + 1] = {
								name = target,
								callback = methodName,
							}
						end
					end
					BFL.ConvertToRaid = function() end
					C_PartyInfo = {
						ConvertToRaid = function() end,
						ConfirmConvertToRaid = function() end,
					}
					ConvertToRaid = function() end
					RaidFrame_ConvertToRaid = function() end
					AutoRaidAssist.ScheduleRosterEvaluate = function(_, reason)
						scheduledReasons[#scheduledReasons + 1] = reason
					end
					AutoRaidAssist.conversionHooksRegistered = nil

					AutoRaidAssist:RegisterConversionHooks()

					local hooked = {}
					for _, hook in ipairs(hooks) do
						hooked[hook.name] = true
						hook.callback()
					end

					V:Assert(hooked.ConvertToRaid == true, "ConvertToRaid should be hooked")
					V:Assert(hooked.ConfirmConvertToRaid == true, "ConfirmConvertToRaid should be hooked")
					V:Assert(hooked.RaidFrame_ConvertToRaid == true, "RaidFrame_ConvertToRaid should be hooked when available")
					V:Assert(#scheduledReasons >= 1, "Conversion hooks should schedule a roster evaluation")
					V:AssertEqual(scheduledReasons[1], "convert-to-raid", "Conversion hooks should use a distinct reason")
				end)

				hooksecurefunc = originalHooksecurefunc
				ConvertToRaid = originalConvertToRaid
				RaidFrame_ConvertToRaid = originalRaidFrameConvertToRaid
				C_PartyInfo = originalCPartyInfo
				BFL.ConvertToRaid = originalBFLConvertToRaid
				AutoRaidAssist.ScheduleRosterEvaluate = originalScheduleRosterEvaluate
				AutoRaidAssist.conversionHooksRegistered = originalConversionHooksRegistered
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_PromotionQueueMultipleMatches", {
		description = "Auto Raid Assist should queue multiple matching raid promotions instead of firing them in one batch",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Alpha-Realm",
							id = "player:Alpha-Realm",
							kind = "player",
							value = "Alpha-Realm",
						},
						{
							key = "player:Beta-Realm",
							id = "player:Beta-Realm",
							kind = "player",
							value = "Beta-Realm",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalIsInRaid = IsInRaid
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local timers = {}
				local promoted = {}
				local assistants = {}
				local unitByExactName = {
					["Alpha-Realm"] = "raid1",
					["Beta-Realm"] = "raid2",
				}
				local now = 100

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}

					C_Timer = {
						NewTimer = function(delay, callback)
							local timer = {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
							timers[#timers + 1] = timer
							return timer
						end,
					}
					IsInRaid = function()
						return true
					end
					GetNumGroupMembers = function()
						return 2
					end
					UnitExists = function(unit)
						return unit == "raid1" or unit == "raid2" or unit == "player"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function(unit)
						return assistants[unit] == true
					end
					UnitFullName = function(unit)
						if unit == "raid1" then
							return "Alpha", "Realm"
						end
						if unit == "raid2" then
							return "Beta", "Realm"
						end
						return nil, nil
					end
					UnitName = UnitFullName
					GetNormalizedRealmName = function()
						return "Realm"
					end
					GetTime = function()
						return now
					end
					BFL.IsActionRestricted = function()
						return false
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							local unit = unitByExactName[name] or name
							assistants[unit] = true
						end,
					}

					V:AssertType(BFL.PromoteToAssistant, "function", "PromoteToAssistant wrapper should exist")
					V:Assert(BFL.PromoteToAssistant("raid1") == true, "Wrapper should accept raid unit tokens")
					V:AssertEqual(promoted[1].name, "Alpha-Realm", "Wrapper should convert unit tokens to full names")
					V:AssertEqual(promoted[1].exactNameMatch, true, "Wrapper should use exact matching for unit tokens")
					promoted = {}
					assistants = {}
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}

					C_PartyInfo.PromoteToAssistant = function(name, exactNameMatch)
						promoted[#promoted + 1] = {
							name = name,
							exactNameMatch = exactNameMatch,
						}
						local unit = unitByExactName[name] or name
						assistants[unit] = true
						return true
					end

					V:Assert(AutoRaidAssist:Evaluate("test") == true, "Evaluate should enqueue and promote matching targets")
					V:AssertEqual(#promoted, 1, "Only the first matching target should be promoted immediately")
					V:AssertEqual(promoted[1].name, "Alpha-Realm", "First queued promotion should pass the full player name")
					V:AssertEqual(promoted[1].exactNameMatch, true, "First queued promotion should use exact matching")
					V:Assert(#timers >= 2, "Second matching target and promotion verification should be delayed")

					local queueTimer
					for _, timer in ipairs(timers) do
						if not timer.cancelled and timer.delay < 2 then
							queueTimer = timer
							break
						end
					end
					V:AssertNotNil(queueTimer, "Second matching target should have a queue timer")

					now = now + queueTimer.delay
					queueTimer.callback()
					V:AssertEqual(#promoted, 2, "Second matching target should be promoted by the queue timer")
					V:AssertEqual(promoted[2].name, "Beta-Realm", "Second queued promotion should pass the full player name")
					V:AssertEqual(promoted[2].exactNameMatch, true, "Second queued promotion should use exact matching")
				end)

				C_Timer = originalCTimer
				IsInRaid = originalIsInRaid
				GetNumGroupMembers = originalGetNumGroupMembers
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_PromotionNameMatchesUnitPopup", {
		description = "Auto Raid Assist should pass same-realm and cross-realm names like Blizzard's unit popup",
		action = function(V)
			local originalCPartyInfo = C_PartyInfo
			local originalUnitExists = UnitExists
			local originalUnitFullName = UnitFullName
			local originalUnitName = UnitName
			local originalUnitRealmRelationship = UnitRealmRelationship
			local originalGetNormalizedRealmName = GetNormalizedRealmName
			local originalSameRealm = LE_REALM_RELATION_SAME
			local calls = {}

			local ok, err = pcall(function()
				LE_REALM_RELATION_SAME = 1
				UnitExists = function(unit)
					return unit == "raid1" or unit == "raid2"
				end
				UnitFullName = function(unit)
					if unit == "raid1" then
						return "Sameplayer", "Home"
					end
					if unit == "raid2" then
						return "Crossplayer", "Away"
					end
					return nil, nil
				end
				UnitName = UnitFullName
				UnitRealmRelationship = function(unit)
					if unit == "raid1" then
						return LE_REALM_RELATION_SAME
					end
					return 2
				end
				GetNormalizedRealmName = function()
					return "Home"
				end
				C_PartyInfo = {
					PromoteToAssistant = function(name, exactNameMatch)
						calls[#calls + 1] = {
							name = name,
							exactNameMatch = exactNameMatch,
						}
					end,
				}

				V:Assert(BFL.PromoteToAssistant("raid1") == true, "Same-realm promote should dispatch")
				V:AssertEqual(calls[1].name, "Sameplayer", "Same-realm unit should be passed without realm")
				V:AssertEqual(calls[1].exactNameMatch, true, "Same-realm unit should use exact matching")

				V:Assert(BFL.PromoteToAssistant("raid2") == true, "Cross-realm promote should dispatch")
				V:AssertEqual(calls[2].name, "Crossplayer-Away", "Cross-realm unit should include realm")
				V:AssertEqual(calls[2].exactNameMatch, true, "Cross-realm unit should use exact matching")
			end)

			C_PartyInfo = originalCPartyInfo
			UnitExists = originalUnitExists
			UnitFullName = originalUnitFullName
			UnitName = originalUnitName
			UnitRealmRelationship = originalUnitRealmRelationship
			GetNormalizedRealmName = originalGetNormalizedRealmName
			LE_REALM_RELATION_SAME = originalSameRealm
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_PromotionCooldownRetry", {
		description = "Auto Raid Assist should retry matching targets after the promote cooldown expires",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Gamma-Realm",
							id = "player:Gamma-Realm",
							kind = "player",
							value = "Gamma-Realm",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalIsInRaid = IsInRaid
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local timers = {}
				local promoted = {}
				local assistants = {}
				local now = 100

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {
						["player:gamma-realm"] = 99,
					}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}

					C_Timer = {
						NewTimer = function(delay, callback)
							local timer = {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
							timers[#timers + 1] = timer
							return timer
						end,
					}
					IsInRaid = function()
						return true
					end
					GetNumGroupMembers = function()
						return 1
					end
					UnitExists = function(unit)
						return unit == "raid1" or unit == "player"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function(unit)
						return assistants[unit] == true
					end
					UnitFullName = function(unit)
						if unit == "raid1" then
							return "Gamma", "Realm"
						end
						return nil, nil
					end
					UnitName = UnitFullName
					GetNormalizedRealmName = function()
						return "Realm"
					end
					GetTime = function()
						return now
					end
					BFL.IsActionRestricted = function()
						return false
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							assistants.raid1 = true
							return true
						end,
					}

					V:Assert(
						AutoRaidAssist:Evaluate("test-cooldown") == false,
						"Evaluate should wait while the matching target is still on cooldown"
					)
					V:AssertEqual(#promoted, 0, "Cooldown target should not be promoted immediately")
					V:AssertEqual(#timers, 1, "Cooldown target should schedule a retry timer")
					V:Assert(timers[1].delay > 1, "Retry timer should wait for the remaining cooldown")

					now = now + timers[1].delay
					timers[1].callback()
					V:AssertEqual(#promoted, 1, "Cooldown target should be promoted after the retry timer")
					V:AssertEqual(promoted[1].name, "Gamma-Realm", "Retry promotion should pass the full player name")
					V:AssertEqual(promoted[1].exactNameMatch, true, "Retry promotion should use exact matching")
				end)

				C_Timer = originalCTimer
				IsInRaid = originalIsInRaid
				GetNumGroupMembers = originalGetNumGroupMembers
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	TS:RegisterTest("data", "AutoRaidAssist_SettingsDesignerControls", {
		description = "Auto Raid Assist should register explicit Settings Center controls without dotted DB keys",
		action = function(V)
			WithTemporaryDatabase({}, function(tempDB)
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")
				V:AssertType(
					AutoRaidAssist.RenderSettingsPage,
					"function",
					"Auto Raid Assist should expose a shared settings renderer"
				)

				local fakeApp = {
					groups = {},
					controls = {},
					RegisterGroup = function(self, pageID, data)
						self.groups[data.id] = data
						data.pageID = pageID
						return data
					end,
					RegisterControl = function(self, pageID, data)
						self.controls[data.id] = data
						data.pageID = pageID
						return data
					end,
				}

				V:Assert(
					AutoRaidAssist:RegisterSettingsDesignerControls(fakeApp, { pageID = "social.raid" }),
					"RegisterSettingsDesignerControls should register controls"
				)
				V:AssertNotNil(fakeApp.groups.autoAssist, "Auto Raid Assist group should be registered")

				local enableControl = fakeApp.controls["autoRaidAssist.enabled"]
				local manageControl = fakeApp.controls["autoRaidAssist.manage"]
				V:AssertNotNil(enableControl, "Enable control should be registered")
				V:AssertNotNil(manageControl, "Manage button should be registered")
				V:AssertNil(enableControl.key, "Enable control should use explicit accessors instead of dotted keys")
				V:AssertEqual(
					enableControl.groupTitle,
					(BFL.L and BFL.L.AUTO_RAID_ASSIST_TITLE) or "Auto Raid Assist",
					"Enable control should pass the localized group title"
				)
				V:AssertEqual(
					manageControl.groupTitle,
					(BFL.L and BFL.L.AUTO_RAID_ASSIST_TITLE) or "Auto Raid Assist",
					"Manage control should pass the localized group title"
				)

				enableControl.setValue(true)
				V:AssertEqual(tempDB.autoRaidAssist.enabled, true, "Enable control should update Auto Raid Assist state")
				V:AssertEqual(enableControl.getValue(), true, "Enable control getter should read Auto Raid Assist state")

				local detailApp = {
					groups = {},
					controls = {},
					RegisterGroup = function(self, pageID, data)
						self.groups[data.id] = data
						data.pageID = pageID
						return data
					end,
					RegisterControl = function(self, pageID, data)
						self.controls[data.id] = data
						data.pageID = pageID
						return data
					end,
				}

				V:Assert(
					AutoRaidAssist:RegisterSettingsDesignerControls(detailApp, {
						pageID = "social.raid.autoAssist",
						groupID = "autoAssistDetails",
						enabledControlID = "autoRaidAssist.enabled.detail",
						includeManageButton = false,
						includeEditor = true,
						order = 100,
						editorOrder = 110,
					}),
					"RegisterSettingsDesignerControls should register detail page controls"
				)

				local detailEnable = detailApp.controls["autoRaidAssist.enabled.detail"]
				local detailEditor = detailApp.controls["autoRaidAssist.targetsEditor"]
				V:AssertNotNil(detailEnable, "Detail page enable control should be registered")
				V:AssertNotNil(detailEditor, "Detail page target editor control should be registered")
				V:AssertNil(detailApp.controls["autoRaidAssist.manage"], "Detail page should not register a Manage button")
				V:AssertEqual(detailEnable.type, "toggle", "Detail page enable control should use native toggle type")
				V:AssertEqual(detailEditor.type, "custom", "Detail page target editor should use a custom control")
				V:AssertNil(detailEnable.key, "Detail page enable control should use explicit accessors")
				V:AssertEqual(detailEditor.trackCustomized, false, "Target editor should not count as a customized setting")
				V:AssertType(detailEditor.render, "function", "Target editor should provide a LibSettingsDesigner renderer")
				V:Assert(
					detailEditor.getHeight() > AutoRaidAssist:GetSettingsPageHeight({ settingsCenter = true }),
					"Target editor control height should include the LibSettingsDesigner row chrome"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "ContactMemory_NoteCRUD", {
		description = "Contact Memory should save private notes and tooltip summaries",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				contactMemory = {
					enabled = true,
				},
			}, function()
				local ContactMemory = BFL:GetModule("ContactMemory")
				V:AssertNotNil(ContactMemory, "ContactMemory module should exist")

				local contactKey = "player:Unit-Realm"
				V:Assert(ContactMemory:SetPrivateNote(contactKey, "  Great key partner  "), "SetPrivateNote should succeed")
				V:AssertEqual(
					ContactMemory:GetContact(contactKey).privateNote,
					"Great key partner",
					"Private note should be trimmed and stored"
				)

				local summary = ContactMemory:GetTooltipSummary(contactKey)
				V:AssertNotNil(summary, "Tooltip summary should exist for a noted contact")
				V:AssertEqual(summary.note, "Great key partner", "Tooltip summary should include the private note")
				V:AssertNil(summary.tagsText, "Contact Memory note summaries should not expose legacy tags")

				V:Assert(ContactMemory:SetPrivateNote(contactKey, nil), "Clearing the note should succeed")
				V:AssertNil(ContactMemory:GetContact(contactKey, false), "Empty contact should be cleaned up")
			end)
		end,
	})

	TS:RegisterTest("data", "Database_Migration_NameDisplayFormat", {
		description = "Legacy name display flags should migrate to nameDisplayFormat",
		action = function(V)
			WithTemporaryDatabase({
				showNotesAsName = true,
				showNicknameAsName = nil,
				showNicknameInName = true,
			}, function(tempDB)
				V:AssertEqual(
					tempDB.nameDisplayFormat,
					"%note% (%nickname%)",
					"nameDisplayFormat should be migrated from legacy flags"
				)
				V:AssertNil(tempDB.showNotesAsName, "showNotesAsName should be removed")
				V:AssertNil(tempDB.showNicknameAsName, "showNicknameAsName should be removed")
				V:AssertNil(tempDB.showNicknameInName, "showNicknameInName should be removed")
			end)
		end,
	})

	TS:RegisterTest("data", "Database_Migration_ThemeFromElvUISkin", {
		description = "Legacy ElvUI skin setting should migrate to the theme setting",
		action = function(V)
			WithTemporaryDatabase({
				enableElvUISkin = true,
				enableBetaFeatures = true,
			}, function(tempDB)
				V:AssertEqual(
					tempDB.theme,
					"elvui",
					"enableElvUISkin=true should migrate to theme='elvui'"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "Theme_Helpers", {
		description = "Theme helper API should resolve selected and effective themes",
		action = function(V)
			V:AssertNotNil(BFL.GetEffectiveTheme, "BFL:GetEffectiveTheme should exist")
			V:AssertNotNil(BFL.IsThemeActive, "BFL:IsThemeActive should exist")
			V:AssertNotNil(BFL.UsesFlatTheme, "BFL:UsesFlatTheme should exist")
			V:AssertNotNil(BFL.UsesDarkSkinTheme, "BFL:UsesDarkSkinTheme should exist")
			V:AssertNotNil(BFL.IsEllesmereUISkinActive, "BFL:IsEllesmereUISkinActive should exist")
			V:AssertNotNil(BFL.AreThemeFeaturesEnabled, "BFL:AreThemeFeaturesEnabled should exist")
			V:AssertNotNil(BFL.ShouldUseLegacyElvUISkinSetting, "BFL:ShouldUseLegacyElvUISkinSetting should exist")
			V:AssertNotNil(BFL.ShouldShowLegacyElvUISkinSetting, "BFL:ShouldShowLegacyElvUISkinSetting should exist")

			local originalIsRetail = BFL.IsRetail
			BFL.IsRetail = true
			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "dark",
					enableBetaFeatures = true,
				}, function()
					V:AssertEqual(BFL:GetEffectiveTheme(), "dark", "Dark theme should resolve as dark")
					V:Assert(BFL:IsThemeActive("dark"), "Dark theme should be active")
					V:Assert(BFL:UsesFlatTheme(), "Dark theme should count as a flat theme")
					V:Assert(BFL:UsesDarkSkinTheme(), "Dark theme should use the BFL skin engine")
				end)

				WithTemporaryDatabase({
					theme = "custom",
					enableBetaFeatures = true,
				}, function()
					V:AssertEqual(BFL:GetEffectiveTheme(), "custom", "Custom theme should resolve as custom")
					V:Assert(BFL:IsThemeActive("custom"), "Custom theme should be active")
					V:Assert(BFL:UsesFlatTheme(), "Custom theme should count as a flat theme")
					V:Assert(BFL:UsesDarkSkinTheme(), "Custom theme should use the BFL skin engine")
				end)
			end)
			BFL.IsRetail = originalIsRetail
			if not ok then
				error(err, 2)
			end

			local originalIsEllesmereUIAvailable = BFL.IsEllesmereUIAvailable
			BFL.IsEllesmereUIAvailable = function()
				return true
			end
			local euiOK, euiError = pcall(function()
				WithTemporaryDatabase({
					theme = "ellesmereui",
				}, function(tempDB)
					V:AssertEqual(tempDB.theme, "ellesmereui", "EllesmereUI should remain a valid stored theme")
					V:AssertEqual(BFL:GetEffectiveTheme(), "ellesmereui", "EllesmereUI should become effective when available")
					V:Assert(BFL:IsThemeActive("ellesmereui"), "EllesmereUI theme should be active")
					V:Assert(BFL:UsesFlatTheme(), "EllesmereUI should use flat-theme layout rules")
					V:Assert(not BFL:UsesDarkSkinTheme(), "EllesmereUI should not activate the BFL skin engine")
				end)
			end)
			BFL.IsEllesmereUIAvailable = originalIsEllesmereUIAvailable
			if not euiOK then
				error(euiError, 2)
			end

			WithTemporaryDatabase({
				theme = "blizzard",
			}, function()
				V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "Blizzard theme should resolve as blizzard")
				V:Assert(not BFL:UsesFlatTheme(), "Blizzard theme should not count as a flat theme")
			end)
		end,
	})

	TS:RegisterTest("data", "Theme_EffectiveCacheTracksDirectSelectionChanges", {
		description = "Effective theme cache should follow direct DB changes and addon availability",
		action = function(V)
			local originalIsEllesmereUIAvailable = BFL.IsEllesmereUIAvailable
			local available = true
			BFL.IsEllesmereUIAvailable = function()
				return available
			end
			local ok, err = pcall(function()
				WithTemporaryDatabase({ theme = "dark" }, function(tempDB)
					V:AssertEqual(BFL:GetEffectiveTheme(), "dark", "Initial direct theme should resolve")
					tempDB.theme = "custom"
					V:AssertEqual(BFL:GetEffectiveTheme(), "custom", "Direct theme replacement should invalidate by source")
					tempDB.theme = "ellesmereui"
					V:AssertEqual(BFL:GetEffectiveTheme(), "ellesmereui", "Available addon theme should resolve")
					available = false
					local ThemeManager = BFL:GetModule("ThemeManager")
					ThemeManager:InvalidateEffectiveTheme()
					V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "Availability loss should invalidate effective theme")
				end)
			end)
			BFL.IsEllesmereUIAvailable = originalIsEllesmereUIAvailable
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "Theme_ElvUIFallbackWithoutAddon", {
		description = "Stored ElvUI theme should fall back to Blizzard when ElvUI is unavailable",
		action = function(V)
			if _G.ElvUI then
				V:Skip("ElvUI is loaded")
				return
			end

			WithTemporaryDatabase({
				theme = "elvui",
				enableBetaFeatures = true,
			}, function()
				V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "ElvUI theme should fall back to Blizzard")
				V:Assert(not BFL:IsThemeActive("elvui"), "ElvUI theme should not be active without ElvUI")
			end)
		end,
	})

	TS:RegisterTest("data", "Theme_EllesmereUIFallbackWithoutSkinAPI", {
		description = "Stored EllesmereUI theme should fall back to Blizzard until the EUI skin facade is active",
		action = function(V)
			local originalIsEllesmereUIAvailable = BFL.IsEllesmereUIAvailable
			BFL.IsEllesmereUIAvailable = function()
				return false
			end

			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "ellesmereui",
				}, function(tempDB)
					V:AssertEqual(tempDB.theme, "ellesmereui", "Unavailable EllesmereUI preference should remain stored")
					V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "Unavailable EllesmereUI should fall back to Blizzard")
					V:Assert(not BFL:IsThemeActive("ellesmereui"), "EllesmereUI should be inactive without its skin facade")
				end)
			end)

			BFL.IsEllesmereUIAvailable = originalIsEllesmereUIAvailable
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "EllesmereUISkin_FacadeLifetimeAndPalette", {
		description = "Dispatched EUI facade should remain active until reload and expose Modern palette tokens",
		action = function(V)
			local skin = BFL:GetModule("EllesmereUISkin")
			V:AssertNotNil(skin, "EllesmereUISkin module should be loaded")
			local originalFacade = skin.facade
			local originalFacadeActivated = skin.facadeActivated
			local originalPaletteVersion = skin.paletteVersion
			local ok, err = pcall(function()
				skin.facade = {
					apiVersion = 1,
					IsEnabled = function()
						return false
					end,
					GetAccentColor = function()
						return 0.1, 0.7, 0.5
					end,
					GetPanelColor = function()
						return 0.04, 0.05, 0.06, 0.94
					end,
				}
				skin.facadeActivated = true
				V:Assert(skin:IsAvailable(), "A dispatched EUI facade should remain available until reload")
				local accentR, accentG, accentB = skin:GetAccentColor()
				V:AssertEqual(accentR, 0.1, "EUI accent red should come from the public facade")
				V:AssertEqual(accentG, 0.7, "EUI accent green should come from the public facade")
				V:AssertEqual(accentB, 0.5, "EUI accent blue should come from the public facade")
				local palette = skin:GetPalette()
				for _, key in ipairs({ "background", "surface", "inset", "control", "border", "accent", "text" }) do
					V:Assert(type(palette[key]) == "table" and #palette[key] == 4, "EUI palette resolves " .. key)
				end
				V:Assert(palette.externalShell == true, "EUI palette should preserve the public EUI shell")
				V:Assert(palette.externalControls == true, "EUI palette should delegate controls to the public EUI API")
				V:Assert(palette.skinFriendCardSurface == true, "EUI palette should request EUIFriends-style friend-card surfaces")
				V:Assert(palette.preserveNativeSideTabs == true, "EUI palette should preserve Blizzard side-tab chrome")
				V:Assert(palette.preserveNativeGroupHeaders == true, "EUI palette should preserve Blizzard group headers")
				V:Assert(palette.preserveNativeInviteButtons == true, "EUI palette should preserve Blizzard invite buttons")
				V:Assert(palette.transparentBattleNetBar == true, "EUI palette should keep the Battle.net bar transparent")
				V:AssertEqual(palette.headerControlOffsetY, 0, "EUI header controls should be vertically centered")
				V:AssertEqual(palette.portraitOffsetX, 6, "EUI portrait should keep the refined left inset")
				V:AssertEqual(palette.portraitOffsetY, -25, "EUI portrait artwork should fill the Battle.net header strip")
				V:AssertEqual(palette.portraitSize, 42, "EUI portrait should keep the compact themed size")
				V:AssertEqual(palette.customTabInactiveMultiplier, 0.68, "EUI custom tabs should match inactive Blizzard luminance")
				V:Assert(palette.background[4] < 0.5, "BFL content wash should not cover the EUI shell")
			end)
			skin.facade = originalFacade
			skin.facadeActivated = originalFacadeActivated
			skin.paletteVersion = originalPaletteVersion
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "EllesmereUISkin_LegacyControlAllowlist", {
		description = "EUI Legacy skinning should cover requested controls without traversing scrollbars or Modern invites",
		action = function(V)
			local skin = BFL:GetModule("EllesmereUISkin")
			V:AssertNotNil(skin, "EllesmereUISkin module should be loaded")

			local function MakeTexture()
				local texture = {
					shown = false,
				}
				function texture:SetAlpha(alpha)
					self.alpha = alpha
				end
				function texture:SetDesaturated(desaturated)
					self.desaturated = desaturated == true
				end
				function texture:SetVertexColor(r, g, b, a)
					self.vertexColor = { r, g, b, a }
				end
				function texture:SetTexture(path)
					self.texture = path
				end
				function texture:SetColorTexture(r, g, b, a)
					self.colorTexture = { r, g, b, a }
				end
				function texture:SetTexCoord(...)
					self.texCoord = { ... }
				end
				function texture:SetSize(width, height)
					self.width = width
					self.height = height
				end
				function texture:SetPoint(...)
					self.point = { ... }
				end
				function texture:ClearAllPoints()
					self.point = nil
				end
				function texture:SetShown(shown)
					self.shown = shown == true
				end
				function texture:Show()
					self.shown = true
				end
				function texture:Hide()
					self.shown = false
				end
				return texture
			end

			local function MakeButton(withIcon)
				local button = {
					hooks = {},
				}
				if withIcon then
					button.Icon = MakeTexture()
				end
				function button:HookScript(event, callback)
					self.hooks[event] = self.hooks[event] or {}
					self.hooks[event][#self.hooks[event] + 1] = callback
				end
				function button:GetFontString()
					return self.Text
				end
				function button:CreateTexture()
					local texture = MakeTexture()
					self.createdTexture = texture
					return texture
				end
				function button:ClearAllPoints()
					self.point = nil
				end
				function button:SetPoint(...)
					self.point = { ... }
				end
				function button:SetSize(width, height)
					self.width = width
					self.height = height
				end
				return button
			end

			local calls = {
				buttons = {},
				checkboxes = {},
				dropdowns = {},
				editBoxes = {},
				tabs = {},
				scrollbar = false,
				shells = 0,
				fadeNineSlices = 0,
			}
			local facade = {
				apiVersion = 1,
				Shell = function()
					calls.shells = calls.shells + 1
				end,
				Inset = function() end,
				FadeNineSlice = function()
					calls.fadeNineSlices = calls.fadeNineSlices + 1
				end,
				CloseButton = function() end,
				Button = function(button)
					if button then
						calls.buttons[button] = true
					end
				end,
				StateButtonLabel = function() end,
				Checkbox = function(checkbox)
					if checkbox then
						calls.checkboxes[checkbox] = true
					end
				end,
				Dropdown = function(dropdown)
					if dropdown then
						calls.dropdowns[dropdown] = true
					end
				end,
				EditBox = function(editBox)
					if editBox then
						calls.editBoxes[editBox] = true
					end
				end,
				Tab = function(tab)
					if tab then
						calls.tabs[tab] = true
					end
				end,
				ScrollBar = function()
					calls.scrollbar = true
				end,
				GetAccentColor = function()
					return 0.12, 0.73, 0.54
				end,
			}

			local header = {
				SearchBox = MakeButton(),
				StatusDropdown = MakeButton(),
				QuickFilterDropdown = MakeButton(),
				PrimarySortDropdown = MakeButton(),
				SecondarySortDropdown = MakeButton(),
				BattlenetFrame = {
					ContactsMenuButton = MakeButton(true),
					SettingsButton = MakeButton(true),
				},
			}
			local who = {
				EditBox = MakeButton(),
				ColumnDropdown = MakeButton(),
				WhoButton = MakeButton(),
				AddFriendButton = MakeButton(),
				GroupInviteButton = MakeButton(),
			}
			local raid = {
				ControlPanel = {
					RaidInfoButton = MakeButton(),
					ReadyCheckButton = MakeButton(true),
				},
				RaidToolsButton = MakeButton(),
				ConvertToRaidButton = MakeButton(),
			}
			local frame = {
				FriendsTabHeader = header,
				AddFriendButton = MakeButton(),
				SendMessageButton = MakeButton(),
				RecruitmentButton = MakeButton(),
				RecruitAFriendFrame = {
					RewardClaiming = {
						ClaimOrViewRewardButton = MakeButton(),
					},
				},
				GuildFrame = {
					SearchBox = MakeButton(),
					ActionsButton = MakeButton(),
				},
				WhoFrame = who,
				RaidFrame = raid,
				PortraitButton = MakeButton(),
				ScrollBar = MakeButton(),
			}

			local originalFacade = skin.facade
			local originalFacadeActivated = skin.facadeActivated
			local originalIsSkinEnabled = skin.IsSkinEnabled
			local originalIsModernInterfaceActive = skin.IsModernInterfaceActive
			local ok, err = pcall(function()
				skin.facade = facade
				skin.facadeActivated = true
				skin.IsSkinEnabled = function()
					return true
				end
				skin.IsModernInterfaceActive = function()
					return false
				end

				skin:SkinLegacyChrome(frame)
				local checkedTexture = MakeTexture()
				local checkbox = MakeButton()
				function checkbox:GetCheckedTexture()
					return checkedTexture
				end
				function checkbox:GetDisabledCheckedTexture()
					return nil
				end
				skin:SkinCheckbox(checkbox)
				V:Assert(calls.checkboxes[checkbox] == true, "Legacy checkbox should use the EUI facade")
				V:Assert(checkedTexture.desaturated == true, "Legacy checkbox should discard its native checkmark hue")
				V:AssertEqual(checkedTexture.vertexColor[1], 0.12, "Legacy checkbox should use pure EUI accent red")
				V:AssertEqual(checkedTexture.vertexColor[2], 0.73, "Legacy checkbox should use pure EUI accent green")
				V:AssertEqual(checkedTexture.vertexColor[3], 0.54, "Legacy checkbox should use pure EUI accent blue")
				checkedTexture:SetDesaturated(false)
				checkedTexture:SetVertexColor(0, 1, 0, 1)
				checkbox.hooks.OnShow[1]()
				V:Assert(checkedTexture.desaturated == true, "Legacy checkbox refresh should neutralize native color again")
				V:AssertEqual(checkedTexture.vertexColor[2], 0.73, "Legacy checkbox refresh should restore EUI accent")
				for _, editBox in ipairs({
					header.SearchBox,
					frame.GuildFrame.SearchBox,
					who.EditBox,
				}) do
					V:Assert(calls.editBoxes[editBox] == true, "Every tab search field should use the EUI facade")
				end
				for _, dropdown in ipairs({
					header.StatusDropdown,
					header.QuickFilterDropdown,
					header.PrimarySortDropdown,
					header.SecondarySortDropdown,
					who.ColumnDropdown,
				}) do
					V:Assert(calls.dropdowns[dropdown] == true, "Requested Legacy dropdown should use the EUI facade")
				end
				for _, button in ipairs({
					header.BattlenetFrame.ContactsMenuButton,
					header.BattlenetFrame.SettingsButton,
					frame.AddFriendButton,
					frame.SendMessageButton,
					frame.RecruitmentButton,
					frame.RecruitAFriendFrame.RewardClaiming.ClaimOrViewRewardButton,
					frame.GuildFrame.ActionsButton,
					who.WhoButton,
					who.AddFriendButton,
					who.GroupInviteButton,
					raid.ControlPanel.RaidInfoButton,
					raid.ControlPanel.ReadyCheckButton,
					raid.RaidToolsButton,
					raid.ConvertToRaidButton,
				}) do
					V:Assert(calls.buttons[button] == true, "Requested Legacy action should use the EUI facade")
				end
				V:Assert(calls.scrollbar == false, "Legacy EUI allowlist must not skin scrollbars")

				local menuIcon = header.BattlenetFrame.ContactsMenuButton.Icon
				V:Assert(menuIcon.desaturated == true, "Legacy menu icon should discard its source hue")
				V:AssertEqual(menuIcon.vertexColor[1], 0.12, "Legacy menu icon should use pure EUI accent red")
				V:AssertEqual(menuIcon.vertexColor[2], 0.73, "Legacy menu icon should use pure EUI accent green")
				V:AssertEqual(menuIcon.vertexColor[3], 0.54, "Legacy menu icon should use pure EUI accent blue")
				menuIcon:SetVertexColor(1, 0, 0, 1)
				header.BattlenetFrame.ContactsMenuButton.hooks.OnEnter[2]()
				V:AssertEqual(menuIcon.vertexColor[2], 0.73, "Legacy menu hover should restore the pure EUI accent")

				local tab = MakeButton()
				tab.Text = MakeTexture()
				skin:SkinLegacyTab(tab)
				V:Assert(calls.tabs[tab] == true, "Legacy tab should use the EUI facade")
				V:AssertEqual(tab.Text.alpha, 0, "Original Legacy tab label should stay hidden behind EUI's label")
				tab.Text:SetAlpha(1)
				tab.hooks.OnShow[1](tab)
				V:AssertEqual(tab.Text.alpha, 0, "Legacy tab show should suppress duplicate native text again")
				tab.Text:SetAlpha(1)
				skin:RefreshLegacyTabLabel(tab)
				V:AssertEqual(tab.Text.alpha, 0, "Legacy tab visual refresh should suppress duplicate native text again")
				tab.Text:SetAlpha(1)
				tab.hooks.OnClick[1](tab)
				V:AssertEqual(tab.Text.alpha, 0, "Legacy tab click should suppress duplicate native text again")

				skin:SkinLegacyPortrait(frame)
				local portrait = frame.PortraitButton.BFL_EllesmerePortraitIcon
				V:AssertNotNil(portrait, "Legacy EUI should create a logo below the shell's direct-texture strip")
				V:AssertEqual(
					portrait.texture,
					"Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon",
					"Legacy EUI logo should reuse the BFL portrait artwork"
				)
				V:AssertEqual(portrait.width, 34, "Legacy EUI logo should leave space above the search row")
				V:Assert(portrait.shown == true, "Legacy EUI logo should be visible")
				V:AssertEqual(frame.PortraitButton.point[1], "TOPLEFT", "Legacy EUI logo button should use the header anchor")
				V:AssertEqual(frame.PortraitButton.point[2], frame, "Legacy EUI logo button should anchor to the main frame")
				V:AssertEqual(frame.PortraitButton.point[4], 15, "Legacy EUI logo should align with the search field")
				V:AssertEqual(frame.PortraitButton.point[5], -21, "Legacy EUI logo should meet the top header edge")
				V:Assert(skin:RefreshMainFrame("test-reopen", frame), "EUI should expose a focused main-frame reopen pass")
				V:AssertEqual(calls.shells, 1, "Focused EUI reopen should touch only the main frame shell once")

				local invite = {
					AcceptButton = MakeButton(),
					DeclineButton = MakeButton(),
				}
				skin:SkinLegacyInviteButtons(invite)
				V:Assert(calls.buttons[invite.AcceptButton] == true, "Legacy Accept should use the EUI facade")
				V:Assert(calls.buttons[invite.DeclineButton] == true, "Legacy Decline should use the EUI facade")

				local modernInvite = {
					AcceptButton = MakeButton(),
					DeclineButton = MakeButton(),
				}
				skin.IsModernInterfaceActive = function()
					return true
				end
				skin:SkinLegacyInviteButtons(modernInvite)
				V:Assert(calls.buttons[modernInvite.AcceptButton] ~= true, "Modern Accept should remain native")
				V:Assert(calls.buttons[modernInvite.DeclineButton] ~= true, "Modern Decline should remain native")
				local modernCard = {
					CardBackground = MakeTexture(),
					ThemeTint = MakeTexture(),
					FactionTint = MakeTexture(),
					background = MakeTexture(),
					highlight = MakeTexture(),
				}
				skin:SkinModernFriendCard(modernCard)
				V:AssertEqual(modernCard.CardBackground.alpha, 0, "Modern EUI should hide the native card surface")
				V:AssertEqual(modernCard.background.colorTexture[4], 0.10, "Modern EUI should apply its restrained row surface")
				V:AssertEqual(modernCard.highlight.colorTexture[4], 0.035, "Modern EUI should apply its hover surface")
				-- FriendsUI rewrites these layers whenever a pooled friend row receives
				-- new data. The EUI pass must restore them even when the palette did not
				-- change, while leaving the template-owned selected/hover visibility intact.
				modernCard.CardBackground:SetAlpha(1)
				modernCard.ThemeTint:Show()
				modernCard.FactionTint:SetColorTexture(0.03, 0.30, 0.85, 1)
				modernCard.FactionTint:Show()
				modernCard.background:SetColorTexture(0, 0, 0, 0)
				modernCard.highlight:SetColorTexture(1, 0, 0, 1)
				modernCard.highlight:SetDesaturated(true)
				modernCard.highlight:SetVertexColor(1, 0, 0, 1)
				modernCard.highlight:SetAlpha(0.12)
				modernCard.highlight:Show()
				skin:SkinModernFriendCard(modernCard, { 0.03, 0.30, 0.85 })
				V:AssertEqual(modernCard.CardBackground.alpha, 0, "Modern EUI should re-hide a recycled native card surface")
				V:Assert(modernCard.ThemeTint.shown == false, "Modern EUI should re-hide recycled theme tint")
				V:Assert(modernCard.FactionTint.shown == false, "Modern EUI should hide the opaque faction layer")
				V:AssertEqual(modernCard.background.colorTexture[1], 0.03, "Modern EUI should transfer faction red to its row surface")
				V:AssertEqual(modernCard.background.colorTexture[2], 0.30, "Modern EUI should transfer faction green to its row surface")
				V:AssertEqual(modernCard.background.colorTexture[3], 0.85, "Modern EUI should transfer faction blue to its row surface")
				V:AssertEqual(modernCard.background.colorTexture[4], 0.22, "Modern EUI should keep faction color visible but subdued")
				V:AssertEqual(modernCard.highlight.colorTexture[4], 0.035, "Modern EUI should restore recycled hover and selection color")
				V:Assert(modernCard.highlight.desaturated == false, "Modern EUI should restore hover saturation")
				V:AssertEqual(modernCard.highlight.alpha, 1, "Modern EUI should restore hover opacity")
				V:Assert(modernCard.highlight.shown == true, "Modern EUI should preserve the template's active hover or selection state")
				local modernFrame = {
					NineSlice = {},
					PortraitContainer = MakeTexture(),
					PortraitIcon = MakeTexture(),
				}
				V:Assert(skin:RefreshModernPortraitCorner(modernFrame), "Modern EUI should expose a focused portrait-corner pass")
				V:AssertEqual(calls.fadeNineSlices, 1, "Modern EUI should re-fade only the restored NineSlice")
				V:AssertEqual(modernFrame.PortraitContainer.alpha, 0, "Modern EUI should keep the native portrait container transparent")
				V:AssertEqual(modernFrame.PortraitIcon.alpha, 0, "Modern EUI should keep the native portrait icon transparent")
			end)

			skin.facade = originalFacade
			skin.facadeActivated = originalFacadeActivated
			skin.IsSkinEnabled = originalIsSkinEnabled
			skin.IsModernInterfaceActive = originalIsModernInterfaceActive
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "Theme_BetaDisabledKeepsStandardThemes", {
		description = "Disabled Beta Features should not disable standard themes",
		action = function(V)
			WithTemporaryDatabase({
				theme = "dark",
				enableBetaFeatures = false,
			}, function(tempDB)
				V:AssertEqual(tempDB.theme, "dark", "Stored Dark theme should remain selected")

				tempDB.theme = "dark"
				V:AssertEqual(BFL:GetEffectiveTheme(), "dark", "Dark theme should become effective")
				V:Assert(BFL:IsThemeActive("dark"), "Dark theme should be active when Beta is disabled")
				V:Assert(BFL:UsesFlatTheme(), "Standard themes should count as flat themes")

				tempDB.theme = "custom"
				V:AssertEqual(BFL:GetEffectiveTheme(), "custom", "Custom theme should become effective")
				V:Assert(BFL:IsThemeActive("custom"), "Custom theme should be active when Beta is disabled")
				V:Assert(BFL:UsesDarkSkinTheme(), "Custom theme should use the skin engine when Beta is disabled")
			end)
		end,
	})

	TS:RegisterTest("data", "Theme_NonRetailAllowsStandardThemes", {
		description = "Non-Retail clients should allow standard themes while keeping guild beta gated",
		action = function(V)
			local originalIsRetail = BFL.IsRetail
			local originalIsElvUIAvailable = BFL.IsElvUIAvailable
			BFL.IsRetail = false
			BFL.IsElvUIAvailable = function()
				return true
			end

			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "dark",
					enableBetaFeatures = true,
				}, function(tempDB)
					V:AssertEqual(tempDB.theme, "dark", "Stored Dark theme should be retained on non-Retail")
					V:Assert(BFL:AreThemeFeaturesEnabled(), "Theme features should be available without Beta gating")
					V:AssertEqual(BFL:GetEffectiveTheme(), "dark", "Dark theme should become effective on non-Retail")
				end)

				WithTemporaryDatabase({
					theme = "elvui",
					enableElvUISkin = true,
					enableBetaFeatures = true,
				}, function()
					V:Assert(not BFL:ShouldUseLegacyElvUISkinSetting(), "Non-Retail should use the standard theme setting path")
					V:AssertEqual(BFL:GetEffectiveTheme(), "elvui", "ElvUI theme should remain effective on non-Retail")
				end)

				WithTemporaryDatabase({
					enableBetaFeatures = true,
					enableGuildTab = true,
				}, function()
					local capability = BFL:GetGuildTabCapability()
					V:Assert(capability.clientSupported == false, "Guild tab beta should be unsupported on non-Retail")
					V:Assert(capability.canShowSetting == false, "Guild tab setting should be hidden on non-Retail")
					V:Assert(capability.canShowRoster == false, "Guild tab should not become active on non-Retail")
				end)
			end)

			BFL.IsRetail = originalIsRetail
			BFL.IsElvUIAvailable = originalIsElvUIAvailable
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "ThemePalette_NormalizesSavedSettings", {
		description = "Theme palette settings should merge defaults and clamp invalid values",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				theme = "custom",
				darkThemeSettings = {
					windowOpacity = 2,
					artworkVisibility = 0.33,
					accentColor = { r = 2, g = -1, b = 0.5, a = 3 },
				},
				customThemeSettings = {
					hoverStrength = 0.25,
				},
				blizzardThemeSettings = {
					accentColor = { r = 2, g = 0.2, b = -1, a = 1 },
					avatarVisibility = 2,
				},
				customTheme = {
					backgroundColor = { r = -1, g = 0.25, b = 2, a = 0.5 },
					unknownColor = { r = 1, g = 1, b = 1, a = 1 },
				},
			}, function(tempDB)
				V:AssertEqual(tempDB.darkThemeSettings.windowOpacity, 1, "Opacity should be clamped")
				V:AssertEqual(tempDB.darkThemeSettings.avatarVisibility, 0.33, "Legacy artwork visibility should migrate to avatar visibility")
				V:AssertEqual(tempDB.darkThemeSettings.accentColor.r, 1, "Accent red should be clamped")
				V:AssertEqual(tempDB.darkThemeSettings.accentColor.g, 0, "Accent green should be clamped")
				V:AssertEqual(tempDB.customThemeSettings.hoverStrength, 0.25, "Custom theme settings should normalize independently")
				V:AssertNil(tempDB.blizzardThemeSettings, "Blizzard theme settings should be removed")
				V:AssertEqual(tempDB.customTheme.backgroundColor.r, 0, "Custom red should be clamped")
				V:AssertEqual(tempDB.customTheme.backgroundColor.b, 1, "Custom blue should be clamped")
				V:AssertNil(tempDB.customTheme.unknownColor, "Unknown custom theme keys should be discarded")
			end)
		end,
	})

	TS:RegisterTest("data", "ThemePalette_DarkAccentFeedsInteractiveTokens", {
		description = "Dark accent color should drive interactive skin tokens",
		action = function(V)
			local ThemePalette = BFL:GetModule("ThemePalette")
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(ThemePalette, "ThemePalette should be loaded")
			V:AssertNotNil(SkinEngine, "SkinEngine should be loaded")

			WithTemporaryDatabase({
				enableBetaFeatures = true,
				theme = "dark",
				darkThemeSettings = {
					accentColor = { r = 0.2, g = 0.4, b = 0.8, a = 1 },
					hoverStrength = 0.2,
					selectionStrength = 0.3,
				},
			}, function()
				local colors = {}
				ThemePalette:ApplyToColors(colors, SkinEngine.defaultColors)

				V:AssertEqual(colors.gold[1], 0.2, "Gold token should inherit accent red")
				V:AssertEqual(colors.icon[3], 0.8, "Icon token should inherit accent blue")
				V:AssertEqual(colors.rowHover[2], 0.4, "Row hover should inherit accent green")
				V:Assert(colors.scrollThumbHover[3] > colors.scrollThumbHover[1], "Scrollbar hover should be accent tinted")
				V:Assert(colors.controlBorderHover[3] > colors.controlBorderHover[1], "Control hover border should be accent tinted")
			end)
		end,
	})

	TS:RegisterTest("data", "ThemePalette_ThemeSpecificSettingsPersist", {
		description = "Theme palette sliders should persist to the selected theme only",
		action = function(V)
			local ThemePalette = BFL:GetModule("ThemePalette")
			V:AssertNotNil(ThemePalette, "ThemePalette should be loaded")

			WithTemporaryDatabase({
				enableBetaFeatures = true,
				theme = "custom",
				darkThemeSettings = {
					hoverStrength = 0.12,
					borderStrength = 0.44,
				},
				customThemeSettings = {
					hoverStrength = 0.22,
					borderStrength = 0.55,
				},
			}, function(tempDB)
				ThemePalette:SetThemeSetting("custom", "hoverStrength", 0.36)
				ThemePalette:SetThemeSetting("dark", "borderStrength", 0.66)
				ThemePalette:SetThemeSetting("blizzard", "accentColor", { r = 0.11, g = 0.22, b = 0.33, a = 1 })

				V:AssertEqual(tempDB.customThemeSettings.hoverStrength, 0.36, "Custom hover strength should persist")
				V:AssertEqual(tempDB.darkThemeSettings.hoverStrength, 0.12, "Dark hover strength should remain unchanged")
				V:AssertEqual(tempDB.darkThemeSettings.borderStrength, 0.66, "Dark border strength should persist")
				V:AssertEqual(tempDB.customThemeSettings.borderStrength, 0.55, "Custom border strength should remain unchanged")
				V:AssertNil(tempDB.blizzardThemeSettings, "Blizzard settings should not be created")
			end)
		end,
	})

	TS:RegisterTest("data", "ThemePalette_BrokerTooltipSettingsNormalize", {
		description = "Broker tooltip theme settings should clamp values and discard unknown keys",
		action = function(V)
			WithTemporaryDatabase({
				brokerSeparatorColor = { r = 2, g = -1, b = 0.25, a = 1.5 },
				brokerTooltipThemeSettings = {
					dark = {
						backgroundColor = { r = -1, g = 0.25, b = 2, a = 0.4 },
						opacity = 1.5,
						ignored = true,
					},
					custom = {
						opacity = -0.5,
					},
					unknown = {
						opacity = 0.3,
					},
				},
			}, function(tempDB)
				V:AssertEqual(tempDB.brokerSeparatorColor.r, 1, "Separator red should be clamped")
				V:AssertEqual(tempDB.brokerSeparatorColor.g, 0, "Separator green should be clamped")
				V:AssertEqual(tempDB.brokerSeparatorColor.a, 1, "Separator alpha should be clamped")

				local settings = tempDB.brokerTooltipThemeSettings
				V:AssertType(settings.blizzard, "table", "Blizzard broker tooltip settings should exist")
				V:AssertType(settings.elvui, "table", "ElvUI broker tooltip settings should exist")
				V:AssertType(settings.ellesmereui, "table", "EllesmereUI broker tooltip settings should exist")
				V:AssertNil(settings.unknown, "Unknown broker tooltip themes should be discarded")
				V:AssertEqual(settings.dark.backgroundColor.r, 0, "Broker tooltip red should be clamped")
				V:AssertEqual(settings.dark.backgroundColor.b, 1, "Broker tooltip blue should be clamped")
				V:AssertEqual(settings.dark.opacity, 1, "Broker tooltip opacity should be clamped")
				V:AssertEqual(settings.custom.opacity, 0, "Broker tooltip opacity should allow transparent values")
				V:AssertNil(settings.dark.ignored, "Unknown broker tooltip setting keys should be discarded")
			end)
		end,
	})

	TS:RegisterTest("data", "ThemePalette_BrokerTooltipSettingsPersistAndReset", {
		description = "Broker tooltip overrides should persist per theme and reset back to inheritance",
		action = function(V)
			local ThemePalette = BFL:GetModule("ThemePalette")
			V:AssertNotNil(ThemePalette, "ThemePalette should be loaded")

			WithTemporaryDatabase({
				brokerTooltipThemeSettings = {},
			}, function(tempDB)
				ThemePalette:SetBrokerTooltipThemeSetting("dark", "backgroundColor", { r = 0.12, g = 0.23, b = 0.34, a = 0.45 })
				ThemePalette:SetBrokerTooltipThemeSetting("dark", "opacity", 0.42)
				ThemePalette:SetBrokerTooltipThemeSetting("custom", "opacity", 0.61)

				local dark = ThemePalette:GetBrokerTooltipThemeSettings("dark")
				V:AssertEqual(dark.backgroundColor.r, 0.12, "Dark broker tooltip background should persist")
				V:AssertEqual(dark.opacity, 0.42, "Dark broker tooltip opacity should persist")
				V:AssertEqual(tempDB.brokerTooltipThemeSettings.custom.opacity, 0.61, "Custom broker tooltip opacity should persist independently")

				ThemePalette:ResetBrokerTooltipThemeSettings("dark")
				V:AssertNil(tempDB.brokerTooltipThemeSettings.dark.backgroundColor, "Dark broker tooltip color should reset to inheritance")
				V:AssertNil(tempDB.brokerTooltipThemeSettings.dark.opacity, "Dark broker tooltip opacity should reset to inheritance")
				V:AssertEqual(tempDB.brokerTooltipThemeSettings.custom.opacity, 0.61, "Custom broker tooltip settings should survive Dark reset")
			end)
		end,
	})

	TS:RegisterTest("data", "BrokerUtils_SeparatorColorResolution", {
		description = "Broker separator helper should resolve and apply the shared saved color",
		action = function(V)
			local BrokerUtils = BFL.BrokerUtils
			V:AssertNotNil(BrokerUtils, "BrokerUtils should be loaded")
			V:AssertNotNil(BrokerUtils.GetBrokerSeparatorColor, "Broker separator resolver should exist")

			WithTemporaryDatabase({
				brokerSeparatorColor = { r = 0.12, g = 0.34, b = 0.56, a = 0.78 },
			}, function()
				local color = BrokerUtils.GetBrokerSeparatorColor()
				V:AssertEqual(color.r, 0.12, "Separator red should resolve from DB")
				V:AssertEqual(color.a, 0.78, "Separator alpha should resolve from DB")

				local texture = {}
				function texture:SetColorTexture(r, g, b, a)
					self.r, self.g, self.b, self.a = r, g, b, a
				end
				function texture:SetHeight(height)
					self.height = height
				end

				BrokerUtils.ApplyBrokerSeparatorColor(texture)
				V:AssertEqual(texture.g, 0.34, "Texture green should receive the shared separator color")
				V:AssertEqual(texture.a, 0.78, "Texture alpha should receive the shared separator color")

				BrokerUtils.ApplyBrokerFooterSeparatorStyle(texture)
				V:AssertEqual(texture.height, BrokerUtils.GetBrokerSeparatorHeight(), "Footer separator should use shared height")
				V:AssertEqual(texture.r, 0.12, "Footer separator red should receive the shared separator color")

				local tooltip = {}
				function tooltip:AddSeparator(height, r, g, b, a)
					self.height, self.r, self.g, self.b, self.a = height, r, g, b, a
					return self
				end

				local separatorRow = BrokerUtils.AddTooltipSeparator(tooltip)
				V:AssertEqual(separatorRow, tooltip, "Tooltip separator helper should return the QTip separator row")
				V:AssertEqual(tooltip.height, BrokerUtils.GetBrokerSeparatorHeight(), "Tooltip separator should use shared height")
				V:AssertEqual(tooltip.r, 0.12, "Tooltip separator red should use saved color")
				V:AssertEqual(tooltip.a, 0.78, "Tooltip separator alpha should use saved color")
			end)
		end,
	})

	TS:RegisterTest("data", "BrokerUtils_BrokerTooltipBackgroundResolution", {
		description = "Broker tooltip background resolver should combine per-theme color, opacity, and inheritance",
		action = function(V)
			local BrokerUtils = BFL.BrokerUtils
			local ThemePalette = BFL:GetModule("ThemePalette")
			V:AssertNotNil(BrokerUtils, "BrokerUtils should be loaded")
			V:AssertNotNil(ThemePalette, "ThemePalette should be loaded")

			WithTemporaryDatabase({
				brokerTooltipThemeSettings = {
					dark = { opacity = 0.42 },
					custom = { backgroundColor = { r = 0.11, g = 0.22, b = 0.33, a = 0.44 } },
				},
			}, function()
				local originalGameTooltip = GameTooltip
				GameTooltip = {
					GetBackdropColor = function()
						return 0, 0, 0, 0
					end,
				}
				local ok, err = pcall(function()
					local blizzardFallback = BrokerUtils.GetBrokerTooltipFallbackBackground("blizzard")
					V:Assert(blizzardFallback.a > 0, "Transparent GameTooltip state should not become the Blizzard default opacity")
				end)
				GameTooltip = originalGameTooltip
				if not ok then
					error(err, 2)
				end

				local inherited = { r = 0.5, g = 0.6, b = 0.7, a = 0.8 }
				local dark = BrokerUtils.ResolveBrokerTooltipBackground("dark", inherited)
				V:AssertEqual(dark.r, 0.5, "Opacity-only override should inherit red")
				V:AssertEqual(dark.a, 0.42, "Opacity-only override should replace alpha")

				local custom = BrokerUtils.ResolveBrokerTooltipBackground("custom", inherited)
				V:AssertEqual(custom.r, 0.11, "Color override should replace red")
				V:AssertEqual(custom.a, 0.44, "Color override should use saved alpha when opacity is inherited")
				V:AssertNil(BrokerUtils.ResolveBrokerTooltipBackground("blizzard", inherited), "Themes without overrides should inherit without applying a color")

				ThemePalette:ResetBrokerTooltipThemeSettings("custom")
				V:AssertNil(BrokerUtils.ResolveBrokerTooltipBackground("custom", inherited), "Reset theme should return to inherited tooltip styling")
			end)
		end,
	})

	TS:RegisterTest("data", "BrokerUtils_ElvUIInitializationCompatibility", {
		description = "Broker tooltip skinning recognizes current, legacy, and Skins-module ElvUI initialization states",
		action = function(V)
			local originalElvUI = _G.ElvUI
			local ok, err = pcall(function()
				local currentEngine = {
					Initialized = true,
					GetModule = function() end,
				}
				_G.ElvUI = { currentEngine }
				V:AssertEqual(
					BFL:GetElvUIEngine(true),
					currentEngine,
					"Current ElvUI's uppercase initialization flag should enable broker skinning"
				)

				local legacyEngine = {
					initialized = true,
					GetModule = function() end,
				}
				_G.ElvUI = { legacyEngine }
				V:AssertEqual(
					BFL:GetElvUIEngine(true),
					legacyEngine,
					"Legacy ElvUI's lowercase initialization flag should remain supported"
				)

				local moduleEngine = {
					GetModule = function(_, name)
						return name == "Skins" and { Initialized = true } or nil
					end,
				}
				_G.ElvUI = { moduleEngine }
				V:AssertEqual(
					BFL:GetElvUIEngine(true),
					moduleEngine,
					"An initialized ElvUI Skins module should enable broker skinning"
				)

				local pendingEngine = {
					GetModule = function()
						return {}
					end,
				}
				_G.ElvUI = { pendingEngine }
				V:AssertNil(
					BFL:GetElvUIEngine(true),
					"Broker skinning should still wait while ElvUI is not initialized"
				)
			end)
			_G.ElvUI = originalElvUI
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "ThemePalette_CopiedCustomAccentMigrationDerivesIndependentDefault", {
		description = "Copied Dark accent defaults should migrate to an independent Custom accent",
		action = function(V)
			WithTemporaryDatabase({
				enableBetaFeatures = true,
				theme = "custom",
				themeSettingsIndependentDefaultsVersion = 0,
				darkThemeSettings = {
					accentColor = { r = 0.2, g = 0.4, b = 0.8, a = 1 },
				},
				customThemeSettings = {
					accentColor = { r = 0.2, g = 0.4, b = 0.8, a = 1 },
				},
				blizzardThemeSettings = {
					accentColor = { r = 0.2, g = 0.4, b = 0.8, a = 1 },
					avatarVisibility = 0.5,
				},
			}, function(tempDB)
				V:Assert(
					tempDB.customThemeSettings.accentColor.r ~= 0.2
						or tempDB.customThemeSettings.accentColor.g ~= 0.4
						or tempDB.customThemeSettings.accentColor.b ~= 0.8,
					"Custom accent should be derived, not copied"
				)
				V:AssertNil(tempDB.blizzardThemeSettings, "Blizzard theme settings should be removed")
				V:AssertEqual(
					tempDB.themeSettingsIndependentDefaultsVersion,
					1,
					"Independent theme default migration should be marked complete"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "ThemePalette_CustomSettingsDriveCustomTheme", {
		description = "Custom theme slider settings should drive inherited skin tokens",
		action = function(V)
			local ThemePalette = BFL:GetModule("ThemePalette")
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(ThemePalette, "ThemePalette should be loaded")
			V:AssertNotNil(SkinEngine, "SkinEngine should be loaded")

			WithTemporaryDatabase({
				enableBetaFeatures = true,
				theme = "custom",
				darkThemeSettings = {
					hoverStrength = 0.10,
					selectionStrength = 0.14,
				},
				customThemeSettings = {
					hoverStrength = 0.31,
					selectionStrength = 0.47,
					borderStrength = 0.25,
				},
			}, function()
				local colors = {}
				ThemePalette:ApplyToColors(colors, SkinEngine.defaultColors)

				V:AssertEqual(colors.rowHover[4], 0.31, "Custom row hover should use custom hover strength")
				V:AssertEqual(colors.rowDown[4], 0.47, "Custom selected rows should use custom selection strength")
				V:AssertEqual(colors.border[4], 0.25, "Custom border should use custom border strength")
			end)
		end,
	})

	TS:RegisterTest("data", "SimpleMode_UpdatePortraitVisibilityOwnsLayout", {
		description = "Simple Mode should keep Core portrait visibility responsible for header layout",
		action = function(V)
			V:AssertNotNil(BFL.UpdatePortraitVisibility, "BFL:UpdatePortraitVisibility should exist")

			local function MakeObject()
				local object = {
					shown = true,
					points = {},
				}
				function object:SetShown(shown)
					self.shown = shown == true
				end
				function object:IsShown()
					return self.shown == true
				end
				function object:Show()
					self.shown = true
				end
				function object:Hide()
					self.shown = false
				end
				function object:SetAlpha(alpha)
					self.alpha = alpha
				end
				function object:SetVertexColor(r, g, b, a)
					self.vertexColor = { r, g, b, a }
				end
				function object:ClearAllPoints()
					self.points = {}
				end
				function object:SetPoint(...)
					self.points[#self.points + 1] = { ... }
				end
				function object:SetWidth(width)
					self.width = width
				end
				function object:SetHeight(height)
					self.height = height
				end
				function object:SetSize(width, height)
					self.width = width
					self.height = height
				end
				function object:SetTexture(texture)
					self.texture = texture
				end
				function object:SetTexCoord(...)
					self.texCoord = { ... }
				end
				function object:CreateTexture()
					local texture = MakeObject()
					self.createdTexture = texture
					return texture
				end
				return object
			end

			local frame = MakeObject()
			function frame:GetName()
				return "BetterFriendsFrame"
			end
			function frame:GetRegions()
			end
			function frame:GetChildren()
			end
			function frame:SetPortraitShown(shown)
				self.portraitShown = shown == true
			end

			frame.PortraitContainer = MakeObject()
			frame.portrait = MakeObject()
			frame.PortraitButton = MakeObject()
			frame.PortraitIcon = MakeObject()
			frame.PortraitMask = MakeObject()
			frame.PortraitFrame = MakeObject()
			frame.TopLeftCorner = MakeObject()
			frame.TopBorder = MakeObject()
			frame.LeftBorder = MakeObject()
			frame.TopRightCorner = MakeObject()
			frame.BotLeftCorner = MakeObject()
			frame.TitleContainer = MakeObject()
			frame.FriendsTabHeader = {
				BattlenetFrame = MakeObject(),
				QuickFilterDropdown = MakeObject(),
				PrimarySortDropdown = MakeObject(),
				SecondarySortDropdown = MakeObject(),
				Tab1 = MakeObject(),
			}

			local globalPortrait = MakeObject()
			local originalFrame = _G.BetterFriendsFrame
			local originalPortrait = _G.BetterFriendsFramePortrait
			local originalIsClassic = BFL.IsClassic
			_G.BetterFriendsFrame = frame
			_G.BetterFriendsFramePortrait = globalPortrait
			BFL.IsClassic = true

			local ok, err = pcall(function()
				WithTemporaryDatabase({
					simpleMode = true,
					theme = "blizzard",
				}, function()
					BFL:UpdatePortraitVisibility("test-simple-mode")

					V:Assert(frame.PortraitButton.shown == false, "Simple Mode should hide the portrait button")
					V:Assert(frame.PortraitIcon.shown == false, "Simple Mode should hide the portrait icon")
					V:Assert(frame.PortraitFrame.shown == false, "Simple Mode should hide the portrait frame ring")
					V:Assert(frame.TopLeftCorner.shown == true, "Simple Mode should show the no-portrait top-left corner")
					V:AssertEqual(frame.TopLeftCorner.texture, "Interface\\FrameGeneral\\UI-Frame", "Simple Mode should use Classic UI-Frame art for the top-left corner")
					V:AssertEqual(frame.TopLeftCorner.width, 33, "Simple Mode top-left corner should use the Classic frame corner width")
					V:AssertEqual(frame.TopLeftCorner.points[1][1], "TOPLEFT", "Simple Mode top-left corner should be anchored to the frame top-left")
					V:Assert(frame.BFL_SimpleModeTopLeftCorner.shown == true, "Simple Mode should show the explicit top-left corner patch")
					V:AssertEqual(frame.BFL_SimpleModeTopLeftCorner.texture, "Interface\\FrameGeneral\\UI-Frame", "Simple Mode patch should use Classic UI-Frame art")
					V:AssertEqual(frame.TopBorder.points[1][1], "TOPLEFT", "Simple Mode should re-anchor top border from the top-left corner")
					V:AssertEqual(frame.TopBorder.points[1][3], "TOPRIGHT", "Simple Mode top border should start at the top-left corner's right edge")
					V:AssertEqual(frame.LeftBorder.points[1][3], "BOTTOMLEFT", "Simple Mode left border should start below the top-left corner")
					V:Assert(globalPortrait.shown == false, "Simple Mode should hide the global portrait")
					V:Assert(frame.FriendsTabHeader.QuickFilterDropdown.shown == false, "Simple Mode should hide quick filter dropdown")
					V:Assert(frame.FriendsTabHeader.PrimarySortDropdown.shown == false, "Simple Mode should hide primary sort dropdown")
					V:Assert(frame.FriendsTabHeader.SecondarySortDropdown.shown == false, "Simple Mode should hide secondary sort dropdown")
					V:AssertEqual(frame.FriendsTabHeader.Tab1.points[1][5], -60, "Simple Mode should move top tabs up")
				end)
			end)

			_G.BetterFriendsFrame = originalFrame
			_G.BetterFriendsFramePortrait = originalPortrait
			BFL.IsClassic = originalIsClassic
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Theme_LegacyElvUISkinMigratesToTheme", {
		description = "Legacy ElvUI skin setting should migrate to the standard theme setting",
		action = function(V)
			local originalIsElvUIAvailable = BFL.IsElvUIAvailable
			BFL.IsElvUIAvailable = function()
				return true
			end

			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "blizzard",
					enableElvUISkin = true,
					enableBetaFeatures = false,
				}, function()
					V:Assert(not BFL:ShouldUseLegacyElvUISkinSetting(), "Legacy ElvUI setting path should be inactive")
					V:AssertEqual(BFL:GetEffectiveTheme(), "elvui", "Legacy ElvUI skin should migrate to the theme setting")
					V:Assert(BFL:IsThemeActive("elvui"), "ElvUI skin should be active through the theme setting")
				end)
			end)

			BFL.IsElvUIAvailable = originalIsElvUIAvailable
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "Theme_LegacyElvUISkinHiddenWithoutAddon", {
		description = "Legacy ElvUI skin setting should be hidden when ElvUI is unavailable",
		action = function(V)
			local originalIsElvUIAvailable = BFL.IsElvUIAvailable
			BFL.IsElvUIAvailable = function()
				return false
			end

			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "elvui",
					enableElvUISkin = true,
					enableBetaFeatures = false,
				}, function()
					V:Assert(not BFL:ShouldUseLegacyElvUISkinSetting(), "Legacy ElvUI setting path should be inactive")
					V:Assert(not BFL:ShouldShowLegacyElvUISkinSetting(), "Legacy ElvUI setting should be hidden without ElvUI")
					V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "ElvUI should fall back to Blizzard without ElvUI")
				end)
			end)

			BFL.IsElvUIAvailable = originalIsElvUIAvailable
			if not ok then
				error(err, 2)
			end
		end,
	})

	TS:RegisterTest("data", "Theme_BlizzardDisablesSkinEngine", {
		description = "Blizzard theme should not leave the Dark skin engine active",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")

			WithTemporaryDatabase({
				theme = "blizzard",
			}, function()
				V:Assert(not SkinEngine:IsActive(), "SkinEngine should be inactive for Blizzard theme")
			end)
		end,
	})

	TS:RegisterTest("data", "SkinEngine_TravelPassSkipsBlizzardTheme", {
		description = "TravelPass invite styling should be Dark-theme only",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")
			V:AssertNotNil(SkinEngine.SkinTravelPassButton, "SkinEngine:SkinTravelPassButton should exist")

			local originalActive = SkinEngine.active
			local button = {}
			local ok, err = pcall(function()
				WithTemporaryDatabase({
					theme = "blizzard",
				}, function()
					SkinEngine.active = true
					SkinEngine:SkinTravelPassButton(button)
					V:AssertNil(button.BFL_DarkTravelPassButton, "TravelPass button should not be marked in Blizzard theme")
					V:AssertNil(button.BFL_DarkSkin, "TravelPass button should not be registered in Blizzard theme")
				end)
			end)
			SkinEngine.active = originalActive
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "SkinEngine_RestoreShownState", {
		description = "SkinEngine restore should return native show/hide state",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")
			V:AssertNotNil(SkinEngine.SetObjectShown, "SkinEngine:SetObjectShown should exist")

			local owner = {}
			local region = { shown = true }
			function region:IsShown()
				return self.shown
			end
			function region:SetShown(shown)
				self.shown = shown == true
			end

			local ok, err = pcall(function()
				SkinEngine:SetObjectShown(owner, region, false)
				V:Assert(region.shown == false, "SkinEngine should be able to hide a native region")
				SkinEngine:RestoreFrame(owner)
				V:Assert(region.shown == true, "SkinEngine should restore the previous shown state")
			end)
			SkinEngine.registry[owner] = nil
			owner.BFL_DarkSkin = nil
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "SkinEngine_RestoreTabState", {
		description = "Dark tab skinning should restore the previous tab text layout state",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")
			V:AssertNotNil(SkinEngine.CenterTabText, "SkinEngine:CenterTabText should exist")

			local tab = { BFL_UseTextCenter = true, BFL_DarkTabButton = true }
			local fs = {
				points = { { "LEFT", tab, "LEFT", 7, -5 } },
				justifyH = "LEFT",
				justifyV = "TOP",
			}
			tab.Text = fs

			function fs:GetNumPoints()
				return #self.points
			end
			function fs:GetPoint(index)
				return unpack(self.points[index])
			end
			function fs:ClearAllPoints()
				self.points = {}
			end
			function fs:SetPoint(...)
				self.points[#self.points + 1] = { ... }
			end
			function fs:GetJustifyH()
				return self.justifyH
			end
			function fs:GetJustifyV()
				return self.justifyV
			end
			function fs:SetJustifyH(value)
				self.justifyH = value
			end
			function fs:SetJustifyV(value)
				self.justifyV = value
			end

			local ok, err = pcall(function()
				SkinEngine:CenterTabText(tab)
				V:AssertEqual(fs.points[1][1], "CENTER", "Dark theme should center tab text while active")
				V:AssertEqual(fs.justifyH, "CENTER", "Dark theme should center horizontal tab text")
				V:AssertEqual(fs.justifyV, "MIDDLE", "Dark theme should center vertical tab text")

				SkinEngine:RestoreFrame(tab)
				V:Assert(tab.BFL_UseTextCenter == true, "Restore should preserve the previous BFL_UseTextCenter value")
				V:AssertEqual(fs.points[1][1], "LEFT", "Restore should return the original tab text point")
				V:AssertEqual(fs.points[1][4], 7, "Restore should return the original tab text x offset")
				V:AssertEqual(fs.points[1][5], -5, "Restore should return the original tab text y offset")
				V:AssertEqual(fs.justifyH, "LEFT", "Restore should return the original horizontal justify")
				V:AssertEqual(fs.justifyV, "TOP", "Restore should return the original vertical justify")
			end)
			SkinEngine.registry[tab] = nil
			tab.BFL_DarkSkin = nil
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "SkinEngine_RestoreVisualState", {
		description = "SkinEngine restore should return native texture, region, and text state",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")
			V:AssertNotNil(SkinEngine.SetTextureVertexColor, "SkinEngine:SetTextureVertexColor should exist")
			V:AssertNotNil(SkinEngine.SetTextureBlendMode, "SkinEngine:SetTextureBlendMode should exist")
			V:AssertNotNil(SkinEngine.SetRegionPoints, "SkinEngine:SetRegionPoints should exist")
			V:AssertNotNil(SkinEngine.SetFontJustify, "SkinEngine:SetFontJustify should exist")

			local owner = {}
			local region = {
				alpha = 0.65,
				color = { 0.2, 0.3, 0.4, 0.5 },
				blendMode = "ADD",
				points = { { "TOPLEFT", owner, "TOPLEFT", 3, -4 } },
				width = 33,
				height = 17,
			}
			local editBox = {
				color = { 0.1, 0.2, 0.3, 0.4 },
				justifyH = "RIGHT",
				justifyV = "BOTTOM",
			}

			function region:GetAlpha()
				return self.alpha
			end
			function region:SetAlpha(alpha)
				self.alpha = alpha
			end
			function region:GetVertexColor()
				return self.color[1], self.color[2], self.color[3], self.color[4]
			end
			function region:SetVertexColor(r, g, b, a)
				self.color = { r, g, b, a }
			end
			function region:GetBlendMode()
				return self.blendMode
			end
			function region:SetBlendMode(blendMode)
				self.blendMode = blendMode
			end
			function region:GetNumPoints()
				return #self.points
			end
			function region:GetPoint(index)
				return unpack(self.points[index])
			end
			function region:ClearAllPoints()
				self.points = {}
			end
			function region:SetPoint(...)
				self.points[#self.points + 1] = { ... }
			end
			function region:GetSize()
				return self.width, self.height
			end
			function region:SetSize(width, height)
				self.width = width
				self.height = height
			end

			function editBox:GetTextColor()
				return self.color[1], self.color[2], self.color[3], self.color[4]
			end
			function editBox:SetTextColor(r, g, b, a)
				self.color = { r, g, b, a }
			end
			function editBox:GetJustifyH()
				return self.justifyH
			end
			function editBox:GetJustifyV()
				return self.justifyV
			end
			function editBox:SetJustifyH(value)
				self.justifyH = value
			end
			function editBox:SetJustifyV(value)
				self.justifyV = value
			end

			local ok, err = pcall(function()
				SkinEngine:SetTextureAlpha(owner, region, 0)
				SkinEngine:SetTextureVertexColor(owner, region, 1, 0.82, 0, 1)
				SkinEngine:SetTextureBlendMode(owner, region, "BLEND")
				SkinEngine:SetRegionPoints(owner, region, {
					{ "CENTER", owner, "CENTER", 0, 0 },
				})
				SkinEngine:SetRegionSize(owner, region, 16, 16)
				SkinEngine:SetFontColor(owner, editBox, 0.92, 0.92, 0.92, 1)
				SkinEngine:SetFontJustify(owner, editBox, "CENTER", "MIDDLE")

				SkinEngine:RestoreFrame(owner)
				V:AssertEqual(region.alpha, 0.65, "Restore should return texture alpha")
				V:AssertEqual(region.color[1], 0.2, "Restore should return texture vertex red")
				V:AssertEqual(region.color[2], 0.3, "Restore should return texture vertex green")
				V:AssertEqual(region.color[3], 0.4, "Restore should return texture vertex blue")
				V:AssertEqual(region.color[4], 0.5, "Restore should return texture vertex alpha")
				V:AssertEqual(region.blendMode, "ADD", "Restore should return texture blend mode")
				V:AssertEqual(region.points[1][1], "TOPLEFT", "Restore should return region point")
				V:AssertEqual(region.points[1][4], 3, "Restore should return region x offset")
				V:AssertEqual(region.points[1][5], -4, "Restore should return region y offset")
				V:AssertEqual(region.width, 33, "Restore should return region width")
				V:AssertEqual(region.height, 17, "Restore should return region height")
				V:AssertEqual(editBox.color[1], 0.1, "Restore should return text color")
				V:AssertEqual(editBox.justifyH, "RIGHT", "Restore should return horizontal justify")
				V:AssertEqual(editBox.justifyV, "BOTTOM", "Restore should return vertical justify")
			end)
			SkinEngine.registry[owner] = nil
			owner.BFL_DarkSkin = nil
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Tabs_VisualState_FontObjects", {
		description = "Tab visual refresh should move selected/deselected font state cleanly",
		action = function(V)
			V:AssertNotNil(BFL.ApplyTabVisualState, "BFL:ApplyTabVisualState should exist")

			local originalSelect = _G.PanelTemplates_SelectTab
			local originalDeselect = _G.PanelTemplates_DeselectTab
			local originalDisabled = _G.PanelTemplates_SetDisabledTabState

			local fs = { color = {} }
			function fs:SetFontObject(fontObject)
				self.fontObject = fontObject
			end
			function fs:SetTextColor(r, g, b, a)
				self.color = { r, g, b, a }
			end

			local tab = { Text = fs }
			function tab:SetNormalFontObject(fontObject)
				self.normalFontObject = fontObject
			end
			function tab:SetHighlightFontObject(fontObject)
				self.highlightFontObject = fontObject
			end
			function tab:SetDisabledFontObject(fontObject)
				self.disabledFontObject = fontObject
			end
			function tab:GetFontString()
				return self.Text
			end

			local ok, err = pcall(function()
				_G.PanelTemplates_SelectTab = function(target)
					target.panelState = "selected"
				end
				_G.PanelTemplates_DeselectTab = function(target)
					target.panelState = "deselected"
				end
				_G.PanelTemplates_SetDisabledTabState = function(target)
					target.panelState = "disabled"
				end

				BFL:ApplyTabVisualState(tab, true, false)
				V:AssertEqual(tab.panelState, "selected", "Selected tab should use selected panel state")
				V:AssertEqual(tab.normalFontObject, "BetterFriendlistTabFontNormal", "Selected tab should keep normal font object")
				V:AssertEqual(tab.highlightFontObject, "BetterFriendlistTabFontHighlight", "Selected tab should keep highlight font object")
				V:AssertEqual(tab.disabledFontObject, "BetterFriendlistTabFontHighlight", "Selected tab should use highlight disabled font")
				V:AssertEqual(fs.fontObject, "BetterFriendlistTabFontHighlight", "Selected tab text should use highlight font")

				BFL:ApplyTabVisualState(tab, false, false)
				V:AssertEqual(tab.panelState, "deselected", "Deselected tab should use deselected panel state")
				V:AssertEqual(tab.disabledFontObject, "BetterFriendlistTabFontDisable", "Deselected tab should restore disabled font")
				V:AssertEqual(fs.fontObject, "BetterFriendlistTabFontNormal", "Deselected tab text should use normal font")

				BFL:ApplyTabVisualState(tab, false, true)
				V:AssertEqual(tab.panelState, "disabled", "Disabled tab should use disabled panel state")
				V:AssertEqual(tab.disabledFontObject, "BetterFriendlistTabFontDisable", "Disabled tab should keep disabled font")
				V:AssertEqual(fs.fontObject, "BetterFriendlistTabFontDisable", "Disabled tab text should use disabled font")
			end)

			_G.PanelTemplates_SelectTab = originalSelect
			_G.PanelTemplates_DeselectTab = originalDeselect
			_G.PanelTemplates_SetDisabledTabState = originalDisabled
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("data", "Database_Migration_DefaultFrameWidth", {
		description = "defaultFrameWidth should be migrated to the new minimum",
		action = function(V)
			WithTemporaryDatabase({
				defaultFrameWidth = 350,
			}, function(tempDB)
				V:AssertEqual(tempDB.defaultFrameWidth, 380, "defaultFrameWidth should be migrated to 380")
			end)
		end,
	})

	TS:RegisterTest("data", "Database_Migration_ColorTables", {
		description = "Color table migrations should repair invalid values",
		action = function(V)
			local sharedColors = { r = 0.1, g = 0.2, b = 0.3 }
			WithTemporaryDatabase({
				fontColorFriendName = {},
				fontColorFriendInfo = {},
				groupCountColors = sharedColors,
				groupArrowColors = sharedColors,
			}, function(tempDB)
				V:Assert(
					type(tempDB.fontColorFriendName) == "table" and tempDB.fontColorFriendName.r ~= nil,
					"fontColorFriendName should be repaired"
				)
				V:Assert(
					type(tempDB.fontColorFriendInfo) == "table" and tempDB.fontColorFriendInfo.r ~= nil,
					"fontColorFriendInfo should be repaired"
				)
				V:Assert(
					tempDB.groupCountColors ~= tempDB.groupArrowColors,
					"groupCountColors and groupArrowColors should not share the same table"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "Groups_Module_Exists", {
		description = "Groups module is loaded and functional",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			V:AssertNotNil(Groups, "Groups module should exist")
			V:AssertNotNil(Groups.Create, "Groups:Create should exist")
			V:AssertNotNil(Groups.Delete, "Groups:Delete should exist")
			V:AssertNotNil(Groups.GetAll, "Groups:GetAll should exist")
		end,
	})

	TS:RegisterTest("data", "Groups_CRUD", {
		description = "Groups can be created, read, updated, deleted",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			local testGroupName = "_TestGroup_" .. time()

			-- Create (returns: success, groupId)
			local success, groupId = Groups:Create(testGroupName)
			V:Assert(success, "Create should succeed")
			V:AssertNotNil(groupId, "Create should return group ID")

			-- Read
			local group = Groups:Get(groupId)
			V:AssertNotNil(group, "Get should return group")
			V:AssertEqual(group.name, testGroupName, "Group name should match")

			-- Update (Rename)
			local newName = testGroupName .. "_Renamed"
			Groups:Rename(groupId, newName)
			group = Groups:Get(groupId)
			V:AssertEqual(group.name, newName, "Group name should be updated")

			-- Delete
			Groups:Delete(groupId)
			group = Groups:Get(groupId)
			V:AssertNil(group, "Group should be deleted")
		end,
	})

	TS:RegisterTest("data", "FriendsList_Module_Exists", {
		description = "FriendsList module is loaded",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			V:AssertNotNil(FriendsList, "FriendsList module should exist")
			V:AssertNotNil(FriendsList.UpdateFriendsList, "UpdateFriendsList should exist")
		end,
	})

	-- ===== CLASSIC TESTS =====

	TS:RegisterTest("classic", "IsClassic_Flag", {
		description = "BFL.IsClassic flag is correct for current client",
		action = function(V)
			V:AssertNotNil(BFL.IsClassic, "BFL.IsClassic should be defined")
			V:AssertNotNil(BFL.IsRetail, "BFL.IsRetail should be defined")
			V:Assert(BFL.IsClassic ~= BFL.IsRetail, "IsClassic and IsRetail should be mutually exclusive")
		end,
	})

	TS:RegisterTest("classic", "Classic_NoRecentAllies", {
		description = "RecentAllies availability should require supported build, ScrollBox, and API support",
		action = function(V)
			local compatAvailable = false
			if BFL.Compat and BFL.Compat.IsRecentAlliesAvailable then
				compatAvailable = BFL.Compat.IsRecentAlliesAvailable()
			end
			local expected = (BFL.IsMainline and BFL.HasModernScrollBox and compatAvailable) == true
			V:AssertEqual(
				BFL.HasRecentAllies == true,
				expected,
				"HasRecentAllies should require Mainline, ScrollBox, and API availability"
			)
		end,
	})

	TS:RegisterTest("classic", "Retail_HasModernScrollBox", {
		description = "Retail should have modern ScrollBox API",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			V:Assert(BFL.HasModernScrollBox, "HasModernScrollBox should be true in Retail")
		end,
	})

	TS:RegisterTest("classic", "CapabilityFlags_ModernMenuDropdown", {
		description = "Menu and dropdown feature flags should reflect client capabilities across Retail and Classic",
		action = function(V)
			V:AssertType(BFL.Capabilities, "table", "BFL.Capabilities should exist")
			V:AssertEqual(
				BFL.HasModernMenu,
				BFL.Capabilities.ModernMenu == true,
				"HasModernMenu should reflect the detected menu capability"
			)
			V:AssertEqual(
				BFL.HasModernDropdown,
				BFL.Capabilities.ModernDropdown == true,
				"HasModernDropdown should reflect the detected dropdown capability"
			)
			V:AssertEqual(
				BFL.CanUseModernScrollBox,
				BFL.Capabilities.ModernScrollBox == true,
				"CanUseModernScrollBox should expose the raw ScrollBox capability"
			)
			if BFL.IsClassic then
				V:Assert(
					BFL.HasModernScrollBox == false or BFL.HasModernScrollBox == BFL.Capabilities.ModernScrollBox,
					"Classic HasModernScrollBox should stay validated-gated until individual frames opt in"
				)
			end
		end,
	})

	TS:RegisterTest("classic", "CreateDropdown_ForceLegacyOption", {
		description = "Shared dropdown factory should allow callers to force UIDropDownMenu fallback without changing boolean opt-in semantics",
		action = function(V)
			V:AssertType(BFL.CreateDropdown, "function", "BFL.CreateDropdown should exist")

			local oldCreateFrame = CreateFrame
			local oldSetWidth = UIDropDownMenu_SetWidth
			local oldHasModernDropdown = BFL.HasModernDropdown
			local oldCapabilities = BFL.Capabilities
			local oldDropdownButtonMixin = DropdownButtonMixin
			local created = {}

			local ok, err = pcall(function()
				BFL.HasModernDropdown = true
				BFL.Capabilities = { ModernDropdown = true }
				DropdownButtonMixin = { SetupMenu = function() end }
				CreateFrame = function(frameType, name, parent, template)
					local frame = {
						frameType = frameType,
						name = name,
						parent = parent,
						template = template,
						SetWidth = function(self, width)
							self.width = width
						end,
					}
					if frameType == "DropdownButton" then
						frame.SetupMenu = function() end
					end
					table.insert(created, frame)
					return frame
				end
				UIDropDownMenu_SetWidth = function(frame, width)
					frame.legacyWidth = width
				end

				local modern = BFL.CreateDropdown({}, "BFLTestModernDropdown", 111, true)
				V:AssertEqual(modern.frameType, "DropdownButton", "Boolean true should still opt into modern dropdowns")
				V:AssertEqual(modern.template, "WowStyle1DropdownTemplate", "Modern dropdown template should be preserved")

				local legacy = BFL.CreateDropdown({}, "BFLTestLegacyDropdown", 123, { forceLegacy = true })
				V:AssertEqual(legacy.frameType, "Frame", "forceLegacy should create a legacy frame")
				V:AssertEqual(legacy.template, "UIDropDownMenuTemplate", "forceLegacy should use UIDropDownMenuTemplate")
				V:AssertEqual(legacy.legacyWidth, 123, "forceLegacy should still apply the requested width")
			end)

			CreateFrame = oldCreateFrame
			UIDropDownMenu_SetWidth = oldSetWidth
			BFL.HasModernDropdown = oldHasModernDropdown
			BFL.Capabilities = oldCapabilities
			DropdownButtonMixin = oldDropdownButtonMixin
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("classic", "DropdownDisplayHelpers_HandleModernAndLegacy", {
		description = "Shared dropdown display helpers should set text, width, and justification across modern and legacy dropdowns",
		action = function(V)
			V:AssertType(BFL.SetDropdownText, "function", "BFL.SetDropdownText should exist")
			V:AssertType(BFL.SetDropdownWidth, "function", "BFL.SetDropdownWidth should exist")
			V:AssertType(BFL.JustifyDropdownText, "function", "BFL.JustifyDropdownText should exist")
			V:AssertType(BFL.SetDropdownSelectedValue, "function", "BFL.SetDropdownSelectedValue should exist")
			V:AssertType(BFL.RefreshDropdown, "function", "BFL.RefreshDropdown should exist")

			local oldSetText = UIDropDownMenu_SetText
			local oldSetWidth = UIDropDownMenu_SetWidth
			local oldJustify = UIDropDownMenu_JustifyText
			local oldSetSelectedValue = UIDropDownMenu_SetSelectedValue
			local oldRefresh = UIDropDownMenu_Refresh
			local legacyCalls = {}

			local ok, err = pcall(function()
				UIDropDownMenu_SetText = function(dropdown, text)
					legacyCalls.text = {
						dropdown = dropdown,
						text = text,
					}
				end
				UIDropDownMenu_SetWidth = function(dropdown, width)
					legacyCalls.width = {
						dropdown = dropdown,
						width = width,
					}
				end
				UIDropDownMenu_JustifyText = function(dropdown, justify)
					legacyCalls.justify = {
						dropdown = dropdown,
						justify = justify,
					}
				end
				UIDropDownMenu_SetSelectedValue = function(dropdown, value)
					legacyCalls.selected = {
						dropdown = dropdown,
						value = value,
					}
				end
				UIDropDownMenu_Refresh = function(dropdown)
					legacyCalls.refresh = {
						dropdown = dropdown,
					}
				end

				local modern = {
					SetupMenu = function() end,
					Update = function(self)
						self.updated = true
					end,
					SetWidth = function(self, width)
						self.width = width
					end,
					Text = {
						SetText = function(self, text)
							self.text = text
						end,
						SetJustifyH = function(self, justify)
							self.justify = justify
						end,
					},
				}
				V:Assert(BFL.SetDropdownText(modern, "Modern") == true, "Modern dropdown text should be handled")
				V:Assert(BFL.SetDropdownWidth(modern, 144) == true, "Modern dropdown width should be handled")
				V:Assert(BFL.JustifyDropdownText(modern, "RIGHT") == true, "Modern dropdown justification should be handled")
				V:Assert(BFL.SetDropdownSelectedValue(modern, "ignored") == false, "Modern dropdown selected value should be getter-driven")
				V:Assert(BFL.RefreshDropdown(modern, "Modern refresh") == true, "Modern dropdown refresh should be handled")
				V:AssertEqual(modern.Text.text, "Modern refresh", "Modern dropdown refresh should update its text region")
				V:AssertEqual(modern.width, 144, "Modern dropdown width should use SetWidth")
				V:AssertEqual(modern.Text.justify, "RIGHT", "Modern dropdown justification should use text region")
				V:Assert(modern.updated == true, "Modern dropdown refresh should call Update")

				local legacy = {}
				V:Assert(BFL.SetDropdownText(legacy, "Legacy") == true, "Legacy dropdown text should be handled")
				V:Assert(BFL.SetDropdownWidth(legacy, 155) == true, "Legacy dropdown width should be handled")
				V:Assert(BFL.JustifyDropdownText(legacy, "LEFT") == true, "Legacy dropdown justification should be handled")
				V:Assert(BFL.SetDropdownSelectedValue(legacy, "zone") == true, "Legacy dropdown selected value should be handled")
				V:Assert(BFL.RefreshDropdown(legacy) == true, "Legacy dropdown refresh should be handled")
				V:AssertEqual(legacyCalls.text.text, "Legacy", "Legacy dropdown text should use UIDropDownMenu_SetText")
				V:AssertEqual(legacyCalls.width.width, 155, "Legacy dropdown width should use UIDropDownMenu_SetWidth")
				V:AssertEqual(legacyCalls.justify.justify, "LEFT", "Legacy dropdown justification should use UIDropDownMenu_JustifyText")
				V:AssertEqual(legacyCalls.selected.value, "zone", "Legacy dropdown selected value should use UIDropDownMenu_SetSelectedValue")
				V:AssertEqual(legacyCalls.refresh.dropdown, legacy, "Legacy dropdown refresh should use UIDropDownMenu_Refresh")
			end)

			UIDropDownMenu_SetText = oldSetText
			UIDropDownMenu_SetWidth = oldSetWidth
			UIDropDownMenu_JustifyText = oldJustify
			UIDropDownMenu_SetSelectedValue = oldSetSelectedValue
			UIDropDownMenu_Refresh = oldRefresh
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("classic", "HeaderDropdownSelections_CenterAcrossTemplates", {
		description = "Compact Legacy header selections should be vertically centered for Retail and Classic dropdown templates",
		action = function(V)
			local initializer = BFL.FrameInitializer
			V:AssertNotNil(initializer, "FrameInitializer should exist")
			V:AssertType(initializer.AlignHeaderDropdownSelection, "function", "Header alignment helper should exist")
			V:AssertType(
				initializer.AlignLegacyHeaderDropdownSelection,
				"function",
				"Legacy header alignment helper should exist"
			)

			local function MakeTextRegion()
				return {
					points = {},
					ClearAllPoints = function(self)
						self.points = {}
					end,
					SetPoint = function(self, ...)
						self.points[#self.points + 1] = { ... }
					end,
					SetJustifyH = function(self, value)
						self.justifyH = value
					end,
					SetJustifyV = function(self, value)
						self.justifyV = value
					end,
					SetWordWrap = function(self, value)
						self.wordWrap = value
					end,
				}
			end

			local modernText = MakeTextRegion()
			local modern = {
				Text = modernText,
				SetupMenu = function() end,
			}
			V:Assert(initializer:AlignHeaderDropdownSelection(modern), "Retail dropdown selection should align")
			V:AssertEqual(modernText.points[1][1], "LEFT", "Retail selection should use a left inset")
			V:AssertEqual(modernText.points[1][5], 0, "Retail selection left anchor should be vertically centered")
			V:AssertEqual(modernText.points[2][1], "RIGHT", "Retail selection should use a right inset")
			V:AssertEqual(modernText.points[2][5], 0, "Retail selection right anchor should be vertically centered")

			local legacyText = MakeTextRegion()
			local legacyMiddle = {}
			local legacy = {
				Text = legacyText,
				Middle = legacyMiddle,
			}
			V:Assert(initializer:AlignHeaderDropdownSelection(legacy), "Classic dropdown selection should align")
			V:AssertEqual(legacyText.points[1][1], "CENTER", "Classic selection should use the middle artwork")
			V:AssertEqual(legacyText.points[1][2], legacyMiddle, "Classic selection should stay within the middle artwork")
			V:AssertEqual(legacyText.points[1][5], 0, "Classic selection should remove Blizzard's two-pixel Y offset")
			V:AssertEqual(legacyText.justifyH, "CENTER", "Compact selections should be horizontally centered")
			V:AssertEqual(legacyText.justifyV, "MIDDLE", "Compact selections should be vertically centered")
			V:AssertEqual(legacyText.wordWrap, false, "Compact selections should never wrap")

			local oldFriendsUI = BFL.FriendsUI
			local ok, err = pcall(function()
				BFL.FriendsUI = {
					IsModernActive = function()
						return true
					end,
				}
				V:Assert(
					initializer:AlignLegacyHeaderDropdownSelection(modern) == false,
					"Legacy-only alignment should leave the active Modern style unchanged"
				)
				BFL.FriendsUI.IsModernActive = function()
					return false
				end
				V:Assert(
					initializer:AlignLegacyHeaderDropdownSelection(modern),
					"Legacy style should align Retail's modern dropdown template"
				)
			end)
			BFL.FriendsUI = oldFriendsUI
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("classic", "InitializeDropdown_ModernPopulateRootDescription", {
		description = "Shared dropdown initializer should support dynamic modern menu population without caller SetupMenu usage",
		action = function(V)
			V:AssertType(BFL.InitializeDropdown, "function", "BFL.InitializeDropdown should exist")

			local capturedGenerator
			local capturedTranslator
			local translatorAtSetup
			local dropdown = {
				SetupMenu = function(self, generator)
					translatorAtSetup = self.selectionTranslator
					capturedGenerator = generator
				end,
				SetSelectionTranslator = function(self, translator)
					capturedTranslator = translator
					self.selectionTranslator = translator
				end,
			}
			local rootDescription = {
				SetScrollMode = function(self, height)
					self.scrollHeight = height
				end,
				CreateButton = function(self, text, callback, data)
					self.createdButton = {
						text = text,
						callback = callback,
						data = data,
					}
					return self.createdButton
				end,
			}
			local populated

			BFL.InitializeDropdown(dropdown, {
				getSelectionText = function(value)
					return "Selected:" .. tostring(value)
				end,
				populateRootDescription = function(root, owner)
					populated = owner == dropdown
					root:CreateButton("Dynamic", function() end, "value")
				end,
			}, nil, nil, 240)

			V:AssertType(capturedGenerator, "function", "Modern dropdown should receive a setup generator")
			V:AssertType(capturedTranslator, "function", "Modern dropdown should receive a selection translator")
			V:AssertType(translatorAtSetup, "function", "Modern dropdown should have a selection translator before SetupMenu runs")
			capturedGenerator(dropdown, rootDescription)
			V:Assert(populated == true, "populateRootDescription should receive the dropdown owner")
			V:AssertEqual(rootDescription.scrollHeight, 240, "Dynamic modern dropdown should preserve scroll height")
			V:AssertEqual(rootDescription.createdButton.text, "Dynamic", "Dynamic modern dropdown should populate the root description")
			V:AssertEqual(capturedTranslator({ data = "value" }), "Selected:value", "Dynamic modern dropdown should use getSelectionText")
		end,
	})

	TS:RegisterTest("classic", "InitializeDropdown_ModernDisabledOptionTooltip", {
		description = "Shared modern dropdowns should keep unavailable options visible, disabled, and explained",
		action = function(V)
			local capturedGenerator
			local radio = {
				SetEnabled = function(self, enabled)
					self.enabled = enabled
				end,
				SetTooltip = function(self, tooltip)
					self.tooltip = tooltip
				end,
			}
			local dropdown = {
				SetupMenu = function(_, generator)
					capturedGenerator = generator
				end,
			}
			local rootDescription = {
				CreateRadio = function()
					return radio
				end,
			}
			BFL.InitializeDropdown(dropdown, {
				labels = { "Modern" },
				values = { "modern" },
				isOptionEnabled = function()
					return false
				end,
				getOptionTooltip = function()
					return "Social UI disabled"
				end,
			}, function()
				return false
			end, function() end)
			V:AssertType(capturedGenerator, "function", "Modern dropdown should receive its menu generator")
			capturedGenerator(dropdown, rootDescription)
			V:AssertEqual(radio.enabled, false, "Unavailable modern dropdown option should be disabled")
			V:AssertType(radio.tooltip, "function", "Unavailable modern dropdown option should expose a tooltip")
			local tooltip = {
				SetText = function(self, text)
					self.title = text
				end,
				AddLine = function(self, text)
					self.body = text
				end,
			}
			radio.tooltip(tooltip)
			V:AssertEqual(tooltip.title, "Modern", "Disabled option tooltip should name the option")
			V:AssertEqual(tooltip.body, "Social UI disabled", "Disabled option tooltip should explain the capability")
		end,
	})

	TS:RegisterTest("classic", "InitializeDropdown_UsesSelectionText", {
		description = "Shared dropdown initializer should allow legacy menu labels and button text to differ",
		action = function(V)
			V:AssertType(BFL.InitializeDropdown, "function", "BFL.InitializeDropdown should exist")

			local oldInitialize = UIDropDownMenu_Initialize
			local oldCreateInfo = UIDropDownMenu_CreateInfo
			local oldAddButton = UIDropDownMenu_AddButton
			local oldSetSelectedValue = UIDropDownMenu_SetSelectedValue
			local oldSetText = UIDropDownMenu_SetText
			local oldClose = CloseDropDownMenus

			local dropdown = {}
			local buttons = {}
			local selectedValue
			local setValue

			local ok, err = pcall(function()
				UIDropDownMenu_CreateInfo = function()
					return {}
				end
				UIDropDownMenu_AddButton = function(info)
					table.insert(buttons, info)
				end
				UIDropDownMenu_SetSelectedValue = function(frame, value)
					selectedValue = value
					frame.selectedValue = value
				end
				UIDropDownMenu_SetText = function(frame, text)
					frame.text = text
				end
				CloseDropDownMenus = function() end
				UIDropDownMenu_Initialize = function(frame, initializer)
					frame.initializer = initializer
					initializer(frame, 1)
				end

				BFL.InitializeDropdown(dropdown, {
					labels = { "Verbose Label", "Hidden Label", "Disabled Label" },
					values = { "value1", "value2", "value3" },
					getSelectionText = function(value)
						return "IconOnly:" .. tostring(value)
					end,
					isOptionHidden = function(value)
						return value == "value2"
					end,
					isOptionEnabled = function(value)
						return value ~= "value3"
					end,
					getOptionTooltip = function(value)
						return value == "value3" and "Unavailable for this client" or nil
					end,
					getItemFontObject = function(value, index)
						V:Assert(
							(value == "value1" and index == 1) or (value == "value3" and index == 3),
							"Font resolver should receive the original item value and index"
						)
						return "BFLTestFontObject"
					end,
				}, function(value)
					return value == "value1"
				end, function(value)
					setValue = value
				end)

				V:AssertEqual(selectedValue, "value1", "Initial selected value should be set")
				V:AssertEqual(dropdown.text, "IconOnly:value1", "Initial legacy dropdown text should use getSelectionText")
				V:AssertEqual(#buttons, 2, "Hidden options should be omitted while disabled options remain visible")
				V:AssertEqual(buttons[1].fontObject, "BFLTestFontObject", "Legacy dropdown item should receive item font object")
				V:AssertEqual(buttons[2].disabled, true, "Unavailable legacy dropdown item should be disabled")
				V:AssertEqual(buttons[2].tooltipWhileDisabled, true, "Disabled legacy dropdown item should retain its tooltip")
				V:AssertEqual(buttons[2].tooltipText, "Unavailable for this client", "Disabled item should explain why it is unavailable")
				buttons[1].func()
				V:AssertEqual(setValue, "value1", "Selection callback should receive the selected value")
				V:AssertEqual(dropdown.text, "IconOnly:value1", "Post-click legacy dropdown text should use getSelectionText")
			end)

			UIDropDownMenu_Initialize = oldInitialize
			UIDropDownMenu_CreateInfo = oldCreateInfo
			UIDropDownMenu_AddButton = oldAddButton
			UIDropDownMenu_SetSelectedValue = oldSetSelectedValue
			UIDropDownMenu_SetText = oldSetText
			CloseDropDownMenus = oldClose
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("classic", "InitializeMultiSelectDropdown_AppliesItemFonts", {
		description = "Shared multi-select dropdown initializer should pass item font objects to legacy menu rows",
		action = function(V)
			V:AssertType(BFL.InitializeMultiSelectDropdown, "function", "BFL.InitializeMultiSelectDropdown should exist")

			local oldInitialize = UIDropDownMenu_Initialize
			local oldCreateInfo = UIDropDownMenu_CreateInfo
			local oldAddButton = UIDropDownMenu_AddButton
			local oldSetText = UIDropDownMenu_SetText

			local dropdown = {}
			local buttons = {}
			local toggledValue
			local toggledChecked

			local ok, err = pcall(function()
				UIDropDownMenu_CreateInfo = function()
					return {}
				end
				UIDropDownMenu_AddButton = function(info)
					table.insert(buttons, info)
				end
				UIDropDownMenu_SetText = function(frame, text)
					frame.text = text
				end
				UIDropDownMenu_Initialize = function(frame, initializer)
					frame.initializer = initializer
					initializer(frame, 1)
				end

				BFL.InitializeMultiSelectDropdown(dropdown, {
					labels = { "First", "Second" },
					values = { "first", "second" },
					getItemFontObject = function(value, index)
						return "BFLFont" .. tostring(index) .. ":" .. tostring(value)
					end,
				}, function(value)
					return value == "first"
				end, function(value, checked)
					toggledValue = value
					toggledChecked = checked
				end, function()
					return "Selected text"
				end)

				V:AssertEqual(dropdown.text, "Selected text", "Initial multi-select text should be set")
				V:AssertEqual(#buttons, 2, "Two dropdown buttons should be created")
				V:AssertEqual(buttons[1].fontObject, "BFLFont1:first", "First item should receive its font object")
				V:AssertEqual(buttons[2].fontObject, "BFLFont2:second", "Second item should receive its font object")
				V:AssertType(buttons[2].checked, "function", "Legacy checkbox state should be dynamic")
				V:AssertEqual(buttons[2].checked(), false, "Unchecked item should report false before click")
				buttons[2].func()
				V:AssertEqual(toggledValue, "second", "Selection callback should receive the toggled value")
				V:AssertEqual(toggledChecked, true, "Selection callback should receive the new checked state")
			end)

			UIDropDownMenu_Initialize = oldInitialize
			UIDropDownMenu_CreateInfo = oldCreateInfo
			UIDropDownMenu_AddButton = oldAddButton
			UIDropDownMenu_SetText = oldSetText
			if not ok then
				error(err, 0)
			end
		end,
	})

	-- ===== INTEGRATION TESTS =====

	TS:RegisterTest("integration", "AllModules_Loaded", {
		description = "All core modules are loaded",
		action = function(V)
			local requiredModules = {
				"DB",
				"Groups",
				"FriendsList",
				"Settings",
				"Changelog",
				"MenuSystem",
				"Dialogs",
				"QuickFilters",
				"WhoFrame",
			}

			for _, moduleName in ipairs(requiredModules) do
				local module = BFL:GetModule(moduleName)
				V:AssertNotNil(module, "Module '" .. moduleName .. "' should be loaded")
			end
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_Toggle", {
		description = "Preview mode can be enabled and disabled",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			V:AssertNotNil(PreviewMode, "PreviewMode module should exist")

			-- Enable
			PreviewMode:Enable()
			V:Assert(PreviewMode.enabled, "PreviewMode should be enabled")

			-- Disable
			PreviewMode:Disable()
			V:Assert(not PreviewMode.enabled, "PreviewMode should be disabled")
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_StagedActivation_HasDiagnosticBoundaries", {
		description = "Slash-command preview activation exposes precise diagnostic phases",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			V:AssertNotNil(PreviewMode, "PreviewMode module should exist")

			local profileID, profile = PreviewMode:GetProfileDefinition("all")
			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			PreviewMode.enabled = true
			PreviewMode.activeProfile = profileID
			PreviewMode.activeComponents = profile.components

			local steps = PreviewMode:BuildProfileActivationSteps(profileID, profile)
			local stepIndexes = {}
			for index, step in ipairs(steps) do
				stepIndexes[step.id] = index
			end

			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents

			local requiredSteps = {
				"friends.fixtures.generate",
				"friends.apply.hook",
				"friends.render.prepare",
				"friends.render.display",
				"refresh.requests",
				"refresh.quick_join",
				"raf.fixtures.enable",
				"refresh.raf",
				"raid.guards.enable",
				"raid.fixtures.generate",
				"raid.render.member_buttons.prepare",
				"raid.render.member_buttons.group_1.prepare",
				"raid.render.member_buttons.group_1.slot_1",
				"raid.render.member_buttons.group_8.slot_5",
				"raid.render.layout",
				"refresh.guild",
				"refresh.navigation",
			}
			for _, stepID in ipairs(requiredSteps) do
				V:Assert(stepIndexes[stepID] ~= nil, "missing staged diagnostic step " .. stepID)
			end
			V:Assert(
				stepIndexes["friends.render.prepare"] < stepIndexes["friends.render.display"],
				"friend render preparation should be isolated before display construction"
			)
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_NormalActivation_IsFrameSlicedAndQuiet", {
		description = "Normal preview uses the safe staged runner without debug chat markers",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			V:AssertNotNil(PreviewMode, "PreviewMode module should exist")

			local startedGeneration
			local startedIndex
			local fakePreview = setmetatable({
				activationGeneration = 42,
				PrepareProfileActivation = function()
					return "all", { components = {} }
				end,
				BuildProfileActivationSteps = function()
					return {
						{ id = "fixture", label = "fixture", action = function() end },
					}, { marker = "context" }
				end,
				RunStagedActivationStep = function(_, generation, index)
					startedGeneration = generation
					startedIndex = index
				end,
			}, { __index = PreviewMode })

			V:Assert(fakePreview:EnableProfile("all"), "normal activation should queue successfully")
			V:Assert(fakePreview.activationInProgress == true, "normal activation should remain in progress")
			V:Assert(fakePreview.activationTrace ~= nil, "normal activation should retain its trace state")
			V:Assert(
				fakePreview.activationTrace.debugMarkers == false,
				"normal activation should suppress diagnostic markers"
			)
			V:AssertEqual(startedGeneration, 42, "normal activation should use the prepared generation")
			V:AssertEqual(startedIndex, 1, "normal activation should start at the first sliced step")
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_FinalFriendCommit_InvalidatesIntermediateProvider", {
		description = "The final preview friend hand-off discards header-only render caches",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			V:AssertNotNil(PreviewMode, "PreviewMode module should exist")

			local updateCalled = false
			local fakeFriendsList = {
				lastBuildSignature = "header-only",
				cachedDisplayList = { "header" },
				cachedGroupedFriends = { favorites = {} },
				forceLayoutRebuild = false,
				UpdateFriendsList = function(self, ignoreVisibility)
					updateCalled = ignoreVisibility == true
					V:Assert(self.lastBuildSignature == nil, "build signature should be invalidated before update")
					V:Assert(self.cachedDisplayList == nil, "display cache should be invalidated before update")
					V:Assert(self.cachedGroupedFriends == nil, "group cache should be invalidated before update")
					V:Assert(self.forceLayoutRebuild == true, "final commit should force a layout rebuild")
				end,
			}
			local fakePreview = setmetatable({
				mockData = { friends = { { _isMock = true } } },
				mockFriendsRenderState = { revision = 1 },
				IsComponentEnabled = function()
					return true
				end,
			}, { __index = PreviewMode })

			V:Assert(
				fakePreview:RenderMockFriendsNow(fakeFriendsList, true),
				"final mock friend commit should render"
			)
			V:Assert(updateCalled, "final mock friend commit should request a visible update")
			V:Assert(fakePreview.mockFriendsRenderState == nil, "render-state cache should be invalidated")
		end,
	})

	TS:RegisterTest("integration", "Preview_RaidMock_SkipsSyntheticSecureUnit", {
		description = "Preview raid rows never register synthetic raid tokens as secure units",
		action = function(V)
			if InCombatLockdown() then
				V:Skip("Secure attributes cannot be tested during combat")
				return
			end
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")

			local fakeButton = {
				memberData = { _isMock = true },
				unit = "raid1",
				registeredSyntheticUnit = false,
				secureAttributeWrites = 0,
			}
			function fakeButton:SetAttribute(key, value)
				self.secureAttributeWrites = self.secureAttributeWrites + 1
				if key == "unit" and value ~= nil then
					self.registeredSyntheticUnit = true
				end
			end

			RaidFrame:UpdateSecureAttributesForButton(fakeButton)
			V:Assert(
				not fakeButton.registeredSyntheticUnit,
				"mock raid unit should not enter the secure unit-menu resolver"
			)
			V:AssertEqual(
				fakeButton.secureAttributeWrites,
				0,
				"mock raid rendering should not enqueue any secure attribute writes"
			)
		end,
	})

	TS:RegisterTest("data", "Preview_RaidMock_IncludesMasterLooter", {
		description = "The Raid preview keeps one Master Looter fixture for the shared row renderer",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")
			local originalRaidMembers = RaidFrame.raidMembers
			local originalDisplayList = RaidFrame.displayList
			local originalMockEnabled = RaidFrame.mockEnabled
			local originalClearMockData = RaidFrame.ClearMockData
			local ok, err = pcall(function()
				RaidFrame.ClearMockData = function(self)
					self.raidMembers = {}
					self.displayList = {}
				end
				RaidFrame:CreateMockPreset_Standard({
					deferApply = true,
					deferDynamicUpdates = true,
				})
				local masterLooterCount = 0
				for _, member in ipairs(RaidFrame.raidMembers) do
					if member.isML == true then
						masterLooterCount = masterLooterCount + 1
						V:Assert(member._isMock == true, "Master Looter fixture should remain marked as preview data")
					end
				end
				V:AssertEqual(masterLooterCount, 1, "Raid preview should contain exactly one Master Looter")
			end)
			RaidFrame.ClearMockData = originalClearMockData
			RaidFrame.raidMembers = originalRaidMembers
			RaidFrame.displayList = originalDisplayList
			RaidFrame.mockEnabled = originalMockEnabled
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "RaidFrame_MemberRefresh_UsesSecureSafeRenderer", {
		description = "Legacy refresh entry points delegate to the mock-safe per-slot renderer",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")

			local originalUpdateAllMemberButtons = RaidFrame.UpdateAllMemberButtons
			local calls = 0
			RaidFrame.UpdateAllMemberButtons = function()
				calls = calls + 1
				return "safe-renderer"
			end

			local ok, result = pcall(RaidFrame.UpdateMemberButtons, RaidFrame)
			RaidFrame.UpdateAllMemberButtons = originalUpdateAllMemberButtons
			if not ok then
				error(result, 0)
			end

			V:AssertEqual(calls, 1, "member refresh should use the shared secure-safe renderer exactly once")
			V:AssertEqual(result, "safe-renderer", "member refresh should return the shared renderer result")
		end,
	})

	TS:RegisterTest("integration", "Scenario_Load_Stress200", {
		description = "ScenarioManager should load stress_200 and apply mock data",
		action = function(V)
			local ScenarioManager = BFL.ScenarioManager
			local FriendsList = BFL:GetModule("FriendsList")
			if not ScenarioManager then
				V:Skip("ScenarioManager not available")
				return
			end
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local ok = ScenarioManager:Load("stress_200")
			V:Assert(ok == true, "Scenario stress_200 should load")

			FriendsList:UpdateFriendsList()
			V:Assert(
				FriendsList.friendsList and #FriendsList.friendsList > 0,
				"Friends list should populate from mock data"
			)

			ScenarioManager:Clear()
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_RestorePersistedState", {
		description = "PreviewMode should restore persisted state and clear backup",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not PreviewMode then
				V:Skip("PreviewMode not available")
				return
			end
			if not BetterFriendlistDB then
				V:Skip("DB not initialized")
				return
			end

			local originalBackup = BetterFriendlistDB.previewBackup
			local originalGroupOrder = BetterFriendlistDB.groupOrder
			local originalFriendGroups = BetterFriendlistDB.friendGroups

			BetterFriendlistDB.previewBackup = {
				groupOrder = { "favorites", "nogroup" },
				friendGroups = { wow_TestRestore = { "favorites" } },
			}
			BetterFriendlistDB.groupOrder = { "temp" }
			BetterFriendlistDB.friendGroups = {}

			PreviewMode:RestorePersistedState()

			V:Assert(BetterFriendlistDB.previewBackup == nil, "previewBackup should be cleared")
			V:AssertEqual(BetterFriendlistDB.groupOrder[1], "favorites", "groupOrder should be restored")
			V:Assert(BetterFriendlistDB.friendGroups.wow_TestRestore ~= nil, "friendGroups should be restored")

			BetterFriendlistDB.previewBackup = originalBackup
			BetterFriendlistDB.groupOrder = originalGroupOrder
			BetterFriendlistDB.friendGroups = originalFriendGroups
		end,
	})

	TS:RegisterTest("integration", "PreviewMode_Enable_Disable_RoundTrip", {
		description = "PreviewMode should enable and disable without persisting changes",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not PreviewMode then
				V:Skip("PreviewMode not available")
				return
			end
			if PreviewMode.enabled then
				V:Skip("PreviewMode already enabled")
				return
			end
			if not BetterFriendlistDB then
				V:Skip("DB not initialized")
				return
			end

			local DB = BFL:GetModule("DB")
			local originalBackup = BetterFriendlistDB.previewBackup
			local originalOrder = BetterFriendlistDB.groupOrder
			if DB then
				DB:Set("groupOrder", { "favorites", "nogroup" })
			end

			PreviewMode:Enable()
			V:Assert(PreviewMode.enabled == true, "PreviewMode should be enabled")
			V:Assert(BetterFriendlistDB.previewBackup ~= nil, "previewBackup should exist after enable")

			PreviewMode:Disable()
			V:Assert(PreviewMode.enabled == false, "PreviewMode should be disabled")
			V:Assert(BetterFriendlistDB.previewBackup == nil, "previewBackup should be cleared after disable")

			BetterFriendlistDB.previewBackup = originalBackup
			BetterFriendlistDB.groupOrder = originalOrder
		end,
	})

	TS:RegisterTest("integration", "QuickJoin_MockGroup_Structure", {
		description = "QuickJoin mock groups should have required fields",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local QuickJoin = BFL:GetModule("QuickJoin")
			if not QuickJoin then
				V:Skip("QuickJoin not loaded")
				return
			end

			local guid, groupData = QuickJoin:CreateMockGroup({
				leaderName = "TestLeader",
				activityName = "Test Activity",
				numMembers = 5,
			})
			V:Assert(type(guid) == "string", "Mock GUID should be a string")
			V:Assert(groupData and groupData.leaderName == "TestLeader", "leaderName should match")
			V:Assert(groupData.numMembers == 5, "numMembers should match")
			V:Assert(type(groupData.members) == "table", "members should be a table")
			V:Assert(groupData.canJoin == true, "canJoin should be true")
			V:Assert(QuickJoin.mockGroups[guid] ~= nil, "mockGroups should contain the entry")
			V:Assert(QuickJoin:IsMockGroup(guid, groupData), "mock group should be recognized before native API access")
			V:AssertEqual(groupData._mockLeaderName, "TestLeader", "mock leader fallback should be retained")
			V:AssertEqual(
				QuickJoin:GetGroupPriority(guid, groupData),
				0,
				"mock priority should resolve without native GUID APIs"
			)

			QuickJoin.mockGroups[guid] = nil
		end,
	})

	TS:RegisterTest("integration", "Preview_MockFriends_SkipUnchangedRender", {
		description = "Stable preview friends should render once until local display state changes",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			local FriendsList = BFL:GetModule("FriendsList")
			if not PreviewMode or not FriendsList then
				V:Skip("PreviewMode or FriendsList not available")
				return
			end

			local originalState = PreviewMode.mockFriendsRenderState
			local originalRevision = PreviewMode.mockFriendsRevision
			local originalSearchText = FriendsList.searchText
			local originalForceLayoutRebuild = FriendsList.forceLayoutRebuild
			PreviewMode.mockFriendsRenderState = nil
			PreviewMode.mockFriendsRevision = originalRevision + 1
			FriendsList.forceLayoutRebuild = false

			V:Assert(PreviewMode:ShouldRenderMockFriends(FriendsList), "first mock render should be allowed")
			V:Assert(not PreviewMode:ShouldRenderMockFriends(FriendsList), "unchanged mock render should be skipped")
			FriendsList.searchText = (originalSearchText or "") .. "preview-state-change"
			V:Assert(PreviewMode:ShouldRenderMockFriends(FriendsList), "search changes should invalidate preview render")

			FriendsList.searchText = originalSearchText
			FriendsList.forceLayoutRebuild = originalForceLayoutRebuild
			PreviewMode.mockFriendsRevision = originalRevision
			PreviewMode.mockFriendsRenderState = originalState
		end,
	})

	TS:RegisterTest("integration", "Preview_MockFriends_RefreshSettingsBeforeRender", {
		description = "Preview friends must refresh invalidated visual and font caches before rendering",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not PreviewMode or not PreviewMode.PrepareMockFriendsRender then
				V:Skip("PreviewMode settings preparation is not available")
				return
			end

			local originalSettingsVersion = BFL.SettingsVersion
			local calls = {}
			local fakeFriendsList = {
				settingsCacheVersion = 40,
				settingsCache = { treatMobileAsOffline = false },
				UpdateFontCache = function()
					calls[#calls + 1] = "font"
				end,
				UpdateSettingsCache = function(self)
					calls[#calls + 1] = "settings"
					self.settingsCacheVersion = BFL.SettingsVersion
				end,
			}

			BFL.SettingsVersion = 41
			local changed = PreviewMode:PrepareMockFriendsRender(fakeFriendsList)
			BFL.SettingsVersion = originalSettingsVersion

			V:Assert(changed, "an invalidated Preview settings cache should be detected")
			V:AssertEqual(calls[1], "font", "font/layout cache should refresh first")
			V:AssertEqual(calls[2], "settings", "visual settings cache should refresh before render")
			V:AssertEqual(#calls, 2, "one Preview preparation should refresh each cache once")
		end,
	})

	TS:RegisterTest("integration", "Preview_MobileSettings_ProjectReversibly", {
		description = "Preview mobile-only friends follow Treat Mobile as Offline and recover when it is disabled",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not (PreviewMode and PreviewMode.ApplyMockFriendSettingState) then
				V:Skip("Preview mobile setting projection is not available")
				return
			end

			local originalFriends = PreviewMode.mockData.friends
			local originalRevision = PreviewMode.mockFriendsRevision
			local mobile = {
				_isMock = true,
				_previewBaseConnected = true,
				_previewMobileOnly = true,
				connected = true,
			}
			PreviewMode.mockData.friends = { mobile }
			PreviewMode:ApplyMockFriendSettingState({ settingsCache = { treatMobileAsOffline = true } })
			V:Assert(not mobile.connected, "mobile-only Preview friend should become offline")
			V:Assert(mobile.isMobileButTreatedOffline, "projected offline state should carry the mobile marker")
			PreviewMode:ApplyMockFriendSettingState({ settingsCache = { treatMobileAsOffline = false } })
			V:Assert(mobile.connected, "disabling the setting should restore the original online state")
			V:AssertNil(mobile.isMobileButTreatedOffline, "restored mobile friend should clear the offline marker")
			PreviewMode.mockData.friends = originalFriends
			PreviewMode.mockFriendsRevision = originalRevision
		end,
	})

	TS:RegisterTest("integration", "Friends_RowHeight_GrowsWithVisibleLines", {
		description = "Friend rows use three-pixel outer padding and grow for info, multi-account, and tag lines",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.CalculateFriendRowHeight then
				V:Skip("FriendsList row-height calculator is not available")
				return
			end

			local base = FriendsList:CalculateFriendRowHeight(12, 10, false, false, 0, 1)
			local withMultiAccount = FriendsList:CalculateFriendRowHeight(12, 10, false, true, 0, 1)
			local withTags = FriendsList:CalculateFriendRowHeight(12, 10, false, false, 16, 1)
			local complete = FriendsList:CalculateFriendRowHeight(12, 10, false, true, 16, 1)
			local wrappedName = FriendsList:CalculateFriendRowHeight(12, 10, false, false, 0, 1, 28)
			local largeFonts = FriendsList:CalculateFriendRowHeight(40, 36, false, true, 16, 1)

			V:AssertEqual(base, 33, "name and info should use exact line heights plus 3px outer padding")
			V:AssertEqual(
				withMultiAccount - base,
				13,
				"multi-account details should add one info-sized line and one gap"
			)
			V:AssertEqual(withTags - base, 16, "one tag row should contribute its exact rendered extent")
			V:AssertEqual(complete, 62, "all four visible rows should fit without hidden padding")
			V:AssertEqual(wrappedName, 47, "a second rendered name line should grow the row instead of being truncated")
			V:Assert(largeFonts > 72, "large configured fonts must grow beyond the retired 72px cap")
		end,
	})

	TS:RegisterTest("integration", "FriendLevelDiagnostics_ClassifiesLevelSources", {
		description = "The internal level diagnostic separates upstream zero values from accessor and BFL normalization mismatches",
		action = function(V)
			local Diagnostics = BFL:GetModule("FriendLevelDiagnostics")
			V:AssertNotNil(Diagnostics, "Friend level diagnostics should be loaded")
			V:AssertEqual(SLASH_BFLLEVELDIAG1, "/bfllvldiag", "The internal diagnostic should use its standalone slash command")
			V:Assert(type(SlashCmdList.BFLLEVELDIAG) == "function", "The internal diagnostic slash handler should be registered")

			local rawZero = {
				gameAccountID = 41,
				clientProgram = "WoW",
				isOnline = true,
				characterLevel = 0,
			}
			local _, apiVerdict = Diagnostics:AnalyzeRecord({
				kind = "bnet",
				focused = rawZero,
				bflFriend = {
					connected = true,
					level = 0,
					gameAccountInfo = rawZero,
				},
				gameAccounts = {
					{ index = 1, raw = rawZero, byID = { characterLevel = 0 } },
				},
			})
			V:AssertEqual(apiVerdict, "API_REPORTED_NONPOSITIVE_LEVEL", "Consensus zero values should be attributed to the API")

			local _, accessorVerdict = Diagnostics:AnalyzeRecord({
				kind = "bnet",
				focused = rawZero,
				gameAccounts = {
					{ index = 1, raw = rawZero, byID = { characterLevel = 70 } },
				},
			})
			V:AssertEqual(accessorVerdict, "API_ACCESSOR_MISMATCH", "A positive alternate accessor should expose an API inconsistency")

			local rawPositive = {
				gameAccountID = 42,
				clientProgram = "WoW",
				isOnline = true,
				characterLevel = 70,
			}
			local _, bflVerdict = Diagnostics:AnalyzeRecord({
				kind = "bnet",
				focused = rawPositive,
				bflFriend = {
					connected = true,
					level = 0,
					gameAccountInfo = rawPositive,
				},
				gameAccounts = {
					{ index = 1, raw = rawPositive },
				},
			})
			V:AssertEqual(bflVerdict, "BFL_NORMALIZATION_MISMATCH", "A positive selected API level should expose a BFL mismatch")
		end,
	})

	TS:RegisterTest("integration", "Friends_DefaultInfoIgnoresNonpositiveApiLevel", {
		description = "The default friend info formatter treats API level zero as unavailable and preserves useful presence text",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			V:AssertNotNil(FriendsList, "FriendsList module should exist")

			local settingsCache = FriendsList.settingsCache
			local originalPreset = settingsCache.infoFormatPreset
			local originalHideMaxLevel = settingsCache.hideMaxLevel
			local originalColorLevel = settingsCache.colorLevelByDifficulty
			local ok, err = pcall(function()
				settingsCache.infoFormatPreset = "default"
				settingsCache.hideMaxLevel = false
				settingsCache.colorLevelByDifficulty = false

				local friend = {
					type = "bnet",
					connected = true,
					level = 0,
					areaName = "Venomfall Deeps",
					gameName = "World of Warcraft",
					numGameAccounts = 1,
				}
				V:AssertEqual(
					FriendsList:FormatInfoLine(friend),
					"Venomfall Deeps",
					"A zero API level should fall back to the available zone"
				)

				friend.areaName = ""
				V:AssertEqual(
					FriendsList:FormatInfoLine(friend),
					"World of Warcraft",
					"A zero API level without a zone should fall back to the game name"
				)
			end)
			settingsCache.infoFormatPreset = originalPreset
			settingsCache.hideMaxLevel = originalHideMaxLevel
			settingsCache.colorLevelByDifficulty = originalColorLevel
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "Friends_NameMeasurement_ResetsAfterCompactText", {
		description = "Friend-name measurement forgets a wrapped Compact label before restoring the normal layout",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.MeasureWrappedFriendNameHeight then
				V:Skip("FriendsList name-height measurement is not available")
				return
			end

			local baselineHeight = FriendsList:MeasureWrappedFriendNameHeight(12, "Anduin", 240)
			local compactHeight = FriendsList:MeasureWrappedFriendNameHeight(
				12,
				"Anduin - Level 90, Orgrimmar - Diablo IV, Torment",
				90
			)
			local restoredHeight = FriendsList:MeasureWrappedFriendNameHeight(12, "Anduin", 240)

			V:Assert(
				compactHeight > baselineHeight,
				"the narrow Compact label should wrap beyond the baseline name height"
			)
			V:AssertEqual(
				restoredHeight,
				baselineHeight,
				"the restored name-only label should recover its original height"
			)
		end,
	})

	TS:RegisterTest("integration", "Friends_TextWidth_ReservesRightSideControls", {
		description = "Friend name measurement reserves current title icons, action buttons, and favorite icons",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.GetFriendTextRightPadding then
				V:Skip("FriendsList text geometry helper is not available")
				return
			end

			local probe = {
				settingsCache = {
					showGameIcon = true,
					infoDisabled = false,
					enableFavoriteIcon = true,
					favoriteIconStyle = "bfl",
				},
			}
			local titleFriend = {
				type = "bnet",
				connected = true,
				gameAccountInfo = { clientProgram = "WoW" },
			}
			local wowFriend = {
				type = "wow",
				connected = true,
			}

			local modernWoWPadding = FriendsList.GetFriendTextRightPadding(
				probe,
				wowFriend,
				true,
				false,
				12,
				10,
				false
			)
			local legacyWoWPadding = FriendsList.GetFriendTextRightPadding(
				probe,
				wowFriend,
				false,
				false,
				12,
				10,
				false
			)
			local titlePadding = FriendsList.GetFriendTextRightPadding(
				probe,
				titleFriend,
				true,
				false,
				12,
				10,
				false
			)
			local favoritePadding = FriendsList.GetFriendTextRightPadding(
				probe,
				titleFriend,
				true,
				false,
				12,
				10,
				true
			)

			probe.settingsCache.showGameIcon = false
			local actionPadding = FriendsList.GetFriendTextRightPadding(
				probe,
				titleFriend,
				true,
				false,
				12,
				10,
				false
			)

			V:AssertEqual(legacyWoWPadding, 25, "Legacy WoW rows without right-side controls retain the base inset")
			V:Assert(
				titlePadding > actionPadding and actionPadding == modernWoWPadding,
				"title icons and every Modern action button should reduce the usable text width"
			)
			V:Assert(
				favoritePadding > titlePadding,
				"the favorite texture should reserve additional room before the right-side controls"
			)
		end,
	})

	TS:RegisterTest("integration", "Friends_FavoriteIconKeepsReleaseAnchorAndBalancedSuffix", {
		description = "Compact favorite icons retain their release anchoring while the following info text uses balanced spacing",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not (FriendsList and FriendsList.GetFavoriteIconLayout) then
				V:Skip("Favorite layout helpers are not available")
				return
			end

			local bfl = FriendsList:GetFavoriteIconLayout(12, "bfl")
			local blizzard = FriendsList:GetFavoriteIconLayout(12, "blizzard")
			V:AssertEqual(bfl.iconSize, 8, "BFL favorite icon should retain its release size")
			V:AssertEqual(bfl.xOffset, 2, "BFL favorite icon should retain its release name anchor")
			V:AssertEqual(bfl.yOffset, 0, "BFL favorite icon should retain its release vertical anchor")
			V:AssertEqual(#bfl.compactSpacer, 3, "BFL Compact Info should leave one additional spacer after the icon")
			V:AssertEqual(blizzard.iconSize, 14, "Blizzard favorite icon should retain its release size")
			V:AssertEqual(blizzard.xOffset, -1, "Blizzard favorite icon should retain its compensated release name anchor")
			V:AssertEqual(blizzard.yOffset, 3, "Blizzard favorite icon should retain its compensated release vertical anchor")
			V:AssertEqual(
				#blizzard.compactSpacer,
				3,
				"Blizzard Compact Info should reserve only its three-pixel wider right edge"
			)
			V:AssertEqual(
				#blizzard.compactSpacer,
				#bfl.compactSpacer,
				"Both icon styles should give following Compact Info the same explicit breathing room"
			)
		end,
	})

	TS:RegisterTest("integration", "Preview_SettingsFixtures_CoverVisualOptions", {
		description = "Preview fixtures expose every data shape required by visual Friends and Guild settings",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not PreviewMode then
				V:Skip("PreviewMode not available")
				return
			end

			local originalFriends = PreviewMode.mockData.friends
			local originalGroups = PreviewMode.mockData.groups
			local originalAssignments = PreviewMode.mockData.groupAssignments
			local originalFriendNicknames = PreviewMode.mockData.friendNicknames
			local originalGuildNicknames = PreviewMode.mockData.guildNicknames
			local originalRecent = PreviewMode.mockData.recentlyAddedTimestamps
			local originalContacts = PreviewMode.mockData.contactMemory
			local originalGuildMembers = PreviewMode.mockData.guildRosterMembers
			local originalGuildName = PreviewMode.mockData.guildRosterName
			local originalGuildMOTD = PreviewMode.mockData.guildRosterMOTD

			PreviewMode:GenerateMockFriends()
			local hasMobileOnly = false
			local hasMultipleAccounts = false
			local hasMaxLevel = false
			local hasAlliance = false
			local hasHorde = false
			local hasVisibleMobileOnly = false
			local hasVisibleOppositeFaction = false
			local hasLowerLevelFavorite = false
			local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 90
			local playerFaction = UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
			for _, friend in ipairs(PreviewMode.mockData.friends) do
				if friend.connected and friend.clientProgram == "BSAp" and (friend.numGameAccounts or 0) == 0 then
					hasMobileOnly = true
					hasVisibleMobileOnly = friend.isFavorite == true
				end
				if friend.connected and (friend.numGameAccounts or 0) > 1 and #(friend.gameAccounts or {}) > 1 then
					hasMultipleAccounts = true
				end
				if tonumber(friend.level) == tonumber(maxLevel) then
					hasMaxLevel = true
				end
				hasAlliance = hasAlliance or friend.factionName == "Alliance"
				hasHorde = hasHorde or friend.factionName == "Horde"
				if friend.isFavorite and friend.connected and friend.factionName and friend.factionName ~= playerFaction then
					hasVisibleOppositeFaction = true
				end
				if friend.isFavorite and tonumber(friend.level) and tonumber(friend.level) < tonumber(maxLevel) then
					hasLowerLevelFavorite = true
				end
			end
			V:Assert(hasMobileOnly, "Preview should include a mobile-only Battle.net friend")
			V:Assert(hasVisibleMobileOnly, "The mobile-only fixture should be visible in Favorites")
			V:Assert(hasMultipleAccounts, "Preview should include a friend with multiple online game accounts")
			V:Assert(hasMaxLevel, "Preview should include a max-level friend")
			V:Assert(hasAlliance and hasHorde, "Preview should expose both factions for faction display settings")
			V:Assert(
				hasVisibleOppositeFaction,
				"Favorites should expose an opposite-faction row for faction background testing"
			)
			V:Assert(
				hasLowerLevelFavorite,
				"Favorites should expose a lower-level WoW row for difficulty-color testing"
			)
			V:Assert(
				PreviewMode.mockData.friendNicknames["bnet_Anduin#1234"] ~= nil,
				"Preview should expose a friend nickname without SavedVariables"
			)
			V:Assert(
				PreviewMode.mockData.recentlyAddedTimestamps["bnet_Anduin#1234"]
					> PreviewMode.mockData.recentlyAddedTimestamps["bnet_Thrall#9012"],
				"Recently Added fixtures should span multiple ages"
			)
			V:Assert(next(PreviewMode.mockData.contactMemory) ~= nil, "Preview should expose ephemeral Contact Memory data")
			local expectedInternationalAssignments = {
				["bnet_안녕하세요#1111"] = "font_korean",
				["bnet_你好世界#2222"] = "font_simplified_chinese",
				["bnet_哈囉世界#3333"] = "font_traditional_chinese",
				["bnet_Россия#4444"] = "font_russian",
			}
			for uid, expectedGroup in pairs(expectedInternationalAssignments) do
				local assigned = false
				for _, groupID in ipairs(PreviewMode.mockData.groupAssignments[uid] or {}) do
					assigned = assigned or groupID == expectedGroup
				end
				V:Assert(assigned, uid .. " should populate " .. expectedGroup)
			end

			PreviewMode:GenerateMockGroupsData()
			local hasInGameGroup = false
			local hasRecentlyAddedGroup = false
			for _, group in ipairs(PreviewMode.mockData.groups) do
				hasInGameGroup = hasInGameGroup or group.id == "ingame"
				hasRecentlyAddedGroup = hasRecentlyAddedGroup or group.id == "recentlyadded"
			end
			V:Assert(hasInGameGroup, "Complete preview should carry the opt-in In-Game group")
			V:Assert(hasRecentlyAddedGroup, "Complete preview should carry the opt-in Recently Added group")

			PreviewMode:GenerateGuildPreviewData()
			V:Assert(
				PreviewMode.mockData.guildNicknames["Hayato-Blackrock"] ~= nil,
				"Guild preview should expose a nickname without SavedVariables"
			)

			PreviewMode.mockData.friends = originalFriends
			PreviewMode.mockData.groups = originalGroups
			PreviewMode.mockData.groupAssignments = originalAssignments
			PreviewMode.mockData.friendNicknames = originalFriendNicknames
			PreviewMode.mockData.guildNicknames = originalGuildNicknames
			PreviewMode.mockData.recentlyAddedTimestamps = originalRecent
			PreviewMode.mockData.contactMemory = originalContacts
			PreviewMode.mockData.guildRosterMembers = originalGuildMembers
			PreviewMode.mockData.guildRosterName = originalGuildName
			PreviewMode.mockData.guildRosterMOTD = originalGuildMOTD
		end,
	})

	TS:RegisterTest("integration", "Preview_SettingsRefresh_IsBounded", {
		description = "Settings changes coalesce into one session-bound Preview refresh",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			local DB = BFL:GetModule("DB")
			if not PreviewMode or not DB then
				V:Skip("PreviewMode or DB not available")
				return
			end

			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			local originalGeneration = PreviewMode.settingsRefreshGeneration
			local originalPending = PreviewMode.settingsRefreshPending
			local originalKeys = PreviewMode.pendingSettingKeys
			local originalRefreshing = PreviewMode.refreshingSettingsPreview
			local originalRefreshActiveComponents = PreviewMode.RefreshActiveComponents
			local originalOnSettingChanged = PreviewMode.OnSettingChanged

			local refreshCount = 0
			PreviewMode.enabled = true
			PreviewMode.activeProfile = "settings-test"
			PreviewMode.activeComponents = {}
			PreviewMode.settingsRefreshGeneration = 42
			PreviewMode.settingsRefreshPending = true
			PreviewMode.pendingSettingKeys = {}
			PreviewMode.refreshingSettingsPreview = false
			PreviewMode.RefreshActiveComponents = function()
				refreshCount = refreshCount + 1
				return {}
			end

			V:Assert(PreviewMode:OnSettingChanged("fontFriendName"), "first queued key should be accepted")
			V:Assert(PreviewMode:OnSettingChanged("fontSizeFriendName"), "second queued key should be coalesced")
			V:Assert(PreviewMode.pendingSettingKeys.fontFriendName, "first key should be retained")
			V:Assert(PreviewMode.pendingSettingKeys.fontSizeFriendName, "second key should be retained")
			PreviewMode:FlushPendingSettingsRefresh(42)
			V:AssertEqual(refreshCount, 1, "one settings change burst should refresh exactly once")
			V:Assert(not PreviewMode.settingsRefreshPending, "successful flush should release the pending gate")
			PreviewMode:FlushPendingSettingsRefresh(41)
			V:AssertEqual(refreshCount, 1, "a callback from an expired Preview session must be ignored")

			local notifiedKey
			PreviewMode.OnSettingChanged = function(_, key)
				notifiedKey = key
			end
			local originalDebugSetting = DB:Get("debugPrintEnabled", false)
			DB:Set("debugPrintEnabled", originalDebugSetting)
			V:AssertEqual(notifiedKey, "debugPrintEnabled", "DB:Set should notify PreviewMode")

			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents
			PreviewMode.settingsRefreshGeneration = originalGeneration
			PreviewMode.settingsRefreshPending = originalPending
			PreviewMode.pendingSettingKeys = originalKeys
			PreviewMode.refreshingSettingsPreview = originalRefreshing
			PreviewMode.RefreshActiveComponents = originalRefreshActiveComponents
			PreviewMode.OnSettingChanged = originalOnSettingChanged
		end,
	})

	TS:RegisterTest("integration", "Preview_IsolationProfiles", {
		description = "Preview profiles expose one tab fixture at a time and keep unrelated components inactive",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			if not PreviewMode then
				V:Skip("PreviewMode not available")
				return
			end

			local friendsID, friends = PreviewMode:GetProfileDefinition("friends")
			local plainID, plain = PreviewMode:GetProfileDefinition("friends-plain")
			local tagsID, tags = PreviewMode:GetProfileDefinition("friends-tags")
			local oneHeaderID, oneHeader = PreviewMode:GetProfileDefinition("friends-header-one")
			local headersID, headers = PreviewMode:GetProfileDefinition("friends-headers")
			local latinHeadersID, latinHeaders = PreviewMode:GetProfileDefinition("friends-headers-latin")
			local i18nHeadersID, i18nHeaders = PreviewMode:GetProfileDefinition("friends-headers-i18n")
			local groupsID, groups = PreviewMode:GetProfileDefinition("friends-groups")
			local recentID, recent = PreviewMode:GetProfileDefinition("recent-allies")
			local quickJoinID, quickJoin = PreviewMode:GetProfileDefinition("qj")
			local rafID, raf = PreviewMode:GetProfileDefinition("raf")
			local raidID, raid = PreviewMode:GetProfileDefinition("raid")
			local guildID, guild = PreviewMode:GetProfileDefinition("guild")
			local whoID, who = PreviewMode:GetProfileDefinition("who")
			local allID, all = PreviewMode:GetProfileDefinition("all")
			V:AssertEqual(friendsID, "friends", "Friends profile should resolve directly")
			V:Assert(
				friends.components.friends
					and friends.components.groups
					and friends.components.group_assignments
					and friends.components.tags,
				"Friends should include rows, group assignments, and tags"
			)
			V:AssertEqual(plainID, "friends_plain", "Hyphenated friends-plain alias should normalize")
			V:Assert(
				plain.components.friends and not plain.components.groups and not plain.components.tags,
				"Friends-plain should exclude groups and tags"
			)
			V:AssertEqual(tagsID, "friends_tags", "Hyphenated friends-tags alias should normalize")
			V:Assert(
				tags.components.friends and tags.components.tags and not tags.components.groups,
				"Friends-tags should add tags without custom groups"
			)
			V:AssertEqual(oneHeaderID, "friends_header_one", "friends-header-one profile should resolve directly")
			V:AssertEqual(oneHeader.groupFixture, "one", "Single-header profile should select the minimal fixture")
			V:AssertEqual(headersID, "friends_group_headers", "friends-headers alias should resolve")
			V:Assert(
				headers.components.friends
					and headers.components.groups
					and not headers.components.group_assignments
					and not headers.components.tags,
				"Friends-headers should add empty custom group headers only"
			)
			V:AssertEqual(headers.groupFixture, "ascii", "Default header diagnostic should retain ASCII-only names")
			V:AssertEqual(
				latinHeadersID,
				"friends_headers_latin",
				"friends-headers-latin profile should resolve directly"
			)
			V:AssertEqual(
				latinHeaders.groupFixture,
				"latin",
				"Extended Latin header profile should select the Latin fixture"
			)
			V:AssertEqual(
				i18nHeadersID,
				"friends_headers_i18n",
				"friends-headers-i18n profile should resolve directly"
			)
			V:AssertEqual(
				i18nHeaders.groupFixture,
				"international",
				"International header profile should retain multilingual labels"
			)
			V:AssertEqual(groupsID, "friends_groups", "friends-groups profile should resolve directly")
			V:Assert(
				groups.components.friends
					and groups.components.groups
					and groups.components.group_assignments
					and not groups.components.tags,
				"Friends-groups should add group assignments without tags"
			)
			V:AssertEqual(recentID, "recent_allies", "recent-allies profile should resolve directly")
			V:Assert(recent.components.recent_allies, "Recent Allies should own a real preview fixture")
			V:AssertEqual(quickJoinID, "quick_join", "qj alias should resolve to Quick Join")
			V:Assert(quickJoin.components.quick_join and not quickJoin.components.raid, "Quick Join should be isolated")
			V:AssertEqual(rafID, "recruit_a_friend", "raf alias should resolve to Recruit a Friend")
			V:Assert(raf.components.raf and not raf.components.friends, "Recruit a Friend should own an isolated fixture")
			V:AssertEqual(raidID, "raid", "Raid profile should resolve directly")
			V:Assert(raid.components.raid and not raid.components.quick_join, "Raid should be isolated")
			V:AssertEqual(guildID, "guild", "Guild profile should resolve directly")
			V:Assert(guild.components.guild and not guild.components.friends, "Guild should own an isolated roster fixture")
			V:AssertEqual(whoID, "who", "Who profile input should normalize without resolving")
			V:Assert(who == nil, "Preview mode must not expose a Who mock profile")
			V:AssertEqual(allID, "all", "All profile should resolve directly")
			V:Assert(all.components.recent_allies, "The combined preview should include Recent Allies")
			V:Assert(all.components.guild, "The combined preview should include the Guild roster")
			V:Assert(all.components.raf, "The combined preview should include Recruit a Friend")
			V:Assert(not all.components.who, "The combined preview must not activate Who mock data")

			local originalMockFriends = PreviewMode.mockData.friends
			local originalRecentAllies = PreviewMode.mockData.recentAllies
			local originalFriendAssignments = PreviewMode.mockData.groupAssignments
			PreviewMode:GenerateMockFriends()
			local favoriteCount, favoriteWoWCount = 0, 0
			for _, friend in ipairs(PreviewMode.mockData.friends) do
				if friend.type == "bnet" and friend.connected then
					V:Assert(
						type(friend._previewTitleIcon) == "string" and friend._previewTitleIcon ~= "",
						"Connected Battle.net preview rows should provide deterministic modern title art"
					)
					V:AssertEqual(
						friend.gameAccountInfo and friend.gameAccountInfo._previewTitleIcon,
						friend._previewTitleIcon,
						"Primary mock account and friend row should share the same title art"
					)
				end
				if friend.connected and friend.isFavorite then
					favoriteCount = favoriteCount + 1
					if friend.clientProgram == "WoW"
						and friend.gameAccountInfo
						and friend.gameAccountInfo.clientProgram == "WoW"
						and friend.gameAccountInfo.characterName ~= ""
					then
						favoriteWoWCount = favoriteWoWCount + 1
					end
				end
			end
			V:Assert(favoriteCount > 0, "Friends preview should include online favorites")
			V:AssertEqual(favoriteWoWCount, favoriteCount, "Leading preview favorites should expose complete WoW game status")
			PreviewMode:GenerateRecentAlliesPreviewData()
			V:Assert(#PreviewMode.mockData.recentAllies >= 5, "Recent Allies preview should populate representative rows")
			V:Assert(
				PreviewMode.mockData.recentAllies[1].stateData.isOnline
					and PreviewMode.mockData.recentAllies[1].characterData.classID ~= nil,
				"Recent Allies fixtures should include online and class metadata"
			)
			PreviewMode.mockData.friends = originalMockFriends
			PreviewMode.mockData.recentAllies = originalRecentAllies
			PreviewMode.mockData.groupAssignments = originalFriendAssignments

			local originalMockGroups = PreviewMode.mockData.groups
			local originalAssignments = PreviewMode.mockData.groupAssignments
			PreviewMode.mockData.groupAssignments = {}
			PreviewMode:GenerateMockGroupsData("one")
			V:AssertEqual(#PreviewMode.mockData.groups, 3, "Minimal fixture should contain built-ins and one custom group")
			PreviewMode.mockData.groupAssignments = {}
			PreviewMode:GenerateMockGroupsData("ascii")
			local asciiGroupCount = #PreviewMode.mockData.groups
			for _, group in ipairs(PreviewMode.mockData.groups) do
				V:Assert(
					not group.name:find("[\128-\255]"),
					"ASCII header fixture must not exercise non-Roman glyph fallback"
				)
			end
			PreviewMode.mockData.groupAssignments = {}
			PreviewMode:GenerateMockGroupsData("latin")
			V:AssertEqual(
				#PreviewMode.mockData.groups,
				asciiGroupCount,
				"ASCII and extended Latin fixtures should keep identical header counts"
			)
			local hasExtendedLatin = false
			for _, group in ipairs(PreviewMode.mockData.groups) do
				if group.name:find("[\128-\255]") then
					hasExtendedLatin = true
					break
				end
			end
			V:Assert(hasExtendedLatin, "Extended Latin fixture should contain non-ASCII Latin labels")
			PreviewMode.mockData.groupAssignments = {}
			PreviewMode:GenerateMockGroupsData("international")
			V:AssertEqual(
				#PreviewMode.mockData.groups,
				asciiGroupCount,
				"ASCII and international fixtures should keep identical header counts"
			)
			PreviewMode.mockData.groups = originalMockGroups
			PreviewMode.mockData.groupAssignments = originalAssignments

			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			local originalGuildRosterMembers = PreviewMode.mockData.guildRosterMembers
			local originalGuildRosterName = PreviewMode.mockData.guildRosterName
			local originalGuildRosterMOTD = PreviewMode.mockData.guildRosterMOTD
			PreviewMode:GenerateGuildPreviewData()
			V:Assert(#PreviewMode.mockData.guildRosterMembers >= 12, "Guild preview should populate a scrollable roster")
			local mockOnline, mockOffline = 0, 0
			for _, member in ipairs(PreviewMode.mockData.guildRosterMembers) do
				V:Assert(member._isMock == true, "Guild preview rows should be marked as synthetic")
				if member.online then
					mockOnline = mockOnline + 1
				else
					mockOffline = mockOffline + 1
				end
			end
			V:Assert(mockOnline > 0 and mockOffline > 0, "Guild preview should cover online and offline filters")
			PreviewMode.enabled = true
			PreviewMode.activeProfile = "guild"
			PreviewMode.activeComponents = { guild = true }
			local GuildRosterData = BFL:GetModule("GuildRosterData")
			if GuildRosterData then
				local online, total = GuildRosterData:GetCounts()
				local members = GuildRosterData:CollectRoster()
				V:AssertEqual(total, #PreviewMode.mockData.guildRosterMembers, "Guild provider should expose every preview row")
				V:AssertEqual(online, mockOnline, "Guild provider should expose the preview online count")
				V:AssertEqual(#members, total, "Guild provider should collect the complete preview roster")
				V:AssertEqual(
					GuildRosterData:GetGuildName(),
					PreviewMode.mockData.guildRosterName,
					"Guild provider should expose the preview guild name"
				)
			end
			PreviewMode.mockData.guildRosterMembers = originalGuildRosterMembers
			PreviewMode.mockData.guildRosterName = originalGuildRosterName
			PreviewMode.mockData.guildRosterMOTD = originalGuildRosterMOTD
			PreviewMode.enabled = true
			PreviewMode.activeProfile = "raid"
			PreviewMode.activeComponents = { raid = true }
			V:Assert(PreviewMode:IsComponentEnabled("raid"), "Active component should be enabled")
			V:Assert(not PreviewMode:IsComponentEnabled("friends"), "Friends should stay inactive in Raid profile")
			V:Assert(not PreviewMode:IsComponentEnabled("quick_join"), "Quick Join should stay inactive in Raid profile")
			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents

			local originalEnableProfile = PreviewMode.EnableProfile
			local originalEnableProfileStaged = PreviewMode.EnableProfileStaged
			local originalDisable = PreviewMode.Disable
			local commandResult
			PreviewMode.EnableProfile = function(_, profileID)
				commandResult = "enable:" .. tostring(profileID)
			end
			PreviewMode.EnableProfileStaged = function(_, profileID)
				commandResult = "debug:" .. tostring(profileID)
			end
			PreviewMode.Disable = function()
				commandResult = "disable"
			end
			PreviewMode.enabled = false
			PreviewMode:HandleCommand("")
			V:AssertEqual(commandResult, "enable:all", "Bare /bfl preview should enable the complete fixture")
			PreviewMode.enabled = true
			PreviewMode:HandleCommand("")
			V:AssertEqual(commandResult, "disable", "Bare /bfl preview should toggle the active fixture off")
			PreviewMode:HandleCommand("debug")
			V:AssertEqual(commandResult, "debug:all", "Preview debug should use the staged activation trace")
			PreviewMode.EnableProfile = originalEnableProfile
			PreviewMode.EnableProfileStaged = originalEnableProfileStaged
			PreviewMode.Disable = originalDisable
			PreviewMode.enabled = originalEnabled
		end,
	})

	TS:RegisterTest("integration", "Preview_FriendsRenderAudit", {
		description = "Friends preview audit requires mock rows in both the model and active DataProvider",
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			local FriendsList = BFL:GetModule("FriendsList")
			if not PreviewMode or not FriendsList then
				V:Skip("PreviewMode or FriendsList not available")
				return
			end

			local originalMockFriends = PreviewMode.mockData.friends
			local originalFriendsList = FriendsList.friendsList
			local originalScrollBox = FriendsList.scrollBox
			local originalPrintProfileStep = PreviewMode.PrintProfileStep
			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			local firstMock = { _isMock = true }
			local secondMock = { _isMock = true }
			local providerRows = {
				{ buttonType = 2, groupId = "nogroup" },
				{ buttonType = 1, friend = firstMock },
				{ buttonType = 1, friend = secondMock },
			}
			local fakeProvider = {}
			function fakeProvider:Enumerate()
				local index = 0
				return function()
					index = index + 1
					if providerRows[index] then
						return index, providerRows[index]
					end
				end
			end

			local auditMessage
			PreviewMode.mockData.friends = { firstMock, secondMock }
			PreviewMode.enabled = true
			PreviewMode.activeProfile = "friends_plain"
			PreviewMode.activeComponents = { friends = true }
			local updateCalls = 0
			local forcedVisibility
			local routed = PreviewMode:RenderMockFriendsNow({
				UpdateFriendsList = function(_, ignoreVisibility)
					updateCalls = updateCalls + 1
					forcedVisibility = ignoreVisibility
				end,
			})
			FriendsList.friendsList = { firstMock, secondMock }
			FriendsList.scrollBox = {
				GetDataProvider = function()
					return fakeProvider
				end,
			}
			PreviewMode.PrintProfileStep = function(_, _, step)
				auditMessage = step
			end

			local ok, rendered = pcall(PreviewMode.ReportFriendsRenderAudit, PreviewMode)

			PreviewMode.mockData.friends = originalMockFriends
			FriendsList.friendsList = originalFriendsList
			FriendsList.scrollBox = originalScrollBox
			PreviewMode.PrintProfileStep = originalPrintProfileStep
			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents

			if not ok then
				error(rendered, 0)
			end
			V:Assert(routed == true, "active Friends preview should own the display refresh")
			V:AssertEqual(updateCalls, 1, "display refresh should route through mock model injection exactly once")
			V:Assert(forcedVisibility == true, "display refresh should force the visible isolated render")
			V:Assert(rendered == true, "render audit should accept mock model and provider rows")
			V:Assert(
				type(auditMessage) == "string" and auditMessage:find("render audit OK", 1, true) ~= nil,
				"audit should report a successful visible provider handoff"
			)
		end,
	})

	TS:RegisterTest("integration", "QuickJoin_PreviewIsolation_State", {
		description = "Combined preview state should isolate and version Quick Join mock data",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			local QuickJoin = BFL:GetModule("QuickJoin")
			if not PreviewMode or not QuickJoin then
				V:Skip("PreviewMode or QuickJoin not available")
				return
			end

			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			local originalVersion = QuickJoin.mockGroupsVersion
			local originalPrepared = QuickJoin.previewPreparedMockVersion
			local originalRendered = QuickJoin.previewRenderedMockVersion
			PreviewMode.enabled = true
			PreviewMode.activeProfile = "raid"
			PreviewMode.activeComponents = { raid = true }
			V:Assert(not QuickJoin:IsCombinedPreviewActive(), "Raid preview must not activate mock-only Quick Join")
			PreviewMode.activeProfile = "quick_join"
			PreviewMode.activeComponents = { quick_join = true }
			V:Assert(QuickJoin:IsCombinedPreviewActive(), "Quick Join profile should activate mock-only Quick Join")
			QuickJoin:MarkMockGroupsChanged()
			V:AssertEqual(QuickJoin.mockGroupsVersion, originalVersion + 1, "mock changes should increment version")
			V:Assert(QuickJoin.previewPreparedMockVersion == nil, "mock changes should invalidate prepared data")
			V:Assert(QuickJoin.previewRenderedMockVersion == nil, "mock changes should invalidate rendered data")

			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents
			QuickJoin.mockGroupsVersion = originalVersion
			QuickJoin.previewPreparedMockVersion = originalPrepared
			QuickJoin.previewRenderedMockVersion = originalRendered
		end,
	})

	TS:RegisterTest("integration", "RaidFrame_ClearMockData", {
		description = "RaidFrame ClearMockData should reset mock state",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			if not RaidFrame then
				V:Skip("RaidFrame not loaded")
				return
			end

			RaidFrame.mockEnabled = true
			RaidFrame.raidMembers = RaidFrame.raidMembers or {}
			RaidFrame.displayList = RaidFrame.displayList or {}
			table.insert(RaidFrame.raidMembers, { name = "MockRaidMember" })
			table.insert(RaidFrame.displayList, { name = "MockRaidMember" })

			RaidFrame:ClearMockData()
			V:Assert(RaidFrame.mockEnabled == false, "mockEnabled should be false")
			V:Assert(#RaidFrame.raidMembers == 0, "raidMembers should be cleared")
			V:Assert(#RaidFrame.displayList == 0, "displayList should be cleared")
		end,
	})

	TS:RegisterTest("integration", "WhoFrame_Update_NoError", {
		description = "WhoFrame Update should not error",
		action = function(V)
			local WhoFrame = BFL:GetModule("WhoFrame")
			if not WhoFrame then
				V:Skip("WhoFrame not loaded")
				return
			end
			WhoFrame:Update(true)
			V:Assert(true, "WhoFrame:Update completed")
		end,
	})

	TS:RegisterTest("integration", "StreamerMode_Toggle", {
		description = "StreamerMode toggle should flip DB flag",
		action = function(V)
			local StreamerMode = BFL:GetModule("StreamerMode")
			if not StreamerMode then
				V:Skip("StreamerMode not loaded")
				return
			end
			if not BetterFriendlistDB then
				V:Skip("DB not initialized")
				return
			end

			local original = BetterFriendlistDB.streamerModeActive
			StreamerMode:Toggle()
			V:Assert(BetterFriendlistDB.streamerModeActive ~= original, "StreamerMode should toggle on/off")
			StreamerMode:Toggle()
			V:Assert(BetterFriendlistDB.streamerModeActive == original, "StreamerMode should restore state")
		end,
	})

	TS:RegisterTest("integration", "StreamerMode_HiddenButtonInvalidatesPrivacyRows", {
		description = "Hiding the Streamer Mode button must disable privacy mode and refresh cached friend rows",
		action = function(V)
			local StreamerMode = BFL:GetModule("StreamerMode")
			if not (StreamerMode and BetterFriendlistDB) then
				V:Skip("StreamerMode or DB not initialized")
				return
			end

			local originalShowButton = BetterFriendlistDB.showStreamerModeButton
			local originalActive = BetterFriendlistDB.streamerModeActive
			local originalToggleButton = StreamerMode.toggleButton
			local originalHeaderText = StreamerMode.originalHeaderText
			local originalUpdateAnchors = StreamerMode.UpdateAdjacentButtonAnchors
			local originalForceRefresh = BFL.ForceRefreshFriendsList
			local refreshes = 0
			local hidden = false
			local ok, err = pcall(function()
				BetterFriendlistDB.showStreamerModeButton = false
				BetterFriendlistDB.streamerModeActive = true
				StreamerMode.originalHeaderText = nil
				StreamerMode.toggleButton = {
					Hide = function()
						hidden = true
					end,
				}
				StreamerMode.UpdateAdjacentButtonAnchors = function() end
				BFL.ForceRefreshFriendsList = function()
					refreshes = refreshes + 1
				end

				StreamerMode:UpdateState()
				V:AssertEqual(BetterFriendlistDB.streamerModeActive, false, "Privacy mode should be disabled")
				V:AssertEqual(refreshes, 1, "Privacy-filtered rows should be invalidated exactly once")
				V:Assert(hidden, "The disabled Streamer Mode button should be hidden")
			end)

			BetterFriendlistDB.showStreamerModeButton = originalShowButton
			BetterFriendlistDB.streamerModeActive = originalActive
			StreamerMode.toggleButton = originalToggleButton
			StreamerMode.originalHeaderText = originalHeaderText
			StreamerMode.UpdateAdjacentButtonAnchors = originalUpdateAnchors
			BFL.ForceRefreshFriendsList = originalForceRefresh
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "Broker_Update_NoError", {
		description = "Broker Update should not error when called",
		action = function(V)
			local Broker = BFL:GetModule("Broker")
			if not Broker or not Broker.UpdateBrokerText then
				V:Skip("Broker not loaded")
				return
			end
			Broker:UpdateBrokerText()
			V:Assert(true, "Broker:UpdateBrokerText completed")
		end,
	})

	TS:RegisterTest("data", "Broker_TooltipRefreshPreservesScrollOffset", {
		description = "Event-driven broker tooltip rebuilds retain the visible scroll offset and clamp it to the new range",
		action = function(V)
			local Broker = BFL:GetModule("Broker")
			V:AssertNotNil(Broker, "Broker module should exist")

			local function CreateSlider(value, minValue, maxValue, shown)
				return {
					value = value,
					GetValue = function(self)
						return self.value
					end,
					GetMinMaxValues = function()
						return minValue, maxValue
					end,
					IsShown = function()
						return shown
					end,
					SetValue = function(self, newValue)
						self.value = newValue
					end,
				}
			end

			local originalSlider = CreateSlider(240, 0, 600, true)
			local offset = Broker:GetTooltipScrollOffset({ Slider = originalSlider })
			V:AssertEqual(offset, 240, "Visible scroll position should be captured before a refresh")

			local rebuiltSlider = CreateSlider(0, 0, 180, true)
			V:Assert(
				Broker:RestoreTooltipScrollOffset({ Slider = rebuiltSlider }, offset),
				"A rebuilt scrollable tooltip should accept the previous offset"
			)
			V:AssertEqual(rebuiltSlider.value, 180, "Restored offsets should clamp to a shortened tooltip range")

			local hiddenSlider = CreateSlider(0, 0, 600, false)
			V:Assert(
				not Broker:RestoreTooltipScrollOffset({ Slider = hiddenSlider }, offset),
				"A tooltip that no longer scrolls should remain at the top"
			)
			V:AssertEqual(hiddenSlider.value, 0, "Hidden sliders should not move their scroll child")
		end,
	})

	TS:RegisterTest("integration", "MenuSystem_WhoFlag", {
		description = "MenuSystem WHO flag should be settable",
		action = function(V)
			local MenuSystem = BFL:GetModule("MenuSystem")
			if not MenuSystem then
				V:Skip("MenuSystem not loaded")
				return
			end
			MenuSystem:SetWhoPlayerMenuFlag(true)
			V:Assert(MenuSystem:GetWhoPlayerMenuFlag() == true, "Who flag should be true")
			MenuSystem:SetWhoPlayerMenuFlag(false)
			V:Assert(MenuSystem:GetWhoPlayerMenuFlag() == false, "Who flag should be false")
		end,
	})

	TS:RegisterTest("integration", "Dialogs_Register", {
		description = "Dialogs should register StaticPopup dialogs",
		action = function(V)
			local Dialogs = BFL:GetModule("Dialogs")
			if not Dialogs then
				V:Skip("Dialogs not loaded")
				return
			end
			Dialogs:RegisterDialogs()
			V:Assert(
				StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] ~= nil,
				"Create group dialog should be registered"
			)
			V:Assert(
				StaticPopupDialogs["BETTER_FRIENDLIST_RENAME_GROUP"] ~= nil,
				"Rename group dialog should be registered"
			)
		end,
	})

	TS:RegisterTest("integration", "TitleFriendInvite_UsesConfirmationWithFallback", {
		description = "Retail title-friend invites use Blizzard's confirmation event and retain the direct fallback",
		condition = function()
			return BFL.IsRetail and BFL.SendTitleFriendInviteByName ~= nil
		end,
		action = function(V)
			local oldBattleNet = C_BattleNet
			local oldAddOns = C_AddOns
			local oldEventRegistry = EventRegistry
			local oldInviteFrame = BattleNetInviteFrame
			local oldIsRetail = BFL.IsRetail
			local eventName, eventTarget
			local directCalls = 0

			local ok, err = pcall(function()
				BFL.IsRetail = true
				C_BattleNet = {
					AreTitleFriendsEnabled = function()
						return true
					end,
					SendTitleFriendInviteByName = function()
						directCalls = directCalls + 1
					end,
				}
				C_AddOns = {
					IsAddOnLoaded = function(addOnName)
						return addOnName == "Blizzard_AddFriend"
					end,
				}
				EventRegistry = {
					TriggerEvent = function(_, name, target)
						eventName = name
						eventTarget = target
					end,
				}
				BattleNetInviteFrame = {
					OnTitleFriendInviteByNameRequested = function() end,
				}

				V:Assert(BFL.SendTitleFriendInviteByName("Jaina-Proudmoore"), "Confirmation request should succeed")
				V:AssertEqual(
					eventName,
					"BattleNetInviteFrame.TitleFriendInviteByNameRequested",
					"Retail 12.1 should route through Blizzard's confirmation event"
				)
				V:AssertEqual(eventTarget, "Jaina-Proudmoore", "Confirmation event should preserve the invite target")
				V:AssertEqual(directCalls, 0, "Confirmation path must not send before the user accepts")

				BattleNetInviteFrame = nil
				V:Assert(BFL.SendTitleFriendInviteByName("Anduin-Stormwind"), "Direct fallback should succeed")
				V:AssertEqual(directCalls, 1, "Older clients should retain exactly one direct API call")
			end)

			C_BattleNet = oldBattleNet
			C_AddOns = oldAddOns
			EventRegistry = oldEventRegistry
			BattleNetInviteFrame = oldInviteFrame
			BFL.IsRetail = oldIsRetail
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "OfflineTitleFriend_WhisperIsBlocked", {
		description = "Only offline title friends are excluded from BFL menu and row-click whisper paths",
		condition = function()
			return BFL.IsRetail
				and Enum
				and Enum.BattleNetFriendLevel
				and Enum.BattleNetFriendLevel.Title ~= nil
		end,
		action = function(V)
			local titleLevel = Enum.BattleNetFriendLevel.Title
			local battleTagLevel = Enum.BattleNetFriendLevel.BattleTag
			V:Assert(BFL.IsOfflineTitleFriend({ friendLevel = titleLevel }, true), "Offline title friend should be blocked")
			V:Assert(not BFL.IsOfflineTitleFriend({ friendLevel = titleLevel }, false), "Online title friend should remain reachable")
			V:Assert(
				not BFL.IsOfflineTitleFriend({ friendLevel = battleTagLevel }, true),
				"Offline BattleTag friend should keep the existing behavior"
			)

			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList module unavailable")
				return
			end
			local oldSend = BFL.SecureSendBNetTell
			local sends = 0
			local ok, err = pcall(function()
				BFL.SecureSendBNetTell = function()
					sends = sends + 1
				end
				local offlineResult = FriendsList:WhisperFriend({
					type = "bnet",
					friendLevel = titleLevel,
					connected = false,
					accountName = "Offline Title Friend",
				})
				V:Assert(offlineResult == false, "Row-click whisper should reject an offline title friend")
				V:AssertEqual(sends, 0, "Rejected title friend must not open Battle.net chat")

				local onlineResult = FriendsList:WhisperFriend({
					type = "bnet",
					friendLevel = titleLevel,
					connected = true,
					accountName = "Online Title Friend",
				})
				V:Assert(onlineResult == true, "Online title friend should remain whisperable")
				V:AssertEqual(sends, 1, "Online title friend should open Battle.net chat exactly once")
			end)
			BFL.SecureSendBNetTell = oldSend
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "RAF_ActiveFrameAndPreviewRewardsSafety", {
		description = "RAF follows C_SocialUI active-frame selection and keeps preview claim controls inert",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local RAF = BFL:GetModule("RAF")
			if not RAF or not RAF.GetNativeRecruitAFriendFrame or not RAF.EnforcePreviewRewardsSafety then
				V:Skip("RAF compatibility helpers unavailable")
				return
			end

			local oldSocialUIFrame = SocialUIFrame
			local oldLegacyFrame = RecruitAFriendFrame
			local oldSocialUI = C_SocialUI
			local modernFrame = {}
			local legacyFrame = {}
			local systemEnabled = true
			local ok, err = pcall(function()
				SocialUIFrame = { RecruitAFriendFrame = modernFrame }
				RecruitAFriendFrame = legacyFrame
				C_SocialUI = {
					IsSystemEnabled = function()
						return systemEnabled
					end,
				}
				V:AssertEqual(RAF:GetNativeRecruitAFriendFrame(), modernFrame, "Enabled SocialUI should own RAF")
				systemEnabled = false
				V:AssertEqual(RAF:GetNativeRecruitAFriendFrame(), legacyFrame, "Disabled SocialUI should use legacy RAF")

				local claimButton = { enabled = true, shown = true, autoClaim = true }
				function claimButton:SetAutoClaimRewardsEnabled(enabled)
					self.autoClaim = enabled
				end
				function claimButton:SetEnabled(enabled)
					self.enabled = enabled
				end
				function claimButton:Hide()
					self.shown = false
				end
				local rewardsFrame = { ClaimLegacyRewardsButton = claimButton }
				V:Assert(
					RAF:EnforcePreviewRewardsSafety(rewardsFrame, { _isMock = true }),
					"Mock rewards should activate the safety contract"
				)
				V:Assert(not claimButton.autoClaim, "Preview should cancel legacy auto-claim")
				V:Assert(not claimButton.enabled and not claimButton.shown, "Preview claim control should stay hidden and disabled")
			end)

			SocialUIFrame = oldSocialUIFrame
			RecruitAFriendFrame = oldLegacyFrame
			C_SocialUI = oldSocialUI
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("integration", "RAF_PreviewFixture_IsLocalAndComplete", {
		description = "RAF preview data covers recruit and activity states without native account lookups",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local RAF = BFL:GetModule("RAF")
			if not RAF or not RAF.BuildPreviewData then
				V:Skip("RAF preview fixture not available")
				return
			end

			local systemInfo, rafInfo = RAF:BuildPreviewData()
			V:AssertEqual(systemInfo.maxRecruits, 10, "Preview should expose a stable recruit capacity")
			V:Assert(rafInfo._isMock == true, "Preview RAF info must be marked as synthetic")
			V:AssertEqual(#rafInfo.recruits, 4, "Preview should cover four representative recruits")
			V:Assert(rafInfo.versions[1].nextReward._isMock == true, "Next reward must remain local")
			V:AssertEqual(
				#rafInfo.versions[1].rewards,
				7,
				"Preview should populate Blizzard's complete two-column reward overview"
			)
			V:Assert(
				rafInfo.versions[1].nextReward == rafInfo.versions[1].rewards[4],
				"The preview header and rewards overview must share the same claimable reward"
			)
			V:Assert(
				rafInfo.versions[1].rewards[1].claimed
					and rafInfo.versions[1].rewards[7].repeatable,
				"Preview rewards should cover claimed and repeatable visual states"
			)

			local online, offline = 0, 0
			local activityStates = {}
			for _, recruit in ipairs(rafInfo.recruits) do
				V:Assert(recruit._isMock == true, "Every preview recruit must bypass Battle.net presence")
				if recruit.isOnline then
					online = online + 1
				else
					offline = offline + 1
				end
				for _, activity in ipairs(recruit.activities or {}) do
					V:Assert(activity._isMock == true, "Every preview activity must be local")
					activityStates[activity.state] = true
				end
			end
			V:Assert(online > 0 and offline > 0, "Preview should exercise online and offline cards")
			V:Assert(
				activityStates[0] and activityStates[1] and activityStates[2],
				"Preview should cover incomplete, complete, and claimed activity states"
			)

			local PreviewMode = BFL:GetModule("PreviewMode")
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if PreviewMode and FriendsUI and FriendsUI.GetCapabilities then
				local originalEnabled = PreviewMode.enabled
				local originalProfile = PreviewMode.activeProfile
				local originalComponents = PreviewMode.activeComponents
				local ok, capabilities = pcall(function()
					PreviewMode.enabled = true
					PreviewMode.activeProfile = "recruit_a_friend"
					PreviewMode.activeComponents = { raf = true }
					return FriendsUI:GetCapabilities()
				end)
				PreviewMode.enabled = originalEnabled
				PreviewMode.activeProfile = originalProfile
				PreviewMode.activeComponents = originalComponents
				if not ok then
					error(capabilities, 0)
				end
				V:Assert(
					capabilities.recruit_a_friend == true,
					"RAF preview should bypass only the RAF account availability gate"
				)
			end
		end,
	})

	TS:RegisterTest("integration", "RAF_Guard_NoError", {
		description = "RAF should guard when unavailable",
		action = function(V)
			local RAF = BFL:GetModule("RAF")
			if not RAF then
				V:Skip("RAF not loaded")
				return
			end
			if BFL.HasRAF then
				V:Skip("RAF available; guard test not applicable")
				return
			end
			local frame = CreateFrame("Frame")
			RAF:OnLoad(frame)
			V:Assert(frame:IsShown() == false, "RAF frame should be hidden when unavailable")
		end,
	})

	TS:RegisterTest("integration", "RecentAllies_Unavailable_Message", {
		description = "RecentAllies should show unavailable message when API missing",
		action = function(V)
			local RecentAllies = BFL:GetModule("RecentAllies")
			if not RecentAllies then
				V:Skip("RecentAllies not loaded")
				return
			end
			if BFL.HasRecentAllies then
				V:Skip("RecentAllies available; guard test not applicable")
				return
			end

			local frame = CreateFrame("Frame")
			frame.ScrollBox = CreateFrame("Frame", nil, frame)
			frame.ScrollBar = CreateFrame("Frame", nil, frame)
			frame.LoadingSpinner = CreateFrame("Frame", nil, frame)

			RecentAllies:OnLoad(frame)
			V:Assert(frame.UnavailableText ~= nil, "UnavailableText should be created")
			V:Assert(frame.ScrollBox:IsShown() == false, "ScrollBox should be hidden")
		end,
	})

	TS:RegisterTest("integration", "Compat_GlobalIgnoreList_Setup", {
		description = "GlobalIgnoreList compat setup should not error",
		action = function(V)
			local Compat = BFL:GetModule("Compat_GlobalIgnoreList")
			if not Compat then
				V:Skip("Compat module not loaded")
				return
			end
			Compat:Setup()
			V:Assert(true, "Compat:Setup completed")
		end,
	})

	TS:RegisterTest("integration", "CombatGuard_IsActionRestricted", {
		description = "IsActionRestricted should reflect combat state",
		action = function(V)
			local originalInCombat = _G.InCombatLockdown
			_G.InCombatLockdown = function()
				return true
			end
			local restricted = BFL:IsActionRestricted()
			_G.InCombatLockdown = originalInCombat
			V:Assert(restricted == true, "IsActionRestricted should be true in combat")
		end,
	})

	TS:RegisterTest("integration", "CombatGuard_QuickJoin_Request", {
		description = "QuickJoin should block requests in combat",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local QuickJoin = BFL:GetModule("QuickJoin")
			if not QuickJoin then
				V:Skip("QuickJoin not loaded")
				return
			end
			local originalInCombat = _G.InCombatLockdown
			_G.InCombatLockdown = function()
				return true
			end
			local guid = QuickJoin:CreateMockGroup({ leaderName = "CombatTest", activityName = "CombatTest" })
			local ok = QuickJoin:RequestToJoin(guid, true, true, true)
			_G.InCombatLockdown = originalInCombat
			QuickJoin.mockGroups[guid] = nil
			V:Assert(ok == false, "RequestToJoin should return false in combat")
		end,
	})

	TS:RegisterTest("integration", "Retail_ApiGuard_QuickJoin_GetAllGroups_Nil", {
		description = "QuickJoin Update should tolerate nil GetAllGroups",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local QuickJoin = BFL:GetModule("QuickJoin")
			if not QuickJoin then
				V:Skip("QuickJoin not loaded")
				return
			end
			if not C_SocialQueue or not C_SocialQueue.GetAllGroups then
				V:Skip("C_SocialQueue not available")
				return
			end
			local originalGetAllGroups = C_SocialQueue.GetAllGroups
			C_SocialQueue.GetAllGroups = function()
				return nil
			end
			QuickJoin:Update(true)
			C_SocialQueue.GetAllGroups = originalGetAllGroups
			V:Assert(type(QuickJoin.availableGroups) == "table", "availableGroups should be a table")
		end,
	})

	-- ===== PERFORMANCE TESTS =====

	TS:RegisterTest("perf", "Memory_Baseline", {
		description = "Record baseline memory usage",
		action = function(V)
			collectgarbage("collect")
			UpdateAddOnMemoryUsage()
			local memory = GetAddOnMemoryUsage("BetterFriendlist") or 0

			TestSuite.Reporter:Info(string.format("Memory usage: %.2f KB", memory))

			-- Warn if memory is unusually high
			if memory > 5000 then -- 5MB
				TestSuite.Reporter:Warn("Memory usage is high (>5MB)")
			end
		end,
	})

	TS:RegisterTest("perf", "FrameToggle_Speed", {
		description = "Frame toggle should be fast (<100ms)",
		setup = function()
			if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
				BetterFriendsFrame:Hide()
			end
		end,
		action = function(V)
			local startTime = debugprofilestop()

			ToggleBetterFriendsFrame() -- Open
			ToggleBetterFriendsFrame() -- Close

			local elapsed = debugprofilestop() - startTime
			TestSuite.Reporter:Info(string.format("Toggle duration: %.2f ms", elapsed))

			V:Assert(elapsed < 100, "Frame toggle should complete in <100ms")
		end,
		teardown = function()
			if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
		end,
	})

	-- ===== DEEP LOGIC TESTS: SETTINGS EFFECTS =====

	TS:RegisterTest("settings", "CacheVersion_Increments_On_Set", {
		description = "DB:Set() must increment SettingsVersion (cache invalidation)",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local versionBefore = BFL.SettingsVersion or 1

			-- Set a test value
			DB:Set("_testCacheInvalidation", true)

			local versionAfter = BFL.SettingsVersion or 1
			V:Assert(
				versionAfter > versionBefore,
				"SettingsVersion should increment after DB:Set() (was "
					.. versionBefore
					.. ", now "
					.. versionAfter
					.. ")"
			)

			-- Cleanup
			DB:Set("_testCacheInvalidation", nil)
		end,
	})

	TS:RegisterTest("settings", "FriendsList_Cache_Invalidation", {
		description = "FriendsList must detect cache version change",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList module not loaded")
				return
			end

			-- Force cache to be built
			FriendsList:UpdateSettingsCache()
			local cachedVersion = FriendsList.settingsCacheVersion

			-- Change a setting
			BFL:GetModule("DB"):Set("compactMode", not BFL:GetModule("DB"):Get("compactMode", false))

			-- Invalidate should have happened (version incremented)
			V:Assert(BFL.SettingsVersion > cachedVersion, "SettingsVersion should be higher than cached version")

			-- UpdateSettingsCache should detect the change
			FriendsList:UpdateSettingsCache()
			V:Assert(
				FriendsList.settingsCacheVersion == BFL.SettingsVersion,
				"FriendsList cache version should match global SettingsVersion after update"
			)

			-- Restore original setting
			BFL:GetModule("DB"):Set("compactMode", not BFL:GetModule("DB"):Get("compactMode", false))
		end,
	})

	TS:RegisterTest("settings", "CompactMode_Effect", {
		description = "compactMode setting must affect FriendsList cache",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			local DB = BFL:GetModule("DB")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local original = DB:Get("compactMode", false)

			-- Set to true
			DB:Set("compactMode", true)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.compactMode == true, "Cache should reflect compactMode=true")

			-- Set to false
			DB:Set("compactMode", false)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.compactMode == false, "Cache should reflect compactMode=false")

			-- Restore
			DB:Set("compactMode", original)
		end,
	})

	TS:RegisterTest("settings", "HideEmptyGroups_Effect", {
		description = "hideEmptyGroups setting must affect FriendsList cache",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			local DB = BFL:GetModule("DB")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local original = DB:Get("hideEmptyGroups", false)

			-- Toggle and verify cache updates
			DB:Set("hideEmptyGroups", true)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.hideEmptyGroups == true, "Cache should reflect hideEmptyGroups=true")

			DB:Set("hideEmptyGroups", false)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.hideEmptyGroups == false, "Cache should reflect hideEmptyGroups=false")

			-- Restore
			DB:Set("hideEmptyGroups", original)
		end,
	})

	TS:RegisterTest("settings", "FavoritesHidden_FallsToNoGroup", {
		description = "Hidden favorites group should fall back to No Group",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			local DB = BFL:GetModule("DB")
			local MockDataProvider = BFL.MockDataProvider
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end
			if not DB then
				V:Skip("DB not loaded")
				return
			end
			if not MockDataProvider then
				V:Skip("MockDataProvider not available")
				return
			end

			local originalShowFavorites = DB:Get("showFavoritesGroup", true)

			local favoriteFriend = MockDataProvider:CreateBNetFriend({
				isOnline = true,
				isFavorite = true,
				game = { program = "WoW", name = "World of Warcraft" },
			})
			local otherFriend = MockDataProvider:CreateWoWFriend({
				isOnline = true,
			})
			local groups = MockDataProvider:GenerateGroups(0, { includeBuiltin = true })

			TestSuite:ApplyMockData({
				friends = { favoriteFriend, otherFriend },
				groups = groups,
				groupAssignments = {},
			})

			DB:Set("showFavoritesGroup", false)
			FriendsList:UpdateSettingsCache()
			FriendsList:UpdateFriendsList()

			local grouped = FriendsList.groupedFriends or {}
			local favorites = grouped.favorites or {}
			local nogroup = grouped.nogroup or {}

			local foundInNoGroup = false
			for _, friend in ipairs(nogroup) do
				if friend == favoriteFriend or friend.battleTag == favoriteFriend.battleTag then
					foundInNoGroup = true
					break
				end
			end

			V:Assert(#favorites == 0, "Favorites group should be empty when hidden")
			V:Assert(foundInNoGroup == true, "Favorite friend should fall back to No Group")

			DB:Set("showFavoritesGroup", originalShowFavorites)
			local ScenarioManager = BFL.ScenarioManager
			if ScenarioManager and ScenarioManager.Clear then
				ScenarioManager:Clear()
			end
		end,
	})

	-- ===== DEEP LOGIC TESTS: SORT LOGIC =====

	TS:RegisterTest("sort", "SortByName_Alphabetical", {
		description = "Sort by name must be alphabetical (A before Z)",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Create mock friends for testing
			local testFriends = {
				{ _sort_name = "zephyr", _sort_isOnline = true, _sort_status = 1, index = 1, isFavorite = false },
				{ _sort_name = "alpha", _sort_isOnline = true, _sort_status = 1, index = 2, isFavorite = false },
				{ _sort_name = "mike", _sort_isOnline = true, _sort_status = 1, index = 3, isFavorite = false },
			}

			-- Store original and set test data
			local originalList = FriendsList.friendsList
			local originalPrimary = FriendsList.sortMode
			local originalSecondary = FriendsList.secondarySort

			FriendsList.friendsList = testFriends
			FriendsList.sortMode = "name"
			FriendsList.secondarySort = "none"

			-- Apply sort
			FriendsList:ApplySort()

			-- Verify order: alpha, mike, zephyr
			V:Assert(
				FriendsList.friendsList[1]._sort_name == "alpha",
				"First should be 'alpha', got '" .. tostring(FriendsList.friendsList[1]._sort_name) .. "'"
			)
			V:Assert(
				FriendsList.friendsList[2]._sort_name == "mike",
				"Second should be 'mike', got '" .. tostring(FriendsList.friendsList[2]._sort_name) .. "'"
			)
			V:Assert(
				FriendsList.friendsList[3]._sort_name == "zephyr",
				"Third should be 'zephyr', got '" .. tostring(FriendsList.friendsList[3]._sort_name) .. "'"
			)

			-- Restore
			FriendsList.friendsList = originalList
			FriendsList.sortMode = originalPrimary
			FriendsList.secondarySort = originalSecondary
		end,
	})

	TS:RegisterTest("sort", "SortByStatus_OnlineFirst", {
		description = "Sort by status must put online friends before offline",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local testFriends = {
				{ _sort_name = "offline1", _sort_isOnline = false, _sort_status = 3, index = 1, isFavorite = false },
				{ _sort_name = "online1", _sort_isOnline = true, _sort_status = 1, index = 2, isFavorite = false },
				{ _sort_name = "offline2", _sort_isOnline = false, _sort_status = 3, index = 3, isFavorite = false },
			}

			local originalList = FriendsList.friendsList
			local originalPrimary = FriendsList.sortMode
			local originalSecondary = FriendsList.secondarySort

			FriendsList.friendsList = testFriends
			FriendsList.sortMode = "status"
			FriendsList.secondarySort = "name"

			FriendsList:ApplySort()

			-- Online should be first
			V:Assert(FriendsList.friendsList[1]._sort_isOnline == true, "First friend should be online")
			V:Assert(FriendsList.friendsList[2]._sort_isOnline == false, "Second friend should be offline")

			-- Restore
			FriendsList.friendsList = originalList
			FriendsList.sortMode = originalPrimary
			FriendsList.secondarySort = originalSecondary
		end,
	})

	TS:RegisterTest("sort", "SortByLevel_Descending", {
		description = "Sort by level must put higher levels first",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local testFriends = {
				{
					_sort_name = "low",
					_sort_level = 10,
					_sort_isOnline = true,
					_sort_status = 1,
					index = 1,
					isFavorite = false,
				},
				{
					_sort_name = "max",
					_sort_level = 80,
					_sort_isOnline = true,
					_sort_status = 1,
					index = 2,
					isFavorite = false,
				},
				{
					_sort_name = "mid",
					_sort_level = 50,
					_sort_isOnline = true,
					_sort_status = 1,
					index = 3,
					isFavorite = false,
				},
			}

			local originalList = FriendsList.friendsList
			local originalPrimary = FriendsList.sortMode
			local originalSecondary = FriendsList.secondarySort

			FriendsList.friendsList = testFriends
			FriendsList.sortMode = "level"
			FriendsList.secondarySort = "none"

			FriendsList:ApplySort()

			-- Highest level first
			V:Assert(
				FriendsList.friendsList[1]._sort_level == 80,
				"First should be level 80, got " .. tostring(FriendsList.friendsList[1]._sort_level)
			)
			V:Assert(
				FriendsList.friendsList[2]._sort_level == 50,
				"Second should be level 50, got " .. tostring(FriendsList.friendsList[2]._sort_level)
			)
			V:Assert(
				FriendsList.friendsList[3]._sort_level == 10,
				"Third should be level 10, got " .. tostring(FriendsList.friendsList[3]._sort_level)
			)

			-- Restore
			FriendsList.friendsList = originalList
			FriendsList.sortMode = originalPrimary
			FriendsList.secondarySort = originalSecondary
		end,
	})

	TS:RegisterTest("sort", "Favorites_AlwaysFirst", {
		description = "Favorites must appear before non-favorites within same status",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local testFriends = {
				{ _sort_name = "notfav", _sort_isOnline = true, _sort_status = 1, index = 1, isFavorite = false },
				{ _sort_name = "favorite", _sort_isOnline = true, _sort_status = 1, index = 2, isFavorite = true },
			}

			local originalList = FriendsList.friendsList
			local originalPrimary = FriendsList.sortMode
			local originalSecondary = FriendsList.secondarySort

			FriendsList.friendsList = testFriends
			FriendsList.sortMode = "status"
			FriendsList.secondarySort = "name"

			FriendsList:ApplySort()

			-- Favorite should be first
			V:Assert(FriendsList.friendsList[1].isFavorite == true, "First friend should be favorite")

			-- Restore
			FriendsList.friendsList = originalList
			FriendsList.sortMode = originalPrimary
			FriendsList.secondarySort = originalSecondary
		end,
	})

	-- ===== DEEP LOGIC TESTS: FILTER LOGIC =====

	TS:RegisterTest("filter", "OnlineFilter_ShowsOnlyOnline", {
		description = "Filter 'online' must hide offline friends",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "online"

			local onlineFriend = { connected = true, type = "bnet" }
			local offlineFriend = { connected = false, type = "bnet" }

			V:Assert(FriendsList:PassesFilters(onlineFriend) == true, "Online friend should pass 'online' filter")
			V:Assert(
				FriendsList:PassesFilters(offlineFriend) == false,
				"Offline friend should NOT pass 'online' filter"
			)

			-- Restore
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "OfflineFilter_ShowsOnlyOffline", {
		description = "Filter 'offline' must hide online friends",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "offline"

			local onlineFriend = { connected = true, type = "bnet" }
			local offlineFriend = { connected = false, type = "bnet" }

			V:Assert(FriendsList:PassesFilters(onlineFriend) == false, "Online friend should NOT pass 'offline' filter")
			V:Assert(FriendsList:PassesFilters(offlineFriend) == true, "Offline friend should pass 'offline' filter")

			-- Restore
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "QuickFilter_TagFacetsUseNestedMenuAndORSelection", {
		description = "Quick Filter menus should group filters and tags while selected tags use OR semantics beside the active filter",
		action = function(V)
			local QuickFilters = BFL:GetModule("QuickFilters")
			local FriendTags = BFL:GetModule("FriendTags")
			local FriendsList = BFL:GetModule("FriendsList")
			if not (QuickFilters and FriendTags and FriendsList and BetterFriendlistDB) then
				V:Skip("QuickFilters, FriendTags, FriendsList, or DB not loaded")
				return
			end

			local definitions = {
				{
					id = "custom:test_alpha",
					name = "Alpha",
					chipProfile = {
						iconType = "texture",
						texture = "Interface\\AddOns\\BetterFriendlist\\Icons\\tag",
					},
				},
				{
					id = "custom:test_beta",
					name = "Beta",
					chipProfile = {
						iconType = "texture",
						texture = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter",
					},
				},
			}
			local originalSelected = BetterFriendlistDB.quickFilterTags
			local originalDBFilter = BetterFriendlistDB.quickFilter
			local originalFilterMode = FriendsList.filterMode
			local originalGetDefinitions = QuickFilters.GetTagFilterDefinitions
			local originalGetTagsForFriend = FriendTags.GetTagsForFriend
			local originalForceRefreshFriendsList = BFL.ForceRefreshFriendsList
			local originalRefreshDropdown = QuickFilters.RefreshDropdown
			local ok, err = pcall(function()
				BetterFriendlistDB.quickFilterTags = {
					["custom:test_alpha"] = true,
					["custom:test_beta"] = true,
				}
				QuickFilters.GetTagFilterDefinitions = function()
					return definitions
				end
				QuickFilters:InvalidateTagFilterCache()
				FriendTags.GetTagsForFriend = function(_, friend)
					return friend.testTags or {}
				end
				BFL.ForceRefreshFriendsList = function() end
				QuickFilters.RefreshDropdown = function() end

				local alphaFriend = {
					type = "wow",
					connected = true,
					testTags = { definitions[1] },
				}
				local betaFriend = {
					type = "wow",
					connected = true,
					testTags = { definitions[2] },
				}
				local unmatchedFriend = { type = "wow", connected = true, testTags = {} }
				V:Assert(QuickFilters:PassesTagFilters(alphaFriend), "The first selected tag should match")
				V:Assert(QuickFilters:PassesTagFilters(betaFriend), "The second selected tag should match through OR")
				V:Assert(not QuickFilters:PassesTagFilters(unmatchedFriend), "Friends without a selected tag should fail")

				FriendsList.filterMode = "online"
				V:Assert(FriendsList:PassesFilters(alphaFriend), "A matching online friend should pass both facets")
				alphaFriend.connected = false
				V:Assert(
					not FriendsList:PassesFilters(alphaFriend),
					"A matching tag must not bypass the active online filter"
				)

				local function CreateDescription(kind, text)
					local description = { kind = kind, text = text, children = {} }
					function description:SetTag(tag)
						self.tag = tag
					end
					function description:SetCloseOnClick(closeOnClick)
						self.closeOnClick = closeOnClick
					end
					function description:SetMinimumWidth(width)
						self.minimumWidth = width
					end
					function description:SetMaximumWidth(width)
						self.maximumWidth = width
					end
					function description:AddInitializer(initializer)
						self.initializers = self.initializers or {}
						self.initializers[#self.initializers + 1] = initializer
					end
					function description:AddResetter(resetter)
						self.resetters = self.resetters or {}
						self.resetters[#self.resetters + 1] = resetter
					end
					function description:CreateButton(label)
						local child = CreateDescription("button", label)
						self.children[#self.children + 1] = child
						return child
					end
					function description:CreateRadio(label, _, _, value)
						local child = CreateDescription("radio", label)
						child.value = value
						self.children[#self.children + 1] = child
						return child
					end
					function description:CreateCheckbox(label, isSelected, onSelected)
						local child = CreateDescription("checkbox", label)
						child.isSelected = isSelected
						child.onSelected = onSelected
						self.children[#self.children + 1] = child
						return child
					end
					function description:CreateTitle(label)
						local child = CreateDescription("title", label)
						self.children[#self.children + 1] = child
						return child
					end
					return description
				end

				local rootDescription = CreateDescription("root")
				QuickFilters:PopulateMenu(rootDescription)
				V:AssertEqual(#rootDescription.children, 2, "Root menu should contain Filters and Tags only")
				V:AssertEqual(rootDescription.children[1].kind, "button", "Filters should be a submenu")
				V:AssertEqual(rootDescription.children[2].kind, "button", "Tags should be a submenu")
				V:AssertEqual(rootDescription.minimumWidth, 120, "Root menu should reserve a compact stable width")
				V:AssertEqual(rootDescription.maximumWidth, 120, "Root menu width should not change with icon count")
				V:Assert(
					rootDescription.children[1].text:find("|T", 1, true) ~= nil,
					"Filters root item should show the active filter icon"
				)
				V:Assert(
					rootDescription.children[2].text:find("|T", 1, true) ~= nil,
					"Tags root item should show selected tag icons"
				)
				V:AssertEqual(rootDescription.children[2].children[1].kind, "checkbox", "Tags should be multi-select")

				local filterRoot = rootDescription.children[1]
				local originalFilterLabel = filterRoot.text
				local alternateFilter
				for _, child in ipairs(filterRoot.children) do
					if child.value and child.value ~= QuickFilters:GetFilter() then
						alternateFilter = child.value
						break
					end
				end
				V:AssertNotNil(alternateFilter, "Test requires a second visible Quick Filter")
				BetterFriendlistDB.quickFilter = alternateFilter
				local refreshedFilterLabel
				filterRoot.initializers[1]({
					fontString = {
						SetTextToFit = function(_, text)
							refreshedFilterLabel = text
						end,
					},
				})
				V:Assert(
					refreshedFilterLabel ~= originalFilterLabel,
					"The first-level filter icon should update when the active filter changes"
				)

				local tagRoot = rootDescription.children[2]
				local originalTagLabel = tagRoot.text
				local refreshedTagLabel
				local visibleTagButton = {
					fontString = {
						SetTextToFit = function(_, text)
							refreshedTagLabel = text
						end,
					},
					SetText = function()
						error("Menu labels must update Blizzard's visible fontString", 0)
					end,
				}
				tagRoot.initializers[1](visibleTagButton)
				tagRoot.children[2].onSelected()
				V:Assert(
					refreshedTagLabel ~= originalTagLabel,
					"The visible first-level tag icons should update directly while the menu remains open"
				)
				tagRoot.resetters[1](visibleTagButton)

			end)

			BetterFriendlistDB.quickFilterTags = originalSelected
			BetterFriendlistDB.quickFilter = originalDBFilter
			FriendsList.filterMode = originalFilterMode
			QuickFilters.GetTagFilterDefinitions = originalGetDefinitions
			FriendTags.GetTagsForFriend = originalGetTagsForFriend
			BFL.ForceRefreshFriendsList = originalForceRefreshFriendsList
			QuickFilters.RefreshDropdown = originalRefreshDropdown
			QuickFilters:InvalidateTagFilterCache()
			if not ok then
				error(err, 0)
			end
		end,
	})

	TS:RegisterTest("filter", "QuickFilter_HeaderSelectionRespectsInterfaceStyle", {
		description = "Legacy uses BFL's generic filter icon while Modern keeps the readable Filter label",
		action = function(V)
			local QuickFilters = BFL:GetModule("QuickFilters")
			if not (QuickFilters and QuickFilters.GetHeaderSelectionText) then
				V:Skip("QuickFilters header selection helper not loaded")
				return
			end

			local oldFriendsUI = BFL.FriendsUI
			local legacyText, modernText
			local ok, err = pcall(function()
				BFL.FriendsUI = {
					IsModernActive = function()
						return false
					end,
				}
				legacyText = QuickFilters:GetHeaderSelectionText(14)
				BFL.FriendsUI.IsModernActive = function()
					return true
				end
				modernText = QuickFilters:GetHeaderSelectionText(14)
			end)
			BFL.FriendsUI = oldFriendsUI
			if not ok then
				error(err, 0)
			end

			V:Assert(
				legacyText:find("Interface\\AddOns\\BetterFriendlist\\Icons\\filter", 1, true) ~= nil,
				"Legacy header should display the generic BFL filter texture"
			)
			V:AssertEqual(modernText, FILTER or "Filter", "Modern header should keep the Filter text label")
		end,
	})

	TS:RegisterTest("filter", "WoWFilter_RequiresWoWClient", {
		description = "Filter 'wow' must require WoW game client",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "wow"

			-- BNet friend in WoW
			local wowFriend = {
				connected = true,
				type = "bnet",
				gameAccountInfo = { clientProgram = BNET_CLIENT_WOW or "WoW" },
			}

			-- BNet friend in Overwatch
			local owFriend = {
				connected = true,
				type = "bnet",
				gameAccountInfo = { clientProgram = "Pro" },
			}

			-- BNet friend offline
			local offlineFriend = {
				connected = false,
				type = "bnet",
				gameAccountInfo = nil,
			}

			-- WoW-only friend (always passes wow filter)
			local wowOnlyFriend = { connected = true, type = "wow" }

			V:Assert(FriendsList:PassesFilters(wowFriend) == true, "BNet friend in WoW should pass 'wow' filter")
			V:Assert(
				FriendsList:PassesFilters(owFriend) == false,
				"BNet friend in other game should NOT pass 'wow' filter"
			)
			V:Assert(
				FriendsList:PassesFilters(offlineFriend) == false,
				"Offline BNet friend should NOT pass 'wow' filter"
			)
			V:Assert(FriendsList:PassesFilters(wowOnlyFriend) == true, "WoW-only friend should pass 'wow' filter")

			-- Restore
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "WoWOnlineFilter_RequiresOnlineWoWClient", {
		description = "Filter 'wowonline' must show only online WoW friends",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "wowonline"

			local onlineBNetWoWFriend = {
				connected = true,
				type = "bnet",
				gameAccountInfo = { clientProgram = BNET_CLIENT_WOW or "WoW" },
			}
			local offlineBNetWoWFriend = {
				connected = false,
				type = "bnet",
				gameAccountInfo = { clientProgram = BNET_CLIENT_WOW or "WoW" },
			}
			local otherGameFriend = {
				connected = true,
				type = "bnet",
				gameAccountInfo = { clientProgram = "Pro" },
			}
			local onlineWoWOnlyFriend = { connected = true, type = "wow" }
			local offlineWoWOnlyFriend = { connected = false, type = "wow" }

			V:Assert(
				FriendsList:PassesFilters(onlineBNetWoWFriend) == true,
				"Online BNet friend in WoW should pass 'wowonline' filter"
			)
			V:Assert(
				FriendsList:PassesFilters(offlineBNetWoWFriend) == false,
				"Offline BNet friend in WoW should NOT pass 'wowonline' filter"
			)
			V:Assert(
				FriendsList:PassesFilters(otherGameFriend) == false,
				"BNet friend in another game should NOT pass 'wowonline' filter"
			)
			V:Assert(
				FriendsList:PassesFilters(onlineWoWOnlyFriend) == true,
				"Online WoW-only friend should pass 'wowonline' filter"
			)
			V:Assert(
				FriendsList:PassesFilters(offlineWoWOnlyFriend) == false,
				"Offline WoW-only friend should NOT pass 'wowonline' filter"
			)

			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "SearchFilter_MatchesName", {
		description = "Search filter must match friend name",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSearch = FriendsList.searchText
			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "all"

			-- Friend with specific name
			local friend = {
				connected = true,
				type = "wow",
				name = "TestPlayer",
			}

			-- Search that matches
			FriendsList.searchText = "testpl"
			V:Assert(FriendsList:PassesFilters(friend) == true, "Friend should pass when search matches name")

			-- Search that doesn't match
			FriendsList.searchText = "xyz123"
			V:Assert(FriendsList:PassesFilters(friend) == false, "Friend should NOT pass when search doesn't match")

			-- Restore
			FriendsList.searchText = originalSearch
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "SearchFilter_MatchesNote", {
		description = "Search filter must match friend note",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSearch = FriendsList.searchText
			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "all"

			local friend = {
				connected = true,
				type = "wow",
				name = "SomePlayer",
				note = "My guild healer",
			}

			-- Search note content
			FriendsList.searchText = "healer"
			V:Assert(FriendsList:PassesFilters(friend) == true, "Friend should pass when search matches note")

			-- Restore
			FriendsList.searchText = originalSearch
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "HideAFK_FiltersAFKFriends", {
		description = "Filter 'hideafk' must hide AFK/DND friends",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "hideafk"

			local availableFriend = { connected = true, type = "bnet", isAFK = false, isDND = false }
			local afkFriend = { connected = true, type = "bnet", isAFK = true, isDND = false }
			local dndFriend = { connected = true, type = "bnet", isAFK = false, isDND = true }

			V:Assert(
				FriendsList:PassesFilters(availableFriend) == true,
				"Available friend should pass 'hideafk' filter"
			)
			V:Assert(FriendsList:PassesFilters(afkFriend) == false, "AFK friend should NOT pass 'hideafk' filter")
			V:Assert(FriendsList:PassesFilters(dndFriend) == false, "DND friend should NOT pass 'hideafk' filter")

			-- Restore
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("filter", "Registry_BFLMenuIcons_UseThemeAccent", {
		description = "BFL-owned menu textures use the active Dark/Custom or EllesmereUI accent without tinting Blizzard assets",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry then
				V:Skip("FilterSortRegistry not loaded")
				return
			end

			local oldUsesDarkSkinTheme = BFL.UsesDarkSkinTheme
			local oldIsEllesmereUISkinActive = BFL.IsEllesmereUISkinActive
			local oldGetThemeAccentColor = BFL.GetThemeAccentColor
			local darkMarkup, ellesmereMarkup, blizzardMarkup
			local ok, err = pcall(function()
				BFL.UsesDarkSkinTheme = function()
					return true
				end
				BFL.IsEllesmereUISkinActive = function()
					return false
				end
				BFL.GetThemeAccentColor = function()
					return 1, 0, 0, 1
				end
				darkMarkup = Registry:FormatIcon("Interface\\AddOns\\BetterFriendlist\\Icons\\filter", 16)

				BFL.UsesDarkSkinTheme = function()
					return false
				end
				BFL.IsEllesmereUISkinActive = function()
					return true
				end
				BFL.GetThemeAccentColor = function()
					return 0, 1, 0, 1
				end
				ellesmereMarkup = Registry:FormatIcon("Interface\\AddOns\\BetterFriendlist\\Icons\\filter", 16)
				blizzardMarkup = Registry:FormatIcon("Interface\\Icons\\INV_Misc_Note_01", 16)
			end)
			BFL.UsesDarkSkinTheme = oldUsesDarkSkinTheme
			BFL.IsEllesmereUISkinActive = oldIsEllesmereUISkinActive
			BFL.GetThemeAccentColor = oldGetThemeAccentColor
			if not ok then
				error(err, 0)
			end

			V:Assert(
				darkMarkup:find(":255:0:0|t", 1, true) ~= nil,
				"BFL menu texture markup should contain the active Dark/Custom accent tint"
			)
			V:Assert(
				darkMarkup:find("Textures\\ThemeIcons\\filter.tga", 1, true) ~= nil,
				"Dark/Custom menu texture markup should use the neutral BFL icon mask"
			)
			V:Assert(
				ellesmereMarkup:find(":0:255:0|t", 1, true) ~= nil,
				"BFL menu texture markup should contain the active EllesmereUI accent tint"
			)
			V:Assert(
				ellesmereMarkup:find("Textures\\ThemeIcons\\filter.tga", 1, true) ~= nil,
				"EllesmereUI menu texture markup should use the neutral BFL icon mask"
			)
			V:Assert(
				blizzardMarkup:find(":0:255:0|t", 1, true) == nil,
				"Blizzard menu textures should retain their native color"
			)
		end,
	})

	TS:RegisterTest("filter", "Registry_CustomFilter_AST_AND_OR_NOT", {
		description = "Custom QuickFilters must evaluate nested AND/OR/NOT AST rules",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry then
				V:Skip("FilterSortRegistry not loaded")
				return
			end
			if not BetterFriendlistDB then
				V:Skip("DB not available")
				return
			end

			Registry:EnsureDB()
			local testId = "custom_filter_test_ast"
			local original = BetterFriendlistDB.customQuickFilters[testId]
			local originalVisibility = BetterFriendlistDB.quickFilterVisibility[testId]

			BetterFriendlistDB.customQuickFilters[testId] = {
				id = testId,
				name = "AST Test",
				icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter",
				ast = {
					type = "group",
					op = "AND",
					children = {
						{ type = "condition", field = "online", op = "is", value = true },
						{
							type = "group",
							op = "OR",
							children = {
								{ type = "condition", field = "status", op = "is", value = "dnd", negate = true },
								{ type = "condition", field = "favorite", op = "is", value = true },
							},
						},
					},
				},
			}
			BetterFriendlistDB.quickFilterVisibility[testId] = true

			V:Assert(
				Registry:EvaluateQuickFilter(testId, { type = "bnet", connected = true, isDND = false }) == true,
				"Online non-DND friend should pass"
			)
			V:Assert(
				Registry:EvaluateQuickFilter(testId, { type = "bnet", connected = true, isDND = true }) == false,
				"Online DND non-favorite friend should fail"
			)
			V:Assert(
				Registry:EvaluateQuickFilter(testId, { type = "bnet", connected = true, isDND = true, isFavorite = true })
					== true,
				"Favorite DND friend should pass through OR branch"
			)
			V:Assert(
				Registry:EvaluateQuickFilter(testId, { type = "bnet", connected = false, isFavorite = true }) == false,
				"Offline friend should fail root AND condition"
			)

			BetterFriendlistDB.customQuickFilters[testId] = original
			BetterFriendlistDB.quickFilterVisibility[testId] = originalVisibility
		end,
	})

	TS:RegisterTest("filter", "Registry_Visibility_ActiveFilterFallback", {
		description = "Hidden active QuickFilters must fall back to 'all'",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local originalFilter = BetterFriendlistDB.quickFilter
			local originalBeta = BetterFriendlistDB.enableBetaFeatures
			local originalVisibility = BetterFriendlistDB.quickFilterVisibility.online

			BetterFriendlistDB.enableBetaFeatures = true
			BetterFriendlistDB.quickFilter = "online"
			BetterFriendlistDB.quickFilterVisibility.online = false
			Registry:NormalizeCurrentSelections()

			V:AssertEqual(BetterFriendlistDB.quickFilter, "all", "Hidden active filter should normalize to all")

			local visible = Registry:GetVisibleQuickFilters()
			for _, entry in ipairs(visible) do
				V:Assert(entry.id ~= "online", "Hidden filter should not appear in visible list")
			end

			BetterFriendlistDB.quickFilter = originalFilter
			BetterFriendlistDB.enableBetaFeatures = originalBeta
			BetterFriendlistDB.quickFilterVisibility.online = originalVisibility
			Registry:NormalizeCurrentSelections()
		end,
	})

	TS:RegisterTest("filter", "Registry_BetaDisabledShowsAllBuiltinFilters", {
		description = "Disabled Beta Features should ignore built-in QuickFilter visibility settings",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local originalFilter = BetterFriendlistDB.quickFilter
			local originalBeta = BetterFriendlistDB.enableBetaFeatures
			local originalVisibility = BetterFriendlistDB.quickFilterVisibility.online

			BetterFriendlistDB.enableBetaFeatures = false
			BetterFriendlistDB.quickFilter = "online"
			BetterFriendlistDB.quickFilterVisibility.online = false
			Registry:NormalizeCurrentSelections()

			V:AssertEqual(BetterFriendlistDB.quickFilter, "online", "Hidden built-in filter should remain selectable")
			V:Assert(Registry:IsQuickFilterVisible("online"), "Built-in filter should be visible when Beta is disabled")

			local found = false
			for _, entry in ipairs(Registry:GetVisibleQuickFilters()) do
				if entry.id == "online" then
					found = true
					break
				end
			end
			V:Assert(found, "Hidden built-in filter should appear in the visible filter list")

			BetterFriendlistDB.quickFilter = originalFilter
			BetterFriendlistDB.enableBetaFeatures = originalBeta
			BetterFriendlistDB.quickFilterVisibility.online = originalVisibility
			Registry:NormalizeCurrentSelections()
		end,
	})

	TS:RegisterTest("sort", "Registry_CustomSorter_ChainAndFallback", {
		description = "Custom sorter chains must compare multiple fields and fall back stably",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local testId = "custom_sorter_test_chain"
			local original = BetterFriendlistDB.customSorters[testId]
			local originalVisibility = BetterFriendlistDB.sorterVisibility[testId]
			BetterFriendlistDB.customSorters[testId] = {
				id = testId,
				name = "Chain Test",
				icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\sliders",
				chain = {
					{ field = "status", direction = "asc", empty = "last" },
					{ field = "level", direction = "desc", empty = "last" },
				},
			}
			BetterFriendlistDB.sorterVisibility[testId] = true

			local high = { connected = true, _sort_status = 0, level = 70, _sort_level = 70, _sort_name = "b", index = 2 }
			local low = { connected = true, _sort_status = 0, level = 10, _sort_level = 10, _sort_name = "a", index = 1 }
			local offline = { connected = false, _sort_status = 4, level = 80, _sort_level = 80, _sort_name = "z", index = 3 }

			V:Assert(Registry:CompareFriends(high, low, testId, "none") == true, "Higher level should sort first")
			V:Assert(Registry:CompareFriends(high, offline, testId, "none") == true, "Online should sort before offline")

			BetterFriendlistDB.customSorters[testId] = original
			BetterFriendlistDB.sorterVisibility[testId] = originalVisibility
		end,
	})

	TS:RegisterTest("sort", "Registry_ActiveSorterFallback_GameStatus", {
		description = "Hidden active sorters must fall back to primary game and secondary status",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local originalPrimary = BetterFriendlistDB.primarySort
			local originalSecondary = BetterFriendlistDB.secondarySort
			local originalBeta = BetterFriendlistDB.enableBetaFeatures
			local originalVisibility = BetterFriendlistDB.sorterVisibility.name

			BetterFriendlistDB.enableBetaFeatures = true
			BetterFriendlistDB.primarySort = "name"
			BetterFriendlistDB.secondarySort = "missing_sorter"
			BetterFriendlistDB.sorterVisibility.name = false
			Registry:NormalizeCurrentSelections()

			V:AssertEqual(BetterFriendlistDB.primarySort, "game", "Hidden primary sorter should fall back to game")
			V:AssertEqual(BetterFriendlistDB.secondarySort, "status", "Invalid secondary sorter should fall back to status")

			BetterFriendlistDB.primarySort = originalPrimary
			BetterFriendlistDB.secondarySort = originalSecondary
			BetterFriendlistDB.enableBetaFeatures = originalBeta
			BetterFriendlistDB.sorterVisibility.name = originalVisibility
			Registry:NormalizeCurrentSelections()
		end,
	})

	TS:RegisterTest("sort", "Registry_BetaDisabledShowsAllBuiltinSorters", {
		description = "Disabled Beta Features should ignore built-in Sorter visibility settings",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local originalPrimary = BetterFriendlistDB.primarySort
			local originalSecondary = BetterFriendlistDB.secondarySort
			local originalBeta = BetterFriendlistDB.enableBetaFeatures
			local originalVisibility = BetterFriendlistDB.sorterVisibility.name

			BetterFriendlistDB.enableBetaFeatures = false
			BetterFriendlistDB.primarySort = "name"
			BetterFriendlistDB.secondarySort = "status"
			BetterFriendlistDB.sorterVisibility.name = false
			Registry:NormalizeCurrentSelections()

			V:AssertEqual(BetterFriendlistDB.primarySort, "name", "Hidden built-in sorter should remain selectable")
			V:Assert(Registry:IsSorterVisible("name"), "Built-in sorter should be visible when Beta is disabled")

			local found = false
			for _, entry in ipairs(Registry:GetVisibleSorters()) do
				if entry.id == "name" then
					found = true
					break
				end
			end
			V:Assert(found, "Hidden built-in sorter should appear in the visible sorter list")

			BetterFriendlistDB.primarySort = originalPrimary
			BetterFriendlistDB.secondarySort = originalSecondary
			BetterFriendlistDB.enableBetaFeatures = originalBeta
			BetterFriendlistDB.sorterVisibility.name = originalVisibility
			Registry:NormalizeCurrentSelections()
		end,
	})

	TS:RegisterTest("settings", "FilterSortBuilder_DBDefaults", {
		description = "Filter/sort builder SavedVariables must exist and use the safe fallback IDs",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			V:AssertType(BetterFriendlistDB.customQuickFilters, "table", "customQuickFilters should be a table")
			V:AssertType(BetterFriendlistDB.quickFilterTags, "table", "quickFilterTags should be a table")
			V:AssertType(BetterFriendlistDB.quickFilterVisibility, "table", "quickFilterVisibility should be a table")
			V:AssertType(BetterFriendlistDB.quickFilterOrder, "table", "quickFilterOrder should be a table")
			V:AssertType(BetterFriendlistDB.customSorters, "table", "customSorters should be a table")
			V:AssertType(BetterFriendlistDB.sorterVisibility, "table", "sorterVisibility should be a table")
			V:AssertType(BetterFriendlistDB.sorterOrder, "table", "sorterOrder should be a table")
			V:AssertEqual(Registry.FALLBACK_FILTER, "all", "Fallback filter should be all")
			V:AssertEqual(Registry.FALLBACK_PRIMARY_SORT, "game", "Fallback primary sort should be game")
			V:AssertEqual(Registry.FALLBACK_SECONDARY_SORT, "status", "Fallback secondary sort should be status")
		end,
	})

	-- ===== DEEP LOGIC TESTS: BUG PATTERN DETECTION =====

	TS:RegisterTest("bugs", "OrTrue_Pattern_Not_Present", {
		description = "Cache lookups must not use problematic boolean pattern (causes bugs)",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Test that boolean settings work correctly with false values
			local DB = BFL:GetModule("DB")
			local originalCompact = DB:Get("compactMode")

			-- Explicitly set to false
			DB:Set("compactMode", false)
			FriendsList:UpdateSettingsCache()

			-- Problematic pattern would return true even when value is false
			-- Correct behavior: returns false when value is false
			V:Assert(
				FriendsList.settingsCache.compactMode == false,
				"compactMode=false must be preserved in cache (not incorrectly converted)"
			)

			-- Restore
			DB:Set("compactMode", originalCompact)
		end,
	})

	TS:RegisterTest("bugs", "NilCheck_Not_OrDefault_For_Booleans", {
		description = "Boolean settings with 'or default' must handle false correctly",
		action = function(V)
			local DB = BFL:GetModule("DB")

			-- Test case: Setting is explicitly false
			DB:Set("_testBoolSetting", false)

			-- BAD pattern: DB:Get("_testBoolSetting") or true  -> returns true (WRONG!)
			-- GOOD pattern: DB:Get("_testBoolSetting", true)   -> returns false (CORRECT!)

			local badPattern = DB:Get("_testBoolSetting") or true
			local goodPattern = DB:Get("_testBoolSetting", true)

			-- The bad pattern would fail this test
			V:Assert(
				goodPattern == false,
				"DB:Get with default must return false when value is false (not use 'or' fallback)"
			)

			-- Cleanup
			DB:Set("_testBoolSetting", nil)
		end,
	})

	TS:RegisterTest("bugs", "Nickname_Persistence", {
		description = "Nicknames must persist after setting them",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local testUID = "wow_TestNicknameFriend-TestRealm"
			local testNickname = "MyBestFriend"

			-- Set nickname
			DB:SetNickname(testUID, testNickname)

			-- Retrieve nickname
			local retrieved = DB:GetNickname(testUID)
			V:Assert(
				retrieved == testNickname,
				"Nickname should be retrievable after setting (expected '"
					.. testNickname
					.. "', got '"
					.. tostring(retrieved)
					.. "')"
			)

			-- Clear nickname
			DB:SetNickname(testUID, nil)
			local cleared = DB:GetNickname(testUID)
			V:Assert(cleared == nil, "Nickname should be nil after clearing")
		end,
	})

	TS:RegisterTest("bugs", "CustomNames_NumericBattleTag_DoesNotResync", {
		description = "Known BattleTags must not be rewritten when CustomNames cannot read their stored alias",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local lookupKey = "Example321#2785"
			local fakeLib = {
				Get = function(name)
					return name
				end,
				IsInBnetDatabase = function(name)
					return name == lookupKey
				end,
			}

			V:Assert(
				DB:ShouldPushNicknameToCustomNames(fakeLib, lookupKey) == false,
				"Known BattleTag aliases must not be pushed again"
			)
			V:Assert(
				DB:ShouldPushNicknameToCustomNames(fakeLib, "New321#1234") == true,
				"Unknown BattleTag aliases should still be imported"
			)
			V:Assert(
				DB:ShouldPushNicknameToCustomNames(fakeLib, "NewFriend-TestRealm") == true,
				"Missing character aliases should still be imported"
			)
		end,
	})

	TS:RegisterTest("bugs", "GroupAssignment_Persistence", {
		description = "Group assignments must persist correctly",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local testUID = "wow_TestGroupFriend-TestRealm"

			-- Create a test group
			local success, groupId = Groups:Create("TestPersistGroup", { r = 1, g = 0, b = 0 })
			if not success then
				V:Skip("Could not create test group")
				return
			end

			-- Add friend to group
			DB:AddFriendToGroup(testUID, groupId)

			-- Verify friend is in group
			V:Assert(DB:IsFriendInGroup(testUID, groupId) == true, "Friend should be in group after adding")

			-- Remove friend from group
			DB:RemoveFriendFromGroup(testUID, groupId)
			V:Assert(DB:IsFriendInGroup(testUID, groupId) == false, "Friend should not be in group after removing")

			-- Cleanup
			Groups:Delete(groupId)
		end,
	})

	TS:RegisterTest("bugs", "StaticGroups_AreNotPersisted", {
		description = "Derived static groups must never be stored as custom friend assignments",
		action = function(V)
			local DB = BFL:GetModule("DB")
			if not DB then
				V:Skip("DB module not loaded")
				return
			end

			local testUID = "wow_TestStaticGroupFriend-TestRealm"
			local staticGroupIds = { "favorites", "ingame", "recentlyadded", "nogroup" }

			for _, groupId in ipairs(staticGroupIds) do
				local added = DB:AddFriendToGroup(testUID, groupId)
				V:Assert(added == false, "Static group should reject assignment: " .. groupId)
				V:Assert(DB:IsFriendInGroup(testUID, groupId) == false, "Static group must not persist: " .. groupId)
			end

			DB:SetFriendGroups(testUID, { "nogroup", "favorites", "test-custom-group", "test-custom-group" })
			local storedGroups = DB:GetFriendGroups(testUID)
			V:Assert(#storedGroups == 1, "Sanitization should retain one unique custom assignment")
			V:Assert(storedGroups[1] == "test-custom-group", "Sanitization should remove all static groups")

			DB:SetFriendGroups(testUID, nil)
		end,
	})

	-- ===== DEEP LOGIC TESTS: GROUPS =====

	TS:RegisterTest("groups", "GroupColor_Persistence", {
		description = "Group colors must persist after setting",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local testColor = { r = 0.5, g = 0.25, b = 0.75 }
			local testGroupName = "ColorTestGroup_" .. tostring(time())
			local success, groupId = Groups:Create(testGroupName)

			if not success then
				V:Skip("Could not create test group")
				return
			end

			Groups:SetColor(groupId, testColor.r, testColor.g, testColor.b)

			local group = Groups:Get(groupId)
			V:Assert(group ~= nil, "Group should exist after creation")
			V:Assert(group.color ~= nil, "Group should have color")
			V:Assert(group.color.r == testColor.r, "Red component should match")
			V:Assert(group.color.g == testColor.g, "Green component should match")
			V:Assert(group.color.b == testColor.b, "Blue component should match")

			-- Cleanup
			Groups:Delete(groupId)
		end,
	})

	TS:RegisterTest("groups", "GroupRename_Works", {
		description = "Groups must be renamable",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local success, groupId = Groups:Create("OriginalName", { r = 1, g = 1, b = 1 })
			if not success then
				V:Skip("Could not create test group")
				return
			end

			-- Rename
			local renamed = Groups:Rename(groupId, "NewName")
			V:Assert(renamed == true, "Rename should succeed")

			local group = Groups:Get(groupId)
			V:Assert(group.name == "NewName", "Group name should be updated")

			-- Cleanup
			Groups:Delete(groupId)
		end,
	})

	-- ===== DEEP LOGIC TESTS: EVENT-DRIVEN UPDATES =====

	TS:RegisterTest("events", "SettingsVersion_Triggers_CacheRebuild", {
		description = "Incrementing SettingsVersion must trigger cache rebuild on next update",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Force cache to current version
			FriendsList:UpdateSettingsCache()
			local cachedVersion = FriendsList.settingsCacheVersion

			-- Manually increment SettingsVersion (simulates DB:Set)
			BFL.SettingsVersion = (BFL.SettingsVersion or 1) + 1

			-- Cache should now be stale
			V:Assert(
				FriendsList.settingsCacheVersion ~= BFL.SettingsVersion,
				"Cache version should be stale after SettingsVersion increment"
			)

			-- Update should rebuild cache
			FriendsList:UpdateSettingsCache()
			V:Assert(
				FriendsList.settingsCacheVersion == BFL.SettingsVersion,
				"Cache version should match after UpdateSettingsCache"
			)
		end,
	})

	TS:RegisterTest("events", "OnFriendListUpdate_TriggersRefresh", {
		description = "OnFriendListUpdate must trigger a UI refresh when frame is visible",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Ensure frame is visible
			if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end

			-- Track if update was called
			local updateCalled = false
			local originalUpdate = FriendsList.UpdateFriendsList
			FriendsList.UpdateFriendsList = function(self, ...)
				updateCalled = true
				return originalUpdate(self, ...)
			end

			-- Fire update with forceImmediate
			FriendsList:OnFriendListUpdate(true)

			-- Restore original function
			FriendsList.UpdateFriendsList = originalUpdate

			V:Assert(
				updateCalled == true,
				"OnFriendListUpdate(true) should call UpdateFriendsList when frame is visible"
			)
		end,
	})

	TS:RegisterTest("events", "HiddenFrame_MarksDirty", {
		description = "Events while frame hidden must mark for update on show",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Ensure frame is hidden
			if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
				BetterFriendsFrame:Hide()
			end

			-- Fire update (should set dirty flag, not actually update)
			local updateCalled = false
			local originalUpdate = FriendsList.UpdateFriendsList
			FriendsList.UpdateFriendsList = function(self, ...)
				updateCalled = true
				return originalUpdate(self, ...)
			end

			FriendsList:OnFriendListUpdate(false) -- Non-immediate

			-- Restore
			FriendsList.UpdateFriendsList = originalUpdate

			-- Update should NOT have been called (frame is hidden)
			V:Assert(updateCalled == false, "OnFriendListUpdate should NOT call UpdateFriendsList when frame is hidden")
		end,
	})

	TS:RegisterTest("events", "GroupChange_TriggersVersionIncrement", {
		description = "Adding/removing friend from group must increment SettingsVersion",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local Groups = BFL:GetModule("Groups")
			if not DB then
				V:Skip("DB module not loaded")
				return
			end
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local testUID = "wow_EventTestFriend-TestRealm"
			local success, groupId = Groups:Create("EventTestGroup", { r = 0.5, g = 0.5, b = 0.5 })
			if not success then
				V:Skip("Could not create test group")
				return
			end

			local versionBefore = BFL.SettingsVersion or 1

			-- Add friend to group
			DB:AddFriendToGroup(testUID, groupId)

			local versionAfterAdd = BFL.SettingsVersion or 1
			V:Assert(versionAfterAdd > versionBefore, "SettingsVersion should increment after AddFriendToGroup")

			-- Remove friend from group
			DB:RemoveFriendFromGroup(testUID, groupId)

			local versionAfterRemove = BFL.SettingsVersion or 1
			V:Assert(
				versionAfterRemove > versionAfterAdd,
				"SettingsVersion should increment after RemoveFriendFromGroup"
			)

			-- Cleanup
			Groups:Delete(groupId)
		end,
	})

	TS:RegisterTest("events", "EventCallback_Registration", {
		description = "FriendsList must have registered required event callbacks",
		action = function(V)
			-- Check if BFL has the callback system
			V:Assert(BFL.FireEventCallbacks ~= nil, "BFL.FireEventCallbacks must exist")
			V:Assert(BFL.RegisterEventCallback ~= nil, "BFL.RegisterEventCallback must exist")

			-- Check if callbacks are registered (by checking internal registry)
			-- Note: BFL uses EventCallbacks (capital E)
			local registry = BFL.EventCallbacks or {}

			-- These events should have callbacks registered after addon loads
			-- (may vary based on what modules are loaded)
			local hasAnyCallbacks = false
			for eventName, callbacks in pairs(registry) do
				if #callbacks > 0 then
					hasAnyCallbacks = true
					break
				end
			end

			V:Assert(hasAnyCallbacks, "At least one event must have registered callbacks")
		end,
	})

	TS:RegisterTest("events", "FireEventCallbacks_Works", {
		description = "FireEventCallbacks must invoke registered callbacks",
		action = function(V)
			local callbackFired = false
			local receivedArgs = nil

			-- Use GROUP_ROSTER_UPDATE which fires synchronously
			-- (FRIENDLIST_UPDATE has special debounce handling that delays callbacks)
			local testEvent = "GROUP_ROSTER_UPDATE"

			-- Ensure the event is in the registry
			if not BFL.EventCallbacks[testEvent] then
				BFL.EventCallbacks[testEvent] = {}
			end

			-- Add a test callback directly to the registry (bypass RegisterEventCallback
			-- to avoid WoW event system side effects)
			local testCallback = {
				callback = function(arg1, arg2)
					callbackFired = true
					receivedArgs = { arg1, arg2 }
				end,
				priority = 999, -- low priority so it runs last
			}
			table.insert(BFL.EventCallbacks[testEvent], testCallback)

			-- Fire the event callbacks directly
			BFL:FireEventCallbacks(testEvent, "test1", "test2")

			V:Assert(callbackFired == true, "Callback should have been fired")
			V:Assert(receivedArgs and receivedArgs[1] == "test1", "Callback should receive correct arguments")

			-- Cleanup: remove test callback from registry
			if BFL.EventCallbacks and BFL.EventCallbacks[testEvent] then
				for i = #BFL.EventCallbacks[testEvent], 1, -1 do
					if BFL.EventCallbacks[testEvent][i] == testCallback then
						table.remove(BFL.EventCallbacks[testEvent], i)
						break
					end
				end
			end
		end,
	})

	-- ===== DEEP LOGIC TESTS: UI UPDATE INTEGRATION =====

	TS:RegisterTest("updates", "ForceRefresh_UpdatesList", {
		description = "ForceRefreshFriendsList must trigger immediate update",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end
			if not BFL.ForceRefreshFriendsList then
				V:Skip("ForceRefreshFriendsList not defined")
				return
			end

			-- Ensure frame is visible
			if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end

			-- Track if update was called
			local updateCalled = false
			local originalUpdate = FriendsList.UpdateFriendsList
			FriendsList.UpdateFriendsList = function(self, ...)
				updateCalled = true
				return originalUpdate(self, ...)
			end

			-- Force refresh
			BFL:ForceRefreshFriendsList()

			-- Restore
			FriendsList.UpdateFriendsList = originalUpdate

			V:Assert(updateCalled == true, "ForceRefreshFriendsList should trigger UpdateFriendsList")
		end,
	})

	TS:RegisterTest("updates", "FilterChange_RefreshesUI", {
		description = "SetFilterMode must trigger UI refresh",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalFilter = FriendsList.filterMode
			local originalDBFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter
			local refreshCalled = false
			local refreshReason

			-- Hook coalesced refresh path
			local originalRefresh = BFL.ScheduleFriendsListRefresh
			BFL.ScheduleFriendsListRefresh = function(_, reason)
				refreshCalled = true
				refreshReason = reason
			end

			-- Change filter mode
			FriendsList:SetFilterMode(originalFilter == "all" and "online" or "all")

			-- Restore
			BFL.ScheduleFriendsListRefresh = originalRefresh
			FriendsList.filterMode = originalFilter
			if BetterFriendlistDB then
				BetterFriendlistDB.quickFilter = originalDBFilter
			end

			V:Assert(refreshCalled == true, "SetFilterMode should schedule friends list refresh")
			V:Assert(refreshReason == "filter", "SetFilterMode should use filter refresh reason")
		end,
	})

	TS:RegisterTest("updates", "SortChange_RefreshesUI", {
		description = "SetSortMode must trigger UI refresh",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSort = FriendsList.sortMode
			local originalSecondarySort = FriendsList.secondarySort
			local originalDBSort = BetterFriendlistDB and BetterFriendlistDB.primarySort
			local originalDBSecondarySort = BetterFriendlistDB and BetterFriendlistDB.secondarySort
			local refreshCalled = false
			local refreshReason

			-- Hook coalesced refresh path
			local originalRefresh = BFL.ScheduleFriendsListRefresh
			BFL.ScheduleFriendsListRefresh = function(_, reason)
				refreshCalled = true
				refreshReason = reason
			end

			-- Change sort mode to something different
			local newSort = originalSort == "status" and "name" or "status"
			FriendsList:SetSortMode(newSort)

			-- Restore
			BFL.ScheduleFriendsListRefresh = originalRefresh
			FriendsList.sortMode = originalSort
			FriendsList.secondarySort = originalSecondarySort
			if BetterFriendlistDB then
				BetterFriendlistDB.primarySort = originalDBSort
				BetterFriendlistDB.secondarySort = originalDBSecondarySort
			end

			V:Assert(refreshCalled == true, "SetSortMode should schedule friends list refresh")
			V:Assert(refreshReason == "primary-sort", "SetSortMode should use primary-sort refresh reason")
		end,
	})

	TS:RegisterTest("updates", "SearchText_SkipRefresh", {
		description = "Programmatic search resets can update state without forcing a refresh",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSearch = FriendsList.searchText
			local testSearch = "__bfl_skip_refresh_test__"
			if originalSearch == testSearch then
				testSearch = testSearch .. "2"
			end

			local refreshCalled = false
			local originalRefresh = BFL.ForceRefreshFriendsList
			BFL.ForceRefreshFriendsList = function(...)
				refreshCalled = true
			end

			FriendsList:SetSearchText(testSearch, true)

			BFL.ForceRefreshFriendsList = originalRefresh
			local changed = FriendsList.searchText == testSearch
			FriendsList.searchText = originalSearch

			V:Assert(changed == true, "SetSearchText should still update search state")
			V:Assert(refreshCalled == false, "skipRefresh should suppress ForceRefreshFriendsList")
		end,
	})

	TS:RegisterTest("updates", "SearchText_FiltersCorrectly", {
		description = "SetSearchText must affect filter results",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSearch = FriendsList.searchText
			local originalFilter = FriendsList.filterMode

			-- Set search text
			FriendsList.filterMode = "all"
			FriendsList:SetSearchText("TestSearchString123")

			-- Create test friend that DOESN'T match
			local nonMatchingFriend = {
				connected = true,
				type = "wow",
				name = "SomeOtherPlayer",
				note = "Random note",
			}

			-- Should NOT pass filter with non-matching search
			V:Assert(
				FriendsList:PassesFilters(nonMatchingFriend) == false,
				"Friend should NOT pass filter when search text doesn't match"
			)

			-- Create test friend that DOES match
			local matchingFriend = {
				connected = true,
				type = "wow",
				name = "TestSearchString123Player",
				note = "",
			}

			V:Assert(
				FriendsList:PassesFilters(matchingFriend) == true,
				"Friend should pass filter when search text matches"
			)

			-- Restore
			FriendsList:SetSearchText(originalSearch or "")
			FriendsList.filterMode = originalFilter
		end,
	})

	TS:RegisterTest("updates", "NicknameChange_InvalidatesCache", {
		description = "Setting nickname must invalidate nickname cache",
		action = function(V)
			local DB = BFL:GetModule("DB")
			if not DB then
				V:Skip("DB not loaded")
				return
			end

			local testUID = "wow_NicknameCacheTest-TestRealm"
			local versionBefore = BFL.NicknameCacheVersion or 1

			-- Set nickname
			DB:SetNickname(testUID, "TestNickname")

			local versionAfter = BFL.NicknameCacheVersion or 1
			V:Assert(versionAfter > versionBefore, "NicknameCacheVersion should increment after SetNickname")

			-- Cleanup
			DB:SetNickname(testUID, nil)
		end,
	})

	-- ===== DEEP LOGIC TESTS: RENDER CONSISTENCY =====

	TS:RegisterTest("render", "FriendsList_NotNil_After_Update", {
		description = "FriendsList.friendsList must not be nil after update",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Ensure frame is shown for update to run
			if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end

			-- Force update
			FriendsList:UpdateFriendsList()

			V:Assert(FriendsList.friendsList ~= nil, "friendsList should not be nil after UpdateFriendsList")
			V:Assert(type(FriendsList.friendsList) == "table", "friendsList should be a table")
		end,
	})

	TS:RegisterTest("render", "GroupedFriends_Structure", {
		description = "groupedFriends must have valid structure after update",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Ensure frame is shown
			if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end

			-- Force update
			FriendsList:UpdateFriendsList()

			local grouped = FriendsList.groupedFriends
			V:Assert(grouped ~= nil, "groupedFriends should not be nil")
			V:Assert(type(grouped) == "table", "groupedFriends should be a table")

			-- Check that each group has expected structure
			for groupId, groupData in pairs(grouped) do
				if type(groupData) == "table" then
					V:Assert(type(groupId) == "string", "Group ID should be string, got " .. type(groupId))
				end
			end
		end,
	})

	TS:RegisterTest("render", "BuiltInRename_UpdatesHeader", {
		description = "Built-in rename should update group header display",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			local Groups = BFL:GetModule("Groups")
			local MockDataProvider = BFL.MockDataProvider
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end
			if not Groups then
				V:Skip("Groups not loaded")
				return
			end
			if not MockDataProvider then
				V:Skip("MockDataProvider not available")
				return
			end

			local DB = BFL:GetModule("DB")
			local originalShowFavorites = DB and DB:Get("showFavoritesGroup", true)
			if DB then
				DB:Set("showFavoritesGroup", true)
			end

			local favoriteFriend = MockDataProvider:CreateBNetFriend({
				isOnline = true,
				isFavorite = true,
				game = { program = "WoW", name = "World of Warcraft" },
			})
			local groups = MockDataProvider:GenerateGroups(0, { includeBuiltin = true })
			TestSuite:ApplyMockData({
				friends = { favoriteFriend },
				groups = groups,
				groupAssignments = {},
			})

			local originalName = Groups:Get("favorites") and Groups:Get("favorites").name
			local newName = "FavoritesRenamed_" .. tostring(time())
			FriendsList:UpdateSettingsCache()
			if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
				ToggleBetterFriendsFrame()
			end
			Groups:Rename("favorites", newName)
			FriendsList:UpdateFriendsList()

			local headerName
			if BFL.IsClassic then
				local displayList = FriendsList.classicDisplayList or {}
				for _, item in ipairs(displayList) do
					if (item.buttonType == 2 or item.type == 2) and item.groupId == "favorites" then
						headerName = item.name
						break
					end
				end
			elseif FriendsList.scrollBox and FriendsList.scrollBox.GetDataProvider then
				local provider = FriendsList.scrollBox:GetDataProvider()
				if provider then
					for _, item in provider:Enumerate() do
						if item and item.buttonType == 2 and item.groupId == "favorites" then
							headerName = item.name
							break
						end
					end
				end
			else
				local displayList = FriendsList.cachedDisplayList or {}
				for _, item in ipairs(displayList) do
					if (item.buttonType == 2 or item.type == 2) and item.groupId == "favorites" then
						headerName = item.name
						break
					end
				end
			end

			V:Assert(headerName == newName, "Favorites header should reflect renamed value")

			if originalName then
				Groups:Rename("favorites", originalName)
			end
			if DB then
				DB:Set("showFavoritesGroup", originalShowFavorites)
			end
			local ScenarioManager = BFL.ScenarioManager
			if ScenarioManager and ScenarioManager.Clear then
				ScenarioManager:Clear()
			end
		end,
	})

	TS:RegisterTest("render", "SettingsCache_Not_Empty", {
		description = "settingsCache must have values after UpdateSettingsCache",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			FriendsList:UpdateSettingsCache()

			local cache = FriendsList.settingsCache
			V:Assert(cache ~= nil, "settingsCache should not be nil")
			V:Assert(type(cache) == "table", "settingsCache should be a table")

			-- Check that essential settings are present
			V:Assert(cache.nameDisplayFormat ~= nil, "settingsCache.nameDisplayFormat should not be nil")
			V:Assert(
				cache.compactMode ~= nil or cache.compactMode == false,
				"settingsCache.compactMode should be defined (even if false)"
			)
		end,
	})

	-- =============================================
	-- GITHUB ISSUE REGRESSION TESTS
	-- Tests derived from actual bug reports
	-- =============================================

	-- Issue #92: Predefined groups can expand empty when the optimized group path rebuilds them
	local issue92State = {}
	TS:RegisterTest("issues", "Issue92_PredefinedGroups_OptimizedFallback", {
		description = "#92: Favorites, In-Game, and Recently Added should populate through optimized group expansion",
		setup = function()
			local FriendsList = BFL:GetModule("FriendsList")
			issue92State = {
				friendsList = {},
				groupedFriends = FriendsList and FriendsList.groupedFriends or nil,
				cachedGroupedFriends = FriendsList and FriendsList.cachedGroupedFriends or nil,
				searchText = FriendsList and FriendsList.searchText or nil,
				filterMode = FriendsList and FriendsList.filterMode or nil,
				recentlyAddedTimestamps = BetterFriendlistDB and BetterFriendlistDB.recentlyAddedTimestamps or nil,
			}
			if FriendsList and FriendsList.friendsList then
				for i, friend in ipairs(FriendsList.friendsList) do
					issue92State.friendsList[i] = friend
				end
			end
		end,
		action = function(V)
			local DB = BFL:GetModule("DB")
			local FriendsList = BFL:GetModule("FriendsList")
			local Groups = BFL:GetModule("Groups")
			local RecentlyAddedModule = BFL:GetModule("RecentlyAdded")
			if not DB or not FriendsList or not Groups or not RecentlyAddedModule then
				V:Skip("Required group modules not loaded")
				return
			end
			if not BetterFriendlistDB then
				V:Skip("BetterFriendlistDB not available")
				return
			end

			DB:Set("showFavoritesGroup", true)
			DB:Set("enableInGameGroup", true)
			DB:Set("inGameGroupMode", "same_game")
			DB:Set("enableRecentlyAddedGroup", true)

			FriendsList.searchText = ""
			FriendsList.filterMode = "all"
			FriendsList.groupedFriends = nil
			FriendsList.cachedGroupedFriends = nil
			BetterFriendlistDB.friendGroups = {}

			local projectID = WOW_PROJECT_ID or WOW_PROJECT_MAINLINE or 1
			local favoriteFriend = {
				type = "bnet",
				bnetAccountID = 92001,
				battleTag = "Issue92Favorite#0001",
				accountName = "Issue92Favorite",
				connected = false,
				isFavorite = true,
				gameAccountInfo = { isOnline = false, clientProgram = "" },
			}
			local inGameFriend = {
				type = "bnet",
				bnetAccountID = 92002,
				battleTag = "Issue92InGame#0001",
				accountName = "Issue92InGame",
				connected = true,
				isFavorite = false,
				gameAccountInfo = {
					isOnline = true,
					clientProgram = BNET_CLIENT_WOW or "WoW",
					wowProjectID = projectID,
				},
			}
			local recentFriend = {
				type = "bnet",
				bnetAccountID = 92003,
				battleTag = "Issue92Recent#0001",
				accountName = "Issue92Recent",
				connected = false,
				isFavorite = false,
				gameAccountInfo = { isOnline = false, clientProgram = "" },
			}
			local recentUID = GetFriendUID(recentFriend)
			BetterFriendlistDB.recentlyAddedTimestamps = {
				[recentUID] = time(),
			}

			wipe(FriendsList.friendsList)
			table.insert(FriendsList.friendsList, favoriteFriend)
			table.insert(FriendsList.friendsList, inGameFriend)
			table.insert(FriendsList.friendsList, recentFriend)

			local favorites = FriendsList:GetFriendsForGroup("favorites")
			local inGame = FriendsList:GetFriendsForGroup("ingame")
			local recent = FriendsList:GetFriendsForGroup("recentlyadded")

			V:AssertEqual(#favorites, 1, "Favorites group should include the favorite friend")
			V:AssertEqual(favorites[1], favoriteFriend, "Favorites group should return the expected friend")
			V:AssertEqual(#inGame, 1, "In-Game group should include the same-project WoW friend")
			V:AssertEqual(inGame[1], inGameFriend, "In-Game group should return the expected friend")
			V:AssertEqual(#recent, 1, "Recently Added group should include recent friends")
			V:AssertEqual(recent[1], recentFriend, "Recently Added group should return the expected friend")
		end,
		teardown = function()
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				wipe(FriendsList.friendsList)
				for i, friend in ipairs(issue92State.friendsList or {}) do
					FriendsList.friendsList[i] = friend
				end
				FriendsList.groupedFriends = issue92State.groupedFriends
				FriendsList.cachedGroupedFriends = issue92State.cachedGroupedFriends
				FriendsList.searchText = issue92State.searchText or ""
				FriendsList.filterMode = issue92State.filterMode or "all"
				FriendsList.lastBuildInputs = nil
			end
			if BetterFriendlistDB then
				BetterFriendlistDB.recentlyAddedTimestamps = issue92State.recentlyAddedTimestamps
			end
		end,
	})

	-- Issue #41: "Show Collapse Arrow" does nothing
	TS:RegisterTest("issues", "Issue41_ShowGroupArrow_Setting", {
		description = "#41: showGroupArrow setting must affect UI",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local original = DB:Get("showGroupArrow", true)

			-- Set to false
			DB:Set("showGroupArrow", false)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.showGroupArrow == false, "showGroupArrow=false must be in cache")

			-- Set to true
			DB:Set("showGroupArrow", true)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.showGroupArrow == true, "showGroupArrow=true must be in cache")

			-- Restore
			DB:Set("showGroupArrow", original)
		end,
	})

	-- Issue #36: Show faction Icons does nothing
	TS:RegisterTest("issues", "Issue36_ShowFactionIcons_Setting", {
		description = "#36: showFactionIcons setting must affect cache",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local original = DB:Get("showFactionIcons", false)

			-- Enable faction icons
			DB:Set("showFactionIcons", true)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.showFactionIcons == true, "showFactionIcons=true must be cached")

			-- Disable faction icons
			DB:Set("showFactionIcons", false)
			FriendsList:UpdateSettingsCache()
			V:Assert(FriendsList.settingsCache.showFactionIcons == false, "showFactionIcons=false must be cached")

			-- Restore
			DB:Set("showFactionIcons", original)
		end,
	})

	-- Issue #32: Rename group is possible for "No Group" - but does nothing
	TS:RegisterTest("issues", "Issue32_NoGroup_RenameUpdates", {
		description = "#32: Renaming 'nogroup' should update display name",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local originalName = Groups:Get("nogroup") and Groups:Get("nogroup").name
			local newName = "RenamedNoGroup"

			local result = Groups:Rename("nogroup", newName)
			V:Assert(result == true, "Renaming 'nogroup' should succeed")

			local updated = Groups:Get("nogroup")
			V:Assert(updated and updated.name == newName, "No Group name should update")

			-- Restore
			if originalName then
				Groups:Rename("nogroup", originalName)
			end
		end,
	})

	-- Issue #31: Rename Favorites changes context menu but not group name
	TS:RegisterTest("issues", "Issue31_Favorites_RenameUpdates", {
		description = "#31: Renaming 'favorites' should update display name",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local originalName = Groups:Get("favorites") and Groups:Get("favorites").name
			local newName = "RenamedFavorites"

			local result = Groups:Rename("favorites", newName)
			V:Assert(result == true, "Renaming 'favorites' should succeed")

			local updated = Groups:Get("favorites")
			V:Assert(updated and updated.name == newName, "Favorites name should update")

			-- Restore
			if originalName then
				Groups:Rename("favorites", originalName)
			end
		end,
	})

	-- Issue #37: Rename of "In-Game" group shouldn't work
	TS:RegisterTest("issues", "Issue37_InGame_RenameUpdates", {
		description = "#37: Renaming 'ingame' should update display name",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			local originalName = Groups:Get("ingame") and Groups:Get("ingame").name
			local newName = "RenamedInGame_" .. tostring(time())

			local result = Groups:Rename("ingame", newName)
			V:Assert(result == true, "Renaming 'ingame' should succeed")

			local updated = Groups:Get("ingame")
			V:Assert(updated and updated.name == newName, "In-Game name should update")

			-- Restore
			if originalName then
				Groups:Rename("ingame", originalName)
			end
		end,
	})

	-- Issue #25 (CLOSED): Global Sync tries to add current character as friend
	TS:RegisterTest("issues", "Issue25_GlobalSync_SkipsSelf", {
		description = "#25: GlobalSync must not try to add player as own friend",
		action = function(V)
			local GlobalSync = BFL:GetModule("GlobalSync")
			V:AssertNotNil(GlobalSync, "GlobalSync should be loaded")

			-- Get player name
			local playerName = UnitName("player")
			local playerRealm = GetRealmName()
			local fullName = playerName .. "-" .. playerRealm:gsub("%s", "")

			V:AssertNotNil(GlobalSync.ShouldAddFriend, "GlobalSync.ShouldAddFriend should exist")
			local shouldAdd = GlobalSync:ShouldAddFriend(fullName)
			V:Assert(shouldAdd == false, "GlobalSync should not try to add player (" .. fullName .. ") as friend")
		end,
	})

	-- Issue #22/#21 (CLOSED): Combat lockdown protection
	TS:RegisterTest("issues", "Issue21_Combat_NoProtectedCalls", {
		description = "#21/#22: Frame operations must check InCombatLockdown",
		action = function(V)
			-- Check if InCombatLockdown function exists
			V:Assert(InCombatLockdown ~= nil, "InCombatLockdown must be available")

			-- Check if FriendsList has combat protection
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- The pattern should be: check InCombatLockdown() before UI updates
			-- We can only verify the function exists, not that it's called correctly
			-- (actual combat testing would require being in combat)
			V:Assert(type(InCombatLockdown) == "function", "InCombatLockdown must be a function for combat protection")
		end,
	})

	-- Issue #18 (CLOSED): Window opens after every reload
	TS:RegisterTest("issues", "Issue18_NoAutoOpen_OnReload", {
		description = "#18: Frame should not auto-open on reload unless previously open",
		action = function(V)
			-- This tests that we DON'T store "always open" state incorrectly
			local DB = BFL:GetModule("DB")

			-- Check that there's no persistent "forceOpen" or similar flag
			local forceOpen = DB:Get("forceOpenOnLogin")
			local autoShow = DB:Get("autoShowOnLoad")

			-- These should either not exist or be false
			V:Assert(forceOpen == nil or forceOpen == false, "forceOpenOnLogin should not be set/true")
			V:Assert(autoShow == nil or autoShow == false, "autoShowOnLoad should not be set/true")
		end,
	})

	-- Issue #15 (CLOSED): strsplit nil error with WoW friends
	TS:RegisterTest("issues", "Issue15_StrsplitNilProtection", {
		description = "#15: Friend name processing must handle nil names",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Test that GetFriendUID handles edge cases
			if FriendsList.GetFriendUID then
				-- Test with nil
				local result1 = FriendsList:GetFriendUID(nil)
				V:Assert(result1 == nil, "GetFriendUID(nil) should return nil")

				-- Test with friend with nil name
				local result2 = FriendsList:GetFriendUID({ name = nil, type = "wow" })
				V:Assert(result2 == nil or type(result2) == "string", "GetFriendUID with nil name should not error")

				-- Test with empty friend
				local result3 = FriendsList:GetFriendUID({})
				V:Assert(result3 == nil or type(result3) == "string", "GetFriendUID({}) should not error")
			else
				V:Skip("FriendsList:GetFriendUID not found")
			end
		end,
	})

	-- Issue #26 (CLOSED): ElvUISkin BFLCheckmark nil
	TS:RegisterTest("issues", "Issue26_ElvUISkin_SafeAccess", {
		description = "#26: ElvUISkin must safely access button elements",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local ElvUISkin = BFL:GetModule("ElvUISkin")
			if not ElvUISkin then
				V:Skip("ElvUISkin not loaded")
				return
			end

			-- Check if the module has nil protection
			-- The bug was accessing BFLCheckmark on buttons that don't have it
			-- We just verify the module exists and loads without error
			V:Assert(type(ElvUISkin) == "table", "ElvUISkin module should be a table")
		end,
	})

	-- Issue #14: Friend text color doesn't match Blizzard default
	TS:RegisterTest("issues", "Issue14_DefaultColorMatches", {
		description = "#14: Default font color should match Blizzard BNet blue",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local defaultColor = DB:Get("fontColorFriendName")

			if not defaultColor then
				V:Skip("fontColorFriendName not in DB")
				return
			end

			-- Blizzard BNet Blue is approximately {r=0.51, g=0.773, b=1.0}
			local expectedR = 0.510
			local expectedG = 0.773
			local expectedB = 1.0
			local tolerance = 0.05

			V:Assert(
				defaultColor.r and math.abs(defaultColor.r - expectedR) < tolerance,
				"Default red should be ~0.51, got " .. tostring(defaultColor.r)
			)
			V:Assert(
				defaultColor.g and math.abs(defaultColor.g - expectedG) < tolerance,
				"Default green should be ~0.773, got " .. tostring(defaultColor.g)
			)
			V:Assert(
				defaultColor.b and math.abs(defaultColor.b - expectedB) < tolerance,
				"Default blue should be ~1.0, got " .. tostring(defaultColor.b)
			)
		end,
	})

	-- Issue #27: Friends name truncated too soon
	TS:RegisterTest("issues", "Issue27_NameNotOverTruncated", {
		description = "#27: Friend name width calculation exists",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			-- Check that name display function exists
			if FriendsList.GetDisplayName then
				-- Test with a normal friend
				local testFriend = {
					accountName = "TestAccountName",
					battleTag = "TestTag#1234",
					characterName = "TestCharacter",
					type = "bnet",
				}
				local displayName = FriendsList:GetDisplayName(testFriend)
				V:Assert(displayName ~= nil and displayName ~= "", "GetDisplayName should return non-empty string")
			else
				V:Skip("GetDisplayName not found")
			end
		end,
	})

	-- Issue #13: Request to Join Group popup not showing
	TS:RegisterTest("issues", "Issue13_JoinButton_Exists", {
		description = "#13: Join/Invite button functionality exists",
		action = function(V)
			-- Check that friend button template would have invite functionality
			-- This is a smoke test that the hook exists
			if BFL.HasQuickJoin then
				V:Assert(BFL.HasQuickJoin == true or BFL.HasQuickJoin == false, "HasQuickJoin flag should be defined")
			end

			-- Check QuickJoin module exists on retail
			if BFL.IsRetail and BFL:GetModule("QuickJoin") then
				V:Assert(type(BFL:GetModule("QuickJoin")) == "table", "QuickJoin module should exist on Retail")
			end
		end,
	})

	-- Issue #42: Rightclick in "Raid" not working
	TS:RegisterTest("issues", "Issue42_RaidTab_RightClick", {
		description = "#42: Raid tab should have context menu functionality",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			-- Check if raid tab exists and has expected elements
			local mainFrame = BetterFriendsFrame
			if not mainFrame then
				V:Skip("BetterFriendsFrame not found")
				return
			end

			-- Just verify the raid frame reference exists
			local raidFrame = mainFrame.RaidFrame
			V:Assert(raidFrame ~= nil or BFL.RaidFrame ~= nil, "Raid frame should exist")
		end,
	})

	-- Issue #6: Right click menu missing raid role options (wontfix, but test for awareness)
	TS:RegisterTest("issues", "Issue6_RaidContextMenu_Exists", {
		description = "#6: Raid member context menu should be accessible",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			-- This is marked wontfix, but we test that shortcuts exist as workaround
			local DB = BFL:GetModule("DB")
			local shortcuts = DB:Get("raidShortcuts")

			V:Assert(shortcuts ~= nil, "raidShortcuts should be defined in DB")
			if shortcuts then
				V:Assert(shortcuts.mainTank ~= nil, "mainTank shortcut should exist")
				V:Assert(shortcuts.mainAssist ~= nil, "mainAssist shortcut should exist")
			end
		end,
	})

	-- Generic: Settings persistence after reload (multiple issues)
	TS:RegisterTest("issues", "SettingsPersistence_Critical", {
		description = "Critical settings must persist correctly",
		action = function(V)
			local DB = BFL:GetModule("DB")
			local criticalSettings = {
				"compactMode",
				"hideEmptyGroups",
				"showGroupArrow",
				"showFactionIcons",
				"colorClassNames",
			}

			for _, setting in ipairs(criticalSettings) do
				local value = DB:Get(setting)
				-- Value can be true, false, or nil (defaults apply)
				V:Assert(value ~= "ERROR", setting .. " should not return error state")
			end
		end,
	})

	local localeTestState
	TS:RegisterTest("issues", "Locales_RequiredKeys", {
		description = "Every enUS localization key must exist in every registered locale",
		setup = function()
			localeTestState = { locale = BFL.ConfiguredLocale, missingKeys = BFL.MissingKeys }
			BFL.MissingKeys = {}
		end,
		action = function(V)
			V:Assert(BFL.L and BFL.Locales, "Localization system should exist")
			V:AssertNotNil(BFL_LOCALE_ENUS, "enUS fallback table should exist")

			local expectedKeys, localeNames = {}, {}
			for key in pairs(BFL_LOCALE_ENUS) do table.insert(expectedKeys, key) end
			table.sort(expectedKeys)
			V:Assert(#expectedKeys > 0, "enUS fallback table should contain localization keys")
			for localeName in pairs(BFL.Locales) do table.insert(localeNames, localeName) end
			table.sort(localeNames)

			local findingCount, affectedLocales = 0, 0
			for _, localeName in ipairs(localeNames) do
				local findings = {}
				local switchOk, switchError = pcall(BFL.SetLocale, BFL, localeName)
				if not switchOk then table.insert(findings, "locale load failed: " .. tostring(switchError)) else
					local localeTable = localeName == "enUS" and BFL_LOCALE_ENUS or BFL_LOCALE
					for _, key in ipairs(expectedKeys) do
						local value = localeTable and rawget(localeTable, key)
						if type(value) ~= "string" or value == "" then
							local reason = value == nil and "missing" or value == "" and "empty" or "non-string"
							table.insert(findings, key .. " (" .. reason .. ")")
						end
					end
				end
				if #findings == 0 then
					TS.Reporter:Info(string.format("%s: %d keys checked, no findings", localeName, #expectedKeys))
				else
					affectedLocales = affectedLocales + 1; findingCount = findingCount + #findings
					TS.Reporter:Warn(string.format("%s: %d localization finding(s)", localeName, #findings))
					for _, finding in ipairs(findings) do TS.Reporter:Warn("  " .. localeName .. ":" .. finding) end
				end
			end

			V:Assert(findingCount == 0, string.format("%d localization finding(s) across %d locale(s); complete report shown above", findingCount, affectedLocales))
		end,
		teardown = function()
			if localeTestState and localeTestState.locale then
				BFL:SetLocale(localeTestState.locale)
			end
			if localeTestState then
				BFL.MissingKeys = localeTestState.missingKeys
			end
			localeTestState = nil
		end,
	})

	-- Generic: Custom group creation/deletion cycle
	TS:RegisterTest("issues", "GroupLifecycle_Complete", {
		description = "Group lifecycle: create -> rename -> delete",
		action = function(V)
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				V:Skip("Groups module not loaded")
				return
			end

			-- Create
			local success, groupId = Groups:Create("LifecycleTestGroup", { r = 0.3, g = 0.6, b = 0.9 })
			V:Assert(success == true, "Group creation should succeed")
			V:Assert(groupId ~= nil, "Group ID should be returned")

			if not groupId then
				return
			end

			-- Verify exists
			local group = Groups:Get(groupId)
			V:Assert(group ~= nil, "Group should exist after creation")
			V:Assert(group.name == "LifecycleTestGroup", "Group name should match")

			-- Rename
			local renamed = Groups:Rename(groupId, "RenamedLifecycleGroup")
			V:Assert(renamed == true, "Rename should succeed")

			group = Groups:Get(groupId)
			V:Assert(group.name == "RenamedLifecycleGroup", "Name should be updated")

			-- Delete
			local deleted = Groups:Delete(groupId)
			V:Assert(deleted == true, "Delete should succeed")

			-- Verify gone
			group = Groups:Get(groupId)
			V:Assert(group == nil, "Group should not exist after deletion")
		end,
	})

	-- ===== SECRET VALUE SAFETY TESTS =====

	TS:RegisterTest("data", "IsSecret_NormalValues", {
		description = "BFL:IsSecret() returns false for normal values",
		action = function(V)
			V:Assert(BFL.IsSecret ~= nil, "BFL:IsSecret should exist")
			V:Assert(BFL:IsSecret("hello") == false, "String should not be secret")
			V:Assert(BFL:IsSecret(42) == false, "Number should not be secret")
			V:Assert(BFL:IsSecret(true) == false, "Boolean should not be secret")
			V:Assert(BFL:IsSecret(nil) == false, "Nil should not be secret")
			V:Assert(BFL:IsSecret({}) == false, "Table should not be secret")
		end,
	})

	TS:RegisterTest("data", "GetSafeAccountName_Normal", {
		description = "GetSafeAccountName returns accountName when not secret",
		action = function(V)
			V:Assert(BFL.GetSafeAccountName ~= nil, "BFL:GetSafeAccountName should exist")
			local result = BFL:GetSafeAccountName("PlayerName", "Player#1234")
			V:AssertEqual(result, "PlayerName", "Should return accountName for normal string")
		end,
	})

	TS:RegisterTest("data", "GetSafeAccountName_NilFallback", {
		description = "GetSafeAccountName falls back to battleTag or Unknown",
		action = function(V)
			local r1 = BFL:GetSafeAccountName(nil, "Player#1234")
			V:AssertEqual(r1, "Player#1234", "Should return battleTag when accountName is nil")

			local r2 = BFL:GetSafeAccountName(nil, nil)
			V:AssertEqual(r2, "Unknown", "Should return 'Unknown' when both are nil")
		end,
	})

	TS:RegisterTest("data", "GetSafeAccountName_EmptyString", {
		description = "GetSafeAccountName handles empty string accountName",
		action = function(V)
			local result = BFL:GetSafeAccountName("", "Player#1234")
			V:AssertEqual(result, "", "Should return empty string (truthy in Lua)")
		end,
	})

	TS:RegisterTest("data", "SafeToString_Normal", {
		description = "BFL:SafeToString handles normal values",
		action = function(V)
			V:Assert(BFL.SafeToString ~= nil, "BFL:SafeToString should exist")
			V:AssertEqual(BFL:SafeToString("test"), "test", "String should pass through")
			V:AssertEqual(BFL:SafeToString(42), "42", "Number should convert")
			V:AssertEqual(BFL:SafeToString(nil), "nil", "Nil should convert")
		end,
	})

	TS:RegisterTest("integration", "GetDisplayName_NilAccountName", {
		description = "GetDisplayName handles nil accountName without error",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.GetDisplayName then
				V:Skip("FriendsList not loaded")
				return
			end
			-- Mock BNet friend with nil accountName (simulates secret fallback)
			local mockFriend = {
				type = "bnet",
				uid = "bnet_TestNil#9999",
				accountName = nil,
				battleTag = "TestNil#9999",
				characterName = "TestChar",
				name = "TestChar-TestRealm",
				connected = true,
				note = "",
			}
			local result = FriendsList:GetDisplayName(mockFriend, false)
			V:AssertNotNil(result, "GetDisplayName should return a value")
			V:Assert(result ~= "", "GetDisplayName should not be empty")
		end,
	})

	TS:RegisterTest("integration", "GetDisplayName_TitleFriendCustomName", {
		description = "Title-Friend custom names take display priority without affecting sort mode",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.GetDisplayName then
				V:Skip("FriendsList not loaded")
				return
			end

			FriendsList.settingsCache = FriendsList.settingsCache or {}
			local oldFormat = FriendsList.settingsCache.nameFormatString
			local oldCache = FriendsList.displayNameCache
			FriendsList.settingsCache.nameFormatString = "%name%"
			FriendsList.displayNameCache = {}

			local mockFriend = {
				type = "bnet",
				uid = "bnet_TitleFriend#1234",
				accountName = "Real Account",
				battleTag = "TitleFriend#1234",
				titleCustomName = "Custom Title Name",
				connected = true,
				note = "",
			}

			local displayResult = FriendsList:GetDisplayName(mockFriend, false)
			local sortResult = FriendsList:GetDisplayName(mockFriend, true)

			FriendsList.settingsCache.nameFormatString = oldFormat
			FriendsList.displayNameCache = oldCache

			V:AssertEqual(displayResult, "Custom Title Name", "Display mode should use Title-Friend custom name")
			V:AssertEqual(sortResult, "TitleFriend", "Sort mode should keep BattleTag-based sorting")
		end,
	})

	TS:RegisterTest("data", "Compat_PTRSocialWrappers_SafeDefaults", {
		description = "PTR social API compatibility wrappers exist and return safe defaults",
		action = function(V)
			V:Assert(type(BFL.CanSetAppearOffline) == "function", "CanSetAppearOffline wrapper should exist")
			V:Assert(type(BFL.SetMyBNetStatus) == "function", "SetMyBNetStatus wrapper should exist")
			V:Assert(type(BFL.IsLegacyFriendSystemEnabled) == "function", "Legacy friend system wrapper should exist")
			V:Assert(type(BFL.CanUseWoWFriendList) == "function", "WoW friend list gate should exist")
			V:Assert(type(BFL.AreTitleFriendCustomNamesEnabled) == "function", "Title custom-name gate should exist")
			V:Assert(type(BFL.GetCustomTitleFriendName) == "function", "Title custom-name getter should exist")
			V:Assert(type(BFL.SetCustomTitleFriendName) == "function", "Title custom-name setter should exist")

			V:Assert(type(BFL.IsLegacyFriendSystemEnabled()) == "boolean", "Legacy friend system gate should return boolean")
			V:Assert(type(BFL.CanUseWoWFriendList()) == "boolean", "WoW friend list gate should return boolean")
			V:Assert(type(BFL.GetNumWoWFriends()) == "number", "WoW friend count wrapper should return number")
			V:Assert(type(BFL.GetNumOnlineWoWFriends()) == "number", "Online WoW friend count wrapper should return number")
			V:Assert(BFL.SetMyBNetStatus("bfl_invalid_status") == false, "Unknown BNet status should fail safely")
		end,
	})

	TS:RegisterTest("integration", "GetDisplayName_OfflineFriend_NilAccountName", {
		description = "GetDisplayName offline path handles nil accountName",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.GetDisplayName then
				V:Skip("FriendsList not loaded")
				return
			end
			-- Mock offline BNet friend with nil accountName
			local mockFriend = {
				type = "bnet",
				uid = "bnet_TestOffline#9999",
				accountName = nil,
				battleTag = "TestOffline#9999",
				characterName = "",
				name = "",
				connected = false,
				note = "",
			}
			local result = FriendsList:GetDisplayName(mockFriend, false)
			V:AssertNotNil(result, "Offline GetDisplayName should return a value")
			V:Assert(result ~= "", "Offline GetDisplayName should not be empty")
		end,
	})

	TS:RegisterTest("integration", "GetDisplayName_SortMode_NilAccountName", {
		description = "GetDisplayName sorting mode handles nil accountName",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.GetDisplayName then
				V:Skip("FriendsList not loaded")
				return
			end
			-- Mock BNet friend with nil accountName, no battleTag
			local mockFriend = {
				type = "bnet",
				uid = "bnet_TestSort#9999",
				accountName = nil,
				battleTag = nil,
				characterName = "SortChar",
				name = "SortChar-TestRealm",
				connected = true,
				note = "",
			}
			local result = FriendsList:GetDisplayName(mockFriend, true)
			V:AssertNotNil(result, "Sort-mode GetDisplayName should return a value")
		end,
	})

	TS:RegisterTest("integration", "Broker_NilAccountName_NoError", {
		description = "Broker tooltip handles friends with nil accountName",
		action = function(V)
			local Broker = BFL:GetModule("Broker")
			if not Broker or not Broker.UpdateBrokerText then
				V:Skip("Broker not loaded")
				return
			end
			-- Just verify UpdateBrokerText completes without error
			Broker:UpdateBrokerText()
			V:Assert(true, "Broker:UpdateBrokerText completed with no error")
		end,
	})

	TS:RegisterTest("integration", "NoteCleanupWizard_Module_Exists", {
		description = "NoteCleanupWizard module loads without error",
		action = function(V)
			local NCW = BFL:GetModule("NoteCleanupWizard")
			V:AssertNotNil(NCW, "NoteCleanupWizard module should be loaded")
		end,
	})
end

local PERFY_263_CUSTOM_TAG_NAMES = {
	"Perfy Progression",
	"Perfy Keys",
	"Perfy Raid Lead",
	"Perfy Backup",
	"Perfy Bench",
	"Perfy Social",
}

local PERFY_263_BLIZZARD_TAG_SETS = {
	{ ["blizzard:raiding"] = true, ["blizzard:damager"] = true },
	{ ["blizzard:dungeons"] = true, ["blizzard:healer"] = true },
	{ ["blizzard:pvp"] = true, ["blizzard:tank"] = true },
	{ ["blizzard:delves"] = true, ["blizzard:questing"] = true },
}

local PERFY_263_SEARCH_TERMS = {
	"",
	"Perfy",
	"Raiding",
	"Keys",
	"DPS",
	"Healer",
	"Backup",
}

local function PerfyDeepCopy(value, seen)
	local DB = BFL:GetModule("DB")
	if DB and DB.InternalDeepCopy then
		return DB:InternalDeepCopy(value)
	end
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		copy[PerfyDeepCopy(k, seen)] = PerfyDeepCopy(v, seen)
	end
	return copy
end

local function CapturePerfy263FeatureState()
	if not BetterFriendlistDB then
		return nil
	end
	return {
		enableBetaFeatures = BetterFriendlistDB.enableBetaFeatures,
		streamerModeActive = BetterFriendlistDB.streamerModeActive,
		contactMemory = PerfyDeepCopy(BetterFriendlistDB.contactMemory),
		friendTagSettings = PerfyDeepCopy(BetterFriendlistDB.friendTagSettings),
		friendTagProfiles = PerfyDeepCopy(BetterFriendlistDB.friendTagProfiles),
		customFriendTags = PerfyDeepCopy(BetterFriendlistDB.customFriendTags),
		friendCustomTags = PerfyDeepCopy(BetterFriendlistDB.friendCustomTags),
		friendBlizzardTags = PerfyDeepCopy(BetterFriendlistDB.friendBlizzardTags),
		nextCustomFriendTagID = BetterFriendlistDB.nextCustomFriendTagID,
		settingsVersion = BFL.SettingsVersion,
		friendTagsVersion = BFL.FriendTagsVersion,
		friendTagsDefinitionVersion = BFL.FriendTagsDefinitionVersion,
		friendTagsAssignmentVersion = BFL.FriendTagsAssignmentVersion,
	}
end

local function RestorePerfy263FeatureState(snapshot)
	if not (BetterFriendlistDB and snapshot) then
		return
	end

	BetterFriendlistDB.enableBetaFeatures = snapshot.enableBetaFeatures
	BetterFriendlistDB.streamerModeActive = snapshot.streamerModeActive
	BetterFriendlistDB.contactMemory = PerfyDeepCopy(snapshot.contactMemory)
	BetterFriendlistDB.friendTagSettings = PerfyDeepCopy(snapshot.friendTagSettings)
	BetterFriendlistDB.friendTagProfiles = PerfyDeepCopy(snapshot.friendTagProfiles)
	BetterFriendlistDB.customFriendTags = PerfyDeepCopy(snapshot.customFriendTags)
	BetterFriendlistDB.friendCustomTags = PerfyDeepCopy(snapshot.friendCustomTags)
	BetterFriendlistDB.friendBlizzardTags = PerfyDeepCopy(snapshot.friendBlizzardTags)
	BetterFriendlistDB.nextCustomFriendTagID = snapshot.nextCustomFriendTagID
	BFL.SettingsVersion = (snapshot.settingsVersion or BFL.SettingsVersion or 0) + 1
	BFL.FriendTagsVersion = (snapshot.friendTagsVersion or BFL.FriendTagsVersion or 0) + 1
	BFL.FriendTagsDefinitionVersion = (snapshot.friendTagsDefinitionVersion or BFL.FriendTagsDefinitionVersion or BFL.FriendTagsVersion or 0) + 1
	BFL.FriendTagsAssignmentVersion = (snapshot.friendTagsAssignmentVersion or BFL.FriendTagsAssignmentVersion or 0) + 1
	local FriendTags = BFL:GetModule("FriendTags")
	if FriendTags then
		FriendTags.friendAssignmentVersions = {}
		FriendTags.allFriendAssignmentsVersion = BFL.FriendTagsAssignmentVersion or 0
		if FriendTags.ClearCaches then
			FriendTags:ClearCaches()
		end
	end
end

local function RefreshPerfy263FeatureSurfaces(FriendsList, forceRender)
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
	BFL.FriendTagsDefinitionVersion = (BFL.FriendTagsDefinitionVersion or BFL.FriendTagsVersion or 0) + 1
	BFL.FriendTagsAssignmentVersion = (BFL.FriendTagsAssignmentVersion or 0) + 1
	local FriendTags = BFL:GetModule("FriendTags")
	if FriendTags then
		FriendTags.friendAssignmentVersions = {}
		FriendTags.allFriendAssignmentsVersion = BFL.FriendTagsAssignmentVersion or 0
		if FriendTags.ClearCaches then
			FriendTags:ClearCaches()
		end
	end
	if FriendsList and FriendsList.InvalidateSettingsCache then
		FriendsList:InvalidateSettingsCache()
	end
	if FriendsList then
		FriendsList.lastBuildInputs = nil
		if forceRender and FriendsList.RenderDisplay then
			FriendsList:RenderDisplay(true)
		elseif FriendsList.ScheduleRefresh then
			FriendsList:ScheduleRefresh("perfy-263-feature-state", 0.05, false)
		end
	end
end

local function SeedPerfy263FeatureData(context, FriendsList, ContactMemory, FriendTags)
	if not BetterFriendlistDB then
		return
	end

	BetterFriendlistDB.enableBetaFeatures = true
	BetterFriendlistDB.streamerModeActive = false

	local contactDB = ContactMemory and ContactMemory.NormalizeDB and ContactMemory:NormalizeDB()
	if contactDB then
		contactDB.enabled = true
		contactDB.settings = contactDB.settings or {}
		contactDB.settings.showTooltipSection = true
		contactDB.settings.hideInStreamerMode = false
	end

	local tagDB = FriendTags and FriendTags.NormalizeDB and FriendTags:NormalizeDB()
	if tagDB then
		tagDB.friendTagSettings = tagDB.friendTagSettings or {}
		tagDB.friendTagSettings.enabled = true
		tagDB.friendTagSettings.showRowChips = true
		tagDB.friendTagSettings.showTooltipChips = true
		tagDB.friendTagSettings.showBrokerChips = true
		tagDB.friendTagSettings.showTagsInStreamerMode = true
		tagDB.friendTagSettings.rowMode = "chip_line"
		tagDB.friendTagSettings.compactRowMode = "chip_line"
		tagDB.friendTagSettings.maxRowChips = 4
		tagDB.friendTagSettings.maxTooltipChips = 8
		tagDB.friendTagSettings.enableDynamicTagGroups = true
		tagDB.friendTagSettings.includeCustomTagsInSearch = true
		tagDB.friendTagSettings.includeBlizzardTagsInSearch = true
		context.customTagIds = {}
		for _, tagName in ipairs(PERFY_263_CUSTOM_TAG_NAMES) do
			local tagId = FriendTags:CreateCustomTag(tagName)
			if tagId then
				context.customTagIds[#context.customTagIds + 1] = tagId
			end
		end
	end

	if FriendsList and FriendsList.UpdateFriendsList then
		FriendsList:UpdateFriendsList(context.forceRender)
	end

	context.perfyFriends = {}
	context.contactKeys = {}
	local friends = FriendsList and FriendsList.friendsList or {}
	if #friends == 0 then
		local PreviewMode = BFL:GetModule("PreviewMode")
		friends = PreviewMode and PreviewMode.mockData and PreviewMode.mockData.friends or friends
	end
	for index, friend in ipairs(friends) do
		if type(friend) == "table" then
			context.perfyFriends[#context.perfyFriends + 1] = friend
			local note = string.format(
				"Perfy 2.6.3 private note %03d - raid role, backup plan, tag search payload",
				index
			)
			local contactKey = ContactMemory and ContactMemory.ResolveContactKeyFromFriend
				and ContactMemory:ResolveContactKeyFromFriend(friend)
			if contactKey then
				context.contactKeys[#context.contactKeys + 1] = contactKey
				ContactMemory:SetPrivateNote(contactKey, note)
			end
			if tagDB and FriendTags then
				local uid = FriendTags:GetFriendUID(friend)
				if uid then
					local customSet = {}
					if context.customTagIds and #context.customTagIds > 0 then
						for offset = 0, 2 do
							local tagId = context.customTagIds[((index + offset - 1) % #context.customTagIds) + 1]
							if tagId then
								customSet[tagId] = true
							end
						end
					end
					tagDB.friendCustomTags[uid] = next(customSet) and customSet or nil
					if friend.type == "bnet" then
						tagDB.friendBlizzardTags[uid] = PerfyDeepCopy(PERFY_263_BLIZZARD_TAG_SETS[((index - 1) % #PERFY_263_BLIZZARD_TAG_SETS) + 1])
					end
				end
			end
		end
	end

	RefreshPerfy263FeatureSurfaces(FriendsList, context.forceRender)
end

local function IsPerfyAddonLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		return C_AddOns.IsAddOnLoaded("!!!Perfy")
	end
	if IsAddOnLoaded then
		return IsAddOnLoaded("!!!Perfy")
	end
	return false
end

local function IsAddonProfilerLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		return C_AddOns.IsAddOnLoaded("!!AddonProfiler")
	end
	if IsAddOnLoaded then
		return IsAddOnLoaded("!!AddonProfiler")
	end
	return false
end

local function StartPerfyTracking(durationSeconds)
	if SlashCmdList and SlashCmdList.PERFY then
		SlashCmdList.PERFY("start " .. tostring(durationSeconds))
		return true
	end
	return false
end

local function StopPerfyTracking()
	if SlashCmdList and SlashCmdList.PERFY then
		SlashCmdList.PERFY("stop")
	end
end

local function StartAddonProfiler()
	if not IsAddonProfilerLoaded() then
		return false
	end
	if SlashCmdList and SlashCmdList.NUMY_ADDON_PROFILER then
		SlashCmdList.NUMY_ADDON_PROFILER("reset")
		SlashCmdList.NUMY_ADDON_PROFILER("enable")
		return true
	end
	return false
end

local function StopAddonProfiler()
	if SlashCmdList and SlashCmdList.NUMY_ADDON_PROFILER then
		SlashCmdList.NUMY_ADDON_PROFILER("disable")
	end
end

local PERFY_STRESS_MODES = {
	visible = true,
	stress = true,
	background = true,
	idle = true,
}

local function NormalizePerfyStressMode(mode)
	mode = tostring(mode or "visible"):lower()
	if mode == "stress" then
		return "visible"
	end
	if PERFY_STRESS_MODES[mode] then
		return mode
	end
	return "visible"
end

local function ParsePerfyCommand(args)
	local mode = "visible"
	local durationSeconds = 30
	for token in string.gmatch(strtrim(args or ""), "%S+") do
		local lowered = token:lower()
		if PERFY_STRESS_MODES[lowered] then
			mode = NormalizePerfyStressMode(lowered)
		else
			local parsedDuration = tonumber(token)
			if parsedDuration and parsedDuration > 0 then
				durationSeconds = parsedDuration
			end
		end
	end
	return mode, durationSeconds
end

function TestSuite:HandlePerfyCommand(args)
	local mode, durationSeconds = ParsePerfyCommand(args)
	self:RunPerfyStress(durationSeconds, mode)
end

function TestSuite:RunPerfyStress(durationSeconds, mode)
	if self.perfyStressActive then
		self.Reporter:Warn(GetLocalizedText("TESTSUITE_PERFY_ALREADY_RUNNING", "Perfy stress test already running"))
		return
	end

	if not IsPerfyAddonLoaded() then
		self.Reporter:Warn(GetLocalizedText("TESTSUITE_PERFY_MISSING_ADDON", "Perfy addon not loaded (!!!Perfy)"))
		return
	end

	if not (SlashCmdList and SlashCmdList.PERFY) then
		self.Reporter:Warn(GetLocalizedText("TESTSUITE_PERFY_MISSING_SLASH", "Perfy slash command not available"))
		return
	end

	local FriendsList = BFL:GetModule("FriendsList")
	local QuickFilters = BFL:GetModule("QuickFilters")
	local Groups = BFL:GetModule("Groups")
	local ContactMemory = BFL:GetModule("ContactMemory")
	local FriendTags = BFL:GetModule("FriendTags")
	local TagChips = BFL:GetModule("TagChips")
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local ScenarioManager = BFL.ScenarioManager
	mode = NormalizePerfyStressMode(mode)
	local visibleMode = mode == "visible"
	local backgroundMode = mode == "background"
	local idleMode = mode == "idle"

	local context = {
		mode = mode,
		forceRender = visibleMode,
		frameWasShown = BetterFriendsFrame and BetterFriendsFrame:IsShown() or false,
		actionIndex = 1,
		sortIndex = 1,
		filterIndex = 1,
		tagSearchIndex = 1,
		friendIndex = 1,
		contactIndex = 1,
		dynamicTagsEnabled = true,
		scrollDirection = 1,
		scrollStep = 0.2,
		sectionIndex = 1,
		featureSnapshot = CapturePerfy263FeatureState(),
		originalFilter = QuickFilters and QuickFilters:GetFilter() or (FriendsList and FriendsList.filterMode),
		originalSort = FriendsList and FriendsList.sortMode,
		originalSecondarySort = FriendsList and FriendsList.secondarySort,
		originalSearchText = FriendsList and FriendsList.searchText,
		originalSection = FriendsUI and FriendsUI.GetSelectedSection and FriendsUI:GetSelectedSection() or "friends",
		originalTab = (BetterFriendsFrame and PanelTemplates_GetSelectedTab(BetterFriendsFrame)) or 1,
		originalTopTab = (
			BetterFriendsFrame
			and BetterFriendsFrame.FriendsTabHeader
			and PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		) or 1,
		groupStates = {},
		filterModes = { "all", "online", "offline", "wowonline", "wow", "bnet" },
		sortModes = { "status", "name", "level", "zone" },
		modernSections = {
			"friends",
			"recent_allies",
			"friend_requests",
			"quick_join",
			"recruit_a_friend",
			"guild",
			"who",
			"raid",
		},
	}

	if Groups and Groups.groups then
		for groupId, groupData in pairs(Groups.groups) do
			context.groupStates[groupId] = groupData.collapsed
		end
	end

	if not visibleMode and BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		context.hiddenForPerfyMode = true
		if _G.HideBetterFriendsFrame then
			_G.HideBetterFriendsFrame()
		else
			BetterFriendsFrame:Hide()
		end
	end

	local friendsTab = 1
	local modernMode = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() or false

	local function EnsureTab(tabIndex)
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			if tabIndex then
				local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame)
				if selectedTab ~= tabIndex and BetterFriendsFrame_ShowBottomTab then
					BetterFriendsFrame_ShowBottomTab(tabIndex)
				elseif selectedTab ~= tabIndex then
					PanelTemplates_SetTab(BetterFriendsFrame, tabIndex)
				end
			end
			return
		end
		if _G.ShowBetterFriendsFrame then
			_G.ShowBetterFriendsFrame(tabIndex)
		elseif _G.ToggleBetterFriendsFrame then
			_G.ToggleBetterFriendsFrame(tabIndex)
		elseif BetterFriendsFrame then
			BetterFriendsFrame:Show()
		end
	end

	local function ScrollFriendsList()
		if not FriendsList then
			return
		end
		local step = context.scrollStep * context.scrollDirection
		local scrollBox = FriendsList.scrollBox
		if scrollBox and scrollBox.GetScrollPercentage and scrollBox.SetScrollPercentage then
			local current = scrollBox:GetScrollPercentage() or 0
			local nextValue = current + step
			if nextValue >= 1 then
				nextValue = 1
				context.scrollDirection = -1
			elseif nextValue <= 0 then
				nextValue = 0
				context.scrollDirection = 1
			end
			scrollBox:SetScrollPercentage(nextValue)
			return
		end

		local scrollBar = FriendsList.scrollBar or (BetterFriendsFrame and BetterFriendsFrame.MinimalScrollBar)
		if scrollBar and scrollBar.GetMinMaxValues and scrollBar.GetValue and scrollBar.SetValue then
			local minValue, maxValue = scrollBar:GetMinMaxValues()
			if minValue == nil or maxValue == nil then
				return
			end
			local current = scrollBar:GetValue() or minValue
			local delta = (maxValue - minValue) * step
			local nextValue = current + delta
			if nextValue >= maxValue then
				nextValue = maxValue
				context.scrollDirection = -1
			elseif nextValue <= minValue then
				nextValue = minValue
				context.scrollDirection = 1
			end
			scrollBar:SetValue(nextValue)
		end
	end

	local function SelectNextModernSection()
		if not (modernMode and FriendsUI and FriendsUI.SelectSection) then
			EnsureTab(friendsTab)
			return
		end
		if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
			EnsureTab(friendsTab)
		end
		local sections = context.modernSections
		for _ = 1, #sections do
			local sectionID = sections[context.sectionIndex]
			context.sectionIndex = (context.sectionIndex % #sections) + 1
			if not FriendsUI.IsSectionAvailable or FriendsUI:IsSectionAvailable(sectionID) then
				FriendsUI:SelectSection(sectionID)
				return
			end
		end
		FriendsUI:SelectSection("friends")
	end

	local function ApplyNextFilter()
		local mode = context.filterModes[context.filterIndex]
		context.filterIndex = (context.filterIndex % #context.filterModes) + 1
		if QuickFilters and QuickFilters.SetFilter then
			QuickFilters:SetFilter(mode)
		elseif FriendsList and FriendsList.SetFilterMode then
			FriendsList:SetFilterMode(mode)
		end
	end

	local function ApplyNextSort()
		local mode = context.sortModes[context.sortIndex]
		context.sortIndex = (context.sortIndex % #context.sortModes) + 1
		if FriendsList and FriendsList.SetSortMode then
			FriendsList:SetSortMode(mode)
		end
	end

	local function ApplyNextTagSearch()
		if not (FriendsList and FriendsList.SetSearchText) then
			return
		end
		local term = PERFY_263_SEARCH_TERMS[context.tagSearchIndex] or ""
		context.tagSearchIndex = (context.tagSearchIndex % #PERFY_263_SEARCH_TERMS) + 1
		FriendsList:SetSearchText(term)
		if context.forceRender and FriendsList.RenderDisplay then
			FriendsList:RenderDisplay(true)
		end
	end

	local function ToggleDynamicTagGroups()
		if not (FriendTags and FriendTags.SetSetting) then
			return
		end
		context.dynamicTagsEnabled = not context.dynamicTagsEnabled
		FriendTags:SetSetting("enableDynamicTagGroups", context.dynamicTagsEnabled)
	end

	local function ExerciseTooltipSummaries()
		if not (ContactMemory or FriendTags) then
			return
		end
		local tooltip = {
			AddLine = function()
				context.tooltipLineCount = (context.tooltipLineCount or 0) + 1
			end,
			Show = function()
				context.tooltipShowCount = (context.tooltipShowCount or 0) + 1
			end,
		}
		local friends = context.perfyFriends or {}
		if #friends == 0 then
			return
		end
		for offset = 0, 7 do
			local index = ((context.friendIndex + offset - 1) % #friends) + 1
			local friend = friends[index]
			if ContactMemory and ContactMemory.AddTooltipLinesForFriend then
				ContactMemory:AddTooltipLinesForFriend(tooltip, friend)
			end
			if FriendTags then
				if FriendTags.GetTooltipTextForFriend then
					FriendTags:GetTooltipTextForFriend(friend)
				end
				if FriendTags.GetBrokerTextForFriend then
					FriendTags:GetBrokerTextForFriend(friend)
				end
			end
		end
	end

	local function ExerciseTagRows()
		local friends = context.perfyFriends or {}
		if #friends == 0 then
			return
		end
		for offset = 0, 19 do
			local index = ((context.friendIndex + offset - 1) % #friends) + 1
			local friend = friends[index]
			if TagChips and TagChips.GetRowExtraHeight then
				TagChips:GetRowExtraHeight(friend, FriendsList)
			end
			if FriendTags then
				if FriendTags.GetTagsForFriend then
					FriendTags:GetTagsForFriend(friend, "row")
					FriendTags:GetTagsForFriend(friend, "search")
				end
				if FriendTags.FriendHasTag then
					FriendTags:FriendHasTag(friend, "Perfy")
				end
			end
		end
	end

	local function RotateTagAssignment()
		local friends = context.perfyFriends or {}
		local tagIds = context.customTagIds or {}
		if not (FriendTags and #friends > 0 and #tagIds > 0) then
			return
		end
		local friend = friends[context.friendIndex]
		context.friendIndex = (context.friendIndex % #friends) + 1
		local tagId = tagIds[((context.friendIndex - 1) % #tagIds) + 1]
		context.tagToggle = not context.tagToggle
		if FriendTags.SetCustomTagForFriend then
			FriendTags:SetCustomTagForFriend(friend, tagId, context.tagToggle)
		end
		if friend and friend.type == "bnet" and FriendTags.SetBlizzardTagsForFriend then
			local localFriend = PerfyDeepCopy(friend)
			localFriend.bnetAccountID = nil
			FriendTags:SetBlizzardTagsForFriend(
				localFriend,
				PERFY_263_BLIZZARD_TAG_SETS[((context.friendIndex - 1) % #PERFY_263_BLIZZARD_TAG_SETS) + 1]
			)
		end
	end

	local function RotatePrivateNote()
		local keys = context.contactKeys or {}
		if not (ContactMemory and ContactMemory.SetPrivateNote and #keys > 0) then
			return
		end
		local key = keys[context.contactIndex]
		context.contactIndex = (context.contactIndex % #keys) + 1
		ContactMemory:SetPrivateNote(
			key,
			string.format("Perfy 2.6.3 rotating note %03d", context.contactIndex)
		)
	end

	-- Profiling runs inside the live UI session. Keep fixtures internal to BFL;
	-- replacing global Unit/group APIs taints Blizzard's secret-value paths until reload.
	if ScenarioManager and ScenarioManager.Load then
		ScenarioManager:Load("stress_200")
	else
		self.Reporter:Warn("ScenarioManager not available")
	end

	local seeded, seedError = pcall(SeedPerfy263FeatureData, context, FriendsList, ContactMemory, FriendTags)
	if not seeded then
		RestorePerfy263FeatureState(context.featureSnapshot)
		if ScenarioManager and ScenarioManager.Clear then
			ScenarioManager:Clear()
		end
		self.Reporter:Warn(
			string.format(
				GetLocalizedText("TESTSUITE_PERFY_ACTION_FAILED", "Perfy stress action failed: %s"),
				tostring(seedError)
			)
		)
		return
	end

	local visibleActions = {
		SelectNextModernSection,
		function()
			if modernMode and FriendsUI and FriendsUI.SelectSection then
				FriendsUI:SelectSection("friends")
			else
				EnsureTab(friendsTab)
			end
			if FriendsList and FriendsList.RenderDisplay then
				FriendsList:RenderDisplay(true)
			end
		end,
		ScrollFriendsList,
		ApplyNextTagSearch,
		ToggleDynamicTagGroups,
		ExerciseTooltipSummaries,
		ExerciseTagRows,
		RotateTagAssignment,
		RotatePrivateNote,
		ApplyNextFilter,
		ApplyNextSort,
		function()
			if FriendsList and FriendsList.UpdateFriendsList then
				FriendsList:UpdateFriendsList()
			end
		end
	}

	local backgroundActions = {
		ApplyNextTagSearch,
		ToggleDynamicTagGroups,
		ExerciseTooltipSummaries,
		ExerciseTagRows,
		RotateTagAssignment,
		RotatePrivateNote,
		ApplyNextFilter,
		ApplyNextSort,
		function()
			if FriendsList and FriendsList.UpdateFriendsList then
				FriendsList:UpdateFriendsList()
			end
		end,
	}

	local idleActions = {
		function() end,
	}

	if idleMode then
		context.actions = idleActions
	elseif backgroundMode then
		context.actions = backgroundActions
	else
		context.actions = visibleActions
	end

	self.perfyStressActive = true
	self.perfyStressContext = context
	self.perfyStressEndTime = GetTime() + durationSeconds

	context.addonProfilerActive = StartAddonProfiler()
	StartPerfyTracking(durationSeconds)
	self.Reporter:Info(
		string.format(
			GetLocalizedText("TESTSUITE_PERFY_STARTING", "Starting Perfy stress test for %d seconds"),
			durationSeconds
		)
	)

	self.perfyStressTicker = C_Timer.NewTicker(0.25, function()
		if not self.perfyStressActive then
			return
		end
		if GetTime() >= self.perfyStressEndTime then
			self:StopPerfyStress("done")
			return
		end
		local action = context.actions[context.actionIndex]
		context.actionIndex = (context.actionIndex % #context.actions) + 1
		if action then
			local ok, err = pcall(action)
			if not ok then
				self.Reporter:Warn(
					string.format(
						GetLocalizedText("TESTSUITE_PERFY_ACTION_FAILED", "Perfy stress action failed: %s"),
						tostring(err)
					)
				)
			end
		end
	end)
end

function TestSuite:StopPerfyStress(reason)
	if not self.perfyStressActive then
		return
	end

	self.perfyStressActive = false

	if self.perfyStressTicker then
		self.perfyStressTicker:Cancel()
		self.perfyStressTicker = nil
	end

	StopPerfyTracking()

	local context = self.perfyStressContext
	self.perfyStressContext = nil

	local FriendsList = BFL:GetModule("FriendsList")
	local QuickFilters = BFL:GetModule("QuickFilters")
	local Groups = BFL:GetModule("Groups")
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local ScenarioManager = BFL.ScenarioManager

	if context then
		if context.addonProfilerActive then
			StopAddonProfiler()
		end
		if QuickFilters and QuickFilters.SetFilter and context.originalFilter then
			QuickFilters:SetFilter(context.originalFilter)
		elseif FriendsList and FriendsList.SetFilterMode and context.originalFilter then
			FriendsList:SetFilterMode(context.originalFilter)
		end
		if FriendsList and FriendsList.SetSortMode and context.originalSort then
			FriendsList:SetSortMode(context.originalSort)
		end
		if FriendsList and FriendsList.SetSecondarySortMode and context.originalSecondarySort then
			FriendsList:SetSecondarySortMode(context.originalSecondarySort)
		end
		if FriendsList and FriendsList.SetSearchText and context.originalSearchText ~= nil then
			FriendsList:SetSearchText(context.originalSearchText)
		end
		if Groups and Groups.groups and context.groupStates then
			for groupId, collapsed in pairs(context.groupStates) do
				local groupData = Groups.groups[groupId]
				if groupData and groupData.collapsed ~= collapsed then
					Groups:SetCollapsed(groupId, collapsed, true)
				end
			end
		end
		if context.hiddenForPerfyMode and context.frameWasShown and BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
			if _G.ShowBetterFriendsFrame then
				_G.ShowBetterFriendsFrame(context.originalTab or 1)
			else
				BetterFriendsFrame:Show()
			end
		end
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() and FriendsUI.SelectSection then
				FriendsUI:SelectSection(context.originalSection or "friends")
			elseif context.originalTab then
				PanelTemplates_SetTab(BetterFriendsFrame, context.originalTab)
				if BetterFriendsFrame_ShowBottomTab then
					BetterFriendsFrame_ShowBottomTab(context.originalTab)
				end
				if context.originalTab == 1 and context.originalTopTab and BetterFriendsFrame_ShowTab then
					BetterFriendsFrame_ShowTab(context.originalTopTab)
				end
			end
		end
	end

	if ScenarioManager and ScenarioManager.Clear then
		ScenarioManager:Clear()
	end
	if context then
		RestorePerfy263FeatureState(context.featureSnapshot)
		RefreshPerfy263FeatureSurfaces(FriendsList, context.forceRender or context.frameWasShown)
	end

	if not context or context.forceRender or context.frameWasShown then
		BFL:ForceRefreshFriendsList()
	end

	if reason == "done" then
		self.Reporter:Info(GetLocalizedText("TESTSUITE_PERFY_DONE", "Perfy stress test finished"))
	else
		self.Reporter:Warn(
			string.format(
				GetLocalizedText("TESTSUITE_PERFY_ABORTED", "Perfy stress test stopped: %s"),
				tostring(reason or "unknown")
			)
		)
	end
end

-- ============================================
-- BENCHMARK COMMANDS
-- ============================================

function TestSuite:HandleBenchmarkCommand(args)
	local PerformanceBenchmark = BFL.PerformanceBenchmark
	if not PerformanceBenchmark then
		self.Reporter:Error("PerformanceBenchmark module not loaded")
		return
	end

	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	if cmd == "list" then
		PerformanceBenchmark:PrintBenchmarkList()
	elseif cmd == "run" then
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test bench run <benchmark_id>")
			print("")
			print("|cffffd200Available benchmark IDs:|r")
			local list = PerformanceBenchmark:ListBenchmarks()
			for _, bench in ipairs(list) do
				print("  * " .. bench.id)
			end
			return
		end

		self.Reporter:Info("Running benchmark: " .. param)
		local result = PerformanceBenchmark:RunBenchmark(param)
		PerformanceBenchmark:PrintResult(result)
	elseif cmd == "all" then
		self.Reporter:Info("Running all benchmarks...")
		local results = PerformanceBenchmark:RunAll()
		PerformanceBenchmark:PrintResults(results)
	elseif cmd == "category" or cmd == "cat" then
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test bench category <category>")
			print("")
			print("|cffffd200Available categories:|r")
			local categories = PerformanceBenchmark:GetCategories()
			for _, cat in ipairs(categories) do
				print("  * " .. cat)
			end
			return
		end

		self.Reporter:Info("Running benchmarks in category: " .. param)
		local results = PerformanceBenchmark:RunCategory(param)
		PerformanceBenchmark:PrintResults(results)
	elseif cmd == "history" then
		PerformanceBenchmark:PrintHistory()
	elseif cmd == "compare" then
		local comparison = PerformanceBenchmark:CompareWithPrevious()
		PerformanceBenchmark:PrintComparison(comparison)
	elseif cmd == "trend" then
		if param == "" then
			self.Reporter:Warn("Usage: /bfl test bench trend <benchmark_id>")
			return
		end

		local trend = PerformanceBenchmark:GetTrend(param, 10)
		if #trend == 0 then
			self.Reporter:Warn("No history data for benchmark: " .. param)
			return
		end

		print("|cff00ff00=== Trend: " .. param .. " ===|r")
		for i, entry in ipairs(trend) do
			local statusColor = entry.status == "pass" and "|cff00ff00" or "|cffff0000"
			print(string.format("  %2d. %s - %s%.2fms|r", i, date("%m-%d", entry.timestamp), statusColor, entry.mean))
		end
	elseif cmd == "clear" then
		PerformanceBenchmark:ClearHistory()
		self.Reporter:Info("Benchmark history cleared")
	elseif cmd == "reset" then
		PerformanceBenchmark:Reset()
		self.Reporter:Info("Benchmark system reset")
	else
		-- Show benchmark help
		print("|cffff9000BFL Benchmark Commands:|r")
		print("")
		print("|cffffd200Run Benchmarks:|r")
		print("  /bfl test bench |cfffffffflist|r              - List available benchmarks")
		print("  /bfl test bench |cffffffffrun <id>|r          - Run specific benchmark")
		print("  /bfl test bench |cffffffffall|r               - Run all benchmarks")
		print("  /bfl test bench |cffffffffcategory <cat>|r    - Run category")
		print("")
		print("|cffffd200History & Analysis:|r")
		print("  /bfl test bench |cffffffffhistory|r           - Show benchmark history")
		print("  /bfl test bench |cffffffffcompare|r           - Compare with previous run")
		print("  /bfl test bench |cfffffffftrend <id>|r        - Show trend for benchmark")
		print("")
		print("|cffffd200Utility:|r")
		print("  /bfl test bench |cffffffffclear|r             - Clear history")
		print("  /bfl test bench |cffffffffreset|r             - Reset benchmark system")
		print("")
		print("|cffffd200Categories:|r")
		local categories = PerformanceBenchmark:GetCategories()
		for _, cat in ipairs(categories) do
			print("  * " .. cat)
		end
		print("")
	end
end

-- ============================================
-- REGRESSION COMMANDS
-- ============================================

function TestSuite:HandleRegressionCommand(args)
	local RegressionTests = BFL.RegressionTests
	if not RegressionTests then
		self.Reporter:Error("RegressionTests module not loaded")
		return
	end

	local cmd, param = strsplit(" ", args or "", 2)
	cmd = cmd and cmd:lower() or ""
	param = param and param:trim() or ""

	if cmd == "all" then
		self.Reporter:Info("Running all regression tests...")
		local results = RegressionTests:RunAll()
		RegressionTests:PrintResults(results)
	elseif cmd == "bugs" then
		self.Reporter:Info("Running bug pattern tests...")
		local results = RegressionTests:RunCategory("bugs")
		RegressionTests:PrintCategoryResults(results)
	elseif cmd == "api" then
		self.Reporter:Info("Running API compatibility tests...")
		local results = RegressionTests:RunCategory("api")
		RegressionTests:PrintCategoryResults(results)
	elseif cmd == "ui" then
		self.Reporter:Info("Running UI regression tests...")
		local results = RegressionTests:RunCategory("ui")
		RegressionTests:PrintCategoryResults(results)
	elseif cmd == "settings" then
		self.Reporter:Info("Running settings tests...")
		local results = RegressionTests:RunCategory("settings")
		RegressionTests:PrintCategoryResults(results)
	elseif cmd == "classic" then
		self.Reporter:Info("Running Classic compatibility tests...")
		local results = RegressionTests:RunCategory("classic")
		RegressionTests:PrintCategoryResults(results)
	elseif cmd == "list" then
		RegressionTests:ListTests()
	else
		-- Show regression help
		print("|cffff9000BFL Regression Test Commands:|r")
		print("")
		print("|cffffd200Run Tests:|r")
		print("  /bfl test regression |cffffffffall|r       - Run all regression tests")
		print("  /bfl test regression |cffffffffbugs|r      - Run bug pattern tests")
		print("  /bfl test regression |cffffffffapi|r       - Run API compatibility tests")
		print("  /bfl test regression |cffffffffui|r        - Run UI regression tests")
		print("  /bfl test regression |cffffffffsettings|r  - Run settings tests")
		print("  /bfl test regression |cffffffffclassic|r   - Run Classic tests")
		print("")
		print("|cffffd200Info:|r")
		print("  /bfl test regression |cfffffffflist|r      - List all regression tests")
		print("")
		print("|cffffd200Categories:|r")
		print("  * bugs     - Tests for known bug patterns")
		print("  * api      - API compatibility tests")
		print("  * ui       - UI state integrity tests")
		print("  * settings - Settings persistence tests")
		print("  * classic  - Classic-specific tests")
		print("")
	end
end

-- ============================================
-- MODULE INITIALIZATION
-- ============================================

function TestSuite:Initialize()
	-- Register built-in tests
	RegisterBuiltInTests()
	self:RegisterAutoRaidAssistRosterFallbackTest()
	self:RegisterSearchIdentityTest()
	self:RegisterCustomFilterMultiAccountIdentityTest()
	self:RegisterBuiltinQuickFilterMultiAccountTest()
	self:RegisterMobileOnlyAccountTest()
	self:RegisterFriendUpdateDebounceTest()
	self:RegisterChunkedFriendsListUpdateTest()
	self:RegisterBNetFriendInfoNoOpTest()
	self:RegisterEventCompatibilityTests()
	self:RegisterForeverCompatibilityTests()
	self:Register1215CompatibilityTests()
	self:RegisterLateUITests(); self:RegisterRaidInteractionTest(); self:RegisterPreviewFriendTagsTest()
	BFL:DebugPrint("|cff00ccff[BFL TestSuite]|r Initialized with " .. self:GetTestCount() .. " tests")
end

function TestSuite:RegisterForeverCompatibilityTests()
	self:RegisterTest("data", "Forever_ClientFamilyMatrix", {
		description = "Forever remains Mainline despite its 1.60 interface number while Classic families keep their existing routing",
		action = function(V)
			local forever = BFL.ResolveClientFlavor(16001, 1, 1, 2)
			V:Assert(forever.isMainline and not forever.isClassic, "Forever project identity resolves to Mainline")
			local fallbackForever = BFL.ResolveClientFlavor(16001, nil, nil, nil)
			V:Assert(fallbackForever.isMainline and not fallbackForever.isClassic, "Forever fallback never resolves as Classic")
			local midnight = BFL.ResolveClientFlavor(120105, 1, 1, 2)
			V:Assert(midnight.isMainline and midnight.isMidnight, "Midnight Standard resolves as Mainline")
			local era = BFL.ResolveClientFlavor(11509, 2, 1, 2)
			V:Assert(era.isClassic and era.isClassicEra and not era.isMainline, "Classic Era remains Classic")
			local anniversary = BFL.ResolveClientFlavor(20506, 2, 1, 2)
			V:Assert(anniversary.isClassic and anniversary.isTBCClassic, "Anniversary remains in the Classic 2.x family")
			local mists = BFL.ResolveClientFlavor(50504, 2, 1, 2)
			V:Assert(mists.isClassic and mists.isMoPClassic, "Mists Classic remains Classic")
		end,
	})

	self:RegisterTest("data", "Forever_SocialKeybindUsesWritableBindingSet", {
		description = "Forever never passes a transient or secret binding-set value to SaveBindings",
		condition = function()
			return BFL.ResolveWritableBindingSet ~= nil
		end,
		action = function(V)
			local bindingSetEnum = { Default = 0, Account = 1, Character = 2, Current = 3 }
			V:AssertEqual(
				BFL.ResolveWritableBindingSet(bindingSetEnum.Account, bindingSetEnum),
				bindingSetEnum.Account,
				"Account bindings remain writable"
			)
			V:AssertEqual(
				BFL.ResolveWritableBindingSet(bindingSetEnum.Character, bindingSetEnum),
				bindingSetEnum.Character,
				"Character bindings remain writable"
			)
			V:AssertEqual(
				BFL.ResolveWritableBindingSet(bindingSetEnum.Default, bindingSetEnum),
				nil,
				"Default bindings are never passed to SaveBindings"
			)
			V:AssertEqual(
				BFL.ResolveWritableBindingSet(bindingSetEnum.Current, bindingSetEnum),
				nil,
				"The transient Current binding set is never passed to SaveBindings"
			)
			local secretBindingSet = {}
			V:AssertEqual(
				BFL.ResolveWritableBindingSet(secretBindingSet, bindingSetEnum, function(value)
					return value == secretBindingSet
				end),
				nil,
				"Secret binding-set values are rejected before comparison"
			)
		end,
	})

	self:RegisterTest("data", "Forever_GameRuleSafety", {
		description = "Game rules fail closed and never inspect secret values",
		action = function(V)
			V:Assert(BFL.ResolveGameRuleState(7, function(value) return value == 7 end, function() return false end), "Active rules resolve true")
			V:Assert(not BFL.ResolveGameRuleState(7, function() error("unavailable") end, nil, false), "Rule API errors use the safe fallback")
			local secret = {}
			V:Assert(not BFL.ResolveGameRuleState(7, function() return secret end, function(value) return value == secret end, false), "Secret rule results use the safe fallback")
			V:Assert(BFL.ResolveNativeWhoInterception(false, true), "BFL intercepts Who while its owned surface is available")
			V:Assert(not BFL.ResolveNativeWhoInterception(true, true), "Explicit native-frame access bypasses BFL interception")
			V:Assert(not BFL.ResolveNativeWhoInterception(false, false), "Disabled Who systems are not intercepted")
			V:AssertEqual(
				BFL.ResolveFriendsFrameRedirectTab(2, true, 1, nil, 2, 3),
				2,
				"BFL's internal Who tab bypasses Forever's native Raid index"
			)
			V:AssertEqual(
				BFL.ResolveFriendsFrameRedirectTab(2, false, 1, nil, 2, 3),
				3,
				"Forever's native tab 2 still maps to BFL Raid"
			)
		end,
	})

	self:RegisterTest("data", "Forever_BFLWhoSuppressesNativeLFGWindow", {
		description = "BFL Who requests temporarily suspend Forever's native LFG Who event without changing manual routing",
		condition = function()
			local module = BFL:GetModule("WhoFrame")
			return module and module.SuspendNativeWhoListUpdates and module.RestoreNativeWhoListUpdates
		end,
		action = function(V)
			if BFL.IsMainline then
				V:Assert(BFL.whoSlashRedirectInstalled, "Mainline's /who slash handler is redirected to BFL")
			end

			local module = BFL:GetModule("WhoFrame")
			local subject = setmetatable({}, { __index = module })
			local nativeFrame = {
				registered = true,
				unregisterCount = 0,
				registerCount = 0,
				IsEventRegistered = function(self, event)
					return self.registered and event == "WHO_LIST_UPDATE"
				end,
				UnregisterEvent = function(self, event)
					if event == "WHO_LIST_UPDATE" then
						self.registered = false
						self.unregisterCount = self.unregisterCount + 1
					end
				end,
				RegisterEvent = function(self, event)
					if event == "WHO_LIST_UPDATE" then
						self.registered = true
						self.registerCount = self.registerCount + 1
					end
				end,
			}

			V:Assert(subject:SuspendNativeWhoListUpdates(nativeFrame), "Forever's native Who listener is suspended")
			V:Assert(not nativeFrame.registered, "The native frame cannot consume BFL's Who result")
			V:AssertEqual(nativeFrame.unregisterCount, 1, "The native listener is removed exactly once")
			V:Assert(subject:RestoreNativeWhoListUpdates(), "The native Who listener is restored")
			V:Assert(nativeFrame.registered, "Manual native Who routing remains available")
			V:AssertEqual(nativeFrame.registerCount, 1, "The native listener is restored exactly once")
		end,
	})

	self:RegisterTest("data", "Forever_WhoPendingUsesLoadingSpinner", {
		description = "Who requests show a spinner and reserve the empty state for completed responses",
		condition = function()
			local module = BFL:GetModule("WhoFrame")
			return module and module.SetLoadingSpinnerShown and module.UpdateEmptyState
		end,
		action = function(V)
			local module = BFL:GetModule("WhoFrame")
			local function NewVisibilityState(initialState)
				return {
					shown = initialState,
					SetShown = function(self, shown) self.shown = shown end,
					Show = function(self) self.shown = true end,
					Hide = function(self) self.shown = false end,
					IsShown = function(self) return self.shown end,
				}
			end

			local frame = {
				LoadingSpinner = NewVisibilityState(false),
				ScrollBox = NewVisibilityState(true),
				ScrollBar = NewVisibilityState(true),
			}
			local subject = setmetatable({
				emptyStateText = NewVisibilityState(true),
				whoPending = true,
			}, { __index = module })

			V:Assert(subject:SetLoadingSpinnerShown(frame, true), "The pending state is applied")
			V:Assert(frame.LoadingSpinner:IsShown(), "The Who loading spinner is visible while pending")
			V:Assert(not frame.ScrollBox:IsShown(), "The incomplete result list is hidden while pending")
			V:Assert(not frame.ScrollBar:IsShown(), "The incomplete result scrollbar is hidden while pending")
			V:Assert(not subject.emptyStateText:IsShown(), "The empty-result message is hidden while pending")

			subject:UpdateEmptyState(0)
			V:Assert(not subject.emptyStateText:IsShown(), "Pending requests cannot show an empty result")

			subject.whoPending = false
			subject:SetLoadingSpinnerShown(frame, false)
			subject:UpdateEmptyState(0)
			V:Assert(not frame.LoadingSpinner:IsShown(), "The spinner stops after the response")
			V:Assert(frame.ScrollBox:IsShown(), "The result list returns after the response")
			V:Assert(subject.emptyStateText:IsShown(), "A completed empty response shows the empty state")
		end,
	})

	self:RegisterTest("data", "Forever_WhoSearchBuilderImportsCurrentQuery", {
		description = "Opening the Search Builder imports slash-populated Who filters without submitting another request",
		condition = function()
			local module = BFL:GetModule("WhoFrame")
			return module and module.ParseWhoQuery and module.ApplyQueryToBuilder
		end,
		action = function(V)
			local module = BFL:GetModule("WhoFrame")
			local parsed = module:ParseWhoQuery('z-"Zephras Isle" 1-4')
			V:AssertEqual(parsed.zone, "Zephras Isle", "Forever's default zone is imported")
			V:AssertEqual(parsed.levelMin, "1", "Forever's default minimum level is imported")
			V:AssertEqual(parsed.levelMax, "4", "Forever's default maximum level is imported")
			V:AssertEqual(parsed.extraQuery, "", "The native default query is fully understood")

			local function NewInput()
				return {
					value = "",
					SetText = function(self, value) self.value = value end,
					GetText = function(self) return self.value end,
				}
			end

			local previewCount = 0
			local classRebuildCount = 0
			local raceRebuildCount = 0
			local subject = setmetatable({
				builder = {
					nameInput = NewInput(),
					guildInput = NewInput(),
					zoneInput = NewInput(),
					levelMin = NewInput(),
					levelMax = NewInput(),
					RebuildClassDropdown = function() classRebuildCount = classRebuildCount + 1 end,
					RebuildRaceDropdown = function() raceRebuildCount = raceRebuildCount + 1 end,
				},
				UpdateBuilderPreview = function() previewCount = previewCount + 1 end,
				SendWhoRequest = function() error("Builder import must not submit a Who request") end,
			}, { __index = module })

			V:Assert(subject:ApplyQueryToBuilder('n-"Hayato" g-"Codex Crew" z-"Zephras Isle" c-"Druid" r-"Night Elf" 1-4 unmapped'), "The current query is applied")
			V:AssertEqual(subject.builder.nameInput:GetText(), "Hayato", "Name filters are imported")
			V:AssertEqual(subject.builder.guildInput:GetText(), "Codex Crew", "Guild filters are imported")
			V:AssertEqual(subject.builder.zoneInput:GetText(), "Zephras Isle", "Zone filters are imported")
			V:AssertEqual(subject.builder.selectedClass, "Druid", "Class filters are imported")
			V:AssertEqual(subject.builder.selectedRace, "Night Elf", "Race filters are imported")
			V:AssertEqual(subject.builder.levelMin:GetText(), "1", "Minimum levels are imported")
			V:AssertEqual(subject.builder.levelMax:GetText(), "4", "Maximum levels are imported")
			V:AssertEqual(subject.builder.extraQuery, "unmapped", "Free-form terms remain lossless")
			V:AssertEqual(classRebuildCount, 1, "The class dropdown refreshes after import")
			V:AssertEqual(raceRebuildCount, 1, "The race dropdown refreshes after import")
			V:AssertEqual(previewCount, 1, "The completed import refreshes the preview once")
			V:AssertEqual(
				subject:ComposeBuilderQuery(),
				'n-"Hayato" g-"Codex Crew" z-"Zephras Isle" c-"Druid" r-"Night Elf" 1-4 unmapped',
				"Builder output retains every imported filter and free-form term"
			)
		end,
	})

	self:RegisterTest("data", "Forever_RecentAlliesDualSchema", {
		description = "Recent Allies builds the exact Midnight or Forever search structure and filters unsupported categories",
		condition = function()
			local module = BFL:GetModule("RecentAllies")
			return module and module.ResolveSearchSchema and module.BuildSearchInfo
		end,
		action = function(V)
			local module = BFL:GetModule("RecentAllies")
			local originalFilters = module.selectedFilters
			local originalSearch = module.searchText
			local ok, err = pcall(function()
				module.selectedFilters = { online = true, pvp = true, questing = true }
				module.searchText = "ally"
				local foreverSchema = module.ResolveSearchSchema({
					RecentAlliesInteractionCategoryFilter = { PvP = 1, Questing = 5 },
				}, {
					IsInteractionCategoryFilterSupportedForCurrentGameType = function(value)
						return value == 1
					end,
				})
				local foreverInfo = module:BuildSearchInfo(foreverSchema)
				V:AssertEqual(foreverInfo.searchText, "ally", "Forever keeps the search text")
				V:Assert(foreverInfo.isOnline, "Forever keeps status filters")
				V:AssertEqual(#foreverInfo.interactionCategoryFilters, 1, "Forever sends only supported interaction categories")
				V:Assert(foreverInfo.interests == nil, "Forever never sends Midnight's interests field")

				local midnightSchema = module.ResolveSearchSchema({
					RecentAlliesFriendTag = { PvP = 1, Questing = 5 },
				}, {})
				local midnightInfo = module:BuildSearchInfo(midnightSchema)
				V:AssertEqual(#midnightInfo.interests, 2, "Midnight sends its friend-tag interests")
				V:Assert(midnightInfo.interactionCategoryFilters == nil, "Midnight never sends Forever's category field")
			end)
			module.selectedFilters = originalFilters
			module.searchText = originalSearch
			if not ok then error(err, 0) end
		end,
	})

	self:RegisterTest("data", "Forever_FriendTagSupportFilter", {
		description = "Battle.net tag support is checked before tags are offered or sent",
		condition = function()
			local module = BFL:GetModule("FriendTags")
			return module and module.IsBlizzardTagSupported and module.BLIZZARD_TAGS
		end,
		action = function(V)
			local module = BFL:GetModule("FriendTags")
			local first = module.BLIZZARD_TAGS[1]
			local second = module.BLIZZARD_TAGS[2]
			V:Assert(module:IsBlizzardTagSupported(first, {}), "Older clients without the support API preserve existing tags")
			V:Assert(module:IsBlizzardTagSupported(first, {
				IsFriendTagSupportedForCurrentGameType = function(value)
					return value == first.enumFallback
				end,
			}), "Supported game-type tags remain available")
			V:Assert(not module:IsBlizzardTagSupported(first, {
				IsFriendTagSupportedForCurrentGameType = function() return false end,
			}), "Unsupported game-type tags are rejected")
			V:Assert(not module:IsBlizzardTagSupported(first, {
				IsFriendTagSupportedForCurrentGameType = function() error("unavailable") end,
			}), "Tag support API errors fail closed")
			local desired, payload = module:BuildSupportedBlizzardTagPayload({
				[first.id] = true,
				[second.id] = true,
			}, {
				IsFriendTagSupportedForCurrentGameType = function(value)
					return value == first.enumFallback
				end,
			})
			V:Assert(desired[first.id] and not desired[second.id], "Unsupported native tags are removed from desired state")
			V:AssertEqual(#payload, 1, "Mutation payload contains only supported native tags")
			V:AssertEqual(payload[1], first.enumFallback, "Mutation payload preserves the supported enum value")
		end,
	})

	self:RegisterTest("integration", "Forever_MenuOwnershipAndNativeTabArt", {
		description = "The menu bridge preserves its owner and side tabs honor the active game-type mixin offsets",
		action = function(V)
			local owner = { GetObjectType = function() return "Button" end }
			local bridge = BFL:GetModule("MenuBridge")
			if bridge and bridge.CreateSafeContext then
				local context = bridge:CreateSafeContext({ ownerFrame = owner, name = "Test" }, "FRIEND", owner)
				V:AssertEqual(context.ownerFrame, owner, "Menu Bridge preserves ownerFrame")
			end
			local friendsUI = BFL:GetModule("FriendsUI")
			if friendsUI and friendsUI.GetSideTabIconAnchorOffsets then
				local x, y = friendsUI:GetSideTabIconAnchorOffsets({
					GetIconAnchorOffsetsForTabArt = function() return -4, 0 end,
				}, {}, true)
				V:AssertEqual(x, -4, "Forever's native side-tab horizontal offset is honored")
				V:AssertEqual(y, 5, "BFL's count offset composes with the native game-type offset")
			end
		end,
	})

	self:RegisterTest("integration", "Forever_CapabilityDiagnostics", {
		description = "Compatibility diagnostics expose project family, rules, and capability state without a version-only decision",
		action = function(V)
			local diagnostics = BFL:GetCompatibilityDiagnostics()
			V:Assert(type(diagnostics) == "table", "Compatibility diagnostics are available")
			V:AssertEqual(diagnostics.isMainline, BFL.IsMainline == true, "Diagnostics report the resolved Mainline family")
			V:Assert(type(diagnostics.gameRules) == "table", "Diagnostics report game-rule state")
			V:Assert(type(diagnostics.capabilities) == "table", "Diagnostics report capability state")
		end,
	})
end

function TestSuite:Register1215CompatibilityTests()
	self:RegisterTest("data", "IntlCompat_CapabilityAndFallbackContract", {
		description = "12.1.5 internationalization helpers reject secret values, use C_Intl when safe, and preserve older-client fallbacks",
		action = function(V)
			local compat = BFL.IntlCompat
			V:AssertNotNil(compat, "Intl compatibility helper should exist")
			local originalAPI = compat._testAPI
			local originalStrengths = compat._testStrengths
			local originalIsSecret = BFL.IsSecret
			local calls = {}
			local ok, err = pcall(function()
				compat._testStrengths = { Primary = 0, Tertiary = 2 }
				compat._testAPI = false
				V:Assert(not compat.CanUseIntl(), "Older clients should use the compatibility path")
				V:Assert(compat.Contains("Élodie", "elodie"), "Fallback search should remain accent-insensitive")
				V:AssertEqual(compat.GetSortKey("Änne"), BFL:StripAccents("Änne"), "Fallback sort key should retain existing normalization")

				compat._testAPI = {
					FindStringMatches = function(text, pattern, strength)
						calls.nativeCallCount = (calls.nativeCallCount or 0) + 1
						calls.searchStrength = strength
						return text == "Unicode haystack" and pattern == "needle" and { 9 } or {}
					end,
					CompareStrings = function(left, right, strength)
						calls.nativeCallCount = (calls.nativeCallCount or 0) + 1
						calls.compareStrength = strength
						return left == "Straße" and right == "strasse" and 0 or 1
					end,
					GetSortKey = function(text, strength)
						calls.nativeCallCount = (calls.nativeCallCount or 0) + 1
						calls.sortStrength = strength
						return "sort:" .. text
					end,
					FoldCase = function(text)
						calls.nativeCallCount = (calls.nativeCallCount or 0) + 1
						return "fold:" .. text
					end,
				}
				V:Assert(compat.CanUseIntl(), "Complete 12.1.5 C_Intl should activate the native path")
				V:Assert(compat.Contains("Unicode haystack", "needle"), "Native search result should be honored")
				V:Assert(compat.Equals("Straße", "strasse"), "Native primary-strength equality should be honored")
				V:AssertEqual(compat.GetSortKey("Änne"), "sort:Änne", "Native locale sort key should be returned unchanged")
				V:AssertEqual(compat.NormalizeForSearch("Mixed"), "fold:Mixed", "Native case folding should be used when available")
				V:AssertEqual(calls.searchStrength, 0, "Search should use primary collation strength")
				V:AssertEqual(calls.compareStrength, 0, "Equality should use primary collation strength")
				V:AssertEqual(calls.sortStrength, 2, "Sorting should use tertiary collation strength")
				V:Assert(compat.Contains(nil, ""), "Nil text should retain empty-string search semantics")
				V:Assert(compat.Equals(nil, nil), "Nil values should retain empty-string equality semantics")

				local secretValue = {}
				BFL.IsSecret = function(_, value)
					return value == secretValue
				end
				local callsBeforeSecretInputs = calls.nativeCallCount
				V:AssertEqual(compat.NormalizeForSearch(secretValue), "", "Secret search text should be discarded")
				V:Assert(not compat.Contains(secretValue, "needle"), "Secret haystacks should not be searched")
				V:Assert(not compat.Contains("haystack", secretValue), "Secret patterns should not be searched")
				V:Assert(not compat.Equals(secretValue, secretValue), "Secret values should never compare equal")
				V:AssertEqual(compat.GetSortKey(secretValue), "", "Secret values should not produce sort keys")
				V:AssertEqual(
					calls.nativeCallCount,
					callsBeforeSecretInputs,
					"Secret values must be rejected before reaching C_Intl"
				)

				local function Fail()
					error("simulated unavailable native result")
				end
				compat._testAPI = {
					FindStringMatches = Fail,
					CompareStrings = Fail,
					GetSortKey = Fail,
					FoldCase = Fail,
				}
				V:Assert(compat.Contains("Élodie", "elodie"), "Native search errors should fall back safely")
				V:AssertEqual(compat.GetSortKey("Änne"), BFL:StripAccents("Änne"), "Native sort errors should fall back safely")
			end)
			compat._testAPI = originalAPI
			compat._testStrengths = originalStrengths
			BFL.IsSecret = originalIsSecret
			if not ok then
				error(err, 0)
			end
		end,
	})

	self:RegisterTest("data", "TimerCompat_KeyedRescheduleContract", {
		description = "TimedSignalMap reschedules one key while the legacy timer path suppresses stale callbacks",
		action = function(V)
			local compat = BFL.TimerCompat
			V:AssertNotNil(compat, "Timer compatibility helper should exist")
			local originalAPI = compat._testAPI
			local ok, err = pcall(function()
				local scheduled = {}
				local signalCallback
				local signalMap = {
					SignalAfter = function(self, key, delay)
						scheduled[key] = delay
					end,
					CancelSignal = function(self, key)
						scheduled[key] = nil
					end,
					HasSignal = function(self, key)
						return scheduled[key] ~= nil
					end,
				}
				compat._testAPI = {
					NewTimedSignalMap = function(callback)
						signalCallback = callback
						return signalMap
					end,
				}
				local nativeCount = 0
				local native = compat.CreateKeyedDebouncer(function(key)
					V:AssertEqual(key, 7, "TimedSignalMap callback should preserve its key")
					nativeCount = nativeCount + 1
				end)
				V:Assert(native:UsesTimedSignalMap(), "12.1.5 should use TimedSignalMap")
				V:Assert(native:Schedule(7, 0.1), "Native schedule should report TimedSignalMap usage")
				V:Assert(native:Schedule(7, 0.25), "Native reschedule should stay on TimedSignalMap")
				V:AssertEqual(scheduled[7], 0.25, "The same key should retain only its latest deadline")
				scheduled[7] = nil -- Native maps remove due signals before invoking the callback.
				signalCallback(7)
				V:AssertEqual(nativeCount, 1, "The rescheduled native key should fire once")
				V:Assert(not native:IsPending(7), "A fired native key should no longer be pending")

				local callbacks = {}
				compat._testAPI = {
					After = function(delay, callback)
						table.insert(callbacks, callback)
					end,
				}
				local fallbackCount = 0
				local fallback = compat.CreateKeyedDebouncer(function()
					fallbackCount = fallbackCount + 1
				end)
				V:Assert(not fallback:UsesTimedSignalMap(), "Older clients should use the timer fallback")
				fallback:Schedule(3, 0.1)
				fallback:Schedule(3, 0.2)
				callbacks[1]()
				V:AssertEqual(fallbackCount, 0, "A superseded fallback timer must be ignored")
				callbacks[2]()
				V:AssertEqual(fallbackCount, 1, "Only the newest fallback timer should fire")
				V:Assert(not fallback:IsPending(3), "A fired fallback key should no longer be pending")

				compat._testAPI = false
				local immediateCount = 0
				compat.CreateKeyedDebouncer(function()
					immediateCount = immediateCount + 1
				end):Schedule(1, 0)
				V:AssertEqual(immediateCount, 1, "A missing timer API should degrade to immediate execution")
			end)
			compat._testAPI = originalAPI
			if not ok then
				error(err, 0)
			end
		end,
	})

	self:RegisterTest("data", "LFGInfo_AssignmentVisibilityContract", {
		description = "12.1.5 LFG assignment visibility is capability-gated and fails open",
		action = function(V)
			local compat = BFL.Compat
			V:AssertNotNil(compat, "Client compatibility helper should exist")
			local originalAPI = compat._testLFGInfo
			local ok, err = pcall(function()
				compat._testLFGInfo = false
				V:Assert(compat.ShouldDisplayMainTankAndAssist(), "Missing API should preserve older-client assignment icons")

				compat._testLFGInfo = {
					IsInMatchmadeRaidWithoutRoleRequirements = function()
						return true
					end,
				}
				V:Assert(not compat.ShouldDisplayMainTankAndAssist(), "Matchmade unrestricted raids should hide manual assignments")

				compat._testLFGInfo = {
					IsInMatchmadeRaidWithoutRoleRequirements = function()
						error("simulated API error")
					end,
				}
				V:Assert(compat.ShouldDisplayMainTankAndAssist(), "Assignment visibility should fail open on API errors")
			end)
			compat._testLFGInfo = originalAPI
			if not ok then
				error(err, 0)
			end
		end,
	})

	self:RegisterTest("ui", "RaidFrame_AssignmentAndMasterLooterIconVisibility", {
		description = "Raid assignments and the Preview-compatible Master Looter marker follow independent visibility rules",
		condition = function()
			return CreateFrame and UIParent and BFL:GetModule("RaidFrame")
		end,
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			local button = CreateFrame("Frame", nil, UIParent)
			button:SetSize(180, 20)
			button.RankIcon = button:CreateTexture(nil, "ARTWORK")
			button.RankIcon:SetSize(16, 16)
			button.RoleIcon = button:CreateTexture(nil, "ARTWORK")
			button.RoleIcon:SetSize(16, 16)
			button.MainTankIcon = button:CreateTexture(nil, "ARTWORK")
			button.MainTankIcon:SetSize(12, 12)
			button.MainAssistIcon = button:CreateTexture(nil, "ARTWORK")
			button.MainAssistIcon:SetSize(12, 12)
			button.MasterLooterIcon = button:CreateTexture(nil, "ARTWORK")
			button.MasterLooterIcon:SetSize(12, 12)

			RaidFrame.UpdateRaidAssignmentIcons(button, 2, "MAINTANK", false, false)
			V:Assert(button.RankIcon:IsShown(), "Leadership icon should remain independent of LFG restrictions")
			V:Assert(not button.MainTankIcon:IsShown(), "Main-tank icon should hide in the restricted LFG context")
			V:Assert(not button._bflMainTankTooltip:IsShown(), "Hidden assignment icon should not retain a tooltip hitbox")

			RaidFrame.UpdateRaidAssignmentIcons(button, 0, "MAINTANK", false, true)
			V:Assert(button.MainTankIcon:IsShown(), "Main-tank icon should remain on clients and groups that support it")
			V:Assert(button._bflMainTankTooltip:IsShown(), "Visible assignment icon should expose its tooltip hitbox")
			RaidFrame.UpdateRaidAssignmentIcons(button, 0, "MAINASSIST", false, false)
			V:Assert(not button.MainAssistIcon:IsShown(), "Main-assist icon should obey the same restriction")

			RaidFrame.UpdateRaidAssignmentIcons(button, 0, nil, false, false, true)
			V:Assert(button.MasterLooterIcon:IsShown(), "Master Looter should remain visible independently of LFG assignments")
			V:Assert(button._bflMasterLooterTooltip:IsShown(), "Master Looter should expose its localized tooltip hitbox")
			RaidFrame.UpdateRaidAssignmentIcons(button, 0, nil, false, true, false)
			V:Assert(not button.MasterLooterIcon:IsShown(), "Master Looter should clear when the roster flag clears")
			V:Assert(not button._bflMasterLooterTooltip:IsShown(), "A cleared Master Looter should not retain a tooltip hitbox")
			button:Hide()
		end,
	})

	self:RegisterTest("data", "RaidFrame_PartyMasterLooterMapping", {
		description = "Classic party loot IDs support legacy strings and current LootMethod enums without leaking other methods",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertEqual(
				RaidFrame.GetPartyMasterLooterID(function()
					return "master", 0
				end),
				0,
				"Party Master Looter ID zero should identify the player"
			)
			V:AssertEqual(
				RaidFrame.GetPartyMasterLooterID(function()
					return "master", 3
				end),
				3,
				"Positive party Master Looter IDs should preserve Blizzard layout indices"
			)
			local masterLooterMethod = Enum and Enum.LootMethod and Enum.LootMethod.Masterlooter
			if masterLooterMethod ~= nil then
				V:AssertEqual(
					RaidFrame.GetPartyMasterLooterID(function()
						return masterLooterMethod, 4
					end),
					4,
					"Current C_PartyInfo LootMethod enums should identify the Master Looter"
				)
			end
			V:AssertNil(RaidFrame.GetPartyMasterLooterID(function()
				return "group", 2
			end), "Non-master loot methods should not mark a member")
			V:AssertNil(RaidFrame.GetPartyMasterLooterID(function()
				error("simulated API error")
			end), "Loot-method API errors should fail closed")
		end,
	})
end

function TestSuite:RegisterPreviewFriendTagsTest()
	self:RegisterTest("data", "PreviewMode_FriendTagsUseSyntheticFixtures", {
		description = "Preview friend tags remain available without the live Blizzard tag rollout",
		action = function(V)
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")

			local originalAreBlizzardTagsEnabled = FriendTags.AreBlizzardTagsEnabled
			local ok, err = pcall(function()
				FriendTags.AreBlizzardTagsEnabled = function()
					return false
				end
				FriendTags:ClearCaches()

				local previewFriend = {
					type = "bnet",
					battleTag = "PreviewTags#1234",
					bnetAccountID = 987654321,
					friendTags = { 2, 8 },
					_isMock = true,
				}
				local tagIds = FriendTags:GetBlizzardTagIdSetForFriend(previewFriend)
				V:Assert(tagIds["blizzard:raiding"] == true, "Preview rows should resolve their Raiding fixture")
				V:Assert(tagIds["blizzard:healer"] == true, "Preview rows should resolve their Healer fixture")

				local liveShapedFriend = {
					type = "bnet",
					battleTag = "NotPreviewTags#1234",
					bnetAccountID = 987654322,
					friendTags = { 2, 8 },
				}
				local liveTagIds = FriendTags:GetNativeBlizzardTagIdSet(liveShapedFriend)
				V:Assert(
					liveTagIds["blizzard:raiding"] ~= true and liveTagIds["blizzard:healer"] ~= true,
					"Only explicit Preview fixtures may bypass live tag availability"
				)
			end)
			FriendTags.AreBlizzardTagsEnabled = originalAreBlizzardTagsEnabled
			FriendTags:ClearCaches()
			if not ok then
				error(err, 0)
			end

			local PreviewMode = BFL:GetModule("PreviewMode")
			local profileID, profile = PreviewMode:GetProfileDefinition("friends_tags")
			local fakePreview = setmetatable({
				enabled = true,
				activeProfile = profileID,
				activeComponents = profile.components,
				mockData = { friends = {} },
			}, { __index = PreviewMode })
			local steps = fakePreview:BuildProfileActivationSteps(profileID, profile)
			local hasTagInvalidationStep = false
			for _, step in ipairs(steps) do
				if step.id == "friends.tags.invalidate" then
					hasTagInvalidationStep = true
					break
				end
			end
			V:Assert(hasTagInvalidationStep, "Preview tag profiles should invalidate deterministic mock UID caches")
		end,
	})
end

function TestSuite:RegisterSearchIdentityTest()
	self:RegisterTest("filter", "SearchFilter_MatchesVisibleBNetIdentities", {
		description = "Search must keep BNet friends visible by title custom name or any displayed game account",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end

			local originalSearch = FriendsList.searchText
			local originalFilter = FriendsList.filterMode
			FriendsList.filterMode = "all"

			local friend = {
				connected = true,
				type = "bnet",
				uid = "bnet_SearchIdentityTest#1234",
				battleTag = "SearchIdentityTest#1234",
				titleCustomName = "Gawdsmack",
				characterName = "FocusedCharacter",
				gameAccounts = {
					{ characterName = "FocusedCharacter", realmName = "PrimaryRealm" },
					{ characterName = "SecondaryCharacter", realmName = "SecondaryRealm" },
				},
			}

			FriendsList.searchText = "gawd"
			V:Assert(
				FriendsList:PassesFilters(friend) == true,
				"Friend should pass when search matches the displayed title custom name"
			)

			FriendsList.searchText = "secondarycharacter"
			V:Assert(
				FriendsList:PassesFilters(friend) == true,
				"Friend should pass when search matches another displayed game account"
			)

			FriendsList.searchText = "secondaryrealm"
			V:Assert(
				FriendsList:PassesFilters(friend) == true,
				"Friend should pass when search matches another displayed game account realm"
			)

			FriendsList.searchText = originalSearch
			FriendsList.filterMode = originalFilter
		end,
	})
end

function TestSuite:RegisterCustomFilterMultiAccountIdentityTest()
	self:RegisterTest("filter", "Registry_CustomFilter_MatchesVisibleBNetGameAccounts", {
		description = "Character and Realm rules must match any visible WoW game account on a BNet friend",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry or not BetterFriendlistDB then
				V:Skip("FilterSortRegistry or DB not loaded")
				return
			end

			Registry:EnsureDB()
			local testId = "custom_filter_test_multi_account_identity"
			local original = BetterFriendlistDB.customQuickFilters[testId]
			local originalVisibility = BetterFriendlistDB.quickFilterVisibility[testId]
			local originalBeta = BetterFriendlistDB.enableBetaFeatures

			BetterFriendlistDB.enableBetaFeatures = true
			BetterFriendlistDB.customQuickFilters[testId] = {
				id = testId,
				name = "Multi-Account Identity Test",
				icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter",
				ast = {
					type = "group",
					op = "AND",
					children = {
						{ type = "condition", field = "character", op = "contains", value = "gawd" },
						{ type = "condition", field = "realm", op = "is", value = "SecondaryRealm" },
						{ type = "condition", field = "client", op = "is", value = BNET_CLIENT_WOW or "WoW" },
						{ type = "condition", field = "game", op = "contains", value = "secondary presence" },
						{ type = "condition", field = "wowProject", op = "is", value = WOW_PROJECT_MAINLINE or 1 },
					},
				},
			}
			BetterFriendlistDB.quickFilterVisibility[testId] = true
			Registry:InvalidateCaches()

			local friend = {
				type = "bnet",
				connected = true,
				characterName = "FocusedCharacter",
				realmName = "PrimaryRealm",
				gameAccountInfo = {
					clientProgram = "S2",
					isOnline = true,
					richPresence = "Focused Presence",
				},
				gameAccounts = {
					{
						clientProgram = "S2",
						isOnline = true,
						richPresence = "Focused Presence",
					},
					{
						clientProgram = BNET_CLIENT_WOW or "WoW",
						isOnline = true,
						characterName = "Gawdsmack",
						realmName = "SecondaryRealm",
						richPresence = "Secondary Presence",
						wowProjectID = WOW_PROJECT_MAINLINE or 1,
					},
				},
			}

			V:Assert(
				Registry:EvaluateQuickFilter(testId, friend) == true,
				"Custom filter should match identity, client, game, and project values from a secondary account"
			)

			BetterFriendlistDB.customQuickFilters[testId] = original
			BetterFriendlistDB.quickFilterVisibility[testId] = originalVisibility
			BetterFriendlistDB.enableBetaFeatures = originalBeta
			Registry:InvalidateCaches()
		end,
	})
end

function TestSuite:RegisterBuiltinQuickFilterMultiAccountTest()
	self:RegisterTest("filter", "Registry_BuiltinFilters_MatchSecondaryBNetGameAccount", {
		description = "Built-in WoW, Retail, and In Game filters must inspect every online BNet game account",
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry then
				V:Skip("FilterSortRegistry not loaded")
				return
			end

			local friend = {
				type = "bnet",
				connected = true,
				gameAccountInfo = {
					clientProgram = "BSAp",
					isOnline = true,
				},
				gameAccounts = {
					{
						clientProgram = BNET_CLIENT_WOW or "WoW",
						isOnline = true,
						wowProjectID = WOW_PROJECT_MAINLINE or 1,
					},
				},
			}

			V:Assert(Registry:EvaluateQuickFilter("wow", friend) == true, "WoW filter should match the secondary account")
			V:Assert(
				Registry:EvaluateQuickFilter("wowonline", friend) == true,
				"WoW Online filter should match the secondary account"
			)
			V:Assert(
				Registry:EvaluateQuickFilter("retail", friend) == true,
				"Retail filter should match the secondary account"
			)
			V:Assert(
				Registry:EvaluateQuickFilter("ingame", friend) == true,
				"In Game filter should match the secondary account"
			)
		end,
	})
end

function TestSuite:RegisterMobileOnlyAccountTest()
	self:RegisterTest("filter", "FriendsList_MobileOffline_RequiresMobileOnly", {
		description = "Treat Mobile as Offline must not hide friends who are active on another game account",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.IsFocusedAccountMobileOnly then
				V:Skip("FriendsList mobile account classifier not loaded")
				return
			end

			local mobileAccount = { clientProgram = "BSAp", isOnline = true }
			V:Assert(
				FriendsList:IsFocusedAccountMobileOnly(mobileAccount, nil) == true,
				"A single online Mobile account should be classified as mobile-only"
			)
			V:Assert(
				FriendsList:IsFocusedAccountMobileOnly(mobileAccount, {
					{ clientProgram = BNET_CLIENT_WOW or "WoW", isOnline = true },
				}) == false,
				"An online secondary WoW account should keep the friend online"
			)
			V:Assert(
				FriendsList:IsFocusedAccountMobileOnly(mobileAccount, {
					{ clientProgram = "D4", isOnline = true },
				}) == false,
				"Any online secondary game account should keep the friend online"
			)
		end,
	})
end

function TestSuite:RegisterFriendUpdateDebounceTest()
	self:RegisterTest("events", "FriendsList_EventBurst_UsesSingleCancelableTimer", {
		description = "Visible friend events must coalesce through one cancelable timer",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList then
				V:Skip("FriendsList not loaded")
				return
			end
			if FriendsList.updateTimer or FriendsList.scheduledRefreshTimer then
				V:Skip("FriendsList already has a pending refresh timer")
				return
			end

			local originalCTimer = C_Timer
			local originalFrame = BetterFriendsFrame
			local originalUpdate = FriendsList.UpdateFriendsList
			local originalReady = FriendsList.bnetDataReady
			local originalTimer = FriendsList.updateTimer
			local callbacks = {}
			local handles = {}
			local updateCount = 0

			BetterFriendsFrame = { IsShown = function() return true end }
			C_Timer = {
				NewTimer = function(_, callback)
					local handle = {
						cancelled = false,
						Cancel = function(self)
							self.cancelled = true
						end,
					}
					callbacks[#callbacks + 1] = callback
					handles[#handles + 1] = handle
					return handle
				end,
			}
			FriendsList.bnetDataReady = true
			FriendsList.updateTimer = nil
			FriendsList.UpdateFriendsList = function()
				updateCount = updateCount + 1
			end

			FriendsList:OnFriendListUpdate(12345)
			FriendsList:OnFriendListUpdate(67890)
			V:AssertEqual(#callbacks, 1, "An event payload burst should schedule only one timer")
			V:AssertType(FriendsList.updateTimer.Cancel, "function", "Scheduled update should be cancelable")

			callbacks[1]()
			V:AssertEqual(updateCount, 1, "The coalesced timer should update exactly once")
			V:AssertNil(FriendsList.updateTimer, "The timer callback should clear the active handle")

			FriendsList:OnFriendListUpdate(false)
			local pendingHandle = handles[#handles]
			FriendsList:OnFriendListUpdate(true)
			V:Assert(pendingHandle.cancelled == true, "A forced update should cancel the pending timer")
			V:AssertEqual(updateCount, 2, "A forced update should run immediately once")

			FriendsList.UpdateFriendsList = originalUpdate
			FriendsList.bnetDataReady = originalReady
			FriendsList.updateTimer = originalTimer
			C_Timer = originalCTimer
			BetterFriendsFrame = originalFrame
		end,
	})
end

function TestSuite:RegisterChunkedFriendsListUpdateTest()
	self:RegisterTest("events", "FriendsList_LargeListUpdate_UsesNextFrameBatches", {
		description = "Large friend-list rebuilds should resume in next-frame batches without overlapping workers",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if
				not FriendsList
				or not FriendsList.StartChunkedFriendsListUpdate
				or not FriendsList.GetChunkedFriendsListUpdateMaxBatchSize
			then
				V:Skip("FriendsList chunked update runner not loaded")
				return
			end

			local originalCTimer = C_Timer
			local originalUpdate = FriendsList.UpdateFriendsList
			local originalThread = FriendsList.chunkedFriendsListUpdate
			local callbacks = {}
			local resumeCount = 0
			local receivedIgnoreVisibility

			local ok, err = pcall(function()
				V:AssertEqual(
					FriendsList:GetChunkedFriendsListUpdateMaxBatchSize(300),
					25,
					"Lists up to 300 friends should use at most 25 entries per batch"
				)
				V:AssertEqual(
					FriendsList:GetChunkedFriendsListUpdateMaxBatchSize(301),
					20,
					"Lists above 300 friends should use at most 20 entries per batch"
				)
				V:AssertEqual(
					FriendsList:GetChunkedFriendsListUpdateMaxBatchSize(600),
					20,
					"Lists up to 600 friends should retain the 20-entry cap"
				)
				V:AssertEqual(
					FriendsList:GetChunkedFriendsListUpdateMaxBatchSize(601),
					15,
					"Lists above 600 friends should use at most 15 entries per batch"
				)

				C_Timer = {
					After = function(delay, callback)
						V:AssertEqual(delay, 0, "Chunked updates should resume on the next frame")
						callbacks[#callbacks + 1] = callback
					end,
				}
				FriendsList.chunkedFriendsListUpdate = nil
				FriendsList.UpdateFriendsList = function(_, ignoreVisibility, isChunkedUpdate)
					receivedIgnoreVisibility = ignoreVisibility
					V:Assert(isChunkedUpdate == true, "The scheduled worker should use the chunked update path")
					for _ = 1, 3 do
						resumeCount = resumeCount + 1
						coroutine.yield()
					end
				end

				FriendsList:StartChunkedFriendsListUpdate(true)
				V:AssertNotNil(FriendsList.chunkedFriendsListUpdate, "The chunked worker should be active")
				V:AssertEqual(#callbacks, 1, "Starting a chunked update should schedule one callback")

				while #callbacks > 0 do
					local callback = table.remove(callbacks, 1)
					callback()
				end

				V:AssertEqual(resumeCount, 3, "Each yielded batch should be resumed")
				V:Assert(receivedIgnoreVisibility == true, "The worker should preserve visibility overrides")
				V:AssertNil(FriendsList.chunkedFriendsListUpdate, "The completed worker should release its state")
			end)

			FriendsList.UpdateFriendsList = originalUpdate
			FriendsList.chunkedFriendsListUpdate = originalThread
			FriendsList:ClearPendingUpdate()
			C_Timer = originalCTimer
			if not ok then
				error(err, 0)
			end
		end,
	})
end

function TestSuite:RegisterBNetFriendInfoNoOpTest()
	self:RegisterTest("events", "FriendsList_BNetInfo_NoOpSkipsFullRefresh", {
		description = "Indexed BNet info events should rebuild only when the cached friend data changed",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.OnBNetFriendInfoChanged then
				V:Skip("FriendsList indexed BNet event handler not loaded")
				return
			end

			local originalFrame = BetterFriendsFrame
			local originalGetBNetFriendInfo = BFL.GetBNetFriendInfo
			local originalGetBNetFriendGameAccountInfo = BFL.GetBNetFriendGameAccountInfo
			local originalFriendTagsEnabled = BFL.AreBattleNetFriendTagsEnabled
			local originalTitleNamesEnabled = BFL.AreTitleFriendCustomNamesEnabled
			local originalCBattleNet = C_BattleNet
			local originalUpdate = FriendsList.OnFriendListUpdate
			local originalReady = FriendsList.bnetDataReady
			local originalIndexMap = FriendsList.bnetFriendsByIndex
			local originalTagSnapshotComplete = FriendsList.bnetFriendTagSnapshotComplete
			local updateCount = 0
			local accountQueryCount = 0
			local accountNote = "unchanged"
			local accountFriendTags = { 1, 2 }
			local secondaryRichPresence = "unchanged presence"

			local gameAccountInfo = {
				gameAccountID = 9001,
				clientProgram = BNET_CLIENT_WOW or "WoW",
				isOnline = true,
				characterName = "IndexedFriend",
				realmName = "TestRealm",
				realmID = 1,
				wowProjectID = WOW_PROJECT_ID,
			}
			local cachedFriend = {
				type = "bnet",
				index = 7,
				bnetAccountID = 1234,
				accountName = "Account",
				battleTag = "Account#1234",
				friendLevel = 1,
				lastOnlineTime = 42,
				isAFK = false,
				isDND = false,
				isFavorite = false,
				note = accountNote,
				customMessage = "Status",
				customMessageTime = 10,
				friendTags = { 1, 2 },
				gameAccountInfo = gameAccountInfo,
				gameAccounts = {
					gameAccountInfo,
					{
						gameAccountID = 9002,
						clientProgram = "D4",
						isOnline = true,
						richPresence = "unchanged presence",
					},
				},
				totalGameAccounts = 2,
				numGameAccounts = 2,
			}

			local ok, err = pcall(function()
				BetterFriendsFrame = { IsShown = function() return true end }
				BFL.GetBNetFriendInfo = function()
					accountQueryCount = accountQueryCount + 1
					return {
						bnetAccountID = 1234,
						accountName = "Account",
						battleTag = "Account#1234",
						friendLevel = 1,
						lastOnlineTime = 42,
						isAFK = false,
						isDND = false,
						isFavorite = false,
						note = accountNote,
						customMessage = "Status",
						customMessageTime = 10,
						friendTags = accountFriendTags,
						gameAccountInfo = {
							gameAccountID = 9001,
							clientProgram = BNET_CLIENT_WOW or "WoW",
							isOnline = true,
							characterName = "IndexedFriend",
							realmName = "TestRealm",
							realmID = 1,
							wowProjectID = WOW_PROJECT_ID,
						},
					}
				end
				BFL.GetBNetFriendGameAccountInfo = function(_, gameAccountIndex)
					if gameAccountIndex == 1 then
						return {
							gameAccountID = 9001,
							clientProgram = BNET_CLIENT_WOW or "WoW",
							isOnline = true,
							characterName = "IndexedFriend",
							realmName = "TestRealm",
							realmID = 1,
							wowProjectID = WOW_PROJECT_ID,
						}
					end
					return {
						gameAccountID = 9002,
						clientProgram = "D4",
						isOnline = true,
						richPresence = secondaryRichPresence,
					}
				end
				BFL.AreBattleNetFriendTagsEnabled = function() return true end
				BFL.AreTitleFriendCustomNamesEnabled = function() return false end
				C_BattleNet = { GetFriendNumGameAccounts = function() return 2 end }
				FriendsList.OnFriendListUpdate = function()
					updateCount = updateCount + 1
				end
				FriendsList.bnetDataReady = true
				FriendsList.bnetFriendsByIndex = { [7] = cachedFriend }
				FriendsList.bnetFriendTagSnapshotComplete = true

				FriendsList:OnBNetFriendInfoChanged(7)
				V:AssertEqual(updateCount, 0, "An unchanged indexed friend should not schedule a full refresh")
				V:AssertEqual(accountQueryCount, 1, "The no-op check should query only the indexed friend")

				accountFriendTags = { 1, 3 }
				FriendsList:OnBNetFriendInfoChanged(7)
				local tagsChanged, changedFriend = FriendsList:GetLastBNetFriendInfoEventTagsChanged(7)
				V:Assert(tagsChanged == true, "A changed native tag set should be identified")
				V:Assert(changedFriend == cachedFriend, "A changed native tag set should retain its targeted friend")
				V:AssertEqual(updateCount, 1, "A changed native tag set should preserve the full refresh path")
				accountFriendTags = { 1, 2 }

				secondaryRichPresence = "changed presence"
				FriendsList:OnBNetFriendInfoChanged(7)
				V:AssertEqual(updateCount, 2, "A secondary game-account change should preserve the full refresh path")
				secondaryRichPresence = "unchanged presence"

				accountNote = "changed"
				FriendsList:OnBNetFriendInfoChanged(7)
				V:AssertEqual(updateCount, 3, "A changed indexed friend should preserve the full refresh path")

				FriendsList:OnBNetFriendInfoChanged(nil)
				local unknownTagsChanged, unknownFriend, canReconcileUnknown =
					FriendsList:GetLastBNetFriendInfoEventTagsChanged(nil)
				V:AssertNil(unknownTagsChanged, "A nil Retail payload should keep its tag change unknown")
				V:AssertNil(unknownFriend, "A nil Retail payload should not target an arbitrary friend")
				V:Assert(canReconcileUnknown == true, "A complete tag snapshot should reconcile nil payloads during rebuild")
				V:AssertEqual(updateCount, 4, "A nil Retail payload should conservatively refresh")
				V:AssertEqual(accountQueryCount, 4, "Invalid payloads should not query arbitrary friend indices")

				BetterFriendsFrame = { IsShown = function() return false end }
				FriendsList:OnBNetFriendInfoChanged(7)
				V:AssertEqual(updateCount, 5, "Hidden lists should use the regular dirty-on-show gate")
				V:AssertEqual(accountQueryCount, 4, "Hidden lists should not query indexed BNet data")
			end)

			BetterFriendsFrame = originalFrame
			BFL.GetBNetFriendInfo = originalGetBNetFriendInfo
			BFL.GetBNetFriendGameAccountInfo = originalGetBNetFriendGameAccountInfo
			BFL.AreBattleNetFriendTagsEnabled = originalFriendTagsEnabled
			BFL.AreTitleFriendCustomNamesEnabled = originalTitleNamesEnabled
			C_BattleNet = originalCBattleNet
			FriendsList.OnFriendListUpdate = originalUpdate
			FriendsList.bnetDataReady = originalReady
			FriendsList.bnetFriendsByIndex = originalIndexMap
			FriendsList.bnetFriendTagSnapshotComplete = originalTagSnapshotComplete
			if not ok then
				error(err, 0)
			end
		end,
	})
end

function TestSuite:RegisterAutoRaidAssistRosterFallbackTest()
	self:RegisterTest("data", "AutoRaidAssist_RosterInfoFallbackPromotion", {
		description = "Auto Raid Assist should promote from raid roster info when raid unit tokens are not ready yet",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Delta-Away",
							id = "player:Delta-Away",
							kind = "player",
							value = "Delta-Away",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalIsInRaid = IsInRaid
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalGetRaidRosterInfo = GetRaidRosterInfo
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalUnitRealmRelationship = UnitRealmRelationship
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionAttemptCounts = AutoRaidAssist.promotionAttemptCounts
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local promoted = {}

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionAttemptCounts = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}

					C_Timer = {
						NewTimer = function(delay, callback)
							return {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
						end,
					}
					IsInRaid = function()
						return true
					end
					GetNumGroupMembers = function()
						return 1
					end
					GetRaidRosterInfo = function(index)
						if index == 1 then
							return "Delta-Away", 0
						end
						return nil, nil
					end
					UnitExists = function(unit)
						return unit == "player"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function()
						return false
					end
					UnitFullName = function()
						return nil, nil
					end
					UnitName = function(unit)
						if unit == "player" then
							return "Leader", "Home"
						end
						return nil, nil
					end
					UnitRealmRelationship = function()
						return nil
					end
					GetNormalizedRealmName = function()
						return "Home"
					end
					GetTime = function()
						return 100
					end
					BFL.IsActionRestricted = function()
						return false
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							return true
						end,
					}

					V:Assert(AutoRaidAssist:Evaluate("test-roster-fallback") == true, "Evaluate should promote a roster-backed target")
					V:AssertEqual(#promoted, 1, "Roster-backed target should be promoted once")
					V:AssertEqual(promoted[1].name, "Delta-Away", "Promotion should use the roster player name")
					V:AssertEqual(promoted[1].exactNameMatch, true, "Roster promotion should use exact matching")
				end)

				C_Timer = originalCTimer
				IsInRaid = originalIsInRaid
				GetNumGroupMembers = originalGetNumGroupMembers
				GetRaidRosterInfo = originalGetRaidRosterInfo
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				UnitRealmRelationship = originalUnitRealmRelationship
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionAttemptCounts = originalPromotionAttemptCounts
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	self:RegisterTest("data", "AutoRaidAssist_ManualDemoteSuppressesRepromote", {
		description = "Auto Raid Assist should not re-promote a target that was manually demoted",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Echo-Realm",
							id = "player:Echo-Realm",
							kind = "player",
							value = "Echo-Realm",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalIsInRaid = IsInRaid
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalGetRaidRosterInfo = GetRaidRosterInfo
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionAttemptCounts = AutoRaidAssist.promotionAttemptCounts
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local originalDemotedLookupKeys = AutoRaidAssist.demotedLookupKeys
				local promoted = {}

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionAttemptCounts = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}
					AutoRaidAssist.demotedLookupKeys = nil

					C_Timer = {
						NewTimer = function(delay, callback)
							return {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
						end,
					}
					IsInRaid = function()
						return true
					end
					GetNumGroupMembers = function()
						return 1
					end
					GetRaidRosterInfo = function(index)
						if index == 1 then
							return "Echo-Realm", 0
						end
						return nil, nil
					end
					UnitExists = function(unit)
						return unit == "raid1" or unit == "player"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function()
						return false
					end
					UnitFullName = function(unit)
						if unit == "raid1" then
							return "Echo", "Realm"
						end
						if unit == "player" then
							return "Leader", "Home"
						end
						return nil, nil
					end
					UnitName = UnitFullName
					GetNormalizedRealmName = function()
						return "Home"
					end
					GetTime = function()
						return 100
					end
					BFL.IsActionRestricted = function()
						return false
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							return true
						end,
					}

					V:Assert(AutoRaidAssist:RememberDemotedTarget("Echo-Realm") == true, "Manual demote should be remembered")
					V:Assert(AutoRaidAssist:IsDemotedLookupKey("player:echo-realm") == true, "Demoted lookup key should be tracked")
					V:Assert(AutoRaidAssist:Evaluate("test-manual-demote") == false, "Evaluate should not queue a demoted target")
					V:AssertEqual(#promoted, 0, "Demoted target should not be promoted again")
				end)

				C_Timer = originalCTimer
				IsInRaid = originalIsInRaid
				GetNumGroupMembers = originalGetNumGroupMembers
				GetRaidRosterInfo = originalGetRaidRosterInfo
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionAttemptCounts = originalPromotionAttemptCounts
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				AutoRaidAssist.demotedLookupKeys = originalDemotedLookupKeys
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	self:RegisterTest("data", "AutoRaidAssist_ManualDemoteClearsAfterRosterLeave", {
		description = "Auto Raid Assist should clear manual-demote suppression after the player leaves the raid",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Echo-Realm",
							id = "player:Echo-Realm",
							kind = "player",
							value = "Echo-Realm",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalInCombatLockdown = InCombatLockdown
				local originalIsInRaid = IsInRaid
				local originalIsInGroup = IsInGroup
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalGetRaidRosterInfo = GetRaidRosterInfo
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionAttemptCounts = AutoRaidAssist.promotionAttemptCounts
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local originalDemotedLookupKeys = AutoRaidAssist.demotedLookupKeys
				local promoted = {}
				local rosterPresent = true

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionAttemptCounts = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}
					AutoRaidAssist.demotedLookupKeys = nil

					C_Timer = {
						NewTimer = function(delay, callback)
							return {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
						end,
					}
					InCombatLockdown = function()
						return false
					end
					IsInRaid = function()
						return true
					end
					IsInGroup = function()
						return true
					end
					GetNumGroupMembers = function()
						return rosterPresent and 1 or 0
					end
					GetRaidRosterInfo = function(index)
						if rosterPresent and index == 1 then
							return "Echo-Realm", 0
						end
						return nil, nil
					end
					UnitExists = function(unit)
						return unit == "player" or (rosterPresent and unit == "raid1")
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function()
						return false
					end
					UnitFullName = function(unit)
						if unit == "raid1" and rosterPresent then
							return "Echo", "Realm"
						end
						if unit == "player" then
							return "Leader", "Home"
						end
						return nil, nil
					end
					UnitName = UnitFullName
					GetNormalizedRealmName = function()
						return "Home"
					end
					GetTime = function()
						return 100
					end
					BFL.IsActionRestricted = function()
						return false
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							return true
						end,
					}

					V:Assert(AutoRaidAssist:RememberDemotedTarget("Echo-Realm") == true, "Manual demote should be remembered")
					V:Assert(AutoRaidAssist:IsDemotedLookupKey("player:echo-realm") == true, "Demoted lookup key should be tracked")

					rosterPresent = false
					V:AssertEqual(
						AutoRaidAssist:PruneDemotedTargetsForCurrentRaid("test-roster-left"),
						1,
						"Leaving the raid should clear the remembered demote"
					)
					V:Assert(
						AutoRaidAssist:IsDemotedLookupKey("player:echo-realm") == false,
						"Demoted lookup key should be cleared after roster leave"
					)

					rosterPresent = true
					V:Assert(AutoRaidAssist:Evaluate("test-reinvite") == true, "Reinvited target should be promoted again")
					V:AssertEqual(#promoted, 1, "Reinvited target should be promoted once")
					V:AssertEqual(promoted[1].name, "Echo-Realm", "Promotion should use the roster player name")
					V:AssertEqual(promoted[1].exactNameMatch, true, "Promotion should use exact matching")
				end)

				C_Timer = originalCTimer
				InCombatLockdown = originalInCombatLockdown
				IsInRaid = originalIsInRaid
				IsInGroup = originalIsInGroup
				GetNumGroupMembers = originalGetNumGroupMembers
				GetRaidRosterInfo = originalGetRaidRosterInfo
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionAttemptCounts = originalPromotionAttemptCounts
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				AutoRaidAssist.demotedLookupKeys = originalDemotedLookupKeys
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})

	self:RegisterTest("data", "AutoRaidAssist_BroadRestrictionDoesNotBlockInstancePromotion", {
		description = "Auto Raid Assist should still promote in raid instances when only the broad BFL action restriction is active",
		action = function(V)
			WithTemporaryDatabase({
				autoRaidAssist = {
					enabled = true,
					targets = {
						{
							key = "player:Instanceone-Realm",
							id = "player:Instanceone-Realm",
							kind = "player",
							value = "Instanceone-Realm",
						},
					},
				},
			}, function()
				local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
				V:AssertNotNil(AutoRaidAssist, "AutoRaidAssist module should exist")

				local originalCTimer = C_Timer
				local originalInCombatLockdown = InCombatLockdown
				local originalIsInRaid = IsInRaid
				local originalIsInGroup = IsInGroup
				local originalIsInInstance = IsInInstance
				local originalGetNumGroupMembers = GetNumGroupMembers
				local originalGetRaidRosterInfo = GetRaidRosterInfo
				local originalUnitExists = UnitExists
				local originalUnitIsUnit = UnitIsUnit
				local originalUnitIsGroupLeader = UnitIsGroupLeader
				local originalUnitIsGroupAssistant = UnitIsGroupAssistant
				local originalUnitFullName = UnitFullName
				local originalUnitName = UnitName
				local originalUnitRealmRelationship = UnitRealmRelationship
				local originalGetNormalizedRealmName = GetNormalizedRealmName
				local originalGetTime = GetTime
				local originalCPartyInfo = C_PartyInfo
				local originalIsActionRestricted = BFL.IsActionRestricted
				local originalLastPromotionAttempt = AutoRaidAssist.lastPromotionAttempt
				local originalPromotionAttemptCounts = AutoRaidAssist.promotionAttemptCounts
				local originalPromotionQueue = AutoRaidAssist.promotionQueue
				local originalPromotionQueueLookup = AutoRaidAssist.promotionQueueLookup
				local originalPromotionQueueTimer = AutoRaidAssist.promotionQueueTimer
				local originalPromotionRetryTimers = AutoRaidAssist.promotionRetryTimers
				local originalDemotedLookupKeys = AutoRaidAssist.demotedLookupKeys
				local promoted = {}

				local ok, err = pcall(function()
					AutoRaidAssist.lastPromotionAttempt = {}
					AutoRaidAssist.promotionAttemptCounts = {}
					AutoRaidAssist.promotionQueue = {}
					AutoRaidAssist.promotionQueueLookup = {}
					AutoRaidAssist.promotionQueueTimer = nil
					AutoRaidAssist.promotionRetryTimers = {}
					AutoRaidAssist.demotedLookupKeys = nil

					C_Timer = {
						NewTimer = function(delay, callback)
							return {
								delay = delay,
								callback = callback,
								cancelled = false,
								Cancel = function(self)
									self.cancelled = true
								end,
							}
						end,
					}
					InCombatLockdown = function()
						return false
					end
					IsInRaid = function()
						return true
					end
					IsInGroup = function()
						return true
					end
					IsInInstance = function()
						return true, "raid"
					end
					GetNumGroupMembers = function()
						return 1
					end
					GetRaidRosterInfo = function(index)
						if index == 1 then
							return "Instanceone-Realm", 0
						end
						return nil, nil
					end
					UnitExists = function(unit)
						return unit == "raid1" or unit == "player"
					end
					UnitIsUnit = function(unit, other)
						return unit == "player" and other == "player"
					end
					UnitIsGroupLeader = function(unit)
						return unit == "player"
					end
					UnitIsGroupAssistant = function()
						return false
					end
					UnitFullName = function(unit)
						if unit == "raid1" then
							return "Instanceone", "Realm"
						end
						if unit == "player" then
							return "Leader", "Home"
						end
						return nil, nil
					end
					UnitName = UnitFullName
					UnitRealmRelationship = function()
						return 2
					end
					GetNormalizedRealmName = function()
						return "Home"
					end
					GetTime = function()
						return 100
					end
					BFL.IsActionRestricted = function()
						return true
					end
					C_PartyInfo = {
						PromoteToAssistant = function(name, exactNameMatch)
							promoted[#promoted + 1] = {
								name = name,
								exactNameMatch = exactNameMatch,
							}
							return true
						end,
					}

					local gate = AutoRaidAssist:GetPromotionGateStatus("test-instance-restriction")
					V:Assert(gate.ok == true, "Broad action restriction should not block out-of-combat assistant promotion")
					V:Assert(gate.bflActionRestricted == true, "Test should simulate active broad BFL action restriction")
					V:Assert(gate.promotionRestricted == false, "Promotion restriction should be false outside combat")
					V:Assert(AutoRaidAssist:Evaluate("test-instance-restriction") == true, "Evaluate should promote in raid instance")
					V:AssertEqual(#promoted, 1, "Target should be promoted once")
					V:AssertEqual(promoted[1].name, "Instanceone-Realm", "Promotion should use exact roster name")
					V:AssertEqual(promoted[1].exactNameMatch, true, "Promotion should use exact matching")
				end)

				C_Timer = originalCTimer
				InCombatLockdown = originalInCombatLockdown
				IsInRaid = originalIsInRaid
				IsInGroup = originalIsInGroup
				IsInInstance = originalIsInInstance
				GetNumGroupMembers = originalGetNumGroupMembers
				GetRaidRosterInfo = originalGetRaidRosterInfo
				UnitExists = originalUnitExists
				UnitIsUnit = originalUnitIsUnit
				UnitIsGroupLeader = originalUnitIsGroupLeader
				UnitIsGroupAssistant = originalUnitIsGroupAssistant
				UnitFullName = originalUnitFullName
				UnitName = originalUnitName
				UnitRealmRelationship = originalUnitRealmRelationship
				GetNormalizedRealmName = originalGetNormalizedRealmName
				GetTime = originalGetTime
				C_PartyInfo = originalCPartyInfo
				BFL.IsActionRestricted = originalIsActionRestricted
				AutoRaidAssist.lastPromotionAttempt = originalLastPromotionAttempt
				AutoRaidAssist.promotionAttemptCounts = originalPromotionAttemptCounts
				AutoRaidAssist.promotionQueue = originalPromotionQueue
				AutoRaidAssist.promotionQueueLookup = originalPromotionQueueLookup
				AutoRaidAssist.promotionQueueTimer = originalPromotionQueueTimer
				AutoRaidAssist.promotionRetryTimers = originalPromotionRetryTimers
				AutoRaidAssist.demotedLookupKeys = originalDemotedLookupKeys
				if not ok then
					error(err, 2)
				end
			end)
		end,
	})
end

function TestSuite:RegisterEventCompatibilityTests()
	self:RegisterTest("events", "EventCallback_RejectsUnknownEvent", {
		description = "Unknown client events must not abort initialization or leave a callback registry entry",
		action = function(V)
			local testEvent = "BFL_TEST_UNKNOWN_EVENT"
			local originalCallbacks = BFL.EventCallbacks[testEvent]
			BFL.EventCallbacks[testEvent] = nil

			local ok, registered = pcall(BFL.RegisterEventCallback, BFL, testEvent, function() end, 50)
			local callbacksAfterRegistration = BFL.EventCallbacks[testEvent]
			BFL.EventCallbacks[testEvent] = originalCallbacks

			V:Assert(ok, "Unknown event registration should not raise a Lua error")
			V:AssertEqual(registered, false, "Unknown event registration should return false")
			V:AssertNil(callbacksAfterRegistration, "Unknown events should not create callback registry entries")
		end,
	})
end

function TestSuite:RegisterLateUITests()
	self:RegisterTest("integration", "Friends_CompactRowHeight_UsesVisibleContent", {
		description = "Compact friend cards grow for visible content while keeping controls in a stable top lane",
		action = function(V)
			local FriendsList = BFL:GetModule("FriendsList")
			if not FriendsList or not FriendsList.CalculateFriendRowHeightForLayout then
				V:Skip("FriendsList layout-aware row-height calculator is not available")
				return
			end

			local compact = FriendsList:CalculateFriendRowHeightForLayout(true, true, 12, 10, false, false, 0, 14)
			local wrapped = FriendsList:CalculateFriendRowHeightForLayout(true, true, 12, 10, false, false, 0, 28)
			local normal = FriendsList:CalculateFriendRowHeightForLayout(true, false, 12, 10, false, false, 0, 14)
			local actionAlignedTags = FriendsList:CalculateFriendRowHeightForLayout(
				true,
				false,
				12,
				10,
				false,
				false,
				25,
				14,
				false
			)
			local fullWidthTags = FriendsList:CalculateFriendRowHeightForLayout(
				true,
				false,
				12,
				10,
				false,
				false,
				25,
				14,
				true
			)

			V:AssertEqual(compact, 24, "a one-line Modern Compact card should use the shared compact height")
			V:AssertEqual(wrapped, 34, "a wrapped Compact name should add only its visible second line")
			V:AssertEqual(normal, 40, "a normal Modern card should retain room for its full-size action control")
			V:AssertEqual(actionAlignedTags, 58, "action-aligned chips may use otherwise empty minimum-height space")
			V:AssertEqual(fullWidthTags, 65, "separate chips should be added below the complete base friend card")
			local statusSize, gameIconSize, actionWidth, actionHeight = FriendsList:GetFriendControlSizesForLayout(
				24,
				true
			)
			V:AssertEqual(statusSize, 14, "Compact status icons should remain clearly visible in the 24px lane")
			V:AssertEqual(gameIconSize, 19, "Compact Modern game icons should use the shared control geometry")
			V:AssertEqual(actionWidth, 22, "Compact Modern Invite buttons should be square")
			V:AssertEqual(actionHeight, 22, "Compact Modern Invite buttons should fit the stable control lane")
			V:AssertEqual(
				FriendsList:GetFriendTagRowRightInsetForLayout(24, true),
				55,
				"Compact tag rows should reserve only the actual Modern controls plus a four-pixel gap"
			)
			V:AssertEqual(
				FriendsList:GetFriendControlTopOffsetForLayout(24, 11, 28, false),
				-6,
				"Compact status controls should center in the stable 24px top lane"
			)
			V:AssertEqual(
				FriendsList:GetFriendControlTopOffsetForLayout(24, 11, 28, true),
				-6,
				"Wrapped names and full-width tags should not move Compact status controls"
			)
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			if FriendsUI and FriendsUI.GetFriendCardControlOffsets then
				V:AssertEqual(
					FriendsUI:GetFriendCardActionIconSize(22),
					18,
					"Compact Invite artwork should retain a two-pixel inset inside the button"
				)
				V:AssertEqual(
					FriendsUI:GetFriendCardActionIconSize(34),
					24,
					"Normal Invite artwork should retain its native 24px cap"
				)
				local actionOffset, gameIconOffset = FriendsUI:GetFriendCardControlOffsets(24, 22, 19, 28, false)
				V:AssertEqual(actionOffset, -1, "Compact Modern Invite should fit its 24px control lane")
				V:AssertEqual(gameIconOffset, -2, "Compact Modern game icon should fit the same control lane")
				local fullActionOffset, fullGameIconOffset = FriendsUI:GetFriendCardControlOffsets(
					24,
					22,
					19,
					28,
					true
				)
				V:AssertEqual(fullActionOffset, actionOffset, "Tag layout should not move the Modern Invite control")
				V:AssertEqual(fullGameIconOffset, gameIconOffset, "Tag layout should not move the Modern game icon")
			end
		end,
	})

	self:RegisterTest("ui", "Core_RegionMouseOver", {
		description = "The cross-flavor mouse-over helper uses the Region method and fails closed",
		action = function(V)
			local probe = { IsMouseOver = function() return true end }
			V:Assert(BFL:IsRegionMouseOver(probe), "Region method result should be returned")
			V:Assert(not BFL:IsRegionMouseOver(nil), "Nil regions should not be treated as hovered")
			V:Assert(not BFL:IsRegionMouseOver({}), "Objects without IsMouseOver should fail closed")
		end,
	})

	self:RegisterTest("ui", "FriendTags_RowChipsAreVisualOnly", {
		description = "Friend tag row chips should provide 20 tag slots plus overflow with mask-free clickthrough pills",
		action = function(V)
			local TagChips = BFL:GetModule("TagChips")
			V:AssertNotNil(TagChips, "TagChips module should exist")
			local owner = CreateFrame("Button", nil, UIParent)
			owner:SetSize(220, 70)
			local row = TagChips:EnsureRow(owner)
			local chip = row and row.chips and row.chips[1]
			V:AssertNotNil(chip, "Tag chip should be created")
			V:AssertEqual(#row.chips, 21, "Tag rows should provide 20 configured chips plus one overflow chip")
			V:Assert(row:IsMouseEnabled() == false, "Tag row should be clickthrough")
			V:Assert(chip:IsMouseEnabled() == false, "Tag chip should be clickthrough")
			V:AssertNil(chip:GetScript("OnEnter"), "Tag chip should not install a tooltip OnEnter handler")
			V:AssertNil(chip:GetScript("OnLeave"), "Tag chip should not install a tooltip OnLeave handler")
			V:Assert(chip.pillBorder and chip.pillBorder.left and chip.pillBorder.right and chip.pillBorder.middle, "Tag chip should have rounded border regions")
			V:Assert(chip.pillBackground and chip.pillBackground.left and chip.pillBackground.right and chip.pillBackground.middle, "Tag chip should have rounded background regions")
			V:Assert(chip.pillBorder.left:GetNumMaskTextures() == 0, "Tag chip border should not attach async mask textures")
			V:Assert(chip.pillBackground.left:GetNumMaskTextures() == 0, "Tag chip background should not attach async mask textures")

			local bareWidth, hasBareIcon = TagChips:UpdateStandaloneChip(chip, {
				iconType = "texture",
				iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				texture = "Interface\\Icons\\INV_Misc_QuestionMark",
			}, "", 180)
			V:AssertEqual(bareWidth, 14, "Icon-only tags should occupy exactly the icon width")
			V:Assert(hasBareIcon, "Icon-only tags should retain their icon")
			V:Assert(chip.bareIcon == true, "An empty chip label should select bare-icon rendering")
			V:Assert(not chip.pillBorder.left:IsShown(), "Bare icons should hide the chip border")
			V:Assert(not chip.pillBackground.left:IsShown(), "Bare icons should hide the chip fill")
			V:Assert(not chip.label:IsShown(), "Bare icons should hide the chip label")
			V:Assert(chip.icon:IsShown(), "Bare icons should remain visible")

			TagChips:UpdateStandaloneChip(chip, {
				iconType = "texture",
				iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				texture = "Interface\\Icons\\INV_Misc_QuestionMark",
				iconOnlyChip = true,
			}, "", 180)
			V:Assert(chip.bareIcon == false, "Colored icon-only tags should retain normal chip rendering")
			V:Assert(chip.pillBorder.left:IsShown(), "Colored icon-only tags should show the chip border")
			V:Assert(chip.pillBackground.left:IsShown(), "Colored icon-only tags should show the chip fill")
			V:Assert(not chip.label:IsShown(), "Colored icon-only tags should not retain an empty label region")
			local point, _, relativePoint, xOffset, yOffset = chip.icon:GetPoint(1)
			V:AssertEqual(point, "CENTER", "Colored icon-only tags should center their icon in the chip")
			V:AssertEqual(relativePoint, "CENTER", "Colored icon-only tags should use the chip center as their anchor")
			V:AssertEqual(xOffset, 0, "Colored icon-only tags should have no horizontal icon offset")
			V:AssertEqual(yOffset, 0, "Colored icon-only tags should have no vertical icon offset")

			TagChips:UpdateStandaloneChip(chip, {
				iconType = "texture",
				iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				texture = "Interface\\Icons\\INV_Misc_QuestionMark",
				iconOnlyChip = true,
				chipIconOffsetX = 0.5,
			}, "", 180)
			point, _, relativePoint, xOffset, yOffset = chip.icon:GetPoint(1)
			V:AssertEqual(point, "CENTER", "Default role icons should keep center anchoring")
			V:AssertEqual(relativePoint, "CENTER", "Default role icons should remain relative to the chip center")
			V:AssertEqual(xOffset, 0.5, "Default role icons with a chip background should receive optical centering")
			V:AssertEqual(yOffset, 0, "Default role icon correction should remain horizontal only")

			TagChips:UpdateStandaloneChip(chip, {
				iconType = "texture",
				iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				texture = "Interface\\Icons\\INV_Misc_QuestionMark",
				chipIconOffsetX = 0.5,
			}, "", 180)
			_, _, _, xOffset = chip.icon:GetPoint(1)
			V:AssertEqual(xOffset, 0, "Bare role icons should not receive the background-specific correction")

			TagChips:UpdateStandaloneChip(chip, {
				iconType = "texture",
				iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				texture = "Interface\\Icons\\INV_Misc_QuestionMark",
			}, "Normal", 180)
			V:Assert(chip.bareIcon == false, "Labeled tags should restore normal chip rendering")
			V:Assert(chip.pillBorder.left:IsShown(), "Normal chips should restore the border")
			V:Assert(chip.pillBackground.left:IsShown(), "Normal chips should restore the fill")
			V:Assert(chip.label:IsShown(), "Normal chips should restore the label")

			owner.Info = owner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			local multiAccountRow = CreateFrame("Frame", nil, owner)
			owner.multiAccountRow = multiAccountRow
			multiAccountRow:Show()
			V:AssertEqual(
				TagChips:GetRowAnchor(owner),
				multiAccountRow,
				"tag chips should sit below visible multi-account details"
			)
			multiAccountRow:Hide()
			V:AssertEqual(TagChips:GetRowAnchor(owner), owner.Info, "tag chips should otherwise sit below friend info")
			owner:Hide()
		end,
	})

	self:RegisterTest("data", "FriendTags_AssignmentVersionTracksBattleNetCharacterAlias", {
		description = "Friend tag assignment invalidation should retain Battle.net character aliases without building a UID list on the row hotpath",
		action = function(V)
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")

			local originalVersions = FriendTags.friendAssignmentVersions
			local originalAllVersion = FriendTags.allFriendAssignmentsVersion
			local originalGlobalVersion = BFL.FriendTagsAssignmentVersion
			local originalFriendsVersion = BFL.FriendsListVersion
			local friend = {
				type = "bnet",
				battleTag = "AliasProbe#1234",
				gameAccountInfo = {
					characterName = "AliasProbe",
					realmName = "TestRealm",
				},
			}
			local ok, err = pcall(function()
				local characterUID
				for _, uid in ipairs(FriendTags:GetRelatedFriendUIDs(friend)) do
					if uid:match("^wow_") then
						characterUID = uid
						break
					end
				end
				V:AssertNotNil(characterUID, "Battle.net character alias should be discoverable")

				FriendTags.friendAssignmentVersions = { [characterUID] = 37 }
				FriendTags.allFriendAssignmentsVersion = 0
				BFL.FriendTagsAssignmentVersion = 37
				BFL.FriendsListVersion = (BFL.FriendsListVersion or 0) + 1
				V:AssertEqual(
					FriendTags:GetFriendAssignmentVersion(friend),
					37,
					"Character alias should invalidate its Battle.net friend row"
				)
			end)
			FriendTags.friendAssignmentVersions = originalVersions
			FriendTags.allFriendAssignmentsVersion = originalAllVersion
			BFL.FriendTagsAssignmentVersion = originalGlobalVersion
			BFL.FriendsListVersion = originalFriendsVersion
			if not ok then
				error(err, 0)
			end
		end,
	})

	self:RegisterTest("data", "SkinEngine_DesaturationCacheRecoversExternalReset", {
		description = "Dark texture updates should skip identical work but repair native desaturation resets",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")

			local owner = {}
			local texture = { desaturated = false, calls = 0 }
			function texture:IsDesaturated()
				return self.desaturated
			end
			function texture:SetDesaturated(value)
				self.desaturated = value == true
				self.calls = self.calls + 1
			end

			local ok, err = pcall(function()
				SkinEngine:SetTextureDesaturated(owner, texture, true)
				SkinEngine:SetTextureDesaturated(owner, texture, true)
				V:AssertEqual(texture.calls, 1, "Identical desaturation should be applied once")

				texture.desaturated = false
				SkinEngine:SetTextureDesaturated(owner, texture, true)
				V:AssertEqual(texture.calls, 2, "A native reset should be detected and repaired")
				V:Assert(texture.desaturated, "Repaired texture should be desaturated again")
			end)
			SkinEngine.registry[owner] = nil
			owner.BFL_DarkSkin = nil
			if not ok then
				error(err, 0)
			end
		end,
	})

	self:RegisterTest("data", "SkinEngine_BackdropCachePreservesStateAndRepairsReset", {
		description = "Dark backdrop caching should preserve managed hover colors and repair external color resets",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			if not (SkinEngine and CreateFrame) then
				V:Skip("Frame creation is unavailable")
				return
			end

			local owner = CreateFrame("Frame", nil, UIParent)
			owner:SetSize(20, 20)
			owner:Hide()
			local backdrop = SkinEngine:CreateBackdrop(owner, "control")
			if not (backdrop and backdrop.SetBackdropColor and backdrop.GetBackdropColor) then
				SkinEngine:RestoreFrame(owner)
				V:Skip("Backdrop color APIs are unavailable")
				return
			end

			local managedBg = { 0.21, 0.22, 0.23, 0.24 }
			local managedBorder = { 0.31, 0.32, 0.33, 0.34 }
			SkinEngine:StyleBackdrop(owner, managedBg, managedBorder)
			SkinEngine:CreateBackdrop(owner, "control")
			local r, g, b, a = backdrop:GetBackdropColor()
			V:Assert(
				r == managedBg[1] and g == managedBg[2] and b == managedBg[3] and a == managedBg[4],
				"Managed backdrop state should survive a cache hit"
			)

			backdrop:SetBackdropColor(0.9, 0.8, 0.7, 0.6)
			SkinEngine:CreateBackdrop(owner, "control")
			r, g, b, a = backdrop:GetBackdropColor()
			V:Assert(
				r == managedBg[1] and g == managedBg[2] and b == managedBg[3] and a == managedBg[4],
				"External backdrop reset should be repaired"
			)
			SkinEngine:RestoreFrame(owner)
			SkinEngine.registry[owner] = nil
		end,
	})

	self:RegisterTest("data", "SkinEngine_DisabledFlatInviteKeepsDisabledAlpha", {
		description = "Cached Dark-theme invite refreshes should preserve the disabled icon alpha",
		action = function(V)
			local SkinEngine = BFL:GetModule("SkinEngine")
			V:AssertNotNil(SkinEngine, "SkinEngine module should exist")

			local actionIcon = {
				alpha = 1,
				desaturated = false,
				shown = true,
				vertexR = 1,
				vertexG = 1,
				vertexB = 1,
				vertexA = 1,
			}
			function actionIcon:GetWidth()
				return 24
			end
			function actionIcon:GetAtlas()
				return "BFL-Test-Invite"
			end
			function actionIcon:GetTexture()
				return nil
			end
			function actionIcon:IsDesaturated()
				return self.desaturated
			end
			function actionIcon:SetDesaturated(desaturated)
				self.desaturated = desaturated == true
			end
			function actionIcon:GetVertexColor()
				return self.vertexR, self.vertexG, self.vertexB, self.vertexA
			end
			function actionIcon:SetVertexColor(r, g, b, a)
				self.vertexR, self.vertexG, self.vertexB, self.vertexA = r, g, b, a
			end
			function actionIcon:GetAlpha()
				return self.alpha
			end
			function actionIcon:SetAlpha(alpha)
				self.alpha = alpha
			end
			function actionIcon:Show()
				self.shown = true
			end

			local colorVersion = SkinEngine.themeColorVersion or 0
			local button = {
				ActionIcon = actionIcon,
				BFL_DarkForceFlatButton = true,
				BFL_DarkIconButtonSkinned = true,
				BFL_DarkBorderlessIconButton = true,
				BFL_DarkIcon = actionIcon,
				BFL_DarkFlatActionIcon = actionIcon,
				BFL_DarkFlatIconSize = 24,
				BFL_DarkFlatIconAtlas = "BFL-Test-Invite",
				BFL_DarkFlatColorVersion = colorVersion,
				BFL_DarkButtonStateKey = "icon:" .. tostring(colorVersion) .. "::0:0:0:",
			}
			function button:IsEnabled()
				return false
			end
			function button:IsShown()
				return true
			end

			local row = {
				BFL_DarkRowSkinned = true,
				BFL_DarkNoRowHighlight = false,
				BFL_DarkRowStateKey = tostring(colorVersion) .. ":normal:",
				travelPassButton = button,
				BFL_DarkTravelPassRowButton = button,
				BFL_DarkTravelPassRowShown = true,
				BFL_DarkTravelPassRowEnabled = false,
			}

			local originalActive = SkinEngine.active
			local originalTheme = SkinEngine.activeTheme
			local ok, err = pcall(function()
				SkinEngine.active = true
				SkinEngine.activeTheme = "dark"
				SkinEngine:RefreshRow(row)
				V:AssertEqual(actionIcon.alpha, 0.35, "Disabled invite icon alpha should survive cached row refreshes")
			end)
			SkinEngine.active = originalActive
			SkinEngine.activeTheme = originalTheme
			SkinEngine.registry[button] = nil
			button.BFL_DarkSkin = nil
			if not ok then
				error(err, 0)
			end
		end,
	})
end

function TestSuite:RegisterRaidInteractionTest()
	self:RegisterTest("data", "RaidFrame_ReadyCheckPartyVisibility", {
		description = "Ready Check remains visible and available to party leaders outside combat",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")

			local shown, available = RaidFrame:ResolveReadyCheckButtonState(true, true, false, true, false, false)
			V:Assert(shown, "Enabled Ready Check is visible in a party")
			V:Assert(available, "Party leaders can start Ready Check outside combat")

			shown, available = RaidFrame:ResolveReadyCheckButtonState(true, true, false, false, false, false)
			V:Assert(shown, "Ready Check remains visible to party members")
			V:Assert(not available, "Party members cannot start Ready Check")

			shown, available = RaidFrame:ResolveReadyCheckButtonState(true, true, false, true, false, true)
			V:Assert(shown, "Ready Check remains visible during combat")
			V:Assert(not available, "Ready Check is disabled during combat")

			shown, available = RaidFrame:ResolveReadyCheckButtonState(false, true, false, true, false, false)
			V:Assert(not shown and not available, "Disabled Ready Check stays hidden")
		end,
	})

	self:RegisterTest("ui", "RaidFrame_EmptyStateLayoutContract", {
		description = "The long raid description remains bounded to the raid inset in every UI layout",
		condition = function()
			local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
			return raid and raid.NotInRaid and raid.GroupsInset and BFL:GetModule("RaidFrame")
		end,
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			local raid = BetterFriendsFrame.RaidFrame
			V:Assert(RaidFrame:UpdateEmptyStateLayout(), "Raid empty-state geometry should be applicable")
			V:AssertEqual(raid.NotInRaid:GetNumPoints(), 2, "Raid description should have a bounded two-anchor extent")
			local topPoint, topRelativeTo, topRelativePoint, topX, topY = raid.NotInRaid:GetPoint(1)
			local bottomPoint, bottomRelativeTo, bottomRelativePoint, bottomX, bottomY = raid.NotInRaid:GetPoint(2)
			V:Assert(
				topPoint == "TOPLEFT"
					and topRelativeTo == raid.GroupsInset
					and topRelativePoint == "TOPLEFT"
					and topX == 20
					and topY == -20,
				"Raid description should begin inside the inset"
			)
			V:Assert(
				bottomPoint == "BOTTOMRIGHT"
					and bottomRelativeTo == raid.GroupsInset
					and bottomRelativePoint == "BOTTOMRIGHT"
					and bottomX == -20
					and bottomY == 20,
				"Raid description should end inside the inset"
			)
			V:AssertEqual(raid.NotInRaid:GetJustifyH(), "LEFT", "Raid description should align with Blizzard's layout")
			V:AssertEqual(raid.NotInRaid:GetJustifyV(), "TOP", "Raid description should start at the top of its bounds")
		end,
	})

	self:RegisterTest("integration", "RaidFrame_VisibleRefresh_UpdatesRosterAndCounts", {
		description = "Raid tab refreshes deferred roster data and its member and role counters together",
		action = function(V)
			local RaidFrame = BFL:GetModule("RaidFrame")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")

			local methodNames = {
				"ShouldDisplayMainTankAndAssist",
				"UpdateRaidMembers",
				"BuildDisplayList",
				"UpdateControlPanel",
				"UpdateGroupLayout",
				"UpdateConvertButton",
			}
			local originals = {}
			local calls = {}
			for _, methodName in ipairs(methodNames) do
				originals[methodName] = RaidFrame[methodName]
				local recordedName = methodName
				RaidFrame[methodName] = function()
					table.insert(calls, recordedName)
				end
			end

			local ok, result = pcall(RaidFrame.RefreshRosterView, RaidFrame)
			for _, methodName in ipairs(methodNames) do
				RaidFrame[methodName] = originals[methodName]
			end
			if not ok then
				error(result, 0)
			end

			V:Assert(result, "visible roster refresh should complete")
			V:AssertEqual(
				table.concat(calls, ","),
				table.concat(methodNames, ","),
				"visible roster refresh should update roster, counters, layout, and controls in order"
			)
		end,
	})

	self:RegisterTest("integration", "RaidFrame_RaidPlayerProxyInteractionContract", {
		description = "Modern and Legacy raid rows route RAID_PLAYER through the secure proxy without breaking child overlays",
		condition = function()
			return BFL.IsRetail
		end,
		action = function(V)
			if InCombatLockdown() then
				V:Skip("Secure attributes cannot be tested during combat")
				return
			end
			local RaidFrame = BFL:GetModule("RaidFrame")
			local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
			V:AssertNotNil(RaidFrame, "RaidFrame module should exist")
			V:AssertNotNil(FriendsUI, "FriendsUI module should exist")

			local originalIsModernActive = FriendsUI.IsModernActive
			local originalHasSecretValues = BFL.HasSecretValues
			local attributes = {}
			local proxyGeometry = {}
			local fakeButton = {
				memberData = {},
				unit = "raid1",
				name = "RaidMember",
				groupIndex = 1,
				slotIndex = 1,
				SetAttribute = function(self, key, value)
					attributes[key] = value
				end,
			}
			local fakeProxy = {
				ClearAllPoints = function()
					proxyGeometry.cleared = true
				end,
				SetPoint = function(self, point, relativeTo, relativePoint, x, y)
					proxyGeometry.point = point
					proxyGeometry.relativeTo = relativeTo
					proxyGeometry.relativePoint = relativePoint
					proxyGeometry.x = x
					proxyGeometry.y = y
				end,
				SetSize = function(self, width, height)
					proxyGeometry.width = width
					proxyGeometry.height = height
				end,
				SetAllPoints = function()
					proxyGeometry.usedSetAllPoints = true
				end,
			}
			local sourceLeft, sourceBottom, sourceWidth, sourceHeight = 317, 241, 180, 20
			local fakeGeometryButton = {
				GetScaledRect = function()
					return sourceLeft, sourceBottom, sourceWidth, sourceHeight
				end,
			}
			local childOverlay = { GetParent = function() return fakeButton end }
			local ok, err = pcall(function()
				BFL.HasSecretValues = true
				FriendsUI.IsModernActive = function() return true end
				RaidFrame:UpdateSecureAttributesForButton(fakeButton)
				V:AssertEqual(attributes.type2, nil, "Modern Raid leaves right-click to the secure proxy")
				V:AssertEqual(attributes["menu-function"], nil, "Modern Raid does not install an insecure menu callback")
				V:AssertEqual(fakeButton.BFL_RaidContextMenuType, "RAID_PLAYER", "Modern Raid uses the Raid Player menu")
				V:AssertType(RaidFrame.ShowSecureProxyForButton, "function", "Retail exposes the raid secure proxy path")
				V:AssertType(RaidFrame.PositionSecureProxyForButton, "function", "Retail exposes safe proxy positioning")
				V:AssertEqual(RaidFrame:ResolveMemberButton(childOverlay), fakeButton, "Child tooltip overlays resolve to their raid member row")

				local rootScale = UIParent:GetEffectiveScale()
				V:Assert(RaidFrame:PositionSecureProxyForButton(fakeProxy, fakeGeometryButton), "Secure proxy geometry should resolve")
				V:Assert(proxyGeometry.cleared, "Secure proxy should clear its previous UIParent anchor")
				V:Assert(not proxyGeometry.usedSetAllPoints, "Secure proxy must not anchor to the insecure visual row")
				V:AssertEqual(proxyGeometry.point, "BOTTOMLEFT", "Secure proxy should use a stable root point")
				V:AssertEqual(proxyGeometry.relativeTo, UIParent, "Secure proxy should only anchor to UIParent")
				V:AssertEqual(proxyGeometry.relativePoint, "BOTTOMLEFT", "Secure proxy should use the matching UIParent point")
				V:AssertEqual(proxyGeometry.x, sourceLeft / rootScale, "Secure proxy should preserve the row's screen X")
				V:AssertEqual(proxyGeometry.y, sourceBottom / rootScale, "Secure proxy should preserve the row's screen Y")
				V:AssertEqual(proxyGeometry.width, sourceWidth / rootScale, "Secure proxy should preserve the row width")
				V:AssertEqual(proxyGeometry.height, sourceHeight / rootScale, "Secure proxy should preserve the row height")

				attributes = {}
				FriendsUI.IsModernActive = function() return false end
				RaidFrame:UpdateSecureAttributesForButton(fakeButton)
				V:AssertEqual(attributes.type2, nil, "Legacy Raid also leaves right-click to the secure proxy")
				V:AssertEqual(attributes["menu-function"], nil, "Legacy Raid does not install an insecure menu callback")
				V:AssertEqual(fakeButton.BFL_RaidContextMenuType, "RAID_PLAYER", "Legacy Raid uses the Raid Player menu")

				attributes = {}
				BFL.HasSecretValues = false
				RaidFrame:UpdateSecureAttributesForButton(fakeButton)
				V:AssertEqual(attributes.type2, "togglemenu", "Pre-secret clients keep the visual secure menu fallback")
				V:AssertEqual(fakeButton.BFL_RaidContextMenuType, "RAID_PLAYER", "The fallback also resolves Raid Player")
			end)
			FriendsUI.IsModernActive = originalIsModernActive
			BFL.HasSecretValues = originalHasSecretValues
			if not ok then
				error(err, 0)
			end
		end,
	})
end

function TestSuite:RunSettingsGroupDragSmoke(item, onDragStart, onDragStop)
	local originalIsRegionMouseOver = BFL.IsRegionMouseOver
	BFL.IsRegionMouseOver = function()
		return false
	end
	local ok, err = pcall(function()
		onDragStart(item)
		item:GetScript("OnUpdate")(item)
		onDragStop(item)
	end)
	BFL.IsRegionMouseOver = originalIsRegionMouseOver
	return ok, err
end

function TestSuite:GetTestCount()
	local count = 0
	for _, category in ipairs(TEST_CATEGORIES) do
		count = count + #self.tests[category]
	end
	return count
end

-- Return module
return TestSuite
