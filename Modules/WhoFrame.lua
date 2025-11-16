-- Modules/WhoFrame.lua
-- WHO Frame System Module
-- Manages WHO search, display, sorting, and selection

local ADDON_NAME, BFL = ...

-- Register Module
local WhoFrame = BFL:RegisterModule("WhoFrame", {})

-- ========================================
-- Module Dependencies
-- ========================================

-- No direct dependencies, but uses global WoW API

-- ========================================
-- Local Variables
-- ========================================

-- WHO constants
local MAX_WHOS_FROM_SERVER = 50

-- WHO sort values
local whoSortValue = 1  -- 1=Zone, 2=Guild, 3=Race

-- Data Provider
local whoDataProvider = nil

-- Selected WHO button
local selectedWhoButton = nil

-- Font cache for performance
local cachedFontHeight = nil
local cachedExtent = nil

-- ========================================
-- Module Lifecycle
-- ========================================

function WhoFrame:Initialize()
	-- Register event callback for WHO list updates
	BFL:RegisterEventCallback("WHO_LIST_UPDATE", function(...)
		self:OnWhoListUpdate(...)
	end, 10)
end

-- Handle WHO_LIST_UPDATE event
function WhoFrame:OnWhoListUpdate(...)
	-- Update will be triggered by the UI if WHO frame is visible
	-- This callback ensures the module is aware of the event
end

-- ========================================
-- WHO Frame Core Functions
-- ========================================

-- Initialize Who Frame with ScrollBox
function WhoFrame:OnLoad(frame)
	-- Initialize ScrollBox with DataProvider
	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("BetterWhoListButtonTemplate", function(button, elementData)
		self:InitButton(button, elementData)
	end)
	
	-- PERFORMANCE: Cache font height calculation (all buttons use same font)
	view:SetElementExtentCalculator(function(dataIndex, elementData)
		-- Cache font height to avoid repeated GetFontInfo calls
		if not cachedFontHeight then
			local fontObj = elementData.fontObject or GameFontNormalSmall
			cachedFontHeight = GetFontInfo(fontObj).height
			local padding = cachedFontHeight + 2
			cachedExtent = cachedFontHeight + padding
		end
		return cachedExtent
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)
	
	-- Create DataProvider
	whoDataProvider = CreateDataProvider()
	frame.ScrollBox:SetDataProvider(whoDataProvider)
	
	-- Initialize selected who
	frame.selectedWho = nil
	frame.selectedName = ""
end

