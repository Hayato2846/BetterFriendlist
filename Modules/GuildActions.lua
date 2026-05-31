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

function GuildActions:GetNumRanks()
	if GuildControlGetNumRanks then
		local ok, numRanks = SafeCall(GuildControlGetNumRanks)
		if ok and type(numRanks) == "number" then
			return numRanks
		end
	end
	return 0
end

function GuildActions:GetRankName(rankOrder)
	if GuildControlGetRankName and type(rankOrder) == "number" then
		local ok, name = SafeCall(GuildControlGetRankName, rankOrder)
		if ok and IsUsableString(name) then
			return name
		end
	end
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

function GuildActions:GetRankOptions(member)
	local options = {}
	local numRanks = self:GetNumRanks()
	if numRanks <= 0 then
		return options
	end

	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	local canPromote = CanGuildPromote and CanGuildPromote() == true
	local canDemote = CanGuildDemote and CanGuildDemote() == true

	local highest = currentRankOrder or 1
	local lowest = currentRankOrder or numRanks
	if canPromote and selfRankOrder then
		highest = selfRankOrder + 1
	end
	if canDemote then
		lowest = numRanks
	end

	for rankOrder = 1, numRanks do
		local inRange = rankOrder >= highest and rankOrder <= lowest
		local enabled = inRange and self:IsRankAssignmentAllowed(member, rankOrder)
		options[#options + 1] = {
			rankOrder = rankOrder,
			text = string.format("%d. %s", rankOrder, self:GetRankName(rankOrder)),
			selected = rankOrder == currentRankOrder,
			enabled = enabled,
		}
	end

	return options
end

