-- Modules/GuildActions.lua
-- Centralized guild roster/member actions shared by GuildFrame, GuildBroker, and menus.

local ADDON_NAME, BFL = ...

local GuildActions = BFL:RegisterModule("GuildActions", {})

local FILTER_ALL = "all"
local FILTER_ONLINE = "online"
local FILTER_OFFLINE = "offline"

local SORT_NAME = "name"
local SORT_RANK = "rank"
local SORT_LEVEL = "level"
local SORT_CLASS = "class"
local SORT_ZONE = "zone"
local SORT_LAST_ONLINE = "lastonline"
local SORT_STATUS = "status"
local SORT_NICKNAME = "nickname"

local ICON_ROOT = "Interface\\AddOns\\BetterFriendlist\\Icons\\"
local FILTER_ICONS = {
	all = ICON_ROOT .. "filter-all.blp",
	online = ICON_ROOT .. "filter-online.blp",
	offline = ICON_ROOT .. "filter-offline.blp",
}
local SORT_ICONS = {
	name = ICON_ROOT .. "name.blp",
	rank = ICON_ROOT .. "guild.blp",
	level = ICON_ROOT .. "level.blp",
	class = ICON_ROOT .. "class.blp",
	zone = ICON_ROOT .. "zone.blp",
	status = ICON_ROOT .. "status.blp",
	lastonline = ICON_ROOT .. "clock.blp",
	nickname = ICON_ROOT .. "tag.blp",
}

local function T(key, fallback)
	return (BFL.L and BFL.L[key]) or fallback or key
end

local FILTER_OPTIONS = {
	{ value = FILTER_ONLINE, icon = FILTER_ICONS.online },
	{ value = FILTER_ALL, icon = FILTER_ICONS.all },
	{ value = FILTER_OFFLINE, icon = FILTER_ICONS.offline },
}

local SORT_OPTIONS = {
	{ value = SORT_RANK, icon = SORT_ICONS.rank },
	{ value = SORT_NAME, icon = SORT_ICONS.name },
	{ value = SORT_LEVEL, icon = SORT_ICONS.level },
	{ value = SORT_CLASS, icon = SORT_ICONS.class },
	{ value = SORT_ZONE, icon = SORT_ICONS.zone },
	{ value = SORT_NICKNAME, icon = SORT_ICONS.nickname },
	{ value = SORT_STATUS, icon = SORT_ICONS.status },
	{ value = SORT_LAST_ONLINE, icon = SORT_ICONS.lastonline },
}

local function RefreshFilterOptionText()
	FILTER_OPTIONS[1].text = T("GUILD_FILTER_ONLINE", FRIENDS_LIST_ONLINE or "Online")
	FILTER_OPTIONS[2].text = T("GUILD_FILTER_ALL", ALL or "All")
	FILTER_OPTIONS[3].text = T("GUILD_FILTER_OFFLINE", FRIENDS_LIST_OFFLINE or "Offline")
end

local function RefreshSortOptionText()
	SORT_OPTIONS[1].text = RANK or "Rank"
	SORT_OPTIONS[2].text = NAME or "Name"
	SORT_OPTIONS[3].text = LEVEL or "Level"
	SORT_OPTIONS[4].text = CLASS or "Class"
	SORT_OPTIONS[5].text = ZONE or "Zone"
	SORT_OPTIONS[6].text = T("GUILD_NICKNAME", "Nickname")
	SORT_OPTIONS[7].text = STATUS or "Status"
	SORT_OPTIONS[8].text = LASTONLINE or "Last Online"
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return false
	end
	return pcall(fn, ...)
end

local function IsGuildPreviewActive()
	local PreviewMode = BFL:GetModule("PreviewMode")
	return PreviewMode
		and PreviewMode.IsComponentEnabled
		and PreviewMode:IsComponentEnabled("guild")
		or false
end

local function IsSecretValue(value)
	return value ~= nil and BFL.HasSecretValues and BFL.IsSecret and BFL:IsSecret(value)
end

