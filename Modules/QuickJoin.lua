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

-- Dirty flag: Set when data changes while frame is hidden
local needsRenderOnShow = false
local updateTimer = nil

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
	-- 1. Check if this is a mock group member first (BetterFriendlist-specific)
	if QuickJoin and QuickJoin.mockGroups then
		for groupGUID, mockGroup in pairs(QuickJoin.mockGroups) do
			if mockGroup.members then
				for _, member in ipairs(mockGroup.members) do
					if member.guid == guid then
						local name = member.name or member.memberName or "MockPlayer"
						local mockColor = "|cff00ff00"  -- Green for mock members
						return name, mockColor, "mock", nil
					end
				end
			end
		end
	end
	
	-- 2. Check BattleNet friend (like Blizzard)
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid)
	if accountInfo then
		local accountName = accountInfo.accountName
		local playerLink = GetBNPlayerLink(accountName, accountName, accountInfo.bnetAccountID, 0, 0, 0)
		return accountName, FRIENDS_BNET_NAME_COLOR_CODE, "bnfriend", playerLink
	end
	
	-- 3. CRITICAL FIX: GetPlayerInfoByGUID fallback (like Blizzard's SocialQueueUtil_GetRelationshipInfo)
	-- This fixes "Unknown" name display for players without direct relationship
	local name, normalizedRealmName = select(6, GetPlayerInfoByGUID(guid))
	name = name or missingNameFallback
	
	local hasName = name ~= nil
	if not hasName then
		name = UNKNOWNOBJECT
	elseif normalizedRealmName and normalizedRealmName ~= "" then
		name = FULL_PLAYER_NAME:format(name, normalizedRealmName)
	end
	
	local linkName = name
	local playerLink
	
	if hasName then
		playerLink = GetPlayerLink(linkName, name)
	end
	
	-- 4. Check WoW friend (with already determined name)
	if C_FriendList.IsFriend(guid) then
		return name, FRIENDS_WOW_NAME_COLOR_CODE, "wowfriend", playerLink
	end
	
	-- 5. Check guild member (with already determined name)
	if IsGuildMember(guid) then
		return name, RGBTableToColorCode(ChatTypeInfo.GUILD), "guild", playerLink
	end
	
	-- 6. Check club/community (with already determined name) - FIX: Don't use GetMemberInfoForSelf!
	local clubInfo = clubId and C_Club.GetClubInfo(clubId) or nil
	if clubInfo then
		return name, FRIENDS_WOW_NAME_COLOR_CODE, "club", playerLink
	end
	
	-- 7. Final fallback (name is already set by GetPlayerInfoByGUID)
	return name, FRIENDS_WOW_NAME_COLOR_CODE, nil, playerLink
end

--[[
	Blizzard's SocialQueueUtil_SortGroupMembers (1:1 copy from SocialQueue.lua)
	Sorts group members by relationship priority: BNet > WoW Friend > Guild > Club > Unknown
	This ensures the most relevant member (usually leader/friend) appears first
]]
local relationshipPriorityOrdering = {
	["bnfriend"] = 1,
	["wowfriend"] = 2,
	["guild"] = 3,
	["club"] = 4,
}

local function BetterFriendlist_SortGroupMembers(members)
	if not members then return members end
	
	table.sort(members, function(lhs, rhs)
		local lhsName, _, lhsRelationship = BetterFriendlist_GetRelationshipInfo(lhs.guid, nil, lhs.clubId)
		local rhsName, _, rhsRelationship = BetterFriendlist_GetRelationshipInfo(rhs.guid, nil, rhs.clubId)
		
		-- Sort by relationship priority first (lower = higher priority)
		if lhsRelationship ~= rhsRelationship then
			local lhsPriority = lhsRelationship and relationshipPriorityOrdering[lhsRelationship] or 10
			local rhsPriority = rhsRelationship and relationshipPriorityOrdering[rhsRelationship] or 10
			return lhsPriority < rhsPriority
		end
		
		-- Same relationship type: sort alphabetically by name
		return strcmputf8i(lhsName or "", rhsName or "") < 0
	end)
	
	return members
end

--[[
	Blizzard's SocialQueueUtil_HasRelationshipWithLeader (1:1 copy from SocialQueue.lua)
	Checks if the player has a relationship with the group leader
	Used for auto-accept logic in tooltips
]]
local function BetterFriendlist_HasRelationshipWithLeader(partyGuid)
	local leaderGuid = select(8, C_SocialQueue.GetGroupInfo(partyGuid))
	if leaderGuid then
		local _, _, relationship = BetterFriendlist_GetRelationshipInfo(leaderGuid)
		return relationship ~= nil
	end
	return false
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
	
	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function()
			if needsRenderOnShow then
				-- Only trigger update if we are on the QuickJoin tab
				if BetterFriendsFrame.QuickJoinFrame and BetterFriendsFrame.QuickJoinFrame:IsShown() then
					self:Update(true)
					needsRenderOnShow = false
				end
			end
		end)
	end
	
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
	-- Visibility Optimization:
	-- If the frame (or the QuickJoin tab) is hidden, don't rebuild the list.
	if not forceUpdate and (not BetterFriendsFrame or not BetterFriendsFrame:IsShown() or not BetterFriendsFrame.QuickJoinFrame or not BetterFriendsFrame.QuickJoinFrame:IsShown()) then
		needsRenderOnShow = true
		return
	end

	-- Event Coalescing (Micro-Throttling)
	if not forceUpdate and updateTimer then
		return
	end
	
	if not forceUpdate then
		updateTimer = C_Timer.After(0, function()
			updateTimer = nil
			self:Update(true)
		end)
		return
	end
	
	self.lastUpdate = GetTime()
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
		
		-- FIX: Explicitly exclude player's own group (defense in depth)
		-- API should return canJoin=false for own group, but this ensures it
		local leaderGUID = groupInfo and groupInfo.leaderGUID
		local isOwnGroup = leaderGUID and C_AccountInfo.IsGUIDRelatedToLocalAccount(leaderGUID)
		
		if groupInfo and groupInfo.canJoin and groupInfo.numQueues > 0 and not isOwnGroup then
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
		
		-- Get leader name using BetterFriendlist_GetRelationshipInfo (like Blizzard's SocialQueueUtil_GetHeaderName)
		-- CRITICAL: C_SocialQueue.GetGroupMembers() returns SocialQueuePlayerInfo with only 'guid' and 'clubId' fields!
		-- Fields like 'name', 'memberName', 'clubName' do NOT exist - must use GetRelationshipInfo to resolve name from GUID
		if info.members and #info.members > 0 and info.members[1] then
			local member = info.members[1]
			
			-- Use BetterFriendlist_GetRelationshipInfo to get name from GUID (exactly like Blizzard)
			-- This function internally uses C_BattleNet.GetAccountInfoByGUID and GetPlayerInfoByGUID
			if member.guid then
				local name, color, relationship, playerLink = BetterFriendlist_GetRelationshipInfo(member.guid, nil, member.clubId)
				if name and name ~= UNKNOWNOBJECT then
					info.leaderName = name
				end
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
				
				-- Auto-Accept (Blizzard's isAutoAccept for auto-join groups)
				if searchResultInfo.autoAccept then
					info.isAutoAccept = true
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
	
	-- Track relationship with leader (Blizzard's hasRelationshipWithLeader)
	-- Used for auto-accept logic in tooltips
	entry.hasRelationshipWithLeader = BetterFriendlist_HasRelationshipWithLeader(guid)
	
	-- Extract member data - use actual member info from groupInfo
	-- CRITICAL: Sort members by relationship priority first! (like Blizzard's SocialQueueUtil_SortGroupMembers)
	local sortedMembers = groupInfo.members
	if sortedMembers and #sortedMembers > 0 then
		-- Make a copy to avoid modifying original
		sortedMembers = {}
		for i, member in ipairs(groupInfo.members) do
			sortedMembers[i] = member
		end
		-- Sort by relationship priority: BNet > WoW Friend > Guild > Club > Unknown
		BetterFriendlist_SortGroupMembers(sortedMembers)
	end
	
	if sortedMembers and #sortedMembers > 0 then
		for i, member in ipairs(sortedMembers) do
			-- Get name using BetterFriendlist_GetRelationshipInfo (like Blizzard)
			-- CRITICAL: C_SocialQueue.GetGroupMembers() only returns 'guid' and 'clubId'!
			-- Fields like 'name', 'memberName' do NOT exist - must resolve name from GUID
			local name
			if i == 1 and groupInfo.leaderName and groupInfo.leaderName ~= UNKNOWN then
				-- Use pre-resolved leaderName for first member if available
				name = groupInfo.leaderName
			elseif member.guid then
				-- Resolve name from GUID using BetterFriendlist_GetRelationshipInfo
				local resolvedName = BetterFriendlist_GetRelationshipInfo(member.guid, nil, member.clubId)
				name = resolvedName or UNKNOWN
			else
				name = UNKNOWN
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
			
			-- Get lfgListID from queue data for fetching fresh searchResultInfo in tooltip
			local lfgListID = queue.queueData and queue.queueData.lfgListID
			local queueType = queue.queueData and queue.queueData.queueType or queue.queueType or "lfg"
			
			entry.displayedQueues[i] = {
				queueData = {
					name = groupTitle,  -- Internal storage
					queueType = queueType,
					lfgListID = lfgListID  -- IMPORTANT: Store lfgListID for tooltip leaderName lookup!
				},
				-- CRITICAL: Blizzard caches the queue name (QuickJoin.lua:386-393)
				-- This is what gets displayed in the button!
				cachedQueueName = groupTitle,
				-- Extract role needs from groupInfo (returned by GetGroupInfo)
				-- These are used in the tooltip to show Available Roles
				needTank = groupInfo.needTank or false,
				needHealer = groupInfo.needHealer or false,
				needDamage = groupInfo.needDamage or false,
				-- Auto-accept flag from groupInfo (for tooltip display)
				isAutoAccept = groupInfo.isAutoAccept or false,
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
			-- Auto-accept flag from groupInfo (for tooltip display)
			isAutoAccept = groupInfo.isAutoAccept or false,
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
	
	-- Get leader name - CRITICAL FIX: For lfglist queues, use searchResultInfo.leaderName (CHARACTER name)!
	-- Like Blizzard's LFGListUtil_SetSearchEntryTooltip, NOT the BNet account name from GetRelationshipInfo
	
	-- First, try to get fresh searchResultInfo.leaderName for lfglist queues
	if self.displayedQueues and #self.displayedQueues > 0 and self.displayedQueues[1] then
		local firstQueue = self.displayedQueues[1]
		if firstQueue.queueData and firstQueue.queueData.queueType == "lfglist" and firstQueue.queueData.lfgListID then
			-- CRITICAL: Fetch FRESH searchResultInfo to get CHARACTER name (not cached BNet name)
			local searchResultInfo = C_LFGList.GetSearchResultInfo(firstQueue.queueData.lfgListID)
			if searchResultInfo and searchResultInfo.leaderName then
				leaderName = searchResultInfo.leaderName  -- This is CHARACTER name like "Tsveta-ChamberofAspects"
			end
		end
	end
	
	-- Fallback to groupInfo.leaderName (may be BNet account name for non-lfglist queues, which is correct)
	if not leaderName or leaderName == "" then
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
	
	-- Auto-Accept indicator (Blizzard's hasRelationshipWithLeader logic)
	-- Only show if player has relationship with leader AND group is auto-accept
	-- Auto-accept means you can join instantly without waiting for leader approval
	local isAutoAccept = false
	if self.displayedQueues and self.displayedQueues[1] then
		isAutoAccept = self.displayedQueues[1].isAutoAccept and self.hasRelationshipWithLeader
	end
	
	if isAutoAccept then
		tooltip:AddLine(" ")
		tooltip:AddLine(QUICK_JOIN_IS_AUTO_ACCEPT_TOOLTIP or "This group will automatically accept you.", LIGHTBLUE_FONT_COLOR.r, LIGHTBLUE_FONT_COLOR.g, LIGHTBLUE_FONT_COLOR.b)
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
	-- Check for mock data first
	local mockGroup = self.mockGroups[groupGUID]
	if mockGroup then
		local leaderName = mockGroup.leaderName or "Unknown"
		local numMembers = mockGroup.numMembers or 1
		local color = "|cff00ff00"  -- Green for mock groups
		
		if numMembers > 1 then
			return string.format("%s%s|r +%d", color, leaderName, numMembers - 1)
		else
			return string.format("%s%s|r", color, leaderName)
		end
	end
	
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
	-- Check for mock data first
	local mockGroup = self.mockGroups[groupGUID]
	if mockGroup then
		return mockGroup.groupTitle or mockGroup.activityName or "Mock Activity"
	end
	
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
	==========================================================================
	PROFESSIONAL MOCK SYSTEM (Debug/Testing)
	==========================================================================
	
	Purpose: Simulate Social Queue groups for testing Quick Join functionality
	without requiring actual friends to be online and in groups.
	
	Design Principles:
	1. Mock data follows EXACT Blizzard API structure (C_SocialQueue)
	2. Mock groups integrate seamlessly with real groups
	3. Dynamic updates simulate real-world scenarios (member joins/leaves)
	4. Event simulation for testing event handlers
	5. Comprehensive presets covering all queue types
	
	API Structure Reference:
	- C_SocialQueue.GetGroupInfo(guid) → canJoin, numQueues, needTank, needHealer, needDamage, isSoloQueueParty, questSessionActive, leaderGUID
	- C_SocialQueue.GetGroupMembers(guid) → {guid, clubId}[]
	- C_SocialQueue.GetGroupQueues(guid) → {clientID, eligible, needTank, needHealer, needDamage, isAutoAccept, queueData}[]
	
	QueueData Types:
	- "lfglist": LFG Finder groups (M+, raids) - has lfgListID
	- "lfg": LFG Dungeon Finder - has lfgIDs[]
	- "pvp": PvP queues - has battlefieldType, rated, teamSize
	- "petbattle": Pet Battle queue
	
	Commands:
	- /bfl qj mock           - Create comprehensive test data
	- /bfl qj mock dungeon   - Create dungeon-specific mocks
	- /bfl qj mock pvp       - Create PvP-specific mocks
	- /bfl qj mock raid      - Create raid-specific mocks
	- /bfl qj mock stress    - Create 50+ groups for stress testing
	- /bfl qj add <params>   - Add custom mock group
	- /bfl qj event <type>   - Simulate events (add, remove, update)
	- /bfl qj list           - List all mock groups
	- /bfl qj clear          - Remove all mock groups
]]

-- ============================================
-- MOCK SYSTEM CONSTANTS
-- ============================================

local MOCK_PREFIX = "MockGroup-"

-- Realistic player names (from WoW lore characters)
local MOCK_PLAYER_NAMES = {
	-- Alliance
	"Anduin", "Jaina", "Genn", "Alleria", "Turalyon", "Velen", "Tyrande", "Malfurion",
	"Muradin", "Mekkatorque", "Aysa", "Tess", "Shaw", "Magni", "Khadgar",
	-- Horde
	"Thrall", "Sylvanas", "Baine", "Lor'themar", "Thalyssra", "Gazlowe", "Ji", 
	"Rokhan", "Geya'rah", "Calia", "Eitrigg", "Saurfang", "Vol'jin", "Rexxar",
	-- Neutral
	"Chromie", "Wrathion", "Alexstrasza", "Ysera", "Nozdormu", "Kalecgos"
}

-- Realistic activity names by type
local MOCK_ACTIVITIES = {
	lfglist_mythicplus = {
		{"M+ Gruppe sucht DD", "Mythic+ Dungeon", "Need experienced DPS, voice preferred"},
		{"NW +22 Timing Run", "Mythic+ Dungeon", "2.8k+ rio, have route"},
		{"Mists Weekly - Chill", "Mythic+ Dungeon", "No timer pressure, all welcome"},
		{"Keys for Vault", "Mythic+ Dungeon", "Any level, just for vault slots"},
		{"CoS +20 Push", "Mythic+ Dungeon", "Going for KSH, need good players"},
		{"BRH Fortified Farm", "Mythic+ Dungeon", "Quick runs, know the dungeon"},
		{"Atal'Dazar +18", "Mythic+ Dungeon", "Learning route, be patient"},
		{"Stonevault +25 Title", "Mythic+ Dungeon", "0.1% title push, 3k+ only"},
	},
	lfglist_raid = {
		{"Nerub-ar Palace Normal", "Raid", "Full clear, new players welcome"},
		{"NaP Heroic - AOTC Run", "Raid", "Link AOTC or 580+ ilvl"},
		{"Queen Ansurek Only", "Raid", "Farm boss, know mechanics"},
		{"Palace Mythic Progress", "Raid", "Guild run, need 1 healer"},
	},
	lfg_dungeon = {
		{"Random Heroic", "Heroic Dungeon"},
		{"Normal Dungeon", "Normal Dungeon"},
		{"Timewalking", "Timewalking Dungeon"},
		{"Follower Dungeon", "Follower Dungeon"},
	},
	pvp = {
		{"RBG 2400+ Push", "Rated Battleground", "Voice required, have strats"},
		{"Casual BGs", "Battleground", "Just for fun, no ragers"},
		{"Arena 3v3 Practice", "Arena", "Learning comps, be chill"},
		{"Solo Shuffle Warmup", "Solo Shuffle", "Getting games in"},
		{"Epic BG Group", "Epic Battleground", "AV/IoC farm"},
	},
}

-- Class data for realistic members
local MOCK_CLASSES = {
	{name = "WARRIOR", icon = "Interface\\Icons\\ClassIcon_Warrior", roles = {"TANK", "DAMAGER"}},
	{name = "PALADIN", icon = "Interface\\Icons\\ClassIcon_Paladin", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "HUNTER", icon = "Interface\\Icons\\ClassIcon_Hunter", roles = {"DAMAGER"}},
	{name = "ROGUE", icon = "Interface\\Icons\\ClassIcon_Rogue", roles = {"DAMAGER"}},
	{name = "PRIEST", icon = "Interface\\Icons\\ClassIcon_Priest", roles = {"HEALER", "DAMAGER"}},
	{name = "DEATHKNIGHT", icon = "Interface\\Icons\\ClassIcon_DeathKnight", roles = {"TANK", "DAMAGER"}},
	{name = "SHAMAN", icon = "Interface\\Icons\\ClassIcon_Shaman", roles = {"HEALER", "DAMAGER"}},
	{name = "MAGE", icon = "Interface\\Icons\\ClassIcon_Mage", roles = {"DAMAGER"}},
	{name = "WARLOCK", icon = "Interface\\Icons\\ClassIcon_Warlock", roles = {"DAMAGER"}},
	{name = "MONK", icon = "Interface\\Icons\\ClassIcon_Monk", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "DRUID", icon = "Interface\\Icons\\ClassIcon_Druid", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "DEMONHUNTER", icon = "Interface\\Icons\\ClassIcon_DemonHunter", roles = {"TANK", "DAMAGER"}},
	{name = "EVOKER", icon = "Interface\\Icons\\ClassIcon_Evoker", roles = {"HEALER", "DAMAGER"}},
}

-- ============================================
-- MOCK SYSTEM STATE
-- ============================================
-- Note: QuickJoin.mockGroups is initialized at module top (line ~40)

QuickJoin.mockUpdateTimer = nil     -- Timer for dynamic updates
QuickJoin.mockEventQueue = {}       -- Queued events for simulation
QuickJoin.mockConfig = {
	dynamicUpdates = true,          -- Enable/disable member count changes
	updateInterval = 3.0,           -- Seconds between dynamic updates
	eventSimulation = false,        -- Simulate SOCIAL_QUEUE events
}

-- ============================================
-- MOCK GROUP CREATION
-- ============================================

--[[
	Generate a unique mock GUID that follows WoW GUID format
	Real format: "Player-ServerID-PlayerID" or "Party-0-GroupID"
]]
local function GenerateMockGUID()
	-- Use smaller random range to avoid integer overflow (Lua max ~2^31)
	return string.format("%s%d-%08X", MOCK_PREFIX, GetServerTime() % 100000, math.random(0x10000000, 0x7FFFFFFF))
end

--[[
	Generate a mock player GUID
	Real format: "Player-ServerID-PlayerID"
]]
local function GenerateMockPlayerGUID()
	-- Use smaller random range to avoid integer overflow (Lua max ~2^31)
	return string.format("Player-%05d-%08X", math.random(1, 99999), math.random(0x10000000, 0x7FFFFFFF))
end

--[[
	Create mock members array following Blizzard API structure
	@param count: Number of members (1-40)
	@param leaderName: Name for the leader (first member)
	@return: Array of SocialQueuePlayerInfo objects
]]
local function CreateMockMembers(count, leaderName)
	local members = {}
	local usedNames = {}
	
	for i = 1, count do
		local name
		if i == 1 and leaderName then
			name = leaderName
		else
			-- Pick a unique random name
			repeat
				name = MOCK_PLAYER_NAMES[math.random(#MOCK_PLAYER_NAMES)]
			until not usedNames[name] or #usedNames >= #MOCK_PLAYER_NAMES
		end
		usedNames[name] = true
		
		-- Create member following exact Blizzard structure
		members[i] = {
			guid = GenerateMockPlayerGUID(),
			clubId = nil,  -- Only set for community members
			-- BetterFriendlist extensions (for display)
			name = name,
			memberName = name,
		}
	end
	
	return members
end

--[[
	Create mock queue data following Blizzard API structure
	@param queueType: "lfglist", "lfg", "pvp", "petbattle"
	@param activityName: Display name for the activity
	@param comment: Optional comment/description
	@param options: Additional options (needTank, needHealer, needDamage, rated, etc.)
	@return: SocialQueueGroupQueueInfo object
]]
local function CreateMockQueueData(queueType, activityName, comment, options)
	options = options or {}
	
	local queueData = {
		queueType = queueType,
	}
	
	if queueType == "lfglist" then
		-- LFG List (Group Finder) - has lfgListID and name
		queueData.lfgListID = math.random(100000, 999999)
		queueData.activityID = math.random(1000, 9999)
		queueData.name = activityName  -- Group title (shows in quotes)
		queueData.comment = comment or ""
	elseif queueType == "lfg" then
		-- LFG Dungeon Finder - has lfgIDs array
		queueData.lfgIDs = {math.random(1, 500)}  -- Dungeon ID
	elseif queueType == "pvp" then
		-- PvP Queue
		queueData.battlefieldType = options.battlefieldType or "BATTLEGROUND"
		queueData.rated = options.rated or false
		queueData.teamSize = options.teamSize or 0
		queueData.mapName = activityName
	end
	
	return {
		clientID = math.random(10000, 99999),
		eligible = true,
		needTank = options.needTank ~= false,
		needHealer = options.needHealer ~= false,
		needDamage = options.needDamage ~= false,
		isAutoAccept = options.isAutoAccept or false,
		queueData = queueData,
	}
end

--[[
	Create a complete mock group with all required data
	@param params: Table with group parameters
	  - leaderName: Leader name (required)
	  - queueType: "lfglist", "lfg", "pvp" (default: "lfglist")
	  - activityName: Activity/group name (required)
	  - activityType: Type description for tooltip
	  - comment: Optional comment
	  - numMembers: 1-40 (default: random 1-5)
	  - needTank: boolean (default: true)
	  - needHealer: boolean (default: true)
	  - needDamage: boolean (default: true)
	@return: guid, groupData
]]
function QuickJoin:CreateMockGroup(params)
	params = params or {}
	
	-- Validate required params
	if not params.leaderName then
		params.leaderName = MOCK_PLAYER_NAMES[math.random(#MOCK_PLAYER_NAMES)]
	end
	if not params.activityName then
		params.activityName = "Test Group"
	end
	
	-- Generate unique GUID
	local guid = GenerateMockGUID()
	
	-- Create members
	local numMembers = params.numMembers or math.random(1, 5)
	numMembers = math.max(1, math.min(40, numMembers))
	local members = CreateMockMembers(numMembers, params.leaderName)
	
	-- Create queue data
	local queueType = params.queueType or "lfglist"
	local queues = {
		CreateMockQueueData(queueType, params.activityName, params.comment, {
			needTank = params.needTank,
			needHealer = params.needHealer,
			needDamage = params.needDamage,
			rated = params.rated,
			battlefieldType = params.battlefieldType,
			teamSize = params.teamSize,
		})
	}
	
	-- Build complete mock group following C_SocialQueue.GetGroupInfo structure
	local mockGroup = {
		-- Core API fields (match GetGroupInfo return values exactly)
		canJoin = true,
		numQueues = 1,
		needTank = params.needTank ~= false,
		needHealer = params.needHealer ~= false,
		needDamage = params.needDamage ~= false,
		isSoloQueueParty = false,
		questSessionActive = false,
		leaderGUID = members[1].guid,
		
		-- Extended data (from GetGroupMembers/GetGroupQueues)
		members = members,
		queues = queues,
		
		-- Calculated fields (for display)
		numMembers = numMembers,
		leaderName = params.leaderName,
		groupTitle = params.activityName,
		activityName = params.activityType or params.activityName,
		activityIcon = params.icon or "Interface\\Icons\\Achievement_Boss_Murmur",
		queueInfo = "",
		requestedToJoin = false,
		
		-- Mock metadata
		_isMock = true,
		_created = GetTime(),
		_queueType = queueType,
	}
	
	-- Store mock group
	self.mockGroups[guid] = mockGroup
	
	BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Created '%s' (%s, %d members)", 
		params.activityName, queueType, numMembers))
	
	return guid, mockGroup
end

--[[
	Remove a specific mock group
	@param guid: Group GUID to remove
	@return: true if removed, false if not found
]]
function QuickJoin:RemoveMockGroup(guid)
	if self.mockGroups[guid] then
		local name = self.mockGroups[guid].groupTitle or "Unknown"
		self.mockGroups[guid] = nil
		BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Removed '%s'", name))
		self:Update(true)
		return true
	end
	return false
end

--[[
	Clear all mock groups and stop timers
]]
function QuickJoin:ClearMockGroups()
	-- Stop dynamic update timer
	if self.mockUpdateTimer then
		self.mockUpdateTimer:Cancel()
		self.mockUpdateTimer = nil
	end
	
	-- Count and clear
	local count = 0
	for guid in pairs(self.mockGroups) do
		count = count + 1
	end
	
	wipe(self.mockGroups)
	
	BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Cleared %d mock groups", count))
	print(string.format("|cff00ff00BFL QuickJoin:|r Cleared %d mock groups", count))
	
	self:Update(true)
end

-- ============================================
-- MOCK PRESETS
-- ============================================

--[[
	Create comprehensive mock data covering all scenarios
]]
function QuickJoin:CreateMockPreset_All()
	self:ClearMockGroups()
	
	-- M+ Groups (lfglist)
	for i, activity in ipairs(MOCK_ACTIVITIES.lfglist_mythicplus) do
		if i <= 5 then  -- Limit to avoid overwhelming
			self:CreateMockGroup({
				leaderName = MOCK_PLAYER_NAMES[i],
				queueType = "lfglist",
				activityName = activity[1],
				activityType = activity[2],
				comment = activity[3],
				numMembers = math.random(1, 4),
				needTank = math.random() > 0.5,
				needHealer = math.random() > 0.5,
				needDamage = true,
			})
		end
	end
	
	-- Raid Groups
	for i, activity in ipairs(MOCK_ACTIVITIES.lfglist_raid) do
		if i <= 2 then
			self:CreateMockGroup({
				leaderName = MOCK_PLAYER_NAMES[10 + i],
				queueType = "lfglist",
				activityName = activity[1],
				activityType = activity[2],
				comment = activity[3],
				numMembers = math.random(5, 15),
				needTank = true,
				needHealer = true,
				needDamage = true,
			})
		end
	end
	
	-- LFG Dungeon (lfg)
	for i, activity in ipairs(MOCK_ACTIVITIES.lfg_dungeon) do
		if i <= 2 then
			self:CreateMockGroup({
				leaderName = MOCK_PLAYER_NAMES[15 + i],
				queueType = "lfg",
				activityName = activity[1],
				activityType = activity[2],
				numMembers = math.random(1, 3),
			})
		end
	end
	
	-- PvP Groups
	for i, activity in ipairs(MOCK_ACTIVITIES.pvp) do
		if i <= 2 then
			self:CreateMockGroup({
				leaderName = MOCK_PLAYER_NAMES[20 + i],
				queueType = "pvp",
				activityName = activity[1],
				activityType = activity[2],
				comment = activity[3],
				numMembers = math.random(1, 5),
				rated = i == 1,
			})
		end
	end
	
	-- Start dynamic updates
	self:StartMockDynamicUpdates()
	
	local count = 0
	for _ in pairs(self.mockGroups) do count = count + 1 end
	print(string.format("|cff00ff00BFL QuickJoin:|r Created %d mock groups (dynamic updates enabled)", count))
	
	self:Update(true)
end

--[[
	Create dungeon-specific mocks
]]
function QuickJoin:CreateMockPreset_Dungeon()
	self:ClearMockGroups()
	
	for i, activity in ipairs(MOCK_ACTIVITIES.lfglist_mythicplus) do
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[i],
			queueType = "lfglist",
			activityName = activity[1],
			activityType = activity[2],
			comment = activity[3],
			numMembers = math.random(1, 4),
		})
	end
	
	for i, activity in ipairs(MOCK_ACTIVITIES.lfg_dungeon) do
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[10 + i],
			queueType = "lfg",
			activityName = activity[1],
			activityType = activity[2],
			numMembers = math.random(1, 4),
		})
	end
	
	self:StartMockDynamicUpdates()
	
	local count = 0
	for _ in pairs(self.mockGroups) do count = count + 1 end
	print(string.format("|cff00ff00BFL QuickJoin:|r Created %d dungeon mock groups", count))
	
	self:Update(true)
end

--[[
	Create PvP-specific mocks
]]
function QuickJoin:CreateMockPreset_PvP()
	self:ClearMockGroups()
	
	for i, activity in ipairs(MOCK_ACTIVITIES.pvp) do
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[i],
			queueType = "pvp",
			activityName = activity[1],
			activityType = activity[2],
			comment = activity[3],
			numMembers = math.random(1, 10),
			rated = i <= 2,
		})
	end
	
	self:StartMockDynamicUpdates()
	
	local count = 0
	for _ in pairs(self.mockGroups) do count = count + 1 end
	print(string.format("|cff00ff00BFL QuickJoin:|r Created %d PvP mock groups", count))
	
	self:Update(true)
