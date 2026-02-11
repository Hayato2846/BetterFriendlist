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
	
	NOTE: QuickJoin/Social Queue is Retail-only. This module is disabled in Classic.
]]

local addonName, BFL = ...
local L = BFL.L

-- Create Module
local QuickJoin = {}
BFL:RegisterModule("QuickJoin", QuickJoin)

-- Classic Guard: QuickJoin/Social Queue doesn't exist in Classic
BFL.HasQuickJoin = BFL.IsRetail and C_SocialQueue ~= nil

-- Constants
local MAX_DISPLAYED_MEMBERS = 8 -- Maximum members shown in group list
local TOAST_DURATION = 8.0 -- Toast button display duration

-- Module State
QuickJoin.initialized = false
QuickJoin.availableGroups = {} -- List of available group GUIDs
QuickJoin.groupCache = {} -- Cached group information
QuickJoin.lastUpdate = 0 -- Timestamp of last update
QuickJoin.updateQueued = false -- Pending update flag
QuickJoin.config = nil -- Social Queue Config (from C_SocialQueue.GetConfig)
QuickJoin.mockGroups = {} -- Mock groups for testing (added to real groups)
QuickJoin.selectedGUID = nil -- Currently selected group GUID
QuickJoin.selectedButtons = {} -- Track button selection states
QuickJoin.relationshipCache = {} -- Short-lived cache for relationship lookups
QuickJoin.mockMemberByGuid = {} -- Fast lookup for mock member GUIDs
QuickJoin.entriesCache = nil -- Cached QuickJoinEntry list
QuickJoin.entriesCacheVersion = nil

-- Dirty flag: Set when data changes while frame is hidden
local needsRenderOnShow = false
local updateTimer = nil
local RELATIONSHIP_CACHE_TTL = 0.5

local function GetRelationshipCacheKey(guid, missingNameFallback, clubId)
	return tostring(guid) .. "|" .. tostring(clubId or "") .. "|" .. tostring(missingNameFallback or "")
end

local function TryGetCachedRelationship(guid, missingNameFallback, clubId)
	if not guid then
		return nil
	end
	local entry = QuickJoin.relationshipCache[GetRelationshipCacheKey(guid, missingNameFallback, clubId)]
	if entry and entry.expires and entry.expires > GetTime() then
		return entry
	end
	return nil
end

local function CacheAndReturnRelationship(guid, missingNameFallback, clubId, name, color, relationship, playerLink)
	if guid then
		QuickJoin.relationshipCache[GetRelationshipCacheKey(guid, missingNameFallback, clubId)] = {
			name = name,
			color = color,
			relationship = relationship,
			playerLink = playerLink,
			expires = GetTime() + RELATIONSHIP_CACHE_TTL,
		}
	end
	return name, color, relationship, playerLink
end

--[[
	Helper: GetFriendInfoByGUID
	C_FriendList.GetFriendInfoByGUID() does NOT exist in WoW 11.2!
	We need to iterate through all friends and match by GUID.
]]
local function GetFriendInfoByGUID(guid)
	if not guid then
		return nil
	end

	local numFriends = C_FriendList.GetNumFriends() or 0
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
	local cached = TryGetCachedRelationship(guid, missingNameFallback, clubId)
	if cached then
		return cached.name, cached.color, cached.relationship, cached.playerLink
	end
	-- 1. Check if this is a mock group member first (BetterFriendlist-specific)
	if QuickJoin and QuickJoin.mockMemberByGuid and guid then
		local member = QuickJoin.mockMemberByGuid[guid]
		if member then
			local name = member.name or member.memberName or "MockPlayer"
			local mockColor = "|cff00ff00" -- Green for mock members
			return CacheAndReturnRelationship(guid, missingNameFallback, clubId, name, mockColor, "mock", nil)
		end
	end

	-- 2. Check BattleNet friend (like Blizzard)
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid)
	if accountInfo then
		-- [STREAMER MODE CHECK]
		if BFL.StreamerMode and BFL.StreamerMode:IsActive() then
			local FL = BFL:GetModule("FriendsList")
			if FL then
				local friendObj = {
					type = "bnet",
					name = accountInfo.accountName,
					accountName = accountInfo.accountName,
					battleTag = accountInfo.battleTag,
					note = accountInfo.note,
					uid = guid,
				}
				local safeName = FL:GetDisplayName(friendObj)
				-- Return masked name, default color, type, and NO LINK (to prevent leaking real ID in link)
				return CacheAndReturnRelationship(
					guid,
					missingNameFallback,
					clubId,
					safeName,
					FRIENDS_BNET_NAME_COLOR_CODE,
					"bnfriend",
					nil
				)
			end
		end

		local accountName = accountInfo.accountName
		local playerLink = GetBNPlayerLink(accountName, accountName, accountInfo.bnetAccountID, 0, 0, 0)
		return CacheAndReturnRelationship(
			guid,
			missingNameFallback,
			clubId,
			accountName,
			FRIENDS_BNET_NAME_COLOR_CODE,
			"bnfriend",
			playerLink
		)
	end

	-- 3. CRITICAL FIX: GetPlayerInfoByGUID fallback (like Blizzard's SocialQueueUtil_GetRelationshipInfo)
	-- This fixes "Unknown" name display for players without direct relationship
	local name, normalizedRealmName = select(6, GetPlayerInfoByGUID(guid))

	-- [STREAMER MODE CHECK FOR WOW FRIENDS]
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() and C_FriendList.IsFriend(guid) then
		local FL = BFL:GetModule("FriendsList")
		local friendInfo = GetFriendInfoByGUID(guid) -- Use local helper (reliable)

		if FL and friendInfo then
			local friendObj = {
				type = "wow",
				name = friendInfo.name,
				note = friendInfo.notes,
				uid = guid,
			}
			local safeName = FL:GetDisplayName(friendObj)
			return CacheAndReturnRelationship(
				guid,
				missingNameFallback,
				clubId,
				safeName,
				FRIENDS_WOW_NAME_COLOR_CODE,
				"wowfriend",
				nil
			)
		end
	end

	name = name or missingNameFallback

	local hasName = name ~= nil
	if not hasName then
		name = ""
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
		return CacheAndReturnRelationship(
			guid,
			missingNameFallback,
			clubId,
			name,
			FRIENDS_WOW_NAME_COLOR_CODE,
			"wowfriend",
			playerLink
		)
	end

	-- 5. Check guild member (with already determined name)
	if IsGuildMember(guid) then
		return CacheAndReturnRelationship(
			guid,
			missingNameFallback,
			clubId,
			name,
			RGBTableToColorCode(ChatTypeInfo.GUILD),
			"guild",
			playerLink
		)
	end

	-- 6. Check club/community (with already determined name) - FIX: Don't use GetMemberInfoForSelf!
	local clubInfo = clubId and C_Club.GetClubInfo(clubId) or nil
	if clubInfo then
		return CacheAndReturnRelationship(
			guid,
			missingNameFallback,
			clubId,
			name,
			FRIENDS_WOW_NAME_COLOR_CODE,
			"club",
			playerLink
		)
	end

	-- 7. Final fallback (name is already set by GetPlayerInfoByGUID)
	return CacheAndReturnRelationship(
		guid,
		missingNameFallback,
		clubId,
		name,
		FRIENDS_WOW_NAME_COLOR_CODE,
		nil,
		playerLink
	)
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
	if not members then
		return members
	end
	local memberInfo = {}
	local function GetMemberInfo(member)
		local guid = member and member.guid
		if guid and memberInfo[guid] then
			return memberInfo[guid].name, memberInfo[guid].relationship
		end
		local name, _, relationship = BetterFriendlist_GetRelationshipInfo(guid, nil, member and member.clubId)
		if guid then
			memberInfo[guid] = { name = name or "", relationship = relationship }
		end
		return name or "", relationship
	end

	table.sort(members, function(lhs, rhs)
		local lhsName, lhsRelationship = GetMemberInfo(lhs)
		local rhsName, rhsRelationship = GetMemberInfo(rhs)

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
	Helper: PopulateGroupMemberDetails
	Populates leaderName, leaderColor, and otherFriends from the members list.
	Shared logic for both Real and Mock groups.
]]
local function PopulateGroupMemberDetails(info)
	if not info.members then
		return
	end

	-- Recalculate numMembers from actual member list if not set
	if not info.numMembers or info.numMembers == 0 then
		info.numMembers = #info.members
	end

	info.otherFriends = {} -- Store names of other friends in the group

	if info.members and #info.members > 0 then
		for i, member in ipairs(info.members) do
			if member.guid then
				local name, color, relationship, playerLink =
					BetterFriendlist_GetRelationshipInfo(member.guid, nil, member.clubId)

				-- Store details for context menu
				member.name = name
				member.playerLink = playerLink

				-- Check if this member is the leader
				local isLeader = (info.leaderGUID and member.guid == info.leaderGUID)

				-- Fallback: If no leaderGUID available, assume first member is leader (legacy behavior)
				if not info.leaderGUID and i == 1 then
					isLeader = true
				end

				if isLeader then
					if name and name ~= "" then
						-- Always use the resolved name for the leader if found in members list
						-- This ensures we use BNet/Friend name instead of Character name
						info.leaderName = name
						info.leaderColor = color -- Store color for leader
					end
				else
					-- Check if this member is a friend (BNet or WoW) or Mock
					if relationship == "bnfriend" or relationship == "wowfriend" or relationship == "mock" then
						if name and name ~= "" then
							-- Store colored name
							local coloredName = (color or "|cffffffff") .. name .. "|r"
							table.insert(info.otherFriends, coloredName)
						end
					end
				end
			end
		end
	end
end

--[[ 
	Public API 
]]

-- QuickJoinEntry Class
local QuickJoinEntry = {}
QuickJoinEntry.__index = QuickJoinEntry

