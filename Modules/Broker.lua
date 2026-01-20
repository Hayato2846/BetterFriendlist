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
			-- BFL:DebugPrint(string.format("Broker: Unknown game client '%s' - using fallback icon", tostring(clientProgram)))
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
local function GetStatusIcon(isAFK, isDND, isMobile)
	local showMobileAsAFK = BetterFriendlistDB and BetterFriendlistDB.showMobileAsAFK

	if isAFK or (isMobile and showMobileAsAFK) then
		return "|TInterface\\FriendsFrame\\StatusIcon-Away:12:12:0:0:32:32:5:27:5:27|t"
	elseif isDND then
		return "|TInterface\\FriendsFrame\\StatusIcon-DnD:12:12:0:0:32:32:5:27:5:27|t"
	else
		return "|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:0:32:32:5:27:5:27|t"
	end
end

-- Convert localized className to classFile (e.g., "Krieger" -> "WARRIOR")
-- Logic moved to BFL.ClassUtils
local function GetClassFileFromClassName(className)
	return BFL.ClassUtils:GetClassFileFromClassName(className)
end

-- Get classFile for friend data (prioritizes classID for 11.2.7+)
local function GetClassFileForFriend(friend)
	return BFL.ClassUtils:GetClassFileForFriend(friend)
end

-- Get class color for friend (returns color table or white fallback)
local function GetClassColorForFriend(friend)
	return BFL.ClassUtils:GetClassColorForFriend(friend)
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
			-- BFL:DebugPrint("Broker: BNet friend not in WoW, cannot invite/join")
			return
		end
		
		if isLeader then
			-- We can invite: Use BNInviteFriend
			BNInviteFriend(data.gameAccountID)
			-- BFL:DebugPrint(string.format("Broker: Invited BNet friend %s", data.accountName or "Unknown"))
		else
			-- We need to request to join their group
			-- For BNet friends, we need to use their character name
			if data.characterName and data.characterName ~= "" then
				local targetName = data.characterName
				if data.realmName and data.realmName ~= "" and data.realmName ~= GetRealmName() then
					targetName = targetName .. "-" .. data.realmName
				end
				C_PartyInfo.RequestInviteFromUnit(targetName)
				-- BFL:DebugPrint(string.format("Broker: Requested invite from %s", targetName))
			else
				-- BFL:DebugPrint("Broker: Cannot request invite - no character name")
			end
		end
		
	elseif friendType == "wow" then
		-- WoW friend
		local targetName = data.fullName or data.characterName
		if not targetName then
			-- BFL:DebugPrint("Broker: WoW friend has no name, cannot invite/join")
			return
		end
		
		if isLeader then
			-- We can invite
			C_PartyInfo.InviteUnit(targetName)
			-- BFL:DebugPrint(string.format("Broker: Invited WoW friend %s", targetName))
		else
			-- We need to request to join their group
			C_PartyInfo.RequestInviteFromUnit(targetName)
			-- BFL:DebugPrint(string.format("Broker: Requested invite from %s", targetName))
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
		-- BFL:DebugPrint("Broker: MenuSystem not available")
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
				accountInfo = data.accountInfo,
				index = data.index,
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "BN", bnetAccountID, extraData)
			-- BFL:DebugPrint(string.format("Broker: Opening BNet context menu for %s", data.accountName or "Unknown"))
		else
			-- BFL:DebugPrint("Broker: Could not get bnetAccountID for context menu")
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
				index = friendIndex,
			}
			MenuSystem:OpenFriendMenu(contextMenuAnchor, "WOW", friendIndex, extraData)
			-- BFL:DebugPrint(string.format("Broker: Opening WoW context menu for %s", data.characterName or "Unknown"))
		else
			-- BFL:DebugPrint("Broker: Could not find friend index for context menu")
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
					-- BFL:DebugPrint(string.format("Broker: Copied '%s' to chat editbox", data.characterName))
				end
			else
				-- BFL:DebugPrint("Broker: BNet friend not in WoW, cannot copy character name")
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
				-- BFL:DebugPrint(string.format("Broker: Opening BNet whisper to %s (ID: %d)", data.accountName or "Unknown", data.bnetAccountID))
			elseif data.accountName and data.accountName ~= "" then
				-- Fallback: try ChatFrame_SendSmartTell
				ChatFrame_SendSmartTell(data.accountName)
				-- BFL:DebugPrint(string.format("Broker: Opening BNet whisper to %s", data.accountName))
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
					-- BFL:DebugPrint(string.format("Broker: Copied '%s' to chat editbox", data.characterName))
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
				-- BFL:DebugPrint(string.format("Broker: Opening whisper to %s", whisperName))
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
	local showLabel = BetterFriendlistDB.brokerShowLabel ~= false -- Default true
	local showTotal = BetterFriendlistDB.brokerShowTotal ~= false -- Default true
	
	if BetterFriendlistDB.brokerShowGroups then
		-- Split display: "[Icon] 5/10 | [Icon] 3/8"
		local wowText = showTotal and string.format("%d/%d", wowOnline, wowTotal) or tostring(wowOnline)
		local bnetText = showTotal and string.format("%d/%d", bnetOnline, bnetTotal) or tostring(bnetOnline)
		
		-- Use modern texture paths for icons (matching FriendsFrame style)
		-- WoW Icon: 939375 (Requested by user) - Zoomed in (cropped) to match visual weight
		local wowIcon = "|T939375:16:16:0:0:64:64:5:59:5:59|t"
		-- BNet Icon: Custom "All Friends" icon from QuickFilter
		local bnetIcon = "|TInterface\\AddOns\\BetterFriendlist\\Icons\\filter-all:16:16:0:0|t"
		
		-- Check visibility settings (default to true if nil)
		local showWoWIcon = BetterFriendlistDB.brokerShowWoWIcon ~= false
		local showBNetIcon = BetterFriendlistDB.brokerShowBNetIcon ~= false
		
		local wowPart = (showWoWIcon and (wowIcon .. " ") or "") .. wowText
		local bnetPart = (showBNetIcon and (bnetIcon .. " ") or "") .. bnetText
		
		text = string.format("%s | %s", wowPart, bnetPart)
		
		if showLabel then
			text = L("BROKER_LABEL_FRIENDS") .. text
		end
	else
		-- Combined display: "Friends: 8/18"
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
		dataObject.icon = nil -- Hide icon
	end

	-- BFL:DebugPrint(string.format("Broker: Updated text to '%s'", text))
