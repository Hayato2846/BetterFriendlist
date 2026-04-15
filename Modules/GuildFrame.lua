-- Modules/GuildFrame.lua
-- Guild Roster Tab Module
-- Displays guild members with search, filter, sort, and group integration

local ADDON_NAME, BFL = ...
local FontManager = BFL.FontManager

-- Register Module
local GuildFrame = BFL:RegisterModule("GuildFrame", {})

-- ========================================
-- Local Variables
-- ========================================

local L -- Set during Initialize (BFL.L)

-- Constants
local BUTTON_HEIGHT = 22
local CLASS_ICON_SIZE = 14
local CLASS_ICON_OFFSET = 4
local NAME_OFFSET_WITH_ICON = 22
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local ROSTER_REFRESH_THROTTLE = 10 -- seconds (WoW server enforces this)

-- Sort modes
local SORT_NAME = "name"
local SORT_RANK = "rank"
local SORT_LEVEL = "level"
local SORT_CLASS = "class"
local SORT_ZONE = "zone"

-- Filter modes
local FILTER_ALL = "all"
local FILTER_ONLINE = "online"
local FILTER_OFFLINE = "offline"

-- State
local guildDataProvider = nil
local needsRenderOnShow = false
local lastRosterRequestTime = 0

-- Dirty flag: Set when data changes while frame is hidden
local rosterDirty = true

-- Zebra stripe colors (same as WhoFrame)
local ZEBRA_EVEN_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.3 }
local ZEBRA_ODD_COLOR = { r = 0, g = 0, b = 0, a = 0 }

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB()
	return BFL:GetModule("DB")
end

-- ========================================
-- Module Lifecycle
-- ========================================

function GuildFrame:Initialize()
	L = BFL.L

	-- State
	self.guildMembers = {}
	self.displayList = {}
	self.filterMode = FILTER_ONLINE
	self.searchText = ""
	self.sortMode = SORT_RANK
	self.sortReversed = {}
	self.selectedMember = nil
	self.totalMembers = 0
	self.onlineMembers = 0

	-- Register events
	BFL:RegisterEventCallback("GUILD_ROSTER_UPDATE", function(...)
		self:OnGuildRosterUpdate(...)
	end, 50)

	BFL:RegisterEventCallback("GUILD_MOTD", function(motd)
		self:UpdateMOTD()
	end, 50)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function(...)
		self:OnPlayerGuildUpdate(...)
	end, 50)

	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function()
			if needsRenderOnShow then
				local guildFrame = BetterFriendsFrame.GuildFrame
				if guildFrame and guildFrame:IsShown() then
					self:Refresh()
					needsRenderOnShow = false
				end
			end
		end)
	end
end

function GuildFrame:OnPlayerLogin()
	-- Request initial guild roster data if in a guild
	if IsInGuild() then
		self:RequestRosterUpdate()
	end
end

-- ========================================
-- Event Handlers
-- ========================================

function GuildFrame:OnGuildRosterUpdate(canRequestRosterUpdate)
	rosterDirty = true

	-- Check if our frame is visible
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if guildFrame and guildFrame:IsShown() then
		self:Refresh()
	else
		needsRenderOnShow = true
	end
end

function GuildFrame:OnPlayerGuildUpdate(unitTarget)
	rosterDirty = true

	-- Update empty state visibility
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if guildFrame and guildFrame:IsShown() then
		self:UpdateEmptyState()
		if IsInGuild() then
			self:RequestRosterUpdate()
		end
	else
		needsRenderOnShow = true
	end
end

-- ========================================
-- Roster Data Layer
-- ========================================

function GuildFrame:RequestRosterUpdate()
	local now = GetTime()
	if (now - lastRosterRequestTime) < ROSTER_REFRESH_THROTTLE then
		return false -- Throttled
	end
	lastRosterRequestTime = now
	BFL.GuildRoster()
	return true
end

