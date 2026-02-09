-- TestData/CharacterNames.lua
-- 500+ Character Names for Mock Data Generation
-- Contains lore characters, typical player names, and international names
--
-- Categories:
-- 1. Lore Characters (Alliance, Horde, Neutral)
-- 2. Typical Player Names (Fantasy, Edgy, Funny)
-- 3. International Names (Korean, Chinese, Russian, Japanese, etc.)
-- 4. BattleTag Pool

local ADDON_NAME, BFL = ...

-- ============================================
-- LORE CHARACTERS (200+ names)
-- ============================================

BFL.TestData = BFL.TestData or {}

BFL.TestData.LoreNames = {
    -- ===================
    -- ALLIANCE HEROES
    -- ===================
    "Anduin", "Jaina", "Genn", "Alleria", "Turalyon", "Velen", "Tyrande", "Malfurion",
    "Muradin", "Aysa", "Tess", "Shaw", "Magni", "Khadgar", "Valeera", "Moira",
    "Falstad", "Kurdran", "Gelbin", "Mekkatorque", "Varian", "Bolvar", "Lothar",
    "Uther", "Arthas", "Daelin", "Tandred", "Calia", "Faol", "Tirion",
    
    -- ===================
    -- HORDE HEROES
    -- ===================
    "Thrall", "Baine", "Lor'themar", "Thalyssra", "Gazlowe", "Rokhan", "Geya'rah",
    "Eitrigg", "Rexxar", "Zekhan", "Lilian", "Saurfang", "Nazgrel", "Jorin",
    "Garrosh", "Vol'jin", "Cairne", "Drek'Thar", "Orgrim", "Blackhand", "Gul'dan",
    "Kargath", "Kilrogg", "Grommash", "Durotan", "Draka", "Aggra",
    
    -- ===================
    -- NEUTRAL/DRAGON ASPECTS
    -- ===================
    "Chromie", "Wrathion", "Alexstrasza", "Ysera", "Nozdormu", "Kalecgos", "Ebonhorn",
    "Neltharion", "Deathwing", "Malygos", "Sindragosa", "Senegos", "Stellagosa",
    "Merithra", "Cenarius", "Elune", "Xal'atath", "N'Zoth", "Azshara",
    
    -- ===================
    -- WARCRAFT III CHARACTERS
    -- ===================
    "Medivh", "Aegwynn", "Kel'Thuzad", "Sylvanas", "Illidan", "Maiev", "Akama",
    "Kael'thas", "Lady Vashj", "Archimonde", "Kil'jaeden", "Mannoroth", "Sargeras",
    "Tichondrius", "Anetheron", "Velen", "Archimonde",
    
    -- ===================
    -- SHADOWLANDS CHARACTERS
    -- ===================
    "Bolvar", "Taelia", "Calia", "Bastion", "Pelagos", "Kleia", "Uther",
    "Draka", "Baroness", "Theotar", "Denathrius", "Renathal", "Anduin",
    "Thrall", "Jaina", "Baine", "Sylvanas", "Primus", "Zovaal",
    
    -- ===================
    -- DRAGONFLIGHT CHARACTERS
    -- ===================
    "Wrathion", "Sabellian", "Ebyssian", "Vyranoth", "Iridikron", "Fyrakk", "Laszta",
    "Raszageth", "Neltharion", "Nozdormu", "Chromie", "Soridormi", "Anachronos",
    
    -- ===================
    -- THE WAR WITHIN CHARACTERS
    -- ===================
    "Xal'atath", "Alleria", "Anduin", "Thrall", "Magni", "Moira", "Dagran",
    "Faerin", "Baelgrim", "Merrix", "Brann", "Adelgonn",
    
    -- ===================
    -- CLASSIC WOW BOSSES
    -- ===================
    "Ragnaros", "Onyxia", "Nefarian", "C'Thun", "Kel'Thuzad", "Hakkar", "Ossirian",
    "Chromaggus", "Firemaw", "Ebonroc", "Vaelastrasz", "Broodlord",
    
    -- ===================
    -- MISC LORE CHARACTERS
    -- ===================
    "Hemet", "Nesingwary", "Harrison", "Lorewalker", "Chen", "Lili", "Taran",
    "Wrynn", "Proudmoore", "Windrunner", "Bronzebeard", "Earthfury",
}

