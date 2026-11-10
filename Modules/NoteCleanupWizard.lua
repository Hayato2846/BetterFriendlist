-- NoteCleanupWizard.lua
-- Wizard UI for cleaning up FriendGroups-style notes (#Group1#Group2 suffixes)

local ADDON_NAME, BFL = ...

local NoteCleanupWizard = {}
BFL.NoteCleanupWizard = NoteCleanupWizard

local L = BFL.L or BFL_L
local DB
local FriendNotes = BFL.FriendNotes

-- ========================================
-- Constants
-- ========================================
local WIZARD_WIDTH = 780
local WIZARD_HEIGHT = 520
local ROW_HEIGHT = 26
local COLUMN_PADDING = 8
local HEADER_HEIGHT = 22
local SCROLL_BAR_WIDTH = 20
local STATUS_COL_WIDTH = 26

-- Column widths (relative to content area)
local COL_ACCOUNT = 0.20
local COL_BATTLETAG = 0.20
local COL_NOTE = 0.28
local COL_CLEANED = 0.32

-- ========================================
-- Local State
-- ========================================
local wizardFrame = nil
local backupViewerFrame = nil
local friendData = {} -- All scanned friends
local filteredData = {} -- After search filter
local rowFrames = {} -- Reusable row frames
local searchText = ""
local backupRowFrames = {} -- Reusable row frames for backup viewer
local backupFilteredData = {} -- Filtered backup data
local restoreOperationRows
local backupSearchText = ""
local isApplying = false
local isRestoring = false
local scanTotal = 0
local scanComplete = false
local pendingWrites, protectedBackups = {}, {}
local pendingTimer
local reconciling = false
local RefreshButtons
local mainRefreshPending, backupRefreshPending = false, false
local operationVersion = 0
local WRITE_INTERVAL = 0.5

local function IsText(value)
	return FriendNotes.IsReadableString(value)
end

local function SafeLabel(value, fallback)
	if IsText(value) and value ~= "" and not value:find("|K", 1, true) then return value end
	return fallback or L.UNKNOWN
end

local function Report(message)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffBetterFriendlist:|r " .. message)
	end
end

local function IsSyncEnabled()
	if not (BetterFriendlistDB and BetterFriendlistDB.syncGroupsToNote == true) then return false end
	local NoteSync = BFL:GetModule("NoteSync")
	-- Requested activation waits behind this operation. Its own retries must
	-- remain possible while sync has deliberately yielded ownership to us.
	return not (NoteSync and NoteSync.waitingForWizard and NoteCleanupWizard:IsBusy())
end

local function SnapshotNotes()
	return FriendNotes.CaptureSnapshot()
end

local function ResolveEntry(entry, key, snapshot)
	if not FriendNotes.IsReadableTable(entry) then return nil end
	if BFL:IsSecret(entry.isBNet) then return nil end
	if entry.isBNet == true then
		local account, reason, uid
		if FriendNotes.IsReadableTable(entry.identity) then
			uid = entry.identity.uid
			account, reason = FriendNotes.ResolveBNetIdentity(entry.identity, snapshot and snapshot.bnet)
		elseif IsText(entry.battleTag) and entry.battleTag ~= "" then
			-- Original backups used the BattleTag itself as the key.
			uid = "bnet_" .. entry.battleTag
			if snapshot then account = snapshot.bnet[uid] else account = FriendNotes.FindBNetFriend(uid) end
		end
		if account then return account, account.note or "", FriendNotes.GetBNetUID(account) end
		if reason == "identity" then return nil, nil, nil, reason end
		if snapshot and snapshot.bnetComplete and uid and snapshot.bnet[uid] == nil then return nil, nil, nil, "removed" end
	elseif entry.isBNet == false then
		local name = IsText(entry.characterName) and entry.characterName or key
		local info
		if snapshot then info = snapshot.wow[name] else info = FriendNotes.FindWoWFriend(name) end
		if not info then return nil, nil, nil, snapshot and snapshot.wowComplete and "removed" or "unavailable" end
		local guid = entry.guid
		if BFL:IsSecret(guid) or (guid ~= nil and not IsText(guid)) then return nil, nil, nil, "identity" end
		if guid ~= nil then
			if BFL:IsSecret(info.guid) or not IsText(info.guid) or info.guid == "" then return nil, nil, nil, "unavailable" end
			if info.guid ~= guid then return nil, nil, nil, "identity" end
		end
		return info, info.notes or "", name
	end
end

local function ReadEntry(entry, key, snapshot)
	local _, note, _, reason = ResolveEntry(entry, key, snapshot)
	return note, reason
end

local function WriteKey(entry, key)
	if entry.isBNet then
		return entry.identity and entry.identity.uid or ("bnet_" .. entry.battleTag)
	end
	return FriendNotes.GetWoWUID(entry.characterName or key)
end

local function SubmitEntry(entry, key, note, expected, snapshot)
	local info, _, identity = ResolveEntry(entry, key, snapshot)
	if not info then return false, "unavailable" end
	if entry.isBNet then
		return FriendNotes.WriteBNetNote(identity, note, expected, snapshot, entry.identity, "wizard")
	end
	return FriendNotes.WriteWoWNote(identity, note, expected, snapshot, entry.guid, "wizard")
end

local function CompletePending(record, success)
	if pendingWrites[record.uid] ~= record then return end
	pendingWrites[record.uid] = nil
	if not next(pendingWrites) and pendingTimer then pendingTimer:Cancel(); pendingTimer = nil end
	for _, callback in ipairs(record.callbacks) do callback(success) end
	if RefreshButtons and not reconciling then RefreshButtons() end
end

local function ReconcilePending(snapshot)
	if reconciling or not next(pendingWrites) then return end
	reconciling = true
	snapshot = snapshot or SnapshotNotes()
	for _, record in pairs(pendingWrites) do
		local current, reason = ReadEntry(record.entry, record.key, snapshot)
		local active = FriendNotes.ObserveAcceptedWrite(record.uid, current, snapshot)
		if reason == "identity" or reason == "removed" then
			CompletePending(record, false)
		elseif active then
			-- Stop/Disable cannot cancel an accepted request owned by another
			-- operation. Its pre-write base is never an acknowledgement of ours.
			if active.note ~= record.note then record.waitingOn = active end
		elseif record.waitingOn then
			local previous = record.waitingOn
			if record.kind == "restore" and current == previous.note and not IsSyncEnabled() then
				record.waitingOn, record.expected = nil, current
				local success, result = SubmitEntry(record.entry, record.key, record.note, current, snapshot)
				if success then CompletePending(record, true)
				elseif result ~= "pending" and result ~= "blocked" then CompletePending(record, false) end
			else
				-- Cleanup needs a fresh recovery backup after another owner's write.
				CompletePending(record, false)
			end
		elseif current == record.note then CompletePending(record, true)
		elseif current ~= nil and current ~= record.expected then
			CompletePending(record, false)
		end
	end
	reconciling = false
	-- A native cache update may acknowledge dozens of notes together. Paint
	-- each window once per poll, not once per acknowledged friend.
	if mainRefreshPending then mainRefreshPending = false; NoteCleanupWizard:RefreshRows(snapshot) end
	if backupRefreshPending then backupRefreshPending = false; NoteCleanupWizard:RefreshBackupRows(snapshot) end
end

local function SchedulePendingCheck()
	if pendingTimer or not next(pendingWrites) then return end
	local timer = C_Timer.NewTimer(1, function()
		pendingTimer = nil
		ReconcilePending()
		SchedulePendingCheck()
	end)
	pendingTimer = timer
end

local function PendingCount(kind)
	local count = 0
	for _, record in pairs(pendingWrites) do if not kind or record.kind == kind then count = count + 1 end end
	return count
end

function NoteCleanupWizard:IsBusy()
	return isApplying or isRestoring or next(pendingWrites) ~= nil, PendingCount()
end

function NoteCleanupWizard:GetOperationStatus(kind)
	local status = { total = 0, confirmed = 0, queued = 0, waiting = 0, unconfirmed = 0 }
	for _, data in pairs(kind == "restore" and (restoreOperationRows or backupFilteredData) or friendData) do
		if data.status then
			status.total = status.total + 1
			if data.status == "success" then status.confirmed = status.confirmed + 1
			elseif data.status == "queued" then status.queued = status.queued + 1
			elseif data.status == "pending" then status.waiting = status.waiting + 1
			else status.unconfirmed = status.unconfirmed + 1 end
		end
	end
	return status
end

RefreshButtons = function()
	local busy = isApplying or isRestoring
	if wizardFrame then
		if wizardFrame.backupButton then wizardFrame.backupButton:SetEnabled(not busy) end
		if wizardFrame.applyButton then wizardFrame.applyButton:SetEnabled(not busy and PendingCount("restore") == 0) end
		if wizardFrame.stopButton then wizardFrame.stopButton:SetShown(busy or PendingCount() > 0) end
	end
	if backupViewerFrame then
		if backupViewerFrame.backupButton then backupViewerFrame.backupButton:SetEnabled(not busy) end
		if backupViewerFrame.restoreButton then backupViewerFrame.restoreButton:SetEnabled(not busy and PendingCount("cleanup") == 0) end
		if backupViewerFrame.stopButton then backupViewerFrame.stopButton:SetShown(busy or PendingCount() > 0) end
	end
end

function NoteCleanupWizard:Stop()
	operationVersion = operationVersion + 1
	isApplying, isRestoring = false, false
	if pendingTimer then pendingTimer:Cancel(); pendingTimer = nil end
	pendingWrites = {}
	for _, collection in ipairs({ friendData, backupFilteredData, restoreOperationRows or {} }) do
		for _, data in pairs(collection) do
			if data.status == "queued" or data.status == "pending" then data.status = "stopped" end
		end
	end
	self:RefreshRows()
	self:RefreshBackupRows()
	Report(L.WIZARD_STOPPED)
end

local function ReportPending(count)
	Report(string.format(L.WIZARD_NOTES_PENDING, count))
end

-- Submission is separate from acknowledgement. Slow cache updates stay pending;
-- they are never turned into failures by an arbitrary two-second timeout.
local function WriteEntry(entry, key, note, expected, kind, callback)
	-- Recheck queued writes if the user enables sync after confirmation.
	if IsSyncEnabled() then callback(false); return end
	local snapshot = SnapshotNotes()
	local info, _, identity = ResolveEntry(entry, key, snapshot)
	if not info then callback(false); return end
	local uid, now = WriteKey(entry, key), GetTime()
	local record = pendingWrites[uid]
	if record then
		if record.note ~= note or record.kind ~= kind then callback(false); return end
		record.callbacks[#record.callbacks + 1] = callback
		-- Repeated clicks only subscribe to the existing delivery, never resend it.
		return
	end
	local success, reason = SubmitEntry(entry, key, note, expected, snapshot)
	if success or (reason ~= "pending" and reason ~= "blocked") then callback(success)
	else
		local active = FriendNotes.GetAcceptedWrite(uid)
		pendingWrites[uid] = { uid = uid, entry = entry, key = key, note = note, expected = expected,
			kind = kind, submittedAt = now, callbacks = { callback },
			waitingOn = active and active.note ~= note and active or nil }
	end
	SchedulePendingCheck()
end

-- ========================================
-- Helper: Get streamer-safe display name
-- ========================================
local function GetStreamerSafeAccountName(data)
	if not (BFL.StreamerMode and BFL.StreamerMode:IsActive()) then
		return data.accountName
	end

	-- In Streamer Mode, never show the Real ID (accountName)
	local mode = BetterFriendlistDB and BetterFriendlistDB.streamerModeNameFormat or "battletag"

	-- Default safe name: BattleTag (short, without #number)
	local safeName
	if data.battleTag and data.battleTag ~= "" then
		safeName = data.battleTag:match("([^#]+)") or data.battleTag
	elseif not data.isBNet then
		-- WoW-only friends: character name is safe
		safeName = data.characterName or data.accountName
	else
		safeName = "Unknown"
	end

	if mode == "note" then
		local note = data.originalNote or data.backedUpNote or ""
		if note ~= "" then
			safeName = note
		end
	end

	return safeName
end

-- ========================================
-- Helper: Parse FriendGroups note
-- ========================================
local function ParseFriendGroupsNote(noteText, friendUID)
	local NoteSync = BFL:GetModule("NoteSync")
	if NoteSync and NoteSync.ParseNoteGroups then
		return NoteSync:ParseNoteGroups(noteText, friendUID)
	end
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

-- ========================================
-- Helper: Check if note has FriendGroups data
-- ========================================
local function NoteHasGroups(noteText)
	if not noteText or noteText == "" then
		return false
	end
	return noteText:find("#") ~= nil
end

local function RefreshCurrentRows(snapshot)
	for _, data in ipairs(friendData) do
		local current = ReadEntry(data, data.characterName, snapshot)
		local active = FriendNotes.GetAcceptedWrite(WriteKey(data, data.characterName))
		if current ~= nil and current ~= data.originalNote then
			local automatic = data.cleanedNote == ParseFriendGroupsNote(data.originalNote, data.backupKey)
			local cleaned, groups = ParseFriendGroupsNote(current, data.backupKey)
			data.originalNote, data.groups, data.hasGroups, data.status = current, groups, #groups > 0, nil
			if automatic then data.cleanedNote = cleaned end
		end
	end
end

-- ========================================
-- Scan all BNet friends
-- ========================================
function NoteCleanupWizard:ScanFriends()
	-- Reopening either window must not release the lock on an in-flight write.
	if isApplying or isRestoring or next(pendingWrites) then return false end
	friendData = {}
	local bnetFriends, bnetComplete, bnetTotal = FriendNotes.GetBNetFriends()
	local wowFriends, wowComplete, wowTotal = FriendNotes.GetWoWFriends()
	scanTotal = bnetTotal + wowTotal
	scanComplete = bnetComplete and wowComplete
	for _, account in ipairs(bnetFriends) do
		if not (BFL.TitleFriendNotes and BFL.TitleFriendNotes:ManagesAccount(account)) then
			local uid = FriendNotes.GetBNetUID(account)
			local noteText = account.note or ""
			local actualNote, groups = ParseFriendGroupsNote(noteText, uid)
			local tag = IsText(account.battleTag) and account.battleTag or ""
			local game = account.gameAccountInfo
			local characterName = FriendNotes.IsReadableTable(game) and SafeLabel(game.characterName) or L.UNKNOWN
			friendData[#friendData + 1] = {
				accountName = SafeLabel(account.accountName, tag ~= "" and tag or characterName),
				battleTag = tag,
				identity = FriendNotes.CreateBNetIdentity(account),
				backupKey = uid,
				originalNote = noteText,
				cleanedNote = actualNote,
				groups = groups,
				hasGroups = #groups > 0,
				isBNet = true,
			}
		end
	end
	for _, info in ipairs(wowFriends) do
		local noteText = info.notes or ""
		local actualNote, groups = ParseFriendGroupsNote(noteText, "wow_" .. info.name)
		friendData[#friendData + 1] = {
			accountName = info.name,
			battleTag = "",
			characterName = info.name,
			guid = not BFL:IsSecret(info.guid) and IsText(info.guid) and info.guid ~= "" and info.guid or nil,
			backupKey = "wow_" .. info.name,
			originalNote = noteText,
			cleanedNote = actualNote,
			groups = groups,
			hasGroups = #groups > 0,
			isBNet = false,
		}
	end

	self:ApplyFilter()
end

-- ========================================
-- Filter friends by search text
-- ========================================
function NoteCleanupWizard:ApplyFilter()
	filteredData = {}
	local query = searchText:lower()

	for _, data in ipairs(friendData) do
		if query == "" then
			table.insert(filteredData, data)
		else
			local displayName = GetStreamerSafeAccountName(data)
			local matchName = displayName:lower():find(query, 1, true)
			local matchTag = data.battleTag:lower():find(query, 1, true)
			local matchNote = data.originalNote:lower():find(query, 1, true)
			local matchCleaned = data.cleanedNote:lower():find(query, 1, true)
			if matchName or matchTag or matchNote or matchCleaned then
				table.insert(filteredData, data)
			end
		end
	end

	self:RefreshRows()
end

-- ========================================
-- Backup notes to DB
-- ========================================
function NoteCleanupWizard:BackupNotes()
	if not BetterFriendlistDB or isApplying or isRestoring then return false, 0, scanTotal end
	local snapshot = SnapshotNotes()
	ReconcilePending(snapshot)
	RefreshCurrentRows(snapshot)
	scanTotal, scanComplete = snapshot.total, snapshot.complete

	local backup = {}
	local count = 0
	local previous = BetterFriendlistDB.noteBackup
	for _, data in ipairs(friendData) do
		local current = ReadEntry(data, data.characterName, snapshot)
		local key = data.backupKey
		if current ~= nil and current == data.originalNote and not backup[key] then
			local protected = protectedBackups[key]
			if protected and FriendNotes.IsReadableTable(previous) and previous[key] == protected.entry
				and (current == protected.entry.originalNote
					or (data.cleanedNote == current and (current == protected.lastApplied or current == protected.lastSubmitted)))
			then
				-- Retrying a partial cleanup must not replace its recovery copy with
				-- notes already cleaned by this same operation.
				backup[key] = protected.entry
			else
				protectedBackups[key] = nil
				backup[key] = {
					originalNote = data.originalNote,
					accountName = data.accountName,
					battleTag = data.battleTag,
					isBNet = data.isBNet,
					identity = data.identity,
					characterName = data.characterName,
					guid = data.guid,
					timestamp = time(),
				}
			end
			count = count + 1
		end
	end

	local complete = scanComplete and count == scanTotal
	-- An unreadable roster must not erase an earlier, recoverable snapshot.
	if not complete and FriendNotes.IsReadableTable(previous) then
		for key, entry in pairs(previous) do
			if IsText(key) and not backup[key] and FriendNotes.IsReadableTable(entry)
				and IsText(entry.originalNote) and not BFL:IsSecret(entry.isBNet) and type(entry.isBNet) == "boolean"
			then
				local canonicalKey
				if entry.isBNet and IsText(entry.battleTag) and entry.battleTag ~= "" then
					canonicalKey = "bnet_" .. entry.battleTag
				elseif not entry.isBNet then
					canonicalKey = "wow_" .. (IsText(entry.characterName) and entry.characterName or key)
				end
				if not canonicalKey or not backup[canonicalKey] then backup[key] = entry end
			end
		end
	end
	BetterFriendlistDB.noteBackup = backup
	if PendingCount("restore") == 0 then restoreOperationRows = nil end
	self:RefreshRows()
	Report(complete and string.format(L.WIZARD_BACKUP_SUCCESS, count)
		or string.format(L.WIZARD_BACKUP_PARTIAL, count, scanTotal))
	return complete, count, scanTotal
end

-- ========================================
-- Apply cleaned notes
-- ========================================
function NoteCleanupWizard:ApplyCleanedNotes()
	if isApplying or isRestoring then return false end
	if IsSyncEnabled() then
		Report(L.WIZARD_SYNC_ENABLED)
		return false
	end
	if PendingCount("restore") > 0 then ReportPending(PendingCount("restore")); return false end
	local snapshot = SnapshotNotes()
	ReconcilePending(snapshot)
	local backup = BetterFriendlistDB and BetterFriendlistDB.noteBackup

	-- Collect entries that need updating and mark as pending
	local toUpdate = {}
	for _, data in ipairs(friendData) do
		local current = ReadEntry(data, data.characterName, snapshot)
		local uid = WriteKey(data, data.characterName)
		if uid and uid:match("^bnet_%d+$") then
			data.cleanedNote = FriendNotes.PreserveTitleGroupToken(current, data.cleanedNote)
		end
		-- A delayed acknowledgement may arrive between batches or while the
		-- window is idle. Already-applied changes need no new backup or write.
		if current == data.cleanedNote and not active then
			data.originalNote = current
			data.groups = select(2, ParseFriendGroupsNote(current, data.backupKey))
			data.hasGroups = #data.groups > 0
		end
		if data.originalNote ~= data.cleanedNote or (active and active.note ~= data.cleanedNote) then
			local saved = FriendNotes.IsReadableTable(backup) and backup[data.backupKey]
			local protected = protectedBackups[data.backupKey]
			local pending = pendingWrites[WriteKey(data, data.characterName)]
			local NoteSync = BFL:GetModule("NoteSync")
			if BetterFriendlistDB.syncGroupsToNote and NoteSync and NoteSync.waitingForWizard and not pending then
				ReportPending(PendingCount()); return false
			end
			if pending and pending.note ~= data.cleanedNote then ReportPending(PendingCount()); return false end
			if not FriendNotes.IsReadableTable(saved) or not IsText(saved.originalNote)
				or (saved.originalNote ~= data.originalNote and not (protected and protected.entry == saved and protected.lastApplied == data.originalNote))
				or current ~= data.originalNote or ReadEntry(saved, data.characterName, snapshot) ~= data.originalNote
			then
				Report(L.WIZARD_BACKUP_REQUIRED)
				return false
			end
			protectedBackups[data.backupKey] = protected and protected.entry == saved and protected or { entry = saved }
			data.status = "queued"
			table.insert(toUpdate, data)
		else
			data.status = nil
		end
	end

	if #toUpdate == 0 then
		self:RefreshRows()
		return
	end

	isApplying = true
	operationVersion = operationVersion + 1
	local version = operationVersion
	self:RefreshRows()

	local currentIndex = 0
	local successCount = 0
	local errorCount = 0
	local remaining, dispatchFinished, reported = #toUpdate, false, false
	local function ReportFinished()
		if not dispatchFinished or remaining > 0 or reported then return end
		reported = true
		Report(errorCount > 0 and string.format(L.WIZARD_APPLY_FAILED, successCount, errorCount)
			or string.format(L.WIZARD_APPLY_SUCCESS, successCount))
	end

	local function ProcessNext()
		if not isApplying or version ~= operationVersion then
			return
		end

		currentIndex = currentIndex + 1
		if currentIndex > #toUpdate then
			isApplying = false
			dispatchFinished = true
			NoteCleanupWizard:RefreshRows()
			if remaining > 0 then ReportPending(remaining) else ReportFinished() end
			return
		end

		local data = toUpdate[currentIndex]
		data.status = "pending"
		local target = data.cleanedNote
		protectedBackups[data.backupKey].lastSubmitted = target
		local completed = false
		WriteEntry(data, data.characterName, target, data.originalNote, "cleanup", function(success)
			if version ~= operationVersion then return end
			completed = true
			if success then
				data.status = "success"
				data.originalNote = target
				data.groups = select(2, ParseFriendGroupsNote(target, data.backupKey))
				data.hasGroups = #data.groups > 0
				local protected = protectedBackups[data.backupKey]
				if protected then protected.lastApplied = target end
				successCount = successCount + 1
			else
				data.status = "error"
				errorCount = errorCount + 1
			end
			remaining = remaining - 1
			NoteCleanupWizard:RefreshRows()
			ReportFinished()
		end)
		if not completed then NoteCleanupWizard:RefreshRows() end
		C_Timer.After(WRITE_INTERVAL, ProcessNext)
	end

	-- Start processing after brief delay to show pending state
	C_Timer.After(0.1, ProcessNext)
end

-- ========================================
-- Create a single table row
-- ========================================
local function CreateRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)

	-- Alternating background
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()

	-- Status icon (pending/success/error)
	row.statusIcon = row:CreateTexture(nil, "ARTWORK")
	row.statusIcon:SetSize(16, 16)
	row.statusIcon:Hide()

	local contentWidth = parent:GetWidth()

	-- Account Name column
	row.accountName = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.accountName:SetJustifyH("LEFT")
	row.accountName:SetWordWrap(false)

	-- BattleTag column
	row.battleTag = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.battleTag:SetJustifyH("LEFT")
	row.battleTag:SetWordWrap(false)

	-- Original Note column
	row.noteText = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.noteText:SetJustifyH("LEFT")
	row.noteText:SetWordWrap(false)

	-- Cleaned Note (EditBox)
	row.cleanedInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	row.cleanedInput:SetAutoFocus(false)
	row.cleanedInput:SetHeight(18)
	row.cleanedInput:SetFontObject("BetterFriendlistFontHighlightSmall")

	row.cleanedInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	row.cleanedInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)

	return row
end

-- ========================================
-- Layout a row with column widths
-- ========================================
local function LayoutRow(row, contentWidth)
	local availWidth = contentWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availWidth * COL_ACCOUNT)
	local colW2 = math.floor(availWidth * COL_BATTLETAG)
	local colW3 = math.floor(availWidth * COL_NOTE)

	-- Status icon at far left
	row.statusIcon:ClearAllPoints()
	row.statusIcon:SetPoint("LEFT", row, "LEFT", (STATUS_COL_WIDTH - 16) / 2, 0)

	local offset = STATUS_COL_WIDTH

	row.accountName:ClearAllPoints()
	row.accountName:SetPoint("LEFT", row, "LEFT", offset + COLUMN_PADDING, 0)
	row.accountName:SetWidth(colW1 - COLUMN_PADDING * 2)

	row.battleTag:ClearAllPoints()
	row.battleTag:SetPoint("LEFT", row, "LEFT", offset + colW1 + COLUMN_PADDING, 0)
	row.battleTag:SetWidth(colW2 - COLUMN_PADDING * 2)

	row.noteText:ClearAllPoints()
	row.noteText:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + COLUMN_PADDING, 0)
	row.noteText:SetWidth(colW3 - COLUMN_PADDING * 2)

	row.cleanedInput:ClearAllPoints()
	row.cleanedInput:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	row.cleanedInput:SetPoint("RIGHT", row, "RIGHT", -COLUMN_PADDING, 0)
