--------------------------------------------------------------------------
-- ButtonPool Module - Button Management & Recycling
--------------------------------------------------------------------------
-- This module manages button pools for the friends list including:
-- - Friend button creation and recycling
-- - Group header button creation and recycling
-- - Drag & drop system for friend-to-group assignment
-- - Button positioning and layout
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...

-- Register the ButtonPool module
local ButtonPool = BFL:RegisterModule("ButtonPool", {})

--------------------------------------------------------------------------
-- Constants & Configuration
--------------------------------------------------------------------------

-- Button types (must match BetterFriendlist.lua constants!)
local BUTTON_TYPE_FRIEND = 1
local BUTTON_TYPE_GROUP_HEADER = 2
local NUM_BUTTONS = 12  -- Number of original XML buttons to hide

--------------------------------------------------------------------------
-- Module State
--------------------------------------------------------------------------

-- Button pool storage
local buttonPool = {
	friendButtons = {},    -- Pooled friend buttons
	headerButtons = {},    -- Pooled group header buttons
	activeButtons = {}     -- Currently visible buttons
}

-- Drag & drop state
local currentDraggedFriend = nil

--------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------

local function GetButtonHeight()
	-- Access FontManager directly (already initialized by Core)
	if BFL.FontManager then
		return BFL.FontManager:GetButtonHeight()
	end
	return 32  -- Default fallback
end

local function GetFriendUID(friendData)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		return FriendsList:GetFriendUID(friendData)
	end
	return nil
end

local function GetGroupColorCode(groupId)
	local Groups = BFL:GetModule("Groups")
	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			local r = group.color.r or group.color[1] or 1
			local g = group.color.g or group.color[2] or 1
			local b = group.color.b or group.color[3] or 1
			return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
		end
	end
	return "|cffffffff"
end

local function GetFriendGroups()
	local Groups = BFL:GetModule("Groups")
	if Groups then
		return Groups:GetAll()
	end
	return {}
end

local function BuildDisplayList()
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList then
		FriendsList:BuildDisplayList()
	end
end

local function UpdateFriendsDisplay()
	-- Trigger display update via main frame
	if BetterFriendsFrame and BetterFriendsFrame.UpdateDisplay then
		BetterFriendsFrame:UpdateDisplay()
	end
end

--------------------------------------------------------------------------
-- Friend Button Creation
--------------------------------------------------------------------------

