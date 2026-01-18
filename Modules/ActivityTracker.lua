--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua"); -- Modules/ActivityTracker.lua
-- Activity Tracker Module - Tracks friend interactions (whispers, groups, trades)
-- Part of v1.3.0 feature set

local ADDON_NAME, BFL = ...
local ActivityTracker = BFL:RegisterModule("ActivityTracker", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB() Perfy_Trace(Perfy_GetTime(), "Enter", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:11:6"); return Perfy_Trace_Passthrough("Leave", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:11:6", BFL:GetModule("DB")) end

-- ========================================
-- Constants
-- ========================================
local SECONDS_PER_DAY = 86400
local MAX_ACTIVITY_AGE_DAYS = 730 -- 2 years
local MAX_ACTIVITY_AGE_SECONDS = MAX_ACTIVITY_AGE_DAYS * SECONDS_PER_DAY

-- Activity types
local ACTIVITY_WHISPER = "lastWhisper"
local ACTIVITY_GROUP = "lastGroup"
local ACTIVITY_TRADE = "lastTrade"

-- ========================================
-- Module State
-- ========================================
ActivityTracker.initialized = false
ActivityTracker.lastGroupRoster = {} -- Track who was in group last check

-- ========================================
-- Helper Functions
-- ========================================

-- Get friend UID from character name
-- This resolves character names to BNet or WoW friend UIDs
-- @param name: Character name (may or may not include realm)
-- @return friendUID or nil
local function GetFriendUIDFromName(name) Perfy_Trace(Perfy_GetTime(), "Enter", "GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:39:6");
	if not name or name == "" then
		Perfy_Trace(Perfy_GetTime(), "Leave", "GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:39:6"); return nil
	end
	
	-- Remove realm suffix if present (Name-Realm -> Name)
	local baseName = name:match("^([^-]+)") or name
	
	-- Check WoW friends first
	local numWoWFriends = C_FriendList.GetNumFriends()
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.name then
			local friendBaseName = friendInfo.name:match("^([^-]+)") or friendInfo.name
			if friendBaseName == baseName then
				return Perfy_Trace_Passthrough("Leave", "GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:39:6", "wow_" .. friendInfo.name)
			end
		end
	end
	
	-- Check BNet friends (search all game accounts)
	local numBNetFriends = BNGetNumFriends()
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.gameAccountInfo then
			-- Check if this BNet friend has a WoW character with matching name
			local gameInfo = accountInfo.gameAccountInfo
			if gameInfo.isOnline and gameInfo.characterName then
				local charBaseName = gameInfo.characterName:match("^([^-]+)") or gameInfo.characterName
				if charBaseName == baseName then
					-- Use battleTag as persistent identifier
					if accountInfo.battleTag then
						return Perfy_Trace_Passthrough("Leave", "GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:39:6", "bnet_" .. accountInfo.battleTag)
					end
				end
			end
		end
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:39:6"); return nil
end

-- Get friend UID from BattleTag (for BNet friends)
-- @param battleTag: BattleTag string (e.g., "Name#1234")
-- @return friendUID or nil
local function GetFriendUIDFromBattleTag(battleTag) Perfy_Trace(Perfy_GetTime(), "Enter", "GetFriendUIDFromBattleTag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:84:6");
	if not battleTag or battleTag == "" then
		Perfy_Trace(Perfy_GetTime(), "Leave", "GetFriendUIDFromBattleTag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:84:6"); return nil
	end
	
	return Perfy_Trace_Passthrough("Leave", "GetFriendUIDFromBattleTag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:84:6", "bnet_" .. battleTag)
end

-- Record activity for a friend
-- @param friendUID: Unique friend identifier (bnet_BattleTag or wow_Name)
-- @param activityType: Type of activity (ACTIVITY_WHISPER, ACTIVITY_GROUP, ACTIVITY_TRADE)
-- @param timestamp: Optional timestamp (defaults to current time)
local function RecordActivity(friendUID, activityType, timestamp) Perfy_Trace(Perfy_GetTime(), "Enter", "RecordActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:96:6");
	if not friendUID or friendUID == "" then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - invalid friendUID")
		Perfy_Trace(Perfy_GetTime(), "Leave", "RecordActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:96:6"); return false
	end
	
	if not activityType then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - invalid activityType")
		Perfy_Trace(Perfy_GetTime(), "Leave", "RecordActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:96:6"); return false
	end
	
	local DB = GetDB()
	if not DB then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - DB module not available")
		Perfy_Trace(Perfy_GetTime(), "Leave", "RecordActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:96:6"); return false
	end
	
	timestamp = timestamp or time()
	
	-- Get or create activity record for this friend
	local friendActivity = DB:Get("friendActivity") or {}
	if not friendActivity[friendUID] then
		friendActivity[friendUID] = {}
	end
	
	-- Update activity timestamp
	friendActivity[friendUID][activityType] = timestamp
	
	-- Save back to database
	DB:Set("friendActivity", friendActivity)
	
	-- BFL:DebugPrint(string.format("ActivityTracker: Recorded %s for %s at %d", activityType, friendUID, timestamp))
	Perfy_Trace(Perfy_GetTime(), "Leave", "RecordActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:96:6"); return true
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function ActivityTracker:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:136:0");
	if self.initialized then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:136:0"); return
	end
	
	-- BFL:DebugPrint("ActivityTracker: Initializing...")
	
	-- Register event callbacks for WoW whispers
	BFL:RegisterEventCallback("CHAT_MSG_WHISPER", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:144:47");
		self:OnWhisper(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:144:47"); end, 50)
	
	BFL:RegisterEventCallback("CHAT_MSG_WHISPER_INFORM", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:148:54");
		self:OnWhisperSent(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:148:54"); end, 50)
	
	-- Register event callbacks for BNet whispers
	BFL:RegisterEventCallback("CHAT_MSG_BN_WHISPER", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:153:50");
		self:OnBNetWhisper(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:153:50"); end, 50)
	
	BFL:RegisterEventCallback("CHAT_MSG_BN_WHISPER_INFORM", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:157:57");
		self:OnBNetWhisperSent(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:157:57"); end, 50)
	
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:161:50");
		self:OnGroupRosterUpdate(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:161:50"); end, 50)
	
	BFL:RegisterEventCallback("TRADE_SHOW", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:165:41");
		self:OnTradeShow(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:165:41"); end, 50)
	
	BFL:RegisterEventCallback("PLAYER_LOGIN", function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:169:43");
		self:OnPlayerLogin(...)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:169:43"); end, 50)
	
	self.initialized = true
	-- BFL:DebugPrint("ActivityTracker: Initialized successfully")
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:136:0"); end

-- Handle PLAYER_LOGIN event (cleanup old data)
function ActivityTracker:OnPlayerLogin() Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnPlayerLogin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:178:0");
	-- BFL:DebugPrint("ActivityTracker: Running PLAYER_LOGIN cleanup...")
	self:CleanupOldActivity()
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnPlayerLogin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:178:0"); end

-- Cleanup activity data older than MAX_ACTIVITY_AGE_DAYS
function ActivityTracker:CleanupOldActivity() Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:CleanupOldActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:184:0");
	local DB = GetDB()
	if not DB then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:CleanupOldActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:184:0"); return
	end
	
	local friendActivity = DB:Get("friendActivity") or {}
	local currentTime = time()
	local cutoffTime = currentTime - MAX_ACTIVITY_AGE_SECONDS
	local removedCount = 0
	
	-- Iterate through all friends
	for friendUID, activities in pairs(friendActivity) do
		local hasRecentActivity = false
		
		-- Check if any activity is recent
		for activityType, timestamp in pairs(activities) do
			if timestamp and timestamp >= cutoffTime then
				hasRecentActivity = true
				break
			end
		end
		
		-- Remove friend entry if no recent activity
		if not hasRecentActivity then
			friendActivity[friendUID] = nil
			removedCount = removedCount + 1
		end
	end
	
	if removedCount > 0 then
		DB:Set("friendActivity", friendActivity)
		-- BFL:DebugPrint(string.format("ActivityTracker: Cleaned up %d old activity records (older than %d days)", removedCount, MAX_ACTIVITY_AGE_DAYS))
	else
		-- BFL:DebugPrint("ActivityTracker: No old activity records to clean up")
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:CleanupOldActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:184:0"); end

-- Get all activities for a friend
function ActivityTracker:GetAllActivities(friendUID) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:223:0");
	local DB = GetDB()
	if not DB then Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:223:0"); return nil end
	
	local friendActivity = DB:Get("friendActivity", {})
	return Perfy_Trace_Passthrough("Leave", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:223:0", friendActivity[friendUID])
end

-- Handle incoming whisper (CHAT_MSG_WHISPER)
function ActivityTracker:OnWhisper(text, sender, languageName, channelName, target, flags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:232:0");
	-- Debug: Log all parameters
	-- BFL:DebugPrint(string.format("ActivityTracker: OnWhisper called - text='%s', sender='%s', target='%s', guid='%s'", 
	-- 	tostring(text), tostring(sender), tostring(target), tostring(guid)))
	
	if not sender or sender == "" then
		-- BFL:DebugPrint("ActivityTracker: OnWhisper - No sender")
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:232:0"); return
	end
	
	-- Resolve sender to friend UID
	local friendUID = GetFriendUIDFromName(sender)
	if friendUID then
		RecordActivity(friendUID, ACTIVITY_WHISPER)
	else
		-- BFL:DebugPrint(string.format("ActivityTracker: OnWhisper - Could not resolve sender '%s' to friend UID", sender))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:232:0"); end

-- Handle outgoing whisper (CHAT_MSG_WHISPER_INFORM)
function ActivityTracker:OnWhisperSent(text, recipient, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:252:0");
	if not recipient or recipient == "" then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:252:0"); return
	end
	
	-- Resolve recipient to friend UID
	local friendUID = GetFriendUIDFromName(recipient)
	if friendUID then
		RecordActivity(friendUID, ACTIVITY_WHISPER)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:252:0"); end

-- Handle incoming BNet whisper (CHAT_MSG_BN_WHISPER)
function ActivityTracker:OnBNetWhisper(text, sender, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnBNetWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:265:0");
	if not bnSenderID then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnBNetWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:265:0"); return
	end
	
	-- Get BNet friend info from bnetAccountID (bnSenderID)
	local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID)
	if accountInfo and accountInfo.battleTag then
		local friendUID = GetFriendUIDFromBattleTag(accountInfo.battleTag)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_WHISPER)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnBNetWhisper file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:265:0"); end

-- Handle outgoing BNet whisper (CHAT_MSG_BN_WHISPER_INFORM)
function ActivityTracker:OnBNetWhisperSent(text, recipient, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnBNetWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:281:0");
	if not bnSenderID then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnBNetWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:281:0"); return
	end
	
	-- Get BNet friend info from bnetAccountID (bnSenderID)
	local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID)
	if accountInfo and accountInfo.battleTag then
		local friendUID = GetFriendUIDFromBattleTag(accountInfo.battleTag)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_WHISPER)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnBNetWhisperSent file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:281:0"); end

-- Handle group roster update (GROUP_ROSTER_UPDATE)
function ActivityTracker:OnGroupRosterUpdate() Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnGroupRosterUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:297:0");
	-- Check if player is in a group
	if not IsInGroup() then
		-- Clear last roster when leaving group
		self.lastGroupRoster = {}
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnGroupRosterUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:297:0"); return
	end
	
	-- Get current group members
	local currentRoster = {}
	local numGroupMembers = GetNumGroupMembers()
	
	for i = 1, numGroupMembers do
		local name, realm = UnitName("party" .. i)
		if name then
			-- Construct full name (Name-Realm or just Name for same realm)
			local fullName = name
			if realm and realm ~= "" then
				fullName = name .. "-" .. realm
			end
			currentRoster[fullName] = true
			
			-- Record activity for new members (not in last roster)
			if not self.lastGroupRoster[fullName] then
				local friendUID = GetFriendUIDFromName(fullName)
				if friendUID then
					RecordActivity(friendUID, ACTIVITY_GROUP)
				end
			end
		end
	end
	
	-- Update last roster
	self.lastGroupRoster = currentRoster
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnGroupRosterUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:297:0"); end

-- Handle trade window opened (TRADE_SHOW)
function ActivityTracker:OnTradeShow() Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:OnTradeShow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:334:0");
	-- Get trade target name
	local targetName = UnitName("NPC") -- Trade target is always "NPC" unit
	
	if targetName and targetName ~= "" then
		local friendUID = GetFriendUIDFromName(targetName)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_TRADE)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:OnTradeShow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:334:0"); end

-- Get last activity timestamp for a friend
-- @param friendUID: Unique friend identifier
-- @param activityType: Optional activity type filter (nil = any activity)
-- @return timestamp or nil
function ActivityTracker:GetLastActivity(friendUID, activityType) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0");
	if not friendUID then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0"); return nil
	end
	
	local DB = GetDB()
	if not DB then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0"); return nil
	end
	
	local friendActivity = DB:Get("friendActivity") or {}
	local activities = friendActivity[friendUID]
	
	if not activities then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0"); return nil
	end
	
	-- If specific activity type requested
	if activityType then
		return Perfy_Trace_Passthrough("Leave", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0", activities[activityType])
	end
	
	-- Return most recent activity across all types
	local mostRecent = nil
	for _, timestamp in pairs(activities) do
		if timestamp and (not mostRecent or timestamp > mostRecent) then
			mostRecent = timestamp
		end
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetLastActivity file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:350:0"); return mostRecent
end

-- Get all activities for a friend
-- @param friendUID: Unique friend identifier
-- @return table of activities or nil
function ActivityTracker:GetAllActivities(friendUID) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:386:0");
	if not friendUID then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:386:0"); return nil
	end
	
	local DB = GetDB()
	if not DB then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:386:0"); return nil
	end
	
	local friendActivity = DB:Get("friendActivity") or {}
	return Perfy_Trace_Passthrough("Leave", "ActivityTracker:GetAllActivities file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:386:0", friendActivity[friendUID])
end

-- Record activity manually (for testing)
-- @param friendUID: Unique friend identifier
-- @param activityType: Type of activity
-- @param timestamp: Optional timestamp (defaults to current time)
function ActivityTracker:RecordActivityManual(friendUID, activityType, timestamp) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:RecordActivityManual file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:404:0");
	return Perfy_Trace_Passthrough("Leave", "ActivityTracker:RecordActivityManual file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:404:0", RecordActivity(friendUID, activityType, timestamp))
end

-- Get friend UID from name (for testing)
-- @param name: Character name
-- @return friendUID or nil
function ActivityTracker:GetFriendUIDFromName(name) Perfy_Trace(Perfy_GetTime(), "Enter", "ActivityTracker:GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:411:0");
	return Perfy_Trace_Passthrough("Leave", "ActivityTracker:GetFriendUIDFromName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua:411:0", GetFriendUIDFromName(name))
end

-- Activity type constants (exposed for external use)
ActivityTracker.ACTIVITY_WHISPER = ACTIVITY_WHISPER
ActivityTracker.ACTIVITY_GROUP = ACTIVITY_GROUP
ActivityTracker.ACTIVITY_TRADE = ACTIVITY_TRADE

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ActivityTracker.lua"); return ActivityTracker
