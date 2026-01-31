-- Settings.lua
-- Settings panel and configuration management module

local ADDON_NAME, BFL = ...
local L = BFL.L

-- Import UI constants
local UI = BFL.UI.CONSTANTS

-- Import Settings Components Library
local Components = BFL.SettingsComponents

-- Localization
local L = BFL.L or BFL_L

-- Register the Settings module
local Settings = BFL:RegisterModule("Settings", {})

-- Local references
local settingsFrame = nil
local currentTab = 1
local draggedGroupButton = nil
local groupButtons = {}

-- Helper to get Database module
local function GetDB()
	return BFL and BFL:GetModule("DB")
end

-- Helper to get Groups module
local function GetGroups()
	return BFL and BFL:GetModule("Groups")
end

--------------------------------------------------------------------------
-- PRIVATE HELPER FUNCTIONS
--------------------------------------------------------------------------

-- Create a single group button for the Groups tab
local function CreateGroupButton(parent, groupId, groupName, orderIndex)
	local button = CreateFrame("Button", nil, parent)
	button.groupId = groupId
	button.orderIndex = orderIndex
	
	button:SetSize(310, 32)
	button:SetNormalTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	button:GetNormalTexture():SetAlpha(UI.ALPHA_DIMMED)
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	button:GetHighlightTexture():SetAlpha(0.7)
	
	-- Background
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(unpack(UI.BG_COLOR_DARK))
	
	-- Drag Handle (:::)
	button.dragHandle = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	button.dragHandle:SetPoint("LEFT", UI.SPACING_SMALL, 0)
	button.dragHandle:SetText(":::")
	button.dragHandle:SetTextColor(unpack(UI.TEXT_COLOR_GRAY))
	
	-- Order Number
	button.orderText = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	button.orderText:SetPoint("LEFT", button.dragHandle, "RIGHT", UI.SPACING_MEDIUM, 0)
	button.orderText:SetText(orderIndex)
	button.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Group Name
	button.nameText = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	button.nameText:SetPoint("LEFT", button.orderText, "RIGHT", UI.SPACING_LARGE, 0)
	button.nameText:SetText(groupName)
	button.nameText:SetTextColor(1, 1, 1)
	
	-- Edit/Rename Button (only for custom groups)
	local isBuiltIn = (groupId == "favorites" or groupId == "nogroup")
	
	if not isBuiltIn then
		button.editButton = CreateFrame("Button", nil, button)
		button.editButton:SetSize(24, 24)
		button.editButton:SetPoint("RIGHT", -70, 0)
		
		local bg = button.editButton:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(unpack(UI.BG_COLOR_MEDIUM))
		
		local texture = button.editButton:CreateTexture(nil, "ARTWORK")
		texture:SetSize(UI.BUTTON_SIZE_SMALL, UI.BUTTON_SIZE_SMALL)
		texture:SetPoint("CENTER")
		texture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		button.editButton.texture = texture
		
		button.editButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		local highlightTex = button.editButton:GetHighlightTexture()
		if highlightTex then
			highlightTex:SetSize(UI.BUTTON_SIZE_SMALL, UI.BUTTON_SIZE_SMALL)
			highlightTex:SetPoint("CENTER")
		end
		
		button.editButton:SetScript("OnClick", function(self)
			StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, groupId)
		end)
		
		button.editButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.TOOLTIP_RENAME_GROUP, 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		
		button.editButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end
	
	-- Color Picker Button
	button.colorButton = CreateFrame("Button", nil, button)
	button.colorButton:SetSize(24, 24)
	button.colorButton:SetPoint("RIGHT", -40, 0)
	
	button.colorBorder = button.colorButton:CreateTexture(nil, "BACKGROUND")
	button.colorBorder:SetAllPoints(button.colorButton)
	button.colorBorder:SetColorTexture(0, 0, 0, 1)
	
	button.colorSwatch = button.colorButton:CreateTexture(nil, "ARTWORK")
	button.colorSwatch:SetPoint("TOPLEFT", button.colorButton, "TOPLEFT", UI.SPACING_TINY, -UI.SPACING_TINY)
	button.colorSwatch:SetPoint("BOTTOMRIGHT", button.colorButton, "BOTTOMRIGHT", -UI.SPACING_TINY, UI.SPACING_TINY)
	button.colorSwatch:SetColorTexture(1, 1, 1)
	
	-- Load current color from Groups module
	local Groups = GetGroups()
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			button.colorSwatch:SetColorTexture(group.color.r, group.color.g, group.color.b)
		else
			button.colorSwatch:SetColorTexture(1, 0.82, 0)
		end
	end
	
	button.colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	button.colorButton:SetScript("OnClick", function(self)
		Settings:ShowColorPicker(groupId, groupName, button.colorSwatch)
	end)
	
	button.colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_GROUP_COLOR, 1, 1, 1)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	
	button.colorButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Delete Button (only for custom groups)
	if not isBuiltIn then
		button.deleteButton = CreateFrame("Button", nil, button)
		button.deleteButton:SetSize(UI.BUTTON_SIZE_SMALL, UI.BUTTON_SIZE_SMALL)
		button.deleteButton:SetPoint("RIGHT", -UI.SPACING_MEDIUM, 0)
		
		local texture = button.deleteButton:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetAtlas("transmog-icon-remove", true)
		texture:SetVertexColor(0.9, 0.2, 0.2)
		button.deleteButton.texture = texture
		
		local highlight = button.deleteButton:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetAtlas("transmog-icon-remove", true)
		highlight:SetVertexColor(1, 0.4, 0.4)
		highlight:SetAlpha(0.8)
		
		button.deleteButton:SetScript("OnClick", function(self)
			Settings:DeleteGroup(groupId, groupName)
		end)
		
		button.deleteButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.TOOLTIP_DELETE_GROUP, 1, 0.2, 0.2)
			GameTooltip:AddLine(L.TOOLTIP_DELETE_DESC, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		
		button.deleteButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end
	
	-- Drag functionality
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		draggedGroupButton = self
		self:SetAlpha(UI.ALPHA_DIMMED)
		
		self:SetScript("OnUpdate", function(updateSelf)
			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			cursorX = cursorX / scale
			cursorY = cursorY / scale
			
			for _, btn in ipairs(groupButtons) do
				if btn ~= updateSelf then
					btn.bg:SetColorTexture(unpack(UI.BG_COLOR_DARK))
				end
			end
			
			for _, btn in ipairs(groupButtons) do
				if btn ~= updateSelf and btn:IsVisible() then
					local left, bottom, width, height = btn:GetRect()
					if left and cursorX >= left and cursorX <= left + width and 
					   cursorY >= bottom and cursorY <= bottom + height then
						btn.bg:SetColorTexture(0.3, 0.3, 0.3, 0.7)
						break
					end
				end
			end
		end)
	end)
	
	button:SetScript("OnDragStop", function(self)
		self:SetAlpha(1.0)
		self:SetScript("OnUpdate", nil)
		
		if not draggedGroupButton then return end
		
		local cursorX, cursorY = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		cursorX = cursorX / scale
		cursorY = cursorY / scale
		
		local targetButton = nil
		for _, btn in ipairs(groupButtons) do
			if btn ~= draggedGroupButton and btn:IsVisible() then
				local left, bottom, width, height = btn:GetRect()
				if left and cursorX >= left and cursorX <= left + width and 
				   cursorY >= bottom and cursorY <= bottom + height then
					targetButton = btn
					break
				end
			end
		end
		
		if targetButton then
			local draggedIndex = draggedGroupButton.orderIndex
			local targetIndex = targetButton.orderIndex
			
			draggedGroupButton.orderIndex = targetIndex
			targetButton.orderIndex = draggedIndex
		end
		
		for _, btn in ipairs(groupButtons) do
			btn.bg:SetColorTexture(unpack(UI.BG_COLOR_DARK))
		end
		
		draggedGroupButton = nil
		Settings:SaveGroupOrder()
	end)
	
	button:SetScript("OnEnter", function(self)
		if draggedGroupButton and draggedGroupButton ~= self then
			self.bg:SetColorTexture(0.3, 0.3, 0.3, 0.7)
		end
	end)
	
	button:SetScript("OnLeave", function(self)
		if not draggedGroupButton or draggedGroupButton == self then
			self.bg:SetColorTexture(unpack(UI.BG_COLOR_DARK))
		end
	end)
	
	return button
end

-- Parse FriendGroups note format: "ActualNote#Group1#Group2#Group3"
local function ParseFriendGroupsNote(noteText)
	if not noteText or noteText == "" then
		return "", {}
	end
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r     Parsing note:", noteText)
	
	local parts = {strsplit("#", noteText)}
	local actualNote = parts[1] or ""
	local groups = {}
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r     Split into", #parts, "parts")
	
	for i = 2, #parts do
		local groupName = strtrim(parts[i])
		if groupName ~= "" then
			table.insert(groups, groupName)
			BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r     Found group:", groupName)
		end
	end
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r     Actual note:", actualNote)
	BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r     Total groups found:", #groups)
	
	return actualNote, groups
end

--------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------

-- Initialize the settings frame
function Settings:OnLoad(frame)
	settingsFrame = frame
	if not settingsFrame then
		return
	end
	
	-- Setup close button
	if settingsFrame.CloseButton then
		settingsFrame.CloseButton:SetScript("OnClick", function()
			self:Cancel()
		end)
	end
end

-- Show the settings window
function Settings:Show()
	if not settingsFrame then
		settingsFrame = BetterFriendlistSettingsFrame
	end
	
	if settingsFrame then
		self:LoadSettings()
		self:RefreshTabs() -- Update tab visibility based on Beta features
		settingsFrame:Show()
		self:ShowTab(currentTab or 1) -- Restore or show first tab
	else
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Settings:|r Frame not initialized!")
	end
end

