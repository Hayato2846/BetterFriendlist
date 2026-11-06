-- Modules/NoteSync.lua
-- Sync custom groups using FriendGroups notes. Local edits stay authoritative until acknowledged.
local ADDON_NAME, BFL = ...
local NoteSync = BFL:RegisterModule("NoteSync", {})
local BNET_NOTE_LIMIT, WOW_NOTE_LIMIT = 127, 48
local SYNC_BATCH_SIZE, SYNC_TICK_INTERVAL, VERIFY_DEBOUNCE = 5, 0.1, 5
-- BFL fairness/pacing policy, not a documented Blizzard request-rate limit.
local MAX_RETRY_DELAY = 60
local TOKEN_PREFIX, JOURNAL_KEY = "~BFL1~", "noteSyncPendingWrites"
NoteSync.isSyncing, NoteSync.isImporting, NoteSync.isWriting = false, false, false
NoteSync.pendingWrites, NoteSync.inFlight, NoteSync.titleIdentities = {}, {}, {}
NoteSync.retryCounts, NoteSync.retryNotes = {}, {}
NoteSync.retryAt = {}
NoteSync.passiveQueued = {}
NoteSync.submitted = {}

local SnapshotFriends

local function IsEnabled()
	local DB = BFL:GetModule("DB")
	return DB and DB:Get("syncGroupsToNote") == true
end

local function WizardIsBusy()
	local wizard = BFL.NoteCleanupWizard
	return wizard and wizard.IsBusy and wizard:IsBusy()
end

