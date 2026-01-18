--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua"); local _, BFL = ...

-- Comprehensive list of Connected Realms
-- Source: Wowpedia (Dec 2025)

-- US / Americas (Region ID: 1)
local groupsUS = {
    { "Nesingwary", "Vek'nilash", "Nazgrel" },
    { "Dentarg", "Whisperwind" },
    { "Fizzcrank", "Aggramar" },
    { "Echo Isles", "Draenor" },
    { "Cairne", "Perenolde", "Cenarius", "Korgath", "Tortheldrin", "Frostmane", "Ner'zhul" },
    { "Winterhoof", "Kilrogg" },
    { "Arygos", "Llane" },
    { "Fenris", "Dragonblight" },
    { "Icecrown", "Malygos", "Garona", "Onyxia", "Burning Blade", "Lightning's Blade" },
    { "Quel'dorei", "Sen'jin", "Boulderfist", "Bloodscalp", "Maiev", "Dunemaul", "Stonemaul" },
    { "Velen", "Eonar", "Scilla", "Ursin", "Andorhal", "Zuluhed", "Black Dragonflight", "Skullcrusher", "Argent Dawn" },
    { "Draka", "Suramar", "Darrowmere", "Windrunner" },
    { "Galakrond", "Blackhand" },
    { "Shandris", "Bronzebeard" },
    { "Bladefist", "Kul Tiras" },
    { "Uldaman", "Ravencrest" },
    { "Misha", "Rexxar" },
    { "Alleria", "Khadgar", "Exodar", "Medivh" },
    { "Shu'halo", "Eitrigg" },
    { "Uther", "Runetotem" },
    { "Azjol-Nerub", "Khaz Modan", "Blackrock", "Nordrassil", "Muradin" },
    { "Alexstrasza", "Terokkar" },
    { "Drak'thul", "Skywall", "Mok'Nathal", "Silvermoon", "Borean Tundra", "Shadowsong", "Hydraxis", "Terenas" },
    { "Duskwood", "Bloodhoof" },
    { "Azuremyst", "Staghelm", "Dawnbringer", "Madoran" },
    { "Tanaris", "Greymane" },
    { "Doomhammer", "Baelgun" },
    { "Ysera", "Durotan" },
    { "Elune", "Gilneas", "Auchindoun", "Laughing Skull", "Cho'gall" },
    { "Malfurion", "Trollbane", "Grizzly Hills", "Lothar", "Gnomeregan", "Moonrunner", "Ghostlands", "Kael'thas" },
    { "Balnazzar", "Warsong", "Gorgonnash", "The Forgotten Coast", "Alterac Mountains", "Undermine", "Anvilmar" },
    { "Gurubashi", "Aegwynn", "Hakkar", "Daggerspine", "Bonechewer", "Garrosh" },
    { "Dalvengyr", "Dark Iron", "Coilfang", "Demon Soul", "Shattered Hand" },
    { "Garithos", "Chromaggus", "Anub'arak", "Smolderthorn", "Nathrezim", "Crushridge", "Drenden", "Arathor" },
    { "Dethecus", "Detheroc", "Blackwing Lair", "Haomarush", "Lethon", "Shadowmoon" },
    { "Rivendare", "Firetree", "Drak'tharon", "Malorne", "Spirestone", "Stormscale", "Frostwolf", "Vashj" },
    { "Azshara", "Azgalor", "Destromath", "Thunderlord", "Blood Furnace", "Mannoroth", "Nazjatar" },
    { "Ysondre", "Magtheridon", "Anetheron", "Altar of Storms" },
    { "Akama", "Dragonmaw", "Mug'thol", "Eldre'Thalas", "Korialstrasz", "Antonidas", "Uldum" },
    { "Executus", "Kalecgos", "Shattered Halls", "Deathwing" },
    { "Agamaggan", "Jaedenar", "The Underbog", "Archimonde", "Burning Legion", "Norgannon", "Kargath", "Blade's Edge", "Thunderhorn" },
    { "Spinebreaker", "Wildhammer", "Gorefiend", "Eredar", "Zangarmarsh", "Hellscream" },
    { "Kirin Tor", "Steamwheedle Cartel", "Sentinels" },
    { "Farstriders", "Silver Hand", "Thorium Brotherhood" },
    { "Feathermoon", "Scarlet Crusade" },
    { "The Scryers", "Argent Dawn" },
    { "Cenarion Circle", "Sisters of Elune", "Blackwater Raiders", "Shadow Council" },
    { "The Venture Co", "Maelstrom", "Lightninghoof", "Ravenholdt", "Twisting Nether" },
    { "Dath'remar", "Khaz'goroth", "Aman'Thul" },
    { "Caelestrasz", "Nagrand", "Saurfang" },
    { "Dreadmaul", "Thaurissan", "Gundrak", "Jubei'Thos", "Frostmourne" },
    { "Nemesis", "Tol Barad" },
}