-- ============================================
-- TYPICAL PLAYER NAMES (200+ names)
-- ============================================

BFL.TestData.PlayerNames = {
    -- ===================
    -- FANTASY/EPIC NAMES
    -- ===================
    "Shadowblade", "Lightforge", "Stormwind", "Ironhammer", "Darkflame", "Frostweaver",
    "Sunfire", "Moonshade", "Earthshaker", "Windwalker", "Bloodfang", "Steelclaw",
    "Nightwhisper", "Dawnbringer", "Fireheart", "Icefury", "Thunderstrike", "Soulkeeper",
    "Starseeker", "Voidwalker", "Felguard", "Spiritbinder", "Stormrage", "Proudmoore",
    "Duskblade", "Sunstrider", "Nightborne", "Starfall", "Moonshadow", "Lightbringer",
    "Darkweaver", "Flamestrike", "Iceborn", "Stormcaller", "Shadowmend", "Holybolt",
    
    -- ===================
    -- CLASS-THEMED NAMES
    -- ===================
    "Holypally", "Retbull", "Tankadin", "Bubbleheart", "Crusaderx", "Divinelight",
    "Arcanemage", "Frostbolt", "Fireblast", "Pyroblast", "Blizzardx", "Spellweaver",
    "Stabstab", "Sinister", "Ambushx", "Backstabber", "Shadowstep", "Vanishx",
    "Huntardx", "Pewpewx", "Beastmaster", "Marksmanx", "Petlover", "Bowmaster",
    "Healbot", "Holypriest", "Shadowform", "Disciplinex", "Smitex", "Lightwell",
    "Demonwrath", "Afflictionx", "Lifetapx", "Soulstone", "Doomguard", "Impmaster",
    "Naturex", "Moonfire", "Bearform", "Catdps", "Treehuger", "Boomkin",
    "Totemplz", "Chainlightning", "Lavaburst", "Earthshock", "Healingwave", "Spiritlink",
    "Deathgrip", "Runicpower", "Frostfever", "Bloodboil", "Unholydk", "Lichking",
    "Chiwave", "Mistweaver", "Windwalkerx", "Brewmasterx", "Tigerpalm", "Blackoutx",
    "Metamorph", "Eyebeamx", "Havocx", "Demonsoulx", "Felrush", "Vengefulx",
    "Bronzewingx", "Evokerx", "Devastationx", "Preservationx", "Augmentationx", "Soarx",
    
    -- ===================
    -- EDGY NAMES
    -- ===================
    "Deathbringer", "Soulcrusher", "Darknessx", "Voidlordx", "Demonslayer", "Nightstalker",
    "Bloodreaver", "Shadowlordx", "Grimdeath", "Bonecrush", "Skullsplitter", "Nightterror",
    "Darkempire", "Hellfire", "Doomhammer", "Soulreaper", "Deathwhisper", "Voidheart",
    
    -- ===================
    -- FUNNY/MEME NAMES
    -- ===================
    "Legolas", "Aragorn", "Gandalf", "Frodobaggins", "Samwisex", "Gimlix",
    "Chuckynorris", "Ipwnnoobs", "Leetskillz", "Omgwtfbbq", "Roflcopter", "Pwnyou",
    "Tankspanks", "Healzplz", "Dpsmeter", "Aggrobait", "Lootmaster", "Ninjaloot",
    "Keyboardcat", "Nyancat", "Dogemoon", "Shreksbank", "Thanosdid", "BigChungus",
    "Stonkmaster", "Diamondhands", "Moonlambo", "Yolobro", "Hodlgang", "Pepehands",
    
    -- ===================
    -- SIMPLE NAMES
    -- ===================
    "Alex", "Jake", "Mike", "Sarah", "Emma", "John", "David", "Chris", "Matt", "Dan",
    "Sam", "Tom", "Nick", "Ben", "Joe", "Max", "Ryan", "Sean", "Mark", "Paul",
    "Alexia", "Emily", "Sophie", "Amanda", "Rachel", "Lauren", "Jessica", "Nicole",
    
    -- ===================
    -- REALM-SPECIFIC NAMES
    -- ===================
    "Dalaranmage", "Stormwindknight", "Orgrimwarrior", "Thunderbluff", "Silvermoonelf",
    "Ironforgesmith", "Undercityxx", "Exodarpriest", "Gilneaswolf", "Teldrassiltree",
}

