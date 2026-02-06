-- A friends list replacement for World of Warcraft with Battle.net support
-- Version 0.13
-- UI GLUE LAYER - XML Callbacks and thin wrappers for modular backend
-- Main business logic is in Modules/ folder

local ADDON_NAME, BFL = ...
local ADDON_VERSION = BFL.Version
local L = BFL.L

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
local function InitializeManagers() if not FontManager then FontManager = BFL.FontManager end
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

-- ========================================
-- Global Functions (for XML OnClick handlers)
-- ========================================

-- Toggle group collapsed/expanded state (called from XML)
function BetterFriendsList_ToggleGroup(groupId) local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		FriendsList:ToggleGroup(groupId)
	end
end

-- Toggle friend in group (called from Drag & Drop system - IDENTICAL to old system)
function BetterFriendsList_ToggleFriendInGroup(friendUID, groupId) local Groups = BFL:GetModule("Groups")
	if Groups then
		Groups:ToggleFriendInGroup(friendUID, groupId)
	end
end

-- ========================================
-- Constants and Display State
-- ========================================

-- Constants
-- NUM_BUTTONS handled by ScrollBox

-- Display state
-- friendsList handled by FriendsList module

-- Button management handled by ScrollBox Factory pattern

-- Performance optimization: Throttle updates to prevent lag
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1 -- Only update every 0.1 seconds maximum
local pendingUpdate = false

-- Sort mode tracking
local currentSortMode = "status" -- Default: status, name, level, zone

-- Quick filter state (session-only, not persistent)
local filterMode = "all" -- Options: "all", "online", "wow", "bnet", "offline"

-- Load filter mode from database
local function LoadFilterMode() local DB = BFL:GetModule("DB")
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
local function GetButtonHeight() InitializeManagers()
	return FontManager:GetButtonHeight()
end

local function GetFontSizeMultiplier() InitializeManagers()
	return FontManager:GetFontSizeMultiplier()
end

local function ApplyFontSize(fontString) InitializeManagers()
	FontManager:ApplyFontSize(fontString)
end

