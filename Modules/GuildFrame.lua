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
local GUILD_HEADER_CONTENT_HEIGHT = 82
local GUILD_HEADER_CONTENT_TOP = -28
local GUILD_NEWS_MAX_ENTRIES = 50
local GUILD_NEWS_ROW_HEIGHT = 15
local GUILD_NEWS_FILTER_IDS = { 1, 2, 3, 4, 5, 6, 9 }
local NEWS_GUILD_ACHIEVEMENT_TYPE = _G.NEWS_GUILD_ACHIEVEMENT or 0
local NEWS_PLAYER_ACHIEVEMENT_TYPE = _G.NEWS_PLAYER_ACHIEVEMENT or 1
local NEWS_DUNGEON_ENCOUNTER_TYPE = _G.NEWS_DUNGEON_ENCOUNTER or 2
local NEWS_ITEM_LOOTED_TYPE = _G.NEWS_ITEM_LOOTED or 3
local NEWS_ITEM_CRAFTED_TYPE = _G.NEWS_ITEM_CRAFTED or 4
local NEWS_ITEM_PURCHASED_TYPE = _G.NEWS_ITEM_PURCHASED or 5
local NEWS_LEGENDARY_LOOTED_TYPE = _G.NEWS_LEGENDARY_LOOTED or 8

-- Sort modes
local SORT_NAME = "name"
local SORT_RANK = "rank"
local SORT_LEVEL = "level"
local SORT_CLASS = "class"
local SORT_ZONE = "zone"
local SORT_ILVL = "ilvl"
local SORT_LAST_ONLINE = "lastonline"
local SORT_STATUS = "status"
local SORT_NICKNAME = "nickname"

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

local function GetFilterOptions()
	local actions = BFL.GetModule and BFL:GetModule("GuildActions")
	if actions and actions.GetFilterOptions then
		return actions:GetFilterOptions()
	end
	return {
		{ value = FILTER_ONLINE, text = FRIENDS_LIST_ONLINE or "Online" },
		{ value = FILTER_ALL, text = ALL or "All" },
		{ value = FILTER_OFFLINE, text = FRIENDS_LIST_OFFLINE or "Offline" },
	}
end

local function IsValidFilterMode(mode)
	for _, option in ipairs(GetFilterOptions()) do
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

local function IsGuildFrameVisible()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	return BetterFriendsFrame and BetterFriendsFrame:IsShown() and guildFrame and guildFrame:IsShown()
end

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

function GuildFrame:GetRetailScrollBarGeometry()
	local reserve = GUILD_SCROLLBAR_RESERVE
	local gap = 0
	local width = GUILD_SCROLLBAR_RESERVE
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() then
		if FriendsUI.GetModernScrollBoxRightInset then
			reserve = FriendsUI:GetModernScrollBoxRightInset()
		end
		if FriendsUI.GetModernScrollBarGap then
			gap = FriendsUI:GetModernScrollBarGap()
		end
		local reference = BetterFriendsFrame and BetterFriendsFrame.MinimalScrollBar
		local referenceWidth = reference and reference:GetWidth()
		width = referenceWidth and referenceWidth > 0 and referenceWidth or 8
	end
	return reserve, gap, width
end

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

local function GetMemberProfession(member, professionID)
	professionID = tonumber(professionID)
	if not member or not professionID then
		return nil
	end
	for slot = 1, 2 do
		if tonumber(member["profession" .. slot .. "ID"]) == professionID then
			return member["profession" .. slot .. "Name"]
		end
	end
	return nil
end

local function GetGuildMOTDLabel()
	return _G.GUILD_MOTD_LABEL
		or (L and L.GUILD_MOTD_TOOLTIP_HEADER)
		or "Message of the Day"
end

local function GetGuildProfessionLabel()
	return _G.PROFESSIONS_COLUMN_LABEL
		or _G.PROFESSIONS
		or (L and L.FRIEND_TAGS_BLIZZARD_PROFESSIONS)
		or "Professions"
end

local function FormatGuildLabeledText(label, text)
	label = tostring(label or "")
	text = tostring(text or "")
	if text == "" then
		return label
	end
	local separator = label:find("[:：]%s*$") and " " or ": "
	return label .. separator .. text
end

local function SetGuildTextColor(fontString)
	if not (fontString and fontString.SetTextColor) then
		return
	end
	local guildColor = _G.ChatTypeInfo and _G.ChatTypeInfo.GUILD
	local r = guildColor and tonumber(guildColor.r)
	local g = guildColor and tonumber(guildColor.g)
	local b = guildColor and tonumber(guildColor.b)
	if not (r and g and b) and _G.GREEN_FONT_COLOR and _G.GREEN_FONT_COLOR.GetRGB then
		r, g, b = _G.GREEN_FONT_COLOR:GetRGB()
	end
	fontString:SetTextColor(r or 0.25, g or 1, b or 0.25, 1)
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
	if not IsValidFilterMode(self.filterMode) then
		self.filterMode = FILTER_ONLINE
	end
	self.searchText = ""
	self.sortMode = DB and DB:Get("guildTabSortMode", SORT_RANK) or SORT_RANK
	if not IsValidSortMode(self.sortMode) then
		self.sortMode = SORT_RANK
	end
	self.sortReversed = {}
	self.selectedMember = nil
	self.professionFilterID = nil
	self.professionFilterName = nil
	self.guildNewsEntries = {}
	self.guildNewsRequested = false
	self.headerDetailMode = "motd"
	self.guildMOTDText = ""
	self.guildInfoText = nil
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
		if IsGuildFrameVisible() then
			self:UpdateMOTD()
		else
			needsRenderOnShow = true
		end
	end, 50)

	BFL:RegisterEventCallback("GUILD_NEWS_UPDATE", function()
		local provider = GetGuildRosterData()
		if provider and provider.InvalidateGuildNews then
			provider:InvalidateGuildNews()
		end
		self:RefreshGuildNews()
	end, 50)

	BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function(...)
		self:OnPlayerGuildUpdate(...)
	end, 50)

	pcall(function()
		BFL:RegisterEventCallback("GUILD_RANKS_UPDATE_ACTIVE_PLAYER", function(...)
			self:OnGuildRosterUpdate(...)
		end, 50)
	end)

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
	if self:EnsureEnabled() and IsGuildFrameVisible() then
		self:Refresh()
	end
end

