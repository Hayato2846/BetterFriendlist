-- Modules/Broker.lua
-- Data Broker Integration Module (LibQTip-2.0)
-- Exposes BetterFriendlist via LibDataBroker-1.1 for display addons (Bazooka, Arcana, TitanPanel)

local ADDON_NAME, BFL = ...

-- Register Module
local Broker = BFL:RegisterModule("Broker", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB()
	return BFL:GetModule("DB")
end
local function GetFriendsList()
	return BFL:GetModule("FriendsList")
end
local function GetGroups()
	return BFL:GetModule("Groups")
end
local function GetStatistics()
	return BFL:GetModule("Statistics")
end
local function GetQuickFilters()
	return BFL:GetModule("QuickFilters")
end

-- ========================================
-- Local Variables
-- ========================================
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LQT = BFL.QTip
local dataObject = nil
local updateThrottle = 0
local lastUpdateTime = 0
local THROTTLE_INTERVAL = 0.1 -- Update max 10 times per second (crisp but not spammy)

-- Quick filter cycle order (offline removed - tooltip only shows online friends)
local FILTER_CYCLE = { "all", "online", "wow", "bnet", "ingame" }

-- LibQTip tooltip reference
local tooltip = nil
local tooltipKey = "BetterFriendlistBrokerTT"

-- Detail Tooltip reference (Forward declared for helper access)
local detailTooltip = nil

-- ========================================
-- Helper Functions
-- ========================================

-- Game/Client Info Table with Icons
local GetClientInfo = setmetatable({
	-- Blizzard Games
	ANBS = { icon = 4557783, short = "DI", long = "Diablo Immortal" },
	App = { icon = 796351, short = "Desktop", long = "Desktop App" },
	BSAp = { icon = 796351, short = "Mobile", long = "Mobile App" },
	CLNT = { icon = 796351, short = "App", long = "Battle.net App" },
	D3 = { icon = 536090, short = "D3", long = "Diablo III" },
	Fen = { icon = 5207606, short = "D4", long = "Diablo IV" },
	GRY = { icon = 4553312, short = "Arclight", long = "Warcraft Arclight Rumble" },
	Hero = { icon = 1087463, short = "HotS", long = "Heroes of the Storm" },
	OSI = { icon = 4034244, short = "D2R", long = "Diablo II Resurrected" },
	Pro = { icon = 1313858, short = "OW", long = "Overwatch" },
	Pro2 = { icon = 4734171, short = "OW2", long = "Overwatch 2" },
	RTRO = { icon = 4034242, short = "Arcade", long = "Blizzard Arcade Collection" },
	S1 = { icon = 1669008, short = "SC1", long = "Starcraft" },
	S2 = { icon = 374211, short = "SC2", long = "Starcraft II" },
	W3 = { icon = 3257659, short = "WC3", long = "Warcraft III Reforged" },
	WoW = { icon = 374212, short = "WoW", long = "World of Warcraft" },
	WTCG = { icon = 852633, short = "HS", long = "Hearthstone" },

	-- Activision Games
	WLBY = { icon = 4034243, short = "CB4", long = "Crash Bandicoot 4" },
	DST2 = { icon = 1711629, short = "DST2", long = "Destiny 2" },
	AUKS = { icon = 134400, short = "COD", long = "Call of Duty" },
	VIPR = { icon = 2204215, short = "BO4", long = "Call of Duty: Black Ops 4" },
	FORE = { icon = 4256535, short = "CoDV", long = "Call of Duty: Vanguard" },
	LAZR = { icon = 3581732, short = "MW2", long = "Call of Duty: Modern Warfare 2" },
	ODIN = { icon = 3257658, short = "MW", long = "Call of Duty: Modern Warfare" },
	ZEUS = { icon = 3920823, short = "BOCW", long = "Call of Duty: Black Ops Cold War" },

	-- Other
	SCOR = { icon = 134400, short = "SOT", long = "Sea of Thieves" },
}, {
	__call = function(t, clientProgram)
		local info = rawget(t, clientProgram)
		if not info then
			-- Unknown game - create fallback entry
			info = { icon = 134400, short = clientProgram or "Unknown", long = clientProgram or "Unknown Game" }
			rawset(t, clientProgram, info)
		end

		-- Lazy initialization of iconStr (smaller size for tooltip)
		if not info.iconStr then
			info.iconStr = string.format("|T%d:14:14:0:0|t", info.icon)
		end

		-- Set type (App vs Game)
		if not info.type then
			info.type = (info.icon == 796351) and "App" or "Game"
		end

		return info
	end,
})

-- Shared helpers from BrokerUtils (used by both Friends Broker and Guild Broker)
local GetStatusIcon = BFL.BrokerUtils.GetStatusIcon
local ClassColorText = BFL.BrokerUtils.ClassColorText
local GetFactionIcon = BFL.BrokerUtils.GetFactionIcon
local C = BFL.BrokerUtils.C

-- Get class color for friend (returns color table or white fallback)
local function GetClassColorForFriend(friend)
	return BFL.ClassUtils:GetClassColorForFriend(friend)
end

-- Helper: Add friend name to active chat editbox (Shift+Click)
local AddNameToEditBox = BFL.BrokerUtils.AddNameToEditBox

-- Helper: Smart invite - either invite to group or request to join their group
local function SmartInviteOrJoin(friendType, data)
	if not data then
		return
	end

	local playerInGroup = IsInGroup(LE_PARTY_CATEGORY_HOME)
	local isLeader = UnitIsGroupLeader("player") or not playerInGroup

	if friendType == "bnet" then
		-- BNet friend - must be in WoW
		if data.client ~= "WoW" or not data.gameAccountID then
			return
		end

		if isLeader then
			BFL.BNInviteFriend(data.gameAccountID)
		else
			if data.characterName and data.characterName ~= "" then
				local targetName = data.characterName
				if data.realmName and data.realmName ~= "" and data.realmName ~= GetRealmName() then
					targetName = targetName .. "-" .. data.realmName
				end
				BFL.RequestInviteFromUnit(targetName)
			end
		end
	elseif friendType == "wow" then
		local targetName = data.fullName or data.characterName
		if not targetName then
			return
		end

		if isLeader then
			BFL.InviteUnit(targetName)
		else
			BFL.RequestInviteFromUnit(targetName)
		end
	end
end

-- Helper: Open context menu for friend (like FriendsList)
-- Create a hidden anchor frame for context menus
local contextMenuAnchor = CreateFrame("Frame", "BFL_BrokerContextMenuAnchor", UIParent)
contextMenuAnchor:SetSize(1, 1)
contextMenuAnchor:Hide()

local function OpenFriendContextMenu(data)
	if not data then
		return
	end

	-- Position anchor at cursor
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	contextMenuAnchor:ClearAllPoints()
	contextMenuAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)

	local MenuSystem = BFL:GetModule("MenuSystem")
	if not MenuSystem then
		return
	end

	if data.type == "bnet" then
		local bnetAccountID = data.bnetAccountID

		if not bnetAccountID and data.id then
			bnetAccountID = tonumber(data.id:match("^bnet(%d+)$"))
		end

		if bnetAccountID then
			local FriendsList = BFL and BFL:GetModule("FriendsList")
			local resolvedIndex = FriendsList
					and FriendsList.ResolveBNetFriendIndex
					and FriendsList:ResolveBNetFriendIndex(bnetAccountID, data.battleTag)
				or data.index
			local extraData = {
				name = BFL:GetSafeAccountName(data.accountName, data.battleTag) or data.characterName or "",
				battleTag = data.battleTag,
				connected = true,
				accountInfo = data.accountInfo,
				index = resolvedIndex,
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "BN", bnetAccountID, extraData)
		end
	elseif data.type == "wow" then
		local FriendsList = BFL and BFL:GetModule("FriendsList")
		local friendIndex = FriendsList
				and FriendsList.ResolveWoWFriendIndex
				and FriendsList:ResolveWoWFriendIndex(data.fullName)
			or nil

		if friendIndex then
			local extraData = {
				name = data.fullName or data.characterName or "",
				connected = true,
				index = friendIndex,
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "WOW", friendIndex, extraData)
		end
	end
end

-- Main click handler for friend lines in LibQTip tooltip
local function OnFriendLineClick(cell, data, mouseButton)
	if not data then
		return
	end

	-- LibQTip might not pass mouseButton - we need to get it ourselves!
	local actualButton = mouseButton or GetMouseButtonClicked()

	-- BattleNet friend click handlers
	if data.type == "bnet" then
		if IsAltKeyDown() then
			SmartInviteOrJoin("bnet", data)
		elseif IsShiftKeyDown() then
			if data.client == "WoW" and data.characterName and data.characterName ~= "" then
				AddNameToEditBox(data.characterName, data.realmName)
			end
		elseif actualButton == "RightButton" then
			OpenFriendContextMenu(data)
		else
			if data.bnetAccountID then
				local safeName = BFL:GetSafeAccountName(data.accountName, data.battleTag)
				BFL:SecureSendBNetTell(safeName, data.bnetAccountID)
			elseif not BFL:IsSecret(data.accountName) and data.accountName and data.accountName ~= "" then
				local safeName = BFL:GetSafeAccountName(data.accountName, data.battleTag)
				BFL:SecureSendBNetTell(safeName, data.bnetAccountID)
			end
		end
	-- WoW friend click handlers
	elseif data.type == "wow" then
		if IsAltKeyDown() then
			SmartInviteOrJoin("wow", data)
		elseif IsShiftKeyDown() then
			if data.characterName then
				AddNameToEditBox(data.characterName, data.realmName)
			end
		elseif actualButton == "RightButton" then
			OpenFriendContextMenu(data)
		else
			if data.fullName then
				local whisperName = data.fullName:gsub(" ", "")
				BFL:SecureSendTell(whisperName)
			end
		end
	end
end

-- Get localized string (fallback to key if L table not available)
local function L(key)
	if BFL.L and BFL.L[key] then
		return BFL.L[key]
	end
	return key
end

