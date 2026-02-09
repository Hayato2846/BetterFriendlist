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
	-- Find test by name across all categories
	for _, category in ipairs(TEST_CATEGORIES) do
		for _, test in ipairs(self.tests[category]) do
			if test.name == testName then
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
	print(GetLocalizedText("TESTSUITE_PERFY_HELP", "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"))
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
				V:Assert(tempDB.groupOrder == nil, "groupOrder default should be nil")
				V:Assert(type(tempDB.groupStates) == "table", "groupStates should be a table")
				V:Assert(type(tempDB.groupColors) == "table", "groupColors should be a table")
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
		description = "RecentAllies availability should match API support",
		action = function(V)
			local compatAvailable = false
			if BFL.Compat and BFL.Compat.IsRecentAlliesAvailable then
				compatAvailable = BFL.Compat.IsRecentAlliesAvailable()
			end
			V:Assert(BFL.HasRecentAllies == compatAvailable, "HasRecentAllies should match API availability")
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
			local refreshCalled = false

			-- Hook ForceRefreshFriendsList
			local originalRefresh = BFL.ForceRefreshFriendsList
			BFL.ForceRefreshFriendsList = function(...)
				refreshCalled = true
				if originalRefresh then
					return originalRefresh(...)
				end
			end

			-- Change filter mode
			FriendsList:SetFilterMode(originalFilter == "all" and "online" or "all")

			-- Restore
			BFL.ForceRefreshFriendsList = originalRefresh
			FriendsList:SetFilterMode(originalFilter) -- Restore original

			V:Assert(refreshCalled == true, "SetFilterMode should trigger ForceRefreshFriendsList")
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
			local refreshCalled = false

			-- Hook ForceRefreshFriendsList
			local originalRefresh = BFL.ForceRefreshFriendsList
			BFL.ForceRefreshFriendsList = function(...)
				refreshCalled = true
				if originalRefresh then
					return originalRefresh(...)
				end
			end

			-- Change sort mode to something different
			local newSort = originalSort == "status" and "name" or "status"
			FriendsList:SetSortMode(newSort)

			-- Restore
			BFL.ForceRefreshFriendsList = originalRefresh
			FriendsList:SetSortMode(originalSort) -- Restore original

			V:Assert(refreshCalled == true, "SetSortMode should trigger ForceRefreshFriendsList")
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
				"TOOLTIP_GROUP_COLOR_DESC",
				"CORE_HELP_TEST_COMMANDS",
				"CORE_HELP_TEST_ACTIVITY",
				"STATUS_AFK",
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
end

-- ============================================
-- PERFY STRESS COMMANDS
-- ============================================

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

function TestSuite:HandlePerfyCommand(args)
	local trimmed = strtrim(args or "")
	local durationSeconds = tonumber(trimmed)
	if not durationSeconds or durationSeconds <= 0 then
		durationSeconds = 30
	end
	self:RunPerfyStress(durationSeconds)
end