-- Apply Font Settings to Tabs (Called when settings change or frame shown)
function BFL:ApplyTabFonts()
	local db = BetterFriendlistDB
	if not db then return end
	
	-- Determine default font props from game standard
	local defaultFontName, defaultFontSize, defaultFontOutline = _G.GameFontNormalSmall:GetFont()
	
	-- Default values: Fallback to standard game font if not set
	local fontName = db.fontTabText or defaultFontName
	local fontSize = db.fontSizeTabText or defaultFontSize
	local fontOutline = db.fontOutlineTabText or "NORMAL"
	-- Shadow disabled per UI constraint, but we clear it to be safe
	
	-- Map outline values to API strings
	local outlineValue = ""
	if fontOutline == "THINOUTLINE" then outlineValue = "OUTLINE" 
	elseif fontOutline == "THICKOUTLINE" then outlineValue = "THICKOUTLINE"
	elseif fontOutline == "MONOCHROME" then outlineValue = "MONOCHROME"
	end
	
	-- Resolve font path using LSM if available
	local fontPath = fontName
	local SharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)
	if SharedMedia then
		-- Only fetch if it looks like a name, not a path
		if not fontName:find("\\") then
			fontPath = SharedMedia:Fetch("font", fontName) or fontName
		end
	end
	
	-- Update the shared font objects (used by all tabs)
	if _G.BetterFriendlistFontNormalSmall then
		_G.BetterFriendlistFontNormalSmall:SetFont(fontPath, fontSize, outlineValue)
		_G.BetterFriendlistFontNormalSmall:SetShadowOffset(0, 0) -- Shadow always off for cleanliness
	end
	
	if _G.BetterFriendlistFontHighlightSmall then
		_G.BetterFriendlistFontHighlightSmall:SetFont(fontPath, fontSize, outlineValue)
		_G.BetterFriendlistFontHighlightSmall:SetShadowOffset(0, 0)
	end
    
    -- Update specific tabs and force resize
	local tabs = {
		_G.BetterFriendsFrameBottomTab1,
		_G.BetterFriendsFrameBottomTab2,
		_G.BetterFriendsFrameBottomTab3,
		_G.BetterFriendsFrameBottomTab4,
		_G.BetterFriendsFrameTab1,
		_G.BetterFriendsFrameTab2,
		_G.BetterFriendsFrameTab3
	}
	
	for _, tab in ipairs(tabs) do
		if tab then
			-- Force update fontstring directly (in case object update doesn't propagate immediately)
            local fs = tab:GetFontString()
            if fs then
                fs:SetFont(fontPath, fontSize, outlineValue)
				fs:SetShadowOffset(0, 0)
				-- Ensure no width constraint on the text itself so it calculates full width
				fs:SetWidth(0) 
            end
            
            -- Recalculate width
            if PanelTemplates_TabResize then
				-- Determine configuration based on tab type
				local padding = 30 -- Default padding for Top Tabs (Larger to match original look)
				local minWidth = 60 -- Default min width
				local tabName = tab:GetName()

				if tabName and tabName:find("BottomTab") then
					padding = 20 -- Compact padding for bottom tabs
					minWidth = 80 -- Standard width for Bottom Tabs
				end
				
			    -- Standard resize with correct padding to set base textures correctly
				-- padding (arg2) is added to the text width
				-- minWidth (arg4) ensures the tab doesn't get too small
			    PanelTemplates_TabResize(tab, padding, nil, minWidth)
				
				-- Apply custom width constraints (Safety net)
				if fs then
					local textWidth = fs:GetStringWidth()
					local calculatedWidth = textWidth + padding
					
					-- Width Logic:
					-- 1. Must fit text + padding (Dynamic Expansion)
					-- 2. Must respect minimum width (No shrinking below default)
					local finalWidth = math.max(calculatedWidth, minWidth)
					
					-- Only force width if our calculated/min width is larger than what TabResize set
					-- This ensures we never shrink the tab, only expand it if necessary
					if tab:GetWidth() < finalWidth then
						tab:SetWidth(finalWidth)
					end
				end
            end
		end
	end
end

-- Animation helper functions (now in Utils/AnimationHelpers.lua)
-- Access via _G.BFL_CreatePulseAnimation and _G.BFL_CreateFadeOutAnimation

-- Friend Groups (now managed by Groups module)
local friendGroups = {} -- Will be synced from Groups module

-- Helper to get FriendsList module
local function GetFriendsList() return BFL:GetModule("FriendsList")
end

-- Helper to get Groups module
local function GetGroups() return BFL:GetModule("Groups")
end

-- Helper to sync groups from module
local function SyncGroups() local Groups = GetGroups()
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

-- Search filter
local searchText = ""

-- Localization Function (Call on PLAYER_LOGIN)
local function LocalizeUI() local frame = BetterFriendsFrame
	if not frame then return end

	-- Ensure Global Strings for XML usage (Literals in XML)
	_G.RAF_NEXT_REWARD_HELP_TEXT = L.RAF_NEXT_REWARD_HELP
	_G.WHO_LIST_SEARCH_INSTRUCTIONS = L.WHO_LIST_SEARCH_INSTRUCTIONS
	_G.WHO_LIST_LEVEL_TOOLTIP = L.WHO_LEVEL_FORMAT

	-- Tabs (Main Frame)
	if frame.FriendsTabHeader then
		if frame.FriendsTabHeader.Tab1 then frame.FriendsTabHeader.Tab1:SetText(L.TAB_FRIENDS or FRIENDS) end
		if frame.FriendsTabHeader.Tab2 then frame.FriendsTabHeader.Tab2:SetText(L.CONTACTS_RECENT_ALLIES_TAB_NAME) end
		if frame.FriendsTabHeader.Tab3 then 
			frame.FriendsTabHeader.Tab3:SetText(L.RECRUIT_A_FRIEND or RECRUIT_A_FRIEND)
			-- Check if RAF is enabled
			if not BFL.IsClassic and C_RecruitAFriend and C_RecruitAFriend.IsEnabled then
				if not C_RecruitAFriend.IsEnabled() then
					frame.FriendsTabHeader.Tab3:Hide()
				end
			elseif not BFL.IsClassic then
				frame.FriendsTabHeader.Tab3:Hide()
			end
		end
	end

	-- Search Box
	if frame.FriendsTabHeader and frame.FriendsTabHeader.SearchBox and frame.FriendsTabHeader.SearchBox.Instructions then
		frame.FriendsTabHeader.SearchBox.Instructions:SetText(L.SEARCH_FRIENDS_INSTRUCTION)
	end
	
	-- Broadcast Frame
	if frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame then
		local bnet = frame.FriendsTabHeader.BattlenetFrame
		if bnet.UnavailableLabel then bnet.UnavailableLabel:SetText(L.BATTLENET_UNAVAILABLE) end
		if bnet.BroadcastFrame then
			if bnet.BroadcastFrame.PromptText then bnet.BroadcastFrame.PromptText:SetText(L.FRIENDS_LIST_ENTER_TEXT) end
			if bnet.BroadcastFrame.UpdateButton then bnet.BroadcastFrame.UpdateButton:SetText(UPDATE) end
			if bnet.BroadcastFrame.CancelButton then bnet.BroadcastFrame.CancelButton:SetText(CANCEL) end
		end
	end

	-- Bottom Buttons
	if frame.AddFriendButton then frame.AddFriendButton:SetText(ADD_FRIEND) end
	if frame.SendMessageButton then frame.SendMessageButton:SetText(SEND_MESSAGE) end
	if frame.RecruitmentButton then frame.RecruitmentButton:SetText(L.RAF_RECRUITMENT) end
	
	-- Who Frame Columns (Classic/Retail)
	if frame.WhoFrame then
		if frame.WhoFrame.NameHeader then frame.WhoFrame.NameHeader:SetText(NAME) end
		if frame.WhoFrame.LevelHeader then frame.WhoFrame.LevelHeader:SetText(LEVEL_ABBR) end
		if frame.WhoFrame.ClassHeader then frame.WhoFrame.ClassHeader:SetText(CLASS) end
		if frame.WhoFrame.WhoButton then frame.WhoFrame.WhoButton:SetText(REFRESH) end
		if frame.WhoFrame.AddFriendButton then frame.WhoFrame.AddFriendButton:SetText(ADD_FRIEND) end
		if frame.WhoFrame.GroupInviteButton then frame.WhoFrame.GroupInviteButton:SetText(GROUP_INVITE) end
	end

	-- Settings Frame
	if BetterFriendlistSettingsFrame then
		local sFrame = BetterFriendlistSettingsFrame
		if sFrame.TitleContainer and sFrame.TitleContainer.TitleText then
			sFrame.TitleContainer.TitleText:SetText(L.SETTINGS_TITLE)
		end
		if sFrame.Tab1 then sFrame.Tab1:SetText(L.SETTINGS_TAB_GENERAL) end
		if sFrame.Tab2 then sFrame.Tab2:SetText(L.SETTINGS_TAB_GROUPS) end
		if sFrame.Tab3 then sFrame.Tab3:SetText(L.SETTINGS_TAB_ADVANCED) end
		if sFrame.Tab4 then sFrame.Tab4:SetText(L.SETTINGS_TAB_DATABROKER) end
		if sFrame.Tab6 then sFrame.Tab6:SetText(L.SETTINGS_TAB_GLOBAL_SYNC) end
	end
end

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
local function FilterWhoPlayerMenu(rootDescription, contextData) if not _G.BetterFriendlist_IsWhoPlayerMenu then
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
local function InitializeMenuSystem() local MenuSystem = GetMenuSystem()
	if MenuSystem then
		MenuSystem:Initialize()
	end
end

-- Update the friends list data (now delegates to FriendsList module)
local function UpdateFriendsList() local FriendsList = GetFriendsList()
	
	if FriendsList then
		-- Set search text from local state
		FriendsList:SetSearchText(searchText)
		
		-- CRITICAL: Read filterMode from DB instead of local variable to prevent stale values
		local DB = BFL:GetModule("DB")
		if DB then
			local db = DB:Get()
			if db and db.quickFilter then
				FriendsList:SetFilterMode(db.quickFilter)
				-- Update local cache
				filterMode = db.quickFilter
			end
		end
		
		-- DON'T override sortMode - it's managed internally by FriendsList module
		-- FriendsList:SetSortMode(currentSortMode)
		
		-- Update friends list data
		FriendsList:UpdateFriendsList()
		
		-- Sync local state for compatibility
		friendsList = FriendsList.friendsList
	end
end

-- Forward declaration for UpdateFriendsDisplay
local UpdateFriendsDisplay

-- Helper: Get color code for a group (wrapper for ColorManager)
local function GetGroupColorCode(groupId) InitializeManagers()
	return ColorManager:GetGroupColorCode(groupId)
end

-- ========================================
-- Quick Filter Functions
-- ========================================
-- QUICK FILTER DROPDOWN FUNCTIONS (Modern API, Icon-Only Display)
-- ========================================

-- Filter icon definitions (Feather Icons for custom filters)
local FILTER_ICONS = {
	all = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all",         -- All Friends (users icon)
	online = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-online",     -- Online Only (user-check icon)
	offline = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-offline",   -- Offline Only (user-x icon)
	wow = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-wow",           -- WoW Only (shield icon)
	bnet = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-bnet",         -- Battle.net Only (share-2 icon)
	hideafk = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-hide-afk",  -- Hide AFK (eye-off icon)
	retail = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-retail"     -- Retail Only (trending-up icon)
}

-- Initialize the Quick Filter dropdown menu (Modern WoW 11.0+ API)
-- Based on InitializeStatusDropdown() implementation
function BetterFriendsFrame_InitQuickFilterDropdown() local dropdown = BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown
	if not dropdown then return end
	
	-- Delegate to QuickFilters module
	local QuickFilters = GetQuickFilters()
	if QuickFilters then
		-- BFL:DebugPrint("BetterFriendlist: Delegating QuickFilter init to module")
		QuickFilters:InitDropdown(dropdown)
	else
		-- BFL:DebugPrint("BetterFriendlist: QuickFilters module not found!")
	end
end

-- Set the quick filter mode
-- DEPRECATED: This function is kept for backward compatibility only
-- All filter management is now handled by QuickFilters module
function BetterFriendsFrame_SetQuickFilter(mode) -- Delegate to QuickFilters module for consistent state management
	local QuickFilters = GetQuickFilters()
	if QuickFilters then
		QuickFilters:SetFilter(mode)
		-- QuickFilters:SetFilter already calls FriendsList:SetFilterMode and triggers refresh
		-- No need to call UpdateFriendsList() here - it would cause double update
	else
		-- Fallback if module not available
		filterMode = mode
		if BetterFriendlistDB then
			BetterFriendlistDB.quickFilter = filterMode
		end
		local FriendsList = GetFriendsList()
		if FriendsList then
			FriendsList:SetFilterMode(filterMode)
		end
	end
end

-- ========================================
-- GROUP MANAGEMENT
-- ========================================
-- All group management functionality is delegated to Modules/Groups.lua
-- These wrapper functions are kept for backward compatibility only

-- Helper function to get friend unique ID (global for use in multiple places)
function GetFriendUID(friend) if not friend then return nil end
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
			-- BFL:DebugPrint("|cffff0000BetterFriendlist Warning:|r Using bnetAccountID for friend UID (battleTag unavailable)")
			return "bnet_" .. tostring(friend.bnetAccountID)
		else
			-- Should never happen
			-- BFL:DebugPrint("|cffff0000BetterFriendlist Error:|r BNet friend without bnetAccountID or battleTag!")
			return "bnet_unknown"
		end
	else
		return "wow_" .. (friend.name or "")
	end
end

-- ========================================
-- DISPLAY MANAGEMENT
-- ========================================

-- Update the UI display (Two-line layout with groups)
UpdateFriendsDisplay = function() local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:RenderDisplay()
	end
end

-- Throttled update function to batch rapid events
-- IMPROVED (Phase 14d): Always update data layer, only conditionally update display
local function RequestUpdate(forceDisplay) local currentTime = GetTime()
	
	-- If enough time has passed, update immediately
	if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
		lastUpdateTime = currentTime
		pendingUpdate = false
		UpdateFriendsList() -- ALWAYS update data
		
		-- Only update display if frame is shown (unless forced)
		if forceDisplay or (BetterFriendsFrame and BetterFriendsFrame:IsShown()) then
			UpdateFriendsDisplay()
		end
	else
		-- Otherwise, schedule a delayed update
		if not pendingUpdate then
			pendingUpdate = true
			C_Timer.After(UPDATE_THROTTLE, function() if pendingUpdate then
					lastUpdateTime = GetTime()
					pendingUpdate = false
					UpdateFriendsList() -- ALWAYS update data
					
					-- Only update display if frame is shown
					if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
						UpdateFriendsDisplay()
					end
				end
			end)
		end
	end
end

-- Global function for getting friends list (called from XML)
function BetterFriendlist_GetFriendsList() return friendsList
end

-- Global function for updating the display (called from XML)
function BetterFriendsFrame_UpdateDisplay() UpdateFriendsDisplay()
end

-- Search debounce timer
local searchDebounceTimer = nil

-- Handle search box text changes (called from XML)
function BetterFriendsFrame_OnSearchTextChanged(editBox) local text = editBox:GetText()
	-- Convert to lowercase, handle empty string as well
	local newSearchText = (text and text ~= "") and text:lower() or ""
	
	-- Cancel pending search update
	if searchDebounceTimer then
		searchDebounceTimer:Cancel()
	end

	-- Debounce: Wait 0.3s after last keystroke before updating
	searchDebounceTimer = C_Timer.NewTimer(0.3, function()
		searchText = newSearchText
		searchDebounceTimer = nil
		
		-- Update FriendsList module with new search text
		local FriendsList = GetFriendsList()
		if FriendsList then
			FriendsList:SetSearchText(searchText)
			-- BFL:ForceRefreshFriendsList is called by SetSearchText, which handles the update
			-- Logic: SetSearchText -> BFL:ForceRefreshFriendsList -> FriendsList:UpdateFriendsList
		end
		
		-- Update immediately - filtering happens in UpdateFriendsList
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			-- Ensure display is updated
			RequestUpdate(true)
		end
	end)
end

-- Configure UI Panel Layout attributes for BetterFriendsFrame
-- Made global for access from Settings module
function ConfigureUIPanelAttributes(enable) if not BetterFriendsFrame then return end
	
	-- Optimization: Don't update if in combat (SetAttribute is restricted)
	if InCombatLockdown() then
		return
	end

	-- Optimization: Don't set attributes if they are already in the desired state
	local isDefined = BetterFriendsFrame:GetAttribute("UIPanelLayout-defined")
	if enable and isDefined then
		return
	elseif not enable and not isDefined then
		return
	end
	
	if enable then
		-- Enable UI Panel Layout system
		BetterFriendsFrame:SetAttribute("UIPanelLayout-defined", true)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-enabled", true)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-area", "left")
		BetterFriendsFrame:SetAttribute("UIPanelLayout-pushable", 0)  -- 8+ recommended for custom addons (Blizzard uses 0-7)
		-- BetterFriendsFrame:SetAttribute("UIPanelLayout-width", width) -- Custom width is not recommended
		BetterFriendsFrame:SetAttribute("UIPanelLayout-whileDead", true)
		BFL:DebugPrint("UI Panel Layout attributes enabled")
	else
		-- Disable UI Panel Layout system
		-- CRITICAL: Remove from UIPanelWindows first (ShowUIPanel auto-registers it)
		if UIPanelWindows and UIPanelWindows["BetterFriendsFrame"] then
			UIPanelWindows["BetterFriendsFrame"] = nil
			BFL:DebugPrint("BetterFriendsFrame removed from UIPanelWindows")
		end
		
		-- Then disable attributes (false disables, nil doesn't work reliably)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-defined", false)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-enabled", false)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-area", "")
		BetterFriendsFrame:SetAttribute("UIPanelLayout-pushable", nil)
		BetterFriendsFrame:SetAttribute("UIPanelLayout-whileDead", false)
		BFL:DebugPrint("UI Panel Layout attributes disabled")
	end
end

-- Show the friends frame
-- tabIndex: Optional tab to show (1=Friends, 2=Who, 3=Raid, 4=Quick Join)
function ShowBetterFriendsFrame(tabIndex) -- Clear search box
	if BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.SearchBox then
		BetterFriendsFrame.FriendsTabHeader.SearchBox:SetText("")
		searchText = ""
	end
	
	-- Force immediate refresh to ensure mock invites are shown
	BFL:ForceRefreshFriendsList()
	
	-- Use UI Panel system if enabled (for auto-repositioning)
	-- Note: ShowUIPanel is protected in combat (since 8.2.0), fallback to Show()
	if BetterFriendlistDB and BetterFriendlistDB.useUIPanelSystem and not InCombatLockdown() then
		-- Configure UI Panel Layout attributes
		ConfigureUIPanelAttributes(true)
		ShowUIPanel(BetterFriendsFrame)
		BFL:DebugPrint("ShowUIPanel called")
	else
		-- Direct :Show() - combat-safe fallback
		-- Ensure attributes are disabled when not using UI Panel system
		ConfigureUIPanelAttributes(false)
		BetterFriendsFrame:Show()
	end
	
	-- Switch to requested tab if specified, otherwise default to current or 1
	local targetTab = tabIndex
	if not targetTab then
		targetTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
	end
	
	if targetTab >= 1 and targetTab <= 4 then
		-- BFL:DebugPrint("[BFL] ShowBetterFriendsFrame: Switching to tab " .. targetTab)
		PanelTemplates_SetTab(BetterFriendsFrame, targetTab)
		BetterFriendsFrame_ShowBottomTab(targetTab)
	end
end

-- Hide the friends frame  
function HideBetterFriendsFrame() -- Clear friend selection (like Blizzard's FriendsFrame)
	local FriendsList = GetFriendsList()
	if FriendsList then
		if FriendsList.selectedButton and FriendsList.selectedButton.selectionHighlight then
			FriendsList.selectedButton.selectionHighlight:Hide()
		end
		FriendsList.selectedFriend = nil
		FriendsList.selectedButton = nil
	end
	
	-- Use UI Panel system if enabled
	-- Note: HideUIPanel is protected in combat (since 8.2.0), fallback to Hide()
	if BetterFriendlistDB and BetterFriendlistDB.useUIPanelSystem and not InCombatLockdown() then
		HideUIPanel(BetterFriendsFrame)
	else
		-- Direct :Hide() - combat-safe fallback
		BetterFriendsFrame:Hide()
	end
end

-- Toggle the friends frame
-- tabIndex: Optional tab to show when opening (1=Friends, 2=Who, 3=Raid, 4=Quick Join)
function ToggleBetterFriendsFrame(tabIndex) -- BFL:DebugPrint("[BFL] ToggleBetterFriendsFrame() called - Frame shown: " .. tostring(BetterFriendsFrame:IsShown()) .. ", tabIndex: " .. tostring(tabIndex))
	
	if BetterFriendsFrame:IsShown() then
		-- If already shown and same tab (or no tab specified), close it
		-- If different tab requested, switch to that tab instead of closing
		if tabIndex and tabIndex >= 1 and tabIndex <= 4 then
			local currentTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
			if currentTab ~= tabIndex then
				-- BFL:DebugPrint("[BFL] Switching from tab " .. currentTab .. " to tab " .. tabIndex)
				PanelTemplates_SetTab(BetterFriendsFrame, tabIndex)
				BetterFriendsFrame_ShowBottomTab(tabIndex)
				return
			end
		end
		-- BFL:DebugPrint("[BFL] Hiding BetterFriendsFrame")
		HideBetterFriendsFrame()
	else
		-- BFL:DebugPrint("[BFL] Showing BetterFriendsFrame")
		ShowBetterFriendsFrame(tabIndex)
	end
end

-- Helper functions for child frame visibility
local function ShowChildFrame(childFrame) if not childFrame then return end
	childFrame:Show()
end

local function HideChildFrame(childFrame) if not childFrame then return end
	childFrame:Hide()
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...) if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == "BetterFriendlist" then
			-- Note: Version print is in Core.lua ADDON_LOADED handler (prevents duplicate)
		
		-- Initialize menu system
		InitializeMenuSystem()
		
		-- Load saved filter mode from database
		LoadFilterMode()
		
		-- Sync groups from module (if available)
		SyncGroups()
		
		-- Force initial friends list update (Classic: ensure list is populated on load)
		if BFL.IsClassic then
			local FriendsList = GetFriendsList()
			if FriendsList and FriendsList.UpdateFriendsList then
				-- BFL:DebugPrint("|cff00ffffADDON_LOADED:|r Scheduling initial Classic UpdateFriendsList")
				C_Timer.After(0.5, function() if FriendsList and FriendsList.UpdateFriendsList then
						FriendsList:UpdateFriendsList()
					end
				end)
			end
		end
		
		-- Initialize FriendsList module (sets up ScrollBox)
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.Initialize then
			FriendsList:Initialize()
		end			-- Initialize saved variables (fallback if modules not used)
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
		CloseSpecialWindows = function() local closedSomething = false
			
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
	
	-- Fix for "Copy Character Name" protected action error
	-- Replaces the protected Blizzard button with a safe BFL version in generic menus
	local function BFL_ReplaceCopyNameButton(owner, rootDescription, contextData, menuTypeWrapper)
		if not rootDescription or not rootDescription.EnumerateElementDescriptions then return end

		local targetText = COPY_CHARACTER_NAME -- Blizzard global string
		local foundAndReplaced = false
		
		-- Loop through all elements in the menu
		for _, elementDescription in rootDescription:EnumerateElementDescriptions() do
			-- Check text (handle function or string)
			local text = elementDescription.text
			if type(text) == "function" then 
				local success, result = pcall(text)
				if success then text = result end
			end
			
			-- Check for match: Text match OR Data match
			local isMatch = false
			
			-- Match by global string (localized) or fallback english
			if text and (text == targetText or text == "Copy Character Name" or (L and text == L.MENU_COPY_CHARACTER_NAME)) then
				isMatch = true
			-- Match by internal data key (Blizzard usually uses this for UnitPopup)
			elseif elementDescription.data == "COPY_CHARACTER_NAME" then
				isMatch = true
			end
			
			if isMatch then
				-- Hijack the click handler
				elementDescription:SetResponder(function()
					-- Resolve Name Lazy (at click time) for maximum accuracy
					local copyNameText = nil
					
					if contextData.bnetIDAccount then
						local accountInfo = C_BattleNet.GetAccountInfoByID(contextData.bnetIDAccount)
						if accountInfo then
							-- 1. Try Character Name (if in-game)
							if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName then
								local charName = accountInfo.gameAccountInfo.characterName
								local realmName = accountInfo.gameAccountInfo.realmName
								if realmName and realmName ~= "" then
									copyNameText = charName .. "-" .. realmName
								else
									copyNameText = charName
								end
							end
							
							-- 2. Try BattleTag (if Valid and Character Name failed, or as backup)
							if (not copyNameText or copyNameText == "") and accountInfo.battleTag then
								copyNameText = accountInfo.battleTag
							end
							
							-- 3. Try Real Name (Account Name) if nothing else
							if (not copyNameText or copyNameText == "") and accountInfo.accountName then
								copyNameText = accountInfo.accountName
							end
						end
					end
					
					-- 4. Fallback to contextData.name (Generic)
					if (not copyNameText or copyNameText == "") then
						if contextData.name then
							copyNameText = contextData.name
							-- Append server/realm if available and not already part of the name
							-- Generic check for contexts that might have server info (Recent Allies, Who, etc)
							if not string.find(copyNameText, "-") then
								if contextData.server and contextData.server ~= "" then
									copyNameText = copyNameText .. "-" .. contextData.server
								elseif contextData.realm and contextData.realm ~= "" then
									copyNameText = copyNameText .. "-" .. contextData.realm
								end
							end
						end
						
						-- Special handling for Who List (needs wrapper identification to use whoIndex)
						if menuTypeWrapper == "WHO" and (contextData.index or contextData.whoIndex) then
							local index = contextData.whoIndex or contextData.index
							local info = C_FriendList.GetWhoInfo(index)
							if info and info.fullName then
								copyNameText = info.fullName
							end
						end
					end

					StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
						text = L.COPY_CHARACTER_NAME_POPUP_TITLE,
						button1 = CLOSE,
						hasEditBox = true,
						editBoxWidth = 350,
						OnShow = function(self)
							self.EditBox:SetText(copyNameText or "")
							self.EditBox:SetFocus()
							self.EditBox:HighlightText()
							self.EditBox:SetScript("OnKeyUp", function(editBox, key)
								if IsControlKeyDown() and key == "C" then
									editBox:GetParent():Hide()
								end
							end)
						end,
						EditBoxOnEnterPressed = function(self)
							self:GetParent():Hide()
						end,
						EditBoxOnEscapePressed = function(self)
							self:GetParent():Hide()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
				end)
				
				-- Update text to our localized version if available
				if L and L.MENU_COPY_CHARACTER_NAME and elementDescription.SetText then
					elementDescription:SetText(L.MENU_COPY_CHARACTER_NAME)
				end
				
				foundAndReplaced = true
				-- break -- Don't break, in case of duplicates
			end
		end
		-- Re-add "Create if missing" logic? 
		-- No, if Blizzard hides the button (e.g. unknown generic unit), we probably shouldn't force it unless we know we have data.
		-- But for BNet friends, we now support BattleTag/RealName fallback, so maybe we COULD add it if missing?
		-- For now, sticking to "Replace Existing" to fix the crash.
	end

	local function AddGroupsToFriendMenu(owner, rootDescription, contextData) -- Check and reset flag in one atomic operation
		local isOurMenu = _G.BetterFriendlist_IsOurMenu
		_G.BetterFriendlist_IsOurMenu = false
		
	-- BFL:DebugPrint("|cff00ffffBFL AddGroupsToFriendMenu called. Flag was:", isOurMenu)
		if not isOurMenu then
			-- BFL:DebugPrint("|cffff0000BFL: Skipping menu entries (flag was false)")
			return
		end
		-- BFL:DebugPrint("|cff00ff00BFL: Adding menu entries (flag was true)")
		
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
		
		-- PHASE 15 FIX: Try to resolve UID via FriendsList module first
		-- This ensures 100% consistency with the list display (which works correctly)
		local FriendsList = GetFriendsList()
		if FriendsList and FriendsList.friendsList then
			if contextData.bnetIDAccount then
				-- Find BNet friend
				for _, friend in ipairs(FriendsList.friendsList) do
					if friend.type == "bnet" and friend.bnetAccountID == contextData.bnetIDAccount then
						friendUID = FriendsList:GetFriendUID(friend)
						-- BFL:DebugPrint("Resolved BNet UID via FriendsList:", friendUID)
						break
					end
				end
			elseif contextData.index then
				-- Find WoW friend by index
				for _, friend in ipairs(FriendsList.friendsList) do
					if friend.type == "wow" and friend.index == contextData.index then
						friendUID = FriendsList:GetFriendUID(friend)
						-- BFL:DebugPrint("Resolved WoW UID via FriendsList:", friendUID)
						break
					end
				end
			end
		end
		
		-- Fallback if not resolved via module
		if not friendUID then
			if contextData.bnetIDAccount then
				-- For BNet friends, we need to look up the battleTag
				local numBNet = BNGetNumFriends()
				for i = 1, numBNet do
					local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
					if accountInfo and accountInfo.bnetAccountID == contextData.bnetIDAccount then
						if accountInfo.battleTag then
							friendUID = "bnet_" .. accountInfo.battleTag
						else
							-- BFL:DebugPrint("|cffff0000BetterFriendlist Warning:|r BNet friend without battleTag, using bnetAccountID")
							friendUID = "bnet_" .. tostring(contextData.bnetIDAccount)
						end
						break
					end
				end
				
				-- If not found in friends list (shouldn't happen), fallback to bnetAccountID
				if not friendUID then
					-- BFL:DebugPrint("|cffff0000BetterFriendlist Warning:|r Could not find BNet friend, using bnetAccountID")
					friendUID = "bnet_" .. tostring(contextData.bnetIDAccount)
				end
			elseif contextData.name then
				-- Normalize name to ensure it matches the format used in FriendsList module (Name-Realm)
				local normalized = BFL:NormalizeWoWFriendName(contextData.name)
				friendUID = "wow_" .. (normalized or contextData.name)
			end
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
		
		-- Add divider and Header
		rootDescription:CreateDivider()
		rootDescription:CreateTitle(L.MENU_TITLE)

		-- Add "Set Nickname" button
		rootDescription:CreateButton(L.MENU_SET_NICKNAME, function() local DB = BFL:GetModule("DB")
			local currentNickname = DB and DB:GetNickname(friendUID)
			
			-- Use contextData.name for display, fallback to battleTag if available
			local displayName = contextData.name
			if not displayName and contextData.battleTag then
				displayName = contextData.battleTag
			end
			
			StaticPopup_Show("BETTER_FRIENDLIST_SET_NICKNAME", displayName or "Friend", nil, {
				uid = friendUID,
				nickname = currentNickname
			})
		end)

		-- Copy Character Name option
		local copyNameText = nil
		if contextData.bnetIDAccount then
			local accountInfo = C_BattleNet.GetAccountInfoByID(contextData.bnetIDAccount)
			if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName then
				local charName = accountInfo.gameAccountInfo.characterName
				local realmName = accountInfo.gameAccountInfo.realmName
				if realmName and realmName ~= "" then
					copyNameText = charName .. "-" .. realmName
				else
					copyNameText = charName
				end
			end
		elseif contextData.name then
			copyNameText = contextData.name
		end
		
		if copyNameText then
			-- Fixed Logic: Find the existing broken button/option and hijacked it, or create new if missing
			local foundAndReplaced = false
			local targetText = COPY_CHARACTER_NAME or "Copy Character Name"
			
			for _, elementDescription in rootDescription:EnumerateElementDescriptions() do
				-- Check text (handle both string and function)
				local text = elementDescription.text
				if type(text) == "function" then 
					local success, result = pcall(text)
					if success then text = result end
				end
				
				-- Check for match: Text match OR Data match (Bit safer for UnitPopup)
				local isMatch = false
				
				if text and (text == targetText or (L and text == L.MENU_COPY_CHARACTER_NAME)) then
					isMatch = true
				elseif elementDescription.data == "COPY_CHARACTER_NAME" then
					isMatch = true
				end
				
				if isMatch then
					-- Found the Blizzard button (or a duplicate). Overwrite its responder to use ours.
					elementDescription:SetResponder(function()
						StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
							text = L.COPY_CHARACTER_NAME_POPUP_TITLE,
							button1 = "Close",
							hasEditBox = true,
							editBoxWidth = 350,
							OnShow = function(self)
								self.EditBox:SetText(copyNameText)
								self.EditBox:SetFocus()
								self.EditBox:HighlightText()
								self.EditBox:SetScript("OnKeyUp", function(editBox, key)
									if IsControlKeyDown() and key == "C" then
										editBox:GetParent():Hide()
									end
								end)
							end,
							EditBoxOnEnterPressed = function(self)
								self:GetParent():Hide()
							end,
							EditBoxOnEscapePressed = function(self)
								self:GetParent():Hide()
							end,
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}
						StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
					end)
					
					-- Force update text to indicate we took over (and fixing visual string)
					if L and L.MENU_COPY_CHARACTER_NAME then
						elementDescription:SetText(L.MENU_COPY_CHARACTER_NAME)
					end
					
					foundAndReplaced = true
					-- Do not break loop; in case Blizzard added it multiple times (rare) or we want to catch all instances
				end
			end

			if not foundAndReplaced then
				rootDescription:CreateButton(L.MENU_COPY_CHARACTER_NAME, function()
					StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
						text = L.COPY_CHARACTER_NAME_POPUP_TITLE,
						button1 = "Close",
						hasEditBox = true,
						editBoxWidth = 350,
						OnShow = function(self)
							self.EditBox:SetText(copyNameText)
							self.EditBox:SetFocus()
							self.EditBox:HighlightText()
							self.EditBox:SetScript("OnKeyUp", function(editBox, key)
								if IsControlKeyDown() and key == "C" then
									editBox:GetParent():Hide()
								end
							end)
						end,
						EditBoxOnEnterPressed = function(self)
							self:GetParent():Hide()
						end,
						EditBoxOnEscapePressed = function(self)
							self:GetParent():Hide()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
				end)
			end
		end

		local groupsButton = rootDescription:CreateButton(L.MENU_GROUPS)
		
		-- Enable scrolling for the groups submenu (User requested scrolling instead of dialog)
		if groupsButton.SetScrollMode then
			groupsButton:SetScrollMode(300) -- 300px limit before scrolling
		end
		
		-- Add "Create Group" option at the top
		groupsButton:CreateButton(L.MENU_CREATE_GROUP, function() StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND", nil, nil, friendUID)
		end)

		-- Add "Remove from All Groups" button immediately after Create Group (User request)
		if next(friendCurrentGroups) then
			-- Add "Remove from All Groups" button
			local Groups = GetGroups()
			groupsButton:CreateButton(L.MENU_REMOVE_ALL_GROUPS, function() if Groups then
					for currentGroupId in pairs(friendCurrentGroups) do
						Groups:RemoveFriendFromGroup(friendUID, currentGroupId)
					end
					-- Force full display refresh - group membership affects display structure
					BFL:ForceRefreshFriendsList()
				end
			end)
		end
		
		-- Get fresh groups list directly from module (bypass stale local cache)
		local Groups = GetGroups()
		local friendGroups = Groups and Groups:GetAll() or {}
		
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
					function() -- Read state dynamically from DB each time checkbox is rendered
						if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
							for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
								if gid == groupId then
									return true
								end
							end
						end
						return false
					end,
					function() local Groups = GetGroups()
						if Groups then
							Groups:ToggleFriendInGroup(friendUID, groupId)
							-- Force full display refresh - group membership affects display structure
							BFL:ForceRefreshFriendsList()
						end
					end
				)
			end			-- End of group checkboxes
		end
	end
		
		-- Register for BattleNet friend menus (online and offline)
		if Menu and Menu.ModifyMenu then
			-- Fix "Copy Character Name" button (Must be registered BEFORE AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", BFL_ReplaceCopyNameButton)
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND_OFFLINE", BFL_ReplaceCopyNameButton)
			Menu.ModifyMenu("MENU_UNIT_FRIEND", BFL_ReplaceCopyNameButton)
			Menu.ModifyMenu("MENU_UNIT_FRIEND_OFFLINE", BFL_ReplaceCopyNameButton)
			Menu.ModifyMenu("MENU_UNIT_RAF_RECRUIT", BFL_ReplaceCopyNameButton)
			
			-- Pass context wrapper for Recent Allies and Who list to handle Realm Name retrieval
			Menu.ModifyMenu("MENU_UNIT_RECENT_ALLY", function(owner, root, context) BFL_ReplaceCopyNameButton(owner, root, context, "RECENT") end)
			Menu.ModifyMenu("MENU_UNIT_RECENT_ALLY_OFFLINE", function(owner, root, context) BFL_ReplaceCopyNameButton(owner, root, context, "RECENT") end)
			Menu.ModifyMenu("MENU_UNIT_WHO", function(owner, root, context) BFL_ReplaceCopyNameButton(owner, root, context, "WHO") end)

			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND_OFFLINE", AddGroupsToFriendMenu)
			
			-- Register for WoW friend menus (online and offline)
			Menu.ModifyMenu("MENU_UNIT_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_FRIEND_OFFLINE", AddGroupsToFriendMenu)
		end
		
		-- DEPRECATED: Old Menu.ModifyMenu code removed (was using wrong tags without MENU_UNIT_ prefix)
		
		-- ScrollBox initialization is now handled by FriendsList:InitializeScrollBox()
		-- No need for OnVerticalScroll script - ScrollBox handles this automatically
		
		-- Setup close button
		if BetterFriendsFrame and BetterFriendsFrame.CloseButton then
			BetterFriendsFrame.CloseButton:SetScript("OnClick", function() HideBetterFriendsFrame()
			end)
		end
		
if BFL.IsClassic and BetterFriendsFrame then
			-- Classic has 4 main tabs: Friends(1), Who(2), Guild(3), Raid(4)
			
			local hideGuildTab = BetterFriendlistDB and BetterFriendlistDB.hideGuildTab
			
			-- TAB 3: Change "Raid" to "Guild" (unless user wants it hidden)
			if BetterFriendsFrame.BottomTab3 then
				-- Check if user wants to hide Guild tab
				if hideGuildTab then
					BetterFriendsFrame.BottomTab3:Hide()
				else
				-- Show and restore Guild tab
				BetterFriendsFrame.BottomTab3:Show()
				BetterFriendsFrame.BottomTab3:SetText(GUILD or "Guild")
				BetterFriendsFrame.BottomTab3:SetScript("OnClick", function(self) -- Guild Tab: Open Blizzard Guild Frame, return to Friends tab, close BFL
					BetterFriendsFrame_HandleGuildTabClick()
				end)
			end
		end

		-- TAB 4: Create "Raid" tab (was Guild)
		if not BetterFriendsFrame.BottomTab4 then
			local tab = CreateFrame("Button", "BetterFriendsFrameBottomTab4", BetterFriendsFrame, "CharacterFrameTabButtonTemplate")
			tab:SetID(4)
			tab:SetText(RAID or "Raid")
			tab:SetFrameStrata("LOW")
			tab:SetScript("OnClick", function(self) PanelTemplates_Tab_OnClick(self, BetterFriendsFrame)
				BetterFriendsFrame_ShowBottomTab(4)
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			end)
			BetterFriendsFrame.BottomTab4 = tab
		end
		
		-- Update Tab 4 position based on hideGuildTab setting
		if BetterFriendsFrame.BottomTab4 then
			BetterFriendsFrame.BottomTab4:ClearAllPoints()
			if hideGuildTab then
				BetterFriendsFrame.BottomTab4:SetPoint("LEFT", BetterFriendsFrame.BottomTab2, "RIGHT", -15, 0)
			else
				BetterFriendsFrame.BottomTab4:SetPoint("LEFT", BetterFriendsFrame.BottomTab3, "RIGHT", -15, 0)
			end
		end
			
			-- Setup Tabs Registry for PanelTemplates
			BetterFriendsFrame.Tabs = {
				BetterFriendsFrame.BottomTab1,
				BetterFriendsFrame.BottomTab2,
				BetterFriendsFrame.BottomTab3,
				BetterFriendsFrame.BottomTab4
			}
			
			-- Enable 4 Tabs
			PanelTemplates_SetNumTabs(BetterFriendsFrame, 4)
			PanelTemplates_SetTab(BetterFriendsFrame, 1)
		end
	end
	elseif event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_LIST_SIZE_CHANGED" or 
	       event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" or
	       event == "BN_FRIEND_INFO_CHANGED" then
		-- Fire callbacks for modules
		BFL:FireEventCallbacks(event, ...)
		
		-- CRITICAL (Phase 14d): Always update friend list data, even if UI is hidden
		-- This ensures data stays synchronized with WoW API
		-- The UpdateFriendsList() function will apply search filter automatically
		RequestUpdate() -- No longer checks if frame is shown
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
		
		-- Close all active Contacts Menus (forces refresh with combat icon on reopen)
		for i = #_G.BFL_ActiveContactsMenus, 1, -1 do
			local menu = _G.BFL_ActiveContactsMenus[i]
			if menu and menu:IsShown() then
				menu:Hide()
			end
		end
		-- Clean up closed menus
		for i = #_G.BFL_ActiveContactsMenus, 1, -1 do
			local menu = _G.BFL_ActiveContactsMenus[i]
			if not menu or not menu:IsShown() then
				table.remove(_G.BFL_ActiveContactsMenus, i)
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Leaving combat - update combat overlay on all raid buttons
		BetterRaidFrame_UpdateCombatOverlay(false)
		
		-- Close all active Contacts Menus (forces refresh without combat icon on reopen)
		for i = #_G.BFL_ActiveContactsMenus, 1, -1 do
			local menu = _G.BFL_ActiveContactsMenus[i]
			if menu and menu:IsShown() then
				menu:Hide()
			end
		end
		-- Clean up closed menus
		for i = #_G.BFL_ActiveContactsMenus, 1, -1 do
			local menu = _G.BFL_ActiveContactsMenus[i]
			if not menu or not menu:IsShown() then
				table.remove(_G.BFL_ActiveContactsMenus, i)
			end
		end
	elseif event == "WHO_LIST_UPDATE" then
		-- Fire callbacks for modules
		BFL:FireEventCallbacks(event, ...)
		
		-- Update Who list when results are received
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() and BetterFriendsFrame.WhoFrame:IsShown() then
			BetterWhoFrame_Update()
		end
	elseif event == "PLAYER_LOGIN" then
		-- Localize UI Elements (replacing hardcoded XML text)
		LocalizeUI()

		-- Classic: Auto-disable useClassicGuildUI CVar on every login
		-- This ensures the setting persists across game restarts
		if BFL.IsClassic then
			local useClassicGuildUI = GetCVar("useClassicGuildUI")
			if useClassicGuildUI == "1" then
				SetCVar("useClassicGuildUI", "0")
				
				-- Show warning popup only on first detection
				if not BetterFriendlistDB.classicGuildUIWarningShown then
					BetterFriendlistDB.classicGuildUIWarningShown = true
					
					-- Define popup dialog
					StaticPopupDialogs["BFL_CLASSIC_GUILD_UI_WARNING"] = {
						text = (BFL.L.CLASSIC_GUILD_UI_WARNING_TITLE or "Classic Guild UI Disabled") .. "\n\n" .. (BFL.L.CLASSIC_GUILD_UI_WARNING_TEXT or "BetterFriendlist has disabled the 'Use Classic Guild UI' setting for proper integration.\n\nThe Guild tab now opens Blizzard's Guild Frame instead of showing it within BetterFriendlist."),
						button1 = OKAY,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = STATICPOPUP_NUMDIALOGS,
					}
					
					C_Timer.After(1, function() StaticPopup_Show("BFL_CLASSIC_GUILD_UI_WARNING")
					end)
				end
			end
		end
		
		-- Override Close Button to use our Hide function
		if BetterFriendsFrame.CloseButton then
			BetterFriendsFrame.CloseButton:SetScript("OnClick", function() HideBetterFriendsFrame()
			end)
		end
		
		-- Initialize UI components (delegated to FrameInitializer)
		if BFL.FrameInitializer and BetterFriendsFrame then
			BFL.FrameInitializer:Initialize(BetterFriendsFrame)
		end
		
		-- Initialize Quick Join tab counter
		BetterFriendsFrame_UpdateQuickJoinTab()
		
		-- Initialize Quick Filter Buttons
		C_Timer.After(0.5, function() if BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.QuickFilters then
				BetterFriendsFrame_UpdateQuickFilterButtons()
			end
		end)
		
		-- Setup automatic keybind override (like BetterBags)
		-- BFL:DebugPrint("[BFL] Setting up keybind override system...")
		BFL.bindingFrame = BFL.bindingFrame or CreateFrame("Frame")
		BFL.bindingFrame:RegisterEvent("PLAYER_LOGIN")
		BFL.bindingFrame:RegisterEvent("UPDATE_BINDINGS")
		BFL.bindingFrame:SetScript("OnEvent", function(self, event, ...) -- BFL:DebugPrint("[BFL] Event received: " .. event)
			BFL_CheckKeyBindings()
		end)
		
		-- Trigger initial check after a short delay
		C_Timer.After(1, function() -- BFL:DebugPrint("[BFL] Running initial keybind check...")
			BFL_CheckKeyBindings()
		end)
	end
end)