end

-- ========================================
-- Refresh visible rows
-- ========================================
function NoteCleanupWizard:RefreshRows(snapshot)
	if reconciling then mainRefreshPending = true; return end
	RefreshButtons()
	if not wizardFrame then
		return
	end

	local scrollChild = wizardFrame.scrollChild
	if not scrollChild then
		return
	end

	local contentWidth = scrollChild:GetWidth()

	-- Hide all existing rows
	for _, row in ipairs(rowFrames) do
		row:Hide()
	end

	-- Create/reuse rows for filtered data
	for i, data in ipairs(filteredData) do
		local row = rowFrames[i]
		if not row then
			row = CreateRow(scrollChild, i)
			rowFrames[i] = row
		end

		-- Position
		row:ClearAllPoints()
		row:SetPoint("LEFT", scrollChild, "LEFT", 0, 0)
		row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

		if i == 1 then
			row:SetPoint("TOP", scrollChild, "TOP", 0, 0)
		else
			row:SetPoint("TOP", rowFrames[i - 1], "BOTTOM", 0, 0)
		end

		-- Background color based on status (traffic light system)
		if data.status == "success" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.05, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.04, 0.20, 0.04, 0.4)
			end
		elseif data.status == "error" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.05, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.04, 0.04, 0.4)
			end
		elseif data.status == "pending" or data.status == "queued" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.20, 0.04, 0.4)
			end
		elseif data.hasGroups then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.2, 0.15, 0.05, 0.5)
			else
				row.bg:SetColorTexture(0.18, 0.12, 0.03, 0.3)
			end
		else
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
			else
				row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
			end
		end

		-- Status icon
		if data.status == "pending" or data.status == "queued" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
			row.statusIcon:Show()
		elseif data.status == "success" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			row.statusIcon:Show()
		elseif data.status == "error" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
			row.statusIcon:Show()
		else
			row.statusIcon:Hide()
		end

		LayoutRow(row, contentWidth)

		-- Set data (respect Streamer Mode for account names)
		row.accountName:SetText(GetStreamerSafeAccountName(data))
		row.battleTag:SetText(data.battleTag)

		-- Color original note: highlight the #groups part in orange
		if data.hasGroups then
			local actualNote, _ = ParseFriendGroupsNote(data.originalNote, data.backupKey)
			local groupPart = data.originalNote:sub(#actualNote + 1)
			row.noteText:SetText(actualNote .. "|cffff8800" .. groupPart .. "|r")
		else
			row.noteText:SetText(data.originalNote)
		end

		-- Set cleaned note input
		row.cleanedInput:SetMaxLetters(data.isBNet and 127 or 48)
		row.cleanedInput:SetCountInvisibleLetters(true)
		row.cleanedInput:SetText(data.cleanedNote)

		-- Store reference to data for the EditBox callback
		row.cleanedInput.dataRef = data
		row.cleanedInput:SetScript("OnTextChanged", function(self, userInput)
			if userInput and self.dataRef then
				self.dataRef.cleanedNote = self:GetText()
			end
		end)

		row:Show()
	end

	-- Update scroll child height
	local totalHeight = #filteredData * ROW_HEIGHT
	scrollChild:SetHeight(math.max(totalHeight, 1))

	-- Update count label
	if wizardFrame.countLabel then
		-- Check if apply progress should be shown
		local status = self:GetOperationStatus("cleanup")
		if status.total > 0 then
			wizardFrame.countLabel:SetText(
				string.format(
					L.WIZARD_OPERATION_STATUS,
					status.confirmed, status.total, status.queued, status.waiting, status.unconfirmed
				)
			)
		else
			local totalWithGroups = 0
			local totalChanged = 0
			for _, data in ipairs(friendData) do
				if data.hasGroups then
					totalWithGroups = totalWithGroups + 1
				end
				if data.originalNote ~= data.cleanedNote then
					totalChanged = totalChanged + 1
				end
			end
			wizardFrame.countLabel:SetText(
				string.format(L.WIZARD_STATUS_FMT, #filteredData, #friendData, totalWithGroups, totalChanged)
			)
		end
	end
end

-- ========================================
-- Create the Wizard Frame
-- ========================================
local function AddStopButton(frame, bottomBar, countLabel)
	local button = CreateFrame("Button", nil, bottomBar, "UIPanelButtonTemplate")
	button:SetSize(80, 22)
	button:SetPoint("RIGHT", bottomBar, "RIGHT", -2, 0)
	button:SetText(L.WIZARD_STOP_BTN)
	button:SetScript("OnClick", function() NoteCleanupWizard:Stop() end)
	button:Hide()
	frame.stopButton = button
	countLabel:SetPoint("RIGHT", button, "LEFT", -8, 0)
end

function NoteCleanupWizard:CreateWizardFrame()
	if wizardFrame then
		return wizardFrame
	end

	-- Main frame
	local frame = CreateFrame("Frame", "BetterFriendlistNoteCleanupWizard", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIZARD_WIDTH, WIZARD_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)

	-- Allow dragging
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Title
	frame:SetTitle(L.WIZARD_TITLE)

	-- Close button
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end

	-- Portrait icon
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	elseif frame.portrait then
		frame.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	end

	-- ========================================
	-- Description
	-- ========================================
	local descText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	descText:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -32)
	descText:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
	descText:SetJustifyH("LEFT")
	descText:SetWordWrap(true)
	descText:SetText(L.WIZARD_DESC)
	frame.descText = descText

	-- ========================================
	-- Top Bar: Search + Buttons
	-- ========================================
	local topBar = CreateFrame("Frame", nil, frame)
	topBar:SetHeight(30)
	topBar:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 8, -8)
	topBar:SetPoint("TOPRIGHT", frame.Inset or frame, "TOPRIGHT", -8, -8)
	frame.topBar = topBar

	-- Search box
	local searchBox = CreateFrame("EditBox", nil, topBar, "SearchBoxTemplate")
	searchBox:SetSize(200, 22)
	searchBox:SetPoint("LEFT", topBar, "LEFT", 4, 0)
	searchBox:SetAutoFocus(false)
	frame.searchBox = searchBox

	if searchBox.Instructions then
		searchBox.Instructions:SetText(L.WIZARD_SEARCH_PLACEHOLDER)
	end

	searchBox:SetScript("OnTextChanged", function(self, userInput)
		if SearchBoxTemplate_OnTextChanged then
			SearchBoxTemplate_OnTextChanged(self)
		end
		searchText = self:GetText() or ""
		NoteCleanupWizard:ApplyFilter()
	end)

	-- Backup button
	local backupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	backupBtn:SetSize(140, 24)
	backupBtn:SetText(L.WIZARD_BACKUP_BTN)
	backupBtn:SetPoint("RIGHT", topBar, "RIGHT", 0, 0)
	frame.backupButton = backupBtn
	if backupBtn.SetNormalFontObject then
		backupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	backupBtn:SetScript("OnClick", function()
		local complete = NoteCleanupWizard:BackupNotes()
		-- Visual feedback
		if complete then backupBtn:SetText("|cff00ff00" .. L.WIZARD_BACKUP_DONE .. "|r") end
		C_Timer.After(2, function()
			if backupBtn and backupBtn:IsShown() then
				backupBtn:SetText(L.WIZARD_BACKUP_BTN)
			end
		end)
	end)

	backupBtn:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.WIZARD_BACKUP_BTN, 1, 1, 1)
		BFL_Tooltip:AddLine(L.WIZARD_BACKUP_TOOLTIP, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	backupBtn:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- View Backup button
	local viewBackupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	viewBackupBtn:SetSize(140, 24)
	viewBackupBtn:SetText(L.WIZARD_VIEW_BACKUP_BTN)
	viewBackupBtn:SetPoint("RIGHT", backupBtn, "LEFT", -8, 0)
	frame.viewBackupButton = viewBackupBtn
	if viewBackupBtn.SetNormalFontObject then
		viewBackupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	viewBackupBtn:SetScript("OnClick", function()
		NoteCleanupWizard:ShowBackupViewer()
	end)

	viewBackupBtn:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.WIZARD_VIEW_BACKUP_BTN, 1, 1, 1)
		BFL_Tooltip:AddLine(L.WIZARD_VIEW_BACKUP_TOOLTIP, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	viewBackupBtn:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- Apply button
	local applyBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	applyBtn:SetSize(140, 24)
	applyBtn:SetText(L.WIZARD_APPLY_BTN)
	applyBtn:SetPoint("RIGHT", viewBackupBtn, "LEFT", -8, 0)
	frame.applyButton = applyBtn
	if applyBtn.SetNormalFontObject then
		applyBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	applyBtn:SetScript("OnClick", function()
		-- Show confirmation dialog
		StaticPopupDialogs["BETTERFRIENDLIST_NOTE_CLEANUP_CONFIRM"] = {
			text = L.WIZARD_APPLY_CONFIRM,
			button1 = L.WIZARD_APPLY_BTN,
			button2 = L.BUTTON_CANCEL or "Cancel",
			OnAccept = function()
				NoteCleanupWizard:ApplyCleanedNotes()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NOTE_CLEANUP_CONFIRM")
	end)

	applyBtn:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.WIZARD_APPLY_BTN, 1, 1, 1)
		BFL_Tooltip:AddLine(L.WIZARD_APPLY_TOOLTIP, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	applyBtn:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- ========================================
	-- Column Headers
	-- ========================================
	local headerBar = CreateFrame("Frame", nil, frame)
	headerBar:SetHeight(HEADER_HEIGHT)
	headerBar:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
	headerBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)
	frame.headerBar = headerBar

	headerBar.bg = headerBar:CreateTexture(nil, "BACKGROUND")
	headerBar.bg:SetAllPoints()
	headerBar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

	local headerWidth = WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH
	local availHeaderWidth = headerWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availHeaderWidth * COL_ACCOUNT)
	local colW2 = math.floor(availHeaderWidth * COL_BATTLETAG)
	local colW3 = math.floor(availHeaderWidth * COL_NOTE)

	local h1 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h1:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + COLUMN_PADDING, 0)
	h1:SetText(L.WIZARD_COL_ACCOUNT)
	h1:SetJustifyH("LEFT")

	local h2 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h2:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + COLUMN_PADDING, 0)
	h2:SetText(L.WIZARD_COL_BATTLETAG)
	h2:SetJustifyH("LEFT")

	local h3 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h3:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + COLUMN_PADDING, 0)
	h3:SetText(L.WIZARD_COL_NOTE)
	h3:SetJustifyH("LEFT")

	local h4 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h4:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	h4:SetText(L.WIZARD_COL_CLEANED)
	h4:SetJustifyH("LEFT")
	frame.headerLabels = { h1, h2, h3, h4 }

	-- ========================================
	-- Scroll Frame for the table
	-- ========================================
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -SCROLL_BAR_WIDTH - 8, 36)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() or (WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH))
	scrollChild:SetHeight(1) -- Will be updated dynamically
	scrollFrame:SetScrollChild(scrollChild)

	frame.scrollChild = scrollChild
	frame.scrollFrame = scrollFrame
	frame.rowFrames = rowFrames

	-- Update scrollChild width when frame resizes
	scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
		scrollChild:SetWidth(width)
		NoteCleanupWizard:RefreshRows()
	end)

	-- ========================================
	-- Bottom Bar: Status
	-- ========================================
	local bottomBar = CreateFrame("Frame", nil, frame)
	bottomBar:SetHeight(28)
	bottomBar:SetPoint("BOTTOMLEFT", frame.Inset or frame, "BOTTOMLEFT", 8, 4)
	bottomBar:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -8, 4)
	frame.bottomBar = bottomBar

	local countLabel = bottomBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	countLabel:SetPoint("LEFT", bottomBar, "LEFT", 4, 0)
	countLabel:SetJustifyH("LEFT")
	frame.countLabel = countLabel
	AddStopButton(frame, bottomBar, countLabel)

	wizardFrame = frame
	frame:Hide()

	return frame
