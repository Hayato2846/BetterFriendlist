-- Modules/GuildBroker.lua
-- Guild Data Broker Integration Module (LibQTip-2.0)
-- Displays guild members via LibDataBroker-1.1 for display addons (Bazooka, Arcana, TitanPanel)

local ADDON_NAME, BFL = ...

-- Register Module
local GuildBroker = BFL:RegisterModule("GuildBroker", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB()
	return BFL:GetModule("DB")
end

-- ========================================
-- Local Variables
-- ========================================
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LQT = BFL.QTip
local dataObject = nil
local updateThrottle = 0
local lastUpdateTime = 0
local THROTTLE_INTERVAL = 0.5 -- Guild data changes less frequently than friends

-- LibQTip tooltip references
local tooltip = nil
local tooltipKey = "BetterFriendlistGuildBrokerTT"
local previewData = nil
local detailTooltip = nil

local function ReleaseDetailTooltip()
	BFL.BrokerUtils.HideBrokerDetailTooltip(detailTooltip)
	detailTooltip = nil
end

-- Roster cache
local rosterCache = nil
local rosterCacheTime = 0
local ROSTER_CACHE_TTL = 2 -- seconds

-- Maximum tooltip height
local MAX_TOOLTIP_HEIGHT = 600
local MOTD_MAX_WIDTH = 520

-- ========================================
-- Shared Helpers from BrokerUtils
-- ========================================
local C = BFL.BrokerUtils.C
local GetStatusIcon = BFL.BrokerUtils.GetStatusIcon
local ClassColorTextByFile = BFL.BrokerUtils.ClassColorTextByFile
local GetClassIcon = BFL.BrokerUtils.GetClassIcon
local FormatLastOnline = BFL.BrokerUtils.FormatLastOnline
local IsMenuOpen = BFL.BrokerUtils.IsMenuOpen
local AddNameToEditBox = BFL.BrokerUtils.AddNameToEditBox
local AddTooltipSeparator = BFL.BrokerUtils.AddTooltipSeparator
local ApplyBrokerFooterSeparatorStyle = BFL.BrokerUtils.ApplyBrokerFooterSeparatorStyle
local ApplyBrokerFontToFontString = BFL.BrokerUtils.ApplyBrokerFontToFontString
local ApplyBrokerFontToTooltip = BFL.BrokerUtils.ApplyBrokerFontToTooltip

local function GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

-- Guild Finder applicant count cache
local applicantCount = 0
local lastApplicantRequestTime = 0
local APPLICANT_REQUEST_INTERVAL = 20

-- ========================================
-- Localization Helper
-- ========================================
local function L(key)
	if BFL.L and BFL.L[key] then
		return BFL.L[key]
	end
	return key
end

local function ShouldAvoidSecretValueGuildActions()
	return BFL.HasSecretValues
end

local function IsSecretValue(value)
	return BFL.HasSecretValues and BFL.IsSecret and BFL:IsSecret(value)
end

local function SafeText(value, fallback)
	if value == nil or IsSecretValue(value) then
		return fallback or ""
	end
	return value
end

local function SafeIsInGuild()
	if previewData and previewData.guildName then
		return true
	end

	if not IsInGuild then
		return false
	end

	local ok, result = pcall(IsInGuild)
	return ok and result or false
end

local function SafeGetGuildInfo()
	if previewData and previewData.guildName then
		return previewData.guildName
	end

	if not GetGuildInfo then
		return nil
	end

	local ok, guildName = pcall(GetGuildInfo, "player")
	if ok and not IsSecretValue(guildName) and guildName then
		return guildName
	end
	return nil
end

local function SafeGetGuildMOTD()
	if previewData then
		local previewMOTD = previewData.motd
		if not IsSecretValue(previewMOTD) and previewMOTD ~= nil then
			return tostring(previewMOTD):gsub("|n", "\n"):gsub("\\n", "\n")
		end
	end

	if not SafeIsInGuild() or not BFL.GetGuildMOTD then
		return ""
	end

	local ok, motd = pcall(BFL.GetGuildMOTD)
	if not ok or IsSecretValue(motd) or motd == nil then
		return ""
	end
	return tostring(motd)
end

local function NormalizeRosterName(name)
	if not name or name == "" then
		return nil
	end
	if IsSecretValue(name) then
		return nil
	end

	return (name:gsub("%s+", ""):lower())
end

local function GetProfessionIcon(professionID, size)
	if not professionID or not C_TradeSkillUI or not C_TradeSkillUI.GetTradeSkillTexture then
		return ""
	end

	local texture = C_TradeSkillUI.GetTradeSkillTexture(professionID)
	if not texture then
		return ""
	end

	size = size or 14
	return string.format("|T%s:%d:%d:0:0|t", tostring(texture), size, size)
end

local function FormatProfessionEntry(professionID, professionName, professionRank)
	if not professionID and (not professionName or professionName == "") then
		return ""
	end

	local icon = GetProfessionIcon(professionID)
	local text = icon ~= "" and icon or (professionName or "")
	if professionRank and professionRank > 1 then
		text = string.format("%s %d", text, professionRank)
	end

	return text
end

local function BuildGuildProfessionLookup()
	local lookup = {}

	if ShouldAvoidSecretValueGuildActions() then
		return lookup
	end

	if not C_Club or not C_Club.GetGuildClubId or not C_Club.GetClubMembers or not C_Club.GetMemberInfo then
		return lookup
	end

	local okClubId, clubId = pcall(C_Club.GetGuildClubId)
	if not okClubId or not clubId then
		return lookup
	end

	local okMembers, memberIds = pcall(C_Club.GetClubMembers, clubId)
	if not okMembers or not memberIds then
		return lookup
	end

	for _, memberId in ipairs(memberIds) do
		local okMemberInfo, memberInfo = pcall(C_Club.GetMemberInfo, clubId, memberId)
		if okMemberInfo and memberInfo and memberInfo.name then
			local professions = {}
			local firstProfession = FormatProfessionEntry(
				memberInfo.profession1ID,
				memberInfo.profession1Name,
				memberInfo.profession1Rank
			)
			local secondProfession = FormatProfessionEntry(
				memberInfo.profession2ID,
				memberInfo.profession2Name,
				memberInfo.profession2Rank
			)

			if firstProfession ~= "" then
				professions[#professions + 1] = firstProfession
			end
			if secondProfession ~= "" then
				professions[#professions + 1] = secondProfession
			end

			if #professions > 0 then
				local key = NormalizeRosterName(memberInfo.name)
				if key then
					lookup[key] = table.concat(professions, " ")
				end
			end
		end
	end

	return lookup
end

-- ========================================
-- Data Layer: Guild Roster Collection
-- ========================================

-- Collect and cache guild roster data
function GuildBroker:CollectGuildRoster()
	if previewData and previewData.members then
		return previewData.members
	end

	if not SafeIsInGuild() then
		rosterCache = nil
		return {}
	end

	-- Return cached data if still valid
	local now = GetTime()
	if rosterCache and (now - rosterCacheTime) < ROSTER_CACHE_TTL then
		return rosterCache
	end

	local maxRows = BetterFriendlistDB and BetterFriendlistDB.guildBrokerMaxRows or 100
	local GuildRosterData = BFL:GetModule("GuildRosterData")
	if GuildRosterData and GuildRosterData.CollectRoster and GuildRosterData:HasBaseRosterAPI() then
		local baseMembers = GuildRosterData:CollectRoster({ maxRows = maxRows })
		local professionLookup = BuildGuildProfessionLookup()
		local members = {}

		for _, baseMember in ipairs(baseMembers) do
			local member = {}
			for key, value in pairs(baseMember) do
				member[key] = value
			end
			member.professions = professionLookup[NormalizeRosterName(member.fullName)]
				or professionLookup[NormalizeRosterName(member.name)]
				or ""
			members[#members + 1] = member
		end

		rosterCache = members
		rosterCacheTime = now
		return members
	end

	if not GetNumGuildMembers then
		rosterCache = {}
		rosterCacheTime = now
		return rosterCache
	end

	local okCounts, numTotal = pcall(GetNumGuildMembers)
	if not okCounts or not numTotal or numTotal == 0 then
		rosterCache = {}
		rosterCacheTime = now
		return rosterCache
	end
	if not BFL.GetGuildRosterInfo then
		rosterCache = {}
		rosterCacheTime = now
		return rosterCache
	end

	local members = {}
	local professionLookup = BuildGuildProfessionLookup()

	for i = 1, numTotal do
		local okInfo, fullName, rank, rankIndex, level, className, zone, note, officerNote, online, status, classFile,
			achievementPoints, achievementRank, isMobile, isSoREligible, standingID = pcall(BFL.GetGuildRosterInfo, i)

		if okInfo and fullName then
			local safeFullName = SafeText(fullName, "Unknown")
			local name, realm
			if safeFullName == "Unknown" then
				name = "Unknown"
				realm = ""
			else
				name, realm = strsplit("-", safeFullName, 2)
			end
			local isAFK = (status == 1)
			local isDND = (status == 2)

			-- Last online time (only relevant for offline members)
			local lastYears, lastMonths, lastDays, lastHours = 0, 0, 0, 0
			if not online and BFL.GetGuildRosterLastOnline then
				local okLastOnline, years, months, days, hours = pcall(BFL.GetGuildRosterLastOnline, i)
				if okLastOnline then
					lastYears, lastMonths, lastDays, lastHours = years, months, days, hours
				end
			end

			local safeZone = SafeText(zone, "")
			local safeRank = SafeText(rank, "")
			local safeClassName = SafeText(className, "")
			local safeClassFile = SafeText(classFile, "")
			local safeNote = SafeText(note, "")
			local safeOfficerNote = SafeText(officerNote, "")

			local professionText = professionLookup[NormalizeRosterName(safeFullName)]
				or professionLookup[NormalizeRosterName(name)]
				or ""

			table.insert(members, {
				index = i,
				fullName = safeFullName,
				name = name or safeFullName,
				realm = realm or "",
				professions = professionText,
				rank = safeRank,
				rankIndex = rankIndex or 0,
				level = level or 0,
				classFile = safeClassFile,
				className = safeClassName,
				zone = safeZone,
				note = safeNote,
				officerNote = safeOfficerNote,
				online = online or false,
				isAFK = isAFK,
				isDND = isDND,
				isMobile = isMobile or false,
				lastOnlineYears = lastYears or 0,
				lastOnlineMonths = lastMonths or 0,
				lastOnlineDays = lastDays or 0,
				lastOnlineHours = lastHours or 0,
			})
		end

		if #members >= maxRows then
			break
		end
	end

	rosterCache = members
	rosterCacheTime = now
	return members
end

-- Invalidate roster cache (called on events)
function GuildBroker:InvalidateCache()
	rosterCache = nil
	rosterCacheTime = 0
end

-- Get online/total counts
function GuildBroker:GetGuildCounts()
	if previewData and previewData.members then
		local total = #previewData.members
		local online = 0
		for _, member in ipairs(previewData.members) do
			if member.online then
				online = online + 1
			end
		end
		return online, total
	end

	if not SafeIsInGuild() then
		return 0, 0
	end
	if not GetNumGuildMembers then
		return 0, 0
	end
	local okCounts, numTotal, numOnline = pcall(GetNumGuildMembers)
	if not okCounts then
		return 0, 0
	end
	return numOnline or 0, numTotal or 0
end

-- ========================================
-- Sorting
-- ========================================

local function CompareMembersByName(a, b)
	return (a.name or ""):lower() < (b.name or ""):lower()
end

local function CompareMembers(a, b)
	-- Online always first
	if a.online ~= b.online then
		return a.online
	end

	-- Then by name
	return CompareMembersByName(a, b)
end

local function CompareMembersByRank(a, b)
	if a.online ~= b.online then
		return a.online
	end
	if a.rankIndex ~= b.rankIndex then
		return a.rankIndex < b.rankIndex
	end
	return CompareMembersByName(a, b)
end

local function CompareMembersByLevel(a, b)
	if a.online ~= b.online then
		return a.online
	end
	if a.level ~= b.level then
		return a.level > b.level
	end
	return CompareMembersByName(a, b)
end

local function CompareMembersByClass(a, b)
	if a.online ~= b.online then
		return a.online
	end
	if a.classFile ~= b.classFile then
		return (a.classFile or "") < (b.classFile or "")
	end
	return CompareMembersByName(a, b)
end

local function CompareMembersByZone(a, b)
	if a.online ~= b.online then
		return a.online
	end
	if (a.zone or "") ~= (b.zone or "") then
		return (a.zone or ""):lower() < (b.zone or ""):lower()
	end
	return CompareMembersByName(a, b)
end

local function CompareMembersByNickname(a, b)
	if a.online ~= b.online then
		return a.online
	end
	local DB = GetDB()
	local nickA = DB and DB:GetGuildNickname(a.fullName) or ""
	local nickB = DB and DB:GetGuildNickname(b.fullName) or ""
	-- Members with nicknames come first
	if (nickA ~= "") ~= (nickB ~= "") then
		return nickA ~= ""
	end
	if nickA ~= "" and nickB ~= "" then
		return nickA:lower() < nickB:lower()
	end
	return CompareMembersByName(a, b)
end

local SORT_COMPARATORS = {
	name = CompareMembers,
	rank = CompareMembersByRank,
	level = CompareMembersByLevel,
	class = CompareMembersByClass,
	zone = CompareMembersByZone,
	nickname = CompareMembersByNickname,
}

-- ========================================
-- Filtering
-- ========================================

local function FilterMembers(members, filter, excludeSelf)
	local playerName = excludeSelf and UnitName("player") or nil
	local playerRealm = excludeSelf and GetNormalizedRealmName() or nil
	local playerFullName = playerName and playerRealm and (playerName .. "-" .. playerRealm) or nil

	if filter == "all" and not excludeSelf then
		return members
	end

	local filtered = {}
	for _, member in ipairs(members) do
		local include = true
		if excludeSelf and playerFullName and member.fullName == playerFullName then
			include = false
		end
		if include and filter == "online" then
			if not member.online then
				include = false
			end
		end
		if include then
			table.insert(filtered, member)
		end
	end
	return filtered
end

-- ========================================
-- Grouping
-- ========================================

local function GroupMembers(members, mode)
	if mode == "none" or not mode then
		return nil, members
	end

	local groups = {}
	local groupOrder = {}
	local groupOrderSet = {}

	for _, member in ipairs(members) do
		local key
		if mode == "by_rank" then
			key = member.rank or "Unknown"
		elseif mode == "by_class" then
			key = member.className or "Unknown"
		end

		if not groups[key] then
			groups[key] = {}
			if not groupOrderSet[key] then
				table.insert(groupOrder, key)
				groupOrderSet[key] = true
			end
		end
		table.insert(groups[key], member)
	end

	-- Sort group order: by rankIndex for rank mode, alphabetical for class mode
	if mode == "by_rank" then
		table.sort(groupOrder, function(a, b)
			local memberA = groups[a] and groups[a][1]
			local memberB = groups[b] and groups[b][1]
			if memberA and memberB then
				return (memberA.rankIndex or 99) < (memberB.rankIndex or 99)
			end
			return a < b
		end)
	else
		table.sort(groupOrder)
	end

	return { groups = groups, order = groupOrder }
end

-- ========================================
-- Guild Finder Applicant Count
-- ========================================

local function HasGuildApplicantPermission()
	if IsGuildLeader then
		local okLeader, isLeader = pcall(IsGuildLeader)
		if okLeader and isLeader then
			return true
		end
	end

	if C_GuildInfo and C_GuildInfo.IsGuildOfficer then
		local okOfficer, isOfficer = pcall(C_GuildInfo.IsGuildOfficer)
		if okOfficer and isOfficer then
			return true
		end
	end

	return false
end

local function GetGuildClubId()
	if not C_Club or not C_Club.GetGuildClubId then
		return nil
	end

	local ok, clubId = pcall(C_Club.GetGuildClubId)
	if ok and clubId then
		return clubId
	end
	return nil
end

function GuildBroker:CanShowApplicantCount()
	return BetterFriendlistDB
		and BetterFriendlistDB.guildBrokerShowApplicants ~= false
		and C_Club
		and C_Club.GetGuildClubId
		and C_ClubFinder
		and C_ClubFinder.RequestApplicantList
		and C_ClubFinder.ReturnClubApplicantList
		and Enum
		and Enum.ClubFinderRequestType
		and Enum.ClubFinderRequestType.Guild
		and HasGuildApplicantPermission()
end

function GuildBroker:RefreshApplicantCount(requestServer)
	applicantCount = 0

	if not self:CanShowApplicantCount() then
		return applicantCount
	end

	local clubId = GetGuildClubId()
	if not clubId then
		return applicantCount
	end

	if requestServer then
		pcall(C_ClubFinder.RequestApplicantList, Enum.ClubFinderRequestType.Guild)
	end

	local okApplicants, applicants = pcall(C_ClubFinder.ReturnClubApplicantList, clubId)
	if okApplicants and type(applicants) == "table" then
		applicantCount = #applicants
	end

	return applicantCount
end

function GuildBroker:RequestApplicantCountUpdate()
	if not self:CanShowApplicantCount() then
		applicantCount = 0
		return applicantCount
	end

	local now = GetTime()
	local shouldRequest = lastApplicantRequestTime == 0 or (now - lastApplicantRequestTime) >= APPLICANT_REQUEST_INTERVAL
	if shouldRequest then
		lastApplicantRequestTime = now
	end

	return self:RefreshApplicantCount(shouldRequest)
end

local function GetApplicantIndicatorText()
	if applicantCount and applicantCount > 0 then
		return " " .. C("ff8800", "+" .. tostring(applicantCount))
	end
	return ""
end

-- ========================================
-- Broker Text Update
-- ========================================

function GuildBroker:UpdateBrokerText(force)
	if not dataObject then
		return
	end

	local currentTime = GetTime()
	if not force and currentTime - lastUpdateTime < THROTTLE_INTERVAL then
		return
	end
	lastUpdateTime = currentTime

	if not BetterFriendlistDB then
		return
	end

	if not SafeIsInGuild() then
		dataObject.text = L("GUILD_BROKER_NO_GUILD")
		return
	end

	self:RequestApplicantCountUpdate()

	local onlineCount, totalCount = self:GetGuildCounts()

	-- Subtract self from counts if excluded
	if BetterFriendlistDB.guildBrokerExcludeSelf then
		totalCount = math.max(0, totalCount - 1)
		onlineCount = math.max(0, onlineCount - 1)
	end

	local showLabel = BetterFriendlistDB.guildBrokerShowLabel ~= false
	local showTotal = BetterFriendlistDB.guildBrokerShowTotal ~= false

	local countText
	if showTotal then
		countText = string.format("%d/%d", onlineCount, totalCount)
	else
		countText = tostring(onlineCount)
	end
	countText = countText .. GetApplicantIndicatorText()

	if showLabel then
		local guildName = SafeGetGuildInfo() or L("GUILD_BROKER_NO_GUILD")
		dataObject.text = guildName .. ": " .. countText
	else
		dataObject.text = countText
	end

	-- Update icon visibility
	local showIcon = BetterFriendlistDB.guildBrokerShowIcon ~= false
	if showIcon then
		dataObject.icon = "Interface\\GossipFrame\\TabardGossipIcon"
	else
		dataObject.icon = nil
	end
end

-- ========================================
-- Colored Level Text
-- ========================================
local function GetColoredLevelText(level)
	if not level or level == 0 then
		return C("gray", "??")
	end

	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 80
	if level >= maxLevel then
		return C("gold", tostring(level))
	elseif level >= maxLevel - 5 then
		return C("green", tostring(level))
	elseif level >= maxLevel - 10 then
		return C("ltyellow", tostring(level))
	else
		return C("white", tostring(level))
	end
end

-- ========================================
-- Click Handlers
-- ========================================

local function OnMemberLineClick(cell, data, mouseButton)
	if not data or not data.online then
		return
	end

	local actualButton = mouseButton or GetMouseButtonClicked()
	local hasUsableFullName = data.fullName and data.fullName ~= "Unknown"

	if IsAltKeyDown() then
		-- Invite to group
		if hasUsableFullName then
			BFL.InviteUnit(data.fullName)
		end
	elseif IsShiftKeyDown() then
		-- Copy name to chat
		if data.name and data.name ~= "Unknown" then
			AddNameToEditBox(data.name, data.realm)
		end
	elseif actualButton == "RightButton" then
		-- Context menu
		GuildBroker:OpenMemberContextMenu(data)
	else
		-- Whisper
		if hasUsableFullName then
			local whisperName = data.fullName:gsub(" ", "")
			BFL:SecureSendTell(whisperName)
		end
	end
end

-- ========================================
-- Context Menu
-- ========================================

function GuildBroker:OpenMemberContextMenu(data)
	if not data then
		return
	end

	local GuildActions = BFL:GetModule("GuildActions")
	if GuildActions then
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
				GuildActions:PopulateMemberMenu(rootDescription, data)
			end)
			return
		elseif UIDropDownMenu_Initialize and ToggleDropDownMenu then
			if not self.GuildMemberDropdown then
				self.GuildMemberDropdown = CreateFrame("Frame", "BFL_GuildBrokerMemberDropdown", UIParent, "UIDropDownMenuTemplate")
			end
			UIDropDownMenu_Initialize(self.GuildMemberDropdown, function(dropdown, level)
				if (level or 1) == 1 then
					local info = UIDropDownMenu_CreateInfo()
					info.text = GuildActions:GetDisplayName(data)
					info.isTitle = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, level)
				end
				GuildActions:AddClassicMemberMenuButtons(data, level)
			end, "MENU")
			ToggleDropDownMenu(1, nil, self.GuildMemberDropdown, UIParent, 0, 0)
			return
		end
	end

	local hasUsableFullName = data.fullName and data.fullName ~= "Unknown"

	-- Use MenuUtil (Retail) or fallback
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
			rootDescription:CreateTitle(data.name or "Unknown")

			-- Whisper (online only)
			if data.online and hasUsableFullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_WHISPER"), function()
					local whisperName = data.fullName:gsub(" ", "")
					BFL:SecureSendTell(whisperName)
				end)
			end

			-- Invite (online only)
			if data.online and hasUsableFullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_INVITE"), function()
					BFL.InviteUnit(data.fullName)
				end)
			end

			-- Who
			if hasUsableFullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_WHO"), function()
					C_FriendList.SendWho(data.fullName)
				end)
			end

			-- Copy Name
			if data.name and data.name ~= "Unknown" then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_COPY_NAME"), function()
					local copyText = data.fullName or data.name
					StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
						text = BFL.L and BFL.L.COPY_CHARACTER_NAME_POPUP_TITLE or "Copy Name",
						button1 = CLOSE,
						hasEditBox = true,
						editBoxWidth = 350,
						OnShow = function(self)
							self.EditBox:SetText(copyText)
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

			-- Set/Edit Nickname
			if hasUsableFullName then
				local DB = GetDB()
				local currentNick = DB and DB:GetGuildNickname(data.fullName) or ""
				local nickLabel = currentNick ~= ""
					and L("GUILD_BROKER_MENU_EDIT_NICKNAME")
					or L("GUILD_BROKER_MENU_SET_NICKNAME")
				rootDescription:CreateButton(nickLabel, function()
					StaticPopupDialogs["BFL_GUILD_SET_NICKNAME"] = {
						text = string.format(L("GUILD_BROKER_NICKNAME_PROMPT"), data.name or data.fullName),
						button1 = ACCEPT,
						button2 = CANCEL,
						button3 = currentNick ~= "" and (L("GUILD_BROKER_MENU_REMOVE_NICKNAME") or "Remove") or nil,
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
								DB:SetGuildNickname(data.fullName, newNick:trim())
								GuildBroker:RefreshTooltip()
							end
						end,
						OnAlt = function()
							-- Button3: Remove nickname
							DB:SetGuildNickname(data.fullName, nil)
							GuildBroker:RefreshTooltip()
						end,
						EditBoxOnEnterPressed = function(self)
							local parent = self:GetParent()
							local newNick = parent.EditBox:GetText()
							if newNick and newNick:trim() ~= "" then
								DB:SetGuildNickname(data.fullName, newNick:trim())
								GuildBroker:RefreshTooltip()
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

		end)
	end
end

function GuildBroker:PromoteMember(data)
	local GuildActions = BFL:GetModule("GuildActions")
	if GuildActions and GuildActions.PromoteMember then
		GuildActions:PromoteMember(data)
		return
	end

	BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
end

function GuildBroker:DemoteMember(data)
	local GuildActions = BFL:GetModule("GuildActions")
	if GuildActions and GuildActions.DemoteMember then
		GuildActions:DemoteMember(data)
		return
	end

	BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
end

function GuildBroker:RemoveMember(data)
	local GuildActions = BFL:GetModule("GuildActions")
	if GuildActions and GuildActions.RemoveMember then
		GuildActions:RemoveMember(data)
		return
	end

	BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
end

-- ========================================
-- ElvUI Tooltip Skin Helpers (delegate to BrokerUtils)
-- ========================================
local ApplyElvUISkin = BFL.BrokerUtils.ApplyElvUISkin
local RemoveElvUISkin = BFL.BrokerUtils.RemoveElvUISkin

-- ========================================
-- Tooltip Cleanup
-- ========================================

local function TooltipCleanup(tt)
	BFL.BrokerUtils.ClearActiveBrokerTooltip(tt)
	ReleaseDetailTooltip()
	if tooltip == tt then
		tooltip = nil
	end
	BFL.BrokerUtils.ScheduleBrokerTooltipRelease(LQT, tt)

	-- Remove ElvUI skin artifacts so released tooltips are clean
	RemoveElvUISkin(tt)

	if tt.footerFrame then
		tt.footerFrame:Hide()
	end

	if tt.bflTimer then
		tt.bflTimer:SetScript("OnUpdate", nil)
	end

	if tt.ScrollFrame then
		tt.ScrollFrame:ClearAllPoints()
		tt.ScrollFrame:SetPoint("TOPLEFT", tt, "TOPLEFT", 10, -10)
		tt.ScrollFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", -10, 10)
	end

	if tt.Slider then
		tt.Slider:ClearAllPoints()
		tt.Slider:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10)
		tt.Slider:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", -10, 10)
	end