-- ============================================
-- INTERNATIONAL NAMES (100+ names)
-- ============================================

BFL.TestData.InternationalNames = {
    -- ===================
    -- KOREAN (한국어)
    -- ===================
    korean = {
        "안녕하세요", "서울용사", "한국전사", "달빛기사", "불꽃마법사", "얼음술사",
        "번개주술사", "초록드루이드", "검은암살자", "빛의성기사", "어둠사제", "영혼술사",
        "용의기사", "별의수호자", "달의전사", "태양의불꽃", "바람의검", "대지의힘",
        "푸른하늘", "붉은달", "검은밤", "흰눈", "금빛용", "은빛별",
    },
    
    -- ===================
    -- SIMPLIFIED CHINESE (简体中文)
    -- ===================
    chinese_simplified = {
        "你好世界", "暴风城勇士", "奥格瑞玛战士", "达拉然法师", "铁炉堡矮人", "雷电王座",
        "艾泽拉斯", "燃烧军团", "联盟英雄", "部落勇士", "熊猫人", "龙族",
        "死亡骑士", "恶魔猎手", "唤魔师", "武僧大师", "德鲁伊", "萨满祭司",
        "圣骑士", "术士大人", "牧师光明", "盗贼暗影", "猎人野兽", "战士狂怒",
    },
    
    -- ===================
    -- TRADITIONAL CHINESE (繁體中文)
    -- ===================
    chinese_traditional = {
        "哈囉世界", "暴風城勇士", "奧格瑞瑪戰士", "達拉然法師", "鐵爐堡矮人", "雷電王座",
        "艾澤拉斯", "燃燒軍團", "聯盟英雄", "部落勇士", "熊貓人", "龍族",
        "死亡騎士", "惡魔獵人", "喚魔師", "武僧大師", "德魯伊", "薩滿祭司",
    },
    
    -- ===================
    -- RUSSIAN (Русский)
    -- ===================
    russian = {
        "Россия", "Ледяной", "Огненный", "Темный", "Светлый", "Грозовой",
        "Штормград", "Оргриммар", "Даларан", "Стальгорн", "Дренор", "Азерот",
        "Паладин", "Воин", "Маг", "Разбойник", "Охотник", "Жрец",
        "Шаман", "Друид", "Чернокнижник", "Рыцарь", "Монах", "Эвокер",
    },
    
    -- ===================
    -- JAPANESE (日本語)
    -- ===================
    japanese = {
        "こんにちは", "炎の勇者", "氷の魔法使い", "雷の戦士", "影の忍者", "光の騎士",
        "ドラゴン", "エルフ", "ドワーフ", "オーク", "トロール", "タウレン",
        "パラディン", "ウォーリア", "メイジ", "ローグ", "ハンター", "プリースト",
        "シャーマン", "ドルイド", "ウォーロック", "デスナイト", "モンク", "エヴォカー",
    },
    
    -- ===================
    -- GERMAN (Deutsch)
    -- ===================
    german = {
        "Sturmwind", "Eisenschmiede", "Donnerfels", "Silbermond", "Dalaran", "Orgrimmar",
        "Feuersturm", "Eiszauber", "Blitzeinschlag", "Schattentanz", "Lichtbringer", "Dunkelheit",
    },
    
    -- ===================
    -- FRENCH (Français)
    -- ===================
    french = {
        "Hurlevent", "Forgefer", "Tonnerre", "Lune'argent", "Dalaran", "Orgrimmar",
        "Tempêtefeu", "Glacesorcel", "Éclairfoudre", "Ombredanse", "Porteur'lumière", "Ténèbres",
    },
    
    -- ===================
    -- SPANISH (Español)
    -- ===================
    spanish = {
        "Ventormenta", "Forjahierro", "Cima'trueno", "Lunaplateada", "Dalaran", "Orgrimmar",
        "Tormentafuego", "Hielohechizo", "Relampagueo", "Sombradanza", "Portadorluz", "Oscuridad",
    },
    
    -- ===================
    -- PORTUGUESE (Português)
    -- ===================
    portuguese = {
        "Ventobravo", "Forjaferro", "Cimadotrovão", "Luaprateada", "Dalaran", "Orgrimmar",
        "Tempestafogo", "Gelofeitiço", "Relâmpago", "Dançasombra", "Portadordaluz", "Escuridão",
    },
}

