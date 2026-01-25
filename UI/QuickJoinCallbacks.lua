--[[
	QuickJoinCallbacks.lua
	
	UI Glue Layer for Quick Join Frame
	XML Callbacks and thin wrappers for QuickJoin module
	
	This file contains ONLY the UI callback functions that are called from XML.
	All business logic is in Modules/QuickJoin.lua
]]

local addonName, BFL = ...
local L = BFL.L

-- Import UI constants
local UI = BFL.UI.CONSTANTS

-- ========================================
-- QUICK JOIN FRAME CALLBACKS
-- ========================================

function BetterQuickJoinFrame_OnLoad(self)
	-- Classic Guard: QuickJoin/Social Queue is Retail-only
	if BFL.IsClassic or not BFL.HasQuickJoin then
		-- BFL:DebugPrint("|cffffcc00QuickJoinCallbacks:|r Not available in Classic - frame hidden")
		self:Hide()
		return
	end
	
	-- Fix: Elements are nested inside ContentInset
	local contentInset = self.ContentInset
	if not contentInset then
		return
	end
	
	local scrollBox = contentInset.ScrollBoxContainer and contentInset.ScrollBoxContainer.ScrollBox
	local scrollBar = contentInset.ScrollBar
	
	-- Initialize Join button
	if contentInset.JoinQueueButton then
		contentInset.JoinQueueButton:SetText(JOIN_QUEUE)
		contentInset.JoinQueueButton:Disable()
	end
	
	-- Classic mode: Skip ScrollBox initialization (handled by QuickJoin module)
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- BFL:DebugPrint("|cff00ffffQuickJoinCallbacks:|r Classic mode - skipping ScrollBox init")
		self.QuickJoin = BFL and BFL:GetModule("QuickJoin")
		self.selectedGUID = nil
		return
	end
	
	-- Retail: Initialize ScrollBox
	if scrollBox and scrollBar then
		-- Create view with Blizzard-style dynamic text creation
		local view = CreateScrollBoxListLinearView()
		
		-- Element initializer - button setup
		view:SetElementInitializer("BetterQuickJoinGroupButtonTemplate", function(button, elementData)
			-- elementData is a QuickJoinEntry from QuickJoin module
			-- It has ApplyToFrame() method that dynamically creates FontStrings
			
			-- Store font object for dynamic text creation
			button.fontObject = BetterFriendlistFontNormalSmall
			
			-- Apply entry data to button (creates FontStrings dynamically)
			elementData:ApplyToFrame(button)
			
			-- Store entry reference
			button.entry = elementData
			button.guid = elementData.guid
			
			-- Register button for selection tracking
			local QuickJoin = BFL and BFL:GetModule("QuickJoin")
			if QuickJoin then
				QuickJoin.selectedButtons[elementData.guid] = button
			end
			
			-- Set selection state
			local selected = QuickJoin and elementData.guid == QuickJoin.selectedGUID
			if button.Selected then
				button.Selected:SetShown(selected)
			end
			if button.Highlight then
				button.Highlight:SetAlpha(selected and 0 or UI.ALPHA_DIMMED)
			end
		end)
		
		-- Dynamic height calculator (matches Blizzard's approach)
		view:SetElementExtentCalculator(function(dataIndex, elementData)
			return elementData:CalculateHeight()
		end)
		
		-- Initialize ScrollBox with view
		ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
		
		-- Add scroll bar visibility behavior
		local scrollBoxAnchorsWithBar = {
			CreateAnchor("TOPLEFT", 4, -4),
			CreateAnchor("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", 0, 4),
		}
		local scrollBoxAnchorsWithoutBar = {
			CreateAnchor("TOPLEFT", 4, -4),
			CreateAnchor("BOTTOMRIGHT", -4, 4),
		}
		ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)
		
		-- Store reference for easy access
		self.ScrollBox = scrollBox
	end
	
	-- Store reference to QuickJoin module
	self.QuickJoin = BFL and BFL:GetModule("QuickJoin")
	self.selectedGUID = nil
end

function BetterQuickJoinFrame_OnShow(self)
	-- Get QuickJoin module directly from BFL (more reliable)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if QuickJoin then
		-- Register update callback
		QuickJoin:SetUpdateCallback(function()
			BetterQuickJoinFrame_Update(self)
		 end)
		
		QuickJoin:Update(true)  -- Force immediate update
	end
	
	-- Initial UI update
	BetterQuickJoinFrame_Update(self)
end

function BetterQuickJoinFrame_OnHide(self)
	-- Cleanup
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if QuickJoin then
		QuickJoin:SetUpdateCallback(nil)
	end
end

