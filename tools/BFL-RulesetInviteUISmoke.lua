-- lua tools/BFL-RulesetInviteUISmoke.lua <repo> <Forever UI source>
-- Production model/menu/row/hover/Broker callbacks with real compatibility and
-- native invite-selection helpers. No live protected execution or server ACK.
local repo, native = assert(arg[1]), assert(arg[2])
local file = assert(io.open(repo .. "/tools/BFL-RulesetInviteSmoke.lua", "rb"))
local fixture = file:read("*a"); file:close()
local boundary = assert(fixture:find("equal(BFL.INVITE_RESTRICTION_RULESET,", 1, true))
local body = [=[
local function check(value, message) checks = checks + 1; assert(value, message) end
local function between(source, first, last)
	local a = assert(source:find(first, 1, true), first)
	return source:sub(a, assert(source:find(last, a + #first, true), last) - 1)
end
local FriendsList = {}
env.FriendsList, env.L = FriendsList, BFL.L
BFL.modules = { FriendsList = FriendsList }
function BFL:GetModule(name) return self.modules[name] end
local function run(source, label)
	return assert(load("local BFL, L, FriendsList = ...\n" .. source, "@" .. label, "t", env))(BFL, BFL.L, FriendsList)
end
execute(repo, "Data/ClassColors.lua")
execute(repo, "Utils/ClassUtils.lua")
local model, main = read(repo, "Modules/FriendsList.lua"), read(repo, "BetterFriendlist.lua")
local constants = between(model, "local INVITE_RESTRICTION_NONE =", "-- Helper Functions")
run(constants .. between(model, "local function GetClassFileFromClassName(", "local function GetInviteRestrictionTextSafe("), "production invite model")
local updateStatus = run(constants .. "\nreturn function(self, friend, accountInfo, i)\n"
	.. between(model, "-- PHASE 4 OPTIMIZATION: Pre-calculate Invite Status", "-- The setting is explicitly mobile-only")
	.. "\nend", "production account availability")
local currentFriend, calls, picker, groupMember = nil, {}, nil, false
env.GetFriendsList = function() return FriendsList end
env.BFL_FindBNetFriendData = function() return currentFriend, FriendsList end
function FriendsList:GetFriendUID() return "bnet_42" end
function FriendsList:GetLastInvitedAccountID() return nil end
function FriendsList:SetLastInvitedAccountID(_, id) self.lastInvited = id end
env.BNGetNumFriends = function() return 1 end
BFL.IsBattleNetFriendsListEnabled = function() return true end
BFL.GetBNetFriendInfo = function() return { bnetAccountID = 42 } end
env.GetNativeRealmID = function() return 100 end
env.RegionalUniqueNamesEnabled = function() return BFL.IsForever end
env.LE_PARTY_CATEGORY_HOME = 1
env.IsInGroup = function() return groupMember end
env.UnitIsGroupLeader = function() return not groupMember end
env.C_BattleNet.InviteFriend = function(id) calls[#calls + 1] = { kind = "invite", id = id } end
env.C_PartyInfo.RequestInviteFromUnit = function(name) calls[#calls + 1] = { kind = "request-unit", name = name } end
env.BNRequestInviteFriend = function(id) calls[#calls + 1] = { kind = "request", id = id } end
env.HelpTip = { Acknowledge = function() end }
env.FriendsFrame = {}
env.C_PartyInfo.IsPartyFull = function() return false end
local nativeFriends = read(native, "Interface/AddOns/Blizzard_FriendsFrame/Camelot/FriendsFrame.lua")
local nativeWrapper = run(between(nativeFriends, "function FriendsFrame_InviteOrRequestToJoin(", "function FriendsFrame_BattlenetInviteByIndex(")
	.. "\nreturn FriendsFrame_InviteOrRequestToJoin", "native invite versus Request Join dispatch")
env.FriendsFrame_InviteOrRequestToJoin = nativeWrapper
env.BFL_GetDisplayedInviteTypeSafe, env.BFL_GetInviteButtonText, env.BFL_InvokeBNetInviteOrRequest = run(
	between(main, "local function BFL_GetDisplayedInviteTypeSafe(", "-- Multi-Game-Account: Replace Blizzard")
	.. "\nreturn BFL_GetDisplayedInviteTypeSafe, BFL_GetInviteButtonText, BFL_InvokeBNetInviteOrRequest", "production menu dispatch")
local addInvite = run(between(main, "local function BFL_AddInviteButton(", "local function BFL_GetBNetAccountInfo(")
	.. "\nreturn BFL_AddInviteButton", "production context invite button")
env.BFL_GetContextFullName = function(data) return data.name end
env.TRAVEL_PASS_INVITE, env.INVITE, env.GROUP_INVITE, env.PARTY_INVITE = "Invite", "Invite", "Invite", "Invite"
env.REQUEST_INVITE, env.SUGGEST_INVITE = "Request Join", "Suggest Invite"
env.RED_FONT_COLOR, env.HIGHLIGHT_FONT_COLOR = { r = 1, g = 0, b = 0 }, { r = 1, g = 1, b = 1 }
env.FACTION_ALLIANCE, env.FACTION_HORDE = "Alliance", "Horde"
env.SOCIAL_UI_FRIENDS_LIST_PARTY_BUTTON_OFFLINE_TOOLTIP = "Offline"
env.max = math.max
local function Tooltip()
	local tooltip = { lines = {} }
	function tooltip:SetOwner() self.lines = {} end
	function tooltip:SetText(text) self.text = text end
	function tooltip:AddLine(text) self.lines[#self.lines + 1] = text end
	function tooltip:Show() self.shown = true end
	return tooltip
end
env.BFL_Tooltip = Tooltip()
BFL.OpenSimpleContextMenu = function(_, _, items) picker = items end
local uiBlock = between(main, "local BFL_INVITE_RESTRICTION_NONE =", "-- Display state")
	.. between(main, "local CLASS_ID_TO_GAME_MODE =", "-- Multi-Game-Account Invite Picker")
	.. between(main, "local function GetInviteRestrictionText(", "-- TravelPass Button Handlers")
	.. between(main, "function BetterFriendsList_TravelPassButton_OnClick(", "local inviteTypeToButtonText =")
	.. between(main, "local inviteTypeToButtonText =", "-- Button OnClick Handler")
run(uiBlock, "production picker, TravelPass click and hover")
local smartInvite = run(between(read(repo, "Modules/Broker.lua"), "local function SmartInviteOrJoin(", "-- Helper: Open context menu for friend")
	.. "\nreturn SmartInviteOrJoin", "production Broker invite/request")
local function Menu()
	local menu = { buttons = {} }
	function menu:CreateButton(text, callback)
		local button = Menu(); button.text, button.callback = text, callback
		function button:SetEnabled(value) self.enabled = value end
		function button:SetTooltip(callback) self.tooltip = callback end
		self.buttons[#self.buttons + 1] = button; return button
	end
	return menu
end
local function leaves(root)
	local result = {}
	local function visit(node)
		for _, button in ipairs(node.buttons) do
			if #button.buttons > 0 then visit(button) else result[#result + 1] = button end
		end
	end
	visit(root); return result
end
local function setAccounts(games, online)
	accounts, fresh, calls, picker = games, {}, {}, nil
	for _, account in ipairs(games) do
		if type(account) == "table" and account ~= restricted then
			account.characterName = account.characterName or "Ada Lovelace"
			fresh[account.gameAccountID] = account
		end
	end
	currentFriend = { type = "bnet", bnetAccountID = 42, connected = online ~= false, gameAccountInfo = games[1] }
	updateStatus(FriendsList, currentFriend, { gameAccountInfo = games[1] }, 1)
	return currentFriend
end
local function menu()
	local root = Menu(); addInvite(root, { bnetIDAccount = 42 }, true, not currentFriend.connected); return leaves(root)
end
local function rowClick() env.BetterFriendsList_TravelPassButton_OnClick({ friendData = currentFriend }) end
local function hover()
	env.BetterFriendsList_TravelPassButton_OnEnter({ friendData = currentFriend })
	return table.concat(env.BFL_Tooltip.lines, "\n")
end
local function broker(account)
	smartInvite("bnet", { client = "WoW", gameAccountID = account.gameAccountID,
		gameAccountInfo = account, characterName = account.characterName, realmName = account.realmName })
end
local function noAction(callback, message)
	local before = #calls; callback(); equal(#calls, before, message)
end

for _, own in ipairs({ "PvE", "PvP", "RP", "RP PvP" }) do
	playerRealm = "CAMWOW EU5 Realm 5 " .. own
	for _, target in ipairs({ "PvE", "PvP", "RP", "RP PvP" }) do
		for _, request in ipairs({ false, true }) do
			local account = game(10, target, request and "Player-18-B" or "Player-18-A")
			setAccounts({ account })
			local buttons = menu()
			equal(currentFriend.canInvite, own == target, "TravelPass model enablement follows the same Ruleset decision")
			equal(#buttons, 1, "same/cross Ruleset stays represented by one real menu entry")
			equal(buttons[1].enabled, own == target, "production menu enablement matches canonical Ruleset equality")
			if own ~= target then
				local tip = Tooltip(); buttons[1].tooltip(tip)
				check(#tip.lines > 0, "disabled menu entry retains its reason on hover")
				noAction(buttons[1].callback, "forced disabled menu click cannot submit")
				noAction(rowClick, "forced disabled TravelPass click cannot submit")
				noAction(function() broker(account) end, "Broker cannot submit across Rulesets")
				check(hover():lower():find("ruleset", 1, true) ~= nil, "TravelPass hover names the Ruleset restriction")
			else
				buttons[1].callback(); equal(#calls, 1, "same Ruleset menu submits exactly once")
				equal(calls[1].kind, request and "request" or "invite", "native menu wrapper preserves invite/request intent")
				rowClick(); equal(#calls, 2, "same Ruleset row submits once")
				equal(calls[2].kind, request and "request" or "invite", "native TravelPass wrapper preserves invite/request intent")
				groupMember = request; broker(account); groupMember = false
				equal(#calls, 3, "same Ruleset Broker submits once")
				equal(calls[3].kind, request and "request-unit" or "invite", "Broker preserves invite/request intent")
			end
		end
	end
end

-- Exercise the real shared dispatcher with HasSecretValues=false. Only the
-- final owned-menu surface is mocked; its invite builder remains production.
playerRealm = "CAMWOW EU5 Realm 5 PvE"
setAccounts({ game(10, "PvP") })
local dispatchedMenu
function BFL:OpenBetterFriendlistContextMenu(_, menuType, context)
	equal(menuType, "BN_FRIEND", "real dispatcher retains the BNet menu type")
	check(context.bflOrigin == "BetterFriendlist", "real dispatcher marks owned context")
	dispatchedMenu = Menu(); addInvite(dispatchedMenu, context, true, false); return true
end
BFL.OpenContextMenu({}, "BN_FRIEND", { bnetIDAccount = 42 }, "Friend")
check(dispatchedMenu and leaves(dispatchedMenu)[1].enabled == false,
	"Forever routes to its owned disabled menu even when HasSecretValues is false")

for _, request in ipairs({ false, true }) do
	setAccounts({ game(10, "PvE", request and "Player-18-B" or "Player-18-A") })
	env.FriendsFrame_InviteOrRequestToJoin = nil
	menu()[1].callback()
	equal(calls[1].kind, request and "request" or "invite", "context fallback preserves Request Join versus Invite")
	rowClick()
	equal(calls[2].kind, request and "request" or "invite", "row fallback preserves Request Join versus Invite")
	env.FriendsFrame_InviteOrRequestToJoin = nativeWrapper
end

setAccounts({ game(10, "Unknown") })
equal(menu()[1].enabled, true, "unknown target Ruleset preserves existing native eligibility")
rowClick(); equal(#calls, 1, "unknown Ruleset does not invent a row restriction")
local normalizedTarget = game(10, "Unknown")
normalizedTarget.realmName, normalizedTarget.richPresence = nil, "Westfall - CAMWOWEU5Realm9RPPvP"
setAccounts({ normalizedTarget })
equal(menu()[1].enabled, false, "UI consumes the real helper's normalized rich-presence Ruleset")
noAction(rowClick, "normalized rich-presence mismatch cannot submit")

playerRealm = "CAMWOW EU5 Realm 5 PvE"
local blocked, allowed = game(10, "PvP"), game(11, "PvE", "Player-18-B")
setAccounts({ blocked, allowed })
local buttons = menu()
equal(#buttons, 2, "mixed-account menu shows the blocked and valid character")
local good, bad
for _, button in ipairs(buttons) do if button.enabled then good = button else bad = button end end
check(good and bad, "exactly one mixed-account entry is actionable")
noAction(bad.callback, "forced mixed blocked click cannot submit")
good.callback(); equal(calls[1].id, allowed.gameAccountID, "mixed menu submits only the compatible character")
rowClick(); equal(calls[2].id, allowed.gameAccountID, "mixed TravelPass bypasses blocked native focus")
check(not hover():lower():find("ruleset", 1, true), "mixed TravelPass hover uses its eligible account")

setAccounts({ game(10, "PvE"), game(11, "PvE", "Player-18-B") })
BFL.ShowMultiAccountInvitePicker(accounts, { friendData = currentFriend })
equal(#picker, 3, "compatible multi-account picker preserves both actions")
picker[2].func(); picker[3].func()
local actionsByID = {}; for _, action in ipairs(calls) do actionsByID[action.id] = action.kind end
equal(actionsByID[10], "invite", "picker executes native Invite for the selected character")
equal(actionsByID[11], "request", "picker executes native Request Join for the selected character")

setAccounts({ game(10, "PvP"), game(11, "RP") })
buttons = menu(); equal(#buttons, 2, "all-blocked menu preserves both reasons")
for _, button in ipairs(buttons) do
	equal(button.enabled, false, "every blocked submenu button uses actual SetEnabled(false)")
	noAction(button.callback, "forced all-blocked callback cannot submit")
end
BFL.ShowMultiAccountInvitePicker(accounts, { friendData = currentFriend })
equal(#picker, 3, "account picker contains title and both blocked characters")
for i = 2, #picker do
	check(picker[i].disabled and picker[i].text:lower():find("ruleset", 1, true), "picker labels its disabled Ruleset entries")
	noAction(picker[i].func, "forced disabled picker callback cannot submit")
end

setAccounts({ restricted })
equal(#menu(), 0, "restricted account containers cannot create invite actions")
noAction(rowClick, "restricted native account cannot be dispatched by forced row click")
local hoverOK, hoverError = pcall(hover)
check(hoverOK, "restricted native account hover must fail closed: " .. tostring(hoverError))

for _, mutation in ipairs({ "guid", "ruleset", "offline", "faction", "missing", "forbidden", "secret", "region", "gameMode", "secretFaction" }) do
	local captured = game(10, "PvE")
	setAccounts({ captured })
	local callback = menu()[1].callback
	BFL.ShowMultiAccountInvitePicker({ captured }, { friendData = currentFriend })
	local pickerCallback = picker[2].func
	local changed = {}; for key, value in pairs(captured) do changed[key] = value end
	if mutation == "guid" then changed.playerGuid = "Player-18-Reassigned"
	elseif mutation == "ruleset" then changed.realmName = "CAMWOW EU5 Realm 5 PvP"
	elseif mutation == "offline" then changed.isOnline = false
	elseif mutation == "faction" then changed.factionName = "Horde"
	elseif mutation == "missing" then changed = nil
	elseif mutation == "secret" then changed = restricted
	elseif mutation == "region" then changed.isInCurrentRegion = false
	elseif mutation == "gameMode" then changed.classID = 14
	elseif mutation == "secretFaction" then changed.factionName = secret
	else refreshError = true end
	fresh[10] = changed
	noAction(callback, mutation .. " stale menu cannot submit")
	noAction(pickerCallback, mutation .. " stale picker cannot submit")
	noAction(function() broker(captured) end, mutation .. " stale Broker cannot submit")
	noAction(rowClick, mutation .. " stale TravelPass cannot submit")
	refreshError = false
end

setAccounts({ game(10, "PvE") })
local openBeforePlayerSwitch = menu()[1].callback
playerRealm = "CAMWOW EU5 Realm 5 PvP"
noAction(openBeforePlayerSwitch, "player Ruleset change also invalidates an already open menu")
playerRealm = "CAMWOW EU5 Realm 5 PvE"
local captured = game(10, "PvE")
setAccounts({ captured })
local readOnly = {}; for key, value in pairs(captured) do if key:sub(1, 3) ~= "bfl" then readOnly[key] = value end end
setmetatable(readOnly, { __newindex = function() error("Native snapshot mutated") end })
fresh[10] = readOnly
rowClick(); equal(#calls, 1, "fresh immutable account can be dispatched without writing addon fields")
equal(readOnly.bflIsInvitable, nil, "UI does not add cached eligibility to fresh native records")

for _, missingGUID in ipairs({ false, "" }) do
	local unpinned = game(10, "PvE"); unpinned.playerGuid = missingGUID or nil
	setAccounts({ unpinned })
	equal(currentFriend.canInvite, false, "missing/empty GUID is unavailable in the production model")
	equal(#menu(), 0, "missing/empty GUID cannot create an active menu entry")
	local staleEntry = FriendsList:BuildAccountDisplay(unpinned)
	staleEntry.isInvitable = true -- Force past the UI state to test the dispatch guard itself.
	fresh[10] = game(10, "PvE", "Player-18-OtherCharacter")
	noAction(function() env.BFL_InvokeBNetInviteOrRequest(staleEntry) end,
		"missing captured GUID cannot authorize a newly bound character")
	noAction(rowClick, "unverifiable captured GUID cannot submit through the row either")
end
setAccounts({ game(10, "PvE", "Player-18-Recovered") })
equal(menu()[1].enabled, true, "readable GUID recovery restores normal invite enablement")
rowClick(); equal(#calls, 1, "readable GUID recovery dispatches normally")

setAccounts({ game(10, "PvE") }, false)
equal(#menu(), 0, "offline friend has no context invite")
noAction(rowClick, "offline TravelPass cannot submit")
check(hover():find("Offline", 1, true), "offline hover does not retain an old Ruleset reason")
for _, field in ipairs({ "realmID", "isInCurrentRegion", "wowProjectID", "classID" }) do
	local account = game(10, "PvE")
	account[field] = ({ realmID = 0, isInCurrentRegion = false, wowProjectID = 1, classID = 14 })[field]
	setAccounts({ account })
	equal(currentFriend.canInvite, false, "existing native gate remains blocked: " .. field)
	equal(#menu(), 0, "Ruleset equality cannot create an entry through native gate: " .. field)
	noAction(rowClick, "forced row preserves native gate: " .. field)
end

for _, flavor in ipairs({ { 1, false }, { 2, true } }) do
	BFL.IsForever, BFL.IsClassic, env.WOW_PROJECT_ID = false, flavor[2], flavor[1]
	local account = game(10, "PvP"); account.wowProjectID = flavor[1]
	setAccounts({ account })
	equal(menu()[1].enabled, true, "Retail/Classic retain native eligibility without Forever Ruleset gating")
	rowClick(); equal(#calls, 1, "Retail/Classic row behavior remains available")
end
io.write(("Ruleset invite UI smoke: %d checks passed\n"):format(checks))
]=]
assert(load(fixture:sub(1, boundary - 1) .. body, "@production Ruleset invite UI smoke", "t", _G))()
