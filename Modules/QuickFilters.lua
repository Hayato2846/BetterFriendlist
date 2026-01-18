--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua"); -- Modules/QuickFilters.lua
-- Quick Filters System Module
-- Manages the quick filter dropdown and filter state

local ADDON_NAME, BFL = ...

-- Register Module
local QuickFilters = BFL:RegisterModule("QuickFilters", {})

-- Localization
local L = BFL.L

-- ========================================
-- Module Dependencies
-- ========================================

local function GetFriendsList() Perfy_Trace(Perfy_GetTime(), "Enter", "GetFriendsList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:17:6");
	return Perfy_Trace_Passthrough("Leave", "GetFriendsList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:17:6", BFL:GetModule("FriendsList"))
end

-- ========================================
-- Local Variables
-- ========================================

-- Filter icons (Feather Icons for custom filters)
local FILTER_ICONS = {
	all = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all",         -- All Friends (users icon)
	online = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-online",     -- Online Only (user-check icon)
	offline = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-offline",   -- Offline Only (user-x icon)
	wow = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-wow",           -- WoW Only (shield icon)
	bnet = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-bnet",         -- Battle.net Only (share-2 icon)
	hideafk = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-hide-afk",  -- Hide AFK (eye-off icon)
	retail = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-retail"     -- Retail Only (trending-up icon)
}

-- Current filter mode
local filterMode = "all"

-- ========================================
-- Public API
-- ========================================

-- Initialize (called from ADDON_LOADED)
function QuickFilters:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:44:0");
	-- Load current filter from database
	if BetterFriendlistDB and BetterFriendlistDB.quickFilter then
		filterMode = BetterFriendlistDB.quickFilter
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:44:0"); end

