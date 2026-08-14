-- Modules/QuickFilters.lua
-- Quick Filters System Module
-- Manages the quick filter dropdown and filter state

local ADDON_NAME, BFL = ...

local QuickFilters = BFL:RegisterModule("QuickFilters", {})
local L = BFL.L

local filterMode = "all"
local FILTER_ROOT_MENU_WIDTH = 120
local FILTER_ROOT_MAX_TAG_ICONS = 2
local FRIENDS_FILTER_ICON = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter"
local visibleMenuLabels = setmetatable({}, { __mode = "k" })
local EMPTY_TABLE = {}
if table.freeze then
	table.freeze(EMPTY_TABLE)
end

local function GetFriendsList()
	return BFL:GetModule("FriendsList")
end

local function GetRegistry()
	return BFL:GetModule("FilterSortRegistry")
end

local function GetFriendTags()
	return BFL:GetModule("FriendTags")
end

local function IsModernDropdown(dropdown)
	return BFL.IsModernDropdown and BFL.IsModernDropdown(dropdown)
end

local function GetActiveGuildFrame()
	local frame = BetterFriendsFrame
	if BFL.IsClassic or not frame or not frame.FriendsTabHeader then
		return nil
	end
	if (PanelTemplates_GetSelectedTab(frame.FriendsTabHeader) or 1) ~= 4 then
		return nil
	end
	local GuildFrame = BFL:GetModule("GuildFrame")
	if GuildFrame and GuildFrame.IsEnabled and GuildFrame:IsEnabled() then
		return GuildFrame
	end
	return nil
end

local function FormatIcon(icon, size)
	local Registry = GetRegistry()
	if Registry and Registry.FormatIcon then
		return Registry:FormatIcon(icon, size or 16)
	end
	size = size or 16
	return string.format("|T%s:%d:%d:0:0|t", icon or "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all", size, size)
end