function GuildActions:CanPromote(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	return CanGuildPromote
		and CanGuildPromote() == true
		and currentRankOrder
		and selfRankOrder
		and currentRankOrder > selfRankOrder + 1
		and not self:IsSelf(member)
		and self:IsRankAssignmentAllowed(member, currentRankOrder - 1)
end

function GuildActions:CanDemote(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	local numRanks = self:GetNumRanks()
	return CanGuildDemote
		and CanGuildDemote() == true
		and currentRankOrder
		and selfRankOrder
		and numRanks > 0
		and currentRankOrder < numRanks
		and currentRankOrder > selfRankOrder
		and not self:IsSelf(member)
		and self:IsRankAssignmentAllowed(member, currentRankOrder + 1)
end

function GuildActions:CanRemoveMember(member)
	local currentRankOrder = self:GetMemberRankOrder(member)
	local selfRankOrder = self:GetSelfRankOrder()
	return CanGuildRemove
		and CanGuildRemove() == true
		and currentRankOrder
		and selfRankOrder
		and currentRankOrder > selfRankOrder
		and not self:IsSelf(member)
end

function GuildActions:CanSetLeader(member)
	return IsGuildLeader
		and IsGuildLeader() == true
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

function GuildActions:CanEditPublicNote(member)
	if not member then
		return false
	end
	if self:IsSelf(member) then
		return true
	end
	return CanEditPublicNote and CanEditPublicNote() == true
end

function GuildActions:CanViewOfficerNote()
	if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then
		local ok, result = SafeCall(C_GuildInfo.CanViewOfficerNote)
		return ok and result == true
	end
	return false
end

function GuildActions:CanEditOfficerNote()
	if C_GuildInfo and C_GuildInfo.CanEditOfficerNote then
		local ok, result = SafeCall(C_GuildInfo.CanEditOfficerNote)
		return ok and result == true
	end
	return false
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

	StaticPopupDialogs["BFL_GUILD_COPY_NAME"] = {
		text = T("GUILD_COPY_NAME_TITLE", "Copy Name"),
		button1 = CLOSE or OKAY or "Close",
		hasEditBox = true,
		editBoxWidth = 300,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(copyText)
				editBox:HighlightText()
				editBox:SetFocus()
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
	StaticPopup_Show("BFL_GUILD_COPY_NAME")
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

function GuildActions:EditNote(member, isPublic)
	if isPublic then
		if not self:CanEditPublicNote(member) then
			ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
			return
		end
	else
		if not self:CanViewOfficerNote() or not self:CanEditOfficerNote() then
			ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
			return
		end
	end

	if not self:IsActionReady() then
		return
	end

	local guid = self:GetMemberGUID(member)
	if not IsUsableString(guid) or not (C_GuildInfo and C_GuildInfo.SetNote) then
		if member and member.index and SetGuildRosterSelection then
			SetGuildRosterSelection(member.index)
			StaticPopup_Show(isPublic and "SET_GUILDPLAYERNOTE" or "SET_GUILDOFFICERNOTE")
		end
		return
	end

	local currentNote = isPublic and (member.note or "") or (member.officerNote or "")
	local dialogKey = "BFL_GUILD_EDIT_NOTE"
	StaticPopupDialogs[dialogKey] = {
		text = string.format(
			isPublic and T("GUILD_EDIT_PUBLIC_NOTE_TITLE", "Public note for %s")
				or T("GUILD_EDIT_OFFICER_NOTE_TITLE", "Officer note for %s"),
			self:GetDisplayName(member)
		),
		button1 = SAVE or ACCEPT or "Save",
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 280,
		maxLetters = 31,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(currentNote)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetEditBox(dialog)
			local newNote = editBox and editBox:GetText() or ""
			C_GuildInfo.SetNote(guid, newNote, isPublic == true)
			RefreshGuildSurfacesSoon(true)
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			C_GuildInfo.SetNote(guid, editBox:GetText() or "", isPublic == true)
			RefreshGuildSurfacesSoon(true)
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
	StaticPopup_Show(dialogKey)
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

	local guid = self:GetMemberGUID(member)
	local fullName = self:GetFullName(member)
	local targetRankName = self:GetRankName(rankOrder)
	local dialogKey = "BFL_GUILD_SET_RANK"

	StaticPopupDialogs[dialogKey] = {
		text = string.format(T("GUILD_SET_RANK_CONFIRM", "Set %s to %s?"), self:GetDisplayName(member), targetRankName),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if IsUsableString(guid) and C_GuildInfo and C_GuildInfo.SetGuildRankOrder then
				C_GuildInfo.SetGuildRankOrder(guid, rankOrder)
			elseif fullName and currentRankOrder and C_GuildInfo then
				if rankOrder == currentRankOrder - 1 and C_GuildInfo.Promote then
					C_GuildInfo.Promote(fullName)
				elseif rankOrder == currentRankOrder + 1 and C_GuildInfo.Demote then
					C_GuildInfo.Demote(fullName)
				end
			end
			RefreshGuildSurfacesSoon(true)
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

	local guid = self:GetMemberGUID(member)
	local fullName = self:GetFullName(member)
	if not IsUsableString(guid) and not IsUsableString(fullName) then
		ShowActionMessage("GUILD_ACTION_RESTRICTED", "This action is not available right now.")
		return
	end

	StaticPopupDialogs["BFL_GUILD_REMOVE_MEMBER"] = {
		text = string.format(T("GUILD_REMOVE_CONFIRM", "Remove %s from the guild?"), self:GetDisplayName(member)),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if IsUsableString(guid) and C_GuildInfo and C_GuildInfo.RemoveFromGuild then
				C_GuildInfo.RemoveFromGuild(guid)
			elseif IsUsableString(fullName) and C_GuildInfo and C_GuildInfo.Uninvite then
				C_GuildInfo.Uninvite(fullName)
			elseif IsUsableString(fullName) and GuildUninvite then
				GuildUninvite(fullName)
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

local function GetGuildMOTD()
	if BFL.GetGuildMOTD then
		local ok, motd = SafeCall(BFL.GetGuildMOTD)
		if ok and not IsSecretValue(motd) then
			return tostring(motd or "")
		end
	end
	return ""
end

function GuildActions:EditMOTD()
	if not (CanEditMOTD and CanEditMOTD() == true) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	local current = GetGuildMOTD()
	StaticPopupDialogs["BFL_GUILD_EDIT_MOTD"] = {
		text = T("GUILD_EDIT_MOTD_TITLE", "Edit guild MOTD"),
		button1 = SAVE or ACCEPT or "Save",
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 320,
		maxLetters = 255,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(current)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetEditBox(dialog)
			local motd = editBox and editBox:GetText() or ""
			if C_GuildInfo and C_GuildInfo.SetMOTD then
				C_GuildInfo.SetMOTD(motd)
			elseif GuildSetMOTD then
				GuildSetMOTD(motd)
			elseif SetGuildRosterMOTD then
				SetGuildRosterMOTD(motd)
			end
			if BFL.CacheGuildMOTD then
				BFL.CacheGuildMOTD(motd)
			end
			RefreshGuildSurfacesSoon(true)
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			local motd = editBox:GetText() or ""
			if C_GuildInfo and C_GuildInfo.SetMOTD then
				C_GuildInfo.SetMOTD(motd)
			elseif GuildSetMOTD then
				GuildSetMOTD(motd)
			elseif SetGuildRosterMOTD then
				SetGuildRosterMOTD(motd)
			end
			if BFL.CacheGuildMOTD then
				BFL.CacheGuildMOTD(motd)
			end
			RefreshGuildSurfacesSoon(true)
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
	StaticPopup_Show("BFL_GUILD_EDIT_MOTD")
end

function GuildActions:EditGuildInfo()
	if not (CanEditGuildInfo and CanEditGuildInfo() == true) then
		ShowActionMessage("GUILD_ACTION_NO_PERMISSION", "You do not have permission to do this.")
		return
	end
	if not self:IsActionReady() then
		return
	end

	local current = ""
	if C_GuildInfo and C_GuildInfo.GetInfoText then
		local ok, text = SafeCall(C_GuildInfo.GetInfoText)
		current = (ok and not IsSecretValue(text)) and tostring(text or "") or ""
	elseif GetGuildInfoText then
		local ok, text = SafeCall(GetGuildInfoText)
		current = (ok and not IsSecretValue(text)) and tostring(text or "") or ""
	end

	StaticPopupDialogs["BFL_GUILD_EDIT_INFO"] = {
		text = T("GUILD_EDIT_INFO_TITLE", "Edit guild information"),
		button1 = SAVE or ACCEPT or "Save",
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 360,
		maxLetters = 500,
		OnShow = function(dialog)
			local editBox = GetEditBox(dialog)
			if editBox then
				editBox:SetText(current)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetEditBox(dialog)
			local text = editBox and editBox:GetText() or ""
			if C_GuildInfo and C_GuildInfo.SetInfoText then
				C_GuildInfo.SetInfoText(text)
			elseif SetGuildInfoText then
				SetGuildInfoText(text)
			end
			RefreshGuildSurfacesSoon(true)
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			local text = editBox:GetText() or ""
			if C_GuildInfo and C_GuildInfo.SetInfoText then
				C_GuildInfo.SetInfoText(text)
			elseif SetGuildInfoText then
				SetGuildInfoText(text)
			end
			RefreshGuildSurfacesSoon(true)
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
	StaticPopup_Show("BFL_GUILD_EDIT_INFO")
end

function GuildActions:OpenBlizzardGuildUI()
	if not self:IsActionReady() then
		return
	end
	local toggle = ToggleGuildFrame or GuildFrame_Toggle
	if toggle then
		pcall(toggle)
	end
end

function GuildActions:OpenGuildControl()
	if not self:IsActionReady() then
		return
	end
	self:OpenBlizzardGuildUI()

	local loadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
	if loadAddOn then
		pcall(loadAddOn, "Blizzard_GuildControlUI")
	end
	if GuildControlUI_OpenRanks then
		pcall(GuildControlUI_OpenRanks)
	elseif GuildControlUI and GuildControlUI.Show then
		GuildControlUI:Show()
	end
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
	return {
		{ value = FILTER_ONLINE, text = T("GUILD_FILTER_ONLINE", FRIENDS_LIST_ONLINE or "Online"), icon = FILTER_ICONS.online },
		{ value = FILTER_ALL, text = T("GUILD_FILTER_ALL", ALL or "All"), icon = FILTER_ICONS.all },
		{ value = FILTER_OFFLINE, text = T("GUILD_FILTER_OFFLINE", FRIENDS_LIST_OFFLINE or "Offline"), icon = FILTER_ICONS.offline },
	}
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
	return {
		{ value = SORT_RANK, text = RANK or "Rank", icon = SORT_ICONS.rank },
		{ value = SORT_NAME, text = NAME or "Name", icon = SORT_ICONS.name },
		{ value = SORT_LEVEL, text = LEVEL or "Level", icon = SORT_ICONS.level },
		{ value = SORT_CLASS, text = CLASS or "Class", icon = SORT_ICONS.class },
		{ value = SORT_ZONE, text = ZONE or "Zone", icon = SORT_ICONS.zone },
		{ value = SORT_STATUS, text = STATUS or "Status", icon = SORT_ICONS.status },
		{ value = SORT_LAST_ONLINE, text = LASTONLINE or "Last Online", icon = SORT_ICONS.lastonline },
	}
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

	local hasCommunication = false
	if member.online and IsUsableString(self:GetFullName(member)) then
		rootDescription:CreateButton(T("GUILD_ACTION_WHISPER", WHISPER or "Whisper"), function()
			self:Whisper(member)
		end)
		hasCommunication = true
	end
	if self:CanInviteParty(member) then
		rootDescription:CreateButton(T("GUILD_ACTION_INVITE_PARTY", PARTY_INVITE or "Invite"), function()
			self:InviteParty(member)
		end)
		hasCommunication = true
	end
	if IsUsableString(self:GetFullName(member)) then
		rootDescription:CreateButton(T("GUILD_BROKER_MENU_WHO", WHO or "Who"), function()
			self:Who(member)
		end)
		hasCommunication = true
	end

	if hasCommunication then
		rootDescription:CreateDivider()
	end

	if IsUsableString(self:GetFullName(member)) then
		local DB = BFL:GetModule("DB")
		local currentNick = DB and DB:GetGuildNickname(self:GetFullName(member)) or ""
		local nickLabel = currentNick ~= "" and T("GUILD_BROKER_MENU_EDIT_NICKNAME", "Edit Nickname")
			or T("GUILD_BROKER_MENU_SET_NICKNAME", "Set Nickname")
		rootDescription:CreateButton(nickLabel, function()
			self:SetNicknameDialog(member)
		end)
		rootDescription:CreateButton(T("GUILD_ACTION_COPY_NAME", "Copy Name"), function()
			self:CopyName(member)
		end)
	end

	local hasNotes = false
	if self:CanEditPublicNote(member) then
		if not hasNotes then
			rootDescription:CreateDivider()
			hasNotes = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_EDIT_PUBLIC_NOTE", "Edit Public Note"), function()
			self:EditNote(member, true)
		end)
	end
	if self:CanViewOfficerNote() and self:CanEditOfficerNote() then
		if not hasNotes then
			rootDescription:CreateDivider()
			hasNotes = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_EDIT_OFFICER_NOTE", "Edit Officer Note"), function()
			self:EditNote(member, false)
		end)
	end

	local hasManagement = false
	local rankOptions = self:GetRankOptions(member)
	if #rankOptions > 0 then
		rootDescription:CreateDivider()
		hasManagement = true
		local rankMenu = rootDescription:CreateButton(T("GUILD_ACTION_SET_RANK", "Set Rank"))
		for _, option in ipairs(rankOptions) do
			local rankItem = rankMenu:CreateRadio(option.text, function(rankOrder)
				return self:GetMemberRankOrder(member) == rankOrder
			end, function(rankOrder)
				self:SetRank(member, rankOrder)
			end, option.rankOrder)
			SetMenuElementEnabled(rankItem, option.enabled)
		end
	end
	if self:CanPromote(member) then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_PROMOTE", "Promote"), function()
			self:PromoteMember(member)
		end)
	end
	if self:CanDemote(member) then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_DEMOTE", "Demote"), function()
			self:DemoteMember(member)
		end)
	end
	if self:CanRemoveMember(member) then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_REMOVE", "Remove from Guild"), function()
			self:RemoveMember(member)
		end)
	end
	if self:CanSetLeader(member) then
		if not hasManagement then
			rootDescription:CreateDivider()
			hasManagement = true
		end
		rootDescription:CreateButton(T("GUILD_ACTION_SET_LEADER", "Set Guild Leader"), function()
			self:SetLeader(member)
		end)
	end

	rootDescription:CreateDivider()
	rootDescription:CreateButton(T("GUILD_ACTION_OPEN_BLIZZARD", "Open in Guild UI"), function()
		self:OpenBlizzardGuildUI()
	end)
end

function GuildActions:AddClassicMemberMenuButtons(member, level)
	level = level or 1
	if level == 2 and UIDROPDOWNMENU_MENU_VALUE == "BFL_GUILD_RANKS" then
		for _, option in ipairs(self:GetRankOptions(member)) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.text
			info.value = option.rankOrder
			info.checked = option.selected
			info.disabled = not option.enabled
			info.func = function(menuButton)
				self:SetRank(member, menuButton.value)
			end
			UIDropDownMenu_AddButton(info, level)
		end
		return
	end

	local function AddButton(text, func, disabled)
		local info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.notCheckable = true
		info.disabled = disabled
		info.func = func
		UIDropDownMenu_AddButton(info, level)
	end

	if member.online and IsUsableString(self:GetFullName(member)) then
		AddButton(T("GUILD_ACTION_WHISPER", WHISPER or "Whisper"), function()
			self:Whisper(member)
		end)
	end
	AddButton(T("GUILD_ACTION_INVITE_PARTY", PARTY_INVITE or "Invite"), function()
		self:InviteParty(member)
	end, not self:CanInviteParty(member))
	if IsUsableString(self:GetFullName(member)) then
		AddButton(T("GUILD_BROKER_MENU_WHO", WHO or "Who"), function()
			self:Who(member)
		end)
		AddButton(T("GUILD_BROKER_MENU_SET_NICKNAME", "Set Nickname"), function()
			self:SetNicknameDialog(member)
		end)
		AddButton(T("GUILD_ACTION_COPY_NAME", "Copy Name"), function()
			self:CopyName(member)
		end)
	end

	if self:CanEditPublicNote(member) then
		AddButton(T("GUILD_ACTION_EDIT_PUBLIC_NOTE", "Edit Public Note"), function()
			self:EditNote(member, true)
		end)
	end
	if self:CanViewOfficerNote() and self:CanEditOfficerNote() then
		AddButton(T("GUILD_ACTION_EDIT_OFFICER_NOTE", "Edit Officer Note"), function()
			self:EditNote(member, false)
		end)
	end

	if #self:GetRankOptions(member) > 0 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = T("GUILD_ACTION_SET_RANK", "Set Rank")
		info.notCheckable = true
		info.hasArrow = true
		info.menuList = "BFL_GUILD_RANKS"
		UIDropDownMenu_AddButton(info, level)
	end
	AddButton(T("GUILD_ACTION_PROMOTE", "Promote"), function()
		self:PromoteMember(member)
	end, not self:CanPromote(member))
	AddButton(T("GUILD_ACTION_DEMOTE", "Demote"), function()
		self:DemoteMember(member)
	end, not self:CanDemote(member))
	AddButton(T("GUILD_ACTION_REMOVE", "Remove from Guild"), function()
		self:RemoveMember(member)
	end, not self:CanRemoveMember(member))
	if self:CanSetLeader(member) then
		AddButton(T("GUILD_ACTION_SET_LEADER", "Set Guild Leader"), function()
			self:SetLeader(member)
		end)
	end
	AddButton(T("GUILD_ACTION_OPEN_BLIZZARD", "Open in Guild UI"), function()
		self:OpenBlizzardGuildUI()
	end)
end

function GuildActions:PopulateGuildActionsMenu(rootDescription)
	rootDescription:CreateTitle(T("GUILD_ACTIONS_MENU", "Guild Actions"))

	local inviteItem = rootDescription:CreateButton(T("GUILD_ACTION_INVITE_TO_GUILD", "Invite to Guild"), function()
		self:InviteToGuild()
	end)
	SetMenuElementEnabled(inviteItem, CanGuildInvite and CanGuildInvite() == true)

	local motdItem = rootDescription:CreateButton(T("GUILD_ACTION_EDIT_MOTD", "Edit MOTD"), function()
		self:EditMOTD()
	end)
	SetMenuElementEnabled(motdItem, CanEditMOTD and CanEditMOTD() == true)

	local infoItem = rootDescription:CreateButton(T("GUILD_ACTION_EDIT_INFO", "Edit Guild Info"), function()
		self:EditGuildInfo()
	end)
	SetMenuElementEnabled(infoItem, CanEditGuildInfo and CanEditGuildInfo() == true)

	rootDescription:CreateDivider()
	rootDescription:CreateButton(T("GUILD_ACTION_OPEN_BLIZZARD", "Open in Guild UI"), function()
		self:OpenBlizzardGuildUI()
	end)
	rootDescription:CreateButton(T("GUILD_ACTION_GUILD_CONTROL", "Guild Control"), function()
		self:OpenGuildControl()
	end)

	rootDescription:CreateDivider()
	if not (IsGuildLeader and IsGuildLeader() == true) then
		rootDescription:CreateButton(T("GUILD_ACTION_LEAVE_GUILD", "Leave Guild"), function()
			self:LeaveGuild()
		end)
	end
	if IsGuildLeader and IsGuildLeader() == true then
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
		self:OpenBlizzardGuildUI()
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

		AddButton(T("GUILD_ACTION_INVITE_TO_GUILD", "Invite to Guild"), function()
			self:InviteToGuild()
		end, not (CanGuildInvite and CanGuildInvite() == true))
		AddButton(T("GUILD_ACTION_EDIT_MOTD", "Edit MOTD"), function()
			self:EditMOTD()
		end, not (CanEditMOTD and CanEditMOTD() == true))
		AddButton(T("GUILD_ACTION_EDIT_INFO", "Edit Guild Info"), function()
			self:EditGuildInfo()
		end, not (CanEditGuildInfo and CanEditGuildInfo() == true))
		AddButton(T("GUILD_ACTION_OPEN_BLIZZARD", "Open in Guild UI"), function()
			self:OpenBlizzardGuildUI()
		end)
		AddButton(T("GUILD_ACTION_GUILD_CONTROL", "Guild Control"), function()
			self:OpenGuildControl()
		end)
		if not (IsGuildLeader and IsGuildLeader() == true) then
			AddButton(T("GUILD_ACTION_LEAVE_GUILD", "Leave Guild"), function()
				self:LeaveGuild()
			end)
		else
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