end

-- ========================================
-- Tooltip Functions
-- ========================================

-- Basic Tooltip
local function CreateBasicTooltip(tooltip)
	tooltip:AddLine(L("BROKER_TITLE"), 1, 0.82, 0, 1)
	tooltip:AddLine(" ")

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()

	-- Summary
	tooltip:AddDoubleLine(L("BROKER_WOW_FRIENDS"), string.format(L("BROKER_ONLINE_TOTAL"), wowOnline, wowTotal), 1, 1, 1, 0, 1, 0)
	tooltip:AddDoubleLine(L("BROKER_HEADER_BNET"), string.format(L("BROKER_ONLINE_TOTAL"), bnetOnline, bnetTotal), 1, 1, 1, 0, 0.5,
		1)
	tooltip:AddLine(" ")

	-- Get current filter
	local QuickFilters = GetQuickFilters()
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	-- Localize current filter text
	if QuickFilters then
		local filterText = QuickFilters:GetFilterText()
		if filterText then currentFilter = filterText end
	end
	tooltip:AddDoubleLine(L("BROKER_CURRENT_FILTER"), currentFilter, 1, 1, 1, 1, 1, 0)

	tooltip:AddLine(" ")
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine(L("BROKER_HINT_CYCLE_FILTER_FULL"), 0.5, 0.9, 1, 1)
end