function GuildFrame:CollectRoster()
	if not IsInGuild() then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		return
	end

	local numTotal, numOnline = GetNumGuildMembers()
	self.totalMembers = numTotal or 0
	self.onlineMembers = numOnline or 0

	local members = {}

	for i = 1, (numTotal or 0) do
		local fullName, rank, rankIndex, level, className, zone, note, officerNote, online, status, classFile,
			achievementPoints, achievementRank, isMobile, isSoREligible, standingID, guid = BFL.GetGuildRosterInfo(i)

		if fullName then
			local name, realm = strsplit("-", fullName, 2)
			local isAFK = (status == 1)
			local isDND = (status == 2)

			-- Last online time
			local lastYears, lastMonths, lastDays, lastHours = 0, 0, 0, 0
			if not online then
				lastYears, lastMonths, lastDays, lastHours = BFL.GetGuildRosterLastOnline(i)
			end

			-- Secret value guards (12.0+)
			local safeName = fullName
			local safeParsedName = name
			local safeZone = zone or ""
			if BFL.HasSecretValues then
				if BFL:IsSecret(fullName) then
					safeName = "Unknown"
					safeParsedName = "Unknown"
				end
				if BFL:IsSecret(zone) then
					safeZone = ""
				end
			end

			members[#members + 1] = {
				guildIndex = i,
				fullName = safeName,
				name = safeParsedName or safeName,
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
				achievementPoints = achievementPoints or 0,
				achievementRank = achievementRank or 0,
				guid = guid or "",
				lastOnlineYears = lastYears or 0,
				lastOnlineMonths = lastMonths or 0,
				lastOnlineDays = lastDays or 0,
				lastOnlineHours = lastHours or 0,
			}
		end
	end

	self.guildMembers = members
	rosterDirty = false
end

-- ========================================
-- Filter & Search
-- ========================================

function GuildFrame:SetFilter(mode)
	self.filterMode = mode
	self:Refresh()
end

function GuildFrame:SetSearchText(text)
	self.searchText = (text or ""):lower()
	self:Refresh()
end

function GuildFrame:PassesFilter(member)
	-- Filter mode
	if self.filterMode == FILTER_ONLINE then
		if not member.online then return false end
	elseif self.filterMode == FILTER_OFFLINE then
		if member.online then return false end
	end

	-- Search text
	if self.searchText ~= "" then
		local s = self.searchText
		if member.name:lower():find(s, 1, true) then return true end
		if member.rank:lower():find(s, 1, true) then return true end
		if member.zone:lower():find(s, 1, true) then return true end
		if member.className:lower():find(s, 1, true) then return true end
		if member.note:lower():find(s, 1, true) then return true end
		if C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote() then
			if member.officerNote:lower():find(s, 1, true) then return true end
		end
		return false
	end

	return true
end

-- ========================================
-- Sorting
-- ========================================

function GuildFrame:SetSort(mode)
	if self.sortMode == mode then
		-- Toggle reverse on same column
		self.sortReversed[mode] = not self.sortReversed[mode]
	else
		self.sortMode = mode
	end
	self:Refresh()
end

function GuildFrame:SortMembers(list)
	local mode = self.sortMode
	local reversed = self.sortReversed[mode]

	table.sort(list, function(a, b)
		-- Online always first
		if a.online ~= b.online then
			return a.online
		end

		local result = false

		if mode == SORT_NAME then
			result = a.name:lower() < b.name:lower()
		elseif mode == SORT_RANK then
			if a.rankIndex ~= b.rankIndex then
				result = a.rankIndex < b.rankIndex
			else
				result = a.name:lower() < b.name:lower()
			end
		elseif mode == SORT_LEVEL then
			if a.level ~= b.level then
				result = a.level > b.level -- Higher level first
			else
				result = a.name:lower() < b.name:lower()
			end
		elseif mode == SORT_CLASS then
			if a.className ~= b.className then
				result = a.className < b.className
			else
				result = a.name:lower() < b.name:lower()
			end
		elseif mode == SORT_ZONE then
			if a.zone ~= b.zone then
				result = a.zone < b.zone
			else
				result = a.name:lower() < b.name:lower()
			end
		else
			result = a.name:lower() < b.name:lower()
		end

		if reversed then
			return not result
		end
		return result
	end)
end

-- ========================================
-- Build Display List
-- ========================================