function QuickJoinEntry:New(guid, groupInfo)
	local entry = setmetatable({}, QuickJoinEntry)
	entry.guid = guid
	entry.groupInfo = groupInfo or {}
	entry.fontObject = BetterFriendlistFontNormalSmall

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
			if i == 1 and groupInfo.leaderName and (groupInfo._hasSecretValues or groupInfo.leaderName ~= "") then
				-- Use pre-resolved leaderName for first member if available
				name = groupInfo.leaderName
			elseif member.guid then
				-- Resolve name from GUID using BetterFriendlist_GetRelationshipInfo
				local resolvedName = BetterFriendlist_GetRelationshipInfo(member.guid, nil, member.clubId)
				name = resolvedName or ""
			else
				name = ""
			end

			entry.displayedMembers[i] = {
				guid = member.guid or guid,
				name = name,
				clubId = member.clubId,
			}
		end
	else
		-- Fallback: Use leader name if no members array
		entry.displayedMembers[1] = {
			guid = guid,
			name = groupInfo.leaderName or groupInfo._mockLeaderName or "",
			clubId = nil,
		}
	end

	-- Extract queue data - Store GROUP TITLE (not activity name!)
	if groupInfo.queues and #groupInfo.queues > 0 then
		for i, queue in ipairs(groupInfo.queues) do
			-- Use groupTitle from groupInfo (the custom group name, e.g., "Wo ist Hayato")
			-- Do NOT use activityName here - that's only for the tooltip!
			local groupTitle = groupInfo.groupTitle or groupInfo._mockActivityName or ""

			-- Get lfgListID from queue data for fetching fresh searchResultInfo in tooltip
			local lfgListID = queue.queueData and queue.queueData.lfgListID
			local queueType = queue.queueData and queue.queueData.queueType or queue.queueType or "lfg"

			entry.displayedQueues[i] = {
				queueData = {
					name = groupTitle, -- Internal storage
					queueType = queueType,
					lfgListID = lfgListID, -- IMPORTANT: Store lfgListID for tooltip leaderName lookup!
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
				isZombie = false, -- Queue is active unless proven otherwise
			}
		end
	else
		-- Fallback: Create one queue entry with group title
		local groupTitle = groupInfo.groupTitle or groupInfo._mockActivityName or ""
		entry.displayedQueues[1] = {
			queueData = {
				name = groupTitle,
				queueType = "lfg",
			},
			cachedQueueName = groupTitle, -- CRITICAL: Cache the name!
			-- Use role needs from groupInfo for fallback too
			needTank = groupInfo.needTank or false,
			needHealer = groupInfo.needHealer or false,
			needDamage = groupInfo.needDamage or false,
			-- Auto-accept flag from groupInfo (for tooltip display)
			isAutoAccept = groupInfo.isAutoAccept or false,
			isZombie = false,
		}
	end

	return entry
end

function QuickJoinEntry:CanJoin()
	return self.groupInfo and self.groupInfo.canJoin ~= false
end

function QuickJoinEntry:ApplyToTooltip(tooltip)
	-- Blizzard's EXACT tooltip structure from LFGListUtil_SetSearchEntryTooltip (lines 4154-4312):
	-- Blizzard uses HELPER FUNCTIONS that apply colors:
	--   GameTooltip_AddHighlightLine() -> HIGHLIGHT_FONT_COLOR (1.0, 0.82, 0 = GOLD/YELLOW)
	--   GameTooltip_AddNormalLine() -> NORMAL_FONT_COLOR (1.0, 1.0, 1.0 = WHITE)
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

	-- 12.0.0+: Track whether secret values are present (combat lockdown).
	-- Secret values can be stored/concatenated/displayed but NOT compared/iterated.
	local hasSecrets = self.groupInfo and self.groupInfo._hasSecretValues

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

	-- User Request: Prioritize BNet Name if available
	local isBNetFriend = false
	if self.groupInfo and self.groupInfo.leaderGUID and C_BattleNet.GetAccountInfoByGUID(self.groupInfo.leaderGUID) then
		isBNetFriend = true
	end

	-- First, try to get fresh searchResultInfo.leaderName for lfglist queues (ONLY if not BNet friend)
	if not isBNetFriend and self.displayedQueues and #self.displayedQueues > 0 and self.displayedQueues[1] then
		local firstQueue = self.displayedQueues[1]
		if firstQueue.queueData and firstQueue.queueData.queueType == "lfglist" and firstQueue.queueData.lfgListID then
			-- CRITICAL: Fetch FRESH searchResultInfo to get CHARACTER name (not cached BNet name)
			local searchResultInfo = C_LFGList.GetSearchResultInfo(firstQueue.queueData.lfgListID)
			if searchResultInfo then
				-- 12.0.0+: Update secret detection for this tooltip render.
				-- Values may have become secret since GetGroupInfo() was called.
				if BFL:IsSecret(searchResultInfo.searchResultID) then
					hasSecrets = true
				end
				-- Secret strings can be stored and passed to SetText/string.format safely
				if searchResultInfo.leaderName then
					leaderName = searchResultInfo.leaderName
				end
			end
		end
	end

	-- Fallback to groupInfo.leaderName (may be BNet account name for non-lfglist queues, which is correct)
	-- 12.0.0+: When hasSecrets, leaderName may be a secret string (truthy).
	-- Skip the == "" comparison to avoid crash on secret values.
	if not leaderName or (not hasSecrets and leaderName == "") then
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

	-- SAFE fallbacks - empty strings are OK
	if not groupTitle then
		groupTitle = ""
	end
	if not leaderName then
		leaderName = ""
	end

	-- Line 1: Group Title (white, word-wrap enabled)
	-- Fix: GameTooltip:SetText arguments are (text, r, g, b, alpha, wrap)
	-- We must explicitly provide alpha (1) before the wrap boolean (true)
	-- Only show if not empty
	-- 12.0.0+: groupTitle may be secret - skip ~= "" comparison, pass directly to SetText
	if hasSecrets or (groupTitle and groupTitle ~= "") then
		tooltip:SetText(groupTitle or " ", 1, 1, 1, 1, true)
	else
		tooltip:SetText(" ", 1, 1, 1, 1, true) -- Fallback: single space to avoid empty tooltip
	end

	-- Line 2: Activity Name (GOLD - HIGHLIGHT_FONT_COLOR: 1.0, 0.82, 0) - Only if different from group title and not empty
	-- 12.0.0+: groupTitle may be secret - skip ~= groupTitle dedup comparison when secret
	if activityName and activityName ~= "" and (hasSecrets or activityName ~= groupTitle) then
		tooltip:AddLine(activityName, 1.0, 0.82, 0)
	end

	-- Line 3: Playstyle (GREEN - 0.1, 1.0, 0.1) - Displayed directly under activity name
	-- Playstyle values: 1 = Standard, 2 = Hardcore (from C_LFGList constants)
	-- 12.0.0+: playstyle may be secret - skip == comparison when secret
	local playstyle = self.groupInfo and self.groupInfo.playstyle
	if playstyle and not hasSecrets then
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
	if comment and (hasSecrets or comment ~= "") then
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
	-- 12.0.0+: leaderFaction may be secret - skip == comparison when secret
	local leaderNameWithFaction = leaderName
	if leaderFaction and not hasSecrets then
		local factionName = nil
		if leaderFaction == 0 then
			factionName = FACTION_HORDE
		elseif leaderFaction == 1 then
			factionName = FACTION_ALLIANCE
		end

		-- Show faction if different from player's faction
		if
			factionName
			and (
				(playerFaction == "Horde" and leaderFaction == 1)
				or (playerFaction == "Alliance" and leaderFaction == 0)
			)
		then
			leaderNameWithFaction = leaderName .. " (" .. factionName .. ")"
		end
	end

	-- Use color code format like MemberCount: gold "Leader:" + white name
	-- Only show if leader name is not empty
	-- 12.0.0+: leaderName may be secret - use truthiness check instead of ~= ""
	if (hasSecrets and leaderName) or (not hasSecrets and leaderName ~= "") then
		local leaderText =
			string.format("|cffffd100%s|r |cffffffff%s|r", L.LEADER_LABEL or "Leader:", leaderNameWithFaction)
		tooltip:AddLine(leaderText)
	end

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

	local memberText = string.format(
		"|cffffd100%s|r |cffffffff%d (%d/%d/%d)|r",
		L.MEMBERS_LABEL or "Members:",
		memberCount,
		tankCount,
		healerCount,
		dpsCount
	)
	tooltip:AddLine(memberText)

	-- Line 6: Empty line (spacing) - BLIZZARD ADDS THIS BEFORE AVAILABLE ROLES
	tooltip:AddLine(" ")

	-- Line 7: Available Roles label (GOLD - HIGHLIGHT_FONT_COLOR: 1.0, 0.82, 0)
	local roleIcons = ""
	if needTank then
		roleIcons = roleIcons
			.. (INLINE_TANK_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:0:16:0:16|t")
	end
	if needHealer then
		roleIcons = roleIcons
			.. (INLINE_HEALER_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:16:32:0:16|t")
	end
	if needDamage then
		roleIcons = roleIcons
			.. (INLINE_DAMAGER_ICON or "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:64:16:32:48:0:16|t")
	end

	if roleIcons ~= "" then
		-- GOLD color (1.0, 0.82, 0) for "Available Roles:" text, avoid AddLine argument issues
		local rolesText = "|cffffd100" .. L.AVAILABLE_ROLES .. "|r " .. roleIcons
		tooltip:AddLine(rolesText)
	else
		tooltip:AddLine(L.NO_AVAILABLE_ROLES)
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
		tooltip:AddLine(L.AUTO_ACCEPT_TOOLTIP, LIGHTBLUE_FONT_COLOR.r, LIGHTBLUE_FONT_COLOR.g, LIGHTBLUE_FONT_COLOR.b)
	end
end

-- Initialize the QuickJoin module
function QuickJoin:Initialize()
	-- Classic Guard: QuickJoin/Social Queue is Retail-only
	if BFL.IsClassic or not BFL.HasQuickJoin then
		-- BFL:DebugPrint("|cffffcc00BFL QuickJoin:|r Not available in Classic - module disabled")
		self.initialized = true -- Prevent future initialization attempts
		return
	end

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

	-- Initialize ScrollBox (Phase 1: Activity Cards)
	if BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame then
		-- Classic: Use FauxScrollFrame approach
		if BFL.IsClassic or not BFL.HasModernScrollBox then
			-- BFL:DebugPrint("|cff00ffffQuickJoin:|r Using Classic FauxScrollFrame mode")
			self:InitializeClassicQuickJoin()
		else
			-- Retail: Use modern ScrollBox system
			-- BFL:DebugPrint("|cff00ffffQuickJoin:|r Using Retail ScrollBox mode")
			local scrollBoxContainer = BetterFriendsFrame.QuickJoinFrame.ContentInset.ScrollBoxContainer
			local scrollBox = scrollBoxContainer.ScrollBox
			local scrollBar = BetterFriendsFrame.QuickJoinFrame.ContentInset.ScrollBar

			-- Create DataProvider
			self.dataProvider = CreateDataProvider()

			-- Initialize ScrollBox with Linear View
			local view = CreateScrollBoxListLinearView()
			view:SetElementInitializer("BetterFriendlistQuickJoinCardTemplate", function(button, elementData)
				self:OnScrollBoxInitialize(button, elementData)
			end)

			-- Set padding
			view:SetPadding(5, 5, 5, 5, 2)

			ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

			-- Dynamic Width Adjustment based on ScrollBar visibility
			local function UpdateScrollBoxWidth()
				scrollBoxContainer:ClearAllPoints()
				scrollBoxContainer:SetPoint("TOPLEFT", 4, -4)
				if scrollBar:IsShown() then
					scrollBoxContainer:SetPoint("BOTTOMRIGHT", -24, 4)
				else
					scrollBoxContainer:SetPoint("BOTTOMRIGHT", -4, 4)
				end
			end

			scrollBar:HookScript("OnShow", UpdateScrollBoxWidth)
			scrollBar:HookScript("OnHide", UpdateScrollBoxWidth)

			-- Initial check
			UpdateScrollBoxWidth()
		end
	end

	-- Initial update
	self:Update()

	-- Start periodic cache cleanup (every 5 minutes)
	if self.cleanupTicker then
		self.cleanupTicker:Cancel()
		self.cleanupTicker = nil
	end

	self.cleanupTicker = C_Timer.NewTicker(300, function()
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

-- Initialize Classic FauxScrollFrame for QuickJoin
function QuickJoin:InitializeClassicQuickJoin()
	local quickJoinFrame = BetterFriendsFrame.QuickJoinFrame
	if not quickJoinFrame then
		return
	end

	self.classicQuickJoinDataList = {}
	self.classicQuickJoinButtonPool = {}

	local CARD_HEIGHT = 72 -- Height of QuickJoin cards
	local NUM_CARDS = 5 -- Max visible cards

	-- Create content frame
	local contentFrame = quickJoinFrame.ContentInset or quickJoinFrame

	-- Create buttons for Classic mode
	for i = 1, NUM_CARDS do
		local button =
			CreateFrame("Button", "BetterQuickJoinCard" .. i, contentFrame, "BetterFriendlistQuickJoinCardTemplate")
		button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -((i - 1) * (CARD_HEIGHT + 2)) - 5)
		button:SetPoint("RIGHT", contentFrame, "RIGHT", -27, 0)
		button:SetHeight(CARD_HEIGHT)
		button.classicIndex = i
		button:Hide()
		self.classicQuickJoinButtonPool[i] = button
	end

	-- Create scroll bar
	if not contentFrame.ClassicScrollBar then
		-- CRITICAL: Do NOT use UIPanelScrollBarTemplate in Classic - it requires SetVerticalScroll method
		local scrollBar = CreateFrame("Slider", nil, contentFrame)
		scrollBar:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -4, -20)
		scrollBar:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -4, 20)
		scrollBar:SetWidth(16)
		scrollBar:SetOrientation("VERTICAL")
		scrollBar:SetMinMaxValues(0, 0)
		scrollBar:SetValueStep(1)
		scrollBar:SetObeyStepOnDrag(true)
		scrollBar:EnableMouseWheel(true)

		-- Create thumb texture
		local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
		thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		thumb:SetSize(18, 24)
		scrollBar:SetThumbTexture(thumb)

		scrollBar:SetScript("OnValueChanged", function(self, value)
			QuickJoin:RenderClassicQuickJoinCards()
		end)
		scrollBar:SetScript("OnMouseWheel", function(self, delta)
			self:SetValue(self:GetValue() - delta)
		end)
		scrollBar:SetValue(0)
		contentFrame.ClassicScrollBar = scrollBar
	end

	-- DataProvider placeholder for Classic
	self.dataProvider = {
		GetSize = function()
			return #QuickJoin.classicQuickJoinDataList
		end,
		Flush = function()
			wipe(QuickJoin.classicQuickJoinDataList)
		end,
		Insert = function(_, data)
			table.insert(QuickJoin.classicQuickJoinDataList, data)
		end,
		Enumerate = function()
			return pairs(QuickJoin.classicQuickJoinDataList)
		end,
	}
end

-- Render Classic QuickJoin cards
function QuickJoin:RenderClassicQuickJoinCards()
	if not self.classicQuickJoinButtonPool then
		return
	end

	local dataList = self.classicQuickJoinDataList or {}
	local numItems = #dataList
	local numButtons = #self.classicQuickJoinButtonPool
	local offset = 0

	local contentFrame = BetterFriendsFrame.QuickJoinFrame.ContentInset or BetterFriendsFrame.QuickJoinFrame
	if contentFrame.ClassicScrollBar then
		offset = math.floor(contentFrame.ClassicScrollBar:GetValue() or 0)
	end

	-- Update scroll bar range
	if contentFrame.ClassicScrollBar then
		local maxValue = math.max(0, numItems - numButtons)
		contentFrame.ClassicScrollBar:SetMinMaxValues(0, maxValue)
	end

	-- Render buttons
	for i, button in ipairs(self.classicQuickJoinButtonPool) do
		local dataIndex = offset + i
		if dataIndex <= numItems then
			local elementData = dataList[dataIndex]
			self:OnScrollBoxInitialize(button, elementData)
			button:Show()
		else
			button:Hide()
		end
	end
end

-- Initialize a card in the ScrollBox
function QuickJoin:OnScrollBoxInitialize(button, elementData)
	local entry = elementData
	local info = entry.groupInfo

	-- 1. Set Icon (Activity Type)
	if button.Icon then
		local icon = info.activityIcon
		if not icon or icon == 0 then
			icon = 134400 -- Interface\Icons\INV_Misc_QuestionMark
		end

		-- Debug Icon
		-- BFL:DebugPrint("SetIcon:", info.groupTitle, icon, type(icon))

		button.Icon:SetTexture(icon)

		-- Handle EJ Icons (Crop to remove transparent padding)
		if info.isEJIcon then
			-- EJ Button images are usually in a texture atlas with padding
			-- Standard crop for EJ list buttons (from EncounterJournal.xml):
			button.Icon:SetTexCoord(0.00390625, 0.71484375, 0.0078125, 0.65625)
		else
			button.Icon:SetTexCoord(0, 1, 0, 1)
		end

		button.Icon:SetShown(true)
	end

	-- 2. Set Title (Group Name)
	if button.Title then
		button.Title:SetText(info.groupTitle or "")
	end

	-- 3. Set Activity (New Line)
	if button.Activity then
		local activityName = info.activityName
		if not activityName or activityName == "" then
			activityName = ""
		end
		button.Activity:SetText(activityName)
	end

	-- 4. Set Details (Leader + Friends)
	if button.Details then
		-- Leader Name (colored)
		local leaderName = info.leaderName or ""
		local leaderColor = info.leaderColor or "|cffffffff"
		local details = ""
		local hasDetails = false

		-- Only show leader if name is not empty
		-- 12.0.0+: leaderName may be secret - use truthiness check when secret
		if (info._hasSecretValues and leaderName) or (not info._hasSecretValues and leaderName ~= "") then
			details = L.LEADER_LABEL .. " " .. leaderColor .. leaderName .. "|r"
			hasDetails = true
		end

		-- Add other friends if present (already colored in GetGroupInfo)
		if info.otherFriends and #info.otherFriends > 0 then
			local friendsList = table.concat(info.otherFriends, ", ")
			if hasDetails then
				details = details .. " (+ " .. friendsList .. ")"
			else
				details = "+ " .. friendsList
			end
		end

		button.Details:SetText(details)
	end

	-- 5. Set Member Count (New Frame)
	if button.MemberCount then
		local count = info.numMembers or 1
		local tanks = info.numTanks or 0
		local healers = info.numHealers or 0
		local dps = info.numDPS or 0

		-- Format: "14 (1/2/11)" - Compact format to save space
		-- Using a group icon texture would be nice, but text is clearer for now
		button.MemberCount:SetText(string.format("|cffffd100%d|r |cffffffff(%d/%d/%d)|r", count, tanks, healers, dps))
	end

	-- 6. Update Role Icons
	if button.RoleContainer then
		local container = button.RoleContainer
		if container.TankIcon then
			container.TankIcon:SetShown(info.needTank)
		end
		if container.HealerIcon then
			container.HealerIcon:SetShown(info.needHealer)
		end
		if container.DPSIcon then
			container.DPSIcon:SetShown(info.needDamage)
		end

		-- Layout role icons (simple horizontal stack)
		local lastIcon = nil
		local icons = { container.TankIcon, container.HealerIcon, container.DPSIcon }
		for _, icon in ipairs(icons) do
			if icon and icon:IsShown() then
				icon:ClearAllPoints()
				if lastIcon then
					icon:SetPoint("LEFT", lastIcon, "RIGHT", 2, 0)
				else
					icon:SetPoint("LEFT", container, "LEFT", 0, 0)
				end
				lastIcon = icon
			end
		end
	end

	-- 5. Setup Join Button
	if button.JoinButton then
		button.JoinButton:SetEnabled(info.canJoin)
		button.JoinButton:SetScript("OnClick", function()
			self:RequestToJoin(entry.guid)
		end)
	end

	-- 6. CRITICAL: Store button references for selection system
	button.guid = entry.guid
	button.entry = entry
	self.selectedButtons[entry.guid] = button

	-- 7. Setup Click Handler for selection
	button:SetScript("OnClick", function(btn, mouseButton)
		BetterQuickJoinGroupButton_OnClick(btn, mouseButton)
	end)

	-- 8. Update selection visual if this button is the selected one
	if button.Selected then
		if self.selectedGUID == entry.guid then
			button.Selected:Show()
		else
			button.Selected:Hide()
		end
	end

	-- 9. Tooltip
	button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		entry:ApplyToTooltip(GameTooltip)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
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
		-- BFL:DebugPrint("QuickJoin: Cleaned up", cleaned, "old cache entries")
	end
end

-- Update available groups list
function QuickJoin:Update(forceUpdate)
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
	if self.relationshipCache then
		wipe(self.relationshipCache)
	end
	self.entriesCache = nil
	self.entriesCacheVersion = nil

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

	-- Update tab counter (ALWAYS update this, even if frame is hidden)
	if BetterFriendsFrame and BetterFriendsFrame_UpdateQuickJoinTab then
		BetterFriendsFrame_UpdateQuickJoinTab()
	end

	-- Visibility Optimization:
	-- If the frame (or the QuickJoin tab) is hidden, don't rebuild the ScrollBox.
	if
		not BetterFriendsFrame
		or not BetterFriendsFrame:IsShown()
		or not BetterFriendsFrame.QuickJoinFrame
		or not BetterFriendsFrame.QuickJoinFrame:IsShown()
	then
		needsRenderOnShow = true
		return
	end

	-- Update ScrollBox DataProvider
	if self.dataProvider then
		local entries = {}
		for _, guid in ipairs(self.availableGroups) do
			local groupInfo = self:GetGroupInfo(guid)
			if groupInfo then
				local entry = QuickJoinEntry:New(guid, groupInfo)
				table.insert(entries, entry)
			end
		end

		-- Classic mode: Use simple list and render
		if BFL.IsClassic or not BFL.HasModernScrollBox then
			self.classicQuickJoinDataList = entries
			self:RenderClassicQuickJoinCards()
		else
			-- Retail mode: Use DataProvider
			self.dataProvider:Flush()
			self.dataProvider:InsertTable(entries)
		end

		-- Update "No Groups" text
		if
			BetterFriendsFrame
			and BetterFriendsFrame.QuickJoinFrame
			and BetterFriendsFrame.QuickJoinFrame.ContentInset.NoGroupsText
		then
			BetterFriendsFrame.QuickJoinFrame.ContentInset.NoGroupsText:SetShown(#entries == 0)
			if #entries == 0 then
				BetterFriendsFrame.QuickJoinFrame.ContentInset.NoGroupsText:SetText(
					L.QUICK_JOIN_NO_GROUPS or QUICK_JOIN_NO_GROUPS or "No groups available"
				)
			end
		end
	end

	-- Fire callback for UI update (Legacy support)
	if self.onUpdateCallback then
		self.onUpdateCallback(self.availableGroups)
	end
end

-- Get information about a specific group
function QuickJoin:GetGroupInfo(groupGUID)
	if not groupGUID then
		return nil
	end

	-- Check for mock data first (mock groups are always prioritized)
	if self.mockGroups[groupGUID] then
		local mockGroup = self.mockGroups[groupGUID]
		-- Ensure details are populated for mock groups
		PopulateGroupMemberDetails(mockGroup)

		-- Try to resolve icon if missing (simulating real group behavior)
		if not mockGroup.activityIcon or mockGroup.activityIcon == 0 then
			self:ResolveMockIcon(mockGroup)
		end

		return mockGroup
	end

	-- Try to get cached info first
	local cached = self.groupCache[groupGUID]
	if cached and (GetTime() - cached.timestamp < 2.0) then
		return cached.info
	end

	-- Get fresh info from API
	local canJoin, numQueues, needTank, needHealer, needDamage, isSoloQueueParty, questSessionActive, leaderGUID =
		C_SocialQueue.GetGroupInfo(groupGUID)

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
		requestedToJoin = C_SocialQueue.GetGroupForPlayer(groupGUID) ~= nil, -- Check if already requested
		numMembers = 0, -- Will be calculated below
		leaderName = "",
		activityName = "",
		activityIcon = nil, -- Will be resolved later
		queueInfo = "",
	}

	-- Calculate member count
	if info.members then
		PopulateGroupMemberDetails(info)
	end

	-- Get GROUP TITLE from queues (NOT activity name!)
	-- Blizzard's approach: Display searchResultInfo.name for LFG List (the group's custom title)
	if info.queues and #info.queues > 0 and info.queues[1] then
		local queueData = info.queues[1].queueData
		if queueData then
			-- BFL:DebugPrint("QuickJoin Debug: Processing Group", groupGUID)
			-- BFL:DebugPrint("  QueueType:", queueData.queueType)

			-- Get group title/name based on queue type
			if queueData.queueType == "lfglist" and queueData.lfgListID then
				-- BFL:DebugPrint("QuickJoin Debug: Processing Group", groupGUID)
				-- BFL:DebugPrint("  QueueType:", queueData.queueType)
				-- BFL:DebugPrint("  LFGList ID:", queueData.lfgListID)

				-- Detailed QueueData Dump
				if queueData then
					for k, v in pairs(queueData) do
						-- BFL:DebugPrint(string.format("  queueData.%s = %s", tostring(k), tostring(v)))
					end
				end

				-- For LFG List: Blizzard displays searchResultInfo.name (the custom group title)
				-- NOT the activity name! (QuickJoin.lua doesn't even use activities)
				local searchResultInfo = C_LFGList.GetSearchResultInfo(queueData.lfgListID)

				-- 12.0.0+: C_LFGList.GetSearchResultInfo returns secret field values during
				-- combat lockdown (SecretInChatMessagingLockdown). Secret values can be
				-- stored, concatenated, and passed to SetText/string.format, but CANNOT be
				-- compared, iterated (pairs/next), indexed, or used in arithmetic.
				-- We detect this and use a passthrough path that preserves display data.
				local hasSecretValues = searchResultInfo and BFL:IsSecret(searchResultInfo.searchResultID)

				if searchResultInfo then
					if hasSecretValues then
						info._hasSecretValues = true
					end

					-- Detailed SearchResult Dump (skip when secret - pairs() crashes on secret values)
					if not hasSecretValues then
						for k, v in pairs(searchResultInfo) do
							-- BFL:DebugPrint(string.format("    searchResultInfo.%s = %s", tostring(k), tostring(v)))
						end
					end

					-- Protected strings are safe to use directly
					info.groupTitle = searchResultInfo.name

					-- IMPORTANT: Use numMembers from searchResultInfo, NOT from members array!
					-- members array only contains visible members (usually just leader)
					if searchResultInfo.numMembers then
						info.numMembers = searchResultInfo.numMembers
					end

					-- IMPORTANT: Use leaderName and leaderFactionGroup from searchResultInfo!
					if searchResultInfo.leaderName then
						-- Only overwrite if NOT a BNet friend (User Request: Prioritize BNet Name)
						local isBNetFriend = false
						if info.leaderGUID and C_BattleNet.GetAccountInfoByGUID(info.leaderGUID) then
							isBNetFriend = true
						end

						if not isBNetFriend then
							info.leaderName = searchResultInfo.leaderName
						end
					end
					if searchResultInfo.leaderFactionGroup then
						info.leaderFactionGroup = searchResultInfo.leaderFactionGroup
					end

					-- Get role distribution using C_LFGList.GetSearchResultMemberCounts
					-- Skip when secret: this API may also return secret values during lockdown
					if not hasSecretValues then
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
					else
						info.numTanks = 0
						info.numHealers = 0
						info.numDPS = 0
					end

					-- Activity name & Icon
					local activityID
					if hasSecretValues then
						-- When secret: searchResultInfo fields are secret and cannot be iterated,
						-- indexed, or compared. Use queueData.activityID (non-secret, from
						-- C_SocialQueue) for activity resolution instead.
						activityID = queueData.activityID
					else
						activityID = searchResultInfo.activityID or queueData.activityID

						-- CRITICAL FIX: Handle activityIDs table (plural) which Blizzard uses now
						if searchResultInfo.activityIDs then
							-- BFL:DebugPrint("  activityIDs table found:")
							for k, v in pairs(searchResultInfo.activityIDs) do
								-- BFL:DebugPrint(string.format("    [%s] = %s", tostring(k), tostring(v)))
							end

							if not activityID then
								-- Try to grab the first ID (usually it's an array)
								if searchResultInfo.activityIDs[1] then
									activityID = searchResultInfo.activityIDs[1]
								else
									-- Fallback for non-array tables (key-value or set)
									local k, v = next(searchResultInfo.activityIDs)
									if v and type(v) == "number" then
										activityID = v
									elseif k and type(k) == "number" then
										activityID = k
									end
								end
								-- BFL:DebugPrint("  Resolved ActivityID from activityIDs table:", activityID)
							end
						end
					end

					-- BFL:DebugPrint("  Resolved ActivityID:", activityID)

					if activityID then
						local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
						if activityInfo then
							-- BFL:DebugPrint("  ActivityInfo Found:", activityInfo.fullName)
							info.activityName = activityInfo.fullName

							if activityInfo.groupFinderActivityGroupID then
								local _, groupIcon =
									C_LFGList.GetActivityGroupInfo(activityInfo.groupFinderActivityGroupID)
								-- BFL:DebugPrint("  GroupFinderActivityGroupID:", activityInfo.groupFinderActivityGroupID)
								-- BFL:DebugPrint("  GroupIcon from API:", groupIcon)

								-- Blizzard sometimes returns garbage IDs (like 20 for Tazavesh)
								-- Valid FileDataIDs are usually large numbers (> 10000)
								if groupIcon and groupIcon > 10000 then
									info.activityIcon = groupIcon
								else
									-- BFL:DebugPrint("  Ignored invalid GroupIcon from API:", groupIcon)
								end
							else
								-- BFL:DebugPrint("  No GroupFinderActivityGroupID in ActivityInfo")
							end

							-- Smart Fallback: Try to get icon from Encounter Journal via MapID
							if not info.activityIcon or info.activityIcon == 0 then
								-- BFL:DebugPrint("  Smart Fallback: Checking MapID:", activityInfo.mapID)

								local currentMapID = activityInfo.mapID
								local instanceID = 0
								local depth = 0

								-- Traverse up the map hierarchy (max 3 levels)
								while currentMapID and currentMapID > 0 and depth < 3 do
									instanceID = EJ_GetInstanceForMap(currentMapID)

									if instanceID and instanceID > 0 then
										break
									end

									local mapInfo = C_Map.GetMapInfo(currentMapID)
									if mapInfo and mapInfo.parentMapID then
										currentMapID = mapInfo.parentMapID
										depth = depth + 1
									else
										break
									end
								end

								if instanceID and instanceID > 0 then
									local name, _, _, buttonImage = EJ_GetInstanceInfo(instanceID)

									if buttonImage and buttonImage ~= 0 then
										info.activityIcon = buttonImage
										info.isEJIcon = true
										-- BFL:DebugPrint("  Smart Fallback: APPLIED EJ Icon:", buttonImage)
									end
								end
							end

							-- Smart Fallback 2: Name-based lookup in Encounter Journal
							-- If MapID lookup failed, try to find an instance with a matching name
							if (not info.activityIcon or info.activityIcon == 0) and info.activityName then
								-- BFL:DebugPrint("  Smart Fallback 2: Searching EJ by Name:", info.activityName)

								-- Clean activity name (remove difficulty suffix like " (Mythic)")
								local cleanName = info.activityName:gsub("%s*%(.*%)", "")

								-- Normalize names for split-dungeons or complex names to improve EJ matching
								if cleanName:find("Tazavesh") then
									cleanName = "Tazavesh"
								end
								if cleanName:find("Mechagon") then
									cleanName = "Mechagon"
								end
								if cleanName:find("Karazhan") then
									cleanName = "Karazhan"
								end

								-- BFL:DebugPrint("  Cleaned Name:", cleanName)

								-- Iterate through ALL tiers to find the instance
								-- We iterate backwards from the latest tier (most likely content) down to Classic.
								local numTiers = EJ_GetNumTiers()
								local currentTier = EJ_GetCurrentTier()

								local tiersToCheck = {}
								for i = numTiers, 1, -1 do
									table.insert(tiersToCheck, i)
								end

								for _, tier in ipairs(tiersToCheck) do
									EJ_SelectTier(tier)
									local index = 1
									while true do
										local instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, true) -- Raid
										if not instanceID then
											break
										end

										if name and (name == cleanName or name:find(cleanName, 1, true)) then
											if buttonImage then
												info.activityIcon = buttonImage
												info.isEJIcon = true
												-- BFL:DebugPrint("  Smart Fallback 2: Found Match (Raid):", name, buttonImage)
												break
											end
										end
										index = index + 1
									end

									if info.activityIcon and info.activityIcon ~= 0 then
										break
									end

									index = 1
									while true do
										local instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, false) -- Dungeon
										if not instanceID then
											break
										end

										if name and (name == cleanName or name:find(cleanName, 1, true)) then
											if buttonImage then
												info.activityIcon = buttonImage
												info.isEJIcon = true
												-- BFL:DebugPrint("  Smart Fallback 2: Found Match (Dungeon):", name, buttonImage)
												break
											end
										end
										index = index + 1
									end

									if info.activityIcon and info.activityIcon ~= 0 then
										break
									end
								end

								-- Restore original tier
								EJ_SelectTier(currentTier)
							end

							-- Fallback if icon is missing or 0
							if not info.activityIcon or info.activityIcon == 0 then
								local catID = activityInfo.categoryID
								-- BFL:DebugPrint("          Icon missing, trying category fallback: categoryID="..tostring(catID))

								if catID == 2 then -- Dungeons
									info.activityIcon = 525134 -- Fallback: Dungeon (Keystone)
									-- BFL:DebugPrint("          ✅ Applied Dungeon fallback icon: 525134")
								elseif catID == 3 then -- Raids
									info.activityIcon = 1536895 -- User Selected: Raid
									-- BFL:DebugPrint("          ✅ Applied Raid fallback icon: 1536895")
								elseif catID == 4 or catID == 5 or catID == 7 or catID == 8 or catID == 9 then -- PvP
									info.activityIcon = 236396 -- User Selected: PvP
									-- BFL:DebugPrint("          ✅ Applied PvP fallback icon: 236396")
								elseif catID == 1 then -- Questing
									info.activityIcon = 409602 -- User Selected: Quest
									-- BFL:DebugPrint("          ✅ Applied Quest fallback icon: 409602")
								elseif catID == 6 then -- Custom
									info.activityIcon = 134149 -- User Selected: Custom
									-- BFL:DebugPrint("          ✅ Applied Custom fallback icon: 134149")
								end

								-- Heuristic if category didn't match (e.g. Legacy Raids might have different ID)
								if not info.activityIcon or info.activityIcon == 0 then
									-- BFL:DebugPrint("          Category fallback failed, trying player count heuristic: maxNumPlayers="..tostring(activityInfo.maxNumPlayers))
									if activityInfo.maxNumPlayers and activityInfo.maxNumPlayers > 5 then
										info.activityIcon = 1536895 -- Assume Raid
										-- BFL:DebugPrint("          ✅ Heuristic: Assumed Raid (>5 players): 1536895")
									elseif activityInfo.maxNumPlayers and activityInfo.maxNumPlayers == 5 then
										info.activityIcon = 525134 -- Assume Dungeon (Keystone)
										-- BFL:DebugPrint("          ✅ Heuristic: Assumed Dungeon (5 players): 525134")
									end
								end
							end
						else
							-- BFL:DebugPrint("  ActivityInfo is NIL for ID:", activityID)
						end
					else
						-- BFL:DebugPrint("  No ActivityID found in SearchResult or QueueData")
						info.groupTitle = info.activityName
						-- BFL:DebugPrint("  Fixed GroupTitle using ActivityName:", info.groupTitle)
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
					-- BFL:DebugPrint("  SearchResult is NIL for ID:", queueData.lfgListID)
					-- Fallback if search result not available
					info.groupTitle = "LFG Group"

					-- Try to get activity name from queueData if available
					if queueData.activityID then
						-- BFL:DebugPrint("      Fallback: Using queueData.activityID="..tostring(queueData.activityID))
						local activityInfo = C_LFGList.GetActivityInfoTable(queueData.activityID)
						if activityInfo then
							info.activityName = activityInfo.fullName
							-- BFL:DebugPrint("      Fallback Activity Name: \""..(info.activityName or "NIL").."\"")
							local _, groupIcon = C_LFGList.GetActivityGroupInfo(activityInfo.groupFinderActivityGroupID)
							if groupIcon then
								info.activityIcon = groupIcon
							end
						else
							-- BFL:DebugPrint("  ActivityInfo is NIL for ID:", queueData.activityID)
						end
					else
						-- BFL:DebugPrint("  Fallback: No activityID in queueData")
					end
				end
			elseif queueData.queueType == "pvp" then
				-- BFL:DebugPrint("  QueueType: PvP")
				info.groupTitle = self:ResolveQueueName(info.queues[1]) or "PvP"
				info.activityIcon = 236396 -- User Selected: PvP
			elseif queueData.queueType == "lfg" then
				-- BFL:DebugPrint("  QueueType: LFG (Dungeon/Raid Finder)")
				info.groupTitle = self:ResolveQueueName(info.queues[1]) or "Dungeon Finder"

				-- Try to determine if it's a raid or dungeon for icon
				if info.groupTitle:find(SOCIAL_QUEUE_FORMAT_RAID or "(Raid)") then
					info.activityIcon = 1536895 -- Raid
				else
					info.activityIcon = 525134 -- Dungeon
				end
			elseif queueData.queueType == "dungeon" or queueData.lfgDungeonID then
				-- Legacy/Fallback handling
				info.groupTitle = self:ResolveQueueName(info.queues[1]) or "Dungeon"
				info.activityIcon = 525134 -- Dungeon
			elseif queueData.queueType == "raid" then
				info.groupTitle = self:ResolveQueueName(info.queues[1]) or "Raid"
				info.activityIcon = 1536895 -- Raid
			else
				-- BFL:DebugPrint("  QueueType: Unknown/Other:", queueData.queueType)
				info.groupTitle = self:ResolveQueueName(info.queues[1])
					or queueData.queueType
					or info.queues[1].name
					or ""
			end
		end

		-- Build queue info string
		if #info.queues > 1 then
			info.queueInfo = string.format("%d activities", #info.queues)
		end
	end

	-- FIX: Icon Overrides for known broken icons (Green Squares)
	if info.activityName then
		-- Add other overrides here if needed
	end

	-- Cache the info
	self.groupCache[groupGUID] = {
		info = info,
		timestamp = GetTime(),
	}

	return info
end

--[[
	Resolve queue name based on Blizzard's SocialQueueUtil implementation
	Fixes missing details for PvP, Dungeons, and Raids
]]
function QuickJoin:ResolveQueueName(queue)
	if not queue or not queue.queueData then
		return nil
	end
	local queueData = queue.queueData
	local queueType = queueData.queueType

	if queueType == "lfg" then
		-- Dungeon/Raid Finder
		local names = {}
		if queueData.lfgIDs then
			for _, lfgID in ipairs(queueData.lfgIDs) do
				local name, typeID, subtypeID, _, _, _, _, _, _, _, _, _, _, _, isHoliday, _, _, isTimeWalker =
					GetLFGDungeonInfo(lfgID)

				if name then
					if isTimeWalker or isHoliday or typeID == TYPEID_RANDOM_DUNGEON then
						-- Name remains unchanged
					elseif subtypeID == LFG_SUBTYPEID_DUNGEON then
						-- SOCIAL_QUEUE_FORMAT_DUNGEON = "%s (Dungeon)"
						name = string.format(SOCIAL_QUEUE_FORMAT_DUNGEON or "%s (Dungeon)", name)
					elseif subtypeID == LFG_SUBTYPEID_HEROIC then
						-- SOCIAL_QUEUE_FORMAT_HEROIC_DUNGEON = "%s (Heroic)"
						name = string.format(SOCIAL_QUEUE_FORMAT_HEROIC_DUNGEON or "%s (Heroic)", name)
					elseif subtypeID == LFG_SUBTYPEID_RAID then
						-- SOCIAL_QUEUE_FORMAT_RAID = "%s (Raid)"
						name = string.format(SOCIAL_QUEUE_FORMAT_RAID or "%s (Raid)", name)
					elseif subtypeID == LFG_SUBTYPEID_FLEXRAID then
						name = string.format(SOCIAL_QUEUE_FORMAT_RAID or "%s (Raid)", name)
					elseif subtypeID == LFG_SUBTYPEID_WORLDPVP then
						-- SOCIAL_QUEUE_FORMAT_WORLDPVP = "%s (PvP)"
						name = string.format(SOCIAL_QUEUE_FORMAT_WORLDPVP or "%s (PvP)", name)
					end
					table.insert(names, name)
				end
			end
		end

		if #names > 0 then
			return table.concat(names, " + ")
		end
	elseif queueType == "pvp" then
		-- PvP Queues
		if queueData.isBrawl and C_PvP.GetAvailableBrawlInfo then
			local brawlInfo = C_PvP.GetAvailableBrawlInfo()
			if brawlInfo and brawlInfo.active and brawlInfo.name then
				return brawlInfo.name
			end
			return L.ACTIVITY_BRAWL or "Brawl"
		elseif queueData.battlefieldType == "BATTLEGROUND" then
			if queueData.mapName then
				name = string.format(SOCIAL_QUEUE_FORMAT_BATTLEGROUND or "%s (Battleground)", queueData.mapName)
				return name
			end
			return L.ACTIVITY_BATTLEGROUND or "Battleground"
		elseif queueData.battlefieldType == "ARENA" then
			if queueData.teamSize then
				return string.format(SOCIAL_QUEUE_FORMAT_ARENA or "%dv%d Arena", queueData.teamSize, queueData.teamSize)
			end
			return L.ACTIVITY_ARENA or "Arena"
		elseif queueData.battlefieldType == "ARENASKIRMISH" then
			return SOCIAL_QUEUE_FORMAT_ARENA_SKIRMISH or "Arena Skirmish"
		end
		return L.ACTIVITY_PVP or "PvP"
	end

	return nil
end

--[[
	Resolve icon for mock group using same logic as real groups
]]
function QuickJoin:ResolveMockIcon(info)
	if info.activityIcon and info.activityIcon ~= 0 then
		return
	end

	-- 1. EJ Lookup (Name based) - "Smart Fallback 2" logic
	if info.activityName then
		-- Clean activity name (remove difficulty suffix like " (Mythic)")
		local cleanName = info.activityName:gsub("%s*%(.*%)", "")

		-- Normalize names for split-dungeons or complex names to improve EJ matching
		if cleanName:find("Tazavesh") then
			cleanName = "Tazavesh"
		end
		if cleanName:find("Mechagon") then
			cleanName = "Mechagon"
		end
		if cleanName:find("Karazhan") then
			cleanName = "Karazhan"
		end

		-- Iterate through ALL tiers to find the instance
		local numTiers = EJ_GetNumTiers()
		local currentTier = EJ_GetCurrentTier()

		local tiersToCheck = {}
		for i = numTiers, 1, -1 do
			table.insert(tiersToCheck, i)
		end

		for _, tier in ipairs(tiersToCheck) do
			EJ_SelectTier(tier)
			local index = 1
			while true do
				local instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, true) -- Raid
				if not instanceID then
					break
				end

				if name and (name == cleanName or name:find(cleanName, 1, true)) then
					if buttonImage and buttonImage ~= 0 then
						info.activityIcon = buttonImage
						info.isEJIcon = true
						break
					end
				end
				index = index + 1
			end

			if info.activityIcon and info.activityIcon ~= 0 then
				break
			end

			index = 1
			while true do
				local instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, false) -- Dungeon
				if not instanceID then
					break
				end

				if name and (name == cleanName or name:find(cleanName, 1, true)) then
					if buttonImage and buttonImage ~= 0 then
						info.activityIcon = buttonImage
						info.isEJIcon = true
						break
					end
				end
				index = index + 1
			end

			if info.activityIcon and info.activityIcon ~= 0 then
				break
			end
		end

		-- Restore original tier
		EJ_SelectTier(currentTier)
	end

	-- 2. Category Fallback (based on queueType/activityType)
	if not info.activityIcon or info.activityIcon == 0 then
		if info._queueType == "lfglist" then
			if info.activityType == "Raid" or (info.activityName and info.activityName:find("Raid")) then
				info.activityIcon = 1536895 -- Raid
			elseif
				info.activityType == "Dungeon"
				or info.activityType == "Mythic+ Dungeon"
				or (info.activityName and info.activityName:find("Dungeon"))
			then
				info.activityIcon = 525134 -- Dungeon
			elseif info.activityType == "Questing" then
				info.activityIcon = 409602 -- Quest
			else
				info.activityIcon = 134149 -- Custom/Other
			end
		elseif info._queueType == "lfg" then
			info.activityIcon = 525134 -- Dungeon
		elseif info._queueType == "pvp" then
			info.activityIcon = 236396 -- PvP
		end
	end

	-- 3. Ultimate Fallback
	if not info.activityIcon then
		info.activityIcon = 134400
	end
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
		UIErrorsFrame:AddMessage(
			"|cff00ff00" .. (L.MOCK_JOIN_REQUEST_SENT or "Mock join request sent"),
			0.1,
			0.8,
			1.0,
			1.0
		)
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

