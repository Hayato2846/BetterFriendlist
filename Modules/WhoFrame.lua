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
local BUTTON_HEIGHT = 22 -- Increased from 16 for class icons + readability
local CLASS_ICON_SIZE = 14
local CLASS_ICON_OFFSET = 4
local NAME_OFFSET_WITH_ICON = 22 -- 4 (icon offset) + 14 (icon) + 4 (gap)
local NAME_OFFSET_WITHOUT_ICON = 6

-- Class icon texture coordinates (from WoW global CLASS_ICON_TCOORDS)
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"

-- Zebra stripe colors
local ZEBRA_EVEN_COLOR = { r = 0.1, g = 0.1, b = 0.1, a = 0.3 }
local ZEBRA_ODD_COLOR = { r = 0, g = 0, b = 0, a = 0 }

-- WHO sort values
local whoSortValue = 1 -- 1=Zone, 2=Guild, 3=Race

-- Data Provider
local whoDataProvider = nil

-- Selected WHO button
local selectedWhoButton = nil

-- Font cache for performance
local cachedFontHeight = nil
local cachedExtent = nil

-- Dirty flag: Set when data changes while frame is hidden
local needsRenderOnShow = false

-- Double-click tracking
local lastClickTime = 0
local lastClickButton = nil
local DOUBLE_CLICK_THRESHOLD = 0.4

-- WHO throttle constants
local WHO_COOLDOWN = 5 -- seconds between WHO queries
local WHO_TIMEOUT = 8 -- seconds to wait for WHO_LIST_UPDATE before showing timeout

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
				if BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame:IsShown() then
					if _G.BetterWhoFrame_Update then
						_G.BetterWhoFrame_Update(true)
					end
					needsRenderOnShow = false
				end
			end
		end)
	end

	-- Restore docked state from DB (must be here, not in CreateSearchBuilder,
	-- because SavedVariables are not yet available during XML OnLoad)
	local DB = BFL:GetModule("DB")
	if DB and self.builderFlyout then
		local isDocked = DB:Get("whoSearchBuilderDocked", false)
		if isDocked then
			self:SetBuilderDocked(true)
		end
	end
end

-- Get a WHO setting from the database with fallback
function WhoFrame:GetSetting(key, default)
	local DB = BFL:GetModule("DB")
	if DB then
		return DB:Get(key, default)
	end
	return default
end

-- Handle WHO_LIST_UPDATE event
function WhoFrame:OnWhoListUpdate(...)
	-- Clear pending state - results arrived successfully
	self.whoPending = false
	if self.whoTimeoutTimer then
		self.whoTimeoutTimer:Cancel()
		self.whoTimeoutTimer = nil
	end

	-- CRITICAL: When WHO list updates, we MUST force a rebuild
	-- The data in C_FriendList has changed, so our cached DataProvider is invalid
	-- regardless of whether the count matches the previous count.
	self:Update(true)
end

-- ========================================
-- Responsive Layout Functions
-- ========================================

function WhoFrame:UpdateResponsiveLayout()
	local frame = BetterFriendsFrame
	if not frame or not frame.WhoFrame then
		return
	end

	local whoFrame = frame.WhoFrame
	local frameWidth = frame:GetWidth()

	-- Calculate available width for column headers
	-- XML positions: NameHeader starts at x=4 (TOPLEFT from ListInset)
	-- Reserve space for:
	--   - Left: NameHeader padding (adjusted for class icons)
	--   - Right: Scrollbar (20px) + overlap (7px) + visual gap (7px) = 34px
	local showClassIcons = self:GetSetting("whoShowClassIcons", true)
	local headerLeftPadding = showClassIcons and NAME_OFFSET_WITH_ICON or NAME_OFFSET_WITHOUT_ICON
	local scrollbarAndPadding = 34 -- 20px scrollbar + 7px overlap + 7px visual gap
	local availableWidth = frameWidth - headerLeftPadding - scrollbarAndPadding

	-- CRITICAL: Headers overlap by -2px each (3 overlaps = 6px gained back)
	-- NameHeader at x=4, then each subsequent header at x=-2 (overlap)
	-- So we need to ADD back the overlap space to availableWidth
	local headerOverlap = -2 -- Each header overlaps by 2px
	local numOverlaps = 3 -- ColumnDropdown, LevelHeader, ClassHeader each overlap
	local totalOverlapGain = numOverlaps * math.abs(headerOverlap) -- 6px

	-- Adjust available width to account for overlaps
	local effectiveWidth = availableWidth + totalOverlapGain

	-- Distribute widths proportionally:
	-- Name: 34%, Column Dropdown: 26%, Level: 10%, Class: 30%
	-- Level only needs ~30px for 2-3 digits; freed space goes to Name and Class
	local nameWidth = math.floor(effectiveWidth * 0.34)
	local columnWidth = math.floor(effectiveWidth * 0.26)
	local levelWidth = math.floor(effectiveWidth * 0.10)
	local classWidth = effectiveWidth - nameWidth - columnWidth - levelWidth -- Remaining space

	-- Apply minimum widths
	nameWidth = math.max(nameWidth, 80)
	local isClassicElvUISkinActive = BFL.IsClassic
		and _G.ElvUI
		and BetterFriendlistDB
		and BetterFriendlistDB.enableElvUISkin ~= false
	local minColumnWidth = isClassicElvUISkinActive and 110 or 70
	columnWidth = math.max(columnWidth, minColumnWidth)
	levelWidth = math.max(levelWidth, 28)
	classWidth = math.max(classWidth, 70)

	-- CRITICAL: Store calculated widths for button layout
	-- These will be used in InitButton() to position row content dynamically
	self.columnWidths = {
		name = nameWidth,
		variable = columnWidth,
		level = levelWidth,
		class = classWidth,
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

	-- Classic: Reposition headers dynamically (XML uses fixed positions, won't adapt to responsive widths)
	if BFL.IsClassic then
		local headerOverlapX = -2
		if whoFrame.ColumnDropdown and whoFrame.NameHeader then
			whoFrame.ColumnDropdown:ClearAllPoints()
			whoFrame.ColumnDropdown:SetPoint("TOPLEFT", whoFrame.NameHeader, "TOPRIGHT", headerOverlapX - 14, 2)
		end
		-- Anchor Level and Class relative to NameHeader using accumulated widths
		-- (UIDropDownMenu frame edges are unreliable due to internal padding)
		local levelX = nameWidth + columnWidth + headerOverlapX
		if whoFrame.LevelHeader and whoFrame.NameHeader then
			whoFrame.LevelHeader:ClearAllPoints()
			whoFrame.LevelHeader:SetPoint("TOPLEFT", whoFrame.NameHeader, "TOPLEFT", levelX, 0)
		end
		if whoFrame.ClassHeader and whoFrame.LevelHeader then
			whoFrame.ClassHeader:ClearAllPoints()
			whoFrame.ClassHeader:SetPoint("LEFT", whoFrame.LevelHeader, "RIGHT", headerOverlapX, 0)
		end
	end

	-- Update bottom button positions to be centered
	-- Restored centering logic to fix "too far right" issue in Retail
	-- CRITICAL: Do NOT apply this to Classic, as it breaks the XML anchor chain
	-- In Classic, buttons are right-aligned and anchored to each other
	if not BFL.IsClassic then
		local buttonsTotalWidth = 327 -- 85 (Refresh) + 1 + 120 (Add) + 1 + 120 (Invite) = 327
		local buttonsStartX = math.floor((frameWidth - buttonsTotalWidth) / 2)

		-- REMOVED: Lua override of XML coordinates
		-- The XML now handles the positioning correctly (y=4 relative to main frame)
		if whoFrame.WhoButton then
			whoFrame.WhoButton:ClearAllPoints()
			-- User requested only X change, Y should remain 4 relative to frame bottom
			whoFrame.WhoButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", buttonsStartX, 4)
		end
	end

	-- REFRESH BUTTONS: Trigger re-layout of all visible buttons
	-- This ensures row content repositions immediately when frame resizes
	-- CRITICAL: Update ALL visible buttons, even if they have no data yet
	if whoFrame.ScrollBox then
		-- Classic: Use classicWhoButtonPool instead of ForEachFrame (modern API)
		if BFL.IsClassic and self.classicWhoButtonPool then
			for i = 1, #self.classicWhoButtonPool do
				local button = self.classicWhoButtonPool[i]
				if button and button:IsShown() then
					-- Check if button has valid element data
					local elementData = button.elementData
					if elementData and elementData.info then
						-- Re-apply layout with new column widths
						self:InitButton(button, elementData)
					elseif button.Name then
						-- Button exists but has no data - still apply column widths for consistency
						-- This ensures proper layout even before first Who results load
						if self.columnWidths then
							local widths = self.columnWidths
							local nameStart = NAME_OFFSET_WITHOUT_ICON -- No data = no icon
							local headerGap = -2 -- Match XML header overlap

							-- Direct header-aligned positioning (same as InitButton)
							button.Name:SetJustifyH("LEFT")
							button.Name:ClearAllPoints()
							button.Name:SetPoint("LEFT", button, "LEFT", nameStart, 0)
							button.Name:SetPoint("RIGHT", button, "LEFT", widths.name, 0)

							local variableStart = widths.name + headerGap + 8
							button.Variable:SetJustifyH("LEFT")
							button.Variable:ClearAllPoints()
							button.Variable:SetPoint("LEFT", button, "LEFT", variableStart, 0)
							button.Variable:SetPoint(
								"RIGHT",
								button,
								"LEFT",
								widths.name + headerGap + widths.variable,
								0
							)

							local levelStart = widths.name + headerGap + widths.variable + headerGap
							button.Level:SetJustifyH("CENTER")
							button.Level:ClearAllPoints()
							button.Level:SetPoint("LEFT", button, "LEFT", levelStart, 0)
							button.Level:SetPoint("RIGHT", button, "LEFT", levelStart + widths.level, 0)

							local classStart = levelStart + widths.level + headerGap
							button.Class:SetJustifyH("LEFT")
							button.Class:ClearAllPoints()
							button.Class:SetPoint("LEFT", button, "LEFT", classStart, 0)
							button.Class:SetPoint("RIGHT", button, "LEFT", classStart + widths.class, 0)
						end
					end
				end
			end
		end
	end
end

-- ========================================
-- WHO Frame Core Functions
-- ========================================

-- Initialize Who Frame with ScrollBox (Retail) or FauxScrollFrame (Classic)
function WhoFrame:OnLoad(frame)
	-- Classic: Use FauxScrollFrame approach
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		self:InitializeClassicWhoFrame(frame)
		return
	end

	-- Retail: Initialize ScrollBox with DataProvider
	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("BetterWhoListButtonTemplate", function(button, elementData)
		self:InitButton(button, elementData)
	end)

	-- PERFORMANCE: Cache font height calculation (all buttons use same font)
	view:SetElementExtentCalculator(function(dataIndex, elementData)
		if not cachedExtent then
			cachedExtent = BUTTON_HEIGHT
		end
		return cachedExtent
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

	-- Anchor ScrollBox flush inside ListInset for a clean, crisp layout
	frame.ScrollBox:ClearAllPoints()
	frame.ScrollBox:SetPoint("TOPLEFT", frame.ListInset, "TOPLEFT", 4, -4)
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ListInset.Totals, "TOPRIGHT", -4, 2)

	-- Create DataProvider
	whoDataProvider = CreateDataProvider()
	frame.ScrollBox:SetDataProvider(whoDataProvider)

	-- Initialize selected who
	frame.selectedWho = nil
	frame.selectedName = ""

	-- Create empty state message
	self:CreateEmptyState(frame)

	-- Create search builder
	self:CreateSearchBuilder(frame)

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

-- Initialize Classic WHO FauxScrollFrame
function WhoFrame:InitializeClassicWhoFrame(frame)
	self.classicWhoFrame = frame
	self.classicWhoButtonPool = {}
	self.classicWhoDataList = {}

	local NUM_BUTTONS = 18 -- Adjusted for taller rows (22px)

	-- Create buttons for Classic mode
	local parentFrame = frame.ScrollBox or frame
	for i = 1, NUM_BUTTONS do
		local button = CreateFrame("Button", "BetterWhoListButton" .. i, parentFrame, "BetterWhoListButtonTemplate")
		button:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -((i - 1) * BUTTON_HEIGHT))
		button:SetPoint("RIGHT", parentFrame, "RIGHT", 0, 0)
		button:SetHeight(BUTTON_HEIGHT)
		button.classicIndex = i
		button:Hide()
		self.classicWhoButtonPool[i] = button
	end

	-- Create scroll bar if needed (use simple Slider, NOT UIPanelScrollBarTemplate which requires ScrollFrame parent)
	if not frame.ClassicScrollBar then
		-- CRITICAL: Remove old named scrollbar if it exists (from previous version)
		-- The old code created "BetterWhoScrollBar" which triggers SecureScrollTemplates hooks
		-- We must completely remove it before creating a new one
		local oldScrollBar = _G["BetterWhoScrollBar"]
		if oldScrollBar then
			-- Unregister all events and scripts to prevent hooks from firing
			oldScrollBar:UnregisterAllEvents()
			oldScrollBar:SetScript("OnValueChanged", nil)
			oldScrollBar:SetScript("OnMouseWheel", nil)
			oldScrollBar:Hide()
			oldScrollBar:SetParent(nil)
			oldScrollBar:ClearAllPoints()
			-- Remove from global namespace
			_G["BetterWhoScrollBar"] = nil
		end

		-- IMPORTANT: Do NOT use BackdropTemplate - it triggers Secure template chain that expects SetVerticalScroll
		-- IMPORTANT: Create completely anonymous frame (no name) to avoid ANY template hooks
		local scrollBar = CreateFrame("Slider", nil, frame) -- Anonymous frame to avoid Secure template hooks

		-- Anchor to ListInset if available to ensure correct positioning
		local inset = frame.ListInset or (frame:GetParent() and frame:GetParent().ListInset)
		if inset then
			-- Adjust for Up/Down buttons (20px) + padding (2px) = 22px
			-- UpButton is attached to TOP of scrollBar, so scrollBar TOP must be lower
			-- DownButton is attached to BOTTOM of scrollBar, so scrollBar BOTTOM must be higher
			-- Move x by -2 to sit inside the inset border
			-- Fix: Increase bottom offset to 38 to clear the EditBox (height 20 + padding)
			scrollBar:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -2, -22)
			scrollBar:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -2, 38)
		else
			scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -16)
			scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 16)
		end

		scrollBar:SetWidth(20)
		scrollBar:SetOrientation("VERTICAL")
		scrollBar:SetMinMaxValues(0, 0)
		scrollBar:SetValueStep(1)
		scrollBar:SetObeyStepOnDrag(true)
		scrollBar:EnableMouseWheel(true)

		-- Add a subtle background track
		local bg = scrollBar:CreateTexture(nil, "BACKGROUND")
		bg:SetColorTexture(0, 0, 0, 0.2)
		bg:SetAllPoints()

		-- Create thumb texture
		local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
		thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		thumb:SetSize(18, 24)
		scrollBar:SetThumbTexture(thumb)

		-- Create up/down button backgrounds
		local upButton = CreateFrame("Button", nil, scrollBar)
		upButton:SetSize(20, 20) -- Larger buttons (20x20)
		upButton:SetPoint("BOTTOM", scrollBar, "TOP", 0, 0)
		upButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		upButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
		upButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
		upButton:SetScript("OnClick", function()
			scrollBar:SetValue(scrollBar:GetValue() - 1)
		end)

		local downButton = CreateFrame("Button", nil, scrollBar)
		downButton:SetSize(20, 20) -- Larger buttons (20x20)
		downButton:SetPoint("TOP", scrollBar, "BOTTOM", 0, 0)
		downButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
		downButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
		downButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
		downButton:SetScript("OnClick", function()
			scrollBar:SetValue(scrollBar:GetValue() + 1)
		end)

		-- Mouse wheel support function
		local function OnMouseWheel(self, delta)
			if scrollBar:IsShown() then
				scrollBar:SetValue(scrollBar:GetValue() - delta)
			end
		end

		-- Apply mousewheel to scrollbar, scrollbox, and buttons
		scrollBar:SetScript("OnMouseWheel", OnMouseWheel)
		if frame.ScrollBox then
			frame.ScrollBox:SetScript("OnMouseWheel", OnMouseWheel)
		end

		-- Apply to existing buttons in pool
		for _, button in ipairs(self.classicWhoButtonPool) do
			button:SetScript("OnMouseWheel", OnMouseWheel)
		end

		scrollBar:SetScript("OnValueChanged", function(self, value)
			WhoFrame:RenderClassicWhoButtons()
		end)

		-- Set initial value AFTER scripts are registered (prevents SecureScrollTemplates error)
		scrollBar:SetValue(0)

		frame.ClassicScrollBar = scrollBar
	end

	-- Initialize selected who
	frame.selectedWho = nil
	frame.selectedName = ""

	-- Create empty state message
	self:CreateEmptyState(frame)

	-- Create search builder
	self:CreateSearchBuilder(frame)

	-- Click outside to clear focus
	frame:SetScript("OnMouseDown", function()
		if frame.EditBox then
			frame.EditBox:ClearFocus()
		end
	end)

	-- Apply initial responsive layout
	C_Timer.After(0.1, function()
		self:UpdateResponsiveLayout()
	end)