-- Initialize individual Who button
function WhoFrame:InitButton(button, elementData)
	local index = elementData.index
	local info = elementData.info
	button.index = index
	
	-- PERFORMANCE: Cache class color lookup
	local classTextColor = info.filename and RAID_CLASS_COLORS[info.filename] or HIGHLIGHT_FONT_COLOR
	
	-- Process Timerunning icon for name display
	local name = info.fullName
	if info.timerunningSeasonID then
		-- Always regenerate name with icon (don't cache old names)
		if TimerunningUtil and TimerunningUtil.AddTinyIcon then
			name = TimerunningUtil.AddTinyIcon(name)
		end
	end
	
	-- Set button text
	button.Name:SetText(name)
	button.Level:SetText(info.level)
	button.Class:SetText(info.classStr or "")
	if classTextColor then
		button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
	end
	
	-- Variable column based on sort
	local variableText
	if whoSortValue == 2 then
		variableText = info.fullGuildName
	elseif whoSortValue == 3 then
		variableText = info.raceStr
	else
		variableText = info.area
	end
	button.Variable:SetText(variableText or "")
	
	-- PERFORMANCE: Defer tooltip checks until OnEnter instead of every update
	-- Store raw data for tooltip generation on hover
	button.tooltipInfo = {
		fullName = info.fullName,
		level = info.level,
		variableText = variableText
	}
	
	-- Update selection state
	local selected = BetterFriendsFrame.WhoFrame.selectedWho == index
	self:SetButtonSelected(button, selected)
end

-- Send Who request
function WhoFrame:SendWhoRequest(text)
	if not text or text == "" then
		-- Use default Who command if no text provided
		local level = UnitLevel("player")
		local minLevel = level - 3
		if minLevel <= 0 then
			minLevel = 1
		end
		local maxLevel = math.min(level + 3, GetMaxPlayerLevel())
		text = "z-\""..GetRealZoneText().."\" "..minLevel.."-"..maxLevel
	end
	
	-- CRITICAL: Ensure FriendsFrame is unregistered from WHO_LIST_UPDATE
	if FriendsFrame then
		FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
		
		-- Hide Blizzard's Who Frame BEFORE sending request
		if FriendsFrame.WhoFrame then
			FriendsFrame.WhoFrame:Hide()
		end
	end
	
	-- CRITICAL: Set Who routing IMMEDIATELY before each SendWho call
	C_FriendList.SetWhoToUi(true)
	
	C_FriendList.SendWho(text)
end

-- Update Who list display
function WhoFrame:Update(forceRebuild)
	if not BetterFriendsFrame or not BetterFriendsFrame.WhoFrame or not whoDataProvider then
		return
	end
	
	local numWhos, totalCount = C_FriendList.GetNumWhoResults()
	
	-- Update totals text
	local displayedText = ""
	if totalCount > MAX_WHOS_FROM_SERVER then
		displayedText = format(WHO_FRAME_SHOWN_TEMPLATE or "Showing %d", MAX_WHOS_FROM_SERVER)
	end
	
	local totalsText = format(WHO_FRAME_TOTAL_TEMPLATE or "Total: %d", totalCount)
	if displayedText ~= "" then
		totalsText = totalsText .. "  " .. displayedText
	end
	BetterFriendsFrame.WhoFrame.ListInset.Totals:SetText(totalsText)
	
	-- PERFORMANCE: Only rebuild if count changed OR if forced (e.g., dropdown change)
	local currentSize = whoDataProvider:GetSize()
	if not forceRebuild and currentSize == numWhos and currentSize > 0 then
		-- Data count unchanged, ScrollBox will automatically refresh from DataProvider
		-- No need to Flush and rebuild - just return
		return
	end
	
	-- If a sort is active, delegate to SortByColumn instead of building unsorted
	if BetterFriendsFrame.WhoFrame.currentSort then
		-- Re-apply current sort - it will rebuild the DataProvider sorted
		-- Use preserveDirection=true to avoid toggling
		self:SortByColumn(BetterFriendsFrame.WhoFrame.currentSort, true)
		return
	end
	
	-- No sort active: build unsorted list
	whoDataProvider:Flush()
	
	-- PERFORMANCE: Cache fontObject reference instead of string lookup
	local fontObj = GameFontNormalSmall
	
	for i = 1, numWhos do
		local info = C_FriendList.GetWhoInfo(i)
		if info then
			-- Strip trailing dash from names (WoW API bug)
			if info.fullName then
				info.fullName = info.fullName:gsub("%-$", "")
			end
			if info.name then
				info.name = info.name:gsub("%-$", "")
			end
			-- Add fontObject reference (not string) for extent calculator
			whoDataProvider:Insert({
				index = i,
				info = info,
				fontObject = fontObj
			})
		end
	end
end

-- Set selected Who button
function WhoFrame:SetSelectedButton(button)
	if selectedWhoButton then
		self:SetButtonSelected(selectedWhoButton, false)
	end
	
	selectedWhoButton = button
	BetterFriendsFrame.WhoFrame.selectedWho = button and button.index or nil
	BetterFriendsFrame.WhoFrame.selectedName = button and button.Name:GetText() or ""
	
	if button then
		self:SetButtonSelected(button, true)
	end
	
	-- Enable/disable buttons based on selection
	if BetterFriendsFrame.WhoFrame.selectedWho then
		BetterFriendsFrame.WhoFrame.GroupInviteButton:Enable()
		BetterFriendsFrame.WhoFrame.AddFriendButton:Enable()
	else
		BetterFriendsFrame.WhoFrame.GroupInviteButton:Disable()
		BetterFriendsFrame.WhoFrame.AddFriendButton:Disable()
	end
end

-- Set button selection visual state
function WhoFrame:SetButtonSelected(button, selected)
	if selected then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
end

-- Sort by column
function WhoFrame:SortByColumn(sortType, preserveDirection)
	-- Store current sort type for client-side sorting
	if not BetterFriendsFrame.WhoFrame.currentSort then
		BetterFriendsFrame.WhoFrame.currentSort = "name"
		BetterFriendsFrame.WhoFrame.sortAscending = true
	end
	
	-- Toggle sort direction if clicking same column (unless preserveDirection is true)
	if not preserveDirection and BetterFriendsFrame.WhoFrame.currentSort == sortType then
		BetterFriendsFrame.WhoFrame.sortAscending = not BetterFriendsFrame.WhoFrame.sortAscending
	elseif not preserveDirection then
		BetterFriendsFrame.WhoFrame.currentSort = sortType
		BetterFriendsFrame.WhoFrame.sortAscending = true
	end
	
	-- Always update currentSort when preserveDirection is true (for re-sorting)
	if preserveDirection then
		BetterFriendsFrame.WhoFrame.currentSort = sortType
	end
	
	-- Client-side sort: Get all WHO data and sort it locally
	local numWhos = C_FriendList.GetNumWhoResults()
	if numWhos == 0 then
		return
	end
	
	-- Collect all WHO data
	local whoData = {}
	for i = 1, numWhos do
		local info = C_FriendList.GetWhoInfo(i)
		if info then
			table.insert(whoData, {index = i, info = info})
		end
	end
	
	-- Sort the data based on sort type
	table.sort(whoData, function(a, b)
		local aVal, bVal
		
		if sortType == "name" then
			aVal = a.info.fullName or ""
			bVal = b.info.fullName or ""
		elseif sortType == "level" then
			aVal = a.info.level or 0
			bVal = b.info.level or 0
		elseif sortType == "class" then
			aVal = a.info.classStr or ""
			bVal = b.info.classStr or ""
		elseif sortType == "zone" then
			aVal = a.info.area or ""
			bVal = b.info.area or ""
		elseif sortType == "guild" then
			aVal = a.info.guild or ""
			bVal = b.info.guild or ""
		elseif sortType == "race" then
			aVal = a.info.raceStr or ""
			bVal = b.info.raceStr or ""
		end
		
		-- Apply sort direction
		if BetterFriendsFrame.WhoFrame.sortAscending then
			return aVal < bVal
		else
			return aVal > bVal
		end
	end)
	
	-- Rebuild DataProvider with sorted data
	if whoDataProvider then
		whoDataProvider:Flush()
		
		local fontObj = GameFontNormalSmall
		for i, entry in ipairs(whoData) do
			whoDataProvider:Insert({
				index = i,
				info = entry.info,
				fontObject = fontObj
			})
		end
	end
end

-- Set whoSortValue (for dropdown)
function WhoFrame:SetSortValue(value)
	whoSortValue = value
end

-- Get whoSortValue
function WhoFrame:GetSortValue()
	return whoSortValue
end

-- Invalidate font cache (called when font scale changes)
function WhoFrame:InvalidateFontCache()
	cachedFontHeight = nil
	cachedExtent = nil
end

-- Handle button click
function WhoFrame:OnButtonClick(button, mouseButton)
	if mouseButton == "LeftButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:SetSelectedButton(button)
	elseif mouseButton == "RightButton" then
		-- Open context menu for WHO player
		if button.index then
			local info = C_FriendList.GetWhoInfo(button.index)
			if info then
				-- Strip trailing dash from fullName (WoW API bug)
				if info.fullName then
					info.fullName = info.fullName:gsub("%-$", "")
				end
				-- Also clean name field if present
				if info.name then
					info.name = info.name:gsub("%-$", "")
				end
				-- Use MenuSystem module if available
				local MenuSystem = BFL and BFL:GetModule("MenuSystem")
				if MenuSystem and MenuSystem.OpenWhoPlayerMenu then
					MenuSystem:OpenWhoPlayerMenu(button, info)
				else
					-- Fallback: Use basic UnitPopup
					local contextData = {
						name = info.fullName,
						server = info.fullGuildName,
						guid = info.guid,
					}
					UnitPopup_OpenMenu("FRIEND", contextData)
				end
			end
		end
	end
end

-- ========================================
-- Module Export
-- ========================================

-- ========================================
-- WHO FRAME UI MIXINS
-- ========================================

-- WHO EditBox Mixin (Blizzard 11.2.5 compatible)
local WhoFrameEditBoxMixin = {}

function WhoFrameEditBoxMixin:OnLoad()
	-- SearchBoxTemplate OnLoad already ran (inherit="append")
	-- KeyValues (instructionText, instructionsFontObject) are already set by SearchBoxTemplate
	
	-- Hide old-style textures (we use modern SearchBoxTemplate)
	if self.Left then self.Left:Hide() end
	if self.Middle then self.Middle:Hide() end
	if self.Right then self.Right:Hide() end
	
	-- Set up search icon
	if self.searchIcon then
		self.searchIcon:SetAtlas("glues-characterSelect-icon-search", TextureKitConstants.IgnoreAtlasSize)
	end
	
	-- Instructions are already configured by SearchBoxTemplate via KeyValues
	-- Just ensure Instructions has proper line wrapping
	if self.Instructions then
		self.Instructions:SetMaxLines(2)
	end
end

function WhoFrameEditBoxMixin:OnShow()
	-- Register for font scale updates
	if EventRegistry then
		EventRegistry:RegisterCallback("TextSizeManager.OnTextScaleUpdated", function()
			self:AdjustHeightToFitInstructions()
		end, self)
	end
	
	-- Adjust height initially
	self:AdjustHeightToFitInstructions()
	
	-- Clear focus
	EditBox_ClearFocus(self)
end

function WhoFrameEditBoxMixin:OnHide()
	-- Unregister from font scale updates
	if EventRegistry then
		EventRegistry:UnregisterCallback("TextSizeManager.OnTextScaleUpdated", self)
	end
end

function WhoFrameEditBoxMixin:AdjustHeightToFitInstructions()
	if not self.Instructions then return end
	
	local linesShown = math.min(self.Instructions:GetNumLines(), self.Instructions:GetMaxLines())
	local totalInstructionHeight = linesShown * self.Instructions:GetLineHeight()
	local padding = 20
	self:SetHeight(totalInstructionHeight + padding)
end

function WhoFrameEditBoxMixin:OnEnterPressed()
	local text = self:GetText()
	self:ClearFocus()
	
	-- Use centralized function to prevent Blizzard frame from opening
	if _G.BetterWhoFrame_SendWhoRequest then
		_G.BetterWhoFrame_SendWhoRequest(text)
	end
	
	-- Update the Who list after search (wait for server response)
	C_Timer.After(0.3, function()
		if BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame:IsShown() then
			if _G.BetterWhoFrame_Update then
				_G.BetterWhoFrame_Update()
			end
		end
	end)
end

function WhoFrameEditBoxMixin:OnEnter()
	if self.Instructions:IsShown() and self.Instructions:IsTruncated() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(WHO_LIST_SEARCH_INSTRUCTIONS or "Enter player name or search criteria", 1, 1, 1, true)
		GameTooltip:Show()
	end
end

function WhoFrameEditBoxMixin:OnLeave()
	GameTooltip:Hide()
end

-- WHO Column Dropdown Mixin (Variable Column: Zone/Guild/Race)
local WhoFrameColumnDropdownMixin = {}

function WhoFrameColumnDropdownMixin:OnLoad()
	-- Set up dropdown with user-scalable font
	self.fontObject = "GameFontNormalSmall"
	
	if self.Text then
		self.Text:SetFontObject(self.fontObject)
		-- Fix font color: Use white instead of yellow
		self.Text:SetTextColor(1, 1, 1)  -- RGB: white
		self.Text:ClearAllPoints()
		self.Text:SetPoint("LEFT", self, 8, 0)
		self.Text:SetPoint("RIGHT", self.Arrow, "LEFT", -8, 0)
	end
	
	if self.Arrow then
		self.Arrow:SetPoint("RIGHT", self, -1, -2)
	end
	
	-- CRITICAL: Set selection translator BEFORE SetupMenu
	self:SetSelectionTranslator(function(selection)
		-- selection.data contains {value, sortType}
		local selectionTexts = {ZONE, GUILD, RACE}
		return selectionTexts[selection.data.value] or ZONE
	end)
	
	-- Setup menu generator
	self:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_WHO_COLUMN")
		
		-- Create radio group for column selection
		local function IsSelected(data)
			return WhoFrame:GetSortValue() == data.value
		end
		
		local function SetSelected(data)
			WhoFrame:SetSortValue(data.value)
			
			-- Force dropdown to update its text immediately
			self:GenerateMenu()
			
			-- Update the Who list after changing sort
			if _G.BetterWhoFrame_Update then
				_G.BetterWhoFrame_Update()
			end
		end
		
		local function CreateRadio(text, value, sortType)
			local radio = rootDescription:CreateButton(text, function() end, {value = value, sortType = sortType})
			radio:SetIsSelected(IsSelected)
			radio:SetResponder(SetSelected)
		end
		
		CreateRadio(ZONE, 1, "zone")
		CreateRadio(GUILD, 2, "guild")
		CreateRadio(RACE, 3, "race")
	end)
end

-- Export mixins globally for XML access
_G.WhoFrameEditBoxMixin = WhoFrameEditBoxMixin
_G.WhoFrameColumnDropdownMixin = WhoFrameColumnDropdownMixin

-- ========================================
-- Global Wrapper Functions for XML Access
-- ========================================

-- Global wrapper for WHO list button OnClick
function _G.BetterWhoListButton_OnClick(button, mouseButton)
	if WhoFrame and WhoFrame.OnButtonClick then
		WhoFrame:OnButtonClick(button, mouseButton)
	end
end

-- ========================================
-- Module Return
-- ========================================

return WhoFrame
