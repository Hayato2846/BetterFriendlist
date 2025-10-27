-- BetterFriendlist.lua
-- A friends list replacement for World of Warcraft with Battle.net support
-- Version 0.1

local ADDON_VERSION = "0.1"

-- Define color constants if they don't exist (used by Recent Allies)
-- Note: Blizzard uses FRIENDS_OFFLINE_BACKGROUND_COLOR (with S), not FRIEND_OFFLINE_BACKGROUND_COLOR
if not FRIENDS_WOW_BACKGROUND_COLOR then
	FRIENDS_WOW_BACKGROUND_COLOR = CreateColor(0.101961, 0.149020, 0.196078, 1)
end
if not FRIENDS_OFFLINE_BACKGROUND_COLOR then
	FRIENDS_OFFLINE_BACKGROUND_COLOR = CreateColor(0.35, 0.35, 0.35, 1)
end

local NUM_BUTTONS = 12
local friendsList = {}
local displayList = {} -- Flat list with groups and friends for display

-- Button pool for managing different button types
local buttonPool = {
	friendButtons = {},  -- Pool of friend buttons
	headerButtons = {},  -- Pool of header buttons
	activeButtons = {}   -- Currently visible buttons in order
}

-- Drag and drop state
local currentDraggedFriend = nil -- Stores the name of the friend being dragged

-- Performance optimization: Throttle updates to prevent lag
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1 -- Only update every 0.1 seconds maximum
local pendingUpdate = false

-- Sort mode tracking
local currentSortMode = "status" -- Default: status, name, level, zone

-- Button types
local BUTTON_TYPE_GROUP_HEADER = "group_header"
local BUTTON_TYPE_FRIEND = "friend"

-- Animation helper functions
local function CreatePulseAnimation(frame)
	if not frame.pulseAnim then
		local animGroup = frame:CreateAnimationGroup()
		
		local scale1 = animGroup:CreateAnimation("Scale")
		scale1:SetScale(1.1, 1.1)
		scale1:SetDuration(0.15)
		scale1:SetOrder(1)
		
		local scale2 = animGroup:CreateAnimation("Scale")
		scale2:SetScale(0.909, 0.909) -- Back to 1.0 (1/1.1)
		scale2:SetDuration(0.15)
		scale2:SetOrder(2)
		
		frame.pulseAnim = animGroup
	end
	return frame.pulseAnim
end

local function CreateFadeOutAnimation(frame, onFinished)
	if not frame.fadeOutAnim then
		local animGroup = frame:CreateAnimationGroup()
		
		local alpha = animGroup:CreateAnimation("Alpha")
		alpha:SetFromAlpha(1.0)
		alpha:SetToAlpha(0.0)
		alpha:SetDuration(0.3)
		alpha:SetSmoothing("OUT")
		
		animGroup:SetScript("OnFinished", onFinished)
		
		frame.fadeOutAnim = animGroup
	end
	return frame.fadeOutAnim
end

-- Friend Groups
local friendGroups = {
	favorites = {
		id = "favorites",
		name = "Favorites",
		collapsed = false,
		builtin = true,
		order = 1,
		color = {r = 1.0, g = 0.82, b = 0.0}, -- Gold
		icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon"
	},
	nogroup = {
		id = "nogroup",
		name = "No Group",
		collapsed = false,
		builtin = true,
		order = 999,
		color = {r = 0.5, g = 0.5, b = 0.5}, -- Gray
		icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
	}
}

-- Saved variables (initialized on ADDON_LOADED)
BetterFriendlistDB = BetterFriendlistDB or {}

-- Invite restriction constants (matching Blizzard's)
local INVITE_RESTRICTION_NONE = 0
local INVITE_RESTRICTION_LEADER = 1
local INVITE_RESTRICTION_FACTION = 2
local INVITE_RESTRICTION_REALM = 3
local INVITE_RESTRICTION_INFO = 4
local INVITE_RESTRICTION_CLIENT = 5
local INVITE_RESTRICTION_WOW_PROJECT_ID = 6
local INVITE_RESTRICTION_WOW_PROJECT_MAINLINE = 7
local INVITE_RESTRICTION_WOW_PROJECT_CLASSIC = 8
local INVITE_RESTRICTION_MOBILE = 9
local INVITE_RESTRICTION_REGION = 10
local INVITE_RESTRICTION_QUEST_SESSION = 11
local INVITE_RESTRICTION_NO_GAME_ACCOUNTS = 12

-- Helper function to get last online text (from Blizzard's FriendsFrame)
local function GetLastOnlineTime(timeDifference)
	if not timeDifference then
		timeDifference = 0
	end
	
	timeDifference = time() - timeDifference
	
	if timeDifference < 60 then
		return LASTONLINE_SECS
	elseif timeDifference >= 60 and timeDifference < 3600 then
		return string.format(LASTONLINE_MINUTES, math.floor(timeDifference / 60))
	elseif timeDifference >= 3600 and timeDifference < 86400 then
		return string.format(LASTONLINE_HOURS, math.floor(timeDifference / 3600))
	elseif timeDifference >= 86400 and timeDifference < 2592000 then
		return string.format(LASTONLINE_DAYS, math.floor(timeDifference / 86400))
	elseif timeDifference >= 2592000 and timeDifference < 31536000 then
		return string.format(LASTONLINE_MONTHS, math.floor(timeDifference / 2592000))
	else
		return string.format(LASTONLINE_YEARS, math.floor(timeDifference / 31536000))
	end
end

local function GetLastOnlineText(accountInfo)
	if not accountInfo or not accountInfo.lastOnlineTime or accountInfo.lastOnlineTime == 0 then
		return FRIENDS_LIST_OFFLINE
	else
		return string.format(BNET_LAST_ONLINE_TIME, GetLastOnlineTime(accountInfo.lastOnlineTime))
	end
end

-- Search filter
local searchText = ""

-- Initialize the addon
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("FRIENDLIST_UPDATE")
frame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SOCIAL_QUEUE_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("WHO_LIST_UPDATE")

-- Update the friends list data (both WoW and Battle.net friends)
local function UpdateFriendsList()
	-- Don't call C_FriendList.ShowFriends() here - it triggers FRIENDLIST_UPDATE events
	-- which creates an infinite loop. The events already tell us when to update.
	
	wipe(friendsList)
	
	-- Add Battle.net friends
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	for i = 1, numBNetTotal do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local friend = {
				type = "bnet",
				index = i,  -- Store the BNet friend list index
				bnetAccountID = accountInfo.bnetAccountID,
				-- WoW API returns "???" for hidden account names, treat it as nil
				accountName = (accountInfo.accountName ~= "???") and accountInfo.accountName or nil,
				battleTag = accountInfo.battleTag,
				connected = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline or false,
				note = accountInfo.note,
				isFavorite = accountInfo.isFavorite,
				gameAccountInfo = accountInfo.gameAccountInfo, -- Store game info for icon display
				lastOnlineTime = accountInfo.lastOnlineTime, -- Store for "last online" display
			}
			
		-- If they're playing WoW, get game info
		if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
			local gameInfo = accountInfo.gameAccountInfo
			if gameInfo.clientProgram == "WoW" or gameInfo.clientProgram == "WTCG" then
				friend.characterName = gameInfo.characterName
				friend.className = gameInfo.className
				friend.areaName = gameInfo.areaName
				friend.level = gameInfo.characterLevel
				friend.realmName = gameInfo.realmName
				friend.factionName = gameInfo.factionName
				friend.timerunningSeasonID = gameInfo.timerunningSeasonID -- Store Timerunning season for Remix icon
			elseif gameInfo.clientProgram == "BSAp" then
				friend.gameName = "Mobile"
			elseif gameInfo.clientProgram == "App" then
				friend.gameName = "In App"
			else
				friend.gameName = gameInfo.clientProgram or "Unknown Game"
			end
		end			table.insert(friendsList, friend)
		end
	end
	
	-- Add WoW friends
	local numFriends = C_FriendList.GetNumFriends()
	for i = 1, numFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo then
			local friend = {
				type = "wow",
				index = i,  -- Store the index for tooltip lookup
				name = friendInfo.name,
				connected = friendInfo.connected,
				level = friendInfo.level,
				className = friendInfo.className,
				area = friendInfo.area,
				notes = friendInfo.notes,
			}
			table.insert(friendsList, friend)
		end
	end
	
	-- Filter by search text if provided
	if searchText and searchText ~= "" then
		local filteredList = {}
		for _, friend in ipairs(friendsList) do
			local searchIn = ""
			
			if friend.type == "bnet" then
				-- Search in Battle.net: BattleTag, note, and character name
				-- Note: Real ID (accountName) is protected by Blizzard and cannot be accessed
				-- when users hide it. To search by Real ID, add it manually to the friend's note.
				searchIn = (friend.battleTag or ""):lower() .. " " ..
				           (friend.note or ""):lower() .. " " ..
				           (friend.characterName or ""):lower()
			else
				-- Search in WoW friend name and note
				searchIn = (friend.name or ""):lower() .. " " ..
				           (friend.note or ""):lower()
			end
			
			if searchIn:find(searchText, 1, true) then
				table.insert(filteredList, friend)
			end
		end
		friendsList = filteredList
	end
	
	-- Sort based on current sort mode
	table.sort(friendsList, function(a, b)
		if currentSortMode == "status" then
			-- Helper function to get status priority
			-- 0 = online (green), 1 = dnd (red), 2 = away/mobile (yellow), 3 = offline
			local function GetStatusPriority(friend)
				if not friend.connected then
					return 3 -- offline
				end
				
				if friend.type == "bnet" and friend.gameAccountInfo then
					local gameInfo = friend.gameAccountInfo
					-- DND (red) has priority 1
					if gameInfo.isDND then
						return 1
					end
					-- AFK or Mobile (yellow) has priority 2
					if gameInfo.isAFK or gameInfo.clientProgram == "BSAp" then
						return 2
					end
					-- Online (green) has priority 0
					return 0
				end
				
				-- WoW friends who are online
				return 0
			end
			
			local aPriority = GetStatusPriority(a)
			local bPriority = GetStatusPriority(b)
			
			if aPriority ~= bPriority then
				return aPriority < bPriority
			end
			
			-- Same status, sort by name
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif currentSortMode == "name" then
			-- Sort by name only
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif currentSortMode == "level" then
			-- Sort by level (highest first), then by name
			local levelA = a.level or 0
			local levelB = b.level or 0
			if levelA ~= levelB then
				return levelA > levelB
			end
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif currentSortMode == "zone" then
			-- Sort by zone, then by name
			local zoneA = a.areaName or a.area or ""
			local zoneB = b.areaName or b.area or ""
			if zoneA ~= zoneB then
				return zoneA:lower() < zoneB:lower()
			end
			local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
			local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
			return (nameA or ""):lower() < (nameB or ""):lower()
		end
		-- Default fallback
		local nameA = a.type == "bnet" and (a.accountName or a.battleTag) or a.name
		local nameB = b.type == "bnet" and (b.accountName or b.battleTag) or b.name
		return (nameA or ""):lower() < (nameB or ""):lower()
	end)
end

-- Forward declaration for UpdateFriendsDisplay
local UpdateFriendsDisplay

-- Build display list with groups
local function BuildDisplayList()
	wipe(displayList)
	
	-- Separate friends into groups
	local groupedFriends = {
		favorites = {},
		nogroup = {}
	}
	
	-- Initialize custom group tables
	for groupId, groupData in pairs(friendGroups) do
		if not groupData.builtin or groupId == "favorites" or groupId == "nogroup" then
			groupedFriends[groupId] = groupedFriends[groupId] or {}
		end
	end
	
	-- Helper function to get friend unique ID
	local function GetFriendUID(friend)
		if friend.type == "bnet" then
			return "bnet_" .. (friend.bnetAccountID or friend.battleTag or "")
		else
			return "wow_" .. (friend.name or "")
		end
	end
	
	for _, friend in ipairs(friendsList) do
		local isInAnyGroup = false
		local friendUID = GetFriendUID(friend)
		
		-- Check if friend is a favorite (Battle.net only)
		if friend.type == "bnet" and friend.isFavorite then
			table.insert(groupedFriends.favorites, friend)
			isInAnyGroup = true
		end
		
		-- Check for custom groups
		if BetterFriendlistDB.friendGroups[friendUID] then
			for _, groupId in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
				if groupedFriends[groupId] then
					table.insert(groupedFriends[groupId], friend)
					isInAnyGroup = true
				end
			end
		end
		
		-- Only add to "No Group" if friend is not in any other group
		if not isInAnyGroup then
			table.insert(groupedFriends.nogroup, friend)
		end
	end
	
	-- Build display list in order
	local orderedGroups = {}
	for _, groupData in pairs(friendGroups) do
		table.insert(orderedGroups, groupData)
	end
	table.sort(orderedGroups, function(a, b) return a.order < b.order end)
	
	for _, groupData in ipairs(orderedGroups) do
		local groupFriends = groupedFriends[groupData.id]
		
		-- Skip empty groups
		if groupFriends and #groupFriends > 0 then
			-- Add group header
			table.insert(displayList, {
				type = BUTTON_TYPE_GROUP_HEADER,
				groupId = groupData.id,
				name = groupData.name,
				count = #groupFriends,
				collapsed = groupData.collapsed
			})
			
			-- Add friends if not collapsed
			if not groupData.collapsed then
				for _, friend in ipairs(groupFriends) do
					table.insert(displayList, {
						type = BUTTON_TYPE_FRIEND,
						friend = friend,
						groupId = groupData.id
					})
				end
			end
		end
	end
end

-- Button Pool Management Functions
local function GetOrCreateFriendButton(index)
	if not buttonPool.friendButtons[index] then
		local scrollFrame = BetterFriendsFrame.ScrollFrame
		local buttonName = "BetterFriendsFrameScrollFrameButton" .. index
		local button = CreateFrame("Button", buttonName, scrollFrame, "BetterFriendsListButtonTemplate")
		
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
				-- Store friend name for header text updates (check multiple name fields)
				currentDraggedFriend = self.friendData.name or self.friendData.accountName or self.friendData.battleTag or "Unknown"
				
				-- Show drag overlay
				self.dragOverlay:Show()
				self:SetAlpha(0.5)
				
				-- Start dragging (visual feedback only)
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
									local headerText = string.format("|cffffd700Add %s to %s|r", currentDraggedFriend, groupData.name)
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
									local headerText = string.format("|cffffd700%s (%d)|r", groupData.name, memberCount)
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
					local headerText = string.format("|cffffd700%s (%d)|r", groupData.name, memberCount)
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
					BetterFriendsList_ToggleFriendInGroup(friendUID, droppedOnGroup)
					BuildDisplayList()
					UpdateFriendsDisplay()
				end
			end
		end)
		
		buttonPool.friendButtons[index] = button
	end
	return buttonPool.friendButtons[index]
end

local function GetOrCreateHeaderButton(index)
	if not buttonPool.headerButtons[index] then
		local scrollFrame = BetterFriendsFrame.ScrollFrame
		local buttonName = "BetterFriendsFrameScrollFrameHeader" .. index
		local button = CreateFrame("Button", buttonName, scrollFrame, "BetterFriendsGroupHeaderTemplate")
		-- Raise header buttons to ensure they're clickable
		button:SetFrameLevel(scrollFrame:GetFrameLevel() + 2)
		
		-- Create drop target highlight
		local dropHighlight = button:CreateTexture(nil, "BACKGROUND")
		dropHighlight:SetAllPoints()
		dropHighlight:SetColorTexture(0, 1, 0, 0.2)
		dropHighlight:Hide()
		button.dropHighlight = dropHighlight
		
		-- Enable tooltips only (highlight and text update handled by OnUpdate during drag)
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

local function ResetButtonPool()
	-- Hide all buttons (don't clear points, we'll reposition them)
	for _, button in pairs(buttonPool.friendButtons) do
		button:Hide()
	end
	for _, button in pairs(buttonPool.headerButtons) do
		button:Hide()
	end
	
	-- Also hide the original XML-defined buttons (Button1-Button12)
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	for i = 1, NUM_BUTTONS do
		local xmlButton = scrollFrame["Button" .. i]
		if xmlButton then
			xmlButton:Hide()
		end
	end
	
	wipe(buttonPool.activeButtons)
end

local function GetButtonForDisplay(index, buttonType)
	-- Get or create the appropriate button type
	local button
	if buttonType == BUTTON_TYPE_GROUP_HEADER then
		button = GetOrCreateHeaderButton(index)
	else
		button = GetOrCreateFriendButton(index)
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

-- Toggle group collapsed state
function BetterFriendsList_ToggleGroup(groupId)
	if friendGroups[groupId] then
		friendGroups[groupId].collapsed = not friendGroups[groupId].collapsed
		
		-- Save to database
		BetterFriendlistDB.groupStates = BetterFriendlistDB.groupStates or {}
		BetterFriendlistDB.groupStates[groupId] = friendGroups[groupId].collapsed
		
		-- Rebuild and update display
		BuildDisplayList()
		UpdateFriendsDisplay()
	end
end

-- Create a new custom group
function BetterFriendsList_CreateGroup(groupName)
	if not groupName or groupName == "" then
		return false, "Group name cannot be empty"
	end
	
	-- Generate unique ID from name
	local groupId = "custom_" .. groupName:gsub("%s+", "_"):lower()
	
	-- Check if group already exists
	if friendGroups[groupId] then
		return false, "Group already exists"
	end
	
	-- Find next order value (place custom groups between Favorites and No Group)
	local maxOrder = 1
	for _, groupData in pairs(friendGroups) do
		if not groupData.builtin or groupData.id == "favorites" then
			maxOrder = math.max(maxOrder, groupData.order or 1)
		end
	end
	
	-- Create group
	friendGroups[groupId] = {
		id = groupId,
		name = groupName,
		collapsed = false,
		builtin = false,
		order = maxOrder + 1,
		color = {r = 0, g = 0.7, b = 1.0}, -- Default blue for custom groups
		icon = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"
	}
	
	-- Save to database
	BetterFriendlistDB.customGroups = BetterFriendlistDB.customGroups or {}
	BetterFriendlistDB.customGroups[groupId] = {
		name = groupName,
		collapsed = false,
		order = maxOrder + 1
	}
	
	-- Rebuild display
	BuildDisplayList()
	UpdateFriendsDisplay()
	
	-- Play pulse animation on the newly created group header
	C_Timer.After(0.1, function()
		for _, button in pairs(buttonPool.headerButtons) do
			if button:IsVisible() and button.groupId == groupId then
				CreatePulseAnimation(button):Play()
				break
			end
		end
	end)
	
	return true, groupId
end

-- Helper function to get friend unique ID (global for use in multiple places)
function GetFriendUID(friend)
	if not friend then return nil end
	if friend.type == "bnet" then
		return "bnet_" .. (friend.bnetAccountID or friend.battleTag or "")
	else
		return "wow_" .. (friend.name or "")
	end
end

-- Add or remove friend from group
function BetterFriendsList_ToggleFriendInGroup(friendUID, groupId)
	if not friendUID or not groupId then
		return false
	end
	
	-- Don't allow adding to builtin groups (except they're managed automatically)
	if friendGroups[groupId] and friendGroups[groupId].builtin then
		return false
	end
	
	-- Initialize friendGroups in DB
	BetterFriendlistDB.friendGroups = BetterFriendlistDB.friendGroups or {}
	BetterFriendlistDB.friendGroups[friendUID] = BetterFriendlistDB.friendGroups[friendUID] or {}
	
	local groups = BetterFriendlistDB.friendGroups[friendUID]
	
	-- Check if friend is already in group
	local isInGroup = false
	local indexToRemove = nil
	for i, gid in ipairs(groups) do
		if gid == groupId then
			isInGroup = true
			indexToRemove = i
			break
		end
	end
	
	-- Toggle membership
	if isInGroup then
		-- Remove from group
		table.remove(groups, indexToRemove)
	else
		-- Add to group
		table.insert(groups, groupId)
	end
	
	-- Rebuild display
	BuildDisplayList()
	UpdateFriendsDisplay()
	
	return true
