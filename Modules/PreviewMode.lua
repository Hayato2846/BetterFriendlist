-- Modules/PreviewMode.lua
-- Unified Preview Mode System for Screenshots and Demonstrations
-- Version 1.0 - December 2025
--
-- Purpose: Enable comprehensive preview/demonstration mode for addon screenshots
-- This module coordinates mock systems (Friends, Groups, Raid, Guild, and Quick Join)
-- to display realistic test data for promotional screenshots.
--
-- Command: /bfl preview <profile>
--
-- IMPORTANT: This module is for DEVELOPMENT/MARKETING purposes only.
-- It does not modify any real data or game state.

local ADDON_NAME, BFL = ...

-- Register Module
local PreviewMode = BFL:RegisterModule("PreviewMode", {})

-- ============================================
-- CONSTANTS
-- ============================================

-- Preview mode state
PreviewMode.enabled = false
PreviewMode.mockFriendsRevision = 0
PreviewMode.activeProfile = nil
PreviewMode.activeComponents = {}
PreviewMode.activeSection = nil
PreviewMode.settingsRefreshGeneration = 0
PreviewMode.settingsRefreshPending = false
PreviewMode.pendingSettingKeys = {}
PreviewMode.refreshingSettingsPreview = false
PreviewMode.activationGeneration = 0
PreviewMode.activationInProgress = false
PreviewMode.activationTrace = nil
PreviewMode.activationRenderGate = false

-- Slash-command activations deliberately yield between every potentially
-- expensive phase. The chat marker therefore reaches the screen one frame
-- before the phase can hang the client.
local PREVIEW_ACTIVATION_STEP_DELAY = 0.15
local MOCK_FRIEND_APPLICATION_PHASES

local PREVIEW_PROFILES = {
	all = {
		section = "friends",
		components = {
			friends = true,
			groups = true,
			group_assignments = true,
			tags = true,
			broker = true,
			quick_join = true,
			raf = true,
			raid = true,
			requests = true,
			recent_allies = true,
			guild = true,
			battletag = true,
		},
	},
	friends = {
		section = "friends",
		components = { friends = true, groups = true, group_assignments = true, tags = true },
	},
	friends_plain = {
		section = "friends",
		components = { friends = true },
	},
	friends_tags = {
		section = "friends",
		components = { friends = true, tags = true },
	},
	friends_header_one = {
		section = "friends",
		components = { friends = true, groups = true },
		groupFixture = "one",
	},
	friends_group_headers = {
		section = "friends",
		components = { friends = true, groups = true },
		groupFixture = "ascii",
	},
	friends_headers_latin = {
		section = "friends",
		components = { friends = true, groups = true },
		groupFixture = "latin",
	},
	friends_headers_i18n = {
		section = "friends",
		components = { friends = true, groups = true },
		groupFixture = "international",
	},
	friends_groups = {
		section = "friends",
		components = { friends = true, groups = true, group_assignments = true },
	},
	recent_allies = {
		section = "recent_allies",
		components = { recent_allies = true },
	},
	quick_join = {
		section = "quick_join",
		components = { quick_join = true },
	},
	friend_requests = {
		section = "friend_requests",
		components = { requests = true },
	},
	recruit_a_friend = {
		section = "recruit_a_friend",
		components = { raf = true },
	},
	raid = {
		section = "raid",
		components = { raid = true },
	},
	guild = {
		section = "guild",
		components = { guild = true },
	},
	broker = {
		components = { broker = true },
	},
	battletag = {
		section = "friends",
		components = { battletag = true },
	},
}

local PREVIEW_PROFILE_ORDER = {
	"friends_plain",
	"friends_tags",
	"friends_header_one",
	"friends_group_headers",
	"friends_headers_latin",
	"friends_headers_i18n",
	"friends_groups",
	"friends",
	"recent_allies",
	"quick_join",
	"friend_requests",
	"recruit_a_friend",
	"raid",
	"guild",
	"broker",
	"battletag",
	"all",
}

local PREVIEW_PROFILE_ALIASES = {
	friend = "friends",
	friends_only = "friends_plain",
	friendsonly = "friends_plain",
	plain = "friends_plain",
	friend_tags = "friends_tags",
	friendstags = "friends_tags",
	tags = "friends_tags",
	friend_headers = "friends_group_headers",
	friends_headers = "friends_group_headers",
	friendsheaders = "friends_group_headers",
	headers = "friends_group_headers",
	header_one = "friends_header_one",
	headers_one = "friends_header_one",
	friends_headers_one = "friends_header_one",
	headers_latin = "friends_headers_latin",
	friends_header_latin = "friends_headers_latin",
	headers_i18n = "friends_headers_i18n",
	friends_header_i18n = "friends_headers_i18n",
	friend_groups = "friends_groups",
	friendsgroups = "friends_groups",
	groups = "friends_groups",
	recent = "recent_allies",
	recentallies = "recent_allies",
	qj = "quick_join",
	quickjoin = "quick_join",
	tooltip = "quick_join",
	tooltips = "quick_join",
	request = "friend_requests",
	requests = "friend_requests",
	invites = "friend_requests",
	raf = "recruit_a_friend",
	recruit = "recruit_a_friend",
	recruitafriend = "recruit_a_friend",
	tag = "battletag",
}

local function CopyComponentSet(source)
	local copy = {}
	for component, enabled in pairs(source or {}) do
		if enabled then
			copy[component] = true
		end
	end
	return copy
end

function PreviewMode:GetProfileDefinition(profileID)
	profileID = (profileID or ""):lower():gsub("-", "_")
	profileID = PREVIEW_PROFILE_ALIASES[profileID] or profileID
	return profileID, PREVIEW_PROFILES[profileID]
end

function PreviewMode:GetProfileIDs()
	return PREVIEW_PROFILE_ORDER
end

function PreviewMode:IsComponentEnabled(component)
	if not self.enabled then
		return false
	end
	-- Older test/scenario callers set enabled directly. Preserve their previous
	-- combined-preview behavior unless an isolation profile was selected.
	if not self.activeProfile then
		return true
	end
	return self.activeComponents and self.activeComponents[component] == true
end

function BFL:IsRAFPreviewActive()
	return PreviewMode:IsComponentEnabled("raf")
end

local function PreviewMessage(message)
	message = tostring(message or "")
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	elseif BFL.DebugPrint then
		BFL:DebugPrint(message)
	end
end

local function CopyArray(source)
	if not source then
		return nil
	end
	local copy = {}
	for i, value in ipairs(source) do
		copy[i] = value
	end
	return copy
end

local function CopyFriendGroups(source)
	if not source then
		return nil
	end
	local copy = {}
	for uid, groups in pairs(source) do
		if type(groups) == "table" then
			local groupsCopy = {}
			for i, value in ipairs(groups) do
				groupsCopy[i] = value
			end
			copy[uid] = groupsCopy
		else
			copy[uid] = groups
		end
	end
	return copy
end

-- Mock player names for realistic screenshots (famous/lore characters + typical names)
local MOCK_NAMES = {
	-- Alliance Lore Characters
	"Anduin",
	"Jaina",
	"Genn",
	"Alleria",
	"Turalyon",
	"Velen",
	"Tyrande",
	"Malfurion",
	"Muradin",
	"Aysa",
	"Tess",
	"Shaw",
	"Magni",
	"Khadgar",
	"Valeera",
	-- Horde Lore Characters
	"Thrall",
	"Baine",
	"Lor'themar",
	"Thalyssra",
	"Gazlowe",
	"Rokhan",
	"Geya'rah",
	"Calia",
	"Eitrigg",
	"Rexxar",
	"Zekhan",
	"Lilian",
	-- Neutral/Dragon Aspects
	"Chromie",
	"Wrathion",
	"Alexstrasza",
	"Ysera",
	"Nozdormu",
	"Kalecgos",
	"Ebonhorn",
	-- Typical Player Names
	"Shadowblade",
	"Lightforge",
	"Stormwind",
	"Ironhammer",
	"Darkflame",
	"Frostweaver",
	"Sunfire",
	"Moonshade",
	"Earthshaker",
	"Windwalker",
	"Bloodfang",
	"Steelclaw",
	"Nightwhisper",
	"Dawnbringer",
	"Fireheart",
	"Icefury",
	"Thunderstrike",
	"Soulkeeper",
	"Starseeker",
	"Voidwalker",
	"Felguard",
	"Spiritbinder",
	"Stormrage",
	"Proudmoore",
	"VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
}

-- Battle Tags for mock BNet friends
local MOCK_BATTLETAGS = {
	"Anduin#1234",
	"Jaina#5678",
	"Thrall#9012",
	"Sylvanas#3456",
	"Bolvar#7890",
	"Illidan#2345",
	"Tyrande#6789",
	"Malfurion#0123",
	"Arthas#4567",
	"Uther#8901",
	"Gul'dan#2345",
	"Khadgar#6789",
	"Medivh#0123",
	"Velen#4567",
	"Alleria#8901",
	"Turalyon#2345",
}

-- Class data (matches WoW class structure)
local MOCK_CLASSES = {
	{ name = "Warrior", file = "WARRIOR", classID = 1 },
	{ name = "Paladin", file = "PALADIN", classID = 2 },
	{ name = "Hunter", file = "HUNTER", classID = 3 },
	{ name = "Rogue", file = "ROGUE", classID = 4 },
	{ name = "Priest", file = "PRIEST", classID = 5 },
	{ name = "Death Knight", file = "DEATHKNIGHT", classID = 6 },
	{ name = "Shaman", file = "SHAMAN", classID = 7 },
	{ name = "Mage", file = "MAGE", classID = 8 },
	{ name = "Warlock", file = "WARLOCK", classID = 9 },
	{ name = "Monk", file = "MONK", classID = 10 },
	{ name = "Druid", file = "DRUID", classID = 11 },
	{ name = "Demon Hunter", file = "DEMONHUNTER", classID = 12 },
	{ name = "Evoker", file = "EVOKER", classID = 13 },
}

-- Zones for variety
local MOCK_ZONES = {
	-- The War Within zones
	"Dornogal",
	"The Ringing Deeps",
	"Hallowfall",
	"Azj-Kahet",
	"Isle of Dorn",
	"City of Threads",
	"Priory of the Sacred Flame",
	"Cinderbrew Meadery",
	-- Classic/Popular zones
	"Stormwind City",
	"Orgrimmar",
	"Dalaran",
	"Valdrakken",
	"Oribos",
	"Boralus",
	"Zuldazar",
	"Mechagon",
	"Nazjatar",
}

-- Game clients for variety
local MOCK_GAMES = {
	{ program = "WoW", name = "World of Warcraft" },
	{ program = "WoW", name = "World of Warcraft" }, -- More WoW players
	{ program = "WoW", name = "World of Warcraft" }, -- More WoW players
	{ program = "ANBS", name = "Diablo IV", richPresence = "Greater Rift" },
	{ program = "WTCG", name = "Hearthstone", richPresence = "Ranked: In Game" },
	{ program = "Pro", name = "Overwatch 2", richPresence = "Competitive: In Game" },
	{ program = "App", name = "Battle.net App" },
}

-- Real 12.1 Battle.net rows receive valid title IDs from Blizzard and continue
-- through the native title API. Preview rows are synthetic and therefore need deterministic
-- local copies of the same modern title art instead of requesting invalid IDs.
local MOCK_TITLE_ICON_TEXTURES = {
	App = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-battlenet",
	BSAp = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-battlenet",
	WoW = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-wow",
	ANBS = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-diablo",
	WTCG = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-hearthstone",
	Pro = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-overwatch",
	S2 = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-starcraft",
}

local function GetMockTitleIconTexture(clientProgram)
	return MOCK_TITLE_ICON_TEXTURES[clientProgram] or MOCK_TITLE_ICON_TEXTURES.App
end

-- ============================================
-- MOCK FRIEND DATA GENERATION
-- ============================================

