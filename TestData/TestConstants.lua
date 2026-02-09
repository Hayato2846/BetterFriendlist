-- TestData/TestConstants.lua
-- Constants for Mock Data Generation and Test Scenarios
--
-- Contains:
-- 1. Class definitions (all WoW classes with appropriate data)
-- 2. Zone lists (current expansion + popular zones)
-- 3. Game client programs (Battle.net apps)
-- 4. Status distributions
-- 5. Activity types (dungeons, raids, PvP, etc.)
-- 6. Level distributions by content type

local ADDON_NAME, BFL = ...

BFL.TestData = BFL.TestData or {}
BFL.TestData.Constants = {}

local Constants = BFL.TestData.Constants

-- ============================================
-- CLASS DEFINITIONS
-- ============================================

Constants.Classes = {
    {classID = 1,  name = "Warrior",      file = "WARRIOR",     color = {0.78, 0.61, 0.43}},
    {classID = 2,  name = "Paladin",      file = "PALADIN",     color = {0.96, 0.55, 0.73}},
    {classID = 3,  name = "Hunter",       file = "HUNTER",      color = {0.67, 0.83, 0.45}},
    {classID = 4,  name = "Rogue",        file = "ROGUE",       color = {1.00, 0.96, 0.41}},
    {classID = 5,  name = "Priest",       file = "PRIEST",      color = {1.00, 1.00, 1.00}},
    {classID = 6,  name = "Death Knight", file = "DEATHKNIGHT", color = {0.77, 0.12, 0.23}},
    {classID = 7,  name = "Shaman",       file = "SHAMAN",      color = {0.00, 0.44, 0.87}},
    {classID = 8,  name = "Mage",         file = "MAGE",        color = {0.41, 0.80, 0.94}},
    {classID = 9,  name = "Warlock",      file = "WARLOCK",     color = {0.58, 0.51, 0.79}},
    {classID = 10, name = "Monk",         file = "MONK",        color = {0.00, 1.00, 0.59}},
    {classID = 11, name = "Druid",        file = "DRUID",       color = {1.00, 0.49, 0.04}},
    {classID = 12, name = "Demon Hunter", file = "DEMONHUNTER", color = {0.64, 0.19, 0.79}},
    {classID = 13, name = "Evoker",       file = "EVOKER",      color = {0.20, 0.58, 0.50}},
}

-- Class distribution weights (based on typical population)
-- Higher weight = more common
Constants.ClassWeights = {
    [1]  = 10, -- Warrior (popular)
    [2]  = 12, -- Paladin (very popular)
    [3]  = 11, -- Hunter (popular)
    [4]  = 9,  -- Rogue
    [5]  = 10, -- Priest
    [6]  = 8,  -- Death Knight
    [7]  = 7,  -- Shaman
    [8]  = 9,  -- Mage
    [9]  = 6,  -- Warlock
    [10] = 6,  -- Monk
    [11] = 10, -- Druid (popular)
    [12] = 7,  -- Demon Hunter
    [13] = 5,  -- Evoker (newer, less common)
}

-- Classes available in Classic (no DK, DH, Monk, Evoker)
Constants.ClassicClasses = {1, 2, 3, 4, 5, 7, 8, 9, 11}

-- Classes available in TBC Classic (adds nothing, but DK in Wrath)
Constants.TBCClasses = {1, 2, 3, 4, 5, 7, 8, 9, 11}

-- Classes available in Wrath Classic (adds DK)
Constants.WrathClasses = {1, 2, 3, 4, 5, 6, 7, 8, 9, 11}

-- Classes available in Cata Classic (same as Wrath)
Constants.CataClasses = {1, 2, 3, 4, 5, 6, 7, 8, 9, 11}

-- Classes available in MoP Classic (adds Monk)
Constants.MoPClasses = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- ============================================
-- ZONE LISTS
-- ============================================

-- The War Within zones (current expansion)
Constants.TWWZones = {
    "Dornogal", "The Ringing Deeps", "Hallowfall", "Azj-Kahet", "Isle of Dorn",
    "City of Threads", "Priory of the Sacred Flame", "Cinderbrew Meadery",
    "Ara-Kara, City of Echoes", "The Stonevault", "Darkflame Cleft", "The Dawnbreaker",
    "Nerub-ar Palace", "The Rookery", "Zekvir's Lair",
}