-- QuickJoinEntry methods (Legacy/Bottom definition merged with top)

-- Apply entry data to button frame (Blizzard's HORIZONTAL layout)
-- Members (left) â†’ Icon (middle) â†’ Queues (right) ALL ON ONE LINE

-- Apply entry to tooltip (EXACT Blizzard replication)

-- Get all available groups as QuickJoinEntry objects (public API)
function QuickJoin:GetEntries()
	if self.entriesCache and self.entriesCacheVersion == self.lastUpdate then
		return self.entriesCache
	end

	local entries = {}
	local groups = self.availableGroups or {}

	for i, guid in ipairs(groups) do
		local groupInfo = self:GetGroupInfo(guid)
		if groupInfo then
			local entry = QuickJoinEntry:New(guid, groupInfo)
			table.insert(entries, entry)
		end
	end

	self.entriesCache = entries
	self.entriesCacheVersion = self.lastUpdate
	return entries
end

function QuickJoin:RebuildMockMemberIndex()
	wipe(self.mockMemberByGuid)
	for _, mockGroup in pairs(self.mockGroups) do
		if mockGroup.members then
			for _, member in ipairs(mockGroup.members) do
				if member.guid then
					self.mockMemberByGuid[member.guid] = member
				end
			end
		end
	end
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
		local leaderName = mockGroup.leaderName or ""
		local numMembers = mockGroup.numMembers or 1
		local color = "|cff00ff00" -- Green for mock groups

		if numMembers > 1 then
			return string.format("%s%s|r +%d", color, leaderName, numMembers - 1)
		else
			return string.format("%s%s|r", color, leaderName)
		end
	end

	local members = C_SocialQueue.GetGroupMembers(groupGUID)
	if not members or #members == 0 then
		return ""
	end

	-- Sort members (leader first)
	table.sort(members, function(a, b)
		return (a.isLeader or false) and not (b.isLeader or false)
	end)

	-- Get leader name
	if not members or #members == 0 or not members[1] then
		return ""
	end

	local leaderName = members[1].clubName or members[1].name or ""
	local color = "|cffffffff" -- Default white

	-- Try to determine relationship for color
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(members[1].guid)
	if accountInfo then
		color = FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff" -- BNet blue
	else
		local friendInfo = GetFriendInfoByGUID(members[1].guid)
		if friendInfo then
			color = FRIENDS_WOW_NAME_COLOR_CODE or "|cff00ff00" -- Friend green
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
		return mockGroup.groupTitle or mockGroup.activityName or ""
	end

	local queues = C_SocialQueue.GetGroupQueues(groupGUID)
	if not queues or #queues == 0 or not queues[1] then
		return ""
	end

	-- Get queue name from first queue
	local queueName = ""
	local queueData = queues[1].queueData

	if queueData then
		if queueData.queueType == "lfglist" and queueData.lfgListID then
			local activityInfo = C_LFGList.GetActivityInfoTable(queueData.lfgListID)
			if activityInfo then
				queueName = activityInfo.fullName or activityInfo.shortName or ""
			else
				queueName = ""
			end
		elseif queueData.queueType == "pvp" then
			queueName = L.ACTIVITY_PVP or "PvP"
		elseif queueData.queueType == "dungeon" then
			queueName = L.ACTIVITY_DUNGEON or "Dungeon"
		elseif queueData.queueType == "raid" then
			queueName = L.ACTIVITY_RAID or "Raid"
		else
			queueName = queueData.queueType or ""
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
	"Anduin",
	"Jaina",
	"Genn",
	"Alleria",
	"Turalyon",
	"Velen",
	"Tyrande",
	"Malfurion",
	"Muradin",
	"Mekkatorque",
	"Aysa",
	"Tess",
	"Shaw",
	"Magni",
	"Khadgar",
	-- Horde
	"Thrall",
	"Sylvanas",
	"Baine",
	"Lor'themar",
	"Thalyssra",
	"Gazlowe",
	"Ji",
	"Rokhan",
	"Geya'rah",
	"Calia",
	"Eitrigg",
	"Saurfang",
	"Vol'jin",
	"Rexxar",
	-- Neutral
	"Chromie",
	"Wrathion",
	"Alexstrasza",
	"Ysera",
	"Nozdormu",
	"Kalecgos",
	"VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout",
}

