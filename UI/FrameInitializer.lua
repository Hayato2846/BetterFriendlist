-- UI/FrameInitializer.lua
-- Handles UI initialization for BetterFriendlist frames
-- Extracted from BetterFriendlist.lua to reduce main file complexity

local ADDON_NAME, BFL = ...

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
	BG_COLOR_DARK = {0.1, 0.1, 0.1, 0.5},
	BG_COLOR_MEDIUM = {0.2, 0.2, 0.2, 0.5},
	
	-- Text colors
	TEXT_COLOR_GRAY = {0.5, 0.5, 0.5},
	
	-- Recursion limits
	MAX_RECURSION_DEPTH = 10,
	
	-- Statistics
	TOP_STATS_COUNT = 5,
}

-- Export to BFL namespace for use in other modules
BFL.UI = BFL.UI or {}
BFL.UI.CONSTANTS = UI_CONSTANTS

-- Module registration
local FrameInitializer = {
	name = "FrameInitializer",
	initialized = false
}

-- Current sort mode tracking (for Sort Dropdown)
local currentSortMode = "status"

--------------------------------------------------------------------------
-- STATUS DROPDOWN INITIALIZATION
-- In Classic, WowStyle1DropdownTemplate doesn't exist, so we need to
-- create a Classic-compatible dropdown or skip initialization
--------------------------------------------------------------------------

function FrameInitializer:InitializeStatusDropdown(frame)
	if not frame or not frame.FriendsTabHeader then return end
	if not frame.FriendsTabHeader.StatusDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.StatusDropdown
	
	-- Get current Battle.net status
	local bnetAFK, bnetDND = select(5, BNGetInfo())
	local bnStatus
	if bnetAFK then
		bnStatus = FRIENDS_TEXTURE_AFK
	elseif bnetDND then
		bnStatus = FRIENDS_TEXTURE_DND
	else
		bnStatus = FRIENDS_TEXTURE_ONLINE
	end
	
	-- Classic: Use UIDropDownMenu API (old-style dropdown)
	if BFL.IsClassic then
		BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for StatusDropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 38)
		UIDropDownMenu_Initialize(dropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			
			-- Online option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
			info.value = FRIENDS_TEXTURE_ONLINE
			info.func = function()
				BNSetAFK(false)
				BNSetDND(false)
				bnStatus = FRIENDS_TEXTURE_ONLINE
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_ONLINE))
			end
			info.checked = (bnStatus == FRIENDS_TEXTURE_ONLINE)
			UIDropDownMenu_AddButton(info)
			
			-- AFK option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
			info.value = FRIENDS_TEXTURE_AFK
			info.func = function()
				BNSetAFK(true)
				bnStatus = FRIENDS_TEXTURE_AFK
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_AFK))
			end
			info.checked = (bnStatus == FRIENDS_TEXTURE_AFK)
			UIDropDownMenu_AddButton(info)
			
			-- DND option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
			info.value = FRIENDS_TEXTURE_DND
			info.func = function()
				BNSetDND(true)
				bnStatus = FRIENDS_TEXTURE_DND
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_DND))
			end
			info.checked = (bnStatus == FRIENDS_TEXTURE_DND)
			UIDropDownMenu_AddButton(info)
		end)
		
		-- Set initial selected text with smaller icon and left offset
		UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", bnStatus))
		
		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local button = _G[dropdown:GetName() .. "Button"]
		if button then
			button:HookScript("OnEnter", function()
				local statusText
				if bnStatus == FRIENDS_TEXTURE_ONLINE then
					statusText = FRIENDS_LIST_AVAILABLE
				elseif bnStatus == FRIENDS_TEXTURE_AFK then
					statusText = FRIENDS_LIST_AWAY
				elseif bnStatus == FRIENDS_TEXTURE_DND then
					statusText = FRIENDS_LIST_BUSY
				end
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, statusText))
				GameTooltip:Show()
			end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function()
				local statusText
				if bnStatus == FRIENDS_TEXTURE_ONLINE then
					statusText = FRIENDS_LIST_AVAILABLE
				elseif bnStatus == FRIENDS_TEXTURE_AFK then
					statusText = FRIENDS_LIST_AWAY
				elseif bnStatus == FRIENDS_TEXTURE_DND then
					statusText = FRIENDS_LIST_BUSY
				end
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, statusText))
				GameTooltip:Show()
			end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		return
	end
	
	-- Retail mode: Use modern WowStyle1DropdownTemplate
	local function IsSelected(status)
		return bnStatus == status
	end
	
	local function SetSelected(status)
		if status ~= bnStatus then
			bnStatus = status
			
			if status == FRIENDS_TEXTURE_ONLINE then
				BNSetAFK(false)
				BNSetDND(false)
			elseif status == FRIENDS_TEXTURE_AFK then
				BNSetAFK(true)
			elseif status == FRIENDS_TEXTURE_DND then
				BNSetDND(true)
			end
		end
	end
	
	local function CreateRadio(rootDescription, text, status)
		local radio = rootDescription:CreateButton(text, function() end, status)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_STATUS")
		
		local optionText = "|T%s.tga:16:16:0:0|t %s"
		
		local onlineText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
		CreateRadio(rootDescription, onlineText, FRIENDS_TEXTURE_ONLINE)
		
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
		CreateRadio(rootDescription, afkText, FRIENDS_TEXTURE_AFK)
		
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
		CreateRadio(rootDescription, dndText, FRIENDS_TEXTURE_DND)
	end)
	
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("|T%s.tga:16:16:0:0|t", selection.data)
	end)
	
	-- Generate menu once to trigger initial selection display
	-- This ensures the dropdown shows the current status icon on load
	dropdown:GenerateMenu()
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		local statusText
		if bnStatus == FRIENDS_TEXTURE_ONLINE then
			statusText = FRIENDS_LIST_AVAILABLE
		elseif bnStatus == FRIENDS_TEXTURE_AFK then
			statusText = FRIENDS_LIST_AWAY
		elseif bnStatus == FRIENDS_TEXTURE_DND then
			statusText = FRIENDS_LIST_BUSY
		end
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
		GameTooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, statusText))
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

