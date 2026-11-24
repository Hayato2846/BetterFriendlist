-- Modules/FilterSortRegistry.lua
-- Central registry for built-in and custom QuickFilters / Sorters.

local ADDON_NAME, BFL = ...

local Registry = BFL:RegisterModule("FilterSortRegistry", {})
local L = BFL.L or {}
local IntlCompat = BFL.IntlCompat

Registry.FALLBACK_FILTER = "all"
Registry.FALLBACK_PRIMARY_SORT = "game"
Registry.FALLBACK_SECONDARY_SORT = "status"
Registry.MAX_FILTER_DEPTH = 5
Registry.MAX_FILTER_NODES = 50
Registry.MAX_SORT_STEPS = 8

local BFL_ICON_PREFIX = "Interface\\AddOns\\BetterFriendlist\\Icons\\"
local BLIZZARD_ICON_PREFIX = "Interface\\Icons\\"
local THEME_ICON_PREFIX = "Interface\\AddOns\\BetterFriendlist\\Textures\\ThemeIcons\\"
local NATIVE_FILTER_ICONS = {
	["logo-wow-retail"] = {
		fallbackAtlas = "friends-icon-addFriend-logo-WoW",
		texture = "Interface\\ChatFrame\\UI-ChatIcon-WoW",
		crop = { 0.25, 0.75, 0.25, 0.75 },
	},
	["logo-wow-forever"] = {
		fallbackAtlas = "friends-icon-addFriend-logo-WoW",
		texture = "Interface\\ChatFrame\\UI-ChatIcon-WoW",
		crop = { 0.21, 0.79, 0.21, 0.79 },
		preserveAspect = true,
		scale = 1.12,
	},
	["friends-icon-addFriend-logo-battleNet"] = {
		fallbackAtlas = "Battlenet-ClientIcon-App",
		texture = "Interface\\FriendsFrame\\Battlenet-Battleneticon",
		crop = { 0, 1, 0, 1 },
	},
	["friends-status-online"] = {
		texture = "Interface\\FriendsFrame\\StatusIcon-Online",
		crop = { 0.10, 0.90, 0.10, 0.90 },
	},
	["friends-status-offline"] = {
		texture = "Interface\\FriendsFrame\\StatusIcon-Offline",
		crop = { 0.14, 0.86, 0.14, 0.86 },
	},
}
local LEGACY_FILTER_ICON_ATLASES = {
	["filter-retail"] = "logo-wow-retail",
	["filter-wow"] = "logo-wow-retail",
	["filter-bnet"] = "friends-icon-addFriend-logo-battleNet",
	["filter-online"] = "friends-status-online",
	["filter-offline"] = "friends-status-offline",
}
local THEME_NEUTRAL_ICON_NAMES = {
	["check-circle"] = true,
	["class"] = true,
	["faction"] = true,
	["filter"] = true,
	["filter-all"] = true,
	["filter-bnet"] = true,
	["filter-hide-afk"] = true,
	["filter-offline"] = true,
	["filter-online"] = true,
	["filter-retail"] = true,
	["filter-wow"] = true,
	["game"] = true,
	["guild"] = true,
	["level"] = true,
	["name"] = true,
	["realm"] = true,
	["sliders"] = true,
	["star"] = true,
	["status"] = true,
	["zone"] = true,
}

local function GetDB()
	return BFL:GetModule("DB")
end

local function GetLocale(key, fallback)
	return (L and L[key]) or fallback or key
end

local function DeepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		copy[DeepCopy(k, seen)] = DeepCopy(v, seen)
	end
	return copy
end

local function IsArray(tbl)
	if type(tbl) ~= "table" then
		return false
	end
	local count = 0
	for key in pairs(tbl) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end
		count = count + 1
	end
	return count == #tbl
end

local function AddUnique(list, id)
	if not id then
		return
	end
	for _, existing in ipairs(list) do
		if existing == id then
			return
		end
	end
	table.insert(list, id)
end

local function IsSecretValue(value)
	return BFL.IsSecret and BFL:IsSecret(value) or false
end

local function SafeString(value)
	if IsSecretValue(value) then
		return ""
	end
	if value == nil then
		return ""
	end
	local ok, str = pcall(tostring, value)
	if not ok or IsSecretValue(str) or type(str) ~= "string" or str:sub(1, 2) == "|K" then
		return ""
	end
	return str
end

function Registry:InvalidateCaches()
	self.cacheVersion = (self.cacheVersion or 0) + 1
	BFL.FilterSortRegistryVersion = (BFL.FilterSortRegistryVersion or 0) + 1
	self.runtimeCache = nil
	self.ensuredDB = nil
	self.ensuredDBSettingsVersion = nil
	self.ensuredDBCacheVersion = nil
end

local function GetRegistryCache(registry)
	local db = BetterFriendlistDB
	local cacheVersion = registry.cacheVersion or 0
	local settingsVersion = BFL.SettingsVersion or 0
	local betaEnabled = db and db.enableBetaFeatures == true
	local cache = registry.runtimeCache
	if
		cache
		and cache.db == db
		and cache.cacheVersion == cacheVersion
		and cache.settingsVersion == settingsVersion
		and cache.betaEnabled == betaEnabled
	then
		return cache
	end

	cache = {
		db = db,
		cacheVersion = cacheVersion,
		settingsVersion = settingsVersion,
		betaEnabled = betaEnabled,
		quickFilterEntries = {},
		quickFilterPlans = {},
	}
	registry.runtimeCache = cache
	return cache
end

local function NormalizeString(value)
	local text = SafeString(value)
	if text == "" then
		return ""
	end
	if BFL.StripAccents then
		text = BFL:StripAccents(text)
	end
	return text:lower()
end

local function IsEmptyValue(value)
	if value == nil then
		return true
	end
	if type(value) == "string" then
		return value == ""
	end
	if type(value) == "table" then
		return next(value) == nil
	end
	return false
end

local function GetGameInfo(friend)
	return friend and (friend.gameAccountInfo or (friend.accountInfo and friend.accountInfo.gameAccountInfo))
end

local function GetClient(friend)
	local gameInfo = GetGameInfo(friend)
	return (friend and friend.client) or (gameInfo and gameInfo.clientProgram) or ""
end

local function IsMobileClient(client)
	return client == "BSAp"
end

local function IsPlayableClient(client)
	return client and client ~= "" and client ~= "App" and client ~= "CLNT" and client ~= "BSAp"
end