end

-- ========================================
-- Get backup data as sorted array
-- ========================================
function NoteCleanupWizard:GetBackupData(snapshot)
	local data = {}
	local backup = BetterFriendlistDB and BetterFriendlistDB.noteBackup
	if not FriendNotes.IsReadableTable(backup) then return data end
	if not snapshot then snapshot = SnapshotNotes(); ReconcilePending(snapshot) end

	for key, entry in pairs(backup) do
		if IsText(key) and FriendNotes.IsReadableTable(entry) and not BFL:IsSecret(entry.isBNet)
			and type(entry.isBNet) == "boolean" and IsText(entry.originalNote)
		then
			local current = ReadEntry(entry, key, snapshot)
			local tag = IsText(entry.battleTag) and entry.battleTag or ""
			local timestamp = not BFL:IsSecret(entry.timestamp) and type(entry.timestamp) == "number" and entry.timestamp or 0
			local operation = restoreOperationRows and restoreOperationRows[key]
			data[#data + 1] = {
				key = key,
				backupEntry = entry,
				accountName = SafeLabel(entry.accountName, tag ~= "" and tag or SafeLabel(entry.characterName)),
				battleTag = tag,
				characterName = IsText(entry.characterName) and entry.characterName or nil,
				backedUpNote = entry.originalNote,
				currentNote = current or L.WIZARD_NOTE_UNAVAILABLE,
				available = current ~= nil,
				isBNet = entry.isBNet,
				timestamp = timestamp,
				noteChanged = current == nil or current ~= entry.originalNote or FriendNotes.GetAcceptedWrite(WriteKey(entry, key)) ~= nil,
				status = pendingWrites[WriteKey(entry, key)] and "pending" or (operation and operation.status),
			}
		end
	end
	table.sort(data, function(a, b) return a.accountName:lower() < b.accountName:lower() end)
	return data
