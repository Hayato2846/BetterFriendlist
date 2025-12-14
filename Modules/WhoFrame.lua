-- Modules/WhoFrame.lua
-- WHO Frame System Module
-- Manages WHO search, display, sorting, and selection

local ADDON_NAME, BFL = ...
local FontManager = BFL.FontManager

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

-- Dirty flag: Set when data changes while frame is hidden
local needsRenderOnShow = false

-- ========================================
-- Module Lifecycle
-- ========================================

function WhoFrame:Initialize()
	-- Register event callback for WHO list updates
	BFL:RegisterEventCallback("WHO_LIST_UPDATE", function(...)
		self:OnWhoListUpdate(...)
	end, 10)
	
	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function()
			if needsRenderOnShow then
				-- Only trigger update if we are on the Who tab (tab 3 usually, but let's check visibility)
				if BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame:IsShown() then
					if _G.BetterWhoFrame_Update then
						_G.BetterWhoFrame_Update()
					end
					needsRenderOnShow = false
				end
			end
		end)
	end
end

-- Handle WHO_LIST_UPDATE event
function WhoFrame:OnWhoListUpdate(...)
	-- Update will be triggered by the UI if WHO frame is visible
	-- This callback ensures the module is aware of the event
end

-- ========================================
-- Responsive Layout Functions
-- ========================================

