local _, BFL = ...
local GlobalSync = {}
BFL.GlobalSync = GlobalSync

-- Constants
local MODULE_NAME = "GlobalSync"
local BATCH_SIZE = 5 -- Number of friends to add per tick to avoid throttling
local ADD_RETRY_DELAY = 30
local MAX_ADD_DISPATCHES = 2

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value)
end

local function IsName(value)
	return not IsSecret(value) and type(value) == "string" and value ~= ""
end

local function HasRegionalNames()
	return BFL.AreRegionalUniqueNamesEnabled and BFL.AreRegionalUniqueNamesEnabled()
end

function GlobalSync:GetFriendKey(name, realm)
	if not IsName(name) then
		return nil
	end
	if HasRegionalNames() or name:find("-", 1, true) then
		return name
	end
	return IsName(realm) and (name .. "-" .. realm) or nil
end

function GlobalSync:GetFriendNameAndRealm(key)
	if not IsName(key) then
		return nil
	end
	if HasRegionalNames() then
		return key
	end
	return key:match("^([^%-]+)%-(.+)$")
end

local function GetFriendCount()
	local ok, count = pcall(BFL.GetNumWoWFriends)
	if ok and not IsSecret(count) and type(count) == "number" then
		return count
	end
end

local function IsReadableTable(value)
	return not IsSecret(value) and type(value) == "table" and not (issecrettable and issecrettable(value))
end

local function GetReadableFriend(index)
	local ok, info = pcall(BFL.GetWoWFriendInfoByIndex, index)
	if ok and IsReadableTable(info) and IsName(info.name) then
		return info
	end
end

function GlobalSync:UsesTitleFriends()
	if C_BattleNet and C_BattleNet.AreTitleFriendsEnabled then
		local ok, enabled = pcall(C_BattleNet.AreTitleFriendsEnabled)
		if not ok or IsSecret(enabled) or type(enabled) ~= "boolean" then
			return nil
		end
		return enabled
	end
	return BFL.AreTitleFriendsEnabled and BFL.AreTitleFriendsEnabled() == true
		or false
end

local function GetStoredFriend(faction, key)
	local friends = BetterFriendlistDB.GlobalFriends and BetterFriendlistDB.GlobalFriends[faction]
	return friends and friends[key]
end

local function MatchesName(left, right)
	return IsName(left) and IsName(right) and left:lower() == right:lower()
end

local function CanChangeFriends()
	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		return false
	end
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
		local ok, restricted = pcall(C_ChatInfo.InChatMessagingLockdown)
		return ok and not IsSecret(restricted) and restricted == false
	end
	return true
end

local function TryFriendAction(action, ...)
	if not CanChangeFriends() then
		return false
	end
	local ok, dispatched = pcall(action, ...)
	return ok and not IsSecret(dispatched) and dispatched == true
end

local function GetKnownTitleNames()
	local names = {}
	local ok, count = pcall(BNGetNumFriends)
	if not ok or IsSecret(count) or type(count) ~= "number" then
		return names, false
	end
	for index = 1, count do
		local readable, account = pcall(BFL.GetBNetFriendInfo, index)
		if not readable or not IsReadableTable(account) or IsSecret(account.friendLevel) then
			return names, false
		end
		if BFL.IsTitleFriend(account) then
			local gameAccount = account.gameAccountInfo
			if IsReadableTable(gameAccount) and IsName(gameAccount.characterName) then
				names[gameAccount.characterName:lower()] = true
			end
		end
	end
	return names, true
end

function GlobalSync:IsKnownTitleFriend(name)
	return IsName(name) and GetKnownTitleNames()[name:lower()] == true
end

