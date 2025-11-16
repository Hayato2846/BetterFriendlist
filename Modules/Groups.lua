-- Modules/Groups.lua
-- Group management module

local ADDON_NAME, BFL = ...
local Groups = BFL:RegisterModule("Groups", {})

-- Built-in groups
local builtinGroups = {
	favorites = {
		id = "favorites",
		name = "Favorites",
		collapsed = false,
		builtin = true,
		order = 1,
		color = {r = 1.0, g = 0.82, b = 0.0}, -- Gold
		icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
	},
	nogroup = {
		id = "nogroup",
		name = "No Group",
		collapsed = false,
		builtin = true,
		order = 999,
		color = {r = 0.5, g = 0.5, b = 0.5}, -- Gray
		icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
	}
}

-- All groups (built-in + custom)
Groups.groups = {}

-- Migrate old bnetAccountID-based UIDs to battleTag-based UIDs
function Groups:MigrateFriendAssignments()
	local DB = BFL:GetModule("DB")
	if not DB then return end
	local friendGroups = DB:GetFriendGroups() -- Get ALL friendGroups
	if not friendGroups then return end
	
	-- Check if migration has already been done
	local migrationDone = DB:Get("bnetUIDMigrationDone_v2") -- Changed flag name to force re-run
	if migrationDone then
		return -- Already migrated
	end
	
	-- Count old-style bnet UIDs (format: "bnet_12345" where 12345 is numeric)
	local oldBnetUIDs = {}
	local totalMappings = 0
	
	for uid, groups in pairs(friendGroups) do
		-- Skip numeric array indices (corrupted data)
		if type(uid) == "string" then
			totalMappings = totalMappings + 1
			if uid:match("^bnet_%d+$") then
				table.insert(oldBnetUIDs, uid)
			end
		end
	end
	
	-- Debug output
	print("|cff00ff00BetterFriendlist:|r Migration check - Total friend mappings:", totalMappings)
	print("|cff00ff00BetterFriendlist:|r Migration check - Old format (bnet_numeric):", #oldBnetUIDs)
	
	if #oldBnetUIDs > 0 then
		-- Remove old-style UIDs (they are now invalid and can't be migrated)
		for _, uid in ipairs(oldBnetUIDs) do
			DB:SetFriendGroups(uid, nil) -- Remove assignment
		end
		
		-- Inform user about the migration
		print("|cff00ff00BetterFriendlist:|r Battle.net friend assignments have been updated to use persistent identifiers.")
		print("|cffff8800Note:|r Please re-assign your Battle.net friends to groups. This is a one-time migration.")
		print("|cffaaaaaa(Reason: bnetAccountID is temporary and changes each session)|r")
	end
	
	-- Mark migration as done
	DB:Set("bnetUIDMigrationDone_v2", true)
end

function Groups:Initialize()
	-- Copy built-in groups
	for id, data in pairs(builtinGroups) do
		self.groups[id] = CopyTable(data)
	end
	
	-- Load custom groups from database
	local DB = BFL:GetModule("DB")
	if not DB or not BetterFriendlistDB then
		-- DB not ready yet, skip initialization
		return
	end
	
	-- Migrate old bnetAccountID-based friend assignments to battleTag-based
	self:MigrateFriendAssignments()
	
	local customGroups = DB:GetCustomGroups()
	if not customGroups then return end
	
	for groupId, groupInfo in pairs(customGroups) do
		self.groups[groupId] = {
			id = groupId,
			name = groupInfo.name,
			collapsed = groupInfo.collapsed or false,
			builtin = false,
			order = groupInfo.order or 50,
			color = {r = 1.0, g = 0.82, b = 0.0}, -- Default gold
			icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
		}
	end
	
	-- Load collapsed states
	for groupId, groupData in pairs(self.groups) do
		local collapsed = DB:GetGroupState(groupId)
		if collapsed ~= nil then
			groupData.collapsed = collapsed
		end
	end
	
	-- Apply custom group colors from settings
	local groupColors = DB:Get("groupColors")
	if groupColors and type(groupColors) == "table" then
		for groupId, color in pairs(groupColors) do
			if self.groups[groupId] and color.r and color.g and color.b then
				self.groups[groupId].color = {r = color.r, g = color.g, b = color.b}
			end
		end
	end
	
	-- Apply saved group order from settings
	local savedOrder = DB:Get("groupOrder")
	if savedOrder and type(savedOrder) == "table" and #savedOrder > 0 then
		-- Apply order from saved settings
		for i, groupId in ipairs(savedOrder) do
			if self.groups[groupId] then
				self.groups[groupId].order = i
			end
		end
		-- Groups not in saved order get high order values
		for groupId, groupData in pairs(self.groups) do
			local found = false
			for _, savedId in ipairs(savedOrder) do
				if savedId == groupId then
					found = true
					break
				end
			end
			if not found then
				groupData.order = 1000 + (#savedOrder)
			end
		end
	end
end

-- Get all groups
function Groups:GetAll()
	-- Check if DB is initialized before checking settings
	local DB = BFL:GetModule("DB")
	if not DB or not BetterFriendlistDB then
		-- DB not yet initialized, return all groups including favorites
		return self.groups
	end
	
	local showFavorites = DB:Get("showFavoritesGroup", true)
	
	-- If Favorites should be hidden, filter it out
	if not showFavorites then
		local filtered = {}
		for id, group in pairs(self.groups) do
			if id ~= "favorites" then
				filtered[id] = group
			end
		end
		return filtered
	end
	
	return self.groups
end

-- Get a specific group
function Groups:Get(groupId)
	return self.groups[groupId]
end

-- Get group ID by name (for migration)
function Groups:GetGroupIdByName(groupName)
	for groupId, groupData in pairs(self.groups) do
		if groupData.name == groupName then
			return groupId
		end
	end
	return nil
end

-- Create a new custom group
function Groups:Create(groupName)
	if not groupName or groupName == "" then
		return false, "Group name cannot be empty"
	end
	
	-- Generate unique ID from name
	local groupId = "custom_" .. groupName:gsub("%s+", "_"):lower()
	
	-- Check if group already exists
	if self.groups[groupId] then
		return false, "Group already exists"
	end
	
	-- Find next order value (place custom groups between Favorites and No Group)
	local maxOrder = 1
	for _, groupData in pairs(self.groups) do
		if not groupData.builtin or groupData.id == "favorites" then
			maxOrder = math.max(maxOrder, groupData.order or 1)
		end
	end
	
	-- Create group
	self.groups[groupId] = {
		id = groupId,
		name = groupName,
		collapsed = false,
		builtin = false,
		order = maxOrder + 1,
		color = {r = 1.0, g = 0.82, b = 0.0}, -- Default gold for all groups
		icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
	}
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	DB:SaveCustomGroup(groupId, {
		name = groupName,
		collapsed = false,
		order = maxOrder + 1
	})
	
	-- Refresh Settings UI if open
	local Settings = BFL:GetModule("Settings")
	if Settings and BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
		Settings:RefreshGroupList()
	end
	
	return true, groupId
end

-- Create a new custom group with specific order (for migration)
function Groups:CreateWithOrder(groupName, orderValue)
	if not groupName or groupName == "" then
		return false, "Group name cannot be empty"
	end
	
	-- Generate unique ID from name
	local groupId = "custom_" .. groupName:gsub("%s+", "_"):lower()
	
	-- Check if group already exists
	if self.groups[groupId] then
		return false, "Group already exists"
	end
	
	-- Create group with specified order
	self.groups[groupId] = {
		id = groupId,
		name = groupName,
		collapsed = false,
		builtin = false,
		order = orderValue,
		color = {r = 1.0, g = 0.82, b = 0.0}, -- Default gold for all groups
		icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
	}
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	DB:SaveCustomGroup(groupId, {
		name = groupName,
		collapsed = false,
		order = orderValue
	})
	
	-- Refresh Settings UI if open
	local Settings = BFL:GetModule("Settings")
	if Settings and BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
		Settings:RefreshGroupList()
	end
	
	return true, groupId
end

-- Rename a custom group
function Groups:Rename(groupId, newName)
	if not groupId or not newName or newName == "" then
		return false, "Invalid group name"
	end
	
	local group = self.groups[groupId]
	if not group then
		return false, "Group does not exist"
	end
	
	if group.builtin then
		return false, "Cannot rename built-in groups"
	end
	
	-- Update in memory
	group.name = newName
	
	-- Update in database
	local DB = BFL:GetModule("DB")
	local groupInfo = DB:GetCustomGroup(groupId)
	if groupInfo then
		groupInfo.name = newName
		DB:SaveCustomGroup(groupId, groupInfo)
	end
	
	-- Refresh Settings UI if open
	local Settings = BFL:GetModule("Settings")
	if Settings and BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
		Settings:RefreshGroupList()
	end
	
	return true
end

-- Delete a custom group
function Groups:Delete(groupId)
	if not groupId then
		return false, "Invalid group ID"
	end
	
	local group = self.groups[groupId]
	if not group then
		return false, "Group does not exist"
	end
	
	if group.builtin then
		return false, "Cannot delete built-in groups"
	end
	
	-- Remove from memory
	self.groups[groupId] = nil
	
	-- Remove from database
	local DB = BFL:GetModule("DB")
	DB:DeleteCustomGroup(groupId)
	
	-- Refresh Settings UI if open
	local Settings = BFL:GetModule("Settings")
	if Settings and BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
		Settings:RefreshGroupList()
	end
	
	-- Remove all friend assignments to this group
	for _, friendUID in ipairs(DB:GetAllFriendUIDs()) do
		DB:RemoveFriendFromGroup(friendUID, groupId)
	end
	
	return true
end

-- Toggle group collapsed state
function Groups:Toggle(groupId)
	local group = self.groups[groupId]
	if not group then
		return false
	end
	
	group.collapsed = not group.collapsed
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	DB:SetGroupState(groupId, group.collapsed)
	
	return true
end

-- Set group collapsed state (for Collapse/Expand All)
function Groups:SetCollapsed(groupId, collapsed)
	local group = self.groups[groupId]
	if not group then
		return false
	end
	
	group.collapsed = collapsed
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	DB:SetGroupState(groupId, group.collapsed)
	
	return true
end

-- Check if friend is in group
function Groups:IsFriendInGroup(friendUID, groupId)
	local DB = BFL:GetModule("DB")
	return DB:IsFriendInGroup(friendUID, groupId)
end

-- Toggle friend in group (add if not present, remove if present)
function Groups:ToggleFriendInGroup(friendUID, groupId)
	if not friendUID or not groupId then
		return false
	end
	
	-- Don't allow adding to builtin groups (except they're managed automatically)
	if self.groups[groupId] and self.groups[groupId].builtin then
		return false
	end
	
	local DB = BFL:GetModule("DB")
	
	if DB:IsFriendInGroup(friendUID, groupId) then
		-- Remove from group
		return DB:RemoveFriendFromGroup(friendUID, groupId)
	else
		-- Add to group
		return DB:AddFriendToGroup(friendUID, groupId)
	end
end

-- Remove friend from group
function Groups:RemoveFriendFromGroup(friendUID, groupId)
	local DB = BFL:GetModule("DB")
	return DB:RemoveFriendFromGroup(friendUID, groupId)
end

-- Get all groups a friend is in
function Groups:GetFriendGroups(friendUID)
	local DB = BFL:GetModule("DB")
	return DB:GetFriendGroups(friendUID)
end

-- Get count of friends in a group
function Groups:GetMemberCount(groupId, friendsList)
	local count = 0
	local DB = BFL:GetModule("DB")
	
	for _, friend in ipairs(friendsList or {}) do
		local friendUID = self:GetFriendUID(friend)
		if friendUID then
			-- Check for built-in groups
			if groupId == "favorites" and friend.type == "bnet" and friend.isFavorite then
				count = count + 1
			elseif groupId == "nogroup" then
				-- Check if friend is in any custom group
				local inAnyGroup = false
				if friend.type == "bnet" and friend.isFavorite then
					inAnyGroup = true
				end
				if not inAnyGroup and DB:GetFriendGroups(friendUID) then
					for _, gid in ipairs(DB:GetFriendGroups(friendUID)) do
						if self.groups[gid] and not self.groups[gid].builtin then
							inAnyGroup = true
							break
						end
					end
				end
				if not inAnyGroup then
					count = count + 1
				end
			else
				-- Check for custom groups
				if DB:IsFriendInGroup(friendUID, groupId) then
					count = count + 1
				end
			end
		end
	end
	
	return count
end

-- Helper function to get friend unique ID
function Groups:GetFriendUID(friend)
	if not friend then return nil end
	if friend.type == "bnet" then
		-- Use battleTag as persistent identifier (bnetAccountID is temporary per session)
		if friend.battleTag then
			return "bnet_" .. friend.battleTag
		else
			-- Fallback to bnetAccountID only if battleTag is unavailable (should never happen)
			return "bnet_" .. tostring(friend.bnetAccountID or "unknown")
		end
	else
		return "wow_" .. (friend.name or "")
	end
end

-- Expose GetFriendUID globally for backward compatibility
_G.GetFriendUID = function(friend)
	return Groups:GetFriendUID(friend)
end
