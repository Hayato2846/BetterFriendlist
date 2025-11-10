-- BetterFriendlist.lua
-- A friends list replacement for World of Warcraft with Battle.net support
-- Version 0.13
-- UI GLUE LAYER - XML Callbacks and thin wrappers for modular backend
-- Main business logic is in Modules/ folder

local ADDON_NAME, BFL = ...
local ADDON_VERSION = BFL.Version

-- ========================================
-- MODULE ACCESSORS
-- ========================================
-- Get modules
local function GetDB() return BFL:GetModule("DB") end
local function GetGroups() return BFL:GetModule("Groups") end
local function GetFriendsList() return BFL and BFL:GetModule("FriendsList") end
local function GetWhoFrame() return BFL and BFL:GetModule("WhoFrame") end
local function GetIgnoreList() return BFL and BFL:GetModule("IgnoreList") end
local function GetRecentAllies() return BFL and BFL:GetModule("RecentAllies") end
local function GetQuickFilters() return BFL and BFL:GetModule("QuickFilters") end
local function GetMenuSystem() return BFL and BFL:GetModule("MenuSystem") end
local function GetRAF() return BFL and BFL:GetModule("RAF") end
local FontManager = nil  -- Will be initialized after modules load
local ColorManager = nil -- Will be initialized after modules load

-- Initialize manager references
local function InitializeManagers()
	if not FontManager then FontManager = BFL.FontManager end
	if not ColorManager then ColorManager = BFL.ColorManager end
end

-- Define color constants if they don't exist (used by Recent Allies)
-- Note: Blizzard uses FRIENDS_OFFLINE_BACKGROUND_COLOR (with S), not FRIEND_OFFLINE_BACKGROUND_COLOR
if not FRIENDS_WOW_BACKGROUND_COLOR then
	FRIENDS_WOW_BACKGROUND_COLOR = CreateColor(0.101961, 0.149020, 0.196078, 1)
end
if not FRIENDS_OFFLINE_BACKGROUND_COLOR then
	FRIENDS_OFFLINE_BACKGROUND_COLOR = CreateColor(0.35, 0.35, 0.35, 1)
end

-- Constants
local NUM_BUTTONS = 12  -- Number of visible buttons in scroll frame

-- Display state
local friendsList = {}
local displayList = {} -- Flat list with groups and friends for display

-- Button pool management (now in Modules/ButtonPool.lua)

-- Performance optimization: Throttle updates to prevent lag
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1 -- Only update every 0.1 seconds maximum
local pendingUpdate = false

-- Sort mode tracking
local currentSortMode = "status" -- Default: status, name, level, zone

-- Quick filter state (session-only, not persistent)
local filterMode = "all" -- Options: "all", "online", "wow", "bnet", "offline"

-- Load filter mode from database
local function LoadFilterMode()
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		if db and db.quickFilter then
			filterMode = db.quickFilter
		end
	end
end

-- Button types (matching FriendsList module constants)
local BUTTON_TYPE_FRIEND = 1
local BUTTON_TYPE_GROUP_HEADER = 2

-- Visual settings helpers (wrappers for FontManager)
local function GetButtonHeight()
	InitializeManagers()
	return FontManager:GetButtonHeight()
end

local function GetFontSizeMultiplier()
	InitializeManagers()
	return FontManager:GetFontSizeMultiplier()
end

local function ApplyFontSize(fontString)
	InitializeManagers()
	FontManager:ApplyFontSize(fontString)
end

-- Animation helper functions (now in Utils/AnimationHelpers.lua)
-- Access via _G.BFL_CreatePulseAnimation and _G.BFL_CreateFadeOutAnimation

-- Friend Groups (now managed by Groups module)
local friendGroups = {} -- Will be synced from Groups module

-- Helper to get FriendsList module
local function GetFriendsList()
	return BFL:GetModule("FriendsList")
end

-- Helper to get ButtonPool module
local function GetButtonPool()
	return BFL:GetModule("ButtonPool")
end

-- Helper to get Groups module
local function GetGroups()
	return BFL:GetModule("Groups")
end

-- Helper to sync groups from module
local function SyncGroups()
	local Groups = GetGroups()
	if Groups then
		friendGroups = Groups:GetAll()
	end
end

-- Initialize groups immediately
SyncGroups()

-- Saved variables (managed by Database module)
-- BetterFriendlistDB is now handled by Modules/Database.lua

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

