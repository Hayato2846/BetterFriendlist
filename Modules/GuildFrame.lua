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
local BUTTON_HEIGHT = 38
local CLASS_ICON_SIZE = 22
local CLASS_ICON_OFFSET = 5
local NAME_OFFSET_WITH_ICON = 34
local STATUS_ICON_SIZE = 14
local STATUS_TEX_AFK = _G.FRIENDS_TEXTURE_AFK or "Interface\\FriendsFrame\\StatusIcon-Away"
local STATUS_TEX_DND = _G.FRIENDS_TEXTURE_DND or "Interface\\FriendsFrame\\StatusIcon-DnD"
local STATUS_TEX_MOBILE = "Interface\\ChatFrame\\UI-ChatIcon-ArmoryChat"
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local ROSTER_REFRESH_THROTTLE = 10 -- seconds (WoW server enforces this)

-- Sort modes
local SORT_NAME = "name"
local SORT_RANK = "rank"
local SORT_LEVEL = "level"
local SORT_CLASS = "class"
local SORT_ZONE = "zone"
local SORT_ILVL = "ilvl"
local SORT_LAST_ONLINE = "lastonline"
local SORT_STATUS = "status"

-- Filter modes
local FILTER_ALL = "all"
local FILTER_ONLINE = "online"
local FILTER_OFFLINE = "offline"
local GUILD_COLUMN_HEADERS = { "NameHeader", "RankHeader", "LevelHeader", "ZoneHeader", "ILvlHeader" }

local function GetSortOptions()
	local actions = BFL.GetModule and BFL:GetModule("GuildActions")
	if actions and actions.GetSortOptions then
		return actions:GetSortOptions()
	end
	return {
		{ value = SORT_RANK, text = RANK or "Rank" },
		{ value = SORT_NAME, text = NAME or "Name" },
		{ value = SORT_LEVEL, text = LEVEL or "Level" },
		{ value = SORT_CLASS, text = CLASS or "Class" },
		{ value = SORT_ZONE, text = ZONE or "Zone" },
		{ value = SORT_LAST_ONLINE, text = LASTONLINE or "Last Online" },
		{ value = SORT_STATUS, text = STATUS or "Status" },
	}
end

local function IsValidSortMode(mode)
	for _, option in ipairs(GetSortOptions()) do
		if option.value == mode then
			return true
		end
	end
	return false
end

-- State
local guildDataProvider = nil
local needsRenderOnShow = false
local lastRosterRequestTime = 0

-- Dirty flag: Set when data changes while frame is hidden
local rosterDirty = true

local function MarkDisplayListDirty(self)
	if not self then
		return
	end
	self._displayListDirty = true
	self._retailScrollBoxDirty = true
end

local function MarkRetailRowsDirty(self)
	if not self then
		return
	end
	self._retailScrollBoxVisualDirty = true
end

local function ResetGuildRenderCache(self)
	if not self then
		return
	end
	self._displayListDirty = true
	self._retailScrollBoxDirty = true
	self._retailScrollBoxVisualDirty = true
	self._retailRowData = nil
	self._headerControlsSignature = nil
end

-- Zebra stripe colors (same as WhoFrame)
local ZEBRA_EVEN_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.3 }
local ZEBRA_ODD_COLOR = { r = 0, g = 0, b = 0, a = 0 }
local GUILD_SCROLLBAR_RESERVE = 22

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB()
	return BFL:GetModule("DB")
end

local function ShouldShowClassIcons()
	local DB = GetDB()
	return not DB or DB:Get("guildTabShowClassIcons", true) ~= false
end

local function ShouldUseGuildNicknames()
	local DB = GetDB()
	return DB and DB:Get("guildTabUseNicknames", true) ~= false
end

local function IsSimpleModeEnabled()
	local DB = GetDB()
	return DB and DB:Get("simpleMode", false) == true
end

local function HideGuildColumnHeaders(frame)
	if not frame then
		return
	end
	for _, key in ipairs(GUILD_COLUMN_HEADERS) do
		local header = frame[key]
		if header then
			header:Hide()
			if header.Disable then
				header:Disable()
			end
			header:EnableMouse(false)
		end
	end
end

local function SafeSetFont(fontObject, fontPath, fontSize, flags)
	local manager = BFL.FontManager or FontManager
	if manager and manager.SafeSetFont then
		return manager:SafeSetFont(fontObject, fontPath, fontSize, flags)
	end
	if not fontObject or not fontObject.SetFont or not fontPath or not fontSize then
		return false
	end
	local ok, result = pcall(fontObject.SetFont, fontObject, fontPath, fontSize, flags)
	return ok and result ~= false
end

local function GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

local function GetGuildRosterData()
	return BFL:GetModule("GuildRosterData")
end

local function GetGuildActions()
	return BFL:GetModule("GuildActions")
end

local function IsGuildTabEnabled()
	return BFL.IsGuildTabEnabled and BFL:IsGuildTabEnabled()
end

local function CanViewOfficerNote()
	local actions = GetGuildActions()
	if actions and actions.CanViewOfficerNote then
		return actions:CanViewOfficerNote()
	end
	local provider = GetGuildRosterData()
	if provider and provider.CanViewOfficerNote then
		return provider:CanViewOfficerNote()
	end
	if not (C_GuildInfo and C_GuildInfo.CanViewOfficerNote) then
		return false
	end
	local ok, result = pcall(C_GuildInfo.CanViewOfficerNote)
	return ok and result == true
end

local function ApplyDefaultSlugToFontString(fontString)
	if BFL.FontManager and BFL.FontManager.ApplyDefaultSlugToFontString then
		BFL.FontManager:ApplyDefaultSlugToFontString(fontString)
	end
end

local function ApplyDefaultSlugToButton(button)
	if button and button.GetFontString then
		ApplyDefaultSlugToFontString(button:GetFontString())
	end
end

local function ApplyBetterFriendlistSmallButtonFonts(button)
	if not button then
		return
	end
	if button.SetNormalFontObject then
		button:SetNormalFontObject("BetterFriendlistFontNormalSmall")
		button:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
		button:SetDisabledFontObject("BetterFriendlistFontDisableSmall")
	end
	ApplyDefaultSlugToButton(button)
end

local function ApplyBetterFriendlistHeaderButtonFonts(button)
	if not button then
		return
	end
	if button.SetNormalFontObject then
		button:SetNormalFontObject("BetterFriendlistFontHighlightSmall")
		button:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
		button:SetDisabledFontObject("BetterFriendlistFontDisableSmall")
	end
	ApplyDefaultSlugToButton(button)
end

local function ApplyStaticGuildFrameFonts(frame)
	if not frame then
		return
	end

	ApplyBetterFriendlistHeaderButtonFonts(frame.NameHeader)
	ApplyBetterFriendlistHeaderButtonFonts(frame.RankHeader)
	ApplyBetterFriendlistHeaderButtonFonts(frame.LevelHeader)
	ApplyBetterFriendlistHeaderButtonFonts(frame.ZoneHeader)
	ApplyBetterFriendlistHeaderButtonFonts(frame.ILvlHeader)

	ApplyBetterFriendlistSmallButtonFonts(frame.FilterAll)
	ApplyBetterFriendlistSmallButtonFonts(frame.FilterOnline)
	ApplyBetterFriendlistSmallButtonFonts(frame.FilterOffline)
	ApplyDefaultSlugToButton(frame.ActionsButton)
	ApplyBetterFriendlistSmallButtonFonts(frame.InvitePlayerButton)

	if frame.SearchBox then
		ApplyDefaultSlugToFontString(frame.SearchBox)
	end
end

local function ShouldSuppressGuildModuleForSecretValues()
	return false
end

-- ========================================
-- Module Lifecycle
-- ========================================

function GuildFrame:Initialize()
	L = BFL.L

	-- State
	self.guildMembers = {}
	self.displayList = {}
	local DB = GetDB()
	self.filterMode = DB and DB:Get("guildTabFilterMode", FILTER_ONLINE) or FILTER_ONLINE
	self.searchText = ""
	self.sortMode = DB and DB:Get("guildTabSortMode", SORT_RANK) or SORT_RANK
	if not IsValidSortMode(self.sortMode) then
		self.sortMode = SORT_RANK
	end
	self.sortReversed = {}
	self.selectedMember = nil
	self.totalMembers = 0
	self.onlineMembers = 0
	self.suppressedForSecretValues = false
	self.eventsRegistered = false
	self.showHookInstalled = false
	ResetGuildRenderCache(self)

	self:EnsureEnabled()
end

function GuildFrame:IsEnabled()
	return IsGuildTabEnabled() == true
end

function GuildFrame:RegisterGuildEvents()
	if self.eventsRegistered then
		return
	end

	BFL:RegisterEventCallback("GUILD_ROSTER_UPDATE", function(...)
		self:OnGuildRosterUpdate(...)
	end, 50)

	BFL:RegisterEventCallback("GUILD_MOTD", function(motd)
		self:UpdateMOTD()
	end, 50)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function(...)
		self:OnPlayerGuildUpdate(...)
	end, 50)

	self.eventsRegistered = true