-- Generate mock Battle.net friend data
local function GenerateMockBNetFriend(index, isOnline, options)
	options = options or {}

	local classInfo = MOCK_CLASSES[math.random(#MOCK_CLASSES)]
	local zone = options.zone or MOCK_ZONES[math.random(#MOCK_ZONES)]
	local game = options.game or MOCK_GAMES[math.random(#MOCK_GAMES)]
	local level = options.level or (isOnline and math.random(70, 80) or math.random(1, 80))
	local battleTag = options.battleTag or MOCK_BATTLETAGS[(index % #MOCK_BATTLETAGS) + 1]
	local accountName = options.accountName or battleTag:match("([^#]+)")
	local characterName = options.characterName or MOCK_NAMES[(index % #MOCK_NAMES) + 1]
	local faction = options.faction or (math.random(2) == 1 and "Alliance" or "Horde")
	local friendLevel = options.friendLevel or ((index % 3) + 1)
	local friendTags = options.friendTags or { index % 10, (index + 3) % 10 }
	local previewTitleIcon = isOnline and GetMockTitleIconTexture(game.program) or nil

	-- Determine status (DND, AFK, normal)
	local isDND = options.isDND or (isOnline and math.random(10) == 1)
	local isAFK = options.isAFK or (isOnline and not isDND and math.random(8) == 1)
	local isWoW = isOnline and game.program == "WoW"
	local richPresence = ""
	if isOnline then
		richPresence = game.richPresence or (isWoW and string.format("%s - Blackrock", zone)) or game.name or ""
	end
	local gameAccountID = 1000 + index

	return {
		type = "bnet",
		index = index,
		bnetAccountID = 1000000 + index,
		accountName = accountName,
		battleTag = battleTag,
		connected = isOnline,
		note = options.note or (math.random(3) == 1 and "Real friend from raids" or nil),
		isFavorite = options.isFavorite or (index <= 3),
		friendLevel = friendLevel,
		friendTags = friendTags,
		lastOnlineTime = not isOnline and (time() - math.random(86400, 604800)) or nil,
		clientProgram = isOnline and game.program or "",
		client = isOnline and game.program or "",
		_previewTitleIcon = previewTitleIcon,
		gameAccountID = isOnline and gameAccountID or nil,
		wowProjectID = isWoW and 1 or 0,
		-- Game account info (always present to prevent errors in FriendsFrame_GetBNetAccountNameAndStatus)
		gameAccountInfo = {
			isOnline = isOnline,
			gameAccountID = gameAccountID, -- Ensure valid ID
			clientProgram = isOnline and game.program or "",
			_previewTitleIcon = previewTitleIcon,
			gameName = isOnline and game.name or "",
			characterName = isWoW and characterName or "",
			className = isWoW and classInfo.name or "",
			classID = isWoW and classInfo.classID or 0,
			classFilename = isWoW and classInfo.file or "",
			characterLevel = isWoW and level or "",
			areaName = isWoW and zone or "",
			richPresence = richPresence,
			realmName = isWoW and "Blackrock" or "",
			factionName = isWoW and faction or "",
			isDND = isDND,
			isAFK = isAFK,
			wowProjectID = isWoW and 1 or 0,
		},
		gameAccounts = isOnline and not options.mobileOnly and {
			{
				gameAccountID = gameAccountID,
				clientProgram = game.program,
				_previewTitleIcon = previewTitleIcon,
				isOnline = true,
				richPresence = richPresence,
				characterName = isWoW and characterName or "",
				className = isWoW and classInfo.name or "",
				classID = isWoW and classInfo.classID or 0,
				classFilename = isWoW and classInfo.file or "",
				characterLevel = isWoW and level or "",
				areaName = isWoW and zone or "",
				realmName = isWoW and "Blackrock" or "",
				factionName = isWoW and faction or "",
				wowProjectID = isWoW and 1 or 0,
			},
		} or {},
		numGameAccounts = isOnline and not options.mobileOnly and 1 or 0,
		-- Additional fields for display
		characterName = isWoW and characterName or nil,
		className = isWoW and classInfo.name or nil,
		classID = isWoW and classInfo.classID or nil,
		classFilename = isWoW and classInfo.file or nil,
		level = isWoW and level or nil,
		areaName = isWoW and zone or nil,
		realmName = isWoW and "Blackrock" or nil,
		factionName = isWoW and faction or nil,
		gameName = isOnline and not isWoW and richPresence or nil,
		-- Mock marker
		_isMock = true,
		_previewBaseConnected = isOnline,
		_previewMobileOnly = options.mobileOnly == true,
	}
end

-- Generate mock WoW-only friend data
local function GenerateMockWoWFriend(index, isOnline, options)
	options = options or {}

	local classInfo = MOCK_CLASSES[math.random(#MOCK_CLASSES)]
	local zone = MOCK_ZONES[math.random(#MOCK_ZONES)]
	local level = options.level or math.random(70, 80)
	local name = options.name or MOCK_NAMES[(index % #MOCK_NAMES) + 1]
	local faction = options.faction or (math.random(2) == 1 and "Alliance" or "Horde")

	return {
		type = "wow",
		index = index,
		name = name .. "-Blackrock",
		connected = isOnline,
		level = isOnline and level or nil,
		className = classInfo.name,
		area = isOnline and zone or nil,
		factionName = faction,
		notes = options.notes or (math.random(4) == 1 and "Met in dungeon" or nil),
		-- Mock marker
		_isMock = true,
		_previewBaseConnected = isOnline,
	}
end

-- ============================================
-- MOCK GROUPS GENERATION
-- ============================================

-- Generate mock friend groups with friends assigned
local function GenerateMockGroups(fixtureID)
	local groups = {
		-- Built-in Groups
		{
			id = "favorites",
			name = "Favorites",
			collapsed = false,
			builtin = true,
			order = 1,
			color = { r = 1.0, g = 0.82, b = 0.0 }, -- Gold
			icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon",
		},
		-- Custom groups (will be shown)
		{
			id = "raid_team",
			name = "Raid Team",
			collapsed = false,
			builtin = false,
			order = 2,
			color = { r = 1.0, g = 0.4, b = 0.4 }, -- Red
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "mythic_plus",
			name = "Mythic+",
			collapsed = false,
			builtin = false,
			order = 3,
			color = { r = 0.4, g = 0.8, b = 1.0 }, -- Light blue
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "pvp_friends",
			name = "PvP Friends",
			collapsed = false,
			builtin = false,
			order = 4,
			color = { r = 1.0, g = 0.6, b = 0.0 }, -- Orange
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "irl_friends",
			name = "IRL Friends",
			collapsed = false,
			builtin = false,
			order = 5,
			color = { r = 0.6, g = 1.0, b = 0.6 }, -- Light green
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "trading",
			name = "Trading Partners",
			collapsed = true, -- Show collapsed for variety
			builtin = false,
			order = 6,
			color = { r = 1.0, g = 0.84, b = 0.0 }, -- Gold
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		-- International Test Groups (Non-Roman)
		{
			id = "group_korea",
			name = "테스트 그룹 (KR)",
			collapsed = false,
			builtin = false,
			order = 7,
			color = { r = 0.4, g = 1.0, b = 0.4 }, -- Mint
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "group_china",
			name = "测试组 (CN)",
			collapsed = false,
			builtin = false,
			order = 8,
			color = { r = 1.0, g = 0.4, b = 0.4 }, -- Redish
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "group_russia",
			name = "Тестовая группа (RU)",
			collapsed = false,
			builtin = false,
			order = 9,
			color = { r = 0.4, g = 0.4, b = 1.0 }, -- Blueish
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		-- Font preview groups for WoW's non-latin font families.
		{
			id = "font_korean",
			name = "테스트 그룹 (Korean)",
			collapsed = false,
			builtin = false,
			order = 10,
			color = { r = 0.35, g = 0.9, b = 0.7 },
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "font_simplified_chinese",
			name = "测试组 (Simplified Chinese)",
			collapsed = false,
			builtin = false,
			order = 11,
			color = { r = 0.95, g = 0.35, b = 0.35 },
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "font_traditional_chinese",
			name = "測試群組 (Traditional Chinese)",
			collapsed = false,
			builtin = false,
			order = 12,
			color = { r = 1.0, g = 0.65, b = 0.25 },
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "font_russian",
			name = "Тестовая группа (Russian)",
			collapsed = false,
			builtin = false,
			order = 13,
			color = { r = 0.45, g = 0.55, b = 1.0 },
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
		{
			id = "nogroup",
			name = "No Group",
			collapsed = false,
			builtin = true,
			order = 999,
			color = { r = 0.5, g = 0.5, b = 0.5 }, -- Gray
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		},
	}

	if fixtureID == "one" then
		local included = {
			favorites = true,
			raid_team = true,
			nogroup = true,
		}
		local filtered = {}
		for _, group in ipairs(groups) do
			if included[group.id] then
				filtered[#filtered + 1] = group
			end
		end
		return filtered
	end

	if fixtureID == "ascii" then
		local asciiNames = {
			group_korea = "Korean Test Group",
			group_china = "Chinese Test Group",
			group_russia = "Russian Test Group",
			font_korean = "Korean Font Preview",
			font_simplified_chinese = "Simplified Chinese Font Preview",
			font_traditional_chinese = "Traditional Chinese Font Preview",
			font_russian = "Russian Font Preview",
		}
		for _, group in ipairs(groups) do
			group.name = asciiNames[group.id] or group.name
		end
	elseif fixtureID == "latin" then
		local latinNames = {
			group_korea = "Grüße & Freunde",
			group_china = "Équipe héroïque",
			group_russia = "Compañeros",
			font_korean = "Crème brûlée",
			font_simplified_chinese = "São Paulo",
			font_traditional_chinese = "Dvořákův tým",
			font_russian = "Café kombiniert",
		}
		for _, group in ipairs(groups) do
			group.name = latinNames[group.id] or group.name
		end
	end

	-- The complete Friends fixture also carries the two opt-in dynamic groups.
	-- Diagnostic header fixtures intentionally keep their historical shape so
	-- they remain useful for crash bisection and font fallback verification.
	if fixtureID == nil then
		groups[#groups + 1] = {
			id = "ingame",
			name = "In-Game",
			collapsed = false,
			builtin = true,
			order = 1.1,
			color = { r = 1.0, g = 0.82, b = 0.0 },
			icon = "Interface\\Icons\\Inv_misc_groupneedmore",
		}
		groups[#groups + 1] = {
			id = "recentlyadded",
			name = "Recently Added",
			collapsed = false,
			builtin = true,
			order = 1.2,
			color = { r = 1.0, g = 0.82, b = 0.0 },
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
		}
	end

	return groups
end

-- Group assignments for mock friends (by battleTag - must match MOCK_BATTLETAGS exactly!)
-- IMPORTANT: Database stores group assignments as ARRAYS, e.g., {groupId1, groupId2}
-- The UID format is: "bnet_" .. battleTag for BNet friends
-- MOCK_BATTLETAGS order: Anduin#1234, Jaina#5678, Thrall#9012, Sylvanas#3456,
--                        Bolvar#7890, Illidan#2345, Tyrande#6789, Malfurion#0123,
--                        Arthas#4567, Uther#8901, Gul'dan#2345, Khadgar#6789,
--                        Medivh#0123, Velen#4567, Alleria#8901, Turalyon#2345
local MOCK_GROUP_ASSIGNMENTS = {
	-- Online BNet Friends (indices 1-8 in MOCK_BATTLETAGS)
	-- Index 1-3: Favorites (isFavorite=true, handled by BNet API mock)
	["bnet_Anduin#1234"] = { "raid_team" }, -- Index 1: Also in Raid Team
	["bnet_Jaina#5678"] = { "mythic_plus" }, -- Index 2: Also in Mythic+
	["bnet_Thrall#9012"] = { "pvp_friends" }, -- Index 3: Also in PvP Friends
	["bnet_Sylvanas#3456"] = { "raid_team" }, -- Index 4: Raid Team (Diablo IV player)
	["bnet_Bolvar#7890"] = { "raid_team" }, -- Index 5: Raid Team (Hearthstone player)
	["bnet_Illidan#2345"] = { "mythic_plus" }, -- Index 6: Mythic+ (DND status)
	["bnet_Tyrande#6789"] = { "mythic_plus" }, -- Index 7: Mythic+ (AFK status)
	["bnet_Malfurion#0123"] = { "irl_friends" }, -- Index 8: IRL Friends

	-- Offline BNet Friends (indices 9-16, wrapping around MOCK_BATTLETAGS)
	["bnet_Arthas#4567"] = { "raid_team" }, -- Offline: Raid Team
	["bnet_Uther#8901"] = { "mythic_plus" }, -- Offline: Mythic+
	["bnet_Gul'dan#2345"] = { "pvp_friends" }, -- Offline: PvP Friends
	["bnet_Khadgar#6789"] = { "pvp_friends" }, -- Offline: PvP Friends
	["bnet_Medivh#0123"] = { "irl_friends" }, -- Offline: IRL Friends
	["bnet_Velen#4567"] = { "irl_friends" }, -- Offline: IRL Friends
	["bnet_Alleria#8901"] = { "trading" }, -- Offline: Trading
	["bnet_Turalyon#2345"] = { "trading" }, -- Offline: Trading
}

-- WoW friend group assignments (by character name)
-- The UID format is: "wow_" .. characterName .. "-" .. realm
local MOCK_WOW_GROUP_ASSIGNMENTS = {
	-- Online WoW friends (names from MOCK_NAMES[21-24])
	["wow_Nightwhisper-Blackrock"] = { "mythic_plus" },
	["wow_Dawnbringer-Blackrock"] = { "raid_team" },
	["wow_Fireheart-Blackrock"] = { "pvp_friends" },
	["wow_Icefury-Blackrock"] = { "pvp_friends" },
	-- Offline WoW friends (names from MOCK_NAMES[25-28])
	["wow_Thunderstrike-Blackrock"] = { "trading" },
	["wow_Soulkeeper-Blackrock"] = { "irl_friends" },
	["wow_Starseeker-Blackrock"] = { "raid_team" },
	["wow_Voidwalker-Blackrock"] = { "mythic_plus" },
}

-- ============================================
-- PREVIEW MODE STATE MANAGEMENT
-- ============================================

-- Stored real data (to restore when exiting preview)
PreviewMode.savedState = {
	friendsList = nil,
	groups = nil,
}

-- Mock data storage
PreviewMode.mockData = {
	friends = {},
	groups = {},
	groupAssignments = {},
	brokerFriends = {},
	guildMembers = {},
	guildName = "",
	guildRosterMembers = {},
	guildRosterName = "",
	guildRosterMOTD = "",
	recentAllies = {},
	friendNicknames = {},
	guildNicknames = {},
	recentlyAddedTimestamps = {},
	contactMemory = {},
}

-- Mock BattleTag for privacy in screenshots
PreviewMode.MOCK_BATTLETAG = "YourName#1234"

function PreviewMode:GetPreviewBattleTag()
	if self:IsComponentEnabled("battletag") then
		return self.MOCK_BATTLETAG
	end
	return nil
end

function PreviewMode:GetMockFriendNickname(friendUID)
	if
		not (self:IsComponentEnabled("friends") or self:IsComponentEnabled("broker"))
		or type(friendUID) ~= "string"
	then
		return nil
	end
	return self.mockData.friendNicknames and self.mockData.friendNicknames[friendUID] or nil
end

function PreviewMode:GetMockGuildNickname(fullName)
	if
		not (self:IsComponentEnabled("guild") or self:IsComponentEnabled("broker"))
		or type(fullName) ~= "string"
	then
		return nil
	end
	return self.mockData.guildNicknames and self.mockData.guildNicknames[fullName] or nil
end

function PreviewMode:GetMockRecentlyAddedTimestamp(friendUID)
	if not self:IsComponentEnabled("friends") or type(friendUID) ~= "string" then
		return nil
	end
	return self.mockData.recentlyAddedTimestamps and self.mockData.recentlyAddedTimestamps[friendUID] or nil
end

function PreviewMode:GetMockRecentlyAddedUIDs()
	if not self:IsComponentEnabled("friends") then
		return nil
	end
	local result = {}
	for friendUID in pairs(self.mockData.recentlyAddedTimestamps or {}) do
		result[#result + 1] = friendUID
	end
	table.sort(result)
	return result
end

-- Returns a second boolean so ContactMemory can distinguish an ephemeral mock
-- contact from an unrelated real contact that merely has no stored data.
function PreviewMode:GetMockContact(contactKey)
	if not self:IsComponentEnabled("friends") or type(contactKey) ~= "string" then
		return nil, false
	end
	local contact = self.mockData.contactMemory and self.mockData.contactMemory[contactKey]
	if contact then
		return contact, true
	end
	return nil, false
end

-- ============================================
-- BATTLETAG MASKING
-- ============================================

--[[
	Get the BattleNet frame where the BattleTag is displayed
]]
function PreviewMode:GetBattleNetFrame()
	if not BetterFriendsFrame then
		return nil
	end
	if not BetterFriendsFrame.FriendsTabHeader then
		return nil
	end
	return BetterFriendsFrame.FriendsTabHeader.BattlenetFrame
end

--[[
	Apply mock BattleTag to the BattleNet frame
	This hides the user's real BattleTag for screenshots
]]
function PreviewMode:ApplyMockBattleTag()
	local bnetFrame = self:GetBattleNetFrame()
	if not bnetFrame or not bnetFrame.Tag then
		-- BFL:DebugPrint("|cffff0000PreviewMode:|r BattleNetFrame not found!")
		return
	end
	local StreamerMode = BFL:GetModule("StreamerMode")
	if StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive() then
		if StreamerMode.UpdateState then
			StreamerMode:UpdateState()
		end
		return
	end

	-- Store original BattleTag text for restoration
	if not self.originalBattleTag then
		self.originalBattleTag = bnetFrame.Tag:GetText()
	end

	-- Format mock BattleTag like the original (with colored suffix)
	local mockTag = self.MOCK_BATTLETAG
	local symbol = string.find(mockTag, "#")
	if symbol then
		local suffix = string.sub(mockTag, symbol)
		mockTag = string.sub(mockTag, 1, symbol - 1) .. "|cff416380" .. suffix .. "|r"
	end

	-- Apply mock BattleTag
	bnetFrame.Tag:SetText(mockTag)
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() and FriendsUI.RefreshBattleTag then
		FriendsUI:RefreshBattleTag()
	end

	-- Hook the FrameInitializer to prevent it from overwriting our mock tag
	local FrameInitializer = BFL:GetModule("FrameInitializer")
	if FrameInitializer and not self.originalInitializeBattlenetFrame then
		self.originalInitializeBattlenetFrame = FrameInitializer.InitializeBattlenetFrame

		FrameInitializer.InitializeBattlenetFrame = function(initSelf, frame)
			-- Call original function first
			if PreviewMode.originalInitializeBattlenetFrame then
				PreviewMode.originalInitializeBattlenetFrame(initSelf, frame)
			end

			-- Only the BattleTag fixture owns this text. Other isolated preview
			-- profiles must leave the real account header untouched.
			if PreviewMode:IsComponentEnabled("battletag") then
				local StreamerMode = BFL:GetModule("StreamerMode")
				if StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive() then
					if StreamerMode.UpdateState then
						StreamerMode:UpdateState()
					end
					return
				end
				local bnFrame = PreviewMode:GetBattleNetFrame()
				if bnFrame and bnFrame.Tag then
					local mockTag = PreviewMode.MOCK_BATTLETAG
					local sym = string.find(mockTag, "#")
					if sym then
						local suf = string.sub(mockTag, sym)
						mockTag = string.sub(mockTag, 1, sym - 1) .. "|cff416380" .. suf .. "|r"
					end
					bnFrame.Tag:SetText(mockTag)
				end
			end
		end
	end

	-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Applied mock BattleTag: " .. self.MOCK_BATTLETAG)
end

--[[
	Restore the original BattleTag
]]
function PreviewMode:RestoreBattleTag()
	local bnetFrame = self:GetBattleNetFrame()
	if not bnetFrame or not bnetFrame.Tag then
		return
	end

	-- Restore original InitializeBattlenetFrame function
	local FrameInitializer = BFL:GetModule("FrameInitializer")
	if FrameInitializer and self.originalInitializeBattlenetFrame then
		FrameInitializer.InitializeBattlenetFrame = self.originalInitializeBattlenetFrame
		self.originalInitializeBattlenetFrame = nil
	end

	-- Restore original BattleTag if we saved it
	if self.originalBattleTag then
		bnetFrame.Tag:SetText(self.originalBattleTag)
		self.originalBattleTag = nil
		-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Restored original BattleTag")
	else
		-- If we don't have the original, refresh from API
		local _, battleTag = BNGetInfo()
		if battleTag then
			local symbol = string.find(battleTag, "#")
			if symbol then
				local suffix = string.sub(battleTag, symbol)
				battleTag = string.sub(battleTag, 1, symbol - 1) .. "|cff416380" .. suffix .. "|r"
			end
			bnetFrame.Tag:SetText(battleTag)
		end
	end

	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() and FriendsUI.RefreshBattleTag then
		FriendsUI:RefreshBattleTag()
	end
end

-- ============================================
-- PREVIEW MODE ACTIVATION
-- ============================================

--[[
	Enable Preview Mode
	Creates and displays comprehensive mock data for screenshots
]]
function PreviewMode:EnableLegacyCombined()
	if self.enabled then
		PreviewMessage("|cffff8800BetterFriendlist:|r Preview mode is already enabled!")
		self:ApplyBrokerPreviewData()
		return
	end

	PreviewMessage("|cff00ff00BetterFriendlist:|r |cffffd700Preview Mode ENABLED|r")
	PreviewMessage("|cff888888Creating demonstration data for screenshots...|r")

	self.settingsRefreshGeneration = self.settingsRefreshGeneration + 1
	self.settingsRefreshPending = false
	self.pendingSettingKeys = {}
	self.enabled = true
	self.mockFriendsRenderState = nil

	-- Generate mock friends (mix of online and offline)
	self:GenerateMockFriends()

	-- Generate mock groups
	self:GenerateMockGroupsData()

	-- Generate broker tooltip data
	self:GenerateBrokerPreviewData()
	self:GenerateGuildPreviewData()

	-- Enable existing mock systems
	self:EnableRaidMock()
	self:EnableQuickJoinMock()
	self:EnableInviteMock()

	-- Apply mock data to FriendsList
	self:ApplyMockFriends()

	-- Apply mock BattleTag (hide real BattleTag for screenshots)
	self:ApplyMockBattleTag()

	-- Force UI refresh
	self:RefreshAllUI()
	self:ApplyBrokerPreviewData()

	PreviewMessage("|cff00ff00BetterFriendlist:|r Preview data created:")
	PreviewMessage("  |cffffffff- Quick Join tooltip class-row preview groups|r")
	PreviewMessage("  |cffffffff- " .. #self.mockData.brokerFriends .. " broker friend rows|r")
	PreviewMessage("  |cffffffff- " .. #self.mockData.guildMembers .. " broker guild rows|r")
	PreviewMessage("  |cffffffff• " .. #self.mockData.friends .. " mock friends|r")
	PreviewMessage("  |cffffffff• " .. #self.mockData.groups .. " custom groups|r")
	PreviewMessage("  |cffffffff• Raid frame with 25 players|r")
	PreviewMessage("  |cffffffff• Quick Join with Retail 12.1 censored/reveal groups|r")
	PreviewMessage("  |cffffffff• 2 friend invite requests|r")
	PreviewMessage("  |cffffffff• BattleTag hidden (" .. self.MOCK_BATTLETAG .. ")|r")
	PreviewMessage("")
	PreviewMessage("|cffffcc00Tip:|r Use |cffffffff/bfl preview|r again to disable preview mode")
end

function PreviewMode:ShowProfileSection(sectionID)
	if not sectionID then
		return
	end

	if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
		if _G.ShowBetterFriendsFrame then
			_G.ShowBetterFriendsFrame(1)
		else
			BetterFriendsFrame:Show()
		end
	end

	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.SelectSection then
		return FriendsUI:SelectSection(sectionID)
	end

	local legacyTabs = {
		friends = { 1, 1 },
		recent_allies = { 1, 2 },
		quick_join = { 4 },
		recruit_a_friend = { 1, 3 },
		raid = { 3 },
		guild = { 1, 4 },
	}
	local tabs = legacyTabs[sectionID]
	if tabs and BetterFriendsFrame_ShowBottomTab then
		BetterFriendsFrame_ShowBottomTab(tabs[1])
	end
	if tabs and tabs[2] and BetterFriendsFrame_ShowTab then
		BetterFriendsFrame_ShowTab(tabs[2])
	end
	return tabs and sectionID or nil
end

function PreviewMode:RenderMockFriendsNow(FriendsList, force)
	if not self:IsComponentEnabled("friends") or #self.mockData.friends == 0 then
		return false
	end
	FriendsList = FriendsList or BFL:GetModule("FriendsList")
	if not FriendsList or not FriendsList.UpdateFriendsList then
		return false
	end
	if force then
		-- Activation may have produced a header-only provider while fixture,
		-- group, and navigation events were deliberately held behind the render
		-- gate.  Release every render cache before the final authoritative model
		-- hand-off so the mock rows cannot inherit that intermediate provider.
		self.mockFriendsRenderState = nil
		FriendsList.lastBuildSignature = nil
		FriendsList.cachedDisplayList = nil
		FriendsList.cachedGroupedFriends = nil
		FriendsList.forceLayoutRebuild = true
	end
	FriendsList:UpdateFriendsList(true)
	return true
end

local MOCK_FRIEND_RENDER_PHASES = {
	"prepare",
	"evaluate",
	"model",
	"filters",
	"sort",
	"display",
}

function PreviewMode:RenderMockFriendsPhase(phase, context)
	context = context or {}
	local FriendsList = context.friendsList or BFL:GetModule("FriendsList")
	context.friendsList = FriendsList
	if not FriendsList then
		return false
	end

	if phase == "prepare" then
		self:PrepareMockFriendsRender(FriendsList)
	elseif phase == "evaluate" then
		context.shouldRenderFriends = self:ShouldRenderMockFriends(FriendsList)
	elseif phase == "model" then
		if context.shouldRenderFriends then
			wipe(FriendsList.friendsList)
			for _, friend in ipairs(self.mockData.friends) do
				table.insert(FriendsList.friendsList, friend)
			end
		end
	elseif phase == "filters" then
		if context.shouldRenderFriends then
			FriendsList:ApplyFilters()
		end
	elseif phase == "sort" then
		if context.shouldRenderFriends then
			FriendsList:ApplySort()
		end
	elseif phase == "display" and context.shouldRenderFriends then
		FriendsList:RenderDisplay(true)
	end
	return context.shouldRenderFriends == true
end

local PREVIEW_REFRESH_COMPONENT_ORDER = {
	"friends",
	"requests",
	"recent_allies",
	"quick_join",
	"raf",
	"raid",
	"guild",
	"broker",
	"battletag",
	"navigation",
}

function PreviewMode:RefreshPreviewComponent(component, options, result)
	options = options or {}
	result = result or {}

	if component == "friends" then
		if self:RenderMockFriendsNow() then
			result.friends = true
			if options.auditFriends then
				self:ReportFriendsRenderAudit()
			end
			return true
		end
	elseif component == "requests" and self:IsComponentEnabled("requests") then
		local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
		if FriendsUI and FriendsUI.RefreshRequests then
			-- Native SocialUI requests a tab glow when a new invite arrives,
			-- but suppresses it while the Requests tab is selected.
			FriendsUI:RefreshRequests(options.reason == "activation")
			result.requests = true
			return true
		end
	elseif component == "recent_allies" and self:IsComponentEnabled("recent_allies") then
		local RecentAllies = BFL:GetModule("RecentAllies")
		local recentFrame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
		if RecentAllies and recentFrame and RecentAllies.Refresh then
			RecentAllies:Refresh(recentFrame, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
			result.recent_allies = true
			return true
		end
	elseif component == "quick_join" and self:IsComponentEnabled("quick_join") then
		local QuickJoin = BFL:GetModule("QuickJoin")
		if QuickJoin and QuickJoin.Update then
			QuickJoin:Update(true)
			result.quick_join = true
			return true
		end
	elseif component == "raf" and self:IsComponentEnabled("raf") then
		local RAF = BFL:GetModule("RAF")
		local rafFrame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
		if RAF and rafFrame and RAF.ApplyPreviewData then
			RAF:ApplyPreviewData(rafFrame)
			result.raf = true
			return true
		end
	elseif component == "raid" and self:IsComponentEnabled("raid") then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame then
			if RaidFrame.mockEnabled and RaidFrame.ApplyMockData then
				RaidFrame:ApplyMockData()
			else
				if RaidFrame.BuildDisplayList then
					RaidFrame:BuildDisplayList()
				end
				if RaidFrame.UpdateAllMemberButtons then
					RaidFrame:UpdateAllMemberButtons()
				elseif RaidFrame.UpdateMemberButtons then
					RaidFrame:UpdateMemberButtons()
				end
				if RaidFrame.UpdateControlPanel then
					RaidFrame:UpdateControlPanel()
				end
			end
			result.raid = true
			return true
		end
	elseif component == "guild" and self:IsComponentEnabled("guild") then
		self:RefreshGuildPreview()
		result.guild = true
		return true
	elseif component == "broker" and self:IsComponentEnabled("broker") then
		self:ApplyBrokerPreviewData()
		result.broker = true
		return true
	elseif component == "battletag" and self:IsComponentEnabled("battletag") then
		local StreamerMode = BFL:GetModule("StreamerMode")
		if StreamerMode and StreamerMode.UpdateState then
			StreamerMode:UpdateState()
		end
		if not (StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive()) then
			self:ApplyMockBattleTag()
		end
		result.battletag = true
		return true
	elseif component == "navigation" then
		local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
		if FriendsUI and FriendsUI.RefreshNavigation then
			FriendsUI:RefreshNavigation()
			return true
		end
	end
	return false
end

function PreviewMode:RefreshActiveComponents(options)
	options = options or {}
	if not self.enabled or self.refreshingSettingsPreview then
		return false
	end

	self.refreshingSettingsPreview = true
	local ok, refreshed = pcall(function()
		local result = {}
		for _, component in ipairs(PREVIEW_REFRESH_COMPONENT_ORDER) do
			self:RefreshPreviewComponent(component, options, result)
		end
		return result
	end)
	self.refreshingSettingsPreview = false

	if not ok then
		error(refreshed, 0)
	end
	return refreshed
end

function PreviewMode:FlushPendingSettingsRefresh(generation)
	if generation ~= self.settingsRefreshGeneration then
		return false
	end
	self.settingsRefreshPending = false
	self.pendingSettingKeys = {}
	if not self.enabled then
		return false
	end
	return self:RefreshActiveComponents({ reason = "settings" })
end

function PreviewMode:OnSettingChanged(key)
	if not self.enabled or self.refreshingSettingsPreview then
		return false
	end
	self.pendingSettingKeys = self.pendingSettingKeys or {}
	self.pendingSettingKeys[tostring(key or "unknown")] = true
	if self.settingsRefreshPending then
		return true
	end

	self.settingsRefreshPending = true
	local generation = self.settingsRefreshGeneration
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			PreviewMode:FlushPendingSettingsRefresh(generation)
		end)
	else
		self:FlushPendingSettingsRefresh(generation)
	end
	return true
end

function PreviewMode:RefreshIsolatedProfile()
	return self:RefreshActiveComponents({ auditFriends = true, reason = "activation" })
end

function PreviewMode:ReportFriendsRenderAudit()
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then
		self:PrintProfileStep(self.activeProfile, "render audit FAILED: FriendsList unavailable")
		return false
	end

	local expectedMockCount = #self.mockData.friends
	local modelMockCount = 0
	for _, friend in ipairs(FriendsList.friendsList or {}) do
		if friend._isMock then
			modelMockCount = modelMockCount + 1
		end
	end

	local providerRowCount = 0
	local providerMockCount = 0
	local providerGroupHeaderCount = 0
	local provider = FriendsList.scrollBox
		and FriendsList.scrollBox.GetDataProvider
		and FriendsList.scrollBox:GetDataProvider()
	if provider and provider.Enumerate then
		for _, elementData in provider:Enumerate() do
			providerRowCount = providerRowCount + 1
			if elementData.friend and elementData.friend._isMock then
				providerMockCount = providerMockCount + 1
			end
			if elementData.groupId and not elementData.friend then
				providerGroupHeaderCount = providerGroupHeaderCount + 1
			end
		end
	end

	local requiresGroupHeaders = self:IsComponentEnabled("groups")
	local rendered = expectedMockCount > 0
		and modelMockCount == expectedMockCount
		and providerMockCount > 0
		and (not requiresGroupHeaders or providerGroupHeaderCount > 0)
	self:PrintProfileStep(
		self.activeProfile,
		string.format(
			"render audit %s: model %d/%d mock friends, provider %d mock rows and %d/%d group headers in %d rows",
			rendered and "OK" or "FAILED",
			modelMockCount,
			expectedMockCount,
			providerMockCount,
			providerGroupHeaderCount,
			#self.mockData.groups,
			providerRowCount
		)
	)
	return rendered
end

function PreviewMode:PrintProfileStep(profileID, step)
	PreviewMessage("|cff66ccffBFL Preview [" .. tostring(profileID) .. "]:|r " .. step)
end

local function AddActivationStep(steps, id, label, action)
	steps[#steps + 1] = {
		id = id,
		label = label,
		action = action,
	}
end

local MOCK_FRIEND_APPLICATION_LABELS = {
	persist = "Back up real group state",
	hook = "Install mock friend data hook",
	groups = "Install mock group definitions",
	group_order = "Install mock group order",
	assignments = "Install mock friend/group assignments",
	cache = "Invalidate friend layout caches",
}

local MOCK_FRIEND_RENDER_LABELS = {
	prepare = "Refresh friend settings and font caches",
	evaluate = "Evaluate friend render invalidation state",
	model = "Populate the friend-list model",
	filters = "Apply friend filters",
	sort = "Sort preview friends",
	display = "Build and display friend ScrollBox rows",
}

local PREVIEW_REFRESH_LABELS = {
	requests = "Refresh Friend Requests and request glow",
	recent_allies = "Refresh Recent Allies",
	quick_join = "Refresh Quick Join cards and glow",
	raf = "Refresh Recruit a Friend preview",
	raid = "Build and display the Raid roster",
	guild = "Refresh Guild roster",
	broker = "Apply Broker preview rows",
	battletag = "Refresh Streamer Mode and BattleTag",
	navigation = "Refresh side-tab navigation state",
}

local RAID_MOCK_APPLY_LABELS = {
	build_display = "Build sorted Raid display data",
	member_buttons = "Populate Raid member buttons",
	visibility = "Show Raid group containers",
	control_panel = "Update Raid role and member counts",
	button_visuals = "Apply Raid member visuals",
	layout = "Calculate Raid group layout and final button state",
}

function PreviewMode:CancelStagedActivation()
	self.activationGeneration = (self.activationGeneration or 0) + 1
	self.activationInProgress = false
	self.activationTrace = nil
	self.activationRenderGate = false
	self.activationDebug = false
end

function PreviewMode:PrepareProfileActivation(profileID, debugActivation)
	local normalizedID, profile = self:GetProfileDefinition(profileID)
	if not profile then
		return nil
	end

	self:CancelStagedActivation()
	if self.enabled then
		self:Disable(true)
	end

	self.settingsRefreshGeneration = self.settingsRefreshGeneration + 1
	self.settingsRefreshPending = false
	self.pendingSettingKeys = {}
	self.enabled = true
	self.activeProfile = normalizedID
	self.activeComponents = CopyComponentSet(profile.components)
	self.mockFriendsRenderState = nil
	self.activationDebug = debugActivation == true
	-- Both slash-command paths now boot across multiple frames.  Hold friend
	-- events for the whole activation so neither the quiet nor traced path can
	-- publish a partially populated model.
	self.activationRenderGate = self:IsComponentEnabled("friends")
	if self.activationDebug then
		self:PrintProfileStep(normalizedID, "starting")
	end
	return normalizedID, profile
end

function PreviewMode:BuildProfileActivationSteps(normalizedID, profile)
	local steps = {}
	local context = {
		profileID = normalizedID,
		profile = profile,
		refreshResult = {},
	}

	if self:IsComponentEnabled("friends") then
		AddActivationStep(steps, "friends.selection.clear", "Clear selected friend row", function()
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList and FriendsList.ClearSelection then
				FriendsList:ClearSelection()
			end
		end)
		AddActivationStep(steps, "friends.fixtures.generate", "Generate mock friend accounts and game sessions", function()
			self:GenerateMockFriends()
		end)
		if not self:IsComponentEnabled("tags") then
			AddActivationStep(steps, "friends.tags.strip", "Remove tags from this isolation profile", function()
				for _, friend in ipairs(self.mockData.friends) do
					-- An empty table is intentional: nil would make FriendTags
					-- fall back to a native lookup for the synthetic account ID.
					friend.friendTags = {}
				end
			end)
		end
		if self:IsComponentEnabled("groups") then
			AddActivationStep(steps, "friends.groups.generate", "Generate custom group headers", function()
				self:GenerateMockGroupsData(profile.groupFixture)
			end)
			if not self:IsComponentEnabled("group_assignments") then
				AddActivationStep(steps, "friends.groups.assignments.clear", "Remove mock group assignments", function()
					self.mockData.groupAssignments = {}
				end)
			end
		else
			AddActivationStep(steps, "friends.groups.disable", "Clear custom group fixtures", function()
				self.mockData.groups = {}
				self.mockData.groupAssignments = {}
			end)
		end
	end

	if self:IsComponentEnabled("broker") then
		AddActivationStep(steps, "broker.fixtures.generate", "Generate Broker friend and guild rows", function()
			self:GenerateBrokerPreviewData()
		end)
	end
	if self:IsComponentEnabled("guild") then
		AddActivationStep(steps, "guild.fixtures.generate", "Generate mock Guild roster", function()
			self:GenerateGuildPreviewData()
		end)
	end
	if self:IsComponentEnabled("recent_allies") then
		AddActivationStep(steps, "recent.fixtures.generate", "Generate Recent Allies rows", function()
			self:GenerateRecentAlliesPreviewData()
		end)
	end
	if self:IsComponentEnabled("raf") then
		AddActivationStep(steps, "raf.fixtures.enable", "Create local Recruit a Friend preview data", function()
			self:EnableRAFMock()
		end)
	end

	if self:IsComponentEnabled("friends") then
		local includeGroups = self:IsComponentEnabled("groups")
		for _, phase in ipairs(MOCK_FRIEND_APPLICATION_PHASES) do
			if
				phase == "hook"
				or phase == "cache"
				or includeGroups
			then
				local phaseID = phase
				AddActivationStep(
					steps,
					"friends.apply." .. phaseID,
					MOCK_FRIEND_APPLICATION_LABELS[phaseID],
					function()
						self:ApplyMockFriendsPhase(phaseID, includeGroups)
					end
				)
			end
		end
	end

	if self:IsComponentEnabled("raid") then
		AddActivationStep(steps, "raid.guards.enable", "Install Raid mock event guards", function()
			self:EnableRaidMock({ deferPreset = true })
		end)
		AddActivationStep(steps, "raid.fixtures.generate", "Generate the 25-player Raid mock roster", function()
			local RaidFrame = BFL:GetModule("RaidFrame")
			if RaidFrame and RaidFrame.CreateMockPreset_Standard then
				RaidFrame:CreateMockPreset_Standard({
					deferApply = true,
					deferDynamicUpdates = true,
				})
			end
		end)
	end
	if self:IsComponentEnabled("quick_join") then
		AddActivationStep(steps, "quickjoin.fixtures.enable", "Create Quick Join preview groups", function()
			self:EnableQuickJoinMock()
		end)
	end
	if self:IsComponentEnabled("requests") then
		AddActivationStep(steps, "requests.fixtures.enable", "Create mock friend requests", function()
			self:EnableInviteMock()
		end)
	end
	if self:IsComponentEnabled("battletag") then
		AddActivationStep(steps, "battletag.fixture.apply", "Apply preview BattleTag", function()
			self:ApplyMockBattleTag()
		end)
	end

	if profile.section then
		AddActivationStep(steps, "section.open." .. profile.section, "Open section " .. profile.section, function()
			self.activeSection = self:ShowProfileSection(profile.section)
		end)
	end

	if self:IsComponentEnabled("raid") then
		local RaidFrame = BFL:GetModule("RaidFrame")
		local phases = RaidFrame
			and RaidFrame.GetMockDataApplyPhases
			and RaidFrame:GetMockDataApplyPhases()
			or {}
		for _, phase in ipairs(phases) do
			local phaseID = phase
			if phaseID == "member_buttons" then
				AddActivationStep(
					steps,
					"raid.render.member_buttons.prepare",
					"Prepare Raid member data and font state",
					function()
						local activeRaidFrame = BFL:GetModule("RaidFrame")
						if activeRaidFrame and activeRaidFrame.PrepareMemberButtonUpdate then
							activeRaidFrame:PrepareMemberButtonUpdate()
						end
					end
				)
				for groupIndex = 1, 8 do
					local diagnosticGroupIndex = groupIndex
					AddActivationStep(
						steps,
						"raid.render.member_buttons.group_" .. diagnosticGroupIndex .. ".prepare",
						"Prepare Raid Group " .. diagnosticGroupIndex .. " container",
						function()
							local activeRaidFrame = BFL:GetModule("RaidFrame")
							if activeRaidFrame and activeRaidFrame.PrepareMemberButtonGroup then
								activeRaidFrame:PrepareMemberButtonGroup(diagnosticGroupIndex)
							end
						end
					)
					for slotIndex = 1, 5 do
						local diagnosticSlotIndex = slotIndex
						AddActivationStep(
							steps,
							"raid.render.member_buttons.group_"
								.. diagnosticGroupIndex
								.. ".slot_"
								.. diagnosticSlotIndex,
							"Populate Raid Group "
								.. diagnosticGroupIndex
								.. " Slot "
								.. diagnosticSlotIndex,
							function()
								local activeRaidFrame = BFL:GetModule("RaidFrame")
								if activeRaidFrame and activeRaidFrame.UpdateMemberButtonSlot then
									activeRaidFrame:UpdateMemberButtonSlot(
										diagnosticGroupIndex,
										diagnosticSlotIndex
									)
								end
							end
						)
					end
				end
			else
				AddActivationStep(
					steps,
					"raid.render." .. phaseID,
					RAID_MOCK_APPLY_LABELS[phaseID] or phaseID,
					function()
						local activeRaidFrame = BFL:GetModule("RaidFrame")
						if activeRaidFrame and activeRaidFrame.ApplyMockDataPhase then
							activeRaidFrame:ApplyMockDataPhase(phaseID)
						end
					end
				)
			end
		end
	end

	if self:IsComponentEnabled("friends") then
		for _, phase in ipairs(MOCK_FRIEND_RENDER_PHASES) do
			local phaseID = phase
			AddActivationStep(
				steps,
				"friends.render." .. phaseID,
				MOCK_FRIEND_RENDER_LABELS[phaseID],
				function()
					self:RenderMockFriendsPhase(phaseID, context)
				end
			)
		end
		AddActivationStep(steps, "friends.render.audit", "Audit rendered friend and group rows", function()
			-- The authoritative render happens after the activation gate is
			-- released.  Defer the audit until then or it can report the
			-- intentionally gated intermediate provider.
			context.friendAuditPending = true
		end)
	end

	for _, component in ipairs(PREVIEW_REFRESH_COMPONENT_ORDER) do
		if
			component ~= "friends"
			and component ~= "raid"
			and (component == "navigation" or self:IsComponentEnabled(component))
		then
			local componentID = component
			AddActivationStep(
				steps,
				"refresh." .. componentID,
				PREVIEW_REFRESH_LABELS[componentID],
				function()
					self:RefreshPreviewComponent(
						componentID,
						{ reason = "activation" },
						context.refreshResult
					)
				end
			)
		end
	end
	return steps, context
end

function PreviewMode:CompleteProfileActivation(normalizedID, profile)
	local debugActivation = self.activationDebug == true
	local trace = self.activationTrace
	self.activationRenderGate = false
	self.activationInProgress = false
	self.activationTrace = nil
	if self:IsComponentEnabled("friends") then
		self:RenderMockFriendsNow(nil, true)
	end
	if debugActivation and trace and trace.context and trace.context.friendAuditPending then
		self:ReportFriendsRenderAudit()
	end
	if self:IsComponentEnabled("raid") then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame and RaidFrame.StartMockDynamicUpdates then
			RaidFrame:StartMockDynamicUpdates()
		end
	end
	if debugActivation then
		self:PrintProfileStep(normalizedID, "complete")
	end

	if profile.section and self.activeSection ~= profile.section then
		PreviewMessage(
			"|cffff8800BetterFriendlist:|r Requested section "
				.. profile.section
				.. " is unavailable; selected "
				.. tostring(self.activeSection or "none")
				.. "."
			)
	end
	if debugActivation then
		PreviewMessage(
			"|cff00ff00BetterFriendlist:|r Preview profile |cffffd700"
				.. normalizedID
				.. "|r enabled in isolation."
		)
		PreviewMessage("|cff888888Use /bfl preview off before the next profile, or select another profile directly.|r")
	else
		PreviewMessage(
			"|cff00ff00BetterFriendlist:|r Preview mode enabled: |cffffd700" .. normalizedID .. "|r."
		)
	end
	self.activationDebug = false
	return true
end

local function QueuePreviewActivationCallback(delay, callback)
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, callback)
	else
		callback()
	end
end

function PreviewMode:PrintActivationMarker(status, trace, index, step, detail)
	local elapsed = GetTime and GetTime() or 0
	local message = string.format(
		"|cff66ccffBFL Preview Boot|r %02d/%02d |cffffd700%s|r [%s] %s |cff888888(t=%.3f)|r",
		index,
		#trace.steps,
		status,
		step.id,
		detail or step.label,
		elapsed
	)
	PreviewMessage(message)
end

function PreviewMode:RunStagedActivationStep(generation, index)
	local trace = self.activationTrace
	if
		not trace
		or generation ~= self.activationGeneration
		or not self.activationInProgress
		or not self.enabled
	then
		return
	end

	local step = trace.steps[index]
	if not step then
		return
	end
	trace.index = index
	if trace.debugMarkers then
		self:PrintActivationMarker("READY", trace, index, step, "starting in 150 ms: " .. step.label)
	end

	local stepDelay = trace.debugMarkers and PREVIEW_ACTIVATION_STEP_DELAY or 0
	QueuePreviewActivationCallback(stepDelay, function()
		local currentTrace = PreviewMode.activationTrace
		if
			not currentTrace
			or generation ~= PreviewMode.activationGeneration
			or not PreviewMode.activationInProgress
			or not PreviewMode.enabled
		then
			return
		end

		local ok, err = pcall(step.action)
		if not ok then
			if currentTrace.debugMarkers then
				PreviewMode:PrintActivationMarker("ERROR", currentTrace, index, step, tostring(err))
			else
				PreviewMessage(
					"|cffff8800BetterFriendlist preview failed at ["
						.. tostring(step.id)
						.. "]:|r "
						.. tostring(err)
				)
			end
			PreviewMode.activationInProgress = false
			PreviewMode.activationRenderGate = false
			PreviewMessage(
				"|cffff8800BFL Preview Boot aborted.|r Use |cffffffff/bfl preview off|r to restore real data."
			)
			return
		end

		if currentTrace.debugMarkers then
			PreviewMode:PrintActivationMarker("DONE", currentTrace, index, step)
		end
		if index < #currentTrace.steps then
			QueuePreviewActivationCallback(0, function()
				PreviewMode:RunStagedActivationStep(generation, index + 1)
			end)
		else
			if currentTrace.debugMarkers then
				PreviewMessage(
					string.format(
						"|cff00ff00BFL Preview Boot finished all %d traced steps.|r",
						#currentTrace.steps
					)
				)
			end
			PreviewMode:CompleteProfileActivation(currentTrace.profileID, currentTrace.profile)
		end
	end)
end

function PreviewMode:EnableProfileStaged(profileID)
	local normalizedID, profile = self:PrepareProfileActivation(profileID, true)
	if not profile then
		return false
	end

	local steps, context = self:BuildProfileActivationSteps(normalizedID, profile)
	self.activationInProgress = true
	self.activationTrace = {
		profileID = normalizedID,
		profile = profile,
		steps = steps,
		context = context,
		index = 0,
		debugMarkers = true,
	}
	local generation = self.activationGeneration
	PreviewMessage(
		string.format(
			"|cff00ff00BFL Preview Boot queued:|r profile |cffffd700%s|r, %d traced steps.",
			normalizedID,
			#steps
		)
	)
	self:RunStagedActivationStep(generation, 1)
	return true
end

-- Normal slash commands use the same frame-sliced activation contract as the
-- diagnostic path, but without chat markers or the deliberate 150 ms pauses.
function PreviewMode:EnableProfile(profileID)
	local normalizedID, profile = self:PrepareProfileActivation(profileID, false)
	if not profile then
		return false
	end
	local steps, context = self:BuildProfileActivationSteps(normalizedID, profile)
	self.activationInProgress = true
	self.activationTrace = {
		profileID = normalizedID,
		profile = profile,
		steps = steps,
		context = context,
		index = 0,
		debugMarkers = false,
	}
	local generation = self.activationGeneration
	self:RunStagedActivationStep(generation, 1)
	return true
end

-- Keep the historical synchronous API for internal test/scenario callers that
-- replace the generated fixtures immediately after Enable() returns.  User
-- slash commands never use this path.
function PreviewMode:EnableProfileImmediate(profileID)
	local normalizedID, profile = self:PrepareProfileActivation(profileID, false)
	if not profile then
		return false
	end
	local steps = self:BuildProfileActivationSteps(normalizedID, profile)
	for _, step in ipairs(steps) do
		step.action()
	end
	return self:CompleteProfileActivation(normalizedID, profile)
end

-- Backwards-compatible combined fixture for tests and scenario tooling.
function PreviewMode:Enable()
	return self:EnableProfileImmediate("all")
end

--[[
	Disable Preview Mode
	Restores real data and removes all mock content
]]
function PreviewMode:Disable(silent)
	if not self.enabled then
		if not silent then
			PreviewMessage("|cffff8800BetterFriendlist:|r Preview mode is not enabled!")
		end
		return
	end
	self:CancelStagedActivation()

	if not silent then
		PreviewMessage("|cff00ff00BetterFriendlist:|r |cffffd700Preview Mode DISABLED|r")
	end

	local activeComponents = self.activeProfile and CopyComponentSet(self.activeComponents) or {
		friends = true,
		groups = true,
		tags = true,
		broker = true,
		quick_join = true,
		raf = true,
		raid = true,
		requests = true,
		guild = true,
		battletag = true,
	}
	self.enabled = false
	self.settingsRefreshGeneration = self.settingsRefreshGeneration + 1
	self.settingsRefreshPending = false
	self.pendingSettingKeys = {}
	self.refreshingSettingsPreview = false
	self.mockFriendsRenderState = nil
	local previewGroupAssignments = self.mockData.groupAssignments

	-- Release a selected mock row before its data and pooled button disappear.
	-- Otherwise its synthetic UID can remain selected after preview mode ends.
	local FriendsList = BFL:GetModule("FriendsList")
	if activeComponents.friends and FriendsList and FriendsList.ClearSelection then
		FriendsList:ClearSelection()
	end

	if activeComponents.broker then
		self:ClearBrokerPreviewData()
	end

	-- Clear mock data
	self.mockData.friends = {}
	self.mockData.groups = {}
	self.mockData.groupAssignments = {}
	self.mockData.brokerFriends = {}
	self.mockData.guildMembers = {}
	self.mockData.guildName = ""
	self.mockData.guildRosterMembers = {}
	self.mockData.guildRosterName = ""
	self.mockData.guildRosterMOTD = ""
	self.mockData.recentAllies = {}
	self.mockData.friendNicknames = {}
	self.mockData.guildNicknames = {}
	self.mockData.recentlyAddedTimestamps = {}
	self.mockData.contactMemory = {}

	-- Restore original UpdateFriendsList function
	if FriendsList and self.originalUpdateFriendsList then
		FriendsList.UpdateFriendsList = self.originalUpdateFriendsList
	end

	-- Restore original groups in Groups.groups table
	local Groups = BFL:GetModule("Groups")
	if Groups and self.originalGroups then
		-- Remove mock groups by removing any non-original group
		for id in pairs(Groups.groups) do
			if not self.originalGroups[id] then
				Groups.groups[id] = nil
			end
		end
		-- Restore original groups (in case any were modified)
		for id, data in pairs(self.originalGroups) do
			Groups.groups[id] = data
		end
		self.originalGroups = nil
	end

	-- Restore original group order
	if BetterFriendlistDB and self.originalGroupOrder then
		BetterFriendlistDB.groupOrder = self.originalGroupOrder
		self.originalGroupOrder = nil
	end

	-- Restore original friendGroups only when the groups fixture actually
	-- replaced them. Broker-only profiles must never remove real assignments.
	if BetterFriendlistDB and BetterFriendlistDB.friendGroups and self.originalFriendGroups then
		-- Remove mock friend group assignments
		for uid in pairs(previewGroupAssignments or {}) do
			BetterFriendlistDB.friendGroups[uid] = nil
		end
		for uid in pairs(MOCK_GROUP_ASSIGNMENTS) do
			BetterFriendlistDB.friendGroups[uid] = nil
		end
		for uid in pairs(MOCK_WOW_GROUP_ASSIGNMENTS) do
			BetterFriendlistDB.friendGroups[uid] = nil
		end

		-- Restore original assignments
		for uid, groups in pairs(self.originalFriendGroups) do
			BetterFriendlistDB.friendGroups[uid] = groups
		end
		self.originalFriendGroups = nil
	end

	if BetterFriendlistDB then
		BetterFriendlistDB.previewBackup = nil
	end

	-- Disable only systems touched by the active profile. This is essential for
	-- crash bisection: switching away from one profile must not refresh every
	-- other tab as the previous combined Disable() implementation did.
	if activeComponents.raid then
		self:DisableRaidMock()
	end
	if activeComponents.quick_join then
		self:DisableQuickJoinMock()
	end
	if activeComponents.raf then
		self:DisableRAFMock()
	end
	if activeComponents.requests then
		self:DisableInviteMock()
		local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
		if FriendsUI and FriendsUI.StopRequestGlow then
			FriendsUI:StopRequestGlow()
		end
		if FriendsUI and FriendsUI.RefreshRequests then
			FriendsUI:RefreshRequests(false)
		end
	end
	if activeComponents.recent_allies then
		local RecentAllies = BFL:GetModule("RecentAllies")
		local recentFrame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
		if RecentAllies and recentFrame and recentFrame:IsShown() then
			RecentAllies:Refresh(recentFrame, ScrollBoxConstants and ScrollBoxConstants.DiscardScrollPosition)
		end
	end
	if activeComponents.guild then
		self:RefreshGuildPreview()
	end

	-- Restore original BattleTag
	if activeComponents.battletag then
		self:RestoreBattleTag()
	end

	if activeComponents.friends then
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.UpdateFriendsList then
			FriendsList:UpdateFriendsList(true)
		end
	end

	self.activeProfile = nil
	self.activeComponents = {}
	self.activeSection = nil
	if activeComponents.raf then
		local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
		if FriendsUI and FriendsUI.RefreshNavigation then
			FriendsUI:RefreshNavigation()
		end
	end

	if not silent then
		PreviewMessage("|cff888888All preview data removed. Real friend data restored.|r")
	end
end

--[[
	Toggle Preview Mode
]]
function PreviewMode:Toggle()
	if self.enabled then
		self:Disable()
	else
		self:Enable()
	end
end

-- ============================================
-- MOCK DATA GENERATION
-- ============================================

function PreviewMode:GenerateMockFriends()
	self.mockData.friends = {}
	self.mockData.groupAssignments = {} -- Clean start for assignments
	self.mockData.friendNicknames = {
		["bnet_Anduin#1234"] = "Lionheart",
		["bnet_Jaina#5678"] = "Proudmoore",
		["wow_Nightwhisper-Blackrock"] = "Night",
	}
	local now = time and time() or 0
	self.mockData.recentlyAddedTimestamps = {
		["bnet_Anduin#1234"] = now - 1800,
		["bnet_Jaina#5678"] = now - (2 * 86400),
		["bnet_Thrall#9012"] = now - (14 * 86400),
	}
	self.mockData.contactMemory = {}
	self.mockFriendsRevision = self.mockFriendsRevision + 1
	local playerFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
	if playerFaction ~= "Alliance" and playerFaction ~= "Horde" then
		playerFaction = "Alliance"
	end
	local oppositeFaction = playerFaction == "Alliance" and "Horde" or "Alliance"

	-- Generate International Friends for Font Testing (KR, SC, TC, RU)
	local intFriends = {
		{
			name = "안녕하세요",
			tag = "안녕하세요#1111",
			groups = { "group_korea", "font_korean" },
			note = "한국어 폰트 테스트 (Korean)",
			zone = "서울 (Seoul)",
		},
		{
			name = "你好世界",
			tag = "你好世界#2222",
			groups = { "group_china", "font_simplified_chinese" },
			note = "中文备注测试 (Simp. Chinese)",
			zone = "奥格瑞玛 (Orgrimmar)",
		},
		{
			name = "哈囉世界",
			tag = "哈囉世界#3333",
			groups = { "group_china", "font_traditional_chinese" },
			note = "繁體中文備註 (Trad. Chinese)",
			zone = "暴風城 (Stormwind)",
		},
		{
			name = "Россия",
			tag = "Россия#4444",
			groups = { "group_russia", "font_russian" },
			note = "Проверка шрифтов (Russian)",
			zone = "Даларан (Dalaran)",
		},
		{
			name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
			tag = "LongName#9999",
			groups = { "favorites" },
			note = "This is a test entry for testing the font string resize behavior when resizing the frame width.",
			zone = "Stormwind City",
		},
	}

	for i, data in ipairs(intFriends) do
		local options = {
			battleTag = data.tag,
			accountName = data.name, -- Distinct account name
			characterName = data.name,
			game = { program = "WoW", name = "World of Warcraft" },
			note = data.note,
			zone = data.zone,
			isFavorite = false, -- Not favorites, per user request
			faction = (i % 2 == 0) and oppositeFaction or playerFaction,
		}
		local friend = GenerateMockBNetFriend(200 + i, true, options)
		table.insert(self.mockData.friends, friend)
		-- Derive the assignment key from the generated friend itself. Keeping a
		-- separately hand-written UID here allowed fixture IDs and assignments
		-- to drift apart when the multilingual preview groups were expanded.
		local uid = friend.battleTag and ("bnet_" .. friend.battleTag) or nil
		if uid then
			self.mockData.groupAssignments[uid] = data.groups
		end
	end

	-- Generate 8 online BNet friends with varied status
	local previewMaxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 90
	for i = 1, 8 do
		local options = {
			battleTag = MOCK_BATTLETAGS[i],
			-- Keep one opposite-faction WoW character and the mobile-only
			-- account in the first visible group so their settings can be
			-- verified immediately on PTR accounts without real friends.
			isFavorite = (i <= 3) or i == 6 or i == 8,
		}
		if i == 1 then
			options.level = previewMaxLevel
		elseif i == 6 then
			options.level = math.max(1, previewMaxLevel - 6)
		elseif i == 7 then
			options.level = math.max(1, previewMaxLevel - 3)
		end
		if i == 1 or i == 7 then
			options.faction = playerFaction
		elseif i == 6 then
			options.faction = oppositeFaction
		end

		-- Keep the leading fixtures deterministic and make the first visible
		-- group prove that Preview Mode renders distinct Blizzard games.
		if i == 1 or i == 6 or i == 7 then
			options.game = { program = "WoW", name = "World of Warcraft" }
		end

		-- Vary the remaining games for client-icon coverage. ANBS is the
		-- Battle.net client program used by Diablo IV on Retail 12.1.
		if i == 2 then
			options.game = { program = "ANBS", name = "Diablo IV", richPresence = "Greater Rift" }
		elseif i == 3 then
			options.game = { program = "WTCG", name = "Hearthstone", richPresence = "Ranked: In Game" }
		elseif i == 4 then
			options.game = { program = "Pro", name = "Overwatch 2", richPresence = "Competitive: In Game" }
		elseif i == 5 then
			options.game = { program = "S2", name = "StarCraft II", richPresence = "In Game" }
		elseif i == 6 then
			options.isDND = true
		elseif i == 7 then
			options.isAFK = true
		elseif i == 8 then
			options.game = { program = "BSAp", name = "Battle.net Mobile" }
			options.mobileOnly = true
		end

		local friend = GenerateMockBNetFriend(i, true, options)
		if i == 1 then
			friend.gameAccounts[#friend.gameAccounts + 1] = {
				gameAccountID = 2001,
				clientProgram = "ANBS",
				_previewTitleIcon = GetMockTitleIconTexture("ANBS"),
				isOnline = true,
				richPresence = "Diablo IV - Torment",
				characterName = "",
				className = "",
				classID = 0,
				classFilename = "",
				characterLevel = "",
				areaName = "",
				realmName = "",
				factionName = "",
				wowProjectID = 0,
			}
			friend.numGameAccounts = #friend.gameAccounts
		end
		table.insert(self.mockData.friends, friend)
	end

	-- Generate 8 offline BNet friends
	for i = 9, 16 do
		local options = {
			battleTag = MOCK_BATTLETAGS[(i % #MOCK_BATTLETAGS) + 1],
		}
		table.insert(self.mockData.friends, GenerateMockBNetFriend(i, false, options))
	end

	-- Generate 4 online WoW-only friends
	for i = 1, 4 do
		table.insert(
			self.mockData.friends,
			GenerateMockWoWFriend(i + 100, true, {
				name = MOCK_NAMES[i + 20],
				faction = (i % 2 == 0) and oppositeFaction or playerFaction,
			})
		)
	end

	-- Add explicit Long Name WoW Friend
	table.insert(
		self.mockData.friends,
		GenerateMockWoWFriend(150, true, {
			name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
			notes = "Testing WoW friend name truncation logic",
			faction = oppositeFaction,
		})
	)

	-- Generate 4 offline WoW-only friends
	for i = 5, 8 do
		table.insert(
			self.mockData.friends,
			GenerateMockWoWFriend(i + 100, false, {
				name = MOCK_NAMES[i + 24],
			})
		)
	end

	-- Add explicit Long Name WoW Friend (Offline)
	table.insert(
		self.mockData.friends,
		GenerateMockWoWFriend(151, false, {
			name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
			notes = "Testing Offline WoW friend name truncation logic",
		})
	)

	self:PrepareContactMemoryPreviewData()
end

function PreviewMode:PrepareContactMemoryPreviewData()
	self.mockData.contactMemory = {}
	local ContactMemory = BFL:GetModule("ContactMemory")
	if not (ContactMemory and ContactMemory.ResolveContactKeyFromFriend) then
		return
	end

	local now = time and time() or 0
	for _, friend in ipairs(self.mockData.friends) do
		local contactKey = ContactMemory:ResolveContactKeyFromFriend(friend)
		if contactKey then
			self.mockData.contactMemory[contactKey] = {
				tags = {},
				privateNote = friend.battleTag == "Anduin#1234"
						and "Preview-only private note for the Contact Memory setting."
					or nil,
				firstSeen = now - (30 * 86400),
				lastSeen = now,
				lastSeenSource = "preview",
			}
		end
	end
end

function PreviewMode:GenerateMockGroupsData(fixtureID)
	self.mockData.groups = GenerateMockGroups(fixtureID)

	-- Combine BNet and WoW group assignments
	-- NOTE: Do NOT wipe table here, as GenerateMockFriends may have added entries!
	-- self.mockData.groupAssignments = {}

	for k, v in pairs(MOCK_GROUP_ASSIGNMENTS) do
		self.mockData.groupAssignments[k] = v
	end
	for k, v in pairs(MOCK_WOW_GROUP_ASSIGNMENTS) do
		self.mockData.groupAssignments[k] = v
	end
end

function PreviewMode:GenerateGuildPreviewData()
	self.mockData.guildRosterName = "Midnight Vanguard"
	self.mockData.guildRosterMOTD = "Raid starts at 19:30 - bring flasks and good vibes."
	self.mockData.guildRosterMembers = {}
	self.mockData.guildNicknames = {
		["Hayato-Blackrock"] = "Raid Lead",
		["Yoshihiko-Blackrock"] = "Yoshi",
		["Valeera-Blackrock"] = "Shadow",
	}

	local samples = {
		{
			name = "Hayato",
			rank = "Guild Master",
			rankIndex = 0,
			classFile = "MONK",
			className = "Monk",
			zone = "Dornogal",
			online = true,
			note = "Raid lead",
			itemLevel = 713,
		},
		{
			name = "Yoshihiko",
			rank = "Officer",
			rankIndex = 1,
			classFile = "PALADIN",
			className = "Paladin",
			zone = "Silvermoon City",
			online = true,
			note = "Tank coordinator",
			itemLevel = 710,
		},
		{
			name = "Jaina",
			rank = "Officer",
			rankIndex = 1,
			classFile = "MAGE",
			className = "Mage",
			zone = "Hallowfall",
			online = true,
			isAFK = true,
			itemLevel = 708,
		},
		{
			name = "Thrall",
			rank = "Raider",
			rankIndex = 2,
			classFile = "SHAMAN",
			className = "Shaman",
			zone = "Orgrimmar",
			online = true,
			itemLevel = 706,
		},
		{
			name = "Anduin",
			rank = "Raider",
			rankIndex = 2,
			classFile = "PRIEST",
			className = "Priest",
			zone = "Dornogal",
			online = true,
			isDND = true,
			itemLevel = 705,
		},
		{
			name = "Alleria",
			rank = "Raider",
			rankIndex = 2,
			classFile = "HUNTER",
			className = "Hunter",
			zone = "Azj-Kahet",
			online = true,
			itemLevel = 704,
		},
		{
			name = "Baine",
			rank = "Raider",
			rankIndex = 2,
			classFile = "WARRIOR",
			className = "Warrior",
			zone = "Isle of Dorn",
			online = true,
			itemLevel = 703,
		},
		{
			name = "Malfurion",
			rank = "Raider",
			rankIndex = 2,
			classFile = "DRUID",
			className = "Druid",
			zone = "The Ringing Deeps",
			online = true,
			itemLevel = 702,
		},
		{
			name = "Valeera",
			rank = "Member",
			rankIndex = 3,
			classFile = "ROGUE",
			className = "Rogue",
			zone = "Undermine",
			online = true,
			itemLevel = 699,
		},
		{
			name = "Velen",
			rank = "Member",
			rankIndex = 3,
			classFile = "PRIEST",
			className = "Priest",
			zone = "Dornogal",
			online = true,
			isMobile = true,
			itemLevel = 697,
		},
		{
			name = "Khadgar",
			rank = "Member",
			rankIndex = 3,
			classFile = "MAGE",
			className = "Mage",
			zone = "Hallowfall",
			online = true,
			itemLevel = 695,
		},
		{
			name = "Arthas",
			rank = "Member",
			rankIndex = 3,
			classFile = "DEATHKNIGHT",
			className = "Death Knight",
			zone = "Icecrown",
			online = true,
			itemLevel = 693,
		},
		{
			name = "Illidan",
			rank = "Member",
			rankIndex = 3,
			classFile = "DEMONHUNTER",
			className = "Demon Hunter",
			online = false,
			lastOnlineHours = 3,
			itemLevel = 690,
		},
		{
			name = "Alexstrasza",
			rank = "Member",
			rankIndex = 3,
			classFile = "EVOKER",
			className = "Evoker",
			online = false,
			lastOnlineDays = 1,
			itemLevel = 688,
		},
		{
			name = "Sylvanas",
			rank = "Social",
			rankIndex = 4,
			classFile = "HUNTER",
			className = "Hunter",
			online = false,
			lastOnlineDays = 4,
			itemLevel = 680,
		},
		{
			name = "Genn",
			rank = "Social",
			rankIndex = 4,
			classFile = "WARRIOR",
			className = "Warrior",
			online = false,
			lastOnlineDays = 12,
			itemLevel = 675,
		},
		{
			name = "Tyrande",
			rank = "Social",
			rankIndex = 4,
			classFile = "PRIEST",
			className = "Priest",
			online = false,
			lastOnlineMonths = 1,
			itemLevel = 670,
		},
		{
			name = "Wrathion",
			rank = "Social",
			rankIndex = 4,
			classFile = "ROGUE",
			className = "Rogue",
			online = false,
			lastOnlineMonths = 3,
			itemLevel = 665,
		},
	}

	for index, sample in ipairs(samples) do
		local realm = sample.realm or "Blackrock"
		self.mockData.guildRosterMembers[index] = {
			index = index,
			guildIndex = index,
			fullName = sample.name .. "-" .. realm,
			name = sample.name,
			realm = realm,
			rank = sample.rank,
			rankIndex = sample.rankIndex,
			level = sample.level or 90,
			classFile = sample.classFile,
			className = sample.className,
			zone = sample.zone or "",
			note = sample.note or "",
			officerNote = sample.officerNote or "",
			online = sample.online == true,
			isAFK = sample.isAFK == true,
			isDND = sample.isDND == true,
			isMobile = sample.isMobile == true,
			achievementPoints = 12000 + index * 375,
			achievementRank = index,
			itemLevel = sample.itemLevel,
			guid = "BFLPreviewGuildMember-" .. index,
			lastOnlineYears = sample.lastOnlineYears or 0,
			lastOnlineMonths = sample.lastOnlineMonths or 0,
			lastOnlineDays = sample.lastOnlineDays or 0,
			lastOnlineHours = sample.lastOnlineHours or 0,
			_isMock = true,
		}
	end
end

function PreviewMode:RefreshGuildPreview()
	local provider = BFL:GetModule("GuildRosterData")
	if provider and provider.InvalidateCache then
		provider:InvalidateCache()
	end

	local GuildFrame = BFL:GetModule("GuildFrame")
	if GuildFrame and GuildFrame.OnGuildRosterUpdate then
		GuildFrame:OnGuildRosterUpdate(false)
	elseif GuildFrame and GuildFrame.Refresh then
		GuildFrame:Refresh()
	end
end

function PreviewMode:GenerateBrokerPreviewData()
	self.mockData.brokerFriends = {}
	self.mockData.guildMembers = {}
	self.mockData.friendNicknames = self.mockData.friendNicknames or {}
	self.mockData.guildNicknames = self.mockData.guildNicknames or {}
	self.mockData.guildName = "Font Preview - 한글 / 简体 / 繁體 / Русский"

	-- WoW font families with non-latin alphabet support:
	-- korean, simplifiedchinese, traditionalchinese, russian.
	local fontSamples = {
		{
			alphabet = "Korean",
			group = "font_korean",
			accountName = "한글친구",
			characterName = "한글수호자",
			battleTagSuffix = "1111",
			zone = "도르노갈",
			rank = "레이드원",
			note = "한국어 폰트 테스트",
			className = "Monk",
			classFile = "MONK",
			classID = 10,
			level = 80,
			factionName = "Alliance",
		},
		{
			alphabet = "Simplified Chinese",
			group = "font_simplified_chinese",
			accountName = "简体好友",
			characterName = "简体法师",
			battleTagSuffix = "2222",
			zone = "奥格瑞玛",
			rank = "测试成员",
			note = "简体中文字体测试",
			className = "Mage",
			classFile = "MAGE",
			classID = 8,
			level = 79,
			factionName = "Horde",
		},
		{
			alphabet = "Traditional Chinese",
			group = "font_traditional_chinese",
			accountName = "繁體好友",
			characterName = "繁體牧師",
			battleTagSuffix = "3333",
			zone = "暴風城",
			rank = "測試成員",
			note = "繁體中文字體測試",
			className = "Priest",
			classFile = "PRIEST",
			classID = 5,
			level = 78,
			factionName = "Alliance",
		},
		{
			alphabet = "Russian",
			group = "font_russian",
			accountName = "РусскийДруг",
			characterName = "РусскийТанк",
			battleTagSuffix = "4444",
			zone = "Даларан",
			rank = "Участник",
			note = "Проверка шрифтов",
			className = "Warrior",
			classFile = "WARRIOR",
			classID = 1,
			level = 77,
			factionName = "Horde",
		},
	}
	fontSamples[1].level = BFL.GetMaxLevel and BFL.GetMaxLevel() or 90

	for i, sample in ipairs(fontSamples) do
		local battleTag = sample.accountName .. "#" .. sample.battleTagSuffix
		local bnetId = "bnet_" .. battleTag
		local wowId = "wow_" .. sample.characterName .. "-Blackrock"
		local guildFullName = sample.characterName .. "-Blackrock"
		local gameAccountID = 9000 + i
		self.mockData.friendNicknames[bnetId] = sample.alphabet .. " Friend"
		self.mockData.friendNicknames[wowId] = sample.alphabet .. " Alt"
		self.mockData.guildNicknames[guildFullName] = sample.alphabet .. " Guildmate"

		local gameInfo = {
			isOnline = true,
			gameAccountID = gameAccountID,
			clientProgram = "WoW",
			_previewTitleIcon = GetMockTitleIconTexture("WoW"),
			gameName = "World of Warcraft",
			characterName = sample.characterName,
			className = sample.className,
			classID = sample.classID,
			classFilename = sample.classFile,
			characterLevel = sample.level,
			areaName = sample.zone,
			realmName = "Blackrock",
			factionName = sample.factionName,
			guildName = self.mockData.guildName,
			wowProjectID = WOW_PROJECT_ID or 1,
		}

		table.insert(self.mockData.brokerFriends, {
			type = "bnet",
			index = 300 + i,
			id = bnetId,
			bnetAccountID = 900000 + i,
			accountName = sample.accountName,
			battleTag = battleTag,
			connected = true,
			note = sample.note .. " (" .. sample.alphabet .. ")",
			isFavorite = false,
			friendLevel = (i % 3) + 1,
			friendTags = { i - 1, i + 2 },
			client = "WoW",
			_previewTitleIcon = GetMockTitleIconTexture("WoW"),
			isMobile = false,
			gameAccountID = gameAccountID,
			gameAccountInfo = gameInfo,
			wowProjectID = WOW_PROJECT_ID or 1,
			characterName = sample.characterName,
			className = sample.className,
			classID = sample.classID,
			classFilename = sample.classFile,
			level = sample.level,
			area = sample.zone,
			realmName = "Blackrock",
			factionName = sample.factionName,
			guildName = self.mockData.guildName,
			_isMock = true,
		})
		self.mockData.groupAssignments[bnetId] = { sample.group }

		table.insert(self.mockData.brokerFriends, {
			type = "wow",
			index = 400 + i,
			id = wowId,
			accountName = sample.characterName,
			characterName = sample.characterName,
			fullName = sample.characterName .. "-Blackrock",
			name = sample.characterName .. "-Blackrock",
			connected = true,
			client = "WoW",
			note = sample.note,
			level = sample.level,
			className = sample.className,
			classID = sample.classID,
			area = sample.zone,
			realmName = "Blackrock",
			factionName = sample.factionName,
			guildName = self.mockData.guildName,
			_isMock = true,
		})
		self.mockData.groupAssignments[wowId] = { sample.group }

		table.insert(self.mockData.guildMembers, {
			index = i,
			fullName = sample.characterName .. "-Blackrock",
			name = sample.characterName,
			realm = "Blackrock",
			professions = "",
			rank = sample.rank,
			rankIndex = i,
			level = sample.level,
			classFile = sample.classFile,
			className = sample.className,
			zone = sample.zone,
			note = sample.note,
			officerNote = sample.note .. " (" .. sample.alphabet .. ")",
			online = true,
			isAFK = false,
			isDND = false,
			isMobile = false,
			lastOnlineYears = 0,
			lastOnlineMonths = 0,
			lastOnlineDays = 0,
			lastOnlineHours = 0,
		})
	end

	table.insert(self.mockData.brokerFriends, {
		type = "bnet",
		index = 399,
		id = "bnet_LatinControl#5555",
		bnetAccountID = 900005,
		accountName = "LatinControl",
		battleTag = "LatinControl#5555",
		connected = true,
		note = "Latin baseline row for comparison",
		isFavorite = false,
		friendLevel = 2,
		friendTags = { 2, 3, 8 },
		client = "WoW",
		_previewTitleIcon = GetMockTitleIconTexture("WoW"),
		gameAccountID = 9005,
		gameAccountInfo = {
			isOnline = true,
			gameAccountID = 9005,
			clientProgram = "WoW",
			_previewTitleIcon = GetMockTitleIconTexture("WoW"),
			gameName = "World of Warcraft",
			characterName = "Latincontrol",
			className = "Paladin",
			classID = 2,
			classFilename = "PALADIN",
			characterLevel = 80,
			areaName = "Stormwind City",
			realmName = "Blackrock",
			factionName = "Alliance",
			guildName = self.mockData.guildName,
			wowProjectID = WOW_PROJECT_ID or 1,
		},
		wowProjectID = WOW_PROJECT_ID or 1,
		characterName = "Latincontrol",
		className = "Paladin",
		classID = 2,
		classFilename = "PALADIN",
		level = 80,
		area = "Stormwind City",
		realmName = "Blackrock",
		factionName = "Alliance",
		guildName = self.mockData.guildName,
		_isMock = true,
	})
	self.mockData.groupAssignments["bnet_LatinControl#5555"] = { "raid_team" }
	self.mockData.friendNicknames["bnet_LatinControl#5555"] = "Latin Nickname"
	self.mockData.guildNicknames["Latincontrol-Blackrock"] = "Latin Guildmate"

	table.insert(self.mockData.guildMembers, {
		index = 99,
		fullName = "Latincontrol-Blackrock",
		name = "Latincontrol",
		realm = "Blackrock",
		professions = "",
		rank = "Officer",
		rankIndex = 0,
		level = 80,
		classFile = "PALADIN",
		className = "Paladin",
		zone = "Stormwind City",
		note = "Latin baseline row for comparison",
		officerNote = "",
		online = true,
		isAFK = false,
		isDND = false,
		isMobile = false,
		lastOnlineYears = 0,
		lastOnlineMonths = 0,
		lastOnlineDays = 0,
		lastOnlineHours = 0,
	})
end

-- ============================================
-- MOCK DATA APPLICATION
-- ============================================

--[[
	Apply mock friends to the FriendsList module
	This injects mock data into the friends display
]]
function PreviewMode:ApplyMockFriendSettingState(FriendsList)
	if not FriendsList then
		return false
	end

	local settings = FriendsList.settingsCache or {}
	local treatMobileAsOffline = settings.treatMobileAsOffline == true
	local changed = false
	for _, friend in ipairs(self.mockData.friends or {}) do
		if friend._isMock and friend._previewBaseConnected ~= nil then
			local connected = friend._previewBaseConnected == true
			if treatMobileAsOffline and friend._previewMobileOnly and connected then
				connected = false
				friend.isMobileButTreatedOffline = true
			else
				friend.isMobileButTreatedOffline = nil
			end
			if friend.connected ~= connected then
				friend.connected = connected
				changed = true
			end
		end
	end
	if changed then
		self.mockFriendsRevision = self.mockFriendsRevision + 1
	end
	return changed
end

function PreviewMode:PrepareMockFriendsRender(FriendsList)
	if not FriendsList then
		return false
	end

	-- The Preview override below replaces FriendsList:UpdateFriendsList(), whose
	-- native entry path refreshes this cache before it reads any visual setting.
	-- Keep that contract here as well; otherwise SettingsVersion invalidates the
	-- cache, Preview renders again, but still consumes the previous values.
	local currentSettingsVersion = BFL.SettingsVersion or 1
	local settingsChanged = FriendsList.settingsCacheVersion ~= currentSettingsVersion
	if settingsChanged and FriendsList.UpdateFontCache then
		-- BFL:ForceRefreshFriendsList() normally performs this part. The central
		-- Preview settings refresh can also enter directly, so make font/layout
		-- changes deterministic for both Settings Center and Legacy controls.
		FriendsList:UpdateFontCache()
	end
	if FriendsList.UpdateSettingsCache then
		FriendsList:UpdateSettingsCache()
	end
	local mockStateChanged = self:ApplyMockFriendSettingState(FriendsList)
	return settingsChanged or mockStateChanged
end

MOCK_FRIEND_APPLICATION_PHASES = {
	"persist",
	"hook",
	"groups",
	"group_order",
	"assignments",
	"cache",
}

function PreviewMode:ApplyMockFriendsPhase(phase, includeGroups)
	if phase == "persist" then
		if includeGroups then
			self:PersistOriginalState()
		end
		return
	end

	local FriendsList = BFL:GetModule("FriendsList")
	if phase == "hook" then
		if not FriendsList then
			return
		end
		if not self.originalUpdateFriendsList then
			self.originalUpdateFriendsList = FriendsList.UpdateFriendsList
		end

		-- Override UpdateFriendsList to inject mock data. During a traced slash
		-- activation the actual render is held back and executed as individual
		-- phases, so frame events cannot jump ahead of the diagnostic marker.
		FriendsList.UpdateFriendsList = function(self, ignoreVisibility)
			if PreviewMode:IsComponentEnabled("friends") and #PreviewMode.mockData.friends > 0 then
				if PreviewMode.activationRenderGate then
					if self.MarkNeedsRenderOnShow then
						self:MarkNeedsRenderOnShow()
					end
					return
				end
				if (not BetterFriendsFrame or not BetterFriendsFrame:IsShown()) and not ignoreVisibility then
					if self.MarkNeedsRenderOnShow then
						self:MarkNeedsRenderOnShow()
					end
					return
				end
				PreviewMode:PrepareMockFriendsRender(self)
				if not PreviewMode:ShouldRenderMockFriends(self) then
					return
				end

				wipe(self.friendsList)
				for _, friend in ipairs(PreviewMode.mockData.friends) do
					table.insert(self.friendsList, friend)
				end
				self:ApplyFilters()
				self:ApplySort()
				self:RenderDisplay(ignoreVisibility)
			elseif PreviewMode.originalUpdateFriendsList then
				PreviewMode.originalUpdateFriendsList(self, ignoreVisibility)
			end
		end
		return
	end

	if phase == "groups" then
		local Groups = BFL:GetModule("Groups")
		if includeGroups and Groups then
			if not self.originalGroups then
				self.originalGroups = {}
				for id, data in pairs(Groups.groups) do
					self.originalGroups[id] = data
				end
			end
			wipe(Groups.groups)
			for _, mockGroup in ipairs(self.mockData.groups) do
				Groups.groups[mockGroup.id] = mockGroup
			end
		end
		return
	end

	if phase == "group_order" then
		if includeGroups and BetterFriendlistDB then
			if not self.originalGroupOrder then
				self.originalGroupOrder = BetterFriendlistDB.groupOrder
			end

			local mockOrder = {}
			local sortedMockGroups = {}
			for _, group in ipairs(self.mockData.groups) do
				table.insert(sortedMockGroups, group)
			end
			table.sort(sortedMockGroups, function(a, b)
				return (a.order or 999) < (b.order or 999)
			end)
			for _, group in ipairs(sortedMockGroups) do
				table.insert(mockOrder, group.id)
			end
			BetterFriendlistDB.groupOrder = mockOrder
		end
		return
	end

	if phase == "assignments" then
		if includeGroups and BetterFriendlistDB then
			if not self.originalFriendGroups then
				self.originalFriendGroups = {}
				if BetterFriendlistDB.friendGroups then
					for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
						self.originalFriendGroups[uid] = groups
					end
				end
			end
			if not BetterFriendlistDB.friendGroups then
				BetterFriendlistDB.friendGroups = {}
			end
			for uid, groups in pairs(self.mockData.groupAssignments) do
				BetterFriendlistDB.friendGroups[uid] = groups
			end
		end
		return
	end

	if phase == "cache" then
		if BFL.SettingsVersion then
			BFL.SettingsVersion = BFL.SettingsVersion + 1
		end
		if FriendsList then
			if FriendsList.InvalidateSettingsCache then
				FriendsList:InvalidateSettingsCache()
			end
			FriendsList.lastBuildInputs = nil
		end
	end
end

function PreviewMode:ApplyMockFriends(options)
	options = options or {}
	local includeGroups = options.includeGroups ~= false
	for _, phase in ipairs(MOCK_FRIEND_APPLICATION_PHASES) do
		self:ApplyMockFriendsPhase(phase, includeGroups)
	end
end

function PreviewMode:PersistOriginalState()
	if not BetterFriendlistDB then
		return
	end
	if not BetterFriendlistDB.previewBackup then
		BetterFriendlistDB.previewBackup = {
			groupOrder = CopyArray(BetterFriendlistDB.groupOrder),
			friendGroups = CopyFriendGroups(BetterFriendlistDB.friendGroups),
		}
	end
end

function PreviewMode:RestorePersistedState()
	if not BetterFriendlistDB then
		return
	end
	local backup = BetterFriendlistDB.previewBackup
	if not backup then
		return
	end

	if backup.groupOrder == nil then
		BetterFriendlistDB.groupOrder = nil
	else
		BetterFriendlistDB.groupOrder = CopyArray(backup.groupOrder)
	end

	if backup.friendGroups == nil then
		BetterFriendlistDB.friendGroups = nil
	else
		BetterFriendlistDB.friendGroups = CopyFriendGroups(backup.friendGroups)
	end

	BetterFriendlistDB.previewBackup = nil
end

-- ============================================
-- EXISTING MOCK SYSTEM INTEGRATION
-- ============================================

function PreviewMode:EnableRaidMock(options)
	options = options or {}
	local RaidFrame = BFL:GetModule("RaidFrame")
	if not RaidFrame then
		return
	end

	-- Store original UpdateRaidMembers function BEFORE activating mock
	-- This is critical to prevent mock data from being wiped!
	if not self.originalUpdateRaidMembers then
		self.originalUpdateRaidMembers = RaidFrame.UpdateRaidMembers
	end

	-- Store original OnGroupLeft function to prevent mock data from being wiped
	if not self.originalOnGroupLeft then
		self.originalOnGroupLeft = RaidFrame.OnGroupLeft
	end

	-- Store original OnGroupJoined function
	if not self.originalOnGroupJoined then
		self.originalOnGroupJoined = RaidFrame.OnGroupJoined
	end

	-- Store original OnRaidRosterUpdate function
	if not self.originalOnRaidRosterUpdate then
		self.originalOnRaidRosterUpdate = RaidFrame.OnRaidRosterUpdate
	end

	-- Override UpdateRaidMembers to preserve mock data when mockEnabled is true
	RaidFrame.UpdateRaidMembers = function(raidSelf)
		-- If mock mode is active, don't touch the raidMembers data at all
		if raidSelf.mockEnabled then
			-- Mock data already in raidMembers - do nothing
			-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Skipping UpdateRaidMembers (mock mode active)")
			return
		end

		-- Not in mock mode - use original function
		if PreviewMode.originalUpdateRaidMembers then
			PreviewMode.originalUpdateRaidMembers(raidSelf)
		end
	end

	-- Override OnGroupLeft to preserve mock data when mockEnabled is true
	RaidFrame.OnGroupLeft = function(raidSelf, ...)
		if raidSelf.mockEnabled then
			-- Mock mode active - do not clear data
			-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Skipping OnGroupLeft (mock mode active)")
			return
		end

		-- Not in mock mode - use original function
		if PreviewMode.originalOnGroupLeft then
			PreviewMode.originalOnGroupLeft(raidSelf, ...)
		end
	end

	-- Override OnGroupJoined to preserve mock data when mockEnabled is true
	RaidFrame.OnGroupJoined = function(raidSelf, ...)
		if raidSelf.mockEnabled then
			-- Mock mode active - do not update from real group
			-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Skipping OnGroupJoined (mock mode active)")
			return
		end

		-- Not in mock mode - use original function
		if PreviewMode.originalOnGroupJoined then
			PreviewMode.originalOnGroupJoined(raidSelf, ...)
		end
	end

	-- Override OnRaidRosterUpdate to preserve mock data when mockEnabled is true
	RaidFrame.OnRaidRosterUpdate = function(raidSelf, ...)
		if raidSelf.mockEnabled then
			-- Mock mode active - do not update from real roster
			-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Skipping OnRaidRosterUpdate (mock mode active)")
			return
		end

		-- Not in mock mode - use original function
		if PreviewMode.originalOnRaidRosterUpdate then
			PreviewMode.originalOnRaidRosterUpdate(raidSelf, ...)
		end
	end

	-- Staged slash-command activation generates and renders the preset in
	-- separate timer frames after this guard-only phase.
	if not options.deferPreset and RaidFrame.CreateMockPreset_Standard then
		RaidFrame:CreateMockPreset_Standard()
		-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Raid mock enabled with event overrides")
	end
end

function PreviewMode:DisableRaidMock()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if not RaidFrame then
		return
	end

	-- Restore original UpdateRaidMembers function
	if self.originalUpdateRaidMembers then
		RaidFrame.UpdateRaidMembers = self.originalUpdateRaidMembers
		self.originalUpdateRaidMembers = nil
	end

	-- Restore original OnGroupLeft function
	if self.originalOnGroupLeft then
		RaidFrame.OnGroupLeft = self.originalOnGroupLeft
		self.originalOnGroupLeft = nil
	end

	-- Restore original OnGroupJoined function
	if self.originalOnGroupJoined then
		RaidFrame.OnGroupJoined = self.originalOnGroupJoined
		self.originalOnGroupJoined = nil
	end

	-- Restore original OnRaidRosterUpdate function
	if self.originalOnRaidRosterUpdate then
		RaidFrame.OnRaidRosterUpdate = self.originalOnRaidRosterUpdate
		self.originalOnRaidRosterUpdate = nil
	end

	-- Clear mock data
	if RaidFrame.ClearMockData then
		RaidFrame:ClearMockData()
	end
end

function PreviewMode:GenerateRecentAlliesPreviewData()
	local now = GetServerTime and GetServerTime() or time()
	local allies = {
		{ name = "Aegwynn", classID = 8, raceID = 1, level = 80, online = true, location = "Dornogal", interaction = "Mythic+ — Priory of the Sacred Flame", pinnedDays = 20 },
		{ name = "Valeera", classID = 4, raceID = 10, level = 80, online = true, location = "Silvermoon City", interaction = "Delve — Underkeep", pending = true },
		{ name = "Baine", classID = 1, raceID = 6, level = 80, online = false, location = "Thunder Bluff", interaction = "Raid — Liberation of Undermine" },
		{ name = "Tyrande", classID = 3, raceID = 4, level = 80, online = true, location = "Bel'ameth", interaction = "Questing — Isle of Dorn", afk = true },
		{ name = "Khadgar", classID = 8, raceID = 1, level = 80, online = true, location = "Dalaran", interaction = "Party — Timewalking", dnd = true },
	}
	self.mockData.recentAllies = {}
	for index, fixture in ipairs(allies) do
		self.mockData.recentAllies[index] = {
			characterData = {
				name = fixture.name,
				fullName = fixture.name .. "-Blackrock",
				realmName = "Blackrock",
				guid = string.format("Player-Preview-%04d", index),
				level = fixture.level,
				classID = fixture.classID,
				raceID = fixture.raceID,
			},
			stateData = {
				isOnline = fixture.online,
				isAFK = fixture.afk == true,
				isDND = fixture.dnd == true,
				currentLocation = fixture.location,
				pinExpirationDate = fixture.pinnedDays and (now + fixture.pinnedDays * 86400) or nil,
				friendRequestSentThisSession = fixture.pending == true,
			},
			interactionData = {
				note = "",
				interactions = {
					{
						timestamp = now - index * 3600,
						description = fixture.interaction,
						type = 0,
						contextData = {},
					},
				},
			},
			_isMock = true,
		}
	end
end

local function GetFriendTagVersions()
	local FriendTags = BFL:GetModule("FriendTags")
	local definitionVersion = FriendTags
		and FriendTags.GetDefinitionVersion
		and FriendTags:GetDefinitionVersion()
		or BFL.FriendTagsVersion
		or 0
	local assignmentVersion = FriendTags
		and FriendTags.GetAssignmentVersion
		and FriendTags:GetAssignmentVersion()
		or 0
	return definitionVersion, assignmentVersion
end

function PreviewMode:ShouldRenderMockFriends(FriendsList)
	if not FriendsList then
		return false
	end

	local state = self.mockFriendsRenderState
	if not state then
		state = { groupOrder = {}, groupCollapsed = {} }
		self.mockFriendsRenderState = state
	end

	local definitionVersion, assignmentVersion = GetFriendTagVersions()
	local invites = BFL.MockFriendInvites and BFL.MockFriendInvites.invites
	local frameWidth = BetterFriendsFrame and BetterFriendsFrame:GetWidth() or 0
	local frameHeight = BetterFriendsFrame and BetterFriendsFrame:GetHeight() or 0
	local changed = FriendsList.forceLayoutRebuild == true
		or state.revision ~= self.mockFriendsRevision
		or state.settingsVersion ~= (BFL.SettingsVersion or 0)
		or state.registryVersion ~= (BFL.FilterSortRegistryVersion or 0)
		or state.definitionVersion ~= definitionVersion
		or state.assignmentVersion ~= assignmentVersion
		or state.filterMode ~= FriendsList.filterMode
		or state.searchText ~= FriendsList.searchText
		or state.sortMode ~= FriendsList.sortMode
		or state.secondarySort ~= FriendsList.secondarySort
		or state.inviteCount ~= (invites and #invites or 0)
		or state.invitesCollapsed ~= (GetCVarBool("friendInvitesCollapsed") == true)
		or state.frameWidth ~= frameWidth
		or state.frameHeight ~= frameHeight

	local groupOrder = BetterFriendlistDB and BetterFriendlistDB.groupOrder or nil
	local cachedOrder = state.groupOrder
	local groupOrderCount = groupOrder and #groupOrder or 0
	if #cachedOrder ~= groupOrderCount then
		changed = true
	end
	for index = 1, groupOrderCount do
		if cachedOrder[index] ~= groupOrder[index] then
			changed = true
		end
		cachedOrder[index] = groupOrder[index]
	end
	for index = groupOrderCount + 1, #cachedOrder do
		cachedOrder[index] = nil
	end

	local Groups = BFL:GetModule("Groups")
	local cachedCollapsed = state.groupCollapsed
	local seenGroups = state.seenGroups or {}
	state.seenGroups = seenGroups
	wipe(seenGroups)
	if Groups and Groups.groups then
		for groupID, group in pairs(Groups.groups) do
			local collapsed = group and group.collapsed == true
			seenGroups[groupID] = true
			if cachedCollapsed[groupID] ~= collapsed then
				changed = true
				cachedCollapsed[groupID] = collapsed
			end
		end
	end
	for groupID in pairs(cachedCollapsed) do
		if not seenGroups[groupID] then
			cachedCollapsed[groupID] = nil
			changed = true
		end
	end

	if not changed then
		return false
	end

	state.revision = self.mockFriendsRevision
	state.settingsVersion = BFL.SettingsVersion or 0
	state.registryVersion = BFL.FilterSortRegistryVersion or 0
	state.definitionVersion = definitionVersion
	state.assignmentVersion = assignmentVersion
	state.filterMode = FriendsList.filterMode
	state.searchText = FriendsList.searchText
	state.sortMode = FriendsList.sortMode
	state.secondarySort = FriendsList.secondarySort
	state.inviteCount = invites and #invites or 0
	state.invitesCollapsed = GetCVarBool("friendInvitesCollapsed") == true
	state.frameWidth = frameWidth
	state.frameHeight = frameHeight
	return true
end

function PreviewMode:EnableQuickJoinMock()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.CreateMockPreset_Preview then
		QuickJoin:CreateMockPreset_Preview()
	elseif QuickJoin and QuickJoin.CreateMockPreset_12_1 then
		QuickJoin:CreateMockPreset_12_1()
	elseif QuickJoin and QuickJoin.CreateMockPreset_All then
		QuickJoin:CreateMockPreset_All()
	end
end

function PreviewMode:ShowQuickJoinPreview()
	if BFL.IsClassic or not BFL.HasQuickJoin then
		PreviewMessage("|cffff8800BetterFriendlist:|r Quick Join preview is only available on Retail clients.")
		return
	end

	if _G.ShowBetterFriendsFrame then
		_G.ShowBetterFriendsFrame(4)
	elseif _G.ToggleBetterFriendsFrame then
		_G.ToggleBetterFriendsFrame(4)
	end

	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.Update then
		QuickJoin:Update(true)
	end

	PreviewMessage("|cff888888Hover the Quick Join preview cards to compare class rows and the count fallback.|r")
end

function PreviewMode:DisableQuickJoinMock()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.ClearMockGroups then
		QuickJoin:ClearMockGroups()
	end
end

function PreviewMode:EnableRAFMock()
	local RAF = BFL:GetModule("RAF")
	local rafFrame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
	if RAF and rafFrame and RAF.EnablePreview then
		return RAF:EnablePreview(rafFrame)
	end
	return false
end

function PreviewMode:DisableRAFMock()
	local RAF = BFL:GetModule("RAF")
	local rafFrame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
	if RAF and RAF.DisablePreview then
		RAF:DisablePreview(rafFrame)
	end
end

function PreviewMode:EnableInviteMock()
	-- Use existing mock invite system
	BFL.MockFriendInvites.enabled = true
	local levels = Enum and Enum.BattleNetFriendLevel
	BFL.MockFriendInvites.invites = {
		{
			inviteID = 1000001,
			accountName = "NewFriend#1234",
			friendLevel = levels and levels.BattleTag or 1,
			creationTimestamp = time() - 180,
		},
		{
			inviteID = 1000002,
			accountName = "GuildRecruit#5678",
			friendLevel = levels and levels.RealID or 2,
			creationTimestamp = time() - 3600,
		},
		{
			inviteID = 1000003,
			accountName = "WarcraftFriend",
			friendLevel = levels and levels.Title or 3,
			creationTimestamp = time() - 7200,
		},
	}
end

function PreviewMode:DisableInviteMock()
	BFL.MockFriendInvites.enabled = false
	BFL.MockFriendInvites.invites = {}
end

-- ============================================
-- BROKER TOOLTIP PREVIEW DATA
-- ============================================

function PreviewMode:ApplyBrokerPreviewData()
	if not self:IsComponentEnabled("broker") then
		return
	end
	if #self.mockData.brokerFriends == 0 or #self.mockData.guildMembers == 0 then
		self:GenerateBrokerPreviewData()
	end

	local Broker = BFL:GetModule("Broker")
	local GuildBroker = BFL:GetModule("GuildBroker")

	if Broker and Broker.SetPreviewData then
		Broker:SetPreviewData({
			friends = self.mockData.brokerFriends,
		})
		if Broker.RefreshTooltip then
			Broker:RefreshTooltip()
		end
	end

	if GuildBroker and GuildBroker.SetPreviewData then
		GuildBroker:SetPreviewData({
			guildName = self.mockData.guildName,
			members = self.mockData.guildMembers,
		})
		if GuildBroker.RefreshTooltip then
			GuildBroker:RefreshTooltip()
		end
	end
end

function PreviewMode:ClearBrokerPreviewData()
	local Broker = BFL:GetModule("Broker")
	if Broker then
		if Broker.SetPreviewData then
			Broker:SetPreviewData(nil)
		end
		if Broker.RefreshTooltip then
			Broker:RefreshTooltip()
		end
	end

	local GuildBroker = BFL:GetModule("GuildBroker")
	if GuildBroker then
		if GuildBroker.SetPreviewData then
			GuildBroker:SetPreviewData(nil)
		end
		if GuildBroker.RefreshTooltip then
			GuildBroker:RefreshTooltip()
		end
	end
end

-- ============================================
-- UI REFRESH
-- ============================================

-- Legacy scenario/test helper. Isolation profiles deliberately never call this
-- broad refresh because it touches Friends, Quick Join, and Raid together.
function PreviewMode:RefreshAllUI()
	-- Refresh friends list
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.UpdateFriendsList then
		FriendsList:UpdateFriendsList()
	end

	-- Refresh Quick Join
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.Update then
		QuickJoin:Update(true)
	end

	-- Refresh Raid Frame - use specific update functions since there's no generic Update()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if RaidFrame then
		-- Rebuild display list from raidMembers data
		if RaidFrame.BuildDisplayList then
			RaidFrame:BuildDisplayList()
		end
		-- Update all member buttons with the display data
		if RaidFrame.UpdateAllMemberButtons then
			RaidFrame:UpdateAllMemberButtons()
		end
		-- Update control panel (role counts, etc.)
		if RaidFrame.mockEnabled and RaidFrame.UpdateMockControlPanel then
			RaidFrame:UpdateMockControlPanel()
		elseif RaidFrame.UpdateControlPanel then
			RaidFrame:UpdateControlPanel()
		end
	end

	self:RefreshGuildPreview()

	-- Force frame show if needed
	if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
		if _G.ToggleBetterFriendsFrame then
			_G.ToggleBetterFriendsFrame()
		end
	end
end

-- ============================================
-- MODULE INITIALIZATION
-- ============================================

function PreviewMode:Initialize()
	self:RestorePersistedState()

	-- Module is ready
	-- BFL:DebugPrint("|cff00ffffBFL:PreviewMode:|r Initialized")
end

-- ============================================
-- SLASH COMMAND HANDLER (Called from Core.lua)
-- ============================================

function PreviewMode:HandleLegacyCommand(args)
	return self:HandleCommand(args)
end

function PreviewMode:PrintStatus()
	if not self.enabled then
		PreviewMessage("|cff00ff00BetterFriendlist:|r Preview mode is |cffff0000DISABLED|r")
		return
	end

	PreviewMessage(
		"|cff00ff00BetterFriendlist:|r Preview profile: |cffffd700"
			.. tostring(self.activeProfile or "legacy_combined")
			.. "|r"
	)
	if self.activeSection then
		PreviewMessage("  |cffffffffSection: " .. self.activeSection .. "|r")
	end
	if self.activationInProgress and self.activationTrace then
		local trace = self.activationTrace
		local step = trace.steps and trace.steps[trace.index]
		PreviewMessage(
			string.format(
				"  |cffffd700Boot: step %d/%d%s|r",
				trace.index or 0,
				trace.steps and #trace.steps or 0,
				step and (" [" .. step.id .. "]") or ""
			)
		)
	end
	local components = {}
	for component, enabled in pairs(self.activeComponents or {}) do
		if enabled then
			components[#components + 1] = component
		end
	end
	table.sort(components)
	PreviewMessage("  |cffffffffComponents: " .. (#components > 0 and table.concat(components, ", ") or "tab shell only") .. "|r")
	PreviewMessage("  |cffffffffFriends: " .. #self.mockData.friends .. ", groups: " .. #self.mockData.groups .. "|r")
	PreviewMessage(
		"  |cffffffffBroker friends: "
			.. #self.mockData.brokerFriends
			.. ", guild rows: "
			.. #self.mockData.guildMembers
			.. "|r"
	)
	PreviewMessage("  |cffffffffGuild roster rows: " .. #self.mockData.guildRosterMembers .. "|r")
end

function PreviewMode:PrintIsolationHelp()
	PreviewMessage("|cff00ff00BFL Preview Isolation:|r")
	PreviewMessage("  |cffffcc00/bfl preview friends-plain|r - Friend cards without tags or custom groups")
	PreviewMessage("  |cffffcc00/bfl preview friends-tags|r - Friend cards with tags, without custom groups")
	PreviewMessage("  |cffffcc00/bfl preview friends-header-one|r - One ASCII custom header plus built-in groups")
	PreviewMessage("  |cffffcc00/bfl preview friends-headers|r - Full header count with ASCII-only names")
	PreviewMessage("  |cffffcc00/bfl preview friends-headers-latin|r - Extended Latin headers using custom fonts")
	PreviewMessage("  |cffffcc00/bfl preview friends-headers-i18n|r - Full multilingual header reproducer")
	PreviewMessage("  |cffffcc00/bfl preview friends-groups|r - Custom groups and assignments without tags")
	PreviewMessage("  |cffffcc00/bfl preview friends|r - Complete Friends tab with groups and tags")
	PreviewMessage("  |cffffcc00/bfl preview recent|r - Recent Allies tab only")
	PreviewMessage("  |cffffcc00/bfl preview quickjoin|r - Quick Join fixture only")
	PreviewMessage("  |cffffcc00/bfl preview requests|r - Friend Requests fixture only")
	PreviewMessage("  |cffffcc00/bfl preview raf|r - Recruit a Friend tab only")
	PreviewMessage("  |cffffcc00/bfl preview raid|r - Raid fixture only")
	PreviewMessage("  |cffffcc00/bfl preview guild|r - Guild tab only")
	PreviewMessage("  |cffffcc00/bfl preview broker|r - Broker fixtures only")
	PreviewMessage("  |cffffcc00/bfl preview battletag|r - Header masking only")
	PreviewMessage("  |cffffcc00/bfl preview all|r - Explicit combined legacy fixture")
	PreviewMessage("  |cffffcc00/bfl preview debug|r - Trace the combined activation step by step")
	PreviewMessage("  |cffffcc00/bfl preview off|r - Restore the touched profile")
	PreviewMessage("  |cffffcc00/bfl preview status|r - Show the active isolation profile")
	PreviewMessage("  |cffffcc00/bfl preview icons|r - Diagnose Retail 12.1 title icons for the mock clients")
end

function PreviewMode:PrintTitleIconDiagnostics()
	if not BFL.IsRetail then
		PreviewMessage("|cffff0000BFL Title Icon:|r Retail 12.1 title icons are unavailable on this client.")
		return false
	end
	PreviewMessage(
		"|cff00ff00BFL Preview title icons:|r build "
			.. tostring(select(4, GetBuildInfo()))
			.. "; synthetic rows use bundled 12.1 title art."
	)
	for _, program in ipairs({ "ANBS", "App", "BSAp", "Pro", "S2", "WTCG", "WoW" }) do
		local path = GetMockTitleIconTexture(program)
		PreviewMessage(
			string.format(
				"  |cffffcc00%s|r |T%s:16:16:0:0|t %s",
				program,
				path,
				path
			)
		)
	end
	PreviewMessage("|cff888888Live friends still use Blizzard's native title-ID pipeline.|r")
	return true
end

function PreviewMode:HandleCommand(args)
	local cmd = (args or ""):lower():match("^%s*(.-)%s*$")

	if cmd == "" then
		if self.enabled then
			self:Disable()
		else
			self:EnableProfile("all")
		end
	elseif cmd == "help" or cmd == "list" then
		self:PrintIsolationHelp()
	elseif cmd == "off" or cmd == "disable" then
		self:Disable()
	elseif cmd == "status" then
		self:PrintStatus()
	elseif cmd == "icons" or cmd == "icon-debug" then
		self:PrintTitleIconDiagnostics()
	elseif cmd == "debug" then
		self:EnableProfileStaged("all")
	elseif cmd == "toggle" then
		if self.enabled then
			self:Disable()
		else
			self:EnableProfile("all")
		end
	elseif cmd == "on" or cmd == "enable" then
		self:EnableProfile("all")
	else
		local profileID, profile = self:GetProfileDefinition(cmd)
		if profile then
			self:EnableProfile(profileID)
		else
			PreviewMessage("|cffff0000BetterFriendlist:|r Unknown preview profile: " .. cmd)
			self:PrintIsolationHelp()
		end
	end
end

-- Return module
return PreviewMode