end

-- Initialize Classic Dropdown (UIDropDownMenu)
function WhoFrame:InitializeClassicDropdown(dropdown)
	if not dropdown then
		return
	end

	local isClassicElvUISkinActive = BFL.IsClassic
		and _G.ElvUI
		and BetterFriendlistDB
		and BetterFriendlistDB.enableElvUISkin ~= false

	local function NormalizeClassicColumnDropdown()
		dropdown:SetHeight(24)
		local name = dropdown:GetName()
		if name then
			local button = _G[name .. "Button"]
			if button then
				button:ClearAllPoints()
				button:SetAllPoints(dropdown)
				button:SetHitRectInsets(0, 0, 0, 0)
				button:SetHeight(24)
			end
		end
	end

	UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()

		local function OnClick(self, arg1, arg2, checked)
			WhoFrame:SetSortValue(arg1)
			UIDropDownMenu_SetSelectedValue(dropdown, arg1)
			-- Force update
			if WhoFrame and WhoFrame.Update then
				WhoFrame:Update(true)
			end
		end

		info.text = ZONE
		info.value = 1
		info.arg1 = 1
		info.func = OnClick
		info.checked = (WhoFrame:GetSortValue() == 1)
		UIDropDownMenu_AddButton(info)

		info.text = GUILD
		info.value = 2
		info.arg1 = 2
		info.func = OnClick
		info.checked = (WhoFrame:GetSortValue() == 2)
		UIDropDownMenu_AddButton(info)

		info.text = RACE
		info.value = 3
		info.arg1 = 3
		info.func = OnClick
		info.checked = (WhoFrame:GetSortValue() == 3)
		UIDropDownMenu_AddButton(info)
	end)

	UIDropDownMenu_SetWidth(dropdown, isClassicElvUISkinActive and 110 or 80)
	UIDropDownMenu_SetSelectedValue(dropdown, 1)
	if not isClassicElvUISkinActive then
		return
	end

	NormalizeClassicColumnDropdown()

	if not dropdown.BFL_ClassicNormalizeHookInstalled then
		dropdown.BFL_ClassicNormalizeHookInstalled = true
		dropdown:HookScript("OnShow", function()
			C_Timer.After(0, NormalizeClassicColumnDropdown)
		end)
		local name = dropdown:GetName()
		if name then
			local button = _G[name .. "Button"]
			if button and button.HookScript then
				button:HookScript("OnClick", function()
					C_Timer.After(0, NormalizeClassicColumnDropdown)
				end)
			end
		end
	end
end

-- Render Classic WHO buttons
function WhoFrame:RenderClassicWhoButtons()
	if not self.classicWhoFrame or not self.classicWhoButtonPool then
		return
	end

	local dataList = self.classicWhoDataList or {}
	local numItems = #dataList
	local numButtons = #self.classicWhoButtonPool

	-- Calculate visible buttons based on ScrollBox height
	local scrollBox = self.classicWhoFrame.ScrollBox
	local visibleButtons = numButtons -- Default to pool size
	if scrollBox then
		local height = scrollBox:GetHeight()
		if height and height > 0 then
			visibleButtons = math.floor(height / BUTTON_HEIGHT)
		end
	end

	local offset = 0
	if self.classicWhoFrame.ClassicScrollBar then
		offset = math.floor(self.classicWhoFrame.ClassicScrollBar:GetValue() or 0)
	end

	-- Update scroll bar range
	if self.classicWhoFrame.ClassicScrollBar then
		local maxValue = math.max(0, numItems - visibleButtons)
		self.classicWhoFrame.ClassicScrollBar:SetMinMaxValues(0, maxValue)

		-- Visibility logic: Only show if there is something to scroll
		if maxValue > 0 then
			self.classicWhoFrame.ClassicScrollBar:Show()
		else
			self.classicWhoFrame.ClassicScrollBar:Hide()
		end
	end

	-- Render buttons
	for i, button in ipairs(self.classicWhoButtonPool) do
		-- Only show buttons that fit in the visible area
		if i <= visibleButtons then
			local dataIndex = offset + i
			if dataIndex <= numItems then
				local elementData = dataList[dataIndex]
				self:InitButton(button, elementData)
				button:Show()
			else
				button:Hide()
			end
		else
			button:Hide()
		end
	end
end