function GuildFrame:OnPlayerLogin()
	if not self:EnsureEnabled() then
		return
	end

	-- The Guild section requests a fresh roster from its OnShow handler.
	needsRenderOnShow = true
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
	if IsGuildFrameVisible() then
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
	self.professionFilterID = nil
	self.professionFilterName = nil
	self.guildNewsEntries = {}
	self.guildNewsRequested = false
	self.headerDetailMode = "motd"
	self.guildMOTDText = ""
	self.guildInfoText = nil
	MarkDisplayListDirty(self)

	-- Update empty state visibility
	if IsGuildFrameVisible() then
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

	local includeClubInfo = provider.HasClubMemberInfoAPI and provider:HasClubMemberInfoAPI() or false
	local members, counts = provider:CollectRoster({ includeClubInfo = includeClubInfo })
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
	if not IsValidFilterMode(mode) then
		mode = FILTER_ONLINE
	end
	if self.filterMode == mode then
		return
	end
	self.filterMode = mode
	MarkDisplayListDirty(self)
	local DB = GetDB()
	if DB and DB.Set then
		DB:Set("guildTabFilterMode", mode)
	end
	self:RefreshFilterDropdown()
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

	if self.professionFilterID then
		local professionName = GetMemberProfession(member, self.professionFilterID)
		if not professionName then
			return false
		end
	end

	-- Search text
	if self.searchText ~= "" then
		local s = self.searchText
		if (member.name or ""):lower():find(s, 1, true) then return true end
		if (member.fullName or ""):lower():find(s, 1, true) then return true end
		if (member.rank or ""):lower():find(s, 1, true) then return true end
		if (member.zone or ""):lower():find(s, 1, true) then return true end
		if (member.className or ""):lower():find(s, 1, true) then return true end
		if (member.profession1Name or ""):lower():find(s, 1, true) then return true end
		if (member.profession2Name or ""):lower():find(s, 1, true) then return true end
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
		elseif mode == SORT_NICKNAME then
			local DB = ShouldUseGuildNicknames() and GetDB()
			local aName = DB and DB:GetGuildNickname(a.fullName) or ""
			local bName = DB and DB:GetGuildNickname(b.fullName) or ""
			if aName == "" then
				aName = a.name or ""
			end
			if bName == "" then
				bName = b.name or ""
			end
			aName, bName = aName:lower(), bName:lower()
			if aName ~= bName then
				result = aName < bName
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
	if not IsGuildFrameVisible() then
		needsRenderOnShow = true
		return
	end

	self:BuildDisplayList()

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end

	-- Update header info
	self:UpdateHeaderInfo()
	self:UpdateGuildFeatureBar()
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
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local modernDirectory = BFL.IsRetail
		and FriendsUI
		and FriendsUI.IsModernActive
		and FriendsUI:IsModernActive()
	if frame.SearchBox then
		if BFL.IsClassic or modernDirectory then
			frame.SearchBox:Show()
		else
			frame.SearchBox:SetText("")
			frame.SearchBox:Hide()
		end
	end
	if frame.SortDropdown then
		if BFL.IsClassic or modernDirectory then
			frame.SortDropdown:Show()
		else
			frame.SortDropdown:Hide()
		end
	end
	if frame.FilterDropdown then
		if BFL.IsClassic or modernDirectory then
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

function GuildFrame:GetFilterLabel(mode)
	local statusLabel
	for _, option in ipairs(GetFilterOptions()) do
		if option.value == mode then
			statusLabel = option.text
			break
		end
	end
	statusLabel = statusLabel or FRIENDS_LIST_ONLINE or "Online"
	if self.professionFilterName then
		return statusLabel .. " · " .. self.professionFilterName
	end
	return statusLabel
end

local function IsModernDropdown(dropdown)
	return BFL.IsModernDropdown and BFL.IsModernDropdown(dropdown)
end

local function SetDropdownText(dropdown, text)
	if not dropdown then
		return
	end
	if BFL.SetDropdownText then
		BFL.SetDropdownText(dropdown, text or "")
	end
end

local function RefreshModernDropdown(dropdown)
	if not IsModernDropdown(dropdown) then
		return
	end
	if dropdown.GenerateMenu then
		dropdown:GenerateMenu()
	elseif dropdown.Update then
		dropdown:Update()
	end
end

local function BuildDropdownOptionsFromItems(items, fallbackOptions, getSelectionText)
	local labels = {}
	local values = {}

	if items then
		for _, item in ipairs(items) do
			local itemType = item.type or "button"
			if not item.hidden and itemType ~= "divider" and itemType ~= "title" and item.value ~= nil then
				labels[#labels + 1] = item.text or tostring(item.value)
				values[#values + 1] = item.value
			end
		end
	end

	if #values == 0 and fallbackOptions then
		for _, option in ipairs(fallbackOptions) do
			if option.value ~= nil then
				labels[#labels + 1] = option.text or tostring(option.value)
				values[#values + 1] = option.value
			end
		end
	end

	if #values == 0 then
		return nil
	end

	return {
		labels = labels,
		values = values,
		getSelectionText = getSelectionText,
	}
end

local function InitializeGuildDropdown(dropdown, items, fallbackOptions, isSelected, selectValue, getSelectionText, width)
	local options = BuildDropdownOptionsFromItems(items, fallbackOptions, getSelectionText)
	if not (dropdown and options) then
		return false
	end

	if not BFL.InitializeDropdown then
		return false
	end

	if not IsModernDropdown(dropdown) and width and BFL.SetDropdownWidth then
		BFL.SetDropdownWidth(dropdown, width)
	end
	BFL.InitializeDropdown(dropdown, options, isSelected, selectValue)
	return true
end

function GuildFrame:RefreshSortDropdown()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local dropdown = frame and frame.SortDropdown
	if not dropdown then
		return
	end
	SetDropdownText(dropdown, self:GetSortLabel(self.sortMode))
	RefreshModernDropdown(dropdown)
end

function GuildFrame:RefreshFilterDropdown()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local dropdown = frame and frame.FilterDropdown
	if not dropdown then
		return
	end
	SetDropdownText(dropdown, self:GetFilterLabel(self.filterMode))
	RefreshModernDropdown(dropdown)
end

function GuildFrame:CreateSortDropdown(frame)
	if not frame then
		return
	end
	if frame.SortDropdown then
		return
	end

	local dropdown = BFL.CreateDropdown and BFL.CreateDropdown(frame, "BFL_GuildSortDropdown", 112, true)
	if not dropdown then
		return
	end

	frame.SortDropdown = dropdown
	local actions = GetGuildActions()
	InitializeGuildDropdown(
		dropdown,
		actions and actions.GetSortMenuItems and actions:GetSortMenuItems(),
		GetSortOptions(),
		function(value)
			return self.sortMode == value
		end,
		function(value)
			self:SetSort(value, true)
			self:RefreshSortDropdown()
		end,
		function(value)
			return self:GetSortLabel(value)
		end,
		112
	)
	self:RefreshSortDropdown()
end

function GuildFrame:CreateFilterDropdown(frame)
	if not frame then
		return
	end
	if frame.FilterDropdown then
		return
	end

	local dropdown = BFL.CreateDropdown and BFL.CreateDropdown(frame, "BFL_GuildFilterDropdown", 104, true)
	if not dropdown then
		return
	end

	frame.FilterDropdown = dropdown
	if not IsModernDropdown(dropdown) and BFL.SetDropdownWidth then
		BFL.SetDropdownWidth(dropdown, 104)
	end
	if BFL.InitializeDropdown then
		BFL.InitializeDropdown(dropdown, {
			getSelectionText = function()
				return self:GetFilterLabel(self.filterMode)
			end,
			populateRootDescription = function(rootDescription)
				self:PopulateFilterMenu(rootDescription)
			end,
		}, function()
			return false
		end, function() end)
	end
	self:RefreshFilterDropdown()
end

local function CreateGuildFeatureIconButton(parent, iconPath, tooltipText, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(20, 20)
	local selectedLine = button:CreateTexture(nil, "BORDER")
	selectedLine:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 0)
	selectedLine:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0)
	selectedLine:SetHeight(2)
	selectedLine:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.95))
	selectedLine:Hide()
	button.selectedLine = selectedLine
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 3)
	icon:SetTexture(iconPath)
	icon:SetAlpha(0.76)
	button.icon = icon
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(btn)
		btn.icon:SetAlpha(1)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		local text = type(tooltipText) == "function" and tooltipText() or tooltipText
		GameTooltip:SetText(text or "")
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(btn)
		btn.icon:SetAlpha(btn.selected and 1 or 0.76)
		if GameTooltip:IsOwned(btn) then
			GameTooltip:Hide()
		end
	end)
	return button