-- Format time difference for activity tracker
local function FormatTimeSince(timestamp)
	if not timestamp then
		return nil
	end
	local diff = GetServerTime() - timestamp
	if diff < 60 then
		return string.format("%ds", diff)
	elseif diff < 3600 then
		return string.format("%dm", math.floor(diff / 60))
	elseif diff < 86400 then
		return string.format("%dh", math.floor(diff / 3600))
	else
		return string.format("%dd", math.floor(diff / 86400))
	end
end

-- Get friend counts (online/total) for WoW and BNet
-- Respects treatMobileAsOffline setting
local function GetFriendCounts()
	local wowOnline, wowTotal = 0, 0
	local bnetOnline, bnetTotal = 0, 0
	local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline

	-- WoW Friends (not affected by mobile setting)
	wowTotal = C_FriendList.GetNumFriends() or 0
	wowOnline = C_FriendList.GetNumOnlineFriends() or 0

	-- BNet Friends
	if BNConnected() then
		local numTotal, numOnline = BNGetNumFriends()
		bnetTotal = numTotal or 0

		if treatMobileAsOffline then
			bnetOnline = 0
			for i = 1, numOnline do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				if accountInfo and accountInfo.gameAccountInfo then
					local client = accountInfo.gameAccountInfo.clientProgram or "App"
					if client ~= "BSAp" then
						bnetOnline = bnetOnline + 1
					end
				end
			end
		else
			bnetOnline = numOnline or 0
		end
	end

	return wowOnline, wowTotal, bnetOnline, bnetTotal
end

-- Get filtered friend counts based on the active QuickFilter
-- Returns wowFiltered, wowTotal, bnetFiltered, bnetTotal
-- When filter is "all", returns same as GetFriendCounts()
local function GetFilteredFriendCounts()
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"

	-- Fast path: "all" and "online" return raw counts (same as before)
	if currentFilter == "all" or currentFilter == "online" then
		return GetFriendCounts()
	end

	local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline
	local BNET_CLIENT_WOW_LOCAL = BNET_CLIENT_WOW or "WoW"

	local wowFiltered, wowTotal = 0, 0
	local bnetFiltered, bnetTotal = 0, 0

	-- WoW Friends
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	wowTotal = numWoWFriends
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo then
			local connected = friendInfo.connected
			local passes = false

			if currentFilter == "offline" then
				passes = not connected
			elseif currentFilter == "wow" then
				-- WoW friends always pass "wow" filter if online
				passes = connected
			elseif currentFilter == "bnet" then
				-- WoW friends never pass "bnet" filter
				passes = false
			elseif currentFilter == "hideafk" then
				passes = connected and not (friendInfo.afk or friendInfo.dnd)
			elseif currentFilter == "retail" then
				-- WoW friends assumed same version as player
				passes = connected
			elseif currentFilter == "ingame" then
				passes = connected
			end

			if passes then
				wowFiltered = wowFiltered + 1
			end
		end
	end

	-- BNet Friends
	if BNConnected() then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		bnetTotal = numBNetTotal or 0

		for i = 1, bnetTotal do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local gameInfo = accountInfo.gameAccountInfo or {}
				local isOnline = gameInfo.isOnline or false
				local client = gameInfo.clientProgram or "App"
				local isMobile = (client == "BSAp")

				if treatMobileAsOffline and isMobile then
					isOnline = false
				end

				local passes = false

				if currentFilter == "offline" then
					passes = not isOnline
				elseif currentFilter == "wow" then
					passes = isOnline and (client == BNET_CLIENT_WOW_LOCAL)
				elseif currentFilter == "bnet" then
					passes = isOnline and (client ~= BNET_CLIENT_WOW_LOCAL)
				elseif currentFilter == "hideafk" then
					passes = isOnline and not (accountInfo.isAFK or accountInfo.isDND)
				elseif currentFilter == "retail" then
					passes = isOnline and (client == BNET_CLIENT_WOW_LOCAL)
					if passes and gameInfo.wowProjectID and gameInfo.wowProjectID ~= WOW_PROJECT_MAINLINE then
						passes = false
					end
				elseif currentFilter == "ingame" then
					passes = isOnline and client ~= "" and client ~= "App" and client ~= "BSAp"
				end

				if passes then
					bnetFiltered = bnetFiltered + 1
				end
			end
		end
	end

	return wowFiltered, wowTotal, bnetFiltered, bnetTotal
end

-- ========================================
-- Broker Text Update
-- ========================================

function Broker:UpdateBrokerText()
	if not dataObject then
		return
	end

	-- Throttle updates
	local currentTime = GetTime()
	if currentTime - lastUpdateTime < THROTTLE_INTERVAL then
		return
	end
	lastUpdateTime = currentTime

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		return
	end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	local totalOnline = wowOnline + bnetOnline
	local totalFriends = wowTotal + bnetTotal

	-- Format text based on config
	local text
	local showLabel = BetterFriendlistDB.brokerShowLabel ~= false -- Default true
	local showTotal = BetterFriendlistDB.brokerShowTotal ~= false -- Default true

	if BetterFriendlistDB.brokerShowGroups then
		local wowText = showTotal and string.format("%d/%d", wowOnline, wowTotal) or tostring(wowOnline)
		local bnetText = showTotal and string.format("%d/%d", bnetOnline, bnetTotal) or tostring(bnetOnline)

		local wowIcon = "|T939375:16:16:0:0:64:64:5:59:5:59|t"
		local bnetIcon = "|TInterface\\AddOns\\BetterFriendlist\\Icons\\filter-all:16:16:0:0|t"

		local showWoWIcon = BetterFriendlistDB.brokerShowWoWIcon ~= false
		local showBNetIcon = BetterFriendlistDB.brokerShowBNetIcon ~= false

		local wowPart = (showWoWIcon and (wowIcon .. " ") or "") .. wowText
		local bnetPart = (showBNetIcon and (bnetIcon .. " ") or "") .. bnetText

		text = string.format("%s | %s", wowPart, bnetPart)

		if showLabel then
			text = L("BROKER_LABEL_FRIENDS") .. text
		end
	else
		local countText = showTotal and string.format("%d/%d", totalOnline, totalFriends) or tostring(totalOnline)
		if showLabel then
			text = string.format(L("BROKER_LABEL_FRIENDS") .. "%s", countText)
		else
			text = countText
		end
	end

	dataObject.text = text

	-- Update Icon
	local showIcon = BetterFriendlistDB.brokerShowIcon ~= false -- Default true
	if showIcon then
		dataObject.icon = "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp"
	else
		dataObject.icon = nil
	end
end

-- ========================================
-- Tooltip Functions (GameTooltip fallback)
-- ========================================

-- Basic Tooltip
local function CreateBasicTooltip(gameTooltip)
	gameTooltip:AddLine(L("BROKER_TITLE"), 1, 0.82, 0, 1)
	gameTooltip:AddLine(" ")

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()

	gameTooltip:AddDoubleLine(
		L("BROKER_WOW_FRIENDS"),
		string.format(L("BROKER_ONLINE_TOTAL"), wowOnline, wowTotal),
		1,
		1,
		1,
		0,
		1,
		0
	)
	gameTooltip:AddDoubleLine(
		L("BROKER_HEADER_BNET"),
		string.format(L("BROKER_ONLINE_TOTAL"), bnetOnline, bnetTotal),
		1,
		1,
		1,
		0,
		0.5,
		1
	)
	gameTooltip:AddLine(" ")

	local QuickFilters = GetQuickFilters()
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	if QuickFilters then
		local filterText = QuickFilters:GetFilterText()
		if filterText then
			currentFilter = filterText
		end
	end
	gameTooltip:AddDoubleLine(L("BROKER_CURRENT_FILTER"), currentFilter, 1, 1, 1, 1, 1, 0)

	if BetterFriendlistDB and BetterFriendlistDB.brokerShowHints ~= false then
		gameTooltip:AddLine(" ")
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_HINT_CYCLE_FILTER_FULL"), 0.5, 0.9, 1, 1)
	end
end

