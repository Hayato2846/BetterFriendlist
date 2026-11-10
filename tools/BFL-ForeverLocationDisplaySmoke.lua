-- lua tools/BFL-ForeverLocationDisplaySmoke.lua <repo> <WoW UI source> [Forever UI source]
-- Production formatters and tooltip/QuickJoin paths; engine widgets/APIs are mocked.
-- The optional third argument supplies Camelot NameUtil when testing Retail's tooltip.
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

do
	local savedFormat = BFL.modules.DB.GetNameFormatString
	local format = "%name% (%character%)"
	BFL.modules.DB.GetNameFormatString = function() return format end
	env.BetterFriendlistDB.colorClassNames = true
	env.BetterFriendlistDB.showFactionIcons = true
	env.GetClassColorForFriend = function(row) return BFL.ClassUtils:GetClassColorForFriend(row) end
	local seasonIcon = "|TTimerunningIcon:12:12|t"
	env.TimerunningUtil = { AddSmallIcon = function(name) return seasonIcon .. name end }
	local row = { type = "bnet", friendLevel = 3, accountName = "Hayato Test", characterName = "Hayato Test",
		connected = true, factionName = "Horde", classID = 8, timerunningSeasonID = 1 }
	local decorated = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. seasonIcon .. "Hayato Test"
	local wrapped = "|cff69ccf0(" .. decorated .. ")|r"
	equal(brokerDisplay(row), "|cff69ccf0" .. decorated .. "|r",
		"Default broker Title name keeps the whole decorated character without parentheses")
	format = "%nickname% (%character%)"
	equal(brokerDisplay(row), "|cff69ccf0" .. decorated .. "|r", "The broker never repeats a Title character as the fallback nickname")
	row.settingsSample, row.sampleNickname = true, "Raid buddy"
	equal(brokerDisplay(row), "Raid buddy " .. wrapped, "A configured nickname still appears beside the decorated Title character")
	format = "%battletag% (%character%)"
	equal(brokerDisplay(row), "|cff69ccf0" .. decorated .. "|r", "The broker never repeats a Title character as the fallback BattleTag")
	row.battleTag = "ActualTag#1234"
	equal(brokerDisplay(row), "ActualTag " .. wrapped, "A present BattleTag still appears beside the decorated Title character")
	row.battleTag = nil
	format = "%name% (%character%)"
	row.titleCustomName = "My mage"
	equal(brokerDisplay(row), "My mage " .. wrapped, "A distinct broker alias retains the character in parentheses")
	row.titleCustomName = nil
	row.friendLevel = 1
	equal(brokerDisplay(row), "Hayato Test " .. wrapped, "The broker keeps the account label for a regular Battle.net friend")
	row.friendLevel, row.battleTag, row.accountName = 3, "SafeTag#1234", "Private account label"
	BFL.StreamerMode = { IsActive = function() return true end }
	equal(brokerDisplay(row), "SafeTag " .. wrapped, "The broker preserves the selected streamer label")
	BFL.StreamerMode = nil
	BFL.modules.DB.GetNameFormatString = savedFormat
	env.BetterFriendlistDB.colorClassNames, env.BetterFriendlistDB.showFactionIcons = false, nil
end

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
equal(list:FormatInfoLine(friend), "Elwynn, PvP", "Retail displays a known Forever target ruleset in the default info line")
for _, modern in ipairs({ false, true }) do
	for _, variant in ipairs({ { "Normal", "Normal" }, { "PvP", "PvP" }, { "RP", "RP" }, { "RP-PvP", "RP-PvP" } }) do
		local snapshot = normal("Ada#1234")
		local game = snapshot.gameAccountInfo
		game.realmName, game.realmDisplayName, game.areaName = nil, nil, nil
		game.richPresence = "Forever · " .. variant[1] .. " · Ashenvale"
		local current = setup({ snapshot }, { modern = modern })
		current.BFL.IsForever, current.env.WOW_PROJECT_ID = false, 1
		current.list:UpdateFriendsList()
		local row = assert(current.list.friendsList[1])
		equal(row.areaName, "Ashenvale", "Retail ingests the Forever presence's area without the game/ruleset prefix")
		equal(game.realmName, nil, "Native account identity remains unchanged")
		equal(select(2, current.list:GetFormattedButtonText(row)), "Ashenvale, " .. variant[2], "Both layouts display the Forever ruleset from presence")
		current.list.settingsCache.infoFormatPreset = "custom"
		current.list.settingsCache.infoFormatString = "%zone% (%ruleset%)"
		equal(current.list:FormatInfoLine(row), "Ashenvale (" .. variant[2] .. ")", "Custom formats reuse the same parsed ruleset")
		current.list.settingsCache.nameFormatString = "%character% [%ruleset%]"
		equal(current.list:GetDisplayName(row), "Ada Lovelace [" .. variant[2] .. "]", "Name formats share the ruleset parsed from presence")
		row.gameAccountInfo.richPresence = "Forever · PvP · Ashenvale"
		equal(current.list:GetDisplayName(row), "Ada Lovelace [PvP]", "A changed presence invalidates the cached ruleset label")
	end
