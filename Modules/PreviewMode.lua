-- Modules/PreviewMode.lua
-- Unified Preview Mode System for Screenshots and Demonstrations
-- Version 1.0 - December 2025
--
-- Purpose: Enable comprehensive preview/demonstration mode for addon screenshots
-- This module coordinates all mock systems (Friends, Groups, Raid, QuickJoin, WHO)
-- to display realistic test data for promotional screenshots.
--
-- Command: /bfl preview
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

-- Mock player names for realistic screenshots (famous/lore characters + typical names)
local MOCK_NAMES = {
	-- Alliance Lore Characters
	"Anduin", "Jaina", "Genn", "Alleria", "Turalyon", "Velen", "Tyrande", "Malfurion",
	"Muradin", "Aysa", "Tess", "Shaw", "Magni", "Khadgar", "Valeera",
	-- Horde Lore Characters
	"Thrall", "Baine", "Lor'themar", "Thalyssra", "Gazlowe", "Rokhan", 
	"Geya'rah", "Calia", "Eitrigg", "Rexxar", "Zekhan", "Lilian",
	-- Neutral/Dragon Aspects
	"Chromie", "Wrathion", "Alexstrasza", "Ysera", "Nozdormu", "Kalecgos", "Ebonhorn",
	-- Typical Player Names
	"Shadowblade", "Lightforge", "Stormwind", "Ironhammer", "Darkflame", "Frostweaver",
	"Sunfire", "Moonshade", "Earthshaker", "Windwalker", "Bloodfang", "Steelclaw",
	"Nightwhisper", "Dawnbringer", "Fireheart", "Icefury", "Thunderstrike", "Soulkeeper",
	"Starseeker", "Voidwalker", "Felguard", "Spiritbinder", "Stormrage", "Proudmoore",
	"VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout"
}

-- Battle Tags for mock BNet friends
local MOCK_BATTLETAGS = {
	"Anduin#1234", "Jaina#5678", "Thrall#9012", "Sylvanas#3456",
	"Bolvar#7890", "Illidan#2345", "Tyrande#6789", "Malfurion#0123",
	"Arthas#4567", "Uther#8901", "Gul'dan#2345", "Khadgar#6789",
	"Medivh#0123", "Velen#4567", "Alleria#8901", "Turalyon#2345"
}

-- Class data (matches WoW class structure)
local MOCK_CLASSES = {
	{name = "Warrior", file = "WARRIOR", classID = 1},
	{name = "Paladin", file = "PALADIN", classID = 2},
	{name = "Hunter", file = "HUNTER", classID = 3},
	{name = "Rogue", file = "ROGUE", classID = 4},
	{name = "Priest", file = "PRIEST", classID = 5},
	{name = "Death Knight", file = "DEATHKNIGHT", classID = 6},
	{name = "Shaman", file = "SHAMAN", classID = 7},
	{name = "Mage", file = "MAGE", classID = 8},
	{name = "Warlock", file = "WARLOCK", classID = 9},
	{name = "Monk", file = "MONK", classID = 10},
	{name = "Druid", file = "DRUID", classID = 11},
	{name = "Demon Hunter", file = "DEMONHUNTER", classID = 12},
	{name = "Evoker", file = "EVOKER", classID = 13},
}

-- Zones for variety
local MOCK_ZONES = {
	-- The War Within zones
	"Dornogal", "The Ringing Deeps", "Hallowfall", "Azj-Kahet", "Isle of Dorn",
	"City of Threads", "Priory of the Sacred Flame", "Cinderbrew Meadery",
	-- Classic/Popular zones
	"Stormwind City", "Orgrimmar", "Dalaran", "Valdrakken", "Oribos",
	"Boralus", "Zuldazar", "Mechagon", "Nazjatar"
}