-- Advanced Tooltip with Groups and Activity
local function CreateAdvancedTooltip(gameTooltip)
	gameTooltip:AddLine(L("BROKER_TITLE"), 1, 0.82, 0, 1)
	gameTooltip:AddLine(" ")

	local Groups = GetGroups()
	local DB = GetDB()

	-- Read fontColorFriendName as fallback color for names without class color
	local fontColorName = BetterFriendlistDB and BetterFriendlistDB.fontColorFriendName
	local fallbackNameColor = { r = 1, g = 1, b = 1 }
	if fontColorName and fontColorName.r and fontColorName.g and fontColorName.b then
		fallbackNameColor = fontColorName
	end

	local friends = {}

	if BNConnected() then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		for i = 1, numBNetOnline do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				local friendUID = (accountInfo.battleTag and accountInfo.battleTag ~= "")
						and ("bnet_" .. accountInfo.battleTag)
					or ("bnet_" .. tostring(accountInfo.bnetAccountID))
				local gameInfo = accountInfo.gameAccountInfo
				table.insert(friends, {
					id = friendUID,
					type = "bnet",
					isFavorite = accountInfo.isFavorite,
					client = gameInfo.clientProgram or "App",
					wowProjectID = gameInfo.wowProjectID,
					connected = true,
					info = {
						name = BFL:GetSafeAccountName(accountInfo.accountName, accountInfo.battleTag),
						level = gameInfo.characterLevel or "??",
						className = gameInfo.className or "UNKNOWN",
						area = gameInfo.areaName or "Unknown",
					},
				})
			end
		end
	end

	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.connected then
			local fullName = friendInfo.name or ""
			local normalizedName = BFL:NormalizeWoWFriendName(fullName)
			local friendUID = normalizedName and ("wow_" .. normalizedName) or ("wow_" .. fullName)
			table.insert(friends, {
				id = friendUID,
				type = "wow",
				client = "WoW",
				connected = true,
				info = {
					name = friendInfo.name or "Unknown",
					level = friendInfo.level or "??",
					className = friendInfo.className or "UNKNOWN",
					area = friendInfo.area or "Unknown",
				},
			})
		end
	end

	local groupsData = Groups and Groups:GetAll() or {}

	-- Read dynamic group settings
	local enableInGameGroup = DB and DB:Get("enableInGameGroup", false) or false
	local inGameGroupMode = DB and DB:Get("inGameGroupMode", "same_game") or "same_game"
	local enableRecentlyAdded = DB and DB:Get("enableRecentlyAddedGroup", false) or false
	local BNET_CLIENT_WOW_LOCAL = BNET_CLIENT_WOW or "WoW"

	local groupedFriends = {}
	local ungrouped = {}

	for _, friend in ipairs(friends) do
		if friend and friend.info then
			local customGroups = BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friend.id]
				or {}
			local assigned = false

			-- Favorites (BNet only)
			if friend.type == "bnet" and friend.isFavorite and groupsData["favorites"] then
				groupedFriends["favorites"] = groupedFriends["favorites"] or {}
				table.insert(groupedFriends["favorites"], friend)
				assigned = true
			end

			-- In-Game group (dynamic)
			if enableInGameGroup and groupsData["ingame"] then
				local isInGame = false
				if inGameGroupMode == "any_game" then
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected then
						local client = friend.client
						if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
							isInGame = true
						end
					end
				else
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected and friend.client == BNET_CLIENT_WOW_LOCAL then
						if friend.wowProjectID == WOW_PROJECT_ID then
							isInGame = true
						end
					end
				end
				if isInGame then
					groupedFriends["ingame"] = groupedFriends["ingame"] or {}
					table.insert(groupedFriends["ingame"], friend)
					assigned = true
				end
			end

			-- Recently Added group (dynamic)
			if enableRecentlyAdded and groupsData["recentlyadded"] then
				local RecentlyAddedModule = BFL:GetModule("RecentlyAdded")
				if RecentlyAddedModule and RecentlyAddedModule:IsFriendRecentlyAdded(friend.id) then
					groupedFriends["recentlyadded"] = groupedFriends["recentlyadded"] or {}
					table.insert(groupedFriends["recentlyadded"], friend)
					assigned = true
				end
			end

			-- Custom groups
			for _, groupId in ipairs(customGroups) do
				if groupsData[groupId] then
					groupedFriends[groupId] = groupedFriends[groupId] or {}
					table.insert(groupedFriends[groupId], friend)
					assigned = true
				end
			end

			if not assigned then
				table.insert(ungrouped, friend)
			end
		end
	end

	local displayedCount = 0
	local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds() or {}

	for _, groupId in ipairs(sortedGroupIds) do
		local groupFriends = groupedFriends[groupId]
		if groupFriends and #groupFriends > 0 then
			local groupInfo = groupsData[groupId]
			if groupInfo then
				gameTooltip:AddLine(groupInfo.name, 1, 0.82, 0, 1)

				for i, friend in ipairs(groupFriends) do
					if i > 5 then
						gameTooltip:AddLine(string.format(L("BROKER_AND_MORE"), #groupFriends - 5), 0.7, 0.7, 0.7)
						break
					end

					local info = friend.info
					local name = info.name or "Unknown"
					local level = info.level or "??"
					local className = info.className or "UNKNOWN"
					local zone = info.area or "Unknown"

					local classColor = RAID_CLASS_COLORS[className] or fallbackNameColor

					gameTooltip:AddDoubleLine(
						string.format("  %s (%s)", name, level),
						zone,
						classColor.r,
						classColor.g,
						classColor.b,
						0.7,
						0.7,
						0.7
					)
					displayedCount = displayedCount + 1
				end

				gameTooltip:AddLine(" ")
			end
		end
	end

	if #ungrouped > 0 then
		gameTooltip:AddLine(L("GROUP_NO_GROUP"), 0.7, 0.7, 0.7, 1)
		for i, friend in ipairs(ungrouped) do
			if i > 5 then
				gameTooltip:AddLine(string.format(L("BROKER_AND_MORE"), #ungrouped - 5), 0.7, 0.7, 0.7)
				break
			end

			local info = friend.info
			local name = info.name or "Unknown"
			local level = info.level or "??"
			local className = info.className or "UNKNOWN"
			local zone = info.area or "Unknown"

			local classColor = RAID_CLASS_COLORS[className] or fallbackNameColor

			gameTooltip:AddDoubleLine(
				string.format("  %s (%s)", name, level),
				zone,
				classColor.r,
				classColor.g,
				classColor.b,
				0.7,
				0.7,
				0.7
			)
			displayedCount = displayedCount + 1
		end
		gameTooltip:AddLine(" ")
	end

	if displayedCount == 0 then
		gameTooltip:AddLine(L("BROKER_NO_FRIENDS_ONLINE"), 0.7, 0.7, 0.7)
		gameTooltip:AddLine(" ")
	end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	gameTooltip:AddDoubleLine(
		L("BROKER_TOTAL_LABEL"),
		string.format(L("BROKER_ONLINE_FRIENDS_COUNT"), wowOnline + bnetOnline, wowTotal + bnetTotal),
		1,
		1,
		1,
		0,
		1,
		0
	)

	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	if GetQuickFilters() then
		local filterText = GetQuickFilters():GetFilterText()
		if filterText then
			currentFilter = filterText
		end
	end
	gameTooltip:AddDoubleLine(L("BROKER_FILTER_LABEL"), currentFilter, 1, 1, 1, 1, 1, 0)

	if BetterFriendlistDB and BetterFriendlistDB.brokerShowHints ~= false then
		gameTooltip:AddLine(" ")
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_HINT_CYCLE_FILTER_FULL"), 0.5, 0.9, 1, 1)
	end
end

-- ========================================
-- LibQTip-2.0 Tooltip
-- ========================================

-- Replace token case-insensitively in format string
local function ReplaceTokenCaseInsensitive(str, token, value)
	local pattern = "%%"
	for i = 1, #token do
		local c = token:sub(i, i)
		if c:match("%a") then
			pattern = pattern .. "[" .. c:upper() .. c:lower() .. "]"
		else
			pattern = pattern .. c
		end
	end
	pattern = pattern .. "%%"

	local safeValue = value:gsub("%%", "%%%%")
	return str:gsub(pattern, safeValue)
end

-- Check if token exists case-insensitively
local function HasTokenCaseInsensitive(str, token)
	local pattern = "%%"
	for i = 1, #token do
		local c = token:sub(i, i)
		if c:match("%a") then
			pattern = pattern .. "[" .. c:upper() .. c:lower() .. "]"
		else
			pattern = pattern .. c
		end
	end
	pattern = pattern .. "%%"
	return str:find(pattern) ~= nil
end

-- Helper: Get display name (respects nameDisplayFormat and tokens)
local function GetFriendDisplayName(friend)
	local isStreamerMode = BFL.StreamerMode and BFL.StreamerMode:IsActive()

	local DB = GetDB()
	local format = DB and DB:GetNameFormatString() or "%name%"

	-- 1. Prepare Data
	local name = "Unknown"
	local battletag = friend.battleTag or ""
	local note = friend.note or ""
	local nickname = DB and DB:GetNickname(friend.id) or ""
	local characterName = ""
	local realmName = ""

	if friend.type == "bnet" then
		if isStreamerMode then
			-- [STREAMER MODE] %name% must NEVER resolve to Real ID (accountName)
			local streamerNameMode = BetterFriendlistDB and BetterFriendlistDB.streamerModeNameFormat or "battletag"
			-- Get short BattleTag (before #)
			local shortTag = ""
			if battletag ~= "" then
				shortTag = battletag:match("([^#]+)") or battletag
			end
			if streamerNameMode == "nickname" and nickname ~= "" then
				name = nickname
			elseif streamerNameMode == "note" and note ~= "" then
				name = note
			else
				name = shortTag ~= "" and shortTag or "Unknown"
			end
		else
			name = BFL:GetSafeAccountName(friend.accountName, friend.battleTag)
		end
		-- Character name from game info
		characterName = friend.characterName or friend.toonName or ""
		realmName = friend.realmName or ""
	else
		local fullName = friend.fullName or friend.name or "Unknown"
		local showRealmName = DB and DB:Get("showRealmName", false)

		-- Extract character and realm from fullName
		local n, r = strsplit("-", fullName)
		characterName = n or fullName
		realmName = r or ""

		if showRealmName then
			name = fullName
		else
			local playerRealm = GetNormalizedRealmName()

			if r and r ~= playerRealm then
				name = n .. "*" -- Indicate cross-realm
			else
				name = n
			end
		end
	end

	-- Process battletag to be short version
	if battletag ~= "" then
		local hashIndex = string.find(battletag, "#")
		if hashIndex then
			battletag = string.sub(battletag, 1, hashIndex - 1)
		end
	end

	-- 2. Replace Tokens (case-insensitive)
	local result = format

	-- Smart Fallback Logic
	if
		nickname == ""
		and HasTokenCaseInsensitive(result, "nickname")
		and not HasTokenCaseInsensitive(result, "name")
	then
		nickname = name
	end
	if
		battletag == ""
		and HasTokenCaseInsensitive(result, "battletag")
		and not HasTokenCaseInsensitive(result, "name")
	then
		battletag = name
	end
	result = ReplaceTokenCaseInsensitive(result, "name", name)
	result = ReplaceTokenCaseInsensitive(result, "note", note)
	result = ReplaceTokenCaseInsensitive(result, "nickname", nickname)
	result = ReplaceTokenCaseInsensitive(result, "battletag", battletag)

	-- Class coloring for %character% token (parity with FriendsList:GetDisplayName)
	local colorClassNames = BetterFriendlistDB and BetterFriendlistDB.colorClassNames
	if colorClassNames == nil then
		colorClassNames = true
	end
	local classColorStr = nil
	if colorClassNames and characterName ~= "" then
		local classColor = GetClassColorForFriend(friend)
		if classColor then
			classColorStr = string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
		end
	end

	-- Decorate character name (faction icon, timerunning) before token replacement
	local decoratedChar = characterName
	if decoratedChar ~= "" then
		if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
			decoratedChar = TimerunningUtil.AddSmallIcon(decoratedChar)
		end
		if BetterFriendlistDB and BetterFriendlistDB.showFactionIcons then
			if friend.factionName == "Horde" then
				decoratedChar = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. decoratedChar
			elseif friend.factionName == "Alliance" then
				decoratedChar = "|TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:0:0|t" .. decoratedChar
			end
		end
	end

	if decoratedChar ~= "" and classColorStr then
		-- Handle wrapped pattern: (%character%) -> class-colored (CharName)
		local wrappedPattern = "%(%%[Cc][Hh][Aa][Rr][Aa][Cc][Tt][Ee][Rr]%%%)"
		local wrapStart, wrapEnd = result:find(wrappedPattern)
		if wrapStart then
			local wrappedReplacement = "|c" .. classColorStr .. "(" .. decoratedChar .. ")|r"
			result = result:sub(1, wrapStart - 1) .. wrappedReplacement .. result:sub(wrapEnd + 1)
			if HasTokenCaseInsensitive(result, "character") then
				local standaloneReplacement = "|c" .. classColorStr .. decoratedChar .. "|r"
				result = ReplaceTokenCaseInsensitive(result, "character", standaloneReplacement)
			end
		else
			local replacement = "|c" .. classColorStr .. decoratedChar .. "|r"
			result = ReplaceTokenCaseInsensitive(result, "character", replacement)
		end
	else
		-- No class coloring or empty character name
		if decoratedChar == "" then
			local wrappedPattern = "%(%%[Cc][Hh][Aa][Rr][Aa][Cc][Tt][Ee][Rr]%%%)"
			result = result:gsub(wrappedPattern, "")
		end
		result = ReplaceTokenCaseInsensitive(result, "character", decoratedChar)
	end

	result = ReplaceTokenCaseInsensitive(result, "realm", realmName)
	-- Phase 22b: Unified tokens - info tokens in name format
	result = ReplaceTokenCaseInsensitive(result, "level", friend.level and tostring(friend.level) or "")
	result = ReplaceTokenCaseInsensitive(result, "zone", friend.areaName or friend.area or "")
	result = ReplaceTokenCaseInsensitive(result, "class", friend.className or "")
	local gameName = ""
	if friend.gameAccountInfo and friend.gameAccountInfo.richPresence then
		gameName = friend.gameAccountInfo.richPresence
	elseif friend.clientProgram then
		gameName = friend.clientProgram
	end
	result = ReplaceTokenCaseInsensitive(result, "game", gameName)
	result = ReplaceTokenCaseInsensitive(result, "status", "")
	result = ReplaceTokenCaseInsensitive(result, "lastonline", "")

	-- 3. Cleanup
	result = result:gsub("%(%)", "")
	result = result:gsub("%[%]", "")
	result = result:match("^%s*(.-)%s*$")

	-- 4. Fallback
	if result == "" then
		return name
	end

	return result
end

-- Helper: Get colored level text
local function GetColoredLevelText(level)
	if not level or level == 0 then
		return ""
	end

	local hideMaxLevel = BetterFriendlistDB and BetterFriendlistDB.hideMaxLevel
	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 60

	if hideMaxLevel and level == maxLevel then
		return ""
	end

	local color = GetQuestDifficultyColor(level)
	return string.format("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
end

-- ========================================
-- Fixed Footer Implementation
-- ========================================
local FOOTER_HEIGHT = 160 -- Height for the fixed footer area (with hints)
local FOOTER_HEIGHT_NO_HINTS = 65 -- Height for the fixed footer area (without hints)
local MAX_TOOLTIP_HEIGHT = 690 -- Maximum height for the tooltip before scrolling

local function GetFooterHeight()
	local showHints = BetterFriendlistDB and BetterFriendlistDB.brokerShowHints ~= false
	return showHints and FOOTER_HEIGHT or FOOTER_HEIGHT_NO_HINTS
end

local function RenderFixedFooter(footerFrame)
	-- Clear previous content (both own .content and cross-module .lines)
	if footerFrame.content then
		for _, region in ipairs(footerFrame.content) do
			region:Hide()
		end
	end
	if footerFrame.lines then
		for _, line in ipairs(footerFrame.lines) do
			line:Hide()
		end
		footerFrame.lines = nil
	end
	footerFrame.content = {}

	local function AddLine(text, font, r, g, b)
		local fs = footerFrame:CreateFontString(nil, "OVERLAY", font or "GameTooltipTextSmall")
		fs:SetText(text)
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false)
		if r then
			fs:SetTextColor(r, g, b)
		end
		table.insert(footerFrame.content, fs)
		return fs
	end

	local function AddSeparator()
		local tex = footerFrame:CreateTexture(nil, "ARTWORK")
		tex:SetColorTexture(0.3, 0.3, 0.3, 0.5)
		tex:SetHeight(1)
		table.insert(footerFrame.content, tex)
		return tex
	end

	local yOffset = -5

	-- Separator
	local sep1 = AddSeparator()
	sep1:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sep1:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
	yOffset = yOffset - 5

	-- Total Online (uses filtered counts to match LDB text)
	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	local totalText = string.format(L("BROKER_TOTAL_ONLINE"), wowOnline + bnetOnline, wowTotal + bnetTotal)
	local totalLine = AddLine(totalText, "GameTooltipText", 1, 1, 1)
	totalLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	totalLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 16

	-- Filter
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	local QuickFilters = GetQuickFilters()
	local filterText = L("FILTER_ALL")
	local filterIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all"

	if QuickFilters then
		filterText = QuickFilters:GetFilterText() or filterText
		local icons = QuickFilters:GetIcons()
		if icons and icons[currentFilter] then
			filterIcon = icons[currentFilter]
		end
	end

	local filterDisplay = string.format("|T%s:16:16:0:0|t %s", filterIcon, C("ltyellow", filterText))
	local filterLine = AddLine(L("BROKER_FILTER_LABEL") .. filterDisplay, "GameTooltipText")
	filterLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	filterLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 18

	-- Sort
	local primarySort = BetterFriendlistDB and BetterFriendlistDB.primarySort or "status"
	local secondarySort = BetterFriendlistDB and BetterFriendlistDB.secondarySort or "name"

	local sortNames = {
		status = L("SORT_STATUS"),
		name = L("SORT_NAME"),
		level = L("SORT_LEVEL"),
		zone = L("SORT_ZONE"),
		game = L("SORT_GAME"),
		faction = L("SORT_FACTION"),
		guild = L("SORT_GUILD"),
		class = L("SORT_CLASS"),
		realm = L("SORT_REALM"),
	}
	local sortIcons = {
		status = "Interface\\AddOns\\BetterFriendlist\\Icons\\status",
		name = "Interface\\AddOns\\BetterFriendlist\\Icons\\name",
		level = "Interface\\AddOns\\BetterFriendlist\\Icons\\level",
		zone = "Interface\\AddOns\\BetterFriendlist\\Icons\\zone",
		game = "Interface\\AddOns\\BetterFriendlist\\Icons\\game",
		faction = "Interface\\AddOns\\BetterFriendlist\\Icons\\faction",
		guild = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild",
		class = "Interface\\AddOns\\BetterFriendlist\\Icons\\class",
		realm = "Interface\\AddOns\\BetterFriendlist\\Icons\\realm",
	}

	local function GetSortDisplay(mode)
		local name = sortNames[mode] or mode
		local icon = sortIcons[mode]
		if icon then
			return string.format("|T%s:14:14:0:0|t %s", icon, name)
		end
		return name
	end

	local sortText = GetSortDisplay(primarySort)
	if secondarySort and secondarySort ~= primarySort and secondarySort ~= "none" then
		sortText = sortText .. " > " .. GetSortDisplay(secondarySort)
	end

	local sortLine = AddLine(L("BROKER_SORT_LABEL") .. C("ltyellow", sortText), "GameTooltipText")
	sortLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sortLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 18

	-- Hints (conditionally shown based on brokerShowHints setting)
	local showHints = BetterFriendlistDB and BetterFriendlistDB.brokerShowHints ~= false
	if showHints then
		-- Separator
		local sep2 = AddSeparator()
		sep2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		sep2:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
		yOffset = yOffset - 5

		-- Hints 1
		local hint1 = AddLine(C("ltgray", L("BROKER_HINT_FRIEND_ACTIONS")), "GameTooltipTextSmall")
		hint1:SetPoint("TOP", footerFrame, "TOP", 0, yOffset)
		yOffset = yOffset - 14

		local hint2 = AddLine(
			C("ltblue", L("BROKER_HINT_CLICK_WHISPER"))
				.. L("BROKER_HINT_WHISPER")
				.. C("ltblue", L("BROKER_HINT_RIGHT_CLICK_MENU"))
				.. L("BROKER_HINT_CONTEXT_MENU"),
			"GameTooltipTextSmall"
		)
		hint2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint2:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		local hint3 = AddLine(
			C("ltblue", L("BROKER_HINT_ALT_CLICK"))
				.. L("BROKER_HINT_INVITE")
				.. C("ltblue", L("BROKER_HINT_SHIFT_CLICK"))
				.. L("BROKER_HINT_COPY"),
			"GameTooltipTextSmall"
		)
		hint3:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint3:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		-- Separator
		local sep3 = AddSeparator()
		sep3:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		sep3:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
		yOffset = yOffset - 5

		-- Hints 2
		local hint4 = AddLine(C("ltgray", L("BROKER_HINT_ICON_ACTIONS")), "GameTooltipTextSmall")
		hint4:SetPoint("TOP", footerFrame, "TOP", 0, yOffset)
		yOffset = yOffset - 14

		local hint5 =
			AddLine(C("ltblue", L("BROKER_HINT_LEFT_CLICK")) .. L("BROKER_HINT_TOGGLE"), "GameTooltipTextSmall")
		hint5:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint5:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14

		local hint6 = AddLine(
			C("ltblue", L("BROKER_HINT_RIGHT_CLICK"))
				.. L("BROKER_HINT_SETTINGS")
				.. C("ltblue", L("BROKER_HINT_MIDDLE_CLICK"))
				.. L("BROKER_HINT_CYCLE_FILTER"),
			"GameTooltipTextSmall"
		)
		hint6:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
		hint6:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
		yOffset = yOffset - 14
	end
end

-- Helper: Check if any context menu is open
local IsMenuOpen = BFL.BrokerUtils.IsMenuOpen

-- Wrapper: SetupTooltipAutoHide with module-specific upvalues (detailTooltip, LQT)
local function SetupTooltipAutoHide(tt, anchorFrame)
	BFL.BrokerUtils.SetupTooltipAutoHide(tt, anchorFrame, LQT, function() return detailTooltip end)
end

-- ========================================
-- ElvUI Tooltip Skin Helpers (delegate to BrokerUtils)
-- ========================================
local ApplyElvUISkin = BFL.BrokerUtils.ApplyElvUISkin
local RemoveElvUISkin = BFL.BrokerUtils.RemoveElvUISkin

local function TooltipCleanup(tt)
	if not tt then
		return
	end

	-- Remove ElvUI skin artifacts so released tooltips are clean
	RemoveElvUISkin(tt)

	BFL.BrokerUtils.ClearActiveBrokerTooltip()

	-- Hide our custom footer
	if tt.footerFrame then
		tt.footerFrame:Hide()
	end

	-- Ensure timer script is cleared (prevent leaks)
	if tt.bflTimer then
		tt.bflTimer:SetScript("OnUpdate", nil)
	end

	-- Restore standard LibQTip-2.0 anchors for ScrollFrame (PascalCase)
	if tt.ScrollFrame then
		tt.ScrollFrame:ClearAllPoints()
		tt.ScrollFrame:SetPoint("TOPLEFT", tt, "TOPLEFT", 10, -10)
		tt.ScrollFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", -10, 10)
	end

	-- Restore standard LibQTip-2.0 anchors for Slider (PascalCase)
	if tt.Slider then
		tt.Slider:ClearAllPoints()
		tt.Slider:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10)
		tt.Slider:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", -10, 10)
	end
end

local function CreateLibQTipTooltip(anchorFrame)
	if not LQT then
		return nil
	end

	-- Dismiss any other BFL broker tooltip (prevents overlap when hovering between plugins)
	BFL.BrokerUtils.DismissActiveBrokerTooltip()

	-- Define available columns and their default visibility
	local columns = {
		{ key = "Nickname", label = L("BROKER_COLUMN_NICKNAME"), align = "LEFT", default = false },
		{ key = "Name", label = L("BROKER_COLUMN_NAME"), align = "LEFT", default = true },
		{ key = "Level", label = L("BROKER_COLUMN_LEVEL"), align = "CENTER", default = true },
		{ key = "Character", label = L("BROKER_COLUMN_CHARACTER"), align = "LEFT", default = true },
		{ key = "Game", label = L("BROKER_COLUMN_GAME"), align = "LEFT", default = true },
		{ key = "Zone", label = L("BROKER_COLUMN_ZONE"), align = "LEFT", default = true },
		{ key = "Realm", label = L("BROKER_COLUMN_REALM"), align = "LEFT", default = true },
		{ key = "Notes", label = L("BROKER_COLUMN_NOTES"), align = "LEFT", default = true },
	}

	-- Get user-defined column order from DB
	local columnOrder = BetterFriendlistDB and BetterFriendlistDB.brokerColumnOrder
	local activeColumns = {}

	if columnOrder and #columnOrder > 0 then
		for _, colKey in ipairs(columnOrder) do
			local colDef = nil
			for _, c in ipairs(columns) do
				if c.key == colKey then
					colDef = c
					break
				end
			end

			if colDef then
				local settingKey = "brokerShowCol" .. colKey
				local visible = BetterFriendlistDB[settingKey]
				if visible == nil then visible = colDef.default end
				if visible ~= false then
					table.insert(activeColumns, colDef)
				end
			end
		end
	else
		for _, col in ipairs(columns) do
			local settingKey = "brokerShowCol" .. col.key
			local visible = BetterFriendlistDB[settingKey]
			if visible == nil then visible = col.default end
			if visible ~= false then
				table.insert(activeColumns, col)
			end
		end
	end

	if #activeColumns == 0 then
		table.insert(activeColumns, columns[2]) -- Fallback: Name column
	end

	-- Build Acquire arguments
	local numColumns = #activeColumns
	local alignArgs = {}
	for _, col in ipairs(activeColumns) do
		table.insert(alignArgs, col.align)
	end

	local tt = LQT:AcquireTooltip(tooltipKey, numColumns, unpack(alignArgs))
	if not tt then
		return nil
	end

	-- Hook OnHide to clean up layout changes when tooltip is released/hidden
	-- LibQTip-2.0's Tooltip:SetScript delegates to native Frame:SetScript via RawSetScript
	-- and tracks it in tooltip.Scripts for cleanup on Release.
	-- The ReleaseTooltip flow calls tooltip:Hide() FIRST which triggers our OnHide handler.
	local oldOnHide = tt:GetScript("OnHide")
	tt:SetScript("OnHide", function(self)
		TooltipCleanup(self)
		if oldOnHide then
			pcall(oldOnHide, self)
		end
	end)

	local status, err = xpcall(function()
		tt:Clear()
		tt:SmartAnchorTo(anchorFrame)
		tt.anchorFrame = anchorFrame -- Store anchor for refresh
		SetupTooltipAutoHide(tt, anchorFrame)
		tt:SetFrameStrata("HIGH")

		-- ElvUI Skin: Apply ElvUI template (hides NineSlice, applies ElvUI backdrop)
		ApplyElvUISkin(tt)

		-- Setup Fixed Footer Frame
		if not tt.footerFrame then
			tt.footerFrame = CreateFrame("Frame", nil, tt)
			tt.footerFrame:SetPoint("BOTTOMLEFT", tt, "BOTTOMLEFT", 0, 0)
			tt.footerFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", 0, 0)
		end
		tt.footerFrame:SetHeight(GetFooterHeight())
		tt.footerFrame:Show()

		-- Adjust ScrollFrame to respect footer (PascalCase in v2)
		if tt.ScrollFrame then
			tt.ScrollFrame:ClearAllPoints()
			tt.ScrollFrame:SetPoint("TOP", tt, "TOP", 0, -10)
			tt.ScrollFrame:SetPoint("LEFT", tt, "LEFT", 10, 0)
			tt.ScrollFrame:SetPoint("RIGHT", tt, "RIGHT", -10, 0)
			tt.ScrollFrame:SetPoint("BOTTOM", tt.footerFrame, "TOP", 0, 0)
		end

		-- Render Footer Content
		RenderFixedFooter(tt.footerFrame)

		tt:SetMaxHeight(MAX_TOOLTIP_HEIGHT)
		tt:UpdateLayout()

		-- Header
		local headerRow = tt:AddHeadingRow()
		local headerCell = headerRow:GetCell(1)
		headerCell:SetColSpan(numColumns)
		headerCell:SetFontObject(BetterFriendlistFontNormalLarge)
		headerCell:SetJustifyH("LEFT")
		headerCell:SetText(C("dkyellow", L("BROKER_TITLE")))
		tt:AddSeparator()

		-- Column Headers
		local headerCells = {}
		for _, col in ipairs(activeColumns) do
			table.insert(headerCells, C("ltyellow", col.label))
		end
		tt:AddRow(unpack(headerCells))
		tt:AddSeparator()

		local Groups = GetGroups()
		local groupsData = Groups and Groups:GetAll() or {}

		-- Get ALL online friends directly from API
		local friends = {}

		-- Check if mobile should be treated as offline
		local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline

		-- Initialize group counts and buckets
		local groupCounts = {}
		local groupedFriends = {}

		for groupId, groupData in pairs(groupsData) do
			groupCounts[groupId] = { total = 0, online = 0 }
			groupedFriends[groupId] = {}
		end
		if not groupCounts["nogroup"] then
			groupCounts["nogroup"] = { total = 0, online = 0 }
			groupedFriends["nogroup"] = {}
		end

		-- Read dynamic group settings
		local DB = GetDB()
		local enableInGameGroup = DB and DB:Get("enableInGameGroup", false) or false
		local inGameGroupMode = DB and DB:Get("inGameGroupMode", "same_game") or "same_game"
		local enableRecentlyAdded = DB and DB:Get("enableRecentlyAddedGroup", false) or false
		local BNET_CLIENT_WOW = BNET_CLIENT_WOW or "WoW"

		-- Helper to process a friend (add to groups and counts)
		local function ProcessFriend(friend)
			local customGroups = BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friend.id]
				or {}
			local assigned = false
			local isOnline = friend.connected

			-- Favorites group (BNet only)
			if friend.type == "bnet" and friend.isFavorite then
				if groupsData["favorites"] then
					groupCounts["favorites"].total = groupCounts["favorites"].total + 1
					if isOnline then
						groupCounts["favorites"].online = groupCounts["favorites"].online + 1
						table.insert(groupedFriends["favorites"], friend)
					end
					assigned = true
				end
			end

			-- In-Game group (dynamic, parity with FriendsList)
			if enableInGameGroup and groupsData["ingame"] then
				local isInGame = false

				if inGameGroupMode == "any_game" then
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected then
						local client = friend.client
						if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
							isInGame = true
						end
					end
				else
					-- Same Game (Default): WoW friends OR BNet friends in SAME WoW version
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif friend.type == "bnet" and friend.connected and friend.client == BNET_CLIENT_WOW then
						if friend.wowProjectID == WOW_PROJECT_ID then
							isInGame = true
						end
					end
				end

				if isInGame then
					groupCounts["ingame"].total = groupCounts["ingame"].total + 1
					if isOnline then
						groupCounts["ingame"].online = groupCounts["ingame"].online + 1
						table.insert(groupedFriends["ingame"], friend)
					end
					assigned = true
				end
			end

			-- Recently Added group (dynamic, parity with FriendsList)
			if enableRecentlyAdded and groupsData["recentlyadded"] then
				local RecentlyAddedModule = BFL:GetModule("RecentlyAdded")
				if RecentlyAddedModule and RecentlyAddedModule:IsFriendRecentlyAdded(friend.id) then
					groupCounts["recentlyadded"].total = groupCounts["recentlyadded"].total + 1
					if isOnline then
						groupCounts["recentlyadded"].online = groupCounts["recentlyadded"].online + 1
						table.insert(groupedFriends["recentlyadded"], friend)
					end
					assigned = true
				end
			end

			-- Custom groups
			for _, groupId in ipairs(customGroups) do
				if groupsData[groupId] then
					groupCounts[groupId].total = groupCounts[groupId].total + 1
					if isOnline then
						groupCounts[groupId].online = groupCounts[groupId].online + 1
						table.insert(groupedFriends[groupId], friend)
					end
					assigned = true
				end
			end

			-- Fallback: No Group
			if not assigned then
				if groupCounts["nogroup"] then
					groupCounts["nogroup"].total = groupCounts["nogroup"].total + 1
					if isOnline then
						groupCounts["nogroup"].online = groupCounts["nogroup"].online + 1
						table.insert(groupedFriends["nogroup"], friend)
					end
				end
			end
		end

		-- Collect BNet Friends (ALL)
		if BNConnected() then
			local numBNetTotal = BNGetNumFriends()
			for i = 1, numBNetTotal do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				if accountInfo then
					local gameInfo = accountInfo.gameAccountInfo or {}
					local isOnline = gameInfo.isOnline or false
					local client = gameInfo.clientProgram or "App"

					local isMobile = (client == "BSAp")
					if treatMobileAsOffline and isMobile then
						isOnline = false
					end

					local friendUID = (accountInfo.battleTag and accountInfo.battleTag ~= "")
							and ("bnet_" .. accountInfo.battleTag)
						or ("bnet_" .. tostring(accountInfo.bnetAccountID))

					local friend = {
						id = friendUID,
						bnetAccountID = accountInfo.bnetAccountID,
						battleTag = accountInfo.battleTag,
						type = "bnet",
						accountName = BFL:GetSafeAccountName(accountInfo.accountName, accountInfo.battleTag),
						characterName = gameInfo.characterName or "",
						level = gameInfo.characterLevel or 0,
						className = gameInfo.className or "UNKNOWN",
						classID = gameInfo.classID,
						client = client,
						area = gameInfo.areaName or "",
						realmName = gameInfo.realmName or "",
						factionName = gameInfo.factionName or "",
						guildName = gameInfo.guildName or "",
						wowProjectID = gameInfo.wowProjectID,
						timerunningSeasonID = gameInfo.timerunningSeasonID,
						isAFK = accountInfo.isAFK or (gameInfo.isAFK or gameInfo.isGameAFK),
						isDND = accountInfo.isDND or (gameInfo.isDND or gameInfo.isGameBusy),
						isMobile = isMobile,
						broadcast = accountInfo.customMessage or "",
						broadcastTime = accountInfo.customMessageTime,
						note = accountInfo.note or "",
						gameAccountID = gameInfo.gameAccountID,
						connected = isOnline,
						isFavorite = accountInfo.isFavorite,
						accountInfo = accountInfo,
						index = i,
					}

					-- Classic fallback: Parse richPresence if area is missing (format: "Zone - Realm")
					if (friend.area == "") and gameInfo.richPresence then
						local sep = string.find(gameInfo.richPresence, " - ", 1, true)
						if sep then
							friend.area = strtrim(string.sub(gameInfo.richPresence, 1, sep - 1))
							if friend.realmName == "" then
								friend.realmName = strtrim(string.sub(gameInfo.richPresence, sep + 3))
							end
						else
							friend.area = strtrim(gameInfo.richPresence)
						end
					end

					ProcessFriend(friend)
				end
			end
		end

		-- Collect WoW Friends (ALL)
		local numWoWFriends = C_FriendList.GetNumFriends() or 0
		for i = 1, numWoWFriends do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo then
				local fullName = friendInfo.name or ""
				local name, realm = strsplit("-", fullName, 2)
				local normalizedName = BFL:NormalizeWoWFriendName(fullName)
				local friendUID = normalizedName and ("wow_" .. normalizedName) or ("wow_" .. fullName)

				local friend = {
					id = friendUID,
					type = "wow",
					accountName = name,
					characterName = name,
					fullName = fullName,
					level = friendInfo.level or 0,
					className = friendInfo.className or "UNKNOWN",
					classID = friendInfo.classID,
					client = "WoW",
					area = friendInfo.area or "",
					realmName = realm or GetRealmName(),
					factionName = UnitFactionGroup("player"),
					guildName = GetGuildInfo(fullName) or "",
					isAFK = friendInfo.afk,
					isDND = friendInfo.dnd,
					note = friendInfo.notes or "",
					connected = friendInfo.connected,
					index = i,
				}

				ProcessFriend(friend)
			end
		end

		-- Apply current filter (to online friends only)
		local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
		if currentFilter ~= "all" then
			for groupId, groupFriends in pairs(groupedFriends) do
				local filteredFriends = {}
				for _, friend in ipairs(groupFriends) do
					local include = false

					if currentFilter == "online" then
						include = true
					elseif currentFilter == "offline" then
						include = false
					elseif currentFilter == "wow" then
						include = (friend.type == "wow" or friend.client == "WoW")
					elseif currentFilter == "bnet" then
						include = (friend.type == "bnet" and friend.client ~= "WoW")
					elseif currentFilter == "hideafk" then
						include = not (friend.isAFK or friend.isDND)
					elseif currentFilter == "retail" then
						include = (friend.client == "WoW" or friend.type == "wow")
					end

					if include then
						table.insert(filteredFriends, friend)
					end
				end
				groupedFriends[groupId] = filteredFriends
			end
		end

		-- Apply current sort mode
		local primarySort = BetterFriendlistDB and BetterFriendlistDB.primarySort or "status"
		local secondarySort = BetterFriendlistDB and BetterFriendlistDB.secondarySort or "name"

		local function CompareFriends(a, b)
			local function CompareByMode(mode, a, b)
				if mode == "name" then
					local nameA = GetFriendDisplayName(a)
					local nameB = GetFriendDisplayName(b)
					if (nameA or ""):lower() ~= (nameB or ""):lower() then
						return (nameA or ""):lower() < (nameB or ""):lower()
					end
				elseif mode == "level" then
					local levelA = a.level or 0
					local levelB = b.level or 0
					if levelA ~= levelB then
						return levelA > levelB
					end
				elseif mode == "zone" then
					local zoneA = a.area or ""
					local zoneB = b.area or ""
					if zoneA:lower() ~= zoneB:lower() then
						return zoneA:lower() < zoneB:lower()
					end
				elseif mode == "game" then
					local function GetGamePriority(friend)
						if friend.client == "WoW" or friend.type == "wow" then
							return 0
						end
						if friend.client == "App" or friend.client == "BSAp" then
							return 2
						end
						return 1
					end
					local priorityA = GetGamePriority(a)
					local priorityB = GetGamePriority(b)
					if priorityA ~= priorityB then
						return priorityA < priorityB
					end
				elseif mode == "status" then
					local function GetStatusPriority(friend)
						if friend.isDND then
							return 1
						end
						if friend.isAFK or friend.isMobile then
							return 2
						end
						return 0
					end
					local priorityA = GetStatusPriority(a)
					local priorityB = GetStatusPriority(b)
					if priorityA ~= priorityB then
						return priorityA < priorityB
					end
				elseif mode == "faction" then
					local factionA = a.factionName or ""
					local factionB = b.factionName or ""
					if factionA ~= factionB then
						return factionA < factionB
					end
				elseif mode == "guild" then
					local guildA = a.guildName or ""
					local guildB = b.guildName or ""
					if guildA ~= guildB then
						return guildA < guildB
					end
				elseif mode == "class" then
					local classA = a.className or ""
					local classB = b.className or ""
					if classA ~= classB then
						return classA < classB
					end
				elseif mode == "realm" then
					local realmA = a.realmName or ""
					local realmB = b.realmName or ""
					if realmA ~= realmB then
						return realmA < realmB
					end
				end
				return nil
			end

			local primaryResult = CompareByMode(primarySort, a, b)
			if primaryResult ~= nil then
				return primaryResult
			end

			if secondarySort and secondarySort ~= primarySort and secondarySort ~= "none" then
				local secondaryResult = CompareByMode(secondarySort, a, b)
				if secondaryResult ~= nil then
					return secondaryResult
				end
			end

			return CompareByMode("name", a, b)
		end

		-- Sort each group
		for groupId, groupFriends in pairs(groupedFriends) do
			table.sort(groupFriends, CompareFriends)
		end

		local displayedCount = 0

		-- Helper to render a friend row
		local function RenderFriendRow(friend, indentation)
			local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND, friend.isMobile)
			local clientInfo = GetClientInfo(friend.client)

			local factionIcon = ""
			if BetterFriendlistDB and BetterFriendlistDB.showFactionIcons then
				if friend.client == "WoW" or friend.type == "wow" then
					factionIcon = GetFactionIcon(friend.factionName)
				end
			end

			-- Color Logic (Parity with FriendsList)
			local playerFactionGroup = UnitFactionGroup("player")
			local grayOtherFaction = BetterFriendlistDB and BetterFriendlistDB.grayOtherFaction
			local colorClassNames = BetterFriendlistDB and BetterFriendlistDB.colorClassNames
			if colorClassNames == nil then
				colorClassNames = true
			end

			local isOppositeFaction = friend.factionName
				and friend.factionName ~= playerFactionGroup
				and friend.factionName ~= ""
			local shouldGray = grayOtherFaction and isOppositeFaction

			-- Read fontColorFriendName from settings as fallback color
			local fontColorName = BetterFriendlistDB and BetterFriendlistDB.fontColorFriendName
			local defaultNameColor = "|cffffffff"
			if fontColorName and fontColorName.r and fontColorName.g and fontColorName.b then
				defaultNameColor = string.format(
					"|cff%02x%02x%02x",
					fontColorName.r * 255,
					fontColorName.g * 255,
					fontColorName.b * 255
				)
			end

			local nameColor = defaultNameColor
			if shouldGray then
				nameColor = "|cff808080"
			elseif friend.type == "bnet" then
				nameColor = defaultNameColor
			elseif friend.type == "wow" then
				if colorClassNames then
					local classColor = GetClassColorForFriend(friend)
					nameColor =
						string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
				else
					nameColor = defaultNameColor
				end
			end

			local cellValues = {}
			for _, col in ipairs(activeColumns) do
				local val = ""
				if col.key == "Nickname" then
					local DB = GetDB()
					local nick = DB and DB:GetNickname(friend.id) or ""
					if nick ~= "" then
						val = defaultNameColor .. nick .. "|r"
					end
				elseif col.key == "Name" then
					local prefix = indentation .. statusIcon .. " "
					val = prefix .. nameColor .. GetFriendDisplayName(friend) .. "|r"
				elseif col.key == "Level" then
					val = GetColoredLevelText(friend.level)
				elseif col.key == "Character" then
					if friend.characterName and friend.characterName ~= "" then
						local displayCharName = friend.characterName
						if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
							displayCharName = TimerunningUtil.AddSmallIcon(displayCharName)
						end
						if factionIcon ~= "" then
							displayCharName = factionIcon .. " " .. displayCharName
						end

						if shouldGray then
							val = "|cff808080" .. displayCharName .. "|r"
						elseif colorClassNames then
							val = ClassColorText(friend, displayCharName)
						else
							val = displayCharName
						end
					else
						val = ""
					end
				elseif col.key == "Game" then
					val = clientInfo.iconStr .. " " .. clientInfo.short
				elseif col.key == "Zone" then
					val = friend.area or ""
				elseif col.key == "Realm" then
					val = friend.realmName or ""
				elseif col.key == "Notes" then
					val = friend.note or ""
				end
				table.insert(cellValues, val)
			end

			local row = tt:AddRow(unpack(cellValues))

			row:SetColor(0, 0, 0, 0)

			row:SetScript("OnEnter", function()
				row:SetColor(0.2, 0.4, 0.6, 0.3)
			end)
			row:SetScript("OnLeave", function()
				row:SetColor(0, 0, 0, 0)
			end)

			row:SetScript("OnMouseUp", function(frame, button)
				OnFriendLineClick(nil, friend, button)
			end)

			return row
		end

		-- Get sorted group IDs for consistent display order (INCLUDE "nogroup" now)
		local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds(true) or {}

		-- Display grouped friends (BNet and WoW) in configured order
		for _, groupId in ipairs(sortedGroupIds) do
			local groupFriends = groupedFriends[groupId]
			local counts = groupCounts[groupId]

			if groupFriends and #groupFriends > 0 then
				local groupInfo = groupsData[groupId]
				if not groupInfo and groupId == "nogroup" then
					groupInfo = { name = L("GROUP_NO_GROUP"), color = { r = 0.5, g = 0.5, b = 0.5 }, builtin = true }
				end

				if groupInfo then
					local groupRow = tt:AddRow()
					local groupCell = groupRow:GetCell(1)

					local colorCode = "ffffffff"
					if groupInfo.color then
						colorCode = string.format(
							"ff%02x%02x%02x",
							groupInfo.color.r * 255,
							groupInfo.color.g * 255,
							groupInfo.color.b * 255
						)
					end

					local countText = string.format("%d/%d", counts.online, counts.total)
					local collapsed = groupInfo.collapsed
					local prefix = collapsed and "(+) " or "(-) "

					local headerText = string.format("|c%s%s%s|r (%s)", colorCode, prefix, groupInfo.name, countText)
					groupCell:SetColSpan(numColumns)
					groupCell:SetJustifyH("LEFT")
					groupCell:SetText("  " .. headerText)

					groupRow:SetScript("OnEnter", function()
						groupRow:SetColor(0.2, 0.2, 0.2, 0.5)
					end)
					groupRow:SetScript("OnLeave", function()
						groupRow:SetColor(0, 0, 0, 0)
					end)

					groupRow:SetScript("OnMouseUp", function(frame, button)
						local actualButton = button or (GetMouseButtonClicked and GetMouseButtonClicked())

						if actualButton == "LeftButton" then
							if Groups and Groups.Toggle then
								Groups:Toggle(groupId)
								if Broker.RefreshTooltip then
									Broker:RefreshTooltip()
								end
							end
						elseif actualButton == "RightButton" then
							if MenuUtil and MenuUtil.CreateContextMenu then
								MenuUtil.CreateContextMenu(frame, function(owner, rootDescription)
									rootDescription:CreateTitle(groupInfo.name)

									if not groupInfo.builtin then
										rootDescription:CreateButton(L("MENU_RENAME_GROUP"), function()
											StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, groupId)
										end)

										rootDescription:CreateButton(L("MENU_CHANGE_COLOR"), function()
											local FriendsList = BFL:GetModule("FriendsList")
											if FriendsList and FriendsList.OpenColorPicker then
												FriendsList:OpenColorPicker(groupId)
											end
										end)

										rootDescription:CreateButton(L("MENU_DELETE_GROUP"), function()
											StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, groupId)
										end)
									end
								end)
							end
						end
					end)

					-- Render friends ONLY if not collapsed
					if not collapsed then
						for i, friend in ipairs(groupFriends) do
							RenderFriendRow(friend, "    ")
							displayedCount = displayedCount + 1
						end
					end
				end
			end
		end

		-- Footer (Empty check only)
		if displayedCount == 0 then
			tt:AddSeparator()
			local emptyRow = tt:AddRow()
			local emptyCell = emptyRow:GetCell(1)
			emptyCell:SetColSpan(numColumns)
			emptyCell:SetJustifyH("CENTER")
			emptyCell:SetText(C("gray", L("BROKER_NO_FRIENDS_ONLINE")))
		end

		local footerHeight = GetFooterHeight()
		local maxContentHeight = MAX_TOOLTIP_HEIGHT - footerHeight
		tt:SetMaxHeight(maxContentHeight)
		tt:UpdateLayout()

		-- Add space for footer to the calculated height
		tt:SetHeight(tt:GetHeight() + footerHeight)

		-- Fix Slider Anchor (must stop at footer) - PascalCase in v2
		if tt.Slider and tt.Slider:IsShown() then
			tt.Slider:ClearAllPoints()
			tt.Slider:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10)
			tt.Slider:SetPoint("BOTTOMRIGHT", tt.footerFrame, "TOPRIGHT", -10, 0)

			if tt.ScrollFrame then
				tt.ScrollFrame:SetPoint("RIGHT", tt, "RIGHT", -30, 0)
			end
		end

		tt:Show()
	end, geterrorhandler())

	if not status then
		tt:Clear()
		local errRow = tt:AddRow()
		local errCell = errRow:GetCell(1)
		errCell:SetText(L("ERROR_TOOLTIP_DISPLAY"))
		local errRow2 = tt:AddRow()
		local errCell2 = errRow2:GetCell(1)
		errCell2:SetText(tostring(err))
		tt:Show()
		SetupTooltipAutoHide(tt, anchorFrame)
	end

	-- Register as active BFL broker tooltip
	BFL.BrokerUtils.SetActiveBrokerTooltip(tt, LQT, function() return detailTooltip end)

	return tt
