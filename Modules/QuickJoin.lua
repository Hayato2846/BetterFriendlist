--[[
	QuickJoin Module
	
	Provides Social Queue functionality for joining friends' groups.
	Based on Blizzard's QuickJoin system (Interface/AddOns/Blizzard_QuickJoin).
	
	Features:
	- List all available groups from friends (C_SocialQueue.GetAllGroups)
	- Display activity type, member count, roles needed
	- Request to join groups (C_SocialQueue.RequestToJoin)
	- Quick Join Toast Button (minimap notification)
	- Auto-update on SOCIAL_QUEUE_UPDATE event
	
	Public API:
	- QuickJoin:Initialize()
	- QuickJoin:Update()
	- QuickJoin:GetAvailableGroups()
	- QuickJoin:RequestToJoin(guid, tank, healer, damage)
	- QuickJoin:GetGroupInfo(guid)
]]

local addonName, BFL = ...

-- Create Module
local QuickJoin = {}
BFL:RegisterModule("QuickJoin", QuickJoin)

-- Constants
local MAX_DISPLAYED_MEMBERS = 8  -- Maximum members shown in group list
local THROTTLE_INTERVAL = 1.0     -- Update throttle (max once per second)
local TOAST_DURATION = 8.0        -- Toast button display duration

-- Module State
QuickJoin.initialized = false
QuickJoin.availableGroups = {}    -- List of available group GUIDs
QuickJoin.groupCache = {}         -- Cached group information
QuickJoin.lastUpdate = 0          -- Timestamp of last update
QuickJoin.updateQueued = false    -- Pending update flag
QuickJoin.config = nil            -- Social Queue Config (from C_SocialQueue.GetConfig)
QuickJoin.mockGroups = {}         -- Mock groups for testing (added to real groups)
QuickJoin.selectedGUID = nil      -- Currently selected group GUID
QuickJoin.selectedButtons = {}    -- Track button selection states

--[[
	Helper: GetFriendInfoByGUID
	C_FriendList.GetFriendInfoByGUID() does NOT exist in WoW 11.2!
	We need to iterate through all friends and match by GUID.
]]
local function GetFriendInfoByGUID(guid)
	if not guid then return nil end
	
	local numFriends = C_FriendList.GetNumFriends()
	for i = 1, numFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.guid == guid then
			return friendInfo
		end
	end
	
	return nil
end

--[[
	Blizzard's SocialQueueUtil_GetRelationshipInfo (1:1 copy from SocialQueue.lua)
	Returns: name, colorCode, relationshipType, playerLink
	
	Extended to support Mock Groups:
	- Mock group member GUIDs are checked against QuickJoin.mockGroups
	- Returns green color for mock members to distinguish them from real players
]]
function BetterFriendlist_GetRelationshipInfo(guid, missingNameFallback, clubId)
	-- Check if this is a mock group member first
	if QuickJoin and QuickJoin.mockGroups then
		for groupGUID, mockGroup in pairs(QuickJoin.mockGroups) do
			if mockGroup.members then
				for _, member in ipairs(mockGroup.members) do
					if member.guid == guid then
						-- Found mock member! Return with green color (mock indicator)
						local name = member.name or member.memberName or "MockPlayer"
						-- Use green for mock members to distinguish them
						local mockColor = "|cff00ff00"  -- Green
						return name, mockColor, "mock", nil
					end
				end
			end
		end
	end
	
	-- Check BattleNet friend first
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid)
	if accountInfo then
		local accountName = accountInfo.accountName
		local gameAccountInfo = accountInfo.gameAccountInfo
		
		-- CHANGED: Always use accountName (BNet display name), not character name
		-- This ensures consistent display in Quick Join member list
		local name = accountName
		
		local playerLink = GetBNPlayerLink(name, accountInfo.bnetAccountID, accountInfo.gameAccountInfo.playerGUID, 0, FRIENDS_BNET_NAME_COLOR_CODE)
		return name, FRIENDS_BNET_NAME_COLOR_CODE, "bnfriend", playerLink
	end
	
	-- Check WoW friend
	local friendInfo = GetFriendInfoByGUID(guid)
	if friendInfo and friendInfo.connected then
		local name = friendInfo.name
		if name then
			local playerLink = GetPlayerLink(name, ("[%s]"):format(name))
			return name, FRIENDS_WOW_NAME_COLOR_CODE, "wowfriend", playerLink
		end
	end
	
	-- Check guild member
	if IsInGuild() then
		local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player")
		for i = 1, GetNumGuildMembers() do
			local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, memberGuid = GetGuildRosterInfo(i)
			if memberGuid == guid and name then
				local playerLink = GetPlayerLink(name, ("[%s]"):format(name))
				return name, FRIENDS_WOW_NAME_COLOR_CODE, "guild", playerLink
			end
		end
	end
	
	-- Check club (community) member
	local clubInfo = clubId and C_Club.GetClubInfo(clubId) or nil
	if clubInfo then
		local memberInfo = C_Club.GetMemberInfoForSelf(clubId)
		if memberInfo and memberInfo.name then
			local name = memberInfo.name
			local playerLink = GetPlayerLink(name, ("[%s]"):format(name))
			return name, FRIENDS_WOW_NAME_COLOR_CODE, "club", playerLink
		end
	end
	
	-- Fallback: No relationship found
	local name = missingNameFallback or UNKNOWN
	return name, FRIENDS_WOW_NAME_COLOR_CODE, nil, nil
end

--[[ 
	Public API 
]]

-- Initialize the QuickJoin module
function QuickJoin:Initialize()
	if self.initialized then
		return
	end
	
	-- Get Social Queue Configuration
	self.config = C_SocialQueue.GetConfig()
	
	if not self.config then
		-- Set fallback config
		self.config = {
			TOASTS_DISABLED = false,
			TOAST_DURATION = TOAST_DURATION,
			DELAY_DURATION = 0.5,
		}
	end
	
	-- Register Events
	self:RegisterEvents()
	
	-- Initial update
	self:Update()
	
	-- Start periodic cache cleanup (every 5 minutes)
	C_Timer.NewTicker(300, function()
		self:CleanupCache()
	end)
	
	self.initialized = true
end

-- Cleanup old cache entries (called every 5 minutes)
function QuickJoin:CleanupCache()
	local currentTime = GetTime()
	local maxAge = 300 -- 5 minutes
	local cleaned = 0
	
	for guid, cached in pairs(self.groupCache) do
		if currentTime - cached.timestamp > maxAge then
			self.groupCache[guid] = nil
			cleaned = cleaned + 1
		end
	end
	
	if cleaned > 0 then
		BFL:DebugPrint("QuickJoin: Cleaned up", cleaned, "old cache entries")
	end
end