-- ===========================================
-- TAB SYSTEM: Central Definition
-- ===========================================
local TAB_DEFINITIONS = {
	-- Stable Tabs (always visible)
	{id = 1, name = L.SETTINGS_TAB_GENERAL, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\settings.blp", beta = false},
	{id = 2, name = L.SETTINGS_TAB_FONTS, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\type.blp", beta = false},
	{id = 3, name = L.SETTINGS_TAB_GROUPS, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp", beta = false},
	{id = 4, name = L.SETTINGS_TAB_ADVANCED, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\sliders.blp", beta = false},
	
	-- Beta Tabs (only visible when enableBetaFeatures = true)
	{id = 5, name = L.SETTINGS_TAB_DATABROKER, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\activity.blp", beta = false},
	{id = 6, name = L.SETTINGS_TAB_NOTIFICATIONS, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\bell.blp", beta = true},
	{id = 7, name = L.SETTINGS_TAB_GLOBAL_SYNC, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\globe.blp", beta = true},
	-- Future beta tabs go here...
}

-- Color scheme
local COLOR_STABLE = "|cffffff00" -- Gold
local COLOR_BETA = "|cffff8800" -- Orange

-- Get all tabs that should be visible based on current settings
local function GetVisibleTabs()
	local betaEnabled = BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures or false
	local visibleTabs = {}
	
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		-- Show tab if: it's stable OR (it's beta AND beta features are enabled)
		if not tabDef.beta or betaEnabled then
			table.insert(visibleTabs, tabDef)
		end
	end
	
	return visibleTabs
end

-- Get all beta tab IDs (for auto-switching when disabling beta)
local function GetBetaTabIds()
	local betaTabIds = {}
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		if tabDef.beta then
			table.insert(betaTabIds, tabDef.id)
		end
	end
	return betaTabIds
end

-- Refresh tab visibility (Beta features toggle)
function Settings:RefreshTabs()
	if not settingsFrame then
		settingsFrame = BetterFriendlistSettingsFrame
	end
	if not settingsFrame then return end
	
	local visibleTabs = GetVisibleTabs()
	
	-- Update tab buttons
	for _, tabDef in ipairs(visibleTabs) do
		local tab = _G["BetterFriendlistSettingsFrameTab" .. tabDef.id]
		if tab then
			-- Ensure fonts are set to our custom objects via string names to be safe
			tab:SetNormalFontObject("BetterFriendlistFontNormalSmall") 
			tab:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
			tab:SetDisabledFontObject("BetterFriendlistFontHighlightSmall") -- Selected = White
			
			-- Build tab text with icon and coloring
			-- Only apply explicit color for Beta tabs (Orange). 
			-- Stable tabs should use the FontObject's color (Gold unselected, White selected).
			local colorPrefix = ""
			if tabDef.beta then
				colorPrefix = COLOR_BETA
			end
			
			-- Icon with color tint: r:g:b values (255, 136, 0 for orange / 255, 255, 0 for gold)
			local r, g, b
			if tabDef.beta then
				r, g, b = 255, 136, 0 -- Orange
			else
				r, g, b = 255, 255, 0 -- Gold
			end
			local iconTexture = tabDef.icon and ("|T" .. tabDef.icon .. ":16:16:0:0:64:64:0:64:0:64:" .. r .. ":" .. g .. ":" .. b .. "|t ") or ""
			local text = colorPrefix .. iconTexture .. tabDef.name
			
			-- Close color tag if we opened one
			if tabDef.beta then
				text = text .. "|r"
			end
			
			tab:SetText(text)
			tab:Show()
		end
	end
	
	-- Hide tabs not in visible list
	for i = 1, 10 do
		local tab = _G["BetterFriendlistSettingsFrameTab" .. i]
		if tab then
			local shouldShow = false
			for _, tabDef in ipairs(visibleTabs) do
				if tabDef.id == i then
					shouldShow = true
					break
				end
			end
			if not shouldShow then
				tab:Hide()
			end
		end
	end
	
	-- Update panel FIRST - let Blizzard do its thing
	local maxTabId = 0
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		if tabDef.id > maxTabId then
			maxTabId = tabDef.id
		end
	end
	PanelTemplates_SetNumTabs(settingsFrame, maxTabId)
	PanelTemplates_UpdateTabs(settingsFrame)
	
	-- THEN reposition tabs dynamically
	-- Start second row at Tab 6 (Notifications) if visible
	local tab1 = _G["BetterFriendlistSettingsFrameTab1"]
	local tab6 = _G["BetterFriendlistSettingsFrameTab6"]
	
	if tab6 and tab1 and tab6:IsShown() then
		tab6:ClearAllPoints()
		-- Position below Tab1: +4px for proper spacing (copied from legacy logic)
		tab6:SetPoint("TOPLEFT", tab1, "BOTTOMLEFT", 0, 8)
		
		-- Move MainInset down to make room for second tab row
		if settingsFrame.MainInset then
			settingsFrame.MainInset:ClearAllPoints()
			settingsFrame.MainInset:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 4, -70)
			settingsFrame.MainInset:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", 0, 2)
		end
	else
		-- Single row layout: Restore default MainInset position (tabs at y=-27)
		if settingsFrame.MainInset then
			settingsFrame.MainInset:ClearAllPoints()
			settingsFrame.MainInset:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 4, -45)
			settingsFrame.MainInset:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", 0, 2)
		end
	end
end

-- Hide the settings window
function Settings:Hide()
	if settingsFrame then
		settingsFrame:Hide()
	end
end

-- Switch between tabs
function Settings:ShowTab(tabID)
	if not settingsFrame then return end
	
	currentTab = tabID
	PanelTemplates_SetTab(settingsFrame, tabID)
	
	-- Manually update tab selection states
	for i = 1, 10 do
		local tab = _G["BetterFriendlistSettingsFrameTab" .. i]
		if tab and tab:IsShown() then
			-- Ensure fonts are strictly enforcing BetterFriendlist style
			tab:SetNormalFontObject("BetterFriendlistFontNormalSmall")
			tab:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
			tab:SetDisabledFontObject("BetterFriendlistFontHighlightSmall")

			if i == tabID then
				PanelTemplates_SelectTab(tab)
				-- Force apply font to text if Disabled state didn't pick it up correctly
				local fs = tab:GetFontString()
				if fs then
					fs:SetFontObject("BetterFriendlistFontHighlightSmall")
				end
			else
				PanelTemplates_DeselectTab(tab)
			end
		end
	end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if content then
		if content.GeneralTab then content.GeneralTab:Hide() end
		if content.FontsTab then content.FontsTab:Hide() end
		if content.GroupsTab then content.GroupsTab:Hide() end
		if content.AdvancedTab then content.AdvancedTab:Hide() end
		if content.NotificationsTab then content.NotificationsTab:Hide() end
		if content.BrokerTab then content.BrokerTab:Hide() end
		if content.GlobalSyncTab then content.GlobalSyncTab:Hide() end
		
		if tabID == 1 and content.GeneralTab then
			content.GeneralTab:Show()
			self:RefreshGeneralTab()
		elseif tabID == 2 and content.FontsTab then
			content.FontsTab:Show()
			self:RefreshFontsTab()
		elseif tabID == 3 and content.GroupsTab then
			content.GroupsTab:Show()
			self:RefreshGroupsTab()
		elseif tabID == 4 and content.AdvancedTab then
			content.AdvancedTab:Show()
			self:RefreshAdvancedTab()
		elseif tabID == 5 and content.BrokerTab then
			content.BrokerTab:Show()
			self:RefreshBrokerTab()
		elseif tabID == 6 and content.NotificationsTab then
			content.NotificationsTab:Show()
			self:RefreshNotificationsTab()
		elseif tabID == 7 and content.GlobalSyncTab then
			content.GlobalSyncTab:Show()
			self:RefreshGlobalSyncTab()
		end
		
		-- Adjust content height dynamically after tab is shown
		self:AdjustContentHeight(tabID)
	end
end

-- Adjust the Content frame height based on the active tab's content
function Settings:AdjustContentHeight(tabID)
	if not settingsFrame then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content then return end
	
	local activeTab = nil
	if tabID == 1 then
		activeTab = content.GeneralTab
	elseif tabID == 2 then
		activeTab = content.FontsTab
	elseif tabID == 3 then
		activeTab = content.GroupsTab
	elseif tabID == 4 then
		activeTab = content.AdvancedTab
	elseif tabID == 5 then
		activeTab = content.BrokerTab
	elseif tabID == 6 then
		activeTab = content.NotificationsTab
	elseif tabID == 7 then
		activeTab = content.GlobalSyncTab
	end
	
	if not activeTab then return end
	
	-- Calculate required height by measuring all visible children
	local maxHeight = self:CalculateTabContentHeight(activeTab)
	
	-- Get available scroll frame height
	local scrollFrame = settingsFrame.ContentScrollFrame
	local availableHeight = scrollFrame:GetHeight()
	
	-- Set content height to maximum of calculated height or available height
	-- This ensures no unnecessary scrolling for small content
	local newHeight = math.max(maxHeight, availableHeight)
	content:SetHeight(newHeight)
end

-- Calculate the actual content height of a tab
function Settings:CalculateTabContentHeight(tab)
	if not tab then return 600 end -- fallback
	
	local maxY = 0
	local minY = 0
	
	-- Iterate through all regions (textures, fontstrings, frames, etc.)
	local regions = {tab:GetRegions()}
	for _, region in ipairs(regions) do
		if region:IsShown() then
			local bottom = region:GetBottom()
			local top = region:GetTop()
			if bottom and top then
				local tabTop = tab:GetTop()
				if tabTop then
					minY = math.min(minY, bottom - tabTop)
					maxY = math.max(maxY, top - tabTop)
				end
			end
		end
	end
	
	-- Check all child frames
	local children = {tab:GetChildren()}
	for _, child in ipairs(children) do
		if child:IsShown() then
			local bottom = child:GetBottom()
			local top = child:GetTop()
			if bottom and top then
				local tabTop = tab:GetTop()
				if tabTop then
					minY = math.min(minY, bottom - tabTop)
					maxY = math.max(maxY, top - tabTop)
				end
			end
		end
	end
	
	-- Calculate total height needed (absolute value of minY gives depth below anchor)
	local totalHeight = math.abs(minY) + 20 -- Add 20px padding at bottom
	
	return math.max(totalHeight, 200) -- Minimum 200px height
end

-- Load settings from database into UI
function Settings:LoadSettings()
	local DB = GetDB()
	if not DB then return end
	
	if not settingsFrame or not settingsFrame.ContentScrollFrame then return end
	local content = settingsFrame.ContentScrollFrame.Content
	
	-- General tab is now populated via RefreshGeneralTab() which reads DB directly
	-- No need to manually set values here anymore
	
	if content and content.GroupsTab then
		local groupsTab = content.GroupsTab
		
		if groupsTab.ShowFavoritesGroup then
			local value = DB:Get("showFavoritesGroup", true)
			groupsTab.ShowFavoritesGroup:SetChecked(value)
		end
	end
	
	if content and content.AppearanceTab then
		local appearanceTab = content.AppearanceTab
		
		if appearanceTab.ColorClassNames then
			local value = DB:Get("colorClassNames", true)
			appearanceTab.ColorClassNames:SetChecked(value)
		end
		
		if appearanceTab.HideEmptyGroups then
			local value = DB:Get("hideEmptyGroups", false)
			appearanceTab.HideEmptyGroups:SetChecked(value)
		end
		
		if appearanceTab.ShowFactionIcons then
			local value = DB:Get("showFactionIcons", false)
			appearanceTab.ShowFactionIcons:SetChecked(value)
		end
		
		if appearanceTab.ShowRealmName then
			local value = DB:Get("showRealmName", false)
			appearanceTab.ShowRealmName:SetChecked(value)
		end
		
		if appearanceTab.GrayOtherFaction then
			local value = DB:Get("grayOtherFaction", false)
			appearanceTab.GrayOtherFaction:SetChecked(value)
		end
		
		if appearanceTab.ShowMobileAsAFK then
			local value = DB:Get("showMobileAsAFK", false)
			appearanceTab.ShowMobileAsAFK:SetChecked(value)
		end
		
		if appearanceTab.ShowMobileText then
			local value = DB:Get("showMobileText", false)
			appearanceTab.ShowMobileText:SetChecked(value)
		end
		
	if appearanceTab.HideMaxLevel then
		local value = DB:Get("hideMaxLevel", false)
		appearanceTab.HideMaxLevel:SetChecked(value)
	end		if appearanceTab.AccordionGroups then
			local value = DB:Get("accordionGroups", false)
			appearanceTab.AccordionGroups:SetChecked(value)
		end
		
		if appearanceTab.CompactMode then
			local value = DB:Get("compactMode", false)
			appearanceTab.CompactMode:SetChecked(value)
		end
		
	end
end

-- Set font size and save immediately
function Settings:SetFontSize(size)
	-- REMOVED: Global font scaling disabled (User Request 2026-01-20)
	-- Do nothing
end

-- Reset to defaults
function Settings:ResetToDefaults()
	StaticPopup_Show("BETTER_FRIENDLIST_RESET_SETTINGS")
end

-- Perform the actual reset
function Settings:DoReset()
	local DB = GetDB()
	if not DB then
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Settings:|r Database not available!")
		return
	end
	
	DB:Set("showBlizzardOption", false)
	DB:Set("compactMode", false)
	-- DB:Set("fontSize", "normal") -- REMOVED
	DB:Set("colorClassNames", true)
	DB:Set("hideEmptyGroups", false)
	DB:Set("showFactionIcons", false)
	DB:Set("showFactionBg", false)
	DB:Set("showRealmName", false)
	DB:Set("grayOtherFaction", false)
	DB:Set("showMobileAsAFK", false)
	DB:Set("treatMobileAsOffline", false)  -- NEW: Feature Request
	DB:Set("showNotesAsName", false)  -- NEW: Feature Request
	DB:Set("showNicknameAsName", false)  -- NEW: Feature Request
	DB:Set("showNicknameInName", false)  -- NEW: Feature Request
	DB:Set("windowScale", 1.0)  -- NEW: Feature Request
	DB:Set("hideMaxLevel", false)
	DB:Set("accordionGroups", false)
	
	self:LoadSettings()
	
	-- Reset window scale to 100%
	local MainFrameEditMode = BFL.Modules and BFL.Modules.MainFrameEditMode
	if MainFrameEditMode and MainFrameEditMode.ApplyScale then
		MainFrameEditMode:ApplyScale()
	elseif BetterFriendsFrame then
		BetterFriendsFrame:SetScale(1.0)
	end
	
	-- Force full display refresh - reset affects all display settings
	BFL:ForceRefreshFriendsList()
	
	BFL:DebugPrint("|cff20ff20BetterFriendlist:|r " .. L.SETTINGS_RESET_SUCCESS)
end

-- Refresh the group list in the Groups tab (Legacy wrapper)
function Settings:RefreshGroupList()
	-- Now uses RefreshGroupsTab which generates everything dynamically
	self:RefreshGroupsTab()
	return
end

-- Old implementation (kept for reference, but not used)
function Settings:RefreshGroupList_OLD()
	local frame = BetterFriendlistSettingsFrame
	if not frame or not frame.ContentScrollFrame or not frame.ContentScrollFrame.Content or not frame.ContentScrollFrame.Content.GroupsTab then return end
	
	local container = frame.ContentScrollFrame.Content.GroupsTab.GroupOrderSection.Container
	
	-- Clear existing buttons
	for _, button in ipairs(groupButtons) do
		button:Hide()
		button:SetParent(nil)
	end
	groupButtons = {}
	
	local DB = GetDB()
	local groupOrder = DB and DB:Get("groupOrder") or nil
	
	local Groups = GetGroups()
	if not Groups then
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Settings:|r Groups module not available!")
		return
	end
	
	local allGroups = Groups:GetAll()
	local orderedGroups = {}
	
	if groupOrder and #groupOrder > 0 then
		for i, groupId in ipairs(groupOrder) do
			local group = allGroups[groupId]
			if group then
				table.insert(orderedGroups, {id = groupId, name = group.name, order = i})
			end
		end
		for groupId, group in pairs(allGroups) do
			local found = false
			for _, ordered in ipairs(orderedGroups) do
				if ordered.id == groupId then
					found = true
					break
				end
			end
			if not found then
				table.insert(orderedGroups, {id = groupId, name = group.name, order = #orderedGroups + 1})
			end
		end
	else
		table.insert(orderedGroups, {id = "favorites", name = L.GROUP_FAVORITES, order = 1})
		
		local customGroups = {}
		for groupId, group in pairs(allGroups) do
			if groupId ~= "favorites" and groupId ~= "nogroup" then
				table.insert(customGroups, {id = groupId, name = group.name})
			end
		end
		table.sort(customGroups, function(a, b) return a.name < b.name end)
		for _, group in ipairs(customGroups) do
			table.insert(orderedGroups, {id = group.id, name = group.name, order = #orderedGroups + 1})
		end
		
		if allGroups["nogroup"] then
			table.insert(orderedGroups, {id = "nogroup", name = L.GROUP_NO_GROUP, order = #orderedGroups + 1})
		end
	end
	
	local yOffset = UI.TOP_OFFSET
	for i, groupData in ipairs(orderedGroups) do
		local button = CreateGroupButton(container, groupData.id, groupData.name, i)
		button:SetPoint("TOPLEFT", UI.SPACING_SMALL, yOffset)
		button:Show()
		table.insert(groupButtons, button)
		yOffset = yOffset - UI.BUTTON_HEIGHT_STANDARD
	end
	
	container:SetHeight(math.max(1, #orderedGroups * UI.BUTTON_HEIGHT_STANDARD + UI.SPACING_MEDIUM))
end

-- Save group order after drag/drop
function Settings:SaveGroupOrder()
	local newOrder = {}
	
	local sortedButtons = {}
	for _, button in ipairs(groupButtons) do
		table.insert(sortedButtons, button)
	end
	table.sort(sortedButtons, function(a, b) return a.orderIndex < b.orderIndex end)
	
	for _, button in ipairs(sortedButtons) do
		table.insert(newOrder, button.groupId)
	end
	
	local DB = GetDB()
	if DB then
		DB:Set("groupOrder", newOrder)
		BFL:DebugPrint("|cff20ff20BetterFriendlist:|r " .. L.SETTINGS_GROUP_ORDER_SAVED)
		
		local Groups = GetGroups()
		if Groups and Groups.Initialize then
			Groups:Initialize()
		end
		
		if BetterFriendsFrame_UpdateFriendsList then
			BetterFriendsFrame_UpdateFriendsList()
		end
	end
	
	self:RefreshGroupList()
end

-- Show color picker for a group
function Settings:ShowGroupCountColorPicker(groupId, groupName, colorSwatch, isReset)
	local DB = GetDB()
	if not DB then return end
	
	-- Handle Reset (Right Click)
	if isReset then
		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = nil
		DB:Set("groupCountColors", groupCountColors)
		
		-- Update UI swatch to "inherited" grey look or the actual inherited color?
		-- We should probably update it to the inherited color for better feedback, 
		-- or grey if we want to signify "unset". 
		-- SettingsComponents logic sets it to grey if initial is nil.
		-- Let's just force a full refresh.
		
		local Groups = GetGroups()
		if Groups then Groups:Initialize() end
		
		BFL:ForceRefreshFriendsList()
		self:RefreshGroupsTab() -- Update the swatch in the list
		return
	end
	
	local Groups = GetGroups()
	local r, g, b = 1, 1, 1
	
	if Groups then
		local group = Groups:Get(groupId)
		if group then
			-- Start with current count color, or fallback to group color (or default white)
			if group.countColor then
				r, g, b = group.countColor.r, group.countColor.g, group.countColor.b
			elseif group.color then
				r, g, b = group.color.r, group.color.g, group.color.b
			end
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = 1.0
	info.hasOpacity = false
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		
		colorSwatch:SetColorTexture(newR, newG, newB)
		
		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = {r = newR, g = newG, b = newB}
		DB:Set("groupCountColors", groupCountColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.countColor = {r = newR, g = newG, b = newB}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	info.cancelFunc = function(previousValues)
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b)
		
		-- Note: Cancellation doesn't revert to "nil" if it was nil before, 
		-- it reverts to the RGB value we started with. This is acceptable.
		-- If user wants to reset to inherit, they can Right-Click.
		
		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
		DB:Set("groupCountColors", groupCountColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.countColor = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
	else
		ColorPickerFrame.func = info.swatchFunc
		ColorPickerFrame.cancelFunc = info.cancelFunc
		ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		ColorPickerFrame:Show()
	end
end

function Settings:ShowGroupArrowColorPicker(groupId, groupName, colorSwatch, isReset)
	local DB = GetDB()
	if not DB then return end
	
	-- Handle Reset (Right Click)
	if isReset then
		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = nil
		DB:Set("groupArrowColors", groupArrowColors)
		
		local Groups = GetGroups()
		if Groups then Groups:Initialize() end
		
		BFL:ForceRefreshFriendsList()
		self:RefreshGroupsTab()
		return
	end
	
	local Groups = GetGroups()
	local r, g, b = 1, 1, 1
	
	if Groups then
		local group = Groups:Get(groupId)
		if group then
			if group.arrowColor then
				r, g, b = group.arrowColor.r, group.arrowColor.g, group.arrowColor.b
			elseif group.color then
				r, g, b = group.color.r, group.color.g, group.color.b
			end
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = 1.0
	info.hasOpacity = false
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		
		colorSwatch:SetColorTexture(newR, newG, newB)
		
		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = {r = newR, g = newG, b = newB}
		DB:Set("groupArrowColors", groupArrowColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.arrowColor = {r = newR, g = newG, b = newB}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	info.cancelFunc = function(previousValues)
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b)
		
		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
		DB:Set("groupArrowColors", groupArrowColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.arrowColor = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
	else
		ColorPickerFrame.func = info.swatchFunc
		ColorPickerFrame.cancelFunc = info.cancelFunc
		ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		ColorPickerFrame:Show()
	end
end

function Settings:ShowColorPicker(groupId, groupName, colorSwatch)
	local DB = GetDB()
	if not DB then return end
	
	local Groups = GetGroups()
	local r, g, b = 1, 1, 1
	
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			r, g, b = group.color.r, group.color.g, group.color.b
		else
			r, g, b = 1, 0.82, 0
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = 1.0
	info.hasOpacity = false
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		
		colorSwatch:SetColorTexture(newR, newG, newB)
		
		local groupColors = DB:Get("groupColors") or {}
		groupColors[groupId] = {r = newR, g = newG, b = newB}
		DB:Set("groupColors", groupColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.color = {r = newR, g = newG, b = newB}
			end
		end
		
		-- Force full display refresh for immediate color update
		BFL:ForceRefreshFriendsList()
	end
	info.cancelFunc = function(previousValues)
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b)
		
		local groupColors = DB:Get("groupColors") or {}
		groupColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
		DB:Set("groupColors", groupColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.color = {r = previousValues.r, g = previousValues.g, b = previousValues.b}
			end
		end
		
		-- Force full display refresh for immediate color update
		BFL:ForceRefreshFriendsList()
	end
	
	ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- Delete a custom group
function Settings:DeleteGroup(groupId, groupName)
	StaticPopupDialogs["BETTERFRIENDLIST_DELETE_GROUP"] = {
		text = string.format(L.DIALOG_DELETE_GROUP_SETTINGS, groupName),
		button1 = L.DIALOG_DELETE_GROUP_BTN1,
		button2 = L.DIALOG_DELETE_GROUP_BTN2,
		OnAccept = function()
			local Groups = GetGroups()
			local DB = GetDB()
			
			if not Groups or not DB then
				BFL:DebugPrint("|cffff0000BetterFriendlist:|r " .. L.ERROR_FAILED_DELETE_GROUP)
				return
			end
			
			local success, err = Groups:Delete(groupId)
			if success then
				BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.MSG_GROUP_DELETED, groupName))
				
				Settings:RefreshGroupList()
				
				-- Force full display refresh - groups affect display list structure
				BFL:ForceRefreshFriendsList()
			else
				BFL:DebugPrint("|cffff0000BetterFriendlist:|r " .. string.format(L.ERROR_FAILED_DELETE, (err or L.UNKNOWN_ERROR)))
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BETTERFRIENDLIST_DELETE_GROUP")
end

-- Rename a custom group
function Settings:RenameGroup(groupId, currentName)
	StaticPopupDialogs["BETTERFRIENDLIST_RENAME_GROUP"] = {
		text = string.format(L.DIALOG_RENAME_GROUP_SETTINGS, currentName),
		button1 = L.DIALOG_RENAME_GROUP_BTN1,
		button2 = L.DIALOG_RENAME_GROUP_BTN2,
		hasEditBox = true,
		maxLetters = 32,
		editBoxWidth = 200,
		OnShow = function(self)
			self.EditBox:SetText(currentName)
			self.EditBox:SetMaxLetters(32)
			self.EditBox:SetFocus()
			self.EditBox:HighlightText()
		end,
		OnAccept = function(self)
			local newName = self.EditBox:GetText()
			if newName and newName ~= "" and newName ~= currentName then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success = Groups:Rename(groupId, newName)
					if success then
						BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.MSG_GROUP_RENAMED, newName))
						Settings:RefreshGroupsTab()
						-- Force full display refresh - groups affect display list structure
						BFL:ForceRefreshFriendsList()
					else
						BFL:DebugPrint("|cffff0000BetterFriendlist:|r " .. L.ERROR_RENAME_FAILED)
					end
				end
			end
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			local newName = parent.EditBox:GetText()
			if newName and newName ~= "" and newName ~= currentName then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success = Groups:Rename(groupId, newName)
					if success then
						BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.MSG_GROUP_RENAMED, newName))
						Settings:RefreshGroupsTab()
						-- Force full display refresh - groups affect display list structure
						BFL:ForceRefreshFriendsList()
					else
						BFL:DebugPrint("|cffff0000BetterFriendlist:|r " .. L.ERROR_RENAME_FAILED)
					end
				end
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BETTERFRIENDLIST_RENAME_GROUP")
end

-- Migrate from FriendGroups addon
function Settings:MigrateFriendGroups(cleanupNotes, force)
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		-- BFL:DebugPrint("|cffff0000BetterFriendlist:|r Migration failed - modules not loaded!")
		return
	end
	
	-- Check if migration has already been completed
	if not force and DB:Get("friendGroupsMigrated") then
		BFL:DebugPrint("|cff00ffffBetterFriendlist:|r " .. L.MSG_MIGRATION_ALREADY_DONE)
		return
	end
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r " .. L.MSG_MIGRATION_STARTING)
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r DB module:", DB and "OK" or "MISSING")
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Groups module:", Groups and "OK" or "MISSING")
	
	local migratedFriends = 0
	local migratedGroups = {}
	local groupNameMap = {}
	local assignmentCount = 0
	local allGroupNames = {}
	local friendGroupAssignments = {}
	
	-- PHASE 1: Collect all group names from all friends
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Phase 1 - Collecting group names...")
	
	local numBNetFriends = BNGetNumFriends()
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Scanning", numBNetFriends, "BattleNet friends...")
	
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local battleTag = accountInfo.battleTag
			local noteText = accountInfo.note
			
			if noteText and noteText ~= "" then
				local actualNote, friendGroups = ParseFriendGroupsNote(noteText)
				
				if #friendGroups > 0 then
					-- Use battleTag as persistent identifier (bnetAccountID is temporary per session)
					local friendUID = "bnet_" .. (battleTag or tostring(accountInfo.bnetAccountID))
					friendGroupAssignments[friendUID] = {
						groups = friendGroups,
						actualNote = actualNote,
						isBNet = true,
						battleTag = battleTag
					}
					
					for _, groupName in ipairs(friendGroups) do
						if groupName ~= "[Favorites]" and groupName ~= "[No Group]" and groupName ~= "" then
							allGroupNames[groupName] = true
						end
					end
				end
			end
		end
	end
	
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Scanning", numWoWFriends, "WoW friends...")
	
	for i = 1, numWoWFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			-- Normalize name to always include realm
			local name = BFL:NormalizeWoWFriendName(info.name)
			
			-- Debug Logs for WoW Friend Migration
			if name then
				BFL:DebugPrint("  Found WoW friend:", name, "Note:", info.notes)
				local noteText = info.notes
				
				if noteText and noteText ~= "" then
					local actualNote, friendGroups = ParseFriendGroupsNote(noteText)
					
					BFL:DebugPrint("    Parsed Note:", actualNote, "Groups Found:", #friendGroups)
					
					if #friendGroups > 0 then
						local friendUID = "wow_" .. name
						BFL:DebugPrint("    Assigning to Groups. UID:", friendUID)
						
						friendGroupAssignments[friendUID] = {
							groups = friendGroups,
							actualNote = actualNote,
							isBNet = false,
							characterName = name
						}
						
						for _, groupName in ipairs(friendGroups) do
							BFL:DebugPrint("      Group:", groupName)
							if groupName ~= "[Favorites]" and groupName ~= "[No Group]" and groupName ~= "" then
								allGroupNames[groupName] = true
							end
						end
					end
				else
					BFL:DebugPrint("    No note found or empty.")
				end
			else
				BFL:DebugPrint("  Name normalization failed for:", info.name)
			end
		end
	end
	
	-- PHASE 2: Create groups in alphabetical order
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Phase 2 - Creating groups in alphabetical order...")
	
	local sortedGroupNames = {}
	for groupName in pairs(allGroupNames) do
		table.insert(sortedGroupNames, groupName)
	end
	table.sort(sortedGroupNames)
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Creating", #sortedGroupNames, "groups...")
	
	local currentOrder = 2
	local groupOrderArray = {"favorites"}
	
	for _, groupName in ipairs(sortedGroupNames) do
		local success, groupId = Groups:CreateWithOrder(groupName, currentOrder)
		if success and groupId then
			groupNameMap[groupName] = groupId
			migratedGroups[groupName] = true
			table.insert(groupOrderArray, groupId)
			BFL:DebugPrint("|cff00ff00BetterFriendlist:|r   ✓ Created:", groupName, "(order:", currentOrder, ")")
			currentOrder = currentOrder + 1
		else
			-- Group already exists - get its ID by name
			if groupId == "Group already exists" then
				local existingGroupId = Groups:GetGroupIdByName(groupName)
				if existingGroupId then
					groupNameMap[groupName] = existingGroupId
					migratedGroups[groupName] = true
					table.insert(groupOrderArray, existingGroupId)
					BFL:DebugPrint("|cffffff00BetterFriendlist:|r   [!] Existing:", groupName, "(using existing group)")
					currentOrder = currentOrder + 1
				else
					BFL:DebugPrint("|cffff0000BetterFriendlist:|r   ✗ FAILED:", groupName, "- Group exists but ID not found")
				end
			else
				BFL:DebugPrint("|cffff0000BetterFriendlist:|r   ✗ FAILED:", groupName, "-", tostring(groupId))
			end
		end
	end
	
	table.insert(groupOrderArray, "nogroup")
	
	DB:Set("groupOrder", groupOrderArray)
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Group order saved:", table.concat(groupOrderArray, ", "))
	
	-- PHASE 3: Assign friends to groups
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Phase 3 - Assigning friends to groups...")
	
	for friendUID, data in pairs(friendGroupAssignments) do
		migratedFriends = migratedFriends + 1
		
		for _, groupName in ipairs(data.groups) do
			if groupName ~= "[Favorites]" and groupName ~= "[No Group]" and groupName ~= "" then
				local groupId = groupNameMap[groupName]
				if groupId then
					local success = DB:AddFriendToGroup(friendUID, groupId)
					if success then
						assignmentCount = assignmentCount + 1
					end
				end
			end
		end
	end
	
	-- PHASE 4: Clean up notes if requested
	if cleanupNotes then
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Phase 4 - Cleaning up notes...")
		
		for friendUID, data in pairs(friendGroupAssignments) do
			if data.isBNet then
				-- Find bnetAccountID by battleTag (needed for BNSetFriendNote)
				local bnetAccountID = nil
				for i = 1, BNGetNumFriends() do
					local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
					if accountInfo and accountInfo.battleTag == data.battleTag then
						bnetAccountID = accountInfo.bnetAccountID
						break
					end
				end
				
				if bnetAccountID then
					if data.actualNote ~= "" then
						BNSetFriendNote(bnetAccountID, data.actualNote)
					else
						BNSetFriendNote(bnetAccountID, "")
					end
				end
			else
				if data.actualNote ~= "" then
					C_FriendList.SetFriendNotes(data.characterName, data.actualNote)
				else
					C_FriendList.SetFriendNotes(data.characterName, "")
				end
			end
		end
	end
	
	local numGroups = 0
	for _ in pairs(migratedGroups) do
		numGroups = numGroups + 1
	end
	
	local cleanupMsg = cleanupNotes and ("\n|cff00ff00" .. L.SETTINGS_NOTES_CLEANED .. "|r") or ("\n|cffffff00" .. L.SETTINGS_NOTES_PRESERVED .. "|r")
	
	-- Mark migration as completed
	DB:Set("friendGroupsMigrated", true)
	
	BFL:DebugPrint("|cff00ff00═══════════════════════════════════════")
	BFL:DebugPrint("|cff00ff00BetterFriendlist: " .. L.SETTINGS_MIGRATION_COMPLETE)
	BFL:DebugPrint("|cff00ff00═══════════════════════════════════════")
	BFL:DebugPrint(string.format(
		"|cff00ffff%s|r %d\n" ..
		"|cff00ffff%s|r %d\n" ..
		"|cff00ffff%s|r %d%s",
		L.SETTINGS_MIGRATION_FRIENDS,
		migratedFriends,
		L.SETTINGS_MIGRATION_GROUPS,
		numGroups,
		L.SETTINGS_MIGRATION_ASSIGNMENTS,
		assignmentCount,
		cleanupMsg
	))
	
	BFL:DebugPrint("|cff00ffffBetterFriendlist:|r Refreshing friends list...")
	-- Force full refresh - migration creates new groups which affect display list structure
	BFL:ForceRefreshFriendsList()
	BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Friends list refreshed!")
end

-- Show migration dialog
function Settings:ShowMigrationDialog()
	StaticPopupDialogs["BETTERFRIENDLIST_MIGRATE_FRIENDGROUPS"] = {
		text = L.DIALOG_MIGRATE_TEXT,
		button1 = L.DIALOG_MIGRATE_BTN1,
		button2 = L.DIALOG_MIGRATE_BTN2,
		button3 = L.DIALOG_MIGRATE_BTN3,
		OnAccept = function()
			Settings:MigrateFriendGroups(true, true)
		end,
		OnCancel = function()
			Settings:MigrateFriendGroups(false, true)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	StaticPopup_Show("BETTERFRIENDLIST_MIGRATE_FRIENDGROUPS")
end

-- Debug: Print database contents
function Settings:DebugDatabase()
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r =================================")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r DATABASE STATE")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r =================================")
	
	if not BetterFriendlistDB then
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Debug:|r BetterFriendlistDB is NIL!")
		return
	end
	
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r CUSTOM GROUPS:")
	if BetterFriendlistDB.customGroups then
		local groupCount = 0
		for groupId, groupInfo in pairs(BetterFriendlistDB.customGroups) do
			groupCount = groupCount + 1
			-- BFL:DebugPrint(string.format("|cff00ffffBetterFriendlist Debug:|r   [%s] = %s", groupId, groupInfo.name or "UNNAMED"))
		end
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r Total groups:", groupCount)
	else
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Debug:|r customGroups table MISSING!")
	end
	
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r FRIEND ASSIGNMENTS:")
	if BetterFriendlistDB.friendGroups then
		local friendCount = 0
		local totalAssignments = 0
		local assignedFriends = {}
		
		for friendUID, groups in pairs(BetterFriendlistDB.friendGroups) do
			-- Filter out non-string keys before concat
			local stringKeys = {}
			for _, v in ipairs(groups) do
				if type(v) == "string" then
					table.insert(stringKeys, v)
				end
			end
			
			-- Only show friends that have actual group assignments
			if #stringKeys > 0 then
				friendCount = friendCount + 1
				totalAssignments = totalAssignments + #stringKeys
				table.insert(assignedFriends, string.format("|cff00ffffBetterFriendlist Debug:|r   %s -> [%s]", friendUID, table.concat(stringKeys, ", ")))
			end
		end
		
		-- Sort and display
		table.sort(assignedFriends)
		for _, line in ipairs(assignedFriends) do
			-- BFL:DebugPrint(line)
		end
		
		if friendCount == 0 then
			-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r   (No friends assigned to custom groups)")
		end
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r Total friends with assignments:", friendCount)
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r Total assignments:", totalAssignments)
	else
		-- BFL:DebugPrint("|cffff0000BetterFriendlist Debug:|r friendGroups table MISSING!")
	end
	
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r GROUP ORDER:")
	if BetterFriendlistDB.groupOrder then
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r", table.concat(BetterFriendlistDB.groupOrder, ", "))
	else
		-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r Using default order (nil)")
	end
	
	-- Show current friends list
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r")
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r CURRENT FRIENDS:")
	
	-- Battle.net friends
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r Battle.net Friends:", numBNetTotal, string.format("(%d online)", numBNetOnline))
	if numBNetTotal > 0 then
		for i = 1, math.min(numBNetTotal, 10) do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local status = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline and "|cff00ff00ONLINE|r" or "|cffaaaaaaOFFLINE|r"
				local name = accountInfo.accountName ~= "???" and accountInfo.accountName or accountInfo.battleTag
				-- BFL:DebugPrint(string.format("|cff00ffffBetterFriendlist Debug:|r   [%d] %s - %s", i, name, status))
			end
		end
		if numBNetTotal > 10 then
			-- BFL:DebugPrint(string.format("|cff00ffffBetterFriendlist Debug:|r   ... and %d more", numBNetTotal - 10))
		end
	end
	
	-- WoW friends
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r")
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	local numWoWOnline = C_FriendList.GetNumOnlineFriends()
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r WoW Friends:", numWoWFriends, string.format("(%d online)", numWoWOnline))
	if numWoWFriends > 0 then
		for i = 1, math.min(numWoWFriends, 10) do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo then
				local status = friendInfo.connected and "|cff00ff00ONLINE|r" or "|cffaaaaaaOFFLINE|r"
				local level = friendInfo.level and friendInfo.level > 0 and string.format(" (Lvl %d)", friendInfo.level) or ""
				-- BFL:DebugPrint(string.format("|cff00ffffBetterFriendlist Debug:|r   [%d] %s%s - %s", i, friendInfo.name, level, status))
			end
		end
		if numWoWFriends > 10 then
			-- BFL:DebugPrint(string.format("|cff00ffffBetterFriendlist Debug:|r   ... and %d more", numWoWFriends - 10))
		end
	end
	
	-- BFL:DebugPrint("|cff00ffffBetterFriendlist Debug:|r =================================")
end

--------------------------------------------------------------------------
-- EXPORT / IMPORT SYSTEM
--------------------------------------------------------------------------

-- Export all settings to a string
function Settings:ExportSettings()
	if not BetterFriendlistDB then
		return nil, L.ERROR_DB_NOT_AVAILABLE
	end
	
	-- Collect data to export
	local exportData = {
		version = 2, -- Export format version (v2 includes all settings)
		-- Structure
		customGroups = {},
		friendGroups = {},
		groupOrder = {},
		groupStates = {},
		groupColors = {},
		-- General Settings
		compactMode = BetterFriendlistDB.compactMode,
		enableElvUISkin = BetterFriendlistDB.enableElvUISkin,
		fontSize = BetterFriendlistDB.fontSize,
		windowScale = BetterFriendlistDB.windowScale,
		hideMaxLevel = BetterFriendlistDB.hideMaxLevel,
		accordionGroups = BetterFriendlistDB.accordionGroups,
		showFavoritesGroup = BetterFriendlistDB.showFavoritesGroup,
		colorClassNames = BetterFriendlistDB.colorClassNames,
		hideEmptyGroups = BetterFriendlistDB.hideEmptyGroups,
		headerCountFormat = BetterFriendlistDB.headerCountFormat,
		groupHeaderAlign = BetterFriendlistDB.groupHeaderAlign,
		showGroupArrow = BetterFriendlistDB.showGroupArrow,
		groupArrowAlign = BetterFriendlistDB.groupArrowAlign,
		showFactionIcons = BetterFriendlistDB.showFactionIcons,
		showRealmName = BetterFriendlistDB.showRealmName,
		grayOtherFaction = BetterFriendlistDB.grayOtherFaction,
		showMobileAsAFK = BetterFriendlistDB.showMobileAsAFK,
		treatMobileAsOffline = BetterFriendlistDB.treatMobileAsOffline,
		nameDisplayFormat = BetterFriendlistDB.nameDisplayFormat,
		enableInGameGroup = BetterFriendlistDB.enableInGameGroup,
		inGameGroupMode = BetterFriendlistDB.inGameGroupMode,
		-- Font Settings
		fontFriendName = BetterFriendlistDB.fontFriendName,
		fontSizeFriendName = BetterFriendlistDB.fontSizeFriendName,
		fontOutlineFriendName = BetterFriendlistDB.fontOutlineFriendName,
		fontShadowFriendName = BetterFriendlistDB.fontShadowFriendName,
		fontColorFriendName = BetterFriendlistDB.fontColorFriendName,
		fontFriendInfo = BetterFriendlistDB.fontFriendInfo,
		fontSizeFriendInfo = BetterFriendlistDB.fontSizeFriendInfo,
		fontOutlineFriendInfo = BetterFriendlistDB.fontOutlineFriendInfo,
		fontShadowFriendInfo = BetterFriendlistDB.fontShadowFriendInfo,
		fontColorFriendInfo = BetterFriendlistDB.fontColorFriendInfo,
		fontGroupHeader = BetterFriendlistDB.fontGroupHeader,
		fontSizeGroupHeader = BetterFriendlistDB.fontSizeGroupHeader,
		fontOutlineGroupHeader = BetterFriendlistDB.fontOutlineGroupHeader,
		fontShadowGroupHeader = BetterFriendlistDB.fontShadowGroupHeader,
		colorGroupCount = BetterFriendlistDB.colorGroupCount,
		colorGroupArrow = BetterFriendlistDB.colorGroupArrow,
		-- Sort & Filter
		primarySort = BetterFriendlistDB.primarySort,
		secondarySort = BetterFriendlistDB.secondarySort,
		-- Notifications
		notificationDisplayMode = BetterFriendlistDB.notificationDisplayMode,
		notificationSoundEnabled = BetterFriendlistDB.notificationSoundEnabled,
		notificationOfflineEnabled = BetterFriendlistDB.notificationOfflineEnabled,
		notificationWowLoginEnabled = BetterFriendlistDB.notificationWowLoginEnabled,
		notificationCharSwitchEnabled = BetterFriendlistDB.notificationCharSwitchEnabled,
		notificationGameSwitchEnabled = BetterFriendlistDB.notificationGameSwitchEnabled,
		notificationQuietCombat = BetterFriendlistDB.notificationQuietCombat,
		notificationQuietInstance = BetterFriendlistDB.notificationQuietInstance,
		notificationQuietManual = BetterFriendlistDB.notificationQuietManual,
		notificationQuietScheduled = BetterFriendlistDB.notificationQuietScheduled,
		notificationQuietScheduleStartMinutes = BetterFriendlistDB.notificationQuietScheduleStartMinutes,
		notificationQuietScheduleEndMinutes = BetterFriendlistDB.notificationQuietScheduleEndMinutes,
		notificationMessageOnline = BetterFriendlistDB.notificationMessageOnline,
		notificationMessageOffline = BetterFriendlistDB.notificationMessageOffline,
		notificationMessageWowLogin = BetterFriendlistDB.notificationMessageWowLogin,
		notificationMessageCharSwitch = BetterFriendlistDB.notificationMessageCharSwitch,
		notificationMessageGameSwitch = BetterFriendlistDB.notificationMessageGameSwitch,
		notificationFriendRules = BetterFriendlistDB.notificationFriendRules,
		notificationGroupRules = BetterFriendlistDB.notificationGroupRules,
		notificationGroupTriggers = BetterFriendlistDB.notificationGroupTriggers,
		notificationToastPosition = BetterFriendlistDB.notificationToastPosition,
		-- Broker
		brokerEnabled = BetterFriendlistDB.brokerEnabled,
		brokerShowIcon = BetterFriendlistDB.brokerShowIcon,
		brokerShowLabel = BetterFriendlistDB.brokerShowLabel,
		brokerShowTotal = BetterFriendlistDB.brokerShowTotal,
		brokerShowGroups = BetterFriendlistDB.brokerShowGroups,
		brokerTooltipMode = BetterFriendlistDB.brokerTooltipMode,
		brokerClickAction = BetterFriendlistDB.brokerClickAction,
		-- Sync
		enableGlobalSync = BetterFriendlistDB.enableGlobalSync,
		enableGlobalSyncDeletion = BetterFriendlistDB.enableGlobalSyncDeletion,
		-- Other
		nicknames = BetterFriendlistDB.nicknames,
		enableBetaFeatures = BetterFriendlistDB.enableBetaFeatures,
	}
	
	-- Export custom groups with all properties
	if BetterFriendlistDB.customGroups then
		for groupId, groupInfo in pairs(BetterFriendlistDB.customGroups) do
			exportData.customGroups[groupId] = {
				name = groupInfo.name,
				collapsed = groupInfo.collapsed,
				order = groupInfo.order,
				color = groupInfo.color and {
					r = groupInfo.color.r,
					g = groupInfo.color.g,
					b = groupInfo.color.b
				} or nil
			}
		end
	end
	
	-- Export friend-to-group assignments
	if BetterFriendlistDB.friendGroups then
		for friendUID, groups in pairs(BetterFriendlistDB.friendGroups) do
			exportData.friendGroups[friendUID] = {}
			for _, groupId in ipairs(groups) do
				table.insert(exportData.friendGroups[friendUID], groupId)
			end
		end
	end
	
	-- Export group order
	if BetterFriendlistDB.groupOrder then
		for _, groupId in ipairs(BetterFriendlistDB.groupOrder) do
			table.insert(exportData.groupOrder, groupId)
		end
	end
	
	-- Export group states (collapsed)
	if BetterFriendlistDB.groupStates then
		for groupId, collapsed in pairs(BetterFriendlistDB.groupStates) do
			exportData.groupStates[groupId] = collapsed
		end
	end
	
	-- Export group colors (user-customized colors)
	if BetterFriendlistDB.groupColors then
		exportData.groupColors = {}
		for groupId, color in pairs(BetterFriendlistDB.groupColors) do
			if color and color.r and color.g and color.b then
				exportData.groupColors[groupId] = {
					r = color.r,
					g = color.g,
					b = color.b
				}
			end
		end
	end
	
	-- Serialize to string using LibSerialize or manual encoding
	local serialized = self:SerializeTable(exportData)
	
	if not serialized then
		return nil, L.ERROR_EXPORT_SERIALIZE
	end
	
	-- Encode to base64-like format for easy copy/paste
	local encoded = self:EncodeString(serialized)
	
	return encoded, nil
end

-- Import settings from string
function Settings:ImportSettings(importString)
	if not importString or importString == "" then
		return false, L.ERROR_IMPORT_EMPTY
	end
	
	-- Decode from base64-like format
	local decoded = self:DecodeString(importString)
	if not decoded then
		return false, L.ERROR_IMPORT_DECODE
	end
	
	-- Deserialize
	local importData = self:DeserializeTable(decoded)
	if not importData then
		return false, L.ERROR_IMPORT_DESERIALIZE
	end
	
	-- Validate version
	if not importData.version or (importData.version ~= 1 and importData.version ~= 2) then
		return false, L.ERROR_EXPORT_VERSION
	end
	
	-- Validate structure
	if not importData.customGroups or not importData.friendGroups then
		return false, L.ERROR_EXPORT_STRUCTURE
	end
	
	-- IMPORT DATA
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		return false, L.ERROR_MODULES_NOT_LOADED
	end
	
	-- Clear existing data (Common to v1 and v2)
	BetterFriendlistDB.customGroups = {}
	BetterFriendlistDB.friendGroups = {}
	BetterFriendlistDB.groupOrder = {}
	BetterFriendlistDB.groupStates = {}
	
	-- Import custom groups
	if importData.customGroups then
		for groupId, groupInfo in pairs(importData.customGroups) do
			BetterFriendlistDB.customGroups[groupId] = {
				name = groupInfo.name,
				collapsed = groupInfo.collapsed or false,
				order = groupInfo.order or 2,
				color = groupInfo.color or {r = 1.0, g = 0.82, b = 0.0}
			}
		end
	end
	
	-- Import friend assignments
	if importData.friendGroups then
		for friendUID, groups in pairs(importData.friendGroups) do
			BetterFriendlistDB.friendGroups[friendUID] = {}
			for _, groupId in ipairs(groups) do
				table.insert(BetterFriendlistDB.friendGroups[friendUID], groupId)
			end
		end
	end
	
	-- Import group order
	if importData.groupOrder then
		for _, groupId in ipairs(importData.groupOrder) do
			table.insert(BetterFriendlistDB.groupOrder, groupId)
		end
	end
	
	-- Import group states
	if importData.groupStates then
		for groupId, collapsed in pairs(importData.groupStates) do
			BetterFriendlistDB.groupStates[groupId] = collapsed
		end
	end
	
	-- Import group colors (user-customized colors)
	if importData.groupColors then
		BetterFriendlistDB.groupColors = {}
		for groupId, color in pairs(importData.groupColors) do
			if color and color.r and color.g and color.b then
				BetterFriendlistDB.groupColors[groupId] = {
					r = color.r,
					g = color.g,
					b = color.b
				}
			end
		end
	end

	-- Version 2: Import all other settings
	if importData.version >= 2 then
		local keysToImport = {
			-- General
			"compactMode", "enableElvUISkin", "fontSize", "windowScale", 
			"hideMaxLevel", "accordionGroups", "showFavoritesGroup", "colorClassNames",
			"hideEmptyGroups", "headerCountFormat", "groupHeaderAlign", "showGroupArrow",
			"groupArrowAlign", "showFactionIcons", "showRealmName", "grayOtherFaction",
			"showMobileAsAFK", "treatMobileAsOffline", "nameDisplayFormat", 
			"enableInGameGroup", "inGameGroupMode",
			-- Fonts
			"fontFriendName", "fontSizeFriendName", "fontOutlineFriendName", "fontShadowFriendName",
			"fontColorFriendName", "fontFriendInfo", "fontSizeFriendInfo", "fontOutlineFriendInfo",
			"fontShadowFriendInfo", "fontColorFriendInfo", "fontGroupHeader", "fontSizeGroupHeader",
			"fontOutlineGroupHeader", "fontShadowGroupHeader", "colorGroupCount", "colorGroupArrow",
			-- Sort & Filter
			"primarySort", "secondarySort",
			-- Notifications
			"notificationDisplayMode", "notificationSoundEnabled",
			"notificationOfflineEnabled", "notificationWowLoginEnabled",
			"notificationCharSwitchEnabled", "notificationGameSwitchEnabled",
			"notificationQuietCombat", "notificationQuietInstance", "notificationQuietManual",
			"notificationQuietScheduled", "notificationQuietScheduleStartMinutes", 
			"notificationQuietScheduleEndMinutes",
			"notificationMessageOnline", "notificationMessageOffline",
			"notificationMessageWowLogin", "notificationMessageCharSwitch",
			"notificationMessageGameSwitch",
			"notificationFriendRules", "notificationGroupRules", "notificationGroupTriggers",
			"notificationToastPosition",
			-- Broker
			"brokerEnabled", "brokerShowIcon", "brokerShowLabel", 
			"brokerShowTotal", "brokerShowGroups", "brokerTooltipMode", "brokerClickAction",
			-- Sync
			"enableGlobalSync", "enableGlobalSyncDeletion",
			-- Other
			"nicknames", "enableBetaFeatures"
		}

		for _, key in ipairs(keysToImport) do
			if importData[key] ~= nil then
				BetterFriendlistDB[key] = importData[key]
			end
		end
	end
	
	-- Reload Groups module (this will apply imported colors)
	Groups:Initialize()
	
	-- Force full display refresh - import affects groups and display structure
	BFL:ForceRefreshFriendsList()
	
	return true, nil
end

-- Simple table serialization (Lua table to string)
function Settings:SerializeTable(tbl)
	local function serialize(val, depth)
		depth = depth or 0
		if depth > UI.MAX_RECURSION_DEPTH then return "nil" end -- Prevent infinite recursion
		
		local t = type(val)
		if t == "number" then
			return tostring(val)
		elseif t == "boolean" then
			return val and "true" or "false"
		elseif t == "string" then
			return string.format("%q", val)
		elseif t == "table" then
			local parts = {}
			table.insert(parts, "{")
			for k, v in pairs(val) do
				local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", tostring(k))
				table.insert(parts, key .. "=" .. serialize(v, depth + 1) .. ",")
			end
			table.insert(parts, "}")
			return table.concat(parts)
		else
			return "nil"
		end
	end
	
	return serialize(tbl)
end

-- Deserialize string to table
function Settings:DeserializeTable(str)
	if not str or str == "" then
		return nil
	end
	
	-- Use loadstring (safe because we control the format)
	local func, err = loadstring("return " .. str)
	if not func then
		return nil
	end
	
	local success, result = pcall(func)
	if not success then
		return nil
	end
	
	return result
end

-- Encode string to base64-like format (simple compression-safe encoding)
function Settings:EncodeString(str)
	-- Simple encoding: convert to hex representation
	local hexParts = {}
	for i = 1, #str do
		table.insert(hexParts, string.format("%02x", string.byte(str, i)))
	end
	return "BFL1:" .. table.concat(hexParts) -- BFL1: prefix for version identification
end

-- Decode base64-like format back to string
function Settings:DecodeString(encoded)
	-- Check prefix
	if not encoded or not string.match(encoded, "^BFL1:") then
		return nil
	end
	
	-- Remove prefix
	local hex = string.sub(encoded, 6)
	
	-- Convert hex back to string
	local chars = {}
	for i = 1, #hex, 2 do
		local byte = tonumber(string.sub(hex, i, i+1), 16)
		if not byte then
			return nil
		end
		table.insert(chars, string.char(byte))
	end
	
	return table.concat(chars)
end

-- Show export dialog with scrollable text
function Settings:ShowExportDialog()
	local exportString, err = self:ExportSettings()
	
	if not exportString then
		BFL:DebugPrint("Export failed:", err or "Unknown error")
		return
	end
	
	-- Create or reuse export frame
	if not self.exportFrame then
		self:CreateExportFrame()
	end
	
	-- Set text and show
	self.exportFrame.scrollFrame.editBox:SetText(exportString)
	self.exportFrame.scrollFrame.editBox:HighlightText()
	self.exportFrame.scrollFrame.editBox:SetFocus()
	self.exportFrame:Show()
	
	BFL:DebugPrint("Export complete! Copy the text from the dialog.")
end

-- Show import dialog
function Settings:ShowImportDialog()
	-- Create or reuse import frame
	if not self.importFrame then
		self:CreateImportFrame()
	end
	
	-- Clear and show
	self.importFrame.scrollFrame.editBox:SetText("")
	self.importFrame.scrollFrame.editBox:SetFocus()
	self.importFrame:Show()
end

-- Refresh statistics display
function Settings:RefreshStatistics()
	if not settingsFrame then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.StatisticsTab then return end
	
	local statsTab = content.StatisticsTab
	
	-- Get Statistics module
	local Statistics = BFL:GetModule("Statistics")
	if not Statistics then
		-- BFL:DebugPrint("Settings: Statistics module not available")
		return
	end
	
	-- Get statistics data
	local stats = Statistics:GetStatistics()
	if not stats then
		-- BFL:DebugPrint("Settings: Failed to get statistics")
		return
	end
	
	-- Helper function to format percentage
	local function FormatPercent(value, total)
		if total == 0 then return 0 end
		return math.floor((value / total) * 100 + 0.5)
	end
	
	-- Update Overview section
	if statsTab.TotalFriends then
		statsTab.TotalFriends:SetText(string.format(L.STATS_TOTAL_FRIENDS, stats.totalFriends))
	end
	
	if statsTab.OnlineFriends then
		local onlinePct = FormatPercent(stats.onlineFriends, stats.totalFriends)
		local offlinePct = FormatPercent(stats.offlineFriends, stats.totalFriends)
		statsTab.OnlineFriends:SetText(string.format(L.STATS_ONLINE_OFFLINE, 
			stats.onlineFriends, onlinePct, stats.offlineFriends, offlinePct))
	end
	
	if statsTab.FriendTypes then
		statsTab.FriendTypes:SetText(string.format(L.STATS_BNET_WOW, 
			stats.bnetFriends, stats.wowFriends))
	end
	
	-- Update Friendship Health (NEW)
	if statsTab.FriendshipHealth then
		local totalHealthFriends = stats.totalFriends - (stats.friendshipHealth.unknown or 0)
		if totalHealthFriends > 0 then
			local healthText = string.format(
				L.STATS_HEALTH_FMT,
				stats.friendshipHealth.active, FormatPercent(stats.friendshipHealth.active, totalHealthFriends),
				stats.friendshipHealth.regular, FormatPercent(stats.friendshipHealth.regular, totalHealthFriends),
				stats.friendshipHealth.drifting, FormatPercent(stats.friendshipHealth.drifting, totalHealthFriends),
				stats.friendshipHealth.stale, FormatPercent(stats.friendshipHealth.stale, totalHealthFriends),
				stats.friendshipHealth.dormant, FormatPercent(stats.friendshipHealth.dormant, totalHealthFriends)
			)
			statsTab.FriendshipHealth:SetText(healthText)
		else
			statsTab.FriendshipHealth:SetText(L.STATS_NO_HEALTH_DATA)
		end
	end
	
	-- Update Top 5 Classes
	if statsTab.ClassList then
		local topClasses = Statistics:GetTopClasses(5)
		if topClasses and #topClasses > 0 then
			local classParts = {}
			for i, class in ipairs(topClasses) do
				if i > 1 then table.insert(classParts, "\n") end
				local pct = FormatPercent(class.count, stats.totalFriends)
				table.insert(classParts, string.format(L.STATS_CLASS_FMT, i, class.name, class.count, pct))
			end
			statsTab.ClassList:SetText(table.concat(classParts))
		else
			statsTab.ClassList:SetText(L.STATS_NO_CLASS_DATA)
		end
	end
	
	-- Update Level Distribution (NEW)
	if statsTab.LevelDistribution then
		if stats.levelDistribution.leveledFriends > 0 then
			local levelText = string.format(
				L.STATS_MAX_LEVEL,
				stats.levelDistribution.maxLevel,
				stats.levelDistribution.ranges[1].count,
				stats.levelDistribution.ranges[2].count,
				stats.levelDistribution.ranges[3].count,
				stats.levelDistribution.ranges[3].count and stats.levelDistribution.average
			)
			-- Logic fix in my mind: code used stats.levelDistribution.average as last arg.
			-- Let's check original code carefully.
			local levelText = string.format(
				L.STATS_MAX_LEVEL,
				stats.levelDistribution.maxLevel,
				stats.levelDistribution.ranges[1].count,
				stats.levelDistribution.ranges[2].count,
				stats.levelDistribution.ranges[3].count,
				stats.levelDistribution.average
			)
			statsTab.LevelDistribution:SetText(levelText)
		else
			statsTab.LevelDistribution:SetText(L.STATS_NO_LEVEL_DATA)
		end
	end
	
	-- Update Top 5 Realms
	if statsTab.RealmList then
		local topRealms = Statistics:GetTopRealms(5)
		if topRealms and #topRealms > 0 then
			local realmParts = {}
			-- Add realm categories first
			local samePct = FormatPercent(stats.realmDistribution.sameRealm, stats.totalFriends)
			local otherPct = FormatPercent(stats.realmDistribution.otherRealms, stats.totalFriends)
			table.insert(realmParts, string.format(L.STATS_SAME_REALM,
				stats.realmDistribution.sameRealm, samePct,
				stats.realmDistribution.otherRealms, otherPct))
			table.insert(realmParts, L.STATS_TOP_REALMS)
			for i, realm in ipairs(topRealms) do
				table.insert(realmParts, string.format(L.STATS_REALM_FMT, i, realm.name, realm.count))
			end
			statsTab.RealmList:SetText(table.concat(realmParts))
		else
			statsTab.RealmList:SetText(L.STATS_NO_REALM_DATA)
		end
	end
	
	-- Update Faction Distribution
	if statsTab.FactionList then
		local factionText = string.format(
			L.STATS_FACTION_DISTRIBUTION,
			stats.factionCounts.alliance or 0,
			stats.factionCounts.horde or 0
		)
		statsTab.FactionList:SetText(factionText)
	end
	
	-- Update Game Distribution (NEW)
	if statsTab.GameDistribution then
		local totalGamePlayers = stats.gameCounts.wow + stats.gameCounts.classic + stats.gameCounts.diablo + 
		                         stats.gameCounts.hearthstone + stats.gameCounts.starcraft + stats.gameCounts.mobile + stats.gameCounts.other
		if totalGamePlayers > 0 then
			local gameParts = {}
			if stats.gameCounts.wow > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_WOW, stats.gameCounts.wow))
			end
			if stats.gameCounts.classic > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_CLASSIC, stats.gameCounts.classic))
			end
			if stats.gameCounts.diablo > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_DIABLO, stats.gameCounts.diablo))
			end
			if stats.gameCounts.hearthstone > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_HEARTHSTONE, stats.gameCounts.hearthstone))
			end
			if stats.gameCounts.mobile > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_MOBILE, stats.gameCounts.mobile))
			end
			if stats.gameCounts.other > 0 then
				table.insert(gameParts, string.format(L.STATS_GAME_OTHER, stats.gameCounts.other))
			end
			statsTab.GameDistribution:SetText(table.concat(gameParts))
		else
			statsTab.GameDistribution:SetText(L.STATS_NO_GAME_DATA)
		end
	end
	
	-- Update Mobile vs Desktop (NEW)
	if statsTab.MobileVsDesktop then
		if stats.mobileVsDesktop.desktop > 0 or stats.mobileVsDesktop.mobile > 0 then
			local total = stats.mobileVsDesktop.desktop + stats.mobileVsDesktop.mobile
			local desktopPct = FormatPercent(stats.mobileVsDesktop.desktop, total)
			local mobilePct = FormatPercent(stats.mobileVsDesktop.mobile, total)
			local mobileText = string.format(
				L.STATS_MOBILE_DESKTOP,
				stats.mobileVsDesktop.desktop, desktopPct,
				stats.mobileVsDesktop.mobile, mobilePct
			)
			statsTab.MobileVsDesktop:SetText(mobileText)
		else
			statsTab.MobileVsDesktop:SetText(L.STATS_NO_MOBILE_DATA)
		end
	end
	
	-- Update Notes and Favorites (NEW)
	if statsTab.NotesAndFavorites then
		local notesPct = FormatPercent(stats.notesAndFavorites.withNotes, stats.totalFriends)
		local favPct = FormatPercent(stats.notesAndFavorites.favorites, stats.totalFriends)
		local notesText = string.format(
			L.STATS_NOTES_FAVORITES,
			stats.notesAndFavorites.withNotes, notesPct,
			stats.notesAndFavorites.favorites, favPct
		)
		statsTab.NotesAndFavorites:SetText(notesText)
	end
	
	-- BFL:DebugPrint("Settings: Statistics refreshed successfully")
end

-- Create export frame
function Settings:CreateExportFrame()
	local frame = CreateFrame("Frame", "BetterFriendlistExportFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(500, 400)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	
	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	frame.title:SetPoint("TOP", 0, -5)
	frame.title:SetText(L.SETTINGS_EXPORT_TITLE)
	
	-- Info text
	frame.info = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	frame.info:SetPoint("TOPLEFT", 15, -30)
	frame.info:SetPoint("TOPRIGHT", -15, -30)
	frame.info:SetJustifyH("LEFT")
	frame.info:SetText(L.SETTINGS_EXPORT_INFO)
	
	-- Scroll frame with edit box
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", UI.SPACING_MEDIUM, -60)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
	frame.scrollFrame = scrollFrame
	
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(BetterFriendlistFontHighlight)
	editBox:SetWidth(460)
	editBox:SetAutoFocus(false)
	editBox:SetScript("OnEscapePressed", function(self)
		frame:Hide()
	end)
	scrollFrame:SetScrollChild(editBox)
	scrollFrame.editBox = editBox
	
	-- Copy All button
	local copyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	copyButton:SetPoint("BOTTOM", 0, 15)
	copyButton:SetSize(120, 25)
	copyButton:SetText(L.SETTINGS_EXPORT_BTN)
	copyButton:SetNormalFontObject("BetterFriendlistFontNormal")
	copyButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	copyButton:SetScript("OnClick", function()
		editBox:HighlightText()
		editBox:SetFocus()
	end)
	
	self.exportFrame = frame
end

-- Create import frame
function Settings:CreateImportFrame()
	local frame = CreateFrame("Frame", "BetterFriendlistImportFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(500, 400)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	
	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	frame.title:SetPoint("TOP", 0, -5)
	frame.title:SetText(L.SETTINGS_IMPORT_TITLE)
	
	-- Info text
	frame.info = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	frame.info:SetPoint("TOPLEFT", 15, -30)
	frame.info:SetPoint("TOPRIGHT", -15, -30)
	frame.info:SetJustifyH("LEFT")
	frame.info:SetText(L.SETTINGS_IMPORT_INFO)
	
	-- Scroll frame with edit box
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", UI.SPACING_MEDIUM, -80)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
	frame.scrollFrame = scrollFrame
	
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(BetterFriendlistFontHighlight)
	editBox:SetWidth(460)
	editBox:SetAutoFocus(true)
	editBox:SetScript("OnEscapePressed", function(self)
		frame:Hide()
	end)
	scrollFrame:SetScrollChild(editBox)
	scrollFrame.editBox = editBox
	
	-- Import button
	local importButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	importButton:SetPoint("BOTTOM", -65, 15)
	importButton:SetSize(120, 25)
	importButton:SetText(L.SETTINGS_IMPORT_BTN)
	importButton:SetNormalFontObject("BetterFriendlistFontNormal")
	importButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	importButton:SetScript("OnClick", function()
		local importString = editBox:GetText()
		local success, err = Settings:ImportSettings(importString)
		
		if success then
			BFL:DebugPrint(L.SETTINGS_IMPORT_SUCCESS)
			frame:Hide()
		else
			BFL:DebugPrint(L.SETTINGS_IMPORT_FAILED .. (err or "Unknown error"))
			-- Show error in UI
			StaticPopupDialogs["BETTERFRIENDLIST_IMPORT_ERROR"] = {
				text = L.SETTINGS_IMPORT_FAILED .. (err or "Unknown error"),
				button1 = "OK",
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("BETTERFRIENDLIST_IMPORT_ERROR")
		end
	end)
	
	-- Cancel button
	local cancelButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	cancelButton:SetPoint("BOTTOM", 65, 15)
	cancelButton:SetSize(120, 25)
	cancelButton:SetText(L.SETTINGS_IMPORT_CANCEL)
	cancelButton:SetNormalFontObject("BetterFriendlistFontNormal")
	cancelButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	cancelButton:SetScript("OnClick", function()
		frame:Hide()
	end)
	
	self.importFrame = frame
end

--------------------------------------------------------------------------
-- CALLBACK FUNCTIONS (Called from Settings.lua wrapper)
--------------------------------------------------------------------------

-- Callback for CompactMode checkbox
function Settings:OnCompactModeChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("compactMode", checked)
	
	-- CRITICAL: Force full display refresh to recalculate button heights
	BFL:ForceRefreshFriendsList()
end

-- Callback for ShowBlizzardOption checkbox
function Settings:OnShowBlizzardOptionChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showBlizzardOption", checked)
	
	-- Force full display refresh for immediate update
	BFL:ForceRefreshFriendsList()
end

-- Callback for ColorClassNames checkbox
function Settings:OnColorClassNamesChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("colorClassNames", checked)
	
	-- Force full display refresh for immediate update
	BFL:ForceRefreshFriendsList()
end

-- Callback for HideEmptyGroups checkbox
function Settings:OnHideEmptyGroupsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("hideEmptyGroups", checked)
	
	-- Affects which groups are shown - needs display list rebuild
	BFL:ForceRefreshFriendsList()
end

-- Show Faction Icons toggle
function Settings:OnShowFactionIconsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showFactionIcons", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- Show Realm Name toggle
function Settings:OnShowRealmNameChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showRealmName", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- Show Favorites Group toggle
function Settings:OnShowFavoritesGroupChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showFavoritesGroup", checked)
	
	-- Affects which groups are shown - needs display list rebuild
	BFL:ForceRefreshFriendsList()
end

-- Gray Other Faction toggle
function Settings:OnGrayOtherFactionChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("grayOtherFaction", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- Show Mobile as AFK toggle
function Settings:OnShowMobileAsAFKChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showMobileAsAFK", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- NEW: Treat Mobile as Offline toggle (Feature Request)
function Settings:OnTreatMobileAsOfflineChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("treatMobileAsOffline", checked)
	
	-- IMPORTANT: This option affects data LOADING (not just display)
	-- Must force full data reload from API, not just display update
	-- UpdateFriendsList() re-reads all friends from C_BattleNet API
	-- where treatMobileAsOffline logic is applied during data processing
	local FriendsList = BFL and BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.UpdateFriendsList then
		FriendsList:UpdateFriendsList()
	end
end


-- Hide Max Level toggle
function Settings:OnHideMaxLevelChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("hideMaxLevel", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- Accordion Groups toggle
function Settings:OnAccordionGroupsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("accordionGroups", checked)
	
	-- Display-only change - re-render existing data
	BFL:ForceRefreshFriendsList()
end

-- Classic: Close on Guild Tab Click toggle
function Settings:OnCloseOnGuildTabClickChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("closeOnGuildTabClick", checked)
	-- No UI refresh needed - only affects Guild tab click behavior
end

-- Use UI Panel System toggle
function Settings:OnUseUIPanelSystemChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	-- Save the pending state temporarily
	DB.pendingUIPanelSystemChange = checked
	
	-- Show confirmation dialog
	StaticPopup_Show("BFL_CONFIRM_UI_PANEL_RELOAD")
end

-- Simple Mode Toggle
function Settings:OnSimpleModeChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("simpleMode", checked)

	-- Update Main Frame Layout (Show/Hide Tabs) FIRST
	-- This ensures the Frame is on Tab 1 (Friends) and contexts like ScrollFrame visibility are established
	-- BEFORE we try to calculate SearchBox visibility/parenting.
	if BetterFriendsFrame_ShowBottomTab then
		BetterFriendsFrame_ShowBottomTab(1)
	end
	
	-- Refresh Friends List Layout immediately
	-- Force UpdateScrollBoxExtent explicitly for instant UI feedback (SearchBox position)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.UpdateScrollBoxExtent then
		FriendsList:UpdateScrollBoxExtent()
		-- Double-tap: Update again on next frame to catch any layout resolution issues (SearchBox)
		C_Timer.After(0.01, function() 
			if FriendsList and FriendsList.UpdateScrollBoxExtent then 
				FriendsList:UpdateScrollBoxExtent() 
			end
		end)
	end
	
	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
	
	-- Update Portrait Visibility immediately
	if BFL.UpdatePortraitVisibility then
		BFL:UpdatePortraitVisibility("SettingsToggle")
	end
	
	-- Classic Fix: Prompt for Reload on Simple Mode toggle
	-- The Atlas texture system in Classic is unstable dynamically but works fine on login
	if BFL.IsClassic then
		StaticPopupDialogs["BFL_SIMPLE_MODE_RELOAD"] = {
			text = (L.MSG_RELOAD_REQUIRED or "A reload is required to apply this change correctly in Classic.") .. "\n\n" .. (L.MSG_RELOAD_NOW or "Reload UI now?"),
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = ReloadUI,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BFL_SIMPLE_MODE_RELOAD")
	end
end

-- Legacy code (no longer needed with ReloadUI)
--[[ function Settings:OnUseUIPanelSystemChanged_OLD(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("useUIPanelSystem", checked)
	
	-- Apply immediately if frame is shown (only out of combat)
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() and not InCombatLockdown() then
		if checked then
			-- Configure attributes and switch to ShowUIPanel
			if _G.ConfigureUIPanelAttributes then
				_G.ConfigureUIPanelAttributes(true)
			end
			BetterFriendsFrame:Hide()
			ShowUIPanel(BetterFriendsFrame)
			BFL:DebugPrint("Switched to UI Panel System")
		else
			-- Disable attributes and switch to direct Show/Hide
			-- CRITICAL: Use HideUIPanel first to properly unregister from UI Panel system
			if UIPanelWindows["BetterFriendsFrame"] then
				HideUIPanel(BetterFriendsFrame)
			else
				BetterFriendsFrame:Hide()
			end
			
			-- Now disable attributes (this removes from UIPanelWindows)
			if _G.ConfigureUIPanelAttributes then
				_G.ConfigureUIPanelAttributes(false)
			end
			
			-- Reopen with normal Show() (no longer a UIPanel)
			BetterFriendsFrame:Show()
			BFL:DebugPrint("Switched to direct Show/Hide")
		end
	elseif InCombatLockdown() then
		BFL:DebugPrint("Setting saved - will apply after combat ends")
	end
end
--]]

-- Classic: Hide Guild Tab toggle
function Settings:OnHideGuildTabChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("hideGuildTab", checked)
	
	-- Toggle Guild Tab visibility and reposition Raid tab immediately
	if BetterFriendsFrame and BetterFriendsFrame.BottomTab3 then
		if checked then
			BetterFriendsFrame.BottomTab3:Hide()
			-- Reposition Raid tab (Tab 4) next to WHO tab (Tab 2)
			if BetterFriendsFrame.BottomTab4 then
				BetterFriendsFrame.BottomTab4:ClearAllPoints()
				BetterFriendsFrame.BottomTab4:SetPoint("LEFT", BetterFriendsFrame.BottomTab2, "RIGHT", -15, 0)
			end
		else
			BetterFriendsFrame.BottomTab3:Show()
			-- Restore Guild tab text and click handler
			BetterFriendsFrame.BottomTab3:SetText(GUILD or "Guild")
			BetterFriendsFrame.BottomTab3:SetScript("OnClick", function(self)
				BetterFriendsFrame_HandleGuildTabClick()
			end)
			-- Reposition Raid tab (Tab 4) next to Guild tab (Tab 3)
			if BetterFriendsFrame.BottomTab4 then
				BetterFriendsFrame.BottomTab4:ClearAllPoints()
				BetterFriendsFrame.BottomTab4:SetPoint("LEFT", BetterFriendsFrame.BottomTab3, "RIGHT", -15, 0)
			end
		end
	end
end

-- NEW: Enable In-Game Group toggle (Feature Request)
function Settings:OnEnableInGameGroupChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("enableInGameGroup", checked)
	
	-- Affects group structure - needs full refresh
	BFL:ForceRefreshFriendsList()
	
	-- Refresh settings to show/hide sub-option
	self:RefreshGeneralTab()
end

-- NEW: In-Game Group Mode (Feature Request)
function Settings:OnInGameGroupModeChanged(value)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("inGameGroupMode", value)
	
	-- Affects group structure - needs full refresh
	BFL:ForceRefreshFriendsList()
end

--------------------------------------------------------------------------
-- NEW: TAB REFRESH FUNCTIONS
--------------------------------------------------------------------------

-- Refresh General Tab with new component library
function Settings:RefreshGeneralTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.GeneralTab then return end
	
	local tab = content.GeneralTab
	local DB = GetDB()
	if not DB then return end
	
	-- Clear existing content (but keep the tab frame itself)
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	
	-- Header: Display Options
	local displayHeader = Components:CreateHeader(tab, L.SETTINGS_DISPLAY_OPTIONS or "Display Options")
	table.insert(allFrames, displayHeader)
	
-- Row 1: Color Class Names & Hide Empty Groups
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_COLOR_CLASS_NAMES,
			initialValue = DB:Get("colorClassNames", true),
			callback = function(val) self:OnColorClassNamesChanged(val) end,
			tooltipTitle = L.SETTINGS_COLOR_CLASS_NAMES,
			tooltipDesc = L.SETTINGS_COLOR_CLASS_NAMES_DESC or "Colors character names using their class color for easier identification"
		},
		{
			label = L.SETTINGS_HIDE_EMPTY_GROUPS,
			initialValue = DB:Get("hideEmptyGroups", false),
			callback = function(val) self:OnHideEmptyGroupsChanged(val) end,
			tooltipTitle = L.SETTINGS_HIDE_EMPTY_GROUPS,
			tooltipDesc = L.SETTINGS_HIDE_EMPTY_GROUPS_DESC or "Automatically hides groups that have no online members"
		}
	))

	-- Row 2: Show Faction Icons & Show Faction Background
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_SHOW_FACTION_ICONS,
			initialValue = DB:Get("showFactionIcons", true),
			callback = function(val) self:OnShowFactionIconsChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_FACTION_ICONS,
			tooltipDesc = L.SETTINGS_SHOW_FACTION_ICONS_DESC or "Display Alliance/Horde icons next to character names"
		},
		{
			label = L.SETTINGS_SHOW_FACTION_BG,
			initialValue = DB:Get("showFactionBg", false),
			callback = function(val) 
				local DB = GetDB()
				DB:Set("showFactionBg", val) 
				BFL:ForceRefreshFriendsList()
			end,
			tooltipTitle = L.SETTINGS_SHOW_FACTION_BG,
			tooltipDesc = L.SETTINGS_SHOW_FACTION_BG_DESC or "Show faction color as background for friend buttons."
		}
	))

	-- Row 3: Gray Other Faction & Show Mobile as AFK
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_GRAY_OTHER_FACTION,
			initialValue = DB:Get("grayOtherFaction", false),
			callback = function(val) self:OnGrayOtherFactionChanged(val) end,
			tooltipTitle = L.SETTINGS_GRAY_OTHER_FACTION,
			tooltipDesc = L.SETTINGS_GRAY_OTHER_FACTION_DESC or "Make friends from the opposite faction appear grayed out"
		},
		{
			label = L.SETTINGS_SHOW_MOBILE_AS_AFK,
			initialValue = DB:Get("showMobileAsAFK", false),
			callback = function(val) self:OnShowMobileAsAFKChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_MOBILE_AS_AFK,
			tooltipDesc = L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC or "Display AFK status icon for friends on mobile (BSAp only)"
		}
	))

	-- Row 4: Treat Mobile as Offline & Hide Max Level
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_TREAT_MOBILE_OFFLINE or "Treat Mobile users as Offline",
			initialValue = DB:Get("treatMobileAsOffline", false),
			callback = function(val) self:OnTreatMobileAsOfflineChanged(val) end,
			tooltipTitle = L.SETTINGS_TREAT_MOBILE_OFFLINE or "Treat Mobile as Offline",
			tooltipDesc = L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC or "Display friends using the Mobile App in the Offline group"
		},
		{
			label = L.SETTINGS_HIDE_MAX_LEVEL,
			initialValue = DB:Get("hideMaxLevel", false),
			callback = function(val) self:OnHideMaxLevelChanged(val) end,
			tooltipTitle = L.SETTINGS_HIDE_MAX_LEVEL,
			tooltipDesc = L.SETTINGS_HIDE_MAX_LEVEL_DESC or "Don't display level number for characters at max level"
		}
	))

	-- Row 5: Enable Favorite Icon & Show Realm Name
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_ENABLE_FAVORITE_ICON,
			initialValue = DB:Get("enableFavoriteIcon", true),
			callback = function(val) 
				local DB = GetDB()
				DB:Set("enableFavoriteIcon", val) 
				BFL:ForceRefreshFriendsList()
			end,
			tooltipTitle = L.SETTINGS_ENABLE_FAVORITE_ICON,
			tooltipDesc = L.SETTINGS_ENABLE_FAVORITE_ICON_DESC or "Display a star icon on the friend button for favorites."
		},
		{
			label = L.SETTINGS_SHOW_REALM_NAME,
			initialValue = DB:Get("showRealmName", true),
			callback = function(val) self:OnShowRealmNameChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_REALM_NAME,
			tooltipDesc = L.SETTINGS_SHOW_REALM_NAME_DESC or "Display the realm name for friends on different servers"
		}
	))

	-- Row 6: Show Blizzard Option
	local blizzardOption = Components:CreateCheckbox(tab,
		L.SETTINGS_SHOW_BLIZZARD,
		DB:Get("showBlizzardOption", false),
		function(val) self:OnShowBlizzardOptionChanged(val) end
	)
	blizzardOption:SetTooltip(L.SETTINGS_SHOW_BLIZZARD, L.SETTINGS_SHOW_BLIZZARD_DESC or "Shows the original Blizzard Friends button in the social menu")
	table.insert(allFrames, blizzardOption)

	-- Row 6: ElvUI Skin (if available) - moved to separate row
	if _G.ElvUI then
		local elvUICheckbox = Components:CreateCheckbox(tab, 
			L.SETTINGS_ENABLE_ELVUI_SKIN or "Enable ElvUI Skin",
			DB:Get("enableElvUISkin", false),
			function(val)
				local boolVal = (val == true or val == 1)
				DB:Set("enableElvUISkin", boolVal)
				StaticPopupDialogs["BFL_ELVUI_RELOAD"] = {
					text = L.DIALOG_ELVUI_RELOAD_TEXT or "Changing ElvUI Skin settings requires a UI Reload.\nReload now?",
					button1 = L.DIALOG_ELVUI_RELOAD_BTN1 or "Yes",
					button2 = L.DIALOG_ELVUI_RELOAD_BTN2 or "No",
					OnAccept = function() ReloadUI() end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
				}
				StaticPopup_Show("BFL_ELVUI_RELOAD")
			end
		)
		elvUICheckbox:SetTooltip(
			L.SETTINGS_ENABLE_ELVUI_SKIN or "Enable ElvUI Skin",
			L.SETTINGS_ENABLE_ELVUI_SKIN_DESC or "Enables the ElvUI skin for BetterFriendlist. Requires ElvUI to be installed and enabled."
		)
		table.insert(allFrames, elvUICheckbox)
	end

	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- Header: Name Formatting (Phase 15)
	local nameFormatHeader = Components:CreateHeader(tab, L.SETTINGS_NAME_FORMAT_HEADER or "Name Formatting")
	table.insert(allFrames, nameFormatHeader)

	-- Name Format Description
	local nameFormatDesc = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	nameFormatDesc:SetWidth(450) -- Increased width to match grid
	nameFormatDesc:SetPoint("LEFT", 20, 0) -- Align with components
	nameFormatDesc:SetJustifyH("LEFT")
	nameFormatDesc:SetWordWrap(true)
	nameFormatDesc:SetTextColor(1, 1, 1)
	nameFormatDesc:SetText(L.SETTINGS_NAME_FORMAT_DESC or "Customize how friend names are displayed using tokens:\n|cffFFD100%name%|r - Account Name (RealID/BattleTag)\n|cffFFD100%note%|r - Note (BNet or WoW)\n|cffFFD100%nickname%|r - Custom Nickname\n|cffFFD100%battletag%|r - Short BattleTag (no #1234)")
	table.insert(allFrames, nameFormatDesc)

	-- Name Format EditBox Container
	local nameFormatContainer = CreateFrame("Frame", nil, tab)
	nameFormatContainer:SetSize(450, 30)
	nameFormatContainer:SetPoint("LEFT", 20, 0) -- Align with components
	
	local nameFormatLabel = nameFormatContainer:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	nameFormatLabel:SetText(L.SETTINGS_NAME_FORMAT_LABEL or "Format:")
	nameFormatLabel:SetPoint("LEFT", 0, 0)
	nameFormatLabel:SetWidth(100) -- LABEL_WIDTH 100
	nameFormatLabel:SetJustifyH("LEFT")
	
	local nameFormatBox = CreateFrame("EditBox", nil, nameFormatContainer, "InputBoxTemplate")
	nameFormatBox:SetSize(200, 25) -- FIELD_WIDTH 200
	nameFormatBox:SetPoint("LEFT", nameFormatContainer, "LEFT", 110, 0) -- CONTROL_OFFSET 110

	nameFormatBox:SetFontObject("BetterFriendlistFontHighlight")
	nameFormatBox:SetAutoFocus(false)
	nameFormatBox:SetText(DB:Get("nameDisplayFormat", "%name%"))
	nameFormatBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	nameFormatBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	nameFormatBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			DB:Set("nameDisplayFormat", text)
			BFL:ForceRefreshFriendsList()
		end
	end)
	
	-- Add tooltip to EditBox
	nameFormatBox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SETTINGS_NAME_FORMAT_TOOLTIP or "Name Display Format", 1, 1, 1)
		GameTooltip:AddLine(L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC or "Enter a format string using tokens.", 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine("Example: %name% (%nickname%)", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	nameFormatBox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	table.insert(allFrames, nameFormatContainer)
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Behavior
	local behaviorHeader = Components:CreateHeader(tab, L.SETTINGS_BEHAVIOR_HEADER or "Behavior")
	table.insert(allFrames, behaviorHeader)
	
	-- Row 1: Accordion Groups & Compact Mode
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_ACCORDION_GROUPS,
			initialValue = DB:Get("accordionGroups", true),
			callback = function(val) self:OnAccordionGroupsChanged(val) end,
			tooltipTitle = L.SETTINGS_ACCORDION_GROUPS,
			tooltipDesc = L.SETTINGS_ACCORDION_GROUPS_DESC or "Only allow one group to be expanded at a time, automatically collapsing others"
		},
		{
			label = L.SETTINGS_COMPACT_MODE,
			initialValue = DB:Get("compactMode", false),
			callback = function(val) self:OnCompactModeChanged(val) end,
			tooltipTitle = L.SETTINGS_COMPACT_MODE,
			tooltipDesc = L.SETTINGS_COMPACT_MODE_DESC or "Reduces button height to fit more friends on screen"
		}
	))
	
	-- Row 2: Use UI Panel System & Simple Mode & (Classic: Close on Guild Tab)
	local simpleModeConfig = {
		label = L.SETTINGS_SIMPLE_MODE or "Simple Mode",
		initialValue = DB:Get("simpleMode", false),
		callback = function(val) self:OnSimpleModeChanged(val) end,
		tooltipTitle = L.SETTINGS_SIMPLE_MODE or "Simple Mode",
		tooltipDesc = L.SETTINGS_SIMPLE_MODE_DESC or "Hides the player portrait and adds a changelog option to the contacts menu."
	}

	local closeOnGuildConfig = nil
	if BFL.IsClassic then
		closeOnGuildConfig = {
			label = L.SETTINGS_CLOSE_ON_GUILD_TAB or "Close BetterFriendlist when opening Guild",
			initialValue = DB:Get("closeOnGuildTabClick", false),
			callback = function(val) self:OnCloseOnGuildTabClickChanged(val) end,
			tooltipTitle = L.SETTINGS_CLOSE_ON_GUILD_TAB or "Close on Guild Tab",
			tooltipDesc = L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC or "Automatically close BetterFriendlist when you click the Guild tab"
		}
	end
	
	-- Row 2: Use UI Panel System & Simple Mode
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_USE_UI_PANEL_SYSTEM or "Use UI Panel System",
			initialValue = DB:Get("useUIPanelSystem", false),
			callback = function(val) self:OnUseUIPanelSystemChanged(val) end,
			tooltipTitle = L.SETTINGS_USE_UI_PANEL_SYSTEM or "Use UI Panel System",
			tooltipDesc = L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC or "Use Blizzard's UI Panel system for automatic repositioning when other windows are open (Character, Spellbook, etc.)"
		},
		simpleModeConfig
	))
	
	-- Row 3 (Classic Only): Hide Guild Tab & Close on Guild Tab
	if BFL.IsClassic then
		table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
			{
				label = L.SETTINGS_HIDE_GUILD_TAB or "Hide Guild Tab",
				initialValue = DB:Get("hideGuildTab", false),
				callback = function(val) self:OnHideGuildTabChanged(val) end,
				tooltipTitle = L.SETTINGS_HIDE_GUILD_TAB or "Hide Guild Tab",
				tooltipDesc = L.SETTINGS_HIDE_GUILD_TAB_DESC or "Hide the Guild tab from the friends list (requires UI reload)"
			},
			closeOnGuildConfig
		))
	end
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- Header: Group Management
	local groupHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_MANAGEMENT or "Group Management")
	table.insert(allFrames, groupHeader)

	-- Row 4: Show Favorites & Show In-Game Group
	table.insert(allFrames, Components:CreateDoubleCheckbox(tab,
		{
			label = L.SETTINGS_SHOW_FAVORITES,
			initialValue = DB:Get("showFavoritesGroup", true),
			callback = function(val) self:OnShowFavoritesGroupChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_FAVORITES,
			tooltipDesc = L.SETTINGS_SHOW_FAVORITES_DESC or "Toggle visibility of the Favorites group in your friends list"
		},
		{
			label = L.SETTINGS_SHOW_INGAME_GROUP or "Show 'In-Game' Group",
			initialValue = DB:Get("enableInGameGroup", false),
			callback = function(val) self:OnEnableInGameGroupChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_INGAME_GROUP or "Show 'In-Game' Group",
			tooltipDesc = L.SETTINGS_SHOW_INGAME_GROUP_DESC or "Automatically groups friends playing games into a separate group"
		}
	))

	-- NEW: In-Game Group Mode (Sub-option)
	if DB:Get("enableInGameGroup", false) then
		local modeOptions = {
			labels = {L.SETTINGS_INGAME_MODE_WOW or "WoW Only (Same Era)", L.SETTINGS_INGAME_MODE_ANY or "Any Game"},
			values = {"same_game", "any_game"}
		}
		local currentMode = DB:Get("inGameGroupMode", "same_game")
		
		local modeDropdown = Components:CreateDropdown(
			tab, 
			L.SETTINGS_INGAME_MODE_LABEL or "   Mode:", 
			modeOptions, 
			function(val) return val == currentMode end,
			function(val) self:OnInGameGroupModeChanged(val) end
		)
		modeDropdown:SetTooltip(L.SETTINGS_INGAME_MODE_TOOLTIP or "In-Game Group Mode", L.SETTINGS_INGAME_MODE_TOOLTIP_DESC or "Choose which friends to include in the In-Game group:\n\n|cffffffffWoW Only:|r Friends playing the same WoW version (Retail/Classic)\n|cffffffffAny Game:|r Friends playing any Battle.net game")
		table.insert(allFrames, modeDropdown)
	end
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Font Settings (REMOVED)
	-- local fontHeader = Components:CreateHeader(tab, L.SETTINGS_FONT_SETTINGS or "Font Settings")
	-- table.insert(allFrames, fontHeader)
	
	-- Font Size Dropdown (REMOVED: User Request 2026-01-20)
	-- Global scaling found counterproductive. 
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

