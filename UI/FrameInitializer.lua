-- UI/FrameInitializer.lua
-- Handles UI initialization for BetterFriendlist frames
-- Extracted from BetterFriendlist.lua to reduce main file complexity

local ADDON_NAME, BFL = ...
local L = BFL.L -- Localization shortcut (Use Proxy Table for Fallbacks)

--------------------------------------------------------------------------
-- UI CONSTANTS
--------------------------------------------------------------------------
local UI_CONSTANTS = {
	-- Dropdown
	DROPDOWN_WIDTH = 51,

	-- Tooltip positioning
	TOOLTIP_OFFSET_X = 36,
	TOOLTIP_ANCHOR_Y = -18,

	-- Spacing
	SPACING_TINY = 2,
	SPACING_SMALL = 5,
	SPACING_MEDIUM = 10,
	SPACING_LARGE = 15,
	SPACING_XLARGE = 20,

	-- Common UI element sizes
	BUTTON_SIZE_SMALL = 20,
	BUTTON_SIZE_MEDIUM = 30,
	BUTTON_SIZE_LARGE = 34,
	BUTTON_HEIGHT_STANDARD = 34,

	-- Offsets
	BUTTON_OFFSET_Y = -40,
	CENTER_OFFSET = 200,
	TOP_OFFSET = -5,
	SIDE_MARGIN = 15,
	SCROLL_TOP_OFFSET = -60,
	SCROLL_TOP_OFFSET_LARGE = -80,
	BOTTOM_BUTTON_OFFSET = 15,

	-- Dialog sizes
	DIALOG_WIDTH = 300,
	DIALOG_HEIGHT = 200,

	-- Alpha values
	ALPHA_DIMMED = 0.5,
	ALPHA_BACKGROUND = 0.5,

	-- Background colors
	BG_COLOR_DARK = { 0.1, 0.1, 0.1, 0.5 },
	BG_COLOR_MEDIUM = { 0.2, 0.2, 0.2, 0.5 },

	-- Text colors
	TEXT_COLOR_GRAY = { 0.5, 0.5, 0.5 },

	-- Recursion limits
	MAX_RECURSION_DEPTH = 10,

	-- Statistics
	TOP_STATS_COUNT = 5,
}

-- Export to BFL namespace for use in other modules
BFL.UI = BFL.UI or {}
BFL.UI.CONSTANTS = UI_CONSTANTS

local IsModernDropdown = BFL.IsModernDropdown
local APPEAR_OFFLINE_TEXTURE = FRIENDS_TEXTURE_OFFLINE or "Interface\\FriendsFrame\\StatusIcon-Offline"

-- Module registration
local FrameInitializer = {
	name = "FrameInitializer",
	initialized = false,
}

-- Current sort mode tracking (for Sort Dropdown)
local currentSortMode = "status"

--------------------------------------------------------------------------
-- STATUS DROPDOWN INITIALIZATION
-- Dropdowns can be modern or legacy depending on flavor/XML; branch by frame API.
--------------------------------------------------------------------------

