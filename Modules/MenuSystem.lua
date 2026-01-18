--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua"); -- Modules/MenuSystem.lua
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
function MenuSystem:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:28:0");
	-- Define StaticPopup for Nicknames
	StaticPopupDialogs["BETTER_FRIENDLIST_SET_NICKNAME"] = {
		text = BFL.L.MENU_SET_NICKNAME_FMT,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		OnShow = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:35:11");
			self.EditBox:SetText(data.nickname or "")
			self.EditBox:SetFocus()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:35:11"); end,
		OnAccept = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:39:13");
			local text = self.EditBox:GetText()
			local DB = BFL:GetModule("DB")
			if DB then
				DB:SetNickname(data.uid, text)
				BFL:ForceRefreshFriendsList()
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:39:13"); end,
		EditBoxOnEnterPressed = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:47:26");
			local text = self:GetText()
			local DB = BFL:GetModule("DB")
			if DB then
				DB:SetNickname(data.uid, text)
				BFL:ForceRefreshFriendsList()
			end
			self:GetParent():Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:47:26"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:28:0"); end

-- Open context menu for a friend
-- For BNet: friendID = bnetIDAccount, extraData = {name, battleTag, connected}
-- For WoW: friendID = friendIndex, extraData = {name, connected}
function MenuSystem:OpenFriendMenu(button, friendType, friendID, extraData) Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:OpenFriendMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:66:0");
	if not button or not friendType then Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenFriendMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:66:0"); return end
	
	extraData = extraData or {}
	local menuType
	local contextData
	
	if friendType == "BN" then
		-- Determine if online or offline
		local connected = extraData.connected
		if connected == nil then connected = true end -- Default to online
		
		menuType = connected and "BN_FRIEND" or "BN_FRIEND_OFFLINE"
		
		-- BNet friends need full contextData like BetterFriendsList_ShowBNDropdown
		contextData = {
			name = extraData.name or "",
			friendsList = extraData.index, -- Use numeric index if available (restores behavior from BetterFriendlist.lua)
			bnetIDAccount = friendID,
			battleTag = extraData.battleTag,
			uid = friendID, -- For Nickname
		}
	else
		-- WoW friends
		local connected = extraData.connected
		if connected == nil then connected = true end
		
		menuType = connected and "FRIEND" or "FRIEND_OFFLINE"
		
		-- Get name from extraData or look up by index
		local name = extraData.name
		if not name and type(friendID) == "number" then
			local friendInfo = C_FriendList.GetFriendInfoByIndex(friendID)
			name = friendInfo and friendInfo.name or ""
		end
		
		contextData = {
			name = name or "",
			friendsList = (type(friendID) == "number") and friendID or true, -- RIO Fix
			uid = name, -- For Nickname (WoW friends use name as UID)
			index = (type(friendID) == "number") and friendID or nil,
			friendsIndex = (type(friendID) == "number") and friendID or nil,
		}
	end
	
	-- Set flag to indicate this menu is opened from BetterFriendlist
	_G.BetterFriendlist_IsOurMenu = true
	-- BFL:DebugPrint("|cff00ff00BFL MenuSystem: Flag set to TRUE, opening menu type:", menuType)
	
	-- Use compatibility wrapper for Classic support
	BFL.OpenContextMenu(button, menuType, contextData, contextData.name)
	
	-- Clear flag immediately after opening
	_G.BetterFriendlist_IsOurMenu = false
Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenFriendMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:66:0"); end

-- Open context menu for a group
function MenuSystem:OpenGroupMenu(button, groupData) Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:OpenGroupMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:123:0");
	if not button or not groupData then Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenGroupMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:123:0"); return end
	
	-- For now, groups don't have special context menus
	-- This can be extended later with group management options
Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenGroupMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:123:0"); end

-- Set WHO player menu flag
function MenuSystem:SetWhoPlayerMenuFlag(value) Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:SetWhoPlayerMenuFlag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:131:0");
	isWhoPlayerMenu = value
	-- Store in global for backwards compatibility
	_G.BetterFriendlist_IsWhoPlayerMenu = value
Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:SetWhoPlayerMenuFlag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:131:0"); end

-- Get WHO player menu flag
function MenuSystem:GetWhoPlayerMenuFlag() Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:GetWhoPlayerMenuFlag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:138:0");
	Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:GetWhoPlayerMenuFlag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:138:0"); return isWhoPlayerMenu
end

-- Open context menu for WHO player
function MenuSystem:OpenWhoPlayerMenu(button, whoInfo) Perfy_Trace(Perfy_GetTime(), "Enter", "MenuSystem:OpenWhoPlayerMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:143:0");
	if not button or not whoInfo then
		Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenWhoPlayerMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:143:0"); return
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
	
	-- Use FRIEND menu as base (compatibility wrapper for Classic)
	BFL.OpenContextMenu(button, "FRIEND", contextData, contextData.name)
	
	-- Clear flag immediately after opening
	self:SetWhoPlayerMenuFlag(false)
Perfy_Trace(Perfy_GetTime(), "Leave", "MenuSystem:OpenWhoPlayerMenu file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua:143:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MenuSystem.lua");