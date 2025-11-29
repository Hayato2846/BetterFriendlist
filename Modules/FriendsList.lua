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
local BUTTON_TYPE_INVITE_HEADER = 3
local BUTTON_TYPE_INVITE = 4
local BUTTON_TYPE_DIVIDER = 5

-- Race condition protection
local isUpdatingFriendsList = false
local hasPendingUpdate = false

-- Selected friend for "Send Message" button (matching Blizzard's FriendsFrame)
FriendsList.selectedFriend = nil
FriendsList.selectedButton = nil  -- Reference to the selected button for highlight management

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
-- Helper Functions
-- ========================================

-- Get height of a display list item based on its type
-- CRITICAL: These heights MUST match XML template heights and ButtonPool SetHeight() calls
-- Otherwise buttons will drift out of position!
local function GetItemHeight(item, isCompactMode)
	if not item then return 0 end
	
	if item.type == BUTTON_TYPE_GROUP_HEADER then
		return 22  -- Header height (BetterFriendsGroupHeaderTemplate y="22")
	elseif item.type == BUTTON_TYPE_INVITE_HEADER then
		return 22  -- Invite header height (BFL_FriendInviteHeaderTemplate y="22")
	elseif item.type == BUTTON_TYPE_INVITE then
		return 34  -- Invite button height (BFL_FriendInviteButtonTemplate y="34")
	elseif item.type == BUTTON_TYPE_DIVIDER then
		return 8  -- Divider height (BetterFriendsDividerTemplate y="8") - FIXED from 16!
	elseif item.type == BUTTON_TYPE_FRIEND then
		return isCompactMode and 24 or 34  -- Friend button (BetterFriendsListButtonTemplate y="34", compactMode=24)
	else
		return 34  -- Default fallback
	end
end

-- ========================================
-- ScrollBox/DataProvider Functions (NEW - Phase 1)
-- ========================================

-- Build DataProvider for ScrollBox system (replaces BuildDisplayList logic)
-- Returns a DataProvider object with elementData for each button
local function BuildDataProvider(self)
	local dataProvider = CreateDataProvider()
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Get friendGroups from Groups module
	local Groups = GetGroups()
	local friendGroups = Groups and Groups:GetAll() or {}
	
	-- Add friend invites at top (real or mock)
	local numInvites
	if BFL.MockFriendInvites.enabled then
		numInvites = #BFL.MockFriendInvites.invites
	else
		numInvites = BNGetNumFriendInvites()
	end
	
	if numInvites and numInvites > 0 then
		dataProvider:Insert({
			buttonType = BUTTON_TYPE_INVITE_HEADER,
			count = numInvites,
		})
		
		if not GetCVarBool("friendInvitesCollapsed") then
			for i = 1, numInvites do
				dataProvider:Insert({
					buttonType = BUTTON_TYPE_INVITE,
					inviteIndex = i,
				})
			end
			
			-- Add divider if there are friends below
			if #self.friendsList > 0 then
				dataProvider:Insert({
					buttonType = BUTTON_TYPE_DIVIDER
				})
			end
		end
	end
	
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
		return dataProvider
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
			
			-- Check for custom groups
			if BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
				local groups = BetterFriendlistDB.friendGroups[friendUID]
				for _, groupId in ipairs(groups) do
					-- Skip invalid entries
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
	
	-- Build data provider in group order
	local orderedGroups = {}
	for _, groupData in pairs(friendGroups) do
		table.insert(orderedGroups, groupData)
	end
	table.sort(orderedGroups, function(a, b) return a.order < b.order end)
	
	for _, groupData in ipairs(orderedGroups) do
		local groupFriends = groupedFriends[groupData.id]
		
		-- Only process if group has friends
		if groupFriends then
			-- Check if we should skip empty groups
			local hideEmptyGroups = GetDB():Get("hideEmptyGroups", false)
			local shouldSkip = false
			
			if hideEmptyGroups then
				-- Count online friends only
				local onlineCount = 0
				for _, friend in ipairs(groupFriends) do
					if friend.connected then
						onlineCount = onlineCount + 1
					end
				end
				shouldSkip = (onlineCount == 0)
			elseif #groupFriends == 0 then
				shouldSkip = true
			end
			
			if not shouldSkip then
				-- Add group header
				dataProvider:Insert({
					buttonType = BUTTON_TYPE_GROUP_HEADER,
					groupId = groupData.id,
					name = groupData.name,
					count = #groupFriends,
					collapsed = groupData.collapsed
				})
				
				-- Add friends if not collapsed
				if not groupData.collapsed then
					for _, friend in ipairs(groupFriends) do
						dataProvider:Insert({
							buttonType = BUTTON_TYPE_FRIEND,
							friend = friend,
							groupId = groupData.id
						})
					end
				end
			end
		end
	end
	
	return dataProvider
end

-- Create element factory for ScrollBox button creation
-- Returns a factory function that creates buttons based on elementData.buttonType
local function CreateElementFactory(friendsList)
	-- Capture friendsList reference in closure
	local self = friendsList
	
	return function(factory, elementData)
		local buttonType = elementData.buttonType
		
		if buttonType == BUTTON_TYPE_DIVIDER then
			factory("BetterFriendsDividerTemplate")
			
		elseif buttonType == BUTTON_TYPE_INVITE_HEADER then
			factory("BFL_FriendInviteHeaderTemplate", function(button, data)
				self:UpdateInviteHeaderButton(button, data)
			end)
			
		elseif buttonType == BUTTON_TYPE_INVITE then
			factory("BFL_FriendInviteButtonTemplate", function(button, data)
				self:UpdateInviteButton(button, data)
			end)
			
		elseif buttonType == BUTTON_TYPE_GROUP_HEADER then
			factory("BetterFriendsGroupHeaderTemplate", function(button, data)
				self:UpdateGroupHeaderButton(button, data)
			end)
			
		else -- BUTTON_TYPE_FRIEND
			factory("BetterFriendsListButtonTemplate", function(button, data)
				self:UpdateFriendButton(button, data)
			end)
		end
	end
end

-- Create extent calculator for dynamic button heights
-- Returns a function that calculates height based on elementData.buttonType
local function CreateExtentCalculator(self)
	local DB = GetDB()
	
	return function(dataIndex, elementData)
		local isCompactMode = DB and DB:Get("compactMode", false)
		
		if elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
			return 22
		elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
			return 22
		elseif elementData.buttonType == BUTTON_TYPE_INVITE then
			return 34
		elseif elementData.buttonType == BUTTON_TYPE_DIVIDER then
			return 8
		elseif elementData.buttonType == BUTTON_TYPE_FRIEND then
			return isCompactMode and 24 or 34
		else
			return 34
		end
	end
end

-- ========================================
-- Responsive ScrollBox Functions (Phase 3)
-- ========================================

-- Update ScrollBox height when frame is resized (called from MainFrameEditMode)
function FriendsList:UpdateScrollBoxExtent()
	local frame = BetterFriendsFrame
	if not frame or not frame.ScrollFrame or not frame.ScrollFrame.ScrollBox then
		return
	end
	
	-- Calculate available height for ScrollBox
	-- Frame structure: TitleContainer (30px) + FriendsTabHeader (30px) + Inset.Top (10px) + Bottom buttons (26px) + padding
	local frameHeight = frame:GetHeight()
	local availableHeight = frameHeight - 120  -- Conservative calculation
	
	-- Ensure minimum height
	if availableHeight < 200 then
		availableHeight = 200
	end
	
	-- Update ScrollFrame size (anchored to Inset, so this adjusts the content area)
	local scrollFrame = frame.ScrollFrame
	scrollFrame:ClearAllPoints()
	scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 2)
	
	-- Trigger ScrollBox redraw
	if self.scrollBox and self.scrollBox:GetDataProvider() then
		self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
	end
end

-- Get button width based on current frame size (Phase 3)
function FriendsList:GetButtonWidth()
	local frame = BetterFriendsFrame
	if not frame then
		return 398  -- Default width from XML
	end
	
	-- Frame width minus padding, scrollbar, and inset borders
	-- Frame width - left padding (8px) - right padding (6px) - scrollbar (22px) - inset borders (8px)
	local frameWidth = frame:GetWidth()
	local buttonWidth = frameWidth - 44
	
	-- Ensure minimum width
	if buttonWidth < 300 then
		buttonWidth = 300
	end
	
	return buttonWidth
end

-- ========================================
-- ScrollBox Initialization (NEW - Phase 1)
-- ========================================

