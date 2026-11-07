-- Lua 5.4: lua tools/BFL-RulesetLocationSmoke.lua <repo> <Forever UI source>
-- Production compatibility helpers with native Camelot name formatting. The
-- sentinels cover our guards; they do not reproduce native secret execution.
local repo = assert(arg[1], "repository root is required")
local forever = assert(arg[2], "Forever UI source root is required")
local function read(root, path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source
end
local assertions = 0
local function equal(actual, expected, message)
	assertions = assertions + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local restricted = setmetatable({}, {
	__index = function() error("Restricted table indexed") end,
	__pairs = function() error("Restricted table enumerated") end,
	__tostring = function() error("Restricted data formatted") end,
})
local secret = setmetatable({}, { __tostring = function() error("Secret formatted") end })
local BFL = { IsForever = false, L = {}, modules = {} }
function BFL:IsSecret(value) return rawequal(value, secret) end
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:RegisterLocale() end
local regional, firstName, surname = true, "Ada", "Lovelace"
local calls, presetReads = {}, 0
local env = setmetatable({
	SlashCmdList = {},
	BNET_CLIENT_WOW = "WoW", FULL_PLAYER_NAME = "%s-%s",
	BFL_LOCALE_ENUS = BFL.L,
	LE_REALM_RELATION_SAME = 1,
	Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } },
	RegionalUniqueNamesEnabled = function() return regional end,
	issecrettable = function(value) return rawequal(value, restricted) end,
	GetNormalizedRealmName = function() return "Home" end,
	UnitExists = function(unit) return unit == "raid1" end,
	UnitNameUnmodified = function() return firstName, surname end,
	UnitName = function() return firstName, surname end,
	UnitFullName = function() return firstName, "Other Realm" end,
	UnitRealmRelationship = function() return 1 end,
	strmatch = string.match,
	C_GameRules = setmetatable({ GetForeverExperiencePreset = function() presetReads = presetReads + 1; return 1 end },
		{ __index = function() error("Player rules are not friend metadata") end }),
	C_PartyInfo = { PromoteToAssistant = function(name, exact) calls[#calls + 1] = { name, exact } end },
}, { __index = _G })
env._G = env
local function execute(source, label)
	return assert(load(source, "@" .. label, "t", env))("BetterFriendlist", BFL)
end
execute(read(repo, "Locales/enUS.lua"), "English locale")
execute(read(repo, "Utils/ClassicCompat.lua"), "ClassicCompat")
execute(read(forever, "Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua"), "native Camelot NameUtil")
local function location(info, fallback, text, kind, message)
	local actual, actualKind, evidence = BFL.GetWoWAccountLocation(info, fallback)
	equal(actual, text, message)
	equal(actualKind, kind, message .. " kind")
	if kind == "ruleset" and text ~= "" then
		equal(type(evidence), "string", message .. " has readable target realm evidence")
	else
		equal(evidence, nil, message .. " has no unverified realm evidence")
	end
end
local function game(project)
	return { clientProgram = "WoW", wowProjectID = project, realmName = "InternalRealm", realmDisplayName = "Display Realm" }
end

-- Retail may see a Forever friend without loading WOW_PROJECT_CAMELOT.
equal(env.WOW_PROJECT_CAMELOT, nil, "Retail does not need the Camelot global")
equal(env.GAMETYPE_NORMAL, nil, "Realm labels do not require Glue's Normal global")
equal(env.PVP_PARENTHESES, nil, "Realm labels do not require Glue's PvP global")
equal(env.RP_PARENTHESES, nil, "Realm labels do not require Glue's RP global")
location(game(18), "Fallback", "", "ruleset", "Forever friends never expose their realm from Retail")
for _, example in ipairs({
	{ "CAMWOW AU1 Realm 2 PVP (PVP) New", "PvP" },
	{ "CAMWOW US2 Realm 1 PVE (Normal) Full", "Normal" },
	{ "CAMWOW US1 Realm 9 RPPVP (RPPVP) New", "RP-PvP" },
	{ "CAMWOW AU1 Realm 3 RP (RP) New", "RP" },
	{ "camwow au1 realm 2 pvp (pvp) new", "PvP" },
	{ "CamWoW us1 realm 9 rpPvP (rpPvp) New", "RP-PvP" },
	-- Actual raw/normalized realms from all four live EU5 diagnostic characters.
	{ "CAMWOW EU5 Realm 5 PvE", "Normal" },
	{ "CAMWOWEU5Realm5PvE", "Normal" },
	{ "CAMWOW EU5 Realm 6 PvP", "PvP" },
	{ "CAMWOWEU5Realm6PvP", "PvP" },
	{ "CAMWOW EU5 Realm 10 RP", "RP" },
	{ "CAMWOWEU5Realm10RP", "RP" },
	{ "CAMWOW EU5 Realm 9 RP PvP", "RP-PvP" },
	{ "CAMWOWEU5Realm9RPPvP", "RP-PvP" },
	{ "camwoweu5realm9rppvp", "RP-PvP" },
	{ "CAMWOW EU5 Realm 9 rp\tPvP", "RP-PvP" },
	{ "CAMWOW EU5 Realm 9 RP PvP (RP PvP) New", "RP-PvP" },
	{ "CAMWOWAU1Realm2PVP", "PvP" },
	{ "CAMWOWUS2Realm1PVE", "Normal" },
	{ "CAMWOWUS1Realm9RPPVP", "RP-PvP" },
	{ "CAMWOWAU1Realm3RP", "RP" },
	{ "PVE", "Normal" }, { "Realm RP-PVP", "RP-PvP" },
	{ "PVP_SUFFIX", "" }, { "PrefixPVP", "" }, { "PVP2", "" },
	{ "XRP", "" }, { "RPPVPX", "" }, { "PVE PVP", "" },
	{ "OtherRealm9RPPVP", "" }, { "PrefixCAMWOWEU5Realm9RPPVP", "" },
	{ "CAMWOWEU5Realm9RPPVPsuffix", "" }, { "CAMWOWEU5Realm9RPPVP2", "" },
	{ "CAMWOWEURealm9RPPVP", "" }, { "CAMWOWEU5RealmRPPVP", "" },
	{ "CAMWOWEU5Realm9PVP_SUFFIX", "" }, { "XRP PvPX", "" },
}) do
	local account = game(18)
	account.realmName, account.realmDisplayName = example[1], nil
	location(account, "Fallback", example[2], "ruleset", "Exact target realm tokens: " .. example[1])
end
local displayOnlyRuleset = game(18)
displayOnlyRuleset.realmName, displayOnlyRuleset.realmDisplayName = nil, "CAMWOW US1 Realm 9 RPPVP (RPPVP) New"
location(displayOnlyRuleset, "Fallback", "RP-PvP", "ruleset", "The target display realm is an explicit fallback")
displayOnlyRuleset.realmDisplayName = "CAMWOWEU5Realm9RPPvP"
location(displayOnlyRuleset, "Fallback", "RP-PvP", "ruleset", "The normalized target display realm also retains RP-PvP")
local _, _, displayEvidence = BFL.GetWoWAccountLocation(displayOnlyRuleset)
equal(displayEvidence, "CAMWOWEU5Realm9RPPvP", "Display realm evidence retains the exact readable source text")
displayOnlyRuleset.realmName, displayOnlyRuleset.realmDisplayName = secret, "Realm PVE"
location(displayOnlyRuleset, "Fallback", "Normal", "ruleset", "A readable target display realm survives hidden raw text")
BFL.L.RULESET_TYPE_NORMAL, BFL.L.RULESET_TYPE_RPPVP = "Normal localisé", "JdR-JcJ"
env.GAMETYPE_NORMAL, env.PVP_PARENTHESES, env.RP_PARENTHESES = "Wrong difficulty", "(Wrong PvP)", "(Wrong RP)"
displayOnlyRuleset.realmDisplayName = "Realm RPPVP"
location(displayOnlyRuleset, "Fallback", "JdR-JcJ", "ruleset", "Addon locale labels override unrelated Glue globals")
displayOnlyRuleset.realmDisplayName = "Realm PVE"
location(displayOnlyRuleset, "Fallback", "Normal localisé", "ruleset", "Normal comes from the locale catalog, not difficulty or Glue labels")
env.GAMETYPE_NORMAL, env.PVP_PARENTHESES, env.RP_PARENTHESES = nil, nil, nil
execute(read(repo, "Locales/enUS.lua"), "Restore English locale")
for _, example in ipairs({
	{ "Westfall - CAMWOW EU5 Realm 5 PvE", "Normal" },
	{ "Westfall - CAMWOW EU5 Realm 6 PvP", "PvP" },
	{ "Westfall - CAMWOW EU5 Realm 10 RP", "RP" },
	{ "Westfall - CAMWOW EU5 Realm 9 RP PvP", "RP-PvP" },
	{ "Westfall - camwoweu5realm9rppvp", "RP-PvP" },
	{ "Westfall - PvP", "" }, { "Battleground PvP", "" },
	{ "Westfall - OtherRealm9RPPVP", "" },
	{ "Westfall - CAMWOWEU5Realm9RPPVPSUFFIX", "" },
}) do
	local account = game(18)
	account.realmName, account.realmDisplayName, account.richPresence = nil, nil, example[1]
	location(account, "CAMWOW EU5 Realm 6 PvP", example[2], "ruleset", "Only the target's CAMWOW presence suffix can supply missing realm data")
end
local unknownTarget = game(18)
for _, separator in ipairs({ " - ", " · " }) do
	for _, variant in ipairs({ { "Normal", "Normal" }, { "PvE", "Normal" }, { "PvP", "PvP" },
		{ "RP", "RP" }, { "RP-PvP", "RP-PvP" }, { "RP PvP", "RP-PvP" } }) do
		local account = game(18)
		account.realmName, account.realmDisplayName = nil, nil
		account.richPresence = "Forever" .. separator .. variant[1] .. separator .. "Ashenvale"
		location(account, "CAMWOW EU5 Realm 6 PvP", variant[2], "ruleset", "Structured Forever presence supplies the exact target ruleset")
		equal(select(4, BFL.GetWoWAccountLocation(account)), "Ashenvale", "Presence area is separate from ruleset evidence")
		equal(account.realmName, nil, "Presence parsing never invents a realm name")
	end
end
for _, presence in ipairs({ "Forever · Heroic · Ashenvale", "Forever · Normal · ", "Forever · Normal", "WoW · PvP · Ashenvale",
	"Battlefield PvP", "Ashenvale - PvP", "Forever · Normal · Ashenvale · Extra" }) do
	local account = game(18)
	account.realmName, account.realmDisplayName, account.richPresence = nil, nil, presence
	location(account, nil, "", "ruleset", "Unrecognized presence is not a realm ruleset")
end
local statusAccount = game(18)
statusAccount.realmName, statusAccount.realmDisplayName = nil, nil
statusAccount.richPresence = "Forever · Normal · PvP Arena"
location(statusAccount, nil, "Normal", "ruleset", "PvP in the zone cannot override the explicit Normal segment")
statusAccount.richPresence = "Forever - RP-PvP - Lune-d’Argent"
equal(select(4, BFL.GetWoWAccountLocation(statusAccount)), "Lune-d’Argent", "Zone hyphens and glyphs are preserved")
statusAccount.wowProjectID = 1
location(statusAccount, nil, "", "realm", "The presence format cannot classify a normal Retail account as Forever")
statusAccount.wowProjectID, statusAccount.richPresence = 18, secret
location(statusAccount, nil, "", "ruleset", "Restricted structured presence is rejected before parsing")
unknownTarget.realmName, unknownTarget.realmDisplayName, unknownTarget.richPresence = nil, nil, secret
location(unknownTarget, "CAMWOW EU5 Realm 6 PvP", "", "ruleset", "Secret presence cannot activate an unrelated caller fallback")
unknownTarget.richPresence = nil
location(unknownTarget, "CAMWOW EU5 Realm 6 PvP", "", "ruleset", "A caller's own realm never classifies an unknown friend")
unknownTarget.richPresence = "Westfall - camwow EU5 Realm 9 RP PvP"
local _, _, presenceEvidence = BFL.GetWoWAccountLocation(unknownTarget)
equal(presenceEvidence, "camwow EU5 Realm 9 RP PvP", "Presence evidence contains only the exact target realm suffix")
equal(unknownTarget.richPresence, "Westfall - camwow EU5 Realm 9 RP PvP", "Evidence extraction never edits native rich presence")
equal(unknownTarget.realmName, nil, "Evidence extraction never populates a native realm field")
unknownTarget.realmName = "CaMwOw EU5 Realm 6 pVp"
local _, _, rawEvidence = BFL.GetWoWAccountLocation(unknownTarget)
equal(rawEvidence, unknownTarget.realmName, "Raw realm evidence retains the original capitalization")
location(game(1), "Fallback", "Display Realm", "realm", "Retail friends keep their display realm")
location(game(2), "Fallback", "Display Realm", "realm", "Classic friends keep their display realm")
local regular = game(1)
regular.realmDisplayName = nil
location(regular, "Fallback", "InternalRealm", "realm", "Raw realm is a normal-client fallback")
regular.realmName = nil
location(regular, "Fallback", "Fallback", "realm", "Caller fallback remains display-only")
location(nil, "Fallback", "Fallback", "realm", "Traditional local friends can use a known realm")
location(game(nil), "Fallback", "Display Realm", "realm", "Unmarked data retains normal Retail behavior")
location({ clientProgram = "App", wowProjectID = 1 }, "Fallback", "", "realm", "Other games cannot borrow a WoW realm")
location(restricted, "Fallback", "", "realm", "Secret tables are rejected before indexing")
location(secret, "Fallback", "", "realm", "Secret values are rejected before use")
local hidden = game(secret)
location(hidden, "Fallback", "", "realm", "An unreadable project cannot select an unrelated realm")
regular.realmDisplayName, regular.realmName = secret, secret
location(regular, secret, "", "realm", "Secret strings are never formatted or returned")

-- Reuse one native record across client changes, including inconsistent
-- presence data until the next Battle.net update. Never mutate its contents.
local changingAccount = game(18)
for _, presence in ipairs({ "Forever · Normal · Ashenvale", "Forever - PvP - Elwynn",
	"Westfall - CAMWOW EU5 Realm 9 RP PvP" }) do
	changingAccount.richPresence, changingAccount.wowProjectID = presence, 18
	equal(BFL.GetGameAccountRichPresence(changingAccount), presence, "Forever keeps its own presence")
	for _, project in ipairs({ 1, 2 }) do
		changingAccount.wowProjectID = project
		equal(BFL.GetGameAccountRichPresence(changingAccount), nil, "Other WoW clients do not reuse Forever presence")
		equal(changingAccount.richPresence, presence, "Filtering never modifies the native snapshot")
	end
	changingAccount.wowProjectID = 18
	equal(BFL.GetGameAccountRichPresence(changingAccount), presence, "Returning to Forever recovers without a cached empty value")
end
changingAccount.wowProjectID, changingAccount.richPresence = 1, "Stormwind - Normal"
equal(BFL.GetGameAccountRichPresence(changingAccount), "Stormwind - Normal", "Current Retail presence remains intact")
changingAccount.richPresence = "PvP Arena"
equal(BFL.GetGameAccountRichPresence(changingAccount), "PvP Arena", "Generic PvP text is not classified as Forever")
changingAccount.richPresence = secret
equal(BFL.GetGameAccountRichPresence(changingAccount), nil, "Restricted presence is never parsed")
changingAccount.richPresence, changingAccount.wowProjectID = "Forever · PvP · Elwynn", secret
equal(BFL.GetGameAccountRichPresence(changingAccount), nil, "Restricted projects are not compared")
equal(BFL.GetGameAccountRichPresence(restricted), nil, "Restricted account tables are not indexed")
equal(BFL.GetGameAccountRichPresence(secret), nil, "Secret accounts are not inspected")
equal(BFL.GetGameAccountRichPresence({ clientProgram = "D3", wowProjectID = 1, richPresence = "Adventure Mode" }),
	"Adventure Mode", "Other games retain their normal status")

BFL.IsForever = true
location(game(18), "Fallback", "", "ruleset", "Forever friends have no invented ruleset")
location(game(nil), "Fallback", "", "ruleset", "Projectless data in Forever has no realm")
location(nil, "Fallback", "", "ruleset", "Local Forever friends have no guessed realm")
location(restricted, "Fallback", "", "ruleset", "Restricted Forever accounts remain empty")
location(hidden, "Fallback", "", "ruleset", "Hidden Forever projects remain empty")
location(game(1), "Fallback", "Display Realm", "realm", "Retail friends retain realms when viewed in Forever")
location(game(2), "Fallback", "Display Realm", "realm", "Classic friends retain realms when viewed in Forever")
local future = game(18)
future.ruleset, future.ruleSetID, future.timerunningSeasonID = "Not documented", 9, 7
location(future, "Fallback", "", "ruleset", "Unverified fields and timerunning IDs cannot become ruleset evidence")
equal(future.realmDisplayName, "Display Realm", "Display helpers never mutate Blizzard snapshots")
equal(presetReads, 0, "The shared preset value cannot classify any friend's ruleset")

-- Shared names use the runtime surname separator, independently of location.
equal(BFL.NormalizePlayerIdentityName("Ada-Lovelace"), "Ada Lovelace", "Manual hyphen alias uses native spelling")
equal(BFL.NormalizePlayerIdentityName("Ada Lovelace", "Wrong Realm"), "Ada Lovelace", "A full regional name never appends a realm")
equal(BFL.NormalizePlayerIdentityName("Ada", "Lovelace"), "Ada Lovelace", "Separate surname follows native NameUtil")
local fullName, realm = BFL.SplitPlayerName("Ada-Lovelace")
equal(fullName, "Ada Lovelace", "Regional split retains the full character identity")
equal(realm, nil, "Regional split does not invent a realm")
equal(BFL.GetUnmodifiedUnitFullName("raid1"), "Ada Lovelace", "Native Camelot formatter retains the surname")
equal(BFL.PromoteToAssistant("raid1"), true, "Regional unit promotion remains available")
equal(calls[#calls][1], "Ada Lovelace", "Same-realm relationship never discards a surname")
equal(calls[#calls][2], true, "Resolved unit uses an exact name")
equal(BFL.PromoteToAssistant("Ada-Lovelace", true), true, "Manual alias can be promoted")
equal(calls[#calls][1], "Ada Lovelace", "Manual promotion uses native surname spelling")
firstName = secret
equal(BFL.PromoteToAssistant("raid1"), false, "Restricted unit names cannot reach a party action")
firstName = "Ada"
env.Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR = "-"
equal(BFL.NormalizePlayerIdentityName("Ada Lovelace"), "Ada-Lovelace", "Clients defining a hyphen separator remain supported")

regional = false
equal(BFL.NormalizePlayerIdentityName("Ada", "Other Realm"), "Ada-OtherRealm", "Traditional realm normalization is unchanged")
local character, actualRealm = BFL.SplitPlayerName("Ada-OtherRealm")
equal(character, "Ada", "Traditional split keeps the character")
equal(actualRealm, "OtherRealm", "Traditional split keeps the actual realm")
equal(BFL.NormalizePlayerIdentityName(secret), nil, "Secret identity inputs are rejected")

local identity = execute(read(repo, "Modules/ContactIdentity.lua"), "ContactIdentity")
equal(identity:ResolveContactKeyFromFriend(restricted), nil, "Restricted friend containers are rejected before indexing")
equal(identity:ResolveContactKeyFromContext(restricted), nil, "Restricted context containers are rejected before indexing")
equal(identity:ResolveContactKeyFromFriend(secret), nil, "Secret friend containers remain unavailable")
equal(identity:ResolveContactKeyFromContext(secret), nil, "Secret context containers remain unavailable")
equal(identity:ResolveContactKeyFromFriend({ gameAccountInfo = restricted }), nil, "Restricted nested game accounts are never indexed")
equal(identity:ResolveContactKeyFromFriend({ name = "Ada-Home", gameAccountInfo = restricted }), "player:Ada-Home", "Readable friend identity survives unavailable optional game data")
equal(identity:ResolveContactKeyFromFriend({ type = "bnet", battleTag = "Ada#1234", gameAccountInfo = restricted }), "bnet:Ada#1234", "A readable BattleTag does not require nested game data")
equal(identity:ResolveContactKeyFromContext({ bnetIDAccount = 42 }), "bnet:42", "Readable context IDs retain their existing semantics")
equal(identity:ResolveContactKeyFromFriend("bnet_Ada#1234"), "bnet:Ada#1234", "String contact identities remain supported")
env.issecrettable = function() error("Unavailable table restriction state") end
equal(identity:ResolveContactKeyFromFriend({ name = "Ada-Home" }), nil, "Failed table checks cannot authorize indexing")
equal(identity:ResolveContactKeyFromContext({ name = "Ada-Home" }), nil, "Failed context checks are conservative")
env.issecrettable = nil
equal(identity:ResolveContactKeyFromFriend({ name = "Ada-Home" }), "player:Ada-Home", "Clients without secret tables retain their behavior")

-- Run every real locale loader, keeping Glue globals absent throughout.
env.BFL_LOCALE = BFL.L
function BFL:RegisterLocale(_, loader) loader() end
for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }) do
	execute(read(repo, "Locales/" .. locale .. ".lua"), locale .. " locale")
	for _, example in ipairs({
		{ "CAMWOWEU5Realm5PvE", "RULESET_TYPE_NORMAL" },
		{ "CAMWOWEU5Realm6PvP", "RULESET_TYPE_PVP" },
		{ "CAMWOWEU5Realm10RP", "RULESET_TYPE_RP" },
		{ "CAMWOW EU5 Realm 9 RP PvP", "RULESET_TYPE_RPPVP" },
	}) do
		local account = game(18)
		account.realmName, account.realmDisplayName = example[1], nil
		assert(type(BFL.L[example[2]]) == "string" and BFL.L[example[2]] ~= "", locale .. " ruleset label is missing")
		location(account, "Fallback", BFL.L[example[2]], "ruleset", locale .. " labels work without Glue globals")
	end
end
io.write("Ruleset/location smoke: " .. assertions .. " assertions passed\n")