end

local function SetGuildFeatureButtonSelected(button, selected)
	if not button then
		return
	end
	button.selected = selected == true
	button.icon:SetAlpha(button.selected and 1 or 0.76)
	button.selectedLine:SetShown(button.selected)
end

local function CreateGuildNewsScrollButton(parent, iconPath, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(14, 14)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture(iconPath)
	icon:SetAlpha(0.75)
	button.icon = icon
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(btn)
		btn.icon:SetAlpha(btn:IsEnabled() and 1 or 0.3)
	end)
	button:SetScript("OnLeave", function(btn)
		btn.icon:SetAlpha(btn:IsEnabled() and 0.75 or 0.3)
	end)
	return button
end

function GuildFrame:CreateGuildFeatureBar(frame)
	if not frame or frame.FeatureBar then
		return frame and frame.FeatureBar
	end

	local bar = CreateFrame("Frame", nil, frame.ListInset)
	bar:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
	bar:SetPoint("TOPRIGHT", frame.ListInset, "TOPRIGHT", -4, -4)
	bar:SetHeight(GUILD_HEADER_CONTENT_HEIGHT)
	local background = bar:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.04, 0.04, 0.04, 0.72)
	bar.background = background
	local divider = bar:CreateTexture(nil, "BORDER")
	divider:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
	divider:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	divider:SetHeight(1)
	divider:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.3))
	bar.divider = divider

	bar.motdButton = CreateGuildFeatureIconButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\message-square.blp",
		function()
			return GetGuildMOTDLabel()
		end,
		function()
			self:SetGuildHeaderMode("motd")
		end
	)
	bar.newsButton = CreateGuildFeatureIconButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\rss.blp",
		function()
			return (BFL.L and BFL.L.GUILD_NEWS_TOOLTIP) or "Refresh and show recent guild news"
		end,
		function()
			self:SetGuildHeaderMode("news")
		end
	)

	bar.newsFilterButton = CreateGuildFeatureIconButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\filter.blp",
		_G.GUILD_NEWS_FILTERS or _G.FILTERS or "Filters",
		function(button)
			self:ShowGuildNewsFilterMenu(button)
		end
	)

	bar.infoButton = CreateGuildFeatureIconButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\info.blp",
		function()
			return (BFL.L and BFL.L.GUILD_INFO_TOOLTIP) or "Show guild information"
		end,
		function()
			self:SetGuildHeaderMode("info")
		end
	)

	bar.detailText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(bar.detailText)
	bar.detailText:SetPoint("TOPLEFT", bar, "TOPLEFT", 7, -29)
	bar.detailText:SetPoint("RIGHT", bar, "RIGHT", -7, 0)
	bar.detailText:SetJustifyH("LEFT")
	bar.detailText:SetJustifyV("TOP")
	bar.detailText:SetWordWrap(true)
	bar.detailText:SetNonSpaceWrap(true)
	bar.detailText:SetMaxLines(3)
	bar.detailText:SetTextColor(0.75, 0.75, 0.75)
	bar.detailText:Hide()

	bar.newsViewport = CreateFrame("ScrollFrame", nil, bar)
	bar.newsViewport:SetPoint("TOPLEFT", bar, "TOPLEFT", 7, -28)
	bar.newsViewport:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -21, 4)
	bar.newsViewport:EnableMouseWheel(true)
	bar.newsViewport:Hide()
	bar.newsContent = CreateFrame("Frame", nil, bar.newsViewport)
	bar.newsContent:SetSize(1, 1)
	bar.newsViewport:SetScrollChild(bar.newsContent)
	bar.newsRows = {}
	bar.newsViewport:SetScript("OnSizeChanged", function(scrollFrame, width)
		bar.newsContent:SetWidth(math.max(1, width))
	end)
	bar.newsViewport:SetScript("OnMouseWheel", function(scrollFrame, delta)
		self:ScrollGuildNews(-delta * GUILD_NEWS_ROW_HEIGHT)
	end)
	bar.newsViewport:SetScript("OnVerticalScroll", function()
		self:UpdateGuildNewsScrollControls()
	end)
	bar.newsViewport:SetScript("OnScrollRangeChanged", function()
		self:UpdateGuildNewsScrollControls()
	end)

	bar.newsScrollUp = CreateGuildNewsScrollButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-up.blp",
		function() self:ScrollGuildNews(-GUILD_NEWS_ROW_HEIGHT) end
	)
	bar.newsScrollUp:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -4, -29)
	bar.newsScrollDown = CreateGuildNewsScrollButton(
		bar,
		"Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down.blp",
		function() self:ScrollGuildNews(GUILD_NEWS_ROW_HEIGHT) end
	)
	bar.newsScrollDown:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -4, 4)
	bar.newsScrollUp:Hide()
	bar.newsScrollDown:Hide()

	frame.FeatureBar = bar
	return bar
end

function GuildFrame:UpdateGuildListAnchors()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not frame or not frame.ListInset then
		return
	end
	local bar = frame.FeatureBar
	local useBar = bar and bar:IsShown()

	if BFL.HasModernScrollBox and frame.ScrollBox then
		local scrollBarReserve, scrollBarGap, scrollBarWidth = self:GetRetailScrollBarGeometry()
		frame.ScrollBox:ClearAllPoints()
		if useBar then
			frame.ScrollBox:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2)
		else
			frame.ScrollBox:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
		end
		frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -scrollBarReserve, 2)
		if frame.ScrollBar then
			frame.ScrollBar:ClearAllPoints()
			frame.ScrollBar:SetWidth(scrollBarWidth)
			frame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollBox, "TOPRIGHT", scrollBarGap, 0)
			frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.ScrollBox, "BOTTOMRIGHT", scrollBarGap, 0)
		end
	elseif frame.FauxScroll then
		frame.FauxScroll:ClearAllPoints()
		if useBar then
			frame.FauxScroll:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 6, -2)
		else
			frame.FauxScroll:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 10, -2)
		end
		frame.FauxScroll:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -22, 18)
	end
end