end
-- Warm caches, then change only the target project. Identical realm/ruleset
-- labels and a stale presence must not allow cached Forever tokens in Retail.
for _, modern in ipairs({ false, true }) do
	for _, replaceSnapshot in ipairs({ false, true }) do
		local snapshot = normal("Stable#1234")
		local current = setup({ snapshot }, { modern = modern, nameFormat = "%character% %ruleset%" })
		current.BFL.IsForever, current.env.WOW_PROJECT_ID = false, 1
		current.env.BetterFriendlistDB.colorClassNames = false
		current.env.GetDB = function() return current.BFL.modules.DB end
		current.env.GetFriendGameName = function() return "WoW" end
		local currentBroker = assert(load(between(broker, "local function GetDisplayLocation(", "local function GetFriendsList()")
			.. between(broker, "local function ReplaceTokenCaseInsensitive(", "-- Helper: Get colored level text")
			.. "\nreturn GetFriendDisplayName", "@broker client transitions", "t", current.env))()
		local firstRow, stableUID
		for _, state in ipairs({
			{ 18, 123, nil, "Forever · Normal · Ashenvale", nil, "Ashenvale", "Normal" },
			{ 1, 123, nil, "Forever · Normal · Ashenvale", nil, "Online", "" },
			{ 1, 123, "Normal", "Forever · Normal · Ashenvale", "Stormwind", "Stormwind", "" },
			{ 18, 123, nil, "Forever · PvP · Ashenvale", nil, "Ashenvale", "PvP" },
			{ 1, 456, nil, "Forever - PvP - Ashenvale", nil, "Online", "" },
			{ 1, 456, "PvP", "Forever · PvP · Ashenvale", "Valdrakken", "Valdrakken", "" },
			{ 18, 789, nil, "Forever · RP · Elwynn", nil, "Elwynn", "RP" },
			{ 1, 456, "Retail Realm", "Stormwind - Retail Realm", "Stormwind", "Stormwind", "" },
		}) do
			local nextAccount = game(true)
			nextAccount.wowProjectID, nextAccount.gameAccountID = state[1], state[2]
			nextAccount.realmName, nextAccount.realmDisplayName = state[3], state[3]
			nextAccount.richPresence, nextAccount.areaName = state[4], state[5]
			if replaceSnapshot then
				snapshot.gameAccountInfo = nextAccount
			else
				for key in pairs(snapshot.gameAccountInfo) do snapshot.gameAccountInfo[key] = nil end
				for key, value in pairs(nextAccount) do snapshot.gameAccountInfo[key] = value end
			end
			current.list:UpdateFriendsList()
			local row = assert(current.list.friendsList[1])
			firstRow, stableUID = firstRow or row, stableUID or row.uid
			equal(row, firstRow, "client switches reuse the same pooled friend row")
			equal(row.uid, stableUID, "client switches preserve the friend identity")
			local expectedName = "Ada Lovelace" .. (state[7] ~= "" and (" " .. state[7]) or "")
			equal(current.list:GetDisplayName(row), expectedName, "persistent name cache follows the current project")
			equal(currentBroker(row), expectedName, "broker ruleset token follows the current project")
			local line1, line2 = current.list:GetFormattedButtonText(row)
			equal(line1, expectedName, "rendered row follows the current project")
			equal(line2, state[6] .. (state[7] ~= "" and (", " .. state[7]) or ""), "default info clears ruleset on every Retail transition")
			equal(select(2, current.list:GetFormattedButtonText(row)), line2, "warmed rendered cache remains correct")
			current.list.settingsCache.infoFormatPreset, current.list.settingsCache.infoFormatString = "custom", "%zone%, %ruleset%"
			equal(current.list:FormatInfoLine(row), line2, "custom info clears ruleset and its dangling separator")
			current.list.settingsCache.infoFormatPreset = "default"
		end
	end
end

