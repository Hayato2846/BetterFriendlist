-- Settings.lua
-- Settings panel and configuration management module

local ADDON_NAME, BFL = ...

-- Import UI constants
local UI = BFL.UI.CONSTANTS

-- Import Settings Components Library
local Components = BFL.SettingsComponents

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
	button.dragHandle = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.dragHandle:SetPoint("LEFT", UI.SPACING_SMALL, 0)
	button.dragHandle:SetText(":::")
	button.dragHandle:SetTextColor(unpack(UI.TEXT_COLOR_GRAY))
	
	-- Order Number
	button.orderText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.orderText:SetPoint("LEFT", button.dragHandle, "RIGHT", UI.SPACING_MEDIUM, 0)
	button.orderText:SetText(orderIndex)
	button.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Group Name
	button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
			GameTooltip:SetText(BFL_L.TOOLTIP_RENAME_GROUP, 1, 1, 1)
			GameTooltip:AddLine(BFL_L.TOOLTIP_RENAME_DESC, 0.8, 0.8, 0.8, true)
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
		GameTooltip:SetText(BFL_L.TOOLTIP_GROUP_COLOR, 1, 1, 1)
		GameTooltip:AddLine(BFL_L.TOOLTIP_GROUP_COLOR_DESC, 0.8, 0.8, 0.8, true)
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
			GameTooltip:SetText(BFL_L.TOOLTIP_DELETE_GROUP, 1, 0.2, 0.2)
			GameTooltip:AddLine(BFL_L.TOOLTIP_DELETE_DESC, 0.8, 0.8, 0.8, true)
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
	
	print("|cff00ffffBetterFriendlist Debug:|r     Parsing note:", noteText)
	
	local parts = {strsplit("#", noteText)}
	local actualNote = parts[1] or ""
	local groups = {}
	
	print("|cff00ffffBetterFriendlist Debug:|r     Split into", #parts, "parts")
	
	for i = 2, #parts do
		local groupName = strtrim(parts[i])
		if groupName ~= "" then
			table.insert(groups, groupName)
			print("|cff00ffffBetterFriendlist Debug:|r     Found group:", groupName)
		end
	end
	
	print("|cff00ffffBetterFriendlist Debug:|r     Actual note:", actualNote)
	print("|cff00ffffBetterFriendlist Debug:|r     Total groups found:", #groups)
	
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
		self:ShowTab(1)
	else
		print("|cffff0000BetterFriendlist Settings:|r Frame not initialized!")
	end
end

-- ===========================================
-- TAB SYSTEM: Central Definition
-- ===========================================
local TAB_DEFINITIONS = {
	-- Stable Tabs (always visible)
	{id = 1, name = "General", icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\settings.blp", beta = false},
	{id = 2, name = "Groups", icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp", beta = false},
	{id = 3, name = "Advanced", icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\sliders.blp", beta = false},
	
	-- Beta Tabs (only visible when enableBetaFeatures = true)
	{id = 4, name = "Notifications", icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\bell.blp", beta = true},
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
			-- Build tab text with icon and coloring
			local color = tabDef.beta and COLOR_BETA or COLOR_STABLE
			-- Icon with color tint: r:g:b values (255, 136, 0 for orange / 255, 255, 0 for gold)
			local r, g, b
			if tabDef.beta then
				r, g, b = 255, 136, 0 -- Orange
			else
				r, g, b = 255, 255, 0 -- Gold
			end
			local iconTexture = tabDef.icon and ("|T" .. tabDef.icon .. ":16:16:0:0:64:64:0:64:0:64:" .. r .. ":" .. g .. ":" .. b .. "|t ") or ""
			local text = color .. iconTexture .. tabDef.name .. "|r"
			
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
	
	-- Update panel - always set to highest tab ID in definitions
	local maxTabId = 0
	for _, tabDef in ipairs(TAB_DEFINITIONS) do
		if tabDef.id > maxTabId then
			maxTabId = tabDef.id
		end
	end
	PanelTemplates_SetNumTabs(settingsFrame, maxTabId)
	PanelTemplates_UpdateTabs(settingsFrame)
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
	settingsFrame.numTabs = 4
	PanelTemplates_SetTab(settingsFrame, tabID)
	
	local content = settingsFrame.ContentScrollFrame.Content
	if content then
		if content.GeneralTab then content.GeneralTab:Hide() end
		if content.GroupsTab then content.GroupsTab:Hide() end
		if content.AdvancedTab then content.AdvancedTab:Hide() end
		if content.NotificationsTab then content.NotificationsTab:Hide() end
		
		if tabID == 1 and content.GeneralTab then
			content.GeneralTab:Show()
			self:RefreshGeneralTab()
		elseif tabID == 2 and content.GroupsTab then
			content.GroupsTab:Show()
			self:RefreshGroupsTab()
		elseif tabID == 3 and content.AdvancedTab then
			content.AdvancedTab:Show()
			self:RefreshAdvancedTab()
		elseif tabID == 4 and content.NotificationsTab then
			content.NotificationsTab:Show()
			self:RefreshNotificationsTab()
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
		activeTab = content.GroupsTab
	elseif tabID == 3 then
		activeTab = content.AdvancedTab
	elseif tabID == 4 then
		activeTab = content.StatisticsTab
	elseif tabID == 5 then
		activeTab = content.StatisticsTab
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
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("fontSize", size)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
	
	-- Refresh General Tab to update dropdown display
	if currentTab == 1 then
		self:RefreshGeneralTab()
	end
end

-- Reset to defaults
function Settings:ResetToDefaults()
	StaticPopup_Show("BETTER_FRIENDLIST_RESET_SETTINGS")
end

-- Perform the actual reset
function Settings:DoReset()
	local DB = GetDB()
	if not DB then
		print("|cffff0000BetterFriendlist Settings:|r Database not available!")
		return
	end
	
	DB:Set("showBlizzardOption", false)
	DB:Set("compactMode", false)
	DB:Set("fontSize", "normal")
	DB:Set("colorClassNames", true)
	DB:Set("hideEmptyGroups", false)
	DB:Set("showFactionIcons", false)
	DB:Set("showRealmName", false)
	DB:Set("grayOtherFaction", false)
	DB:Set("showMobileAsAFK", false)
	DB:Set("hideMaxLevel", false)
	DB:Set("accordionGroups", false)
	
	self:LoadSettings()
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
	
	print("|cff20ff20BetterFriendlist:|r " .. BFL_L.SETTINGS_RESET_SUCCESS)
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
		print("|cffff0000BetterFriendlist Settings:|r Groups module not available!")
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
		table.insert(orderedGroups, {id = "favorites", name = "Favorites", order = 1})
		
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
			table.insert(orderedGroups, {id = "nogroup", name = "No Group", order = #orderedGroups + 1})
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
		print("|cff20ff20BetterFriendlist:|r " .. BFL_L.SETTINGS_GROUP_ORDER_SAVED)
		
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
		
		if BetterFriendsFrame_UpdateDisplay then
			BetterFriendsFrame_UpdateDisplay()
		end
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
		
		if BetterFriendsFrame_UpdateDisplay then
			BetterFriendsFrame_UpdateDisplay()
		end
	end
	
	ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- Delete a custom group
function Settings:DeleteGroup(groupId, groupName)
	StaticPopupDialogs["BETTERFRIENDLIST_DELETE_GROUP"] = {
		text = string.format("Delete group '%s'?\n\nAll friends will be unassigned from this group.", groupName),
		button1 = "Delete",
		button2 = "Cancel",
		OnAccept = function()
			local Groups = GetGroups()
			local DB = GetDB()
			
			if not Groups or not DB then
				print("|cffff0000BetterFriendlist:|r Failed to delete group - modules not loaded")
				return
			end
			
			local success, err = Groups:Delete(groupId)
			if success then
				print("|cff00ff00BetterFriendlist:|r " .. string.format(BFL_L.MSG_GROUP_DELETED, groupName))
				
				Settings:RefreshGroupList()
				
				if BetterFriendsFrame_UpdateDisplay then
					BetterFriendsFrame_UpdateDisplay()
				end
			else
				print("|cffff0000BetterFriendlist:|r Failed to delete group: " .. (err or "Unknown error"))
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
		text = string.format("Rename group '%s':", currentName),
		button1 = "Rename",
		button2 = "Cancel",
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
						print("|cff00ff00BetterFriendlist:|r Group renamed to '" .. newName .. "'")
						Settings:RefreshGroupsTab()
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					else
						print("|cffff0000BetterFriendlist:|r Failed to rename group")
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
						print("|cff00ff00BetterFriendlist:|r Group renamed to '" .. newName .. "'")
						Settings:RefreshGroupsTab()
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					else
						print("|cffff0000BetterFriendlist:|r Failed to rename group")
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
function Settings:MigrateFriendGroups(cleanupNotes)
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		print("|cffff0000BetterFriendlist:|r Migration failed - modules not loaded!")
		return
	end
	
	-- Check if migration has already been completed
	if DB:Get("friendGroupsMigrated") then
		print("|cff00ffffBetterFriendlist:|r " .. BFL_L.MSG_MIGRATION_ALREADY_DONE)
		return
	end
	
	print("|cff00ffffBetterFriendlist:|r " .. BFL_L.MSG_MIGRATION_STARTING)
	print("|cff00ffffBetterFriendlist:|r DB module:", DB and "OK" or "MISSING")
	print("|cff00ffffBetterFriendlist:|r Groups module:", Groups and "OK" or "MISSING")
	
	local migratedFriends = 0
	local migratedGroups = {}
	local groupNameMap = {}
	local assignmentCount = 0
	local allGroupNames = {}
	local friendGroupAssignments = {}
	
	-- PHASE 1: Collect all group names from all friends
	print("|cff00ffffBetterFriendlist:|r Phase 1 - Collecting group names...")
	
	local numBNetFriends = BNGetNumFriends()
	print("|cff00ffffBetterFriendlist:|r Scanning", numBNetFriends, "BattleNet friends...")
	
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
	
	local numWoWFriends = C_FriendList.GetNumFriends()
	print("|cff00ffffBetterFriendlist:|r Scanning", numWoWFriends, "WoW friends...")
	
	for i = 1, numWoWFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			-- Normalize name to always include realm
			local name = BFL:NormalizeWoWFriendName(info.name)
			local noteText = info.notes
			
			if noteText and noteText ~= "" then
				local actualNote, friendGroups = ParseFriendGroupsNote(noteText)
				
				if #friendGroups > 0 then
					local friendUID = "wow_" .. name
					friendGroupAssignments[friendUID] = {
						groups = friendGroups,
						actualNote = actualNote,
						isBNet = false,
						characterName = name
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
	
	-- PHASE 2: Create groups in alphabetical order
	print("|cff00ffffBetterFriendlist:|r Phase 2 - Creating groups in alphabetical order...")
	
	local sortedGroupNames = {}
	for groupName in pairs(allGroupNames) do
		table.insert(sortedGroupNames, groupName)
	end
	table.sort(sortedGroupNames)
	
	print("|cff00ffffBetterFriendlist:|r Creating", #sortedGroupNames, "groups...")
	
	local currentOrder = 2
	local groupOrderArray = {"favorites"}
	
	for _, groupName in ipairs(sortedGroupNames) do
		local success, groupId = Groups:CreateWithOrder(groupName, currentOrder)
		if success and groupId then
			groupNameMap[groupName] = groupId
			migratedGroups[groupName] = true
			table.insert(groupOrderArray, groupId)
			print("|cff00ff00BetterFriendlist:|r   ✓ Created:", groupName, "(order:", currentOrder, ")")
			currentOrder = currentOrder + 1
		else
			-- Group already exists - get its ID by name
			if groupId == "Group already exists" then
				local existingGroupId = Groups:GetGroupIdByName(groupName)
				if existingGroupId then
					groupNameMap[groupName] = existingGroupId
					migratedGroups[groupName] = true
					table.insert(groupOrderArray, existingGroupId)
					print("|cffffff00BetterFriendlist:|r   [!] Existing:", groupName, "(using existing group)")
					currentOrder = currentOrder + 1
				else
					print("|cffff0000BetterFriendlist:|r   ✗ FAILED:", groupName, "- Group exists but ID not found")
				end
			else
				print("|cffff0000BetterFriendlist:|r   ✗ FAILED:", groupName, "-", tostring(groupId))
			end
		end
	end
	
	table.insert(groupOrderArray, "nogroup")
	
	DB:Set("groupOrder", groupOrderArray)
	print("|cff00ffffBetterFriendlist:|r Group order saved:", table.concat(groupOrderArray, ", "))
	
	-- PHASE 3: Assign friends to groups
	print("|cff00ffffBetterFriendlist:|r Phase 3 - Assigning friends to groups...")
	
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
		print("|cff00ffffBetterFriendlist:|r Phase 4 - Cleaning up notes...")
		
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
	
	local cleanupMsg = cleanupNotes and ("\n|cff00ff00" .. BFL_L.SETTINGS_NOTES_CLEANED .. "|r") or ("\n|cffffff00" .. BFL_L.SETTINGS_NOTES_PRESERVED .. "|r")
	
	-- Mark migration as completed
	DB:Set("friendGroupsMigrated", true)
	
	print("|cff00ff00═══════════════════════════════════════")
	print("|cff00ff00BetterFriendlist: " .. BFL_L.SETTINGS_MIGRATION_COMPLETE)
	print("|cff00ff00═══════════════════════════════════════")
	print(string.format(
		"|cff00ffff%s|r %d\n" ..
		"|cff00ffff%s|r %d\n" ..
		"|cff00ffff%s|r %d%s",
		BFL_L.SETTINGS_MIGRATION_FRIENDS,
		migratedFriends,
		BFL_L.SETTINGS_MIGRATION_GROUPS,
		numGroups,
		BFL_L.SETTINGS_MIGRATION_ASSIGNMENTS,
		assignmentCount,
		cleanupMsg
	))
	
	print("|cff00ffffBetterFriendlist:|r Refreshing friends list...")
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		if BetterFriendsFrame_UpdateDisplay then
			BetterFriendsFrame_UpdateDisplay()
			print("|cff00ff00BetterFriendlist:|r Friends list refreshed!")
		end
	else
		print("|cffffff00BetterFriendlist:|r Friends frame not open - changes will appear when you open it.")
	end
end

-- Show migration dialog
function Settings:ShowMigrationDialog()
	StaticPopupDialogs["BETTERFRIENDLIST_MIGRATE_FRIENDGROUPS"] = {
		text = BFL_L.DIALOG_MIGRATE_TEXT,
		button1 = BFL_L.DIALOG_MIGRATE_BTN1,
		button2 = BFL_L.DIALOG_MIGRATE_BTN2,
		button3 = BFL_L.DIALOG_MIGRATE_BTN3,
		OnAccept = function()
			Settings:MigrateFriendGroups(true)
		end,
		OnCancel = function()
			Settings:MigrateFriendGroups(false)
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
	print("|cff00ffffBetterFriendlist Debug:|r =================================")
	print("|cff00ffffBetterFriendlist Debug:|r DATABASE STATE")
	print("|cff00ffffBetterFriendlist Debug:|r =================================")
	
	if not BetterFriendlistDB then
		print("|cffff0000BetterFriendlist Debug:|r BetterFriendlistDB is NIL!")
		return
	end
	
	print("|cff00ffffBetterFriendlist Debug:|r")
	print("|cff00ffffBetterFriendlist Debug:|r CUSTOM GROUPS:")
	if BetterFriendlistDB.customGroups then
		local groupCount = 0
		for groupId, groupInfo in pairs(BetterFriendlistDB.customGroups) do
			groupCount = groupCount + 1
			print(string.format("|cff00ffffBetterFriendlist Debug:|r   [%s] = %s", groupId, groupInfo.name or "UNNAMED"))
		end
		print("|cff00ffffBetterFriendlist Debug:|r Total groups:", groupCount)
	else
		print("|cffff0000BetterFriendlist Debug:|r customGroups table MISSING!")
	end
	
	print("|cff00ffffBetterFriendlist Debug:|r")
	print("|cff00ffffBetterFriendlist Debug:|r FRIEND ASSIGNMENTS:")
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
			print(line)
		end
		
		if friendCount == 0 then
			print("|cff00ffffBetterFriendlist Debug:|r   (No friends assigned to custom groups)")
		end
		print("|cff00ffffBetterFriendlist Debug:|r Total friends with assignments:", friendCount)
		print("|cff00ffffBetterFriendlist Debug:|r Total assignments:", totalAssignments)
	else
		print("|cffff0000BetterFriendlist Debug:|r friendGroups table MISSING!")
	end
	
	print("|cff00ffffBetterFriendlist Debug:|r")
	print("|cff00ffffBetterFriendlist Debug:|r GROUP ORDER:")
	if BetterFriendlistDB.groupOrder then
		print("|cff00ffffBetterFriendlist Debug:|r", table.concat(BetterFriendlistDB.groupOrder, ", "))
	else
		print("|cff00ffffBetterFriendlist Debug:|r Using default order (nil)")
	end
	
	-- Show current friends list
	print("|cff00ffffBetterFriendlist Debug:|r")
	print("|cff00ffffBetterFriendlist Debug:|r CURRENT FRIENDS:")
	
	-- Battle.net friends
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	print("|cff00ffffBetterFriendlist Debug:|r Battle.net Friends:", numBNetTotal, string.format("(%d online)", numBNetOnline))
	if numBNetTotal > 0 then
		for i = 1, math.min(numBNetTotal, 10) do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local status = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline and "|cff00ff00ONLINE|r" or "|cffaaaaaaOFFLINE|r"
				local name = accountInfo.accountName ~= "???" and accountInfo.accountName or accountInfo.battleTag
				print(string.format("|cff00ffffBetterFriendlist Debug:|r   [%d] %s - %s", i, name, status))
			end
		end
		if numBNetTotal > 10 then
			print(string.format("|cff00ffffBetterFriendlist Debug:|r   ... and %d more", numBNetTotal - 10))
		end
	end
	
	-- WoW friends
	print("|cff00ffffBetterFriendlist Debug:|r")
	local numWoWFriends = C_FriendList.GetNumFriends()
	local numWoWOnline = C_FriendList.GetNumOnlineFriends()
	print("|cff00ffffBetterFriendlist Debug:|r WoW Friends:", numWoWFriends, string.format("(%d online)", numWoWOnline))
	if numWoWFriends > 0 then
		for i = 1, math.min(numWoWFriends, 10) do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo then
				local status = friendInfo.connected and "|cff00ff00ONLINE|r" or "|cffaaaaaaOFFLINE|r"
				local level = friendInfo.level and friendInfo.level > 0 and string.format(" (Lvl %d)", friendInfo.level) or ""
				print(string.format("|cff00ffffBetterFriendlist Debug:|r   [%d] %s%s - %s", i, friendInfo.name, level, status))
			end
		end
		if numWoWFriends > 10 then
			print(string.format("|cff00ffffBetterFriendlist Debug:|r   ... and %d more", numWoWFriends - 10))
		end
	end
	
	print("|cff00ffffBetterFriendlist Debug:|r =================================")
end

--------------------------------------------------------------------------
-- EXPORT / IMPORT SYSTEM
--------------------------------------------------------------------------

-- Export all settings to a string
function Settings:ExportSettings()
	if not BetterFriendlistDB then
		return nil, "Database not available"
	end
	
	-- Collect data to export
	local exportData = {
		version = 1, -- Export format version
		customGroups = {},
		friendGroups = {},
		groupOrder = {},
		groupStates = {},
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
		return nil, "Failed to serialize data"
	end
	
	-- Encode to base64-like format for easy copy/paste
	local encoded = self:EncodeString(serialized)
	
	return encoded, nil
end

-- Import settings from string
function Settings:ImportSettings(importString)
	if not importString or importString == "" then
		return false, "Import string is empty"
	end
	
	-- Decode from base64-like format
	local decoded = self:DecodeString(importString)
	if not decoded then
		return false, "Failed to decode import string (invalid format)"
	end
	
	-- Deserialize
	local importData = self:DeserializeTable(decoded)
	if not importData then
		return false, "Failed to deserialize data (corrupted string)"
	end
	
	-- Validate version
	if not importData.version or importData.version ~= 1 then
		return false, "Unsupported export version"
	end
	
	-- Validate structure
	if not importData.customGroups or not importData.friendGroups then
		return false, "Invalid export data structure"
	end
	
	-- IMPORT DATA
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		return false, "Modules not available"
	end
	
	-- Clear existing data
	BetterFriendlistDB.customGroups = {}
	BetterFriendlistDB.friendGroups = {}
	BetterFriendlistDB.groupOrder = {}
	BetterFriendlistDB.groupStates = {}
	
	-- Import custom groups
	for groupId, groupInfo in pairs(importData.customGroups) do
		BetterFriendlistDB.customGroups[groupId] = {
			name = groupInfo.name,
			collapsed = groupInfo.collapsed or false,
			order = groupInfo.order or 2,
			color = groupInfo.color or {r = 1.0, g = 0.82, b = 0.0}
		}
	end
	
	-- Import friend assignments
	for friendUID, groups in pairs(importData.friendGroups) do
		BetterFriendlistDB.friendGroups[friendUID] = {}
		for _, groupId in ipairs(groups) do
			table.insert(BetterFriendlistDB.friendGroups[friendUID], groupId)
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
	
	-- Reload Groups module (this will apply imported colors)
	Groups:Initialize()
	
	-- Refresh UI
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
	
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
		print("|cffff0000BetterFriendlist:|r Export failed:", err or "Unknown error")
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
	
	print("|cff00ff00BetterFriendlist:|r Export complete! Copy the text from the dialog.")
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
		BFL:DebugPrint("Settings: Statistics module not available")
		return
	end
	
	-- Get statistics data
	local stats = Statistics:GetStatistics()
	if not stats then
		BFL:DebugPrint("Settings: Failed to get statistics")
		return
	end
	
	-- Helper function to format percentage
	local function FormatPercent(value, total)
		if total == 0 then return 0 end
		return math.floor((value / total) * 100 + 0.5)
	end
	
	-- Update Overview section
	if statsTab.TotalFriends then
		statsTab.TotalFriends:SetText(string.format("Total Friends: %d", stats.totalFriends))
	end
	
	if statsTab.OnlineFriends then
		local onlinePct = FormatPercent(stats.onlineFriends, stats.totalFriends)
		local offlinePct = FormatPercent(stats.offlineFriends, stats.totalFriends)
		statsTab.OnlineFriends:SetText(string.format("|cff00ff00Online: %d (%d%%)|r  |  |cff808080Offline: %d (%d%%)|r", 
			stats.onlineFriends, onlinePct, stats.offlineFriends, offlinePct))
	end
	
	if statsTab.FriendTypes then
		statsTab.FriendTypes:SetText(string.format("|cff0070ddBattle.net Friends: %d|r  |  |cffffd700WoW Friends: %d|r", 
			stats.bnetFriends, stats.wowFriends))
	end
	
	-- Update Friendship Health (NEW)
	if statsTab.FriendshipHealth then
		local totalHealthFriends = stats.totalFriends - (stats.friendshipHealth.unknown or 0)
		if totalHealthFriends > 0 then
			local healthText = string.format(
				"|cff00ff00Active: %d (%d%%)|r\n|cffffd700Regular: %d (%d%%)|r\n|cffffaa00Drifting: %d (%d%%)|r\n|cffff6600Stale: %d (%d%%)|r\n|cffff0000Dormant: %d (%d%%)|r",
				stats.friendshipHealth.active, FormatPercent(stats.friendshipHealth.active, totalHealthFriends),
				stats.friendshipHealth.regular, FormatPercent(stats.friendshipHealth.regular, totalHealthFriends),
				stats.friendshipHealth.drifting, FormatPercent(stats.friendshipHealth.drifting, totalHealthFriends),
				stats.friendshipHealth.stale, FormatPercent(stats.friendshipHealth.stale, totalHealthFriends),
				stats.friendshipHealth.dormant, FormatPercent(stats.friendshipHealth.dormant, totalHealthFriends)
			)
			statsTab.FriendshipHealth:SetText(healthText)
		else
			statsTab.FriendshipHealth:SetText("No health data available")
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
				table.insert(classParts, string.format("%d. %s: %d (%d%%)", i, class.name, class.count, pct))
			end
			statsTab.ClassList:SetText(table.concat(classParts))
		else
			statsTab.ClassList:SetText("No class data available")
		end
	end
	
	-- Update Level Distribution (NEW)
	if statsTab.LevelDistribution then
		if stats.levelDistribution.leveledFriends > 0 then
			local levelText = string.format(
				"Max (80): %d\n70-79: %d\n60-69: %d\n<60: %d\nAverage: %.1f",
				stats.levelDistribution.maxLevel,
				stats.levelDistribution.ranges[1].count,
				stats.levelDistribution.ranges[2].count,
				stats.levelDistribution.ranges[3].count,
				stats.levelDistribution.average
			)
			statsTab.LevelDistribution:SetText(levelText)
		else
			statsTab.LevelDistribution:SetText("No level data available")
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
			table.insert(realmParts, string.format("Same Realm: %d (%d%%)  |  Other Realms: %d (%d%%)",
				stats.realmDistribution.sameRealm, samePct,
				stats.realmDistribution.otherRealms, otherPct))
			table.insert(realmParts, "\nTop Realms:")
			for i, realm in ipairs(topRealms) do
				table.insert(realmParts, string.format("\n%d. %s: %d", i, realm.name, realm.count))
			end
			statsTab.RealmList:SetText(table.concat(realmParts))
		else
			statsTab.RealmList:SetText("No realm data available")
		end
	end
	
	-- Update Faction Distribution
	if statsTab.FactionList then
		local factionText = string.format(
			"|cff0080ffAlliance: %d|r\n|cffff0000Horde: %d|r",
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
				table.insert(gameParts, string.format("WoW: %d", stats.gameCounts.wow))
			end
			if stats.gameCounts.classic > 0 then
				table.insert(gameParts, string.format("\nClassic: %d", stats.gameCounts.classic))
			end
			if stats.gameCounts.diablo > 0 then
				table.insert(gameParts, string.format("\nDiablo IV: %d", stats.gameCounts.diablo))
			end
			if stats.gameCounts.hearthstone > 0 then
				table.insert(gameParts, string.format("\nHearthstone: %d", stats.gameCounts.hearthstone))
			end
			if stats.gameCounts.mobile > 0 then
				table.insert(gameParts, string.format("\nMobile: %d", stats.gameCounts.mobile))
			end
			if stats.gameCounts.other > 0 then
				table.insert(gameParts, string.format("\nOther: %d", stats.gameCounts.other))
			end
			statsTab.GameDistribution:SetText(table.concat(gameParts))
		else
			statsTab.GameDistribution:SetText("No game data available")
		end
	end
	
	-- Update Mobile vs Desktop (NEW)
	if statsTab.MobileVsDesktop then
		if stats.mobileVsDesktop.desktop > 0 or stats.mobileVsDesktop.mobile > 0 then
			local total = stats.mobileVsDesktop.desktop + stats.mobileVsDesktop.mobile
			local desktopPct = FormatPercent(stats.mobileVsDesktop.desktop, total)
			local mobilePct = FormatPercent(stats.mobileVsDesktop.mobile, total)
			local mobileText = string.format(
				"Desktop: %d (%d%%)\nMobile: %d (%d%%)",
				stats.mobileVsDesktop.desktop, desktopPct,
				stats.mobileVsDesktop.mobile, mobilePct
			)
			statsTab.MobileVsDesktop:SetText(mobileText)
		else
			statsTab.MobileVsDesktop:SetText("No mobile data available")
		end
	end
	
	-- Update Notes and Favorites (NEW)
	if statsTab.NotesAndFavorites then
		local notesPct = FormatPercent(stats.notesAndFavorites.withNotes, stats.totalFriends)
		local favPct = FormatPercent(stats.notesAndFavorites.favorites, stats.totalFriends)
		local notesText = string.format(
			"With Notes: %d (%d%%)\nFavorites: %d (%d%%)",
			stats.notesAndFavorites.withNotes, notesPct,
			stats.notesAndFavorites.favorites, favPct
		)
		statsTab.NotesAndFavorites:SetText(notesText)
	end
	
	BFL:DebugPrint("Settings: Statistics refreshed successfully")
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
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -5)
	frame.title:SetText("Export Settings")
	
	-- Info text
	frame.info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.info:SetPoint("TOPLEFT", 15, -30)
	frame.info:SetPoint("TOPRIGHT", -15, -30)
	frame.info:SetJustifyH("LEFT")
	frame.info:SetText("Copy the text below and save it. You can import it on another character or account.")
	
	-- Scroll frame with edit box
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", UI.SPACING_MEDIUM, -60)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
	frame.scrollFrame = scrollFrame
	
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(GameFontHighlight)
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
	copyButton:SetText("Select All")
	copyButton:SetNormalFontObject("GameFontNormal")
	copyButton:SetHighlightFontObject("GameFontHighlight")
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
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -5)
	frame.title:SetText("Import Settings")
	
	-- Info text
	frame.info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.info:SetPoint("TOPLEFT", 15, -30)
	frame.info:SetPoint("TOPRIGHT", -15, -30)
	frame.info:SetJustifyH("LEFT")
	frame.info:SetText("Paste your export string below and click Import.\n\n|cffff0000Warning: This will replace ALL your groups and assignments!|r")
	
	-- Scroll frame with edit box
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", UI.SPACING_MEDIUM, -80)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
	frame.scrollFrame = scrollFrame
	
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(GameFontHighlight)
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
	importButton:SetText("Import")
	importButton:SetNormalFontObject("GameFontNormal")
	importButton:SetHighlightFontObject("GameFontHighlight")
	importButton:SetScript("OnClick", function()
		local importString = editBox:GetText()
		local success, err = Settings:ImportSettings(importString)
		
		if success then
			print("|cff00ff00BetterFriendlist:|r Import successful! All groups and assignments have been restored.")
			frame:Hide()
		else
			print("|cffff0000BetterFriendlist:|r Import failed:", err or "Unknown error")
			-- Show error in UI
			StaticPopupDialogs["BETTERFRIENDLIST_IMPORT_ERROR"] = {
				text = "Import Failed!\n\n" .. (err or "Unknown error"),
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
	cancelButton:SetText("Cancel")
	cancelButton:SetNormalFontObject("GameFontNormal")
	cancelButton:SetHighlightFontObject("GameFontHighlight")
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
	
	-- CRITICAL: Re-render display to recalculate button heights
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		FriendsList:RenderDisplay()
	end
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Callback for ShowBlizzardOption checkbox
function Settings:OnShowBlizzardOptionChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showBlizzardOption", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Callback for ColorClassNames checkbox
function Settings:OnColorClassNamesChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("colorClassNames", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Callback for HideEmptyGroups checkbox
function Settings:OnHideEmptyGroupsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("hideEmptyGroups", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Show Faction Icons toggle
function Settings:OnShowFactionIconsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showFactionIcons", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Show Realm Name toggle
function Settings:OnShowRealmNameChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showRealmName", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Show Favorites Group toggle
function Settings:OnShowFavoritesGroupChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showFavoritesGroup", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Gray Other Faction toggle
function Settings:OnGrayOtherFactionChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("grayOtherFaction", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Show Mobile as AFK toggle
function Settings:OnShowMobileAsAFKChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("showMobileAsAFK", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Hide Max Level toggle
function Settings:OnHideMaxLevelChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("hideMaxLevel", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

-- Accordion Groups toggle
function Settings:OnAccordionGroupsChanged(checked)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("accordionGroups", checked)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
end

--------------------------------------------------------------------------
-- NEW: PLATYNATOR-STYLE TAB REFRESH FUNCTIONS
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
	local displayHeader = Components:CreateHeader(tab, "Display Options")
	table.insert(allFrames, displayHeader)
	
	-- Color Class Names
	local colorClassNames = Components:CreateCheckbox(tab, "Color Character Names by Class", 
		DB:Get("colorClassNames", true),
		function(val) self:OnColorClassNamesChanged(val) end)
	colorClassNames:SetTooltip("Class Colors", "Colors character names using their class color for easier identification")
	table.insert(allFrames, colorClassNames)
	
	-- Hide Empty Groups
	local hideEmptyGroups = Components:CreateCheckbox(tab, "Hide Groups with No Online Friends",
		DB:Get("hideEmptyGroups", false),
		function(val) self:OnHideEmptyGroupsChanged(val) end)
	hideEmptyGroups:SetTooltip("Hide Empty Groups", "Automatically hides groups that have no online members")
	table.insert(allFrames, hideEmptyGroups)
	
	-- Show Faction Icons
	local showFactionIcons = Components:CreateCheckbox(tab, "Show Faction Icons", 
		DB:Get("showFactionIcons", true),
		function(val) self:OnShowFactionIconsChanged(val) end)
	showFactionIcons:SetTooltip("Show Faction Icons", "Display Alliance/Horde icons next to character names")
	table.insert(allFrames, showFactionIcons)
	
	-- Show Realm Name
	local showRealmName = Components:CreateCheckbox(tab, "Show Realm Name for Cross-Realm Friends",
		DB:Get("showRealmName", true),
		function(val) self:OnShowRealmNameChanged(val) end)
	showRealmName:SetTooltip("Show Realm Name", "Display the realm name for friends on different servers")
	table.insert(allFrames, showRealmName)
	
	-- Gray Other Faction
	local grayOtherFaction = Components:CreateCheckbox(tab, "Gray Out Opposite Faction", 
		DB:Get("grayOtherFaction", false),
		function(val) self:OnGrayOtherFactionChanged(val) end)
	grayOtherFaction:SetTooltip("Gray Other Faction", "Make friends from the opposite faction appear grayed out")
	table.insert(allFrames, grayOtherFaction)
	
	-- Show Mobile as AFK
	local showMobileAsAFK = Components:CreateCheckbox(tab, "Show Mobile Friends as AFK", 
		DB:Get("showMobileAsAFK", false),
		function(val) self:OnShowMobileAsAFKChanged(val) end)
	showMobileAsAFK:SetTooltip("Mobile as AFK", "Display AFK status icon for friends on mobile (BSAp only)")
	table.insert(allFrames, showMobileAsAFK)
	
	-- Hide Max Level
	local hideMaxLevel = Components:CreateCheckbox(tab, "Hide Level for Max Level Characters", 
		DB:Get("hideMaxLevel", false),
		function(val) self:OnHideMaxLevelChanged(val) end)
	hideMaxLevel:SetTooltip("Hide Max Level", "Don't display level number for characters at max level")
	table.insert(allFrames, hideMaxLevel)
	
	-- Show Blizzard Friend List Option
	local showBlizzard = Components:CreateCheckbox(tab, "Show Blizzard Friends Button", 
		DB:Get("showBlizzardOption", false),
		function(val) self:OnShowBlizzardOptionChanged(val) end)
	showBlizzard:SetTooltip("Show Blizzard Friends Button", "Shows the original Blizzard Friends button in the social menu")
	table.insert(allFrames, showBlizzard)
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Behavior
	local behaviorHeader = Components:CreateHeader(tab, "Behavior")
	table.insert(allFrames, behaviorHeader)
	
	-- Accordion Groups
	local accordionGroups = Components:CreateCheckbox(tab, "Accordion Mode (Only One Group Open)", 
		DB:Get("accordionGroups", true),
		function(val) self:OnAccordionGroupsChanged(val) end)
	accordionGroups:SetTooltip("Accordion Groups", "Only allow one group to be expanded at a time, automatically collapsing others")
	table.insert(allFrames, accordionGroups)
	
	-- Compact Mode
	local compactMode = Components:CreateCheckbox(tab, "Compact Mode",
		DB:Get("compactMode", false),
		function(val) self:OnCompactModeChanged(val) end)
	compactMode:SetTooltip("Compact Mode", "Reduces button height to fit more friends on screen")
	table.insert(allFrames, compactMode)
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Group Management
	local groupHeader = Components:CreateHeader(tab, "Group Management")
	table.insert(allFrames, groupHeader)
	
	-- Show Favorites Group
	local showFavorites = Components:CreateCheckbox(tab, "Show Favorites Group",
		DB:Get("showFavoritesGroup", true),
		function(val) self:OnShowFavoritesGroupChanged(val) end)
	showFavorites:SetTooltip("Show Favorites Group", "Toggle visibility of the Favorites group in your friends list")
	table.insert(allFrames, showFavorites)
	
	-- Spacer before next section
	table.insert(allFrames, Components:CreateSpacer(tab))
	
	-- Header: Font Settings
	local fontHeader = Components:CreateHeader(tab, "Font Settings")
	table.insert(allFrames, fontHeader)
	
	-- Font Size Dropdown
	local fontSizeOptions = {
		labels = {"Small", "Medium", "Large"},
		values = {"small", "medium", "large"}
	}
	local currentFontSize = DB:Get("fontSize", "medium")
	
	local function isFontSizeSelected(value)
		return value == currentFontSize
	end
	
	local function onFontSizeChanged(value)
		self:SetFontSize(value)
	end
	
	local fontSizeDropdown = Components:CreateDropdown(tab, "Font Size:", fontSizeOptions, isFontSizeSelected, onFontSizeChanged)
	table.insert(allFrames, fontSizeDropdown)
	
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
	
	-- Header: Group Order
	local orderHeader = Components:CreateHeader(tab, "Group Order")
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
					
					if BetterFriendsFrame_UpdateDisplay then
						BetterFriendsFrame_UpdateDisplay()
					end
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
					
					if BetterFriendsFrame_UpdateDisplay then
						BetterFriendsFrame_UpdateDisplay()
					end
				end
			end,
			-- Rename callback (only for non-builtin groups)
			not isBuiltin and function()
				self:RenameGroup(groupData.id, groupData.name)
			end or nil,
			-- Color callback (only for non-builtin groups)
			not isBuiltin and function(colorSwatch)
				self:ShowColorPicker(groupData.id, groupData.name, colorSwatch)
			end or nil,
			-- Delete callback (only for non-builtin groups)
			not isBuiltin and function()
				self:DeleteGroup(groupData.id, groupData.name)
			end or nil
		)
		
		-- Set initial color for custom groups
		if not isBuiltin and listItem.colorSwatch then
			local group = Groups:Get(groupData.id)
			if group and group.color then
				listItem.colorSwatch:SetColorTexture(group.color.r, group.color.g, group.color.b)
			else
				listItem.colorSwatch:SetColorTexture(1, 0.82, 0)
			end
		end
		
		-- Set arrow button states
		listItem:SetArrowState(canMoveUp, canMoveDown)
		
		table.insert(allFrames, listItem)
	end
	
	-- Anchor all frames vertically
	Components:AnchorChain(allFrames, -5)
	
	-- Store components for cleanup
	tab.components = allFrames
end

-- Refresh Advanced Tab
function Settings:RefreshAdvancedTab()
	if not settingsFrame then 
		print("RefreshAdvancedTab: settingsFrame is nil")
		return 
	end
	if not Components then 
		print("RefreshAdvancedTab: Components is nil")
		return 
	end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if not content then 
		print("RefreshAdvancedTab: content is nil")
		return 
	end
	if not content.AdvancedTab then 
		print("RefreshAdvancedTab: AdvancedTab is nil")
		return 
	end
	
	local tab = content.AdvancedTab
	
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
	local title = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, yOffset)
	title:SetText("Advanced Settings")
	table.insert(allFrames, title)
	yOffset = yOffset - 25
	
	-- Description
	local desc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 10, yOffset)
	desc:SetText("Advanced options and tools")
	table.insert(allFrames, desc)
	yOffset = yOffset - 30
	
	-- ===========================================
	-- FriendGroups Migration Section
	-- ===========================================
	local migrationHeader = Components:CreateHeader(tab, "FriendGroups Migration")
	migrationHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, migrationHeader)
	yOffset = yOffset - 25
	
	-- Migration description
	local migrationDesc1 = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	migrationDesc1:SetPoint("TOPLEFT", 10, yOffset)
	migrationDesc1:SetWidth(350)
	migrationDesc1:SetJustifyH("LEFT")
	migrationDesc1:SetWordWrap(true)
	migrationDesc1:SetText("Migrate groups and friend assignments from FriendGroups addon. This will parse group information from BattleNet notes and create corresponding groups in BetterFriendlist.")
	table.insert(allFrames, migrationDesc1)
	yOffset = yOffset - 35
	
	-- Migration button
	local migrateButton = Components:CreateButton(
		tab,
		"Migrate from FriendGroups",
		function()
			self:ShowMigrationDialog()
		end,
		"Import groups from the FriendGroups addon"
	)
	migrateButton:SetPoint("TOPLEFT", 10, yOffset)
	migrateButton:SetSize(200, 24)
	table.insert(allFrames, migrateButton)
	yOffset = yOffset - 40
	
	-- ===========================================
	-- Export / Import Section
	-- ===========================================
	local exportHeader = Components:CreateHeader(tab, "Export / Import Settings")
	exportHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, exportHeader)
	yOffset = yOffset - 25
	
	-- Export/Import description
	local exportDesc1 = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	exportDesc1:SetPoint("TOPLEFT", 10, yOffset)
	exportDesc1:SetWidth(350)
	exportDesc1:SetJustifyH("LEFT")
	exportDesc1:SetWordWrap(true)
	exportDesc1:SetText("Export your groups and friend assignments to share between characters or accounts. Perfect for players with multiple accounts who share Battle.net friends.")
	table.insert(allFrames, exportDesc1)
	yOffset = yOffset - 35
	
	local exportWarning = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	exportWarning:SetPoint("TOPLEFT", 10, yOffset)
	exportWarning:SetPoint("RIGHT", -10, 0)
	exportWarning:SetJustifyH("LEFT")
	exportWarning:SetText("|cffff0000Warning: Importing will replace ALL your groups and assignments!|r")
	table.insert(allFrames, exportWarning)
	yOffset = yOffset - 25
	
	-- Export button
	local exportButton = Components:CreateButton(
		tab,
		"Export Settings",
		function()
			self:ShowExportDialog()
		end,
		"Export your groups and friend assignments"
	)
	exportButton:SetPoint("TOPLEFT", 10, yOffset)
	exportButton:SetSize(140, 24)
	table.insert(allFrames, exportButton)
	
	-- Import button
	local importButton = Components:CreateButton(
		tab,
		"Import Settings",
		function()
			self:ShowImportDialog()
		end,
		"Import groups and friend assignments"
	)
	importButton:SetPoint("LEFT", exportButton, "RIGHT", 10, 0)
	importButton:SetSize(140, 24)
	table.insert(allFrames, importButton)
	
	yOffset = yOffset - 50
	
	-- ===========================================
	-- Beta Features Section
	-- ===========================================
	local betaHeader = Components:CreateHeader(tab, "|cffff8800Beta Features|r") -- Orange for Beta
	betaHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, betaHeader)
	yOffset = yOffset - 25
	
	-- Beta features description
	local betaDesc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	betaDesc:SetPoint("TOPLEFT", 10, yOffset)
	betaDesc:SetWidth(350)
	betaDesc:SetJustifyH("LEFT")
	betaDesc:SetWordWrap(true)
	betaDesc:SetText("Enable experimental features that are still in development. These features may change or be removed in future versions.")
	table.insert(allFrames, betaDesc)
	yOffset = yOffset - 35
	
	-- Warning icon + text (before checkbox)
	local warningIcon = tab:CreateTexture(nil, "ARTWORK")
	warningIcon:SetSize(16, 16)
	warningIcon:SetPoint("TOPLEFT", 10, yOffset)
	warningIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\alert-triangle")
	warningIcon:SetVertexColor(1, 0.65, 0)
	table.insert(allFrames, warningIcon)
	
	local warningText = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	warningText:SetPoint("LEFT", warningIcon, "RIGHT", 6, 0)
	warningText:SetWidth(330)
	warningText:SetJustifyH("LEFT")
	warningText:SetWordWrap(true)
	warningText:SetText("Beta features may contain bugs, performance issues, or incomplete functionality. Use at your own risk.")
	warningText:SetTextColor(1, 0.53, 0) -- Orange (matching Beta theme)
	table.insert(allFrames, warningText)
	yOffset = yOffset - 35
	
	-- Enable Beta Features Toggle
	local betaToggle = Components:CreateCheckbox(
		tab,
		"Enable Beta Features",
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
				print("|cff00ff00BetterFriendlist:|r Beta Features |cff00ff00ENABLED|r")
				print("|cffff8800[>]|r Beta tabs are now visible in Settings")
			else
				print("|cff00ff00BetterFriendlist:|r Beta Features |cffff0000DISABLED|r")
				print("|cffff8800[>]|r Beta tabs are now hidden")
			end
		end
	)
	betaToggle:SetPoint("TOPLEFT", 10, yOffset)
	betaToggle:SetTooltip("Beta Features", "Enable experimental features like Smart Notifications and Bulk Operations")
	table.insert(allFrames, betaToggle)
	yOffset = yOffset - 35
	
	-- Beta feature list (informational)
	local featureListTitle = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	featureListTitle:SetPoint("TOPLEFT", 10, yOffset)
	featureListTitle:SetText("Currently available Beta features:")
	featureListTitle:SetTextColor(1, 0.53, 0) -- Orange (Beta theme)
	table.insert(allFrames, featureListTitle)
	yOffset = yOffset - 20
	
	-- Feature 1: Smart Friend Notifications
	local feature1Icon = tab:CreateTexture(nil, "ARTWORK")
	feature1Icon:SetSize(14, 14)
	feature1Icon:SetPoint("TOPLEFT", 15, yOffset)
	feature1Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\bell")
	feature1Icon:SetVertexColor(1, 0.53, 0) -- Orange (Beta theme)
	table.insert(allFrames, feature1Icon)
	
	local feature1Text = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	feature1Text:SetPoint("LEFT", feature1Icon, "RIGHT", 6, 0)
	feature1Text:SetText("Smart Friend Notifications")
	table.insert(allFrames, feature1Text)
	
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
	local title = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, yOffset)
	title:SetText("Friend Network Statistics")
	table.insert(allFrames, title)
	yOffset = yOffset - 25
	
	-- Description
	local desc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 10, yOffset)
	desc:SetText("Overview of your friend network and activity")
	table.insert(allFrames, desc)
	yOffset = yOffset - 30
	
	-- ===========================================
	-- Overview Section
	-- ===========================================
	local overviewHeader = Components:CreateHeader(tab, "Overview")
	overviewHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, overviewHeader)
	yOffset = yOffset - 25
	
	-- Total Friends
	tab.TotalFriends = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tab.TotalFriends:SetPoint("TOPLEFT", 20, yOffset)
	tab.TotalFriends:SetText("Total Friends: --")
	table.insert(allFrames, tab.TotalFriends)
	yOffset = yOffset - 20
	
	-- Online/Offline
	tab.OnlineFriends = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tab.OnlineFriends:SetPoint("TOPLEFT", 20, yOffset)
	tab.OnlineFriends:SetText("Online: --  |  Offline: --")
	table.insert(allFrames, tab.OnlineFriends)
	yOffset = yOffset - 20
	
	-- Friend Types
	tab.FriendTypes = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tab.FriendTypes:SetPoint("TOPLEFT", 20, yOffset)
	tab.FriendTypes:SetText("Battle.net: --  |  WoW: --")
	table.insert(allFrames, tab.FriendTypes)
	yOffset = yOffset - 30
	
	-- Store left column start position
	local leftColumnStart = yOffset
	
	-- ===========================================
	-- LEFT COLUMN
	-- ===========================================
	
	-- Friendship Health Section
	local healthHeader = Components:CreateHeader(tab, "Friendship Health")
	healthHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, healthHeader)
	yOffset = yOffset - 25
	
	tab.FriendshipHealth = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.FriendshipHealth:SetPoint("TOPLEFT", 20, yOffset)
	tab.FriendshipHealth:SetWidth(210)
	tab.FriendshipHealth:SetJustifyH("LEFT")
	tab.FriendshipHealth:SetText("No health data available")
	table.insert(allFrames, tab.FriendshipHealth)
	yOffset = yOffset - 90
	
	-- Top 5 Classes Section
	local classHeader = Components:CreateHeader(tab, "Top 5 Classes")
	classHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, classHeader)
	yOffset = yOffset - 25
	
	tab.ClassList = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.ClassList:SetPoint("TOPLEFT", 20, yOffset)
	tab.ClassList:SetWidth(210)
	tab.ClassList:SetJustifyH("LEFT")
	tab.ClassList:SetText("No class data available")
	table.insert(allFrames, tab.ClassList)
	yOffset = yOffset - 90
	
	-- Realm Clusters Section
	local realmHeader = Components:CreateHeader(tab, "Realm Clusters")
	realmHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, realmHeader)
	yOffset = yOffset - 25
	
	tab.RealmList = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.RealmList:SetPoint("TOPLEFT", 20, yOffset)
	tab.RealmList:SetWidth(210)
	tab.RealmList:SetJustifyH("LEFT")
	tab.RealmList:SetText("No realm data available")
	table.insert(allFrames, tab.RealmList)
	yOffset = yOffset - 110
	
	-- Organization Section
	local notesHeader = Components:CreateHeader(tab, "Organization")
	notesHeader:SetPoint("TOPLEFT", 10, yOffset)
	table.insert(allFrames, notesHeader)
	yOffset = yOffset - 25
	
	tab.NotesAndFavorites = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.NotesAndFavorites:SetPoint("TOPLEFT", 20, yOffset)
	tab.NotesAndFavorites:SetWidth(210)
	tab.NotesAndFavorites:SetJustifyH("LEFT")
	tab.NotesAndFavorites:SetText("No data available")
	table.insert(allFrames, tab.NotesAndFavorites)
	yOffset = yOffset - 60
	
	-- ===========================================
	-- RIGHT COLUMN
	-- ===========================================
	yOffset = leftColumnStart
	
	-- Level Distribution Section
	local levelHeader = Components:CreateHeader(tab, "Level Distribution")
	levelHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, levelHeader)
	yOffset = yOffset - 25
	
	tab.LevelDistribution = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.LevelDistribution:SetPoint("TOPLEFT", 250, yOffset)
	tab.LevelDistribution:SetWidth(190)
	tab.LevelDistribution:SetJustifyH("LEFT")
	tab.LevelDistribution:SetText("No level data available")
	table.insert(allFrames, tab.LevelDistribution)
	yOffset = yOffset - 90
	
	-- Game Distribution Section
	local gameHeader = Components:CreateHeader(tab, "Game Distribution")
	gameHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, gameHeader)
	yOffset = yOffset - 25
	
	tab.GameDistribution = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.GameDistribution:SetPoint("TOPLEFT", 250, yOffset)
	tab.GameDistribution:SetWidth(190)
	tab.GameDistribution:SetJustifyH("LEFT")
	tab.GameDistribution:SetText("No game data available")
	table.insert(allFrames, tab.GameDistribution)
	yOffset = yOffset - 90
	
	-- Mobile vs Desktop Section
	local mobileHeader = Components:CreateHeader(tab, "Mobile vs. Desktop")
	mobileHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, mobileHeader)
	yOffset = yOffset - 25
	
	tab.MobileVsDesktop = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.MobileVsDesktop:SetPoint("TOPLEFT", 250, yOffset)
	tab.MobileVsDesktop:SetWidth(190)
	tab.MobileVsDesktop:SetJustifyH("LEFT")
	tab.MobileVsDesktop:SetText("No mobile data available")
	table.insert(allFrames, tab.MobileVsDesktop)
	yOffset = yOffset - 60
	
	-- Faction Distribution Section
	local factionHeader = Components:CreateHeader(tab, "Faction Distribution")
	factionHeader:SetPoint("TOPLEFT", 240, yOffset)
	table.insert(allFrames, factionHeader)
	yOffset = yOffset - 25
	
	tab.FactionList = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	tab.FactionList:SetPoint("TOPLEFT", 250, yOffset)
	tab.FactionList:SetWidth(190)
	tab.FactionList:SetJustifyH("LEFT")
	tab.FactionList:SetText("No faction data available")
	table.insert(allFrames, tab.FactionList)
	
	-- ===========================================
	-- Refresh Button (below Organization section)
	-- ===========================================
	local refreshButton = Components:CreateButton(
		tab,
		"Refresh Statistics",
		function()
			self:RefreshStatistics()
		end,
		"Update statistics with current data"
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
	
	-- ===========================================
	-- Header (Beta - Orange)
	-- ===========================================
	local betaHeader = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	betaHeader:SetText("|cffff8800Notifications|r") -- Orange for Beta feature
	table.insert(allFrames, betaHeader)
	
	-- Description
	local desc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	desc:SetWidth(360)
	desc:SetJustifyH("LEFT")
	desc:SetWordWrap(true)
	desc:SetText("Configure smart friend notifications. Get alerts when friends come online.")
	table.insert(allFrames, desc)
	
	-- ===========================================
	-- NOTIFICATION DISPLAY SECTION
	-- ===========================================
	local displayHeader = Components:CreateHeader(tab, "Notification Display")
	table.insert(allFrames, displayHeader)
	
	-- Display Mode Dropdown
	local displayModeOptions = {
		labels = {"Toast Notification", "Chat Message Only", "Disabled"},
		values = {"alert", "chat", "disabled"}
	}
	local currentMode = BetterFriendlistDB.notificationDisplayMode or "alert"
	
	local function isDisplayModeSelected(value)
		return value == BetterFriendlistDB.notificationDisplayMode
	end
	
	local function onDisplayModeChanged(value)
		BetterFriendlistDB.notificationDisplayMode = value
		local modeNames = {
			alert = "|cffffcc00Toast|r",
			chat = "|cffffcc00Chat|r",
			disabled = "|cffff0000DISABLED|r"
		}
		print("|cff00ff00BetterFriendlist:|r Notification mode set to " .. (modeNames[value] or value))
	end
	
	local displayModeDropdown = Components:CreateDropdown(tab, "Display Mode:", displayModeOptions, isDisplayModeSelected, onDisplayModeChanged)
	table.insert(allFrames, displayModeDropdown)
	
	-- Mode Description
	local modeDesc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	modeDesc:SetWidth(360)
	modeDesc:SetJustifyH("LEFT")
	modeDesc:SetWordWrap(true)
	modeDesc:SetText(
		"|cffffcc00Toast Notification:|r Shows a compact notification when friends come online\n" ..
		"|cffffcc00Chat Message Only:|r No popup, only shows messages in chat\n" ..
		"|cffffcc00Disabled:|r No notifications at all"
	)
	table.insert(allFrames, modeDesc)
	
	-- Test Button
	local testBtn = Components:CreateButton(
		tab,
		"Test Notification",
		function()
			if BFL.NotificationSystem and BFL.NotificationSystem.ShowTestNotification then
				BFL.NotificationSystem:ShowTestNotification()
			else
				print("|cffff0000BetterFriendlist:|r Notification system not available")
			end
		end,
		"Trigger a test notification"
	)
	testBtn:SetSize(150, 24)
	table.insert(allFrames, testBtn)
	
	-- ===========================================
	-- SOUND SETTINGS SECTION
	-- ===========================================
	local soundHeader = Components:CreateHeader(tab, "Sound Settings")
	table.insert(allFrames, soundHeader)
	
	-- Enable Sound Checkbox
	local soundToggle = Components:CreateCheckbox(
		tab,
		"Play sound with notifications",
		BetterFriendlistDB.notificationSoundEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationSoundEnabled = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r Notification sounds |cff00ff00ENABLED|r")
			else
				print("|cff00ff00BetterFriendlist:|r Notification sounds |cffff0000DISABLED|r")
			end
		end
	)
	soundToggle:SetTooltip("Notification Sounds", "Play a sound effect when notifications appear. You can test the sound using the button above.")
	table.insert(allFrames, soundToggle)
	
	-- ===========================================
	-- QUIET HOURS SECTION
	-- ===========================================
	local quietHeader = Components:CreateHeader(tab, "Quiet Hours")
	table.insert(allFrames, quietHeader)
	
	-- Manual DND Toggle
	local manualDND = Components:CreateCheckbox(
		tab,
		"Manual Do Not Disturb",
		BetterFriendlistDB.notificationQuietManual or false,
		function(checked)
			BetterFriendlistDB.notificationQuietManual = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r Manual DND |cff00ff00ENABLED|r - All notifications silenced")
			else
				print("|cff00ff00BetterFriendlist:|r Manual DND |cffff0000DISABLED|r")
			end
		end
	)
	manualDND:SetTooltip("Manual Do Not Disturb", "Manually silence all notifications until you disable this option. Takes highest priority over all other settings.")
	table.insert(allFrames, manualDND)
	
	-- Combat Toggle
	local combatQuiet = Components:CreateCheckbox(
		tab,
		"Silence during combat",
		BetterFriendlistDB.notificationQuietCombat ~= false, -- Default: true
		function(checked)
			BetterFriendlistDB.notificationQuietCombat = checked
			print("|cff00ff00BetterFriendlist:|r Combat quiet mode " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	combatQuiet:SetTooltip("Combat Silence", "Automatically silence notifications during combat encounters to avoid distractions.")
	table.insert(allFrames, combatQuiet)
	
	-- Instance Toggle
	local instanceQuiet = Components:CreateCheckbox(
		tab,
		"Silence in instances (dungeons, raids, PvP)",
		BetterFriendlistDB.notificationQuietInstance or false,
		function(checked)
			BetterFriendlistDB.notificationQuietInstance = checked
			print("|cff00ff00BetterFriendlist:|r Instance quiet mode " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
		end
	)
	instanceQuiet:SetTooltip("Instance Silence", "Silence notifications when you are in dungeons, raids, battlegrounds, or arenas.")
	table.insert(allFrames, instanceQuiet)
	
	-- Scheduled Quiet Hours Toggle
	local scheduledQuiet = Components:CreateCheckbox(
		tab,
		"Scheduled quiet hours",
		BetterFriendlistDB.notificationQuietScheduled or false,
		function(checked)
			BetterFriendlistDB.notificationQuietScheduled = checked
			print("|cff00ff00BetterFriendlist:|r Scheduled quiet hours " .. (checked and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
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
		"Start Time:",
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
		"End Time:",
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
	local scheduleInfo = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	scheduleInfo:SetWidth(360)
	scheduleInfo:SetJustifyH("LEFT")
	scheduleInfo:SetWordWrap(true)
	scheduleInfo:SetTextColor(0.7, 0.7, 0.7)
	scheduleInfo:SetText("|cffffcc00Note:|r If start hour is greater than end hour, the schedule crosses midnight (e.g., 22:00-08:00).")
	table.insert(allFrames, scheduleInfo)
	
	-- ===========================================
	-- OFFLINE NOTIFICATIONS SECTION
	-- ===========================================
	local offlineHeader = Components:CreateHeader(tab, "Offline Notifications")
	table.insert(allFrames, offlineHeader)
	
	-- Offline Notifications Toggle
	local offlineToggle = Components:CreateCheckbox(
		tab,
		"Show notifications when friends go offline",
		BetterFriendlistDB.notificationOfflineEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationOfflineEnabled = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r Offline notifications |cff00ff00ENABLED|r")
			else
				print("|cff00ff00BetterFriendlist:|r Offline notifications |cffff0000DISABLED|r")
			end
		end
	)
	offlineToggle:SetTooltip("Offline Notifications", "Show notifications when friends log off. These are independent from online notifications and respect all quiet hours settings.")
	table.insert(allFrames, offlineToggle)
	
	-- ===========================================
	-- GAME-SPECIFIC NOTIFICATIONS SECTION (Phase 11.5)
	-- ===========================================
	local gameSpecificHeader = Components:CreateHeader(tab, "Game-Specific Notifications")
	table.insert(allFrames, gameSpecificHeader)
	
	-- WoW Login Toggle
	local wowLoginToggle = Components:CreateCheckbox(
		tab,
		"WoW Login: Notify when friend logs into World of Warcraft",
		BetterFriendlistDB.notificationWowLoginEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationWowLoginEnabled = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r WoW Login notifications |cff00ff00ENABLED|r")
			else
				print("|cff00ff00BetterFriendlist:|r WoW Login notifications |cffff0000DISABLED|r")
			end
		end
	)
	wowLoginToggle:SetTooltip("WoW Login Notifications", "Get notified when a Battle.net friend starts World of Warcraft (even if they were already online in another game).")
	table.insert(allFrames, wowLoginToggle)
	
	-- Character Switch Toggle
	local charSwitchToggle = Components:CreateCheckbox(
		tab,
		"Character Switch: Notify when friend changes character",
		BetterFriendlistDB.notificationCharSwitchEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationCharSwitchEnabled = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r Character switch notifications |cff00ff00ENABLED|r")
			else
				print("|cff00ff00BetterFriendlist:|r Character switch notifications |cffff0000DISABLED|r")
			end
		end
	)
	charSwitchToggle:SetTooltip("Character Switch Notifications", "Get notified when a friend switches to a different character in World of Warcraft.")
	table.insert(allFrames, charSwitchToggle)
	
	-- Game Switch Toggle
	local gameSwitchToggle = Components:CreateCheckbox(
		tab,
		"Game Switch: Notify when friend changes game",
		BetterFriendlistDB.notificationGameSwitchEnabled or false,
		function(checked)
			BetterFriendlistDB.notificationGameSwitchEnabled = checked
			if checked then
				print("|cff00ff00BetterFriendlist:|r Game switch notifications |cff00ff00ENABLED|r")
			else
				print("|cff00ff00BetterFriendlist:|r Game switch notifications |cffff0000DISABLED|r")
			end
		end
	)
	gameSwitchToggle:SetTooltip("Game Switch Notifications", "Get notified when a friend switches from WoW to another Battle.net game (Diablo, Overwatch, etc.).")
	table.insert(allFrames, gameSwitchToggle)
	
	-- ===========================================
	-- CUSTOM MESSAGES SECTION (Phase 11)
	-- ===========================================
	local messagesHeader = Components:CreateHeader(tab, "Custom Messages")
	table.insert(allFrames, messagesHeader)
	
	local messagesDesc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	messagesDesc:SetWidth(360)
	messagesDesc:SetJustifyH("LEFT")
	messagesDesc:SetWordWrap(true)
	messagesDesc:SetTextColor(0.7, 0.7, 0.7)
	messagesDesc:SetText("Customize notification messages. Available variables: %name%, %game%, %level%, %zone%, %class%, %realm%, %char%, %prevchar%")
	table.insert(allFrames, messagesDesc)
	
	-- Online Message Label
	local onlineMsgLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	onlineMsgLabel:SetText("Online Message:")
	onlineMsgLabel:SetPoint("LEFT", 0, 0)
	table.insert(allFrames, onlineMsgLabel)
	
	-- Online Message EditBox
	local onlineMsgBox = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	onlineMsgBox:SetSize(340, 25)
	onlineMsgBox:SetAutoFocus(false)
	onlineMsgBox:SetText(BetterFriendlistDB.notificationMessageOnline or "%name% is now online")
	onlineMsgBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	onlineMsgBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	onlineMsgBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			BetterFriendlistDB.notificationMessageOnline = text
		end
	end)
	table.insert(allFrames, onlineMsgBox)
	
	-- Offline Message Label
	local offlineMsgLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	offlineMsgLabel:SetText("Offline Message:")
	offlineMsgLabel:SetPoint("LEFT", 0, 0)
	table.insert(allFrames, offlineMsgLabel)
	
	-- Offline Message EditBox
	local offlineMsgBox = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	offlineMsgBox:SetSize(340, 25)
	offlineMsgBox:SetAutoFocus(false)
	offlineMsgBox:SetText(BetterFriendlistDB.notificationMessageOffline or "%name% went offline")
	offlineMsgBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	offlineMsgBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	offlineMsgBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			BetterFriendlistDB.notificationMessageOffline = text
		end
	end)
	table.insert(allFrames, offlineMsgBox)
	
	-- WoW Login Message Label (Phase 11.5)
	local wowLoginMsgLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	wowLoginMsgLabel:SetText("WoW Login Message:")
	wowLoginMsgLabel:SetPoint("LEFT", 0, 0)
	table.insert(allFrames, wowLoginMsgLabel)
	
	-- WoW Login Message EditBox
	local wowLoginMsgBox = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	wowLoginMsgBox:SetSize(340, 25)
	wowLoginMsgBox:SetAutoFocus(false)
	wowLoginMsgBox:SetText(BetterFriendlistDB.notificationMessageWowLogin or "%name% logged into World of Warcraft")
	wowLoginMsgBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	wowLoginMsgBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	wowLoginMsgBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			BetterFriendlistDB.notificationMessageWowLogin = text
		end
	end)
	table.insert(allFrames, wowLoginMsgBox)
	
	-- Character Switch Message Label
	local charSwitchMsgLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	charSwitchMsgLabel:SetText("Character Switch Message:")
	charSwitchMsgLabel:SetPoint("LEFT", 0, 0)
	table.insert(allFrames, charSwitchMsgLabel)
	
	-- Character Switch Message EditBox
	local charSwitchMsgBox = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	charSwitchMsgBox:SetSize(340, 25)
	charSwitchMsgBox:SetAutoFocus(false)
	charSwitchMsgBox:SetText(BetterFriendlistDB.notificationMessageCharSwitch or "%name% switched to %char%")
	charSwitchMsgBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	charSwitchMsgBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	charSwitchMsgBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			BetterFriendlistDB.notificationMessageCharSwitch = text
		end
	end)
	table.insert(allFrames, charSwitchMsgBox)
	
	-- Game Switch Message Label
	local gameSwitchMsgLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	gameSwitchMsgLabel:SetText("Game Switch Message:")
	gameSwitchMsgLabel:SetPoint("LEFT", 0, 0)
	table.insert(allFrames, gameSwitchMsgLabel)
	
	-- Game Switch Message EditBox
	local gameSwitchMsgBox = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	gameSwitchMsgBox:SetSize(340, 25)
	gameSwitchMsgBox:SetAutoFocus(false)
	gameSwitchMsgBox:SetText(BetterFriendlistDB.notificationMessageGameSwitch or "%name% is now playing %game%")
	gameSwitchMsgBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	gameSwitchMsgBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	gameSwitchMsgBox:SetScript("OnEditFocusLost", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			BetterFriendlistDB.notificationMessageGameSwitch = text
		end
	end)
	table.insert(allFrames, gameSwitchMsgBox)
	
	-- Preview Info Text
	local previewInfo = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	previewInfo:SetWidth(360)
	previewInfo:SetJustifyH("LEFT")
	previewInfo:SetWordWrap(true)
	previewInfo:SetTextColor(0.7, 0.7, 0.7)
	previewInfo:SetText("|cffffcc00Tip:|r Use the 'Test Notification' button above to preview your custom messages.")
	table.insert(allFrames, previewInfo)
	
	-- ===========================================
	-- GROUP TRIGGERS SECTION (Phase 10)
	-- ===========================================
	local triggersHeader = Components:CreateHeader(tab, "Group Triggers")
	table.insert(allFrames, triggersHeader)
	
	local triggersDesc = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	triggersDesc:SetWidth(360)
	triggersDesc:SetJustifyH("LEFT")
	triggersDesc:SetWordWrap(true)
	triggersDesc:SetTextColor(0.7, 0.7, 0.7)
	triggersDesc:SetText("Get notified when a certain number of friends from a group come online. Example: Alert when 3+ M+ team members are online.")
	table.insert(allFrames, triggersDesc)
	
	-- Trigger list container
	local triggerListContainer = CreateFrame("Frame", nil, tab)
	triggerListContainer:SetSize(360, 100)
	table.insert(allFrames, triggerListContainer)
	
	-- Function to refresh trigger list
	local function RefreshTriggerList()
		-- Clear existing children
		for _, child in ipairs({triggerListContainer:GetChildren()}) do
			child:Hide()
			child:SetParent(nil)
		end
		
		-- Clear all font strings (includes the "No triggers" message)
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
		
		-- Show each trigger
		for triggerID, trigger in pairs(BetterFriendlistDB.notificationGroupTriggers) do
			local triggerFrame = CreateFrame("Frame", nil, triggerListContainer)
			triggerFrame:SetSize(360, 25)
			triggerFrame:SetPoint("TOPLEFT", triggerListContainer, "TOPLEFT", 0, yOffset)
			
			-- Get group name
			local group = Groups and Groups:Get(trigger.groupId)
			local groupName = group and group.name or trigger.groupId
			
			-- Trigger label
			local label = triggerFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			label:SetPoint("LEFT", triggerFrame, "LEFT", 0, 0)
			label:SetText(string.format("%d+ from '%s'", trigger.threshold, groupName))
			
			-- Enable/Disable toggle
			local enableBtn = CreateFrame("CheckButton", nil, triggerFrame, "SettingsCheckboxTemplate")
			enableBtn:SetPoint("RIGHT", triggerFrame, "RIGHT", -40, 0)
			enableBtn:SetSize(20, 20)
			enableBtn:SetChecked(trigger.enabled)
			enableBtn:SetScript("OnClick", function(self)
				trigger.enabled = self:GetChecked()
				print("|cff00ff00BetterFriendlist:|r Group trigger " .. (trigger.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
			end)
			
			-- Delete button
			local deleteBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
			deleteBtn:SetSize(20, 20)
			deleteBtn:SetPoint("RIGHT", triggerFrame, "RIGHT", 0, 0)
			deleteBtn:SetText("X")
			deleteBtn:SetScript("OnClick", function()
				BetterFriendlistDB.notificationGroupTriggers[triggerID] = nil
				RefreshTriggerList()
				print("|cff00ff00BetterFriendlist:|r Group trigger removed")
			end)
			
			yOffset = yOffset - 30
		end
		
		-- Show "No triggers" message if empty
		if next(BetterFriendlistDB.notificationGroupTriggers) == nil then
			local emptyText = triggerListContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			emptyText:SetPoint("TOPLEFT", triggerListContainer, "TOPLEFT", 0, 0)
			emptyText:SetTextColor(0.5, 0.5, 0.5)
			emptyText:SetText("No group triggers configured. Click 'Add Trigger' below.")
		end
	end
	
	-- Add Trigger button
	local addTriggerBtn = CreateFrame("Button", nil, tab, "UIPanelButtonTemplate")
	addTriggerBtn:SetSize(120, 25)
	addTriggerBtn:SetText("Add Trigger")
	addTriggerBtn:SetScript("OnClick", function()
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
	local yPos = -15
	local frameIndex = 1
	
	-- BETA Header (1)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Description (2)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 45
	frameIndex = frameIndex + 1
	
	-- Notification Display Header (3)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 50
	frameIndex = frameIndex + 1
	
	-- Display Mode Dropdown (4)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Mode Description (5)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 50
	frameIndex = frameIndex + 1
	
	-- Test Button (6)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Sound Settings Header (7)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Sound Toggle Checkbox (8)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Quiet Hours Header (9)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Manual DND Toggle (10)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Combat Quiet Toggle (11)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Instance Quiet Toggle (12)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Scheduled Quiet Toggle (13)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Start Hour Slider (14)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- End Hour Slider (15)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Schedule Info Text (16)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Offline Notifications Header (17)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Offline Toggle (18)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Game-Specific Notifications Header (19) [Phase 11.5]
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- WoW Login Toggle (20)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Character Switch Toggle (21)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 25
	frameIndex = frameIndex + 1
	
	-- Game Switch Toggle (22)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Custom Messages Header (23)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Custom Messages Description (24)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 45
	frameIndex = frameIndex + 1
	
	-- Online Message Label (25)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 20
	frameIndex = frameIndex + 1
	
	-- Online Message EditBox (26)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Offline Message Label (27)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 20
	frameIndex = frameIndex + 1
	
	-- Offline Message EditBox (28)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- WoW Login Message Label (29) [Phase 11.5]
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 20
	frameIndex = frameIndex + 1
	
	-- WoW Login Message EditBox (30)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Character Switch Message Label (31)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 20
	frameIndex = frameIndex + 1
	
	-- Character Switch Message EditBox (32)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Game Switch Message Label (33)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 20
	frameIndex = frameIndex + 1
	
	-- Game Switch Message EditBox (34)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Preview Info Text (35)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 35
	frameIndex = frameIndex + 1
	
	-- Group Triggers Header (36)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 30
	frameIndex = frameIndex + 1
	
	-- Group Triggers Description (37)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 45
	frameIndex = frameIndex + 1
	
	-- Trigger List Container (38)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 110
	frameIndex = frameIndex + 1
	
	-- Add Trigger Button (39)
	allFrames[frameIndex]:SetPoint("TOPLEFT", tab, "TOPLEFT", 10, yPos)
	yPos = yPos - 40
	frameIndex = frameIndex + 1
	
	-- Store components for cleanup
	tab.components = allFrames
end

return Settings

