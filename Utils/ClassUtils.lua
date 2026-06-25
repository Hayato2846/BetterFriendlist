-- Utils/ClassUtils.lua
-- Centralized Class Utils for converting names, IDs and retrieving colors
-- Updated for Retail (11.0.2/11.0.5) to use classID where possible

local ADDON_NAME, BFL = ...
local ClassUtils = {}
BFL.ClassUtils = ClassUtils

-- ========================================
-- Constants
-- ========================================
-- Fallback for when RAID_CLASS_COLORS is not available or for custom colors
local FALLBACK_COLOR = { r = 1, g = 1, b = 1 }

local CLASS_ID_TO_FILE = {
	[1] = "WARRIOR",
	[2] = "PALADIN",
	[3] = "HUNTER",
	[4] = "ROGUE",
	[5] = "PRIEST",
	[6] = "DEATHKNIGHT",
	[7] = "SHAMAN",
	[8] = "MAGE",
	[9] = "WARLOCK",
	[10] = "MONK",
	[11] = "DRUID",
	[12] = "DEMONHUNTER",
	[13] = "EVOKER",
}

local MAX_CLASS_ID = 13

local function IsKnownClassFile(classFile)
	return classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] ~= nil
end

local function NormalizeClassToken(className)
	local token = string.upper(className)
	token = token:gsub("%s+", "")
	token = token:gsub("[%-_']", "")
	return token
end

local function MatchLocalizedClassTable(className, localizedTable)
	if type(localizedTable) ~= "table" then
		return nil
	end

	for classFile, localizedName in pairs(localizedTable) do
		if localizedName == className and IsKnownClassFile(classFile) then
			return classFile
		end
	end

	return nil
end

local function MatchLocalizedClassTables(className)
	return MatchLocalizedClassTable(className, LOCALIZED_CLASS_NAMES_MALE)
		or MatchLocalizedClassTable(className, LOCALIZED_CLASS_NAMES_FEMALE)
end

local function MatchGetClassInfo(className)
	if not GetClassInfo then
		return nil
	end

	if GetNumClasses then
		local numClasses = GetNumClasses()
		if type(numClasses) == "number" then
			for i = 1, numClasses do
				local localizedName, classFile = GetClassInfo(i)
				if localizedName == className and IsKnownClassFile(classFile) then
					return classFile
				end
			end
		end
	end

	-- Classic Era/TBC/Wrath/Cata can have class ID gaps. Druid is 11, so
	-- a plain 1..GetNumClasses() loop can miss it on Anniversary clients.
	for classID = 1, MAX_CLASS_ID do
		local localizedName, classFile = GetClassInfo(classID)
		classFile = classFile or CLASS_ID_TO_FILE[classID]
		if localizedName == className and IsKnownClassFile(classFile) then
			return classFile
		end
	end

	return nil
end

local function MatchCreatureInfo(className)
	if not C_CreatureInfo or not C_CreatureInfo.GetClassInfo then
		return nil
	end

	for classID = 1, MAX_CLASS_ID do
		local info = C_CreatureInfo.GetClassInfo(classID)
		if info and info.className == className and IsKnownClassFile(info.classFile) then
			return info.classFile
		end
	end

	return nil
end

local function ResolveLocalizedClassName(className)
	return MatchLocalizedClassTables(className)
		or MatchGetClassInfo(className)
		or MatchCreatureInfo(className)
end

function ClassUtils:GetClassFileFromClassID(classID)
	classID = tonumber(classID)
	if not classID or classID <= 0 then
		return nil
	end

	if C_CreatureInfo and C_CreatureInfo.GetClassInfo then
		local info = C_CreatureInfo.GetClassInfo(classID)
		if info and IsKnownClassFile(info.classFile) then
			return info.classFile
		end
	end

	if GetClassInfo then
		local _, classFile = GetClassInfo(classID)
		if IsKnownClassFile(classFile) then
			return classFile
		end
	end

	local fallbackFile = CLASS_ID_TO_FILE[classID]
	if IsKnownClassFile(fallbackFile) then
		return fallbackFile
	end

	return nil
end

-- ========================================
-- Core Logic
-- ========================================