end

-- Check if friend is in a specific group
function BetterFriendsList_IsFriendInGroup(friendUID, groupId)
	if not BetterFriendlistDB.friendGroups or not BetterFriendlistDB.friendGroups[friendUID] then
		return false
	end
	
	for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
		if gid == groupId then
			return true
		end
	end
	
	return false
end

-- Rename a custom group
function BetterFriendsList_RenameGroup(groupId, newName)
	if not groupId or not newName or newName == "" then
		return false, "Invalid group name"
	end
	
	local group = friendGroups[groupId]
	if not group then
		return false, "Group does not exist"
	end
	
	if group.builtin then
		return false, "Cannot rename built-in groups"
	end
	
	-- Update in memory
	group.name = newName
	
	-- Update in database
	if BetterFriendlistDB.customGroups and BetterFriendlistDB.customGroups[groupId] then
		BetterFriendlistDB.customGroups[groupId].name = newName
	end
	
	-- Rebuild display
	BuildDisplayList()
	UpdateFriendsDisplay()
	
	return true
end

-- Delete a custom group
function BetterFriendsList_DeleteGroup(groupId)
	if not groupId then
		return false, "Invalid group ID"
	end
	
	local group = friendGroups[groupId]
	if not group then
		return false, "Group does not exist"
	end
	
	if group.builtin then
		return false, "Cannot delete built-in groups"
	end
	
	-- Remove from memory
	friendGroups[groupId] = nil
	
	-- Remove from database
	if BetterFriendlistDB.customGroups then
		BetterFriendlistDB.customGroups[groupId] = nil
	end
	
	-- Remove all friend assignments to this group
	if BetterFriendlistDB.friendGroups then
		for friendUID, groups in pairs(BetterFriendlistDB.friendGroups) do
			for i = #groups, 1, -1 do
				if groups[i] == groupId then
					table.remove(groups, i)
				end
			end
			-- Clean up empty entries
			if #groups == 0 then
				BetterFriendlistDB.friendGroups[friendUID] = nil
			end
		end
	end
	
	-- Rebuild display
	BuildDisplayList()
	UpdateFriendsDisplay()
	
	return true
end

-- Remove friend from a specific group
function BetterFriendsList_RemoveFriendFromGroup(friendUID, groupId)
	if not friendUID or not groupId then
		return false
	end
	
	if not BetterFriendlistDB.friendGroups or not BetterFriendlistDB.friendGroups[friendUID] then
		return false
	end
	
	local groups = BetterFriendlistDB.friendGroups[friendUID]
	for i = #groups, 1, -1 do
		if groups[i] == groupId then
			table.remove(groups, i)
			
			-- Clean up if no groups left
			if #groups == 0 then
				BetterFriendlistDB.friendGroups[friendUID] = nil
			end
			
			-- Rebuild display
			BuildDisplayList()
			UpdateFriendsDisplay()
			return true
		end
	end
	
	return false
end

-- Helper function to get displayList count (used by XML mouse wheel handler)
function BetterFriendsFrame_GetDisplayListCount()
	return #displayList
end

