-- Friends List Core Logic Module

local ADDON_NAME, BFL = ...
local FriendsList = BFL:RegisterModule("FriendsList", {})
local L = BFL.L  -- Localization table
local LSM = LibStub("LibSharedMedia-3.0")

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

-- Reference to Groups (Upvalue shared by all functions)
local friendGroups = {}

-- Race condition protection
local isUpdatingFriendsList = false
local hasPendingUpdate = false

-- Dirty flag: Set when data changes while frame is hidden
-- When true, next time frame is shown, we need to re-render
local needsRenderOnShow = false

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
local function GetItemHeight(item, isCompactMode) if not item then return 0 end
	
	-- Support both .type (Retail) and .buttonType (Classic)
	local itemType = item.type or item.buttonType
	
	if itemType == BUTTON_TYPE_GROUP_HEADER then
		return 22
	elseif itemType == BUTTON_TYPE_INVITE_HEADER then
		return 22  -- Invite header height (BFL_FriendInviteHeaderTemplate y="22")
	elseif itemType == BUTTON_TYPE_INVITE then
		return 34  -- Invite button height (BFL_FriendInviteButtonTemplate y="34")
	elseif itemType == BUTTON_TYPE_DIVIDER then
		return 8  -- Divider height (BetterFriendsDividerTemplate y="8") - FIXED from 16!
	elseif itemType == BUTTON_TYPE_FRIEND then
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
local function BuildDataProvider(self) local dataProvider = CreateDataProvider()
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Get friendGroups from Groups module (SyncGroups updates the module-level friendGroups table)
	local Groups = GetGroups()
	-- friendGroups is now an upvalue, updated by SyncGroups()
	
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
		nogroup = {},
		ingame = {} -- Feature: In-Game Group
	}
	local totalGroupCounts = {
		favorites = 0,
		nogroup = 0,
		ingame = 0
	}
	local onlineGroupCounts = {
		favorites = 0,
		nogroup = 0,
		ingame = 0
	}
	
	-- Initialize custom group tables
	for groupId, groupData in pairs(friendGroups) do
		if not groupData.builtin or groupId == "favorites" or groupId == "nogroup" or groupId == "ingame" then
			groupedFriends[groupId] = groupedFriends[groupId] or {}
			totalGroupCounts[groupId] = 0
			onlineGroupCounts[groupId] = 0
		end
	end
	
	-- Get DB
	local DB = GetDB()
	if not DB then 
		return dataProvider
	end
	
	-- PERFY OPTIMIZATION: Cache settings outside loop
	local enableInGameGroup = DB:Get("enableInGameGroup", false)
	local inGameGroupMode = DB:Get("inGameGroupMode", "same_game")
	
	-- Group friends
	for _, friend in ipairs(self.friendsList) do
		local friendUID = GetFriendUID(friend)
		local isFavorite = (friend.type == "bnet" and friend.isFavorite)
		local customGroups = (BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID]) or {}
		
		-- Determine groups for this friend
		local friendGroupIds = {}
		local isInAnyGroup = false
		
		if isFavorite then
			table.insert(friendGroupIds, "favorites")
			isInAnyGroup = true
		end
		
		-- Feature: In-Game Group (Dynamic)
		-- Only if enabled in settings
		if enableInGameGroup then
			local mode = inGameGroupMode
			local isInGame = false
			
			if mode == "any_game" then
				-- Any Game: WoW friends (always online in game) OR BNet friends online in ANY game
				if friend.type == "wow" and friend.connected then
					isInGame = true
				elseif friend.type == "bnet" and friend.connected and friend.gameAccountInfo and friend.gameAccountInfo.isOnline then
					-- Check if actually in a game (clientProgram is set)
					-- App and BSAp (Mobile) are not considered "In-Game" for this purpose usually, unless user wants "Online"
					-- User said "friends who are in any game". Usually implies playing.
					local client = friend.gameAccountInfo.clientProgram
					if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
						isInGame = true
					end
				end
			else
				-- Same Game (Default): WoW friends OR BNet friends in SAME WoW version
				if friend.type == "wow" and friend.connected then
					isInGame = true
				elseif friend.type == "bnet" and friend.connected and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
					-- Check Project ID (Retail vs Classic vs Classic Era)
					if friend.gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
						isInGame = true
					end
				end
			end
			
			if isInGame then
				table.insert(friendGroupIds, "ingame")
				isInAnyGroup = true
			end
		end
		
		for _, groupId in ipairs(customGroups) do
			if type(groupId) == "string" and groupedFriends[groupId] then
				table.insert(friendGroupIds, groupId)
				isInAnyGroup = true
			end
		end
		
		if not isInAnyGroup then
			table.insert(friendGroupIds, "nogroup")
		end
		
		-- Update counts and lists
		for _, groupId in ipairs(friendGroupIds) do
			-- Increment total count
			totalGroupCounts[groupId] = (totalGroupCounts[groupId] or 0) + 1
			
			-- Increment online count
			if friend.connected then
				onlineGroupCounts[groupId] = (onlineGroupCounts[groupId] or 0) + 1
			end
			
			-- Add to display list if passes filters
			if self:PassesFilters(friend) then
				table.insert(groupedFriends[groupId], friend)
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
					totalCount = totalGroupCounts[groupData.id] or 0,
					onlineCount = onlineGroupCounts[groupData.id] or 0,
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
local function CreateElementFactory(friendsList) -- Capture friendsList reference in closure
	local self = friendsList
	
	-- Pre-define initializers to avoid closure allocation per row (Phase 9.3 Optimization)
	local function InitInviteHeader(button, data)
		self:UpdateInviteHeaderButton(button, data)
	end
	
	local function InitInviteButton(button, data)
		self:UpdateInviteButton(button, data)
	end
	
	local function InitGroupHeader(button, data)
		self:UpdateGroupHeaderButton(button, data)
	end
	
	local function InitFriendButton(button, data)
		self:UpdateFriendButton(button, data)
	end
	
	return function(factory, elementData) local buttonType = elementData.buttonType
		
		if buttonType == BUTTON_TYPE_DIVIDER then
			factory("BetterFriendsDividerTemplate")
			
		elseif buttonType == BUTTON_TYPE_INVITE_HEADER then
			factory("BFL_FriendInviteHeaderTemplate", InitInviteHeader)
			
		elseif buttonType == BUTTON_TYPE_INVITE then
			factory("BFL_FriendInviteButtonTemplate", InitInviteButton)
			
		elseif buttonType == BUTTON_TYPE_GROUP_HEADER then
			factory("BetterFriendsGroupHeaderTemplate", InitGroupHeader)
			
		else -- BUTTON_TYPE_FRIEND
			factory("BetterFriendsListButtonTemplate", InitFriendButton)
		end
	end
end

-- Create extent calculator for dynamic button heights
-- Returns a function that calculates height based on elementData.buttonType
local function CreateExtentCalculator(self) local DB = GetDB()
	
	return function(dataIndex, elementData) local isCompactMode = DB and DB:Get("compactMode", false)
		
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

-- Update ScrollBox/ScrollFrame height when frame is resized (called from MainFrameEditMode)
function FriendsList:UpdateScrollBoxExtent() local frame = BetterFriendsFrame
	if not frame or not frame.ScrollFrame then
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
	
	-- Classic: Update FauxScrollFrame and re-render
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		if self.classicScrollFrame and self.classicScrollFrame.FauxScrollFrame then
			self.classicScrollFrame.FauxScrollFrame:SetHeight(availableHeight)
		end
		self:RenderClassicButtons()
		return
	end
	
	-- Retail: Trigger ScrollBox redraw
	if self.scrollBox and self.scrollBox:GetDataProvider() then
		self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
	end
end

-- Get button width based on current frame size (Phase 3)
function FriendsList:GetButtonWidth() local frame = BetterFriendsFrame
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

-- Initialize scroll system (called once in Initialize())
-- Retail: Modern ScrollBox/DataProvider system
-- Classic: FauxScrollFrame with button pool
function FriendsList:InitializeScrollBox() local scrollFrame = BetterFriendsFrame.ScrollFrame
	if not scrollFrame then
		return
	end
	
	-- Classic: Use FauxScrollFrame approach
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- BFL:DebugPrint("|cff00ffffFriendsList:|r Using Classic FauxScrollFrame mode")
		self:InitializeClassicScrollFrame(scrollFrame)
		return
	end
	
	-- Retail: Use modern ScrollBox system
	-- BFL:DebugPrint("|cff00ffffFriendsList:|r Using Retail ScrollBox mode")
	
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
-- Classic FauxScrollFrame Implementation
-- ========================================

-- Classic button pool configuration
local CLASSIC_BUTTON_HEIGHT = 34
local CLASSIC_COMPACT_BUTTON_HEIGHT = 24
local CLASSIC_MAX_BUTTONS = 20  -- Max visible buttons

-- Initialize Classic FauxScrollFrame with button pool
function FriendsList:InitializeClassicScrollFrame(scrollFrame) -- Store reference to scrollFrame for Classic mode
	self.classicScrollFrame = scrollFrame
	self.classicButtonPool = {}
	self.classicDisplayList = {}
	
	-- Create FauxScrollFrame if needed
	if not scrollFrame.FauxScrollFrame then
		-- Create the scroll frame
		local fauxScroll = CreateFrame("ScrollFrame", "BetterFriendsClassicScrollFrame", scrollFrame, "FauxScrollFrameTemplate")
		fauxScroll:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		fauxScroll:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -22, 0)
		scrollFrame.FauxScrollFrame = fauxScroll
		
		-- Set OnVerticalScroll handler
		fauxScroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, CLASSIC_BUTTON_HEIGHT, function() BFL.FriendsList:RenderClassicButtons()
			end)
		end)
	end
	
	-- Create content frame for buttons (same size as FauxScrollFrame)
	if not scrollFrame.ContentFrame then
		local content = CreateFrame("Frame", nil, scrollFrame)
		content:SetPoint("TOPLEFT", scrollFrame.FauxScrollFrame, "TOPLEFT", 0, 0)
		content:SetPoint("BOTTOMRIGHT", scrollFrame.FauxScrollFrame, "BOTTOMRIGHT", 0, 0)
		scrollFrame.ContentFrame = content
	end
	
	-- Calculate how many buttons we need
	local frameHeight = scrollFrame:GetHeight() or 400
	local numButtons = math.ceil(frameHeight / CLASSIC_COMPACT_BUTTON_HEIGHT) + 5  -- +5 extra for variable heights (headers are smaller)
	numButtons = math.min(numButtons, CLASSIC_MAX_BUTTONS)
	
	-- Create button pool using friend button template
	for i = 1, numButtons do
		local button = CreateFrame("Button", "BetterFriendsListButton" .. i, scrollFrame.ContentFrame, "BetterFriendsListButtonTemplate")
		button:SetPoint("TOPLEFT", scrollFrame.ContentFrame, "TOPLEFT", 2, -((i - 1) * CLASSIC_BUTTON_HEIGHT))  -- 2px left padding
		button:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 5, 0)  -- 12px - 2px right padding = 10px
		button:SetHeight(CLASSIC_BUTTON_HEIGHT)
		button.classicIndex = i
		button:Hide()
		self.classicButtonPool[i] = button
	end
	
	-- Also create group header buttons
	self.classicHeaderPool = {}
	for i = 1, 10 do  -- Max 10 group headers
		local header = CreateFrame("Button", "BetterFriendsGroupHeader" .. i, scrollFrame.ContentFrame, "BetterFriendsGroupHeaderTemplate")
		header:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)  -- 2px left padding
		header:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)  -- Match friend buttons
		header:SetHeight(22)
		header:Hide()
		self.classicHeaderPool[i] = header
	end
	
	-- Create invite header buttons (Phase 6 Fix)
	self.classicInviteHeaderPool = {}
	for i = 1, 5 do -- Max 5 invite headers (usually only 1)
		local header = CreateFrame("Button", "BetterFriendsInviteHeader" .. i, scrollFrame.ContentFrame, "BFL_FriendInviteHeaderTemplate")
		header:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		header:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		header:SetHeight(22)
		header:Hide()
		self.classicInviteHeaderPool[i] = header
	end
	
	-- Create invite buttons (Phase 6 Fix)
	self.classicInviteButtonPool = {}
	for i = 1, 10 do -- Max 10 invites
		local button = CreateFrame("Button", "BetterFriendsInviteButton" .. i, scrollFrame.ContentFrame, "BFL_FriendInviteButtonTemplate")
		button:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		button:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		button:SetHeight(34)
		button:Hide()
		self.classicInviteButtonPool[i] = button
	end
	
	-- Create divider buttons (Phase 6 Fix)
	self.classicDividerPool = {}
	for i = 1, 5 do -- Max 5 dividers
		local divider = CreateFrame("Frame", "BetterFriendsDivider" .. i, scrollFrame.ContentFrame, "BetterFriendsDividerTemplate")
		divider:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		divider:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		divider:SetHeight(8)
		divider:Hide()
		self.classicDividerPool[i] = divider
	end
	
	-- BFL:DebugPrint(string.format("|cff00ffffFriendsList:|r Created Classic button pool with %d buttons", numButtons))
