-- Run from the repository root: lua tools/BFL-FriendNotesSmoke.lua [source root]
-- Exercises the real identity/write helpers and wizard without a WoW client.
local root = arg[1] or "."
local nativePrint = print
local checks = 0
local function Check(condition, message)
	assert(condition, message)
	checks = checks + 1
end

local function Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = Copy(item) end
	return result
end

local function Environment(backup)
	local env = { accounts = {
		{ bnetAccountID = 101, battleTag = "", friendLevel = 3, accountName = "Title Alice", note = "Alice#Raid",
			gameAccountInfo = { playerGuid = "Player-1-101", characterName = "Alice-Surname" } },
		{ bnetAccountID = 202, battleTag = "", friendLevel = 3, accountName = "Title Bob", note = "Bob#PvP",
			gameAccountInfo = { playerGuid = "Player-1-202", characterName = "Bob-Surname" } },
		{ bnetAccountID = 303, battleTag = "Friend#1234", friendLevel = 1, accountName = "|Kq123|k", note = "Tag#Raid" },
	}, wow = { { name = "Friend-Realm", guid = "Player-1-404", notes = "WoW#Raid" } },
		writes = {}, messages = {}, callbacks = {}, queue = {}, now = 0, mode = "normal" }
	local secret = setmetatable({}, { __index = function() error("secret value indexed") end })
	local secretTable = setmetatable({}, { __index = function() error("secret table indexed") end,
		__pairs = function() error("secret table iterated") end })
	env.secret, env.secretTable = secret, secretTable
	Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 } }
	issecrettable = function(value) return rawequal(value, secretTable) end
	local BFL = { L = {
		UNKNOWN = "Unknown", WIZARD_BACKUP_SUCCESS = "BACKUP %d", WIZARD_BACKUP_PARTIAL = "PARTIAL %d/%d",
		WIZARD_BACKUP_REQUIRED = "BACKUP_REQUIRED", WIZARD_APPLY_SUCCESS = "APPLY %d",
		WIZARD_APPLY_FAILED = "APPLY_FAILED %d/%d", WIZARD_RESTORE_SUCCESS = "RESTORE %d",
		WIZARD_RESTORE_FAILED = "RESTORE_FAILED %d/%d", WIZARD_NOTE_UNAVAILABLE = "UNAVAILABLE",
		WIZARD_SYNC_ENABLED = "SYNC_ENABLED",
		WIZARD_NOTES_PENDING = "PENDING %d",
		WIZARD_OPERATION_STATUS = "%d/%d confirmed | %d queued | %d awaiting confirmation | %d unconfirmed",
		WIZARD_STOPPED = "STOPPED", WIZARD_STOP_BTN = "Stop",
	} }
	function BFL:IsSecret(value) return rawequal(value, secret) end
	function BFL:RegisterEventCallback(event, callback) env.callbacks[event] = callback end
	function BFL:GetModule(name) return self.modules and self.modules[name] end
	BFL.DebugPrint = function() end
	BFL.GetNumWoWFriends = function() return #env.wow end
	BFL.GetWoWFriendInfoByIndex = function(index) return env.wow[index] end
	BFL.CanUseWoWFriendList = function() return true end
	local function Timer(delay, callback)
		local item = { time = env.now + delay, callback = callback }
		function item:Cancel() self.cancelled = true end
		env.queue[#env.queue + 1] = item
		return item
	end
	C_Timer = { After = Timer, NewTimer = Timer }
	GetTime = function() return env.now end
	function env:Flush(seconds)
		local finish = self.now + (seconds or 60)
		local iterations = 0
		while #self.queue > 0 do
			table.sort(self.queue, function(a, b) return a.time < b.time end)
			if self.queue[1].time > finish then break end
			local item = table.remove(self.queue, 1)
			self.now = item.time
			if not item.cancelled then item.callback() end
			iterations = iterations + 1
			assert(iterations < 2000, "timer did not terminate")
		end
		self.now = finish
	end
	function env:Message(message)
		for _, value in ipairs(self.messages) do if value:find(message, 1, true) then return true end end
		return false
	end
	DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) env.messages[#env.messages + 1] = tostring(message) end }
	function time() return 123456 end
	function strtrim(value) return value:match("^%s*(.-)%s*$") end
	function strsplit(separator, value)
		local parts, start = {}, 1
		while true do
			local index = value:find(separator, start, true)
			if not index then parts[#parts + 1] = value:sub(start); break end
			parts[#parts + 1] = value:sub(start, index - 1)
			start = index + #separator
		end
		return (table.unpack or unpack)(parts)
	end
	function BNGetNumFriends() return #env.accounts end
	C_BattleNet = { GetFriendAccountInfo = function(index) return env.accounts[index] end }
	local function SetNote(info, field, text)
		if env.mode == "throw" then error("native note failure") end
		if env.mode == "false" then return false end
		if env.mode == "paced" then
			if env.lastWrite and env.now - env.lastWrite < .49 then return false end
			env.lastWrite = env.now
		end
		env.writes[#env.writes + 1] = { info = info, note = text }
		if env.mode == "drop" then return end
		if env.mode == "async" then C_Timer.After(env.delay or 0.3, function() info[field] = text end)
		else info[field] = text end
	end
	function BNSetFriendNote(id, text)
		for _, account in ipairs(env.accounts) do
			if account.bnetAccountID == id then return SetNote(account, "note", text) end
		end
		return false
	end
	C_FriendList = { SetFriendNotes = function(name, text)
		for _, info in ipairs(env.wow) do if info.name == name then
			local result = SetNote(info, "notes", text)
			if result == false then return false end
			return true
		end end
		return false
	end }
	BetterFriendlistDB = { noteBackup = backup }
	assert(loadfile(root .. "/Utils/FriendNotes.lua"))("BetterFriendlist", BFL)
	assert(loadfile(root .. "/Modules/NoteCleanupWizard.lua"))("BetterFriendlist", BFL)
	env.BFL, env.notes, env.wizard = BFL, BFL.FriendNotes, BFL.NoteCleanupWizard
	return env
end

local env = Environment()
local notes = env.notes
Check(notes.GetBNetUID(env.accounts[1]) == "bnet_101", "Title identity missing")
Check(notes.GetBNetUID(env.accounts[2]) == "bnet_202", "Title identities collide")
Check(notes.GetBNetUID(env.accounts[3]) == "bnet_Friend#1234", "BattleTag identity changed")
Check(notes.FindBNetFriend("bnet_202") == env.accounts[2], "Title resolves another friend")
Check(notes.FindBNetFriend("bnet_") == nil, "empty BattleTag identity accepted")
Check(notes.GetBNetUID({ battleTag = "", bnetAccountID = 4, friendLevel = 1 }) == nil, "incomplete non-Title identity accepted")
Check(notes.GetBNetUID(env.secretTable) == nil, "secret table inspected")
Check(notes.GetBNetUID({ battleTag = env.secret, bnetAccountID = 4, friendLevel = 3 }) == nil, "secret BattleTag accepted")
env.wizard:ScanFriends()
Check(env.wizard:ApplyCleanedNotes() == false and #env.writes == 0, "cleanup ran without a backup")
local complete, saved, total = env.wizard:BackupNotes()
Check(complete and saved == 4 and total == 4, "mixed backup count wrong")
Check(BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid"
	and BetterFriendlistDB.noteBackup.bnet_202.originalNote == "Bob#PvP", "Title backups collide")
Check(BetterFriendlistDB.noteBackup["bnet_Friend#1234"].accountName == "Friend#1234", "masked label persisted")
env.mode = "async"
env.wizard:ApplyCleanedNotes()
env:Flush()
Check(#env.writes == 4, "asynchronous verification resent notes")
Check(env.accounts[1].note == "Alice" and env.accounts[2].note == "Bob" and env.wow[1].notes == "WoW", "cleanup crossed identities")
Check(env:Message("APPLY 4"), "confirmed write count wrong")
env.wizard:ApplyBackupFilter()
env.wizard:RestoreBackup()
env:Flush()
Check(env.accounts[1].note == "Alice#Raid" and env.accounts[2].note == "Bob#PvP" and env.wow[1].notes == "WoW#Raid", "restore lost mixed notes")
Check(env:Message("RESTORE 4"), "restore count wrong")

-- Sync owns the note suffix while enabled. The wizard must refuse without
-- changing that preference, then work normally after the user disables it.
env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
BetterFriendlistDB.syncGroupsToNote = true
Check(env.wizard:ApplyCleanedNotes() == false, "cleanup accepted enabled sync")
env.accounts[1].note = "changed after backup"
env.wizard:ApplyBackupFilter()
Check(env.wizard:RestoreBackup() == false, "restore accepted enabled sync")
env:Flush()
Check(#env.writes == 0 and BetterFriendlistDB.syncGroupsToNote == true, "wizard changed sync preference or wrote while enabled")
Check(env:Message("SYNC_ENABLED"), "sync refusal was not explained")
BetterFriendlistDB.syncGroupsToNote = false
env.wizard:RestoreBackup()
env:Flush()
Check(env.accounts[1].note == "Alice#Raid", "restore did not recover after disabling sync")
env.wizard:ScanFriends()
env.wizard:ApplyCleanedNotes()
env:Flush()
Check(env.accounts[1].note == "Alice", "cleanup did not recover after disabling sync")

-- A rescan/reopened window must not permit an overlapping asynchronous batch.
env = Environment()
env.mode = "async"
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.wizard:ApplyCleanedNotes()
C_Timer.After(0.2, function()
	Check(env.wizard:ScanFriends() == false, "rescan cleared an in-flight cleanup lock")
	env.wizard:ApplyBackupFilter()
	Check(env.wizard:RestoreBackup() == false, "restore overlapped asynchronous cleanup")
end)
env:Flush()
Check(#env.writes == 4 and env.accounts[1].note == "Alice", "overlapping restore changed cleanup results")
env.wizard:ApplyBackupFilter()
env.wizard:RestoreBackup()
C_Timer.After(0.2, function()
	Check(env.wizard:ScanFriends() == false, "rescan cleared an in-flight restore lock")
	Check(env.wizard:ApplyCleanedNotes() == false, "cleanup overlapped asynchronous restore")
end)
env:Flush()
Check(#env.writes == 8 and env.accounts[1].note == "Alice#Raid", "overlapping cleanup changed restore results")

env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.wizard:ApplyCleanedNotes()
BetterFriendlistDB.syncGroupsToNote = true
env:Flush()
Check(#env.writes == 0 and env:Message("APPLY_FAILED 0/4"), "queued cleanup wrote after sync was enabled")
BetterFriendlistDB.syncGroupsToNote = false
env.wizard:ApplyCleanedNotes()
env:Flush()
env.wizard:ApplyBackupFilter()
env.wizard:RestoreBackup()
BetterFriendlistDB.syncGroupsToNote = true
env:Flush()
Check(#env.writes == 4 and env:Message("RESTORE_FAILED 0/4"), "queued restore wrote after sync was enabled")

-- Serialized/imported backups cannot reuse a numeric account ID as proof.
local copiedBackup = Copy(BetterFriendlistDB.noteBackup)
env = Environment(copiedBackup)
env.accounts[1].note = "Other person's note"
local rows = env.wizard:GetBackupData()
local unavailable = 0
for _, row in ipairs(rows) do if row.isBNet and row.battleTag == "" then
	Check(row.available == false, "Title identity survived a reload/copy")
	unavailable = unavailable + 1
end end
Check(unavailable == 2, "unavailable Title backups hidden")
Check(env.notes.ResolveBNetIdentity({ uid = "bnet_101" }) == nil, "unmarked numeric identity bypasses session guard")
env.wizard:ApplyBackupFilter()
env.wizard:RestoreBackup()
env:Flush()
Check(#env.writes == 0 and env.accounts[1].note == "Other person's note", "stale Title backup wrote another friend")
Check(env:Message("RESTORE_FAILED 0/2"), "unavailable restores counted successful")

-- Original raw-BattleTag and raw-character-name backups remain restorable.
env = Environment({ ["Friend#1234"] = { isBNet = true, battleTag = "Friend#1234", originalNote = "legacy tag" },
	["Friend-Realm"] = { isBNet = false, originalNote = "legacy wow" } })
env.wizard:ApplyBackupFilter()
env.wizard:RestoreBackup()
env:Flush()
Check(env.accounts[3].note == "legacy tag" and env.wow[1].notes == "legacy wow", "legacy backup compatibility failed")

-- Disappearance and identity changes must fail before a native call.
env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
table.remove(env.accounts, 1)
Check(env.wizard:ApplyCleanedNotes() == false and #env.writes == 0, "cleanup accepted a disappeared friend")
env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.accounts[1].gameAccountInfo.playerGuid = "Player-9-999"
Check(env.wizard:ApplyCleanedNotes() == false and #env.writes == 0, "cleanup accepted changed Title identity")
env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.callbacks.BN_FRIEND_LIST_SIZE_CHANGED()
Check(env.wizard:ApplyCleanedNotes() == false, "roster changes retained numeric backup authority")

-- Changes after confirmation cannot be overwritten by a queued write.
env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.wizard:ApplyCleanedNotes()
env.accounts[1].note = "new external note"
env:Flush()
Check(env.accounts[1].note == "new external note" and #env.writes == 3, "queued cleanup overwrote an external edit")
Check(env:Message("APPLY_FAILED 3/1"), "changed-note failure count wrong")

for _, mode in ipairs({ "false", "throw" }) do
	env = Environment()
	env.wizard:ScanFriends()
	env.wizard:BackupNotes()
	env.mode = mode
	env.wizard:ApplyCleanedNotes()
	env:Flush()
	Check(env.accounts[1].note == "Alice#Raid" and env.wow[1].notes == "WoW#Raid", mode .. " changed notes")
	Check(env:Message("APPLY_FAILED 0/4"), mode .. " counted unconfirmed writes as success")
end

-- Reproduce the reported cache lag: a two-second readback deadline must not
-- turn accepted updates into errors or make a repeated backup unusable.
env = Environment()
env.mode, env.delay = "async", 12
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes()
env:Flush(4)
Check(env:Message("PENDING 4") and not env:Message("APPLY_FAILED"), "slow acknowledgements were reported as failures")
Check(env.wizard:BackupNotes() == true, "backup refused notes awaiting an acknowledgement")
env.wizard:ApplyCleanedNotes(); env:Flush(3)
Check(#env.writes == 4, "early retry duplicated accepted requests")
env:Flush(10)
Check(env.accounts[1].note == "Alice" and env.wow[1].notes == "WoW" and env:Message("APPLY 4"), "late readbacks did not complete without reload")
Check(env.wizard:BackupNotes() == true, "backup stayed stale after late acknowledgement")
Check(BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid", "retry backup erased the pre-cleanup recovery copy")
env.wizard:ApplyCleanedNotes(); env:Flush(2)
Check(#env.writes == 4 and not env:Message("BACKUP_REQUIRED"), "already-clean notes required a new backup or were submitted again")

-- A request with no acknowledgement stays pending. Repeated UI actions cannot
-- infer cancellation or dispatch another copy of the accepted request.
env = Environment()
env.mode = "drop"
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(15)
Check(env:Message("PENDING 4") and not env:Message("APPLY_FAILED"), "unacknowledged request was misclassified")
env.mode = "async"
Check(env.wizard:BackupNotes() == true, "manual retry could not refresh its backup")
env.wizard:ApplyCleanedNotes(); env:Flush(5)
Check(#env.writes == 4, "manual retry duplicated accepted cleanup requests")
env.accounts[1].note, env.accounts[2].note, env.accounts[3].note, env.wow[1].notes = "Alice", "Bob", "Tag", "WoW"
env:Flush(2)
Check(#env.writes == 4 and env:Message("APPLY 4"), "actual cleanup acknowledgement did not complete subscribed retry")

-- The Backup button reads fresh notes instead of requiring the old window
-- snapshot to match. Cleanup must use the new text and preserve user edits.
env = Environment(); env.wizard:ScanFriends()
env.accounts[3].note = "new memo#NewGroup"
Check(env.wizard:BackupNotes() == true, "fresh backup was compared to stale scan text")
Check(BetterFriendlistDB.noteBackup["bnet_Friend#1234"].originalNote == "new memo#NewGroup", "backup saved stale note text")
env.wizard:ApplyCleanedNotes(); env:Flush()
Check(env.accounts[3].note == "new memo", "cleanup used the old window's note text")

-- Queued and submitted notes must be distinguishable while no native update
-- is visible. Stop must cancel remaining dispatch and allow a clean restart.
env = Environment(); env.mode = "drop"
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes()
local progress = env.wizard:GetOperationStatus("cleanup")
Check(progress.queued == 4 and progress.waiting == 0, "cleanup labels unsent work as awaiting confirmation")
env:Flush(.7)
progress = env.wizard:GetOperationStatus("cleanup")
Check(progress.queued == 2 and progress.waiting == 2 and progress.confirmed == 0, "cleanup does not expose actual submitted progress")
env.wizard:Stop()
Check(not env.wizard:IsBusy() and env:Message("STOPPED"), "stop left a wizard lock or omitted feedback")
Check(BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid", "stop erased the recovery copy")
env.mode = "normal"
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes()
C_Timer.After(1, function() env.accounts[1].note, env.accounts[2].note = "Alice", "Bob" end)
env:Flush(5)
Check(#env.writes == 4 and env.accounts[1].note == "Alice", "restart resent stopped accepted deliveries")
Check(env.wizard:GetOperationStatus("cleanup").confirmed == 4, "restart did not confirm all current-operation notes")

env.wizard:ApplyBackupFilter(); env.mode = "drop"; env.wizard:RestoreBackup(); env:Flush(.7)
env.wizard:Stop(); local stoppedWrites = #env.writes; env:Flush(5)
Check(#env.writes == stoppedWrites and not env.wizard:IsBusy(), "stop did not cancel remaining restore work")

env = Environment(); env.mode = "drop"
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(15)
env.wizard:ApplyCleanedNotes()
C_Timer.After(.25, function()
	env.accounts[1].note, env.accounts[2].note, env.accounts[3].note, env.wow[1].notes = "Alice", "Bob", "Tag", "WoW"
end)
env:Flush(6)
progress = env.wizard:GetOperationStatus("cleanup")
Check(progress.confirmed == 4 and progress.unconfirmed == 0 and not env:Message("APPLY_FAILED"), "late first acknowledgement made queued cleanup retries fail")

env = Environment()
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush()
env.mode = "drop"; env.wizard:ApplyBackupFilter(); env.wizard:RestoreBackup(); env:Flush(.2)
progress = env.wizard:GetOperationStatus("restore")
Check(progress.total == 4 and progress.queued == 3 and progress.waiting == 1, "restore did not distinguish queued/submitted work")
env.wizard:ApplyBackupFilter()
progress = env.wizard:GetOperationStatus("restore")
Check(progress.total == 4 and progress.queued == 3 and progress.waiting == 1, "reopening/filtering lost restore queue progress")
env:Flush(15); env.wizard:RestoreBackup()
C_Timer.After(.25, function()
	env.accounts[1].note, env.accounts[2].note, env.accounts[3].note, env.wow[1].notes = "Alice#Raid", "Bob#PvP", "Tag#Raid", "WoW#Raid"
end)
env:Flush(6)
progress = env.wizard:GetOperationStatus("restore")
Check(progress.confirmed == 4 and progress.waiting == 0 and progress.unconfirmed == 0 and not env:Message("RESTORE_FAILED"), "late restore acknowledgement left stale operation progress or false failures")

-- Snapshot index hints are hints, not identity. A reordered roster must
-- re-resolve; a revoked Title identity must be checked immediately before send.
env = Environment()
local snapshot = env.notes.CaptureSnapshot()
local originalAlice, originalBob = env.accounts[1], env.accounts[2]
local identity = env.notes.CreateBNetIdentity(originalAlice)
env.accounts[1], env.accounts[2] = originalBob, originalAlice
Check(env.notes.WriteBNetNote("bnet_101", "Alice", "Alice#Raid", snapshot, identity) == true, "stale index hint did not re-resolve the original friend")
Check(originalAlice.note == "Alice" and originalBob.note == "Bob#PvP", "stale index hint wrote the wrong friend")
env = Environment(); snapshot = env.notes.CaptureSnapshot(); identity = env.notes.CreateBNetIdentity(env.accounts[1])
local originalGetter = C_BattleNet.GetFriendAccountInfo
local replaced = false
C_BattleNet.GetFriendAccountInfo = function(index)
	if not replaced then
		replaced = true
		env.accounts[1] = { bnetAccountID = 101, battleTag = "", friendLevel = 3, note = "Alice#Raid",
			gameAccountInfo = { playerGuid = "Player-9-999" } }
		env.callbacks.BN_FRIEND_LIST_SIZE_CHANGED()
	end
	return originalGetter(index)
end
Check(env.notes.WriteBNetNote("bnet_101", "private group data", "Alice#Raid", snapshot, identity) == false and #env.writes == 0,
	"write used identity evidence revoked during fresh resolution")

env = Environment(); env.mode = "paced"
for index = 4, 80 do env.accounts[index] = { bnetAccountID = index + 400, battleTag = "Bulk#" .. index, note = "memo#Raid" } end
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(60)
Check(#env.writes == 81 and env:Message("APPLY 81") and not env:Message("APPLY_FAILED"), "bulk cleanup exceeded submission pacing")

-- A roster change revokes numeric Title identities. Pending work must finish
-- as unconfirmed instead of holding every wizard action locked forever.
env = Environment(); env.mode, env.delay = "async", 12
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(3)
env.callbacks.BN_FRIEND_LIST_SIZE_CHANGED(); env:Flush(15)
Check(env.wizard:ScanFriends() ~= false, "invalidated pending Title identity permanently blocked scanning")
Check(BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid", "revoked identity erased its recovery text")
Check(env.wizard:BackupNotes() == true and BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid", "fresh backup erased an accepted cleanup's original after identity revocation")
Check(env.notes.ResolveBNetIdentity(BetterFriendlistDB.noteBackup.bnet_101.identity) == nil, "preserving recovery text silently rebound the old Title identity")
env.wizard:ApplyBackupFilter()
Check(env.wizard:RestoreBackup() ~= false, "invalidated pending Title identity permanently blocked restoring other friends")
env:Flush(20)
Check(env.accounts[3].note == "Tag#Raid" and env.wow[1].notes == "WoW#Raid", "stable friends did not restore after Title revocation")

-- Missing optional character details are not proof of removal or replacement.
env = Environment(); env.mode, env.delay = "async", 12
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(3)
env.accounts[1].gameAccountInfo.playerGuid = nil; env:Flush(3)
Check(not env:Message("APPLY_FAILED"), "temporary missing character GUID was treated as an identity replacement")
env.accounts[1].gameAccountInfo.playerGuid = "Player-1-101"; env:Flush(12)
Check(env:Message("APPLY 4"), "pending Title write did not recover when optional details returned")

for _, missing in ipairs({ false, "restricted" }) do
	env = Environment(); env.mode, env.delay = "async", 12
	env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(3)
	env.wow[1].guid = missing == "restricted" and env.secret or nil
	env:Flush(3)
	Check(not env:Message("APPLY_FAILED"), "missing/restricted WoW GUID was treated as replacement")
	env.wow[1].guid = "Player-1-404"; env:Flush(12)
	Check(env:Message("APPLY 4"), "pending WoW write did not recover when its GUID returned")
end

env = Environment()
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush()
env.mode, env.delay = "async", 12
env.wizard:ApplyBackupFilter(); env.wizard:RestoreBackup(); env:Flush(4)
Check(env:Message("PENDING 4") and not env:Message("RESTORE_FAILED"), "delayed restore was reported as a failure")
Check(env.wizard:ApplyCleanedNotes() == false, "cleanup overlapped an accepted, unconfirmed restore")
env.wizard:ApplyBackupFilter(); env.wizard:RestoreBackup(); env:Flush(15)
Check(#env.writes == 8 and env:Message("RESTORE 4"), "late restore acknowledgements were lost after refreshing/retrying the viewer")

env = Environment()
env.accounts[1].note = env.secret
env.accounts[2] = env.secretTable
env.wow[1].notes = env.secret
env.wizard:ScanFriends()
complete, saved, total = env.wizard:BackupNotes()
Check(not complete and saved == 1 and total == 4, "restricted notes became authoritative empty backups")
Check(env:Message("PARTIAL 1/4"), "partial backup count misleading")
Check(BetterFriendlistDB.noteBackup.bnet_101 == nil and BetterFriendlistDB.noteBackup.bnet_202 == nil,
	"restricted records persisted")

env = Environment()
env.wizard:ScanFriends()
env.wizard:BackupNotes()
env.accounts[1].note = env.secret
env.wizard:ScanFriends()
complete, saved, total = env.wizard:BackupNotes()
Check(not complete and saved == 3 and total == 4, "partial refresh count wrong")
Check(BetterFriendlistDB.noteBackup.bnet_101.originalNote == "Alice#Raid", "restricted refresh erased a recoverable backup")
BetterFriendlistDB.noteBackup.unsafe = { isBNet = env.secret, originalNote = "hidden" }
BetterFriendlistDB.noteBackup.secretTable = env.secretTable
Check(#env.wizard:GetBackupData() == 4, "restricted backup fields were inspected")
BetterFriendlistDB.noteBackup["Friend#1234"] = { isBNet = true, battleTag = "Friend#1234", originalNote = "older" }
env.wizard:BackupNotes()
Check(BetterFriendlistDB.noteBackup["Friend#1234"] == nil, "legacy and canonical backups duplicated a friend")

-- The wizard must delegate decoding to NoteSync when its canonical parser exists.
env = Environment()
local parsed = 0
env.BFL.modules = { NoteSync = { ParseNoteGroups = function(_, note, uid)
	Check(type(uid) == "string" and uid ~= "bnet_", "parser received invalid identity")
	parsed = parsed + 1
	return note:match("^[^#]*"), { "decoded#group" }
end } }
env.wizard:ScanFriends()
Check(parsed == 4, "canonical NoteSync parser was bypassed")

env = Environment(); env.mode, env.delay = "async", 12
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(.2)
env.wizard:Stop(); env.wizard:ApplyBackupFilter(); env.wizard:RestoreBackup(); env:Flush(10)
Check(#env.writes == 1 and env.accounts[1].note == "Alice#Raid", "restore overtook the stopped accepted cleanup or falsely confirmed its base")
env:Flush(16)
Check(env.accounts[1].note == "Alice#Raid" and #env.writes == 2, "serialized restore did not follow the cleanup acknowledgement exactly once")
Check(not env.wizard:IsBusy(), "serialized restore retained the operation lock after both acknowledgements")

env = Environment()
env.wizard:ScanFriends(); env.wizard:BackupNotes()
local nativeWoWRead = env.BFL.GetWoWFriendInfoByIndex
local wowReads = 0
env.BFL.GetWoWFriendInfoByIndex = function(index)
	wowReads = wowReads + 1
	if wowReads == 3 then env.wow[index] = { name = "Friend-Realm", guid = "Player-1-OTHER", notes = "WoW#Raid" } end
	return nativeWoWRead(index)
end
-- Exercise the public helper boundary with a snapshot and a fresh same-name replacement.
local oldSnapshot = env.notes.CaptureSnapshot()
env.wow[1] = { name = "Friend-Realm", guid = "Player-1-OTHER", notes = "WoW#Raid" }
local wrote = env.notes.WriteWoWNote("Friend-Realm", "private", "WoW#Raid", oldSnapshot, "Player-1-404", "wizard")
Check(wrote == false and #env.writes == 0, "fresh WoW GUID boundary wrote another same-name character")

env = Environment(); env.mode = "drop"
local stableUID = "bnet_Friend#1234"
env.notes.WriteBNetNote(stableUID, "Tag", "Tag#Raid", nil, nil, "wizard")
Check(BetterFriendlistDB.noteSyncPendingWrites[stableUID].deliveryOnly == true, "wizard accepted record was promoted to sync authority")
local acceptedJournal = Copy(BetterFriendlistDB.noteSyncPendingWrites)
local backupForReload = Copy(BetterFriendlistDB.noteBackup)
env = Environment(backupForReload); BetterFriendlistDB.noteSyncPendingWrites = acceptedJournal
env.mode = "normal"
local success, reason = env.notes.WriteBNetNote(stableUID, "Other", "Tag#Raid", nil, nil, "wizard")
Check(not success and reason == "blocked" and #env.writes == 0, "reload forgot an accepted wizard delivery barrier")
env.accounts[3].note = "Tag"
env.notes.ObserveAcceptedWrite(stableUID, "Tag")
Check(BetterFriendlistDB.noteSyncPendingWrites == nil, "wizard-only acknowledgement left false sync intent in the journal")

print = nativePrint
nativePrint("Friend note helper/wizard smoke passed: " .. checks .. " checks")