function FrameInitializer:InitializeStatusDropdown(frame)
	if not frame or not frame.FriendsTabHeader then
		return
	end
	if not frame.FriendsTabHeader.StatusDropdown then
		return
	end

	local dropdown = frame.FriendsTabHeader.StatusDropdown

	-- Get current Battle.net status
	local bnetAFK, bnetDND, bnetAppearOffline = BFL.GetMyBNetStatus()
	local bnStatus
	if bnetAppearOffline and BFL.CanSetAppearOffline and BFL.CanSetAppearOffline() then
		bnStatus = APPEAR_OFFLINE_TEXTURE
	elseif bnetAFK then
		bnStatus = FRIENDS_TEXTURE_AFK
	elseif bnetDND then
		bnStatus = FRIENDS_TEXTURE_DND
	else
		bnStatus = FRIENDS_TEXTURE_ONLINE
	end

	local optionLabels = {
		string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE),
		string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY),
		string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY),
	}
	local optionValues = {
		FRIENDS_TEXTURE_ONLINE,
		FRIENDS_TEXTURE_AFK,
		FRIENDS_TEXTURE_DND,
	}
	if BFL.CanSetAppearOffline and BFL.CanSetAppearOffline() then
		table.insert(
			optionLabels,
			string.format(
				"|T%s.tga:14:14:0:0|t %s",
				APPEAR_OFFLINE_TEXTURE,
				L.STATUS_APPEAR_OFFLINE or SOCIAL_UI_PRESENCE_TYPE_LABEL_APPEAR_OFFLINE or "Appear Offline"
			)
		)
		table.insert(optionValues, APPEAR_OFFLINE_TEXTURE)
	end
	local function GetStatusText(status)
		if status == FRIENDS_TEXTURE_ONLINE then
			return FRIENDS_LIST_AVAILABLE
		elseif status == FRIENDS_TEXTURE_AFK then
			return FRIENDS_LIST_AWAY
		elseif status == FRIENDS_TEXTURE_DND then
			return FRIENDS_LIST_BUSY
		elseif status == APPEAR_OFFLINE_TEXTURE then
			return L.STATUS_APPEAR_OFFLINE or SOCIAL_UI_PRESENCE_TYPE_LABEL_APPEAR_OFFLINE or "Appear Offline"
		end
		return FRIENDS_LIST_AVAILABLE
	end
	local function GetStatusSelectionText(status)
		if IsModernDropdown(dropdown) then
			return string.format("|T%s.tga:16:16:0:0|t", status or FRIENDS_TEXTURE_ONLINE)
		end
		return string.format("|T%s.tga:14:14:-2:-2|t", status or FRIENDS_TEXTURE_ONLINE)
	end
	local function IsSelected(status)
		return bnStatus == status
	end
	local function SetSelected(status)
		if status == bnStatus then
			return
		end

		bnStatus = status
		if status == FRIENDS_TEXTURE_ONLINE then
			BFL.SetMyBNetStatus("online")
		elseif status == FRIENDS_TEXTURE_AFK then
			BFL.SetMyBNetStatus("afk")
		elseif status == FRIENDS_TEXTURE_DND then
			BFL.SetMyBNetStatus("dnd")
		elseif status == APPEAR_OFFLINE_TEXTURE then
			BFL.SetMyBNetStatus("appear_offline")
		end
	end
	local function RefreshStatus()
		local isAFK, isDND, isAppearOffline = BFL.GetMyBNetStatus()
		if isAppearOffline and BFL.CanSetAppearOffline and BFL.CanSetAppearOffline() then
			bnStatus = APPEAR_OFFLINE_TEXTURE
		elseif isAFK then
			bnStatus = FRIENDS_TEXTURE_AFK
		elseif isDND then
			bnStatus = FRIENDS_TEXTURE_DND
		else
			bnStatus = FRIENDS_TEXTURE_ONLINE
		end

		if IsModernDropdown(dropdown) then
			if dropdown.GenerateMenu then
				dropdown:GenerateMenu()
			end
		else
			BFL.SetDropdownText(dropdown, GetStatusSelectionText(bnStatus))
		end
	end
	dropdown.BFLRefreshStatus = RefreshStatus

	if not IsModernDropdown(dropdown) then
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r legacy UIDropDownMenu path for StatusDropdown")

		BFL.SetDropdownWidth(dropdown, 38)
		BFL.InitializeDropdown(dropdown, {
			labels = optionLabels,
			values = optionValues,
			getSelectionText = GetStatusSelectionText,
		}, IsSelected, SetSelected)

		-- Set initial selected text with smaller icon and left offset
		BFL.SetDropdownText(dropdown, GetStatusSelectionText(bnStatus))

		-- Restore text on show (Fix for "..." when switching tabs)
		-- We use C_Timer.After to ensure this runs AFTER any default layout logic that might clear our text
		dropdown:SetScript("OnShow", function(self)
			C_Timer.After(0.01, function()
				RefreshStatus()
				-- Increase width slightly to ensure icon fits without truncating to "..."
				BFL.SetDropdownWidth(self, 40)
			end)
		end)

		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local button = _G[dropdown:GetName() .. "Button"]
		if button then
			button:HookScript("OnEnter", function()
				BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				BFL_Tooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, GetStatusText(bnStatus)))
				BFL_Tooltip:Show()
			end)
			button:HookScript("OnLeave", BFL_Tooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function()
				BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				BFL_Tooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, GetStatusText(bnStatus)))
				BFL_Tooltip:Show()
			end)
			dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
		end

		return
	end

	-- Modern dropdown path.
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)
	BFL.InitializeDropdown(dropdown, {
		labels = optionLabels,
		values = optionValues,
		getSelectionText = GetStatusSelectionText,
	}, IsSelected, SetSelected)

	-- Generate menu once to trigger initial selection display
	-- This ensures the dropdown shows the current status icon on load
	if dropdown.GenerateMenu then
		dropdown:GenerateMenu()
	end

	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
		BFL_Tooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, GetStatusText(bnStatus)))
		BFL_Tooltip:Show()
	end)
	dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