-- Initialize ScrollBox system (called once in Initialize())
-- Converts FauxScrollFrame to modern ScrollBox/DataProvider system
function FriendsList:InitializeScrollBox()
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	if not scrollFrame then
		return
	end
	
	-- Create ScrollBox if it doesn't exist
	if not scrollFrame.ScrollBox then
		-- Create ScrollBox container (replaces FauxScrollFrame)
		local scrollBox = CreateFrame("Frame", nil, scrollFrame, "WowScrollBoxList")
		scrollBox:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		scrollBox:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
		scrollFrame.ScrollBox = scrollBox
	end
	
	-- Use existing MinimalScrollBar (already defined in XML)
	local scrollBar = BetterFriendsFrame.MinimalScrollBar
	if not scrollBar then
		return
	end
	
	-- Create view with factory and extent calculator
	local view = CreateScrollBoxListLinearView()
	view:SetElementFactory(CreateElementFactory(self))
	view:SetElementExtentCalculator(CreateExtentCalculator(self))
	
	-- Initialize ScrollBox with view and scrollbar
	ScrollUtil.InitScrollBoxListWithScrollBar(
		scrollFrame.ScrollBox,
		scrollBar,
		view
	)
	
	-- Store reference for later use
	self.scrollBox = scrollFrame.ScrollBox
	self.scrollBar = scrollBar
end

-- ========================================
-- Legacy Helper Functions
-- ========================================

-- Convert localized class name to English class filename for RAID_CLASS_COLORS
-- This fixes class coloring in non-English clients (deDE, frFR, esES, etc.)
-- CRITICAL: gameAccountInfo.className and friendInfo.className are LOCALIZED
-- German client: "Krieger", French client: "Guerrier", English client: "Warrior"
-- We must convert localized → English classFile (e.g., "Krieger" → "WARRIOR")
--
-- IMPORTANT: German (and other languages) use GENDERED class names:
-- - Masculine: "Krieger", "Dämonenjäger" (from GetClassInfo)
-- - Feminine: "Kriegerin", "Dämonenjägerin" (from gameAccountInfo.className)
-- We need to strip gender suffixes before matching
--
-- ⚠️ DEPRECATED: This function is now used only as FALLBACK via GetClassFileForFriend()
-- Use cases where this fallback is still needed:
-- - WoW-only friends (friendInfo.className, no classID available from API)
-- - Game versions < 11.2.7 (classID not available in BNetGameAccountInfo)
-- - When GetClassInfoByID() fails or returns invalid data
--
-- For 11.2.7+: GetClassFileForFriend() prioritizes classID for better performance
local function GetClassFileFromClassName(className)
	if not className or className == "" then 
		return nil 
	end
	
	-- First try: Direct uppercase match (works for English clients)
	-- "Warrior" → "WARRIOR" → RAID_CLASS_COLORS["WARRIOR"] ✅
	local upperClassName = string.upper(className)
	if RAID_CLASS_COLORS[upperClassName] then
		return upperClassName
	end
	
	-- Second try: Match localized className against GetClassInfo()
	-- This handles non-English clients where className is localized
	-- German: "Krieger" matches GetClassInfo() → returns "WARRIOR"
	local numClasses = GetNumClasses()
	for i = 1, numClasses do
		local localizedName, classFile = GetClassInfo(i)
		if localizedName == className then
			return classFile
		end
	end
	
	-- Third try: Handle gendered class names (German, French, Spanish, etc.)
	-- German feminine forms add "-in" suffix: "Kriegerin" → "Krieger"
	-- French feminine forms add "-e" suffix: "Guerrière" → "Guerrier"
	-- Spanish feminine forms change "-o" to "-a": "Guerrera" → "Guerrero"
	
	-- Try removing German/French/Spanish feminine suffixes
	local genderVariants = {}
	
	-- German: Remove "-in" suffix (Kriegerin → Krieger)
	if className:len() > 2 and className:sub(-2) == "in" then
		table.insert(genderVariants, className:sub(1, -3))
	end
	
	-- French: Remove "-e" suffix (Guerrière → Guerrier, Chasseresse → Chasseur)
	if className:len() > 1 and className:sub(-1) == "e" then
		table.insert(genderVariants, className:sub(1, -2))
	end
	
	-- Spanish: Replace "-a" with "-o" (Guerrera → Guerrero)
	if className:len() > 1 and className:sub(-1) == "a" then
		table.insert(genderVariants, className:sub(1, -2) .. "o")
	end
	
	-- Try matching gender variants against GetClassInfo()
	for _, variant in ipairs(genderVariants) do
		for i = 1, numClasses do
			local localizedName, classFile = GetClassInfo(i)
			if localizedName == variant then
				return classFile
			end
		end
	end
	
	-- No match found
	return nil
end

-- Get class file for friend (optimized for 11.2.7+)
-- Priority: classID (11.2.7+) > className (fallback for 11.2.5 and WoW friends)
-- This function provides a dual system:
-- 1. Uses classID if available (fast, language-independent, BNet friends on 11.2.7+)
-- 2. Falls back to className conversion (slower, all languages, WoW friends + older versions)
local function GetClassFileForFriend(friend)
	-- 11.2.7+: Use classID if available (BNet friends only)
	if BFL.UseClassID and friend.classID then
		local classInfo = GetClassInfoByID(friend.classID)
		if classInfo and classInfo.classFile then
			return classInfo.classFile
		end
	end
	
	-- Fallback: Convert className (WoW friends + older game versions)
	if friend.className then
		return GetClassFileFromClassName(friend.className)
	end
	
	return nil
end

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
		-- Use battleTag as persistent identifier (bnetAccountID is temporary per session)
		if friend.battleTag then
			return "bnet_" .. friend.battleTag
		else
			-- Fallback to bnetAccountID only if battleTag is unavailable (should never happen)
			return "bnet_" .. tostring(friend.bnetAccountID or "unknown")
		end
	else
		-- WoW friends: Always use Name-Realm format for consistency
		local normalizedName = BFL:NormalizeWoWFriendName(friend.name)
		return normalizedName and ("wow_" .. normalizedName) or nil
	end
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function FriendsList:Initialize()
	-- Initialize sort modes from database
	local DB = BFL:GetModule("DB")
	local db = DB and DB:Get() or {}
	self.sortMode = db.primarySort or "status"
	self.secondarySort = db.secondarySort or "name"
	
	-- Sync groups from Groups module
	self:SyncGroups()
	
	-- Initialize ScrollBox system (NEW - Phase 1)
	self:InitializeScrollBox()
	
	-- Initialize responsive SearchBox width
	C_Timer.After(0.1, function()
		if BFL.FriendsList and BFL.FriendsList.UpdateSearchBoxWidth then
			BFL.FriendsList:UpdateSearchBoxWidth()
			BFL:DebugPrint("|cff00ffffFriendsList:Initialize:|r Called UpdateSearchBoxWidth")
		else
			BFL:DebugPrint("|cffff0000FriendsList:Initialize:|r UpdateSearchBoxWidth not found!")
		end
	end)
	
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
	
	-- Register friend invite events
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", function()
		self:UpdateFriendsList()
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_ADDED", function()
		local collapsed = GetCVarBool("friendInvitesCollapsed")
		if collapsed then
			self:FlashInviteHeader()
		end
		self:UpdateFriendsList()
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_REMOVED", function()
		self:UpdateFriendsList()
	end, 10)
end