end

-- Refresh the tooltip (re-create it) to update content
function Broker:RefreshTooltip()
	if LQT and tooltip and tooltip:IsShown() then
		local anchor = tooltip.anchorFrame

		-- Don't re-create if nobody is looking (prevents event-driven refreshes
		-- from resetting the auto-hide timer after the user moved away)
		local isOver = tooltip:IsMouseOver()
		if not isOver and anchor and anchor.IsMouseOver then
			isOver = anchor:IsMouseOver()
		end
		if not isOver then
			LQT:ReleaseTooltip(tooltip)
			tooltip = nil
			return
		end

		LQT:ReleaseTooltip(tooltip)
		tooltip = nil
		if anchor then
			tooltip = CreateLibQTipTooltip(anchor)
		end
	end
end

-- ========================================
-- LibQTip-2.0 Detail Tooltip (Two-Tier System)
-- ========================================

local detailTooltipKey = "BetterFriendlistBrokerDetailTT"

-- Create detail tooltip on friend line hover
local function CreateDetailTooltip(cell, data)
	if not LQT or not data then
		return
	end

	-- Release previous detail tooltip if exists
	if detailTooltip then
		LQT:ReleaseTooltip(detailTooltip)
		detailTooltip = nil
	end

	local tt2 = LQT:AcquireTooltip(detailTooltipKey, 3, "LEFT", "RIGHT", "RIGHT")
	tt2:Clear()
	tt2:SmartAnchorTo(cell)
	tt2:SetAutoHideDelay(0.25, tooltip)
	tt2:SetFrameStrata("HIGH")
	tt2:UpdateLayout()

	-- Hook OnHide to clean up ElvUI skin when detail tooltip is released/hidden
	local oldOnHide2 = tt2:GetScript("OnHide")
	tt2:SetScript("OnHide", function(self)
		RemoveElvUISkin(self)
		if oldOnHide2 then
			pcall(oldOnHide2, self)
		end
	end)

	-- ElvUI Skin: Apply ElvUI template (hides NineSlice, applies ElvUI backdrop)
	ApplyElvUISkin(tt2)

	-- Header with character/account name
	local headerRow = tt2:AddHeadingRow()
	local displayName = data.characterName and data.characterName ~= "" and data.characterName
		or BFL:GetSafeAccountName(data.accountName, data.battleTag)
		or "Unknown"

	-- [STREAMER MODE] Use safe name for detail tooltip header
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() then
		if data.battleTag then
			displayName = data.battleTag:match("([^#]+)") or data.battleTag
		elseif data.characterName and data.characterName ~= "" then
			displayName = data.characterName
		else
			displayName = "Unknown"
		end
	end

	local headerCell = headerRow:GetCell(1)
	headerCell:SetColSpan(3)
	headerCell:SetFontObject(BetterFriendlistFontNormalLarge)
	headerCell:SetJustifyH("LEFT")
	headerCell:SetText(C("dkyellow", displayName))
	tt2:AddSeparator()

	-- Status info
	if data.isAFK or data.isDND then
		local statusIcon = GetStatusIcon(data.isAFK, data.isDND)
		local statusText = data.isAFK and L("STATUS_AWAY") or L("STATUS_DND_FULL")
		local statusRow = tt2:AddRow(C("ltblue", L("STATUS_LABEL")), "", "")
		local statusCell = statusRow:GetCell(2)
		statusCell:SetColSpan(2)
		statusCell:SetJustifyH("RIGHT")
		statusCell:SetText(statusIcon .. " " .. C("gold", statusText))
	end

	-- Game/Client info with icon
	if data.client then
		local clientInfo = GetClientInfo(data.client)
		local gameRow = tt2:AddRow(C("ltblue", L("GAME_LABEL")), "", "")
		local gameCell = gameRow:GetCell(2)
		gameCell:SetColSpan(2)
		gameCell:SetJustifyH("RIGHT")
		gameCell:SetText(clientInfo.iconStr .. " " .. clientInfo.long)
	end

	-- WoW-specific details
	if data.client == "WoW" then
		-- Realm
		if data.realmName and data.realmName ~= "" then
			local realmRow = tt2:AddRow(C("ltblue", L("REALM_LABEL")), data.realmName, "")
			local realmCell = realmRow:GetCell(2)
			realmCell:SetColSpan(2)
			realmCell:SetJustifyH("RIGHT")
			realmCell:SetText(data.realmName)
		end

		-- Class (with color)
		if data.className and data.className ~= "UNKNOWN" then
			local classRow = tt2:AddRow(C("ltblue", L("CLASS_LABEL")), "", "")
			local classCell = classRow:GetCell(2)
			classCell:SetColSpan(2)
			classCell:SetJustifyH("RIGHT")
			classCell:SetText(C(data.className, _G[data.className] or data.className))
		end

		-- Faction with icon
		if data.factionName and data.factionName ~= "" then
			local factionIcon = GetFactionIcon(data.factionName)
			local factionRow = tt2:AddRow(C("ltblue", L("FACTION_LABEL")), "", "")
			local factionCell = factionRow:GetCell(2)
			factionCell:SetColSpan(2)
			factionCell:SetJustifyH("RIGHT")
			factionCell:SetText(factionIcon .. " " .. data.factionName)
		end
	end

	-- Zone/Area
	if data.area and data.area ~= "" then
		local zoneRow = tt2:AddRow(C("ltblue", L("ZONE_LABEL")), "", "")
		local zoneCell = zoneRow:GetCell(2)
		zoneCell:SetColSpan(2)
		zoneCell:SetJustifyH("RIGHT")
		zoneCell:SetText(data.area)
	end

	-- Notes
	if data.note and data.note ~= "" then
		tt2:AddSeparator()
		local notesHeaderRow = tt2:AddRow()
		local notesHeaderCell = notesHeaderRow:GetCell(1)
		notesHeaderCell:SetColSpan(3)
		notesHeaderCell:SetJustifyH("LEFT")
		notesHeaderCell:SetText(C("ltblue", L("NOTE_LABEL")))
		tt2:AddSeparator()
		local notesRow = tt2:AddRow()
		local notesCell = notesRow:GetCell(1)
		notesCell:SetColSpan(3)
		notesCell:SetJustifyH("LEFT")
		notesCell:SetText(C("white", data.note))
	end

	-- Broadcast message (BNet only)
	if data.type == "bnet" and data.broadcast and data.broadcast ~= "" then
		tt2:AddSeparator()
		local broadcastHeaderRow = tt2:AddRow()
		local broadcastHeaderCell = broadcastHeaderRow:GetCell(1)
		broadcastHeaderCell:SetColSpan(3)
		broadcastHeaderCell:SetJustifyH("LEFT")
		broadcastHeaderCell:SetText(C("ltblue", L("BROADCAST_LABEL")))
		tt2:AddSeparator()
		local broadcastRow = tt2:AddRow()
		local broadcastCell = broadcastRow:GetCell(1)
		broadcastCell:SetColSpan(3)
		broadcastCell:SetJustifyH("LEFT")
		broadcastCell:SetText(C("white", data.broadcast))

		-- Broadcast time
		if data.broadcastTime then
			local timeSince = time() - data.broadcastTime
			local timeText = SecondsToTime(timeSince)
			local timeRow = tt2:AddRow()
			local timeCell = timeRow:GetCell(1)
			timeCell:SetColSpan(3)
			timeCell:SetJustifyH("RIGHT")
			timeCell:SetText(C("ltgray", string.format(L("ACTIVE_SINCE_FMT"), timeText)))
		end
	end

	tt2:Show()
	detailTooltip = tt2
