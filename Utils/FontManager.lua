-- BetterFriendlist - FontManager Module
-- Handles font sizing, scaling, compact mode, and Alphabet-aware FontFamilies

local _, BFL = ...

-- Create FontManager namespace
BFL.FontManager = {}
local FontManager = BFL.FontManager

-- ========================================
-- Dependencies
-- ========================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local GetDB = function()
	return BFL:GetModule("DB")
end

-- ========================================
-- Font Path Resolution
-- ========================================

-- Resolve a font name (e.g. "Friz Quadrata TT") to a file path.
-- Uses LibSharedMedia if available; falls back to STANDARD_TEXT_FONT
-- which is locale-aware (e.g. 2002.TTF on Korean, FRIZQT___CYR.TTF on Russian).
function FontManager:ResolveFontPath(fontName)
	if not fontName then
		return STANDARD_TEXT_FONT
	end
	-- Already a file path
	if fontName:find("\\") or fontName:find("/") then
		return fontName
	end
	-- Try LibSharedMedia (may be provided by another addon)
	local media = LibStub and LibStub("LibSharedMedia-3.0", true)
	if media then
		local path = media:Fetch("font", fontName)
		if path then
			return path
		end
	end
	-- Unresolvable name: use locale-appropriate default
	return STANDARD_TEXT_FONT
end

-- ========================================
-- Advanced Font Family System
-- ========================================

