-- Settings.lua
-- Settings panel and configuration management module

local ADDON_NAME, BFL = ...

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
	button:GetNormalTexture():SetAlpha(0.3)
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	button:GetHighlightTexture():SetAlpha(0.7)
	
	-- Background
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
	
	-- Drag Handle (:::)
	button.dragHandle = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.dragHandle:SetPoint("LEFT", 5, 0)
	button.dragHandle:SetText(":::")
	button.dragHandle:SetTextColor(0.5, 0.5, 0.5)
	
	-- Order Number
	button.orderText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.orderText:SetPoint("LEFT", button.dragHandle, "RIGHT", 10, 0)
	button.orderText:SetText(orderIndex)
	button.orderText:SetTextColor(0.7, 0.7, 0.7)
	
	-- Group Name
	button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.nameText:SetPoint("LEFT", button.orderText, "RIGHT", 15, 0)
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
		bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
		
		local texture = button.editButton:CreateTexture(nil, "ARTWORK")
		texture:SetSize(20, 20)
		texture:SetPoint("CENTER")
		texture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		button.editButton.texture = texture
		
		button.editButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
		local highlightTex = button.editButton:GetHighlightTexture()
		if highlightTex then
			highlightTex:SetSize(20, 20)
			highlightTex:SetPoint("CENTER")
		end
		
		button.editButton:SetScript("OnClick", function(self)
			StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, groupId)
		end)
		
		button.editButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Rename Group", 1, 1, 1)
			GameTooltip:AddLine("Click to rename this group", 0.8, 0.8, 0.8, true)
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
	button.colorSwatch:SetPoint("TOPLEFT", button.colorButton, "TOPLEFT", 2, -2)
	button.colorSwatch:SetPoint("BOTTOMRIGHT", button.colorButton, "BOTTOMRIGHT", -2, 2)
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
		GameTooltip:SetText("Group Color", 1, 1, 1)
		GameTooltip:AddLine("Click to change the color of this group", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	
	button.colorButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Delete Button (only for custom groups)
	if not isBuiltIn then
		button.deleteButton = CreateFrame("Button", nil, button)
		button.deleteButton:SetSize(20, 20)
		button.deleteButton:SetPoint("RIGHT", -10, 0)
		
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
			GameTooltip:SetText("Delete Group", 1, 0.2, 0.2)
			GameTooltip:AddLine("Remove this group and unassign all friends", 0.8, 0.8, 0.8, true)
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
		self:SetAlpha(0.5)
		
		self:SetScript("OnUpdate", function(updateSelf)
			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			cursorX = cursorX / scale
			cursorY = cursorY / scale
			
			for _, btn in ipairs(groupButtons) do
				if btn ~= updateSelf then
					btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
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
			btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
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
			self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
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
		settingsFrame:Show()
		self:ShowTab(1)
	else
		print("|cffff0000BetterFriendlist Settings:|r Frame not initialized!")
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
	settingsFrame.numTabs = 5
	PanelTemplates_SetTab(settingsFrame, tabID)
	
	local content = settingsFrame.ContentScrollFrame.Content
	if content then
		if content.GeneralTab then content.GeneralTab:Hide() end
		if content.GroupsTab then content.GroupsTab:Hide() end
		if content.AppearanceTab then content.AppearanceTab:Hide() end
		if content.AdvancedTab then content.AdvancedTab:Hide() end
		if content.StatisticsTab then content.StatisticsTab:Hide() end
		
		if tabID == 1 and content.GeneralTab then
			content.GeneralTab:Show()
		elseif tabID == 2 and content.GroupsTab then
			content.GroupsTab:Show()
			self:RefreshGroupList()
		elseif tabID == 3 and content.AppearanceTab then
			content.AppearanceTab:Show()
		elseif tabID == 4 and content.AdvancedTab then
			content.AdvancedTab:Show()
		elseif tabID == 5 and content.StatisticsTab then
			content.StatisticsTab:Show()
			self:RefreshStatistics()
		end
	end
end

-- Load settings from database into UI
function Settings:LoadSettings()
	local DB = GetDB()
	if not DB then return end
	
	local content = settingsFrame.ContentScrollFrame.Content
	if content and content.GeneralTab then
		local generalTab = content.GeneralTab
		
		if generalTab.ShowBlizzardOption then
			local value = DB:Get("showBlizzardOption", false)
			generalTab.ShowBlizzardOption:SetChecked(value)
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
		
		if appearanceTab.FontSizeSection then
			self:InitFontSizeDropdown()
		end
	end
end

-- Initialize font size dropdown
function Settings:InitFontSizeDropdown()
	if not settingsFrame or not settingsFrame.ContentScrollFrame or not settingsFrame.ContentScrollFrame.Content then return end
	
	local dropdown = settingsFrame.ContentScrollFrame.Content.AppearanceTab.FontSizeSection.Dropdown
	if not dropdown then return end
	
	local DB = GetDB()
	if not DB then return end
	
	local currentFontSize = DB:Get("fontSize", "normal")
	dropdown:SetDefaultText("Normal (12px)")
	
	dropdown:SetupMenu(function(owner, rootDescription)
		-- Small option (10px)
		rootDescription:CreateRadio("Small (Compact, 10px)",
			function() return currentFontSize == "small" end,
			function() Settings:SetFontSize("small") end
		)
		
		-- Normal option (12px)
		rootDescription:CreateRadio("Normal (12px)",
			function() return currentFontSize == "normal" end,
			function() Settings:SetFontSize("normal") end
		)
		
		-- Large option (14px)
		rootDescription:CreateRadio("Large (14px)",
			function() return currentFontSize == "large" end,
			function() Settings:SetFontSize("large") end
		)
	end)
end

-- Set font size and save immediately
function Settings:SetFontSize(size)
	local DB = GetDB()
	if not DB then return end
	
	DB:Set("fontSize", size)
	
	if BetterFriendsFrame_UpdateDisplay then
		BetterFriendsFrame_UpdateDisplay()
	end
	
	-- Refresh dropdown to show new selection
	self:InitFontSizeDropdown()
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
	
	print("|cff20ff20BetterFriendlist:|r Settings reset to defaults!")
end

-- Refresh the group list in the Groups tab
function Settings:RefreshGroupList()
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
	
	local yOffset = -5
	for i, groupData in ipairs(orderedGroups) do
		local button = CreateGroupButton(container, groupData.id, groupData.name, i)
		button:SetPoint("TOPLEFT", 5, yOffset)
		button:Show()
		table.insert(groupButtons, button)
		yOffset = yOffset - 34
	end
	
	container:SetHeight(math.max(1, #orderedGroups * 34 + 10))
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
		print("|cff20ff20BetterFriendlist:|r Group order saved!")
		
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
				print("|cff00ff00BetterFriendlist:|r Group '" .. groupName .. "' deleted")
				
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

-- Migrate from FriendGroups addon
function Settings:MigrateFriendGroups(cleanupNotes)
	local DB = GetDB()
	local Groups = GetGroups()
	
	if not DB or not Groups then
		print("|cffff0000BetterFriendlist:|r Migration failed - modules not loaded!")
		return
	end
	
	print("|cff00ffffBetterFriendlist:|r Starting FriendGroups migration...")
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
			local name = info.name
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
					print("|cffffff00BetterFriendlist:|r   ⚠ Existing:", groupName, "(using existing group)")
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
	
	local cleanupMsg = cleanupNotes and "\n|cff00ff00Notes cleaned up!|r" or "\n|cffffff00Notes preserved (you can clean them manually).|r"
	
	print("|cff00ff00═══════════════════════════════════════")
	print("|cff00ff00BetterFriendlist: Migration Complete!")
	print("|cff00ff00═══════════════════════════════════════")
	print(string.format(
		"|cff00ffffFriends processed:|r %d\n" ..
		"|cff00ffffGroups created:|r %d\n" ..
		"|cff00ffffAssignments made:|r %d%s",
		migratedFriends,
		numGroups,
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
		text = "Migrate friend groups from FriendGroups to BetterFriendlist?\n\nThis will:\n• Create all groups from BNet notes\n• Assign friends to their groups\n• Optionally clean up notes\n\n|cffff0000Warning: This cannot be undone!|r",
		button1 = "Migrate & Clean Notes",
		button2 = "Migrate Only",
		button3 = "Cancel",
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
		for friendUID, groups in pairs(BetterFriendlistDB.friendGroups) do
			friendCount = friendCount + 1
			totalAssignments = totalAssignments + #groups
			-- Filter out non-string keys before concat
			local stringKeys = {}
			for _, v in ipairs(groups) do
				if type(v) == "string" then
					table.insert(stringKeys, v)
				end
			end
			print(string.format("|cff00ffffBetterFriendlist Debug:|r   %s -> [%s]", friendUID, table.concat(stringKeys, ", ")))
		end
		print("|cff00ffffBetterFriendlist Debug:|r Total friends:", friendCount)
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
	
	-- Reload Groups module
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
		if depth > 10 then return "nil" end -- Prevent infinite recursion
		
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
	local hex = ""
	for i = 1, #str do
		hex = hex .. string.format("%02x", string.byte(str, i))
	end
	return "BFL1:" .. hex -- BFL1: prefix for version identification
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
	local str = ""
	for i = 1, #hex, 2 do
		local byte = tonumber(string.sub(hex, i, i+1), 16)
		if not byte then
			return nil
		end
		str = str .. string.char(byte)
	end
	
	return str
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
	
	-- Update Overview section
	if statsTab.TotalFriends then
		statsTab.TotalFriends:SetText(string.format("Total Friends: %d", stats.totalFriends))
	end
	
	if statsTab.OnlineFriends then
		statsTab.OnlineFriends:SetText(string.format("|cff00ff00Online: %d|r  |  |cff808080Offline: %d|r", 
			stats.onlineFriends, stats.offlineFriends))
	end
	
	if statsTab.FriendTypes then
		statsTab.FriendTypes:SetText(string.format("|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r", 
			stats.bnetFriends, stats.wowFriends))
	end
	
	-- Update Top 5 Classes
	if statsTab.ClassList then
		local topClasses = Statistics:GetTopClasses(5)
		if topClasses and #topClasses > 0 then
			local classText = ""
			for i, class in ipairs(topClasses) do
				if i > 1 then classText = classText .. "\n" end
				classText = classText .. string.format("%d. %s: %d", i, class.name, class.count)
			end
			statsTab.ClassList:SetText(classText)
		else
			statsTab.ClassList:SetText("No class data available")
		end
	end
	
	-- Update Top 5 Realms
	if statsTab.RealmList then
		local topRealms = Statistics:GetTopRealms(5)
		if topRealms and #topRealms > 0 then
			local realmText = ""
			for i, realm in ipairs(topRealms) do
				if i > 1 then realmText = realmText .. "\n" end
				realmText = realmText .. string.format("%d. %s: %d", i, realm.name, realm.count)
			end
			statsTab.RealmList:SetText(realmText)
		else
			statsTab.RealmList:SetText("No realm data available")
		end
	end
	
	-- Update Faction Distribution
	if statsTab.FactionList then
		local factionText = string.format(
			"|cff0080ffAlliance: %d|r\n|cffff0000Horde: %d|r\n|cff808080Unknown: %d|r",
			stats.factionCounts.Alliance or 0,
			stats.factionCounts.Horde or 0,
			stats.factionCounts.Unknown or 0
		)
		statsTab.FactionList:SetText(factionText)
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
	scrollFrame:SetPoint("TOPLEFT", 10, -60)
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
	scrollFrame:SetPoint("TOPLEFT", 10, -80)
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

return Settings