end

-- ========================================
-- SetupTooltipAutoHide (wrapper)
-- ========================================

local function SetupTooltipAutoHide(tt, anchorFrame)
	BFL.BrokerUtils.SetupTooltipAutoHide(tt, anchorFrame, LQT, function()
		return detailTooltip
	end)
end

-- ========================================
-- Footer Height Calculation
-- ========================================

local function GetFooterHeight()
	local showHints = BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowHints ~= false
	local height = 55 -- base: separator + total line + filter line + padding
	if showHints then
		height = height + 95 -- 6 hint lines (6*14) + 2 separators (2*5) + spacing = 94, +1 padding
	end
	return height
end

-- ========================================
-- Render Fixed Footer
-- ========================================

local function RenderFixedFooter(footerFrame)
	-- Clear existing children (both own .lines and cross-module .content)
	if footerFrame.lines then
		for _, line in ipairs(footerFrame.lines) do
			line:Hide()
		end
	end
	if footerFrame.content then
		for _, region in ipairs(footerFrame.content) do
			region:Hide()
		end
		footerFrame.content = nil
	end
	footerFrame.lines = {}

	local function AddLine(text, fontObject)
		fontObject = fontObject or "GameTooltipText"
		local fs = footerFrame:CreateFontString(nil, "OVERLAY", fontObject)
		ApplyBrokerFontToFontString(fs, fontObject == "GameTooltipTextSmall" and -2 or 0)
		table.insert(footerFrame.lines, fs)
		fs:SetText(text)
		fs:Show()
		return fs
	end

	local function AddSeparator()
		local line = footerFrame:CreateTexture(nil, "OVERLAY")
		ApplyBrokerFooterSeparatorStyle(line)
		table.insert(footerFrame.lines, line)
		line:Show()
		return line
	end

	local yOffset = -5

	-- Separator
	local sep1 = AddSeparator()
	sep1:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sep1:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
	yOffset = yOffset - 8

	-- Total line
	local onlineCount, totalCount = GuildBroker:GetGuildCounts()
	if BetterFriendlistDB and BetterFriendlistDB.guildBrokerExcludeSelf then
		totalCount = math.max(0, totalCount - 1)
		onlineCount = math.max(0, onlineCount - 1)
	end
	local totalText = string.format(L("GUILD_BROKER_TOTAL_COUNT"), onlineCount, totalCount)
	local totalLine = AddLine(L("GUILD_BROKER_TOOLTIP_HEADER") .. ": " .. C("green", totalText), "GameTooltipText")
	totalLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	totalLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 18

	-- Filter line
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.guildBrokerFilter or "online"
	local filterText
	if currentFilter == "all" then
		filterText = L("GUILD_BROKER_FILTER_ALL")
	else
		filterText = L("GUILD_BROKER_FILTER_ONLINE")
	end
	local filterLine = AddLine(L("GUILD_BROKER_FILTER_LABEL") .. C("ltyellow", filterText), "GameTooltipText")
	filterLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	filterLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 18

	-- Hints
	local showHints = BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowHints ~= false
	if showHints then
		local sep2 = AddSeparator()
		sep2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		sep2:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
		yOffset = yOffset - 5

		local hint1 = AddLine(C("ltgray", L("GUILD_BROKER_HINT_MEMBER_ACTIONS")), "GameTooltipTextSmall")
		hint1:SetPoint("TOP", footerFrame, "TOP", 0, yOffset)
		yOffset = yOffset - 14

		local hint2 = AddLine(
			C("ltblue", L("GUILD_BROKER_HINT_CLICK_WHISPER"))
				.. L("GUILD_BROKER_HINT_WHISPER")
				.. "  "
				.. C("ltblue", L("GUILD_BROKER_HINT_RIGHT_CLICK_MENU"))
				.. L("GUILD_BROKER_HINT_CONTEXT_MENU"),
			"GameTooltipTextSmall"
		)
		hint2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint2:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		local hint3 = AddLine(
			C("ltblue", L("GUILD_BROKER_HINT_ALT_CLICK"))
				.. L("GUILD_BROKER_HINT_INVITE")
				.. "  "
				.. C("ltblue", L("GUILD_BROKER_HINT_SHIFT_CLICK"))
				.. L("GUILD_BROKER_HINT_COPY"),
			"GameTooltipTextSmall"
		)
		hint3:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint3:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		local sep3 = AddSeparator()
		sep3:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		sep3:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
		yOffset = yOffset - 5

		local hint4 = AddLine(C("ltgray", L("GUILD_BROKER_HINT_ICON_ACTIONS")), "GameTooltipTextSmall")
		hint4:SetPoint("TOP", footerFrame, "TOP", 0, yOffset)
		yOffset = yOffset - 14

		local hint5 = AddLine(
			C("ltblue", L("GUILD_BROKER_HINT_LEFT_CLICK")) .. L("GUILD_BROKER_HINT_TOGGLE"),
			"GameTooltipTextSmall"
		)
		hint5:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint5:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		local hint6 = AddLine(
			C("ltblue", L("GUILD_BROKER_HINT_RIGHT_CLICK"))
				.. L("GUILD_BROKER_HINT_SETTINGS")
				.. "  "
				.. C("ltblue", L("GUILD_BROKER_HINT_MIDDLE_CLICK"))
				.. L("GUILD_BROKER_HINT_CYCLE_FILTER"),
			"GameTooltipTextSmall"
		)
		hint6:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint6:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	end