end

function GuildFrame:EnsureEnabled()
	if not self:IsEnabled() then
		return false
	end

	self:RegisterGuildEvents()

	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame and not self.showHookInstalled then
		BetterFriendsFrame:HookScript("OnShow", function()
			if needsRenderOnShow then
				local guildFrame = BetterFriendsFrame.GuildFrame
				if guildFrame and guildFrame:IsShown() then
					self:Refresh()
					needsRenderOnShow = false
				end
			end
		end)
		self.showHookInstalled = true
	end

	return true
end

function GuildFrame:OnGuildTabSettingChanged()
	rosterDirty = true
	MarkDisplayListDirty(self)
	needsRenderOnShow = true
	if self:EnsureEnabled() then
		self:Refresh()
	end
end

function GuildFrame:OnPlayerLogin()
	if not self:EnsureEnabled() then
		return
	end

	-- Request initial guild roster data if in a guild
	local provider = GetGuildRosterData()
	if provider and provider.IsInGuild and provider:IsInGuild() then
		self:RequestRosterUpdate()
	end
end

-- ========================================
-- Event Handlers
-- ========================================

function GuildFrame:OnGuildRosterUpdate(canRequestRosterUpdate)
	if not self:IsEnabled() then
		return
	end

	rosterDirty = true
	MarkDisplayListDirty(self)

	-- Check if our frame is visible
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if guildFrame and guildFrame:IsShown() then
		self:Refresh()
	else
		needsRenderOnShow = true
	end
end

function GuildFrame:OnPlayerGuildUpdate(unitTarget)
	if not self:IsEnabled() then
		return
	end

	rosterDirty = true
	MarkDisplayListDirty(self)

	-- Update empty state visibility
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if guildFrame and guildFrame:IsShown() then
		self:UpdateEmptyState()
		local provider = GetGuildRosterData()
		if provider and provider.IsInGuild and provider:IsInGuild() then
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
	if not self:EnsureEnabled() then
		return false
	end

	local now = GetTime()
	if (now - lastRosterRequestTime) < ROSTER_REFRESH_THROTTLE then
		return false -- Throttled
	end
	lastRosterRequestTime = now
	local provider = GetGuildRosterData()
	if provider and provider.RequestRosterUpdate then
		return provider:RequestRosterUpdate()
	end
	local ok = pcall(BFL.GuildRoster)
	return ok == true
end

function GuildFrame:CollectRoster()
	if not self:IsEnabled() then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		rosterDirty = false
		MarkDisplayListDirty(self)
		return
	end

	local provider = GetGuildRosterData()
	if not (provider and provider.IsInGuild and provider:IsInGuild()) then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		rosterDirty = false
		MarkDisplayListDirty(self)
		return
	end

	if not (provider and provider.CollectRoster) then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		rosterDirty = false
		MarkDisplayListDirty(self)
		return
	end

	local members, counts = provider:CollectRoster()
	self.guildMembers = members
	self.totalMembers = counts and counts.total or #members
	self.onlineMembers = counts and counts.online or 0
	rosterDirty = false
	MarkDisplayListDirty(self)
end

-- ========================================
-- Filter & Search
-- ========================================

function GuildFrame:SetFilter(mode)
	if self.filterMode == mode then
		return
	end
	self.filterMode = mode
	MarkDisplayListDirty(self)
	local DB = GetDB()
	if DB and DB.Set then
		DB:Set("guildTabFilterMode", mode)
	end
	self:RefreshHeaderControls()
	self:Refresh()
end

function GuildFrame:SetSearchText(text, skipRefresh)
	local newText = (text or ""):lower()
	if self.searchText == newText then
		return
	end
	self.searchText = newText
	MarkDisplayListDirty(self)

	if skipRefresh then
		return
	end

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if guildFrame and guildFrame:IsShown() then
		self:Refresh()
	end
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
		if (member.name or ""):lower():find(s, 1, true) then return true end
		if (member.fullName or ""):lower():find(s, 1, true) then return true end
		if (member.rank or ""):lower():find(s, 1, true) then return true end
		if (member.zone or ""):lower():find(s, 1, true) then return true end
		if (member.className or ""):lower():find(s, 1, true) then return true end
		if (member.note or ""):lower():find(s, 1, true) then return true end
		if CanViewOfficerNote() then
			if (member.officerNote or ""):lower():find(s, 1, true) then return true end
		end
		return false
	end

	return true
end

-- ========================================
-- Sorting
-- ========================================

