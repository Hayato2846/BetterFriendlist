-- TestData/MockDataProvider.lua
-- Dynamic Mock Data Generation for Test Scenarios
--
-- Purpose:
-- Provides APIs to generate realistic mock data for testing BetterFriendlist
-- without requiring actual friends online or specific game states.
--
-- Features:
-- - Generate N friends with configurable online ratio
-- - Generate groups with friend assignments
-- - Generate raid compositions
-- - Generate QuickJoin groups
-- - Supports scenarios with preset configurations
--
-- Usage:
--   local provider = BFL.MockDataProvider
--   local friends = provider:GenerateFriends(200, {onlineRatio = 0.4})
--   local groups = provider:GenerateGroups(8, {friendDistribution = "random"})

local ADDON_NAME, BFL = ...

-- Ensure TestData namespace exists
BFL.TestData = BFL.TestData or {}

-- Create MockDataProvider module
local MockDataProvider = {}
BFL.MockDataProvider = MockDataProvider

-- ============================================
-- STATE MANAGEMENT
-- ============================================

-- Current mock data (active)
MockDataProvider.currentData = {
    friends = {},
    groups = {},
    groupAssignments = {},
    raid = nil,
    quickJoinGroups = {},
}

-- Tracking for unique ID generation
MockDataProvider.nextBNetAccountID = 1000000
MockDataProvider.nextWoWFriendIndex = 1
MockDataProvider.usedNames = {}
MockDataProvider.usedBattleTags = {}

-- ============================================
-- INITIALIZATION
-- ============================================

function MockDataProvider:Reset()
    self.currentData = {
        friends = {},
        groups = {},
        groupAssignments = {},
        raid = nil,
        quickJoinGroups = {},
    }
    self.nextBNetAccountID = 1000000
    self.nextWoWFriendIndex = 1
    wipe(self.usedNames)
    wipe(self.usedBattleTags)
end

-- ============================================
-- NAME GENERATION (uses CharacterNames.lua)
-- ============================================

-- Get a unique name that hasn't been used yet
function MockDataProvider:GetUniqueName()
    local TestData = BFL.TestData
    if not TestData then
        return "Friend" .. math.random(1000, 9999)
    end
    
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local name = TestData:GetRandomName()
        if not self.usedNames[name] then
            self.usedNames[name] = true
            return name
        end
        attempts = attempts + 1
    end
    
    -- Fallback: generate numbered name
    local fallback = "Friend" .. self.nextWoWFriendIndex
    self.nextWoWFriendIndex = self.nextWoWFriendIndex + 1
    self.usedNames[fallback] = true
    return fallback
end

-- Get a unique BattleTag
function MockDataProvider:GetUniqueBattleTag()
    local TestData = BFL.TestData
    if not TestData then
        local tag = string.format("Player#%04d", self.nextBNetAccountID - 1000000)
        self.nextBNetAccountID = self.nextBNetAccountID + 1
        return tag
    end
    
    local attempts = 0
    local maxAttempts = 50
    
    while attempts < maxAttempts do
        local tag = TestData:GetRandomBattleTag()
        if not self.usedBattleTags[tag] then
            self.usedBattleTags[tag] = true
            return tag
        end
        attempts = attempts + 1
    end
    
    -- Fallback: generate numbered tag
    local index = self.nextBNetAccountID - 999999
    local fallback = string.format("Player#%04d", index)
    self.nextBNetAccountID = self.nextBNetAccountID + 1
    self.usedBattleTags[fallback] = true
    return fallback
end

-- Get an international name (for font testing)
function MockDataProvider:GetInternationalName(language)
    local TestData = BFL.TestData
    if not TestData or not TestData.InternationalNames then
        return "InternationalPlayer"
    end
    
    return TestData:GetRandomInternationalName(language)
end

-- ============================================
-- FRIEND GENERATION
-- ============================================

