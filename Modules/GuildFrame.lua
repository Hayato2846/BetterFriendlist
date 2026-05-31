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
local BUTTON_HEIGHT = 24
local CLASS_ICON_SIZE = 18
local CLASS_ICON_OFFSET = 4
local NAME_OFFSET_WITH_ICON = 26
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

-- Zebra stripe colors (same as WhoFrame)
local ZEBRA_EVEN_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.3 }
local ZEBRA_ODD_COLOR = { r = 0, g = 0, b = 0, a = 0 }

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
	ApplyBetterFriendlistSmallButtonFonts(frame.OpenBlizzardGuildButton)
	ApplyBetterFriendlistSmallButtonFonts(frame.RefreshButton)
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
		return
	end

	local provider = GetGuildRosterData()
	if not (provider and provider.IsInGuild and provider:IsInGuild()) then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		return
	end

	if not (provider and provider.CollectRoster) then
		self.guildMembers = {}
		self.totalMembers = 0
		self.onlineMembers = 0
		return
	end

	local members, counts = provider:CollectRoster()
	self.guildMembers = members
	self.totalMembers = counts and counts.total or #members
	self.onlineMembers = counts and counts.online or 0
	rosterDirty = false
end

-- ========================================
-- Filter & Search
-- ========================================

function GuildFrame:SetFilter(mode)
	self.filterMode = mode
	local DB = GetDB()
	if DB and DB.Set then
		DB:Set("guildTabFilterMode", mode)
	end
	self:RefreshHeaderControls()
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
	if self.sortMode == mode and not skipToggle then
		-- Toggle reverse on same column
		self.sortReversed[mode] = not self.sortReversed[mode]
	else
		self.sortMode = mode
	end
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
		return self.displayList
	end

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
	if not self:IsEnabled() then
		self.guildMembers = {}
		self.displayList = {}
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

function GuildFrame:ApplyV1Visibility(frame)
	if not frame then
		return
	end

	if frame.ILvlHeader then
		frame.ILvlHeader:Hide()
		frame.ILvlHeader:Disable()
	end
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

			-- Bottom buttons: align left edge to Inset (pixel-perfect)
			frame.OpenBlizzardGuildButton:ClearAllPoints()
			frame.OpenBlizzardGuildButton:SetPoint("TOPLEFT", inset, "BOTTOMLEFT", 0, -4)
			-- RefreshButton chains from OpenBlizzardGuildButton via XML

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
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", -18, 2)

	-- ScrollBar uses XML anchors (ScrollBox TOPRIGHT + (0, 0))

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
	ApplyDefaultSlugToFontString(button.nameText)
	button.nameText:SetPoint("LEFT", button.classIcon, "RIGHT", 4, 0)
	button.nameText:SetJustifyH("LEFT")

	-- Status icon (Blizzard AFK/DND/Mobile textures; hidden for online & offline)
	button.statusIcon = button:CreateTexture(nil, "OVERLAY")
	button.statusIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	button.statusIcon:Hide()

	-- Rank text
	button.rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.rankText)
	button.rankText:SetJustifyH("LEFT")
	button.rankText:SetTextColor(0.6, 0.6, 0.6)
	button.rankText:SetMaxLines(1)
	button.rankText:SetWordWrap(false)
	button.rankText:SetNonSpaceWrap(false)

	-- Level text
	button.levelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.levelText)
	button.levelText:SetJustifyH("CENTER")

	-- Zone text
	button.zoneText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.zoneText)
	button.zoneText:SetJustifyH("LEFT")
	button.zoneText:SetMaxLines(1)
	button.zoneText:SetWordWrap(false)

	-- Item Level text
	button.ilvlText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(button.ilvlText)
	button.ilvlText:SetJustifyH("RIGHT")
	button.ilvlText:SetTextColor(GetAccentColor(1, 0.82, 0, 1))

	-- Highlight texture
	button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(1, 1, 1, 0.1)

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
		button.bg:SetColorTexture(r, g, b, 0.18)
	elseif dataIndex % 2 == 0 then
		button.bg:SetColorTexture(ZEBRA_EVEN_COLOR.r, ZEBRA_EVEN_COLOR.g, ZEBRA_EVEN_COLOR.b, ZEBRA_EVEN_COLOR.a)
	else
		button.bg:SetColorTexture(ZEBRA_ODD_COLOR.r, ZEBRA_ODD_COLOR.g, ZEBRA_ODD_COLOR.b, ZEBRA_ODD_COLOR.a)
	end

	-- Class icon
	local classCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.classFile]
	if ShouldShowClassIcons() and classCoords and button.classIcon then
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

	-- Item Level
	if button.ilvlText then
		button.ilvlText:SetTextColor(GetAccentColor(1, 0.82, 0, 1))
		local ilvl = member.itemLevel or 0
		if ilvl > 0 then
			button.ilvlText:SetText(tostring(math.floor(ilvl)))
			button.ilvlText:SetAlpha(member.online and 1.0 or 0.55)
			button.ilvlText:Show()
		else
			button.ilvlText:SetText("-")
			button.ilvlText:SetAlpha(member.online and 0.55 or 0.35)
			button.ilvlText:Show()
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

