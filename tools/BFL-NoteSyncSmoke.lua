-- Lua 5.4: lua tools/BFL-NoteSyncSmoke.lua <repository root>
-- Loads production modules; native friend APIs/timers and SavedVariables stay in memory.
local repo = arg[1] or "."
local assertions, modules, events = 0, {}, {}
local accounts, wowFriends, timers, now, writes, setterMode = {}, {}, {}, 0, {}, "success"
local lastNativeWrite
local secret = setmetatable({}, { __tostring = function() error("secret consumed") end })
local env = setmetatable({}, { __index = _G })
env._G = env
local BFL = { L = {}, SettingsVersion = 1 }
function BFL:RegisterModule(name, module) modules[name] = module; return module end
function BFL:GetModule(name) return modules[name] end
BFL.DebugPrint = function() end
function BFL:ForceRefreshFriendsList() end
function BFL:IsSecret(value) return value == secret end
function BFL:RegisterEventCallback(event, callback)
	events[event] = events[event] or {}; table.insert(events[event], callback)
end
function BFL:NormalizeWoWFriendName(name) return name:find("-", 1, true) and name or name .. "-Realm" end
BFL.CanUseWoWFriendList = function() return true end
BFL.GetNumWoWFriends = function() return #wowFriends end
BFL.GetWoWFriendInfoByIndex = function(index) return wowFriends[index] end
env.Enum = { BattleNetFriendLevel = { Title = 1 } }
env.BFL_LOCALE = {}
local messages = {}
env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
env.GetTime = function() return now end
env.strtrim = function(text) return text:match("^%s*(.-)%s*$") end
env.strsplit = function(delimiter, text)
	local parts, start = {}, 1
	while true do
		local index = text:find(delimiter, start, true)
		if not index then parts[#parts + 1] = text:sub(start); break end
		parts[#parts + 1] = text:sub(start, index - 1); start = index + #delimiter
	end
	return table.unpack(parts)
end
env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
env.CopyTable = function(t)
	local copy = {}; for k, v in pairs(t) do copy[k] = type(v) == "table" and env.CopyTable(v) or v end; return copy
end
local function timer(delay, callback, repeating)
	local item = { due = now + delay, delay = delay, callback = callback, repeating = repeating }
	function item:Cancel() self.cancelled = true end
	timers[#timers + 1] = item; return item
end
env.C_Timer = {
	NewTimer = function(delay, callback) return timer(delay, callback) end,
	NewTicker = function(delay, callback) return timer(delay, callback, true) end,
}
env.BNGetNumFriends = function() return #accounts end
env.C_BattleNet = { GetFriendAccountInfo = function(index) return accounts[index] end }
local function write(target, note, isBNet)
	writes[#writes + 1] = { target, note, isBNet, time = now }
	if setterMode == "error" then error("native failure") end
	if setterMode == "false" then return false end
	if setterMode == "pending" then return end
	if setterMode == "recover-later" and now < 45 then return false end
	if setterMode == "paced" then
		if lastNativeWrite and now - lastNativeWrite < .099 then return false end
		lastNativeWrite = now
	end
	for _, friend in ipairs(isBNet and accounts or wowFriends) do
		if (isBNet and friend.bnetAccountID or friend.name) == target then
			if setterMode == "delayed" then
				timer(12, function() friend[isBNet and "note" or "notes"] = note end)
				return
			end
			friend[isBNet and "note" or "notes"] = note
			return true
		end
	end
	return false
end
env.BNSetFriendNote = function(id, note) return write(id, note, true) end
env.C_FriendList = { SetFriendNotes = function(name, note) return write(name, note, false) end }
for _, path in ipairs({ "Utils/FriendNotes.lua", "Modules/Database.lua", "Modules/Groups.lua", "Modules/NoteSync.lua" }) do
	assert(loadfile(repo .. "/" .. path, "t", env))("BetterFriendlist", BFL)
end
local DB, Groups, NoteSync = modules.DB, modules.Groups, modules.NoteSync
local function equal(actual, expected, message)
	assertions = assertions + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function reset(count)
	NoteSync:CancelWork()
	-- Each fixture is an independent game session, including shared delivery state.
	for index = 1, 20 do
		local name, value = debug.getupvalue(BFL.FriendNotes.GetAcceptedWrite, index)
		if name == "acceptedWrites" then for uid in pairs(value) do value[uid] = nil end; break end
	end
	env.BetterFriendlistDB = { syncGroupsToNote = true, customGroups = {}, friendGroups = {}, groupCountColors = {},
		groupArrowColors = {}, groupColors = {}, groupStates = {}, migration = {} }
	accounts, wowFriends, timers, writes, now, setterMode = {}, {}, {}, {}, 0, "success"
	lastNativeWrite, messages = nil, {}
	for i = 1, count or 1 do accounts[i] = { bnetAccountID = i, battleTag = "Friend#" .. i, note = "memo" } end
	NoteSync.pendingWrites, NoteSync.inFlight, NoteSync.titleIdentities, NoteSync.unresolvedImports = {}, {}, {}, {}
	NoteSync.isImporting, NoteSync.isWriting = false, false
	Groups:Initialize()
end
local function advance(seconds)
	local finish, guard = now + seconds, 0
	while true do
		local nextTimer
		for _, item in ipairs(timers) do
			if not item.cancelled and item.due <= finish and (not nextTimer or item.due < nextTimer.due) then nextTimer = item end
		end
		if not nextTimer then break end
		guard = guard + 1; assert(guard < 1000, "timer failed to settle")
		now = nextTimer.due
		if nextTimer.repeating then nextTimer.due = now + nextTimer.delay else nextTimer.cancelled = true end
		nextTimer.callback(nextTimer)
	end
	now = finish
end
local function create(name)
	local success, id = Groups:Create(name); assert(success); return id
end
local function emit(event)
	for _, callback in ipairs(events[event] or {}) do callback() end
end

reset(); NoteSync:Initialize()

reset()
env.BetterFriendlistDB.syncGroupsToNote = false
accounts = {
	{ bnetAccountID = 1, battleTag = "Friend#1", note = "memo#Raid" },
	{ bnetAccountID = 2, battleTag = "", friendLevel = 1, note = "two#Beta" },
	{ bnetAccountID = 3, battleTag = "", friendLevel = 1, note = "three#Gamma" },
}
equal(NoteSync:Enable(), true, "enable succeeds")
advance(0.2)
equal(accounts[1].note, "memo#Raid", "enable preserves FriendGroups tag")
equal(accounts[2].note, "two#Beta", "first Title note stays distinct")
equal(accounts[3].note, "three#Gamma", "second Title note stays distinct")
equal(DB:IsFriendInGroup("bnet_2", "custom_beta"), true, "Title import uses current UID")
equal(DB:IsFriendInGroup("bnet_3", "custom_gamma"), true, "second Title assignment stays distinct")
equal(env.BetterFriendlistDB.friendGroups.bnet_, nil, "no empty BattleTag UID")
equal(Groups:GetFriendUID({ type = "bnet", battleTag = "", friendLevel = 1, bnetAccountID = 2 }), "bnet_2", "group UID agrees")

reset()
local renamed = create("Alpha")
DB:AddFriendToGroup("bnet_Friend#1", renamed)
assert(Groups:Rename(renamed, "Beta")); assert(Groups:Rename(renamed, "Gamma"))
NoteSync:VerifyAllNotes(); advance(1)
equal(accounts[1].note, "memo#Gamma", "rename replaces old tag after paced dispatch")
equal(Groups:GetGroupIdByName("Beta"), nil, "rename never resurrects old group")
equal(Groups:GetGroupIdByName("Alpha"), nil, "original deterministic ID does not resurrect name")
setterMode = "false"
assert(Groups:Rename(renamed, "Delta"))
NoteSync:VerifyAllNotes(); advance(1)
equal(Groups:GetGroupIdByName("Gamma"), nil, "failed rename excludes stale import")
equal(NoteSync.isWriting, false, "native false releases write guard")
equal(env.BetterFriendlistDB.noteSyncPendingWrites["bnet_Friend#1"], true, "failed edit journals intent")
setterMode = "success"; NoteSync:VerifyAllNotes(); advance(6)
equal(accounts[1].note, "memo#Delta", "failed rename recovers")
equal(next(NoteSync.pendingWrites), nil, "successful reconciliation clears journal")
setterMode = "false"; assert(Groups:Rename(renamed, "AfterReload"))
NoteSync:CancelWork(); NoteSync.pendingWrites = {}; NoteSync:LoadPendingWrites()
setterMode = "success"; NoteSync:VerifyAllNotes()
equal(accounts[1].note, "memo#AfterReload", "saved unfinished rename reconciles before import after reload")
equal(Groups:GetGroupIdByName("Delta"), nil, "reload journal prevents stale group resurrection")

reset()
local hashGroup = create("Raid#One")
DB:AddFriendToGroup("bnet_Friend#1", hashGroup)
equal(accounts[1].note, "memo#~BFL1~Raid%23One", "delimiter is reversibly encoded")
NoteSync:VerifyAllNotes()
equal(Groups:GetGroupIdByName("Raid"), nil, "encoded name creates no phantom Raid")
equal(Groups:GetGroupIdByName("One"), nil, "encoded name creates no phantom One")
accounts[1].note = "memo#Raid#One"; NoteSync:VerifyAllNotes(); advance(1)
equal(accounts[1].note, "memo#~BFL1~Raid%23One", "assigned legacy ambiguous name is upgraded safely")
local names = { "Plain", "100% Ready", "Raid#One", " space ", "~BFL1~Raid%23One", "~BFL1~bad%xx", "a##b", "\233\155\170" }
for _, name in ipairs(names) do
	local note = NoteSync:BuildNoteWithGroups("memo", { name }, 127)
	local actual, parsed = NoteSync:ParseNoteGroups(note)
	equal(actual, "memo", "roundtrip preserves note")
	equal(#parsed, 1, "roundtrip preserves group count")
	equal(parsed[1], name, "roundtrip preserves exact name")
end
local ordinary = NoteSync:BuildNoteWithGroups("memo", { "100% Ready" }, 127)
equal(ordinary, "memo#100% Ready", "ordinary FriendGroups names remain byte-for-byte")
local markerGroup = create("~BFL1~Raid%23One")
DB:AddFriendToGroup("bnet_Friend#1", markerGroup)
advance(1)
local _, mixedNames = NoteSync:ParseNoteGroups(accounts[1].note, "bnet_Friend#1")
local mixedSet = {}; for _, name in ipairs(mixedNames) do mixedSet[name] = true end
equal(mixedSet["Raid#One"], true, "encoded group wins canonical interpretation beside literal marker name")
equal(mixedSet["~BFL1~Raid%23One"], true, "literal marker name also roundtrips beside encoded group")
reset()
local legacyMarker = create("~BFL1~Raid%23One")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { legacyMarker }
accounts[1].note = "memo#~BFL1~Raid%23One"
NoteSync:VerifyAllNotes()
equal(Groups:GetGroupIdByName("Raid#One"), nil, "known legacy literal marker is not mistaken for encoded name")
local _, literalNames = NoteSync:ParseNoteGroups(accounts[1].note)
equal(literalNames[1], "~BFL1~Raid%23One", "legacy literal marker upgrades reversibly")

reset(6)
local deleted = create("Raid")
for _, account in ipairs(accounts) do DB:AddFriendToGroup("bnet_" .. account.battleTag, deleted) end
NoteSync:SyncAllFriends(); advance(0.1)
equal(NoteSync.isSyncing, true, "paced batch remains active before dispatch")
assert(Groups:Delete(deleted)); advance(4); NoteSync:VerifyAllNotes()
equal(Groups:GetGroupIdByName("Raid"), nil, "delete during sync never resurrects group")
for _, account in ipairs(accounts) do equal(account.note, "memo", "delete revisits processed and unprocessed friends") end
local added = create("New")
NoteSync:SyncAllFriends(); DB:AddFriendToGroup("bnet_Friend#1", added); advance(1)
equal(accounts[1].note, "memo#New", "membership added during batch is synchronized")

reset()
create("Raid"); accounts[1].note = "memo#raid"
local created, assigned = NoteSync:ImportGroupsFromNotes()
equal(created, 0, "case variant uses existing group")
equal(assigned, 1, "case variant imports assignment")
NoteSync:SyncAllFriends(); advance(1)
equal(accounts[1].note, "memo#Raid", "case variant retains membership")

local glyph = "\233\155\170"
local text, limited = NoteSync:BuildNoteWithGroups(string.rep(glyph, 44), { glyph .. glyph .. glyph }, 48)
equal(limited, false, "48 UTF-8 letters fit character note")
equal(utf8.len(text), 48, "UTF-8 note uses native letter capacity")
text, limited = NoteSync:BuildNoteWithGroups(string.rep(glyph, 45), { glyph .. glyph .. glyph }, 48)
equal(limited, true, "49 letters exceed character note")
equal(text, string.rep(glyph, 45), "limit leaves note untouched")

reset()
wowFriends = { { name = "Character", notes = "character memo" } }
local native = create("Native")
setterMode = "false"; DB:AddFriendToGroup("wow_Character-Realm", native)
equal(wowFriends[1].notes, "character memo", "false native result does not report completion")
equal(NoteSync.pendingWrites["wow_Character-Realm"], true, "false native result queues retry")
setterMode = "error"; NoteSync:VerifyAllNotes(); advance(6)
equal(NoteSync.isWriting, false, "native error releases write guard")
equal(NoteSync.isImporting, false, "native error leaves import guard clear")
setterMode = "success"; NoteSync:VerifyAllNotes(); advance(15)
equal(wowFriends[1].notes, "character memo#Native", "native write recovers after error")

reset()
local pending = create("Pending")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", pending)
local before = #writes
NoteSync:VerifyAllNotes(); equal(#writes, before, "unacknowledged write is not resent immediately")
accounts[1].note = "memo#Pending"; NoteSync:VerifyAllNotes()
equal(next(NoteSync.pendingWrites), nil, "readback acknowledgement clears pending without resend")

reset(6)
local paused = create("Paused")
for _, account in ipairs(accounts) do DB:AddFriendToGroup("bnet_" .. account.battleTag, paused) end
writes = {}; NoteSync:SyncAllFriends(); NoteSync.isImporting = true; advance(1.1)
equal(#writes, 0, "profile transaction pauses ticker writes")
NoteSync.isImporting = false; NoteSync:Disable(); advance(6)
equal(NoteSync.isSyncing, false, "disable cancels ticker")
equal(NoteSync.verifyTimer, nil, "disable cancels verification")
equal(#writes, 0, "disabled feature performs no writes")
NoteSync:Enable(nil, function() NoteSync:Disable() end); advance(0.5)
equal(NoteSync.isSyncing, false, "disable from progress callback safely cancels old generation")

reset()
local imported = create("Imported")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { imported }
accounts[1].note = "memo#Old"
NoteSync:OnDatabaseImported()
equal(accounts[1].note, "memo#Old", "import hook never writes synchronously")
advance(1); NoteSync:VerifyAllNotes()
equal(accounts[1].note, "memo#Imported", "committed profile reconciles DB before note import")
equal(Groups:GetGroupIdByName("Old"), nil, "committed profile does not resurrect previous note groups")

reset()
accounts[1].note = "memo#Favorites"
equal(NoteSync:Enable(), true, "builtin-name import does not fail whole enable")
advance(1)
equal(accounts[1].note, "memo#Favorites", "unrepresentable builtin token is preserved")
reset()
accounts[1].note = "memo#FailedImport"
local originalCreate = Groups.CreateWithOrder
Groups.CreateWithOrder = function() error("import failure") end
equal(NoteSync:Enable(), false, "failed import never starts writing")
equal(NoteSync.isImporting, false, "failed import releases guard")
equal(NoteSync.isWriting, false, "failed import leaves write guard clear")
equal(env.BetterFriendlistDB.syncGroupsToNote, false, "failed enable rolls back enabled flag")
equal(accounts[1].note, "memo#FailedImport", "failed import preserves source note")
Groups.CreateWithOrder = originalCreate
equal(NoteSync:Enable(), true, "enable recovers after importer failure")
advance(1)
equal(accounts[1].note, "memo#FailedImport", "recovered enable imports before writing")
reset()
accounts[1].note = "memo#Refresh"
local originalRefresh = BFL.ForceRefreshFriendsList
BFL.ForceRefreshFriendsList = function() error("refresh failure") end
equal(NoteSync:Enable(), true, "UI refresh failure does not leak import state or lose notes")
BFL.ForceRefreshFriendsList = originalRefresh
advance(1)
equal(NoteSync.isImporting, false, "UI refresh failure releases import guard")
equal(accounts[1].note, "memo#Refresh", "UI refresh failure preserves imported note")

reset()
accounts[1].battleTag, accounts[1].friendLevel = "", 1
local title = create("Title")
DB:AddFriendToGroup("bnet_1", title)
equal(accounts[1].note, "memo#Title", "current Title action binds identity and writes")
equal(env.BetterFriendlistDB.noteSyncPendingWrites, nil, "numeric Title intent is never saved")
setterMode = "false"; assert(Groups:Rename(title, "Renamed"))
for _, callback in ipairs(events.BN_DISCONNECTED or {}) do callback() end
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "other person" }
setterMode = "success"; NoteSync:VerifyAllNotes()
equal(accounts[1].note, "other person", "invalidated Title identity cannot replay pending write")
assert(Groups:Rename(title, "Again"))
equal(accounts[1].note, "other person", "definition rename cannot reauthorize an invalidated Title target")
NoteSync:OnDatabaseImported(); advance(0.2)
equal(accounts[1].note, "other person", "profile cannot inherit old numeric Title authorization")
DB:SetFriendGroups("bnet_1", { title }); advance(1)
equal(accounts[1].note, "other person#Again", "new current-friend action can establish a fresh identity")

reset()
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "old memo#OldPrivateGroup",
	gameAccountInfo = { playerGuid = "Player-1-OLD" } }
assert(NoteSync:Enable()); advance(1)
emit("BN_DISCONNECTED")
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "new memo#NewPublicGroup",
	gameAccountInfo = { playerGuid = "Player-1-NEW" } }
NoteSync:VerifyAllNotes()
equal(accounts[1].note, "new memo#NewPublicGroup", "passive note import cannot rebind an invalidated Title target")
equal(DB:IsFriendInGroup("bnet_1", "custom_oldprivategroup"), true, "invalidated Title mapping remains preserved")
NoteSync:SyncAllFriends(); advance(0.2); NoteSync:VerifyAllNotes()
equal(accounts[1].note, "new memo#NewPublicGroup", "full sync cannot reauthorize invalidated numeric evidence")
NoteSync.titleIdentities = {}; NoteSync.pendingWrites = {}
NoteSync:VerifyAllNotes()
equal(accounts[1].note, "new memo#NewPublicGroup", "missing Title pin after reload cannot replay unrelated saved names")

reset()
local savedTitle = create("SavedPrivate")
env.BetterFriendlistDB.friendGroups.bnet_1 = { savedTitle }
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "memo#Public",
	gameAccountInfo = { playerGuid = "Player-1-UNKNOWN" } }
assert(NoteSync:Enable()); advance(1)
equal(accounts[1].note, "memo#Public", "unknown persisted numeric mapping cannot authorize first automatic write")
equal(DB:IsFriendInGroup("bnet_1", savedTitle), true, "unknown persisted Title membership is not deleted")
NoteSync:VerifyAllNotes()
equal(accounts[1].note, "memo#Public", "later imports do not turn unknown numeric mappings into authority")

reset()
env.BetterFriendlistDB.syncGroupsToNote = false
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "memo",
	gameAccountInfo = { playerGuid = "Player-1-CURRENT" } }
local currentTitle = create("CurrentSessionGroup")
DB:AddFriendToGroup("bnet_1", currentTitle)
equal(#writes, 0, "disabled current-friend action records evidence without writing")
equal(env.BetterFriendlistDB.noteSyncPendingWrites, nil, "disabled current-friend action creates no exportable write intent")
assert(NoteSync:Enable()); advance(1)
equal(accounts[1].note, "memo#CurrentSessionGroup", "current-session Title assignment made while disabled survives activation")

reset()
accounts[1] = { bnetAccountID = 1, battleTag = "", friendLevel = 1, note = "memo",
	gameAccountInfo = { playerGuid = "Player-1-MIGRATION" } }
local migratedTitle = create("Migration")
local originalMigration = Groups.MigrateFriendAssignments
Groups.MigrateFriendAssignments = function() DB:AddFriendToGroup("bnet_1", migratedTitle) end
Groups:Initialize()
Groups.MigrateFriendAssignments = originalMigration
equal(NoteSync.titleIdentities.bnet_1, nil, "initialization migration is not a current-friend identity action")
equal(#writes, 0, "initialization migration performs no note writes")

reset()
local unavailable = create("Unavailable")
setterMode = "false"; DB:AddFriendToGroup("bnet_Friend#1", unavailable)
accounts = {}; advance(11)
equal(NoteSync.verifyTimer, nil, "unavailable target waits for roster events instead of permanent polling")
accounts = { { bnetAccountID = 1, battleTag = "Friend#1", note = "memo" } }
setterMode = "success"; NoteSync:VerifyAllNotes()
equal(accounts[1].note, "memo#Unavailable", "returning target reconciles retained local intent")

reset()
local helperFailure = create("Helper")
local originalWrite = BFL.FriendNotes.WriteBNetNote
BFL.FriendNotes.WriteBNetNote = function() error("helper callback failure") end
DB:AddFriendToGroup("bnet_Friend#1", helperFailure)
equal(NoteSync.isWriting, false, "unexpected writer exception releases write guard")
BFL.FriendNotes.WriteBNetNote = originalWrite
NoteSync:VerifyAllNotes(); advance(6)
equal(accounts[1].note, "memo#Helper", "unexpected writer exception recovers")

reset()
local rejected = create("Rejected")
setterMode = "false"; DB:AddFriendToGroup("bnet_Friend#1", rejected)
advance(40)
equal(#writes <= 5, true, "permanent false uses bounded exponential backoff")
equal(NoteSync.verifyTimer ~= nil, true, "permanent false retains scheduled recovery")
equal(NoteSync.pendingWrites["bnet_Friend#1"], true, "permanent false retains local intent")
setterMode = "success"; advance(65)
equal(accounts[1].note, "memo#Rejected", "transient rejection recovers without a new roster event")

reset()
local neverAcknowledged = create("NeverAcknowledged")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", neverAcknowledged)
advance(40)
equal(#writes <= 5, true, "void setter without acknowledgement has bounded submission rate")
equal(NoteSync.verifyTimer ~= nil, true, "unacknowledged setter keeps reconciliation scheduled")
local attemptsBeforeEvent = #writes
emit("BN_FRIEND_INFO_CHANGED"); advance(5.2)
equal(#writes, attemptsBeforeEvent, "unchanged note event does not reset retry backoff")
accounts[1].note = "memo#NeverAcknowledged"; advance(6)
equal(accounts[1].note, "memo#NeverAcknowledged", "actual asynchronous acknowledgement completes without reconnect or reload")
equal(#writes, 1, "accepted void request is never automatically submitted again")

reset(2)
local localGroup = create("Local")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { localGroup }
accounts[1].note, accounts[2].note = secret, "second#Remote"
equal(NoteSync:Enable(), true, "incomplete roster keeps requested setting enabled")
advance(6)
equal(#writes, 0, "incomplete initial import never writes a partial roster")
equal(NoteSync.enablePending, true, "incomplete first import waits for readiness")
NoteSync:SyncAllFriends(); advance(1)
equal(#writes, 0, "explicit full sync cannot bypass pending initial import")
accounts[1].note = "memo#FirstLoaded"
emit("BN_FRIEND_INFO_CHANGED"); advance(5.3)
equal(NoteSync.enablePending, false, "readable roster completes pending enable")
equal(DB:IsFriendInGroup("bnet_Friend#1", "custom_firstloaded"), true, "newly readable existing tag imports before first write")
equal(DB:IsFriendInGroup("bnet_Friend#1", localGroup), true, "initial readiness preserves saved local membership")

reset()
local emptyRosterGroup = create("Local")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { emptyRosterGroup }
accounts = {}
assert(NoteSync:Enable()); advance(0.3)
equal(NoteSync.pendingWrites["bnet_Friend#1"], nil, "complete empty activation roster establishes no authority for unseen saved UID")
accounts = { { bnetAccountID = 1, battleTag = "Friend#1", note = "memo#Remote" } }
emit("BN_CONNECTED"); advance(5.3)
equal(DB:IsFriendInGroup("bnet_Friend#1", "custom_remote"), true, "first readable note is imported after empty activation")
equal(accounts[1].note:find("Remote", 1, true) ~= nil, true, "initially unseen remote group is preserved")

reset(2)
local omittedGroup = create("Local")
env.BetterFriendlistDB.friendGroups["bnet_Friend#2"] = { omittedGroup }
accounts[2] = nil
assert(NoteSync:Enable()); advance(0.3)
equal(NoteSync.pendingWrites["bnet_Friend#2"], nil, "readable partial roster creates no authority for omitted saved UID")
accounts[2] = { bnetAccountID = 2, battleTag = "Friend#2", note = "second memo#RemoteSecond" }
emit("BN_FRIEND_LIST_SIZE_CHANGED"); advance(5.3)
equal(DB:IsFriendInGroup("bnet_Friend#2", "custom_remotesecond"), true, "omitted friend imports its own first readable note")
equal(accounts[2].note:find("RemoteSecond", 1, true) ~= nil, true, "omitted friend's remote assignment survives activation")

reset()
local explicitJournal = create("JournalLocal")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { explicitJournal }
env.BetterFriendlistDB.noteSyncPendingWrites = { ["bnet_Friend#1"] = true }
accounts = {}; assert(NoteSync:Enable()); advance(0.3)
accounts = { { bnetAccountID = 1, battleTag = "Friend#1", note = "memo#Stale" } }
emit("BN_CONNECTED"); advance(5.3)
equal(accounts[1].note, "memo#JournalLocal", "explicit unfinished journal still authorizes delayed reconciliation")

reset()
local restoredAbsent = create("RestoredAbsent")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { restoredAbsent }
accounts = {}; NoteSync:OnDatabaseImported(); advance(0.3)
equal(NoteSync.pendingWrites["bnet_Friend#1"], true, "explicit profile restore preserves intent for absent stable UID")
accounts = { { bnetAccountID = 1, battleTag = "Friend#1", note = "memo#PreviousProfile" } }
emit("BN_CONNECTED"); advance(5.3)
equal(accounts[1].note, "memo#RestoredAbsent", "explicit profile restore remains authoritative when target later appears")

reset()
accounts[1].note = secret
local _, _, scanned = NoteSync:ImportGroupsFromNotes()
equal(scanned, true, "restricted row is safely skipped")
equal(#writes, 0, "restricted note is never written")
accounts[1].note = "memo#Recovered"; NoteSync:VerifyAllNotes()
equal(DB:IsFriendInGroup("bnet_Friend#1", "custom_recovered"), true, "restricted read recovers when readable")

-- The reported partial bulk sync must not exhaust a global/native burst budget.
reset(80)
local bulk = create("Bulk")
for _, account in ipairs(accounts) do env.BetterFriendlistDB.friendGroups["bnet_" .. account.battleTag] = { bulk } end
setterMode = "paced"
NoteSync:SyncAllFriends(); advance(60)
for _, account in ipairs(accounts) do equal(account.note, "memo#Bulk", "paced bulk sync reaches every friend") end
for index = 2, #writes do equal(writes[index].time - writes[index - 1].time >= .099, true, "every native write path obeys BFL pacing policy") end
equal(next(NoteSync.pendingWrites), nil, "bulk success clears all pending intent")

-- A busy roster previously postponed verification indefinitely. The backend
-- recovers after the former three-attempt budget without any reconnect event.
reset(20)
local recovered = create("Recovered")
for _, account in ipairs(accounts) do env.BetterFriendlistDB.friendGroups["bnet_" .. account.battleTag] = { recovered } end
setterMode = "recover-later"
local noisyRoster = timer(.2, function() emit("BN_FRIEND_INFO_CHANGED") end, true)
local completed = 0
NoteSync:SyncAllFriends(function() completed = completed + 1 end)
advance(40)
equal(completed, 0, "bulk completion callback waits for actual confirmations")
equal(next(NoteSync.pendingWrites) ~= nil or next(NoteSync.passiveQueued) ~= nil, true, "unconfirmed changes retain work beyond three attempts")
advance(90); noisyRoster:Cancel()
for _, account in ipairs(accounts) do equal(account.note, "memo#Recovered", "busy roster cannot starve delayed sync recovery") end
equal(completed, 1, "recovered bulk sync completes exactly once")
equal(next(NoteSync.pendingWrites), nil, "delayed bulk recovery clears every journal entry")
NoteSync:Disable(); local submissions = #writes; advance(90)
equal(#writes, submissions, "disabling sync cancels continuing retries")

reset(30)
local delayed = create("Delayed")
for _, account in ipairs(accounts) do env.BetterFriendlistDB.friendGroups["bnet_" .. account.battleTag] = { delayed } end
setterMode = "delayed"
completed = 0
NoteSync:SyncAllFriends(function() completed = completed + 1 end)
advance(16)
equal(completed, 0, "dispatching every note does not falsely announce completion")
local pendingMessage = false
for _, message in ipairs(messages) do if message:find("queued", 1, true) then pendingMessage = true end end
equal(pendingMessage, true, "unconfirmed full sync reports pending state")
advance(35)
for _, account in ipairs(accounts) do equal(account.note, "memo#Delayed", "late readback eventually confirms every friend") end
equal(completed, 1, "late acknowledgements complete full sync without reload")
equal(next(NoteSync.pendingWrites), nil, "late acknowledgements clear saved work")

reset(6)
local alpha = create("Alpha")
for _, account in ipairs(accounts) do account.note = "memo#Alpha" end
assert(NoteSync:Enable()); advance(.05)
local lastUID = NoteSync.syncQueue[#NoteSync.syncQueue]
local lastID = tonumber(lastUID:match("#(%d+)$"))
accounts[lastID].note = "memo#RemoteDuringQueue"
advance(6)
equal(DB:IsFriendInGroup(lastUID, "custom_remoteduringqueue"), true, "passive queue reads fresh remote tags at dispatch")
equal(accounts[lastID].note:find("RemoteDuringQueue", 1, true) ~= nil, true, "queue wait never grants authority to discard a new tag")

reset(6)
alpha = create("Alpha")
for _, account in ipairs(accounts) do account.note = "memo#Alpha" end
assert(NoteSync:Enable()); advance(.1)
local confirmedUID
for uid in pairs(NoteSync.syncReport.confirmed) do confirmedUID = uid; break end
local confirmedID = tonumber(confirmedUID:match("#(%d+)$"))
local beta = create("Beta")
setterMode = "pending"; DB:AddFriendToGroup(confirmedUID, beta); advance(1)
equal(NoteSync.pendingWrites[confirmedUID], true, "changing a confirmed friend creates fresh pending intent")
equal(NoteSync.syncReport ~= nil, true, "new pending edit invalidates the earlier bulk confirmation")
local prematureComplete = false
for _, message in ipairs(messages) do if message:find("complete", 1, true) then prematureComplete = true end end
equal(prematureComplete, false, "old confirmation cannot produce a premature completion message")
accounts[confirmedID].note = "memo#Alpha#Beta"; NoteSync:VerifyAllNotes(); advance(.2)
equal(NoteSync.syncReport, nil, "latest acknowledgement completes the current bulk generation")

-- Exercise both real modules together: enabling sync during accepted cleanup
-- writes must wait for those acknowledgements before importing/writing notes.
reset(3)
local resumed = create("Resumed")
env.BetterFriendlistDB.noteSyncPendingWrites = {}
for _, account in ipairs(accounts) do
	local uid = "bnet_" .. account.battleTag
	env.BetterFriendlistDB.friendGroups[uid] = { resumed }
	env.BetterFriendlistDB.noteSyncPendingWrites[uid] = true
end
setterMode = "pending"
NoteSync:Initialize(); advance(6)
local resumeStatus = assert(NoteSync:GetSyncStatus())
equal(resumeStatus.total, 3, "reload-resumed journal has visible progress without toggling sync")
equal(resumeStatus.waiting, 3, "resumed progress distinguishes submitted requests")
for _, account in ipairs(accounts) do account.note = "memo#Resumed" end
advance(6)
equal(NoteSync:GetSyncStatus(), nil, "resumed progress completes after actual confirmation")

-- Acceptance is not delivery: a previously accepted request must be observed,
-- including across reload and DB mutations, before a successor may be sent.
reset()
local acceptedGroup = create("Accepted")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", acceptedGroup)
local delivery = env.BetterFriendlistDB.noteSyncPendingWrites["bnet_Friend#1"]
equal(type(delivery), "table", "accepted delivery persists a local record instead of an unsent boolean")
equal(delivery.note, "memo#Accepted", "accepted record preserves exact submitted value")
equal(delivery.before, "memo", "accepted record preserves readable pre-write value")
NoteSync:CancelWork(); NoteSync.pendingWrites, NoteSync.inFlight = {}, {}
NoteSync:LoadPendingWrites(); assert(NoteSync:Enable()); advance(60)
equal(#writes, 1, "reload does not resubmit an already accepted delivery")
emit("BN_CONNECTED"); emit("BN_FRIEND_LIST_SIZE_CHANGED"); advance(10)
equal(#writes, 1, "roster reset does not erase acceptance or resubmit it")
accounts[1].note = "memo#Accepted"; NoteSync:VerifyAllNotes()
equal(NoteSync.pendingWrites["bnet_Friend#1"], nil, "reloaded delivery clears only after visible confirmation")
equal(env.BetterFriendlistDB.noteSyncPendingWrites, nil, "confirmed reloaded delivery clears private record")

reset()
acceptedGroup = create("Accepted")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", acceptedGroup)
DB:RemoveFriendFromGroup("bnet_Friend#1", acceptedGroup); advance(60)
equal(#writes, 1, "remove before add acknowledgement never duplicates the old request")
equal(NoteSync.pendingWrites["bnet_Friend#1"], true, "matching pre-add base state cannot falsely complete the later remove")
equal(NoteSync.inFlight["bnet_Friend#1"].note, "memo#Accepted", "local remove retains the earlier accepted value")
accounts[1].note = "memo#Accepted"; NoteSync:VerifyAllNotes(); advance(.2)
equal(#writes, 2, "old add acknowledgement dispatches the latest remove exactly once")
equal(writes[2][2], "memo", "successor targets latest DB membership")
advance(60)
equal(#writes, 2, "accepted remove also waits read-only for acknowledgement")
accounts[1].note = "memo"; NoteSync:VerifyAllNotes()
equal(NoteSync.pendingWrites["bnet_Friend#1"], nil, "visible latest remove finally completes intent")

reset()
acceptedGroup = create("Original")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", acceptedGroup)
assert(Groups:Rename(acceptedGroup, "Intermediate")); assert(Groups:Rename(acceptedGroup, "Latest"))
advance(20)
equal(#writes, 1, "multiple renames cannot replace or resend an accepted older delivery")
accounts[1].note = "memo#Original"; setterMode = "success"; NoteSync:VerifyAllNotes(); advance(.2)
equal(#writes, 2, "acknowledged older delivery gets one latest-goal successor")
equal(accounts[1].note, "memo#Latest", "renames coalesce to latest DB value after prior delivery")
equal(Groups:GetGroupIdByName("Intermediate"), nil, "accepted rename reconciliation never imports intermediate stale names")

reset(3)
local fair = create("Fair")
setterMode = "false"; DB:AddFriendToGroup("bnet_Friend#1", fair)
for index = 2, 3 do
	local uid = "bnet_Friend#" .. index
	env.BetterFriendlistDB.friendGroups[uid] = { fair }
	env.BetterFriendlistDB.noteSyncPendingWrites[uid] = true
end
NoteSync:LoadPendingWrites()
setterMode = "success"; NoteSync:StartDispatcher(); advance(.4)
equal(writes[2][1], 2, "first never-submitted loaded journal UID precedes a rejected retry")
equal(writes[3][1], 3, "next unsent journal UID keeps FIFO before eligible retries")
advance(6)
equal(accounts[1].note, "memo#Fair", "real false native rejection recovers after new work receives a turn")

reset()
acceptedGroup = create("BeforeImport")
setterMode = "pending"; DB:AddFriendToGroup("bnet_Friend#1", acceptedGroup)
local afterImport = create("AfterImport")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { afterImport }
NoteSync:OnDatabaseImported(); advance(10)
equal(#writes, 1, "profile restore cannot overtake an accepted local delivery")
accounts[1].note = "memo#BeforeImport"; setterMode = "success"; NoteSync:VerifyAllNotes(); advance(.2)
equal(accounts[1].note, "memo#AfterImport", "profile restore goal follows acknowledgement of older local work")
equal(#writes, 2, "profile restore submits latest goal only once after older delivery")

reset()
local passiveSaved = create("Saved")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { passiveSaved }
accounts[1].note = "memo#Alpha"; NoteSync.passiveQueued["bnet_Friend#1"] = true
local originalRead, freshReads = env.C_BattleNet.GetFriendAccountInfo, 0
env.C_BattleNet.GetFriendAccountInfo = function(index)
	freshReads = freshReads + 1
	if freshReads == 2 then accounts[index].note = "memo#Alpha#Remote" end
	return originalRead(index)
end
local _, _, changedReason = NoteSync:SyncSingleFriend("bnet_Friend#1")
env.C_BattleNet.GetFriendAccountInfo = originalRead
equal(changedReason, "changed", "fresh compare rejection is identified")
equal(#writes, 0, "fresh compare rejection never reached native setter")
equal(NoteSync.pendingWrites["bnet_Friend#1"], nil, "passive compare rejection creates no local authority")
equal(env.BetterFriendlistDB.noteSyncPendingWrites, nil, "passive compare rejection creates no authoritative journal")
advance(1)
equal(DB:IsFriendInGroup("bnet_Friend#1", "custom_remote"), true, "passive compare retry imports the newest remote group")
equal(accounts[1].note:find("Remote", 1, true) ~= nil, true, "passive compare retry preserves newest remote token")

env.C_Timer.After = function(delay, callback) return timer(delay, callback) end
env.time = function() return 12345 end
for key, value in pairs({ UNKNOWN = "Unknown", WIZARD_BACKUP_SUCCESS = "BACKUP %d", WIZARD_BACKUP_PARTIAL = "PARTIAL %d/%d",
	WIZARD_APPLY_SUCCESS = "APPLY %d", WIZARD_APPLY_FAILED = "FAILED %d/%d", WIZARD_NOTES_PENDING = "PENDING %d" }) do BFL.L[key] = value end
assert(loadfile(repo .. "/Modules/NoteCleanupWizard.lua", "t", env))("BetterFriendlist", BFL)
reset(6); NoteSync:Disable()
local wanted = create("Wanted")
for _, account in ipairs(accounts) do
	account.note = "memo#Old"
	env.BetterFriendlistDB.friendGroups["bnet_" .. account.battleTag] = { wanted }
end
setterMode = "delayed"
BFL.NoteCleanupWizard:ScanFriends(); BFL.NoteCleanupWizard:BackupNotes(); BFL.NoteCleanupWizard:ApplyCleanedNotes()
advance(3)
equal(#writes, 6, "wizard submitted its delayed cleanup before enabling sync")
equal(NoteSync:Enable(), true, "sync activation can wait for the cleanup owner")
advance(5)
equal(#writes, 6, "sync never competes with unconfirmed wizard writes")
equal(Groups:GetGroupIdByName("Old"), nil, "pending cleanup text is not imported as a new group")
advance(65)
for _, account in ipairs(accounts) do equal(account.note, "memo#Wanted", "activation proceeds after cleanup acknowledgement") end
equal(NoteSync.enablePending, false, "wizard completion releases pending sync activation")

reset(2); NoteSync:Disable()
wanted = create("Wanted")
for _, account in ipairs(accounts) do
	account.note = "memo#Old"
	env.BetterFriendlistDB.friendGroups["bnet_" .. account.battleTag] = { wanted }
end
setterMode = "pending"
BFL.NoteCleanupWizard:ScanFriends(); BFL.NoteCleanupWizard:BackupNotes(); BFL.NoteCleanupWizard:ApplyCleanedNotes()
advance(3); assert(NoteSync:Enable()); advance(15)
equal(NoteSync.waitingForWizard, true, "requested sync waits for unacknowledged wizard changes")
setterMode = "success"
equal(BFL.NoteCleanupWizard:BackupNotes(), true, "waiting activation does not block a fresh recovery backup")
equal(BFL.NoteCleanupWizard:ApplyCleanedNotes() ~= false, true, "waiting activation leaves same-operation retries available")
for _, account in ipairs(accounts) do account.note = "memo" end
advance(8)
for _, account in ipairs(accounts) do equal(account.note, "memo#Wanted", "pending wizard retry releases sync without disable or reload") end
equal(NoteSync.waitingForWizard, false, "successful retry clears the ownership wait")
equal(env.BetterFriendlistDB.noteBackup["bnet_Friend#1"].originalNote, "memo#Old", "retry keeps the pre-cleanup recovery copy")
BFL.L.WIZARD_STOPPED, BFL.L.WIZARD_RESTORE_SUCCESS, BFL.L.WIZARD_RESTORE_FAILED = "STOPPED", "RESTORE %d", "RESTORE_FAILED %d/%d"

reset()
local ownerAlpha = create("Alpha")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { ownerAlpha }; accounts[1].note = "memo#Alpha"
setterMode = "pending"; assert(Groups:Rename(ownerAlpha, "Beta")); NoteSync:Disable()
BFL.NoteCleanupWizard:ScanFriends(); BFL.NoteCleanupWizard:BackupNotes(); BFL.NoteCleanupWizard:ApplyCleanedNotes(); advance(.2)
equal(#writes, 1, "disabled sync retains an accepted barrier against opposite wizard cleanup")
accounts[1].note = "memo#Beta"; advance(2)
equal(#writes, 1, "cleanup requires a new recovery snapshot after another owner's acknowledgement")
equal(accounts[1].note, "memo#Beta", "opposite cleanup never silently overwrites newly delivered text")
BFL.NoteCleanupWizard:Stop()

reset(); NoteSync:Disable()
local ownerDesired = create("Desired")
env.BetterFriendlistDB.friendGroups["bnet_Friend#1"] = { ownerDesired }; accounts[1].note = "memo#Old"
setterMode = "pending"
BFL.NoteCleanupWizard:ScanFriends(); BFL.NoteCleanupWizard:BackupNotes(); BFL.NoteCleanupWizard:ApplyCleanedNotes(); advance(.2)
BFL.NoteCleanupWizard:Stop()
equal(env.BetterFriendlistDB.noteSyncPendingWrites["bnet_Friend#1"].deliveryOnly, true, "stopped wizard leaves a delivery-only receipt")
assert(NoteSync:Enable()); advance(9)
equal(#writes, 1, "sync activation cannot overtake stopped wizard accepted cleanup")
equal(NoteSync.pendingWrites["bnet_Friend#1"], nil, "wizard delivery-only load is never promoted to sync authority")
equal(Groups:GetGroupIdByName("Old"), nil, "activation does not import the unsafe pre-cleanup base")
accounts[1].note = "memo"; setterMode = "success"; NoteSync:VerifyAllNotes(); advance(.2)
equal(accounts[1].note, "memo#Desired", "sync goal follows actual cleanup acknowledgement")
equal(#writes, 2, "owner switch produces exactly one safe successor")

reset()
wowFriends = { { name = "Short", notes = "wow memo#Alpha", guid = "Player-1-SHORT" } }
local shortGroup = create("World")
setterMode = "pending"; DB:AddFriendToGroup("wow_Short-Realm", shortGroup); NoteSync:Disable()
local worldRecord = env.BetterFriendlistDB.noteSyncPendingWrites["wow_Short-Realm"]
equal(worldRecord.name, "Short", "accepted WoW journal preserves the raw identity name")
equal(worldRecord.guid, "Player-1-SHORT", "accepted WoW journal preserves the character GUID")
BFL.NoteCleanupWizard:ScanFriends(); BFL.NoteCleanupWizard:BackupNotes(); BFL.NoteCleanupWizard:ApplyCleanedNotes(); advance(.2)
equal(#writes, 1, "raw wizard name and realm-normalized sync UID share one accepted barrier")
BFL.NoteCleanupWizard:Stop()
BFL.NoteCleanupWizard = nil

io.write("PASS: " .. assertions .. " NoteSync assertions using production modules.\n")