end

function FrameInitializer:RefreshStatusDropdown(frame)
	local dropdown = frame and frame.FriendsTabHeader and frame.FriendsTabHeader.StatusDropdown
	if dropdown and dropdown.BFLRefreshStatus then
		dropdown.BFLRefreshStatus()
	end
end

--------------------------------------------------------------------------
-- SORT DROPDOWN INITIALIZATION
--------------------------------------------------------------------------

-- Sort mode icons (All using Feather Icons)
local SORT_ICONS = {
	status = "Interface\\AddOns\\BetterFriendlist\\Icons\\status", -- Feather: disc/status icon
	name = "Interface\\AddOns\\BetterFriendlist\\Icons\\name", -- Feather: type/text icon
	level = "Interface\\AddOns\\BetterFriendlist\\Icons\\level", -- Feather: bar-chart icon
	zone = "Interface\\AddOns\\BetterFriendlist\\Icons\\zone", -- Feather: map-pin icon
	game = "Interface\\AddOns\\BetterFriendlist\\Icons\\game", -- Feather: target/game icon
	faction = "Interface\\AddOns\\BetterFriendlist\\Icons\\faction", -- Feather: shield icon
	guild = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild", -- Feather: users/group icon
	class = "Interface\\AddOns\\BetterFriendlist\\Icons\\class", -- Feather: award icon
	realm = "Interface\\AddOns\\BetterFriendlist\\Icons\\realm", -- Feather: server icon
	none = "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up", -- X icon for none
}

-- Sort mode display names (PHASE 9B+9C: Added 5 new sort options)
local SORT_NAMES = {
	status = L.SORT_STATUS,
	name = L.SORT_NAME,
	level = L.SORT_LEVEL,
	zone = L.SORT_ZONE,
	game = L.SORT_GAME, -- PHASE 9B
	faction = L.SORT_FACTION, -- PHASE 9C
	guild = L.SORT_GUILD, -- PHASE 9C
	class = L.SORT_CLASS, -- PHASE 9C
	realm = L.SORT_REALM, -- PHASE 9C
}

-- Helper: Format icon for display (handles both texture paths and Font Awesome strings)
local function FormatIconText(iconData, text)
	-- Check if it's a texture path (starts with "Interface")
	if type(iconData) == "number" or (type(iconData) == "string" and iconData:match("^Interface")) then
		return string.format("\124T%s:16:16:0:0\124t %s", iconData, text)
	else
		-- Font Awesome icon - use directly with color
		return string.format("|cFF00CCFF%s|r %s", iconData, text)
	end
end

-- Helper: Format icon only for dropdown button
local function FormatIconOnly(iconData)
	if type(iconData) == "number" or (type(iconData) == "string" and iconData:match("^Interface")) then
		return string.format("\124T%s:16:16:0:0\124t", iconData)
	else
		-- Font Awesome icon
		return string.format("|cFF00CCFF%s|r", iconData)
	end
end

local function GetFilterSortRegistry()
	return BFL:GetModule("FilterSortRegistry")
end

