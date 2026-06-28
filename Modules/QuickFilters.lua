-- Modules/QuickFilters.lua
-- Quick Filters System Module
-- Manages the quick filter dropdown and filter state

local ADDON_NAME, BFL = ...

local QuickFilters = BFL:RegisterModule("QuickFilters", {})
local L = BFL.L

local filterMode = "all"

local function GetFriendsList()
	return BFL:GetModule("FriendsList")
end

local function GetRegistry()
	return BFL:GetModule("FilterSortRegistry")
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

function QuickFilters:Initialize()
	local Registry = GetRegistry()
	if Registry and Registry.NormalizeCurrentSelections then
		Registry:NormalizeCurrentSelections()
	end
	if BetterFriendlistDB and BetterFriendlistDB.quickFilter then
		filterMode = ResolveFilter(BetterFriendlistDB.quickFilter)
		BetterFriendlistDB.quickFilter = filterMode
	end
end

function QuickFilters:InitDropdown(dropdown)
	if not dropdown then
		return
	end

	if not IsModernDropdown(dropdown) then
		local isElvUIActive = BFL.IsThemeActive and BFL:IsThemeActive("elvui")
		if not isElvUIActive then
			BFL.SetDropdownWidth(dropdown, 70)
		end
		local labels = {}
		local values = {}
		for _, filter in ipairs(GetVisibleFilters()) do
			table.insert(labels, FormatIcon(filter.icon, 14) .. " " .. filter.name)
			table.insert(values, filter.id)
		end
		BFL.InitializeDropdown(dropdown, {
			labels = labels,
			values = values,
			getSelectionText = function(value)
				return FormatIcon(self:GetIcon(ResolveFilter(value)), 14)
			end,
		}, function(value)
			local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
			return currentFilter == value
		end, function(value)
			QuickFilters:SetFilter(value)
		end)

		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]
		local function ShowTooltip()
			local filterText = QuickFilters:GetFilterText()
			BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
			BFL_Tooltip:SetText(string.format(L.TOOLTIP_QUICK_FILTER or "Quick Filter: %s", filterText))
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

	dropdown:SetWidth(51)
	BFL.InitializeDropdown(dropdown, {
		getSelectionText = function(mode)
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.GetHeaderFilterIcon then
				return FormatIcon(GuildFrame:GetHeaderFilterIcon(), 16)
			end
			local Registry = GetRegistry()
			local icon = Registry and Registry:GetQuickFilterIcon(mode) or self:GetIcon(mode)
			return FormatIcon(icon, 16)
		end,
		populateRootDescription = function(rootDescription)
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.PopulateFilterMenu then
				rootDescription:SetTag("MENU_GUILD_STATUS_FILTER")
				GuildFrame:PopulateFilterMenu(rootDescription)
				return
			end

			rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
			for _, filter in ipairs(GetVisibleFilters()) do
				rootDescription:CreateRadio(FormatIcon(filter.icon, 16) .. " " .. filter.name, IsSelected, SetSelected, filter.id)
			end
		end,
	}, IsSelected, SetSelected)

	dropdown:SetScript("OnEnter", function()
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame and GuildFrame.GetHeaderFilterText then
			BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
			BFL_Tooltip:SetText(string.format(L.GUILD_HEADER_FILTER_TOOLTIP or "Guild Filter: %s", GuildFrame:GetHeaderFilterText()))
			BFL_Tooltip:Show()
			return
		end

		local filterText = self:GetFilterText()
		BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		BFL_Tooltip:SetText(string.format(L.TOOLTIP_QUICK_FILTER or "Quick Filter: %s", filterText))
		BFL_Tooltip:Show()
	end)
	dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
end

function QuickFilters:SetFilter(mode)
	mode = ResolveFilter(mode)

	if BetterFriendlistDB then
		BetterFriendlistDB.quickFilter = mode
	end
	filterMode = mode

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
	if not dropdown then
		return
	end

	local GuildFrame = GetActiveGuildFrame()
	if GuildFrame and GuildFrame.GetHeaderFilterIcon then
		local modernDropdown = IsModernDropdown(dropdown)
		local text = FormatIcon(GuildFrame:GetHeaderFilterIcon(), modernDropdown and 16 or 14)
		BFL.SetDropdownText(dropdown, text)
		return
	end

	local currentFilter = self:GetFilter()
	local icon = self:GetIcon(currentFilter)
	local modernDropdown = IsModernDropdown(dropdown)
	local size = modernDropdown and 16 or 14
	local text = FormatIcon(icon, size)

	BFL.SetDropdownText(dropdown, text)
end

function QuickFilters:PopulateMenu(rootDescription)
	local function IsSelected(mode)
		return self:GetFilter() == mode
	end

	local function SetSelected(mode)
		self:SetFilter(mode)
	end

	for _, filter in ipairs(GetVisibleFilters()) do
		rootDescription:CreateRadio(FormatIcon(filter.icon, 16) .. " " .. filter.name, IsSelected, SetSelected, filter.id)
	end
end