--[[
    Generate a single Battle.net friend
    
    @param options table:
        - isOnline (boolean): Whether the friend is online
        - isFavorite (boolean): Whether the friend is a favorite
        - game (table): {program, name} game client info
        - status (string): "available", "afk", "dnd", "busy"
        - characterName (string): Override character name
        - battleTag (string): Override BattleTag
        - note (string): Friend note
        - zone (string): Override zone
        - level (number): Override level
        - classInfo (table): Override class
        - international (boolean): Use international name
        - language (string): Specific language for international name
    
    @return table: Mock BNet friend data
]]
function MockDataProvider:CreateBNetFriend(options)
    options = options or {}
    
    local Constants = BFL.TestData and BFL.TestData.Constants
    
    -- Get class info
    local classInfo
    if options.classInfo then
        classInfo = options.classInfo
    elseif Constants then
        classInfo = Constants:GetWeightedRandomClass()
    else
        classInfo = {classID = 1, name = "Warrior", file = "WARRIOR"}
    end
    
    -- Get zone
    local zone
    if options.zone then
        zone = options.zone
    elseif Constants then
        zone = Constants:GetRandomZone()
    else
        zone = "Dornogal"
    end
    
    -- Get game client
    local game
    if options.game then
        game = options.game
    elseif Constants then
        game = Constants:GetRandomGameClient()
    else
        game = {program = "WoW", name = "World of Warcraft"}
    end
    
    -- Get level
    local level
    if options.level then
        level = options.level
    elseif Constants then
        level = Constants:GetRandomLevel()
    else
        level = 80
    end
    
    -- Get status
    local status = options.status or "available"
    local isDND = status == "dnd"
    local isAFK = status == "afk"
    
    -- Get BattleTag
    local battleTag = options.battleTag or self:GetUniqueBattleTag()
    local accountName = battleTag:match("([^#]+)")
    
    -- Get character name
    local characterName
    if options.characterName then
        characterName = options.characterName
    elseif options.international then
        characterName = self:GetInternationalName(options.language)
    else
        characterName = self:GetUniqueName()
    end
    
    -- Determine if playing WoW
    local isPlayingWoW = options.isOnline and game.program == "WoW"
    
    -- Generate faction
    local factions = {"Alliance", "Horde"}
    local faction = factions[math.random(#factions)]
    
    -- Generate realm
    local realms = {"Blackrock", "Stormrage", "Area 52", "Illidan", "Tichondrius", "Proudmoore"}
    local realm = realms[math.random(#realms)]
    
    -- Generate unique ID
    local bnetAccountID = self.nextBNetAccountID
    self.nextBNetAccountID = self.nextBNetAccountID + 1
    
    -- Build friend data structure (matches real WoW API)
    local friend = {
        type = "bnet",
        index = bnetAccountID - 999999,
        bnetAccountID = bnetAccountID,
        accountName = accountName,
        battleTag = battleTag,
        connected = options.isOnline or false,
        note = options.note or nil,
        isFavorite = options.isFavorite or false,
        lastOnlineTime = not options.isOnline and (time() - math.random(3600, 604800)) or nil,
        
        -- Game account info (always present)
        gameAccountInfo = {
            isOnline = options.isOnline or false,
            gameAccountID = 1000 + (bnetAccountID - 1000000),
            clientProgram = options.isOnline and game.program or "",
            gameName = options.isOnline and game.name or "",
            characterName = isPlayingWoW and characterName or "",
            className = isPlayingWoW and classInfo.name or "",
            classID = isPlayingWoW and classInfo.classID or 0,
            characterLevel = isPlayingWoW and level or "",
            areaName = isPlayingWoW and zone or "",
            realmName = isPlayingWoW and realm or "",
            factionName = isPlayingWoW and faction or "",
            isDND = isDND,
            isAFK = isAFK,
            wowProjectID = isPlayingWoW and 1 or 0,
        },
        
        -- Additional fields for display
        characterName = isPlayingWoW and characterName or nil,
        className = isPlayingWoW and classInfo.name or nil,
        classID = isPlayingWoW and classInfo.classID or nil,
        level = isPlayingWoW and level or nil,
        areaName = isPlayingWoW and zone or nil,
        realmName = isPlayingWoW and realm or nil,
        factionName = isPlayingWoW and faction or nil,
        gameName = (options.isOnline and game.program ~= "WoW") and game.name or nil,
        
        -- Mock marker
        _isMock = true,
    }
    
    return friend
end

--[[
    Generate a single WoW-only friend
    
    @param options table:
        - isOnline (boolean): Whether the friend is online
        - name (string): Character name
        - note (string): Friend note
        - level (number): Character level
        - classInfo (table): Class info
        - zone (string): Current zone
    
    @return table: Mock WoW friend data
]]
function MockDataProvider:CreateWoWFriend(options)
    options = options or {}
    
    local Constants = BFL.TestData and BFL.TestData.Constants
    
    -- Get class info
    local classInfo
    if options.classInfo then
        classInfo = options.classInfo
    elseif Constants then
        classInfo = Constants:GetWeightedRandomClass()
    else
        classInfo = {classID = 1, name = "Warrior", file = "WARRIOR"}
    end
    
    -- Get zone
    local zone
    if options.zone then
        zone = options.zone
    elseif Constants then
        zone = Constants:GetRandomZone()
    else
        zone = "Dornogal"
    end
    
    -- Get level
    local level
    if options.level then
        level = options.level
    elseif Constants then
        level = Constants:GetRandomLevel()
    else
        level = 80
    end
    
    -- Get name
    local name = options.name or self:GetUniqueName()
    
    -- Generate realm
    local realms = {"Blackrock", "Stormrage", "Area 52"}
    local realm = realms[math.random(#realms)]
    
    local index = self.nextWoWFriendIndex
    self.nextWoWFriendIndex = self.nextWoWFriendIndex + 1
    
    local friend = {
        type = "wow",
        index = index,
        name = name .. "-" .. realm,
        connected = options.isOnline or false,
        level = options.isOnline and level or nil,
        className = classInfo.name,
        classFileName = classInfo.file,
        area = options.isOnline and zone or nil,
        notes = options.note or nil,
        
        -- Mock marker
        _isMock = true,
    }
    
    return friend
end

--[[
    Generate multiple friends with configurable distribution
    
    @param count number: Total number of friends to generate
    @param options table:
        - onlineRatio (number 0-1): Ratio of online friends (default: 0.4)
        - wowRatio (number 0-1): Ratio of WoW players among online (default: 0.7)
        - bnetRatio (number 0-1): Ratio of BNet friends (default: 0.8)
        - favoriteRatio (number 0-1): Ratio of favorites (default: 0.08)
        - noteRatio (number 0-1): Ratio of friends with notes (default: 0.25)
        - internationalRatio (number 0-1): Ratio of international names (default: 0)
        - statusDistribution (table): Override status distribution
    
    @return table: Array of mock friend data
]]
function MockDataProvider:GenerateFriends(count, options)
    options = options or {}
    
    local onlineRatio = options.onlineRatio or 0.4
    local wowRatio = options.wowRatio or 0.7
    local bnetRatio = options.bnetRatio or 0.8
    local favoriteRatio = options.favoriteRatio or 0.08
    local noteRatio = options.noteRatio or 0.25
    local internationalRatio = options.internationalRatio or 0
    
    local Constants = BFL.TestData and BFL.TestData.Constants
    
    local friends = {}
    
    for i = 1, count do
        local isBNet = math.random() < bnetRatio
        local isOnline = math.random() < onlineRatio
        local isFavorite = math.random() < favoriteRatio
        local hasNote = math.random() < noteRatio
        local isInternational = math.random() < internationalRatio
        
        local friendOptions = {
            isOnline = isOnline,
            isFavorite = isFavorite,
            international = isInternational,
        }
        
        -- Add note if applicable
        if hasNote and Constants then
            friendOptions.note = Constants:GetRandomNote()
        end
        
        -- Determine game for online BNet friends
        if isBNet and isOnline then
            local playingWoW = math.random() < wowRatio
            if not playingWoW then
                -- Pick a non-WoW game
                local nonWoWGames = {
                    {program = "D4", name = "Diablo IV"},
                    {program = "Pro", name = "Overwatch 2"},
                    {program = "WTCG", name = "Hearthstone"},
                    {program = "BSAp", name = "Battle.net"},
                }
                friendOptions.game = nonWoWGames[math.random(#nonWoWGames)]
            else
                friendOptions.game = {program = "WoW", name = "World of Warcraft"}
                
                -- Determine status for WoW players
                if Constants then
                    friendOptions.status = Constants:GetRandomStatus()
                end
            end
        end
        
        local friend
        if isBNet then
            friend = self:CreateBNetFriend(friendOptions)
        else
            friend = self:CreateWoWFriend(friendOptions)
        end
        
        table.insert(friends, friend)
    end
    
    return friends
end

-- ============================================
-- GROUP GENERATION
-- ============================================

--[[
    Generate custom friend groups
    
    @param count number: Number of groups to generate (max 10)
    @param options table:
        - includeBuiltin (boolean): Include Favorites and No Group (default: true)
        - customGroups (table): Specific group definitions
        - colors (table): Array of color tables {r, g, b}
    
    @return table: Array of group definitions
]]
function MockDataProvider:GenerateGroups(count, options)
    options = options or {}
    count = math.min(count or 5, 10)
    
    local includeBuiltin = options.includeBuiltin
    if includeBuiltin == nil then includeBuiltin = true end
    
    local groups = {}
    local order = 1
    
    -- Built-in Favorites group
    if includeBuiltin then
        table.insert(groups, {
            id = "favorites",
            name = "Favorites",
            collapsed = false,
            builtin = true,
            order = order,
            color = {r = 1.0, g = 0.82, b = 0.0},
            icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
        })
        order = order + 1
    end
    
    -- Default group names and colors
    local defaultGroups = {
        {name = "Raid Team",       color = {r = 1.0, g = 0.4, b = 0.4}},
        {name = "Mythic+",         color = {r = 0.4, g = 0.8, b = 1.0}},
        {name = "PvP Friends",     color = {r = 1.0, g = 0.6, b = 0.0}},
        {name = "IRL Friends",     color = {r = 0.6, g = 1.0, b = 0.6}},
        {name = "Trading Partners", color = {r = 1.0, g = 0.84, b = 0.0}},
        {name = "Guild Members",   color = {r = 0.4, g = 0.4, b = 1.0}},
        {name = "Arena Partners",  color = {r = 0.8, g = 0.4, b = 0.8}},
        {name = "Alts",            color = {r = 0.5, g = 0.8, b = 0.5}},
        {name = "Old Guildies",    color = {r = 0.6, g = 0.6, b = 0.6}},
        {name = "Streamers",       color = {r = 1.0, g = 0.5, b = 0.8}},
    }
    
    -- Use custom groups if provided
    local groupDefs = options.customGroups or defaultGroups
    
    -- Generate groups
    for i = 1, count do
        local def = groupDefs[i] or defaultGroups[((i - 1) % #defaultGroups) + 1]
        local groupId = "group_" .. i
        
        -- Generate unique ID based on name
        if def.name then
            groupId = def.name:lower():gsub(" ", "_"):gsub("[^%w_]", "")
        end
        
        table.insert(groups, {
            id = groupId,
            name = def.name,
            collapsed = def.collapsed or false,
            builtin = false,
            order = order,
            color = def.color or {r = 0.5, g = 0.5, b = 0.5},
            icon = def.icon or "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
        })
        
        order = order + 1
    end
    
    -- Built-in No Group
    if includeBuiltin then
        table.insert(groups, {
            id = "nogroup",
            name = "No Group",
            collapsed = false,
            builtin = true,
            order = 999,
            color = {r = 0.5, g = 0.5, b = 0.5},
            icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
        })
    end
    
    return groups
end

--[[
    Assign friends to groups
    
    @param friends table: Array of friend data
    @param groups table: Array of group data
    @param options table:
        - distribution (string): "random", "even", "weighted"
        - assignmentRatio (number 0-1): Ratio of friends to assign (default: 0.7)
        - multiGroupRatio (number 0-1): Ratio of friends in multiple groups (default: 0.1)
    
    @return table: Map of UID -> {groupId1, groupId2, ...}
]]
function MockDataProvider:AssignFriendsToGroups(friends, groups, options)
    options = options or {}
    
    local distribution = options.distribution or "random"
    local assignmentRatio = options.assignmentRatio or 0.7
    local multiGroupRatio = options.multiGroupRatio or 0.1
    
    local assignments = {}
    
    -- Filter out builtin groups for assignment
    local assignableGroups = {}
    for _, group in ipairs(groups) do
        if not group.builtin or group.id == "favorites" then
            table.insert(assignableGroups, group)
        end
    end
    
    -- Filter out "favorites" from regular assignment (handled by isFavorite flag)
    local regularGroups = {}
    for _, group in ipairs(assignableGroups) do
        if group.id ~= "favorites" then
            table.insert(regularGroups, group)
        end
    end
    
    if #regularGroups == 0 then
        return assignments
    end
    
    for _, friend in ipairs(friends) do
        -- Generate UID
        local uid
        if friend.type == "bnet" then
            uid = "bnet_" .. friend.battleTag
        else
            uid = "wow_" .. friend.name
        end
        
        -- Decide if this friend gets assigned
        if math.random() < assignmentRatio then
            local friendGroups = {}
            
            if distribution == "random" then
                -- Random single group
                local group = regularGroups[math.random(#regularGroups)]
                table.insert(friendGroups, group.id)
                
                -- Maybe add to additional groups
                if math.random() < multiGroupRatio then
                    local secondGroup = regularGroups[math.random(#regularGroups)]
                    if secondGroup.id ~= group.id then
                        table.insert(friendGroups, secondGroup.id)
                    end
                end
                
            elseif distribution == "even" then
                -- Distribute evenly across groups
                local groupIndex = ((_ - 1) % #regularGroups) + 1
                local group = regularGroups[groupIndex]
                table.insert(friendGroups, group.id)
                
            elseif distribution == "weighted" then
                -- First groups get more members
                local roll = math.random()
                local groupIndex
                if roll < 0.4 then
                    groupIndex = 1
                elseif roll < 0.7 then
                    groupIndex = math.min(2, #regularGroups)
                elseif roll < 0.85 then
                    groupIndex = math.min(3, #regularGroups)
                else
                    groupIndex = math.random(#regularGroups)
                end
                local group = regularGroups[groupIndex]
                table.insert(friendGroups, group.id)
            end
            
            if #friendGroups > 0 then
                assignments[uid] = friendGroups
            end
        end
    end
    
    return assignments
end

-- ============================================
-- RAID GENERATION
-- ============================================

--[[
    Generate raid member data
    
    @param options table:
        - size (number): Raid size (5, 10, 20, 25, 40)
        - composition (string): "standard_20", "mythic_20", "lfr_25", etc.
        - tanks (number): Override tank count
        - healers (number): Override healer count
        - fillWithClasses (table): Specific classes to include
    
    @return table: Array of raid member data
]]
function MockDataProvider:GenerateRaidMembers(options)
    options = options or {}
    
    local Constants = BFL.TestData and BFL.TestData.Constants
    
    -- Get composition
    local comp
    if options.composition and Constants and Constants.RaidCompositions[options.composition] then
        comp = Constants.RaidCompositions[options.composition]
    else
        comp = {
            size = options.size or 20,
            tanks = options.tanks or 2,
            healers = options.healers or 4,
            dps = (options.size or 20) - (options.tanks or 2) - (options.healers or 4),
        }
    end
    
    local members = {}
    
    -- Generate tanks
    local tankClasses = Constants and Constants.TankClasses or {
        {classID = 1, spec = "Protection"},
        {classID = 2, spec = "Protection"},
        {classID = 11, spec = "Guardian"},
    }
    
    for i = 1, comp.tanks do
        local tankClass = tankClasses[(i - 1) % #tankClasses + 1]
        local classInfo = Constants and Constants.Classes[tankClass.classID] or {classID = tankClass.classID, name = "Warrior", file = "WARRIOR"}
        
        table.insert(members, {
            name = self:GetUniqueName(),
            rank = i == 1 and 2 or 1,  -- First tank is raid leader
            subgroup = 1,
            level = 80,
            class = classInfo.name,
            fileName = classInfo.file,
            zone = Constants and Constants:GetRandomZone(Constants.RaidLocations) or "Nerub-ar Palace",
            online = true,
            isDead = false,
            role = "MAINTANK",
            isML = i == 1,
            combatRole = "TANK",
            _isMock = true,
        })
    end
    
    -- Generate healers
    local healerClasses = Constants and Constants.HealerClasses or {
        {classID = 2, spec = "Holy"},
        {classID = 5, spec = "Holy"},
        {classID = 11, spec = "Restoration"},
    }
    
    for i = 1, comp.healers do
        local healerClass = healerClasses[(i - 1) % #healerClasses + 1]
        local classInfo = Constants and Constants.Classes[healerClass.classID] or {classID = healerClass.classID, name = "Priest", file = "PRIEST"}
        
        table.insert(members, {
            name = self:GetUniqueName(),
            rank = 1,
            subgroup = math.ceil((comp.tanks + i) / 5),
            level = 80,
            class = classInfo.name,
            fileName = classInfo.file,
            zone = Constants and Constants:GetRandomZone(Constants.RaidLocations) or "Nerub-ar Palace",
            online = true,
            isDead = false,
            role = "MAINASSIST",
            isML = false,
            combatRole = "HEALER",
            _isMock = true,
        })
    end
    
    -- Generate DPS
    for i = 1, comp.dps do
        local classInfo
        if Constants then
            classInfo = Constants:GetWeightedRandomClass()
        else
            classInfo = {classID = 1, name = "Warrior", file = "WARRIOR"}
        end
        
        table.insert(members, {
            name = self:GetUniqueName(),
            rank = 0,
            subgroup = math.ceil((comp.tanks + comp.healers + i) / 5),
            level = 80,
            class = classInfo.name,
            fileName = classInfo.file,
            zone = Constants and Constants:GetRandomZone(Constants.RaidLocations) or "Nerub-ar Palace",
            online = true,
            isDead = math.random() < 0.05,  -- 5% chance dead
            role = nil,
            isML = false,
            combatRole = "DAMAGER",
            _isMock = true,
        })
    end
    
    return members
end

-- ============================================
-- QUICKJOIN GROUP GENERATION
-- ============================================

--[[
    Generate QuickJoin group data
    
    @param count number: Number of groups to generate
    @param options table:
        - activityTypes (table): Array of activity type strings
        - includeKeys (boolean): Include M+ key groups
        - keyLevelDistribution (table): Override key level distribution
    
    @return table: Array of QuickJoin group data
]]
function MockDataProvider:GenerateQuickJoinGroups(count, options)
    options = options or {}
    count = count or 10
    
    local Constants = BFL.TestData and BFL.TestData.Constants
    
    local groups = {}
    
    local activityTypes = options.activityTypes or {"dungeon", "raid", "arena", "battleground", "delve"}
    
    for i = 1, count do
        local activityType = activityTypes[math.random(#activityTypes)]
        
        local group = {
            groupID = i,
            leaderName = self:GetUniqueName(),
            activityType = activityType,
            memberCount = math.random(1, 5),
            maxMembers = 5,
            _isMock = true,
        }
        
        -- Add activity-specific data
        if activityType == "dungeon" then
            local dungeons = Constants and Constants.DungeonLocations or {"The Stonevault", "Darkflame Cleft"}
            group.dungeon = dungeons[math.random(#dungeons)]
            
            if options.includeKeys ~= false and math.random() < 0.6 then
                -- M+ group
                if Constants then
                    group.keyLevel = Constants:GetRandomKeyLevel()
                else
                    group.keyLevel = math.random(2, 20)
                end
                group.activityName = group.dungeon .. " +" .. group.keyLevel
            else
                local difficulties = {"Normal", "Heroic", "Mythic"}
                group.difficulty = difficulties[math.random(#difficulties)]
                group.activityName = group.difficulty .. " " .. group.dungeon
            end
            
        elseif activityType == "raid" then
            local raids = Constants and Constants.RaidLocations or {"Nerub-ar Palace"}
            group.raid = raids[math.random(#raids)]
            local difficulties = {"LFR", "Normal", "Heroic", "Mythic"}
            group.difficulty = difficulties[math.random(#difficulties)]
            group.activityName = group.difficulty .. " " .. group.raid
            group.maxMembers = group.difficulty == "Mythic" and 20 or 30
            group.memberCount = math.random(5, group.maxMembers - 5)
            
        elseif activityType == "arena" then
            local arenaTypes = {"2v2", "3v3", "Skirmish"}
            group.arenaType = arenaTypes[math.random(#arenaTypes)]
            group.activityName = group.arenaType .. " Arena"
            group.maxMembers = group.arenaType == "2v2" and 2 or 3
            group.memberCount = math.random(1, group.maxMembers)
            
        elseif activityType == "battleground" then
            local bgs = Constants and Constants.BattlegroundLocations or {"Warsong Gulch", "Arathi Basin"}
            group.battleground = bgs[math.random(#bgs)]
            local bgTypes = {"Random", "Epic", "Rated"}
            group.bgType = bgTypes[math.random(#bgTypes)]
            group.activityName = group.bgType .. " BG - " .. group.battleground
            group.maxMembers = 5
            
        elseif activityType == "delve" then
            local delveTypes = {"Solo", "Group"}
            group.delveType = delveTypes[math.random(#delveTypes)]
            group.tier = math.random(1, 11)
            group.activityName = "Delve T" .. group.tier .. " (" .. group.delveType .. ")"
            group.maxMembers = 5
        end
        
        table.insert(groups, group)
    end
    
    return groups
end

-- ============================================
-- SCENARIO GENERATION
-- ============================================

--[[
    Generate complete mock data based on a scenario definition
    
    @param scenario table: Scenario configuration
        - friends (table): Friend generation options
        - groups (table): Group generation options
        - raid (table): Raid generation options (optional)
        - quickJoin (table): QuickJoin options (optional)
    
    @return table: Complete mock data structure
]]
function MockDataProvider:GenerateFromScenario(scenario)
    self:Reset()
    
    local data = {
        friends = {},
        groups = {},
        groupAssignments = {},
        raid = nil,
        quickJoinGroups = {},
    }
    
    -- Generate groups first (needed for assignments)
    if scenario.groups then
        local groupCount = scenario.groups.count or 5
        local groupOptions = {
            includeBuiltin = scenario.groups.includeBuiltin ~= false,
            customGroups = scenario.groups.customGroups,
        }
        data.groups = self:GenerateGroups(groupCount, groupOptions)
    else
        data.groups = self:GenerateGroups(5)
    end
    
    -- Generate friends
    if scenario.friends then
        local bnetCount = scenario.friends.bnet and scenario.friends.bnet.count or 0
        local wowCount = scenario.friends.wow and scenario.friends.wow.count or 0
        
        -- Generate BNet friends
        if bnetCount > 0 then
            local bnetOptions = scenario.friends.bnet or {}
            local bnetFriends = self:GenerateFriends(bnetCount, {
                onlineRatio = bnetOptions.onlineRatio or 0.4,
                wowRatio = bnetOptions.wowRatio or 0.7,
                favoriteRatio = bnetOptions.favoriteRatio or 0.08,
                noteRatio = bnetOptions.noteRatio or 0.25,
                internationalRatio = bnetOptions.includeInternational and 0.1 or 0,
                bnetRatio = 1.0,  -- All BNet
            })
            for _, friend in ipairs(bnetFriends) do
                table.insert(data.friends, friend)
            end
        end
        
        -- Generate WoW friends
        if wowCount > 0 then
            local wowOptions = scenario.friends.wow or {}
            local wowFriends = self:GenerateFriends(wowCount, {
                onlineRatio = wowOptions.onlineRatio or 0.3,
                noteRatio = wowOptions.noteRatio or 0.2,
                bnetRatio = 0.0,  -- All WoW
            })
            for _, friend in ipairs(wowFriends) do
                table.insert(data.friends, friend)
            end
        end
        
    else
        -- Default: 50 friends
        data.friends = self:GenerateFriends(50)
    end
    
    -- Assign friends to groups
    if scenario.groups then
        local assignOptions = {
            distribution = scenario.groups.friendDistribution or "random",
            assignmentRatio = scenario.groups.assignmentRatio or 0.7,
            multiGroupRatio = scenario.groups.multiGroupRatio or 0.1,
        }
        data.groupAssignments = self:AssignFriendsToGroups(data.friends, data.groups, assignOptions)
    else
        data.groupAssignments = self:AssignFriendsToGroups(data.friends, data.groups)
    end
    
    -- Generate raid if configured
    if scenario.raid then
        data.raid = self:GenerateRaidMembers(scenario.raid)
    end
    
    -- Generate QuickJoin groups if configured
    if scenario.quickJoin then
        local qjCount = scenario.quickJoin.count or scenario.quickJoin.groups or 10
        data.quickJoinGroups = self:GenerateQuickJoinGroups(qjCount, {
            activityTypes = scenario.quickJoin.types,
            includeKeys = scenario.quickJoin.includeKeys ~= false,
        })
    end
    
    -- Store as current data
    self.currentData = data
    
    return data
end

-- ============================================
-- PRESET SCENARIOS
-- ============================================

MockDataProvider.Presets = {
    -- Stress test with 200 friends
    stress_200 = {
        name = "Stress Test: 200 Friends",
        description = "200 friends for performance testing",
        friends = {
            bnet = {count = 150, onlineRatio = 0.4, wowRatio = 0.7, favoriteRatio = 0.1},
            wow = {count = 50, onlineRatio = 0.3},
        },
        groups = {count = 8, friendDistribution = "random"},
        quickJoin = {count = 15},
    },
    
    -- Maximum stress test
    stress_500 = {
        name = "Stress Test: 500 Friends",
        description = "500 friends for extreme performance testing",
        friends = {
            bnet = {count = 400, onlineRatio = 0.3, wowRatio = 0.6},
            wow = {count = 100, onlineRatio = 0.2},
        },
        groups = {count = 10, friendDistribution = "weighted"},
        quickJoin = {count = 30},
    },
    
    -- Mythic raid scenario
    raid_mythic = {
        name = "Mythic Raid",
        description = "20-man mythic raid composition",
        friends = {
            bnet = {count = 30, onlineRatio = 0.8, wowRatio = 0.95},
        },
        groups = {count = 1, customGroups = {{name = "Raid Team", color = {r = 1, g = 0.4, b = 0.4}}}},
        raid = {composition = "mythic_20"},
    },
    
    -- Small dungeon group
    dungeon_5 = {
        name = "Dungeon Group",
        description = "5-man dungeon group",
        friends = {
            bnet = {count = 10, onlineRatio = 0.6, wowRatio = 0.9},
        },
        groups = {count = 2, customGroups = {
            {name = "M+ Team", color = {r = 0.4, g = 0.8, b = 1}},
            {name = "Alts", color = {r = 0.5, g = 0.8, b = 0.5}},
        }},
        raid = {composition = "dungeon_5"},
    },
    
    -- International fonts test
    international = {
        name = "International Names",
        description = "Friends with Korean, Chinese, Japanese, Russian names",
        friends = {
            bnet = {count = 50, onlineRatio = 0.6, includeInternational = true},
        },
        groups = {count = 5, customGroups = {
            {name = "한국어 (KR)", color = {r = 0.4, g = 1, b = 0.4}},
            {name = "中文 (CN)", color = {r = 1, g = 0.4, b = 0.4}},
            {name = "日本語 (JP)", color = {r = 1, g = 0.6, b = 0.8}},
            {name = "Русский (RU)", color = {r = 0.4, g = 0.4, b = 1}},
        }},
    },
    
    -- Classic mode simulation
    classic_mode = {
        name = "Classic Mode",
        description = "WoW-only friends, no BNet features",
        friends = {
            wow = {count = 50, onlineRatio = 0.3},
        },
        groups = {count = 3},
    },
    
    -- Empty state
    empty = {
        name = "Empty State",
        description = "No friends, no groups - clean slate",
        friends = {},
        groups = {count = 0, includeBuiltin = true},
    },
    
    -- QuickJoin focused
    quickjoin_full = {
        name = "QuickJoin Full",
        description = "30 active QuickJoin groups",
        friends = {
            bnet = {count = 40, onlineRatio = 0.7, wowRatio = 0.9},
        },
        groups = {count = 2},
        quickJoin = {count = 30, types = {"dungeon", "raid", "arena", "battleground", "delve"}},
    },
}

--[[
    Load a preset scenario
    
    @param presetName string: Name of the preset
    @return table: Generated mock data
]]
function MockDataProvider:LoadPreset(presetName)
    local preset = self.Presets[presetName]
    if not preset then
        BFL:DebugPrint("|cffff0000MockDataProvider:|r Unknown preset: " .. tostring(presetName))
        return nil
    end
    
    BFL:DebugPrint("|cff00ffffMockDataProvider:|r Loading preset: " .. preset.name)
    return self:GenerateFromScenario(preset)
end

--[[
    List all available presets
    
    @return table: Array of {name, description} pairs
]]
function MockDataProvider:ListPresets()
    local list = {}
    for name, preset in pairs(self.Presets) do
        table.insert(list, {
            id = name,
            name = preset.name,
            description = preset.description,
        })
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- ============================================
-- DEBUG / TESTING
-- ============================================

function MockDataProvider:PrintStats()
    local data = self.currentData
    
    print("|cff00ff00BFL MockDataProvider Statistics:|r")
    print("  |cffffffffFriends:|r " .. #data.friends)
    print("  |cffffffffGroups:|r " .. #data.groups)
    
    local assignmentCount = 0
    for _ in pairs(data.groupAssignments) do
        assignmentCount = assignmentCount + 1
    end
    print("  |cffffffffGroup Assignments:|r " .. assignmentCount)
    
    if data.raid then
        print("  |cffffffffRaid Members:|r " .. #data.raid)
    end
    
    print("  |cffffffffQuickJoin Groups:|r " .. #data.quickJoinGroups)
    
    -- Count online friends
    local onlineCount = 0
    for _, friend in ipairs(data.friends) do
        if friend.connected then
            onlineCount = onlineCount + 1
        end
    end
    print("  |cffffffffOnline Friends:|r " .. onlineCount .. "/" .. #data.friends)
end

return MockDataProvider
