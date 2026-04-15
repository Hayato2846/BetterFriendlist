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
local detailTooltip = nil
local detailTooltipKey = "BetterFriendlistGuildBrokerDetailTT"

-- Roster cache
local rosterCache = nil
local rosterCacheTime = 0
local ROSTER_CACHE_TTL = 2 -- seconds

-- Maximum tooltip height
local MAX_TOOLTIP_HEIGHT = 600

-- ========================================
-- Shared Helpers from BrokerUtils
-- ========================================
local C = BFL.BrokerUtils.C
local GetStatusIcon = BFL.BrokerUtils.GetStatusIcon
local ClassColorTextByFile = BFL.BrokerUtils.ClassColorTextByFile
local FormatLastOnline = BFL.BrokerUtils.FormatLastOnline
local IsMenuOpen = BFL.BrokerUtils.IsMenuOpen
local AddNameToEditBox = BFL.BrokerUtils.AddNameToEditBox

-- ========================================
-- Localization Helper
-- ========================================
local function L(key)
	if BFL.L and BFL.L[key] then
		return BFL.L[key]
	end
	return key
end

-- ========================================
-- Data Layer: Guild Roster Collection
-- ========================================

-- Collect and cache guild roster data
function GuildBroker:CollectGuildRoster()
	if not IsInGuild() then
		rosterCache = nil
		return {}
	end

	-- Return cached data if still valid
	local now = GetTime()
	if rosterCache and (now - rosterCacheTime) < ROSTER_CACHE_TTL then
		return rosterCache
	end

	local numTotal, numOnline = GetNumGuildMembers()
	if not numTotal or numTotal == 0 then
		rosterCache = {}
		rosterCacheTime = now
		return rosterCache
	end

	local maxRows = BetterFriendlistDB and BetterFriendlistDB.guildBrokerMaxRows or 100
	local members = {}

	for i = 1, numTotal do
		local fullName, rank, rankIndex, level, className, zone, note, officerNote, online, status, classFile,
			achievementPoints, achievementRank, isMobile, isSoREligible, standingID = BFL.GetGuildRosterInfo(i)

		if fullName then
			local name, realm = strsplit("-", fullName, 2)
			local isAFK = (status == 1)
			local isDND = (status == 2)

			-- Last online time (only relevant for offline members)
			local lastYears, lastMonths, lastDays, lastHours = 0, 0, 0, 0
			if not online then
				lastYears, lastMonths, lastDays, lastHours = BFL.GetGuildRosterLastOnline(i)
			end

			-- Secret value guards (12.0+)
			local safeName = fullName
			local safeZone = zone or ""
			if BFL.HasSecretValues then
				if BFL:IsSecret(fullName) then
					safeName = "Unknown"
					name = "Unknown"
				end
				if BFL:IsSecret(zone) then
					safeZone = ""
				end
			end

			table.insert(members, {
				index = i,
				fullName = safeName,
				name = name or safeName,
				realm = realm or "",
				rank = rank or "",
				rankIndex = rankIndex or 0,
				level = level or 0,
				classFile = classFile or "",
				className = className or "",
				zone = safeZone,
				note = note or "",
				officerNote = officerNote or "",
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
	if not IsInGuild() then
		return 0, 0
	end
	local numTotal, numOnline = GetNumGuildMembers()
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

-- ========================================
-- Filtering
-- ========================================

local function FilterMembers(members, filter)
	if filter == "all" then
		return members
	end

	local filtered = {}
	for _, member in ipairs(members) do
		if filter == "online" then
			if member.online then
				table.insert(filtered, member)
			end
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
-- Broker Text Update
-- ========================================

function GuildBroker:UpdateBrokerText()
	if not dataObject then
		return
	end

	local currentTime = GetTime()
	if currentTime - lastUpdateTime < THROTTLE_INTERVAL then
		return
	end
	lastUpdateTime = currentTime

	if not BetterFriendlistDB then
		return
	end

	if not IsInGuild() then
		dataObject.text = L("GUILD_BROKER_NO_GUILD")
		return
	end

	local onlineCount, totalCount = self:GetGuildCounts()
	local showLabel = BetterFriendlistDB.guildBrokerShowLabel ~= false
	local showTotal = BetterFriendlistDB.guildBrokerShowTotal ~= false

	local countText
	if showTotal then
		countText = string.format("%d/%d", onlineCount, totalCount)
	else
		countText = tostring(onlineCount)
	end

	if showLabel then
		local guildName = GetGuildInfo("player") or L("GUILD_BROKER_NO_GUILD")
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

	if IsAltKeyDown() then
		-- Invite to group
		if data.fullName then
			BFL.InviteUnit(data.fullName)
		end
	elseif IsShiftKeyDown() then
		-- Copy name to chat
		if data.name then
			AddNameToEditBox(data.name, data.realm)
		end
	elseif actualButton == "RightButton" then
		-- Context menu
		GuildBroker:OpenMemberContextMenu(data)
	else
		-- Whisper
		if data.fullName then
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

	-- Use MenuUtil (Retail) or fallback
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
			rootDescription:CreateTitle(data.name or "Unknown")

			-- Whisper (online only)
			if data.online and data.fullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_WHISPER"), function()
					local whisperName = data.fullName:gsub(" ", "")
					BFL:SecureSendTell(whisperName)
				end)
			end

			-- Invite (online only)
			if data.online and data.fullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_INVITE"), function()
					BFL.InviteUnit(data.fullName)
				end)
			end

			-- Who
			if data.fullName then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_WHO"), function()
					C_FriendList.SendWho(data.fullName)
				end)
			end

			-- Copy Name
			if data.name then
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

			-- Edit Note
			if CanEditPublicNote and CanEditPublicNote() then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_EDIT_NOTE"), function()
					SetGuildRosterSelection(data.index)
					StaticPopup_Show("SET_GUILDPLAYERNOTE")
				end)
			end

			-- Edit Officer Note
			local canViewOfficer = C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote()
			local canEditOfficer = CanEditOfficerNote and CanEditOfficerNote()
			if canViewOfficer and canEditOfficer then
				rootDescription:CreateButton(L("GUILD_BROKER_MENU_EDIT_OFFICER_NOTE"), function()
					SetGuildRosterSelection(data.index)
					StaticPopup_Show("SET_GUILDOFFICERNOTE")
				end)
			end

			-- Separator before rank management
			local hasRankOptions = false

			-- Promote
			if CanGuildPromote and CanGuildPromote() and data.rankIndex and data.rankIndex > 1 then
				if not hasRankOptions then
					rootDescription:CreateDivider()
					hasRankOptions = true
				end

				rootDescription:CreateButton(L("GUILD_BROKER_MENU_PROMOTE"), function()
					GuildBroker:PromoteMember(data)
				end)
			end

			-- Demote
			if CanGuildDemote and CanGuildDemote() then
				local numRanks = GuildControlGetNumRanks and GuildControlGetNumRanks() or 10
				if data.rankIndex and data.rankIndex < (numRanks - 1) then
					if not hasRankOptions then
						rootDescription:CreateDivider()
						hasRankOptions = true
					end

					rootDescription:CreateButton(L("GUILD_BROKER_MENU_DEMOTE"), function()
						GuildBroker:DemoteMember(data)
					end)
				end
			end

			-- Remove
			if CanGuildRemove and CanGuildRemove() then
				if not hasRankOptions then
					rootDescription:CreateDivider()
				end

				rootDescription:CreateButton(L("GUILD_BROKER_MENU_REMOVE"), function()
					GuildBroker:RemoveMember(data)
				end)
			end
		end)
	elseif BFL.OpenContextMenu then
		-- Classic fallback: Use WoW friend-style context menu for guild members
		-- The guild roster index-based popup actions work via SetGuildRosterSelection
		if data.index then
			SetGuildRosterSelection(data.index)
		end
		-- Fallback to basic dropdown
		if UIDROPDOWNMENU_INIT_MENU then
			ToggleDropDownMenu(1, nil, _G["GuildMemberDropDown"], "cursor", 0, 0)
		end
	end