function GlobalSync:GetPendingTitleFriends()
	local entries = {}
	if self:UsesTitleFriends() ~= true or not BetterFriendlistDB or not BetterFriendlistDB.GlobalFriends then
		return entries
	end
	local known, readable = GetKnownTitleNames()
	if not readable then
		return entries
	end
	local requested = self.requestedTitleFriends or {}
	local seen = {}
	for _, friends in pairs(BetterFriendlistDB.GlobalFriends) do
		for name, entry in pairs(friends) do
			if IsName(name) and not entry.deleted and self:ShouldAddFriend(name) then
				local key = name:lower()
				if not known[key] and not requested[key] and not seen[key] then
					entries[#entries + 1] = name
					seen[key] = true
				end
			end
		end
	end
	table.sort(entries, function(a, b) return a:lower() < b:lower() end)
	return entries
end

local function HasStoredTitleFriend(name)
	local database = BetterFriendlistDB and BetterFriendlistDB.GlobalFriends
	if not IsReadableTable(database) then return false end
	for _, friends in pairs(database) do
		if IsReadableTable(friends) then
			for key, entry in pairs(friends) do
				if MatchesName(key, name) and IsReadableTable(entry) and not entry.deleted then return true end
			end
		end
	end
	return false
end

function GlobalSync:AdvanceTitleInvites()
	local batch = self.titleInviteBatch
	if not batch or self.activeTitlePrompt then
		return
	end
	local name = batch.names[batch.index]
	if not name or self:UsesTitleFriends() ~= true or not CanChangeFriends() then
		self.titleInviteBatch = nil
		return
	end
	batch.index = batch.index + 1
	if not HasStoredTitleFriend(name) or self:IsKnownTitleFriend(name) then
		C_Timer.After(0, function()
			if self.titleInviteBatch == batch then self:AdvanceTitleInvites() end
		end)
		return
	end

	local ok, dialog = pcall(BFL.RequestTitleFriendInviteConfirmation, name)
	if not ok or IsSecret(dialog) or not dialog then
		self.titleInviteBatch = nil
		return
	end
	local prompt = { name = name, batch = batch, dialog = dialog }
	self.activeTitlePrompt = prompt
	if not self.titleInviteDialogs then
		self.titleInviteDialogs = {}
	end
	if self.titleInviteDialogs[dialog] then
		return true
	end
	self.titleInviteDialogs[dialog] = true
	dialog.SendButton:HookScript("OnClick", function()
		local active = self.activeTitlePrompt
		if active and active.dialog == dialog and active.matchedOnClose then
			active.confirmed = true
		end
	end)
	dialog:HookScript("OnHide", function(owner)
		local active = self.activeTitlePrompt
		if not active or active.dialog ~= owner then
			return
		end
		local readable, displayedName = pcall(owner.InviteeName.GetText, owner.InviteeName)
		active.matchedOnClose = readable and MatchesName(displayedName, active.name)
		-- Blizzard closes the popup inside Send's click handler. Let that handler
		-- and the post-hook finish before opening the next confirmation.
		C_Timer.After(0, function()
			if self.activeTitlePrompt ~= active then
				return
			end
			self.activeTitlePrompt = nil
			if active.confirmed then
				self.requestedTitleFriends = self.requestedTitleFriends or {}
				self.requestedTitleFriends[active.name:lower()] = true
			end
			if self.titleInviteBatch == active.batch and active.matchedOnClose then
				self:AdvanceTitleInvites()
			else
				self.titleInviteBatch = nil
			end
			if self.RefreshTitleFriendUI then
				self:RefreshTitleFriendUI()
			end
		end)
	end)
	return true
end

function GlobalSync:StartTitleInvites(names)
	if self.titleInviteBatch or self.activeTitlePrompt or #names == 0 then
		return false
	end
	self.titleInviteBatch = { names = names, index = 1 }
	return self:AdvanceTitleInvites() == true
end

function GlobalSync:RestoreStoredFriend(faction, key)
	local entry = GetStoredFriend(faction, key)
	if not entry or not self:ShouldAddFriend(key) then
		return false
	end
	local titleMode = self:UsesTitleFriends()
	if titleMode == nil then
		return false
	end
	if titleMode then
		if self:IsKnownTitleFriend(key) or (self.requestedTitleFriends and self.requestedTitleFriends[key:lower()]) then
			return false
		end
		-- The user clicked a database row. Blizzard still owns confirmation.
		return self:StartTitleInvites({ key })
	end
	if TryFriendAction(BFL.AddFriend, key) then
		self.pendingRestores = self.pendingRestores or {}
		self.pendingRestores[entry] = true
		self:OnFriendListUpdate()
		return true
	end
	return false
end

local function FindLocalFriend(sync, key, entry)
	local count = GetFriendCount()
	local realm = GetNormalizedRealmName()
	for index = 1, count or 0 do
		local info = GetReadableFriend(index)
		if info and (MatchesName(sync:GetFriendKey(info.name, realm), key)
			or (IsName(entry.guid) and not IsSecret(info.guid) and info.guid == entry.guid))
		then
			return info.name
		end
	end
end

function GlobalSync:DeleteStoredFriend(faction, key)
	local entry = GetStoredFriend(faction, key)
	if not entry or self:UsesTitleFriends() ~= false then
		return
	end
	entry.deleted, entry.deletedTime = true, time()
	if BetterFriendlistDB.enableGlobalSyncDeletion then
		local name = FindLocalFriend(self, key, entry)
		if name then
			TryFriendAction(BFL.RemoveFriend, name)
		end
	end
end

-- Removing a saved record is independent of deleting a Blizzard friendship.
-- In particular, imported legacy records must remain removable with Title Friends.
function GlobalSync:RemoveStoredEntry(faction, key)
	if not IsName(faction) or not IsName(key) then return false end
	local database = BetterFriendlistDB and BetterFriendlistDB.GlobalFriends
	local friends = IsReadableTable(database) and database[faction]
	local entry = IsReadableTable(friends) and friends[key]
	if not IsReadableTable(entry) then return false end
	friends[key] = nil
	if self.pendingRestores then self.pendingRestores[entry] = nil end
	if self.attemptedAdds then self.attemptedAdds[key] = nil end
	return true
end

function GlobalSync:GetStoredEntryCount()
	local database = BetterFriendlistDB and BetterFriendlistDB.GlobalFriends
	if not IsReadableTable(database) then return 0 end
	local count = 0
	for _, friends in pairs(database) do
		if IsReadableTable(friends) then
			for _ in pairs(friends) do count = count + 1 end
		end
	end
	return count
end

local function ClearLocalTable(value)
	if not IsReadableTable(value) then return end
	for key in pairs(value) do value[key] = nil end
end

-- Remove saved records, including hidden/deleted ones, without touching native
-- friendships. Keep the graph and faction tables shared by the open editors.
function GlobalSync:ClearStoredEntries()
	self.storageGeneration = (self.storageGeneration or 0) + 1
	if self.addQueueTicker then self.addQueueTicker:Cancel(); self.addQueueTicker = nil end
	if self.updateTimer then self.updateTimer:Cancel(); self.updateTimer = nil end
	self.processingQueue, self.syncDeferred = false, false
	self.titleInviteBatch = nil
	self.deletionSnapshot, self.pendingIndexRemoval, self.refreshDatabase = nil, nil, nil
	ClearLocalTable(self.pendingRestores)
	ClearLocalTable(self.attemptedAdds)
	ClearLocalTable(self.requestedTitleFriends)
	-- An already open Blizzard confirmation remains owned by Blizzard and the
	-- user. Retain its tracking record; clearing the batch prevents a successor.
	local database = BetterFriendlistDB and BetterFriendlistDB.GlobalFriends
	if not IsReadableTable(database) then return 0 end
	local count = self:GetStoredEntryCount()
	for _, friends in pairs(database) do ClearLocalTable(friends) end
	return count
end

function GlobalSync:SetStoredFriendNote(faction, key, note)
	local entry = GetStoredFriend(faction, key)
	if not entry or IsSecret(note) or type(note) ~= "string" then
		return
	end
	entry.notes = note
	if self:UsesTitleFriends() == false then
		local name = FindLocalFriend(self, key, entry)
		if name then
			TryFriendAction(BFL.SetFriendNotes, name, note)
		end
	end
end

-- Helper: Get Normalized Realm Name (for DB keys and internal matching)
local function GetNormalizedRealm()
	return GetNormalizedRealmName()
end

-- Helper: Get Display Realm Name (for AddFriend API - preserves spaces/hyphens)
local function GetDisplayRealmName()
	return _G.GetRealmName()
end

-- Helper: Get Faction
local function GetFaction()
	local faction = UnitFactionGroup("player")
	return faction
end

-- Helper: Determine whether a FriendUID should be added (self-check)
function GlobalSync:ShouldAddFriend(friendUID, currentRealm, currentPlayerName)
	if not IsName(friendUID) then
		return false
	end

	currentRealm = currentRealm or GetNormalizedRealm()
	if currentPlayerName == nil then
		local getName = HasRegionalNames() and UnitNameUnmodified or UnitName
		local name, suffix = getName("player")
		if HasRegionalNames() and BFL.GetCopyCharacterName then
			currentPlayerName = BFL.GetCopyCharacterName(name, nil, suffix)
		else
			currentPlayerName = name
		end
	end
	if not IsName(currentPlayerName) then
		return false
	end
	if HasRegionalNames() then
		return friendUID:lower() ~= currentPlayerName:lower()
	end
	if not IsName(currentRealm) then
		return false
	end

	local name, realm = self:GetFriendNameAndRealm(friendUID)
	if not name or not realm then
		return false
	end

	local isSelf = (name == currentPlayerName) and (string.gsub(realm, "%s+", "") == currentRealm)
	return not isSelf
end

function GlobalSync:Initialize()
	-- Initialize DB structure if missing
	if not BetterFriendlistDB.GlobalFriends then
		BetterFriendlistDB.GlobalFriends = {
			Alliance = {},
			Horde = {},
		}
	end

	-- Perform Migration to Flat Structure
	self:MigrateGlobalFriends()

	-- Hook Deletion APIs
	self:HookDeletionAPIs()

	self:RegisterEvents()

	-- Initialize session tracking for attempted adds
	self.attemptedAdds = {}

	-- Ensure current realm display name is in the reverse lookup
	local normalizedRealm = GetNormalizedRealm()
	if BFL.RealmDisplayNames and normalizedRealm then
		BFL.RealmDisplayNames[normalizedRealm] = GetDisplayRealmName()
	end

	-- Request friend list update from server to ensure we have data
	if BFL.ShowFriends then
		BFL.ShowFriends()
	end

	-- BFL:DebugPrint("GlobalSync Module Initialized")
end

function GlobalSync:MigrateGlobalFriends()
	if BetterFriendlistDB.globalFriendsMigrated then
		return
	end

	-- BFL:DebugPrint("GlobalSync: Starting migration to flat structure...")

	local newStructure = {
		Alliance = {},
		Horde = {},
	}

	local count = 0

	-- Iterate old structure: [Faction][StorageKey][Name]
	for faction, storageKeys in pairs(BetterFriendlistDB.GlobalFriends) do
		if newStructure[faction] then
			for storageKey, friends in pairs(storageKeys) do
				-- Extract Realm from StorageKey (Format: "Realm - CharacterName" or legacy "Realm")
				local realm = string.match(storageKey, "^(.+) %- .+$") or storageKey

				for name, data in pairs(friends) do
					local friendUID = self:GetFriendKey(name, realm)

					-- Store in new structure (overwrite duplicates, last one wins)
					newStructure[faction][friendUID] = {
						notes = data.notes,
						guid = data.guid,
						lastSeen = data.lastSeen or time(), -- Preserve or add timestamp
					}
					count = count + 1
				end
			end
		end
	end

	-- Replace old DB with new structure
	BetterFriendlistDB.GlobalFriends = newStructure
	BetterFriendlistDB.globalFriendsMigrated = true

	-- BFL:DebugPrint("GlobalSync: Migration complete. Migrated " .. count .. " friends.")
end

function GlobalSync:HookDeletionAPIs()
	if self.hooksInstalled then
		return
	end
	self.hooksInstalled = true

	-- Hook RemoveFriend (Checks both Modern C_FriendList and Legacy Global)
	if C_FriendList and C_FriendList.RemoveFriend then
		hooksecurefunc(C_FriendList, "RemoveFriend", function(name)
			self:OnFriendRemoved(name)
		end)
	elseif RemoveFriend then
		hooksecurefunc("RemoveFriend", function(name)
			self:OnFriendRemoved(name)
		end)
	end

	-- An index may refer to a different row after the call. Reconcile a complete
	-- snapshot after the explicit removal instead of replacing Blizzard's API.
	if C_FriendList and C_FriendList.RemoveFriendByIndex then
		hooksecurefunc(C_FriendList, "RemoveFriendByIndex", function(index)
			if BetterFriendlistDB.enableGlobalSyncDeletion and self:UsesTitleFriends() == false
				and not IsSecret(index) and type(index) == "number" and CanChangeFriends() and self.deletionSnapshot
			then
				local pending = self.pendingIndexRemoval
				if pending and pending.snapshot == self.deletionSnapshot and time() <= pending.expires then
					pending.count = pending.count + 1
				else
					self.pendingIndexRemoval = { snapshot = self.deletionSnapshot, count = 1, expires = time() + 8 }
				end
				self:OnFriendListUpdate()
			end
		end)
	end

	-- Hook AddFriend
	if C_FriendList and C_FriendList.AddFriend then
		hooksecurefunc(C_FriendList, "AddFriend", function(name)
			self:OnFriendAdded(name)
		end)
	elseif AddFriend then
		hooksecurefunc("AddFriend", function(name)
			self:OnFriendAdded(name)
		end)
	end

	-- Hook SetFriendNotes
	if C_FriendList and C_FriendList.SetFriendNotes then
		hooksecurefunc(C_FriendList, "SetFriendNotes", function(name, notes)
			self:OnFriendNoteUpdated(name, notes)
		end)
	elseif SetFriendNotes then
		hooksecurefunc("SetFriendNotes", function(name, notes)
			self:OnFriendNoteUpdated(name, notes)
		end)
	end

	-- BFL:DebugPrint("GlobalSync: Deletion APIs hooked.")
end

function GlobalSync:OnFriendNoteUpdated(name, notes)
	if not IsName(name) or IsSecret(notes) or (notes ~= nil and type(notes) ~= "string")
		or self:UsesTitleFriends() ~= false
	then
		return
	end

	local faction = GetFaction()
	local realm = GetNormalizedRealm()

	if not IsName(faction) or not IsName(realm) then
		return
	end

	local friendUID = self:GetFriendKey(name, realm)
	if not friendUID then
		return
	end

	-- Update DB if entry exists
	if BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID] then
		BetterFriendlistDB.GlobalFriends[faction][friendUID].notes = notes
		-- BFL:DebugPrint("GlobalSync: Updated DB note for " .. friendUID .. " (Hooked SetFriendNotes).")
	end