local function EncodeGroupName(name)
	if name:find("#", 1, true) or strtrim(name) ~= name or name:sub(1, #TOKEN_PREFIX) == TOKEN_PREFIX then
		return TOKEN_PREFIX .. name:gsub("[%%#%s~]", function(char)
			return string.format("%%%02X", string.byte(char))
		end)
	end
	return name
end

local function DecodeGroupName(token)
	if token:sub(1, #TOKEN_PREFIX) == TOKEN_PREFIX then
		local decoded = token:sub(#TOKEN_PREFIX + 1):gsub("%%(%x%x)", function(hex)
			return string.char(tonumber(hex, 16))
		end)
		if EncodeGroupName(decoded) == token then return decoded end
	end
	return strtrim(token)
end

local function LetterCount(text)
	-- Native note dialogs use SetMaxLetters, not SetMaxBytes. Never slice UTF-8 sequences.
	local _, count = text:gsub("[^\128-\191]", "")
	return count
end

function NoteSync:GetGroupNamesForFriend(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then return {} end
	local orderMap, entries, names = {}, {}, {}
	for i, id in ipairs(DB:Get("groupOrder") or {}) do orderMap[id] = i end
	local customGroups = DB:GetCustomGroups()
	for _, id in ipairs(DB:GetFriendGroups(friendUID)) do
		local group = customGroups[id]
		if group and type(group.name) == "string" then
			entries[#entries + 1] = { name = group.name, order = orderMap[id] or group.order or 9999, id = id }
		end
	end
	table.sort(entries, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.id < b.id
	end)
	for _, entry in ipairs(entries) do names[#names + 1] = entry.name end
	return names
end

function NoteSync:ParseNoteGroups(noteText, friendUID)
	if not (BFL.FriendNotes and BFL.FriendNotes.IsReadableString(noteText)) or noteText == "" then return "", {} end
	local parts, groups, i = { strsplit("#", noteText) }, {}, 2
	-- Current assignments disambiguate raw names written before delimiter escaping existed.
	local knownNames = friendUID and self:GetGroupNamesForFriend(friendUID) or {}
	table.sort(knownNames, function(a, b) return #a > #b end)
	while i <= #parts do
		local name, consumed
		local decoded, knownLiteral, knownDecoded = DecodeGroupName(parts[i]), false, false
		for _, known in ipairs(knownNames) do
			knownLiteral = knownLiteral or known == parts[i]
			knownDecoded = knownDecoded or known == decoded
		end
		if decoded ~= strtrim(parts[i]) and (not knownLiteral or knownDecoded) then name, consumed = decoded, 1 end
		for _, known in ipairs(name and {} or knownNames) do
			if EncodeGroupName(known) ~= known then
				local candidate, j = parts[i], i
				while #candidate < #known and j < #parts do
					j = j + 1
					candidate = candidate .. "#" .. parts[j]
				end
				if candidate == known then name, consumed = known, j - i + 1; break end
			end
		end
		name = name or DecodeGroupName(parts[i])
		if name ~= "" then groups[#groups + 1] = name end
		i = i + (consumed or 1)
	end
	return parts[1] or "", groups
end

function NoteSync:BuildNoteWithGroups(actualNote, groupNames, charLimit)
	local result, limitReached = actualNote or "", false
	for _, name in ipairs(groupNames or {}) do
		local candidate = result .. "#" .. EncodeGroupName(name)
		if LetterCount(candidate) > charLimit then limitReached = true; break end
		result = candidate
	end
	return result, limitReached
end

function NoteSync:LoadPendingWrites()
	local DB = BFL:GetModule("DB")
	local saved = DB and DB:Get(JOURNAL_KEY)
	if type(saved) == "table" then
		local ordered = {}
		for uid in pairs(saved) do if type(uid) == "string" then ordered[#ordered + 1] = uid end end
		table.sort(ordered)
		for _, uid in ipairs(ordered) do
			local pending = saved[uid]
			-- Do not replay numeric Title write intent without a verified current-session identity.
			local accepted = type(pending) == "table" and BFL.FriendNotes.IsReadableString(pending.note)
				and BFL.FriendNotes.IsReadableString(pending.before)
			if (pending == true or accepted) and not uid:match("^bnet_%d+$") then
				if not accepted or not pending.deliveryOnly then self.pendingWrites[uid] = true end
				if accepted and not self.inFlight[uid] then
					self.inFlight[uid] = BFL.FriendNotes.GetAcceptedWrite(uid)
					if pending.deliveryOnly and not self.pendingWrites[uid] then self.passiveQueued[uid] = true end
				end
				self:TrackSyncWork(uid)
				if not self.inFlight[uid] then self:QueueFriend(uid) end
			end
		end
	end
end

function NoteSync:TrackSyncWork(uid)
	self.syncReport = self.syncReport or { uids = {}, confirmed = {}, limits = {}, unavailable = {}, callbacks = {} }
	self.syncReport.uids[uid], self.syncReport.confirmed[uid] = true, nil
end

function NoteSync:MarkPending(friendUID, pending)
	self.pendingWrites[friendUID] = pending and true or nil
	if pending then
		self.passiveQueued[friendUID] = nil
		if self.syncReport then self.syncReport.confirmed[friendUID] = nil end
	end
	if not pending then self.inFlight[friendUID], self.submitted[friendUID] = nil, nil; self:ResetRetry(friendUID) end
	if friendUID:match("^bnet_%d+$") then return end
	-- Internal delivery bookkeeping is not a visual setting. DB:Set would bump
	-- SettingsVersion and invalidate every visible list even for a no-op readback.
	if BetterFriendlistDB then
		local saved = BetterFriendlistDB[JOURNAL_KEY]
		if type(saved) ~= "table" then saved = {} end
		local accepted = self.inFlight[friendUID] or BFL.FriendNotes.GetAcceptedWrite(friendUID)
		if accepted and accepted.confirmed then self.inFlight[friendUID] = nil; accepted = BFL.FriendNotes.GetAcceptedWrite(friendUID) end
		local delivery
		if pending then
			delivery = true
			if accepted then
				delivery = { note = accepted.note, before = accepted.before, name = accepted.name, guid = accepted.guid }
			end
		end
		saved[friendUID] = delivery
		BetterFriendlistDB[JOURNAL_KEY] = next(saved) and saved or nil
	end
end

function NoteSync:ResetRetry(friendUID)
	-- A roster event or DB mutation cannot cancel a request already accepted by native code.
	self.retryCounts[friendUID], self.retryNotes[friendUID] = nil, nil
	self.retryAt[friendUID] = nil
end

function NoteSync:CancelWork()
	self.workVersion = (self.workVersion or 0) + 1
	if self.syncTimer then self.syncTimer:Cancel(); self.syncTimer = nil end
	if self.verifyTimer then self.verifyTimer:Cancel(); self.verifyTimer = nil end
	self.isSyncing, self.isWriting = false, false
	self.syncQueue, self.syncQueued, self.syncCallbacks = nil, nil, nil
	self.verificationPending, self.enablePending, self.enableCallbacks = false, false, nil
	self.profileRestorePending = false
	self.waitingForWizard = false
	self.retryCounts, self.retryNotes = {}, {}
	self.retryAt, self.nextWriteAt, self.verifyDue, self.verificationDelay, self.syncReport = {}, nil, nil, nil, nil
	self.passiveQueued = {}
	self.submitted = {}
	self.rosterChanged, self.noteEventPending = false, false
end

function NoteSync:ResetPendingWrites()
	self:CancelWork()
	self.pendingWrites, self.unresolvedImports, self.titleIdentities = {}, {}, {}
	self.profileRestorePending = false
	if BetterFriendlistDB then BetterFriendlistDB[JOURNAL_KEY] = nil end
	BFL.FriendNotes.PreserveAcceptedWrites()
	-- Accepted local deliveries can still arrive after a profile change. Observe them
	-- before sending the new stable-UID goal; never import these records from a profile.
	for uid in pairs(self.inFlight) do self:MarkPending(uid, true) end
end

function NoteSync:OnDatabaseImported()
	-- The importer calls this only after its transaction commits. Do not import stale notes.
	local committed = false
	local timer = C_Timer.NewTimer(0, function()
		if not committed then return end
		self.verifyTimer = nil
		if IsEnabled() then self:SyncAllFriends() end
	end)
	local ok, err = pcall(self.ResetPendingWrites, self)
	if not ok then timer:Cancel(); error(err) end
	self.profileRestorePending = true
	self.verifyTimer, committed = timer, true
end

function NoteSync:Disable()
	local DB = BFL:GetModule("DB")
	if DB then DB:Set("syncGroupsToNote", false) end
	self:CancelWork()
end

function NoteSync:Enable(callback, progressCallback)
	if self.isImporting then return false end
	self:CancelWork()
	self.profileRestorePending = false
	self:LoadPendingWrites()
	local DB = BFL:GetModule("DB")
	if not DB then return false end
	DB:Set("syncGroupsToNote", true)
	if WizardIsBusy() then
		self.waitingForWizard = true
		self.enablePending, self.enableCallbacks = true, { callback, progressCallback }
		self:ScheduleVerification(1)
		return true, 0, 0
	end
	local groups, assignments, success, complete = self:ImportGroupsFromNotes()
	if not success then self:Disable(); return false end
	if complete then
		self:SyncAllFriends(callback, progressCallback)
	else
		self.enablePending, self.enableCallbacks = true, { callback, progressCallback }
		self:ScheduleVerification()
	end
	return true, groups, assignments
end

function NoteSync:SetEnabled(enabled, callback, progressCallback)
	if enabled then return self:Enable(callback, progressCallback) end
	self:Disable()
	return true
end

function NoteSync:Initialize()
	self:LoadPendingWrites()
	if not self.eventsRegistered then
		self.eventsRegistered = true
		for _, event in ipairs({ "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_CONNECTED", "LEGACY_FRIEND_SYSTEM_STATUS_UPDATED" }) do
			local rosterChanged = event ~= "FRIENDLIST_UPDATE" and event ~= "BN_FRIEND_INFO_CHANGED"
			BFL:RegisterEventCallback(event, function()
				-- Events only flag work. Native note setters can synchronously emit
				-- many events; do not read the entire roster from each callback.
				self.rosterChanged = self.rosterChanged or rosterChanged
				self.noteEventPending = true
				self:ScheduleVerification()
			end, 90)
		end
	end
	-- Unsent journal work already has explicit local authority; do not hold its
	-- first dispatch behind the normal five-second note-import debounce.
	if next(self.pendingWrites) then self:StartDispatcher() end
	self:ScheduleVerification()
end

function NoteSync:ScheduleVerification(delay)
	if not IsEnabled() then return end
	delay = math.max(0.25, delay or VERIFY_DEBOUNCE)
	if self.isWriting or self.isSyncing or self.isImporting then
		self.verificationPending = true
		self.verificationDelay = math.min(self.verificationDelay or delay, delay)
		return
	end
	local due = (GetTime and GetTime() or 0) + delay
	-- Busy rosters must not postpone a scheduled verification forever.
	if self.verifyTimer and self.verifyDue and self.verifyDue <= due then return end
	if self.verifyTimer then self.verifyTimer:Cancel() end
	self.verifyDue, self.verificationDelay = due, nil
	self.verifyTimer = C_Timer.NewTimer(delay, function()
		self.verifyTimer, self.verifyDue = nil, nil
		self:VerifyAllNotes()
	end)
end

SnapshotFriends = function()
	local friends, helper = {}, BFL.FriendNotes
	if not helper then return friends, false end
	local snapshot = helper.CaptureSnapshot()
	for uid, account in pairs(snapshot.bnet) do
		if account then friends[uid] = { note = account.note or "", account = account } end
	end
	for _, info in pairs(snapshot.wow) do
		if info then
		local name = BFL:NormalizeWoWFriendName(info.name)
		if name then friends["wow_" .. name] = { note = info.notes or "", name = info.name } end
		end
	end
	return friends, snapshot.complete, snapshot
end

function NoteSync:ApplyRosterChanges(friends)
	if not self.noteEventPending then return end
	for uid in pairs(self.pendingWrites) do
		local note = friends[uid] and friends[uid].note
		if self.rosterChanged or (self.retryCounts[uid] and note ~= self.retryNotes[uid]) then self:ResetRetry(uid) end
	end
	self.rosterChanged, self.noteEventPending = false, false
end

function NoteSync:BindTitleIdentity(uid, account, explicitAction, snapshot)
	if uid:match("^bnet_%d+$") then
		local helper = BFL.FriendNotes
		if not helper then return end
		local identity = self.titleIdentities[uid]
		if identity and helper.ResolveBNetIdentity(identity, snapshot and snapshot.bnet) then return end
		-- An invalidated identity is evidence of a boundary, not permission to select its replacement.
		if identity and not explicitAction then return end
		if not account then
			if snapshot then account = snapshot.bnet[uid] else account = helper.FindBNetFriend(uid) end
		end
		if not account then return end
		if not explicitAction then
			-- Persisted numeric mappings alone cannot authorize sending names to another account.
			local present = {}
			local _, names = self:ParseNoteGroups(account.note or "", uid)
			for _, name in ipairs(names) do present[name:lower()] = true end
			for _, name in ipairs(self:GetGroupNamesForFriend(uid)) do
				if not present[name:lower()] then return end
			end
		end
		self.titleIdentities[uid] = helper.CreateBNetIdentity(account)
	end
end

function NoteSync:ImportGroupsFromNotes(friends, excluded, snapshot)
	local DB, Groups = BFL:GetModule("DB"), BFL:GetModule("Groups")
	if not DB or not Groups or self.isImporting then return 0, 0, false end
	local created, assigned = 0, 0
	local complete = true
	self.isImporting = true
	local success, err = pcall(function()
		if not friends then friends, complete, snapshot = SnapshotFriends() end
		local allNames, assignments = {}, {}
		for uid, friend in pairs(friends) do
			local barrier = BFL.FriendNotes.ObserveAcceptedWrite(uid, friend.note, snapshot)
			if not barrier and not self.pendingWrites[uid] and not (excluded and excluded[uid]) then
				local _, names = self:ParseNoteGroups(friend.note, uid)
				assignments[uid] = names
				for _, name in ipairs(names) do allNames[name] = true end
				if #names > 0 then self:BindTitleIdentity(uid, friend.account, false, snapshot) end
			end
		end
		local sorted, nameMap, order, seen = {}, {}, {}, {}
		for name in pairs(allNames) do sorted[#sorted + 1] = name end
		table.sort(sorted)
		for _, id in ipairs(DB:Get("groupOrder") or { "favorites" }) do
			if not seen[id] then order[#order + 1] = id; seen[id] = true end
		end
		local insertAt, nextOrder = #order + 1, 2
		for i, id in ipairs(order) do if id == "nogroup" then insertAt = i; break end end
		for id, group in pairs(Groups:GetAll()) do
			if id ~= "nogroup" then nextOrder = math.max(nextOrder, (group.order or 1) + 1) end
		end
		for _, name in ipairs(sorted) do
			local id = Groups:GetGroupIdByName(name)
			if not id then
				local added
				added, id = Groups:CreateWithOrder(name, nextOrder)
				if added then
					created, nextOrder = created + 1, nextOrder + 1
					if not seen[id] then table.insert(order, insertAt, id); seen[id] = true; insertAt = insertAt + 1 end
				else id = nil end
			end
			-- Built-ins derive membership. Do not delete an unrepresentable imported token.
			if id and not Groups:Get(id).builtin then nameMap[name] = id end
		end
		if not seen.nogroup then order[#order + 1] = "nogroup" end
		if created > 0 then DB:Set("groupOrder", order) end
		self.unresolvedImports = self.unresolvedImports or {}
		for uid, names in pairs(assignments) do
			local unresolved = false
			for _, name in ipairs(names) do
				local id = nameMap[name]
				if id then
					if DB:AddFriendToGroup(uid, id) then assigned = assigned + 1 end
				else unresolved = true end
			end
			self.unresolvedImports[uid] = unresolved and true or nil
		end
	end)
	self.isImporting = false
	if not success then BFL:DebugPrint("NoteSync: Import failed: " .. tostring(err)); return created, assigned, false end
	if created > 0 or assigned > 0 then
		local refreshed, refreshError = pcall(BFL.ForceRefreshFriendsList, BFL)
		if not refreshed then BFL:DebugPrint("NoteSync: Refresh failed: " .. tostring(refreshError)) end
	end
	return created, assigned, true, complete
end

function NoteSync:WriteNote(friendUID, currentNote, groupNames, charLimit, writer, target, snapshot, identity)
	local actualNote = self:ParseNoteGroups(currentNote, friendUID)
	local expectedNote, limitReached = self:BuildNoteWithGroups(actualNote, groupNames, charLimit)
	local shared = BFL.FriendNotes.ObserveAcceptedWrite(friendUID, currentNote, snapshot)
	if shared then
		self.inFlight[friendUID] = shared
		if not self.pendingWrites[friendUID] then self.passiveQueued[friendUID] = true end
	end
	local accepted = self.inFlight[friendUID]
	if accepted then
		if shared or (not accepted.confirmed and currentNote ~= accepted.note) then
			-- Even current == latest desired can be the pre-write base state. An old
			-- accepted add may still arrive after a local remove, so do not clear intent.
			self:TrackSyncWork(friendUID)
			self:ScheduleVerification(VERIFY_DEBOUNCE)
			return false, limitReached, "awaiting"
		end
		self.inFlight[friendUID] = nil
		self:ResetRetry(friendUID)
		if self.pendingWrites[friendUID] then self:MarkPending(friendUID, true) end
	end
	if expectedNote == currentNote then self:MarkPending(friendUID, false); return true, limitReached end
	local now = GetTime and GetTime() or 0
	if self.isPolling then
		if not self.pendingWrites[friendUID] then self.passiveQueued[friendUID] = true end
		self:QueueFriend(friendUID); return false, limitReached, "queued"
	end
	local due = math.max(self.nextWriteAt or 0, self.retryAt[friendUID] or 0)
	if due > now then
		self:TrackSyncWork(friendUID)
		return false, limitReached, "paced"
	end
	local passive = not self.pendingWrites[friendUID] and self.passiveQueued[friendUID] == true
	if not passive then self:MarkPending(friendUID, true) end
	-- Apply the same pacing to bulk sync, verification and direct membership edits.
	self.nextWriteAt = now + SYNC_TICK_INTERVAL
	self.retryCounts[friendUID] = math.min((self.retryCounts[friendUID] or 0) + 1, 5)
	self.retryNotes[friendUID] = currentNote
	self.submitted[friendUID] = true
	self.isWriting = true
	local ok, success, reason = pcall(writer, target, expectedNote, currentNote, snapshot, identity, "sync")
	self.isWriting = false
	if ok and success then self:MarkPending(friendUID, false); return true, limitReached end
	self:TrackSyncWork(friendUID)
	if ok and reason == "changed" and passive then
		self:ResetRetry(friendUID); self.submitted[friendUID] = nil
		self.passiveQueued[friendUID] = true
		self:QueueFriend(friendUID); self:StartDispatcher()
		return false, limitReached, "changed"
	end
	if ok and reason == "blocked" then
		self.inFlight[friendUID] = BFL.FriendNotes.GetAcceptedWrite(friendUID)
		self:ScheduleVerification()
		return false, limitReached, "awaiting"
	end
	if ok and reason == "pending" then
		self.inFlight[friendUID] = BFL.FriendNotes.GetAcceptedWrite(friendUID) or { note = expectedNote, before = currentNote, time = now }
		self:MarkPending(friendUID, true)
		self.retryAt[friendUID] = nil
		self:ScheduleVerification(VERIFY_DEBOUNCE)
		return false, limitReached, "awaiting"
	end
	local delay = math.min(MAX_RETRY_DELAY, VERIFY_DEBOUNCE * 2 ^ (self.retryCounts[friendUID] - 1))
	self.retryAt[friendUID] = now + delay
	-- Only a real native rejection/error is eligible for automatic resubmission.
	self:ScheduleVerification(math.min(delay, VERIFY_DEBOUNCE))
	return false, limitReached, ok and reason or "failed"
end

function NoteSync:SyncBNetFriend(friendUID, groupNames, snapshot)
	local helper = BFL.FriendNotes
	local account = helper and helper.FindBNetFriend(friendUID, snapshot)
	local identity
	if friendUID:match("^bnet_%d+$") then
		identity = self.titleIdentities[friendUID]
		account = identity and helper.ResolveBNetIdentity(identity, snapshot and snapshot.bnet)
	end
	if not account or not helper.IsReadableString(account.note or "") then return false, false, "unavailable" end
	return self:WriteNote(friendUID, account.note or "", groupNames, BNET_NOTE_LIMIT, helper.WriteBNetNote, friendUID, snapshot, identity)
end

function NoteSync:SyncWoWFriend(friendUID, groupNames, snapshot, friends)
	local helper = BFL.FriendNotes
	if not helper then return false, false, "unavailable" end
	local friend = (friends or SnapshotFriends())[friendUID]
	if not friend then return false, false, "unavailable" end
	local info = snapshot and snapshot.wow[friend.name]
	local guid = info and helper.IsReadableString(info.guid) and info.guid or nil
	return self:WriteNote(friendUID, friend.note, groupNames, WOW_NOTE_LIMIT, helper.WriteWoWNote, friend.name, snapshot, guid)
end

function NoteSync:SyncSingleFriend(friendUID, snapshot, friends)
	if not IsEnabled() or self.isImporting or self.isWriting then return false, false, "disabled" end
	if WizardIsBusy() then self.waitingForWizard = true; self:ScheduleVerification(1); return false, false, "pending" end
	if not snapshot then
		local now = GetTime and GetTime() or 0
		if self.nextWriteAt and self.nextWriteAt > now then
			if self.pendingWrites[friendUID] then self:TrackSyncWork(friendUID) end
			self:QueueFriend(friendUID)
			self:StartDispatcher()
			return false, false, "paced"
		end
		local complete
		friends, complete, snapshot = SnapshotFriends()
		self:ApplyRosterChanges(friends)
	end
	if self.passiveQueued[friendUID] and not self.pendingWrites[friendUID] then
		-- Queueing a normal full sync is not a local edit. Read/import again at
		-- dispatch time, since a large paced queue can remain open for minutes.
		local friend = friends[friendUID]
		if not friend then
			if self.syncReport then self.syncReport.unavailable[friendUID] = true end
			return false, false, "unavailable"
		end
		local _, _, imported = self:ImportGroupsFromNotes({ [friendUID] = friend }, nil, snapshot)
		if not imported then return false, false, "unavailable" end
	end
	if self.unresolvedImports and self.unresolvedImports[friendUID] and not self.pendingWrites[friendUID] then return false, false, "unresolved" end
	local ok, success, limitReached, reason = pcall(function()
		local names = self:GetGroupNamesForFriend(friendUID)
		if friendUID:match("^bnet_") then return self:SyncBNetFriend(friendUID, names, snapshot) end
		if friendUID:match("^wow_") then return self:SyncWoWFriend(friendUID, names, snapshot, friends) end
		return false, false, "unavailable"
	end)
	self.isWriting = false
	if not ok then
		self:MarkPending(friendUID, true)
		self:TrackSyncWork(friendUID)
		self.retryAt[friendUID] = (GetTime and GetTime() or 0) + MAX_RETRY_DELAY
		self:ScheduleVerification(VERIFY_DEBOUNCE)
		BFL:DebugPrint("NoteSync: Write failed: " .. tostring(success))
		return false, false, "failed"
	end
	if self.syncReport then
		if success then self.syncReport.confirmed[friendUID] = true end
		if limitReached then self.syncReport.limits[friendUID] = true end
		self.syncReport.unavailable[friendUID] = not success and (reason == "unavailable" or reason == "unresolved") or nil
	end
	if reason == "unavailable" or reason == "unresolved" then self.retryAt[friendUID] = nil end
	if success then self.passiveQueued[friendUID] = nil end
	return success, limitReached, reason
end

function NoteSync:GetSyncStatus()
	local report = self.syncReport
	if not report then return nil end
	local status = { total = 0, confirmed = 0, queued = 0, waiting = 0, retrying = 0, unavailable = 0, limits = 0 }
	local now = GetTime and GetTime() or 0
	for uid in pairs(report.uids) do
		status.total = status.total + 1
		if report.confirmed[uid] then status.confirmed = status.confirmed + 1
		elseif report.unavailable[uid] then status.unavailable = status.unavailable + 1
		elseif self.inFlight[uid] then status.waiting = status.waiting + 1
		elseif not self.submitted[uid] then status.queued = status.queued + 1
		else status.retrying = status.retrying + 1 end
		if report.limits[uid] then status.limits = status.limits + 1 end
	end
	return status
end

function NoteSync:ReportSyncState()
	local report = self.syncReport
	if not report then return end
	local status = self:GetSyncStatus()
	local pending = status.total - status.confirmed
	local now = GetTime and GetTime() or 0
	local key = string.format("%d:%d:%d:%d:%d:%d", status.confirmed, status.total, status.queued, status.waiting, status.retrying, status.unavailable)
	if pending > 0 and report.lastUpdate and now - report.lastUpdate < 5 then return end
	if pending == 0 and self.isSyncing then return end
	local L = BFL.L or BFL_LOCALE or {}
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		if pending > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffff00BetterFriendlist:|r " .. string.format(L.MSG_SYNC_GROUPS_STATUS or "Note sync: %d/%d confirmed | %d queued | %d awaiting confirmation | %d retrying | %d unavailable.", status.confirmed, status.total, status.queued, status.waiting, status.retrying, status.unavailable))
		elseif pending == 0 then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00BetterFriendlist:|r " .. string.format(L.MSG_SYNC_GROUPS_COMPLETE or "Group note sync complete. Updated: %d, Skipped (limit): %d", status.confirmed, status.limits))
		end
	end
	report.lastStatus, report.lastUpdate = key, now
	if pending == 0 then
		self.syncReport = nil
		for _, callbacks in ipairs(report.callbacks) do if callbacks[1] then pcall(callbacks[1], status.confirmed, status.limits) end end
	end
end

function NoteSync:VerifyAllNotes()
	if not IsEnabled() then return end
	if WizardIsBusy() then self.waitingForWizard = true; self:ScheduleVerification(1); return end
	self.waitingForWizard = false
	if self.isSyncing or self.isImporting or self.isWriting then self.verificationPending = true; return end
	self.verificationPending = false
	if self.profileRestorePending then self:SyncAllFriends(); return end
	if self.enablePending then
		local friends, complete, snapshot = SnapshotFriends()
		local _, _, success = self:ImportGroupsFromNotes(friends, nil, snapshot)
		if success and complete then
			local callbacks = self.enableCallbacks or {}
			self.enablePending, self.enableCallbacks = false, nil
			self:SyncAllFriends(callbacks[1], callbacks[2])
		end
		return
	end
	local excluded = {}
	local friends, complete, snapshot = SnapshotFriends()
	self:ApplyRosterChanges(friends)
	for uid in pairs(self.pendingWrites) do excluded[uid] = true end
	local _, _, imported = self:ImportGroupsFromNotes(friends, excluded, snapshot)
	if not imported then return end
	-- Confirmation is read-only. A changed DB goal is dispatched only after the
	-- older accepted value is actually observed, and joins the same fair FIFO.
	self.isPolling = true
	for uid in pairs(friends) do self:SyncSingleFriend(uid, snapshot, friends) end
	for uid in pairs(excluded) do if not friends[uid] then self:SyncSingleFriend(uid, snapshot, friends) end end
	self.isPolling = false
	self:StartDispatcher()
	if self.isSyncing then self:ProcessDispatch(friends, snapshot) end
	self:ReportSyncState()
	-- Unavailable/removed friends keep their journal entry and retry on roster events, not a permanent polling loop.
	if self.verificationPending then self:ScheduleVerification(self.verificationDelay) end
end

function NoteSync:QueueFriend(friendUID)
	if self.syncReport then self.syncReport.uids[friendUID] = true end
	if self.inFlight[friendUID] and self.inFlight[friendUID].confirmed then self.inFlight[friendUID] = nil end
	if self.inFlight[friendUID] then self:ScheduleVerification(); return end
	self.syncQueue, self.syncQueued = self.syncQueue or {}, self.syncQueued or {}
	if not self.syncQueued[friendUID] then
		self.syncQueue[#self.syncQueue + 1] = friendUID
		self.syncQueued[friendUID] = true
		if self.syncReport then self.syncReport.uids[friendUID] = true end
	end
end

function NoteSync:FinishDispatcher()
	if self.syncTimer then self.syncTimer:Cancel(); self.syncTimer = nil end
	self.isSyncing = false
	local callbacks = self.syncCallbacks or {}
	self.syncCallbacks = nil
	if self.syncReport then
		for _, entry in ipairs(callbacks) do self.syncReport.callbacks[#self.syncReport.callbacks + 1] = entry end
	end
	self:ReportSyncState()
	local delay
	local now = GetTime and GetTime() or 0
	for uid in pairs(self.pendingWrites) do
		if self.inFlight[uid] then delay = VERIFY_DEBOUNCE; break end
		if self.retryAt[uid] then delay = math.min(delay or VERIFY_DEBOUNCE, math.max(.25, self.retryAt[uid] - now)) end
	end
	if delay or self.verificationPending then self:ScheduleVerification(delay or self.verificationDelay) end
end

function NoteSync:ProcessDispatch(friends, snapshot)
	if not IsEnabled() or self.isImporting or WizardIsBusy() then return end
	if not friends then
		local complete
		friends, complete, snapshot = SnapshotFriends()
		self:ApplyRosterChanges(friends)
	end
	local version = self.workVersion
	for _ = 1, SYNC_BATCH_SIZE do
		local selected, retry
		local now = GetTime and GetTime() or 0
		-- Legacy booleans retain local intent but contain no persisted delivery
		-- receipt. Their initial attempt precedes known rejections, across entrypoints.
		for i, uid in ipairs(self.syncQueue) do
			if not self.submitted[uid] and not self.inFlight[uid] then selected = i; break end
			if not self.inFlight[uid] and (self.retryAt[uid] or 0) <= now and not retry then retry = i end
		end
		selected = selected or retry
		if not selected then self:FinishDispatcher(); return end
		local uid = table.remove(self.syncQueue, selected)
		self.syncQueued[uid] = nil
		local success, _, reason = self:SyncSingleFriend(uid, snapshot, friends)
		if version ~= self.workVersion then return end
		if reason == "paced" then
			-- Keep its position rather than sending it through a verification timer
			-- or rotating it behind newer requests on each pacing check.
			table.insert(self.syncQueue, selected, uid); self.syncQueued[uid] = true
			break
		elseif not success and reason ~= "awaiting" and reason ~= "unavailable" and reason ~= "unresolved" then
			self:QueueFriend(uid)
		end
	end
	local status = self:GetSyncStatus()
	for _, callbacks in ipairs(self.syncCallbacks or {}) do
		if callbacks[2] then pcall(callbacks[2], status and (status.total - #self.syncQueue) or 0, status and status.total or 0) end
		if version ~= self.workVersion then return end
	end
	self:ReportSyncState()
	if #self.syncQueue == 0 then self:FinishDispatcher() end
end

function NoteSync:StartDispatcher()
	if self.isSyncing or not IsEnabled() or self.isImporting then return end
	if not self.syncQueue or #self.syncQueue == 0 then return end
	self.isSyncing = true
	local version = self.workVersion
	self.syncTimer = C_Timer.NewTicker(SYNC_TICK_INTERVAL, function(ticker)
		if version ~= self.workVersion then ticker:Cancel(); return end
		if not IsEnabled() then self:CancelWork(); ticker:Cancel(); return end
		if self.isImporting then return end
		if WizardIsBusy() then self.waitingForWizard = true; self:FinishDispatcher(); self:ScheduleVerification(1); return end
		self:ProcessDispatch()
	end)
end

function NoteSync:SyncAllFriends(callback, progressCallback)
	if not IsEnabled() or self.isImporting then return false end
	if WizardIsBusy() then self.waitingForWizard = true; self:ScheduleVerification(1); return false end
	if self.enablePending then self:ScheduleVerification(); return true end
	local DB = BFL:GetModule("DB")
	if not DB then return false end
	local friends, complete, snapshot = SnapshotFriends()
	local restore = self.profileRestorePending
	-- Every newly readable UID gets its read/import phase before a normal full sync can claim write authority.
	if not restore then
		local _, _, imported = self:ImportGroupsFromNotes(friends, nil, snapshot)
		if not imported then return false end
	end
	self.syncQueue, self.syncQueued, self.syncCallbacks = self.syncQueue or {}, self.syncQueued or {}, self.syncCallbacks or {}
	self.syncReport = self.syncReport or { uids = {}, confirmed = {}, limits = {}, unavailable = {}, callbacks = {} }
	if callback or progressCallback then self.syncCallbacks[#self.syncCallbacks + 1] = { callback, progressCallback } end
	local function QueueAuthoritative(uid)
		-- A complete empty/partial roster does not establish intent for saved friends we have not seen.
		if not friends[uid] and not self.pendingWrites[uid] and not restore then return end
		if (self.unresolvedImports and self.unresolvedImports[uid]) and not self.pendingWrites[uid] then return end
		if uid:match("^bnet_%d+$") and not self.titleIdentities[uid] then return end
		if restore then self:ResetRetry(uid); self:MarkPending(uid, true)
		elseif not self.pendingWrites[uid] then self.passiveQueued[uid] = true end
		self:QueueFriend(uid)
	end
	for uid in pairs(DB:GetFriendGroups()) do QueueAuthoritative(uid) end
	for uid in pairs(self.pendingWrites) do self:QueueFriend(uid) end
	for uid, friend in pairs(friends) do if friend.note:find("#", 1, true) then QueueAuthoritative(uid) end end
	self.profileRestorePending = false
	if self.isSyncing then return true end
	local L = BFL.L or BFL_LOCALE or {}
	if #self.syncQueue > 0 and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffBetterFriendlist:|r " .. (L.MSG_SYNC_GROUPS_STARTED or "Syncing groups to friend notes..."))
	end
	self:StartDispatcher()
	if not self.isSyncing then self:FinishDispatcher() end
	return true
end

function NoteSync:OnGroupChanged(friendUID, preserveIdentity)
	if self.isImporting then return end
	local snapshot, friends = self.groupDefinitionSnapshot, self.groupDefinitionFriends
	if friendUID:match("^bnet_%d+$") and (preserveIdentity or self.isChangingGroupDefinition) then
		local identity = self.titleIdentities[friendUID]
		if not identity or not BFL.FriendNotes.ResolveBNetIdentity(identity, snapshot and snapshot.bnet) then return end
	else
		-- Remember explicit current-friend identity evidence even while sync is disabled.
		self:BindTitleIdentity(friendUID, snapshot and snapshot.bnet[friendUID], true, snapshot)
	end
	if not IsEnabled() then return end
	self:ResetRetry(friendUID)
	if not self.inFlight[friendUID] then self.submitted[friendUID] = nil end
	self:MarkPending(friendUID, true)
	if self.enablePending then return end
	if self.isSyncing then self:QueueFriend(friendUID); return end
	-- Preserve immediate feedback for an isolated edit, but never jump ahead of
	-- older unsent work loaded from the journal.
	self:QueueFriend(friendUID)
	self:StartDispatcher()
	if self.isSyncing then self:ProcessDispatch(friends, snapshot) end
end

function NoteSync:WithGroupDefinitionChange(callback)
	local previous = self.isChangingGroupDefinition
	local previousSnapshot, previousFriends = self.groupDefinitionSnapshot, self.groupDefinitionFriends
	local friends, complete, snapshot = SnapshotFriends()
	self.isChangingGroupDefinition, self.groupDefinitionSnapshot, self.groupDefinitionFriends = true, snapshot, friends
	local ok, err = pcall(callback)
	self.isChangingGroupDefinition, self.groupDefinitionSnapshot, self.groupDefinitionFriends = previous, previousSnapshot, previousFriends
	if not ok then error(err) end
end

function NoteSync:OnGroupRenamed(groupId)
	if not IsEnabled() or self.isImporting then return end
	local DB = BFL:GetModule("DB")
	if not DB then return end
	self:WithGroupDefinitionChange(function()
		for uid, ids in pairs(DB:GetFriendGroups()) do
			for _, id in ipairs(ids) do if id == groupId then self:OnGroupChanged(uid, true); break end end
		end
	end)
end

function NoteSync:OnGroupOrderChanged()
	if IsEnabled() and not self.isImporting then self:SyncAllFriends() end
end

function NoteSync:CleanFriendNote(friendUID)
	if not IsEnabled() or self.isImporting then return false end
	if friendUID:match("^bnet_") then return self:SyncBNetFriend(friendUID, {}) end
	if friendUID:match("^wow_") then return self:SyncWoWFriend(friendUID, {}) end
	return false
end