-- Realistic activity names by type
local MOCK_ACTIVITIES = {
	lfglist_mythicplus = {
		{ "M+ Gruppe sucht DD", "Mythic+ Dungeon", "Need experienced DPS, voice preferred" },
		{ "NW +22 Timing Run", "Mythic+ Dungeon", "2.8k+ rio, have route" },
		{ "Mists Weekly - Chill", "Mythic+ Dungeon", "No timer pressure, all welcome" },
		{ "Keys for Vault", "Mythic+ Dungeon", "Any level, just for vault slots" },
		{ "CoS +20 Push", "Mythic+ Dungeon", "Going for KSH, need good players" },
		{ "BRH Fortified Farm", "Mythic+ Dungeon", "Quick runs, know the dungeon" },
		{ "Atal'Dazar +18", "Mythic+ Dungeon", "Learning route, be patient" },
		{ "Stonevault +25 Title", "Mythic+ Dungeon", "0.1% title push, 3k+ only" },
		{
			"ThisIsAVeryLongSocialQueueTitleThatIdeallyShouldTruncateOrWrapCorrectlyInTheList",
			"Mythic+ Dungeon",
			"Testing long names in Social Queue",
		},
	},
	lfglist_raid = {
		{ "Nerub-ar Palace Normal", "Raid", "Full clear, new players welcome" },
		{ "NaP Heroic - AOTC Run", "Raid", "Link AOTC or 580+ ilvl" },
		{ "Queen Ansurek Only", "Raid", "Farm boss, know mechanics" },
		{ "Palace Mythic Progress", "Raid", "Guild run, need 1 healer" },
		{ "AnotherVeryLongRaidTitleForTestingTruncationInTheSocialQueueListLayout", "Raid", "Testing long raid names" },
	},
	lfg_dungeon = {
		{ "Random Heroic", "Heroic Dungeon" },
		{ "Normal Dungeon", "Normal Dungeon" },
		{ "Timewalking", "Timewalking Dungeon" },
		{ "Follower Dungeon", "Follower Dungeon" },
	},
	pvp = {
		{ "RBG 2400+ Push", "Rated Battleground", "Voice required, have strats" },
		{ "Casual BGs", "Battleground", "Just for fun, no ragers" },
		{ "Arena 3v3 Practice", "Arena", "Learning comps, be chill" },
		{ "Solo Shuffle Warmup", "Solo Shuffle", "Getting games in" },
		{ "Epic BG Group", "Epic Battleground", "AV/IoC farm" },
	},
}