function GuildFrame:SetProfessionFilter(professionID, professionName)
	professionID = tonumber(professionID)
	if professionID and professionID <= 0 then
		professionID = nil
	end
	if self.professionFilterID == professionID then
		return
	end
	self.professionFilterID = professionID
	self.professionFilterName = professionID and professionName or nil
	MarkDisplayListDirty(self)
	self:RefreshFilterDropdown()
	self:RefreshHeaderControls(true)
	self:Refresh()
end

function GuildFrame:GetProfessionFilterMenuItems()
	local provider = GetGuildRosterData()
	if not (provider and provider.HasClubMemberInfoAPI and provider:HasClubMemberInfoAPI()) then
		return nil
	end
	local catalog = provider and provider.GetProfessionCatalog and provider:GetProfessionCatalog(self.guildMembers) or {}
	local items = {
		{
			type = "radio",
			text = (L and L.GUILD_PROFESSION_ALL) or "All Professions",
			checked = function() return self.professionFilterID == nil end,
			func = function() self:SetProfessionFilter(nil) end,
		},
	}
	for _, profession in ipairs(catalog) do
		local professionID = profession.id
		local professionName = profession.name
		items[#items + 1] = {
			type = "radio",
			text = professionName,
			checked = function() return self.professionFilterID == professionID end,
			func = function() self:SetProfessionFilter(professionID, professionName) end,
		}
	end
	return items
end

local function IsGuildNewsAchievement(newsType)
	return newsType == NEWS_GUILD_ACHIEVEMENT_TYPE or newsType == NEWS_PLAYER_ACHIEVEMENT_TYPE
end

local function IsGuildNewsLoot(newsType)
	return newsType == NEWS_ITEM_LOOTED_TYPE
		or newsType == NEWS_ITEM_CRAFTED_TYPE
		or newsType == NEWS_ITEM_PURCHASED_TYPE
		or newsType == NEWS_LEGENDARY_LOOTED_TYPE
end

local function FormatGuildNewsEntry(entry)
	if type(entry) ~= "table" then
		return ""
	end
	local newsType = tonumber(entry.newsType) or 0
	local whoText = tostring(entry.whoText or ""):gsub("[%c]+", " ")
	local whatText = tostring(entry.whatText or ""):gsub("[%c]+", " ")
	local text1 = whoText
	local text2 = whatText
	local achievementColor = _G.ACHIEVEMENT_COLOR_CODE or "|cffffff00"
	if newsType == NEWS_GUILD_ACHIEVEMENT_TYPE and whatText ~= "" then
		text1 = achievementColor .. "[" .. whatText .. "]|r"
		text2 = ""
	elseif newsType == NEWS_PLAYER_ACHIEVEMENT_TYPE and whatText ~= "" then
		text2 = achievementColor .. "[" .. whatText .. "]|r"
	end

	local formatString = _G["GUILD_NEWS_FORMAT" .. newsType]
	if type(formatString) == "string" and formatString ~= "" then
		local ok, formatted = pcall(string.format, formatString, text1, text2)
		if ok and type(formatted) == "string" and formatted ~= "" then
			return formatted
		end
	end
	if whoText ~= "" and whatText ~= "" then
		return whoText .. " - " .. whatText
	end
	return whoText ~= "" and whoText or whatText
end

function GuildFrame:ShowGuildNewsFilterMenu(owner)
	local provider = GetGuildRosterData()
	if not (BFL.OpenSimpleContextMenu and provider and provider.HasGuildNewsFilterAPI
		and provider:HasGuildNewsFilterAPI())
	then
		return
	end

	local items = {
		{ type = "title", text = _G.GUILD_NEWS_FILTERS or _G.FILTERS or "Filters" },
	}
	for _, filterID in ipairs(GUILD_NEWS_FILTER_IDS) do
		if not provider.IsGuildNewsFilterAvailable or provider:IsGuildNewsFilterAvailable(filterID) then
			local capturedID = filterID
			items[#items + 1] = {
				type = "checkbox",
				text = _G["GUILD_NEWS_FILTER" .. capturedID] or tostring(capturedID),
				keepShownOnClick = true,
				checked = function()
					local filters = provider:GetGuildNewsFilters()
					return filters[capturedID] == true
				end,
				func = function()
					local filters = provider:GetGuildNewsFilters()
					if provider:SetGuildNewsFilter(capturedID, filters[capturedID] ~= true) then
						self.headerDetailMode = "news"
						self:RefreshGuildNews()
					end
					return MenuResponse and MenuResponse.Refresh
				end,
			}
		end
	end
	BFL.OpenSimpleContextMenu(owner or UIParent, "BFL_GuildNewsFilters", items)
end

function GuildFrame:UpdateGuildNewsScrollControls()
	local bar = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
		and BetterFriendsFrame.GuildFrame.FeatureBar
	if not (bar and bar.newsViewport and bar.newsScrollUp and bar.newsScrollDown) then
		return
	end
	local range = math.max(0, bar.newsViewport:GetVerticalScrollRange() or 0)
	local offset = math.max(0, math.min(bar.newsViewport:GetVerticalScroll() or 0, range))
	local showControls = bar.newsViewport:IsShown() and range > 0.5
	bar.newsScrollUp:SetShown(showControls)
	bar.newsScrollDown:SetShown(showControls)
	if not showControls then
		return
	end
	local canScrollUp = offset > 0.5
	local canScrollDown = offset < range - 0.5
	bar.newsScrollUp:SetEnabled(canScrollUp)
	bar.newsScrollDown:SetEnabled(canScrollDown)
	bar.newsScrollUp.icon:SetAlpha(canScrollUp and 0.75 or 0.3)
	bar.newsScrollDown.icon:SetAlpha(canScrollDown and 0.75 or 0.3)
end

function GuildFrame:ScrollGuildNews(delta)
	local bar = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
		and BetterFriendsFrame.GuildFrame.FeatureBar
	if not (bar and bar.newsViewport and bar.newsViewport:IsShown()) then
		return
	end
	local range = math.max(0, bar.newsViewport:GetVerticalScrollRange() or 0)
	local offset = math.max(0, math.min((bar.newsViewport:GetVerticalScroll() or 0) + delta, range))
	bar.newsViewport:SetVerticalScroll(offset)
	self:UpdateGuildNewsScrollControls()
end

