--------------------------------------------------------------------------
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

-- Helper to add error label to dialog if it doesn't exist
local function EnsureErrorLabel(dialog)
	if not dialog.BFL_ErrorLabel then
		local errorLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
		errorLabel:SetPoint("TOP", dialog.EditBox, "BOTTOM", 0, 0)
		errorLabel:SetPoint("LEFT", dialog, "LEFT", 30, 0)
		errorLabel:SetPoint("RIGHT", dialog, "RIGHT", -30, 0)
		errorLabel:SetWordWrap(true)
		dialog.BFL_ErrorLabel = errorLabel
	end
	return dialog.BFL_ErrorLabel
end

-- Shared validation logic
local function ValidateDialogInput(editBox, isRename)
	local dialog = editBox:GetParent()
	local text = editBox:GetText()
	local Groups = BFL:GetModule("Groups")
	local errorLabel = EnsureErrorLabel(dialog)
	
	-- Safely get the accept button (Button1)
	local button1 = dialog.button1
	
	-- Last resort: Check global name if we have one (covers Button1)
	if not button1 and dialog.GetName and dialog:GetName() then
		button1 = _G[dialog:GetName().."Button1"]
	end

	-- Absolute fallback for standard StaticPopup1 (Common case)
	if not button1 and dialog == StaticPopup1 and _G["StaticPopup1Button1"] then
		button1 = _G["StaticPopup1Button1"]
	end

	-- Ultimate fallback: Scan children for the button (Robustness for renamed/hooked frames)
	if not button1 and dialog.GetChildren then
		local children = {dialog:GetChildren()}
		for _, child in ipairs(children) do
			if child and child.GetObjectType and child:GetObjectType() == "Button" and child.GetText then
				local btnText = child:GetText()
				-- Check for Create or Rename button text
				if btnText and (btnText == L.DIALOG_CREATE_GROUP_BTN1 or btnText == L.DIALOG_RENAME_GROUP_BTN1) then
					button1 = child
					break
				end
			end
		end
	end
	
	if not Groups then return end
	
	local currentGroupId = isRename and dialog.data or nil
	local isValid, errorMsg = Groups:ValidateGroupName(text, currentGroupId)

	-- Debug visualization for troubleshooting
	-- if BFL.DebugPrint then
	-- 	BFL:DebugPrint("Validation:", text, "| Rename:", isRename, "| Valid:", isValid, "| ButtonFound:", (button1 ~= nil))
	-- end
	
	if isValid then
		if button1 then
			button1:Enable()
		end
		if errorLabel then
			errorLabel:SetText("")
			-- Reset text color if needed, typically standard
			editBox:SetTextColor(1, 1, 1)
		end
	else
		if button1 then
			button1:Disable()
		end
		if errorLabel then
			errorLabel:SetText(errorMsg or "")
			editBox:SetTextColor(1, 0.5, 0.5) -- Reddish text to indicate error
		end
	end
end

function Dialogs:RegisterDialogs()
	-- Dialog for creating a new group
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self)
			local groupName = self.EditBox:GetText()
			local Groups = BFL:GetModule("Groups")
			if Groups then
				local isValid = Groups:ValidateGroupName(groupName)
				if isValid then
					local success, groupId = Groups:Create(groupName)
					if success then
						BFL:ForceRefreshFriendsList()
					end
				end
			end
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, false)
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			local groupName = self:GetText()
			local Groups = BFL:GetModule("Groups")
			if Groups then
				-- Double check validation before proceeding on Enter
				local isValid = Groups:ValidateGroupName(groupName)
				if isValid then
					Groups:Create(groupName)
					BFL:ForceRefreshFriendsList()
					parent:Hide()
				end
			end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
			ValidateDialogInput(self.EditBox, false) -- Validate initial state
		end,
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
		OnAccept = function(self, friendUID)
			local groupName = self.EditBox:GetText()
			local Groups = BFL:GetModule("Groups")
			if Groups then
				local isValid = Groups:ValidateGroupName(groupName)
				if isValid then
					local success, groupId = Groups:Create(groupName)
					if success then
						Groups:ToggleFriendInGroup(friendUID, groupId)
						BFL:ForceRefreshFriendsList()
					end
				end
			end
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, false)
		end,
		EditBoxOnEnterPressed = function(self, friendUID)
			local parent = self:GetParent()
			local groupName = self:GetText()
			local Groups = BFL:GetModule("Groups")
			if Groups then
				-- Double check validation
				local isValid = Groups:ValidateGroupName(groupName)
				if isValid then
					local success, groupId = Groups:Create(groupName)
					if success then
						Groups:ToggleFriendInGroup(friendUID, groupId)
						BFL:ForceRefreshFriendsList()
						parent:Hide()
					end
				end
			end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
			ValidateDialogInput(self.EditBox, false) -- Validate initial state
		end,
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
		OnAccept = function(self, data)
			local newName = self.EditBox:GetText()
			local FriendsList = BFL and BFL:GetModule("FriendsList")
			if FriendsList then
				-- We assume validation passed because button was enabled
				local success, err = FriendsList:RenameGroup(data, newName)
				if success then
					local Settings = BFL and BFL:GetModule("Settings")
					if Settings then
						Settings:RefreshGroupList()
					end
					BFL:ForceRefreshFriendsList()
				end
			end
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, true)
		end,
		EditBoxOnEnterPressed = function(self, data)
			local parent = self:GetParent()
			local newName = self:GetText()
			
			-- Double check validation manually if needed, or rely on visual state logic
			local Groups = BFL:GetModule("Groups")
			if Groups then
				local isValid = Groups:ValidateGroupName(newName, data)
				if isValid then
					local FriendsList = BFL and BFL:GetModule("FriendsList")
					if FriendsList then
						local success, err = FriendsList:RenameGroup(data, newName)
						if success then
							local Settings = BFL and BFL:GetModule("Settings")
							if Settings then
								Settings:RefreshGroupList()
							end
							BFL:ForceRefreshFriendsList()
							parent:Hide()
						end
					end
				end
			end
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
			ValidateDialogInput(self.EditBox, true) -- Validate initial state
		end,
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
	
	-- Dialog for resetting all Edit Mode layouts (Phase 5)
	StaticPopupDialogs["BETTER_FRIENDLIST_RESET_ALL_LAYOUTS"] = {
		text = BFL.L.DIALOG_RESET_LAYOUTS_TEXT,
		button1 = BFL.L.DIALOG_RESET_LAYOUTS_BTN1,
		button2 = BFL.L.DIALOG_RESET_BTN2, -- Cancel
		OnAccept = function(self)
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
		end,
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
		OnAccept = function(self)
			local DB = BFL:GetModule("DB")
			if DB and DB.pendingUIPanelSystemChange ~= nil then
				DB:Set("useUIPanelSystem", DB.pendingUIPanelSystemChange)
				DB.pendingUIPanelSystemChange = nil
				ReloadUI()
			end
		end,
		OnCancel = function(self)
			local DB = BFL:GetModule("DB")
			if DB then
				DB.pendingUIPanelSystemChange = nil
				-- Revert checkbox to original state
				if BFL.Settings and BFL.Settings.RefreshSettingsPanel then
					BFL.Settings:RefreshSettingsPanel()
				end
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	

end

--------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------

-- Auto-register dialogs when module loads
Dialogs:RegisterDialogs()