end

-- ========================================
-- Apply backup filter
-- ========================================
function NoteCleanupWizard:ApplyBackupFilter()
	local allData = self:GetBackupData()
	backupFilteredData = {}
	local query = backupSearchText:lower()

	for _, entry in ipairs(allData) do
		if query == "" then
			table.insert(backupFilteredData, entry)
		else
			local displayName = GetStreamerSafeAccountName(entry)
			local matchName = displayName:lower():find(query, 1, true)
			local matchTag = entry.battleTag:lower():find(query, 1, true)
			local matchBackup = entry.backedUpNote:lower():find(query, 1, true)
			local matchCurrent = entry.currentNote:lower():find(query, 1, true)
			if matchName or matchTag or matchBackup or matchCurrent then
				table.insert(backupFilteredData, entry)
			end
		end
	end

	self:RefreshBackupRows()
end

-- ========================================
-- Restore notes from backup (sequential with status icons)
-- ========================================
function NoteCleanupWizard:RestoreBackup()
	if isRestoring or isApplying then return false end
	if IsSyncEnabled() then
		Report(L.WIZARD_SYNC_ENABLED)
		return false
	end
	ReconcilePending()
	if PendingCount("cleanup") > 0 then ReportPending(PendingCount("cleanup")); return false end

	if not BetterFriendlistDB or not BetterFriendlistDB.noteBackup then
		return
	end
	self:ApplyBackupFilter()

	-- Collect entries that need restoring and mark as pending
	local toRestore = {}
	if PendingCount("restore") == 0 then restoreOperationRows = {} end
	for _, data in ipairs(backupFilteredData) do
		if data.noteChanged then
			data.status = "queued"
			local existing = restoreOperationRows[data.key]
			if not existing or (existing.status ~= "pending" and existing.status ~= "queued") then
				restoreOperationRows[data.key] = data
			end
			table.insert(toRestore, data)
		else
			data.status = nil
		end
	end

	if #toRestore == 0 then
		self:RefreshBackupRows()
		return
	end

	isRestoring = true
	operationVersion = operationVersion + 1
	local version = operationVersion
	self:RefreshBackupRows()

	local currentIndex = 0
	local successCount = 0
	local errorCount = 0
	local remaining, dispatchFinished, reported = #toRestore, false, false
	local function ReportFinished()
		if not dispatchFinished or remaining > 0 or reported then return end
		reported = true
		Report(errorCount > 0 and string.format(L.WIZARD_RESTORE_FAILED, successCount, errorCount)
			or string.format(L.WIZARD_RESTORE_SUCCESS, successCount))
	end

	local function ProcessNext()
		if not isRestoring or version ~= operationVersion then
			return
		end

		currentIndex = currentIndex + 1
		if currentIndex > #toRestore then
			isRestoring = false
			dispatchFinished = true
			NoteCleanupWizard:RefreshBackupRows()
			if remaining > 0 then ReportPending(remaining) else ReportFinished() end
			-- Refresh main wizard if open
			C_Timer.After(0.3, function()
				if wizardFrame and wizardFrame:IsShown() then
					NoteCleanupWizard:ScanFriends()
				end
			end)
			return
		end

		local data = toRestore[currentIndex]
		data.status = "pending"
		local restoredNote = data.backedUpNote
		local uid = data.available and WriteKey(data.backupEntry, data.key)
		if uid and uid:match("^bnet_%d+$") then
			restoredNote = FriendNotes.PreserveTitleGroupToken(data.currentNote, restoredNote)
		end
		local completed = false
		local function Complete(success)
			if version ~= operationVersion then return end
			completed = true
			if success then
				data.status = "success"
				data.currentNote = restoredNote
				data.noteChanged = false
				successCount = successCount + 1
			else
				data.status = "error"
				errorCount = errorCount + 1
			end
			remaining = remaining - 1
			-- Filtering/reopening may replace the visible row objects while an
			-- acknowledgement is in flight; update the matching current row too.
			local operation = restoreOperationRows and restoreOperationRows[data.key]
			if operation then
				operation.status = data.status
				if success then operation.currentNote, operation.noteChanged = restoredNote, false end
			end
			for _, visible in ipairs(backupFilteredData) do
				if visible.key == data.key then
					visible.status = data.status
					if success then visible.currentNote, visible.noteChanged = restoredNote, false end
				end
			end
			NoteCleanupWizard:RefreshBackupRows()
			ReportFinished()
		end
		if not data.available then
			Complete(false)
		else
			WriteEntry(data.backupEntry, data.key, restoredNote, data.currentNote, "restore", Complete)
		end
		if not completed then NoteCleanupWizard:RefreshBackupRows() end
		C_Timer.After(WRITE_INTERVAL, ProcessNext)
	end

	-- Start processing after brief delay to show pending state
	C_Timer.After(0.1, ProcessNext)