function GuildFrame:RefreshHeaderControls()
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	if not header or BFL.IsClassic then
		return
	end

	local active = self:IsRetailHeaderActive()
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

	guildFrame.InfoEditButton = CreateEditButton(
		"BFL_GuildInfoEditButton",
		(BFL.L and BFL.L.GUILD_ACTION_EDIT_INFO) or "Guild Info",
		function()
		local actions = GetGuildActions()
		if actions and actions.EditGuildInfo then
			actions:EditGuildInfo()
		end
	end)
	guildFrame.InfoEditButton:SetPoint("LEFT", guildFrame.GuildName, "RIGHT", 5, 0)

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
		if CanEditGuildInfo and CanEditGuildInfo() == true then
			guildFrame.InfoEditButton:Show()
		else
			guildFrame.InfoEditButton:Hide()
		end
	end

	if guildFrame.MOTDEditButton then
		if CanEditMOTD and CanEditMOTD() == true and guildFrame.MOTDText and guildFrame.MOTDText:IsShown() then
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

	-- NameHeader follows ListInset via XML (TOPLEFT + 4, 25)
	-- Sub-headers chain from NameHeader via XML
	-- ScrollBox/ScrollBar follow ListInset via Lua OnLoad anchors
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
-- Open Blizzard Guild Frame
-- ========================================

function GuildFrame:OpenBlizzardGuildUI(memberIndex)
	local actions = GetGuildActions()
	if actions and actions.OpenBlizzardGuildUI then
		actions:OpenBlizzardGuildUI()
		return
	end

	if BFL:IsActionRestricted() then
		return
	end

	local toggle = ToggleGuildFrame or GuildFrame_Toggle
	if not toggle then
		return
	end
	if BFL.HasSecretValues and securecallfunction then
		pcall(securecallfunction, toggle)
	else
		pcall(toggle)
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
-- Column Width Management (Responsive)
-- ========================================

