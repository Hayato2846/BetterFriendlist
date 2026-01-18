--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua"); -- Modules/Statistics.lua
-- Friend network statistics and analytics module (ENHANCED - Phase 12)
-- Now uses ALL Friends List API data (20+ fields) instead of just ActivityTracker

local ADDON_NAME, BFL = ...
local Statistics = BFL:RegisterModule("Statistics", {})

-- ========================================
-- Constants
-- ========================================
local SECONDS_PER_DAY = 86400
local DAYS_7 = 7 * SECONDS_PER_DAY
local DAYS_30 = 30 * SECONDS_PER_DAY
local DAYS_90 = 90 * SECONDS_PER_DAY
local DAYS_180 = 180 * SECONDS_PER_DAY

-- Max level for current expansion (update per expansion)
local MAX_LEVEL = 80

-- ========================================
-- Helper Functions
-- ========================================

-- Get localized class file name from localized class name (for offline friends)
-- Logic moved to BFL.ClassUtils (renamed from GetClassFileFromLocalizedName to GetClassFileFromClassName)
local function GetClassFileFromLocalizedName(localizedClassName) Perfy_Trace(Perfy_GetTime(), "Enter", "GetClassFileFromLocalizedName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:26:6");
	return Perfy_Trace_Passthrough("Leave", "GetClassFileFromLocalizedName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:26:6", BFL.ClassUtils:GetClassFileFromClassName(localizedClassName))
end

