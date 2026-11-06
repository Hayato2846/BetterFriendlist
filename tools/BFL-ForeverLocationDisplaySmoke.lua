-- lua tools/BFL-ForeverLocationDisplaySmoke.lua <repo> <Forever UI source>
-- Production formatters and tooltip/QuickJoin paths; engine widgets/APIs are mocked.
local repo, native = assert(arg[1]), assert(arg[2])
local function read(path) local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s end
local function fixture(path, boundary, body)
	local source = read(repo .. "/tools/" .. path)
	local stop = assert(source:find(boundary, 1, true))
	assert(load(source:sub(1, stop - 1) .. body, "@" .. path .. ":location-display", "t", _G))()
end
fixture("BFL-FriendsListStartupSmoke.lua", "-- A layout switch replaces the view", [=[
local context = setup({}, { nameFormat = "%character% %realm%" })
local env, BFL, list = context.env, context.BFL, context.list
env.RegionalUniqueNamesEnabled = function() return true end
env.Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
check(env.GAMETYPE_NORMAL == nil and env.PVP_PARENTHESES == nil and env.RP_PARENTHESES == nil,
	"in-game formatter fixture does not provide Glue-only realm labels")
env.BetterFriendlistDB.colorClassNames = false
local account = { clientProgram = "WoW", wowProjectID = 18, characterName = "Ada Lovelace",
	realmName = "CAMWOW US1 Realm 1 PVE (Normal) New", gameAccountID = 7, playerGuid = "Player-18-7" }
local friend = { type = "bnet", uid = "bnet_7", friendLevel = 3, connected = true, characterName = account.characterName,
	accountName = account.characterName, battleTag = "", realmName = account.realmName, gameAccountInfo = account, areaName = "Elwynn" }
equal(list:GetDisplayName(friend), "Ada Lovelace Normal", "friend name token substitutes target ruleset")
equal(list:GetFormattedButtonText(friend), "Ada Lovelace Normal", "rendered friend row uses ruleset")
account.realmName = "CAMWOW US1 Realm 2 pVp (PVP) New"
equal(list:GetFormattedButtonText(friend), "Ada Lovelace PvP", "location mutation invalidates the rendered-name cache")
local display = list:BuildAccountDisplay(account)
equal(display.text, "Ada Lovelace - PvP", "account picker replaces realm with ruleset")
equal(display.realmName, account.realmName, "display object retains raw realm metadata for callers")
equal(display.raw, account, "display never copies or modifies native identity")
equal(display.playerGuid, account.playerGuid, "ruleset display preserves GUID")

local broker = read("Modules/Broker.lua")
local function between(source, first, last)
	local a = assert(source:find(first, 1, true)); return source:sub(a, assert(source:find(last, a + #first, true)) - 1)
end
env.GetDB = function() return BFL.modules.DB end
env.GetFriendGameName = function() return "WoW Forever" end
local brokerDisplay = assert(load(between(broker, "local function GetDisplayLocation(", "local function GetFriendsList()")
	.. between(broker, "local function ReplaceTokenCaseInsensitive(", "-- Helper: Get colored level text")
	.. "\nreturn GetFriendDisplayName", "@production broker location formatter", "t", env))()
equal(brokerDisplay(friend), "Ada Lovelace PvP", "broker name tokens use ruleset")
friend.type, friend.name, friend.fullName = "wow", "Ada Lovelace", "Ada Lovelace"
equal(brokerDisplay(friend), "Ada Lovelace PvP", "broker preserves full regional names")
env.RegionalUniqueNamesEnabled = function() return false end
BFL.IsForever = false; account.wowProjectID, account.realmName = 1, "Retail Realm"
friend.type = "bnet"
equal(list:GetDisplayName(friend), "Ada Lovelace Retail Realm", "Retail account keeps actual realm")
equal(brokerDisplay(friend), "Ada Lovelace Retail Realm", "Retail broker keeps realm")

-- Exercise actual API ingestion and rendered second lines, not just helpers
-- fed hand-built display rows. Existing default preferences need no migration.
for _, modern in ipairs({ false, true }) do
	for _, variant in ipairs({ { "PvE", "Normal" }, { "PvP", "PvP" }, { "RP", "RP" }, { "RP PvP", "RP-PvP" } }) do
		local snapshot = title()
		snapshot.gameAccountInfo.realmName = "CAMWOW EU5 Realm 9 " .. variant[1]
		snapshot.gameAccountInfo.characterLevel = 16
		local current = setup({ snapshot }, { modern = modern })
		current.BFL.modules.DB:Set("colorLevelByDifficulty", false)
		current.list:UpdateFriendsList()
		local row = assert(current.list.friendsList[1])
		local expected = string.format(current.BFL.L.LEVEL_FORMAT, 16) .. ", Elwynn, " .. variant[2]
		equal(select(2, current.list:GetFormattedButtonText(row)), expected, "Forever default renders level, zone and ruleset from an API snapshot")
		current.list.settingsCache.infoFormatPreset = "custom"
		current.list.settingsCache.infoFormatString = "%zone% (%RuLeSeT%)"
		equal(current.list:FormatInfoLine(row), "Elwynn (" .. variant[2] .. ")", "custom ruleset token is case insensitive")
		current.list.settingsCache.nameFormatString = "%character% %ruleset%"
		equal(current.list:GetDisplayName(row), "Ada Lovelace " .. variant[2], "name formats share the explicit ruleset token")
		current.list.settingsCache.infoFormatPreset = "disabled"
		equal(current.list:FormatInfoLine(row), nil, "disabled info stays disabled")
		current.list.settingsCache.infoFormatPreset = "default"
		row.connected = false
		equal(current.list:FormatInfoLine(row), current.BFL.L.OFFLINE_STATUS, "offline default does not retain a stale ruleset")
	end
end

-- A realm literally called PvP cannot masquerade as a Forever ruleset, even
-- when the previous rendered value was the same string.
env.RegionalUniqueNamesEnabled = function() return true end
BFL.IsForever = true
list.settingsCache.nameFormatString = "%character% %ruleset%"
list.settingsCache.infoFormatPreset = "custom"
list.settingsCache.infoFormatString = "%zone%, %ruleset%"
account.wowProjectID, account.realmName = 18, "CAMWOW EU5 Realm 6 PvP"
equal(list:GetFormattedButtonText(friend), "Ada Lovelace PvP", "rendered explicit ruleset token uses the target project")
account.wowProjectID, account.realmName = 1, "PvP"
equal(list:GetFormattedButtonText(friend), "Ada Lovelace", "location kind invalidates a same-text cached ruleset")
equal(list:FormatInfoLine(friend), "Elwynn", "Retail target does not supply a ruleset token")
BFL.modules.DB.GetNameFormatString = function() return list.settingsCache.nameFormatString end
equal(brokerDisplay(friend), "Ada Lovelace", "broker shares the ruleset token and target-project distinction")
env.RegionalUniqueNamesEnabled = function() return false end
friend.type, friend.name, friend.fullName, friend.realmName = "wow", "Ada", "Ada", "Home"
friend.gameAccountInfo = nil
BFL.IsForever = false
list.settingsCache.nameFormatString = "%character% [%realm%]"
equal(brokerDisplay(friend), "Ada", "unqualified Retail/Classic WoW friends retain their old empty realm token")
friend.fullName = "Ada-OtherRealm"
equal(brokerDisplay(friend), "Ada [OtherRealm]", "qualified Retail/Classic names retain their explicit realm token")
friend.type, friend.name, friend.fullName, friend.realmName, friend.gameAccountInfo = "bnet", nil, nil, account.realmName, account
env.RegionalUniqueNamesEnabled = function() return true end
BFL.IsForever = true
list.settingsCache.infoFormatPreset = "default"
equal(list:FormatInfoLine(friend), "Elwynn", "Retail target in Forever keeps the default info layout")
account.wowProjectID, account.realmName = 18, "Unrecognized Realm"
equal(list:FormatInfoLine(friend), "Elwynn", "unknown ruleset has no dangling separator")
account.realmName = "CAMWOW EU5 Realm 6 PvP"
BFL.IsForever = false
equal(list:FormatInfoLine(friend), "Elwynn", "Retail client default stays unchanged for Forever targets")
io.write("[OK] location display formatters: " .. assertions .. " checks\n")
]=])

fixture("BFL-TitleFriendTooltipSmoke.lua", "local game = { gameAccountID", [=[
env.WOW_PROJECT_ID = 1
env.BFL_LOCALE_ENUS = BFL.L
function BFL:RegisterLocale() end
execute(read(repo, "Locales/enUS.lua"), "production enUS locale")
check(env.GAMETYPE_NORMAL == nil and env.PVP_PARENTHESES == nil and env.RP_PARENTHESES == nil,
	"tooltip fixture does not invent Glue-only globals")
local primary = { gameAccountID = 101, isOnline = true, clientProgram = "WoW", wowProjectID = 1,
	characterName = "RetailAda", characterLevel = 80, raceName = "Human", className = "Rogue",
	factionName = "Alliance", isInCurrentRegion = true, realmName = "Retail Realm", areaName = "Stormwind" }
local secondary = { gameAccountID = 102, isOnline = true, clientProgram = "WoW", wowProjectID = 18,
	characterName = "Ada Lovelace", realmName = "CAMWOW US1 Realm 1 PVP (PVP) New", areaName = "Elwynn Forest" }
secondary.richPresence = "Elwynn Forest - " .. secondary.realmName
local friend = { type = "bnet", index = 1, bnetAccountID = 42, friendLevel = 1, accountName = "Ada#1234",
	battleTag = "Ada#1234", connected = true, gameAccountInfo = primary, totalGameAccounts = 2, gameAccounts = { primary, secondary } }
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "Zone: Stormwind\nRealm: Retail Realm", "primary Retail tooltip keeps realm")
equal(env.FriendsTooltipGameAccount2Info.text, "Elwynn Forest - PvP", "secondary Forever rich presence uses target ruleset")
secondary.richPresence = "Elwynn Forest - " .. secondary.realmName:lower()
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount2Info.text, "Elwynn Forest - PvP", "realm replacement tolerates native capitalization differences")
env.WOW_PROJECT_ID = 18
friend.gameAccountInfo, friend.totalGameAccounts, friend.gameAccounts = secondary, 1, nil
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "Elwynn Forest\nRuleset: PvP", "primary Forever tooltip labels ruleset correctly")
local button = { friendIndex = 1, friendData = friend }
env.BetterFriendsList_Button_OnEnter(button)
equal(env.FriendsTooltipGameAccount1Info.text, "Elwynn Forest\nRuleset: PvP", "actual mouseover dispatch shows target ruleset without Glue globals")
BFL.IsForever, BFL.HasSecretValues = true, false
env.BetterFriendsList_Button_OnEnter(button)
equal(env.FriendsTooltipGameAccount1Info.text, "Elwynn Forest\nRuleset: PvP", "Forever ruleset dispatch is independent of the Secret Values capability")
BFL.HasSecretValues = true
primary.wowProjectID, primary.realmName = 18, "CAMWOW EU5 Realm 9 RP PvP"
friend.totalGameAccounts, friend.gameAccounts = 2, { secondary, primary }
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount2Info.text, "Stormwind\nRuleset: RP-PvP", "secondary same-project tooltip retains its ruleset after native-style formatting")
friend.totalGameAccounts, friend.gameAccounts = 1, nil
secondary.characterLevel, secondary.areaName = 0, ""
secondary.richPresence = "In the world"
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "In the world - PvP", "presence-only layout adds a known ruleset even without realm text")
secondary.realmName = nil
secondary.richPresence = "Elwynn Forest - CAMWOW EU5 Realm 9 RP PvP"
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "Elwynn Forest - RP-PvP", "realm evidence from target presence is replaced without leaking CAMWOW")
io.write("[OK] mixed-client tooltips: " .. count .. " checks\n")
]=])