local function GetVisibleGameAccounts(friend)
	local accounts = {}
	local seen = {}
	local readable = BFL.IsReadableGameAccountInfo
	local function AddAccount(gameAccountInfo)
		if IsSecretValue(gameAccountInfo) or type(gameAccountInfo) ~= "table"
			or (readable and not readable(gameAccountInfo)) or seen[gameAccountInfo]
		then
			return
		end
		seen[gameAccountInfo] = true
		accounts[#accounts + 1] = gameAccountInfo
	end

	AddAccount(GetGameInfo(friend))
	if friend and not IsSecretValue(friend.gameAccounts) and type(friend.gameAccounts) == "table"
		and (not readable or readable(friend.gameAccounts))
	then
		for _, gameAccountInfo in ipairs(friend.gameAccounts) do
			AddAccount(gameAccountInfo)
		end
	end
	return accounts
end

local function IsGameAccountOnline(friend, gameAccountInfo)
	if not gameAccountInfo then
		return false
	end
	if IsSecretValue(gameAccountInfo.isOnline) then return false end
	if gameAccountInfo.isOnline ~= nil then
		return gameAccountInfo.isOnline and true or false
	end
	return gameAccountInfo == GetGameInfo(friend) and friend and friend.connected == true
end

local function HasOnlineGameAccount(friend, predicate)
	for _, gameAccountInfo in ipairs(GetVisibleGameAccounts(friend)) do
		if IsGameAccountOnline(friend, gameAccountInfo) and (not predicate or predicate(gameAccountInfo)) then
			return true
		end
	end
	return false
end

local function IsMobileOnlyFriend(friend)
	if not friend then
		return false
	end

	local hasOnlineMobileAccount = friend.isMobile == true
	for _, gameAccountInfo in ipairs(GetVisibleGameAccounts(friend)) do
		if IsGameAccountOnline(friend, gameAccountInfo) then
			local client = gameAccountInfo.clientProgram
			if IsMobileClient(client) then
				hasOnlineMobileAccount = true
			elseif IsPlayableClient(client) then
				return false
			end
		end
	end
	return hasOnlineMobileAccount
end

local function IsFriendOnline(friend)
	if not friend then
		return false
	end
	if friend.connected ~= nil then
		return friend.connected and true or false
	end
	if friend.isOnline ~= nil then
		if BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline and IsMobileOnlyFriend(friend) then
			return false
		end
		return friend.isOnline and true or false
	end
	local gameInfo = GetGameInfo(friend)
	local isOnline = gameInfo and gameInfo.isOnline and true or false
	if isOnline and BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline and IsMobileOnlyFriend(friend) then
		return false
	end
	return isOnline
end

local function IsAFK(friend)
	return friend and (friend.isAFK or friend.afk) and true or false
end

local function IsDND(friend)
	return friend and (friend.isDND or friend.dnd) and true or false
end

local function IsMobile(friend)
	return IsMobileOnlyFriend(friend)
end

local function GetFriendUID(friend)
	if not friend then
		return nil
	end
	if friend.uid then
		return friend.uid
	end
	local id = friend.id
	if not IsSecretValue(id) and type(id) == "string" and (id:match("^bnet_") or id:match("^wow_")) then
		return id
	end
	if friend.bnetAccountID then
		return "bnet_" .. tostring(friend.bnetAccountID)
	end
	if friend.name then
		return "wow_" .. tostring(friend.name)
	end
	return nil
end

local function GetNickname(friend)
	if friend and friend.settingsSample then
		return friend.sampleNickname
	end
	local DB = GetDB()
	local uid = GetFriendUID(friend)
	if DB and DB.GetNickname and uid then
		return DB:GetNickname(uid)
	end
	return nil
end

local function GetFriendGroups(friend)
	if friend and friend.settingsSample then
		return friend.sampleGroupIDs
	end
	local uid = GetFriendUID(friend)
	local DB = BFL:GetModule("DB")
	return uid and DB and DB:GetFriendGroups(uid)
end

local function GetRecentlyAddedAgeDays(friend)
	if friend and friend.settingsSample then
		return friend.sampleRecentlyAdded
	end
	local uid = GetFriendUID(friend)
	if not uid or not BetterFriendlistDB or type(BetterFriendlistDB.recentlyAddedTimestamps) ~= "table" then
		return nil
	end
	local timestamp = BetterFriendlistDB.recentlyAddedTimestamps[uid]
	if not timestamp then
		return nil
	end
	local now = GetServerTime and GetServerTime() or time()
	return math.max(0, (now - timestamp) / 86400)
end

local function GetLastOnlineAgeDays(friend)
	if not friend or not friend.lastOnlineTime or friend.lastOnlineTime <= 0 then
		return nil
	end
	local now = GetServerTime and GetServerTime() or time()
	if friend.lastOnlineTime > now then
		return nil
	end
	return math.max(0, (now - friend.lastOnlineTime) / 86400)
end

local function GetStatusValue(friend)
	if not IsFriendOnline(friend) then
		return "offline"
	end
	if IsDND(friend) then
		return "dnd"
	end
	if IsAFK(friend) then
		return "afk"
	end
	if IsMobile(friend) then
		return "mobile"
	end
	return "online"
end

local function GetStatusPriority(friend)
	if not IsFriendOnline(friend) then
		return 4
	end
	if IsDND(friend) then
		return 2
	end
	if IsAFK(friend) or IsMobile(friend) then
		return 1
	end
	return 0
end

local GAME_PRIORITY = {
	WoW = 0,
	WTCG = 1,
	S1 = 2,
	D3 = 3,
	D4 = 3,
	ANBS = 3,
	OSI = 4,
	Pro = 5,
	Hero = 6,
	App = 8,
	BSAp = 9,
}

local function GetGamePriority(friend)
	if friend and friend.type == "wow" then
		return 0
	end
	local client = GetClient(friend)
	if client == (BNET_CLIENT_WOW or "WoW") then
		local gameInfo = GetGameInfo(friend)
		local projectID = gameInfo and gameInfo.wowProjectID
		if projectID and WOW_PROJECT_MAINLINE and projectID ~= WOW_PROJECT_MAINLINE then
			return 0.5
		end
		return 0
	end
	return GAME_PRIORITY[client] or (client ~= "" and 7 or 10)
end

local function GetFactionPriority(friend)
	local faction = friend and friend.factionName
	if not faction or faction == "" then
		return 3
	end
	local playerFaction = UnitFactionGroup and UnitFactionGroup("player")
	if playerFaction and faction == playerFaction then
		return 0
	end
	if faction == "Alliance" then
		return 1
	end
	if faction == "Horde" then
		return 2
	end
	return 3
end

local function GetFieldValue(friend, field)
	if not friend then
		return nil
	end

	if field == "type" then
		return friend.type
	elseif field == "online" then
		return IsFriendOnline(friend)
	elseif field == "status" then
		return GetStatusValue(friend)
	elseif field == "afk" then
		return IsAFK(friend)
	elseif field == "dnd" then
		return IsDND(friend)
	elseif field == "mobile" then
		return IsMobile(friend)
	elseif field == "favorite" then
		return friend.isFavorite and true or false
	elseif field == "group" then
		return GetFriendGroups(friend)
	elseif field == "note" then
		return friend.note or friend.notes or friend.customMessage
	elseif field == "nickname" then
		return GetNickname(friend)
	elseif field == "battleTag" then
		return friend.battleTag
	elseif field == "character" then
		return friend.characterName or friend.name
	elseif field == "realm" then
		return friend.realmName
	elseif field == "level" then
		return friend.level or (GetGameInfo(friend) and GetGameInfo(friend).characterLevel)
	elseif field == "zone" then
		return friend.areaName or friend.area
	elseif field == "class" then
		return friend.className
	elseif field == "faction" then
		return friend.factionName
	elseif field == "guild" then
		return friend.guildName
	elseif field == "client" then
		return GetClient(friend)
	elseif field == "game" then
		return friend.gameName or (GetGameInfo(friend) and GetGameInfo(friend).richPresence) or GetClient(friend)
	elseif field == "wowProject" then
		if friend.type == "wow" then return WOW_PROJECT_ID end
		return GetGameInfo(friend) and GetGameInfo(friend).wowProjectID
	elseif field == "multiAccount" then
		local count = friend.numGameAccounts or (friend.gameAccounts and #friend.gameAccounts) or 0
		return count > 1
	elseif field == "lastOnline" then
		return GetLastOnlineAgeDays(friend)
	elseif field == "recentlyAdded" then
		return GetRecentlyAddedAgeDays(friend)
	elseif field == "accountCount" then
		return friend.numGameAccounts or (friend.gameAccounts and #friend.gameAccounts) or 0
	elseif field == "tag" then
		if friend.settingsSample then return friend.sampleTagText or "" end
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetSearchText and FriendTags:GetSearchText(friend) or ""
	elseif field == "tagSource" then
		if friend.settingsSample then return friend.sampleTagSource or "" end
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetTagSourceText and FriendTags:GetTagSourceText(friend) or ""
	elseif field == "tagCount" then
		if friend.settingsSample then return friend.sampleTagCount or 0 end
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetTagCount and FriendTags:GetTagCount(friend) or 0
	elseif field == "hasTag" then
		if friend.settingsSample then return (friend.sampleTagCount or 0) > 0 end
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetTagCount and FriendTags:GetTagCount(friend) > 0 or false
	elseif field == "displayName" or field == "name" then
		return friend.displayName or friend.name or friend.accountName or friend.battleTag or friend.characterName
	end

	return nil
end

local function AddUniqueFilterValue(values, seen, value)
	local normalized = NormalizeString(value)
	if normalized == "" or seen[normalized] then
		return
	end
	seen[normalized] = true
	values[#values + 1] = value
end

local function GetMultiAccountFilterValues(friend, field)
	local values = {}
	local seen = {}
	if not friend then
		return values
	end

	if field == "character" then
		AddUniqueFilterValue(values, seen, friend.characterName or (friend.type == "wow" and friend.name))
	elseif field == "realm" then
		AddUniqueFilterValue(values, seen, friend.realmName)
	elseif field == "client" then
		AddUniqueFilterValue(values, seen, GetClient(friend))
	elseif field == "game" then
		AddUniqueFilterValue(values, seen, friend.gameName)
	elseif field == "wowProject" and friend.type == "wow" then
		AddUniqueFilterValue(values, seen, WOW_PROJECT_ID)
	end

	if friend.type ~= "bnet" then
		return values
	end

	local wowClient = BNET_CLIENT_WOW or "WoW"
	for _, gameAccountInfo in ipairs(GetVisibleGameAccounts(friend)) do
		if field == "character" and gameAccountInfo.clientProgram == wowClient then
			AddUniqueFilterValue(values, seen, gameAccountInfo.characterName)
		elseif field == "realm" and gameAccountInfo.clientProgram == wowClient then
			AddUniqueFilterValue(values, seen, gameAccountInfo.realmName)
		elseif field == "client" then
			AddUniqueFilterValue(values, seen, gameAccountInfo.clientProgram)
		elseif field == "game" then
			AddUniqueFilterValue(values, seen, gameAccountInfo.richPresence or gameAccountInfo.clientProgram)
		elseif field == "wowProject" and gameAccountInfo.clientProgram == wowClient then
			AddUniqueFilterValue(values, seen, gameAccountInfo.wowProjectID)
		end
	end

	return values
end

local FILTER_FIELDS = {
	{ id = "type", labelKey = "FILTER_BUILDER_FIELD_TYPE", type = "enum", values = { "wow", "bnet" } },
	{ id = "online", labelKey = "FILTER_BUILDER_FIELD_ONLINE", type = "boolean" },
	{ id = "status", labelKey = "FILTER_BUILDER_FIELD_STATUS", type = "enum", values = { "online", "offline", "afk", "dnd", "mobile" } },
	{ id = "afk", labelKey = "FILTER_BUILDER_FIELD_AFK", type = "boolean" },
	{ id = "dnd", labelKey = "FILTER_BUILDER_FIELD_DND", type = "boolean" },
	{ id = "mobile", labelKey = "FILTER_BUILDER_FIELD_MOBILE", type = "boolean" },
	{ id = "favorite", labelKey = "FILTER_BUILDER_FIELD_FAVORITE", type = "boolean" },
	{ id = "group", labelKey = "FILTER_BUILDER_FIELD_GROUP", type = "enum" },
	{ id = "note", labelKey = "FILTER_BUILDER_FIELD_NOTE", type = "string" },
	{ id = "nickname", labelKey = "FILTER_BUILDER_FIELD_NICKNAME", type = "string" },
	{ id = "battleTag", labelKey = "FILTER_BUILDER_FIELD_BATTLETAG", type = "string" },
	{ id = "character", labelKey = "FILTER_BUILDER_FIELD_CHARACTER", type = "string" },
	{ id = "realm", labelKey = "FILTER_BUILDER_FIELD_REALM", type = "string" },
	{ id = "level", labelKey = "FILTER_BUILDER_FIELD_LEVEL", type = "number" },
	{ id = "zone", labelKey = "FILTER_BUILDER_FIELD_ZONE", type = "string" },
	{ id = "class", labelKey = "FILTER_BUILDER_FIELD_CLASS", type = "string" },
	{ id = "faction", labelKey = "FILTER_BUILDER_FIELD_FACTION", type = "enum", values = { "Alliance", "Horde" } },
	{ id = "guild", labelKey = "FILTER_BUILDER_FIELD_GUILD", type = "string" },
	{ id = "client", labelKey = "FILTER_BUILDER_FIELD_CLIENT", type = "string" },
	{ id = "game", labelKey = "FILTER_BUILDER_FIELD_GAME", type = "string" },
	{ id = "wowProject", labelKey = "FILTER_BUILDER_FIELD_WOW_PROJECT", type = "number" },
	{ id = "multiAccount", labelKey = "FILTER_BUILDER_FIELD_MULTI_ACCOUNT", type = "boolean" },
	{ id = "lastOnline", labelKey = "FILTER_BUILDER_FIELD_LAST_ONLINE", type = "number" },
	{ id = "recentlyAdded", labelKey = "FILTER_BUILDER_FIELD_RECENTLY_ADDED", type = "number" },
	{ id = "tag", labelKey = "FILTER_BUILDER_FIELD_TAG", type = "string" },
	{ id = "tagSource", labelKey = "FILTER_BUILDER_FIELD_TAG_SOURCE", type = "enum", values = { "blizzard", "custom" } },
	{ id = "tagCount", labelKey = "FILTER_BUILDER_FIELD_TAG_COUNT", type = "number" },
	{ id = "hasTag", labelKey = "FILTER_BUILDER_FIELD_HAS_TAG", type = "boolean" },
}

local FILTER_FIELD_MAP = {}
for _, field in ipairs(FILTER_FIELDS) do
	FILTER_FIELD_MAP[field.id] = field
end

local function NormalizeLocationSortID(id)
	if BFL.IsForever and id == "realm" then
		return "ruleset"
	elseif not BFL.IsForever and id == "ruleset" then
		return "realm"
	end
	return id
end

local SORT_FIELDS = {
	{ id = "status", labelKey = "SORT_STATUS", type = "number", defaultDirection = "asc" },
	{ id = "name", labelKey = "SORT_NAME", type = "string", defaultDirection = "asc" },
	{ id = "displayName", labelKey = "SORT_NAME", type = "string", defaultDirection = "asc" },
	{ id = "nickname", labelKey = "FILTER_BUILDER_FIELD_NICKNAME", type = "string", defaultDirection = "asc" },
	{ id = "favorite", labelKey = "FILTER_BUILDER_FIELD_FAVORITE", type = "boolean", defaultDirection = "desc" },
	{ id = "level", labelKey = "SORT_LEVEL", type = "number", defaultDirection = "desc" },
	{ id = "zone", labelKey = "SORT_ZONE", type = "string", defaultDirection = "asc" },
	{ id = "game", labelKey = "SORT_GAME", type = "number", defaultDirection = "asc" },
	{ id = "faction", labelKey = "SORT_FACTION", type = "number", defaultDirection = "asc" },
	{ id = "guild", labelKey = "SORT_GUILD", type = "string", defaultDirection = "asc" },
	{ id = "class", labelKey = "SORT_CLASS", type = "string", defaultDirection = "asc" },
	{ id = "realm", labelKey = "SORT_REALM", type = "string", defaultDirection = "asc" },
	{ id = "ruleset", labelKey = "BROKER_COLUMN_RULESET", type = "string", defaultDirection = "asc" },
	{ id = "lastOnline", labelKey = "FILTER_BUILDER_FIELD_LAST_ONLINE", type = "number", defaultDirection = "asc" },
	{ id = "recentlyAdded", labelKey = "FILTER_BUILDER_FIELD_RECENTLY_ADDED", type = "number", defaultDirection = "asc" },
	{ id = "accountCount", labelKey = "FILTER_BUILDER_FIELD_ACCOUNT_COUNT", type = "number", defaultDirection = "desc" },
	{ id = "type", labelKey = "FILTER_BUILDER_FIELD_TYPE", type = "string", defaultDirection = "asc" },
}

local SORT_FIELD_MAP = {}
for _, field in ipairs(SORT_FIELDS) do
	SORT_FIELD_MAP[field.id] = field
end

local FILTER_OPERATORS = {
	["is"] = true,
	isnot = true,
	contains = true,
	notcontains = true,
	starts = true,
	ends = true,
	empty = true,
	notempty = true,
	gt = true,
	gte = true,
	lt = true,
	lte = true,
	between = true,
	["in"] = true,
	notin = true,
}

local OPERATORS_BY_TYPE = {
	boolean = { "is", "isnot" },
	enum = { "is", "isnot", "in", "notin", "empty", "notempty" },
	string = { "contains", "notcontains", "is", "isnot", "starts", "ends", "empty", "notempty" },
	number = { "is", "isnot", "gt", "gte", "lt", "lte", "between", "empty", "notempty" },
}

local function HasValue(list, value)
	if type(list) ~= "table" then
		return false
	end
	for _, item in ipairs(list) do
		if tostring(item) == tostring(value) then
			return true
		end
	end
	return false
end

local function CompareScalar(actual, expected)
	if IsSecretValue(actual) or IsSecretValue(expected) then
		return false
	end
	if type(actual) == "boolean" or type(expected) == "boolean" then
		return (actual and true or false) == (expected == true or expected == "true" or expected == 1 or expected == "1")
	end
	if IntlCompat and IntlCompat.Equals then
		return IntlCompat.Equals(actual, expected)
	end
	return NormalizeString(actual) == NormalizeString(expected)
end

local function MatchesConditionValue(actual, op, expected)
	if IsSecretValue(actual) or IsSecretValue(expected) then
		return false
	end
	if op == "empty" then
		return IsEmptyValue(actual)
	elseif op == "notempty" then
		return not IsEmptyValue(actual)
	end

	if type(actual) == "table" and (op == "is" or op == "contains" or op == "in") then
		if type(expected) == "table" then
			for _, item in ipairs(expected) do
				if HasValue(actual, item) then
					return true
				end
			end
			return false
		end
		return HasValue(actual, expected)
	elseif type(actual) == "table" and (op == "isnot" or op == "notcontains" or op == "notin") then
		return not MatchesConditionValue(actual, "is", expected)
	end

	if op == "is" then
		return CompareScalar(actual, expected)
	elseif op == "isnot" then
		return not CompareScalar(actual, expected)
	elseif op == "contains" or op == "notcontains" or op == "starts" or op == "ends" then
		local actualText = NormalizeString(actual)
		local expectedText = NormalizeString(expected)
		local found = false
		if op == "starts" then
			found = expectedText == "" or actualText:sub(1, #expectedText) == expectedText
		elseif op == "ends" then
			found = expectedText == "" or actualText:sub(-#expectedText) == expectedText
		elseif IntlCompat and IntlCompat.Contains then
			found = IntlCompat.Contains(actual, expected)
		else
			found = actualText:find(expectedText, 1, true) ~= nil
		end
		if op == "notcontains" then
			return not found
		end
		return found
	elseif op == "in" or op == "notin" then
		local found = false
		if type(expected) == "table" then
			found = HasValue(expected, actual)
		else
			found = CompareScalar(actual, expected)
		end
		if op == "notin" then
			return not found
		end
		return found
	elseif op == "gt" or op == "gte" or op == "lt" or op == "lte" or op == "between" then
		local actualNumber = tonumber(actual)
		if not actualNumber then
			return false
		end
		if op == "between" then
			local minValue, maxValue
			if type(expected) == "table" then
				minValue = tonumber(expected[1] or expected.min)
				maxValue = tonumber(expected[2] or expected.max)
			end
			if not minValue or not maxValue then
				return false
			end
			return actualNumber >= minValue and actualNumber <= maxValue
		end
		local expectedNumber = tonumber(expected)
		if not expectedNumber then
			return false
		end
		if op == "gt" then
			return actualNumber > expectedNumber
		elseif op == "gte" then
			return actualNumber >= expectedNumber
		elseif op == "lt" then
			return actualNumber < expectedNumber
		elseif op == "lte" then
			return actualNumber <= expectedNumber
		end
	end

	return false
end

local NEGATED_MULTI_VALUE_OPERATORS = {
	isnot = true,
	notcontains = true,
	notin = true,
}

local MULTI_ACCOUNT_FILTER_FIELDS = {
	character = true,
	realm = true,
	client = true,
	game = true,
	wowProject = true,
}

local function MatchesFilterFieldValue(friend, field, op, expected)
	if not MULTI_ACCOUNT_FILTER_FIELDS[field] then
		return MatchesConditionValue(GetFieldValue(friend, field), op, expected)
	end

	local values = GetMultiAccountFilterValues(friend, field)
	if #values == 0 then
		return MatchesConditionValue(nil, op, expected)
	end

	if NEGATED_MULTI_VALUE_OPERATORS[op] then
		for _, value in ipairs(values) do
			if not MatchesConditionValue(value, op, expected) then
				return false
			end
		end
		return true
	end

	for _, value in ipairs(values) do
		if MatchesConditionValue(value, op, expected) then
			return true
		end
	end
	return false
end

local function EvaluateAST(node, friend, depth, stats)
	if type(node) ~= "table" then
		return true
	end
	depth = depth or 1
	stats = stats or { nodes = 0 }
	stats.nodes = stats.nodes + 1
	if depth > Registry.MAX_FILTER_DEPTH or stats.nodes > Registry.MAX_FILTER_NODES then
		return false
	end

	local result
	if node.type == "group" then
		local op = node.op == "OR" and "OR" or "AND"
		local children = type(node.children) == "table" and node.children or {}
		if #children == 0 then
			result = true
		elseif op == "OR" then
			result = false
			for _, child in ipairs(children) do
				if EvaluateAST(child, friend, depth + 1, stats) then
					result = true
					break
				end
			end
		else
			result = true
			for _, child in ipairs(children) do
				if not EvaluateAST(child, friend, depth + 1, stats) then
					result = false
					break
				end
			end
		end
	elseif node.type == "condition" then
		local fieldDef = FILTER_FIELD_MAP[node.field]
		local op = FILTER_OPERATORS[node.op] and node.op or "is"
		if not fieldDef then
			result = false
		else
			result = MatchesFilterFieldValue(friend, node.field, op, node.value)
		end
	else
		result = false
	end

	if node.negate then
		return not result
	end
	return result
end

local function BuiltinQuickFilter_All()
	return true
end

local function BuiltinQuickFilter_Online(friend)
	return IsFriendOnline(friend)
end

local function BuiltinQuickFilter_Offline(friend)
	return not IsFriendOnline(friend)
end

local function BuiltinQuickFilter_WoW(friend)
	if friend and friend.type == "wow" then
		return true
	end
	local wowClient = BNET_CLIENT_WOW or "WoW"
	return HasOnlineGameAccount(friend, function(gameAccountInfo)
		return gameAccountInfo.clientProgram == wowClient
	end)
end

local function BuiltinQuickFilter_WoWOnline(friend)
	if friend and friend.type == "wow" then
		return IsFriendOnline(friend)
	end
	return BuiltinQuickFilter_WoW(friend)
end

local function BuiltinQuickFilter_BNet(friend)
	return friend and friend.type == "bnet"
end

local function BuiltinQuickFilter_HideAFK(friend)
	return not (IsAFK(friend) or IsDND(friend))
end

local function BuiltinQuickFilter_Retail(friend)
	if friend and friend.type == "wow" then
		return true
	end
	local wowClient = BNET_CLIENT_WOW or "WoW"
	return HasOnlineGameAccount(friend, function(gameAccountInfo)
		return gameAccountInfo.clientProgram == wowClient
			and (
				not gameAccountInfo.wowProjectID
				or not WOW_PROJECT_MAINLINE
				or gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE
			)
	end)
end

local function BuiltinQuickFilter_Forever(friend)
	if friend and friend.type == "wow" then
		return BFL.IsForever == true and IsFriendOnline(friend)
	end
	local wowClient = BNET_CLIENT_WOW or "WoW"
	-- Retail and Classic do not define Camelot's project constant, but can
	-- still receive Battle.net presence for its project ID.
	local foreverProjectID = WOW_PROJECT_CAMELOT or 18
	return HasOnlineGameAccount(friend, function(gameAccountInfo)
		return not IsSecretValue(gameAccountInfo.clientProgram)
			and not IsSecretValue(gameAccountInfo.wowProjectID)
			and gameAccountInfo.clientProgram == wowClient
			and gameAccountInfo.wowProjectID == foreverProjectID
	end)
end

function Registry:GetPlayerForeverRuleset()
	local compat = BFL.Compat
	if not BFL.IsForever or not (compat and compat.GetPlayerForeverSocialRuleset) then return nil end
	local friendsVersion = BFL.FriendsListVersion or 0
	if self.playerRulesetFriendsVersion ~= friendsVersion then
		self.playerRuleset = compat.GetPlayerForeverSocialRuleset()
		self.playerRulesetFriendsVersion = friendsVersion
	end
	return self.playerRuleset
end

function Registry:IsOtherForeverRuleset(friend, displayedAccount, playerRuleset, targetRuleset)
	if not BFL.IsForever or IsSecretValue(friend) or type(friend) ~= "table"
		or (issecrettable and issecrettable(friend))
		or IsSecretValue(friend.connected) or IsSecretValue(friend.type)
		or friend.type ~= "bnet" or friend.connected ~= true
		or IsSecretValue(displayedAccount) or type(displayedAccount) ~= "table"
		or (issecrettable and issecrettable(displayedAccount))
	then
		return false
	end

	local client, project, online = displayedAccount.clientProgram, displayedAccount.wowProjectID, displayedAccount.isOnline
	if IsSecretValue(client) or IsSecretValue(project) or IsSecretValue(online) or online == false then
		return false
	end
	if client == (BNET_CLIENT_WOW or "WoW") and project == (WOW_PROJECT_MAINLINE or 1) then
		return true
	end

	playerRuleset = playerRuleset or self:GetPlayerForeverRuleset()
	if not playerRuleset then return false end
	-- false means the caller already checked the account location.
	if targetRuleset == nil and BFL.GetWoWAccountLocation then
		targetRuleset = select(5, BFL.GetWoWAccountLocation(displayedAccount))
	end
	return targetRuleset and targetRuleset ~= playerRuleset or false
end

function BFL.FormatDimmedFriendText(text)
	local base = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", "")
	return "|cff808080" .. base .. "|r"
end

local function BuiltinQuickFilter_ForeverRuleset(friend)
	local ownRuleset = Registry:GetPlayerForeverRuleset()
	if not ownRuleset or not friend then return false end
	if friend.type == "wow" then return IsFriendOnline(friend) end
	return HasOnlineGameAccount(friend, function(account)
		return ownRuleset == select(5, BFL.GetWoWAccountLocation(account))
	end)
end

local function BuiltinQuickFilter_InGame(friend)
	if friend and friend.type == "wow" then
		return IsFriendOnline(friend)
	end
	return HasOnlineGameAccount(friend, function(gameAccountInfo)
		return IsPlayableClient(gameAccountInfo.clientProgram)
	end)
end

local BUILTIN_QUICK_FILTERS = {
	{
		id = "all",
		labelKey = "FILTER_ALL",
		descriptionKey = "FILTER_ALL_DESC",
		icon = BFL_ICON_PREFIX .. "filter-all",
		order = 10,
		evaluator = BuiltinQuickFilter_All,
	},
	{
		id = "online",
		labelKey = "FILTER_ONLINE",
		descriptionKey = "FILTER_ONLINE_DESC",
		icon = "friends-status-online",
		order = 20,
		evaluator = BuiltinQuickFilter_Online,
	},
	{
		id = "offline",
		labelKey = "FILTER_OFFLINE",
		descriptionKey = "FILTER_OFFLINE_DESC",
		icon = "friends-status-offline",
		order = 30,
		evaluator = BuiltinQuickFilter_Offline,
	},
	{
		id = "wowonline",
		labelKey = "FILTER_WOW_ONLINE",
		descriptionKey = "FILTER_WOW_ONLINE_DESC",
		icon = "logo-wow-retail",
		order = 40,
		evaluator = BuiltinQuickFilter_WoWOnline,
	},
	{
		id = "wow",
		labelKey = "FILTER_WOW",
		descriptionKey = "FILTER_WOW_DESC",
		icon = "logo-wow-retail",
		order = 50,
		evaluator = BuiltinQuickFilter_WoW,
	},
	{
		id = "bnet",
		labelKey = "FILTER_BNET",
		descriptionKey = "FILTER_BNET_DESC",
		icon = "friends-icon-addFriend-logo-battleNet",
		order = 60,
		evaluator = BuiltinQuickFilter_BNet,
	},
	{
		id = "hideafk",
		labelKey = "FILTER_HIDE_AFK",
		descriptionKey = "FILTER_HIDE_AFK_DESC",
		icon = BFL_ICON_PREFIX .. "filter-hide-afk",
		order = 70,
		evaluator = BuiltinQuickFilter_HideAFK,
	},
	{
		id = "retail",
		labelKey = "FILTER_RETAIL",
		descriptionKey = "FILTER_RETAIL_DESC",
		icon = "logo-wow-retail",
		order = 80,
		evaluator = BuiltinQuickFilter_Retail,
	},
	{
		id = "forever",
		labelKey = "FILTER_FOREVER",
		descriptionKey = "FILTER_FOREVER_DESC",
		icon = "logo-wow-forever",
		order = 85,
		evaluator = BuiltinQuickFilter_Forever,
	},
	{
		id = "foreverruleset",
		labelKey = "FILTER_FOREVER_RULESET",
		descriptionKey = "FILTER_FOREVER_RULESET_DESC",
		icon = "logo-wow-forever",
		order = 86,
		evaluator = BuiltinQuickFilter_ForeverRuleset,
		isSupported = function() return BFL.IsForever == true end,
	},
	{
		id = "ingame",
		labelKey = "FILTER_INGAME",
		descriptionKey = "FILTER_INGAME_DESC",
		icon = BFL_ICON_PREFIX .. "game",
		order = 90,
		evaluator = BuiltinQuickFilter_InGame,
	},
}

local BUILTIN_QUICK_FILTER_MAP = {}
for _, filter in ipairs(BUILTIN_QUICK_FILTERS) do
	BUILTIN_QUICK_FILTER_MAP[filter.id] = filter
end

local BUILTIN_SORTERS = {
	{ id = "status", labelKey = "SORT_STATUS", icon = BFL_ICON_PREFIX .. "status", order = 10, chain = { { field = "status", direction = "asc", empty = "last" } } },
	{ id = "name", labelKey = "SORT_NAME", icon = BFL_ICON_PREFIX .. "name", order = 20, chain = { { field = "name", direction = "asc", empty = "last" } } },
	{ id = "nickname", labelKey = "FILTER_BUILDER_FIELD_NICKNAME", icon = BFL_ICON_PREFIX .. "name", order = 25, chain = { { field = "nickname", direction = "asc", empty = "last" } } },
	{ id = "level", labelKey = "SORT_LEVEL", icon = BFL_ICON_PREFIX .. "level", order = 30, chain = { { field = "level", direction = "desc", empty = "last" } } },
	{ id = "zone", labelKey = "SORT_ZONE", icon = BFL_ICON_PREFIX .. "zone", order = 40, chain = { { field = "zone", direction = "asc", empty = "last" } } },
	{ id = "game", labelKey = "SORT_GAME", icon = BFL_ICON_PREFIX .. "game", order = 50, chain = { { field = "game", direction = "asc", empty = "last" } } },
	{ id = "faction", labelKey = "SORT_FACTION", icon = BFL_ICON_PREFIX .. "faction", order = 60, chain = { { field = "faction", direction = "asc", empty = "last" } } },
	{ id = "guild", labelKey = "SORT_GUILD", icon = BFL_ICON_PREFIX .. "guild", order = 70, chain = { { field = "guild", direction = "asc", empty = "last" } } },
	{ id = "class", labelKey = "SORT_CLASS", icon = BFL_ICON_PREFIX .. "class", order = 80, chain = { { field = "class", direction = "asc", empty = "last" } } },
	{ id = "realm", labelKey = "SORT_REALM", icon = BFL_ICON_PREFIX .. "realm", order = 90, chain = { { field = "realm", direction = "asc", empty = "last" } } },
	{ id = "ruleset", labelKey = "BROKER_COLUMN_RULESET", icon = BFL_ICON_PREFIX .. "realm", order = 90, chain = { { field = "ruleset", direction = "asc", empty = "last" } } },
}

local BUILTIN_SORTER_MAP = {}
for _, sorter in ipairs(BUILTIN_SORTERS) do
	BUILTIN_SORTER_MAP[sorter.id] = sorter
end

local function NormalizeIconRef(iconRef)
	if type(iconRef) == "number" then
		return iconRef
	end
	if type(iconRef) ~= "string" or iconRef == "" then
		return nil
	end
	if NATIVE_FILTER_ICONS[iconRef] then
		return iconRef
	end
	local normalized = iconRef:gsub("/", "\\")
	if normalized:match("^%d+$") then
		return tonumber(normalized)
	end
	if normalized:find(BFL_ICON_PREFIX, 1, true) == 1 then
		return normalized
	end
	if normalized:lower():find(BLIZZARD_ICON_PREFIX:lower(), 1, true) == 1 then
		return normalized
	end
	return nil
end

local function NormalizeCondition(node)
	if type(node) ~= "table" or node.type ~= "condition" then
		return nil
	end
	local fieldDef = FILTER_FIELD_MAP[node.field]
	if not fieldDef then
		return nil
	end
	local op = FILTER_OPERATORS[node.op] and node.op or (fieldDef.type == "string" and "contains" or "is")
	return {
		type = "condition",
		field = node.field,
		op = op,
		value = DeepCopy(node.value),
		negate = node.negate and true or false,
	}
end

local function NormalizeGroup(node, depth, stats)
	if type(node) ~= "table" then
		return { type = "group", op = "AND", children = {} }
	end
	depth = depth or 1
	stats = stats or { nodes = 0 }
	stats.nodes = stats.nodes + 1
	if depth > Registry.MAX_FILTER_DEPTH or stats.nodes > Registry.MAX_FILTER_NODES then
		return { type = "group", op = "AND", children = {} }
	end
	if node.type == "condition" then
		return NormalizeCondition(node) or { type = "group", op = "AND", children = {} }
	end

	local children = {}
	if type(node.children) == "table" then
		for _, child in ipairs(node.children) do
			if stats.nodes >= Registry.MAX_FILTER_NODES then
				break
			end
			local normalizedChild
			if type(child) == "table" and child.type == "condition" then
				normalizedChild = NormalizeCondition(child)
				stats.nodes = stats.nodes + 1
			else
				normalizedChild = NormalizeGroup(child, depth + 1, stats)
			end
			if normalizedChild then
				table.insert(children, normalizedChild)
			end
		end
	end

	return {
		type = "group",
		op = node.op == "OR" and "OR" or "AND",
		negate = node.negate and true or false,
		children = children,
	}
end

local function NormalizeSortStep(step)
	local field = type(step) == "table" and NormalizeLocationSortID(step.field)
	local fieldDef = SORT_FIELD_MAP[field]
	if not fieldDef then
		return nil
	end
	local direction = (step.direction == "asc" or step.direction == "desc") and step.direction
		or fieldDef.defaultDirection
		or "asc"
	local empty = step.empty == "first" and "first" or "last"
	return {
		field = field,
		direction = direction,
		empty = empty,
	}
end

local function NormalizeSorterChain(chain)
	local normalized = {}
	if type(chain) == "table" then
		for _, step in ipairs(chain) do
			if #normalized >= Registry.MAX_SORT_STEPS then
				break
			end
			local normalizedStep = NormalizeSortStep(step)
			if normalizedStep then
				table.insert(normalized, normalizedStep)
			end
		end
	end
	if #normalized == 0 then
		table.insert(normalized, { field = "name", direction = "asc", empty = "last" })
	end
	return normalized
end

function Registry:EnsureDB()
	if not BetterFriendlistDB then
		return nil
	end
	local settingsVersion = BFL.SettingsVersion or 0
	local cacheVersion = self.cacheVersion or 0
	if
		self.ensuredDB == BetterFriendlistDB
		and self.ensuredDBSettingsVersion == settingsVersion
		and self.ensuredDBCacheVersion == cacheVersion
	then
		return BetterFriendlistDB
	end

	BetterFriendlistDB.customQuickFilters = BetterFriendlistDB.customQuickFilters or {}
	BetterFriendlistDB.quickFilterVisibility = BetterFriendlistDB.quickFilterVisibility or {}
	BetterFriendlistDB.quickFilterOrder = BetterFriendlistDB.quickFilterOrder or {}
	BetterFriendlistDB.nextCustomQuickFilterId = BetterFriendlistDB.nextCustomQuickFilterId or 1
	BetterFriendlistDB.customSorters = BetterFriendlistDB.customSorters or {}
	BetterFriendlistDB.sorterVisibility = BetterFriendlistDB.sorterVisibility or {}
	BetterFriendlistDB.sorterOrder = BetterFriendlistDB.sorterOrder or {}
	BetterFriendlistDB.nextCustomSorterId = BetterFriendlistDB.nextCustomSorterId or 1
	self.ensuredDB = BetterFriendlistDB
	self.ensuredDBSettingsVersion = settingsVersion
	self.ensuredDBCacheVersion = cacheVersion
	return BetterFriendlistDB
end

function Registry:Initialize()
	self:NormalizeDB()
	self:NormalizeCurrentSelections()
	if BFL.IsForever and BFL.RegisterEventCallback then
		BFL:RegisterEventCallback("GAME_RULES_CHANGED", function()
			local previous = self.playerRuleset
			self.playerRulesetFriendsVersion = nil
			if previous ~= self:GetPlayerForeverRuleset() then
				self:InvalidateCaches()
				if BFL.ForceRefreshFriendsList and (not IsLoggedIn or IsLoggedIn()) then
					BFL:ForceRefreshFriendsList()
				end
				local broker = BFL:GetModule("Broker")
				if broker and broker.ScheduleObservedTooltipRefresh then broker:ScheduleObservedTooltipRefresh() end
			if BetterFriendlistDB and BetterFriendlistDB.quickFilter == "foreverruleset"
				and broker and broker.ScheduleBrokerTextUpdate then
				broker:ScheduleBrokerTextUpdate()
			end
			end
		end)
	end
end

function Registry:NormalizeDB()
	local db = self:EnsureDB()
	if not db then
		return
	end

	for id, filter in pairs(db.customQuickFilters) do
		if type(filter) ~= "table" then
			db.customQuickFilters[id] = nil
		else
			local icon = NormalizeIconRef(filter.icon)
			db.customQuickFilters[id] = {
				id = id,
				name = SafeString(filter.name ~= "" and filter.name or nil),
				icon = icon or BFL_ICON_PREFIX .. "filter-all",
				ast = NormalizeGroup(filter.ast),
			}
			if db.customQuickFilters[id].name == "" then
				db.customQuickFilters[id].name = GetLocale("FILTER_BUILDER_NEW_FILTER", "Custom Filter")
			end
		end
	end

	for id, sorter in pairs(db.customSorters) do
		if type(sorter) ~= "table" then
			db.customSorters[id] = nil
		else
			local icon = NormalizeIconRef(sorter.icon)
			db.customSorters[id] = {
				id = id,
				name = SafeString(sorter.name ~= "" and sorter.name or nil),
				icon = icon or BFL_ICON_PREFIX .. "sliders",
				chain = NormalizeSorterChain(sorter.chain),
			}
			if db.customSorters[id].name == "" then
				db.customSorters[id].name = GetLocale("FILTER_BUILDER_NEW_SORTER", "Custom Sorter")
			end
		end
	end

	if not IsArray(db.quickFilterOrder) then
		db.quickFilterOrder = {}
	end
	for _, id in ipairs({ "inqueue", "availableforqueue" }) do
		self:RemoveFromOrder(db.quickFilterOrder, id)
		db.quickFilterVisibility[id] = nil
	end
	if not IsArray(db.sorterOrder) then
		db.sorterOrder = {}
	end

	for _, filter in ipairs(BUILTIN_QUICK_FILTERS) do
		AddUnique(db.quickFilterOrder, filter.id)
	end
	for id in pairs(db.customQuickFilters) do
		AddUnique(db.quickFilterOrder, id)
	end
	for _, sorter in ipairs(BUILTIN_SORTERS) do
		AddUnique(db.sorterOrder, sorter.id)
	end
	for id in pairs(db.customSorters) do
		AddUnique(db.sorterOrder, id)
	end
	self:InvalidateCaches()
end

local function BuildDisplayEntry(entry, isCustom)
	return {
		id = entry.id,
		name = entry.name or GetLocale(entry.labelKey, entry.id),
		labelKey = entry.labelKey,
		description = entry.descriptionKey and GetLocale(entry.descriptionKey),
		icon = entry.icon,
		isCustom = isCustom and true or false,
		builtin = not isCustom,
		ast = entry.ast,
		chain = entry.chain and NormalizeSorterChain(entry.chain) or nil,
	}
end

function Registry:AreBuilderFeaturesEnabled()
	return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

local function IsBuiltinQuickFilter(id)
	return id and BUILTIN_QUICK_FILTER_MAP[id] ~= nil
end

local function IsQuickFilterSupported(entry)
	return entry ~= nil and (not entry.isSupported or entry.isSupported() == true)
end

local function IsBuiltinSorter(id)
	return id and BUILTIN_SORTER_MAP[id] ~= nil
end

local function ResolveSorterEntry(registry, id, requireVisible, fallbackId)
	if id == "none" then
		return nil
	end

	local db = registry:EnsureDB()
	id = NormalizeLocationSortID(id or fallbackId or registry.FALLBACK_PRIMARY_SORT)
	local entry = BUILTIN_SORTER_MAP[id]
	if not entry and db and db.customSorters then
		entry = db.customSorters[id]
	end
	if entry and (not requireVisible or registry:IsSorterVisible(id)) then
		return entry
	end
	return BUILTIN_SORTER_MAP[fallbackId or registry.FALLBACK_PRIMARY_SORT]
end

local function ResolveQuickFilterEntry(registry, id, requireVisible)
	local cache = GetRegistryCache(registry)
	local cacheKey = tostring(id or registry.FALLBACK_FILTER) .. "|" .. tostring(requireVisible and 1 or 0)
	local cached = cache.quickFilterEntries[cacheKey]
	if cached then
		return cached.entry, cached.isCustom
	end

	local db = registry:EnsureDB()
	id = id or registry.FALLBACK_FILTER
	local entry = BUILTIN_QUICK_FILTER_MAP[id]
	local isCustom = false
	if not entry and db and db.customQuickFilters then
		entry = db.customQuickFilters[id]
		isCustom = entry ~= nil
	end
	if not (IsQuickFilterSupported(entry) and (not requireVisible or registry:IsQuickFilterVisible(id))) then
		entry = BUILTIN_QUICK_FILTER_MAP[registry.FALLBACK_FILTER]
		isCustom = false
	end

	cached = { entry = entry, isCustom = isCustom }
	cache.quickFilterEntries[cacheKey] = cached
	return entry, isCustom
end

function Registry:ResolveQuickFilter(id, requireVisible)
	local entry, isCustom = ResolveQuickFilterEntry(self, id, requireVisible)
	return entry and BuildDisplayEntry(entry, isCustom) or nil
end

function Registry:ResolveSorter(id, requireVisible, fallbackId)
	local entry = ResolveSorterEntry(self, id, requireVisible, fallbackId)
	if not entry then
		return nil
	end
	return BuildDisplayEntry(entry, not BUILTIN_SORTER_MAP[entry.id])
end

function Registry:IsQuickFilterVisible(id)
	local builtin = id and BUILTIN_QUICK_FILTER_MAP[id]
	if builtin and not IsQuickFilterSupported(builtin) then
		return false
	end
	local db = self:EnsureDB()
	if not db or not id then
		return true
	end
	if not self:AreBuilderFeaturesEnabled() then
		return IsBuiltinQuickFilter(id)
	end
	if db.quickFilterVisibility[id] == nil then
		return true
	end
	return db.quickFilterVisibility[id] and true or false
end

function Registry:IsSorterVisible(id)
	if id ~= NormalizeLocationSortID(id) then return false end
	local db = self:EnsureDB()
	if not db or not id then
		return true
	end
	if not self:AreBuilderFeaturesEnabled() then
		return IsBuiltinSorter(id)
	end
	if db.sorterVisibility[id] == nil then
		return true
	end
	return db.sorterVisibility[id] and true or false
end

local function SortByOrder(a, b)
	local ao = a._order or 9999
	local bo = b._order or 9999
	if ao ~= bo then
		return ao < bo
	end
	return (a.name or a.id) < (b.name or b.id)
end

local function BuildOrderMap(orderList)
	local map = {}
	if type(orderList) == "table" then
		for index, id in ipairs(orderList) do
			map[id] = index
		end
	end
	return map
end

function Registry:GetQuickFilters(includeHidden)
	local db = self:EnsureDB()
	local useBuilderSettings = self:AreBuilderFeaturesEnabled()
	local orderMap = useBuilderSettings and BuildOrderMap(db and db.quickFilterOrder) or {}
	local list = {}

	for _, entry in ipairs(BUILTIN_QUICK_FILTERS) do
		if IsQuickFilterSupported(entry) and (includeHidden or self:IsQuickFilterVisible(entry.id)) then
			local display = BuildDisplayEntry(entry, false)
			display.visible = self:IsQuickFilterVisible(entry.id)
			display._order = orderMap[entry.id] or entry.order
			table.insert(list, display)
		end
	end

	if db and db.customQuickFilters then
		for id, entry in pairs(db.customQuickFilters) do
			if includeHidden or self:IsQuickFilterVisible(id) then
				local display = BuildDisplayEntry(entry, true)
				display.visible = self:IsQuickFilterVisible(id)
				display._order = orderMap[id] or 1000
				table.insert(list, display)
			end
		end
	end

	table.sort(list, SortByOrder)
	for _, entry in ipairs(list) do
		entry._order = nil
	end
	return list
end

function Registry:GetVisibleQuickFilters()
	return self:GetQuickFilters(false)
end

function Registry:GetSorters(includeHidden, primaryId, secondaryId)
	local db = self:EnsureDB()
	local useBuilderSettings = self:AreBuilderFeaturesEnabled()
	local orderMap = useBuilderSettings and BuildOrderMap(db and db.sorterOrder) or {}
	local list = {}

	for _, entry in ipairs(BUILTIN_SORTERS) do
		if entry.id ~= primaryId and entry.id ~= secondaryId and entry.id == NormalizeLocationSortID(entry.id)
			and (includeHidden or self:IsSorterVisible(entry.id)) then
			local display = BuildDisplayEntry(entry, false)
			display.visible = self:IsSorterVisible(entry.id)
			display._order = orderMap[entry.id] or entry.order
			table.insert(list, display)
		end
	end

	if db and db.customSorters then
		for id, entry in pairs(db.customSorters) do
			if id ~= primaryId and id ~= secondaryId and (includeHidden or self:IsSorterVisible(id)) then
				local display = BuildDisplayEntry(entry, true)
				display.visible = self:IsSorterVisible(id)
				display._order = orderMap[id] or 1000
				table.insert(list, display)
			end
		end
	end

	table.sort(list, SortByOrder)
	for _, entry in ipairs(list) do
		entry._order = nil
	end
	return list
end

function Registry:GetVisibleSorters(primaryId, secondaryId)
	return self:GetSorters(false, NormalizeLocationSortID(primaryId), NormalizeLocationSortID(secondaryId))
end

function Registry:SetQuickFilterVisibility(id, visible)
	local db = self:EnsureDB()
	if not db or not self:ResolveQuickFilter(id, false) then
		return
	end
	db.quickFilterVisibility[id] = visible and true or false
	self:InvalidateCaches()
	self:NormalizeCurrentSelections()
	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

function Registry:SetSorterVisibility(id, visible)
	local db = self:EnsureDB()
	if not db or not self:ResolveSorter(id, false, self.FALLBACK_PRIMARY_SORT) then
		return
	end
	db.sorterVisibility[id] = visible and true or false
	self:InvalidateCaches()
	self:NormalizeCurrentSelections()
	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

local function GetQuickFilterPlan(registry, id)
	local cache = GetRegistryCache(registry)
	local cacheKey = tostring(id or registry.FALLBACK_FILTER)
	local plan = cache.quickFilterPlans[cacheKey]
	if plan then
		return plan
	end

	local entry, isCustom = ResolveQuickFilterEntry(registry, id, true)
	if isCustom then
		plan = {
			isCustom = true,
			id = entry.id,
			ast = entry.ast,
		}
	else
		local evaluator = (entry and entry.evaluator) or BuiltinQuickFilter_All
		plan = {
			isCustom = false,
			evaluator = evaluator,
		}
	end
	cache.quickFilterPlans[cacheKey] = plan
	return plan
end

function Registry:EvaluateSettingsFilterAST(ast, friend)
	return EvaluateAST(ast, friend)
end

function Registry:EvaluateQuickFilter(id, friend)
	local cacheKey = tostring(id or self.FALLBACK_FILTER)
	if cacheKey == self.FALLBACK_FILTER then
		return true
	end
	if type(friend) == "table" and friend.settingsSample then
		local entry, custom = ResolveQuickFilterEntry(self, id, false)
		if custom then return EvaluateAST(entry.ast, friend) end
		local evaluator = (entry and entry.evaluator) or BuiltinQuickFilter_All
		return evaluator(friend)
	end

	local useFriendCache = type(friend) == "table"
	local plan = GetQuickFilterPlan(self, id)
	if useFriendCache then
		local cacheVersion = self.cacheVersion or 0
		local settingsVersion = BFL.SettingsVersion or 0
		local friendsVersion = BFL.FriendsListVersion or 0
		local tagsDefinitionVersion = 0
		local tagsAssignmentVersion = 0
		if plan.isCustom then
			local FriendTags = BFL:GetModule("FriendTags")
			tagsDefinitionVersion = FriendTags and FriendTags.GetDefinitionVersion and FriendTags:GetDefinitionVersion()
				or BFL.FriendTagsVersion
				or 0
			tagsAssignmentVersion = FriendTags and FriendTags.GetFriendAssignmentVersion and FriendTags:GetFriendAssignmentVersion(friend)
				or BFL.FriendTagsVersion
				or 0
		end
		local nicknameVersion = BFL.NicknameCacheVersion or 0
		local resultCache = friend._bflQuickFilterResults
		if
			friend._bflQuickFilterCacheVersion ~= cacheVersion
			or friend._bflQuickFilterSettingsVersion ~= settingsVersion
			or friend._bflQuickFilterFriendsVersion ~= friendsVersion
			or friend._bflQuickFilterTagsDefinitionVersion ~= tagsDefinitionVersion
			or friend._bflQuickFilterTagsAssignmentVersion ~= tagsAssignmentVersion
			or friend._bflQuickFilterNicknameVersion ~= nicknameVersion
		then
			resultCache = {}
			friend._bflQuickFilterResults = resultCache
			friend._bflQuickFilterCacheVersion = cacheVersion
			friend._bflQuickFilterSettingsVersion = settingsVersion
			friend._bflQuickFilterFriendsVersion = friendsVersion
			friend._bflQuickFilterTagsDefinitionVersion = tagsDefinitionVersion
			friend._bflQuickFilterTagsAssignmentVersion = tagsAssignmentVersion
			friend._bflQuickFilterNicknameVersion = nicknameVersion
		end
		local cached = resultCache[cacheKey]
		if cached ~= nil then
			return cached
		end

		local result
		if plan.isCustom then
			result = EvaluateAST(plan.ast, friend) and true or false
		else
			result = plan.evaluator(friend) and true or false
		end
		resultCache[cacheKey] = result
		return result
	end

	if plan.isCustom then
		return EvaluateAST(plan.ast, friend)
	end
	return plan.evaluator(friend)
end

local STRING_SORT_CACHE_FIELDS = {
	name = "_sort_name",
	displayName = "_sort_displayName",
	zone = "_sort_zoneName",
	guild = "_sort_guildName",
	class = "_sort_className",
	realm = "_sort_realmName",
}

local function GetLocationOrNicknameSortKey(friend, field, plan)
	local keys = plan[field]
	if not keys then
		keys = {}
		plan[field] = keys
	end
	if keys[friend] == nil then
		local value
		if not (BFL.StreamerMode and BFL.StreamerMode:IsActive()) then
			if field == "nickname" then
				value = GetNickname(friend)
			elseif BFL.GetWoWAccountLocation and not IsSecretValue(friend.gameAccountInfo) then
				local location, kind = BFL.GetWoWAccountLocation(friend.gameAccountInfo or friend, friend.realmName)
				if kind == "ruleset" then
					value = location
				end
			end
		end
		local text = SafeString(value)
		keys[friend] = (IntlCompat and IntlCompat.GetSortKey and IntlCompat.GetSortKey(text)) or NormalizeString(text)
	end
	return keys[friend]
end

local function GetSortValue(friend, field, plan)
	if field == "nickname" or field == "ruleset" then
		return GetLocationOrNicknameSortKey(friend, field, plan)
	elseif field == "status" then
		return friend._sort_status or GetStatusPriority(friend)
	elseif field == "game" then
		return friend._sort_game or GetGamePriority(friend)
	elseif field == "faction" then
		return friend._sort_faction or GetFactionPriority(friend)
	elseif STRING_SORT_CACHE_FIELDS[field] then
		return friend[STRING_SORT_CACHE_FIELDS[field]] or NormalizeString(GetFieldValue(friend, field))
	elseif field == "level" then
		return friend._sort_level or tonumber(GetFieldValue(friend, "level")) or nil
	elseif field == "favorite" then
		return friend.isFavorite and 1 or 0
	elseif field == "lastOnline" then
		return GetLastOnlineAgeDays(friend)
	elseif field == "recentlyAdded" then
		return GetRecentlyAddedAgeDays(friend)
	elseif field == "accountCount" then
		return tonumber(GetFieldValue(friend, "accountCount")) or 0
	elseif field == "type" then
		return NormalizeString(GetFieldValue(friend, field))
	end
	return GetFieldValue(friend, field)
end

local function CompareRawValues(aValue, bValue, fieldDef)
	if fieldDef and fieldDef.type == "number" then
		aValue = tonumber(aValue) or 0
		bValue = tonumber(bValue) or 0
	elseif fieldDef and fieldDef.type == "boolean" then
		aValue = aValue and 1 or 0
		bValue = bValue and 1 or 0
	else
		-- String sort values are prepared before table.sort. On 12.1.5 this is
		-- the binary C_Intl sort key; older clients retain normalized text.
		aValue = SafeString(aValue)
		bValue = SafeString(bValue)
	end
	if aValue == bValue then
		return nil
	end
	return aValue < bValue
end

local NIL_SORT_VALUE = {}

local function GetCachedSortValue(keys, friend, field, plan)
	local value = keys[friend]
	if value == nil then
		value = GetSortValue(friend, field, plan)
		keys[friend] = value == nil and NIL_SORT_VALUE or value
	elseif value == NIL_SORT_VALUE then
		return nil
	end
	return value
end

local function CompareSortStep(step, a, b, plan, cachedKeys)
	local field = NormalizeLocationSortID(step.field)
	local fieldDef = SORT_FIELD_MAP[field]
	if not fieldDef then
		return nil
	end

	local aValue, bValue
	if cachedKeys then
		local keys = cachedKeys[field]
		if not keys then
			keys = {}
			cachedKeys[field] = keys
		end
		aValue = GetCachedSortValue(keys, a, field, plan)
		bValue = GetCachedSortValue(keys, b, field, plan)
	else
		aValue = GetSortValue(a, field, plan)
		bValue = GetSortValue(b, field, plan)
	end
	local aEmpty = IsEmptyValue(aValue)
	local bEmpty = IsEmptyValue(bValue)
	if aEmpty ~= bEmpty then
		local emptyFirst = step.empty == "first"
		return aEmpty == emptyFirst
	end
	if aEmpty and bEmpty then
		return nil
	end

	local result = CompareRawValues(aValue, bValue, fieldDef)
	if result == nil then
		return nil
	end
	if step.direction == "desc" then
		return not result
	end
	return result
end

local function CompareChain(chain, a, b, plan, cachedKeys)
	if type(chain) ~= "table" then
		return nil
	end
	for _, step in ipairs(chain) do
		local result = CompareSortStep(step, a, b, plan, cachedKeys)
		if result ~= nil then
			return result
		end
	end
	return nil
end

local function ChainContainsField(chain, field)
	if type(chain) ~= "table" then
		return false
	end
	for _, step in ipairs(chain) do
		if step.field == field then
			return true
		end
	end
	return false
end

local NAME_FALLBACK_SORT_STEP = { field = "name", direction = "asc", empty = "last" }

function Registry:CreateSortPlan(primaryId, secondaryId, includeHidden, tertiaryId)
	local primary = ResolveSorterEntry(self, primaryId, not includeHidden, self.FALLBACK_PRIMARY_SORT)
	local secondary = ResolveSorterEntry(self, secondaryId, true, self.FALLBACK_SECONDARY_SORT)
	local tertiary
	if tertiaryId and tertiaryId ~= "none" then
		tertiary = ResolveSorterEntry(self, tertiaryId, true, "none")
		if tertiary == primary or tertiary == secondary then
			tertiary = nil
		end
	end
	return {
		primary = primary,
		secondary = secondary,
		tertiary = tertiary,
		tertiaryValues = tertiary and {} or nil,
		primaryContainsFavorite = primary and ChainContainsField(primary.chain, "favorite") or false,
	}
end

function Registry:CreateSettingsSortPlan(chain, secondaryID, tertiaryID)
	local plan = self:CreateSortPlan("none", secondaryID, false, tertiaryID)
	plan.primary = { chain = NormalizeSorterChain(chain) }
	plan.primaryContainsFavorite = ChainContainsField(plan.primary.chain, "favorite")
	return plan
end

function Registry:CompareFriendsWithSortPlan(a, b, plan)
	plan = plan or self:CreateSortPlan()
	local primary = plan.primary
	local secondary = plan.secondary
	local tertiary = plan.tertiary
	local result = primary and CompareChain(primary.chain, a, b, plan)
	if result ~= nil then
		return result
	end

	if not tertiary and primary and not plan.primaryContainsFavorite and a.isFavorite ~= b.isFavorite then
		return a.isFavorite and true or false
	end

	if secondary and secondary.id ~= (primary and primary.id) then
		result = CompareChain(secondary.chain, a, b, plan)
		if result ~= nil then
			return result
		end
	end

	if tertiary then
		result = CompareChain(tertiary.chain, a, b, plan, plan.tertiaryValues)
		if result ~= nil then
			return result
		end
		if primary and not plan.primaryContainsFavorite and a.isFavorite ~= b.isFavorite then
			return a.isFavorite and true or false
		end
	end
	if not IsFriendOnline(a) and not IsFriendOnline(b) then
		local aTime = a.lastOnlineTime or 0
		local bTime = b.lastOnlineTime or 0
		if aTime ~= bTime then
			return aTime > bTime
		end
	end

	result = CompareSortStep(NAME_FALLBACK_SORT_STEP, a, b, plan)
	if result ~= nil then
		return result
	end
	return (a.index or a.bnetAccountID or 0) < (b.index or b.bnetAccountID or 0)
end

function Registry:CompareFriends(a, b, primaryId, secondaryId, tertiaryId)
	return self:CompareFriendsWithSortPlan(a, b, self:CreateSortPlan(primaryId, secondaryId, false, tertiaryId))
end

function Registry:GetQuickFilterText(id)
	local entry = ResolveQuickFilterEntry(self, id, false)
	return entry and (entry.name or GetLocale(entry.labelKey, entry.id)) or GetLocale("FILTER_ALL", "All Friends")
end

function Registry:GetQuickFilterIcon(id)
	local entry = ResolveQuickFilterEntry(self, id, false)
	return entry and entry.icon or BFL_ICON_PREFIX .. "filter-all"
end

function Registry:GetSorterText(id)
	if id == "none" then
		return GetLocale("SORT_NONE", "None")
	end
	local entry = ResolveSorterEntry(self, id, false, self.FALLBACK_PRIMARY_SORT)
	return entry and (entry.name or GetLocale(entry.labelKey, entry.id)) or id
end

function Registry:GetSorterIcon(id)
	if id == "none" then
		return "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up"
	end
	local entry = ResolveSorterEntry(self, id, false, self.FALLBACK_PRIMARY_SORT)
	return entry and entry.icon or BFL_ICON_PREFIX .. "game"
end

function Registry:GetQuickFilterIcons()
	local icons = {}
	for _, entry in ipairs(self:GetQuickFilters(true)) do
		icons[entry.id] = entry.icon
	end
	return icons
end

function Registry:GetSortIcons()
	local icons = { none = "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" }
	for _, entry in ipairs(self:GetSorters(true)) do
		icons[entry.id] = entry.icon
	end
	return icons
end

function Registry:GetFilterFieldCatalog()
	return DeepCopy(FILTER_FIELDS)
end

function Registry:GetSortFieldCatalog()
	local fields = {}
	for _, field in ipairs(SORT_FIELDS) do
		if field.id == NormalizeLocationSortID(field.id) then
			fields[#fields + 1] = DeepCopy(field)
		end
	end
	return fields
end

function Registry:GetOperatorsForField(fieldId)
	local field = FILTER_FIELD_MAP[fieldId]
	if not field then
		return { "is" }
	end
	return DeepCopy(OPERATORS_BY_TYPE[field.type] or OPERATORS_BY_TYPE.string)
end

function Registry:NormalizeQuickFilterId(id)
	local entry = ResolveQuickFilterEntry(self, id, true)
	return entry and entry.id or self.FALLBACK_FILTER
end

function Registry:NormalizePrimarySorterId(id)
	local entry = self:ResolveSorter(id, true, self.FALLBACK_PRIMARY_SORT)
	return entry and entry.id or self.FALLBACK_PRIMARY_SORT
end

function Registry:NormalizeSecondarySorterId(id, primaryId)
	if id == "none" then
		return "none"
	end
	local entry = self:ResolveSorter(id, true, self.FALLBACK_SECONDARY_SORT)
	local resolved = entry and entry.id or self.FALLBACK_SECONDARY_SORT
	if resolved == primaryId then
		return "none"
	end
	return resolved
end

function Registry:NormalizeTertiarySorterId(id, primaryId, secondaryId)
	if type(id) ~= "string" or id == "none" then return "none" end
	local entry = ResolveSorterEntry(self, id, true, "none")
	return entry and entry.id ~= NormalizeLocationSortID(primaryId) and entry.id ~= NormalizeLocationSortID(secondaryId)
		and entry.id or "none"
end

function Registry:NormalizeCurrentSelections()
	local db = self:EnsureDB()
	if not db then
		return
	end
	local previousFilter = db.quickFilter
	db.quickFilter = self:NormalizeQuickFilterId(previousFilter)
	if db.quickFilter ~= previousFilter then
		local broker = BFL:GetModule("Broker")
		if broker and broker.ScheduleBrokerTextUpdate then broker:ScheduleBrokerTextUpdate() end
	end
	db.primarySort = self:NormalizePrimarySorterId(db.primarySort)
	db.secondarySort = self:NormalizeSecondarySorterId(db.secondarySort, db.primarySort)
	db.enableTertiarySort = db.enableTertiarySort == true
	db.tertiarySort = self:NormalizeTertiarySorterId(db.tertiarySort, db.primarySort, db.secondarySort)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		FriendsList.filterMode = db.quickFilter
		FriendsList.sortMode = db.primarySort
		FriendsList.secondarySort = db.secondarySort
	end
end

local function NewCustomFilterAST()
	return {
		type = "group",
		op = "AND",
		children = {
			{
				type = "condition",
				field = "online",
				op = "is",
				value = true,
			},
		},
	}
end

local function GetBuiltinFilterAST(id)
	if id == "all" then
		return { type = "group", op = "AND", children = {} }
	elseif id == "online" then
		return { type = "group", op = "AND", children = { { type = "condition", field = "online", op = "is", value = true } } }
	elseif id == "offline" then
		return { type = "group", op = "AND", children = { { type = "condition", field = "online", op = "is", value = false } } }
	elseif id == "bnet" then
		return { type = "group", op = "AND", children = { { type = "condition", field = "type", op = "is", value = "bnet" } } }
	elseif id == "wow" then
		return {
			type = "group",
			op = "OR",
			children = {
				{ type = "condition", field = "type", op = "is", value = "wow" },
				{ type = "condition", field = "client", op = "is", value = BNET_CLIENT_WOW or "WoW" },
			},
		}
	elseif id == "wowonline" then
		return {
			type = "group",
			op = "AND",
			children = {
				{ type = "condition", field = "online", op = "is", value = true },
				GetBuiltinFilterAST("wow"),
			},
		}
	elseif id == "hideafk" then
		return {
			type = "group",
			op = "AND",
			children = {
				{ type = "condition", field = "afk", op = "is", value = false },
				{ type = "condition", field = "dnd", op = "is", value = false },
			},
		}
	elseif id == "retail" then
		return {
			type = "group",
			op = "AND",
			children = {
				GetBuiltinFilterAST("wow"),
				{ type = "condition", field = "wowProject", op = "is", value = WOW_PROJECT_MAINLINE or WOW_PROJECT_ID or 1 },
			},
		}
	elseif id == "forever" then
		return {
			type = "group",
			op = "AND",
			children = {
				GetBuiltinFilterAST("wowonline"),
				{ type = "condition", field = "wowProject", op = "is", value = WOW_PROJECT_CAMELOT or 18 },
			},
		}
	elseif id == "ingame" then
		return {
			type = "group",
			op = "AND",
			children = {
				{ type = "condition", field = "online", op = "is", value = true },
				{ type = "condition", field = "client", op = "notin", value = { "", "App", "BSAp" } },
			},
		}
	end
	return NewCustomFilterAST()
end

local function GetFilterTemplateAST(template, db)
	if template and template.isCustom and db and db.customQuickFilters[template.id] then
		return DeepCopy(db.customQuickFilters[template.id].ast)
	end
	if template and BUILTIN_QUICK_FILTER_MAP[template.id] then
		return GetBuiltinFilterAST(template.id)
	end
	return NewCustomFilterAST()
end

function Registry:GetSettingsTemplateRules(kind, templateId)
	if kind == "sorter" then
		local template = templateId and self:ResolveSorter(templateId, false, self.FALLBACK_PRIMARY_SORT)
		return nil, NormalizeSorterChain(template and template.chain)
	end
	local template = templateId and self:ResolveQuickFilter(templateId, false)
	return NormalizeGroup(GetFilterTemplateAST(template, self:EnsureDB()))
end

function Registry:CreateCustomQuickFilter(templateId)
	local db = self:EnsureDB()
	if not db then
		return nil
	end
	local nextId = tonumber(db.nextCustomQuickFilterId) or 1
	local id = "custom_filter_" .. tostring(nextId)
	db.nextCustomQuickFilterId = nextId + 1

	local template = templateId and self:ResolveQuickFilter(templateId, false) or nil
	local name = GetLocale("FILTER_BUILDER_NEW_FILTER", "Custom Filter")
	local icon = BFL_ICON_PREFIX .. "filter-all"
	if template and template.isCustom and db.customQuickFilters[template.id] then
		name = template.name
		icon = template.icon
	elseif template and BUILTIN_QUICK_FILTER_MAP[template.id] then
		name = template.name .. " " .. GetLocale("FILTER_BUILDER_COPY_SUFFIX", "Copy")
		icon = template.icon
	end

	db.customQuickFilters[id] = {
		id = id,
		name = name,
		icon = icon,
		ast = NormalizeGroup(GetFilterTemplateAST(template, db)),
	}
	AddUnique(db.quickFilterOrder, id)
	self:InvalidateCaches()
	return id
end

function Registry:UpdateCustomQuickFilter(id, patch)
	local db = self:EnsureDB()
	if not db or not db.customQuickFilters[id] or type(patch) ~= "table" then
		return false
	end
	local filter = db.customQuickFilters[id]
	if patch.name ~= nil then
		filter.name = SafeString(patch.name)
		if filter.name == "" then
			filter.name = GetLocale("FILTER_BUILDER_NEW_FILTER", "Custom Filter")
		end
	end
	if patch.icon ~= nil then
		filter.icon = NormalizeIconRef(patch.icon) or filter.icon
	end
	if patch.ast ~= nil then
		filter.ast = NormalizeGroup(patch.ast)
	end
	self:InvalidateCaches()
	if patch.ast ~= nil and db.quickFilter == id then
		local broker = BFL:GetModule("Broker")
		if broker and broker.ScheduleBrokerTextUpdate then broker:ScheduleBrokerTextUpdate() end
		if broker and broker.ScheduleObservedTooltipRefresh then broker:ScheduleObservedTooltipRefresh() end
	end
	return true
end

function Registry:DeleteCustomQuickFilter(id)
	local db = self:EnsureDB()
	if not db or not db.customQuickFilters[id] then
		return false
	end
	db.customQuickFilters[id] = nil
	db.quickFilterVisibility[id] = nil
	self:RemoveFromOrder(db.quickFilterOrder, id)
	self:InvalidateCaches()
	self:NormalizeCurrentSelections()
	return true
end

function Registry:CreateCustomSorter(templateId)
	local db = self:EnsureDB()
	if not db then
		return nil
	end
	local nextId = tonumber(db.nextCustomSorterId) or 1
	local id = "custom_sorter_" .. tostring(nextId)
	db.nextCustomSorterId = nextId + 1

	local template = templateId and self:ResolveSorter(templateId, false, self.FALLBACK_PRIMARY_SORT) or nil
	db.customSorters[id] = {
		id = id,
		name = template and (template.name .. " " .. GetLocale("FILTER_BUILDER_COPY_SUFFIX", "Copy"))
			or GetLocale("FILTER_BUILDER_NEW_SORTER", "Custom Sorter"),
		icon = (template and template.icon) or BFL_ICON_PREFIX .. "sliders",
		chain = NormalizeSorterChain(template and template.chain or nil),
	}
	AddUnique(db.sorterOrder, id)
	self:InvalidateCaches()
	return id
end

function Registry:UpdateCustomSorter(id, patch)
	local db = self:EnsureDB()
	if not db or not db.customSorters[id] or type(patch) ~= "table" then
		return false
	end
	local sorter = db.customSorters[id]
	if patch.name ~= nil then
		sorter.name = SafeString(patch.name)
		if sorter.name == "" then
			sorter.name = GetLocale("FILTER_BUILDER_NEW_SORTER", "Custom Sorter")
		end
	end
	if patch.icon ~= nil then
		sorter.icon = NormalizeIconRef(patch.icon) or sorter.icon
	end
	if patch.chain ~= nil then
		sorter.chain = NormalizeSorterChain(patch.chain)
	end
	self:InvalidateCaches()
	return true
end

function Registry:DeleteCustomSorter(id)
	local db = self:EnsureDB()
	if not db or not db.customSorters[id] then
		return false
	end
	db.customSorters[id] = nil
	db.sorterVisibility[id] = nil
	self:RemoveFromOrder(db.sorterOrder, id)
	self:InvalidateCaches()
	self:NormalizeCurrentSelections()
	return true
end

function Registry:RemoveFromOrder(orderList, id)
	if type(orderList) ~= "table" then
		return
	end
	for index = #orderList, 1, -1 do
		if orderList[index] == id then
			table.remove(orderList, index)
		end
	end
end

local function MoveInOrder(orderList, id, delta)
	if type(orderList) ~= "table" then
		return false
	end
	local index
	for i, value in ipairs(orderList) do
		if value == id then
			index = i
			break
		end
	end
	if not index then
		return false
	end
	local target = index + delta
	if target < 1 or target > #orderList then
		return false
	end
	orderList[index], orderList[target] = orderList[target], orderList[index]
	return true
end

function Registry:MoveQuickFilter(id, delta)
	local db = self:EnsureDB()
	local moved = db and MoveInOrder(db.quickFilterOrder, id, delta) or false
	if moved then
		self:InvalidateCaches()
	end
	return moved
end

function Registry:MoveSorter(id, delta)
	local db = self:EnsureDB()
	local moved = db and MoveInOrder(db.sorterOrder, id, delta) or false
	if moved then
		self:InvalidateCaches()
	end
	return moved
end

function Registry:CountQuickFilterMatches(id)
	local FriendsList = BFL:GetModule("FriendsList")
	local list = FriendsList and FriendsList.friendsList
	if type(list) ~= "table" then
		return 0, 0
	end
	local matches = 0
	for _, friend in ipairs(list) do
		if self:EvaluateQuickFilter(id, friend) then
			matches = matches + 1
		end
	end
	return matches, #list
end

function Registry:FormatIcon(iconRef, size)
	size = size or 16
	iconRef = NormalizeIconRef(iconRef) or BFL_ICON_PREFIX .. "filter-all"
	local atlas = NATIVE_FILTER_ICONS[iconRef] and iconRef
	if not atlas and type(iconRef) == "string" and iconRef:find(BFL_ICON_PREFIX, 1, true) == 1 then
		local name = iconRef:sub(#BFL_ICON_PREFIX + 1):gsub("%.[^%.\\]+$", "")
		atlas = LEGACY_FILTER_ICON_ATLASES[name]
	end
	if atlas then
		local profile = NATIVE_FILTER_ICONS[atlas]
		if BFL.GetAtlasOrTextureMarkup and BFL.HasAtlas and BFL.HasAtlas(atlas) then
			local width, height = size, size
			if profile.preserveAspect then
				local info = BFL.Compat and BFL.Compat.GetAtlasInfo and BFL.Compat.GetAtlasInfo(atlas)
				local aspect = info and info.width and info.height and info.height > 0 and info.width / info.height or 1
				if profile.crop then aspect = aspect * (profile.crop[2] - profile.crop[1]) / (profile.crop[4] - profile.crop[3]) end
				width, height = size * (profile.scale or 1), size * (profile.scale or 1)
				if aspect > 1 then height = height / aspect elseif aspect > 0 then width = width * aspect end
				width, height = math.floor(width + .5), math.floor(height + .5)
			end
			return BFL.GetAtlasOrTextureMarkup(atlas, profile.texture, width, height, profile.crop)
		end
		if profile.fallbackAtlas and BFL.GetAtlasOrTextureMarkup and BFL.HasAtlas and BFL.HasAtlas(profile.fallbackAtlas) then
			return BFL.GetAtlasOrTextureMarkup(profile.fallbackAtlas, profile.texture, size, size)
		end
		-- Keep native brand and status colors, including when the active theme
		-- tints BFL-owned icons. Older clients use their installed textures.
		return string.format("|T%s:%d:%d:0:0|t", profile.texture, size, size)
	end
	local usesThemeAccent = (BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme())
		or (BFL.IsEllesmereUISkinActive and BFL:IsEllesmereUISkinActive())
	if type(iconRef) == "string"
		and iconRef:find(BFL_ICON_PREFIX, 1, true) == 1
		and usesThemeAccent
		and BFL.GetThemeAccentColor then
		local iconName = iconRef:sub(#BFL_ICON_PREFIX + 1):gsub("%.[^%.\\]+$", "")
		if THEME_NEUTRAL_ICON_NAMES[iconName] then
			-- Inline texture markup has no desaturation flag. Use a white RGB mask
			-- with the original asset's alpha before multiplying in the theme color;
			-- tinting the baked-gold BLP directly cannot produce a pure EUI accent.
			iconRef = THEME_ICON_PREFIX .. iconName .. ".tga"
		end
		local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0, 1)
		local function ToColorByte(value)
			value = math.max(0, math.min(1, tonumber(value) or 1))
			return math.floor((value * 255) + 0.5)
		end
		-- Texture markup accepts RGB tint bytes after its file/crop fields. Known
		-- BFL assets use neutral masks; Blizzard and user icons retain their colors.
		return string.format(
			"|T%s:%d:%d:0:0:32:32:0:32:0:32:%d:%d:%d|t",
			tostring(iconRef),
			size,
			size,
			ToColorByte(r),
			ToColorByte(g),
			ToColorByte(b)
		)
	end
	return string.format("|T%s:%d:%d:0:0|t", tostring(iconRef), size, size)
end

function Registry:NormalizeIcon(iconRef)
	return NormalizeIconRef(iconRef)
end

function BFL.FormatIcon(iconRef, size)
	return Registry:FormatIcon(iconRef, size)
end
