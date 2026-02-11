-- Modules/NoteSync.lua
-- Syncs group assignments to friend notes in FriendGroups format

local ADDON_NAME, BFL = ...
local NoteSync = BFL:RegisterModule("NoteSync", {})

-- Constants
local BNET_NOTE_LIMIT = 127
local WOW_NOTE_LIMIT = 48
local SYNC_BATCH_SIZE = 5 -- Friends per tick during full sync
local SYNC_TICK_INTERVAL = 0.1 -- Seconds between batches
local VERIFY_DEBOUNCE = 5 -- Seconds to wait after last event before verifying notes

-- State
NoteSync.isSyncing = false
NoteSync.syncTimer = nil
NoteSync.verifyTimer = nil
NoteSync.isWriting = false -- Guard to prevent verification re-triggering itself

-- ============================================================
-- UTILITY: Parse FriendGroups note format
-- Format: "ActualNote#Group1#Group2#Group3"
-- ============================================================
local function ParseNoteGroups(noteText)
	if not noteText or noteText == "" then
		return "", {}
	end

	local parts = { strsplit("#", noteText) }
	local actualNote = parts[1] or ""
	local groups = {}

	for i = 2, #parts do
		local groupName = strtrim(parts[i])
		if groupName ~= "" then
			table.insert(groups, groupName)
		end
	end

	return actualNote, groups
end

-- ============================================================
-- INITIALIZE: Register event callbacks for periodic verification
-- ============================================================
function NoteSync:Initialize()
	-- Listen for friend list changes to detect external note modifications
	-- (e.g., Note Cleanup Wizard stripping group tags)
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
		self:ScheduleVerification()
	end, 90) -- Low priority: runs after all other handlers

	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function()
		self:ScheduleVerification()
	end, 90)
end

-- ============================================================
-- SCHEDULE: Debounced verification after friend list events
-- Coalesces rapid events into a single verification pass
-- ============================================================
function NoteSync:ScheduleVerification()
	-- Guard: Skip if we caused the note change ourselves
	if self.isWriting then
		return
	end

	-- Guard: Skip if sync is disabled or already running a full sync
	local DB = BFL:GetModule("DB")
	if not DB or not DB:Get("syncGroupsToNote") then
		return
	end

	if self.isSyncing then
		return
	end

	-- Debounce: Cancel pending verification and schedule a new one
	if self.verifyTimer then
		self.verifyTimer:Cancel()
	end

	self.verifyTimer = C_Timer.NewTimer(VERIFY_DEBOUNCE, function()
		self.verifyTimer = nil
		self:VerifyAllNotes()
	end)
end

-- ============================================================
-- VERIFY: Single-pass check of all friend notes against DB state
-- Only writes notes that are actually out of sync (missing/wrong groups)
-- ============================================================
function NoteSync:VerifyAllNotes()
	if self.isSyncing or self.isWriting then
		return
	end

	local DB = BFL:GetModule("DB")
	if not DB or not DB:Get("syncGroupsToNote") then
		return
	end

	local allFriendGroups = DB:GetFriendGroups() -- no arg = all

	-- Build lookup tables for O(1) friend access (avoid O(n*m) iteration)
	local bnetLookup = {} -- battleTag -> { accountInfo, index }
	local numBNetFriends = BNGetNumFriends()
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.battleTag then
			bnetLookup[accountInfo.battleTag] = accountInfo
		end
	end

	local wowLookup = {} -- normalizedName -> info
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	for i = 1, numWoWFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name then
			local normalized = BFL:NormalizeWoWFriendName(info.name)
			if normalized then
				wowLookup[normalized] = info
			end
		end
	end

	local fixedCount = 0

	-- Set writing guard to prevent re-triggering from our own note writes
	self.isWriting = true

	for uid in pairs(allFriendGroups) do
		local groupNames = self:GetGroupNamesForFriend(uid)
		if #groupNames > 0 then
			if uid:match("^bnet_") then
				local battleTag = uid:gsub("^bnet_", "")
				local accountInfo = bnetLookup[battleTag]
				if accountInfo then
					local actualNote = ParseNoteGroups(accountInfo.note or "")
					local expectedNote = self:BuildNoteWithGroups(actualNote, groupNames, BNET_NOTE_LIMIT)
					local currentNote = accountInfo.note or ""
					if expectedNote ~= currentNote then
						BNSetFriendNote(accountInfo.bnetAccountID, expectedNote)
						fixedCount = fixedCount + 1
						BFL:DebugPrint("NoteSync: Verification fixed BNet note for " .. battleTag)
					end
				end
			elseif uid:match("^wow_") then
				local charName = uid:gsub("^wow_", "")
				local info = wowLookup[charName]
				if info then
					local actualNote = ParseNoteGroups(info.notes or "")
					local expectedNote = self:BuildNoteWithGroups(actualNote, groupNames, WOW_NOTE_LIMIT)
					local currentNote = info.notes or ""
					if expectedNote ~= currentNote then
						C_FriendList.SetFriendNotes(info.name, expectedNote)
						fixedCount = fixedCount + 1
						BFL:DebugPrint("NoteSync: Verification fixed WoW note for " .. charName)
					end
				end
			end
		end
	end

	self.isWriting = false

	if fixedCount > 0 then
		BFL:DebugPrint("NoteSync: Verification complete, fixed " .. fixedCount .. " note(s).")
	end