local function GetVisibleFilters()
	local Registry = GetRegistry()
	if Registry and Registry.GetVisibleQuickFilters then
		return Registry:GetVisibleQuickFilters()
	end
	return {
		{ id = "all", name = L.FILTER_ALL, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all" },
	}
end

local function ResolveFilter(mode)
	local Registry = GetRegistry()
	if Registry and Registry.NormalizeQuickFilterId then
		return Registry:NormalizeQuickFilterId(mode)
	end
	return mode or "all"
end

local function UsesModernFriendsFilterLabel()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() or false
end

local function GetFriendsFilterSelectionText(size)
	if UsesModernFriendsFilterLabel() then
		return FILTER or "Filter"
	end
	return FormatIcon(FRIENDS_FILTER_ICON, size or 14)
end

local function GetGuildFilterSelectionText(icon, size)
	if UsesModernFriendsFilterLabel() then
		return string.format("%s (%s)", FILTER or "Filter", FormatIcon(icon, math.max(10, (size or 16) - 1)))
	end
	return GetFriendsFilterSelectionText(size)
end

local function AlignLegacyHeaderSelection(dropdown)
	local initializer = BFL.FrameInitializer
	if initializer and initializer.AlignLegacyHeaderDropdownSelection then
		initializer:AlignLegacyHeaderDropdownSelection(dropdown)
	end
end

local function GetTagIconMarkup(tag, size)
	local FriendTags = GetFriendTags()
	local profile = type(tag) == "table" and (tag.chipProfile or (FriendTags and FriendTags:GetChipProfile(tag))) or nil
	if type(profile) ~= "table" or profile.iconType == "none" then
		return ""
	end

	size = tonumber(size) or 16
	if profile.iconType == "atlas" then
		local atlas = profile.iconValue or profile.atlas
		if not (atlas and BFL.HasAtlas and BFL.HasAtlas(atlas)) then
			atlas = profile.fallbackAtlas
		end
		if atlas and BFL.GetAtlasOrTextureMarkup then
			return BFL.GetAtlasOrTextureMarkup(atlas, profile.texture, size, size)
		end
	end

	local texture = profile.texture or profile.icon or profile.iconValue
	if texture then
		return FormatIcon(texture, size)
	end
	return ""
end

local function JoinMenuLabel(label, icons)
	if #icons == 0 then
		return label
	end
	return label .. "  " .. table.concat(icons, " ")
end

local function SetMenuButtonText(button, text)
	if not button then
		return
	end
	local fontString = button.fontString or button.Text
	if fontString and fontString.SetTextToFit then
		fontString:SetTextToFit(text)
	elseif fontString and fontString.SetText then
		fontString:SetText(text)
	elseif button.SetText then
		button:SetText(text)
	end
end

local function RefreshVisibleMenuLabels()
	for button, getText in pairs(visibleMenuLabels) do
		SetMenuButtonText(button, getText())
	end
end

local function AddDynamicMenuLabel(element, getText)
	if not (element and element.AddInitializer and type(getText) == "function") then
		return
	end
	element:AddInitializer(function(button)
		visibleMenuLabels[button] = getText
		SetMenuButtonText(button, getText())
	end)
	if element.AddResetter then
		element:AddResetter(function(button)
			visibleMenuLabels[button] = nil
		end)
	end
end

function QuickFilters:Initialize()
	self:InvalidateTagFilterCache()
	local Registry = GetRegistry()
	if Registry and Registry.NormalizeCurrentSelections then
		Registry:NormalizeCurrentSelections()
	end
	if BetterFriendlistDB and BetterFriendlistDB.quickFilter then
		filterMode = ResolveFilter(BetterFriendlistDB.quickFilter)
		BetterFriendlistDB.quickFilter = filterMode
	end
	if BetterFriendlistDB and type(BetterFriendlistDB.quickFilterTags) ~= "table" then
		BetterFriendlistDB.quickFilterTags = {}
	end
end

function QuickFilters:InvalidateTagFilterCache()
	self.tagFilterDefinitionsCache = nil
	self.activeTagFilterCache = nil
end

function QuickFilters:GetTagFilterDefinitions()
	local FriendTags = GetFriendTags()
	if not (FriendTags and FriendTags.CanDisplayTags and FriendTags:CanDisplayTags("filter")) then
		return EMPTY_TABLE
	end

	local definitionVersion = FriendTags.GetDefinitionVersion and FriendTags:GetDefinitionVersion() or 0
	local cache = self.tagFilterDefinitionsCache
	if
		cache
		and cache.db == BetterFriendlistDB
		and cache.friendTags == FriendTags
		and cache.definitionVersion == definitionVersion
	then
		return cache.definitions
	end

	local definitions = {}
	for _, tag in ipairs(FriendTags:GetAllTagDefinitions()) do
		if FriendTags:ShouldIncludeTagOnSurface(tag, "filter") then
			definitions[#definitions + 1] = tag
		end
	end
	self.tagFilterDefinitionsCache = {
		db = BetterFriendlistDB,
		friendTags = FriendTags,
		definitionVersion = definitionVersion,
		definitions = definitions,
	}
	return definitions
end

function QuickFilters:GetSelectedTagFilters()
	if not BetterFriendlistDB then
		return EMPTY_TABLE
	end
	if type(BetterFriendlistDB.quickFilterTags) ~= "table" then
		BetterFriendlistDB.quickFilterTags = {}
	end
	return BetterFriendlistDB.quickFilterTags
end

function QuickFilters:IsTagFilterSelected(tagId)
	return self:GetSelectedTagFilters()[tagId] == true
end

function QuickFilters:GetActiveTagFilterDefinitions()
	local selected = self:GetSelectedTagFilters()
	local FriendTags = GetFriendTags()
	local definitionVersion = FriendTags and FriendTags.GetDefinitionVersion and FriendTags:GetDefinitionVersion() or 0
	local definitions = self:GetTagFilterDefinitions()
	local cache = self.activeTagFilterCache
	if
		cache
		and cache.db == BetterFriendlistDB
		and cache.selected == selected
		and cache.friendTags == FriendTags
		and cache.definitionVersion == definitionVersion
		and cache.definitions == definitions
	then
		return cache.activeDefinitions, cache.idSet
	end

	local active = {}
	local activeIdSet = {}
	for _, tag in ipairs(definitions) do
		if selected[tag.id] == true then
			active[#active + 1] = tag
			activeIdSet[tag.id] = true
		end
	end
	self.activeTagFilterCache = {
		db = BetterFriendlistDB,
		selected = selected,
		friendTags = FriendTags,
		definitionVersion = definitionVersion,
		definitions = definitions,
		idSet = activeIdSet,
		activeDefinitions = active,
	}
	return active, activeIdSet
end

function QuickFilters:SetTagFilter(tagId, selected)
	if type(tagId) ~= "string" or tagId == "" then
		return false
	end
	local selectedTags = self:GetSelectedTagFilters()
	local newValue = selected == true or nil
	if selectedTags[tagId] == newValue then
		return false
	end
	selectedTags[tagId] = newValue
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	self:InvalidateTagFilterCache()
	RefreshVisibleMenuLabels()

	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
	local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
	self:RefreshDropdown(header and header.QuickFilterDropdown)
	return true
end

function QuickFilters:PassesTagFilters(friend)
	local activeTags, activeTagIds = self:GetActiveTagFilterDefinitions()
	if #activeTags == 0 then
		return true
	end

	local FriendTags = GetFriendTags()
	for _, tag in ipairs(FriendTags and FriendTags:GetTagsForFriend(friend, "filter") or EMPTY_TABLE) do
		if activeTagIds[tag.id] == true then
			return true
		end
	end
	return false
end

function QuickFilters:GetTagFilterText()
	local names = {}
	for _, tag in ipairs(self:GetActiveTagFilterDefinitions()) do
		names[#names + 1] = tag.name
	end
	return table.concat(names, ", ")
end

function QuickFilters:InitDropdown(dropdown)
	if not dropdown then
		return
	end

	if not IsModernDropdown(dropdown) then
		local isElvUIActive = BFL.IsElvUISkinActive and BFL:IsElvUISkinActive()
		if not isElvUIActive then
			BFL.SetDropdownWidth(dropdown, 70)
		end
		BFL.InitializeDropdown(dropdown, {
			getSelectionText = function()
				return GetFriendsFilterSelectionText(14)
			end,
			populateRootDescription = function(rootDescription)
				self:PopulateMenu(rootDescription)
			end,
		}, function()
			return false
		end, function() end)
		BFL.SetDropdownText(dropdown, GetFriendsFilterSelectionText(14))
		AlignLegacyHeaderSelection(dropdown)

		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]
		local function ShowTooltip()
			BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
			BFL_Tooltip:SetText(QuickFilters:GetTooltipText())
			BFL_Tooltip:Show()
		end

		if button then
			button:HookScript("OnEnter", ShowTooltip)
			button:HookScript("OnLeave", BFL_Tooltip_Hide)
		else
			dropdown:SetScript("OnEnter", ShowTooltip)
			dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
		end
		return
	end

	local function IsSelected(mode)
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame then
			return GuildFrame.filterMode == mode
		end
		local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
		return currentFilter == mode
	end

	local function SetSelected(mode)
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame and GuildFrame.SetFilter then
			GuildFrame:SetFilter(mode)
			return
		end
		local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
		if mode ~= currentFilter then
			self:SetFilter(mode)
		end
	end

	dropdown:SetWidth(UsesModernFriendsFilterLabel() and 92 or 51)
	BFL.InitializeDropdown(dropdown, {
		getSelectionText = function()
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.GetHeaderFilterIcon then
				return GetGuildFilterSelectionText(GuildFrame:GetHeaderFilterIcon(), 16)
			end
			return GetFriendsFilterSelectionText(14)
		end,
		populateRootDescription = function(rootDescription)
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.PopulateFilterMenu then
				rootDescription:SetTag("MENU_GUILD_STATUS_FILTER")
				GuildFrame:PopulateFilterMenu(rootDescription)
				return
			end

			self:PopulateMenu(rootDescription)
		end,
	}, IsSelected, SetSelected)
	AlignLegacyHeaderSelection(dropdown)

	local function OnEnter()
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame and GuildFrame.GetHeaderFilterText then
			BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
			BFL_Tooltip:SetText(string.format(L.GUILD_HEADER_FILTER_TOOLTIP or "Guild Filter: %s", GuildFrame:GetHeaderFilterText()))
			BFL_Tooltip:Show()
			return
		end

		BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		BFL_Tooltip:SetText(self:GetTooltipText())
		BFL_Tooltip:Show()
	end
	if dropdown.HookScript then
		dropdown:HookScript("OnEnter", OnEnter)
		dropdown:HookScript("OnLeave", BFL_Tooltip_Hide)
	else
		dropdown:SetScript("OnEnter", OnEnter)
		dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
	end
end

function QuickFilters:GetHeaderSelectionText(size)
	return GetFriendsFilterSelectionText(size)
end

function QuickFilters:GetTooltipText()
	local text = string.format(L.TOOLTIP_QUICK_FILTER or "Quick Filter: %s", self:GetFilterText())
	local tagText = self:GetTagFilterText()
	if tagText ~= "" then
		text = text .. "\n" .. (L.FRIEND_TAGS_SETTINGS_TAG_LIST or "Tags") .. ": " .. tagText
	end
	return text
end

function QuickFilters:SetFilter(mode)
	mode = ResolveFilter(mode)

	if BetterFriendlistDB then
		BetterFriendlistDB.quickFilter = mode
	end
	filterMode = mode
	RefreshVisibleMenuLabels()

	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:SetFilterMode(mode)
	end

	local Broker = BFL:GetModule("Broker")
	if Broker then
		if Broker.ScheduleBrokerTextUpdate then
			Broker:ScheduleBrokerTextUpdate()
		elseif Broker.UpdateBrokerText then
			Broker:UpdateBrokerText()
		end
	end

	return true
end

function QuickFilters:GetFilter()
	local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or filterMode or "all")
	filterMode = currentFilter
	if BetterFriendlistDB then
		BetterFriendlistDB.quickFilter = currentFilter
	end
	return currentFilter
end

function QuickFilters:GetFilterText()
	local Registry = GetRegistry()
	local currentFilter = self:GetFilter()
	if Registry and Registry.GetQuickFilterText then
		return Registry:GetQuickFilterText(currentFilter)
	end
	return L.FILTER_ALL
end

function QuickFilters:GetIcon(mode)
	local Registry = GetRegistry()
	if Registry and Registry.GetQuickFilterIcon then
		return Registry:GetQuickFilterIcon(mode or self:GetFilter())
	end
	return "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all"
end

function QuickFilters:GetIcons()
	local Registry = GetRegistry()
	if Registry and Registry.GetQuickFilterIcons then
		return Registry:GetQuickFilterIcons()
	end
	return { all = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all" }
end

function QuickFilters:RefreshDropdown(dropdown)
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() then
		local modernDropdown = FriendsUI.root and FriendsUI.root.FilterBar and FriendsUI.root.FilterBar.FilterDropdown
		dropdown = modernDropdown or dropdown
	end
	if not dropdown then
		return
	end

	local GuildFrame = GetActiveGuildFrame()
	if GuildFrame and GuildFrame.GetHeaderFilterIcon then
		local modernDropdown = IsModernDropdown(dropdown)
		local size = modernDropdown and 16 or 14
		local text = GetGuildFilterSelectionText(GuildFrame:GetHeaderFilterIcon(), size)
		BFL.SetDropdownText(dropdown, text)
		AlignLegacyHeaderSelection(dropdown)
		return
	end

	BFL.SetDropdownText(dropdown, GetFriendsFilterSelectionText(14))
	AlignLegacyHeaderSelection(dropdown)
end

function QuickFilters:PopulateMenu(rootDescription)
	rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
	if rootDescription.SetMinimumWidth then
		rootDescription:SetMinimumWidth(FILTER_ROOT_MENU_WIDTH)
	end
	if rootDescription.SetMaximumWidth then
		rootDescription:SetMaximumWidth(FILTER_ROOT_MENU_WIDTH)
	end
	local function IsSelected(mode)
		return self:GetFilter() == mode
	end

	local function SetSelected(mode)
		self:SetFilter(mode)
	end

	local function GetFilterLabel()
		local filterIcons = { FormatIcon(self:GetIcon(self:GetFilter()), 16) }
		return JoinMenuLabel(FILTERS or FILTER or "Filters", filterIcons)
	end
	local filterSubmenu = rootDescription:CreateButton(GetFilterLabel())
	AddDynamicMenuLabel(filterSubmenu, GetFilterLabel)
	for _, filter in ipairs(GetVisibleFilters()) do
		filterSubmenu:CreateRadio(FormatIcon(filter.icon, 16) .. " " .. filter.name, IsSelected, SetSelected, filter.id)
	end

	local function GetTagLabel()
		local activeTags = self:GetActiveTagFilterDefinitions()
		local tagIcons = {}
	for _, tag in ipairs(activeTags) do
		if #tagIcons >= FILTER_ROOT_MAX_TAG_ICONS then
			break
		end
		local icon = GetTagIconMarkup(tag, 16)
		if icon ~= "" then
			tagIcons[#tagIcons + 1] = icon
		end
	end
	if #activeTags > #tagIcons then
		tagIcons[#tagIcons + 1] = "+" .. (#activeTags - #tagIcons)
	end
		return JoinMenuLabel(L.FRIEND_TAGS_SETTINGS_TAG_LIST or "Tags", tagIcons)
	end

	local tagSubmenu = rootDescription:CreateButton(GetTagLabel())
	AddDynamicMenuLabel(tagSubmenu, GetTagLabel)
	local tagDefinitions = self:GetTagFilterDefinitions()
	if #tagDefinitions == 0 then
		tagSubmenu:CreateTitle(L.FRIEND_TAGS_SETTINGS_TAG_LIST_EMPTY or "No tags available.")
		return
	end
	for _, tag in ipairs(tagDefinitions) do
		local tagId = tag.id
		local icon = GetTagIconMarkup(tag, 16)
		local label = icon ~= "" and (icon .. " " .. tag.name) or tag.name
		local checkbox = tagSubmenu:CreateCheckbox(label, function()
			return self:IsTagFilterSelected(tagId)
		end, function()
			self:SetTagFilter(tagId, not self:IsTagFilterSelected(tagId))
			return MenuResponse and MenuResponse.Refresh
		end)
		if checkbox and checkbox.SetCloseOnClick then
			checkbox:SetCloseOnClick(false)
		end
	end
end
