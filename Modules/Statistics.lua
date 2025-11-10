-- Modules/Statistics.lua
-- Friend network statistics and analytics module

local ADDON_NAME, BFL = ...
local Statistics = BFL:RegisterModule("Statistics", {})

-- Initialize the module
function Statistics:Initialize()
	BFL:DebugPrint("|cff00ff00BetterFriendlist Statistics:|r Initialized")
end

-- Calculate all statistics
function Statistics:GetStatistics()
	local stats = {
		totalFriends = 0,
		onlineFriends = 0,
		offlineFriends = 0,
		bnetFriends = 0,
		wowFriends = 0,
		classCounts = {},
		realmCounts = {},
		factionCounts = {Alliance = 0, Horde = 0, Unknown = 0}
	}
	
	-- BNet friends
	local numBNet = BNGetNumFriends()
	stats.bnetFriends = numBNet
	
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			stats.totalFriends = stats.totalFriends + 1
			
			if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				stats.onlineFriends = stats.onlineFriends + 1
				
				local gameInfo = accountInfo.gameAccountInfo
				
				-- Class breakdown (only for WoW)
				if gameInfo.clientProgram == "WoW" and gameInfo.className then
					local className = gameInfo.className
					stats.classCounts[className] = (stats.classCounts[className] or 0) + 1
				end
				
				-- Realm breakdown
				if gameInfo.realmName and gameInfo.realmName ~= "" then
					local realmName = gameInfo.realmName
					stats.realmCounts[realmName] = (stats.realmCounts[realmName] or 0) + 1
				end
				
				-- Faction breakdown
				if gameInfo.factionName then
					stats.factionCounts[gameInfo.factionName] = (stats.factionCounts[gameInfo.factionName] or 0) + 1
				else
					stats.factionCounts.Unknown = stats.factionCounts.Unknown + 1
				end
			else
				stats.offlineFriends = stats.offlineFriends + 1
			end
		end
	end
	
	-- WoW friends
	local numWoW = C_FriendList.GetNumFriends()
	stats.wowFriends = numWoW
	
	for i = 1, numWoW do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			stats.totalFriends = stats.totalFriends + 1
			
			if info.connected then
				stats.onlineFriends = stats.onlineFriends + 1
				
				-- Class breakdown
				if info.className then
					stats.classCounts[info.className] = (stats.classCounts[info.className] or 0) + 1
				end
			else
				stats.offlineFriends = stats.offlineFriends + 1
			end
		end
	end
	
	return stats
end

-- Get top N realms by friend count
function Statistics:GetTopRealms(n)
	local stats = self:GetStatistics()
	local realms = {}
	
	for realm, count in pairs(stats.realmCounts) do
		table.insert(realms, {name = realm, count = count})
	end
	
	table.sort(realms, function(a, b) return a.count > b.count end)
	
	-- Return top N
	local topRealms = {}
	for i = 1, math.min(n or 5, #realms) do
		table.insert(topRealms, realms[i])
	end
	
	return topRealms
end

-- Get top N classes by friend count
function Statistics:GetTopClasses(n)
	local stats = self:GetStatistics()
	local classes = {}
	
	for className, count in pairs(stats.classCounts) do
		table.insert(classes, {name = className, count = count})
	end
	
	table.sort(classes, function(a, b) return a.count > b.count end)
	
	-- Return top N
	local topClasses = {}
	for i = 1, math.min(n or 13, #classes) do
		table.insert(topClasses, classes[i])
	end
	
	return topClasses
end

return Statistics