end

--[[
	Create raid-specific mocks
]]
function QuickJoin:CreateMockPreset_Raid()
	self:ClearMockGroups()
	
	for i, activity in ipairs(MOCK_ACTIVITIES.lfglist_raid) do
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[i],
			queueType = "lfglist",
			activityName = activity[1],
			activityType = activity[2],
			comment = activity[3],
			numMembers = math.random(5, 25),
		})
	end
	
	self:StartMockDynamicUpdates()
	
	local count = 0
	for _ in pairs(self.mockGroups) do count = count + 1 end
	print(string.format("|cff00ff00BFL QuickJoin:|r Created %d raid mock groups", count))
	
	self:Update(true)
end

--[[
	Create many groups for stress testing scrollbar
]]
function QuickJoin:CreateMockPreset_Stress()
	self:ClearMockGroups()
	
	-- Create 50 groups
	for i = 1, 50 do
		local activities = MOCK_ACTIVITIES.lfglist_mythicplus
		local activity = activities[((i - 1) % #activities) + 1]
		
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[((i - 1) % #MOCK_PLAYER_NAMES) + 1] .. i,
			queueType = "lfglist",
			activityName = activity[1] .. " #" .. i,
			activityType = activity[2],
			comment = activity[3],
			numMembers = math.random(1, 5),
		})
	end
	
	-- Don't enable dynamic updates for stress test (too much CPU)
	
	print("|cff00ff00BFL QuickJoin:|r Created 50 mock groups (stress test)")
	
	self:Update(true)
end

-- ============================================
-- DYNAMIC UPDATE SYSTEM
-- ============================================

--[[
	Start timer for dynamic mock updates (simulates real activity)
]]
function QuickJoin:StartMockDynamicUpdates()
	-- Stop existing timer
	if self.mockUpdateTimer then
		self.mockUpdateTimer:Cancel()
	end
	
	self.mockUpdateTimer = C_Timer.NewTicker(self.mockConfig.updateInterval, function()
		self:ProcessMockDynamicUpdate()
	end)
	
	BFL:DebugPrint("|cff00ff00QuickJoin Mock:|r Dynamic updates started")
end

--[[
	Process one cycle of dynamic updates
]]
function QuickJoin:ProcessMockDynamicUpdate()
	if not self.mockConfig.dynamicUpdates then return end
	
	local updated = false
	
	for guid, group in pairs(self.mockGroups) do
		-- 30% chance to change member count
		if math.random() < 0.3 then
			local maxMembers = group._queueType == "lfglist" and 
				(group.activityName and group.activityName:find("Raid") and 25 or 5) or 5
			local newCount = math.random(1, maxMembers)
			
			if newCount ~= group.numMembers then
				-- Update member count
				group.numMembers = newCount
				
				-- Rebuild members array
				group.members = CreateMockMembers(newCount, group.leaderName)
				group.leaderGUID = group.members[1].guid
				
				updated = true
				BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s: %d members", 
					group.leaderName, newCount))
			end
		end
		
		-- 10% chance to change role requirements
		if math.random() < 0.1 then
			group.needTank = math.random() > 0.3
			group.needHealer = math.random() > 0.3
			group.needDamage = math.random() > 0.2
			if group.queues and group.queues[1] then
				group.queues[1].needTank = group.needTank
				group.queues[1].needHealer = group.needHealer
				group.queues[1].needDamage = group.needDamage
			end
			updated = true
		end
	end
	
	if updated then
		self:Update(true)
	end