-- Handle friend list update events
function FriendsList:OnFriendListUpdate(...)
	-- If an update is already in progress, mark that we need another update
	if isUpdatingFriendsList then
		hasPendingUpdate = true
		return
	end
	
	-- Trigger immediate update
	self:UpdateFriendsList()
	
	-- Process any pending update that occurred during our update
	if hasPendingUpdate then
		hasPendingUpdate = false
		self:UpdateFriendsList()
	end
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
	-- Prevent concurrent updates
	if isUpdatingFriendsList then
		hasPendingUpdate = true
		return
	end
	
	isUpdatingFriendsList = true
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
						friend.classID = gameInfo.classID  -- 11.2.7+: Store classID for optimized class color lookup
						friend.areaName = gameInfo.areaName
						friend.level = gameInfo.characterLevel
						friend.realmName = gameInfo.realmName
						friend.factionName = gameInfo.factionName
						friend.timerunningSeasonID = gameInfo.timerunningSeasonID
						
						if gameInfo.timerunningSeasonID then
							friend.timerunningSeasonID = gameInfo.timerunningSeasonID
						end

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
			-- Normalize name to always include realm for consistent identification
			local normalizedName = BFL:NormalizeWoWFriendName(friendInfo.name)
			
			local friend = {
				type = "wow",
				index = i,
				name = normalizedName, -- Always includes realm: "Name-Realm"
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
	
	-- Build display list to update UI
	self:BuildDisplayList()
	
	-- Release lock after update complete
	isUpdatingFriendsList = false
end

-- Clear pending update flag (used by ForceRefreshFriendsList to prevent race conditions)
function FriendsList:ClearPendingUpdate()
	hasPendingUpdate = false
end

-- Apply search and filter to friends list
function FriendsList:ApplyFilters()
	-- Filter will be applied in BuildDisplayList
end

-- Apply sort order to friends list (with primary and secondary sort)
function FriendsList:ApplySort()
	local primarySort = self.sortMode
	local secondarySort = self.secondarySort or "name" -- Default secondary: name
	
	table.sort(self.friendsList, function(a, b)
		-- Apply primary sort first
		local primaryResult = self:CompareFriends(a, b, primarySort)
		if primaryResult ~= nil then
			return primaryResult
		end
		
		-- If primary sort is equal, use secondary sort
		if secondarySort and secondarySort ~= "none" and secondarySort ~= primarySort then
			local secondaryResult = self:CompareFriends(a, b, secondarySort)
			if secondaryResult ~= nil then
				return secondaryResult
			end
		end
		
		-- Fallback: sort by name
		local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
		local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
		return (nameA or ""):lower() < (nameB or ""):lower()
	end)
end

-- Compare two friends by a specific sort mode (returns true, false, or nil if equal)
function FriendsList:CompareFriends(a, b, sortMode)
	if sortMode == "status" then
		-- Sort by online status first
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
		
		-- Equal status - return nil to try secondary sort
		return nil
		
	elseif sortMode == "name" then
		local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
		local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
		local aLower, bLower = (nameA or ""):lower(), (nameB or ""):lower()
		if aLower ~= bLower then
			return aLower < bLower
		end
		return nil
		
	elseif sortMode == "level" then
		local levelA = a.level or 0
		local levelB = b.level or 0
		if levelA ~= levelB then
			return levelA > levelB
		end
		return nil
		
	elseif sortMode == "zone" then
		-- PHASE 9A FIX: Online with zone first, then online without zone, then offline
		-- Get online status
		local aOnline = (a.type == "wow" and a.connected) or (a.type == "bnet" and a.connected)
		local bOnline = (b.type == "wow" and b.connected) or (b.type == "bnet" and b.connected)
		
		-- Get zone info (only meaningful if online)
		local aZone = ""
		local bZone = ""
		
		if aOnline then
			aZone = a.areaName or a.area or ""
		end
		if bOnline then
			bZone = b.areaName or b.area or ""
		end
		
		-- Priority 1: Online WITH zone
		local aHasZone = aOnline and aZone ~= ""
		local bHasZone = bOnline and bZone ~= ""
		
		if aHasZone ~= bHasZone then
			return aHasZone  -- Friends with zone first
		end
		
		-- Both have zones: sort alphabetically
		if aHasZone and bHasZone then
			if aZone ~= bZone then
				return aZone:lower() < bZone:lower()
			end
			return nil
		end
		
		-- Priority 2: Online without zone vs Offline
		if aOnline ~= bOnline then
			return aOnline  -- Online (no zone) before offline
		end
		
		-- Both same status (both online without zone, or both offline)
		return nil
		
	elseif sortMode == "activity" then
		-- PHASE 9A FIX: Hybrid Activity + Last Online
		local ActivityTracker = BFL:GetModule("ActivityTracker")
		if not ActivityTracker then
			return nil
		end
		
		-- Get friend UIDs
		local function GetFriendUID(friend)
			if friend.type == "bnet" then
				return friend.battleTag and ("bnet_" .. friend.battleTag) or nil
			else
				-- WoW friends: Use normalized name with realm
				local normalizedName = BFL:NormalizeWoWFriendName(friend.name)
				return normalizedName and ("wow_" .. normalizedName) or nil
			end
		end
		
		local uidA = GetFriendUID(a)
		local uidB = GetFriendUID(b)
		
		-- Get activity timestamps (whisper/group/trade)
		local activityA = uidA and ActivityTracker:GetLastActivity(uidA) or 0
		local activityB = uidB and ActivityTracker:GetLastActivity(uidB) or 0
		
		-- FALLBACK: If no activity tracked, use lastOnline from API
		if activityA == 0 and a.lastOnline then
			activityA = a.lastOnline  -- Unix timestamp from C_FriendList API
		end
		if activityB == 0 and b.lastOnline then
			activityB = b.lastOnline
		end
		
		-- Sort by most recent first (higher timestamp = more recent)
		if activityA ~= activityB then
			return activityA > activityB
		end
		return nil
		
	elseif sortMode == "game" then
		-- PHASE 9B: DYNAMIC Game Sort (future-proof for Classic addons)
		-- Prioritizes friends on YOUR current WoW version first, then other WoW versions, then other games
		local function GetGamePriority(friend)
			-- Offline = lowest priority
			if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
				return 999
			end
			
			-- WoW-only friends: Check if same project as player
			if friend.type == "wow" then
				return 0  -- Always highest (same game by definition)
			end
			
			-- BNet friends: check clientProgram and wowProjectID
			if friend.type == "bnet" and friend.gameAccountInfo then
				local clientProgram = friend.gameAccountInfo.clientProgram
				local friendProjectID = friend.gameAccountInfo.wowProjectID
				
				-- WoW games: Use DYNAMIC wowProjectID prioritization
				if clientProgram == "WoW" and friendProjectID then
					-- Priority 0: Same WoW version as player (Retail if player on Retail, Classic if player on Classic, etc.)
					if friendProjectID == WOW_PROJECT_ID then
						return 0  -- HIGHEST: Same version (future-proof for Classic addons!)
					end
					
					-- Priority 1-99: Other WoW versions (sorted by projectID)
					-- Lower projectID = higher priority
					-- See https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID
					-- 1=Retail, 2=Classic Era, 5=Cataclysm Classic, 11=Classic TBC, etc.
					return friendProjectID  -- Natural priority based on projectID
				end
				
				-- Non-WoW Blizzard games: Lower priority
				-- Diablo IV
				if clientProgram == "ANBS" then
					return 100
				end
				-- Hearthstone
				if clientProgram == "WTCG" then
					return 101
				end
				-- Diablo Immortal
				if clientProgram == "DIMAR" then
					return 102
				end
				-- Overwatch 2
				if clientProgram == "Pro" then
					return 103
				end
				-- StarCraft II
				if clientProgram == "S2" then
					return 104
				end
				-- Diablo III
				if clientProgram == "D3" then
					return 105
				end
				-- Heroes of the Storm
				if clientProgram == "Hero" then
					return 106
				end
				-- Mobile App
				if clientProgram == "BSAp" or clientProgram == "App" then
					return 200  -- Lowest priority (mobile/app)
				end
				-- Unknown/Other games
				return 150
			end
			
			return 999  -- Fallback (offline)
		end
		
		local aPriority = GetGamePriority(a)
		local bPriority = GetGamePriority(b)
		
		if aPriority ~= bPriority then
			return aPriority < bPriority  -- Lower number = higher priority
		end
		
		return nil  -- Equal priority
		
	elseif sortMode == "faction" then
		-- PHASE 9C: Faction Sort (Same Faction → Other Faction → No Faction)
		local playerFaction = UnitFactionGroup("player")  -- "Alliance" or "Horde"
		
		local function GetFactionPriority(friend)
			-- Offline or non-WoW = lowest priority
			if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
				return 3
			end
			
			local friendFaction = nil
			
			-- WoW-only friends
			if friend.type == "wow" and friend.factionName then
				friendFaction = friend.factionName
			end
			
			-- BNet friends playing WoW
			if friend.type == "bnet" and friend.gameAccountInfo then
				if friend.gameAccountInfo.clientProgram == "WoW" and friend.gameAccountInfo.factionName then
					friendFaction = friend.gameAccountInfo.factionName
				end
			end
			
			-- Priority logic
			if not friendFaction then
				return 3  -- No faction data
			elseif friendFaction == playerFaction then
				return 0  -- Same faction (highest priority)
			else
				return 1  -- Other faction
			end
		end
		
		local aPriority = GetFactionPriority(a)
		local bPriority = GetFactionPriority(b)
		
		if aPriority ~= bPriority then
			return aPriority < bPriority
		end
		
		return nil
		
	elseif sortMode == "guild" then
		-- PHASE 9C: Guild Sort (Same Guild → Other Guilds → No Guild/Not Playing WoW)
		local playerGuild = GetGuildInfo("player")  -- Returns guild name or nil
		
		local function GetGuildPriority(friend)
			local friendGuild = nil
			local isPlayingWoW = false
			
			-- WoW-only friends
			if friend.type == "wow" and friend.connected then
				isPlayingWoW = true
				friendGuild = GetGuildInfo(friend.name)
			end
			
			-- BNet friends playing WoW
			if friend.type == "bnet" and friend.gameAccountInfo then
				if friend.gameAccountInfo.clientProgram == "WoW" then
					isPlayingWoW = true
					friendGuild = friend.gameAccountInfo.guildName  -- Available in gameAccountInfo
				end
			end
			
			-- Not playing WoW = lowest priority
			if not isPlayingWoW then
				return {priority = 3, guild = ""}  -- Not playing WoW (lowest)
			end
			
			-- Priority logic for WoW players
			if not friendGuild then
				return {priority = 2, guild = ""}  -- No guild
			elseif playerGuild and friendGuild == playerGuild then
				return {priority = 0, guild = friendGuild}  -- Same guild (highest)
			else
				return {priority = 1, guild = friendGuild}  -- Other guild
			end
		end
		
		local aData = GetGuildPriority(a)
		local bData = GetGuildPriority(b)
		
		-- First by priority
		if aData.priority ~= bData.priority then
			return aData.priority < bData.priority
		end
		
		-- Then by guild name alphabetically (for "other guilds" tier)
		if aData.priority == 1 and aData.guild ~= bData.guild then
			return aData.guild:lower() < bData.guild:lower()
		end
		
		return nil
		
	elseif sortMode == "class" then
		-- PHASE 9C: Class Sort (Tank → Healer → DPS → Not Playing WoW)
		local TANK_CLASSES = {WARRIOR = 1, PALADIN = 1, DEATHKNIGHT = 1, DRUID = 1, MONK = 1, DEMONHUNTER = 1}
		local HEALER_CLASSES = {PRIEST = 1, PALADIN = 1, SHAMAN = 1, DRUID = 1, MONK = 1, EVOKER = 1}
		-- DPS: All others
		
		local function GetClassPriority(friend)
			-- Check if friend is actually playing WoW
			local isPlayingWoW = false
			if friend.type == "wow" and friend.connected then
				isPlayingWoW = true
			elseif friend.type == "bnet" and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "WoW" then
				isPlayingWoW = true
			end
			
			-- Not playing WoW = lowest priority (below all DPS)
			if not isPlayingWoW then
				return {priority = 10, class = ""}  -- Not playing WoW (lowest)
			end
			
			-- friend.class already contains the English class file (WARRIOR, MAGE, etc.)
			local classFile = friend.class
			
			if not classFile or classFile == "" or classFile == "Unknown" then
				return {priority = 9, class = ""}  -- Playing WoW but no class (shouldn't happen)
			end
			
			-- Hybrid classes (can tank AND heal): Check spec if available
			-- For simplicity, treat hybrids as "Tank" tier (PALADIN, DRUID, MONK)
			if TANK_CLASSES[classFile] and HEALER_CLASSES[classFile] then
				return {priority = 0, class = classFile}  -- Hybrid (tank priority)
			elseif TANK_CLASSES[classFile] then
				return {priority = 0, class = classFile}  -- Pure tank
			elseif HEALER_CLASSES[classFile] then
				return {priority = 1, class = classFile}  -- Pure healer
			else
				return {priority = 2, class = classFile}  -- DPS
			end
		end
		
		local aData = GetClassPriority(a)
		local bData = GetClassPriority(b)
		
		-- First by role priority
		if aData.priority ~= bData.priority then
			return aData.priority < bData.priority
		end
		
		-- Then by class name alphabetically (within same role)
		if aData.class ~= bData.class then
			return aData.class < bData.class
		end
		
		return nil
		
	elseif sortMode == "realm" then
		-- PHASE 9C: Realm Sort (Same Realm → Other Realms)
		local playerRealm = GetRealmName()
		
		local function GetRealmPriority(friend)
			local friendRealm = nil
			
			-- WoW-only friends
			if friend.type == "wow" and friend.name then
				-- Name format: "CharName-RealmName" or just "CharName" (same realm)
				friendRealm = friend.name:match("-(.+)$") or playerRealm
			end
			
			-- BNet friends playing WoW
			if friend.type == "bnet" and friend.gameAccountInfo then
				if friend.gameAccountInfo.clientProgram == "WoW" then
					friendRealm = friend.gameAccountInfo.realmName or friend.realmName
				end
			end
			
			if not friendRealm then
				return {priority = 2, realm = ""}  -- No realm (offline/non-WoW)
			elseif friendRealm == playerRealm then
				return {priority = 0, realm = friendRealm}  -- Same realm
			else
				return {priority = 1, realm = friendRealm}  -- Other realm
			end
		end
		
		local aData = GetRealmPriority(a)
		local bData = GetRealmPriority(b)
		
		-- First by priority
		if aData.priority ~= bData.priority then
			return aData.priority < bData.priority
		end
		
		-- Then by realm name alphabetically
		if aData.realm ~= bData.realm then
			return aData.realm:lower() < bData.realm:lower()
		end
		
		return nil
	end
	
	-- Unknown sort mode or equal
	return nil
end

-- Build display list with groups and headers
function FriendsList:BuildDisplayList()
	wipe(self.displayList)
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Add friend invites at top
	local numInvites = BNGetNumFriendInvites()
	if numInvites and numInvites > 0 then
		table.insert(self.displayList, {
			type = BUTTON_TYPE_INVITE_HEADER,
			count = numInvites,
		})
		
		if not GetCVarBool("friendInvitesCollapsed") then
			for i = 1, numInvites do
				table.insert(self.displayList, {
					type = BUTTON_TYPE_INVITE,
					inviteIndex = i,
				})
			end
		end
	end
	
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
		
		-- Check if we should skip empty groups based on setting
		local hideEmptyGroups = GetDB():Get("hideEmptyGroups", false)
		local shouldSkip = false
		
		if hideEmptyGroups and groupFriends then
			-- Count online friends only
			local onlineCount = 0
			for _, friend in ipairs(groupFriends) do
				if friend.connected then
					onlineCount = onlineCount + 1
				end
			end
			-- Skip if no online friends
			shouldSkip = (onlineCount == 0)
		elseif not groupFriends or #groupFriends == 0 then
			-- Always skip if no friends at all
			shouldSkip = true
		end
		
		if not shouldSkip then
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
		
	elseif self.filterMode == "hideafk" then
		-- Hide AFK/DND friends
		if friend.type == "bnet" and friend.connected and friend.gameAccountInfo then
			local gameInfo = friend.gameAccountInfo
			if gameInfo.isAFK or gameInfo.isDND then
				return false
			end
		end
		-- WoW friends don't have AFK/DND status, always show
		
	elseif self.filterMode == "retail" then
		-- Show only Retail/Mainline WoW friends
		if friend.type == "bnet" then
			-- BNet friend must be in WoW Retail
			if not friend.connected or not friend.gameAccountInfo then return false end
			if friend.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then return false end
			-- Check if it's Retail (Mainline)
			if friend.gameAccountInfo.wowProjectID and friend.gameAccountInfo.wowProjectID ~= WOW_PROJECT_MAINLINE then
				return false
			end
		end
		-- WoW friends are assumed to be on same version as player
	end
	
	return true
end

-- Get display list count
function FriendsList:GetDisplayListCount()
	return #self.displayList
end

-- Get display list item
function FriendsList:GetDisplayListItem(index)
	if not self.displayList or not index or index < 1 or index > #self.displayList then
		return nil
	end
	return self.displayList[index]
end

-- Get friend UID (public helper)
function FriendsList:GetFriendUID(friend)
	return GetFriendUID(friend)
end

-- Set search text
function FriendsList:SetSearchText(text)
	self.searchText = text or ""
	BFL:ForceRefreshFriendsList()
end

-- Set filter mode
function FriendsList:SetFilterMode(mode)
	self.filterMode = mode or "all"
	BFL:ForceRefreshFriendsList()
end

-- Set sort mode
function FriendsList:SetSortMode(mode)
	self.sortMode = mode or "status"
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.primarySort = self.sortMode
	end
	
	self:ApplySort()
	BFL:ForceRefreshFriendsList()
end

-- Set secondary sort mode (for multi-criteria sorting)
function FriendsList:SetSecondarySortMode(mode)
	self.secondarySort = mode
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.secondarySort = self.secondarySort
	end
	
	self:ApplySort()
	BFL:ForceRefreshFriendsList()
end

-- ========================================
-- Group Management API
-- ========================================

-- Toggle group collapsed state
function FriendsList:ToggleGroup(groupId)
	local Groups = GetGroups()
	if not Groups then return end
	
	if Groups:Toggle(groupId) then
		BFL:ForceRefreshFriendsList()
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
		BFL:ForceRefreshFriendsList()
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
		BFL:ForceRefreshFriendsList()
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
		BFL:ForceRefreshFriendsList()
	end
	
	return success, err
end

-- Invite all online friends in a group to party
function FriendsList:InviteGroupToParty(groupId)
	local DB = GetDB()
	if not DB then return end
	
	local inviteCount = 0
	
	-- Collect all friends in this group
	for _, friend in ipairs(self.friendsList) do
		if friend.connected then
			local friendUID = GetFriendUID(friend)
			local isInGroup = false
			
			-- Check if favorite
			if groupId == "favorites" and friend.type == "bnet" and friend.isFavorite then
				isInGroup = true
			-- Check if in custom group
			elseif groupId ~= "favorites" and groupId ~= "nogroup" then
				if BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					for _, gid in ipairs(groups) do
						if gid == groupId then
							isInGroup = true
							break
						end
					end
				end
			-- Check if in no group
			elseif groupId == "nogroup" then
				local hasGroup = false
				if friend.type == "bnet" and friend.isFavorite then
					hasGroup = true
				elseif BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					if #groups > 0 then
						hasGroup = true
					end
				end
				isInGroup = not hasGroup
			end
			
			-- Invite if in this group
			if isInGroup then
				if friend.type == "bnet" then
					-- Battle.net friend - invite via BNet
					if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
						local gameAccountID = friend.gameAccountInfo.gameAccountID
						if gameAccountID then
							BNInviteFriend(gameAccountID)
							inviteCount = inviteCount + 1
						end
					end
				elseif friend.type == "wow" then
					-- WoW friend - invite by name
					C_PartyInfo.InviteUnit(friend.name)
					inviteCount = inviteCount + 1
				end
			end
		end
	end
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
-- NEW: Simplified RenderDisplay using ScrollBox/DataProvider system (Phase 2)
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
	if BetterFriendsFrame.FriendsTabHeader then
		local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		if selectedTab and selectedTab ~= 1 then
			return
		end
	end
	
	-- Build DataProvider from friends list
	local dataProvider = BuildDataProvider(self)
	
	-- Update ScrollBox with automatic scroll position preservation!
	local retainScrollPosition = true
	if self.scrollBox then
		self.scrollBox:SetDataProvider(dataProvider, retainScrollPosition)
	end
end

-- ========================================
-- Button Update Functions (called by ScrollBox Factory)
-- ========================================

-- Update group header button (NEW - Phase 1)
function FriendsList:UpdateGroupHeaderButton(button, elementData)
	local groupId = elementData.groupId
	local name = elementData.name
	local count = elementData.count
	local collapsed = elementData.collapsed
	
	-- Store group data on button
	button.groupId = groupId
	
	-- Create drop target highlight if it doesn't exist
	if not button.dropHighlight then
		local dropHighlight = button:CreateTexture(nil, "BACKGROUND")
		dropHighlight:SetAllPoints()
		dropHighlight:SetColorTexture(0, 1, 0, 0.2)
		dropHighlight:Hide()
		button.dropHighlight = dropHighlight
	end
	
	-- Get Groups module
	local Groups = GetGroups()
	
	-- Get group color
	local colorCode = "|cffffffff"  -- Default white
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			local r = group.color.r or group.color[1] or 1
			local g = group.color.g or group.color[2] or 1
			local b = group.color.b or group.color[3] or 1
			colorCode = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
		end
	end
	
	-- Set header text with color
	button:SetFormattedText("%s%s|r (%d)", colorCode, name, count)
	
	-- Show/hide collapse arrows
	button.DownArrow:SetShown(not collapsed)
	button.RightArrow:SetShown(collapsed)
	
	-- Apply font scaling
	local FontManager = GetFontManager()
	if FontManager and button:GetFontString() then
		FontManager:ApplyFontSize(button:GetFontString())
	end
	
	-- Tooltips for group headers
	button:SetScript("OnEnter", function(self)
		-- Check if we're currently dragging a friend
		local isDragging = BetterFriendsList_DraggedFriend ~= nil
		
		local Groups = GetGroups()
		local friendGroups = Groups and Groups:GetAll() or {}
		
		if isDragging and self.groupId and friendGroups[self.groupId] and not friendGroups[self.groupId].builtin then
			-- Show drop target tooltip
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(BFL_L.TOOLTIP_DROP_TO_ADD, 1, 1, 1)
			GameTooltip:AddLine(BFL_L.TOOLTIP_HOLD_SHIFT, 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		else
			-- Show group info tooltip
			if self.groupId and friendGroups[self.groupId] then
				local groupData = friendGroups[self.groupId]
				
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(groupData.name, 1, 1, 1)
				GameTooltip:AddLine("Right-click for options", 0.7, 0.7, 0.7, true)
				if not groupData.builtin then
					GameTooltip:AddLine(BFL_L.TOOLTIP_DRAG_HERE, 0.5, 0.8, 1.0, true)
				end
				GameTooltip:Show()
			end
		end
	end)
	
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Add right-click menu functionality
	if Groups then
		local group = Groups:Get(groupId)
		if group and not group.builtin then
			-- Custom groups: Full context menu with Rename/Delete
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName)
				if buttonName == "RightButton" then
					-- Open context menu for custom group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
						local groupData = Groups:Get(self.groupId)
						if not groupData then return end
						
						rootDescription:CreateTitle(groupData.name)
						
						rootDescription:CreateButton("Rename Group", function()
							StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
						end)
						
						rootDescription:CreateButton("Delete Group", function()
							StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
						rootDescription:CreateButton("Invite All to Party", function()
							FriendsList:InviteGroupToParty(self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
					-- Notification Rules for Group (Beta Features)
					if BetterFriendlistDB.enableBetaFeatures then
						local notificationButton = rootDescription:CreateButton("Notifications")
						
						notificationButton:CreateRadio(
							"Default (Use global settings)",
							function()
								local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return not rule or rule == "default"
							end,
							function()
								if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "default"
								print("|cff00ff00BetterFriendlist:|r Notifications for group '" .. groupData.name .. "' set to |cffffffffDefault|r")
							end
						)
						
						notificationButton:CreateRadio(
							"Whitelist (Always notify)",
							function()
								local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return rule == "whitelist"
							end,
							function()
								if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "whitelist"
								print("|cff00ff00BetterFriendlist:|r Notifications for group '" .. groupData.name .. "' set to |cff00ff00Whitelist|r (always notify)")
							end
						)
						
						notificationButton:CreateRadio(
							"Blacklist (Never notify)",
							function()
								local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return rule == "blacklist"
							end,
							function()
								if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "blacklist"
								print("|cff00ff00BetterFriendlist:|r Notifications for group '" .. groupData.name .. "' set to |cffff0000Blacklist|r (never notify)")
							end
						)
						
						rootDescription:CreateDivider()
					end
					
					-- Group-wide action buttons
					rootDescription:CreateButton("Collapse All Groups", function()
						for gid in pairs(Groups.groups) do
							Groups:SetCollapsed(gid, true)  -- true = force collapse
						end
						BFL:ForceRefreshFriendsList()
					end)
					
					rootDescription:CreateButton("Expand All Groups", function()
						for gid in pairs(Groups.groups) do
							Groups:SetCollapsed(gid, false)  -- false = force expand
						end
						BFL:ForceRefreshFriendsList()
					end)
				end)
			else
					-- Left click: toggle collapse
					if Groups:Toggle(self.groupId) then
						-- Check accordion mode
						local DB = GetDB()
						local accordionMode = DB and DB:Get("accordionGroups", false)
						if accordionMode then
							local clickedGroup = Groups:Get(self.groupId)
							if clickedGroup and not clickedGroup.collapsed then
								-- Opening this group - collapse all others
								for gid in pairs(Groups.groups) do
									if gid ~= self.groupId then
										Groups:SetCollapsed(gid, true)  -- Force collapse
									end
								end
							end
						end
						
						BFL:ForceRefreshFriendsList()
					end
				end
			end)
		else
			-- Built-in groups: Right-click for Collapse/Expand All + Invite
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName)
				if buttonName == "RightButton" then
					-- Open context menu for built-in group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
						local groupData = Groups:Get(self.groupId)
						if not groupData then return end
						
						rootDescription:CreateTitle(groupData.name)
						
						rootDescription:CreateButton("Invite All to Party", function()
							FriendsList:InviteGroupToParty(self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
						rootDescription:CreateButton("Collapse All Groups", function()
							if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, true)  -- true = force collapse
								end
								BFL:ForceRefreshFriendsList()
							end
						end)
						
						rootDescription:CreateButton("Expand All Groups", function()
							if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, false)  -- false = force expand
								end
								BFL:ForceRefreshFriendsList()
							end
						end)
					end)
				else
					-- Left click: toggle collapse
					if Groups:Toggle(self.groupId) then
						-- Check accordion mode
						local DB = GetDB()
						local accordionMode = DB and DB:Get("accordionGroups", false)
						if accordionMode then
							local clickedGroup = Groups:Get(self.groupId)
							if clickedGroup and not clickedGroup.collapsed then
								-- Opening this group - collapse all others
								for gid in pairs(Groups.groups) do
									if gid ~= self.groupId then
										Groups:SetCollapsed(gid, true)  -- Force collapse
									end
								end
							end
						end
						
						BFL:ForceRefreshFriendsList()
					end
				end
			end)
		end
	end
	
	-- Ensure button is visible
	button:Show()
