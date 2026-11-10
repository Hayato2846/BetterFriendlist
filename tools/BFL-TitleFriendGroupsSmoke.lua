-- Exercise automatic Title Friend note migration using the production DB and note writers.
local root = assert(arg[1], "repository root required"):gsub("[\\/]$", "")
local modules, callbacks, messages, roster = {}, {}, {}, {}
local secret = {}
local writes, deferred = 0, nil
local BFL = {
	IsForever = true,
	AreTitleFriendsEnabled = function() return true end,
	IsSecret = function(_, value) return value == secret end,
	IsTitleFriend = function(info) return info.friendLevel == 3 end,
	RegisterModule = function(_, name, module) modules[name] = module; return module end,
	GetModule = function(_, name) return modules[name] end,
	RegisterEventCallback = function(_, event, callback) callbacks[event] = callback end,
	L = setmetatable({}, { __index = function(_, key) return key end }),
}
local store = { enabled = true, notes = {}, originals = {}, backups = {}, active = {} }
local legacyKey, legacyToken = "bnet_title_ABCD2345", "ABCD2345"
local env = setmetatable({
	Enum = { BattleNetFriendLevel = { Title = 3 } },
	BetterFriendlistDB = {
		titleFriendNotes = store,
		friendGroups = { bnet_150 = { "orphan" }, [legacyKey] = { "group2" },
			["bnet_title_name:Old Name"] = { "orphan" }, ["bnet_Friend#1234"] = { "regular" } },
	},
	BNGetNumFriends = function() return #roster end,
	C_Timer = { NewTimer = function(_, callback) return callback end },
	StaticPopupDialogs = {},
	StaticPopup_Show = function(name) assert(name == "BFL_SET_TITLE_FRIEND_NOTE") end,
	print = function(message) messages[#messages + 1] = message end,
}, { __index = _G })
env._G = env
local function loadProduction(path)
	assert(loadfile(root .. "/" .. path, "t", env))("BetterFriendlist", BFL)
end
local function titleFriend(id, note)
	return { bnetAccountID = id, isFriend = true, friendLevel = 3, accountName = secret, note = note, battleTag = "" }
end
local fullNote = string.rep("ä", 127)
local long = titleFriend(150, fullNote)
local blank = titleFriend(77, "")
local old = titleFriend(82, "old text [BFL:" .. legacyToken .. "]")
local regular = { bnetAccountID = 80, battleTag = "Friend#1234", note = "unrelated" }
roster = { long, blank, old, regular }
BFL.GetBNetFriendInfo = function(index) return roster[index] end
env.C_BattleNet = { GetFriendAccountInfo = BFL.GetBNetFriendInfo }
env.BNSetFriendNote = function(id, note)
	writes = writes + 1
	for _, account in ipairs(roster) do
		if account.bnetAccountID == id then
			if deferred then deferred[account] = note else account.note = note end
			return
		end
	end
	error("wrong contact")
end
loadProduction("Utils/FriendNotes.lua")
loadProduction("Modules/Database.lua")
local notes, db = BFL.FriendNotes, modules.DB
local function relog()
	db:ClearTitleFriendGroupKeys()
	loadProduction("Modules/TitleFriendNotes.lua")
	return BFL.TitleFriendNotes
end
local titleNotes = relog()
local function token(account)
	return select(2, notes.SplitTitleGroupNote(account.note))
end

local function check(condition, description)
	assert(condition, description)
end
check(callbacks.PLAYER_ENTERING_WORLD and callbacks.BN_FRIEND_LIST_SIZE_CHANGED, "migration starts from roster events")
long.note = secret
titleNotes:Process()
check(writes == 0 and next(store.backups) == nil, "wait for a readable Title Friend roster")
long.note = fullNote
titleNotes:Process()
check(writes == 1 and token(blank) and long.note == fullNote and old.note:find("old text", 1, true), "blank notes enroll now and original text waits for a save")
check(next(store.backups) ~= nil and store.notes[legacyToken] == "old text", "back up old text")
check(#db:GetFriendGroups("bnet_150") == 0 and db:GetFriendGroups("bnet_82")[1] == "group2", "keep only marker-backed assignments")
titleNotes:Process()
check(writes == 1, "an in-memory backup cannot authorize replacement")
local blankToken = token(blank)
check(db:AddFriendToGroup("bnet_77", "group1"), "assign a group by ID")
check(env.BetterFriendlistDB.friendGroups["bnet_title_" .. blankToken][1] == "group1", "persist the group against the marker")

titleNotes = relog()
long.bnetAccountID, blank.bnetAccountID = 199, 150
deferred = {}
titleNotes:Process()
check(writes == 3 and long.note == fullNote and deferred[long], "after relog migrate even a full note, waiting for native confirmation")
titleNotes:Process()
check(writes == 3, "don't submit a second write while the server has not confirmed")
for account, note in pairs(deferred) do account.note = note end
deferred = nil
local longToken = token(long)
check(longToken and #longToken == 14 and old.note == "[BFL:" .. legacyToken .. "]", "Blizzard holds only the marker")

-- Simulate a crash after the server saved the marker but before WoW saved its local row.
store.notes[longToken] = nil
titleNotes = relog()
check(notes.GetBNetDisplayNote(long) == fullNote, "recover exact original text from the previously saved backup")
titleNotes:Process()
check(db:GetFriendGroups("bnet_150")[1] == "group1" and #db:GetFriendGroups("bnet_199") == 0, "new session IDs don't change group identity")
check(env.BetterFriendlistDB.friendGroups.bnet_150[1] == "orphan", "keep ambiguous old data for recovery")
check(notes.GetBNetDisplayNote(regular) == "unrelated", "normal friends keep their native notes")
check(titleNotes:ShowEditor(199, "Title Friend"), "normal menu opens the BFL note editor")
local popup = env.StaticPopupDialogs.BFL_SET_TITLE_FRIEND_NOTE
local editor = { editBox = {
	SetText = function(_, value) check(value == fullNote, "the editor starts with the recovered note") end,
	SetFocus = function() end, HighlightText = function() end,
	GetText = function() return "Updated note" end,
} }
popup.OnShow(editor)
popup.OnAccept(editor)
check(store.notes[longToken] == "Updated note" and notes.GetBNetDisplayNote(long) == "Updated note", "local note saves to the same link")
check(writes == 3 and long.note == "[BFL:" .. longToken .. "]", "editing the local note leaves the native ID alone")
check(notes.WriteBNetNote("bnet_199", "Group sync text", long.note) == false, "generic writers can't edit managed Title Friend notes")

local duplicate = titleFriend(206, long.note)
local newcomer = titleFriend(224, "")
roster[5], roster[6] = duplicate, newcomer
titleNotes:Process()
check(writes == 3 and not db:GetVerifiedTitleFriendToken("bnet_199", true), "duplicate markers never route edits or groups")
roster[5], roster[6] = newcomer, nil
titleNotes:Process()
check(writes == 4 and token(newcomer), "new Title Friends enroll automatically")
titleNotes:Process()
newcomer.note = "edited outside BFL"
roster[6] = titleFriend(225, "")
titleNotes:Process()
check(writes == 4 and newcomer.note == "edited outside BFL", "don't guess which unmarked contact lost a known marker")
roster[6] = nil

titleNotes:SetEnabled(false)
titleNotes:Process()
check(long.note == "Updated note" and blank.note == "" and old.note == "old text", "return the current text to Blizzard")
titleNotes:Process()
check(store.returning == nil and not store.enabled and not env.BetterFriendlistDB.friendGroups[legacyKey], "confirm return and clear links")
titleNotes:Process()
check(writes == 7 and not token(blank), "disabled mode never recreates IDs")
check(db:GetFriendGroups("bnet_Friend#1234")[1] == "regular", "ordinary group keys are untouched")
io.write("Title Friend note and group migration smoke passed.\n")