end

function GlobalSync:OnFriendAdded(name)
	if not IsName(name) or self:UsesTitleFriends() ~= false or not CanChangeFriends() then
		return
	end

	local faction = GetFaction()
	local realm = GetNormalizedRealm()

	if not IsName(faction) or not IsName(realm) then
		return
	end

	local friendUID = self:GetFriendKey(name, realm)
	if not friendUID then
		return
	end

	local entry = BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID]
	if entry and entry.deleted then
		self.pendingRestores = self.pendingRestores or {}
		self.pendingRestores[entry] = true
	end
end

function GlobalSync:OnFriendRemoved(name)
	if not BetterFriendlistDB.enableGlobalSyncDeletion or self:UsesTitleFriends() ~= false or not CanChangeFriends() then
		return
	end
	if not IsName(name) then
		return
	end

	local faction = GetFaction()
	local realm = GetNormalizedRealm()

	if not IsName(faction) or not IsName(realm) then
		return
	end

	local friendUID = self:GetFriendKey(name, realm)
	if not friendUID then
		return
	end

	-- Check if exists in DB
	if BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID] then
		-- Mark as deleted instead of removing
		BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted = true
		BetterFriendlistDB.GlobalFriends[faction][friendUID].deletedTime = time()
		-- BFL:DebugPrint("GlobalSync: Marked " .. friendUID .. " as DELETED in Global DB.")

		self.refreshDatabase = true
		self:OnFriendListUpdate()
	end
