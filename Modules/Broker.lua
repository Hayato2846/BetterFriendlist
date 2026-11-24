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
local function GetDisplayLocation(friend)
	return BFL.GetWoWAccountLocation(friend.gameAccountInfo or friend, friend.realmName)
end
local function IsForeverFilter(id)
	return id == "forever" or id == "foreverruleset"
end

local function GetFriendsList()
	return BFL:GetModule("FriendsList")
end
local function GetGroups()
	return BFL:GetModule("Groups")
end
local function GetQuickFilters()
	return BFL:GetModule("QuickFilters")
end
local function GetFilterSortRegistry()
	return BFL:GetModule("FilterSortRegistry")
end

local function GetRosterComparator(settings)
	local registry = GetFilterSortRegistry()
	if not registry or not registry.CreateSortPlan or not registry.CompareFriendsWithSortPlan then return nil end
	local primary = settings and settings.primarySort or "status"
	local secondary = settings and settings.secondarySort or "name"
	local tertiary = settings and settings.enableTertiarySort == true and settings.tertiarySort
	local plan = registry:CreateSortPlan(primary, secondary, false, tertiary)
	return function(a, b)
		return registry:CompareFriendsWithSortPlan(a, b, plan)
	end
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
local pendingDeferredUpdate = false
local pendingTextUpdate = false
local pendingTooltipRefresh = false
local pendingTooltipBattleNetInvalidation = false
local friendCountsCache = nil
local FRIEND_COUNTS_CACHE_TTL = 2.0
local friendCountsEventVersion = 0
local bnetCountsCache = nil
-- Mobile filtering needs per-account Battle.net reads; keep it out of idle broker bursts.
local BNET_COUNTS_SNAPSHOT_TTL = 60.0
local bnetCountsHardInvalidated = true

-- LibQTip tooltip reference
local tooltip = nil
local tooltipKey = "BetterFriendlistBrokerTT"
-- Keep tooltip-only event callbacks out of the hidden broker path entirely.
local brokerTooltipEventGate = { active = false }
local filteredCountEventGate = { active = false }
local previewData = nil

-- Detail Tooltip reference (Forward declared for helper access)
local detailTooltip = nil

-- ========================================
-- Helper Functions
-- ========================================

-- Shared helpers from BrokerUtils (used by both Friends Broker and Guild Broker)
local GetStatusIcon = BFL.BrokerUtils.GetStatusIcon
local ClassColorText = BFL.BrokerUtils.ClassColorText
local GetFactionIcon = BFL.BrokerUtils.GetFactionIcon
local C = BFL.BrokerUtils.C
local AddTooltipSeparator = BFL.BrokerUtils.AddTooltipSeparator
local ApplyBrokerFooterSeparatorStyle = BFL.BrokerUtils.ApplyBrokerFooterSeparatorStyle

local function GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

local function GetTitleFriendCustomName(accountInfo)
	if
		not (
			accountInfo
			and BFL.IsTitleFriend
			and BFL.IsTitleFriend(accountInfo)
			and BFL.AreTitleFriendCustomNamesEnabled
			and BFL.AreTitleFriendCustomNamesEnabled()
			and BFL.GetCustomTitleFriendName
		)
	then
		return nil
	end

	local customName = BFL.GetCustomTitleFriendName(accountInfo.bnetAccountID)
	if customName and customName ~= "" and not BFL:IsSecret(customName) then
		return customName
	end
	return nil
end

local function InvalidateFriendCountsCache()
	friendCountsCache = nil
	friendCountsEventVersion = friendCountsEventVersion + 1
end

local function InvalidateBattleNetCountsCache()
	bnetCountsCache = nil
	bnetCountsHardInvalidated = true
end

local function CountBattleNetOnlineFriends(numTotal)
	local onlineCount = 0
	local nonMobileOnlineByAccountID = {}
	for i = 1, numTotal or 0 do
		if BNGetFriendInfo then
			local accountID, _, _, _, _, _, client, isOnline = BNGetFriendInfo(i)
			local isNonMobileOnline = isOnline and client ~= "BSAp" or false
			if accountID then
				nonMobileOnlineByAccountID[accountID] = isNonMobileOnline
			end
			if isNonMobileOnline then
				onlineCount = onlineCount + 1
			end
		else
			local accountInfo = BFL.GetBNetFriendInfo and BFL.GetBNetFriendInfo(i)
			local gameInfo = accountInfo and accountInfo.gameAccountInfo
			local client = gameInfo and gameInfo.clientProgram or "App"
			local isNonMobileOnline = accountInfo and gameInfo and gameInfo.isOnline and client ~= "BSAp" or false
			if accountInfo and accountInfo.bnetAccountID then
				nonMobileOnlineByAccountID[accountInfo.bnetAccountID] = isNonMobileOnline
			end
			if isNonMobileOnline then
				onlineCount = onlineCount + 1
			end
		end
	end
	return onlineCount, nonMobileOnlineByAccountID
end

local function ClampBattleNetOnlineCount(onlineCount, numOnline)
	onlineCount = onlineCount or 0
	numOnline = numOnline or 0
	if onlineCount > numOnline then
		return numOnline
	end
	if onlineCount < 0 then
		return 0
	end
	return onlineCount
end

local function RefreshBattleNetCountsSnapshot(numTotal, numOnline, now)
	local filteredOnline, nonMobileOnlineByAccountID = CountBattleNetOnlineFriends(numTotal)
	bnetCountsCache = {
		time = now,
		numTotal = numTotal,
		numOnline = numOnline,
		total = numTotal,
		online = filteredOnline,
		nonMobileOnlineByAccountID = nonMobileOnlineByAccountID,
	}
	bnetCountsHardInvalidated = false
	return numTotal, filteredOnline
end

local function GetBattleNetCounts(treatMobileAsOffline)
	if not BNConnected or not BNGetNumFriends then
		return 0, 0
	end

	if not (BNConnected() and (not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled())) then
		return 0, 0
	end

	local numTotal, numOnline = BNGetNumFriends()
	numTotal = numTotal or 0
	numOnline = numOnline or 0

	if not treatMobileAsOffline then
		return numTotal, numOnline
	end

	local now = GetTime and GetTime() or 0
	if numTotal == 0 or numOnline == 0 then
		bnetCountsCache = {
			time = now,
			numTotal = numTotal,
			numOnline = numOnline,
			total = numTotal,
			online = 0,
		}
		bnetCountsHardInvalidated = false
		return numTotal, 0
	end

	local cacheAge = bnetCountsCache and (now - (bnetCountsCache.time or 0)) or BNET_COUNTS_SNAPSHOT_TTL + 1
	if
		not bnetCountsCache
		or bnetCountsHardInvalidated
		or bnetCountsCache.numTotal ~= numTotal
		or cacheAge > BNET_COUNTS_SNAPSHOT_TTL
	then
		return RefreshBattleNetCountsSnapshot(numTotal, numOnline, now)
	end

	bnetCountsCache.numOnline = numOnline
	bnetCountsCache.total = numTotal
	return numTotal, ClampBattleNetOnlineCount(bnetCountsCache.online, numOnline)
end

-- Account online/offline events identify the changed account; companion-app
-- transitions are excluded by the callers below. Once the initial snapshot
-- exists, update the permanently visible non-mobile count in O(1) instead of
-- re-reading every Battle.net friend.
local function ApplyBattleNetAccountStatusEvent(friendID, isOnline)
	local states = bnetCountsCache and bnetCountsCache.nonMobileOnlineByAccountID
	if bnetCountsHardInvalidated or not states or not friendID or states[friendID] == nil then
		return false
	end

	local wasOnline = states[friendID] == true
	if wasOnline ~= isOnline then
		states[friendID] = isOnline
		bnetCountsCache.online = math.max(0, (bnetCountsCache.online or 0) + (isOnline and 1 or -1))
	end
	bnetCountsCache.time = GetTime and GetTime() or bnetCountsCache.time
	return true
end

-- Get class color for friend (returns color table or white fallback)
local function GetClassColorForFriend(friend)
	return BFL.ClassUtils:GetClassColorForFriend(friend)
end

local function GetClassIconForFriend(friend, size)
	local classFile = BFL.ClassUtils and BFL.ClassUtils:GetClassFileForFriend(friend)
	return BFL.BrokerUtils.GetClassIcon(classFile, size)
end

local function GetBrokerColumnColor(settingKey, settings)
	settings = settings or BetterFriendlistDB
	local color = settings and settings[settingKey]
	if not color then
		return nil
	end

	local r = color.r or color[1]
	local g = color.g or color[2]
	local b = color.b or color[3]
	if not r or not g or not b then
		return nil
	end

	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function ApplyBrokerColumnColor(text, settingKey, settings)
	if not text or text == "" then
		return text or ""
	end

	local color = GetBrokerColumnColor(settingKey, settings)
	if color then
		return color .. text .. "|r"
	end

	return text
end