local function GetOrCreateFriendButton(index)
	if not buttonPool.friendButtons[index] then
		local scrollFrame = BetterFriendsFrame.ScrollFrame
		local buttonName = "BetterFriendsFrameScrollFrameButton" .. index
		local button = CreateFrame("Button", buttonName, scrollFrame, "BetterFriendsListButtonTemplate")
		
		local friendGroups = GetFriendGroups()
		
		-- Enable drag for friend buttons
		button:SetMovable(true)
		button:RegisterForDrag("LeftButton")
		
		-- Create drag overlay (shown during drag)
		local dragOverlay = button:CreateTexture(nil, "OVERLAY")
		dragOverlay:SetAllPoints()
		dragOverlay:SetColorTexture(1, 1, 1, 0.3)
		dragOverlay:Hide()
		button.dragOverlay = dragOverlay
		
		button:SetScript("OnDragStart", function(self)
			if self.friendData then
				-- Store friend name for header text updates
				currentDraggedFriend = self.friendData.name or self.friendData.accountName or self.friendData.battleTag or "Unknown"
				
				-- Show drag overlay
				self.dragOverlay:Show()
				self:SetAlpha(0.5)
				
				-- Start dragging
				GameTooltip:Hide()
				
				-- Enable OnUpdate to continuously check headers under mouse
				self:SetScript("OnUpdate", function(updateSelf)
					-- Get cursor position
					local cursorX, cursorY = GetCursorPosition()
					local scale = UIParent:GetEffectiveScale()
					cursorX = cursorX / scale
					cursorY = cursorY / scale
					
					-- Update all group headers
					for _, headerButton in pairs(buttonPool.headerButtons) do
						if headerButton:IsVisible() and headerButton.groupId and friendGroups[headerButton.groupId] and not friendGroups[headerButton.groupId].builtin then
							-- Check if cursor is over this header
							local left, bottom, width, height = headerButton:GetRect()
							local isOver = false
							if left then
								isOver = (cursorX >= left and cursorX <= left + width and 
								         cursorY >= bottom and cursorY <= bottom + height)
							end
							
							if isOver and currentDraggedFriend then
								-- Show highlight and update text
								headerButton.dropHighlight:Show()
								local groupData = friendGroups[headerButton.groupId]
								if groupData then
									local colorCode = GetGroupColorCode(headerButton.groupId)
									local headerText = string.format("%sAdd %s to %s|r", colorCode, currentDraggedFriend, groupData.name)
									headerButton:SetText(headerText)
								end
							else
								-- Hide highlight and restore original text
								headerButton.dropHighlight:Hide()
								local groupData = friendGroups[headerButton.groupId]
								if groupData then
									local memberCount = 0
									if BetterFriendlistDB.friendGroups then
										for _, groups in pairs(BetterFriendlistDB.friendGroups) do
											for _, gid in ipairs(groups) do
												if gid == headerButton.groupId then
													memberCount = memberCount + 1
													break
												end
											end
										end
									end
									local colorCode = GetGroupColorCode(headerButton.groupId)
									local headerText = string.format("%s%s (%d)|r", colorCode, groupData.name, memberCount)
									headerButton:SetText(headerText)
								end
							end
						end
					end
				end)
			end
		end)
		
		button:SetScript("OnDragStop", function(self)
			-- Disable OnUpdate
			self:SetScript("OnUpdate", nil)
			
			-- Clear dragged friend name
			currentDraggedFriend = nil
			
			-- Hide drag overlay
			self.dragOverlay:Hide()
			self:SetAlpha(1.0)
			
			-- Reset all header highlights and texts
			for _, headerButton in pairs(buttonPool.headerButtons) do
				if headerButton:IsVisible() and headerButton.groupId and friendGroups[headerButton.groupId] then
					headerButton.dropHighlight:Hide()
					local groupData = friendGroups[headerButton.groupId]
					local memberCount = 0
					if BetterFriendlistDB.friendGroups then
						for _, groups in pairs(BetterFriendlistDB.friendGroups) do
							for _, gid in ipairs(groups) do
								if gid == headerButton.groupId then
									memberCount = memberCount + 1
									break
								end
							end
						end
					end
					local colorCode = GetGroupColorCode(headerButton.groupId)
					local headerText = string.format("%s%s (%d)|r", colorCode, groupData.name, memberCount)
					headerButton:SetText(headerText)
				end
			end
			
			-- Get mouse position and find group header under cursor
			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			cursorX = cursorX / scale
			cursorY = cursorY / scale
			
			-- Check all group headers for mouse-over
			local droppedOnGroup = nil
			for _, headerButton in pairs(buttonPool.headerButtons) do
				if headerButton:IsVisible() and headerButton.groupId then
					local left, bottom, width, height = headerButton:GetRect()
					if left and cursorX >= left and cursorX <= left + width and 
					   cursorY >= bottom and cursorY <= bottom + height then
						droppedOnGroup = headerButton.groupId
						break
					end
				end
			end
			
			-- If dropped on a group, add friend to that group
			if droppedOnGroup and self.friendData then
				local friendUID = GetFriendUID(self.friendData)
				if friendUID then
					-- Remove from current groups if shift is not held
					if not IsShiftKeyDown() then
						if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
							for i = #BetterFriendlistDB.friendGroups[friendUID], 1, -1 do
								local groupId = BetterFriendlistDB.friendGroups[friendUID][i]
								if friendGroups[groupId] and not friendGroups[groupId].builtin then
									table.remove(BetterFriendlistDB.friendGroups[friendUID], i)
								end
							end
						end
					end
					
					-- Add to new group
					local Groups = BFL:GetModule("Groups")
					if Groups then
						Groups:ToggleFriendInGroup(friendUID, droppedOnGroup)
					end
					BuildDisplayList()
					UpdateFriendsDisplay()
				end
			end
		end)
		
		buttonPool.friendButtons[index] = button
	end
	return buttonPool.friendButtons[index]
end

--------------------------------------------------------------------------
-- Header Button Creation
--------------------------------------------------------------------------