end

function GlobalSync:RegisterEvents()
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
		self:OnFriendListUpdate()
	end)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if self.syncDeferred then
			self:OnFriendListUpdate()
		end
		if self.RefreshTitleFriendUI then self:RefreshTitleFriendUI() end
	end)
	if BFL.IsMainline and self.RefreshTitleFriendUI then
		local function RefreshTitleFriends()
			self:RefreshTitleFriendUI()
		end
		BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", RefreshTitleFriends)
		BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", RefreshTitleFriends)
		BFL:RegisterEventCallback("LEGACY_FRIEND_SYSTEM_STATUS_UPDATED", RefreshTitleFriends)
		if BetterFriendsFrame then
			BetterFriendsFrame:HookScript("OnShow", RefreshTitleFriends)
		end
	end
	pcall(function()
		BFL:RegisterEventCallback("LEGACY_FRIEND_SYSTEM_STATUS_UPDATED", function()
			self:OnFriendListUpdate()
		end)
	end)
end

function GlobalSync:OnFriendListUpdate()
	if not BetterFriendlistDB
		or (not BetterFriendlistDB.enableGlobalSync and not BetterFriendlistDB.enableGlobalSyncDeletion)
	then
		return
	end
	-- Throttle updates
	if self.updateTimer then
		return
	end
	local generation = self.storageGeneration or 0
	self.updateTimer = C_Timer.NewTimer(2, function()
		if generation ~= (self.storageGeneration or 0) then return end
		self:PerformSync()
		self.updateTimer = nil
	end)