-- Update available groups list
function QuickJoin:Update(forceUpdate)
	-- Throttle updates (max once per second) unless forced
	local now = GetTime()
	if not forceUpdate and now - self.lastUpdate < THROTTLE_INTERVAL then
		if not self.updateQueued then
			self.updateQueued = true
			C_Timer.After(THROTTLE_INTERVAL, function()
				self:Update()
			end)
		end
		return
	end
	
	self.lastUpdate = now
	self.updateQueued = false
	
	-- Get all available groups from Social Queue API
	local groups = C_SocialQueue.GetAllGroups(false, false) or {}
	
	-- Add mock groups to the list (if any exist)
	if next(self.mockGroups) ~= nil then
		for guid, _ in pairs(self.mockGroups) do
			table.insert(groups, guid)
		end
	end
	
	-- Clear old data
	self.availableGroups = {}
	
	-- Build group cache
	for i, groupGUID in ipairs(groups) do
		local groupInfo = self:GetGroupInfo(groupGUID)
		
		if groupInfo and groupInfo.canJoin and groupInfo.numQueues > 0 then
			table.insert(self.availableGroups, groupGUID)
		end
	end
	
	-- Sort groups by priority (BNet friends first, then WoW friends, then guild)
	table.sort(self.availableGroups, function(a, b)
		return self:GetGroupPriority(a) > self:GetGroupPriority(b)
	end)
	
	-- Fire callback for UI update
	if self.onUpdateCallback then
		self.onUpdateCallback(self.availableGroups)
	end
	
	-- Update tab counter
	if BetterFriendsFrame and BetterFriendsFrame_UpdateQuickJoinTab then
		BetterFriendsFrame_UpdateQuickJoinTab()
	end
end