-- Helper function to get last online text (from Blizzard's FriendsFrame)
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

-- Search filter
local searchText = ""

-- Initialize the addon
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("FRIENDLIST_UPDATE")
frame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SOCIAL_QUEUE_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leaving combat
frame:RegisterEvent("WHO_LIST_UPDATE")

-- Global flag to track if we're showing a WHO player menu (not a friend)
_G.BetterFriendlist_IsWhoPlayerMenu = false

-- Hook UnitPopup to filter out group options for WHO players
local function FilterWhoPlayerMenu(rootDescription, contextData)
	if not _G.BetterFriendlist_IsWhoPlayerMenu then
		return -- Not a WHO player, don't filter
	end
	
	-- List of group-related options to hide for WHO players
	local groupOptionsToHide = {
		"BETTERFRIENDLIST_ADD_GROUP",
		"BETTERFRIENDLIST_REMOVE_GROUP", 
		"BETTERFRIENDLIST_MOVE_TO_GROUP",
		"BETTERFRIENDLIST_FAVORITE",
		"BETTERFRIENDLIST_UNFAVORITE",
	}
	
	-- Remove group management options
	if rootDescription and rootDescription.elements then
		for i = #rootDescription.elements, 1, -1 do
			local element = rootDescription.elements[i]
			if element and element.data then
				-- Check if this is one of our group options
				for _, optionName in ipairs(groupOptionsToHide) do
					if element.data.text and element.data.text:find(optionName) or
					   element.data.value == optionName then
						table.remove(rootDescription.elements, i)
						break
					end
				end
			end
		end
	end
end

-- Initialize Menu System (delegates to MenuSystem module)
local function InitializeMenuSystem()
	local MenuSystem = GetMenuSystem()
	if MenuSystem then
		MenuSystem:Initialize()
	end
end

-- Update the friends list data (now delegates to FriendsList module)
local function UpdateFriendsList()
	local FriendsList = GetFriendsList()
	
	if FriendsList then
		-- Set search and filter from local state
		FriendsList:SetSearchText(searchText)
		FriendsList:SetFilterMode(filterMode)
		-- DON'T override sortMode - it's managed internally by FriendsList module
		-- FriendsList:SetSortMode(currentSortMode)
		
		-- Update and build display list
		FriendsList:UpdateFriendsList()
		FriendsList:BuildDisplayList()
		
		-- Sync local state for compatibility
		friendsList = FriendsList.friendsList
		displayList = FriendsList.displayList
	end
end

-- Forward declaration for UpdateFriendsDisplay
local UpdateFriendsDisplay

-- Helper: Get color code for a group (wrapper for ColorManager)
local function GetGroupColorCode(groupId)
	InitializeManagers()
	return ColorManager:GetGroupColorCode(groupId)
end

-- Build display list with groups (now delegates to FriendsList module)
local function BuildDisplayList()
	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:BuildDisplayList()
		-- Sync local state for compatibility
		displayList = FriendsList.displayList
	end
end

-- ========================================
-- Quick Filter Functions
-- ========================================
-- QUICK FILTER DROPDOWN FUNCTIONS (Modern API, Icon-Only Display)
-- ========================================

-- Filter icon definitions (using WoW texture paths like StatusDropdown)
-- Note: Using .tga extension like FRIENDS_TEXTURE_ONLINE constant
local FILTER_ICONS = {
	all = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",  -- All Friends (friend icon)
	online = "Interface\\FriendsFrame\\StatusIcon-Online",       -- Online Only (green online icon)
	offline = "Interface\\FriendsFrame\\StatusIcon-Offline",     -- Offline Only (gray offline icon)
	wow = "Interface\\ChatFrame\\UI-ChatIcon-WoW",               -- WoW Only (WoW logo from chat)
	bnet = "Interface\\ChatFrame\\UI-ChatIcon-Battlenet"         -- Battle.net Only (BNet logo from chat)
}

-- Initialize the Quick Filter dropdown menu (Modern WoW 11.0+ API)
-- Based on InitializeStatusDropdown() implementation
function BetterFriendsFrame_InitQuickFilterDropdown()
	local dropdown = BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown
	if not dropdown then return end
	
	-- Helper function to check if a filter mode is selected
	local function IsSelected(mode)
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentFilter = db.quickFilter or filterMode or "all"
		return currentFilter == mode
	end
	
	-- Helper function to set the filter mode
	local function SetSelected(mode)
		if mode ~= filterMode then
			BetterFriendsFrame_SetQuickFilter(mode)
		end
	end
	
	-- Helper function to create radio button with icon (using Texture format like StatusDropdown)
	local function CreateRadio(rootDescription, text, mode)
		local radio = rootDescription:CreateButton(text, function() end, mode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	-- Set dropdown width (same as StatusDropdown)
	dropdown:SetWidth(51)
	
	-- Setup the dropdown menu
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
		
		-- Format for icon + text in menu (like StatusDropdown)
		local optionText = "\124T%s:16:16:0:0\124t %s"
		
		-- Create filter options with icons
		local allText = string.format(optionText, FILTER_ICONS.all, "All Friends")
		CreateRadio(rootDescription, allText, "all")
		
		local onlineText = string.format(optionText, FILTER_ICONS.online, "Online Only")
		CreateRadio(rootDescription, onlineText, "online")
		
		local offlineText = string.format(optionText, FILTER_ICONS.offline, "Offline Only")
		CreateRadio(rootDescription, offlineText, "offline")
		
		local wowText = string.format(optionText, FILTER_ICONS.wow, "WoW Only")
		CreateRadio(rootDescription, wowText, "wow")
		
		local bnetText = string.format(optionText, FILTER_ICONS.bnet, "Battle.net Only")
		CreateRadio(rootDescription, bnetText, "bnet")
	end)
	
	-- SetSelectionTranslator: Shows only the icon (like StatusDropdown)
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("\124T%s:16:16:0:0\124t", FILTER_ICONS[selection.data])
	end)
	
	-- Setup tooltip
	dropdown:SetScript("OnEnter", function()
		local filterText = "All Friends"
		if filterMode == "online" then
			filterText = "Online Only"
		elseif filterMode == "offline" then
			filterText = "Offline Only"
		elseif filterMode == "wow" then
			filterText = "WoW Only"
		elseif filterMode == "bnet" then
			filterText = "Battle.net Only"
		end
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		GameTooltip:SetText("Quick Filter: " .. filterText)
		GameTooltip:Show()
	end)
	
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Set the quick filter mode
function BetterFriendsFrame_SetQuickFilter(mode)
	filterMode = mode
	
	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.quickFilter = filterMode
	end
	
	-- Update FriendsList module with new filter
	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:SetFilterMode(filterMode)
	end
	
	-- Refresh the friends list
	UpdateFriendsList()
	UpdateFriendsDisplay()
end

-- ========================================
-- GROUP MANAGEMENT
-- ========================================
-- All group management functionality is delegated to Modules/Groups.lua
-- These wrapper functions are kept for backward compatibility only

-- Helper function to get friend unique ID (global for use in multiple places)
function GetFriendUID(friend)
	if not friend then return nil end
	if friend.type == "bnet" then
		-- Use battleTag as persistent identifier (bnetAccountID is temporary per session)
		if friend.battleTag then
			return "bnet_" .. friend.battleTag
		elseif friend.bnetAccountID then
			-- Fallback: Try to look up battleTag from bnetAccountID
			local numBNet = BNGetNumFriends()
			for i = 1, numBNet do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				if accountInfo and accountInfo.bnetAccountID == friend.bnetAccountID and accountInfo.battleTag then
					return "bnet_" .. accountInfo.battleTag
				end
			end
			-- Last resort: use bnetAccountID (will cause issues with persistence)
			print("|cffff0000BetterFriendlist Warning:|r Using bnetAccountID for friend UID (battleTag unavailable)")
			return "bnet_" .. tostring(friend.bnetAccountID)
		else
			-- Should never happen
			print("|cffff0000BetterFriendlist Error:|r BNet friend without bnetAccountID or battleTag!")
			return "bnet_unknown"
		end
	else
		return "wow_" .. (friend.name or "")
	end
end

-- Helper function to get displayList count (used by XML mouse wheel handler)
function BetterFriendsFrame_GetDisplayListCount()
	return #displayList
end

-- ========================================
-- DISPLAY MANAGEMENT
-- ========================================

-- Update the UI display (Two-line layout with groups)
UpdateFriendsDisplay = function()
	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:RenderDisplay()
	end
end

-- Throttled update function to batch rapid events
local function RequestUpdate()
	local currentTime = GetTime()
	
	-- If enough time has passed, update immediately
	if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
		lastUpdateTime = currentTime
		pendingUpdate = false
		UpdateFriendsList()
		UpdateFriendsDisplay()
	else
		-- Otherwise, schedule a delayed update
		if not pendingUpdate then
			pendingUpdate = true
			C_Timer.After(UPDATE_THROTTLE, function()
				if pendingUpdate and BetterFriendsFrame and BetterFriendsFrame:IsShown() then
					lastUpdateTime = GetTime()
					pendingUpdate = false
					UpdateFriendsList()
					UpdateFriendsDisplay()
				end
			end)
		end
	end
end

-- Global function for getting friends list (called from XML)
function BetterFriendlist_GetFriendsList()
	return friendsList
end

-- Global function for updating the display (called from XML)
function BetterFriendsFrame_UpdateDisplay()
	UpdateFriendsDisplay()
end

-- Handle search box text changes (called from XML)
function BetterFriendsFrame_OnSearchTextChanged(editBox)
	local text = editBox:GetText()
	-- Convert to lowercase, handle empty string as well
	searchText = (text and text ~= "") and text:lower() or ""
	
	-- Update FriendsList module with new search text
	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:SetSearchText(searchText)
	end
	
	-- Update immediately - filtering happens in UpdateFriendsList
	-- No need to throttle, RequestUpdate will handle that
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		RequestUpdate()
	end