-- Check if realm is same or connected to player's realm
local function GetRealmCategory(realmName) Perfy_Trace(Perfy_GetTime(), "Enter", "GetRealmCategory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:31:6");
	if not realmName or realmName == "" then Perfy_Trace(Perfy_GetTime(), "Leave", "GetRealmCategory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:31:6"); return "unknown" end
	
	local playerRealm = GetNormalizedRealmName()
	if realmName == playerRealm then
		Perfy_Trace(Perfy_GetTime(), "Leave", "GetRealmCategory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:31:6"); return "same"
	end
	
	-- TODO: Connected realm detection (WoW API doesn't provide this easily)
	-- For now, treat all non-matching realms as "other"
	Perfy_Trace(Perfy_GetTime(), "Leave", "GetRealmCategory file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:31:6"); return "other"
end

-- Calculate friendship health score based on last activity
local function CalculateFriendshipHealth(friendData, currentTime) Perfy_Trace(Perfy_GetTime(), "Enter", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6");
	local ActivityTracker = BFL:GetModule("ActivityTracker")
	if not ActivityTracker then Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "unknown" end
	
	-- Get UID for ActivityTracker lookup
	local uid = nil
	if friendData.type == "bnet" then
		uid = "bnet_" .. tostring(friendData.bnetAccountID)
	elseif friendData.type == "wow" then
		uid = "wow_" .. friendData.name
	end
	
	if not uid then Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "unknown" end
	
	-- Get last activity (whisper/group/trade)
	local lastActivity = ActivityTracker:GetLastActivity(uid)
	local mostRecentActivity = 0
	
	if lastActivity then
		mostRecentActivity = math.max(
			lastActivity.lastWhisper or 0,
			lastActivity.lastGroup or 0,
			lastActivity.lastTrade or 0
		)
	end
	
	-- Check if activity exists
	if mostRecentActivity > 0 then
		local timeSinceActivity = currentTime - mostRecentActivity
		
		if timeSinceActivity <= DAYS_7 then
			Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "active"      -- Interacted within 7 days
		elseif timeSinceActivity <= DAYS_30 then
			Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "regular"     -- Interacted within 30 days
		end
	end
	
	-- No recent activity, check last online time
	local lastOnline = friendData.lastOnlineTime or 0
	
	if lastOnline > 0 then
		local timeSinceOnline = currentTime - lastOnline
		
		if timeSinceOnline <= DAYS_90 then
			Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "drifting"   -- Online within 90 days, but no interaction
		elseif timeSinceOnline <= DAYS_180 then
			Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "stale"      -- Online 90-180 days ago
		else
			Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "dormant"    -- Not seen in 180+ days
		end
	end
	
	-- Friend is currently online but no activity tracked
	if friendData.connected then
		Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "drifting"
	end
	
	-- No data available
	Perfy_Trace(Perfy_GetTime(), "Leave", "CalculateFriendshipHealth file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:45:6"); return "unknown"
end

-- ========================================
-- Module Initialization
-- ========================================
function Statistics:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:109:0");
	-- BFL:DebugPrint("|cff00ff00BetterFriendlist Statistics:|r Initialized (Enhanced - Phase 12)")
Perfy_Trace(Perfy_GetTime(), "Leave", "Statistics:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:109:0"); end

-- ========================================
-- Core Statistics Calculation
-- ========================================

-- Calculate comprehensive statistics using ALL API fields
function Statistics:GetStatistics() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetStatistics file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:118:0");
	local currentTime = time()
	
	-- Initialize comprehensive stats structure
	local stats = {
		-- Overview
		totalFriends = 0,
		onlineFriends = 0,
		offlineFriends = 0,
		bnetFriends = 0,
		wowFriends = 0,
		
		-- Demographics
		classCounts = {
			online = {},
			offline = {},
			total = {}
		},
		levelDistribution = {
			maxLevel = 0,
			ranges = {
				{min = 70, max = 79, count = 0},
				{min = 60, max = 69, count = 0},
				{min = 1, max = 59, count = 0}
			},
			totalLevels = 0,  -- Sum for average calculation
			leveledFriends = 0  -- Count for average (exclude nil levels)
		},
		realmDistribution = {
			sameRealm = 0,
			otherRealms = 0,
			unknownRealm = 0,
			realmCounts = {}
		},
		factionCounts = {
			alliance = 0,
			horde = 0
		},
		gameCounts = {
			wow = 0,
			classic = 0,
			diablo = 0,
			hearthstone = 0,
			starcraft = 0,
			mobile = 0,
			other = 0
		},
		
		-- Activity & Health
		friendshipHealth = {
			active = 0,
			regular = 0,
			drifting = 0,
			stale = 0,
			dormant = 0,
			unknown = 0
		},
		mobileVsDesktop = {
			desktop = 0,
			mobile = 0
		},
		
		-- Growth & Retention
		notesAndFavorites = {
			withNotes = 0,
			favorites = 0
		}
	}
	
	-- ========================================
	-- Analyze Battle.net Friends
	-- ========================================
	local numBNet = BNGetNumFriends()
	stats.bnetFriends = numBNet
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			stats.totalFriends = stats.totalFriends + 1
			
			local isOnline = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline
			
			if isOnline then
				stats.onlineFriends = stats.onlineFriends + 1
			else
				stats.offlineFriends = stats.offlineFriends + 1
			end
			
			-- Friendship health
			local friendData = {
				type = "bnet",
				bnetAccountID = accountInfo.bnetAccountID,
				connected = isOnline,
				lastOnlineTime = accountInfo.lastOnlineTime
			}
			local health = CalculateFriendshipHealth(friendData, currentTime)
			stats.friendshipHealth[health] = (stats.friendshipHealth[health] or 0) + 1
			
			-- Notes and Favorites
			if accountInfo.note and accountInfo.note ~= "" then
				stats.notesAndFavorites.withNotes = stats.notesAndFavorites.withNotes + 1
			end
			if accountInfo.isFavorite then
				stats.notesAndFavorites.favorites = stats.notesAndFavorites.favorites + 1
			end
			
			-- Game info (only if online)
			if isOnline and accountInfo.gameAccountInfo then
				local gameInfo = accountInfo.gameAccountInfo
				
				-- Game distribution
				local clientProgram = gameInfo.clientProgram
				if clientProgram == "WoW" then
					stats.gameCounts.wow = stats.gameCounts.wow + 1
				elseif clientProgram == "WoW_classic" then
					stats.gameCounts.classic = stats.gameCounts.classic + 1
				elseif clientProgram == "D4" then
					stats.gameCounts.diablo = stats.gameCounts.diablo + 1
				elseif clientProgram == "WTCG" then
					stats.gameCounts.hearthstone = stats.gameCounts.hearthstone + 1
				elseif clientProgram == "S2" then
					stats.gameCounts.starcraft = stats.gameCounts.starcraft + 1
				elseif clientProgram == "BSAp" or clientProgram == "App" then
					stats.gameCounts.mobile = stats.gameCounts.mobile + 1
					stats.mobileVsDesktop.mobile = stats.mobileVsDesktop.mobile + 1
				else
					stats.gameCounts.other = stats.gameCounts.other + 1
				end
				
				-- Desktop count (exclude mobile)
				if clientProgram ~= "BSAp" and clientProgram ~= "App" then
					stats.mobileVsDesktop.desktop = stats.mobileVsDesktop.desktop + 1
				end
				
				-- WoW-specific stats (class, level, realm, faction)
				if clientProgram == "WoW" or clientProgram == "WoW_classic" then
					-- Class
					if gameInfo.className then
						local className = gameInfo.className
						stats.classCounts.online[className] = (stats.classCounts.online[className] or 0) + 1
						stats.classCounts.total[className] = (stats.classCounts.total[className] or 0) + 1
					end
					
					-- Level
					if gameInfo.characterLevel then
						local level = gameInfo.characterLevel
						stats.levelDistribution.totalLevels = stats.levelDistribution.totalLevels + level
						stats.levelDistribution.leveledFriends = stats.levelDistribution.leveledFriends + 1
						
						if level == MAX_LEVEL then
							stats.levelDistribution.maxLevel = stats.levelDistribution.maxLevel + 1
						elseif level >= 70 then
							stats.levelDistribution.ranges[1].count = stats.levelDistribution.ranges[1].count + 1
						elseif level >= 60 then
							stats.levelDistribution.ranges[2].count = stats.levelDistribution.ranges[2].count + 1
						else
							stats.levelDistribution.ranges[3].count = stats.levelDistribution.ranges[3].count + 1
						end
					end
					
					-- Realm
					if gameInfo.realmName and gameInfo.realmName ~= "" then
						local realmName = gameInfo.realmName
						local realmCategory = GetRealmCategory(realmName)
						
						if realmCategory == "same" then
							stats.realmDistribution.sameRealm = stats.realmDistribution.sameRealm + 1

						end
						
						-- Top realms
						stats.realmDistribution.realmCounts[realmName] = (stats.realmDistribution.realmCounts[realmName] or 0) + 1
					else
						stats.realmDistribution.unknownRealm = stats.realmDistribution.unknownRealm + 1
					end
					
					-- Faction
					if gameInfo.factionName then
						if gameInfo.factionName == "Alliance" or gameInfo.factionName == FACTION_ALLIANCE then
							stats.factionCounts.alliance = stats.factionCounts.alliance + 1
						elseif gameInfo.factionName == "Horde" or gameInfo.factionName == FACTION_HORDE then
							stats.factionCounts.horde = stats.factionCounts.horde + 1
						end
					end
				end
			end
		end
	end
	
	-- ========================================
	-- Analyze WoW Friends
	-- ========================================
	local numWoW = C_FriendList.GetNumFriends()
	stats.wowFriends = numWoW
	
	for i = 1, numWoW do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			stats.totalFriends = stats.totalFriends + 1
			
			if info.connected then
				stats.onlineFriends = stats.onlineFriends + 1
			else
				stats.offlineFriends = stats.offlineFriends + 1
			end
			
			-- Friendship health
			local friendData = {
				type = "wow",
				name = info.name,
				connected = info.connected,
				lastOnlineTime = 0  -- WoW friends don't have lastOnlineTime
			}
			local health = CalculateFriendshipHealth(friendData, currentTime)
			stats.friendshipHealth[health] = (stats.friendshipHealth[health] or 0) + 1
			
			-- Notes
			if info.notes and info.notes ~= "" then
				stats.notesAndFavorites.withNotes = stats.notesAndFavorites.withNotes + 1
			end
			
			-- Class (online and offline)
			if info.className then
				local className = info.className
				if info.connected then
					stats.classCounts.online[className] = (stats.classCounts.online[className] or 0) + 1
				else
					stats.classCounts.offline[className] = (stats.classCounts.offline[className] or 0) + 1
				end
				stats.classCounts.total[className] = (stats.classCounts.total[className] or 0) + 1
			end
			
			-- Level (only available for online friends)
			if info.connected and info.level then
				local level = info.level
				stats.levelDistribution.totalLevels = stats.levelDistribution.totalLevels + level
				stats.levelDistribution.leveledFriends = stats.levelDistribution.leveledFriends + 1
				
				if level == MAX_LEVEL then
					stats.levelDistribution.maxLevel = stats.levelDistribution.maxLevel + 1
				elseif level >= 70 then
					stats.levelDistribution.ranges[1].count = stats.levelDistribution.ranges[1].count + 1
				elseif level >= 60 then
					stats.levelDistribution.ranges[2].count = stats.levelDistribution.ranges[2].count + 1
				else
					stats.levelDistribution.ranges[3].count = stats.levelDistribution.ranges[3].count + 1
				end
			end
		end
	end
	
	-- Calculate average level
	if stats.levelDistribution.leveledFriends > 0 then
		stats.levelDistribution.average = stats.levelDistribution.totalLevels / stats.levelDistribution.leveledFriends
	else
		stats.levelDistribution.average = 0
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Statistics:GetStatistics file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:118:0"); return stats
end

-- ========================================
-- Helper Functions for UI/Reports
-- ========================================

-- Get top N realms by friend count
function Statistics:GetTopRealms(n) Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetTopRealms file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:384:0");
	local stats = self:GetStatistics()
	local realms = {}
	
	for realm, count in pairs(stats.realmDistribution.realmCounts) do
		table.insert(realms, {name = realm, count = count})
	end
	
	table.sort(realms, function(a, b) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:392:20"); return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:392:20", a.count > b.count) end)
	
	-- Return top N
	local topRealms = {}
	for i = 1, math.min(n or 5, #realms) do
		table.insert(topRealms, realms[i])
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Statistics:GetTopRealms file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:384:0"); return topRealms
end

-- Get top N classes by friend count (total = online + offline)
function Statistics:GetTopClasses(n) Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetTopClasses file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:404:0");
	local stats = self:GetStatistics()
	local classes = {}
	
	for className, count in pairs(stats.classCounts.total) do
		table.insert(classes, {name = className, count = count})
	end
	
	table.sort(classes, function(a, b) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:412:21"); return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:412:21", a.count > b.count) end)
	
	-- Return top N
	local topClasses = {}
	for i = 1, math.min(n or 13, #classes) do
		table.insert(topClasses, classes[i])
	end
	
	Perfy_Trace(Perfy_GetTime(), "Leave", "Statistics:GetTopClasses file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:404:0"); return topClasses
end

-- Get friendship health summary
function Statistics:GetFriendshipHealthSummary() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetFriendshipHealthSummary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:424:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetFriendshipHealthSummary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:424:0", stats.friendshipHealth)
end

-- Get level distribution summary
function Statistics:GetLevelDistribution() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetLevelDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:430:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetLevelDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:430:0", stats.levelDistribution)
end

-- Get realm distribution summary
function Statistics:GetRealmDistribution() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetRealmDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:436:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetRealmDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:436:0", stats.realmDistribution)
end

-- Get game distribution summary
function Statistics:GetGameDistribution() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetGameDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:442:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetGameDistribution file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:442:0", stats.gameCounts)
end

-- Get mobile vs desktop summary
function Statistics:GetMobileVsDesktop() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetMobileVsDesktop file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:448:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetMobileVsDesktop file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:448:0", stats.mobileVsDesktop)
end

-- Get class roles summary
function Statistics:GetClassRoles() Perfy_Trace(Perfy_GetTime(), "Enter", "Statistics:GetClassRoles file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:454:0");
	local stats = self:GetStatistics()
	return Perfy_Trace_Passthrough("Leave", "Statistics:GetClassRoles file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua:454:0", stats.classRoles)
end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Statistics.lua"); return Statistics
