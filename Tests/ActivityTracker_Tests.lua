-- Tests/ActivityTracker_Tests.lua
-- Test suite for ActivityTracker module (Phase 1 - v1.3.0)
-- Run these tests manually in-game after loading the addon

local ADDON_NAME, BFL = ...

-- Test framework
local TestRunner = {
	tests = {},
	passed = 0,
	failed = 0,
	results = {}
}

function TestRunner:AddTest(name, testFunc)
	table.insert(self.tests, {name = name, func = testFunc})
end

function TestRunner:Assert(condition, message)
	if not condition then
		error("Assertion failed: " .. (message or "no message"))
	end
end

function TestRunner:AssertEqual(actual, expected, message)
	if actual ~= expected then
		error(string.format("Assertion failed: %s\nExpected: %s\nActual: %s", 
			message or "values not equal", tostring(expected), tostring(actual)))
	end
end

function TestRunner:AssertNotNil(value, message)
	if value == nil then
		error("Assertion failed: " .. (message or "value is nil"))
	end
end

function TestRunner:Run()
	print("|cff00ff00=== ActivityTracker Test Suite ===|r")
	print(string.format("Running %d tests...\n", #self.tests))
	
	self.passed = 0
	self.failed = 0
	self.results = {}
	
	for i, test in ipairs(self.tests) do
		local success, err = pcall(function()
			test.func(self)
		end)
		
		if success then
			self.passed = self.passed + 1
			print(string.format("|cff00ff00[PASS]|r Test %d: %s", i, test.name))
			table.insert(self.results, {name = test.name, passed = true})
		else
			self.failed = self.failed + 1
			print(string.format("|cffff0000[FAIL]|r Test %d: %s", i, test.name))
			print(string.format("  Error: %s", tostring(err)))
			table.insert(self.results, {name = test.name, passed = false, error = err})
		end
	end
	
	print(string.format("\n|cff00ff00=== Test Results ===|r"))
	print(string.format("Passed: %d/%d", self.passed, #self.tests))
	print(string.format("Failed: %d/%d", self.failed, #self.tests))
	
	if self.failed == 0 then
		print("|cff00ff00All tests passed!|r")
	else
		print("|cffff0000Some tests failed. See details above.|r")
	end
end

-- ========================================
-- Test 1: Module Initialization
-- ========================================
TestRunner:AddTest("Module is registered and initialized", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	t:AssertNotNil(tracker, "ActivityTracker module should be registered")
	t:AssertEqual(tracker.initialized, true, "Module should be initialized")
end)

-- ========================================
-- Test 2: Database Schema
-- ========================================
TestRunner:AddTest("Database has friendActivity schema", function(t)
	local DB = BFL:GetModule("DB")
	t:AssertNotNil(DB, "DB module should be available")
	
	local friendActivity = DB:Get("friendActivity")
	t:AssertNotNil(friendActivity, "friendActivity should exist in database")
	t:AssertEqual(type(friendActivity), "table", "friendActivity should be a table")
end)

-- ========================================
-- Test 3: Record Whisper Activity (Outgoing)
-- ========================================
TestRunner:AddTest("Record outgoing whisper activity", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Create a test friend UID
	local testUID = "wow_TestFriend"
	local beforeTime = time()
	
	-- Record whisper activity manually
	local success = tracker:RecordActivityManual(testUID, tracker.ACTIVITY_WHISPER)
	t:AssertEqual(success, true, "Should successfully record whisper activity")
	
	-- Verify it was recorded
	local lastWhisper = tracker:GetLastActivity(testUID, tracker.ACTIVITY_WHISPER)
	t:AssertNotNil(lastWhisper, "Should have recorded whisper timestamp")
	
	local afterTime = time()
	t:Assert(lastWhisper >= beforeTime and lastWhisper <= afterTime, 
		"Timestamp should be within test execution window")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 4: Record Group Activity
-- ========================================
TestRunner:AddTest("Record group activity", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Create a test friend UID
	local testUID = "wow_GroupFriend"
	local beforeTime = time()
	
	-- Record group activity manually
	local success = tracker:RecordActivityManual(testUID, tracker.ACTIVITY_GROUP)
	t:AssertEqual(success, true, "Should successfully record group activity")
	
	-- Verify it was recorded
	local lastGroup = tracker:GetLastActivity(testUID, tracker.ACTIVITY_GROUP)
	t:AssertNotNil(lastGroup, "Should have recorded group timestamp")
	
	local afterTime = time()
	t:Assert(lastGroup >= beforeTime and lastGroup <= afterTime, 
		"Timestamp should be within test execution window")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 5: Record Trade Activity
-- ========================================
TestRunner:AddTest("Record trade activity", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Create a test friend UID
	local testUID = "wow_TradeFriend"
	local beforeTime = time()
	
	-- Record trade activity manually
	local success = tracker:RecordActivityManual(testUID, tracker.ACTIVITY_TRADE)
	t:AssertEqual(success, true, "Should successfully record trade activity")
	
	-- Verify it was recorded
	local lastTrade = tracker:GetLastActivity(testUID, tracker.ACTIVITY_TRADE)
	t:AssertNotNil(lastTrade, "Should have recorded trade timestamp")
	
	local afterTime = time()
	t:Assert(lastTrade >= beforeTime and lastTrade <= afterTime, 
		"Timestamp should be within test execution window")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 6: Timestamp Accuracy
-- ========================================
TestRunner:AddTest("Timestamp accuracy verification", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Create test UIDs for different activity types
	local testUID = "wow_TimestampTest"
	
	-- Record activities at different times (simulate with manual timestamps)
	local whisperTime = time() - 100 -- 100 seconds ago
	local groupTime = time() - 50 -- 50 seconds ago
	local tradeTime = time() - 10 -- 10 seconds ago
	
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_WHISPER, whisperTime)
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_GROUP, groupTime)
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_TRADE, tradeTime)
	
	-- Verify each timestamp
	local recordedWhisper = tracker:GetLastActivity(testUID, tracker.ACTIVITY_WHISPER)
	local recordedGroup = tracker:GetLastActivity(testUID, tracker.ACTIVITY_GROUP)
	local recordedTrade = tracker:GetLastActivity(testUID, tracker.ACTIVITY_TRADE)
	
	t:AssertEqual(recordedWhisper, whisperTime, "Whisper timestamp should match")
	t:AssertEqual(recordedGroup, groupTime, "Group timestamp should match")
	t:AssertEqual(recordedTrade, tradeTime, "Trade timestamp should match")
	
	-- Verify GetLastActivity returns most recent when no type specified
	local mostRecent = tracker:GetLastActivity(testUID)
	t:AssertEqual(mostRecent, tradeTime, "Should return most recent activity (trade)")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 7: BNet Friend UID Resolution
-- ========================================
TestRunner:AddTest("BNet friend UID uses battleTag", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Test with BNet UID format
	local testBattleTag = "TestUser#1234"
	local testUID = "bnet_" .. testBattleTag
	
	-- Record activity
	local success = tracker:RecordActivityManual(testUID, tracker.ACTIVITY_WHISPER)
	t:AssertEqual(success, true, "Should successfully record activity for BNet friend")
	
	-- Verify it was recorded with correct UID format
	local lastActivity = tracker:GetLastActivity(testUID)
	t:AssertNotNil(lastActivity, "Should have recorded activity for BNet UID")
	
	-- Verify UID format
	t:Assert(testUID:match("^bnet_"), "BNet UID should start with 'bnet_'")
	t:Assert(testUID:match("#%d+$"), "BNet UID should contain BattleTag with #number")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 8: Data Cleanup (Old Activity Removal)
-- ========================================
TestRunner:AddTest("Cleanup removes activity older than 730 days", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	-- Create test UIDs with different ages
	local recentUID = "wow_RecentFriend"
	local oldUID = "wow_OldFriend"
	
	local recentTime = time() - (365 * 86400) -- 1 year ago (within 730 days)
	local oldTime = time() - (800 * 86400) -- 800 days ago (beyond 730 days)
	
	-- Record activities
	tracker:RecordActivityManual(recentUID, tracker.ACTIVITY_WHISPER, recentTime)
	tracker:RecordActivityManual(oldUID, tracker.ACTIVITY_WHISPER, oldTime)
	
	-- Verify both are in database before cleanup
	t:AssertNotNil(tracker:GetLastActivity(recentUID), "Recent activity should exist before cleanup")
	t:AssertNotNil(tracker:GetLastActivity(oldUID), "Old activity should exist before cleanup")
	
	-- Run cleanup
	tracker:CleanupOldActivity()
	
	-- Verify recent activity remains, old activity removed
	t:AssertNotNil(tracker:GetLastActivity(recentUID), "Recent activity should remain after cleanup")
	
	local oldActivityAfterCleanup = tracker:GetLastActivity(oldUID)
	t:Assert(oldActivityAfterCleanup == nil, "Old activity should be removed after cleanup")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[recentUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Test 9: Error Handling (Invalid UIDs)
-- ========================================
TestRunner:AddTest("Handle invalid UIDs gracefully", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	
	-- Test with nil UID
	local success1 = tracker:RecordActivityManual(nil, tracker.ACTIVITY_WHISPER)
	t:AssertEqual(success1, false, "Should return false for nil UID")
	
	-- Test with empty UID
	local success2 = tracker:RecordActivityManual("", tracker.ACTIVITY_WHISPER)
	t:AssertEqual(success2, false, "Should return false for empty UID")
	
	-- Test with nil activity type
	local success3 = tracker:RecordActivityManual("wow_Test", nil)
	t:AssertEqual(success3, false, "Should return false for nil activity type")
	
	-- Test GetLastActivity with nil UID
	local result = tracker:GetLastActivity(nil)
	t:Assert(result == nil, "Should return nil for invalid UID")
end)

-- ========================================
-- Test 10: Multiple Activity Types for Same Friend
-- ========================================
TestRunner:AddTest("Track multiple activity types for same friend", function(t)
	local tracker = BFL:GetModule("ActivityTracker")
	local DB = BFL:GetModule("DB")
	
	local testUID = "wow_MultiFriend"
	
	-- Record different activities
	local whisperTime = time() - 300
	local groupTime = time() - 200
	local tradeTime = time() - 100
	
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_WHISPER, whisperTime)
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_GROUP, groupTime)
	tracker:RecordActivityManual(testUID, tracker.ACTIVITY_TRADE, tradeTime)
	
	-- Get all activities
	local activities = tracker:GetAllActivities(testUID)
	t:AssertNotNil(activities, "Should have activities record")
	t:AssertEqual(activities[tracker.ACTIVITY_WHISPER], whisperTime, "Should have whisper timestamp")
	t:AssertEqual(activities[tracker.ACTIVITY_GROUP], groupTime, "Should have group timestamp")
	t:AssertEqual(activities[tracker.ACTIVITY_TRADE], tradeTime, "Should have trade timestamp")
	
	-- Cleanup
	local friendActivity = DB:Get("friendActivity")
	friendActivity[testUID] = nil
	DB:Set("friendActivity", friendActivity)
end)

-- ========================================
-- Slash Command to Run Tests
-- ========================================
-- Legacy slash commands (redirect to /bfl test)
-- Kept for backwards compatibility
SLASH_ACTIVITYTRACKER_TEST1 = "/bfltest"
SLASH_ACTIVITYTRACKER_TEST2 = "/bflactivitytest"
SlashCmdList["ACTIVITYTRACKER_TEST"] = function(msg)
	if msg == "activity" or msg == "" then
		TestRunner:Run()
	else
		print("|cffffcc00Usage:|r /bfl test - Run ActivityTracker tests")
	end
end

print("|cff00ff00ActivityTracker Tests loaded. Use /bfl test to run tests.|r")
