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
	-- Define StaticPopup for Nicknames
	StaticPopupDialogs["BETTER_FRIENDLIST_SET_NICKNAME"] = {
		text = BFL.L.MENU_SET_NICKNAME_FMT,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		OnShow = function(self, data)
			self.EditBox:SetText(data.nickname or "")
			self.EditBox:SetFocus()
		end,
		OnAccept = function(self, data)
			local text = self.EditBox:GetText()
			local DB = BFL:GetModule("DB")
			if DB then
				DB:SetNickname(data.uid, text)
				BFL:ForceRefreshFriendsList()
			end
		end,
		EditBoxOnEnterPressed = function(self, data)
			local text = self:GetText()
			local DB = BFL:GetModule("DB")
			if DB then
				DB:SetNickname(data.uid, text)
				BFL:ForceRefreshFriendsList()
			end
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
end

-- Open context menu for a friend
-- For BNet: friendID = bnetIDAccount, extraData = {name, battleTag, connected}
-- For WoW: friendID = friendIndex, extraData = {name, connected}
function MenuSystem:OpenFriendMenu(button, friendType, friendID, extraData)
	if not button or not friendType then
		return
	end

	extraData = extraData or {}
	local menuType
	local contextData

	if friendType == "BN" then
		-- Determine if online or offline
		local connected = extraData.connected
		if connected == nil then
			connected = true
		end -- Default to online

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
		if connected == nil then
			connected = true
		end

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

	-- Use compatibility wrapper for Classic support
	BFL.OpenContextMenu(button, menuType, contextData, contextData.name)
end

-- Open context menu for a group
function MenuSystem:OpenGroupMenu(button, groupData)
	if not button or not groupData then
		return
	end

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
			cleanName = name -- Use just the character name
			serverName = server
		end
	end

	local contextData = {
		name = cleanName or cleanShortName,
		server = serverName, -- Only set if cross-realm, otherwise nil
		guid = whoInfo.guid,
		bflWhoPlayerMenu = true,
	}

	-- Use FRIEND menu as base (compatibility wrapper for Classic)
	BFL.OpenContextMenu(button, "FRIEND", contextData, contextData.name)

	-- Clear flag immediately after opening
	self:SetWhoPlayerMenuFlag(false)
end

-- Open context menu for a guild member (from Guild Tab)
function MenuSystem:ShowGuildMemberMenu(button, member)
	if not button or not member then return end

	local GuildActions = BFL:GetModule("GuildActions")
	if GuildActions then
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(button, function(owner, rootDescription)
				GuildActions:PopulateMemberMenu(rootDescription, member)
			end)
			return
		elseif UIDropDownMenu_Initialize and ToggleDropDownMenu then
			if not self.GuildMemberDropdown then
				self.GuildMemberDropdown = CreateFrame("Frame", "BFL_GuildMemberDropdown", UIParent, "UIDropDownMenuTemplate")
			end

			UIDropDownMenu_Initialize(self.GuildMemberDropdown, function(dropdown, level)
				if (level or 1) == 1 then
					local info = UIDropDownMenu_CreateInfo()
					info.text = GuildActions:GetDisplayName(member)
					info.isTitle = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, level)
				end
				GuildActions:AddClassicMemberMenuButtons(member, level)
			end, "MENU")

			ToggleDropDownMenu(1, nil, self.GuildMemberDropdown, button, 0, 0)
			return
		end
	end

	local L = BFL.L
	local fullName = member.fullName
	local displayName = Ambiguate(fullName, "guild")

	-- Helper: copy-name dialog
	local function ShowCopyName()
		local key = "BFL_GUILD_COPY_NAME"
		StaticPopupDialogs[key] = {
			text = (L and L.GUILD_COPY_NAME_TITLE) or "Copy Name",
			button1 = OKAY or "Okay",
			hasEditBox = 1,
			editBoxWidth = 240,
			OnShow = function(self)
				self.editBox:SetText(fullName or "")
				self.editBox:HighlightText()
				self.editBox:SetFocus()
			end,
			EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
		StaticPopup_Show(key)
	end

	local function RefreshGuildSurfaces()
		local GuildFrame = BFL:GetModule("GuildFrame")
		if GuildFrame and GuildFrame.Refresh then GuildFrame:Refresh() end
		local GuildBroker = BFL:GetModule("GuildBroker")
		if GuildBroker and GuildBroker.RefreshTooltip then GuildBroker:RefreshTooltip() end
	end

	local function ShowNicknameDialog()
		if not fullName then
			return
		end
		local DB = BFL:GetModule("DB")
		local currentNick = DB and DB:GetGuildNickname(fullName) or ""
		StaticPopupDialogs["BFL_GUILD_SET_NICKNAME"] = {
			text = string.format(L.GUILD_BROKER_NICKNAME_PROMPT or "Enter a nickname for %s:", displayName),
			button1 = ACCEPT,
			button2 = CANCEL,
			button3 = currentNick ~= "" and (L.GUILD_BROKER_MENU_REMOVE_NICKNAME or "Remove") or nil,
			hasEditBox = true,
			editBoxWidth = 250,
			OnShow = function(self)
				self.EditBox:SetText(currentNick)
				self.EditBox:SetFocus()
				self.EditBox:HighlightText()
			end,
			OnAccept = function(self)
				local newNick = self.EditBox:GetText()
				if DB and newNick and newNick:trim() ~= "" then
					DB:SetGuildNickname(fullName, newNick:trim())
					RefreshGuildSurfaces()
				end
			end,
			OnAlt = function()
				if DB then
					DB:SetGuildNickname(fullName, nil)
					RefreshGuildSurfaces()
				end
			end,
			EditBoxOnEnterPressed = function(self)
				local parent = self:GetParent()
				local newNick = parent.EditBox:GetText()
				if DB and newNick and newNick:trim() ~= "" then
					DB:SetGuildNickname(fullName, newNick:trim())
					RefreshGuildSurfaces()
				end
				parent:Hide()
			end,
			EditBoxOnEscapePressed = function(self)
				self:GetParent():Hide()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BFL_GUILD_SET_NICKNAME")
	end

	local function InviteToGroup()
		if fullName and BFL.InviteUnit and not BFL:IsActionRestricted() then
			BFL.InviteUnit(fullName)
		end
	end

	local function Whisper()
		if fullName then
			BFL:SecureSendTell(fullName:gsub(" ", ""))
		end
	end

	if MenuUtil and MenuUtil.CreateContextMenu then
		-- Retail: Modern menu
		MenuUtil.CreateContextMenu(button, function(owner, rootDescription)
			rootDescription:CreateTitle(displayName)

			-- Communication
			if member.online and fullName then
				rootDescription:CreateButton((L and L.GUILD_ACTION_WHISPER) or WHISPER or "Whisper", Whisper)
				rootDescription:CreateButton((L and L.GUILD_ACTION_INVITE_PARTY) or PARTY_INVITE or "Invite", InviteToGroup)
			end

			rootDescription:CreateDivider()

			-- BFL-local nickname only; guild notes/admin actions stay in the native UI.
			if fullName then
				local DB = BFL:GetModule("DB")
				local currentNick = DB and DB:GetGuildNickname(fullName) or ""
				local nickLabel = currentNick ~= ""
					and (L.GUILD_BROKER_MENU_EDIT_NICKNAME or "Edit Nickname")
					or (L.GUILD_BROKER_MENU_SET_NICKNAME or "Set Nickname")
				rootDescription:CreateButton(nickLabel, ShowNicknameDialog)
			end

			rootDescription:CreateDivider()

			-- System
			rootDescription:CreateButton((L and L.GUILD_ACTION_COPY_NAME) or "Copy Name", function()
				ShowCopyName()
			end)
		end)
	elseif UIDropDownMenu_Initialize and ToggleDropDownMenu then
		if not self.GuildMemberDropdown then
			self.GuildMemberDropdown = CreateFrame("Frame", "BFL_GuildMemberDropdown", UIParent, "UIDropDownMenuTemplate")
		end

		UIDropDownMenu_Initialize(self.GuildMemberDropdown, function(dropdown, level)
			local info = UIDropDownMenu_CreateInfo()
			info.text = displayName
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			if member.online and fullName then
				info = UIDropDownMenu_CreateInfo()
				info.text = (L and L.GUILD_ACTION_WHISPER) or WHISPER or "Whisper"
				info.notCheckable = true
				info.func = Whisper
				UIDropDownMenu_AddButton(info, level)

				info = UIDropDownMenu_CreateInfo()
				info.text = (L and L.GUILD_ACTION_INVITE_PARTY) or PARTY_INVITE or "Invite"
				info.notCheckable = true
				info.func = InviteToGroup
				UIDropDownMenu_AddButton(info, level)
			end

			if fullName then
				local DB = BFL:GetModule("DB")
				local currentNick = DB and DB:GetGuildNickname(fullName) or ""
				info = UIDropDownMenu_CreateInfo()
				info.text = currentNick ~= ""
					and (L.GUILD_BROKER_MENU_EDIT_NICKNAME or "Edit Nickname")
					or (L.GUILD_BROKER_MENU_SET_NICKNAME or "Set Nickname")
				info.notCheckable = true
				info.func = ShowNicknameDialog
				UIDropDownMenu_AddButton(info, level)
			end

			info = UIDropDownMenu_CreateInfo()
			info.text = (L and L.GUILD_ACTION_COPY_NAME) or "Copy Name"
			info.notCheckable = true
			info.func = ShowCopyName
			UIDropDownMenu_AddButton(info, level)

		end, "MENU")

		ToggleDropDownMenu(1, nil, self.GuildMemberDropdown, button, 0, 0)
	end
end
