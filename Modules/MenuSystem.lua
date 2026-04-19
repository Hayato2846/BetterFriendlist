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

	-- Set flag to indicate this menu is opened from BetterFriendlist
	_G.BetterFriendlist_IsOurMenu = true

	-- Use compatibility wrapper for Classic support
	-- Flag is cleared by AddGroupsToFriendMenu callback (fires during menu construction)
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
	}

	-- Use FRIEND menu as base (compatibility wrapper for Classic)
	BFL.OpenContextMenu(button, "FRIEND", contextData, contextData.name)

	-- Clear flag immediately after opening
	self:SetWhoPlayerMenuFlag(false)
end

-- Open context menu for a guild member (from Guild Tab)
function MenuSystem:ShowGuildMemberMenu(button, member)
	if not button or not member then return end

	local L = BFL.L
	local fullName = member.fullName
	local displayName = Ambiguate(fullName, "guild")

	-- Helper: confirm-and-execute via StaticPopup
	local function ShowConfirm(dialogKey, text, onAccept)
		StaticPopupDialogs[dialogKey] = {
			text = text,
			button1 = ACCEPT or "Accept",
			button2 = CANCEL or "Cancel",
			OnAccept = onAccept,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
		StaticPopup_Show(dialogKey)
	end

	-- Helper: remove confirmation requires typing the member name
	local function ShowRemoveConfirm()
		local key = "BFL_GUILD_UNINVITE_CONFIRM"
		StaticPopupDialogs[key] = {
			text = format((L and L.GUILD_CONFIRM_REMOVE)
				or "Type %s to confirm removing this member from the guild:", displayName),
			button1 = ACCEPT or "Accept",
			button2 = CANCEL or "Cancel",
			hasEditBox = 1,
			editBoxWidth = 240,
			OnShow = function(self)
				self.editBox:SetText("")
				self.editBox:SetFocus()
				self.button1:Disable()
			end,
			EditBoxOnTextChanged = function(self)
				local parent = self:GetParent()
				if self:GetText() == displayName then
					parent.button1:Enable()
				else
					parent.button1:Disable()
				end
			end,
			OnAccept = function(self)
				if self.editBox:GetText() == displayName and GuildUninvite then
					GuildUninvite(fullName)
				end
			end,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
		StaticPopup_Show(key)
	end

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

	if MenuUtil and MenuUtil.CreateContextMenu then
		-- Retail: Modern menu
		MenuUtil.CreateContextMenu(button, function(owner, rootDescription)
			rootDescription:CreateTitle(displayName)

			-- View Member Info Panel
			rootDescription:CreateButton((L and L.GUILD_ACTION_OPEN_INFO) or "View Member Info", function()
				local GuildFrame = BFL:GetModule("GuildFrame")
				if GuildFrame then GuildFrame:ShowMemberInfoPanel(member) end
			end)

			rootDescription:CreateDivider()

			-- Communication
			if member.online and fullName then
				rootDescription:CreateButton((L and L.GUILD_ACTION_WHISPER) or WHISPER or "Whisper", function()
					local whisperName = fullName:gsub(" ", "")
					BFL:SecureSendTell(whisperName)
				end)
				rootDescription:CreateButton((L and L.GUILD_ACTION_INVITE_PARTY) or PARTY_INVITE or "Invite", function()
					BFL.InviteUnit(fullName)
				end)
			end

			-- Management (remove only; rank changes now live in the Member Info panel)
			local canRemove = CanGuildRemove and CanGuildRemove() or false
			if canRemove then
				rootDescription:CreateDivider()
				rootDescription:CreateButton((L and L.GUILD_ACTION_REMOVE) or "Remove from Guild", function()
					ShowRemoveConfirm()
				end)
			end

			rootDescription:CreateDivider()

			-- BFL: Nickname + Note editing
			if fullName then
				local DB = BFL:GetModule("DB")
				local currentNick = DB and DB:GetGuildNickname(fullName) or ""
				local nickLabel = currentNick ~= ""
					and (L.GUILD_BROKER_MENU_EDIT_NICKNAME or "Edit Nickname")
					or (L.GUILD_BROKER_MENU_SET_NICKNAME or "Set Nickname")
				rootDescription:CreateButton(nickLabel, function()
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
							if newNick and newNick:trim() ~= "" then
								DB:SetGuildNickname(fullName, newNick:trim())
								local GuildFrame = BFL:GetModule("GuildFrame")
								if GuildFrame then GuildFrame:Refresh() end
								local GuildBroker = BFL:GetModule("GuildBroker")
								if GuildBroker and GuildBroker.RefreshTooltip then GuildBroker:RefreshTooltip() end
							end
						end,
						OnAlt = function()
							DB:SetGuildNickname(fullName, nil)
							local GuildFrame = BFL:GetModule("GuildFrame")
							if GuildFrame then GuildFrame:Refresh() end
							local GuildBroker = BFL:GetModule("GuildBroker")
							if GuildBroker and GuildBroker.RefreshTooltip then GuildBroker:RefreshTooltip() end
						end,
						EditBoxOnEnterPressed = function(self)
							local parent = self:GetParent()
							local newNick = parent.EditBox:GetText()
							if newNick and newNick:trim() ~= "" then
								DB:SetGuildNickname(fullName, newNick:trim())
								local GuildFrame = BFL:GetModule("GuildFrame")
								if GuildFrame then GuildFrame:Refresh() end
								local GuildBroker = BFL:GetModule("GuildBroker")
								if GuildBroker and GuildBroker.RefreshTooltip then GuildBroker:RefreshTooltip() end
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
				end)
			end

			if CanEditPublicNote and CanEditPublicNote() and member.guildIndex then
				rootDescription:CreateButton(L.GUILD_BROKER_MENU_EDIT_NOTE or "Edit Note", function()
					SetGuildRosterSelection(member.guildIndex)
					StaticPopup_Show("SET_GUILDPLAYERNOTE")
				end)
			end

			if C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote() then
				if CanEditOfficerNote and CanEditOfficerNote() and member.guildIndex then
					rootDescription:CreateButton(L.GUILD_BROKER_MENU_EDIT_OFFICER_NOTE or "Edit Officer Note", function()
						SetGuildRosterSelection(member.guildIndex)
						StaticPopup_Show("SET_GUILDOFFICERNOTE")
					end)
				end
			end

			rootDescription:CreateDivider()

			-- System
			rootDescription:CreateButton((L and L.GUILD_ACTION_COPY_NAME) or "Copy Name", function()
				ShowCopyName()
			end)
			rootDescription:CreateButton((L and L.GUILD_ACTION_OPEN_BLIZZARD) or "Open in Guild UI", function()
				local GuildFrame = BFL:GetModule("GuildFrame")
				if GuildFrame then GuildFrame:OpenBlizzardGuildUI(member.guildIndex) end
			end)
		end)
	elseif BFL.OpenContextMenu then
		-- Classic fallback: delegate to native Guild member dropdown
		if member.guildIndex then
			SetGuildRosterSelection(member.guildIndex)
		end
		if UIDROPDOWNMENU_INIT_MENU then
			ToggleDropDownMenu(1, nil, _G["GuildMemberDropDown"], "cursor", 0, 0)
		end
	end
end