end

-- ========================================
-- Friend Button Update (ScrollBox Factory Callback)
-- ========================================

-- Update friend button (called by ScrollBox factory for each visible friend)
function FriendsList:UpdateFriendButton(button, elementData)
	local friend = elementData.friend
	local groupId = elementData.groupId
	
	-- Store friend data on button for tooltip and context menu
	button.friendIndex = friend.index
	button.friendData = friend
	button.groupId = groupId
	
	-- Store friendInfo for context menu (matches OnClick handler)
	button.friendInfo = {
		type = friend.type,
		index = friend.index,
		name = friend.name or friend.accountName or friend.battleTag,
		connected = friend.connected,
		guid = friend.guid,
		bnetAccountID = friend.bnetAccountID,
		battleTag = friend.battleTag
	}
	
	-- Create selection highlight texture if it doesn't exist (blue, like Blizzard)
	if not button.selectionHighlight then
		local selectionHighlight = button:CreateTexture(nil, "BACKGROUND")
		selectionHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		selectionHighlight:SetBlendMode("ADD")
		selectionHighlight:SetAllPoints()
		selectionHighlight:SetVertexColor(0.510, 0.773, 1.0, 0.5)  -- Blue with alpha
		selectionHighlight:Hide()
		button.selectionHighlight = selectionHighlight
	end
	
	-- Enable drag and drop for group assignment
	button:RegisterForDrag("LeftButton")
	
	-- Create drag overlay if it doesn't exist (same gold color as RaidFrame)
	if not button.dragOverlay then
		local dragOverlay = button:CreateTexture(nil, "OVERLAY")
		dragOverlay:SetAllPoints()
		dragOverlay:SetColorTexture(1.0, 0.843, 0.0, 0.5) -- Gold with 50% alpha (matching RaidFrame)
		dragOverlay:SetBlendMode("ADD")
		dragOverlay:Hide()
		button.dragOverlay = dragOverlay
	end
	
	button:SetScript("OnDragStart", function(self)
		if self.friendData then
			-- Store friend name for header text updates (same as old system)
			BetterFriendsList_DraggedFriend = self.friendData.name or self.friendData.accountName or self.friendData.battleTag or "Unknown"
			
			-- Show drag overlay
			self.dragOverlay:Show()
			self:SetAlpha(0.5)
			
			-- Hide tooltip
			GameTooltip:Hide()
			
			-- Enable OnUpdate to continuously check headers under mouse (IDENTICAL to old system)
			self:SetScript("OnUpdate", function(updateSelf)
				-- Get cursor position
				local cursorX, cursorY = GetCursorPosition()
				local scale = UIParent:GetEffectiveScale()
				cursorX = cursorX / scale
				cursorY = cursorY / scale
				
				-- Get all visible group header buttons from ScrollBox
				local Groups = GetGroups()
				local friendGroups = Groups and Groups:GetAll() or {}
				local scrollBox = self:GetParent():GetParent()  -- Get ScrollBox
				
				if scrollBox then
					-- GetFrames() returns a table, not a function - iterate with pairs()
					local frames = scrollBox:GetFrames()
					for _, frame in pairs(frames) do
						if frame.groupId and frame.dropHighlight then
							local groupData = friendGroups[frame.groupId]
							if groupData and not groupData.builtin then
								-- Check if cursor is over this header
								local left, bottom, width, height = frame:GetRect()
								local isOver = false
								if left then
									isOver = (cursorX >= left and cursorX <= left + width and 
									         cursorY >= bottom and cursorY <= bottom + height)
								end
								
								if isOver and BetterFriendsList_DraggedFriend then
									-- Show highlight and update text (IDENTICAL to old system - GOLD color)
									frame.dropHighlight:Show()
									local headerText = string.format("|cffffd700Add %s to %s|r", BetterFriendsList_DraggedFriend, groupData.name)
									frame:SetText(headerText)
								else
									-- Hide highlight and restore original text (IDENTICAL to old system - GOLD color)
									frame.dropHighlight:Hide()
									local memberCount = 0
									if BetterFriendlistDB.friendGroups then
										for _, groups in pairs(BetterFriendlistDB.friendGroups) do
											for _, gid in ipairs(groups) do
												if gid == frame.groupId then
													memberCount = memberCount + 1
													break
												end
											end
										end
									end
									local headerText = string.format("|cffffd700%s (%d)|r", groupData.name, memberCount)
									frame:SetText(headerText)
								end
							end
						end
					end
				end
			end)
		end
	end)
	
	button:SetScript("OnDragStop", function(self)
		-- Disable OnUpdate
		self:SetScript("OnUpdate", nil)
		
		-- Hide drag overlay
		if self.dragOverlay then
			self.dragOverlay:Hide()
		end
		self:SetAlpha(1.0)
		
		-- Get Groups and reset all header highlights and texts (IDENTICAL to old system)
		local Groups = GetGroups()
		local friendGroups = Groups and Groups:GetAll() or {}
		local scrollBox = self:GetParent():GetParent()
		
		if scrollBox then
			local frames = scrollBox:GetFrames()
			for _, frame in pairs(frames) do
				if frame.groupId and frame.dropHighlight then
					frame.dropHighlight:Hide()
					local groupData = friendGroups[frame.groupId]
					if groupData then
						local memberCount = 0
						if BetterFriendlistDB.friendGroups then
							for _, groups in pairs(BetterFriendlistDB.friendGroups) do
								for _, gid in ipairs(groups) do
									if gid == frame.groupId then
										memberCount = memberCount + 1
										break
									end
								end
							end
						end
						local colorCode = "|cffffffff"
						if groupData.color then
							local r = groupData.color.r or groupData.color[1] or 1
							local g = groupData.color.g or groupData.color[2] or 1
							local b = groupData.color.b or groupData.color[3] or 1
							colorCode = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
						end
						local headerText = string.format("%s%s (%d)|r", colorCode, groupData.name, memberCount)
						frame:SetText(headerText)
					end
				end
			end
		end
		
		-- Get mouse position and find group header under cursor (IDENTICAL to old system)
		local cursorX, cursorY = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		cursorX = cursorX / scale
		cursorY = cursorY / scale
		
		local droppedOnGroup = nil
		if scrollBox then
			local frames = scrollBox:GetFrames()
			for _, frame in pairs(frames) do
				if frame.groupId then
					local left, bottom, width, height = frame:GetRect()
					if left and cursorX >= left and cursorX <= left + width and 
					   cursorY >= bottom and cursorY <= bottom + height then
						droppedOnGroup = frame.groupId
						break
					end
				end
			end
		end
		
		-- If dropped on a group, add friend to that group (IDENTICAL to old system)
		if droppedOnGroup and self.friendData then
			local friendUID = FriendsList:GetFriendUID(self.friendData)
			if friendUID then
				-- Without Shift: Remove from all other custom groups (move)
				-- With Shift: Keep in other groups (add to multiple groups)
				if not IsShiftKeyDown() then
					if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
						for i = #BetterFriendlistDB.friendGroups[friendUID], 1, -1 do
							if BetterFriendlistDB.friendGroups[friendUID][i] then
								local groupId = BetterFriendlistDB.friendGroups[friendUID][i]
								if friendGroups[groupId] and not friendGroups[groupId].builtin then
									table.remove(BetterFriendlistDB.friendGroups[friendUID], i)
								end
							end
						end
					end
				end
				
				-- Add to target group (use DB:AddFriendToGroup to prevent toggle behavior)
				local DB = GetDB()
				if DB and not DB:IsFriendInGroup(friendUID, droppedOnGroup) then
					DB:AddFriendToGroup(friendUID, droppedOnGroup)
				end
				BFL:ForceRefreshFriendsList()
			end
		end
		
		-- Clear dragged friend name
		BetterFriendsList_DraggedFriend = nil
	end)
	
	-- Get settings
	local DB = GetDB()
	local isCompactMode = DB and DB:Get("compactMode", false)
	local showGameIcon = DB and DB:Get("showGameIcon", true)
	
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
		button.gameIcon:SetPoint("TOPRIGHT", -30, -2)  -- Moved 8px right total
		
		-- TravelPass button: reduce size for compact mode
		if button.travelPassButton then
			button.travelPassButton:SetSize(18, 24)  -- Smaller (was 24x32)
			button.travelPassButton:ClearAllPoints()
			button.travelPassButton:SetPoint("TOPRIGHT", 0, 0)  -- Moved 8px right total
			
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
		button.gameIcon:SetPoint("TOPRIGHT", -30, -3)  -- Moved 8px right total
		
		-- TravelPass button: restore original size
		if button.travelPassButton then
			button.travelPassButton:SetSize(24, 32)  -- Original size
			button.travelPassButton:ClearAllPoints()
			button.travelPassButton:SetPoint("TOPRIGHT", 0, -1)  -- Moved 8px right total
			
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
		
		-- Set status icon (BSAp shows as AFK if setting enabled)
		local showMobileAsAFK = GetDB():Get("showMobileAsAFK", false)
		if friend.connected then
			local isMobile = friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp"
			if showMobileAsAFK and isMobile then
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
				button.travelPassButton.friendIndex = friend.index
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
		local playerFactionGroup = UnitFactionGroup("player")
		local grayOtherFaction = GetDB():Get("grayOtherFaction", false)
		local showFactionIcons = GetDB():Get("showFactionIcons", false)
		local showRealmName = GetDB():Get("showRealmName", false)
		
		if friend.connected then
			-- Check if friend is from opposite faction
			local isOppositeFaction = friend.factionName and friend.factionName ~= playerFactionGroup and friend.factionName ~= ""
			local shouldGray = grayOtherFaction and isOppositeFaction
			
			-- Use Battle.net blue color for the account name (or gray if opposite faction)
			if shouldGray then
				line1Text = "|cff808080" .. displayName .. "|r"
			else
				line1Text = "|cff00ccff" .. displayName .. "|r"
			end
			
			if friend.characterName and friend.className then
				-- Add Timerunning icon if applicable
				local characterName = friend.characterName
				if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
					characterName = TimerunningUtil.AddSmallIcon(characterName)
				end
				
				-- Add faction icon if enabled
				if showFactionIcons and friend.factionName then
					if friend.factionName == "Horde" then
						characterName = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. characterName
					elseif friend.factionName == "Alliance" then
						characterName = "|TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:0:0|t" .. characterName
					end
				end
				
				-- Add realm name if enabled and available
				if showRealmName and friend.realmName and friend.realmName ~= "" then
					local playerRealm = GetRealmName()
					if friend.realmName ~= playerRealm then
						characterName = characterName .. " - " .. friend.realmName
					end
				end
				
			-- Check if class coloring is enabled
			local useClassColor = GetDB():Get("colorClassNames", true)
			
			if useClassColor and not shouldGray then
				-- Get class file (uses classID if available on 11.2.7+, falls back to className)
				local classFile = GetClassFileForFriend(friend)
				local classColor = classFile and RAID_CLASS_COLORS[classFile]
				
				if classColor then
					line1Text = line1Text .. " (|c" .. (classColor.colorStr or "ffffffff") .. characterName .. "|r)"
				else
					line1Text = line1Text .. " (" .. characterName .. ")"
				end
			else
				-- No class coloring or opposite faction gray - just show character name
				if shouldGray then
					line1Text = line1Text .. " (|cff808080" .. characterName .. "|r)"
				else
					line1Text = line1Text .. " (" .. characterName .. ")"
				end
			end
			end
		else
			-- Offline - use gray
			line1Text = "|cff7f7f7f" .. displayName .. "|r"
		end
		
		-- In compact mode, append additional info to line1Text
		if isCompactMode then
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			local maxLevel = GetMaxLevelForPlayerExpansion()
			
			if friend.connected then
				local infoText = ""
				if friend.level and friend.areaName then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. friend.areaName
					else
						infoText = string.format(" - Lvl %d, %s", friend.level, friend.areaName)
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - Max Level"
					else
						infoText = " - Lvl " .. friend.level
					end
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
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			local maxLevel = GetMaxLevelForPlayerExpansion()
			
			if friend.connected then
				if friend.level and friend.areaName then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(friend.areaName)
					else
						button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.areaName))
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText("Max Level")
					else
						button.Info:SetText("Lvl " .. friend.level)
					end
				elseif friend.areaName then
					button.Info:SetText(friend.areaName)
				elseif friend.gameName then
					-- Show "Mobile" or "In App" without "Playing" prefix
					button.Info:SetText(friend.gameName)
				else
					button.Info:SetText(BFL_L.ONLINE_STATUS)
				end
			else
				-- Offline - show last online time for Battle.net friends
				if friend.lastOnlineTime then
					button.Info:SetText(GetLastOnlineText(friend))
				else
					button.Info:SetText(BFL_L.OFFLINE_STATUS)
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
		
		-- Line 1: Character Name (in class color if enabled)
		local line1Text = ""
		local playerFactionGroup = UnitFactionGroup("player")
		local grayOtherFaction = GetDB():Get("grayOtherFaction", false)
		local showFactionIcons = GetDB():Get("showFactionIcons", false)
		local showRealmName = GetDB():Get("showRealmName", false)
		
		if friend.connected then
			-- Check if friend is from opposite faction
			local isOppositeFaction = friend.factionName and friend.factionName ~= playerFactionGroup and friend.factionName ~= ""
			local shouldGray = grayOtherFaction and isOppositeFaction
			
			-- Get display name: strips realm for same-realm friends unless showRealmName is enabled
			local characterName
			if showRealmName then
				-- Always show full "Name-Realm" format when setting is enabled
				characterName = friend.name
			else
				-- Strip realm for same-realm friends (default behavior)
				characterName = BFL:GetWoWFriendDisplayName(friend.name)
			end
			
			-- Add faction icon if enabled
			if showFactionIcons and friend.factionName then
				if friend.factionName == "Horde" then
					characterName = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. characterName
				elseif friend.factionName == "Alliance" then
					characterName = "|TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:0:0|t" .. characterName
				end
			end
			
			local useClassColor = GetDB():Get("colorClassNames", true)
			
			if useClassColor and not shouldGray then
				-- Convert class name to English class file for RAID_CLASS_COLORS
				local classFile = GetClassFileFromClassName(friend.className)
				local classColor = classFile and RAID_CLASS_COLORS[classFile]
				if classColor then
					line1Text = "|c" .. (classColor.colorStr or "ffffffff") .. characterName .. "|r"
				else
					line1Text = characterName
				end
			else
				if shouldGray then
					line1Text = "|cff808080" .. characterName .. "|r"
				else
					line1Text = characterName
				end
			end
		else
			-- Offline - gray (use display helper here too)
			local displayName = BFL:GetWoWFriendDisplayName(friend.name)
			line1Text = "|cff7f7f7f" .. displayName .. "|r"
		end
		
		-- In compact mode, append additional info to line1Text
		if isCompactMode then
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			local maxLevel = GetMaxLevelForPlayerExpansion()
			
			if friend.connected then
				local infoText = ""
				if friend.level and friend.area then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. friend.area
					else
						infoText = string.format(" - Lvl %d, %s", friend.level, friend.area)
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - Max Level"
					else
						infoText = " - Lvl " .. friend.level
					end
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
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			local maxLevel = GetMaxLevelForPlayerExpansion()
			
			if friend.connected then
				if friend.level and friend.area then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(friend.area)
					else
						button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.area))
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText("Max Level")
					else
						button.Info:SetText("Lvl " .. friend.level)
					end
				elseif friend.area then
					button.Info:SetText(friend.area)
				else
					button.Info:SetText(BFL_L.ONLINE_STATUS)
				end
			else
				button.Info:SetText(BFL_L.OFFLINE_STATUS)
			end
		end  -- end of if not isCompactMode
	end -- end of if friend.type == "bnet"
	
	-- Ensure button is visible
	button:Show()
