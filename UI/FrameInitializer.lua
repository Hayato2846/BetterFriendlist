--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua"); -- UI/FrameInitializer.lua
-- Handles UI initialization for BetterFriendlist frames
-- Extracted from BetterFriendlist.lua to reduce main file complexity

local ADDON_NAME, BFL = ...
local L = BFL_LOCALE  -- Localization shortcut

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

function FrameInitializer:InitializeStatusDropdown(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:InitializeStatusDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:82:0");
	if not frame or not frame.FriendsTabHeader then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeStatusDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:82:0"); return end
	if not frame.FriendsTabHeader.StatusDropdown then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeStatusDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:82:0"); return end
	
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
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for StatusDropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 38)
		UIDropDownMenu_Initialize(dropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:104:38");
			local info = UIDropDownMenu_CreateInfo()
			
			-- Online option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
			info.value = FRIENDS_TEXTURE_ONLINE
			info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:110:15");
				BNSetAFK(false)
				BNSetDND(false)
				bnStatus = FRIENDS_TEXTURE_ONLINE
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_ONLINE))
			Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:110:15"); end
			info.checked = (bnStatus == FRIENDS_TEXTURE_ONLINE)
			UIDropDownMenu_AddButton(info)
			
			-- AFK option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
			info.value = FRIENDS_TEXTURE_AFK
			info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:122:15");
				BNSetAFK(true)
				bnStatus = FRIENDS_TEXTURE_AFK
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_AFK))
			Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:122:15"); end
			info.checked = (bnStatus == FRIENDS_TEXTURE_AFK)
			UIDropDownMenu_AddButton(info)
			
			-- DND option
			info.text = string.format("|T%s.tga:14:14:0:0|t %s", FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
			info.value = FRIENDS_TEXTURE_DND
			info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:133:15");
				BNSetDND(true)
				bnStatus = FRIENDS_TEXTURE_DND
				UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", FRIENDS_TEXTURE_DND))
			Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:133:15"); end
			info.checked = (bnStatus == FRIENDS_TEXTURE_DND)
			UIDropDownMenu_AddButton(info)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:104:38"); end)
		
		-- Set initial selected text with smaller icon and left offset
		UIDropDownMenu_SetText(dropdown, string.format("|T%s.tga:14:14:-2:-2|t", bnStatus))
		
		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local button = _G[dropdown:GetName() .. "Button"]
		if button then
			button:HookScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:149:32");
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
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:149:32"); end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:165:33");
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
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:165:33"); end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeStatusDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:82:0"); return
	end
	
	-- Retail mode: Use modern WowStyle1DropdownTemplate
	local function IsSelected(status) Perfy_Trace(Perfy_GetTime(), "Enter", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:186:7");
		return Perfy_Trace_Passthrough("Leave", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:186:7", bnStatus == status)
	end
	
	local function SetSelected(status) Perfy_Trace(Perfy_GetTime(), "Enter", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:190:7");
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
	Perfy_Trace(Perfy_GetTime(), "Leave", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:190:7"); end
	
	local function CreateRadio(rootDescription, text, status) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:205:7");
		local radio = rootDescription:CreateButton(text, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:206:51"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:206:51"); end, status)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:205:7"); end
	
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)
	dropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:212:20");
		rootDescription:SetTag("MENU_FRIENDS_STATUS")
		
		local optionText = "|T%s.tga:16:16:0:0|t %s"
		
		local onlineText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
		CreateRadio(rootDescription, onlineText, FRIENDS_TEXTURE_ONLINE)
		
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
		CreateRadio(rootDescription, afkText, FRIENDS_TEXTURE_AFK)
		
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
		CreateRadio(rootDescription, dndText, FRIENDS_TEXTURE_DND)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:212:20"); end)
	
	dropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:227:33");
		return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:227:33", string.format("|T%s.tga:16:16:0:0|t", selection.data))
	end)
	
	-- Generate menu once to trigger initial selection display
	-- This ensures the dropdown shows the current status icon on load
	dropdown:GenerateMenu()
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:236:31");
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
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:236:31"); end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeStatusDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:82:0"); end

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
	status = L.SORT_STATUS,
	name = L.SORT_NAME,
	level = L.SORT_LEVEL,
	zone = L.SORT_ZONE,
	game = L.SORT_GAME,      -- PHASE 9B
	faction = L.SORT_FACTION,  -- PHASE 9C
	guild = L.SORT_GUILD,    -- PHASE 9C
	class = L.SORT_CLASS,    -- PHASE 9C
	realm = L.SORT_REALM     -- PHASE 9C
}