-- Class data for realistic members
local MOCK_CLASSES = {
	{ name = "WARRIOR", icon = "Interface\\Icons\\ClassIcon_Warrior", roles = { "TANK", "DAMAGER" } },
	{ name = "PALADIN", icon = "Interface\\Icons\\ClassIcon_Paladin", roles = { "TANK", "HEALER", "DAMAGER" } },
	{ name = "HUNTER", icon = "Interface\\Icons\\ClassIcon_Hunter", roles = { "DAMAGER" } },
	{ name = "ROGUE", icon = "Interface\\Icons\\ClassIcon_Rogue", roles = { "DAMAGER" } },
	{ name = "PRIEST", icon = "Interface\\Icons\\ClassIcon_Priest", roles = { "HEALER", "DAMAGER" } },
	{ name = "DEATHKNIGHT", icon = "Interface\\Icons\\ClassIcon_DeathKnight", roles = { "TANK", "DAMAGER" } },
	{ name = "SHAMAN", icon = "Interface\\Icons\\ClassIcon_Shaman", roles = { "HEALER", "DAMAGER" } },
	{ name = "MAGE", icon = "Interface\\Icons\\ClassIcon_Mage", roles = { "DAMAGER" } },
	{ name = "WARLOCK", icon = "Interface\\Icons\\ClassIcon_Warlock", roles = { "DAMAGER" } },
	{ name = "MONK", icon = "Interface\\Icons\\ClassIcon_Monk", roles = { "TANK", "HEALER", "DAMAGER" } },
	{ name = "DRUID", icon = "Interface\\Icons\\ClassIcon_Druid", roles = { "TANK", "HEALER", "DAMAGER" } },
	{ name = "DEMONHUNTER", icon = "Interface\\Icons\\ClassIcon_DemonHunter", roles = { "TANK", "DAMAGER" } },
	{ name = "EVOKER", icon = "Interface\\Icons\\ClassIcon_Evoker", roles = { "HEALER", "DAMAGER" } },
}

