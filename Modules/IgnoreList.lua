-- Modules/IgnoreList.lua
-- Ignore List System Module
-- Manages the ignore list window, player selection, and unignore functionality

local ADDON_NAME, BFL = ...

-- Register Module
local IgnoreList = BFL:RegisterModule("IgnoreList", {})

-- ========================================
-- Module Dependencies
-- ========================================

-- No direct dependencies, uses global WoW API

-- ========================================
-- Local Variables
-- ========================================

-- ========================================
-- Public API
-- ========================================

-- Initialize (called from ADDON_LOADED)
function IgnoreList:Initialize()
	-- Nothing to initialize yet
end

-- Initialize Ignore List Window (FriendsIgnoreListMixin:OnLoad)
function IgnoreList:OnLoad(frame)
	-- Set up frame visuals matching Blizzard's InitializeFrameVisuals
	ButtonFrameTemplate_HidePortrait(frame)
	frame:SetTitle(IGNORE_LIST)
	
	if frame.TopTileStreaks then
		frame.TopTileStreaks:Hide()
	end
	
	-- Position Inset (matching Blizzard's exact positioning)
	if frame.Inset then
		frame.Inset:ClearAllPoints()
		frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -28)
		frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 36)
	end
	
	-- Position ScrollBox inside Inset (matching Blizzard's exact positioning)
	if frame.ScrollBox and frame.Inset then
		frame.ScrollBox:ClearAllPoints()
		frame.ScrollBox:SetPoint("TOPLEFT", frame.Inset, 5, -5)
		frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.Inset, -22, 2)
	end
	
	-- Localization Fix for Unignore Button
	if frame.UnignorePlayerButton then
		-- Use global string or fallback
		frame.UnignorePlayerButton:SetText(UNIGNORE or BFL.L.IGNORE_LIST_UNIGNORE)
	end
	
	-- Global Ignore List Integration
	if frame.GlobalIgnoreListButton then
		-- Safe check for addon loaded
		local loaded = false
		if C_AddOns and C_AddOns.IsAddOnLoaded then
			loaded = C_AddOns.IsAddOnLoaded("GlobalIgnoreList")
		elseif IsAddOnLoaded then
			loaded = IsAddOnLoaded("GlobalIgnoreList")
		end

		if loaded then
			frame.GlobalIgnoreListButton:Show()
		else
			frame.GlobalIgnoreListButton:Hide()
		end
	end
	
	-- Classic: Use FauxScrollFrame approach
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- BFL:DebugPrint("|cff00ffffIgnoreList:|r Using Classic FauxScrollFrame mode")
		self:InitializeClassicIgnoreList(frame)
		return
	end
	
	-- Retail: Initialize ScrollBox with element factory (exact Blizzard implementation)
	-- BFL:DebugPrint("|cff00ffffIgnoreList:|r Using Retail ScrollBox mode")
	local scrollBoxView = CreateScrollBoxListLinearView()
	scrollBoxView:SetElementFactory(function(factory, elementData)
		if elementData.header then
			factory(elementData.header)
		else
			factory("BetterIgnoreListButtonTemplate", function(button, data)
				IgnoreList:InitButton(button, data)
			end)
		end
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, scrollBoxView)
end

-- Initialize Classic IgnoreList FauxScrollFrame
function IgnoreList:InitializeClassicIgnoreList(frame)
	self.classicIgnoreFrame = frame
	self.classicIgnoreButtonPool = {}
	self.classicIgnoreDataList = {}
	
	local BUTTON_HEIGHT = 16
	local NUM_BUTTONS = 15
	
	-- Create buttons for Classic mode
	for i = 1, NUM_BUTTONS do
		local button = CreateFrame("Button", "BetterIgnoreListButton" .. i, frame.Inset or frame, "BetterIgnoreListButtonTemplate")
		button:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 5, -((i - 1) * BUTTON_HEIGHT) - 5)
		button:SetPoint("RIGHT", frame.Inset or frame, "RIGHT", -27, 0)
		button:SetHeight(BUTTON_HEIGHT)
		button.classicIndex = i
		button:Hide()
		self.classicIgnoreButtonPool[i] = button
	end
	
	-- Create scroll bar
	local parent = frame.Inset or frame
	if not parent.ClassicScrollBar then
		-- Clean up old named scrollbar if exists
		if _G["BetterIgnoreScrollBar"] then
			_G["BetterIgnoreScrollBar"]:Hide()
			_G["BetterIgnoreScrollBar"] = nil
		end
		
		-- Use Standard UIPanelScrollBarTemplate
		local scrollBar = CreateFrame("Slider", "BetterIgnoreListScrollBar", parent, "UIPanelScrollBarTemplate")
		scrollBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -16)
		scrollBar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 16)
		-- Adjust width slightly if needed, template usually handles it
		
		scrollBar:SetScript("OnValueChanged", function(self, value)
			IgnoreList:RenderClassicIgnoreButtons()
		end)
		
		-- Set value AFTER scripts are registered (Classic requirement)
		scrollBar:SetValue(0)
		
		parent.ClassicScrollBar = scrollBar
	end