end

-- ========================================
-- Rank Management (SetGuildRankOrder / RemoveFromGuild)
-- ========================================

-- Get member GUID via C_Club
local function GetMemberGUID(memberData)
	if not C_Club or not C_Club.GetGuildClubId or not C_Club.GetMemberInfo then
		return nil, nil
	end

	local clubId = C_Club.GetGuildClubId()
	if not clubId then
		return nil, nil
	end

	-- Find member by name in club roster
	local members = C_Club.GetClubMembers(clubId)
	if not members then
		return nil, nil
	end

	for _, memberId in ipairs(members) do
		local memberInfo = C_Club.GetMemberInfo(clubId, memberId)
		if memberInfo then
			local infoName = memberInfo.name
			if BFL.HasSecretValues and BFL:IsSecret(infoName) then
				-- Cannot compare secret names
			elseif infoName and memberData.fullName then
				-- C_Club names may or may not have realm suffix
				if infoName == memberData.fullName or infoName == memberData.name then
					return memberInfo.guid, memberInfo.guildRankOrder
				end
			end
		end
	end

	return nil, nil
end

function GuildBroker:PromoteMember(data)
	if BFL:IsActionRestricted() then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	if not CanGuildPromote or not CanGuildPromote() then
		BFL:DebugPrint(L("GUILD_BROKER_NO_PERMISSION"))
		return
	end

	local guid, currentRankOrder = GetMemberGUID(data)
	if not guid then
		BFL:DebugPrint("Could not resolve member GUID for rank change.")
		return
	end

	if BFL.HasSecretValues and BFL:IsSecret(guid) then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	if not currentRankOrder or currentRankOrder <= 1 then
		return -- Already highest rank or GM
	end

	local newRankOrder = currentRankOrder - 1

	-- Get rank name for confirmation
	local newRankName = GuildControlGetRankName and GuildControlGetRankName(newRankOrder + 1) or "?"

	-- Confirmation dialog
	StaticPopupDialogs["BFL_GUILD_PROMOTE"] = {
		text = string.format(L("GUILD_BROKER_PROMOTE_CONFIRM"), data.name or "?", newRankName),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if C_GuildInfo and C_GuildInfo.SetGuildRankOrder then
				C_GuildInfo.SetGuildRankOrder(guid, newRankOrder)
			end
		end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("BFL_GUILD_PROMOTE")
end

function GuildBroker:DemoteMember(data)
	if BFL:IsActionRestricted() then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	if not CanGuildDemote or not CanGuildDemote() then
		BFL:DebugPrint(L("GUILD_BROKER_NO_PERMISSION"))
		return
	end

	local guid, currentRankOrder = GetMemberGUID(data)
	if not guid then
		BFL:DebugPrint("Could not resolve member GUID for rank change.")
		return
	end

	if BFL.HasSecretValues and BFL:IsSecret(guid) then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	local numRanks = GuildControlGetNumRanks and GuildControlGetNumRanks() or 10
	if not currentRankOrder or currentRankOrder >= (numRanks - 1) then
		return -- Already lowest rank
	end

	local newRankOrder = currentRankOrder + 1
	local newRankName = GuildControlGetRankName and GuildControlGetRankName(newRankOrder + 1) or "?"

	StaticPopupDialogs["BFL_GUILD_DEMOTE"] = {
		text = string.format(L("GUILD_BROKER_DEMOTE_CONFIRM"), data.name or "?", newRankName),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if C_GuildInfo and C_GuildInfo.SetGuildRankOrder then
				C_GuildInfo.SetGuildRankOrder(guid, newRankOrder)
			end
		end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("BFL_GUILD_DEMOTE")
end

function GuildBroker:RemoveMember(data)
	if BFL:IsActionRestricted() then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	if not CanGuildRemove or not CanGuildRemove() then
		BFL:DebugPrint(L("GUILD_BROKER_NO_PERMISSION"))
		return
	end

	local guid = GetMemberGUID(data)
	if not guid then
		BFL:DebugPrint("Could not resolve member GUID for removal.")
		return
	end

	if BFL.HasSecretValues and BFL:IsSecret(guid) then
		BFL:DebugPrint(L("GUILD_BROKER_ACTION_RESTRICTED"))
		return
	end

	StaticPopupDialogs["BFL_GUILD_REMOVE"] = {
		text = string.format(L("GUILD_BROKER_REMOVE_CONFIRM"), data.name or "?"),
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if C_GuildInfo and C_GuildInfo.RemoveFromGuild then
				C_GuildInfo.RemoveFromGuild(guid)
			end
		end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("BFL_GUILD_REMOVE")
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
	BFL.BrokerUtils.ClearActiveBrokerTooltip()

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
		table.insert(footerFrame.lines, fs)
		fs:SetText(text)
		fs:Show()
		return fs
	end

	local function AddSeparator()
		local line = footerFrame:CreateTexture(nil, "OVERLAY")
		line:SetHeight(1)
		line:SetColorTexture(0.5, 0.5, 0.5, 0.3)
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
	if not LQT or not data then
		return
	end

	if detailTooltip then
		LQT:ReleaseTooltip(detailTooltip)
		detailTooltip = nil
	end

	local tt2 = LQT:AcquireTooltip(detailTooltipKey, 2, "LEFT", "RIGHT")
	tt2:Clear()
	tt2:SmartAnchorTo(cell)
	tt2:SetAutoHideDelay(0.25, tooltip)
	tt2:SetFrameStrata("HIGH")
	tt2:SetFrameLevel(tooltip:GetFrameLevel() + 10)

	-- Hook OnHide to clean up ElvUI skin when detail tooltip is released/hidden
	local oldOnHide2 = tt2:GetScript("OnHide")
	tt2:SetScript("OnHide", function(self)
		RemoveElvUISkin(self)
		if oldOnHide2 then
			pcall(oldOnHide2, self)
		end
	end)

	-- ElvUI Skin: Apply ElvUI template (hides NineSlice, applies ElvUI backdrop)
	ApplyElvUISkin(tt2)

	-- Header
	local headerRow = tt2:AddHeadingRow()
	local headerCell = headerRow:GetCell(1)
	headerCell:SetColSpan(2)
	headerCell:SetFontObject(BetterFriendlistFontNormalLarge or "GameTooltipHeaderText")
	headerCell:SetJustifyH("LEFT")
	headerCell:SetText(ClassColorTextByFile(data.classFile, data.name or "Unknown"))
	tt2:AddSeparator()

	-- Rank
	if data.rank and data.rank ~= "" then
		local rankRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_RANK")), data.rank)
	end

	-- Level
	if data.level and data.level > 0 then
		local levelRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_LEVEL")), GetColoredLevelText(data.level))
	end

	-- Class
	if data.className and data.className ~= "" then
		local classRow = tt2:AddRow(
			C("ltblue", L("GUILD_BROKER_COL_CLASS")),
			ClassColorTextByFile(data.classFile, data.className)
		)
	end

	-- Zone
	if data.zone and data.zone ~= "" then
		local zoneRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_ZONE")), data.zone)
	end

	-- Status
	if data.online then
		if data.isAFK then
			local statusRow = tt2:AddRow(C("ltblue", "Status"), C("gold", AWAY or "Away"))
		elseif data.isDND then
			local statusRow = tt2:AddRow(C("ltblue", "Status"), C("gold", DND or "DND"))
		end
	else
		local lastOnline = FormatLastOnline(
			data.lastOnlineYears, data.lastOnlineMonths, data.lastOnlineDays, data.lastOnlineHours
		)
		if lastOnline and lastOnline ~= "" then
			local lastRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_LAST_ONLINE")), C("gray", lastOnline))
		end
	end

	-- Note
	if data.note and data.note ~= "" then
		tt2:AddSeparator()
		local noteRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_NOTE")), C("white", data.note))
	end

	-- Officer Note
	local canViewOfficer = C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote()
	if canViewOfficer and data.officerNote and data.officerNote ~= "" then
		local offNoteRow = tt2:AddRow(C("ltblue", L("GUILD_BROKER_COL_OFFICER_NOTE")), C("ltyellow", data.officerNote))
	end

	tt2:UpdateLayout()
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
		{ key = "Name",        label = L("GUILD_BROKER_COL_NAME"),         align = "LEFT",   setting = "guildBrokerShowColName" },
		{ key = "Level",       label = L("GUILD_BROKER_COL_LEVEL"),        align = "CENTER", setting = "guildBrokerShowColLevel" },
		{ key = "Class",       label = L("GUILD_BROKER_COL_CLASS"),        align = "LEFT",   setting = "guildBrokerShowColClass" },
		{ key = "Rank",        label = L("GUILD_BROKER_COL_RANK"),         align = "LEFT",   setting = "guildBrokerShowColRank" },
		{ key = "Zone",        label = L("GUILD_BROKER_COL_ZONE"),         align = "LEFT",   setting = "guildBrokerShowColZone" },
		{ key = "Note",        label = L("GUILD_BROKER_COL_NOTE"),         align = "LEFT",   setting = "guildBrokerShowColNote" },
		{ key = "OfficerNote", label = L("GUILD_BROKER_COL_OFFICER_NOTE"), align = "LEFT",   setting = "guildBrokerShowColOfficerNote" },
		{ key = "LastOnline",  label = L("GUILD_BROKER_COL_LAST_ONLINE"),  align = "CENTER", setting = "guildBrokerShowColLastOnline" },
	}

	-- Build active columns based on settings and column order
	local columnOrder = BetterFriendlistDB and BetterFriendlistDB.guildBrokerColumnOrder
	local activeColumns = {}

	if columnOrder and #columnOrder > 0 then
		for _, colKey in ipairs(columnOrder) do
			for _, c in ipairs(columns) do
				if c.key == colKey and BetterFriendlistDB[c.setting] ~= false then
					table.insert(activeColumns, c)
					break
				end
			end
		end
	else
		for _, col in ipairs(columns) do
			if BetterFriendlistDB[col.setting] ~= false then
				table.insert(activeColumns, col)
			end
		end
	end

	-- Officer Note visibility gated by permission
	local canViewOfficer = C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote()
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
		if not IsInGuild() then
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
			tt:AddSeparator()

			local noGuildRow = tt:AddRow()
			local noGuildCell = noGuildRow:GetCell(1)
			noGuildCell:SetColSpan(numColumns)
			noGuildCell:SetJustifyH("CENTER")
			noGuildCell:SetText(C("gray", L("GUILD_BROKER_NO_GUILD")))

			-- Show icon action hints if enabled
			local showHints = BetterFriendlistDB and BetterFriendlistDB.guildBrokerShowHints ~= false
			if showHints then
				tt:AddSeparator()
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

		local guildName = GetGuildInfo("player") or L("GUILD_BROKER_NO_GUILD")
		headerCell:SetText(C("dkyellow", guildName))
		tt:AddSeparator()

		-- Column Headers
		local headerCells = {}
		for _, col in ipairs(activeColumns) do
			table.insert(headerCells, C("ltyellow", col.label))
		end
		tt:AddRow(unpack(headerCells))
		tt:AddSeparator()

		-- Collect and process roster data
		local members = GuildBroker:CollectGuildRoster()

		-- Apply filter
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.guildBrokerFilter or "online"
		members = FilterMembers(members, currentFilter)

		-- Apply sort (online first, then by name)
		table.sort(members, CompareMembers)

		-- Apply grouping
		local groupMode = BetterFriendlistDB and BetterFriendlistDB.guildBrokerGroupMode or "none"
		local groupData, flatMembers = GroupMembers(members, groupMode)

		local displayedCount = 0

		-- Helper: render a single member row
		local function RenderMemberRow(member, indent)
			indent = indent or ""
			local cellValues = {}

			for _, col in ipairs(activeColumns) do
				local val = ""
				if col.key == "Name" then
					local statusIcon = ""
					if member.online then
						statusIcon = GetStatusIcon(member.isAFK, member.isDND, member.isMobile) .. " "
					end
					local nameText = ClassColorTextByFile(member.classFile, member.name or "Unknown")
					if not member.online then
						nameText = C("gray", member.name or "Unknown")
					end
					val = indent .. statusIcon .. nameText
				elseif col.key == "Level" then
					if member.online then
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
				elseif col.key == "Rank" then
					val = member.online and (member.rank or "") or C("gray", member.rank or "")
				elseif col.key == "Zone" then
					val = member.online and (member.zone or "") or ""
				elseif col.key == "Note" then
					val = member.note or ""
				elseif col.key == "OfficerNote" then
					val = member.officerNote or ""
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
				if detailTooltip then
					-- Let auto-hide handle it
				end
			end)

			-- Click handler
			row:SetScript("OnMouseUp", function(frame, button)
				OnMemberLineClick(nil, member, button)
			end)

			displayedCount = displayedCount + 1
		end

		-- Render content: grouped or flat
		if groupData then
			local collapsedGroups = BetterFriendlistDB and BetterFriendlistDB.guildBrokerCollapsedGroups or {}

			for _, groupKey in ipairs(groupData.order) do
				local groupMembers = groupData.groups[groupKey]
				if groupMembers and #groupMembers > 0 then
					local collapsed = collapsedGroups[groupKey]

					-- Group header row
					local groupRow = tt:AddRow()
					local groupCell = groupRow:GetCell(1)
					groupCell:SetColSpan(numColumns)
					groupCell:SetJustifyH("LEFT")

					local prefix = collapsed and "(+) " or "(-) "
					local countText = string.format("(%d)", #groupMembers)

					-- Color by class file for class grouping
					local headerText
					if groupMode == "by_class" then
						local sampleMember = groupMembers[1]
						headerText = prefix .. ClassColorTextByFile(sampleMember.classFile, groupKey) .. " " .. C("gray", countText)
					else
						headerText = prefix .. C("gold", groupKey) .. " " .. C("gray", countText)
					end
					groupCell:SetText("  " .. headerText)

					-- Group header hover
					groupRow:SetScript("OnEnter", function()
						groupRow:SetColor(0.2, 0.2, 0.2, 0.5)
						if detailTooltip then
							LQT:ReleaseTooltip(detailTooltip)
							detailTooltip = nil
						end
					end)
					groupRow:SetScript("OnLeave", function()
						groupRow:SetColor(0, 0, 0, 0)
					end)

					-- Toggle collapse on click
					groupRow:SetScript("OnMouseUp", function()
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
			tt:AddSeparator()
			local emptyRow = tt:AddRow()
			local emptyCell = emptyRow:GetCell(1)
			emptyCell:SetColSpan(numColumns)
			emptyCell:SetJustifyH("CENTER")
			emptyCell:SetText(C("gray", L("GUILD_BROKER_NO_MEMBERS_ONLINE")))
		end

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
	gameTooltip:AddLine(L("GUILD_BROKER_TITLE"), 1, 0.82, 0, 1)
	gameTooltip:AddLine(" ")

	if not IsInGuild() then
		gameTooltip:AddLine(L("GUILD_BROKER_NO_GUILD"), 0.7, 0.7, 0.7)
		return
	end

	local guildName = GetGuildInfo("player") or ""
	gameTooltip:AddLine(guildName, 0, 1, 0)
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
		local Settings = BFL:GetModule("Settings")
		if Settings and Settings.OpenSettingsTab then
			Settings:OpenSettingsTab("broker")
		elseif BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			-- Toggle frame
		else
			if ToggleGuildFrame then
				ToggleGuildFrame()
			elseif GuildFrame_Toggle then
				GuildFrame_Toggle()
			end
		end
	else
		-- Left click: configurable action
local action = BetterFriendlistDB and BetterFriendlistDB.guildBrokerClickAction or "guild_frame"

		if action == "settings" then
			local Settings = BFL:GetModule("Settings")
			if Settings and Settings.OpenSettingsTab then
				Settings:OpenSettingsTab("broker")
			end
		else
			-- Default: open guild frame
			if ToggleGuildFrame then
				ToggleGuildFrame()
			elseif GuildFrame_Toggle then
				GuildFrame_Toggle()
			end
		end
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
			BFL.GuildRoster()
			tooltip = CreateLibQTipTooltip(anchorFrame)
		end
		dataObjectDef.OnLeave = function() end
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
		if IsInGuild() then
			BFL.GuildRoster()
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
		GuildBroker:UpdateBrokerText()
		GuildBroker:RefreshTooltip()
	end, 50)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function()
		GuildBroker:InvalidateCache()
		GuildBroker:UpdateBrokerText()
		if IsInGuild() then
			BFL.GuildRoster()
		end
	end, 50)

	if BFL.RegisterEventCallback then
		-- GUILD_RANKS_UPDATE may not exist on all versions
		pcall(function()
			BFL:RegisterEventCallback("GUILD_RANKS_UPDATE", function()
				GuildBroker:InvalidateCache()
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