local function GetVisibleSorters()
	local Registry = GetFilterSortRegistry()
	if Registry and Registry.GetVisibleSorters then
		return Registry:GetVisibleSorters()
	end
	local sorters = {}
	for id, name in pairs(SORT_NAMES) do
		table.insert(sorters, { id = id, name = name, icon = SORT_ICONS[id] })
	end
	table.sort(sorters, function(a, b)
		return (a.name or a.id) < (b.name or b.id)
	end)
	return sorters
end

local function GetSorterIcon(sortMode)
	local Registry = GetFilterSortRegistry()
	if Registry and Registry.GetSorterIcon then
		return Registry:GetSorterIcon(sortMode)
	end
	return SORT_ICONS[sortMode] or SORT_ICONS.name
end

local function GetSorterName(sortMode)
	if sortMode == "none" then
		return L.SORT_NONE or "None"
	end
	local Registry = GetFilterSortRegistry()
	if Registry and Registry.GetSorterText then
		return Registry:GetSorterText(sortMode)
	end
	return SORT_NAMES[sortMode] or sortMode or "Status"
end

function FrameInitializer:InitializeSortDropdown(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.SortDropdown then
		return
	end

	local dropdown = frame.FriendsTabHeader.SortDropdown
	local optionLabels = {
		string.format("|T%s:14:14:0:0|t %s", SORT_ICONS.status, L.SORT_STATUS),
		string.format("|T%s:14:14:0:0|t %s", SORT_ICONS.name, L.SORT_NAME),
		string.format("|T%s:14:14:0:0|t %s", SORT_ICONS.level, L.SORT_LEVEL),
		string.format("|T%s:14:14:0:0|t %s", SORT_ICONS.zone, L.SORT_ZONE),
	}
	local optionValues = { "status", "name", "level", "zone" }
	local function GetSortSelectionText(sortMode)
		local icon = SORT_ICONS[sortMode] or SORT_ICONS.status
		return string.format("|T%s:14:14:-2:-2|t", icon)
	end
	local function IsSelected(sortMode)
		return currentSortMode == sortMode
	end
	local function SetSelected(sortMode)
		if sortMode ~= currentSortMode then
			currentSortMode = sortMode
			-- Notify main file to update display
			if _G.UpdateFriendsList then
				_G.UpdateFriendsList()
			end
			if _G.UpdateFriendsDisplay then
				_G.UpdateFriendsDisplay()
			end
		end
	end

	if not IsModernDropdown(dropdown) then
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r legacy UIDropDownMenu path for SortDropdown")

		BFL.SetDropdownWidth(dropdown, 60)
		BFL.InitializeDropdown(dropdown, {
			labels = optionLabels,
			values = optionValues,
			getSelectionText = GetSortSelectionText,
		}, IsSelected, SetSelected)

		-- Set initial selected text
		local currentIcon = SORT_ICONS[currentSortMode] or SORT_ICONS.status
		BFL.SetDropdownText(dropdown, string.format("|T%s:14:14:-2:-2|t", currentIcon))

		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]

		if button then
			button:HookScript("OnEnter", function()
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				BFL_Tooltip:SetText("Sort: " .. sortName)
				BFL_Tooltip:Show()
			end)
			button:HookScript("OnLeave", BFL_Tooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function()
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				BFL_Tooltip:SetText("Sort: " .. sortName)
				BFL_Tooltip:Show()
			end)
			dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
		end

		return
	end

	-- Narrower width to match QuickFilters style
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)

	BFL.InitializeDropdown(dropdown, {
		labels = optionLabels,
		values = optionValues,
		getSelectionText = GetSortSelectionText,
	}, IsSelected, SetSelected)

	if dropdown.GenerateMenu then
		dropdown:GenerateMenu()
	end

	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		local sortName = SORT_NAMES[currentSortMode] or "Status"
		BFL_Tooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
		BFL_Tooltip:SetText("Sort: " .. sortName)
		BFL_Tooltip:Show()
	end)
	dropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
end