end

-- ============================================================
-- BUILD: Construct note string with groups appended
-- Returns: newNote, limitReached (boolean)
-- ============================================================
function NoteSync:BuildNoteWithGroups(actualNote, groupNames, charLimit)
	local result = actualNote or ""

	if not groupNames or #groupNames == 0 then
		return result, false
	end

	local limitReached = false

	for _, groupName in ipairs(groupNames) do
		local candidate = result .. "#" .. groupName
		if #candidate > charLimit then
			limitReached = true
			break
		end
		result = candidate
	end

	return result, limitReached
end

-- ============================================================
-- RESOLVE: Get group names from group IDs, ordered by group order
-- ============================================================
function NoteSync:GetGroupNamesForFriend(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return {}
	end

	local groupIds = DB:GetFriendGroups(friendUID)
	if not groupIds or #groupIds == 0 then
		return {}
	end

	local customGroups = DB:GetCustomGroups()

	-- Build a lookup of groupId -> order position from saved group order
	local savedOrder = DB:Get("groupOrder")
	local orderMap = {}
	if savedOrder and type(savedOrder) == "table" then
		for i, gid in ipairs(savedOrder) do
			orderMap[gid] = i
		end
	end

	-- Collect custom groups with their order position
	local groupEntries = {}
	for _, groupId in ipairs(groupIds) do
		-- Only sync custom groups (not built-in like favorites, nogroup, ingame)
		local groupInfo = customGroups[groupId]
		if groupInfo and groupInfo.name then
			table.insert(groupEntries, {
				name = groupInfo.name,
				order = orderMap[groupId] or 9999,
			})
		end
	end

	-- Sort by group order position
	table.sort(groupEntries, function(a, b)
		return a.order < b.order
	end)

	-- Extract names in order
	local groupNames = {}
	for _, entry in ipairs(groupEntries) do
		table.insert(groupNames, entry.name)
	end

	return groupNames
end

-- ============================================================
-- EVENT HOOK: Called when group order changes
-- Triggers a full re-sync of all friend notes
-- ============================================================
function NoteSync:OnGroupOrderChanged()
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	-- Guard: Only sync if setting is enabled
	if not DB:Get("syncGroupsToNote") then
		return
	end

	-- Re-sync all friends with the new group order
	self:SyncAllFriends()
end

-- ============================================================
-- SYNC: Single friend note update
-- ============================================================
function NoteSync:SyncSingleFriend(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return false
	end

	-- Guard: Only sync if setting is enabled
	if not DB:Get("syncGroupsToNote") then
		return false
	end

	local groupNames = self:GetGroupNamesForFriend(friendUID)

	if friendUID:match("^bnet_") then
		return self:SyncBNetFriend(friendUID, groupNames)
	elseif friendUID:match("^wow_") then
		return self:SyncWoWFriend(friendUID, groupNames)
	end

	return false
end

-- ============================================================
-- SYNC: BNet friend note
-- ============================================================
function NoteSync:SyncBNetFriend(friendUID, groupNames)
	local battleTag = friendUID:gsub("^bnet_", "")

	-- Find account by battleTag
	local numBNetFriends = BNGetNumFriends()
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.battleTag == battleTag then
			local actualNote = ParseNoteGroups(accountInfo.note or "")
			local newNote, limitReached = self:BuildNoteWithGroups(actualNote, groupNames, BNET_NOTE_LIMIT)

			-- Only write if note actually changed
			local currentNote = accountInfo.note or ""
			if newNote ~= currentNote then
				self.isWriting = true
				BNSetFriendNote(accountInfo.bnetAccountID, newNote)
				self.isWriting = false
				BFL:DebugPrint("NoteSync: Updated BNet note for " .. battleTag)
			end

			return true, limitReached
		end
	end

	BFL:DebugPrint("NoteSync: BNet friend not found: " .. battleTag)
	return false, false
end

-- ============================================================
-- SYNC: WoW friend note
-- ============================================================
function NoteSync:SyncWoWFriend(friendUID, groupNames)
	local charName = friendUID:gsub("^wow_", "")

	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	for i = 1, numWoWFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			local name = BFL:NormalizeWoWFriendName(info.name)
			if name == charName then
				local actualNote = ParseNoteGroups(info.notes or "")
				local newNote, limitReached = self:BuildNoteWithGroups(actualNote, groupNames, WOW_NOTE_LIMIT)

				-- Only write if note actually changed
				local currentNote = info.notes or ""
				if newNote ~= currentNote then
					-- Use info.name (raw API name) instead of charName (normalized with realm)
					-- C_FriendList.SetFriendNotes expects the name in the format the API returns it
					self.isWriting = true
					C_FriendList.SetFriendNotes(info.name, newNote)
					self.isWriting = false
					BFL:DebugPrint("NoteSync: Updated WoW note for " .. charName)
				end

				return true, limitReached
			end
		end
	end

	BFL:DebugPrint("NoteSync: WoW friend not found: " .. charName)
	return false, false
end

-- ============================================================
-- FULL SYNC: Sync all friends with group assignments
-- Uses batched processing to avoid UI freezes
-- ============================================================
function NoteSync:SyncAllFriends(callback, progressCallback)
	local L = BFL_LOCALE

	if self.isSyncing then
		BFL:DebugPrint("NoteSync: Already syncing, skipping.")
		return
	end

	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	-- Collect all friends that have group assignments
	local allFriendGroups = DB:GetFriendGroups() -- no arg = all
	local friendUIDs = {}
	for uid in pairs(allFriendGroups) do
		table.insert(friendUIDs, uid)
	end

	-- Also collect friends with NO groups (to clean their notes)
	-- We need to check all BNet and WoW friends
	local allFriendSet = {}
	for _, uid in ipairs(friendUIDs) do
		allFriendSet[uid] = true
	end

	-- Scan BNet friends for any that have group tags in notes but no DB assignment
	local numBNetFriends = BNGetNumFriends()
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.battleTag then
			local uid = "bnet_" .. accountInfo.battleTag
			if not allFriendSet[uid] then
				-- Check if note has group tags
				local noteText = accountInfo.note or ""
				if noteText:find("#") then
					table.insert(friendUIDs, uid)
					allFriendSet[uid] = true
				end
			end
		end
	end

	-- Scan WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	for i = 1, numWoWFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			local name = BFL:NormalizeWoWFriendName(info.name)
			if name then
				local uid = "wow_" .. name
				if not allFriendSet[uid] then
					local noteText = info.notes or ""
					if noteText:find("#") then
						table.insert(friendUIDs, uid)
						allFriendSet[uid] = true
					end
				end
			end
		end
	end

	local totalFriends = #friendUIDs
	if totalFriends == 0 then
		BFL:DebugPrint("NoteSync: No friends to sync.")
		if callback then
			callback(0, 0)
		end
		return
	end

	BFL:DebugPrint(string.format(L.MSG_SYNC_GROUPS_STARTED or "Syncing groups to friend notes..."))
	print("|cff00ff00BetterFriendlist:|r " .. (L.MSG_SYNC_GROUPS_STARTED or "Syncing groups to friend notes..."))

	self.isSyncing = true
	local index = 1
	local updatedCount = 0
	local skippedCount = 0

	-- Cancel any existing sync timer
	if self.syncTimer then
		self.syncTimer:Cancel()
		self.syncTimer = nil
	end

	self.syncTimer = C_Timer.NewTicker(SYNC_TICK_INTERVAL, function(ticker)
		local batchEnd = math.min(index + SYNC_BATCH_SIZE - 1, totalFriends)

		for i = index, batchEnd do
			local uid = friendUIDs[i]
			local success, limitReached = self:SyncSingleFriend(uid)

			if success then
				updatedCount = updatedCount + 1
				if limitReached then
					skippedCount = skippedCount + 1
					local displayName = uid:gsub("^bnet_", ""):gsub("^wow_", "")
					BFL:DebugPrint(
						string.format(L.MSG_SYNC_GROUPS_NOTE_LIMIT or "Note limit reached for %s", displayName)
					)
				end
			end
		end

		index = batchEnd + 1

		-- Progress update every batch
		if index <= totalFriends then
			BFL:DebugPrint(
				string.format(L.MSG_SYNC_GROUPS_PROGRESS or "Syncing notes: %d / %d", index - 1, totalFriends)
			)
			if progressCallback then
				progressCallback(index - 1, totalFriends)
			end
		end

		-- Done
		if index > totalFriends then
			ticker:Cancel()
			self.syncTimer = nil
			self.isSyncing = false

			if progressCallback then
				progressCallback(totalFriends, totalFriends)
			end

			local completeMsg = string.format(
				L.MSG_SYNC_GROUPS_COMPLETE or "Group note sync complete. Updated: %d, Skipped (limit): %d",
				updatedCount,
				skippedCount
			)
			BFL:DebugPrint(completeMsg)
			print("|cff00ff00BetterFriendlist:|r " .. completeMsg)

			if callback then
				callback(updatedCount, skippedCount)
			end
		end
	end)
end

-- ============================================================
-- EVENT HOOK: Called when a friend's group membership changes
-- This is called from Database.lua after AddFriendToGroup/RemoveFriendFromGroup
-- ============================================================
function NoteSync:OnGroupChanged(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	-- Guard: Only sync if setting is enabled
	if not DB:Get("syncGroupsToNote") then
		return
	end

	-- Avoid syncing during full sync
	if self.isSyncing then
		return
	end

	-- Sync the specific friend
	self:SyncSingleFriend(friendUID)
end

-- ============================================================
-- CLEANUP: Remove group tags from a friend's note
-- Used when disabling sync or removing all groups
-- ============================================================
function NoteSync:CleanFriendNote(friendUID)
	if friendUID:match("^bnet_") then
		local battleTag = friendUID:gsub("^bnet_", "")
		local numBNetFriends = BNGetNumFriends()
		for i = 1, numBNetFriends do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.battleTag == battleTag then
				local actualNote = ParseNoteGroups(accountInfo.note or "")
				if actualNote ~= (accountInfo.note or "") then
					self.isWriting = true
					BNSetFriendNote(accountInfo.bnetAccountID, actualNote)
					self.isWriting = false
				end
				return
			end
		end
	elseif friendUID:match("^wow_") then
		local charName = friendUID:gsub("^wow_", "")
		local numWoWFriends = C_FriendList.GetNumFriends() or 0
		for i = 1, numWoWFriends do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if info then
				local name = BFL:NormalizeWoWFriendName(info.name)
				if name == charName then
					local actualNote = ParseNoteGroups(info.notes or "")
					if actualNote ~= (info.notes or "") then
						-- Use info.name (raw API name) for same reason as SyncWoWFriend
						self.isWriting = true
						C_FriendList.SetFriendNotes(info.name, actualNote)
						self.isWriting = false
					end
					return
				end
			end
		end
	end
end