-- Get information about a specific group
function QuickJoin:GetGroupInfo(groupGUID)
	if not groupGUID then
		return nil
	end
	
	-- Check for mock data first (mock groups are always prioritized)
	if self.mockGroups[groupGUID] then
		return self.mockGroups[groupGUID]
	end
	
	-- Try to get cached info first
	local cached = self.groupCache[groupGUID]
	if cached and (GetTime() - cached.timestamp < 2.0) then
		return cached.info
	end
	
	-- Get fresh info from API
	local canJoin, numQueues, needTank, needHealer, needDamage, isSoloQueueParty, questSessionActive, leaderGUID = C_SocialQueue.GetGroupInfo(groupGUID)
	
	if not canJoin then
		return nil
	end
	
	local info = {
		canJoin = canJoin,
		numQueues = numQueues,
		needTank = needTank,
		needHealer = needHealer,
		needDamage = needDamage,
		isSoloQueueParty = isSoloQueueParty,
		questSessionActive = questSessionActive,
		leaderGUID = leaderGUID,
		members = C_SocialQueue.GetGroupMembers(groupGUID),
		queues = C_SocialQueue.GetGroupQueues(groupGUID),
		requestedToJoin = C_SocialQueue.GetGroupForPlayer(groupGUID) ~= nil,  -- Check if already requested
		numMembers = 0,  -- Will be calculated below
		leaderName = UNKNOWN,
		activityName = UNKNOWN,
		activityIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
		queueInfo = "",
	}
	
	-- Calculate member count
	if info.members then
		info.numMembers = #info.members
		
		-- Get leader name
		if info.members and #info.members > 0 and info.members[1] then
			local member = info.members[1]
			
			-- Try multiple name fields
			local rawName = member.clubName or member.name or member.memberName
			
			-- If still no name, try to get name from GUID
			if not rawName and member.guid then
				local accountInfo = C_BattleNet.GetAccountInfoByGUID(member.guid)
				if accountInfo and accountInfo.accountName then
					rawName = accountInfo.accountName
				else
					local friendInfo = GetFriendInfoByGUID(member.guid)
					if friendInfo and friendInfo.name then
						rawName = friendInfo.name
					end
				end
			end
			
			-- Protected strings are safe to use directly
			if rawName then
				info.leaderName = rawName
			else
				info.leaderName = "Player"
			end
		end
	end
	
	-- Get GROUP TITLE from queues (NOT activity name!)
	-- Blizzard's approach: Display searchResultInfo.name for LFG List (the group's custom title)
	if info.queues and #info.queues > 0 and info.queues[1] then
		local queueData = info.queues[1].queueData
		if queueData then
			-- Get group title/name based on queue type
			if queueData.queueType == "lfglist" and queueData.lfgListID then
				-- For LFG List: Blizzard displays searchResultInfo.name (the custom group title)
				-- NOT the activity name! (QuickJoin.lua doesn't even use activities)
				local searchResultInfo = C_LFGList.GetSearchResultInfo(queueData.lfgListID)
				if searchResultInfo then
				
				-- Protected strings are safe to use directly
				info.groupTitle = searchResultInfo.name
				
				-- IMPORTANT: Use numMembers from searchResultInfo, NOT from members array!
				-- members array only contains visible members (usually just leader)
				if searchResultInfo.numMembers then
					info.numMembers = searchResultInfo.numMembers
				end
				
				-- IMPORTANT: Use leaderName and leaderFactionGroup from searchResultInfo!
				if searchResultInfo.leaderName then
					info.leaderName = searchResultInfo.leaderName
				end
				if searchResultInfo.leaderFactionGroup then
					info.leaderFactionGroup = searchResultInfo.leaderFactionGroup
				end
				
				-- Get role distribution using C_LFGList.GetSearchResultMemberCounts
				local memberCounts = C_LFGList.GetSearchResultMemberCounts(queueData.lfgListID)
				if memberCounts then
					info.numTanks = memberCounts.TANK or 0
					info.numHealers = memberCounts.HEALER or 0
					info.numDPS = memberCounts.DAMAGER or 0
				else
					info.numTanks = 0
					info.numHealers = 0
					info.numDPS = 0
				end
				
				-- Activity name für Tooltip
				if searchResultInfo.activityIDs and #searchResultInfo.activityIDs > 0 and searchResultInfo.activityIDs[1] then
					info.activityName = C_LFGList.GetActivityFullName(searchResultInfo.activityIDs[1], nil, searchResultInfo.isWarMode)
				end
				
				-- Playstyle für Tooltip
				if searchResultInfo.playstyle then
					info.playstyle = searchResultInfo.playstyle
				end
			else
				-- Fallback if search result not available
				info.groupTitle = "LFG Group"
			end
			elseif queueData.queueType == "pvp" then
				info.groupTitle = "PvP"
			elseif queueData.queueType == "dungeon" or queueData.lfgDungeonID then
				-- Try to get dungeon name
				if queueData.lfgDungeonID then
					local dungeonName = GetLFGDungeonInfo(queueData.lfgDungeonID)
					info.groupTitle = dungeonName or "Dungeon"
				else
					info.groupTitle = "Dungeon"
				end
			elseif queueData.queueType == "raid" then
				info.groupTitle = "Raid"
			else
				info.groupTitle = queueData.queueType or info.queues[1].name or UNKNOWN
			end
			
			-- Use generic icon for now (could be improved with queue-specific icons)
			info.activityIcon = "Interface\\Icons\\Achievement_General_StayClassy"
		end
		
		-- Build queue info string
		if #info.queues > 1 then
			info.queueInfo = string.format("%d activities", #info.queues)
		end
	end
	
	-- Cache the info
	self.groupCache[groupGUID] = {
		info = info,
		timestamp = GetTime()
	}
	
	return info
end

-- Get all available groups
function QuickJoin:GetAvailableGroups()
	return self.availableGroups
end

-- Request to join a group
function QuickJoin:RequestToJoin(groupGUID, applyAsTank, applyAsHealer, applyAsDamage)
	if not groupGUID then
		return false
	end
	
	-- Check if already in a group
	if IsInGroup() then
		UIErrorsFrame:AddMessage("You are already in a group!", 1.0, 0.1, 0.1, 1.0)
		return false
	end
	
	-- Check combat lockdown
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage("Cannot join groups while in combat!", 1.0, 0.1, 0.1, 1.0)
		return false
	end
	
	-- Default to all roles if none specified
	if not applyAsTank and not applyAsHealer and not applyAsDamage then
		applyAsTank = true
		applyAsHealer = true
		applyAsDamage = true
	end
	
	-- Handle mock groups (don't actually send request)
	if self.mockGroups[groupGUID] then
		UIErrorsFrame:AddMessage("|cff00ff00Mock join request sent (simulated only)", 0.1, 0.8, 1.0, 1.0)
		return true
	end
	
	local success = C_SocialQueue.RequestToJoin(groupGUID, applyAsTank, applyAsHealer, applyAsDamage)
	
	if not success then
		UIErrorsFrame:AddMessage(QUICK_JOIN_FAILED or "Quick Join request failed", 1.0, 0.1, 0.1, 1.0)
	end
	
	return success
end

-- Get priority for sorting groups (higher = more important)
function QuickJoin:GetGroupPriority(groupGUID)
	local members = C_SocialQueue.GetGroupMembers(groupGUID)
	if not members or #members == 0 then
		return 0
	end
	
	local priority = 0
	
	-- Sort members (leader first) - simple sort by checking if they're leader
	table.sort(members, function(a, b)
		-- Leader has isLeader flag or is first in original list
		return (a.isLeader or false) and not (b.isLeader or false)
	end)
	
	-- Check relationship with leader
	if not members or #members == 0 or not members[1] then
		return 0
	end
	local leaderGUID = members[1].guid
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(leaderGUID)
	
	if accountInfo then
		-- BNet friend (highest priority)
		priority = priority + 1000
	else
		-- Check for WoW friend
		local friendInfo = GetFriendInfoByGUID(leaderGUID)
		if friendInfo then
			priority = priority + 500
		else
			-- Check for guild member
			if IsInGuild() then
				local guildName = GetGuildInfo("player")
				local memberGuildName = GetGuildInfo("unit") -- TODO: Need proper unit token
				if guildName and memberGuildName and guildName == memberGuildName then
					priority = priority + 100
				end
			end
		end
	end
	
	return priority
end

-- QuickJoinEntry - Blizzard-style entry object with ApplyToFrame and CalculateHeight methods
local QuickJoinEntry = {}
QuickJoinEntry.__index = QuickJoinEntry

function QuickJoinEntry:New(guid, groupInfo)
	local entry = setmetatable({}, QuickJoinEntry)
	entry.guid = guid
	entry.groupInfo = groupInfo or {}
	entry.fontObject = UserScaledFontGameNormalSmall
	
	-- Parse display data
	entry.displayedMembers = {}
	entry.displayedQueues = {}
	entry.zombieMemberIndices = {}
	entry.zombieQueueIndices = {}
	
	-- Extract member data - use actual member info from groupInfo
	if groupInfo.members and #groupInfo.members > 0 then
		for i, member in ipairs(groupInfo.members) do
			-- Use leaderName from groupInfo for first member if available
			local name
			if i == 1 and groupInfo.leaderName then
				name = groupInfo.leaderName
			else
				name = member.name or member.memberName or UNKNOWN
			end
			
			entry.displayedMembers[i] = {
				guid = member.guid or guid,
				name = name,
				clubId = member.clubId
			}
		end
	else
		-- Fallback: Use leader name if no members array
		entry.displayedMembers[1] = {
			guid = guid,
			name = groupInfo.leaderName or groupInfo._mockLeaderName or UNKNOWN,
			clubId = nil
		}
	end
	
	-- Extract queue data - Store GROUP TITLE (not activity name!)
	if groupInfo.queues and #groupInfo.queues > 0 then
		for i, queue in ipairs(groupInfo.queues) do
			-- Use groupTitle from groupInfo (the custom group name, e.g., "Wo ist Hayato")
			-- Do NOT use activityName here - that's only for the tooltip!
			local groupTitle = groupInfo.groupTitle or groupInfo._mockActivityName or UNKNOWN
			
			entry.displayedQueues[i] = {
				queueData = {
					name = groupTitle,  -- Internal storage
					queueType = queue.queueData and queue.queueData.queueType or queue.queueType or "lfg"
				},
				-- CRITICAL: Blizzard caches the queue name (QuickJoin.lua:386-393)
				-- This is what gets displayed in the button!
				cachedQueueName = groupTitle,
				-- Extract role needs from groupInfo (returned by GetGroupInfo)
				-- These are used in the tooltip to show Available Roles
				needTank = groupInfo.needTank or false,
				needHealer = groupInfo.needHealer or false,
				needDamage = groupInfo.needDamage or false,
				isZombie = false -- Queue is active unless proven otherwise
			}
		end
	else
		-- Fallback: Create one queue entry with group title
		local groupTitle = groupInfo.groupTitle or groupInfo._mockActivityName or UNKNOWN
		entry.displayedQueues[1] = {
			queueData = {
				name = groupTitle,
				queueType = "lfg"
			},
			cachedQueueName = groupTitle,  -- CRITICAL: Cache the name!
			-- Use role needs from groupInfo for fallback too
			needTank = groupInfo.needTank or false,
			needHealer = groupInfo.needHealer or false,
			needDamage = groupInfo.needDamage or false,
			isZombie = false
		}
	end
	
	return entry
end

-- Apply entry data to button frame (Blizzard's HORIZONTAL layout)
-- Members (left) â†’ Icon (middle) â†’ Queues (right) ALL ON ONE LINE
function QuickJoinEntry:ApplyToFrame(frame)
	-- CRITICAL: Blizzard uses parentArray="Members" in XML for MemberName
	-- This makes frame.MemberName accessible as frame.Members[0]
	-- When i=1, frame.Members[i-1] = frame.Members[0] = frame.MemberName
	
	-- Members: Blizzard creates Members[] array dynamically (QuickJoin.lua:466-487)
	for i = 1, #self.displayedMembers do
		local member = self.displayedMembers[i]
		
		-- Blizzard's EXACT code (QuickJoin.lua:470-471):
		-- local name, color, relationship, playerLink = SocialQueueUtil_GetRelationshipInfo(self.displayedMembers[i].guid, nil, self.displayedMembers[i].clubId);
		local name, color, relationship, playerLink = BetterFriendlist_GetRelationshipInfo(member.guid, nil, member.clubId)
		
		-- Create/get the FontString for this member (EXACT Blizzard pattern)
		local nameObj = frame.Members[i]
		if not nameObj then
			nameObj = frame:CreateFontString(nil, "ARTWORK", "UserScaledFontGameNormalSmall")
			-- EXACT Blizzard code (QuickJoin.lua:473):
			-- nameObj:SetPoint("TOPLEFT", frame.Members[i-1], "BOTTOMLEFT", 0, -QUICK_JOIN_NAME_SEPARATION);
			-- When i=1, frame.Members[0] is frame.MemberName (because of parentArray in XML)
			nameObj:SetPoint("TOPLEFT", frame.Members[i-1], "BOTTOMLEFT", 0, -5) -- QUICK_JOIN_NAME_SEPARATION = 5
			frame.Members[i] = nameObj
		end
		
		nameObj.playerLink = playerLink
		nameObj.name = name
		
		-- WICHTIG: Verwende NAME für Anzeige, nicht playerLink!
		-- playerLink enthält die bnetAccountID (z.B. "41") statt dem Namen
		local displayName = name
		
		-- Apply color (QuickJoin.lua:480-485)
		if not self:CanJoin() then
			-- Disabled color if can't join
			name = string.format("%s%s|r", DISABLED_FONT_COLOR_CODE, displayName)
		else
			-- Use relationship color code
			name = string.format("%s%s|r", color, displayName)
		end
		
		nameObj:SetText(name)
		nameObj:Show()
	end
	
	-- Hide unused member FontStrings (QuickJoin.lua:488-490)
	for i = #self.displayedMembers + 1, #frame.Members do
		frame.Members[i]:Hide()
	end
	
	-- Queue Icon (MIDDLE, between members and queues) (QuickJoin.lua:492-497)
	local useGroupIcon = self.displayedQueues and #self.displayedQueues > 0 and self.displayedQueues[1] and self.displayedQueues[1].queueData and self.displayedQueues[1].queueData.queueType == "lfglist"
	if frame.Icon then
		frame.Icon:SetAtlas(useGroupIcon and "socialqueuing-icon-group" or "socialqueuing-icon-eye")
		-- Set height based on member names height (Blizzard: QuickJoin.lua:500)
		-- frame.Icon:SetHeight(math.max(17, frame.MemberName:GetHeight()))
		frame.Icon:SetHeight(math.max(17, frame.MemberName:GetHeight()))
		-- Width based on height (aspect ratio ~0.95)
		frame.Icon:SetWidth(math.max(16, frame.Icon:GetHeight() * 0.95))
		
		if self:CanJoin() then
			frame.Icon:SetDesaturation(0)
			frame.Icon:SetAlpha(0.9)
		else
			frame.Icon:SetDesaturation(1)
			frame.Icon:SetAlpha(0.3)
		end
	end
	
	-- CRITICAL: Blizzard positions QueueName ONCE in Lua (QuickJoin.lua:512)
	-- frame.QueueName:SetPoint("TOPLEFT", frame.MemberName, "TOPRIGHT", frame.Icon:GetWidth() + 4, 0);
	-- But we already do this in XML! So we only need to update it if icon width changed
	-- Actually, let's set it dynamically since icon size can change
	if frame.QueueName then
		frame.QueueName:ClearAllPoints()
		frame.QueueName:SetPoint("TOPLEFT", frame.MemberName, "TOPRIGHT", frame.Icon:GetWidth() + 4, 0)
	end
	
	-- Queues: Blizzard creates Queues[] array dynamically (QuickJoin.lua:512-537)
	for i = 1, #self.displayedQueues do
		local queue = self.displayedQueues[i]
		
		-- Create/get the FontString for this queue (EXACT Blizzard pattern)
		local queueObj = frame.Queues[i]
		if not queueObj then
			queueObj = frame:CreateFontString(nil, "ARTWORK", "UserScaledFontGameNormalSmall")
			-- EXACT Blizzard code (QuickJoin.lua:519):
			-- queueObj:SetPoint("TOPLEFT", frame.Queues[i-1], "BOTTOMLEFT", 0, -QUICK_JOIN_NAME_SEPARATION);
			-- When i=1, frame.Queues[0] is frame.QueueName (because of parentArray in XML)
			queueObj:SetPoint("TOPLEFT", frame.Queues[i-1], "BOTTOMLEFT", 0, -5) -- QUICK_JOIN_NAME_SEPARATION = 5
			frame.Queues[i] = queueObj
		end
		
	-- Blizzard gets the cachedQueueName (QuickJoin.lua:530)
	local queueName = queue.cachedQueueName
	
	if not queueName then
		-- This should never happen in Blizzard's code
		queueName = "Unknown Queue"
	else
		-- Blizzard wraps LFGList names in quotes (QuickJoin.lua:533-535)
		if queue.queueData.queueType == "lfglist" then
			queueName = string.format(LFG_LIST_IN_QUOTES, queueName)
		end
		
		-- Blizzard adds comma if not last queue (QuickJoin.lua:537-539)
		if i < #self.displayedQueues then
			queueName = queueName .. PLAYER_LIST_DELIMITER -- This is ", "
		end
		
		-- Apply disabled color if can't join (QuickJoin.lua:541-543)
		if not self:CanJoin() then
			queueName = DISABLED_FONT_COLOR_CODE .. queueName .. FONT_COLOR_CODE_CLOSE
		end
	end
		
		queueObj:SetText(queueName)
		queueObj:Show()
	end
	
	-- Hide unused queue FontStrings
	for i = #self.displayedQueues + 1, #frame.Queues do
		frame.Queues[i]:Hide()
	end
	
	-- Update button height (Blizzard's calculation - QuickJoin.lua:556-575)
	frame:SetHeight(self:CalculateHeight())
end

-- Calculate button height based on content (Blizzard's formula - QuickJoin.lua:556-575)
function QuickJoinEntry:CalculateHeight()
	local bufferHeight = 13
	local fontHeight = 12 -- UserScaledFontGameNormalSmall default height
	local separation = 5  -- QUICK_JOIN_NAME_SEPARATION
	
	-- Height = one line per member OR one line per queue (whichever is MORE)
	local height = fontHeight + separation
	local namesHeight = height * #self.displayedMembers
	local queuesHeight = height * math.min(#self.displayedQueues, 6) -- MAX_NUM_DISPLAYED_QUEUES = 6
	
	return bufferHeight + math.max(namesHeight, queuesHeight)
end

-- Check if group is joinable
function QuickJoinEntry:CanJoin()
	return self.groupInfo and self.groupInfo.canJoin ~= false
end

-- Apply entry to tooltip (EXACT Blizzard replication)
function QuickJoinEntry:ApplyToTooltip(tooltip)
	-- Blizzard's EXACT tooltip structure from LFGListUtil_SetSearchEntryTooltip (lines 4154-4312):
	-- Blizzard uses HELPER FUNCTIONS that apply colors:
	--   GameTooltip_AddHighlightLine() â†’ HIGHLIGHT_FONT_COLOR (1.0, 0.82, 0 = GOLD/YELLOW)
	--   GameTooltip_AddNormalLine() â†’ NORMAL_FONT_COLOR (1.0, 1.0, 1.0 = WHITE)
	-- 
	-- Colors:
	--   - Activity Name: HIGHLIGHT_FONT_COLOR (1.0, 0.82, 0 = gold/yellow)
	--   - Leader Name: WHITE (1, 1, 1)
	--   - Members count: HIGHLIGHT_FONT_COLOR (1.0, 0.82, 0 = gold/yellow)
	--   - Available Roles text: HIGHLIGHT_FONT_COLOR (1.0, 0.82, 0 = gold/yellow)
	--   - Comment: LFG_LIST_COMMENT_FONT_COLOR (0.6, 0.6, 0.6 = gray)
	
	local groupTitle = nil
	local activityName = nil
	local leaderName = nil
	local comment = nil
	local needTank, needHealer, needDamage = false, false, false
	
	-- Get group title from first queue (this is searchResultInfo.name - "Wo ist Hayato")
	if self.displayedQueues and #self.displayedQueues > 0 and self.displayedQueues[1] then
		local firstQueue = self.displayedQueues[1]
		if firstQueue.queueData and firstQueue.queueData.name then
			groupTitle = firstQueue.queueData.name
		end
		
		-- Get role needs from first queue
		needTank = firstQueue.needTank or false
		needHealer = firstQueue.needHealer or false
		needDamage = firstQueue.needDamage or false
		
		-- Get comment if available
		if firstQueue.queueData and firstQueue.queueData.comment then
			comment = firstQueue.queueData.comment
		end
	end
	
	-- Get activity name from groupInfo (this is activityFullName - "Molten Core")
	if self.groupInfo and self.groupInfo.activityName then
		activityName = self.groupInfo.activityName
	end
	
	-- Get leader name from first member (CHARACTER name-server, NOT account name!)
	-- Try groupInfo.leaderName first (more reliable)
	if self.groupInfo and self.groupInfo.leaderName then
		leaderName = self.groupInfo.leaderName
	elseif self.displayedMembers and #self.displayedMembers > 0 and self.displayedMembers[1] then
		local memberGuid = self.displayedMembers[1].guid
		if memberGuid then
			-- Check if this is a mock GUID first
			if self.groupInfo and self.groupInfo._mockLeaderName then
				leaderName = self.groupInfo._mockLeaderName
			else
				-- Get CHARACTER name and realm from GUID (like Blizzard does)
				local characterName, realmName = select(6, GetPlayerInfoByGUID(memberGuid))
				if characterName then
					-- Format: "Name-Server" or just "Name" if same server
					if realmName and realmName ~= "" and realmName ~= GetNormalizedRealmName() then
						leaderName = characterName .. "-" .. realmName
					else
						leaderName = characterName
					end
				end
			end
		end
	end
	
	-- SAFE fallbacks (don't use UNKNOWN!)
	if not groupTitle or groupTitle == "" then groupTitle = "???" end
	if not leaderName or leaderName == "" then leaderName = "???" end
	
	-- Line 1: Group Title (white, word-wrap enabled)
	tooltip:SetText(groupTitle, 1, 1, 1, true)
	
	-- Line 2: Activity Name (GOLD - HIGHLIGHT_FONT_COLOR: 1.0, 0.82, 0) - Only if different from group title and not empty
	if activityName and activityName ~= groupTitle and activityName ~= "" then
		tooltip:AddLine(activityName, 1.0, 0.82, 0)
	end
	
	-- Line 3: Playstyle (GREEN - 0.1, 1.0, 0.1) - Displayed directly under activity name
	-- Playstyle values: 1 = Standard, 2 = Hardcore (from C_LFGList constants)
	local playstyle = self.groupInfo and self.groupInfo.playstyle
	if playstyle then
		local playstyleName = nil
		if playstyle == 1 then
			playstyleName = "Standard" -- LFG_LIST_PLAYSTYLE_STANDARD
		elseif playstyle == 2 then
			playstyleName = "Hardcore" -- LFG_LIST_PLAYSTYLE_HARDCORE
		end
		if playstyleName then
			tooltip:AddLine(playstyleName, 0.1, 1.0, 0.1) -- Green color
		end
	end
	
	-- Comment (GRAY - 0.6, 0.6, 0.6) - Blizzard uses LFG_LIST_COMMENT_FONT_COLOR
	-- Format: "|cff44ccff[Comment]|r Comment text" (blue bracket, then gray text)
	if comment and comment ~= "" then
		tooltip:AddLine(string.format("[%s] %s", "Comment", comment), 0.6, 0.6, 0.6, true)
	end
	
	-- Blank line after title/activity/comment section, before leader
	tooltip:AddLine(" ")
	
	-- Line 3: Leader with faction indicator
	-- Format: "Leader: " (gold) + "Name-Server (Horde)" (white)
	-- Get leader faction from groupInfo
	local leaderFaction = self.groupInfo and self.groupInfo.leaderFactionGroup
	local playerFaction = UnitFactionGroup("player")
	
	-- Add faction indicator if different from player's faction
	local leaderNameWithFaction = leaderName
	if leaderFaction then
		local factionName = nil
		if leaderFaction == 0 then
			factionName = FACTION_HORDE
		elseif leaderFaction == 1 then
			factionName = FACTION_ALLIANCE
		end
		
		-- Show faction if different from player's faction
		if factionName and ((playerFaction == "Horde" and leaderFaction == 1) or (playerFaction == "Alliance" and leaderFaction == 0)) then
			leaderNameWithFaction = leaderName .. " (" .. factionName .. ")"
		end
	end
	
	-- Use color code format like MemberCount: gold "Leader:" + white name
	local leaderText = string.format("|cffffd100Leader:|r |cffffffff%s|r", leaderNameWithFaction)
	tooltip:AddLine(leaderText)
	
	-- Line 4: Empty line (spacing) - BLIZZARD ADDS THIS BEFORE MEMBER COUNT
	tooltip:AddLine(" ")
	
	-- Line 5: Member count with role breakdown
	-- Format: "Members: 5 (1/1/3)" with gold "Members:" and white count
	-- IMPORTANT: Get CURRENT member count from groupInfo, not cached displayedMembers!
	local memberCount = (self.groupInfo and self.groupInfo.numMembers) or #self.displayedMembers
	
	-- Get role counts from groupInfo (stored from C_LFGList.GetSearchResultMemberCounts)
	local tankCount = (self.groupInfo and self.groupInfo.numTanks) or 0
	local healerCount = (self.groupInfo and self.groupInfo.numHealers) or 0  
	local dpsCount = (self.groupInfo and self.groupInfo.numDPS) or 0
	
	local memberText = string.format("|cffffd100Members:|r |cffffffff%d (%d/%d/%d)|r", memberCount, tankCount, healerCount, dpsCount)
	tooltip:AddLine(memberText)
	
	-- Line 6: Empty line (spacing) - BLIZZARD ADDS THIS BEFORE AVAILABLE ROLES
	tooltip:AddLine(" ")
	
	-- Line 7: Available Roles label (GOLD - HIGHLIGHT_FONT_COLOR: 1.0, 0.82, 0)
	local roleIcons = ""
	if needTank then 
		roleIcons = roleIcons .. (INLINE_TANK_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:0:16:0:16|t")
	end
	if needHealer then 
		roleIcons = roleIcons .. (INLINE_HEALER_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:16:32:0:16|t")
	end
	if needDamage then 
		roleIcons = roleIcons .. (INLINE_DAMAGER_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:32:48:0:16|t")
	end
	
	if roleIcons ~= "" then
		-- FIXED: Remove extra colon - global already has one colon
		-- GOLD color (1.0, 0.82, 0) for "Available Roles:" text
		local rolesText = (QUICK_JOIN_TOOLTIP_AVAILABLE_ROLES or "Available Roles") .. " " .. roleIcons
		tooltip:AddLine(rolesText, 1.0, 0.82, 0)
	else
		tooltip:AddLine(QUICK_JOIN_TOOLTIP_NO_AVAILABLE_ROLES or "No available roles", 1, 1, 1)
	end
end

-- Get all available groups as QuickJoinEntry objects (public API)
function QuickJoin:GetEntries()
	local entries = {}
	local groups = self.availableGroups or {}
	
	for i, guid in ipairs(groups) do
		local groupInfo = self:GetGroupInfo(guid)
		if groupInfo then
			local entry = QuickJoinEntry:New(guid, groupInfo)
			table.insert(entries, entry)
		end
	end
	
	return entries
end

-- Get all available groups as GUIDs (legacy API for tab counter)
function QuickJoin:GetAllGroups()
	return self.availableGroups or {}
end

-- Set callback for UI updates
function QuickJoin:SetUpdateCallback(callback)
	self.onUpdateCallback = callback
end

--[[ 
	Event Handlers 
]]

function QuickJoin:RegisterEvents()
	-- Register for Social Queue events
	BFL:RegisterEventCallback("SOCIAL_QUEUE_UPDATE", function(groupGUID, numAddedItems)
		self:OnSocialQueueUpdate(groupGUID, numAddedItems)
	end, 10)
	
	BFL:RegisterEventCallback("SOCIAL_QUEUE_CONFIG_UPDATED", function()
		self:OnConfigUpdated()
	end, 10)
	
	BFL:RegisterEventCallback("GROUP_JOINED", function()
		self:OnGroupJoined()
	end, 10)
	
	BFL:RegisterEventCallback("GROUP_LEFT", function()
		self:OnGroupLeft()
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function()
		-- Friend came online, might have a group
		self:Update()
	end, 10)
	
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function()
		-- Friend went offline, remove their groups
		self:Update()
	end, 10)
end

function QuickJoin:OnSocialQueueUpdate(groupGUID, numAddedItems)
	-- Specific group updated
	if groupGUID then
		-- Invalidate cache for this group
		self.groupCache[groupGUID] = nil
		
		-- Check if group still exists
		local groupInfo = self:GetGroupInfo(groupGUID)
		if not groupInfo or not groupInfo.canJoin or groupInfo.numQueues == 0 then
			-- Group no longer available, remove from list
			for i, guid in ipairs(self.availableGroups) do
				if guid == groupGUID then
					table.remove(self.availableGroups, i)
					break
				end
			end
			
			-- Edge Case: Deselect group if it was selected and disappeared
			if self.selectedGUID == groupGUID then
				self:SelectGroup(nil)
			end
		end
	end
	
	-- Full update
	self:Update()
end

function QuickJoin:OnConfigUpdated()
	-- Reload configuration
	self.config = C_SocialQueue.GetConfig()
end

function QuickJoin:OnGroupJoined()
	-- Player joined a group, update available groups
	self:Update()
end

function QuickJoin:OnGroupLeft()
	-- Player left a group, update available groups
	self:Update()
end

--[[ 
	Utility Functions 
]]

-- Get formatted group name for display
function QuickJoin:GetGroupDisplayName(groupGUID)
	local members = C_SocialQueue.GetGroupMembers(groupGUID)
	if not members or #members == 0 then
		return UNKNOWNOBJECT or "Unknown Group"
	end
	
	-- Sort members (leader first)
	table.sort(members, function(a, b)
		return (a.isLeader or false) and not (b.isLeader or false)
	end)
	
	-- Get leader name
	if not members or #members == 0 or not members[1] then
		return UNKNOWNOBJECT or "Unknown Group"
	end
	
	local leaderName = members[1].clubName or members[1].name or "Unknown"
	local color = "|cffffffff"  -- Default white
	
	-- Try to determine relationship for color
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(members[1].guid)
	if accountInfo then
		color = FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff"  -- BNet blue
	else
		local friendInfo = GetFriendInfoByGUID(members[1].guid)
		if friendInfo then
			color = FRIENDS_WOW_NAME_COLOR_CODE or "|cff00ff00"  -- Friend green
		end
	end
	
	-- Format with extra players count
	if #members > 1 then
		leaderName = string.format("%s +%d", leaderName, #members - 1)
	end
	
	return string.format("%s%s|r", color, leaderName)
end

-- Get formatted queue name for display
function QuickJoin:GetQueueDisplayName(groupGUID)
	local queues = C_SocialQueue.GetGroupQueues(groupGUID)
	if not queues or #queues == 0 or not queues[1] then
		return "No Queue"
	end
	
	-- Get queue name from first queue
	local queueName = "Unknown Activity"
	local queueData = queues[1].queueData
	
	if queueData then
		if queueData.queueType == "lfglist" and queueData.lfgListID then
			local activityInfo = C_LFGList.GetActivityInfoTable(queueData.lfgListID)
			if activityInfo then
				queueName = activityInfo.fullName or activityInfo.shortName or "LFG Activity"
			else
				queueName = "LFG Activity"
			end
		elseif queueData.queueType == "pvp" then
			queueName = "PvP"
		elseif queueData.queueType == "dungeon" then
			queueName = "Dungeon"
		elseif queueData.queueType == "raid" then
			queueName = "Raid"
		else
			queueName = queueData.queueType or "Unknown Activity"
		end
	end
	
	-- Add extra queue count if multiple
	if #queues > 1 then
		queueName = string.format("%s +%d", queueName, #queues - 1)
	end
	
	return queueName
end

--[[ 
	Mock Data System (Debug/Testing Only)
]]

-- Create a mock group for testing
function QuickJoin:CreateMockGroup(leaderName, activityName, numMembers, needTank, needHealer, needDamage, queueType, activityType, comment)
	leaderName = leaderName or "TestPlayer"
	activityName = activityName or "Heroic Dungeon"
	numMembers = math.min(numMembers or 2, 2)  -- Maximum 2 members to avoid visual overload
	needTank = needTank ~= false  -- default true
	needHealer = needHealer ~= false
	needDamage = needDamage ~= false
	queueType = queueType or "lfglist"  -- default to lfglist (group icon + quotes)
	activityType = activityType or activityName  -- Default to activityName if not specified
	comment = comment or ""  -- Optional comment text
	
	-- Generate unique GUID
	local guid = string.format("MockGroup-%d-%s", math.random(10000, 99999), leaderName)
	
	-- Mock player names - varied to show different relationship types
	local mockNames = {
		"Anduin", "Thrall", "Jaina", "Sylvanas", "Varian",
		"Velen", "Malfurion", "Tyrande", "Genn", "Alleria"
	}
	
	-- Create mock members
	local members = {}
	for i = 1, numMembers do
		local memberName = (i == 1) and leaderName or mockNames[i] or ("Spieler" .. i)
		table.insert(members, {
			guid = string.format("Player-00000000-%08X", math.random(1, 999999)),
			name = memberName,
			memberName = memberName,
			clubId = nil,
		})
	end
	
	-- Create mock queue with specified type
	local queues = {
		{
			clientID = math.random(1000, 9999),
			eligible = true,
			needTank = needTank,
			needHealer = needHealer,
			needDamage = needDamage,
			isAutoAccept = false,
			queueData = {
				queueType = queueType,  -- Use specified queue type
				activityID = 1234,
				lfgListID = (queueType == "lfglist") and math.random(10000, 99999) or nil,  -- Only for lfglist
				name = activityName,  -- Group title
				comment = comment,  -- Optional comment
			}
		}
	}
	
	-- Store mock group with ALL required fields
	self.mockGroups[guid] = {
		canJoin = true,
		numQueues = 1,
		needTank = needTank,  -- FIXED: Use needTank not needsTank to match Blizzard API!
		needHealer = needHealer,  -- FIXED: Use needHealer not needsHealer
		needDamage = needDamage,  -- FIXED: Use needDamage not needsDPS
		isSoloQueueParty = false,
		questSessionActive = false,
		leaderGUID = (members and #members > 0 and members[1]) and members[1].guid or "Unknown",
		members = members,
		queues = queues,
		requestedToJoin = false,
		numMembers = numMembers,
		leaderName = leaderName,
		-- IMPORTANT: For LFG List, this is the GROUP TITLE (not activity name!)
		-- Blizzard displays searchResultInfo.name, which is the custom group name
		groupTitle = activityName,  -- This is the custom group title, e.g. "M+ Gruppe sucht DD"
		activityName = activityType,  -- This is the activity type for tooltip, e.g. "Mythic+ Dungeon"
		activityIcon = "Interface\\Icons\\Achievement_Boss_Murmur",
		queueInfo = "",
		-- Mock-specific fields
		_mockLeaderName = leaderName,
		_mockActivityName = activityName,
	}
	
	print(string.format("|cff00ff00BFL QuickJoin Mock:|r Created group '%s' - %s (%d members)", guid, activityName, numMembers))
	return guid
end

-- Remove a mock group
function QuickJoin:RemoveMockGroup(guid)
	if self.mockGroups[guid] then
		self.mockGroups[guid] = nil
		print(string.format("|cff00ff00BFL QuickJoin Mock:|r Removed group '%s'", guid))
		self:Update()
		return true
	end
	return false
end

-- Clear all mock groups
function QuickJoin:ClearMockGroups()
	local count = 0
	for guid, _ in pairs(self.mockGroups) do
		count = count + 1
	end
	self.mockGroups = {}
	print(string.format("|cff00ff00BFL QuickJoin Mock:|r Cleared %d mock groups", count))
	self:Update()
end

-- Get mock group display name
function QuickJoin:GetMockGroupDisplayName(guid)
	local mockGroup = self.mockGroups[guid]
	if not mockGroup then
		return self:GetGroupDisplayName(guid)
	end
	
	local leaderName = mockGroup._mockLeaderName or "Unknown"
	local numMembers = mockGroup.members and #mockGroup.members or 1
	
	if numMembers > 1 then
		return string.format("|cff00ff00%s|r +%d", leaderName, numMembers - 1)
	else
		return string.format("|cff00ff00%s|r", leaderName)
	end
end

-- Get mock queue display name
function QuickJoin:GetMockQueueDisplayName(guid)
	local mockGroup = self.mockGroups[guid]
	if not mockGroup then
		return self:GetQueueDisplayName(guid)
	end
	
	return mockGroup._mockActivityName or "Unknown Activity"
end

-- Slash command handler
SLASH_BFLQUICKJOIN1 = "/bflqj"
SLASH_BFLQUICKJOIN2 = "/bflquickjoin"
SlashCmdList["BFLQUICKJOIN"] = function(msg)
	local args = {}
	for word in msg:gmatch("%S+") do
		table.insert(args, word)
	end
	
	local cmd = args[1] and args[1]:lower() or "help"
	
	if cmd == "mock" then
		-- Create mock groups showcasing all different queue types and display variants
		-- Create MANY groups to test ScrollBar functionality
		QuickJoin:ClearMockGroups()
		
		-- Stop any existing mock update timer
		if QuickJoin.mockUpdateTimer then
			QuickJoin.mockUpdateTimer:Cancel()
			QuickJoin.mockUpdateTimer = nil
		end
		
		-- LFGList groups (group icon + quotes)
		QuickJoin:CreateMockGroup("Shadowmeld", "M+ Gruppe sucht DD", 2, true, false, true, "lfglist", "Mythic+ Dungeon", "Need experienced DPS for +20 keys")
		QuickJoin:CreateMockGroup("Anduin", "M+ NW +22 Timing", 1, true, true, false, "lfglist", "Mythic+ Dungeon", "2.8k+ rio only")
		QuickJoin:CreateMockGroup("Varian", "M+ Mists Weekly", 2, false, true, true, "lfglist", "Mythic+ Dungeon", "Chill key completion")
		QuickJoin:CreateMockGroup("Alleria", "Keys for Vault", 1, true, false, true, "lfglist", "Mythic+ Dungeon", "Any level, just for vault")
		QuickJoin:CreateMockGroup("Genn", "M+ BRH +20", 2, false, true, true, "lfglist", "Mythic+ Dungeon", "Push to 2k rio")
		
		-- LFG dungeon groups (eye icon, no quotes)
		QuickJoin:CreateMockGroup("Thrall", "Random HC Dungeon", 1, false, true, true, "lfg", "Heroic Dungeon", "Chill run, all welcome")
		QuickJoin:CreateMockGroup("Jaina", "Normal Dungeon", 2, true, false, false, "lfg", "Normal Dungeon", "Quick daily")
		QuickJoin:CreateMockGroup("Sylvanas", "Timewalking", 1, false, true, true, "lfg", "Timewalking Dungeon", "Badge farming")
		
		-- PVP groups (eye icon, no quotes)
		QuickJoin:CreateMockGroup("Malfurion", "Rated BG 2400+", 2, true, true, false, "pvp", "Rated Battleground", "Pushing rating, voice required")
		QuickJoin:CreateMockGroup("Tyrande", "Random BG", 1, false, false, true, "pvp", "Battleground", "Just for fun")
		QuickJoin:CreateMockGroup("Velen", "Arena 3v3", 2, true, true, true, "pvp", "Arena", "Practice session")
		
		-- Raid groups
		QuickJoin:CreateMockGroup("Khadgar", "Nerub-ar Palace Normal", 2, true, true, true, "lfglist", "Raid", "Full clear, AOTC optional")
		
		QuickJoin:Update(true)  -- Force update (skip throttle)
		
		-- Start dynamic MemberCount update timer (every 3 seconds)
		QuickJoin.mockUpdateTimer = C_Timer.NewTicker(3, function()
			local updated = false
			for guid, group in pairs(QuickJoin.mockGroups) do
				-- Randomly change member count (1-2 members, max 5 for raids)
				local maxMembers = (group.activityName == "Raid") and 5 or 2
				local newCount = math.random(1, maxMembers)
				if newCount ~= group.numMembers then
					group.numMembers = newCount
					-- Update members array
					while #group.members < newCount do
						local mockNames = {"Anduin", "Thrall", "Jaina", "Sylvanas", "Varian", "Velen", "Malfurion", "Tyrande", "Genn", "Alleria"}
						local memberName = mockNames[#group.members + 1] or ("Player" .. (#group.members + 1))
						table.insert(group.members, {
							guid = string.format("Player-00000000-%08X", math.random(1, 999999)),
							name = memberName,
							memberName = memberName,
							clubId = nil,
						})
					end
					while #group.members > newCount do
						table.remove(group.members)
					end
					updated = true
					print(string.format("|cff00ff00Mock Update:|r %s now has %d members", group.leaderName, newCount))
				end
			end
			if updated then
				QuickJoin:Update(true)  -- Force update to refresh UI
			end
		end)
		
		-- Debug: Show what we created
		local groups = QuickJoin:GetAllGroups()
		print("|cff00ff00BFL QuickJoin:|r Created 12 mock groups (total groups: " .. #groups .. ")")
		print("|cff00ff00BFL QuickJoin:|r Mock timer started - member counts will change every 3 seconds")
		
		-- Manually trigger UI update if frame exists
		if BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame then
			local qjFrame = BetterFriendsFrame.QuickJoinFrame
			if qjFrame.QuickJoin then
				BetterQuickJoinFrame_Update(qjFrame)
			end
		end
		
	elseif cmd == "add" then
		-- Add a custom mock group
		local leaderName = args[2] or "Player"
		local activityName = args[3] or "Dungeon"
		local numMembers = tonumber(args[4]) or 3
		local guid = QuickJoin:CreateMockGroup(leaderName, activityName, numMembers)
		QuickJoin:Update(true)  -- Force update (skip throttle)
		
	elseif cmd == "clear" then
		-- Stop mock update timer
		if QuickJoin.mockUpdateTimer then
			QuickJoin.mockUpdateTimer:Cancel()
			QuickJoin.mockUpdateTimer = nil
			print("|cff00ff00BFL QuickJoin:|r Mock timer stopped")
		end
		-- Clear all mock groups
		QuickJoin:ClearMockGroups()
		
	elseif cmd == "list" then
		-- List all mock groups
		print("|cff00ff00BFL QuickJoin Mock Groups:|r")
		local count = 0
		for guid, group in pairs(QuickJoin.mockGroups) do
			count = count + 1
			print(string.format("  %d. %s - %s (%d members)", count, group._mockLeaderName, group._mockActivityName, #group.members))
		end
		if count == 0 then
			print("  No mock groups (use '/bflqj mock' to create test groups)")
		end
		
	else
		-- Help
		print("|cff00ff00BFL QuickJoin Commands:|r")
		print("  |cffffcc00/bflqj mock|r - Add 3 test groups to Quick Join list")
		print("  |cffffcc00/bflqj add <name> <activity> <members>|r - Add custom mock group")
		print("  |cffffcc00/bflqj list|r - List all mock groups")
		print("  |cffffcc00/bflqj clear|r - Remove all mock groups")
		print("  |cffffcc00/bflqj help|r - Show this help")
		print("")
		print("|cff888888Mock groups are added to real Quick Join entries and marked with green color.|r")
	end
end

--[[
	SelectGroup - Select a group for joining
	@param guid - Group GUID to select (nil to deselect)
]]
function QuickJoin:SelectGroup(guid)
	local oldGUID = self.selectedGUID
	self.selectedGUID = guid
	
	-- Update button visuals
	if oldGUID then
		self:UpdateButtonSelection(oldGUID, false)
	end
	if guid then
		self:UpdateButtonSelection(guid, true)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	
	-- Update Join button state
	self:UpdateJoinButtonState()
end

--[[
	GetSelectedGroup - Get currently selected group
	@return guid - Selected group GUID or nil
]]
function QuickJoin:GetSelectedGroup()
	return self.selectedGUID
end

--[[
	UpdateButtonSelection - Update a button's selection visual
	@param guid - Group GUID
	@param selected - true to mark selected, false to deselect
]]
function QuickJoin:UpdateButtonSelection(guid, selected)
	if self.selectedButtons[guid] then
		local button = self.selectedButtons[guid]
		if button.Selected then
			button.Selected:SetShown(selected)
		end
		-- Don't manipulate Highlight here - it's controlled by OnEnter/OnLeave
	end
end

--[[
	UpdateJoinButtonState - Enable/disable Join button based on state
]]
function QuickJoin:UpdateJoinButtonState()
	local frame = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	if not frame or not frame.ContentInset or not frame.ContentInset.JoinQueueButton then return end
	
	local button = frame.ContentInset.JoinQueueButton
	
	-- Check if in group
	if IsInGroup(LE_PARTY_CATEGORY_HOME) then
		button:Disable()
		button.tooltip = QUICK_JOIN_ALREADY_IN_PARTY
		return
	end
	
	-- Check if group selected
	if not self.selectedGUID then
		button:Disable()
		button.tooltip = nil
		return
	end
	
	-- Check if group still exists
	local groupInfo = self:GetGroupInfo(self.selectedGUID)
	if not groupInfo then
		button:Disable()
		button.tooltip = nil
		return
	end
	
	-- Enable button
	button:Enable()
	button.tooltip = nil
	
	-- Set button text based on activity type
	if groupInfo.lfgListInfo then
		button:SetText(SIGN_UP)
	else
		button:SetText(JOIN_QUEUE)
	end
end

--[[
	JoinQueue - Attempt to join the selected group
	Handles edge cases:
	- Group no longer exists
	- Already in a group
	- In combat lockdown
	- Missing dialog frames
]]
function QuickJoin:JoinQueue()
	if not self.selectedGUID then return end
	
	-- Edge Case: Group disappeared since selection
	local groupInfo = self:GetGroupInfo(self.selectedGUID)
	if not groupInfo then
		UIErrorsFrame:AddMessage(ERR_PARTY_NOT_FOUND or "Group is no longer available.", 1.0, 0.1, 0.1, 1.0)
		self:SelectGroup(nil)
		return
	end
	
	-- Edge Case: Already in a group (double-check, button should be disabled)
	if IsInGroup(LE_PARTY_CATEGORY_HOME) then
		UIErrorsFrame:AddMessage(ALREADY_IN_GROUP or "You are already in a group.", 1.0, 0.1, 0.1, 1.0)
		return
	end
	
	-- Edge Case: Combat lockdown (double-check, button should be disabled)
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT or "Cannot join groups in combat.", 1.0, 0.1, 0.1, 1.0)
		return
	end
	
	-- Check if LFG List group
	if groupInfo.lfgListInfo then
		-- Show LFG List application dialog
		if LFGListApplicationDialog and LFGListApplicationDialog_Show then
			LFGListApplicationDialog_Show(LFGListApplicationDialog, groupInfo.lfgListInfo.queueData.lfgListID)
		else
			UIErrorsFrame:AddMessage("LFG List dialog not available.", 1.0, 0.1, 0.1, 1.0)
		end
	else
		-- Show role selection dialog for regular group
		if BetterQuickJoinRoleSelectionFrame then
			BetterQuickJoinRoleSelectionFrame:ShowForGroup(self.selectedGUID)
		else
			UIErrorsFrame:AddMessage("Role selection dialog not available.", 1.0, 0.1, 0.1, 1.0)
		end
	end
end

--[[
	OpenContextMenu - Show right-click context menu for a group
	@param guid - Group GUID
	@param anchorFrame - Frame to anchor menu to
]]
function QuickJoin:OpenContextMenu(guid, anchorFrame)
	if not guid then return end
	
	local groupInfo = self:GetGroupInfo(guid)
	if not groupInfo or not groupInfo.members or #groupInfo.members == 0 then
		return
	end
	
	-- Get first member (leader) for context
	if not groupInfo.members[1] then return end
	local leaderInfo = groupInfo.members[1]
	if not leaderInfo then return end
	
	-- Create context menu
	MenuUtil.CreateContextMenu(anchorFrame, function(owner, rootDescription)
		-- Title: Leader name
		rootDescription:CreateTitle(leaderInfo.name or UNKNOWN)
		
		-- Whisper button
		rootDescription:CreateButton(WHISPER, function()
			if leaderInfo.playerLink then
				local link, text = LinkUtil.SplitLink(leaderInfo.playerLink)
				SetItemRef(link, text, "LeftButton")
			end
		end)
	end)
end

-- Export module
BFL.QuickJoin = QuickJoin
