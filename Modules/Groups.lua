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
	ingame = {
		id = "ingame",
		name = "In-Game",
		collapsed = false,
		builtin = true,
		order = 2,
		color = {r = 1.0, g = 0.82, b = 0.0}, -- Gold
		icon = "Interface\\Icons\\Inv_misc_groupneedmore"
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
	
	-- Check if Battle.net migration has already been done
	local bnetMigrationDone = DB:Get("bnetUIDMigrationDone_v2") -- Changed flag name to force re-run
	local wowMigrationDone = DB:Get("wowUIDMigrationDone_v1") -- New migration for WoW friends
	
	if bnetMigrationDone and wowMigrationDone then
		return -- Already migrated
	end
	
	-- Count old-style UIDs
	local oldBnetUIDs = {}
	local wowUIDsToMigrate = {}
	local totalMappings = 0
	
	for uid, groups in pairs(friendGroups) do
		-- Skip numeric array indices (corrupted data)
		if type(uid) == "string" then
			totalMappings = totalMappings + 1
			
			-- Battle.net: Old format "bnet_12345" where 12345 is numeric
			if not bnetMigrationDone and uid:match("^bnet_%d+$") then
				table.insert(oldBnetUIDs, uid)
			end
			
			-- WoW: Old format "wow_Name" without realm
			if not wowMigrationDone and uid:match("^wow_[^%-]+$") then
				-- Extract character name (without "wow_" prefix)
				local charName = uid:sub(5)
				-- Only migrate if name doesn't look like it already has realm (no "-")
				if not charName:find("-") then
					table.insert(wowUIDsToMigrate, {oldUID = uid, charName = charName, groups = groups})
				end
			end
		end
	end
	
	-- Debug output
	print("|cff00ff00BetterFriendlist:|r Migration check - Total friend mappings:", totalMappings)
	if not bnetMigrationDone then
		print("|cff00ff00BetterFriendlist:|r Migration check - Old Battle.net format:", #oldBnetUIDs)
	end
	if not wowMigrationDone then
		print("|cff00ff00BetterFriendlist:|r Migration check - WoW friends without realm:", #wowUIDsToMigrate)
	end
	
	-- Migrate Battle.net UIDs
	if not bnetMigrationDone and #oldBnetUIDs > 0 then
		-- Remove old-style UIDs (they are now invalid and can't be migrated)
		for _, uid in ipairs(oldBnetUIDs) do
			DB:SetFriendGroups(uid, nil) -- Remove assignment
		end
		
		-- Inform user about the migration
		print("|cff00ff00BetterFriendlist:|r Battle.net friend assignments have been updated to use persistent identifiers.")
		print("|cffff8800Note:|r Please re-assign your Battle.net friends to groups. This is a one-time migration.")
		print("|cffaaaaaa(Reason: bnetAccountID is temporary and changes each session)|r")
		
		DB:Set("bnetUIDMigrationDone_v2", true)
	end
	
	-- Migrate WoW UIDs (add realm)
	if not wowMigrationDone and #wowUIDsToMigrate > 0 then
		local playerRealm = GetNormalizedRealmName()
		local migrated = 0
		
		if playerRealm and playerRealm ~= "" then
			for _, entry in ipairs(wowUIDsToMigrate) do
				local newUID = "wow_" .. entry.charName .. "-" .. playerRealm
				
				-- Copy groups to new UID
				DB:SetFriendGroups(newUID, entry.groups)
				
				-- Remove old UID
				DB:SetFriendGroups(entry.oldUID, nil)
				
				migrated = migrated + 1
			end
			
			print("|cff00ff00BetterFriendlist:|r Migrated " .. migrated .. " WoW friend assignments to include realm names.")
			print("|cffaaaaaa(Now using format: CharacterName-RealmName for consistent identification)|r")
		else
			print("|cffff8800BetterFriendlist:|r Could not migrate WoW friend assignments (realm name unavailable).")
		end
		
		DB:Set("wowUIDMigrationDone_v1", true)
	end
end

-- Smart migration for WoW friends (v2) - Fixes missing realm in UIDs
function Groups:RunSmartMigration()
	local DB = BFL:GetModule("DB")
	if not DB then return end
	
	-- Check if already done
	if DB:Get("wowUIDMigrationDone_v2") then return end
	
	-- We need friend list data to be loaded
	local numFriends = C_FriendList.GetNumFriends()
	if numFriends == 0 then
		-- Try again later when list updates
		BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
			self:RunSmartMigration()
		end)
		return
	end
	
	-- Perform migration
	local friendGroups = DB:GetFriendGroups()
	if not friendGroups then return end
	
	local changesMade = false
	
	-- Build a lookup of Name -> {FullNames...} from current friend list
	local nameLookup = {}
	for i = 1, numFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name then
			-- Normalize to ensure we have the full Name-Realm format
			local normalized = BFL:NormalizeWoWFriendName(info.name)
			if normalized then
				-- Extract short name (before hyphen)
				local shortName = normalized:match("^([^%-]+)")
				if shortName then
					nameLookup[shortName] = nameLookup[shortName] or {}
					table.insert(nameLookup[shortName], normalized)
				end
			end
		end
	end
	
	-- Check for old UIDs in database
	for uid, groups in pairs(friendGroups) do
		-- Look for "wow_Name" where Name has no hyphen
		if type(uid) == "string" and uid:match("^wow_[^%-]+$") then
			local shortName = uid:sub(5) -- Remove "wow_" prefix
			
			-- Check if we have EXACTLY ONE match in the friend list
			local matches = nameLookup[shortName]
			if matches and #matches == 1 then
				local correctFullName = matches[1] -- e.g. "Copium-Mal'Ganis"
				local newUID = "wow_" .. correctFullName
				
				-- Only migrate if the new UID is actually different (it should be, since old had no hyphen)
				if newUID ~= uid then
					-- Check if target already has groups (safety check)
					local existing = DB:GetFriendGroups(newUID)
					if not existing or #existing == 0 then
						print("|cff00ff00BetterFriendlist:|r Migrating group settings for " .. shortName .. " -> " .. correctFullName)
						DB:SetFriendGroups(newUID, groups)
						DB:SetFriendGroups(uid, nil)
						changesMade = true
					end
				end
			end
		end
	end
	
	if changesMade then
		BFL:ForceRefreshFriendsList()
	end
	
	-- Mark as done
	DB:Set("wowUIDMigrationDone_v2", true)
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
	
	-- Load built-in group overrides
	local overrides = DB:Get("builtinGroupOverrides", {})
	for groupId, overrideData in pairs(overrides) do
		if self.groups[groupId] then
			if overrideData.name then
				self.groups[groupId].name = overrideData.name
			end
		end
	end
	
	-- Migrate old bnetAccountID-based friend assignments to battleTag-based
	self:MigrateFriendAssignments()
	
	-- Run smart migration for WoW friends (v2)
	self:RunSmartMigration()
	
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
	local enableInGame = DB:Get("enableInGameGroup", false)
	
	-- Filter out hidden built-in groups
	if not showFavorites or not enableInGame then
		local filtered = {}
		for id, group in pairs(self.groups) do
			local keep = true
			if id == "favorites" and not showFavorites then keep = false end
			if id == "ingame" and not enableInGame then keep = false end
			
			if keep then
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
	
	-- Update in memory
	group.name = newName
	
	local DB = BFL:GetModule("DB")
	
	if group.builtin then
		-- Save override for built-in group
		local overrides = DB:Get("builtinGroupOverrides", {})
		overrides[groupId] = overrides[groupId] or {}
		overrides[groupId].name = newName
		DB:Set("builtinGroupOverrides", overrides)
	else
		-- Update custom group in database
		local groupInfo = DB:GetCustomGroup(groupId)
		if groupInfo then
			groupInfo.name = newName
			DB:SaveCustomGroup(groupId, groupInfo)
		end
	end
	
	-- Refresh Settings UI if open
	local Settings = BFL:GetModule("Settings")
	if Settings and BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
		Settings:RefreshGroupList()
	end
	
	return true
end

-- Set group color
function Groups:SetColor(groupId, r, g, b)
	if not groupId or not r or not g or not b then
		return false, "Invalid parameters"
	end
	
	local group = self.groups[groupId]
	if not group then
		return false, "Group does not exist"
	end
	
	-- Update in memory
	group.color = {r = r, g = g, b = b}
	
	local DB = BFL:GetModule("DB")
	
	-- Save to database (same structure for built-in and custom)
	local groupColors = DB:Get("groupColors", {})
	groupColors[groupId] = {r = r, g = g, b = b}
	DB:Set("groupColors", groupColors)
	
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
	
	-- Force refresh of the friends list to update UI immediately
	BFL:ForceRefreshFriendsList()
	
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
	
	-- Force refresh of the friends list to update UI immediately
	BFL:ForceRefreshFriendsList()
	
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

-- Get sorted list of group IDs based on their configured order
-- Excludes "nogroup" by default since it's displayed separately at the end
function Groups:GetSortedGroupIds(includeNoGroup)
	local allGroups = self:GetAll()
	local sortedIds = {}
	
	for groupId, groupData in pairs(allGroups) do
		if includeNoGroup or groupId ~= "nogroup" then
			table.insert(sortedIds, {
				id = groupId,
				order = groupData.order or 999
			})
		end
	end
	
	-- Sort by order value
	table.sort(sortedIds, function(a, b)
		return a.order < b.order
	end)
	
	-- Extract just the IDs in sorted order
	local result = {}
	for _, entry in ipairs(sortedIds) do
		table.insert(result, entry.id)
	end
	
	return result
end
