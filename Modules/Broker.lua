-- Modules/Broker.lua
-- Data Broker Integration Module
-- Exposes BetterFriendlist via LibDataBroker-1.1 for display addons (Bazooka, ChocolateBar, TitanPanel)

local ADDON_NAME, BFL = ...

-- Register Module
local Broker = BFL:RegisterModule("Broker", {})

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB() return BFL:GetModule("DB") end
local function GetFriendsList() return BFL:GetModule("FriendsList") end
local function GetGroups() return BFL:GetModule("Groups") end
local function GetActivityTracker() return BFL:GetModule("ActivityTracker") end
local function GetStatistics() return BFL:GetModule("Statistics") end
local function GetQuickFilters() return BFL:GetModule("QuickFilters") end

-- ========================================
-- Local Variables
-- ========================================
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LQT = LibStub and LibStub:GetLibrary("LibQTip-1.0", true)
local dataObject = nil
local updateThrottle = 0
local lastUpdateTime = 0
local THROTTLE_INTERVAL = 0.1 -- Update max 10 times per second (crisp but not spammy)

-- Quick filter cycle order (offline removed - tooltip only shows online friends)
local FILTER_CYCLE = { "all", "online", "wow", "bnet" }

-- LibQTip tooltip reference
local tooltip = nil
local tooltipKey = "BetterFriendlistBrokerTT"

-- ========================================
-- Helper Functions
-- ========================================

-- Game/Client Info Table with Icons
local GetClientInfo = setmetatable({
	-- Blizzard Games
	ANBS = { icon = 4557783, short = "DI", long = "Diablo Immortal" },
	App  = { icon = 796351, short = "Desktop", long = "Desktop App" },
	BSAp = { icon = 796351, short = "Mobile", long = "Mobile App" },
	CLNT = { icon = 796351, short = "App", long = "Battle.net App" },
	D3   = { icon = 536090, short = "D3", long = "Diablo III" },
	Fen  = { icon = 5207606, short = "D4", long = "Diablo IV" },
	GRY  = { icon = 4553312, short = "Arclight", long = "Warcraft Arclight Rumble" },
	Hero = { icon = 1087463, short = "HotS", long = "Heroes of the Storm" },
	OSI  = { icon = 4034244, short = "D2R", long = "Diablo II Resurrected" },
	Pro  = { icon = 1313858, short = "OW", long = "Overwatch" },
	Pro2 = { icon = 4734171, short = "OW2", long = "Overwatch 2" },
	RTRO = { icon = 4034242, short = "Arcade", long = "Blizzard Arcade Collection" },
	S1   = { icon = 1669008, short = "SC1", long = "Starcraft" },
	S2   = { icon = 374211, short = "SC2", long = "Starcraft II" },
	W3   = { icon = 3257659, short = "WC3", long = "Warcraft III Reforged" },
	WoW  = { icon = 374212, short = "WoW", long = "World of Warcraft" },
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
	SCOR = { icon = 134400, short = "SOT", long = "Sea of Thieves" }
}, {
	__call = function(t, clientProgram)
		local info = rawget(t, clientProgram)
		if not info then
			-- Unknown game - create fallback entry
			info = { icon = 134400, short = clientProgram or "Unknown", long = clientProgram or "Unknown Game" }
			BFL:DebugPrint(string.format("Broker: Unknown game client '%s' - using fallback icon",
				tostring(clientProgram)))
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
	end
})

-- Status icon helper (AFK/DND) - smaller size for tooltip
local function GetStatusIcon(isAFK, isDND)
	if isAFK then
		return "|TInterface\\FriendsFrame\\StatusIcon-Away:12:12:0:0:32:32:5:27:5:27|t"
	elseif isDND then
		return "|TInterface\\FriendsFrame\\StatusIcon-DnD:12:12:0:0:32:32:5:27:5:27|t"
	else
		return "|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:0:32:32:5:27:5:27|t"
	end
end

-- Convert localized className to classFile (e.g., "Krieger" -> "WARRIOR")
-- This is necessary because RAID_CLASS_COLORS uses classFile keys, not localized names
local function GetClassFileFromClassName(className)
	if not className or className == "" then 
		return nil 
	end
	
	-- First try: Direct uppercase match (works for English clients)
	local upperClassName = string.upper(className)
	if RAID_CLASS_COLORS[upperClassName] then
		return upperClassName
	end
	
	-- Second try: Match localized className against GetClassInfo()
	local numClasses = GetNumClasses()
	for i = 1, numClasses do
		local localizedName, classFile = GetClassInfo(i)
		if localizedName == className then
			return classFile
		end
	end
	
	-- Third try: Handle gendered class names (German, French, Spanish, etc.)
	local genderVariants = {}
	
	-- German: Remove "-in" suffix (Kriegerin → Krieger)
	if className:len() > 2 and className:sub(-2) == "in" then
		table.insert(genderVariants, className:sub(1, -3))
	end
	
	-- French: Remove "-e" suffix
	if className:len() > 1 and className:sub(-1) == "e" then
		table.insert(genderVariants, className:sub(1, -2))
	end
	
	-- Spanish: Replace "-a" with "-o"
	if className:len() > 1 and className:sub(-1) == "a" then
		table.insert(genderVariants, className:sub(1, -2) .. "o")
	end
	
	-- Try matching gender variants
	for _, variant in ipairs(genderVariants) do
		for i = 1, numClasses do
			local localizedName, classFile = GetClassInfo(i)
			if localizedName == variant then
				return classFile
			end
		end
	end
	
	return nil
end

-- Get classFile for friend data (prioritizes classID for 11.2.7+)
local function GetClassFileForFriend(friend)
	-- 11.2.7+: Use classID if available (fast, language-independent)
	if BFL.UseClassID and friend.classID then
		local classInfo = GetClassInfoByID(friend.classID)
		if classInfo and classInfo.classFile then
			return classInfo.classFile
		end
	end
	
	-- Fallback: Convert localized className
	if friend.className then
		return GetClassFileFromClassName(friend.className)
	end
	
	return nil
end

-- Get class color for friend (returns color table or white fallback)
local function GetClassColorForFriend(friend)
	local classFile = GetClassFileForFriend(friend)
	if classFile and RAID_CLASS_COLORS[classFile] then
		return RAID_CLASS_COLORS[classFile]
	end
	return { r = 1, g = 1, b = 1 } -- White fallback