end

function GlobalSync:ReconcileIndexRemoval(realm)
	if not BetterFriendlistDB.enableGlobalSyncDeletion then
		self.deletionSnapshot, self.pendingIndexRemoval = nil, nil
		return
	end
	local count = GetFriendCount()
	if not count then
		return
	end
	local names = {}
	for i = 1, count do
		local info = GetReadableFriend(i)
		if not info then
			return
		end
		names[self:GetFriendKey(info.name, realm)] = info.name
	end
	local pending = self.pendingIndexRemoval
	self.deletionSnapshot = { names = names, count = count }
	if not pending then
		return
	end
	if time() > pending.expires then
		self.pendingIndexRemoval = nil
		return
	end
	if count == pending.snapshot.count then
		return
	end
	self.pendingIndexRemoval = nil
	if count ~= pending.snapshot.count - pending.count then
		return
	end
	for key in pairs(names) do
		if not pending.snapshot.names[key] then
			return
		end
	end
	for key, name in pairs(pending.snapshot.names) do
		if not names[key] then
			self:OnFriendRemoved(name)
		end
	end
end

function GlobalSync:PerformSync()
	if not BetterFriendlistDB
		or (not BetterFriendlistDB.enableGlobalSync and not BetterFriendlistDB.enableGlobalSyncDeletion)
	then
		return
	end
	-- Title friendships are managed by Blizzard through explicit invitations.
	if self.processingQueue or self:UsesTitleFriends() ~= false then
		return
	end
	if BFL.CanUseWoWFriendList and not BFL.CanUseWoWFriendList() then
		return
	end
	self.syncDeferred = not CanChangeFriends()
	if self.syncDeferred then
		return
	end

	local faction = GetFaction()
	local realm = GetNormalizedRealm()

	if not IsName(faction) or not IsName(realm) then
		return
	end

	self:ReconcileIndexRemoval(realm)

	-- 1. Export current friends to DB
	self:ExportFriends(faction, realm)

	-- 2. Import friends from connected realms
	self:ImportFriends(faction, realm)

	-- 3. Sync Deletions (Remove friends marked as deleted)
	self:SyncDeletions(faction, realm)

	if self.refreshDatabase then
		self.refreshDatabase = nil
		local Settings = BFL:GetModule("Settings")
		if Settings and Settings.RefreshGlobalSyncTab then
			Settings:RefreshGlobalSyncTab()
		end
	end