end

-- ========================================
-- Create a single backup viewer row
-- ========================================
local function CreateBackupRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)

	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()

	-- Status icon (pending/success/error)
	row.statusIcon = row:CreateTexture(nil, "ARTWORK")
	row.statusIcon:SetSize(16, 16)
	row.statusIcon:Hide()

	-- Account Name column
	row.accountName = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.accountName:SetJustifyH("LEFT")
	row.accountName:SetWordWrap(false)

	-- BattleTag column
	row.battleTag = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.battleTag:SetJustifyH("LEFT")
	row.battleTag:SetWordWrap(false)

	-- Backed Up Note column
	row.backedUpNote = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.backedUpNote:SetJustifyH("LEFT")
	row.backedUpNote:SetWordWrap(false)

	-- Current Note column
	row.currentNote = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.currentNote:SetJustifyH("LEFT")
	row.currentNote:SetWordWrap(false)

	return row
end

-- Column widths for backup viewer
local BCOL_ACCOUNT = 0.20
local BCOL_BATTLETAG = 0.20
local BCOL_BACKUP = 0.30
local BCOL_CURRENT = 0.30

-- ========================================
-- Layout a backup viewer row
-- ========================================
local function LayoutBackupRow(row, contentWidth)
	local availWidth = contentWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availWidth * BCOL_ACCOUNT)
	local colW2 = math.floor(availWidth * BCOL_BATTLETAG)
	local colW3 = math.floor(availWidth * BCOL_BACKUP)

	-- Status icon at far left
	row.statusIcon:ClearAllPoints()
	row.statusIcon:SetPoint("LEFT", row, "LEFT", (STATUS_COL_WIDTH - 16) / 2, 0)

	local offset = STATUS_COL_WIDTH

	row.accountName:ClearAllPoints()
	row.accountName:SetPoint("LEFT", row, "LEFT", offset + COLUMN_PADDING, 0)
	row.accountName:SetWidth(colW1 - COLUMN_PADDING * 2)

	row.battleTag:ClearAllPoints()
	row.battleTag:SetPoint("LEFT", row, "LEFT", offset + colW1 + COLUMN_PADDING, 0)
	row.battleTag:SetWidth(colW2 - COLUMN_PADDING * 2)

	row.backedUpNote:ClearAllPoints()
	row.backedUpNote:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + COLUMN_PADDING, 0)
	row.backedUpNote:SetWidth(colW3 - COLUMN_PADDING * 2)

	row.currentNote:ClearAllPoints()
	row.currentNote:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	row.currentNote:SetPoint("RIGHT", row, "RIGHT", -COLUMN_PADDING, 0)