-- ============================================
-- BATTLETAG POOL (100+ tags)
-- ============================================

BFL.TestData.BattleTags = {
    -- ===================
    -- LORE-BASED
    -- ===================
    "Anduin#1234", "Jaina#5678", "Thrall#9012", "Sylvanas#3456", "Bolvar#7890",
    "Illidan#2345", "Tyrande#6789", "Malfurion#0123", "Arthas#4567", "Uther#8901",
    "Gul'dan#2345", "Khadgar#6789", "Medivh#0123", "Velen#4567", "Alleria#8901",
    "Turalyon#2345", "Chromie#1111", "Wrathion#2222", "Alexstrasza#3333", "Nozdormu#4444",
    
    -- ===================
    -- PLAYER-STYLE
    -- ===================
    "ProGamer#1337", "Noobslayer#9999", "TheChosen#0001", "GuildMaster#8888", "RaidLeader#7777",
    "PvPKing#6666", "Mythicplus#5555", "Healer#4444", "Tank#3333", "DPS#2222",
    "Crafter#1111", "Farmer#0000", "Collector#9876", "Achievement#5432", "Mount#1098",
    
    -- ===================
    -- INTERNATIONAL
    -- ===================
    "안녕하세요#1111", "你好世界#2222", "哈囉世界#3333", "Россия#4444", "こんにちは#5555",
    "Sturmwind#6666", "Hurlevent#7777", "Ventormenta#8888", "Ventobravo#9999",
    
    -- ===================
    -- NUMERIC SEQUENCES
    -- ===================
    "Player#1001", "Player#1002", "Player#1003", "Player#1004", "Player#1005",
    "Player#1006", "Player#1007", "Player#1008", "Player#1009", "Player#1010",
    "Player#2001", "Player#2002", "Player#2003", "Player#2004", "Player#2005",
    "Friend#3001", "Friend#3002", "Friend#3003", "Friend#3004", "Friend#3005",
    "Gamer#4001", "Gamer#4002", "Gamer#4003", "Gamer#4004", "Gamer#4005",
    
    -- ===================
    -- STRESS TEST (Unique tags for large friend lists)
    -- ===================
    "Stress#0001", "Stress#0002", "Stress#0003", "Stress#0004", "Stress#0005",
    "Stress#0006", "Stress#0007", "Stress#0008", "Stress#0009", "Stress#0010",
    "Stress#0011", "Stress#0012", "Stress#0013", "Stress#0014", "Stress#0015",
    "Stress#0016", "Stress#0017", "Stress#0018", "Stress#0019", "Stress#0020",
    "Stress#0021", "Stress#0022", "Stress#0023", "Stress#0024", "Stress#0025",
    "Stress#0026", "Stress#0027", "Stress#0028", "Stress#0029", "Stress#0030",
    "Stress#0031", "Stress#0032", "Stress#0033", "Stress#0034", "Stress#0035",
    "Stress#0036", "Stress#0037", "Stress#0038", "Stress#0039", "Stress#0040",
    "Stress#0041", "Stress#0042", "Stress#0043", "Stress#0044", "Stress#0045",
    "Stress#0046", "Stress#0047", "Stress#0048", "Stress#0049", "Stress#0050",
}