end

-- ========================================
-- Detail Tooltip (hover on member row)
-- ========================================

local function CreateDetailTooltip(cell, data)
	if not data then
		return
	end

	ReleaseDetailTooltip()

	-- Bail out if main tooltip is gone
	if not tooltip or not tooltip:IsShown() then
		return
	end

	local tt2 = BFL.BrokerUtils.GetOrCreateBrokerDetailTooltip("BetterFriendlistGuildBrokerDetailTooltip")
	tt2:ClearLines()
	BFL.BrokerUtils.AnchorBrokerDetailTooltip(tt2, cell, tooltip)

	-- Header
	tt2:SetText(ClassColorTextByFile(data.classFile, data.name or "Unknown"))

	-- Rank
	if data.rank and data.rank ~= "" then
		tt2:AddDoubleLine(C("ltblue", L("GUILD_BROKER_COL_RANK")), data.rank)
	end

	-- Level
	if data.level and data.level > 0 then
		tt2:AddDoubleLine(C("ltblue", L("GUILD_BROKER_COL_LEVEL")), GetColoredLevelText(data.level))
	end

	-- Class
	if data.className and data.className ~= "" then
		tt2:AddDoubleLine(
			C("ltblue", L("GUILD_BROKER_COL_CLASS")),
			ClassColorTextByFile(data.classFile, data.className)
		)
	end

	-- Zone
	if data.zone and data.zone ~= "" then
		tt2:AddDoubleLine(C("ltblue", L("GUILD_BROKER_COL_ZONE")), data.zone)
	end

	-- Status
	if data.online then
		if data.isAFK then
			tt2:AddDoubleLine(C("ltblue", L("STATUS_LABEL")), C("gold", AWAY or "Away"))
		elseif data.isDND then
			tt2:AddDoubleLine(C("ltblue", L("STATUS_LABEL")), C("gold", DND or "DND"))
		end
	else
		local lastOnline = FormatLastOnline(
			data.lastOnlineYears, data.lastOnlineMonths, data.lastOnlineDays, data.lastOnlineHours
		)
		if lastOnline and lastOnline ~= "" then
			tt2:AddDoubleLine(C("ltblue", L("GUILD_BROKER_COL_LAST_ONLINE")), C("gray", lastOnline))
		end
	end

	-- Professions
	if data.professions and data.professions ~= "" then
		tt2:AddLine(" ")
		tt2:AddDoubleLine(C("ltblue", L("GUILD_BROKER_COL_PROFESSIONS")), data.professions)
	end

	-- Note
	if data.note and data.note ~= "" then
		tt2:AddLine(" ")
		tt2:AddLine(C("ltblue", L("GUILD_BROKER_COL_NOTE")))
		tt2:AddLine(data.note, 1, 1, 1, true)
	end

	-- Officer Note
	local canViewOfficer = false
	if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then
		local okOfficerView, result = pcall(C_GuildInfo.CanViewOfficerNote)
		canViewOfficer = okOfficerView and result or false
	end
	if canViewOfficer and data.officerNote and data.officerNote ~= "" then
		tt2:AddLine(" ")
		tt2:AddLine(C("ltblue", L("GUILD_BROKER_COL_OFFICER_NOTE")))
		tt2:AddLine(C("ltyellow", data.officerNote), 1, 1, 1, true)
	end

	tt2:Show()
	detailTooltip = tt2