end

-- ========================================
-- Friend Invite Functions
-- ========================================

function FriendsList:UpdateInviteHeaderButton(button, data)
	button.Text:SetFormattedText(BFL_L.INVITE_HEADER, data.count)
	local collapsed = GetCVarBool("friendInvitesCollapsed")
	button.DownArrow:SetShown(not collapsed)
	button.RightArrow:SetShown(collapsed)
	
	-- Apply font scaling to header text
	local FontManager = BFL.FontManager
	if FontManager and button.Text then
		FontManager:ApplyFontSize(button.Text)
	end
	
	-- Setup OnClick handler for collapse/expand (only once)
	if not button.handlerRegistered then
		button:SetScript("OnClick", function(self)
			local collapsed = GetCVarBool("friendInvitesCollapsed")
			SetCVar("friendInvitesCollapsed", collapsed and "0" or "1")
			
			-- Force full rebuild of display list
			BFL:ForceRefreshFriendsList()
		end)
		button.handlerRegistered = true
	end
	
	-- Ensure button is visible
	button:Show()
end

-- Update invite button
function FriendsList:UpdateInviteButton(button, data)
	local inviteID, accountName
	
	-- Get invite info from mock or real API
	if BFL.MockFriendInvites.enabled then
		local mockInvite = BFL.MockFriendInvites.invites[data.inviteIndex]
		if mockInvite then
			inviteID = mockInvite.inviteID
			accountName = mockInvite.accountName
		end
	else
		inviteID, accountName = BNGetFriendInviteInfo(data.inviteIndex)
	end
	
	if not inviteID then return end
	
	-- Get current button height to determine if compact mode
	local height = button:GetHeight()
	local isCompact = height < 25
	
	-- Set name with cyan color (BNet style)
	button.Name:SetText("|cff00ccff" .. accountName .. "|r")
	
	-- Set Info text ALWAYS
	button.Info:SetText(BFL_L.INVITE_TAP_TEXT)
	
	-- Adjust positioning based on compact mode
	button.Name:ClearAllPoints()
	
	if isCompact then
		-- Compact mode: single line, vertically centered
		button.Name:SetPoint("LEFT", 10, 0)
		button.Info:Hide()
	else
		-- Normal mode: two-line layout (Info uses XML relative positioning)
		button.Name:SetPoint("TOPLEFT", 10, -6)
		button.Info:Show()
	end
	
	-- Apply font scaling (must be called after text is set)
	local FontManager = BFL.FontManager
	if FontManager then
		FontManager:ApplyFontSize(button.Name)
		if not isCompact then
			FontManager:ApplyFontSize(button.Info)
		end
		-- Apply to button text if exists
		if button.AcceptButton and button.AcceptButton:GetFontString() then
			FontManager:ApplyFontSize(button.AcceptButton:GetFontString())
		end
		if button.DeclineButton and button.DeclineButton:GetFontString() then
			FontManager:ApplyFontSize(button.DeclineButton:GetFontString())
		end
	end
	
	-- Store invite data
	button.inviteID = inviteID
	button.inviteIndex = data.inviteIndex
	
	-- Setup Accept button OnClick handler
	if button.AcceptButton and not button.AcceptButton.handlerRegistered then
		button.AcceptButton:SetScript("OnClick", function(self)
			local parent = self:GetParent()
			if parent.inviteID then
				if BFL.MockFriendInvites.enabled then
					-- Mock: Remove from list and refresh
					for i, invite in ipairs(BFL.MockFriendInvites.invites) do
						if invite.inviteID == parent.inviteID then
							table.remove(BFL.MockFriendInvites.invites, i)
							print("|cff00ff00BetterFriendlist:|r Accepted mock invite from " .. invite.accountName)
							break
						end
					end
					BFL:ForceRefreshFriendsList()
				else
					-- Real API call
					BNAcceptFriendInvite(parent.inviteID)
				end
			end
		end)
		button.AcceptButton.handlerRegistered = true
	end
	
	-- Setup Decline button OnClick handler
	if button.DeclineButton and not button.DeclineButton.handlerRegistered then
		button.DeclineButton:SetScript("OnClick", function(self)
			local parent = self:GetParent()
			if not parent.inviteID or not parent.inviteIndex then return end
			
			local inviteID, accountName
			
			-- Get invite info from mock or real API
			if BFL.MockFriendInvites.enabled then
				local mockInvite = BFL.MockFriendInvites.invites[parent.inviteIndex]
				if mockInvite then
					inviteID = mockInvite.inviteID
					accountName = mockInvite.accountName
				end
			else
				inviteID, accountName = BNGetFriendInviteInfo(parent.inviteIndex)
			end
			
			if not inviteID then return end
			
			MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
				rootDescription:CreateButton("Decline", function()
					if BFL.MockFriendInvites.enabled then
						-- Mock: Remove from list and refresh
						for i, invite in ipairs(BFL.MockFriendInvites.invites) do
							if invite.inviteID == inviteID then
								table.remove(BFL.MockFriendInvites.invites, i)
								print("|cffff0000BetterFriendlist:|r Declined mock invite from " .. invite.accountName)
								break
							end
						end
						BFL:ForceRefreshFriendsList()
					else
						-- Real API call
						BNDeclineFriendInvite(inviteID)
					end
				end)
				
				if not BFL.MockFriendInvites.enabled then
					rootDescription:CreateButton("Report Player", function()
						if C_ReportSystem and C_ReportSystem.OpenReportPlayerDialog then
							C_ReportSystem.OpenReportPlayerDialog(
								C_ReportSystem.ReportType.InappropriateBattleNetName,
								accountName
							)
						end
					end)
					rootDescription:CreateButton("Block Invites", function()
						BNSetBlocked(inviteID, true)
					end)
				end
			end)
		end)
		button.DeclineButton.handlerRegistered = true
	end
	
	-- Ensure button is visible
	button:Show()
