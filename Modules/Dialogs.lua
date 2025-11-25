--------------------------------------------------------------------------
-- Dialogs Module - StaticPopup Dialog Management
--------------------------------------------------------------------------
-- This module manages all StaticPopup dialogs for the addon including:
-- - Group creation dialogs
-- - Group rename/delete dialogs
-- - Friend assignment dialogs
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...

-- Register the Dialogs module
local Dialogs = BFL:RegisterModule("Dialogs", {})

--------------------------------------------------------------------------
-- Dialog Registration
--------------------------------------------------------------------------

function Dialogs:RegisterDialogs()
	-- Dialog for creating a new group
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] = {
		text = BFL_L.DIALOG_CREATE_GROUP_TEXT,
		button1 = BFL_L.DIALOG_CREATE_GROUP_BTN1,
		button2 = BFL_L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self)
			local groupName = self.EditBox:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					local success, groupId = Groups:Create(groupName)
					if success then
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					end
				end
			end
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			local groupName = self:GetText()
			if groupName and groupName ~= "" then
				local Groups = BFL:GetModule("Groups")
				if Groups then
					Groups:Create(groupName)
					if BetterFriendsFrame_UpdateDisplay then
						BetterFriendsFrame_UpdateDisplay()
					end
				end
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for creating a new group and adding a friend to it
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND"] = {
		text = BFL_L.DIALOG_CREATE_GROUP_TEXT,
		button1 = BFL_L.DIALOG_CREATE_GROUP_BTN1,
		button2 = BFL_L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, friendUID)
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
		end,
		EditBoxOnEnterPressed = function(self, friendUID)
			local parent = self:GetParent()
			local groupName = self:GetText()
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
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for renaming a group
	StaticPopupDialogs["BETTER_FRIENDLIST_RENAME_GROUP"] = {
		text = BFL_L.DIALOG_RENAME_GROUP_TEXT,
		button1 = BFL_L.DIALOG_RENAME_GROUP_BTN1,
		button2 = BFL_L.DIALOG_RENAME_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, data)
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
						
						-- Refresh the friends list display
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					end
				end
			end
		end,
		EditBoxOnEnterPressed = function(self, data)
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
						
						-- Refresh the friends list display
						if BetterFriendsFrame_UpdateDisplay then
							BetterFriendsFrame_UpdateDisplay()
						end
					end
				end
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self, data)
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
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for deleting a group
	StaticPopupDialogs["BETTER_FRIENDLIST_DELETE_GROUP"] = {
		text = BFL_L.DIALOG_DELETE_GROUP_TEXT,
		button1 = BFL_L.DIALOG_DELETE_GROUP_BTN1,
		button2 = BFL_L.DIALOG_DELETE_GROUP_BTN2,
		OnAccept = function(self, data)
			local groupId = data
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:DeleteGroup(groupId)
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	-- Add Group Trigger Dialog (Phase 10) - Using proper frame approach like Export/Import
	local triggerFrame = nil
	
	function Dialogs:CreateGroupTriggerDialog()
		if triggerFrame then
			triggerFrame:Show()
			return
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
		triggerFrame.title = triggerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		triggerFrame.title:SetPoint("TOP", 0, -5)
		triggerFrame.title:SetText("Create Group Trigger")
		
		-- Info text
		triggerFrame.info = triggerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		triggerFrame.info:SetPoint("TOPLEFT", 15, -30)
		triggerFrame.info:SetPoint("TOPRIGHT", -15, -30)
		triggerFrame.info:SetJustifyH("LEFT")
		triggerFrame.info:SetText("Get notified when X friends from a group come online.")
		
		-- Group label
		triggerFrame.groupLabel = triggerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		triggerFrame.groupLabel:SetPoint("TOPLEFT", 15, -60)
		triggerFrame.groupLabel:SetText("Select Group:")
		
		-- Group dropdown
		triggerFrame.groupDropdown = CreateFrame("DropdownButton", nil, triggerFrame, "WowStyle1DropdownTemplate")
		triggerFrame.groupDropdown:SetWidth(360)
		triggerFrame.groupDropdown:SetPoint("TOPLEFT", 15, -80)
		
		-- Threshold label
		triggerFrame.thresholdLabel = triggerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		triggerFrame.thresholdLabel:SetPoint("TOPLEFT", 15, -120)
		triggerFrame.thresholdLabel:SetText("Minimum Friends Online:")
		
		-- Threshold value display (next to label)
		triggerFrame.thresholdValue = triggerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		triggerFrame.thresholdValue:SetPoint("LEFT", triggerFrame.thresholdLabel, "RIGHT", 5, 0)
		triggerFrame.thresholdValue:SetText("3")
		
		-- Threshold slider (full width)
		triggerFrame.thresholdSlider = CreateFrame("Slider", nil, triggerFrame, "MinimalSliderWithSteppersTemplate")
		triggerFrame.thresholdSlider:SetPoint("TOPLEFT", 15, -140)
		triggerFrame.thresholdSlider:SetPoint("TOPRIGHT", -15, -140)
		triggerFrame.thresholdSlider:SetHeight(20)
		triggerFrame.thresholdSlider:Init(3, 1, 10, 9, {
			[MinimalSliderWithSteppersMixin.Label.Right] = function(value)
				return "" -- Empty string, we show value in thresholdValue instead
			end
		})
		
		-- Update value display when slider changes
		triggerFrame.thresholdSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
			triggerFrame.thresholdValue:SetText(tostring(value))
		end)
		
		-- Create button
		local createBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
		createBtn:SetSize(100, 25)
		createBtn:SetPoint("BOTTOMRIGHT", -15, 15)
		createBtn:SetText("Create")
		createBtn:SetScript("OnClick", function()
			local Groups = BFL:GetModule("Groups")
			if not Groups then return end
			
			local selectedGroup = triggerFrame.selectedGroupId
			-- Get value from display text (more reliable than GetValue)
			local threshold = tonumber(triggerFrame.thresholdValue:GetText()) or 3
			
			if not selectedGroup then
				print("|cffff0000BetterFriendlist:|r Please select a group")
				return
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
			print("|cff00ff00BetterFriendlist:|r Trigger created: " .. threshold .. "+ friends from '" .. groupName .. "'")
			
			-- Trigger list refresh via global callback if registered
			if _G.BFL_RefreshNotificationTriggers then
				_G.BFL_RefreshNotificationTriggers()
			end
			
			triggerFrame:Hide()
		end)
		
		-- Cancel button
		local cancelBtn = CreateFrame("Button", nil, triggerFrame, "UIPanelButtonTemplate")
		cancelBtn:SetSize(100, 25)
		cancelBtn:SetPoint("BOTTOMLEFT", 15, 15)
		cancelBtn:SetText("Cancel")
		cancelBtn:SetScript("OnClick", function()
			triggerFrame:Hide()
		end)
		
		-- OnShow: Populate dropdown and reposition
		triggerFrame:SetScript("OnShow", function(self)
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
				return
			end
			
			local allGroups = Groups:GetAll()
			local groupOptions = {}
			
			for groupId, groupData in pairs(allGroups) do
				if not groupData.builtin or groupId == "favorites" then
					table.insert(groupOptions, {id = groupId, name = groupData.name, order = groupData.order or 50})
				end
			end
			
			-- Sort by order field (same as in Settings UI)
			table.sort(groupOptions, function(a, b) return a.order < b.order end)
			
			if #groupOptions == 0 then
				print("|cffff0000BetterFriendlist:|r No groups available. Create a custom group first.")
				self:Hide()
				return
			end
			
			-- Set default
			self.selectedGroupId = groupOptions[1].id
			
			-- Setup dropdown menu
			self.groupDropdown:SetupMenu(function(dropdown, rootDescription)
				for _, option in ipairs(groupOptions) do
					local button = rootDescription:CreateButton(option.name, function()
						self.selectedGroupId = option.id
					end)
					button:SetIsSelected(function()
						return self.selectedGroupId == option.id
					end)
				end
			end)
			
			-- Reset slider and value display
			self.thresholdSlider:SetValue(3)
			self.thresholdValue:SetText("3")
		end)
		
		triggerFrame:Show()
	end
	
	-- Global accessor
	_G.BFL_ShowGroupTriggerDialog = function()
		local Dialogs = BFL:GetModule("Dialogs")
		if Dialogs then
			Dialogs:CreateGroupTriggerDialog()
		end
	end
end

--------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------

-- Auto-register dialogs when module loads
Dialogs:RegisterDialogs()
