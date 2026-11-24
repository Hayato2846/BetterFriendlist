-- Modules/RecentlyAdded.lua
-- Tracks newly added friends and manages the "Recently Added" builtin group

local ADDON_NAME, BFL = ...
local RecentlyAdded = BFL:RegisterModule("RecentlyAdded", {})

local function GetDB()
	return BFL:GetModule("DB")
end

-- ========================================
-- Duration Calculation
-- ========================================

function RecentlyAdded:GetDurationSeconds(settings)
	local DB = settings or GetDB()
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

function RecentlyAdded:IsWithinDuration(age, duration)
	return age < duration
end

function RecentlyAdded:IsFriendRecentlyAdded(friendUID)
	if not friendUID then
		return false
	end
	local PreviewMode = BFL:GetModule("PreviewMode")
	if PreviewMode and PreviewMode.GetMockRecentlyAddedTimestamp then
		local timestamp = PreviewMode:GetMockRecentlyAddedTimestamp(friendUID)
		if timestamp then
			return self:IsWithinDuration(time() - timestamp, self:GetDurationSeconds())
		end
	end
	if not BetterFriendlistDB then
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
	return self:IsWithinDuration(time() - ts, self:GetDurationSeconds())
end

function RecentlyAdded:GetAllRecentFriendUIDs()
	local result = {}
	local PreviewMode = BFL:GetModule("PreviewMode")
	if PreviewMode and PreviewMode.GetMockRecentlyAddedUIDs then
		local previewUIDs = PreviewMode:GetMockRecentlyAddedUIDs()
		if previewUIDs then
			for _, friendUID in ipairs(previewUIDs) do
				if self:IsFriendRecentlyAdded(friendUID) then
					result[#result + 1] = friendUID
				end
			end
			return result
		end
	end
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

-- Return nil when any expected identity is still loading or unreadable.
local function BuildBNetSnapshot()
	local getInfo = BFL.Compat and BFL.Compat.GetBNetFriendInfo
	if not BNGetNumFriends or not getInfo or (BNConnected and not BNConnected()) then
		return
	end

	local snapshot = {}
	local count = BNGetNumFriends()
	if BFL:IsSecret(count) or type(count) ~= "number" then
		return
	end
	for i = 1, count do
		local accountInfo = getInfo(i)
		local battleTag = accountInfo and accountInfo.battleTag
		if not BFL:IsSecret(battleTag) and type(battleTag) == "string" and battleTag ~= "" then
			snapshot["bnet_" .. battleTag] = true
		elseif not (accountInfo and BFL.IsTitleFriend and BFL.IsTitleFriend(accountInfo)) then
			return
		end
	end
	return snapshot
end

local function BuildWoWSnapshot()
	if not (BFL.CanUseWoWFriendList and BFL.CanUseWoWFriendList()) then
		return
	end

	local snapshot = {}
	for i = 1, BFL.GetNumWoWFriends() do
		local friendInfo = BFL.GetWoWFriendInfoByIndex(i)
		local name = friendInfo and friendInfo.name
		local normalizedName = not BFL:IsSecret(name) and BFL:NormalizeWoWFriendName(name)
		if not normalizedName then
			return
		end
		snapshot["wow_" .. normalizedName] = true
	end
	return snapshot
end

local snapshotBuilders = { bnet = BuildBNetSnapshot, wow = BuildWoWSnapshot }

-- Compare current snapshot against stored known UIDs and record new friends
function RecentlyAdded:PerformSnapshotDiff(source, settleBaseline)
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

	local knownUIDs = BetterFriendlistDB.knownFriendUIDs
	local timestamps = BetterFriendlistDB.recentlyAddedTimestamps
	local now = time()
	local changed = false

	for kind, buildSnapshot in pairs(snapshotBuilders) do
		if not source or source == kind then
			local snapshot = buildSnapshot()
			self.incomplete[kind] = snapshot == nil
			if snapshot then
				for uid in pairs(snapshot) do
					if not knownUIDs[uid] then
						knownUIDs[uid] = true
						if self.ready[kind] then
							timestamps[uid] = now
							changed = true
						end
					end
				end
				-- A startup zero can mean the service has yet to load. Wait for
				-- a populated list before treating unknown identities as additions.
				if settleBaseline and next(snapshot) then
					self.ready[kind] = true
				end
			end
		end
	end

	-- Snapshot absence alone cannot confirm that a friendship ended.
	-- Keep known identities so partial lists cannot turn them into new friends.
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

function RecentlyAdded:UpdateSource(source)
	local DB = GetDB()
	if not DB or not DB:Get("enableRecentlyAddedGroup", false) then
		return
	end

	self:PerformSnapshotDiff(source)
	if self.ready[source] then
		return
	end

	-- Allow successive startup updates to settle before finalizing the baseline.
	if self.baselineTimers[source] then
		self.baselineTimers[source]:Cancel()
	end
	local timer = C_Timer.NewTimer(1, function()
		self.baselineTimers[source] = nil
		if self:ShouldDeferSourceUpdates() then
			self.pendingSources[source] = true
			return
		end
		self:PerformSnapshotDiff(source, true)
	end)
	self.baselineTimers[source] = timer
end

function RecentlyAdded:ShouldDeferSourceUpdates()
	return InCombatLockdown and InCombatLockdown()
		and not (BetterFriendsFrame and BetterFriendsFrame:IsShown())
end

function RecentlyAdded:FlushSourceUpdates()
	if self.sourceTimer then
		self.sourceTimer:Cancel()
		self.sourceTimer = nil
	end
	if not self.pendingSources or self:ShouldDeferSourceUpdates() then
		return
	end
	for source in pairs(self.pendingSources) do
		self.pendingSources[source] = nil
		self:UpdateSource(source)
	end
end

function RecentlyAdded:OnSourceEvent(source)
	local DB = GetDB()
	if not DB or not DB:Get("enableRecentlyAddedGroup", false) then
		return
	end
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		self.pendingSources[source] = nil
		self:UpdateSource(source)
		return
	end

	-- Status bursts can contain real additions, including same-size roster
	-- changes. Coalesce whole-roster reads without relying on a count match.
	self.pendingSources[source] = true
	if not self.sourceTimer and not self:ShouldDeferSourceUpdates() then
		self.sourceTimer = C_Timer.NewTimer(1, function()
			self.sourceTimer = nil
			self:FlushSourceUpdates()
		end)
	end
end

function RecentlyAdded:Initialize()
	self.ready = {}
	self.incomplete = {}
	self.baselineTimers = {}
	self.pendingSources = {}
	self:OnFeatureEnabled()

	-- Update timestamps before FriendsList builds its display list (priority 10).
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
		self:OnSourceEvent("wow")
	end, 5)
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function()
		self:OnSourceEvent("bnet")
	end, 5)
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function()
		if not self.ready.bnet or self.incomplete.bnet then
			self:OnSourceEvent("bnet")
		end
	end, 5)
	BFL:RegisterEventCallback("BN_CONNECTED", function()
		self:OnSourceEvent("bnet")
	end, 5)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		self:FlushSourceUpdates()
	end, 5)
	BFL:RegisterEventCallback("BN_DISCONNECTED", function()
		self.pendingSources.bnet = nil
		self.ready.bnet = nil
		if self.baselineTimers.bnet then
			self.baselineTimers.bnet:Cancel()
			self.baselineTimers.bnet = nil
		end
	end, 5)
end

function RecentlyAdded:OnFeatureEnabled()
	wipe(self.ready)
	self:UpdateSource("wow")
	self:UpdateSource("bnet")
end