-- Update the UI display (Two-line layout with groups)
UpdateFriendsDisplay = function()
	-- Skip update if frame is not shown (performance optimization)
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		return
	end
	
	-- Skip update if Friends list elements are hidden (means we're on another tab)
	if BetterFriendsFrame.ScrollFrame and not BetterFriendsFrame.ScrollFrame:IsShown() then
		return
	end
	
	-- Skip update if we're not on the Friends tab (tab 1)
	-- This prevents the Sort panel from being closed when friend list updates
	if BetterFriendsFrame.FriendsTabHeader then
		local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		if selectedTab and selectedTab ~= 1 then
			return
		end
	end
	
	-- Build display list from friends list
	BuildDisplayList()
	
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	local numItems = #displayList  -- Use displayList instead of friendsList
	
	-- Calculate the maximum valid offset
	local maxOffset = math.max(0, numItems - NUM_BUTTONS)
	
	-- Update scroll frame - use average height for mixed button types (headers=22px, friends=34px)
	-- Using 28px as a reasonable middle ground for scroll calculations
	-- ONLY call FauxScrollFrame_Update if we're not in a mouse wheel update
	local buttonHeight = 28
	
	if not BetterFriendsFrame.inMouseWheelUpdate then
		FauxScrollFrame_Update(scrollFrame, numItems, NUM_BUTTONS, buttonHeight)
	end
	
	-- FauxScrollFrame_Update can hide the scrollFrame when numItems <= NUM_BUTTONS
	-- We want it always visible, so force it to show
	scrollFrame:Show()
	
	-- Update MinimalScrollBar to match (uses percentage-based system)
	if BetterFriendsFrame.MinimalScrollBar then
		local scrollBar = BetterFriendsFrame.MinimalScrollBar
		
		-- Set the visible extent percentage (how much of the content is visible)
		if numItems > 0 then
			local visibleExtent = NUM_BUTTONS / numItems
			scrollBar:SetVisibleExtentPercentage(visibleExtent)
		end
		
		-- Only update scroll position if we're not already in a callback
		-- This prevents infinite recursion: SetScrollPercentage -> OnScroll callback -> UpdateDisplay -> SetScrollPercentage...
		local isInCallback = BetterFriendsFrame.isUpdatingScrollFromCallback and BetterFriendsFrame.isUpdatingScrollFromCallback()
		if not isInCallback and not BetterFriendsFrame.inMouseWheelUpdate then
			-- Update scroll position
			if maxOffset > 0 then
				local currentOffset = FauxScrollFrame_GetOffset(scrollFrame)
				currentOffset = math.max(0, math.min(currentOffset, maxOffset))
				local scrollPercentage = currentOffset / maxOffset
				scrollBar:SetScrollPercentage(scrollPercentage)
			else
				scrollBar:SetScrollPercentage(0)
			end
		end
	end
	
	-- Get offset and clamp it to valid range (ensure it's at least 0)
	local offset = FauxScrollFrame_GetOffset(scrollFrame)
	offset = math.max(0, math.min(offset, maxOffset))
	
	-- Reset button pool for this frame
	ResetButtonPool()
	
	-- Render visible buttons using button pool
	-- We need to fill the available height (418px) with mixed button heights
	-- Headers: 22px, Friends: 34px
	local SCROLL_FRAME_HEIGHT = 418
	local HEADER_HEIGHT = 22
	local FRIEND_HEIGHT = 34
	local BUTTON_SPACING = 1
	local TOP_PADDING = 3
	
	local currentHeight = TOP_PADDING
	local buttonsRendered = 0
	
	-- Keep rendering buttons until we fill the available height or run out of items
	for i = 1, math.min(numItems, 20) do  -- Max 20 buttons as safety limit
		local index = offset + i
		
		if index > numItems then
			break
		end
		
		local item = displayList[index]
		local buttonHeight = (item.type == BUTTON_TYPE_GROUP_HEADER) and HEADER_HEIGHT or FRIEND_HEIGHT
		
		-- Check if this button would fit in the remaining space
		-- Allow partial visibility of last button (at least 10px visible)
		if currentHeight + buttonHeight > SCROLL_FRAME_HEIGHT + 24 then
			break
		end
		
		buttonsRendered = buttonsRendered + 1
		local button = GetButtonForDisplay(buttonsRendered, item.type)
		button:Show()
		
		currentHeight = currentHeight + buttonHeight + BUTTON_SPACING
		
		if item.type == BUTTON_TYPE_GROUP_HEADER then
			-- Configure group header button
			button.groupId = item.groupId
			
			-- Set text in gold (standard WoW header color)
			button:SetText(string.format("|cffffd700%s (%d)|r", item.name, item.count))
			
			-- Show/hide arrows based on collapsed state
			if item.collapsed then
				button.RightArrow:Show()
				button.DownArrow:Hide()
			else
				button.RightArrow:Hide()
				button.DownArrow:Show()
			end
			
			-- Add right-click menu for custom groups
			if friendGroups[item.groupId] and not friendGroups[item.groupId].builtin then
				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:SetScript("OnClick", function(self, buttonName)
					if buttonName == "RightButton" then
						-- Open context menu for group header
						MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
							rootDescription:CreateTitle(friendGroups[self.groupId].name)
							
							rootDescription:CreateButton("Rename Group", function()
								StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
							end)
							
							rootDescription:CreateButton("Delete Group", function()
								StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, self.groupId)
							end)
							
							rootDescription:CreateDivider()
							
							rootDescription:CreateButton("Collapse All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = true
									BetterFriendlistDB.groupStates[gid] = true
								end
								BuildDisplayList()
								UpdateFriendsDisplay()
							end)
							
							rootDescription:CreateButton("Expand All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = false
									BetterFriendlistDB.groupStates[gid] = false
								end
								BuildDisplayList()
								UpdateFriendsDisplay()
							end)
						end)
					else
						-- Left click: toggle collapse
						BetterFriendsList_ToggleGroup(self.groupId)
					end
				end)
			else
				-- Built-in groups: Rechtsklick für Collapse/Expand All
				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:SetScript("OnClick", function(self, buttonName)
					if buttonName == "RightButton" then
						-- Open context menu for built-in group header
						MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
							rootDescription:CreateTitle(friendGroups[self.groupId].name)
							
							rootDescription:CreateButton("Collapse All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = true
									BetterFriendlistDB.groupStates[gid] = true
								end
								BuildDisplayList()
								UpdateFriendsDisplay()
							end)
							
							rootDescription:CreateButton("Expand All Groups", function()
								for gid, gdata in pairs(friendGroups) do
									gdata.collapsed = false
									BetterFriendlistDB.groupStates[gid] = false
								end
								BuildDisplayList()
								UpdateFriendsDisplay()
							end)
						end)
					else
						-- Left click: toggle collapse
						BetterFriendsList_ToggleGroup(self.groupId)
					end
				end)
			end
			
		elseif item.type == BUTTON_TYPE_FRIEND then
			-- Configure friend button
			local friend = item.friend
			
			-- Store friend data on button for tooltip
			button.friendIndex = friend.index  -- Use the actual friend list index, not display index
			button.friendData = friend
			button.groupId = nil
			
			-- Store friendInfo for context menu (matches our OnClick handler)
			button.friendInfo = {
				type = friend.type,
				index = friend.index,  -- Use the actual friend list index
				name = friend.name or friend.accountName or friend.battleTag,
				connected = friend.connected,
				guid = friend.guid,
				bnetAccountID = friend.bnetAccountID,
				battleTag = friend.battleTag
			}
			
			-- Hide arrows if they exist
			if button.RightArrow then button.RightArrow:Hide() end
			if button.DownArrow then button.DownArrow:Hide() end				-- Reset name position
				button.Name:SetPoint("LEFT", 44, 7)
				button.Name:SetTextColor(1, 1, 1) -- White
				
				-- Show friend elements
				button.status:Show()
				button.Info:Show()
				
				if friend.type == "bnet" then
				-- Battle.net friend
				local displayName = friend.accountName or friend.battleTag or "Unknown"
				
				-- Set background color
				if friend.connected then
					button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
				else
					button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
				end
				
				-- Set status icon (BSAp shows as AFK)
				if friend.connected then
					if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp" then
						button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Away")
					else
						button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
					end
				else
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
				end
				
			-- Set game icon using Blizzard's modern API
			if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram and friend.connected then
				local clientProgram = friend.gameAccountInfo.clientProgram
				
				-- Use Blizzard's modern texture API (11.0+) for ALL client programs including Battle.net App
				C_Texture.SetTitleIconTexture(button.gameIcon, clientProgram, Enum.TitleIconVersion.Medium)
				
				-- Fade icon for WoW friends on different project versions
				local fadeIcon = (clientProgram == BNET_CLIENT_WOW) and (friend.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID)
				if fadeIcon then
					button.gameIcon:SetAlpha(0.6)
				else
					button.gameIcon:SetAlpha(1)
				end
				
				button.gameIcon:Show()
			else
				button.gameIcon:Hide()
			end				-- Handle TravelPass button for Battle.net friends
				if button.travelPassButton then
					-- Show for ALL online Battle.net friends (matching Blizzard's behavior)
					if friend.connected then
						-- Store friend index for click handler
						button.travelPassButton.friendIndex = index
						button.travelPassButton.friendData = friend
						
						-- Get the actual Battle.net friend index for restriction checking
						local numBNet = BNGetNumFriends()
						local actualBNetIndex = nil
						for i = 1, numBNet do
							local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
							if accountInfo and accountInfo.bnetAccountID == friend.bnetAccountID then
								actualBNetIndex = i
								break
							end
						end
						
						-- Calculate invite restriction (matching Blizzard's logic)
						local restriction = nil  -- Will be set to NO_GAME_ACCOUNTS if no valid accounts found
						if actualBNetIndex then
							local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualBNetIndex)
							
							for i = 1, numGameAccounts do
								local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualBNetIndex, i)
								if gameAccountInfo then
									if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
										-- Check WoW version compatibility
										if gameAccountInfo.wowProjectID and WOW_PROJECT_ID then
											if gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
												-- Friend is on Classic, we're not
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_CLASSIC
												end
											elseif gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
												-- Friend is on Mainline, we're not
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_MAINLINE
												end
											elseif gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
												-- Different WoW version (other)
												if not restriction then
													restriction = INVITE_RESTRICTION_WOW_PROJECT_ID
												end
											elseif gameAccountInfo.realmID == 0 then
												-- No realm info
												if not restriction then
													restriction = INVITE_RESTRICTION_INFO
												end
											elseif not gameAccountInfo.isInCurrentRegion then
												-- Different region
												restriction = INVITE_RESTRICTION_REGION
											else
												-- At least one valid WoW account that can be invited
												restriction = INVITE_RESTRICTION_NONE
												break
											end
										elseif gameAccountInfo.realmID == 0 then
											-- No realm info
											if not restriction then
												restriction = INVITE_RESTRICTION_INFO
											end
										elseif not gameAccountInfo.isInCurrentRegion then
											-- Different region
											restriction = INVITE_RESTRICTION_REGION
										elseif gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
											-- Valid WoW account (no project ID check needed)
											restriction = INVITE_RESTRICTION_NONE
											break
										end
									else
										-- Non-WoW client (App, BSAp, etc.)
										if not restriction then
											restriction = INVITE_RESTRICTION_CLIENT
										end
									end
								end
							end
						end
						
						-- If no restriction was set, means no game accounts at all
						if not restriction then
							restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
						end
						
						-- Enable/disable button based on restriction
						if restriction == INVITE_RESTRICTION_NONE then
							button.travelPassButton:Enable()
						else
							button.travelPassButton:Disable()
						end
						
						-- Set atlas based on faction for cross-faction invites
						local playerFactionGroup = UnitFactionGroup("player")
						local isCrossFaction = friend.gameAccountInfo and
											   friend.gameAccountInfo.factionName and 
											   friend.gameAccountInfo.factionName ~= playerFactionGroup
						
						if isCrossFaction then
							if friend.gameAccountInfo.factionName == "Horde" then
								button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-horde-normal")
								button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-horde-pressed")
								button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-horde-disabled")
							elseif friend.gameAccountInfo.factionName == "Alliance" then
								button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-alliance-normal")
								button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-alliance-pressed")
								button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-alliance-disabled")
							end
						else
							button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-default-normal")
							button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-default-pressed")
							button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-default-disabled")
						end
						
						button.travelPassButton:Show()
					else
						button.travelPassButton:Hide()
					end
				end
				
			-- Line 1: BattleNet Name (CharacterName)
			-- BattleNet Name in blue/cyan Battle.net color, CharacterName in class color
			local line1Text = ""
			if friend.connected then
				-- Use Battle.net blue color for the account name
				line1Text = "|cff00ccff" .. displayName .. "|r"
				
				if friend.characterName and friend.className then
					-- Add Timerunning icon if applicable
					local characterName = friend.characterName
					if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
						characterName = TimerunningUtil.AddSmallIcon(characterName)
					end
					
					-- Convert localized class name to English uppercase key for RAID_CLASS_COLORS
					local classFile = nil
					for i = 1, GetNumClasses() do
						local localizedClassName, classFilename = GetClassInfo(i)
						if localizedClassName == friend.className then
							classFile = classFilename
							break
						end
					end
					
					-- Get class color using the English file name
					local classColor = classFile and RAID_CLASS_COLORS[classFile]
					
					if classColor then
						line1Text = line1Text .. " (|c" .. (classColor.colorStr or "ffffffff") .. characterName .. "|r)"
					else
						line1Text = line1Text .. " (" .. characterName .. ")"
					end
				end
			else
				-- Offline - use gray
				line1Text = "|cff7f7f7f" .. displayName .. "|r"
			end				button.Name:SetText(line1Text)
				
				-- Line 2: Level, Zone (in gray)
				if friend.connected then
					if friend.level and friend.areaName then
						button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.areaName))
					elseif friend.level then
						button.Info:SetText("Lvl " .. friend.level)
					elseif friend.areaName then
						button.Info:SetText(friend.areaName)
					elseif friend.gameName then
						-- Show "Mobile" or "In App" without "Playing" prefix
						button.Info:SetText(friend.gameName)
					else
						button.Info:SetText("Online")
					end
				else
					-- Offline - show last online time for Battle.net friends
					if friend.lastOnlineTime then
						button.Info:SetText(GetLastOnlineText(friend))
					else
						button.Info:SetText("Offline")
					end
				end
			else
				-- WoW friend
				-- Set background color
				if friend.connected then
					button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a)
				else
					button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
				end
				
				-- Set status icon
				if friend.connected then
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
				else
					button.status:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
				end
				
				button.gameIcon:Hide()
				
				-- Hide TravelPass button for WoW friends (they don't have it)
				if button.travelPassButton then
					button.travelPassButton:Hide()
				end
				
				-- Line 1: Character Name (in class color)
				local line1Text = ""
				if friend.connected then
					local classColor = RAID_CLASS_COLORS[friend.className]
					if classColor then
						line1Text = "|c" .. (classColor.colorStr or "ffffffff") .. friend.name .. "|r"
					else
						line1Text = friend.name
					end
				else
					-- Offline - gray
					line1Text = "|cff7f7f7f" .. friend.name .. "|r"
				end
				
				button.Name:SetText(line1Text)
				
				-- Line 2: Level, Zone (in gray)
				if friend.connected then
					if friend.level and friend.area then
						button.Info:SetText(string.format("Lvl %d, %s", friend.level, friend.area))
					elseif friend.level then
						button.Info:SetText("Lvl " .. friend.level)
					elseif friend.area then
						button.Info:SetText(friend.area)
					else
						button.Info:SetText("Online")
					end
				else
					button.Info:SetText("Offline")
				end
			end -- end of if friend.type == "bnet"
			
		end -- end of elseif item.type == BUTTON_TYPE_FRIEND
	end -- end of for loop
	
	-- Update status text
	-- Update status text removed - we'll show this in group headers instead
end

-- Throttled update function to batch rapid events
local function RequestUpdate()
	local currentTime = GetTime()
	
	-- If enough time has passed, update immediately
	if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
		lastUpdateTime = currentTime
		pendingUpdate = false
		UpdateFriendsList()
		UpdateFriendsDisplay()
	else
		-- Otherwise, schedule a delayed update
		if not pendingUpdate then
			pendingUpdate = true
			C_Timer.After(UPDATE_THROTTLE, function()
				if pendingUpdate and BetterFriendsFrame and BetterFriendsFrame:IsShown() then
					lastUpdateTime = GetTime()
					pendingUpdate = false
					UpdateFriendsList()
					UpdateFriendsDisplay()
				end
			end)
		end
	end
end

-- Global function for getting friends list (called from XML)
function BetterFriendlist_GetFriendsList()
	return friendsList
end

-- Global function for updating the display (called from XML)
function BetterFriendsFrame_UpdateDisplay()
	UpdateFriendsDisplay()
end

-- Handle search box text changes (called from XML)
function BetterFriendsFrame_OnSearchTextChanged(editBox)
	local text = editBox:GetText()
	if text then
		searchText = text:lower()
		
		-- Update immediately - filtering happens in UpdateFriendsList
		-- No need to throttle, RequestUpdate will handle that
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			RequestUpdate()
		end
	end
end

-- Show the friends frame
function ShowBetterFriendsFrame()
	-- Clear search box
	if BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.SearchBox then
		BetterFriendsFrame.FriendsTabHeader.SearchBox:SetText("")
		searchText = ""
	end
	
	UpdateFriendsList()
	UpdateFriendsDisplay()
	BetterFriendsFrame:Show()
end

-- Hide the friends frame  
function HideBetterFriendsFrame()
	BetterFriendsFrame:Hide()
end

-- Toggle the friends frame
function ToggleBetterFriendsFrame()
	if BetterFriendsFrame:IsShown() then
		HideBetterFriendsFrame()
	else
		ShowBetterFriendsFrame()
	end
end

--------------------------------------------------------------------------
-- STATIC POPUP DIALOGS
--------------------------------------------------------------------------

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

--------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == "BetterFriendlist" then
			print("|cff00ff00BetterFriendlist v" .. ADDON_VERSION .. "|r loaded successfully!")
			
			-- Initialize saved variables
			BetterFriendlistDB = BetterFriendlistDB or {}
			BetterFriendlistDB.groupStates = BetterFriendlistDB.groupStates or {}
			BetterFriendlistDB.customGroups = BetterFriendlistDB.customGroups or {}
			BetterFriendlistDB.friendGroups = BetterFriendlistDB.friendGroups or {}
			
			-- Load custom groups from DB
			for groupId, groupInfo in pairs(BetterFriendlistDB.customGroups) do
				if not friendGroups[groupId] then
					friendGroups[groupId] = {
						id = groupId,
						name = groupInfo.name,
						collapsed = groupInfo.collapsed or false,
						builtin = false,
						order = groupInfo.order or 50
					}
				end
			end
			
			-- Load collapsed states
			for groupId, groupData in pairs(friendGroups) do
				if BetterFriendlistDB.groupStates[groupId] ~= nil then
					groupData.collapsed = BetterFriendlistDB.groupStates[groupId]
				end
			end
			
		-- Register frame to close on Escape key (like Blizzard's FriendsFrame)
		table.insert(UISpecialFrames, "BetterFriendsFrame")
		
		-- For WoW 11.2: Use Menu.ModifyMenu with correct MENU_UNIT_* tags
		-- According to https://warcraft.wiki.gg/wiki/Blizzard_Menu_implementation_guide
		-- UnitPopup menus use "MENU_UNIT_<UNIT_TYPE>" format
		
		local function AddGroupsToFriendMenu(owner, rootDescription, contextData)
			-- contextData contains bnetIDAccount or name
			if not contextData then
				return
			end
			
			-- Determine friendUID from contextData
			local friendUID
			if contextData.bnetIDAccount then
				friendUID = "bnet_" .. contextData.bnetIDAccount
			elseif contextData.name then
				friendUID = "wow_" .. contextData.name
			end
			
			if not friendUID then
				return
			end
			
			-- Check if this friend is in any custom group
			local friendCurrentGroups = {}
			if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
				for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
					friendCurrentGroups[gid] = true
				end
			end
			
			-- Add divider and Groups submenu
			rootDescription:CreateDivider()
			local groupsButton = rootDescription:CreateButton("Groups")
			
			-- Add "Create Group" option at the top
			groupsButton:CreateButton("Create Group", function()
				StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND", nil, nil, friendUID)
			end)
			
			-- Count custom groups
			local customGroupCount = 0
			for groupId, groupData in pairs(friendGroups) do
				if not groupData.builtin then
					customGroupCount = customGroupCount + 1
				end
			end
			
			-- Add divider if there are custom groups
			if customGroupCount > 0 then
				groupsButton:CreateDivider()
				
				-- Add checkbox for each custom group
				for groupId, groupData in pairs(friendGroups) do
					if not groupData.builtin then
						groupsButton:CreateCheckbox(
							groupData.name,
							function() return BetterFriendsList_IsFriendInGroup(friendUID, groupId) end,
							function()
								BetterFriendsList_ToggleFriendInGroup(friendUID, groupId)
								BetterFriendsFrame_UpdateDisplay()
							end
						)
					end
				end
				
				-- Add "Remove from All Groups" if friend is in custom groups
				if next(friendCurrentGroups) then
					groupsButton:CreateDivider()
					
					-- Add "Remove from All Groups" button
					groupsButton:CreateButton("Remove from All Groups", function()
						for currentGroupId in pairs(friendCurrentGroups) do
							BetterFriendsList_RemoveFriendFromGroup(friendUID, currentGroupId)
						end
						BetterFriendsFrame_UpdateDisplay()
					end)
				end
			end
		end
		
		-- Register for BattleNet friend menus (online and offline)
		if Menu and Menu.ModifyMenu then
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_BN_FRIEND_OFFLINE", AddGroupsToFriendMenu)
			
			-- Register for WoW friend menus (online and offline)
			Menu.ModifyMenu("MENU_UNIT_FRIEND", AddGroupsToFriendMenu)
			Menu.ModifyMenu("MENU_UNIT_FRIEND_OFFLINE", AddGroupsToFriendMenu)
		end
		
		-- DEPRECATED: Old Menu.ModifyMenu code removed (was using wrong tags without MENU_UNIT_ prefix)
		
		-- Setup scroll frame
			if BetterFriendsFrame and BetterFriendsFrame.ScrollFrame then
				BetterFriendsFrame.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
					FauxScrollFrame_OnVerticalScroll(self, offset, 34, UpdateFriendsDisplay)
				end)
			end
			
			-- Setup close button
			if BetterFriendsFrame and BetterFriendsFrame.CloseButton then
				BetterFriendsFrame.CloseButton:SetScript("OnClick", function()
					HideBetterFriendsFrame()
				end)
			end
		end
	elseif event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_LIST_SIZE_CHANGED" or 
	       event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" or
	       event == "BN_FRIEND_INFO_CHANGED" then
		-- Always allow events, but throttle them to prevent spam
		-- The UpdateFriendsList() function will apply search filter automatically
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			RequestUpdate() -- Use throttled update to prevent lag from rapid events
		end
	elseif event == "SOCIAL_QUEUE_UPDATE" or event == "GROUP_LEFT" or event == "GROUP_JOINED" then
		-- Update Quick Join tab counter when social queue changes
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			BetterFriendsFrame_UpdateQuickJoinTab()
		end
	elseif event == "WHO_LIST_UPDATE" then
		-- Update Who list when results are received
		if BetterFriendsFrame and BetterFriendsFrame:IsShown() and BetterFriendsFrame.WhoFrame:IsShown() then
			BetterWhoFrame_Update()
		end
	elseif event == "PLAYER_LOGIN" then
		-- Initialize Battlenet Frame
		InitializeBattlenetFrame()
		
		-- Initialize Status Dropdown
		InitializeStatusDropdown()
		
		-- Initialize Tabs
		InitializeTabs()
		
		-- Initialize Quick Join tab counter
		BetterFriendsFrame_UpdateQuickJoinTab()
		
		-- Hook the default friends frame functions to show ours instead
		-- This makes the 'O' key work
		if ToggleFriendsFrame then
			hooksecurefunc("ToggleFriendsFrame", function(tab)
				-- Hide default frame if it's shown
				if FriendsFrame and FriendsFrame:IsShown() then
					HideUIPanel(FriendsFrame)
				end
				-- Show our frame
				ToggleBetterFriendsFrame()
			end)
		end
	end
end)

-- Initialize Status Dropdown based on Blizzard's implementation
function InitializeStatusDropdown()
	local frame = BetterFriendsFrame
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.StatusDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.StatusDropdown
	
	-- Set up status tracking
	local bnetAFK, bnetDND = select(5, BNGetInfo())
	local bnStatus
	if bnetAFK then
		bnStatus = FRIENDS_TEXTURE_AFK
	elseif bnetDND then
		bnStatus = FRIENDS_TEXTURE_DND
	else
		bnStatus = FRIENDS_TEXTURE_ONLINE
	end
	
	local function IsSelected(status)
		return bnStatus == status
	end
	
	local function SetSelected(status)
		if status ~= bnStatus then
			bnStatus = status
			
			if status == FRIENDS_TEXTURE_ONLINE then
				BNSetAFK(false)
				BNSetDND(false)
			elseif status == FRIENDS_TEXTURE_AFK then
				BNSetAFK(true)
			elseif status == FRIENDS_TEXTURE_DND then
				BNSetDND(true)
			end
		end
	end
	
	local function CreateRadio(rootDescription, text, status)
		local radio = rootDescription:CreateButton(text, function() end, status)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	dropdown:SetWidth(51)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_STATUS")
		
		local optionText = "\124T%s.tga:16:16:0:0\124t %s"
		
		local onlineText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
		CreateRadio(rootDescription, onlineText, FRIENDS_TEXTURE_ONLINE)
		
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
		CreateRadio(rootDescription, afkText, FRIENDS_TEXTURE_AFK)
		
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
		CreateRadio(rootDescription, dndText, FRIENDS_TEXTURE_DND)
	end)
	
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("\124T%s.tga:16:16:0:0\124t", selection.data)
	end)
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		local statusText
		if bnStatus == FRIENDS_TEXTURE_ONLINE then
			statusText = FRIENDS_LIST_AVAILABLE
		elseif bnStatus == FRIENDS_TEXTURE_AFK then
			statusText = FRIENDS_LIST_AWAY
		elseif bnStatus == FRIENDS_TEXTURE_DND then
			statusText = FRIENDS_LIST_BUSY
		end
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		GameTooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, statusText))
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Initialize Sort Dropdown
function InitializeSortDropdown()
	local frame = BetterFriendsFrame
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.SortDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.SortDropdown
	
	local function IsSelected(sortMode)
		return currentSortMode == sortMode
	end
	
	local function SetSelected(sortMode)
		if sortMode ~= currentSortMode then
			currentSortMode = sortMode
			-- Update the display
			UpdateFriendsList()
			UpdateFriendsDisplay()
		end
	end
	
	local function CreateRadio(rootDescription, text, sortMode)
		local radio = rootDescription:CreateButton(text, function() end, sortMode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	dropdown:SetWidth(120)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_SORT")
		
		CreateRadio(rootDescription, "Sort by Status", "status")
		CreateRadio(rootDescription, "Sort by Name", "name")
		CreateRadio(rootDescription, "Sort by Level", "level")
		CreateRadio(rootDescription, "Sort by Zone", "zone")
	end)
	
	dropdown:SetSelectionTranslator(function(selection)
		if selection.data == "status" then
			return "Sort: Status"
		elseif selection.data == "name" then
			return "Sort: Name"
		elseif selection.data == "level" then
			return "Sort: Level"
		elseif selection.data == "zone" then
			return "Sort: Zone"
		end
		return "Sort"
	end)
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Sort Friends List")
		GameTooltip:AddLine("Choose how to sort your friends list", 1, 1, 1)
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Initialize Tabs
function InitializeTabs()
	local frame = BetterFriendsFrame
	if not frame or not frame.FriendsTabHeader then return end
	
	-- Set up the tabs on the FriendsTabHeader (11.2.5: 4 tabs - Friends, Recent Allies, RAF, Sort)
	PanelTemplates_SetNumTabs(frame.FriendsTabHeader, 4)
	PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
	PanelTemplates_UpdateTabs(frame.FriendsTabHeader)