end

-- ========================================
-- LibQTip Tooltip Creation
-- ========================================

local function CreateLibQTipTooltip(anchorFrame)
	if not LQT then
		return nil
	end

	-- Dismiss any other BFL broker tooltip (prevents overlap when hovering between plugins)
	BFL.BrokerUtils.DismissActiveBrokerTooltip()

	-- Define columns
	local columns = {
		{ key = "Nickname",    label = L("GUILD_BROKER_COL_NICKNAME"),     align = "LEFT",   setting = "guildBrokerShowColNickname",    default = false },
		{ key = "Name",        label = L("GUILD_BROKER_COL_NAME"),         align = "LEFT",   setting = "guildBrokerShowColName",        default = true },
		{ key = "Level",       label = L("GUILD_BROKER_COL_LEVEL"),        align = "CENTER", setting = "guildBrokerShowColLevel",       default = true },
		{ key = "Class",       label = L("GUILD_BROKER_COL_CLASS"),        align = "LEFT",   setting = "guildBrokerShowColClass",       default = true },
		{ key = "Professions", label = L("GUILD_BROKER_COL_PROFESSIONS"),  align = "LEFT",   setting = "guildBrokerShowColProfessions", default = false },
		{ key = "Rank",        label = L("GUILD_BROKER_COL_RANK"),         align = "LEFT",   setting = "guildBrokerShowColRank",        default = true },
		{ key = "Zone",        label = L("GUILD_BROKER_COL_ZONE"),         align = "LEFT",   setting = "guildBrokerShowColZone",        default = true },
		{ key = "Note",        label = L("GUILD_BROKER_COL_NOTE"),         align = "LEFT",   setting = "guildBrokerShowColNote",        default = false },
		{ key = "OfficerNote", label = L("GUILD_BROKER_COL_OFFICER_NOTE"), align = "LEFT",   setting = "guildBrokerShowColOfficerNote", default = false },
		{ key = "LastOnline",  label = L("GUILD_BROKER_COL_LAST_ONLINE"),  align = "CENTER", setting = "guildBrokerShowColLastOnline",  default = true },
	}

	-- Build active columns based on settings and column order
	local columnOrder = BetterFriendlistDB and BetterFriendlistDB.guildBrokerColumnOrder
	local activeColumns = {}
	local orderedColumns = {}

	local function IsColumnVisible(col)
		local visible = BetterFriendlistDB and BetterFriendlistDB[col.setting]
		if visible == nil then
			visible = col.default
		end
		return visible ~= false
	end

	if columnOrder and #columnOrder > 0 then
		for _, colKey in ipairs(columnOrder) do
			for _, c in ipairs(columns) do
				if c.key == colKey then
					table.insert(orderedColumns, c)
					break
				end
			end
		end

		for _, col in ipairs(columns) do
			local found = false
			for _, ordered in ipairs(orderedColumns) do
				if ordered.key == col.key then
					found = true
					break
				end
			end
			if not found then
				table.insert(orderedColumns, col)
			end
		end
	else
		orderedColumns = columns
	end

	for _, col in ipairs(orderedColumns) do
		if IsColumnVisible(col) then
			table.insert(activeColumns, col)
		end
	end

	-- Officer Note visibility gated by permission
	local canViewOfficer = false
	if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then
		local okOfficerView, result = pcall(C_GuildInfo.CanViewOfficerNote)
		canViewOfficer = okOfficerView and result or false
	end
	if not canViewOfficer then
		local filtered = {}
		for _, col in ipairs(activeColumns) do
			if col.key ~= "OfficerNote" then
				table.insert(filtered, col)
			end
		end
		activeColumns = filtered
	end

	if #activeColumns == 0 then
		table.insert(activeColumns, columns[1])
	end

	local numColumns = #activeColumns
	local alignArgs = {}
	for _, col in ipairs(activeColumns) do
		table.insert(alignArgs, col.align)
	end

	local function AddGuildMOTDRow(tt)
		local motd = SafeGetGuildMOTD()
		if motd == "" then
			return false
		end

		local motdRow = tt:AddRow()
		local motdCell = motdRow:GetCell(1)
		motdCell:SetColSpan(numColumns)
		motdCell:SetJustifyH("LEFT")
		if motdCell.SetMaxWidth then
			pcall(motdCell.SetMaxWidth, motdCell, MOTD_MAX_WIDTH)
		end
		if motdCell.FontString then
			if motdCell.FontString.SetWordWrap then
				pcall(motdCell.FontString.SetWordWrap, motdCell.FontString, true)
			end
			if motdCell.FontString.SetNonSpaceWrap then
				pcall(motdCell.FontString.SetNonSpaceWrap, motdCell.FontString, true)
			end
		end

		local motdLabel = L("GUILD_HEADER_MOTD")
		if motdLabel == "GUILD_HEADER_MOTD" then
			motdLabel = "MOTD:"
		end
		motdCell:SetText(C("ltyellow", motdLabel) .. " " .. C("white", motd))
		return true
	end

	local tt = LQT:AcquireTooltip(tooltipKey, numColumns, unpack(alignArgs))
	if not tt then
		return nil
	end

	-- Hook OnHide for cleanup
	local oldOnHide = tt:GetScript("OnHide")
	tt:SetScript("OnHide", function(self)
		TooltipCleanup(self)
		if oldOnHide then
			pcall(oldOnHide, self)
		end
	end)

	local status, err = xpcall(function()
		tt:Clear()
		tt:SmartAnchorTo(anchorFrame)
		tt.anchorFrame = anchorFrame
		SetupTooltipAutoHide(tt, anchorFrame)
		tt:SetFrameStrata("HIGH")

		-- ElvUI Skin: Apply ElvUI template (hides NineSlice, applies ElvUI backdrop)
		ApplyElvUISkin(tt)

		-- No guild: show a simple, clean tooltip without footer/scroll infrastructure
		if not SafeIsInGuild() then
			-- Hide leftover footer and reset scroll anchors from a previous in-guild tooltip (pooled frame reuse)
			if tt.footerFrame then
				tt.footerFrame:Hide()
			end
			if tt.ScrollFrame then
				tt.ScrollFrame:ClearAllPoints()
				tt.ScrollFrame:SetPoint("TOPLEFT", tt, "TOPLEFT", 10, -10)
				tt.ScrollFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", -10, 10)
			end

			local headerRow = tt:AddHeadingRow()
			local headerCell = headerRow:GetCell(1)
			headerCell:SetColSpan(numColumns)
			headerCell:SetFontObject(BetterFriendlistFontNormalLarge or "GameTooltipHeaderText")
			headerCell:SetJustifyH("LEFT")
			headerCell:SetText(C("dkyellow", L("GUILD_BROKER_TITLE")))
			AddTooltipSeparator(tt)

			local noGuildRow = tt:AddRow()
			local noGuildCell = noGuildRow:GetCell(1)
			noGuildCell:SetColSpan(numColumns)
			noGuildCell:SetJustifyH("CENTER")
			noGuildCell:SetText(C("gray", L("GUILD_BROKER_NO_GUILD")))

			-- Show icon action hints if enabled
			local showHints = BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowHints ~= false
			if showHints then
				AddTooltipSeparator(tt)
				local hint1 = tt:AddRow()
				local hint1Cell = hint1:GetCell(1)
				hint1Cell:SetColSpan(numColumns)
				hint1Cell:SetJustifyH("CENTER")
				hint1Cell:SetText(C("ltblue", L("GUILD_BROKER_HINT_LEFT_CLICK")) .. L("GUILD_BROKER_HINT_TOGGLE"))

				local hint2 = tt:AddRow()
				local hint2Cell = hint2:GetCell(1)
				hint2Cell:SetColSpan(numColumns)
				hint2Cell:SetJustifyH("CENTER")
				hint2Cell:SetText(
					C("ltblue", L("GUILD_BROKER_HINT_RIGHT_CLICK")) .. L("GUILD_BROKER_HINT_SETTINGS")
					.. "  " .. C("ltblue", L("GUILD_BROKER_HINT_MIDDLE_CLICK")) .. L("GUILD_BROKER_HINT_CYCLE_FILTER")
				)
			end

			ApplyBrokerFontToTooltip(tt)
			tt:UpdateLayout()
			tt:Show()
			return
		end

		-- Fixed Footer Frame (only when in a guild)
		if not tt.footerFrame then
			tt.footerFrame = CreateFrame("Frame", nil, tt)
			tt.footerFrame:SetPoint("BOTTOMLEFT", tt, "BOTTOMLEFT", 0, 0)
			tt.footerFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", 0, 0)
		end
		tt.footerFrame:SetHeight(GetFooterHeight())
		tt.footerFrame:Show()

		if tt.ScrollFrame then
			tt.ScrollFrame:ClearAllPoints()
			tt.ScrollFrame:SetPoint("TOP", tt, "TOP", 0, -10)
			tt.ScrollFrame:SetPoint("LEFT", tt, "LEFT", 10, 0)
			tt.ScrollFrame:SetPoint("RIGHT", tt, "RIGHT", -10, 0)
			tt.ScrollFrame:SetPoint("BOTTOM", tt.footerFrame, "TOP", 0, 0)
		end

		RenderFixedFooter(tt.footerFrame)
		tt:SetMaxHeight(MAX_TOOLTIP_HEIGHT)
		tt:UpdateLayout()

		-- Header
		local headerRow = tt:AddHeadingRow()
		local headerCell = headerRow:GetCell(1)
		headerCell:SetColSpan(numColumns)
		headerCell:SetFontObject(BetterFriendlistFontNormalLarge or "GameTooltipHeaderText")
		headerCell:SetJustifyH("LEFT")

		local guildName = SafeGetGuildInfo() or L("GUILD_BROKER_NO_GUILD")
		headerCell:SetText(C("dkyellow", guildName))
		AddGuildMOTDRow(tt)
		AddTooltipSeparator(tt)

		-- Column Headers
		local headerCells = {}
		for _, col in ipairs(activeColumns) do
			table.insert(headerCells, C("ltyellow", col.label))
		end
		tt:AddRow(unpack(headerCells))
		AddTooltipSeparator(tt)

		-- Collect and process roster data
		local members = GuildBroker:CollectGuildRoster()

		-- Apply filter (with self-exclusion)
		local currentFilter = previewData and "all" or (BetterFriendlistDB and BetterFriendlistDB.guildBrokerFilter or "online")
		local excludeSelf = BetterFriendlistDB and BetterFriendlistDB.guildBrokerExcludeSelf
		members = FilterMembers(members, currentFilter, excludeSelf)

		-- Apply sort
		local sortMode = BetterFriendlistDB and BetterFriendlistDB.guildBrokerSortMode or "name"
		local comparator = SORT_COMPARATORS[sortMode] or CompareMembers
		table.sort(members, comparator)

		-- Apply grouping
		local groupMode = BetterFriendlistDB and BetterFriendlistDB.guildBrokerGroupMode or "none"
		local groupData, flatMembers = GroupMembers(members, groupMode)

		local displayedCount = 0

		-- Helper: render a single member row
		local function RenderMemberRow(member, indent)
			indent = indent or ""
			local cellValues = {}

			local hideLevelAtMax = BetterFriendlistDB and BetterFriendlistDB.guildBrokerHideLevelAtMax
			local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 80
			local showClassIcons = BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowClassIcons
			local customNickColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerNicknameColor
			local customRankColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerRankColor
			local customZoneColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerZoneColor
			local customNoteColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerNoteColor
			local customOfficerNoteColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerOfficerNoteColor

			for _, col in ipairs(activeColumns) do
				local val = ""
				if col.key == "Nickname" then
					local DB = GetDB()
					local nick = DB and DB:GetGuildNickname(member.fullName) or ""
					if nick ~= "" then
						if member.online then
							if customNickColor then
								local hex = string.format("%02x%02x%02x",
									math.floor(customNickColor[1] * 255),
									math.floor(customNickColor[2] * 255),
									math.floor(customNickColor[3] * 255))
								val = C(hex, nick)
							else
								val = ClassColorTextByFile(member.classFile, nick)
							end
						else
							val = C("gray", nick)
						end
					end
				elseif col.key == "Name" then
					local classIcon = ""
					if showClassIcons then
						classIcon = GetClassIcon(member.classFile) .. " "
					end
					local statusIcon = ""
					if member.online and (member.isAFK or member.isDND) then
						statusIcon = GetStatusIcon(member.isAFK, member.isDND, member.isMobile) .. " "
					end
					local nameText = ClassColorTextByFile(member.classFile, member.name or "Unknown")
					if not member.online then
						nameText = C("gray", member.name or "Unknown")
					end
					val = indent .. classIcon .. statusIcon .. nameText
				elseif col.key == "Level" then
					if hideLevelAtMax and member.level and member.level >= maxLevel then
						val = ""
					elseif member.online then
						val = GetColoredLevelText(member.level)
					else
						val = C("gray", tostring(member.level or ""))
					end
				elseif col.key == "Class" then
					if member.online then
						val = ClassColorTextByFile(member.classFile, member.className or "")
					else
						val = C("gray", member.className or "")
					end
				elseif col.key == "Professions" then
					val = member.professions or ""
				elseif col.key == "Rank" then
					local rankText = member.rank or ""
					if not member.online then
						val = C("gray", rankText)
					elseif customRankColor and rankText ~= "" then
						local hex = string.format("%02x%02x%02x",
							math.floor(customRankColor[1] * 255),
							math.floor(customRankColor[2] * 255),
							math.floor(customRankColor[3] * 255))
						val = C(hex, rankText)
					else
						val = rankText
					end
				elseif col.key == "Zone" then
					local zoneText = member.online and (member.zone or "") or ""
					if zoneText ~= "" and member.online and customZoneColor then
						local hex = string.format("%02x%02x%02x",
							math.floor(customZoneColor[1] * 255),
							math.floor(customZoneColor[2] * 255),
							math.floor(customZoneColor[3] * 255))
						val = C(hex, zoneText)
					else
						val = zoneText
					end
				elseif col.key == "Note" then
					local noteText = member.note or ""
					if noteText ~= "" and customNoteColor then
						local hex = string.format("%02x%02x%02x",
							math.floor(customNoteColor[1] * 255),
							math.floor(customNoteColor[2] * 255),
							math.floor(customNoteColor[3] * 255))
						val = C(hex, noteText)
					else
						val = noteText
					end
				elseif col.key == "OfficerNote" then
					local offNoteText = member.officerNote or ""
					if offNoteText ~= "" and customOfficerNoteColor then
						local hex = string.format("%02x%02x%02x",
							math.floor(customOfficerNoteColor[1] * 255),
							math.floor(customOfficerNoteColor[2] * 255),
							math.floor(customOfficerNoteColor[3] * 255))
						val = C(hex, offNoteText)
					else
						val = offNoteText
					end
				elseif col.key == "LastOnline" then
					if member.online then
						val = C("green", L("GUILD_BROKER_LAST_ONLINE_NOW"))
					else
						val = C("gray", FormatLastOnline(
							member.lastOnlineYears, member.lastOnlineMonths,
							member.lastOnlineDays, member.lastOnlineHours
						))
					end
				end
				table.insert(cellValues, val)
			end

			local row = tt:AddRow(unpack(cellValues))
			row:SetColor(0, 0, 0, 0)

			-- Hover highlight + detail tooltip
			row:SetScript("OnEnter", function()
				row:SetColor(0.2, 0.4, 0.6, 0.3)
				CreateDetailTooltip(row, member)
			end)
			row:SetScript("OnLeave", function()
				row:SetColor(0, 0, 0, 0)
				ReleaseDetailTooltip()
			end)

			-- Click handler
			row:SetScript("OnMouseUp", function(frame, button)
				if previewData then
					return
				end
				OnMemberLineClick(nil, member, button)
			end)

			displayedCount = displayedCount + 1
		end

		-- Render content: grouped or flat
		if groupData then
			local collapsedGroups = BetterFriendlistDB and BetterFriendlistDB.guildBrokerCollapsedGroups or {}
			local displayedRankGroupCount = 0

			for _, groupKey in ipairs(groupData.order) do
				local groupMembers = groupData.groups[groupKey]
				if groupMembers and #groupMembers > 0 then
					local collapsed = collapsedGroups[groupKey]
					if groupMode == "by_rank" then
						if displayedRankGroupCount > 0 then
							AddTooltipSeparator(tt)
						end
						displayedRankGroupCount = displayedRankGroupCount + 1
					end

					-- Group header row
					local groupRow = tt:AddRow()
					local groupCell = groupRow:GetCell(1)
					groupCell:SetColSpan(numColumns)
					groupCell:SetJustifyH("LEFT")

					local prefix = collapsed and "+ " or "- "
					local countText = string.format("(%d)", #groupMembers)

					-- Color by class file for class grouping
					local headerText
					if groupMode == "by_class" then
						local sampleMember = groupMembers[1]
						headerText = ClassColorTextByFile(sampleMember.classFile, prefix .. groupKey) .. " " .. C("gray", countText)
					elseif groupMode == "by_rank" then
						local rankColor = BetterFriendlistDB and BetterFriendlistDB.guildBrokerRankColor
						if rankColor then
							local hex = string.format("%02x%02x%02x",
								math.floor(rankColor[1] * 255),
								math.floor(rankColor[2] * 255),
								math.floor(rankColor[3] * 255))
							headerText = C(hex, prefix .. groupKey) .. " " .. C("gray", countText)
						else
							headerText = C("gold", prefix .. groupKey) .. " " .. C("gray", countText)
						end
					else
						headerText = C("gold", prefix .. groupKey) .. " " .. C("gray", countText)
					end
					groupCell:SetText("  " .. headerText)

					-- Group header hover
					groupRow:SetScript("OnEnter", function()
						groupRow:SetColor(0.2, 0.2, 0.2, 0.5)
						ReleaseDetailTooltip()
					end)
					groupRow:SetScript("OnLeave", function()
						groupRow:SetColor(0, 0, 0, 0)
					end)

					-- Toggle collapse on click
					groupRow:SetScript("OnMouseUp", function()
						if previewData then
							return
						end
						if not BetterFriendlistDB.guildBrokerCollapsedGroups then
							BetterFriendlistDB.guildBrokerCollapsedGroups = {}
						end
						if BetterFriendlistDB.guildBrokerCollapsedGroups[groupKey] then
							BetterFriendlistDB.guildBrokerCollapsedGroups[groupKey] = nil
						else
							BetterFriendlistDB.guildBrokerCollapsedGroups[groupKey] = true
						end
						GuildBroker:RefreshTooltip()
					end)

					-- Render members (if not collapsed)
					if not collapsed then
						for _, member in ipairs(groupMembers) do
							RenderMemberRow(member, "    ")
						end
					end
				end
			end
		else
			-- Flat list
			for _, member in ipairs(flatMembers) do
				RenderMemberRow(member)
			end
		end

		-- Empty state
		if displayedCount == 0 then
			AddTooltipSeparator(tt)
			local emptyRow = tt:AddRow()
			local emptyCell = emptyRow:GetCell(1)
			emptyCell:SetColSpan(numColumns)
			emptyCell:SetJustifyH("CENTER")
			emptyCell:SetText(C("gray", L("GUILD_BROKER_NO_MEMBERS_ONLINE")))
		end

		ApplyBrokerFontToTooltip(tt)

		local footerHeight = GetFooterHeight()
		local maxContentHeight = MAX_TOOLTIP_HEIGHT - footerHeight
		tt:SetMaxHeight(maxContentHeight)
		tt:UpdateLayout()

		tt:SetHeight(tt:GetHeight() + footerHeight)

		-- Fix Slider Anchor (must stop at footer)
		if tt.Slider and tt.Slider:IsShown() then
			tt.Slider:ClearAllPoints()
			tt.Slider:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10)
			tt.Slider:SetPoint("BOTTOMRIGHT", tt.footerFrame, "TOPRIGHT", -10, 0)

			if tt.ScrollFrame then
				tt.ScrollFrame:SetPoint("RIGHT", tt, "RIGHT", -30, 0)
			end
		end

		tt:Show()
	end, geterrorhandler())

	if not status then
		tt:Clear()
		local errRow = tt:AddRow()
		local errCell = errRow:GetCell(1)
		errCell:SetText("Error rendering guild tooltip")
		local errRow2 = tt:AddRow()
		local errCell2 = errRow2:GetCell(1)
		errCell2:SetText(tostring(err))
		tt:Show()
		SetupTooltipAutoHide(tt, anchorFrame)
	end

	-- Register as active BFL broker tooltip
	BFL.BrokerUtils.SetActiveBrokerTooltip(tt, LQT, function() return detailTooltip end)

	return tt