end

-- Render buttons in Classic FauxScrollFrame mode
function FriendsList:RenderClassicButtons() if not self.classicScrollFrame or not self.classicButtonPool then
		return
	end
	
	local displayList = self.classicDisplayList or {}
	local numItems = #displayList
	local offset = FauxScrollFrame_GetOffset(self.classicScrollFrame.FauxScrollFrame) or 0
	local numButtons = #self.classicButtonPool
	
	-- Get compact mode setting
	local DB = GetDB()
	local isCompactMode = DB and DB:Get("compactMode", false)
	
	-- Calculate total content height for accurate scrolling with variable item heights
	local totalHeight = 0
	for _, elementData in ipairs(displayList) do
		totalHeight = totalHeight + GetItemHeight(elementData, isCompactMode)
	end
	
	-- Set ContentFrame height to actual content size (enables proper scrolling)
	self.classicScrollFrame.ContentFrame:SetHeight(math.max(totalHeight, self.classicScrollFrame:GetHeight() or 400))
	
	-- Calculate number of VISIBLE buttons (not pool size!)
	local scrollHeight = isCompactMode and CLASSIC_COMPACT_BUTTON_HEIGHT or CLASSIC_BUTTON_HEIGHT
	local frameHeight = self.classicScrollFrame:GetHeight() or 400
	local numVisibleButtons = math.floor(frameHeight / scrollHeight)
	
	FauxScrollFrame_Update(self.classicScrollFrame.FauxScrollFrame, numItems, numVisibleButtons, scrollHeight)
	
	-- Track current Y position for variable height items
	local yOffset = 0
	local buttonIndex = 1
	local headerIndex = 1
	local inviteHeaderIndex = 1
	local inviteButtonIndex = 1
	local dividerIndex = 1
	
	-- Hide all buttons and headers first
	for _, button in ipairs(self.classicButtonPool) do button:Hide() end
	for _, header in ipairs(self.classicHeaderPool) do header:Hide() end
	if self.classicInviteHeaderPool then for _, b in ipairs(self.classicInviteHeaderPool) do b:Hide() end end
	if self.classicInviteButtonPool then for _, b in ipairs(self.classicInviteButtonPool) do b:Hide() end end
	if self.classicDividerPool then for _, b in ipairs(self.classicDividerPool) do b:Hide() end end
	
	-- Render visible items
	for i = 1, numButtons do
		local dataIndex = offset + i
		if dataIndex <= numItems then
			local elementData = displayList[dataIndex]
			
			-- Use appropriate button type
			local button
			if elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
				-- Use header from header pool
				button = self.classicHeaderPool[headerIndex]
				headerIndex = headerIndex + 1
			elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
				-- Use invite header from pool
				if self.classicInviteHeaderPool then
					button = self.classicInviteHeaderPool[inviteHeaderIndex]
					inviteHeaderIndex = inviteHeaderIndex + 1
				end
			elseif elementData.buttonType == BUTTON_TYPE_INVITE then
				-- Use invite button from pool
				if self.classicInviteButtonPool then
					button = self.classicInviteButtonPool[inviteButtonIndex]
					inviteButtonIndex = inviteButtonIndex + 1
				end
			elseif elementData.buttonType == BUTTON_TYPE_DIVIDER then
				-- Use divider from pool
				if self.classicDividerPool then
					button = self.classicDividerPool[dividerIndex]
					dividerIndex = dividerIndex + 1
				end
			else
				-- Use friend button from button pool
				button = self.classicButtonPool[buttonIndex]
				buttonIndex = buttonIndex + 1
			end
			
			if button and elementData then
				-- Position button (set BOTH TOPLEFT and RIGHT for full width)
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", self.classicScrollFrame.ContentFrame, "TOPLEFT", 2, -yOffset)  -- 2px left padding
				button:SetPoint("RIGHT", self.classicScrollFrame.ContentFrame, "RIGHT", 5, 0)  -- 12px - 2px right padding = 10px
				
				-- Get height for this item type
				local itemHeight = GetItemHeight(elementData, isCompactMode)
				button:SetHeight(itemHeight)
				
				-- Update button based on type
				if elementData.buttonType == BUTTON_TYPE_FRIEND then
					self:UpdateFriendButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
					self:UpdateGroupHeaderButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
					self:UpdateInviteHeaderButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE then
					self:UpdateInviteButton(button, elementData)
				end
				
				button:Show()
				yOffset = yOffset + itemHeight
			end
			-- Continue iterating to process other items in the logic (offset calculation)
		end
	end
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
-- ⚠️ DEPRECATED: Logic moved to BFL.ClassUtils
local function GetClassFileFromClassName(className) return BFL.ClassUtils:GetClassFileFromClassName(className)
end

-- Get class file for friend (optimized for 11.2.7+)
local function GetClassFileForFriend(friend) return BFL.ClassUtils:GetClassFileForFriend(friend)
end

-- ========================================
-- Module State
-- ========================================
FriendsList.friendsList = {}      -- Raw friends data from API
FriendsList.searchText = ""       -- Current search filter
FriendsList.filterMode = "all"    -- Current filter mode: all, online, offline, wow, bnet
FriendsList.sortMode = "status"   -- Current sort mode: status, name, level, zone

-- Reference to Groups
-- local friendGroups = {} -- MOVED TO TOP OF FILE

-- ========================================
-- Private Helper Functions
-- ========================================