end

-- Flash invite header when new invite arrives while collapsed
function FriendsList:FlashInviteHeader()
	if not self.scrollBox then
		return
	end
	
	-- Get all currently visible frames from ScrollBox
	local frames = self.scrollBox:GetFrames()
	if not frames then
		return
	end
	
	-- Find the invite header button and flash it
	for _, frame in pairs(frames) do
		-- Check if this is an invite header button by verifying its unique children
		if frame:GetObjectType() == "Button" and frame.Text and frame.DownArrow and frame.RightArrow then
			-- Flash animation (simple alpha pulse)
			UIFrameFlash(frame, 0.5, 0.5, 2, false, 0, 0)
			break
		end
	end
end

-- ========================================
-- Event Hooks (for future Raid/QuickJoin integration)
-- ========================================
function FriendsList:FireEvent(eventName, ...)
	-- TODO: Implement event system for module communication
	-- This will allow Raid/QuickJoin modules to hook into friend list updates
end

-- ========================================
-- Responsive UI Functions
-- ========================================

-- Update SearchBox width dynamically based on available space
function FriendsList:UpdateSearchBoxWidth()
	local frame = BetterFriendsFrame
	if not frame then
		BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No frame|r")
		return
	end
	
	if not frame.FriendsTabHeader then
		BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No FriendsTabHeader|r")
		return
	end
	
	local header = frame.FriendsTabHeader
	if not header.SearchBox then
		BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No SearchBox|r")
		return
	end
	
	local frameWidth = frame:GetWidth()
	
	-- ========================================
	-- DETAILED DEBUG: Measure all elements
	-- ========================================
	local debugInfo = {}
	
	-- Measure SearchBox
	if header.SearchBox then
		local sbLeft = header.SearchBox:GetLeft() or 0
		local sbRight = header.SearchBox:GetRight() or 0
		local sbWidth = header.SearchBox:GetWidth() or 0
		debugInfo.searchBox = {left = sbLeft, right = sbRight, width = sbWidth}
	end
	
	-- Measure QuickFilter
	if header.QuickFilter then
		local qfLeft = header.QuickFilter:GetLeft() or 0
		local qfRight = header.QuickFilter:GetRight() or 0
		local qfWidth = header.QuickFilter:GetWidth() or 0
		debugInfo.quickFilter = {left = qfLeft, right = qfRight, width = qfWidth}
	end
	
	-- Measure PrimarySortDropdown
	if header.PrimarySortDropdown then
		local psLeft = header.PrimarySortDropdown:GetLeft() or 0
		local psRight = header.PrimarySortDropdown:GetRight() or 0
		local psWidth = header.PrimarySortDropdown:GetWidth() or 0
		debugInfo.primarySort = {left = psLeft, right = psRight, width = psWidth}
	end
	
	-- Measure SecondarySortDropdown
	if header.SecondarySortDropdown then
		local ssLeft = header.SecondarySortDropdown:GetLeft() or 0
		local ssRight = header.SecondarySortDropdown:GetRight() or 0
		local ssWidth = header.SecondarySortDropdown:GetWidth() or 0
		debugInfo.secondarySort = {left = ssLeft, right = ssRight, width = ssWidth}
	end
	
	-- Measure BattlenetFrame (contains BattleTag)
	if header.BattlenetFrame then
		local bnLeft = header.BattlenetFrame:GetLeft() or 0
		local bnRight = header.BattlenetFrame:GetRight() or 0
		local bnWidth = header.BattlenetFrame:GetWidth() or 0
		debugInfo.battlenet = {left = bnLeft, right = bnRight, width = bnWidth}
		
		-- Measure Tag (BattleTag text inside BattlenetFrame)
		if header.BattlenetFrame.Tag then
			local tagWidth = header.BattlenetFrame.Tag:GetStringWidth() or 0
			debugInfo.battlenetTag = {stringWidth = tagWidth}
		end
	end
	
	-- Measure StatusDropdown
	if header.StatusDropdown then
		local sdLeft = header.StatusDropdown:GetLeft() or 0
		local sdRight = header.StatusDropdown:GetRight() or 0
		local sdWidth = header.StatusDropdown:GetWidth() or 0
		debugInfo.statusDropdown = {left = sdLeft, right = sdRight, width = sdWidth}
	end
	
	-- Measure frame bounds
	local frameLeft = frame:GetLeft() or 0
	local frameRight = frame:GetRight() or 0
	debugInfo.frame = {left = frameLeft, right = frameRight, width = frameWidth}
	
	-- ========================================
	-- CLIPPING DETECTION
	-- ========================================
	local clipping = {}
	local rightmostElement = 0
	
	-- Check each element if it extends beyond frame bounds
	for elementName, data in pairs(debugInfo) do
		if elementName ~= "frame" and elementName ~= "battlenetTag" and data.right then
			if data.right > frameRight then
				table.insert(clipping, {
					name = elementName,
					overflow = data.right - frameRight
				})
			end
			if data.right > rightmostElement then
				rightmostElement = data.right
			end
		end
	end
	
	-- Calculate actual space used and available
	local usedWidth = rightmostElement - frameLeft
	local wastedSpace = frameRight - rightmostElement
	
	-- ========================================
	-- CALCULATE OPTIMAL SEARCHBOX WIDTH
	-- ========================================
	-- Reserve MORE space for right-side elements to prevent clipping at dropdowns
	-- Goal: Dropdowns have breathing room, no clipping even during resize
	local fixedElementsWidth = 205  -- Increased from 192px to give dropdowns 13px more space
	local availableWidth = frameWidth - fixedElementsWidth
	
	-- Clamp SearchBox between 175px (functional minimum) and 340px (reduced maximum)
	if availableWidth < 175 then
		availableWidth = 175
	elseif availableWidth > 340 then
		availableWidth = 340
	end
	
	header.SearchBox:SetWidth(availableWidth)
end

-- Export module to BFL namespace (required for BFL.FriendsList access)
BFL.FriendsList = FriendsList

return FriendsList





