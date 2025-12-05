-- BetterFriendlist - FontManager Module
-- Handles font sizing, scaling, and compact mode

local _, BFL = ...

-- Create FontManager namespace
BFL.FontManager = {}
local FontManager = BFL.FontManager

-- ========================================
-- Local References
-- ========================================
local GetDB = function() return BFL:GetModule("DB") end

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
	local db = GetDB()
	if not db then return 1.0 end
	
	local fontSize = db:Get("fontSize", "normal")
	
	if fontSize == "small" then
		return 0.85
	elseif fontSize == "large" then
		return 1.15
	else
		return 1.0 -- normal
	end
end

-- Apply font size to a font string based on settings
function FontManager:ApplyFontSize(fontString)
	if not fontString then return end
	
	local multiplier = self:GetFontSizeMultiplier()
	
	-- Store base font info on first call
	if not fontString.baseFontSize then
		local font, size, flags = fontString:GetFont()
		if font and size then
			fontString.baseFontPath = font
			fontString.baseFontSize = size
			fontString.baseFontFlags = flags
		else
			return -- Can't get font info
		end
	end
	
	-- Apply multiplier to base size
	local newSize = math.floor(fontString.baseFontSize * multiplier + 0.5)
	fontString:SetFont(fontString.baseFontPath, newSize, fontString.baseFontFlags)
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
	local db = GetDB()
	if not db then return end
	
	-- Validate size
	if size ~= "small" and size ~= "normal" and size ~= "large" then
		size = "normal"
	end
	
	db:Set("fontSize", size)
	
	-- Force full display refresh for immediate update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

-- ========================================
-- Helper Functions
-- ========================================

-- Get recommended font object based on settings
function FontManager:GetRecommendedFont()
	local fontSize = self:GetFontSizeMultiplier()
	
	if fontSize < 0.9 then
		return "GameFontNormalSmall"
	elseif fontSize > 1.1 then
		return "GameFontNormal"
	else
		return "GameFontNormalSmall"
	end
end