end

-- Color text using friend's class color (uses classID if available)
local function ClassColorText(friend, text)
	if not text then return "" end
	local classColor = GetClassColorForFriend(friend)
	return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
end

-- Faction icon helper
local function GetFactionIcon(factionName)
	if not factionName then return "" end

	if factionName == "Alliance" then
		return "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|t"
	elseif factionName == "Horde" then
		return "|TInterface\\FriendsFrame\\PlusManz-Horde:16:16|t"
	else
		return "" -- Neutral or unknown
	end
end

-- Color wrapper helper
local function C(color, text)
	if not text then
		return ""
	end

	local colors = {
		dkyellow = "ffcc00",
		ltyellow = "ffff99",
		ltblue = "6699ff",
		ltgray = "b0b0b0",
		gray = "808080",
		white = "ffffff",
		green = "00ff00",
		red = "ff0000",
		gold = "ffd700",
	}

	-- Check if it's a class color (try direct match first, then convert from localized name)
	local classColor = RAID_CLASS_COLORS[color]
	if not classColor then
		-- Try converting localized className to classFile
		local classFile = GetClassFileFromClassName(color)
		if classFile then
			classColor = RAID_CLASS_COLORS[classFile]
		end
	end
	
	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end

	-- Otherwise use predefined or custom hex
	local hex = colors[color] or color
	return "|cff" .. hex .. text .. "|r"
end

-- Helper: Add friend name to active chat editbox (Shift+Click)
-- Must be defined before OnFriendLineClick which uses it
local function AddNameToEditBox(name, realm)
	if not name then return false end

	-- Add realm suffix if different from player's realm
	local playerRealm = GetRealmName()
	if realm and realm ~= "" and realm ~= playerRealm then
		name = name .. "-" .. realm
	end

	-- Find active chat editbox and insert name
	local editboxes = {
		ChatEdit_GetActiveWindow(),
		ChatEdit_GetLastActiveWindow(),
	}

	for _, editbox in ipairs(editboxes) do
		if editbox and editbox:IsVisible() and editbox:HasFocus() then
			editbox:Insert(name)
			return true
		end
	end

	-- Fallback: Insert into default chat frame's editbox
	local defaultEditBox = ChatEdit_ChooseBoxForSend()
	if defaultEditBox then
		ChatEdit_ActivateChat(defaultEditBox)
		defaultEditBox:Insert(name)
		return true
	end

	return false
end

-- Helper: Smart invite - either invite to group or request to join their group
local function SmartInviteOrJoin(friendType, data)
	if not data then return end
	
	local playerInGroup = IsInGroup(LE_PARTY_CATEGORY_HOME)
	local isLeader = UnitIsGroupLeader("player") or not playerInGroup
	
	if friendType == "bnet" then
		-- BNet friend - must be in WoW
		if data.client ~= "WoW" or not data.gameAccountID then
			BFL:DebugPrint("Broker: BNet friend not in WoW, cannot invite/join")
			return
		end
		
		if isLeader then
			-- We can invite: Use BNInviteFriend
			BNInviteFriend(data.gameAccountID)
			BFL:DebugPrint(string.format("Broker: Invited BNet friend %s", data.accountName or "Unknown"))
		else
			-- We need to request to join their group
			-- For BNet friends, we need to use their character name
			if data.characterName and data.characterName ~= "" then
				local targetName = data.characterName
				if data.realmName and data.realmName ~= "" and data.realmName ~= GetRealmName() then
					targetName = targetName .. "-" .. data.realmName
				end
				C_PartyInfo.RequestInviteFromUnit(targetName)
				BFL:DebugPrint(string.format("Broker: Requested invite from %s", targetName))
			else
				BFL:DebugPrint("Broker: Cannot request invite - no character name")
			end
		end
		
	elseif friendType == "wow" then
		-- WoW friend
		local targetName = data.fullName or data.characterName
		if not targetName then
			BFL:DebugPrint("Broker: WoW friend has no name, cannot invite/join")
			return
		end
		
		if isLeader then
			-- We can invite
			C_PartyInfo.InviteUnit(targetName)
			BFL:DebugPrint(string.format("Broker: Invited WoW friend %s", targetName))
		else
			-- We need to request to join their group
			C_PartyInfo.RequestInviteFromUnit(targetName)
			BFL:DebugPrint(string.format("Broker: Requested invite from %s", targetName))
		end
	end
end

-- Helper: Open context menu for friend (like FriendsList)
-- Create a hidden anchor frame for context menus
local contextMenuAnchor = CreateFrame("Frame", "BFL_BrokerContextMenuAnchor", UIParent)
contextMenuAnchor:SetSize(1, 1)
contextMenuAnchor:Hide()

local function OpenFriendContextMenu(data)
	if not data then return end
	
	-- Position anchor at cursor
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	contextMenuAnchor:ClearAllPoints()
	contextMenuAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	
	local MenuSystem = BFL:GetModule("MenuSystem")
	if not MenuSystem then
		BFL:DebugPrint("Broker: MenuSystem not available")
		return
	end
	
	if data.type == "bnet" then
		-- Need bnetAccountID for BNet menu
		local bnetAccountID = data.bnetAccountID
		
		if not bnetAccountID and data.id then
			-- Extract from id string "bnet_BattleTag#1234" - fallback to old format
			bnetAccountID = tonumber(data.id:match("^bnet(%d+)$"))
		end
		
		if bnetAccountID then
			-- Pass extra data for menu title and context
			local extraData = {
				name = data.accountName or data.characterName or "",
				battleTag = data.battleTag,
				connected = true, -- Broker only shows online friends
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "BN", bnetAccountID, extraData)
			BFL:DebugPrint(string.format("Broker: Opening BNet context menu for %s", data.accountName or "Unknown"))
		else
			BFL:DebugPrint("Broker: Could not get bnetAccountID for context menu")
		end
		
	elseif data.type == "wow" then
		-- For WoW friends, we need to find the friend index
		local numFriends = C_FriendList.GetNumFriends()
		local friendIndex = nil
		
		for i = 1, numFriends do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo and friendInfo.name == data.fullName then
				friendIndex = i
				break
			end
		end
		
		if friendIndex then
			-- Pass extra data for menu title and context
			local extraData = {
				name = data.fullName or data.characterName or "",
				connected = true, -- Broker only shows online friends
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "WOW", friendIndex, extraData)
			BFL:DebugPrint(string.format("Broker: Opening WoW context menu for %s", data.characterName or "Unknown"))
		else
			BFL:DebugPrint("Broker: Could not find friend index for context menu")
		end
	end