-- ============================================
-- MOCK SYSTEM STATE
-- ============================================
-- Note: QuickJoin.mockGroups is initialized at module top (line ~40)

QuickJoin.mockUpdateTimer = nil -- Timer for dynamic updates
QuickJoin.mockEventQueue = {} -- Queued events for simulation
QuickJoin.mockConfig = {
	dynamicUpdates = true, -- Enable/disable member count changes
	updateInterval = 3.0, -- Seconds between dynamic updates
	eventSimulation = false, -- Simulate SOCIAL_QUEUE events
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
			clubId = nil, -- Only set for community members
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
		queueData.name = activityName -- Group title (shows in quotes)
		queueData.comment = comment or ""
	elseif queueType == "lfg" then
		-- LFG Dungeon Finder - has lfgIDs array
		queueData.lfgIDs = { math.random(1, 500) } -- Dungeon ID
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
		}),
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
		activityName = params.activityName, -- Prioritize specific name
		activityType = params.activityType, -- Store type for fallback logic
		activityIcon = params.icon, -- Allow nil to test resolution logic
		queueInfo = "",
		requestedToJoin = false,

		-- Mock metadata
		_isMock = true,
		_created = GetTime(),
		_queueType = queueType,

		-- Fake role distribution for display
		numTanks = math.min(1, numMembers),
		numHealers = math.min(1, math.max(0, numMembers - 1)),
		numDPS = math.max(0, numMembers - 2),
	}

	-- Store mock group
	self.mockGroups[guid] = mockGroup
	self:RebuildMockMemberIndex()

	-- BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Created '%s' (%s, %d members)",
	-- 	params.activityName, queueType, numMembers))

	return guid, mockGroup
