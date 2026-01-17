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
	if not className or className == "" then 
		return nil 
	end
	
	-- First try: Direct uppercase match (works for English clients)
	-- "Warrior" → "WARRIOR" → RAID_CLASS_COLORS["WARRIOR"] ✅
	local upperClassName = string.upper(className)
	if RAID_CLASS_COLORS[upperClassName] then
		return upperClassName
	end
	
	-- Second try: Match localized className against GetClassInfo()
	-- This handles non-English clients where className is localized
	-- German: "Krieger" matches GetClassInfo() → returns "WARRIOR"
	local numClasses = GetNumClasses()
	for i = 1, numClasses do
		local localizedName, classFile = GetClassInfo(i)
		if localizedName == className then
			return classFile
		end
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
	
	-- Try matching gender variants against GetClassInfo()
	for _, variant in ipairs(genderVariants) do
		for i = 1, numClasses do
			local localizedName, classFile = GetClassInfo(i)
			if localizedName == variant then
				return classFile
			end
		end
	end
	
	-- No match found
	return nil
end

-- Get class file for friend (optimized for 11.2.7+)
-- Priority: classID (11.2.7+) > className (fallback for 11.2.5 and WoW friends)
-- This function provides a dual system:
-- 1. Uses classID if available (fast, language-independent, BNet friends on 11.2.7+)
-- 2. Falls back to className conversion (slower, all languages, WoW friends + older versions)
function ClassUtils:GetClassFileForFriend(friend)
	if not friend then return nil end

	-- 1. Optimized Lookup: Use classID if available (Language Independent)
	-- Use Blizzard's standard GetClassInfo (works with ID as index)
	if friend.classID then
		local _, classFile = GetClassInfo(friend.classID)
		if classFile then
			return classFile
		end
	end
	
	-- 2. Fallback: Convert className (WoW friends + older game versions)
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