local FONT_CACHE = {}
-- NOTE: "japanese" is excluded as it is not a standard CreateFontFamily member key in all client versions.
-- CJK characters for Japanese are typically covered by the "korean" or Chinese fonts in WoW's fallback system.
local ALPHABETS = { "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }

-- Map Locale to Alphabet
local function GetLocaleAlphabet()
	local locale = GetLocale()
	if locale == "koKR" then
		return "korean"
	elseif locale == "zhCN" then
		return "simplifiedchinese"
	elseif locale == "zhTW" then
		return "traditionalchinese"
	elseif locale == "ruRU" then
		return "russian"
	-- jaJP uses standard fonts (often maps to Roman or Korean internally)
	-- We default to "roman" so the user's chosen font is used for the main text.
	else
		return "roman"
	end
end

local CURRENT_ALPHABET = GetLocaleAlphabet()
local FAMILY_COUNTER = 0
local SLUG_RENDERING_SUPPORTED = nil

local FONT_FLAG_ORDER = { "OUTLINE", "THICKOUTLINE", "MONOCHROME", "SLUG" }
local VALID_FONT_FLAGS = {
	OUTLINE = true,
	THICKOUTLINE = true,
	MONOCHROME = true,
	SLUG = true,
}

local FONT_FLAG_ALIASES = {
	NONE = "",
	NORMAL = "",
	THINOUTLINE = "OUTLINE",
}

local function GetFontFlagSet(flags)
	local flagSet = {}
	if flags == nil then
		return flagSet
	end

	for flag in tostring(flags):gmatch("[^,%s]+") do
		flag = string.upper(flag)
		flag = FONT_FLAG_ALIASES[flag] or flag
		if flag ~= "" and VALID_FONT_FLAGS[flag] then
			flagSet[flag] = true
		end
	end

	if flagSet.THICKOUTLINE then
		flagSet.OUTLINE = nil
	end

	return flagSet
end

local function SerializeFontFlags(flagSet)
	local flags = {}
	for _, flag in ipairs(FONT_FLAG_ORDER) do
		if flagSet[flag] then
			flags[#flags + 1] = flag
		end
	end
	return table.concat(flags, ",")
end

function FontManager:NormalizeFontFlags(flags)
	return SerializeFontFlags(GetFontFlagSet(flags))
end

function FontManager:GetFontFlagSet(flags)
	return GetFontFlagSet(flags)
end

function FontManager:SerializeFontFlags(flagSet)
	return SerializeFontFlags(flagSet or {})
end

function FontManager:AddFontFlag(flags, flag)
	local flagSet = GetFontFlagSet(flags)
	flag = FONT_FLAG_ALIASES[flag] or flag
	if flag and VALID_FONT_FLAGS[flag] then
		if flag == "OUTLINE" then
			flagSet.THICKOUTLINE = nil
		elseif flag == "THICKOUTLINE" then
			flagSet.OUTLINE = nil
		end
		flagSet[flag] = true
	end
	return SerializeFontFlags(flagSet)
end

function FontManager:RemoveFontFlag(flags, flag)
	local flagSet = GetFontFlagSet(flags)
	flag = FONT_FLAG_ALIASES[flag] or flag
	if flag and VALID_FONT_FLAGS[flag] then
		flagSet[flag] = nil
	end
	return SerializeFontFlags(flagSet)
end

function FontManager:IsSlugRenderingAvailable()
	if SLUG_RENDERING_SUPPORTED ~= nil then
		return SLUG_RENDERING_SUPPORTED
	end

	SLUG_RENDERING_SUPPORTED = false
	if not CreateFont then
		return false
	end

	local probeFont = _G.BFL_SlugProbeFont
	if not probeFont then
		local ok, createdFont = pcall(CreateFont, "BFL_SlugProbeFont")
		if not ok or not createdFont then
			return false
		end
		probeFont = createdFont
	end

	local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local ok, result = pcall(probeFont.SetFont, probeFont, fontPath, 12, "SLUG")
	SLUG_RENDERING_SUPPORTED = ok and result ~= false
	return SLUG_RENDERING_SUPPORTED
end

function FontManager:GetFontFlags(flags)
	local flagSet = GetFontFlagSet(flags)
	if flagSet.SLUG and not self:IsSlugRenderingAvailable() then
		flagSet.SLUG = nil
	end
	return SerializeFontFlags(flagSet)
end

function FontManager:GetDefaultUIFontFlags(flags)
	return self:GetFontFlags(self:AddFontFlag(flags, "SLUG"))
end

function FontManager:ApplyDefaultSlugToFontObject(fontObject)
	if not fontObject or not fontObject.GetFont or not fontObject.SetFont then
		return false
	end

	local fontPath, fontSize, flags = fontObject:GetFont()
	if not fontPath or not fontSize then
		return false
	end

	local resolvedFlags = self:GetFontFlags(flags)
	local slugFlags = self:GetDefaultUIFontFlags(flags)
	if slugFlags == resolvedFlags then
		return true
	end

	local ok, result = pcall(fontObject.SetFont, fontObject, fontPath, fontSize, slugFlags)
	return ok and result ~= false
end

function FontManager:ApplyDefaultSlugToFontString(fontString)
	if not fontString or not fontString.GetFont or not fontString.SetFont then
		return false
	end

	local fontPath, fontSize, flags = fontString:GetFont()
	if not fontPath or not fontSize then
		return false
	end

	local resolvedFlags = self:GetFontFlags(flags)
	local slugFlags = self:GetDefaultUIFontFlags(flags)
	if slugFlags == resolvedFlags then
		return true
	end

	local ok, result = pcall(fontString.SetFont, fontString, fontPath, fontSize, slugFlags)
	return ok and result ~= false
end

-- Generate and Cache FontFamily
function FontManager:GetOrCreateFontFamily(fontPath, size, flags, shadow, useFontForNonLatinAlphabets)
	-- Normalize inputs
	size = math.floor(size + 0.5) -- Round to integer
	flags = self:GetFontFlags(flags)

	local shadowKey = shadow and "SHADOW" or "NONE"
	local alphabetKey = useFontForNonLatinAlphabets and "USER_NON_LATIN" or "SYSTEM_NON_LATIN"

	-- Create Cache Key
	local cacheKey = string.format("%s_%d_%s_%s_%s", fontPath, size, flags, shadowKey, alphabetKey)

	if FONT_CACHE[cacheKey] then
		return FONT_CACHE[cacheKey]
	end

	-- Create Unique Global Name
	FAMILY_COUNTER = FAMILY_COUNTER + 1
	local familyName = "BFL_GenFont_" .. FAMILY_COUNTER

	-- Build Family Members
	local members = {}
	local baseFont = _G["ChatFontNormal"] -- Safe fallback source

	for _, alphabet in ipairs(ALPHABETS) do
		local memberDef = {}

		memberDef.alphabet = alphabet
		memberDef.height = size
		memberDef.flags = flags

		if alphabet == "roman" or useFontForNonLatinAlphabets then
			-- Roman text always uses the chosen font. Non-latin alphabets use it only
			-- when explicitly enabled because many LSM fonts do not contain those glyphs.
			memberDef.file = fontPath
		elseif alphabet == CURRENT_ALPHABET then
			-- Non-roman locale: Prefer the system default for this alphabet
			-- because the user's chosen font (e.g. FRIZQT__.TTF) is unlikely
			-- to contain glyphs for Korean, Chinese, or Cyrillic.
			local defaultFile = nil
			if baseFont and baseFont.GetFontObjectForAlphabet then
				local defaultObj = baseFont:GetFontObjectForAlphabet(alphabet)
				if defaultObj then
					defaultFile, _, _ = defaultObj:GetFont()
				end
			end
			memberDef.file = defaultFile or fontPath
		else
			-- Secondary alphabet: Try to use system fallback
			local defaultFile = nil
			if baseFont then
				local defaultObj = baseFont:GetFontObjectForAlphabet(alphabet)
				if defaultObj then
					defaultFile, _, _ = defaultObj:GetFont()
				end
			end

			-- Keep user font as last resort if system default is missing
			memberDef.file = defaultFile or fontPath
		end

		table.insert(members, memberDef)
	end

	-- Create the Font Family Object
	local success, familyObj = pcall(CreateFontFamily, familyName, members)

	if not success or not familyObj then
		-- BFL:DebugPrint("CreateFontFamily failed for: " .. fontPath)
		return nil
	end

	-- Apply Shadow to all members
	local targetShadowParams = shadow and { 1, -1, 0, 0, 0, 1 } or { 0, 0, 0, 0, 0, 0 }

	for _, alphabet in ipairs(ALPHABETS) do
		local memberObj = familyObj:GetFontObjectForAlphabet(alphabet)
		if memberObj then
			memberObj:SetShadowOffset(targetShadowParams[1], targetShadowParams[2])
			memberObj:SetShadowColor(
				targetShadowParams[3],
				targetShadowParams[4],
				targetShadowParams[5],
				targetShadowParams[6]
			)
		end
	end

	-- Cache it
	FONT_CACHE[cacheKey] = familyObj
	return familyObj
end

-- ========================================
-- Font Family Logic
-- ========================================

-- Apply font to a FontString using the robust Family system
function FontManager:ApplyFont(fontString, fontPath, size, flags, shadow)
	if not fontString or not fontPath then
		return
	end

	-- Attempt to get/create the FontFamily object
	local familyObj = self:GetOrCreateFontFamily(fontPath, size, flags, shadow)

	if familyObj then
		-- Apply the Family Object
		fontString:SetFontObject(familyObj)
	else
		-- Fallback: Use SetFont directly if Family creation failed
		-- This loses alphabet backups but keeps text visible
		fontString:SetFont(fontPath, size, self:GetFontFlags(flags))
		if shadow then
			fontString:SetShadowOffset(1, -1)
			fontString:SetShadowColor(0, 0, 0, 1)
		else
			fontString:SetShadowOffset(0, 0)
			fontString:SetShadowColor(0, 0, 0, 0)
		end
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
	if not db then
		return false
	end
	return db:Get("compactMode", false)
end

-- Set compact mode (triggers UI refresh)
function FontManager:SetCompactMode(enabled)
	local db = GetDB()
	if not db then
		return
	end

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
