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
local categoryButtons = {} -- Store vertical category buttons

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
		bg:SetColorTexture(0, 0, 0, 1)
		
		local texture = button.editButton:CreateTexture(nil, "ARTWORK")
		texture:SetPoint("TOPLEFT", button.editButton, "TOPLEFT", UI.SPACING_TINY, -UI.SPACING_TINY)
		texture:SetPoint("BOTTOMRIGHT", button.editButton, "BOTTOMRIGHT", -UI.SPACING_TINY, UI.SPACING_TINY)
		texture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		button.editButton.texture = texture
		
		button.editButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		local highlightTex = button.editButton:GetHighlightTexture()
		if highlightTex then
			highlightTex:ClearAllPoints()
			highlightTex:SetPoint("TOPLEFT", button.editButton, "TOPLEFT", UI.SPACING_TINY, -UI.SPACING_TINY)
			highlightTex:SetPoint("BOTTOMRIGHT", button.editButton, "BOTTOMRIGHT", -UI.SPACING_TINY, UI.SPACING_TINY)
		end
		
		button.editButton:SetScript("OnClick", function(self)
			Settings:RenameGroup(groupId, groupName)
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
	
	-- Highlight removed by user request
	-- button.colorButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	
	button.colorButton:SetScript("OnClick", function(self)
		Settings:ShowColorPicker(groupId, groupName, button.colorSwatch)
	end)
	
	button.colorButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.TOOLTIP_GROUP_COLOR, 1, 0.82, 0)
		GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	
	button.colorButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Delete Button (only for custom groups)
	if not isBuiltIn then
		button.deleteButton = CreateFrame("Button", nil, button)
		button.deleteButton:SetSize(24, 24)
		button.deleteButton:SetPoint("RIGHT", -UI.SPACING_MEDIUM, 0)
		
		local bg = button.deleteButton:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 1)
		
		local texture = button.deleteButton:CreateTexture(nil, "ARTWORK")
		texture:SetPoint("TOPLEFT", button.deleteButton, "TOPLEFT", UI.SPACING_TINY, -UI.SPACING_TINY)
		texture:SetPoint("BOTTOMRIGHT", button.deleteButton, "BOTTOMRIGHT", -UI.SPACING_TINY, UI.SPACING_TINY)
		texture:SetAtlas("transmog-icon-remove", true)
		texture:SetVertexColor(0.9, 0.2, 0.2)
		button.deleteButton.texture = texture
		
		local highlight = button.deleteButton:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetPoint("TOPLEFT", button.deleteButton, "TOPLEFT", UI.SPACING_TINY, -UI.SPACING_TINY)
		highlight:SetPoint("BOTTOMRIGHT", button.deleteButton, "BOTTOMRIGHT", -UI.SPACING_TINY, UI.SPACING_TINY)
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
		self:RefreshCategories() -- Update category visibility based on Beta features
		settingsFrame:Show()
		self:SelectCategory(currentTab or 1) -- Restore or show first category
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
	{id = 8, name = L.SETTINGS_TAB_RAID, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\shield.blp", beta = false},
	{id = 4, name = L.SETTINGS_TAB_ADVANCED, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\sliders.blp", beta = false},
	
	-- Data Broker & Global Sync (Stable)
	{id = 5, name = L.SETTINGS_TAB_DATABROKER, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\activity.blp", beta = false},
	{id = 6, name = L.SETTINGS_TAB_GLOBAL_SYNC, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\globe.blp", beta = false},
	
	-- Special Tabs (Force to new line)
	{id = 7, name = L.STREAMER_MODE_TITLE, icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\twitch.blp", beta = false},
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

-- Refresh category visibility (Beta features toggle)
function Settings:RefreshCategories()
	if not settingsFrame then
		settingsFrame = BetterFriendlistSettingsFrame
	end
	if not settingsFrame then return end
	
	-- Ensure CategoryList exists
	local listFrame = settingsFrame.CategoryList
	if not listFrame then return end
	
	local visibleCategories = GetVisibleTabs()
	
	-- Layout constants
	local BUTTON_HEIGHT = 32
	local SPACING = 2
	local MAX_TEXT_WIDTH = 0
	
	-- Update category buttons
	for i, catDef in ipairs(visibleCategories) do
		local button = categoryButtons[i]
		if not button then
			button = CreateFrame("Button", nil, listFrame)
			button:SetHeight(BUTTON_HEIGHT)
			
			-- Background/Highlight
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
			button:GetHighlightTexture():SetAlpha(UI.ALPHA_DIMMED or 0.3)
			button:GetHighlightTexture():SetBlendMode("ADD")
			
			-- Selected State Indicator
			button.selectedTex = button:CreateTexture(nil, "BACKGROUND")
			button.selectedTex:SetAllPoints()
			button.selectedTex:SetColorTexture(1, 1, 1, 0.1)
			button.selectedTex:Hide()
			
			-- Icon
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetSize(18, 18)
			button.icon:SetPoint("LEFT", 10, 0)
			
			-- Text
			button.text = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
			button.text:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
			button.text:SetJustifyH("LEFT")
			
			-- Click Handler
			button:SetScript("OnClick", function(self)
				Settings:SelectCategory(self.id)
			end)
			
			categoryButtons[i] = button
		end
		
		-- Update Button Data
		button.id = catDef.id
		button:Show()
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -((i-1) * (BUTTON_HEIGHT + SPACING)))
		button:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", 0, -((i-1) * (BUTTON_HEIGHT + SPACING)))
		
		-- Styling
		local r, g, b = 1, 0.82, 0 -- Default Gold
		if catDef.beta then
			r, g, b = 1, 0.53, 0 -- Orange
		end
		
		button.text:SetText(catDef.name)
		button.text:SetTextColor(r, g, b)
		
		if catDef.icon then
			button.icon:SetTexture(catDef.icon)
			button.icon:SetVertexColor(r, g, b) -- Match text color exactly
			button.icon:Show()
		else
			button.icon:Hide()
		end
		
		-- Measure width
		local width = button.text:GetStringWidth()
		if width > MAX_TEXT_WIDTH then
			MAX_TEXT_WIDTH = width
		end
	end
	
	-- Hide unused buttons
	for i = #visibleCategories + 1, #categoryButtons do
		categoryButtons[i]:Hide()
	end
	
	-- Dynamic Width Calculation (Icon + Gap + Text + Padding)
	local requiredWidth = 10 + 18 + 10 + MAX_TEXT_WIDTH + 20
	local sidebarWidth = math.max(requiredWidth, 150)
	listFrame:SetWidth(sidebarWidth)
	
	-- Update Content ScrollChild width to match visible area
	-- SettingsFrame (800) - Sidebar (sidebarWidth) - Margins
	-- MainInset Width = 790 - (sidebarWidth + 20) = 770 - sidebarWidth
	-- ScrollChild Width = MainInset Width - 33 (8 left + 25 right anchors)
	local contentWidth = (770 - sidebarWidth) - 33
	
	if settingsFrame.ContentScrollFrame and settingsFrame.ContentScrollFrame.Content then
		settingsFrame.ContentScrollFrame.Content:SetWidth(contentWidth)
		
		-- Force layout update for active tab components if needed
		local content = settingsFrame.ContentScrollFrame.Content
		if content.GeneralTab and content.GeneralTab:IsVisible() then
			-- Re-trigger logic if strictly needed, but OnSizeChanged usually fires automatically if width changed
		end
	end
end

-- Hide the settings window
function Settings:Hide()
	if settingsFrame then
		settingsFrame:Hide()
	end
end

-- Select a settings category
function Settings:SelectCategory(categoryID)
	if not settingsFrame then return end
	
	currentTab = categoryID
	
	-- Update Button Selection States
	for _, button in pairs(categoryButtons) do
		-- Determine if beta category for color restoration
		local isBeta = false
		for _, def in ipairs(TAB_DEFINITIONS) do
			if def.id == button.id and def.beta then
				isBeta = true
				break
			end
		end

		if button.id == categoryID then
			-- SELECTED STATE
			if button.selectedTex then button.selectedTex:Show() end
			button.text:SetTextColor(1, 1, 1) -- White Text
			if button.icon then button.icon:SetVertexColor(1, 1, 1) end -- White Icon
		else
			-- UNSELECTED STATE
			if button.selectedTex then button.selectedTex:Hide() end
			
			local r, g, b
			if isBeta then
				r, g, b = 1, 0.53, 0 -- Beta Orange
			else
				r, g, b = 1, 0.82, 0 -- Normal Gold
			end
			
			button.text:SetTextColor(r, g, b)
			if button.icon then button.icon:SetVertexColor(r, g, b) end
		end
	end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if content then
		if content.GeneralTab then content.GeneralTab:Hide() end
		if content.FontsTab then content.FontsTab:Hide() end
		if content.GroupsTab then content.GroupsTab:Hide() end
		if content.AdvancedTab then content.AdvancedTab:Hide() end
		if content.StreamerTab then content.StreamerTab:Hide() end
		if content.BrokerTab then content.BrokerTab:Hide() end
		if content.GlobalSyncTab then content.GlobalSyncTab:Hide() end
		if content.RaidTab then content.RaidTab:Hide() end
		
		if categoryID == 1 and content.GeneralTab then
			content.GeneralTab:Show()
			self:RefreshGeneralTab()
		elseif categoryID == 2 and content.FontsTab then
			content.FontsTab:Show()
			self:RefreshFontsTab()
		elseif categoryID == 3 and content.GroupsTab then
			content.GroupsTab:Show()
			self:RefreshGroupsTab()
		elseif categoryID == 4 and content.AdvancedTab then
			content.AdvancedTab:Show()
			self:RefreshAdvancedTab()
		elseif categoryID == 5 and content.BrokerTab then
			content.BrokerTab:Show()
			self:RefreshBrokerTab()
		elseif categoryID == 6 and content.GlobalSyncTab then
			content.GlobalSyncTab:Show()
			self:RefreshGlobalSyncTab()
		elseif categoryID == 7 and content.StreamerTab then
			content.StreamerTab:Show()
			self:RefreshStreamerTab()
		elseif categoryID == 8 and content.RaidTab then
			content.RaidTab:Show()
			self:RefreshRaidTab()
		end
		
		-- Adjust content height dynamically after tab is shown
		self:AdjustContentHeight(categoryID)
		
		-- Reset scroll position to top (User Request: Fix scroll staying down when switching tabs)
		if settingsFrame.ContentScrollFrame then
			settingsFrame.ContentScrollFrame:SetVerticalScroll(0)
		end
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
		activeTab = content.GlobalSyncTab
	elseif tabID == 7 then
		activeTab = content.StreamerTab
	elseif tabID == 8 then
		activeTab = content.RaidTab
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
	DB:Set("favoriteIconStyle", "bfl")
	
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
	
	-- Handle Reset (Right Click) - Snapshot Group Color (Fix #34: includes alpha)
	if isReset then
		local Groups = GetGroups()
		local group = Groups and Groups:Get(groupId)
		local r, g, b, a = 1, 1, 1, 1
		if group and group.color then
			r, g, b = group.color.r, group.color.g, group.color.b
			a = group.color.a or 1
		end

		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = {r = r, g = g, b = b, a = a}
		DB:Set("groupCountColors", groupCountColors)
		
		if group then
			group.countColor = {r = r, g = g, b = b, a = a}
		end
		
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
	
	-- Robust Cleanup: Ensure no stale callbacks or state exist
	ColorPickerFrame:Hide()
	ColorPickerFrame.func = nil
	ColorPickerFrame.opacityFunc = nil
	ColorPickerFrame.cancelFunc = nil
	
	-- Fix #34: Get existing alpha value for count color
	local a = 1.0
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.countColor and group.countColor.a then
			a = group.countColor.a
		elseif group and group.color and group.color.a then
			a = group.color.a  -- Inherit from group color
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = a
	info.hasOpacity = true  -- Fix #34: Enable alpha slider
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		local newA = ColorPickerFrame:GetColorAlpha() or 1
		
		colorSwatch:SetColorTexture(newR, newG, newB, newA)
		
		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = {r = newR, g = newG, b = newB, a = newA}
		DB:Set("groupCountColors", groupCountColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.countColor = {r = newR, g = newG, b = newB, a = newA}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	info.opacityFunc = info.swatchFunc  -- Fix #34: Update on alpha slider change
	info.cancelFunc = function(previousValues)
		local prevA = previousValues.a or 1
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b, prevA)
		
		local groupCountColors = DB:Get("groupCountColors") or {}
		groupCountColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
		DB:Set("groupCountColors", groupCountColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.countColor = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
		-- Force update the color RGB again to ensure internal wheel state is synced
		-- This fixes an issue in some WoW versions where the picker remembers previous drag position
		if ColorPickerFrame.SetColorRGB then
			ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		end
	else
		ColorPickerFrame.func = info.swatchFunc
		ColorPickerFrame.cancelFunc = info.cancelFunc
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.hasOpacity = info.hasOpacity
		ColorPickerFrame.opacity = info.opacity
		ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		ColorPickerFrame:Show()
	end
end

function Settings:ShowGroupArrowColorPicker(groupId, groupName, colorSwatch, isReset)
	local DB = GetDB()
	if not DB then return end
	
	-- Handle Reset (Right Click) - Snapshot Group Color (Fix #34: includes alpha)
	if isReset then
		local Groups = GetGroups()
		local group = Groups and Groups:Get(groupId)
		local r, g, b, a = 1, 1, 1, 1
		if group and group.color then
			r, g, b = group.color.r, group.color.g, group.color.b
			a = group.color.a or 1
		end

		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = {r = r, g = g, b = b, a = a}
		DB:Set("groupArrowColors", groupArrowColors)
		
		if group then
			group.arrowColor = {r = r, g = g, b = b, a = a}
		end
		
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
	
	-- Robust Cleanup
	ColorPickerFrame:Hide()
	ColorPickerFrame.func = nil
	ColorPickerFrame.opacityFunc = nil
	ColorPickerFrame.cancelFunc = nil
	
	-- Fix #34: Get existing alpha value for arrow color
	local a = 1.0
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.arrowColor and group.arrowColor.a then
			a = group.arrowColor.a
		elseif group and group.color and group.color.a then
			a = group.color.a  -- Inherit from group color
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = a
	info.hasOpacity = true  -- Fix #34: Enable alpha slider
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		local newA = ColorPickerFrame:GetColorAlpha() or 1
		
		colorSwatch:SetColorTexture(newR, newG, newB, newA)
		
		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = {r = newR, g = newG, b = newB, a = newA}
		DB:Set("groupArrowColors", groupArrowColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.arrowColor = {r = newR, g = newG, b = newB, a = newA}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	info.opacityFunc = info.swatchFunc  -- Fix #34: Update on alpha slider change
	info.cancelFunc = function(previousValues)
		local prevA = previousValues.a or 1
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b, prevA)
		
		local groupArrowColors = DB:Get("groupArrowColors") or {}
		groupArrowColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
		DB:Set("groupArrowColors", groupArrowColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.arrowColor = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
			end
		end
		
		BFL:ForceRefreshFriendsList()
	end
	
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
		-- Fix for sticky color wheel state
		if ColorPickerFrame.SetColorRGB then
			ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		end
	else
		ColorPickerFrame.func = info.swatchFunc
		ColorPickerFrame.cancelFunc = info.cancelFunc
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.hasOpacity = info.hasOpacity
		ColorPickerFrame.opacity = info.opacity
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
	
	-- Robust Cleanup
	ColorPickerFrame:Hide()
	ColorPickerFrame.func = nil
	ColorPickerFrame.opacityFunc = nil
	ColorPickerFrame.cancelFunc = nil
	
	-- Fix #34: Get existing alpha value
	local a = 1.0
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color and group.color.a then
			a = group.color.a
		end
	end
	
	local info = {}
	info.r = r
	info.g = g
	info.b = b
	info.opacity = a
	info.hasOpacity = true  -- Fix #34: Enable alpha slider
	info.swatchFunc = function()
		local newR, newG, newB = ColorPickerFrame:GetColorRGB()
		local newA = ColorPickerFrame:GetColorAlpha() or 1
		
		colorSwatch:SetColorTexture(newR, newG, newB, newA)
		
		local groupColors = DB:Get("groupColors") or {}
		groupColors[groupId] = {r = newR, g = newG, b = newB, a = newA}
		DB:Set("groupColors", groupColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.color = {r = newR, g = newG, b = newB, a = newA}
			end
		end
		
		-- Force full display refresh for immediate color update
		BFL:ForceRefreshFriendsList()
		
		-- Refresh Settings UI to update inherited swatches
		if self.RefreshGroupsTab then self:RefreshGroupsTab() end
	end
	info.opacityFunc = info.swatchFunc  -- Fix #34: Update on alpha slider change
	info.cancelFunc = function(previousValues)
		local prevA = previousValues.a or 1
		colorSwatch:SetColorTexture(previousValues.r, previousValues.g, previousValues.b, prevA)
		
		local groupColors = DB:Get("groupColors") or {}
		groupColors[groupId] = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
		DB:Set("groupColors", groupColors)
		
		local Groups = GetGroups()
		if Groups then
			local group = Groups:Get(groupId)
			if group then
				group.color = {r = previousValues.r, g = previousValues.g, b = previousValues.b, a = prevA}
			end
		end
		
		-- Force full display refresh for immediate color update
		BFL:ForceRefreshFriendsList()
		
		-- Refresh Settings UI to update inherited swatches
		if self.RefreshGroupsTab then self:RefreshGroupsTab() end
	end
	
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
		-- Fix for sticky color wheel state
		if ColorPickerFrame.SetColorRGB then
			ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		end
	else
		ColorPickerFrame.func = info.swatchFunc
		ColorPickerFrame.cancelFunc = info.cancelFunc
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.hasOpacity = info.hasOpacity
		ColorPickerFrame.opacity = info.opacity
		ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
		ColorPickerFrame:Show()
	end
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
	-- Use the centralized rename dialog from Dialogs.lua which has full validation support.
	-- Pass groupId as data (4th arg) so OnShow/OnAccept can use it.
	StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, groupId)
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
	
	-- Deep copy the DB to ensure we capture EVERYTHING
	-- This fulfills the requirement to export future settings automatically
	local DB = GetDB()
	local exportData = DB:InternalDeepCopy(BetterFriendlistDB)
	
	-- Tag with export version 3 (Base64 + Full DB)
	exportData.exportVersion = 3
	
	-- Serialize to string using manual encoding
	local serialized = self:SerializeTable(exportData)
	
	if not serialized then
		return nil, L.ERROR_EXPORT_SERIALIZE
	end
	
	-- Encode to Base64 (using BFL3: prefix)
	-- Used C_EncodingUtil.EncodeBase64 if available as requested
	local encoded = self:EncodeString(serialized)
	
	return encoded, nil
end

-- Import settings from string
function Settings:ImportSettings(importString)
	if not importString or importString == "" then
		return false, L.ERROR_IMPORT_EMPTY
	end
	
	-- Decode
	local decoded, version = self:DecodeString(importString)
	if not decoded then
		return false, L.ERROR_IMPORT_DECODE
	end
	
	-- Deserialize
	local importData = self:DeserializeTable(decoded)
	if not importData then
		return false, L.ERROR_IMPORT_DESERIALIZE
	end
	
	-- IMPORT DATA
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		return false, L.ERROR_MODULES_NOT_LOADED
	end
	
	-- Handle V3 (Everything)
	if importData.exportVersion and importData.exportVersion >= 3 then
		BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Importing V3 (Full) backup...")
		
		-- Import ALL keys from the export
		for key, value in pairs(importData) do
			-- Skip metadata
			if key ~= "exportVersion" and key ~= "version" then
				BetterFriendlistDB[key] = value
			end
		end
		
		-- Explicitly handle version to prevent mismatches
		-- We keep the current addon version in DB, not the one from export, 
		-- to trigger migration logic if needed on next reload
		BetterFriendlistDB.version = BFL.VERSION
	else
		-- Legacy V1/V2 Import Logic
		BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Importing V1/V2 (Legacy) backup...")
		
		-- Validate structure (Relaxed for V1/V2 as they might miss some keys but must have core ones)
		if not importData.customGroups or not importData.friendGroups then
			return false, L.ERROR_EXPORT_STRUCTURE
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
		if importData.version and importData.version >= 2 then
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
	end
	
	-- Reload Groups module (this will apply imported colors)
	Groups:Initialize()

	-- Invalidate caches after direct DB writes
	if BFL.SettingsVersion then
		BFL.SettingsVersion = BFL.SettingsVersion + 1
	end
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		if FriendsList.InvalidateSettingsCache then
			FriendsList:InvalidateSettingsCache()
		end
		FriendsList.lastBuildInputs = nil
	end
	
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
	
	-- Security: Validate that the string only contains safe table-literal characters
	-- Allowed: braces, brackets, quotes, commas, equals, alphanumerics, whitespace, dots, minus, underscores
	-- This prevents arbitrary Lua code execution from user-provided import strings
	if string.find(str, "[^%w%s{}%[%]\"',=%.%-_]") then
		BFL:DebugPrint("DeserializeTable: Rejected input - contains unsafe characters")
		return nil
	end
	
	-- Additional safety: reject strings containing function calls or known dangerous patterns
	if string.find(str, "%w+%s*%(") then
		BFL:DebugPrint("DeserializeTable: Rejected input - contains function call pattern")
		return nil
	end
	
	local func, err = loadstring("return " .. str)
	if not func then
		return nil
	end
	
	-- Execute in protected call to catch runtime errors
	local success, result = pcall(func)
	if not success then
		return nil
	end
	
	return result
end

-- Encode string to base64 or hex format
function Settings:EncodeString(str)
	-- V3: Use Base64 (C_EncodingUtil or fallback)
	-- This is much more efficient than hex string
	-- and fulfills the requirement to use C_EncodingUtil
	local encoded = BFL:Base64Encode(str)
	if encoded then
		return "BFL3:" .. encoded
	end
	
	-- Fallback to Hex (Legacy V1/V2 style) if Base64 fails
	local hexParts = {}
	for i = 1, #str do
		table.insert(hexParts, string.format("%02x", string.byte(str, i)))
	end
	return "BFL1:" .. table.concat(hexParts) 
end

-- Decode format back to string
function Settings:DecodeString(encoded)
	if not encoded then return nil end
	
	-- V3: Base64
	if string.match(encoded, "^BFL3:") then
		local b64 = string.sub(encoded, 6)
		local decoded = BFL:Base64Decode(b64)
		return decoded, 3
	end
	
	-- V1/V2: Hex
	if string.match(encoded, "^BFL1:") then
		local hex = string.sub(encoded, 6)
		local chars = {}
		for i = 1, #hex, 2 do
			local byte = tonumber(string.sub(hex, i, i+1), 16)
			if not byte then
				return nil
			end
			table.insert(chars, string.char(byte))
		end
		return table.concat(chars), 1
	end
	
	-- Try raw base64 (if user copied without prefix?)
	local tryB64 = BFL:Base64Decode(encoded)
	if tryB64 then
		return tryB64, 3
	end
	
	return nil
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
	self.exportFrame:Show()
	self.exportFrame.scrollFrame.editBox:SetText(exportString)
	self.exportFrame.scrollFrame.editBox:HighlightText()
	self.exportFrame.scrollFrame.editBox:SetFocus()
	
	BFL:DebugPrint("Export complete! Copy the text from the dialog.")
end

-- Show import dialog
function Settings:ShowImportDialog()
	-- Create or reuse import frame
	if not self.importFrame then
		self:CreateImportFrame()
	end
	
	-- Clear and show
	self.importFrame:Show()
	self.importFrame.scrollFrame.editBox:SetText("")
	self.importFrame.scrollFrame.editBox:SetFocus()
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
	editBox:SetScript("OnKeyUp", function(self, key)
		if IsControlKeyDown() and key == "C" then
			frame:Hide()
		end
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
	
	-- Collapse all groups to ensure clean state (Requested by User)
	local Groups = BFL:GetModule("Groups")
	if Groups then
		local allGroups = Groups:GetAll()
		for groupId, _ in pairs(allGroups) do
			Groups:SetCollapsed(groupId, true, true)
		end
	end
	
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
	
	-- Row 1: Class Colors & Faction Icons
	local row1 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_COLOR_CLASS_NAMES,
			initialValue = DB:Get("colorClassNames", true),
			callback = function(val) self:OnColorClassNamesChanged(val) end,
			tooltipTitle = L.SETTINGS_COLOR_CLASS_NAMES,
			tooltipDesc = L.SETTINGS_COLOR_CLASS_NAMES_DESC or "Colors character names using their class color for easier identification"
		},
		{ -- Right
			label = L.SETTINGS_SHOW_FACTION_ICONS,
			initialValue = DB:Get("showFactionIcons", false),
			callback = function(val) self:OnShowFactionIconsChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_FACTION_ICONS,
			tooltipDesc = L.SETTINGS_SHOW_FACTION_ICONS_DESC or "Display Alliance/Horde icons next to character names"
		}
	)
	table.insert(allFrames, row1)

	-- Row 2: Faction BG & Gray Other Faction
	local row2 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_SHOW_FACTION_BG,
			initialValue = DB:Get("showFactionBg", false),
			callback = function(val) DB:Set("showFactionBg", val); BFL:ForceRefreshFriendsList() end,
			tooltipTitle = L.SETTINGS_SHOW_FACTION_BG,
			tooltipDesc = L.SETTINGS_SHOW_FACTION_BG_DESC or "Show faction color as background for friend buttons."
		},
		{ -- Right
			label = L.SETTINGS_GRAY_OTHER_FACTION,
			initialValue = DB:Get("grayOtherFaction", false),
			callback = function(val) self:OnGrayOtherFactionChanged(val) end,
			tooltipTitle = L.SETTINGS_GRAY_OTHER_FACTION,
			tooltipDesc = L.SETTINGS_GRAY_OTHER_FACTION_DESC or "Make friends from the opposite faction appear grayed out"
		}
	)
	table.insert(allFrames, row2)

	-- Row 3: Realm Name & Hide Max Level
	local row3 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_SHOW_REALM_NAME,
			initialValue = DB:Get("showRealmName", true),
			callback = function(val) self:OnShowRealmNameChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_REALM_NAME,
			tooltipDesc = L.SETTINGS_SHOW_REALM_NAME_DESC or "Display the realm name for friends on different servers"
		},
		{ -- Right
			label = L.SETTINGS_HIDE_MAX_LEVEL,
			initialValue = DB:Get("hideMaxLevel", false),
			callback = function(val) self:OnHideMaxLevelChanged(val) end,
			tooltipTitle = L.SETTINGS_HIDE_MAX_LEVEL,
			tooltipDesc = L.SETTINGS_HIDE_MAX_LEVEL_DESC or "Don't display level number for characters at max level"
		}
	)
	table.insert(allFrames, row3)

	-- Row 4: Mobile Settings
	local row4 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_SHOW_MOBILE_AS_AFK,
			initialValue = DB:Get("showMobileAsAFK", false),
			callback = function(val) self:OnShowMobileAsAFKChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_MOBILE_AS_AFK,
			tooltipDesc = L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC or "Display AFK status icon for friends on mobile (BSAp only)"
		},
		{ -- Right
			label = L.SETTINGS_TREAT_MOBILE_OFFLINE or "Treat Mobile users as Offline",
			initialValue = DB:Get("treatMobileAsOffline", false),
			callback = function(val) self:OnTreatMobileAsOfflineChanged(val) end,
			tooltipTitle = L.SETTINGS_TREAT_MOBILE_OFFLINE or "Treat Mobile as Offline",
			tooltipDesc = L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC or "Display friends using the Mobile App in the Offline group"
		}
	)
	table.insert(allFrames, row4)

	-- Row 5: Welcome Message & Hide Empty
	local row5 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_SHOW_WELCOME_MESSAGE,
			initialValue = DB:Get("showWelcomeMessage", true),
			callback = function(val) DB:Set("showWelcomeMessage", val) end,
			tooltipTitle = L.SETTINGS_SHOW_WELCOME_MESSAGE,
			tooltipDesc = L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC or "Shows the 'BetterFriendlist loaded...' message in chat when you log in or reload."
		},
		{ -- Right
			label = L.SETTINGS_HIDE_EMPTY_GROUPS,
			initialValue = DB:Get("hideEmptyGroups", false),
			callback = function(val) self:OnHideEmptyGroupsChanged(val) end,
			tooltipTitle = L.SETTINGS_HIDE_EMPTY_GROUPS,
			tooltipDesc = L.SETTINGS_HIDE_EMPTY_GROUPS_DESC or "Automatically hides groups that have no online members"
		}
	)
	table.insert(allFrames, row5)

	-- Row 6: Favorite Icon + Favorite Icon Dropdown (conditional)
	local favoriteIconEnabled = DB:Get("enableFavoriteIcon", true)
	local blizzardIconTag = "|A:friendslist-favorite:20:20|a"
	if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("friendslist-favorite")) then
		blizzardIconTag = "|TInterface\\AddOns\\BetterFriendlist\\Icons\\star:20:20|t"
	end

	local favoriteEntries = {
		labels = {
			"|TInterface\\AddOns\\BetterFriendlist\\Icons\\star:17:17|t " .. (L.SETTINGS_FAVORITE_ICON_OPTION_BFL or "BFL Icon"),
			blizzardIconTag .. " " .. (L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD or "Blizzard Icon")
		},
		values = {"bfl", "blizzard"}
	}

	local favoriteDropdownData = nil
	if favoriteIconEnabled then
		favoriteDropdownData = {
			label = L.SETTINGS_FAVORITE_ICON_STYLE or "Favorite Icon",
			entries = favoriteEntries,
			isSelectedCallback = function(value)
				return DB:Get("favoriteIconStyle", "bfl") == value
			end,
			onSelectionCallback = function(value)
				DB:Set("favoriteIconStyle", value)
				BFL:ForceRefreshFriendsList()
			end,
			tooltipTitle = L.SETTINGS_FAVORITE_ICON_STYLE or "Favorite Icon",
			tooltipDesc = L.SETTINGS_FAVORITE_ICON_STYLE_DESC or "Choose which icon is used for favorites."
		}
	end

	local row6 = Components:CreateCheckboxDropdown(tab,
		{
			label = L.SETTINGS_ENABLE_FAVORITE_ICON,
			initialValue = favoriteIconEnabled,
			callback = function(val)
				DB:Set("enableFavoriteIcon", val)
				BFL:ForceRefreshFriendsList()
				self:RefreshGeneralTab()
			end,
			tooltipTitle = L.SETTINGS_ENABLE_FAVORITE_ICON,
			tooltipDesc = L.SETTINGS_ENABLE_FAVORITE_ICON_DESC or "Display a star icon on the friend button for favorites."
		},
		favoriteDropdownData
	)
	table.insert(allFrames, row6)

	-- Row 7: Blizzard Option (Single or with ElvUI)
	local elvData = nil
	if _G.ElvUI then
		elvData = {
			label = L.SETTINGS_ENABLE_ELVUI_SKIN or "Enable ElvUI Skin",
			initialValue = DB:Get("enableElvUISkin", false),
			callback = function(val)
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
			end,
			tooltipTitle = L.SETTINGS_ENABLE_ELVUI_SKIN or "Enable ElvUI Skin",
			tooltipDesc = L.SETTINGS_ENABLE_ELVUI_SKIN_DESC or "Enables the ElvUI skin for BetterFriendlist. Requires ElvUI to be installed and enabled."
		}
	end
	
	local row7 = Components:CreateDoubleCheckbox(tab,
		{ -- Left
			label = L.SETTINGS_SHOW_BLIZZARD,
			initialValue = DB:Get("showBlizzardOption", false),
			callback = function(val) self:OnShowBlizzardOptionChanged(val) end,
			tooltipTitle = L.SETTINGS_SHOW_BLIZZARD,
			tooltipDesc = L.SETTINGS_SHOW_BLIZZARD_DESC or "Shows the original Blizzard Friends button in the social menu"
		},
		elvData -- Right (nil if no ElvUI)
	)
	table.insert(allFrames, row7)

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
	
	-- MODIFIED: Show warning text if FriendListColors is active, otherwise show instructions
	if _G.FriendListColorsAPI then
		nameFormatDesc:SetText("|cffFF3333" .. (L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS or "This setting is disabled because the addon 'FriendListColors' is managing name colors/formats.") .. "|r")
	else
		nameFormatDesc:SetTextColor(1, 1, 1)
		nameFormatDesc:SetText(L.SETTINGS_NAME_FORMAT_DESC or "Customize how friend names are displayed using tokens:\n|cffFFD100%name%|r - Account Name (RealID/BattleTag)\n|cffFFD100%note%|r - Note (BNet or WoW)\n|cffFFD100%nickname%|r - Custom Nickname\n|cffFFD100%battletag%|r - Short BattleTag (no #1234)")
	end
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
		
		if _G.FriendListColorsAPI then
			GameTooltip:SetText(L.SETTINGS_NAME_FORMAT_TOOLTIP or "Name Display Format", 0.5, 0.5, 0.5)
			GameTooltip:AddLine(L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS or "This setting is disabled because the addon 'FriendListColors' is managing name colors/formats.", 1, 0.2, 0.2, true)
		else
			GameTooltip:SetText(L.SETTINGS_NAME_FORMAT_TOOLTIP or "Name Display Format", 1, 1, 1)
			GameTooltip:AddLine(L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC or "Enter a format string using tokens.", 0.8, 0.8, 0.8, true)
			GameTooltip:AddLine("Example: %name% (%nickname%)", 0.8, 0.8, 0.8, true)
		end
		
		GameTooltip:Show()
	end)
	nameFormatBox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Disable Name Formatting if FriendListColors is active
	if _G.FriendListColorsAPI then
		nameFormatBox:Disable()
		nameFormatBox:SetTextColor(0.5, 0.5, 0.5)
		if nameFormatLabel then nameFormatLabel:SetTextColor(0.5, 0.5, 0.5) end
		-- Description text is handled above (shown in red)
	end

	table.insert(allFrames, nameFormatContainer)
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Behavior
	local behaviorHeader = Components:CreateHeader(tab, L.SETTINGS_BEHAVIOR_HEADER or "Behavior")
	table.insert(allFrames, behaviorHeader)
	
    -- Behavior Settings Row 1 (Accordion / Compact)
    local behaviorRow1 = Components:CreateDoubleCheckbox(tab,
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
    )
    table.insert(allFrames, behaviorRow1)

    -- Behavior Settings Row 2 (UI Panel / Simple Mode)
    local behaviorRow2 = Components:CreateDoubleCheckbox(tab,
        {
            label = L.SETTINGS_USE_UI_PANEL_SYSTEM or "Use UI Panel System",
            initialValue = DB:Get("useUIPanelSystem", false),
            callback = function(val) self:OnUseUIPanelSystemChanged(val) end,
            tooltipTitle = L.SETTINGS_USE_UI_PANEL_SYSTEM or "Use UI Panel System",
            tooltipDesc = L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC or "Use Blizzard's UI Panel system for automatic repositioning when other windows are open (Character, Spellbook, etc.)"
        },
        {
            label = L.SETTINGS_SIMPLE_MODE or "Simple Mode",
            initialValue = DB:Get("simpleMode", false),
            callback = function(val) self:OnSimpleModeChanged(val) end,
            tooltipTitle = L.SETTINGS_SIMPLE_MODE or "Simple Mode",
            tooltipDesc = L.SETTINGS_SIMPLE_MODE_DESC or "Hides the player portrait and adds a changelog option to the contacts menu."
        }
    )
    table.insert(allFrames, behaviorRow2)

    -- Behavior Settings Row 3 (Classic Only)
	if BFL.IsClassic then
		local behaviorRow3 = Components:CreateDoubleCheckbox(tab,
			{
				label = L.SETTINGS_HIDE_GUILD_TAB or "Hide Guild Tab",
				initialValue = DB:Get("hideGuildTab", false),
				callback = function(val) self:OnHideGuildTabChanged(val) end,
				tooltipTitle = L.SETTINGS_HIDE_GUILD_TAB or "Hide Guild Tab",
				tooltipDesc = L.SETTINGS_HIDE_GUILD_TAB_DESC or "Hide the Guild tab from the friends list (requires UI reload)"
			},
			{
				label = L.SETTINGS_CLOSE_ON_GUILD_TAB or "Close BetterFriendlist when opening Guild",
				initialValue = DB:Get("closeOnGuildTabClick", false),
				callback = function(val) self:OnCloseOnGuildTabClickChanged(val) end,
				tooltipTitle = L.SETTINGS_CLOSE_ON_GUILD_TAB or "Close on Guild Tab",
				tooltipDesc = L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC or "Automatically close BetterFriendlist when you click the Guild tab"
			}
		)
		table.insert(allFrames, behaviorRow3)
	end
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- Header: Group Management
	local groupHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_MANAGEMENT or "Group Management")
	table.insert(allFrames, groupHeader)

	-- Group Management Row (Favorites / In-Game)
	local Groups = GetGroups()
	local showGroupFmt = L.SETTINGS_SHOW_GROUP_FMT or "Show %s Group"
	local showGroupDescFmt = L.SETTINGS_SHOW_GROUP_DESC_FMT or "Toggle visibility of the %s group in your friends list"
	local function BuildBuiltinDisplayName(groupId, fallbackName)
		local groupName = (Groups and Groups:Get(groupId) and Groups:Get(groupId).name) or fallbackName
		local defaultName = fallbackName
		if groupName and defaultName and groupName ~= defaultName then
			return string.format("%s (%s)", groupName, defaultName)
		end
		return groupName or defaultName
	end
	local favoritesDisplayName = BuildBuiltinDisplayName("favorites", L.GROUP_FAVORITES or "Favorites")
	local inGameDisplayName = BuildBuiltinDisplayName("ingame", L.GROUP_INGAME or "In-Game")
	local favoritesLabel = string.format(showGroupFmt, favoritesDisplayName)
	local inGameLabel = string.format(showGroupFmt, inGameDisplayName)

	local groupRow = Components:CreateDoubleCheckbox(tab,
		{
			label = favoritesLabel,
			initialValue = DB:Get("showFavoritesGroup", true),
			callback = function(val) self:OnShowFavoritesGroupChanged(val) end,
			tooltipTitle = favoritesLabel,
			tooltipDesc = string.format(showGroupDescFmt, favoritesDisplayName)
		},
		{
			label = inGameLabel,
			initialValue = DB:Get("enableInGameGroup", false),
			callback = function(val) self:OnEnableInGameGroupChanged(val) end,
			tooltipTitle = inGameLabel,
			tooltipDesc = string.format(showGroupDescFmt, inGameDisplayName)
		}
	)
    table.insert(allFrames, groupRow)

	-- NEW: In-Game Group Mode (Sub-option) - Keep as dedicated row since it's a dropdown
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
			function(val) return val == DB:Get("inGameGroupMode", "same_game") end,
			function(val) self:OnInGameGroupModeChanged(val) end
		)
		modeDropdown:SetTooltip(L.SETTINGS_INGAME_MODE_TOOLTIP or "In-Game Group Mode", L.SETTINGS_INGAME_MODE_TOOLTIP_DESC or "Choose which friends to include in the In-Game group:\n\n|cffffffffWoW Only:|r Friends playing the same WoW version (Retail/Classic)\n|cffffffffAny Game:|r Friends playing any Battle.net game")
		table.insert(allFrames, modeDropdown)
	end
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Frame Dimensions
	local frameHeader = Components:CreateHeader(tab, L.SETTINGS_FRAME_DIMENSIONS_HEADER or "Frame Dimensions")
	table.insert(allFrames, frameHeader)

	-- Helper for input validation
	local function ValidateAndApply(val, min, max, applyFunc, editBox, isFloat)
		local num = tonumber(val)
		if num then
			-- Clamp
			if num < min then num = min end
			if num > max then num = max end
			
			if not isFloat then 
				num = math.floor(num + 0.5) 
			end
			
			applyFunc(num)
			
			if editBox then 
				editBox:SetText(tostring(num)) 
			end
		end
	end

	-- Frame Width Input
	local width = 415
	local dbSize = DB:Get("mainFrameSize")
	if dbSize and dbSize["Default"] and dbSize["Default"].width then
		width = dbSize["Default"].width
	end

	local widthInput = Components:CreateInput(
		tab,
		(L.SETTINGS_FRAME_WIDTH or "Width:") .. " (380-800)",
		tostring(width), -- Current Value
		function(val, editBox)
			ValidateAndApply(val, 380, 800, function(v)
				local FrameSettings = BFL:GetModule("FrameSettings")
				if FrameSettings then
					FrameSettings:ApplySize(v, nil)
					BFL:ForceRefreshFriendsList()
				end
			end, editBox, false)
		end
	)
	table.insert(allFrames, widthInput)

	-- Frame Height Input
	local height = 570
	if dbSize and dbSize["Default"] and dbSize["Default"].height then
		height = dbSize["Default"].height
	end

	local heightInput = Components:CreateInput(
		tab,
		(L.SETTINGS_FRAME_HEIGHT or "Height:") .. " (400-1200)",
		tostring(height), -- Current Value
		function(val, editBox)
			ValidateAndApply(val, 400, 1200, function(v)
				local FrameSettings = BFL:GetModule("FrameSettings")
				if FrameSettings then
					FrameSettings:ApplySize(nil, v)
					BFL:ForceRefreshFriendsList()
				end
			end, editBox, false)
		end
	)
	table.insert(allFrames, heightInput)

	-- Frame Scale Input
	local scaleInput = Components:CreateInput(
		tab,
		(L.SETTINGS_FRAME_SCALE or "Scale:") .. " (0.5-2.0)",
		tostring(DB:Get("windowScale", 1.0)), -- Current Value
		function(val, editBox)
			ValidateAndApply(val, 0.5, 2.0, function(v)
				local FrameSettings = BFL:GetModule("FrameSettings")
				if FrameSettings then
					FrameSettings:ApplyScale(v)
					-- Scale touches everything, might need layout update
					BFL:ForceRefreshFriendsList() 
				end
			end, editBox, true)
		end
	)
	table.insert(allFrames, scaleInput)
	
	-- Lock Window Checkbox
	local lockCheckbox = Components:CreateCheckbox(
		tab,
		L.SETTINGS_LOCK_WINDOW or "Lock Window",
		DB:Get("lockWindow", false),
		function(checked)
			local FrameSettings = BFL:GetModule("FrameSettings")
			if FrameSettings then
				FrameSettings:ApplyLock(checked)
			end
		end
	)
	lockCheckbox:SetTooltip(L.SETTINGS_LOCK_WINDOW or "Lock Window", L.SETTINGS_LOCK_WINDOW_DESC or "Prevent the main window from being moved.")
	table.insert(allFrames, lockCheckbox)
	
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
	local fontPaths = {}
	for i, fontName in ipairs(fontList) do
		fontPaths[i] = LSM:Fetch("font", fontName)
	end
	local fontOptions = { labels = fontList, values = fontList, fontPaths = fontPaths, useCheckboxes = true }
	
	-- -------------------------------------------------------------------------
	-- Friend Name Settings
	-- -------------------------------------------------------------------------
	local nameFontHeader = Components:CreateHeader(tab, L.SETTINGS_FRIEND_NAME_SETTINGS or "Friend Name Settings")
	table.insert(allFrames, nameFontHeader)

	-- Name Font Face
	local currentNameFont = DB:Get("fontFriendName", "Friz Quadrata TT")
	local currentNameSize = DB:Get("fontSizeFriendName", 12)
	local currentNameColor = DB:Get("fontColorFriendName", {r=1, g=1, b=1, a=1})
	local nameFontDropdown
	nameFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:",  -- Use generic label as per request to move code
		fontOptions, 
		function(val) return val == currentNameFont end,
		function(val) 
			DB:Set("fontFriendName", val)
			currentNameFont = val
			if nameFontDropdown.DropDown then
				if nameFontDropdown.DropDown.SetText then
					nameFontDropdown.DropDown:SetText(val)
				elseif UIDropDownMenu_SetText then
					UIDropDownMenu_SetText(nameFontDropdown.DropDown, val)
				end
			end
			-- Defer update to next frame to ensure resource availability
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
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
			-- Fix #35/#40: Invalidate settings cache to update dynamic row heights
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:InvalidateSettingsCache()
			end
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
	local infoFontDropdown
	infoFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:",  -- Changed from "Font Face:" (User Request)
		fontOptions, 
		function(val) return val == currentInfoFont end,
		function(val) 
			DB:Set("fontFriendInfo", val)
			currentInfoFont = val
			if infoFontDropdown.DropDown then
				if infoFontDropdown.DropDown.SetText then
					infoFontDropdown.DropDown:SetText(val)
				elseif UIDropDownMenu_SetText then
					UIDropDownMenu_SetText(infoFontDropdown.DropDown, val)
				end
			end
			-- Defer update to next frame
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
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
			-- Fix #35/#40: Invalidate settings cache to update dynamic row heights
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:InvalidateSettingsCache()
			end
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



	-- -------------------------------------------------------------------------
	-- Tabs Text Settings
	-- -------------------------------------------------------------------------
	table.insert(allFrames, Components:CreateSpacer(tab))
	local tabsFontHeader = Components:CreateHeader(tab, L.SETTINGS_FONT_TABS_TITLE or "Tabs Text")
	table.insert(allFrames, tabsFontHeader)
	
	-- Determine defaults
	local _, defaultTabSize = _G.GameFontNormalSmall:GetFont()

	-- Tabs Font Face
	local currentTabFont = DB:Get("fontTabText", "Friz Quadrata TT")
	local currentTabSize = DB:Get("fontSizeTabText", defaultTabSize)
	local tabFontDropdown
	tabFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:", 
		fontOptions, 
		function(val) return val == currentTabFont end,
		function(val) 
			DB:Set("fontTabText", val)
			currentTabFont = val
			if tabFontDropdown.DropDown then
				if tabFontDropdown.DropDown.SetText then
					tabFontDropdown.DropDown:SetText(val)
				elseif UIDropDownMenu_SetText then
					UIDropDownMenu_SetText(tabFontDropdown.DropDown, val)
				end
			end
			C_Timer.After(0.01, function()
				BFL:ApplyTabFonts() -- Immediate Apply
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	if tabFontDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = tabFontDropdown.DropDown:GetPoint(1)
		if point then
			tabFontDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, tabFontDropdown)

	-- Tabs Font Size
	local tabSizeSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_FONT_SIZE_NUM or "Font Size:",
		8, 24, -- Fix #40: Proportional tab scaling handles overflow
		currentTabSize,
		function(val) return tostring(val) end,
		function(val)
			DB:Set("fontSizeTabText", val)
			C_Timer.After(0.01, function()
				BFL:ApplyTabFonts() -- Immediate Apply
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, tabSizeSlider)



	-- -------------------------------------------------------------------------
	-- Raid Name Settings
	-- -------------------------------------------------------------------------
	table.insert(allFrames, Components:CreateSpacer(tab))
	local raidFontHeader = Components:CreateHeader(tab, L.SETTINGS_FONT_RAID_TITLE or "Raid Name Text")
	table.insert(allFrames, raidFontHeader)

	-- Determine defaults for Raid (consistent with Tabs)
	local _, raidSizeDefault = _G.GameFontNormalSmall:GetFont()
	local defaultRaidSize = raidSizeDefault or 10

	-- Raid Font Face
	local currentRaidFont = DB:Get("fontRaidName", "Friz Quadrata TT")
	local currentRaidSize = DB:Get("fontSizeRaidName", defaultRaidSize)
	local raidFontDropdown
	raidFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:", 
		fontOptions, 
		function(val) return val == currentRaidFont end,
		function(val) 
			DB:Set("fontRaidName", val)
			currentRaidFont = val
			if raidFontDropdown.DropDown then
				if raidFontDropdown.DropDown.SetText then
					raidFontDropdown.DropDown:SetText(val)
				elseif UIDropDownMenu_SetText then
					UIDropDownMenu_SetText(raidFontDropdown.DropDown, val)
				end
			end
			C_Timer.After(0.01, function()
				local RaidFrame = BFL:GetModule("RaidFrame")
				if RaidFrame and RaidFrame.UpdateAllMemberButtons then
					RaidFrame:UpdateAllMemberButtons()
				end
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	if raidFontDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = raidFontDropdown.DropDown:GetPoint(1)
		if point then
			raidFontDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	table.insert(allFrames, raidFontDropdown)

	-- Raid Font Size
	local raidSizeSlider = Components:CreateSlider(
		tab,
		L.SETTINGS_FONT_SIZE_NUM or "Font Size:",
		8, 24,
		currentRaidSize,
		function(val) return tostring(val) end,
		function(val)
			DB:Set("fontSizeRaidName", val)
			C_Timer.After(0.01, function()
				local RaidFrame = BFL:GetModule("RaidFrame")
				if RaidFrame and RaidFrame.UpdateAllMemberButtons then
					RaidFrame:UpdateAllMemberButtons()
				end
				BFL:ForceRefreshFriendsList()
			end)
		end
	)
	table.insert(allFrames, raidSizeSlider)


	
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
	
	-- Clear existing content using GetChildren for robustness against reference leaks
	local children = {tab:GetChildren()}
	for _, child in ipairs(children) do
		if child.Hide then child:Hide() end
	end
	-- Legacy compatibility (keep table clear)
	tab.components = {}
	
	local allFrames = {}

	-- Common Font Options
	local LSM = LibStub("LibSharedMedia-3.0")
	local fontList = LSM:List("font")
	local fontPaths = {}
	for i, fontName in ipairs(fontList) do
		fontPaths[i] = LSM:Fetch("font", fontName)
	end
	local fontOptions = { labels = fontList, values = fontList, fontPaths = fontPaths, useCheckboxes = true }
	
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
			-- Force full rebuild of display list to ensure arrows update
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:InvalidateSettingsCache()
			end
			BFL:ForceRefreshFriendsList()
			self:RefreshGroupsTab()
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
	local groupFontDropdown
	groupFontDropdown = Components:CreateDropdown(
		tab, 
		"Font:", 
		fontOptions, 
		function(val) return val == currentGroupFont end,
		function(val) 
			DB:Set("fontGroupHeader", val)
			currentGroupFont = val
			if groupFontDropdown.DropDown then
				if groupFontDropdown.DropDown.SetText then
					groupFontDropdown.DropDown:SetText(val)
				elseif UIDropDownMenu_SetText then
					UIDropDownMenu_SetText(groupFontDropdown.DropDown, val)
				end
			end
			-- Defer update
			C_Timer.After(0.01, function()
				BFL:ForceRefreshFriendsList()
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
	

	
	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Group Order
	local orderHeader = Components:CreateHeader(tab, L.SETTINGS_GROUP_ORDER or "Group Order")
	table.insert(allFrames, orderHeader)
	
	-- Get ordered groups
	local Groups = BFL:GetModule("Groups")
	if not Groups then return end
	
	local function GetBuiltinDefaultName(groupId)
		if groupId == "favorites" then
			return L.GROUP_FAVORITES or "Favorites"
		end
		if groupId == "ingame" then
			return L.GROUP_INGAME or "In-Game"
		end
		if groupId == "nogroup" then
			return L.GROUP_NO_GROUP or "No Group"
		end
		return nil
	end
	
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
		if allGroups["favorites"] then
			table.insert(orderedGroups, {id = "favorites", name = allGroups["favorites"].name, order = 1, builtin = true})
		end
		
		local customGroups = {}
		for groupId, group in pairs(allGroups) do
			if groupId ~= "favorites" and groupId ~= "nogroup" then
				table.insert(customGroups, {id = groupId, name = group.name, builtin = group.builtin == true})
			end
		end
		table.sort(customGroups, function(a, b) return a.name < b.name end)
		
		for _, group in ipairs(customGroups) do
			table.insert(orderedGroups, {id = group.id, name = group.name, order = #orderedGroups + 1, builtin = false})
		end
		
		if allGroups["nogroup"] then
			table.insert(orderedGroups, {id = "nogroup", name = allGroups["nogroup"].name, order = #orderedGroups + 1, builtin = true})
		end
	end
	
	-- Create list items for each group
	local listItems = {}
	
	for i, groupData in ipairs(orderedGroups) do
		local isBuiltin = groupData.builtin
		local displayName = groupData.name
		if isBuiltin then
			local defaultName = GetBuiltinDefaultName(groupData.id)
			if defaultName and groupData.name and groupData.name ~= defaultName then
				displayName = string.format("%s (%s)", groupData.name, defaultName)
			end
		end
		
		local onDragStart = function(btn)
			
			-- Only update background highlights in OnUpdate to be efficient
			btn:SetScript("OnUpdate", function(self)
				for _, otherItem in ipairs(listItems) do
					if otherItem ~= self and otherItem:IsVisible() then
						if MouseIsOver(otherItem) then
							otherItem.bg:SetColorTexture(0.3, 0.3, 0.3, 0.7)
						else
							otherItem.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
						end
					end
				end
			end)
		end
		
		local onDragStop = function(btn)
			btn:SetScript("OnUpdate", nil)
			
			local targetIndex = nil
			
			for _, otherItem in ipairs(listItems) do
				otherItem.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5) -- Reset
				if otherItem ~= btn and otherItem:IsVisible() then
					if MouseIsOver(otherItem) then
						targetIndex = otherItem.orderIndex
					end
				end
			end
			
			if targetIndex and targetIndex ~= btn.orderIndex then
				-- Perform Move
				local itemToMove = table.remove(orderedGroups, btn.orderIndex)
				table.insert(orderedGroups, targetIndex, itemToMove)
				
				-- Save
				local newOrder = {}
				for _, g in ipairs(orderedGroups) do
					table.insert(newOrder, g.id)
				end
				DB:Set("groupOrder", newOrder)
				
				-- Refresh
				Groups:Initialize()
				self:RefreshGroupsTab()
				BFL:ForceRefreshFriendsList()
			end
		end
		
		local listItem = Components:CreateListItem(
			tab,
			displayName,
			i,
			onDragStart,
			onDragStop,
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
				count = Groups:Get(groupData.id) and Groups:Get(groupData.id).countColor,
				arrow = Groups:Get(groupData.id) and Groups:Get(groupData.id).arrowColor,
				countSet = Groups:Get(groupData.id) and Groups:Get(groupData.id).countColor,
				arrowSet = Groups:Get(groupData.id) and Groups:Get(groupData.id).arrowColor,
				fallback = {r=1, g=1, b=1}
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
		
		-- Update tooltips properties for new component structure
		if listItem.renameButton then
			listItem.renameButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_RENAME_GROUP, 1, 1, 1)
				GameTooltip:AddLine(L.TOOLTIP_RENAME_DESC, 1, 1, 1, true)
				GameTooltip:Show()
			end)
		end
		
		if listItem.colorButton then
			listItem.colorButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_GROUP_COLOR, 1, 0.82, 0)
				GameTooltip:AddLine(L.TOOLTIP_GROUP_COLOR_DESC, 1, 1, 1, true)
				GameTooltip:Show()
			end)
		end
		
		if listItem.deleteButton then
			listItem.deleteButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L.SETTINGS_DELETE_GROUP, 1, 1, 1)
				GameTooltip:AddLine(L.TOOLTIP_DELETE_DESC, 1, 1, 1, true)
				GameTooltip:Show()
			end)
		end
		
		table.insert(listItems, listItem)
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
	-- Only show if there are actual beta features
	local hasBetaFeatures = false
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		if tabDef.beta then
			hasBetaFeatures = true
			break
		end
	end
	
	if hasBetaFeatures then
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
	end
	
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
	
	-- Clear existing content using GetChildren for robustness against reference leaks
	local children = {tab:GetChildren()}
	for _, child in ipairs(children) do
		if child.Hide then child:Hide() end
	end
	-- Legacy compatibility (keep table clear)
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
			
			-- Refresh to update sub-options visibility
			self:RefreshBrokerTab()

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
	
	if DB:Get("brokerEnabled", true) then
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
	local listItems = {}
	
	for i, col in ipairs(orderedColumns) do
		local onDragStart = function(btn)
			btn:SetScript("OnUpdate", function(self)
				for _, otherItem in ipairs(listItems) do
					if otherItem ~= self and otherItem:IsVisible() then
						if MouseIsOver(otherItem) then
							otherItem.bg:SetColorTexture(0.3, 0.3, 0.3, 0.7)
						else
							otherItem.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
						end
					end
				end
			end)
		end
		
		local onDragStop = function(btn)
			btn:SetScript("OnUpdate", nil)
			
			local targetIndex = nil
			-- Reset all backgrounds
			for _, otherItem in ipairs(listItems) do
				otherItem.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
				if otherItem ~= btn and otherItem:IsVisible() then
					if MouseIsOver(otherItem) then
						targetIndex = otherItem.orderIndex
					end
				end
			end
			
			if targetIndex then
				if targetIndex ~= btn.orderIndex then
					-- Move
					local itemToMove = table.remove(orderedColumns, btn.orderIndex)
					table.insert(orderedColumns, targetIndex, itemToMove)
					
					-- Save
					local newOrder = {}
					for _, c in ipairs(orderedColumns) do
						table.insert(newOrder, c.key)
					end
					DB:Set("brokerColumnOrder", newOrder)
					self:RefreshBrokerTab()
				end
			end
		end

		-- Create a custom list item that includes a checkbox for visibility
		local listItem = Components:CreateListItem(
			tab,
			col.label,
			i,
			onDragStart,
			onDragStop,
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
		
		table.insert(listItems, listItem)
		table.insert(allFrames, listItem)
	end
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
	
	if DB:Get("enableGlobalSync", false) then
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
									BFL.AddFriend(friendUID)
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
													BFL.RemoveFriend(info.name) -- Use the name from the API
													BFL:DebugPrint("Removed " .. info.name .. " from friend list.")
													removed = true
													break
												end
											end
										end
										
										if not removed then
											-- Fallback: Try to remove by UID directly if not found in loop (e.g. offline/cache issue)
											BFL.RemoveFriend(friendUID)
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
	end
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end



-- Refresh Streamer Mode Tab
function Settings:RefreshStreamerTab()
	if not settingsFrame or not Components then return end

	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.StreamerTab then return end

	local tab = content.StreamerTab
	local DB = GetDB()

	-- Clear existing content
	if tab.components then
		for _, component in ipairs(tab.components) do
			if component.Hide then component:Hide() end
		end
	end
	tab.components = {}

	local allFrames = {}

	-- Title
	local title = Components:CreateHeader(tab, L.STREAMER_MODE_TITLE or "Streamer Mode")
	table.insert(allFrames, title)

	-- Enable Streamer Mode Toggle
	local enableToggle = Components:CreateCheckbox(
		tab,
		L.SETTINGS_ENABLE_STREAMER_MODE or "Show Streamer Mode Button",
		DB:Get("showStreamerModeButton", true),
		function(checked)
			DB:Set("showStreamerModeButton", checked)
			local StreamerMode = BFL:GetModule("StreamerMode")
			if StreamerMode then
				StreamerMode:UpdateState()
			end
		end
	)
	enableToggle:SetTooltip(L.STREAMER_MODE_TITLE, L.STREAMER_MODE_ENABLE_DESC)
	table.insert(allFrames, enableToggle)

	-- Header: Privacy Options
	table.insert(allFrames, Components:CreateHeader(tab, L.SETTINGS_PRIVACY_OPTIONS or "Privacy Options"))

	-- 1. Custom Header Text Input
	local headerBox = Components:CreateInput(
		tab,
		L.STREAMER_MODE_HEADER_TEXT or "Custom Header Text",
		DB:Get("streamerModeHeaderText", "Streamer Mode"),
		function(val)
			DB:Set("streamerModeHeaderText", val)
			-- Update live if active
			local StreamerMode = BFL:GetModule("StreamerMode")
			if StreamerMode then
				StreamerMode:UpdateState()
			end
		end
	)
	table.insert(allFrames, headerBox)
	
	-- 3. Name Formatting Dropdown
	local formatOptions = {
		labels = {
			L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET or "Force BattleTag",
			L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME or "Force Nickname",
			L.SETTINGS_STREAMER_NAME_FORMAT_NOTE or "Force Note"
		},
		values = {"battletag", "nickname", "note"}
	}

	local formatDropdown = Components:CreateDropdown(
		tab,
		L.SETTINGS_STREAMER_NAME_FORMAT or "Name Formatting",
		formatOptions,
		function(val) return val == DB:Get("streamerModeNameFormat", "battletag") end,
		function(val)
			DB:Set("streamerModeNameFormat", val)
			-- Refresh Friends List to update names if active
			local StreamerMode = BFL:GetModule("StreamerMode")
			if StreamerMode and StreamerMode:IsActive() then
				if BFL.ForceRefreshFriendsList then
					BFL:ForceRefreshFriendsList()
				end
			end
		end
	)
	-- Shift dropdown to prevent clipping (matching other dropdowns in Settings.lua)
	if formatDropdown.DropDown then
		local point, relativeTo, relativePoint, xOfs, yOfs = formatDropdown.DropDown:GetPoint(1)
		if point then
			formatDropdown.DropDown:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + 10, yOfs or 0)
		end
	end
	-- Add tooltip
	if formatDropdown.SetTooltip then
		formatDropdown:SetTooltip(L.SETTINGS_STREAMER_NAME_FORMAT, L.SETTINGS_STREAMER_NAME_FORMAT_DESC)
	end
	table.insert(allFrames, formatDropdown)

	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)

	-- Store components for cleanup
	tab.components = allFrames
