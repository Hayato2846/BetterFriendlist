--[[
	RaidFrameCallbacks.lua
	
	UI Glue Layer for Raid Frame
	XML Callbacks and thin wrappers for RaidFrame module
	
	This file contains ONLY the UI callback functions that are called from XML.
	All business logic is in Modules/RaidFrame.lua
]]

local addonName, BFL = ...

-- Import localized strings
local L = BFL.L

-- Import UI constants
local UI = BFL.UI.CONSTANTS

-- ========================================
-- STORY MODE DETECTION (Fix #43)
-- ========================================
-- Uses Blizzard's official DifficultyUtil.InStoryRaid() API
-- See Interface/AddOns/Blizzard_FrameXMLUtil/DifficultyUtil.lua
-- DifficultyUtil.ID.RaidStory = 220 is the official Story Raid difficulty ID

-- Check if player is in a Story Mode instance (not a real raid)
-- This is a fallback check for RaidFrame content display
-- Primary check is in BetterFriendlist.lua where the tab is disabled
local function IsInStoryModeRaid()
	-- Guard for Classic (no DifficultyUtil) and missing API
	if BFL.IsClassic then
		return false
	end
	if DifficultyUtil and DifficultyUtil.InStoryRaid then
		return DifficultyUtil.InStoryRaid()
	end
	-- Fallback: Manual check for Story Raid difficulty ID (220)
	local _, _, difficultyID = GetInstanceInfo()
	return difficultyID == 220
end

-- ========================================
-- MULTI-SELECT STATE (Phase 8.2)
-- ========================================

-- Global state for multi-selection
BetterRaidFrame_SelectedPlayers = {}

-- Helper: Get RaidFrame module
local function GetRaidFrame()
	return BFL:GetModule("RaidFrame")
end

-- ========================================
-- MULTI-SELECT HELPER FUNCTIONS (Phase 8.2)
-- ========================================

local function IsPlayerSelected(raidIndex)
	for i, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
		if playerData.raidIndex == raidIndex then
			return true, i
		end
	end
	return false
end

local function ClearAllSelections()
	local RaidFrame = GetRaidFrame()
	if not RaidFrame then
		return
	end

	-- Clear visual highlights
	for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
		RaidFrame:SetButtonSelectionHighlight(playerData.raidIndex, false)
	end

	-- Clear state
	BetterRaidFrame_SelectedPlayers = {}
end

local function TogglePlayerSelection(button)
	if not button.unit or not button.name or not button.groupIndex then
		return
	end

	local raidIndex = tonumber(string.match(button.unit, "raid(%d+)"))
	if not raidIndex then
		return
	end

	local RaidFrame = GetRaidFrame()
	if not RaidFrame then
		return
	end

	local isSelected, index = IsPlayerSelected(raidIndex)

	if isSelected then
		-- Remove from selection
		table.remove(BetterRaidFrame_SelectedPlayers, index)
		RaidFrame:SetButtonSelectionHighlight(raidIndex, false)
	else
		-- Add to selection
		table.insert(BetterRaidFrame_SelectedPlayers, {
			raidIndex = raidIndex,
			groupIndex = button.groupIndex,
			unit = button.unit,
			name = button.name,
		})
		RaidFrame:SetButtonSelectionHighlight(raidIndex, true)
	end
end

local function CountPlayersInGroup(targetSubgroup)
	local count = 0
	for i = 1, GetNumGroupMembers() do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if subgroup == targetSubgroup then
			count = count + 1
		end
	end
	return count
end

local function BulkMoveToGroup(targetSubgroup)
	local selectedCount = #BetterRaidFrame_SelectedPlayers
	if selectedCount == 0 then
		return
	end

	-- Count free slots in target group
	local targetGroupSize = CountPlayersInGroup(targetSubgroup)
	local freeSlots = 5 - targetGroupSize

	-- Validation: Enough space?
	if selectedCount > freeSlots then
		UIErrorsFrame:AddMessage(
			string.format(L.RAID_ERROR_NOT_ENOUGH_SPACE, selectedCount, freeSlots, targetSubgroup),
			1.0,
			0.1,
			0.1,
			1.0
		)
		return false
	end

	-- Check if all players already in target group (no-op)
	local allInTargetGroup = true
	for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
		if playerData.groupIndex ~= targetSubgroup then
			allInTargetGroup = false
			break
		end
	end

	if allInTargetGroup then
		-- Silent no-op, clear selections
		ClearAllSelections()
		return true
	end

	-- Execute bulk move
	local movedCount = 0
	local failedCount = 0

	for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
		local success = pcall(SetRaidSubgroup, playerData.raidIndex, targetSubgroup)
		if success then
			movedCount = movedCount + 1
		else
			failedCount = failedCount + 1
		end
	end

	-- Success feedback
	if movedCount > 0 then
		UIErrorsFrame:AddMessage(
			string.format(L.RAID_MSG_BULK_MOVE_SUCCESS, movedCount, targetSubgroup),
			0.0,
			1.0,
			0.0,
			1.0
		)
		-- Note: Update handled by GROUP_ROSTER_UPDATE event with throttling
	end

	-- Error feedback if any failed
	if failedCount > 0 then
		UIErrorsFrame:AddMessage(string.format(L.RAID_ERROR_BULK_MOVE_FAILED, failedCount), 1.0, 0.1, 0.1, 1.0)
	end

	return movedCount > 0
end

-- ========================================
-- RAID FRAME CALLBACKS
-- ========================================

-- OnShow: Initialize Raid Frame and update roster
function BetterRaidFrame_OnShow(self)
	local RaidFrame = GetRaidFrame()
	if not RaidFrame then
		return
	end

	-- Clear multi-selections on show (Phase 8.2)
	ClearAllSelections()

	-- Request raid info (for saved instances)
	RequestRaidInfo()

	-- Update raid roster
	RaidFrame:UpdateRaidMembers()
	RaidFrame:BuildDisplayList()

	-- Update member buttons (using XML-defined slots)
	RaidFrame:UpdateAllMemberButtons()

	-- Ensure layout matches Mock (responsive sizing)
	RaidFrame:UpdateGroupLayout()

	-- Update Raid Info button state
	BetterRaidFrame_UpdateRaidInfoButton()

	-- Central Update Logic
	BetterRaidFrame_Update()
end

-- OnHide: Cleanup
function BetterRaidFrame_OnHide(self)
	-- Clear multi-selections on hide (Phase 8.2)
	ClearAllSelections()
end

-- Update: Render raid member list and control panel
function BetterRaidFrame_Update()
	local RaidFrame = GetRaidFrame()
	if not RaidFrame then
		return
	end

	local frame = BetterFriendsFrame.RaidFrame
	if not frame or not frame:IsShown() then
		return
	end

	-- Fix #43: Exclude Story Mode raids (player is technically "in raid" but solo)
	-- Fix: Also exclude "solo raids" (IsInRaid but only 1 member) - e.g. after leaving Story Mode
	local numMembers = GetNumGroupMembers()
	local isSoloRaid = IsInRaid() and numMembers <= 1
	local isInRaid = IsInRaid() and not IsInStoryModeRaid() and not isSoloRaid
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

	-- Always update control panel layout (adjusts for frame width changes)
	RaidFrame:UpdateControlPanelLayout()
end

-- Update Control Panel Buttons (Enable/Disable based on state)
function BetterRaidFrame_UpdateControlPanelButtons()
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame or not frame.ControlPanel then
		return
	end

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
	if not frame then
		return
	end

	-- Fix #43: Only show combat overlay when in real raid (not Story Mode)
	-- Fix: Also exclude "solo raids" (IsInRaid but only 1 member)
	local numMembers = GetNumGroupMembers()
	local isSoloRaid = IsInRaid() and numMembers <= 1
	local isInRaid = IsInRaid() and not IsInStoryModeRaid() and not isSoloRaid

	-- BFL:DebugPrint("[BFL] UpdateCombatOverlay called: inCombat=" .. tostring(inCombat) .. ", isInRaid=" .. tostring(isInRaid))

	-- Update Combat Icon (shows between MemberCount and RaidInfo button)
	-- Only show if in raid AND in combat
	if frame.ControlPanel and frame.ControlPanel.CombatIcon then
		frame.ControlPanel.CombatIcon:SetShown(isInRaid and inCombat)
		-- BFL:DebugPrint("[BFL] Combat icon " .. (isInRaid and inCombat and "shown" or "hidden"))
	end

	-- Update member button overlays via RaidFrame module
	-- Only update if in raid
	if isInRaid then
		local raidFrameModule = BFL.Modules and BFL.Modules.RaidFrame
		if raidFrameModule then
			raidFrameModule:UpdateCombatOverlay(inCombat) -- Pass the parameter!
			-- BFL:DebugPrint("[BFL] Member button overlays updated")
		end
	end
end -- ========================================
-- CONTROL PANEL BUTTONS
-- ========================================

-- Ready Check Button
function BetterRaidFrame_DoReadyCheck()
	if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
		DoReadyCheck()
	else
		UIErrorsFrame:AddMessage(L.RAID_ERROR_READY_CHECK_PERMISSION, 1.0, 0.1, 0.1, 1.0)
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
	-- Guard: Skip update briefly after user click to prevent race condition
	-- (GROUP_ROSTER_UPDATE may fire before server confirms the new state)
	if self.clickCooldown and GetTime() - self.clickCooldown < 0.5 then
		return
	end

	local label = self:GetParent() and self:GetParent().EveryoneAssistLabel

	if IsInRaid() and UnitIsGroupLeader("player") then
		self:Enable()
		self:SetChecked(IsEveryoneAssistant())
		if label then
			label:SetFontObject("BetterFriendlistFontNormal")
		end
	else
		self:Disable()
		self:SetChecked(false)
		if label then
			label:SetFontObject("BetterFriendlistFontDisable")
		end
	end
end

function BetterRaidFrame_EveryoneAssistCheckbox_OnClick(self)
	if UnitIsGroupLeader("player") then
		local checked = self:GetChecked()
		-- Set cooldown to prevent OnEvent from resetting state before server confirms
		self.clickCooldown = GetTime()
		SetEveryoneIsAssistant(checked)
	end
end

local function RestoreRaidInfoFrameLayering()
	if not RaidInfoFrame then
		return
	end

	local targetParent = RaidInfoFrame._originalParent or UIParent

	if RaidInfoFrame._originalFrameStrata then
		RaidInfoFrame:SetFrameStrata(RaidInfoFrame._originalFrameStrata)
	elseif targetParent and targetParent.GetFrameStrata then
		RaidInfoFrame:SetFrameStrata(targetParent:GetFrameStrata())
	end

	if RaidInfoFrame._originalFrameLevel then
		RaidInfoFrame:SetFrameLevel(RaidInfoFrame._originalFrameLevel)
	elseif targetParent and targetParent.GetFrameLevel then
		RaidInfoFrame:SetFrameLevel((targetParent:GetFrameLevel() or 0) + 1)
	end
end

local function GetHigherFrameStrata(baseStrata)
	local strataOrder = {
		"BACKGROUND",
		"LOW",
		"MEDIUM",
		"HIGH",
		"DIALOG",
		"FULLSCREEN",
		"FULLSCREEN_DIALOG",
		"TOOLTIP",
	}

	for i, strataName in ipairs(strataOrder) do
		if strataName == baseStrata then
			return strataOrder[math.min(i + 1, #strataOrder)]
		end
	end

	-- Fallback for unknown/empty strata values.
	return "DIALOG"
end

local function ApplyDockedRaidInfoFrameLayering()
	if not RaidInfoFrame or not BetterFriendsFrame then
		return
	end

	-- Keep RaidInfoFrame above the entire BetterFriendsFrame hierarchy so movable
	-- RaidInfo windows from other addons never end up under BFL borders.
	local higherStrata = GetHigherFrameStrata(BetterFriendsFrame:GetFrameStrata())
	RaidInfoFrame:SetFrameStrata(higherStrata)
	RaidInfoFrame:SetFrameLevel((BetterFriendsFrame:GetFrameLevel() or 0) + 100)
	RaidInfoFrame:Raise()
end

-- Raid Info Button
function BetterRaidFrame_RaidInfoButton_OnClick(self)
	-- Get number of saved instances to check if we have any
	local numSaved = GetNumSavedInstances()

	if numSaved == 0 then
		-- No saved instances, show message
		UIErrorsFrame:AddMessage(L.RAID_ERROR_NO_SAVED_INSTANCES, 1.0, 1.0, 1.0, 1.0)
		return
	end

	-- Check if RaidInfoFrame exists (provided by Blizzard_RaidUI, loaded automatically)
	if not RaidInfoFrame then
		UIErrorsFrame:AddMessage(L.RAID_ERROR_LOAD_RAID_INFO, 1.0, 0.1, 0.1, 1.0)
		return
	end

	-- If RaidInfoFrame is already shown in BetterFriendsFrame, close it
	if RaidInfoFrame:IsShown() and RaidInfoFrame:GetParent() == BetterFriendsFrame then
		-- Close and restore to default parent
		RaidInfoFrame:Hide()
		RaidInfoFrame:SetParent(RaidInfoFrame._originalParent or UIParent)
		RestoreRaidInfoFrameLayering()
		RaidInfoFrame:ClearAllPoints()
		if RaidFrame then
			RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", 0, -20)
		end
		return
	end

	-- Otherwise, hijack RaidInfoFrame and show it
	-- Save original parent and points
	if not RaidInfoFrame._originalParent then
		RaidInfoFrame._originalParent = RaidInfoFrame:GetParent()
	end
	if not RaidInfoFrame._originalFrameStrata then
		RaidInfoFrame._originalFrameStrata = RaidInfoFrame:GetFrameStrata()
	end
	if not RaidInfoFrame._originalFrameLevel then
		RaidInfoFrame._originalFrameLevel = RaidInfoFrame:GetFrameLevel()
	end

	-- Reparent to BetterFriendsFrame
	RaidInfoFrame:SetParent(BetterFriendsFrame)
	ApplyDockedRaidInfoFrameLayering()
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
				RestoreRaidInfoFrameLayering()
				RaidInfoFrame:ClearAllPoints()
				if RaidFrame then
					RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", 0, -20)
				end
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
	if not raidFrame then
		return
	end

	local button = raidFrame.ControlPanel and raidFrame.ControlPanel.RaidInfoButton
	if not button then
		return
	end

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
	-- CRITICAL: Register for ALL clicks to allow Secure Attributes with modifiers
	-- "AnyUp" enables processing of Shift+Click, Alt+Click, etc. via attributes
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton")

	-- Expand hit rect to cover the 2px gap between buttons
	-- Negative values expand the hit area BEYOND the button's visual bounds
	-- Top: +1px, Right: 0px, Bottom: +1px, Left: 0px
	-- This makes the drop zone 2px taller (1px above + 1px below) covering the gaps
	self:SetHitRectInsets(0, 0, -1, -1)
end

function BetterRaidMemberButton_OnEnter(self)
	-- Always show highlight
	if self.Highlight then
		self.Highlight:Show()
	end

	-- If dragging, skip tooltip (but keep highlight)
	if BetterRaidFrame_DraggedUnit then
		return
	end

	-- Show tooltip if unit exists
	if self.unit then
		UnitFrame_UpdateTooltip(self)
	end
end

function BetterRaidMemberButton_OnLeave(self)
	GameTooltip:Hide()

	if self.Highlight then
		self.Highlight:Hide()
	end
end

function BetterRaidMemberButton_PostClick(self, button)
	-- PostClick wird NACH Attribute-Verarbeitung aufgerufen
	-- Hier ist sicher, dass Secure Attributes bereits verarbeitet wurden

	if not self.unit or not self.name then
		return
	end

	-- Detect modifier combination
	local modifier = nil
	if IsShiftKeyDown() and IsControlKeyDown() then
		modifier = "SHIFT-CTRL"
	elseif IsShiftKeyDown() and IsAltKeyDown() then
		modifier = "SHIFT-ALT"
	elseif IsControlKeyDown() and IsAltKeyDown() then
		modifier = "CTRL-ALT"
	elseif IsShiftKeyDown() then
		modifier = "SHIFT"
	elseif IsControlKeyDown() then
		modifier = "CTRL"
	elseif IsAltKeyDown() then
		modifier = "ALT"
	end

	-- Try to handle as shortcut (Promote/Lead only, MainTank/MainAssist via attributes)
	if modifier then
		local RaidFrame = GetRaidFrame()
		if RaidFrame and RaidFrame:HandleShortcutClick(self, button, modifier) then
			return -- Shortcut handled
		end
	end

	if button == "LeftButton" then
		-- Ctrl+Left-click: Toggle multi-selection
		if IsControlKeyDown() then
			TogglePlayerSelection(self)
		else
			-- Normal left-click: Clear all selections
			ClearAllSelections()
		end
	elseif button == "RightButton" then
		-- RightButton: Show unit context menu manually
		-- (InsecureActionButtonTemplate doesn't support togglemenu secure attribute)
		if not IsModifierKeyDown() and self.unit then
			if UnitExists(self.unit) then
				-- Use Blizzard's unit popup menu system
				if ToggleDropDownMenu and FriendsDropDown then
					-- Classic: Use dropdown-based unit menu
					FriendsDropDown.unit = self.unit
					FriendsDropDown.id = self.name
					FriendsDropDown.initialize = RaidFrameDropDown_Initialize
					ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor", 0, 0)
				elseif UnitPopup_ShowMenu then
					-- Retail: Use modern unit popup
					UnitPopup_ShowMenu(self, "RAID_PLAYER", self.unit, self.name)
				end
			end
		end
	end
end

function BetterRaidMemberButton_OnDragUpdate(self)
	local ghost = BFL:GetDragGhost()
	if ghost and ghost:IsShown() then
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		ghost:ClearAllPoints()
		ghost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x / scale) + 10, (y / scale) - 10)
	end
end

function BetterRaidMemberButton_OnDragStart(self)
	if not self.unit or not self.name then
		return
	end

	-- CRITICAL: Block drag if ANY modifier is pressed (shortcuts have priority)
	if IsModifierKeyDown() then
		return
	end

	-- Check if player is raid leader or assistant
	local isLeader = UnitIsGroupLeader("player")
	local isAssistant = UnitIsGroupAssistant("player")

	if not isLeader and not isAssistant then
		return
	end

	-- Start ghost
	local ghost = BFL:GetDragGhost()
	if ghost then
		local raidIndex = tonumber(string.match(self.unit, "raid(%d+)"))
		local isMultiDrag = raidIndex and IsPlayerSelected(raidIndex) and #BetterRaidFrame_SelectedPlayers > 1

		if isMultiDrag then
			-- Multi-selection mode: Show list of names
			local names = {}
			for _, data in ipairs(BetterRaidFrame_SelectedPlayers) do
				local nameStr = data.name or "Unknown"
				-- Use UnitClass if valid unit, otherwise try to guess or white
				local _, cls = UnitClass(data.unit)
				if cls and RAID_CLASS_COLORS[cls] then
					local c = RAID_CLASS_COLORS[cls]
					nameStr = string.format("|c%s%s|r", c.colorStr, nameStr)
				end
				table.insert(names, nameStr)
			end

			ghost.text:SetText(table.concat(names, "\n"))
			ghost.text:SetTextColor(1, 0.82, 0) -- Reset base color to Gold

			if ghost.stripe then
				ghost.stripe:SetColorTexture(1, 0.82, 0, 1.0) -- Gold for group drag
			end

			-- Dynamic size
			local width = ghost.text:GetStringWidth() + 30
			local height = ghost.text:GetStringHeight() + 10
			ghost:SetSize(width, math.max(24, height))
		else
			-- Single mode: Standard class colored text
			ghost.text:SetText(self.name)

			local r, g, b = 1, 1, 1
			local classFileName = nil

			if self.memberData and self.memberData.classFileName then
				classFileName = self.memberData.classFileName
			elseif self.unit then
				local _, cls = UnitClass(self.unit)
				classFileName = cls
			end

			if classFileName then
				local classColor = RAID_CLASS_COLORS[classFileName]
				if classColor then
					r, g, b = classColor.r, classColor.g, classColor.b
				end
			end

			ghost.text:SetTextColor(r, g, b)
			if ghost.stripe then
				ghost.stripe:SetColorTexture(r, g, b, 1.0)
			end

			-- Set size based on text width (Fix for invisible ghost)
			local width = ghost.text:GetStringWidth() + 30
			ghost:SetSize(width, 24)
		end

		ghost:Show()
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		ghost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x / scale) + 10, (y / scale) - 10)
	end

	-- Enable update script
	self:SetScript("OnUpdate", BetterRaidMemberButton_OnDragUpdate)

	-- Phase 8.2: Clear selections if dragging non-selected player
	local raidIndex = tonumber(string.match(self.unit, "raid(%d+)"))
	if raidIndex and not IsPlayerSelected(raidIndex) then
		ClearAllSelections()
	end

	-- Show drag highlight on the dragged button
	local RaidFrame = GetRaidFrame()
	if RaidFrame and raidIndex then
		RaidFrame:SetButtonDragHighlight(raidIndex, true)
	end

	-- Phase 8.2: Show drag highlights on all selected players (if multi-select active)
	if #BetterRaidFrame_SelectedPlayers > 0 then
		for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
			if RaidFrame and playerData.raidIndex and playerData.raidIndex ~= raidIndex then
				RaidFrame:SetButtonDragHighlight(playerData.raidIndex, true)
			end
		end
	end

	-- Start drag (for moving to different groups)
	-- Store dragged unit info
	BetterRaidFrame_DraggedUnit = {
		unit = self.unit,
		name = self.name,
		groupIndex = self.groupIndex,
		raidIndex = raidIndex, -- Store for clearing highlight later
	}