-- Convert localized class name to English class filename for RAID_CLASS_COLORS
-- This fixes class coloring in non-English clients (deDE, frFR, esES, etc.)
-- CRITICAL: gameAccountInfo.className and friendInfo.className are LOCALIZED
-- German client: "Krieger", French client: "Guerrier", English client: "Warrior"
-- We must convert localized → English classFile (e.g., "Krieger" → "WARRIOR")
--
-- IMPORTANT: German (and other languages) use GENDERED class names:
-- - Masculine: "Krieger", "Dämonenjäger" (from GetClassInfo)
-- - Feminine: "Kriegerin", "Dämonenjägerin" (from gameAccountInfo.className)
-- We need to strip gender suffixes before matching
function ClassUtils:GetClassFileFromClassName(className)
	if type(className) ~= "string" then
		return nil
	end

	className = className:match("^%s*(.-)%s*$")
	if className == "" then
		return nil
	end
	
	-- First try: direct class token match (English and API token fields).
	-- "Death Knight" -> "DEATHKNIGHT", "Druid" -> "DRUID".
	local classToken = NormalizeClassToken(className)
	if IsKnownClassFile(classToken) then
		return classToken
	end
	
	-- Second try: Blizzard localized tables and class APIs.
	-- This avoids Classic ID gaps where Druid is class ID 11.
	local classFile = ResolveLocalizedClassName(className)
	if classFile then
		return classFile
	end
	
	-- Third try: Handle gendered class names (German, French, Spanish, etc.)
	-- German feminine forms add "-in" suffix: "Kriegerin" → "Krieger"
	-- French feminine forms add "-e" suffix: "Guerrière" → "Guerrier"
	-- Spanish feminine forms change "-o" to "-a": "Guerrera" → "Guerrero"
	
	-- Try removing German/French/Spanish feminine suffixes
	local genderVariants = {}
	
	-- German: Remove "-in" suffix (Kriegerin → Krieger)
	if className:len() > 2 and className:sub(-2) == "in" then
		table.insert(genderVariants, className:sub(1, -3))
	end
	
	-- French: Remove "-e" suffix (Guerrière → Guerrier, Chasseresse → Chasseur)
	if className:len() > 1 and className:sub(-1) == "e" then
		table.insert(genderVariants, className:sub(1, -2))
	end
	
	-- Spanish: Replace "-a" with "-o" (Guerrera → Guerrero)
	if className:len() > 1 and className:sub(-1) == "a" then
		table.insert(genderVariants, className:sub(1, -2) .. "o")
	end
	
	-- Try matching gender variants against the same localized lookup path.
	for _, variant in ipairs(genderVariants) do
		classFile = ResolveLocalizedClassName(variant)
		if classFile then
			return classFile
		end
	end
	
	-- No match found
	return nil
end

-- Get class file for friend (optimized for 11.2.7+)
-- Priority: classFile/classFilename > classID > className
-- This function provides a dual system:
-- 1. Uses class file fields if available (fast, language-independent)
-- 2. Uses classID if available (fast, language-independent, BNet friends on 11.2.7+)
-- 3. Falls back to className conversion (slower, all languages, WoW friends + older versions)
function ClassUtils:GetClassFileForFriend(friend)
	if not friend then return nil end

	-- 1. Direct class file fields from BNet/game account APIs.
	local classFile = friend.classFile or friend.classFileName or friend.classFilename
	if IsKnownClassFile(classFile) then
		return classFile
	end

	-- 2. Optimized Lookup: Use classID if available (Language Independent)
	if friend.classID then
		classFile = self:GetClassFileFromClassID(friend.classID)
		if classFile then
			return classFile
		end
	end
	
	-- 3. Fallback: Convert className (WoW friends + older game versions)
	if friend.className then
		return self:GetClassFileFromClassName(friend.className)
	end
	
	return nil
end

-- Get class color for friend (returns color table or white fallback)
function ClassUtils:GetClassColorForFriend(friend)
	local classFile = self:GetClassFileForFriend(friend)
	if classFile and RAID_CLASS_COLORS[classFile] then
		return RAID_CLASS_COLORS[classFile]
	end
	return FALLBACK_COLOR
end

-- Get color hex string for friend's class
function ClassUtils:GetClassColorHex(friend)
	local color = self:GetClassColorForFriend(friend)
	return string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
end
