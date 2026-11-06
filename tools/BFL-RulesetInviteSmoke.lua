-- Lua 5.4: lua tools/BFL-RulesetInviteSmoke.lua <repo> <Forever UI source>
-- Real compatibility/locale modules and Blizzard invite-selection helpers.
-- Mocks cover data/ownership guards, not protected execution or server policy.
local repo, native = assert(arg[1]), assert(arg[2])
local function read(root, path)
	local f = assert(io.open(root .. "/" .. path, "rb")); local s = f:read("*a"); f:close(); return s
end
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1; assert(actual == expected, message .. ": " .. tostring(actual))
end
local secret = setmetatable({}, { __tostring = function() error("Secret formatted") end })
local restricted = setmetatable({}, { __index = function() error("Restricted table indexed") end })
local BFL = { L = {}, IsForever = true, HasSecretValues = false }
function BFL:RegisterLocale() end
function BFL:IsSecret(value) return rawequal(value, secret) end
local playerRealm, normalizedRealm, playerFaction = "CAMWOW EU5 Realm 5 PvE", "CAMWOWEU5Realm5PvE", "Alliance"
local accounts, fresh, refreshReads, realmReads, presetReads = {}, {}, 0, 0, 0
local refreshError, realmError, crossFaction = false, false, true
local env = setmetatable({
	SlashCmdList = {}, BFL_LOCALE_ENUS = BFL.L, BNET_CLIENT_WOW = "WoW", WOW_PROJECT_CAMELOT = 18,
	WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
	GetRealmName = function() realmReads = realmReads + 1; if realmError then error("Realm unavailable") end; return playerRealm end,
	GetNormalizedRealmName = function() realmReads = realmReads + 1; return normalizedRealm end,
	UnitFactionGroup = function() return playerFaction end, GetRealmID = function() return 100 end,
	issecrettable = function(value) return rawequal(value, restricted) end,
	GetDisplayedInviteType = function(guid) return guid == "Player-18-B" and "REQUEST_INVITE" or "INVITE" end,
	C_GameRules = { GetActiveGameMode = function() return 0 end, IsCharacterlessLoginActive = function() return false end,
		GetForeverExperiencePreset = function() presetReads = presetReads + 1; return 1 end },
	C_Glue = { IsOnGlueScreen = function() return false end },
	C_PartyInfo = { CanFormCrossFactionParties = function() return crossFaction end },
	C_QuestSession = { Exists = function() return false end },
	Enum = { GameMode = { Standard = 0, Plunderstorm = 1, WoWHack = 2 } },
	EnumUtil = { MakeEnum = function(...)
		local t = {}; for i = 1, select("#", ...) do t[select(i, ...)] = i - 1 end; return t
	end },
	table = setmetatable({ count = function(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end }, { __index = table }),
	assertsafe = assert, ERR_TRAVEL_PASS_NO_INFO = "Unavailable", ERR_TRAVEL_PASS_NOT_ALLIED = "Different faction",
	ERR_TRAVEL_PASS_DIFFERENT_REGION = "Different region", ERR_TRAVEL_PASS_WRONG_PROJECT_MAINLINE_OVERRIDE = "Retail project",
}, { __index = _G })
env._G = env
env.C_BattleNet = {
	GetFriendNumGameAccounts = function() return #accounts end,
	GetFriendGameAccountInfo = function(_, i) return accounts[i] end,
	GetGameAccountInfoByID = function(id)
		refreshReads = refreshReads + 1; if refreshError then error("Account unavailable") end; return fresh[id]
	end,
}
local function execute(root, path)
	return assert(load(read(root, path), "@" .. path, "t", env))("BetterFriendlist", BFL)
end
execute(repo, "Locales/enUS.lua")
execute(repo, "Utils/ClassicCompat.lua")
execute(native, "Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsListConstants.lua")
execute(native, "Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsListUtil.lua")
local function game(id, rule, guid)
	return { gameAccountID = id, playerGuid = guid or "Player-18-A", clientProgram = "WoW", wowProjectID = 18,
		realmName = "CAMWOW EU5 Realm 9 " .. rule, factionName = "Alliance", realmID = 100,
		isInCurrentRegion = true, isOnline = true, classID = 11 }
end
equal(BFL.INVITE_RESTRICTION_RULESET, 14, "Only BFL owns the new restriction value")
equal(env.INVITE_RESTRICTION_RULESET, nil, "No Blizzard/global restriction constant is created")
for _, own in ipairs({ "PvE", "PvP", "RP", "RP PvP" }) do
	playerRealm = "CAMWOW EU5 Realm 5 " .. own
	for _, other in ipairs({ "PvE", "PvP", "RP", "RP PvP" }) do
		local account = game(10, other)
		local reason, targetToken, playerToken, current = BFL.GetForeverRulesetInviteRestriction(account)
		equal(reason ~= nil, own ~= other, own .. " vs " .. other .. " canonical mismatch")
		equal(current, account, "Display check preserves snapshot identity")
		equal(targetToken == playerToken, own == other, "Canonical comparison agrees independently of labels")
	end
end
equal(refreshReads, 0, "Rendering does not refresh every game account")
playerRealm = "CAMWOW EU5 Realm 5 PvE"
local a = game(10, "PvP")
local oldPVE, oldPVP = BFL.L.RULESET_TYPE_NORMAL, BFL.L.RULESET_TYPE_PVP
BFL.L.RULESET_TYPE_NORMAL, BFL.L.RULESET_TYPE_PVP = "same label", "same label"
equal(BFL.GetForeverRulesetInviteRestriction(a) ~= nil, true, "Equal translations cannot hide a canonical mismatch")
BFL.L.RULESET_TYPE_NORMAL, BFL.L.RULESET_TYPE_PVP = oldPVE, oldPVP
a.realmName, a.realmDisplayName, a.richPresence = nil, nil, "Westfall - CAMWOWEU5Realm9RPPvP"
local reason, target = BFL.GetForeverRulesetInviteRestriction(a)
equal(target, "RPPVP", "Target presence uses the shared strict realm parser")
equal(reason ~= nil, true, "Known target presence can prove mismatch")
a.realmName, a.richPresence = secret, secret
equal(BFL.GetForeverRulesetInviteRestriction(a), nil, "Hidden target rulesets create no invented block")
equal(BFL.GetForeverRulesetInviteRestriction(restricted), nil, "Restricted account containers are not indexed")
equal(BFL.GetForeverRulesetInviteRestriction(secret), nil, "Secret accounts are unavailable")
playerRealm, normalizedRealm = secret, secret
equal(BFL.GetForeverRulesetInviteRestriction(game(10, "PvP")), nil, "Hidden player realms do not invent a mismatch")
realmError, normalizedRealm = true, "CAMWOWEU5Realm5PvE"
equal(BFL.GetForeverRulesetInviteRestriction(game(10, "PvP")) ~= nil, true, "Normalized player realm can recover from a failed getter")
realmError, playerRealm = false, "CAMWOW EU5 Realm 5 PvE"
a = game(10, "PvP"); a.wowProjectID = 1
local before = realmReads
equal(BFL.GetForeverRulesetInviteRestriction(a), nil, "Explicit Retail targets keep native restrictions")
equal(realmReads, before, "Foreign projects do not query the player's ruleset")
a.clientProgram = "App"
equal(BFL.GetForeverRulesetInviteRestriction(a), nil, "Other games never use the Forever ruleset gate")

local captured = game(21, "PvE")
fresh[21] = game(21, "PvP")
local allowed, why, current = BFL.ValidateForeverInviteTarget(captured)
equal(allowed, false, "Changed ruleset is checked at click time")
equal(why ~= nil, true, "Mismatch produces a localized explanation")
equal(current, fresh[21], "Dispatch gets only the refreshed target record")
equal(captured.realmName, "CAMWOW EU5 Realm 9 PvE", "Validation never edits a captured/native snapshot")
fresh[21] = game(21, "PvE", "Player-18-NewCharacter")
equal(BFL.ValidateForeverInviteTarget(captured), false, "Same game account never silently changes a pinned character")
fresh[21] = game(21, "PvE"); fresh[21].factionName = "Horde"
allowed, why = BFL.ValidateForeverInviteTarget(captured)
equal(allowed, false, "Fresh faction mismatch is forbidden even if native cross-faction support is true")
equal(why, "Different faction", "Faction uses the existing native reason")
fresh[21] = game(21, "unknown")
equal(BFL.ValidateForeverInviteTarget(captured), true, "Fresh unknown ruleset leaves native eligibility authoritative")
fresh[21] = game(21, "PvE")
equal(BFL.ValidateForeverInviteTarget(captured), true, "Fresh matching identity/faction/ruleset is allowed")
fresh[21].wowProjectID, captured.wowProjectID = 1, 1
equal(BFL.ValidateForeverInviteTarget(captured), false, "An explicitly foreign project is never dispatched from Forever")
fresh[21].wowProjectID, captured.wowProjectID = 18, 18
fresh[21].isOnline = false
equal(BFL.ValidateForeverInviteTarget(captured), false, "Offline refreshed records cannot authorize an invite")
fresh[21].isOnline = secret
equal(BFL.ValidateForeverInviteTarget(captured), false, "Hidden online state cannot authorize an invite")
fresh[21].isOnline = nil
equal(BFL.ValidateForeverInviteTarget(captured), false, "Incomplete online metadata cannot authorize an invite")
fresh[21].isOnline = true
fresh[21].gameAccountID = 22
equal(BFL.ValidateForeverInviteTarget(captured), false, "Mismatched refreshed ID is rejected")
fresh[21], refreshError = game(21, "PvE"), true
equal(BFL.ValidateForeverInviteTarget(captured), false, "Refresh errors cannot authorize a stale record")
refreshError, fresh[21] = false, nil
equal(BFL.ValidateForeverInviteTarget(captured), false, "Disappeared accounts are unavailable")
fresh[21] = restricted
equal(BFL.ValidateForeverInviteTarget(captured), false, "Restricted refreshed records are unavailable")
fresh[21] = game(21, "PvE"); fresh[21].playerGuid = secret
equal(BFL.ValidateForeverInviteTarget(captured), false, "Hidden current GUID cannot match a selected character")
captured.gameAccountID = secret
before = refreshReads
equal(BFL.ValidateForeverInviteTarget(captured), false, "Secret IDs never reach the refresh API")
equal(refreshReads, before, "Invalid captured identity performs no native lookup")

-- The central dispatch guard must feed the refreshed record to the production
-- model eligibility entry point. Full UI smokes exercise its actual policies.
local modelCalls, nativeRestriction = 0, 0
local model = { GetGameAccountInviteRestriction = function(_, record)
	modelCalls = modelCalls + 1
	equal(record, fresh[21], "Native eligibility receives the fresh account, not captured menu data")
	return nativeRestriction
end }
function BFL:GetModule(name) equal(name, "FriendsList", "Validation queries only the invite model"); return model end
BFL.GetInviteRestrictionText = function(code) return code == 10 and "Fresh region blocked" or "Fresh mode blocked" end
captured, fresh[21] = game(21, "PvE"), game(21, "PvE")
nativeRestriction = 10
allowed, why = BFL.ValidateForeverInviteTarget(captured)
equal(allowed, false, "Fresh native region restriction blocks a formerly valid menu")
equal(why, "Fresh region blocked", "Native restriction reason is preserved")
nativeRestriction = 13
equal(BFL.ValidateForeverInviteTarget(captured), false, "Fresh native game mode restriction blocks dispatch")
nativeRestriction = 0
equal(BFL.ValidateForeverInviteTarget(captured), true, "Fresh native eligibility can authorize a matching target")
before = modelCalls
fresh[21].playerGuid = "Player-18-Other"
equal(BFL.ValidateForeverInviteTarget(captured), false, "GUID pinning remains mandatory before native model checks")
equal(modelCalls, before, "Changed characters never reach eligibility for a captured menu")
fresh[21].playerGuid = captured.playerGuid
nativeRestriction = secret
equal(BFL.ValidateForeverInviteTarget(captured), false, "A secret native restriction cannot authorize dispatch")
model.GetGameAccountInviteRestriction = function() error("Native eligibility unavailable") end
equal(BFL.ValidateForeverInviteTarget(captured), false, "A failed native eligibility check cannot authorize dispatch")
BFL.GetModule, BFL.GetInviteRestrictionText = nil, nil
equal(BFL.IsReadableGameAccountInfo, BFL.Compat.IsReadableGameAccountInfo, "BFL and Compat export the same guarded table query")
equal(BFL.IsReadableGameAccountInfo(restricted), false, "The shared query rejects restricted parent account tables")
equal(BFL.IsReadableGameAccountInfo(secret), false, "The shared query rejects secret parent values")

-- Native selection prefers the first same-faction account, even if its ruleset
-- differs. BFL must choose the later actually eligible account and its action.
accounts = { game(1, "PvP", "Player-18-A"), game(2, "PvE", "Player-18-B") }
before = refreshReads
local info, text = BFL.GetBNetInviteTooltipInfo(1)
equal(text, "", "An eligible account beats a blocked account")
equal(info.playerGUID, "Player-18-B", "Tooltip follows the ruleset-compatible character")
equal(info.inviteType, "REQUEST_INVITE", "Tooltip action is recomputed for that character")
equal(accounts[1].inviteRestriction, nil, "Native game account snapshots are not annotated")
accounts = { game(1, "PvP") }
info, text = BFL.GetBNetInviteTooltipInfo(1)
equal(text ~= nil and text ~= "", true, "Native None cannot suppress a known ruleset mismatch")
accounts = { game(1, "PvE") }; accounts[1].factionName = "Horde"
info, text = BFL.GetBNetInviteTooltipInfo(1)
equal(text, "Different faction", "Forever overrides native cross-faction permissiveness")
accounts[1].factionName = "Alliance"; accounts[1].isInCurrentRegion = false
info, text = BFL.GetBNetInviteTooltipInfo(1)
equal(text, "Different region", "Existing native restrictions remain authoritative")
accounts = { game(1, "PvP") }; accounts[1].wowProjectID = 1
info, text = BFL.GetBNetInviteTooltipInfo(1)
equal(text, "Retail project", "Foreign project keeps its native restriction")
equal(refreshReads, before, "Tooltip rendering never refreshes every account")

local ownedMenus = 0
BFL.OpenBetterFriendlistContextMenu = function() ownedMenus = ownedMenus + 1; return true end
BFL.OpenContextMenu({}, "BN_FRIEND", { bnetIDAccount = 1 })
equal(ownedMenus, 1, "BFL friend menus use the guarded path on Forever without secret-value APIs")
BFL.IsForever = false
before = refreshReads
local original = game(99, "PvP")
allowed, why, current = BFL.ValidateForeverInviteTarget(original)
equal(allowed, true, "Other clients have no additional Forever restriction")
equal(why, nil, "Other clients receive no extra reason")
equal(current, original, "Other clients preserve their original record")
equal(refreshReads, before, "Other clients perform no refresh through this guard")
equal(presetReads, 0, "Preset ID is never read for invitations")
io.write("Ruleset invite smoke: " .. checks .. " checks passed\n")