end

-- Release detail tooltip on mouse leave
local function ReleaseDetailTooltip()
	if LQT and detailTooltip then
		LQT:ReleaseTooltip(detailTooltip)
		detailTooltip = nil
	end
end

-- ========================================
-- Click Handlers (Data Broker)
-- ========================================

function Broker:OnClick(clickedFrame, button)
	-- Safety: Don't process clicks in combat
	if InCombatLockdown() then
		return
	end

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		return
	end

	local action = "none"
	if button == "LeftButton" then
		action = BetterFriendlistDB.brokerClickAction or "toggle"
	elseif button == "RightButton" then
		action = BetterFriendlistDB.brokerRightClickAction or "settings"
	elseif button == "MiddleButton" then
		action = "cycle_filter"
	end

	if action == "toggle" then
		ToggleFriendsFrame(1)
	elseif action == "friends" then
		if BFL.ShowBlizzardFriendsFrame then
			BFL.ShowBlizzardFriendsFrame()
		elseif BFL.OriginalToggleFriendsFrame then
			BFL.OriginalToggleFriendsFrame(1)
		else
			ToggleFriendsFrame(1)
		end
	elseif action == "settings" then
		-- Ensure the friendlist is open first (never close it)
		if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
			if _G.ShowBetterFriendsFrame then
				_G.ShowBetterFriendsFrame()
			else
				BetterFriendsFrame:Show()
			end
		end
		local Settings = BFL:GetModule("Settings")
		if Settings then
			if BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
				Settings:Hide()
			else
				Settings:Show()
				Settings:SelectCategory(5) -- Data Broker tab
			end
		end
	elseif action == "bnet" then
		ToggleFriendsFrame(1)
	elseif action == "cycle_filter" then
		local currentFilter = BetterFriendlistDB.quickFilter or "all"
		local currentIndex = 1

		for i, filter in ipairs(FILTER_CYCLE) do
			if filter == currentFilter then
				currentIndex = i
				break
			end
		end

		local nextIndex = (currentIndex % #FILTER_CYCLE) + 1
		local nextFilter = FILTER_CYCLE[nextIndex]

		if BetterFriendsFrame_SetQuickFilter then
			BetterFriendsFrame_SetQuickFilter(nextFilter)
		else
			if BetterFriendlistDB then
				BetterFriendlistDB.quickFilter = nextFilter
			end
		end

		BFL:ForceRefreshFriendsList()

		if LQT and tooltip then
			LQT:ReleaseTooltip(tooltip)
			tooltip = nil
		end

		-- Recreate tooltip immediately with updated filter
		if LQT and dataObject and dataObject.OnEnter and clickedFrame then
			if clickedFrame then
				tooltip = CreateLibQTipTooltip(clickedFrame)
			end
			self:UpdateBrokerText()
		end
	end
end

-- ========================================
-- Public API
-- ========================================

function Broker:Initialize()
	local isEnabled = BetterFriendlistDB and BetterFriendlistDB.brokerEnabled

	if not isEnabled then
		return
	end

	if not LDB then
		return
	end
	if not LQT then
		-- LibQTip-2.0 not available - tooltips will be basic
	end

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		return
	end

	if not BetterFriendlistDB.brokerEnabled then
		return
	end

	-- Create Data Broker object
	local dataObjectDef = {
		type = "data source",
		text = "Friends: 0/0",
		icon = "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp",
		label = L("BROKER_TITLE"),

		OnClick = function(clickedFrame, button)
			Broker:OnClick(clickedFrame, button)
		end,
	}

	-- Define Tooltip Handlers based on LibQTip availability
	if LQT then
		dataObjectDef.OnEnter = function(anchorFrame)
			tooltip = CreateLibQTipTooltip(anchorFrame)
		end

		-- OnLeave signals to broker displays (Arcana, Bazooka, etc.) that we
		-- manage our own tooltip lifecycle. Without this, they apply a fallback hide
		-- timeout (typically 5 seconds). The actual hide logic is handled by
		-- SetupTooltipAutoHide's OnUpdate polling (0.25s after mouse leaves both
		-- the tooltip and the anchor frame).
		dataObjectDef.OnLeave = function() end
	else
		dataObjectDef.OnTooltipShow = function(gameTooltip)
			if gameTooltip and gameTooltip.AddLine then
				if BetterFriendlistDB.brokerTooltipMode == "advanced" then
					CreateAdvancedTooltip(gameTooltip)
				else
					CreateBasicTooltip(gameTooltip)
				end
			end
		end
	end

	dataObject = LDB:NewDataObject("BetterFriendlist", dataObjectDef)

	if dataObject then
		self:RegisterEvents()
		self:UpdateBrokerText()
	end