local function GetOrCreateHeaderButton(index)
	if not buttonPool.headerButtons[index] then
		local scrollFrame = BetterFriendsFrame.ScrollFrame
		local buttonName = "BetterFriendsFrameScrollFrameHeader" .. index
		local button = CreateFrame("Button", buttonName, scrollFrame, "BetterFriendsGroupHeaderTemplate")
		
		local friendGroups = GetFriendGroups()
		
		-- Raise header buttons to ensure they're clickable
		button:SetFrameLevel(scrollFrame:GetFrameLevel() + 2)
		
		-- Create drop target highlight
		local dropHighlight = button:CreateTexture(nil, "BACKGROUND")
		dropHighlight:SetAllPoints()
		dropHighlight:SetColorTexture(0, 1, 0, 0.2)
		dropHighlight:Hide()
		button.dropHighlight = dropHighlight
		
		-- Enable tooltips
		button:SetScript("OnEnter", function(self)
			-- Check if we're currently dragging a friend
			local isDragging = currentDraggedFriend ~= nil
			
			if isDragging and self.groupId and friendGroups[self.groupId] and not friendGroups[self.groupId].builtin then
				-- Show drop target tooltip
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText("Drop to add to group", 1, 1, 1)
				GameTooltip:AddLine("Hold Shift to keep in other groups", 0.7, 0.7, 0.7, true)
				GameTooltip:Show()
			else
				-- Show group info tooltip
				if self.groupId and friendGroups[self.groupId] then
					local groupData = friendGroups[self.groupId]
					
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(groupData.name, 1, 1, 1)
					GameTooltip:AddLine("Right-click for options", 0.7, 0.7, 0.7, true)
					if not groupData.builtin then
						GameTooltip:AddLine("Drag friends here to add them", 0.5, 0.8, 1.0, true)
					end
					GameTooltip:Show()
				end
			end
		end)
		
		button:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		
		buttonPool.headerButtons[index] = button
	end
	return buttonPool.headerButtons[index]
end

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------

function ButtonPool:Initialize()
	-- Nothing to initialize yet
end

function ButtonPool:GetOrCreateFriendButton(index)
	return GetOrCreateFriendButton(index)
end

function ButtonPool:GetOrCreateHeaderButton(index)
	return GetOrCreateHeaderButton(index)
end

function ButtonPool:GetButtonForDisplay(index, buttonType)
	-- Get or create the appropriate button type
	local button
	if buttonType == BUTTON_TYPE_GROUP_HEADER then
		button = GetOrCreateHeaderButton(index)
	else
		button = GetOrCreateFriendButton(index)
		-- Set dynamic height based on compact mode
		button:SetHeight(GetButtonHeight())
	end
	
	-- Position the button based on previous button
	button:ClearAllPoints()
	if index == 1 then
		button:SetPoint("TOPLEFT", BetterFriendsFrame.ScrollFrame, "TOPLEFT", 5, -3)
	else
		local prevButton = buttonPool.activeButtons[index - 1]
		if prevButton then
			button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -1)
		end
	end
	
	buttonPool.activeButtons[index] = button
	return button
end

function ButtonPool:ResetButtonPool()
	-- Hide all buttons
	for _, button in pairs(buttonPool.friendButtons) do
		button:Hide()
	end
	for _, button in pairs(buttonPool.headerButtons) do
		button:Hide()
	end
	
	-- Clear active buttons list
	wipe(buttonPool.activeButtons)
	
	-- Also hide the original XML-defined buttons (Button1-Button12)
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	if scrollFrame then
		for i = 1, NUM_BUTTONS do
			local xmlButton = scrollFrame["Button" .. i]
			if xmlButton then
				xmlButton:Hide()
			end
		end
	end
end

function ButtonPool:GetActiveButtonCount()
	return #buttonPool.activeButtons
end

function ButtonPool:GetFriendButtonCount()
	local count = 0
	for _ in pairs(buttonPool.friendButtons) do
		count = count + 1
	end
	return count
end

function ButtonPool:GetHeaderButtonCount()
	local count = 0
	for _ in pairs(buttonPool.headerButtons) do
		count = count + 1
	end
	return count
end

-- Expose button type constant for external use
ButtonPool.BUTTON_TYPE_GROUP_HEADER = BUTTON_TYPE_GROUP_HEADER
