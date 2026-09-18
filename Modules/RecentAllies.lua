-- Modules/RecentAllies.lua
-- Recent Allies System Module
-- Manages the recent allies list, data provider, and player interactions

local ADDON_NAME, BFL = ...

-- Register Module
local RecentAllies = BFL:RegisterModule("RecentAllies", {})

local function IsModernSocialUIActive()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() or false
end

local function SetLegacyPartyButtonTextures(partyButton)
	local textureFile = "Interface\\FriendsFrame\\TravelPass-Invite"
	local textures = {
		{ partyButton:GetNormalTexture(), 0.01562500, 0.39062500, 0.27343750, 0.52343750 },
		{ partyButton:GetPushedTexture(), 0.42187500, 0.79687500, 0.27343750, 0.52343750 },
		{ partyButton:GetDisabledTexture(), 0.01562500, 0.39062500, 0.00781250, 0.25781250 },
		{ partyButton:GetHighlightTexture(), 0.42187500, 0.79687500, 0.00781250, 0.25781250 },
	}
	for _, textureInfo in ipairs(textures) do
		local texture = textureInfo[1]
		if texture then
			texture:SetTexture(textureFile)
			texture:SetTexCoord(textureInfo[2], textureInfo[3], textureInfo[4], textureInfo[5])
		end
	end
end

local function SetModernPartyButtonAtlas(texture, atlas)
	if not texture then
		return
	end

	-- The shared entry template starts with cropped TravelPass texture coordinates.
	-- Reset them while applying the SocialCard atlas or only a thin atlas slice is shown.
	if texture.SetAtlas then
		local applied = pcall(texture.SetAtlas, texture, atlas, false, nil, true)
		if applied then
			return
		end
	end

	BFL.SetTextureOrAtlas(texture, atlas)
end

function RecentAllies:ApplyEntryLayout(button, stateData)
	local modern = IsModernSocialUIActive()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local _, themed = FriendsUI and FriendsUI.GetModernThemeColors and FriendsUI:GetModernThemeColors()
	local stateContainer = button.StateIconContainer
	local pinDisplay = stateContainer.PinDisplay
	local requestDisplay = stateContainer.FriendRequestPendingDisplay
	local characterData = button.CharacterData
	local classText = characterData.Class
	local mostRecentInteraction = characterData.MostRecentInteraction
	local partyButton = button.PartyButton
	partyButton.BFL_DarkForceFlatButton = modern and themed and true or nil

	if not modern then
		button.bflModernRecentAllyLayout = nil
		stateContainer:Show()
		stateContainer:ClearAllPoints()
		stateContainer:SetSize(32, 20)
		stateContainer:SetPoint("TOPRIGHT", button, "TOPRIGHT", -24, 0)
		requestDisplay:ClearAllPoints()
		requestDisplay:SetSize(13, 13)
		requestDisplay:SetPoint("LEFT")
		requestDisplay.Icon:ClearAllPoints()
		requestDisplay.Icon:SetAllPoints()
		pinDisplay:ClearAllPoints()
		pinDisplay:SetSize(15, 15)
		pinDisplay:SetPoint("RIGHT")
		characterData:ClearAllPoints()
		characterData:SetPoint("TOPLEFT", button.OnlineStatusIcon, "TOPRIGHT", 2, -2)
		characterData:SetPoint("RIGHT", stateContainer, "LEFT", -2, 0)
		classText:ClearAllPoints()
		classText:SetPoint("LEFT", characterData.LevelDivider, "RIGHT", 3, -1)
		classText:SetPoint("RIGHT")
		mostRecentInteraction:ClearAllPoints()
		mostRecentInteraction:SetPoint("TOPLEFT", characterData.Name, "BOTTOMLEFT", 0, -1)
		mostRecentInteraction:SetPoint("TOPRIGHT", classText, "BOTTOMRIGHT", 0, -1)
		partyButton:SetSize(24, 32)
		partyButton:ClearAllPoints()
		partyButton:SetPoint("RIGHT")
		if partyButton.ActionIcon then
			partyButton.ActionIcon:Hide()
		end
		SetLegacyPartyButtonTextures(partyButton)
		return
	end

	button.bflModernRecentAllyLayout = true
	local pinShown = stateData.pinExpirationDate ~= nil
	local requestShown = stateData.friendRequestSentThisSession or stateData.hasFriendRequestPending or false
	local stateWidth = (pinShown and 18 or 0) + (requestShown and 18 or 0)
	if pinShown and requestShown then
		stateWidth = stateWidth + 3
	end

	pinDisplay:ClearAllPoints()
	pinDisplay:SetSize(18, 18)
	pinDisplay:SetPoint("LEFT")
	requestDisplay:ClearAllPoints()
	requestDisplay:SetSize(18, 18)
	if pinShown then
		requestDisplay:SetPoint("LEFT", pinDisplay, "RIGHT", 3, 0)
	else
		requestDisplay:SetPoint("LEFT", stateContainer, "LEFT", 0, 0)
	end
	requestDisplay.Icon:ClearAllPoints()
	requestDisplay.Icon:SetPoint("TOPLEFT", 1, -1)
	requestDisplay.Icon:SetPoint("BOTTOMRIGHT", -1, 1)

	characterData:ClearAllPoints()
	characterData:SetPoint("TOPLEFT", button.OnlineStatusIcon, "TOPRIGHT", 2, -2)
	characterData:SetPoint("RIGHT", partyButton, "LEFT", -5, 0)

	local nameWidth = characterData.Name:GetWidth() or 0
	local levelWidth = characterData.Level:GetWidth() or 0
	local usedBeforeClass = nameWidth + levelWidth + 29
	local availableClassWidth = math.max(
		1,
		(characterData:GetWidth() or 0) - usedBeforeClass - stateWidth - (stateWidth > 0 and 2 or 0)
	)
	classText:ClearAllPoints()
	classText:SetPoint("LEFT", characterData.LevelDivider, "RIGHT", 3, -1)
	classText:SetWidth(math.min(classText:GetUnboundedStringWidth(), availableClassWidth))

	stateContainer:ClearAllPoints()
	stateContainer:SetSize(stateWidth, 18)
	stateContainer:SetPoint("LEFT", classText, "RIGHT", stateWidth > 0 and 2 or 0, 0)
	stateContainer:SetShown(stateWidth > 0)

	mostRecentInteraction:ClearAllPoints()
	mostRecentInteraction:SetPoint("TOPLEFT", characterData.Name, "BOTTOMLEFT", 0, -1)
	mostRecentInteraction:SetPoint("RIGHT", characterData, "RIGHT")

	partyButton:SetSize(34, 34)
	partyButton:ClearAllPoints()
	partyButton:SetPoint("RIGHT", button, "RIGHT", -4, 0)
	SetModernPartyButtonAtlas(partyButton:GetNormalTexture(), "common-button-tertiary-square-normal")
	SetModernPartyButtonAtlas(partyButton:GetPushedTexture(), "common-button-tertiary-square-pressed")
	SetModernPartyButtonAtlas(partyButton:GetDisabledTexture(), "common-button-tertiary-square-normal")
	SetModernPartyButtonAtlas(partyButton:GetHighlightTexture(), "common-button-tertiary-square-normal")
	if not partyButton.ActionIcon then
		partyButton.ActionIcon = partyButton:CreateTexture(nil, "OVERLAY")
		partyButton.ActionIcon:SetPoint("CENTER")
	end
	local partyAtlas = stateData.isOnline
		and "friends-icon-friendsAvailable"
		or "friends-icon-friendsAvailable-dis"
	BFL.SetTextureOrAtlas(partyButton.ActionIcon, partyAtlas, nil, true)
	partyButton.ActionIcon:Show()
