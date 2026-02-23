-- Modules/RecentlyAdded.lua
-- Tracks newly added friends and manages the "Recently Added" builtin group

local ADDON_NAME, BFL = ...
local RecentlyAdded = BFL:RegisterModule("RecentlyAdded", {})

local function GetDB()
	return BFL:GetModule("DB")
end

local function GetGroups()
	return BFL:GetModule("Groups")
end

-- ========================================
-- Duration Calculation
-- ========================================

function RecentlyAdded:GetDurationSeconds()
	local DB = GetDB()
	if not DB then
		return 604800 -- 7 days fallback
	end
	local unit = DB:Get("recentlyAddedDurationUnit", "days")
	local value = DB:Get("recentlyAddedDurationValue", 7)
	if unit == "days" then
		return value * 86400
	elseif unit == "hours" then
		return value * 3600
	elseif unit == "minutes" then
		return value * 60
	end
	return value * 86400 -- fallback to days
end

-- ========================================
-- Query API
-- ========================================

function RecentlyAdded:IsFriendRecentlyAdded(friendUID)
	if not friendUID or not BetterFriendlistDB then
		return false
	end
	local timestamps = BetterFriendlistDB.recentlyAddedTimestamps
	if not timestamps then
		return false
	end
	local ts = timestamps[friendUID]
	if not ts then
		return false
	end
	return (time() - ts) < self:GetDurationSeconds()
end

function RecentlyAdded:GetAllRecentFriendUIDs()
	local result = {}
	if not BetterFriendlistDB then
		return result
	end
	local timestamps = BetterFriendlistDB.recentlyAddedTimestamps
	if not timestamps then
		return result
	end
	local duration = self:GetDurationSeconds()
	local now = time()
	for uid, ts in pairs(timestamps) do
		if (now - ts) < duration then
			table.insert(result, uid)
		end
	end
	return result
end

-- ========================================
-- Removal API
-- ========================================

function RecentlyAdded:RemoveFriend(friendUID)
	if not friendUID or not BetterFriendlistDB then
		return
	end
	if BetterFriendlistDB.recentlyAddedTimestamps then
		BetterFriendlistDB.recentlyAddedTimestamps[friendUID] = nil
	end
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
end

function RecentlyAdded:ClearAll()
	if not BetterFriendlistDB then
		return
	end
	wipe(BetterFriendlistDB.recentlyAddedTimestamps)
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
end

-- ========================================
-- Snapshot Diffing
-- ========================================

-- Build a set of all current friend UIDs by iterating WoW API directly
function RecentlyAdded:BuildCurrentFriendSnapshot()
	local snapshot = {}

	-- BNet friends
	if BNGetNumFriends then
		local numBNet = select(1, BNGetNumFriends()) or 0
		local getInfo = (BFL.Compat and BFL.Compat.GetBNetFriendInfo)
			or (C_BattleNet and C_BattleNet.GetFriendAccountInfo)
		if getInfo then
			for i = 1, numBNet do
				local accountInfo = getInfo(i)
				if accountInfo and accountInfo.battleTag and accountInfo.battleTag ~= "" then
					snapshot["bnet_" .. accountInfo.battleTag] = true
				end
			end
		end
	end

	-- WoW friends
	if C_FriendList and C_FriendList.GetNumFriends then
		local numWoW = C_FriendList.GetNumFriends() or 0
		for i = 1, numWoW do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo and friendInfo.name then
				local normalizedName = BFL:NormalizeWoWFriendName(friendInfo.name)
				if normalizedName then
					snapshot["wow_" .. normalizedName] = true
				end
			end
		end
	end

	return snapshot
end

-- Compare current snapshot against stored known UIDs and record new friends
function RecentlyAdded:PerformSnapshotDiff()
	if not BetterFriendlistDB then
		return
	end

	local DB = GetDB()
	if not DB then
		return
	end

	-- Only run if the feature is enabled
	if not DB:Get("enableRecentlyAddedGroup", false) then
		return
	end

	-- Ensure tables exist
	if not BetterFriendlistDB.knownFriendUIDs then
		BetterFriendlistDB.knownFriendUIDs = {}
	end
	if not BetterFriendlistDB.recentlyAddedTimestamps then
		BetterFriendlistDB.recentlyAddedTimestamps = {}
	end

	local currentSnapshot = self:BuildCurrentFriendSnapshot()
	local knownUIDs = BetterFriendlistDB.knownFriendUIDs
	local timestamps = BetterFriendlistDB.recentlyAddedTimestamps
	local now = time()
	local changed = false

	-- Detect NEW friends (in current but not in known)
	for uid in pairs(currentSnapshot) do
		if not knownUIDs[uid] then
			knownUIDs[uid] = true
			timestamps[uid] = now
			changed = true
		end
	end

	-- Detect REMOVED friends (in known but not in current)
	for uid in pairs(knownUIDs) do
		if not currentSnapshot[uid] then
			knownUIDs[uid] = nil
			timestamps[uid] = nil
			changed = true
		end
	end

	-- Prune expired timestamps
	local duration = self:GetDurationSeconds()
	for uid, ts in pairs(timestamps) do
		if (now - ts) >= duration then
			timestamps[uid] = nil
			changed = true
		end
	end

	if changed then
		BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	end
end

-- ========================================
-- Initialization
-- ========================================

function RecentlyAdded:Initialize()
	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		return
	end

	-- Ensure tables exist
	if not BetterFriendlistDB.knownFriendUIDs then
		BetterFriendlistDB.knownFriendUIDs = {}
	end
	if not BetterFriendlistDB.recentlyAddedTimestamps then
		BetterFriendlistDB.recentlyAddedTimestamps = {}
	end

	-- First activation: if knownFriendUIDs is empty and feature is enabled,
	-- populate with all current friends so the group starts empty
	if DB:Get("enableRecentlyAddedGroup", false) then
		if not next(BetterFriendlistDB.knownFriendUIDs) then
			local snapshot = self:BuildCurrentFriendSnapshot()
			for uid in pairs(snapshot) do
				BetterFriendlistDB.knownFriendUIDs[uid] = true
			end
		end
	end

	-- Register event callbacks with priority 5 (before FriendsList at priority 10)
	-- so timestamps are updated before BuildDisplayList reads them
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
		self:PerformSnapshotDiff()
	end, 5)
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function()
		self:PerformSnapshotDiff()
	end, 5)
end

-- Called when the feature is toggled on in settings
function RecentlyAdded:OnFeatureEnabled()
	if not BetterFriendlistDB then
		return
	end

	-- Populate known UIDs with current friends so group starts empty
	if not BetterFriendlistDB.knownFriendUIDs then
		BetterFriendlistDB.knownFriendUIDs = {}
	end

	if not next(BetterFriendlistDB.knownFriendUIDs) then
		local snapshot = self:BuildCurrentFriendSnapshot()
		for uid in pairs(snapshot) do
			BetterFriendlistDB.knownFriendUIDs[uid] = true
		end
	end

	if not BetterFriendlistDB.recentlyAddedTimestamps then
		BetterFriendlistDB.recentlyAddedTimestamps = {}
	end
end