-- Dragonflight zones
Constants.DFZones = {
    "Valdrakken", "The Waking Shores", "Ohn'ahran Plains", "The Azure Span",
    "Thaldraszus", "Zaralek Cavern", "Emerald Dream", "Forbidden Reach",
}

-- Shadowlands zones
Constants.SLZones = {
    "Oribos", "Bastion", "Maldraxxus", "Ardenweald", "Revendreth", "The Maw",
    "Korthia", "Zereth Mortis",
}

-- Capital cities
Constants.Capitals = {
    "Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Darnassus",
    "Undercity", "Silvermoon City", "The Exodar", "Dalaran", "Shattrath City",
    "Boralus", "Dazar'alor",
}

-- Popular legacy zones
Constants.LegacyZones = {
    "Tanaris", "Winterspring", "Eastern Plaguelands", "Silithus", "Felwood",
    "Burning Steppes", "Blasted Lands", "Netherstorm", "Blade's Edge Mountains",
    "Icecrown", "Storm Peaks", "Uldum", "Deepholm", "Twilight Highlands",
}

-- Raid locations (for raid frame testing)
Constants.RaidLocations = {
    "Nerub-ar Palace", "Amirdrassil, the Dream's Hope", "Aberrus, the Shadowed Crucible",
    "Vault of the Incarnates", "Sanctum of Domination", "Castle Nathria",
    "Sepulcher of the First Ones", "Ny'alotha, the Waking City",
}

-- Dungeon locations (for M+ testing)
Constants.DungeonLocations = {
    "Ara-Kara, City of Echoes", "The Stonevault", "Darkflame Cleft", "The Dawnbreaker",
    "City of Threads", "Priory of the Sacred Flame", "Cinderbrew Meadery", "The Rookery",
    "Dawn of the Infinite", "Brackenhide Hollow", "Ruby Life Pools", "Algeth'ar Academy",
}

-- Arena locations
Constants.ArenaLocations = {
    "Blade's Edge Arena", "Nagrand Arena", "Ruins of Lordaeron", "Dalaran Sewers",
    "The Tiger's Peak", "Tol'viron Arena", "Ashamane's Fall", "Hook Point",
}

-- Battleground locations
Constants.BattlegroundLocations = {
    "Warsong Gulch", "Arathi Basin", "Alterac Valley", "Eye of the Storm",
    "Strand of the Ancients", "Isle of Conquest", "Twin Peaks", "Battle for Gilneas",
    "Silvershard Mines", "Temple of Kotmogu", "Deepwind Gorge", "Ashran",
}

-- ============================================
-- GAME CLIENTS (Battle.net)
-- ============================================

Constants.GameClients = {
    {program = "WoW",  name = "World of Warcraft",  weight = 60},
    {program = "D4",   name = "Diablo IV",          weight = 15},
    {program = "Pro",  name = "Overwatch 2",        weight = 10},
    {program = "WTCG", name = "Hearthstone",        weight = 8},
    {program = "Hero", name = "Heroes of the Storm", weight = 2},
    {program = "D3",   name = "Diablo III",         weight = 2},
    {program = "S2",   name = "StarCraft II",       weight = 1},
    {program = "BSAp", name = "Battle.net",         weight = 2},
}

-- WoW project IDs (for different WoW versions)
Constants.WoWProjects = {
    retail = 1,
    classic_era = 2,
    classic_tbc = 5,
    classic_wrath = 11,
    classic_cata = 14,
    classic_mop = 17,  -- Estimated
}

-- ============================================
-- STATUS DISTRIBUTIONS
-- ============================================

-- Player status distribution (for online friends)
Constants.StatusDistribution = {
    available = 0.70,  -- 70% available
    afk = 0.15,        -- 15% AFK
    dnd = 0.10,        -- 10% DND
    busy = 0.05,       -- 5% busy
}

-- Online ratio by time of day (for realistic scenarios)
Constants.OnlineRatioByTime = {
    morning = 0.20,    -- 6am-12pm
    afternoon = 0.35,  -- 12pm-6pm
    evening = 0.60,    -- 6pm-10pm (peak)
    night = 0.40,      -- 10pm-2am
    late_night = 0.15, -- 2am-6am
}

-- Favorite ratio
Constants.FavoriteRatio = 0.08  -- ~8% of friends are favorites

-- Note ratio (friends with notes)
Constants.NoteRatio = 0.25  -- ~25% have notes

-- ============================================
-- LEVEL DISTRIBUTIONS
-- ============================================