-- Count table entries (replacement for tsize)
local function CountTableEntries(t) local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- Get last online time text (from Blizzard's FriendsFrame)
local function GetLastOnlineTime(timeDifference) if not timeDifference then
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

local function GetLastOnlineText(accountInfo) if not accountInfo or not accountInfo.lastOnlineTime or accountInfo.lastOnlineTime == 0 then
		return FRIENDS_LIST_OFFLINE
	else
		return string.format(BNET_LAST_ONLINE_TIME, GetLastOnlineTime(accountInfo.lastOnlineTime))
	end
end

-- Get friend unique ID (matching BetterFriendlist.lua format)
local function GetFriendUID(friend) if not friend then return nil end
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

-- Get display name based on format setting
-- @param forSorting (boolean) If true, use BattleTag instead of AccountName for BNet friends (prevents sorting issues with protected strings)
function FriendsList:GetDisplayName(friend, forSorting) -- PHASE 9.6: Display Name Caching
	if not self.displayNameCache then self.displayNameCache = {} end

	local DB = GetDB()
	local format = DB and DB:Get("nameDisplayFormat", "%name%") or "%name%"
	
	-- 1. Prepare Data
	local name = "Unknown"
	local battletag = friend.battleTag or ""
	local note = (friend.note or friend.notes or "")
	local uid = GetFriendUID(friend)
	local nickname = DB and DB:GetNickname(uid) or ""
	
	if friend.type == "bnet" then
		if forSorting then
			-- SORTING MODE: Use BattleTag (Short) instead of accountName
			-- This avoids issues with protected strings in accountName affecting sort order
			if friend.battleTag and friend.battleTag ~= "" then
				local bTag = friend.battleTag
				local hashIndex = string.find(bTag, "#")
				if hashIndex then
					name = string.sub(bTag, 1, hashIndex - 1)
				else
					name = bTag
				end
			else
				-- Fallback if no battletag available (rare)
				name = friend.accountName or "Unknown"
			end
		else
			-- DISPLAY MODE: Use accountName as requested (RealID or BattleTag)
			name = friend.accountName or "Unknown"
		end
	else
		-- WoW: Name is Character Name
		local fullName = friend.name or "Unknown"
		local showRealmName = DB and DB:Get("showRealmName", false)
		
		if showRealmName then
			name = fullName
		else
			local n, r = strsplit("-", fullName)
			local playerRealm = GetNormalizedRealmName() -- Use normalized realm
			
			if r and r ~= playerRealm then
				name = n .. "*" -- Indicate cross-realm
			else
				name = n
			end
		end
	end

	-- Process battletag to be short version as requested
	if battletag ~= "" then
		local hashIndex = string.find(battletag, "#")
		if hashIndex then
			battletag = string.sub(battletag, 1, hashIndex - 1)
		end
	end
	
	-- CACHE CHECK
	local cacheKey = (uid or "unknown") .. (forSorting and "_s" or "_d")
	local cacheEntry = self.displayNameCache[cacheKey]
	
	if cacheEntry and 
	   cacheEntry.format == format and
	   cacheEntry.note == note and
	   cacheEntry.nickname == nickname and
	   cacheEntry.name == name and
	   cacheEntry.btag == battletag then
		return cacheEntry.result
	end

	-- 2. Replace Tokens
	-- Use string replacement without closures for performance (Phase 9.2 Optimization)
	local result = format

	-- Smart Fallback Logic:
	-- If %nickname% is used but empty, and %name% is NOT in the format, use name as nickname
	if nickname == "" and result:find("%%nickname%%") and not result:find("%%name%%") then
		-- Fallback to name.
		-- NOTE: If forSorting=true and this is a BNet friend, 'name' has already been set to the BattleTag (the fix).
		-- So this correctly propagates the fix to the nickname fallback for sorting.
		nickname = name
	end
	-- Same for %battletag% (e.g. for WoW friends)
	if battletag == "" and result:find("%%battletag%%") and not result:find("%%name%%") then
		battletag = name
	end

	-- Optimize replacement: Escape special chars (%) in values and standard string replacement
	-- Check existence first to avoid unnecessary gsub calls
	if result:find("%%name%%") then
		local safeName = name:gsub("%%", "%%%%")
		result = result:gsub("%%name%%", safeName)
	end
	
	if result:find("%%note%%") then
		local safeNote = note:gsub("%%", "%%%%")
		result = result:gsub("%%note%%", safeNote)
	end
	
	if result:find("%%nickname%%") then
		local safeNickname = nickname:gsub("%%", "%%%%")
		result = result:gsub("%%nickname%%", safeNickname)
	end
	
	if result:find("%%battletag%%") then
		local safeBattletag = battletag:gsub("%%", "%%%%")
		result = result:gsub("%%battletag%%", safeBattletag)
	end
	
	-- 3. Cleanup
	-- Remove empty parentheses/brackets (e.g. "Name ()" -> "Name")
	result = result:gsub("%(%)", "")
	result = result:gsub("%[%]", "")
	-- Trim whitespace
	result = result:match("^%s*(.-)%s*$")
	
	-- 4. Fallback
	if result == "" then
		result = name
	end
	
	-- Cache the result
	self.displayNameCache[cacheKey] = {
		result = result,
		format = format,
		note = note,
		nickname = nickname,
		name = name,
		btag = battletag
	}
	
	return result
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function FriendsList:Initialize() -- Initialize sort modes and filter from database
	local DB = BFL:GetModule("DB")
	local db = DB and DB:Get() or {}
	self.sortMode = db.primarySort or "status"
	self.secondarySort = db.secondarySort or "name"
	-- CRITICAL: Load filterMode from DB to ensure consistency
	self.filterMode = db.quickFilter or "all"
	
	-- Sync groups from Groups module
	self:SyncGroups()
	
	-- Initialize ScrollBox system (NEW - Phase 1)
	self:InitializeScrollBox()
	
	-- Initialize responsive SearchBox width
	C_Timer.After(0.1, function() if BFL.FriendsList and BFL.FriendsList.UpdateSearchBoxWidth then
			BFL.FriendsList:UpdateSearchBoxWidth()
			-- BFL:DebugPrint("|cff00ffffFriendsList:Initialize:|r Called UpdateSearchBoxWidth")
		else
			-- BFL:DebugPrint("|cffff0000FriendsList:Initialize:|r UpdateSearchBoxWidth not found!")
		end
	end)
	
	-- Register event callbacks for friend list updates
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	-- Additional events from Blizzard's FriendsFrame
	BFL:RegisterEventCallback("BN_CONNECTED", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("BN_DISCONNECTED", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function(...) self:OnFriendListUpdate(...)
	end, 10)
	
	-- Register friend invite events
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", function() self:OnFriendListUpdate(true) -- Force immediate update
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_ADDED", function() -- Play sound immediately (Phase 1)
		PlaySound(SOUNDKIT.UI_BNET_TOAST)
		
		local collapsed = GetCVarBool("friendInvitesCollapsed")
		if collapsed then
			self:FlashInviteHeader()
		end
		self:OnFriendListUpdate(true) -- Force immediate update (Phase 2)
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_REMOVED", function() self:OnFriendListUpdate(true) -- Force immediate update (Phase 2)
	end, 10)
	
	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function() if needsRenderOnShow then
				-- BFL:DebugPrint("|cff00ffffFriendsList:|r Frame shown, dirty flag set - triggering refresh")
				self:UpdateFriendsList()
			end
		end)
		
		-- Also hook ScrollFrame OnShow for tab switching
		if BetterFriendsFrame.ScrollFrame then
			BetterFriendsFrame.ScrollFrame:HookScript("OnShow", function() if needsRenderOnShow then
					-- BFL:DebugPrint("|cff00ffffFriendsList:|r ScrollFrame shown, dirty flag set - triggering refresh")
					self:UpdateFriendsList()
				end
			end)
		end
	end
	
	-- Initialize font cache (Performance Optimization)
	self:UpdateFontCache()
end

-- Update cached font paths and colors to avoid lookups in render loop
function FriendsList:UpdateFontCache() 
	if not self.fontCache then self.fontCache = {} end
	
	local DB = GetDB()
	if not DB then return end

	-- Function to safely get color table
	local function GetColor(key)
		local c = DB:Get(key)
		if c and c.r and c.g and c.b then
			return c.r, c.g, c.b, c.a or 1
		end
		-- Default fallbacks if DB is missing or corrupt
		if key == "fontColorFriendName" then return 1, 0.82, 0, 1 end -- Gold/Yellow
		if key == "fontColorFriendInfo" then return 0.5, 0.5, 0.5, 1 end -- Gray
		return 1, 1, 1, 1
	end

	-- Name Font
	local nameFontName = DB:Get("fontFriendName", "Friz Quadrata TT")
	self.fontCache.namePath = LSM:Fetch("font", nameFontName)
	self.fontCache.nameSize = DB:Get("fontSizeFriendName", 13)
	self.fontCache.nameR, self.fontCache.nameG, self.fontCache.nameB, self.fontCache.nameA = GetColor("fontColorFriendName")

	-- Info Font
	local infoFontName = DB:Get("fontFriendInfo", "Friz Quadrata TT")
	self.fontCache.infoPath = LSM:Fetch("font", infoFontName)
	self.fontCache.infoSize = DB:Get("fontSizeFriendInfo", 10)
	self.fontCache.infoR, self.fontCache.infoG, self.fontCache.infoB, self.fontCache.infoA = GetColor("fontColorFriendInfo")
end

-- Handle friend list update events
function FriendsList:OnFriendListUpdate(forceImmediate) -- Event Coalescing (Micro-Throttling)
	-- Instead of updating immediately for every event, we schedule an update for the next frame.
	-- This handles "event bursts" (e.g. 50 friends coming online at once) by updating only once.
	
	-- Phase 2: Allow bypassing throttle for critical UI interactions (Invites)
	if forceImmediate then
		if self.updateTimer then
			self.updateTimer:Cancel()
			self.updateTimer = nil
		end
		self:UpdateFriendsList()
		return
	end
	
	-- Phase 9.5 Strict Throttling: 
	-- If frame is hidden, DO NOT allocate a timer or closure.
	-- Just mark as dirty (needsRenderOnShow) and return. 
	-- This saves valid memory/CPU cycles during gameplay when frame is closed.
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		needsRenderOnShow = true
		return
	end
	
	if self.updateTimer then
		-- Timer already running, update will happen next frame
		return
	end
	
	-- Schedule update with a small delay (0.1s) to batch multiple events
	-- This significantly reduces CPU usage during login or mass status changes
	self.updateTimer = C_Timer.After(0.1, function() self.updateTimer = nil
		self:UpdateFriendsList()
	end)
end

-- Sync groups from Groups module
function FriendsList:SyncGroups() local Groups = GetGroups()
	if Groups then
		friendGroups = Groups:GetAll()
	else
		-- Fallback: Use built-in groups
		friendGroups = {
			favorites = {
				id = "favorites",
				name = BFL.L.GROUP_FAVORITES,
				collapsed = false,
				builtin = true,
				order = 1,
				color = {r = 1.0, g = 0.82, b = 0.0},
				icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
			},
			nogroup = {
				id = "nogroup",
				name = BFL.L.GROUP_NO_GROUP,
				collapsed = false,
				builtin = true,
				order = 999,
				color = {r = 0.5, g = 0.5, b = 0.5},
				icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
			}
		}
	end
	
	-- Feature: In-Game Group (Dynamic)
	-- Now handled by Groups module (Groups:GetAll filters it based on settings)
end

-- ========================================
-- Sorting Priority Calculation Helpers (Optimized)
-- ========================================

local function CalculateStatusPriority(friend)
	if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
		return 3 -- Offline lowest priority
	end
	
	-- Check DND first (Priority 1)
	local isDND = false
	if friend.type == "bnet" then
		isDND = friend.isDND or (friend.gameAccountInfo and (friend.gameAccountInfo.isDND or friend.gameAccountInfo.isGameBusy))
	elseif friend.type == "wow" then
		isDND = friend.dnd
	end
	if isDND then return 1 end

	-- Check AFK second (Priority 2)
	local isAFK = false
	if friend.type == "bnet" then
		isAFK = friend.isAFK or (friend.gameAccountInfo and (friend.gameAccountInfo.isAFK or friend.gameAccountInfo.isGameAFK))
		if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp" then isAFK = true end
	elseif friend.type == "wow" then
		isAFK = friend.afk
	end
	if isAFK then return 2 end
	
	return 0 -- Online (Priority 0)
end

local function CalculateGamePriority(friend)
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
			-- Priority 0: Same WoW version as player
			if friendProjectID == WOW_PROJECT_ID then
				return 0  -- HIGHEST: Same version
			end
			
			-- Priority 1-99: Other WoW versions (sorted by projectID)
			return friendProjectID  -- Natural priority based on projectID
		end
		
		-- Non-WoW Blizzard games: Lower priority
		if clientProgram == "ANBS" then return 100 end -- Diablo IV
		if clientProgram == "WTCG" then return 101 end -- Hearthstone
		if clientProgram == "DIMAR" then return 102 end -- Diablo Immortal
		if clientProgram == "Pro" then return 103 end -- Overwatch 2
		if clientProgram == "S2" then return 104 end -- StarCraft II
		if clientProgram == "D3" then return 105 end -- Diablo III
		if clientProgram == "Hero" then return 106 end -- Heroes of the Storm
		if clientProgram == "BSAp" or clientProgram == "App" then return 200 end -- Lowest priority (mobile/app)
		return 150 -- Unknown/Other games
	end
	
	return 999  -- Fallback (offline)
end

local function CalculateFactionPriority(friend)
	local playerFaction = UnitFactionGroup("player")
	
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

local function CalculateGuildPriority(friend)
	local playerGuild = GetGuildInfo("player")
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
			friendGuild = friend.gameAccountInfo.guildName
		end
	end
	
	-- Not playing WoW = lowest priority
	if not isPlayingWoW then
		return 3, ""
	end
	
	-- Priority logic for WoW players
	if not friendGuild then
		return 2, "" -- No guild
	elseif playerGuild and friendGuild == playerGuild then
		return 0, friendGuild -- Same guild (highest)
	else
		return 1, friendGuild -- Other guild
	end
end

local TANK_CLASSES = {WARRIOR = 1, PALADIN = 1, DEATHKNIGHT = 1, DRUID = 1, MONK = 1, DEMONHUNTER = 1}
local HEALER_CLASSES = {PRIEST = 1, PALADIN = 1, SHAMAN = 1, DRUID = 1, MONK = 1, EVOKER = 1}