-- Initialize Quick Filter Dropdown
function QuickFilters:InitDropdown(dropdown) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:InitDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:52:0");
	if not dropdown then Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:InitDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:52:0"); return end
	
	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		-- BFL:DebugPrint("|cff00ffffQuickFilters:|r Classic mode - using UIDropDownMenu for Quick Filter dropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 70)
		UIDropDownMenu_Initialize(dropdown, function(self, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:60:38");
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddFilterOption(mode, label, icon) Perfy_Trace(Perfy_GetTime(), "Enter", "AddFilterOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:63:9");
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = mode
				info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:66:16");
					QuickFilters:SetFilter(mode)
					UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:66:16"); end
				-- CRITICAL: Read from DB for checked state, not local variable
				local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
				info.checked = (currentFilter == mode)
				UIDropDownMenu_AddButton(info)
			Perfy_Trace(Perfy_GetTime(), "Leave", "AddFilterOption file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:63:9"); end
			
			AddFilterOption("all", L.FILTER_ALL, FILTER_ICONS.all)
			AddFilterOption("online", L.FILTER_ONLINE, FILTER_ICONS.online)
			AddFilterOption("offline", L.FILTER_OFFLINE, FILTER_ICONS.offline)
			AddFilterOption("wow", L.FILTER_WOW, FILTER_ICONS.wow)
			AddFilterOption("bnet", L.FILTER_BNET, FILTER_ICONS.bnet)
			AddFilterOption("hideafk", L.FILTER_HIDE_AFK, FILTER_ICONS.hideafk)
			AddFilterOption("retail", L.FILTER_RETAIL, FILTER_ICONS.retail)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:60:38"); end)
		
		-- Set initial selected text (read from DB, not local variable)
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		local currentIcon = FILTER_ICONS[currentFilter] or FILTER_ICONS.all
		UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", currentIcon))
		
		-- Setup tooltip for Classic
		-- We need to hook the button inside the dropdown frame because it consumes mouse events
		local dropdownName = dropdown:GetName()
		local buttonName = dropdownName and (dropdownName .. "Button")
		local button = buttonName and _G[buttonName]
		
		if button then
			button:HookScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:97:32");
				local filterText = QuickFilters:GetFilterText()
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
				GameTooltip:SetText(L.TOOLTIP_QUICK_FILTER .. filterText)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:97:32"); end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:106:33");
				local filterText = QuickFilters:GetFilterText()
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
				GameTooltip:SetText(L.TOOLTIP_QUICK_FILTER .. filterText)
				GameTooltip:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:106:33"); end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:InitDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:52:0"); return
	end
	
	-- Helper function to check if a filter mode is selected
	-- IMPORTANT: Read from DB to stay in sync with external changes (e.g., Broker middle click)
	local function IsSelected(mode) Perfy_Trace(Perfy_GetTime(), "Enter", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:121:7");
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		return Perfy_Trace_Passthrough("Leave", "IsSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:121:7", currentFilter == mode)
	end
	
	-- Helper function to set the filter mode
	local function SetSelected(mode) Perfy_Trace(Perfy_GetTime(), "Enter", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:127:7");
		-- CRITICAL: Read from DB to prevent race conditions
		-- Using local filterMode variable can lead to stale comparisons when events fire during dropdown changes
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		if mode ~= currentFilter then
			self:SetFilter(mode)
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "SetSelected file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:127:7"); end
	
	-- Helper function to create radio button with icon
	local function CreateRadio(rootDescription, text, mode) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:137:7");
		local radio = rootDescription:CreateButton(text, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:138:51"); Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:138:51"); end, mode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	Perfy_Trace(Perfy_GetTime(), "Leave", "CreateRadio file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:137:7"); end
	
	-- Set dropdown width (same as StatusDropdown)
	dropdown:SetWidth(51)
	
	-- Setup the dropdown menu
	dropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:147:20");
		rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
		
		-- Format for icon + text in menu (with vertical offset +2)
		local optionText = "\124T%s:16:16:0:2\124t %s"
		
		-- Create filter options with icons
		local allText = string.format(optionText, FILTER_ICONS.all, L.FILTER_ALL)
		CreateRadio(rootDescription, allText, "all")
		
		local onlineText = string.format(optionText, FILTER_ICONS.online, L.FILTER_ONLINE)
		CreateRadio(rootDescription, onlineText, "online")
		
		local offlineText = string.format(optionText, FILTER_ICONS.offline, L.FILTER_OFFLINE)
		CreateRadio(rootDescription, offlineText, "offline")
		
		local wowText = string.format(optionText, FILTER_ICONS.wow, L.FILTER_WOW)
		CreateRadio(rootDescription, wowText, "wow")
		
		local bnetText = string.format(optionText, FILTER_ICONS.bnet, L.FILTER_BNET)
		CreateRadio(rootDescription, bnetText, "bnet")
		
		local hideafkText = string.format(optionText, FILTER_ICONS.hideafk, L.FILTER_HIDE_AFK)
		CreateRadio(rootDescription, hideafkText, "hideafk")
		
		local retailText = string.format(optionText, FILTER_ICONS.retail, L.FILTER_RETAIL)
		CreateRadio(rootDescription, retailText, "retail")
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:147:20"); end)
	
	-- SetSelectionTranslator: Shows only the icon (with vertical offset +2)
	dropdown:SetSelectionTranslator(function(selection) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:177:33");
		return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:177:33", string.format("\124T%s:16:16:0:2\124t", FILTER_ICONS[selection.data]))
	end)
	
	-- Setup tooltip
	dropdown:SetScript("OnEnter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:182:31");
		local filterText = self:GetFilterText()
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		GameTooltip:SetText(string.format(L.TOOLTIP_QUICK_FILTER or "Quick Filter: %s", filterText))
		GameTooltip:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:182:31"); end)
	
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:InitDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:52:0"); end

-- Set the quick filter mode
function QuickFilters:SetFilter(mode) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:SetFilter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:194:0");
	-- Update database FIRST to ensure consistency
	if BetterFriendlistDB then
		BetterFriendlistDB.quickFilter = mode
	end
	
	-- Update local cache AFTER DB write
	filterMode = mode
	
	-- Update FriendsList module with new filter (use mode parameter, not cached variable)
	local FriendsList = GetFriendsList()
	if FriendsList then
		FriendsList:SetFilterMode(mode)
	end
	
	-- Return true to indicate filter changed (caller should refresh display)
	Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:SetFilter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:194:0"); return true
end

-- Get current filter mode
function QuickFilters:GetFilter() Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:GetFilter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:214:0");
	-- ALWAYS read from DB for consistency
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	-- Update local cache
	filterMode = currentFilter
	Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:GetFilter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:214:0"); return currentFilter
end

-- Get filter text for UI display
function QuickFilters:GetFilterText() Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:GetFilterText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:223:0");
	-- ALWAYS read from DB to ensure correct text after external changes (e.g., Broker)
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or filterMode
	
	local filterTexts = {
		all = L.FILTER_ALL,
		online = L.FILTER_ONLINE,
		offline = L.FILTER_OFFLINE,
		wow = L.FILTER_WOW,
		bnet = L.FILTER_BNET,
		hideafk = L.FILTER_HIDE_AFK,
		retail = L.FILTER_RETAIL,
	}
	return Perfy_Trace_Passthrough("Leave", "QuickFilters:GetFilterText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:223:0", filterTexts[currentFilter] or L.FILTER_ALL)
end

-- Get filter icons table
function QuickFilters:GetIcons() Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:GetIcons file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:240:0");
	Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:GetIcons file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:240:0"); return FILTER_ICONS
end

-- Refresh the dropdown display (icon) based on current filter
-- Called when filter changes externally (e.g. via Broker)
function QuickFilters:RefreshDropdown(dropdown) Perfy_Trace(Perfy_GetTime(), "Enter", "QuickFilters:RefreshDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:246:0");
	if not dropdown then Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:RefreshDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:246:0"); return end
	
	-- Get current filter from DB
	local currentFilter = self:GetFilter()
	local icon = FILTER_ICONS[currentFilter]
	
	if icon then
		-- Manually update the text to match the translator format
		-- This forces the dropdown button to show the correct icon
		
		if BFL.IsClassic or not BFL.HasModernDropdown then
			-- Classic: Use 14x14 icon with -2:-2 offset to match InitDropdown
			local text = string.format("\124T%s:14:14:-2:-2\124t", icon)
			UIDropDownMenu_SetText(dropdown, text)
		elseif dropdown.SetText then
			-- Retail: Use 16x16 icon with 0:2 offset
			local text = string.format("\124T%s:16:16:0:2\124t", icon)
			dropdown:SetText(text)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "QuickFilters:RefreshDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua:246:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/QuickFilters.lua");