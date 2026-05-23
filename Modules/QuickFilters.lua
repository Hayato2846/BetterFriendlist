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

	if BFL.IsClassic or not BFL.HasModernDropdown then
		local isElvUIActive = BFL.IsThemeActive and BFL:IsThemeActive("elvui")
		if not isElvUIActive then
			UIDropDownMenu_SetWidth(dropdown, 70)
		end
		UIDropDownMenu_Initialize(dropdown, function(self, level)
			for _, filter in ipairs(GetVisibleFilters()) do
				local info = UIDropDownMenu_CreateInfo()
				local iconText = FormatIcon(filter.icon, 14)
				info.text = iconText .. " " .. filter.name
				info.value = filter.id
				info.func = function()
					QuickFilters:SetFilter(filter.id)
					UIDropDownMenu_SetText(dropdown, iconText)
				end
				local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
				info.checked = (currentFilter == filter.id)
				UIDropDownMenu_AddButton(info)
			end
		end)

		local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
		UIDropDownMenu_SetText(dropdown, FormatIcon(self:GetIcon(currentFilter), 14))

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
		local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
		return currentFilter == mode
	end

	local function SetSelected(mode)
		local currentFilter = ResolveFilter(BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all")
		if mode ~= currentFilter then
			self:SetFilter(mode)
		end
	end

	dropdown:SetWidth(51)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
		for _, filter in ipairs(GetVisibleFilters()) do
			rootDescription:CreateRadio(FormatIcon(filter.icon, 16) .. " " .. filter.name, IsSelected, SetSelected, filter.id)
		end
	end)

	dropdown:SetSelectionTranslator(function(selection)
		local Registry = GetRegistry()
		local icon = Registry and Registry:GetQuickFilterIcon(selection.data) or self:GetIcon(selection.data)
		return FormatIcon(icon, 16)
	end)

	dropdown:SetScript("OnEnter", function()
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
	if Broker and Broker.UpdateBrokerText then
		Broker:UpdateBrokerText()
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

	local currentFilter = self:GetFilter()
	local icon = self:GetIcon(currentFilter)
	local size = (BFL.IsClassic or not BFL.HasModernDropdown) and 14 or 16
	local text = FormatIcon(icon, size)

	if BFL.IsClassic or not BFL.HasModernDropdown then
		UIDropDownMenu_SetText(dropdown, text)
	elseif dropdown.SetText then
		dropdown:SetText(text)
	end
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
