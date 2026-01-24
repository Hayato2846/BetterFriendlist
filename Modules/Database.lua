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
	groupCountColors = {}, -- {groupId: {r, g, b}} - custom colors for group counts (overrides global)
	groupArrowColors = {}, -- {groupId: {r, g, b}} - custom colors for group arrows (overrides global)
	friendActivity = {}, -- {friendUID: {lastWhisper, lastGroup, lastTrade}} - tracks friend interaction timestamps
	nicknames = {}, -- {friendUID: "Nickname"} - custom nicknames for friends
	-- Visual Settings
	compactMode = false, -- Use compact button layout
	enableElvUISkin = false, -- Enable ElvUI Skin (default: OFF)
	fontSize = "normal", -- "small", "normal", "large"
	-- Font Customization (LibSharedMedia)
	fontFriendName = "Friz Quadrata TT",
	fontSizeFriendName = 12,
	fontOutlineFriendName = "NONE",
	fontShadowFriendName = false,
	fontColorFriendName = {r = 0.510, g = 0.773, b = 1.0, a = 1}, -- Blizzard BNet Blue {r=0.51, g=0.773, b=1.0}
	fontFriendInfo = "Friz Quadrata TT",
	fontSizeFriendInfo = 10,
	fontOutlineFriendInfo = "NONE",
	fontShadowFriendInfo = false,
	fontColorFriendInfo = {r = 0.510, g = 0.510, b = 0.510, a = 1}, -- Blizzard Gray {r=0.51, g=0.51, b=0.51}
	-- Group Header Font Customization
	fontGroupHeader = "Friz Quadrata TT",
	fontSizeGroupHeader = 12,
	fontOutlineGroupHeader = "NONE",
	fontShadowGroupHeader = false,
	colorGroupCount = nil, -- Default: nil (Inherit from Group Color)
	colorGroupArrow = nil, -- Default: nil (Inherit from Group Color)

	colorClassNames = true, -- Color character names by class (default: ON)
	hideEmptyGroups = false, -- Hide groups with no online friends (default: OFF)
	headerCountFormat = "visible", -- Group header count format: "visible", "online", "both" (default: visible)
	groupHeaderAlign = "LEFT", -- Alignment of group header text: "LEFT", "CENTER", "RIGHT" (default: LEFT)
	showGroupArrow = true, -- Show the collapse/expand arrow on group headers (default: ON)
	groupArrowAlign = "LEFT", -- Alignment of group header arrow: "LEFT", "CENTER", "RIGHT" (default: LEFT)
	showFactionIcons = false, -- Show faction icons next to character names (default: OFF)
	showRealmName = false, -- Show realm name for cross-realm friends (default: OFF)
	grayOtherFaction = false, -- Gray out friends from other faction (default: OFF)
	showMobileAsAFK = false, -- Show mobile friends with AFK status icon (default: OFF)
	treatMobileAsOffline = false, -- Treat mobile friends as offline (display in Offline group) (default: OFF)
	nameDisplayFormat = "%name%", -- Display format: %name%, %note%, %nickname% (default: %name%)
	enableInGameGroup = false, -- Enable dynamic "In-Game" group (default: OFF)
	inGameGroupMode = "same_game", -- "same_game" (WoW matching project) or "any_game" (Any BNet game)
	windowScale = 1.0, -- Window scale factor: 0.5 = 50%, 1.0 = 100%, 2.0 = 200% (default: 100%)
	hideMaxLevel = false, -- Hide level display for max level characters (default: OFF)
	accordionGroups = false, -- Only allow one group to be open at a time (default: OFF)
	showFavoritesGroup = true, -- Show the Favorites group (default: ON)
	-- Sort Settings
	primarySort = "status", -- Primary sort method: status, name, level, zone (default: status)
	secondarySort = "name", -- Secondary sort method: none, name, level, zone (default: name)
	-- Filter Settings
	quickFilter = "all", -- Quick filter mode: all, online, offline, wow, bnet (default: all)
	-- Debug Settings
	debugPrintEnabled = false, -- Toggle debug prints with /bfl debug print
	-- Beta Features
	enableBetaFeatures = false, -- Enable experimental Beta features (default: OFF)
	-- Global Sync Settings (Beta)
	enableGlobalSync = false, -- Enable Global Friend Sync (default: OFF)
	enableGlobalSyncDeletion = false, -- Enable deletion of friends during sync (default: OFF)
	-- Notification Settings (Beta)
	notificationDisplayMode = "alert", -- Display mode: "alert", "chat", "disabled" (default: alert)
	notificationSoundEnabled = true, -- Play sound with notifications (default: true)
	notificationOfflineEnabled = false, -- Show notifications when friends go offline (default: false)
	-- Quiet Hours Settings
	notificationQuietCombat = true, -- Silence notifications during combat (default: true)
	notificationQuietInstance = false, -- Silence notifications in instances (default: false)
	notificationQuietManual = false, -- Manual DND mode (default: false)
	notificationQuietScheduled = false, -- Enable scheduled quiet hours (default: false)
	notificationQuietScheduleStartMinutes = 1320, -- Quiet hours start in minutes since midnight (default: 22:00 = 1320)
	notificationQuietScheduleEndMinutes = 480, -- Quiet hours end in minutes since midnight (default: 08:00 = 480)
	-- Per-Friend Rules
	notificationFriendRules = {}, -- Per-friend notification rules: {[friendUID] = "whitelist"/"blacklist"/"default"}
	-- Per-Group Rules (NEW: Phase 14.1)
	notificationGroupRules = {}, -- Per-group notification rules: {[groupId] = "whitelist"/"blacklist"/"default"}
	-- Group Triggers
	notificationGroupTriggers = {}, -- Group triggers: {[triggerID] = {groupId, threshold, enabled, lastTriggered}}
	-- Custom Message Templates
	notificationMessageOnline = "%name% is now online", -- Template for online notifications (default)
	notificationMessageOffline = "%name% went offline", -- Template for offline notifications (default)
	-- Toast Container Position (Edit Mode)
	notificationToastPosition = {}, -- {[layoutName] = {point, x, y}} - Toast container position per layout
	-- Main Frame Edit Mode (Phase EditMode)
	mainFrameSize = {}, -- {[layoutName] = {width, height}} - Main frame size per layout
	mainFramePosition = {}, -- {[layoutName] = {point, x, y}} - Main frame position per layout
	mainFramePositionMigrated = false, -- Track if old position has been migrated (one-time)
	defaultFrameWidth = 415, -- User-customizable default width (350-800)
	defaultFrameHeight = 570, -- User-customizable default height (400-1200)
	-- Phase 11.5: Game-Specific Notifications
	notificationWowLoginEnabled = true, -- Show notifications when friend logs into WoW (default: true)
	notificationCharSwitchEnabled = false, -- Show notifications when friend switches character (default: false)
	notificationGameSwitchEnabled = false, -- Show notifications when friend switches game (default: false)
	notificationMessageWowLogin = "%name% logged into World of Warcraft", -- Template for WoW login
	notificationMessageCharSwitch = "%name% switched to %char%", -- Template for character switch
	notificationMessageGameSwitch = "%name% is now playing %game%", -- Template for game switch
	-- Data Broker Settings (BETA Feature - requires enableBetaFeatures)
	brokerEnabled = false, -- Enable Data Broker integration (default: OFF, Beta Feature)
	brokerShowIcon = true, -- Show icon on display addons (default: ON)
	brokerShowLabel = true, -- Show label text (default: ON)
	brokerShowTotal = true, -- Show total count (default: ON)
	brokerShowGroups = false, -- Split counts by WoW/BNet (default: OFF, shows combined)
	brokerTooltipMode = "advanced", -- Tooltip detail level: "basic" or "advanced" (default: advanced)
	brokerClickAction = "toggle", -- Left click action: "toggle", "friends", "settings" (default: toggle)
	-- Classic Guild Tab Settings
	closeOnGuildTabClick = false, -- Close BetterFriendlist when opening Guild Frame (Classic only, default: OFF)
	hideGuildTab = false, -- Hide the Guild tab completely (Classic only, default: OFF)
	-- UI Panel System
	useUIPanelSystem = false, -- Use ShowUIPanel/HideUIPanel for automatic repositioning (default: OFF)
	-- Migration tracking
	friendGroupsMigrated = false, -- Track if FriendGroups migration has been completed
	lastChangelogVersion = "0.0.0", -- Last version the user saw the changelog for
	version = BFL.Version
}

