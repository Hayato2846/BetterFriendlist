-- BetterFriendlist - FontManager Module
-- Handles font sizing, scaling, compact mode, and Alphabet-aware FontFamilies

local _, BFL = ...

-- Create FontManager namespace
BFL.FontManager = {}
local FontManager = BFL.FontManager

-- ========================================
-- Dependencies
-- ========================================
local LSM = LibStub("LibSharedMedia-3.0")
local GetDB = function() return BFL:GetModule("DB") end

-- ========================================
-- Font Family Logic (Alphabet Support)
-- ========================================
local fontObjectCache = {}

-- Alphabets supported by WoW API
-- Matches standardized FontFamilies list for modern API
local FONT_ALPHABETS = {
	"roman",
	"korean",
	"simplifiedchinese",
	"traditionalchinese",
	"russian",
}

-- Determine current alphabet based on locale
local currentAlphabet = "roman"
local locale = GetLocale()
if locale == "koKR" then
	currentAlphabet = "korean"
elseif locale == "zhCN" then
	currentAlphabet = "simplifiedchinese"
elseif locale == "zhTW" then
	currentAlphabet = "traditionalchinese"
elseif locale == "ruRU" then
	currentAlphabet = "russian"
end

-- Get or create a Font Family Object that handles proper alphabet fallback
-- This mimics modern WoW internal logic to support CJK/Cyrillic characters even if the user-selected font lacks them
function FontManager:GetFontFamily(fontPath, size, flags)
	-- Fallback if API not available (Classic/Older clients)
	-- Note: CreateFontFamily is global in modern Retail/TWW
	if not CreateFontFamily then
		return nil
	end

	-- Create cache key
	local safeFlags = flags or ""
	local key = string.format("%s_%d_%s", fontPath, size, safeFlags)
	if fontObjectCache[key] then
		return fontObjectCache[key]
	end

	-- Generate safe unique global name
	local safeKey = key:gsub("[^%w]", "")
	local globalName = "BFL_FontFamily_" .. safeKey
	
	-- Check global if exists (shared resource)
	if _G[globalName] then
		fontObjectCache[key] = _G[globalName]
		return _G[globalName]
	end
	
	-- Build members table
	local members = {}
	local coreFont = GameFontNormal
	
	for _, alphabet in ipairs(FONT_ALPHABETS) do
		-- Retrieve the font object Blizzard uses for this alphabet
		local fontForAlphabet = coreFont:GetFontObjectForAlphabet(alphabet)
		
		-- Get the PHYSICAL file path Blizzard uses for this alphabet (e.g., Arial.ttf or generic CJK font)
		local file, sysSize, _ = nil, nil, nil
		if fontForAlphabet then
			file, sysSize, _ = fontForAlphabet:GetFont()
		end
		
		-- Logic: 
		-- Use User Font for current locale's native alphabet.
		-- Use System Font for all other alphabets (Fallback).
		
		local fileToUse = file
		local heightToUse = sysSize or size
		
		-- Strict Override: Only use User Font if it MATCHES key alphabet
		if alphabet == currentAlphabet then
			fileToUse = fontPath
			heightToUse = size
		else
			-- Fallback: Use system file (already fetched above)
		end
		
		table.insert(members, {
			alphabet = alphabet,
			file = fileToUse,
			height = heightToUse, 
			flags = safeFlags
		})
	end
	
	-- Create the family
	-- Pcall to be safe against API changes
	local success, result = pcall(CreateFontFamily, globalName, members)
	
	if success and result then
		fontObjectCache[key] = result
		return result
	else
		-- Warning is always printed
		return nil
	end
end

-- Apply font to a FontString using Family if available, else SetFont
-- Use this instead of simple SetFont() to enable Alphabet support
function FontManager:ApplyFont(fontString, fontPath, size, flags)
	if not fontString then return end
	
	-- Phase 16: Alphabet Support check
	-- Try to get the complex layout family
	local family = self:GetFontFamily(fontPath, size, flags)
	
	if family then
		fontString:SetFontObject(family)
	else
		-- Fallback to standard SetFont (no alphabet handling)
		-- This happens on Classic or if CreateFontFamily fails
		fontString:SetFont(fontPath, size, flags)
	end
end

-- ========================================
-- Public API
-- ========================================

-- Get button height based on compact mode setting
function FontManager:GetButtonHeight()
	local db = GetDB()
	if db and db:Get("compactMode", false) then
		return 24 -- Compact height
	end
	return 34 -- Normal height
end

-- Get font size multiplier based on settings
function FontManager:GetFontSizeMultiplier()
	-- REMOVED: Global scaling disabled (User Request 2026-01-20)
	return 1.0
end

-- Apply font size to a font string based on settings
function FontManager:ApplyFontSize(fontString)
	-- REMOVED: Global font scaling disabled (User Request 2026-01-20)
	-- No-op to preserve original XML/CreateFontString sizes
end

-- Get compact mode setting
function FontManager:GetCompactMode()
	local db = GetDB()
	if not db then return false end
	return db:Get("compactMode", false)
end

-- Set compact mode (triggers UI refresh)
function FontManager:SetCompactMode(enabled)
	local db = GetDB()
	if not db then return end
	
	db:Set("compactMode", enabled)
	
	-- Force full display refresh for immediate update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

-- Set font size (triggers UI refresh)
function FontManager:SetFontSize(size)
	-- REMOVED: Global font scaling disabled (User Request 2026-01-20)
end

-- ========================================
-- Helper Functions
-- ========================================

-- Get recommended font object based on settings
function FontManager:GetRecommendedFont()
	local fontSize = self:GetFontSizeMultiplier()
	
	if fontSize < 0.9 then
		return "BetterFriendlistFontNormalSmall"
	elseif fontSize > 1.1 then
		return "BetterFriendlistFontNormal"
	else
		return "BetterFriendlistFontNormalSmall"
	end
end
