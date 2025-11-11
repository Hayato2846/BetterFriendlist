--[[
	RaidFrameCallbacks.lua
	
	UI Glue Layer for Raid Frame
	XML Callbacks and thin wrappers for RaidFrame module
	
	This file contains ONLY the UI callback functions that are called from XML.
	All business logic is in Modules/RaidFrame.lua
]]

local addonName, BFL = ...

-- Import UI constants
local UI = BFL.UI.CONSTANTS

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
	
	local isInRaid = IsInRaid()
	local controlPanel = frame.ControlPanel
	
	-- Show/hide UI elements based on group type (Raid vs Party)
	if controlPanel then
		-- Hide raid-specific controls when not in raid
		if controlPanel.EveryoneAssistCheckbox then
			controlPanel.EveryoneAssistCheckbox:SetShown(isInRaid)
		end
		if controlPanel.EveryoneAssistLabel then
			controlPanel.EveryoneAssistLabel:SetShown(isInRaid)
		end
		if controlPanel.MemberCount then
			controlPanel.MemberCount:SetShown(isInRaid)
		end
		if controlPanel.CombatIcon then
			controlPanel.CombatIcon:SetShown(isInRaid and InCombatLockdown())
		end
		if controlPanel.RoleSummary then
			controlPanel.RoleSummary:SetShown(isInRaid)
		end
		-- Raid Info Button always visible
	end
	
	-- Show/hide member buttons and groups container
	if frame.GroupsInset and frame.GroupsInset.GroupsContainer then
		frame.GroupsInset.GroupsContainer:SetShown(isInRaid)
	end
	
	-- Show/hide "Not in Raid" placeholder text
	if frame.NotInRaid then
		frame.NotInRaid:SetShown(not isInRaid)
	end
	
	-- Only update member buttons if in raid
	if isInRaid then
		-- Update control panel buttons
		BetterRaidFrame_UpdateControlPanelButtons()
		
		-- Update member buttons via module
		RaidFrame:UpdateAllMemberButtons()
	end
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
	if not frame then return end
	
	-- Only show combat overlay when in raid
	local isInRaid = IsInRaid()
	
	BFL:DebugPrint("[BFL] UpdateCombatOverlay called: inCombat=" .. tostring(inCombat) .. ", isInRaid=" .. tostring(isInRaid))
	
	-- Update Combat Icon (shows between MemberCount and RaidInfo button)
	-- Only show if in raid AND in combat
	if frame.ControlPanel and frame.ControlPanel.CombatIcon then
		frame.ControlPanel.CombatIcon:SetShown(isInRaid and inCombat)
		BFL:DebugPrint("[BFL] Combat icon " .. (isInRaid and inCombat and "shown" or "hidden"))
	end
	
    -- Update member button overlays via RaidFrame module
    -- Only update if in raid
    if isInRaid then
        local raidFrameModule = BFL.Modules and BFL.Modules.RaidFrame
        if raidFrameModule then
            raidFrameModule:UpdateCombatOverlay(inCombat)  -- Pass the parameter!
            BFL:DebugPrint("[BFL] Member button overlays updated")
        end
    end
end-- ========================================
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
	
	-- Label will be set by RaidFrame:Initialize() after frame is ready
	-- Don't try to set it here - BetterFriendsFrame.RaidFrame doesn't exist yet
	
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
	if not C_AddOns.IsAddOnLoaded("Blizzard_RaidUI") then
		C_AddOns.LoadAddOn("Blizzard_RaidUI")
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
		RaidInfoFrame:SetPoint("CENTER", UIParent, "CENTER", UI.CENTER_OFFSET, 0)
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
	if not self.unit then
		return
	end
	
	-- Use Blizzard's standard UnitFrame tooltip (same as default raid frames)
	UnitFrame_UpdateTooltip(self)
	
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
	if not self.unit or not self.name then
		return
	end
	
	if button == "RightButton" then
		-- Right-click: Show standard raid context menu
		local contextData = {
			unit = self.unit,
			name = self.name,
		}
		UnitPopup_OpenMenu("RAID", contextData)
	end
	-- Note: Left-click is handled by OnDragStart for drag and drop (only when not in combat)
	-- We do NOT target the unit on left-click to avoid taint issues
end

function BetterRaidMemberButton_OnDragStart(self)
	if not self.unit or not self.name then
		return
	end
	
	-- Check if player is raid leader or assistant
	local isLeader = UnitIsGroupLeader("player")
	local isAssistant = UnitIsGroupAssistant("player")
	
	if not isLeader and not isAssistant then
		return
	end
	
	-- Start drag (for moving to different groups)
	-- Store dragged unit info
	BetterRaidFrame_DraggedUnit = {
		unit = self.unit,
		name = self.name,
		groupIndex = self.groupIndex
	}
end

function BetterRaidMemberButton_OnDragStop(self)
	if not BetterRaidFrame_DraggedUnit then
		return
	end
	
	-- Check if dropped on a valid target (raid member button - can be empty or occupied)
	-- GetMouseFoci() returns array in WoW 11.2+, GetMouseFocus() was deprecated
	local mouseFoci = GetMouseFoci and GetMouseFoci() or {}
	local targetFrame = nil
	
	-- Search through all frames under mouse to find a raid member button
	for _, frame in ipairs(mouseFoci) do
		if frame and frame.groupIndex and frame.slotIndex then
			targetFrame = frame
			break
		end
	end
	
	-- Fallback for older WoW versions
	if not targetFrame and GetMouseFocus then
		local frame = GetMouseFocus()
		if frame and frame.groupIndex and frame.slotIndex then
			targetFrame = frame
		end
	end
	
	if not targetFrame or not targetFrame.groupIndex then
		BetterRaidFrame_DraggedUnit = nil
		return
	end
	
	-- Don't allow dropping on self
	if targetFrame.unit == BetterRaidFrame_DraggedUnit.unit then
		BetterRaidFrame_DraggedUnit = nil
		return
	end
	
	-- Get source and target subgroups from groupIndex (always set on buttons)
	local sourceSubgroup = BetterRaidFrame_DraggedUnit.groupIndex
	local targetSubgroup = targetFrame.groupIndex
	
	-- Only move if different subgroup
	if targetSubgroup ~= sourceSubgroup then
		-- Calculate raidIndex from unit (raid1 = 1, raid2 = 2, etc.)
		local raidIndex = tonumber(string.match(BetterRaidFrame_DraggedUnit.unit, "raid(%d+)"))
		if not raidIndex then
			BetterRaidFrame_DraggedUnit = nil
			return
		end
		
		-- SetRaidSubgroup(raidIndex, subgroup) - moves raid member to different subgroup
		SetRaidSubgroup(raidIndex, targetSubgroup)
	end
	
	-- Clear drag state
	BetterRaidFrame_DraggedUnit = nil
end
