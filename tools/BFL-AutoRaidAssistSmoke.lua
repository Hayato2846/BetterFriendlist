-- Lua 5.4: lua tools/BFL-AutoRaidAssistSmoke.lua <repo> <Forever UI source>
-- Loads production identity/compatibility/assist modules and Blizzard's Camelot
-- NameUtil. API/frame mocks do not prove live promotion permissions or delivery.
local repo = arg[1] or "."
local native = assert(arg[2], "Forever UI source root is required")
local function read(root, path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source
end
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function fixture(regional, separator)
	local secret = setmetatable({}, { __index = function() error("secret table indexed") end,
		__tostring = function() error("secret formatted") end })
	local BFL = { modules = {}, L = {}, IsForever = regional, IsMainline = not regional }
	function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
	function BFL:GetModule(name) return self.modules[name] end
	function BFL:RegisterLocale() end
	function BFL:IsSecret(value) return rawequal(value, secret) end
	local state = { now = 100, combat = false, restricted = false, leader = true, raid = true, rosterOnly = false,
		rows = { { first = "Ada", last = "Lovelace", realm = "OtherRealm", rank = 0 },
			{ first = "Ada", last = "Byron", realm = "OtherRealm", rank = 0 } },
		friends = {}, promotions = {}, timers = {}, secret = secret }
	local function row(unit)
		local index = type(unit) == "string" and tonumber(unit:match("^raid(%d+)$"))
		return index and state.rows[index]
	end
	local env = setmetatable({ BFL = BFL, SlashCmdList = {}, BNET_CLIENT_WOW = "WoW", WOW_PROJECT_ID = regional and 18 or 1,
		GAMETYPE_NORMAL = "Normal", PVP_PARENTHESES = "(PvP)", RP_PARENTHESES = "(RP)",
		WOW_PROJECT_CAMELOT = 18, LE_REALM_RELATION_SAME = 1, UNKNOWN = "Unknown", UNKNOWNOBJECT = "Unknown object",
		Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = separator or "-",
			CHARACTERNAME_REALMNAME_SEPARATOR = "-" } },
		Enum = { BattleNetFriendLevel = { Title = 3, BattleTag = 1, RealID = 2 } },
		BFL_LOCALE_ENUS = BFL.L,
		BetterFriendlistDB = { autoRaidAssist = { enabled = true, targets = {} } },
		issecrettable = function(value) return rawequal(value, secret) end,
		strmatch = string.match, strtrim = function(value) return value:match("^%s*(.-)%s*$") end,
		strsplit = function(delimiter, value) return value:match("^(.-)" .. delimiter .. "(.*)$") end,
	}, { __index = _G })
	env.RegionalUniqueNamesEnabled = function() return regional end
	env.GetNormalizedRealmName = function() return "HomeRealm" end
	env.GetTime = function() return state.now end
	env.time = function() return 1234 end
	env.InCombatLockdown = function() return state.combat end
	function BFL:IsActionRestricted() return state.restricted or state.combat end
	env.IsInRaid = function() return state.raid end
	env.IsInGroup = function() return true end
	env.GetNumGroupMembers = function() return #state.rows end
	env.GetNumSubgroupMembers = function() return #state.rows end
	env.UnitExists = function(unit) return not state.rosterOnly and row(unit) ~= nil end
	env.UnitIsUnit = function(_, other) return other ~= "player" end
	env.UnitIsGroupLeader = function(unit) return unit == "player" and state.leader or false end
	env.UnitIsGroupAssistant = function(unit) local value = row(unit); return value and value.rank == 1 or false end
	env.UnitRealmRelationship = function() return 1 end
	env.UnitNameUnmodified = function(unit)
		local value = row(unit)
		if not value or state.rosterOnly then return nil end
		return value.first, regional and value.last or value.realm
	end
	env.UnitName = env.UnitNameUnmodified
	env.UnitFullName = function(unit)
		local value = row(unit)
		if not value or state.rosterOnly then return nil end
		return value.first, value.realm
	end
	env.GetRaidRosterInfo = function(index)
		local value = state.rows[index]
		if not value then return nil end
		if value.rosterName ~= nil then return value.rosterName, value.rank end
		local name = regional and (value.first .. (separator or "-") .. value.last) or value.first .. "-" .. value.realm
		return name, value.rank
	end
	env.C_PartyInfo = { PromoteToAssistant = function(name, exact)
		state.promotions[#state.promotions + 1] = { name = name, exact = exact }
	end }
	env.C_Timer = { NewTimer = function(delay, callback)
		local timer = { callback = callback, due = state.now + delay }
		function timer:Cancel() self.cancelled = true end
		state.timers[#state.timers + 1] = timer; return timer
	end }
	local function execute(root, path)
		return assert(load(read(root, path), "@" .. path, "t", env))("BetterFriendlist", BFL)
	end
	execute(repo, "Utils/ClassicCompat.lua")
	execute(repo, "Locales/enUS.lua")
	execute(native, regional and "Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua"
		or "Interface/AddOns/Blizzard_FrameXMLUtil/NameUtil.lua")
	local identity = execute(repo, "Modules/ContactIdentity.lua")
	local assist = execute(repo, "Modules/AutoRaidAssist.lua")
	BFL.modules.FriendsList = { friendsList = state.friends, GetDisplayName = function(_, friend) return friend.displayName end }
	BFL.modules.DB = { GetNickname = function() return nil end }
	assist.lastPromotionAttempt, assist.promotionAttemptCounts, assist.promotionQueue = {}, {}, {}
	assist.promotionQueueLookup, assist.promotionRetryTimers = {}, {}
	function state:resetTargets()
		env.BetterFriendlistDB.autoRaidAssist.targets = {}; assist.dbCacheDirty = true
		assist:ClearPromotionQueue(); assist:CancelPromotionRetryTimers()
		assist.lastPromotionAttempt, assist.promotionAttemptCounts = {}, {}
	end
	function state:render()
		local widgets = {}
		local methods = {}
		local function widget()
			local value = setmetatable({ scripts = {}, text = "", visible = true }, { __index = methods })
			widgets[#widgets + 1] = value; return value
		end
		function methods:CreateFontString() return widget() end
		function methods:SetText(text) self.text = text; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
		function methods:GetText() return self.text end
		function methods:SetHeight(height) self.height = height end
		function methods:GetHeight() return self.height or 24 end
		function methods:GetFrameLevel() return 1 end
		function methods:SetScript(event, callback) self.scripts[event] = callback end
		function methods:Show() self.visible = true end
		function methods:Hide() self.visible = false end
		function methods:ClearFocus() if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end end
		for _, name in ipairs({ "SetPoint", "SetJustifyH", "SetAutoFocus", "SetFontObject", "SetSize", "SetTextColor",
			"SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetFrameLevel" }) do methods[name] = function() end end
		env.CreateFrame = widget
		BFL.SetOwnedBackdrop = function() end
		local handle = assist:RenderSettingsPage(widget(), { settingsCenter = true })
		return handle, widgets
	end
	return assist, identity, BFL, env, state
end

for _, separator in ipairs({ "-", " " }) do
	local assist, identity, BFL, env, state = fixture(true, separator)
	local full = "Ada" .. separator .. "Lovelace"
	local other = "Ada" .. separator .. "Byron"
	equal(assist:GetUnitPromotionName("raid1"), full, "Regional promotion keeps the surname")
	equal(assist:GetUnitDebugName("raid1"), full, "Regional debug names omit realms")
	equal(assist:GetUnitContactKey("raid1"), "player:" .. full, "Regional contact key uses full native identity")
	check(assist:GetUnitContactKey("raid1") ~= assist:GetUnitContactKey("raid2"), "Same first names cannot collide")
	equal(assist:GetLookupKeyFromNameOrUnit("Ada-Lovelace"), ("player:" .. full):lower(), "Hyphen alias matches the unit")
	equal(assist:GetLookupKeyFromNameOrUnit("Ada Lovelace"), ("player:" .. full):lower(), "Space alias matches the unit")
	check(assist:AddManualCharacterTarget("Ada Lovelace"), "Manual space input is accepted")
	equal(assist:GetTargets()[1].key, "player:" .. full, "Manual input saves the full canonical identity")
	local ok, reason = assist:AddManualCharacterTarget("Ada-Lovelace")
	check(not ok and reason == "duplicate", "Alternate separator cannot create a duplicate")
	check(not assist:AddManualCharacterTarget("Ada"), "Incomplete first-name target is rejected")
	check(assist:AddManualCharacterTarget("Ada-Byron"), "Different surname remains a distinct target")
	equal(#assist:GetTargets(), 2, "Both surnames persist")
	check(assist:RemoveTarget("player:Ada-Lovelace"), "Removal accepts the hyphen alias for native-space storage")
	equal(#assist:GetTargets(), 1, "Alias removal removes only the selected surname")
	state:resetTargets()
	state.rosterOnly = true
	equal(assist:GetUnitPromotionName("raid1"), full, "Roster-only fallback keeps surname")
	equal(assist:GetUnitContactKey("raid1"), "player:" .. full, "Roster-only lookup agrees with live units")
	state.rosterOnly = false
	state.friends[1] = { type = "bnet", friendLevel = 3, bnetAccountID = 7, displayName = "Ada Lovelace",
		characterName = full, gameAccountInfo = { isOnline = true, clientProgram = "WoW", wowProjectID = 18,
			characterName = full, realmName = "HiddenRealm" } }
	state.friends[2] = { type = "bnet", friendLevel = 3, bnetAccountID = 8, displayName = "Ada Byron",
		characterName = other, gameAccountInfo = { isOnline = true, clientProgram = "WoW", wowProjectID = 18,
			characterName = other, realmName = "HiddenRealm" } }
	for _, query in ipairs({ "Ada Lovelace", "Ada-Lovelace" }) do
		local candidates = assist:BuildCandidateList(query, 10)
		check(#candidates >= 1, "Search accepts both regional separators")
		check(not candidates[1].subtitle:find("HiddenRealm", 1, true), "Title candidate omits realm")
	end
	check(assist:AddTargetFromFriend(state.friends[1]), "Title friend can be selected")
	equal(assist:GetTargets()[1].key, "player:" .. full, "New Title selection persists character identity rather than a numeric account")
	equal(assist:GetTargets()[1].source, "titleFriend", "Title source survives character-key storage")
	state.friends[1].gameAccountInfo.realmName = "Forever RPPVP"
	equal(assist:GetCandidateSubtitle(state.friends[1], "player", full), "WoW Friend - " .. full .. " - RP-PvP",
		"Title candidate shows a recognized target ruleset")
	local _, targetSubtitle = assist:GetTargetDisplay(assist:GetTargets()[1])
	equal(targetSubtitle, "WoW Friend - " .. full .. " - RP-PvP", "Saved Title target shows display-only ruleset")
	equal(assist:GetTargets()[1].key, "player:" .. full, "Ruleset never enters target identity")
	state.friends[1].gameAccountInfo.realmName = "HiddenRealm"
	local keys = assist:BuildEffectiveTargetKeySet()
	check(keys[("player:" .. full):lower()], "Title target expands to full character identity")
	check(not keys[("player:" .. other):lower()], "Title selection never includes another surname")
	check(assist:Evaluate("smoke"), "Selected Title produces an eligible promotion")
	equal(#state.promotions, 1, "Title promotion dispatches once")
	equal(state.promotions[1].name, full, "Native promotion receives complete identity")
	equal(state.promotions[1].exact, true, "Native promotion requests exact matching")
	state.friends[1].characterName, state.friends[1].gameAccountInfo.characterName = other, other
	keys = assist:BuildEffectiveTargetKeySet()
	check(keys[("player:" .. full):lower()] and not keys[("player:" .. other):lower()], "Selected Title character never silently follows another character")
	state.friends[1].characterName, state.friends[1].gameAccountInfo.characterName = full, full
	state.friends[1].gameAccountInfo.wowProjectID = 1
	check(not assist:AddTargetFromFriend(state.friends[1]), "Foreign-project Title cannot select a same-named local player")
	state.friends[1].gameAccountInfo.wowProjectID = 18
	state:resetTargets()
	check(assist:AddTarget("bnet:7", "bnetFriend", "Ada Lovelace"), "Legacy numeric target can remain stored")
	check(assist:BuildEffectiveTargetKeySet()[("player:" .. full):lower()], "Legacy Title ID requires matching readable full saved name")
	state.friends[1].gameAccountInfo.characterName = other
	equal(next(assist:BuildEffectiveTargetKeySet()), nil, "Stale cached character name cannot authorize a different game account character")
	state.friends[1].gameAccountInfo.characterName = full
	state.friends[1].characterName, state.friends[1].gameAccountInfo.characterName = other, other
	equal(next(assist:BuildEffectiveTargetKeySet()), nil, "Legacy ID cannot switch to another character")
	state.friends[1].characterName, state.friends[1].gameAccountInfo.characterName = full, full
	assist:GetTargets()[1].displayName = "Alias"
	equal(next(assist:BuildEffectiveTargetKeySet()), nil, "Unverified legacy display alias cannot authorize numeric target")
	assist:GetTargets()[1].displayName = "Ada-Lovelace"
	state.friends[1].friendLevel = 1
	equal(next(assist:BuildEffectiveTargetKeySet()), nil, "A recycled numeric row without Title level cannot authorize promotion")
	state.friends[1].friendLevel = 3
	local nativeFriends = { state.friends[1] }
	BFL.GetBNetFriendInfo = function(index) return nativeFriends[index] end
	env.BNGetNumFriends = function() return #nativeFriends end
	state.friends[1] = nil
	check(assist:BuildEffectiveTargetKeySet()[("player:" .. full):lower()], "Native Title row fallback preserves exact full identity")
	nativeFriends[1] = state.secret
	equal(next(assist:BuildEffectiveTargetKeySet()), nil, "Secret native account row is not indexed")
	env.BNGetNumFriends = nil
	state.friends[1] = state.friends[2]
	state:resetTargets()
	check(assist:AddManualCharacterTarget("Ada-Lovelace"), "Restriction target added")
	state.combat = true; check(not assist:Evaluate("combat"), "Combat prevents promotion")
	state.combat = false; state.restricted = true
	local broadGate = assist:GetPromotionGateStatus("broad-restriction")
	check(broadGate.ok and not broadGate.promotionRestricted and broadGate.bflActionRestricted,
		"Module retains its specific combat gate rather than inferring every AddOn restriction forbids promotion")
	local restrictedCallCount = #state.promotions
	assist:Evaluate("restriction")
	equal(#state.promotions, restrictedCallCount, "Shared AddOn action restriction prevents native promotion")
	assist:ClearPromotionQueue(); assist:CancelPromotionRetryTimers()
	assist.lastPromotionAttempt, assist.promotionAttemptCounts = {}, {}
	state.restricted = false; state.leader = false
	check(not assist:Evaluate("leader"), "Nonleader cannot promote")
	state.leader = true; state.raid = false
	check(not assist:Evaluate("party"), "Party members are not raid-promoted")
	state.raid = true; state.rows[1].rank = 1
	check(not assist:Evaluate("assistant"), "Existing assistants are not promoted again")
	state.rows[1].rank = 0
	assist:RememberDemotedTarget("Ada Lovelace")
	check(not assist:Evaluate("demotion"), "Manual demotion is remembered with full identity")
	assist:ClearDemotedTargets("smoke")
	check(assist:Evaluate("recovery"), "Readable unrestricted state recovers")
	state.rows[1].first = state.secret; state.rows[1].rosterName = state.secret
	equal(assist:GetUnitContactKey("raid1"), nil, "Restricted unit and roster names are skipped")
	local restrictedKeys = {}
	assist:AddGameAccountKey(state.secret, restrictedKeys)
	equal(next(restrictedKeys), nil, "Restricted game account table is not indexed")
	state.rows[1].first, state.rows[1].rosterName = "Ada", nil
	local originalLeader, originalAssistant = env.UnitIsGroupLeader, env.UnitIsGroupAssistant
	env.UnitIsGroupLeader = function() return state.secret end
	check(not assist:CanPromoteNow("secret-leader"), "Restricted leadership fails closed")
	env.UnitIsGroupLeader = originalLeader
	env.UnitIsGroupAssistant = function() return state.secret end
	equal(assist:GetNotPromotableReason("raid1"), "restrictedRank", "Restricted member rank fails closed")
	env.UnitIsGroupAssistant = originalAssistant
	local oldPromotionName = assist.GetUnitPromotionName
	assist.GetUnitPromotionName = function() return nil end
	state:resetTargets(); assist:AddManualCharacterTarget("Ada-Lovelace")
	local calls = #state.promotions
	assist:Evaluate("identity-disappeared")
	equal(#state.promotions, calls, "Missing fresh identity sends no promotion")
	assist.GetUnitPromotionName = oldPromotionName
	state:resetTargets()
	local savedFriends = BFL.modules.FriendsList.friendsList
	BFL.modules.FriendsList.friendsList = {}
	assist:InvalidateCandidateCache()
	local groupCandidates = assist:BuildCandidateList("Ada Lovelace", 10)
	equal(#groupCandidates, 1, "Group-only candidates preserve unique full names")
	equal(groupCandidates[1].key, "player:" .. full, "Group candidate key includes surname")
	equal(groupCandidates[1].displayName, full, "Group candidate display includes surname")
	local guildMembers = { { name = "Ada", fullName = "Ada-Lovelace", realm = "MustNotAppend", classFile = state.secret }, state.secret }
	BFL.modules.GuildRosterData = { HasBaseRosterAPI = function() return true end, IsInGuild = function() return true end,
		CollectRoster = function() return guildMembers end, RequestRosterUpdate = function() end }
	assist:InvalidateCandidateCache()
	local guildCandidates = assist:BuildCandidateList("Ada-Lovelace", 10)
	equal(#guildCandidates, 1, "Guild and group aliases deduplicate")
	equal(guildCandidates[1].source, "guild", "Guild source wins the existing priority")
	equal(guildCandidates[1].key, "player:" .. full, "Guild key does not truncate surname or append realm")
	equal(guildCandidates[1].displayName, full, "Guild display does not truncate surname")
	guildMembers = state.secret
	assist:InvalidateCandidateCache()
	check(pcall(assist.BuildCandidateList, assist, "Ada", 10), "Restricted guild container is not iterated")
	BFL.modules.GuildRosterData = nil
	BFL.modules.FriendsList.friendsList = savedFriends
	assist:InvalidateCandidateCache()
	local handle, widgets = state:render()
	handle:SetStatus("invalidCharacter")
	equal(handle.status.text, "Use First name-Last name.", "Forever invalid-name help requests the full surname")
	local foundTitle = false
	for _, value in ipairs(widgets) do if value.text == "Find Friend / First name-Last name" then foundTitle = true end end
	check(foundTitle, "Forever editor does not request a realm")
	local controls = {}
	assist:RegisterSettingsDesignerControls({ RegisterControl = function(_, _, control) controls[control.id] = control end },
		{ includeEditor = false })
	equal(controls["autoRaidAssist.manage"].description,
		"Choose friends, nickname matches, or manual First name-Last name targets.", "Forever manager help omits realm requirement")
end

local assist, identity, BFL, env, state = fixture(false)
equal(assist:GetUnitPromotionName("raid1"), "Ada", "Traditional same-realm promotion keeps original behavior")
env.UnitRealmRelationship = function() return 2 end
equal(assist:GetUnitPromotionName("raid1"), "Ada-OtherRealm", "Traditional foreign-realm promotion is qualified")
check(assist:AddManualCharacterTarget("Ada-OtherRealm"), "Traditional manual realm target remains valid")
check(not assist:AddManualCharacterTarget("Ada OtherRealm"), "Traditional manual target still requires a hyphen")
equal(assist:GetTargets()[1].key, "player:Ada-OtherRealm", "Traditional persisted target remains unchanged")
state.friends[1] = { type = "bnet", battleTag = "Friend#123", displayName = "Friend", gameAccountInfo = {
	isOnline = true, clientProgram = "WoW", wowProjectID = 1, characterName = "Ada", realmName = "OtherRealm" } }
check(assist:AddTargetFromFriend(state.friends[1]), "BattleTag target remains supported")
check(assist:BuildEffectiveTargetKeySet()["player:ada-otherrealm"], "BattleTag expands traditional name and realm")
equal(assist:GetCandidateSubtitle(state.friends[1], "bnet", "Friend#123"), "BattleTag - Ada-OtherRealm", "Retail/Classic realm subtitle remains")
state.friends[1].gameAccountInfo.wowProjectID = 18
state.friends[1].gameAccountInfo.characterName = "Ada Lovelace"
state.friends[1].gameAccountInfo.realmName = "Forever PVP"
equal(assist:GetCandidateSubtitle(state.friends[1], "bnet", "Friend#123"), "BattleTag - Ada Lovelace - PvP", "Retail viewing a Forever friend uses its target ruleset")
state:resetTargets()
local handle, widgets = state:render()
handle:SetStatus("invalidCharacter")
equal(handle.status.text, "Use Name-Realm.", "Traditional invalid-name help remains unchanged")
local foundTitle = false
for _, value in ipairs(widgets) do if value.text == "Find Friend / Character-Realm" then foundTitle = true end end
check(foundTitle, "Traditional editor still requests realm")

-- A nonregional Title's name belongs to its target realm, never an implicit
-- local-realm fallback. Two same-named raid members make misbinding observable.
assist, identity, BFL, env, state = fixture(false)
state.rows[1].realm, state.rows[2].realm = "HomeRealm", "OtherRealm"
env.UnitRealmRelationship = function(unit) return unit == "raid1" and 1 or 2 end
local selected = { type = "bnet", friendLevel = 3, bnetAccountID = 7, displayName = "Ada-OtherRealm",
	characterName = "Ada", gameAccountInfo = { isOnline = true, clientProgram = "WoW", wowProjectID = 1,
		characterName = "Ada", realmName = "OtherRealm" } }
state.friends[1] = selected
check(assist:AddTargetFromFriend(selected), "Nonregional foreign Title can be selected")
equal(assist:GetTargets()[1].key, "player:Ada-OtherRealm", "Nonregional Title persists its actual target realm")
assist:Evaluate("foreign-title")
equal(#state.promotions, 1, "Foreign Title selects one exact raid member")
equal(state.promotions[1].name, "Ada-OtherRealm", "Foreign Title never promotes same-named home-realm member")
equal(state.promotions[1].exact, true, "Foreign Title promotion remains exact")
state:resetTargets()
selected.gameAccountInfo.realmName = nil
check(not assist:AddTargetFromFriend(selected), "Unknown nonregional Title realm cannot be inferred as home realm")
selected.gameAccountInfo.characterName = "Ada-OtherRealm"
check(assist:AddTargetFromFriend(selected), "Already qualified Title character keeps its native realm without a separate realm field")
equal(assist:GetTargets()[1].key, "player:Ada-OtherRealm", "Qualified Title name never gains the home realm")
state:resetTargets()
selected.gameAccountInfo.characterName, selected.gameAccountInfo.realmName = "Ada", "HomeRealm"
check(assist:AddTarget("bnet:7", "bnetFriend", "Ada"), "Unqualified legacy Title target is retained")
equal(next(assist:BuildEffectiveTargetKeySet()), nil, "Legacy numeric ID and first name alone cannot authorize the home-realm member")
assist:GetTargets()[1].displayName = "Ada-HomeRealm"
check(assist:BuildEffectiveTargetKeySet()["player:ada-homerealm"], "Explicit matching saved realm is usable legacy Title evidence")
io.write(string.format("PASS: %d AutoRaidAssist checks (production modules; mocked native APIs)\n", checks))