-- Advanced Tooltip with Groups and Activity
local function CreateAdvancedTooltip(tooltip)
	tooltip:AddLine(L("BROKER_TITLE"), 1, 0.82, 0, 1)
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
					tooltip:AddLine(string.format(L("BROKER_AND_MORE"), #groupFriends - 5), 0.7, 0.7, 0.7)
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
							activityText = string.format(L("BROKER_WHISPER_AGO"), timeStr)
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
		tooltip:AddLine(L("GROUP_NO_GROUP"), 0.7, 0.7, 0.7, 1)
		for i, friend in ipairs(ungrouped) do
			if i > 5 then
				tooltip:AddLine(string.format(L("BROKER_AND_MORE"), #ungrouped - 5), 0.7, 0.7, 0.7)
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
		tooltip:AddLine(L("BROKER_NO_FRIENDS_ONLINE"), 0.7, 0.7, 0.7)
		tooltip:AddLine(" ")
	end

	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()
	tooltip:AddDoubleLine(L("BROKER_TOTAL_LABEL"), string.format(L("BROKER_ONLINE_FRIENDS_COUNT"), wowOnline + bnetOnline, wowTotal + bnetTotal),
		1, 1, 1, 0, 1, 0)

	-- Current filter
	local currentFilter = BetterFriendlistDB and BetterFriendlistDB.quickFilter or "all"
	-- Localize current filter text
	if GetQuickFilters() then
		local filterText = GetQuickFilters():GetFilterText()
		if filterText then currentFilter = filterText end
	end
	tooltip:AddDoubleLine(L("BROKER_FILTER_LABEL"), currentFilter, 1, 1, 1, 1, 1, 0)

	tooltip:AddLine(" ")
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_LEFT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine(L("BROKER_TOOLTIP_FOOTER_RIGHT"), 0.5, 0.9, 1, 1)
	tooltip:AddLine(L("BROKER_HINT_CYCLE_FILTER_FULL"), 0.5, 0.9, 1, 1)
end

-- ========================================
-- LibQTip Tooltip (NEW)
-- ========================================

-- Helper: Get display name (respects nameDisplayFormat and tokens)
local function GetFriendDisplayName(friend)
	local DB = GetDB()
	local format = DB and DB:Get("nameDisplayFormat", "%name%") or "%name%"
	
	-- 1. Prepare Data
	local name = "Unknown"
	local battletag = friend.battleTag or ""
	local note = friend.note or ""
	local nickname = DB and DB:GetNickname(friend.id) or ""
	
	if friend.type == "bnet" then
		-- BNet: Use accountName as requested (RealID or BattleTag)
		name = friend.accountName or "Unknown"
	else
		-- WoW: Name is Character Name
		local fullName = friend.fullName or friend.name or "Unknown"
		local showRealmName = DB and DB:Get("showRealmName", false)
		
		if showRealmName then
			name = fullName
		else
			local n, r = strsplit("-", fullName)
			local playerRealm = GetNormalizedRealmName() -- Use normalized realm
			
			if r and r ~= playerRealm then
				name = n .. "*" -- Indicate cross-realm
			else
				name = n
			end
		end
	end

	-- Process battletag to be short version as requested
	if battletag ~= "" then
		local hashIndex = string.find(battletag, "#")
		if hashIndex then
			battletag = string.sub(battletag, 1, hashIndex - 1)
		end
	end
	
	-- 2. Replace Tokens
	-- Use function replacement to avoid issues with % characters in names
	local result = format

	-- Smart Fallback Logic:
	-- If %nickname% is used but empty, and %name% is NOT in the format, use name as nickname
	if nickname == "" and result:find("%%nickname%%") and not result:find("%%name%%") then
		nickname = name
	end
	-- Same for %battletag% (e.g. for WoW friends)
	if battletag == "" and result:find("%%battletag%%") and not result:find("%%name%%") then
		battletag = name
	end

	result = result:gsub("%%name%%", function() return name end)
	result = result:gsub("%%note%%", function() return note end)
	result = result:gsub("%%nickname%%", function() return nickname end)
	result = result:gsub("%%battletag%%", function() return battletag end)
	
	-- 3. Cleanup
	-- Remove empty parentheses/brackets (e.g. "Name ()" -> "Name")
	result = result:gsub("%(%)", "")
	result = result:gsub("%[%]", "")
	-- Trim whitespace
	result = result:match("^%s*(.-)%s*$")
	
	-- 4. Fallback
	if result == "" then
		return name
	end
	
	return result
end

-- Helper: Get colored level text
local function GetColoredLevelText(level)
	if not level or level == 0 then return "" end
	
	local hideMaxLevel = BetterFriendlistDB and BetterFriendlistDB.hideMaxLevel
	local maxLevel = GetMaxLevelForPlayerExpansion()
	
	if hideMaxLevel and level == maxLevel then
		return ""
	end
	
	local color = GetQuestDifficultyColor(level)
	return string.format("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
end

-- ========================================
-- Fixed Footer Implementation
-- ========================================
local FOOTER_HEIGHT = 160 -- Height for the fixed footer area
local MAX_TOOLTIP_HEIGHT = 690 -- Maximum height for the tooltip before scrolling

local function RenderFixedFooter(footerFrame)
	-- Clear previous content
	if footerFrame.content then
		for _, region in ipairs(footerFrame.content) do
			region:Hide()
		end
	end
	footerFrame.content = {}
	
	local function AddLine(text, font, r, g, b)
		local fs = footerFrame:CreateFontString(nil, "OVERLAY", font or "GameTooltipTextSmall")
		fs:SetText(text)
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false) -- Prevent wrapping to avoid overlap with fixed offsets
		if r then fs:SetTextColor(r, g, b) end
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
	
	-- Total Online
	local wowOnline, wowTotal, bnetOnline, bnetTotal = GetFriendCounts()
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
		status = L("SORT_STATUS"), name = L("SORT_NAME"), level = L("SORT_LEVEL"), zone = L("SORT_ZONE"),
		game = L("SORT_GAME"), faction = L("SORT_FACTION"), guild = L("SORT_GUILD"), class = L("SORT_CLASS"),
		activity = L("SORT_ACTIVITY"), realm = L("SORT_REALM")
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
		activity = "Interface\\AddOns\\BetterFriendlist\\Icons\\activity",
		realm = "Interface\\AddOns\\BetterFriendlist\\Icons\\realm"
	}
	
	local function GetSortDisplay(mode)
		local name = sortNames[mode] or mode
		local icon = sortIcons[mode]
		if icon then return string.format("|T%s:14:14:0:0|t %s", icon, name) end
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
	
	-- Separator
	local sep2 = AddSeparator()
	sep2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	sep2:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", -10, yOffset)
	yOffset = yOffset - 5
	
	-- Hints 1
	local hint1 = AddLine(C("ltgray", L("BROKER_HINT_FRIEND_ACTIONS")), "GameTooltipTextSmall")
	hint1:SetPoint("TOP", footerFrame, "TOP", 0, yOffset)
	yOffset = yOffset - 14
	
	local hint2 = AddLine(C("ltblue", L("BROKER_HINT_CLICK_WHISPER")) .. L("BROKER_HINT_WHISPER") .. C("ltblue", L("BROKER_HINT_RIGHT_CLICK_MENU")) .. L("BROKER_HINT_CONTEXT_MENU"), "GameTooltipTextSmall")
	hint2:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	hint2:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 14
	
	local hint3 = AddLine(C("ltblue", L("BROKER_HINT_ALT_CLICK")) .. L("BROKER_HINT_INVITE") .. C("ltblue", L("BROKER_HINT_SHIFT_CLICK")) .. L("BROKER_HINT_COPY"), "GameTooltipTextSmall")
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
	
	local hint5 = AddLine(C("ltblue", L("BROKER_HINT_LEFT_CLICK")) .. L("BROKER_HINT_TOGGLE"), "GameTooltipTextSmall")
	hint5:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	hint5:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 14
	
	local hint6 = AddLine(C("ltblue", L("BROKER_HINT_RIGHT_CLICK")) .. L("BROKER_HINT_SETTINGS") .. C("ltblue", L("BROKER_HINT_MIDDLE_CLICK")) .. L("BROKER_HINT_CYCLE_FILTER"), "GameTooltipTextSmall")
	hint6:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 10, yOffset)
	hint6:SetPoint("RIGHT", footerFrame, "RIGHT", -10, yOffset)
	yOffset = yOffset - 14
end

-- Helper: Check if any context menu is open
local function IsMenuOpen()
	-- Check Legacy Dropdowns (UIDropDownMenu)
	if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU:IsShown() then return true end
	if _G.Lib_UIDROPDOWNMENU_OPEN_MENU and _G.Lib_UIDROPDOWNMENU_OPEN_MENU:IsShown() then return true end

	-- Check Modern Menu System (11.x C_Menu)
	if Menu and Menu.GetManager then
		local manager = Menu.GetManager()
		if manager and manager:GetOpenMenu() then
			return true
		end
	end
	
	return false
end

-- Helper: Custom AutoHide that respects open menus
local function SetupTooltipAutoHide(tooltip, anchorFrame)
	tooltip:SetAutoHideDelay(nil) -- Disable LibQTip's built-in auto-hide
	
	if not tooltip.bflTimer then
		tooltip.bflTimer = CreateFrame("Frame", nil, tooltip)
	end
	
	local timer = tooltip.bflTimer
	timer.hideTimer = 0
	timer.checkTimer = 0
	
	timer:SetScript("OnUpdate", function(self, elapsed)
		self.checkTimer = self.checkTimer + elapsed
		if self.checkTimer < 0.1 then return end
		
		local checkInterval = self.checkTimer
		self.checkTimer = 0
		
		-- Check if mouse is over tooltip or anchor
		local isOver = tooltip:IsMouseOver() or (anchorFrame and anchorFrame:IsMouseOver())
		
		if isOver then
			self.hideTimer = 0
		else
			-- Mouse is outside
			if IsMenuOpen() then
				self.hideTimer = 0 -- Reset timer if menu is open
			else
				self.hideTimer = self.hideTimer + checkInterval
				if self.hideTimer >= 0.25 then
					if LQT then 
						-- Safely release tooltip
						pcall(function() LQT:Release(tooltip) end)
					end
					self:SetScript("OnUpdate", nil)
				end
			end
		end
	end)
end

local function TooltipCleanup(tooltip)
	if not tooltip then return end
	
	-- Hide our custom footer
	if tooltip.footerFrame then
		tooltip.footerFrame:Hide()
	end
	
	-- Ensure timer script is cleared (prevent leaks)
	if tooltip.bflTimer then
		tooltip.bflTimer:SetScript("OnUpdate", nil)
	end
	
	-- Restore standard LibQTip anchors for ScrollFrame
	if tooltip.scrollFrame then
		tooltip.scrollFrame:ClearAllPoints()
		tooltip.scrollFrame:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -10)
		tooltip.scrollFrame:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
	end
	
	-- Restore standard LibQTip anchors for Slider
	if tooltip.slider then
		tooltip.slider:ClearAllPoints()
		tooltip.slider:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -10, -10)
		tooltip.slider:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
	end
