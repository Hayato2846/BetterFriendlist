-- Modules/FriendsList.lua
-- Friends List Core Logic Module

local ADDON_NAME, BFL = ...
local FriendsList = BFL:RegisterModule("FriendsList", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB() return BFL:GetModule("DB") end
local function GetGroups() return BFL:GetModule("Groups") end
local function GetColorManager() return BFL.ColorManager end
local function GetFontManager() return BFL.FontManager end

-- ========================================
-- Constants
-- ========================================
local BUTTON_TYPE_FRIEND = 1
local BUTTON_TYPE_GROUP_HEADER = 2

-- Invite restriction constants (matching Blizzard's)
local INVITE_RESTRICTION_NONE = 0
local INVITE_RESTRICTION_LEADER = 1
local INVITE_RESTRICTION_FACTION = 2
local INVITE_RESTRICTION_REALM = 3
local INVITE_RESTRICTION_INFO = 4
local INVITE_RESTRICTION_CLIENT = 5
local INVITE_RESTRICTION_WOW_PROJECT_ID = 6
local INVITE_RESTRICTION_WOW_PROJECT_MAINLINE = 7
local INVITE_RESTRICTION_WOW_PROJECT_CLASSIC = 8
local INVITE_RESTRICTION_MOBILE = 9
local INVITE_RESTRICTION_REGION = 10
local INVITE_RESTRICTION_QUEST_SESSION = 11
local INVITE_RESTRICTION_NO_GAME_ACCOUNTS = 12

-- ========================================
-- Module State
-- ========================================
FriendsList.friendsList = {}      -- Raw friends data from API
FriendsList.displayList = {}      -- Processed display list with groups
FriendsList.searchText = ""       -- Current search filter
FriendsList.filterMode = "all"    -- Current filter mode: all, online, offline, wow, bnet
FriendsList.sortMode = "status"   -- Current sort mode: status, name, level, zone

-- Reference to Groups
local friendGroups = {}

-- ========================================
-- Private Helper Functions
-- ========================================

-- Count table entries (replacement for tsize)
local function CountTableEntries(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- Get last online time text (from Blizzard's FriendsFrame)
local function GetLastOnlineTime(timeDifference)
	if not timeDifference then
		timeDifference = 0
	end
	
	timeDifference = time() - timeDifference
	
	if timeDifference < 60 then
		return LASTONLINE_SECS
	elseif timeDifference >= 60 and timeDifference < 3600 then
		return string.format(LASTONLINE_MINUTES, math.floor(timeDifference / 60))
	elseif timeDifference >= 3600 and timeDifference < 86400 then
		return string.format(LASTONLINE_HOURS, math.floor(timeDifference / 3600))
	elseif timeDifference >= 86400 and timeDifference < 2592000 then
		return string.format(LASTONLINE_DAYS, math.floor(timeDifference / 86400))
	elseif timeDifference >= 2592000 and timeDifference < 31536000 then
		return string.format(LASTONLINE_MONTHS, math.floor(timeDifference / 2592000))
	else
		return string.format(LASTONLINE_YEARS, math.floor(timeDifference / 31536000))
	end
end

local function GetLastOnlineText(accountInfo)
	if not accountInfo or not accountInfo.lastOnlineTime or accountInfo.lastOnlineTime == 0 then
		return FRIENDS_LIST_OFFLINE
	else
		return string.format(BNET_LAST_ONLINE_TIME, GetLastOnlineTime(accountInfo.lastOnlineTime))
	end
end

-- Get friend unique ID (matching BetterFriendlist.lua format)
local function GetFriendUID(friend)
	if not friend then return nil end
	if friend.type == "bnet" then
		-- Must use tostring() to match the global GetFriendUID function
		if friend.bnetAccountID then
			return "bnet_" .. tostring(friend.bnetAccountID)
		else
			return "bnet_" .. (friend.battleTag or "unknown")
		end
	else
		return "wow_" .. (friend.name or "")
	end
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function FriendsList:Initialize()
	-- Sync groups from Groups module
	self:SyncGroups()
	
	-- Register event callbacks for friend list updates
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
		self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function(...)
		self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(...)
		self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(...)
		self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function(...)
		self:OnFriendListUpdate(...)
	end, 10)
end

-- Handle friend list update events
function FriendsList:OnFriendListUpdate(...)
	-- Update will be triggered by the UI if visible
	-- This callback just ensures the module is aware of the event
	-- The actual update is throttled in the UI layer
end

-- Sync groups from Groups module
function FriendsList:SyncGroups()
	local Groups = GetGroups()
	if Groups then
		friendGroups = Groups:GetAll()
	else
		-- Fallback: Use built-in groups
		friendGroups = {
			favorites = {
				id = "favorites",
				name = "Favorites",
				collapsed = false,
				builtin = true,
				order = 1,
				color = {r = 1.0, g = 0.82, b = 0.0},
				icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
			},
			nogroup = {
				id = "nogroup",
				name = "No Group",
				collapsed = false,
				builtin = true,
				order = 999,
				color = {r = 0.5, g = 0.5, b = 0.5},
				icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
			}
		}
	end
end

-- Update the friends list from WoW API
function FriendsList:UpdateFriendsList()
	wipe(self.friendsList)
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Get Battle.net friends
	local bnetFriends = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendAccountInfo or nil
	if bnetFriends then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		
		for i = 1, numBNetTotal do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local friend = {
					type = "bnet",
					index = i,
					bnetAccountID = accountInfo.bnetAccountID,
					accountName = (accountInfo.accountName ~= "???") and accountInfo.accountName or nil,
					battleTag = accountInfo.battleTag,
					connected = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline or false,
					note = accountInfo.note,
					isFavorite = accountInfo.isFavorite,
					gameAccountInfo = accountInfo.gameAccountInfo,
					lastOnlineTime = accountInfo.lastOnlineTime,
				}
				
				-- If they're playing WoW, get game info (EXACT COPY OF OLD LOGIC)
				if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
					local gameInfo = accountInfo.gameAccountInfo
					if gameInfo.clientProgram == "WoW" or gameInfo.clientProgram == "WTCG" then
						friend.characterName = gameInfo.characterName
						friend.className = gameInfo.className
						friend.areaName = gameInfo.areaName
						friend.level = gameInfo.characterLevel
						friend.realmName = gameInfo.realmName
						friend.factionName = gameInfo.factionName
						friend.timerunningSeasonID = gameInfo.timerunningSeasonID
					elseif gameInfo.clientProgram == "BSAp" then
						friend.gameName = "Mobile"
					elseif gameInfo.clientProgram == "App" then
						friend.gameName = "In App"
					else
						friend.gameName = gameInfo.clientProgram or "Unknown Game"
					end
				end
				
				table.insert(self.friendsList, friend)
			end
		end
	end
	
	-- Get WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends()
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo then
			local friend = {
				type = "wow",
				index = i,
				name = friendInfo.name,
				connected = friendInfo.connected,
				level = friendInfo.level,
				className = friendInfo.className,
				area = friendInfo.area,
				notes = friendInfo.notes,
			}
			table.insert(self.friendsList, friend)
		end
	end
	
	-- Apply filters and sort
	self:ApplyFilters()
	self:ApplySort()
end

-- Apply search and filter to friends list
function FriendsList:ApplyFilters()
	-- Filter will be applied in BuildDisplayList
end

-- Apply sort order to friends list
function FriendsList:ApplySort()
	local sortMode = self.sortMode
	
	table.sort(self.friendsList, function(a, b)
		if sortMode == "status" then
			-- Sort by online status first (use 'connected' not 'isOnline')
			local aOnline = (a.type == "bnet" and a.connected) or (a.type == "wow" and a.connected)
			local bOnline = (b.type == "bnet" and b.connected) or (b.type == "wow" and b.connected)
			
			if aOnline ~= bOnline then
				return aOnline
			end
			
			-- Then by DND/AFK priority
			local function GetStatusPriority(friend)
				if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
					return 3 -- Offline lowest priority
				end
				
				if friend.type == "bnet" and friend.gameAccountInfo then
					local gameInfo = friend.gameAccountInfo
					if gameInfo.isDND then return 1 end
					if gameInfo.isAFK or gameInfo.clientProgram == "BSAp" then return 2 end
					return 0
				end
				
				return 0
			end
			
			local aPriority = GetStatusPriority(a)
			local bPriority = GetStatusPriority(b)
			
			if aPriority ~= bPriority then
				return aPriority < bPriority
			end
			
			-- Same status, sort by name
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
			
		elseif sortMode == "name" then
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
			
		elseif sortMode == "level" then
			local levelA = a.level or 0
			local levelB = b.level or 0
			if levelA ~= levelB then
				return levelA > levelB
			end
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
			
		elseif sortMode == "zone" then
			local zoneA = a.areaName or a.area or ""
			local zoneB = b.areaName or b.area or ""
			if zoneA ~= zoneB then
				return zoneA:lower() < zoneB:lower()
			end
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
		end
		
		-- Default fallback
		local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
		local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
		return (nameA or ""):lower() < (nameB or ""):lower()
	end)
end

-- Build display list with groups and headers
function FriendsList:BuildDisplayList()
	wipe(self.displayList)
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Separate friends into groups
	local groupedFriends = {
		favorites = {},
		nogroup = {}
	}
	
	-- Initialize custom group tables
	for groupId, groupData in pairs(friendGroups) do
		if not groupData.builtin or groupId == "favorites" or groupId == "nogroup" then
			groupedFriends[groupId] = groupedFriends[groupId] or {}
		end
	end
	
	-- Get DB
	local DB = GetDB()
	if not DB then 
		return 
	end
	
	-- Group friends
	for _, friend in ipairs(self.friendsList) do
		-- Apply filters
		if self:PassesFilters(friend) then
			local isInAnyGroup = false
			local friendUID = GetFriendUID(friend)
			
			-- Check if favorite (Battle.net only)
			if friend.type == "bnet" and friend.isFavorite then
				table.insert(groupedFriends.favorites, friend)
				isInAnyGroup = true
			end
			
			-- Check for custom groups (DIRECT ACCESS TO DB LIKE OLD CODE)
			if BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
				local groups = BetterFriendlistDB.friendGroups[friendUID]
				for _, groupId in ipairs(groups) do
					-- Skip invalid entries (corrupted data like boolean 'true')
					if type(groupId) == "string" and groupedFriends[groupId] then
						table.insert(groupedFriends[groupId], friend)
						isInAnyGroup = true
					end
				end
			end
			
			-- Add to "No Group" if not in any group
			if not isInAnyGroup then
				table.insert(groupedFriends.nogroup, friend)
			end
		end
	end
	
	-- Build display list in group order
	local orderedGroups = {}
	for _, groupData in pairs(friendGroups) do
		table.insert(orderedGroups, groupData)
	end
	table.sort(orderedGroups, function(a, b) return a.order < b.order end)
	
	for _, groupData in ipairs(orderedGroups) do
		local groupFriends = groupedFriends[groupData.id]
		
		-- Skip empty groups
		if groupFriends and #groupFriends > 0 then
			-- Add group header
			table.insert(self.displayList, {
				type = BUTTON_TYPE_GROUP_HEADER,
				groupId = groupData.id,
				name = groupData.name,
				count = #groupFriends,
				collapsed = groupData.collapsed
			})
			
			-- Add friends if not collapsed
			if not groupData.collapsed then
				for _, friend in ipairs(groupFriends) do
					table.insert(self.displayList, {
						type = BUTTON_TYPE_FRIEND,
						friend = friend,
						groupId = groupData.id
					})
				end
			end
		end
	end
end

-- Check if friend passes current filters
function FriendsList:PassesFilters(friend)
	-- Search text filter
	if self.searchText and self.searchText ~= "" then
		local searchLower = self.searchText:lower()
		local found = false
		
		-- Helper function to check if a field contains the search text
		local function contains(text)
			if text and text ~= "" and text ~= "???" then
				return text:lower():find(searchLower, 1, true) ~= nil
			end
			return false
		end
		
		-- Search in multiple fields depending on friend type
		if friend.type == "bnet" then
			-- BNet friends: search in accountName, battleTag, characterName, realmName, note
			found = contains(friend.accountName)
				or contains(friend.battleTag)
				or contains(friend.characterName)
				or contains(friend.realmName)
				or contains(friend.note)
		else
			-- WoW friends: search in name, note
			found = contains(friend.name)
				or contains(friend.note)
		end
		
		-- If no match found in any field, filter out this friend
		if not found then
			return false
		end
	end
	
	-- Filter mode (use 'connected' field for both BNet and WoW friends)
	if self.filterMode == "online" then
		if not friend.connected then return false end
		
	elseif self.filterMode == "offline" then
		if friend.connected then return false end
		
	elseif self.filterMode == "wow" then
		if friend.type == "bnet" then
			-- BNet friend must be in WoW
			if not friend.connected or not friend.gameAccountInfo then return false end
			if friend.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then return false end
		end
		-- WoW friends always pass
		
	elseif self.filterMode == "bnet" then
		if friend.type ~= "bnet" then return false end
	end
	
	return true
end

-- Get display list count
function FriendsList:GetDisplayListCount()
	return #self.displayList
end

-- Get display list item
function FriendsList:GetDisplayListItem(index)
	return self.displayList[index]
end

-- Get friend UID (public helper)
function FriendsList:GetFriendUID(friend)
	return GetFriendUID(friend)
end

-- Set search text
function FriendsList:SetSearchText(text)
	self.searchText = text or ""
	self:BuildDisplayList()
end

-- Set filter mode
function FriendsList:SetFilterMode(mode)
	self.filterMode = mode or "all"
	self:BuildDisplayList()
end

-- Set sort mode
function FriendsList:SetSortMode(mode)
	self.sortMode = mode or "status"
	self:ApplySort()
	self:BuildDisplayList()
end

-- ========================================
-- Group Management API
-- ========================================

-- Toggle group collapsed state
function FriendsList:ToggleGroup(groupId)
	local Groups = GetGroups()
	if not Groups then return end
	
	local group = Groups:Get(groupId)
	if group then
		Groups:SetCollapsed(groupId, not group.collapsed)
		self:BuildDisplayList()
	end
end

-- Create a new custom group
function FriendsList:CreateGroup(groupName)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end
	
	local success, err = Groups:Create(groupName)
	if success then
		self:SyncGroups()
		self:BuildDisplayList()
	end
	
	return success, err
end

-- Rename a group
function FriendsList:RenameGroup(groupId, newName)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end
	
	local success, err = Groups:Rename(groupId, newName)
	if success then
		self:SyncGroups()
		self:BuildDisplayList()
	end
	
	return success, err
end

-- Delete a group
function FriendsList:DeleteGroup(groupId)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end
	
	local success, err = Groups:Delete(groupId)
	if success then
		self:SyncGroups()
		self:BuildDisplayList()
	end
	
	return success, err
end

-- Toggle friend in group
function FriendsList:ToggleFriendInGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then return end
	
	local friendGroupsData = DB:Get("friendGroups", {})
	friendGroupsData[friendUID] = friendGroupsData[friendUID] or {}
	
	local isInGroup = false
	for i, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			table.remove(friendGroupsData[friendUID], i)
			isInGroup = true
			break
		end
	end
	
	if not isInGroup then
		table.insert(friendGroupsData[friendUID], groupId)
	end
	
	-- Clean up if no groups
	if #friendGroupsData[friendUID] == 0 then
		friendGroupsData[friendUID] = nil
	end
	
	DB:Set("friendGroups", friendGroupsData)
	self:BuildDisplayList()
	
	return not isInGroup -- Return new state (true = added)
end

-- Check if friend is in group
function FriendsList:IsFriendInGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then return false end
	
	local friendGroupsData = DB:Get("friendGroups", {})
	if not friendGroupsData[friendUID] then return false end
	
	for _, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			return true
		end
	end
	
	return false
end

-- Remove friend from group
function FriendsList:RemoveFriendFromGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then return end
	
	local friendGroupsData = DB:Get("friendGroups", {})
	if not friendGroupsData[friendUID] then return end
	
	for i, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			table.remove(friendGroupsData[friendUID], i)
			break
		end
	end
	
	-- Clean up if no groups
	if #friendGroupsData[friendUID] == 0 then
		friendGroupsData[friendUID] = nil
	end
	
	DB:Set("friendGroups", friendGroupsData)
	self:BuildDisplayList()
end

-- ========================================
-- Friends Display Rendering
-- ========================================

-- RenderDisplay: Updates the visual display of the friends list
-- This function handles ScrollBox rendering, button pool management, 
-- friend button configuration (BNet/WoW), compact mode, and TravelPass buttons
function FriendsList:RenderDisplay()
	-- Skip update if frame is not shown (performance optimization)
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		return
	end
	
	-- Skip update if Friends list elements are hidden (means we're on another tab)
	if BetterFriendsFrame.ScrollFrame and not BetterFriendsFrame.ScrollFrame:IsShown() then
		return
	end
	
	-- Skip update if we're not on the Friends tab (tab 1)
	-- This prevents the Sort panel from being closed when friend list updates
	if BetterFriendsFrame.FriendsTabHeader then
		local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		if selectedTab and selectedTab ~= 1 then
			return
		end
	end
	
	-- Build display list from friends list
	self:BuildDisplayList()
	
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	local numItems = #self.displayList
	
	-- Calculate maximum visible buttons based on scroll frame height and button heights
	-- ScrollFrame height: 418px, Button heights: 24px (compact) or 34px (normal), Header: 22px
	local SCROLL_FRAME_HEIGHT = 418
	local DB = GetDB()
	local isCompactMode = DB and DB:Get("compactMode", false)
	local avgButtonHeight = isCompactMode and 24 or 34
	local maxVisibleButtons = math.floor(SCROLL_FRAME_HEIGHT / avgButtonHeight)
	
	-- Calculate the maximum valid offset
	local maxOffset = math.max(0, numItems - maxVisibleButtons)
	
	-- Update scroll frame - use dynamic height based on compact mode
	-- ONLY call FauxScrollFrame_Update if we're not in a mouse wheel update
	if not BetterFriendsFrame.inMouseWheelUpdate then
		FauxScrollFrame_Update(scrollFrame, numItems, maxVisibleButtons, avgButtonHeight)
	end
	
	-- FauxScrollFrame_Update can hide the scrollFrame when numItems <= NUM_BUTTONS
	-- We want it always visible, so force it to show
	scrollFrame:Show()
	
	-- Update MinimalScrollBar to match (uses percentage-based system)
	if BetterFriendsFrame.MinimalScrollBar then
		local scrollBar = BetterFriendsFrame.MinimalScrollBar
		
		-- Set the visible extent percentage (how much of the content is visible)
		if numItems > 0 then
			local visibleExtent = maxVisibleButtons / numItems
			scrollBar:SetVisibleExtentPercentage(visibleExtent)
		end
		
		-- Only update scroll position if we're not already in a callback
		-- This prevents infinite recursion: SetScrollPercentage -> OnScroll callback -> UpdateDisplay -> SetScrollPercentage...
		local isInCallback = BetterFriendsFrame.isUpdatingScrollFromCallback and BetterFriendsFrame.isUpdatingScrollFromCallback()
		if not isInCallback and not BetterFriendsFrame.inMouseWheelUpdate then
			-- Update scroll position
			if maxOffset > 0 then
				local currentOffset = FauxScrollFrame_GetOffset(scrollFrame)
				currentOffset = math.max(0, math.min(currentOffset, maxOffset))
				local scrollPercentage = currentOffset / maxOffset
				scrollBar:SetScrollPercentage(scrollPercentage)
			else
				scrollBar:SetScrollPercentage(0)
			end
		end
	end
	
	-- Get offset and clamp it to valid range (ensure it's at least 0)
	local offset = FauxScrollFrame_GetOffset(scrollFrame)
	offset = math.max(0, math.min(offset, maxOffset))
	
	-- Reset button pool for this frame
	local ButtonPool = BFL:GetModule("ButtonPool")
	if ButtonPool then
		ButtonPool:ResetButtonPool()
	end
	
	-- Render visible buttons using button pool
	-- We need to fill the available height (418px) with mixed button heights
	-- Headers: 22px, Friends: dynamic based on compact mode
	local SCROLL_FRAME_HEIGHT = 418
	local HEADER_HEIGHT = 22
	local FRIEND_HEIGHT = avgButtonHeight
	local BUTTON_SPACING = 1
	local TOP_PADDING = 3
	
	local currentHeight = TOP_PADDING
	local buttonsRendered = 0
	
	local Groups = GetGroups()
	local displayList = self.displayList
	local friendGroups = Groups and Groups.groups or {}
	
	-- Store reference to self for callbacks
	local FriendsListModule = self
	
	-- Keep rendering buttons until we fill the available height or run out of items
	for i = 1, math.min(numItems, 20) do  -- Max 20 buttons as safety limit
		local index = offset + i
		
		if index > numItems then
			break
		end
		
		local item = displayList[index]
		local buttonHeight = (item.type == BUTTON_TYPE_GROUP_HEADER) and HEADER_HEIGHT or FRIEND_HEIGHT
		
		-- Check if this button would fit in the remaining space
		-- Allow partial visibility of last button (at least 10px visible)
		if currentHeight + buttonHeight > SCROLL_FRAME_HEIGHT + 24 then
			break
		end
		
		buttonsRendered = buttonsRendered + 1
		local ButtonPool = BFL:GetModule("ButtonPool")
		local button = ButtonPool and ButtonPool:GetButtonForDisplay(buttonsRendered, item.type)
		if not button then
			break
		end
		button:Show()
		
		currentHeight = currentHeight + buttonHeight + BUTTON_SPACING
		
		if item.type == BUTTON_TYPE_GROUP_HEADER then
			-- Configure group header button
			button.groupId = item.groupId
		
			-- Set text with custom color
			local ColorManager = GetColorManager()
			local colorCode = ColorManager and ColorManager:GetGroupColorCode(item.groupId) or "|cffffffff"
			button:SetText(string.format("%s%s (%d)|r", colorCode, item.name, item.count))
			
			-- Apply font size settings
			local headerText = button:GetFontString()
			if headerText then
				local FontManager = GetFontManager()
				if FontManager then
					FontManager:ApplyFontSize(headerText)
				end
			end
			
			-- Show/hide arrows based on collapsed state
			if button.RightArrow and button.DownArrow then
				if item.collapsed then
					button.RightArrow:Show()
					button.DownArrow:Hide()
				else
					button.RightArrow:Hide()
					button.DownArrow:Show()
				end
			end
			
			-- Add right-click menu for custom groups
			if friendGroups[item.groupId] and not friendGroups[item.groupId].builtin then
				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:SetScript("OnClick", function(self, buttonName)
					if buttonName == "RightButton" then
						-- Open context menu for group header
						MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
							local groupData = friendGroups[self.groupId]
							if not groupData then return end
							
							rootDescription:CreateTitle(groupData.name)
							
							rootDescription:CreateButton("Rename Group", function()
								StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
							end)
							
							rootDescription:CreateButton("Delete Group", function()
								StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, self.groupId)
							end)
							
							rootDescription:CreateDivider()
							
							rootDescription:CreateButton("Collapse All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = true
									BetterFriendlistDB.groupStates[gid] = true
								end
								FriendsListModule:BuildDisplayList()
								FriendsListModule:RenderDisplay()
							end)
							
							rootDescription:CreateButton("Expand All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = false
									BetterFriendlistDB.groupStates[gid] = false
								end
								FriendsListModule:BuildDisplayList()
								FriendsListModule:RenderDisplay()
							end)
						end)
					else
						-- Left click: toggle collapse
						local groupData = friendGroups[self.groupId]
						if groupData then
							groupData.collapsed = not groupData.collapsed
							BetterFriendlistDB.groupStates[self.groupId] = groupData.collapsed
							FriendsListModule:BuildDisplayList()
							FriendsListModule:RenderDisplay()
						end
					end
				end)
			else
				-- Built-in groups: Rechtsklick für Collapse/Expand All
				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:SetScript("OnClick", function(self, buttonName)
					if buttonName == "RightButton" then
						-- Open context menu for built-in group header
						MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
							local groupData = friendGroups[self.groupId]
							if not groupData then return end
							
							rootDescription:CreateTitle(groupData.name)
							
							rootDescription:CreateButton("Collapse All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = true
									BetterFriendlistDB.groupStates[gid] = true
								end
								FriendsListModule:BuildDisplayList()
								FriendsListModule:RenderDisplay()
							end)
							
							rootDescription:CreateButton("Expand All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = false
									BetterFriendlistDB.groupStates[gid] = false
								end
								FriendsListModule:BuildDisplayList()
								FriendsListModule:RenderDisplay()
							end)
						end)
					else
						-- Left click: toggle collapse
						local groupData = friendGroups[self.groupId]
						if groupData then
							groupData.collapsed = not groupData.collapsed
							BetterFriendlistDB.groupStates[self.groupId] = groupData.collapsed
							FriendsListModule:BuildDisplayList()
							FriendsListModule:RenderDisplay()
						end
					end
				end)
			end
		
		elseif item.type == BUTTON_TYPE_FRIEND then
			-- Configure friend button
			local friend = item.friend
			
			-- Store friend data on button for tooltip
			button.friendIndex = friend.index  -- Use the actual friend list index, not display index
			button.friendData = friend
			button.groupId = nil
			
			-- Store friendInfo for context menu (matches our OnClick handler)
			button.friendInfo = {
				type = friend.type,
				index = friend.index,  -- Use the actual friend list index
				name = friend.name or friend.accountName or friend.battleTag,
				connected = friend.connected,
				guid = friend.guid,
				bnetAccountID = friend.bnetAccountID,
				battleTag = friend.battleTag
			}
			
			-- Hide arrows if they exist
			if button.RightArrow then button.RightArrow:Hide() end
			if button.DownArrow then button.DownArrow:Hide() end
			
			-- Reset name position based on compact mode
			if isCompactMode then
				button.Name:SetPoint("LEFT", 44, 0)  -- Centered vertically for single line
			else
				button.Name:SetPoint("LEFT", 44, 7)  -- Upper position for two lines
			end
			button.Name:SetTextColor(1, 1, 1) -- White
				
			-- Show/hide friend elements based on compact mode
			button.status:Show()
			if isCompactMode then
				button.Info:Hide()  -- Hide second line in compact mode
			else
				button.Info:Show()
			end
			
			-- Apply font size settings
			local FontManager = GetFontManager()
			if FontManager then
				FontManager:ApplyFontSize(button.Name)
				FontManager:ApplyFontSize(button.Info)
			end
			
			-- Adjust icon positions and sizes for compact mode
			if isCompactMode then
				-- Status icon: move up to align with single-line text
				button.status:ClearAllPoints()
				button.status:SetPoint("TOPLEFT", 4, -4)  -- Higher position (was -9)
				
				-- Game icon: reduce size for compact mode
				button.gameIcon:SetSize(20, 20)  -- Smaller (was 28x28)
				button.gameIcon:ClearAllPoints()
				button.gameIcon:SetPoint("TOPRIGHT", -38, -2)  -- Adjust position slightly
				
				-- TravelPass button: reduce size for compact mode
				if button.travelPassButton then
					button.travelPassButton:SetSize(18, 24)  -- Smaller (was 24x32)
					button.travelPassButton:ClearAllPoints()
					button.travelPassButton:SetPoint("TOPRIGHT", -8, 0)  -- Adjust position
					
					-- Scale textures
					button.travelPassButton.NormalTexture:SetSize(18, 24)
					button.travelPassButton.PushedTexture:SetSize(18, 24)
					button.travelPassButton.DisabledTexture:SetSize(18, 24)
					button.travelPassButton.HighlightTexture:SetSize(18, 24)
				end
			else
				-- Normal mode: restore original positions and sizes
				button.status:ClearAllPoints()
				button.status:SetPoint("TOPLEFT", 4, -9)  -- Original position
				
				button.gameIcon:SetSize(28, 28)  -- Original size
				button.gameIcon:ClearAllPoints()
				button.gameIcon:SetPoint("TOPRIGHT", -38, -3)  -- Original position
				
				-- TravelPass button: restore original size
				if button.travelPassButton then
					button.travelPassButton:SetSize(24, 32)  -- Original size
					button.travelPassButton:ClearAllPoints()
					button.travelPassButton:SetPoint("TOPRIGHT", -8, -1)  -- Original position
					
					-- Restore texture sizes
					button.travelPassButton.NormalTexture:SetSize(24, 32)
					button.travelPassButton.PushedTexture:SetSize(24, 32)
					button.travelPassButton.DisabledTexture:SetSize(24, 32)
					button.travelPassButton.HighlightTexture:SetSize(24, 32)
				end
			end
			
			if friend.type == "bnet" then
				-- Battle.net friend
				local displayName = friend.accountName or friend.battleTag or "Unknown"
				
				-- Set background color
				if friend.connected then
					button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
				else
					button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
				end
				
				-- Set status icon (BSAp shows as AFK)
				if friend.connected then
					if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp" then
						button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Away")
					else
						button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
					end
				else
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
				end
				
				-- Set game icon using Blizzard's modern API
				if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram and friend.connected then
					local clientProgram = friend.gameAccountInfo.clientProgram
					
					-- Use Blizzard's modern texture API (11.0+) for ALL client programs including Battle.net App
					C_Texture.SetTitleIconTexture(button.gameIcon, clientProgram, Enum.TitleIconVersion.Medium)
					
					-- Fade icon for WoW friends on different project versions
					local fadeIcon = (clientProgram == BNET_CLIENT_WOW) and (friend.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID)
					if fadeIcon then
						button.gameIcon:SetAlpha(0.6)
					else
						button.gameIcon:SetAlpha(1)
					end
					
					button.gameIcon:Show()
				else
					button.gameIcon:Hide()
				end
				
				-- Handle TravelPass button for Battle.net friends
				if button.travelPassButton then
					-- Show for ALL online Battle.net friends (matching Blizzard's behavior)
					if friend.connected then
						-- Store friend index for click handler
						button.travelPassButton.friendIndex = index
						button.travelPassButton.friendData = friend
						
						-- Get the actual Battle.net friend index for restriction checking
						local numBNet = BNGetNumFriends()
						local actualBNetIndex = nil
						for i = 1, numBNet do
							local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
							if accountInfo and accountInfo.bnetAccountID == friend.bnetAccountID then
								actualBNetIndex = i
								break
							end
						end
						
						-- Calculate invite restriction (matching Blizzard's logic)
						local restriction = nil  -- Will be set to NO_GAME_ACCOUNTS if no valid accounts found
						if actualBNetIndex then
							local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualBNetIndex)
							
							for i = 1, numGameAccounts do
								local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualBNetIndex, i)
								if gameAccountInfo then
									if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
										-- Check WoW version compatibility
										if gameAccountInfo.wowProjectID and WOW_PROJECT_ID then
											if gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
												-- Friend is on Classic, we're not
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_CLASSIC
												end
											elseif gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
												-- Friend is on Mainline, we're not
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_MAINLINE
												end
											elseif gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
												-- Different WoW version (other)
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_ID
												end
											elseif gameAccountInfo.realmID == 0 then
												-- No realm info
												if not restriction then
													restriction = INVITE_RESTRICTION_INFO
												end
											elseif not gameAccountInfo.isInCurrentRegion then
												-- Different region
												restriction = INVITE_RESTRICTION_REGION
											else
												-- At least one valid WoW account that can be invited
												restriction = INVITE_RESTRICTION_NONE
												break
											end
										elseif gameAccountInfo.realmID == 0 then
											-- No realm info
											if not restriction then
												restriction = INVITE_RESTRICTION_INFO
											end
										elseif not gameAccountInfo.isInCurrentRegion then
											-- Different region
											restriction = INVITE_RESTRICTION_REGION
										elseif gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
											-- Valid WoW account (no project ID check needed)
											restriction = INVITE_RESTRICTION_NONE
											break
										end
									else
										-- Non-WoW client (App, BSAp, etc.)
										if not restriction then
											restriction = INVITE_RESTRICTION_CLIENT
										end
									end
								end
							end
						end
						
						-- If no restriction was set, means no game accounts at all
						if not restriction then
							restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
						end
						
						-- Enable/disable button based on restriction
						if restriction == INVITE_RESTRICTION_NONE then
							button.travelPassButton:Enable()
						else
							button.travelPassButton:Disable()
						end
						
						-- Set atlas based on faction for cross-faction invites
						local playerFactionGroup = UnitFactionGroup("player")
						local isCrossFaction = friend.gameAccountInfo and
											   friend.gameAccountInfo.factionName and 
											   friend.gameAccountInfo.factionName ~= playerFactionGroup
						
						if isCrossFaction then
							if friend.gameAccountInfo.factionName == "Horde" then
								button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-horde-normal")
								button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-horde-pressed")
								button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-horde-disabled")
							elseif friend.gameAccountInfo.factionName == "Alliance" then
								button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-alliance-normal")
								button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-alliance-pressed")
								button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-alliance-disabled")
							end
						else
							button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-default-normal")
							button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-default-pressed")
							button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-default-disabled")
						end
						
						button.travelPassButton:Show()
					else
						button.travelPassButton:Hide()
					end
				end
				
				-- Line 1: BattleNet Name (CharacterName)
				-- BattleNet Name in blue/cyan Battle.net color, CharacterName in class color
				local line1Text = ""
				if friend.connected then
					-- Use Battle.net blue color for the account name
					line1Text = "|cff00ccff" .. displayName .. "|r"
					
					if friend.characterName and friend.className then
						-- Add Timerunning icon if applicable
						local characterName = friend.characterName
						if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
							characterName = TimerunningUtil.AddSmallIcon(characterName)
						end
						
						-- Convert localized class name to English uppercase key for RAID_CLASS_COLORS
						local classFile = nil
						for i = 1, GetNumClasses() do
							local localizedClassName, classFilename = GetClassInfo(i)
							if localizedClassName == friend.className then
								classFile = classFilename
								break
							end
						end
						
						-- Get class color using the English file name
						local classColor = classFile and RAID_CLASS_COLORS[classFile]
						
						if classColor then
							line1Text = line1Text .. " (|c" .. (classColor.colorStr or "ffffffff") .. characterName .. "|r)"
						else
							line1Text = line1Text .. " (" .. characterName .. ")"
						end
					end
				else
					-- Offline - use gray
					line1Text = "|cff7f7f7f" .. displayName .. "|r"
				end
				
				-- In compact mode, append additional info to line1Text
				if isCompactMode then
					if friend.connected then
						local infoText = ""
						if friend.level and friend.areaName then
							infoText = string.format(" - Lvl %d, %s", friend.level, friend.areaName)
						elseif friend.level then
							infoText = " - Lvl " .. friend.level
						elseif friend.areaName then
							infoText = " - " .. friend.areaName
						elseif friend.gameName then
							infoText = " - " .. friend.gameName
						end
						-- Add info in gray color
						if infoText ~= "" then
							line1Text = line1Text .. "|cff7f7f7f" .. infoText .. "|r"
						end
					else
						-- Offline - add last online time
						if friend.lastOnlineTime then
							line1Text = line1Text .. " |cff7f7f7f- " .. GetLastOnlineText(friend) .. "|r"
						end
					end
				end
				
				button.Name:SetText(line1Text)
				
				-- Line 2: Level, Zone (in gray) - only used in normal mode
				if not isCompactMode then
					if friend.connected then
						if friend.level and friend.areaName then
							button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.areaName))
						elseif friend.level then
							button.Info:SetText("Lvl " .. friend.level)
						elseif friend.areaName then
							button.Info:SetText(friend.areaName)
						elseif friend.gameName then
							-- Show "Mobile" or "In App" without "Playing" prefix
							button.Info:SetText(friend.gameName)
						else
							button.Info:SetText("Online")
						end
					else
						-- Offline - show last online time for Battle.net friends
						if friend.lastOnlineTime then
							button.Info:SetText(GetLastOnlineText(friend))
						else
							button.Info:SetText("Offline")
						end
					end
				end  -- end of if not isCompactMode
			else
				-- WoW friend
				-- Set background color
				if friend.connected then
					button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a)
				else
					button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
				end
				
				-- Set status icon
				if friend.connected then
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
				else
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
				end
				
				button.gameIcon:Hide()
				
				-- Hide TravelPass button for WoW friends (they don't have it)
				if button.travelPassButton then
					button.travelPassButton:Hide()
				end
				
				-- Line 1: Character Name (in class color)
				local line1Text = ""
				if friend.connected then
					local classColor = RAID_CLASS_COLORS[friend.className]
					if classColor then
						line1Text = "|c" .. (classColor.colorStr or "ffffffff") .. friend.name .. "|r"
					else
						line1Text = friend.name
					end
				else
					-- Offline - gray
					line1Text = "|cff7f7f7f" .. friend.name .. "|r"
				end
				
				-- In compact mode, append additional info to line1Text
				if isCompactMode then
					if friend.connected then
						local infoText = ""
						if friend.level and friend.area then
							infoText = string.format(" - Lvl %d, %s", friend.level, friend.area)
						elseif friend.level then
							infoText = " - Lvl " .. friend.level
						elseif friend.area then
							infoText = " - " .. friend.area
						end
						-- Add info in gray color
						if infoText ~= "" then
							line1Text = line1Text .. "|cff7f7f7f" .. infoText .. "|r"
						end
					end
				end
				
				button.Name:SetText(line1Text)
				
				-- Line 2: Level, Zone (in gray) - only used in normal mode
				if not isCompactMode then
					if friend.connected then
						if friend.level and friend.area then
							button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.area))
						elseif friend.level then
							button.Info:SetText("Lvl " .. friend.level)
						elseif friend.area then
							button.Info:SetText(friend.area)
						else
							button.Info:SetText("Online")
						end
					else
						button.Info:SetText("Offline")
					end
				end  -- end of if not isCompactMode
			end -- end of if friend.type == "bnet"
			
		end -- end of elseif item.type == BUTTON_TYPE_FRIEND
	end -- end of for loop
end

-- ========================================
-- Event Hooks (for future Raid/QuickJoin integration)
-- ========================================
function FriendsList:FireEvent(eventName, ...)
	-- TODO: Implement event system for module communication
	-- This will allow Raid/QuickJoin modules to hook into friend list updates
end

return FriendsList
