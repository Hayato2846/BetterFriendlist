-- Modules/QuickFilters.lua
-- Quick Filters System Module
-- Manages the quick filter dropdown and filter state

local ADDON_NAME, BFL = ...

-- Register Module
local QuickFilters = BFL:RegisterModule("QuickFilters", {})

-- ========================================
-- Module Dependencies
-- ========================================

local function GetFriendsList()
	return BFL:GetModule("FriendsList")
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
function QuickFilters:Initialize()
	-- Load current filter from database
	if BetterFriendlistDB and BetterFriendlistDB.quickFilter then
		filterMode = BetterFriendlistDB.quickFilter
	end
end

-- Initialize Quick Filter Dropdown
function QuickFilters:InitDropdown(dropdown)
	if not dropdown then return end
	
	-- Classic mode: Use UIDropDownMenu
	if BFL.IsClassic or not BFL.HasModernDropdown then
		-- BFL:DebugPrint("|cff00ffffQuickFilters:|r Classic mode - using UIDropDownMenu for Quick Filter dropdown")
		
		UIDropDownMenu_SetWidth(dropdown, 70)
		UIDropDownMenu_Initialize(dropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			
			local function AddFilterOption(mode, label, icon)
				info.text = string.format("|T%s:14:14:0:0|t %s", icon, label)
				info.value = mode
				info.func = function()
					QuickFilters:SetFilter(mode)
					UIDropDownMenu_SetText(dropdown, string.format("|T%s:14:14:-2:-2|t", icon))
				end
				-- CRITICAL: Read from DB for checked state, not local variable
				local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
				info.checked = (currentFilter == mode)
				UIDropDownMenu_AddButton(info)
			end
			
			AddFilterOption("all", "All Friends", FILTER_ICONS.all)
			AddFilterOption("online", "Online Only", FILTER_ICONS.online)
			AddFilterOption("offline", "Offline Only", FILTER_ICONS.offline)
			AddFilterOption("wow", "WoW Only", FILTER_ICONS.wow)
			AddFilterOption("bnet", "Battle.net Only", FILTER_ICONS.bnet)
			AddFilterOption("hideafk", "Hide AFK/DND", FILTER_ICONS.hideafk)
			AddFilterOption("retail", "Retail Only", FILTER_ICONS.retail)
		end)
		
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
			button:HookScript("OnEnter", function()
				local filterText = QuickFilters:GetFilterText()
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
				GameTooltip:SetText("Quick Filter: " .. filterText)
				GameTooltip:Show()
			end)
			button:HookScript("OnLeave", GameTooltip_Hide)
		else
			dropdown:SetScript("OnEnter", function()
				local filterText = QuickFilters:GetFilterText()
				
				GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
				GameTooltip:SetText("Quick Filter: " .. filterText)
				GameTooltip:Show()
			end)
			dropdown:SetScript("OnLeave", GameTooltip_Hide)
		end
		
		return
	end
	
	-- Helper function to check if a filter mode is selected
	-- IMPORTANT: Read from DB to stay in sync with external changes (e.g., Broker middle click)
	local function IsSelected(mode)
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		return currentFilter == mode
	end
	
	-- Helper function to set the filter mode
	local function SetSelected(mode)
		-- CRITICAL: Read from DB to prevent race conditions
		-- Using local filterMode variable can lead to stale comparisons when events fire during dropdown changes
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		if mode ~= currentFilter then
			self:SetFilter(mode)
		end
	end
	
	-- Helper function to create radio button with icon
	local function CreateRadio(rootDescription, text, mode)
		local radio = rootDescription:CreateButton(text, function() end, mode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	-- Set dropdown width (same as StatusDropdown)
	dropdown:SetWidth(51)
	
	-- Setup the dropdown menu
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_QUICKFILTER")
		
		-- Format for icon + text in menu (with vertical offset +2)
		local optionText = "\124T%s:16:16:0:2\124t %s"
		
		-- Create filter options with icons
		local allText = string.format(optionText, FILTER_ICONS.all, "All Friends")
		CreateRadio(rootDescription, allText, "all")
		
		local onlineText = string.format(optionText, FILTER_ICONS.online, "Online Only")
		CreateRadio(rootDescription, onlineText, "online")
		
		local offlineText = string.format(optionText, FILTER_ICONS.offline, "Offline Only")
		CreateRadio(rootDescription, offlineText, "offline")
		
		local wowText = string.format(optionText, FILTER_ICONS.wow, "WoW Only")
		CreateRadio(rootDescription, wowText, "wow")
		
		local bnetText = string.format(optionText, FILTER_ICONS.bnet, "Battle.net Only")
		CreateRadio(rootDescription, bnetText, "bnet")
		
		local hideafkText = string.format(optionText, FILTER_ICONS.hideafk, "Hide AFK/DND")
		CreateRadio(rootDescription, hideafkText, "hideafk")
		
		local retailText = string.format(optionText, FILTER_ICONS.retail, "Retail Only")
		CreateRadio(rootDescription, retailText, "retail")
	end)
	
	-- SetSelectionTranslator: Shows only the icon (with vertical offset +2)
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("\124T%s:16:16:0:2\124t", FILTER_ICONS[selection.data])
	end)
	
	-- Setup tooltip
	dropdown:SetScript("OnEnter", function()
		local filterText = self:GetFilterText()
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		GameTooltip:SetText("Quick Filter: " .. filterText)
		GameTooltip:Show()
	end)
	
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Set the quick filter mode
function QuickFilters:SetFilter(mode)
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
	return true
end

-- Get current filter mode
function QuickFilters:GetFilter()
	-- ALWAYS read from DB for consistency
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	-- Update local cache
	filterMode = currentFilter
	return currentFilter
end

-- Get filter text for UI display
function QuickFilters:GetFilterText()
	-- ALWAYS read from DB to ensure correct text after external changes (e.g., Broker)
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or filterMode
	
	local filterTexts = {
		all = "All Friends",
		online = "Online Only",
		offline = "Offline Only",
		wow = "WoW Only",
		bnet = "Battle.net Only",
		hideafk = "Hide AFK/DND",
		retail = "Retail Only",
	}
	return filterTexts[currentFilter] or "All Friends"
end

-- Get filter icons table
function QuickFilters:GetIcons()
	return FILTER_ICONS
end

-- Refresh the dropdown display (icon) based on current filter
-- Called when filter changes externally (e.g. via Broker)
function QuickFilters:RefreshDropdown(dropdown)
	if not dropdown then return end
	
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
end