-- Selecting a preferred active account must override the focused account in
-- both directions, and an offline preferred account must not remain displayed.
for _, modern in ipairs({ false, true }) do
	local snapshot = normal("Preferred#1234")
	local foreverAccount, retailAccount = game(true), game(true)
	foreverAccount.gameAccountID, foreverAccount.realmName, foreverAccount.areaName = 201, nil, nil
	foreverAccount.richPresence = "Forever · Normal · Ashenvale"
	retailAccount.gameAccountID, retailAccount.wowProjectID = 202, 1
	retailAccount.realmName, retailAccount.realmDisplayName, retailAccount.areaName = "Normal", "Normal", "Stormwind"
	retailAccount.richPresence = "Stormwind - Normal"
	snapshot.gameAccountInfo = foreverAccount
	local current = setup({ snapshot }, { modern = modern, nameFormat = "%character% %ruleset%" })
	current.BFL.IsForever, current.env.WOW_PROJECT_ID = false, 1
	local activeAccounts, preferredID = { foreverAccount, retailAccount }
	current.env.C_BattleNet.GetFriendNumGameAccounts = function() return #activeAccounts end
	current.env.C_BattleNet.GetFriendGameAccountInfo = function(_, index) return activeAccounts[index] end
	current.BFL.modules.DB.GetPreferredGameAccount = function() return preferredID end
	current.BFL.modules.DB.SetPreferredGameAccount = function(_, _, id) preferredID = id end
	current.BFL.ForceRefreshFriendsList = function() current.list:UpdateFriendsList() end
	current.list:UpdateFriendsList()
	local uid = current.list.friendsList[1].uid
	for _, selection in ipairs({ { 201, "Ashenvale, Normal" }, { 202, "Stormwind" }, { 201, "Ashenvale, Normal" } }) do
		current.list:SetPreferredGameAccount(uid, selection[1])
		local row = current.list.friendsList[1]
		equal(row.gameAccountInfo.gameAccountID, selection[1], "preferred account controls ruleset metadata")
		equal(select(2, current.list:GetFormattedButtonText(row)), selection[2], "preferred client changes invalidate the rendered ruleset")
	end
	retailAccount.areaName, retailAccount.realmName, retailAccount.realmDisplayName = nil, nil, nil
	retailAccount.richPresence = "Forever · Normal · Ashenvale"
	current.list:SetPreferredGameAccount(uid, 202)
	equal(select(2, current.list:GetFormattedButtonText(current.list.friendsList[1])), "Online", "preferred Retail account also rejects old Forever presence while location is missing")
	retailAccount.areaName, retailAccount.realmName, retailAccount.richPresence = "Stormwind", "Normal", "Stormwind - Normal"
	current.list:SetPreferredGameAccount(uid, 201)
	foreverAccount.isOnline = false
	snapshot.gameAccountInfo, activeAccounts = retailAccount, { retailAccount }
	current.list:UpdateFriendsList()
	equal(select(2, current.list:GetFormattedButtonText(current.list.friendsList[1])), "Stormwind", "offline preferred Forever account does not leave a Retail ruleset")
	foreverAccount.isOnline, foreverAccount.richPresence = true, "Forever · PvP · Elwynn"
	activeAccounts = { retailAccount, foreverAccount }
	current.list:UpdateFriendsList()
	equal(select(2, current.list:GetFormattedButtonText(current.list.friendsList[1])), "Elwynn, PvP", "returning preferred Forever account uses its new ruleset")
end
io.write("[OK] location display formatters and client transitions: " .. assertions .. " checks\n")
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
env.WOW_PROJECT_ID = 1
BFL.IsForever = false
secondary.realmName, secondary.realmDisplayName, secondary.areaName = nil, nil, nil
secondary.richPresence = "Forever · Normal · Ashenvale"
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "Ashenvale\nRuleset: Normal", "Retail tooltip formats structured presence like a Forever tooltip")
secondary.richPresence = "Forever - PvP - Lune-d’Argent"
showSafe({}, {}, friend)
equal(env.FriendsTooltipGameAccount1Info.text, "Lune-d’Argent\nRuleset: PvP", "ASCII presence keeps the zone and avoids duplicate rulesets")
for _, replaceSnapshot in ipairs({ false, true }) do
	for _, state in ipairs({
		{ 18, nil, nil, "Forever · Normal · Ashenvale", "Ashenvale\nRuleset: Normal" },
		{ 1, nil, nil, "Forever · Normal · Ashenvale", "" },
		{ 1, "Normal", "Stormwind", "Forever · Normal · Ashenvale", "Zone: Stormwind\nRealm: Normal" },
		{ 18, nil, nil, "Forever · PvP · Elwynn", "Elwynn\nRuleset: PvP" },
		{ 1, nil, nil, "Forever - PvP - Elwynn", "" },
		{ 1, "PvP", "Valdrakken", "Valdrakken - PvP", "Zone: Valdrakken\nRealm: PvP" },
	}) do
		if replaceSnapshot then secondary = { gameAccountID = 102, clientProgram = "WoW", isOnline = true } end
		secondary.isInCurrentRegion = true
		secondary.wowProjectID, secondary.realmName, secondary.realmDisplayName = state[1], state[2], state[2]
		secondary.areaName, secondary.richPresence = state[3], state[4]
		friend.gameAccountInfo = secondary
		showSafe({}, {}, friend)
		equal(env.FriendsTooltipGameAccount1Info.text, state[5], "same tooltip widget replaces all old client/ruleset text")
	end
end
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
execute((arg[3] or native) .. "/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua")
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
