-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 1.0 - November 2025
-- Complete replacement for WoW Friends frame with modular architecture

-- Create addon namespace
local ADDON_NAME, BFL = ...

-- Version will be loaded dynamically from TOC file in ADDON_LOADED
BFL.VERSION = "Unknown"

-- Make BFL globally accessible for tooltip and other legacy files
_G.BFL = BFL

--------------------------------------------------------------------------
-- Version Detection (Retail: Expansion Version)
--------------------------------------------------------------------------
local tocVersion = select(4, GetBuildInfo())  -- Returns TOC version (e.g., 110205)
BFL.TOCVersion = tocVersion
BFL.IsTWW = (tocVersion >= 110200 and tocVersion < 120000)    -- The War Within (11.x)
BFL.IsMidnight = (tocVersion >= 120000)                       -- Midnight (12.x+)

-- Feature Detection (detect available APIs for optional features)
BFL.UseClassID = false              -- 11.2.7+ classID optimization
BFL.HasSecretValues = false         -- 12.0.0+ Secret Values API
BFL.UseNativeCallbacks = false      -- 12.0.0+ Frame:RegisterEventCallback

-- Mock Friend Invites System (for testing)
BFL.MockFriendInvites = {
	enabled = false,
	invites = {}
}

-- Detect optional features based on API availability
local function DetectOptionalFeatures()
	-- 11.2.7+ classID support for performance optimization
	if GetClassInfoByID then
		BFL.UseClassID = true
	end
	
	-- 12.0.0+ Secret Values API
	if issecretvalue then
		BFL.HasSecretValues = true
	end
	
	-- Print version info (only if debug enabled)
	if BFL.debugPrintEnabled then
		local versionName = BFL.IsMidnight and "Midnight (12.x)" or "The War Within (11.x)"
		print(string.format("|cff00ff00BetterFriendlist:|r TOC %d (%s)", tocVersion, versionName))
		
		if BFL.UseClassID then
			print("|cff00ff00BetterFriendlist:|r Using classID optimization (11.2.7+)")
		end
		if BFL.HasSecretValues then
			print("|cff00ff00BetterFriendlist:|r Secret Values API detected (12.0.0+)")
		end
	end
end

-- Module registry
BFL.Modules = {}

-- Event callback registry
BFL.EventCallbacks = {}

--------------------------------------------------------------------------
-- Debug Print System
--------------------------------------------------------------------------
-- All debug prints are gated behind /bfl print toggle
-- Default: OFF (no debug spam), persists in SavedVariables
--------------------------------------------------------------------------

-- Store debug flag in BFL namespace for instant access
BFL.debugPrintEnabled = false

-- Debug print function (replaces all print() calls except version print)
function BFL:DebugPrint(...)
	-- Use cached flag for instant access (no DB lookup)
	if self.debugPrintEnabled then
		print(...)
	end
end

-- Toggle debug print mode (slash command)
function BFL:ToggleDebugPrint()
	if not BetterFriendlistDB then
		print("|cffff0000BetterFriendlist:|r Database not initialized yet. Try again after login.")
		return
	end
	
	-- Toggle in DB
	BetterFriendlistDB.debugPrintEnabled = not BetterFriendlistDB.debugPrintEnabled
	
	-- Update cached flag immediately
	self.debugPrintEnabled = BetterFriendlistDB.debugPrintEnabled
	
	if self.debugPrintEnabled then
		print("|cff00ff00BetterFriendlist:|r Debug printing |cff00ff00ENABLED|r")
	else
		print("|cff00ff00BetterFriendlist:|r Debug printing |cffff0000DISABLED|r")
	end
end

-- Register a module
function BFL:RegisterModule(name, module)
	if self.Modules[name] then
		error(string.format("Module '%s' is already registered!", name))
	end
	self.Modules[name] = module
	return module
end

-- Get a module
function BFL:GetModule(name)
	return self.Modules[name]
end

--------------------------------------------------------------------------
-- Event Callback System
--------------------------------------------------------------------------
-- Allows modules to register callbacks for specific events
-- This decouples event handling from the main UI file
--------------------------------------------------------------------------

-- Core event frame (must be defined before RegisterEventCallback)
local eventFrame = CreateFrame("Frame")