-- Game clients for variety
local MOCK_GAMES = {
	{program = "WoW", name = "World of Warcraft"},
	{program = "WoW", name = "World of Warcraft"},  -- More WoW players
	{program = "WoW", name = "World of Warcraft"},  -- More WoW players
	{program = "D4", name = "Diablo IV"},
	{program = "WTCG", name = "Hearthstone"},
	{program = "Pro", name = "Overwatch 2"},
	{program = "BSAp", name = "Battle.net App"},
}

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
	local accountName = battleTag:match("([^#]+)")
	local characterName = options.characterName or MOCK_NAMES[(index % #MOCK_NAMES) + 1]
	local faction = math.random(2) == 1 and "Alliance" or "Horde"
	
	-- Determine status (DND, AFK, normal)
	local isDND = options.isDND or (isOnline and math.random(10) == 1)
	local isAFK = options.isAFK or (isOnline and not isDND and math.random(8) == 1)
	
	return {
		type = "bnet",
		index = index,
		bnetAccountID = 1000000 + index,
		accountName = accountName,
		battleTag = battleTag,
		connected = isOnline,
		note = options.note or (math.random(3) == 1 and "Real friend from raids" or nil),
		isFavorite = options.isFavorite or (index <= 3),
		lastOnlineTime = not isOnline and (time() - math.random(86400, 604800)) or nil,
		-- Game account info (always present to prevent errors in FriendsFrame_GetBNetAccountNameAndStatus)
		gameAccountInfo = {
			isOnline = isOnline,
			gameAccountID = 1000 + index, -- Ensure valid ID
			clientProgram = isOnline and game.program or "",
			gameName = isOnline and game.name or "",
			characterName = (isOnline and game.program == "WoW") and characterName or "",
			className = (isOnline and game.program == "WoW") and classInfo.name or "",
			classID = (isOnline and game.program == "WoW") and classInfo.classID or 0,
			characterLevel = (isOnline and game.program == "WoW") and level or "",
			areaName = (isOnline and game.program == "WoW") and zone or "",
			realmName = (isOnline and game.program == "WoW") and "Blackrock" or "",
			factionName = (isOnline and game.program == "WoW") and faction or "",
			isDND = isDND,
			isAFK = isAFK,
			wowProjectID = (isOnline and game.program == "WoW") and 1 or 0,
		},
		-- Additional fields for display
		characterName = isOnline and game.program == "WoW" and characterName or nil,
		className = isOnline and game.program == "WoW" and classInfo.name or nil,
		classID = isOnline and game.program == "WoW" and classInfo.classID or nil,
		level = isOnline and game.program == "WoW" and level or nil,
		areaName = isOnline and game.program == "WoW" and zone or nil,
		realmName = isOnline and game.program == "WoW" and "Blackrock" or nil,
		factionName = isOnline and game.program == "WoW" and faction or nil,
		gameName = isOnline and game.program ~= "WoW" and game.name or nil,
		-- Mock marker
		_isMock = true,
	}
end

-- Generate mock WoW-only friend data
local function GenerateMockWoWFriend(index, isOnline, options)
	options = options or {}
	
	local classInfo = MOCK_CLASSES[math.random(#MOCK_CLASSES)]
	local zone = MOCK_ZONES[math.random(#MOCK_ZONES)]
	local level = options.level or math.random(70, 80)
	local name = options.name or MOCK_NAMES[(index % #MOCK_NAMES) + 1]
	
	return {
		type = "wow",
		index = index,
		name = name .. "-Blackrock",
		connected = isOnline,
		level = isOnline and level or nil,
		className = classInfo.name,
		area = isOnline and zone or nil,
		notes = options.notes or (math.random(4) == 1 and "Met in dungeon" or nil),
		-- Mock marker
		_isMock = true,
	}
end

-- ============================================
-- MOCK GROUPS GENERATION
-- ============================================

-- Generate mock friend groups with friends assigned
local function GenerateMockGroups()
	return {
		-- Built-in Groups
		{
			id = "favorites",
			name = "Favorites",
			collapsed = false,
			builtin = true,
			order = 1,
			color = {r = 1.0, g = 0.82, b = 0.0}, -- Gold
			icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
		},
		-- Custom groups (will be shown)
		{
			id = "raid_team",
			name = "Raid Team",
			collapsed = false,
			builtin = false,
			order = 2,
			color = {r = 1.0, g = 0.4, b = 0.4},  -- Red
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "mythic_plus",
			name = "Mythic+",
			collapsed = false,
			builtin = false,
			order = 3,
			color = {r = 0.4, g = 0.8, b = 1.0},  -- Light blue
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "pvp_friends",
			name = "PvP Friends",
			collapsed = false,
			builtin = false,
			order = 4,
			color = {r = 1.0, g = 0.6, b = 0.0},  -- Orange
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "irl_friends",
			name = "IRL Friends",
			collapsed = false,
			builtin = false,
			order = 5,
			color = {r = 0.6, g = 1.0, b = 0.6},  -- Light green
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "trading",
			name = "Trading Partners",
			collapsed = true,  -- Show collapsed for variety
			builtin = false,
			order = 6,
			color = {r = 1.0, g = 0.84, b = 0.0},  -- Gold
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		-- International Test Groups (Non-Roman)
		{
			id = "group_korea",
			name = "테스트 그룹 (KR)",
			collapsed = false,
			builtin = false,
			order = 7,
			color = {r = 0.4, g = 1.0, b = 0.4},  -- Mint
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "group_china",
			name = "测试组 (CN)",
			collapsed = false,
			builtin = false,
			order = 8,
			color = {r = 1.0, g = 0.4, b = 0.4},  -- Redish
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "group_russia",
			name = "Тестовая группа (RU)",
			collapsed = false,
			builtin = false,
			order = 9,
			color = {r = 0.4, g = 0.4, b = 1.0},  -- Blueish
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "group_japan",
			name = "テストグループ (JP)",
			collapsed = false,
			builtin = false,
			order = 10,
			color = {r = 1.0, g = 0.6, b = 0.8},  -- Pink
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
		{
			id = "nogroup",
			name = "No Group",
			collapsed = false,
			builtin = true,
			order = 999,
			color = {r = 0.5, g = 0.5, b = 0.5}, -- Gray
			icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
		},
	}
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
	["bnet_Anduin#1234"] = {"raid_team"},      -- Index 1: Also in Raid Team
	["bnet_Jaina#5678"] = {"mythic_plus"},     -- Index 2: Also in Mythic+
	["bnet_Thrall#9012"] = {"pvp_friends"},    -- Index 3: Also in PvP Friends
	["bnet_Sylvanas#3456"] = {"raid_team"},    -- Index 4: Raid Team (Diablo IV player)
	["bnet_Bolvar#7890"] = {"raid_team"},      -- Index 5: Raid Team (Hearthstone player)
	["bnet_Illidan#2345"] = {"mythic_plus"},   -- Index 6: Mythic+ (DND status)
	["bnet_Tyrande#6789"] = {"mythic_plus"},   -- Index 7: Mythic+ (AFK status)
	["bnet_Malfurion#0123"] = {"irl_friends"}, -- Index 8: IRL Friends
	
	-- Offline BNet Friends (indices 9-16, wrapping around MOCK_BATTLETAGS)
	["bnet_Arthas#4567"] = {"raid_team"},      -- Offline: Raid Team
	["bnet_Uther#8901"] = {"mythic_plus"},     -- Offline: Mythic+
	["bnet_Gul'dan#2345"] = {"pvp_friends"},   -- Offline: PvP Friends
	["bnet_Khadgar#6789"] = {"pvp_friends"},   -- Offline: PvP Friends
	["bnet_Medivh#0123"] = {"irl_friends"},    -- Offline: IRL Friends
	["bnet_Velen#4567"] = {"irl_friends"},     -- Offline: IRL Friends
	["bnet_Alleria#8901"] = {"trading"},       -- Offline: Trading
	["bnet_Turalyon#2345"] = {"trading"},      -- Offline: Trading
}

-- WoW friend group assignments (by character name)
-- The UID format is: "wow_" .. characterName .. "-" .. realm
local MOCK_WOW_GROUP_ASSIGNMENTS = {
	-- Online WoW friends (names from MOCK_NAMES[21-24])
	["wow_Nightwhisper-Blackrock"] = {"mythic_plus"},
	["wow_Dawnbringer-Blackrock"] = {"raid_team"},
	["wow_Fireheart-Blackrock"] = {"pvp_friends"},
	["wow_Icefury-Blackrock"] = {"pvp_friends"},
	-- Offline WoW friends (names from MOCK_NAMES[25-28])
	["wow_Thunderstrike-Blackrock"] = {"trading"},
	["wow_Soulkeeper-Blackrock"] = {"irl_friends"},
	["wow_Starseeker-Blackrock"] = {"raid_team"},
	["wow_Voidwalker-Blackrock"] = {"mythic_plus"},
}

-- ============================================
-- MOCK WHO RESULTS
-- ============================================

local function GenerateMockWhoResults()
	local results = {}
	local numResults = math.random(15, 30)
	
	for i = 1, numResults do
		local classInfo = MOCK_CLASSES[math.random(#MOCK_CLASSES)]
		local zone = MOCK_ZONES[math.random(#MOCK_ZONES)]
		local name = MOCK_NAMES[(i % #MOCK_NAMES) + 1]
		local level = math.random(70, 80)
		
		-- Generate guild names
		local guilds = {"Eternal", "Phoenix Rising", "Legends", "Storm Riders", "Iron Legion", "", "", ""}
		local guild = guilds[math.random(#guilds)]
		
		-- Generate race
		local races = {"Human", "Night Elf", "Dwarf", "Gnome", "Orc", "Troll", "Tauren", "Blood Elf", "Dracthyr", "Pandaren"}
		local race = races[math.random(#races)]
		
		results[i] = {
			name = name,
			guild = guild,
			level = level,
			race = race,
			class = classInfo.name,
			classFileName = classInfo.file,
			zone = zone,
			-- Mock marker
			_isMock = true,
		}
	end
	
	return results
end

-- ============================================
-- PREVIEW MODE STATE MANAGEMENT
-- ============================================

-- Stored real data (to restore when exiting preview)
PreviewMode.savedState = {
	friendsList = nil,
	groups = nil,
	whoResults = nil,
}

-- Mock data storage
PreviewMode.mockData = {
	friends = {},
	groups = {},
	whoResults = {},
	groupAssignments = {},
}

-- Mock BattleTag for privacy in screenshots
PreviewMode.MOCK_BATTLETAG = "YourName#1234"

-- ============================================
-- BATTLETAG MASKING
-- ============================================

--[[
	Get the BattleNet frame where the BattleTag is displayed
]]
function PreviewMode:GetBattleNetFrame()
	if not BetterFriendsFrame then return nil end
	if not BetterFriendsFrame.FriendsTabHeader then return nil end
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
	
	-- Hook the FrameInitializer to prevent it from overwriting our mock tag
	local FrameInitializer = BFL:GetModule("FrameInitializer")
	if FrameInitializer and not self.originalInitializeBattlenetFrame then
		self.originalInitializeBattlenetFrame = FrameInitializer.InitializeBattlenetFrame
		
		FrameInitializer.InitializeBattlenetFrame = function(initSelf, frame)
			-- Call original function first
			if PreviewMode.originalInitializeBattlenetFrame then
				PreviewMode.originalInitializeBattlenetFrame(initSelf, frame)
			end
			
			-- If preview mode is active, re-apply mock BattleTag
			if PreviewMode.enabled then
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
	if not bnetFrame or not bnetFrame.Tag then return end
	
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
end

-- ============================================
-- PREVIEW MODE ACTIVATION
-- ============================================

--[[
	Enable Preview Mode
	Creates and displays comprehensive mock data for screenshots
]]
function PreviewMode:Enable()
	if self.enabled then
		print("|cffff8800BetterFriendlist:|r Preview mode is already enabled!")
		return
	end
	
	print("|cff00ff00BetterFriendlist:|r |cffffd700Preview Mode ENABLED|r")
	print("|cff888888Creating demonstration data for screenshots...|r")
	
	self.enabled = true
	
	-- Generate mock friends (mix of online and offline)
	self:GenerateMockFriends()
	
	-- Generate mock groups
	self:GenerateMockGroupsData()
	
	-- Enable existing mock systems
	self:EnableRaidMock()
	self:EnableQuickJoinMock()
	self:EnableWhoMock()
	self:EnableInviteMock()
	
	-- Apply mock data to FriendsList
	self:ApplyMockFriends()
	
	-- Apply mock BattleTag (hide real BattleTag for screenshots)
	self:ApplyMockBattleTag()
	
	-- Force UI refresh
	self:RefreshAllUI()
	
	print("|cff00ff00BetterFriendlist:|r Preview data created:")
	print("  |cffffffff• " .. #self.mockData.friends .. " mock friends|r")
	print("  |cffffffff• " .. #self.mockData.groups .. " custom groups|r")
	print("  |cffffffff• Raid frame with 25 players|r")
	print("  |cffffffff• Quick Join with ~11 groups|r")
	print("  |cffffffff• 2 friend invite requests|r")
	print("  |cffffffff• BattleTag hidden (" .. self.MOCK_BATTLETAG .. ")|r")
	print("")
	print("|cffffcc00Tip:|r Use |cffffffff/bfl preview off|r to disable preview mode")
end

--[[
	Disable Preview Mode
	Restores real data and removes all mock content
]]
function PreviewMode:Disable()
	if not self.enabled then
		print("|cffff8800BetterFriendlist:|r Preview mode is not enabled!")
		return
	end
	
	print("|cff00ff00BetterFriendlist:|r |cffffd700Preview Mode DISABLED|r")
	
	self.enabled = false
	
	-- Clear mock data
	self.mockData.friends = {}
	self.mockData.groups = {}
	self.mockData.groupAssignments = {}
	
	-- Restore original UpdateFriendsList function
	local FriendsList = BFL:GetModule("FriendsList")
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
	
	-- Restore original friendGroups in BetterFriendlistDB
	if BetterFriendlistDB and BetterFriendlistDB.friendGroups then
		-- Remove mock friend group assignments
		for uid in pairs(MOCK_GROUP_ASSIGNMENTS) do
			BetterFriendlistDB.friendGroups[uid] = nil
		end
		for uid in pairs(MOCK_WOW_GROUP_ASSIGNMENTS) do
			BetterFriendlistDB.friendGroups[uid] = nil
		end
		
		-- Restore original assignments
		if self.originalFriendGroups then
			for uid, groups in pairs(self.originalFriendGroups) do
				BetterFriendlistDB.friendGroups[uid] = groups
			end
		end
		self.originalFriendGroups = nil
	end
	
	-- Disable existing mock systems (this also restores original functions)
	self:DisableRaidMock()
	self:DisableQuickJoinMock()
	self:DisableWhoMock()
	self:DisableInviteMock()
	
	-- Restore original BattleTag
	self:RestoreBattleTag()
	
	-- Force UI refresh with real data
	self:RefreshAllUI()
	
	print("|cff888888All preview data removed. Real friend data restored.|r")
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
	
	-- Generate International Friends for Font Testing (KR, SC, TC, RU, JP)
	local intFriends = {
		{ 
			name = "안녕하세요", 
			tag = "안녕하세요#1111", 
			uid="bnet_안녕하세요#1111", 
			group="group_korea", 
			note="한국어 폰트 테스트 (Korean)",
			zone="서울 (Seoul)"
		}, 
		{ 
			name = "你好世界", 
			tag = "你好世界#2222", 
			uid="bnet_你好世界#2222", 
			group="group_china", 
			note="中文备注测试 (Simp. Chinese)",
			zone="奥格瑞玛 (Orgrimmar)"
		}, 
		{ 
			name = "哈囉世界", 
			tag = "哈囉世界#3333", 
			uid="bnet_哈囉世界#3333", 
			group="group_china", 
			note="繁體中文備註 (Trad. Chinese)",
			zone="暴風城 (Stormwind)"
		}, 
		{ 
			name = "Россия", 
			tag = "Россия#4444", 
			uid="bnet_Россия#4444", 
			group="group_russia", 
			note="Проверка шрифтов (Russian)",
			zone="Даларан (Dalaran)" 
		},
		{ 
			name = "こんにちは", 
			tag = "こんにちは#5555", 
			uid="bnet_こんにちは#5555", 
			group="group_japan", 
			note="日本語テスト (Japanese)",
			zone="ドラゴンの島 (Dragon Isles)" 
		},
		{ 
			name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout", 
			tag = "LongName#9999", 
			uid="bnet_LongName#9999", 
			group="favorites", 
			note="This is a test entry for testing the font string resize behavior when resizing the frame width.",
			zone="Stormwind City" 
		},
	}
	
	for i, data in ipairs(intFriends) do
		local options = {
			battleTag = data.tag,
			accountName = data.name, -- Distinct account name
			characterName = data.name,
			game = {program = "WoW", name = "World of Warcraft"},
			note = data.note,
			zone = data.zone,
			isFavorite = false, -- Not favorites, per user request
		}
		-- print("BFL Preview: Adding " .. data.tag) -- Debug print
		table.insert(self.mockData.friends, GenerateMockBNetFriend(200 + i, true, options))
		-- Assign to specific normal groups to integrate them into the preview
		self.mockData.groupAssignments[data.uid] = {data.group}
	end
	
	-- Generate 8 online BNet friends with varied status
	for i = 1, 8 do
		local options = {
			battleTag = MOCK_BATTLETAGS[i],
			isFavorite = (i <= 3),
		}
		
		-- Vary the games for variety in screenshots
		if i == 4 then
			options.game = {program = "D4", name = "Diablo IV"}
		elseif i == 5 then
			options.game = {program = "WTCG", name = "Hearthstone"}
		elseif i == 6 then
			options.isDND = true
		elseif i == 7 then
			options.isAFK = true
		end
		
		table.insert(self.mockData.friends, GenerateMockBNetFriend(i, true, options))
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
		table.insert(self.mockData.friends, GenerateMockWoWFriend(i + 100, true, {
			name = MOCK_NAMES[i + 20],
		}))
	end

	-- Add explicit Long Name WoW Friend
	table.insert(self.mockData.friends, GenerateMockWoWFriend(150, true, {
		name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
		notes = "Testing WoW friend name truncation logic",
	}))
	
	-- Generate 4 offline WoW-only friends
	for i = 5, 8 do
		table.insert(self.mockData.friends, GenerateMockWoWFriend(i + 100, false, {
			name = MOCK_NAMES[i + 24],
		}))
	end
	
	-- Add explicit Long Name WoW Friend (Offline)
	table.insert(self.mockData.friends, GenerateMockWoWFriend(151, false, {
		name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout", 
		notes = "Testing Offline WoW friend name truncation logic",
	}))
end

function PreviewMode:GenerateMockGroupsData()
	self.mockData.groups = GenerateMockGroups()
	
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

-- ============================================
-- MOCK DATA APPLICATION
-- ============================================

--[[
	Apply mock friends to the FriendsList module
	This injects mock data into the friends display
]]
function PreviewMode:ApplyMockFriends()
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then return end
	
	-- Store the current friendsList generation function
	if not self.originalUpdateFriendsList then
		self.originalUpdateFriendsList = FriendsList.UpdateFriendsList
	end
	
	-- Override UpdateFriendsList to inject mock data
	FriendsList.UpdateFriendsList = function(self)
		if PreviewMode.enabled and #PreviewMode.mockData.friends > 0 then
			-- Use mock data instead of real API data
			wipe(self.friendsList)
			
			for _, friend in ipairs(PreviewMode.mockData.friends) do
				table.insert(self.friendsList, friend)
			end
			
			-- Apply filters and sort
			self:ApplyFilters()
			self:ApplySort()
			
			-- Build display list to update UI
			self:RenderDisplay()
		else
			-- Call original function for real data
			PreviewMode.originalUpdateFriendsList(self)
		end
	end
	
	-- Apply mock groups to Groups module
	-- IMPORTANT: We need to inject directly into Groups.groups table
	local Groups = BFL:GetModule("Groups")
	if Groups then
		-- Store original groups before modification
		if not self.originalGroups then
			self.originalGroups = {}
			for id, data in pairs(Groups.groups) do
				self.originalGroups[id] = data
			end
		end
		
		-- Wipe existing groups to prevent mixing real and mock data
		wipe(Groups.groups)
		
		-- Inject mock groups directly into Groups.groups table
		for _, mockGroup in ipairs(self.mockData.groups) do
			Groups.groups[mockGroup.id] = mockGroup
		end
		
		-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Replaced Groups.groups with " .. #self.mockData.groups .. " mock groups")
	end
	
	-- Mock group order for Settings tab
	if BetterFriendlistDB then
		if not self.originalGroupOrder then
			self.originalGroupOrder = BetterFriendlistDB.groupOrder
		end
		
		-- Create mock order list
		local mockOrder = {}
		local sortedMockGroups = {}
		for _, group in ipairs(self.mockData.groups) do
			table.insert(sortedMockGroups, group)
		end
		table.sort(sortedMockGroups, function(a, b) return (a.order or 999) < (b.order or 999) end)
		
		for _, group in ipairs(sortedMockGroups) do
			table.insert(mockOrder, group.id)
		end
		
		BetterFriendlistDB.groupOrder = mockOrder
	end
	
	-- Inject mock friend group assignments directly into BetterFriendlistDB.friendGroups
	-- IMPORTANT: This is where FriendsList reads the assignments from!
	if BetterFriendlistDB then
		-- Store original friendGroups for restoration
		if not self.originalFriendGroups then
			self.originalFriendGroups = {}
			if BetterFriendlistDB.friendGroups then
				for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
					self.originalFriendGroups[uid] = groups
				end
			end
		end
		
		-- Ensure friendGroups table exists
		if not BetterFriendlistDB.friendGroups then
			BetterFriendlistDB.friendGroups = {}
		end
		
		-- Inject mock assignments (using the consolidated mockData table)
		local injectedCount = 0
		for uid, groups in pairs(self.mockData.groupAssignments) do
			BetterFriendlistDB.friendGroups[uid] = groups
			injectedCount = injectedCount + 1
		end
		
		-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Injected " .. injectedCount .. " friend group assignments into BetterFriendlistDB.friendGroups")
	end
end

-- ============================================
-- EXISTING MOCK SYSTEM INTEGRATION
-- ============================================

function PreviewMode:EnableRaidMock()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if not RaidFrame then return end
	
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
	
	-- Now activate the mock preset
	if RaidFrame.CreateMockPreset_Standard then
		RaidFrame:CreateMockPreset_Standard()
		-- BFL:DebugPrint("|cff00ffffPreviewMode:|r Raid mock enabled with event overrides")
	end
end

function PreviewMode:DisableRaidMock()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if not RaidFrame then return end
	
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

function PreviewMode:EnableQuickJoinMock()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.CreateMockPreset_All then
		QuickJoin:CreateMockPreset_All()
	end
end

function PreviewMode:DisableQuickJoinMock()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.ClearMockGroups then
		QuickJoin:ClearMockGroups()
	end
end

function PreviewMode:EnableWhoMock()
	-- Generate mock WHO results
	self.mockData.whoResults = GenerateMockWhoResults()
	
	-- The WHO frame will pick up mock data on next update
	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
		-- Store original function
		if not self.originalGetWhoResults then
			-- WhoFrame uses C_FriendList.GetNumWhoResults() and C_FriendList.GetWhoInfo(i)
			-- We'll hook into the WhoFrame update instead
		end
	end
end

function PreviewMode:DisableWhoMock()
	self.mockData.whoResults = {}
end

function PreviewMode:EnableInviteMock()
	-- Use existing mock invite system
	BFL.MockFriendInvites.enabled = true
	BFL.MockFriendInvites.invites = {
		{inviteID = 1000001, accountName = "NewFriend#1234"},
		{inviteID = 1000002, accountName = "GuildRecruit#5678"},
	}
end

function PreviewMode:DisableInviteMock()
	BFL.MockFriendInvites.enabled = false
	BFL.MockFriendInvites.invites = {}
end

-- ============================================
-- UI REFRESH
-- ============================================

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
		if RaidFrame.UpdateControlPanel then
			RaidFrame:UpdateControlPanel()
		end
	end
	
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
	-- Module is ready
	-- BFL:DebugPrint("|cff00ffffBFL:PreviewMode:|r Initialized")
end

-- ============================================
-- SLASH COMMAND HANDLER (Called from Core.lua)
-- ============================================

function PreviewMode:HandleCommand(args)
	local cmd = args and args:lower() or ""
	
	if cmd == "" or cmd == "on" or cmd == "enable" then
		self:Enable()
	elseif cmd == "off" or cmd == "disable" then
		self:Disable()
	elseif cmd == "toggle" then
		self:Toggle()
	elseif cmd == "status" then
		if self.enabled then
			print("|cff00ff00BetterFriendlist:|r Preview mode is |cff00ff00ENABLED|r")
			print("  |cffffffff• " .. #self.mockData.friends .. " mock friends|r")
			print("  |cffffffff• " .. #self.mockData.groups .. " custom groups|r")
		else
			print("|cff00ff00BetterFriendlist:|r Preview mode is |cffff0000DISABLED|r")
		end
	else
		print("|cff00ff00BFL Preview Mode Commands:|r")
		print("")
		print("  |cffffcc00/bfl preview|r - Enable preview mode")
		print("  |cffffcc00/bfl preview off|r - Disable preview mode")
		print("  |cffffcc00/bfl preview toggle|r - Toggle preview mode")
		print("  |cffffcc00/bfl preview status|r - Show current status")
		print("")
		print("|cff888888Preview mode displays realistic mock data for screenshots.|r")
		print("|cff888888It includes: Friends, Groups, Raid, QuickJoin, and Invites.|r")
	end
end

-- Return module
return PreviewMode