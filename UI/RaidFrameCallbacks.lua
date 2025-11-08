--[[
	RaidFrameCallbacks.lua
	
	UI Glue Layer for Raid Frame
	XML Callbacks and thin wrappers for RaidFrame module
	
	This file contains ONLY the UI callback functions that are called from XML.
	All business logic is in Modules/RaidFrame.lua
]]

local addonName, BFL = ...

-- Helper: Get RaidFrame module
local function GetRaidFrame()
	return BFL:GetModule("RaidFrame")
end

-- ========================================
-- RAID FRAME CALLBACKS
-- ========================================

-- OnShow: Initialize Raid Frame and update roster
function BetterRaidFrame_OnShow(self)
	local RaidFrame = GetRaidFrame()
	if not RaidFrame then return end
	
	-- Request raid info (for saved instances)
	RequestRaidInfo()
	
	-- Update raid roster
	RaidFrame:UpdateRaidMembers()
	RaidFrame:BuildDisplayList()
	
	-- Update member buttons (using XML-defined slots)
	RaidFrame:UpdateAllMemberButtons()
	
	-- Render display
	BetterRaidFrame_Update()
	
	-- Update Raid Info button state
	BetterRaidFrame_UpdateRaidInfoButton()
end

-- OnHide: Cleanup
function BetterRaidFrame_OnHide(self)
	-- Cleanup if needed (currently nothing to do)
end

-- Update: Render raid member list and control panel
function BetterRaidFrame_Update()
	local RaidFrame = GetRaidFrame()
	if not RaidFrame then return end
	
	local frame = BetterFriendsFrame.RaidFrame
	if not frame or not frame:IsShown() then return end
	
	local controlPanel = frame.ControlPanel
	local raidMembers = RaidFrame.raidMembers or {}
	local numMembers = #raidMembers
	
	-- Update member count text
	if controlPanel and controlPanel.MemberCountText then
		controlPanel.MemberCountText:SetText(string.format("%d/40", numMembers))
	end
	
	-- Show/hide "Not in Raid" text
	if frame.NotInRaid then
		frame.NotInRaid:SetShown(not IsInRaid())
	end
	
	-- Update control panel buttons
	BetterRaidFrame_UpdateControlPanelButtons()
	
	-- Update member buttons via module
	RaidFrame:UpdateAllMemberButtons()
end

-- Update Control Panel Buttons (Enable/Disable based on state)
function BetterRaidFrame_UpdateControlPanelButtons()
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame or not frame.ControlPanel then return end
	
	local controlPanel = frame.ControlPanel
	local isLeader = UnitIsGroupLeader("player")
	local isAssistant = UnitIsGroupAssistant("player")
	local canControl = isLeader or isAssistant
	
	-- Ready Check: Only Leader or Assistant
	if controlPanel.ReadyCheckButton then
		if canControl then
			controlPanel.ReadyCheckButton:Enable()
		else
			controlPanel.ReadyCheckButton:Disable()
		end
	end
	
	-- Convert to Raid: Only if in Party (not Raid) and is Leader
	if controlPanel.ConvertToRaidButton then
		if not IsInRaid() and IsInGroup() and isLeader then
			controlPanel.ConvertToRaidButton:Enable()
		else
			controlPanel.ConvertToRaidButton:Disable()
		end
	end
end

-- Update Combat Overlay (shows during combat to prevent taint)
function BetterRaidFrame_UpdateCombatOverlay(inCombat)
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame or not frame.CombatOverlay then return end
	
	frame.CombatOverlay:SetShown(inCombat)
	
	-- Update text
	if inCombat then
		frame.CombatOverlay.Text:SetText("Raid management disabled during combat")
	end
end

-- ========================================
-- CONTROL PANEL BUTTONS
-- ========================================

-- Ready Check Button
function BetterRaidFrame_DoReadyCheck()
	if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
		DoReadyCheck()
	else
		UIErrorsFrame:AddMessage("You must be the raid leader or assistant to initiate a ready check.", 1.0, 0.1, 0.1, 1.0)
	end
end

-- Everyone Assist Checkbox
function BetterRaidFrame_EveryoneAssistCheckbox_OnLoad(self)
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	
	-- Initialize state
	BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(self)
end

function BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(self)
	if IsInRaid() and UnitIsGroupLeader("player") then
		self:Enable()
		self:SetChecked(IsEveryoneAssistant())
	else
		self:Disable()
		self:SetChecked(false)
	end
end

function BetterRaidFrame_EveryoneAssistCheckbox_OnClick(self)
	if UnitIsGroupLeader("player") then
		local checked = self:GetChecked()
		SetEveryoneIsAssistant(checked)
	end
end

