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

function Dialogs:RegisterDialogs()
	-- Dialog for creating a new group
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self)
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
		end,
		EditBoxOnEnterPressed = function(self)
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
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
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
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
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
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
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
		text = L.DIALOG_RENAME_GROUP_TEXT,
		button1 = L.DIALOG_RENAME_GROUP_BTN1,
		button2 = L.DIALOG_RENAME_GROUP_BTN2,
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
						
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
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
						
						-- Force full display refresh - groups affect display structure
						BFL:ForceRefreshFriendsList()
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

