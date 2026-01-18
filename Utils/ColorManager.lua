--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua"); -- BetterFriendlist - ColorManager Module
-- Handles group color customization and management

local _, BFL = ...

-- Create ColorManager namespace
BFL.ColorManager = {}
local ColorManager = BFL.ColorManager

-- ========================================
-- Local References
-- ========================================
local GetDB = function() Perfy_Trace(Perfy_GetTime(), "Enter", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:13:14"); return Perfy_Trace_Passthrough("Leave", "GetDB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:13:14", BFL:GetModule("DB")) end
local GetGroups = function() Perfy_Trace(Perfy_GetTime(), "Enter", "GetGroups file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:14:18"); return Perfy_Trace_Passthrough("Leave", "GetGroups file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:14:18", BFL:GetModule("Groups")) end

-- ========================================
-- Default Colors
-- ========================================
-- FFD100 = RGB(255, 209, 0) = normalized (1.0, 0.82, 0.0)
-- Using Blizzard UI gold color for consistency
local DEFAULT_COLOR_GOLD = {r = 1.0, g = 0.82, b = 0.0}

local DEFAULT_COLORS = {
	favorites = DEFAULT_COLOR_GOLD,
	nogroup = DEFAULT_COLOR_GOLD,
	default = DEFAULT_COLOR_GOLD,  -- For custom groups
}

-- ========================================
-- Public API
-- ========================================

-- Get RGB color for a group
function ColorManager:GetGroupColor(groupId) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:GetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:34:0");
	-- Try to get color from Groups module first (active colors)
	local Groups = GetGroups()
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			return Perfy_Trace_Passthrough("Leave", "ColorManager:GetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:34:0", group.color.r, group.color.g, group.color.b)
		end
	end
	
	-- Fall back to default color
	return Perfy_Trace_Passthrough("Leave", "ColorManager:GetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:34:0", self:GetDefaultColor(groupId))
end

-- Get color code string for a group (format: |cFFRRGGBB)
function ColorManager:GetGroupColorCode(groupId) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:GetGroupColorCode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:49:0");
	local r, g, b = self:GetGroupColor(groupId)
	
	-- Convert to hex
	local hexR = string.format("%02x", math.floor(r * 255))
	local hexG = string.format("%02x", math.floor(g * 255))
	local hexB = string.format("%02x", math.floor(b * 255))
	
	return Perfy_Trace_Passthrough("Leave", "ColorManager:GetGroupColorCode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:49:0", "|cFF" .. hexR .. hexG .. hexB)
end

-- Set custom color for a group
function ColorManager:SetGroupColor(groupId, r, g, b) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:SetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:61:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:SetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:61:0"); return end
	
	-- Save to database
	local groupColors = db:Get("groupColors", {})
	groupColors[groupId] = {r = r, g = g, b = b}
	db:Set("groupColors", groupColors)
	
	-- Update Groups module active color
	local Groups = GetGroups()
	if Groups then
		local group = Groups:Get(groupId)
		if group then
			group.color = {r = r, g = g, b = b}
		end
	end
	
	-- Force full display refresh for immediate color update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:SetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:61:0"); end

-- Reset group color to default
function ColorManager:ResetGroupColor(groupId) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:ResetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:86:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:ResetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:86:0"); return end
	
	-- Remove from database
	local groupColors = db:Get("groupColors", {})
	groupColors[groupId] = nil
	db:Set("groupColors", groupColors)
	
	-- Reset Groups module color to default
	local Groups = GetGroups()
	if Groups then
		local group = Groups:Get(groupId)
		if group then
			local r, g, b = self:GetDefaultColor(groupId)
			group.color = {r = r, g = g, b = b}
		end
	end
	
	-- Force full display refresh for immediate color update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:ResetGroupColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:86:0"); end

-- Get default color for a group
function ColorManager:GetDefaultColor(groupId) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:GetDefaultColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:112:0");
	if groupId == "favorites" then
		local c = DEFAULT_COLORS.favorites
		return Perfy_Trace_Passthrough("Leave", "ColorManager:GetDefaultColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:112:0", c.r, c.g, c.b)
	elseif groupId == "nogroup" then
		local c = DEFAULT_COLORS.nogroup
		return Perfy_Trace_Passthrough("Leave", "ColorManager:GetDefaultColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:112:0", c.r, c.g, c.b)
	else
		local c = DEFAULT_COLORS.default
		return Perfy_Trace_Passthrough("Leave", "ColorManager:GetDefaultColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:112:0", c.r, c.g, c.b)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:GetDefaultColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:112:0"); end

-- Get all group colors (for settings UI)
function ColorManager:GetAllGroupColors() Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:GetAllGroupColors file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:126:0");
	local Groups = GetGroups()
	if not Groups then return Perfy_Trace_Passthrough("Leave", "ColorManager:GetAllGroupColors file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:126:0", {}) end
	
	local result = {}
	
	-- Get all groups from Groups module
	local allGroups = Groups:GetAll()
	
	for groupId, group in pairs(allGroups) do
		result[groupId] = {
			name = group.name,
			color = group.color or {r = 1, g = 1, b = 1}
		}
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:GetAllGroupColors file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:126:0"); return result
end

-- Check if group has custom color
function ColorManager:HasCustomColor(groupId) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:HasCustomColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:146:0");
	local db = GetDB()
	if not db then Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:HasCustomColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:146:0"); return false end
	
	local groupColors = db:Get("groupColors", {})
	return Perfy_Trace_Passthrough("Leave", "ColorManager:HasCustomColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:146:0", groupColors[groupId] ~= nil)
end

-- ========================================
-- Helper Functions
-- ========================================

-- Convert RGB to Hex string (without |c prefix)
function ColorManager:RGBToHex(r, g, b) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:RGBToHex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:159:0");
	local hexR = string.format("%02x", math.floor(r * 255))
	local hexG = string.format("%02x", math.floor(g * 255))
	local hexB = string.format("%02x", math.floor(b * 255))
	return Perfy_Trace_Passthrough("Leave", "ColorManager:RGBToHex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:159:0", hexR .. hexG .. hexB)
end

-- Convert Hex string to RGB
function ColorManager:HexToRGB(hex) Perfy_Trace(Perfy_GetTime(), "Enter", "ColorManager:HexToRGB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:167:0");
	-- Remove any |c prefix if present
	hex = hex:gsub("|c[fF][fF]", "")
	
	if #hex ~= 6 then
		Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:HexToRGB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:167:0"); return 1, 1, 1 -- Return white if invalid
	end
	
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "ColorManager:HexToRGB file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua:167:0"); return r, g, b
end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Utils/ColorManager.lua");