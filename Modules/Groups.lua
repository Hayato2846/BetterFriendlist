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

function Groups:Initialize()
	-- Copy built-in groups
	for id, data in pairs(builtinGroups) do
		self.groups[id] = CopyTable(data)
	end
	
	-- Load custom groups from database
	local DB = BFL:GetModule("DB")
	for groupId, groupInfo in pairs(DB:GetCustomGroups()) do
		self.groups[groupId] = {
			id = groupId,
			name = groupInfo.name,
			collapsed = groupInfo.collapsed or false,
			builtin = false,
			order = groupInfo.order or 50,
			color = {r = 0, g = 0.7, b = 1.0}, -- Default blue
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
end

-- Get all groups
function Groups:GetAll()
	return self.groups
end

-- Get a specific group
function Groups:Get(groupId)
	return self.groups[groupId]
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
		color = {r = 0, g = 0.7, b = 1.0}, -- Default blue for custom groups
		icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
	}
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	DB:SaveCustomGroup(groupId, {
		name = groupName,
		collapsed = false,
		order = maxOrder + 1
	})
	
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
		return "bnet_" .. (friend.bnetAccountID or friend.battleTag or "")
	else
		return "wow_" .. (friend.name or "")
	end
end

-- Expose GetFriendUID globally for backward compatibility
_G.GetFriendUID = function(friend)
	return Groups:GetFriendUID(friend)
end