end

-- Show the friends frame
function ShowBetterFriendsFrame()
	-- Clear search box
	if BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.SearchBox then
		BetterFriendsFrame.FriendsTabHeader.SearchBox:SetText("")
		searchText = ""
	end
	
	UpdateFriendsList()
	UpdateFriendsDisplay()
	
	-- Direct :Show() - now combat-safe (no longer SECURE frame)
	BetterFriendsFrame:Show()
end

-- Hide the friends frame  
function HideBetterFriendsFrame()
	-- Direct :Hide() - now combat-safe (no longer SECURE frame)
	BetterFriendsFrame:Hide()
end

-- Toggle the friends frame
function ToggleBetterFriendsFrame()
	BFL:DebugPrint("[BFL] ToggleBetterFriendsFrame() called - Frame shown: " .. tostring(BetterFriendsFrame:IsShown()))
	
	if BetterFriendsFrame:IsShown() then
		BFL:DebugPrint("[BFL] Hiding BetterFriendsFrame")
		HideBetterFriendsFrame()
	else
		BFL:DebugPrint("[BFL] Showing BetterFriendsFrame")
		ShowBetterFriendsFrame()
	end
end

-- Helper functions for child frame visibility
local function ShowChildFrame(childFrame)
	if not childFrame then return end
	childFrame:Show()
end

local function HideChildFrame(childFrame)
	if not childFrame then return end
	childFrame:Hide()
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == "BetterFriendlist" then
			-- Note: Version print is in Core.lua ADDON_LOADED handler (prevents duplicate)
			
		-- Initialize menu system
		InitializeMenuSystem()
		
		-- Load saved filter mode from database
		LoadFilterMode()
		
		-- Sync groups from module (if available)
		SyncGroups()			-- Initialize saved variables (fallback if modules not used)
			BetterFriendlistDB = BetterFriendlistDB or {}
			BetterFriendlistDB.groupStates = BetterFriendlistDB.groupStates or {}
			BetterFriendlistDB.customGroups = BetterFriendlistDB.customGroups or {}
			BetterFriendlistDB.friendGroups = BetterFriendlistDB.friendGroups or {}
			
			-- Load custom groups from DB (if not using modules)
			local Groups = GetGroups()
			if not Groups then
				-- Fallback: Load custom groups manually
				for groupId, groupInfo in pairs(BetterFriendlistDB.customGroups) do
					if not friendGroups[groupId] then
						friendGroups[groupId] = {
							id = groupId,
							name = groupInfo.name,
							collapsed = groupInfo.collapsed or false,
							builtin = false,
							order = groupInfo.order or 50,
							color = {r = 0, g = 0.7, b = 1.0},
							icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
						}
					end
				end
			end
			
			-- Load collapsed states
			for groupId, groupData in pairs(friendGroups) do
				if BetterFriendlistDB.groupStates[groupId] ~= nil then
					groupData.collapsed = BetterFriendlistDB.groupStates[groupId]
				end
			end
			
			-- Initialize Quick Filter dropdown
			if BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown then
				BetterFriendsFrame_InitQuickFilterDropdown()
			end
			
		-- COMBAT FIX: ESC key via CloseSpecialWindows hook
		-- CloseSpecialWindows is NOT protected and called by ESC before ToggleGameMenu
		-- Hook (not replace!) to ensure our frame also responds to ESC
		local originalCloseSpecialWindows = CloseSpecialWindows
		CloseSpecialWindows = function()
			local closedSomething = false
			
			-- If our frame is visible, close it
			if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
				HideBetterFriendsFrame()
				closedSomething = true
			end
			
			-- Always call original to handle other frames
			-- It returns true if it closed something
			local originalClosed = originalCloseSpecialWindows()
			
			-- Return true if either we closed something OR original closed something
			return closedSomething or originalClosed
		end
		
	
	-- For WoW 11.2: Use Menu.ModifyMenu with correct MENU_UNIT_* tags
	-- According to https://warcraft.wiki.gg/wiki/Blizzard_Menu_implementation_guide
	-- UnitPopup menus use "MENU_UNIT_<UNIT_TYPE>" format
	
	local function AddGroupsToFriendMenu(owner, rootDescription, contextData)
		-- CRITICAL: Don't add group options for WHO players (non-friends)
		if _G.BetterFriendlist_IsWhoPlayerMenu then
			return
		end
		
		-- contextData contains bnetIDAccount or name
		if not contextData then
			return
		end
		
		-- Determine friendUID from contextData
		local friendUID
		if contextData.bnetIDAccount then
			-- For BNet friends, we need to look up the battleTag
			local numBNet = BNGetNumFriends()
			for i = 1, numBNet do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				if accountInfo and accountInfo.bnetAccountID == contextData.bnetIDAccount then
					if accountInfo.battleTag then
						friendUID = "bnet_" .. accountInfo.battleTag
					else
						print("|cffff0000BetterFriendlist Warning:|r BNet friend without battleTag, using bnetAccountID")
						friendUID = "bnet_" .. tostring(contextData.bnetIDAccount)
					end
					break
				end
			end
			
			-- If not found in friends list (shouldn't happen), fallback to bnetAccountID
			if not friendUID then
				print("|cffff0000BetterFriendlist Warning:|r Could not find BNet friend, using bnetAccountID")
				friendUID = "bnet_" .. tostring(contextData.bnetIDAccount)
			end
		elseif contextData.name then
			friendUID = "wow_" .. contextData.name
		end
		
		if not friendUID then
			return
		end
		
		-- Check if this friend is in any custom group
		local friendCurrentGroups = {}
		if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
			for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
				friendCurrentGroups[gid] = true
			end
		end
		
		-- Add divider and Groups submenu
		rootDescription:CreateDivider()
		local groupsButton = rootDescription:CreateButton("Groups")
		
		-- Add "Create Group" option at the top
		groupsButton:CreateButton("Create Group", function()
			StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND", nil, nil, friendUID)
		end)
		
		-- Count custom groups
		local customGroupCount = 0
		for groupId, groupData in pairs(friendGroups) do
			if not groupData.builtin then
				customGroupCount = customGroupCount + 1
			end
		end
		
		-- Add divider if there are custom groups
		if customGroupCount > 0 then
			groupsButton:CreateDivider()
			
			-- Collect and sort custom groups by order
			local sortedGroups = {}
			for groupId, groupData in pairs(friendGroups) do
				if not groupData.builtin then
					table.insert(sortedGroups, {id = groupId, data = groupData})
				end
			end
			table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)
			
		-- Add checkbox for each custom group in sorted order
		for _, group in ipairs(sortedGroups) do
			-- Capture group.id in local variable for closure
			local groupId = group.id
			
			groupsButton:CreateCheckbox(
				group.data.name,
				function()
					-- Read state dynamically from DB each time checkbox is rendered
					if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
						for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
							if gid == groupId then
								return true
							end
						end
					end
					return false
				end,
				function()
					local Groups = GetGroups()
					if Groups then
						Groups:ToggleFriendInGroup(friendUID, groupId)
						BetterFriendsFrame_UpdateDisplay()
					end
				end
			)
		end			-- Add "Remove from All Groups" if friend is in custom groups
			if next(friendCurrentGroups) then
				groupsButton:CreateDivider()
				
				-- Add "Remove from All Groups" button
				local Groups = GetGroups()
				groupsButton:CreateButton("Remove from All Groups", function()
					if Groups then
						for currentGroupId in pairs(friendCurrentGroups) do
							Groups:RemoveFriendFromGroup(friendUID, currentGroupId)
						end
						BetterFriendsFrame_UpdateDisplay()
					end
				end)
			end
		end
	end
		
		-- Register for BattleNet friend menus (online and offline)
		if Menu and Menu.ModifyMenu then
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND_OFFLINE", AddGroupsToFriendMenu)
			
			-- Register for WoW friend menus (online and offline)
			Menu.ModifyMenu("MENU_UNIT_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_FRIEND_OFFLINE", AddGroupsToFriendMenu)
		end
		
		-- DEPRECATED: Old Menu.ModifyMenu code removed (was using wrong tags without MENU_UNIT_ prefix)
		
		-- Setup scroll frame
			if BetterFriendsFrame and BetterFriendsFrame.ScrollFrame then
				BetterFriendsFrame.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
					FauxScrollFrame_OnVerticalScroll(self, offset, 34, UpdateFriendsDisplay)
				end)
			end
			
			-- Setup close button
			if BetterFriendsFrame and BetterFriendsFrame.CloseButton then
				BetterFriendsFrame.CloseButton:SetScript("OnClick", function()
					HideBetterFriendsFrame()
				end)
			end
		end
	elseif event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_LIST_SIZE_CHANGED" or 
	       event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" or
	       event == "BN_FRIEND_INFO_CHANGED" then
		-- Fire callbacks for modules
		BFL:FireEventCallbacks(event, ...)
		
		-- Always allow events, but throttle them to prevent spam
		-- The UpdateFriendsList() function will apply search filter automatically
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			RequestUpdate() -- Use throttled update to prevent lag from rapid events
		end
	elseif event == "SOCIAL_QUEUE_UPDATE" or event == "GROUP_LEFT" or event == "GROUP_JOINED" then
		-- Update Quick Join tab counter when social queue changes
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			BetterFriendsFrame_UpdateQuickJoinTab()
		end
		-- Fire callbacks for RaidFrame module
		BFL:FireEventCallbacks(event, ...)
	elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
		-- Fire callbacks for RaidFrame module to update raid info
		BFL:FireEventCallbacks(event, ...)
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- Entering combat - update combat overlay on all raid buttons
		BetterRaidFrame_UpdateCombatOverlay(true)
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Leaving combat - update combat overlay on all raid buttons
		BetterRaidFrame_UpdateCombatOverlay(false)
	elseif event == "WHO_LIST_UPDATE" then
		-- Fire callbacks for modules
		BFL:FireEventCallbacks(event, ...)
		
		-- Update Who list when results are received
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() and BetterFriendsFrame.WhoFrame:IsShown() then
			BetterWhoFrame_Update()
		end
	elseif event == "PLAYER_LOGIN" then
		-- Override Close Button to use our Hide function
		if BetterFriendsFrame.CloseButton then
			BetterFriendsFrame.CloseButton:SetScript("OnClick", function()
				HideBetterFriendsFrame()
			end)
		end
		
		-- Initialize UI components (delegated to FrameInitializer)
		if BFL.FrameInitializer and BetterFriendsFrame then
			BFL.FrameInitializer:Initialize(BetterFriendsFrame)
		end
		
		-- Initialize Quick Join tab counter
		BetterFriendsFrame_UpdateQuickJoinTab()
		
		-- Initialize Quick Filter Buttons
		C_Timer.After(0.5, function()
			if BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.QuickFilters then
				BetterFriendsFrame_UpdateQuickFilterButtons()
			end
		end)
		
		-- Setup automatic keybind override (like BetterBags)
		BFL:DebugPrint("[BFL] Setting up keybind override system...")
		BFL.bindingFrame = BFL.bindingFrame or CreateFrame("Frame")
		BFL.bindingFrame:RegisterEvent("PLAYER_LOGIN")
		BFL.bindingFrame:RegisterEvent("UPDATE_BINDINGS")
		BFL.bindingFrame:SetScript("OnEvent", function(self, event, ...)
			BFL:DebugPrint("[BFL] Event received: " .. event)
			BFL_CheckKeyBindings()
		end)
		
		-- Trigger initial check after a short delay
		C_Timer.After(1, function()
			BFL:DebugPrint("[BFL] Running initial keybind check...")
			BFL_CheckKeyBindings()
		end)
	end