function GuildFrame:ShowGuildNewsEntryTooltip(row)
	local entry = row and row.entry
	if type(entry) ~= "table" then
		return
	end
	local newsType = tonumber(entry.newsType) or 0
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	if IsGuildNewsLoot(newsType) and type(entry.whatText) == "string" and entry.whatText:find("|H", 1, true) then
		local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, entry.whatText)
		if ok then
			GameTooltip:Show()
			return
		end
	elseif IsGuildNewsAchievement(newsType) and type(GetAchievementInfo) == "function" then
		local results = { pcall(GetAchievementInfo, tonumber(entry.newsDataID) or 0) }
		local name = results[3]
		local description = results[9]
		if results[1] and type(name) == "string" and name ~= "" then
			GameTooltip:SetText((_G.ACHIEVEMENT_COLOR_CODE or "|cffffff00") .. name .. "|r")
			if type(description) == "string" and description ~= "" then
				GameTooltip:AddLine(description, 1, 1, 1, true)
			end
			GameTooltip:Show()
			return
		end
	elseif newsType == NEWS_DUNGEON_ENCOUNTER_TYPE then
		local title = tostring(entry.whatText or "")
		local zone
		if type(GetRealZoneText) == "function" and type(entry.data) == "table" and entry.data[1] then
			local ok, result = pcall(GetRealZoneText, entry.data[1])
			if ok and type(result) == "string" then
				zone = result
			end
		end
		if title ~= "" then
			GameTooltip:SetText(title)
			if zone and zone ~= "" then
				GameTooltip:AddLine(zone, 1, 1, 1)
			end
			GameTooltip:Show()
			return
		end
	end

	if row.text and row.text:IsTruncated() then
		GameTooltip:SetText(row.displayText or "")
		GameTooltip:Show()
	end
end

local function LinkGuildNewsItem(entry)
	if type(entry) ~= "table" then
		return false
	end
	if ChatFrameUtil and type(ChatFrameUtil.LinkItem) == "function" then
		return pcall(ChatFrameUtil.LinkItem, tonumber(entry.newsDataID) or 0, entry.whatText)
	end
	if type(ChatEdit_InsertLink) == "function" and type(entry.whatText) == "string" then
		return pcall(ChatEdit_InsertLink, entry.whatText)
	end
	return false
end

function GuildFrame:OpenGuildNewsEntryMenu(owner, entry)
	if not (BFL.OpenSimpleContextMenu and type(entry) == "table") then
		return
	end
	local newsType = tonumber(entry.newsType) or 0
	local items = {
		{ type = "title", text = tostring(entry.whatText or entry.whoText or "") },
	}
	if IsGuildNewsAchievement(newsType) and type(ShowAchievementFrameForAchievement) == "function" then
		items[#items + 1] = {
			text = _G.GUILD_NEWS_VIEW_ACHIEVEMENT or _G.ACHIEVEMENTS or "Achievement",
			func = function()
				pcall(ShowAchievementFrameForAchievement, tonumber(entry.newsDataID) or 0)
			end,
		}
	elseif IsGuildNewsLoot(newsType) then
		items[#items + 1] = {
			text = _G.GUILD_NEWS_LINK_ITEM or _G.ITEM_LINK or _G.LINK or "Link Item",
			func = function() LinkGuildNewsItem(entry) end,
		}
	end
	if #items > 1 then
		BFL.OpenSimpleContextMenu(owner or UIParent, "BFL_GuildNewsEntry", items)
	end
end

function GuildFrame:ActivateGuildNewsEntry(row, mouseButton)
	local entry = row and row.entry
	if type(entry) ~= "table" then
		return
	end
	local newsType = tonumber(entry.newsType) or 0
	if mouseButton == "RightButton" then
		self:OpenGuildNewsEntryMenu(row, entry)
		return
	end
	if IsGuildNewsAchievement(newsType) and type(ShowAchievementFrameForAchievement) == "function" then
		pcall(ShowAchievementFrameForAchievement, tonumber(entry.newsDataID) or 0)
	elseif IsGuildNewsLoot(newsType) and type(entry.whatText) == "string" then
		if type(HandleModifiedItemClick) == "function" then
			local ok, handled = pcall(HandleModifiedItemClick, entry.whatText)
			if ok and handled then
				return
			end
		end
		if type(SetItemRef) == "function" then
			local link = entry.whatText:match("|H([^|]+)|h")
			local text = entry.whatText:match("|h(.-)|h") or entry.whatText
			if link then
				pcall(SetItemRef, link, text, "LeftButton", DEFAULT_CHAT_FRAME)
			end
		end
	end
end