end

-- Show specific tab content (11.2.5: 4 tabs - Friends, Recent Allies, RAF, Sort)
function BetterFriendsFrame_ShowTab(tabIndex)
	local frame = BetterFriendsFrame
	if not frame then return end
	
	-- Hide all frames by default
	if frame.SortFrame then frame.SortFrame:Hide() end
	if frame.RecentAlliesFrame then frame.RecentAlliesFrame:Hide() end
	if frame.RecruitAFriendFrame then frame.RecruitAFriendFrame:Hide() end
	frame.ScrollFrame:Hide()
	if frame.MinimalScrollBar then frame.MinimalScrollBar:Hide() end
	
	-- Hide bottom buttons by default (only show on specific tabs)
	if frame.AddFriendButton then frame.AddFriendButton:Hide() end
	if frame.SendMessageButton then frame.SendMessageButton:Hide() end
	if frame.RecruitmentButton then frame.RecruitmentButton:Hide() end
	
	if tabIndex == 1 then
		-- Show Friends list (11.2.5: CONTACTS/FRIENDS tab)
		frame.ScrollFrame:Show()
		if frame.MinimalScrollBar then frame.MinimalScrollBar:Show() end
		-- Show bottom buttons for Friends list
		if frame.AddFriendButton then frame.AddFriendButton:Show() end
		if frame.SendMessageButton then frame.SendMessageButton:Show() end
		UpdateFriendsDisplay()
	elseif tabIndex == 2 then
		-- Show Recent Allies (11.2.5: new tab replacing Ignore tab)
		if frame.RecentAlliesFrame then
			frame.RecentAlliesFrame:Show()
			BetterRecentAlliesFrame_Update()
		end
	elseif tabIndex == 3 then
		-- Show Recruit A Friend (11.2.5: Complete implementation)
		if frame.RecruitAFriendFrame then
			frame.RecruitAFriendFrame:Show()
			-- Show Recruitment button for RAF tab
			if frame.RecruitmentButton then
				frame.RecruitmentButton:Show()
			end
			
			-- Initialize RAF data (match Blizzard's OnLoad behavior)
			if C_RecruitAFriend and C_RecruitAFriend.IsSystemEnabled then
				-- Ensure Blizzard's RecruitAFriendFrame is loaded and initialized
				if not RecruitAFriendFrame then
					-- Load the addon if not loaded yet
					LoadAddOn("Blizzard_RecruitAFriend")
				end
				
				-- If Blizzard's frame exists, trigger its initialization
				if RecruitAFriendFrame then
					-- Call OnLoad if it hasn't been called yet (simulate first-time load)
					if RecruitAFriendFrame.OnLoad and not RecruitAFriendFrame.rafEnabled then
						RecruitAFriendFrame:OnLoad()
					end
					
					-- Call OnShow to refresh data (this is what Blizzard does when showing the tab)
					if RecruitAFriendFrame.OnShow then
						-- OnShow doesn't exist as a direct method, but we can trigger the event
						-- by registering events if not already done
						if not RecruitAFriendFrame.eventsRegistered then
							RecruitAFriendFrame:RegisterEvent("RAF_SYSTEM_ENABLED_STATUS")
							RecruitAFriendFrame:RegisterEvent("RAF_RECRUITING_ENABLED_STATUS")
							RecruitAFriendFrame:RegisterEvent("RAF_INFO_UPDATED")
							RecruitAFriendFrame.eventsRegistered = true
						end
					end
				end
				
				-- Get RAF system info
				local rafSystemInfo = C_RecruitAFriend.GetRAFSystemInfo()
				if rafSystemInfo then
					-- Store system info for use by RAF functions
					frame.RecruitAFriendFrame.rafSystemInfo = rafSystemInfo
				end
				
				-- Get RAF info and update
				local rafInfo = C_RecruitAFriend.GetRAFInfo()
				if rafInfo then
					BetterRAF_UpdateRAFInfo(frame.RecruitAFriendFrame, rafInfo)
					-- Also store in Blizzard's frame if it exists
					if RecruitAFriendFrame then
						RecruitAFriendFrame.rafInfo = rafInfo
					end
				end
				
				-- Request updated recruitment info (enables "Generate Link" functionality)
				C_RecruitAFriend.RequestUpdatedRecruitmentInfo()
			end
		end
	elseif tabIndex == 4 then
		-- Show Sort options (11.2.5: restored from dropdown to tab)
		if frame.SortFrame then
			frame.SortFrame:Show()
		end
	end
end

-- Set sort method and update display
function BetterFriendlist_SetSortMethod(method)
	if not method then return end
	
	-- Store the sort method
	currentSortMethod = method
	
	-- Switch back to Friends tab and update tab selection
	local frame = BetterFriendsFrame
	if frame and frame.FriendsTabHeader then
		PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
	end
	
	-- Show Friends tab content
	BetterFriendsFrame_ShowTab(1)
	
	-- Provide feedback
	local methodNames = {
		status = "Status (Online First)",
		name = "Name (A-Z)",
		level = "Level (Highest First)",
		zone = "Zone"
	}
	print("|cff00ff00Sort changed to:|r " .. (methodNames[method] or method))
end

-- Update Quick Join tab with group count (matching Blizzard's FriendsFrame_UpdateQuickJoinTab)
function BetterFriendsFrame_UpdateQuickJoinTab()
	local frame = BetterFriendsFrame
	if not frame or not frame.BottomTab4 then return end
	
	-- Get number of groups available for quick join
	local numGroups = C_SocialQueue and C_SocialQueue.GetAllGroups and #C_SocialQueue.GetAllGroups() or 0
	
	-- Update tab text with count
	frame.BottomTab4:SetText(QUICK_JOIN.." "..string.format(NUMBER_IN_PARENTHESES, numGroups))
	
	-- Resize tab to fit text (0 = no padding)
	PanelTemplates_TabResize(frame.BottomTab4, 0)
end

-- Initialize Battlenet Frame based on Blizzard's implementation
function InitializeBattlenetFrame()
	local frame = BetterFriendsFrame
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame then return end
	
	local bnetFrame = frame.FriendsTabHeader.BattlenetFrame
	
	-- Setup BroadcastFrame methods first
	SetupBroadcastFrame()
	
	if BNFeaturesEnabled() then
		if BNConnected() then
			-- Update broadcast display
			UpdateBroadcast()
			
			-- Get and display BattleTag
			local _, battleTag = BNGetInfo()
			if battleTag then
				-- Format battle tag with colored suffix (like Blizzard does)
				local symbol = string.find(battleTag, "#")
				if symbol then
					local suffix = string.sub(battleTag, symbol)
					battleTag = string.sub(battleTag, 1, symbol - 1).."|cff416380"..suffix.."|r"
				end
				bnetFrame.Tag:SetText(battleTag)
				bnetFrame.Tag:Show()
				bnetFrame:Show()
			else
				bnetFrame:Hide()
			end
			
			bnetFrame.UnavailableLabel:Hide()
			-- Show Contacts Menu Button (11.2.5 - replaces old BroadcastButton)
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Show()
			end
		else
			-- Battle.net not connected
			bnetFrame:Show()
			bnetFrame.Tag:Hide()
			bnetFrame.UnavailableLabel:Show()
			-- Hide Contacts Menu Button when not connected
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Hide()
			end
		end
	end
end

-- Update broadcast message display
function UpdateBroadcast()
	local frame = BetterFriendsFrame
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame or not frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame then return end
	
	local _, _, _, broadcastText = BNGetInfo()
	local editBox = frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame.EditBox
	if editBox then
		editBox:SetText(broadcastText or "")
	end
end

-- Setup BroadcastFrame methods
function SetupBroadcastFrame()
	local broadcastFrame = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.BattlenetFrame and BetterFriendsFrame.FriendsTabHeader.BattlenetFrame.BroadcastFrame
	if not broadcastFrame then return end
	
	-- ToggleFrame method
	function broadcastFrame:ToggleFrame()
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
		if self:IsShown() then
			self:HideFrame()
		else
			self:ShowFrame()
		end
	end
	
	-- ShowFrame method
	function broadcastFrame:ShowFrame()
		UpdateBroadcast()
		self:Show()
		if self.EditBox then
			self.EditBox:SetFocus()
		end
		-- Note: ContactsMenuButton (11.2.5) uses SquareIconButtonTemplate, no custom textures needed
	end
	
	-- HideFrame method
	function broadcastFrame:HideFrame()
		self:Hide()
		if self.EditBox then
			self.EditBox:ClearFocus()
		end
		-- Note: ContactsMenuButton (11.2.5) uses SquareIconButtonTemplate, no custom textures needed
	end
	
	-- UpdateBroadcast method (for cancel button)
	function broadcastFrame:UpdateBroadcast()
		UpdateBroadcast()
	end
	
	-- SetBroadcast method (for update button)
	function broadcastFrame:SetBroadcast()
		if not self.EditBox then return end
		local text = self.EditBox:GetText() or ""
		local _, _, _, broadcastText = BNGetInfo()
		if text ~= broadcastText then
			if BNSetCustomMessage then
				BNSetCustomMessage(text)
			end
		end
		self:HideFrame()
	end
end

-- TravelPass Button Handlers
function BetterFriendsList_TravelPassButton_OnClick(self)
	local friendData = self.friendData
	if not friendData or friendData.type ~= "bnet" then return end
	
	-- Get the actual Battle.net friend index from our stored data
	local numBNet = BNGetNumFriends()
	local actualIndex = nil
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID == friendData.bnetAccountID then
			actualIndex = i
			break
		end
	end
	
	if not actualIndex then return end
	
	-- Check if friend has multiple game accounts
	local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualIndex)
	
	if numGameAccounts > 1 then
		-- Multiple game accounts - need to show dropdown
		-- For now, just invite the first valid WoW account
		local playerFactionGroup = UnitFactionGroup("player")
		for i = 1, numGameAccounts do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, i)
			if gameAccountInfo and gameAccountInfo.clientProgram == BNET_CLIENT_WOW and 
			   gameAccountInfo.isOnline and gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
				-- Found a valid WoW account - send invite
				if gameAccountInfo.playerGuid then
					BNInviteFriend(gameAccountInfo.gameAccountID)
					return
				end
			end
		end
	else
		-- Single game account - invite directly
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, 1)
		if gameAccountInfo and gameAccountInfo.gameAccountID then
			BNInviteFriend(gameAccountInfo.gameAccountID)
		end
	end
end