function GuildFrame:SetSort(mode, skipToggle)
	if not IsValidSortMode(mode) then
		return
	end
	if self.sortMode == mode and skipToggle then
		return
	end
	if self.sortMode == mode and not skipToggle then
		-- Toggle reverse on same column
		self.sortReversed[mode] = not self.sortReversed[mode]
	else
		self.sortMode = mode
	end
	MarkDisplayListDirty(self)
	local DB = GetDB()
	if DB and DB.Set then
		DB:Set("guildTabSortMode", self.sortMode)
	end
	self:RefreshSortDropdown()
	self:RefreshHeaderControls()
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

		local result

		if mode == SORT_NAME then
			local aName, bName = (a.name or ""):lower(), (b.name or ""):lower()
			if aName ~= bName then
				result = aName < bName
			end
		elseif mode == SORT_RANK then
			if a.rankIndex ~= b.rankIndex then
				result = a.rankIndex < b.rankIndex
			end
		elseif mode == SORT_LEVEL then
			if (a.level or 0) ~= (b.level or 0) then
				result = (a.level or 0) > (b.level or 0) -- Higher level first
			end
		elseif mode == SORT_CLASS then
			local aClass, bClass = a.className or "", b.className or ""
			if aClass ~= bClass then
				result = aClass < bClass
			end
		elseif mode == SORT_ZONE then
			local aZone, bZone = a.zone or "", b.zone or ""
			if aZone ~= bZone then
				result = aZone < bZone
			end
		elseif mode == SORT_ILVL then
			if (a.itemLevel or 0) ~= (b.itemLevel or 0) then
				result = (a.itemLevel or 0) > (b.itemLevel or 0) -- higher first
			end
		elseif mode == SORT_LAST_ONLINE then
			local function toHours(m)
				return (m.lastOnlineYears or 0) * 8760
					+ (m.lastOnlineMonths or 0) * 730
					+ (m.lastOnlineDays or 0) * 24
					+ (m.lastOnlineHours or 0)
			end
			local ah, bh = toHours(a), toHours(b)
			if ah ~= bh then
				result = ah < bh -- most recently online first
			end
		elseif mode == SORT_STATUS then
			-- Online > AFK > DND > Offline
			local function rank(m)
				if not m.online then return 3 end
				if m.isDND then return 2 end
				if m.isAFK then return 1 end
				return 0
			end
			local ar, br = rank(a), rank(b)
			if ar ~= br then
				result = ar < br
			end
		end

		-- Tiebreaker: name (strict ordering guarantee)
		if result == nil then
			local aName, bName = (a.name or ""):lower(), (b.name or ""):lower()
			if aName ~= bName then
				result = aName < bName
			else
				-- Final tiebreaker: guildIndex (unique per member, guarantees strict ordering)
				return (a.guildIndex or 0) < (b.guildIndex or 0)
			end
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
	if not self:IsEnabled() then
		self.guildMembers = {}
		self.displayList = {}
		ResetGuildRenderCache(self)
		return self.displayList, false
	end

	if rosterDirty then
		self:CollectRoster()
	end

	if not self._displayListDirty and self.displayList then
		return self.displayList, true
	end

	local filtered = {}
	for _, member in ipairs(self.guildMembers) do
		if self:PassesFilter(member) then
			filtered[#filtered + 1] = member
		end
	end

	self:SortMembers(filtered)
	self.displayList = filtered
	self._displayListDirty = false
	self._retailScrollBoxDirty = true
	return filtered, false
end

-- ========================================
-- Refresh & Render (Retail ScrollBox)
-- ========================================

function GuildFrame:Refresh()
	if not self:IsEnabled() then
		self.guildMembers = {}
		self.displayList = {}
		ResetGuildRenderCache(self)
		return
	end

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

function GuildFrame:RefreshVisibleRetailRows()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local scrollBox = guildFrame and guildFrame.ScrollBox
	if not (scrollBox and scrollBox.ForEachFrame) then
		self._retailScrollBoxVisualDirty = false
		return
	end

	scrollBox:ForEachFrame(function(button, elementData)
		if elementData and elementData.member then
			self:UpdateMemberButton(button, elementData.member, elementData.index)
		end
	end)
	self._retailScrollBoxVisualDirty = false
end

function GuildFrame:UpdateRetailScrollBox()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.ScrollBox then return end
	if not guildDataProvider then return end

	local displayList = self.displayList or {}
	local scrollBox = guildFrame.ScrollBox
	if not self._retailScrollBoxDirty then
		if self._retailScrollBoxVisualDirty then
			self:RefreshVisibleRetailRows()
		end
		return
	end

	local currentProvider = scrollBox.GetDataProvider and scrollBox:GetDataProvider() or guildDataProvider
	local structureChanged = true
	if currentProvider and currentProvider.Enumerate then
		local currentSize = (currentProvider.GetSize and currentProvider:GetSize())
			or (currentProvider.Count and currentProvider:Count())
			or 0
		if currentSize == #displayList then
			structureChanged = false
			local index = 1
			for _, oldData in currentProvider:Enumerate() do
				local member = displayList[index]
				if not oldData
					or not oldData.member
					or not member
					or oldData.member.guildIndex ~= member.guildIndex
					or oldData.member.fullName ~= member.fullName
				then
					structureChanged = true
					break
				end
				index = index + 1
			end
		end
	end

	if not structureChanged and currentProvider and currentProvider.Enumerate then
		local index = 1
		for _, oldData in currentProvider:Enumerate() do
			oldData.index = index
			oldData.member = displayList[index]
			index = index + 1
		end
		self._retailScrollBoxDirty = false
		MarkRetailRowsDirty(self)
		self:RefreshVisibleRetailRows()
		return
	end

	local rowData = self._retailRowData
	if not rowData then
		rowData = {}
		self._retailRowData = rowData
	end

	for i, member in ipairs(displayList) do
		local data = rowData[i]
		if not data then
			data = {}
			rowData[i] = data
		end
		data.index = i
		data.member = member
	end
	for i = #displayList + 1, #rowData do
		rowData[i] = nil
	end

	guildDataProvider:Flush()
	if guildDataProvider.InsertTable then
		guildDataProvider:InsertTable(rowData)
	else
		for i = 1, #rowData do
			guildDataProvider:Insert(rowData[i])
		end
	end

	if scrollBox.SetDataProvider and scrollBox.GetDataProvider and scrollBox:GetDataProvider() ~= guildDataProvider then
		scrollBox:SetDataProvider(guildDataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
	self._retailScrollBoxDirty = false
	self._retailScrollBoxVisualDirty = false
end

-- ========================================
-- Classic FauxScrollFrame
-- ========================================

function GuildFrame:UpdateClassicScrollFrame()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.FauxScroll then return end

	local displayList = self.displayList
	local numEntries = #displayList
	local buttonCount = self.classicButtons and #self.classicButtons or 0
	local scrollHeight = guildFrame.FauxScroll:GetHeight() or 0
	if scrollHeight <= 0 then
		scrollHeight = BUTTON_HEIGHT * 12
	end
	local visibleRows = math.max(1, math.floor(scrollHeight / BUTTON_HEIGHT))
	if buttonCount > 0 then
		visibleRows = math.min(buttonCount, visibleRows)
	end

	FauxScrollFrame_Update(guildFrame.FauxScroll, numEntries, visibleRows, BUTTON_HEIGHT)

	local offset = FauxScrollFrame_GetOffset(guildFrame.FauxScroll)

	for i = 1, buttonCount do
		local dataIndex = offset + i
		local button = self.classicButtons and self.classicButtons[i]
		if button then
			if i <= visibleRows and dataIndex <= numEntries then
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
	for i = 1, 20 do
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

function GuildFrame:ApplyV1Visibility(frame)
	if not frame then
		return
	end

	HideGuildColumnHeaders(frame)
	if frame.FilterAll then
		frame.FilterAll:Hide()
		frame.FilterAll:Disable()
	end
	if frame.FilterOnline then
		frame.FilterOnline:Hide()
		frame.FilterOnline:Disable()
	end
	if frame.FilterOffline then
		frame.FilterOffline:Hide()
		frame.FilterOffline:Disable()
	end
	if frame.InvitePlayerButton then
		frame.InvitePlayerButton:Hide()
		frame.InvitePlayerButton:Disable()
	end
	if frame.SearchBox then
		if BFL.IsClassic then
			frame.SearchBox:Show()
		else
			frame.SearchBox:SetText("")
			frame.SearchBox:Hide()
		end
	end
	if frame.SortDropdown then
		if BFL.IsClassic then
			frame.SortDropdown:Show()
		else
			frame.SortDropdown:Hide()
		end
	end
	if frame.FilterDropdown then
		if BFL.IsClassic then
			frame.FilterDropdown:Show()
		else
			frame.FilterDropdown:Hide()
		end
	end
	if frame._bflTabard then
		frame._bflTabard:Hide()
	end
end

function GuildFrame:GetSortLabel(mode)
	for _, option in ipairs(GetSortOptions()) do
		if option.value == mode then
			return option.text
		end
	end
	return RANK or "Rank"
end

function GuildFrame:RefreshSortDropdown()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local dropdown = frame and frame.SortDropdown
	if not dropdown or not UIDropDownMenu_SetText then
		return
	end
	UIDropDownMenu_SetText(dropdown, self:GetSortLabel(self.sortMode))
end

function GuildFrame:RefreshFilterDropdown()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local dropdown = frame and frame.FilterDropdown
	if not dropdown or not UIDropDownMenu_SetText then
		return
	end
	local actions = GetGuildActions()
	local text = actions and actions.GetFilterLabel and actions:GetFilterLabel(self.filterMode)
		or (self.filterMode == FILTER_ALL and (ALL or "All"))
		or (self.filterMode == FILTER_OFFLINE and (FRIENDS_LIST_OFFLINE or "Offline"))
		or (FRIENDS_LIST_ONLINE or "Online")
	UIDropDownMenu_SetText(dropdown, text)
end

function GuildFrame:CreateSortDropdown(frame)
	if not (frame and UIDropDownMenu_Initialize) then
		return
	end
	if frame.SortDropdown then
		return
	end

	local dropdown = CreateFrame("Frame", "BFL_GuildSortDropdown", frame, "UIDropDownMenuTemplate")
	frame.SortDropdown = dropdown
	if UIDropDownMenu_SetWidth then
		UIDropDownMenu_SetWidth(dropdown, 112)
	end
	if UIDropDownMenu_SetText then
		UIDropDownMenu_SetText(dropdown, self:GetSortLabel(self.sortMode))
	end

	UIDropDownMenu_Initialize(dropdown, function(_, level)
		for _, option in ipairs(GetSortOptions()) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.text
			info.value = option.value
			info.checked = self.sortMode == option.value
			info.func = function(menuButton)
				self:SetSort(menuButton.value)
				self:RefreshSortDropdown()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
end

function GuildFrame:CreateFilterDropdown(frame)
	if not (frame and UIDropDownMenu_Initialize) then
		return
	end
	if frame.FilterDropdown then
		return
	end

	local dropdown = CreateFrame("Frame", "BFL_GuildFilterDropdown", frame, "UIDropDownMenuTemplate")
	frame.FilterDropdown = dropdown
	if UIDropDownMenu_SetWidth then
		UIDropDownMenu_SetWidth(dropdown, 104)
	end
	self:RefreshFilterDropdown()

	UIDropDownMenu_Initialize(dropdown, function(_, level)
		local actions = GetGuildActions()
		local options = actions and actions.GetFilterOptions and actions:GetFilterOptions() or {
			{ value = FILTER_ONLINE, text = FRIENDS_LIST_ONLINE or "Online" },
			{ value = FILTER_ALL, text = ALL or "All" },
			{ value = FILTER_OFFLINE, text = FRIENDS_LIST_OFFLINE or "Offline" },
		}
		for _, option in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.text
			info.value = option.value
			info.checked = self.filterMode == option.value
			info.func = function(menuButton)
				self:SetFilter(menuButton.value)
				self:RefreshFilterDropdown()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
end

function GuildFrame:OnLoad(frame)
	self.frame = frame
	ApplyStaticGuildFrameFonts(frame)
	self:ApplyV1Visibility(frame)
	self:CreateSortDropdown(frame)
	self:CreateFilterDropdown(frame)

	-- NOTE: L (locale) is NOT available during OnLoad (set in Initialize).
	-- Button/label text is set in OnShow instead.

	-- GuildFrame uses setAllPoints="true" (fills BetterFriendsFrame, like WhoFrame).
	-- XML anchors use positive y offsets (UP from ListInset), designed for WhoFrame.
	-- We override ALL positions for the guild-specific top-down layout.
	-- Dynamic elements (SearchBox, Filters, ListInset) are repositioned in
	-- UpdateLayout() whenever MOTD height changes.
	if not BFL.IsClassic then
		local inset = frame:GetParent() and frame:GetParent().Inset
		if inset then
			-- Row 1: Guild name (left) + member count (right) -- STATIC
			frame.GuildName:ClearAllPoints()
			frame.GuildName:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -4)
			frame.MemberCount:ClearAllPoints()
			frame.MemberCount:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -6, -4)

			-- Row 2: MOTD below guild name, compact two-line max.
			frame.MOTDText:ClearAllPoints()
			frame.MOTDText:SetPoint("TOPLEFT", frame.GuildName, "BOTTOMLEFT", 0, -2)
			frame.MOTDText:SetPoint("RIGHT", inset, "RIGHT", -6, 0)
			frame.MOTDText:SetWordWrap(true)
			frame.MOTDText:SetMaxLines(2)
			frame.MOTDText:SetNonSpaceWrap(true)

			-- Bottom buttons: mirror the Friends tab Add Friend / Send Message layout.
			frame.ActionsButton:ClearAllPoints()
			frame.ActionsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 4)

			-- Initial layout with empty MOTD
			self:UpdateLayout()
		end
	end
	if BFL.IsClassic then
		if frame.SearchBox then
			frame.SearchBox:ClearAllPoints()
			frame.SearchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -32)
			frame.SearchBox:SetSize(142, 20)
		end
		if frame.FilterDropdown then
			frame.FilterDropdown:ClearAllPoints()
			frame.FilterDropdown:SetPoint("LEFT", frame.SearchBox or frame, "RIGHT", -12, 0)
		end
		if frame.SortDropdown then
			frame.SortDropdown:ClearAllPoints()
			frame.SortDropdown:SetPoint("LEFT", frame.FilterDropdown or frame.SearchBox or frame, "RIGHT", -10, 0)
		end
	end

	self:CreateEmptyState(frame)

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

	BFL.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

	-- ScrollBox: flush inside ListInset (WhoFrame pattern)
	frame.ScrollBox:ClearAllPoints()
	frame.ScrollBox:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -GUILD_SCROLLBAR_RESERVE, 2)

	frame.ScrollBar:ClearAllPoints()
	frame.ScrollBar:SetWidth(GUILD_SCROLLBAR_RESERVE)
	frame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollBox, "TOPRIGHT", 0, 0)
	frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.ScrollBox, "BOTTOMRIGHT", 0, 0)

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
	button.iconBorder = button:CreateTexture(nil, "BORDER")
	button.iconBorder:SetColorTexture(0, 0, 0, 0.85)
	button.iconBorder:Hide()

	button.classIcon = button:CreateTexture(nil, "ARTWORK")
	button.classIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
	button.classIcon:SetPoint("TOPLEFT", button, "TOPLEFT", CLASS_ICON_OFFSET, -8)
	button.classIcon:SetTexture(CLASS_ICON_TEXTURE)

	-- Primary name line
	button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ApplyDefaultSlugToFontString(button.nameText)
	button.nameText:SetPoint("TOPLEFT", button.classIcon, "TOPRIGHT", 4, 1)
	button.nameText:SetJustifyH("LEFT")
	button.nameText:SetMaxLines(1)
	button.nameText:SetWordWrap(false)
	button.nameText:SetNonSpaceWrap(false)
	button.nameText:SetShadowColor(0, 0, 0, 0.9)
	button.nameText:SetShadowOffset(1, -1)

	-- Status icon (Blizzard AFK/DND/Mobile textures; hidden for online & offline)
	button.statusIcon = button:CreateTexture(nil, "OVERLAY")
	button.statusIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	button.statusIcon:Hide()

	-- Secondary info line (rank, level, class, zone/last online)
	button.rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.rankText)
	button.rankText:SetJustifyH("LEFT")
	button.rankText:SetTextColor(0.6, 0.6, 0.6)
	button.rankText:SetMaxLines(1)
	button.rankText:SetWordWrap(false)
	button.rankText:SetNonSpaceWrap(false)
	button.rankText:SetShadowColor(0, 0, 0, 0.75)
	button.rankText:SetShadowOffset(1, -1)

	-- Level text
	button.levelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.levelText)
	button.levelText:SetJustifyH("CENTER")
	button.levelText:Hide()

	-- Zone text
	button.zoneText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.zoneText)
	button.zoneText:SetJustifyH("LEFT")
	button.zoneText:SetMaxLines(1)
	button.zoneText:SetWordWrap(false)
	button.zoneText:Hide()

	-- Item Level text
	button.ilvlText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.ilvlText)
	button.ilvlText:SetJustifyH("RIGHT")
	button.ilvlText:SetTextColor(GetAccentColor(1, 0.82, 0, 1))
	button.ilvlText:Hide()

	-- Highlight texture
	button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.14))

	button.selectionBar = button:CreateTexture(nil, "OVERLAY")
	button.selectionBar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -3)
	button.selectionBar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 3)
	button.selectionBar:SetWidth(2)
	button.selectionBar:Hide()

	-- Enable mouse
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Click / hover handlers (Retail ScrollBox buttons are recycled; Classic buttons
	-- also call SetupMemberButton but additionally set their own OnClick - the hook
	-- below is harmless there because it is simply overridden)
	local self = self
	button:SetScript("OnClick", function(btn, mouseButton)
		self:OnMemberClick(btn, mouseButton)
	end)
	button:SetScript("OnEnter", function(btn)
		self:OnMemberEnter(btn)
	end)
	button:SetScript("OnLeave", function(btn)
		if GameTooltip:IsOwned(btn) then GameTooltip:Hide() end
	end)