-- Initialize primary and secondary sort dropdowns
function FrameInitializer:InitializeSortDropdowns(frame)
	if not frame or not frame.FriendsTabHeader then
		return
	end

	local header = frame.FriendsTabHeader
	if not header.PrimarySortDropdown or not header.SecondarySortDropdown then
		return
	end

	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then
		return
	end

	if not (IsModernDropdown(header.PrimarySortDropdown) and IsModernDropdown(header.SecondarySortDropdown)) then
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r legacy UIDropDownMenu path for Primary/Secondary Sort dropdowns")

		-- Primary Sort Dropdown
		local primaryDropdown = header.PrimarySortDropdown
		local secondaryDropdown = header.SecondarySortDropdown
		-- Only set width if ElvUI is not active (ElvUI Skin handles sizing)
		local isElvUIActive = BFL.IsElvUISkinActive and BFL:IsElvUISkinActive()
		if not isElvUIActive then
			BFL.SetDropdownWidth(primaryDropdown, 70)
		end
		local function GetIconText(sortMode)
			return string.format("|T%s:14:14:-2:-2|t", GetSorterIcon(sortMode))
		end

		local function GetSortDB()
			local DB = BFL:GetModule("DB")
			return DB and DB:Get() or {}
		end

		local function BuildSortOptions(includeNone)
			local labels = {}
			local values = {}
			if includeNone then
				table.insert(labels, string.format("|T%s:14:14:0:0|t %s", SORT_ICONS.none, L.SORT_NONE))
				table.insert(values, "none")
			end
			for _, sorter in ipairs(GetVisibleSorters()) do
				table.insert(labels, string.format("|T%s:14:14:0:0|t %s", sorter.icon, sorter.name))
				table.insert(values, sorter.id)
			end
			return {
				labels = labels,
				values = values,
				getSelectionText = GetIconText,
			}
		end

		local primaryOptions = BuildSortOptions(false)
		BFL.InitializeDropdown(primaryDropdown, primaryOptions, function(sortMode)
			local db = GetSortDB()
			local currentSort = db.primarySort or FriendsList.sortMode or "status"
			return currentSort == sortMode
		end, function(sortMode)
			FriendsList:SetSortMode(sortMode)
			FriendsList:RenderDisplay()

			-- Update secondary dropdown text in case the primary change reset it.
			local currentSecondary = FriendsList.secondarySort or GetSortDB().secondarySort or "none"
			if currentSecondary ~= "none" and currentSecondary == FriendsList.sortMode then
				currentSecondary = "none"
			end
			BFL.SetDropdownText(secondaryDropdown, GetIconText(currentSecondary))
		end)

		-- Secondary Sort Dropdown
		-- Only set width if ElvUI is not active (ElvUI Skin handles sizing)
		local isElvUIActiveSecondary = BFL.IsElvUISkinActive and BFL:IsElvUISkinActive()
		if not isElvUIActiveSecondary then
			BFL.SetDropdownWidth(secondaryDropdown, 70)
		end
		local secondaryOptions = BuildSortOptions(true)
		secondaryOptions.isOptionHidden = function(sortMode)
			return sortMode ~= "none" and sortMode == FriendsList.sortMode
		end
		BFL.InitializeDropdown(secondaryDropdown, secondaryOptions, function(sortMode)
			local db = GetSortDB()
			local currentSort = db.secondarySort or FriendsList.secondarySort or "name"
			return currentSort == sortMode
		end, function(sortMode)
			FriendsList:SetSecondarySortMode(sortMode)
			FriendsList:RenderDisplay()
		end)
		local currentSecondary = GetSortDB().secondarySort or FriendsList.secondarySort or "name"
		if currentSecondary ~= "none" and currentSecondary == FriendsList.sortMode then
			currentSecondary = "none"
		end
		BFL.SetDropdownText(secondaryDropdown, GetIconText(currentSecondary))

		-- Setup tooltips for Classic
		-- Hook buttons as they consume mouse events
		local primaryButton = _G[primaryDropdown:GetName() .. "Button"]
		if primaryButton then
			primaryButton:HookScript("OnEnter", function()
				local sortName = GetSorterName(FriendsList.sortMode)
				BFL_Tooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				BFL_Tooltip:SetText(L.SORT_PRIMARY_LABEL .. ": " .. sortName)
				BFL_Tooltip:AddLine(L.SORT_PRIMARY_DESC, 1, 1, 1, true)
				BFL_Tooltip:Show()
			end)
			primaryButton:HookScript("OnLeave", BFL_Tooltip_Hide)
		else
			primaryDropdown:SetScript("OnEnter", function()
				local sortName = GetSorterName(FriendsList.sortMode)
				BFL_Tooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				BFL_Tooltip:SetText(L.SORT_PRIMARY_LABEL .. ": " .. sortName)
				BFL_Tooltip:AddLine(L.SORT_PRIMARY_DESC, 1, 1, 1, true)
				BFL_Tooltip:Show()
			end)
			primaryDropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
		end

		local secondaryButton = _G[secondaryDropdown:GetName() .. "Button"]
		if secondaryButton then
			secondaryButton:HookScript("OnEnter", function()
				local sortName = GetSorterName(FriendsList.secondarySort)
				BFL_Tooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				BFL_Tooltip:SetText(L.SORT_SECONDARY_LABEL .. ": " .. sortName)
				BFL_Tooltip:AddLine(L.SORT_SECONDARY_DESC, 1, 1, 1, true)
				BFL_Tooltip:Show()
			end)
			secondaryButton:HookScript("OnLeave", BFL_Tooltip_Hide)
		else
			secondaryDropdown:SetScript("OnEnter", function()
				local sortName = GetSorterName(FriendsList.secondarySort)
				BFL_Tooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				BFL_Tooltip:SetText(L.SORT_SECONDARY_LABEL .. ": " .. sortName)
				BFL_Tooltip:AddLine(L.SORT_SECONDARY_DESC, 1, 1, 1, true)
				BFL_Tooltip:Show()
			end)
			secondaryDropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
		end

		return
	end

	local primaryDropdown = header.PrimarySortDropdown
	local secondaryDropdown = header.SecondarySortDropdown
	local function GetActiveGuildFrame()
		local bflFrame = BetterFriendsFrame
		if BFL.IsClassic or not bflFrame or not bflFrame.FriendsTabHeader then
			return nil
		end
		if (PanelTemplates_GetSelectedTab(bflFrame.FriendsTabHeader) or 1) ~= 4 then
			return nil
		end
		local GuildFrame = BFL:GetModule("GuildFrame")
		if GuildFrame and GuildFrame.IsEnabled and GuildFrame:IsEnabled() then
			return GuildFrame
		end
		return nil
	end

	local function IsPrimarySelected(sortMode)
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame then
			return GuildFrame.sortMode == sortMode
		end
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentSort = db.primarySort or FriendsList.sortMode or "status"
		return currentSort == sortMode
	end

	local function SetPrimarySelected(sortMode)
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame and GuildFrame.SetSort then
			GuildFrame:SetSort(sortMode, true)
			return
		end

		FriendsList:SetSortMode(sortMode)
		FriendsList:RenderDisplay()

		-- Force update secondary dropdown to reflect potential reset to "none"
		if secondaryDropdown and secondaryDropdown.GenerateMenu then
			secondaryDropdown:GenerateMenu()
		end
	end

	BFL.InitializeDropdown(primaryDropdown, {
		getSelectionText = function(sortMode)
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.GetHeaderSortIcon then
				return FormatIconOnly(GuildFrame:GetHeaderSortIcon())
			end
			return FormatIconOnly(GetSorterIcon(sortMode))
		end,
		populateRootDescription = function(rootDescription)
			local GuildFrame = GetActiveGuildFrame()
			if GuildFrame and GuildFrame.PopulateSortMenu then
				rootDescription:SetTag("MENU_GUILD_PRIMARY_SORT")
				GuildFrame:PopulateSortMenu(rootDescription)
				return
			end

			rootDescription:SetTag("MENU_FRIENDS_PRIMARY_SORT")

			for _, sorter in ipairs(GetVisibleSorters()) do
				rootDescription:CreateRadio(FormatIconText(sorter.icon, sorter.name), IsPrimarySelected, SetPrimarySelected, sorter.id)
			end
		end,
	}, IsPrimarySelected, SetPrimarySelected)

	-- Generate menu once to trigger initial selection display
	if primaryDropdown.GenerateMenu then
		primaryDropdown:GenerateMenu()
	end

	primaryDropdown:SetScript("OnEnter", function()
		local GuildFrame = GetActiveGuildFrame()
		if GuildFrame and GuildFrame.GetHeaderSortText then
			BFL_Tooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
			BFL_Tooltip:SetText((L.GUILD_HEADER_SORT_TOOLTIP or "Guild Sort: %s"):format(GuildFrame:GetHeaderSortText()))
			BFL_Tooltip:Show()
			return
		end
		local sortName = GetSorterName(FriendsList.sortMode)
		BFL_Tooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.SORT_PRIMARY_LABEL .. ": " .. sortName)
		BFL_Tooltip:AddLine(L.SORT_PRIMARY_DESC, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	primaryDropdown:SetScript("OnLeave", BFL_Tooltip_Hide)

	-- Initialize Secondary Sort Dropdown

	local function IsSecondarySelected(sortMode)
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentSort = db.secondarySort or FriendsList.secondarySort or "name"
		return currentSort == sortMode
	end

	local function SetSecondarySelected(sortMode)
		FriendsList:SetSecondarySortMode(sortMode)
		FriendsList:RenderDisplay()
	end

	BFL.InitializeDropdown(secondaryDropdown, {
		getSelectionText = function(sortMode)
			return FormatIconOnly(GetSorterIcon(sortMode))
		end,
		populateRootDescription = function(rootDescription)
			rootDescription:SetTag("MENU_FRIENDS_SECONDARY_SORT")

			rootDescription:CreateRadio(FormatIconText(SORT_ICONS.none, L.SORT_NONE), IsSecondarySelected, SetSecondarySelected, "none")
			for _, sorter in ipairs(GetVisibleSorters()) do
				if sorter.id ~= FriendsList.sortMode then
					rootDescription:CreateRadio(FormatIconText(sorter.icon, sorter.name), IsSecondarySelected, SetSecondarySelected, sorter.id)
				end
			end
		end,
	}, IsSecondarySelected, SetSecondarySelected)

	-- Generate menu once to trigger initial selection display
	if secondaryDropdown.GenerateMenu then
		secondaryDropdown:GenerateMenu()
	end

	secondaryDropdown:SetScript("OnEnter", function()
		local sortName = GetSorterName(FriendsList.secondarySort)
		BFL_Tooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(L.SORT_SECONDARY_LABEL .. ": " .. sortName)
		BFL_Tooltip:AddLine(L.SORT_SECONDARY_DESC, 1, 1, 1, true)
		BFL_Tooltip:Show()
	end)
	secondaryDropdown:SetScript("OnLeave", BFL_Tooltip_Hide)
end

-- Get current sort mode (for external access)
function FrameInitializer:GetSortMode()
	return currentSortMode
end

-- Set current sort mode (for external access)
function FrameInitializer:SetSortMode(mode)
	currentSortMode = mode or "status"
end

--------------------------------------------------------------------------
-- TABS INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeTabs(frame)
	if not frame or not frame.FriendsTabHeader then
		return
	end

	-- Classic: Only Friends tab is visible, but we need to tell PanelTemplates about it
	-- In Classic, Tab2 and Tab3 exist in XML but are hidden by HideClassicOnlyTabs()
	if BFL.IsClassic then
		-- Register Tabs array so PanelTemplates_UpdateTabs can find tabs via frame.Tabs[i]
		-- Classic's SharedUIPanelTemplates uses frame.Tabs[i], NOT frame["Tab"..i]
		frame.FriendsTabHeader.Tabs = { frame.FriendsTabHeader.Tab1 }
		PanelTemplates_SetNumTabs(frame.FriendsTabHeader, 1)
		PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
	else
		-- Retail: Set up the tabs on the FriendsTabHeader
		-- Base tabs: Friends, Recent Allies, RAF. Guild tab (Tab4) added conditionally.
		local enableGuildTab = BFL.IsGuildTabEnabled and BFL:IsGuildTabEnabled()
		local numTopTabs = enableGuildTab and 4 or 3
		PanelTemplates_SetNumTabs(frame.FriendsTabHeader, numTopTabs)
		PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
		PanelTemplates_UpdateTabs(frame.FriendsTabHeader)
	end
end

--------------------------------------------------------------------------
-- BROADCAST FRAME SETUP
--------------------------------------------------------------------------

function FrameInitializer:SetupBroadcastFrame(frame)
	local broadcastFrame = frame
		and frame.FriendsTabHeader
		and frame.FriendsTabHeader.BattlenetFrame
		and frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame
	if not broadcastFrame then
		return
	end

	-- ToggleFrame method
	function broadcastFrame:ToggleFrame()
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
		if self:IsShown() then
			self:HideFrame()
		else
			self:ShowFrame()
		end
	end

	-- ShowFrame method
	function broadcastFrame:ShowFrame()
		if self:IsShown() then
			return
		end
		self:Show()

		-- Update broadcast text
		local _, _, _, broadcastText = BNGetInfo()
		if self.EditBox then
			self.EditBox:SetText(broadcastText or "")
		end

		-- Focus edit box
		if self.EditBox then
			self.EditBox:SetFocus()
		end
	end

	-- HideFrame method
	function broadcastFrame:HideFrame()
		if not self:IsShown() then
			return
		end
		self:Hide()

		-- Clear focus
		if self.EditBox then
			self.EditBox:ClearFocus()
		end
	end

	-- Update broadcast display
	function broadcastFrame:UpdateBroadcast()
		local _, _, _, broadcastText = BNGetInfo()
		if self.EditBox then
			self.EditBox:SetText(broadcastText or "")
		end
	end

	-- SetBroadcast method (called by Update button and Enter key)
	function broadcastFrame:SetBroadcast()
		if not self.EditBox then
			return
		end

		local text = self.EditBox:GetText() or ""

		-- Set the broadcast message using BattleNet API
		BNSetCustomMessage(text)

		-- Hide the frame
		self:HideFrame()

		-- Play sound
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
	end
end

--------------------------------------------------------------------------
-- BATTLE.NET FRAME INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeBattlenetFrame(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame then
		return
	end

	local bnetFrame = frame.FriendsTabHeader.BattlenetFrame

	-- Setup BroadcastFrame methods first
	self:SetupBroadcastFrame(frame)

	if BNFeaturesEnabled() then
		if BNConnected() then
			-- Update broadcast display
			if bnetFrame.BroadcastFrame and bnetFrame.BroadcastFrame.UpdateBroadcast then
				bnetFrame.BroadcastFrame:UpdateBroadcast()
			end

			-- Get and display BattleTag
			local _, battleTag = BNGetInfo()
			if battleTag then
				-- Format battle tag with colored suffix (like Blizzard does)
				local symbol = string.find(battleTag, "#")
				if symbol then
					local suffix = string.sub(battleTag, symbol)
					battleTag = string.sub(battleTag, 1, symbol - 1) .. "|cff416380" .. suffix .. "|r"
				end
				bnetFrame.Tag:SetText(battleTag)
				bnetFrame.Tag:Show()
				bnetFrame:Show()
			else
				bnetFrame:Hide()
			end

			bnetFrame.UnavailableLabel:Hide()
			-- Show Contacts Menu Button (11.2.5 - replaces old BroadcastButton)
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Show()
			end
		else
			-- Battle.net not connected
			bnetFrame:Show()
			bnetFrame.Tag:Hide()
			bnetFrame.UnavailableLabel:Show()
			-- Hide Contacts Menu Button when not connected
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Hide()
			end
		end
	end
end

--------------------------------------------------------------------------
-- MAIN INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:Initialize(frame)
	if self.initialized then
		return
	end
	if not frame then
		return
	end

	self:InitializeStatusDropdown(frame)
	self:InitializeSortDropdown(frame)
	self:InitializeSortDropdowns(frame)
	self:InitializeTabs(frame)
	self:InitializeBattlenetFrame(frame)

	self.initialized = true
end

-- Reset initialization state (for reloads)
function FrameInitializer:Reset()
	self.initialized = false
end

-- Register module with BFL
BFL.FrameInitializer = FrameInitializer