-- Automatic Keybind Override System (like BetterBags)
-- Intercepts the default O-key and redirects it to our frame
function BFL_CheckKeyBindings() -- BFL:DebugPrint("[BFL] CheckKeyBindings called")
	
	if InCombatLockdown() then
		-- BFL:DebugPrint("[BFL] In combat, delaying keybind check")
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
	
	-- BFL:DebugPrint("[BFL] Checking " .. #bindings .. " binding names...")
	
	for _, binding in pairs(bindings) do
		local key, otherkey = GetBindingKey(binding)
		-- BFL:DebugPrint("[BFL] Binding '" .. binding .. "': key1=" .. tostring(key) .. ", key2=" .. tostring(otherkey))
		
		if key ~= nil then
			SetOverrideBinding(BFL.bindingFrame, true, key, "BETTERFRIENDLIST_TOGGLE")
			-- BFL:DebugPrint("[BFL] Override set: " .. key .. " -> BETTERFRIENDLIST_TOGGLE")
		end
		if otherkey ~= nil then
			SetOverrideBinding(BFL.bindingFrame, true, otherkey, "BETTERFRIENDLIST_TOGGLE")
			-- BFL:DebugPrint("[BFL] Override set: " .. otherkey .. " -> BETTERFRIENDLIST_TOGGLE")
		end
	end
	
	-- BFL:DebugPrint("[BFL] Keybind override complete")
end

-- Slash Commands are now in Core.lua
-- This avoids loading order conflicts

-- Show specific tab content (11.2.5: 4 tabs - Friends, Recent Allies, RAF, Sort)
-- In Classic: Only tab 1 (Friends) is available
function BetterFriendsFrame_ShowTab(tabIndex) local frame = BetterFriendsFrame
	if not frame then return end

	-- SEARCHBOX VISIBILITY IS NOW MANAGED ENTIRELY BY FriendsList:UpdateScrollBoxExtent()
	-- We force a layout update immediately if switching to Tab 1 to ensure SearchBox appears instantly
	if tabIndex == 1 then
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.UpdateScrollBoxExtent then
			FriendsList:UpdateScrollBoxExtent()
		end
	else
		-- If switching away from Tab 1
		local searchBox = frame.FriendsTabHeader and frame.FriendsTabHeader.SearchBox
		
		-- Fix: Only hide if in Simple Mode (where it is inside the list view)
		-- In Normal Mode, searchBox is in the header and should remain visible for sub-tabs
		local DB = BFL:GetModule("DB")
		local simpleMode = DB and DB:Get("simpleMode", false)
		
		if simpleMode then
			if searchBox then searchBox:Hide() end
		else
			if searchBox then searchBox:Show() end
		end
	end

	-- FORCE FONT UPDATE: Ensure Custom Fonts win against ElvUI
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameTab" .. i]
		if tab then
			-- Ensure fonts are strictly enforcing BetterFriendlist style
			-- Use Small font (10pt) to match Bottom Tabs (and standard Blizzard tabs)
			tab:SetNormalFontObject("BetterFriendlistFontNormalSmall")
			tab:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
			tab:SetDisabledFontObject("BetterFriendlistFontHighlightSmall")
			
			if i == tabIndex then
				-- Re-enforce selection state visually just to be safe
				PanelTemplates_SelectTab(tab)
				local fs = tab:GetFontString()
				if fs then
					fs:SetFontObject("BetterFriendlistFontHighlightSmall")
				end
			else
				PanelTemplates_DeselectTab(tab)
			end
		end
	end
	
	-- Use hybrid helper functions for all child frames
	HideChildFrame(frame.SortFrame)
	HideChildFrame(frame.RecentAlliesFrame)
	HideChildFrame(frame.RecruitAFriendFrame)
	HideChildFrame(frame.ScrollFrame)
	HideChildFrame(frame.MinimalScrollBar)
	HideChildFrame(frame.AddFriendButton)
	HideChildFrame(frame.SendMessageButton)
	HideChildFrame(frame.RecruitmentButton)
	
	-- Additional Classic frames
	HideChildFrame(frame.WhoFrame)
	if BFL.IsClassic and frame.RaidFrame then
		HideChildFrame(frame.RaidFrame)
	end

	if tabIndex == 1 then
		-- Show Friends list
		ShowChildFrame(frame.ScrollFrame)
		ShowChildFrame(frame.MinimalScrollBar)
		ShowChildFrame(frame.AddFriendButton)
		ShowChildFrame(frame.SendMessageButton)
		UpdateFriendsDisplay()
	elseif tabIndex == 2 then
		-- Retail: Recent Allies
		if not BFL.IsClassic and frame.RecentAlliesFrame then
			ShowChildFrame(frame.RecentAlliesFrame)
			local RecentAllies = BFL:GetModule("RecentAllies")
			if RecentAllies then
				RecentAllies:Refresh(frame.RecentAlliesFrame, ScrollBoxConstants.RetainScrollPosition)
			end
		-- Classic: Who Frame
		elseif BFL.IsClassic and frame.WhoFrame then
			ShowChildFrame(frame.WhoFrame)
			BetterWhoFrame_Update()
		end
	elseif tabIndex == 3 then
		-- Retail: Recruit A Friend
		-- Check IsEnabled() as requested
		local rafEnabled = C_RecruitAFriend and C_RecruitAFriend.IsEnabled and C_RecruitAFriend.IsEnabled()
		if not BFL.IsClassic and frame.RecruitAFriendFrame and rafEnabled then
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
		-- Retail: Sort options
		if not BFL.IsClassic then
			-- Show Sort options (11.2.5: restored from dropdown to tab)
			ShowChildFrame(frame.SortFrame)
		-- Classic: Raid Frame
		else
			if frame.RaidFrame then
				ShowChildFrame(frame.RaidFrame)
			end
		end
	end
end

-- Set sort method and update display
function BetterFriendlist_SetSortMethod(method) if not method then return end
	
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
		status = L.SORT_STATUS,
		name = L.SORT_NAME,
		level = L.SORT_LEVEL,
		zone = L.SORT_ZONE
	}
	print("|cff00ff00BetterFriendlist:|r " .. string.format(L.SORT_CHANGED, (methodNames[method] or method)))