function GuildFrame:UpdateResponsiveLayout()
	if not self:IsEnabled() then
		return
	end

	local frame = BetterFriendsFrame
	if not frame or not frame.GuildFrame then return end

	local guildFrame = frame.GuildFrame
	local frameWidth = (guildFrame.ListInset and guildFrame.ListInset:GetWidth()) or frame:GetWidth()

	-- Cache check
	local roundedWidth = math.floor(frameWidth + 0.5)
	if self._lastLayoutWidth == roundedWidth then return end
	self._lastLayoutWidth = roundedWidth

	local scrollbarAndPadding = 28
	local effectiveWidth = math.max((frameWidth or 360) - scrollbarAndPadding, 220)

	local ilvlWidth = 0
	local remaining = effectiveWidth - ilvlWidth
	local nameWidth = math.floor(remaining * 0.35)
	local rankWidth = math.floor(remaining * 0.22)
	local levelWidth = math.floor(remaining * 0.08)
	local zoneWidth = remaining - nameWidth - rankWidth - levelWidth

	nameWidth = math.max(nameWidth, 82)
	rankWidth = math.max(rankWidth, 52)
	levelWidth = math.max(levelWidth, 28)
	zoneWidth = math.max(zoneWidth, 54)

	local totalWidth = nameWidth + rankWidth + levelWidth + zoneWidth
	if totalWidth > remaining then
		local overflow = totalWidth - remaining
		local zoneShrink = math.min(overflow, math.max(zoneWidth - 54, 0))
		zoneWidth = zoneWidth - zoneShrink
		overflow = overflow - zoneShrink
		local rankShrink = math.min(overflow, math.max(rankWidth - 48, 0))
		rankWidth = rankWidth - rankShrink
		overflow = overflow - rankShrink
		if overflow > 0 then
			nameWidth = math.max(nameWidth - overflow, 70)
		end
	end

	self.columnWidths = {
		name = nameWidth,
		rank = rankWidth,
		level = levelWidth,
		zone = zoneWidth,
		ilvl = ilvlWidth,
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
	if guildFrame.ILvlHeader then
		guildFrame.ILvlHeader:Hide()
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
	local showClassIcons = ShouldShowClassIcons()
	local nameOffset = showClassIcons and NAME_OFFSET_WITH_ICON or 8

	-- Name column: class icon + name text fill the Name header width
	-- Reserve space for status icon at the right edge of the name cell
	local statusIconReserve = STATUS_ICON_SIZE + 4
	if button.classIcon then
		button.classIcon:ClearAllPoints()
		if showClassIcons then
			button.classIcon:SetPoint("LEFT", button, "LEFT", CLASS_ICON_OFFSET, 0)
		else
			button.classIcon:Hide()
		end
	end
	if button.nameText then
		button.nameText:ClearAllPoints()
		button.nameText:SetPoint("LEFT", button, "LEFT", nameOffset, 0)
		button.nameText:SetWidth(math.max(w.name - nameOffset - 2 - statusIconReserve, 24))
	end
	-- Status icon: sits at the right edge of the name column (before rank)
	if button.statusIcon then
		button.statusIcon:ClearAllPoints()
		button.statusIcon:SetPoint("RIGHT", button, "LEFT", w.name - 4, 0)
	end
	-- Rank, Level, Zone: positioned at cumulative header offsets from button LEFT
	if button.rankText then
		button.rankText:ClearAllPoints()
		button.rankText:SetPoint("LEFT", button, "LEFT", w.name, 0)
		button.rankText:SetWidth(w.rank - 4)
	end
	if button.levelText then
		button.levelText:ClearAllPoints()
		button.levelText:SetPoint("LEFT", button, "LEFT", w.name + w.rank, 0)
		button.levelText:SetWidth(w.level - 4)
	end
	if button.zoneText then
		button.zoneText:ClearAllPoints()
		button.zoneText:SetPoint("LEFT", button, "LEFT", w.name + w.rank + w.level, 0)
		button.zoneText:SetWidth(w.zone - 4)
	end
	-- iLvl: rightmost column
	if button.ilvlText then
		button.ilvlText:ClearAllPoints()
		if (w.ilvl or 0) > 0 then
			button.ilvlText:SetPoint("LEFT", button, "LEFT", w.name + w.rank + w.level + w.zone, 0)
			button.ilvlText:SetWidth(w.ilvl - 4)
			button.ilvlText:Show()
		else
			button.ilvlText:Hide()
		end
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

	-- Rank dropdown label
	panel.rankLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ApplyDefaultSlugToFontString(panel.rankLabel)
	panel.rankLabel:SetPoint("TOPLEFT", panel.ilvlText, "BOTTOMLEFT", 0, -10)
	panel.rankLabel:SetText((L and L.GUILD_INFO_RANK) or "Rank")
	panel.rankLabel:SetTextColor(0.7, 0.7, 0.7)

	-- Rank dropdown (uses non-protected SetGuildMemberRank)
	panel.rankDropdown = CreateFrame("Frame", "BFL_GuildMemberRankDropdown", panel, "UIDropDownMenuTemplate")
	panel.rankDropdown:SetPoint("TOPLEFT", panel.rankLabel, "BOTTOMLEFT", -16, -2)
	UIDropDownMenu_SetWidth(panel.rankDropdown, 200)

	-- Divider before notes
	panel.divider2 = CreatePanelDivider(panel, panel.rankDropdown, -4)

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

-- Populate/refresh the rank dropdown based on the given member and current
-- player permissions. Uses SetGuildMemberRank (non-protected).
function GuildFrame:_RefreshRankDropdown(member)
	return
end

function GuildFrame:_RefreshRankDropdown_Legacy(member)
	local panel = self._infoPanel
	if not panel or not panel.rankDropdown then return end

	panel._pendingRankIndex = member.rankIndex

	local canPromote = _G.CanGuildPromote and _G.CanGuildPromote() or false
	local canDemote = _G.CanGuildDemote and _G.CanGuildDemote() or false
	local canChange = canPromote or canDemote

	UIDropDownMenu_Initialize(panel.rankDropdown, function(dropdown, level)
		local info = UIDropDownMenu_CreateInfo()
		local numRanks = (_G.GuildControlGetNumRanks and _G.GuildControlGetNumRanks()) or 0
		for rankIdx = 0, numRanks - 1 do
			local rankName = _G.GuildControlGetRankName and _G.GuildControlGetRankName(rankIdx) or ""
			if rankName and rankName ~= "" then
				info = UIDropDownMenu_CreateInfo()
				info.text = format("%d. %s", rankIdx + 1, rankName)
				info.value = rankIdx
				info.checked = (rankIdx == panel._pendingRankIndex)
				info.func = function(self_info)
					panel._pendingRankIndex = self_info.value
					UIDropDownMenu_SetSelectedValue(panel.rankDropdown, self_info.value)
					UIDropDownMenu_SetText(panel.rankDropdown, self_info.text)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end)

	UIDropDownMenu_SetSelectedValue(panel.rankDropdown, member.rankIndex or 0)
	local currentRankName = _G.GuildControlGetRankName and _G.GuildControlGetRankName(member.rankIndex or 0) or ""
	UIDropDownMenu_SetText(panel.rankDropdown, format("%d. %s", (member.rankIndex or 0) + 1, currentRankName))

	if canChange then
		UIDropDownMenu_EnableDropDown(panel.rankDropdown)
	else
		UIDropDownMenu_DisableDropDown(panel.rankDropdown)
	end
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

	-- Public note (editable if permitted)
	panel.pubNote:SetText(member.note or "")
	local canEditPub = CanEditPublicNote and CanEditPublicNote() or false
	panel.pubNote:SetEnabled(canEditPub)
	if not canEditPub then
		panel.pubNote:SetTextColor(0.5, 0.5, 0.5)
	else
		panel.pubNote:SetTextColor(1, 1, 1)
	end

	-- Officer note (editable/viewable if permitted)
	local canViewOff = C_GuildInfo and C_GuildInfo.CanViewOfficerNote
		and C_GuildInfo.CanViewOfficerNote() or false
	local canEditOff = CanEditOfficerNote and CanEditOfficerNote() or false
	if canViewOff then
		panel.offNote:SetText(member.officerNote or "")
		panel.offNote:Show()
		panel.offLabel:Show()
		panel.offNote:SetEnabled(canEditOff)
		if not canEditOff then
			panel.offNote:SetTextColor(0.5, 0.5, 0.5)
		else
			panel.offNote:SetTextColor(0.5, 1, 0.5)
		end
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

	if BFL:IsActionRestricted() then
		BFL:DebugPrint("Cannot save guild changes: combat restriction active")
		return
	end

	-- Public note
	if CanEditPublicNote and CanEditPublicNote() and GuildRosterSetPublicNote then
		local newPub = panel.pubNote:GetText() or ""
		if newPub ~= (member.note or "") and member.guildIndex then
			GuildRosterSetPublicNote(member.guildIndex, newPub)
		end
	end

	-- Officer note
	if CanEditOfficerNote and CanEditOfficerNote() and GuildRosterSetOfficerNote then
		local newOff = panel.offNote:GetText() or ""
		if newOff ~= (member.officerNote or "") and member.guildIndex then
			GuildRosterSetOfficerNote(member.guildIndex, newOff)
		end
	end

	-- Rank change via non-protected SetGuildMemberRank(playerIndex, newRankIndex)
	local newRank = panel._pendingRankIndex
	if newRank and newRank ~= member.rankIndex and member.guildIndex and _G.SetGuildMemberRank then
		local canPromote = _G.CanGuildPromote and _G.CanGuildPromote() or false
		local canDemote = _G.CanGuildDemote and _G.CanGuildDemote() or false
		local isPromoting = newRank < member.rankIndex
		if (isPromoting and canPromote) or ((not isPromoting) and canDemote) then
			pcall(_G.SetGuildMemberRank, member.guildIndex, newRank)
		end
	end

	-- Nickname (local)
	local DB = GetDB()
	if DB and DB.SetGuildNickname then
		local newNick = panel.nickBox:GetText() or ""
		DB:SetGuildNickname(member.fullName, newNick ~= "" and newNick or nil)
	end

	self:HideMemberInfoPanel()
	-- Request refresh so new notes appear in tooltips
	self:RequestRosterUpdate()
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
		if frame.OpenBlizzardGuildButton and BFL.L then
			frame.OpenBlizzardGuildButton:SetText(BFL.L.GUILD_ACTIONS_MENU or "Guild Actions")
			ApplyDefaultSlugToButton(frame.OpenBlizzardGuildButton)
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

function BFL_GuildFrame_OpenBlizzardGuild(button)
	local actions = BFL:GetModule("GuildActions")
	if actions and actions.ShowGuildActionsMenu then
		local owner = button
			or (BetterFriendsFrame and BetterFriendsFrame.GuildFrame and BetterFriendsFrame.GuildFrame.OpenBlizzardGuildButton)
			or UIParent
		actions:ShowGuildActionsMenu(owner)
		return
	end
	local GF = BFL:GetModule("GuildFrame")
	if GF then GF:OpenBlizzardGuildUI() end
end

function BFL_GuildFrame_RefreshRoster()
	local GF = BFL:GetModule("GuildFrame")
	if GF and GF:IsEnabled() then
		local success = GF:RequestRosterUpdate()
		if not success then
			BFL:DebugPrint("Guild roster refresh throttled (10s cooldown)")
		end
	end
end