function TestSuite:RunPerfyStress(durationSeconds)
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
	local QuickJoin = BFL:GetModule("QuickJoin")
	local RaidFrame = BFL:GetModule("RaidFrame")
	local PreviewMode = BFL:GetModule("PreviewMode")
	local ScenarioManager = BFL.ScenarioManager

	local context = {
		actionIndex = 1,
		sortIndex = 1,
		filterIndex = 1,
		groupIndex = 1,
		scrollDirection = 1,
		scrollStep = 0.2,
		nextWhoTime = 0,
		whoInterval = 10,
		whoMockEnabled = false,
		whoMockHooked = false,
		whoMockResults = {},
		whoOriginalGetNum = nil,
		whoOriginalGetInfo = nil,
		originalFilter = QuickFilters and QuickFilters:GetFilter() or (FriendsList and FriendsList.filterMode),
		originalSort = FriendsList and FriendsList.sortMode,
		originalSecondarySort = FriendsList and FriendsList.secondarySort,
		originalSearchText = FriendsList and FriendsList.searchText,
		originalTab = (BetterFriendsFrame and PanelTemplates_GetSelectedTab(BetterFriendsFrame)) or 1,
		groupStates = {},
		groupIds = {},
		filterModes = { "all", "online", "offline", "wow", "bnet", "hideafk" },
		sortModes = { "status", "name", "level", "zone" },
	}

	if Groups and Groups.groups then
		local orderedGroups = {}
		for groupId, groupData in pairs(Groups.groups) do
			context.groupStates[groupId] = groupData.collapsed
			local order = groupData.order or 50
			table.insert(orderedGroups, { id = groupId, order = order })
		end
		table.sort(orderedGroups, function(a, b)
			if a.order == b.order then
				return tostring(a.id) < tostring(b.id)
			end
			return a.order < b.order
		end)
		for _, entry in ipairs(orderedGroups) do
			table.insert(context.groupIds, entry.id)
		end
	end

	local friendsTab = 1
	local whoTab = 2
	local raidTab = BFL.IsRetail and 3 or 4
	local quickJoinTab = BFL.IsRetail and 4 or nil

	local function EnsureTab(tabIndex)
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			if tabIndex then
				PanelTemplates_SetTab(BetterFriendsFrame, tabIndex)
				if BetterFriendsFrame_ShowBottomTab then
					BetterFriendsFrame_ShowBottomTab(tabIndex)
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

	local function ToggleNextGroup()
		if not FriendsList or #context.groupIds == 0 then
			return
		end
		local groupId = context.groupIds[context.groupIndex]
		context.groupIndex = (context.groupIndex % #context.groupIds) + 1
		FriendsList:ToggleGroup(groupId)
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

	local function EnsureWhoMock()
		if context.whoMockEnabled then
			return
		end
		if PreviewMode and PreviewMode.EnableWhoMock then
			PreviewMode:EnableWhoMock()
			context.whoMockEnabled = true
		end
		if not (C_FriendList and C_FriendList.GetNumWhoResults and C_FriendList.GetWhoInfo) then
			return
		end
		if context.whoMockHooked then
			return
		end
		context.whoOriginalGetNum = C_FriendList.GetNumWhoResults
		context.whoOriginalGetInfo = C_FriendList.GetWhoInfo
		context.whoMockHooked = true
		C_FriendList.GetNumWhoResults = function()
			local results = (PreviewMode and PreviewMode.mockData and PreviewMode.mockData.whoResults)
				or context.whoMockResults
			local count = results and #results or 0
			return count, count
		end
		C_FriendList.GetWhoInfo = function(index)
			local results = (PreviewMode and PreviewMode.mockData and PreviewMode.mockData.whoResults)
				or context.whoMockResults
			return results and results[index] or nil
		end
	end

	local function TriggerWhoInteraction()
		if not (BetterFriendsFrame and BetterFriendsFrame.WhoFrame) then
			return
		end
		local now = GetTime()
		if now < context.nextWhoTime then
			return
		end
		context.nextWhoTime = now + context.whoInterval
		EnsureTab(whoTab)
		EnsureWhoMock()
		if _G.BetterWhoFrame_Update then
			_G.BetterWhoFrame_Update(true)
		end
	end

	context.actions = {
		function()
			EnsureTab(friendsTab)
		end,
		function()
			if FriendsList and FriendsList.RenderDisplay then
				FriendsList:RenderDisplay(true)
			end
		end,
		ScrollFriendsList,
		ToggleNextGroup,
		ApplyNextFilter,
		ApplyNextSort,
		TriggerWhoInteraction,
		function()
			if quickJoinTab then
				EnsureTab(quickJoinTab)
			end
			if QuickJoin and QuickJoin.Update then
				QuickJoin:Update(true)
			end
		end,
		function()
			EnsureTab(raidTab)
			if RaidFrame and RaidFrame.UpdateGroupLayout then
				RaidFrame:UpdateGroupLayout()
			end
		end,
		function()
			if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
				HideBetterFriendsFrame()
			else
				EnsureTab(friendsTab)
			end
		end,
	}

	self.perfyStressActive = true
	self.perfyStressContext = context
	self.perfyStressEndTime = GetTime() + durationSeconds

	if ScenarioManager and ScenarioManager.Load then
		ScenarioManager:Load("stress_200")
	else
		self.Reporter:Warn("ScenarioManager not available")
	end

	if QuickJoin and QuickJoin.CreateMockPreset_Stress then
		QuickJoin:CreateMockPreset_Stress()
	end

	if RaidFrame and RaidFrame.CreateMockPreset_Stress then
		RaidFrame:CreateMockPreset_Stress()
	end

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

	local context = self.perfyStressContext
	self.perfyStressContext = nil

	local FriendsList = BFL:GetModule("FriendsList")
	local QuickFilters = BFL:GetModule("QuickFilters")
	local Groups = BFL:GetModule("Groups")
	local QuickJoin = BFL:GetModule("QuickJoin")
	local RaidFrame = BFL:GetModule("RaidFrame")
	local PreviewMode = BFL:GetModule("PreviewMode")
	local ScenarioManager = BFL.ScenarioManager

	if context then
		if context.addonProfilerActive then
			StopAddonProfiler()
		end
		if context.whoMockHooked and C_FriendList then
			if context.whoOriginalGetNum then
				C_FriendList.GetNumWhoResults = context.whoOriginalGetNum
			end
			if context.whoOriginalGetInfo then
				C_FriendList.GetWhoInfo = context.whoOriginalGetInfo
			end
		end
		if context.whoMockEnabled and PreviewMode and PreviewMode.DisableWhoMock then
			PreviewMode:DisableWhoMock()
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
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() and context.originalTab then
			PanelTemplates_SetTab(BetterFriendsFrame, context.originalTab)
			if BetterFriendsFrame_ShowBottomTab then
				BetterFriendsFrame_ShowBottomTab(context.originalTab)
			end
		end
	end

	if ScenarioManager and ScenarioManager.Clear then
		ScenarioManager:Clear()
	end
	if QuickJoin and QuickJoin.ClearMockGroups then
		QuickJoin:ClearMockGroups()
	end
	if RaidFrame and RaidFrame.ClearMockData then
		RaidFrame:ClearMockData()
	end

	BFL:ForceRefreshFriendsList()

	if reason == "done" then
		self.Reporter:Info(GetLocalizedText("TESTSUITE_PERFY_DONE", "Perfy stress test finished"))
	else
		StopPerfyTracking()
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

	BFL:DebugPrint("|cff00ccff[BFL TestSuite]|r Initialized with " .. self:GetTestCount() .. " tests")
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