local function CalculateClassPriority(friend)
	-- Check if friend is actually playing WoW
	local isPlayingWoW = false
	if friend.type == "wow" and friend.connected then
		isPlayingWoW = true
	elseif friend.type == "bnet" and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "WoW" then
		isPlayingWoW = true
	end
	
	-- Not playing WoW = lowest priority (below all DPS)
	if not isPlayingWoW then
		return 10, ""
	end
	
	-- friend.class already contains the English class file (WARRIOR, MAGE, etc.)
	local classFile = friend.class
	
	if not classFile or classFile == "" or classFile == "Unknown" then
		return 9, "" -- Playing WoW but no class
	end
	
	if TANK_CLASSES[classFile] and HEALER_CLASSES[classFile] then
		return 0, classFile -- Hybrid (tank priority)
	elseif TANK_CLASSES[classFile] then
		return 0, classFile -- Pure tank
	elseif HEALER_CLASSES[classFile] then
		return 1, classFile -- Pure healer
	else
		return 2, classFile -- DPS
	end
end

local function CalculateRealmPriority(friend)
	local playerRealm = GetRealmName()
	local friendRealm = nil
	
	-- WoW-only friends
	if friend.type == "wow" and friend.name then
		friendRealm = friend.name:match("-(.+)$") or playerRealm
	end
	
	-- BNet friends playing WoW
	if friend.type == "bnet" and friend.gameAccountInfo then
		if friend.gameAccountInfo.clientProgram == "WoW" then
			friendRealm = friend.gameAccountInfo.realmName or friend.realmName
		end
	end
	
	if not friendRealm then
		return 2, "" -- No realm (offline/non-WoW)
	elseif friendRealm == playerRealm then
		return 0, friendRealm -- Same realm
	else
		return 1, friendRealm -- Other realm
	end
end

-- Update the friends list from WoW API
function FriendsList:UpdateFriendsList() -- Visibility Optimization:
	-- If the frame is hidden, we don't need to fetch data or rebuild the list.
	-- Just mark it as dirty so it updates when shown.
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		needsRenderOnShow = true
		isUpdatingFriendsList = false -- Ensure lock is released if it was somehow set
		return
	end

	-- Prevent concurrent updates
	if isUpdatingFriendsList then
		hasPendingUpdate = true
		return
	end
	
	isUpdatingFriendsList = true
	
	-- PHASE 9.6: Object Pooling Optimization
	-- Instead of wipe(self.friendsList), we overwrite existing entries to reduce garbage
	local listIndex = 0
	
	-- Helper to get next recycled object
	local function GetNextFriendObject()
		listIndex = listIndex + 1
		local f = self.friendsList[listIndex]
		if not f then
			f = {}
			self.friendsList[listIndex] = f
		else
			wipe(f)
		end
		return f
	end
	
	-- Sync groups first
	self:SyncGroups()
	
	-- Get Battle.net friends (Classic: May not be available)
	local bnetFriends = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendAccountInfo or nil
	-- Classic safeguard: BNGetNumFriends may not exist
	if bnetFriends and BNGetNumFriends then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		
		for i = 1, numBNetTotal do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local friend = GetNextFriendObject()
				
				friend.type = "bnet"
				friend.index = i
				friend.bnetAccountID = accountInfo.bnetAccountID
				friend.accountName = (accountInfo.accountName ~= "???") and accountInfo.accountName or nil
				friend.battleTag = accountInfo.battleTag
				
				-- PHASE 9.6: Cache UID for ActivityTracker (Hot Path)
				if friend.battleTag then
					friend.uid = "bnet_" .. friend.battleTag
				else
					friend.uid = "bnet_" .. (accountInfo.bnetAccountID or "unknown")
				end
				
				friend.connected = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline or false
				friend.note = accountInfo.note
				friend.isFavorite = accountInfo.isFavorite
				friend.gameAccountInfo = accountInfo.gameAccountInfo
				friend.lastOnlineTime = accountInfo.lastOnlineTime
				friend.isAFK = accountInfo.isAFK
				friend.isDND = accountInfo.isDND
				
				-- If they're playing WoW, get game info (EXACT COPY OF OLD LOGIC)
				if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
					local gameInfo = accountInfo.gameAccountInfo
					if gameInfo.clientProgram == "WoW" or gameInfo.clientProgram == "WTCG" then
						-- DEBUG: Log raw data for analysis
						if BFL.DebugPrint then
							-- BFL:DebugPrint(string.format("BNet Friend: %s (Prog: %s, Proj: %s, Class: %s, Area: %s, Rich: %s)", 
							-- 	tostring(gameInfo.characterName),
							-- 	tostring(gameInfo.clientProgram),
							-- 	tostring(gameInfo.wowProjectID),
							-- 	tostring(gameInfo.className),
							-- 	tostring(gameInfo.areaName),
							-- 	tostring(gameInfo.richPresence)
							-- ))
						end

						friend.characterName = gameInfo.characterName
						friend.className = gameInfo.className
						friend.classID = gameInfo.classID  -- 11.2.7+: Store classID for optimized class color lookup
						friend.areaName = gameInfo.areaName
						-- friend.richPresence = gameInfo.richPresence -- REVERTED: Caused issues with zone display
						friend.level = gameInfo.characterLevel
						friend.realmName = gameInfo.realmName
						friend.factionName = gameInfo.factionName
						friend.timerunningSeasonID = gameInfo.timerunningSeasonID
						
						-- Classic Fix: Parse richPresence if areaName is missing (e.g. "Zone - Realm")
						if (not friend.areaName or friend.areaName == "") and gameInfo.richPresence then
							local richZone, richRealm = strsplit("-", gameInfo.richPresence)
							if richZone then
								friend.areaName = strtrim(richZone)
							end
							if richRealm and (not friend.realmName or friend.realmName == "") then
								friend.realmName = strtrim(richRealm)
							end
						end
						
						if gameInfo.timerunningSeasonID then
							friend.timerunningSeasonID = gameInfo.timerunningSeasonID
						end

					elseif gameInfo.clientProgram == "BSAp" then
						friend.gameName = BFL.L.STATUS_MOBILE
						-- Feature: Treat Mobile as Offline (Phase Feature Request)
						local treatMobileAsOffline = GetDB():Get("treatMobileAsOffline", false)
						if treatMobileAsOffline then
							friend.connected = false  -- Treat as offline for sorting/display
							friend.isMobileButTreatedOffline = true  -- Flag for special display
						end
					elseif gameInfo.clientProgram == "App" then
						friend.gameName = BFL.L.STATUS_IN_APP
					else
						friend.gameName = gameInfo.clientProgram or BFL.L.UNKNOWN_GAME
					end
				end
			end
		end
	end
	
	-- Get WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends()
	-- Optimization: Cache player realm to avoid repeated API calls in loop
	local playerRealm = GetNormalizedRealmName()
	
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo then
			-- Normalize name to always include realm for consistent identification
			local normalizedName = BFL:NormalizeWoWFriendName(friendInfo.name, playerRealm)
			
			-- Extract realm name from normalized name (Name-Realm)
			local _, realmName = strsplit("-", normalizedName)
			
			-- Classic Fallback: Ensure area is populated
			-- C_FriendList might return nil area in some Classic versions
			local area = friendInfo.area
			if (not area or area == "") and BFL.IsClassic and GetFriendInfo then
				local _, _, _, classicArea = GetFriendInfo(i)
				area = classicArea
			end
			
			local friend = GetNextFriendObject()
			
			friend.type = "wow"
			friend.index = i
			friend.name = normalizedName -- Always includes realm: "Name-Realm"
			
			-- PHASE 9.6: Cache UID
			friend.uid = "wow_" .. normalizedName
			
			friend.realmName = realmName -- Explicitly store realm name for display
			friend.connected = friendInfo.connected
			friend.level = friendInfo.level
			friend.className = friendInfo.className
			friend.area = area
			friend.notes = friendInfo.notes
			friend.afk = friendInfo.afk
			friend.dnd = friendInfo.dnd
		end
	end
	
	-- Clean up excess recycled objects
	for i = #self.friendsList, listIndex + 1, -1 do
		self.friendsList[i] = nil
	end
	
	-- PERFY OPTIMIZATION: Pre-calculate sort keys for ALL friends
	-- This prevents recalculation during the N*log(N) sort process (1000s of calls)
	-- We always calculate ALL keys because primary/secondary sort can switch instantly
	
	-- PERFY OPTIMIZATION: Cache ActivityTracker module reference
	local ActivityTracker = BFL and BFL:GetModule("ActivityTracker")
	
	for _, friend in ipairs(self.friendsList) do
		-- Status Priority (Always used)
		friend._sort_status = CalculateStatusPriority(friend)
		
		-- PHASE 9.6: Cache Display Name
		-- Calculate main display name once per update
		friend.displayName = self:GetDisplayName(friend, false) or "Unknown"
		
		-- Name (Always used as fallback) - calculate lowercase once
		local nameForSort = self:GetDisplayName(friend, true) or ""
		friend._sort_name = nameForSort:lower()
		friend._sort_level = friend.level or 0
		
		-- Game Priority (For game sort)
		friend._sort_game = CalculateGamePriority(friend)
		
		-- Faction Priority (For faction sort)
		friend._sort_faction = CalculateFactionPriority(friend)
		
		-- Guild Priority (For guild sort)
		local gp, gName = CalculateGuildPriority(friend)
		friend._sort_guildPriority = gp
		friend._sort_guildName = gName and gName:lower() or ""
		
		-- Class Priority
		local cp, cName = CalculateClassPriority(friend)
		friend._sort_classPriority = cp
		friend._sort_className = cName -- Already file string (WARRIOR etc)
		
		-- Realm Priority
		local rp, rName = CalculateRealmPriority(friend)
		friend._sort_realmPriority = rp
		friend._sort_realmName = rName and rName:lower() or ""
		
		-- Zone Priority (Complex: Online+Zone > Online > Offline)
		local isOnline = ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected))
		local zoneName = (friend.areaName or friend.area or "")
		local hasZone = isOnline and zoneName ~= ""
		friend._sort_hasZone = hasZone
		friend._sort_zoneName = zoneName:lower()
		friend._sort_isOnline = isOnline -- Cached for fallback and zone sort
		
		-- Activity (Hybrid Activity + Last Online)
		local activityTime = 0
		-- Use cached ActivityTracker
		if ActivityTracker then
			-- PHASE 9.6: Use Cached UID
			local uid = friend.uid
			if uid then
				activityTime = ActivityTracker:GetLastActivity(uid) or 0
			end
		end
		-- Fallback to API lastOnline if no tracked activity
		if activityTime == 0 and friend.lastOnline then
			activityTime = friend.lastOnline
		end
		friend._sort_activity = activityTime
	end

	-- Apply filters and sort
	self:ApplyFilters()
	self:ApplySort()
	
	-- CRITICAL FIX: Render the display after building list
	-- Without this, UI never updates after friend offline/online events
	self:RenderDisplay()
	
	-- Release lock after update complete
	isUpdatingFriendsList = false
end

-- Clear pending update flag (used by ForceRefreshFriendsList to prevent race conditions)
function FriendsList:ClearPendingUpdate() hasPendingUpdate = false
end

-- Apply search and filter to friends list
function FriendsList:ApplyFilters() -- Filter is applied in RenderDisplay / BuildDataProvider
end

