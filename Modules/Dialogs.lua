--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua"); --------------------------------------------------------------------------
-- Dialogs Module - StaticPopup Dialog Management
--------------------------------------------------------------------------
-- This module manages all StaticPopup dialogs for the addon including:
-- - Group creation dialogs
-- - Group rename/delete dialogs
-- - Friend assignment dialogs
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local L = BFL.L

-- Register the Dialogs module
local Dialogs = BFL:RegisterModule("Dialogs", {})

--------------------------------------------------------------------------
-- Dialog Registration
--------------------------------------------------------------------------

function Dialogs:RegisterDialogs() Perfy_Trace(Perfy_GetTime(), "Enter", "Dialogs:RegisterDialogs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:20:0");
	-- Dialog for creating a new group
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:27:13");
			local groupName = self.EditBox:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success, groupId = Groups:Create(groupName)
					if success then
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
					end
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:27:13"); end,
		EditBoxOnEnterPressed = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:40:26");
			local parent = self:GetParent()
			local groupName = self:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					Groups:Create(groupName)
					-- Force full display refresh - groups affect display structure
					BFL:ForceRefreshFriendsList()
				end
			end
			parent:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:40:26"); end,
		EditBoxOnEscapePressed = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:53:27");
			self:GetParent():Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:53:27"); end,
		OnShow = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:56:11");
			self.EditBox:SetFocus()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:56:11"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for creating a new group and adding a friend to it
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, friendUID) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:71:13");
			local groupName = self.EditBox:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success, groupId = Groups:Create(groupName)
					if success then
						-- Add friend to the newly created group
						Groups:ToggleFriendInGroup(friendUID, groupId)
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					end
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:71:13"); end,
		EditBoxOnEnterPressed = function(self, friendUID) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:87:26");
			local parent = self:GetParent()
			local groupName = self:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success, groupId = Groups:Create(groupName)
					if success then
						-- Add friend to the newly created group
						Groups:ToggleFriendInGroup(friendUID, groupId)
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
					end
				end
			end
			parent:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:87:26"); end,
		EditBoxOnEscapePressed = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:104:27");
			self:GetParent():Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:104:27"); end,
		OnShow = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:107:11");
			self.EditBox:SetFocus()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:107:11"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for renaming a group
	StaticPopupDialogs["BETTER_FRIENDLIST_RENAME_GROUP"] = {
		text = L.DIALOG_RENAME_GROUP_TEXT,
		button1 = L.DIALOG_RENAME_GROUP_BTN1,
		button2 = L.DIALOG_RENAME_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:122:13");
			local newName = self.EditBox:GetText()
			if newName and newName ~= "" then
				local FriendsList = BFL and BFL:GetModule("FriendsList")
				if FriendsList then
					local success, err = FriendsList:RenameGroup(data, newName)
					if success then
						-- Refresh settings group list if it's open
						local Settings = BFL and BFL:GetModule("Settings")
						if Settings then
							Settings:RefreshGroupList()
						end
						
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
					end
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:122:13"); end,
		EditBoxOnEnterPressed = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:141:26");
			local parent = self:GetParent()
			local newName = self:GetText()
			if newName and newName ~= "" then
				local FriendsList = BFL and BFL:GetModule("FriendsList")
				if FriendsList then
					local success, err = FriendsList:RenameGroup(data, newName)
					if success then
						-- Refresh settings group list if it's open
						local Settings = BFL and BFL:GetModule("Settings")
						if Settings then
							Settings:RefreshGroupList()
						end
						
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
					end
				end
			end
			parent:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:141:26"); end,
		EditBoxOnEscapePressed = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:162:27");
			self:GetParent():Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:162:27"); end,
		OnShow = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:165:11");
			-- Get group info from Groups module
			local Groups = BFL and BFL:GetModule("Groups")
			local groupName = ""
			
			if Groups and data then
				local groupInfo = Groups:Get(data)
				if groupInfo then
					groupName = groupInfo.name or ""
				end
			end
			
			self.EditBox:SetText(groupName)
			self.EditBox:SetFocus()
			self.EditBox:HighlightText()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:165:11"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for deleting a group
	StaticPopupDialogs["BETTER_FRIENDLIST_DELETE_GROUP"] = {
		text = L.DIALOG_DELETE_GROUP_TEXT,
		button1 = L.DIALOG_DELETE_GROUP_BTN1,
		button2 = L.DIALOG_DELETE_GROUP_BTN2,
		OnAccept = function(self, data) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:192:13");
			local groupId = data
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:DeleteGroup(groupId)
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:192:13"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	-- Dialog for resetting all Edit Mode layouts (Phase 5)
	StaticPopupDialogs["BETTER_FRIENDLIST_RESET_ALL_LAYOUTS"] = {
		text = BFL.L.DIALOG_RESET_LAYOUTS_TEXT,
		button1 = BFL.L.DIALOG_RESET_LAYOUTS_BTN1,
		button2 = BFL.L.DIALOG_RESET_BTN2, -- Cancel
		OnAccept = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:210:13");
			-- Clear all layout data
			BetterFriendlistDB.mainFrameSize = {}
			BetterFriendlistDB.mainFramePosition = {}
			BetterFriendlistDB.mainFramePositionMigrated = false
			
			-- Reset frame to default size and position
			local frame = BetterFriendsFrame
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				frame:SetSize(415, 570)
				
				-- Trigger responsive updates
				if BFL.MainFrameEditMode then
					BFL.MainFrameEditMode:TriggerResponsiveUpdates()
				end
			end
			
			-- BFL:DebugPrint("|cff00ff00All Edit Mode layouts reset to default|r")
			print("|cff00ffffBetterFriendlist:|r " .. BFL.L.MSG_LAYOUTS_RESET)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:210:13"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Confirm UI Panel System Change (requires reload)
	StaticPopupDialogs["BFL_CONFIRM_UI_PANEL_RELOAD"] = {
		text = BFL.L.DIALOG_UI_PANEL_RELOAD_TEXT or "Changing the UI Hierarchy setting requires a UI reload.\n\nReload now?",
		button1 = BFL.L.DIALOG_UI_PANEL_RELOAD_BTN1 or "Reload",
		button2 = BFL.L.DIALOG_UI_PANEL_RELOAD_BTN2 or "Cancel",
		OnAccept = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:243:13");
			local DB = BFL:GetModule("DB")
			if DB and DB.pendingUIPanelSystemChange ~= nil then
				DB:Set("useUIPanelSystem", DB.pendingUIPanelSystemChange)
				DB.pendingUIPanelSystemChange = nil
				ReloadUI()
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:243:13"); end,
		OnCancel = function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:251:13");
			local DB = BFL:GetModule("DB")
			if DB then
				DB.pendingUIPanelSystemChange = nil
				-- Revert checkbox to original state
				if BFL.Settings and BFL.Settings.RefreshSettingsPanel then
					BFL.Settings:RefreshSettingsPanel()
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:251:13"); end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	-- Add Group Trigger Dialog (Phase 10) - Using proper frame approach like Export/Import
	local triggerFrame = nil
	
	function Dialogs:CreateGroupTriggerDialog() Perfy_Trace(Perfy_GetTime(), "Enter", "Dialogs:CreateGroupTriggerDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:270:1");
		if triggerFrame then
			triggerFrame:Show()
			Perfy_Trace(Perfy_GetTime(), "Leave", "Dialogs:CreateGroupTriggerDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:270:1"); return
		end
		
		triggerFrame = CreateFrame("Frame", "BFL_GroupTriggerDialog", UIParent, "BasicFrameTemplateWithInset")
		triggerFrame:SetSize(400, 300)
		triggerFrame:SetFrameStrata("DIALOG")
		
		-- Set parent to Settings frame for auto-close behavior
		if BetterFriendlistSettingsFrame then
			triggerFrame:SetParent(BetterFriendlistSettingsFrame)
		end
		
		-- Position next to Settings frame if open, otherwise center
		if BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
			triggerFrame:SetPoint("TOPLEFT", BetterFriendlistSettingsFrame, "TOPRIGHT", 10, 0)
		else
			triggerFrame:SetPoint("CENTER")
		end
		triggerFrame:EnableMouse(true)
		triggerFrame:SetMovable(true)
		triggerFrame:RegisterForDrag("LeftButton")
		triggerFrame:SetScript("OnDragStart", triggerFrame.StartMoving)
		triggerFrame:SetScript("OnDragStop", triggerFrame.StopMovingOrSizing)
		triggerFrame:Hide()
		
		-- Title
		triggerFrame.title = triggerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
		triggerFrame.title:SetPoint("TOP", 0, -5)
		triggerFrame.title:SetText(BFL.L.DIALOG_TRIGGER_TITLE)
		
		-- Info text
		triggerFrame.info = triggerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
		triggerFrame.info:SetPoint("TOPLEFT", 15, -30)
		triggerFrame.info:SetPoint("TOPRIGHT", -15, -30)
		triggerFrame.info:SetJustifyH("LEFT")
		triggerFrame.info:SetText(BFL.L.DIALOG_TRIGGER_INFO)
		
		-- Group label
		triggerFrame.groupLabel = triggerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
		triggerFrame.groupLabel:SetPoint("TOPLEFT", 15, -60)
		triggerFrame.groupLabel:SetText(BFL.L.DIALOG_TRIGGER_SELECT_GROUP)
		
		-- Group dropdown (Classic-compatible)
		if BFL.IsClassic or not BFL.HasModernDropdown then
			-- Classic: Use UIDropDownMenuTemplate
			triggerFrame.groupDropdown = CreateFrame("Frame", "BFL_GroupTriggerDropdown", triggerFrame, "UIDropDownMenuTemplate")
			triggerFrame.groupDropdown:SetPoint("TOPLEFT", 0, -80)
			UIDropDownMenu_SetWidth(triggerFrame.groupDropdown, 340)
		else
			-- Retail: Use modern WowStyle1DropdownTemplate
			triggerFrame.groupDropdown = CreateFrame("DropdownButton", nil, triggerFrame, "WowStyle1DropdownTemplate")
			triggerFrame.groupDropdown:SetWidth(360)
			triggerFrame.groupDropdown:SetPoint("TOPLEFT", 15, -80)
		end
		
		-- Threshold label
		triggerFrame.thresholdLabel = triggerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
		triggerFrame.thresholdLabel:SetPoint("TOPLEFT", 15, -120)
		triggerFrame.thresholdLabel:SetText(BFL.L.DIALOG_TRIGGER_MIN_FRIENDS)
		
		-- Threshold value display (next to label)
		triggerFrame.thresholdValue = triggerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
		triggerFrame.thresholdValue:SetPoint("LEFT", triggerFrame.thresholdLabel, "RIGHT", 5, 0)
		triggerFrame.thresholdValue:SetText("3")
		
		-- Threshold slider (full width) - Classic uses OptionsSliderTemplate
		if BFL.IsClassic then
			-- Classic: Use OptionsSliderTemplate
			triggerFrame.thresholdSlider = CreateFrame("Slider", "BFL_TriggerThresholdSlider", triggerFrame, "OptionsSliderTemplate")
			triggerFrame.thresholdSlider:SetPoint("TOPLEFT", 15, -150)
			triggerFrame.thresholdSlider:SetPoint("TOPRIGHT", -15, -150)
			triggerFrame.thresholdSlider:SetMinMaxValues(1, 10)
			triggerFrame.thresholdSlider:SetValue(3)
			triggerFrame.thresholdSlider:SetValueStep(1)
			triggerFrame.thresholdSlider:SetObeyStepOnDrag(true)
			
			-- Hide default text elements
			local name = triggerFrame.thresholdSlider:GetName()
			if _G[name .. "Low"] then _G[name .. "Low"]:SetText("1") end
			if _G[name .. "High"] then _G[name .. "High"]:SetText("10") end
			if _G[name .. "Text"] then _G[name .. "Text"]:SetText("") end
			
			-- Update value display when slider changes
			triggerFrame.thresholdSlider:SetScript("OnValueChanged", function(self, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:356:60");
				value = math.floor(value + 0.5)
				triggerFrame.thresholdValue:SetText(tostring(value))
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:356:60"); end)
			
			-- Helper method for getting value
			function triggerFrame.thresholdSlider:GetSliderValue() Perfy_Trace(Perfy_GetTime(), "Enter", "thresholdSlider:GetSliderValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:362:3");
				return Perfy_Trace_Passthrough("Leave", "thresholdSlider:GetSliderValue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:362:3", math.floor(self:GetValue() + 0.5))
			end
		else
			-- Retail: Use modern MinimalSliderWithSteppersTemplate
			triggerFrame.thresholdSlider = CreateFrame("Slider", nil, triggerFrame, "MinimalSliderWithSteppersTemplate")
			triggerFrame.thresholdSlider:SetPoint("TOPLEFT", 15, -140)
			triggerFrame.thresholdSlider:SetPoint("TOPRIGHT", -15, -140)
			triggerFrame.thresholdSlider:SetHeight(20)
			triggerFrame.thresholdSlider:Init(3, 1, 10, 9, {
				[MinimalSliderWithSteppersMixin.Label.Right] = function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:372:51");
					Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:372:51"); return "" -- Empty string, we show value in thresholdValue instead
				end
			})
			
			-- Update value display when slider changes
			triggerFrame.thresholdSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:378:102");
				triggerFrame.thresholdValue:SetText(tostring(value))
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:378:102"); end)
		end
		
		-- Create button
		local createBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
		createBtn:SetSize(100, 25)
		createBtn:SetPoint("BOTTOMRIGHT", -15, 15)
		createBtn:SetText(BFL.L.DIALOG_TRIGGER_CREATE)
		createBtn:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:388:33");
			local Groups = BFL:GetModule("Groups")
			if not Groups then Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:388:33"); return end
			
			local selectedGroup = triggerFrame.selectedGroupId
			-- Get value from display text (more reliable than GetValue)
			local threshold = tonumber(triggerFrame.thresholdValue:GetText()) or 3
			
			if not selectedGroup then
				print("|cffff0000BetterFriendlist:|r " .. BFL.L.ERROR_SELECT_GROUP)
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:388:33"); return
			end
			
			local triggerID = "trigger_" .. selectedGroup .. "_" .. threshold .. "_" .. time()
			
			if not BetterFriendlistDB.notificationGroupTriggers then
				BetterFriendlistDB.notificationGroupTriggers = {}
			end
			
			BetterFriendlistDB.notificationGroupTriggers[triggerID] = {
				groupId = selectedGroup,
				threshold = threshold,
				enabled = true,
				lastTriggered = 0
			}
			
			local group = Groups:Get(selectedGroup)
			local groupName = group and group.name or selectedGroup
			print("|cff00ff00BetterFriendlist:|r " .. string.format(BFL.L.MSG_TRIGGER_CREATED, threshold, groupName))
			
			-- Trigger list refresh via global callback if registered
			if _G.BFL_RefreshNotificationTriggers then
				_G.BFL_RefreshNotificationTriggers()
			end
			
			triggerFrame:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:388:33"); end)
		
		-- Cancel button
		local cancelBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
		cancelBtn:SetSize(100, 25)
		cancelBtn:SetPoint("BOTTOMLEFT", 15, 15)
		cancelBtn:SetText(BFL.L.DIALOG_TRIGGER_CANCEL)
		cancelBtn:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:431:33");
			triggerFrame:Hide()
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:431:33"); end)
		
		-- OnShow: Populate dropdown and reposition
		triggerFrame:SetScript("OnShow", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:436:35");
			-- Reposition next to Settings if open
			self:ClearAllPoints()
			if BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
				self:SetPoint("TOPLEFT", BetterFriendlistSettingsFrame, "TOPRIGHT", 10, 0)
			else
				self:SetPoint("CENTER")
			end
			
			local Groups = BFL:GetModule("Groups")
			if not Groups then
				self:Hide()
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:436:35"); return
			end
			
			local allGroups = Groups:GetAll()
			local groupOptions = {}
			
			for groupId, groupData in pairs(allGroups) do
				if not groupData.builtin or groupId == "favorites" then
					table.insert(groupOptions, {id = groupId, name = groupData.name, order = groupData.order or 50})
				end
			end
			
			-- Sort by order field (same as in Settings UI)
			table.sort(groupOptions, function(a, b) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:461:28"); return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:461:28", a.order < b.order) end)
			
			if #groupOptions == 0 then
				print("|cffff0000BetterFriendlist:|r " .. BFL.L.ERROR_NO_GROUPS)
				self:Hide()
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:436:35"); return
			end
			
			-- Set default
			self.selectedGroupId = groupOptions[1].id
			
			-- Setup dropdown menu (Classic-compatible)
			if BFL.IsClassic or not BFL.HasModernDropdown then
				-- Classic: Use UIDropDownMenu_Initialize
				-- Clssic: Use UIDropDownMenu API
				UIDropDownMenu_Initialize(self.groupDropdown, function(frame, level) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:476:50");
					level = level or 1
					for _, option in ipairs(groupOptions) do
						local info = UIDropDownMenu_CreateInfo()
						info.text = option.name
						info.value = option.id
						-- Use triggerFrame explicitely to avoid scope issues with 'self'
						info.checked = (triggerFrame.selectedGroupId == option.id)
						info.func = function() Perfy_Trace(Perfy_GetTime(), "Enter", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:484:18");
							triggerFrame.selectedGroupId = option.id
							UIDropDownMenu_SetText(triggerFrame.groupDropdown, option.name)
							CloseDropDownMenus()
						Perfy_Trace(Perfy_GetTime(), "Leave", "info.func file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:484:18"); end
						UIDropDownMenu_AddButton(info, level)
					end
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:476:50"); end)
				UIDropDownMenu_SetText(self.groupDropdown, groupOptions[1].name)
			else
				-- Retail: Use modern SetupMenu API
				self.groupDropdown:SetupMenu(function(dropdown, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:495:33");
					for _, option in ipairs(groupOptions) do
						local button = rootDescription:CreateButton(option.name, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:497:63");
							self.selectedGroupId = option.id
						Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:497:63"); end)
						button:SetIsSelected(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:500:27");
							return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:500:27", self.selectedGroupId == option.id)
						end)
					end
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:495:33"); end)
			end
			
			-- Reset slider and value display
			self.thresholdSlider:SetValue(3)
			self.thresholdValue:SetText("3")
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:436:35"); end)
		
		triggerFrame:Show()
	Perfy_Trace(Perfy_GetTime(), "Leave", "Dialogs:CreateGroupTriggerDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:270:1"); end
	
	-- Global accessor
	_G.BFL_ShowGroupTriggerDialog = function() Perfy_Trace(Perfy_GetTime(), "Enter", "_G.BFL_ShowGroupTriggerDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:516:33");
		local Dialogs = BFL:GetModule("Dialogs")
		if Dialogs then
			Dialogs:CreateGroupTriggerDialog()
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "_G.BFL_ShowGroupTriggerDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:516:33"); end
Perfy_Trace(Perfy_GetTime(), "Leave", "Dialogs:RegisterDialogs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua:20:0"); end

--------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------

-- Auto-register dialogs when module loads
Dialogs:RegisterDialogs()


Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Dialogs.lua");