function BetterQuickJoinFrame_Update(self)
	if not self or not self.ScrollBox then 
		return 
	end
	
	-- Get QuickJoin module directly from BFL (more reliable than storing reference)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if not QuickJoin then 
		return 
	end
	
	-- Get QuickJoin entries (these are QuickJoinEntry objects with ApplyToFrame and CalculateHeight methods)
	local entries = QuickJoin:GetEntries()
	
	-- Show/hide "no groups" text (Edge Case: No groups available)
	if self.ContentInset and self.ContentInset.NoGroupsText then
		-- Set localized text using WoW global variable
		self.ContentInset.NoGroupsText:SetText(L.QUICK_JOIN_NO_GROUPS or QUICK_JOIN_NO_GROUPS or "No groups available")
		self.ContentInset.NoGroupsText:SetShown(not entries or #entries == 0)
	end
	
	-- Update ScrollBox - always create a data provider, even if empty
	local dataProvider = CreateDataProvider(entries or {})
	self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	
	-- Update Join button state (handles "already in group" and "combat" edge cases)
	QuickJoin:UpdateJoinButtonState()
end

-- ========================================
-- Quick Join Button Functions (Blizzard-style callbacks)
-- ========================================

function BetterQuickJoinGroupButton_OnEnter(self)
	if not self.entry then return end
	
	-- Update entry's groupInfo reference to get latest data (for dynamic updates like member count changes)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if QuickJoin then
		local latestGroupInfo = QuickJoin:GetGroupInfo(self.guid)
		if latestGroupInfo then
			self.entry.groupInfo = latestGroupInfo
		end
	end
	
	-- Show tooltip using entry's ApplyToTooltip method
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	self.entry:ApplyToTooltip(GameTooltip)
	GameTooltip:Show()
	
	-- Hide selection highlight and show hover highlight (blue)
	if self.Selected then
		self.Selected:Hide()
	end
	if self.HoverHighlight then
		self.HoverHighlight:Show()
	end
end

function BetterQuickJoinGroupButton_OnLeave(self)
	GameTooltip:Hide()
	
	-- Hide hover highlight and restore selection if needed
	if self.HoverHighlight then
		self.HoverHighlight:Hide()
	end
	
	-- Restore selection highlight if this button is selected
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if QuickJoin and self.guid == QuickJoin.selectedGUID and self.Selected then
		self.Selected:Show()
	end
end

function BetterQuickJoinGroupButton_OnClick(self, button)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if not QuickJoin then return end
	
	-- Edge Case: Don't allow selection/interaction during combat
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0)
		return
	end
	
	if button == "LeftButton" then
		if self.entry and self.entry:CanJoin() then
			-- Select this group
			QuickJoin:SelectGroup(self.guid)
		end
	elseif button == "RightButton" then
		-- Show context menu
		QuickJoin:OpenContextMenu(self.guid, self)
	end
end

-- Join Queue Button Handler
function BetterQuickJoinFrame_JoinQueueButton_OnClick(self)
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if QuickJoin then
		QuickJoin:JoinQueue()
	end
end

-- ========================================
-- DEPRECATED: Custom Role Selection Frame
-- As of v2.0.0, we use Blizzard's native QuickJoinRoleSelectionFrame instead
-- This code is kept for reference but is no longer used
-- ========================================

--[[ DEPRECATED - Now using Blizzard's QuickJoinRoleSelectionFrame
BetterQuickJoinRoleSelectionFrame = BetterQuickJoinRoleSelectionFrame or CreateFrame("Frame", "BetterQuickJoinRoleSelectionFrame", UIParent, "BasicFrameTemplate")

function BetterQuickJoinRoleSelectionFrame:ShowForGroup(guid)
	if not guid then return end
	
	self.guid = guid
	
	-- Position frame
	self:SetPoint("CENTER", UIParent, "CENTER")
	self:SetSize(300, 200)
	
	-- Set title
	self.TitleText:SetText("Select Roles")
	
	-- Create checkboxes if not exist
	if not self.TankCheck then
		self.TankCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
		self.TankCheck:SetPoint("TOPLEFT", UI.SPACING_XLARGE, UI.BUTTON_OFFSET_Y)
		self.TankCheck.Text:SetText("Tank")
		
		self.HealerCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
		self.HealerCheck:SetPoint("TOPLEFT", UI.SPACING_XLARGE, -70)
		self.HealerCheck.Text:SetText("Healer")
		
		self.DamageCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
		self.DamageCheck:SetPoint("TOPLEFT", UI.SPACING_XLARGE, -100)
		self.DamageCheck.Text:SetText("Damage")
		
		-- Join button
		self.JoinButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
		self.JoinButton:SetSize(100, 25)
		self.JoinButton:SetPoint("BOTTOM", 0, UI.SPACING_XLARGE)
		self.JoinButton:SetText("Join")
		self.JoinButton:SetScript("OnClick", function()
			BetterQuickJoinGroupButton_OnJoinClick(self)
		end)
	end
	
	-- Default to all roles checked
	self.TankCheck:SetChecked(true)
	self.HealerCheck:SetChecked(true)
	self.DamageCheck:SetChecked(true)
	
	self:Show()
end

function BetterQuickJoinGroupButton_OnJoinClick(button)
	local frame = BetterQuickJoinRoleSelectionFrame
	if not frame or not frame.guid then return end
	
	local QuickJoin = BFL and BFL:GetModule("QuickJoin")
	if not QuickJoin then return end
	
	-- Get selected roles
	local tank = frame.TankCheck:GetChecked()
	local healer = frame.HealerCheck:GetChecked()
	local damage = frame.DamageCheck:GetChecked()
	
	-- Request to join
	QuickJoin:RequestToJoin(frame.guid, tank, healer, damage)
	
	-- Close dialog
	frame:Hide()
end
--]] -- End of DEPRECATED code