end

local function CreateLibQTipTooltip(anchorFrame)
	if not LQT then
		-- BFL:DebugPrint("Broker: LibQTip not available, skipping tooltip")
		return nil
	end

	-- Define available columns and their default visibility
	local columns = {
		{ key = "Name",      label = L("BROKER_COLUMN_NAME"),      align = "LEFT",   default = true },
		{ key = "Level",     label = L("BROKER_COLUMN_LEVEL"),       align = "CENTER", default = true },
		{ key = "Character", label = L("BROKER_COLUMN_CHARACTER"), align = "LEFT",   default = true },
		{ key = "Game",      label = L("BROKER_COLUMN_GAME"),      align = "LEFT",   default = true },
		{ key = "Zone",      label = L("BROKER_COLUMN_ZONE"),      align = "LEFT",   default = true },
		{ key = "Realm",     label = L("BROKER_COLUMN_REALM"),     align = "LEFT",   default = true },
		{ key = "Notes",     label = L("BROKER_COLUMN_NOTES"),     align = "LEFT",   default = true }
	}
	
	-- Get user-defined column order from DB
	local columnOrder = BetterFriendlistDB and BetterFriendlistDB.brokerColumnOrder
	local activeColumns = {}
	
	if columnOrder and #columnOrder > 0 then
		-- Use user-defined order
		for _, colKey in ipairs(columnOrder) do
			-- Find column definition
			local colDef = nil
			for _, c in ipairs(columns) do
				if c.key == colKey then
					colDef = c
					break
				end
			end
			
			if colDef then
				-- Check visibility
				local settingKey = "brokerShowCol" .. colKey
				if BetterFriendlistDB[settingKey] ~= false then -- Default true
					table.insert(activeColumns, colDef)
				end
			end
		end
	else
		-- Use default order
		for _, col in ipairs(columns) do
			local settingKey = "brokerShowCol" .. col.key
			if BetterFriendlistDB[settingKey] ~= false then -- Default true
				table.insert(activeColumns, col)
			end
		end
	end
	
	-- If no columns selected, force Name
	if #activeColumns == 0 then
		table.insert(activeColumns, columns[1])
	end
	
	-- Build Acquire arguments
	local numColumns = #activeColumns
	local alignArgs = {}
	for _, col in ipairs(activeColumns) do
		table.insert(alignArgs, col.align)
	end

	-- Acquire tooltip
	local tt = LQT:Acquire(tooltipKey, numColumns, unpack(alignArgs))

	-- Hook OnHide to clean up layout changes when tooltip is released/hidden
	-- Always re-hook because LibQTip might clear scripts on Release
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
	tt:SetFrameStrata("HIGH") -- Lower than TOOLTIP so context menus appear above
	
	-- Setup Fixed Footer Frame
	if not tt.footerFrame then
		tt.footerFrame = CreateFrame("Frame", nil, tt)
		tt.footerFrame:SetPoint("BOTTOMLEFT", tt, "BOTTOMLEFT", 0, 0)
		tt.footerFrame:SetPoint("BOTTOMRIGHT", tt, "BOTTOMRIGHT", 0, 0)
		tt.footerFrame:SetHeight(FOOTER_HEIGHT)
	end
	tt.footerFrame:Show()
	
	-- Adjust ScrollFrame to respect footer
	if tt.scrollFrame then
		tt.scrollFrame:ClearAllPoints()
		tt.scrollFrame:SetPoint("TOP", tt, "TOP", 0, -10) -- TOOLTIP_PADDING
		tt.scrollFrame:SetPoint("LEFT", tt, "LEFT", 10, 0)
		tt.scrollFrame:SetPoint("RIGHT", tt, "RIGHT", -10, 0)
		tt.scrollFrame:SetPoint("BOTTOM", tt.footerFrame, "TOP", 0, 0)
	end
	
	-- Render Footer Content
	RenderFixedFooter(tt.footerFrame)
	
	-- Update Scrolling (Initial)
	tt:UpdateScrolling(MAX_TOOLTIP_HEIGHT)

	-- Header
	local headerLine = tt:AddHeader()
	tt:SetCell(headerLine, 1, C("dkyellow", L("BROKER_TITLE")), BetterFriendlistFontNormalLarge, "LEFT", numColumns)
	tt:AddSeparator()

	-- Column Headers
	local headerCells = {}
	for _, col in ipairs(activeColumns) do
		table.insert(headerCells, C("ltyellow", col.label))
	end
	local colLine = tt:AddLine(unpack(headerCells))
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
	
	-- Initialize for all known groups
	for groupId, groupData in pairs(groupsData) do
		groupCounts[groupId] = { total = 0, online = 0 }
		groupedFriends[groupId] = {}
	end
	-- Ensure nogroup exists if not in groupsData
	if not groupCounts["nogroup"] then
		groupCounts["nogroup"] = { total = 0, online = 0 }
		groupedFriends["nogroup"] = {}
	end

	-- Helper to process a friend (add to groups and counts)
	local function ProcessFriend(friend)
		local friendGroups = BetterFriendlistDB and BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friend.id] or {}
		local assigned = false
		local isOnline = friend.connected

		-- Check Favorites (BNet only)
		if friend.type == "bnet" and friend.isFavorite then
			-- Only if favorites group is active (in groupsData)
			if groupsData["favorites"] then
				groupCounts["favorites"].total = groupCounts["favorites"].total + 1
				if isOnline then
					groupCounts["favorites"].online = groupCounts["favorites"].online + 1
					table.insert(groupedFriends["favorites"], friend)
				end
				assigned = true
			end
		end

		-- Check Custom Groups
		for _, groupId in ipairs(friendGroups) do
			if groupsData[groupId] then
				groupCounts[groupId].total = groupCounts[groupId].total + 1
				if isOnline then
					groupCounts[groupId].online = groupCounts[groupId].online + 1
					table.insert(groupedFriends[groupId], friend)
				end
				assigned = true
			end
		end

		-- Check No Group
		if not assigned then
			-- Ensure nogroup exists in counts
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
				
				-- Check mobile setting
				local isMobile = (client == "BSAp")
				if treatMobileAsOffline and isMobile then
					isOnline = false
				end
				
				-- Create friend object
				local friendUID = accountInfo.battleTag and ("bnet_" .. accountInfo.battleTag) or ("bnet_" .. tostring(accountInfo.bnetAccountID))
				
				local friend = {
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
					guildName = gameInfo.guildName or "",
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
				
				ProcessFriend(friend)
			end
		end
	end

	-- Collect WoW Friends (ALL)
	local numWoWFriends = C_FriendList.GetNumFriends()
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
		for groupId, friends in pairs(groupedFriends) do
			local filteredFriends = {}
			for _, friend in ipairs(friends) do
				local include = false

				if currentFilter == "online" then
					include = true -- already only online friends in groupedFriends
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
			groupedFriends[groupId] = filteredFriends
		end
	end

	-- Apply current sort mode (simplified sorting for tooltip)
	local primarySort = BetterFriendlistDB and BetterFriendlistDB.primarySort or "status"
	local secondarySort = BetterFriendlistDB and BetterFriendlistDB.secondarySort or "name"
	
	-- Simple sort comparator for tooltip
	local function CompareFriends(a, b)
		-- Helper to compare by a specific mode
		local function CompareByMode(mode, a, b)
			if mode == "name" then
				-- Use the centralized GetFriendDisplayName function to ensure sorting matches display
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
			elseif mode == "status" then
				-- Sort by DND/AFK priority (Online=0, DND=1, AFK=2)
				local function GetStatusPriority(friend)
					if friend.isDND then return 1 end
					if friend.isAFK or friend.isMobile then return 2 end
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
			return nil -- Equal
		end

		-- Primary Sort
		local primaryResult = CompareByMode(primarySort, a, b)
		if primaryResult ~= nil then return primaryResult end

		-- Secondary Sort
		if secondarySort and secondarySort ~= primarySort and secondarySort ~= "none" then
			local secondaryResult = CompareByMode(secondarySort, a, b)
			if secondaryResult ~= nil then return secondaryResult end
		end

		-- Fallback: Name
		return CompareByMode("name", a, b)
	end
	
	-- Sort each group
	for groupId, friends in pairs(groupedFriends) do
		table.sort(friends, CompareFriends)
	end

	local displayedCount = 0

	-- Helper to render a friend row
	local function RenderFriendRow(friend, indentation)
		local nameText = friend.characterName ~= "" and friend.characterName or friend.accountName
		
		-- Add Timerunning icon if applicable
		if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
			nameText = TimerunningUtil.AddSmallIcon(nameText)
		end

		local statusIcon = GetStatusIcon(friend.isAFK, friend.isDND, friend.isMobile)
		local clientInfo = GetClientInfo(friend.client)
		
		-- Faction Icon logic
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
		if colorClassNames == nil then colorClassNames = true end -- Default true

		local isOppositeFaction = friend.factionName and friend.factionName ~= playerFactionGroup and friend.factionName ~= ""
		local shouldGray = grayOtherFaction and isOppositeFaction

		-- Determine Name Column Color
		local nameColor = "|cffffffff" -- Default white
		if shouldGray then
			nameColor = "|cff808080"
		elseif friend.type == "bnet" then
			nameColor = FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff" -- BNet Blue
		elseif friend.type == "wow" then
			if colorClassNames then
				local classColor = GetClassColorForFriend(friend)
				nameColor = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
			else
				nameColor = "|cffffffff"
			end
		end

		local cellValues = {}
		for _, col in ipairs(activeColumns) do
			local val = ""
			if col.key == "Name" then
				-- Prepend status icon
				local prefix = indentation .. statusIcon .. " "
				val = prefix .. nameColor .. GetFriendDisplayName(friend) .. "|r"
			elseif col.key == "Level" then
				val = GetColoredLevelText(friend.level)
			elseif col.key == "Character" then
				-- Only show if we have a character name
				if friend.characterName and friend.characterName ~= "" then
					-- Add faction icon if enabled (matches FriendsList behavior)
					local displayCharName = nameText
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
		
		local line = tt:AddLine(unpack(cellValues))

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
		
		return line
	end

	-- Display Battle.Net Friends Header
	-- if BNConnected() then
	-- 	local bnetLine = tt:AddLine()
	-- 	tt:SetCell(bnetLine, 1, C("ltgray", L("BROKER_HEADER_BNET")), nil, "LEFT", numColumns)
	-- end

	-- Get sorted group IDs for consistent display order (INCLUDE "nogroup" now)
	local sortedGroupIds = Groups and Groups.GetSortedGroupIds and Groups:GetSortedGroupIds(true) or {}

	-- Display grouped friends (BNet and WoW) in configured order
	for _, groupId in ipairs(sortedGroupIds) do
		local groupFriends = groupedFriends[groupId]
		local counts = groupCounts[groupId]
		
		-- Only show if there are online friends
		if groupFriends and #groupFriends > 0 then
			local groupInfo = groupsData[groupId]
			-- Handle nogroup special case if not in groupsData
			if not groupInfo and groupId == "nogroup" then
				groupInfo = { name = L("GROUP_NO_GROUP"), color = {r=0.5, g=0.5, b=0.5}, builtin = true }
			end
			
			if groupInfo then
				local groupLine = tt:AddLine()
				
				-- Calculate color
				local colorCode = "ffffffff" -- Default white
				if groupInfo.color then
					colorCode = string.format("ff%02x%02x%02x", groupInfo.color.r * 255, groupInfo.color.g * 255, groupInfo.color.b * 255)
				end
				
				-- Header text with color and count (Online/Total)
				local countText = string.format("%d/%d", counts.online, counts.total)
				
				-- Add collapse indicator
				local collapsed = groupInfo.collapsed
				local prefix = collapsed and "(+) " or "(-) "
				
				local headerText = string.format("|c%s%s%s|r (%s)", colorCode, prefix, groupInfo.name, countText)
				tt:SetCell(groupLine, 1, "  " .. headerText, nil, "LEFT", numColumns)
				
				-- Hover Highlight for Group Header (Visual Feedback)
				tt:SetLineScript(groupLine, "OnEnter", function(self)
					tt:SetLineColor(groupLine, 0.2, 0.2, 0.2, 0.5)
				end)
				tt:SetLineScript(groupLine, "OnLeave", function(self)
					tt:SetLineColor(groupLine, 0, 0, 0, 0)
				end)
				
				-- Click Handler for Group Header
				tt:SetLineScript(groupLine, "OnMouseUp", function(self, button)
					-- LibQTip might not pass the button argument correctly in all versions
					-- Use GetMouseButtonClicked() as fallback (standard WoW API since 10.0)
					local actualButton = button or (GetMouseButtonClicked and GetMouseButtonClicked())
					
					-- Debug print to verify click is registered
					-- BFL:DebugPrint("Broker: Group header clicked - " .. tostring(actualButton) .. " on group " .. tostring(groupId))
					
					if actualButton == "LeftButton" then
						-- Toggle collapse state
						if Groups and Groups.Toggle then
							Groups:Toggle(groupId)
							-- Refresh tooltip to show/hide friends
							if Broker.RefreshTooltip then
								Broker:RefreshTooltip()
							end
						end
					elseif actualButton == "RightButton" then
						-- Context Menu
						if MenuUtil and MenuUtil.CreateContextMenu then
							MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
								rootDescription:CreateTitle(groupInfo.name)
								
								-- Only show options for custom groups (not builtin)
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
						else
							-- BFL:DebugPrint("Broker: MenuUtil not available")
						end
					end
				end)

				-- Render friends ONLY if not collapsed
				if not collapsed then
					for i, friend in ipairs(groupFriends) do
						RenderFriendRow(friend, "    ") -- 4 spaces indentation for grouped friends
						displayedCount = displayedCount + 1
					end
				end
			end
		end
	end

	-- Footer (Empty check only)
	if displayedCount == 0 then
		tt:AddSeparator()
		local emptyLine = tt:AddLine()
		tt:SetCell(emptyLine, 1, C("gray", L("BROKER_NO_FRIENDS_ONLINE")), nil, "CENTER", numColumns)
	end

	-- Update Scrolling with Max Height (adjusted for footer)
	local maxContentHeight = MAX_TOOLTIP_HEIGHT - FOOTER_HEIGHT
	tt:UpdateScrolling(maxContentHeight)
	
	-- Add space for footer to the calculated height
	tt:SetHeight(tt:GetHeight() + FOOTER_HEIGHT)
	
	-- Fix Slider Anchor (must stop at footer)
	if tt.slider and tt.slider:IsShown() then
		tt.slider:ClearAllPoints()
		tt.slider:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10)
		tt.slider:SetPoint("BOTTOMRIGHT", tt.footerFrame, "TOPRIGHT", -10, 0)
		
		-- Re-adjust scrollframe right point to accommodate slider
		if tt.scrollFrame then
			tt.scrollFrame:SetPoint("RIGHT", tt, "RIGHT", -30, 0) -- 10 padding + 20 slider space
		end
	end

	tt:Show()
	end, geterrorhandler())

	if not status then
		-- BFL:DebugPrint("Broker: Error populating tooltip: " .. tostring(err))
		tt:Clear()
		tt:AddLine(L("ERROR_TOOLTIP_DISPLAY"))
		tt:AddLine(tostring(err))
		tt:Show()
		SetupTooltipAutoHide(tt, anchorFrame)
	end

	return tt
