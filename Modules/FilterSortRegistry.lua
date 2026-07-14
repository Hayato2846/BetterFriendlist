-- Modules/FilterSortRegistry.lua
-- Central registry for built-in and custom QuickFilters / Sorters.

local ADDON_NAME, BFL = ...

local Registry = BFL:RegisterModule("FilterSortRegistry", {})
local L = BFL.L or {}

Registry.FALLBACK_FILTER = "all"
Registry.FALLBACK_PRIMARY_SORT = "game"
Registry.FALLBACK_SECONDARY_SORT = "status"
Registry.MAX_FILTER_DEPTH = 5
Registry.MAX_FILTER_NODES = 50
Registry.MAX_SORT_STEPS = 8

local BFL_ICON_PREFIX = "Interface\\AddOns\\BetterFriendlist\\Icons\\"
local BLIZZARD_ICON_PREFIX = "Interface\\Icons\\"

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

local function SafeString(value)
	if value == nil then
		return ""
	end
	if BFL.IsSecret and BFL:IsSecret(value) then
		return ""
	end
	local str = tostring(value)
	if str:sub(1, 2) == "|K" then
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
	local function AddAccount(gameAccountInfo)
		if type(gameAccountInfo) ~= "table" or seen[gameAccountInfo] then
			return
		end
		seen[gameAccountInfo] = true
		accounts[#accounts + 1] = gameAccountInfo
	end

	AddAccount(GetGameInfo(friend))
	if friend and type(friend.gameAccounts) == "table" then
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
	if friend.bnetAccountID then
		return "bnet_" .. tostring(friend.bnetAccountID)
	end
	if friend.name then
		return "wow_" .. tostring(friend.name)
	end
	return nil
end

local function GetNickname(friend)
	local DB = GetDB()
	local uid = GetFriendUID(friend)
	if DB and DB.GetNickname and uid then
		return DB:GetNickname(uid)
	end
	return nil
end

local function GetFriendGroups(friend)
	local uid = GetFriendUID(friend)
	if not uid or not BetterFriendlistDB or type(BetterFriendlistDB.friendGroups) ~= "table" then
		return nil
	end
	return BetterFriendlistDB.friendGroups[uid]
end

local function GetRecentlyAddedAgeDays(friend)
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
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetSearchText and FriendTags:GetSearchText(friend) or ""
	elseif field == "tagSource" then
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetTagSourceText and FriendTags:GetTagSourceText(friend) or ""
	elseif field == "tagCount" then
		local FriendTags = BFL:GetModule("FriendTags")
		return FriendTags and FriendTags.GetTagCount and FriendTags:GetTagCount(friend) or 0
	elseif field == "hasTag" then
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

local SORT_FIELDS = {
	{ id = "status", labelKey = "SORT_STATUS", type = "number", defaultDirection = "asc" },
	{ id = "name", labelKey = "SORT_NAME", type = "string", defaultDirection = "asc" },
	{ id = "displayName", labelKey = "SORT_NAME", type = "string", defaultDirection = "asc" },
	{ id = "favorite", labelKey = "FILTER_BUILDER_FIELD_FAVORITE", type = "boolean", defaultDirection = "desc" },
	{ id = "level", labelKey = "SORT_LEVEL", type = "number", defaultDirection = "desc" },
	{ id = "zone", labelKey = "SORT_ZONE", type = "string", defaultDirection = "asc" },
	{ id = "game", labelKey = "SORT_GAME", type = "number", defaultDirection = "asc" },
	{ id = "faction", labelKey = "SORT_FACTION", type = "number", defaultDirection = "asc" },
	{ id = "guild", labelKey = "SORT_GUILD", type = "string", defaultDirection = "asc" },
	{ id = "class", labelKey = "SORT_CLASS", type = "string", defaultDirection = "asc" },
	{ id = "realm", labelKey = "SORT_REALM", type = "string", defaultDirection = "asc" },
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
	if type(actual) == "boolean" or type(expected) == "boolean" then
		return (actual and true or false) == (expected == true or expected == "true" or expected == 1 or expected == "1")
	end
	return NormalizeString(actual) == NormalizeString(expected)
end

local function MatchesConditionValue(actual, op, expected)
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
		icon = BFL_ICON_PREFIX .. "filter-all",
		order = 10,
		evaluator = BuiltinQuickFilter_All,
	},
	{
		id = "online",
		labelKey = "FILTER_ONLINE",
		icon = BFL_ICON_PREFIX .. "filter-online",
		order = 20,
		evaluator = BuiltinQuickFilter_Online,
	},
	{
		id = "offline",
		labelKey = "FILTER_OFFLINE",
		icon = BFL_ICON_PREFIX .. "filter-offline",
		order = 30,
		evaluator = BuiltinQuickFilter_Offline,
	},
	{
		id = "wowonline",
		labelKey = "FILTER_WOW_ONLINE",
		icon = BFL_ICON_PREFIX .. "check-circle",
		order = 40,
		evaluator = BuiltinQuickFilter_WoWOnline,
	},
	{
		id = "wow",
		labelKey = "FILTER_WOW",
		icon = BFL_ICON_PREFIX .. "filter-wow",
		order = 50,
		evaluator = BuiltinQuickFilter_WoW,
	},
	{
		id = "bnet",
		labelKey = "FILTER_BNET",
		icon = BFL_ICON_PREFIX .. "filter-bnet",
		order = 60,
		evaluator = BuiltinQuickFilter_BNet,
	},
	{
		id = "hideafk",
		labelKey = "FILTER_HIDE_AFK",
		icon = BFL_ICON_PREFIX .. "filter-hide-afk",
		order = 70,
		evaluator = BuiltinQuickFilter_HideAFK,
	},
	{
		id = "retail",
		labelKey = "FILTER_RETAIL",
		icon = BFL_ICON_PREFIX .. "filter-retail",
		order = 80,
		evaluator = BuiltinQuickFilter_Retail,
	},
	{
		id = "ingame",
		labelKey = "FILTER_INGAME",
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
	{ id = "level", labelKey = "SORT_LEVEL", icon = BFL_ICON_PREFIX .. "level", order = 30, chain = { { field = "level", direction = "desc", empty = "last" } } },
	{ id = "zone", labelKey = "SORT_ZONE", icon = BFL_ICON_PREFIX .. "zone", order = 40, chain = { { field = "zone", direction = "asc", empty = "last" } } },
	{ id = "game", labelKey = "SORT_GAME", icon = BFL_ICON_PREFIX .. "game", order = 50, chain = { { field = "game", direction = "asc", empty = "last" } } },
	{ id = "faction", labelKey = "SORT_FACTION", icon = BFL_ICON_PREFIX .. "faction", order = 60, chain = { { field = "faction", direction = "asc", empty = "last" } } },
	{ id = "guild", labelKey = "SORT_GUILD", icon = BFL_ICON_PREFIX .. "guild", order = 70, chain = { { field = "guild", direction = "asc", empty = "last" } } },
	{ id = "class", labelKey = "SORT_CLASS", icon = BFL_ICON_PREFIX .. "class", order = 80, chain = { { field = "class", direction = "asc", empty = "last" } } },
	{ id = "realm", labelKey = "SORT_REALM", icon = BFL_ICON_PREFIX .. "realm", order = 90, chain = { { field = "realm", direction = "asc", empty = "last" } } },
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
	if type(step) ~= "table" or not SORT_FIELD_MAP[step.field] then
		return nil
	end
	local fieldDef = SORT_FIELD_MAP[step.field]
	local direction = (step.direction == "asc" or step.direction == "desc") and step.direction
		or fieldDef.defaultDirection
		or "asc"
	local empty = step.empty == "first" and "first" or "last"
	return {
		field = step.field,
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
		icon = entry.icon,
		isCustom = isCustom and true or false,
		builtin = not isCustom,
		ast = entry.ast,
		chain = entry.chain and DeepCopy(entry.chain) or nil,
	}
end

function Registry:AreBuilderFeaturesEnabled()
	return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

local function IsBuiltinQuickFilter(id)
	return id and BUILTIN_QUICK_FILTER_MAP[id] ~= nil
end

local function IsBuiltinSorter(id)
	return id and BUILTIN_SORTER_MAP[id] ~= nil
end

local function ResolveSorterEntry(registry, id, requireVisible, fallbackId)
	if id == "none" then
		return nil
	end

	local db = registry:EnsureDB()
	id = id or fallbackId or registry.FALLBACK_PRIMARY_SORT
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
	if not (entry and (not requireVisible or registry:IsQuickFilterVisible(id))) then
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
		if includeHidden or self:IsQuickFilterVisible(entry.id) then
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

function Registry:GetSorters(includeHidden)
	local db = self:EnsureDB()
	local useBuilderSettings = self:AreBuilderFeaturesEnabled()
	local orderMap = useBuilderSettings and BuildOrderMap(db and db.sorterOrder) or {}
	local list = {}

	for _, entry in ipairs(BUILTIN_SORTERS) do
		if includeHidden or self:IsSorterVisible(entry.id) then
			local display = BuildDisplayEntry(entry, false)
			display.visible = self:IsSorterVisible(entry.id)
			display._order = orderMap[entry.id] or entry.order
			table.insert(list, display)
		end
	end

	if db and db.customSorters then
		for id, entry in pairs(db.customSorters) do
			if includeHidden or self:IsSorterVisible(id) then
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

function Registry:GetVisibleSorters()
	return self:GetSorters(false)
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

function Registry:EvaluateQuickFilter(id, friend)
	local cacheKey = tostring(id or self.FALLBACK_FILTER)
	if cacheKey == self.FALLBACK_FILTER then
		return true
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

local function GetSortValue(friend, field)
	if field == "status" then
		return friend._sort_status or GetStatusPriority(friend)
	elseif field == "game" then
		return friend._sort_game or GetGamePriority(friend)
	elseif field == "faction" then
		return friend._sort_faction or GetFactionPriority(friend)
	elseif field == "name" then
		return friend._sort_name or NormalizeString(GetFieldValue(friend, "name"))
	elseif field == "displayName" then
		return NormalizeString(GetFieldValue(friend, "displayName"))
	elseif field == "zone" then
		return friend._sort_zoneName or NormalizeString(GetFieldValue(friend, "zone"))
	elseif field == "guild" then
		return friend._sort_guildName or NormalizeString(GetFieldValue(friend, "guild"))
	elseif field == "class" then
		return friend._sort_className or NormalizeString(GetFieldValue(friend, "class"))
	elseif field == "realm" then
		return friend._sort_realmName or NormalizeString(GetFieldValue(friend, "realm"))
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
		aValue = NormalizeString(aValue)
		bValue = NormalizeString(bValue)
	end
	if aValue == bValue then
		return nil
	end
	return aValue < bValue
end

local function CompareSortStep(step, a, b)
	local fieldDef = SORT_FIELD_MAP[step.field]
	if not fieldDef then
		return nil
	end

	local aValue = GetSortValue(a, step.field)
	local bValue = GetSortValue(b, step.field)
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

local function CompareChain(chain, a, b)
	if type(chain) ~= "table" then
		return nil
	end
	for _, step in ipairs(chain) do
		local result = CompareSortStep(step, a, b)
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

function Registry:CreateSortPlan(primaryId, secondaryId)
	local primary = ResolveSorterEntry(self, primaryId, true, self.FALLBACK_PRIMARY_SORT)
	local secondary = ResolveSorterEntry(self, secondaryId, true, self.FALLBACK_SECONDARY_SORT)
	return {
		primary = primary,
		secondary = secondary,
		primaryContainsFavorite = primary and ChainContainsField(primary.chain, "favorite") or false,
	}
end

function Registry:CompareFriendsWithSortPlan(a, b, plan)
	plan = plan or self:CreateSortPlan()
	local primary = plan.primary
	local secondary = plan.secondary
	local result = primary and CompareChain(primary.chain, a, b)
	if result ~= nil then
		return result
	end

	if primary and not plan.primaryContainsFavorite and a.isFavorite ~= b.isFavorite then
		return a.isFavorite and true or false
	end

	if secondary and secondary.id ~= (primary and primary.id) then
		result = CompareChain(secondary.chain, a, b)
		if result ~= nil then
			return result
		end
	end

	if not IsFriendOnline(a) and not IsFriendOnline(b) then
		local aTime = a.lastOnlineTime or 0
		local bTime = b.lastOnlineTime or 0
		if aTime ~= bTime then
			return aTime > bTime
		end
	end

	result = CompareSortStep(NAME_FALLBACK_SORT_STEP, a, b)
	if result ~= nil then
		return result
	end
	return (a.index or a.bnetAccountID or 0) < (b.index or b.bnetAccountID or 0)
end

function Registry:CompareFriends(a, b, primaryId, secondaryId)
	return self:CompareFriendsWithSortPlan(a, b, self:CreateSortPlan(primaryId, secondaryId))
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
	return DeepCopy(SORT_FIELDS)
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

function Registry:NormalizeCurrentSelections()
	local db = self:EnsureDB()
	if not db then
		return
	end
	db.quickFilter = self:NormalizeQuickFilterId(db.quickFilter)
	db.primarySort = self:NormalizePrimarySorterId(db.primarySort)
	db.secondarySort = self:NormalizeSecondarySorterId(db.secondarySort, db.primarySort)
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

function Registry:CreateCustomQuickFilter(templateId)
	local db = self:EnsureDB()
	if not db then
		return nil
	end
	local nextId = tonumber(db.nextCustomQuickFilterId) or 1
	local id = "custom_filter_" .. tostring(nextId)
	db.nextCustomQuickFilterId = nextId + 1

	local template = templateId and self:ResolveQuickFilter(templateId, false) or nil
	local ast = NewCustomFilterAST()
	local name = GetLocale("FILTER_BUILDER_NEW_FILTER", "Custom Filter")
	local icon = BFL_ICON_PREFIX .. "filter-all"
	if template and template.isCustom and db.customQuickFilters[template.id] then
		ast = DeepCopy(db.customQuickFilters[template.id].ast)
		name = template.name
		icon = template.icon
	elseif template and BUILTIN_QUICK_FILTER_MAP[template.id] then
		name = template.name .. " " .. GetLocale("FILTER_BUILDER_COPY_SUFFIX", "Copy")
		icon = template.icon
		ast = GetBuiltinFilterAST(template.id)
	end

	db.customQuickFilters[id] = {
		id = id,
		name = name,
		icon = icon,
		ast = NormalizeGroup(ast),
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
	return string.format("|T%s:%d:%d:0:0|t", tostring(iconRef), size, size)
end

function Registry:NormalizeIcon(iconRef)
	return NormalizeIconRef(iconRef)
end

function BFL.FormatIcon(iconRef, size)
	return Registry:FormatIcon(iconRef, size)
end