end

function GuildBroker:SetPreviewData(data)
	previewData = data
	self:InvalidateCache()
end

-- Refresh the tooltip
function GuildBroker:RefreshTooltip()
	if LQT and tooltip and tooltip:IsShown() then
		local anchor = tooltip.anchorFrame

		-- Don't re-create if nobody is looking (prevents event-driven refreshes
		-- from resetting the auto-hide timer after the user moved away)
		local isOver = tooltip:IsMouseOver()
		if not isOver and anchor and anchor.IsMouseOver then
			isOver = anchor:IsMouseOver()
		end
		if not isOver then
			LQT:ReleaseTooltip(tooltip)
			tooltip = nil
			return
		end

		LQT:ReleaseTooltip(tooltip)
		tooltip = nil
		if anchor then
			tooltip = CreateLibQTipTooltip(anchor)
		end
	end
end

-- ========================================
-- Basic Tooltip (GameTooltip fallback)
-- ========================================

local function CreateBasicTooltip(gameTooltip)
	gameTooltip:AddLine(L("GUILD_BROKER_TITLE"), GetAccentColor(1, 0.82, 0, 1))
	gameTooltip:AddLine(" ")

	if not SafeIsInGuild() then
		gameTooltip:AddLine(L("GUILD_BROKER_NO_GUILD"), 0.7, 0.7, 0.7)
		return
	end

	local guildName = SafeGetGuildInfo() or ""
	gameTooltip:AddLine(guildName, 0, 1, 0)

	local motd = SafeGetGuildMOTD()
	if motd ~= "" then
		local motdLabel = L("GUILD_HEADER_MOTD")
		if motdLabel == "GUILD_HEADER_MOTD" then
			motdLabel = "MOTD:"
		end
		gameTooltip:AddLine(C("ltyellow", motdLabel) .. " " .. C("white", motd), 1, 1, 1, true)
	end
	gameTooltip:AddLine(" ")

	local onlineCount, totalCount = GuildBroker:GetGuildCounts()
	gameTooltip:AddDoubleLine(
		L("GUILD_BROKER_TOOLTIP_HEADER"),
		string.format("%d / %d", onlineCount, totalCount),
		1, 1, 1, 0, 1, 0
	)

	if BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowHints ~= false then
		gameTooltip:AddLine(" ")
		gameTooltip:AddLine(L("GUILD_BROKER_HINT_LEFT_CLICK") .. L("GUILD_BROKER_HINT_TOGGLE"), 0.5, 0.9, 1)
		gameTooltip:AddLine(L("GUILD_BROKER_HINT_RIGHT_CLICK") .. L("GUILD_BROKER_HINT_SETTINGS"), 0.5, 0.9, 1)
		gameTooltip:AddLine(L("GUILD_BROKER_HINT_MIDDLE_CLICK") .. L("GUILD_BROKER_HINT_CYCLE_FILTER"), 0.5, 0.9, 1)
	end