-- Optimized comparator to avoid closure allocation
local function SortComparator(a, b)
	local self = FriendsList
	local primarySort = self.currentPrimarySort
	local secondarySort = self.currentSecondarySort
	
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

	-- FALLBACK FOR OFFLINE FRIENDS: Sort by Last Online Time
	local aOffline = not a._sort_isOnline
	local bOffline = not b._sort_isOnline

	if aOffline and bOffline then
		local aTime = a.lastOnlineTime or 0
		local bTime = b.lastOnlineTime or 0
		if aTime ~= bTime then
			return aTime > bTime -- Recent first
		end
	end
	
	-- Fallback: sort by name
	local fallbackResult = self:CompareFriends(a, b, "name")
	if fallbackResult ~= nil then
		return fallbackResult
	end
	
	-- Ultimate fallback: stable sort by ID/Index
	return (a.index or 0) < (b.index or 0)
end

-- Apply sort order to friends list (with primary and secondary sort)
function FriendsList:ApplySort() -- Store sort modes for the static comparator
	self.currentPrimarySort = self.sortMode
	self.currentSecondarySort = self.secondarySort or "name"
	
	-- Use static comparator to avoid closure allocation (Phase 9.4 Optimization)
	table.sort(self.friendsList, SortComparator)
end

-- Compare two friends by a specific sort mode (returns true, false, or nil if equal)
-- Compare two friends by a specific sort mode (Optimized)
function FriendsList:CompareFriends(a, b, sortMode)
	-- Use pre-calculated sort keys (FAST)
	
	if sortMode == "status" then
		-- 1. Sort by online status (Online > Offline)
		if a._sort_isOnline ~= b._sort_isOnline then
			return a._sort_isOnline
		end
		
		-- 2. Sort by Status Priority (Online > DND > AFK > Offline)
		local aP = a._sort_status or 3
		local bP = b._sort_status or 3
		if aP ~= bP then
			return aP < bP
		end
		return nil
		
	elseif sortMode == "name" then
		local aName = a._sort_name or ""
		local bName = b._sort_name or ""
		if aName ~= bName then
			return aName < bName
		end
		return nil
		
	elseif sortMode == "level" then
		local aLevel = a._sort_level or 0
		local bLevel = b._sort_level or 0
		if aLevel ~= bLevel then
			return aLevel > bLevel -- Descending
		end
		return nil
		
	elseif sortMode == "zone" then
		-- Priority 1: Online WITH zone
		if a._sort_hasZone ~= b._sort_hasZone then
			return a._sort_hasZone -- true > false
		end
		
		-- Both have zones: sort alphabetically
		if a._sort_hasZone then
			if a._sort_zoneName ~= b._sort_zoneName then
				return a._sort_zoneName < b._sort_zoneName
			end
			return nil
		end
		
		-- Priority 2: Online without zone vs Offline
		if a._sort_isOnline ~= b._sort_isOnline then
			return a._sort_isOnline
		end
		return nil
		
	elseif sortMode == "activity" then
		local aTime = a._sort_activity or 0
		local bTime = b._sort_activity or 0
		if aTime ~= bTime then
			return aTime > bTime -- Recent first
		end
		return nil
		
	elseif sortMode == "game" then
		local aP = a._sort_game or 999
		local bP = b._sort_game or 999
		if aP ~= bP then
			return aP < bP -- Lower is better
		end
		return nil
		
	elseif sortMode == "faction" then
		local aP = a._sort_faction or 3
		local bP = b._sort_faction or 3
		if aP ~= bP then
			return aP < bP
		end
		return nil
		
	elseif sortMode == "guild" then
		local aP = a._sort_guildPriority or 3
		local bP = b._sort_guildPriority or 3
		if aP ~= bP then
			return aP < bP
		end
		
		if aP == 1 then -- Both "Other Guild"
			if a._sort_guildName ~= b._sort_guildName then
				return a._sort_guildName < b._sort_guildName
			end
		end
		return nil
		
	elseif sortMode == "class" then
		local aP = a._sort_classPriority or 10
		local bP = b._sort_classPriority or 10
		if aP ~= bP then
			return aP < bP
		end
		
		if a._sort_className ~= b._sort_className then
			return a._sort_className < b._sort_className
		end
		return nil
		
	elseif sortMode == "realm" then
		local aP = a._sort_realmPriority or 2
		local bP = b._sort_realmPriority or 2
		if aP ~= bP then
			return aP < bP
		end
		
		if a._sort_realmName ~= b._sort_realmName then
			return a._sort_realmName < b._sort_realmName
		end
		return nil
	end
	
	return nil
end

-- Check if friend passes current filters
function FriendsList:PassesFilters(friend) -- Search text filter
	if self.searchText and self.searchText ~= "" then
		local searchLower = self.searchText:lower()
		local found = false
		
		-- Helper function to check if a field contains the search text
		local function contains(text) if text and text ~= "" and text ~= "???" then
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
		-- Hide AFK/DND friends (show all friends, but hide those who are AFK or DND)
		if friend.type == "bnet" then
			-- CRITICAL: isAFK/isDND are on friend object directly, not in gameAccountInfo
			if friend.isAFK or friend.isDND then
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

-- Get friend UID (public helper)
function FriendsList:GetFriendUID(friend) return GetFriendUID(friend)
end

-- Set search text
function FriendsList:SetSearchText(text) local newText = text or ""
	if self.searchText == newText then
		return
	end
	self.searchText = newText
	BFL:ForceRefreshFriendsList()
end

-- Set filter mode
function FriendsList:SetFilterMode(mode) local newMode = mode or "all"
	if self.filterMode == newMode then
		return
	end
	self.filterMode = newMode
	BFL:ForceRefreshFriendsList()
end

-- Set sort mode
function FriendsList:SetSortMode(mode) local newMode = mode or "status"
	if self.sortMode == newMode then
		return
	end
	self.sortMode = newMode
	
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
function FriendsList:SetSecondarySortMode(mode) if self.secondarySort == mode then
		return
	end
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

-- Helper: Get friends in a specific group (optimized for single group access)
function FriendsList:GetFriendsForGroup(targetGroupId) local groupFriends = {}
	local DB = GetDB()
	if not DB then return groupFriends end
	
	for _, friend in ipairs(self.friendsList) do
		-- Apply filters first
		if self:PassesFilters(friend) then
			local friendUID = GetFriendUID(friend)
			local isFavorite = (friend.type == "bnet" and friend.isFavorite)
			local isInTargetGroup = false
			local isInAnyGroup = false
			
			-- Check Favorites
			if isFavorite then
				if targetGroupId == "favorites" then isInTargetGroup = true end
				isInAnyGroup = true
			end
			
			-- Check In-Game Group
			if GetDB():Get("enableInGameGroup", false) then
				local mode = GetDB():Get("inGameGroupMode", "same_game")
				local isInGame = false
				
				if mode == "any_game" then
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected and friend.gameAccountInfo and friend.gameAccountInfo.isOnline then
						local client = friend.gameAccountInfo.clientProgram
						if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
							isInGame = true
						end
					end
				else
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
						if friend.gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
							isInGame = true
						end
					end
				end
				
				if isInGame then
					if targetGroupId == "ingame" then isInTargetGroup = true end
					isInAnyGroup = true
				end
			end
			
			-- Check Custom Groups
			local customGroups = (BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID]) or {}
			for _, groupId in ipairs(customGroups) do
				if type(groupId) == "string" then
					if groupId == targetGroupId then isInTargetGroup = true end
					isInAnyGroup = true
				end
			end
			
			-- Check "No Group"
			if not isInAnyGroup and targetGroupId == "nogroup" then
				isInTargetGroup = true
			end
			
			if isInTargetGroup then
				table.insert(groupFriends, friend)
			end
		end
	end
	
	return groupFriends
end

-- Attempt optimized group toggle without full list rebuild
function FriendsList:OptimizedGroupToggle(groupId, expanding) -- Only possible on Retail (ScrollBox)
	if not self.scrollBox then return false end
	
	local dataProvider = self.scrollBox:GetDataProvider()
	if not dataProvider then return false end
	
	local headerData = nil
	local friendsToRemove = {}
	local foundHeader = false
	
	-- Scan provider to find header and children
	for _, data in dataProvider:Enumerate() do
		if not foundHeader then
			if data.buttonType == BUTTON_TYPE_GROUP_HEADER and data.groupId == groupId then
				headerData = data
				foundHeader = true
				
				-- If expanding, we just need the header, so we can stop scanning
				if expanding then break end
			end
		else
			-- We are in the group (Collapsing logic)
			if data.buttonType == BUTTON_TYPE_FRIEND and data.groupId == groupId then
				table.insert(friendsToRemove, data) -- Collect data to remove
			else
				-- Hit something else (another header or filtered out), stop
				break
			end
		end
	end
	
	if not headerData then return false end
	
	-- Update header state
	headerData.collapsed = not expanding
	
	if not expanding then
		-- COLLAPSING: Remove friends
		-- Depending on DataProvider implementation, Remove(data) is usually available
		if dataProvider.Remove then
			for _, data in ipairs(friendsToRemove) do
				dataProvider:Remove(data)
			end
		else
			-- Fallback if Remove(data) missing (unlikely on Retail)
			return false
		end
	else
		-- EXPANDING: Insert friends
		local friends = self:GetFriendsForGroup(groupId)
		
		-- Find insertion index
		local insertIndex = nil
		if dataProvider.FindIndex then
			insertIndex = dataProvider:FindIndex(headerData)
		end
		
		-- Fallback scan if needed
		if not insertIndex then
			local idx = 0
			for _, data in dataProvider:Enumerate() do
				idx = idx + 1
				if data == headerData then insertIndex = idx; break end
			end
		end
		
		if insertIndex then
			insertIndex = insertIndex + 1 -- Start inserting AFTER header
			for _, friend in ipairs(friends) do
				dataProvider:InsertAtIndex({
					buttonType = BUTTON_TYPE_FRIEND,
					friend = friend,
					groupId = groupId
				}, insertIndex)
				insertIndex = insertIndex + 1
			end
		else
			return false -- Should not happen header was found earlier
		end
	end
	
	-- Manually update header visual to reflect new state
	self.scrollBox:ForEachFrame(function(frame, elementData) if elementData == headerData then
			self:UpdateGroupHeaderButton(frame, elementData)
		end
	end)
	
	return true
end

-- Toggle group collapsed state (Optimized)
function FriendsList:ToggleGroup(groupId) local Groups = GetGroups()
	if not Groups then return end
	
	-- Handle Accordion Mode
	-- Note: We do this before the main toggle to clear others
	local DB = GetDB()
	local accordionMode = DB and DB:Get("accordionGroups", false)
	local needsFullRefresh = false
	
	if accordionMode then
		local group = Groups:Get(groupId)
		-- If we are expanding a closed group
		if group and group.collapsed then
			for gid, gData in pairs(Groups.groups) do
				if gid ~= groupId and not gData.collapsed then
					-- Force collapse, suppress update
					Groups:SetCollapsed(gid, true, true)
					needsFullRefresh = true -- Multiple changes, safer to full refresh
				end
			end
		end
	end
	
	-- Toggle the target group, suppress native update
	if Groups:Toggle(groupId, true) then
		if needsFullRefresh then
			BFL:ForceRefreshFriendsList()
			return
		end
		
		-- Try optimized update first
		local group = Groups:Get(groupId)
		local expanding = not group.collapsed
		
		if self:OptimizedGroupToggle(groupId, expanding) then
			-- Optimization successful!
			return
		end
		
		-- Fallback to full refresh
		BFL:ForceRefreshFriendsList()
	elseif needsFullRefresh then
		-- Target group didn't change but others did (Accordion)
		BFL:ForceRefreshFriendsList()
	end
