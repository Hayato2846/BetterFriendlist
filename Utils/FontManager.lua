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
-- Advanced Font Family System (Chattynator-Implementation)
-- ========================================

local FONT_CACHE = {}
-- NOTE: "japanese" is excluded as it is not a standard CreateFontFamily member key in all client versions.
-- CJK characters for Japanese are typically covered by the "korean" or Chinese fonts in WoW's fallback system.
local ALPHABETS = {"roman", "korean", "simplifiedchinese", "traditionalchinese", "russian"}

-- Map Locale to Alphabet
local function GetLocaleAlphabet()
    local locale = GetLocale()
    if locale == "koKR" then return "korean"
    elseif locale == "zhCN" then return "simplifiedchinese"
    elseif locale == "zhTW" then return "traditionalchinese"
    elseif locale == "ruRU" then return "russian"
    -- jaJP uses standard fonts (often maps to Roman or Korean internally)
    -- We default to "roman" so the user's chosen font is used for the main text.
    else return "roman" end
end

local CURRENT_ALPHABET = GetLocaleAlphabet()
local FAMILY_COUNTER = 0

-- Generate and Cache FontFamily
function FontManager:GetOrCreateFontFamily(fontPath, size, flags, shadow)
    -- Normalize inputs
    size = math.floor(size + 0.5) -- Round to integer
    flags = flags or ""
    if flags == "NONE" then flags = "" end
    
    local shadowKey = shadow and "SHADOW" or "NONE"
    
    -- Create Cache Key
    local cacheKey = string.format("%s_%d_%s_%s", fontPath, size, flags, shadowKey)
    
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
        
        if alphabet == CURRENT_ALPHABET then
             -- Active locale: Use user's chosen font
             memberDef.file = fontPath
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
        BFL:DebugPrint("CreateFontFamily failed for: " .. fontPath)
        return nil
    end
    
    -- Apply Shadow to all members
    local targetShadowParams = shadow and {1, -1, 0, 0, 0, 1} or {0, 0, 0, 0, 0, 0}
    
    for _, alphabet in ipairs(ALPHABETS) do
        local memberObj = familyObj:GetFontObjectForAlphabet(alphabet)
        if memberObj then
            memberObj:SetShadowOffset(targetShadowParams[1], targetShadowParams[2])
            memberObj:SetShadowColor(targetShadowParams[3], targetShadowParams[4], targetShadowParams[5], targetShadowParams[6])
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
    if not fontString or not fontPath then return end

    -- Attempt to get/create the FontFamily object
    local familyObj = self:GetOrCreateFontFamily(fontPath, size, flags, shadow)
    
    if familyObj then
        -- Apply the Family Object
        fontString:SetFontObject(familyObj)
    else
        -- Fallback: Use SetFont directly if Family creation failed
        -- This loses alphabet backups but keeps text visible
        fontString:SetFont(fontPath, size, flags)
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