end

--[[
	Remove a specific mock group
	@param guid: Group GUID to remove
	@return: true if removed, false if not found
]]
function QuickJoin:RemoveMockGroup(guid)
	if self.mockGroups[guid] then
		local name = self.mockGroups[guid].groupTitle or ""
		self.mockGroups[guid] = nil
		self:RebuildMockMemberIndex()
		-- BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Removed '%s'", name))
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
	wipe(self.mockMemberByGuid)

	-- BFL:DebugPrint(string.format("|cff00ff00QuickJoin Mock:|r Cleared %d mock groups", count))
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
		if i <= 5 then -- Limit to avoid overwhelming
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
				icon = 525134, -- Mythic+ Keystone
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
				icon = 1536895, -- User Selected: Raid
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
				icon = 525134, -- Mythic+ Keystone
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
				icon = 2056011, -- Honor Symbol
			})
		end
	end

	-- Fallback Icon Tests (Explicitly testing the fallback logic)
	-- 1. Dungeon Fallback (inv_relics_hourglass: 525134)
	self:CreateMockGroup({
		leaderName = "DungeonFallback",
		queueType = "lfg",
		activityName = "Fallback: Dungeon Icon",
		activityType = "Dungeon",
		icon = 525134, -- Mythic+ Keystone
		numMembers = 5,
	})

	-- 2. Raid Fallback (Achievement_Boss_CThun: 463432)
	self:CreateMockGroup({
		leaderName = "RaidFallback",
		queueType = "lfglist",
		activityName = "Fallback: Raid Icon",
		activityType = "Raid",
		icon = 463432, -- Skull/Boss
		numMembers = 20,
	})

	-- 3. PvP Fallback (pvpcurrency-honor-horde: 2056011)
	self:CreateMockGroup({
		leaderName = "PvPFallback",
		queueType = "pvp",
		activityName = "Fallback: PvP Icon",
		activityType = "Battleground",
		icon = 2056011, -- Honor Symbol
		numMembers = 10,
	})

	-- 4. Questing Fallback (inv_misc_map02: 1500869)
	self:CreateMockGroup({
		leaderName = "QuestFallback",
		queueType = "lfglist",
		activityName = "Fallback: Quest Icon",
		activityType = "Questing",
		icon = 1500869, -- Map/Exploration
		numMembers = 2,
	})

	-- 5. Custom Fallback (Achievement_Reputation_01: 237272)
	self:CreateMockGroup({
		leaderName = "CustomFallback",
		queueType = "lfglist",
		activityName = "Fallback: Custom Icon",
		activityType = "Custom",
		icon = 237272, -- Handshake/Social
		numMembers = 1,
	})

	-- Start dynamic updates
	self:StartMockDynamicUpdates()

	local count = 0
	for _ in pairs(self.mockGroups) do
		count = count + 1
	end
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
			icon = 525134, -- Mythic+ Keystone
		})
	end

	for i, activity in ipairs(MOCK_ACTIVITIES.lfg_dungeon) do
		self:CreateMockGroup({
			leaderName = MOCK_PLAYER_NAMES[10 + i],
			queueType = "lfg",
			activityName = activity[1],
			activityType = activity[2],
			numMembers = math.random(1, 4),
			icon = 525134, -- Mythic+ Keystone
		})
	end

	self:StartMockDynamicUpdates()

	local count = 0
	for _ in pairs(self.mockGroups) do
		count = count + 1
	end
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
			icon = 2056011, -- Honor Symbol
		})
	end

	self:StartMockDynamicUpdates()

	local count = 0
	for _ in pairs(self.mockGroups) do
		count = count + 1
	end
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
			icon = 1536895, -- User Selected: Raid
		})
	end

	self:StartMockDynamicUpdates()

	local count = 0
	for _ in pairs(self.mockGroups) do
		count = count + 1
	end
	print(string.format("|cff00ff00BFL QuickJoin:|r Created %d raid mock groups", count))

	self:Update(true)
end

--[[
	Create mock groups to test all fallback icons
]]
function QuickJoin:CreateMockPreset_Icons()
	self:ClearMockGroups()

	-- 1. Dungeon Fallback (Keystone: 525134)
	self:CreateMockGroup({
		leaderName = "DungeonFallback",
		queueType = "lfg",
		activityName = "Fallback: Dungeon",
		activityType = "Dungeon",
		icon = 525134,
		numMembers = 5,
	})

	-- 2. Raid Fallback (User Selected: 1536895)
	self:CreateMockGroup({
		leaderName = "RaidFallback",
		queueType = "lfglist",
		activityName = "Fallback: Raid",
		activityType = "Raid",
		icon = 1536895,
		numMembers = 20,
	})

	-- 3. PvP Fallback (User Selected: 236396)
	self:CreateMockGroup({
		leaderName = "PvPFallback",
		queueType = "pvp",
		activityName = "Fallback: PvP",
		activityType = "Battleground",
		icon = 236396,
		numMembers = 10,
	})

	-- 4. Questing Fallback (User Selected: 409602)
	self:CreateMockGroup({
		leaderName = "QuestFallback",
		queueType = "lfglist",
		activityName = "Fallback: Questing",
		activityType = "Questing",
		icon = 409602,
		numMembers = 2,
	})

	-- 5. Custom Fallback (User Selected: 134149)
	self:CreateMockGroup({
		leaderName = "CustomFallback",
		queueType = "lfglist",
		activityName = "Fallback: Custom",
		activityType = "Custom",
		icon = 134149,
		numMembers = 1,
	})

	-- 6. Default Question Mark (INV_Misc_QuestionMark: 134400)
	-- This is the ultimate fallback if no icon is set
	self:CreateMockGroup({
		leaderName = "UltimateFallback",
		queueType = "lfglist",
		activityName = "Fallback: Default",
		activityType = "Unknown",
		icon = 134400,
		numMembers = 3,
	})

	print("|cff00ff00BFL QuickJoin:|r " .. BFL.L.QJ_MOCK_CREATED_FALLBACK)

	self:Update(true)
end

