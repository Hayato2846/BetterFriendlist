-- Modules/Database.lua
-- Database module for managing SavedVariables

local ADDON_NAME, BFL = ...
local DB = BFL:RegisterModule("DB", {})

-- Default values
local defaults = {
	groupStates = {},
	customGroups = {},
	friendGroups = {},
	showBlizzardOption = false, -- Show "Show Blizzard's Friendlist" in menu
	groupOrder = nil, -- nil = use default order (favorites, custom alphabetically, nogroup)
	groupColors = {}, -- {groupId: {r, g, b}} - custom colors for group headers
	-- Visual Settings
	compactMode = false, -- Use compact button layout
	fontSize = "normal", -- "small", "normal", "large"
	-- Debug Settings
	debugPrintEnabled = false, -- Toggle debug prints with /bfl debug print
	version = BFL.Version
}

function DB:Initialize()
	-- Initialize SavedVariables
	if not BetterFriendlistDB then
		BetterFriendlistDB = {}
	end
	
	-- Apply defaults
	for key, value in pairs(defaults) do
		if BetterFriendlistDB[key] == nil then
			BetterFriendlistDB[key] = type(value) == "table" and {} or value
		end
	end
	
	-- Version migration if needed
	if BetterFriendlistDB.version ~= BFL.Version then
		self:MigrateData(BetterFriendlistDB.version, BFL.Version)
		BetterFriendlistDB.version = BFL.Version
	end
end

function DB:MigrateData(oldVersion, newVersion)
	-- Future: Add data migration logic here
	-- print("Migrating data from", oldVersion or "unknown", "to", newVersion)
end

-- Get a value from the database
function DB:Get(key, default)
	if BetterFriendlistDB[key] ~= nil then
		return BetterFriendlistDB[key]
	end
	return default
end

-- Set a value in the database
function DB:Set(key, value)
	BetterFriendlistDB[key] = value
end

-- Get group state (collapsed/expanded)
function DB:GetGroupState(groupId)
	return BetterFriendlistDB.groupStates[groupId]
end

-- Set group state
function DB:SetGroupState(groupId, collapsed)
	BetterFriendlistDB.groupStates[groupId] = collapsed
end

-- Get custom groups
function DB:GetCustomGroups()
	return BetterFriendlistDB.customGroups
end

-- Get custom group info
function DB:GetCustomGroup(groupId)
	return BetterFriendlistDB.customGroups[groupId]
end

-- Save custom group
function DB:SaveCustomGroup(groupId, groupInfo)
	BetterFriendlistDB.customGroups[groupId] = groupInfo
end

-- Delete custom group
function DB:DeleteCustomGroup(groupId)
	BetterFriendlistDB.customGroups[groupId] = nil
end

-- Get friend's groups
function DB:GetFriendGroups(friendUID)
	-- If friendUID is provided, return groups for that specific friend
	if friendUID then
		return BetterFriendlistDB.friendGroups[friendUID] or {}
	end
	-- If no friendUID provided, return ALL friendGroups mappings
	return BetterFriendlistDB.friendGroups or {}
end

-- Set friend's groups
function DB:SetFriendGroups(friendUID, groups)
	if not groups or #groups == 0 then
		BetterFriendlistDB.friendGroups[friendUID] = nil
	else
		BetterFriendlistDB.friendGroups[friendUID] = groups
	end
end

-- Add friend to group
function DB:AddFriendToGroup(friendUID, groupId)
	if not BetterFriendlistDB.friendGroups[friendUID] then
		BetterFriendlistDB.friendGroups[friendUID] = {}
	end
	
	-- Check if already in group
	for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
		if gid == groupId then
			return false -- Already in group
		end
	end
	
	table.insert(BetterFriendlistDB.friendGroups[friendUID], groupId)
	return true
end

-- Remove friend from group
function DB:RemoveFriendFromGroup(friendUID, groupId)
	if not BetterFriendlistDB.friendGroups[friendUID] then
		return false
	end
	
	for i = #BetterFriendlistDB.friendGroups[friendUID], 1, -1 do
		if BetterFriendlistDB.friendGroups[friendUID][i] == groupId then
			table.remove(BetterFriendlistDB.friendGroups[friendUID], i)
			
			-- Clean up if no groups left
			if #BetterFriendlistDB.friendGroups[friendUID] == 0 then
				BetterFriendlistDB.friendGroups[friendUID] = nil
			end
			
			return true
		end
	end
	
	return false
end

-- Check if friend is in group
function DB:IsFriendInGroup(friendUID, groupId)
	if not BetterFriendlistDB.friendGroups[friendUID] then
		return false
	end
	
	for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
		if gid == groupId then
			return true
		end
	end
	
	return false
end

-- Get all friends in database
function DB:GetAllFriendUIDs()
	local uids = {}
	for uid in pairs(BetterFriendlistDB.friendGroups) do
		table.insert(uids, uid)
	end
	return uids
end