end

-- ========================================
-- DataObject OnClick Handler
-- ========================================

local function OpenGuildBrokerSettings()
	local Settings = BFL:GetModule("Settings")
	if not Settings then
		return false
	end

	if Settings.OpenSettingsTab then
		Settings:OpenSettingsTab("broker")
		return true
	end

	if Settings.Show then
		Settings:Show()
		if Settings.SelectCategory then
			Settings:SelectCategory(5)
		end
		return true
	end

	return false
end

local function OpenBetterFriendlistGuildTab()
	if not (BFL.IsGuildTabEnabled and BFL:IsGuildTabEnabled()) then
		return OpenGuildBrokerSettings(), "settings"
	end

	if ShowBetterFriendsFrame then
		ShowBetterFriendsFrame(1)
	elseif BetterFriendsFrame then
		BetterFriendsFrame:Show()
	end

	if BetterFriendsFrame_ShowTab then
		BetterFriendsFrame_ShowTab(4)
		return true, "guild_tab"
	end

	return false, "missing-guild-tab"
end

local function RunConfiguredLeftClickAction()
	local action = (BetterFriendlistDB and BetterFriendlistDB.guildBrokerClickAction) or "guild_tab"
	if action == "guild_frame" then
		action = "guild_tab"
		if BetterFriendlistDB then
			BetterFriendlistDB.guildBrokerClickAction = "guild_tab"
		end
	end

	if action == "settings" then
		return OpenGuildBrokerSettings(), "settings"
	end

	return OpenBetterFriendlistGuildTab()