function DB:InternalDeepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[self:InternalDeepCopy(orig_key)] = self:InternalDeepCopy(orig_value)
		end
		setmetatable(copy, self:InternalDeepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function DB:Initialize()
	-- Initialize SavedVariables
	if not BetterFriendlistDB then
		BetterFriendlistDB = {}
	end
	
	-- Apply defaults
	for key, value in pairs(defaults) do
		if BetterFriendlistDB[key] == nil then
			if type(value) == "table" then
				BetterFriendlistDB[key] = self:InternalDeepCopy(value)
			else
				BetterFriendlistDB[key] = value
			end
		end
	end
	
	-- MIGRATION: Fix Color Tables initialized as empty tables (Bug fix Phase 20)
	-- Check if color settings are empty tables and reset to defaults
	local colorKeys = {"fontColorFriendName", "fontColorFriendInfo"}
	for _, key in ipairs(colorKeys) do
		local dbVal = BetterFriendlistDB[key]
		if type(dbVal) == "table" and (dbVal.r == nil or dbVal.g == nil or dbVal.b == nil) then
			-- Reset to default if any color component is missing
			if defaults[key] then
				BetterFriendlistDB[key] = self:InternalDeepCopy(defaults[key])
				-- BFL:DebugPrint("Database: Fixed corrupted color table for " .. key)
			end
		end
	end
	
	-- Debug: Check ElvUI Skin setting
	if BetterFriendlistDB.enableElvUISkin then
		-- BFL:DebugPrint("Database: ElvUI Skin is ENABLED")
	else
		-- BFL:DebugPrint("Database: ElvUI Skin is DISABLED")
	end
	
	-- MIGRATION: Name Display Format (Phase 15)
	-- Convert old boolean flags to new format string
	if BetterFriendlistDB.showNotesAsName ~= nil or BetterFriendlistDB.showNicknameAsName ~= nil or BetterFriendlistDB.showNicknameInName ~= nil then
		local showNotes = BetterFriendlistDB.showNotesAsName
		local showNick = BetterFriendlistDB.showNicknameAsName
		local showNickInName = BetterFriendlistDB.showNicknameInName
		
		local format = "%name%"
		
		if showNick then
			format = "%nickname%"
		elseif showNotes then
			format = "%note%"
		end
		
		if showNickInName then
			-- If base format is already nickname, don't append nickname again
			if format ~= "%nickname%" then
				format = format .. " (%nickname%)"
			end
		end
		
		BetterFriendlistDB.nameDisplayFormat = format
		
		-- Remove old keys
		BetterFriendlistDB.showNotesAsName = nil
		BetterFriendlistDB.showNicknameAsName = nil
		BetterFriendlistDB.showNicknameInName = nil
		
		-- BFL:DebugPrint("|cff00ff00BFL:Database:|r Migrated name display settings to: " .. format)
	end
	
	-- Migration: Ensure defaultFrameWidth meets new minimum (380px)
	if BetterFriendlistDB.defaultFrameWidth and BetterFriendlistDB.defaultFrameWidth < 380 then
		BetterFriendlistDB.defaultFrameWidth = 380
		-- BFL:DebugPrint("|cff00ff00BFL:Database:|r Migrated defaultFrameWidth to 380 (old minimum was 350)")
	end
	
	-- Version migration if needed
	if BetterFriendlistDB.version ~= BFL.VERSION then
		self:MigrateData(BetterFriendlistDB.version, BFL.VERSION)
		BetterFriendlistDB.version = BFL.VERSION
	end
	
	-- Initialize CustomNames Sync if available
	local lib = LibStub("CustomNames", true)
	if lib then
		-- BFL:DebugPrint("Database: CustomNames Library DETECTED and Sync enabled.")
		
		-- Push existing BFL nicknames to Library (One-way sync on load)
		if BetterFriendlistDB.nicknames then
			for uid, nickname in pairs(BetterFriendlistDB.nicknames) do
				local libKey = self:GetLibKey(uid)
				-- Only push if we have a valid lib key (not a raw bnet_ID that failed to resolve)
				if libKey and nickname and not libKey:match("^bnet_") then
					local libName = lib.Get(libKey)
					-- Only push if Lib doesn't have a custom name yet (returns original name)
					if libName == libKey then
						lib.Set(libKey, nickname)
						-- BFL:DebugPrint("Database: Synced " .. libKey .. " to CustomNames Lib")
					end
				end
			end
		end

		-- Register callbacks to keep internal DB in sync
		lib.RegisterCallback(self, "Name_Added", function(_, name, customName)
			self:SetNicknameInternal(name, customName)
		end)
		lib.RegisterCallback(self, "Name_Update", function(_, name, customName)
			self:SetNicknameInternal(name, customName)
		end)
		lib.RegisterCallback(self, "Name_Removed", function(_, name)
			self:SetNicknameInternal(name, nil)
		end)
	else
		-- BFL:DebugPrint("Database: CustomNames Library NOT detected.")
	end
end

function DB:GetLibKey(friendUID)
	if not friendUID then return nil end
	
	if friendUID:match("^wow_") then
		-- WoW: Strip "wow_" prefix for Lib (Name-Realm)
		return friendUID:gsub("^wow_", "")
	elseif friendUID:match("^bnet_%d+") then
		-- BNet ID: Resolve to BattleTag for Lib
		local bnetID = tonumber(friendUID:match("^bnet_(%d+)"))
		if bnetID then
			local accountInfo = C_BattleNet.GetAccountInfoByID(bnetID)
			if accountInfo and accountInfo.battleTag then
				return accountInfo.battleTag
			end
		end
	elseif friendUID:match("^bnet_") then
		-- BNet Tag (legacy/fallback): Strip "bnet_"
		return friendUID:gsub("^bnet_", "")
	elseif friendUID:match("#") then
		-- Already a BattleTag
		return friendUID
	end
	
	-- Fallback: Assume it's a WoW name without prefix (shouldn't happen with BFL UIDs but safe to return)
	return friendUID