-- Korea (Region ID: 2)
local groupsKR = {
    { "불타는 군단", "스톰레이지", "듀로탄" },
    { "렉사르", "와일드해머", "윈드러너", "알렉스트라자", "데스윙" },
    { "세나리우스", "달라란", "말퓨리온", "노르간논", "가로나", "굴단", "줄진", "하이잘", "헬스크림" },
}

-- EU / Europe (Region ID: 3)
local groupsEU = {
    -- EU English
    { "Kilrogg", "Runetotem", "Nagrand", "Arathor", "Hellfire" },
    { "Thunderhorn", "Wildhammer" },
    { "Aggramar", "Hellscream" },
    { "Azjol-Nerub", "Quel'Thalas" },
    { "Aszune", "Shadowsong" },
    { "Bloodhoof", "Khadgar" },
    { "Bronze Dragonflight", "Nordrassil" },
    { "Lightbringer", "Mazrigos" },
    { "Azuremyst", "Stormrage" },
    { "Doomhammer", "Turalyon" },
    { "Blade's Edge", "Vek'nilash", "Eonar", "Aerie Peak", "Bronzebeard" },
    { "Alonsus", "Kul Tiras", "Anachronos" },
    { "Emerald Dream", "Terenas" },
    { "Emeriss", "Hakkar", "Crushridge", "Agamaggan", "Bloodscalp", "Twilight's Hammer" },
    { "Burning Steppes", "Kor'gall", "Executus", "Bloodfeather", "Shattered Hand", "Darkspear", "Terokkar", "Saurfang" },
    { "Chromaggus", "Shattered Halls", "Boulderfist", "Daggerspine", "Talnivarr", "Trollbane", "Ahn'Qiraj", "Balnazzar", "Sunstrider", "Laughing Skull" },
    { "Aggra", "Grim Batol", "Frostmane" },
    { "Karazhan", "Lightning's Blade", "Deathwing", "The Maelstrom", "Dragonblight", "Ghostlands" },
    { "Auchindoun", "Jaedenar", "Dunemaul", "Sylvanas" },
    { "Bladefist", "Zenedar", "Frostwhisper", "Darksorrow", "Genjuros", "Neptulon" },
    { "Dragonmaw", "Haomarush", "Spinebreaker", "Vashj", "Stormreaver" },
    { "Skullcrusher", "Xavius", "Al'Akir", "Burning Legion" },
    { "Burning Blade", "Drak'thul" },
    { "Dentarg", "Tarren Mill" },
    { "Moonglade", "The Sha'tar", "Steamwheedle Cartel" },
    { "Scarshield Legion", "Sporeggar", "The Venture Co", "Ravenholdt", "Defias Brotherhood", "Darkmoon Faire", "Earthen Ring" },
    
    -- EU German
    { "Area 52", "Un'Goro", "Sen'jin" },
    { "Garrosh", "Nozdormu", "Shattrath", "Perenolde", "Teldrassil" },
    { "Ambossar", "Kargath", "Thrall" },
    { "Malorne", "Ysera" },
    { "Malfurion", "Malygos" },
    { "Arygos", "Khaz'goroth" },
    { "Lordaeron", "Tichondrius", "Blackmoore" },
    { "Baelgun", "Lothar", "Azshara", "Krag'jin" },
    { "Dun Morogh", "Norgannon" },
    { "Alleria", "Rexxar" },
    { "Madmortem", "Proudmoore", "Alexstrasza", "Nethersturm" },
    { "Dethecus", "Theradras", "Mug'thol", "Terrordar", "Onyxia" },
    { "Echsenkessel", "Taerar", "Mal'Ganis", "Blackhand" },
    { "Arthas", "Vek'lor", "Blutkessel", "Kel'Thuzad", "Wrathbringer", "Durotan", "Tirion" },
    { "Anetheron", "Rajaxx", "Gul'dan", "Festung der Stürme", "Nathrezim", "Kil'Jaeden" },
    { "Dalvengyr", "Nazjatar", "Frostmourne", "Zuluhed", "Anub'arak", "Aman'Thul" },
    { "Nefarian", "Nera'thor", "Mannoroth", "Destromath", "Gorgonnash", "Gilneas", "Ulduar" },
    { "Todeswache", "Zirkel des Cenarius", "Die Nachtwache", "Forscherliga", "Der Mithrilorden", "Der Rat von Dalaran" },
    { "Das Syndikat", "Die Arguswacht", "Die Todeskrallen", "Der Abyssische Rat", "Kult der Verdammten", "Das Konsortium", "Die ewige Wacht", "Die Silberne Hand" },

    -- EU French
    { "Medivh", "Suramar" },
    { "Elune", "Varimathras" },
    { "Drek'Thar", "Uldaman", "Eitrigg", "Krasus" },
    { "Chants éternels", "Vol'jin" },
    { "Naxxramas", "Temple noir", "Arathi", "Illidan" },
    { "Arak-arahm", "Throk'Feroth", "Rashgarroth", "Kael'Thas" },
    { "Garona", "Ner'zhul", "Sargeras" },
    { "Eldre'Thalas", "Sinstralis", "Cho'gall", "Dalaran", "Marécage de Zangar" },
    { "Confrérie du Thorium", "Les Clairvoyants", "Les Sentinelles", "Kirin Tor", "Culte de la Rive noire", "La Croisade écarlate", "Conseil des Ombres" },

    -- EU Spanish
    { "C'Thun", "Dun Modr" },
    { "Exodar", "Minahonda" },
    { "Colinas Pardas", "Tyrande", "Los Errantes" },
    { "Shen'dralar", "Zul'jin", "Uldum", "Sanguino" },

    -- EU Russian
    { "Deepholm", "Razuvious", "Galakrond" },
    { "Lich King", "Greymane", "Goldrinn" },
    { "Blackscar", "Grom", "Thermaplugg" },
    { "Подземье", "Разувий", "Галакронд" },
    { "Король-лич", "Седогрив", "Голдринн" },
    { "Черный Шрам", "Гром", "Термоштепсель" },
}