-- Raid Info Button
function BetterRaidFrame_RaidInfoButton_OnClick(self)
	-- Get number of saved instances to check if we have any
	local numSaved = GetNumSavedInstances()
	
	if numSaved == 0 then
		-- No saved instances, show message
		UIErrorsFrame:AddMessage("You have no saved raid instances.", 1.0, 1.0, 1.0, 1.0)
		return
	end
	
	-- Load Blizzard's Raid UI (contains RaidInfoFrame)
	if not IsAddOnLoaded("Blizzard_RaidUI") then
		LoadAddOn("Blizzard_RaidUI")
	end
	
	-- Check if RaidInfoFrame exists
	if not RaidInfoFrame then
		UIErrorsFrame:AddMessage("Error: Could not load Raid Info frame.", 1.0, 0.1, 0.1, 1.0)
		return
	end
	
	-- If RaidInfoFrame is already shown in BetterFriendsFrame, close it
	if RaidInfoFrame:IsShown() and RaidInfoFrame:GetParent() == BetterFriendsFrame then
		-- Close and restore to default parent
		RaidInfoFrame:Hide()
		RaidInfoFrame:SetParent(UIParent)
		RaidInfoFrame:ClearAllPoints()
		RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", 0, -20)
		return
	end
	
	-- Otherwise, hijack RaidInfoFrame and show it
	-- Save original parent and points
	if not RaidInfoFrame._originalParent then
		RaidInfoFrame._originalParent = RaidInfoFrame:GetParent()
	end
	
	-- Reparent to BetterFriendsFrame
	RaidInfoFrame:SetParent(BetterFriendsFrame)
	RaidInfoFrame:ClearAllPoints()
	
	-- Position next to BetterFriendsFrame (top-aligned)
	if BetterFriendsFrame:IsShown() then
		RaidInfoFrame:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", 0, 0)
	else
		-- Fallback if BetterFriendsFrame is hidden
		RaidInfoFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
	end
	
	-- Hook the close button to restore original parent
	if RaidInfoFrame.CloseButton and not RaidInfoFrame.CloseButton._hooked then
		RaidInfoFrame.CloseButton:HookScript("OnClick", function(self)
			-- Restore original parent
			if RaidInfoFrame._originalParent then
				RaidInfoFrame:SetParent(RaidInfoFrame._originalParent)
				RaidInfoFrame:ClearAllPoints()
				RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", 0, -20)
			end
		end)
		RaidInfoFrame.CloseButton._hooked = true
	end
	
	-- Show the frame
	RaidInfoFrame:Show()
end

-- Update Raid Info Button (Enable/Disable based on saved instances)
function BetterRaidFrame_UpdateRaidInfoButton()
	local raidFrame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not raidFrame then return end
	
	local button = raidFrame.ControlPanel and raidFrame.ControlPanel.RaidInfoButton
	if not button then return end
	
	-- Check for saved instances
	local numSaved = GetNumSavedInstances()
	
	if numSaved > 0 then
		button:Enable()
	else
		button:Disable()
	end
end

-- ========================================
-- RAID MEMBER BUTTON CALLBACKS
-- ========================================

function BetterRaidMemberButton_OnLoad(self)
	-- Register for updates
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterForDrag("LeftButton")
end

function BetterRaidMemberButton_OnEnter(self)
	if not self.unit then return end
	
	-- Show tooltip
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetUnit(self.unit)
	GameTooltip:Show()
	
	-- Highlight
	if self.Highlight then
		self.Highlight:Show()
	end
end

function BetterRaidMemberButton_OnLeave(self)
	GameTooltip:Hide()
	
	if self.Highlight then
		self.Highlight:Hide()
	end
end

function BetterRaidMemberButton_OnClick(self, button)
	if not self.unit or not self.name then return end
	
	if button == "LeftButton" then
		-- Target unit
		if UnitExists(self.unit) then
			TargetUnit(self.unit)
		end
	elseif button == "RightButton" then
		-- Show context menu
		local contextData = {
			name = self.name,
			unit = self.unit,
			guid = UnitGUID(self.unit)
		}
		UnitPopup_OpenMenu("RAID_PLAYER", contextData, self)
	end
end

function BetterRaidMemberButton_OnDragStart(self)
	if not self.unit or not self.name then return end
	
	-- Start drag (for moving to different groups)
	-- Store dragged unit info
	BetterRaidFrame_DraggedUnit = {
		unit = self.unit,
		name = self.name,
		slot = self.raidSlot
	}
	
	-- Set cursor
	SetCursor("Interface\\CURSOR\\UI-Cursor-Move")
end

function BetterRaidMemberButton_OnDragStop(self)
	if not BetterRaidFrame_DraggedUnit then return end
	
	-- Get target group from mouse position
	-- For now, just clear the drag state
	-- Full implementation would detect drop target and call SetRaidSubgroup()
	
	BetterRaidFrame_DraggedUnit = nil
	ResetCursor()
end