-- Initialize individual Who button
function WhoFrame:InitButton(button, elementData)
	local index = elementData.index
	local info = elementData.info
	local dataIndex = elementData.dataIndex or index
	button.index = index
	button.info = info
	button.elementData = elementData

	-- Get settings
	local showClassIcons = self:GetSetting("whoShowClassIcons", true)
	local classColorNames = self:GetSetting("whoClassColorNames", true)
	local levelColors = self:GetSetting("whoLevelColors", true)
	local zebraStripes = self:GetSetting("whoZebraStripes", true)

	-- PERFORMANCE: Cache class color lookup
	local classTextColor = info.filename and RAID_CLASS_COLORS[info.filename] or HIGHLIGHT_FONT_COLOR

	-- Class Icon
	if button.classIcon then
		if showClassIcons and info.filename and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[info.filename] then
			local coords = CLASS_ICON_TCOORDS[info.filename]
			button.classIcon:SetTexture(CLASS_ICON_TEXTURE)
			button.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			button.classIcon:Show()
		else
			button.classIcon:Hide()
		end
	end

	-- Zebra stripe background
	if button.background and zebraStripes then
		if dataIndex % 2 == 0 then
			button.background:SetColorTexture(
				ZEBRA_EVEN_COLOR.r,
				ZEBRA_EVEN_COLOR.g,
				ZEBRA_EVEN_COLOR.b,
				ZEBRA_EVEN_COLOR.a
			)
		else
			button.background:SetColorTexture(
				ZEBRA_ODD_COLOR.r,
				ZEBRA_ODD_COLOR.g,
				ZEBRA_ODD_COLOR.b,
				ZEBRA_ODD_COLOR.a
			)
		end
	elseif button.background then
		button.background:SetColorTexture(0, 0, 0, 0)
	end

	-- Selection highlight (create once per button)
	if not button.selectionHighlight then
		local sel = button:CreateTexture(nil, "BACKGROUND", nil, 1)
		sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		sel:SetBlendMode("ADD")
		sel:SetVertexColor(0.510, 0.773, 1.0, 0.5)
		sel:SetPoint("TOPLEFT", 0, -1)
		sel:SetPoint("BOTTOMRIGHT", 0, 1)
		sel:Hide()
		button.selectionHighlight = sel
	end

	-- Process Timerunning icon for name display
	local name = info.fullName
	if info.timerunningSeasonID then
		if TimerunningUtil and TimerunningUtil.AddTinyIcon then
			name = TimerunningUtil.AddTinyIcon(name)
		end
	end

	-- RESPONSIVE LAYOUT: Position row elements to align directly with column headers
	-- With ScrollBox x=0 fix, button LEFT = NameHeader LEFT, so header widths map directly
	if self.columnWidths then
		local widths = self.columnWidths
		local nameStart = showClassIcons and NAME_OFFSET_WITH_ICON or NAME_OFFSET_WITHOUT_ICON
		local headerGap = -2 -- Match XML header overlap (-2px between each header)

		-- Name column: aligned with NameHeader, text offset for class icon
		button.Name:SetJustifyH("LEFT")
		button.Name:ClearAllPoints()
		button.Name:SetPoint("LEFT", button, "LEFT", nameStart, 0)
		button.Name:SetPoint("RIGHT", button, "LEFT", widths.name, 0)

		-- Variable column: aligned with ColumnDropdown text (offset for dropdown padding)
		local dropdownTextPad = 8 -- Match WhoFrameColumnDropdownMixin Text LEFT offset
		local variableStart = widths.name + headerGap + dropdownTextPad
		button.Variable:SetJustifyH("LEFT")
		button.Variable:ClearAllPoints()
		button.Variable:SetPoint("LEFT", button, "LEFT", variableStart, 0)
		button.Variable:SetPoint("RIGHT", button, "LEFT", widths.name + headerGap + widths.variable, 0)

		-- Level column: aligned with LevelHeader
		local levelStart = widths.name + headerGap + widths.variable + headerGap
		button.Level:SetJustifyH("CENTER")
		button.Level:ClearAllPoints()
		button.Level:SetPoint("LEFT", button, "LEFT", levelStart, 0)
		button.Level:SetPoint("RIGHT", button, "LEFT", levelStart + widths.level, 0)

		-- Class column: aligned with ClassHeader
		local classStart = levelStart + widths.level + headerGap
		button.Class:SetJustifyH("LEFT")
		button.Class:ClearAllPoints()
		button.Class:SetPoint("LEFT", button, "LEFT", classStart, 0)
		button.Class:SetPoint("RIGHT", button, "LEFT", classStart + widths.class, 0)
	end

	-- Set button text
	button.Name:SetText(name)
	button.Level:SetText(info.level)
	button.Class:SetText(info.classStr or "")

	-- Class-colored name
	if classColorNames and classTextColor then
		button.Name:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
	else
		button.Name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	end

	-- Class-colored class column
	if classTextColor then
		button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
	end

	-- Level difficulty coloring
	if levelColors and info.level then
		local diffColor = GetQuestDifficultyColor(info.level)
		if diffColor then
			button.Level:SetTextColor(diffColor.r, diffColor.g, diffColor.b)
		end
	else
		button.Level:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
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

	-- Store full data for tooltip and interactions
	button.tooltipInfo = {
		fullName = info.fullName,
		level = info.level,
		classStr = info.classStr,
		raceStr = info.raceStr,
		area = info.area,
		guild = info.fullGuildName or info.guild,
		filename = info.filename,
		variableText = variableText,
	}

	-- Update selection state
	local selected = BetterFriendsFrame.WhoFrame.selectedWho == index
	self:SetButtonSelected(button, selected)
end

-- Check if WHO search is currently on cooldown
function WhoFrame:IsOnCooldown()
	return self.lastWhoSendTime and (GetTime() - self.lastWhoSendTime < WHO_COOLDOWN)
end

-- Send Who request
function WhoFrame:SendWhoRequest(text)
	-- Throttle: Prevent queries faster than the server allows
	local now = GetTime()
	if self.lastWhoSendTime and (now - self.lastWhoSendTime < WHO_COOLDOWN) then
		-- Still in cooldown - update buttons to show remaining time
		self:UpdateRefreshButtonCooldown()
		self:UpdateBuilderSearchButtonCooldown()
		return
	end

	if not text or text == "" then
		-- Use default Who command if no text provided
		local level = UnitLevel("player")
		local minLevel = level - 3
		if minLevel <= 0 then
			minLevel = 1
		end
		local maxLevel = math.min(level + 3, GetMaxPlayerLevel())
		text = 'z-"' .. GetRealZoneText() .. '" ' .. minLevel .. "-" .. maxLevel
	end

	-- Record send time and set pending state
	self.lastWhoSendTime = now
	self.whoPending = true

	-- Start button cooldown feedback
	self:StartRefreshButtonCooldown()
	self:StartBuilderSearchButtonCooldown()

	-- Start timeout timer (server may silently drop the request)
	if self.whoTimeoutTimer then
		self.whoTimeoutTimer:Cancel()
	end
	self.whoTimeoutTimer = C_Timer.NewTimer(WHO_TIMEOUT, function()
		self.whoTimeoutTimer = nil
		if self.whoPending then
			self.whoPending = false
			self:ShowThrottleHint()
		end
	end)

	-- Show pending state in totals area
	self:ShowPendingState()

	-- Clear selection from previous search results
	self:SetSelectedButton(nil)

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

-- Show "Searching..." in the totals area while waiting for results
-- Also clears old result rows so they don't remain visible underneath
function WhoFrame:ShowPendingState()
	local totalsElement = BetterFriendsFrame
		and BetterFriendsFrame.WhoFrame
		and BetterFriendsFrame.WhoFrame.ListInset
		and BetterFriendsFrame.WhoFrame.ListInset.Totals
	if not totalsElement then
		return
	end

	local L = BFL.L
	local pendingText = L and L.WHO_SEARCH_PENDING or "Searching..."
	if totalsElement.Text then
		totalsElement.Text:SetText(pendingText)
	elseif totalsElement.SetText then
		totalsElement:SetText(pendingText)
	end

	-- Clear old result rows so they don't show below "Searching..."
	if whoDataProvider then
		whoDataProvider:Flush()
	end
	if self.classicWhoDataList then
		wipe(self.classicWhoDataList)
		self:RenderClassicWhoButtons()
	end

	-- Hide the empty state text (we have "Searching..." instead)
	if self.emptyStateText then
		self.emptyStateText:Hide()
	end
end

-- Show a brief hint that the search may have been throttled
function WhoFrame:ShowThrottleHint()
	local totalsElement = BetterFriendsFrame
		and BetterFriendsFrame.WhoFrame
		and BetterFriendsFrame.WhoFrame.ListInset
		and BetterFriendsFrame.WhoFrame.ListInset.Totals
	if not totalsElement then
		return
	end

	local L = BFL.L
	local timeoutText = L and L.WHO_SEARCH_TIMEOUT or "No response. Try again."
	if totalsElement.Text then
		totalsElement.Text:SetText(timeoutText)
	elseif totalsElement.SetText then
		totalsElement:SetText(timeoutText)
	end

	-- Show empty state since results were cleared during pending
	self:UpdateEmptyState(0)
end

-- Start the Refresh button cooldown with countdown text
function WhoFrame:StartRefreshButtonCooldown()
	local whoButton = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.WhoButton
	if not whoButton then
		return
	end

	whoButton:Disable()

	-- Cancel any existing ticker
	if self.buttonCooldownTicker then
		self.buttonCooldownTicker:Cancel()
		self.buttonCooldownTicker = nil
	end

	-- Update button text with countdown
	local L = BFL.L
	local refreshLabel = REFRESH or "Refresh"
	local remaining = WHO_COOLDOWN
	whoButton:SetText(format("%s (%ds)", refreshLabel, remaining))

	self.buttonCooldownTicker = C_Timer.NewTicker(1, function()
		remaining = remaining - 1
		if remaining <= 0 then
			self:StopRefreshButtonCooldown()
		else
			whoButton:SetText(format("%s (%ds)", refreshLabel, remaining))
		end
	end, WHO_COOLDOWN)
end

-- Re-enable the Refresh button and restore its label
function WhoFrame:StopRefreshButtonCooldown()
	if self.buttonCooldownTicker then
		self.buttonCooldownTicker:Cancel()
		self.buttonCooldownTicker = nil
	end

	local whoButton = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.WhoButton
	if not whoButton then
		return
	end

	whoButton:SetText(REFRESH or "Refresh")
	whoButton:Enable()
end

-- Update button when a throttled request is attempted (visual shake / feedback)
function WhoFrame:UpdateRefreshButtonCooldown()
	local whoButton = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.WhoButton
	if not whoButton then
		return
	end

	-- Button should already be disabled with countdown text from StartRefreshButtonCooldown
	-- If somehow it's enabled, re-start the cooldown display
	if whoButton:IsEnabled() then
		self:StartRefreshButtonCooldown()
	end
end

-- Start the builder Search button cooldown with countdown text
function WhoFrame:StartBuilderSearchButtonCooldown()
	local searchBtn = self.builder and self.builder.searchBtn
	if not searchBtn then
		return
	end

	searchBtn:Disable()

	-- Cancel any existing ticker
	if self.builderCooldownTicker then
		self.builderCooldownTicker:Cancel()
		self.builderCooldownTicker = nil
	end

	local L = BFL.L
	local searchLabel = L and L.WHO_BUILDER_SEARCH or "Search"
	local remaining = WHO_COOLDOWN
	searchBtn:SetText(format("%s (%ds)", searchLabel, remaining))

	self.builderCooldownTicker = C_Timer.NewTicker(1, function()
		remaining = remaining - 1
		if remaining <= 0 then
			self:StopBuilderSearchButtonCooldown()
		else
			searchBtn:SetText(format("%s (%ds)", searchLabel, remaining))
		end
	end, WHO_COOLDOWN)
end

-- Re-enable the builder Search button and restore its label
function WhoFrame:StopBuilderSearchButtonCooldown()
	if self.builderCooldownTicker then
		self.builderCooldownTicker:Cancel()
		self.builderCooldownTicker = nil
	end

	local searchBtn = self.builder and self.builder.searchBtn
	if not searchBtn then
		return
	end

	local L = BFL.L
	searchBtn:SetText(L and L.WHO_BUILDER_SEARCH or "Search")
	searchBtn:Enable()
end

-- Update builder Search button when a throttled request is attempted
function WhoFrame:UpdateBuilderSearchButtonCooldown()
	local searchBtn = self.builder and self.builder.searchBtn
	if not searchBtn then
		return
	end

	if searchBtn:IsEnabled() then
		self:StartBuilderSearchButtonCooldown()
	end
end