end

-- Update Quick Join tab with group count (matching Blizzard's FriendsFrame_UpdateQuickJoinTab)
function BetterFriendsFrame_UpdateQuickJoinTab() -- Quick Join is Retail only
	if BFL.IsClassic then return end

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
	
	-- Resize tab to fit text (matching ApplyTabFonts parameters: padding=20, minWidth=80)
	PanelTemplates_TabResize(frame.BottomTab4, 20, nil, 80)
end

--------------------------------------------------------------------------
-- TRAVEL PASS BUTTON HANDLERS
--------------------------------------------------------------------------

local CLASS_ID_TO_GAME_MODE = {
	[14] = Enum.GameMode.Plunderstorm,
	[15] = Enum.GameMode.WoWHack,
}

local function CanInviteByGameMode(gameAccountInfo)
	if not C_GameRules or not C_GameRules.GetActiveGameMode then return true end
	
	local otherGameMode = CLASS_ID_TO_GAME_MODE[gameAccountInfo.classID]
	local activeGameMode = C_GameRules.GetActiveGameMode()
	
	if otherGameMode then
		return otherGameMode == activeGameMode
	else
		-- If we're both in standard we can invite them.
		return activeGameMode == Enum.GameMode.Standard
	end
end

-- TravelPass Button Handlers
function BetterFriendsList_TravelPassButton_OnClick(self) local friendData = self.friendData
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

	-- USE BLIZZARD LOGIC (Retail)
	-- Fixes "Join" button not working (Request vs Invite) and Cross-Faction logic
	if FriendsFrame_InviteOrRequestToJoin and FriendsFrame_SetupTravelPassDropdown then
		-- Check Valid Game Accounts (Ported from FriendsFrame.lua)
		local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualIndex)
		local numValidGameAccounts = 0
		local lastGameAccountID, lastGameAccountGUID
		local playerFactionGroup = UnitFactionGroup("player")
		local playerRealmID = GetRealmID()
		local WOW_PROJECT_ID = WOW_PROJECT_ID
		
		for i = 1, numGameAccounts do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, i)
			local isValid = true
			
			-- Basic checks
			if gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then isValid = false end
			if gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then isValid = false end
			if gameAccountInfo.realmID == 0 then isValid = false end
			if not gameAccountInfo.isInCurrentRegion then isValid = false end
			
			-- Cross-faction checks
			if isValid and gameAccountInfo.factionName ~= playerFactionGroup then
				if C_QuestSession and C_QuestSession.Exists() then
					isValid = false
				elseif C_PartyInfo and C_PartyInfo.CanFormCrossFactionParties and not C_PartyInfo.CanFormCrossFactionParties() then
					isValid = false
				end
			end
			
			-- Game Mode Check
			if isValid and not CanInviteByGameMode(gameAccountInfo) then
				isValid = false
			end
			
			if isValid then
				numValidGameAccounts = numValidGameAccounts + 1
				lastGameAccountID = gameAccountInfo.gameAccountID
				lastGameAccountGUID = gameAccountInfo.playerGuid
			end
		end
		
		if numValidGameAccounts == 1 then
			-- Single valid account: Auto-Invite or Request Join
			FriendsFrame_InviteOrRequestToJoin(lastGameAccountGUID, lastGameAccountID)
		else
			-- Multiple valid (or 0 valid): Show Dropdown
			-- Blizzard's dropdown logic handles the "0 valid" case by showing disabled buttons
			FriendsFrame_SetupTravelPassDropdown(actualIndex, self)
		end
		return
	end
	
	-- CLASSIC FALLBACK (Legacy Logic)
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