end

function GuildFrame:UpdateMemberButton(button, member, dataIndex)
	if not button or not member then return end

	-- Store reference
	button.memberData = member

	-- Zebra striping
	local isSelected = self.selectedMember
		and (self.selectedMember.fullName == member.fullName or self.selectedMember.guildIndex == member.guildIndex)
	if isSelected then
		local r, g, b = GetAccentColor(1, 0.82, 0, 1)
		button.bg:SetColorTexture(r, g, b, 0.15)
		if button.selectionBar then
			button.selectionBar:SetColorTexture(r, g, b, 0.9)
			button.selectionBar:Show()
		end
	elseif dataIndex % 2 == 0 then
		button.bg:SetColorTexture(ZEBRA_EVEN_COLOR.r, ZEBRA_EVEN_COLOR.g, ZEBRA_EVEN_COLOR.b, ZEBRA_EVEN_COLOR.a)
		if button.selectionBar then
			button.selectionBar:Hide()
		end
	else
		button.bg:SetColorTexture(ZEBRA_ODD_COLOR.r, ZEBRA_ODD_COLOR.g, ZEBRA_ODD_COLOR.b, ZEBRA_ODD_COLOR.a)
		if button.selectionBar then
			button.selectionBar:Hide()
		end
	end

	-- Class icon
	local classCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.classFile]
	if ShouldShowClassIcons() and classCoords and button.classIcon then
		button.classIcon:SetTexCoord(unpack(classCoords))
		button.classIcon:Show()
		if button.iconBorder then
			button.iconBorder:Show()
		end
	elseif button.classIcon then
		button.classIcon:Hide()
		if button.iconBorder then
			button.iconBorder:Hide()
		end
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
		local DB = ShouldUseGuildNicknames() and GetDB()
		local nickname = DB and DB:GetGuildNickname(member.fullName) or nil
		if ShouldUseGuildNicknames() and nickname and nickname ~= "" then
			displayName = nickname
		end
		if member.online then
			button.nameText:SetText(nameColor .. displayName .. "|r" .. statusSuffix)
		else
			button.nameText:SetText("|cff808080" .. displayName .. "|r")
		end
	end

	-- Status icon (Blizzard AFK/DND/Mobile, hidden for plain online)
	if button.statusIcon then
		if member.online and member.isDND then
			button.statusIcon:SetTexture(STATUS_TEX_DND)
			button.statusIcon:SetVertexColor(1, 1, 1, 1)
			button.statusIcon:Show()
		elseif member.online and member.isAFK then
			button.statusIcon:SetTexture(STATUS_TEX_AFK)
			button.statusIcon:SetVertexColor(1, 1, 1, 1)
			button.statusIcon:Show()
		elseif member.online and member.isMobile then
			button.statusIcon:SetTexture(STATUS_TEX_MOBILE)
			button.statusIcon:SetVertexColor(1, 1, 1, 1)
			button.statusIcon:Show()
		else
			button.statusIcon:Hide()
		end
	end

	-- Offline dim (alpha on classIcon only; name handled via color)
	if button.classIcon then
		button.classIcon:SetAlpha(member.online and 1.0 or 0.55)
	end

	local locationText = ""
	if member.online then
		locationText = member.zone or ""
	else
		locationText = self:FormatLastOnline(member)
	end
	local levelLabel = LEVEL_ABBR or LEVEL or "Level"
	local levelText = ""
	if member.level and member.level > 0 then
		levelText = string.format("%s %d", levelLabel, member.level)
	end
	local infoParts = {}
	if member.rank and member.rank ~= "" then
		table.insert(infoParts, member.rank)
	end
	if levelText ~= "" then
		table.insert(infoParts, levelText)
	end
	if member.className and member.className ~= "" then
		table.insert(infoParts, member.className)
	end
	if locationText ~= "" then
		table.insert(infoParts, locationText)
	end
	if button.rankText then
		button.rankText:SetText(table.concat(infoParts, " - "))
		if member.online then
			button.rankText:SetTextColor(0.72, 0.72, 0.62)
		else
			button.rankText:SetTextColor(0.5, 0.5, 0.5)
		end
	end

	if button.levelText then
		button.levelText:SetText("")
		button.levelText:Hide()
	end

	if button.zoneText then
		button.zoneText:SetText("")
		button.zoneText:Hide()
	end

	if button.ilvlText then
		button.ilvlText:SetText("")
		button.ilvlText:Hide()
	end

	-- Apply responsive row layout
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
	if not self:IsEnabled() then
		return
	end

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end
	local provider = GetGuildRosterData()

	-- Guild name
	if guildFrame.GuildName then
		if provider and provider.IsInGuild and provider:IsInGuild() then
			local guildName = provider.GetGuildName and provider:GetGuildName() or ""
			guildFrame.GuildName:SetText(guildName or "")
		else
			guildFrame.GuildName:SetText("")
		end
	end

	-- Member count -- unified "N / M online" format
	if guildFrame.MemberCount then
		local online = self.onlineMembers or 0
		local total = self.totalMembers or 0
		local fmt = (L and L.GUILD_HEADER_ONLINE_FORMAT) or "%d / %d online"
		guildFrame.MemberCount:SetText(format(fmt, online, total))
	end

	self:UpdateTabard()
	self:UpdateMOTD()
	self:UpdateHeaderEditButtons()