local function CopyFriendTags(friendTags)
	if (BFL.IsSecret and BFL:IsSecret(friendTags)) or type(friendTags) ~= "table"
		or (type(issecrettable) == "function" and issecrettable(friendTags))
	then
		return nil
	end
	local copy = {}
	for _, tag in ipairs(friendTags) do
		if not (BFL.IsSecret and BFL:IsSecret(tag)) then copy[#copy + 1] = tag end
	end
	return copy
end

-- Helper: Add friend name to active chat editbox (Shift+Click)
local AddNameToEditBox = BFL.BrokerUtils.AddNameToEditBox

-- Helper: Smart invite - either invite to group or request to join their group
local function SmartInviteOrJoin(friendType, data)
	if not data then
		return
	end
	local identity = BFL.FriendActions.Capture(data)

	local playerInGroup = IsInGroup(LE_PARTY_CATEGORY_HOME)
	local isLeader = UnitIsGroupLeader("player") or not playerInGroup

	if friendType == "bnet" then
		-- BNet friend - must be in WoW
		if data.client ~= "WoW" or not data.gameAccountID then
			return
		end
		local friends = BFL:GetModule("FriendsList")
		local guid = friends and friends:GetReadableInviteField(data.gameAccountInfo, "playerGuid")
		local currentGameInfo = BFL.FriendActions.ResolveGameAccount(identity, data.gameAccountID, guid)
		if not currentGameInfo then return end
		if BFL.IsForever then
			if BFL:IsSecret(data.gameAccountID) then return end
			local allowed, reason
			allowed, reason, currentGameInfo = BFL.ValidateForeverInviteTarget(currentGameInfo)
			if not allowed or not currentGameInfo or currentGameInfo.gameAccountID ~= data.gameAccountID then return end
		end

		if isLeader then
			BFL.BNInviteFriend(data.gameAccountID)
		else
			local targetName = currentGameInfo and currentGameInfo.characterName or data.characterName
			if not BFL:IsSecret(targetName) and type(targetName) == "string" and targetName ~= "" then
				if BFL.AreRegionalUniqueNamesEnabled() then
					targetName = BFL.NormalizePlayerIdentityName(targetName)
				else
					local realmName = friends and friends:GetReadableInviteField(currentGameInfo, "realmName")
					targetName = BFL.NormalizePlayerIdentityName(targetName, realmName)
				end
				if targetName then BFL.RequestInviteFromUnit(targetName) end
			end
		end
	elseif friendType == "wow" then
		if not BFL.FriendActions.Resolve(identity) then return end
		if BFL.IsForever and BFL.GetForeverRulesetInviteRestriction(data.gameAccountInfo or data) then return end
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
contextMenuAnchor:EnableMouse(false)
contextMenuAnchor:SetFrameStrata("TOOLTIP")
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
	contextMenuAnchor:Show()

	BFL:OpenFriendMenuFallback(contextMenuAnchor, data, true)
end

-- Main click handler for friend lines in LibQTip tooltip
local function OnFriendLineClick(cell, data, mouseButton)
	if not data then
		return
	end

	-- LibQTip might not pass mouseButton - we need to get it ourselves!
	local actualButton = mouseButton or (cell and cell.bflLastMouseButton) or (GetMouseButtonClicked and GetMouseButtonClicked())

	if IsAltKeyDown() then
		SmartInviteOrJoin(data.type, data)
	elseif IsShiftKeyDown() then
		if data.characterName and (data.type == "wow" or (data.client == "WoW" and data.characterName ~= "")) then
			AddNameToEditBox(data.characterName, data.realmName)
		end
	else
		local friendMenu = BFL:GetModule("NativeFriendMenu")
		if actualButton == "RightButton" then
			OpenFriendContextMenu(data)
		elseif actualButton == "LeftButton" and friendMenu and not InCombatLockdown() then
			friendMenu:ShowWhisperUnavailable()
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

local function GetClientEmbeddedIcon(clientProgram, size, previewTexture, subIcon)
	if not clientProgram or clientProgram == "" then
		return ""
	end

	if previewTexture then
		size = size or 14
		return string.format("|T%s:%d:%d:0:0|t ", previewTexture, size, size)
	end

	if BFL.GetClientEmbeddedIcon then
		local icon = BFL:GetClientEmbeddedIcon(clientProgram, size or 14, subIcon)
		if icon and icon ~= "" then
			return icon
		end
	end

	if BNet_GetClientTexture then
		local texturePath = BNet_GetClientTexture(clientProgram)
		if texturePath then
			size = size or 14
			if BNet_GetClientEmbeddedTexture then
				return BNet_GetClientEmbeddedTexture(texturePath, size, size, 0) .. " "
			end
			return string.format("|T%s:%d:%d:0:0|t ", texturePath, size, size)
		end
	end

	return ""
end

local function GetFriendGameName(friend)
	if not friend then
		return ""
	end

	if friend.gameName and friend.gameName ~= "" then
		return friend.gameName
	end

	local gameInfo = friend.gameAccountInfo or (friend.accountInfo and friend.accountInfo.gameAccountInfo)
	local client = friend.client or (gameInfo and gameInfo.clientProgram)

	if friend.type == "wow" or client == (BNET_CLIENT_WOW or "WoW") then
		return WORLD_OF_WARCRAFT or "World of Warcraft"
	end

	if client == "BSAp" then
		return L("STATUS_MOBILE")
	end

	if client == "App" or client == "CLNT" then
		return L("STATUS_IN_APP")
	end

	if gameInfo and gameInfo.richPresence and gameInfo.richPresence ~= "" then
		return gameInfo.richPresence
	end

	return client or ""
end

local function GetFriendGameDisplay(friend, iconSize)
	local gameName = GetFriendGameName(friend)
	local gameInfo = friend and (friend.gameAccountInfo or (friend.accountInfo and friend.accountInfo.gameAccountInfo))
	local client = friend and (friend.client or (gameInfo and gameInfo.clientProgram))
	local previewTexture = friend
		and friend._isMock
		and (friend._previewTitleIcon or (gameInfo and gameInfo._previewTitleIcon))
		or nil
	local icon = GetClientEmbeddedIcon(client, iconSize or 14, previewTexture, gameInfo and gameInfo.subIcon)

	if icon ~= "" and gameName ~= "" then
		return icon .. gameName
	end
	return icon ~= "" and icon or gameName
end

local function ApplyGameAccountToFriend(friend, gameInfo)
	if not friend or not gameInfo then
		return
	end

	local client = gameInfo.clientProgram or "App"
	friend.client = client
	friend.isMobile = client == "BSAp"
	friend.wowProjectID = gameInfo.wowProjectID
	friend.timerunningSeasonID = gameInfo.timerunningSeasonID
	friend.gameAccountID = gameInfo.gameAccountID
	friend.gameAccountInfo = gameInfo
	friend.classFilename = gameInfo.classFilename

	if client == (BNET_CLIENT_WOW or "WoW") then
		friend.characterName = gameInfo.characterName or ""
		friend.level = gameInfo.characterLevel or 0
		friend.className = gameInfo.className or "UNKNOWN"
		friend.classID = gameInfo.classID
		local area, realm = BFL.Compat.GetBNetWoWAreaAndRealm(gameInfo)
		friend.area = area or ""
		friend.realmName = realm or ""
		friend.factionName = gameInfo.factionName or ""
		friend.guildName = gameInfo.guildName or ""
		friend.gameName = nil

	elseif client == "BSAp" then
		friend.characterName = ""
		friend.level = 0
		friend.className = "UNKNOWN"
		friend.classID = nil
		friend.area = ""
		friend.realmName = ""
		friend.factionName = ""
		friend.guildName = ""
		friend.gameName = L("STATUS_MOBILE")
	elseif client == "App" or client == "CLNT" then
		friend.characterName = ""
		friend.level = 0
		friend.className = "UNKNOWN"
		friend.classID = nil
		friend.area = ""
		friend.realmName = ""
		friend.factionName = ""
		friend.guildName = ""
		friend.gameName = L("STATUS_IN_APP")
	else
		friend.characterName = ""
		friend.level = 0
		friend.className = "UNKNOWN"
		friend.classID = nil
		friend.area = ""
		friend.realmName = ""
		friend.factionName = ""
		friend.guildName = ""
		local richPresence = gameInfo.richPresence
		friend.gameName = (richPresence and richPresence ~= "") and richPresence
			or (gameInfo.clientProgram or L("UNKNOWN_GAME"))
	end
end

local function GetPreviewFriendGameInfo(friend)
	return friend and (friend.gameAccountInfo or (friend.accountInfo and friend.accountInfo.gameAccountInfo))
end

local function GetPreviewFriendClient(friend)
	local gameInfo = GetPreviewFriendGameInfo(friend)
	return (friend and friend.client) or (gameInfo and gameInfo.clientProgram) or ""
end

local function IsPreviewFriendOnline(friend, treatMobileAsOffline)
	if not friend then
		return false
	end
	if BetterFriendlistDB and IsForeverFilter(BetterFriendlistDB.quickFilter) then
		local registry = GetFilterSortRegistry()
		if registry and registry.EvaluateQuickFilter and registry.NormalizeQuickFilterId
			and registry:NormalizeQuickFilterId("forever") == "forever"
		then
			return registry:EvaluateQuickFilter("forever", friend)
		end
	end

	local client = GetPreviewFriendClient(friend)
	if treatMobileAsOffline and client == "BSAp" then
		return false
	end

	if friend.connected ~= nil then
		return friend.connected and true or false
	end

	local gameInfo = GetPreviewFriendGameInfo(friend)
	return gameInfo and gameInfo.isOnline or false
end

local function PreviewFriendPassesFilter(friend, currentFilter, isOnline)
	local client = GetPreviewFriendClient(friend)
	local wowClient = BNET_CLIENT_WOW or "WoW"

	if currentFilter == "all" or currentFilter == "online" then
		return isOnline
	elseif currentFilter == "offline" then
		return not isOnline
	elseif currentFilter == "wowonline" then
		return isOnline and (friend.type == "wow" or client == wowClient)
	elseif currentFilter == "wow" then
		return isOnline and (friend.type == "wow" or client == wowClient)
	elseif currentFilter == "bnet" then
		return isOnline and friend.type == "bnet" and client ~= wowClient
	elseif currentFilter == "hideafk" then
		return isOnline and not (friend.isAFK or friend.isDND)
	elseif currentFilter == "retail" then
		if not isOnline or not (friend.type == "wow" or client == wowClient) then
			return false
		end
		return not friend.wowProjectID or friend.wowProjectID == (WOW_PROJECT_MAINLINE or WOW_PROJECT_ID)
	elseif currentFilter == "ingame" then
		if friend.type == "wow" then
			return isOnline
		end
		return isOnline and client ~= "" and client ~= "App" and client ~= "BSAp"
	end

	local Registry = GetFilterSortRegistry()
	if Registry and Registry.EvaluateQuickFilter then
		return Registry:EvaluateQuickFilter(currentFilter, friend)
	end

	return isOnline
end

local function GetPreviewFriendCounts(currentFilter, friends)
	local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline
	local wowFiltered, wowTotal = 0, 0
	local bnetFiltered, bnetTotal = 0, 0

	for _, friend in ipairs(friends or (previewData and previewData.friends) or {}) do
		local isOnline = IsPreviewFriendOnline(friend, treatMobileAsOffline)
		local passes = PreviewFriendPassesFilter(friend, currentFilter or "all", isOnline)

		if friend.type == "wow" then
			wowTotal = wowTotal + 1
			if passes then
				wowFiltered = wowFiltered + 1
			end
		else
			bnetTotal = bnetTotal + 1
			if passes then
				bnetFiltered = bnetFiltered + 1
			end
		end
	end

	return wowFiltered, wowTotal, bnetFiltered, bnetTotal
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
	wowTotal = (BFL.GetNumWoWFriends and BFL.GetNumWoWFriends() or 0)
	wowOnline = (BFL.GetNumOnlineWoWFriends and BFL.GetNumOnlineWoWFriends() or 0)

	-- BNet Friends
	bnetTotal, bnetOnline = GetBattleNetCounts(treatMobileAsOffline)

	return wowOnline, wowTotal, bnetOnline, bnetTotal
end

-- Get filtered friend counts based on the active QuickFilter
-- Returns wowFiltered, wowTotal, bnetFiltered, bnetTotal
-- The first value is the number to display as "online/current"; never report
-- total friends as online just because the active filter is "All".
local function BuildFriendCountsCacheSignature(currentFilter)
	return table.concat({
		currentFilter or "all",
		BFL.FriendsListVersion or 0,
		BFL.FilterSortRegistryVersion or 0,
		BFL.FriendTagsVersion or 0,
		BFL.FriendTagsAssignmentVersion or 0,
		Broker.tagSearch or "",
		BFL.SettingsVersion or 0,
		BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline and 1 or 0,
		friendCountsEventVersion or 0,
		tostring(previewData or ""),
	}, "|")
end

local function GetBNetFilterGameAccounts(friendIndex)
	local countAPI = (C_BattleNet and C_BattleNet.GetFriendNumGameAccounts) or BNGetNumFriendGameAccounts
	if type(countAPI) ~= "function" or not BFL.GetBNetFriendGameAccountInfo then
		return nil
	end
	local ok, count = pcall(countAPI, friendIndex)
	if not ok or (BFL.IsSecret and BFL:IsSecret(count))
		or type(count) ~= "number" or count < 0 or count % 1 ~= 0
	then
		return nil
	end
	local accounts = {}
	for accountIndex = 1, count do
		local infoOK, info = pcall(BFL.GetBNetFriendGameAccountInfo, friendIndex, accountIndex)
		if infoOK and type(info) == "table" then accounts[#accounts + 1] = info end
	end
	return accounts
end

local function NormalizeTagSearch(value)
	local intl = BFL.IntlCompat
	return intl and intl.NormalizeForSearch and intl.NormalizeForSearch(value) or BFL:StripAccents(value)
end

local function GetBrokerTagFilter()
	local quickFilters = GetQuickFilters()
	local tags = BFL:GetModule("FriendTags")
	local query = Broker.tagSearch and tags and tags:CanDisplayTags("broker") and Broker.tagSearch or nil
	local selected = quickFilters and quickFilters.GetActiveTagFilterDefinitions
		and #quickFilters:GetActiveTagFilterDefinitions() > 0
	if not query and not selected then return nil end
	local normalized = query and NormalizeTagSearch(query)
	return function(friend)
		if selected and not quickFilters:PassesTagFilters(friend) then return false end
		if not normalized then return true end
		local text = tags:GetSearchText(friend)
		return text ~= nil and NormalizeTagSearch(text):find(normalized, 1, true) ~= nil
	end
end

local function GetFilteredFriendCounts()
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	local Registry = GetFilterSortRegistry()
	if Registry and Registry.NormalizeQuickFilterId then
		currentFilter = Registry:NormalizeQuickFilterId(currentFilter)
	end
	local cacheSignature = BuildFriendCountsCacheSignature(currentFilter)
	local now = GetTime and GetTime() or 0
	if
		friendCountsCache
		and friendCountsCache.signature == cacheSignature
		and now - (friendCountsCache.time or 0) <= FRIEND_COUNTS_CACHE_TTL
	then
		return friendCountsCache.wowOnline,
			friendCountsCache.wowTotal,
			friendCountsCache.bnetOnline,
			friendCountsCache.bnetTotal
	end

	local resolvedFilter = Registry and Registry.ResolveQuickFilter and Registry:ResolveQuickFilter(currentFilter, true)
	local foreverFilter = IsForeverFilter(currentFilter)
	local useRegistryFilter = resolvedFilter and (resolvedFilter.isCustom or foreverFilter)
	local tagFilter = GetBrokerTagFilter()
	local useSimpleCounts = not useRegistryFilter and not tagFilter and (currentFilter == "all" or currentFilter == "online")
	filteredCountEventGate.active = not useSimpleCounts and not previewData

	local wowFiltered, wowTotal, bnetFiltered, bnetTotal
	if previewData and previewData.friends then
		wowFiltered, wowTotal, bnetFiltered, bnetTotal = GetPreviewFriendCounts(currentFilter)
	elseif useSimpleCounts then
		wowFiltered, wowTotal, bnetFiltered, bnetTotal = GetFriendCounts()
	else
		local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline
		local BNET_CLIENT_WOW_LOCAL = BNET_CLIENT_WOW or "WoW"

		wowFiltered, wowTotal = 0, 0
		bnetFiltered, bnetTotal = 0, 0

		-- WoW Friends
		local numWoWFriends = (BFL.GetNumWoWFriends and BFL.GetNumWoWFriends() or 0)
		wowTotal = numWoWFriends
		for i = 1, numWoWFriends do
			local friendInfo = BFL.GetWoWFriendInfoByIndex(i)
			if friendInfo then
				local connected = friendInfo.connected
				local passes = false
				local friendForRegistry

				if useRegistryFilter or tagFilter then
					friendForRegistry = {
						type = "wow",
						index = i,
						name = friendInfo.name,
						characterName = friendInfo.name,
						connected = connected,
						level = friendInfo.level,
						className = friendInfo.className,
						area = friendInfo.area,
						realmName = friendInfo.name and select(2, BFL.SplitPlayerName(friendInfo.name)),
						note = friendInfo.notes,
						notes = friendInfo.notes,
						afk = friendInfo.afk,
						dnd = friendInfo.dnd,
					}
				end
				if useRegistryFilter then
					passes = Registry:EvaluateQuickFilter(currentFilter, friendForRegistry)
				elseif currentFilter == "all" or currentFilter == "online" then
					passes = connected
				elseif currentFilter == "offline" then
					passes = not connected
				elseif currentFilter == "wowonline" then
					passes = connected
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

				if passes and (not tagFilter or tagFilter(friendForRegistry)) then
					wowFiltered = wowFiltered + 1
				end
			end
		end

		-- BNet Friends
		if BNConnected() and (not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled()) then
			local numBNetTotal, numBNetOnline = BNGetNumFriends()
			bnetTotal = numBNetTotal or 0
			local nativeTags = tagFilter and BFL.AreBattleNetFriendTagsEnabled and BFL.AreBattleNetFriendTagsEnabled()

			for i = 1, bnetTotal do
				local accountInfo = BFL.GetBNetFriendInfo and BFL.GetBNetFriendInfo(i)
				if accountInfo then
					local gameInfo = accountInfo.gameAccountInfo or {}
					local isOnline = gameInfo.isOnline or false
					local client = gameInfo.clientProgram or "App"
					local isMobile = (client == "BSAp")

					if treatMobileAsOffline and isMobile then
						isOnline = false
					end

					local passes = false
					local friendForRegistry

					if useRegistryFilter or tagFilter then
						friendForRegistry = {
							type = "bnet",
							index = i,
							bnetAccountID = accountInfo.bnetAccountID,
							accountName = accountInfo.accountName,
							titleCustomName = GetTitleFriendCustomName(accountInfo),
							battleTag = accountInfo.battleTag,
							connected = isOnline,
							isAFK = accountInfo.isAFK,
							isDND = accountInfo.isDND,
							note = BFL.FriendNotes.GetBNetDisplayNote(accountInfo),
							customMessage = accountInfo.customMessage,
							gameAccountInfo = gameInfo,
							characterName = gameInfo.characterName,
							level = gameInfo.characterLevel,
							className = gameInfo.className,
							areaName = gameInfo.areaName,
							realmName = gameInfo.realmName,
							factionName = gameInfo.factionName,
							gameName = gameInfo.richPresence,
							numGameAccounts = accountInfo.numGameAccounts,
							friendTags = nativeTags and CopyFriendTags(accountInfo.friendTags) or nil,
						}
						if foreverFilter then
							friendForRegistry.gameAccounts = GetBNetFilterGameAccounts(i)
						end
					end
					if useRegistryFilter then
						passes = Registry:EvaluateQuickFilter(currentFilter, friendForRegistry)
					elseif currentFilter == "all" or currentFilter == "online" then
						passes = isOnline
					elseif currentFilter == "offline" then
						passes = not isOnline
					elseif currentFilter == "wowonline" then
						passes = isOnline and (client == BNET_CLIENT_WOW_LOCAL)
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

					if passes and (not tagFilter or tagFilter(friendForRegistry)) then
						bnetFiltered = bnetFiltered + 1
					end
				end
			end
		end
	end

	friendCountsCache = {
		signature = cacheSignature,
		time = now,
		wowOnline = wowFiltered,
		wowTotal = wowTotal,
		bnetOnline = bnetFiltered,
		bnetTotal = bnetTotal,
	}
	return wowFiltered, wowTotal, bnetFiltered, bnetTotal
end

-- ========================================
-- Broker Text Update
-- ========================================

local function FormatBrokerDisplay(wowOnline, wowTotal, bnetOnline, bnetTotal, settings)
	settings = settings or BetterFriendlistDB
	local totalOnline = wowOnline + bnetOnline
	local totalFriends = wowTotal + bnetTotal

	-- Format text based on config
	local text
	local showLabel = settings.brokerShowLabel ~= false -- Default true
	local showTotal = settings.brokerShowTotal ~= false -- Default true

	if settings.brokerShowGroups then
		local wowText = showTotal and string.format("%d/%d", wowOnline, wowTotal) or tostring(wowOnline)
		local bnetText = showTotal and string.format("%d/%d", bnetOnline, bnetTotal) or tostring(bnetOnline)

		local wowIcon = "|T939375:16:16:0:0:64:64:5:59:5:59|t"
		local bnetIcon = "|TInterface\\AddOns\\BetterFriendlist\\Icons\\filter-all:16:16:0:0|t"

		local showWoWIcon = settings.brokerShowWoWIcon ~= false
		local showBNetIcon = settings.brokerShowBNetIcon ~= false

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

	local showIcon = settings.brokerShowIcon ~= false -- Default true
	return text, showIcon and "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp" or nil
end

function Broker:RenderSettingsDisplaySample(settings)
	return FormatBrokerDisplay(2, 5, 3, 8, settings)
end

function Broker:UpdateBrokerText(force)
	if not dataObject then
		return
	end

	local currentTime = GetTime()
	if not force and currentTime - lastUpdateTime < THROTTLE_INTERVAL then
		return
	end
	lastUpdateTime = currentTime

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		return
	end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	dataObject.text, dataObject.icon = FormatBrokerDisplay(wowOnline, wowTotal, bnetOnline, bnetTotal)
end

function Broker:ScheduleBrokerTextUpdate(invalidateBattleNet)
	if not dataObject then return end
	-- Invalidate before the deferred pass so the label and an open tooltip can share the next result.
	InvalidateFriendCountsCache()
	pendingTextUpdate = true

	if pendingDeferredUpdate then
		if invalidateBattleNet then
			InvalidateBattleNetCountsCache()
		end
		return
	end

	if invalidateBattleNet then
		InvalidateBattleNetCountsCache()
	end

	pendingDeferredUpdate = true
	local function FlushBrokerTextUpdate()
		pendingDeferredUpdate = false
		if not pendingTextUpdate then
			return
		end
		pendingTextUpdate = false
		Broker:UpdateBrokerText(true)
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(0.25, FlushBrokerTextUpdate)
	else
		FlushBrokerTextUpdate()
	end
end

local function IsBrokerTooltipObserved()
	if not (LQT and tooltip and tooltip.IsShown and tooltip:IsShown()) then
		return false
	end

	if tooltip.IsMouseOver and tooltip:IsMouseOver() then
		return true
	end
	if tooltip.bflBrokerFilterOpen and BFL.BrokerUtils.IsMenuOpen() then return true end

	local anchor = tooltip.anchorFrame
	return anchor and anchor.IsMouseOver and anchor:IsMouseOver() or false
end

-- Presence/details are only observable while the broker tooltip is hovered.
-- Coalesce its noisy Battle.net events and do no cache work at all otherwise.
function Broker:ScheduleObservedTooltipRefresh(invalidateBattleNet)
	if not IsBrokerTooltipObserved() then
		return
	end

	InvalidateFriendCountsCache()
	pendingTooltipBattleNetInvalidation = pendingTooltipBattleNetInvalidation or invalidateBattleNet
	if pendingTooltipRefresh then
		return
	end

	pendingTooltipRefresh = true
	local function FlushObservedTooltipRefresh()
		pendingTooltipRefresh = false
		if not IsBrokerTooltipObserved() then
			pendingTooltipBattleNetInvalidation = false
			return
		end

		if pendingTooltipBattleNetInvalidation then
			InvalidateBattleNetCountsCache()
			if not filteredCountEventGate.active then InvalidateFriendCountsCache() end
		end
		pendingTooltipBattleNetInvalidation = false
		Broker:RefreshTooltip()
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(0.25, FlushObservedTooltipRefresh)
	else
		FlushObservedTooltipRefresh()
	end
end

-- ========================================
-- Tooltip Functions (GameTooltip fallback)
-- ========================================

-- Basic Tooltip
local function CreateBasicTooltip(gameTooltip, sample)
	gameTooltip:AddLine(L("BROKER_TITLE"), GetAccentColor(1, 0.82, 0, 1))
	gameTooltip:AddLine(" ")

	local wowOnline, wowTotal, bnetOnline, bnetTotal
	if sample then
		wowOnline, wowTotal, bnetOnline, bnetTotal = GetPreviewFriendCounts("all", sample.friends)
	else
		wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	end

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

	local QuickFilters = not sample and GetQuickFilters()
	local settings = sample and sample.settings or BetterFriendlistDB
	local currentFilter = sample and L("FILTER_ALL_FRIENDS") or settings and settings.quickFilter or "all"
	if QuickFilters then
		local filterText = QuickFilters:GetFilterText()
		if filterText then
			currentFilter = filterText
		end
	end
	gameTooltip:AddDoubleLine(L("BROKER_CURRENT_FILTER"), currentFilter, 1, 1, 1, 1, 1, 0)

	if settings and settings.brokerShowHints ~= false then
		gameTooltip:AddLine(" ")
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
		gameTooltip:AddLine(L("BROKER_HINT_CYCLE_FILTER_FULL"), 0.5, 0.9, 1, 1)
	end
end

-- Advanced Tooltip with Groups and Activity
local function CreateAdvancedTooltip(gameTooltip)
	gameTooltip:AddLine(L("BROKER_TITLE"), GetAccentColor(1, 0.82, 0, 1))
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

	if BNConnected() and (not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled()) then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		local friendTagsEnabled = BFL.AreBattleNetFriendTagsEnabled and BFL.AreBattleNetFriendTagsEnabled()
		for i = 1, numBNetOnline do
			local accountInfo = BFL.GetBNetFriendInfo and BFL.GetBNetFriendInfo(i)
			if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				local friendUID = (accountInfo.battleTag and accountInfo.battleTag ~= "")
						and ("bnet_" .. accountInfo.battleTag)
					or ("bnet_" .. tostring(accountInfo.bnetAccountID))
				local gameInfo = accountInfo.gameAccountInfo
				local name = BFL:GetSafeAccountName(accountInfo.accountName, accountInfo.battleTag)
				table.insert(friends, {
					id = friendUID,
					type = "bnet",
					index = i,
					gameAccountInfo = gameInfo,
					realmName = gameInfo.realmName,
					name = name,
					isFavorite = accountInfo.isFavorite,
					friendLevel = accountInfo.friendLevel,
					friendTags = friendTagsEnabled and CopyFriendTags(accountInfo.friendTags) or nil,
					client = gameInfo.clientProgram or "App",
					wowProjectID = gameInfo.wowProjectID,
					connected = true,
					info = {
						name = name,
						level = gameInfo.characterLevel or "??",
						className = gameInfo.className or "UNKNOWN",
						area = gameInfo.areaName or "Unknown",
					},
				})
			end
		end
	end

	local numWoWFriends = (BFL.GetNumWoWFriends and BFL.GetNumWoWFriends() or 0)
	for i = 1, numWoWFriends do
		local friendInfo = BFL.GetWoWFriendInfoByIndex(i)
		if friendInfo and friendInfo.connected then
			local fullName = friendInfo.name or ""
			local normalizedName = BFL:NormalizeWoWFriendName(fullName)
			local friendUID = normalizedName and ("wow_" .. normalizedName) or ("wow_" .. fullName)
			table.insert(friends, {
				id = friendUID,
				type = "wow",
				index = i,
				name = fullName,
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
			local customGroups = DB and friend.id and DB:GetFriendGroups(friend.id) or {}
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
				if groupsData[groupId] and not groupsData[groupId].builtin then
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

	local compareFriends = GetRosterComparator(BetterFriendlistDB)
	if compareFriends then
		for _, groupFriends in pairs(groupedFriends) do table.sort(groupFriends, compareFriends) end
		table.sort(ungrouped, compareFriends)
	end

	local displayedCount = 0
	local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds() or {}

	for _, groupId in ipairs(sortedGroupIds) do
		local groupFriends = groupedFriends[groupId]
		if groupFriends and #groupFriends > 0 then
			local groupInfo = groupsData[groupId]
			if groupInfo then
				gameTooltip:AddLine(groupInfo.name, GetAccentColor(1, 0.82, 0, 1))

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
local function GetBrokerNickname(friend)
	if friend.settingsSample then
		return friend.sampleNickname or ""
	end
	local DB = GetDB()
	return DB and DB:GetNickname(friend.id) or ""
end

local function GetFriendDisplayName(friend)
	local isStreamerMode = BFL.StreamerMode and BFL.StreamerMode:IsActive()

	local DB = GetDB()
	local format = DB and DB:GetNameFormatString() or "%name%"

	-- 1. Prepare Data
	local name = "Unknown"
	local battletag = friend.battleTag or ""
	local note = friend.note or ""
	local nickname = GetBrokerNickname(friend)
	local characterName = ""
	local realmName, locationKind = GetDisplayLocation(friend)

	if friend.type == "bnet" then
		characterName = friend.characterName
		if not BFL:IsSecret(characterName) and characterName == nil then characterName = friend.toonName end
		if BFL:IsSecret(characterName) or type(characterName) ~= "string" then characterName = "" end

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
			local alias = friend.titleCustomName
			if BFL:IsSecret(alias) or type(alias) ~= "string" or alias == "" then alias = nil end
			name = alias or BFL:GetSafeAccountName(friend.accountName, friend.battleTag)
			if characterName ~= "" and BFL.IsTitleFriend(friend) then
				format = BFL.GetTitleFriendNameFormat(format, characterName, alias, nickname, battletag)
			end
		end
	else
		local fullName = friend.fullName or friend.name or "Unknown"
		local showRealmName = DB and DB:Get("showRealmName", false)

		-- Extract character and realm from fullName
		local n, r = BFL.SplitPlayerName(fullName)
		characterName = n or fullName
		if locationKind ~= "ruleset" then realmName = r or "" end

		if BFL.AreRegionalUniqueNamesEnabled() then
			name = fullName
		elseif showRealmName then
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
			classColorStr = BFL.ClassUtils:GetClassColorHex(friend)
		end
	end

	-- Decorate character name (faction icon, timerunning) before token replacement
	local decoratedChar = characterName
	if decoratedChar ~= "" then
		if not BFL:IsSecret(friend.timerunningSeasonID)
			and friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon
		then
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
	result = ReplaceTokenCaseInsensitive(result, "ruleset", locationKind == "ruleset" and realmName or "")
	-- Phase 22b: Unified tokens - info tokens in name format
	result = ReplaceTokenCaseInsensitive(result, "level", friend.level and tostring(friend.level) or "")
	result = ReplaceTokenCaseInsensitive(result, "zone", friend.areaName or friend.area or "")
	result = ReplaceTokenCaseInsensitive(result, "class", friend.className or "")
	result = ReplaceTokenCaseInsensitive(result, "game", GetFriendGameName(friend))
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

	return BFL.BrokerUtils.ColorLevelByDifficulty(level)
end

-- ========================================
-- Fixed Footer Implementation
-- ========================================
local FOOTER_HEIGHT = 160 -- Height for the fixed footer area (with hints)
local FOOTER_HEIGHT_NO_HINTS = 65 -- Height for the fixed footer area (without hints)
local MAX_TOOLTIP_HEIGHT = 690 -- Maximum height for the tooltip before scrolling

local function GetFooterHeight(settings)
	settings = settings or BetterFriendlistDB
	local showHints = settings and settings.brokerShowHints ~= false
	return showHints and FOOTER_HEIGHT or FOOTER_HEIGHT_NO_HINTS
end

local function FormatBrokerClickHint()
	return C("ltblue", L("BROKER_HINT_LEFT_CLICK")) .. L("BROKER_HINT_TOGGLE")
end

local function ShowBrokerTagSearch()
	local key = "BFL_BROKER_TAG_SEARCH"
	if not StaticPopupDialogs[key] then
		local function Apply(text)
			text = text:match("^%s*(.-)%s*$")
			Broker.tagSearch = text ~= "" and text or nil
			Broker:ScheduleBrokerTextUpdate()
			Broker:ScheduleObservedTooltipRefresh()
		end
		StaticPopupDialogs[key] = {
			text = L("BROKER_TAG_SEARCH"), button1 = ACCEPT, button2 = CANCEL, hasEditBox = true,
			OnShow = function(frame)
				local editBox = frame.EditBox or frame.editBox
				editBox:SetMaxLetters(64)
				editBox:SetText(Broker.tagSearch or "")
				editBox:SetFocus()
				editBox:HighlightText()
			end,
			OnAccept = function(frame) Apply((frame.EditBox or frame.editBox):GetText()) end,
			EditBoxOnEnterPressed = function(editBox)
				Apply(editBox:GetText())
				editBox:GetParent():Hide()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true,
		}
	end
	StaticPopup_Show(key)
end

local function RenderFixedFooter(footerFrame, sampleFriends, settings)
	settings = settings or BetterFriendlistDB
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
	end
	footerFrame.content = footerFrame.content or {}
	local index = 0
	local contentWidth = 0

	local function NextRegion(create)
		index = index + 1
		local region = footerFrame.content[index]
		if not region then
			region = create()
			footerFrame.content[index] = region
		end
		region:Show()
		return region
	end

	local function AddLine(text, font, r, g, b)
		local fs = NextRegion(function()
			return footerFrame:CreateFontString(nil, "OVERLAY", font or "GameTooltipTextSmall")
		end)
		BFL.BrokerUtils.ApplyBrokerFontToFontString(fs, font == "GameTooltipText" and 0 or -2, settings)
		fs:SetText(text)
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false)
		local width = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
		contentWidth = math.max(contentWidth, width)
		if r then
			fs:SetTextColor(r, g, b)
		end
		return fs
	end

	local function AddSeparator()
		local tex = NextRegion(function()
			return footerFrame:CreateTexture(nil, "ARTWORK")
		end)
		ApplyBrokerFooterSeparatorStyle(tex, settings)
		return tex
	end

	local yOffset = -5

	-- Separator
	local sep1 = AddSeparator()
	sep1:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sep1:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
	yOffset = yOffset - 5

	-- Total Online (filtered to match LDB text)
	local wowOnline, wowTotal, bnetOnline, bnetTotal
	if sampleFriends then
		wowOnline, wowTotal, bnetOnline, bnetTotal = GetPreviewFriendCounts(settings.quickFilter, sampleFriends)
	else
		wowOnline, wowTotal, bnetOnline, bnetTotal = GetFilteredFriendCounts()
	end
	local totalText = settings.quickFilter == "offline"
		and string.format("%s · %d / %d", L("FILTER_OFFLINE"), wowOnline + bnetOnline, wowTotal + bnetTotal)
		or string.format(L("BROKER_TOTAL_ONLINE"), wowOnline + bnetOnline, wowTotal + bnetTotal)
	local totalLine = AddLine(totalText, "GameTooltipText", 1, 1, 1)
	totalLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	totalLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 16

	-- Filter
	local currentFilter = settings and settings.quickFilter or "all"
	local QuickFilters = not sampleFriends and GetQuickFilters()
	local tags = not sampleFriends and BFL:GetModule("FriendTags")
	local tagsVisible = tags and tags:CanDisplayTags("broker")
	local filterText = L("FILTER_ALL")
	local filterIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all"
	local Registry = GetFilterSortRegistry()

	if QuickFilters then
		currentFilter = QuickFilters:GetFilter()
		filterText = QuickFilters:GetFilterText() or filterText
		local icons = QuickFilters:GetIcons()
		if icons and icons[currentFilter] then
			filterIcon = icons[currentFilter]
		end
	elseif sampleFriends and Registry then
		filterText = Registry:GetQuickFilterText(currentFilter) or filterText
		filterIcon = Registry:GetQuickFilterIcon(currentFilter) or filterIcon
	end
	if tagsVisible and Broker.tagSearch then
		filterText = filterText .. " · " .. Broker.tagSearch:gsub("|", "||")
	end

	local filterIconText = Registry and Registry:FormatIcon(filterIcon, 16) or string.format("|T%s:16:16:0:0|t", filterIcon)
	local filterDisplay = filterIconText .. " " .. C("ltyellow", filterText)
	local filterLine = AddLine(L("BROKER_FILTER_LABEL") .. filterDisplay, "GameTooltipText")
	filterLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	filterLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	local filterButton = footerFrame.tagFilterButton
	if tagsVisible and QuickFilters and BFL.CreateContextMenu then
		if not filterButton then
			filterButton = CreateFrame("Button", nil, footerFrame)
			filterButton:RegisterForClicks("LeftButtonUp")
			footerFrame.tagFilterButton = filterButton
		end
		filterButton:ClearAllPoints()
		filterButton:SetAllPoints(filterLine)
		filterButton:SetScript("OnEnter", function() filterLine:SetAlpha(0.8) end)
		filterButton:SetScript("OnLeave", function() filterLine:SetAlpha(1) end)
		filterButton:SetScript("OnClick", function(button)
			BFL.CreateContextMenu(button, function(_, root)
				QuickFilters:PopulateMenu(root)
				root:CreateButton(L("BROKER_TAG_SEARCH"), ShowBrokerTagSearch)
				root:CreateButton(L("FRIEND_TAGS_EDITOR_TITLE"), function() tags:OpenSettings() end)
			end)
			footerFrame:GetParent().bflBrokerFilterOpen = true
		end)
		filterLine:SetAlpha(1)
		filterButton:Show()
	elseif filterButton then
		filterButton:Hide()
	end
	yOffset = yOffset - 18

	-- Sort
	local primarySort = settings and settings.primarySort or "status"
	local secondarySort = settings and settings.secondarySort or "name"
	local function GetSortDisplay(mode)
		if Registry then
			local name = Registry:GetSorterText(mode)
			local icon = Registry:GetSorterIcon(mode)
			return Registry:FormatIcon(icon, 14) .. " " .. name
		end
		return mode
	end

	local sortText = GetSortDisplay(primarySort)
	if secondarySort and secondarySort ~= primarySort and secondarySort ~= "none" then
		sortText = sortText .. " > " .. GetSortDisplay(secondarySort)
	end

	if Registry and settings and settings.enableTertiarySort == true then
		local tertiarySort = Registry:NormalizeTertiarySorterId(settings.tertiarySort, primarySort, secondarySort)
		if tertiarySort ~= "none" then
			sortText = sortText .. " > " .. GetSortDisplay(tertiarySort)
		end
	end

	local sortLine = AddLine(L("BROKER_SORT_LABEL") .. C("ltyellow", sortText), "GameTooltipText")
	sortLine:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sortLine:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 18

	-- Hints (conditionally shown based on brokerShowHints setting)
	local showHints = settings and settings.brokerShowHints ~= false
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

		local hint5 = AddLine(FormatBrokerClickHint(), "GameTooltipTextSmall")
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
	return math.ceil(contentWidth) + 20
end

-- Helper: Check if any context menu is open
local IsMenuOpen = BFL.BrokerUtils.IsMenuOpen

-- Wrapper: SetupTooltipAutoHide with module-specific upvalues (detailTooltip, LQT)
local function SetupTooltipAutoHide(tt, anchorFrame)
	BFL.BrokerUtils.SetupTooltipAutoHide(tt, anchorFrame, LQT, function() return detailTooltip end, function()
		if not tt.bflBrokerFilterOpen then return false end
		if BFL.BrokerUtils.IsMenuOpen() then return true end
		tt.bflBrokerFilterOpen = nil
		if tt.bflBrokerFilterDirty then
			tt.bflBrokerFilterDirty = nil
			Broker:ScheduleObservedTooltipRefresh()
		end
		return false
	end)
end

local CreateDetailTooltip
local ReleaseDetailTooltip

-- ========================================
-- ElvUI Tooltip Skin Helpers (delegate to BrokerUtils)
-- ========================================
local ApplyElvUISkin = BFL.BrokerUtils.ApplyElvUISkin
local RemoveElvUISkin = BFL.BrokerUtils.RemoveElvUISkin

local function TooltipCleanup(tt)
	if not tt then return end
	tt.bflBrokerFilterOpen, tt.bflBrokerFilterDirty = nil, nil

	ReleaseDetailTooltip()
	RemoveElvUISkin(tt)
	BFL.BrokerUtils.ClearActiveBrokerTooltip(tt)
	if tooltip == tt then
		tooltip = nil
		brokerTooltipEventGate.active = false
	end
	BFL.BrokerUtils.ScheduleBrokerTooltipRelease(LQT, tt)
	BFL.BrokerUtils.RestoreBrokerTooltipLayout(tt)
end

local RenderBasicQTipTooltip

local function BindLiveTooltipCleanup(tt)
	-- QTip calls OnHide first when releasing a tooltip.
	local previousOnHide = tt:GetScript("OnHide")
	tt:SetScript("OnHide", function(self)
		TooltipCleanup(self)
		if previousOnHide then pcall(previousOnHide, self) end
	end)
end

local function AnchorLiveTooltip(tt, anchorFrame)
	tt:SmartAnchorTo(anchorFrame)
	tt.anchorFrame = anchorFrame
	SetupTooltipAutoHide(tt, anchorFrame)
	tt:SetFrameStrata("HIGH")
end

local function ActivateLiveTooltip(tt)
	BFL.BrokerUtils.SetActiveBrokerTooltip(tt, LQT, function() return detailTooltip end)
	brokerTooltipEventGate.active = true
end

local tagCellProvider
local function SetBrokerTagCell(row, index, lineTags, comparison, columns, tagSettings)
	local chips = BFL:GetModule("TagChips")
	if not chips or not LQT.CreateCellProvider or #lineTags == 0 then return end
	if not tagCellProvider then
		local provider = LQT:CreateCellProvider()
		local cell, base = provider.newCellPrototype, provider.baseCellPrototype
		function cell:GetSize()
			if self.tagWidth then return self.tagWidth, self.tagHeight end
			return base.GetSize(self)
		end
		function cell:GetContentHeight()
			return self.tagHeight or base.GetContentHeight(self)
		end
		function cell:OnRelease()
			if self.tagHolder then self.tagHolder:Hide() end
			self.tagWidth, self.tagHeight = nil, nil
			base.OnRelease(self)
		end
		tagCellProvider = provider.newCellProvider
	end
	local cell = row:GetCell(index, tagCellProvider)
	BFL.BrokerUtils.SizeSettingsComparisonCell(cell, comparison, columns, false)
	local width = cell:GetMaxWidth() or 150
	local holder = cell.tagHolder
	if not holder then
		holder = CreateFrame("Frame", nil, cell)
		holder:SetPoint("LEFT", cell, "LEFT", 4, 0)
		cell.tagHolder = holder
	end
	local height = chips:LayoutCellTags(lineTags, width - 8, true, holder, 0, 0, tagSettings)
	holder:SetSize(width - 8, math.max(1, height))
	holder:SetShown(height > 0)
	cell.tagWidth = width
	cell.tagHeight = height + 2
	cell:OnContentChanged()
end

local function GetBrokerTagGroupHeader(group, style)
	local profile = group.tagProfile
	if not profile or style == "standard" then return group.name end
	local name = group.name
	if style == "chip" and profile.iconType ~= "none" then
		local atlas = profile.atlas or (profile.iconType == "atlas" and profile.iconValue)
		local texture = profile.texture or profile.icon or (profile.iconType == "texture" and profile.iconValue)
		local icon = BFL.GetAtlasOrTextureMarkup and BFL.GetAtlasOrTextureMarkup(atlas, texture, 13, 13)
		if icon and icon ~= "" then name = icon .. " " .. name end
	end
	local color = profile.color
	if color then
		name = string.format("|cff%02x%02x%02x%s|r", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), name)
	end
	return name
end

local function CreateLibQTipTooltip(anchorFrame, sample)
	if not sample and BetterFriendlistDB and BetterFriendlistDB.brokerTooltipMode == "basic" then
		return RenderBasicQTipTooltip(anchorFrame)
	end
	local settings = sample and sample.settings or BetterFriendlistDB
	local comparison = sample and sample.comparison
	local friendTags = BFL:GetModule("FriendTags")
	local tagChips = BFL:GetModule("TagChips")
	local sampleTagSettings = sample and friendTags and (sample.tagSettings or friendTags:GetSettings())
	local showTags = friendTags and friendTags:CanDisplayTags("broker", nil, sample and settings.streamerModeActive, sampleTagSettings)
	local tagRenderer = { settingsSample = sample ~= nil, settingsSampleTagSettings = sampleTagSettings,
		settingsSampleStreamerMode = sample and settings.streamerModeActive }
	local function AddSeparator(tt)
		local color = BFL.BrokerUtils.GetBrokerSeparatorColor(settings)
		return AddTooltipSeparator(tt, color.r, color.g, color.b, color.a)
	end
	if not LQT then
		return nil
	end

	-- Dismiss any other BFL broker tooltip (prevents overlap when hovering between plugins)
	if not sample then
		BFL.BrokerUtils.DismissActiveBrokerTooltip()
	end

	-- Define available columns and their default visibility
	local columns = {
		{ key = "Nickname", label = L("BROKER_COLUMN_NICKNAME"), align = "LEFT", default = false },
		{ key = "Name", label = L("BROKER_COLUMN_NAME"), align = "LEFT", default = true },
		{ key = "Status", label = L("BROKER_COLUMN_STATUS"), align = "CENTER", default = false },
		{ key = "Level", label = L("BROKER_COLUMN_LEVEL"), align = "CENTER", default = true },
		{ key = "Character", label = L("BROKER_COLUMN_CHARACTER"), align = "LEFT", default = true },
		{ key = "Game", label = L("BROKER_COLUMN_GAME"), align = "LEFT", default = true },
		{ key = "Zone", label = L("BROKER_COLUMN_ZONE"), align = "LEFT", default = true },
		{ key = "Realm", label = L(BFL.IsForever and "BROKER_COLUMN_RULESET" or "BROKER_COLUMN_REALM"), align = "LEFT", default = true },
		{ key = "Notes", label = L("BROKER_COLUMN_NOTES"), align = "LEFT", default = true },
		{ key = "Tags", label = L("FRIEND_TAGS_SETTINGS_TAG_LIST"), align = "LEFT", default = true },
	}

	-- Get user-defined column order from DB
	local columnOrder = settings and settings.brokerColumnOrder
	local activeColumns = {}
	local orderedColumns = {}

	local function IsColumnVisible(col)
		if col.key == "Tags" and not showTags then return false end
		if comparison and not comparison.columns[col.key] then return false end
		local settingKey = "brokerShowCol" .. col.key
		local visible = settings and settings[settingKey]
		if visible == nil then
			visible = col.default
		end
		return visible ~= false
	end

	if columnOrder and #columnOrder > 0 then
		for _, colKey in ipairs(columnOrder) do
			for _, c in ipairs(columns) do
				if c.key == colKey then
					table.insert(orderedColumns, c)
					break
				end
			end
		end

		for _, col in ipairs(columns) do
			local found = false
			for _, ordered in ipairs(orderedColumns) do
				if ordered.key == col.key then
					found = true
					break
				end
			end
			if not found then
				table.insert(orderedColumns, col)
			end
		end
	else
		orderedColumns = columns
	end

	for _, col in ipairs(orderedColumns) do
		if IsColumnVisible(col) then
			table.insert(activeColumns, col)
		end
	end

	if #activeColumns == 0 then
		table.insert(activeColumns, columns[2]) -- Fallback: Name column
	end

	local hasStatusColumn, tagColumn = false, nil
	for index, col in ipairs(activeColumns) do
		if col.key == "Status" then
			hasStatusColumn = true
		elseif col.key == "Tags" then
			tagColumn = index
		end
	end

	-- Build Acquire arguments
	local numColumns = #activeColumns
	local alignArgs = {}
	for _, col in ipairs(activeColumns) do
		table.insert(alignArgs, col.align)
	end

	local tt = sample
		and BFL.BrokerUtils.AcquireSettingsTooltip(anchorFrame, (sample.tooltipKey or "BetterFriendlistSettingsBrokerSample"), sample, numColumns, alignArgs)
		or LQT:AcquireTooltip(tooltipKey, numColumns, unpack(alignArgs))
	if not tt then
		return nil
	end

	if not sample then BindLiveTooltipCleanup(tt) end

	local status, err = xpcall(function()
		tt:Clear()
		if not sample then AnchorLiveTooltip(tt, anchorFrame) end

		-- ElvUI Skin: Apply ElvUI template (hides NineSlice, applies ElvUI backdrop)
		ApplyElvUISkin(tt)

		-- Setup Fixed Footer Frame
		if not tt.footerFrame then
			tt.footerFrame = CreateFrame("Frame", nil, tt)
			tt.footerFrame:SetPoint("BOTTOMLEFT", tt, "BOTTOMLEFT", 0, 0)
			tt.footerFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", 0, 0)
		end
		local footerHeight = comparison and 0 or GetFooterHeight(settings)
		tt.footerFrame:SetHeight(math.max(1, footerHeight))
		tt.footerFrame:SetShown(footerHeight > 0)

		-- Adjust ScrollFrame to respect footer (PascalCase in v2)
		if tt.ScrollFrame then
			tt.ScrollFrame:ClearAllPoints()
			tt.ScrollFrame:SetPoint("TOP", tt, "TOP", 0, -10)
			tt.ScrollFrame:SetPoint("LEFT", tt, "LEFT", 10, 0)
			tt.ScrollFrame:SetPoint("RIGHT", tt, "RIGHT", -10, 0)
			tt.ScrollFrame:SetPoint("BOTTOM", footerHeight > 0 and tt.footerFrame or tt,
				footerHeight > 0 and "TOP" or "BOTTOM", 0, 0)
		end

		-- Render Footer Content
		local footerWidth = footerHeight > 0 and RenderFixedFooter(tt.footerFrame, sample and sample.friends, settings) or 0

		tt:SetMaxHeight(MAX_TOOLTIP_HEIGHT)
		tt:UpdateLayout()

		-- Header
		local headerRow = tt:AddHeadingRow()
		local headerCell = headerRow:GetCell(1)
		headerCell:SetColSpan(numColumns)
		BFL.BrokerUtils.SizeSettingsComparisonCell(headerCell, comparison, numColumns, true)
		headerCell:SetFontObject(BetterFriendlistFontNormalLarge)
		headerCell:SetJustifyH("LEFT")
		headerCell:SetText(C("dkyellow", L("BROKER_TITLE")))
		AddSeparator(tt)

		if comparison and comparison.hints then
			if settings.brokerShowHints ~= false then
				BFL.BrokerUtils.AddSettingsComparisonRow(tt, comparison, { FormatBrokerClickHint() })
			end
			BFL.BrokerUtils.ApplyBrokerFontToTooltip(tt, nil, settings)
			tt:UpdateLayout()
			tt:Show()
			return
		end

		-- Column Headers
		local headerCells = {}
		for _, col in ipairs(activeColumns) do
			table.insert(headerCells, C("ltyellow", col.label))
		end
		BFL.BrokerUtils.AddSettingsComparisonRow(tt, comparison, headerCells)
		AddSeparator(tt)

		local Groups = not sample and GetGroups()
		local groupsData = {}
		for id, group in pairs(sample and sample.groups or Groups and Groups:GetAll() or {}) do groupsData[id] = group end
		local roster = not sample and GetFriendsList()
		local dynamicGroups, tagGroupIds = {}, {}
		if showTags and roster and not previewData then
			dynamicGroups, tagGroupIds = friendTags:GetDynamicGroups("broker")
			for _, group in ipairs(dynamicGroups) do groupsData[group.id] = group end
		end
		local tagGroupMode = #dynamicGroups > 0 and friendTags:GetSetting("dynamicTagGroupFilter", "all")
		local prioritizeTags = tagGroupMode and friendTags:GetSetting("prioritizeDynamicTagGroups", false)
		local groupHeaderStyle = tagGroupMode and friendTags:GetSetting("dynamicTagGroupHeaderStyle", "standard")

		-- Check if mobile should be treated as offline
		local treatMobileAsOffline = settings and settings.treatMobileAsOffline

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
		local filterMode = settings and settings.quickFilter or "all"
		local filterRegistry = GetFilterSortRegistry()
		local showOffline = filterRegistry and filterRegistry:NormalizeQuickFilterId(filterMode) == "offline"
			or filterMode == "offline"

		local function ProcessFriend(friend)
			local customGroups = not sample and DB and friend.id and DB:GetFriendGroups(friend.id) or {}
			local assigned = false
			local isOnline = IsPreviewFriendOnline(friend, treatMobileAsOffline)

			local function PlaceInGroup(groupId)
				local counts = groupCounts[groupId]
				counts.total = counts.total + 1
				if isOnline then counts.online = counts.online + 1 end
				if isOnline ~= showOffline then
					table.insert(groupedFriends[groupId], friend)
				end
				assigned = true
			end

			if friend.type == "bnet" and friend.isFavorite and groupsData.favorites then
				PlaceInGroup("favorites")
			end

			if enableInGameGroup and groupsData.ingame and friend.connected then
				local client = friend.client
				local inGame = friend.type == "wow"
				if not inGame and friend.type == "bnet" then
					if inGameGroupMode == "any_game" then
						inGame = client and client ~= "" and client ~= "App" and client ~= "BSAp"
					else
						inGame = client == BNET_CLIENT_WOW and friend.wowProjectID == WOW_PROJECT_ID
					end
				end
				if inGame then PlaceInGroup("ingame") end
			end

			if not sample and enableRecentlyAdded and groupsData.recentlyadded then
				local recentlyAdded = BFL:GetModule("RecentlyAdded")
				if recentlyAdded and recentlyAdded:IsFriendRecentlyAdded(friend.id) then
					PlaceInGroup("recentlyadded")
				end
			end

			for _, groupId in ipairs(customGroups) do
				if groupsData[groupId] and not groupsData[groupId].builtin then
					PlaceInGroup(groupId)
				end
			end

			if tagGroupMode and roster:PassesDynamicTagGroupFilter(friend, tagGroupMode) then
				for _, tag in ipairs(friendTags:GetTagsForFriend(friend, "broker")) do
					local groupId = tagGroupIds[tag.id]
					if groupId then
						PlaceInGroup(groupId)
						if prioritizeTags then break end
					end
				end
			end

			if not assigned then PlaceInGroup("nogroup") end
		end

		if sample then
			for _, friend in ipairs(sample.friends) do
				ProcessFriend(friend)
			end
		elseif previewData and previewData.friends then
			for _, friend in ipairs(previewData.friends) do
				ProcessFriend(friend)
			end
		else
			-- Collect BNet Friends (ALL)
			if BNConnected() and (not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled()) then
				local numBNetTotal = BNGetNumFriends()
				local friendTagsEnabled = BFL.AreBattleNetFriendTagsEnabled and BFL.AreBattleNetFriendTagsEnabled()
				for i = 1, numBNetTotal do
					local accountInfo = BFL.GetBNetFriendInfo and BFL.GetBNetFriendInfo(i)
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
							titleCustomName = GetTitleFriendCustomName(accountInfo),
							isAFK = accountInfo.isAFK or (gameInfo.isAFK or gameInfo.isGameAFK),
							isDND = accountInfo.isDND or (gameInfo.isDND or gameInfo.isGameBusy),
							broadcast = accountInfo.customMessage or "",
							broadcastTime = accountInfo.customMessageTime,
							note = BFL.FriendNotes.GetBNetDisplayNote(accountInfo),
							connected = isOnline,
							isFavorite = accountInfo.isFavorite,
							friendLevel = accountInfo.friendLevel,
							friendTags = friendTagsEnabled and CopyFriendTags(accountInfo.friendTags) or nil,
							accountInfo = accountInfo,
							index = i,
						}

						ApplyGameAccountToFriend(friend, gameInfo)

						if isOnline and C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendGameAccountInfo then
							local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0
							if numGameAccounts > 1 then
								local gameAccounts = {}
								for accountIndex = 1, numGameAccounts do
									local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, accountIndex)
									if
										gameAccountInfo
										and gameAccountInfo.clientProgram ~= "App"
										and gameAccountInfo.clientProgram ~= "CLNT"
										and gameAccountInfo.clientProgram ~= "BSAp"
									then
										gameAccounts[#gameAccounts + 1] = gameAccountInfo
									end
								end

								friend.gameAccounts = gameAccounts
								friend.numGameAccounts = #gameAccounts

								local FriendsList = GetFriendsList()
								local prefID = FriendsList
									and FriendsList.GetPreferredGameAccountID
									and FriendsList:GetPreferredGameAccountID(friendUID)
								if prefID then
									for _, account in ipairs(gameAccounts) do
										if account.gameAccountID == prefID then
											ApplyGameAccountToFriend(friend, account)
											friend.hasPreferredAccountOverride = true
											break
										end
									end
								end
							else
								friend.numGameAccounts = numGameAccounts
							end
						else
							friend.numGameAccounts = isOnline and 1 or 0
						end

						if settings and IsForeverFilter(settings.quickFilter) and not friend.gameAccounts then
							friend.gameAccounts = GetBNetFilterGameAccounts(i)
						end

						ProcessFriend(friend)
					end
				end
			end

			-- Collect WoW Friends (ALL)
			local numWoWFriends = (BFL.GetNumWoWFriends and BFL.GetNumWoWFriends() or 0)
			for i = 1, numWoWFriends do
				local friendInfo = BFL.GetWoWFriendInfoByIndex(i)
				if friendInfo then
					local fullName = friendInfo.name or ""
					local name, realm
					if BFL.SplitPlayerName then
						name, realm = BFL.SplitPlayerName(fullName)
					else
						name, realm = strsplit("-", fullName, 2)
					end
					local normalizedName = BFL:NormalizeWoWFriendName(fullName)
					local friendUID = normalizedName and ("wow_" .. normalizedName) or ("wow_" .. fullName)

					local friend = {
						id = friendUID,
						type = "wow",
						accountName = name,
						name = fullName,
						characterName = name,
						fullName = fullName,
						guid = friendInfo.guid,
						level = friendInfo.level or 0,
						className = friendInfo.className or "UNKNOWN",
						classID = friendInfo.classID,
						client = "WoW",
						area = friendInfo.area or "",
						realmName = realm or ((not BFL.AreRegionalUniqueNamesEnabled
							or not BFL.AreRegionalUniqueNamesEnabled()) and GetRealmName() or nil),
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
		end

		-- Apply the roster filter and the shared tag selections.
		local currentFilter = settings and settings.quickFilter or "all"
		local Registry = GetFilterSortRegistry()
		if Registry and Registry.NormalizeQuickFilterId then
			currentFilter = Registry:NormalizeQuickFilterId(currentFilter)
		end
		local resolvedFilter = Registry and Registry.ResolveQuickFilter and Registry:ResolveQuickFilter(currentFilter, true)
		local useRegistryFilter = resolvedFilter and (resolvedFilter.isCustom or IsForeverFilter(currentFilter))
		local tagFilter = not sample and not previewData and GetBrokerTagFilter()
		if currentFilter ~= "all" or tagFilter then
			for groupId, groupFriends in pairs(groupedFriends) do
				local filteredFriends = {}
				for _, friend in ipairs(groupFriends) do
					local include = false

					if useRegistryFilter and Registry and Registry.EvaluateQuickFilter then
						include = Registry:EvaluateQuickFilter(currentFilter, friend)
					elseif currentFilter == "all" or currentFilter == "online" then
						include = true
					elseif currentFilter == "offline" then
						include = true
					elseif currentFilter == "wowonline" then
						include = friend.connected and (friend.type == "wow" or friend.client == BNET_CLIENT_WOW)
					elseif currentFilter == "wow" then
						include = (friend.type == "wow" or friend.client == "WoW")
					elseif currentFilter == "bnet" then
						include = (friend.type == "bnet" and friend.client ~= "WoW")
					elseif currentFilter == "hideafk" then
						include = not (friend.isAFK or friend.isDND)
					elseif currentFilter == "retail" then
						include = (friend.client == "WoW" or friend.type == "wow")
					elseif currentFilter == "ingame" then
						if friend.type == "wow" then
							include = friend.connected
						elseif friend.type == "bnet" then
							local client = friend.client
							include = friend.connected and client ~= "" and client ~= "App" and client ~= "BSAp"
						end
					end

					if include and (not tagFilter or tagFilter(friend)) then
						table.insert(filteredFriends, friend)
					end
				end
				groupedFriends[groupId] = filteredFriends
			end
		end

		-- Apply current sort mode
		local primarySort = settings and settings.primarySort or "status"
		local secondarySort = settings and settings.secondarySort or "name"

		local compareFriends = GetRosterComparator(settings)
		local SortRegistry = GetFilterSortRegistry()
		local function CompareFallback(a, b)
			if SortRegistry and SortRegistry.CompareFriends then
				local tertiary = settings and settings.enableTertiarySort == true and settings.tertiarySort
				return SortRegistry:CompareFriends(a, b, primarySort, secondarySort, tertiary)
			end

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
					local realmA = GetDisplayLocation(a)
					local realmB = GetDisplayLocation(b)
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
		for _, groupFriends in pairs(groupedFriends) do
			table.sort(groupFriends, compareFriends or CompareFallback)
		end

		local displayedCount = 0
		local displayedGroupCount = 0
		local rowIconSize = BFL.BrokerUtils.GetBrokerRowIconSize(settings)

		-- Helper to render a friend row
		local rulesetDimmedCells = {}
		local function RenderFriendRow(friend, indentation, groupId)
			local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND, friend.isMobile)
			local showClassIcons = settings and settings.brokerShowClassIcons
			local classIcon = showClassIcons and GetClassIconForFriend(friend, rowIconSize) or ""
			if classIcon ~= "" then
				classIcon = classIcon .. " "
			end

			local factionIcon = ""
			if settings and settings.showFactionIcons then
				if friend.client == "WoW" or friend.type == "wow" then
					factionIcon = GetFactionIcon(friend.factionName, rowIconSize)
				end
			end

			-- Color Logic (Parity with FriendsList)
			local playerFactionGroup = UnitFactionGroup("player")
			local grayOtherFaction = settings and settings.grayOtherFaction
			local colorClassNames = settings and settings.colorClassNames
			if colorClassNames == nil then
				colorClassNames = true
			end

			local isOppositeFaction = friend.factionName
				and friend.factionName ~= playerFactionGroup
				and friend.factionName ~= ""
			local grayRuleset
			if BFL.IsForever and settings and settings.grayOtherRuleset then
				local registry = GetFilterSortRegistry()
				grayRuleset = registry and registry:IsOtherForeverRuleset(friend, friend.gameAccountInfo, sample and "PVP" or nil)
			end
			local shouldGray = grayRuleset or (grayOtherFaction and isOppositeFaction)

			-- Read fontColorFriendName from settings as fallback color
			local fontColorName = settings and settings.fontColorFriendName
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
					local nick = GetBrokerNickname(friend)
					if nick ~= "" then
						val = shouldGray and BFL.FormatDimmedFriendText(nick)
							or ApplyBrokerColumnColor(nick, "brokerNicknameColor", settings)
						if val == nick then
							val = defaultNameColor .. nick .. "|r"
						end
					end
				elseif col.key == "Name" then
					local statusPrefix = hasStatusColumn and "" or (statusIcon .. " ")
					local displayName = GetFriendDisplayName(friend)
					local nameText = shouldGray and BFL.FormatDimmedFriendText(displayName) or (nameColor .. displayName .. "|r")
					val = indentation .. statusPrefix .. nameText
				elseif col.key == "Status" then
					val = statusIcon
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
						if classIcon ~= "" then
							displayCharName = classIcon .. displayCharName
						end

						if shouldGray then
							val = BFL.FormatDimmedFriendText(displayCharName)
						elseif GetBrokerColumnColor("brokerCharacterColor", settings) then
							val = ApplyBrokerColumnColor(displayCharName, "brokerCharacterColor", settings)
						elseif colorClassNames then
							val = ClassColorText(friend, displayCharName)
						else
							val = ApplyBrokerColumnColor(displayCharName, "brokerCharacterColor", settings)
						end
					else
						val = ""
					end
				elseif col.key == "Game" then
					val = GetFriendGameDisplay(friend, 14)
				elseif col.key == "Zone" then
					val = ApplyBrokerColumnColor(friend.area or "", "brokerZoneColor", settings)
				elseif col.key == "Realm" then
					val = ApplyBrokerColumnColor(GetDisplayLocation(friend), "brokerRealmColor", settings)
				elseif col.key == "Notes" then
					val = ApplyBrokerColumnColor(friend.note or "", "brokerNotesColor", settings)
				end
				table.insert(cellValues, val)
			end

			local row = BFL.BrokerUtils.AddSettingsComparisonRow(tt, comparison, cellValues)
			if shouldGray then
				for index, column in ipairs(activeColumns) do
					if column.key == "Name" or column.key == "Character" or column.key == "Nickname" then
						rulesetDimmedCells[#rulesetDimmedCells + 1] = row:GetCell(index)
					end
				end
			end
			if tagColumn and tagChips then
				local tags = tagChips:GetVisibleRowTags(friend, tagRenderer, groupId, "broker")
				SetBrokerTagCell(row, tagColumn, tags, comparison, numColumns, sampleTagSettings)
			end

			row:SetColor(0, 0, 0, 0)
			if sample then
				return row
			end

			row:SetScript("OnEnter", function()
				row:SetColor(0.2, 0.4, 0.6, 0.3)
				if CreateDetailTooltip then
					CreateDetailTooltip(row, friend)
				end
			end)
			row:SetScript("OnLeave", function()
				row:SetColor(0, 0, 0, 0)
				if ReleaseDetailTooltip then
					ReleaseDetailTooltip()
				end
			end)

			row:SetScript("OnMouseDown", function(frame, button)
				frame.bflLastMouseButton = button
				frame.bflPressedFriend = friend
			end)
			row:SetScript("OnMouseUp", function(frame, button)
				if not previewData and frame.bflPressedFriend == friend then OnFriendLineClick(frame, friend, button) end
				frame.bflLastMouseButton = nil
				frame.bflPressedFriend = nil
			end)

			local nativeMenu = not previewData and BFL:GetModule("NativeFriendMenu")
			if nativeMenu then nativeMenu:UpdateBrokerRow(row, friend) end

			return row
		end

		-- Get sorted group IDs for consistent display order (INCLUDE "nogroup" now)
		local groupOrder = sample and sample.groupOrder
			or Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds(true) or {}
		local sortedGroupIds = {}
		local tagIndex, hasFallback = 1, false
		for _, groupId in ipairs(groupOrder) do
			local group = groupsData[groupId]
			local order = group and group.order or 999
			while dynamicGroups[tagIndex] and dynamicGroups[tagIndex].order < order do
				sortedGroupIds[#sortedGroupIds + 1] = dynamicGroups[tagIndex].id
				tagIndex = tagIndex + 1
			end
			sortedGroupIds[#sortedGroupIds + 1] = groupId
			hasFallback = hasFallback or groupId == "nogroup"
		end
		for index = tagIndex, #dynamicGroups do sortedGroupIds[#sortedGroupIds + 1] = dynamicGroups[index].id end
		if not hasFallback then sortedGroupIds[#sortedGroupIds + 1] = "nogroup" end

		-- Display grouped friends (BNet and WoW) in configured order
		for _, groupId in ipairs(sortedGroupIds) do
			local groupFriends = groupedFriends[groupId]
			local counts = groupCounts[groupId]

			if groupFriends and #groupFriends > 0 then
				local groupInfo = groupsData[groupId]
				if not groupInfo and groupId == "nogroup" then
					groupInfo = { name = L("GROUP_NO_GROUP"), color = { r = 0.5, g = 0.5, b = 0.5 }, builtin = true }
				end

				if groupInfo and (not comparison or comparison.groups) then
					if displayedGroupCount > 0 then
						AddSeparator(tt)
					end
					displayedGroupCount = displayedGroupCount + 1

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
					local prefix = collapsed and "+ " or "- "
					local headerAlign = settings and settings.brokerGroupHeaderAlign or "LEFT"
					if headerAlign ~= "LEFT" and headerAlign ~= "CENTER" and headerAlign ~= "RIGHT" then
						headerAlign = "LEFT"
					end

					local headerName = GetBrokerTagGroupHeader(groupInfo, groupHeaderStyle)
					local headerText = string.format("|c%s%s%s|r (%s)", colorCode, prefix, headerName, countText)
					groupCell:SetColSpan(numColumns)
					BFL.BrokerUtils.SizeSettingsComparisonCell(groupCell, comparison, numColumns, true)
					groupCell:SetJustifyH(headerAlign)
					groupCell:SetText(headerText)

					if not sample then
						groupRow:SetScript("OnEnter", function()
							groupRow:SetColor(0.2, 0.2, 0.2, 0.5)
						end)
						groupRow:SetScript("OnLeave", function()
							groupRow:SetColor(0, 0, 0, 0)
						end)

						groupRow:SetScript("OnMouseUp", function(frame, button)
							if previewData then
								return
							end
							local actualButton = button or (GetMouseButtonClicked and GetMouseButtonClicked())

							if actualButton == "LeftButton" then
								if groupInfo.virtualTagGroup then
									roster:ToggleGroup(groupId)
								elseif Groups and Groups.Toggle then
									Groups:Toggle(groupId)
								else
									return
								end
								Broker:RefreshTooltip()
							elseif actualButton == "RightButton" then
								if BFL.OpenSimpleContextMenu then
									local items = {
										{
											type = "title",
											text = groupInfo.name,
										},
									}
									if groupInfo.virtualTagGroup then
										items[#items + 1] = { text = L("FRIEND_TAGS_EDITOR_EDIT"), func = function() friendTags:OpenSettings(groupInfo.tagId) end }
										items[#items + 1] = { text = L("MENU_CREATE_GROUP"), func = function() BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP") end }
										local count = roster:GetInvitableCount(groupId)
										if count > 0 then
											items[#items + 1] = { text = L("MENU_INVITE_GROUP") .. " (" .. count .. ")",
												func = function() roster:InviteGroupToParty(groupId) end }
										end
									elseif not groupInfo.builtin then
										table.insert(items, {
											text = L("MENU_RENAME_GROUP"),
											func = function()
												BFL.ShowInputDialog("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, groupId)
											end,
										})
										table.insert(items, {
											text = L("MENU_CHANGE_COLOR"),
											func = function()
												local FriendsList = BFL:GetModule("FriendsList")
												if FriendsList and FriendsList.OpenColorPicker then
													FriendsList:OpenColorPicker(groupId)
												end
											end,
										})
										table.insert(items, {
											text = L("MENU_DELETE_GROUP"),
											func = function()
												StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, groupId)
											end,
										})
									end
									BFL.OpenSimpleContextMenu(frame, "BFL_BrokerGroupDropdown", items)
								end
							end
						end)

					end
				end
				-- Render friends ONLY if not collapsed
				if groupInfo and not groupInfo.collapsed then
					for _, friend in ipairs(groupFriends) do
						RenderFriendRow(friend, comparison and not comparison.groups and "" or "    ", groupId)
						displayedCount = displayedCount + 1
						if comparison and displayedCount >= comparison.rowBudget then break end
					end
				end
				if comparison and displayedCount >= comparison.rowBudget then break end
			end
		end

		-- Footer (Empty check only)
		if displayedCount == 0 and displayedGroupCount == 0 then
			AddSeparator(tt)
			local emptyRow = tt:AddRow()
			local emptyCell = emptyRow:GetCell(1)
			emptyCell:SetColSpan(numColumns)
			BFL.BrokerUtils.SizeSettingsComparisonCell(emptyCell, comparison, numColumns, true)
			emptyCell:SetJustifyH("CENTER")
			emptyCell:SetText(C("gray", L((showOffline or tagFilter) and "AUTO_RAID_ASSIST_NO_RESULTS" or "BROKER_NO_FRIENDS_ONLINE")))
		end

		BFL.BrokerUtils.ApplyBrokerFontToTooltip(tt, nil, settings)
		for _, cell in ipairs(rulesetDimmedCells) do cell:SetTextColor(0.5, 0.5, 0.5) end

		local maxContentHeight = MAX_TOOLTIP_HEIGHT - footerHeight
		tt:SetMaxHeight(maxContentHeight)
		tt:UpdateLayout()
		if tt:GetWidth() < footerWidth then
			tt:SetWidth(footerWidth)
		end

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
		if not sample then
			SetupTooltipAutoHide(tt, anchorFrame)
		end
	end

	if not sample then ActivateLiveTooltip(tt) end

	return tt
end

function RenderBasicQTipTooltip(parent, sample)
	local tt
	if sample then
		local key = sample.tooltipKey or "BetterFriendlistSettingsBrokerSample"
		tt = BFL.BrokerUtils.AcquireSettingsTooltip(parent, key, sample, 2, { "LEFT", "RIGHT" })
	else
		BFL.BrokerUtils.DismissActiveBrokerTooltip()
		tt = LQT:AcquireTooltip(tooltipKey .. "Basic", 2, "LEFT", "RIGHT")
	end
	if not tt then return nil end
	tt:Clear()
	if not sample then
		BindLiveTooltipCleanup(tt)
		AnchorLiveTooltip(tt, parent)
	end
	ApplyElvUISkin(tt)
	if tt.footerFrame then tt.footerFrame:Hide() end
	tt.ScrollFrame:ClearAllPoints()
	tt.ScrollFrame:SetPoint("TOPLEFT", 8, -6)
	tt.ScrollFrame:SetPoint("BOTTOMRIGHT", -8, 6)
	local comparison = sample and sample.comparison
	CreateBasicTooltip({
		AddLine = function(_, text, r, g, b)
			local cell = (comparison and tt:AddRow() or tt:AddRow(text)):GetCell(1)
			cell:SetColSpan(2)
			if comparison then
				BFL.BrokerUtils.SizeSettingsComparisonCell(cell, comparison, 2, true)
				cell:SetText(text)
			end
			if r then cell:SetTextColor(r, g, b) end
		end,
		AddDoubleLine = function(_, label, value, lr, lg, lb, rr, rg, rb)
			local row = comparison and BFL.BrokerUtils.AddSettingsComparisonRow(tt, comparison, { label, value })
				or tt:AddRow(label, value)
			row:GetCell(1):SetTextColor(lr, lg, lb)
			row:GetCell(2):SetTextColor(rr, rg, rb)
		end,
	}, sample)
	tt:SetMaxHeight(MAX_TOOLTIP_HEIGHT)
	tt:UpdateLayout()
	tt:Show()
	if not sample then ActivateLiveTooltip(tt) end
	return tt
end

function Broker:RenderSettingsSample(parent, sample)
	local settings = sample.settings or BetterFriendlistDB
	local basic = settings and settings.brokerTooltipMode == "basic"
	if sample.tooltip and sample.tooltip.BFL_SettingsBasic ~= basic then
		BFL.BrokerUtils.ReleaseSettingsTooltip(sample.tooltip)
		sample.tooltip = nil
	end
	sample.settings = settings
	local tt = basic and RenderBasicQTipTooltip(parent, sample) or CreateLibQTipTooltip(parent, sample)
	if tt then tt.BFL_SettingsBasic = basic end
	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetPreviewFriendCounts("all", sample.friends)
	local label, icon = FormatBrokerDisplay(wowOnline, wowTotal, bnetOnline, bnetTotal, settings)
	return tt, label, icon
end

function Broker:SetPreviewData(data)
	previewData = data
	InvalidateFriendCountsCache()
end

function Broker:GetTooltipScrollOffset(tt)
	local slider = tt and tt.Slider
	if not (slider and slider.IsShown and slider:IsShown() and slider.GetValue) then
		return nil
	end

	local offset = tonumber(slider:GetValue())
	return offset and offset > 0 and offset or nil
end

function Broker:RestoreTooltipScrollOffset(tt, offset)
	offset = tonumber(offset)
	local slider = tt and tt.Slider
	if
		not offset
		or offset <= 0
		or not (slider and slider.IsShown and slider:IsShown() and slider.GetMinMaxValues and slider.SetValue)
	then
		return false
	end

	local minValue, maxValue = slider:GetMinMaxValues()
	minValue = tonumber(minValue)
	maxValue = tonumber(maxValue)
	if not minValue or not maxValue or maxValue <= minValue then
		return false
	end

	slider:SetValue(math.max(minValue, math.min(offset, maxValue)))
	return true
end

-- Refresh the tooltip (re-create it) to update content
function Broker:RefreshTooltip()
	if LQT and tooltip and tooltip:IsShown() then
		if tooltip.bflBrokerFilterOpen and BFL.BrokerUtils.IsMenuOpen() then
			tooltip.bflBrokerFilterDirty = true
			return
		end
		local anchor = tooltip.anchorFrame
		local scrollOffset = self:GetTooltipScrollOffset(tooltip)

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
			self:RestoreTooltipScrollOffset(tooltip, scrollOffset)
		end
	end
end

function Broker:OnPrivacyChanged()
	InvalidateFriendCountsCache()
	self:ScheduleBrokerTextUpdate()
	if LQT and tooltip then
		LQT:ReleaseTooltip(tooltip)
		tooltip = nil
	end
	if StaticPopup_Hide then StaticPopup_Hide("BFL_BROKER_TAG_SEARCH") end
end

-- ========================================
-- Broker Detail Tooltip
-- ========================================

-- Create detail tooltip on friend line hover
function CreateDetailTooltip(cell, data)
	if not data then
		return
	end

	ReleaseDetailTooltip()

	if not tooltip or not tooltip:IsShown() then
		return
	end

	local tt2 = BFL.BrokerUtils.GetOrCreateBrokerDetailTooltip("BetterFriendlistBrokerDetailTooltip")
	tt2:ClearLines()
	BFL.BrokerUtils.AnchorBrokerDetailTooltip(tt2, cell, tooltip)

	-- Header with character/account name
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

	tt2:SetText(displayName, GetAccentColor(1, 0.82, 0, 1))

	-- Status info
	if data.isAFK or data.isDND then
		local statusIcon = GetStatusIcon(data.isAFK, data.isDND)
		local statusText = data.isAFK and L("STATUS_AWAY") or L("STATUS_DND_FULL")
		tt2:AddDoubleLine(C("ltblue", L("STATUS_LABEL")), statusIcon .. " " .. C("gold", statusText))
	end

	-- Game/Client info with icon
	if data.client then
		tt2:AddDoubleLine(C("ltblue", L("GAME_LABEL")), GetFriendGameDisplay(data, 14))
	end

	-- WoW-specific details
	if data.client == "WoW" then
		-- Realm
		local location, locationKind = GetDisplayLocation(data)
		if location ~= "" then
			tt2:AddDoubleLine(C("ltblue", L(locationKind == "ruleset" and "RULESET_LABEL" or "REALM_LABEL")), location)
		end

		-- Class (with color)
		if data.className and data.className ~= "UNKNOWN" then
			tt2:AddDoubleLine(C("ltblue", L("CLASS_LABEL")), C(data.className, _G[data.className] or data.className))
		end

		-- Faction with icon
		if data.factionName and data.factionName ~= "" then
			local factionIcon = GetFactionIcon(data.factionName)
			tt2:AddDoubleLine(C("ltblue", L("FACTION_LABEL")), factionIcon .. " " .. data.factionName)
		end
	end

	-- Zone/Area
	if data.area and data.area ~= "" then
		tt2:AddDoubleLine(C("ltblue", L("ZONE_LABEL")), data.area)
	end

	-- Notes
	if data.note and data.note ~= "" then
		tt2:AddLine(" ")
		tt2:AddLine(C("ltblue", L("NOTE_LABEL")))
		tt2:AddLine(data.note, 1, 1, 1, true)
	end

	local FriendTags = BFL:GetModule("FriendTags")
	local tagText = FriendTags and FriendTags.GetBrokerTextForFriend and FriendTags:CanDisplayTags("tooltip")
		and FriendTags:GetBrokerTextForFriend(data)
	if tagText and tagText ~= "" then
		tt2:AddLine(" ")
		tt2:AddLine(C("ltblue", (BFL.L and BFL.L.FRIEND_TAGS_TOOLTIP_TITLE) or "Friend Tags"))
		tt2:AddLine(tagText, 0.50, 0.78, 1.00, true)
	end

	-- Broadcast message (BNet only)
	if data.type == "bnet" and data.broadcast and data.broadcast ~= "" then
		tt2:AddLine(" ")
		tt2:AddLine(C("ltblue", L("BROADCAST_LABEL")))
		tt2:AddLine(data.broadcast, 1, 1, 1, true)

		-- Broadcast time
		if data.broadcastTime then
			local timeSince = time() - data.broadcastTime
			local timeText = SecondsToTime(timeSince)
			tt2:AddLine(C("ltgray", string.format(L("ACTIVE_SINCE_FMT"), timeText)))
		end
	end

	tt2:Show()
	detailTooltip = tt2
end

-- Release detail tooltip on mouse leave
function ReleaseDetailTooltip()
	BFL.BrokerUtils.HideBrokerDetailTooltip(detailTooltip)
	detailTooltip = nil
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
		if _G.ToggleBetterFriendsFrame then
			_G.ToggleBetterFriendsFrame(1)
		elseif BetterFriendsFrame then
			BetterFriendsFrame:Show()
		end
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
		if _G.ToggleBetterFriendsFrame then
			_G.ToggleBetterFriendsFrame(1)
		elseif BetterFriendsFrame then
			BetterFriendsFrame:Show()
		end
	elseif action == "cycle_filter" then
		local currentFilter = BetterFriendlistDB.quickFilter or "all"
		local currentIndex = 0
		local cycleFilters = {}
		local Registry = GetFilterSortRegistry()
		if Registry and Registry.GetVisibleQuickFilters then
			for _, filter in ipairs(Registry:GetVisibleQuickFilters()) do
				table.insert(cycleFilters, filter.id)
			end
		end
		if #cycleFilters == 0 then
			cycleFilters[1] = (Registry and Registry.FALLBACK_FILTER) or "all"
		end

		for i, filter in ipairs(cycleFilters) do
			if filter == currentFilter then
				currentIndex = i
				break
			end
		end

		local nextIndex = (currentIndex % #cycleFilters) + 1
		local nextFilter = cycleFilters[nextIndex]

		if BetterFriendsFrame_SetQuickFilter then
			BetterFriendsFrame_SetQuickFilter(nextFilter)
		else
			if BetterFriendlistDB then
				BetterFriendlistDB.quickFilter = nextFilter
			end
			self:ScheduleBrokerTextUpdate()
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
			if tooltip and tooltip.IsShown and tooltip:IsShown() and tooltip.anchorFrame == anchorFrame then
				return
			end
			InvalidateFriendCountsCache()
			InvalidateBattleNetCountsCache()
			tooltip = CreateLibQTipTooltip(anchorFrame)
		end
	else
		dataObjectDef.OnTooltipShow = function(gameTooltip)
			if gameTooltip and gameTooltip.AddLine then
				InvalidateFriendCountsCache()
				InvalidateBattleNetCountsCache()
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
	if not BetterFriendlistDB.brokerEnabled then
		return
	end

	if not dataObject then
		return
	end

	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(friendID, isCompanionApp)
		if BetterFriendlistDB.treatMobileAsOffline then
			if not isCompanionApp then
				Broker:ScheduleBrokerTextUpdate(not ApplyBattleNetAccountStatusEvent(friendID, true))
			end
		else
			Broker:ScheduleBrokerTextUpdate(false)
		end
	end)

	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(friendID, isCompanionApp)
		if BetterFriendlistDB.treatMobileAsOffline then
			if not isCompanionApp then
				Broker:ScheduleBrokerTextUpdate(not ApplyBattleNetAccountStatusEvent(friendID, false))
			end
		else
			Broker:ScheduleBrokerTextUpdate(false)
		end
	end)

	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function(...)
		Broker:ScheduleBrokerTextUpdate(true)
	end)

	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
		Broker:ScheduleBrokerTextUpdate(false)
	end)

	pcall(function()
		BFL:RegisterEventCallback("LEGACY_FRIEND_SYSTEM_STATUS_UPDATED", function(...)
			Broker:ScheduleBrokerTextUpdate(false)
		end)
	end)

	BFL:RegisterEventCallback("BN_CONNECTED", function(...)
		Broker:ScheduleBrokerTextUpdate(true)
	end)

	BFL:RegisterEventCallback("BN_DISCONNECTED", function(...)
		Broker:ScheduleBrokerTextUpdate(true)
	end)

	-- An online friend can switch games or status without signing in or out.
	local function RefreshFilteredCount()
		Broker:ScheduleBrokerTextUpdate()
	end
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", RefreshFilteredCount, nil, filteredCountEventGate)
	BFL:RegisterEventCallback("BN_INFO_CHANGED", RefreshFilteredCount, nil, filteredCountEventGate)

	local function RegisterObservedTooltipEvent(event, invalidateBattleNet)
		BFL:RegisterEventCallback(event, function()
			Broker:ScheduleObservedTooltipRefresh(invalidateBattleNet)
		end, nil, brokerTooltipEventGate)
	end

	RegisterObservedTooltipEvent("BN_FRIEND_ACCOUNT_ONLINE", true)
	RegisterObservedTooltipEvent("BN_FRIEND_ACCOUNT_OFFLINE", true)
	RegisterObservedTooltipEvent("BN_FRIEND_INFO_CHANGED", true)
	RegisterObservedTooltipEvent("BN_INFO_CHANGED", true)
	RegisterObservedTooltipEvent("BATTLE_NET_TITLE_FRIEND_CUSTOM_NAME_ENABLED_STATUS_UPDATED", false)
	RegisterObservedTooltipEvent("BN_FRIEND_LIST_SIZE_CHANGED", true)
	RegisterObservedTooltipEvent("FRIENDLIST_UPDATE", false)
	RegisterObservedTooltipEvent("LEGACY_FRIEND_SYSTEM_STATUS_UPDATED", false)
	RegisterObservedTooltipEvent("BN_CONNECTED", true)
	RegisterObservedTooltipEvent("BN_DISCONNECTED", true)
end

-- ========================================
-- Slash Command Support
-- ========================================

function Broker:ToggleEnabled()
	if not BetterFriendlistDB then
		return
	end

	BetterFriendlistDB.brokerEnabled = not BetterFriendlistDB.brokerEnabled

	local message
	if BetterFriendlistDB.brokerEnabled then
		message = "|cff00ff00BetterFriendlist:|r Data Broker |cff00ff00ENABLED|r - /reload to apply"
	else
		message = "|cff00ff00BetterFriendlist:|r Data Broker |cffff0000DISABLED|r - /reload to apply"
	end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

-- Export module
BFL.Broker = Broker
return Broker
