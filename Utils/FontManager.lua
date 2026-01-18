--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua"); -- BetterFriendlist - FontManager Module
-- Handles font sizing, scaling, and compact mode

local _, BFL = ...

-- Create FontManager namespace
BFL.FontManager = {}
local FontManager = BFL.FontManager

-- ========================================
-- Local References
-- ========================================
local GetDB = function() Perfy_Trace(Perfy_GetTime(), "Enter", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:13:14"); return Perfy_Trace_Passthrough("Leave", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:13:14", BFL:GetModule("DB")) end

-- ========================================
-- Public API
-- ========================================

-- Get button height based on compact mode setting
function FontManager:GetButtonHeight() Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:GetButtonHeight file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:20:0");
	local db = GetDB()
	if db and db:Get("compactMode", false) then
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetButtonHeight file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:20:0"); return 24 -- Compact height
	end
	Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetButtonHeight file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:20:0"); return 34 -- Normal height
end

-- Get font size multiplier based on settings
function FontManager:GetFontSizeMultiplier() Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0"); return 1.0 end
	
	local fontSize = db:Get("fontSize", "normal")
	
	if fontSize == "small" then
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0"); return 0.85
	elseif fontSize == "large" then
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0"); return 1.15
	else
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0"); return 1.0 -- normal
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetFontSizeMultiplier file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:29:0"); end

-- Apply font size to a font string based on settings
function FontManager:ApplyFontSize(fontString) Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:ApplyFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:45:0");
	if not fontString then Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:ApplyFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:45:0"); return end
	
	local multiplier = self:GetFontSizeMultiplier()
	
	-- Store base font info on first call
	if not fontString.baseFontSize then
		local font, size, flags = fontString:GetFont()
		if font and size then
			fontString.baseFontPath = font
			fontString.baseFontSize = size
			fontString.baseFontFlags = flags
		else
			Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:ApplyFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:45:0"); return -- Can't get font info
		end
	end
	
	-- Apply multiplier to base size
	local newSize = math.floor(fontString.baseFontSize * multiplier + 0.5)
	fontString:SetFont(fontString.baseFontPath, newSize, fontString.baseFontFlags)
Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:ApplyFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:45:0"); end

-- Get compact mode setting
function FontManager:GetCompactMode() Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:GetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:68:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:68:0"); return false end
	return Perfy_Trace_Passthrough("Leave", "FontManager:GetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:68:0", db:Get("compactMode", false))
end

-- Set compact mode (triggers UI refresh)
function FontManager:SetCompactMode(enabled) Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:SetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:75:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:SetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:75:0"); return end
	
	db:Set("compactMode", enabled)
	
	-- Force full display refresh for immediate update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:SetCompactMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:75:0"); end

-- Set font size (triggers UI refresh)
function FontManager:SetFontSize(size) Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:SetFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:88:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:SetFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:88:0"); return end
	
	-- Validate size
	if size ~= "small" and size ~= "normal" and size ~= "large" then
		size = "normal"
	end
	
	db:Set("fontSize", size)
	
	-- Force full display refresh for immediate update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:SetFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:88:0"); end

-- ========================================
-- Helper Functions
-- ========================================

-- Get recommended font object based on settings
function FontManager:GetRecommendedFont() Perfy_Trace(Perfy_GetTime(), "Enter", "FontManager:GetRecommendedFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:110:0");
	local fontSize = self:GetFontSizeMultiplier()
	
	if fontSize < 0.9 then
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetRecommendedFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:110:0"); return "BetterFriendlistFontNormalSmall"
	elseif fontSize > 1.1 then
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetRecommendedFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:110:0"); return "BetterFriendlistFontNormal"
	else
		Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetRecommendedFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:110:0"); return "BetterFriendlistFontNormalSmall"
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontManager:GetRecommendedFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua:110:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/FontManager.lua");