function WhoFrame:UpdateResponsiveLayout()
	local frame = BetterFriendsFrame
	if not frame or not frame.WhoFrame then return end
	
	local whoFrame = frame.WhoFrame
	local frameWidth = frame:GetWidth()
	
	-- Calculate available width for column headers
	-- XML positions: NameHeader starts at x=4 (TOPLEFT from ListInset)
	-- Reserve space for: 
	--   - Left: NameHeader padding (4px)
	--   - Right: Scrollbar (20px) + right padding (7px) = 27px
	local headerLeftPadding = 4
	local scrollbarAndPadding = 27  -- 20px scrollbar + 7px padding
	local availableWidth = frameWidth - headerLeftPadding - scrollbarAndPadding
	
	-- CRITICAL: Headers overlap by -2px each (3 overlaps = 6px gained back)
	-- NameHeader at x=4, then each subsequent header at x=-2 (overlap)
	-- So we need to ADD back the overlap space to availableWidth
	local headerOverlap = -2  -- Each header overlaps by 2px
	local numOverlaps = 3     -- ColumnDropdown, LevelHeader, ClassHeader each overlap
	local totalOverlapGain = numOverlaps * math.abs(headerOverlap)  -- 6px
	
	-- Adjust available width to account for overlaps
	local effectiveWidth = availableWidth + totalOverlapGain
	
	-- Distribute widths proportionally:
	-- Name: 32%, Column Dropdown: 29%, Level: 15%, Class: 24%
	local nameWidth = math.floor(effectiveWidth * 0.32)
	local columnWidth = math.floor(effectiveWidth * 0.29)
	local levelWidth = math.floor(effectiveWidth * 0.15)
	local classWidth = effectiveWidth - nameWidth - columnWidth - levelWidth -- Remaining space
	
	-- Apply minimum widths
	nameWidth = math.max(nameWidth, 80)
	columnWidth = math.max(columnWidth, 70)
	levelWidth = math.max(levelWidth, 40)
	classWidth = math.max(classWidth, 60)
	
	-- CRITICAL: Store calculated widths for button layout
	-- These will be used in InitButton() to position row content dynamically
	self.columnWidths = {
		name = nameWidth,
		variable = columnWidth,
		level = levelWidth,
		class = classWidth
	}
	
	-- Update column header widths
	if whoFrame.NameHeader then
		whoFrame.NameHeader:SetWidth(nameWidth)
		-- Update middle texture width (total - left(5) - right(4) = total - 9)
		if whoFrame.NameHeader.Middle then
			whoFrame.NameHeader.Middle:SetWidth(nameWidth - 9)
		end
	end
	
	if whoFrame.ColumnDropdown then
		whoFrame.ColumnDropdown:SetWidth(columnWidth)
	end
	
	if whoFrame.LevelHeader then
		whoFrame.LevelHeader:SetWidth(levelWidth)
		if whoFrame.LevelHeader.Middle then
			whoFrame.LevelHeader.Middle:SetWidth(levelWidth - 9)
		end
	end
	
	if whoFrame.ClassHeader then
		whoFrame.ClassHeader:SetWidth(classWidth)
		if whoFrame.ClassHeader.Middle then
			whoFrame.ClassHeader.Middle:SetWidth(classWidth - 9)
		end
	end
	
	-- Update bottom button positions to be centered
	local buttonsTotalWidth = 326 -- 85 (Refresh) + 1 + 120 (Add) + 1 + 120 (Invite) = 327
	local buttonsStartX = math.floor((frameWidth - buttonsTotalWidth) / 2)
	
	if whoFrame.WhoButton then
		whoFrame.WhoButton:ClearAllPoints()
		whoFrame.WhoButton:SetPoint("BOTTOMLEFT", whoFrame.ListInset, buttonsStartX, -26)
	end
	
	-- REFRESH BUTTONS: Trigger re-layout of all visible buttons
	-- This ensures row content repositions immediately when frame resizes
	-- CRITICAL: Update ALL visible buttons, even if they have no data yet
	if whoFrame.ScrollBox then
		whoFrame.ScrollBox:ForEachFrame(function(button)
			-- Check if button has valid element data (from DataProvider)
			local elementData = button:GetElementData()
			if elementData and elementData.info then
				-- Re-apply layout with new column widths
				self:InitButton(button, elementData)
			elseif button.Name then
				-- Button exists but has no data - still apply column widths for consistency
				-- This ensures proper layout even before first Who results load
				if self.columnWidths then
					local widths = self.columnWidths
					local headerLeftPadding = 4  -- Match NameHeader XML position
					local headerGap = -2         -- Match XML header overlap
					
					-- Scale widths to fit button width (same logic as InitButton)
					local buttonWidth = button:GetWidth()
					local rightPadding = 2  -- Prevent text clipping
					local totalHeaderWidth = widths.name + widths.variable + widths.level + widths.class - (3 * math.abs(headerGap))
					local buttonContentWidth = buttonWidth - headerLeftPadding - rightPadding
					local scaleFactor = buttonContentWidth / totalHeaderWidth
					
					local scaledName = math.floor(widths.name * scaleFactor)
					local scaledVariable = math.floor(widths.variable * scaleFactor)
					local scaledLevel = math.floor(widths.level * scaleFactor)
					local scaledClass = buttonContentWidth - scaledName - scaledVariable - scaledLevel + (3 * math.abs(headerGap))
					
					-- Apply scaled widths
					local nameStart = headerLeftPadding
					button.Name:SetWidth(scaledName)
					button.Name:SetJustifyH("LEFT")
					button.Name:ClearAllPoints()
					button.Name:SetPoint("LEFT", button, "LEFT", nameStart, 0)
					button.Name:SetPoint("RIGHT", button, "LEFT", nameStart + scaledName, 0)
					
					local variableStart = nameStart + scaledName + headerGap
					button.Variable:SetWidth(scaledVariable)
					button.Variable:SetJustifyH("LEFT")
					button.Variable:ClearAllPoints()
					button.Variable:SetPoint("LEFT", button, "LEFT", variableStart, 0)
					button.Variable:SetPoint("RIGHT", button, "LEFT", variableStart + scaledVariable, 0)
					
					local levelStart = variableStart + scaledVariable + headerGap
					button.Level:SetWidth(scaledLevel)
					button.Level:SetJustifyH("CENTER")
					button.Level:ClearAllPoints()
					button.Level:SetPoint("LEFT", button, "LEFT", levelStart, 0)
					button.Level:SetPoint("RIGHT", button, "LEFT", levelStart + scaledLevel, 0)
					
					local classStart = levelStart + scaledLevel + headerGap
					button.Class:SetWidth(scaledClass)
					button.Class:SetJustifyH("CENTER")
					button.Class:ClearAllPoints()
					button.Class:SetPoint("LEFT", button, "LEFT", classStart, 0)
					button.Class:SetPoint("RIGHT", button, "LEFT", classStart + scaledClass, 0)
				end
			end
		end)
	end
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
			local _, fontHeight = fontObj:GetFont()
			
			-- Apply multiplier from FontManager
			if FontManager then
				local multiplier = FontManager:GetFontSizeMultiplier()
				fontHeight = math.floor(fontHeight * multiplier + 0.5)
			end
			
			cachedFontHeight = fontHeight
			local padding = 4 -- Slightly more padding for readability
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
	
	-- Apply initial responsive layout
	C_Timer.After(0.1, function()
		self:UpdateResponsiveLayout()
	end)
	
	-- Register for font scale updates
	if EventRegistry then
		EventRegistry:RegisterCallback("TextSizeManager.OnTextScaleUpdated", function()
			self:InvalidateFontCache()
			self:Update(true) -- Force rebuild to re-measure
		end, self)
	end
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
	
	-- RESPONSIVE LAYOUT: Apply calculated column widths to button elements
	-- This ensures row content aligns perfectly with column headers
	-- All text elements are CENTER-justified to match header button alignment
	if self.columnWidths then
		local widths = self.columnWidths
		
		-- Match XML header positions EXACTLY:
		-- NameHeader: x=4 from ListInset TOPLEFT
		-- ColumnDropdown: x=-2 from NameHeader RIGHT (overlap)
		-- LevelHeader: x=-2 from ColumnDropdown RIGHT (overlap)
		-- ClassHeader: x=-2 from LevelHeader RIGHT (overlap)
		local headerLeftPadding = 4  -- NameHeader starts at x=4 in XML
		local headerGap = -2         -- Headers overlap by 2px in XML
		
		-- CRITICAL: Buttons are narrower than headers due to ScrollBox layout
		-- We need to scale down the column widths proportionally to fit button width
		local buttonWidth = button:GetWidth()
		local rightPadding = 2  -- Small padding to prevent text clipping at button edge
		local totalHeaderWidth = widths.name + widths.variable + widths.level + widths.class - (3 * math.abs(headerGap))
		local buttonContentWidth = buttonWidth - headerLeftPadding - rightPadding  -- Available width in button
		local scaleFactor = buttonContentWidth / totalHeaderWidth
		
		-- Scale all widths proportionally
		local scaledName = math.floor(widths.name * scaleFactor)
		local scaledVariable = math.floor(widths.variable * scaleFactor)
		local scaledLevel = math.floor(widths.level * scaleFactor)
		local scaledClass = buttonContentWidth - scaledName - scaledVariable - scaledLevel + (3 * math.abs(headerGap))
		
		-- Name column: Starts at x=4 (matching NameHeader XML position)
		local nameStart = headerLeftPadding
		button.Name:SetWidth(scaledName)
		button.Name:SetJustifyH("LEFT")
		button.Name:ClearAllPoints()
		button.Name:SetPoint("LEFT", button, "LEFT", nameStart, 0)
		button.Name:SetPoint("RIGHT", button, "LEFT", nameStart + scaledName, 0)
		
		-- Variable column: Positioned with -2px overlap (matching XML)
		local variableStart = nameStart + scaledName + headerGap
		button.Variable:SetWidth(scaledVariable)
		button.Variable:SetJustifyH("LEFT")
		button.Variable:ClearAllPoints()
		button.Variable:SetPoint("LEFT", button, "LEFT", variableStart, 0)
		button.Variable:SetPoint("RIGHT", button, "LEFT", variableStart + scaledVariable, 0)
		
		-- Level column: Positioned with -2px overlap (matching XML)
		local levelStart = variableStart + scaledVariable + headerGap
		button.Level:SetWidth(scaledLevel)
		button.Level:SetJustifyH("CENTER")
		button.Level:ClearAllPoints()
		button.Level:SetPoint("LEFT", button, "LEFT", levelStart, 0)
		button.Level:SetPoint("RIGHT", button, "LEFT", levelStart + scaledLevel, 0)
		
		-- Class column: Positioned with -2px overlap (matching XML)
		local classStart = levelStart + scaledLevel + headerGap
		button.Class:SetWidth(scaledClass)
		button.Class:SetJustifyH("CENTER")
		button.Class:ClearAllPoints()
		button.Class:SetPoint("LEFT", button, "LEFT", classStart, 0)
		button.Class:SetPoint("RIGHT", button, "LEFT", classStart + scaledClass, 0)
	end
	
	-- Set button text
	button.Name:SetText(name)
	button.Level:SetText(info.level)
	button.Class:SetText(info.classStr or "")
	if classTextColor then
		button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
	end
	
	-- Apply font scaling
	if FontManager then
		FontManager:ApplyFontSize(button.Name)
		FontManager:ApplyFontSize(button.Level)
		FontManager:ApplyFontSize(button.Class)
		FontManager:ApplyFontSize(button.Variable)
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
	if BFL then BFL:DebugPrint("WhoFrame:SendWhoRequest called with text: " .. tostring(text)) end
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
	
	-- Visibility Optimization:
	-- If the frame (or the Who tab) is hidden, don't rebuild the list.
	if not BetterFriendsFrame:IsShown() or not BetterFriendsFrame.WhoFrame:IsShown() then
		needsRenderOnShow = true
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
			-- CRITICAL: Must force rebuild because data count hasn't changed, 
			-- but the displayed content (Variable column) has changed!
			if WhoFrame and WhoFrame.Update then
				WhoFrame:Update(true)
			elseif _G.BetterWhoFrame_Update then
				_G.BetterWhoFrame_Update(true)
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

-- Export module to BFL namespace (required for BFL.WhoFrame access)
BFL.WhoFrame = WhoFrame

return WhoFrame
