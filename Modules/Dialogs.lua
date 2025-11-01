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
		text = "Enter a name for the new group:",
		button1 = "Create",
		button2 = "Cancel",
		hasEditBox = true,
		OnAccept = function(self)
			local groupName = self.EditBox:GetText()
			if groupName and groupName ~= "" then
				BetterFriendsList_CreateGroup(groupName)
			end
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			local groupName = self:GetText()
			if groupName and groupName ~= "" then
				BetterFriendsList_CreateGroup(groupName)
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
		text = "Enter a name for the new group:",
		button1 = "Create",
		button2 = "Cancel",
		hasEditBox = true,
		OnAccept = function(self, friendUID)
			local groupName = self.EditBox:GetText()
			if groupName and groupName ~= "" then
				local success, groupId = BetterFriendsList_CreateGroup(groupName)
				if success then
					-- Add friend to the newly created group
					BetterFriendsList_ToggleFriendInGroup(friendUID, groupId)
				end
			end
		end,
		EditBoxOnEnterPressed = function(self, friendUID)
			local parent = self:GetParent()
			local groupName = self:GetText()
			if groupName and groupName ~= "" then
				local success, groupId = BetterFriendsList_CreateGroup(groupName)
				if success then
					-- Add friend to the newly created group
					BetterFriendsList_ToggleFriendInGroup(friendUID, groupId)
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
		text = "Enter a new name for the group:",
		button1 = "Rename",
		button2 = "Cancel",
		hasEditBox = true,
		OnAccept = function(self, data)
			local newName = self.EditBox:GetText()
			if newName and newName ~= "" then
				BetterFriendsList_RenameGroup(data, newName)
			end
		end,
		EditBoxOnEnterPressed = function(self, data)
			local parent = self:GetParent()
			local newName = self:GetText()
			if newName and newName ~= "" then
				BetterFriendsList_RenameGroup(data, newName)
			end
			parent:Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self, data)
			-- Access global friendGroups table
			local friendGroups = _G.friendGroups or {}
			self.EditBox:SetText(friendGroups[data] and friendGroups[data].name or "")
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
		text = "Are you sure you want to delete this group?\n\n|cffff0000This will remove all friends from this group.|r",
		button1 = "Delete",
		button2 = "Cancel",
		OnAccept = function(self, data)
			BetterFriendsList_DeleteGroup(data)
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
