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
	
	-- Initialize ScrollBox with element factory (exact Blizzard implementation)
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
	
	local dataProvider = CreateDataProvider()

	local numIgnores = C_FriendList.GetNumIgnores()
	if numIgnores and numIgnores > 0 then
		dataProvider:Insert({header="BetterFriendsFrameIgnoredHeaderTemplate"})
		for index = 1, numIgnores do
			dataProvider:Insert({squelchType=SQUELCH_TYPE_IGNORE, index=index})
		end
	end

	local numBlocks = BNGetNumBlocked()
	if numBlocks and numBlocks > 0 then
		dataProvider:Insert({header="BetterFriendsFrameBlockedInviteHeaderTemplate"})
		for index = 1, numBlocks do
			dataProvider:Insert({squelchType=SQUELCH_TYPE_BLOCK_INVITE, index=index})
		end
	end
	BetterFriendsFrame.IgnoreListWindow.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

	local selectedSquelchType, selectedSquelchIndex = self:GetSelected()

	local hasSelection = selectedSquelchType and selectedSquelchIndex > 0
	if not hasSelection then
		-- Auto-select first entry if nothing selected
		local elementData = dataProvider:FindElementDataByPredicate(function(elementData)
			return elementData.squelchType ~= nil
		end)
		if elementData then
			self:SelectSquelched(elementData.squelchType, elementData.index)
			hasSelection = true
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
		local button = BetterFriendsFrame.IgnoreListWindow.ScrollBox:FindFrameByPredicate(function(button, elementData)
			return elementData.squelchType == type and elementData.index == index
		end)
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