--[[
	Create many groups for stress testing scrollbar
]]
function QuickJoin:CreateMockPreset_Stress()
	self:ClearMockGroups()

	local definitions = {
		-- Raid Valid (Should find icon via EJ lookup)
		{
			leaderName = "RaidLeader",
			queueType = "lfglist",
			activityName = "Molten Core", -- Valid EJ Name (Classic Raid)
			activityType = "Raid",
			comment = "Valid Raid Activity (EJ Lookup)",
			icon = nil, -- Force lookup
		},
		-- Raid Valid 2 (Should find icon via EJ lookup)
		{
			leaderName = "RaidLeader2",
			queueType = "lfglist",
			activityName = "Throne of the Four Winds", -- Valid EJ Name
			activityType = "Raid",
			comment = "Valid Raid Activity 2 (EJ Lookup)",
			icon = nil, -- Force lookup
		},
		-- Raid Fallback (Should fallback to generic Raid icon)
		{
			leaderName = "RaidFallback",
			queueType = "lfglist",
			activityName = "Unknown Raid Activity",
			activityType = "Raid",
			comment = "Fallback Raid Icon",
			icon = nil, -- Force lookup
		},
		-- M+ Valid (Should find icon via EJ lookup)
		{
			leaderName = "DungeonLeader",
			queueType = "lfglist",
			activityName = "The Stonevault", -- Valid EJ Name (TWW Dungeon)
			activityType = "Mythic+ Dungeon",
			comment = "Valid Dungeon Activity (EJ Lookup)",
			icon = nil, -- Force lookup
		},
		-- Dungeon Valid 2 (Should find icon via EJ lookup)
		{
			leaderName = "DungeonLeader2",
			queueType = "lfglist",
			activityName = "End Time", -- Valid EJ Name
			activityType = "Dungeon",
			comment = "Valid Dungeon Activity 2 (EJ Lookup)",
			icon = nil, -- Force lookup
		},
		-- M+ Fallback (Should fallback to generic Dungeon icon)
		{
			leaderName = "DungeonFallback",
			queueType = "lfglist",
			activityName = "Unknown Dungeon Activity",
			activityType = "Dungeon",
			comment = "Fallback Dungeon Icon",
			icon = nil, -- Force lookup
		},
		-- PvP Valid (Should find icon via EJ lookup if exists, or fallback)
		{
			leaderName = "PvPLeader",
			queueType = "pvp",
			activityName = "Warsong Gulch",
			activityType = "Battleground",
			comment = "Valid PvP Activity",
			icon = nil, -- Force lookup
		},
		-- PvP Fallback
		{
			leaderName = "PvPFallback",
			queueType = "pvp",
			activityName = "Unknown PvP",
			activityType = "PvP",
			comment = "Fallback PvP Icon",
			icon = nil, -- Force lookup
		},
	}

	-- Create 50 groups
	for i = 1, 50 do
		local defIndex = ((i - 1) % #definitions) + 1
		local def = definitions[defIndex]

		self:CreateMockGroup({
			leaderName = def.leaderName .. i,
			queueType = def.queueType,
			activityName = def.activityName,
			activityType = def.activityType,
			comment = def.comment,
			numMembers = math.random(1, 5),
			icon = def.icon,
		})
	end

	-- Don't enable dynamic updates for stress test (too much CPU)

	print("|cff00ff00BFL QuickJoin:|r " .. BFL.L.QJ_MOCK_CREATED_STRESS)

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

	-- BFL:DebugPrint("|cff00ff00QuickJoin Mock:|r Dynamic updates started")
end

--[[
	Process one cycle of dynamic updates
]]
function QuickJoin:ProcessMockDynamicUpdate()
	if not self.mockConfig.dynamicUpdates then
		return
	end

	local updated = false

	for guid, group in pairs(self.mockGroups) do
		-- 30% chance to change member count
		if math.random() < 0.3 then
			local maxMembers = group._queueType == "lfglist"
					and (group.activityName and group.activityName:find("Raid") and 25 or 5)
				or 5
			local newCount = math.random(1, maxMembers)

			if newCount ~= group.numMembers then
				-- Update member count
				group.numMembers = newCount

				-- Rebuild members array
				group.members = CreateMockMembers(newCount, group.leaderName)
				group.leaderGUID = group.members[1].guid

				updated = true
				-- BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s: %d members",
				-- 	group.leaderName, newCount))
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
		print("|cff00ff00BFL QuickJoin:|r " .. BFL.L.QJ_SIM_ADDED)
	elseif eventType == "group_removed" then
		-- Remove a random group
		local guids = {}
		for guid in pairs(self.mockGroups) do
			table.insert(guids, guid)
		end
		if #guids > 0 then
			local guid = guids[math.random(#guids)]
			self:RemoveMockGroup(guid)
			print("|cff00ff00BFL QuickJoin:|r " .. BFL.L.QJ_SIM_REMOVED)
		else
			print("|cffff8800BFL QuickJoin:|r " .. BFL.L.QJ_ERR_NO_GROUPS_REMOVE)
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
			print(
				"|cff00ff00BFL QuickJoin:|r "
					.. string.format(BFL.L.QJ_SIM_UPDATED_FMT, group.leaderName, group.numMembers)
			)
		else
			print("|cffff8800BFL QuickJoin:|r " .. BFL.L.QJ_ERR_NO_GROUPS_UPDATE)
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
		elseif subCmd == "icons" or subCmd == "fallback" then
			QuickJoin:CreateMockPreset_Icons()
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
		print(
			"|cff00ff00BFL QuickJoin:|r "
				.. string.format(BFL.L.QJ_ADDED_GROUP_FMT, leaderName, activityName, numMembers)
		)
	elseif cmd == "event" then
		local eventType = args[2] and args[2]:lower() or "help"

		if eventType == "add" or eventType == "added" then
			QuickJoin:SimulateMockEvent("group_added")
		elseif eventType == "remove" or eventType == "removed" then
			QuickJoin:SimulateMockEvent("group_removed")
		elseif eventType == "update" or eventType == "updated" then
			QuickJoin:SimulateMockEvent("group_updated")
		else
			print(BFL.L.QJ_EVENT_COMMANDS)
			print("  |cffffcc00/bfl qj event add|r - " .. BFL.L.QJ_HELP_CMD_ADD_DESC)
			print("  |cffffcc00/bfl qj event remove|r - " .. BFL.L.QJ_HELP_CMD_REMOVE_DESC)
			print("  |cffffcc00/bfl qj event update|r - " .. BFL.L.QJ_HELP_CMD_UPDATE_DESC)
		end
	elseif cmd == "clear" then
		QuickJoin:ClearMockGroups()
	elseif cmd == "list" then
		print(BFL.L.QJ_LIST_HEADER)
		local count = 0
		for guid, group in pairs(QuickJoin.mockGroups) do
			count = count + 1
			local queueType = group._queueType or "unknown"
			print(
				string.format(
					"  %d. |cff00ff00%s|r - %s (%s, %d members)",
					count,
					group.leaderName,
					group.groupTitle,
					queueType,
					group.numMembers
				)
			)
		end
		if count == 0 then
			print("  |cff888888" .. BFL.L.QJ_NO_GROUPS_HINT .. "|r")
		end
	elseif cmd == "config" then
		local setting = args[2] and args[2]:lower()
		local value = args[3]

		if setting == "dynamic" then
			QuickJoin.mockConfig.dynamicUpdates = (value == "on" or value == "true" or value == "1")
			print(
				"|cff00ff00BFL QuickJoin:|r "
					.. string.format(BFL.L.RAID_DYN_UPDATES, QuickJoin.mockConfig.dynamicUpdates and "ON" or "OFF")
			)
		elseif setting == "interval" then
			local interval = tonumber(value) or 3.0
			QuickJoin.mockConfig.updateInterval = math.max(1.0, interval)
			print(
				"|cff00ff00BFL QuickJoin:|r "
					.. string.format(BFL.L.RAID_UPDATE_INTERVAL, QuickJoin.mockConfig.updateInterval)
			)
		else
			print(BFL.L.QJ_CONFIG_HEADER)
			print(string.format(BFL.L.RAID_DYN_UPDATES_STATUS, QuickJoin.mockConfig.dynamicUpdates and "ON" or "OFF"))
			print(string.format(BFL.L.RAID_UPDATE_INTERVAL_STATUS, QuickJoin.mockConfig.updateInterval))
			print("")
			print("  |cffffcc00/bfl qj config dynamic on|off|r")
			print("  |cffffcc00/bfl qj config interval <seconds>|r")
		end
	else
		-- Help
		print(BFL.L.CORE_HELP_QJ_COMMANDS)
		print("")
		print(BFL.L.CORE_HELP_MOCK_COMMANDS)
		print(BFL.L.CORE_HELP_QJ_MOCK)
		print(BFL.L.CORE_HELP_QJ_DUNGEON)
		print(BFL.L.CORE_HELP_QJ_PVP)
		print(BFL.L.CORE_HELP_QJ_RAID)
		print(BFL.L.QJ_MOCK_ICONS_HELP)
		print(BFL.L.CORE_HELP_QJ_STRESS)
		print("")
		print(BFL.L.RAID_HELP_MANAGEMENT)
		print(BFL.L.QJ_CMD_ADD_HELP)
		print(BFL.L.CORE_HELP_QJ_LIST)
		print(BFL.L.CORE_HELP_QJ_CLEAR)
		print("")
		print(BFL.L.RAID_HELP_EVENTS)
		print("  |cffffcc00/bfl qj event add|r - " .. BFL.L.QJ_HELP_CMD_ADD_DESC)
		print("  |cffffcc00/bfl qj event remove|r - " .. BFL.L.QJ_HELP_CMD_REMOVE_DESC)
		print("  |cffffcc00/bfl qj event update|r - " .. BFL.L.QJ_HELP_CMD_UPDATE_DESC)
		print("")
		print(BFL.L.HELP_HEADER_CONFIGURATION)
		print(BFL.L.QJ_CMD_CONFIG_HELP)
		print("")
		print(BFL.L.QJ_EXT_FOOTER)
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
	if not frame or not frame.ContentInset or not frame.ContentInset.JoinQueueButton then
		return
	end

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
	if not self.selectedGUID then
		return
	end

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
		-- Show LFG List application dialog (Blizzard's native dialog)
		if LFGListApplicationDialog and LFGListApplicationDialog_Show then
			LFGListApplicationDialog_Show(LFGListApplicationDialog, groupInfo.lfgListInfo.queueData.lfgListID)
		else
			UIErrorsFrame:AddMessage("LFG List dialog not available.", 1.0, 0.1, 0.1, 1.0)
		end
	else
		-- Show role selection dialog for regular group (Blizzard's native QuickJoinRoleSelectionFrame)
		if QuickJoinRoleSelectionFrame and QuickJoinRoleSelectionFrame.ShowForGroup then
			QuickJoinRoleSelectionFrame:ShowForGroup(self.selectedGUID)
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
	if not guid then
		return
	end

	local groupInfo = self:GetGroupInfo(guid)
	if not groupInfo or not groupInfo.members or #groupInfo.members == 0 then
		return
	end

	-- Sort members to ensure the most relevant one is first (Friend/Leader)
	-- This mirrors Blizzard's behavior of showing the context menu for the primary friend
	BetterFriendlist_SortGroupMembers(groupInfo.members)

	-- Get first member (leader/friend) for context
	if not groupInfo.members[1] then
		return
	end
	local leaderInfo = groupInfo.members[1]
	if not leaderInfo then
		return
	end

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