end

function Broker:RegisterEvents()
	-- BETA FEATURE CHECK: Only register events if Beta Features are enabled
	if not BetterFriendlistDB or not BetterFriendlistDB.enableBetaFeatures then
		return
	end

	if not BetterFriendlistDB.brokerEnabled then
		return
	end

	if not dataObject then
		return
	end

	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(...)
		Broker:UpdateBrokerText()
	end)

	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(...)
		Broker:UpdateBrokerText()
	end)

	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
		Broker:UpdateBrokerText()
	end)

	BFL:RegisterEventCallback("BN_CONNECTED", function(...)
		Broker:UpdateBrokerText()
	end)

	BFL:RegisterEventCallback("BN_DISCONNECTED", function(...)
		Broker:UpdateBrokerText()
	end)
end

-- ========================================
-- Slash Command Support
-- ========================================

function Broker:ToggleEnabled()
	if not BetterFriendlistDB then
		return
	end

	BetterFriendlistDB.brokerEnabled = not BetterFriendlistDB.brokerEnabled

	if BetterFriendlistDB.brokerEnabled then
		print("|cff00ff00BetterFriendlist:|r Data Broker |cff00ff00ENABLED|r - /reload to apply")
	else
		print("|cff00ff00BetterFriendlist:|r Data Broker |cffff0000DISABLED|r - /reload to apply")
	end
end

-- Export module
BFL.Broker = Broker
return Broker
