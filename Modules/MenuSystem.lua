-- Modules/MenuSystem.lua
-- Context Menu System Module
-- Manages context menus for friends, groups, and other UI elements

local ADDON_NAME, BFL = ...

-- Register Module
local MenuSystem = BFL:RegisterModule("MenuSystem", {})

-- ========================================
-- Module Dependencies
-- ========================================

-- No direct dependencies, uses global WoW API

-- ========================================
-- Local Variables
-- ========================================

-- Flag for WHO player menu filtering
local isWhoPlayerMenu = false

-- ========================================
-- Public API
-- ========================================

-- Initialize (called from ADDON_LOADED)
function MenuSystem:Initialize()
	-- No menu modifications needed currently
end

-- Open context menu for a friend
function MenuSystem:OpenFriendMenu(button, friendType, friendID)
	if not button or not friendType then return end
	
	local menuType
	if friendType == "BN" then
		menuType = "BN_FRIEND"
	else
		menuType = "FRIEND"
	end
	
	local contextData = {
		friendType = friendType,
		friendID = friendID,
		button = button,
	}
	
	-- Set flag to indicate this menu is opened from BetterFriendlist
	_G.BetterFriendlist_IsOurMenu = true
	print("|cff00ff00BFL MenuSystem: Flag set to TRUE, opening menu type:", menuType)
	
	UnitPopup_OpenMenu(menuType, contextData)
end

-- Open context menu for a group
function MenuSystem:OpenGroupMenu(button, groupData)
	if not button or not groupData then return end
	
	-- For now, groups don't have special context menus
	-- This can be extended later with group management options
end

-- Set WHO player menu flag
function MenuSystem:SetWhoPlayerMenuFlag(value)
	isWhoPlayerMenu = value
	-- Store in global for backwards compatibility
	_G.BetterFriendlist_IsWhoPlayerMenu = value
end

-- Get WHO player menu flag
function MenuSystem:GetWhoPlayerMenuFlag()
	return isWhoPlayerMenu
end

-- Open context menu for WHO player
function MenuSystem:OpenWhoPlayerMenu(button, whoInfo)
	if not button or not whoInfo then
		return
	end
	
	-- Set flag to indicate this is a WHO player menu
	self:SetWhoPlayerMenuFlag(true)
	
	-- Strip trailing dash from name (WoW API bug)
	local cleanName = whoInfo.fullName
	if cleanName then
		cleanName = cleanName:gsub("%-$", "")
	end
	
	-- IMPORTANT: Also clean the regular name field
	local cleanShortName = whoInfo.name
	if cleanShortName then
		cleanShortName = cleanShortName:gsub("%-$", "")
	end
	
	-- Extract server from fullName (e.g., "Name-Server" -> "Server")
	-- DO NOT use fullGuildName as server - that's the guild name!
	local serverName = nil
	if cleanName and cleanName:find("-") then
		-- Split "Charactername-Servername" 
		local _, _, name, server = cleanName:find("^(.-)%-(.+)$")
		if server then
			cleanName = name  -- Use just the character name
			serverName = server
		end
	end
	
	local contextData = {
		name = cleanName or cleanShortName,
		server = serverName,  -- Only set if cross-realm, otherwise nil
		guid = whoInfo.guid,
	}
	
	-- Use FRIEND menu as base
	UnitPopup_OpenMenu("FRIEND", contextData)
end