end

-- ========================================
-- Module Dependencies
-- ========================================

-- No direct dependencies, uses global WoW API

-- ========================================
-- Local Variables
-- ========================================

-- Recent Allies List Events
local RecentAlliesListEvents = {
	"RECENT_ALLIES_CACHE_UPDATE",
}

-- Current search text for filtering
RecentAllies.searchText = ""
RecentAllies.selectedFilters = {}

local STATUS_FILTER_OPTIONS = {
	{ id = "online", field = "isOnline", global = "SOCIAL_UI_PRESENCE_TYPE_LABEL_ONLINE", fallback = "FILTER_ONLINE" },
	{ id = "away", field = "isAFK", global = "SOCIAL_UI_PRESENCE_TYPE_LABEL_AWAY", fallback = "STATUS_AWAY" },
	{ id = "busy", field = "isDND", global = "SOCIAL_UI_PRESENCE_TYPE_LABEL_BUSY", fallback = "STATUS_BUSY" },
	{ id = "offline", field = "isOffline", global = "SOCIAL_UI_PRESENCE_TYPE_LABEL_OFFLINE", fallback = "FILTER_OFFLINE" },
}

local INTEREST_FILTER_OPTIONS = {
	{ id = "professions", enum = "Professions", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_PROFESSIONS", fallback = "FRIEND_TAGS_BLIZZARD_PROFESSIONS" },
	{ id = "pvp", enum = "PvP", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_PVP", fallback = "FRIEND_TAGS_BLIZZARD_PVP" },
	{ id = "raiding", enum = "Raiding", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_RAIDING", fallback = "FRIEND_TAGS_BLIZZARD_RAIDING" },
	{ id = "dungeons", enum = "Dungeons", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_DUNGEONS", fallback = "FRIEND_TAGS_BLIZZARD_DUNGEONS" },
	{ id = "delves", enum = "Delves", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_DELVE", fallback = "FRIEND_TAGS_BLIZZARD_DELVES" },
	{ id = "questing", enum = "Questing", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_QUESTING", fallback = "FRIEND_TAGS_BLIZZARD_QUESTING" },
	-- Build 68675's generated enum has only six values. Keep this dynamic so a
	-- later PTR can expose RolePlaying without making the current menu error.
	{ id = "roleplaying", enum = "RolePlaying", global = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_ROLEPLAYING", fallback = "FRIEND_TAGS_BLIZZARD_ROLEPLAYING" },
}

local function GetFilterOptionLabel(option)
	local legacyLabels = {
		online = FRIENDS_LIST_ONLINE,
		offline = FRIENDS_LIST_OFFLINE,
		away = CHAT_FLAG_AFK,
		busy = CHAT_FLAG_DND,
	}
	return option.label or _G[option.global] or BFL.L[option.fallback] or legacyLabels[option.id] or option.id
end

local function CanUseNativeRecentAlliesSearch()
	return BFL.IsMainline and C_RecentAllies and type(C_RecentAllies.SearchRecentAllies) == "function"
end

function RecentAllies.ResolveSearchSchema(enumRoot, recentAlliesAPI)
	enumRoot = type(enumRoot) == "table" and enumRoot or {}
	recentAlliesAPI = type(recentAlliesAPI) == "table" and recentAlliesAPI or {}
	if type(enumRoot.RecentAlliesInteractionCategoryFilter) == "table" then
		return {
			kind = "interactionCategoryFilters",
			field = "interactionCategoryFilters",
			enum = enumRoot.RecentAlliesInteractionCategoryFilter,
			isSupported = recentAlliesAPI.IsInteractionCategoryFilterSupportedForCurrentGameType,
		}
	end
	if type(enumRoot.RecentAlliesFriendTag) == "table" then
		return {
			kind = "interests",
			field = "interests",
			enum = enumRoot.RecentAlliesFriendTag,
		}
	end
	return nil
end

function RecentAllies.IsSearchFilterValueSupported(schema, enumValue)
	if not schema or enumValue == nil then
		return false
	end
	if type(schema.isSupported) ~= "function" then
		return true
	end
	local ok, supported = pcall(schema.isSupported, enumValue)
	return ok and not BFL:IsSecret(supported) and supported == true
end

function RecentAllies:GetSearchSchema()
	return self.ResolveSearchSchema(Enum, C_RecentAllies)
end

function RecentAllies:IsSystemEnabled()
	local evaluator = C_RecentAllies and (C_RecentAllies.IsSystemEnabled or C_RecentAllies.IsRecentAlliesEnabled)
	if type(evaluator) ~= "function" then
		return false
	end
	local ok, enabled = pcall(evaluator)
	return ok and not BFL:IsSecret(enabled) and enabled == true
end

function RecentAllies:IsDataReady()
	local evaluator = C_RecentAllies and C_RecentAllies.IsRecentAllyDataReady
	if type(evaluator) ~= "function" then
		return false
	end
	local ok, ready = pcall(evaluator)
	return ok and not BFL:IsSecret(ready) and ready == true
end

-- ========================================
-- Public API
-- ========================================

-- Initialize (called from ADDON_LOADED)
function RecentAllies:Initialize()
	-- Capability-gated Mainline feature (Midnight Standard and Forever).
	if not BFL.HasRecentAllies then
		-- BFL:DebugPrint("|cffffcc00BFL RecentAllies:|r Not available in Classic - module disabled")
		return
	end
	BFL:RegisterEventCallback("RECENT_ALLIES_SYSTEM_STATUS_UPDATED", function()
		self:OnSystemStatusUpdated()
	end, 20)
end

function RecentAllies:OnTextScaleUpdated()
	local frame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
	if frame and frame:IsShown() then
		self:Refresh(frame, ScrollBoxConstants.RetainScrollPosition)
	end
end

function RecentAllies:OnSystemStatusUpdated()
	local FriendsUI = BFL:GetModule("FriendsUI")
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		if FriendsUI then
			FriendsUI.navigationDirty = true
		end
		return
	end
	if FriendsUI then
		if FriendsUI:IsModernActive() then
			FriendsUI:RefreshNavigation()
		else
			local selectedSection = FriendsUI:GetSelectedSection()
			if not FriendsUI:IsSectionAvailable(selectedSection) then
				FriendsUI:SelectSection(FriendsUI:BuildAvailableSectionIDs()[1] or "friends")
			else
				FriendsUI:RestoreLegacyTabs(false)
			end
		end
	end

	local frame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
	if frame and frame:IsShown() then
		self:Refresh(frame, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- Initialize Recent Allies Frame (RecentAlliesListMixin:OnLoad)
function RecentAllies:OnLoad(frame)
	-- Capability-gated Mainline feature (Midnight Standard and Forever).
	if not BFL.HasRecentAllies then
		-- Show "Not Available" message for Classic users
		local notAvailableText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
		notAvailableText:SetPoint("CENTER")
		notAvailableText:SetText(BFL.L.RECENT_ALLIES_NOT_AVAILABLE)
		notAvailableText:SetTextColor(0.5, 0.5, 0.5)
		frame.UnavailableText = notAvailableText

		-- Hide ScrollBox elements if they exist
		if frame.ScrollBox then
			frame.ScrollBox:Hide()
		end
		if frame.ScrollBar then
			frame.ScrollBar:Hide()
		end
		if frame.LoadingSpinner then
			frame.LoadingSpinner:Hide()
		end
		return
	end

	-- Initialize ScrollBox with element factory
	local elementSpacing = 1
	local topPadding, bottomPadding, leftPadding, rightPadding = 0, 0, 0, 0
	local view = CreateScrollBoxListLinearView(topPadding, bottomPadding, leftPadding, rightPadding, elementSpacing)

	view:SetElementFactory(function(factory, elementData)
		if elementData.isHeader then
			factory("BetterRecentAlliesHeaderTemplate", function(header, data)
				RecentAllies:InitializeHeader(header, data)
			end)
		elseif elementData.isDivider then
			factory("BetterRecentAlliesDividerTemplate")
		else
			factory("BetterRecentAlliesEntryTemplate", function(button, elementData)
				RecentAllies:InitializeEntry(button, elementData)
				button:SetScript("OnClick", function(btn, mouseButtonName)
					if mouseButtonName == "LeftButton" then
						PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
						-- Selection behavior
						if frame.selectedEntry == btn then
							frame.selectedEntry = nil
							btn:UnlockHighlight()
						else
							if frame.selectedEntry then
								frame.selectedEntry:UnlockHighlight()
							end
							frame.selectedEntry = btn
							btn:LockHighlight()
						end
					elseif mouseButtonName == "RightButton" then
						RecentAllies:OpenMenu(btn)
					end
				end)
			end)
		end
	end)
	view:SetElementExtentCalculator(function(_, elementData)
		if elementData.isHeader then
			return 24
		elseif elementData.isDivider then
			return 16
		end
		return 53
	end)

	BFL.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)
	self.view = view
end

function RecentAllies:InitializeHeader(header, elementData)
	header.elementData = elementData
	header.Text:SetText(elementData.headerText or "")
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local palette, themed = FriendsUI and FriendsUI.GetModernThemeColors and FriendsUI:GetModernThemeColors()
	if IsModernSocialUIActive() and themed and palette then
		local surface = palette.control or palette.surface or { 0.035, 0.035, 0.04, 0.82 }
		header.Background:SetColorTexture(surface[1] or 0.035, surface[2] or 0.035, surface[3] or 0.04, surface[4] or 0.82)
		local accent = palette.accent or { 1, 0.82, 0, 1 }
		header.Text:SetTextColor(accent[1] or 1, accent[2] or 0.82, accent[3] or 0, accent[4] or 1)
	else
		header.Background:SetColorTexture(0.035, 0.035, 0.04, 0.82)
		header.Text:SetTextColor(1, 0.82, 0, 1)
	end
end

-- Show Recent Allies Frame (RecentAlliesListMixin:OnShow)
function RecentAllies:OnShow(frame)
	if not BFL.HasRecentAllies then
		self:Refresh(frame, ScrollBoxConstants and ScrollBoxConstants.DiscardScrollPosition)
		return
	end

	FrameUtil.RegisterFrameForEvents(frame, RecentAlliesListEvents)
	-- TryRequestRecentAlliesData is restricted to Blizzard UI. The client fills
	-- the cache and RECENT_ALLIES_CACHE_UPDATE drives our refresh when it is ready.

	-- Show spinner initially, will hide when data is ready
	self:SetLoadingSpinnerShown(frame, true)

	-- Refresh will check if data is ready and hide spinner if it is
	self:Refresh(frame, ScrollBoxConstants.DiscardScrollPosition)
end

-- Hide Recent Allies Frame (RecentAlliesListMixin:OnHide)
function RecentAllies:OnHide(frame)
	if BFL.HasRecentAllies then
		FrameUtil.UnregisterFrameForEvents(frame, RecentAlliesListEvents)
	end
end

-- Event handler (RecentAlliesListMixin:OnEvent)
function RecentAllies:OnEvent(frame, event, ...)
	if BFL.HasRecentAllies and event == "RECENT_ALLIES_CACHE_UPDATE" then
		self:Refresh(frame, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- Refresh the list (RecentAlliesListMixin:Refresh)
function RecentAllies:Refresh(frame, retainScrollPosition)
	local PreviewMode = BFL:GetModule("PreviewMode")
	local previewActive = PreviewMode
		and PreviewMode.IsComponentEnabled
		and PreviewMode:IsComponentEnabled("recent_allies")
		and PreviewMode.mockData
		and type(PreviewMode.mockData.recentAllies) == "table"
	if previewActive then
		self:SetLoadingSpinnerShown(frame, false)
		if frame.UnavailableText then
			frame.UnavailableText:Hide()
		end
		frame.ScrollBox:SetDataProvider(self:BuildDataProvider(), retainScrollPosition)
		return
	end

	-- Check if the Recent Allies system is enabled at all
	if not BFL.HasRecentAllies or not self:IsSystemEnabled() then
		self:SetLoadingSpinnerShown(frame, false)
		-- Show a message that the system is not available
		if not frame.UnavailableText then
			frame.UnavailableText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
			frame.UnavailableText:SetPoint("CENTER")
			frame.UnavailableText:SetText(BFL.L.RECENT_ALLIES_SYSTEM_UNAVAILABLE)
		end
		frame.UnavailableText:Show()
		return
	end

	-- Hide unavailable message if it exists
	if frame.UnavailableText then
		frame.UnavailableText:Hide()
	end

	-- Check if data is ready
	local dataReady = self:IsDataReady()
	self:SetLoadingSpinnerShown(frame, not dataReady)

	if not dataReady then
		-- Data will load automatically, and we'll get RECENT_ALLIES_CACHE_UPDATE event
		return
	end

	local dataProvider = self:BuildDataProvider()
	frame.ScrollBox:SetDataProvider(dataProvider, retainScrollPosition)
end

-- Build data provider (RecentAlliesListMixin:BuildRecentAlliesDataProvider)
function RecentAllies:HasActiveFilters()
	for _, selected in pairs(self.selectedFilters) do
		if selected then
			return true
		end
	end
	return false
end

function RecentAllies:GetFilterCount()
	local count = 0
	for _, selected in pairs(self.selectedFilters) do
		if selected then
			count = count + 1
		end
	end
	return count
end

function RecentAllies:GetFilterDropdownText()
	local count = self:GetFilterCount()
	local label = FILTER or "Filter"
	return count > 0 and string.format("%s (%d)", label, count) or label
end

function RecentAllies:GetAvailableInterestOptions(schema)
	local available = {}
	local explicitSchema = schema ~= nil
	schema = schema or self:GetSearchSchema()
	if not (schema and (explicitSchema or CanUseNativeRecentAlliesSearch())) then
		return available
	end
	for _, option in ipairs(INTEREST_FILTER_OPTIONS) do
		local enumValue = schema.enum[option.enum]
		if self.IsSearchFilterValueSupported(schema, enumValue) then
			local entry = {
				id = option.id,
				enum = option.enum,
				enumValue = enumValue,
				global = option.global,
				fallback = option.fallback,
			}
			if schema.kind == "interactionCategoryFilters"
				and RecentAlliesUtil
				and type(RecentAlliesUtil.GetLabelForInteractionCategoryFilter) == "function"
			then
				local ok, label = pcall(RecentAlliesUtil.GetLabelForInteractionCategoryFilter, enumValue)
				if ok and not BFL:IsSecret(label) and type(label) == "string" then
					entry.label = label
				end
			end
			available[#available + 1] = entry
		end
	end
	return available
end

function RecentAllies:SetFilterEnabled(filterID, enabled)
	self.selectedFilters[filterID] = enabled == true or nil
	if self.filterDropdown then
		BFL.RefreshDropdown(self.filterDropdown, self:GetFilterDropdownText())
	end
	local frame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
	if frame and frame:IsShown() then
		self:Refresh(frame, ScrollBoxConstants.DiscardScrollPosition)
	end
end

function RecentAllies:PopulateFilterMenu(rootDescription)
	rootDescription:SetTag("MENU_BFL_RECENT_ALLIES_FILTER")
	local statusTitle = rootDescription:CreateTitle(STATUS or FRIENDS_LIST_AVAILABLE or "Status")
	if statusTitle and statusTitle.AddInitializer and SocialUIUtil and SocialUIUtil.InitializeUserScaledDropdownTitle then
		statusTitle:AddInitializer(SocialUIUtil.InitializeUserScaledDropdownTitle)
	end
	for _, option in ipairs(STATUS_FILTER_OPTIONS) do
		local filterID = option.id
		local checkbox = rootDescription:CreateCheckbox(GetFilterOptionLabel(option), function()
			return self.selectedFilters[filterID] == true
		end, function()
			self:SetFilterEnabled(filterID, self.selectedFilters[filterID] ~= true)
		end)
		if checkbox and checkbox.SetCloseOnClick then
			checkbox:SetCloseOnClick(false)
		end
	end

	local interests = self:GetAvailableInterestOptions()
	if #interests > 0 then
		rootDescription:CreateDivider()
		local interestTitle = rootDescription:CreateTitle(BFL.L.FRIEND_TAGS_INTERESTS_SECTION or "Interests")
		if interestTitle and interestTitle.AddInitializer and SocialUIUtil and SocialUIUtil.InitializeUserScaledDropdownTitle then
			interestTitle:AddInitializer(SocialUIUtil.InitializeUserScaledDropdownTitle)
		end
		for _, option in ipairs(interests) do
			local filterID = option.id
			local checkbox = rootDescription:CreateCheckbox(GetFilterOptionLabel(option), function()
				return self.selectedFilters[filterID] == true
			end, function()
				self:SetFilterEnabled(filterID, self.selectedFilters[filterID] ~= true)
			end)
			if checkbox and checkbox.SetCloseOnClick then
				checkbox:SetCloseOnClick(false)
			end
		end
	end
end

function RecentAllies:InitializeFilterDropdown(dropdown)
	if not (dropdown and dropdown.SetupMenu) then
		return false
	end
	self.filterDropdown = dropdown
	dropdown:SetupMenu(function(_, rootDescription)
		self:PopulateFilterMenu(rootDescription)
	end)
	if dropdown.SetDefaultText then
		dropdown:SetDefaultText(self:GetFilterDropdownText())
	end
	if dropdown.SetSelectionText then
		dropdown:SetSelectionText(function()
			return self:GetFilterDropdownText()
		end)
	end
	return true
end

function RecentAllies:BuildSearchInfo(schema)
	local searchInfo = {
		searchText = self.searchText or "",
		isOnline = false,
		isAFK = false,
		isDND = false,
		isOffline = false,
	}
	for _, option in ipairs(STATUS_FILTER_OPTIONS) do
		if self.selectedFilters[option.id] then
			searchInfo[option.field] = true
		end
	end
	schema = schema or self:GetSearchSchema()
	if schema then
		searchInfo[schema.field] = {}
		for _, option in ipairs(self:GetAvailableInterestOptions(schema)) do
			if self.selectedFilters[option.id] then
				searchInfo[schema.field][#searchInfo[schema.field] + 1] = option.enumValue
			end
		end
	end
	return searchInfo
end

function RecentAllies:MatchesStatusFilters(ally)
	local hasStatusFilter = false
	local stateData = ally and ally.stateData or {}
	for _, option in ipairs(STATUS_FILTER_OPTIONS) do
		if self.selectedFilters[option.id] then
			hasStatusFilter = true
			local matches = option.field == "isOffline" and not stateData.isOnline or stateData[option.field] == true
			if matches then
				return true
			end
		end
	end
	return not hasStatusFilter
end

function RecentAllies:GetFilteredRecentAllies()
	local PreviewMode = BFL:GetModule("PreviewMode")
	if PreviewMode
		and PreviewMode.IsComponentEnabled
		and PreviewMode:IsComponentEnabled("recent_allies")
		and PreviewMode.mockData
		and type(PreviewMode.mockData.recentAllies) == "table"
	then
		return PreviewMode.mockData.recentAllies, false
	end

	if CanUseNativeRecentAlliesSearch() and (self:HasActiveFilters() or self.searchText ~= "") then
		local ok, result = pcall(C_RecentAllies.SearchRecentAllies, self:BuildSearchInfo())
		if ok and not BFL:IsSecret(result) and type(result) == "table" then
			return result, true
		end
	end
	if BFL.Compat and BFL.Compat.GetRecentAllies then
		return BFL.Compat.GetRecentAllies(), false
	end
	return {}, false
end

function RecentAllies:PartitionByPinAndLegacyState(recentAllies)
	local convertedLegacyFriends = {}
	local pinnedAllies = {}
	local unpinnedAllies = {}
	for _, ally in ipairs(recentAllies or {}) do
		local stateData = type(ally.stateData) == "table" and ally.stateData or {}
		local isPinned = stateData.pinExpirationDate ~= nil
		if isPinned and stateData.isConvertedLegacyFriend == true then
			convertedLegacyFriends[#convertedLegacyFriends + 1] = ally
		elseif isPinned then
			pinnedAllies[#pinnedAllies + 1] = ally
		else
			unpinnedAllies[#unpinnedAllies + 1] = ally
		end
	end
	return convertedLegacyFriends, pinnedAllies, unpinnedAllies
end

function RecentAllies:BuildDataProvider()
	-- Get recent allies (presorted by pin state, online status, most recent interaction, alphabetically)
	local recentAllies, usedNativeSearch = self:GetFilteredRecentAllies()

	-- Older clients retain BFL's accent-insensitive local fallback. Native 12.1
	-- search is authoritative for interests, which are absent from RecentAllyData.
	if not usedNativeSearch and (self.searchText ~= "" or self:HasActiveFilters()) then
		local compat = BFL.IntlCompat
		local searchNormalized = compat and compat.NormalizeForSearch and compat.NormalizeForSearch(self.searchText)
			or BFL:StripAccents(self.searchText)
		local filtered = {}
		for _, ally in ipairs(recentAllies) do
			local matchesText = self.searchText == "" or self:MatchesSearch(ally, searchNormalized)
			if matchesText and self:MatchesStatusFilters(ally) then
				filtered[#filtered + 1] = ally
			end
		end
		recentAllies = filtered
	end

	local convertedLegacyFriends, pinnedAllies, unpinnedAllies =
		self:PartitionByPinAndLegacyState(recentAllies)

	local dataProvider = CreateDataProvider()
	local function InsertGroup(allies, nativeFormat, fallbackLabel)
		if #allies == 0 then
			return
		end
		local onlineCount = 0
		for _, ally in ipairs(allies) do
			if type(ally.stateData) == "table" and ally.stateData.isOnline == true then
				onlineCount = onlineCount + 1
			end
		end
		local headerText
		if type(nativeFormat) == "string" then
			local ok, formatted = pcall(string.format, nativeFormat, onlineCount, #allies)
			headerText = ok and formatted or nil
		end
		headerText = headerText or string.format("%s (%d/%d)", fallbackLabel, onlineCount, #allies)
		dataProvider:Insert({ isHeader = true, headerText = headerText })
		for _, ally in ipairs(allies) do
			dataProvider:Insert(ally)
		end
	end

	InsertGroup(
		convertedLegacyFriends,
		_G.SOCIAL_UI_RECENT_ALLIES_VIEW_HEADER_LEGACY_FRIENDS,
		BFL.L.RECENT_ALLIES_GROUP_LEGACY
	)
	InsertGroup(pinnedAllies, _G.SOCIAL_UI_RECENT_ALLIES_VIEW_HEADER_PINNED, BFL.L.RECENT_ALLIES_GROUP_PINNED)
	InsertGroup(unpinnedAllies, _G.SOCIAL_UI_RECENT_ALLIES_VIEW_HEADER_UNPINNED, BFL.L.RECENT_ALLIES_GROUP_OTHER)

	return dataProvider
end

-- Check if a recent ally matches the search text (locale-aware on 12.1.5).
function RecentAllies:MatchesSearch(ally, searchNormalized)
	local characterData = ally.characterData
	local stateData = ally.stateData
	local interactionData = ally.interactionData

	-- Helper: use C_Intl when available and retain the accent-insensitive fallback.
	local function contains(text)
		if BFL.IsSecret and BFL:IsSecret(text) then
			return false
		end
		if text and text ~= "" then
			local compat = BFL.IntlCompat
			if compat and compat.Contains then
				return compat.Contains(text, searchNormalized)
			end
			return BFL:StripAccents(text):find(searchNormalized, 1, true) ~= nil
		end
		return false
	end

	-- Search across all relevant fields
	return contains(characterData.name)
		or contains(characterData.fullName)
		or contains(stateData.currentLocation)
		or contains(interactionData and interactionData.note)
		or (
			interactionData
			and interactionData.interactions
			and #interactionData.interactions > 0
			and interactionData.interactions[1]
			and contains(interactionData.interactions[1].description)
		)
end

-- Set search text and refresh the list
function RecentAllies:SetSearchText(text, skipRefresh)
	local newText = text or ""
	if self.searchText == newText then
		return
	end
	self.searchText = newText

	if skipRefresh then
		return
	end

	-- Refresh the list with the new search filter
	local frame = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
	if frame and frame:IsShown() then
		self:Refresh(frame, ScrollBoxConstants.DiscardScrollPosition)
	end
end

-- Set loading spinner visibility (RecentAlliesListMixin:SetLoadingSpinnerShown)
function RecentAllies:SetLoadingSpinnerShown(frame, shown)
	frame.LoadingSpinner:SetShown(shown)
	frame.ScrollBox:SetShown(not shown)
	frame.ScrollBar:SetShown(not shown)
end

-- Initialize a recent ally entry button (RecentAlliesEntryMixin:Initialize)
function RecentAllies:InitializeEntry(button, elementData)
	button.elementData = elementData

	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData

	-- Set online status icon
	local statusIcon = "Interface\\FriendsFrame\\StatusIcon-Offline"
	if stateData.isOnline then
		if stateData.isAFK then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Away"
		elseif stateData.isDND then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-DnD"
		else
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Online"
		end
	end
	button.OnlineStatusIcon:SetTexture(statusIcon)

	-- Update background color based on online status
	button.NormalTexture:Show()
	local backgroundColor = stateData.isOnline and FRIENDS_WOW_BACKGROUND_COLOR or FRIENDS_OFFLINE_BACKGROUND_COLOR
	button.NormalTexture:SetColorTexture(backgroundColor:GetRGBA())

	-- Set name in class color (Line 1, Part 1)
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	local nameColor
	if stateData.isOnline and classInfo then
		nameColor = GetClassColorObj(classInfo.classFile)
	else
		nameColor = FRIENDS_GRAY_COLOR
	end
	button.CharacterData.Name:SetText(nameColor:WrapTextInColorCode(characterData.name))
	button.CharacterData.Name:SetWidth(math.min(button.CharacterData.Name:GetUnboundedStringWidth(), 150))

	-- Set level (Line 1, Part 2)
	local levelColor = stateData.isOnline and NORMAL_FONT_COLOR or FRIENDS_GRAY_COLOR
	button.CharacterData.Level:SetText(levelColor:WrapTextInColorCode(characterData.level))
	button.CharacterData.Level:SetWidth(button.CharacterData.Level:GetUnboundedStringWidth())

	-- Class (Line 1, Part 3)
	if classInfo then
		local classColor = stateData.isOnline and GetClassColorObj(classInfo.classFile) or FRIENDS_GRAY_COLOR
		button.CharacterData.Class:SetText(classColor:WrapTextInColorCode(classInfo.className))
	else
		button.CharacterData.Class:SetText("")
	end

	-- Update divider colors
	if button.CharacterData.Dividers then
		for _, divider in ipairs(button.CharacterData.Dividers) do
			if divider.SetTextColor then
				divider:SetTextColor(levelColor:GetRGB())
			else
				divider:SetVertexColor(levelColor:GetRGB())
			end
		end
	end

	-- Set most recent interaction (Line 2)
	local mostRecentInteraction = interactionData.interactions
		and #interactionData.interactions > 0
		and interactionData.interactions[1]
	if mostRecentInteraction then
		button.CharacterData.MostRecentInteraction:SetText(mostRecentInteraction.description or "")
	else
		button.CharacterData.MostRecentInteraction:SetText("")
	end

	-- Set location (Line 3)
	button.CharacterData.Location:SetText(stateData.currentLocation or "")

	-- Update state icons
	button.StateIconContainer.PinDisplay:SetShown(stateData.pinExpirationDate ~= nil)
	if stateData.pinExpirationDate then
		-- Check if pin is nearing expiration
		local remainingDays = (stateData.pinExpirationDate - GetServerTime()) / SECONDS_PER_DAY
		local isNearingExpiration = remainingDays <= 7
		local atlas
		if IsModernSocialUIActive() then
			atlas = stateData.isOnline
				and (isNearingExpiration and "friendslist-recentallies-pin" or "friends-icon-pinned")
				or "friends-icon-pinned-dis"
		else
			atlas = isNearingExpiration
				and "friendslist-recentallies-pin"
				or "friendslist-recentallies-pin-yellow"
		end
		BFL.SetTextureOrAtlas(button.StateIconContainer.PinDisplay.Icon, atlas)
	end

	-- Field renamed in 12.0.5: hasFriendRequestPending -> friendRequestSentThisSession
	button.StateIconContainer.FriendRequestPendingDisplay:SetShown(stateData.friendRequestSentThisSession or stateData.hasFriendRequestPending or false)
	self:ApplyEntryLayout(button, stateData)

	-- Enable/disable party button based on online status
	button.PartyButton:SetEnabled(stateData.isOnline)

	-- Setup party button click handler
	button.PartyButton:SetScript("OnClick", function()
		if characterData and characterData.fullName and BFL.InviteUnit then
			BFL.InviteUnit(characterData.fullName)
		end
	end)

	-- Setup party button tooltip
	button.PartyButton:SetScript("OnEnter", function(self)
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_AddHighlightLine(BFL_Tooltip, BFL.L.RECENT_ALLIES_INVITE)
		if not self:IsEnabled() then
			GameTooltip_AddErrorLine(BFL_Tooltip, BFL.L.RECENT_ALLIES_PLAYER_OFFLINE)
		end
		BFL_Tooltip:Show()
	end)

	button.PartyButton:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)

	-- Setup pin display tooltip
	if button.StateIconContainer.PinDisplay then
		button.StateIconContainer.PinDisplay:SetScript("OnEnter", function(self)
			if stateData.pinExpirationDate then
				BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
				local timeUntilExpiration = math.max(stateData.pinExpirationDate - GetServerTime(), 1)
				local timeText = RecentAlliesUtil.GetFormattedTime(timeUntilExpiration)
				GameTooltip_AddHighlightLine(BFL_Tooltip, BFL.L.RECENT_ALLIES_PIN_EXPIRES:format(timeText))
				BFL_Tooltip:Show()
			end
		end)

		button.StateIconContainer.PinDisplay:SetScript("OnLeave", function()
			BFL_Tooltip:Hide()
		end)
	end
end

-- Open context menu for recent ally
function RecentAllies:OpenMenu(button)
	local elementData = button.elementData
	if not elementData then
		return
	end

	local recentAllyData = elementData
	local contextData = {
		recentAllyData = recentAllyData,
		name = recentAllyData.characterData.name,
		server = recentAllyData.characterData.realmName,
		guid = recentAllyData.characterData.guid,
		isOffline = not recentAllyData.stateData.isOnline,
	}

	-- Use appropriate menu based on online status
	local bestMenu = recentAllyData.stateData.isOnline and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE"

	-- Fallback to FRIEND menu if RECENT_ALLY not available
	if not UnitPopupMenus[bestMenu] then
		bestMenu = recentAllyData.stateData.isOnline and "FRIEND" or "FRIEND_OFFLINE"
	end

	-- Use compatibility wrapper for Classic support
	BFL.OpenContextMenu(button, bestMenu, contextData, contextData.name)
end

-- Build tooltip for recent ally (RecentAlliesEntryMixin:BuildRecentAllyTooltip)
function RecentAllies:BuildTooltip(button, tooltip)
	local elementData = button.elementData
	if not elementData then
		return
	end

	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData

	-- Character name
	GameTooltip_AddNormalLine(tooltip, characterData.fullName)

	-- Race and level
	local raceInfo = C_CreatureInfo.GetRaceInfo(characterData.raceID)
	if raceInfo then
		GameTooltip_AddHighlightLine(
			tooltip,
			BFL.L.RECENT_ALLIES_LEVEL_RACE:format(characterData.level, raceInfo.raceName)
		)
	end

	-- Class
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	if classInfo then
		GameTooltip_AddHighlightLine(tooltip, classInfo.className)
	end

	-- Faction
	local factionInfo = C_CreatureInfo.GetFactionInfo(characterData.raceID)
	if factionInfo then
		GameTooltip_AddHighlightLine(tooltip, factionInfo.name)
	end

	-- Current location
	if stateData.currentLocation then
		GameTooltip_AddHighlightLine(tooltip, stateData.currentLocation)
	end

	-- Note
	if interactionData.note and interactionData.note ~= "" then
		GameTooltip_AddNormalLine(tooltip, BFL.L.RECENT_ALLIES_NOTE:format(interactionData.note))
	end

	-- Most recent interaction
	if interactionData.interactions and #interactionData.interactions > 0 and interactionData.interactions[1] then
		GameTooltip_AddBlankLineToTooltip(tooltip)
		local mostRecent = interactionData.interactions[1]
		GameTooltip_AddNormalLine(tooltip, BFL.L.RECENT_ALLIES_ACTIVITY)
		GameTooltip_AddHighlightLine(tooltip, mostRecent.description or "")
	end
end