--------------------------------------------------------------------------
-- SORT DROPDOWN INITIALIZATION
--------------------------------------------------------------------------

-- Sort mode icons (All using Feather Icons)
local SORT_ICONS = {
	status = "Interface\\AddOns\\BetterFriendlist\\Icons\\status",      -- Feather: disc/status icon
	name = "Interface\\AddOns\\BetterFriendlist\\Icons\\name",          -- Feather: type/text icon
	level = "Interface\\AddOns\\BetterFriendlist\\Icons\\level",        -- Feather: bar-chart icon
	zone = "Interface\\AddOns\\BetterFriendlist\\Icons\\zone",          -- Feather: map-pin icon
	activity = "Interface\\AddOns\\BetterFriendlist\\Icons\\activity",  -- Feather: activity pulse
	game = "Interface\\AddOns\\BetterFriendlist\\Icons\\game",          -- Feather: target/game icon
	faction = "Interface\\AddOns\\BetterFriendlist\\Icons\\faction",    -- Feather: shield icon
	guild = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild",        -- Feather: users/group icon
	class = "Interface\\AddOns\\BetterFriendlist\\Icons\\class",        -- Feather: award icon
	realm = "Interface\\AddOns\\BetterFriendlist\\Icons\\realm",        -- Feather: server icon
	none = "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up"            -- X icon for none
}

-- Sort mode display names (PHASE 9B+9C: Added 5 new sort options)
local SORT_NAMES = {
	status = "Status",
	name = "Name",
	level = "Level",
	zone = "Zone",
	game = "Game",      -- PHASE 9B
	faction = "Faction",  -- PHASE 9C
	guild = "Guild",    -- PHASE 9C
	class = "Class",    -- PHASE 9C
	realm = "Realm"     -- PHASE 9C
}

-- Helper: Format icon for display (handles both texture paths and Font Awesome strings)
local function FormatIconText(iconData, text)
	-- Check if it's a texture path (starts with "Interface")
	if type(iconData) == "string" and iconData:match("^Interface") then
		return string.format("\124T%s:16:16:0:2\124t %s", iconData, text)
	else
		-- Font Awesome icon - use directly with color
		return string.format("|cFF00CCFF%s|r %s", iconData, text)
	end
end

-- Helper: Format icon only for dropdown button
local function FormatIconOnly(iconData)
	if type(iconData) == "string" and iconData:match("^Interface") then
		return string.format("\124T%s:16:16:0:2\124t", iconData)
	else
		-- Font Awesome icon
		return string.format("|cFF00CCFF%s|r", iconData)
	end
end