end

-- Main click handler for friend lines in LibQTip tooltip
local function OnFriendLineClick(cell, data, mouseButton)
	if not data then return end
	
	-- LibQTip doesn't pass mouseButton - we need to get it ourselves!
	local actualButton = mouseButton or GetMouseButtonClicked()

	-- BattleNet friend click handlers
	if data.type == "bnet" then
		if IsAltKeyDown() then
			-- Alt+Click: Smart Invite or Request to Join
			SmartInviteOrJoin("bnet", data)
		elseif IsShiftKeyDown() then
			-- Shift+Click: Copy character name to chat editbox (WoW only)
			if data.client == "WoW" and data.characterName and data.characterName ~= "" then
				if AddNameToEditBox(data.characterName, data.realmName) then
					BFL:DebugPrint(string.format("Broker: Copied '%s' to chat editbox", data.characterName))
				end
			else
				BFL:DebugPrint("Broker: BNet friend not in WoW, cannot copy character name")
			end
		elseif actualButton == "RightButton" then
			-- Right Click: Open context menu (like FriendsList)
			OpenFriendContextMenu(data)
		else
			-- Left Click: BNet whisper (account name)
			if data.bnetAccountID then
				-- Use SetItemRef with BNplayer link - this is the modern way to whisper BNet friends
				local bnetLink = "BNplayer:" .. (data.accountName or "Friend") .. ":" .. data.bnetAccountID
				SetItemRef(bnetLink, bnetLink, "LeftButton")
				BFL:DebugPrint(string.format("Broker: Opening BNet whisper to %s (ID: %d)", data.accountName or "Unknown", data.bnetAccountID))
			elseif data.accountName and data.accountName ~= "" then
				-- Fallback: try ChatFrame_SendSmartTell
				ChatFrame_SendSmartTell(data.accountName)
				BFL:DebugPrint(string.format("Broker: Opening BNet whisper to %s", data.accountName))
			end
		end

	-- WoW friend click handlers
	elseif data.type == "wow" then
		if IsAltKeyDown() then
			-- Alt+Click: Smart Invite or Request to Join
			SmartInviteOrJoin("wow", data)
		elseif IsShiftKeyDown() then
			-- Shift+Click: Copy name to chat editbox
			if data.characterName then
				if AddNameToEditBox(data.characterName, data.realmName) then
					BFL:DebugPrint(string.format("Broker: Copied '%s' to chat editbox", data.characterName))
				end
			end
		elseif actualButton == "RightButton" then
			-- Right Click: Open context menu (like FriendsList)
			OpenFriendContextMenu(data)
		else
			-- Left Click: Whisper
			if data.fullName then
				local whisperName = data.fullName:gsub(" ", "")
				ChatFrame_SendTell(whisperName)
				BFL:DebugPrint(string.format("Broker: Opening whisper to %s", whisperName))
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
	if not timestamp then return nil end
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
			-- Count online friends excluding mobile users
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

-- ========================================
-- Broker Text Update
-- ========================================

function Broker:UpdateBrokerText()
	if not dataObject then return end

	-- Throttle updates
	local currentTime = GetTime()
	if currentTime - lastUpdateTime < THROTTLE_INTERVAL then
		return
	end
	lastUpdateTime = currentTime

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then return end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()
	local totalOnline = wowOnline + bnetOnline
	local totalFriends = wowTotal + bnetTotal

	-- Format text based on config
	local text
	if BetterFriendlistDB.brokerShowGroups then
		-- Split display: "5/10 WoW | 3/8 BNet"
		text = string.format("%d/%d WoW | %d/%d BNet", wowOnline, wowTotal, bnetOnline, bnetTotal)
	else
		-- Combined display: "Friends: 8/18"
		text = string.format("Friends: %d/%d", totalOnline, totalFriends)
	end

	dataObject.text = text

	BFL:DebugPrint(string.format("Broker: Updated text to '%s'", text))
end

-- ========================================
-- Tooltip Functions
-- ========================================

-- Basic Tooltip
local function CreateBasicTooltip(tooltip)
	tooltip:AddLine("BetterFriendlist", 1, 0.82, 0, 1)
	tooltip:AddLine(" ")

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()

	-- Summary
	tooltip:AddDoubleLine("WoW Friends:", string.format("%d online / %d total", wowOnline, wowTotal), 1, 1, 1, 0, 1, 0)
	tooltip:AddDoubleLine("BNet Friends:", string.format("%d online / %d total", bnetOnline, bnetTotal), 1, 1, 1, 0, 0.5,
		1)
	tooltip:AddLine(" ")

	-- Get current filter
	local QuickFilters = GetQuickFilters()
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	tooltip:AddDoubleLine("Current Filter:", currentFilter, 1, 1, 1, 1, 1, 0)

	tooltip:AddLine(" ")
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine("Middle Click: Cycle Filter", 0.5, 0.9, 1, 1)
end