function GuildFrame:BuildDisplayList()
	if rosterDirty then
		self:CollectRoster()
	end

	local filtered = {}
	for _, member in ipairs(self.guildMembers) do
		if self:PassesFilter(member) then
			filtered[#filtered + 1] = member
		end
	end

	self:SortMembers(filtered)
	self.displayList = filtered
	return filtered
end

-- ========================================
-- Refresh & Render (Retail ScrollBox)
-- ========================================

function GuildFrame:Refresh()
	self:BuildDisplayList()

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	-- Update header info
	self:UpdateHeaderInfo()
	self:UpdateEmptyState()
	self:UpdateFilterHighlight()

	-- Update scroll list
	if BFL.HasModernScrollBox then
		self:UpdateRetailScrollBox()
	else
		self:UpdateClassicScrollFrame()
	end
end

function GuildFrame:UpdateRetailScrollBox()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.ScrollBox then return end
	if not guildDataProvider then return end

	guildDataProvider:Flush()

	for i, member in ipairs(self.displayList) do
		guildDataProvider:Insert({
			index = i,
			member = member,
		})
	end
end

-- ========================================
-- Classic FauxScrollFrame
-- ========================================

function GuildFrame:UpdateClassicScrollFrame()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.FauxScroll then return end

	local displayList = self.displayList
	local numEntries = #displayList

	FauxScrollFrame_Update(guildFrame.FauxScroll, numEntries, 15, BUTTON_HEIGHT)

	local offset = FauxScrollFrame_GetOffset(guildFrame.FauxScroll)

	for i = 1, 15 do
		local dataIndex = offset + i
		local button = self.classicButtons and self.classicButtons[i]
		if button then
			if dataIndex <= numEntries then
				local member = displayList[dataIndex]
				self:UpdateMemberButton(button, member, dataIndex)
				button:Show()
			else
				button:Hide()
			end
		end
	end
end

function GuildFrame:InitializeClassicScrollFrame(guildFrame)
	if not guildFrame.FauxScroll then return end

	self.classicButtons = {}
	for i = 1, 15 do
		local button = CreateFrame("Button", "BFL_GuildMemberButton" .. i, guildFrame.FauxScroll, nil)
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("TOPLEFT", guildFrame.FauxScroll, "TOPLEFT", 0, -((i - 1) * BUTTON_HEIGHT))
		button:SetPoint("TOPRIGHT", guildFrame.FauxScroll, "TOPRIGHT", 0, -((i - 1) * BUTTON_HEIGHT))

		self:SetupMemberButton(button)

		button:SetScript("OnClick", function(btn, mouseButton)
			self:OnMemberClick(btn, mouseButton)
		end)

		button:SetScript("OnEnter", function(btn)
			self:OnMemberEnter(btn)
		end)

		button:SetScript("OnLeave", function(btn)
			GameTooltip:Hide()
		end)

		self.classicButtons[i] = button
	end

	guildFrame.FauxScroll:SetScript("OnVerticalScroll", function(scroll, scrollOffset)
		FauxScrollFrame_OnVerticalScroll(scroll, scrollOffset, BUTTON_HEIGHT, function()
			self:UpdateClassicScrollFrame()
		end)
	end)
end

-- ========================================
-- Retail ScrollBox Initialization
-- ========================================

function GuildFrame:OnLoad(frame)
	-- Set locale text for buttons
	if frame.OpenBlizzardGuildButton and L then
		frame.OpenBlizzardGuildButton:SetText(L.GUILD_OPEN_MANAGEMENT or "Guild Management")
	end
	if frame.FilterOffline and L then
		frame.FilterOffline:SetText(FRIENDS_LIST_OFFLINE or "Offline")
	end

	-- NOTE: Guild top tab button setup (text, show/hide) is handled in BetterFriendlist.lua
	-- ADDON_LOADED and FrameInitializer.lua, not here.

	if BFL.IsClassic or not BFL.HasModernScrollBox then
		self:InitializeClassicScrollFrame(frame)
		return
	end

	-- Retail: Initialize ScrollBox with DataProvider
	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("BFL_GuildMemberButtonTemplate", function(button, elementData)
		if not button._bflSetup then
			self:SetupMemberButton(button)
			button._bflSetup = true
		end
		self:UpdateMemberButton(button, elementData.member, elementData.index)
	end)

	view:SetElementExtentCalculator(function(dataIndex, elementData)
		return BUTTON_HEIGHT
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

	-- Anchor ScrollBox inside ListInset
	frame.ScrollBox:ClearAllPoints()
	frame.ScrollBox:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -4, 4)

	-- Create DataProvider
	guildDataProvider = CreateDataProvider()
	frame.ScrollBox:SetDataProvider(guildDataProvider)

	-- Empty state
	self:CreateEmptyState(frame)
end

-- ========================================
-- Button Setup & Update
-- ========================================

function GuildFrame:SetupMemberButton(button)
	-- Background (zebra striping)
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0, 0, 0, 0)

	-- Class icon
	button.classIcon = button:CreateTexture(nil, "ARTWORK")
	button.classIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
	button.classIcon:SetPoint("LEFT", button, "LEFT", CLASS_ICON_OFFSET, 0)
	button.classIcon:SetTexture(CLASS_ICON_TEXTURE)

	-- Name text
	button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.nameText:SetPoint("LEFT", button.classIcon, "RIGHT", 4, 0)
	button.nameText:SetJustifyH("LEFT")

	-- Rank text
	button.rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.rankText:SetJustifyH("LEFT")
	button.rankText:SetTextColor(0.6, 0.6, 0.6)

	-- Level text
	button.levelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.levelText:SetJustifyH("CENTER")

	-- Zone text
	button.zoneText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.zoneText:SetJustifyH("LEFT")

	-- Highlight texture
	button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(1, 1, 1, 0.1)

	-- Enable mouse
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function GuildFrame:UpdateMemberButton(button, member, dataIndex)
	if not button or not member then return end

	-- Store reference
	button.memberData = member

	-- Zebra striping
	if dataIndex % 2 == 0 then
		button.bg:SetColorTexture(ZEBRA_EVEN_COLOR.r, ZEBRA_EVEN_COLOR.g, ZEBRA_EVEN_COLOR.b, ZEBRA_EVEN_COLOR.a)
	else
		button.bg:SetColorTexture(ZEBRA_ODD_COLOR.r, ZEBRA_ODD_COLOR.g, ZEBRA_ODD_COLOR.b, ZEBRA_ODD_COLOR.a)
	end

	-- Class icon
	local classCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.classFile]
	if classCoords and button.classIcon then
		button.classIcon:SetTexCoord(unpack(classCoords))
		button.classIcon:Show()
	elseif button.classIcon then
		button.classIcon:Hide()
	end

	-- Name with class color
	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.classFile]
	local nameColor = classColor and format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255) or "|cffffffff"
	local statusSuffix = ""
	if member.isAFK then
		statusSuffix = " |cffff8000" .. (CHAT_FLAG_AFK or "<AFK>") .. "|r"
	elseif member.isDND then
		statusSuffix = " |cffff0000" .. (CHAT_FLAG_DND or "<DND>") .. "|r"
	elseif member.isMobile then
		statusSuffix = " |cff82c5ff" .. (REMOTE_CHAT or "(Mobile)") .. "|r"
	end

	if button.nameText then
		local displayName = Ambiguate(member.fullName, "guild")
		if member.online then
			button.nameText:SetText(nameColor .. displayName .. "|r" .. statusSuffix)
		else
			button.nameText:SetText("|cff808080" .. displayName .. "|r")
		end
	end

	-- Rank
	if button.rankText then
		button.rankText:SetText(member.rank)
	end

	-- Level
	if button.levelText then
		if member.online then
			-- Color by difficulty
			local color = GetQuestDifficultyColor and GetQuestDifficultyColor(member.level)
			if color then
				button.levelText:SetTextColor(color.r, color.g, color.b)
			else
				button.levelText:SetTextColor(1, 1, 1)
			end
		else
			button.levelText:SetTextColor(0.5, 0.5, 0.5)
		end
		button.levelText:SetText(member.level)
	end

	-- Zone
	if button.zoneText then
		if member.online then
			button.zoneText:SetText(member.zone)
			button.zoneText:SetTextColor(0.8, 0.8, 0.6)
		else
			-- Offline: Show last online time
			button.zoneText:SetText(self:FormatLastOnline(member))
			button.zoneText:SetTextColor(0.5, 0.5, 0.5)
		end
	end

	-- Apply responsive column widths
	self:ApplyColumnWidths(button)