end

-- Create a new custom group
function FriendsList:CreateGroup(groupName) local Groups = GetGroups()
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
function FriendsList:RenameGroup(groupId, newName) local Groups = GetGroups()
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

-- Open color picker for a group
function FriendsList:OpenColorPicker(groupId) local Groups = GetGroups()
	if not Groups then return end
	
	local group = Groups:Get(groupId)
	if not group then return end
	
	local r, g, b = 1, 1, 1
	if group.color then
		r = group.color.r or 1
		g = group.color.g or 1
		b = group.color.b or 1
	end
	
	local info = {
		swatchFunc = function() local newR, newG, newB = ColorPickerFrame:GetColorRGB()
			Groups:SetColor(groupId, newR, newG, newB)
			BFL:ForceRefreshFriendsList()
		end,
		cancelFunc = function(previousValues) if previousValues then
				Groups:SetColor(groupId, previousValues.r, previousValues.g, previousValues.b)
				BFL:ForceRefreshFriendsList()
			end
		end,
		r = r,
		g = g,
		b = b,
		hasOpacity = false,
	}
	
	ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- Delete a group
function FriendsList:DeleteGroup(groupId) local Groups = GetGroups()
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
function FriendsList:InviteGroupToParty(groupId) local DB = GetDB()
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
function FriendsList:ToggleFriendInGroup(friendUID, groupId) local DB = GetDB()
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
	self:RenderDisplay()
	
	return not isInGroup -- Return new state (true = added)
end

-- Check if friend is in group
function FriendsList:IsFriendInGroup(friendUID, groupId) local DB = GetDB()
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
function FriendsList:RemoveFriendFromGroup(friendUID, groupId) local DB = GetDB()
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
	self:RenderDisplay()
end

-- ========================================
-- Friends Display Rendering
-- ========================================

-- RenderDisplay: Updates the visual display of the friends list
-- This function handles ScrollBox rendering, button pool management, 
-- friend button configuration (BNet/WoW), compact mode, and TravelPass buttons
-- Supports both Retail (ScrollBox/DataProvider) and Classic (FauxScrollFrame)
function FriendsList:RenderDisplay() -- Skip update if frame is not shown (performance optimization)
	-- But mark that we need to render when frame is shown
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		needsRenderOnShow = true
		return
	end
	
	-- Skip update if Friends list elements are hidden (means we're on another tab)
	if BetterFriendsFrame.ScrollFrame and not BetterFriendsFrame.ScrollFrame:IsShown() then
		needsRenderOnShow = true
		return
	end
	
	-- Skip update if we're not on the Friends tab (tab 1)
	if BetterFriendsFrame.FriendsTabHeader then
		local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		if selectedTab and selectedTab ~= 1 then
			needsRenderOnShow = true
			return
		end
	end
	
	-- Clear dirty flag since we're rendering now
	needsRenderOnShow = false
	
	-- Build DataProvider from friends list (used by both Retail and Classic)
	local dataProvider = BuildDataProvider(self)
	
	-- Classic: Use FauxScrollFrame rendering
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- Convert DataProvider to display list for Classic
		self.classicDisplayList = {}
		if dataProvider and dataProvider.Enumerate then
			for _, elementData in dataProvider:Enumerate() do
				table.insert(self.classicDisplayList, elementData)
			end
		end
		-- Render with Classic button pool
		self:RenderClassicButtons()
		return
	end
	
	-- Retail: Update ScrollBox with automatic scroll position preservation!
	local retainScrollPosition = true
	if self.scrollBox then
		self.scrollBox:SetDataProvider(dataProvider, retainScrollPosition)
	end
end

-- Check if render is needed (called when frame is shown)
function FriendsList:NeedsRenderOnShow() return needsRenderOnShow
end

-- ========================================
-- Button Update Functions (called by ScrollBox Factory)
-- ========================================

-- Update group header button (NEW - Phase 1)
function FriendsList:UpdateGroupHeaderButton(button, elementData) local groupId = elementData.groupId
	local name = elementData.name
	local count = elementData.count
	local collapsed = elementData.collapsed
	
	-- Store group data on button
	button.groupId = groupId
	button.elementData = elementData
	
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
	local DB = GetDB()
	local format = DB and DB:Get("headerCountFormat", "visible") or "visible"
	local countText = ""
	
	if format == "online" then
		-- Show "Online / Total" (e.g. "3/10")
		countText = string.format("%d/%d", elementData.onlineCount or 0, elementData.totalCount or 0)
	elseif format == "both" then
		-- Show "Filtered (Online) / Total" (e.g. "1 (3)/10")
		-- count = Filtered (currently shown)
		-- onlineCount = Total Online
		-- totalCount = Total Members
		countText = string.format("%d (%d)/%d", count, elementData.onlineCount or 0, elementData.totalCount or 0)
	else -- "visible" (Default)
		-- Show "Filtered / Total" (e.g. "3/10" or just "3" if same)
		countText = count
		if elementData.totalCount and elementData.totalCount > count then
			countText = string.format("%d/%d", count, elementData.totalCount)
		end
	end
	
	button:SetFormattedText("%s%s|r (%s)", colorCode, name, countText)
	
	-- Apply Text Alignment (Feature Request)
	local align = DB and DB:Get("groupHeaderAlign", "LEFT") or "LEFT"
	if button:GetFontString() then
		button:GetFontString():ClearAllPoints()
		
		if align == "CENTER" then
			button:GetFontString():SetPoint("CENTER", button, "CENTER", 0, 0)
			button:GetFontString():SetJustifyH("CENTER")
		elseif align == "RIGHT" then
			-- Classic XML uses x=22 for LEFT, so we use x=-22 for RIGHT symmetry (minus arrow space)
			-- Note: Button has arrows on both sides in template, but usually only one is shown.
			button:GetFontString():SetPoint("RIGHT", button, "RIGHT", -22, 0)
			button:GetFontString():SetJustifyH("RIGHT")
		else -- "LEFT" (Default)
			button:GetFontString():SetPoint("LEFT", button, "LEFT", 22, 0)
			button:GetFontString():SetJustifyH("LEFT")
		end
	end

	-- Show/hide and align collapse arrows (Feature Request)
	local showArrow = DB and DB:Get("showGroupArrow", true)
	local arrowAlign = DB and DB:Get("groupArrowAlign", "LEFT") or "LEFT"

	-- Reset visibility first
	if button.DownArrow then button.DownArrow:Hide() end
	if button.RightArrow then button.RightArrow:Hide() end

	if showArrow then
		local targetArrow = collapsed and button.RightArrow or button.DownArrow
		if targetArrow then
			targetArrow:Show()
			targetArrow:ClearAllPoints()
			
			-- Restore normal textures first (resetting any overrides)
			if BFL.IsClassic then
				if targetArrow == button.RightArrow then
					targetArrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
				else
					targetArrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
				end
			else
				if targetArrow == button.RightArrow then
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
					targetArrow:SetRotation(0)
				else
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-down")
					targetArrow:SetRotation(0)
				end
			end

			-- Base coordinates for unpressed state
			local point, x, y
			if arrowAlign == "RIGHT" then
				point = "RIGHT"
				
				-- Override texture for Right Arrow (Collapsed state) to point Left
				if targetArrow == button.RightArrow then
					if not BFL.IsClassic then
						targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
						targetArrow:SetRotation(math.pi)
					else
						targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-left")
					end
				end
				
				x = (targetArrow == button.DownArrow) and -8 or -6
				y = (targetArrow == button.DownArrow) and -2 or 0
			elseif arrowAlign == "CENTER" then
				point = "CENTER"
				
				if align == "CENTER" then
					-- If text is also centered, offset arrow to the left of text
					local textWidth = 0
					if button:GetFontString() then
						textWidth = button:GetFontString():GetStringWidth() or 0
					end
					local offset = (textWidth / 2) + 12
					x = -offset
				else
					x = (targetArrow == button.DownArrow) and 0 or 2
				end

				y = (targetArrow == button.DownArrow) and -2 or 0
			else -- LEFT (Default)
				point = "LEFT"
				x = (targetArrow == button.DownArrow) and 6 or 8
				y = (targetArrow == button.DownArrow) and -2 or 0
			end
			
			targetArrow:SetPoint(point, x, y)
			
			-- Override mouse scripts to support alignment (only once per button)
			if not button.isArrowScriptHooked then
				button:SetScript("OnMouseDown", function(self) if self.DownArrow and self.DownArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.DownArrow:GetPoint()
						if p then self.DownArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1) end
					end
					if self.RightArrow and self.RightArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.RightArrow:GetPoint()
						if p then self.RightArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1) end
					end
				end)
				
				button:SetScript("OnMouseUp", function(self) -- Trigger update to reset positions based on current settings
					if FriendsList and FriendsList.UpdateGroupHeaderButton and self.elementData then
						FriendsList:UpdateGroupHeaderButton(self, self.elementData)
					end
				end)
				button.isArrowScriptHooked = true
			end
		end
	end
	
	-- Apply font scaling
	local FontManager = GetFontManager()
	if FontManager and button:GetFontString() then
		FontManager:ApplyFontSize(button:GetFontString())
	end
	
	-- Tooltips for group headers
	button:SetScript("OnEnter", function(self) -- Check if we're currently dragging a friend
		local isDragging = BetterFriendsList_DraggedFriend ~= nil
		
		local Groups = GetGroups()
		local friendGroups = Groups and Groups:GetAll() or {}
		
		if isDragging and self.groupId and friendGroups[self.groupId] and not friendGroups[self.groupId].builtin then
			-- Show drop target tooltip
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.TOOLTIP_DROP_TO_ADD, 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_HOLD_SHIFT, 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		else
			-- Show group info tooltip
			if self.groupId and friendGroups[self.groupId] then
				local groupData = friendGroups[self.groupId]
				
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(groupData.name, 1, 1, 1)
				GameTooltip:AddLine(BFL.L.HINT_RIGHT_CLICK_OPTIONS, 0.7, 0.7, 0.7, true)
				if not groupData.builtin then
					GameTooltip:AddLine(L.TOOLTIP_DRAG_HERE, 0.5, 0.8, 1.0, true)
				end
				GameTooltip:Show()
			end
		end
	end)
	
	button:SetScript("OnLeave", function(self) GameTooltip:Hide()
	end)
	
	-- Add right-click menu functionality
	if Groups then
		local group = Groups:Get(groupId)
		if group and not group.builtin then
			-- Custom groups: Full context menu with Rename/Delete
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName) if buttonName == "RightButton" then
					-- Open context menu for custom group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription) local groupData = Groups:Get(self.groupId)
						if not groupData then return end
						
						rootDescription:CreateTitle(groupData.name)
						
						rootDescription:CreateButton(BFL.L.MENU_RENAME_GROUP, function() StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
						end)
						
						rootDescription:CreateButton(BFL.L.MENU_CHANGE_COLOR, function() FriendsList:OpenColorPicker(self.groupId)
						end)
						
						rootDescription:CreateButton(BFL.L.MENU_DELETE_GROUP, function() StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
						rootDescription:CreateButton(BFL.L.MENU_INVITE_GROUP, function() FriendsList:InviteGroupToParty(self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
					-- Notification Rules for Group (Beta Features)
					if BetterFriendlistDB.enableBetaFeatures then
						local notificationButton = rootDescription:CreateButton(BFL.L.MENU_NOTIFICATIONS)
						
						notificationButton:CreateRadio(
							BFL.L.MENU_NOTIFY_DEFAULT,
							function() local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return not rule or rule == "default"
							end,
							function() if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "default"
								print(string.format(BFL.L.MSG_NOTIFY_DEFAULT, groupData.name))
							end
						)
						
						notificationButton:CreateRadio(
							BFL.L.MENU_NOTIFY_WHITELIST,
							function() local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return rule == "whitelist"
							end,
							function() if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "whitelist"
								print(string.format(BFL.L.MSG_NOTIFY_WHITELIST, groupData.name))
							end
						)
						
						notificationButton:CreateRadio(
							BFL.L.MENU_NOTIFY_BLACKLIST,
							function() local rule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[self.groupId]
								return rule == "blacklist"
							end,
							function() if not BetterFriendlistDB.notificationGroupRules then
									BetterFriendlistDB.notificationGroupRules = {}
								end
								BetterFriendlistDB.notificationGroupRules[self.groupId] = "blacklist"
								print(string.format(BFL.L.MSG_NOTIFY_BLACKLIST, groupData.name))
							end
						)
						
						rootDescription:CreateDivider()
					end
					
					-- Group-wide action buttons
					rootDescription:CreateButton(BFL.L.MENU_COLLAPSE_ALL, function() for gid in pairs(Groups.groups) do
							Groups:SetCollapsed(gid, true, true)  -- true = force collapse
						end
						BFL:ForceRefreshFriendsList()
					end)
					
					rootDescription:CreateButton(BFL.L.MENU_EXPAND_ALL, function() for gid in pairs(Groups.groups) do
							Groups:SetCollapsed(gid, false, true)  -- false = force expand
						end
						BFL:ForceRefreshFriendsList()
					end)
				end)
			else
					-- Left click: toggle collapse
					FriendsList:ToggleGroup(self.groupId)
				end
			end)
		else
			-- Built-in groups: Right-click for Collapse/Expand All + Invite
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName) if buttonName == "RightButton" then
					-- Open context menu for built-in group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription) local groupData = Groups:Get(self.groupId)
						if not groupData then return end
						
						rootDescription:CreateTitle(groupData.name)
						
						rootDescription:CreateButton(BFL.L.MENU_RENAME_GROUP, function() StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
						end)
						
						rootDescription:CreateButton(BFL.L.MENU_CHANGE_COLOR, function() FriendsList:OpenColorPicker(self.groupId)
						end)
						
						rootDescription:CreateButton(BFL.L.MENU_INVITE_GROUP, function() FriendsList:InviteGroupToParty(self.groupId)
						end)
						
						rootDescription:CreateDivider()
						
						rootDescription:CreateButton(BFL.L.MENU_COLLAPSE_ALL, function() if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, true, true)  -- true = force collapse
								end
								BFL:ForceRefreshFriendsList()
							end
						end)
						
						rootDescription:CreateButton(BFL.L.MENU_EXPAND_ALL, function() if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, false, true)  -- false = force expand
								end
								BFL:ForceRefreshFriendsList()
							end
						end)
					end)
				else
					-- Left click: toggle collapse
					FriendsList:ToggleGroup(self.groupId)
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

