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
end

--------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------

-- Auto-register dialogs when module loads
Dialogs:RegisterDialogs()
