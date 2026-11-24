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
local shown, inCombat, scheduled = false, false, nil
env.BetterFriendsFrame = { IsShown = function() return shown end }
env.InCombatLockdown = function() return inCombat end
env.C_Timer.NewTimer = function(_, callback)
	scheduled = callback
	return { Cancel = function() scheduled = nil end }
end
local liveProcess, passes = titleNotes.Process, 0
titleNotes.Process = function() passes = passes + 1 end
for _ = 1, 100 do callbacks.BN_FRIEND_INFO_CHANGED() end
callbacks.PLAYER_REGEN_ENABLED()
check(scheduled == nil and passes == 0, "Closed-window events never schedule an automatic roster scan")
shown = true
titleNotes:ResumeProcessing()
check(scheduled ~= nil, "Opening the list schedules deferred maintenance")
local scan = scheduled
scheduled, shown = nil, false
scan()
check(passes == 0, "A timer queued before closing cannot scan the hidden roster")
shown, inCombat = true, true
titleNotes:ResumeProcessing()
check(scheduled == nil, "Combat defers automatic maintenance")
inCombat = false
callbacks.PLAYER_REGEN_ENABLED()
scan, scheduled = scheduled, nil
scan()
callbacks.PLAYER_REGEN_ENABLED()
check(passes == 1 and scheduled == nil, "Combat recovery runs once and ordinary combat exits do no work")
titleNotes.Process = liveProcess
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
env.BetterFriendlistDB.nicknames = { bnet_77 = "Unverified previous-session nickname" }
local blankToken = token(blank)
check(db:AddFriendToGroup("bnet_77", "group1"), "assign a group by ID")
check(env.BetterFriendlistDB.friendGroups["bnet_title_" .. blankToken][1] == "group1", "persist the group against the marker")
check(db:GetNickname("bnet_77") == nil, "a session-only ID cannot supply an old nickname")
check(db:SetNickname("bnet_unknown", "Wrong target") == false, "an unknown contact cannot receive a shared nickname")
local blankNicknameKey = db:GetNicknameKey("bnet_77")
check(db:SetNickname("bnet_77", "Verified nickname", blankNicknameKey), "save the nickname with the same unique marker")
check(db:GetNickname("bnet_77") == "Verified nickname", "the verified Title Friend displays its nickname")

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
check(db:GetNickname("bnet_150") == "Verified nickname" and db:GetNickname("bnet_199") == nil,
	"the nickname follows the Title Friend across session ID changes")
check(db:SetNickname("bnet_199", "Wrong contact", blankNicknameKey) == false,
	"confirming the edit cannot overwrite a different Title Friend's nickname")
check(env.BetterFriendlistDB.nicknames.bnet_77 == "Unverified previous-session nickname",
	"ambiguous old nicknames stay stored")
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

-- Use the production drag callbacks and database together. Friend rows carry
-- their group ID too, so relying on that field alone accepts invisible drops.
store.enabled = true
titleNotes = relog()
blank.note = notes.AppendTitleGroupToken("", blankToken)
roster = { blank, regular }
loadProduction("Modules/FriendsList.lua")
local list = modules.FriendsList
local hovered, shift = nil, false
local refreshes = 0
list.ShowFriendDragGhost = function() end
BFL.IsRegionMouseOver = function(_, frame) return hovered == frame end
BFL.ForceRefreshFriendsList = function() refreshes = refreshes + 1 end
env.GetCursorPosition = function() return 0, 0 end
env.UIParent = { GetEffectiveScale = function() return 1 end }
env.BFL_Tooltip = { Hide = function() end }
env.IsShiftKeyDown = function() return shift end
local function region()
	return {
		Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end,
		IsShown = function(self) return self.shown ~= false end,
		IsVisible = function(self) return self:IsShown() and not self.parentHidden end,
	}
end
local function groupHeader(id)
	local header = region()
	header.groupId, header.elementData, header.dropHighlight = id, { count = 1 }, region()
	header.dropHighlight:Hide()
	return header
end
local function friendRow(friend)
	local row = region()
	row.friendData, row.dragOverlay, row.scripts = friend, region(), {}
	row.Name = { GetText = function() return friend.displayName or friend.name end }
	list:BindFriendGroupAction(row, list:GetFriendUID(friend), friend.rawNote)
	row.dragOverlay:Hide()
	function row:SetAlpha(alpha) self.alpha = alpha end
	function row:SetScript(event, handler) self.scripts[event] = handler end
	return row