-- Update Who list display
function WhoFrame:Update(forceRebuild)
	if not BetterFriendsFrame or not BetterFriendsFrame.WhoFrame then
		return
	end

	-- Classic: Check if using Classic mode
	local isClassicMode = BFL.IsClassic or not BFL.HasModernScrollBox

	-- Retail: Check if DataProvider exists
	if not isClassicMode and not whoDataProvider then
		return
	end

	-- Visibility Optimization:
	if not BetterFriendsFrame:IsShown() or not BetterFriendsFrame.WhoFrame:IsShown() then
		needsRenderOnShow = true
		return
	end

	local numWhos, totalCount = C_FriendList.GetNumWhoResults()

	-- Update totals text with improved format
	local L = BFL.L
	local totalsText
	if totalCount == 0 then
		totalsText = ""
	elseif totalCount > MAX_WHOS_FROM_SERVER then
		totalsText = format(L and L.WHO_RESULTS_SHOWING or "%d of %d players", MAX_WHOS_FROM_SERVER, totalCount)
	else
		totalsText = format(WHO_FRAME_TOTAL_TEMPLATE or "Total: %d", totalCount)
	end

	-- Classic: Totals is a Frame with a Text FontString child
	-- Retail: Totals is a FontString directly
	local totalsElement = BetterFriendsFrame.WhoFrame.ListInset.Totals
	if totalsElement then
		if totalsElement.Text then
			totalsElement.Text:SetText(totalsText)
		elseif totalsElement.SetText then
			totalsElement:SetText(totalsText)
		end
	end

	-- Empty state message
	self:UpdateEmptyState(numWhos)

	-- PERFORMANCE: Cache fontObject reference instead of string lookup
	local fontObj = "BetterFriendlistFontNormalSmall"

	-- Classic mode: Build data list and render
	if isClassicMode then
		self.classicWhoDataList = {}
		for i = 1, numWhos do
			local info = C_FriendList.GetWhoInfo(i)
			if info then
				if info.fullName then
					info.fullName = info.fullName:gsub("%-$", "")
				end
				if info.name then
					info.name = info.name:gsub("%-$", "")
				end
				table.insert(self.classicWhoDataList, {
					index = i,
					dataIndex = i,
					info = info,
					fontObject = fontObj,
				})
			end
		end
		self:RenderClassicWhoButtons()
		return
	end

	-- Retail mode: PERFORMANCE: Only rebuild if count changed OR if forced
	local currentSize = whoDataProvider:GetSize()
	if not forceRebuild and currentSize == numWhos and currentSize > 0 then
		return
	end

	-- If a sort is active, delegate to SortByColumn instead of building unsorted
	if BetterFriendsFrame.WhoFrame.currentSort then
		self:SortByColumn(BetterFriendsFrame.WhoFrame.currentSort, true)
		return
	end

	-- No sort active: build unsorted list
	whoDataProvider:Flush()

	for i = 1, numWhos do
		local info = C_FriendList.GetWhoInfo(i)
		if info then
			if info.fullName then
				info.fullName = info.fullName:gsub("%-$", "")
			end
			if info.name then
				info.name = info.name:gsub("%-$", "")
			end
			whoDataProvider:Insert({
				index = i,
				dataIndex = i,
				info = info,
				fontObject = fontObj,
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
		if button.selectionHighlight then
			button.selectionHighlight:Show()
		end
	else
		button:UnlockHighlight()
		if button.selectionHighlight then
			button.selectionHighlight:Hide()
		end
	end
end

-- Sort by column
function WhoFrame:SortByColumn(sortType, preserveDirection)
	-- Store current sort type for client-side sorting
	if not BetterFriendsFrame.WhoFrame.currentSort then
		BetterFriendsFrame.WhoFrame.currentSort = "name"
		BetterFriendsFrame.WhoFrame.sortAscending = true
	end

	-- Toggle sort direction or switch column
	if not preserveDirection and BetterFriendsFrame.WhoFrame.currentSort == sortType then
		BetterFriendsFrame.WhoFrame.sortAscending = not BetterFriendsFrame.WhoFrame.sortAscending
	elseif not preserveDirection then
		-- Save previous sort state for stable sorting
		BetterFriendsFrame.WhoFrame.prevSort = BetterFriendsFrame.WhoFrame.currentSort
		BetterFriendsFrame.WhoFrame.prevSortAscending = BetterFriendsFrame.WhoFrame.sortAscending

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
			table.insert(whoData, { index = i, info = info })
		end
	end

	-- Value extractor helper
	local function GetSortValue(entry, type)
		if type == "name" then
			return entry.info.fullName or ""
		elseif type == "level" then
			return entry.info.level or 0
		elseif type == "class" then
			return entry.info.classStr or ""
		elseif type == "zone" then
			return entry.info.area or ""
		elseif type == "guild" then
			return entry.info.guild or ""
		elseif type == "race" then
			return entry.info.raceStr or ""
		end
		return ""
	end

	local currentSort = BetterFriendsFrame.WhoFrame.currentSort
	local currentAsc = BetterFriendsFrame.WhoFrame.sortAscending
	local prevSort = BetterFriendsFrame.WhoFrame.prevSort
	local prevAsc = BetterFriendsFrame.WhoFrame.prevSortAscending

	-- Sort the data with detailed fallback logic
	table.sort(whoData, function(a, b)
		-- 1. Primary Sort
		local aVal = GetSortValue(a, currentSort)
		local bVal = GetSortValue(b, currentSort)

		if aVal ~= bVal then
			if currentAsc then
				return aVal < bVal
			else
				return aVal > bVal
			end
		end

		-- 2. Secondary Sort (Previous Column)
		if prevSort and prevSort ~= currentSort then
			local aPrev = GetSortValue(a, prevSort)
			local bPrev = GetSortValue(b, prevSort)

			if aPrev ~= bPrev then
				if prevAsc then
					return aPrev < bPrev
				else
					return aPrev > bPrev
				end
			end
		end

		-- 3. Tertiary Sort (Name) - Deterministic fallback
		-- If we aren't already sorting by name (primary or secondary), use Name to break ties
		if currentSort ~= "name" and prevSort ~= "name" then
			local aName = GetSortValue(a, "name")
			local bName = GetSortValue(b, "name")
			return aName < bName
		end

		return false
	end)

	-- Rebuild DataProvider with sorted data
	if whoDataProvider then
		whoDataProvider:Flush()

		local fontObj = "BetterFriendlistFontNormalSmall"
		for i, entry in ipairs(whoData) do
			whoDataProvider:Insert({
				index = i,
				dataIndex = i,
				info = entry.info,
				fontObject = fontObj,
			})
		end
	elseif self.classicWhoFrame or (BFL.IsClassic or not BFL.HasModernScrollBox) then
		-- Classic Mode Support
		self.classicWhoDataList = {}
		local fontObj = "BetterFriendlistFontNormalSmall"
		for i, entry in ipairs(whoData) do
			table.insert(self.classicWhoDataList, {
				index = entry.index,
				dataIndex = i,
				info = entry.info,
				fontObject = fontObj,
			})
		end
		self:RenderClassicWhoButtons()
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
		-- Alt+Click: Add value to Search Builder
		if IsAltKeyDown() and button.info then
			self:HandleAltClick(button)
			return
		end

		-- Ctrl+Click: Interactive column search
		if IsControlKeyDown() and button.info then
			self:HandleCtrlClick(button)
			return
		end

		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:SetSelectedButton(button)
	elseif mouseButton == "RightButton" then
		-- Open context menu for WHO player
		-- Fix for data mismatch: Use stored info if available to ensure correct context menu
		local info = button.info

		-- Fallback for legacy/error cases: Fetch by index
		if not info and button.index then
			info = C_FriendList.GetWhoInfo(button.index)
			-- Must manually sanitize if fetching fresh
			if info then
				if info.fullName then
					info.fullName = info.fullName:gsub("%-$", "")
				end
				if info.name then
					info.name = info.name:gsub("%-$", "")
				end
			end
		end

		if info then
			-- Use MenuSystem module if available
			local MenuSystem = BFL and BFL:GetModule("MenuSystem")
			if MenuSystem and MenuSystem.OpenWhoPlayerMenu then
				MenuSystem:OpenWhoPlayerMenu(button, info)
			else
				-- Fallback: Use basic UnitPopup (with Classic compatibility)
				local contextData = {
					name = info.fullName,
					server = info.fullGuildName,
					guid = info.guid,
				}
				BFL.OpenContextMenu(button, "FRIEND", contextData, info.fullName)
			end
		end
	end
end

-- ========================================
-- ========================================
-- Empty State
-- ========================================

-- Create empty state message for when no results are found
function WhoFrame:CreateEmptyState(frame)
	local parent = frame.ScrollBox or frame
	local emptyText = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
	emptyText:SetPoint("CENTER", parent, "CENTER", 0, 20)
	emptyText:SetText(BFL.L and BFL.L.WHO_NO_RESULTS or "No players found")
	emptyText:SetTextColor(0.5, 0.5, 0.5)
	emptyText:Hide()
	self.emptyStateText = emptyText
end

-- Show/hide empty state based on result count
function WhoFrame:UpdateEmptyState(numWhos)
	if not self.emptyStateText then
		return
	end
	if numWhos == 0 then
		self.emptyStateText:Show()
	else
		self.emptyStateText:Hide()
	end
end

-- ========================================
-- Ctrl+Click Interactive Search
-- ========================================

-- Determine which column the cursor is hovering over based on X position
-- Returns: "name", "variable", "level", "class", or nil
function WhoFrame:GetHoveredColumn(button)
	if not button or not self.columnWidths then
		return nil
	end

	local cursorX = GetCursorPosition()
	local scale = button:GetEffectiveScale()
	cursorX = cursorX / scale

	local buttonLeft = button:GetLeft()
	if not buttonLeft then
		return nil
	end

	local relativeX = cursorX - buttonLeft
	local widths = self.columnWidths
	local headerGap = -2

	-- Column boundaries (accumulated from left)
	local nameEnd = widths.name
	local variableEnd = nameEnd + headerGap + widths.variable
	local levelEnd = variableEnd + headerGap + widths.level

	if relativeX <= nameEnd then
		return "name"
	elseif relativeX <= variableEnd then
		return "variable"
	elseif relativeX <= levelEnd then
		return "level"
	else
		return "class"
	end
end

-- Handle Alt+Click on a WHO result to populate the Search Builder field
function WhoFrame:HandleAltClick(button)
	if not button or not button.info then
		return
	end

	local info = button.info
	local column = self:GetHoveredColumn(button)

	-- Ensure builder exists
	if not self.builder then
		return
	end

	-- Auto-open the Search Builder if not visible
	if not self.builderFlyout or not self.builderFlyout:IsShown() then
		self:ToggleSearchBuilder(true)
	end

	if column == "name" then
		if info.fullName and info.fullName ~= "" then
			local name = info.fullName:match("^([^%-]+)") or info.fullName
			self.builder.nameInput:SetText(name)
		end
	elseif column == "variable" then
		if whoSortValue == 2 and info.fullGuildName and info.fullGuildName ~= "" then
			self.builder.guildInput:SetText(info.fullGuildName)
		elseif whoSortValue == 3 and info.raceStr and info.raceStr ~= "" then
			self.builder.selectedRace = info.raceStr
			self.builder.RebuildRaceDropdown()
			self.builder.RebuildClassDropdown()
		else
			if info.area and info.area ~= "" then
				self.builder.zoneInput:SetText(info.area)
			end
		end
	elseif column == "level" then
		if info.level then
			local levelStr = tostring(info.level)
			self.builder.levelMin:SetText(levelStr)
			self.builder.levelMax:SetText(levelStr)
		end
	elseif column == "class" then
		if info.classStr and info.classStr ~= "" then
			self.builder.selectedClass = info.classStr
			self.builder.RebuildClassDropdown()
			self.builder.RebuildRaceDropdown()
		end
	else
		-- Fallback: use zone
		if info.area and info.area ~= "" then
			self.builder.zoneInput:SetText(info.area)
		end
	end

	self:UpdateBuilderPreview()
end

-- Handle Ctrl+Click on a WHO result to search by the hovered column
function WhoFrame:HandleCtrlClick(button)
	if not button or not button.info then
		return
	end

	local info = button.info
	local searchText
	local column = self:GetHoveredColumn(button)

	if column == "name" then
		if info.fullName and info.fullName ~= "" then
			-- Strip realm suffix for name search
			local name = info.fullName:match("^([^%-]+)") or info.fullName
			searchText = 'n-"' .. name .. '"'
		end
	elseif column == "variable" then
		-- Variable column depends on dropdown selection (Zone/Guild/Race)
		if whoSortValue == 2 and info.fullGuildName and info.fullGuildName ~= "" then
			searchText = 'g-"' .. info.fullGuildName .. '"'
		elseif whoSortValue == 3 and info.raceStr and info.raceStr ~= "" then
			searchText = 'r-"' .. info.raceStr .. '"'
		elseif info.area and info.area ~= "" then
			searchText = 'z-"' .. info.area .. '"'
		end
	elseif column == "level" then
		if info.level then
			searchText = info.level .. "-" .. info.level
		end
	elseif column == "class" then
		if info.classStr and info.classStr ~= "" then
			searchText = 'c-"' .. info.classStr .. '"'
		end
	else
		-- Fallback: search by zone (mirrors original behavior)
		if info.area and info.area ~= "" then
			searchText = 'z-"' .. info.area .. '"'
		end
	end

	if not searchText then
		return
	end

	-- Set search text in edit box and send query
	local editBox = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.EditBox
	if editBox then
		editBox:SetText(searchText)
		editBox:ClearFocus()
	end

	self:SendWhoRequest(searchText)
end

-- ========================================
-- Rich Tooltip (OnEnter/OnLeave)
-- ========================================

-- Show rich tooltip for WHO result button
function _G.BetterWhoListButton_OnEnter(self)
	if not self.tooltipInfo then
		return
	end

	local info = self.tooltipInfo
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	-- Name as header (class-colored if available)
	local classColor = info.filename and RAID_CLASS_COLORS[info.filename]
	if classColor then
		GameTooltip:AddLine(info.fullName or "", classColor.r, classColor.g, classColor.b)
	else
		GameTooltip:AddLine(info.fullName or "", 1, 0.82, 0)
	end

	-- Level, Race, Class line
	local levelRaceClass = ""
	if info.level then
		local diffColor = GetQuestDifficultyColor(info.level)
		local levelStr = format(
			"|cff%02x%02x%02x%s %d|r",
			(diffColor.r or 1) * 255,
			(diffColor.g or 1) * 255,
			(diffColor.b or 1) * 255,
			LEVEL or "Level",
			info.level
		)

		if info.raceStr then
			levelRaceClass = levelStr .. " " .. info.raceStr
		else
			levelRaceClass = levelStr
		end

		if info.classStr then
			if classColor then
				levelRaceClass = levelRaceClass
					.. " |cff"
					.. format("%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
					.. info.classStr
					.. "|r"
			else
				levelRaceClass = levelRaceClass .. " " .. info.classStr
			end
		end
	end
	if levelRaceClass ~= "" then
		GameTooltip:AddLine(levelRaceClass, 1, 1, 1)
	end

	-- Guild
	if info.guild and info.guild ~= "" then
		GameTooltip:AddLine("<" .. info.guild .. ">", 0.25, 1, 0.25)
	end

	-- Zone
	if info.area and info.area ~= "" then
		GameTooltip:AddLine(info.area, 1, 1, 1)
	end

	-- Hints
	GameTooltip:AddLine(" ")
	local L = BFL.L
	GameTooltip:AddLine(L and L.WHO_TOOLTIP_HINT_CLICK or "Click to select", 0.5, 0.5, 0.5)
	local DB = BFL:GetModule("DB")
	local dblClickAction = DB and DB:Get("whoDoubleClickAction", "whisper") or "whisper"
	local dblClickHint
	if dblClickAction == "invite" then
		dblClickHint = L and L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE or "Double-click to invite"
	else
		dblClickHint = L and L.WHO_TOOLTIP_HINT_DBLCLICK or "Double-click to whisper"
	end
	GameTooltip:AddLine(dblClickHint, 0.5, 0.5, 0.5)

	-- Dynamic Ctrl+Click hint based on hovered column
	local WhoFrameModule = BFL:GetModule("WhoFrame")
	local column = WhoFrameModule:GetHoveredColumn(self)
	local columnLabel
	if column == "name" then
		columnLabel = L and L.WHO_BUILDER_NAME or "Name"
	elseif column == "variable" then
		if whoSortValue == 2 then
			columnLabel = L and L.WHO_BUILDER_GUILD or "Guild"
		elseif whoSortValue == 3 then
			columnLabel = L and L.WHO_BUILDER_RACE or "Race"
		else
			columnLabel = L and L.WHO_BUILDER_ZONE or "Zone"
		end
	elseif column == "level" then
		columnLabel = L and L.WHO_BUILDER_LEVEL or "Level"
	elseif column == "class" then
		columnLabel = L and L.WHO_BUILDER_CLASS or "Class"
	end

	if columnLabel then
		local ctrlFormat = L and L.WHO_TOOLTIP_HINT_CTRL_FORMAT or "Ctrl+Click to search %s"
		GameTooltip:AddLine(format(ctrlFormat, columnLabel), 0.5, 0.5, 0.5)
		local altFormat = L and L.WHO_TOOLTIP_HINT_ALT_FORMAT or "Alt+Click to add %s to Search Builder"
		GameTooltip:AddLine(format(altFormat, columnLabel), 0.5, 0.5, 0.5)
	else
		GameTooltip:AddLine(L and L.WHO_TOOLTIP_HINT_CTRL_FORMAT or "Ctrl+Click to search", 0.5, 0.5, 0.5)
	end

	GameTooltip:AddLine(L and L.WHO_TOOLTIP_HINT_RIGHTCLICK or "Right-click for options", 0.5, 0.5, 0.5)

	GameTooltip:Show()

	-- Track hovered column for dynamic tooltip refresh
	self.lastHoveredColumn = column
	if not self.columnTrackingActive then
		self.columnTrackingActive = true
		self:SetScript("OnUpdate", function(btn)
			local WFM = BFL:GetModule("WhoFrame")
			local col = WFM:GetHoveredColumn(btn)
			if col ~= btn.lastHoveredColumn then
				_G.BetterWhoListButton_OnEnter(btn)
			end
		end)
	end

	-- Highlight row
	if self.background then
		self.background:SetColorTexture(0.15, 0.15, 0.3, 0.4)
	end
end

-- Hide tooltip when leaving WHO result button
function _G.BetterWhoListButton_OnLeave(self)
	GameTooltip:Hide()
	self.columnTrackingActive = nil
	self.lastHoveredColumn = nil
	self:SetScript("OnUpdate", nil)

	-- Restore zebra stripe
	if self.background and self.elementData then
		local WhoFrameModule = BFL:GetModule("WhoFrame")
		local zebraStripes = WhoFrameModule:GetSetting("whoZebraStripes", true)
		local dataIndex = self.elementData.dataIndex or self.elementData.index or 1

		if zebraStripes then
			if dataIndex % 2 == 0 then
				self.background:SetColorTexture(
					ZEBRA_EVEN_COLOR.r,
					ZEBRA_EVEN_COLOR.g,
					ZEBRA_EVEN_COLOR.b,
					ZEBRA_EVEN_COLOR.a
				)
			else
				self.background:SetColorTexture(
					ZEBRA_ODD_COLOR.r,
					ZEBRA_ODD_COLOR.g,
					ZEBRA_ODD_COLOR.b,
					ZEBRA_ODD_COLOR.a
				)
			end
		else
			self.background:SetColorTexture(0, 0, 0, 0)
		end
	end
end

-- ========================================
-- Double-Click Handler
-- ========================================

-- Handle double-click on WHO result button
function _G.BetterWhoListButton_OnDoubleClick(self, mouseButton)
	if mouseButton ~= "LeftButton" then
		return
	end

	if not self.info or not self.info.fullName then
		return
	end

	local WhoFrameModule = BFL:GetModule("WhoFrame")
	local action = WhoFrameModule:GetSetting("whoDoubleClickAction", "whisper")

	local name = self.info.fullName
	if action == "invite" then
		BFL.InviteUnit(name)
	else
		ChatFrame_SendTell(name)
	end
end

-- ========================================
-- WHO FRAME UI MIXINS
-- ========================================

-- WHO EditBox Mixin (Blizzard 11.2.5 compatible)
local WhoFrameEditBoxMixin = {}

function WhoFrameEditBoxMixin:OnLoad()
	-- SearchBoxTemplate OnLoad already ran (inherit="append")
	-- KeyValues (instructionText, instructionsFontObject) are already set by SearchBoxTemplate

	-- Hide old-style textures (we use modern SearchBoxTemplate)
	if self.Left then
		self.Left:Hide()
	end
	if self.Middle then
		self.Middle:Hide()
	end
	if self.Right then
		self.Right:Hide()
	end

	-- Set up search icon
	if self.searchIcon then
		self.searchIcon:SetAtlas("glues-characterSelect-icon-search", TextureKitConstants.IgnoreAtlasSize)
	end

	-- Instructions are already configured by SearchBoxTemplate via KeyValues
	-- Just ensure Instructions has proper line wrapping
	if self.Instructions then
		self.Instructions:SetMaxLines(2)
		self.Instructions:SetFontObject("BetterFriendlistFontDisableSmall")
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
	if not self.Instructions then
		return
	end

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
	self.fontObject = "BetterFriendlistFontNormalSmall"

	if self.Text then
		self.Text:SetFontObject("BetterFriendlistFontNormalSmall")
		-- Fix font color: Use white instead of yellow
		self.Text:SetTextColor(1, 1, 1) -- RGB: white
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
		local selectionTexts = { ZONE, GUILD, RACE }
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
			local radio = rootDescription:CreateButton(text, function() end, { value = value, sortType = sortType })
			radio:SetIsSelected(IsSelected)
			radio:SetResponder(SetSelected)
			radio:AddInitializer(function(button, description, menu)
				-- Ensure dropdown items use the correct font
				local fontString = button.fontString or button.Text
				if fontString then
					fontString:SetFontObject("BetterFriendlistFontNormalSmall")
				end
			end)
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
-- WHO SEARCH BUILDER
-- ========================================

-- Race lists for dropdown, split by faction (English internal names used in WHO queries)
local WHO_RACES_ALLIANCE = {
	"Human",
	"Dwarf",
	"Night Elf",
	"Gnome",
	"Draenei",
	"Worgen",
}

local WHO_RACES_HORDE = {
	"Orc",
	"Undead",
	"Tauren",
	"Troll",
	"Blood Elf",
	"Goblin",
}

local WHO_RACES_NEUTRAL = {
	"Pandaren",
}

-- Allied races (Retail only)
local WHO_RACES_ALLIANCE_RETAIL = {
	"Void Elf",
	"Lightforged Draenei",
	"Dark Iron Dwarf",
	"Kul Tiran",
	"Mechagnome",
}

local WHO_RACES_HORDE_RETAIL = {
	"Nightborne",
	"Highmountain Tauren",
	"Mag'har Orc",
	"Zandalari Troll",
	"Vulpera",
}

local WHO_RACES_NEUTRAL_RETAIL = {
	"Dracthyr",
	"Earthen",
	"Haranir",
}

-- ========================================
-- CLASS-RACE COMPATIBILITY TABLES
-- ========================================
-- Source: https://warcraft.wiki.gg/wiki/Class (Race-Class table)
-- Last updated: 2026-02-21 for Midnight 12.0+ / The War Within 11.0+

-- Retail (The War Within 11.0+ / Midnight 12.0+)
local CLASS_RACE_COMPATIBILITY_RETAIL = {
	["Warrior"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Paladin"] = {
		"Human",
		"Dwarf",
		"Draenei",
		"Blood Elf",
		"Tauren",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Zandalari Troll",
		"Earthen",
	},
	["Hunter"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Rogue"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Priest"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Death Knight"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
	},
	["Shaman"] = {
		"Dwarf",
		"Draenei",
		"Pandaren",
		"Orc",
		"Tauren",
		"Troll",
		"Goblin",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Earthen",
		"Haranir",
	},
	["Mage"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Warlock"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Dracthyr",
		"Earthen",
		"Haranir",
	},
	["Monk"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Pandaren",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Void Elf",
		"Lightforged Draenei",
		"Dark Iron Dwarf",
		"Kul Tiran",
		"Mechagnome",
		"Nightborne",
		"Highmountain Tauren",
		"Mag'har Orc",
		"Zandalari Troll",
		"Vulpera",
		"Earthen",
		"Haranir",
	},
	["Druid"] = {
		"Night Elf",
		"Worgen",
		"Tauren",
		"Troll",
		"Kul Tiran",
		"Highmountain Tauren",
		"Zandalari Troll",
		"Haranir",
	},
	["Demon Hunter"] = {
		"Night Elf",
		"Blood Elf",
		"Void Elf", -- Added in Midnight
	},
	["Evoker"] = {
		"Dracthyr",
	},
}

-- Mists of Pandaria Classic 5.x (Monk added, Pandaren added, many new combos)
local CLASS_RACE_COMPATIBILITY_MOP = {
	["Warrior"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Pandaren",
	},
	["Paladin"] = {
		"Human",
		"Dwarf",
		"Draenei",
		"Blood Elf",
		"Tauren", -- Tauren added in Cata 4.0
	},
	["Hunter"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Pandaren",
	},
	["Rogue"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Worgen",
		"Orc",
		"Undead",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Pandaren",
	},
	["Priest"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome", -- NEW in Cata 4.0
		"Draenei",
		"Worgen",
		"Undead",
		"Tauren", -- NEW in Cata 4.0
		"Troll",
		"Blood Elf",
		"Goblin",
		"Pandaren",
	},
	["Death Knight"] = { -- Added in WotLK 3.0, Pandaren DK added in Shadowlands 9.0
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Shaman"] = {
		"Dwarf",
		"Draenei", -- Dwarf added in Cata 4.0
		"Orc",
		"Tauren",
		"Troll",
		"Goblin",
		"Pandaren",
	},
	["Mage"] = {
		"Human",
		"Dwarf", -- NEW in Cata 4.0
		"Night Elf", -- NEW in Cata 4.0
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc", -- NEW in Cata 4.0
		"Undead",
		"Troll",
		"Blood Elf",
		"Goblin",
		"Pandaren",
	},
	["Warlock"] = {
		"Human",
		"Dwarf", -- NEW in Cata 4.0
		"Gnome",
		"Worgen",
		"Orc",
		"Undead",
		"Troll", -- NEW in Cata 4.0
		"Blood Elf",
		"Goblin",
	},
	["Monk"] = { -- NEW in MoP 5.0
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Pandaren",
	},
	["Druid"] = {
		"Night Elf",
		"Worgen",
		"Tauren",
		"Troll", -- Troll added in Cata 4.0
	},
}

-- Cataclysm Classic 4.x (Goblin/Worgen added, many new combos)
local CLASS_RACE_COMPATIBILITY_CATA = {
	["Warrior"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Paladin"] = {
		"Human",
		"Dwarf",
		"Draenei",
		"Blood Elf",
		"Tauren", -- NEW in Cata 4.0
	},
	["Hunter"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Rogue"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Worgen",
		"Orc",
		"Undead",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Priest"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome", -- NEW in Cata 4.0
		"Draenei",
		"Worgen",
		"Undead",
		"Tauren", -- NEW in Cata 4.0
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Death Knight"] = { -- All races (added in WotLK)
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Shaman"] = {
		"Dwarf",
		"Draenei", -- Dwarf NEW in Cata 4.0
		"Orc",
		"Tauren",
		"Troll",
		"Goblin",
	},
	["Mage"] = {
		"Human",
		"Dwarf", -- NEW in Cata 4.0
		"Night Elf", -- NEW in Cata 4.0
		"Gnome",
		"Draenei",
		"Worgen",
		"Orc", -- NEW in Cata 4.0
		"Undead",
		"Troll",
		"Blood Elf",
		"Goblin",
	},
	["Warlock"] = {
		"Human",
		"Dwarf", -- NEW in Cata 4.0
		"Gnome",
		"Worgen",
		"Orc",
		"Undead",
		"Troll", -- NEW in Cata 4.0
		"Blood Elf",
		"Goblin",
	},
	["Druid"] = {
		"Night Elf",
		"Worgen",
		"Tauren",
		"Troll", -- Troll NEW in Cata 4.0
	},
}

-- Classic Era (Vanilla 1.12 / Anniversary) - Original 8 classes only
local CLASS_RACE_COMPATIBILITY_CLASSIC = {
	["Warrior"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Orc",
		"Undead",
		"Tauren",
		"Troll",
	},
	["Paladin"] = {
		"Human",
		"Dwarf", -- Alliance only originally
	},
	["Hunter"] = {
		"Dwarf",
		"Night Elf",
		"Orc",
		"Tauren",
		"Troll",
	},
	["Rogue"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Gnome",
		"Orc",
		"Undead",
		"Troll",
	},
	["Priest"] = {
		"Human",
		"Dwarf",
		"Night Elf",
		"Undead",
		"Troll",
	},
	["Shaman"] = {
		"Orc",
		"Tauren",
		"Troll", -- Horde only originally
	},
	["Mage"] = {
		"Human",
		"Gnome",
		"Undead",
		"Troll",
	},
	["Warlock"] = {
		"Human",
		"Gnome",
		"Orc",
		"Undead",
	},
	["Druid"] = {
		"Night Elf",
		"Tauren",
	},
}

-- Select the appropriate compatibility table based on WoW version
local CLASS_RACE_COMPATIBILITY
if BFL.IsClassicEra then
	CLASS_RACE_COMPATIBILITY = CLASS_RACE_COMPATIBILITY_CLASSIC
elseif BFL.IsCataClassic then
	CLASS_RACE_COMPATIBILITY = CLASS_RACE_COMPATIBILITY_CATA
elseif BFL.IsMoPClassic then
	CLASS_RACE_COMPATIBILITY = CLASS_RACE_COMPATIBILITY_MOP
else
	-- Retail (including Wrath/TBC classic if they exist)
	CLASS_RACE_COMPATIBILITY = CLASS_RACE_COMPATIBILITY_RETAIL
end

-- Helper: Check if a race-class combination is valid
local function IsRaceClassCompatible(raceName, className)
	if not raceName or raceName == "" or not className or className == "" then
		return true -- No selection = all valid
	end

	local compatibleRaces = CLASS_RACE_COMPATIBILITY[className]
	if not compatibleRaces then
		return true -- Unknown class = allow all
	end

	for _, race in ipairs(compatibleRaces) do
		if race == raceName then
			return true
		end
	end

	return false
end

-- Helper: Get races compatible with a class
local function GetCompatibleRacesForClass(className)
	if not className or className == "" then
		return nil -- All races
	end
	return CLASS_RACE_COMPATIBILITY[className]
end

-- Helper: Get classes compatible with a race
local function GetCompatibleClassesForRace(raceName)
	if not raceName or raceName == "" then
		return nil -- All classes
	end

	local compatibleClasses = {}
	for className, races in pairs(CLASS_RACE_COMPATIBILITY) do
		for _, race in ipairs(races) do
			if race == raceName then
				table.insert(compatibleClasses, className)
				break
			end
		end
	end

	return compatibleClasses
end

-- Create the Search Builder UI (trigger button + flyout panel)
function WhoFrame:CreateSearchBuilder(whoFrame)
	local L = BFL.L or {}
	local editBox = whoFrame.EditBox
	if not editBox then
		return
	end

	-- DO NOT modify EditBox anchors. Place the toggle button inside the EditBox,
	-- overlaying the right-side padding area (left of the clear "X" button).
	local toggleBtn = CreateFrame("Button", nil, editBox)
	toggleBtn:SetSize(16, 16)
	toggleBtn:SetPoint("RIGHT", editBox, "RIGHT", -20, 0) -- left of the clear button
	toggleBtn:SetFrameLevel(editBox:GetFrameLevel() + 5)

	local icon = toggleBtn:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\sliders")
	icon:SetSize(14, 14)
	icon:SetPoint("CENTER")
	icon:SetVertexColor(0.7, 0.7, 0.7)
	toggleBtn.icon = icon

	toggleBtn:SetScript("OnEnter", function(self)
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L.WHO_BUILDER_TOOLTIP or "Open Search Builder")
		GameTooltip:Show()
	end)
	toggleBtn:SetScript("OnLeave", function(self)
		if not WhoFrame.builderFlyout or not WhoFrame.builderFlyout:IsShown() then
			self.icon:SetVertexColor(0.7, 0.7, 0.7)
		end
		GameTooltip:Hide()
	end)

	-- Create the flyout panel (match ListInset width)
	local flyout = CreateFrame("Frame", nil, whoFrame, "BackdropTemplate")
	flyout:SetPoint("BOTTOMLEFT", whoFrame.ListInset, "BOTTOMLEFT", 0, 60)
	flyout:SetPoint("BOTTOMRIGHT", whoFrame.ListInset, "BOTTOMRIGHT", 0, 60)
	flyout:SetHeight(235)
	flyout:SetFrameLevel(editBox:GetFrameLevel() + 10)
	flyout:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	flyout:SetBackdropColor(0.08, 0.08, 0.08, 1)
	flyout:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	flyout:Hide()
	flyout:EnableMouse(true) -- Block clicks from passing through

	-- ESC to close
	flyout:EnableKeyboard(true)
	flyout:SetPropagateKeyboardInput(true)
	flyout:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" and not WhoFrame.builderDocked then
			self:SetPropagateKeyboardInput(false)
			WhoFrame:ToggleSearchBuilder(false)
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)

	-- Title bar
	local title = flyout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", flyout, "TOPLEFT", 10, -8)
	title:SetText(L.WHO_BUILDER_TITLE or "Search Builder")

	-- Close button
	local closeBtn = CreateFrame("Button", nil, flyout, "UIPanelCloseButton")
	closeBtn:SetSize(20, 20)
	closeBtn:SetPoint("TOPRIGHT", flyout, "TOPRIGHT", -4, -4)
	closeBtn:SetScript("OnClick", function()
		WhoFrame:ToggleSearchBuilder(false)
	end)

	-- Store title/close references for dock mode switching
	self.builderTitle = title
	self.builderCloseBtn = closeBtn

	-- Build content
	self.builder = {}
	local yOffset = -28
	local labelWidth = 55
	local rowHeight = 24
	local padding = 10

	-- Helper: Create a labeled row with an EditBox
	local function CreateInputRow(parent, labelText, yPos)
		local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, yPos)
		label:SetWidth(labelWidth)
		label:SetJustifyH("LEFT")
		label:SetText(labelText)

		local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		input:SetPoint("LEFT", label, "RIGHT", 6, 0)
		input:SetPoint("RIGHT", parent, "RIGHT", -padding, 0)
		input:SetHeight(20)
		input:SetAutoFocus(false)
		input:SetFontObject("GameFontHighlight")
		input:SetScript("OnTextChanged", function()
			WhoFrame:UpdateBuilderPreview()
		end)
		input:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
			WhoFrame:ExecuteBuilderSearch()
		end)
		input:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
			if not WhoFrame.builderDocked then
				WhoFrame:ToggleSearchBuilder(false)
			end
		end)
		-- Tab navigation handled by WoW default EditBox behavior
		return input
	end

	-- Row 1: Name (max 12 chars = WoW character name limit)
	self.builder.nameInput = CreateInputRow(flyout, (L.WHO_BUILDER_NAME or "Name") .. ":", yOffset)
	self.builder.nameInput:SetMaxLetters(12)
	yOffset = yOffset - rowHeight

	-- Row 2: Guild
	self.builder.guildInput = CreateInputRow(flyout, (L.WHO_BUILDER_GUILD or "Guild") .. ":", yOffset)
	yOffset = yOffset - rowHeight

	-- Row 3: Zone
	self.builder.zoneInput = CreateInputRow(flyout, (L.WHO_BUILDER_ZONE or "Zone") .. ":", yOffset)
	yOffset = yOffset - rowHeight

	-- Row 4: Class dropdown
	local classLabel = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	classLabel:SetPoint("TOPLEFT", flyout, "TOPLEFT", padding, yOffset)
	classLabel:SetWidth(labelWidth)
	classLabel:SetJustifyH("LEFT")
	classLabel:SetText((L.WHO_BUILDER_CLASS or "Class") .. ":")

	self.builder.selectedClass = "" -- "" = All
	self.builder.selectedRace = "" -- "" = All (pre-declare for cross-reference)

	local classDropdown = BFL.CreateDropdown(flyout, nil, 140)
	if BFL.HasModernDropdown then
		classDropdown:SetPoint("LEFT", classLabel, "RIGHT", 0, 0)
	else
		classDropdown:SetPoint("LEFT", classLabel, "RIGHT", -14, -2)
	end
	self.builder.classDropdown = classDropdown

	-- Forward declaration (RebuildRaceDropdown is defined after RebuildClassDropdown)
	local RebuildRaceDropdown

	-- Function to build/rebuild class dropdown with optional race filter
	local function RebuildClassDropdown()
		local classLabels = { L.WHO_BUILDER_ALL_CLASSES or "All Classes" }
		local classValues = { "" }

		local compatibleClasses = GetCompatibleClassesForRace(self.builder.selectedRace)

		-- Collect classes first (excluding "All Classes")
		local tempClasses = {}
		if CLASS_SORT_ORDER then
			for _, classToken in ipairs(CLASS_SORT_ORDER) do
				local localName = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]
				if localName then
					-- Only add if compatible with selected race (or no race selected)
					if not compatibleClasses or tContains(compatibleClasses, localName) then
						table.insert(tempClasses, localName)
					end
				end
			end
		end

		-- Sort alphabetically
		table.sort(tempClasses)

		-- Add sorted classes to dropdown lists
		for _, className in ipairs(tempClasses) do
			table.insert(classLabels, className)
			table.insert(classValues, className)
		end

		BFL.InitializeDropdown(classDropdown, {
			labels = classLabels,
			values = classValues,
		}, function(value)
			return self.builder.selectedClass == value
		end, function(value)
			self.builder.selectedClass = value
			RebuildRaceDropdown()
			self:UpdateBuilderPreview()
		end, 300)
	end

	self.builder.RebuildClassDropdown = RebuildClassDropdown
	yOffset = yOffset - (rowHeight + 2)

	-- Row 5: Race dropdown
	local raceLabel = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	raceLabel:SetPoint("TOPLEFT", flyout, "TOPLEFT", padding, yOffset)
	raceLabel:SetWidth(labelWidth)
	raceLabel:SetJustifyH("LEFT")
	raceLabel:SetText((L.WHO_BUILDER_RACE or "Race") .. ":")

	local raceDropdown = BFL.CreateDropdown(flyout, nil, 140)
	if BFL.HasModernDropdown then
		raceDropdown:SetPoint("LEFT", raceLabel, "RIGHT", 0, 0)
	else
		raceDropdown:SetPoint("LEFT", raceLabel, "RIGHT", -14, -2)
	end
	self.builder.raceDropdown = raceDropdown

	-- Function to build/rebuild race dropdown with optional class filter
	RebuildRaceDropdown = function()
		local raceLabels = { L.WHO_BUILDER_ALL_RACES or "All Races" }
		local raceValues = { "" }

		local compatibleRaces = GetCompatibleRacesForClass(self.builder.selectedClass)
		local faction = UnitFactionGroup("player")

		-- Collect races first (excluding "All Races")
		local tempRaces = {}

		-- Helper: Add race if compatible with selected class
		local function AddRaceIfCompatible(raceName)
			if not compatibleRaces or tContains(compatibleRaces, raceName) then
				table.insert(tempRaces, raceName)
			end
		end

		-- Faction-specific races
		local factionRaces = (faction == "Alliance") and WHO_RACES_ALLIANCE or WHO_RACES_HORDE
		for _, raceName in ipairs(factionRaces) do
			AddRaceIfCompatible(raceName)
		end

		-- Allied races (Retail only)
		if not BFL.IsClassic then
			local retailFactionRaces = (faction == "Alliance") and WHO_RACES_ALLIANCE_RETAIL or WHO_RACES_HORDE_RETAIL
			for _, raceName in ipairs(retailFactionRaces) do
				AddRaceIfCompatible(raceName)
			end
		end

		-- Neutral races
		for _, raceName in ipairs(WHO_RACES_NEUTRAL) do
			AddRaceIfCompatible(raceName)
		end

		if not BFL.IsClassic then
			for _, raceName in ipairs(WHO_RACES_NEUTRAL_RETAIL) do
				AddRaceIfCompatible(raceName)
			end
		end

		-- Sort alphabetically
		table.sort(tempRaces)

		-- Add sorted races to dropdown lists
		for _, raceName in ipairs(tempRaces) do
			table.insert(raceLabels, raceName)
			table.insert(raceValues, raceName)
		end

		BFL.InitializeDropdown(raceDropdown, {
			labels = raceLabels,
			values = raceValues,
		}, function(value)
			return self.builder.selectedRace == value
		end, function(value)
			self.builder.selectedRace = value
			RebuildClassDropdown()
			self:UpdateBuilderPreview()
		end, 300)
	end

	self.builder.RebuildRaceDropdown = RebuildRaceDropdown

	-- Initial build
	RebuildClassDropdown()
	RebuildRaceDropdown()
	yOffset = yOffset - (rowHeight + 2)

	-- Row 6: Level range
	local levelLabel = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	levelLabel:SetPoint("TOPLEFT", flyout, "TOPLEFT", padding, yOffset)
	levelLabel:SetWidth(labelWidth)
	levelLabel:SetJustifyH("LEFT")
	levelLabel:SetText((L.WHO_BUILDER_LEVEL or "Level") .. ":")

	local levelMin = CreateFrame("EditBox", nil, flyout, "InputBoxTemplate")
	levelMin:SetPoint("LEFT", levelLabel, "RIGHT", 6, 0)
	levelMin:SetSize(40, 18)
	levelMin:SetAutoFocus(false)
	levelMin:SetFontObject("GameFontHighlight")
	levelMin:SetNumeric(true)
	levelMin:SetMaxLetters(3)
	levelMin:SetScript("OnTextChanged", function(self)
		-- Cap level to max player level
		local text = self:GetText()
		if text ~= "" then
			local value = tonumber(text)
			if value then
				local maxLevel = BFL.GetMaxLevel()
				if value > maxLevel then
					self:SetText(tostring(maxLevel))
				elseif value < 1 then
					self:SetText("1")
				end
			end
		end
		WhoFrame:UpdateBuilderPreview()
	end)
	levelMin:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		WhoFrame:ExecuteBuilderSearch()
	end)
	levelMin:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		WhoFrame:ToggleSearchBuilder(false)
	end)
	self.builder.levelMin = levelMin

	local levelMax = CreateFrame("EditBox", nil, flyout, "InputBoxTemplate")
	levelMax:SetPoint("LEFT", levelMin, "RIGHT", 50, 0)

	local toLabel = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	toLabel:SetPoint("LEFT", levelMin, "RIGHT", 0, 0)
	toLabel:SetPoint("RIGHT", levelMax, "LEFT", 0, 0)
	toLabel:SetJustifyH("CENTER")
	toLabel:SetText(L.WHO_BUILDER_LEVEL_TO or "to")
	levelMax:SetSize(40, 18)
	levelMax:SetAutoFocus(false)
	levelMax:SetFontObject("GameFontHighlight")
	levelMax:SetNumeric(true)
	levelMax:SetMaxLetters(3)
	levelMax:SetScript("OnTextChanged", function(self)
		-- Cap level to max player level
		local text = self:GetText()
		if text ~= "" then
			local value = tonumber(text)
			if value then
				local maxLevel = BFL.GetMaxLevel()
				if value > maxLevel then
					self:SetText(tostring(maxLevel))
				elseif value < 1 then
					self:SetText("1")
				end
			end
		end
		WhoFrame:UpdateBuilderPreview()
	end)
	levelMax:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		WhoFrame:ExecuteBuilderSearch()
	end)
	levelMax:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		WhoFrame:ToggleSearchBuilder(false)
	end)
	self.builder.levelMax = levelMax
	yOffset = yOffset - rowHeight

	-- Separator line
	local sep = flyout:CreateTexture(nil, "ARTWORK")
	sep:SetColorTexture(0.4, 0.4, 0.4, 0.5)
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", flyout, "TOPLEFT", padding, yOffset - 2)
	sep:SetPoint("TOPRIGHT", flyout, "TOPRIGHT", -padding, yOffset - 2)
	yOffset = yOffset - 6

	-- Buttons row (anchored flush to bottom)
	local searchBtn = CreateFrame("Button", nil, flyout, "UIPanelButtonTemplate")
	searchBtn:SetSize(80, 22)
	searchBtn:SetPoint("BOTTOMRIGHT", flyout, "BOTTOM", -2, 6)
	searchBtn:SetText(L.WHO_BUILDER_SEARCH or "Search")
	searchBtn:SetScript("OnClick", function()
		WhoFrame:ExecuteBuilderSearch()
	end)
	self.builder.searchBtn = searchBtn

	local resetBtn = CreateFrame("Button", nil, flyout, "UIPanelButtonTemplate")
	resetBtn:SetSize(80, 22)
	resetBtn:SetPoint("BOTTOMLEFT", flyout, "BOTTOM", 2, 6)
	resetBtn:SetText(L.WHO_BUILDER_RESET or "Reset")
	resetBtn:SetScript("OnClick", function()
		WhoFrame:ResetBuilder()
	end)

	-- Preview row (between separator and buttons, using TOPLEFT for proper multi-line alignment)
	local previewLabel = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	previewLabel:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, -4)
	previewLabel:SetText(L.WHO_BUILDER_PREVIEW or "Preview:")
	previewLabel:SetTextColor(0.6, 0.6, 0.6)
	previewLabel:SetJustifyV("TOP")

	local previewText = flyout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	previewText:SetPoint("TOPLEFT", previewLabel, "TOPRIGHT", 4, 0)
	previewText:SetPoint("RIGHT", flyout, "RIGHT", -6, 0)
	previewText:SetJustifyH("LEFT")
	previewText:SetJustifyV("TOP")
	previewText:SetTextColor(1, 0.82, 0)
	previewText:SetWordWrap(true)
	previewText:SetText(L.WHO_BUILDER_PREVIEW_EMPTY or "Fill in fields to build a search")
	self.builder.previewText = previewText
	self.builder.previewLabel = previewLabel

	-- Dock toggle button (next to close button in title bar)
	local dockBtn = CreateFrame("Button", nil, flyout)
	dockBtn:SetSize(16, 16)
	dockBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
	dockBtn:SetFrameLevel(flyout:GetFrameLevel() + 2)

	local dockIcon = dockBtn:CreateTexture(nil, "ARTWORK")
	dockIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\maximize-2")
	dockIcon:SetSize(12, 12)
	dockIcon:SetPoint("CENTER")
	dockIcon:SetVertexColor(0.7, 0.7, 0.7)
	dockBtn.icon = dockIcon

	dockBtn:SetScript("OnEnter", function(self)
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if WhoFrame.builderDocked then
			GameTooltip:AddLine(L.WHO_BUILDER_UNDOCK_TOOLTIP or "Undock Search Builder")
		else
			GameTooltip:AddLine(L.WHO_BUILDER_DOCK_TOOLTIP or "Dock Search Builder")
		end
		GameTooltip:Show()
	end)
	dockBtn:SetScript("OnLeave", function(self)
		self.icon:SetVertexColor(0.7, 0.7, 0.7)
		GameTooltip:Hide()
	end)
	dockBtn:SetScript("OnClick", function()
		WhoFrame:SetBuilderDocked(not WhoFrame.builderDocked)
	end)
	self.builderDockBtn = dockBtn

	-- Store references
	self.builderFlyout = flyout
	self.builderToggle = toggleBtn

	-- Toggle button click
	toggleBtn:SetScript("OnClick", function()
		WhoFrame:ToggleSearchBuilder(not flyout:IsShown())
	end)

	-- Store whoFrame reference for re-anchoring
	self.builderWhoFrame = whoFrame