-- ========================================
-- Drag & Drop Handlers (Hoisted - Phase 9.2)
-- ========================================

-- Drag OnUpdate Handler
local function Button_OnDragUpdate(self)
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
						-- Show highlight and update text
						frame.dropHighlight:Show()
						local headerText = string.format(BFL.L.HEADER_ADD_FRIEND, BetterFriendsList_DraggedFriend, groupData.name)
						frame:SetText(headerText)
					else
						-- Hide highlight and restore original text
						frame.dropHighlight:Hide()
						-- Optimization: Use cached count from elementData if available
						local memberCount = 0
						if frame.GetElementData then
							local data = frame:GetElementData()
							if data and data.count then
								memberCount = data.count
							end
						else
							-- Fallback (should not happen with ScrollBox)
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
						end
						local headerText = string.format("|cffffd700%s (%d)|r", groupData.name, memberCount)
						frame:SetText(headerText)
					end
				end
			end
		end
	end
end

-- Drag OnStart Handler
local function Button_OnDragStart(self)
	if self.friendData then
		-- Store friend name for header text updates
		BetterFriendsList_DraggedFriend = self.friendData.name or self.friendData.accountName or self.friendData.battleTag or "Unknown"
		
		-- Show drag overlay
		self.dragOverlay:Show()
		self:SetAlpha(0.5)
		
		-- Hide tooltip
		GameTooltip:Hide()
		
		-- Enable OnUpdate
		self:SetScript("OnUpdate", Button_OnDragUpdate)
	end
end

-- Drag OnStop Handler
local function Button_OnDragStop(self)
	-- Disable OnUpdate
	self:SetScript("OnUpdate", nil)
	
	-- Hide drag overlay
	if self.dragOverlay then
		self.dragOverlay:Hide()
	end
	self:SetAlpha(1.0)
	
	-- Get Groups and reset all header highlights and texts
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
	
	-- Get mouse position and find group header under cursor
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
	
	-- If dropped on a group, add friend to that group
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
			
			-- Add to target group
			local DB = GetDB()
			if DB and not DB:IsFriendInGroup(friendUID, droppedOnGroup) then
				DB:AddFriendToGroup(friendUID, droppedOnGroup)
			end
			BFL:ForceRefreshFriendsList()
		end
	end
	
	-- Clear dragged friend name
	BetterFriendsList_DraggedFriend = ""
end