-- Level distribution for current content
Constants.CurrentLevelDistribution = {
    {min = 80, max = 80, weight = 70},  -- Max level
    {min = 70, max = 79, weight = 20},  -- Leveling
    {min = 60, max = 69, weight = 5},   -- Previous expansion
    {min = 1,  max = 59, weight = 5},   -- Alts/new players
}

-- Level distribution for Classic
Constants.ClassicLevelDistribution = {
    {min = 60, max = 60, weight = 60},  -- Max level
    {min = 50, max = 59, weight = 20},
    {min = 30, max = 49, weight = 15},
    {min = 1,  max = 29, weight = 5},
}

-- Level distribution for Wrath Classic
Constants.WrathLevelDistribution = {
    {min = 80, max = 80, weight = 65},
    {min = 70, max = 79, weight = 20},
    {min = 55, max = 69, weight = 10},
    {min = 1,  max = 54, weight = 5},
}

-- Level distribution for Cata Classic
Constants.CataLevelDistribution = {
    {min = 85, max = 85, weight = 65},
    {min = 80, max = 84, weight = 20},
    {min = 60, max = 79, weight = 10},
    {min = 1,  max = 59, weight = 5},
}

-- ============================================
-- QUICKJOIN / ACTIVITY TYPES
-- ============================================

Constants.ActivityTypes = {
    dungeon = {
        name = "Dungeon",
        subtypes = {"Normal", "Heroic", "Mythic", "Mythic+"},
        weight = 40,
    },
    raid = {
        name = "Raid",
        subtypes = {"LFR", "Normal", "Heroic", "Mythic"},
        weight = 20,
    },
    arena = {
        name = "Arena",
        subtypes = {"2v2", "3v3", "Skirmish"},
        weight = 15,
    },
    battleground = {
        name = "Battleground",
        subtypes = {"Random", "Epic", "Rated"},
        weight = 15,
    },
    scenario = {
        name = "Scenario",
        subtypes = {"Normal", "Heroic"},
        weight = 5,
    },
    delve = {
        name = "Delve",
        subtypes = {"Solo", "Group"},
        weight = 5,
    },
}

-- M+ key levels distribution
Constants.KeyLevelDistribution = {
    {min = 2,  max = 5,  weight = 20},  -- Low keys
    {min = 6,  max = 10, weight = 35},  -- Mid keys
    {min = 11, max = 15, weight = 30},  -- High keys
    {min = 16, max = 20, weight = 12},  -- Very high keys
    {min = 21, max = 30, weight = 3},   -- Extreme keys
}

-- ============================================
-- RAID COMPOSITION
-- ============================================