function Settings:RefreshFontsTab()
	if not settingsFrame or not Components then return end

	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.FontsTab then return end

	local tab = content.FontsTab
	local DB = GetDB()
	
	-- Clear existing content (but keep the tab frame itself)
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}

	local allFrames = {}

	-- Font Library
	local LSM = LibStub("LibSharedMedia-3.0")
	local fontList = LSM:List("font")
	local fontOptions = { labels = fontList, values = fontList }
	
	local outlineOptions = {
		labels = {L.SETTINGS_FONT_OUTLINE_NONE, L.SETTINGS_FONT_OUTLINE_NORMAL, L.SETTINGS_FONT_OUTLINE_THICK, L.SETTINGS_FONT_OUTLINE_MONOCHROME},
		values = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"}
	}

	-- -------------------------------------------------------------------------
	-- Friend Name Settings
	-- -------------------------------------------------------------------------
	local nameFontHeader = Components:CreateHeader(tab, L.SETTINGS_FRIEND_NAME_SETTINGS or "Friend Name Settings")
	table.insert(allFrames, nameFontHeader)

	-- Name Font Face
	local currentNameFont = DB:Get("fontFriendName", "Friz Quadrata TT")
	local currentNameSize = DB:Get("fontSizeFriendName", 12)
	local currentNameColor = DB:Get("fontColorFriendName", {r=1, g=1, b=1, a=1})
	local nameFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:",  -- Use generic label as per request to move code
		fontOptions, 
		function(val) return val == currentNameFont end,
		function(val) 
			DB:Set("fontFriendName", val)
			-- Defer update to next frame to ensure resource availability
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
				self:RefreshFontsTab(tab) -- Refresh to update dropdown label
			end)
		end
	)
	-- Shift 10px right to prevent clipping (matching other dropdowns)
	if nameFontDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = nameFontDropdown.DropDown:GetPoint(1)
		if point then
			nameFontDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, nameFontDropdown)

	-- Name Font Size
	local nameSizeSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_FONT_SIZE_NUM or "Font Size:",
		8, 24, -- Min/Max
		currentNameSize, -- Current Value
		function(val) return tostring(val) end, -- Label formatter
		function(val)
			DB:Set("fontSizeFriendName", val)
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, nameSizeSlider)

	-- Name Font Color
	local nameColorPicker = Components:CreateColorPicker(
		tab,
		L.SETTINGS_FONT_COLOR,
		currentNameColor,
		function(r, g, b, a)
			DB:Set("fontColorFriendName", {r=r, g=g, b=b, a=a})
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, nameColorPicker)

	-- Name Font Outline
	local currentNameOutline = DB:Get("fontOutlineFriendName", "NONE")
	local nameOutlineDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_FONT_OUTLINE, 
		outlineOptions, 
		function(val) return val == (DB:Get("fontOutlineFriendName", "NONE")) end,
		function(val) 
			DB:Set("fontOutlineFriendName", val)
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	-- Shift 10px right to prevent clipping
	if nameOutlineDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = nameOutlineDropdown.DropDown:GetPoint(1)
		if point then
			nameOutlineDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, nameOutlineDropdown)

	-- Name Font Shadow (Temporarily Disabled)
	local currentNameShadow = DB:Get("fontShadowFriendName", false)
	local nameShadowCheckbox = Components:CreateCheckbox(
		tab,
		L.SETTINGS_FONT_SHADOW,
		currentNameShadow,
		function(checked)
			-- Disabled: No op
		end
	)
	
	-- Force disable UI
	if nameShadowCheckbox.checkBox then
		nameShadowCheckbox.checkBox:Disable()
		nameShadowCheckbox.checkBox:SetEnabled(false)
	end
	
	-- Set tooltip
	nameShadowCheckbox:SetTooltip(L.SETTINGS_FONT_SHADOW, "|cffff0000Feature temporarily disabled (coming later)|r")
	table.insert(allFrames, nameShadowCheckbox)

	-- -------------------------------------------------------------------------
	-- Friend Info Settings
	-- -------------------------------------------------------------------------
	table.insert(allFrames, Components:CreateSpacer(tab))
	local infoFontHeader = Components:CreateHeader(tab, L.SETTINGS_FRIEND_INFO_SETTINGS or "Friend Info Settings")
	table.insert(allFrames, infoFontHeader)

	-- Info Font Face
	local currentInfoFont = DB:Get("fontFriendInfo", "Friz Quadrata TT")
	local currentInfoSize = DB:Get("fontSizeFriendInfo", 12)
	local currentInfoColor = DB:Get("fontColorFriendInfo", {r=0.82, g=0.82, b=0.82, a=1})
	local infoFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:",  -- Changed from "Font Face:" (User Request)
		fontOptions, 
		function(val) return val == currentInfoFont end,
		function(val) 
			DB:Set("fontFriendInfo", val)
			-- Defer update to next frame
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
				self:RefreshFontsTab(tab) -- Refresh to update dropdown label
			end)
		end
	)
	-- Shift 10px right to prevent clipping
	if infoFontDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = infoFontDropdown.DropDown:GetPoint(1)
		if point then
			infoFontDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, infoFontDropdown)

	-- Info Font Size
	local infoSizeSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_FONT_SIZE_NUM or "Font Size:",
		8, 24, -- Min/Max
		currentInfoSize, -- Current Value
		function(val) return tostring(val) end, -- Label formatter
		function(val)
			DB:Set("fontSizeFriendInfo", val)
			-- Defer update to next frame
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, infoSizeSlider)

	-- Info Font Color
	local infoColorPicker = Components:CreateColorPicker(
		tab,
		L.SETTINGS_FONT_COLOR,
		currentInfoColor,
		function(r, g, b, a)
			DB:Set("fontColorFriendInfo", {r=r, g=g, b=b, a=a})
			-- Defer update to next frame
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, infoColorPicker)

	-- Info Font Outline
	local currentInfoOutline = DB:Get("fontOutlineFriendInfo", "NONE")
	local infoOutlineDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_FONT_OUTLINE, 
		outlineOptions, 
		function(val) return val == (DB:Get("fontOutlineFriendInfo", "NONE")) end,
		function(val) 
			DB:Set("fontOutlineFriendInfo", val)
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	-- Shift 10px right to prevent clipping (matching other dropdowns)
	if infoOutlineDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = infoOutlineDropdown.DropDown:GetPoint(1)
		if point then
			infoOutlineDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, infoOutlineDropdown)

	-- Info Font Shadow (Temporarily Disabled)
	local currentInfoShadow = DB:Get("fontShadowFriendInfo", false)
	local infoShadowCheckbox = Components:CreateCheckbox(
		tab,
		L.SETTINGS_FONT_SHADOW,
		currentInfoShadow,
		function(checked)
			-- Disabled: No op
		end
	)
	
	-- Force disable UI
	if infoShadowCheckbox.checkBox then
		infoShadowCheckbox.checkBox:Disable()
		infoShadowCheckbox.checkBox:SetEnabled(false)
	end
	
	-- Set tooltip using standard component method
	infoShadowCheckbox:SetTooltip(L.SETTINGS_FONT_SHADOW, "|cffff0000Feature temporarily disabled (coming later)|r")
	table.insert(allFrames, infoShadowCheckbox)
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- Refresh Groups Tab with new component library
function Settings:RefreshGroupsTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.GroupsTab then return end
	
	local tab = content.GroupsTab
	local DB = GetDB()
	if not DB then return end
	
	-- Clear existing content (but keep the tab frame itself)
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}

	-- Common Font Options
	local LSM = LibStub("LibSharedMedia-3.0")
	local fontList = LSM:List("font")
	local fontOptions = { labels = fontList, values = fontList }
	
	local outlineOptions = {
		labels = {L.SETTINGS_FONT_OUTLINE_NONE, L.SETTINGS_FONT_OUTLINE_NORMAL, L.SETTINGS_FONT_OUTLINE_THICK, L.SETTINGS_FONT_OUTLINE_MONOCHROME},
		values = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"}
	}

	-- ===========================================
	-- MOVED SETTINGS (From General)
	-- ===========================================
	local headerSettingsHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_HEADER_SETTINGS or "Group Header Settings")
	table.insert(allFrames, headerSettingsHeader)

	-- Row 1: Group Header Count Format & Group Arrow
	local headerCountFormatOptions = {
		labels = {L.SETTINGS_HEADER_COUNT_VISIBLE, L.SETTINGS_HEADER_COUNT_ONLINE, L.SETTINGS_HEADER_COUNT_BOTH},
		values = {"visible", "online", "both"}
	}
	
	local headerCountDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_HEADER_COUNT_FORMAT, 
		headerCountFormatOptions, 
		function(val) return val == DB:Get("headerCountFormat", "visible") end,
		function(val) 
			DB:Set("headerCountFormat", val)
			BFL:ForceRefreshFriendsList()
			self:RefreshGroupsTab() -- Self refresh to update visible state if needed
		end
	)
	-- Shift dropdown to prevent clipping
	if headerCountDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = headerCountDropdown.DropDown:GetPoint(1)
		if point then
			headerCountDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, headerCountDropdown)
	
	-- Group Header Alignment
	local groupHeaderAlignOptions = {
		labels = {L.SETTINGS_ALIGN_LEFT, L.SETTINGS_ALIGN_CENTER, L.SETTINGS_ALIGN_RIGHT},
		values = {"LEFT", "CENTER", "RIGHT"}
	}
	local groupHeaderAlignDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_GROUP_HEADER_ALIGN, 
		groupHeaderAlignOptions, 
		function(val) return val == DB:Get("groupHeaderAlign", "LEFT") end,
		function(val) 
			DB:Set("groupHeaderAlign", val)
			BFL:ForceRefreshFriendsList()
			self:RefreshGroupsTab()
		end
	)
	-- Shift dropdown to prevent clipping
	if groupHeaderAlignDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = groupHeaderAlignDropdown.DropDown:GetPoint(1)
		if point then
			groupHeaderAlignDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, groupHeaderAlignDropdown)
	
	-- Group Arrow Alignment
	local groupArrowAlignOptions = {
		labels = {L.SETTINGS_ALIGN_LEFT, L.SETTINGS_ALIGN_CENTER, L.SETTINGS_ALIGN_RIGHT},
		values = {"LEFT", "CENTER", "RIGHT"}
	}
	local groupArrowAlignDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_GROUP_ARROW_ALIGN, 
		groupArrowAlignOptions, 
		function(val) return val == DB:Get("groupArrowAlign", "LEFT") end,
		function(val) 
			DB:Set("groupArrowAlign", val)
			BFL:ForceRefreshFriendsList()
			self:RefreshGroupsTab()
		end
	)
	-- Shift dropdown to prevent clipping
	if groupArrowAlignDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = groupArrowAlignDropdown.DropDown:GetPoint(1)
		if point then
			groupArrowAlignDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, groupArrowAlignDropdown)
	
	-- Show Arrow Checkbox
	local showArrowCheckbox = Components:CreateCheckbox(
		tab,
		L.SETTINGS_SHOW_GROUP_ARROW,
		DB:Get("showGroupArrow", true),
		function(val) 
			DB:Set("showGroupArrow", val)
			BFL:ForceRefreshFriendsList()
		end
	)
	table.insert(allFrames, showArrowCheckbox)
	 
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- ===========================================
	-- NEW FONT SETTINGS
	-- ===========================================
	local fontHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_FONT_HEADER or "Group Header Font")
	table.insert(allFrames, fontHeader)
	
	-- Group Font Dropdown
	local currentGroupFont = DB:Get("fontGroupHeader", "Friz Quadrata TT")
	local groupFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:", 
		fontOptions, 
		function(val) return val == currentGroupFont end,
		function(val) 
			DB:Set("fontGroupHeader", val)
			-- Defer update
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
				self:RefreshGroupsTab()
			end)
		end
	)
	if groupFontDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = groupFontDropdown.DropDown:GetPoint(1)
		if point then
			groupFontDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, groupFontDropdown)
	
	-- Group Font Size
	local currentGroupSize = DB:Get("fontSizeGroupHeader", 12)
	local GroupSizeSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_FONT_SIZE_NUM or "Font Size:",
		8, 24, -- Min/Max
		currentGroupSize, -- Current Value
		function(val) return tostring(val) end, -- Label formatter
		function(val)
			DB:Set("fontSizeGroupHeader", val)
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, GroupSizeSlider)
	
	-- Group Font Outline
	local currentGroupOutline = DB:Get("fontOutlineGroupHeader", "NONE")
	local GroupOutlineDropdown = Components:CreateDropdown(
		tab, 
		L.SETTINGS_FONT_OUTLINE, 
		outlineOptions, 
		function(val) return val == currentGroupOutline end,
		function(val) 
			DB:Set("fontOutlineGroupHeader", val)
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	if GroupOutlineDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = GroupOutlineDropdown.DropDown:GetPoint(1)
		if point then
			GroupOutlineDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, GroupOutlineDropdown)
	
	-- Group Font Shadow (Temporarily Disabled)
	local currentGroupShadow = DB:Get("fontShadowGroupHeader", false)
	local groupShadowCheckbox = Components:CreateCheckbox(
		tab,
		L.SETTINGS_FONT_SHADOW or "Font Shadow",
		currentGroupShadow,
		function(checked)
			-- Disabled: No op
		end
	)
	
	-- Force disable UI
	if groupShadowCheckbox.checkBox then
		groupShadowCheckbox.checkBox:Disable()
		groupShadowCheckbox.checkBox:SetEnabled(false)
	end
	
	-- Set tooltip
	groupShadowCheckbox:SetTooltip(L.SETTINGS_FONT_SHADOW, "|cffff0000Feature temporarily disabled (coming later)|r")
	table.insert(allFrames, groupShadowCheckbox)
	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Group Order
	local orderHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_ORDER or "Group Order")
	table.insert(allFrames, orderHeader)
	
	-- Get ordered groups
	local Groups = BFL:GetModule("Groups")
	if not Groups then return end
	
	local allGroups = Groups:GetAll()
	local groupOrder = DB:Get("groupOrder") or {}
	local orderedGroups = {}
	
	-- Build ordered list
	if #groupOrder > 0 then
		for i, groupId in ipairs(groupOrder) do
			local group = allGroups[groupId]
			if group then
				table.insert(orderedGroups, {id = groupId, name = group.name, order = i, builtin = group.builtin})
			end
		end
		-- Add any groups not in order
		for groupId, group in pairs(allGroups) do
			local found = false
			for _, ordered in ipairs(orderedGroups) do
				if ordered.id == groupId then
					found = true
					break
				end
			end
			if not found then
				table.insert(orderedGroups, {id = groupId, name = group.name, order = #orderedGroups + 1, builtin = group.builtin})
			end
		end
	else
		-- Default order: favorites, custom groups (sorted), nogroup
		table.insert(orderedGroups, {id = "favorites", name = "Favorites", order = 1, builtin = true})
		
		local customGroups = {}
		for groupId, group in pairs(allGroups) do
			if groupId ~= "favorites" and groupId ~= "nogroup" then
				table.insert(customGroups, {id = groupId, name = group.name, builtin = false})
			end
		end
		table.sort(customGroups, function(a, b) return a.name < b.name end)
		
		for _, group in ipairs(customGroups) do
			table.insert(orderedGroups, {id = group.id, name = group.name, order = #orderedGroups + 1, builtin = false})
		end
		
		if allGroups["nogroup"] then
			table.insert(orderedGroups, {id = "nogroup", name = "No Group", order = #orderedGroups + 1, builtin = true})
		end
	end
	
	-- Create list items for each group
	for i, groupData in ipairs(orderedGroups) do
		local canMoveUp = i > 1
		local canMoveDown = i < #orderedGroups
		local isBuiltin = groupData.builtin
		
		local listItem = Components:CreateListItem(
			tab,
			groupData.name,
			i,
			-- Move Up callback
			function()
				if i > 1 then
					-- Swap with previous
					local temp = orderedGroups[i-1]
					orderedGroups[i-1] = orderedGroups[i]
					orderedGroups[i] = temp
					
					-- Save new order
					local newOrder = {}
					for _, g in ipairs(orderedGroups) do
						table.insert(newOrder, g.id)
					end
					DB:Set("groupOrder", newOrder)
					
					-- Refresh display
					Groups:Initialize()
					self:RefreshGroupsTab()
					
					-- Force full display refresh - group order affects display list structure
					BFL:ForceRefreshFriendsList()
				end
			end,
			-- Move Down callback
			function()
				if i < #orderedGroups then
					-- Swap with next
					local temp = orderedGroups[i+1]
					orderedGroups[i+1] = orderedGroups[i]
					orderedGroups[i] = temp
					
					-- Save new order
					local newOrder = {}
					for _, g in ipairs(orderedGroups) do
						table.insert(newOrder, g.id)
					end
					DB:Set("groupOrder", newOrder)
					
					-- Refresh display
					Groups:Initialize()
					self:RefreshGroupsTab()
					
					-- Force full display refresh - group order affects display list structure
					BFL:ForceRefreshFriendsList()
				end
			end,
			-- Rename callback (allow for all groups)
			function()
				self:RenameGroup(groupData.id, groupData.name)
			end,
			-- Color callback (allow for all groups)
			function(colorSwatch)
				self:ShowColorPicker(groupData.id, groupData.name, colorSwatch)
			end,
			-- Delete callback (only for non-builtin groups)
			not isBuiltin and function()
				self:DeleteGroup(groupData.id, groupData.name)
			end or nil,
			-- Count Color Callback (New)
			function(colorSwatch, isReset)
				self:ShowGroupCountColorPicker(groupData.id, groupData.name, colorSwatch, isReset)
			end,
			-- Arrow Color Callback (New)
			function(colorSwatch, isReset)
				self:ShowGroupArrowColorPicker(groupData.id, groupData.name, colorSwatch, isReset)
			end,
			-- Initial Colors (New)
			{
				count = Groups:Get(groupData.id) and (Groups:Get(groupData.id).countColor or Groups:Get(groupData.id).color),
				arrow = Groups:Get(groupData.id) and (Groups:Get(groupData.id).arrowColor or Groups:Get(groupData.id).color),
				countSet = Groups:Get(groupData.id) and Groups:Get(groupData.id).countColor,
				arrowSet = Groups:Get(groupData.id) and Groups:Get(groupData.id).arrowColor,
				fallback = Groups:Get(groupData.id) and Groups:Get(groupData.id).color or {r=1, g=1, b=1}
			}
		)
		
		-- Set initial color for all groups
		if listItem.colorSwatch then
			local group = Groups:Get(groupData.id)
			if group and group.color then
				listItem.colorSwatch:SetColorTexture(group.color.r, group.color.g, group.color.b)
			else
				listItem.colorSwatch:SetColorTexture(1, 0.82, 0)
			end
		end
		
		-- Set arrow button states
		listItem:SetArrowState(canMoveUp, canMoveDown)
		
		-- Set tooltips (localized)
		if listItem.renameBtn then
			listItem.renameBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_RENAME_GROUP, 1, 1, 1)
				GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC, nil, nil, nil, true)
				GameTooltip:Show()
			end)
		end
		
		if listItem.colorBtn then
			listItem.colorBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_GROUP_COLOR, 1, 1, 1)
				GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, nil, nil, nil, true)
				GameTooltip:Show()
			end)
		end
		
		if listItem.deleteBtn then
			listItem.deleteBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_DELETE_GROUP, 1, 1, 1)
				GameTooltip:AddLine(L.TOOLTIP_DELETE_DESC, nil, nil, nil, true)
				GameTooltip:Show()
			end)
		end
		
		table.insert(allFrames, listItem)
	end
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- Refresh Advanced Tab
-- Refresh Advanced Tab
function Settings:RefreshAdvancedTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.AdvancedTab then return end
	
	local tab = content.AdvancedTab
	
	-- Clear existing content (but keep the tab frame itself)
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	
	-- Title
	local title = Components:CreateHeader(tab, L.SETTINGS_TAB_ADVANCED or "Advanced Settings")
	table.insert(allFrames, title)
	
	-- Description
	table.insert(allFrames, Components:CreateLabel(tab, L.SETTINGS_ADVANCED_DESC or "Advanced options and tools"))

	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- ===========================================
	-- FriendGroups Migration Section
	-- ===========================================
	table.insert(allFrames, Components:CreateHeader(tab, L.SETTINGS_MIGRATION_HEADER or "FriendGroups Migration"))
	
	-- Migration description
	table.insert(allFrames, Components:CreateLabel(tab, L.SETTINGS_MIGRATION_DESC or "Migrate groups and friend assignments from FriendGroups addon. This will parse group information from BattleNet notes and create corresponding groups in BetterFriendlist.", true))
	
	-- Migration button
	local migrateButton = Components:CreateButton(
		tab,
		L.SETTINGS_MIGRATE_BTN or "Migrate from FriendGroups",
		function()
			self:ShowMigrationDialog()
		end,
		L.SETTINGS_MIGRATE_TOOLTIP or "Import groups from the FriendGroups addon"
	)
	migrateButton:SetSize(200, 24)
	-- Center the migrate button
	migrateButton:ClearAllPoints()
	migrateButton:SetPoint("CENTER", tab, "CENTER", 0, 0) -- This point will be overridden by AnchorChain? No, AnchorChain sets TOP. We need a container if we want horizontal centering?
	-- Wait, Components:CreateButton returns a button. AnchorChain sets its TOP point. It usually lacks LEFT/RIGHT.
	-- If we want it centered, we need to wrap it or set a point that conflicts less?
	-- AnchorChain sets "TOP". If we set "CENTER" x-offset it might work if we set relative to parent center?
	-- But AnchorChain uses "TOP" relative to previous element.
	-- Ideally we put it in a container like btnRow.
	
	local migrateBtnRow = CreateFrame("Frame", nil, tab)
	migrateBtnRow:SetHeight(30)
	migrateBtnRow:SetPoint("LEFT", 20, 0)
	migrateBtnRow:SetPoint("RIGHT", -20, 0)
	
	migrateButton:SetParent(migrateBtnRow)
	migrateButton:ClearAllPoints()
	migrateButton:SetPoint("CENTER", migrateBtnRow, "CENTER", 0, 0)
	
	table.insert(allFrames, migrateBtnRow)
	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- ===========================================
	-- Export / Import Section
	-- ===========================================
	table.insert(allFrames, Components:CreateHeader(tab, L.SETTINGS_EXPORT_HEADER or "Export / Import Settings"))
	
	-- Export/Import description
	table.insert(allFrames, Components:CreateLabel(tab, L.SETTINGS_EXPORT_DESC or "Export your groups and friend assignments to share between characters or accounts. Perfect for players with multiple accounts who share Battle.net friends.", true))
	
	-- Export Warning
	local exportWarning = Components:CreateLabel(tab, L.SETTINGS_EXPORT_WARNING or "|cffff0000Warning: Importing will replace ALL your groups and assignments!|r", true)
	table.insert(allFrames, exportWarning)
	
	-- Export/Import Buttons Row
	local btnRow = CreateFrame("Frame", nil, tab)
	btnRow:SetHeight(30)
	btnRow:SetPoint("LEFT", 20, 0)
	btnRow:SetPoint("RIGHT", -20, 0)
	
	-- Export button
	local exportButton = Components:CreateButton(
		btnRow,
		L.BUTTON_EXPORT,
		function()
			self:ShowExportDialog()
		end,
		L.SETTINGS_EXPORT_TOOLTIP or "Export your groups and friend assignments"
	)
	exportButton:SetSize(140, 24)
	exportButton:SetPoint("RIGHT", btnRow, "CENTER", -5, 0)
	
	-- Import button
	local importButton = Components:CreateButton(
		btnRow,
		L.SETTINGS_IMPORT_BTN,
		function()
			self:ShowImportDialog()
		end,
		L.SETTINGS_IMPORT_TOOLTIP or "Import groups and friend assignments"
	)
	importButton:SetSize(140, 24)
	importButton:SetPoint("LEFT", btnRow, "CENTER", 5, 0)
	
	table.insert(allFrames, btnRow)
	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- ===========================================
	-- Beta Features Section
	-- ===========================================
	table.insert(allFrames, Components:CreateHeader(tab, "|cffff8800" .. L.SETTINGS_BETA_FEATURES_TITLE .. "|r"))
	
	-- Beta features description
	table.insert(allFrames, Components:CreateLabel(tab, L.SETTINGS_BETA_FEATURES_DESC, true))
	
	-- Warning icon + text container
	local warningFrame = CreateFrame("Frame", nil, tab)
	warningFrame:SetHeight(45)
	warningFrame:SetPoint("LEFT", 20, 0)
	warningFrame:SetPoint("RIGHT", -20, 0)
	
	local warningIcon = warningFrame:CreateTexture(nil, "ARTWORK")
	warningIcon:SetSize(16, 16)
	warningIcon:SetPoint("TOPLEFT", 0, -2)
	warningIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\alert-triangle")
	warningIcon:SetVertexColor(1, 0.65, 0)
	
	local warningText = warningFrame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormalSmall")
	warningText:SetPoint("LEFT", warningIcon, "RIGHT", 6, 0)
	warningText:SetPoint("RIGHT", warningFrame, "RIGHT", 0, 0)
	warningText:SetJustifyH("LEFT")
	warningText:SetWordWrap(true)
	warningText:SetText(L.SETTINGS_BETA_FEATURES_WARNING)
	warningText:SetTextColor(1, 0.53, 0) -- Orange
	
	table.insert(allFrames, warningFrame)
	
	-- Enable Beta Features Toggle
	local betaToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_BETA_FEATURES_ENABLE,
		BetterFriendlistDB.enableBetaFeatures or false,
		function(checked)
			BetterFriendlistDB.enableBetaFeatures = checked
			
			-- If disabling Beta and currently on ANY Beta tab, switch to General
			if not checked then
				local betaTabIds = GetBetaTabIds()
				for _, betaTabId in ipairs(betaTabIds) do
					if currentTab == betaTabId then
						self:ShowTab(1)
						break
					end
				end
			end
			
			-- Refresh Settings UI (show/hide Beta tabs)
			if BetterFriendlistSettings_RefreshTabs then
				BetterFriendlistSettings_RefreshTabs()
			end
			
			-- User feedback
			if checked then
				BFL:DebugPrint(L.SETTINGS_BETA_FEATURES_ENABLED)
				BFL:DebugPrint(L.SETTINGS_BETA_TABS_VISIBLE)
			else
				BFL:DebugPrint(L.SETTINGS_BETA_FEATURES_DISABLED)
				BFL:DebugPrint(L.SETTINGS_BETA_TABS_HIDDEN)
			end
			
			-- Data Broker is stable now, no reload required when toggling Beta features
		end
	)
	betaToggle:SetTooltip(L.SETTINGS_BETA_FEATURES_TITLE, L.SETTINGS_BETA_FEATURES_TOOLTIP)
	table.insert(allFrames, betaToggle)

	-- Beta feature list (informational)
	local listContainer = CreateFrame("Frame", nil, tab)
	listContainer:SetPoint("LEFT", 20, 0)
	listContainer:SetPoint("RIGHT", -20, 0)
	
	local featureListTitle = listContainer:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	featureListTitle:SetPoint("TOPLEFT", 0, 0)
	featureListTitle:SetText(L.SETTINGS_BETA_FEATURES_LIST)
	featureListTitle:SetTextColor(1, 0.53, 0) -- Orange
	
	-- Dynamic list from TAB_DEFINITIONS
	local listY = -20
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		if tabDef.beta then
			local icon = listContainer:CreateTexture(nil, "ARTWORK")
			icon:SetSize(14, 14)
			icon:SetPoint("TOPLEFT", 5, listY)
			icon:SetTexture(tabDef.icon)
			icon:SetVertexColor(1, 0.53, 0) -- Orange
			
			local text = listContainer:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
			text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
			text:SetPoint("TOP", icon, "TOP", 0, -1)
			text:SetText(tabDef.name)
			
			listY = listY - 18
		end
	end
	listContainer:SetHeight(math.abs(listY) + 10)
	table.insert(allFrames, listContainer)
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -15)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- Refresh Statistics Tab
function Settings:RefreshStatisticsTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.StatisticsTab then return end
	
	local tab = content.StatisticsTab
	
	-- Clear existing content (but keep the tab frame itself)
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	local yOffset = -15
	
	-- Title
	local title = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, yOffset)
	title:SetText(L.STATS_HEADER or "Friend Network Statistics")
	table.insert(allFrames, title)
	yOffset = yOffset - 25
	
	-- Description
	local desc = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	desc:SetPoint("TOPLEFT", 10, yOffset)
	desc:SetText(L.STATS_DESC or "Overview of your friend network and activity")
	table.insert(allFrames, desc)
	yOffset = yOffset - 30
	
	-- ===========================================
	-- Overview Section
	-- ===========================================
	local overviewHeader = Components:CreateHeader(tab, L.STATS_OVERVIEW_HEADER or "Overview")
	overviewHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, overviewHeader)
	yOffset = yOffset - 25
	
	-- Total Friends
	tab.TotalFriends = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	tab.TotalFriends:SetPoint("TOPLEFT", 20, yOffset)
	tab.TotalFriends:SetText(string.format(L.STATS_TOTAL_FRIENDS or "Total Friends: %s", "--"))
	table.insert(allFrames, tab.TotalFriends)
	yOffset = yOffset - 20
	
	-- Online/Offline
	tab.OnlineFriends = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	tab.OnlineFriends:SetPoint("TOPLEFT", 20, yOffset)
	tab.OnlineFriends:SetText(string.format(L.STATS_ONLINE_OFFLINE or "Online: %s  |  Offline: %s", "--", "--"))
	table.insert(allFrames, tab.OnlineFriends)
	yOffset = yOffset - 20
	
	-- Friend Types
	tab.FriendTypes = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	tab.FriendTypes:SetPoint("TOPLEFT", 20, yOffset)
	tab.FriendTypes:SetText(string.format(L.STATS_BNET_WOW or "Battle.net: %s  |  WoW: %s", "--", "--"))
	table.insert(allFrames, tab.FriendTypes)
	yOffset = yOffset - 30
	
	-- Store left column start position
	local leftColumnStart = yOffset
	
	-- ===========================================
	-- LEFT COLUMN
	-- ===========================================
	
	-- Friendship Health Section
	local healthHeader = Components:CreateHeader(tab, L.STATS_HEALTH_HEADER or "Friendship Health")
	healthHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, healthHeader)
	yOffset = yOffset - 25
	
	tab.FriendshipHealth = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.FriendshipHealth:SetPoint("TOPLEFT", 20, yOffset)
	tab.FriendshipHealth:SetWidth(210)
	tab.FriendshipHealth:SetJustifyH("LEFT")
	tab.FriendshipHealth:SetText(L.STATS_NO_DATA or "No health data available")
	table.insert(allFrames, tab.FriendshipHealth)
	yOffset = yOffset - 90
	
	-- Top 5 Classes Section
	local classHeader = Components:CreateHeader(tab, L.STATS_CLASSES_HEADER or "Top 5 Classes")
	classHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, classHeader)
	yOffset = yOffset - 25
	
	tab.ClassList = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.ClassList:SetPoint("TOPLEFT", 20, yOffset)
	tab.ClassList:SetWidth(210)
	tab.ClassList:SetJustifyH("LEFT")
	tab.ClassList:SetText(L.STATS_NO_DATA or "No class data available")
	table.insert(allFrames, tab.ClassList)
	yOffset = yOffset - 90
	
	-- Realm Clusters Section
	local realmHeader = Components:CreateHeader(tab, L.STATS_REALMS_HEADER or "Realm Clusters")
	realmHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, realmHeader)
	yOffset = yOffset - 25
	
	tab.RealmList = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.RealmList:SetPoint("TOPLEFT", 20, yOffset)
	tab.RealmList:SetWidth(210)
	tab.RealmList:SetJustifyH("LEFT")
	tab.RealmList:SetText(L.STATS_NO_DATA or "No realm data available")
	table.insert(allFrames, tab.RealmList)
	yOffset = yOffset - 110
	
	-- Organization Section
	local notesHeader = Components:CreateHeader(tab, L.STATS_ORGANIZATION_HEADER or "Organization")
	notesHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, notesHeader)
	yOffset = yOffset - 25
	
	tab.NotesAndFavorites = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.NotesAndFavorites:SetPoint("TOPLEFT", 20, yOffset)
	tab.NotesAndFavorites:SetWidth(210)
	tab.NotesAndFavorites:SetJustifyH("LEFT")
	tab.NotesAndFavorites:SetText(L.STATS_NO_DATA or "No data available")
	table.insert(allFrames, tab.NotesAndFavorites)
	yOffset = yOffset - 60
	
	-- ===========================================
	-- RIGHT COLUMN
	-- ===========================================
	yOffset = leftColumnStart
	
	-- Level Distribution Section
	local levelHeader = Components:CreateHeader(tab, L.STATS_LEVELS_HEADER or "Level Distribution")
	levelHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, levelHeader)
	yOffset = yOffset - 25
	
	tab.LevelDistribution = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.LevelDistribution:SetPoint("TOPLEFT", 250, yOffset)
	tab.LevelDistribution:SetWidth(190)
	tab.LevelDistribution:SetJustifyH("LEFT")
	tab.LevelDistribution:SetText(L.STATS_NO_DATA or "No level data available")
	table.insert(allFrames, tab.LevelDistribution)
	yOffset = yOffset - 90
	
	-- Game Distribution Section
	local gameHeader = Components:CreateHeader(tab, L.STATS_GAMES_HEADER or "Game Distribution")
	gameHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, gameHeader)
	yOffset = yOffset - 25
	
	tab.GameDistribution = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.GameDistribution:SetPoint("TOPLEFT", 250, yOffset)
	tab.GameDistribution:SetWidth(190)
	tab.GameDistribution:SetJustifyH("LEFT")
	tab.GameDistribution:SetText(L.STATS_NO_DATA or "No game data available")
	table.insert(allFrames, tab.GameDistribution)
	yOffset = yOffset - 90
	
	-- Mobile vs Desktop Section
	local mobileHeader = Components:CreateHeader(tab, L.STATS_MOBILE_HEADER or "Mobile vs. Desktop")
	mobileHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, mobileHeader)
	yOffset = yOffset - 25
	
	tab.MobileVsDesktop = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.MobileVsDesktop:SetPoint("TOPLEFT", 250, yOffset)
	tab.MobileVsDesktop:SetWidth(190)
	tab.MobileVsDesktop:SetJustifyH("LEFT")
	tab.MobileVsDesktop:SetText(L.STATS_NO_DATA or "No mobile data available")
	table.insert(allFrames, tab.MobileVsDesktop)
	yOffset = yOffset - 60
	
	-- Faction Distribution Section
	local factionHeader = Components:CreateHeader(tab, L.STATS_FACTIONS_HEADER or "Faction Distribution")
	factionHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, factionHeader)
	yOffset = yOffset - 25
	
	tab.FactionList = tab:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	tab.FactionList:SetPoint("TOPLEFT", 250, yOffset)
	tab.FactionList:SetWidth(190)
	tab.FactionList:SetJustifyH("LEFT")
	tab.FactionList:SetText(L.STATS_NO_DATA or "No faction data available")
	table.insert(allFrames, tab.FactionList)
	
	-- ===========================================
	-- Refresh Button (below Organization section)
	-- ===========================================
	local refreshButton = Components:CreateButton(
		tab,
		L.STATS_REFRESH_BTN or "Refresh Statistics",
		function()
			self:RefreshStatistics()
		end,
		L.STATS_REFRESH_TOOLTIP or "Update statistics with current data"
	)
	refreshButton:SetPoint("TOPLEFT", 10, yOffset)
	refreshButton:SetSize(150, 24)
	table.insert(allFrames, refreshButton)
	
	-- Store components for cleanup
	tab.components = allFrames
	
	-- Trigger initial data refresh
	self:RefreshStatistics()