function BetterFriendsList_TravelPassButton_OnEnter(self)
	local friendData = self.friendData
	if not friendData then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	-- Get the actual Battle.net friend index
	local numBNet = BNGetNumFriends()
	local actualIndex = nil
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID == friendData.bnetAccountID then
			actualIndex = i
			break
		end
	end
	
	if not actualIndex then
		GameTooltip:SetText("Error", RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		GameTooltip:Show()
		return
	end
	
	-- Check for invite restrictions (matching Blizzard's logic)
	local restriction = nil  -- Will be set to NO_GAME_ACCOUNTS if no valid accounts found
	local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualIndex)
	local playerFactionGroup = UnitFactionGroup("player")
	local hasWowAccount = false
	local isCrossFaction = false
	local factionName = nil
	
	for i = 1, numGameAccounts do
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualIndex, i)
		if gameAccountInfo then
			if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
				hasWowAccount = true
				if gameAccountInfo.factionName then
					factionName = gameAccountInfo.factionName
					isCrossFaction = (factionName ~= playerFactionGroup)
				end
				
				-- Check WoW version compatibility (same logic as enable/disable)
				if gameAccountInfo.wowProjectID and WOW_PROJECT_ID then
					if gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
						-- Friend is on Classic, we're not
						if not restriction then
							restriction = INVITE_RESTRICTION_WOW_PROJECT_CLASSIC
						end
					elseif gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
						-- Friend is on Mainline, we're not
						if not restriction then
							restriction = INVITE_RESTRICTION_WOW_PROJECT_MAINLINE
						end
					elseif gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
						-- Different WoW version (other)
						if not restriction then
							restriction = INVITE_RESTRICTION_WOW_PROJECT_ID
						end
					elseif gameAccountInfo.realmID == 0 then
						-- No realm info
						if not restriction then
							restriction = INVITE_RESTRICTION_INFO
						end
					elseif not gameAccountInfo.isInCurrentRegion then
						-- Different region
						restriction = INVITE_RESTRICTION_REGION
					else
						-- At least one valid WoW account that can be invited
						restriction = INVITE_RESTRICTION_NONE
						break
					end
				elseif gameAccountInfo.realmID == 0 then
					-- No realm info
					if not restriction then
						restriction = INVITE_RESTRICTION_INFO
					end
				elseif not gameAccountInfo.isInCurrentRegion then
					-- Different region
					restriction = INVITE_RESTRICTION_REGION
				elseif gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
					-- Valid WoW account (no project ID check needed)
					restriction = INVITE_RESTRICTION_NONE
					break
				end
			else
				-- Non-WoW client (App, BSAp, etc.)
				if not restriction then
					restriction = INVITE_RESTRICTION_CLIENT
				end
			end
		end
	end
	
	-- If no restriction was set, means no game accounts at all
	if not restriction then
		restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
	end
	
	-- Set tooltip text based on restriction
	local tooltipText = TRAVEL_PASS_INVITE or "Invite to Group"
	if isCrossFaction then
		tooltipText = TRAVEL_PASS_INVITE_CROSS_FACTION or "Invite to Group"
	end
	
	GameTooltip:SetText(tooltipText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	
	-- Add cross-faction line
	if isCrossFaction and factionName then
		local factionLabel = factionName == "Horde" and (FACTION_HORDE or "Horde") or (FACTION_ALLIANCE or "Alliance")
		if CROSS_FACTION_INVITE_TOOLTIP then
			GameTooltip:AddLine(CROSS_FACTION_INVITE_TOOLTIP:format(factionLabel), nil, nil, nil, true)
		end
	end
	
	-- Add restriction text in red if there's a restriction
	if restriction ~= INVITE_RESTRICTION_NONE then
		local restrictionText = ""
		if restriction == INVITE_RESTRICTION_CLIENT then
			restrictionText = ERR_TRAVEL_PASS_NOT_WOW or "Friend is not playing World of Warcraft"
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_CLASSIC then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_CLASSIC_OVERRIDE or "This friend is playing World of Warcraft Classic."
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_MAINLINE then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT_MAINLINE_OVERRIDE or "This friend is playing World of Warcraft."
		elseif restriction == INVITE_RESTRICTION_WOW_PROJECT_ID then
			restrictionText = ERR_TRAVEL_PASS_WRONG_PROJECT or "Friend is playing a different version of World of Warcraft"
		elseif restriction == INVITE_RESTRICTION_INFO then
			restrictionText = ERR_TRAVEL_PASS_NO_INFO or "Not enough information available"
		elseif restriction == INVITE_RESTRICTION_REGION then
			restrictionText = ERR_TRAVEL_PASS_DIFFERENT_REGION or "Friend is in a different region"
		elseif restriction == INVITE_RESTRICTION_NO_GAME_ACCOUNTS then
			restrictionText = "No game accounts available"
		end
		
		if restrictionText ~= "" then
			GameTooltip:AddLine(restrictionText, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		end
	end
	
	GameTooltip:Show()
end

-- Friend List Button OnEnter (tooltip)
function BetterFriendsList_Button_OnEnter(button)
	if not button.friendData then return end
	
	local friend = button.friendData
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	-- Show Battle.net account name as header
	if friend.accountName then
		GameTooltip:SetText(friend.accountName, FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b)
	end
	
	-- Show character info if online and playing WoW
	if friend.connected and friend.characterName and friend.gameAccountInfo then
		-- Add Timerunning icon to character name first
		local characterName = friend.characterName
		if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
			characterName = TimerunningUtil.AddSmallIcon(characterName)
		end
		
		-- Build the character line: "Name, Level X ClassName"
		local characterLine = characterName
		if friend.level and friend.className then
			characterLine = characterLine .. ", Level " .. friend.level .. " " .. friend.className
		end
		GameTooltip:AddLine(characterLine, 1, 1, 1, true)
		
		-- Show location (area + realm in one line like Blizzard)
		if friend.areaName then
			local locationLine = friend.areaName
			if friend.realmName then
				locationLine = locationLine .. " - " .. friend.realmName
			end
			GameTooltip:AddLine(locationLine, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
		elseif friend.realmName then
			GameTooltip:AddLine(friend.realmName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
		end
	elseif not friend.connected then
		-- Show last online time
		GameTooltip:AddLine(FRIENDS_LIST_OFFLINE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true)
	end
	
	-- Show note if exists
	if friend.note and friend.note ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(friend.note, 1, 0.82, 0, true)
	end
	
	GameTooltip:Show()
end

-- Friend List Button OnLeave
function BetterFriendsList_Button_OnLeave(button)
	GameTooltip:Hide()
end

-- Button OnClick Handler (1:1 from Blizzard)
function BetterFriendsList_Button_OnClick(button, mouseButton)
	if not button.friendInfo then
		return
	end
	
	if mouseButton == "LeftButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		-- Left click: Select friend (future functionality)
		-- For now, we just play the sound
	elseif mouseButton == "RightButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		
		local friendInfo = button.friendInfo
		
		if friendInfo.type == "bnet" then
			-- BattleNet friend context menu
			local accountInfo = C_BattleNet.GetFriendAccountInfo(friendInfo.index)
			if accountInfo then
				BetterFriendsList_ShowBNDropdown(
					accountInfo.accountName,
					accountInfo.gameAccountInfo.isOnline,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					true, -- friendsList
					accountInfo.bnetAccountID,
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					accountInfo.battleTag
				)
			end
		else
			-- WoW friend context menu
			local info = C_FriendList.GetFriendInfoByIndex(friendInfo.index)
			if info then
				BetterFriendsList_ShowDropdown(
					info.name,
					info.connected,
					nil, -- lineID
					nil, -- chatType
					nil, -- chatFrame
					true, -- friendsList
					nil, -- communityClubID
					nil, -- communityStreamID
					nil, -- communityEpoch
					nil, -- communityPosition
					info.guid
				)
			end
		end
	end
end

-- Show WoW Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowDropdown(name, connected, lineID, chatType, chatFrame, friendsList, communityClubID, communityStreamID, communityEpoch, communityPosition, guid)
	if connected or friendsList then
		local contextData = {
			name = name,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = nil,
			guid = guid,
		}
		
		-- Determine menu type based on online status
		local menuType = connected and "FRIEND" or "FRIEND_OFFLINE"
		UnitPopup_OpenMenu(menuType, contextData)
	end
end

-- Show BattleNet Friend Context Menu (1:1 from Blizzard)
function BetterFriendsList_ShowBNDropdown(name, connected, lineID, chatType, chatFrame, friendsList, bnetIDAccount, communityClubID, communityStreamID, communityEpoch, communityPosition, battleTag)
	if connected or friendsList then
		local contextData = {
			name = name,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = bnetIDAccount,
			battleTag = battleTag,
		}
		
		-- Determine menu type based on online status
		local menuType = connected and "BN_FRIEND" or "BN_FRIEND_OFFLINE"
		UnitPopup_OpenMenu(menuType, contextData)
	end
end

--------------------------------------------------------------------------
-- WHO FRAME FUNCTIONALITY
--------------------------------------------------------------------------

-- Who frame variables
local whoSortValue = 1  -- Default sort: zone
local MAX_WHOS_FROM_SERVER = 50  -- Maximum number of results from server
local NUM_WHO_BUTTONS = 17  -- Number of visible buttons in Who list
local whoDataProvider = nil
local selectedWhoButton = nil

-- Contacts Menu (11.2.5 - replaces broadcast button, includes ignore list)
-- Uses MenuUtil like Blizzard's ContactsMenuMixin
function BetterFriendsFrame_ShowContactsMenu(button)
	MenuUtil.CreateContextMenu(button, function(ownerRegion, rootDescription)
		rootDescription:SetTag("CONTACTS_MENU");
		
		-- Create Group option
		rootDescription:CreateButton("Create Group", function()
			StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP")
		end);
		
		rootDescription:CreateDivider();
		
		-- Broadcast option (only if BNet is connected)
		local canUseBroadCastFrame = BNFeaturesEnabled() and BNConnected();
		if canUseBroadCastFrame then
			rootDescription:CreateButton(CONTACTS_MENU_BROADCAST_BUTTON_NAME or "Set Broadcast Message", function()
				local broadcastFrame = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame.BroadcastFrame;
				if broadcastFrame then
					broadcastFrame:ToggleFrame();
				end
			end);
		end
		
		-- Ignore List option
		rootDescription:CreateButton(CONTACTS_MENU_IGNORE_BUTTON_NAME or "Manage Ignore List", function()
			BetterFriendsFrame_ShowIgnoreList();
		end);
	end);
end

-- Show Ignore List (11.2.5 - part of contacts menu)
function BetterFriendsFrame_ShowIgnoreList()
	-- For now, show a simple message
	-- In the future, we can implement a full ignore list UI
	local numIgnores = C_FriendList.GetNumIgnores()
	
	if numIgnores == 0 then
		print("Your ignore list is empty.")
		return
	end
	
	print("Ignore List (" .. numIgnores .. " players):")
	for i = 1, numIgnores do
		local name = C_FriendList.GetIgnoreName(i)
		if name then
			print("  " .. i .. ". " .. name)
		end
	end
	print("Use '/unignore <name>' to remove someone from your ignore list.")
end

-- Initialize Who Frame with ScrollBox
function BetterWhoFrame_OnLoad(self)
	-- Initialize ScrollBox with DataProvider
	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("BetterWhoListButtonTemplate", function(button, elementData)
		BetterWhoFrame_InitButton(button, elementData)
	end)
	view:SetElementExtentCalculator(function(dataIndex, elementData)
		return 16 -- Height of each button
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
	
	-- Create DataProvider
	whoDataProvider = CreateDataProvider()
	self.ScrollBox:SetDataProvider(whoDataProvider)
	
	-- Initialize selected who
	self.selectedWho = nil
	self.selectedName = ""
end

-- Initialize individual Who button
function BetterWhoFrame_InitButton(button, elementData)
	local info = elementData
	button.index = info.index
	
	-- Get class color
	local classTextColor
	if info.filename then
		classTextColor = RAID_CLASS_COLORS[info.filename]
	else
		classTextColor = HIGHLIGHT_FONT_COLOR
	end
	
	-- Set button text
	button.Name:SetText(info.fullName)
	button.Level:SetText(info.level)
	button.Class:SetText(info.classStr or "")
	if classTextColor then
		button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
	end
	
	-- Variable column based on sort
	local variableColumnTable = { info.area, info.fullGuildName, info.raceStr }
	local variableText = variableColumnTable[whoSortValue] or info.area
	button.Variable:SetText(variableText or "")
	
	-- Set tooltip if truncated
	if button.Variable:IsTruncated() or button.Level:IsTruncated() or button.Name:IsTruncated() then
		button.tooltip1 = info.fullName
		button.tooltip2 = format(WHO_LIST_LEVEL_TOOLTIP or "Level %d", info.level)
		button.tooltip3 = variableText
	else
		button.tooltip1 = nil
		button.tooltip2 = nil
		button.tooltip3 = nil
	end
	
	-- Update selection state
	local selected = BetterFriendsFrame.WhoFrame.selectedWho == info.index
	BetterWhoListButton_SetSelected(button, selected)
end

-- Function to show specific bottom tab
function BetterFriendsFrame_ShowBottomTab(tabIndex)
	local frame = BetterFriendsFrame
	if not frame then return end
	
	-- Hide all content frames and their associated UI elements
	if frame.ScrollFrame then frame.ScrollFrame:Hide() end
	if frame.MinimalScrollBar then frame.MinimalScrollBar:Hide() end
	if frame.AddFriendButton then frame.AddFriendButton:Hide() end
	if frame.SendMessageButton then frame.SendMessageButton:Hide() end
	if frame.WhoFrame then frame.WhoFrame:Hide() end
	if frame.SortFrame then frame.SortFrame:Hide() end
	
	-- Hide all friend list buttons explicitly
	if tabIndex ~= 1 then
		-- Hide all buttons in the button pool
		for _, button in pairs(buttonPool.friendButtons) do
			button:Hide()
		end
		for _, button in pairs(buttonPool.headerButtons) do
			button:Hide()
		end
		-- Also hide XML-defined buttons
		for i = 1, NUM_BUTTONS do
			local xmlButton = frame.ScrollFrame and frame.ScrollFrame["Button" .. i]
			if xmlButton then
				xmlButton:Hide()
			end
		end
	end
	
	-- Hide/show FriendsTabHeader based on tab (top tabs should only show for Friends bottom tab)
	if frame.FriendsTabHeader then
		if tabIndex == 1 then
			-- Show FriendsTabHeader for Friends tab
			frame.FriendsTabHeader:Show()
			if frame.FriendsTabHeader.SearchBox then
				frame.FriendsTabHeader.SearchBox:Show()
			end
		else
			-- Hide FriendsTabHeader for other tabs (Who, Raid, Quick Join)
			frame.FriendsTabHeader:Hide()
		end
	end
	
	if tabIndex == 1 then
		-- Friends list
		frame.ScrollFrame:Show()
		frame.MinimalScrollBar:Show()
		frame.AddFriendButton:Show()
		frame.SendMessageButton:Show()
		UpdateFriendsDisplay()
	elseif tabIndex == 2 then
		-- Who frame
		frame.WhoFrame:Show()
		BetterWhoFrame_Update()
	elseif tabIndex == 3 then
		-- Raid (placeholder for now)
		print("Raid tab not yet implemented")
	elseif tabIndex == 4 then
		-- Quick Join (placeholder for now)
		print("Quick Join tab not yet implemented")
	end
end

-- Send Who request
function BetterWhoFrame_SendWhoRequest(text)
	if not text or text == "" then
		-- Use default Who command if no text provided
		local level = UnitLevel("player")
		local minLevel = level - 3
		if minLevel <= 0 then
			minLevel = 1
		end
		local maxLevel = math.min(level + 3, GetMaxPlayerLevel())
		text = "z-\""..GetRealZoneText().."\" "..minLevel.."-"..maxLevel
	end
	
	C_FriendList.SendWho(text)
end

-- Update Who list display
function BetterWhoFrame_Update()
	if not BetterFriendsFrame or not BetterFriendsFrame.WhoFrame or not whoDataProvider then
		return
	end
	
	local numWhos, totalCount = C_FriendList.GetNumWhoResults()
	
	-- Update totals text
	local displayedText = ""
	if totalCount > MAX_WHOS_FROM_SERVER then
		displayedText = format(WHO_FRAME_SHOWN_TEMPLATE or "Showing %d", MAX_WHOS_FROM_SERVER)
	end
	
	local totalsText = format(WHO_FRAME_TOTAL_TEMPLATE or "Total: %d", totalCount)
	if displayedText ~= "" then
		totalsText = totalsText .. "  " .. displayedText
	end
	BetterFriendsFrame.WhoFrame.ListInset.Totals:SetText(totalsText)
	
	-- Clear and rebuild DataProvider
	whoDataProvider:Flush()
	
	for i = 1, numWhos do
		local info = C_FriendList.GetWhoInfo(i)
		if info then
			info.index = i  -- Store index for selection tracking
			whoDataProvider:Insert(info)
		end
	end
end

-- Set selected Who button
function BetterWhoFrame_SetSelectedButton(button)
	if selectedWhoButton then
		BetterWhoListButton_SetSelected(selectedWhoButton, false)
	end
	
	selectedWhoButton = button
	BetterFriendsFrame.WhoFrame.selectedWho = button and button.index or nil
	BetterFriendsFrame.WhoFrame.selectedName = button and button.Name:GetText() or ""
	
	if button then
		BetterWhoListButton_SetSelected(button, true)
	end
	
	-- Enable/disable buttons based on selection
	if BetterFriendsFrame.WhoFrame.selectedWho then
		BetterFriendsFrame.WhoFrame.GroupInviteButton:Enable()
		BetterFriendsFrame.WhoFrame.AddFriendButton:Enable()
	else
		BetterFriendsFrame.WhoFrame.GroupInviteButton:Disable()
		BetterFriendsFrame.WhoFrame.AddFriendButton:Disable()
	end
end

-- Set button selection visual state
function BetterWhoListButton_SetSelected(button, selected)
	if selected then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
end

-- Button click handler
function BetterWhoListButton_OnClick(button, mouseButton)
	if mouseButton == "LeftButton" then
		BetterWhoFrame_SetSelectedButton(button)
	else
		-- Right-click: show dropdown menu
		local name = button.Name:GetText()
		if name then
			FriendsFrame_ShowDropdown(name, 1)
		end
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Sort by column
function BetterWhoFrame_SortByColumn(sortType)
	if sortType == "name" then
		whoSortValue = 1
		C_FriendList.SortWho("name")
	elseif sortType == "zone" then
		whoSortValue = 1
		C_FriendList.SortWho("zone")
	elseif sortType == "level" then
		whoSortValue = 1
		C_FriendList.SortWho("level")
	elseif sortType == "class" then
		whoSortValue = 1
		C_FriendList.SortWho("class")
	end
	BetterWhoFrame_Update()
end

-- ========================================
-- Ignore List Window Functions (11.2.5)
-- Replicated from Blizzard_FriendsFrame 11.2.5
-- ========================================

-- Constants
local SQUELCH_TYPE_IGNORE = 1
local SQUELCH_TYPE_BLOCK_INVITE = 2

-- Initialize Ignore List Window (FriendsIgnoreListMixin:OnLoad)
function BetterIgnoreListWindow_OnLoad(self)
	-- Set up frame visuals matching Blizzard's InitializeFrameVisuals
	ButtonFrameTemplate_HidePortrait(self)
	self:SetTitle(IGNORE_LIST)
	
	if self.TopTileStreaks then
		self.TopTileStreaks:Hide()
	end
	
	-- Position Inset (matching Blizzard's exact positioning)
	if self.Inset then
		self.Inset:ClearAllPoints()
		self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 11, -28)
		self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 36)
	end
	
	-- Position ScrollBox inside Inset (matching Blizzard's exact positioning)
	if self.ScrollBox and self.Inset then
		self.ScrollBox:ClearAllPoints()
		self.ScrollBox:SetPoint("TOPLEFT", self.Inset, 5, -5)
		self.ScrollBox:SetPoint("BOTTOMRIGHT", self.Inset, -22, 2)
	end
	
	-- Initialize ScrollBox with element factory (exact Blizzard implementation)
	local scrollBoxView = CreateScrollBoxListLinearView()
	scrollBoxView:SetElementFactory(function(factory, elementData)
		if elementData.header then
			factory(elementData.header)
		else
			factory("BetterIgnoreListButtonTemplate", IgnoreList_InitButton)
		end
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, scrollBoxView)
end

-- Initialize a button in the ignore list (exact Blizzard implementation)
function IgnoreList_InitButton(button, elementData)
	button.index = elementData.index

	if elementData.squelchType == SQUELCH_TYPE_IGNORE then
		local name = C_FriendList.GetIgnoreName(button.index)
		if not name then
			button.name:SetText(UNKNOWN)
		else
			button.name:SetText(name)
			button.type = SQUELCH_TYPE_IGNORE
		end
	elseif elementData.squelchType == SQUELCH_TYPE_BLOCK_INVITE then
		local blockID, blockName = BNGetBlockedInfo(button.index)
		button.name:SetText(blockName)
		button.type = SQUELCH_TYPE_BLOCK_INVITE
	end

	local selectedSquelchType, selectedSquelchIndex = IgnoreList_GetSelected()
	local selected = (selectedSquelchType == button.type) and (selectedSquelchIndex == button.index)
	IgnoreList_SetButtonSelected(button, selected)
end

-- Get current selection (exact Blizzard implementation)
function IgnoreList_GetSelected()
	local selectedSquelchType = BetterFriendsFrame.selectedSquelchType
	local selectedSquelchIndex = 0
	if selectedSquelchType == SQUELCH_TYPE_IGNORE then
		selectedSquelchIndex = C_FriendList.GetSelectedIgnore() or 0
	elseif selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE then
		selectedSquelchIndex = BNGetSelectedBlock()
	end
	return selectedSquelchType, selectedSquelchIndex
end

-- Set button selection state (exact Blizzard implementation)
function IgnoreList_SetButtonSelected(button, selected)
	if selected then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
end

-- Update the ignore list display (exact Blizzard implementation)
function IgnoreList_Update()
	local dataProvider = CreateDataProvider()

	local numIgnores = C_FriendList.GetNumIgnores()
	if numIgnores and numIgnores > 0 then
		dataProvider:Insert({header="BetterFriendsFrameIgnoredHeaderTemplate"})
		for index = 1, numIgnores do
			dataProvider:Insert({squelchType=SQUELCH_TYPE_IGNORE, index=index})
		end
	end

	local numBlocks = BNGetNumBlocked()
	if numBlocks and numBlocks > 0 then
		dataProvider:Insert({header="BetterFriendsFrameBlockedInviteHeaderTemplate"})
		for index = 1, numBlocks do
			dataProvider:Insert({squelchType=SQUELCH_TYPE_BLOCK_INVITE, index=index})
		end
	end
	BetterFriendsFrame.IgnoreListWindow.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

	local selectedSquelchType, selectedSquelchIndex = IgnoreList_GetSelected()

	local hasSelection = selectedSquelchType and selectedSquelchIndex > 0
	if not hasSelection then
		-- Auto-select first entry if nothing selected
		local elementData = dataProvider:FindElementDataByPredicate(function(elementData)
			return elementData.squelchType ~= nil
		end)
		if elementData then
			BetterFriendsFrame_SelectSquelched(elementData.squelchType, elementData.index)
			hasSelection = true
		end
	end

	BetterFriendsFrame.IgnoreListWindow.UnignorePlayerButton:SetEnabled(hasSelection)
end

-- Select a squelched player (exact Blizzard implementation)
function BetterFriendsFrame_SelectSquelched(squelchType, index)
	local oldSquelchType, oldSquelchIndex = IgnoreList_GetSelected()

	if squelchType == SQUELCH_TYPE_IGNORE then
		C_FriendList.SetSelectedIgnore(index)
	elseif squelchType == SQUELCH_TYPE_BLOCK_INVITE then
		BNSetSelectedBlock(index)
	end
	BetterFriendsFrame.selectedSquelchType = squelchType

	local function UpdateButtonSelection(type, index, selected)
		local button = BetterFriendsFrame.IgnoreListWindow.ScrollBox:FindFrameByPredicate(function(button, elementData)
			return elementData.squelchType == type and elementData.index == index
		end)
		if button then
			IgnoreList_SetButtonSelected(button, selected)
		end
	end

	UpdateButtonSelection(oldSquelchType, oldSquelchIndex, false)
	UpdateButtonSelection(squelchType, index, true)
end

-- Handle button click (exact Blizzard implementation: IgnoreListButtonMixin:OnClick)
function BetterIgnoreListButton_OnClick(self)
	BetterFriendsFrame_SelectSquelched(self.type, self.index)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Unignore the selected player (exact Blizzard implementation: FriendsFrameUnsquelchButton_OnClick)
function BetterIgnoreList_Unignore()
	local selectedSquelchType = BetterFriendsFrame.selectedSquelchType
	if selectedSquelchType == SQUELCH_TYPE_IGNORE then
		C_FriendList.DelIgnoreByIndex(C_FriendList.GetSelectedIgnore())
	elseif selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE then
		local blockID = BNGetBlockedInfo(BNGetSelectedBlock())
		BNSetBlocked(blockID, false)
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Toggle Ignore List Window visibility (FriendsIgnoreListMixin:ToggleFrame)
function BetterFriendsFrame_ToggleIgnoreList()
	local frame = BetterFriendsFrame
	if not frame or not frame.IgnoreListWindow then return end
	
	frame.IgnoreListWindow:SetShown(not frame.IgnoreListWindow:IsShown())
	PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
end

-- Update BetterFriendsFrame_ShowIgnoreList to toggle window
function BetterFriendsFrame_ShowIgnoreList()
	BetterFriendsFrame_ToggleIgnoreList()
end

-- ========================================
-- Recent Allies Functions (11.2.5)
-- Complete Blizzard implementation from Blizzard_RecentAllies
-- ========================================

-- Recent Allies List Events
local RecentAlliesListEvents = {
	"RECENT_ALLIES_CACHE_UPDATE",
}

-- Initialize Recent Allies Frame (RecentAlliesListMixin:OnLoad)
function BetterRecentAlliesFrame_OnLoad(self)
	-- Initialize ScrollBox with element factory
	local elementSpacing = 1
	local topPadding, bottomPadding, leftPadding, rightPadding = 0, 0, 0, 0
	local view = CreateScrollBoxListLinearView(topPadding, bottomPadding, leftPadding, rightPadding, elementSpacing)
	
	view:SetElementFactory(function(factory, elementData)
		if elementData.isDivider then
			factory("BetterRecentAlliesDividerTemplate")
		else
			factory("BetterRecentAlliesEntryTemplate", function(button, elementData)
				BetterRecentAlliesEntry_Initialize(button, elementData)
				button:SetScript("OnClick", function(btn, mouseButtonName)
					if mouseButtonName == "LeftButton" then
						PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
						-- Selection behavior handled here
						if self.selectedEntry == btn then
							self.selectedEntry = nil
							btn:UnlockHighlight()
						else
							if self.selectedEntry then
								self.selectedEntry:UnlockHighlight()
							end
							self.selectedEntry = btn
							btn:LockHighlight()
						end
					elseif mouseButtonName == "RightButton" then
						BetterRecentAlliesEntry_OpenMenu(btn)
					end
				end)
			end)
		end
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
	
	-- LoadingSpinner is now defined in XML using SpinnerTemplate
end

-- Show Recent Allies Frame (RecentAlliesListMixin:OnShow)
function BetterRecentAlliesFrame_OnShow(self)
	FrameUtil.RegisterFrameForEvents(self, RecentAlliesListEvents)
	
	-- NOTE: TryRequestRecentAlliesData() is PROTECTED and cannot be called by addons.
	-- Blizzard's code can call it because it's part of the UI core, not an addon.
	-- The data loads automatically when we check IsRecentAllyDataReady(), and we'll 
	-- receive RECENT_ALLIES_CACHE_UPDATE event when it becomes available.
	
	-- Show spinner initially, will hide when data is ready
	BetterRecentAlliesFrame_SetLoadingSpinnerShown(self, true)
	
	-- Refresh will check if data is ready and hide spinner if it is
	BetterRecentAlliesFrame_Refresh(self, ScrollBoxConstants.DiscardScrollPosition)
end

-- Hide Recent Allies Frame (RecentAlliesListMixin:OnHide)
function BetterRecentAlliesFrame_OnHide(self)
	FrameUtil.UnregisterFrameForEvents(self, RecentAlliesListEvents)
end

-- Event handler (RecentAlliesListMixin:OnEvent)
function BetterRecentAlliesFrame_OnEvent(self, event, ...)
	if event == "RECENT_ALLIES_CACHE_UPDATE" then
		BetterRecentAlliesFrame_Refresh(self, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- Refresh the list (RecentAlliesListMixin:Refresh)
function BetterRecentAlliesFrame_Refresh(self, retainScrollPosition)
	-- Check if the Recent Allies system is enabled at all
	if not C_RecentAllies or not C_RecentAllies.IsSystemEnabled() then
		BetterRecentAlliesFrame_SetLoadingSpinnerShown(self, false)
		-- Show a message that the system is not available
		if not self.UnavailableText then
			self.UnavailableText = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			self.UnavailableText:SetPoint("CENTER")
			self.UnavailableText:SetText("Recent Allies system is not available.")
		end
		self.UnavailableText:Show()
		return
	end
	
	-- Hide unavailable message if it exists
	if self.UnavailableText then
		self.UnavailableText:Hide()
	end
	
	-- Check if data is ready
	local dataReady = C_RecentAllies.IsRecentAllyDataReady()
	BetterRecentAlliesFrame_SetLoadingSpinnerShown(self, not dataReady)
	
	if not dataReady then
		-- Data will load automatically, and we'll get RECENT_ALLIES_CACHE_UPDATE event
		return
	end
	
	local dataProvider = BetterRecentAlliesFrame_BuildDataProvider()
	self.ScrollBox:SetDataProvider(dataProvider, retainScrollPosition)
end

-- Build data provider (RecentAlliesListMixin:BuildRecentAlliesDataProvider)
function BetterRecentAlliesFrame_BuildDataProvider()
	-- Get recent allies (presorted by pin state, online status, most recent interaction, alphabetically)
	local recentAllies = C_RecentAllies.GetRecentAllies()
	local dataProvider = CreateDataProvider(recentAllies)
	
	-- Insert divider between pinned and unpinned allies
	local firstUnpinnedIndex = dataProvider:FindIndexByPredicate(function(elementData)
		return not elementData.stateData.pinExpirationDate
	end)
	
	if firstUnpinnedIndex and firstUnpinnedIndex > 1 then
		dataProvider:InsertAtIndex({ isDivider = true }, firstUnpinnedIndex)
	end
	
	return dataProvider
end

-- Set loading spinner visibility (RecentAlliesListMixin:SetLoadingSpinnerShown)
function BetterRecentAlliesFrame_SetLoadingSpinnerShown(self, shown)
	self.LoadingSpinner:SetShown(shown)
	self.ScrollBox:SetShown(not shown)
	self.ScrollBar:SetShown(not shown)
end

-- Initialize a recent ally entry button (RecentAlliesEntryMixin:Initialize)
function BetterRecentAlliesEntry_Initialize(button, elementData)
	button.elementData = elementData
	
	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData
	
	-- Set online status icon
	local statusIcon = "Interface\\FriendsFrame\\StatusIcon-Offline"
	if stateData.isOnline then
		if stateData.isAFK then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Away"
		elseif stateData.isDND then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-DnD"
		else
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Online"
		end
	end
	button.OnlineStatusIcon:SetTexture(statusIcon)
	
	-- Update background color based on online status (match Blizzard exactly)
	-- Use FRIENDS_OFFLINE_BACKGROUND_COLOR (with S), not FRIEND_OFFLINE_BACKGROUND_COLOR
	button.NormalTexture:Show()
	local backgroundColor = stateData.isOnline and FRIENDS_WOW_BACKGROUND_COLOR or FRIENDS_OFFLINE_BACKGROUND_COLOR
	button.NormalTexture:SetColorTexture(backgroundColor:GetRGBA())
	
	-- Set name in class color (Zeile 1, Teil 1)
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	local nameColor
	if stateData.isOnline and classInfo then
		nameColor = GetClassColorObj(classInfo.classFile)
	else
		nameColor = FRIENDS_GRAY_COLOR
	end
	button.CharacterData.Name:SetText(nameColor:WrapTextInColorCode(characterData.name))
	button.CharacterData.Name:SetWidth(math.min(button.CharacterData.Name:GetUnboundedStringWidth(), 150))
	
	-- Set level with "Lvl " prefix (Zeile 1, Teil 2)
	local levelColor = stateData.isOnline and NORMAL_FONT_COLOR or FRIENDS_GRAY_COLOR
	button.CharacterData.Level:SetText(levelColor:WrapTextInColorCode("Lvl " .. tostring(characterData.level)))
	button.CharacterData.Level:SetWidth(button.CharacterData.Level:GetUnboundedStringWidth())
	
	-- Hide class name (no longer needed)
	button.CharacterData.Class:SetText("")
	
	-- Update divider colors (only first divider between name and level is visible)
	if button.CharacterData.Dividers then
		for _, divider in ipairs(button.CharacterData.Dividers) do
			divider:SetVertexColor(levelColor:GetRGB())
		end
	end
	
	-- Set most recent interaction (Zeile 2)
	local mostRecentInteraction = interactionData.interactions and interactionData.interactions[1]
	if mostRecentInteraction then
		button.CharacterData.MostRecentInteraction:SetText(mostRecentInteraction.description or "")
	else
		button.CharacterData.MostRecentInteraction:SetText("")
	end
	
	-- Set location (Zeile 3)
	button.CharacterData.Location:SetText(stateData.currentLocation or "")
	
	-- Update state icons
	button.StateIconContainer.PinDisplay:SetShown(stateData.pinExpirationDate ~= nil)
	if stateData.pinExpirationDate then
		-- Check if pin is nearing expiration
		local remainingDays = (stateData.pinExpirationDate - GetServerTime()) / SECONDS_PER_DAY
		local isNearingExpiration = remainingDays <= 7 -- Constants.RecentAlliesConsts.PIN_EXPIRATION_WARNING_DAYS
		local atlas = isNearingExpiration and "friendslist-recentallies-pin" or "friendslist-recentallies-pin-yellow"
		button.StateIconContainer.PinDisplay.Icon:SetAtlas(atlas, true)
	end
	
	button.StateIconContainer.FriendRequestPendingDisplay:SetShown(stateData.hasFriendRequestPending or false)
	
	-- Enable/disable party button based on online status
	button.PartyButton:SetEnabled(stateData.isOnline)
	
	-- Setup party button click handler
	button.PartyButton:SetScript("OnClick", function()
		if characterData and characterData.fullName then
			C_PartyInfo.InviteUnit(characterData.fullName)
		end
	end)
	
	-- Setup party button tooltip
	button.PartyButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_AddHighlightLine(GameTooltip, RECENT_ALLIES_PARTY_BUTTON_TOOLTIP or "Invite")
		if not self:IsEnabled() then
			GameTooltip_AddErrorLine(GameTooltip, RECENT_ALLIES_PARTY_BUTTON_OFFLINE_TOOLTIP or "Player is offline")
		end
		GameTooltip:Show()
	end)
	
	button.PartyButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Setup pin display tooltip
	if button.StateIconContainer.PinDisplay then
		button.StateIconContainer.PinDisplay:SetScript("OnEnter", function(self)
			if stateData.pinExpirationDate then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local timeUntilExpiration = math.max(stateData.pinExpirationDate - GetServerTime(), 1)
				local timeText = RecentAlliesUtil.GetFormattedTime(timeUntilExpiration)
				GameTooltip_AddHighlightLine(GameTooltip, string.format("Pin expires in %s", timeText))
				GameTooltip:Show()
			end
		end)
		
		button.StateIconContainer.PinDisplay:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

-- OnEnter handler for Recent Allies Entry
function BetterRecentAlliesEntry_OnEnter(button)
	if not button.elementData then return end
	
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	BetterRecentAlliesEntry_BuildTooltip(button, GameTooltip)
	GameTooltip:Show()
end

-- OnLeave handler for Recent Allies Entry
function BetterRecentAlliesEntry_OnLeave(button)
	GameTooltip:Hide()
end

-- Build tooltip for recent ally (RecentAlliesEntryMixin:BuildRecentAllyTooltip)
function BetterRecentAlliesEntry_BuildTooltip(button, tooltip)
	local elementData = button.elementData
	if not elementData then return end
	
	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData
	
	-- Character name
	GameTooltip_AddNormalLine(tooltip, characterData.fullName)
	
	-- Race and level
	local raceInfo = C_CreatureInfo.GetRaceInfo(characterData.raceID)
	if raceInfo then
		GameTooltip_AddHighlightLine(tooltip, string.format("Level %d %s", characterData.level, raceInfo.raceName))
	end
	
	-- Class
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	if classInfo then
		GameTooltip_AddHighlightLine(tooltip, classInfo.className)
	end
	
	-- Faction
	local factionInfo = C_CreatureInfo.GetFactionInfo(characterData.raceID)
	if factionInfo then
		GameTooltip_AddHighlightLine(tooltip, factionInfo.name)
	end
	
	-- Current location
	if stateData.currentLocation then
		GameTooltip_AddHighlightLine(tooltip, stateData.currentLocation)
	end
	
	-- Note
	if interactionData.note and interactionData.note ~= "" then
		GameTooltip_AddNormalLine(tooltip, string.format("Note: %s", interactionData.note))
	end
	
	-- Most recent interaction
	if interactionData.interactions and #interactionData.interactions > 0 then
		GameTooltip_AddBlankLineToTooltip(tooltip)
		local mostRecent = interactionData.interactions[1]
		GameTooltip_AddNormalLine(tooltip, "Recent Activity:")
		GameTooltip_AddHighlightLine(tooltip, mostRecent.description or "")
	end
end

-- Open context menu for recent ally
function BetterRecentAlliesEntry_OpenMenu(button)
	local elementData = button.elementData
	if not elementData then return end
	
	local recentAllyData = elementData
	local contextData = {
		recentAllyData = recentAllyData,
		name = recentAllyData.characterData.name,
		server = recentAllyData.characterData.realmName,
		guid = recentAllyData.characterData.guid,
		isOffline = not recentAllyData.stateData.isOnline,
	}
	
	-- Use appropriate menu based on online status
	local bestMenu = recentAllyData.stateData.isOnline and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE"
	
	-- Fallback to FRIEND menu if RECENT_ALLY not available
	if not UnitPopupMenus[bestMenu] then
		bestMenu = recentAllyData.stateData.isOnline and "FRIEND" or "FRIEND_OFFLINE"
	end
	
	UnitPopup_OpenMenu(bestMenu, contextData)
end

-- Update Recent Allies display (wrapper function)
function BetterRecentAlliesFrame_Update()
	local frame = BetterFriendsFrame
	if not frame or not frame.RecentAlliesFrame then return end
	
	-- Check if system is enabled
	if not C_RecentAllies or not C_RecentAllies.IsSystemEnabled() then
		if frame.RecentAlliesFrame.DescriptionText then
			frame.RecentAlliesFrame.DescriptionText:SetText("Recent Allies system is not available.")
		end
		return
	end
	
	BetterRecentAlliesFrame_Refresh(frame.RecentAlliesFrame, ScrollBoxConstants.RetainScrollPosition)
end

----------------------------------------
-- RECRUIT A FRIEND (RAF) FUNCTIONS (11.2.5)
----------------------------------------

-- RAF Constants
local RECRUIT_HEIGHT = 34
local DIVIDER_HEIGHT = 16
local maxRecruits = 0
local maxRecruitMonths = 0
local maxRecruitLinkUses = 0
local daysInCycle = 0
local latestRAFVersion = 0

-- RAF Frame OnLoad
function BetterRAF_OnLoad(frame)
	if not C_RecruitAFriend then
		print("BetterFriendlist: RAF system not available")
		return
	end
	
	-- Check if RAF is enabled
	frame.rafEnabled = C_RecruitAFriend.IsEnabled and C_RecruitAFriend.IsEnabled() or false
	frame.rafRecruitingEnabled = C_RecruitAFriend.IsRecruitingEnabled and C_RecruitAFriend.IsRecruitingEnabled() or false
	
	-- Register events
	frame:RegisterEvent("RAF_SYSTEM_ENABLED_STATUS")
	frame:RegisterEvent("RAF_RECRUITING_ENABLED_STATUS")
	frame:RegisterEvent("RAF_SYSTEM_INFO_UPDATED")
	frame:RegisterEvent("RAF_INFO_UPDATED")
	frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
	
	-- Set up no recruits text
	if frame.RecruitList and frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetText(RAF_NO_RECRUITS_DESC or "You have not recruited any friends yet.")
	end
	
	-- Set up ScrollBox
	if frame.RecruitList and frame.RecruitList.ScrollBox and frame.RecruitList.ScrollBar then
		local view = CreateScrollBoxListLinearView()
		view:SetElementExtentCalculator(function(dataIndex, elementData)
			return elementData.isDivider and DIVIDER_HEIGHT or RECRUIT_HEIGHT
		end)
		view:SetElementInitializer("BetterRecruitListButtonTemplate", function(button, elementData)
			BetterRecruitListButton_Init(button, elementData)
		end)
		ScrollUtil.InitScrollBoxListWithScrollBar(frame.RecruitList.ScrollBox, frame.RecruitList.ScrollBar, view)
	end
	
	-- Get RAF system info
	if C_RecruitAFriend.GetRAFSystemInfo then
		local rafSystemInfo = C_RecruitAFriend.GetRAFSystemInfo()
		BetterRAF_UpdateSystemInfo(rafSystemInfo)
	end
	
	-- Get RAF info
	if C_RecruitAFriend.GetRAFInfo then
		local rafInfo = C_RecruitAFriend.GetRAFInfo()
		BetterRAF_UpdateRAFInfo(frame, rafInfo)
	end
end

-- RAF Frame OnEvent
function BetterRAF_OnEvent(frame, event, ...)
	if event == "RAF_SYSTEM_ENABLED_STATUS" then
		local rafEnabled = ...
		frame.rafEnabled = rafEnabled
		if rafEnabled and C_RecruitAFriend.GetRAFInfo then
			BetterRAF_UpdateRAFInfo(frame, C_RecruitAFriend.GetRAFInfo())
		end
	elseif event == "RAF_RECRUITING_ENABLED_STATUS" then
		local rafRecruitingEnabled = ...
		frame.rafRecruitingEnabled = rafRecruitingEnabled
		if frame.RecruitmentButton then
			frame.RecruitmentButton:SetShown(rafRecruitingEnabled)
		end
	elseif event == "RAF_SYSTEM_INFO_UPDATED" then
		local rafSystemInfo = ...
		BetterRAF_UpdateSystemInfo(rafSystemInfo)
	elseif event == "RAF_INFO_UPDATED" then
		local rafInfo = ...
		BetterRAF_UpdateRAFInfo(frame, rafInfo)
	elseif event == "BN_FRIEND_INFO_CHANGED" then
		if frame.rafInfo and frame.rafInfo.recruits then
			BetterRAF_UpdateRecruitList(frame, frame.rafInfo.recruits)
		end
	end
end

-- RAF Frame OnHide
function BetterRAF_OnHide(frame)
	-- Hide splash frame if shown
	if frame.SplashFrame then
		frame.SplashFrame:Hide()
	end
end

-- Update RAF System Info
function BetterRAF_UpdateSystemInfo(rafSystemInfo)
	if rafSystemInfo then
		maxRecruits = rafSystemInfo.maxRecruits or 0
		maxRecruitMonths = rafSystemInfo.maxRecruitMonths or 0
		maxRecruitLinkUses = rafSystemInfo.maxRecruitmentUses or 0
		daysInCycle = rafSystemInfo.daysInCycle or 0
	end
end

-- Sort recruits by online status, version, and name
local function SortRecruits(a, b)
	if a.isOnline ~= b.isOnline then
		return a.isOnline
	else
		if a.versionRecruited ~= b.versionRecruited then
			return a.versionRecruited > b.versionRecruited
		end
		return (a.nameText or "") < (b.nameText or "")
	end
end

-- Process and sort recruits with divider logic
local function ProcessAndSortRecruits(recruits)
	local seenAccounts = {}
	local haveOnlineFriends = false
	local haveOfflineFriends = false
	
	-- Get account info for all recruits
	for _, recruitInfo in ipairs(recruits) do
		if C_BattleNet and C_BattleNet.GetAccountInfoByID then
			local accountInfo = C_BattleNet.GetAccountInfoByID(recruitInfo.bnetAccountID, recruitInfo.wowAccountGUID)
			
			if accountInfo and accountInfo.gameAccountInfo and not accountInfo.gameAccountInfo.isWowMobile then
				recruitInfo.isOnline = accountInfo.gameAccountInfo.isOnline
				recruitInfo.characterName = accountInfo.gameAccountInfo.characterName
				
				-- Get name and status
				if FriendsFrame_GetBNetAccountNameAndStatus then
					recruitInfo.nameText, recruitInfo.nameColor = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo)
				else
					recruitInfo.nameText = recruitInfo.battleTag or "Unknown"
					recruitInfo.nameColor = FRIENDS_GRAY_COLOR
				end
				
				if BNet_GetBNetAccountName then
					recruitInfo.plainName = BNet_GetBNetAccountName(accountInfo)
				else
					recruitInfo.plainName = recruitInfo.nameText
				end
			else
				-- No presence info yet
				recruitInfo.isOnline = false
				recruitInfo.nameText = BNet_GetTruncatedBattleTag and BNet_GetTruncatedBattleTag(recruitInfo.battleTag) or recruitInfo.battleTag or "Unknown"
				recruitInfo.plainName = recruitInfo.nameText
				recruitInfo.nameColor = FRIENDS_GRAY_COLOR
			end
			
			-- Handle pending recruits
			if recruitInfo.nameText == "" and RAF_PENDING_RECRUIT then
				recruitInfo.nameText = RAF_PENDING_RECRUIT
				recruitInfo.plainName = RAF_PENDING_RECRUIT
			end
			
			recruitInfo.accountInfo = accountInfo
			
			-- Track seen accounts
			if not seenAccounts[recruitInfo.bnetAccountID] then
				seenAccounts[recruitInfo.bnetAccountID] = 1
			else
				seenAccounts[recruitInfo.bnetAccountID] = seenAccounts[recruitInfo.bnetAccountID] + 1
			end
			
			recruitInfo.recruitIndex = seenAccounts[recruitInfo.bnetAccountID]
			
			if recruitInfo.isOnline then
				haveOnlineFriends = true
			else
				haveOfflineFriends = true
			end
		end
	end
	
	-- Append recruit index for multiple accounts
	for _, recruitInfo in ipairs(recruits) do
		if seenAccounts[recruitInfo.bnetAccountID] > 1 and not recruitInfo.characterName then
			if RAF_RECRUIT_NAME_MULTIPLE then
				recruitInfo.nameText = RAF_RECRUIT_NAME_MULTIPLE:format(recruitInfo.nameText, recruitInfo.recruitIndex)
			end
		end
	end
	
	-- Sort by online status, version, and name
	table.sort(recruits, SortRecruits)
	
	return haveOnlineFriends and haveOfflineFriends
end

-- Update Recruit List
function BetterRAF_UpdateRecruitList(frame, recruits)
	if not frame or not frame.RecruitList then return end
	
	local numRecruits = #recruits
	
	-- Show/hide no recruits message
	if frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetShown(numRecruits == 0)
	end
	
	-- Update header count
	if frame.RecruitList.Header and frame.RecruitList.Header.Count then
		frame.RecruitList.Header.Count:SetText(RAF_RECRUITED_FRIENDS_COUNT and RAF_RECRUITED_FRIENDS_COUNT:format(numRecruits, maxRecruits) or string.format("%d/%d", numRecruits, maxRecruits))
	end
	
	-- Process and sort recruits
	local needDivider = ProcessAndSortRecruits(recruits)
	
	-- Build data provider with divider
	local dataProvider = CreateDataProvider()
	for index = 1, numRecruits do
		local recruit = recruits[index]
		if needDivider and not recruit.isOnline then
			dataProvider:Insert({isDivider=true})
			needDivider = false
		end
		dataProvider:Insert(recruit)
	end
	
	-- Update ScrollBox
	if frame.RecruitList.ScrollBox then
		frame.RecruitList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- Update Next Reward Display
function BetterRAF_UpdateNextReward(frame, nextReward)
	if not frame or not frame.RewardClaiming then return end
	
	local rewardPanel = frame.RewardClaiming
	
	if not nextReward then
		if rewardPanel.EarnInfo then rewardPanel.EarnInfo:Hide() end
		if rewardPanel.NextRewardButton then rewardPanel.NextRewardButton:Hide() end
		if rewardPanel.NextRewardName then rewardPanel.NextRewardName:Hide() end
		return
	end
	
	-- Set earn info text
	if rewardPanel.EarnInfo then
		local earnText = ""
		if nextReward.canClaim then
			earnText = RAF_YOU_HAVE_EARNED or "You have earned:"
		elseif nextReward.monthCost and nextReward.monthCost > 1 then
			earnText = RAF_NEXT_REWARD_AFTER and RAF_NEXT_REWARD_AFTER:format(nextReward.monthCost - nextReward.availableInMonths, nextReward.monthCost) or "Next reward soon"
		elseif nextReward.monthsRequired == 0 then
			earnText = RAF_FIRST_REWARD or "First Reward:"
		else
			earnText = RAF_NEXT_REWARD or "Next Reward:"
		end
		rewardPanel.EarnInfo:SetText(earnText)
		rewardPanel.EarnInfo:Show()
	end
	
	-- Set reward icon
	if rewardPanel.NextRewardButton and nextReward.iconID then
		-- Apply circular mask (only once)
		if not rewardPanel.NextRewardButton.maskApplied then
			if rewardPanel.NextRewardButton.Icon and rewardPanel.NextRewardButton.IconOverlay and rewardPanel.NextRewardButton.CircleMask then
				rewardPanel.NextRewardButton.Icon:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.IconOverlay:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.maskApplied = true
			end
		end
		
		rewardPanel.NextRewardButton.Icon:SetTexture(nextReward.iconID)
		
		if not nextReward.canClaim then
			rewardPanel.NextRewardButton.Icon:SetDesaturated(true)
			rewardPanel.NextRewardButton.IconOverlay:Show()
		else
			rewardPanel.NextRewardButton.Icon:SetDesaturated(false)
			rewardPanel.NextRewardButton.IconOverlay:Hide()
		end
		rewardPanel.NextRewardButton:Show()
	end
	
	-- Set reward name
	if rewardPanel.NextRewardName and rewardPanel.NextRewardName.Text then
		local rewardName = ""
		if nextReward.petInfo and nextReward.petInfo.speciesName then
			rewardName = nextReward.petInfo.speciesName
		elseif nextReward.mountInfo and nextReward.mountInfo.mountID then
			rewardName = C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(nextReward.mountInfo.mountID) or "Mount"
		elseif nextReward.titleInfo and nextReward.titleInfo.titleMaskID then
			local titleName = TitleUtil.GetNameFromTitleMaskID and TitleUtil.GetNameFromTitleMaskID(nextReward.titleInfo.titleMaskID) or "Title"
			rewardName = RAF_REWARD_TITLE and RAF_REWARD_TITLE:format(titleName) or titleName
		else
			rewardName = RAF_BENEFIT4 or "Game Time"
		end
		
		rewardPanel.NextRewardName.Text:SetText(rewardName)
		
		-- Set color using the same method as Blizzard
		if nextReward.rewardType == Enum.RafRewardType.GameTime then
			rewardPanel.NextRewardName.Text:SetTextColor(HEIRLOOM_BLUE_COLOR:GetRGBA())
		else
			rewardPanel.NextRewardName.Text:SetTextColor(EPIC_PURPLE_COLOR:GetRGBA())
		end
		
		rewardPanel.NextRewardName:Show()
	end
end

-- Update RAF Info (main update function)
function BetterRAF_UpdateRAFInfo(frame, rafInfo)
	if not frame or not rafInfo then return end
	
	frame.rafInfo = rafInfo
	
	-- Store latest RAF version globally for recruit button logic
	if rafInfo.versions and rafInfo.versions[1] then
		latestRAFVersion = rafInfo.versions[1].rafVersion or 0
	end
	
	-- Update recruit list
	if rafInfo.recruits then
		BetterRAF_UpdateRecruitList(frame, rafInfo.recruits)
	end
	
	-- Update month count
	if frame.RewardClaiming and frame.RewardClaiming.MonthCount and frame.RewardClaiming.MonthCount.Text then
		local latestVersionInfo = rafInfo.versions and rafInfo.versions[1]
		if latestVersionInfo then
			local monthCount = latestVersionInfo.monthCount and latestVersionInfo.monthCount.lifetimeMonths or 0
			-- Format: "X Months Subscribed by Friends"
			local monthText = string.format(RAF_MONTH_COUNT or "%d Months Subscribed by Friends", monthCount)
			frame.RewardClaiming.MonthCount.Text:SetText(monthText)
			frame.RewardClaiming.MonthCount:Show()
		end
	end
	
	-- Update next reward
	local latestVersionInfo = rafInfo.versions and rafInfo.versions[1]
	if latestVersionInfo and latestVersionInfo.nextReward then
		BetterRAF_UpdateNextReward(frame, latestVersionInfo.nextReward)
	end
	
	-- Update claim button
	if frame.RewardClaiming and frame.RewardClaiming.ClaimOrViewRewardButton then
		local nextReward = latestVersionInfo and latestVersionInfo.nextReward
		local haveUnclaimedReward = nextReward and nextReward.canClaim
		
		if haveUnclaimedReward then
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(CLAIM_REWARD or "Claim Reward")
		else
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(RAF_VIEW_ALL_REWARDS or "View All Rewards")
		end
	end
end

-- Show RAF Splash Screen
function BetterRAF_ShowSplashScreen(frame)
	if not frame or not frame.SplashFrame then return end
	frame.SplashFrame:Show()
end

-- Recruit List Button Init
function BetterRecruitListButton_Init(button, elementData)
	if elementData.isDivider then
		BetterRecruitListButton_SetupDivider(button)
	else
		BetterRecruitListButton_SetupRecruit(button, elementData)
	end
end

-- Setup button as divider
function BetterRecruitListButton_SetupDivider(button)
	button.DividerTexture:Show()
	button.Background:Hide()
	button.Name:Hide()
	button.InfoText:Hide()
	button.Icon:Hide()
	
	for i = 1, #button.Activities do
		button.Activities[i]:Hide()
	end
	
	button:SetHeight(DIVIDER_HEIGHT)
	button:Disable()
	button.recruitInfo = nil
	button:Show()
end

-- Setup button as recruit
function BetterRecruitListButton_SetupRecruit(button, recruitInfo)
	button.DividerTexture:Hide()
	button.Background:Show()
	button.Name:Show()
	button.InfoText:Show()
	
	-- Always show Icon, but set different atlas based on RAF version
	local versionRecruited = recruitInfo.versionRecruited or 0
	
	-- Show legacy icon for older RAF versions, or current icon for current version
	if versionRecruited > 0 and versionRecruited < latestRAFVersion then
		-- Legacy RAF version - show legacy icon
		button.Icon:SetAtlas("recruitafriend_friendslist_v2_icon", true)
		button.Icon:Show()
	elseif versionRecruited == latestRAFVersion then
		-- Current RAF version - show current icon
		button.Icon:SetAtlas("recruitafriend_friendslist_v3_icon", true)
		button.Icon:Show()
	else
		-- No valid version - hide icon
		button.Icon:Hide()
	end
	
	button:SetHeight(RECRUIT_HEIGHT)
	button:Enable()
	button.recruitInfo = recruitInfo
	
	-- Set name with color
	if recruitInfo.nameText and recruitInfo.nameColor then
		button.Name:SetText(recruitInfo.nameText)
		button.Name:SetTextColor(recruitInfo.nameColor:GetRGB())
	end
	
	-- Set background color based on online status
	if recruitInfo.isOnline then
		button.Background:SetColorTexture(0.2, 0.4, 0.8, 0.3) -- Blue tint for online
		
		-- Set info text based on subscription status
		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Active then
			button.InfoText:SetText(RAF_ACTIVE_RECRUIT or "Active")
			button.InfoText:SetTextColor(GREEN_FONT_COLOR:GetRGB())
		elseif recruitInfo.subStatus == Enum.RafRecruitSubStatus.Trial then
			button.InfoText:SetText(RAF_TRIAL_RECRUIT or "Trial")
			button.InfoText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		else
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or "Inactive")
			button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		end
	else
		button.Background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR:GetRGBA())
		button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		
		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Inactive then
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or "Inactive")
		else
			-- Show last online time
			if recruitInfo.accountInfo and FriendsFrame_GetLastOnlineText then
				button.InfoText:SetText(FriendsFrame_GetLastOnlineText(recruitInfo.accountInfo))
			else
				button.InfoText:SetText(FRIENDS_LIST_OFFLINE or "Offline")
			end
		end
	end
	
	-- Update activities (always process all activity buttons to ensure they're hidden when no activities)
	for i = 1, #button.Activities do
		local activityInfo = recruitInfo.activities and recruitInfo.activities[i] or nil
		BetterRecruitActivityButton_Setup(button.Activities[i], activityInfo, recruitInfo)
	end
	
	button:Show()
end

-- Recruit List Button OnEnter
function BetterRecruitListButton_OnEnter(button)
	if not button.recruitInfo then return end
	
	local recruitInfo = button.recruitInfo
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	if recruitInfo.nameText and recruitInfo.nameColor then
		GameTooltip_SetTitle(GameTooltip, recruitInfo.nameText, recruitInfo.nameColor)
	end
	
	local wrap = true
	if maxRecruitMonths > 0 then
		GameTooltip_AddNormalLine(GameTooltip, RAF_RECRUIT_TOOLTIP_DESC and RAF_RECRUIT_TOOLTIP_DESC:format(maxRecruitMonths) or string.format("Up to %d months", maxRecruitMonths), wrap)
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
	end
	
	if recruitInfo.monthsRemaining then
		local usedMonths = math.max(maxRecruitMonths - recruitInfo.monthsRemaining, 0)
		GameTooltip_AddColoredLine(GameTooltip, RAF_RECRUIT_TOOLTIP_MONTH_COUNT and RAF_RECRUIT_TOOLTIP_MONTH_COUNT:format(usedMonths, maxRecruitMonths) or string.format("%d / %d months", usedMonths, maxRecruitMonths), HIGHLIGHT_FONT_COLOR, wrap)
	end
	
	GameTooltip:Show()
end

-- Recruit List Button OnClick
function BetterRecruitListButton_OnClick(button, mouseButton)
	if mouseButton == "RightButton" and button.recruitInfo then
		local recruitInfo = button.recruitInfo
		local contextData = {
			name = recruitInfo.plainName,
			bnetIDAccount = recruitInfo.bnetAccountID,
			wowAccountGUID = recruitInfo.wowAccountGUID,
			isRafRecruit = true,
		}
		
		if recruitInfo.accountInfo and recruitInfo.accountInfo.gameAccountInfo then
			contextData.guid = recruitInfo.accountInfo.gameAccountInfo.playerGuid
		end
		
		UnitPopup_OpenMenu("RAF_RECRUIT", contextData)
	end
end

-- Recruit Activity Button Setup
function BetterRecruitActivityButton_Setup(button, activityInfo, recruitInfo)
	if not activityInfo then
		button:Hide()
		return
	end
	
	button.activityInfo = activityInfo
	button.recruitInfo = recruitInfo
	
	BetterRecruitActivityButton_UpdateIcon(button)
	button:Show()
end

-- Recruit Activity Button Update Icon
function BetterRecruitActivityButton_UpdateIcon(button)
	if not button.activityInfo then return end
	
	local useAtlasSize = true
	if button:IsMouseOver() then
		if button.activityInfo.state == Enum.RafRecruitActivityState.RewardClaimed then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_CursorOverChecked", useAtlasSize)
		else
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_CursorOver", useAtlasSize)
		end
	else
		if button.activityInfo.state == Enum.RafRecruitActivityState.Incomplete then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_ActiveChest", useAtlasSize)
		elseif button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_OpenChest", useAtlasSize)
		else
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_ClaimedChest", useAtlasSize)
		end
	end
end

-- Recruit Activity Button OnClick
function BetterRecruitActivityButton_OnClick(button)
	if not button.activityInfo or not button.recruitInfo then return end
	
	if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
		if C_RecruitAFriend.ClaimActivityReward then
			if C_RecruitAFriend.ClaimActivityReward(button.activityInfo.activityID, button.recruitInfo.acceptanceID) then
				PlaySound(SOUNDKIT.RAF_RECRUIT_REWARD_CLAIM)
				C_Timer.After(0.3, function()
					button.activityInfo.state = Enum.RafRecruitActivityState.RewardClaimed
					BetterRecruitActivityButton_UpdateIcon(button)
				end)
			end
		end
	end
end

-- Recruit Activity Button OnEnter
function BetterRecruitActivityButton_OnEnter(button)
	if not button.activityInfo or not button.recruitInfo then return end
	
	-- Enable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:EnableDrawLayer("HIGHLIGHT")
	end
	
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	local wrap = true
	local questName = button.activityInfo.rewardQuestID and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(button.activityInfo.rewardQuestID)
	
	if questName then
		GameTooltip_SetTitle(GameTooltip, questName, nil, wrap)
		GameTooltip:SetMinimumWidth(300)
		GameTooltip_AddNormalLine(GameTooltip, RAF_RECRUIT_ACTIVITY_DESCRIPTION and RAF_RECRUIT_ACTIVITY_DESCRIPTION:format(button.recruitInfo.nameText) or "Activity", true)
		
		if C_RecruitAFriend.GetRecruitActivityRequirementsText then
			local reqTextLines = C_RecruitAFriend.GetRecruitActivityRequirementsText(button.activityInfo.activityID, button.recruitInfo.acceptanceID)
			for i = 1, #reqTextLines do
				GameTooltip_AddColoredLine(GameTooltip, reqTextLines[i], HIGHLIGHT_FONT_COLOR, wrap)
			end
		end
		
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		
		if button.activityInfo.state == Enum.RafRecruitActivityState.Incomplete then
			GameTooltip_AddNormalLine(GameTooltip, QUEST_REWARDS or "Rewards", wrap)
		else
			GameTooltip_AddNormalLine(GameTooltip, YOU_EARNED_LABEL or "You earned:", wrap)
		end
		
		if GameTooltip_AddQuestRewardsToTooltip then
			GameTooltip_AddQuestRewardsToTooltip(GameTooltip, button.activityInfo.rewardQuestID, TOOLTIP_QUEST_REWARDS_STYLE_NONE)
		end
		
		if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
			GameTooltip_AddBlankLineToTooltip(GameTooltip)
			GameTooltip_AddInstructionLine(GameTooltip, CLICK_CHEST_TO_CLAIM_REWARD or "Click to claim reward", wrap)
		end
	else
		GameTooltip_SetTitle(GameTooltip, RETRIEVING_DATA or "Loading...", RED_FONT_COLOR)
	end
	
	BetterRecruitActivityButton_UpdateIcon(button)
	GameTooltip:Show()
end

-- Recruit Activity Button OnLeave
function BetterRecruitActivityButton_OnLeave(button)
	-- Disable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:DisableDrawLayer("HIGHLIGHT")
	end
	
	GameTooltip_Hide()
	BetterRecruitActivityButton_UpdateIcon(button)
end

-- Next Reward Button OnClick
function BetterRAF_NextRewardButton_OnClick(button, mouseButton)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	
	if IsModifiedClick("DRESSUP") and nextReward then
		if nextReward.petInfo and DressUpBattlePet then
			DressUpBattlePet(nextReward.petInfo.creatureID, nextReward.petInfo.displayID, nextReward.petInfo.speciesID)
		elseif nextReward.mountInfo and DressUpMount then
			DressUpMount(nextReward.mountInfo.mountID)
		elseif nextReward.appearanceInfo and DressUpVisual then
			DressUpVisual(nextReward.appearanceInfo.appearanceID)
		end
	elseif IsModifiedClick("CHATLINK") and nextReward and nextReward.itemID then
		local name, link = C_Item.GetItemInfo(nextReward.itemID)
		if not ChatEdit_InsertLink(link) then
			ChatFrame_OpenChat(link)
		end
	end
end

-- Next Reward Button OnEnter
function BetterRAF_NextRewardButton_OnEnter(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	
	if not nextReward or not nextReward.itemID then return end
	
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetItemByID(nextReward.itemID)
	
	if IsModifiedClick("DRESSUP") then
		ShowInspectCursor()
	else
		ResetCursor()
	end
end

-- Claim or View Reward Button OnClick
function BetterRAF_ClaimOrViewRewardButton_OnClick(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	local haveUnclaimedReward = nextReward and nextReward.canClaim
	
	if haveUnclaimedReward then
		-- Claim reward
		if nextReward.rewardType == Enum.RafRewardType.GameTime then
			-- Game time requires special dialog
			PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
			if WowTokenRedemptionFrame_ShowDialog then
				WowTokenRedemptionFrame_ShowDialog("RAF_GAME_TIME_REDEEM_CONFIRMATION_SUB", latestVersionInfo.rafVersion)
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Recruit-A-Friend:|r Game time reward available. Use the Blizzard UI to claim.", 1, 1, 0)
			end
		elseif C_RecruitAFriend.ClaimNextReward then
			if C_RecruitAFriend.ClaimNextReward() then
				PlaySound(SOUNDKIT.RAF_RECRUIT_REWARD_CLAIM)
				-- Refresh RAF info after claim
				C_Timer.After(0.5, function()
					local rafInfo = C_RecruitAFriend.GetRAFInfo()
					if rafInfo then
						BetterRAF_UpdateRAFInfo(frame, rafInfo)
					end
				end)
			end
		end
	else
		-- Show all rewards list
		if RecruitAFriendRewardsFrame then
			-- Load Blizzard's RAF addon if not already loaded
			if not RecruitAFriendFrame then
				LoadAddOn("Blizzard_RecruitAFriend")
			end
			
			-- Ensure Blizzard's RecruitAFriendFrame has the data it needs
			if RecruitAFriendFrame and frame.rafInfo then
				-- Store RAF info in Blizzard's frame (critical for RewardsFrame to work!)
				RecruitAFriendFrame.rafInfo = frame.rafInfo
				RecruitAFriendFrame.rafEnabled = true
				
				-- ALWAYS set selected RAF version to the latest when opening rewards
				-- This ensures we start with the correct version every time
				if frame.rafInfo.versions and #frame.rafInfo.versions > 0 then
					local latestVersion = frame.rafInfo.versions[1].rafVersion
					RecruitAFriendFrame.selectedRAFVersion = latestVersion
				end
				
				-- Store rafSystemInfo if we have it
				if frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.rafSystemInfo then
					RecruitAFriendFrame.rafSystemInfo = frame.RecruitAFriendFrame.rafSystemInfo
				end
				
				-- CRITICAL: Override/Initialize the TriggerEvent system
				-- Even if it exists, we need to ensure it works with our setup
				local originalTriggerEvent = RecruitAFriendFrame.TriggerEvent
				
				RecruitAFriendFrame.callbacks = RecruitAFriendFrame.callbacks or {}
				
				RecruitAFriendFrame.TriggerEvent = function(self, event, ...)
					-- Handle NewRewardTabSelected event
					if event == "NewRewardTabSelected" then
						local newRAFVersion = ...
						self.selectedRAFVersion = newRAFVersion
						
						-- Refresh the rewards display
						if RecruitAFriendRewardsFrame and RecruitAFriendRewardsFrame.Refresh then
							RecruitAFriendRewardsFrame:Refresh()
						end
					elseif event == "RewardsListOpened" then
						-- Set to latest version when opening
						if self.rafInfo and self.rafInfo.versions and #self.rafInfo.versions > 0 then
							self.selectedRAFVersion = self.rafInfo.versions[1].rafVersion
						end
					end
					
					-- Call original if it was a real function (not our mock)
					if originalTriggerEvent and originalTriggerEvent ~= self.TriggerEvent then
						originalTriggerEvent(self, event, ...)
					end
				end
				
				-- Add helper methods that RecruitAFriendFrame needs (always set these)
				RecruitAFriendFrame.GetSelectedRAFVersion = function(self)
					return self.selectedRAFVersion
				end
				
				RecruitAFriendFrame.GetSelectedRAFVersionInfo = function(self)
					if not self.rafInfo or not self.rafInfo.versions then 
						return nil 
					end
					for _, versionInfo in ipairs(self.rafInfo.versions) do
						if versionInfo.rafVersion == self.selectedRAFVersion then
							return versionInfo
						end
					end
					return self.rafInfo.versions[1] -- Fallback to first version
				end
				
				RecruitAFriendFrame.GetLatestRAFVersion = function(self)
					if self.rafInfo and self.rafInfo.versions and #self.rafInfo.versions > 0 then
						return self.rafInfo.versions[1].rafVersion
					end
					return nil
				end
				
				RecruitAFriendFrame.IsLegacyRAFVersion = function(self, rafVersion)
					-- All versions except the latest are considered legacy
					local latestVersion = self:GetLatestRAFVersion()
					return rafVersion ~= latestVersion
				end
				
				RecruitAFriendFrame.GetRAFVersionInfo = function(self, rafVersion)
					if not self.rafInfo or not self.rafInfo.versions then return nil end
					for _, versionInfo in ipairs(self.rafInfo.versions) do
						if versionInfo.rafVersion == rafVersion then
							return versionInfo
						end
					end
					return nil
				end
			end
			
			-- Use Blizzard's rewards frame
			if RecruitAFriendRewardsFrame:IsShown() then
				RecruitAFriendRewardsFrame:Hide()
			else
				-- Set up tabs and refresh (Blizzard does this in UpdateRAFInfo)
				if frame.rafInfo then
					if RecruitAFriendRewardsFrame.SetUpTabs then
						RecruitAFriendRewardsFrame:SetUpTabs(frame.rafInfo)
					end
					
					if RecruitAFriendRewardsFrame.Refresh then
						RecruitAFriendRewardsFrame:Refresh()
					end
				end
				
				RecruitAFriendRewardsFrame:Show()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
				StaticPopupSpecial_Hide(RecruitAFriendRecruitmentFrame)
			end
		else
			-- Fallback: Display rewards info in chat
			BetterRAF_DisplayRewardsInChat(frame.rafInfo)
		end
	end
end

-- Display RAF Rewards info in chat (fallback method)
function BetterRAF_DisplayRewardsInChat(rafInfo)
	if not rafInfo or not rafInfo.versions then return end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== Recruit-A-Friend Rewards ===|r", 1, 1, 0)
	
	for versionIndex, versionInfo in ipairs(rafInfo.versions) do
		local versionName = versionIndex == 1 and "Current RAF" or "Legacy RAF v" .. versionInfo.rafVersion
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff" .. versionName .. ":|r", 0.8, 0.8, 1)
		DEFAULT_CHAT_FRAME:AddMessage("  Months earned: " .. (versionInfo.monthCount and versionInfo.monthCount.lifetimeMonths or 0), 1, 1, 1)
		DEFAULT_CHAT_FRAME:AddMessage("  Recruits: " .. (versionInfo.numRecruits or 0), 1, 1, 1)
		
		if versionInfo.rewards and #versionInfo.rewards > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("  Available Rewards:", 1, 1, 1)
			for i, reward in ipairs(versionInfo.rewards) do
				if i <= 5 then -- Show first 5 rewards
					local status = reward.claimed and "|cff00ff00[Claimed]|r" or 
								   reward.canClaim and "|cffffff00[Can Claim]|r" or
								   reward.canAfford and "|cffff9900[Affordable]|r" or
								   "|cff666666[Locked]|r"
					local rewardName = "Reward"
					if reward.petInfo then
						rewardName = reward.petInfo.speciesName or "Pet"
					elseif reward.mountInfo then
						local mountName = C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(reward.mountInfo.mountID)
						rewardName = mountName or "Mount"
					elseif reward.titleInfo then
						rewardName = TitleUtil.GetNameFromTitleMaskID and TitleUtil.GetNameFromTitleMaskID(reward.titleInfo.titleMaskID) or "Title"
					end
					DEFAULT_CHAT_FRAME:AddMessage("    - " .. rewardName .. " " .. status .. " (" .. reward.monthsRequired .. " months)", 0.9, 0.9, 0.9)
				end
			end
			if #versionInfo.rewards > 5 then
				DEFAULT_CHAT_FRAME:AddMessage("    ... and " .. (#versionInfo.rewards - 5) .. " more rewards", 0.7, 0.7, 0.7)
			end
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Use the in-game Recruit-A-Friend interface for full details.|r", 1, 1, 0)
end

-- Recruitment Button OnClick (1:1 from Blizzard)
function BetterRAF_RecruitmentButton_OnClick(button)
	-- Ensure RecruitAFriendRecruitmentFrame is loaded
	if not RecruitAFriendRecruitmentFrame then
		LoadAddOn("Blizzard_RecruitAFriend")
	end
	
	if not RecruitAFriendRecruitmentFrame then
		print("Error: Could not load RecruitAFriendRecruitmentFrame")
		return
	end
	
	-- Toggle recruitment frame (exact Blizzard logic)
	if RecruitAFriendRecruitmentFrame:IsShown() then
		StaticPopupSpecial_Hide(RecruitAFriendRecruitmentFrame)
	else
		C_RecruitAFriend.RequestUpdatedRecruitmentInfo()
		
		-- Hide rewards frame if shown
		if RecruitAFriendRewardsFrame then
			RecruitAFriendRewardsFrame:Hide()
		end
		
		StaticPopupSpecial_Show(RecruitAFriendRecruitmentFrame)
	end
end