Constants.RaidCompositions = {
    standard_20 = {
        size = 20,
        tanks = 2,
        healers = 4,
        dps = 14,
    },
    heroic_25 = {
        size = 25,
        tanks = 2,
        healers = 5,
        dps = 18,
    },
    mythic_20 = {
        size = 20,
        tanks = 2,
        healers = 4,
        dps = 14,
    },
    lfr_25 = {
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    classic_40 = {
        size = 40,
        tanks = 4,
        healers = 12,
        dps = 24,
    },
    dungeon_5 = {
        size = 5,
        tanks = 1,
        healers = 1,
        dps = 3,
    },
}

-- Tank classes
Constants.TankClasses = {
    {classID = 1,  spec = "Protection"},   -- Warrior
    {classID = 2,  spec = "Protection"},   -- Paladin
    {classID = 6,  spec = "Blood"},        -- Death Knight
    {classID = 10, spec = "Brewmaster"},   -- Monk
    {classID = 11, spec = "Guardian"},     -- Druid
    {classID = 12, spec = "Vengeance"},    -- Demon Hunter
}

-- Healer classes
Constants.HealerClasses = {
    {classID = 2,  spec = "Holy"},         -- Paladin
    {classID = 5,  spec = "Holy"},         -- Priest (Holy)
    {classID = 5,  spec = "Discipline"},   -- Priest (Disc)
    {classID = 7,  spec = "Restoration"},  -- Shaman
    {classID = 10, spec = "Mistweaver"},   -- Monk
    {classID = 11, spec = "Restoration"},  -- Druid
    {classID = 13, spec = "Preservation"}, -- Evoker
}

-- ============================================
-- GUILD NAMES FOR MOCK DATA
-- ============================================

Constants.GuildNames = {
    -- Serious raid guilds
    "Eternal Flame", "Phoenix Rising", "Legends Reborn", "Storm Riders", "Iron Legion",
    "Crimson Dawn", "Azure Knights", "Shadow Empire", "Golden Horde", "Silver Hand",
    
    -- Casual guilds
    "Friends and Family", "Weekend Warriors", "Casual Crew", "Alt Army", "Level Up",
    "Just For Fun", "Happy Pandas", "Chill Guild", "No Drama", "Good Times",
    
    -- Funny guilds
    "Pulls Before Homework", "We Wiped on Trash", "Press Alt F4", "Still Buffing",
    "AFK Since Beta", "Hogger Fan Club", "Murloc Appreciation Society", "Leeroy Was Right",
    
    -- International
    "황금용단", "龙之军团", "Русские Медведи", "Les Chevaliers",
    "Die Deutschen", "Los Conquistadores",
}

-- ============================================
-- FRIEND NOTE TEMPLATES
-- ============================================

Constants.NoteTemplates = {
    -- Social
    "Met in dungeon", "IRL friend", "College buddy", "Work colleague",
    "Brother/Sister", "Cousin", "Old guildmate", "From Discord",
    
    -- Gameplay
    "Good tank", "Great healer", "Crazy DPS", "M+ carry", "PvP partner",
    "Raid buddy", "Crafting alt", "Farming partner", "Quest helper",
    
    -- Trading
    "Sells herbs", "Buys ore", "Enchanter", "Jewelcrafter", "Blacksmith",
    "Alchemist", "Best AH prices", "Trade contact",
    
    -- Misc
    "Nice person", "Helpful", "Funny", "Always online", "Rarely plays",
    "Main is Warrior", "Has many alts", "Collector", "Achievement hunter",
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get a random class based on weights
function Constants:GetWeightedRandomClass(classicMode)
    local classes = classicMode and self.ClassicClasses or nil
    local totalWeight = 0
    local weightedClasses = {}
    
    if classes then
        for _, classID in ipairs(classes) do
            local weight = self.ClassWeights[classID] or 5
            totalWeight = totalWeight + weight
            table.insert(weightedClasses, {classID = classID, weight = weight})
        end
    else
        for classID, weight in pairs(self.ClassWeights) do
            totalWeight = totalWeight + weight
            table.insert(weightedClasses, {classID = classID, weight = weight})
        end
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, entry in ipairs(weightedClasses) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return self.Classes[entry.classID]
        end
    end
    
    return self.Classes[1]  -- Fallback to Warrior
end

-- Get a random zone from a pool
function Constants:GetRandomZone(pool)
    pool = pool or self.TWWZones
    return pool[math.random(#pool)]
end

-- Get a random level based on distribution
function Constants:GetRandomLevel(distribution)
    distribution = distribution or self.CurrentLevelDistribution
    local totalWeight = 0
    
    for _, range in ipairs(distribution) do
        totalWeight = totalWeight + range.weight
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, range in ipairs(distribution) do
        cumulative = cumulative + range.weight
        if roll <= cumulative then
            return math.random(range.min, range.max)
        end
    end
    
    return 80  -- Fallback
end

-- Get a random game client based on weights
function Constants:GetRandomGameClient()
    local totalWeight = 0
    for _, client in ipairs(self.GameClients) do
        totalWeight = totalWeight + client.weight
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, client in ipairs(self.GameClients) do
        cumulative = cumulative + client.weight
        if roll <= cumulative then
            return client
        end
    end
    
    return self.GameClients[1]  -- Fallback to WoW
end

-- Get a random status based on distribution
function Constants:GetRandomStatus()
    local roll = math.random()
    local cumulative = 0
    
    for status, weight in pairs(self.StatusDistribution) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return status
        end
    end
    
    return "available"
end

-- Get a random guild name
function Constants:GetRandomGuildName()
    return self.GuildNames[math.random(#self.GuildNames)]
end

-- Get a random note
function Constants:GetRandomNote()
    return self.NoteTemplates[math.random(#self.NoteTemplates)]
end

-- Get a random M+ key level
function Constants:GetRandomKeyLevel()
    local totalWeight = 0
    for _, range in ipairs(self.KeyLevelDistribution) do
        totalWeight = totalWeight + range.weight
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, range in ipairs(self.KeyLevelDistribution) do
        cumulative = cumulative + range.weight
        if roll <= cumulative then
            return math.random(range.min, range.max)
        end
    end
    
    return 10  -- Fallback
end

return Constants