end

function GuildFrame:UpdateMOTD()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame or not guildFrame.MOTDText then return end

	local motd = ""
	if BFL.GetGuildMOTD then
		local ok, result = pcall(BFL.GetGuildMOTD)
		if ok and result then
			motd = tostring(result):gsub("|n", " "):gsub("\\n", " "):gsub("\n", " ")
		end
	end

	if motd ~= "" then
		local label = (L and L.GUILD_HEADER_MOTD) or "MOTD:"
		guildFrame.MOTDText:SetText(label .. " " .. motd)
		guildFrame.MOTDText:Show()
		if guildFrame.HeaderDivider then
			guildFrame.HeaderDivider:Show()
		end
	else
		guildFrame.MOTDText:SetText("")
		guildFrame.MOTDText:Hide()
		if guildFrame.HeaderDivider then
			guildFrame.HeaderDivider:Hide()
		end
	end

	-- Defer layout update so FontString width is resolved before measuring height
	if self._layoutTimer then self._layoutTimer:Cancel() end
	self._layoutTimer = C_Timer.NewTimer(0, function()
		self._layoutTimer = nil
		self:UpdateLayout()
	end)
end

function GuildFrame:IsRetailHeaderActive()
	local frame = BetterFriendsFrame
	if BFL.IsClassic or not frame or not frame.FriendsTabHeader then
		return false
	end
	return (PanelTemplates_GetSelectedTab(frame.FriendsTabHeader) or 1) == 4
		and self:IsEnabled()
end

function GuildFrame:RefreshHeaderControls(force)
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	if not header or BFL.IsClassic then
		return
	end

	local active = self:IsRetailHeaderActive()
	local simpleMode = IsSimpleModeEnabled()
	local signature = table.concat({
		active and "active" or "inactive",
		simpleMode and "simple" or "full",
		tostring(self.filterMode or ""),
		tostring(self.sortMode or ""),
		self.sortReversed and self.sortReversed[self.sortMode] and "reversed" or "normal",
		tostring(BFL.SettingsVersion or 0),
	}, "|")
	if not force and self._headerControlsSignature == signature then
		return
	end
	self._headerControlsSignature = signature

	local actions = GetGuildActions()
	if active and actions then
		if header.SecondarySortDropdown then
			header.SecondarySortDropdown:Hide()
		end
		if header.QuickFilterDropdown then
			if header.QuickFilterDropdown.GenerateMenu then
				header.QuickFilterDropdown:GenerateMenu()
			elseif UIDropDownMenu_SetText then
				UIDropDownMenu_SetText(
					header.QuickFilterDropdown,
					actions:GetFilterLabel(self.filterMode)
				)
			end
		end
		if header.PrimarySortDropdown then
			if header.PrimarySortDropdown.GenerateMenu then
				header.PrimarySortDropdown:GenerateMenu()
			elseif UIDropDownMenu_SetText then
				UIDropDownMenu_SetText(
					header.PrimarySortDropdown,
					actions:GetSortLabel(self.sortMode)
				)
			end
		end
	else
		if header.SecondarySortDropdown then
			local simpleMode = IsSimpleModeEnabled()
			if simpleMode then
				header.SecondarySortDropdown:Hide()
			else
				header.SecondarySortDropdown:Show()
			end
			if not simpleMode and header.SecondarySortDropdown.GenerateMenu then
				header.SecondarySortDropdown:GenerateMenu()
			end
		end
		local QuickFilters = BFL:GetModule("QuickFilters")
		if QuickFilters and QuickFilters.RefreshDropdown and header.QuickFilterDropdown then
			QuickFilters:RefreshDropdown(header.QuickFilterDropdown)
		end
		if header.PrimarySortDropdown and header.PrimarySortDropdown.GenerateMenu then
			header.PrimarySortDropdown:GenerateMenu()
		end
	end
end

function GuildFrame:OnTopTabChanged(tabIndex)
	if BFL.IsClassic then
		return
	end

	local active = tabIndex == 4 and self:IsEnabled() or false
	if self._lastRetailHeaderActive == active then
		return
	end
	self._lastRetailHeaderActive = active
	self:RefreshHeaderControls()
end

function GuildFrame:PopulateFilterMenu(rootDescription)
	local actions = GetGuildActions()
	if actions and actions.PopulateFilterMenu then
		actions:PopulateFilterMenu(rootDescription)
	end
end

function GuildFrame:PopulateSortMenu(rootDescription)
	local actions = GetGuildActions()
	if actions and actions.PopulateSortMenu then
		actions:PopulateSortMenu(rootDescription)
	end
end

function GuildFrame:GetHeaderFilterText()
	local actions = GetGuildActions()
	return actions and actions.GetFilterLabel and actions:GetFilterLabel(self.filterMode)
		or self.filterMode
end

function GuildFrame:GetHeaderFilterIcon()
	local actions = GetGuildActions()
	return actions and actions.GetFilterIcon and actions:GetFilterIcon(self.filterMode)
		or "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-online.blp"
end

function GuildFrame:GetHeaderSortText()
	local actions = GetGuildActions()
	return actions and actions.GetSortLabel and actions:GetSortLabel(self.sortMode)
		or self:GetSortLabel(self.sortMode)
end

function GuildFrame:GetHeaderSortIcon()
	local actions = GetGuildActions()
	return actions and actions.GetSortIcon and actions:GetSortIcon(self.sortMode)
		or "Interface\\AddOns\\BetterFriendlist\\Icons\\guild.blp"
end

function GuildFrame:EnsureHeaderEditButtons(guildFrame)
	if not guildFrame or guildFrame._bflHeaderEditButtonsReady then
		return
	end

	local function CreateEditButton(name, tooltipTitle, onClick)
		local button = CreateFrame("Button", name, guildFrame)
		button:SetSize(16, 16)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\edit-2.blp")
		button.icon = icon
		button:SetScript("OnClick", onClick)
		button:SetScript("OnEnter", function(btn)
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltipTitle)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function(btn)
			if GameTooltip:IsOwned(btn) then
				GameTooltip:Hide()
			end
		end)
		button:Hide()
		return button
	end

	guildFrame.MOTDEditButton = CreateEditButton(
		"BFL_GuildMOTDEditButton",
		(BFL.L and BFL.L.GUILD_ACTION_EDIT_MOTD) or "MOTD",
		function()
		local actions = GetGuildActions()
		if actions and actions.EditMOTD then
			actions:EditMOTD()
		end
	end)
	guildFrame.MOTDEditButton:SetPoint("TOPRIGHT", guildFrame.MOTDText or guildFrame, "TOPRIGHT", -2, 0)

	guildFrame._bflHeaderEditButtonsReady = true
end

function GuildFrame:UpdateHeaderEditButtons()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then
		return
	end
	self:EnsureHeaderEditButtons(guildFrame)

	if guildFrame.InfoEditButton then
		guildFrame.InfoEditButton:Hide()
	end

	if guildFrame.MOTDEditButton then
		local actions = GetGuildActions()
		if actions and actions.CanEditMOTD and actions:CanEditMOTD()
			and guildFrame.MOTDText and guildFrame.MOTDText:IsShown() then
			guildFrame.MOTDEditButton:Show()
		else
			guildFrame.MOTDEditButton:Hide()
		end
	end