end

-- ========================================
-- Last Online Formatting
-- ========================================

function GuildFrame:FormatLastOnline(member)
	local years = member.lastOnlineYears or 0
	local months = member.lastOnlineMonths or 0
	local days = member.lastOnlineDays or 0
	local hours = member.lastOnlineHours or 0

	if years > 0 then
		return format(GUILD_LASTONLINE_YEARS or "%d yr", years)
	elseif months > 0 then
		return format(GUILD_LASTONLINE_MONTHS or "%d mo", months)
	elseif days > 0 then
		return format(GUILD_LASTONLINE_DAYS or "%d d", days)
	elseif hours > 0 then
		return format(GUILD_LASTONLINE_HOURS or "%d hr", hours)
	else
		return LASTONLINE_SECONDS or "< 1 hr"
	end
end

-- ========================================
-- Header Info (Guild name, MOTD, counts)
-- ========================================

function GuildFrame:UpdateHeaderInfo()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	-- Guild name
	if guildFrame.GuildName then
		if IsInGuild() then
			local guildName = GetGuildInfo("player")
			guildFrame.GuildName:SetText(guildName or "")
		else
			guildFrame.GuildName:SetText("")
		end
	end

	-- Member count
	if guildFrame.MemberCount then
		local displayCount = #self.displayList
		if self.filterMode == FILTER_ALL and self.searchText == "" then
			guildFrame.MemberCount:SetText(format("%d/%d", self.onlineMembers, self.totalMembers))
		else
			guildFrame.MemberCount:SetText(format("%d " .. (L and L.GUILD_RESULTS_SHOWN or "shown"), displayCount))
		end
	end

	-- MOTD
	self:UpdateMOTD()