function FrameInitializer:InitializeSortDropdown(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.SortDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.SortDropdown
	
	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for SortDropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 60)
		UIDropDownMenu_Initialize(dropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddSortOption(sortMode, label, icon)
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function()
					currentSortMode = sortMode
					UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", icon))
					-- Notify main file to update display
					if _G.UpdateFriendsList then _G.UpdateFriendsList() end
					if _G.UpdateFriendsDisplay then _G.UpdateFriendsDisplay() end
				end
				info.checked = (currentSortMode == sortMode)
				UIDropDownMenu_AddButton(info)
			end
			
			AddSortOption("status", "Sort by Status", SORT_ICONS.status)
			AddSortOption("name", "Sort by Name", SORT_ICONS.name)
			AddSortOption("level", "Sort by Level", SORT_ICONS.level)
			AddSortOption("zone", "Sort by Zone", SORT_ICONS.zone)
		end)
		
		-- Set initial selected text
		local currentIcon = SORT_ICONS[currentSortMode] or SORT_ICONS.status
		UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", currentIcon))
		
		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]
		
		if button then
			button:HookScript("OnEnter", function()
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText("Sort: " .. sortName)
				GameTooltip:Show()
			end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function()
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText("Sort: " .. sortName)
				GameTooltip:Show()
			end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		return
	end
	
	local function IsSelected(sortMode)
		return currentSortMode == sortMode
	end
	
	local function SetSelected(sortMode)
		if sortMode ~= currentSortMode then
			currentSortMode = sortMode
			-- Notify main file to update display
			if _G.UpdateFriendsList then _G.UpdateFriendsList() end
			if _G.UpdateFriendsDisplay then _G.UpdateFriendsDisplay() end
		end
	end
	
	local function CreateRadio(rootDescription, text, sortMode)
		local radio = rootDescription:CreateButton(text, function() end, sortMode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	-- Narrower width to match QuickFilters style
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)
	
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_SORT")
		
		-- Format for icon + text in menu
		local optionText = "\124T%s:16:16:0:0\124t %s"
		
		-- Create sort options with icons
		local statusText = string.format(optionText, SORT_ICONS.status, "Sort by Status")
		CreateRadio(rootDescription, statusText, "status")
		
		local nameText = string.format(optionText, SORT_ICONS.name, "Sort by Name")
		CreateRadio(rootDescription, nameText, "name")
		
		local levelText = string.format(optionText, SORT_ICONS.level, "Sort by Level")
		CreateRadio(rootDescription, levelText, "level")
		
		local zoneText = string.format(optionText, SORT_ICONS.zone, "Sort by Zone")
		CreateRadio(rootDescription, zoneText, "zone")
	end)
	
	-- SetSelectionTranslator: Show icon only (like QuickFilters)
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("\124T%s:16:16:0:0\124t", SORT_ICONS[selection.data])
	end)
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		local sortName = SORT_NAMES[currentSortMode] or "Status"
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
		GameTooltip:SetText("Sort: " .. sortName)
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Initialize primary and secondary sort dropdowns
function FrameInitializer:InitializeSortDropdowns(frame)
	if not frame or not frame.FriendsTabHeader then return end
	
	local header = frame.FriendsTabHeader
	if not header.PrimarySortDropdown or not header.SecondarySortDropdown then return end
	
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then return end

	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for Primary/Secondary Sort dropdowns")
		
		-- Primary Sort Dropdown
		local primaryDropdown = header.PrimarySortDropdown
		UIDropDownMenu_SetWidth(primaryDropdown, 70)
		UIDropDownMenu_Initialize(primaryDropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddPrimaryOption(sortMode, label, icon)
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function()
					FriendsList:SetSortMode(sortMode)
					FriendsList:RenderDisplay()
					UIDropDownMenu_SetText(primaryDropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				end
				-- Check against DB/Module state
				local DB = BFL:GetModule("DB")
				local db = DB and DB:Get() or {}
				local currentSort = db.primarySort or FriendsList.sortMode or "status"
				info.checked = (currentSort == sortMode)
				UIDropDownMenu_AddButton(info)
			end
			
			AddPrimaryOption("status", "Sort by Status", SORT_ICONS.status)
			AddPrimaryOption("name", "Sort by Name", SORT_ICONS.name)
			AddPrimaryOption("level", "Sort by Level", SORT_ICONS.level)
			AddPrimaryOption("zone", "Sort by Zone", SORT_ICONS.zone)
			AddPrimaryOption("game", "Sort by Game", SORT_ICONS.game)
			AddPrimaryOption("faction", "Sort by Faction", SORT_ICONS.faction)
			AddPrimaryOption("guild", "Sort by Guild", SORT_ICONS.guild)
			AddPrimaryOption("class", "Sort by Class", SORT_ICONS.class)
			AddPrimaryOption("realm", "Sort by Realm", SORT_ICONS.realm)
		end)
		
		-- Set initial text for Primary
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentPrimary = db.primarySort or FriendsList.sortMode or "status"
		local primaryIcon = SORT_ICONS[currentPrimary] or SORT_ICONS.status
		UIDropDownMenu_SetText(primaryDropdown, string.format("|T%s:14:14:-2:-2|t", primaryIcon))

		-- Secondary Sort Dropdown
		local secondaryDropdown = header.SecondarySortDropdown
		UIDropDownMenu_SetWidth(secondaryDropdown, 70)
		UIDropDownMenu_Initialize(secondaryDropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddSecondaryOption(sortMode, label, icon)
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function()
					FriendsList:SetSecondarySortMode(sortMode)
					FriendsList:RenderDisplay()
					UIDropDownMenu_SetText(secondaryDropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				end
				
				local DB = BFL:GetModule("DB")
				local db = DB and DB:Get() or {}
				local currentSort = db.secondarySort or FriendsList.secondarySort or "name"
				info.checked = (currentSort == sortMode)
				UIDropDownMenu_AddButton(info)
			end
			
			AddSecondaryOption("none", "None", SORT_ICONS.none)
			AddSecondaryOption("name", "then by Name", SORT_ICONS.name)
			AddSecondaryOption("level", "then by Level", SORT_ICONS.level)
			AddSecondaryOption("zone", "then by Zone", SORT_ICONS.zone)
			AddSecondaryOption("activity", "then by Activity", SORT_ICONS.activity)
			AddSecondaryOption("game", "then by Game", SORT_ICONS.game)
			AddSecondaryOption("faction", "then by Faction", SORT_ICONS.faction)
			AddSecondaryOption("guild", "then by Guild", SORT_ICONS.guild)
			AddSecondaryOption("class", "then by Class", SORT_ICONS.class)
			AddSecondaryOption("realm", "then by Realm", SORT_ICONS.realm)
		end)
		
		-- Set initial text for Secondary
		local currentSecondary = db.secondarySort or FriendsList.secondarySort or "name"
		local secondaryIcon = SORT_ICONS[currentSecondary] or SORT_ICONS.name
		UIDropDownMenu_SetText(secondaryDropdown, string.format("|T%s:14:14:-2:-2|t", secondaryIcon))
		
		-- Setup tooltips for Classic
		-- Hook buttons as they consume mouse events
		local primaryButton = _G[primaryDropdown:GetName() .. "Button"]
		if primaryButton then
			primaryButton:HookScript("OnEnter", function()
				local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
				GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Primary Sort: " .. sortName)
				GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			primaryButton:HookScript("OnLeave", GameTooltip_Hide)
		else
			primaryDropdown:SetScript("OnEnter", function()
				local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
				GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Primary Sort: " .. sortName)
				GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			primaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		local secondaryButton = _G[secondaryDropdown:GetName() .. "Button"]
		if secondaryButton then
			secondaryButton:HookScript("OnEnter", function()
				local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
				GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Secondary Sort: " .. sortName)
				GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			secondaryButton:HookScript("OnLeave", GameTooltip_Hide)
		else
			secondaryDropdown:SetScript("OnEnter", function()
				local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
				GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Secondary Sort: " .. sortName)
				GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			secondaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		return
	end
	
	-- Initialize Primary Sort Dropdown
	local primaryDropdown = header.PrimarySortDropdown
	
	local function IsPrimarySelected(sortMode)
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentSort = db.primarySort or FriendsList.sortMode or "status"
		return currentSort == sortMode
	end
	
	local function SetPrimarySelected(sortMode)
		FriendsList:SetSortMode(sortMode)
		FriendsList:RenderDisplay()
	end
	
	local function CreatePrimaryRadio(rootDescription, text, sortMode)
		local radio = rootDescription:CreateButton(text, function() end, sortMode)
		radio:SetIsSelected(IsPrimarySelected)
		radio:SetResponder(SetPrimarySelected)
	end
	
	primaryDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_PRIMARY_SORT")
		
		-- Create sort options with icons (using helper function)
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.status, "Sort by Status"), "status")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, "Sort by Name"), "name")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, "Sort by Level"), "level")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, "Sort by Zone"), "zone")
		
		-- PHASE 9B+9C: Add 5 new sort options
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, "Sort by Game"), "game")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, "Sort by Faction"), "faction")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, "Sort by Guild"), "guild")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, "Sort by Class"), "class")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, "Sort by Realm"), "realm")
	end)
	
	-- Show icon only (like QuickFilters)
	primaryDropdown:SetSelectionTranslator(function(selection)
		return FormatIconOnly(SORT_ICONS[selection.data])
	end)
	
	-- Generate menu once to trigger initial selection display
	primaryDropdown:GenerateMenu()
	
	primaryDropdown:SetScript("OnEnter", function()
		local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
		GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Primary Sort: " .. sortName)
		GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	primaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
	
	-- Initialize Secondary Sort Dropdown
	local secondaryDropdown = header.SecondarySortDropdown
	
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
	
	local function CreateSecondaryRadio(rootDescription, text, sortMode)
		local radio = rootDescription:CreateButton(text, function() end, sortMode)
		radio:SetIsSelected(IsSecondarySelected)
		radio:SetResponder(SetSecondarySelected)
	end
	
	secondaryDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_SECONDARY_SORT")
		
		-- Create secondary sort options with icons (using helper function)
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.none, "None"), "none")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, "then by Name"), "name")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, "then by Level"), "level")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, "then by Zone"), "zone")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.activity, "then by Activity"), "activity")
		
		-- PHASE 9B+9C: Add 5 new sort options
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, "then by Game"), "game")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, "then by Faction"), "faction")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, "then by Guild"), "guild")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, "then by Class"), "class")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, "then by Realm"), "realm")
	end)
	
	-- Show icon only (X for none, sort icons for others)
	secondaryDropdown:SetSelectionTranslator(function(selection)
		local iconData = SORT_ICONS[selection.data] or SORT_ICONS.name
		return FormatIconOnly(iconData)
	end)
	
	-- Generate menu once to trigger initial selection display
	secondaryDropdown:GenerateMenu()
	
	secondaryDropdown:SetScript("OnEnter", function()
		local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
		GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Secondary Sort: " .. sortName)
		GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	secondaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
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
	if not frame or not frame.FriendsTabHeader then return end
	
	-- Classic: Only Friends tab is visible, but we need to tell PanelTemplates about it
	-- In Classic, Tab2 and Tab3 exist in XML but are hidden by HideClassicOnlyTabs()
	if BFL.IsClassic then
		-- In Classic, we only have 1 active tab (Friends)
		-- Tab2 and Tab3 exist in XML but are already positioned and will be hidden
		-- IMPORTANT: Do NOT call PanelTemplates_SetTab as it triggers PanelTemplates_UpdateTabs
		-- which tries to iterate over all tabs (including hidden ones)
		frame.FriendsTabHeader.numTabs = 1
		frame.FriendsTabHeader.selectedTab = 1
		-- Manually select Tab1 (PanelTopTabButtonTemplate uses visual state, not SetChecked)
		if frame.FriendsTabHeader.Tab1 then
			-- Show tab as selected by hiding the tab's Left texture (makes it look pressed)
			if frame.FriendsTabHeader.Tab1.Left then
				frame.FriendsTabHeader.Tab1.Left:Hide()
			end
			if frame.FriendsTabHeader.Tab1.LeftDisabled then
				frame.FriendsTabHeader.Tab1.LeftDisabled:Show()
			end
		end
	else
		-- Retail: Set up the tabs on the FriendsTabHeader (11.2.5: 3 tabs - Friends, Recent Allies, RAF. Sort tab removed.)
		PanelTemplates_SetNumTabs(frame.FriendsTabHeader, 3)
		PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
		PanelTemplates_UpdateTabs(frame.FriendsTabHeader)
	end
end

--------------------------------------------------------------------------
-- BROADCAST FRAME SETUP
--------------------------------------------------------------------------

function FrameInitializer:SetupBroadcastFrame(frame)
	local broadcastFrame = frame and frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame and frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame
	if not broadcastFrame then return end
	
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
		if self:IsShown() then return end
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
		if not self:IsShown() then return end
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
		if not self.EditBox then return end
		
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
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame then return end
	
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
					battleTag = string.sub(battleTag, 1, symbol - 1).."|cff416380"..suffix.."|r"
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
	if self.initialized then return end
	if not frame then return end
	
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