-- Taiwan (Region ID: 4)
local groupsTW = {
    { "聖光之願", "天空之牆", "水晶之刺", "憤怒使者", "銀翼要塞", "屠魔山谷", "日落沼澤" },
    { "眾星之子", "暗影之月", "語風", "冰風崗哨", "寒冰皇冠", "尖石", "阿薩斯", "地獄吼", "狂熱之刃" },
    { "血之谷", "冰霜之刺", "米奈希爾", "巨龍之喉", "夜空之歌", "雷鱗", "亞雷戈斯", "雲蛟衛", "世界之樹" },
}

-- China (Region ID: 5)
local groupsCN = {
    { "奥蕾莉亚", "布莱恩", "万色星辰", "世界之树" },
    { "亚雷戈斯", "银松森林" },
    { "艾维娜", "艾露恩" },
    { "塞纳留斯", "海达希亚", "图拉扬", "瓦里玛萨斯" },
    { "梦境之树", "诺兹多姆", "泰兰德" },
    { "回音山", "霜之哀伤", "神圣之歌", "遗忘海岸" },
    { "翡翠梦境", "黄金之路", "永夜港" },
    { "羽月", "玛多兰", "银月", "耳语海岸" },
    { "麦迪文", "月光林地" },
    { "普瑞斯托", "逐日者", "奥杜尔" },
    { "阿比迪斯", "踏梦者" },
    { "伊莫塔尔", "萨尔" },
    { "大漩涡", "风暴之怒", "提尔之手", "萨菲隆", "布莱克摩", "灰谷" },
    { "燃烧之刃", "格瑞姆巴托", "埃霍恩" },
    { "凤凰之神", "托塞德林" },
    { "主宰之剑", "霍格" },
    { "无尽之海", "米奈希尔" },
    { "亡语者", "克尔苏加德", "奥尔加隆" },
    { "洛肯", "海克泰尔" },
    { "天空之墙", "法拉希姆", "玛法里奥", "麦维·影歌", "血羽", "森金", "沙怒", "戈提克", "雏龙之翼" },
    { "鬼雾峰", "黑暗之矛", "塞泰克", "罗曼斯", "巨龙之吼", "黑石尖塔" },
    { "雷克萨", "火喉", "激流堡", "阿古斯" },
    { "红云台地", "卡扎克", "爱斯特纳", "戈古纳斯", "巴纳扎尔", "激流之傲", "拉格纳洛斯", "龙骨平原" },
    { "拉文霍德", "山丘之王", "红龙军团", "加里索斯", "库德兰" },
    { "暴风祭坛", "利刃之拳", "摩摩尔", "熵魔", "黑翼之巢", "玛里苟斯", "艾萨拉" },
    { "迅捷微风", "萨洛拉丝" },
    { "索瑞森", "试炼之环", "伊利丹", "尘风峡谷" },
    { "深渊之喉", "古拉巴什", "安戈洛", "德拉诺", "深渊之巢", "外域", "织亡者", "阿格拉玛", "屠魔山谷" },
    { "祖尔金", "破碎岭", "埃基尔松", "厄祖玛特", "奎尔萨拉斯" },
    { "塞拉摩", "暗影迷宫", "麦姆" },
    { "卡珊德拉", "暗影之月" },
    { "艾森娜", "月神殿", "轻风之语", "伊瑟拉" },
    { "菲拉斯", "奈萨里奥", "红龙女王", "格雷迈恩", "黑手军团", "瓦丝琪" },
    { "蓝龙军团", "朵丹尼尔", "希雷诺斯", "芬里斯", "烈焰荆棘", "沃金", "天谴之门" },
    { "冰霜之刃", "安格博达" },
    { "斩魔者", "埃加洛尔", "鲜血熔炉", "幽暗沼泽" },
    { "埃雷达尔", "永恒之井" },
    { "达克萨隆", "阿纳克洛斯" },
    { "范克里夫", "血环" },
    { "熔火之心", "黑锋哨站" },
    { "加基森", "黑暗虚空" },
    { "迪瑟洛克", "拉文凯斯", "加兹鲁维", "奥金顿", "哈兰" },
    { "大地之怒", "恶魔之魂", "希尔瓦娜斯" },
    { "刺骨利刃", "千针石林", "白骨荒野", "能源舰" },
    { "哈卡", "诺森德", "燃烧军团", "死亡熔炉" },
    { "铜龙军团", "普罗德摩", "玛洛加尔" },
    { "诺莫瑞根", "无底海渊", "阿努巴拉克", "刀塔", "自由之风", "达隆米尔", "艾欧纳尔", "冬寒" },
    { "达尔坎", "鹰巢山", "石锤", "范达尔鹿盔" },
    { "燃烧平原", "风行者" },
    { "伊兰尼库斯", "阿克蒙德", "恐怖图腾" },
    { "地狱之石", "火焰之树", "耐奥祖" },
    { "洛萨", "阿卡玛", "萨格拉斯" },
    { "加尔", "黑龙军团" },
    { "冬泉谷", "寒冰皇冠" },
    { "圣火神殿", "桑德兰" },
    { "提瑞斯法", "暗影议会" },
    { "卡德罗斯", "符文图腾", "黑暗魅影", "阿斯塔洛" },
    { "基尔罗格", "巫妖之王", "迦顿" },
    { "古加尔", "洛丹伦" },
    { "地狱咆哮", "阿曼尼", "奈法利安" },
    { "卡拉赞", "苏塔恩" },
    { "夺灵者", "战歌", "奥斯里安" },
    { "凯恩血蹄", "瑟莱德丝", "卡德加" },
    { "暮色森林", "杜隆坦", "狂风峭壁", "玛瑟里顿" },
    { "烈焰峰", "瓦拉斯塔兹" },
    { "守护之剑", "瑞文戴尔" },
    { "火烟之谷", "玛诺洛斯", "达纳斯" },
    { "奥妮克希亚", "海加尔", "纳克萨玛斯" },
    { "索拉丁", "雷霆之王", "勇士岛", "达文格尔" },
    { "血吼", "黑暗之门" },
    { "安纳塞隆", "日落沼泽", "风暴之鳞", "耐普图隆" },
    { "祖达克", "阿尔萨斯" },
    { "元素之力", "菲米丝", "夏维安" },
    { "古达克", "梅尔加尼" },
    { "阿拉索", "阿迦玛甘" },
    { "迦玛兰", "霜狼" },
    { "伊森德雷", "达斯雷玛", "库尔提拉斯", "雷霆之怒" },
    { "塔纳利斯", "巴瑟拉斯", "密林游侠" },
    { "安其拉", "弗塞雷迦", "盖斯" },
    { "嚎风峡湾", "闪电之刃" },
    { "埃克索图斯", "血牙魔王" },
    { "塞拉赞恩", "太阳之井" },
    { "安威玛尔", "扎拉赞恩" },
    { "奎尔丹纳斯", "艾莫莉丝", "布鲁塔卢斯" },
    { "藏宝海湾", "阿拉希", "塔伦米尔" },
    { "末日祷告祭坛", "迦罗娜", "纳沙塔尔", "火羽山" },
    { "石爪峰", "阿扎达斯" },
    { "恶魔之翼", "通灵学院" },
    { "奥达曼", "甜水绿洲" },
    { "斯坦索姆", "穆戈尔", "泰拉尔", "格鲁尔" },
    { "拉贾克斯", "荆棘谷" },
    { "雷霆号角", "风暴之眼" },
    { "影牙要塞", "艾苏恩" },
    { "古尔丹", "血顶" },
    { "古基尔加丹", "奥拉基尔" },
    { "克洛玛古斯", "金度" },
    { "伊萨里奥斯", "祖阿曼" },
    { "冰川之拳", "双子峰", "埃苏雷格", "凯尔萨斯" },
    { "丹莫德", "克苏恩" },
    { "安加萨", "莱索恩" },
    { "军团要塞", "生态船" },
    { "冬拥湖", "迪托马斯", "达基萨斯" },
    { "巴尔古恩", "托尔巴拉德" },
    { "毁灭之锤", "兰娜瑟尔" },
    { "暗影裂口", "辛达苟萨" },
}