end

function GlobalSync:ExportFriends(faction, realm)
	local numFriends = GetFriendCount()
	if not numFriends then
		return
	end

	-- Ensure faction table exists
	if not BetterFriendlistDB.GlobalFriends[faction] then
		BetterFriendlistDB.GlobalFriends[faction] = {}
	end

	local count = 0
	for i = 1, numFriends do
		local info = GetReadableFriend(i)
		if info then
			local friendUID = self:GetFriendKey(info.name, realm)

			-- Check if marked as deleted
			local dbEntry = BetterFriendlistDB.GlobalFriends[faction][friendUID]
			local restored = dbEntry and self.pendingRestores and self.pendingRestores[dbEntry]
			if restored then
				self.pendingRestores[dbEntry] = nil
				dbEntry.deleted = nil
				dbEntry.deletedTime = nil
				dbEntry.restoring = true
			end
			local isDeleted = dbEntry and dbEntry.deleted
			local isRestoring = dbEntry and dbEntry.restoring

			local noteReadable = not IsSecret(info.notes) and (info.notes == nil or type(info.notes) == "string")
			local noteToSave = noteReadable and (info.notes or "") or (dbEntry and dbEntry.notes)
			local dbNote = dbEntry and dbEntry.notes

			-- SYNC NOTE LOGIC:
			-- 1. Restore: If restoring, force DB note.
			-- 2. DB Priority: If DB has a note, it overrides local note (DB is source of truth).
			-- 3. Local Priority: If DB has NO note, local note is saved to DB.

			if isRestoring then
				if dbNote and dbNote ~= "" then
					TryFriendAction(BFL.SetFriendNotes, info.name, dbNote)
					noteToSave = dbNote
					-- BFL:DebugPrint("GlobalSync: Restored note for " .. info.name)
				end
				BetterFriendlistDB.GlobalFriends[faction][friendUID].restoring = nil
			elseif dbNote and noteReadable then
				-- DB has a note. Check if we need to enforce it.
				if noteToSave ~= dbNote then
					TryFriendAction(BFL.SetFriendNotes, info.name, dbNote)
					noteToSave = dbNote
					-- BFL:DebugPrint("GlobalSync: Enforced DB note for " .. info.name)
				end
			end

			-- Only update if NOT marked as deleted (unless we want to force un-delete, but AddFriend hook handles that)
			if not isDeleted then
				-- Update DB entry
				BetterFriendlistDB.GlobalFriends[faction][friendUID] = {
					notes = noteToSave,
					guid = IsName(info.guid) and info.guid or (dbEntry and dbEntry.guid),
					lastSeen = time(),
				}
				count = count + 1
			end
		end
	end

	-- BFL:DebugPrint("GlobalSync: Exported " .. count .. " friends to flat DB.")
