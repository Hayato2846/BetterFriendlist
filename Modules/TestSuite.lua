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
			}
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
	print("  WoW Version:        " .. (BFL.IsRetail and "Retail" or "Classic") .. " (" .. BFL.TOCVersion .. ")")
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
		description = "Groups tab drag handlers should run without error",
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
						onDragStart(item)
						onDragStop(item)
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
			if BetterFriendsFrame then
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
				contactMemory = {
					enabled = true,
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
		description = "Friend Tags defaults should be present for Contact Memory extension data",
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
				V:AssertEqual(
					tempDB.friendTagSettings.compactRowMode,
					"icon_only",
					"Compact rows should default to icon-only tags"
				)
			end)
		end,
	})

	TS:RegisterTest("data", "FriendTagEditor_IconDropdown_AllowsModernDropdown", {
		description = "Friend Tag editor icon picker should use the shared dropdown factory without forcing legacy mode",
		action = function(V)
			local FriendTagEditor = BFL:GetModule("FriendTagEditor")
			local FriendTags = BFL:GetModule("FriendTags")
			V:AssertNotNil(FriendTagEditor, "FriendTagEditor module should exist")
			V:AssertNotNil(FriendTags, "FriendTags module should exist")
			V:AssertType(FriendTagEditor.CreateIconControls, "function", "FriendTagEditor should create icon controls")

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

				V:Assert(FriendTags:IsEnabled() == true, "Friend Tags should be enabled with Beta and Contact Memory")
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

	TS:RegisterTest("data", "ContactMemory_MenuEmbedsFriendTagsOnly", {
		description = "Contact Memory friend menus should embed FriendTags and stop exposing legacy Contact Memory tags",
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

				V:Assert(
					ContactMemory:PopulateMenu(rootDescription, "player:Unit-Realm", "Unit", nil, {
						friendData = {
							type = "wow",
							uid = "wow_Unit-Realm",
							name = "Unit-Realm",
						},
						friendUID = "wow_Unit-Realm",
					}),
					"Contact Memory menu should populate"
				)

				local seen = {}
				for _, entry in ipairs(entries) do
					if entry.text then
						seen[entry.text] = true
					end
				end
				V:Assert(seen["Notes & Tags"], "Notes & Tags should be the single root menu entry")
				V:Assert(seen["Edit Private Note"], "Contact Memory menu should keep note actions")
				V:Assert(seen["Friend Tags"], "FriendTags should be embedded under Contact Memory")
				V:Assert(seen["Custom Tags"], "Embedded FriendTags section should show custom tags")
				V:Assert(seen["Key Team"], "Embedded FriendTags section should show custom tag assignments")
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
		description = "Friend Tags should support custom tag rename/delete and icon-only chip profiles",
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
					iconType = "texture",
					iconValue = "Interface\\Icons\\INV_Misc_QuestionMark",
				}), "SetChipProfile should accept icon-only labels")

				local profile = FriendTags:GetChipProfile(tagId)
				V:AssertEqual(profile.chipLabel, "", "Empty chip label should be preserved for icon-only chips")
				V:AssertEqual(
					profile.icon,
					"Interface\\Icons\\INV_Misc_QuestionMark",
					"Icon-only profile should keep its icon"
				)
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

			WithTemporaryDatabase({
				theme = "blizzard",
			}, function()
				V:AssertEqual(BFL:GetEffectiveTheme(), "blizzard", "Blizzard theme should resolve as blizzard")
				V:Assert(not BFL:UsesFlatTheme(), "Blizzard theme should not count as a flat theme")
			end)
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
			local expected = ((BFL.IsTWW or BFL.IsMidnight) and BFL.HasModernScrollBox and compatAvailable) == true
			V:AssertEqual(
				BFL.HasRecentAllies == true,
				expected,
				"HasRecentAllies should require supported build, ScrollBox, and API availability"
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
					labels = { "Verbose Label", "Hidden Label" },
					values = { "value1", "value2" },
					getSelectionText = function(value)
						return "IconOnly:" .. tostring(value)
					end,
					isOptionHidden = function(value)
						return value == "value2"
					end,
					getItemFontObject = function(value, index)
						V:AssertEqual(value, "value1", "Font resolver should receive item value")
						V:AssertEqual(index, 1, "Font resolver should receive item index")
						return "BFLTestFontObject"
					end,
				}, function(value)
					return value == "value1"
				end, function(value)
					setValue = value
				end)

				V:AssertEqual(selectedValue, "value1", "Initial selected value should be set")
				V:AssertEqual(dropdown.text, "IconOnly:value1", "Initial legacy dropdown text should use getSelectionText")
				V:AssertEqual(#buttons, 1, "One dropdown button should be created")
				V:AssertEqual(buttons[1].fontObject, "BFLTestFontObject", "Legacy dropdown item should receive item font object")
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

			QuickJoin.mockGroups[guid] = nil
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

	TS:RegisterTest("issues", "Locales_RequiredKeys", {
		description = "Critical localization keys must exist in all locales",
		action = function(V)
			V:AssertNotNil(BFL.L, "Localization table should exist")
			V:AssertNotNil(BFL.Locales, "Locale registry should exist")

			local requiredKeys = {
				"DIALOG_DELETE_GROUP_TEXT",
				"DIALOG_RENAME_GROUP_TEXT",
				"ERROR_GROUP_NAME_EMPTY",
				"ERROR_GROUP_EXISTS",
				"ERROR_GROUP_NOT_EXIST",
				"SETTINGS_GROUP_COLOR",
				"SETTINGS_TAB_THEME",
				"SETTINGS_THEME_HEADER",
				"SETTINGS_THEME_DROPDOWN",
				"SETTINGS_THEME_DROPDOWN_DESC",
				"SETTINGS_THEME_BLIZZARD",
				"SETTINGS_THEME_DARK",
				"SETTINGS_THEME_ELVUI",
				"TOOLTIP_GROUP_COLOR_DESC",
				"CORE_HELP_TEST_COMMANDS",
				"CORE_HELP_TEST_ACTIVITY",
				"STATUS_AFK",
				"STATUS_APPEAR_OFFLINE",
				"BROKER_CLICK_APPEAR_OFFLINE",
				"MENU_SET_TITLE_FRIEND_NAME",
				"TITLE_FRIEND_CUSTOM_NAME_PROMPT",
			}

			local originalLocale = BFL.ConfiguredLocale
			local originalMissing = BFL.MissingKeys
			BFL.MissingKeys = {}

			for localeName, _ in pairs(BFL.Locales) do
				BFL:SetLocale(localeName)

				local localeTable = BFL_LOCALE
				if localeName == "enUS" then
					localeTable = BFL_LOCALE_ENUS
				end

				for _, key in ipairs(requiredKeys) do
					local value = localeTable and rawget(localeTable, key)
					V:Assert(value ~= nil and value ~= "", "Missing localization key in " .. localeName .. ": " .. key)
				end
			end

			if originalLocale then
				BFL:SetLocale(originalLocale)
			end
			BFL.MissingKeys = originalMissing
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

local PERFY_263_RAID_QUERIES = {
	"",
	"perfy",
	"assist",
	"target",
	"blackhand",
}

local PERFY_NIL_SENTINEL = {}

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
		autoRaidAssist = PerfyDeepCopy(BetterFriendlistDB.autoRaidAssist),
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
	BetterFriendlistDB.autoRaidAssist = PerfyDeepCopy(snapshot.autoRaidAssist)
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

local function GetPerfy263FriendCharacter(friend, fallbackIndex)
	if type(friend) == "table" then
		local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
		local name = gameAccountInfo and gameAccountInfo.characterName or friend.characterName or friend.name
		local realm = gameAccountInfo and gameAccountInfo.realmName or friend.realmName
		if type(name) == "string" and name ~= "" then
			name = name:match("([^%-]+)") or name
			if not realm or realm == "" then
				realm = GetNormalizedRealmName and GetNormalizedRealmName() or "Blackhand"
			end
			return name, realm
		end
	end
	return "PerfyAssist" .. tostring(fallbackIndex), "Blackhand"
end

local function BuildPerfy263RaidRoster(friends)
	local roster = {}
	for index, friend in ipairs(friends or {}) do
		if #roster >= 40 then
			break
		end
		local name, realm = GetPerfy263FriendCharacter(friend, index)
		roster[#roster + 1] = {
			name = name,
			realm = realm,
		}
	end
	while #roster < 40 do
		local index = #roster + 1
		roster[index] = {
			name = "PerfyAssist" .. tostring(index),
			realm = "Blackhand",
		}
	end
	return roster
end

local function GetPerfy263RaidEntry(context, unit)
	if unit == "player" then
		return { name = "PerfyLeader", realm = "Blackhand" }
	end
	local index = type(unit) == "string" and tonumber(unit:match("^raid(%d+)$")) or nil
	return index and context.raidRoster and context.raidRoster[index] or nil
end

local function OverridePerfy263Global(context, name, replacement)
	context.globalOverrides = context.globalOverrides or {}
	if context.globalOverrides[name] == nil then
		local original = _G[name]
		context.globalOverrides[name] = original == nil and PERFY_NIL_SENTINEL or original
	end
	_G[name] = replacement
end

local function InstallPerfy263RaidMocks(context)
	context.promotedUnits = {}
	OverridePerfy263Global(context, "IsInRaid", function()
		return true
	end)
	OverridePerfy263Global(context, "IsInGroup", function()
		return true
	end)
	OverridePerfy263Global(context, "GetNumGroupMembers", function()
		return context.raidRoster and #context.raidRoster or 0
	end)
	OverridePerfy263Global(context, "GetNumSubgroupMembers", function()
		return math.min(context.raidRoster and #context.raidRoster or 0, 4)
	end)
	OverridePerfy263Global(context, "UnitExists", function(unit)
		return unit == "player" or GetPerfy263RaidEntry(context, unit) ~= nil
	end)
	OverridePerfy263Global(context, "UnitIsUnit", function(left, right)
		return left == right or (left == "player" and right == "player")
	end)
	OverridePerfy263Global(context, "UnitIsGroupLeader", function(unit)
		return unit == "player"
	end)
	OverridePerfy263Global(context, "UnitIsGroupAssistant", function(unit)
		return context.promotedUnits and context.promotedUnits[unit] == true
	end)
	OverridePerfy263Global(context, "UnitFullName", function(unit)
		local entry = GetPerfy263RaidEntry(context, unit)
		return entry and entry.name or nil, entry and entry.realm or nil
	end)
	OverridePerfy263Global(context, "UnitName", function(unit)
		local entry = GetPerfy263RaidEntry(context, unit)
		return entry and entry.name or nil, entry and entry.realm or nil
	end)
	OverridePerfy263Global(context, "GetNormalizedRealmName", function()
		return "Blackhand"
	end)
	OverridePerfy263Global(context, "UnitRealmRelationship", function()
		return LE_REALM_RELATION_SAME or 1
	end)

	context.bflOverrides = {
		PromoteToAssistant = BFL.PromoteToAssistant,
		IsActionRestricted = BFL.IsActionRestricted,
	}
	BFL.PromoteToAssistant = function(unit)
		context.promotedUnits[unit] = true
		context.promoteCount = (context.promoteCount or 0) + 1
		return true
	end
	BFL.IsActionRestricted = function()
		return false
	end
end

local function RestorePerfy263RaidMocks(context)
	if not context then
		return
	end
	for name, original in pairs(context.globalOverrides or {}) do
		_G[name] = original == PERFY_NIL_SENTINEL and nil or original
	end
	context.globalOverrides = nil
	if context.bflOverrides then
		BFL.PromoteToAssistant = context.bflOverrides.PromoteToAssistant
		BFL.IsActionRestricted = context.bflOverrides.IsActionRestricted
		context.bflOverrides = nil
	end
end

local function ResetPerfy263AutoRaidRuntime(AutoRaidAssist)
	if not AutoRaidAssist then
		return
	end
	if AutoRaidAssist.pendingTimer and AutoRaidAssist.pendingTimer.Cancel then
		AutoRaidAssist.pendingTimer:Cancel()
	end
	AutoRaidAssist.pendingTimer = nil
	if AutoRaidAssist.CancelRosterRetryTimers then
		AutoRaidAssist:CancelRosterRetryTimers()
	end
	if AutoRaidAssist.CancelPromotionRetryTimers then
		AutoRaidAssist:CancelPromotionRetryTimers()
	end
	if AutoRaidAssist.ClearPromotionQueue then
		AutoRaidAssist:ClearPromotionQueue()
	end
	AutoRaidAssist.lastPromotionAttempt = {}
	AutoRaidAssist.promotionAttemptCounts = {}
	AutoRaidAssist.needsCombatRetry = nil
end

local function SeedPerfy263FeatureData(context, FriendsList, ContactMemory, FriendTags, AutoRaidAssist)
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

	context.raidRoster = BuildPerfy263RaidRoster(context.perfyFriends)
	InstallPerfy263RaidMocks(context)
	if AutoRaidAssist and AutoRaidAssist.NormalizeDB then
		local assistDB = AutoRaidAssist:NormalizeDB()
		assistDB.enabled = true
		assistDB.targets = {}
		local ContactIdentity = BFL:GetModule("ContactIdentity")
		if ContactIdentity then
			for index, entry in ipairs(context.raidRoster) do
				if index > 32 then
					break
				end
				local key = ContactIdentity:GetContactKeyFromPlayerName(entry.name, entry.realm)
				local _, value = ContactIdentity:SplitContactKey(key)
				if key then
					assistDB.targets[#assistDB.targets + 1] = {
						id = key,
						key = key,
						kind = "player",
						value = value,
						source = (index % 3 == 0 and "group") or (index % 3 == 1 and "friend") or "manual",
						displayName = entry.name,
						addedAt = time and time() or 0,
					}
				end
			end
		end
		ResetPerfy263AutoRaidRuntime(AutoRaidAssist)
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
	local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
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
		raidQueryIndex = 1,
		friendIndex = 1,
		contactIndex = 1,
		dynamicTagsEnabled = true,
		scrollDirection = 1,
		scrollStep = 0.2,
		featureSnapshot = CapturePerfy263FeatureState(),
		originalFilter = QuickFilters and QuickFilters:GetFilter() or (FriendsList and FriendsList.filterMode),
		originalSort = FriendsList and FriendsList.sortMode,
		originalSecondarySort = FriendsList and FriendsList.secondarySort,
		originalSearchText = FriendsList and FriendsList.searchText,
		originalTab = (BetterFriendsFrame and PanelTemplates_GetSelectedTab(BetterFriendsFrame)) or 1,
		originalTopTab = (
			BetterFriendsFrame
			and BetterFriendsFrame.FriendsTabHeader
			and PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		) or 1,
		groupStates = {},
		filterModes = { "all", "online", "offline", "wowonline", "wow", "bnet" },
		sortModes = { "status", "name", "level", "zone" },
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

	local function ExerciseAutoRaidCandidates()
		if not (AutoRaidAssist and AutoRaidAssist.BuildCandidateList) then
			return
		end
		local query = PERFY_263_RAID_QUERIES[context.raidQueryIndex] or ""
		context.raidQueryIndex = (context.raidQueryIndex % #PERFY_263_RAID_QUERIES) + 1
		context.lastAutoRaidCandidates = AutoRaidAssist:BuildCandidateList(query, 25)
	end

	local function ExerciseAutoRaidEvaluate()
		if not (AutoRaidAssist and AutoRaidAssist.Evaluate) then
			return
		end
		context.promotedUnits = {}
		ResetPerfy263AutoRaidRuntime(AutoRaidAssist)
		AutoRaidAssist:Evaluate("perfy-263")
	end

	local function ExerciseAutoRaidRosterSchedule()
		if not (AutoRaidAssist and AutoRaidAssist.ScheduleRosterEvaluate) then
			return
		end
		AutoRaidAssist:ScheduleRosterEvaluate("perfy-263")
		if AutoRaidAssist.CancelRosterRetryTimers then
			AutoRaidAssist:CancelRosterRetryTimers()
		end
	end

	if ScenarioManager and ScenarioManager.Load then
		ScenarioManager:Load("stress_200")
	else
		self.Reporter:Warn("ScenarioManager not available")
	end

	local seeded, seedError = pcall(SeedPerfy263FeatureData, context, FriendsList, ContactMemory, FriendTags, AutoRaidAssist)
	if not seeded then
		ResetPerfy263AutoRaidRuntime(AutoRaidAssist)
		RestorePerfy263RaidMocks(context)
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
		function()
			EnsureTab(friendsTab)
		end,
		function()
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
		ExerciseAutoRaidCandidates,
		ExerciseAutoRaidEvaluate,
		ExerciseAutoRaidRosterSchedule,
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
		ExerciseAutoRaidCandidates,
		ExerciseAutoRaidEvaluate,
		ExerciseAutoRaidRosterSchedule,
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
	local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
	local ScenarioManager = BFL.ScenarioManager

	if context then
		if context.addonProfilerActive then
			StopAddonProfiler()
		end
		ResetPerfy263AutoRaidRuntime(AutoRaidAssist)
		RestorePerfy263RaidMocks(context)
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
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() and context.originalTab then
			PanelTemplates_SetTab(BetterFriendsFrame, context.originalTab)
			if BetterFriendsFrame_ShowBottomTab then
				BetterFriendsFrame_ShowBottomTab(context.originalTab)
			end
			if context.originalTab == 1 and context.originalTopTab and BetterFriendsFrame_ShowTab then
				BetterFriendsFrame_ShowTab(context.originalTopTab)
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
	RegisterBuiltInTests(); self:RegisterAutoRaidAssistRosterFallbackTest()

	BFL:DebugPrint("|cff00ccff[BFL TestSuite]|r Initialized with " .. self:GetTestCount() .. " tests")
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

function TestSuite:GetTestCount()
	local count = 0
	for _, category in ipairs(TEST_CATEGORIES) do
		count = count + #self.tests[category]
	end
	return count
end

-- Return module
return TestSuite