function GuildFrame:GetGuildNewsRow(bar, index)
	local row = bar.newsRows[index]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, bar.newsContent)
	row:SetHeight(GUILD_NEWS_ROW_HEIGHT)
	row:SetPoint("TOPLEFT", bar.newsContent, "TOPLEFT", 0, -((index - 1) * GUILD_NEWS_ROW_HEIGHT))
	row:SetPoint("TOPRIGHT", bar.newsContent, "TOPRIGHT", 0, -((index - 1) * GUILD_NEWS_ROW_HEIGHT))
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:EnableMouseWheel(true)
	local highlight = row:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(GetAccentColor(1, 0.82, 0, 0.1))
	row.highlight = highlight
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ApplyDefaultSlugToFontString(row.text)
	row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
	row.text:SetPoint("RIGHT", row, "RIGHT", -2, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row.text:SetMaxLines(1)
	row:SetScript("OnClick", function(button, mouseButton)
		self:ActivateGuildNewsEntry(button, mouseButton)
	end)
	row:SetScript("OnEnter", function(button)
		self:ShowGuildNewsEntryTooltip(button)
	end)
	row:SetScript("OnLeave", function(button)
		if GameTooltip:IsOwned(button) then
			GameTooltip:Hide()
		end
	end)
	row:SetScript("OnMouseWheel", function(_, delta)
		self:ScrollGuildNews(-delta * GUILD_NEWS_ROW_HEIGHT)
	end)
	bar.newsRows[index] = row
	return row
end

function GuildFrame:RenderGuildNews(bar)
	if not (bar and bar.newsViewport and bar.newsContent) then
		return 0
	end
	for _, row in ipairs(bar.newsRows) do
		row:Hide()
	end

	local visibleCount = 0
	for _, entry in ipairs(self.guildNewsEntries or {}) do
		local text = FormatGuildNewsEntry(entry)
		if text ~= "" then
			visibleCount = visibleCount + 1
			local row = self:GetGuildNewsRow(bar, visibleCount)
			row.entry = entry
			row.displayText = text
			row.text:SetText("|cffd7b75b•|r " .. text)
			row:Show()
		end
	end
	bar.newsContent:SetHeight(math.max(1, visibleCount * GUILD_NEWS_ROW_HEIGHT))
	if self.guildNewsResetScroll then
		bar.newsViewport:SetVerticalScroll(0)
		self.guildNewsResetScroll = false
	end
	self:UpdateGuildNewsScrollControls()
	return visibleCount
end

function GuildFrame:RefreshGuildNews()
	local provider = GetGuildRosterData()
	if not (provider and provider.HasGuildNewsAPI and provider:HasGuildNewsAPI()) then
		self.guildNewsEntries = {}
		return
	end
	self.guildNewsEntries = provider and provider.CollectGuildNews
		and provider:CollectGuildNews(GUILD_NEWS_MAX_ENTRIES) or {}
	self.guildNewsResetScroll = true
	if IsGuildFrameVisible() then
		self:UpdateGuildFeatureBar()
	end
end

function GuildFrame:RequestGuildNews(force)
	if self.guildNewsRequested and not force then
		return true
	end
	local provider = GetGuildRosterData()
	if not (provider and provider.HasGuildNewsAPI and provider:HasGuildNewsAPI()) then
		return false
	end
	self.guildNewsRequested = true
	local requested = provider.RequestGuildNews and provider:RequestGuildNews() or false
	self:RefreshGuildNews()
	return requested
end

function GuildFrame:SetGuildHeaderMode(mode)
	if mode ~= "motd" and mode ~= "info" and mode ~= "news" then
		mode = "motd"
	end

	local provider = GetGuildRosterData()
	if mode == "info" then
		if not (provider and provider.HasGuildInfoTextAPI and provider:HasGuildInfoTextAPI()) then
			mode = "motd"
		else
			self.guildInfoText = provider.GetGuildInfoText and provider:GetGuildInfoText() or ""
		end
	elseif mode == "news" then
		if not (provider and provider.HasGuildNewsAPI and provider:HasGuildNewsAPI()) then
			mode = "motd"
		end
	end

	self.headerDetailMode = mode
	if mode == "news" then
		-- Match Blizzard's Guild News panel: entering the view always requests
		-- current server data and applies the active filters/sticky ordering.
		self:RequestGuildNews(true)
	end
	self:UpdateGuildFeatureBar()
	self:UpdateHeaderEditButtons()
end

-- Kept as a compatibility entry point for callers from older UI revisions.
function GuildFrame:ToggleGuildInfo()
	self:SetGuildHeaderMode("info")
end

function GuildFrame:LayoutGuildHeaderButtons(frame, bar, showInfo, showNews, reserveNewsFilter)
	local buttons = {}
	buttons[#buttons + 1] = bar.motdButton
	if showInfo then
		buttons[#buttons + 1] = bar.infoButton
	end
	if showNews then
		buttons[#buttons + 1] = bar.newsButton
	end
	if reserveNewsFilter then
		buttons[#buttons + 1] = bar.newsFilterButton
	end

	for _, button in ipairs({ bar.motdButton, bar.infoButton, bar.newsFilterButton, bar.newsButton }) do
		button:ClearAllPoints()
	end

	local previous
	for index = #buttons, 1, -1 do
		local button = buttons[index]
		if previous then
			button:SetPoint("RIGHT", previous, "LEFT", -2, 0)
		else
			button:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -3, -3)
		end
		previous = button
	end
end

function GuildFrame:LayoutGuildHeaderContent(frame, bar)
	local detailRight = frame.MOTDEditButton and frame.MOTDEditButton:IsShown() and -25 or -7
	bar.detailText:ClearAllPoints()
	bar.detailText:SetPoint("TOPLEFT", bar, "TOPLEFT", 7, GUILD_HEADER_CONTENT_TOP)
	bar.detailText:SetPoint("RIGHT", bar, "RIGHT", detailRight, 0)
	bar.detailText:SetMaxLines(BFL.IsClassic and 3 or 5)

	bar.newsViewport:ClearAllPoints()
	bar.newsViewport:SetPoint("TOPLEFT", bar, "TOPLEFT", 7, GUILD_HEADER_CONTENT_TOP + 1)
	bar.newsViewport:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -21, 4)
	bar.newsScrollUp:ClearAllPoints()
	bar.newsScrollUp:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -4, GUILD_HEADER_CONTENT_TOP)
end

function GuildFrame:UpdateGuildFeatureBar()
	local frame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not frame or not frame.ListInset then
		return
	end
	local bar = self:CreateGuildFeatureBar(frame)
	local provider = GetGuildRosterData()
	local inGuild = provider and provider.IsInGuild and provider:IsInGuild() or false
	local showInfo = provider and provider.HasGuildInfoTextAPI and provider:HasGuildInfoTextAPI()
	local showNews = provider and provider.HasGuildNewsAPI and provider:HasGuildNewsAPI()
	local showBar = inGuild
	bar:SetShown(showBar)
	if not showBar then
		self:UpdateGuildListAnchors()
		return
	end
	if not self.headerDetailMode
		or (self.headerDetailMode == "info" and not showInfo)
		or (self.headerDetailMode == "news" and not showNews)
	then
		self.headerDetailMode = "motd"
	end

	bar.motdButton:Show()
	bar.infoButton:SetShown(showInfo)
	bar.newsButton:SetShown(showNews)
	local hasNewsFilters = showNews
		and provider.HasGuildNewsFilterAPI and provider:HasGuildNewsFilterAPI()
	local showNewsFilters = hasNewsFilters and self.headerDetailMode == "news"
	bar.newsFilterButton:SetShown(showNewsFilters)
	-- Keep the filter slot reserved in every header view so the MOTD, info, and
	-- news buttons do not move when the filter itself appears in Guild News.
	self:LayoutGuildHeaderButtons(frame, bar, showInfo, showNews, hasNewsFilters)
	self:LayoutGuildHeaderContent(frame, bar)
	SetGuildFeatureButtonSelected(bar.motdButton, self.headerDetailMode == "motd")
	SetGuildFeatureButtonSelected(bar.infoButton, self.headerDetailMode == "info")
	SetGuildFeatureButtonSelected(bar.newsButton, self.headerDetailMode == "news")
	local detailText = ""
	local showNewsViewport = false
	if self.headerDetailMode == "motd" then
		local motd = tostring(self.guildMOTDText or "")
		detailText = FormatGuildLabeledText(GetGuildMOTDLabel(), motd)
	elseif self.headerDetailMode == "info" and showInfo then
		detailText = tostring(self.guildInfoText or ""):gsub("|n", " "):gsub("\\n", " "):gsub("\n", " ")
		if detailText == "" then
			detailText = (L and L.GUILD_INFO_EMPTY) or "No guild information is available."
		end
	elseif self.headerDetailMode == "news" and showNews then
		showNewsViewport = true
		bar.newsViewport:Show()
		local visibleNews = self:RenderGuildNews(bar)
		if visibleNews == 0 then
			showNewsViewport = false
			bar.newsViewport:Hide()
			detailText = (L and L.GUILD_NEWS_EMPTY) or "No recent guild news is available."
		end
	end

	bar.newsViewport:SetShown(showNewsViewport)
	if not showNewsViewport then
		bar.newsScrollUp:Hide()
		bar.newsScrollDown:Hide()
	end
	bar.detailText:SetText(detailText)
	bar.detailText:SetShown(detailText ~= "")
	if self.headerDetailMode == "motd" or self.headerDetailMode == "info" then
		SetGuildTextColor(bar.detailText)
	else
		bar.detailText:SetTextColor(0.75, 0.75, 0.75, 1)
	end
	bar:SetHeight(GUILD_HEADER_CONTENT_HEIGHT)
	if showNewsViewport then
		self:UpdateGuildNewsScrollControls()
	end
	self:UpdateGuildListAnchors()
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
	-- UpdateLayout(). MOTD, news and guild information share one content area.
	if not BFL.IsClassic then
		local inset = frame:GetParent() and frame:GetParent().Inset
		if inset then
			-- Row 1: Guild name (left) + member count (right) -- STATIC
			frame.GuildName:ClearAllPoints()
			frame.GuildName:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -4)
			frame.MemberCount:ClearAllPoints()
			frame.MemberCount:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -6, -4)

			-- Bottom buttons: mirror the Friends tab Add Friend / Send Message layout.
			frame.ActionsButton:ClearAllPoints()
			frame.ActionsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 4)

			-- Initial layout for the unified guild header content.
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
	self:CreateGuildFeatureBar(frame)
	if frame.MOTDText then
		frame.MOTDText:SetText("")
		frame.MOTDText:Hide()
	end
	if frame.HeaderDivider then
		frame.HeaderDivider:Hide()
	end

	if not BFL.HasModernScrollBox then
		self:InitializeClassicScrollFrame(frame)
		self:UpdateGuildFeatureBar()
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
	local scrollBarReserve, scrollBarGap, scrollBarWidth = self:GetRetailScrollBarGeometry()
	frame.ScrollBox:ClearAllPoints()
	frame.ScrollBox:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -scrollBarReserve, 2)

	frame.ScrollBar:ClearAllPoints()
	frame.ScrollBar:SetWidth(scrollBarWidth)
	frame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollBox, "TOPRIGHT", scrollBarGap, 0)
	frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.ScrollBox, "BOTTOMRIGHT", scrollBarGap, 0)

	-- Create DataProvider
	guildDataProvider = CreateDataProvider()
	frame.ScrollBox:SetDataProvider(guildDataProvider)

	-- Empty state
	self:CreateEmptyState(frame)
	self:UpdateGuildFeatureBar()
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

	button.rowAction = CreateFrame("Button", nil, button)
	button.rowAction:SetSize(18, 18)
	button.rowAction:SetPoint("RIGHT", button, "RIGHT", -5, 0)
	button.rowAction.icon = button.rowAction:CreateTexture(nil, "ARTWORK")
	button.rowAction.icon:SetPoint("TOPLEFT", button.rowAction, "TOPLEFT", 2, -2)
	button.rowAction.icon:SetPoint("BOTTOMRIGHT", button.rowAction, "BOTTOMRIGHT", -2, 2)
	button.rowAction.icon:SetAlpha(0.82)
	button.rowAction:RegisterForClicks("LeftButtonUp")
	button.rowAction:SetScript("OnClick", function(actionButton)
		local memberData = actionButton:GetParent() and actionButton:GetParent().memberData
		if not memberData then
			return
		end
		local actions = GetGuildActions()
		if self.professionFilterID and actions and actions.QueryMemberRecipes then
			actions:QueryMemberRecipes(memberData, self.professionFilterID)
		end
	end)
	button.rowAction:SetScript("OnEnter", function(actionButton)
		actionButton.icon:SetAlpha(1)
		if not self.professionFilterID then
			return
		end
		GameTooltip:SetOwner(actionButton, "ANCHOR_RIGHT")
		local professionName = GetMemberProfession(actionButton:GetParent().memberData, self.professionFilterID)
		GameTooltip:SetText(string.format(
			(L and L.GUILD_PROFESSION_VIEW_RECIPES) or "View %s Recipes",
			professionName or self.professionFilterName or PROFESSIONS_COLUMN_LABEL or "Profession"
		))
		GameTooltip:Show()
	end)
	button.rowAction:SetScript("OnLeave", function(actionButton)
		actionButton.icon:SetAlpha(0.82)
		if GameTooltip:IsOwned(actionButton) then
			GameTooltip:Hide()
		end
	end)

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

	local provider = GetGuildRosterData()
	local canViewRecipes = not member._isMock
		and self.professionFilterID
		and provider and provider.HasGuildRecipeAPI and provider:HasGuildRecipeAPI()
		and GetMemberProfession(member, self.professionFilterID)

	-- Status icon (Blizzard AFK/DND/Mobile, hidden for plain online)
	if button.statusIcon then
		button.statusIcon:ClearAllPoints()
		button.statusIcon:SetPoint("TOPRIGHT", button, "TOPRIGHT", canViewRecipes and -27 or -7, -7)
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

	if button.rowAction then
		if canViewRecipes then
			button.rowAction.icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\tool.blp")
			button.rowAction:Show()
		else
			button.rowAction:Hide()
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
	if self.professionFilterID then
		local professionName = GetMemberProfession(member, self.professionFilterID)
		if professionName and professionName ~= "" then
			table.insert(infoParts, professionName)
		end
	end
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
	local inGuild = provider and provider.IsInGuild and provider:IsInGuild() or false

	-- Guild name
	if guildFrame.GuildName then
		if inGuild then
			local guildName = provider.GetGuildName and provider:GetGuildName() or ""
			guildFrame.GuildName:SetText(guildName or "")
		else
			guildFrame.GuildName:SetText("")
		end
	end

	-- Member count -- unified "N / M online" format
	if guildFrame.MemberCount then
		guildFrame.MemberCount:SetShown(inGuild)
		if inGuild then
			local online = self.onlineMembers or 0
			local total = self.totalMembers or 0
			local fmt = (L and L.GUILD_HEADER_ONLINE_FORMAT) or "%d / %d online"
			guildFrame.MemberCount:SetText(format(fmt, online, total))
		else
			guildFrame.MemberCount:SetText("")
		end
	end
	if guildFrame.ActionsButton then
		guildFrame.ActionsButton:SetEnabled(inGuild)
	end
	local FriendsUI = BFL:GetModule("FriendsUI")
	local modernAction = FriendsUI
		and FriendsUI.selectedSection == "guild"
		and FriendsUI.root
		and FriendsUI.root.BottomActionBar
		and FriendsUI.root.BottomActionBar.AddFriendButton
	if modernAction then
		modernAction:SetEnabled(inGuild)
	end

	self:UpdateTabard()
	self:UpdateMOTD()
	self:UpdateHeaderEditButtons()