end

-- ========================================
-- Dynamic Layout (repositions elements below MOTD based on MOTD height)
-- ========================================

function GuildFrame:UpdateLayout()
	if not self:IsEnabled() then
		return
	end

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local inset = BetterFriendsFrame and BetterFriendsFrame.Inset
	if not guildFrame or not inset then return end
	if BFL.IsClassic then return end
	self:ApplyV1Visibility(guildFrame)

	-- Measure MOTD height (0 when empty)
	local motdText = guildFrame.MOTDText and guildFrame.MOTDText:GetText()
	local motdHeight = 0
	if motdText and motdText ~= "" then
		motdHeight = guildFrame.MOTDText:GetStringHeight() or 0
	end

	-- Calculate row positions from Inset top (negative y = downward).
	-- Retail Guild uses the shared header Search/Filter/Sorter row, so this frame
	-- only owns the guild header and list.
	local guildNameHeight = guildFrame.GuildName and guildFrame.GuildName:GetStringHeight() or 14
	local motdBottom = -4 - guildNameHeight - 2 - motdHeight

	local listInsetTop = motdBottom - 10

	guildFrame.ListInset:ClearAllPoints()
	guildFrame.ListInset:SetPoint("TOPLEFT", inset, "TOPLEFT", 0, listInsetTop)
	guildFrame.ListInset:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)

	-- Column headers are hidden; sorting is handled through the shared header dropdown.
	-- ScrollBox/ScrollBar follow ListInset via Lua OnLoad anchors.
	self:UpdateResponsiveLayout()
end

-- ========================================
-- Filter Highlight (which filter button is active)
-- ========================================

function GuildFrame:UpdateFilterHighlight()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end
	self:ApplyV1Visibility(guildFrame)

	self:RefreshFilterDropdown()
	self:RefreshSortDropdown()
	self:RefreshHeaderControls()
end

-- ========================================
-- Empty State
-- ========================================

function GuildFrame:CreateEmptyState(frame)
	if frame.EmptyText then return end

	local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ApplyDefaultSlugToFontString(emptyText)
	emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
	emptyText:SetTextColor(0.5, 0.5, 0.5)
	frame.EmptyText = emptyText
end

function GuildFrame:UpdateEmptyState()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	local hasContent = false
	local provider = GetGuildRosterData()
	local inGuild = provider and provider.IsInGuild and provider:IsInGuild()

	if not inGuild then
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
		MarkRetailRowsDirty(self)
		self:Refresh()
	end
end

function GuildFrame:OnMemberEnter(button)
	local member = button and button.memberData
	if not member then return end

	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()

	-- Name with class color (show nickname if set)
	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.classFile]
	local DB = ShouldUseGuildNicknames() and GetDB()
	local nickname = DB and DB:GetGuildNickname(member.fullName) or nil
	local tooltipName = Ambiguate(member.fullName, "guild")
	if ShouldUseGuildNicknames() and nickname and nickname ~= "" then
		tooltipName = nickname .. " (" .. Ambiguate(member.fullName, "guild") .. ")"
	end
	if classColor then
		GameTooltip:AddLine(tooltipName, classColor.r, classColor.g, classColor.b)
	else
		GameTooltip:AddLine(tooltipName)
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
		GameTooltip:AddLine(format("%s %s", NOTE_COLON or "Note:", member.note), 1, 1, 1, true)
	end
	if CanViewOfficerNote() then
		if member.officerNote and member.officerNote ~= "" then
			GameTooltip:AddLine(format("%s %s", OFFICER_NOTE_COLON or "Officer Note:", member.officerNote), 0.5, 1, 0.5, true)
		end
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
	if not self:IsEnabled() then
		return
	end

	-- Basic context menu using existing MenuSystem
	local MenuSystem = BFL:GetModule("MenuSystem")
	if MenuSystem and MenuSystem.ShowGuildMemberMenu then
		MenuSystem:ShowGuildMemberMenu(button, member)
	end
end

-- ========================================
-- Public API
-- ========================================

function GuildFrame:GetMemberByName(name)
	if not self:IsEnabled() then
		return nil
	end

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
-- Row Layout Management (Responsive)
-- ========================================

function GuildFrame:UpdateResponsiveLayout()
	if not self:IsEnabled() then
		return
	end

	local frame = BetterFriendsFrame
	if not frame or not frame.GuildFrame then return end

	local guildFrame = frame.GuildFrame
	local frameWidth = (guildFrame.ListInset and guildFrame.ListInset:GetWidth()) or frame:GetWidth()
	HideGuildColumnHeaders(guildFrame)

	-- Cache check
	local roundedWidth = math.floor(frameWidth + 0.5)
	if self._lastLayoutWidth == roundedWidth then return end
	self._lastLayoutWidth = roundedWidth

	local scrollbarAndPadding = GUILD_SCROLLBAR_RESERVE + 10
	local effectiveWidth = math.max((frameWidth or 360) - scrollbarAndPadding, 220)

	self.rowContentWidth = effectiveWidth

	-- Update button widths for Retail
	if BFL.HasModernScrollBox and guildDataProvider then
		MarkRetailRowsDirty(self)
		self:RefreshVisibleRetailRows()
	end
end

-- Apply Friendlist-style row layout to a button's text elements.
function GuildFrame:ApplyColumnWidths(button)
	local showClassIcons = ShouldShowClassIcons()
	local nameOffset = showClassIcons and NAME_OFFSET_WITH_ICON or 8
	local width = button:GetWidth()
	if not width or width <= 1 then
		width = self.rowContentWidth or 340
	end

	if button.classIcon then
		button.classIcon:ClearAllPoints()
		if showClassIcons then
			button.classIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
			button.classIcon:SetPoint("TOPLEFT", button, "TOPLEFT", CLASS_ICON_OFFSET, -8)
		else
			button.classIcon:Hide()
		end
	end
	if button.iconBorder then
		button.iconBorder:ClearAllPoints()
		if showClassIcons and button.classIcon and button.classIcon:IsShown() then
			button.iconBorder:SetPoint("TOPLEFT", button.classIcon, "TOPLEFT", -1, 1)
			button.iconBorder:SetPoint("BOTTOMRIGHT", button.classIcon, "BOTTOMRIGHT", 1, -1)
			button.iconBorder:Show()
		else
			button.iconBorder:Hide()
		end
	end
	local rightReserve = STATUS_ICON_SIZE + 14
	if button.nameText then
		button.nameText:ClearAllPoints()
		button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", nameOffset, -4)
		button.nameText:SetWidth(math.max(width - nameOffset - rightReserve, 40))
	end
	if button.statusIcon then
		button.statusIcon:ClearAllPoints()
		button.statusIcon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -7, -7)
	end
	if button.rankText then
		button.rankText:ClearAllPoints()
		button.rankText:SetPoint("TOPLEFT", button, "TOPLEFT", nameOffset, -21)
		button.rankText:SetWidth(math.max(width - nameOffset - 10, 40))
	end
	if button.levelText then
		button.levelText:Hide()
	end
	if button.zoneText then
		button.zoneText:Hide()
	end
	if button.ilvlText then
		button.ilvlText:Hide()
	end
end

-- ========================================
-- Filter Button Styling (Blizzard UIPanelButton)
-- ========================================

function GuildFrame.StylePillButton(button, isActive)
	if not button then return end
	if isActive then
		button:LockHighlight()
		button:SetNormalFontObject("BetterFriendlistFontHighlightSmall")
	else
		button:UnlockHighlight()
		button:SetNormalFontObject("BetterFriendlistFontNormalSmall")
	end
end

function GuildFrame:SetupFilterPills()
	if not self:IsEnabled() then
		return
	end

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	self:ApplyV1Visibility(guildFrame)
	self:RefreshFilterDropdown()
	self:RefreshSortDropdown()
	self:RefreshHeaderControls()
end

-- ========================================
-- MOTD Tooltip (shows full MOTD on hover)
-- ========================================

function GuildFrame:SetupMOTDTooltip()
	return
end

-- ========================================
-- Guild Tabard (optional, setting-controlled)
-- ========================================

function GuildFrame:UpdateTabard()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end
	if guildFrame._bflTabard then guildFrame._bflTabard:Hide() end
end

-- ========================================
-- Member Info Panel (left-click target)
-- ========================================

local function CreatePanelDivider(parent, anchorTo, yOffset)
	local div = parent:CreateTexture(nil, "ARTWORK")
	div:SetHeight(1)
	div:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOffset or -6)
	div:SetPoint("TOPRIGHT", anchorTo, "BOTTOMRIGHT", 0, yOffset or -6)
	div:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.35))
	return div
end

function GuildFrame:CreateMemberInfoPanel()
	return nil
end