end

-- Refresh the tooltip (re-create it) to update content
function Broker:RefreshTooltip()
	if LQT and tooltip and tooltip:IsShown() then
		local anchor = tooltip.anchorFrame
		LQT:Release(tooltip)
		tooltip = nil
		if anchor then
			tooltip = CreateLibQTipTooltip(anchor)
		end
	end
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
	tt2:SetCell(headerLine, 1, C("dkyellow", displayName), BetterFriendlistFontNormalLarge, "LEFT", 3)
	tt2:AddSeparator()

	-- Status info
	if data.isAFK or data.isDND then
		local statusIcon = GetStatusIcon(data.isAFK, data.isDND)
		local statusText = data.isAFK and L("STATUS_AWAY") or L("STATUS_DND_FULL")
		local statusLine = tt2:AddLine(C("ltblue", L("STATUS_LABEL")), "", "")
		tt2:SetCell(statusLine, 2, statusIcon .. " " .. C("gold", statusText), nil, "RIGHT", 2)
	end

	-- Game/Client info with icon
	if data.client then
		local clientInfo = GetClientInfo(data.client)
		local gameLine = tt2:AddLine(C("ltblue", L("GAME_LABEL")), "", "")
		tt2:SetCell(gameLine, 2, clientInfo.iconStr .. " " .. clientInfo.long, nil, "RIGHT", 2)
	end

	-- WoW-specific details
	if data.client == "WoW" then
		-- Realm
		if data.realmName and data.realmName ~= "" then
			local realmLine = tt2:AddLine(C("ltblue", L("REALM_LABEL")), data.realmName, "")
			tt2:SetCell(realmLine, 2, data.realmName, nil, "RIGHT", 2)
		end

		-- Class (with color)
		if data.className and data.className ~= "UNKNOWN" then
			local classLine = tt2:AddLine(C("ltblue", L("CLASS_LABEL")), "", "")
			tt2:SetCell(classLine, 2, C(data.className, _G[data.className] or data.className), nil, "RIGHT", 2)
		end

		-- Faction with icon
		if data.factionName and data.factionName ~= "" then
			local factionIcon = GetFactionIcon(data.factionName)
			local factionLine = tt2:AddLine(C("ltblue", L("FACTION_LABEL")), "", "")
			tt2:SetCell(factionLine, 2, factionIcon .. " " .. data.factionName, nil, "RIGHT", 2)
		end
	end

	-- Zone/Area
	if data.area and data.area ~= "" then
		local zoneLine = tt2:AddLine(C("ltblue", L("ZONE_LABEL")), "", "")
		tt2:SetCell(zoneLine, 2, data.area, nil, "RIGHT", 2)
	end

	-- Notes
	if data.note and data.note ~= "" then
		tt2:AddSeparator()
		local notesHeaderLine = tt2:AddLine()
		tt2:SetCell(notesHeaderLine, 1, C("ltblue", L("NOTE_LABEL")), nil, "LEFT", 3)
		tt2:AddSeparator()
		local notesLine = tt2:AddLine()
		tt2:SetCell(notesLine, 1, C("white", data.note), nil, "LEFT", 3)
	end

	-- Broadcast message (BNet only)
	if data.type == "bnet" and data.broadcast and data.broadcast ~= "" then
		tt2:AddSeparator()
		local broadcastHeaderLine = tt2:AddLine()
		tt2:SetCell(broadcastHeaderLine, 1, C("ltblue", L("BROADCAST_LABEL")), nil, "LEFT", 3)
		tt2:AddSeparator()
		local broadcastLine = tt2:AddLine()
		tt2:SetCell(broadcastLine, 1, C("white", data.broadcast), nil, "LEFT", 3)

		-- Broadcast time
		if data.broadcastTime then
			local timeSince = time() - data.broadcastTime
			local timeText = SecondsToTime(timeSince)
			local timeLine = tt2:AddLine()
			tt2:SetCell(timeLine, 1, C("ltgray", string.format(L("ACTIVE_SINCE_FMT"), timeText)), nil, "RIGHT", 3)
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
		-- BFL:DebugPrint("Broker: Clicks disabled in combat")
		return
	end

	local DB = GetDB()
	if not DB or not BetterFriendlistDB then return end

	local action = "none"
	if button == "LeftButton" then
		action = BetterFriendlistDB.brokerClickAction or "toggle"
	elseif button == "RightButton" then
		action = BetterFriendlistDB.brokerRightClickAction or "settings"
	elseif button == "MiddleButton" then
		action = "cycle_filter"
	end

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
			if BetterFriendlistSettingsFrame and BetterFriendlistSettingsFrame:IsShown() then
				Settings:Hide()
			else
				Settings:Show()
				Settings:ShowTab(4) -- Data Broker tab
			end
		end
	elseif action == "bnet" then
		-- Open Friends Frame (Standard)
		ToggleFriendsFrame(1)
	elseif action == "cycle_filter" then
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
		
		-- Force refresh to ensure UI updates immediately (fixes sync issue)
		BFL:ForceRefreshFriendsList()

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

			-- BFL:DebugPrint(string.format("Broker: Filter cycled to '%s'", nextFilter))
		end
	end