-- ============================================
-- EDGE CASE NAMES (For testing)
-- ============================================

BFL.TestData.EdgeCaseNames = {
    -- Very long names
    "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
    "ThisIsAnotherExtremelyLongCharacterNameThatShouldBeTruncatedProperlyInTheUI",
    "AmazinglyLongAndUnnecessarilyVerboseCharacterNameForTestingPurposes",
    
    -- Special characters (that WoW allows)
    "Name-Realm",
    "Name'Apostrophe",
    
    -- Very short names
    "A", "Ab", "Abc",
    
    -- Numbers at end (common pattern)
    "Warrior1", "Mage22", "Priest333", "Hunter4444",
    
    -- Alt codes / special chars (valid in some regions)
    "Çhàrâctér", "Ñoñó", "Ünïcödé",
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get a random name from the combined pool
function BFL.TestData:GetRandomName()
    local pools = {self.LoreNames, self.PlayerNames}
    local pool = pools[math.random(#pools)]
    return pool[math.random(#pool)]
end

-- Get a random lore name
function BFL.TestData:GetRandomLoreName()
    return self.LoreNames[math.random(#self.LoreNames)]
end

-- Get a random player-style name
function BFL.TestData:GetRandomPlayerName()
    return self.PlayerNames[math.random(#self.PlayerNames)]
end

-- Get a random international name
function BFL.TestData:GetRandomInternationalName(language)
    if language and self.InternationalNames[language] then
        local pool = self.InternationalNames[language]
        return pool[math.random(#pool)]
    end
    
    -- Random language
    local languages = {"korean", "chinese_simplified", "chinese_traditional", "russian", "japanese", "german", "french", "spanish", "portuguese"}
    local lang = languages[math.random(#languages)]
    local pool = self.InternationalNames[lang]
    return pool[math.random(#pool)], lang
end

-- Get a random BattleTag
function BFL.TestData:GetRandomBattleTag()
    return self.BattleTags[math.random(#self.BattleTags)]
end

-- Get a unique BattleTag (with index for uniqueness)
function BFL.TestData:GetUniqueBattleTag(index)
    -- Use existing tag if index is small enough
    if index <= #self.BattleTags then
        return self.BattleTags[index]
    end
    
    -- Generate new unique tag
    return string.format("Friend#%04d", index)
end

-- Get a random edge case name
function BFL.TestData:GetEdgeCaseName()
    return self.EdgeCaseNames[math.random(#self.EdgeCaseNames)]
end

-- Count total names available
function BFL.TestData:GetTotalNameCount()
    local count = #self.LoreNames + #self.PlayerNames + #self.EdgeCaseNames
    
    for _, pool in pairs(self.InternationalNames) do
        count = count + #pool
    end
    
    return count
end

-- Debug: Print name counts
function BFL.TestData:PrintNameStats()
    print("|cff00ff00BFL TestData Name Statistics:|r")
    print("  |cffffffffLore Names:|r " .. #self.LoreNames)
    print("  |cffffffffPlayer Names:|r " .. #self.PlayerNames)
    print("  |cffffffffBattleTags:|r " .. #self.BattleTags)
    print("  |cffffffffEdge Cases:|r " .. #self.EdgeCaseNames)
    
    local intCount = 0
    for lang, pool in pairs(self.InternationalNames) do
        intCount = intCount + #pool
        print("  |cffffffff" .. lang .. ":|r " .. #pool)
    end
    
    print("  |cffffd700TOTAL:|r " .. self:GetTotalNameCount())
end

return BFL.TestData