-- Helper to normalize realm names (remove spaces for consistent keys)
local function Normalize(name) Perfy_Trace(Perfy_GetTime(), "Enter", "Normalize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:263:6");
    if not name then Perfy_Trace(Perfy_GetTime(), "Leave", "Normalize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:263:6"); return "" end
    -- gsub returns 2 values (string, count), we only want the string
    -- otherwise table.insert receives 3 args and treats the string as a position index
    return Perfy_Trace_Passthrough("Leave", "Normalize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:263:6", (name:gsub("%s", "")))
end

-- Generate bidirectional lookup table based on current region
BFL.ConnectedRealms = {}

-- Determine current region
-- 1: US, 2: KR, 3: EU, 4: TW, 5: CN
local function GetRegionID() Perfy_Trace(Perfy_GetTime(), "Enter", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6");
    -- Try GetCurrentRegion first (wrapped in pcall)
    if GetCurrentRegion then
        local success, region = pcall(GetCurrentRegion)
        if success and type(region) == "number" then
            Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return region
        end
    end

    -- Fallback to portal CVar
    local portal = GetCVar("portal")
    if portal == "US" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 1 end
    if portal == "KR" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 2 end
    if portal == "EU" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 3 end
    if portal == "TW" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 4 end
    if portal == "CN" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 5 end
    
    Perfy_Trace(Perfy_GetTime(), "Leave", "GetRegionID file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:275:6"); return 1 -- Default to US
end

local regionID = GetRegionID()
local activeGroups = {}

if regionID == 1 then
    activeGroups = groupsUS
elseif regionID == 2 then
    activeGroups = groupsKR
elseif regionID == 3 then
    activeGroups = groupsEU
elseif regionID == 4 then
    activeGroups = groupsTW
elseif regionID == 5 then
    activeGroups = groupsCN
end

for _, group in ipairs(activeGroups) do
    for _, realm in ipairs(group) do
        local key = Normalize(realm)
        -- Ensure table exists
        if not BFL.ConnectedRealms[key] then
            BFL.ConnectedRealms[key] = {}
        end
        
        -- Add all realms in group to this realm's list (including itself)
        for _, connectedRealm in ipairs(group) do
            -- Store the normalized name so we can look it up in DB easily
            table.insert(BFL.ConnectedRealms[key], Normalize(connectedRealm))
        end
    end
end

-- Helper to get connected realms (safe access)
function BFL:GetConnectedRealms(realm) Perfy_Trace(Perfy_GetTime(), "Enter", "BFL:GetConnectedRealms file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:327:0");
    if not realm then return Perfy_Trace_Passthrough("Leave", "BFL:GetConnectedRealms file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:327:0", {}) end
    local key = Normalize(realm)
    return Perfy_Trace_Passthrough("Leave", "BFL:GetConnectedRealms file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua:327:0", BFL.ConnectedRealms[key] or { key })
end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Data/ConnectedRealms.lua");