end

function GuildFrame:UpdateMOTD()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.MOTDText then return end

	if IsInGuild() then
		local motd = GetGuildRosterMOTD()
		if motd and motd ~= "" then
			guildFrame.MOTDText:SetText(motd)
			guildFrame.MOTDText:Show()
		else
			guildFrame.MOTDText:SetText("")
			guildFrame.MOTDText:Hide()
		end
	else
		guildFrame.MOTDText:SetText("")
		guildFrame.MOTDText:Hide()
	end
end

-- ========================================
-- Filter Highlight (which filter button is active)
-- ========================================

function GuildFrame:UpdateFilterHighlight()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	local buttons = {
		{ btn = guildFrame.FilterAll, mode = FILTER_ALL },
		{ btn = guildFrame.FilterOnline, mode = FILTER_ONLINE },
		{ btn = guildFrame.FilterOffline, mode = FILTER_OFFLINE },
	}

	for _, entry in ipairs(buttons) do
		if entry.btn then
			if entry.mode == self.filterMode then
				entry.btn:SetNormalFontObject("GameFontHighlightSmall")
			else
				entry.btn:SetNormalFontObject("GameFontNormalSmall")
			end
		end
	end
end

-- ========================================
-- Empty State
-- ========================================

function GuildFrame:CreateEmptyState(frame)
	if frame.EmptyText then return end

	local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
	emptyText:SetTextColor(0.5, 0.5, 0.5)
	frame.EmptyText = emptyText
end

function GuildFrame:UpdateEmptyState()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	local hasContent = false

	if not IsInGuild() then
		if guildFrame.EmptyText then
			guildFrame.EmptyText:SetText(L and L.GUILD_NOT_IN_GUILD or "You are not in a guild.")
			guildFrame.EmptyText:Show()
		end
	elseif #self.displayList == 0 then
		if guildFrame.EmptyText then
			guildFrame.EmptyText:SetText(L and L.GUILD_NO_RESULTS or "No members found.")
			guildFrame.EmptyText:Show()
		end
	else
		hasContent = true
		if guildFrame.EmptyText then
			guildFrame.EmptyText:Hide()
		end
	end

	-- Show/hide scroll area
	if BFL.HasModernScrollBox then
		if guildFrame.ScrollBox then
			if hasContent then
				guildFrame.ScrollBox:Show()
			else
				guildFrame.ScrollBox:Hide()
			end
		end
		if guildFrame.ScrollBar then
			if hasContent then
				guildFrame.ScrollBar:Show()
			else
				guildFrame.ScrollBar:Hide()
			end
		end
	else
		if guildFrame.FauxScroll then
			if hasContent then
				guildFrame.FauxScroll:Show()
			else
				guildFrame.FauxScroll:Hide()
			end
		end
	end
end

-- ========================================
-- Member Click Handlers
-- ========================================

function GuildFrame:OnMemberClick(button, mouseButton)
	local member = button and button.memberData
	if not member then return end

	if mouseButton == "RightButton" then
		self:ShowContextMenu(button, member)
	else
		self.selectedMember = member
	end
end

