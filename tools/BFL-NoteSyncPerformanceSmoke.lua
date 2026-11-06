-- lua tools/BFL-NoteSyncPerformanceSmoke.lua <repository root>
-- Deterministic API/widget budgets using the production code and existing mocks.
-- CPU timings are diagnostics from this Lua process, not in-game FPS measurements.
local root = assert(arg[1], "repository root required")
local function fixture(path, boundary, body)
	local file = assert(io.open(root .. "/tools/" .. path, "rb"))
	local source = file:read("*a"); file:close()
	local finish = assert(source:find(boundary, 1, true), "fixture setup anchor missing")
	assert(load(source:sub(1, finish - 1) .. body, "@" .. path .. ":performance", "t", _G))()
end

fixture("BFL-NoteSyncSmoke.lua", "reset(); NoteSync:Initialize()", [=[
reset(135); NoteSync:Initialize()
env.BetterFriendlistDB.syncGroupsToNote = false
local group = create("Raid")
for index = 1, 63 do env.BetterFriendlistDB.friendGroups["bnet_Friend#" .. index] = { group } end
env.BetterFriendlistDB.noteSyncPendingWrites = {}
for index = 1, 63 do env.BetterFriendlistDB.noteSyncPendingWrites["bnet_Friend#" .. index] = true end
setterMode = "pending"
local reads, peakReads, peakCPU, invalidations = 0, 0, 0, 0
local nativeRead = env.C_BattleNet.GetFriendAccountInfo
env.C_BattleNet.GetFriendAccountInfo = function(index) reads = reads + 1; return nativeRead(index) end
modules.FriendsList = { InvalidateSettingsCache = function() invalidations = invalidations + 1 end }
for _, name in ipairs({ "NewTimer", "NewTicker" }) do
	local original = env.C_Timer[name]
	env.C_Timer[name] = function(delay, callback)
		return original(delay, function(...)
			local before, start = reads, os.clock()
			callback(...)
			peakReads = math.max(peakReads, reads - before)
			peakCPU = math.max(peakCPU, os.clock() - start)
		end)
	end
end
local initialVersion, start = BFL.SettingsVersion, os.clock()
local completed = 0
assert(NoteSync:Enable(function() completed = completed + 1 end)); advance(9)
assert(#writes == 63 and writes[#writes].time < 10, "legacy pending journal starved initial submissions")
local firstPassFinished = writes[#writes].time
advance(11)
assert(reads < 10000 and peakReads <= 300, string.format("135-friend sync exceeded linear API-read budget: %d total, %d peak", reads, peakReads))
assert(BFL.SettingsVersion - initialVersion <= 1 and invalidations <= 1, "delivery journal invalidated visual settings")
local status = assert(NoteSync:GetSyncStatus())
assert(status.total == 63 and status.confirmed == 0, "status falsely acknowledged a void setter")
assert(status.queued + status.waiting + status.retrying + status.unavailable == 63, "status lost or double-counted work")
local seen = {}
for _, write in ipairs(writes) do assert(not seen[write[1]], "retried old requests before submitting the rest"); seen[write[1]] = true end
local reports = 0
for _, message in ipairs(messages) do if message:find("awaiting confirmation", 1, true) then reports = reports + 1 end end
assert(reports >= 3 and reports <= 6, "long sync has missing or excessive progress messages")
io.write(string.format("[OK] 135 friends/63 legacy journal/20s: first pass %.1fs, %d native reads, peak %d/callback, %d settings invalidations, %.3fs Lua CPU, %.2fms peak\n", firstPassFinished, reads, peakReads, invalidations, os.clock()-start, peakCPU*1000))
advance(40)
assert(#writes == 63 and completed == 0, "unacknowledged accepted requests were duplicated or falsely confirmed after 60s")
for index = 1, 63 do accounts[index].note = "memo#Raid" end
local eventReads = reads; emit("BN_FRIEND_INFO_CHANGED")
assert(reads == eventReads, "native roster reads leaked into event callback")
advance(6)
assert(#writes == 63 and completed == 1 and not NoteSync:GetSyncStatus(), "late acknowledgement failed to complete once without resubmitting")
NoteSync:Disable(); local previousReads = reads; advance(60)
assert(reads == previousReads, "disabled sync continued reading the roster")

modules.FriendsList = nil
reset(135)
group = create("Raid")
for index = 1, 63 do
	accounts[index].battleTag, accounts[index].friendLevel = "", 1
	accounts[index].gameAccountInfo = { playerGuid = "Player-1-" .. index }
	accounts[index].note = "memo#Raid"
	env.BetterFriendlistDB.friendGroups["bnet_" .. index] = { group }
end
assert(NoteSync:Enable()); advance(8)
reads = 0; assert(Groups:Rename(group, "Updated"))
assert(reads <= 300, "Title group rename rescanned the roster per member")
advance(1); reads = 0; assert(Groups:Delete(group))
assert(reads <= 300, "Title group deletion rescanned the roster per member")
io.write("[OK] Title rename/delete use bounded synchronous reads\n")

reset(135)
group = create("Startup")
env.BetterFriendlistDB.noteSyncPendingWrites = {}
for index = 1, 63 do
	local uid = "bnet_Friend#" .. index
	env.BetterFriendlistDB.friendGroups[uid] = { group }
	env.BetterFriendlistDB.noteSyncPendingWrites[uid] = true
end
setterMode = "pending"
NoteSync:Initialize(); advance(9)
assert(#writes == 63 and writes[63].time < 10, "startup journal waited behind verification or old retries")
local startupFinished = writes[63].time
advance(51)
assert(#writes == 63, "startup accepted deliveries were automatically duplicated")
for index = 1, 63 do accounts[index].note = "memo#Startup" end
advance(6)
assert(not NoteSync:GetSyncStatus() and not next(NoteSync.pendingWrites), "startup acknowledgement did not finish visible work")
io.write(string.format("[OK] startup without toggle/63 legacy journal: first pass %.1fs, exactly 63 submissions through 60s\n", startupFinished))
]=])

fixture("BFL-FriendNotesSmoke.lua", "local env = Environment()", [=[
local env = Environment()
for index = 4, 135 do env.accounts[index] = { bnetAccountID = 1000 + index, battleTag = "Load#" .. index, note = "memo#Raid" } end
env.wizard:ScanFriends(); env.wizard:BackupNotes(); env.wizard:ApplyCleanedNotes(); env:Flush(80)
local backup, count = {}, 0
for key, entry in pairs(BetterFriendlistDB.noteBackup) do
	if entry.isBNet and count < 63 then backup[key] = entry; count = count + 1 end
end
BetterFriendlistDB.noteBackup = backup
env.mode = "drop"
env.wizard:ApplyBackupFilter(); env.wizard:RestoreBackup(); env:Flush(35)
local widgets = 0
local function Widget()
	return setmetatable({}, { __index = function(_, key)
		if key == "GetWidth" then return function() return 700 end end
		if key == "CreateTexture" or key == "CreateFontString" then return function() return Widget() end end
		return function() widgets = widgets + 1 end
	end })
end
CreateFrame = function() return Widget() end
date = os.date
env.BFL.L.WIZARD_BACKUP_STATUS_FMT = "%d %d %d %s"
for index = 1, 40 do
	local name = debug.getupvalue(env.wizard.RefreshBackupRows, index)
	if not name then break end
	if name == "backupViewerFrame" then debug.setupvalue(env.wizard.RefreshBackupRows, index, { scrollChild = Widget(), countLabel = Widget() }) end
end
for _, account in ipairs(env.accounts) do
	local saved = backup[env.notes.GetBNetUID(account)]
	if saved then account.note = saved.originalNote end
end
local reads = 0
local getter = C_BattleNet.GetFriendAccountInfo
C_BattleNet.GetFriendAccountInfo = function(index) reads = reads + 1; return getter(index) end
local start = os.clock(); env:Flush(1)
assert(reads <= 300, "acknowledgement callbacks each recaptured the roster")
assert(widgets < 5000, "acknowledgement callbacks each rebuilt the full window")
assert(not env.wizard:IsBusy(), "confirmed restore kept the wizard locked")
io.write(string.format("[OK] 63 restore acknowledgements/open viewer: %d native reads, %d widget calls, %.2fms Lua CPU\n", reads, widgets, (os.clock()-start)*1000))
]=])
