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
	SORT_OPTIONS[6].text = STATUS or "Status"
	SORT_OPTIONS[7].text = LASTONLINE or "Last Online"
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return false
	end
	return pcall(fn, ...)
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

local function RefreshGuildSurfacesSoon(requestRoster)
	if C_Timer and C_Timer.After then
		C_Timer.After(0.25, function()
			RefreshGuildSurfaces(requestRoster)
		end)
	else
		RefreshGuildSurfaces(requestRoster)
	end
end

local function SetMenuElementEnabled(element, enabled)
	if not element then
		return
	end
	if element.SetEnabled then
		element:SetEnabled(enabled)
	else
		element.enabled = enabled
	end
end

local function FormatIcon(icon, size)
	size = size or 16
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

function GuildActions:GetMemberGUID(member)
	if not member then
		return nil, self:GetMemberRankOrder(member)
	end

	if IsUsableString(member.guid) then
		return member.guid, self:GetMemberRankOrder(member)
	end

	local targetName = self:GetFullName(member)
	if not IsUsableString(targetName) then
		return nil, self:GetMemberRankOrder(member)
	end

	if not (C_Club and C_Club.GetGuildClubId and C_Club.GetClubMembers and C_Club.GetMemberInfo) then
		return nil, self:GetMemberRankOrder(member)
	end

	local okClubId, clubId = SafeCall(C_Club.GetGuildClubId)
	if not okClubId or not clubId then
		return nil, self:GetMemberRankOrder(member)
	end

	local okMembers, members = SafeCall(C_Club.GetClubMembers, clubId)
	if not okMembers or type(members) ~= "table" then
		return nil, self:GetMemberRankOrder(member)
	end

	local normalizedTarget = NormalizeName(targetName)
	for _, memberId in ipairs(members) do
		local okInfo, info = SafeCall(C_Club.GetMemberInfo, clubId, memberId)
		if okInfo and info and IsUsableString(info.name) and NormalizeName(info.name) == normalizedTarget then
			local rankOrder = tonumber(info.guildRankOrder) or self:GetMemberRankOrder(member)
			if IsUsableString(info.guid) then
				return info.guid, rankOrder
			end
			return nil, rankOrder
		end
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

function GuildActions:GetSelfRankOrder()
	if GetGuildInfo then
		local ok, _, _, rankIndex = SafeCall(GetGuildInfo, "player")
		if ok and type(rankIndex) == "number" then
			return rankIndex + 1
		end
	end

	if C_Club and C_Club.GetGuildClubId and C_Club.GetMemberInfoForSelf then
		local okClubId, clubId = SafeCall(C_Club.GetGuildClubId)
		if okClubId and clubId then
			local okInfo, info = SafeCall(C_Club.GetMemberInfoForSelf, clubId)
			if okInfo and info and type(info.guildRankOrder) == "number" then
				return info.guildRankOrder
			end
		end
	end

	return nil
end

function GuildActions:GetRankName(rankOrder)
	return string.format("%s %d", RANK or "Rank", rankOrder or 0)
end

function GuildActions:IsRankAssignmentAllowed(member, rankOrder)
	local guid = self:GetMemberGUID(member)
	if C_GuildInfo and C_GuildInfo.IsGuildRankAssignmentAllowed and IsUsableString(guid) then
		local ok, allowed = SafeCall(C_GuildInfo.IsGuildRankAssignmentAllowed, guid, rankOrder)
		if ok then
			return allowed == true
		end
	end

	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	if not currentRankOrder or not selfRankOrder or not rankOrder then
		return false
	end
	if rankOrder == currentRankOrder then
		return true
	end
	if self:IsSelf(member) then
		return false
	end
	if rankOrder < currentRankOrder then
		return (CanGuildPromote and CanGuildPromote() == true) and rankOrder > selfRankOrder
	end
	return (CanGuildDemote and CanGuildDemote() == true) and currentRankOrder > selfRankOrder