end

-- Render Classic Ignore buttons
function IgnoreList:RenderClassicIgnoreButtons()
	if not self.classicIgnoreButtonPool then return end
	
	local dataList = self.classicIgnoreDataList or {}
	local numItems = #dataList
	local numButtons = #self.classicIgnoreButtonPool
	local offset = 0
	
	local parent = self.classicIgnoreFrame.Inset or self.classicIgnoreFrame
	if parent.ClassicScrollBar then
		offset = math.floor(parent.ClassicScrollBar:GetValue() or 0)
	end
	
	-- Update scroll bar range
	if parent.ClassicScrollBar then
		local maxValue = math.max(0, numItems - numButtons)
		parent.ClassicScrollBar:SetMinMaxValues(0, maxValue)
	end
	
	-- Render buttons
	for i, button in ipairs(self.classicIgnoreButtonPool) do
		local dataIndex = offset + i
		if dataIndex <= numItems then
			local elementData = dataList[dataIndex]
			if not elementData.header then
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

-- Initialize a button in the ignore list (exact Blizzard implementation)
function IgnoreList:InitButton(button, elementData)
	button.index = elementData.index

	if elementData.squelchType == SQUELCH_TYPE_IGNORE then
		local name = C_FriendList.GetIgnoreName(button.index)
		if not name then
			button.name:SetText(UNKNOWN)
		else
			button.name:SetText(name)
			button.type = SQUELCH_TYPE_IGNORE
		end
	elseif elementData.squelchType == SQUELCH_TYPE_BLOCK_INVITE then
		local blockID, blockName = BNGetBlockedInfo(button.index)
		button.name:SetText(blockName)
		button.type = SQUELCH_TYPE_BLOCK_INVITE
	end

	local selectedSquelchType, selectedSquelchIndex = self:GetSelected()
	local selected = (selectedSquelchType == button.type) and (selectedSquelchIndex == button.index)
	self:SetButtonSelected(button, selected)
end

-- Get current selection (exact Blizzard implementation)
function IgnoreList:GetSelected()
	local selectedSquelchType = BetterFriendsFrame.selectedSquelchType
	local selectedSquelchIndex = 0
	if selectedSquelchType == SQUELCH_TYPE_IGNORE then
		selectedSquelchIndex = C_FriendList.GetSelectedIgnore() or 0
	elseif selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE then
		selectedSquelchIndex = BNGetSelectedBlock()
	end
	return selectedSquelchType, selectedSquelchIndex
end

-- Set button selection state (exact Blizzard implementation)
function IgnoreList:SetButtonSelected(button, selected)
	if selected then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
end

-- Update the ignore list display (exact Blizzard implementation)
function IgnoreList:Update()
	if not BetterFriendsFrame or not BetterFriendsFrame.IgnoreListWindow then
		return
	end
	
	-- Global Ignore List Integration Check
	local ignoreFrame = BetterFriendsFrame.IgnoreListWindow
	if ignoreFrame.GlobalIgnoreListButton then
		local loaded = false
		if C_AddOns and C_AddOns.IsAddOnLoaded then
			loaded = C_AddOns.IsAddOnLoaded("GlobalIgnoreList")
		elseif IsAddOnLoaded then
			loaded = IsAddOnLoaded("GlobalIgnoreList")
		end
		
		ignoreFrame.GlobalIgnoreListButton:SetShown(loaded)
	end
	
	-- Build data list for both modes
	local dataList = {}

	local numIgnores = C_FriendList.GetNumIgnores()
	-- Always show header, even when empty (except in Classic/FauxScrollFrame mode)
	if not BFL.IsClassic and BFL.HasModernScrollBox then
		table.insert(dataList, {header="BetterFriendsFrameIgnoredHeaderTemplate"})
	end

	if numIgnores and numIgnores > 0 then
		for index = 1, numIgnores do
			table.insert(dataList, {squelchType=SQUELCH_TYPE_IGNORE, index=index})
		end
	end

	local numBlocks = BNGetNumBlocked()
	if numBlocks and numBlocks > 0 then
		if not BFL.IsClassic and BFL.HasModernScrollBox then
			table.insert(dataList, {header="BetterFriendsFrameBlockedInviteHeaderTemplate"})
		end
		for index = 1, numBlocks do
			table.insert(dataList, {squelchType=SQUELCH_TYPE_BLOCK_INVITE, index=index})
		end
	end
	
	-- Classic mode: Use simple list and render
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		self.classicIgnoreDataList = dataList
		self:RenderClassicIgnoreButtons()
	else
		-- Retail mode: Use DataProvider
		local dataProvider = CreateDataProvider()
		for _, data in ipairs(dataList) do
			dataProvider:Insert(data)
		end
		BetterFriendsFrame.IgnoreListWindow.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end

	local selectedSquelchType, selectedSquelchIndex = self:GetSelected()

	local hasSelection = selectedSquelchType and selectedSquelchIndex > 0
	if not hasSelection then
		-- Auto-select first entry if nothing selected
		for _, elementData in ipairs(dataList) do
			if elementData.squelchType ~= nil then
				self:SelectSquelched(elementData.squelchType, elementData.index)
				hasSelection = true
				break
			end
		end
	end

	BetterFriendsFrame.IgnoreListWindow.UnignorePlayerButton:SetEnabled(hasSelection)