function GuildFrame:CreateMemberInfoPanel_Legacy()
	if self._infoPanel then return self._infoPanel end

	local panel = CreateFrame("Frame", "BFL_GuildMemberInfoPanel", UIParent,
		BackdropTemplateMixin and "BackdropTemplate" or nil)
	panel:SetSize(310, 420)
	panel:SetFrameStrata("HIGH")
	panel:SetToplevel(true)
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:SetClampedToScreen(true)
	panel:Hide()

	if panel.SetBackdrop then
		panel:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 16,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})
	end

	-- Title bar backdrop
	local titleBg = panel:CreateTexture(nil, "ARTWORK")
	titleBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
	titleBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -12)
	titleBg:SetHeight(24)
	titleBg:SetColorTexture(0.1, 0.1, 0.1, 0.85)
	panel.titleBg = titleBg

	local titleBgEdge = panel:CreateTexture(nil, "OVERLAY")
	titleBgEdge:SetHeight(1)
	titleBgEdge:SetPoint("BOTTOMLEFT", titleBg, "BOTTOMLEFT", 0, -1)
	titleBgEdge:SetPoint("BOTTOMRIGHT", titleBg, "BOTTOMRIGHT", 0, -1)
	titleBgEdge:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.55))
	panel.titleBgEdge = titleBgEdge

	-- Title text
	panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ApplyDefaultSlugToFontString(panel.title)
	panel.title:SetPoint("LEFT", titleBg, "LEFT", 6, 0)
	panel.title:SetText((L and L.GUILD_INFO_PANEL_TITLE) or "Member Info")
	panel.title:SetTextColor(GetAccentColor(1, 0.82, 0, 1))

	-- Close button
	panel.closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	panel.closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

	-- Portrait / class icon (large, left column)
	panel.classIcon = panel:CreateTexture(nil, "ARTWORK")
	panel.classIcon:SetSize(46, 46)
	panel.classIcon:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 4, -10)
	panel.classIcon:SetTexture(CLASS_ICON_TEXTURE)

	-- Portrait border
	panel.classIconBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.classIconBorder:SetPoint("TOPLEFT", panel.classIcon, "TOPLEFT", -1, 1)
	panel.classIconBorder:SetPoint("BOTTOMRIGHT", panel.classIcon, "BOTTOMRIGHT", 1, -1)
	panel.classIconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.9)
	panel.classIconBorder:SetDrawLayer("ARTWORK", -1)

	-- Name (class colored)
	panel.nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	ApplyDefaultSlugToFontString(panel.nameText)
	panel.nameText:SetPoint("TOPLEFT", panel.classIcon, "TOPRIGHT", 10, -2)
	panel.nameText:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
	panel.nameText:SetJustifyH("LEFT")
	panel.nameText:SetMaxLines(1)

	-- Subtitle (level + class)
	panel.subText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.subText)
	panel.subText:SetPoint("TOPLEFT", panel.nameText, "BOTTOMLEFT", 0, -4)
	panel.subText:SetPoint("RIGHT", panel.nameText, "RIGHT", 0, 0)
	panel.subText:SetJustifyH("LEFT")
	panel.subText:SetTextColor(0.85, 0.85, 0.85)

	-- Zone / last online
	panel.zoneText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.zoneText)
	panel.zoneText:SetPoint("TOPLEFT", panel.subText, "BOTTOMLEFT", 0, -3)
	panel.zoneText:SetPoint("RIGHT", panel.subText, "RIGHT", 0, 0)
	panel.zoneText:SetJustifyH("LEFT")
	panel.zoneText:SetTextColor(0.8, 0.8, 0.6)

	-- Divider after header
	panel.divider1 = CreatePanelDivider(panel, panel.classIcon, -8)

	-- Item Level line
	panel.ilvlText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.ilvlText)
	panel.ilvlText:SetPoint("TOPLEFT", panel.divider1, "BOTTOMLEFT", 6, -6)
	panel.ilvlText:SetJustifyH("LEFT")
	panel.ilvlText:SetTextColor(GetAccentColor(1, 0.82, 0, 1))

	-- Rank label
	panel.rankLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.rankLabel)
	panel.rankLabel:SetPoint("TOPLEFT", panel.ilvlText, "BOTTOMLEFT", 0, -10)
	panel.rankLabel:SetText((L and L.GUILD_INFO_RANK) or "Rank")
	panel.rankLabel:SetTextColor(0.7, 0.7, 0.7)

	panel.rankText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.rankText)
	panel.rankText:SetPoint("TOPLEFT", panel.rankLabel, "BOTTOMLEFT", 0, -4)
	panel.rankText:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
	panel.rankText:SetJustifyH("LEFT")
	panel.rankText:SetTextColor(0.85, 0.85, 0.85)

	-- Divider before notes
	panel.divider2 = CreatePanelDivider(panel, panel.rankText, -8)

	-- Public Note
	panel.pubLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.pubLabel)
	panel.pubLabel:SetPoint("TOPLEFT", panel.divider2, "BOTTOMLEFT", 6, -8)
	panel.pubLabel:SetText((L and L.GUILD_INFO_PUBLIC_NOTE) or "Public Note")
	panel.pubLabel:SetTextColor(0.7, 0.7, 0.7)

	panel.pubNote = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	panel.pubNote:SetSize(264, 22)
	panel.pubNote:SetPoint("TOPLEFT", panel.pubLabel, "BOTTOMLEFT", 5, -4)
	panel.pubNote:SetAutoFocus(false)
	panel.pubNote:SetMaxLetters(31)
	ApplyDefaultSlugToFontString(panel.pubNote)
	panel.pubNote:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
	panel.pubNote:SetScript("OnEnterPressed", function(e) e:ClearFocus() end)

	-- Officer Note
	panel.offLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.offLabel)
	panel.offLabel:SetPoint("TOPLEFT", panel.pubNote, "BOTTOMLEFT", -5, -8)
	panel.offLabel:SetText((L and L.GUILD_INFO_OFFICER_NOTE) or "Officer Note")
	panel.offLabel:SetTextColor(0.5, 1, 0.5)

	panel.offNote = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	panel.offNote:SetSize(264, 22)
	panel.offNote:SetPoint("TOPLEFT", panel.offLabel, "BOTTOMLEFT", 5, -4)
	panel.offNote:SetAutoFocus(false)
	panel.offNote:SetMaxLetters(31)
	ApplyDefaultSlugToFontString(panel.offNote)
	panel.offNote:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
	panel.offNote:SetScript("OnEnterPressed", function(e) e:ClearFocus() end)

	-- Nickname
	panel.nickLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.nickLabel)
	panel.nickLabel:SetPoint("TOPLEFT", panel.offNote, "BOTTOMLEFT", -5, -8)
	panel.nickLabel:SetText((L and L.GUILD_INFO_NICKNAME) or "Nickname")
	panel.nickLabel:SetTextColor(0.7, 0.7, 0.7)

	panel.nickBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	panel.nickBox:SetSize(264, 22)
	panel.nickBox:SetPoint("TOPLEFT", panel.nickLabel, "BOTTOMLEFT", 5, -4)
	panel.nickBox:SetAutoFocus(false)
	panel.nickBox:SetMaxLetters(32)
	ApplyDefaultSlugToFontString(panel.nickBox)
	panel.nickBox:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
	panel.nickBox:SetScript("OnEnterPressed", function(e) e:ClearFocus() end)

	-- Save button
	panel.saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	panel.saveBtn:SetSize(90, 22)
	panel.saveBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 14)
	panel.saveBtn:SetText((L and L.GUILD_INFO_SAVE) or "Save")
	panel.saveBtn:SetScript("OnClick", function()
		self:SaveMemberInfoPanel()
	end)

	-- Cancel button
	panel.cancelBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	panel.cancelBtn:SetSize(90, 22)
	panel.cancelBtn:SetPoint("RIGHT", panel.saveBtn, "LEFT", -6, 0)
	panel.cancelBtn:SetText((L and L.GUILD_INFO_CANCEL) or "Cancel")
	panel.cancelBtn:SetScript("OnClick", function()
		self:HideMemberInfoPanel()
	end)

	self._infoPanel = panel
	return panel
end

function GuildFrame:RefreshMemberInfoPanelAccent()
	local panel = self._infoPanel
	if not panel then
		return
	end

	local accentR, accentG, accentB = GetAccentColor(1, 0.82, 0, 1)
	if panel.title then
		panel.title:SetTextColor(accentR, accentG, accentB)
	end
	if panel.ilvlText then
		panel.ilvlText:SetTextColor(accentR, accentG, accentB)
	end
	if panel.titleBgEdge then
		panel.titleBgEdge:SetColorTexture(accentR, accentG, accentB, 0.55)
	end
	if panel.divider1 then
		panel.divider1:SetColorTexture(accentR, accentG, accentB, 0.35)
	end
	if panel.divider2 then
		panel.divider2:SetColorTexture(accentR, accentG, accentB, 0.35)
	end
end

-- Rank changes are handled only through adjacent promote/demote actions.
function GuildFrame:_RefreshRankDropdown(member)
	return
