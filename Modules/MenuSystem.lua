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
	-- Hook into UnitPopup system to handle menu customization
	hooksecurefunc("UnitPopup_OpenMenu", function(which, contextData)
		-- If we just opened a WHO player menu, handle it
		if isWhoPlayerMenu then
			-- Reset flag after a short delay (menu is built asynchronously)
			C_Timer.After(0, function()
				isWhoPlayerMenu = false
			end)
		end
	end)
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
	if not button or not whoInfo then return end
	
	-- Set flag to indicate this is a WHO player menu
	self:SetWhoPlayerMenuFlag(true)
	
	local contextData = {
		name = whoInfo.fullName,
		server = whoInfo.fullGuildName, -- TODO: Get actual server if available
		guid = whoInfo.guid,
	}
	
	-- Use FRIEND menu as base
	UnitPopup_OpenMenu("FRIEND", contextData)
end