-- Register a callback for an event
-- @param event: The event name (e.g., "FRIENDLIST_UPDATE")
-- @param callback: Function to call when event fires
-- @param priority: Optional priority (lower = called first), default 50
function BFL:RegisterEventCallback(event, callback, priority)
	priority = priority or 50
	
	if not self.EventCallbacks[event] then
		self.EventCallbacks[event] = {}
		-- Auto-register WoW event with the event frame
		eventFrame:RegisterEvent(event)
	end
	
	table.insert(self.EventCallbacks[event], {
		callback = callback,
		priority = priority
	})
	
	-- Sort by priority
	table.sort(self.EventCallbacks[event], function(a, b)
		return a.priority < b.priority
	end)
end

-- Fire all callbacks for an event
-- @param event: The event name
-- @param ...: Event arguments
function BFL:FireEventCallbacks(event, ...)
	if not self.EventCallbacks[event] then
		return
	end
	
	for _, entry in ipairs(self.EventCallbacks[event]) do
		entry.callback(...)
	end
end

-- Normalize WoW friend name to always include realm
-- If name doesn't contain "-", append current player's realm
-- This ensures consistent identification across connected realms
-- @param name: Friend name from API (e.g., "Name" or "Name-Realm")
-- @return: Normalized name with realm (e.g., "Name-Realm")
function BFL:NormalizeWoWFriendName(name)
	if not name or name == "" then
		return nil
	end
	
	-- If name already contains realm separator, it's already normalized
	if string.find(name, "-") then
		return name
	end
	
	-- Name has no realm - append current player's realm
	-- Using GetNormalizedRealmName() which returns the connected realm name
	local playerRealm = GetNormalizedRealmName()
	if playerRealm and playerRealm ~= "" then
		return name .. "-" .. playerRealm
	end
	
	-- Fallback: return name as-is if we can't determine realm
	return name
end

-- Get display name for WoW friend (strips realm if it matches player's realm)
-- Database always stores "Name-Realm" format for consistency
-- Display shows "Name" for same realm, "Name-Realm" for different realms
-- @param fullName: The normalized name from database (e.g., "Renzai-Blackhand")
-- @return: Display name ("Renzai" if same realm, "Renzai-Blackhand" if different)
function BFL:GetWoWFriendDisplayName(fullName)
	if not fullName or fullName == "" then
		return fullName
	end
	
	-- Split name and realm
	local name, realm = strsplit("-", fullName, 2)
	if not realm then
		-- No realm separator found, return as-is
		return fullName
	end
	
	-- Check if realm matches player's realm
	local playerRealm = GetNormalizedRealmName()
	if realm == playerRealm then
		-- Same realm: return name only
		return name
	else
		-- Different realm: return full "Name-Realm"
		return fullName
	end
end

-- Force immediate refresh of the friends list display
-- This bypasses the normal update throttling and immediately rebuilds and renders the display
-- Can be called from any module to ensure instant visual updates (e.g., after mock data changes)
-- Also clears any pending updates to prevent race conditions with collapse/expand actions
function BFL:ForceRefreshFriendsList()
	local FriendsList = self:GetModule("FriendsList")
	if FriendsList then
		-- Clear pending update flag to prevent overwriting our forced refresh
		FriendsList:ClearPendingUpdate()
		
		-- Force immediate refresh regardless of update state
		-- This ensures collapse/expand actions work even during background updates
		FriendsList:BuildDisplayList()
		FriendsList:RenderDisplay()
	end
end

-- Register initial events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == ADDON_NAME then
			-- Get version dynamically from TOC file
			BFL.VERSION = C_AddOns.GetAddOnMetadata("BetterFriendlist", "Version") or "Unknown"
			
			-- Initialize database
			if BFL.DB then
				BFL.DB:Initialize()
			end
			
			-- Load debug flag from DB
			if BetterFriendlistDB then
				BFL.debugPrintEnabled = BetterFriendlistDB.debugPrintEnabled or false
			end
			
			-- Detect optional features (version-specific APIs)
			DetectOptionalFeatures()
			
			-- Initialize all modules
			for name, module in pairs(BFL.Modules) do
				if module.Initialize then
					module:Initialize()
				end
			end
			
			-- Version-aware success message
			local versionSuffix = BFL.IsMidnight and " (Midnight)" or " (TWW)"
			print("|cff00ff00BetterFriendlist v" .. BFL.VERSION .. versionSuffix .. "|r loaded successfully!")
		end
	elseif event == "PLAYER_LOGIN" then
		-- Check for native event callbacks (12.0.0+)
		if BetterFriendsFrame and BetterFriendsFrame.RegisterEventCallback then
			BFL.UseNativeCallbacks = true
			BFL:DebugPrint("|cff00ff00[BFL]|r Using native Frame:RegisterEventCallback (12.0.0+)")
		end
		
		-- Hook ToggleFriendsFrame to open BetterFriendlist instead
		-- This is taint-safe because:
		-- 1. We're hooking a non-protected FrameXML function
		-- 2. We're not modifying secure frames
		-- 3. The hook is installed after PLAYER_LOGIN (all addons loaded)
		if ToggleFriendsFrame then
			-- Store original function
			BFL.OriginalToggleFriendsFrame = ToggleFriendsFrame
			
			-- Replace with our version (always use BetterFriendlist)
			-- Note: Menu option "Show Blizzard's Friendlist" calls OriginalToggleFriendsFrame directly
			ToggleFriendsFrame = function(tabIndex)
				BFL:DebugPrint("[BFL] ToggleFriendsFrame: Opening BetterFriendlist")
				
				-- Close Blizzard's frame if it's open
				if FriendsFrame and FriendsFrame:IsShown() then
					HideFriends()
				end
				
				-- Toggle our frame
				if _G.ToggleBetterFriendsFrame then
					_G.ToggleBetterFriendsFrame()
				end
			end
			
			BFL:DebugPrint("|cff00ff00[BFL]|r ToggleFriendsFrame hooked successfully")
		end
		
		-- Late initialization for modules that need PLAYER_LOGIN
		for name, module in pairs(BFL.Modules) do
			if module.OnPlayerLogin then
				module:OnPlayerLogin()
			end
		end
	end
	
	-- Fire event callbacks for all events
	BFL:FireEventCallbacks(event, ...)
end)