end

-- ============================================
-- EVENT SIMULATION
-- ============================================

--[[
	Simulate SOCIAL_QUEUE_UPDATE event
	@param eventType: "group_added", "group_removed", "group_updated"
]]
function QuickJoin:SimulateMockEvent(eventType)
	if eventType == "group_added" then
		-- Add a random new group
		local activity = MOCK_ACTIVITIES.lfglist_mythicplus[math.random(#MOCK_ACTIVITIES.lfglist_mythicplus)]
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[math.random(#MOCK_PLAYER_NAMES)],
			queueType = "lfglist",
			activityName = activity[1],
			activityType = activity[2],
			comment = activity[3],
			numMembers = math.random(1, 4),
		})
		print("|cff00ff00BFL QuickJoin:|r Simulated: Group added")
		
	elseif eventType == "group_removed" then
		-- Remove a random group
		local guids = {}
		for guid in pairs(self.mockGroups) do
			table.insert(guids, guid)
		end
		if #guids > 0 then
			local guid = guids[math.random(#guids)]
			self:RemoveMockGroup(guid)
			print("|cff00ff00BFL QuickJoin:|r Simulated: Group removed")
		else
			print("|cffff8800BFL QuickJoin:|r No mock groups to remove")
		end
		
	elseif eventType == "group_updated" then
		-- Update a random group
		local guids = {}
		for guid in pairs(self.mockGroups) do
			table.insert(guids, guid)
		end
		if #guids > 0 then
			local guid = guids[math.random(#guids)]
			local group = self.mockGroups[guid]
			group.numMembers = math.random(1, 5)
			group.members = CreateMockMembers(group.numMembers, group.leaderName)
			print(string.format("|cff00ff00BFL QuickJoin:|r Simulated: %s updated (%d members)", 
				group.leaderName, group.numMembers))
		else
			print("|cffff8800BFL QuickJoin:|r No mock groups to update")
		end
	end
	
	self:Update(true)
end

-- ============================================
-- SLASH COMMAND HANDLER
-- ============================================

-- Legacy slash command (redirects to /bfl qj)
SLASH_BFLQUICKJOIN1 = "/bflqj"
SLASH_BFLQUICKJOIN2 = "/bflquickjoin"
SlashCmdList["BFLQUICKJOIN"] = function(msg)
	local args = {}
	for word in msg:gmatch("%S+") do
		table.insert(args, word)
	end
	
	local cmd = args[1] and args[1]:lower() or "help"
	
	if cmd == "mock" then
		local subCmd = args[2] and args[2]:lower() or "all"
		
		if subCmd == "dungeon" or subCmd == "m+" or subCmd == "mythic" then
			QuickJoin:CreateMockPreset_Dungeon()
		elseif subCmd == "pvp" or subCmd == "arena" or subCmd == "bg" then
			QuickJoin:CreateMockPreset_PvP()
		elseif subCmd == "raid" then
			QuickJoin:CreateMockPreset_Raid()
		elseif subCmd == "stress" or subCmd == "many" then
			QuickJoin:CreateMockPreset_Stress()
		else
			QuickJoin:CreateMockPreset_All()
		end
		
	elseif cmd == "add" then
		-- /bfl qj add <leader> <activity> [members]
		local leaderName = args[2] or "TestPlayer"
		local activityName = args[3] or "Custom Group"
		local numMembers = tonumber(args[4]) or 2
		
		QuickJoin:CreateMockGroup({
			leaderName = leaderName,
			activityName = activityName,
			numMembers = numMembers,
		})
		QuickJoin:Update(true)
		print(string.format("|cff00ff00BFL QuickJoin:|r Added mock group: %s - %s (%d members)", 
			leaderName, activityName, numMembers))
		
	elseif cmd == "event" then
		local eventType = args[2] and args[2]:lower() or "help"
		
		if eventType == "add" or eventType == "added" then
			QuickJoin:SimulateMockEvent("group_added")
		elseif eventType == "remove" or eventType == "removed" then
			QuickJoin:SimulateMockEvent("group_removed")
		elseif eventType == "update" or eventType == "updated" then
			QuickJoin:SimulateMockEvent("group_updated")
		else
			print("|cff00ff00BFL QuickJoin Event Commands:|r")
			print("  |cffffcc00/bfl qj event add|r - Simulate group added")
			print("  |cffffcc00/bfl qj event remove|r - Simulate group removed")
			print("  |cffffcc00/bfl qj event update|r - Simulate group updated")
		end
		
	elseif cmd == "clear" then
		QuickJoin:ClearMockGroups()
		
	elseif cmd == "list" then
		print("|cff00ff00BFL QuickJoin Mock Groups:|r")
		local count = 0
		for guid, group in pairs(QuickJoin.mockGroups) do
			count = count + 1
			local queueType = group._queueType or "unknown"
			print(string.format("  %d. |cff00ff00%s|r - %s (%s, %d members)", 
				count, group.leaderName, group.groupTitle, queueType, group.numMembers))
		end
		if count == 0 then
			print("  |cff888888No mock groups. Use '/bfl qj mock' to create test data.|r")
		end
		
	elseif cmd == "config" then
		local setting = args[2] and args[2]:lower()
		local value = args[3]
		
		if setting == "dynamic" then
			QuickJoin.mockConfig.dynamicUpdates = (value == "on" or value == "true" or value == "1")
			print(string.format("|cff00ff00BFL QuickJoin:|r Dynamic updates: %s", 
				QuickJoin.mockConfig.dynamicUpdates and "ON" or "OFF"))
		elseif setting == "interval" then
			local interval = tonumber(value) or 3.0
			QuickJoin.mockConfig.updateInterval = math.max(1.0, interval)
			print(string.format("|cff00ff00BFL QuickJoin:|r Update interval: %.1f seconds", 
				QuickJoin.mockConfig.updateInterval))
		else
			print("|cff00ff00BFL QuickJoin Config:|r")
			print(string.format("  Dynamic updates: %s", QuickJoin.mockConfig.dynamicUpdates and "ON" or "OFF"))
			print(string.format("  Update interval: %.1f seconds", QuickJoin.mockConfig.updateInterval))
			print("")
			print("  |cffffcc00/bfl qj config dynamic on|off|r")
			print("  |cffffcc00/bfl qj config interval <seconds>|r")
		end
		
	else
		-- Help
		print("|cff00ff00BFL QuickJoin Commands:|r")
		print("")
		print("|cffffcc00Mock Data:|r")
		print("  |cffffcc00/bfl qj mock|r - Create comprehensive test data")
		print("  |cffffcc00/bfl qj mock dungeon|r - Dungeon/M+ groups only")
		print("  |cffffcc00/bfl qj mock pvp|r - PvP groups only")
		print("  |cffffcc00/bfl qj mock raid|r - Raid groups only")
		print("  |cffffcc00/bfl qj mock stress|r - 50 groups (scrollbar test)")
		print("")
		print("|cffffcc00Management:|r")
		print("  |cffffcc00/bfl qj add <name> <activity> [members]|r - Add custom group")
		print("  |cffffcc00/bfl qj list|r - List all mock groups")
		print("  |cffffcc00/bfl qj clear|r - Remove all mock groups")
		print("")
		print("|cffffcc00Event Simulation:|r")
		print("  |cffffcc00/bfl qj event add|r - Simulate new group")
		print("  |cffffcc00/bfl qj event remove|r - Simulate group leaving")
		print("  |cffffcc00/bfl qj event update|r - Simulate group change")
		print("")
		print("|cffffcc00Configuration:|r")
		print("  |cffffcc00/bfl qj config|r - Show/set mock configuration")
		print("")
		print("|cff888888Mock groups appear with real groups and are marked green.|r")
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