end

-- ========================================
-- Notifications Tab (BETA)
-- ========================================

function Settings:RefreshNotificationsTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.NotificationsTab then return end
	
	local tab = content.NotificationsTab
	
	-- Clear existing content
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	
	-- BETA Header
	if BetterFriendlistDB.enableBetaFeatures then
		local betaHeader = Components:CreateHeader(tab, L.SETTINGS_TAB_NOTIFICATIONS .. " (BETA)")
		betaHeader.text:SetTextColor(1, 0.5, 0) -- Orange
		table.insert(allFrames, betaHeader)
	end
	
	-- Description
	local desc = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_DESC or "Customize how and when you want to be notified about friend activity.", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, desc)

	-- ===========================================
	-- VISUAL & SOUND
	-- ===========================================
	local displayHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_DISPLAY_HEADER or "Display & Sound")
	table.insert(allFrames, displayHeader)
	
	-- Display Mode Dropdown
	local dropdownMode = Components:CreateDropdown(
		tab,
		L.SETTINGS_NOTIFY_DISPLAY_MODE or "Notification Style:",
		{
			labels = {
				L.SETTINGS_NOTIFY_MODE_TOAST or "Toast (Blizzard Style)", 
				L.SETTINGS_NOTIFY_MODE_CHAT or "Chat Message", 
				L.SETTINGS_NOTIFY_MODE_BOTH or "Both", 
				L.SETTINGS_NOTIFY_MODE_NONE or "Disabled"
			},
			values = {"alert", "chat", "both", "disabled"}
		},
		function(value) return value == BetterFriendlistDB.notificationDisplayMode end,
		function(value)
			BetterFriendlistDB.notificationDisplayMode = value
			BFL:DebugPrint((L.SETTINGS_NOTIFY_MODE_CHANGED or "Notification mode changed to:") .. " " .. value)
		end
	)
	dropdownMode:SetTooltip(L.SETTINGS_NOTIFY_DISPLAY_MODE or "Notification Style", "Choose how notifications appear on your screen.")
	table.insert(allFrames, dropdownMode)
	
	local modeDesc = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_MODE_DESC or "Toast: Popup at bottom-middle of screen.\nChat: Message in chat window.\nBoth: Show both.\nDisabled: No notifications.", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, modeDesc)
	
	-- Test Button
	local testBtn = Components:CreateButton(tab, L.SETTINGS_NOTIFY_TEST or "Test Notification", function()
		if BFL.NotificationSystem and BFL.NotificationSystem.ShowTestNotification then
			BFL.NotificationSystem:ShowTestNotification()
		else
			BFL:DebugPrint("Notification system not ready")
		end
	end)
	table.insert(allFrames, testBtn)
	
	-- Sound Toggle
	local soundToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_SOUND or "Play sound on notification",
		BetterFriendlistDB.notificationSoundEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationSoundEnabled = checked
			if checked then
				PlaySound(BFL.IsClassic and 8959 or 12867) -- SOUNDKIT.RAID_WARNING
				BFL:DebugPrint("Sound |cff00ff00ENABLED|r")
			else
				BFL:DebugPrint("Sound |cffff0000DISABLED|r")
			end
		end
	)
	soundToggle:SetTooltip("Notification Sound", "Play a sound effect when a friend comes online or goes offline.")
	table.insert(allFrames, soundToggle)
	
	-- ===========================================
	-- QUIET HOURS & FILTERS
	-- ===========================================
	local quietHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_QUIET_HEADER or "Quiet Hours & Filters")
	table.insert(allFrames, quietHeader)
	
	-- Manual DND Toggle
	local dndToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_DND or "Do Not Disturb (Silence all notifications)",
		BetterFriendlistDB.notificationQuietManual or false,
		function(checked)
			BetterFriendlistDB.notificationQuietManual = checked
			BFL:DebugPrint((L.SETTINGS_NOTIFY_DND_MODE or "Do Not Disturb mode") .. " " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	dndToggle:SetTooltip("Do Not Disturb", "Temporarily silence all notifications without changing your settings.")
	table.insert(allFrames, dndToggle)
	
	-- Combat Silence
	local combatQuiet = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_QUIET_COMBAT or "Silence while in combat",
		BetterFriendlistDB.notificationQuietCombat or false,
		function(checked)
			BetterFriendlistDB.notificationQuietCombat = checked
			BFL:DebugPrint((L.SETTINGS_NOTIFY_COMBAT_QUIET or "Combat quiet mode") .. " " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	combatQuiet:SetTooltip("Combat Silence", "Automatically silence notifications during combat encounters to avoid distractions.")
	table.insert(allFrames, combatQuiet)
	
	-- Instance Toggle
	local instanceQuiet = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_QUIET_INSTANCE or "Silence in instances (dungeons, raids, PvP)",
		BetterFriendlistDB.notificationQuietInstance or false,
		function(checked)
			BetterFriendlistDB.notificationQuietInstance = checked
			BFL:DebugPrint((L.SETTINGS_NOTIFY_INSTANCE_QUIET or "Instance quiet mode") .. " " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	instanceQuiet:SetTooltip("Instance Silence", "Silence notifications when you are in dungeons, raids, battlegrounds, or arenas.")
	table.insert(allFrames, instanceQuiet)
	
	-- Scheduled Quiet Hours Toggle
	local scheduledQuiet = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_QUIET_SCHEDULED or "Scheduled quiet hours",
		BetterFriendlistDB.notificationQuietScheduled or false,
		function(checked)
			BetterFriendlistDB.notificationQuietScheduled = checked
			BFL:DebugPrint((L.SETTINGS_NOTIFY_SCHEDULED_QUIET or "Scheduled quiet hours") .. " " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	scheduledQuiet:SetTooltip("Scheduled Quiet Hours", "Silence notifications during specific hours each day. Configure your preferred schedule below.")
	table.insert(allFrames, scheduledQuiet)
	
	-- Helper: Convert minutes to slider index (0-95)
	local function MinutesToIndex(minutes)
		return math.floor(minutes / 15)
	end
	
	-- Helper: Convert slider index to minutes
	local function IndexToMinutes(index)
		return index * 15
	end
	
	-- Helper: Format minutes as HH:MM
	local function FormatTime(minutes)
		local hours = math.floor(minutes / 60)
		local mins = minutes % 60
		return string.format("%02d:%02d", hours, mins)
	end
	
	-- Start Time Slider (0-95 = 00:00 to 23:45 in 15-minute steps)
	local startMinutes = BetterFriendlistDB.notificationQuietScheduleStartMinutes or 1320 -- Default: 22:00 = 1320 minutes
	local startHourSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_NOTIFY_QUIET_START or "Start Time:",
		0,
		95,
		MinutesToIndex(startMinutes),
		function(value)
			return FormatTime(IndexToMinutes(value))
		end,
		function(value)
			BetterFriendlistDB.notificationQuietScheduleStartMinutes = IndexToMinutes(value)
		end
	)
	table.insert(allFrames, startHourSlider)
	
	-- End Time Slider (0-95 = 00:00 to 23:45 in 15-minute steps)
	local endMinutes = BetterFriendlistDB.notificationQuietScheduleEndMinutes or 480 -- Default: 08:00 = 480 minutes
	local endHourSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_NOTIFY_QUIET_END or "End Time:",
		0,
		95,
		MinutesToIndex(endMinutes),
		function(value)
			return FormatTime(IndexToMinutes(value))
		end,
		function(value)
			BetterFriendlistDB.notificationQuietScheduleEndMinutes = IndexToMinutes(value)
		end
	)
	table.insert(allFrames, endHourSlider)
	
	-- Scheduled Hours Info
	local scheduleInfo = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_QUIET_NOTE or "|cffffcc00Note:|r If start hour is greater than end hour, the schedule crosses midnight (e.g., 22:00-08:00).", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, scheduleInfo)
	
	-- ===========================================
	-- OFFLINE NOTIFICATIONS SECTION
	-- ===========================================
	local offlineHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_OFFLINE_HEADER or "Offline Notifications")
	table.insert(allFrames, offlineHeader)
	
	-- Offline Notifications Toggle
	local offlineToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_OFFLINE_ENABLE or "Show notifications when friends go offline",
		BetterFriendlistDB.notificationOfflineEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationOfflineEnabled = checked
			if checked then
				BFL:DebugPrint(L.SETTINGS_NOTIFY_OFFLINE_ENABLED or "Offline notifications |cff00ff00ENABLED|r")
			else
				BFL:DebugPrint(L.SETTINGS_NOTIFY_OFFLINE_DISABLED or "Offline notifications |cffff0000DISABLED|r")
			end
		end
	)
	offlineToggle:SetTooltip("Offline Notifications", "Show notifications when friends log off. These are independent from online notifications and respect all quiet hours settings.")
	table.insert(allFrames, offlineToggle)
	
	-- ===========================================
	-- GAME-SPECIFIC NOTIFICATIONS SECTION (Phase 11.5)
	-- ===========================================
	local gameSpecificHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_GAME_HEADER or "Game-Specific Notifications")
	table.insert(allFrames, gameSpecificHeader)
	
	-- WoW Login Toggle
	local wowLoginToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_WOW_LOGIN or "WoW Login: Notify when friend logs into World of Warcraft",
		BetterFriendlistDB.notificationWowLoginEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationWowLoginEnabled = checked
			if checked then
				BFL:DebugPrint(L.SETTINGS_NOTIFY_WOW_LOGIN_ENABLED or "WoW Login notifications |cff00ff00ENABLED|r")
			else
				BFL:DebugPrint(L.SETTINGS_NOTIFY_WOW_LOGIN_DISABLED or "WoW Login notifications |cffff0000DISABLED|r")
			end
		end
	)
	wowLoginToggle:SetTooltip("WoW Login Notifications", "Get notified when a Battle.net friend starts World of Warcraft (even if they were already online in another game).")
	table.insert(allFrames, wowLoginToggle)
	
	-- Character Switch Toggle
	local charSwitchToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_CHAR_SWITCH or "Character Switch: Notify when friend changes character",
		BetterFriendlistDB.notificationCharSwitchEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationCharSwitchEnabled = checked
			if checked then
				BFL:DebugPrint(L.SETTINGS_NOTIFY_CHAR_SWITCH_ENABLED or "Character switch notifications |cff00ff00ENABLED|r")
			else
				BFL:DebugPrint(L.SETTINGS_NOTIFY_CHAR_SWITCH_DISABLED or "Character switch notifications |cffff0000DISABLED|r")
			end
		end
	)
	charSwitchToggle:SetTooltip("Character Switch Notifications", "Get notified when a friend switches to a different character in World of Warcraft.")
	table.insert(allFrames, charSwitchToggle)
	
	-- Game Switch Toggle
	local gameSwitchToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_NOTIFY_GAME_SWITCH or "Game Switch: Notify when friend changes game",
		BetterFriendlistDB.notificationGameSwitchEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationGameSwitchEnabled = checked
			if checked then
				BFL:DebugPrint(L.SETTINGS_NOTIFY_GAME_SWITCH_ENABLED or "Game switch notifications |cff00ff00ENABLED|r")
			else
				BFL:DebugPrint(L.SETTINGS_NOTIFY_GAME_SWITCH_DISABLED or "Game switch notifications |cffff0000DISABLED|r")
			end
		end
	)
	gameSwitchToggle:SetTooltip("Game Switch Notifications", "Get notified when a friend switches from WoW to another Battle.net game (Diablo, Overwatch, etc.).")
	table.insert(allFrames, gameSwitchToggle)
	
	-- ===========================================
	-- CUSTOM MESSAGES SECTION (Phase 11)
	-- ===========================================
	local messagesHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_MESSAGES_HEADER or "Custom Messages")
	table.insert(allFrames, messagesHeader)
	
	local messagesDesc = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_MESSAGES_DESC or "Customize notification messages. Available variables: %name%, %game%, %level%, %zone%, %class%, %realm%, %char%, %prevchar%", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, messagesDesc)
	
	-- Online Message
	local onlineMsgInput = Components:CreateInput(
		tab,
		L.SETTINGS_NOTIFY_MSG_ONLINE or "Online Message:",
		BetterFriendlistDB.notificationMessageOnline or "%name% is now online",
		function(value)
			if value and value ~= "" then
				BetterFriendlistDB.notificationMessageOnline = value
			end
		end
	)
	table.insert(allFrames, onlineMsgInput)
	
	-- Offline Message
	local offlineMsgInput = Components:CreateInput(
		tab,
		L.SETTINGS_NOTIFY_MSG_OFFLINE or "Offline Message:",
		BetterFriendlistDB.notificationMessageOffline or "%name% went offline",
		function(value)
			if value and value ~= "" then
				BetterFriendlistDB.notificationMessageOffline = value
			end
		end
	)
	table.insert(allFrames, offlineMsgInput)
	
	-- WoW Login Message (Phase 11.5)
	local wowLoginMsgInput = Components:CreateInput(
		tab,
		L.SETTINGS_NOTIFY_MSG_WOW_LOGIN or "WoW Login Message:",
		BetterFriendlistDB.notificationMessageWowLogin or "%name% logged into World of Warcraft",
		function(value)
			if value and value ~= "" then
				BetterFriendlistDB.notificationMessageWowLogin = value
			end
		end
	)
	table.insert(allFrames, wowLoginMsgInput)
	
	-- Character Switch Message
	local charSwitchMsgInput = Components:CreateInput(
		tab,
		L.SETTINGS_NOTIFY_MSG_CHAR_SWITCH or "Character Switch Message:",
		BetterFriendlistDB.notificationMessageCharSwitch or "%name% switched to %char%",
		function(value)
			if value and value ~= "" then
				BetterFriendlistDB.notificationMessageCharSwitch = value
			end
		end
	)
	table.insert(allFrames, charSwitchMsgInput)
	
	-- Game Switch Message
	local gameSwitchMsgInput = Components:CreateInput(
		tab,
		L.SETTINGS_NOTIFY_MSG_GAME_SWITCH or "Game Switch Message:",
		BetterFriendlistDB.notificationMessageGameSwitch or "%name% is now playing %game%",
		function(value)
			if value and value ~= "" then
				BetterFriendlistDB.notificationMessageGameSwitch = value
			end
		end
	)
	table.insert(allFrames, gameSwitchMsgInput)
	
	-- Preview Info Text
	local previewInfo = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_PREVIEW_TIP or "|cffffcc00Tip:|r Use the 'Test Notification' button above to preview your custom messages.", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, previewInfo)
	
	-- ===========================================
	-- GROUP TRIGGERS SECTION (Phase 10)
	-- ===========================================
	local triggersHeader = Components:CreateHeader(tab, L.SETTINGS_NOTIFY_TRIGGERS_HEADER or "Group Triggers")
	table.insert(allFrames, triggersHeader)
	
	local triggersDesc = Components:CreateLabel(tab, L.SETTINGS_NOTIFY_TRIGGERS_DESC or "Get notified when a certain number of friends from a group come online. Example: Alert when 3+ M+ team members are online.", true, {r=0.7, g=0.7, b=0.7})
	table.insert(allFrames, triggersDesc)
	
	-- Trigger list container (Custom frame kept, but sized/anchored better)
	local triggerListContainer = CreateFrame("Frame", nil, tab)
	triggerListContainer:SetSize(360, 100) -- Initial height
	triggerListContainer:SetPoint("LEFT", 5, 0)
	triggerListContainer:SetPoint("RIGHT", -5, 0)
	table.insert(allFrames, triggerListContainer)
	
	-- Function to refresh trigger list
	local function RefreshTriggerList()
		-- Clear existing children
		for _, child in ipairs({triggerListContainer:GetChildren()}) do
			child:Hide()
			child:SetParent(nil)
		end
		
		-- Clear all font strings
		for _, region in ipairs({triggerListContainer:GetRegions()}) do
			if region:GetObjectType() == "FontString" then
				region:Hide()
				region:SetText("")
			end
		end
		
		if not BetterFriendlistDB.notificationGroupTriggers then
			BetterFriendlistDB.notificationGroupTriggers = {}
		end
		
		local yOffset = 0
		local Groups = BFL:GetModule("Groups")
		local triggerCount = 0
		
		-- Show each trigger
		for triggerID, trigger in pairs(BetterFriendlistDB.notificationGroupTriggers) do
			triggerCount = triggerCount + 1
			local triggerFrame = CreateFrame("Frame", nil, triggerListContainer)
			triggerFrame:SetSize(360, 25)
			triggerFrame:SetPoint("TOPLEFT", triggerListContainer, "TOPLEFT", 10, yOffset) -- Added margin
			triggerFrame:SetPoint("RIGHT", triggerListContainer, "RIGHT", -10, 0)
			
			-- Get group name
			local group = Groups and Groups:Get(trigger.groupId)
			local groupName = group and group.name or trigger.groupId
			
			-- Trigger label
			local label = triggerFrame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
			label:SetPoint("LEFT", triggerFrame, "LEFT", 0, 0)
			label:SetText(string.format(L.SETTINGS_NOTIFY_TRIGGER_FORMAT or "%d+ from '%s'", trigger.threshold, groupName))
			
			-- Enable/Disable toggle
			local checkboxTemplate = BFL.IsClassic and "InterfaceOptionsCheckButtonTemplate" or "SettingsCheckboxTemplate"
			local enableBtn = CreateFrame("CheckButton", nil, triggerFrame, checkboxTemplate)
			enableBtn:SetPoint("RIGHT", triggerFrame, "RIGHT", -40, 0)
			enableBtn:SetSize(20, 20)
			enableBtn:SetChecked(trigger.enabled)
			enableBtn:SetScript("OnClick", function(self)
				trigger.enabled = self:GetChecked()
				BFL:DebugPrint((L.SETTINGS_NOTIFY_TRIGGER_PREFIX or "Group trigger") .. " " .. (trigger.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
			end)
			enableBtn:SetScript("OnEnter", function() end)
			enableBtn:SetScript("OnLeave", function() end)
			
			-- Delete button
			local deleteBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
			deleteBtn:SetSize(20, 20)
			deleteBtn:SetPoint("RIGHT", triggerFrame, "RIGHT", 0, 0)
			deleteBtn:SetText("X")
			deleteBtn:SetScript("OnClick", function()
				BetterFriendlistDB.notificationGroupTriggers[triggerID] = nil
				RefreshTriggerList()
				BFL:DebugPrint(L.SETTINGS_NOTIFY_TRIGGER_REMOVED or "Group trigger removed")
			end)
			
			yOffset = yOffset - 30
		end
		
		-- Show "No triggers" message if empty
		if triggerCount == 0 then
			local emptyText = triggerListContainer:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
			emptyText:SetPoint("TOPLEFT", triggerListContainer, "TOPLEFT", 10, 0)
			emptyText:SetTextColor(0.5, 0.5, 0.5)
			emptyText:SetText(L.SETTINGS_NOTIFY_NO_TRIGGERS or "No group triggers configured. Click 'Add Trigger' below.")
			yOffset = -20
		end
		
		-- Resize container based on content
		triggerListContainer:SetHeight(math.abs(yOffset) + 10)
	end
	
	-- Add Trigger button
	local addTriggerBtn = Components:CreateButton(tab, L.SETTINGS_NOTIFY_ADD_TRIGGER or "Add Trigger", function()
		if _G.BFL_ShowGroupTriggerDialog then
			_G.BFL_ShowGroupTriggerDialog()
		end
	end)
	table.insert(allFrames, addTriggerBtn)
	
	-- Initial refresh
	RefreshTriggerList()
	
	-- Register global refresh callback for dialog
	_G.BFL_RefreshNotificationTriggers = RefreshTriggerList
	
	-- Anchor all frames vertically with proper spacing
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- ===========================================
-- DATA BROKER TAB (Tab ID 5)
-- ===========================================
function Settings:RefreshBrokerTab()
	if not settingsFrame then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.BrokerTab then return end
	
	local tab = content.BrokerTab
	local DB = GetDB()
	if not DB then return end
	
	-- Clear existing content
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	
	-- Header: Data Broker Integration
	local header = Components:CreateHeader(tab, L.BROKER_SETTINGS_HEADER_INTEGRATION)
	table.insert(allFrames, header)
	
	-- Info Text
	local infoText = Components:CreateLabel(tab, L.BROKER_SETTINGS_INFO, true)
	table.insert(allFrames, infoText)
	
	-- Enable Data Broker
	local enableBroker = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_ENABLE or "Enable Data Broker",
		DB:Get("brokerEnabled", true),
		function(val)
			BetterFriendlistDB.brokerEnabled = val
			-- Show confirmation dialog for reload
			local statusText = val and "|cff00ff00" .. (L.STATUS_ENABLED or "ENABLED") .. "|r" or "|cffff0000" .. (L.STATUS_DISABLED or "DISABLED") .. "|r"
			StaticPopupDialogs["BFL_BROKER_RELOAD_CONFIRM"] = {
				text = string.format(L.BROKER_SETTINGS_RELOAD_TEXT or "Data Broker has been %s.\n\nA UI reload is required for this change to take effect.\n\nReload now?", statusText),
				button1 = L.BROKER_SETTINGS_RELOAD_BTN or "Reload Now",
				button2 = L.BROKER_SETTINGS_RELOAD_CANCEL or "Later",
				OnAccept = function()
					ReloadUI()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("BFL_BROKER_RELOAD_CONFIRM")
		end)
	enableBroker:SetTooltip(L.BROKER_SETTINGS_ENABLE or "Enable Data Broker", L.BROKER_SETTINGS_ENABLE_TOOLTIP or "Show BetterFriendlist in Data Broker display addons. Requires UI reload to take effect.")
	table.insert(allFrames, enableBroker)
	
	-- Show Icon
	local showIcon = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_ICON or "Show Icon on Display Addon",
		DB:Get("brokerShowIcon", true),
		function(val)
			BetterFriendlistDB.brokerShowIcon = val
			local Broker = BFL:GetModule("Broker")
			if Broker and Broker.UpdateBrokerText then Broker:UpdateBrokerText() end
		end)
	showIcon:SetTooltip(L.BROKER_SETTINGS_SHOW_ICON_TITLE or "Show Icon", L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP or "Display the BetterFriendlist icon on your display addon")
	table.insert(allFrames, showIcon)
	
	-- Show Label
	local showLabel = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_LABEL or "Show Label",
		DB:Get("brokerShowLabel", true),
		function(val)
			BetterFriendlistDB.brokerShowLabel = val
			local Broker = BFL:GetModule("Broker")
			if Broker and Broker.UpdateBrokerText then Broker:UpdateBrokerText() end
		end)
	showLabel:SetTooltip(L.BROKER_SETTINGS_SHOW_LABEL_TITLE or "Show Label", L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP or "Display 'Friends:' text before the count")
	table.insert(allFrames, showLabel)

	-- Show Total Count
	local showTotal = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_TOTAL or "Show Total Count",
		DB:Get("brokerShowTotal", true),
		function(val)
			BetterFriendlistDB.brokerShowTotal = val
			local Broker = BFL:GetModule("Broker")
			if Broker and Broker.UpdateBrokerText then Broker:UpdateBrokerText() end
		end)
	showTotal:SetTooltip(L.BROKER_SETTINGS_SHOW_TOTAL_TITLE or "Show Total Count", L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP or "Display total friends count (e.g. '5/10') instead of just online count")
	table.insert(allFrames, showTotal)

	-- Split WoW/BNet Counts
	local showGroups = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_GROUPS,
		DB:Get("brokerShowGroups", false),
		function(val)
			BetterFriendlistDB.brokerShowGroups = val
			-- Refresh tab to show/hide sub-options
			self:RefreshBrokerTab()
			-- Update broker text immediately
			local Broker = BFL:GetModule("Broker")
			if Broker and Broker.UpdateBrokerText then
				Broker:UpdateBrokerText()
			end
		end)
	showGroups:SetTooltip(L.BROKER_SETTINGS_SHOW_GROUPS_TITLE or "Split Counts", L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP or "Show separate counts for WoW and Battle.net friends")
	table.insert(allFrames, showGroups)

	-- Sub-options for Split Counts (only visible if enabled)
	if DB:Get("brokerShowGroups", false) then
		-- Show WoW Icon
		local showWoWIcon = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_WOW_ICON or "Show WoW Icon",
			DB:Get("brokerShowWoWIcon", true),
			function(val)
				BetterFriendlistDB.brokerShowWoWIcon = val
				local Broker = BFL:GetModule("Broker")
				if Broker and Broker.UpdateBrokerText then Broker:UpdateBrokerText() end
			end)
		showWoWIcon:SetTooltip(L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE or "Show WoW Icon", L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP or "Display the World of Warcraft icon next to the WoW friend count")
		
		table.insert(allFrames, showWoWIcon)

		-- Show Battle.net Icon
		local showBNetIcon = Components:CreateCheckbox(tab, L.BROKER_SETTINGS_SHOW_BNET_ICON or "Show Battle.net Icon",
			DB:Get("brokerShowBNetIcon", true),
			function(val)
				BetterFriendlistDB.brokerShowBNetIcon = val
				local Broker = BFL:GetModule("Broker")
				if Broker and Broker.UpdateBrokerText then Broker:UpdateBrokerText() end
			end)
		showBNetIcon:SetTooltip(L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE or "Show Battle.net Icon", L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP or "Display the Battle.net icon next to the Battle.net friend count")
		
		table.insert(allFrames, showBNetIcon)
	end
	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- Header: Tooltip Columns
	local columnsHeader = Components:CreateHeader(tab, L.BROKER_SETTINGS_COLUMNS_HEADER)
	table.insert(allFrames, columnsHeader)
	
	-- Column Reordering Logic
	local availableColumns = {
		{ key = "Name",      label = L.BROKER_COLUMN_NAME },
		{ key = "Level",     label = L.BROKER_COLUMN_LEVEL },
		{ key = "Character", label = L.BROKER_COLUMN_CHARACTER },
		{ key = "Game",      label = L.BROKER_COLUMN_GAME },
		{ key = "Zone",      label = L.BROKER_COLUMN_ZONE },
		{ key = "Realm",     label = L.BROKER_COLUMN_REALM },
		{ key = "Notes",     label = L.BROKER_COLUMN_NOTES }
	}
	
	local currentOrder = DB:Get("brokerColumnOrder")
	local orderedColumns = {}
	
	if currentOrder and #currentOrder > 0 then
		for _, key in ipairs(currentOrder) do
			for _, col in ipairs(availableColumns) do
				if col.key == key then
					table.insert(orderedColumns, col)
					break
				end
			end
		end
		-- Add missing columns
		for _, col in ipairs(availableColumns) do
			local found = false
			for _, ordered in ipairs(orderedColumns) do
				if ordered.key == col.key then
					found = true
					break
				end
			end
			if not found then
				table.insert(orderedColumns, col)
			end
		end
	else
		-- Default order
		orderedColumns = availableColumns
	end
	
	-- Create reorderable list items
	for i, col in ipairs(orderedColumns) do
		local canMoveUp = i > 1
		local canMoveDown = i < #orderedColumns
		
		-- Create a custom list item that includes a checkbox for visibility
		local listItem = Components:CreateListItem(
			tab,
			col.label,
			i,
			-- Move Up
			function()
				if i > 1 then
					local temp = orderedColumns[i-1]
					orderedColumns[i-1] = orderedColumns[i]
					orderedColumns[i] = temp
					
					local newOrder = {}
					for _, c in ipairs(orderedColumns) do
						table.insert(newOrder, c.key)
					end
					DB:Set("brokerColumnOrder", newOrder)
					self:RefreshBrokerTab()
				end
			end,
			-- Move Down
			function()
				if i < #orderedColumns then
					local temp = orderedColumns[i+1]
					orderedColumns[i+1] = orderedColumns[i]
					orderedColumns[i] = temp
					
					local newOrder = {}
					for _, c in ipairs(orderedColumns) do
						table.insert(newOrder, c.key)
					end
					DB:Set("brokerColumnOrder", newOrder)
					self:RefreshBrokerTab()
				end
			end,
			nil, -- No rename
			nil, -- No color
			nil  -- No delete
		)
		
		-- Hide unused buttons
		if listItem.colorButton then listItem.colorButton:Hide() end
		if listItem.orderText then listItem.orderText:Hide() end
		
		-- Add Checkbox to the list item (Classic-compatible template selection)
		local isChecked = DB:Get("brokerShowCol" .. col.key, true)
		local checkboxTemplate = BFL.IsClassic and "InterfaceOptionsCheckButtonTemplate" or "SettingsCheckboxTemplate"
		local checkbox = CreateFrame("CheckButton", nil, listItem, checkboxTemplate)
		checkbox:SetPoint("LEFT", listItem, "LEFT", 4, 0)
		checkbox:SetSize(20, 20)
		checkbox:SetChecked(isChecked)
		checkbox:SetScript("OnClick", function(self)
			local checked = self:GetChecked()
			DB:Set("brokerShowCol" .. col.key, checked)
		end)
		
		-- Fix for ugly hover effect
		checkbox:SetScript("OnEnter", function() end)
		checkbox:SetScript("OnLeave", function() end)
		
		-- Adjust label position to make room for checkbox
		if listItem.nameText then
			listItem.nameText:ClearAllPoints()
			listItem.nameText:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)
		end
		
		listItem:SetArrowState(canMoveUp, canMoveDown)
		table.insert(allFrames, listItem)
	end
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- ===========================================
-- GLOBAL SYNC TAB (Tab ID 6)
-- ===========================================
function Settings:RefreshGlobalSyncTab()
	if not settingsFrame then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.GlobalSyncTab then return end
	
	local tab = content.GlobalSyncTab
	local DB = GetDB()
	if not DB then return end
	
	-- Clear existing content
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}
	
	local allFrames = {}
	
	-- Header: Global Friend Sync
	local header = Components:CreateHeader(tab, L.SETTINGS_TAB_GLOBAL_SYNC or "Global Friend Sync")
	table.insert(allFrames, header)
	
	-- Description
	local desc = Components:CreateLabel(tab, L.SETTINGS_GLOBAL_SYNC_DESC or "Synchronize your WoW friends list across all characters on this account.", true)
	table.insert(allFrames, desc)
	
	-- Enable Global Sync
	local enableSync = Components:CreateCheckbox(tab, L.SETTINGS_GLOBAL_SYNC_ENABLE or "Enable Global Friend Sync",
		DB:Get("enableGlobalSync", false),
		function(val)
			BetterFriendlistDB.enableGlobalSync = val
			if val then
				BFL:DebugPrint("Global Sync |cff00ff00" .. (L.STATUS_ENABLED or "ENABLED") .. "|r")
				-- Trigger sync
				local GlobalSync = BFL:GetModule("GlobalSync")
				if GlobalSync then GlobalSync:OnFriendListUpdate() end
			else
				BFL:DebugPrint("Global Sync |cffff0000" .. (L.STATUS_DISABLED or "DISABLED") .. "|r")
			end
			-- Refresh to update table state if needed
			self:RefreshGlobalSyncTab()
		end)
	enableSync:SetTooltip(L.SETTINGS_GLOBAL_SYNC_ENABLE or "Enable Global Sync", L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP or "Automatically sync friends from other realms to this character.")
	table.insert(allFrames, enableSync)
	
	-- Enable Deletion
	local enableDeletion = Components:CreateCheckbox(tab, L.SETTINGS_GLOBAL_SYNC_DELETION or "Enable Deletion",
		DB:Get("enableGlobalSyncDeletion", false),
		function(val)
			BetterFriendlistDB.enableGlobalSyncDeletion = val
			if val then
				BFL:DebugPrint("Global Sync Deletion |cff00ff00" .. (L.STATUS_ENABLED or "ENABLED") .. "|r")
			else
				BFL:DebugPrint("Global Sync Deletion |cffff0000" .. (L.STATUS_DISABLED or "DISABLED") .. "|r")
			end
		end)
	enableDeletion:SetTooltip(L.SETTINGS_GLOBAL_SYNC_DELETION or "Enable Deletion", L.SETTINGS_GLOBAL_SYNC_DELETION_DESC or "Allow the sync process to remove friends from your list if they are removed from the database.")
	table.insert(allFrames, enableDeletion)

	-- Show Deleted Friends
	local showDeleted = Components:CreateCheckbox(tab, L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED or "Show Deleted Friends",
		self.showDeletedFriends or false,
		function(val)
			self.showDeletedFriends = val
			self:RefreshGlobalSyncTab()
		end)
	showDeleted:SetTooltip(L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE or "Show Deleted Friends", L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP or "Show friends that have been deleted from the database but are kept for history.")
	table.insert(allFrames, showDeleted)
	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Synced Friends
	local listHeader = Components:CreateHeader(tab, L.SETTINGS_GLOBAL_SYNC_HEADER or "Synced Friends Database")
	table.insert(allFrames, listHeader)
	
	-- Populate Table
	local count = 0
	local rowHeight = 24
	
	if BetterFriendlistDB.GlobalFriends then
		for faction, friends in pairs(BetterFriendlistDB.GlobalFriends) do
			for key, value in pairs(friends) do
				if value.guid or value.notes or value.lastSeen or value.deleted then
					-- Check if we should show this friend
					if not value.deleted or self.showDeletedFriends then
						local friendUID = key
						local data = value
						count = count + 1
						
						local row = CreateFrame("Frame", nil, tab)
						row:SetHeight(rowHeight)
						row:SetPoint("LEFT", 5, 0) -- Maximized width (was 20)
						row:SetPoint("RIGHT", -5, 0) -- Maximized width (was -20)
						
						-- Background (alternating)
						if count % 2 == 0 then
							local bg = row:CreateTexture(nil, "BACKGROUND")
							bg:SetAllPoints()
							bg:SetColorTexture(1, 1, 1, 0.05)
						end
						
						-- Parse Name and Realm
						local name, realm = string.match(friendUID, "^(.+)%-(.+)$")
						if not name then 
							name = friendUID 
							realm = "Unknown"
						end
						
						-- Name
						local nameText = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
						nameText:SetPoint("LEFT", 5, 0)
						nameText:SetWidth(130) -- Optimized to prevent clipping (was 155)
						nameText:SetJustifyH("LEFT")
						nameText:SetWordWrap(false)
						nameText:SetText(name)
						
						-- Realm
						local realmText = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
						realmText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
						realmText:SetWidth(120) -- Optimized to prevent clipping (was 135)
						realmText:SetJustifyH("LEFT")
						realmText:SetWordWrap(false)
						realmText:SetText(realm)
						
						-- Faction Icon
						local factionIcon = row:CreateTexture(nil, "ARTWORK")
						factionIcon:SetSize(16, 16)
						factionIcon:SetPoint("LEFT", realmText, "RIGHT", 5, 0)
						if faction == "Alliance" then
							factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Alliance")
						elseif faction == "Horde" then
							factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Horde")
						end

						-- Visuals for deleted friends
						if value.deleted then
							nameText:SetTextColor(0.5, 0.5, 0.5)
							realmText:SetTextColor(0.5, 0.5, 0.5)
						end
						
						-- Action Button (Delete or Restore)
						local actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
						actionBtn:SetSize(20, 20)
						actionBtn:SetPoint("RIGHT", -5, 0)
						
						if value.deleted then
							-- Restore Button
							actionBtn:SetText("R")
							actionBtn:SetScript("OnClick", function()
								BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted = nil
								BetterFriendlistDB.GlobalFriends[faction][friendUID].deletedTime = nil
								BetterFriendlistDB.GlobalFriends[faction][friendUID].restoring = true -- Flag for GlobalSync to restore note
								
								-- Add back to friend list
								C_FriendList.AddFriend(friendUID)
								BFL:DebugPrint("Restored " .. name .. " to friend list.")
								
								self:RefreshGlobalSyncTab()
							end)
							actionBtn:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
								GameTooltip:SetText(L.TOOLTIP_RESTORE_FRIEND or "Restore Friend")
								GameTooltip:Show()
							end)
							actionBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
						else
							-- Delete Button
							actionBtn:SetText("X")
							actionBtn:SetScript("OnClick", function()
								-- Mark as deleted
								BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted = true
								BetterFriendlistDB.GlobalFriends[faction][friendUID].deletedTime = time()
								
								-- Immediate deletion from friend list if enabled
								if BetterFriendlistDB.enableGlobalSyncDeletion then
									local removed = false
									-- Check if friend exists in current list
									for i = 1, (C_FriendList.GetNumFriends() or 0) do
										local info = C_FriendList.GetFriendInfoByIndex(i)
										if info then
											-- Robust matching: Check GUID first, then Name-Realm, then Name
											local match = false
											if data.guid and info.guid and data.guid == info.guid then
												match = true
											elseif info.name == friendUID then
												match = true
											elseif info.name == name then
												match = true
											end
											
											if match then
												C_FriendList.RemoveFriend(info.name) -- Use the name from the API
												BFL:DebugPrint("Removed " .. info.name .. " from friend list.")
												removed = true
												break
											end
										end
									end
									
									if not removed then
										-- Fallback: Try to remove by UID directly if not found in loop (e.g. offline/cache issue)
										C_FriendList.RemoveFriend(friendUID)
									end
								end
								
								self:RefreshGlobalSyncTab()
							end)
							actionBtn:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
								GameTooltip:SetText(L.TOOLTIP_DELETE_FRIEND or "Delete Friend")
								GameTooltip:Show()
							end)
							actionBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
						end
						
						-- Edit Button (Note)
						local editBtn = CreateFrame("Button", nil, row)
						editBtn:SetSize(16, 16)
						editBtn:SetPoint("RIGHT", actionBtn, "LEFT", -5, 0)
						editBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
						editBtn:SetScript("OnClick", function()
							StaticPopupDialogs["BFL_EDIT_GLOBAL_NOTE"] = {
								text = string.format(L.POPUP_EDIT_NOTE_TITLE or "Edit Note for %s", name),
								button1 = L.BUTTON_SAVE or "Save",
								button2 = L.BUTTON_CANCEL or "Cancel",
								hasEditBox = true,
								OnShow = function(self)
									self.EditBox:SetText(data.notes or "")
								end,
								OnAccept = function(self)
									local text = self.EditBox:GetText()
									-- Update DB
									BetterFriendlistDB.GlobalFriends[faction][friendUID].notes = text
									
									-- Update In-Game Friend Note if friend exists locally
									for i = 1, (C_FriendList.GetNumFriends() or 0) do
										local info = C_FriendList.GetFriendInfoByIndex(i)
										if info then
											-- Robust matching
											local match = false
											if data.guid and info.guid and data.guid == info.guid then
												match = true
											elseif info.name == friendUID then
												match = true
											elseif info.name == name then
												match = true
											end
											
											if match then
												C_FriendList.SetFriendNotes(info.name, text)
												BFL:DebugPrint("Updated note for " .. info.name)
												break
											end
										end
									end
									
									-- Trigger sync to ensure consistency
									local GlobalSync = BFL:GetModule("GlobalSync")
									if GlobalSync then GlobalSync:OnFriendListUpdate() end
								end,
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
							}
							StaticPopup_Show("BFL_EDIT_GLOBAL_NOTE")
						end)
						
						editBtn:SetScript("OnEnter", function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							GameTooltip:SetText(L.TOOLTIP_EDIT_NOTE or "Edit Note")
							GameTooltip:Show()
						end)
						editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
						
						table.insert(allFrames, row)
					end
				end
			end
		end
	end
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

return Settings