end

function GlobalSync:ImportFriends(faction, currentRealm)
	-- Check if sync is enabled in settings (default false)
	if not BetterFriendlistDB.enableGlobalSync or self:UsesTitleFriends() ~= false or not CanChangeFriends() then
		return
	end

	-- Ensure faction table exists
	if not BetterFriendlistDB.GlobalFriends[faction] then
		return
	end

	-- Check friend list cap (max 100 WoW friends)
	local numFriends = GetFriendCount()
	if not numFriends then
		return
	end
	if numFriends >= 100 then
		return
	end

	local friendsToAdd = {}
	local currentFriendList = {}
	local currentFriendNames = {} -- Name-only lookup for connected realm matching

	-- Build connected realm set for current realm (normalized names)
	local connectedRealms = {}
	local connectedList = BFL.GetConnectedRealms and BFL:GetConnectedRealms(currentRealm)
	if connectedList then
		for _, connRealm in ipairs(connectedList) do
			connectedRealms[connRealm] = true
		end
	end
	connectedRealms[currentRealm] = true -- Include self

	-- Cache current friends for quick lookup
	for i = 1, numFriends do
		local info = GetReadableFriend(i)
		if not info then
			return
		end
		local uid = self:GetFriendKey(info.name, currentRealm)
		currentFriendList[uid:lower()] = true
		local name = self:GetFriendNameAndRealm(uid)
		if name then
			currentFriendNames[name] = true
		end
	end

	-- Iterate FLAT structure: [Faction][FriendUID]
	local now = time()
	for friendUID, data in pairs(BetterFriendlistDB.GlobalFriends[faction]) do
		local attempt = self.attemptedAdds[friendUID]
		if not data.deleted and (not attempt or (attempt.count < MAX_ADD_DISPATCHES and now >= attempt.retryAt)) then
			-- Check if we already have this friend (exact UID match)
			if not currentFriendList[friendUID:lower()] then
				-- Parse UID to get Name and Realm
				local name, realm = self:GetFriendNameAndRealm(friendUID)

				if name then
					-- Check connected realm: friend may already exist under different realm suffix
					if connectedRealms[realm] and currentFriendNames[name] then
						-- Already have this friend on a connected realm, skip
					elseif self:ShouldAddFriend(friendUID, currentRealm) then
						local nameToAdd
						if not realm or realm == currentRealm or connectedRealms[realm] then
							-- Same realm or connected realm: just the name (no suffix needed)
							nameToAdd = name
						else
							-- Cross realm: resolve display realm name for AddFriend
							local displayRealm = BFL.RealmDisplayNames and BFL.RealmDisplayNames[realm] or realm
							nameToAdd = name .. "-" .. displayRealm
						end

						table.insert(friendsToAdd, { key = friendUID, name = nameToAdd, faction = faction })
						if #friendsToAdd >= 100 - numFriends then
							break
						end
					end
				end
			end
		end
	end

	-- Process queue
	if #friendsToAdd > 0 then
		-- BFL:DebugPrint("GlobalSync: Found " .. #friendsToAdd .. " missing friends.")
		self:ProcessAddQueue(friendsToAdd)
	end
end

function GlobalSync:SyncDeletions(faction, currentRealm)
	-- Check if deletion sync is enabled
	if not BetterFriendlistDB.enableGlobalSyncDeletion or self:UsesTitleFriends() ~= false then
		return
	end
	if not BetterFriendlistDB.GlobalFriends[faction] then
		return
	end

	local friendsToRemove = {}

	-- Iterate current friends
	local numFriends = GetFriendCount()
	if not numFriends then
		return
	end
	for i = 1, numFriends do
		local info = GetReadableFriend(i)
		if info then
			local friendUID = self:GetFriendKey(info.name, currentRealm)

			-- Check if marked as deleted in DB
			local dbEntry = BetterFriendlistDB.GlobalFriends[faction][friendUID]
			if dbEntry and dbEntry.deleted then
				table.insert(friendsToRemove, info.name)
			end
		end
	end

	-- Process removals
	if #friendsToRemove > 0 then
		-- BFL:DebugPrint("GlobalSync: Found " .. #friendsToRemove .. " friends marked for deletion.")
		for _, name in ipairs(friendsToRemove) do
			-- BFL:DebugPrint("GlobalSync: Removing " .. name .. " (Synced Deletion)")
			TryFriendAction(BFL.RemoveFriend, name)
		end
	end
end

function GlobalSync:ProcessAddQueue(queue)
	if self.processingQueue then
		return
	end
	self.processingQueue = true

	local index = 1
	local max = #queue

	if self.addQueueTicker then
		self.addQueueTicker:Cancel()
		self.addQueueTicker = nil
	end

	local generation = self.storageGeneration or 0
	self.addQueueTicker = C_Timer.NewTicker(0.5, function(timer)
		if generation ~= (self.storageGeneration or 0) then timer:Cancel(); return end
		local legacyMode = self:UsesTitleFriends() == false
		if not BetterFriendlistDB.enableGlobalSync or not legacyMode or not CanChangeFriends() then
			self.syncDeferred = BetterFriendlistDB.enableGlobalSync and legacyMode
			timer:Cancel()
			self.addQueueTicker = nil
			self.processingQueue = false
			return
		end

		for i = 1, BATCH_SIZE do
			if index > max then
				timer:Cancel()
				self.addQueueTicker = nil
				self.processingQueue = false
				-- BFL:DebugPrint("GlobalSync: Finished syncing friends.")
				return
			end

			local entry = queue[index]
			local friends = BetterFriendlistDB.GlobalFriends[entry.faction]
			local stored = friends and friends[entry.key]
			if stored and not stored.deleted and TryFriendAction(BFL.AddFriend, entry.name) then
				-- AddFriend has no server acknowledgement. A later update may retry
				-- a still-missing friend after the cooldown, with a per-session cap.
				local attempt = self.attemptedAdds[entry.key]
				self.attemptedAdds[entry.key] = {
					count = (attempt and attempt.count or 0) + 1,
					retryAt = time() + ADD_RETRY_DELAY,
				}
			end

			index = index + 1
		end
	end)
end

-- Register module
BFL.Modules[MODULE_NAME] = GlobalSync
