-- BetterFriendlist - ColorManager Module
-- Handles group color customization and management

local _, BFL = ...

-- Create ColorManager namespace
BFL.ColorManager = {}
local ColorManager = BFL.ColorManager

-- ========================================
-- Local References
-- ========================================
local GetDB = function() return BFL:GetModule("DB") end
local GetGroups = function() return BFL:GetModule("Groups") end

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
function ColorManager:GetGroupColor(groupId)
	-- Try to get color from Groups module first (active colors)
	local Groups = GetGroups()
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			return group.color.r, group.color.g, group.color.b
		end
	end
	
	-- Fall back to default color
	return self:GetDefaultColor(groupId)
end

-- Get color code string for a group (format: |cFFRRGGBB)
function ColorManager:GetGroupColorCode(groupId)
	local r, g, b = self:GetGroupColor(groupId)
	
	-- Convert to hex
	local hexR = string.format("%02x", math.floor(r * 255))
	local hexG = string.format("%02x", math.floor(g * 255))
	local hexB = string.format("%02x", math.floor(b * 255))
	
	return "|cFF" .. hexR .. hexG .. hexB
end

-- Set custom color for a group
function ColorManager:SetGroupColor(groupId, r, g, b)
	local db = GetDB()
	if not db then return end
	
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
end

-- Reset group color to default
function ColorManager:ResetGroupColor(groupId)
	local db = GetDB()
	if not db then return end
	
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
end

-- Get default color for a group
function ColorManager:GetDefaultColor(groupId)
	if groupId == "favorites" then
		local c = DEFAULT_COLORS.favorites
		return c.r, c.g, c.b
	elseif groupId == "nogroup" then
		local c = DEFAULT_COLORS.nogroup
		return c.r, c.g, c.b
	else
		local c = DEFAULT_COLORS.default
		return c.r, c.g, c.b
	end
end

-- Get all group colors (for settings UI)
function ColorManager:GetAllGroupColors()
	local Groups = GetGroups()
	if not Groups then return {} end
	
	local result = {}
	
	-- Get all groups from Groups module
	local allGroups = Groups:GetAll()
	
	for groupId, group in pairs(allGroups) do
		result[groupId] = {
			name = group.name,
			color = group.color or {r = 1, g = 1, b = 1}
		}
	end
	
	return result
end

-- Check if group has custom color
function ColorManager:HasCustomColor(groupId)
	local db = GetDB()
	if not db then return false end
	
	local groupColors = db:Get("groupColors", {})
	return groupColors[groupId] ~= nil
end

-- ========================================
-- Helper Functions
-- ========================================

-- Convert RGB to Hex string (without |c prefix)
function ColorManager:RGBToHex(r, g, b)
	local hexR = string.format("%02x", math.floor(r * 255))
	local hexG = string.format("%02x", math.floor(g * 255))
	local hexB = string.format("%02x", math.floor(b * 255))
	return hexR .. hexG .. hexB
end

-- Convert Hex string to RGB
function ColorManager:HexToRGB(hex)
	-- Remove any |c prefix if present
	hex = hex:gsub("|c[fF][fF]", "")
	
	if #hex ~= 6 then
		return 1, 1, 1 -- Return white if invalid
	end
	
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	
	return r, g, b
end
