-- Modules/ActivityTracker.lua
-- Activity Tracker Module - Tracks friend interactions (whispers, groups, trades)
-- Part of v1.3.0 feature set

local ADDON_NAME, BFL = ...
local ActivityTracker = BFL:RegisterModule("ActivityTracker", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB() return BFL:GetModule("DB") end

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

-- 12.0.0+ Secret Values Compatibility
-- Checks if a value is a "Secret" (tainted/restricted) which cannot be inspected or used as table keys
local function IsSecret(value)
	if issecretvalue then
		return issecretvalue(value)
	end
	return false
end

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
local function GetFriendUIDFromName(name)
	if IsSecret(name) then return nil end -- 12.0.0 Safety

	if not name or name == "" then
		return nil
	end
	
	-- Remove realm suffix if present (Name-Realm -> Name)
	local baseName = name:match("^([^-]+)") or name
	
	-- Check WoW friends first
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.name then
			if IsSecret(friendInfo.name) then -- 12.0.0 Safety
				-- Skip secret names
			else
				local friendBaseName = friendInfo.name:match("^([^-]+)") or friendInfo.name
				if friendBaseName == baseName then
					return "wow_" .. friendInfo.name
				end
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
				if IsSecret(gameInfo.characterName) then -- 12.0.0 Safety
					-- Skip secret character names
				else
					local charBaseName = gameInfo.characterName:match("^([^-]+)") or gameInfo.characterName
					if charBaseName == baseName then
						-- Use battleTag as persistent identifier
						if accountInfo.battleTag and accountInfo.battleTag ~= "" then
							if IsSecret(accountInfo.battleTag) then return nil end -- 12.0.0 Safety
							return "bnet_" .. accountInfo.battleTag
						end
					end
				end
			end
		end
	end
	
	return nil
end

-- Get friend UID from BattleTag (for BNet friends)
-- @param battleTag: BattleTag string (e.g., "Name#1234")
-- @return friendUID or nil
local function GetFriendUIDFromBattleTag(battleTag)
	if IsSecret(battleTag) then return nil end -- 12.0.0 Safety

	if not battleTag or battleTag == "" then
		return nil
	end
	
	return "bnet_" .. battleTag
end

-- Record activity for a friend
-- @param friendUID: Unique friend identifier (bnet_BattleTag or wow_Name)
-- @param activityType: Type of activity (ACTIVITY_WHISPER, ACTIVITY_GROUP, ACTIVITY_TRADE)
-- @param timestamp: Optional timestamp (defaults to current time)
local function RecordActivity(friendUID, activityType, timestamp)
	if IsSecret(friendUID) then return false end -- 12.0.0 Safety: Secrets cannot be table keys

	if not friendUID or friendUID == "" then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - invalid friendUID")
		return false
	end
	
	if not activityType then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - invalid activityType")
		return false
	end
	
	local DB = GetDB()
	if not DB then
		-- BFL:DebugPrint("ActivityTracker: Cannot record activity - DB module not available")
		return false
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
	return true
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function ActivityTracker:Initialize()
	if self.initialized then
		return
	end
	
	-- BFL:DebugPrint("ActivityTracker: Initializing...")
	
	-- Register event callbacks for WoW whispers
	BFL:RegisterEventCallback("CHAT_MSG_WHISPER", function(...)
		self:OnWhisper(...)
	end, 50)
	
	BFL:RegisterEventCallback("CHAT_MSG_WHISPER_INFORM", function(...)
		self:OnWhisperSent(...)
	end, 50)
	
	-- Register event callbacks for BNet whispers
	BFL:RegisterEventCallback("CHAT_MSG_BN_WHISPER", function(...)
		self:OnBNetWhisper(...)
	end, 50)
	
	BFL:RegisterEventCallback("CHAT_MSG_BN_WHISPER_INFORM", function(...)
		self:OnBNetWhisperSent(...)
	end, 50)
	
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function(...)
		self:OnGroupRosterUpdate(...)
	end, 50)
	
	BFL:RegisterEventCallback("TRADE_SHOW", function(...)
		self:OnTradeShow(...)
	end, 50)
	
	BFL:RegisterEventCallback("PLAYER_LOGIN", function(...)
		self:OnPlayerLogin(...)
	end, 50)
	
	self.initialized = true
	-- BFL:DebugPrint("ActivityTracker: Initialized successfully")
end

-- Handle PLAYER_LOGIN event (cleanup old data)
function ActivityTracker:OnPlayerLogin()
	-- BFL:DebugPrint("ActivityTracker: Running PLAYER_LOGIN cleanup...")
	self:CleanupOldActivity()
end

-- Cleanup activity data older than MAX_ACTIVITY_AGE_DAYS
function ActivityTracker:CleanupOldActivity()
	local DB = GetDB()
	if not DB then
		return
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
end

-- Get all activities for a friend
function ActivityTracker:GetAllActivities(friendUID)
	local DB = GetDB()
	if not DB then return nil end
	
	local friendActivity = DB:Get("friendActivity", {})
	return friendActivity[friendUID]
end