-- Update friend button (called by ScrollBox factory for each visible friend)
function FriendsList:UpdateFriendButton(button, elementData) local friend = elementData.friend
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
	
	-- Use hoisted handlers to avoid closure creation (Phase 9.2)
	button:SetScript("OnDragStart", Button_OnDragStart)
	button:SetScript("OnDragStop", Button_OnDragStop)
	
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

	-- Apply Friend Name Font Settings (Optimized)
	if self.fontCache and self.fontCache.namePath then
		local _, _, currentFlags = button.Name:GetFont()
		
		-- Use FontManager to apply font with Alphabet support
		if BFL.FontManager and BFL.FontManager.ApplyFont then
			BFL.FontManager:ApplyFont(button.Name, self.fontCache.namePath, self.fontCache.nameSize, currentFlags)
		else
			button.Name:SetFont(self.fontCache.namePath, self.fontCache.nameSize, currentFlags)
		end
		
		button.Name:SetTextColor(self.fontCache.nameR, self.fontCache.nameG, self.fontCache.nameB, self.fontCache.nameA)
	end
	
	-- Show/hide friend elements based on compact mode
	button.status:Show()
	if isCompactMode then
		button.Info:Hide()  -- Hide second line in compact mode
	else
		button.Info:Show()

		-- Apply Friend Info Font Settings (Optimized)
		if self.fontCache and self.fontCache.infoPath then
			local _, _, currentFlags = button.Info:GetFont()
			
			-- Use FontManager to apply font with Alphabet support
			if BFL.FontManager and BFL.FontManager.ApplyFont then
				BFL.FontManager:ApplyFont(button.Info, self.fontCache.infoPath, self.fontCache.infoSize, currentFlags)
			else
				button.Info:SetFont(self.fontCache.infoPath, self.fontCache.infoSize, currentFlags)
			end
			
			button.Info:SetTextColor(self.fontCache.infoR, self.fontCache.infoG, self.fontCache.infoB, self.fontCache.infoA)
		end
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
		-- Feature: Flexible Name Format (Phase 15)
		local displayName = friend.displayName or self:GetDisplayName(friend)
		
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
			-- Check both account status (App) and game status (WoW /afk)
			local isAFK = friend.isAFK or (friend.gameAccountInfo and (friend.gameAccountInfo.isAFK or friend.gameAccountInfo.isGameAFK))
			local isDND = friend.isDND or (friend.gameAccountInfo and (friend.gameAccountInfo.isDND or friend.gameAccountInfo.isGameBusy))
			
			if isDND then
				button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-DnD")
			elseif isAFK or (showMobileAsAFK and isMobile) then
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
				-- CRITICAL: Classic Era does NOT support SetAtlas() - keep file-based textures from XML
				if not BFL.IsClassic then
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
				end
				-- Classic: Uses file-based textures from XML (Interface\FriendsFrame\TravelPass-Invite)
				
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
				-- REMOVED: (FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff") wrapper
				-- Now uses button.Name:SetTextColor() from settings
				line1Text = displayName
			end
			
			if friend.characterName then
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
			
			if useClassColor and not shouldGray and friend.className then
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
			-- Classic-compatible: GetMaxLevelForPlayerExpansion() doesn't exist in Classic
			local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or MAX_PLAYER_LEVEL or 60
			
			if friend.connected then
				local infoText = ""
				if friend.level and friend.areaName then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. friend.areaName
					else
						infoText = " - " .. string.format(L.LEVEL_FORMAT, friend.level) .. ", " .. friend.areaName
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. L.FRIEND_MAX_LEVEL
					else
						infoText = " - " .. string.format(L.LEVEL_FORMAT, friend.level)
					end
				elseif friend.areaName then
					infoText = " - " .. friend.areaName
				elseif friend.gameName then
					infoText = " - " .. friend.gameName
				end
				-- Add info in user-defined info color
				if infoText ~= "" then
					local infoColor = GetDB():Get("fontColorFriendInfo") or {r=0.5, g=0.5, b=0.5, a=1}
					local infoHex = string.format("|cff%02x%02x%02x", infoColor.r*255, infoColor.g*255, infoColor.b*255)
					line1Text = line1Text .. infoHex .. infoText .. "|r"
				end
			else
				-- Offline - add last online time
				if friend.lastOnlineTime then
					local infoColor = GetDB():Get("fontColorFriendInfo") or {r=0.5, g=0.5, b=0.5, a=1}
					local infoHex = string.format("|cff%02x%02x%02x", infoColor.r*255, infoColor.g*255, infoColor.b*255)
					line1Text = line1Text .. " " .. infoHex .. "- " .. GetLastOnlineText(friend) .. "|r"
				end
			end
		end
		
		button.Name:SetText(line1Text)
		
		-- Line 2: Level, Zone (in gray) - only used in normal mode
		if not isCompactMode then
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			-- Classic-compatible: GetMaxLevelForPlayerExpansion() doesn't exist in Classic
			local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or MAX_PLAYER_LEVEL or 60
			
			if friend.connected then
				if friend.level and friend.areaName then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(friend.areaName)
					else
						button.Info:SetText(string.format(L.LEVEL_FORMAT, friend.level) .. ", " .. friend.areaName)
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(L.FRIEND_MAX_LEVEL)
					else
						button.Info:SetText(string.format(L.LEVEL_FORMAT, friend.level))
					end
				elseif friend.areaName then
					button.Info:SetText(friend.areaName)
				elseif friend.gameName then
					-- Show "Mobile" or "In App" without "Playing" prefix
					button.Info:SetText(friend.gameName)
				else
					button.Info:SetText(L.ONLINE_STATUS)
				end
			else
				-- Offline - show last online time for Battle.net friends
				if friend.lastOnlineTime then
					button.Info:SetText(GetLastOnlineText(friend))
				else
					button.Info:SetText(L.OFFLINE_STATUS)
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
			if friend.dnd then
				button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-DnD")
			elseif friend.afk then
				button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Away")
			else
				button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
			end
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
			
			-- Feature: Flexible Name Format (Phase 15)
			local characterName = friend.displayName or self:GetDisplayName(friend)
			
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
			-- Feature: Flexible Name Format (Phase 15)
			local displayName = friend.displayName or self:GetDisplayName(friend)
			line1Text = "|cff7f7f7f" .. displayName .. "|r"
		end
		
		-- In compact mode, append additional info to line1Text
		if isCompactMode then
			local hideMaxLevel = GetDB():Get("hideMaxLevel", false)
			-- Classic-compatible: GetMaxLevelForPlayerExpansion() doesn't exist in Classic
			local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or MAX_PLAYER_LEVEL or 60
			
			if friend.connected then
				local infoText = ""
				if friend.level and friend.area then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. friend.area
					else
						infoText = " - " .. string.format(L.LEVEL_FORMAT, friend.level) .. ", " .. friend.area
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						infoText = " - " .. L.FRIEND_MAX_LEVEL
					else
						infoText = " - " .. string.format(L.LEVEL_FORMAT, friend.level)
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
			-- Classic-compatible: GetMaxLevelForPlayerExpansion() doesn't exist in Classic
			local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or MAX_PLAYER_LEVEL or 60
			
			if friend.connected then
				if friend.level and friend.area then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(friend.area)
					else
						button.Info:SetText(string.format(L.LEVEL_FORMAT, friend.level) .. ", " .. friend.area)
					end
				elseif friend.level then
					if hideMaxLevel and friend.level == maxLevel then
						button.Info:SetText(L.FRIEND_MAX_LEVEL)
					else
						button.Info:SetText(string.format(L.LEVEL_FORMAT, friend.level))
					end
				elseif friend.area then
					button.Info:SetText(friend.area)
				else
					button.Info:SetText(L.ONLINE_STATUS)
				end
			else
				button.Info:SetText(L.OFFLINE_STATUS)
			end
		end  -- end of if not isCompactMode
	end -- end of if friend.type == "bnet"
	
	-- Ensure button is visible
	button:Show()
end

-- ========================================
-- Friend Invite Functions
-- ========================================

function FriendsList:UpdateInviteHeaderButton(button, data) button.Text:SetFormattedText(L.INVITE_HEADER, data.count)
	local collapsed = GetCVarBool("friendInvitesCollapsed")
	
	-- Store data on button for callbacks (important for OnMouseUp refresh)
	button.elementData = data
	
	-- Get Database for settings
	local DB = GetDB and GetDB() or BFL.Settings
	
	-- APPLY TEXT ALIGNMENT (Feature Request)
	local align = DB and DB:Get("groupHeaderAlign", "LEFT") or "LEFT"
	if button.Text then
		button.Text:ClearAllPoints()
		if align == "CENTER" then
			button.Text:SetPoint("CENTER", button, "CENTER", 0, 0)
			button.Text:SetJustifyH("CENTER")
		elseif align == "RIGHT" then
			button.Text:SetPoint("RIGHT", button, "RIGHT", -22, 0)
			button.Text:SetJustifyH("RIGHT")
		else -- "LEFT" (Default)
			button.Text:SetPoint("LEFT", button, "LEFT", 22, 0)
			button.Text:SetJustifyH("LEFT")
		end
	end

	-- ARROW ALIGNMENT & VISIBILITY
	local showArrow = DB and DB:Get("showGroupArrow", true)
	local arrowAlign = DB and DB:Get("groupArrowAlign", "LEFT") or "LEFT"

	-- Reset visibility
	if button.DownArrow then button.DownArrow:Hide() end
	if button.RightArrow then button.RightArrow:Hide() end

	if showArrow then
		local targetArrow = collapsed and button.RightArrow or button.DownArrow
		if targetArrow then
			targetArrow:Show()
			targetArrow:ClearAllPoints()
			
			-- Restore normal textures (resetting overrides)
			if BFL.IsClassic then
				if targetArrow == button.RightArrow then
					targetArrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
				else
					targetArrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
				end
			else
				if targetArrow == button.RightArrow then
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
					targetArrow:SetRotation(0)
				else
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-down")
					targetArrow:SetRotation(0)
				end
			end

			-- Position Calculation
			local point, x, y
			if arrowAlign == "RIGHT" then
				point = "RIGHT"
				-- Flip right arrow to point left if aligned right
				if targetArrow == button.RightArrow then
					if not BFL.IsClassic then
						targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
						targetArrow:SetRotation(math.pi)
					else
						targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\arrow-left")
					end
				end
				x = (targetArrow == button.DownArrow) and -8 or -6
				y = (targetArrow == button.DownArrow) and -2 or 0
			elseif arrowAlign == "CENTER" then
				point = "CENTER"
				if align == "CENTER" then
					local textWidth = button.Text and button.Text:GetStringWidth() or 0
					local offset = (textWidth / 2) + 12
					x = -offset
				else
					x = (targetArrow == button.DownArrow) and 0 or 2
				end
				y = (targetArrow == button.DownArrow) and -2 or 0
			else -- LEFT (Default)
				point = "LEFT"
				x = (targetArrow == button.DownArrow) and 6 or 8
				y = (targetArrow == button.DownArrow) and -2 or 0
			end
			
			targetArrow:SetPoint(point, x, y)
			
			-- Mouse Scripts for Arrow depression
			if not button.isArrowScriptHooked then
				button:SetScript("OnMouseDown", function(self) if self.DownArrow and self.DownArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.DownArrow:GetPoint()
						if p then self.DownArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1) end
					end
					if self.RightArrow and self.RightArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.RightArrow:GetPoint()
						if p then self.RightArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1) end
					end
				end)
				
				button:SetScript("OnMouseUp", function(self) -- Trigger update via element factory if possible, or just re-run this function
					if FriendsList and FriendsList.UpdateInviteHeaderButton and self.elementData then
						FriendsList:UpdateInviteHeaderButton(self, self.elementData)
					end
				end)
				button.isArrowScriptHooked = true
			end
		end
	end
	
	-- Apply font scaling to header text
	local FontManager = BFL.FontManager
	if FontManager and button.Text then
		FontManager:ApplyFontSize(button.Text)
	end
	
	-- Setup OnClick handler for collapse/expand (only once)
	if not button.handlerRegistered then
		button:SetScript("OnClick", function(self) local collapsed = GetCVarBool("friendInvitesCollapsed")
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
function FriendsList:UpdateInviteButton(button, data) local inviteID, accountName
	
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
	button.Name:SetText((FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff") .. accountName .. "|r")
	
	-- Set Info text ALWAYS
	button.Info:SetText(L.INVITE_TAP_TEXT)
	
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
		button.AcceptButton:SetScript("OnClick", function(self) local parent = self:GetParent()
			if parent.inviteID then
				if BFL.MockFriendInvites.enabled then
					-- Mock: Remove from list and refresh
					for i, invite in ipairs(BFL.MockFriendInvites.invites) do
						if invite.inviteID == parent.inviteID then
							table.remove(BFL.MockFriendInvites.invites, i)
							print("|cff00ff00BetterFriendlist:|r " .. string.format(BFL.L.MOCK_INVITE_ACCEPTED, invite.accountName))
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
		button.DeclineButton:SetScript("OnClick", function(self) local parent = self:GetParent()
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
			
			MenuUtil.CreateContextMenu(self, function(owner, rootDescription) rootDescription:CreateButton("Decline", function() if BFL.MockFriendInvites.enabled then
						-- Mock: Remove from list and refresh
						for i, invite in ipairs(BFL.MockFriendInvites.invites) do
							if invite.inviteID == inviteID then
								table.remove(BFL.MockFriendInvites.invites, i)
								print("|cffff0000BetterFriendlist:|r " .. string.format(BFL.L.MOCK_INVITE_DECLINED, invite.accountName))
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
					rootDescription:CreateButton("Report Player", function() if C_ReportSystem and C_ReportSystem.OpenReportPlayerDialog then
							C_ReportSystem.OpenReportPlayerDialog(
								C_ReportSystem.ReportType.InappropriateBattleNetName,
								accountName
							)
						end
					end)
					rootDescription:CreateButton("Block Invites", function() BNSetBlocked(inviteID, true)
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
function FriendsList:FlashInviteHeader() if not self.scrollBox then
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
function FriendsList:FireEvent(eventName, ...) -- TODO: Implement event system for module communication
	-- This will allow Raid/QuickJoin modules to hook into friend list updates
end

-- ========================================
-- Responsive UI Functions
-- ========================================

-- Update SearchBox width dynamically based on available space
function FriendsList:UpdateSearchBoxWidth() local frame = BetterFriendsFrame
	if not frame then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No frame|r")
		return
	end
	
	if not frame.FriendsTabHeader then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No FriendsTabHeader|r")
		return
	end
	
	local header = frame.FriendsTabHeader
	if not header.SearchBox then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No SearchBox|r")
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
	-- CALCULATE OPTIMAL SEARCHBOX WIDTH (RESPONSIVE)
	-- ========================================
	
	-- Classic Mode: Fixed width to fit dropdowns
	if BFL.IsClassic then
		-- Let XML anchors handle width (Full Width)
		return
	end

	-- Fixed elements on the right side of the header:
	-- - QuickFilter dropdown (~125px)
	-- - Sort dropdown (~80px)
	-- Total reserved space: ~205px (with padding)
	local fixedElementsWidth = 205
	local availableWidth = frameWidth - fixedElementsWidth
	
	-- Clamp SearchBox to functional minimum (175px)
	-- NO MAXIMUM: Scale up to max frame width (800px - 205px = 595px)
	-- This allows SearchBox to grow with frame width for better UX
	local minSearchBoxWidth = 175
	
	if availableWidth < minSearchBoxWidth then
		availableWidth = minSearchBoxWidth
	end
	
	-- Apply new width
	header.SearchBox:SetWidth(availableWidth)
	
	-- BFL:DebugPrint(string.format("|cff00ffffFriendsList:|r SearchBox width updated: %.1fpx (frame width: %.1fpx)", 
	-- 	availableWidth, frameWidth))
end

-- Export module to BFL namespace (required for BFL.FriendsList access)
BFL.FriendsList = FriendsList

return FriendsList