-- Helper: Format icon for display (handles both texture paths and Font Awesome strings)
local function FormatIconText(iconData, text) Perfy_Trace(Perfy_GetTime(), "Enter", "FormatIconText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:286:6");
	-- Check if it's a texture path (starts with "Interface")
	if type(iconData) == "string" and iconData:match("^Interface") then
		return Perfy_Trace_Passthrough("Leave", "FormatIconText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:286:6", string.format("\124T%s:16:16:0:2\124t %s", iconData, text))
	else
		-- Font Awesome icon - use directly with color
		return Perfy_Trace_Passthrough("Leave", "FormatIconText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:286:6", string.format("|cFF00CCFF%s|r %s", iconData, text))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FormatIconText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:286:6"); end

-- Helper: Format icon only for dropdown button
local function FormatIconOnly(iconData) Perfy_Trace(Perfy_GetTime(), "Enter", "FormatIconOnly file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:297:6");
	if type(iconData) == "string" and iconData:match("^Interface") then
		return Perfy_Trace_Passthrough("Leave", "FormatIconOnly file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:297:6", string.format("\124T%s:16:16:0:2\124t", iconData))
	else
		-- Font Awesome icon
		return Perfy_Trace_Passthrough("Leave", "FormatIconOnly file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:297:6", string.format("|cFF00CCFF%s|r", iconData))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "FormatIconOnly file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:297:6"); end

function FrameInitializer:InitializeSortDropdown(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:InitializeSortDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:306:0");
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.SortDropdown then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:306:0"); return end
	
	local dropdown = frame.FriendsTabHeader.SortDropdown
	
	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for SortDropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 60)
		UIDropDownMenu_Initialize(dropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:316:38");
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddSortOption(sortMode, label, icon) Perfy_Trace(Perfy_GetTime(), "Enter", "AddSortOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:319:9");
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:322:16");
					currentSortMode = sortMode
					UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", icon))
					-- Notify main file to update display
					if _G.UpdateFriendsList then _G.UpdateFriendsList() end
					if _G.UpdateFriendsDisplay then _G.UpdateFriendsDisplay() end
				Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:322:16"); end
				info.checked = (currentSortMode == sortMode)
				UIDropDownMenu_AddButton(info)
			Perfy_Trace(Perfy_GetTime(), "Leave", "AddSortOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:319:9"); end
			
			AddSortOption("status", L.SORT_STATUS, SORT_ICONS.status)
			AddSortOption("name", L.SORT_NAME, SORT_ICONS.name)
			AddSortOption("level", L.SORT_LEVEL, SORT_ICONS.level)
			AddSortOption("zone", L.SORT_ZONE, SORT_ICONS.zone)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:316:38"); end)
		
		-- Set initial selected text
		local currentIcon = SORT_ICONS[currentSortMode] or SORT_ICONS.status
		UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", currentIcon))
		
		-- Setup tooltip for Classic
		-- Hook button as it consumes mouse events
		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]
		
		if button then
			button:HookScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:350:32");
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText("Sort: " .. sortName)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:350:32"); end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:358:33");
				local sortName = SORT_NAMES[currentSortMode] or "Status"
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
				GameTooltip:SetText("Sort: " .. sortName)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:358:33"); end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:306:0"); return
	end
	
	local function IsSelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:370:7");
		return Perfy_Trace_Passthrough("Leave", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:370:7", currentSortMode == sortMode)
	end
	
	local function SetSelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:374:7");
		if sortMode ~= currentSortMode then
			currentSortMode = sortMode
			-- Notify main file to update display
			if _G.UpdateFriendsList then _G.UpdateFriendsList() end
			if _G.UpdateFriendsDisplay then _G.UpdateFriendsDisplay() end
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:374:7"); end
	
	local function CreateRadio(rootDescription, text, sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:383:7");
		local radio = rootDescription:CreateButton(text, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:384:51"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:384:51"); end, sortMode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:383:7"); end
	
	-- Narrower width to match QuickFilters style
	dropdown:SetWidth(UI_CONSTANTS.DROPDOWN_WIDTH)
	
	dropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:392:20");
		rootDescription:SetTag("MENU_FRIENDS_SORT")
		
		-- Format for icon + text in menu
		local optionText = "\124T%s:16:16:0:0\124t %s"
		
		-- Create sort options with icons
		local statusText = string.format(optionText, SORT_ICONS.status, L.SORT_STATUS)
		CreateRadio(rootDescription, statusText, "status")
		
		local nameText = string.format(optionText, SORT_ICONS.name, L.SORT_NAME)
		CreateRadio(rootDescription, nameText, "name")
		
		local levelText = string.format(optionText, SORT_ICONS.level, L.SORT_LEVEL)
		CreateRadio(rootDescription, levelText, "level")
		
		local zoneText = string.format(optionText, SORT_ICONS.zone, L.SORT_ZONE)
		CreateRadio(rootDescription, zoneText, "zone")
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:392:20"); end)
	
	-- SetSelectionTranslator: Show icon only (like QuickFilters)
	dropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:413:33");
		return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:413:33", string.format("\124T%s:16:16:0:0\124t", SORT_ICONS[selection.data]))
	end)
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:418:31");
		local sortName = SORT_NAMES[currentSortMode] or "Status"
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", UI_CONSTANTS.TOOLTIP_ANCHOR_Y, 0)
		GameTooltip:SetText("Sort: " .. sortName)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:418:31"); end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:306:0"); end