end

function GuildBroker:OnClick(clickedFrame, button)
	if button == "MiddleButton" then
		-- Cycle filter: online <-> all
		if not BetterFriendlistDB then
			return
		end
		local currentFilter = BetterFriendlistDB.guildBrokerFilter or "online"
		if currentFilter == "online" then
			BetterFriendlistDB.guildBrokerFilter = "all"
		else
			BetterFriendlistDB.guildBrokerFilter = "online"
		end

		-- Release and recreate tooltip
		if LQT and tooltip then
			LQT:ReleaseTooltip(tooltip)
			tooltip = nil
		end
		if LQT and clickedFrame then
			tooltip = CreateLibQTipTooltip(clickedFrame)
		end
		self:UpdateBrokerText()
	elseif button == "RightButton" then
		-- Open settings
		OpenGuildBrokerSettings()
	else
		-- Left click: configurable action
		RunConfiguredLeftClickAction()
	end
end

-- ========================================
-- Initialization & Events
-- ========================================

function GuildBroker:Initialize()
	local isEnabled = BetterFriendlistDB and BetterFriendlistDB.guildBrokerEnabled

	if not isEnabled then
		return
	end

	if not LDB then
		return
	end

	if not BetterFriendlistDB then
		return
	end

	-- Create Data Broker object
	local dataObjectDef = {
		type = "data source",
		text = L("GUILD_BROKER_NO_GUILD"),
		icon = "Interface\\GossipFrame\\TabardGossipIcon",
		label = L("GUILD_BROKER_TITLE"),

		OnClick = function(clickedFrame, button)
			GuildBroker:OnClick(clickedFrame, button)
		end,
	}

	if LQT then
		dataObjectDef.OnEnter = function(anchorFrame)
			-- Request fresh roster data when tooltip opens
			if BFL.GuildRoster then
				pcall(BFL.GuildRoster)
			end
			GuildBroker:RequestApplicantCountUpdate()
			tooltip = CreateLibQTipTooltip(anchorFrame)
		end
	else
		dataObjectDef.OnTooltipShow = function(gameTooltip)
			if gameTooltip and gameTooltip.AddLine then
				CreateBasicTooltip(gameTooltip)
			end
		end
	end

	dataObject = LDB:NewDataObject("BetterFriendlist - Guild", dataObjectDef)

	if dataObject then
		self:RegisterEvents()
		-- Request initial roster (async: UpdateBrokerText will be called by GUILD_ROSTER_UPDATE)
		self:UpdateBrokerText()
		if SafeIsInGuild() and BFL.GuildRoster then
			pcall(BFL.GuildRoster)
		end
	end