local inviteTypeToButtonText = {
	["INVITE"] = TRAVEL_PASS_INVITE,
	["SUGGEST_INVITE"] = SUGGEST_INVITE,
	["REQUEST_INVITE"] = REQUEST_INVITE,
	["INVITE_CROSS_FACTION"] = TRAVEL_PASS_INVITE_CROSS_FACTION,
	["SUGGEST_INVITE_CROSS_FACTION"] = SUGGEST_INVITE,
	["REQUEST_INVITE_CROSS_FACTION"] = REQUEST_INVITE,
}

local inviteTypeIsCrossFaction = {
	["INVITE_CROSS_FACTION"] = true,
	["SUGGEST_INVITE_CROSS_FACTION"] = true,
	["REQUEST_INVITE_CROSS_FACTION"] = true,
}

local FACTION_LABELS_FROM_STRING = {
	["Alliance"] = FACTION_ALLIANCE,
	["Horde"] = FACTION_HORDE,
}

function BetterFriendsList_TravelPassButton_OnEnter(self) local friendData = self.friendData
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
	
	-- USE BLIZZARD LOGIC (Retail 11.0+)
	if FriendsFrame_GetDisplayedInviteTypeAndGuid and FriendsFrame_GetInviteRestriction and FriendsFrame_GetInviteRestrictionText then
		local inviteType, guid, factionName = FriendsFrame_GetDisplayedInviteTypeAndGuid(actualIndex)
		local restriction = FriendsFrame_GetInviteRestriction(actualIndex)
		
		if inviteType and inviteTypeToButtonText[inviteType] then
			GameTooltip:SetText(inviteTypeToButtonText[inviteType], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			
			if inviteTypeIsCrossFaction[inviteType] and factionName then
				local factionLabel = FACTION_LABELS_FROM_STRING[factionName] or (factionName == "Horde" and FACTION_HORDE or FACTION_ALLIANCE)
				if CROSS_FACTION_INVITE_TOOLTIP then
					GameTooltip:AddLine(CROSS_FACTION_INVITE_TOOLTIP:format(factionLabel), nil, nil, nil, true)
				end
			end
			
			if restriction == INVITE_RESTRICTION_NONE then
				if (inviteType == "REQUEST_INVITE" or inviteType == "REQUEST_INVITE_CROSS_FACTION") and C_SocialQueue then
					-- Show who is in the group (Social Queue)
					local group = C_SocialQueue.GetGroupForPlayer(guid)
					local members = C_SocialQueue.GetGroupMembers(group)
					local numDisplayed = 0
					if members then
						for i=1, #members do
							if members[i].guid ~= guid then
								if numDisplayed == 0 then
									GameTooltip:AddLine(SOCIAL_QUEUE_ALSO_IN_GROUP)
								elseif numDisplayed >= 7 then
									GameTooltip:AddLine(SOCIAL_QUEUE_AND_MORE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1)
									break
								end
								
								local name, color = SocialQueueUtil_GetRelationshipInfo(members[i].guid, nil, members[i].clubId)
								GameTooltip:AddLine(color..name..FONT_COLOR_CODE_CLOSE)
								numDisplayed = numDisplayed + 1
							end
						end
					end
				end
			else
				GameTooltip:AddLine(FriendsFrame_GetInviteRestrictionText(restriction), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
			end
			
			GameTooltip:Show()
			return
		end
	end
	
	-- CLASSIC FALLBACK (Legacy Logic)
	-- Check for invite restrictions (matching Blizzard's Check code)
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
			restrictionText = ERR_TRAVEL_PASS_NOT_WOW or L.TRAVEL_PASS_NOT_WOW
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_CLASSIC then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_CLASSIC_OVERRIDE or L.TRAVEL_PASS_WOW_CLASSIC
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_MAINLINE then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_MAINLINE_OVERRIDE or L.TRAVEL_PASS_WOW_MAINLINE
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_ID then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT or L.TRAVEL_PASS_DIFFERENT_VERSION
		elseif restriction == INVITE_RESTRICTION_INFO then
			restrictionText = ERR_TRAVEL_PASS_NO_INFO or L.TRAVEL_PASS_NO_INFO
		elseif restriction == INVITE_RESTRICTION_REGION then
			restrictionText = ERR_TRAVEL_PASS_DIFFERENT_REGION or L.TRAVEL_PASS_DIFFERENT_REGION
		elseif restriction == INVITE_RESTRICTION_NO_GAME_ACCOUNTS then
			restrictionText = L.TRAVEL_PASS_NO_GAME_ACCOUNTS
		end
		
		if restrictionText ~= "" then
			GameTooltip:AddLine(restrictionText, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		end
	end
	
	GameTooltip:Show()
end

-- Friend List Button OnEnter (tooltip)
function BetterFriendsList_Button_OnEnter(button) if not button.friendData then return end
	
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
		
		-- Determine friend UID based on friend type (matching FriendsList structure)
		if friend.type == "bnet" and friend.battleTag then
			-- Battle.net friend - use battleTag
			friendUID = "bnet_" .. friend.battleTag
		elseif friend.type == "wow" and friend.name then
			-- WoW friend - use character name
			friendUID = "wow_" .. friend.name
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

-- Button OnClick Handler (matching Blizzard's FriendsFrame_SelectFriend behavior)
function BetterFriendsList_Button_OnClick(button, mouseButton)
	if not button.friendData then
		return
	end
	
	if mouseButton == "LeftButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		-- Left click: Select friend (for Send Message button) with visual highlight
		local FriendsList = GetFriendsList()
		if FriendsList and button.friendData then
			-- Clear previous selection highlight
			if FriendsList.selectedButton and FriendsList.selectedButton.selectionHighlight then
				FriendsList.selectedButton.selectionHighlight:Hide()
			end
			
			-- Set new selection
			FriendsList.selectedFriend = button.friendData
			FriendsList.selectedButton = button
			
			-- Show selection highlight (blue, like Blizzard)
			if button.selectionHighlight then
				button.selectionHighlight:Show()
			end
			
			-- Update Send Message button state
			if FriendsList.UpdateSendMessageButton then
				FriendsList:UpdateSendMessageButton()
			end
		end
	elseif mouseButton == "RightButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		
		local friendData = button.friendData
		
		if friendData.type == "bnet" then
			-- BattleNet friend context menu
			-- FIXED: Use bnetAccountID instead of index to avoid stale data issues
			local accountInfo = friendData.bnetAccountID and C_BattleNet.GetAccountInfoByID(friendData.bnetAccountID) or nil
			if accountInfo then
				BetterFriendsList_ShowBNDropdown(
					accountInfo.accountName,
					accountInfo.gameAccountInfo.isOnline,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					true, -- showMenuFlag (Pass TRUE to force menu show, NOT friendsList index)
					accountInfo.bnetAccountID,
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					accountInfo.battleTag,
					friendData.index
				)
			end
		else
			-- WoW friend context menu
			-- FIXED: Use index instead of guid (guid is not stored in friend data)
			local info = C_FriendList.GetFriendInfoByIndex(friendData.index)
			if info then
				BetterFriendsList_ShowDropdown(
					info.name,
					info.connected,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					friendData.index, -- friendsList (Pass INDEX here, not true)
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					info.guid,
					friendData.index
				)
			end
		end
	end
end

-- Show WoW Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowDropdown(name, connected, lineID, chatType, chatFrame, friendsList, communityClubID, communityStreamID, communityEpoch, communityPosition, guid, index) -- Ensure friendsList is a number (index) if possible
	local actualIndex = index
	if not actualIndex and type(friendsList) == "number" then
		actualIndex = friendsList
	end

	if connected or friendsList then
		local contextData = {
			name = name,
			friendsList = actualIndex, -- RIO Fix: Pass index if available (MUST be number or nil)
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
			uid = name, -- For Nickname (WoW friends use name as UID)
			index = actualIndex, -- Required for some addons (e.g. RaiderIO)
			friendsIndex = actualIndex, -- Alternative name used by Blizzard
		}
		
		-- Set flag BEFORE opening menu (menu modifiers run during UnitPopup_OpenMenu)
		_G.BetterFriendlist_IsOurMenu = true
		
		-- Determine menu type based on online status
		local menuType = connected and "FRIEND" or "FRIEND_OFFLINE"
		-- Use compatibility wrapper for Classic support
		BFL.OpenContextMenu(nil, menuType, contextData, name)
	end
end

-- Show BattleNet Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowBNDropdown(name, connected, lineID, chatType, chatFrame, showMenuFlag, bnetIDAccount, communityClubID, communityStreamID, communityEpoch, communityPosition, battleTag, index) -- Ensure friendsList is a number (index) if possible
	local actualIndex = index
	if not actualIndex and type(showMenuFlag) == "number" then
		actualIndex = showMenuFlag
	end

	if connected or showMenuFlag then
		local contextData = {
			name = name,
			friendsList = showMenuFlag, -- Restored v2.0.0 behavior (was nil)
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
			uid = bnetIDAccount, -- For Nickname (BNet friends use bnetIDAccount as UID)
			index = actualIndex, -- Required for some addons
			friendsIndex = actualIndex, -- Alternative name
		}
		
		-- Set flag BEFORE opening menu (menu modifiers run during UnitPopup_OpenMenu)
		_G.BetterFriendlist_IsOurMenu = true
		
		-- Determine menu type based on online status
		local menuType = connected and "BN_FRIEND" or "BN_FRIEND_OFFLINE"
		
		-- Use compatibility wrapper for Classic support
		BFL.OpenContextMenu(nil, menuType, contextData, name)
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

-- Store active menu instance for combat closing (use global scope for persistence)
if not _G.BFL_ActiveContactsMenus then
	_G.BFL_ActiveContactsMenus = {}
end

-- Contacts Menu (11.2.5 - replaces broadcast button, includes ignore list)
-- Uses MenuUtil like Blizzard's ContactsMenuMixin
function BetterFriendsFrame_ShowContactsMenu(button) local generator = function(ownerRegion, rootDescription) rootDescription:SetTag("BFL_CONTACTS_MENU");
		
		-- Add BetterFriendList title
		rootDescription:CreateTitle(L.MENU_TITLE);

        -- Settings option
		rootDescription:CreateButton(L.MENU_SETTINGS, function() BetterFriendlistSettings_Show()
		end);
        
        rootDescription:CreateDivider();

		-- Simple Mode ONLY: Include "Quick Filter" and "Sort" menus here 
		local DB = GetDB()
		local simpleMode = DB and DB:Get("simpleMode", false) or false
		if simpleMode then
			-- Search Toggle
			local searchToggle = rootDescription:CreateCheckbox(
				L.MENU_SHOW_SEARCH or "Show Search",
				function() return DB and DB:Get("simpleModeShowSearch", true) end,
				function() 
					if DB then 
						local current = DB:Get("simpleModeShowSearch", true)
						DB:Set("simpleModeShowSearch", not current)
						BFL:ForceRefreshFriendsList()
					end
				end
			)
            
			-- Quick Filter Submenu
            local filterSubmenu = rootDescription:CreateButton(L.MENU_QUICK_FILTER or "Quick Filter")
            local QuickFilters = BFL:GetModule("QuickFilters")
            if QuickFilters and QuickFilters.PopulateMenu then
                QuickFilters:PopulateMenu(filterSubmenu)
            end

            -- Sort Submenu
            local sortSubmenu = rootDescription:CreateButton(L.Sort or "Sort")
            local FriendsList = BFL:GetModule("FriendsList")
            if FriendsList and FriendsList.PopulateSortMenu then
                 -- Primary Sort
                 local primarySort = sortSubmenu:CreateButton("Primary")
                 FriendsList:PopulateSortMenu(primarySort, "primary")

                 -- Secondary Sort
                 local secondarySort = sortSubmenu:CreateButton("Secondary")
                 FriendsList:PopulateSortMenu(secondarySort, "secondary")
            end
            
		    rootDescription:CreateDivider();
		end
		
		-- Changelog option (Simple Mode OR Classic+ElvUI)
		local DB = GetDB()
		local simpleMode = DB and DB:Get("simpleMode", false) or false
		local isElvUIActive = BFL.IsClassic and _G.ElvUI and BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin ~= false
		if simpleMode or isElvUIActive then
			local changelogText = L.MENU_CHANGELOG or "Changelog"
			local Changelog = BFL:GetModule("Changelog")
			if Changelog and Changelog:IsNewVersion() then
				local atlas, size
				if BFL.IsClassic then
					atlas = "communities-icon-invitemail"
					size = ":48:64"
					changelogText = string.format("|A:%s%s|a %s", atlas, size, changelogText)
				else
					-- Retail: Use "NewCharacter-Alliance" (56x29) positioned after text
					-- Height: 29, Width: 56
					changelogText = string.format("%s|A:NewCharacter-Alliance:29:56|a", changelogText)
				end
			end

			rootDescription:CreateButton(changelogText, function()
				local Changelog = BFL:GetModule("Changelog")
				if Changelog then Changelog:Show() end
			end);
		end
		
		-- Show Blizzard's Friendlist option (conditional based on setting)
		local DB = GetDB()
		if DB and DB:Get("showBlizzardOption", false) then
			-- Check combat state
			local inCombat = InCombatLockdown()
			
			-- Create button title with combat lock icon if in combat
			local buttonTitle = L.MENU_SHOW_BLIZZARD
			if inCombat then
				-- Add combat lock icon (same as Raid Tab)
				buttonTitle = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|t " .. buttonTitle
			end
			
			local menuButton = rootDescription:CreateButton(buttonTitle, function() -- Use helper function that bypasses our OnShow hook
				if BFL and BFL.ShowBlizzardFriendsFrame then
					BFL.ShowBlizzardFriendsFrame()
				elseif BFL and BFL.OriginalToggleFriendsFrame then
					-- Fallback to stored original function
					BFL.OriginalToggleFriendsFrame()
				else
					-- Fallback to ShowUIPanel (may cause taint in combat)
					if FriendsFrame:IsShown() then
						HideUIPanel(FriendsFrame)
					else
						ShowUIPanel(FriendsFrame)
					end
				end
			end);
			
			-- Disable button in combat (ShowUIPanel/HideUIPanel are protected)
			if inCombat then
				menuButton:SetEnabled(false)
				-- Add tooltip using OnEnter/OnLeave (SetTooltip doesn't exist)
				menuButton:AddInitializer(function(btn, description, menuInstance) btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(L.MENU_SHOW_BLIZZARD, 1, 1, 1)
						GameTooltip:AddLine(L.MENU_COMBAT_LOCKED, 1, 0.2, 0.2, true)
						GameTooltip:Show()
					end)
					btn:SetScript("OnLeave", function() GameTooltip:Hide()
					end)
				end)
			else
				menuButton:SetEnabled(true)
			end
		end
		
		-- Create Group option
		rootDescription:CreateButton(L.MENU_CREATE_GROUP, function() StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP")
		end);
		
		rootDescription:CreateDivider();
		
		-- Broadcast option (only if BNet is connected)
		local canUseBroadCastFrame = BNFeaturesEnabled() and BNConnected();
		if canUseBroadCastFrame then
			rootDescription:CreateButton(CONTACTS_MENU_BROADCAST_BUTTON_NAME or L.MENU_SET_BROADCAST, function() local broadcastFrame = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame.BroadcastFrame;
				if broadcastFrame then
					broadcastFrame:ToggleFrame();
				end
			end);
		end
		
		-- Ignore List option
		rootDescription:CreateButton(CONTACTS_MENU_IGNORE_BUTTON_NAME or L.MENU_IGNORE_LIST, function() BetterFriendsFrame_ShowIgnoreList();
		end);
	end

	-- Use DropdownButtonMixin (Retail 11.0+) to ensure correct anchoring
	if button.SetupMenu and button.OpenMenu then
		-- Setup once and restore native Toggle behavior
		if not button._bflMenuInitialized then
			button._bflMenuInitialized = true
			button:SetupMenu(generator)
			
			-- Fix: Template overrides OnMouseDown, breaking Mixin behavior.
			-- Hook OnMouseDown to properly toggle the menu.
			if button.HookScript then
				button:HookScript("OnMouseDown", function(self)
					if self.ToggleMenu then
						self:ToggleMenu()
					end
				end)
			end
			
			-- Disable OnClick to prevent "Double Toggle" (Close on MouseDown -> Re-open on MouseUp)
			if button.SetScript then
				button:SetScript("OnClick", nil)
			end
			
			-- Open initially (since we missed the MouseDown hook for this first click)
			button:OpenMenu()
		end
		return
	end
	
	-- Fallback: Manual creation (forces cursor anchor, but tries to fix it)
	local menu = MenuUtil.CreateContextMenu(button, generator)
	
	if menu then
		table.insert(_G.BFL_ActiveContactsMenus, menu)
	end
	
	-- Hook menu's Hide to track when it closes (but DON'T remove from list yet)
	if menu and not menu._bflHooked then
		menu._bflHooked = true
		local originalHide = menu.Hide
		menu.Hide = function(self) originalHide(self)
			-- DON'T remove from list - let combat handler do cleanup
		end
	end
end

-- Show Ignore List (11.2.5 - part of contacts menu)
function BetterFriendsFrame_ShowIgnoreList() -- Show IgnoreList module UI (always, even if empty)
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
			print(L.IGNORE_LIST_EMPTY)
		else
			print(string.format(L.IGNORE_LIST_HEADER, numIgnores))
			for i = 1, numIgnores do
				local name = C_FriendList.GetIgnoreName(i)
				if name then
					print("  " .. i .. ". " .. name)
				end
			end
			print(L.IGNORE_LIST_HELP)
		end
	end
end

-- ========================================
-- XML CALLBACK FUNCTIONS (Required by XML OnLoad/OnEvent/OnShow/OnHide attributes)
-- ========================================
-- These functions are called directly from XML and must remain global

-- WHO Frame OnLoad (called from XML line 1540)
function BetterWhoFrame_OnLoad(self) local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:OnLoad(self)
	end
end

-- WHO Frame Update (called from XML OnShow and event handlers)
function BetterWhoFrame_Update(forceRebuild) local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:Update(forceRebuild)
	end
end

-- WHO Frame Sort By Column (called from XML header buttons)
function BetterWhoFrame_SortByColumn(column) local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SortByColumn(column)
	end
end

-- WHO Frame Send Request (called from XML Who button)
function BetterWhoFrame_SendWhoRequest(text) local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SendWhoRequest(text)
	end
end

-- WHO Frame Set Selected Button (called from XML)
function BetterWhoFrame_SetSelectedButton(button) local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:SetSelectedButton(button)
	end
end

-- WHO Frame Invalidate Font Cache (called from XML OnShow)
function BetterWhoFrame_InvalidateFontCache() local WhoFrame = GetWhoFrame()
	if WhoFrame then
		WhoFrame:InvalidateFontCache()
	end
end

-- Ignore List Window OnLoad (called from XML line 1801)
function BetterIgnoreListWindow_OnLoad(self) local IgnoreList = GetIgnoreList()
	if IgnoreList then
		IgnoreList:OnLoad(self)
	end
end

-- Ignore List Update (called from XML OnShow)
function IgnoreList_Update() local IgnoreList = GetIgnoreList()
	if IgnoreList then
		IgnoreList:Update()
	end
end

-- Recent Allies Frame OnLoad (called from XML line 1841)
function BetterRecentAlliesFrame_OnLoad(self) local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnLoad(self)
	end
end

-- Recent Allies Frame OnShow (called from XML)
function BetterRecentAlliesFrame_OnShow(self) local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnShow(self)
	end
end

-- Recent Allies Frame OnHide (called from XML)
function BetterRecentAlliesFrame_OnHide(self) local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnHide(self)
	end
end

-- Recent Allies Frame OnEvent (called from XML)
function BetterRecentAlliesFrame_OnEvent(self, event, ...) local RecentAllies = GetRecentAllies()
	if RecentAllies then
		RecentAllies:OnEvent(self, event, ...)
	end
end

-- RAF Frame OnLoad (called from XML line 1292)
function BetterRAF_OnLoad(frame) local RAF = GetRAF()
	if RAF then
		RAF:OnLoad(frame)
	end
end

-- RAF Frame OnEvent (called from XML)
function BetterRAF_OnEvent(frame, event, ...) local RAF = GetRAF()
	if RAF then
		RAF:OnEvent(frame, event, ...)
	end
end

-- RAF Frame OnHide (called from XML)
function BetterRAF_OnHide(frame) local RAF = GetRAF()
	if RAF then
		RAF:OnHide(frame)
	end
end

-- RAF Button Callbacks (called from ScrollBox initializer and XML)
function BetterRecruitListButton_Init(button, elementData) local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_Init(button, elementData)
	end
end

function BetterRecruitListButton_OnEnter(button) local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_OnEnter(button)
	end
end

function BetterRecruitListButton_OnClick(button, mouseButton) local RAF = GetRAF()
	if RAF then
		RAF:RecruitListButton_OnClick(button, mouseButton)
	end
end

function BetterRecruitActivityButton_OnClick(button) local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnClick(button)
	end
end

function BetterRecruitActivityButton_OnEnter(button) local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnEnter(button)
	end
end

function BetterRecruitActivityButton_OnLeave(button) local RAF = GetRAF()
	if RAF then
		RAF:RecruitActivityButton_OnLeave(button)
	end
end

function BetterRAF_NextRewardButton_OnClick(button, mouseButton) local RAF = GetRAF()
	if RAF then
		RAF:NextRewardButton_OnClick(button, mouseButton)
	end
end

function BetterRAF_NextRewardButton_OnEnter(button) local RAF = GetRAF()
	if RAF then
		RAF:NextRewardButton_OnEnter(button)
	end
end

function BetterRAF_ClaimOrViewRewardButton_OnClick(button) local RAF = GetRAF()
	if RAF then
		RAF:ClaimOrViewRewardButton_OnClick(button)
	end
end

function BetterRAF_DisplayRewardsInChat(rafInfo) local RAF = GetRAF()
	if RAF then
		RAF:DisplayRewardsInChat(rafInfo)
	end
end

function BetterRAF_RecruitmentButton_OnClick(button) local RAF = GetRAF()
	if RecruitAFriendRecruitmentFrame:IsShown() then
		StaticPopupSpecial_Hide(RecruitAFriendRecruitmentFrame);
	else
		C_RecruitAFriend.RequestUpdatedRecruitmentInfo();
		RecruitAFriendRewardsFrame:Hide();
		StaticPopupSpecial_Show(RecruitAFriendRecruitmentFrame);
	end
end

-- ========================================
-- BOTTOM TAB MANAGEMENT
-- ========================================

-- Handle Guild Tab Click (Classic only)
-- Opens Blizzard Guild Frame, optionally closes BFL based on setting
function BetterFriendsFrame_HandleGuildTabClick() if not BFL.IsClassic then return end
	
	-- Check and disable useClassicGuildUI CVar before opening Guild Frame (silent, no popup)
	local useClassicGuildUI = GetCVar("useClassicGuildUI")
	if useClassicGuildUI == "1" then
		SetCVar("useClassicGuildUI", "0")
	end
	
	-- Toggle Blizzard Guild Frame
	ToggleGuildFrame()
	
	-- Switch back to Friends tab (tab 1)
	PanelTemplates_SetTab(BetterFriendsFrame, 1)
	BetterFriendsFrame_ShowBottomTab(1)
	
	-- Close BFL Frame only if setting is enabled
	if BetterFriendlistDB and BetterFriendlistDB.closeOnGuildTabClick then
		HideUIPanel(BetterFriendsFrame)
	end
end

-- Function to show specific bottom tab
function BetterFriendsFrame_ShowBottomTab(tabIndex) local frame = BetterFriendsFrame
	if not frame then return end
	
	-- CRITICAL: Update the Frame's selected tab index so PanelTemplates_GetSelectedTab returns correct value
	-- This fixes 'isFriendsTab' checks in other modules (like FriendsList:UpdateSearchBoxState)
	PanelTemplates_SetTab(frame, tabIndex)
	
	-- SEARCHBOX VISIBILITY IS NOW MANAGED ENTIRELY BY FriendsList:UpdateScrollBoxExtent()
	-- We do not manually hide it here to prevent race conditions (Scenario 1 fix)
	
	-- FORCE FONT UPDATE: Ensure Custom Fonts win against ElvUI
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameBottomTab" .. i]
		if tab then
			-- Ensure fonts are strictly enforcing BetterFriendlist style
			tab:SetNormalFontObject("BetterFriendlistFontNormalSmall")
			tab:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
			tab:SetDisabledFontObject("BetterFriendlistFontHighlightSmall")
			
			if i == tabIndex then
				-- Re-enforce selection state visually just to be safe
				PanelTemplates_SelectTab(tab)
				local fs = tab:GetFontString()
				if fs then
					fs:SetFontObject("BetterFriendlistFontHighlightSmall")
				end
			else
				PanelTemplates_DeselectTab(tab)
			end
		end
	end

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
	-- REMOVED: ScrollBox handles button visibility automatically
	-- if tabIndex ~= 1 then
	-- 	for i = 1, NUM_BUTTONS do
	-- 		local xmlButton = frame.ScrollFrame and frame.ScrollFrame["Button" .. i]
	-- 		if xmlButton then
	-- 			HideChildFrame(xmlButton)
	-- 		end
	-- 	end
	-- end
	
	-- Hide/show FriendsTabHeader based on tab
	if frame.FriendsTabHeader then
		if tabIndex == 1 then
			ShowChildFrame(frame.FriendsTabHeader)
		else
			HideChildFrame(frame.FriendsTabHeader)
		end
	end
	
	-- Hide/show Inset based on tab
	if frame.Inset then
		-- Classic Tab 4 (Guild) also needs Inset hidden
		if tabIndex == 2 or tabIndex == 3 or (BFL.IsClassic and tabIndex == 4) then
			HideChildFrame(frame.Inset)
		else
			ShowChildFrame(frame.Inset)
		end
	end
	
	-- Show/hide Help button (only visible on Raid tab)
	if frame.HelpButton then
		local isRaidTab = false
		if BFL.IsClassic then
			-- Classic: Raid is Tab 4 (or Tab 3 if Guild hidden)
			local hideGuildTab = BetterFriendlistDB and BetterFriendlistDB.hideGuildTab
			isRaidTab = (hideGuildTab and tabIndex == 3) or (tabIndex == 4)
		else
			-- Retail: Raid is ALWAYS Tab 3
			isRaidTab = (tabIndex == 3)
		end
		
		if isRaidTab then
			ShowChildFrame(frame.HelpButton)
		else
			HideChildFrame(frame.HelpButton)
		end
	end
	
	if tabIndex == 1 then
		-- Tab 1: Friends/Contacts list
		-- CRITICAL: Check which TOP tab is active (Friends/Recent Allies/RAF)
		-- to show the correct content when switching from Who/Raid back to Contacts
		if not BFL.IsClassic and frame.FriendsTabHeader then
			local activeTopTab = PanelTemplates_GetSelectedTab(frame.FriendsTabHeader) or 1
			
			if activeTopTab == 1 then
				-- Top Tab 1: Friends
				ShowChildFrame(frame.ScrollFrame)
				ShowChildFrame(frame.MinimalScrollBar)
				ShowChildFrame(frame.AddFriendButton)
				ShowChildFrame(frame.SendMessageButton)
				UpdateFriendsDisplay()
			elseif activeTopTab == 2 then
				-- Top Tab 2: Recent Allies
				if frame.RecentAlliesFrame then
					ShowChildFrame(frame.RecentAlliesFrame)
					local RecentAllies = BFL:GetModule("RecentAllies")
					if RecentAllies then
						RecentAllies:Refresh(frame.RecentAlliesFrame, ScrollBoxConstants.RetainScrollPosition)
					end
				end
			elseif activeTopTab == 3 then
				-- Top Tab 3: Recruit A Friend
				if frame.RecruitAFriendFrame then
					ShowChildFrame(frame.RecruitAFriendFrame)
					ShowChildFrame(frame.RecruitmentButton)
				end
			end
		else
			-- Classic: Always show Friends list (only 1 top tab exists)
			ShowChildFrame(frame.ScrollFrame)
			ShowChildFrame(frame.MinimalScrollBar)
			ShowChildFrame(frame.AddFriendButton)
			ShowChildFrame(frame.SendMessageButton)
			UpdateFriendsDisplay()
		end
	elseif tabIndex == 2 then
		-- Tab 2: Who frame
		ShowChildFrame(frame.WhoFrame)
		BetterWhoFrame_Update()
	elseif tabIndex == 3 then
		if BFL.IsClassic then
			-- Classic: Guild Tab (if visible) OR Raid (if Guild hidden)
			local hideGuildTab = BetterFriendlistDB and BetterFriendlistDB.hideGuildTab
			if hideGuildTab then
				-- Guild hidden: Show Raid
				ShowChildFrame(frame.RaidFrame)
			else
				-- Guild visible: Opens Blizzard's Guild Frame
				-- No content shown here, handled by BetterFriendsFrame_HandleGuildTabClick()
			end
		else
			-- Retail: Raid
			ShowChildFrame(frame.RaidFrame)
		end
	elseif tabIndex == 4 then
		if BFL.IsClassic then
			-- Classic: Raid (only when Guild tab is visible)
			ShowChildFrame(frame.RaidFrame)
		else
			-- Retail: Quick Join
			ShowChildFrame(frame.QuickJoinFrame)
			if BetterQuickJoinFrame_OnShow then
				BetterQuickJoinFrame_OnShow(frame.QuickJoinFrame)
			end
		end
	end

	-- Force update of SearchBox state (Fix for visibility bugs)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.UpdateSearchBoxState then
		FriendsList:UpdateSearchBoxState()
	end
	
	-- Apply custom tab fonts from DB settings (Applied LAST to respect selection state for sizing)
	BFL:ApplyTabFonts()
end

-- ========================================
-- WHO Frame Functions
-- ========================================
-- All WHO Frame functionality is delegated to Modules/WhoFrame.lua
-- XML callbacks reference module methods directly via mixins

-- ========================================
-- Help Button Functions
-- ========================================

-- Help button click handler - shows detailed help about raid roster features
function BetterFriendsFrame_HelpButton_OnClick(self) -- Toggle help frame visibility
	if BFL.HelpFrame then
		BFL.HelpFrame:Toggle()
	end
end

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

function BetterRecentAlliesEntry_OnEnter(self) local RecentAllies = BFL and BFL:GetModule("RecentAllies")
	if RecentAllies and RecentAllies.BuildTooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		RecentAllies:BuildTooltip(self, GameTooltip)
		GameTooltip:Show()
	end
end

function BetterRecentAlliesEntry_OnLeave(self) GameTooltip:Hide()
end

-- ========================================
-- SLASH COMMANDS
-- ========================================

-- Reset Classic Guild UI warning flag (for testing)
SLASH_BFLRESET1 = "/bflreset"
SlashCmdList["BFLRESET"] = function(msg) if msg == "warning" then
		BetterFriendlistDB.classicGuildUIWarningShown = nil
		print("|cff00ff00BetterFriendlist:|r " .. L.CMD_RESET_FILTER_SUCCESS)
	else
		print("|cff00ff00BetterFriendlist " .. L.CMD_RESET_HEADER .. "|r")
		print("  |cffFFD100/bflreset warning|r - " .. L.CMD_RESET_HELP_WARNING)
	end
end

-- ========================================
-- RAID FRAME & QUICK JOIN XML CALLBACKS
-- ========================================
-- All Raid Frame and Quick Join XML callbacks have been moved to:
--   - UI/RaidFrameCallbacks.lua (268 lines)
--   - UI/QuickJoinCallbacks.lua (264 lines)
-- This keeps BetterFriendlist.lua focused on Friends List logic only.