-- Initialize primary and secondary sort dropdowns
function FrameInitializer:InitializeSortDropdowns(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0");
	if not frame or not frame.FriendsTabHeader then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0"); return end
	
	local header = frame.FriendsTabHeader
	if not header.PrimarySortDropdown or not header.SecondarySortDropdown then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0"); return end
	
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0"); return end

	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		-- BFL:DebugPrint("|cff00ffffFrameInitializer:|r Classic mode - using UIDropDownMenu for Primary/Secondary Sort dropdowns")
		
		-- Primary Sort Dropdown
		local primaryDropdown = header.PrimarySortDropdown
		UIDropDownMenu_SetWidth(primaryDropdown, 70)
		UIDropDownMenu_Initialize(primaryDropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:444:45");
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddPrimaryOption(sortMode, label, icon) Perfy_Trace(Perfy_GetTime(), "Enter", "AddPrimaryOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:447:9");
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:450:16");
					FriendsList:SetSortMode(sortMode)
					FriendsList:RenderDisplay()
					UIDropDownMenu_SetText(primaryDropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:450:16"); end
				-- Check against DB/Module state
				local DB = BFL:GetModule("DB")
				local db = DB and DB:Get() or {}
				local currentSort = db.primarySort or FriendsList.sortMode or "status"
				info.checked = (currentSort == sortMode)
				UIDropDownMenu_AddButton(info)
			Perfy_Trace(Perfy_GetTime(), "Leave", "AddPrimaryOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:447:9"); end
			
			AddPrimaryOption("status", L.SORT_STATUS, SORT_ICONS.status)
			AddPrimaryOption("name", L.SORT_NAME, SORT_ICONS.name)
			AddPrimaryOption("level", L.SORT_LEVEL, SORT_ICONS.level)
			AddPrimaryOption("zone", L.SORT_ZONE, SORT_ICONS.zone)
			AddPrimaryOption("game", L.SORT_GAME, SORT_ICONS.game)
			AddPrimaryOption("faction", L.SORT_FACTION, SORT_ICONS.faction)
			AddPrimaryOption("guild", L.SORT_GUILD, SORT_ICONS.guild)
			AddPrimaryOption("class", L.SORT_CLASS, SORT_ICONS.class)
			AddPrimaryOption("realm", L.SORT_REALM, SORT_ICONS.realm)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:444:45"); end)
		
		-- Set initial text for Primary
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentPrimary = db.primarySort or FriendsList.sortMode or "status"
		local primaryIcon = SORT_ICONS[currentPrimary] or SORT_ICONS.status
		UIDropDownMenu_SetText(primaryDropdown, string.format("|T%s:14:14:-2:-2|t", primaryIcon))

		-- Secondary Sort Dropdown
		local secondaryDropdown = header.SecondarySortDropdown
		UIDropDownMenu_SetWidth(secondaryDropdown, 70)
		UIDropDownMenu_Initialize(secondaryDropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:484:47");
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddSecondaryOption(sortMode, label, icon) Perfy_Trace(Perfy_GetTime(), "Enter", "AddSecondaryOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:487:9");
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = sortMode
				info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:490:16");
					FriendsList:SetSecondarySortMode(sortMode)
					FriendsList:RenderDisplay()
					UIDropDownMenu_SetText(secondaryDropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:490:16"); end
				
				local DB = BFL:GetModule("DB")
				local db = DB and DB:Get() or {}
				local currentSort = db.secondarySort or FriendsList.secondarySort or "name"
				info.checked = (currentSort == sortMode)
				UIDropDownMenu_AddButton(info)
			Perfy_Trace(Perfy_GetTime(), "Leave", "AddSecondaryOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:487:9"); end
			
			AddSecondaryOption("none", L.SORT_NONE, SORT_ICONS.none)
			AddSecondaryOption("name", L.SORT_NAME, SORT_ICONS.name)
			AddSecondaryOption("level", L.SORT_LEVEL, SORT_ICONS.level)
			AddSecondaryOption("zone", L.SORT_ZONE, SORT_ICONS.zone)
			AddSecondaryOption("activity", L.SORT_ACTIVITY, SORT_ICONS.activity)
			AddSecondaryOption("game", L.SORT_GAME, SORT_ICONS.game)
			AddSecondaryOption("faction", L.SORT_FACTION, SORT_ICONS.faction)
			AddSecondaryOption("guild", L.SORT_GUILD, SORT_ICONS.guild)
			AddSecondaryOption("class", L.SORT_CLASS, SORT_ICONS.class)
			AddSecondaryOption("realm", L.SORT_REALM, SORT_ICONS.realm)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:484:47"); end)
		
		-- Set initial text for Secondary
		local currentSecondary = db.secondarySort or FriendsList.secondarySort or "name"
		local secondaryIcon = SORT_ICONS[currentSecondary] or SORT_ICONS.name
		UIDropDownMenu_SetText(secondaryDropdown, string.format("|T%s:14:14:-2:-2|t", secondaryIcon))
		
		-- Setup tooltips for Classic
		-- Hook buttons as they consume mouse events
		local primaryButton = _G[primaryDropdown:GetName() .. "Button"]
		if primaryButton then
			primaryButton:HookScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:524:39");
				local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
				GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Primary Sort: " .. sortName)
				GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:524:39"); end)
			primaryButton:HookScript("OnLeave", GameTooltip_Hide)
		else
			primaryDropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:533:40");
				local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
				GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Primary Sort: " .. sortName)
				GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:533:40"); end)
			primaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		local secondaryButton = _G[secondaryDropdown:GetName() .. "Button"]
		if secondaryButton then
			secondaryButton:HookScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:545:41");
				local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
				GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Secondary Sort: " .. sortName)
				GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:545:41"); end)
			secondaryButton:HookScript("OnLeave", GameTooltip_Hide)
		else
			secondaryDropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:554:42");
				local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
				GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
				GameTooltip:SetText("Secondary Sort: " .. sortName)
				GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:554:42"); end)
			secondaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0"); return
	end
	
	-- Initialize Primary Sort Dropdown
	local primaryDropdown = header.PrimarySortDropdown
	
	local function IsPrimarySelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "IsPrimarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:570:7");
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentSort = db.primarySort or FriendsList.sortMode or "status"
		return Perfy_Trace_Passthrough("Leave", "IsPrimarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:570:7", currentSort == sortMode)
	end
	
	local function SetPrimarySelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "SetPrimarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:578:7");
		FriendsList:SetSortMode(sortMode)
		FriendsList:RenderDisplay()
	Perfy_Trace(Perfy_GetTime(), "Leave", "SetPrimarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:578:7"); end
	
	local function CreatePrimaryRadio(rootDescription, text, sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "CreatePrimaryRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:583:7");
		local radio = rootDescription:CreateButton(text, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:584:51"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:584:51"); end, sortMode)
		radio:SetIsSelected(IsPrimarySelected)
		radio:SetResponder(SetPrimarySelected)
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreatePrimaryRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:583:7"); end
	
	primaryDropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:589:27");
		rootDescription:SetTag("MENU_FRIENDS_PRIMARY_SORT")
		
		-- Create sort options with icons (using helper function)
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.status, L.SORT_STATUS), "status")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, L.SORT_NAME), "name")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, L.SORT_LEVEL), "level")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, L.SORT_ZONE), "zone")
		
		-- PHASE 9B+9C: Add 5 new sort options
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, L.SORT_GAME), "game")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, L.SORT_FACTION), "faction")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, L.SORT_GUILD), "guild")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, L.SORT_CLASS), "class")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, L.SORT_REALM), "realm")
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:589:27"); end)
	
	-- Show icon only (like QuickFilters)
	primaryDropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:607:40");
		return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:607:40", FormatIconOnly(SORT_ICONS[selection.data]))
	end)
	
	-- Generate menu once to trigger initial selection display
	primaryDropdown:GenerateMenu()
	
	primaryDropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:614:38");
		local sortName = SORT_NAMES[FriendsList.sortMode] or "Status"
		GameTooltip:SetOwner(primaryDropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Primary Sort: " .. sortName)
		GameTooltip:AddLine("Main sorting criterion for friends list.", 1, 1, 1, true)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:614:38"); end)
	primaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
	
	-- Initialize Secondary Sort Dropdown
	local secondaryDropdown = header.SecondarySortDropdown
	
	local function IsSecondarySelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "IsSecondarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:626:7");
		-- Always read from DB when checking selection
		local DB = BFL:GetModule("DB")
		local db = DB and DB:Get() or {}
		local currentSort = db.secondarySort or FriendsList.secondarySort or "name"
		return Perfy_Trace_Passthrough("Leave", "IsSecondarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:626:7", currentSort == sortMode)
	end
	
	local function SetSecondarySelected(sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "SetSecondarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:634:7");
		FriendsList:SetSecondarySortMode(sortMode)
		FriendsList:RenderDisplay()
	Perfy_Trace(Perfy_GetTime(), "Leave", "SetSecondarySelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:634:7"); end
	
	local function CreateSecondaryRadio(rootDescription, text, sortMode) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateSecondaryRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:639:7");
		local radio = rootDescription:CreateButton(text, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:640:51"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:640:51"); end, sortMode)
		radio:SetIsSelected(IsSecondarySelected)
		radio:SetResponder(SetSecondarySelected)
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreateSecondaryRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:639:7"); end
	
	secondaryDropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:645:29");
		rootDescription:SetTag("MENU_FRIENDS_SECONDARY_SORT")
		
		-- Create secondary sort options with icons (using helper function)
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.none, L.SORT_NONE), "none")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, L.SORT_NAME), "name")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, L.SORT_LEVEL), "level")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, L.SORT_ZONE), "zone")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.activity, L.SORT_ACTIVITY), "activity")
		
		-- PHASE 9B+9C: Add 5 new sort options
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, L.SORT_GAME), "game")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, L.SORT_FACTION), "faction")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, L.SORT_GUILD), "guild")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, L.SORT_CLASS), "class")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, L.SORT_REALM), "realm")
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:645:29"); end)
	
	-- Show icon only (X for none, sort icons for others)
	secondaryDropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:664:42");
		local iconData = SORT_ICONS[selection.data] or SORT_ICONS.name
		return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:664:42", FormatIconOnly(iconData))
	end)
	
	-- Generate menu once to trigger initial selection display
	secondaryDropdown:GenerateMenu()
	
	secondaryDropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:672:40");
		local sortName = FriendsList.secondarySort == "none" and "None" or (SORT_NAMES[FriendsList.secondarySort] or "Name")
		GameTooltip:SetOwner(secondaryDropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Secondary Sort: " .. sortName)
		GameTooltip:AddLine("Sort by this when primary values are equal.", 1, 1, 1, true)
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:672:40"); end)
	secondaryDropdown:SetScript("OnLeave", GameTooltip_Hide)
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeSortDropdowns file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:428:0"); end

-- Get current sort mode (for external access)
function FrameInitializer:GetSortMode() Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:GetSortMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:683:0");
	Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:GetSortMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:683:0"); return currentSortMode
end

-- Set current sort mode (for external access)
function FrameInitializer:SetSortMode(mode) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:SetSortMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:688:0");
	currentSortMode = mode or "status"
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:SetSortMode file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:688:0"); end

--------------------------------------------------------------------------
-- TABS INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeTabs(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:InitializeTabs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:696:0");
	if not frame or not frame.FriendsTabHeader then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeTabs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:696:0"); return end
	
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
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeTabs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:696:0"); end

--------------------------------------------------------------------------
-- BROADCAST FRAME SETUP
--------------------------------------------------------------------------

function FrameInitializer:SetupBroadcastFrame(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:SetupBroadcastFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:730:0");
	local broadcastFrame = frame and frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame and frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame
	if not broadcastFrame then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:SetupBroadcastFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:730:0"); return end
	
	-- ToggleFrame method
	function broadcastFrame:ToggleFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "broadcastFrame:ToggleFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:735:1");
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
		if self:IsShown() then
			self:HideFrame()
		else
			self:ShowFrame()
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:ToggleFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:735:1"); end
	
	-- ShowFrame method
	function broadcastFrame:ShowFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "broadcastFrame:ShowFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:745:1");
		if self:IsShown() then Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:ShowFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:745:1"); return end
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
	Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:ShowFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:745:1"); end
	
	-- HideFrame method
	function broadcastFrame:HideFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "broadcastFrame:HideFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:762:1");
		if not self:IsShown() then Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:HideFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:762:1"); return end
		self:Hide()
		
		-- Clear focus
		if self.EditBox then
			self.EditBox:ClearFocus()
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:HideFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:762:1"); end
	
	-- Update broadcast display
	function broadcastFrame:UpdateBroadcast() Perfy_Trace(Perfy_GetTime(), "Enter", "broadcastFrame:UpdateBroadcast file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:773:1");
		local _, _, _, broadcastText = BNGetInfo()
		if self.EditBox then
			self.EditBox:SetText(broadcastText or "")
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:UpdateBroadcast file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:773:1"); end
	
	-- SetBroadcast method (called by Update button and Enter key)
	function broadcastFrame:SetBroadcast() Perfy_Trace(Perfy_GetTime(), "Enter", "broadcastFrame:SetBroadcast file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:781:1");
		if not self.EditBox then Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:SetBroadcast file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:781:1"); return end
		
		local text = self.EditBox:GetText() or ""
		
		-- Set the broadcast message using BattleNet API
		BNSetCustomMessage(text)
		
		-- Hide the frame
		self:HideFrame()
		
		-- Play sound
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
	Perfy_Trace(Perfy_GetTime(), "Leave", "broadcastFrame:SetBroadcast file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:781:1"); end
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:SetupBroadcastFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:730:0"); end

--------------------------------------------------------------------------
-- BATTLE.NET FRAME INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeBattlenetFrame(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:InitializeBattlenetFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:801:0");
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeBattlenetFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:801:0"); return end
	
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
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:InitializeBattlenetFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:801:0"); end

--------------------------------------------------------------------------
-- MAIN INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:Initialize(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:854:0");
	if self.initialized then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:854:0"); return end
	if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:854:0"); return end
	
	self:InitializeStatusDropdown(frame)
	self:InitializeSortDropdown(frame)
	self:InitializeSortDropdowns(frame)
	self:InitializeTabs(frame)
	self:InitializeBattlenetFrame(frame)
	
	self.initialized = true
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:854:0"); end

-- Reset initialization state (for reloads)
function FrameInitializer:Reset() Perfy_Trace(Perfy_GetTime(), "Enter", "FrameInitializer:Reset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:868:0");
	self.initialized = false
Perfy_Trace(Perfy_GetTime(), "Leave", "FrameInitializer:Reset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua:868:0"); end

-- Register module with BFL
BFL.FrameInitializer = FrameInitializer

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\UI/FrameInitializer.lua");