end

function GuildFrame:UpdateMOTD()
	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	if not guildFrame then return end
	if not IsGuildFrameVisible() then
		needsRenderOnShow = true
		return
	end

	local motd = ""
	local provider = GetGuildRosterData()
	local getGuildMOTD = provider and provider.GetGuildMOTD
	if getGuildMOTD then
		local ok, result = pcall(getGuildMOTD, provider)
		if ok and result then
			motd = tostring(result):gsub("|n", " "):gsub("\\n", " "):gsub("\n", " ")
		end
	elseif BFL.GetGuildMOTD then
		local ok, result = pcall(BFL.GetGuildMOTD)
		if ok and result then
			motd = tostring(result):gsub("|n", " "):gsub("\\n", " "):gsub("\n", " ")
		end
	end

	self.guildMOTDText = motd
	if guildFrame.MOTDText then
		guildFrame.MOTDText:SetText("")
		guildFrame.MOTDText:Hide()
	end
	if guildFrame.HeaderDivider then
		guildFrame.HeaderDivider:Hide()
	end
	if BFL.IsClassic then
		self:UpdateGuildFeatureBar()
	else
		self:UpdateLayout()
	end
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
		tostring(self.professionFilterID or ""),
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
			else
				SetDropdownText(header.QuickFilterDropdown, self:GetFilterLabel(self.filterMode))
			end
		end
		if header.PrimarySortDropdown then
			if header.PrimarySortDropdown.GenerateMenu then
				header.PrimarySortDropdown:GenerateMenu()
			else
				SetDropdownText(header.PrimarySortDropdown, actions:GetSortLabel(self.sortMode))
			end
		end
		local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
		local inset = BetterFriendsFrame and BetterFriendsFrame.Inset
		local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
		local modernLayout = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()
		if not modernLayout then
			self:LayoutLegacyGuildHeader(guildFrame, inset, header)
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

	local professionItems = self:GetProfessionFilterMenuItems()
	if professionItems and BFL.PopulateSimpleMenu then
		BFL.PopulateSimpleMenu(rootDescription, {
			{
				text = GetGuildProfessionLabel(),
				children = professionItems,
			},
		})
	end