local BFL = { L = {}, modules = {}, IsForever = true }
function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
function BFL:GetModule(name) return self.modules[name] end
function BFL:IsSecret() return false end
function BFL.IsSocialQueueSupported() return false end
local realm = "CAMWOW US1 Realm 1 PVP (PVP) New"
local env = setmetatable({ SlashCmdList = {},
	Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } },
	RegionalUniqueNamesEnabled = function() return true end,
	GetPlayerInfoByGUID = function() return nil, nil, nil, nil, nil, "Ada Lovelace", realm, 10 end,
	C_BattleNet = { GetAccountInfoByGUID = function() return nil end },
	UnitFactionGroup = function() return "Alliance" end, strmatch = string.match,
}, { __index = _G })
env._G = env
local function execute(path, suffix)
	return assert(load(read(path) .. (suffix or ""), "@" .. path, "t", env))("BetterFriendlist", BFL)
end
execute(repo .. "/Utils/ClassicCompat.lua")
execute(native .. "/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua")
local entryType = execute(repo .. "/Modules/QuickJoin.lua", "\nreturn QuickJoinEntry")
local entry = setmetatable({ groupInfo = { leaderGUID = "Player-18-1234" }, displayedQueues = {},
	displayedMembers = { { guid = "Player-18-1234" } } }, entryType)
local tooltip = { lines = {} }
function tooltip:SetText(text) self.lines[#self.lines + 1] = text end
function tooltip:AddLine(text) self.lines[#self.lines + 1] = text or "" end
entry:ApplyToTooltip(tooltip)
local found = false
for _, line in ipairs(tooltip.lines) do
	if line:find("Leader:", 1, true) then
		found = true
		assert(line:find("Ada Lovelace", 1, true) and not line:find(realm, 1, true), "GUID realm was treated as surname")
	end
end
assert(found, "QuickJoin leader path was not exercised")
io.write("[OK] QuickJoin GUID leader preserves full regional name without realm\n")