end

function GuildFrame:_RefreshRankDropdown_Legacy(member)
	local panel = self._infoPanel
	if not panel or not panel.rankText then
		return
	end

	local rankText = member and member.rank or ""
	if rankText == "" and member and member.rankIndex ~= nil then
		rankText = format("#%d", (member.rankIndex or 0) + 1)
	end
	panel.rankText:SetText(rankText ~= "" and rankText or "-")
end

function GuildFrame:ShowMemberInfoPanel(member)
	return
end

function GuildFrame:ShowMemberInfoPanel_Legacy(member)
	if not member then return end
	local panel = self:CreateMemberInfoPanel_Legacy()
	if not panel then return end
	self:RefreshMemberInfoPanelAccent()
	panel._currentMember = member

	-- Anchor to right side of main frame
	panel:ClearAllPoints()
	if BetterFriendsFrame then
		panel:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", 4, 0)
	else
		panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	-- Class icon (from the character-creation atlas)
	local classFile = member.classFile or ""
	if _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[classFile] then
		local coords = _G.CLASS_ICON_TCOORDS[classFile]
		panel.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		panel.classIcon:Show()
	else
		panel.classIcon:SetTexCoord(0, 1, 0, 1)
	end

	-- Populate
	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.classFile]
	local displayName = Ambiguate(member.fullName, "guild")
	if classColor then
		panel.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
	else
		panel.nameText:SetTextColor(1, 1, 1)
	end
	panel.nameText:SetText(displayName)

	panel.subText:SetText(format("%s %d %s", LEVEL or "Level", member.level or 0,
		member.className or ""))

	if member.online then
		panel.zoneText:SetText(member.zone or "")
		panel.zoneText:SetTextColor(0.8, 0.8, 0.6)
	else
		panel.zoneText:SetText(format("%s: %s", LASTONLINE or "Last Online", self:FormatLastOnline(member)))
		panel.zoneText:SetTextColor(0.55, 0.55, 0.55)
	end

	-- iLvl line
	local ilvl = member.itemLevel or 0
	if ilvl > 0 then
		panel.ilvlText:SetText(format("%s: %d",
			(L and L.GUILD_INFO_ILVL) or "Item Level", math.floor(ilvl)))
	else
		panel.ilvlText:SetText(format("%s: %s",
			(L and L.GUILD_INFO_ILVL) or "Item Level",
			(L and L.GUILD_INFO_ILVL_UNKNOWN) or "-"))
	end

	-- Rank dropdown
	self:_RefreshRankDropdown_Legacy(member)

	-- Guild notes are read-only in BFL; Blizzard note setters are restricted.
	panel.pubNote:SetText(member.note or "")
	panel.pubNote:SetEnabled(false)
	panel.pubNote:SetTextColor(0.5, 0.5, 0.5)

	-- Officer note (viewable if permitted)
	local canViewOff = C_GuildInfo and C_GuildInfo.CanViewOfficerNote
		and C_GuildInfo.CanViewOfficerNote() or false
	if canViewOff then
		panel.offNote:SetText(member.officerNote or "")
		panel.offNote:Show()
		panel.offLabel:Show()
		panel.offNote:SetEnabled(false)
		panel.offNote:SetTextColor(0.5, 0.5, 0.5)
	else
		panel.offNote:Hide()
		panel.offLabel:Hide()
	end

	-- Nickname (BFL-local)
	local DB = GetDB()
	local nick = DB and DB:GetGuildNickname(member.fullName) or ""
	panel.nickBox:SetText(nick or "")

	panel:Show()
end

function GuildFrame:HideMemberInfoPanel()
	if self._infoPanel then
		self._infoPanel:Hide()
		self._infoPanel._currentMember = nil
		self._infoPanel._pendingRankIndex = nil
	end
end

function GuildFrame:SaveMemberInfoPanel()
	return
end

function GuildFrame:SaveMemberInfoPanel_Legacy()
	local panel = self._infoPanel
	if not panel or not panel._currentMember then return end
	local member = panel._currentMember

	-- Nickname (local)
	local DB = GetDB()
	if DB and DB.SetGuildNickname then
		local newNick = panel.nickBox:GetText() or ""
		DB:SetGuildNickname(member.fullName, newNick ~= "" and newNick or nil)
	end

	self:HideMemberInfoPanel()
	self:Refresh()
end

-- ========================================
-- Invite Player Dialog (StaticPopup-based)
-- ========================================

local INVITE_DIALOG_KEY = "BFL_GUILD_INVITE_PLAYER"

local function EnsureInviteDialog()
	if StaticPopupDialogs[INVITE_DIALOG_KEY] then return end
	StaticPopupDialogs[INVITE_DIALOG_KEY] = {
		text = "%s",
		button1 = (BFL.L and BFL.L.GUILD_INVITE_BUTTON) or "Invite",
		button2 = CANCEL or "Cancel",
		hasEditBox = 1,
		editBoxWidth = 240,
		maxLetters = 60,
		OnShow = function(self)
			self.editBox:SetText("")
			self.editBox:SetFocus()
		end,
		OnAccept = function(self)
			local name = self.editBox:GetText()
			if name and name ~= "" and GuildInvite then
				GuildInvite(name)
			end
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			local name = parent.editBox:GetText()
			if name and name ~= "" and GuildInvite then
				GuildInvite(name)
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		preferredIndex = 3,
	}
end

function GuildFrame:ShowInviteDialog()
	local actions = GetGuildActions()
	if actions and actions.InviteToGuild then
		actions:InviteToGuild()
	end
end



function BFL_GuildFrame_OnLoad(frame)
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		GF:OnLoad(frame)
	end
end

function BFL_GuildFrame_OnShow(frame)
	local GF = BFL:GetModule("GuildFrame")
	if GF then
		if not GF:EnsureEnabled() then
			frame:Hide()
			return
		end
		GF:ApplyV1Visibility(frame)

		-- Set locale text for buttons (L is not available during OnLoad, only after Initialize)
		if frame.ActionsButton and BFL.L then
			frame.ActionsButton:SetText(BFL.L.GUILD_ACTIONS_MENU or "Guild Actions")
			ApplyDefaultSlugToButton(frame.ActionsButton)
		end
		if frame.FilterOffline and BFL.L then
			frame.FilterOffline:SetText(BFL.L.GUILD_FILTER_OFFLINE or FRIENDS_LIST_OFFLINE or "Offline")
			ApplyDefaultSlugToButton(frame.FilterOffline)
		end
		if frame.SearchBox and frame.SearchBox.Instructions and BFL.L then
			frame.SearchBox.Instructions:SetText(BFL.L.GUILD_SEARCH_PLACEHOLDER or SEARCH or "Search")
		end
		-- Enlarge GuildName for visual weight
		if frame.GuildName then
			local f, _, flags = frame.GuildName:GetFont()
			if f then
				local fontFlags = flags or ""
				if BFL.FontManager and BFL.FontManager.GetDefaultUIFontFlags then
					fontFlags = BFL.FontManager:GetDefaultUIFontFlags(fontFlags)
				end
				SafeSetFont(frame.GuildName, f, 18, fontFlags)
			end
		end
		-- Pill-style filter buttons
		GF:SetupFilterPills()
		GF:UpdateHeaderEditButtons()

		-- Request roster update
		local provider = GetGuildRosterData()
		if provider and provider.IsInGuild and provider:IsInGuild() then
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
	if GF and GF:IsEnabled() then
		GF:SetSearchText(editBox:GetText())
	end
end

function BFL_GuildFrame_FilterAll()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then
		GF:SetFilter(FILTER_ALL)
	end
end

function BFL_GuildFrame_FilterOnline()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then
		GF:SetFilter(FILTER_ONLINE)
	end
end

function BFL_GuildFrame_FilterOffline()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then
		GF:SetFilter(FILTER_OFFLINE)
	end
end

function BFL_GuildFrame_SortByName()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then GF:SetSort(SORT_NAME) end
end

function BFL_GuildFrame_SortByRank()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then GF:SetSort(SORT_RANK) end
end

function BFL_GuildFrame_SortByLevel()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then GF:SetSort(SORT_LEVEL) end
end

function BFL_GuildFrame_SortByZone()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then GF:SetSort(SORT_ZONE) end
end

function BFL_GuildFrame_SortByILvl()
	return
end

function BFL_GuildFrame_ShowInviteDialog()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF.ShowInviteDialog then
		GF:ShowInviteDialog()
	end
end

function BFL_GuildFrame_ShowActionsMenu(button)
	local actions = BFL:GetModule("GuildActions")
	if actions and actions.ShowGuildActionsMenu then
		local owner = button
			or (BetterFriendsFrame and BetterFriendsFrame.GuildFrame and BetterFriendsFrame.GuildFrame.ActionsButton)
			or UIParent
		actions:ShowGuildActionsMenu(owner)
	end
end