end

-- Internal setter for DB only (used by Sync and SetNickname)
function DB:SetNicknameInternalDB(key, nickname)
	if not key then return end
	if not BetterFriendlistDB.nicknames then
		BetterFriendlistDB.nicknames = {}
	end
	
	if nickname and nickname ~= "" then
		BetterFriendlistDB.nicknames[key] = nickname
	else
		BetterFriendlistDB.nicknames[key] = nil
	end
end

-- Callback handler for CustomNames Sync
function DB:SetNicknameInternal(name, nickname)
	if not name then return end
	-- BFL:DebugPrint("DB:SetNicknameInternal (Sync) for " .. tostring(name) .. " to " .. tostring(nickname))

	-- Convert Lib Name back to DB Key
	local dbKey = name
	if not name:match("#") then 
		-- It's a WoW Name (Name-Realm) -> Prepend "wow_" for BFL DB
		dbKey = "wow_" .. name
	else
		-- It's a BattleTag -> Use as is (matches our BNet storage strategy)
		dbKey = name
	end
	
	self:SetNicknameInternalDB(dbKey, nickname)

	-- Force UI Refresh to show new nickname immediately
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

function DB:MigrateData(oldVersion, newVersion)
	-- Future: Add data migration logic here
	-- print("Migrating data from", oldVersion or "unknown", "to", newVersion)