end

-- Create the ButtonFrameTemplate container for docked mode (lazy, one-time)
function WhoFrame:GetOrCreateDockedContainer()
	if self.builderDockedContainer then
		return self.builderDockedContainer
	end

	local L = BFL.L or {}
	local template = BFL.IsClassic and "BasicFrameTemplateWithInset" or "ButtonFrameTemplate"
	local container = CreateFrame("Frame", "BetterFriendlistSearchBuilderFrame", BetterFriendsFrame, template)
	container:SetSize(240, 240)
	container:EnableMouse(true)
	container:SetMovable(false)
	container:Hide()

	if not BFL.IsClassic then
		-- Retail: hide portrait from ButtonFrameTemplate
		if container.portrait then
			container.portrait:Hide()
		end
		if container.PortraitContainer then
			container.PortraitContainer:Hide()
		end
		if ButtonFrameTemplate_HidePortrait then
			ButtonFrameTemplate_HidePortrait(container)
		end
		if ButtonFrameTemplate_HideAttic then
			ButtonFrameTemplate_HideAttic(container)
		end
	end

	-- Set title
	if container.TitleText and container.TitleText.SetText then
		container.TitleText:SetText(L.WHO_BUILDER_TITLE or "Search Builder")
	elseif container.TitleContainer and container.TitleContainer.TitleText then
		container.TitleContainer.TitleText:SetText(L.WHO_BUILDER_TITLE or "Search Builder")
	end

	-- Hide default Inset (we use the flyout content directly)
	if container.Inset then
		container.Inset:Hide()
	end
	if container.InsetRight then
		container.InsetRight:Hide()
	end

	-- Override close button to toggle builder
	if container.CloseButton then
		container.CloseButton:SetScript("OnClick", function()
			WhoFrame:ToggleSearchBuilder(false)
		end)
	end

	self.builderDockedContainer = container
	return container