end

function BetterRaidMemberButton_OnDragStop(self)
	-- Stop updates
	self:SetScript("OnUpdate", nil)

	-- Hide ghost
	local ghost = BFL:GetDragGhost()
	if ghost then
		ghost:Hide()
		ghost:ClearAllPoints()
	end

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
		-- Clear drag highlights before returning
		local RaidFrame = GetRaidFrame()
		if RaidFrame then
			if BetterRaidFrame_DraggedUnit and BetterRaidFrame_DraggedUnit.raidIndex then
				RaidFrame:SetButtonDragHighlight(BetterRaidFrame_DraggedUnit.raidIndex, false)
			end
			-- Phase 8.2: Clear drag highlights on all selected players
			for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
				if playerData.raidIndex then
					RaidFrame:SetButtonDragHighlight(playerData.raidIndex, false)
				end
			end
		end
		BetterRaidFrame_DraggedUnit = nil
		return
	end

	-- Don't allow dropping on self
	if targetFrame.unit == BetterRaidFrame_DraggedUnit.unit then
		-- Clear drag highlights before returning
		local RaidFrame = GetRaidFrame()
		if RaidFrame then
			if BetterRaidFrame_DraggedUnit and BetterRaidFrame_DraggedUnit.raidIndex then
				RaidFrame:SetButtonDragHighlight(BetterRaidFrame_DraggedUnit.raidIndex, false)
			end
			-- Phase 8.2: Clear drag highlights on all selected players
			for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
				if playerData.raidIndex then
					RaidFrame:SetButtonDragHighlight(playerData.raidIndex, false)
				end
			end
		end
		BetterRaidFrame_DraggedUnit = nil
		return
	end

	-- Get source and target subgroups from groupIndex (always set on buttons)
	local sourceSubgroup = BetterRaidFrame_DraggedUnit.groupIndex
	local targetSubgroup = targetFrame.groupIndex

	-- Only move if different subgroup
	if targetSubgroup ~= sourceSubgroup then
		-- Calculate raidIndex from unit (raid1 = 1, raid2 = 2, etc.)
		local sourceRaidIndex = tonumber(string.match(BetterRaidFrame_DraggedUnit.unit, "raid(%d+)"))
		if not sourceRaidIndex then
			BetterRaidFrame_DraggedUnit = nil
			return
		end

		-- Phase 8.2: Check for multi-selection bulk move
		if #BetterRaidFrame_SelectedPlayers > 0 then
			-- BULK MOVE: Move all selected players to target group
			BulkMoveToGroup(targetSubgroup)

			-- Clear drag highlights BEFORE clearing selections (need the player list)
			local RaidFrame = GetRaidFrame()
			if RaidFrame then
				if BetterRaidFrame_DraggedUnit and BetterRaidFrame_DraggedUnit.raidIndex then
					RaidFrame:SetButtonDragHighlight(BetterRaidFrame_DraggedUnit.raidIndex, false)
				end
				for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
					if playerData.raidIndex then
						RaidFrame:SetButtonDragHighlight(playerData.raidIndex, false)
					end
				end
			end

			ClearAllSelections()
			BetterRaidFrame_DraggedUnit = nil
			return
		end

		-- Check if target slot is occupied
		if targetFrame.unit and targetFrame.unit ~= "" then
			-- SWAP: Both players exchange subgroups
			-- Use Blizzard's native SwapRaidSubgroup API (handles full groups automatically)
			local targetRaidIndex = tonumber(string.match(targetFrame.unit, "raid(%d+)"))

			if targetRaidIndex then
				local success, errorMsg = pcall(SwapRaidSubgroup, sourceRaidIndex, targetRaidIndex)

				if success then
					-- Success feedback (green toast)
					local sourceName = GetRaidRosterInfo(sourceRaidIndex)
					local targetName = GetRaidRosterInfo(targetRaidIndex)
					if sourceName and targetName then
						UIErrorsFrame:AddMessage(
							string.format(L.RAID_MSG_SWAP_SUCCESS, sourceName, targetName),
							0.0,
							1.0,
							0.0,
							1.0
						)
					end
					-- Note: Update handled by GROUP_ROSTER_UPDATE event with throttling
				else
					-- Error feedback (red toast)
					UIErrorsFrame:AddMessage(
						string.format(
							L.RAID_ERROR_SWAP_FAILED,
							tostring(errorMsg or (L.UNKNOWN_ERROR or "Unknown error"))
						),
						1.0,
						0.1,
						0.1,
						1.0
					)
				end
			end
		else
			-- MOVE: Target slot is empty (existing logic)
			local success, errorMsg = pcall(SetRaidSubgroup, sourceRaidIndex, targetSubgroup)

			if success then
				-- Success feedback (green toast)
				local playerName = GetRaidRosterInfo(sourceRaidIndex)
				if playerName then
					UIErrorsFrame:AddMessage(
						string.format(L.RAID_MSG_MOVE_SUCCESS, playerName, targetSubgroup),
						0.0,
						1.0,
						0.0,
						1.0
					)
				end
				-- Note: Update handled by GROUP_ROSTER_UPDATE event with throttling
			else
				-- Error feedback (red toast)
				UIErrorsFrame:AddMessage(
					string.format(L.RAID_ERROR_MOVE_FAILED, tostring(errorMsg or (L.UNKNOWN_ERROR or "Unknown error"))),
					1.0,
					0.1,
					0.1,
					1.0
				)
			end
		end
	end

	-- Clear drag highlights on all buttons (primary dragged button + any selected players)
	local RaidFrame = GetRaidFrame()
	if RaidFrame then
		-- Clear drag highlight on primary dragged button
		if BetterRaidFrame_DraggedUnit and BetterRaidFrame_DraggedUnit.raidIndex then
			RaidFrame:SetButtonDragHighlight(BetterRaidFrame_DraggedUnit.raidIndex, false)
		end

		-- Phase 8.2: Clear drag highlights on all selected players (if multi-select was active)
		for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
			if playerData.raidIndex then
				RaidFrame:SetButtonDragHighlight(playerData.raidIndex, false)
			end
		end
	end

	-- Clear drag state
	BetterRaidFrame_DraggedUnit = nil
end