end

-- Get a value from the database
function DB:ResetFontColors()
	-- Reset font colors to Blizzard defaults
	if defaults.fontColorFriendName then
		BetterFriendlistDB.fontColorFriendName = self:InternalDeepCopy(defaults.fontColorFriendName)
	end
	if defaults.fontColorFriendInfo then
		BetterFriendlistDB.fontColorFriendInfo = self:InternalDeepCopy(defaults.fontColorFriendInfo)
	end
	
	-- Force full display refresh
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
	
	-- BFL:DebugPrint("Database: Font colors reset to defaults.")
	print("|cff00ff00BetterFriendlist:|r Font colors reset to Blizzard defaults.")
end

function DB:Get(key, default)
	-- If no key provided, return entire database
	if key == nil then
		return BetterFriendlistDB
	end
	
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

-- Get nickname
function DB:GetNickname(friendUID)
	if not friendUID then return nil end
	
	local libKey = self:GetLibKey(friendUID)
	
	-- 1. Try CustomNames Lib
	local lib = LibStub("CustomNames", true)
	if lib and libKey then
		local customName = lib.Get(libKey)
		if customName and customName ~= libKey then
			-- BFL:DebugPrint("DB:GetNickname (Lib) found for " .. tostring(libKey) .. ": " .. tostring(customName))
			return customName
		end
	end

	-- 2. Fallback to Internal DB
	-- For WoW friends, we use the original UID (wow_Name-Realm) as key
	-- For BNet friends, we use the BattleTag (libKey) as key, because we can't map back to ID easily in Sync
	
	local dbKey = friendUID
	if friendUID:match("^bnet_") and libKey then
		dbKey = libKey -- Use BattleTag for BNet storage
	end

	local nickname = BetterFriendlistDB.nicknames and BetterFriendlistDB.nicknames[dbKey]
	
	if nickname then
		-- BFL:DebugPrint("DB:GetNickname (Internal) found for " .. tostring(dbKey) .. ": " .. tostring(nickname))
	end
	return nickname
end

-- Set nickname
function DB:SetNickname(friendUID, nickname)
	if not friendUID then return end
	
	local libKey = self:GetLibKey(friendUID)
	-- BFL:DebugPrint("DB:SetNickname called for " .. tostring(friendUID) .. " -> LibKey: " .. tostring(libKey) .. " Value: " .. tostring(nickname))
	
	-- 1. Update CustomNames Lib
	local lib = LibStub("CustomNames", true)
	if lib and libKey then
		if nickname and nickname ~= "" then
			lib.Set(libKey, nickname)
		else
			lib.Set(libKey, nil)
		end
	end
	
	-- 2. Update Internal DB
	-- Determine DB Key (same logic as GetNickname)
	local dbKey = friendUID
	if friendUID:match("^bnet_") and libKey then
		dbKey = libKey
	end
	
	self:SetNicknameInternalDB(dbKey, nickname)
end