end

function GuildActions:CanPromote(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	return CanGuildPromote
		and CanGuildPromote() == true
		and C_GuildInfo
		and C_GuildInfo.Promote
		and currentRankOrder
		and selfRankOrder
		and currentRankOrder > selfRankOrder + 1
		and not self:IsSelf(member)
		and self:IsRankAssignmentAllowed(member, currentRankOrder - 1)
end

function GuildActions:CanDemote(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	return CanGuildDemote
		and CanGuildDemote() == true
		and C_GuildInfo
		and C_GuildInfo.Demote
		and currentRankOrder
		and selfRankOrder
		and currentRankOrder > selfRankOrder
		and not self:IsSelf(member)
		and self:IsRankAssignmentAllowed(member, currentRankOrder + 1)
end

function GuildActions:CanRemoveMember(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	return CanGuildRemove
		and CanGuildRemove() == true
		and IsUsableString(self:GetFullName(member))
		and ((C_GuildInfo and C_GuildInfo.Uninvite) or GuildUninvite)
		and currentRankOrder
		and selfRankOrder
		and currentRankOrder > selfRankOrder
		and not self:IsSelf(member)
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

function GuildActions:CanEditMOTD()
	return IsClassicGuildFlavor()
		and CanEditMOTD
		and CanEditMOTD() == true
		and StaticPopup_Show
		and StaticPopupDialogs
		and StaticPopupDialogs["SET_GUILDMOTD"] ~= nil
end

function GuildActions:GetMemberCapabilities(member)
	local hasName = IsUsableString(self:GetFullName(member))
	local online = member and member.online == true
	return {
		whisper = hasName and online,
		inviteParty = self:CanInviteParty(member),
		who = hasName,
		nickname = hasName,
		copyName = hasName,
		promote = self:CanPromote(member),
		demote = self:CanDemote(member),
		remove = self:CanRemoveMember(member),
		setLeader = self:CanSetLeader(member),
	}
end

function GuildActions:GetGuildCapabilities()
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

function GuildActions:Who(member)
	local fullName = self:GetFullName(member)
	if not fullName then
		return
	end
	if C_FriendList and C_FriendList.SendWho then
		pcall(C_FriendList.SendWho, fullName)
	elseif SendWho then
		pcall(SendWho, fullName)
	end
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

function GuildActions:SetRank(member, rankOrder)
	rankOrder = tonumber(rankOrder)
	if not member or not rankOrder then
		return
	end
	if not self:IsActionReady() then
		return
	end
	if not self:IsRankAssignmentAllowed(member, rankOrder) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end

	local currentRankOrder = self:GetMemberRankOrder(member)
	if currentRankOrder == rankOrder then
		return
	end

	local fullName = self:GetFullName(member)
	local isPromote = rankOrder == currentRankOrder - 1
	local isDemote = rankOrder == currentRankOrder + 1
	if not (IsUsableString(fullName) and (isPromote or isDemote)) then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
		return
	end

	local targetRankName = self:GetRankName(rankOrder)
	local dialogKey = "BFL_GUILD_SET_RANK"

	StaticPopupDialogs[dialogKey] = {
		text = string.format(T("GUILD_SET_RANK_CONFIRM", "Set %s to %s?"), self:GetDisplayName(member), targetRankName),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if isPromote and C_GuildInfo and C_GuildInfo.Promote then
				C_GuildInfo.Promote(fullName)
				RefreshGuildSurfacesSoon(true)
			elseif isDemote and C_GuildInfo and C_GuildInfo.Demote then
				C_GuildInfo.Demote(fullName)
				RefreshGuildSurfacesSoon(true)
			else
				ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
			end
		end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show(dialogKey)
end

function GuildActions:PromoteMember(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	if currentRankOrder and self:CanPromote(member) then
		self:SetRank(member, currentRankOrder - 1)
	else
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
	end
end

function GuildActions:DemoteMember(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	if currentRankOrder and self:CanDemote(member) then
		self:SetRank(member, currentRankOrder + 1)
	else
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
	end
end

function GuildActions:RemoveMember(member)
	if not self:CanRemoveMember(member) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	local fullName = self:GetFullName(member)
	if not IsUsableString(fullName) then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
		return
	end

	StaticPopupDialogs["BFL_GUILD_REMOVE_MEMBER"] = {
		text = string.format(T("GUILD_REMOVE_CONFIRM", "Remove %s from the guild?"), self:GetDisplayName(member)),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if IsUsableString(fullName) and C_GuildInfo and C_GuildInfo.Uninvite then
				C_GuildInfo.Uninvite(fullName)
			elseif IsUsableString(fullName) and GuildUninvite then
				GuildUninvite(fullName)
			else
				ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
			end
			RefreshGuildSurfacesSoon(true)
		end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BFL_GUILD_REMOVE_MEMBER")
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

function GuildActions:PopulateMemberMenu(rootDescription, member)
	rootDescription:CreateTitle(self:GetDisplayName(member))
	local caps = self:GetMemberCapabilities(member)

	local hasCommunication = false
	if caps.whisper then
		rootDescription:CreateButton(T("GUILD_ACTION_WHISPER", WHISPER or "Whisper"), function()
			self:Whisper(member)
		end)
		hasCommunication = true
	end
	if caps.inviteParty then
		rootDescription:CreateButton(T("GUILD_ACTION_INVITE_PARTY", PARTY_INVITE or "Invite"), function()
			self:InviteParty(member)
		end)
		hasCommunication = true
	end
	if caps.who then
		rootDescription:CreateButton(T("GUILD_BROKER_MENU_WHO", WHO or "Who"), function()
			self:Who(member)
		end)
		hasCommunication = true
	end

	if hasCommunication then
		rootDescription:CreateDivider()
	end

	if caps.nickname or caps.copyName then
		local DB = BFL:GetModule("DB")
		local currentNick = DB and DB:GetGuildNickname(self:GetFullName(member)) or ""
		if caps.nickname then
			local nickLabel = currentNick ~= "" and T("GUILD_BROKER_MENU_EDIT_NICKNAME", "Edit Nickname")
				or T("GUILD_BROKER_MENU_SET_NICKNAME", "Set Nickname")
			rootDescription:CreateButton(nickLabel, function()
				self:SetNicknameDialog(member)
			end)
		end
		if caps.copyName then
			rootDescription:CreateButton(T("GUILD_ACTION_COPY_NAME", "Copy Name"), function()
				self:CopyName(member)
			end)
		end
	end

	local hasManagement = false
	if caps.promote then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_PROMOTE", "Promote"), function()
			self:PromoteMember(member)
		end)
	end
	if caps.demote then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_DEMOTE", "Demote"), function()
			self:DemoteMember(member)
		end)
	end
	if caps.remove then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_REMOVE", "Remove from Guild"), function()
			self:RemoveMember(member)
		end)
	end
	if caps.setLeader then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_SET_LEADER", "Set Guild Leader"), function()
			self:SetLeader(member)
		end)
	end
end

function GuildActions:AddClassicMemberMenuButtons(member, level)
	level = level or 1
	local caps = self:GetMemberCapabilities(member)

	local function AddButton(text, func, disabled)
		local info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.notCheckable = true
		info.disabled = disabled
		info.func = func
		UIDropDownMenu_AddButton(info, level)
	end

	if caps.whisper then
		AddButton(T("GUILD_ACTION_WHISPER", WHISPER or "Whisper"), function()
			self:Whisper(member)
		end)
	end
	if caps.inviteParty then
		AddButton(T("GUILD_ACTION_INVITE_PARTY", PARTY_INVITE or "Invite"), function()
			self:InviteParty(member)
		end)
	end
	if caps.who then
		AddButton(T("GUILD_BROKER_MENU_WHO", WHO or "Who"), function()
			self:Who(member)
		end)
	end
	if caps.nickname then
		AddButton(T("GUILD_BROKER_MENU_SET_NICKNAME", "Set Nickname"), function()
			self:SetNicknameDialog(member)
		end)
	end
	if caps.copyName then
		AddButton(T("GUILD_ACTION_COPY_NAME", "Copy Name"), function()
			self:CopyName(member)
		end)
	end

	if caps.promote then
		AddButton(T("GUILD_ACTION_PROMOTE", "Promote"), function()
			self:PromoteMember(member)
		end)
	end
	if caps.demote then
		AddButton(T("GUILD_ACTION_DEMOTE", "Demote"), function()
			self:DemoteMember(member)
		end)
	end
	if caps.remove then
		AddButton(T("GUILD_ACTION_REMOVE", "Remove from Guild"), function()
			self:RemoveMember(member)
		end)
	end
	if caps.setLeader then
		AddButton(T("GUILD_ACTION_SET_LEADER", "Set Guild Leader"), function()
			self:SetLeader(member)
		end)
	end
end

function GuildActions:PopulateGuildActionsMenu(rootDescription)
	rootDescription:CreateTitle(T("GUILD_ACTIONS_MENU", "Guild Actions"))
	local caps = self:GetGuildCapabilities()

	local inviteItem = rootDescription:CreateButton(T("GUILD_ACTION_INVITE_TO_GUILD", "Invite to Guild"), function()
		self:InviteToGuild()
	end)
	SetMenuElementEnabled(inviteItem, caps.invite)

	if caps.editMOTD then
		rootDescription:CreateButton(T("GUILD_ACTION_EDIT_MOTD", "Edit MOTD"), function()
			self:EditMOTD()
		end)
	end

	rootDescription:CreateDivider()
	if caps.leave then
		rootDescription:CreateButton(T("GUILD_ACTION_LEAVE_GUILD", "Leave Guild"), function()
			self:LeaveGuild()
		end)
	end
	if caps.disband then
		rootDescription:CreateButton(T("GUILD_ACTION_DISBAND_GUILD", "Disband Guild"), function()
			self:DisbandGuild()
		end)
	end
end

function GuildActions:ShowGuildActionsMenu(owner)
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(owner or UIParent, function(_, rootDescription)
			self:PopulateGuildActionsMenu(rootDescription)
		end)
		return
	end

	if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then
		return
	end

	if not self.GuildActionsDropdown then
		self.GuildActionsDropdown = CreateFrame("Frame", "BFL_GuildActionsDropdown", UIParent, "UIDropDownMenuTemplate")
	end

	UIDropDownMenu_Initialize(self.GuildActionsDropdown, function(_, level)
		local function AddButton(text, func, disabled)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.notCheckable = true
			info.disabled = disabled
			info.func = func
			UIDropDownMenu_AddButton(info, level)
		end

		local info = UIDropDownMenu_CreateInfo()
		info.text = T("GUILD_ACTIONS_MENU", "Guild Actions")
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		local caps = self:GetGuildCapabilities()

		AddButton(T("GUILD_ACTION_INVITE_TO_GUILD", "Invite to Guild"), function()
			self:InviteToGuild()
		end, not caps.invite)
		if caps.editMOTD then
			AddButton(T("GUILD_ACTION_EDIT_MOTD", "Edit MOTD"), function()
				self:EditMOTD()
			end)
		end
		if caps.leave then
			AddButton(T("GUILD_ACTION_LEAVE_GUILD", "Leave Guild"), function()
				self:LeaveGuild()
			end)
		end
		if caps.disband then
			AddButton(T("GUILD_ACTION_DISBAND_GUILD", "Disband Guild"), function()
				self:DisbandGuild()
			end)
		end
	end, "MENU")

	ToggleDropDownMenu(1, nil, self.GuildActionsDropdown, owner or "cursor", 0, 0)
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