function GuildFrame:OnMemberEnter(button)
	local member = button and button.memberData
	if not member then return end

	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()

	-- Name with class color
	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.classFile]
	if classColor then
		GameTooltip:AddLine(Ambiguate(member.fullName, "guild"), classColor.r, classColor.g, classColor.b)
	else
		GameTooltip:AddLine(Ambiguate(member.fullName, "guild"))
	end

	-- Rank + Level + Class
	GameTooltip:AddLine(format("%s - %s %d %s", member.rank, LEVEL or "Level", member.level, member.className), 1, 1, 1)

	-- Zone
	if member.online and member.zone ~= "" then
		GameTooltip:AddLine(member.zone, 0.8, 0.8, 0.6)
	end

	-- Status
	if member.isAFK then
		GameTooltip:AddLine(CHAT_FLAG_AFK or "<AFK>", 1, 0.5, 0)
	elseif member.isDND then
		GameTooltip:AddLine(CHAT_FLAG_DND or "<DND>", 1, 0, 0)
	elseif member.isMobile then
		GameTooltip:AddLine(REMOTE_CHAT or "Remote Chat", 0.51, 0.77, 1)
	elseif not member.online then
		GameTooltip:AddLine(format("%s: %s", LASTONLINE or "Last Online", self:FormatLastOnline(member)), 0.5, 0.5, 0.5)
	end

	-- Notes
	if member.note and member.note ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format("%s: %s", NOTE_COLON or "Note:", member.note), 1, 1, 1, true)
	end
	if C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote() then
		if member.officerNote and member.officerNote ~= "" then
			GameTooltip:AddLine(format("%s: %s", OFFICER_NOTE_COLON or "Officer Note:", member.officerNote), 0.5, 1, 0.5, true)
		end
	end

	-- Achievement points
	if member.achievementPoints and member.achievementPoints > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format("%s: %d", ACHIEVEMENT_POINTS or "Achievement Points", member.achievementPoints), 1, 0.82, 0)
	end

	-- Hints
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L and L.GUILD_TOOLTIP_HINT or "Right-click for options", 0.5, 0.5, 0.5)

	GameTooltip:Show()
end

-- ========================================
-- Context Menu (placeholder - will be extended in MenuSystem)
-- ========================================

function GuildFrame:ShowContextMenu(button, member)
	-- Basic context menu using existing MenuSystem
	local MenuSystem = BFL:GetModule("MenuSystem")
	if MenuSystem and MenuSystem.ShowGuildMemberMenu then
		MenuSystem:ShowGuildMemberMenu(button, member)
	end
end

-- ========================================
-- Open Blizzard Guild Frame
-- ========================================

function GuildFrame:OpenBlizzardGuildUI()
	if BFL.IsClassic then
		local useClassicGuildUI = GetCVar("useClassicGuildUI")
		if useClassicGuildUI == "1" then
			SetCVar("useClassicGuildUI", "0")
		end
	end
	ToggleGuildFrame()
end

-- ========================================
-- Public API
-- ========================================

function GuildFrame:GetMemberByName(name)
	for _, member in ipairs(self.guildMembers) do
		if member.fullName == name or member.name == name then
			return member
		end
	end
	return nil
end

function GuildFrame:GetDisplayList()
	return self.displayList
end

function GuildFrame:GetMemberCount()
	return self.onlineMembers, self.totalMembers
end

-- ========================================
-- Column Width Management (Responsive)
-- ========================================