end

-- ========================================
-- Public API
-- ========================================

function Broker:Initialize()
	-- BFL:DebugPrint("Broker: Initializing...")

	-- BETA FEATURE CHECK: Only initialize if Beta Features are enabled
	if not BetterFriendlistDB or not BetterFriendlistDB.enableBetaFeatures then
		-- BFL:DebugPrint("Broker: Beta Features not enabled - Data Broker integration disabled")
		return
	end

	-- Check if LibDataBroker is available
	if not LDB then
		-- BFL:DebugPrint("Broker: LibDataBroker-1.1 not found - Data Broker integration disabled")
		return
	end
	-- Check if LibQTip is available
	if not LQT then
		-- BFL:DebugPrint("Broker: LibQTip-1.0 not available - tooltips will be basic")
	else
		-- BFL:DebugPrint("Broker: LibQTip-1.0 loaded successfully")
	end
	-- Check if enabled in config
	local DB = GetDB()
	if not DB or not BetterFriendlistDB then
		-- BFL:DebugPrint("Broker: Database not initialized yet")
		return
	end

	if not BetterFriendlistDB.brokerEnabled then
		-- BFL:DebugPrint("Broker: Disabled in settings")
		return
	end

	-- Create Data Broker object
	local dataObjectDef = {
		type = "data source",
		text = "Friends: 0/0",
		icon = "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp",
		label = L("BROKER_TITLE"),

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
	}

	-- Only add OnEnter if LibQTip is available
	-- LDB Spec: Display addons prefer OnEnter over OnTooltipShow.
	-- If we define OnEnter but LQT is missing, the function would be empty and
	-- the display addon would skip OnTooltipShow, resulting in NO tooltip.
	if LQT then
		dataObjectDef.OnEnter = function(anchorFrame)
			tooltip = CreateLibQTipTooltip(anchorFrame)
		end
		-- We do NOT define OnLeave here to allow the display addon to handle its own cleanup/unhighlighting.
		-- Our tooltip handles its own hiding via SetupTooltipAutoHide.
	end

	dataObject = LDB:NewDataObject("BetterFriendlist", dataObjectDef)

	if dataObject then
		-- BFL:DebugPrint("Broker: Data Broker object created successfully")

		-- Register events for auto-update
		self:RegisterEvents()

		-- Initial text update
		self:UpdateBrokerText()
	else
		-- BFL:DebugPrint("Broker: Failed to create Data Broker object")
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
		-- BFL:DebugPrint("Broker: Events not registered - no data object")
		return
	end

	-- BFL:DebugPrint("Broker: Registering events...")

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

	-- BFL:DebugPrint("Broker: Events registered")
end

-- ========================================
-- Slash Command Support
-- ========================================

function Broker:ToggleEnabled()
	if not BetterFriendlistDB then
		-- BFL:DebugPrint("|cffff0000BetterFriendlist:|r Database not initialized")
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