-- Expose namespace globally for backward compatibility
_G.BetterFriendlist = BFL

--------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------

-- Main slash command handler
SLASH_BETTERFRIENDLIST1 = "/bfl"
SlashCmdList["BETTERFRIENDLIST"] = function(msg)
	msg = msg:lower():trim()
	
	-- Toggle frame (no parameters)
	if msg == "" then
		if _G.ToggleBetterFriendsFrame then
			_G.ToggleBetterFriendsFrame()
		else
			print("|cffff0000BetterFriendlist:|r Frame not loaded yet")
		end
		return
	end
	
	-- Debug print toggle
	if msg == "print" then
		BFL:ToggleDebugPrint()
	
	-- Legacy commands (from old BetterFriendlist.lua slash handler)
	elseif msg == "show" then
		if BFL.DB then
			BFL.DB:Set("showBlizzardOption", true)
			print("|cff20ff20BetterFriendlist:|r 'Show Blizzard's Friendlist' option is now |cff20ff20enabled|r in the menu")
		end
	elseif msg == "hide" then
		if BFL.DB then
			BFL.DB:Set("showBlizzardOption", false)
			print("|cff20ff20BetterFriendlist:|r 'Show Blizzard's Friendlist' option is now |cffff0000disabled|r in the menu")
		end
	elseif msg == "toggle" then
		if BFL.DB then
			local current = BFL.DB:Get("showBlizzardOption", false)
			BFL.DB:Set("showBlizzardOption", not current)
			if not current then
				print("|cff20ff20BetterFriendlist:|r 'Show Blizzard's Friendlist' option is now |cff20ff20enabled|r in the menu")
			else
				print("|cff20ff20BetterFriendlist:|r 'Show Blizzard's Friendlist' option is now |cffff0000disabled|r in the menu")
			end
		end
	elseif msg == "debug" or msg == "debugdb" then
		if _G.BetterFriendlistSettings_DebugDatabase then
			_G.BetterFriendlistSettings_DebugDatabase()
		else
			print("|cffff0000BetterFriendlist:|r Debug function not available (settings not loaded)")
		end
	
	-- Debug Activity Tracking
	elseif msg == "activity" or msg == "debugactivity" then
		local DB = BFL:GetModule("DB")
		if not DB then
			print("|cffff0000BetterFriendlist:|r DB module not available")
			return
		end
		
		local friendActivity = DB:Get("friendActivity") or {}
		local count = 0
		for _ in pairs(friendActivity) do count = count + 1 end
		
		print("|cff00ff00=== BetterFriendlist Activity Tracking ===|r")
		print(string.format("Total friends with activity: %d", count))
		print("")
		
		for friendUID, activities in pairs(friendActivity) do
			print("|cffffcc00" .. friendUID .. "|r")
			if activities.lastWhisper then
				print(string.format("  lastWhisper: %d (%s ago)", activities.lastWhisper, SecondsToTime(time() - activities.lastWhisper)))
			end
			if activities.lastGroup then
				print(string.format("  lastGroup: %d (%s ago)", activities.lastGroup, SecondsToTime(time() - activities.lastGroup)))
			end
			if activities.lastTrade then
				print(string.format("  lastTrade: %d (%s ago)", activities.lastTrade, SecondsToTime(time() - activities.lastTrade)))
			end
		end
	
	-- Statistics
	elseif msg == "stats" or msg == "statistics" then
		local Statistics = BFL:GetModule("Statistics")
		if not Statistics then
			print("|cffff0000BetterFriendlist:|r Statistics module not loaded")
			return
		end
		
		local stats = Statistics:GetStatistics()
		print("|cff00ff00=== BetterFriendlist Enhanced Statistics ===|r")
		print("")
		
		-- Overview
		print("|cffffcc00Overview:|r")
		print(string.format("  Total: |cffffffff%d|r  Online: |cff00ff00%d|r (%.0f%%)  Offline: |cffaaaaaa%d|r (%.0f%%)", 
			stats.totalFriends, 
			stats.onlineFriends, (stats.onlineFriends / math.max(stats.totalFriends, 1)) * 100,
			stats.offlineFriends, (stats.offlineFriends / math.max(stats.totalFriends, 1)) * 100))
		print(string.format("  Battle.net Friends: |cff0099ff%d|r  |  WoW Friends: |cffffd700%d|r", stats.bnetFriends, stats.wowFriends))
		print("")
		
		-- Friendship Health
		print("|cffffcc00Friendship Health:|r")
		local totalHealthFriends = stats.totalFriends - (stats.friendshipHealth.unknown or 0)
		if totalHealthFriends > 0 then
			print(string.format("  Active: |cff00ff00%d|r (%.0f%%)  Regular: |cffffd700%d|r (%.0f%%)  Drifting: |cffffaa00%d|r (%.0f%%)",
				stats.friendshipHealth.active, (stats.friendshipHealth.active / totalHealthFriends) * 100,
				stats.friendshipHealth.regular, (stats.friendshipHealth.regular / totalHealthFriends) * 100,
				stats.friendshipHealth.drifting, (stats.friendshipHealth.drifting / totalHealthFriends) * 100))
			print(string.format("  Stale: |cffff6600%d|r (%.0f%%)  Dormant: |cffff0000%d|r (%.0f%%)",
				stats.friendshipHealth.stale, (stats.friendshipHealth.stale / totalHealthFriends) * 100,
				stats.friendshipHealth.dormant, (stats.friendshipHealth.dormant / totalHealthFriends) * 100))
		else
			print("  No health data available")
		end
		print("")
		
		-- Class Distribution (Top 5)
		local topClasses = Statistics:GetTopClasses(5)
		if #topClasses > 0 then
			print("|cffffcc00Class Distribution (Top 5):|r")
			for i, class in ipairs(topClasses) do
				local pct = (class.count / math.max(stats.totalFriends, 1)) * 100
				print(string.format("  %d. %s: |cffffffff%d|r (%.0f%%)", i, class.name, class.count, pct))
			end
			print("")
		end
		
		-- Level Distribution
		if stats.levelDistribution.leveledFriends > 0 then
			print("|cffffcc00Level Distribution:|r")
			print(string.format("  Max (80): |cffffffff%d|r  70-79: |cffffffff%d|r  60-69: |cffffffff%d|r  <60: |cffffffff%d|r",
				stats.levelDistribution.maxLevel,
				stats.levelDistribution.ranges[1].count,
				stats.levelDistribution.ranges[2].count,
				stats.levelDistribution.ranges[3].count))
			print(string.format("  Average Level: |cffffffff%.1f|r", stats.levelDistribution.average))
			print("")
		end
		
		-- Realm Clusters
		local topRealms = Statistics:GetTopRealms(5)
		if #topRealms > 0 then
			print("|cffffcc00Realm Clusters:|r")
			print(string.format("  Same Realm: |cffffffff%d|r (%.0f%%)  |  Other Realms: |cffffffff%d|r (%.0f%%)",
				stats.realmDistribution.sameRealm, (stats.realmDistribution.sameRealm / math.max(stats.totalFriends, 1)) * 100,
				stats.realmDistribution.otherRealms, (stats.realmDistribution.otherRealms / math.max(stats.totalFriends, 1)) * 100))
			print("  Top Realms:")
			for i, realm in ipairs(topRealms) do
				print(string.format("    %d. %s: |cffffffff%d|r", i, realm.name, realm.count))
			end
			print("")
		end
		
		-- Faction Split
		if stats.factionCounts.alliance > 0 or stats.factionCounts.horde > 0 then
			print("|cffffcc00Faction Split:|r")
			print(string.format("  Alliance: |cff0080ff%d|r  |  Horde: |cffff0000%d|r",
				stats.factionCounts.alliance, stats.factionCounts.horde))
			print("")
		end
		
		-- Game Distribution
		local totalGamePlayers = stats.gameCounts.wow + stats.gameCounts.classic + stats.gameCounts.diablo + 
		                         stats.gameCounts.hearthstone + stats.gameCounts.starcraft + stats.gameCounts.mobile + stats.gameCounts.other
		if totalGamePlayers > 0 then
			print("|cffffcc00Game Distribution:|r")
			if stats.gameCounts.wow > 0 then
				print(string.format("  WoW Retail: |cffffffff%d|r", stats.gameCounts.wow))
			end
			if stats.gameCounts.classic > 0 then
				print(string.format("  WoW Classic: |cffffffff%d|r", stats.gameCounts.classic))
			end
			if stats.gameCounts.diablo > 0 then
				print(string.format("  Diablo IV: |cffffffff%d|r", stats.gameCounts.diablo))
			end
			if stats.gameCounts.hearthstone > 0 then
				print(string.format("  Hearthstone: |cffffffff%d|r", stats.gameCounts.hearthstone))
			end
			if stats.gameCounts.starcraft > 0 then
				print(string.format("  StarCraft: |cffffffff%d|r", stats.gameCounts.starcraft))
			end
			if stats.gameCounts.mobile > 0 then
				print(string.format("  Mobile App: |cffffffff%d|r", stats.gameCounts.mobile))
			end
			if stats.gameCounts.other > 0 then
				print(string.format("  Other Games: |cffffffff%d|r", stats.gameCounts.other))
			end
			print("")
		end
		
		-- Mobile vs Desktop
		if stats.mobileVsDesktop.desktop > 0 or stats.mobileVsDesktop.mobile > 0 then
			print("|cffffcc00Mobile vs. Desktop:|r")
			print(string.format("  Desktop: |cffffffff%d|r (%.0f%%)  Mobile: |cffffffff%d|r (%.0f%%)",
				stats.mobileVsDesktop.desktop, (stats.mobileVsDesktop.desktop / math.max(stats.onlineFriends, 1)) * 100,
				stats.mobileVsDesktop.mobile, (stats.mobileVsDesktop.mobile / math.max(stats.onlineFriends, 1)) * 100))
			print("")
		end
		
		-- Notes and Favorites
		print("|cffffcc00Organization:|r")
		print(string.format("  With Notes: |cffffffff%d|r (%.0f%%)  Favorites: |cffffffff%d|r (%.0f%%)",
			stats.notesAndFavorites.withNotes, (stats.notesAndFavorites.withNotes / math.max(stats.totalFriends, 1)) * 100,
			stats.notesAndFavorites.favorites, (stats.notesAndFavorites.favorites / math.max(stats.totalFriends, 1)) * 100))
	
	-- Settings
	elseif msg == "settings" or msg == "config" or msg == "options" then
		local Settings = BFL:GetModule("Settings")
		if Settings then
			-- Ensure main frame is visible first
			if _G.BetterFriendsFrame and not _G.BetterFriendsFrame:IsShown() then
				if _G.ToggleBetterFriendsFrame then
					_G.ToggleBetterFriendsFrame()
				end
			end
			-- Show settings frame
			Settings:Show()
		else
			print("|cffff0000BetterFriendlist:|r Settings not loaded yet")
		end
	
	-- Mock Friend Invites
	elseif msg == "invite" or msg == "invites" or msg == "mockinvite" or msg == "mockinvites" then
		-- Enable mock system if not already enabled
		if not BFL.MockFriendInvites.enabled then
			BFL.MockFriendInvites.enabled = true
			print("|cff00ff00BetterFriendlist:|r Mock friend invites |cff00ff00ENABLED|r")
		end
		
		-- Add ONE new mock invite
		local nextID = 1000001 + #BFL.MockFriendInvites.invites
		local names = {"TestPlayer", "FriendRequest", "NewFriend", "GamerBuddy", "CoolDude", "ProPlayer", "NiceGuy", "BestFriend"}
		local nameIndex = ((#BFL.MockFriendInvites.invites) % #names) + 1
		local battleTag = names[nameIndex] .. "#" .. math.random(1000, 9999)
		
		table.insert(BFL.MockFriendInvites.invites, {
			inviteID = nextID,
			accountName = battleTag
		})
		
		print(string.format("|cff00ff00BetterFriendlist:|r Added mock invite from |cffffffff%s|r (Total: %d)", battleTag, #BFL.MockFriendInvites.invites))
		print("|cffffcc00Tip:|r Use |cffffffff/bfl clearinvites|r to remove all mock invites")
		
		-- Force immediate refresh
		BFL:ForceRefreshFriendsList()
		
		-- Flash header if collapsed
		local collapsed = GetCVarBool("friendInvitesCollapsed")
		if collapsed then
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:FlashInviteHeader()
			end
		end
	
	elseif msg == "clearinvites" or msg == "clearinvite" then
		if BFL.MockFriendInvites.enabled or #BFL.MockFriendInvites.invites > 0 then
			local count = #BFL.MockFriendInvites.invites
			BFL.MockFriendInvites.enabled = false
			BFL.MockFriendInvites.invites = {}
			print(string.format("|cff00ff00BetterFriendlist:|r Removed %d mock invite(s) - Mock system |cffff0000DISABLED|r", count))
			
			-- Force immediate refresh
			if count > 0 then
				BFL:ForceRefreshFriendsList()
			end
		else
			print("|cffff0000BetterFriendlist:|r No mock invites active")
		end
	
	-- Help (or any other unrecognized command)
	else
		print("|cff00ff00=== BetterFriendlist v" .. BFL.VERSION .. " ===|r")
		print("")
		print("|cffffcc00Main Commands:|r")
		print("  |cffffffff/bfl|r - Toggle BetterFriendlist frame")
		print("  |cffffffff/bfl settings|r - Open settings panel")
		print("  |cffffffff/bfl help|r - Show this help")
		print("")
		print("|cffffcc00Debug Commands:|r")
		print("  |cffffffff/bfl debug print|r - Toggle debug output")
		print("  |cffffffff/bfl debug|r - Show database state")
		print("  |cffffffff/bfl activity|r - Show activity tracking data")
		print("  |cffffffff/bfl stats|r - Show friend network statistics")
		print("")
		print("|cffffcc00Quick Join Commands:|r")
		print("  |cffffffff/bflqj mock|r - Create 3 test groups")
		print("  |cffffffff/bflqj clear|r - Remove test groups")
		print("  |cffffffff/bflqj list|r - List all mock groups")
		print("  |cffffffff/bflqj disable|r - Use real Social Queue data")
		print("")
		print("|cffffcc00Friend Invite Commands:|r")
		print("  |cffffffff/bfl invite|r - Add one mock friend invite (repeatable)")
		print("  |cffffffff/bfl clearinvites|r - Remove all mock invites")
		print("")
		print("|cffffcc00Performance Monitoring:|r")
		print("  |cffffffff/bflperf enable|r - Enable performance tracking")
		print("  |cffffffff/bflperf report|r - Show performance stats")
		print("  |cffffffff/bflperf reset|r - Reset statistics")
		print("  |cffffffff/bflperf memory|r - Show memory usage")
		print("")
		print("|cff20ff20For more help, see:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r")
	end
end