end
local first, second, noGroup = groupHeader("group1"), groupHeader("group2"), groupHeader("nogroup")
local favorites = groupHeader("favorites")
local tagHeader = groupHeader("tag:inherited")
local titleRow = friendRow({ type = "bnet", name = "Title Friend", friendLevel = 3,
	bnetAccountID = blank.bnetAccountID, rawNote = blank.note })
local otherRow = friendRow({ type = "bnet", name = "BattleTag Friend", battleTag = regular.battleTag })
otherRow.groupId = "group1"
local frames = { first, second, noGroup, favorites, tagHeader, titleRow, otherRow }
modules.Groups = { GetAll = function()
	return { group1 = { name = "First" }, group2 = { name = "Second" },
		nogroup = { name = "No Group", builtin = true }, favorites = { name = "Favorites", builtin = true } }
end }
list.scrollBox = { GetFrames = function() return frames end }
function list:UpdateGroupHeaderButton(header) header.restored = true end
local function drag(row, target, keepExisting)
	hovered, shift = target, keepExisting
	list.OnDragStart(row)
	list.OnDragUpdate(row)
	list.OnDragStop(row)
end
local uid = "bnet_" .. blank.bnetAccountID
check(db:SetFriendGroups(uid, { "group1", "group2" }), "prepare two group assignments")
drag(titleRow, otherRow, false)
check(#db:GetFriendGroups(uid) == 2 and refreshes == 0, "dropping over a friend row never replaces memberships")
drag(titleRow, second, false)
check(#db:GetFriendGroups(uid) == 1 and db:IsFriendInGroup(uid, "group2"), "dropping on a group header moves the Title Friend")
drag(titleRow, first, true)
check(#db:GetFriendGroups(uid) == 2, "Shift-drop adds a Title Friend without removing the previous membership")
drag(titleRow, favorites, false)
check(#db:GetFriendGroups(uid) == 2, "built-in favorites is not a drop target")
drag(titleRow, tagHeader, false)
drag(titleRow, nil, false)
check(#db:GetFriendGroups(uid) == 2, "virtual tag groups and empty space are not drop targets")
first.parentHidden = true
drag(titleRow, first, false)
check(#db:GetFriendGroups(uid) == 2, "a header under a hidden parent is not a drop target")
first.parentHidden = nil
drag(titleRow, noGroup, true)
check(#db:GetFriendGroups(uid) == 0, "dropping on No Group clears every membership, even with Shift")

check(db:AddFriendToGroup(uid, "group2"), "prepare a group before the row is recycled")
hovered = first
first.restored = nil
list.OnDragStart(titleRow)
list.OnDragUpdate(titleRow)
check(first.dropHighlight:IsShown(), "the hovered custom group is highlighted")
list.OnDragStop(otherRow)
check(first.dropHighlight:IsShown() and titleRow.scripts.OnUpdate, "release from a different row leaves the real drag intact")
local originalFriend = titleRow.friendData
titleRow.friendData = otherRow.friendData
list.OnDragStop(titleRow)
check(not first.dropHighlight:IsShown() and first.restored and not titleRow.scripts.OnUpdate
	and titleRow.alpha == 1 and not titleRow.dragOverlay:IsShown(), "a recycled source clears all drag feedback")
check(db:IsFriendInGroup(uid, "group2") and db:IsFriendInGroup("bnet_Friend#1234", "regular"),
	"a recycled source cannot change either friend")
titleRow.friendData = originalFriend

local originalNote = blank.note
local menuKey = titleRow.bflGroupActionKey
list.OnDragStart(titleRow)
blank.note = notes.AppendTitleGroupToken("", "BBBBBBBB")
list.OnDragStop(titleRow)
check(#db:GetFriendGroups(uid) == 0, "a replacement Title link on the same numeric ID cannot receive the old drop")
check(not db:ToggleFriendInGroup(uid, "group1", menuKey) and not db:SetFriendGroups(uid, nil, true, menuKey)
	and not db:RequireFriendGroupKey(uid, menuKey), "an open menu or create dialog cannot act on a replacement link")
blank.note = originalNote
check(db:RequireFriendGroupKey(uid) and db:IsFriendInGroup(uid, "group2"), "rejected drop preserves the original linked membership")

check(titleNotes:ShowEditor(blank.bnetAccountID, "Displayed Title Friend", menuKey), "open the editor for the current link")
local heldPopup = env.StaticPopupDialogs.BFL_SET_TITLE_FRIEND_NOTE
local savedText = store.notes[blankToken]
roster[1] = titleFriend(blank.bnetAccountID, notes.AppendTitleGroupToken("", "CCCCCCCC"))
check(titleNotes:ShowEditor(blank.bnetAccountID, "Displayed Title Friend", menuKey)
	and env.StaticPopupDialogs.BFL_SET_TITLE_FRIEND_NOTE == heldPopup, "a stale displayed row cannot open the replacement note")
heldPopup.OnAccept(editor)
check(store.notes[blankToken] == savedText and store.notes.CCCCCCCC == nil, "an open editor cannot save across a link replacement")
drag(titleRow, first, false)
check(#db:GetFriendGroups(uid) == 0 and not titleRow.scripts.OnUpdate,
	"a replacement before mouse-down cannot take over a drag from the old displayed row")
list:BindFriendGroupAction(titleRow, uid, roster[1].note)
drag(titleRow, first, false)
check(db:IsFriendInGroup(uid, "group1"), "the same row becomes actionable after rendering the new link")
check(not db:IsFriendInGroup(uid, "group1", menuKey), "an old menu cannot display the replacement contact's membership")
roster[1] = blank
list:BindFriendGroupAction(titleRow, uid, blank.note)
check(db:RequireFriendGroupKey(uid) and db:IsFriendInGroup(uid, "group2"), "rendering a replacement never moves the old friend's memberships")

hovered = first
list.OnDragStart(titleRow)
list.OnDragUpdate(titleRow)
list:BindFriendGroupAction(titleRow, uid, blank.note)
check(first.dropHighlight:IsShown() and titleRow.scripts.OnUpdate, "rebinding the same displayed identity preserves an active drag")
list.CancelFriendDrag(titleRow) -- OnHide is wired to this handler in both list paths.
list.OnDragStop(titleRow)
check(not first.dropHighlight:IsShown() and db:IsFriendInGroup(uid, "group2"), "hiding the source cancels even over a valid target")

BFL.IsForever = false
drag(otherRow, first, false)
drag(otherRow, second, true)
check(#db:GetFriendGroups("bnet_Friend#1234") == 2, "Retail ScrollBox uses the BattleTag for move and Shift-add")
drag(otherRow, noGroup, false)
check(#db:GetFriendGroups("bnet_Friend#1234") == 0, "Retail ScrollBox supports ungrouping")

-- Classic uses the header pool and persistent character UIDs.
BFL.IsClassic = true
BFL.NormalizeWoWFriendName = function(_, name) return name end
list.classicHeaderPool = { first, second, noGroup }
local character = friendRow({ type = "wow", name = "Character-Realm" })
drag(character, first, false)
drag(character, second, true)
check(#db:GetFriendGroups("wow_Character-Realm") == 2, "Classic pool supports move and Shift-add")
drag(character, noGroup, false)
check(#db:GetFriendGroups("wow_Character-Realm") == 0, "Classic pool supports ungrouping")
io.write("Friend row drag and drop smoke passed.\n")

BFL.IsForever, BFL.IsClassic = true, false
loadProduction("Utils/FriendActions.lua")
local actions = BFL.FriendActions
env.C_BattleNet.GetAccountInfoByID = function(id)
	for _, entry in ipairs(roster) do if entry.bnetAccountID == id then return entry end end
end
local titleAction = actions.Capture({ type = "bnet", accountInfo = blank })
check(titleAction.groupKey == menuKey and actions.Resolve(titleAction) == blank, "a displayed Title link resolves the live contact")
roster[1] = titleFriend(blank.bnetAccountID, notes.AppendTitleGroupToken("", "DDDDDDDD"))
check(not actions.Resolve(titleAction), "the same numeric ID with a different Title link cannot receive a social action")
roster[1], roster[3] = blank, titleFriend(301, blank.note)
check(not actions.Resolve(titleAction), "duplicate Title links cannot authorize social actions")
roster[3] = nil
check(actions.Resolve(titleAction) == blank, "actions recover when the original link is unique again")