end)

-- Automatic Keybind Override System (like BetterBags)
-- Intercepts the default O-key and redirects it to our frame
function BFL_CheckKeyBindings()
	BFL:DebugPrint("[BFL] CheckKeyBindings called")
	
	if InCombatLockdown() then
		BFL:DebugPrint("[BFL] In combat, delaying keybind check")
		BFL.bindingFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	BFL.bindingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	ClearOverrideBindings(BFL.bindingFrame)
	
	local bindings = {
		"TOGGLESOCIAL",			-- O-key (default social/friends keybind)
		"TOGGLEFRIENDSTAB",		-- Alternative binding (if exists)
		"TOGGLEFRIENDSFRAME"	-- Possible alternative name
	}
	
	BFL:DebugPrint("[BFL] Checking " .. #bindings .. " binding names...")
	
	for _, binding in pairs(bindings) do
		local key, otherkey = GetBindingKey(binding)
		BFL:DebugPrint("[BFL] Binding '" .. binding .. "': key1=" .. tostring(key) .. ", key2=" .. tostring(otherkey))
		
		if key ~= nil then
			SetOverrideBinding(BFL.bindingFrame, true, key, "BETTERFRIENDLIST_TOGGLE")
			BFL:DebugPrint("[BFL] Override set: " .. key .. " -> BETTERFRIENDLIST_TOGGLE")
		end
		if otherkey ~= nil then
			SetOverrideBinding(BFL.bindingFrame, true, otherkey, "BETTERFRIENDLIST_TOGGLE")
			BFL:DebugPrint("[BFL] Override set: " .. otherkey .. " -> BETTERFRIENDLIST_TOGGLE")
		end
	end
	
	BFL:DebugPrint("[BFL] Keybind override complete")
end

-- Slash Commands are now in Core.lua
-- This avoids loading order conflicts

-- Show specific tab content (11.2.5: 4 tabs - Friends, Recent Allies, RAF, Sort)
function BetterFriendsFrame_ShowTab(tabIndex)
	local frame = BetterFriendsFrame
	if not frame then return end
	
	-- Use hybrid helper functions for all child frames
	HideChildFrame(frame.SortFrame)
	HideChildFrame(frame.RecentAlliesFrame)
	HideChildFrame(frame.RecruitAFriendFrame)
	HideChildFrame(frame.ScrollFrame)
	HideChildFrame(frame.MinimalScrollBar)
	HideChildFrame(frame.AddFriendButton)
	HideChildFrame(frame.SendMessageButton)
	HideChildFrame(frame.RecruitmentButton)
	
	if tabIndex == 1 then
		-- Show Friends list
		ShowChildFrame(frame.ScrollFrame)
		ShowChildFrame(frame.MinimalScrollBar)
		ShowChildFrame(frame.AddFriendButton)
		ShowChildFrame(frame.SendMessageButton)
		UpdateFriendsDisplay()
	elseif tabIndex == 2 then
		-- Show Recent Allies
		if frame.RecentAlliesFrame then
			ShowChildFrame(frame.RecentAlliesFrame)
			local RecentAllies = BFL:GetModule("RecentAllies")
			if RecentAllies then
				RecentAllies:Refresh(frame.RecentAlliesFrame, ScrollBoxConstants.RetainScrollPosition)
			end
		end
	elseif tabIndex == 3 then
		-- Show Recruit A Friend
		if frame.RecruitAFriendFrame then
			ShowChildFrame(frame.RecruitAFriendFrame)
			ShowChildFrame(frame.RecruitmentButton)
			
			-- Initialize RAF data (match Blizzard's OnLoad behavior)
			if C_RecruitAFriend and C_RecruitAFriend.IsSystemEnabled then
				-- Ensure Blizzard's RecruitAFriendFrame is loaded and initialized
				if not RecruitAFriendFrame then
					-- Load the addon if not loaded yet
					LoadAddOn("Blizzard_RecruitAFriend")
				end
				
				-- If Blizzard's frame exists, trigger its initialization
				if RecruitAFriendFrame then
					-- Call OnLoad if it hasn't been called yet (simulate first-time load)
					if RecruitAFriendFrame.OnLoad and not RecruitAFriendFrame.rafEnabled then
						RecruitAFriendFrame:OnLoad()
					end
					
					-- Call OnShow to refresh data (this is what Blizzard does when showing the tab)
					if RecruitAFriendFrame.OnShow then
						-- OnShow doesn't exist as a direct method, but we can trigger the event
						-- by registering events if not already done
						if not RecruitAFriendFrame.eventsRegistered then
							RecruitAFriendFrame:RegisterEvent("RAF_SYSTEM_ENABLED_STATUS")
							RecruitAFriendFrame:RegisterEvent("RAF_RECRUITING_ENABLED_STATUS")
							RecruitAFriendFrame:RegisterEvent("RAF_INFO_UPDATED")
							RecruitAFriendFrame.eventsRegistered = true
						end
					end
				end
				
				-- Get RAF system info
				local rafSystemInfo = C_RecruitAFriend.GetRAFSystemInfo()
				if rafSystemInfo then
					-- Store system info for use by RAF functions
					frame.RecruitAFriendFrame.rafSystemInfo = rafSystemInfo
				end
				
				-- Get RAF info and update
				local rafInfo = C_RecruitAFriend.GetRAFInfo()
				if rafInfo then
					BetterRAF_UpdateRAFInfo(frame.RecruitAFriendFrame, rafInfo)
					-- Also store in Blizzard's frame if it exists
					if RecruitAFriendFrame then
						RecruitAFriendFrame.rafInfo = rafInfo
					end
				end
				
				-- Request updated recruitment info (enables "Generate Link" functionality)
				C_RecruitAFriend.RequestUpdatedRecruitmentInfo()
			end
		end
	elseif tabIndex == 4 then
		-- Show Sort options (11.2.5: restored from dropdown to tab)
		ShowChildFrame(frame.SortFrame)
	end
end

-- Set sort method and update display
function BetterFriendlist_SetSortMethod(method)
	if not method then return end
	
	-- Update FriendsList module
	local FriendsList = BFL and BFL:GetModule("FriendsList")
	if FriendsList then
		FriendsList:SetSortMode(method)
	end
	
	-- Also store in legacy global for backwards compatibility
	currentSortMethod = method
	
	-- Switch back to Friends tab and update tab selection
	local frame = BetterFriendsFrame
	if frame and frame.FriendsTabHeader then
		PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
	end
	
	-- Show Friends tab content
	BetterFriendsFrame_ShowTab(1)
	
	-- Provide feedback
	local methodNames = {
		status = "Status (Online First)",
		name = "Name (A-Z)",
		level = "Level (Highest First)",
		zone = "Zone"
	}
	print("|cff00ff00Sort changed to:|r " .. (methodNames[method] or method))
end

-- Update Quick Join tab with group count (matching Blizzard's FriendsFrame_UpdateQuickJoinTab)
function BetterFriendsFrame_UpdateQuickJoinTab()
	local frame = BetterFriendsFrame
	if not frame or not frame.BottomTab4 then return end
	
	-- Get number of groups from QuickJoin module (supports mock mode)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	local numGroups = 0
	
	if QuickJoin then
		local groups = QuickJoin:GetAllGroups()
		numGroups = groups and #groups or 0
	else
		-- Fallback to C_SocialQueue if module not loaded
		numGroups = C_SocialQueue and C_SocialQueue.GetAllGroups and #C_SocialQueue.GetAllGroups() or 0
	end
	
	-- Update tab text with count
	frame.BottomTab4:SetText(QUICK_JOIN.." "..string.format(NUMBER_IN_PARENTHESES, numGroups))
	
	-- Resize tab to fit text (0 = no padding)
	PanelTemplates_TabResize(frame.BottomTab4, 0)
end

--------------------------------------------------------------------------
-- TRAVEL PASS BUTTON HANDLERS
--------------------------------------------------------------------------

-- TravelPass Button Handlers
function BetterFriendsList_TravelPassButton_OnClick(self)
	local friendData = self.friendData
	if not friendData or friendData.type ~= "bnet" then return end
	
	-- Get the actual Battle.net friend index from our stored data
	local numBNet = BNGetNumFriends()
	local actualIndex = nil
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID == friendData.bnetAccountID then
			actualIndex = i
			break
		end
	end
	
	if not actualIndex then return end
	
	-- Check if friend has multiple game accounts
	local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualIndex)
	
	if numGameAccounts > 1 then
		-- Multiple game accounts - need to show dropdown
		-- For now, just invite the first valid WoW account
		local playerFactionGroup = UnitFactionGroup("player")
		for i = 1, numGameAccounts do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, i)
			if gameAccountInfo and gameAccountInfo.clientProgram == BNET_CLIENT_WOW and 
			   gameAccountInfo.isOnline and gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
				-- Found a valid WoW account - send invite
				if gameAccountInfo.playerGuid then
					BNInviteFriend(gameAccountInfo.gameAccountID)
					return
				end
			end
		end
	else
		-- Single game account - invite directly
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, 1)
		if gameAccountInfo and gameAccountInfo.gameAccountID then
			BNInviteFriend(gameAccountInfo.gameAccountID)
		end
	end