end

function GuildFrame:PopulateSortMenu(rootDescription)
	local actions = GetGuildActions()
	if actions and actions.PopulateSortMenu then
		actions:PopulateSortMenu(rootDescription)
	end
end

function GuildFrame:GetHeaderFilterText()
	return self:GetFilterLabel(self.filterMode)
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
	local featureBar = guildFrame.FeatureBar or guildFrame
	guildFrame.MOTDEditButton:SetPoint("TOPRIGHT", featureBar, "TOPRIGHT", -4, GUILD_HEADER_CONTENT_TOP - 1)

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
		local showMOTDEdit = self.headerDetailMode == "motd"
			and actions and actions.CanEditMOTD and actions:CanEditMOTD()
		local featureBar = guildFrame.FeatureBar or guildFrame
		guildFrame.MOTDEditButton:ClearAllPoints()
		guildFrame.MOTDEditButton:SetPoint("TOPRIGHT", featureBar, "TOPRIGHT", -4, GUILD_HEADER_CONTENT_TOP - 1)
		if showMOTDEdit then
			guildFrame.MOTDEditButton:Show()
		else
			guildFrame.MOTDEditButton:Hide()
		end
		local detailText = guildFrame.FeatureBar and guildFrame.FeatureBar.detailText
		if detailText then
			detailText:SetPoint("RIGHT", guildFrame.FeatureBar, "RIGHT", showMOTDEdit and -25 or -7, 0)
		end
	end
end

-- ========================================
-- Dynamic Layout (positions the unified guild header and roster)
-- ========================================

function GuildFrame:LayoutLegacyGuildHeader(guildFrame, inset, header)
	if not (guildFrame and inset and header and header.SearchBox and header.QuickFilterDropdown and header.PrimarySortDropdown) then
		return false
	end

	local searchBox = header.SearchBox
	local sortDropdown = header.PrimarySortDropdown
	local flatThemeActive = BFL.UsesFlatTheme and BFL:UsesFlatTheme()
	local guildNameOffsetX = flatThemeActive and 2 or -3.5

	if header.SecondarySortDropdown then
		header.SecondarySortDropdown:Hide()
	end
	local memberCountAnchor = searchBox
	if not IsSimpleModeEnabled() then
		local insetRight = inset.GetRight and inset:GetRight()
		for _, control in ipairs({ sortDropdown, header.QuickFilterDropdown }) do
			local controlRight = control and control.GetRight and control:GetRight()
			if control and control.IsShown and control:IsShown()
				and insetRight and controlRight and controlRight <= insetRight + 1 then
				memberCountAnchor = control
				break
			end
		end
	end

	-- The shared header geometry belongs to FriendsList. Re-anchoring SearchBox
	-- against its dropdowns here can create a cycle because the dropdowns are
	-- already anchored back to SearchBox. Guild only owns the content below that
	-- established row.
	guildFrame.GuildName:ClearAllPoints()
	guildFrame.GuildName:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", guildNameOffsetX, -8)
	guildFrame.MemberCount:ClearAllPoints()
	guildFrame.MemberCount:SetPoint("TOPRIGHT", memberCountAnchor, "BOTTOMRIGHT", 0, -8)

	guildFrame.ListInset:ClearAllPoints()
	guildFrame.ListInset:SetPoint("TOPLEFT", guildFrame.GuildName, "BOTTOMLEFT", -6, -8)
	guildFrame.ListInset:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
	return true
end

function GuildFrame:UpdateLayout()
	if not self:IsEnabled() then
		return
	end

	local guildFrame = BetterFriendsFrame and BetterFriendsFrame.GuildFrame
	local inset = BetterFriendsFrame and BetterFriendsFrame.Inset
	if not guildFrame or not inset then return end
	if BFL.IsClassic then return end
	self:ApplyV1Visibility(guildFrame)
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local modernLayout = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()
	local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
	if not modernLayout and self:IsRetailHeaderActive()
		and self:LayoutLegacyGuildHeader(guildFrame, inset, header) then
		self:UpdateGuildFeatureBar()
		self:UpdateResponsiveLayout()
		return
	end

	-- Calculate row positions from Inset top (negative y = downward).
	-- Retail Guild uses the shared header Search/Filter/Sorter row, so this frame
	-- only owns the guild name, unified guild content and list.
	local guildNameHeight = guildFrame.GuildName and guildFrame.GuildName:GetStringHeight() or 14
	local listInsetTop = -4 - guildNameHeight - 8
	guildFrame.GuildName:ClearAllPoints()
	guildFrame.GuildName:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -4)
	guildFrame.MemberCount:ClearAllPoints()
	guildFrame.MemberCount:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -6, -4)

	guildFrame.ListInset:ClearAllPoints()
	guildFrame.ListInset:SetPoint("TOPLEFT", inset, "TOPLEFT", 0, listInsetTop)
	guildFrame.ListInset:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
	self:UpdateGuildFeatureBar()

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

	local professionLines = {}
	for slot = 1, 2 do
		local professionName = member["profession" .. slot .. "Name"]
		if professionName and professionName ~= "" then
			professionLines[#professionLines + 1] = professionName
		end
	end
	if #professionLines > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(table.concat(professionLines, "  •  "), 0.75, 0.75, 0.75, true)
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

function GuildFrame:IsInGuild()
	local provider = GetGuildRosterData()
	return provider and provider.IsInGuild and provider:IsInGuild() == true or false
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

	local scrollBarReserve = self:GetRetailScrollBarGeometry()
	local scrollbarAndPadding = scrollBarReserve + 10
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
	local rightReserve = STATUS_ICON_SIZE + (self.professionFilterID and 38 or 14)
	if button.nameText then
		button.nameText:ClearAllPoints()
		button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", nameOffset, -4)
		button.nameText:SetWidth(math.max(width - nameOffset - rightReserve, 40))
	end
	if button.statusIcon then
		button.statusIcon:ClearAllPoints()
		button.statusIcon:SetPoint("TOPRIGHT", button, "TOPRIGHT", self.professionFilterID and -27 or -7, -7)
	end
	if button.rankText then
		button.rankText:ClearAllPoints()
		button.rankText:SetPoint("TOPLEFT", button, "TOPLEFT", nameOffset, -21)
		button.rankText:SetWidth(math.max(width - nameOffset - rightReserve, 40))
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
		-- Every visit to the Guild tab starts with the guild message.
		GF.headerDetailMode = "motd"
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