local function IsUsableString(value)
	return type(value) == "string" and value ~= "" and value ~= "Unknown" and not IsSecretValue(value)
end

local function IsClassicGuildFlavor()
	return BFL.IsClassic == true
		or BFL.IsClassicEra == true
		or BFL.IsMoPClassic == true
		or BFL.IsCataClassic == true
end

local function Trim(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetEditBox(dialog)
	if not dialog then
		return nil
	end
	if dialog.GetEditBox then
		local ok, editBox = pcall(dialog.GetEditBox, dialog)
		if ok and editBox then
			return editBox
		end
	end
	return dialog.EditBox or dialog.editBox
end

local function NormalizeName(name)
	if not IsUsableString(name) then
		return nil
	end
	name = name:gsub("%s+", "")
	if not name:find("-", 1, true) then
		local realm = GetNormalizedRealmName and GetNormalizedRealmName()
		if IsUsableString(realm) then
			name = name .. "-" .. realm
		end
	end
	return name:lower()
end

local function GetFullPlayerName()
	if UnitFullName then
		local name, realm = UnitFullName("player")
		if IsUsableString(name) then
			if IsUsableString(realm) then
				return name .. "-" .. realm
			end
			local normalizedRealm = GetNormalizedRealmName and GetNormalizedRealmName()
			if IsUsableString(normalizedRealm) then
				return name .. "-" .. normalizedRealm
			end
			return name
		end
	end
	return UnitName and UnitName("player") or nil
end

local function ShowActionMessage(key, fallback)
	local message = T(key, fallback)
	if not message or message == "" then
		return
	end
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage(message, 1, 0.1, 0.1)
	elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd200BetterFriendlist:|r " .. message)
	end
end

local function RefreshGuildSurfaces(requestRoster)
	local GuildFrame = BFL:GetModule("GuildFrame")
	if requestRoster and GuildFrame and GuildFrame.RequestRosterUpdate then
		GuildFrame:RequestRosterUpdate()
	end
	if GuildFrame and GuildFrame.Refresh then
		GuildFrame:Refresh()
	end

	local GuildBroker = BFL:GetModule("GuildBroker")
	if GuildBroker then
		if GuildBroker.InvalidateCache then
			GuildBroker:InvalidateCache()
		end
		if GuildBroker.UpdateBrokerText then
			GuildBroker:UpdateBrokerText()
		end
		if GuildBroker.RefreshTooltip then
			GuildBroker:RefreshTooltip()
		end
	end
end

local function FormatIcon(icon, size)
	size = size or 16
	if BFL.FormatIcon then
		return BFL.FormatIcon(icon or ICON_ROOT .. "guild.blp", size)
	end
	return string.format("|T%s:%d:%d:0:0|t", icon or ICON_ROOT .. "guild.blp", size, size)
end

local function FormatIconText(icon, text, size)
	return FormatIcon(icon, size or 16) .. " " .. (text or "")
end

function GuildActions:Initialize()
	-- No eager state. This module is intentionally a late-bound API facade.
end

function GuildActions:GetFullName(member)
	if not member then
		return nil
	end
	local fullName = member.fullName or member.name
	if IsUsableString(fullName) then
		return fullName:gsub("%s+", "")
	end
	return nil
end

function GuildActions:GetDisplayName(member)
	local fullName = self:GetFullName(member)
	local displayName = fullName or (member and member.name) or UNKNOWN or "Unknown"
	if Ambiguate and IsUsableString(displayName) then
		return Ambiguate(displayName, "guild")
	end
	return displayName
end

function GuildActions:IsSelf(member)
	local memberName = self:GetFullName(member)
	local playerName = GetFullPlayerName()
	local normalizedMember = NormalizeName(memberName) or NormalizeName(member and member.name)
	local normalizedPlayer = NormalizeName(playerName)
	return normalizedMember ~= nil and normalizedMember == normalizedPlayer
end

function GuildActions:IsActionReady()
	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
		return false
	end
	return true
end

function GuildActions:GetGuildClubMemberInfo(member)
	if not member then
		return nil, nil
	end
	if not (C_Club and C_Club.GetGuildClubId and C_Club.GetClubMembers and C_Club.GetMemberInfo) then
		return nil, nil
	end

	local okClubId, clubId = SafeCall(C_Club.GetGuildClubId)
	if not okClubId or not clubId then
		return nil, nil
	end

	if member.memberId then
		local okInfo, info = SafeCall(C_Club.GetMemberInfo, clubId, member.memberId)
		if okInfo and info then
			return clubId, info
		end
	end

	local okMembers, members = SafeCall(C_Club.GetClubMembers, clubId)
	if not okMembers or type(members) ~= "table" then
		return clubId, nil
	end

	local targetGUID = IsUsableString(member.guid) and member.guid or nil
	local normalizedTarget = NormalizeName(self:GetFullName(member)) or NormalizeName(member.name)
	for _, memberId in ipairs(members) do
		local okInfo, info = SafeCall(C_Club.GetMemberInfo, clubId, memberId)
		if okInfo and info then
			local guidMatches = targetGUID and IsUsableString(info.guid) and info.guid == targetGUID
			local nameMatches = normalizedTarget and IsUsableString(info.name) and NormalizeName(info.name) == normalizedTarget
			if guidMatches or nameMatches then
				return clubId, info
			end
		end
	end

	return clubId, nil
end

function GuildActions:GetMemberGUID(member)
	if not member then
		return nil, self:GetMemberRankOrder(member)
	end

	if IsUsableString(member.guid) then
		return member.guid, self:GetMemberRankOrder(member)
	end

	local _, info = self:GetGuildClubMemberInfo(member)
	if info then
		return IsUsableString(info.guid) and info.guid or nil,
			tonumber(info.guildRankOrder) or self:GetMemberRankOrder(member)
	end

	return nil, self:GetMemberRankOrder(member)
end

function GuildActions:GetMemberRankOrder(member)
	if not member then
		return nil
	end
	if type(member.guildRankOrder) == "number" then
		return member.guildRankOrder
	end
	if type(member.rankOrder) == "number" then
		return member.rankOrder
	end
	if type(member.rankIndex) == "number" then
		return member.rankIndex + 1
	end
	return nil
end

function GuildActions:CanSetLeader(member)
	return IsGuildLeader
		and IsGuildLeader() == true
		and ((C_GuildInfo and C_GuildInfo.SetLeader) or (StaticPopupDialogs and StaticPopupDialogs.CONFIRM_GUILD_PROMOTE))
		and member
		and not self:IsSelf(member)
		and IsUsableString(self:GetFullName(member))
end

function GuildActions:CanInviteParty(member)
	return member
		and member.online == true
		and member.isMobile ~= true
		and not self:IsSelf(member)
		and IsUsableString(self:GetFullName(member))
		and BFL.InviteUnit ~= nil
		and not (BFL.IsActionRestricted and BFL:IsActionRestricted())
end

function GuildActions:CanViewOfficerNote()
	if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then
		local ok, result = SafeCall(C_GuildInfo.CanViewOfficerNote)
		return ok and result == true
	end
	return false
end

function GuildActions:IsCharacterFriend(member)
	local guid = member and member.guid
	if C_FriendList and C_FriendList.IsFriend and IsUsableString(guid) then
		local ok, result = SafeCall(C_FriendList.IsFriend, guid)
		if ok then
			return result == true
		end
	end

	local fullName = self:GetFullName(member)
	if C_FriendList and C_FriendList.GetFriendInfo and IsUsableString(fullName) then
		local ok, info = SafeCall(C_FriendList.GetFriendInfo, fullName)
		return ok and info ~= nil
	end
	return false
end

function GuildActions:IsIgnored(member)
	local fullName = self:GetFullName(member)
	if C_FriendList and C_FriendList.IsOnIgnoredList and IsUsableString(fullName) then
		local ok, result = SafeCall(C_FriendList.IsOnIgnoredList, fullName)
		return ok and result == true
	end
	return false
end

function GuildActions:CanEditMOTD()
	return IsClassicGuildFlavor()
		and CanEditMOTD
		and CanEditMOTD() == true
		and StaticPopup_Show
		and StaticPopupDialogs
		and StaticPopupDialogs["SET_GUILDMOTD"] ~= nil
end

function GuildActions:GetMemberCapabilities(member)
	if member and member._isMock then
		return {
			whisper = false,
			inviteParty = false,
			addFriend = false,
			toggleIgnore = false,
			viewHouses = false,
			viewRecipes = false,
			nickname = false,
			copyName = true,
			setLeader = false,
		}
	end

	local hasName = IsUsableString(self:GetFullName(member))
	local online = member and member.online == true
	return {
		whisper = hasName and online,
		inviteParty = self:CanInviteParty(member),
		addFriend = hasName
			and not self:IsSelf(member)
			and C_FriendList
			and type(C_FriendList.AddFriend) == "function"
			and not self:IsCharacterFriend(member),
		toggleIgnore = hasName
			and not self:IsSelf(member)
			and C_FriendList
			and type(C_FriendList.AddOrDelIgnore) == "function",
		viewHouses = hasName
			and not IsClassicGuildFlavor()
			and UNIT_VIEW_HOUSES ~= nil
			and C_AddOns
			and type(C_AddOns.LoadAddOn) == "function",
		viewRecipes = hasName
			and IsUsableString(member and member.guid)
			and C_GuildInfo
			and type(C_GuildInfo.QueryGuildMemberRecipes) == "function"
			and ((tonumber(member and member.profession1ID) or 0) > 0
				or (tonumber(member and member.profession2ID) or 0) > 0),
		nickname = hasName,
		copyName = hasName,
		setLeader = self:CanSetLeader(member),
	}
end

function GuildActions:GetGuildCapabilities()
	if IsGuildPreviewActive() then
		return {
			invite = false,
			editMOTD = false,
			leave = false,
			disband = false,
		}
	end

	local isLeader = IsGuildLeader and IsGuildLeader() == true
	local inGuild = true
	if IsInGuild then
		local ok, result = SafeCall(IsInGuild)
		inGuild = ok and result == true
	end
	local canInviteAPI = ((C_GuildInfo and C_GuildInfo.Invite) or GuildInvite) ~= nil
	local canLeaveAPI = StaticPopup_Show ~= nil or (C_GuildInfo and C_GuildInfo.Leave) ~= nil
	local canDisbandAPI = StaticPopup_Show ~= nil or (C_GuildInfo and C_GuildInfo.Disband) ~= nil
	return {
		invite = inGuild and CanGuildInvite and CanGuildInvite() == true and canInviteAPI,
		editMOTD = self:CanEditMOTD(),
		leave = inGuild and not isLeader and canLeaveAPI,
		disband = inGuild and isLeader and canDisbandAPI,
	}
end

function GuildActions:Whisper(member)
	local fullName = self:GetFullName(member)
	if fullName and BFL.SecureSendTell then
		BFL:SecureSendTell(fullName)
	end
end

function GuildActions:InviteParty(member)
	if self:CanInviteParty(member) then
		BFL.InviteUnit(self:GetFullName(member))
	end
end

function GuildActions:AddCharacterFriend(member)
	local fullName = self:GetFullName(member)
	if not (IsUsableString(fullName) and C_FriendList and C_FriendList.AddFriend) then
		return
	end
	if self:IsSelf(member) or self:IsCharacterFriend(member) or not self:IsActionReady() then
		return
	end
	SafeCall(C_FriendList.AddFriend, fullName)
end

function GuildActions:ToggleIgnore(member)
	local fullName = self:GetFullName(member)
	if not (IsUsableString(fullName) and C_FriendList and C_FriendList.AddOrDelIgnore) then
		return
	end
	if self:IsSelf(member) or not self:IsActionReady() then
		return
	end
	SafeCall(C_FriendList.AddOrDelIgnore, fullName)
end

function GuildActions:ViewHouses(member)
	if not self:IsActionReady() then
		return
	end

	local fullName = self:GetFullName(member)
	local guid = self:GetMemberGUID(member)
	if not HouseListFrame and C_AddOns and C_AddOns.LoadAddOn then
		SafeCall(C_AddOns.LoadAddOn, "Blizzard_HouseList")
	end
	if HouseListFrame and HouseListFrame.InitWithContextData and IsUsableString(fullName) then
		if ShowUIPanel then
			ShowUIPanel(HouseListFrame)
		else
			HouseListFrame:Show()
		end
		HouseListFrame:InitWithContextData(fullName, guid, nil, true)
	else
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
	end
end

function GuildActions:QueryMemberRecipes(member, professionID)
	professionID = tonumber(professionID)
	if not professionID or professionID <= 0 then
		return false
	end
	if not (C_GuildInfo and type(C_GuildInfo.QueryGuildMemberRecipes) == "function") then
		return false
	end
	if not self:IsActionReady() then
		return false
	end

	local guid = self:GetMemberGUID(member)
	if not IsUsableString(guid) then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
		return false
	end
	local ok = SafeCall(C_GuildInfo.QueryGuildMemberRecipes, guid, professionID)
	if not ok then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
	end
	return ok == true
end

function GuildActions:CopyName(member)
	local copyText = self:GetFullName(member) or (member and member.name) or ""
	if copyText == "" then
		return
	end

	local editBoxWidth = 300
	StaticPopupDialogs["BFL_GUILD_COPY_NAME"] = {
		text = T("GUILD_COPY_NAME_TITLE", "Copy Name"),
		button1 = CLOSE or OKAY or "Close",
		hasEditBox = true,
		editBoxWidth = editBoxWidth,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(copyText)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			if BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
				BFL.BrokerUtils.FixCopyStaticPopupLayout(dialog, editBoxWidth)
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	local dialog = StaticPopup_Show("BFL_GUILD_COPY_NAME")
	if dialog and BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
		BFL.BrokerUtils.FixCopyStaticPopupLayout(dialog, editBoxWidth)
	end
end

function GuildActions:SetNicknameDialog(member)
	local fullName = self:GetFullName(member)
	if not fullName then
		return
	end

	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local currentNick = DB:GetGuildNickname(fullName) or ""
	local displayName = self:GetDisplayName(member)
	StaticPopupDialogs["BFL_GUILD_SET_NICKNAME"] = {
		text = string.format(T("GUILD_BROKER_NICKNAME_PROMPT", "Enter a nickname for %s:"), displayName),
		button1 = ACCEPT,
		button2 = CANCEL,
		button3 = currentNick ~= "" and T("GUILD_BROKER_MENU_REMOVE_NICKNAME", "Remove") or nil,
		hasEditBox = true,
		editBoxWidth = 250,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(currentNick)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetEditBox(dialog)
			local newNick = editBox and Trim(editBox:GetText()) or ""
			DB:SetGuildNickname(fullName, newNick ~= "" and newNick or nil)
			RefreshGuildSurfaces(false)
		end,
		OnAlt = function()
			DB:SetGuildNickname(fullName, nil)
			RefreshGuildSurfaces(false)
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			local newNick = Trim(editBox:GetText())
			DB:SetGuildNickname(fullName, newNick ~= "" and newNick or nil)
			RefreshGuildSurfaces(false)
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BFL_GUILD_SET_NICKNAME")
end

function GuildActions:SetLeader(member)
	if not self:CanSetLeader(member) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	local fullName = self:GetFullName(member)
	if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs.CONFIRM_GUILD_PROMOTE then
		StaticPopup_Show("CONFIRM_GUILD_PROMOTE", fullName, nil, fullName)
	elseif C_GuildInfo and C_GuildInfo.SetLeader then
		C_GuildInfo.SetLeader(fullName)
	end
end

function GuildActions:InviteToGuild()
	if not (CanGuildInvite and CanGuildInvite() == true) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	StaticPopupDialogs["BFL_GUILD_INVITE_PLAYER"] = {
		text = T("GUILD_INVITE_PLAYER_TITLE", "Invite player to guild"),
		button1 = T("GUILD_INVITE_BUTTON", "Invite"),
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 240,
		maxLetters = 60,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText("")
				editBox:SetFocus()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetEditBox(dialog)
			local name = editBox and Trim(editBox:GetText()) or ""
			if name ~= "" then
				if C_GuildInfo and C_GuildInfo.Invite then
					C_GuildInfo.Invite(name)
				elseif GuildInvite then
					GuildInvite(name)
				end
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			local name = Trim(editBox:GetText())
			if name ~= "" then
				if C_GuildInfo and C_GuildInfo.Invite then
					C_GuildInfo.Invite(name)
				elseif GuildInvite then
					GuildInvite(name)
				end
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BFL_GUILD_INVITE_PLAYER")
end

function GuildActions:EditMOTD()
	if not self:CanEditMOTD() then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	StaticPopup_Show("SET_GUILDMOTD")
end

function GuildActions:LeaveGuild()
	if not self:IsActionReady() then
		return
	end
	if StaticPopup_Show then
		local guildName = GetGuildInfo and select(2, SafeCall(GetGuildInfo, "player")) or nil
		StaticPopup_Show("CONFIRM_GUILD_LEAVE", guildName)
	elseif C_GuildInfo and C_GuildInfo.Leave then
		C_GuildInfo.Leave()
	end
end

function GuildActions:DisbandGuild()
	if not self:IsActionReady() then
		return
	end
	if not (IsGuildLeader and IsGuildLeader() == true) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if StaticPopup_Show then
		StaticPopup_Show("CONFIRM_GUILD_DISBAND")
	elseif C_GuildInfo and C_GuildInfo.Disband then
		C_GuildInfo.Disband()
	end
end

function GuildActions:GetFilterOptions()
	RefreshFilterOptionText()
	return FILTER_OPTIONS
end

function GuildActions:GetFilterLabel(mode)
	for _, option in ipairs(self:GetFilterOptions()) do
		if option.value == mode then
			return option.text
		end
	end
	return T("GUILD_FILTER_ONLINE", "Online")
end

function GuildActions:GetFilterIcon(mode)
	return FILTER_ICONS[mode or FILTER_ONLINE] or FILTER_ICONS.online
end

function GuildActions:GetSortOptions()
	RefreshSortOptionText()
	return SORT_OPTIONS
end

function GuildActions:GetSortLabel(mode)
	for _, option in ipairs(self:GetSortOptions()) do
		if option.value == mode then
			return option.text
		end
	end
	return RANK or "Rank"
end

function GuildActions:GetSortIcon(mode)
	return SORT_ICONS[mode or SORT_RANK] or SORT_ICONS.rank
end

function GuildActions:PopulateFilterMenu(rootDescription)
	if BFL.PopulateSimpleMenu then
		BFL.PopulateSimpleMenu(rootDescription, function()
			return self:GetFilterMenuItems()
		end)
		return
	end

	local GuildFrame = BFL:GetModule("GuildFrame")
	local function IsSelected(mode)
		return GuildFrame and GuildFrame.filterMode == mode
	end
	local function SetSelected(mode)
		if GuildFrame and GuildFrame.SetFilter then
			GuildFrame:SetFilter(mode)
			if GuildFrame.RefreshHeaderControls then
				GuildFrame:RefreshHeaderControls()
			end
		end
	end

	for _, option in ipairs(self:GetFilterOptions()) do
		rootDescription:CreateRadio(FormatIconText(option.icon, option.text, 16), IsSelected, SetSelected, option.value)
	end
end

function GuildActions:PopulateSortMenu(rootDescription)
	if BFL.PopulateSimpleMenu then
		BFL.PopulateSimpleMenu(rootDescription, function()
			return self:GetSortMenuItems()
		end)
		return
	end

	local GuildFrame = BFL:GetModule("GuildFrame")
	local function IsSelected(mode)
		return GuildFrame and GuildFrame.sortMode == mode
	end
	local function SetSelected(mode)
		if GuildFrame and GuildFrame.SetSort then
			GuildFrame:SetSort(mode, true)
			if GuildFrame.RefreshHeaderControls then
				GuildFrame:RefreshHeaderControls()
			end
		end
	end

	for _, option in ipairs(self:GetSortOptions()) do
		rootDescription:CreateRadio(FormatIconText(option.icon, option.text, 16), IsSelected, SetSelected, option.value)
	end
end

function GuildActions:GetFilterMenuItems()
	local GuildFrame = BFL:GetModule("GuildFrame")
	local function IsSelected(mode)
		return GuildFrame and GuildFrame.filterMode == mode
	end
	local function SetSelected(mode)
		if GuildFrame and GuildFrame.SetFilter then
			GuildFrame:SetFilter(mode)
			if GuildFrame.RefreshHeaderControls then
				GuildFrame:RefreshHeaderControls()
			end
		end
	end

	local items = {}
	for _, option in ipairs(self:GetFilterOptions()) do
		items[#items + 1] = {
			type = "radio",
			text = FormatIconText(option.icon, option.text, 16),
			value = option.value,
			checked = IsSelected,
			func = SetSelected,
		}
	end
	return items
end

function GuildActions:GetSortMenuItems()
	local GuildFrame = BFL:GetModule("GuildFrame")
	local function IsSelected(mode)
		return GuildFrame and GuildFrame.sortMode == mode
	end
	local function SetSelected(mode)
		if GuildFrame and GuildFrame.SetSort then
			GuildFrame:SetSort(mode, true)
			if GuildFrame.RefreshHeaderControls then
				GuildFrame:RefreshHeaderControls()
			end
		end
	end

	local items = {}
	for _, option in ipairs(self:GetSortOptions()) do
		items[#items + 1] = {
			type = "radio",
			text = FormatIconText(option.icon, option.text, 16),
			value = option.value,
			checked = IsSelected,
			func = SetSelected,
		}
	end
	return items
end

function GuildActions:GetMemberMenuItems(member)
	local caps = self:GetMemberCapabilities(member)
	local items = {
		{
			type = "title",
			text = self:GetDisplayName(member),
		},
	}

	local hasCommunication = false
	if caps.whisper then
		table.insert(items, {
			text = T("GUILD_ACTION_WHISPER", WHISPER or "Whisper"),
			func = function()
				self:Whisper(member)
			end,
		})
		hasCommunication = true
	end
	if caps.inviteParty then
		table.insert(items, {
			text = T("GUILD_ACTION_INVITE_PARTY", PARTY_INVITE or "Invite"),
			func = function()
				self:InviteParty(member)
			end,
		})
		hasCommunication = true
	end
	if caps.addFriend then
		table.insert(items, {
			text = ADD_FRIEND or "Add Friend",
			func = function()
				self:AddCharacterFriend(member)
			end,
		})
		hasCommunication = true
	end
	if caps.toggleIgnore then
		table.insert(items, {
			text = self:IsIgnored(member) and (IGNORE_REMOVE or "Remove Ignore") or (IGNORE or "Ignore"),
			func = function()
				self:ToggleIgnore(member)
			end,
		})
		hasCommunication = true
	end

	if hasCommunication then
		table.insert(items, { type = "divider" })
	end

	if caps.viewHouses or caps.viewRecipes or caps.nickname or caps.copyName then
		if caps.viewHouses then
			table.insert(items, {
				text = UNIT_VIEW_HOUSES or "View Houses",
				func = function()
					self:ViewHouses(member)
				end,
			})
		end
		if caps.viewRecipes then
			for slot = 1, 2 do
				local professionID = tonumber(member["profession" .. slot .. "ID"])
				local professionName = member["profession" .. slot .. "Name"]
				if professionID and professionID > 0 then
					table.insert(items, {
						text = string.format(
							T("GUILD_PROFESSION_VIEW_RECIPES", "View %s Recipes"),
							IsUsableString(professionName) and professionName or PROFESSIONS_COLUMN_LABEL or "Profession"
						),
						func = function()
							self:QueryMemberRecipes(member, professionID)
						end,
					})
				end
			end
		end
		local DB = BFL:GetModule("DB")
		local currentNick = DB and DB:GetGuildNickname(self:GetFullName(member)) or ""
		if caps.nickname then
			local nickLabel = currentNick ~= "" and T("GUILD_BROKER_MENU_EDIT_NICKNAME", "Edit Nickname")
				or T("GUILD_BROKER_MENU_SET_NICKNAME", "Set Nickname")
			table.insert(items, {
				text = nickLabel,
				func = function()
					self:SetNicknameDialog(member)
				end,
			})
		end
		if caps.copyName then
			table.insert(items, {
				text = T("GUILD_ACTION_COPY_NAME", "Copy Name"),
				func = function()
					self:CopyName(member)
				end,
			})
		end
	end

	local hasManagement = false
	local function AddManagementDivider()
		if not hasManagement then
			table.insert(items, { type = "divider" })
			hasManagement = true
		end
	end

	if caps.setLeader then
		AddManagementDivider()
		table.insert(items, {
			text = T("GUILD_ACTION_SET_LEADER", "Set Guild Leader"),
			func = function()
				self:SetLeader(member)
			end,
		})
	end

	return items
end

function GuildActions:PopulateMemberMenu(rootDescription, member)
	if BFL.PopulateSimpleMenu then
		BFL.PopulateSimpleMenu(rootDescription, function()
			return self:GetMemberMenuItems(member)
		end)
	end
end

function GuildActions:ShowMemberMenu(owner, member, name)
	if BFL.OpenSimpleContextMenu then
		return BFL.OpenSimpleContextMenu(owner or UIParent, name or "BFL_GuildMemberDropdown", function()
			return self:GetMemberMenuItems(member)
		end)
	end
	return false
end

function GuildActions:PopulateGuildActionsMenu(rootDescription)
	if BFL.PopulateSimpleMenu then
		BFL.PopulateSimpleMenu(rootDescription, function()
			return self:GetGuildActionsMenuItems()
		end)
	end
end

function GuildActions:GetGuildActionsMenuItems()
	local caps = self:GetGuildCapabilities()
	local items = {
		{
			type = "title",
			text = T("GUILD_ACTIONS_MENU", "Guild Actions"),
		},
		{
			text = T("GUILD_ACTION_INVITE_TO_GUILD", "Invite to Guild"),
			disabled = not caps.invite,
			func = function()
				self:InviteToGuild()
			end,
		},
	}

	if caps.editMOTD then
		table.insert(items, {
			text = T("GUILD_ACTION_EDIT_MOTD", "Edit MOTD"),
			func = function()
				self:EditMOTD()
			end,
		})
	end

	table.insert(items, { type = "divider" })
	if caps.leave then
		table.insert(items, {
			text = T("GUILD_ACTION_LEAVE_GUILD", "Leave Guild"),
			func = function()
				self:LeaveGuild()
			end,
		})
	end
	if caps.disband then
		table.insert(items, {
			text = T("GUILD_ACTION_DISBAND_GUILD", "Disband Guild"),
			func = function()
				self:DisbandGuild()
			end,
		})
	end
	return items
end

function GuildActions:ShowGuildActionsMenu(owner)
	if BFL.OpenSimpleContextMenu then
		return BFL.OpenSimpleContextMenu(owner or UIParent, "BFL_GuildActionsDropdown", function()
			return self:GetGuildActionsMenuItems()
		end)
	end
	return false
end

GuildActions.FILTER_ALL = FILTER_ALL
GuildActions.FILTER_ONLINE = FILTER_ONLINE
GuildActions.FILTER_OFFLINE = FILTER_OFFLINE
GuildActions.SORT_NAME = SORT_NAME
GuildActions.SORT_RANK = SORT_RANK
GuildActions.SORT_LEVEL = SORT_LEVEL
GuildActions.SORT_CLASS = SORT_CLASS
GuildActions.SORT_ZONE = SORT_ZONE
GuildActions.SORT_LAST_ONLINE = SORT_LAST_ONLINE
GuildActions.SORT_STATUS = SORT_STATUS

return GuildActions