end

-- ========================================
-- Refresh backup viewer rows
-- ========================================
function NoteCleanupWizard:RefreshBackupRows(snapshot)
	if reconciling then backupRefreshPending = true; return end
	RefreshButtons()
	if not backupViewerFrame then
		return
	end

	local scrollChild = backupViewerFrame.scrollChild
	if not scrollChild then
		return
	end

	local contentWidth = scrollChild:GetWidth()

	-- Hide all existing rows
	for _, row in ipairs(backupRowFrames) do
		row:Hide()
	end

	-- Create/reuse rows for filtered data
	for i, data in ipairs(backupFilteredData) do
		local row = backupRowFrames[i]
		if not row then
			row = CreateBackupRow(scrollChild)
			backupRowFrames[i] = row
		end

		-- Position
		row:ClearAllPoints()
		row:SetPoint("LEFT", scrollChild, "LEFT", 0, 0)
		row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

		if i == 1 then
			row:SetPoint("TOP", scrollChild, "TOP", 0, 0)
		else
			row:SetPoint("TOP", backupRowFrames[i - 1], "BOTTOM", 0, 0)
		end

		-- Background color based on status (traffic light system)
		if data.status == "success" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.05, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.04, 0.20, 0.04, 0.4)
			end
		elseif data.status == "error" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.05, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.04, 0.04, 0.4)
			end
		elseif data.status == "pending" or data.status == "queued" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.20, 0.04, 0.4)
			end
		elseif data.noteChanged then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.1, 0.2, 0.1, 0.5)
			else
				row.bg:SetColorTexture(0.08, 0.18, 0.08, 0.3)
			end
		else
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
			else
				row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
			end
		end

		-- Status icon
		if data.status == "pending" or data.status == "queued" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
			row.statusIcon:Show()
		elseif data.status == "success" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			row.statusIcon:Show()
		elseif data.status == "error" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
			row.statusIcon:Show()
		else
			row.statusIcon:Hide()
		end

		LayoutBackupRow(row, contentWidth)

		-- Set data (respect Streamer Mode for account names)
		row.accountName:SetText(GetStreamerSafeAccountName(data))
		row.battleTag:SetText(data.battleTag)
		row.backedUpNote:SetText(data.backedUpNote)

		-- Highlight current note differently if it differs from backup
		if data.noteChanged then
			row.currentNote:SetText("|cffff8800" .. data.currentNote .. "|r")
		else
			row.currentNote:SetText(data.currentNote)
		end

		row:Show()
	end

	-- Update scroll child height
	local totalHeight = #backupFilteredData * ROW_HEIGHT
	scrollChild:SetHeight(math.max(totalHeight, 1))

	-- Update count label
	if backupViewerFrame.countLabel then
		local totalChanged = 0
		local allData = self:GetBackupData(snapshot)
		for _, entry in ipairs(allData) do
			if entry.noteChanged then
				totalChanged = totalChanged + 1
			end
		end

		-- Format the timestamp from most recent backup entry
		local latestTimestamp = 0
		for _, entry in ipairs(allData) do
			if entry.timestamp > latestTimestamp then latestTimestamp = entry.timestamp end
		end

		local timeStr = ""
		if latestTimestamp > 0 then
			timeStr = date("%Y-%m-%d %H:%M", latestTimestamp)
		end

		-- Check if restore progress should be shown
		local status = self:GetOperationStatus("restore")
		if status.total > 0 then
			backupViewerFrame.countLabel:SetText(
				string.format(L.WIZARD_OPERATION_STATUS, status.confirmed, status.total, status.queued, status.waiting, status.unconfirmed)
			)
		else
			backupViewerFrame.countLabel:SetText(
				string.format(L.WIZARD_BACKUP_STATUS_FMT, #backupFilteredData, #allData, totalChanged, timeStr)
			)
		end
	end
end

-- ========================================
-- Create the Backup Viewer Frame
-- ========================================
function NoteCleanupWizard:CreateBackupViewerFrame()
	if backupViewerFrame then
		return backupViewerFrame
	end

	local frame = CreateFrame("Frame", "BetterFriendlistNoteBackupViewer", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIZARD_WIDTH, WIZARD_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)

	-- Allow dragging
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Title
	frame:SetTitle(L.WIZARD_BACKUP_VIEWER_TITLE)

	-- Close button
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end

	-- Portrait icon
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	elseif frame.portrait then
		frame.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	end

	-- ========================================
	-- Description
	-- ========================================
	local descText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	descText:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -32)
	descText:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
	descText:SetJustifyH("LEFT")
	descText:SetWordWrap(true)
	descText:SetText(L.WIZARD_BACKUP_VIEWER_DESC)
	frame.descText = descText

	-- ========================================
	-- Top Bar: Search + Restore Button
	-- ========================================
	local topBar = CreateFrame("Frame", nil, frame)
	topBar:SetHeight(30)
	topBar:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 8, -8)
	topBar:SetPoint("TOPRIGHT", frame.Inset or frame, "TOPRIGHT", -8, -8)
	frame.topBar = topBar

	-- Search box
	local searchBox = CreateFrame("EditBox", nil, topBar, "SearchBoxTemplate")
	searchBox:SetSize(200, 22)
	searchBox:SetPoint("LEFT", topBar, "LEFT", 4, 0)
	searchBox:SetAutoFocus(false)
	frame.searchBox = searchBox

	if searchBox.Instructions then
		searchBox.Instructions:SetText(L.WIZARD_SEARCH_PLACEHOLDER)
	end

	searchBox:SetScript("OnTextChanged", function(self, userInput)
		if SearchBoxTemplate_OnTextChanged then
			SearchBoxTemplate_OnTextChanged(self)
		end
		backupSearchText = self:GetText() or ""
		NoteCleanupWizard:ApplyBackupFilter()
	end)

	-- Backup button (create new backup from Backup Viewer)
	local backupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	backupBtn:SetSize(140, 24)
	backupBtn:SetText(L.WIZARD_BACKUP_BTN)
	backupBtn:SetPoint("RIGHT", topBar, "RIGHT", 0, 0)
	frame.backupButton = backupBtn
	if backupBtn.SetNormalFontObject then
		backupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	backupBtn:SetScript("OnClick", function()
		-- Need to scan friends first to have data for backup
		NoteCleanupWizard:ScanFriends()
		local complete = NoteCleanupWizard:BackupNotes()
		-- Visual feedback
		if complete then backupBtn:SetText("|cff00ff00" .. L.WIZARD_BACKUP_DONE .. "|r") end
		C_Timer.After(2, function()
			if backupBtn and backupBtn:IsShown() then
				backupBtn:SetText(L.WIZARD_BACKUP_BTN)
			end
		end)
		-- Refresh backup viewer to show updated data
		C_Timer.After(0.5, function()
			if backupViewerFrame and backupViewerFrame:IsShown() then
				NoteCleanupWizard:ApplyBackupFilter()
			end
		end)
	end)

	backupBtn:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.WIZARD_BACKUP_BTN, 1, 1, 1)
		BFL_Tooltip:AddLine(L.WIZARD_BACKUP_TOOLTIP, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	backupBtn:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- Restore button
	local restoreBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	restoreBtn:SetSize(160, 24)
	restoreBtn:SetText(L.WIZARD_RESTORE_BTN)
	restoreBtn:SetPoint("RIGHT", backupBtn, "LEFT", -8, 0)
	frame.restoreButton = restoreBtn
	if restoreBtn.SetNormalFontObject then
		restoreBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	restoreBtn:SetScript("OnClick", function()
		StaticPopupDialogs["BETTERFRIENDLIST_NOTE_RESTORE_CONFIRM"] = {
			text = L.WIZARD_RESTORE_CONFIRM,
			button1 = L.WIZARD_RESTORE_BTN,
			button2 = L.BUTTON_CANCEL or "Cancel",
			OnAccept = function()
				NoteCleanupWizard:RestoreBackup()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NOTE_RESTORE_CONFIRM")
	end)

	restoreBtn:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.WIZARD_RESTORE_BTN, 1, 1, 1)
		BFL_Tooltip:AddLine(L.WIZARD_RESTORE_TOOLTIP, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	restoreBtn:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- ========================================
	-- Column Headers
	-- ========================================
	local headerBar = CreateFrame("Frame", nil, frame)
	headerBar:SetHeight(HEADER_HEIGHT)
	headerBar:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
	headerBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)
	frame.headerBar = headerBar

	headerBar.bg = headerBar:CreateTexture(nil, "BACKGROUND")
	headerBar.bg:SetAllPoints()
	headerBar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

	local headerWidth = WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH
	local availHeaderWidth = headerWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availHeaderWidth * BCOL_ACCOUNT)
	local colW2 = math.floor(availHeaderWidth * BCOL_BATTLETAG)
	local colW3 = math.floor(availHeaderWidth * BCOL_BACKUP)

	local h1 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h1:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + COLUMN_PADDING, 0)
	h1:SetText(L.WIZARD_COL_ACCOUNT)
	h1:SetJustifyH("LEFT")

	local h2 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h2:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + COLUMN_PADDING, 0)
	h2:SetText(L.WIZARD_COL_BATTLETAG)
	h2:SetJustifyH("LEFT")

	local h3 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h3:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + COLUMN_PADDING, 0)
	h3:SetText(L.WIZARD_COL_BACKED_UP)
	h3:SetJustifyH("LEFT")

	local h4 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h4:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	h4:SetText(L.WIZARD_COL_CURRENT)
	h4:SetJustifyH("LEFT")
	frame.headerLabels = { h1, h2, h3, h4 }

	-- ========================================
	-- Scroll Frame
	-- ========================================
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -SCROLL_BAR_WIDTH - 8, 36)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() or (WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH))
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	frame.scrollChild = scrollChild
	frame.scrollFrame = scrollFrame
	frame.rowFrames = backupRowFrames

	scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
		scrollChild:SetWidth(width)
		NoteCleanupWizard:RefreshBackupRows()
	end)

	-- ========================================
	-- Bottom Bar: Status
	-- ========================================
	local bottomBar = CreateFrame("Frame", nil, frame)
	bottomBar:SetHeight(28)
	bottomBar:SetPoint("BOTTOMLEFT", frame.Inset or frame, "BOTTOMLEFT", 8, 4)
	bottomBar:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -8, 4)
	frame.bottomBar = bottomBar

	local countLabel = bottomBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	countLabel:SetPoint("LEFT", bottomBar, "LEFT", 4, 0)
	countLabel:SetJustifyH("LEFT")
	frame.countLabel = countLabel
	AddStopButton(frame, bottomBar, countLabel)

	backupViewerFrame = frame
	frame:Hide()

	return frame
end

-- ========================================
-- Show the Backup Viewer
-- ========================================
function NoteCleanupWizard:ShowBackupViewer()
	if not BetterFriendlistDB or not FriendNotes.IsReadableTable(BetterFriendlistDB.noteBackup)
		or not next(BetterFriendlistDB.noteBackup)
	then
		-- No backup available - show message
		StaticPopupDialogs["BETTERFRIENDLIST_NO_BACKUP"] = {
			text = L.WIZARD_NO_BACKUP,
			button1 = OKAY or "OK",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NO_BACKUP")
		return
	end

	local frame = self:CreateBackupViewerFrame()
	self:ApplyBackupFilter()
	frame:Show()
end

-- ========================================
-- Show the Wizard
-- ========================================
function NoteCleanupWizard:Show()
	local frame = self:CreateWizardFrame()
	self:ScanFriends()
	frame:Show()
end

-- ========================================
-- Hide the Wizard
-- ========================================
function NoteCleanupWizard:Hide()
	if wizardFrame then
		wizardFrame:Hide()
	end
end