function GuildFrame:UpdateResponsiveLayout()
	local frame = BetterFriendsFrame
	if not frame or not frame.GuildFrame then return end

	local guildFrame = frame.GuildFrame
	local frameWidth = frame:GetWidth()

	-- Cache check
	local roundedWidth = math.floor(frameWidth + 0.5)
	if self._lastLayoutWidth == roundedWidth then return end
	self._lastLayoutWidth = roundedWidth

	-- Columns: Name (35%), Rank (20%), Level (8%), Zone (37%)
	local scrollbarAndPadding = 34
	local nameLeftPadding = NAME_OFFSET_WITH_ICON
	local headerOverlapGain = 6 -- 3 overlaps x 2px
	local effectiveWidth = frameWidth - nameLeftPadding - scrollbarAndPadding + headerOverlapGain

	local nameWidth = math.floor(effectiveWidth * 0.35)
	local rankWidth = math.floor(effectiveWidth * 0.20)
	local levelWidth = math.floor(effectiveWidth * 0.08)
	local zoneWidth = effectiveWidth - nameWidth - rankWidth - levelWidth

	nameWidth = math.max(nameWidth, 80)
	rankWidth = math.max(rankWidth, 50)
	levelWidth = math.max(levelWidth, 28)
	zoneWidth = math.max(zoneWidth, 60)

	self.columnWidths = {
		name = nameWidth,
		rank = rankWidth,
		level = levelWidth,
		zone = zoneWidth,
	}

	-- Update column headers
	if guildFrame.NameHeader then
		guildFrame.NameHeader:SetWidth(nameWidth)
		if guildFrame.NameHeader.Middle then
			guildFrame.NameHeader.Middle:SetWidth(nameWidth - 9)
		end
	end
	if guildFrame.RankHeader then
		guildFrame.RankHeader:SetWidth(rankWidth)
		if guildFrame.RankHeader.Middle then
			guildFrame.RankHeader.Middle:SetWidth(rankWidth - 9)
		end
	end
	if guildFrame.LevelHeader then
		guildFrame.LevelHeader:SetWidth(levelWidth)
		if guildFrame.LevelHeader.Middle then
			guildFrame.LevelHeader.Middle:SetWidth(levelWidth - 9)
		end
	end
	if guildFrame.ZoneHeader then
		guildFrame.ZoneHeader:SetWidth(zoneWidth)
		if guildFrame.ZoneHeader.Middle then
			guildFrame.ZoneHeader.Middle:SetWidth(zoneWidth - 9)
		end
	end

	-- Update button widths for Retail
	if BFL.HasModernScrollBox and guildDataProvider then
		self:UpdateRetailScrollBox()
	end
end

-- Apply column widths to a button's text elements
function GuildFrame:ApplyColumnWidths(button)
	if not self.columnWidths then return end

	local w = self.columnWidths

	if button.nameText then
		button.nameText:SetWidth(w.name - NAME_OFFSET_WITH_ICON)
	end
	if button.rankText then
		button.rankText:ClearAllPoints()
		button.rankText:SetPoint("LEFT", button, "LEFT", NAME_OFFSET_WITH_ICON + w.name + 2, 0)
		button.rankText:SetWidth(w.rank - 4)
	end
	if button.levelText then
		button.levelText:ClearAllPoints()
		button.levelText:SetPoint("LEFT", button, "LEFT", NAME_OFFSET_WITH_ICON + w.name + w.rank + 2, 0)
		button.levelText:SetWidth(w.level - 4)
	end
	if button.zoneText then
		button.zoneText:ClearAllPoints()
		button.zoneText:SetPoint("LEFT", button, "LEFT", NAME_OFFSET_WITH_ICON + w.name + w.rank + w.level + 2, 0)
		button.zoneText:SetWidth(w.zone - 4)
	end
end

-- ========================================
-- Global callbacks for XML
-- ========================================

function BFL_GuildFrame_OnLoad(frame)
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:OnLoad(frame)
	end
end

function BFL_GuildFrame_OnShow(frame)
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		-- Request roster update
		if IsInGuild() then
			GF:RequestRosterUpdate()
		end
		GF:Refresh()
		GF:UpdateResponsiveLayout()
	end
end

function BFL_GuildFrame_OnHide(frame)
	-- Nothing needed currently
end

function BFL_GuildFrame_SearchChanged(editBox)
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:SetSearchText(editBox:GetText())
	end
end

function BFL_GuildFrame_FilterAll()
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:SetFilter(FILTER_ALL)
	end
end

function BFL_GuildFrame_FilterOnline()
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:SetFilter(FILTER_ONLINE)
	end
end

function BFL_GuildFrame_FilterOffline()
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:SetFilter(FILTER_OFFLINE)
	end
end

function BFL_GuildFrame_SortByName()
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:SetSort(SORT_NAME) end
end

function BFL_GuildFrame_SortByRank()
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:SetSort(SORT_RANK) end
end

function BFL_GuildFrame_SortByLevel()
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:SetSort(SORT_LEVEL) end
end

function BFL_GuildFrame_SortByZone()
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:SetSort(SORT_ZONE) end
end

function BFL_GuildFrame_OpenBlizzardGuild()
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:OpenBlizzardGuildUI() end
end

function BFL_GuildFrame_RefreshRoster()
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		local success = GF:RequestRosterUpdate()
		if not success then
			BFL:DebugPrint("Guild roster refresh throttled (10s cooldown)")
		end
	end
end