end

-- Select a squelched player (exact Blizzard implementation)
function IgnoreList:SelectSquelched(squelchType, index)
	local oldSquelchType, oldSquelchIndex = self:GetSelected()

	if squelchType == SQUELCH_TYPE_IGNORE then
		C_FriendList.SetSelectedIgnore(index)
	elseif squelchType == SQUELCH_TYPE_BLOCK_INVITE then
		BNSetSelectedBlock(index)
	end
	BetterFriendsFrame.selectedSquelchType = squelchType

	local function UpdateButtonSelection(type, index, selected)
		local button = nil
		
		-- Classic mode: Manual iteration through button pool
		if BFL.IsClassic or not BFL.HasModernScrollBox then
			if self.classicIgnoreButtonPool then
				for _, btn in ipairs(self.classicIgnoreButtonPool) do
					if btn.type == type and btn.index == index then
						button = btn
						break
					end
				end
			end
		else
			-- Retail mode: Use FindFrameByPredicate
			button = BetterFriendsFrame.IgnoreListWindow.ScrollBox:FindFrameByPredicate(function(button, elementData)
				return elementData.squelchType == type and elementData.index == index
			end)
		end
		
		if button then
			self:SetButtonSelected(button, selected)
		end
	end

	UpdateButtonSelection(oldSquelchType, oldSquelchIndex, false)
	UpdateButtonSelection(squelchType, index, true)
end

-- Unignore the selected player (exact Blizzard implementation: FriendsFrameUnsquelchButton_OnClick)
function IgnoreList:Unignore()
	local selectedSquelchType = BetterFriendsFrame.selectedSquelchType
	if selectedSquelchType == SQUELCH_TYPE_IGNORE then
		C_FriendList.DelIgnoreByIndex(C_FriendList.GetSelectedIgnore())
	elseif selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE then
		local blockID = BNGetBlockedInfo(BNGetSelectedBlock())
		BNSetBlocked(blockID, false)
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Toggle Ignore List Window visibility (FriendsIgnoreListMixin:ToggleFrame)
function IgnoreList:Toggle()
	local frame = BetterFriendsFrame
	if not frame or not frame.IgnoreListWindow then return end
	
	frame.IgnoreListWindow:SetShown(not frame.IgnoreListWindow:IsShown())
	PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
end

-- ========================================
-- Global XML Event Handlers
-- ========================================

function BetterIgnoreListButton_OnClick(button)
	local IgnoreList = BFL:GetModule("IgnoreList")
	if IgnoreList and button.type and button.index then
		IgnoreList:SelectSquelched(button.type, button.index)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end

function BetterIgnoreList_Unignore()
	local IgnoreList = BFL:GetModule("IgnoreList")
	if IgnoreList then
		IgnoreList:Unignore()
	end
end

function BetterIgnoreList_ToggleGIL()
	-- 1. Try to toggle existing frame directly (Best way)
	local gilFrame = _G["GIL"]
	if gilFrame then
		gilFrame:SetShown(not gilFrame:IsShown())
		if gilFrame:IsShown() then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		else
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		end
		return
	end

	-- 2. If frame doesn't exist, try to load it via slash command
	local loaded = false
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		loaded = C_AddOns.IsAddOnLoaded("GlobalIgnoreList")
	elseif IsAddOnLoaded then
		loaded = IsAddOnLoaded("GlobalIgnoreList")
	end
	
	if loaded then
		if SlashCmdList and SlashCmdList["GIGNORE"] then
			-- This creates the frame AND shows it
			SlashCmdList["GIGNORE"]("ui")
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		else
			if BFL then
				BFL:DebugPrint("BetterIgnoreList_ToggleGIL: GlobalIgnoreList loaded but SlashCmdList['GIGNORE'] is missing.")
			end
		end
	end
end
