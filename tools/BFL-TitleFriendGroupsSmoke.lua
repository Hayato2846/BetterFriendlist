-- Exercise automatic Title Friend note migration using the production DB and note writers.
local root = assert(arg[1], "repository root required"):gsub("[\\/]$", "")
local modules, callbacks, messages, roster = {}, {}, {}, {}
local secret = {}
local writes, deferred, now = 0, nil, 0
local rejected, lastAttempt
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
	GetTime = function() return now end,
	C_Timer = { NewTimer = function() return { Cancel = function() end } end },
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
	if id == rejected then
		lastAttempt = note
		return false
	end
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
check(writes == 4 and token(newcomer), "a duplicate marker does not block linking a different contact")
check(not db:GetVerifiedTitleFriendToken("bnet_199", true), "duplicate markers never route edits or groups")
roster[5], roster[6] = newcomer, nil
titleNotes:Process()
local removedToken = token(newcomer)
check(db:AddFriendToGroup("bnet_224", "keep"), "save a group before its marker goes missing")
newcomer.note = "edited outside BFL"
local short = titleFriend(225, "short native note")
local hidden = titleFriend(secret, "")
roster[6], roster[7] = short, hidden
titleNotes:Process()
check(writes == 6 and token(short) and token(newcomer) ~= removedToken, "a missing saved marker and an unreadable ID do not block unrelated links")
check(newcomer.note:find("edited outside BFL", 1, true) and short.note:find("short native note", 1, true),
	"link a short native note immediately while preserving the original text")
check(#db:GetFriendGroups("bnet_224") == 0 and env.BetterFriendlistDB.friendGroups["bnet_title_" .. removedToken][1] == "keep",
	"keep old data available without assigning it to an unverified contact")
short.battleTag = secret
check(db:RequireFriendGroupKey("bnet_225") and notes.GetBNetDisplayNote(short) == "short native note",
	"the readable Title identity does not depend on the BattleTag")
check(db:ToggleFriendInGroup("bnet_225", "group1") and db:IsFriendInGroup("bnet_225", "group1"), "menu adds a linked friend")
check(db:ToggleFriendInGroup("bnet_225", "group1") and not db:IsFriendInGroup("bnet_225", "group1"), "menu removes a linked friend")
check(db:SetFriendGroups("bnet_225", { "group2" }, true) and db:AddFriendToGroup("bnet_225", "group1"), "move and add a second group")
check(db:RemoveFriendFromGroup("bnet_225", "group2") and db:SetFriendGroups("bnet_225", nil, true)
	and #db:GetFriendGroups("bnet_225") == 0, "remove individual and all memberships")

hidden.note = long.note
check(not db:GetVerifiedTitleFriendToken("bnet_199", true) and db:GetVerifiedTitleFriendToken("bnet_150"),
	"an unaddressable duplicate marker blocks only the colliding link")
roster[7] = titleFriend(225, "")
check(not db:GetVerifiedTitleFriendToken("bnet_225", true), "a duplicate live account ID cannot route either row")

local delayed = titleFriend(226, "")
roster[7], rejected = delayed, 226
titleNotes:Process()
local planned = lastAttempt
check(planned and writes == 7 and not token(delayed), "a rejected write remains unverified")
now = 1
titleNotes:Process()
check(writes == 7, "do not immediately repeat a rejected write")
now, rejected = 6, nil
titleNotes:Process()
check(writes == 8 and delayed.note == planned, "retry only the same marker after a fresh roster check")
titleNotes:Process()
check(db:RequireFriendGroupKey("bnet_226"), "the retried link becomes usable after confirmation")

titleNotes:SetEnabled(false)
titleNotes:Process()
check(long.note == "Updated note" and blank.note == "" and old.note == "old text", "return the current text to Blizzard")
check(short.note == "short native note" and newcomer.note == "edited outside BFL", "return inline notes without losing their text")
titleNotes:Process()
check(store.returning == nil and not store.enabled and not env.BetterFriendlistDB.friendGroups[legacyKey], "confirm return and clear links")
titleNotes:Process()
check(writes == 14 and not token(blank), "disabled mode never recreates IDs")
check(db:GetFriendGroups("bnet_Friend#1234")[1] == "regular", "ordinary group keys are untouched")
io.write("Title Friend note and group migration smoke passed.\n")