end

function BetterFriendsList_TravelPassButton_OnEnter(self)
	local friendData = self.friendData
	if not friendData then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	-- Get the actual Battle.net friend index
	local numBNet = BNGetNumFriends()
	local actualIndex = nil
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID == friendData.bnetAccountID then
			actualIndex = i
			break
		end
	end
	
	if not actualIndex then
		GameTooltip:SetText("Error", RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		GameTooltip:Show()
		return
	end
	
	-- Check for invite restrictions (matching Blizzard's logic)
	local restriction = nil  -- Will be set to NO_GAME_ACCOUNTS if no valid accounts found
	local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualIndex)
	local playerFactionGroup = UnitFactionGroup("player")
	local hasWowAccount = false
	local isCrossFaction = false
	local factionName = nil
	
	for i = 1, numGameAccounts do
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, i)
		if gameAccountInfo then
			if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
				hasWowAccount = true
				if gameAccountInfo.factionName then
					factionName = gameAccountInfo.factionName
					isCrossFaction = (factionName ~= playerFactionGroup)
				end
				
				-- Check WoW version compatibility (same logic as enable/disable)
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
	
	-- If no restriction was set, means no game accounts at all
	if not restriction then
		restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
	end
	
	-- Set tooltip text based on restriction
	local tooltipText = TRAVEL_PASS_INVITE or "Invite to Group"
	if isCrossFaction then
		tooltipText = TRAVEL_PASS_INVITE_CROSS_FACTION or "Invite to Group"
	end
	
	GameTooltip:SetText(tooltipText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	
	-- Add cross-faction line
	if isCrossFaction and factionName then
		local factionLabel = factionName == "Horde" and (FACTION_HORDE or "Horde") or (FACTION_ALLIANCE or "Alliance")
		if CROSS_FACTION_INVITE_TOOLTIP then
			GameTooltip:AddLine(CROSS_FACTION_INVITE_TOOLTIP:format(factionLabel), nil, nil, nil, true)
		end
	end
	
	-- Add restriction text in red if there's a restriction
	if restriction ~= INVITE_RESTRICTION_NONE then
		local restrictionText = ""
		if restriction == INVITE_RESTRICTION_CLIENT then
			restrictionText = ERR_TRAVEL_PASS_NOT_WOW or "Friend is not playing World of Warcraft"
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_CLASSIC then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_CLASSIC_OVERRIDE or "This friend is playing World of Warcraft Classic."
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_MAINLINE then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_MAINLINE_OVERRIDE or "This friend is playing World of Warcraft."
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_ID then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT or "Friend is playing a different version of World of Warcraft"
		elseif restriction == INVITE_RESTRICTION_INFO then
			restrictionText = ERR_TRAVEL_PASS_NO_INFO or "Not enough information available"
		elseif restriction == INVITE_RESTRICTION_REGION then
			restrictionText = ERR_TRAVEL_PASS_DIFFERENT_REGION or "Friend is in a different region"
		elseif restriction == INVITE_RESTRICTION_NO_GAME_ACCOUNTS then
			restrictionText = "No game accounts available"
		end
		
		if restrictionText ~= "" then
			GameTooltip:AddLine(restrictionText, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		end
	end
	
	GameTooltip:Show()
end

-- Friend List Button OnEnter (tooltip)
function BetterFriendsList_Button_OnEnter(button)
	if not button.friendData then return end
	
	local friend = button.friendData
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	-- Show Battle.net account name as header
	if friend.accountName then
		GameTooltip:SetText(friend.accountName, FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b)
	end
	
	-- Show character info if online and playing WoW
	if friend.connected and friend.characterName and friend.gameAccountInfo then
		-- Add Timerunning icon to character name first
		local characterName = friend.characterName
		if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
			characterName = TimerunningUtil.AddSmallIcon(characterName)
		end
		
		-- Build the character line: "Name, Level X ClassName"
		local characterLine = characterName
		if friend.level and friend.className then
			characterLine = characterLine .. ", Level " .. friend.level .. " " .. friend.className
		end
		GameTooltip:AddLine(characterLine, 1, 1, 1, true)
		
		-- Show location (area + realm in one line like Blizzard)
		if friend.areaName then
			local locationLine = friend.areaName
			if friend.realmName then
				locationLine = locationLine .. " - " .. friend.realmName
			end
			GameTooltip:AddLine(locationLine, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
		elseif friend.realmName then
			GameTooltip:AddLine(friend.realmName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
		end
	elseif not friend.connected then
		-- Show last online time
		GameTooltip:AddLine(FRIENDS_LIST_OFFLINE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true)
	end
	
	-- Show note if exists
	if friend.note and friend.note ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(friend.note, 1, 0.82, 0, true)
	end
	
	-- Add activity information
	local ActivityTracker = BFL:GetModule("ActivityTracker")
	if ActivityTracker then
		local friendUID = nil
		
		-- Determine friend UID based on friend type
		if friend.bnetAccountID then
			-- Battle.net friend
			if friend.battleTag then
				friendUID = "bnet_" .. friend.battleTag
			end
		else
			-- WoW friend
			if friend.name then
				friendUID = "wow_" .. friend.name
			end
		end
		
		if friendUID then
			local activity = ActivityTracker:GetAllActivities(friendUID)
			if activity and (activity.lastWhisper or activity.lastGroup or activity.lastTrade) then
				GameTooltip:AddLine(" ") -- Spacer
				
				-- Show each activity type that exists
				if activity.lastWhisper then
					local elapsed = time() - activity.lastWhisper
					local timeText = SecondsToTime(elapsed) .. " ago"
					GameTooltip:AddDoubleLine(
						"Last Whisper:",
						timeText,
						0.7, 0.7, 0.7, -- Left color (gray)
						1.0, 1.0, 1.0  -- Right color (white)
					)
				end
				
				if activity.lastGroup then
					local elapsed = time() - activity.lastGroup
					local timeText = SecondsToTime(elapsed) .. " ago"
					GameTooltip:AddDoubleLine(
						"Last Group:",
						timeText,
						0.7, 0.7, 0.7,
						1.0, 1.0, 1.0
					)
				end
				
				if activity.lastTrade then
					local elapsed = time() - activity.lastTrade
					local timeText = SecondsToTime(elapsed) .. " ago"
					GameTooltip:AddDoubleLine(
						"Last Trade:",
						timeText,
						0.7, 0.7, 0.7,
						1.0, 1.0, 1.0
					)
				end
			 end
		end
	end
	
	GameTooltip:Show()
end

-- Friend List Button OnLeave
function BetterFriendsList_Button_OnLeave(button)
	GameTooltip:Hide()
end

-- Button OnClick Handler (1:1 from Blizzard)
function BetterFriendsList_Button_OnClick(button, mouseButton)
	if not button.friendInfo then
		return
	end
	
	if mouseButton == "LeftButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		-- Left click: Select friend (future functionality)
		-- For now, we just play the sound
	elseif mouseButton == "RightButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		
		local friendInfo = button.friendInfo
		
		if friendInfo.type == "bnet" then
			-- BattleNet friend context menu
			local accountInfo = C_BattleNet.GetFriendAccountInfo(friendInfo.index)
			if accountInfo then
				BetterFriendsList_ShowBNDropdown(
					accountInfo.accountName,
					accountInfo.gameAccountInfo.isOnline,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					true, -- friendsList
					accountInfo.bnetAccountID,
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					accountInfo.battleTag
				)
			end
		else
			-- WoW friend context menu
			local info = C_FriendList.GetFriendInfoByIndex(friendInfo.index)
			if info then
				BetterFriendsList_ShowDropdown(
					info.name,
					info.connected,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					true, -- friendsList
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					info.guid
				)
			end
		end
	end
end

-- Show WoW Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowDropdown(name, connected, lineID, chatType, chatFrame, friendsList, communityClubID, communityStreamID, communityEpoch, communityPosition, guid)
	if connected or friendsList then
		local contextData = {
			name = name,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = nil,
			guid = guid,
		}
		
		-- Determine menu type based on online status
		local menuType = connected and "FRIEND" or "FRIEND_OFFLINE"
		UnitPopup_OpenMenu(menuType, contextData)
	end
end

-- Show BattleNet Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowBNDropdown(name, connected, lineID, chatType, chatFrame, friendsList, bnetIDAccount, communityClubID, communityStreamID, communityEpoch, communityPosition, battleTag)
	if connected or friendsList then
		local contextData = {
			name = name,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = bnetIDAccount,
			battleTag = battleTag,
		}
		
		-- Determine menu type based on online status
		local menuType = connected and "BN_FRIEND" or "BN_FRIEND_OFFLINE"
		UnitPopup_OpenMenu(menuType, contextData)
	end
end

--------------------------------------------------------------------------
-- WHO FRAME FUNCTIONALITY
--------------------------------------------------------------------------

-- Who frame variables
local whoSortValue = 1  -- Default sort: zone
local MAX_WHOS_FROM_SERVER = 50  -- Maximum number of results from server
local NUM_WHO_BUTTONS = 17  -- Number of visible buttons in Who list
local whoDataProvider = nil
local selectedWhoButton = nil

--------------------------------------------------------------------------
-- WHO FRAME COLUMN DROPDOWN
--------------------------------------------------------------------------

-- WHO Frame mixins are now in Modules/WhoFrame.lua

--------------------------------------------------------------------------
-- CONTACTS MENU (11.2.5)
--------------------------------------------------------------------------

-- Contacts Menu (11.2.5 - replaces broadcast button, includes ignore list)
-- Uses MenuUtil like Blizzard's ContactsMenuMixin
function BetterFriendsFrame_ShowContactsMenu(button)
	MenuUtil.CreateContextMenu(button, function(ownerRegion, rootDescription)
		rootDescription:SetTag("CONTACTS_MENU");
		
		-- Add BetterFriendList title
		rootDescription:CreateTitle("BetterFriendList");
		
		-- Settings option
		rootDescription:CreateButton("Settings", function()
			BetterFriendlistSettings_Show()
		end);
		
		-- Show Blizzard's Friendlist option (conditional based on setting)
		local DB = GetDB()
		if DB and DB:Get("showBlizzardOption", false) then
			rootDescription:CreateButton("Show Blizzard's Friendlist", function()
				if FriendsFrame:IsShown() then
					HideUIPanel(FriendsFrame)
				else
					ShowUIPanel(FriendsFrame)
				end
			end);
		end
		
		-- Create Group option
		rootDescription:CreateButton("Create Group", function()
			StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP")
		end);
		
		rootDescription:CreateDivider();
		
		-- Broadcast option (only if BNet is connected)
		local canUseBroadCastFrame = BNFeaturesEnabled() and BNConnected();
		if canUseBroadCastFrame then
			rootDescription:CreateButton(CONTACTS_MENU_BROADCAST_BUTTON_NAME or "Set Broadcast Message", function()
				local broadcastFrame = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame.BroadcastFrame;
				if broadcastFrame then
					broadcastFrame:ToggleFrame();
				end
			end);
		end
		
		-- Ignore List option
		rootDescription:CreateButton(CONTACTS_MENU_IGNORE_BUTTON_NAME or "Manage Ignore List", function()
			BetterFriendsFrame_ShowIgnoreList();
		end);
	end);
end

-- Show Ignore List (11.2.5 - part of contacts menu)
function BetterFriendsFrame_ShowIgnoreList()
	-- Show IgnoreList module UI (always, even if empty)
	local IgnoreList = BFL and BFL:GetModule("IgnoreList")
	if IgnoreList then
		-- Set ignore list as active dropdown and show
		if BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow then
			BetterFriendsFrame.IgnoreListWindow:Show()
			IgnoreList:Update()
		end
	else
		-- Fallback: show console message
		local numIgnores = C_FriendList.GetNumIgnores()
		if numIgnores == 0 then
			print("Your ignore list is empty.")
		else
			print("Ignore List (" .. numIgnores .. " players):")
			for i = 1, numIgnores do
				local name = C_FriendList.GetIgnoreName(i)
				if name then
					print("  " .. i .. ". " .. name)
				end
			end
			print("Use '/unignore <name>' to remove someone from your ignore list.")
		end
	end
end

-- ========================================
-- XML CALLBACK FUNCTIONS (Required by XML OnLoad/OnEvent/OnShow/OnHide attributes)
-- ========================================
-- These functions are called directly from XML and must remain global

-- WHO Frame OnLoad (called from XML line 1540)
function BetterWhoFrame_OnLoad(self)
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:OnLoad(self)
	end
end

-- WHO Frame Update (called from XML OnShow and event handlers)
function BetterWhoFrame_Update()
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:Update()
	end
end

-- WHO Frame Sort By Column (called from XML header buttons)
function BetterWhoFrame_SortByColumn(column)
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SortByColumn(column)
	end
end

-- WHO Frame Send Request (called from XML Who button)
function BetterWhoFrame_SendWhoRequest(text)
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SendWhoRequest(text)
	end
end

-- WHO Frame Set Selected Button (called from XML)
function BetterWhoFrame_SetSelectedButton(button)
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SetSelectedButton(button)
	end
end

-- WHO Frame Invalidate Font Cache (called from XML OnShow)
function BetterWhoFrame_InvalidateFontCache()
	local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:InvalidateFontCache()
	end
end

-- Ignore List Window OnLoad (called from XML line 1801)
function BetterIgnoreListWindow_OnLoad(self)
	local IgnoreList = GetIgnoreList()
	if IgnoreList then
		IgnoreList:OnLoad(self)
	end
end

-- Ignore List Update (called from XML OnShow)
function IgnoreList_Update()
	local IgnoreList = GetIgnoreList()
	if IgnoreList then
		IgnoreList:Update()
	end
end

-- Recent Allies Frame OnLoad (called from XML line 1841)
function BetterRecentAlliesFrame_OnLoad(self)
	local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnLoad(self)
	end
end

-- Recent Allies Frame OnShow (called from XML)
function BetterRecentAlliesFrame_OnShow(self)
	local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnShow(self)
	end
end

-- Recent Allies Frame OnHide (called from XML)
function BetterRecentAlliesFrame_OnHide(self)
	local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnHide(self)
	end
end

-- Recent Allies Frame OnEvent (called from XML)
function BetterRecentAlliesFrame_OnEvent(self, event, ...)
	local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnEvent(self, event, ...)
	end
end

-- RAF Frame OnLoad (called from XML line 1292)
function BetterRAF_OnLoad(frame)
	local RAF = GetRAF()
	if RAF then
		RAF:OnLoad(frame)
	end
end

-- RAF Frame OnEvent (called from XML)
function BetterRAF_OnEvent(frame, event, ...)
	local RAF = GetRAF()
	if RAF then
		RAF:OnEvent(frame, event, ...)
	end
end

-- RAF Frame OnHide (called from XML)
function BetterRAF_OnHide(frame)
	local RAF = GetRAF()
	if RAF then
		RAF:OnHide(frame)
	end
end

-- RAF Button Callbacks (called from ScrollBox initializer and XML)
function BetterRecruitListButton_Init(button, elementData)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_Init(button, elementData)
	end
end

function BetterRecruitListButton_OnEnter(button)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_OnEnter(button)
	end
end

function BetterRecruitListButton_OnClick(button, mouseButton)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_OnClick(button, mouseButton)
	end
end

function BetterRecruitActivityButton_OnClick(button)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnClick(button)
	end
end

function BetterRecruitActivityButton_OnEnter(button)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnEnter(button)
	end
end

function BetterRecruitActivityButton_OnLeave(button)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnLeave(button)
	end
end

function BetterRAF_NextRewardButton_OnClick(button, mouseButton)
	local RAF = GetRAF()
	if RAF then
		RAF:NextRewardButton_OnClick(button, mouseButton)
	end
end

function BetterRAF_NextRewardButton_OnEnter(button)
	local RAF = GetRAF()
	if RAF then
		RAF:NextRewardButton_OnEnter(button)
	end
end

function BetterRAF_ClaimOrViewRewardButton_OnClick(button)
	local RAF = GetRAF()
	if RAF then
		RAF:ClaimOrViewRewardButton_OnClick(button)
	end
end

function BetterRAF_DisplayRewardsInChat(rafInfo)
	local RAF = GetRAF()
	if RAF then
		RAF:DisplayRewardsInChat(rafInfo)
	end
end

function BetterRAF_RecruitmentButton_OnClick(button)
	local RAF = GetRAF()
	if RAF then
		RAF:RecruitmentButton_OnClick(button)
	end
end

-- ========================================
-- BOTTOM TAB MANAGEMENT
-- ========================================

-- Function to show specific bottom tab
function BetterFriendsFrame_ShowBottomTab(tabIndex)
	local frame = BetterFriendsFrame
	if not frame then return end
	
	-- Use hybrid helper functions
	HideChildFrame(frame.ScrollFrame)
	HideChildFrame(frame.MinimalScrollBar)
	HideChildFrame(frame.AddFriendButton)
	HideChildFrame(frame.SendMessageButton)
	HideChildFrame(frame.RecruitmentButton)
	HideChildFrame(frame.WhoFrame)
	HideChildFrame(frame.RaidFrame)
	HideChildFrame(frame.SortFrame)
	HideChildFrame(frame.RecentAlliesFrame)
	HideChildFrame(frame.RecruitAFriendFrame)
	HideChildFrame(frame.QuickJoinFrame)
	
	-- Hide all friend list buttons explicitly
	if tabIndex ~= 1 then
		local ButtonPool = GetButtonPool()
		if ButtonPool then
			ButtonPool:ResetButtonPool()
		end
		for i = 1, NUM_BUTTONS do
			local xmlButton = frame.ScrollFrame and frame.ScrollFrame["Button" .. i]
			if xmlButton then
				HideChildFrame(xmlButton)
			end
		end
	end
	
	-- Hide/show FriendsTabHeader based on tab
	if frame.FriendsTabHeader then
		if tabIndex == 1 then
			ShowChildFrame(frame.FriendsTabHeader)
			if frame.FriendsTabHeader.SearchBox then
				ShowChildFrame(frame.FriendsTabHeader.SearchBox)
			end
		else
			HideChildFrame(frame.FriendsTabHeader)
		end
	end
	
	-- Hide/show Inset based on tab
	if frame.Inset then
		if tabIndex == 2 or tabIndex == 3 then
			HideChildFrame(frame.Inset)
		else
			ShowChildFrame(frame.Inset)
		end
	end
	
	if tabIndex == 1 then
		-- Friends list
		ShowChildFrame(frame.ScrollFrame)
		ShowChildFrame(frame.MinimalScrollBar)
		ShowChildFrame(frame.AddFriendButton)
		ShowChildFrame(frame.SendMessageButton)
		UpdateFriendsDisplay()
	elseif tabIndex == 2 then
		-- Who frame
		ShowChildFrame(frame.WhoFrame)
		BetterWhoFrame_Update()
	elseif tabIndex == 3 then
		-- Raid frame
		ShowChildFrame(frame.RaidFrame)
	elseif tabIndex == 4 then
		-- Quick Join
		ShowChildFrame(frame.QuickJoinFrame)
		if BetterQuickJoinFrame_OnShow then
			BetterQuickJoinFrame_OnShow(frame.QuickJoinFrame)
		end
	end
end

-- ========================================
-- WHO Frame Functions
-- ========================================
-- All WHO Frame functionality is delegated to Modules/WhoFrame.lua
-- XML callbacks reference module methods directly via mixins

-- ========================================
-- ========================================
-- IGNORE LIST Functions
-- ========================================
-- All Ignore List functionality is delegated to Modules/IgnoreList.lua
-- XML callbacks reference module methods directly via mixins

-- ========================================
-- Recent Allies Functions
-- ========================================
-- All Recent Allies functionality is delegated to Modules/RecentAllies.lua
-- XML callbacks reference module methods directly via mixins

-- ========================================
-- RAF (Recruit-a-Friend) Functions
-- ========================================
-- All RAF functionality is delegated to Modules/RAF.lua
-- XML callbacks reference module methods directly via mixins

-- ========================================
-- RECENT ALLIES CALLBACKS
-- ========================================

function BetterRecentAlliesEntry_OnEnter(self)
	local RecentAllies = BFL and BFL:GetModule("RecentAllies")
	if RecentAllies and RecentAllies.BuildTooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		RecentAllies:BuildTooltip(self, GameTooltip)
		GameTooltip:Show()
	end
end

function BetterRecentAlliesEntry_OnLeave(self)
	GameTooltip:Hide()
end

-- ========================================
-- RAID FRAME & QUICK JOIN XML CALLBACKS
-- ========================================
-- All Raid Frame and Quick Join XML callbacks have been moved to:
--   - UI/RaidFrameCallbacks.lua (268 lines)
--   - UI/QuickJoinCallbacks.lua (264 lines)
-- This keeps BetterFriendlist.lua focused on Friends List logic only.