-- Advanced Tooltip with Groups and Activity
local function CreateAdvancedTooltip(tooltip)
	tooltip:AddLine("BetterFriendlist", 1, 0.82, 0, 1)
	tooltip:AddLine(" ")

	local Groups = GetGroups()
	local ActivityTracker = GetActivityTracker()

	-- Get ALL online friends directly from API (ignore filters)
	local friends = {}

	-- BNet friends
	if BNConnected() then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		for i = 1, numBNetOnline do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				table.insert(friends, {
					id = "bnet" .. accountInfo.bnetAccountID,
					type = "bnet",
					info = {
						name = accountInfo.accountName or "Unknown",
						level = accountInfo.gameAccountInfo.characterLevel or "??",
						className = accountInfo.gameAccountInfo.className or "UNKNOWN",
						area = accountInfo.gameAccountInfo.areaName or "Unknown"
					}
				})
			end
		end
	end

	-- WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends()
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.connected then
			table.insert(friends, {
				id = "wow" .. (friendInfo.name or ""),
				type = "wow",
				info = {
					name = friendInfo.name or "Unknown",
					level = friendInfo.level or "??",
					className = friendInfo.className or "UNKNOWN",
					area = friendInfo.area or "Unknown"
				}
			})
		end
	end

	local groupsData = Groups and Groups:GetAll() or {}

	-- Group friends by custom groups
	local groupedFriends = {}
	local ungrouped = {}

	for _, friend in ipairs(friends) do
		if friend and friend.info then
			local friendGroups = BetterFriendlistDB and BetterFriendlistDB.friendGroups and
			BetterFriendlistDB.friendGroups[friend.id] or {}
			local assigned = false

			for _, groupId in ipairs(friendGroups) do
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

	-- Display grouped friends in configured order
	local displayedCount = 0
	local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds() or {}
	
	for _, groupId in ipairs(sortedGroupIds) do
		local groupFriends = groupedFriends[groupId]
		if groupFriends and #groupFriends > 0 then
			local groupInfo = groupsData[groupId]
			if groupInfo then
				tooltip:AddLine(groupInfo.name, 1, 0.82, 0, 1)

			for i, friend in ipairs(groupFriends) do
				if i > 5 then
					tooltip:AddLine(string.format("  ... and %d more", #groupFriends - 5), 0.7, 0.7, 0.7)
					break
				end

				local info = friend.info
				local name = info.name or "Unknown"
				local level = info.level or "??"
				local className = info.className or "UNKNOWN"
				local zone = info.area or "Unknown"

				-- Color by class
				local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }

				-- Activity info
				local activityText = ""
				if ActivityTracker then
					local activities = ActivityTracker:GetAllActivities(friend.id)
					if activities and activities.lastWhisper then
						local timeStr = FormatTimeSince(activities.lastWhisper)
						if timeStr then
							activityText = string.format(" (whisper %s ago)", timeStr)
						end
					end
				end

				tooltip:AddDoubleLine(
					string.format("  %s (%s)", name, level),
					zone .. activityText,
					classColor.r, classColor.g, classColor.b,
					0.7, 0.7, 0.7
				)
				displayedCount = displayedCount + 1
			end

			tooltip:AddLine(" ")
		end
		end
	end

	-- Display ungrouped friends
	if #ungrouped > 0 then
		tooltip:AddLine("No Group", 0.7, 0.7, 0.7, 1)
		for i, friend in ipairs(ungrouped) do
			if i > 5 then
				tooltip:AddLine(string.format("  ... and %d more", #ungrouped - 5), 0.7, 0.7, 0.7)
				break
			end

			local info = friend.info
			local name = info.name or "Unknown"
			local level = info.level or "??"
			local className = info.className or "UNKNOWN"
			local zone = info.area or "Unknown"

			local classColor = RAID_CLASS_COLORS[className] or { r = 1, g = 1, b = 1 }

			tooltip:AddDoubleLine(
				string.format("  %s (%s)", name, level),
				zone,
				classColor.r, classColor.g, classColor.b,
				0.7, 0.7, 0.7
			)
			displayedCount = displayedCount + 1
		end
		tooltip:AddLine(" ")
	end

	-- Statistics
	if displayedCount == 0 then
		tooltip:AddLine("No friends online", 0.7, 0.7, 0.7)
		tooltip:AddLine(" ")
	end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()
	tooltip:AddDoubleLine("Total:", string.format("%d online / %d friends", wowOnline + bnetOnline, wowTotal + bnetTotal),
		1, 1, 1, 0, 1, 0)

	-- Current filter
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	tooltip:AddDoubleLine("Filter:", currentFilter, 1, 1, 1, 1, 1, 0)

	tooltip:AddLine(" ")
	tooltip:AddLine("Left Click: Toggle BetterFriendlist", 0.5, 0.9, 1, 1)
	tooltip:AddLine("Right Click: Settings", 0.5, 0.9, 1, 1)
	tooltip:AddLine("Middle Click: Cycle Filter", 0.5, 0.9, 1, 1)
end

-- ========================================
-- LibQTip Tooltip (NEW)
-- ========================================

local function CreateLibQTipTooltip(anchorFrame)
	if not LQT then
		BFL:DebugPrint("Broker: LibQTip not available, skipping tooltip")
		return nil
	end

	-- Acquire tooltip with 8 columns
	-- Columns: Name(LEFT), Level(CENTER), Character(LEFT), Game(LEFT), Zone(LEFT), Realm(LEFT), Faction(LEFT), Notes(LEFT)
	local tt = LQT:Acquire(tooltipKey, 8, "LEFT", "CENTER", "LEFT", "LEFT", "LEFT", "LEFT", "LEFT", "LEFT")
	tt:Clear()
	tt:SmartAnchorTo(anchorFrame)
	tt:SetAutoHideDelay(0.25, anchorFrame)
	tt:SetFrameStrata("HIGH") -- Lower than TOOLTIP so context menus appear above
	tt:UpdateScrolling()

	-- Header
	local headerLine = tt:AddHeader()
	tt:SetCell(headerLine, 1, C("dkyellow", "BetterFriendlist"), "GameFontNormalLarge", "LEFT", 8)
	tt:AddSeparator()

	-- Column Headers
	local colLine = tt:AddLine(
		C("ltyellow", "Name"),
		C("ltyellow", "Lvl"),
		C("ltyellow", "Character"),
		C("ltyellow", "Game"),
		C("ltyellow", "Zone"),
		C("ltyellow", "Realm"),
		C("ltyellow", "Faction"),
		C("ltyellow", "Notes")
	)
	tt:AddSeparator()

	local Groups = GetGroups()
	local groupsData = Groups and Groups:GetAll() or {}

	-- Get ALL online friends directly from API
	local friends = {}
	
	-- Check if mobile should be treated as offline
	local treatMobileAsOffline = BetterFriendlistDB and BetterFriendlistDB.treatMobileAsOffline

	-- BNet friends
	if BNConnected() then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		for i = 1, numBNetOnline do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				local gameInfo = accountInfo.gameAccountInfo
				local client = gameInfo.clientProgram or "App"
				
				-- Skip mobile users if treatMobileAsOffline is enabled
				local isMobile = (client == "BSAp")
				if treatMobileAsOffline and isMobile then
					-- Skip this friend - treat as offline
				else
					-- Use battleTag for consistent UID with FriendsList (bnet_BattleTag#1234)
					local friendUID = accountInfo.battleTag and ("bnet_" .. accountInfo.battleTag) or ("bnet_" .. tostring(accountInfo.bnetAccountID))
					table.insert(friends, {
						id = friendUID,
						bnetAccountID = accountInfo.bnetAccountID,
						battleTag = accountInfo.battleTag,
						type = "bnet",
						accountName = accountInfo.accountName or "Unknown",
						characterName = gameInfo.characterName or "",
						level = gameInfo.characterLevel or 0,
						className = gameInfo.className or "UNKNOWN",
						classID = gameInfo.classID,
						client = client,
						area = gameInfo.areaName or gameInfo.richPresence or "",
						realmName = gameInfo.realmName or "",
						factionName = gameInfo.factionName or "",
						isAFK = accountInfo.isAFK,
						isDND = accountInfo.isDND,
						isMobile = isMobile,
						broadcast = accountInfo.customMessage or "",
						broadcastTime = accountInfo.customMessageTime,
						note = accountInfo.note or "",
						gameAccountID = gameInfo.gameAccountID
					})
				end
			end
		end
	end

	-- WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends()
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.connected then
			local fullName = friendInfo.name or ""
			local name, realm = strsplit("-", fullName, 2)
			-- Use normalized name for consistent UID with FriendsList (wow_Name-Realm)
			local normalizedName = BFL:NormalizeWoWFriendName(fullName)
			local friendUID = normalizedName and ("wow_" .. normalizedName) or ("wow_" .. fullName)
			table.insert(friends, {
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
				isAFK = friendInfo.afk,
				isDND = friendInfo.dnd,
				note = friendInfo.notes or ""
			})
		end
	end

	-- Apply current filter
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	if currentFilter ~= "all" then
		local filteredFriends = {}
		for _, friend in ipairs(friends) do
			local include = false

			if currentFilter == "online" then
				include = true -- already only online friends
			elseif currentFilter == "offline" then
				include = false -- skip all (no offline friends in tooltip)
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
		friends = filteredFriends
	end

	-- Apply current sort mode (simplified sorting for tooltip)
	local sortMode = BetterFriendlistDB and BetterFriendlistDB.primarySort or "status"
	
	-- Simple sort comparator for tooltip
	local function CompareFriends(a, b)
		if sortMode == "name" then
			local nameA = (a.characterName and a.characterName ~= "") and a.characterName or a.accountName
			local nameB = (b.characterName and b.characterName ~= "") and b.characterName or b.accountName
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif sortMode == "level" then
			local levelA = a.level or 0
			local levelB = b.level or 0
			if levelA ~= levelB then
				return levelA > levelB
			end
			-- Secondary: name
			local nameA = (a.characterName and a.characterName ~= "") and a.characterName or a.accountName
			local nameB = (b.characterName and b.characterName ~= "") and b.characterName or b.accountName
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif sortMode == "zone" then
			local zoneA = a.area or ""
			local zoneB = b.area or ""
			if zoneA ~= zoneB then
				return zoneA:lower() < zoneB:lower()
			end
			-- Secondary: name
			local nameA = (a.characterName and a.characterName ~= "") and a.characterName or a.accountName
			local nameB = (b.characterName and b.characterName ~= "") and b.characterName or b.accountName
			return (nameA or ""):lower() < (nameB or ""):lower()
		elseif sortMode == "game" then
			-- WoW first, then other games, then apps
			local function GetGamePriority(friend)
				if friend.client == "WoW" or friend.type == "wow" then return 0 end
				if friend.client == "App" or friend.client == "BSAp" then return 2 end
				return 1
			end
			local priorityA = GetGamePriority(a)
			local priorityB = GetGamePriority(b)
			if priorityA ~= priorityB then
				return priorityA < priorityB
			end
			-- Secondary: name
			local nameA = (a.characterName and a.characterName ~= "") and a.characterName or a.accountName
			local nameB = (b.characterName and b.characterName ~= "") and b.characterName or b.accountName
			return (nameA or ""):lower() < (nameB or ""):lower()
		else
			-- Default (status): Online first (all are online in tooltip), then by AFK/DND, then name
			-- AFK/DND at bottom
			local afkA = (a.isAFK or a.isDND) and 1 or 0
			local afkB = (b.isAFK or b.isDND) and 1 or 0
			if afkA ~= afkB then
				return afkA < afkB
			end
			-- Secondary: name
			local nameA = (a.characterName and a.characterName ~= "") and a.characterName or a.accountName
			local nameB = (b.characterName and b.characterName ~= "") and b.characterName or b.accountName
			return (nameA or ""):lower() < (nameB or ""):lower()
		end
	end
	
	table.sort(friends, CompareFriends)

	-- Group friends by custom groups
	local groupedFriends = {}
	local ungrouped = {}

	for _, friend in ipairs(friends) do
		local friendGroups = BetterFriendlistDB and BetterFriendlistDB.friendGroups and
		BetterFriendlistDB.friendGroups[friend.id] or {}
		local assigned = false

		for _, groupId in ipairs(friendGroups) do
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

	local displayedCount = 0

	-- Display Battle.Net Friends Header
	if BNConnected() then
		local bnetLine = tt:AddLine()
		tt:SetCell(bnetLine, 1, C("ltgray", "Battle.Net Friends"), nil, "LEFT", 8)
	end

	-- Get sorted group IDs for consistent display order
	local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds() or {}

	-- Display grouped BNet friends in configured order
	for _, groupId in ipairs(sortedGroupIds) do
		local groupFriends = groupedFriends[groupId]
		if groupFriends then
			local groupInfo = groupsData[groupId]
			if groupInfo then
			local hasMembers = false
			for _, friend in ipairs(groupFriends) do
				if friend.type == "bnet" then
					hasMembers = true
					break
				end
			end

			if hasMembers then
				local groupLine = tt:AddLine()
				tt:SetCell(groupLine, 1, "  " .. C("dkyellow", groupInfo.name), nil, "LEFT", 8)

				for i, friend in ipairs(groupFriends) do
					if friend.type == "bnet" then
						local nameText = friend.characterName ~= "" and friend.characterName or friend.accountName
						local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND)
						local clientInfo = GetClientInfo(friend.client)
						local factionIcon = friend.client == "WoW" and GetFactionIcon(friend.factionName) or ""

						local line = tt:AddLine(
							"    " .. statusIcon .. " " .. friend.accountName,
							friend.level > 0 and tostring(friend.level) or "",
							ClassColorText(friend, nameText) .. (factionIcon ~= "" and " " .. factionIcon or ""),
							clientInfo.iconStr .. " " .. clientInfo.short,
							friend.area or "",
							friend.realmName or "",
							friend.factionName or "",
							friend.note or ""
						)

						-- Hover highlight
						tt:SetLineColor(line, 0, 0, 0, 0)
						tt:SetLineScript(line, "OnEnter", function()
							tt:SetLineColor(line, 0.2, 0.4, 0.6, 0.3)
						end)
						tt:SetLineScript(line, "OnLeave", function()
							tt:SetLineColor(line, 0, 0, 0, 0)
						end)

						-- Click handler
						tt:SetLineScript(line, "OnMouseUp", function(self, button)
							OnFriendLineClick(nil, friend, button)
						end)

						displayedCount = displayedCount + 1
					end
				end
			end
			end
		end
	end

	-- Display ungrouped BNet friends
	local ungroupedBNet = {}
	for _, friend in ipairs(ungrouped) do
		if friend.type == "bnet" then
			table.insert(ungroupedBNet, friend)
		end
	end

	if #ungroupedBNet > 0 then
		for i, friend in ipairs(ungroupedBNet) do
			local nameText = friend.characterName ~= "" and friend.characterName or friend.accountName
			local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND)
			local clientInfo = GetClientInfo(friend.client)
			local factionIcon = friend.client == "WoW" and GetFactionIcon(friend.factionName) or ""

			local line = tt:AddLine(
				"  " .. statusIcon .. " " .. friend.accountName,
				friend.level > 0 and tostring(friend.level) or "",
				ClassColorText(friend, nameText) .. (factionIcon ~= "" and " " .. factionIcon or ""),
				clientInfo.iconStr .. " " .. clientInfo.short,
				friend.area or "",
				friend.realmName or "",
				friend.factionName or "",
				friend.note or ""
			)

			-- Hover highlight
			tt:SetLineColor(line, 0, 0, 0, 0)
			tt:SetLineScript(line, "OnEnter", function()
				tt:SetLineColor(line, 0.2, 0.4, 0.6, 0.3)
			end)
			tt:SetLineScript(line, "OnLeave", function()
				tt:SetLineColor(line, 0, 0, 0, 0)
			end)

			-- Click handler
			tt:SetLineScript(line, "OnMouseUp", function(self, button)
				OnFriendLineClick(nil, friend, button)
			end)

			displayedCount = displayedCount + 1
		end
	end

	-- WoW Friends Section
	tt:AddSeparator()
	local wowLine = tt:AddLine()
	tt:SetCell(wowLine, 1, C("ltgray", "WoW Friends"), nil, "LEFT", 8)

	-- Display ungrouped WoW friends
	local ungroupedWoW = {}
	for _, friend in ipairs(ungrouped) do
		if friend.type == "wow" then
			table.insert(ungroupedWoW, friend)
		end
	end

	if #ungroupedWoW > 0 then
		for i, friend in ipairs(ungroupedWoW) do
			local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND)
			local clientInfo = GetClientInfo(friend.client)
			local factionIcon = GetFactionIcon(friend.factionName)

			local line = tt:AddLine(
				statusIcon,
				friend.level > 0 and tostring(friend.level) or "",
				ClassColorText(friend, friend.characterName) .. (factionIcon ~= "" and " " .. factionIcon or ""),
				clientInfo.iconStr .. " " .. clientInfo.short,
				friend.area or "",
				friend.realmName or "",
				friend.factionName or "",
				friend.note or ""
			)

			-- Hover highlight
			tt:SetLineColor(line, 0, 0, 0, 0)
			tt:SetLineScript(line, "OnEnter", function()
				tt:SetLineColor(line, 0.2, 0.4, 0.6, 0.3)
			end)
			tt:SetLineScript(line, "OnLeave", function()
				tt:SetLineColor(line, 0, 0, 0, 0)
			end)

			-- Click handler
			tt:SetLineScript(line, "OnMouseUp", function(self, button)
				OnFriendLineClick(nil, friend, button)
			end)

			displayedCount = displayedCount + 1
		end
	else
		local emptyLine = tt:AddLine()
		tt:SetCell(emptyLine, 1, C("gray", "  No WoW friends online"), nil, "LEFT", 8)
	end

	-- Footer
	if displayedCount == 0 then
		tt:AddSeparator()
		local emptyLine = tt:AddLine()
		tt:SetCell(emptyLine, 1, C("gray", "No friends online"), nil, "CENTER", 8)
	end

	tt:AddSeparator()
	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()
	local totalLine = tt:AddLine()
	tt:SetCell(totalLine, 1, string.format("Total: %d online / %d friends", wowOnline + bnetOnline, wowTotal + bnetTotal),
		nil, "LEFT", 8)

	-- Current filter with icon and text (same as QuickFilter dropdown)
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	local QuickFilters = GetQuickFilters()
	local filterText = "All Friends"
	local filterIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\filter-all"

	if QuickFilters then
		filterText = QuickFilters:GetFilterText() or filterText
		local icons = QuickFilters:GetIcons()
		if icons and icons[currentFilter] then
			filterIcon = icons[currentFilter]
		end
	end

	local filterLine = tt:AddLine()
	local filterDisplay = string.format("|T%s:16:16:0:0|t %s", filterIcon, C("ltyellow", filterText))
	tt:SetCell(filterLine, 1, "Filter: " .. filterDisplay, nil, "LEFT", 8)

	-- Current sort mode
	local sortMode = BetterFriendlistDB and BetterFriendlistDB.primarySort or "status"
	local sortNames = {
		status = "Status",
		name = "Name",
		level = "Level",
		zone = "Zone",
		game = "Game",
		faction = "Faction",
		guild = "Guild",
		class = "Class",
		activity = "Activity"
	}
	local sortLine = tt:AddLine()
	tt:SetCell(sortLine, 1, "Sort: " .. C("ltyellow", sortNames[sortMode] or sortMode), nil, "LEFT", 8)

	tt:AddSeparator()
	local hint1 = tt:AddLine()
	tt:SetCell(hint1, 1, C("ltgray", "--- Friend Line Actions ---"), nil, "CENTER", 8)
	local hint2 = tt:AddLine()
	tt:SetCell(hint2, 1,
		C("ltblue", "Click Friend:") .. " Whisper • " .. C("ltblue", "Right-Click:") .. " Context Menu", nil, "LEFT",
		8)
	local hint3 = tt:AddLine()
	tt:SetCell(hint3, 1, C("ltblue", "Alt+Click:") .. " Invite/Join • " .. C("ltblue", "Shift+Click:") .. " Copy to Chat", nil,
		"LEFT", 8)

	tt:AddSeparator()
	local hint4 = tt:AddLine()
	tt:SetCell(hint4, 1, C("ltgray", "--- Broker Icon Actions ---"), nil, "CENTER", 8)
	local hint5 = tt:AddLine()
	tt:SetCell(hint5, 1, C("ltblue", "Left Click:") .. " Toggle BetterFriendlist", nil, "LEFT", 8)
	local hint6 = tt:AddLine()
	tt:SetCell(hint6, 1, C("ltblue", "Right Click:") .. " Settings • " .. C("ltblue", "Middle Click:") .. " Cycle Filter",
		nil, "LEFT", 8)

	tt:Show()
	return tt
end

-- ========================================
-- LibQTip Detail Tooltip (Two-Tier System)
-- ========================================

local detailTooltip = nil
local detailTooltipKey = "BetterFriendlistBrokerDetailTT"

-- Create detail tooltip on friend line hover
local function CreateDetailTooltip(cell, data)
	if not LQT or not data then return end

	-- Release previous detail tooltip if exists
	if detailTooltip then
		LQT:Release(detailTooltip)
		detailTooltip = nil
	end

	-- Create 3-column detail tooltip
	local tt2 = LQT:Acquire(detailTooltipKey, 3, "LEFT", "RIGHT", "RIGHT")
	tt2:Clear()
	tt2:SmartAnchorTo(cell)
	tt2:SetAutoHideDelay(0.25, tooltip)
	tt2:SetFrameStrata("HIGH") -- Lower than TOOLTIP so context menus appear above
	tt2:UpdateScrolling()

	-- Header with character/account name
	local headerLine = tt2:AddHeader()
	local displayName = data.characterName and data.characterName ~= "" and data.characterName or data.accountName or
	"Unknown"
	tt2:SetCell(headerLine, 1, C("dkyellow", displayName), "GameFontNormalLarge", "LEFT", 3)
	tt2:AddSeparator()

	-- Status info
	if data.isAFK or data.isDND then
		local statusIcon = GetStatusIcon(data.isAFK, data.isDND)
		local statusText = data.isAFK and "Away" or "Do Not Disturb"
		local statusLine = tt2:AddLine(C("ltblue", "Status:"), "", "")
		tt2:SetCell(statusLine, 2, statusIcon .. " " .. C("gold", statusText), nil, "RIGHT", 2)
	end

	-- Game/Client info with icon
	if data.client then
		local clientInfo = GetClientInfo(data.client)
		local gameLine = tt2:AddLine(C("ltblue", "Game:"), "", "")
		tt2:SetCell(gameLine, 2, clientInfo.iconStr .. " " .. clientInfo.long, nil, "RIGHT", 2)
	end

	-- WoW-specific details
	if data.client == "WoW" then
		-- Realm
		if data.realmName and data.realmName ~= "" then
			local realmLine = tt2:AddLine(C("ltblue", "Realm:"), data.realmName, "")
			tt2:SetCell(realmLine, 2, data.realmName, nil, "RIGHT", 2)
		end

		-- Class (with color)
		if data.className and data.className ~= "UNKNOWN" then
			local classLine = tt2:AddLine(C("ltblue", "Class:"), "", "")
			tt2:SetCell(classLine, 2, C(data.className, _G[data.className] or data.className), nil, "RIGHT", 2)
		end

		-- Faction with icon
		if data.factionName and data.factionName ~= "" then
			local factionIcon = GetFactionIcon(data.factionName)
			local factionLine = tt2:AddLine(C("ltblue", "Faction:"), "", "")
			tt2:SetCell(factionLine, 2, factionIcon .. " " .. data.factionName, nil, "RIGHT", 2)
		end
	end

	-- Zone/Area
	if data.area and data.area ~= "" then
		local zoneLine = tt2:AddLine(C("ltblue", "Zone:"), "", "")
		tt2:SetCell(zoneLine, 2, data.area, nil, "RIGHT", 2)
	end

	-- Notes
	if data.note and data.note ~= "" then
		tt2:AddSeparator()
		local notesHeaderLine = tt2:AddLine()
		tt2:SetCell(notesHeaderLine, 1, C("ltblue", "Note:"), nil, "LEFT", 3)
		tt2:AddSeparator()
		local notesLine = tt2:AddLine()
		tt2:SetCell(notesLine, 1, C("white", data.note), nil, "LEFT", 3)
	end

	-- Broadcast message (BNet only)
	if data.type == "bnet" and data.broadcast and data.broadcast ~= "" then
		tt2:AddSeparator()
		local broadcastHeaderLine = tt2:AddLine()
		tt2:SetCell(broadcastHeaderLine, 1, C("ltblue", "Broadcast:"), nil, "LEFT", 3)
		tt2:AddSeparator()
		local broadcastLine = tt2:AddLine()
		tt2:SetCell(broadcastLine, 1, C("white", data.broadcast), nil, "LEFT", 3)

		-- Broadcast time
		if data.broadcastTime then
			local timeSince = time() - data.broadcastTime
			local timeText = SecondsToTime(timeSince)
			local timeLine = tt2:AddLine()
			tt2:SetCell(timeLine, 1, C("ltgray", string.format("(Active since: %s)", timeText)), nil, "RIGHT", 3)
		end
	end

	tt2:Show()
	detailTooltip = tt2
end

-- Release detail tooltip on mouse leave
local function ReleaseDetailTooltip()
	if LQT and detailTooltip then
		LQT:Release(detailTooltip)
		detailTooltip = nil
	end
end

-- ========================================
-- Click Handlers (Data Broker)
-- ========================================

function Broker:OnClick(clickedFrame, button)
	-- Safety: Don't process clicks in combat
	if InCombatLockdown() then
		BFL:DebugPrint("Broker: Clicks disabled in combat")
		return
	end

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then return end

	if button == "LeftButton" then
		-- Left Click: Check config for action
		local action = BetterFriendlistDB.brokerClickAction or "toggle"

		if action == "toggle" then
			-- Toggle BetterFriendlist frame
			ToggleFriendsFrame(1)
		elseif action == "friends" then
			-- Open Blizzard FriendsFrame directly (bypasses our hook)
			if BFL.ShowBlizzardFriendsFrame then
				BFL.ShowBlizzardFriendsFrame()
			elseif BFL.OriginalToggleFriendsFrame then
				BFL.OriginalToggleFriendsFrame(1)
			else
				ToggleFriendsFrame(1)
			end
		elseif action == "settings" then
			-- Open BFL Settings
			local Settings = BFL:GetModule("Settings")
			if Settings then
				Settings:Show()
			end
		end
	elseif button == "RightButton" then
		-- Right Click: Open FriendsList (if not already open) AND open Settings (Broker tab)
		
		-- First, ensure FriendsList is open
		if not (FriendsFrame and FriendsFrame:IsShown()) then
			ToggleFriendsFrame(1)
		end
		
		-- Then open Settings
		local Settings = BFL:GetModule("Settings")
		if Settings then
			if BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
				Settings:Hide()
			else
				Settings:Show()
				Settings:ShowTab(4) -- Data Broker tab
			end
		end
	elseif button == "MiddleButton" then
		-- Middle Click: Cycle quick filter
		local currentFilter = BetterFriendlistDB.quickFilter or "all"
		local currentIndex = 1

		-- Find current filter index
		for i, filter in ipairs(FILTER_CYCLE) do
			if filter == currentFilter then
				currentIndex = i
				break
			end
		end

		-- Next filter
		local nextIndex = (currentIndex % #FILTER_CYCLE) + 1
		local nextFilter = FILTER_CYCLE[nextIndex]

		-- Apply filter using the global setter function
		-- This updates filterMode, DB, and refreshes the friends list
		if BetterFriendsFrame_SetQuickFilter then
			BetterFriendsFrame_SetQuickFilter(nextFilter)
		else
			-- Fallback: Direct DB update only
			if BetterFriendlistDB then
				BetterFriendlistDB.quickFilter = nextFilter
			end
		end

		-- Close current tooltip and recreate with new filter
		-- The tooltip will read the updated value from BetterFriendlistDB.quickFilter
		if LQT and tooltip then
			LQT:Release(tooltip)
			tooltip = nil
		end

		-- Recreate tooltip immediately with updated filter
		if LQT and dataObject and dataObject.OnEnter and clickedFrame then
			-- Immediate update for crisp UI response
			if clickedFrame then
				tooltip = CreateLibQTipTooltip(clickedFrame)
			end
			-- Update broker text
			self:UpdateBrokerText()

			-- Show confirmation message
			local filterName = nextFilter:sub(1, 1):upper() .. nextFilter:sub(2)
			print(string.format(L("BROKER_FILTER_CHANGED"), filterName))

			BFL:DebugPrint(string.format("Broker: Filter cycled to '%s'", nextFilter))
		end
	end
end

-- ========================================
-- Public API
-- ========================================

function Broker:Initialize()
	BFL:DebugPrint("Broker: Initializing...")

	-- BETA FEATURE CHECK: Only initialize if Beta Features are enabled
	if not BetterFriendlistDB or not BetterFriendlistDB.enableBetaFeatures then
		BFL:DebugPrint("Broker: Beta Features not enabled - Data Broker integration disabled")
		return
	end

	-- Check if LibDataBroker is available
	if not LDB then
		BFL:DebugPrint("Broker: LibDataBroker-1.1 not found - Data Broker integration disabled")
		return
	end
	-- Check if LibQTip is available
	if not LQT then
		BFL:DebugPrint("Broker: LibQTip-1.0 not available - tooltips will be basic")
	else
		BFL:DebugPrint("Broker: LibQTip-1.0 loaded successfully")
	end
	-- Check if enabled in config
	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		BFL:DebugPrint("Broker: Database not initialized yet")
		return
	end

	if not BetterFriendlistDB.brokerEnabled then
		BFL:DebugPrint("Broker: Disabled in settings")
		return
	end

	-- Create Data Broker object
	dataObject = LDB:NewDataObject("BetterFriendlist", {
		type = "data source",
		text = "Friends: 0/0",
		icon = "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp",
		label = L("BROKER_TITLE"),

		OnEnter = function(anchorFrame)
			-- Use LibQTip if available, otherwise fall back to GameTooltip
			if LQT then
				tooltip = CreateLibQTipTooltip(anchorFrame)
			end
		end,

		-- OnLeave removed - LibQTip's SetAutoHideDelay handles tooltip hiding
		-- This allows the tooltip to stay visible when hovering over it

		OnTooltipShow = function(gameTooltip)
			-- Fallback for display addons that use OnTooltipShow (without LibQTip support)
			if not LQT and gameTooltip and gameTooltip.AddLine then
				-- Choose tooltip mode
				if BetterFriendlistDB.brokerTooltipMode == "advanced" then
					CreateAdvancedTooltip(gameTooltip)
				else
					CreateBasicTooltip(gameTooltip)
				end
			end
		end,

		OnClick = function(clickedFrame, button)
			Broker:OnClick(clickedFrame, button)
		end,
	})

	if dataObject then
		BFL:DebugPrint("Broker: Data Broker object created successfully")

		-- Register events for auto-update
		self:RegisterEvents()

		-- Initial text update
		self:UpdateBrokerText()
	else
		BFL:DebugPrint("Broker: Failed to create Data Broker object")
	end
end

function Broker:RegisterEvents()
	-- BETA FEATURE CHECK: Only register events if Beta Features are enabled
	if not BetterFriendlistDB or not BetterFriendlistDB.enableBetaFeatures then
		return
	end
	
	-- Check if enabled in broker settings
	if not BetterFriendlistDB.brokerEnabled then
		return
	end

	if not dataObject then
		BFL:DebugPrint("Broker: Events not registered - no data object")
		return
	end

	BFL:DebugPrint("Broker: Registering events...")

	-- Friend status events
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

	BFL:DebugPrint("Broker: Events registered")
end

-- ========================================
-- Slash Command Support
-- ========================================

function Broker:ToggleEnabled()
	if not BetterFriendlistDB then
		BFL:DebugPrint("|cffff0000BetterFriendlist:|r Database not initialized")
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