-- Handle incoming whisper (CHAT_MSG_WHISPER)
function ActivityTracker:OnWhisper(text, sender, languageName, channelName, target, flags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, ...)
	-- Debug: Log all parameters
	-- BFL:DebugPrint(string.format("ActivityTracker: OnWhisper called - text='%s', sender='%s', target='%s', guid='%s'", 
	-- 	tostring(text), tostring(sender), tostring(target), tostring(guid)))
	
	if IsSecret(sender) then return end -- 12.0.0 Safety

	if not sender or sender == "" then
		-- BFL:DebugPrint("ActivityTracker: OnWhisper - No sender")
		return
	end
	
	-- Resolve sender to friend UID
	local friendUID = GetFriendUIDFromName(sender)
	if friendUID then
		RecordActivity(friendUID, ACTIVITY_WHISPER)
	else
		-- BFL:DebugPrint(string.format("ActivityTracker: OnWhisper - Could not resolve sender '%s' to friend UID", sender))
	end
end

-- Handle outgoing whisper (CHAT_MSG_WHISPER_INFORM)
function ActivityTracker:OnWhisperSent(text, recipient, ...)
	if IsSecret(recipient) then return end -- 12.0.0 Safety

	if not recipient or recipient == "" then
		return
	end
	
	-- Resolve recipient to friend UID
	local friendUID = GetFriendUIDFromName(recipient)
	if friendUID then
		RecordActivity(friendUID, ACTIVITY_WHISPER)
	end
end

-- Handle incoming BNet whisper (CHAT_MSG_BN_WHISPER)
function ActivityTracker:OnBNetWhisper(text, sender, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, ...)
	if IsSecret(bnSenderID) then return end -- 12.0.0 Safety

	if not bnSenderID then
		return
	end
	
	-- Get BNet friend info from bnetAccountID (bnSenderID)
	local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID)
	if accountInfo and accountInfo.battleTag then
		local friendUID = GetFriendUIDFromBattleTag(accountInfo.battleTag)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_WHISPER)
		end
	end
end

-- Handle outgoing BNet whisper (CHAT_MSG_BN_WHISPER_INFORM)
function ActivityTracker:OnBNetWhisperSent(text, recipient, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, ...)
	if IsSecret(bnSenderID) then return end -- 12.0.0 Safety

	if not bnSenderID then
		return
	end
	
	-- Get BNet friend info from bnetAccountID (bnSenderID)
	local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID)
	if accountInfo and accountInfo.battleTag then
		local friendUID = GetFriendUIDFromBattleTag(accountInfo.battleTag)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_WHISPER)
		end
	end
end

-- Handle group roster update (GROUP_ROSTER_UPDATE)
function ActivityTracker:OnGroupRosterUpdate()
	-- Check if player is in a group
	if not IsInGroup() then
		-- Clear last roster when leaving group
		self.lastGroupRoster = {}
		return
	end
	
	-- Get current group members
	local currentRoster = {}
	local numGroupMembers = GetNumGroupMembers()
	
	for i = 1, numGroupMembers do
		local name, realm = UnitName("party" .. i)
		if name and not IsSecret(name) then -- 12.0.0 Safety
			-- Construct full name (Name-Realm or just Name for same realm)
			local fullName = name
			if realm and realm ~= "" and not IsSecret(realm) then -- Realm check too
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
end

-- Handle trade window opened (TRADE_SHOW)
function ActivityTracker:OnTradeShow()
	-- Get trade target name
	local targetName = UnitName("NPC") -- Trade target is always "NPC" unit
	
	if targetName and targetName ~= "" and not IsSecret(targetName) then -- 12.0.0 Safety
		local friendUID = GetFriendUIDFromName(targetName)
		if friendUID then
			RecordActivity(friendUID, ACTIVITY_TRADE)
		end
	end
end

-- Get last activity timestamp for a friend
-- @param friendUID: Unique friend identifier
-- @param activityType: Optional activity type filter (nil = any activity)
-- @return timestamp or nil
function ActivityTracker:GetLastActivity(friendUID, activityType)
	if not friendUID then
		return nil
	end
	
	local DB = GetDB()
	if not DB then
		return nil
	end
	
	local friendActivity = DB:Get("friendActivity") or {}
	local activities = friendActivity[friendUID]
	
	if not activities then
		return nil
	end
	
	-- If specific activity type requested
	if activityType then
		return activities[activityType]
	end
	
	-- Return most recent activity across all types
	local mostRecent = nil
	for _, timestamp in pairs(activities) do
		if timestamp and (not mostRecent or timestamp > mostRecent) then
			mostRecent = timestamp
		end
	end
	
	return mostRecent
end

-- Get all activities for a friend
-- @param friendUID: Unique friend identifier
-- @return table of activities or nil
function ActivityTracker:GetAllActivities(friendUID)
	if not friendUID then
		return nil
	end
	
	local DB = GetDB()
	if not DB then
		return nil
	end
	
	local friendActivity = DB:Get("friendActivity") or {}
	return friendActivity[friendUID]
end

-- Record activity manually (for testing)
-- @param friendUID: Unique friend identifier
-- @param activityType: Type of activity
-- @param timestamp: Optional timestamp (defaults to current time)
function ActivityTracker:RecordActivityManual(friendUID, activityType, timestamp)
	return RecordActivity(friendUID, activityType, timestamp)
end

-- Get friend UID from name (for testing)
-- @param name: Character name
-- @return friendUID or nil
function ActivityTracker:GetFriendUIDFromName(name)
	return GetFriendUIDFromName(name)
end

-- Activity type constants (exposed for external use)
ActivityTracker.ACTIVITY_WHISPER = ACTIVITY_WHISPER
ActivityTracker.ACTIVITY_GROUP = ACTIVITY_GROUP
ActivityTracker.ACTIVITY_TRADE = ACTIVITY_TRADE

return ActivityTracker
