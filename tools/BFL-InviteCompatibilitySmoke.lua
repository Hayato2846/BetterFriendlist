-- Run with Lua 5.4: lua tools/BFL-InviteCompatibilitySmoke.lua <repo> [Forever UI source] [Classic UI source]
-- Executes the actual changed source blocks with deterministic Battle.net data.
-- This is not a replacement for secure/taint and server-side checks in WoW.
local repoRoot = assert(arg[1], "repository root argument is required")
local separator = package.config:sub(1, 1)
local function read(root, path)
	local file = assert(io.open(root .. separator .. path:gsub("/", separator), "rb"))
	local contents = file:read("*a")
	file:close()
	return contents
end

local function between(source, first, last)
	local start = assert(source:find(first, 1, true), "missing source anchor: " .. first)
	local finish = assert(source:find(last, start + #first, true), "missing source anchor: " .. last)
	return source:sub(start, finish - 1)
end

local BFL = { L = {} }
local env = setmetatable({ BFL = BFL }, { __index = _G })
env.SlashCmdList = {}
env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_CAMELOT = 1, 2, 18
env.BNET_CLIENT_WOW, env.BNET_CLIENT_APP = "WoW", "App"
env.Enum = { GameMode = { Standard = 0, Plunderstorm = 1, WoWHack = 2 } }
env.UnitFactionGroup = function() return "Alliance" end
env.GetNativeRealmID = function() return 100 end
env.max = math.max
local activeMode, crossFaction, questSession = 0, false, false
env.C_GameRules = { GetActiveGameMode = function() return activeMode end }
env.C_PartyInfo = { CanFormCrossFactionParties = function() return crossFaction end }
env.C_QuestSession = { Exists = function() return questSession end }
local accounts, calls = {}, {}
env.C_BattleNet = {
	GetFriendNumGameAccounts = function() return #accounts end,
	GetFriendGameAccountInfo = function(_, index) return accounts[index] end,
}
env.BNGetNumFriendGameAccounts = function() return #accounts end
env.BNGetFriendGameAccountInfo = function(_, index)
	local ga = accounts[index]
	local fields = { [1] = true, [2] = ga.characterName, [3] = ga.clientProgram,
		[4] = ga.realmName, [5] = ga.realmID, [6] = ga.factionName, [20] = ga.playerGuid, [21] = ga.wowProjectID }
	return table.unpack(fields, 1, 21)
end
local function execute(source, name)
	return assert(load(source, "@" .. name, "t", env))("BetterFriendlist", BFL)
end

local core = read(repoRoot, "Core.lua")
execute(between(core, "function BFL.ResolveClientFlavor(", "local clientFlavor ="), "Core.lua")
execute(read(repoRoot, "Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")

local assertions = 0
local V = {}
function V:Assert(value, message)
	assertions = assertions + 1
	assert(value, message)
end
function V:AssertEqual(actual, expected, message)
	self:Assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local currentForever = BFL.ResolveClientFlavor(16001, 18, 1, 2, 18)
V:Assert(currentForever.isMainline and currentForever.isForever and not currentForever.isClassic,
	"Camelot project 18 must resolve as Forever/Mainline, not Classic Era")
function BFL:RegisterModule(_, module) return module end
local suite = execute(read(repoRoot, "Modules/TestSuite.lua"), "Modules/TestSuite.lua")
local tests = {}
function suite:RegisterTest(_, name, test) tests[name] = test end
suite:RegisterForeverCompatibilityTests()
tests.Forever_ClientFamilyMatrix.action(V)
tests.Forever_BNetInviteRealmGate.action(V)

local friendsSource = read(repoRoot, "Modules/FriendsList.lua")
local constants = between(friendsSource, "local INVITE_RESTRICTION_NONE =", "-- Helper Functions")
local statusBlock = between(friendsSource, "-- PHASE 4 OPTIMIZATION: Pre-calculate Invite Status", "-- The setting is explicitly mobile-only")
local updateStatus = execute(constants .. "\nreturn function(friend, accountInfo, i)\n" .. statusBlock .. "\nend", "FriendsList invite status")

local mainSource = read(repoRoot, "BetterFriendlist.lua")
local modeCheck = between(mainSource, "local CLASS_ID_TO_GAME_MODE =", "-- Multi-Game-Account Invite Picker")
execute(modeCheck .. between(mainSource, "function BetterFriendsList_TravelPassButton_OnClick(", "function BetterFriendsList_TravelPassButton_OnEnter("), "TravelPassButton_OnClick")
env.BNGetNumFriends = function() return 1 end
BFL.IsBattleNetFriendsListEnabled = function() return true end
BFL.GetBNetFriendInfo = function() return { bnetAccountID = 42 } end
env.FriendsFrame_InviteOrRequestToJoin = function(guid, id) calls[#calls + 1] = { guid = guid, id = id } end
env.FriendsFrame_SetupTravelPassDropdown = function() calls[#calls + 1] = { picker = true } end

local friend, inviteType = nil, "INVITE"
local FriendsList = {}
env.GetFriendsList = function() return FriendsList end
function FriendsList:BuildAccountDisplay(ga)
	return { gameAccountID = ga.gameAccountID, playerGuid = ga.playerGuid, text = ga.characterName, isInvitable = ga.bflIsInvitable }
end
-- Load the existing picker with the click handler so both share its local.
execute(modeCheck .. between(mainSource, "local function GetInviteRestrictionText(", "BFL.ShowMultiAccountInvitePicker =")
	.. between(mainSource, "function BetterFriendsList_TravelPassButton_OnClick(", "local inviteTypeToButtonText ="), "TravelPass picker and click")
BFL.OpenSimpleContextMenu = function(_, _, items) calls[#calls + 1] = { picker = true, items = items } end
env.BFL_FindBNetFriendData = function() return friend, FriendsList end
env.BFL_GetDisplayedInviteTypeSafe = function() return inviteType end
env.GetDisplayedInviteType = env.BFL_GetDisplayedInviteTypeSafe
env.BFL_GetInviteButtonText = function(value) return value end
env.BFL_InvokeBNetInviteOrRequest = execute(between(mainSource, "local function BFL_InvokeBNetInviteOrRequest(", "-- Multi-Game-Account: Replace Blizzard") .. "\nreturn BFL_InvokeBNetInviteOrRequest", "BNet invite dispatch")
local addInviteButton = execute(between(mainSource, "local function BFL_AddInviteButton(", "local function BFL_GetBNetAccountInfo(") .. "\nreturn BFL_AddInviteButton", "BNet context invite")
local function menu()
	local root = { buttons = {} }
	function root:CreateButton(text, callback)
		local button = menu()
		button.text, button.callback = text, callback
		self.buttons[#self.buttons + 1] = button
		return button
	end
	return root
end

-- Optionally compare the data-layer decision with Blizzard's real Camelot implementation.
local nativeRestriction, nativeClassicRestriction
if arg[2] then
	local nativeSource = read(arg[2], "Interface/AddOns/Blizzard_FriendsFrame/Camelot/FriendsFrame.lua")
	local nativeConstants = between(nativeSource, "local INVITE_RESTRICTION_NO_GAME_ACCOUNTS =", "local FriendListEntries =")
	env.playerFactionGroup, env.playerRealmID = "Alliance", 100
	env.CanInviteByGameMode = execute(between(nativeSource, "local CLASS_ID_TO_GAME_MODE =", "local function ShouldGameModeShowRichPresence(") .. "\nreturn CanInviteByGameMode", "native game mode guard")
	nativeRestriction = execute(nativeConstants .. between(nativeSource, "function FriendsFrame_GetInviteRestriction(", "function FriendsFrame_GetInviteRestrictionText(") .. "\nlocal getRestriction = FriendsFrame_GetInviteRestriction\nreturn function(index) return getRestriction(index) == INVITE_RESTRICTION_NONE end", "Blizzard Camelot invite restriction")
end
if arg[3] then
	local nativeSource = read(arg[3], "Interface/AddOns/Blizzard_UIPanels_Game/Classic/FriendsFrame.lua")
	local nativeConstants = between(nativeSource, "local INVITE_RESTRICTION_NO_GAME_ACCOUNTS =", "local FriendListEntries =")
	env.playerFactionGroup, env.playerNativeRealmID = "Alliance", 100
	nativeClassicRestriction = execute(nativeConstants .. between(nativeSource, "function FriendsFrame_GetInviteRestriction(", "function FriendsFrame_GetInviteRestrictionText(") .. "\nlocal getRestriction = FriendsFrame_GetInviteRestriction\nreturn function(index) return getRestriction(index) == INVITE_RESTRICTION_NONE end", "Blizzard Classic invite restriction")
end

local function account(overrides)
	local ga = { clientProgram = "WoW", wowProjectID = 18, realmID = 200, isInCurrentRegion = true,
		factionName = "Alliance", playerGuid = "Player-200-1", gameAccountID = 99, characterName = "Friend", classID = 1 }
	for key, value in pairs(overrides or {}) do ga[key] = value end
	return ga
end
local function check(name, project, list, expected, count)
	accounts = list
	env.WOW_PROJECT_ID = project
	local interfaces = { [18] = 16001, [1] = 120105, [2] = 11509, [5] = 20506, [11] = 30405, [14] = 40402, [19] = 50504 }
	local flavor = BFL.ResolveClientFlavor(interfaces[project], project, 1, 2, 18)
	BFL.IsClassic, BFL.IsForever, BFL.IsMainline = flavor.isClassic, flavor.isForever, flavor.isMainline
	friend = { type = "bnet", bnetAccountID = 42, connected = true }
	updateStatus(friend, { gameAccountInfo = accounts[1] }, 1)
	V:AssertEqual(friend.canInvite, expected, name .. " enabled state")
	V:AssertEqual(friend.numInvitableAccounts, count, name .. " validated account count")
	local native = BFL.IsClassic and nativeClassicRestriction or (not BFL.IsClassic and nativeRestriction)
	if native then
		V:AssertEqual(friend.canInvite, native(1), name .. " Blizzard parity")
	end
	local root = menu()
	addInviteButton(root, { bnetIDAccount = 42 }, true, false)
	V:AssertEqual(#root.buttons, expected and 1 or 0, name .. " context entry")
	if expected then
		calls = {}
		if count == 1 then
			root.buttons[1].callback()
			V:AssertEqual(calls[1].id, friend.invitableAccounts[1].gameAccountID, name .. " menu dispatch")
			env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
			V:AssertEqual(calls[2].id, friend.invitableAccounts[1].gameAccountID, name .. " row dispatch")
		else
			V:AssertEqual(#root.buttons[1].buttons, count, name .. " picker entries")
		end
	end
end

check("Forever cross realm, single login", 18, { account() }, true, 1)
check("Forever same realm", 18, { account({ realmID = 100 }) }, true, 1)
check("Retail cross realm", 1, { account({ wowProjectID = 1 }) }, true, 1)
for _, classic in ipairs({ { "Era", 2 }, { "TBC", 5 }, { "Wrath", 11 }, { "Cata", 14 }, { "Mists", 19 } }) do
	check(classic[1] .. " cross realm", classic[2], { account({ wowProjectID = classic[2] }) }, false, 0)
	check(classic[1] .. " same realm", classic[2], { account({ wowProjectID = classic[2], realmID = 100 }) }, true, 1)
end
check("Different WoW project", 18, { account({ wowProjectID = 1 }) }, false, 0)
check("Different region", 18, { account({ isInCurrentRegion = false }) }, false, 0)
check("Missing realm", 18, { account({ realmID = 0 }) }, false, 0)
check("No game accounts", 18, {}, false, 0)
check("App only", 18, { account({ clientProgram = "App" }) }, false, 0)
check("Two WoW logins", 18, { account(), account({ gameAccountID = 100 }) }, true, 2)
check("WoW and App", 18, { account(), account({ clientProgram = "App" }) }, true, 1)
check("One incompatible WoW login", 18, { account({ wowProjectID = 1 }), account() }, true, 1)
check("No cross faction capability", 18, { account({ factionName = "Horde" }) }, false, 0)
crossFaction = true
check("Cross faction supported", 18, { account({ factionName = "Horde" }) }, true, 1)
questSession = true
check("Quest session blocks cross faction", 18, { account({ factionName = "Horde" }) }, false, 0)
questSession = false
check("Different game mode", 18, { account({ classID = 14 }) }, false, 0)
activeMode = 1
check("Same special game mode", 18, { account({ classID = 14 }) }, true, 1)
activeMode, inviteType = 0, "REQUEST_INVITE"
check("Request to join", 18, { account() }, true, 1)

-- The native dropdown uses FriendsFrame OnShow faction locals, which are not
-- initialized when BFL replaces that frame. The row must use the BFL picker.
env.FriendsFrame_SetupTravelPassDropdown = function() error("Hidden native FriendsFrame dropdown must not be used") end
inviteType = "INVITE"
accounts = { account(), account({ gameAccountID = 100 }) }
calls = {}
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:AssertEqual(#calls[1].items, 3, "Fresh multi-account picker has a title and two eligible accounts")
V:Assert(not calls[1].items[2].disabled and not calls[1].items[3].disabled, "Fresh accounts remain enabled without native cached faction data")
calls[1].items[3].func()
V:AssertEqual(calls[2].id, 100, "Row picker dispatches the selected account")

local gameAccountAPI = env.C_BattleNet.GetFriendGameAccountInfo
env.C_BattleNet.GetFriendGameAccountInfo = function(_, index) if index == 1 then return nil end; return accounts[index] end
calls = {}
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:AssertEqual(calls[1].id, 100, "An account disappearing during a click does not prevent inviting the remaining one")
env.C_BattleNet.GetFriendGameAccountInfo = gameAccountAPI
accounts = { account({ wowProjectID = 1 }) }
calls = {}
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:AssertEqual(#calls, 0, "A now-incompatible account does not open the hidden native dropdown")
friend.connected = false
accounts = { account() }
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:AssertEqual(#calls, 0, "An offline row cannot dispatch a stale invite")
friend.connected = true
updateStatus(friend, { gameAccountInfo = accounts[1] }, 1)

-- The older-client dispatcher still distinguishes requests from direct invites.
env.FriendsFrame_InviteOrRequestToJoin = nil
inviteType = "REQUEST_INVITE"
env.BNRequestInviteFriend = function(id) calls[#calls + 1] = { id = id, request = true } end
BFL.BNInviteFriend = function(id) calls[#calls + 1] = { id = id, invite = true } end
calls = {}
local root = menu()
addInviteButton(root, { bnetIDAccount = 42 }, true, false)
root.buttons[1].callback()
V:Assert(calls[1].request, "Legacy request-to-join uses BNRequestInviteFriend")
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:Assert(calls[2].request, "Legacy row request-to-join uses BNRequestInviteFriend")
inviteType = "INVITE"
root = menu()
addInviteButton(root, { bnetIDAccount = 42 }, true, false)
root.buttons[1].callback()
V:Assert(calls[3].invite, "Legacy direct invite uses BFL.BNInviteFriend")
env.BetterFriendsList_TravelPassButton_OnClick({ friendData = friend })
V:Assert(calls[4].invite, "Legacy row direct invite uses BFL.BNInviteFriend")
io.write("[OK] Invite compatibility smoke: " .. assertions .. " assertions" .. (nativeRestriction and ", including Blizzard Camelot parity" or "") .. (nativeClassicRestriction and " and Classic parity" or "") .. "\n")