end

function GuildBroker:RegisterEvents()
	if not BetterFriendlistDB or not BetterFriendlistDB.guildBrokerEnabled then
		return
	end

	if not dataObject then
		return
	end

	BFL:RegisterEventCallback("GUILD_ROSTER_UPDATE", function()
		GuildBroker:InvalidateCache()
		GuildBroker:RequestApplicantCountUpdate()
		GuildBroker:UpdateBrokerText()
		GuildBroker:RefreshTooltip()
	end, 50)

	BFL:RegisterEventCallback("GUILD_MOTD", function(motd)
		if BFL.CacheGuildMOTD then
			BFL.CacheGuildMOTD(motd)
		end
		GuildBroker:RefreshTooltip()
	end, 50)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function(unitTarget)
		if unitTarget and unitTarget ~= "player" then
			return
		end
		if BFL.ClearGuildMOTDCache then
			BFL.ClearGuildMOTDCache()
		end
		GuildBroker:InvalidateCache()
		lastApplicantRequestTime = 0
		GuildBroker:RequestApplicantCountUpdate()
		GuildBroker:UpdateBrokerText()
		if SafeIsInGuild() and BFL.GuildRoster then
			pcall(BFL.GuildRoster)
		end
		GuildBroker:RefreshTooltip()
	end, 50)

	pcall(function()
		BFL:RegisterEventCallback("CLUB_FINDER_APPLICATIONS_UPDATED", function(requestType)
			if
				Enum
				and Enum.ClubFinderRequestType
				and Enum.ClubFinderRequestType.Guild
				and requestType
				and requestType ~= Enum.ClubFinderRequestType.Guild
			then
				return
			end

			GuildBroker:RefreshApplicantCount(false)
			lastUpdateTime = 0
			GuildBroker:UpdateBrokerText()
			GuildBroker:RefreshTooltip()
		end, 50)
	end)

	if BFL.RegisterEventCallback then
		-- GUILD_RANKS_UPDATE may not exist on all versions
		pcall(function()
			BFL:RegisterEventCallback("GUILD_RANKS_UPDATE", function()
				GuildBroker:InvalidateCache()
				GuildBroker:UpdateBrokerText()
				GuildBroker:RefreshTooltip()
			end, 50)
		end)

		-- Retail 12.1 adds a narrower active-player rank update event.
		pcall(function()
			BFL:RegisterEventCallback("GUILD_RANKS_UPDATE_ACTIVE_PLAYER", function()
				GuildBroker:InvalidateCache()
				GuildBroker:UpdateBrokerText()
				GuildBroker:RefreshTooltip()
			end, 50)
		end)
	end
end

-- ========================================
-- Slash Command Support
-- ========================================

function GuildBroker:ToggleEnabled()
	if not BetterFriendlistDB then
		return
	end

	BetterFriendlistDB.guildBrokerEnabled = not BetterFriendlistDB.guildBrokerEnabled

	if BetterFriendlistDB.guildBrokerEnabled then
		print("|cff00ff00BetterFriendlist:|r Guild Broker |cff00ff00ENABLED|r - /reload to apply")
	else
		print("|cff00ff00BetterFriendlist:|r Guild Broker |cffff0000DISABLED|r - /reload to apply")
	end
end

-- Export module
BFL.GuildBroker = GuildBroker
return GuildBroker