end

-- Refresh Raid Tab
function Settings:RefreshRaidTab()
	if not settingsFrame or not Components then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content or not content.RaidTab then return end
	
	local tab = content.RaidTab
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
	
	-- Header
	local header = Components:CreateHeader(tab, L.SETTINGS_TAB_RAID or "Raid & Group")
	table.insert(allFrames, header)
	
	-- Description
	local desc = Components:CreateLabel(tab, L.SETTINGS_RAID_DESC or "Configure shortcuts for raid and group management actions on the Raid Frame.", true)
	table.insert(allFrames, desc)

	-- Spacer
	table.insert(allFrames, Components:CreateSpacer(tab))

	-- Shortcuts Configuration
	local shortcuts = DB:Get("raidShortcuts") or {}
	
	-- Helper Options
	local modifierOptions = {
		labels = {L.SETTINGS_RAID_MODIFIER_NONE or "None", "Shift", "Ctrl", "Alt", "Shift+Ctrl", "Shift+Alt", "Ctrl+Alt"},
		values = {"NONE", "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT"}
	}
	
	local buttonOptions = {
		labels = {L.SETTINGS_RAID_MOUSE_LEFT or "Left Click", L.SETTINGS_RAID_MOUSE_RIGHT or "Right Click", L.SETTINGS_RAID_MOUSE_MIDDLE or "Middle Click", "Button 4", "Button 5"},
		values = {"LeftButton", "RightButton", "Button3", "Button4", "Button5"}
	}
	
	-- Helper function to create rows
	local function CreateShortcutRow(actionName, actionKey)
		local isEnabled = DB:Get("raidShortcutEnabled_" .. actionKey, true)

		local currentMod = "NONE"
		local currentBtn = "LeftButton"
		if shortcuts[actionKey] then
			currentMod = shortcuts[actionKey].modifier or "NONE"
			currentBtn = shortcuts[actionKey].button or "LeftButton"
		end
		
		-- Row container
		local row = CreateFrame("Frame", nil, tab)
		row:SetHeight(40)
		row:SetPoint("LEFT", 0, 0)
		row:SetPoint("RIGHT", 0, 0)
		
		-- Checkbox (Manual creation for Left-Alignment)
		local template = "SettingsCheckboxTemplate"
		if BFL.IsClassic then
			template = "InterfaceOptionsCheckButtonTemplate"
		end
		
		local checkbox = CreateFrame("CheckButton", nil, row, template)
		checkbox:SetSize(26, 26)
		checkbox:SetPoint("LEFT", 0, 0)
		checkbox:SetChecked(isEnabled)
		
		-- Fix text regions in template
		if checkbox.Text then checkbox.Text:SetText("") end
		if checkbox.SetText then checkbox:SetText("") end
		local regions = {checkbox:GetRegions()}
		for _, region in ipairs(regions) do
			if region:GetObjectType() == "FontString" then region:SetText("") end
		end
		
		-- Disable highlighting when hovering (no tooltip)
		checkbox:SetScript("OnEnter", function() end)

		checkbox:SetScript("OnClick", function(self)
			local val = self:GetChecked()
			DB:Set("raidShortcutEnabled_" .. actionKey, val)
			
			-- Live refresh: Update all raid buttons
			local RaidFrame = BFL:GetModule("RaidFrame")
			if RaidFrame then
				RaidFrame:UpdateAllMemberButtons()
			end
			
			-- Refresh tab to show/hide shortcut options
			C_Timer.After(0.05, function() Settings:RefreshRaidTab() end)
		end)

		-- Label
		local label = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
		label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
		label:SetWidth(200) -- Increased width for German text
		label:SetJustifyH("LEFT")
		label:SetText(actionName)
		label:SetWordWrap(false)

		-- Validation Function
		local function IsReservedCombination(mod, btn)
			-- Reserved: LeftClick (Drag&Drop), RightClick (Menu), Ctrl+LeftClick (Multi-Select)
			if mod == "NONE" and btn == "LeftButton" then return true end
			if mod == "NONE" and btn == "RightButton" then return true end
			if mod == "CTRL" and btn == "LeftButton" then return true end
			return false
		end
		
		-- Get valid modifiers for a button
		local function GetValidModifiersForButton(btn)
			local validLabels = {}
			local validValues = {}
			for i = 1, #modifierOptions.values do
				if not IsReservedCombination(modifierOptions.values[i], btn) then
					table.insert(validLabels, modifierOptions.labels[i])
					table.insert(validValues, modifierOptions.values[i])
				end
			end
			return {labels = validLabels, values = validValues}
		end
		
		-- Get valid buttons for a modifier
		local function GetValidButtonsForModifier(mod)
			local validLabels = {}
			local validValues = {}
			for i = 1, #buttonOptions.values do
				if not IsReservedCombination(mod, buttonOptions.values[i]) then
					table.insert(validLabels, buttonOptions.labels[i])
					table.insert(validValues, buttonOptions.values[i])
				end
			end
			return {labels = validLabels, values = validValues}
		end

		-- Validation Function (legacy, now replaced by filtering)
		local function ValidateShortcut(mod, btn)
			if IsReservedCombination(mod, btn) then
				print("|cffff0000BetterFriendlist:|r " .. (L.SETTINGS_RAID_ERROR_RESERVED or "This combination is reserved."))
				return false
			end
			return true
		end

		-- Only show dropdowns if enabled
		if isEnabled then
			-- Get current shortcuts
			local s = DB:Get("raidShortcuts") or {}
			
			-- Modifier Dropdown (dynamically filtered)
			local currentBtn = s[actionKey] and s[actionKey].button or "LeftButton"
			local validModifiers = GetValidModifiersForButton(currentBtn)
			
			local modDropdown = Components:CreateDropdown(
				row, 
				"", 
				validModifiers, -- Use filtered list
				function(val) 
					local s = DB:Get("raidShortcuts") or {}
					local m = "NONE"
					if s[actionKey] then
						m = s[actionKey].modifier or "NONE"
					end
					return val == m
				end,
				function(val)
					-- Snapshot update
					local s = DB:Get("raidShortcuts") or {}
					if not s[actionKey] then s[actionKey] = {} end
					
					local currentBtnVal = s[actionKey].button or "LeftButton"
					if not ValidateShortcut(val, currentBtnVal) then
						Settings:RefreshRaidTab() -- Reset UI
						return
					end

					s[actionKey].modifier = val
					DB:Set("raidShortcuts", s)
					
					-- Live refresh: Update all raid buttons
					local RaidFrame = BFL:GetModule("RaidFrame")
					if RaidFrame then
						RaidFrame:UpdateAllMemberButtons()
					end
					
					-- Refresh button dropdown (modifier changed, button options may change)
					C_Timer.After(0.05, function() Settings:RefreshRaidTab() end)
				end
			)
			-- MANUAL LAYOUT FIX: Disable auto-layout to prevent 170px width enforcement
			modDropdown:SetScript("OnSizeChanged", nil)
			modDropdown:ClearAllPoints()
			modDropdown:SetPoint("LEFT", label, "RIGHT", 5, 0)
			modDropdown:SetWidth(115)
			modDropdown:SetScale(1)
			modDropdown.Label:Hide()
			
			local ddMod = modDropdown.DropDown
			ddMod:ClearAllPoints()
			if BFL.IsClassic or not BFL.HasModernMenu then
				UIDropDownMenu_SetWidth(ddMod, 95)
				ddMod:SetPoint("TOPLEFT", modDropdown, "TOPLEFT", -15, -2)
			else
				ddMod:SetPoint("LEFT", modDropdown, "LEFT", 0, 0)
				ddMod:SetWidth(115)
			end
			
			-- Button Dropdown (dynamically filtered)
			local currentMod = s[actionKey] and s[actionKey].modifier or "NONE"
			local validButtons = GetValidButtonsForModifier(currentMod)
			
			local btnDropdown = Components:CreateDropdown(
				row, 
				"", 
				validButtons, -- Use filtered list
				function(val) 
					local s = DB:Get("raidShortcuts") or {}
					local b = "LeftButton"
					if s[actionKey] then
						b = s[actionKey].button or "LeftButton"
					end
					return val == b
				end,
				function(val)
					local s = DB:Get("raidShortcuts") or {}
					if not s[actionKey] then s[actionKey] = {} end
					
					local currentModVal = s[actionKey].modifier or "NONE"
					if not ValidateShortcut(currentModVal, val) then
						Settings:RefreshRaidTab() -- Reset UI
						return
					end

					s[actionKey].button = val
					DB:Set("raidShortcuts", s)
					
					-- Live refresh: Update all raid buttons
					local RaidFrame = BFL:GetModule("RaidFrame")
					if RaidFrame then
						RaidFrame:UpdateAllMemberButtons()
					end
					
					-- Refresh modifier dropdown (button changed, modifier options may change)
					C_Timer.After(0.05, function() Settings:RefreshRaidTab() end)
				end
			)
			-- MANUAL LAYOUT FIX: Disable auto-layout
			btnDropdown:SetScript("OnSizeChanged", nil)
			btnDropdown:ClearAllPoints()
			btnDropdown:SetPoint("LEFT", modDropdown, "RIGHT", 5, 0)
			btnDropdown:SetWidth(115)
			btnDropdown:SetScale(1)
			btnDropdown.Label:Hide()
			
			local ddBtn = btnDropdown.DropDown
			ddBtn:ClearAllPoints()
			if BFL.IsClassic or not BFL.HasModernMenu then
				UIDropDownMenu_SetWidth(ddBtn, 95)
				ddBtn:SetPoint("TOPLEFT", btnDropdown, "TOPLEFT", -15, -2)
			else
				ddBtn:SetPoint("LEFT", btnDropdown, "LEFT", 0, 0)
				ddBtn:SetWidth(115)
			end

			-- If action is Target, maybe verify it defaults to None+Left?
			-- It is configured in DB defaults.
		end
		
		table.insert(allFrames, row)
	end
	
	-- Create rows
	CreateShortcutRow(L.SETTINGS_RAID_ACTION_MAIN_TANK or "Set Main Tank", "mainTank")
	CreateShortcutRow(L.SETTINGS_RAID_ACTION_MAIN_ASSIST or "Set Main Assist", "mainAssist")
	CreateShortcutRow(L.SETTINGS_RAID_ACTION_RAID_LEAD or "Set Raid Leader", "lead")
	CreateShortcutRow(L.SETTINGS_RAID_ACTION_PROMOTE or "Promo/Demote Assistant", "promote")

	-- Warning about reloading/combat
	table.insert(allFrames, Components:CreateSpacer(tab))
	local warning = Components:CreateLabel(tab, L.SETTINGS_RAID_WARNING or "Note: Shortcuts are secure actions and update immediately (when out of combat).", true)
	warning:SetTextColor(0.7, 0.7, 0.7)
	table.insert(allFrames, warning)
	
	-- Anchor
	Components:AnchorChain(allFrames, -5)
	
	tab.components = allFrames
end


return Settings