end

-- Set the Search Builder to docked or flyout mode
function WhoFrame:SetBuilderDocked(docked)
	local flyout = self.builderFlyout
	local whoFrame = self.builderWhoFrame
	if not flyout or not whoFrame then
		return
	end

	local DB = BFL:GetModule("DB")
	self.builderDocked = docked
	DB:Set("whoSearchBuilderDocked", docked)

	flyout:ClearAllPoints()

	if docked then
		-- Create (or get) the ButtonFrameTemplate container
		local container = self:GetOrCreateDockedContainer()
		container:ClearAllPoints()
		container:SetPoint("BOTTOMLEFT", BetterFriendsFrame, "BOTTOMRIGHT", 2, 0)
		container:SetFrameStrata("HIGH")

		-- Reparent flyout into the container and fill it
		flyout:SetParent(container)
		flyout:ClearAllPoints()
		flyout:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -22)
		flyout:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -4, 4)

		-- Hide flyout's own backdrop, title bar, and close button (container provides these)
		flyout:SetBackdrop(nil)
		if self.builderTitle then
			self.builderTitle:Hide()
		end
		if self.builderCloseBtn then
			self.builderCloseBtn:Hide()
		end

		-- Move dock button to the container's title bar
		if self.builderDockBtn then
			self.builderDockBtn:SetParent(container)
			self.builderDockBtn:ClearAllPoints()
			if container.CloseButton then
				self.builderDockBtn:SetPoint("RIGHT", container.CloseButton, "LEFT", -2, 0)
				self.builderDockBtn:SetFrameStrata(container.CloseButton:GetFrameStrata())
				self.builderDockBtn:SetFrameLevel(container.CloseButton:GetFrameLevel())
			else
				self.builderDockBtn:SetPoint("TOPRIGHT", container, "TOPRIGHT", -28, -4)
				self.builderDockBtn:SetFrameLevel(container:GetFrameLevel() + 10)
			end
		end

		-- Show the container if the builder flyout is currently visible
		if flyout:IsShown() then
			container:Show()
		end

		-- Hide preview (live EditBox replaces it)
		if self.builder.previewLabel then
			self.builder.previewLabel:Hide()
		end
		if self.builder.previewText then
			self.builder.previewText:Hide()
		end

		-- Update dock button icon to "minimize" (undock)
		if self.builderDockBtn then
			self.builderDockBtn.icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\minimize-2")
		end
	else
		-- Hide the docked container
		if self.builderDockedContainer then
			self.builderDockedContainer:Hide()
		end

		-- Undock: restore original flyout position inside WhoFrame
		flyout:SetParent(whoFrame)
		flyout:ClearAllPoints()
		flyout:SetFrameStrata(whoFrame:GetFrameStrata())
		local editBox = whoFrame.EditBox
		if editBox then
			flyout:SetFrameLevel(editBox:GetFrameLevel() + 10)
		end
		flyout:SetPoint("BOTTOMLEFT", whoFrame.ListInset, "BOTTOMLEFT", 0, 60)
		flyout:SetPoint("BOTTOMRIGHT", whoFrame.ListInset, "BOTTOMRIGHT", 0, 60)
		flyout:SetHeight(235)

		-- Restore flyout's own backdrop, title bar, and close button
		flyout:SetBackdrop({
			bgFile = "Interface\\BUTTONS\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		flyout:SetBackdropColor(0.08, 0.08, 0.08, 1)
		flyout:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
		if self.builderTitle then
			self.builderTitle:Show()
		end
		if self.builderCloseBtn then
			self.builderCloseBtn:Show()
		end

		-- Move dock button back to flyout title bar
		if self.builderDockBtn and self.builderCloseBtn then
			self.builderDockBtn:SetParent(flyout)
			self.builderDockBtn:ClearAllPoints()
			self.builderDockBtn:SetPoint("RIGHT", self.builderCloseBtn, "LEFT", -2, 0)
			self.builderDockBtn:SetFrameLevel(flyout:GetFrameLevel() + 2)
		end

		-- Show preview again
		if self.builder.previewLabel then
			self.builder.previewLabel:Show()
		end
		if self.builder.previewText then
			self.builder.previewText:Show()
		end

		-- Update dock button icon to "maximize" (dock)
		if self.builderDockBtn then
			self.builderDockBtn.icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\maximize-2")
		end
	end

	-- Sync current state
	self:UpdateBuilderPreview()
end

-- Toggle the Search Builder flyout open/closed
function WhoFrame:ToggleSearchBuilder(show)
	if not self.builderFlyout then
		return
	end

	if show then
		-- In docked mode, also show the container
		if self.builderDocked and self.builderDockedContainer then
			self.builderDockedContainer:Show()
		end
		self.builderFlyout:Show()
		self.builderToggle.icon:SetVertexColor(1, 0.82, 0) -- Gold tint when active
		self:UpdateBuilderPreview()
	else
		self.builderFlyout:Hide()
		-- In docked mode, also hide the container
		if self.builderDocked and self.builderDockedContainer then
			self.builderDockedContainer:Hide()
		end
		self.builderToggle.icon:SetVertexColor(0.7, 0.7, 0.7) -- Dim when inactive
		-- Clear focus from all builder inputs
		if self.builder then
			if self.builder.nameInput then
				self.builder.nameInput:ClearFocus()
			end
			if self.builder.guildInput then
				self.builder.guildInput:ClearFocus()
			end
			if self.builder.zoneInput then
				self.builder.zoneInput:ClearFocus()
			end
			if self.builder.levelMin then
				self.builder.levelMin:ClearFocus()
			end
			if self.builder.levelMax then
				self.builder.levelMax:ClearFocus()
			end
		end
	end
end

-- Compose the WHO query string from builder fields
function WhoFrame:ComposeBuilderQuery()
	if not self.builder then
		return ""
	end

	local parts = {}

	local name = self.builder.nameInput and self.builder.nameInput:GetText() or ""
	if name ~= "" then
		table.insert(parts, 'n-"' .. name .. '"')
	end

	local guild = self.builder.guildInput and self.builder.guildInput:GetText() or ""
	if guild ~= "" then
		table.insert(parts, 'g-"' .. guild .. '"')
	end

	local zone = self.builder.zoneInput and self.builder.zoneInput:GetText() or ""
	if zone ~= "" then
		table.insert(parts, 'z-"' .. zone .. '"')
	end

	local class = self.builder.selectedClass or ""
	if class ~= "" then
		table.insert(parts, 'c-"' .. class .. '"')
	end

	local race = self.builder.selectedRace or ""
	if race ~= "" then
		table.insert(parts, 'r-"' .. race .. '"')
	end

	local minLvl = self.builder.levelMin and self.builder.levelMin:GetText() or ""
	local maxLvl = self.builder.levelMax and self.builder.levelMax:GetText() or ""
	if minLvl ~= "" and maxLvl ~= "" then
		table.insert(parts, minLvl .. "-" .. maxLvl)
	elseif minLvl ~= "" then
		table.insert(parts, minLvl .. "-" .. minLvl)
	elseif maxLvl ~= "" then
		table.insert(parts, "1-" .. maxLvl)
	end

	return table.concat(parts, " ")
end

-- Update the live preview text (or live-update EditBox in docked mode)
function WhoFrame:UpdateBuilderPreview()
	if not self.builder then
		return
	end

	local query = self:ComposeBuilderQuery()
	local L = BFL.L or {}

	-- In docked mode, write directly to the WHO EditBox
	if self.builderDocked then
		local editBox = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.EditBox
		if editBox then
			editBox:SetText(query)
		end
		return
	end

	-- Flyout mode: update preview text
	if not self.builder.previewText then
		return
	end

	if query == "" then
		self.builder.previewText:SetText(L.WHO_BUILDER_PREVIEW_EMPTY or "Fill in fields to build a search")
		self.builder.previewText:SetTextColor(0.5, 0.5, 0.5)
	else
		self.builder.previewText:SetText(query)
		self.builder.previewText:SetTextColor(1, 0.82, 0)
	end
end

-- Execute the builder search
function WhoFrame:ExecuteBuilderSearch()
	-- Don't close the builder or search during cooldown
	if self:IsOnCooldown() then
		self:UpdateBuilderSearchButtonCooldown()
		return
	end

	local query = self:ComposeBuilderQuery()
	if query == "" then
		return
	end

	-- Set in EditBox for visibility
	local editBox = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.EditBox
	if editBox then
		editBox:SetText(query)
		editBox:ClearFocus()
	end

	-- In docked mode, keep builder open; in flyout mode, close it
	if not self.builderDocked then
		self:ToggleSearchBuilder(false)
	end

	-- Send the WHO request
	self:SendWhoRequest(query)
end

-- Reset all builder fields
function WhoFrame:ResetBuilder()
	if not self.builder then
		return
	end

	if self.builder.nameInput then
		self.builder.nameInput:SetText("")
	end
	if self.builder.guildInput then
		self.builder.guildInput:SetText("")
	end
	if self.builder.zoneInput then
		self.builder.zoneInput:SetText("")
	end
	if self.builder.levelMin then
		self.builder.levelMin:SetText("")
	end
	if self.builder.levelMax then
		self.builder.levelMax:SetText("")
	end

	self.builder.selectedClass = ""
	self.builder.selectedRace = ""

	-- Rebuild dropdowns to show full lists (no filtering)
	if self.builder.RebuildClassDropdown then
		self.builder.RebuildClassDropdown()
	end
	if self.builder.RebuildRaceDropdown then
		self.builder.RebuildRaceDropdown()
	end

	-- In docked mode, also clear the WHO EditBox
	if self.builderDocked then
		local editBox = BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame.EditBox
		if editBox then
			editBox:SetText("")
		end
	end

	self:UpdateBuilderPreview()
end

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
