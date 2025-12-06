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

-- Count table entries (for non-sequential tables)
function BFL:TableCount(tbl)
	if not tbl then return 0 end
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
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
		
		-- Force immediate data update from WoW API
		-- This ensures we have the latest friend data before rendering
		FriendsList:UpdateFriendsList()
	end
	
	-- Refresh QuickFilter Dropdown (if it exists)
	-- This ensures the dropdown icon updates when filter changes externally (e.g. via Broker)
	local QuickFilters = self:GetModule("QuickFilters")
	if QuickFilters and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown then
		QuickFilters:RefreshDropdown(BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown)
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
			
			-- Link Localization
			BFL.L = _G["BFL_L"]
			
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
			
			-- Initialize NotificationSystem (cooldown timer, etc.)
			if BFL.NotificationSystem and BFL.NotificationSystem.Initialize then
				BFL.NotificationSystem:Initialize()
			end
			
			-- Initialize NotificationEditMode (Edit Mode integration, optional dependency)
			if BFL.NotificationEditMode and BFL.NotificationEditMode.Initialize then
				BFL.NotificationEditMode:Initialize()
			end
			
			-- Initialize MainFrameEditMode (Edit Mode integration for main frame)
			if BFL.MainFrameEditMode and BFL.MainFrameEditMode.Initialize then
				BFL.MainFrameEditMode:Initialize()
			end
			
			-- Register module events after initialization
			-- CRITICAL: Only register NotificationSystem events if Beta Features enabled
			if BFL.NotificationSystem and BFL.NotificationSystem.RegisterEvents then
				if BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures then
					BFL.NotificationSystem:RegisterEvents()
					BFL:DebugPrint("|cff00ffffBFL:|r NotificationSystem events registered (Beta enabled)")
				else
					BFL:DebugPrint("|cffffcc00BFL:|r NotificationSystem events NOT registered (Beta disabled)")
				end
			end
			
			-- Version-aware success message
			local versionSuffix = BFL.IsMidnight and " (Midnight)" or " (TWW)"
			print("|cff00ff00BetterFriendlist v" .. BFL.VERSION .. versionSuffix .. "|r loaded successfully!")
			
			-- ============================================================================
			-- Hook ToggleFriendsFrame to open BetterFriendlist instead
			-- ============================================================================
			-- Strategy: Multi-layer hooking for maximum compatibility
			-- 1. Remove FriendsFrame from UIPanel system (allows Hide() in combat)
			-- 2. Hook FriendsFrame:OnShow to intercept ALL ways of opening it
			-- 3. Replace _G.ToggleFriendsFrame for direct calls
			-- 4. Hook ShowFriends for additional coverage
			--
			-- This works with ElvUI because even if they cached ToggleFriendsFrame,
			-- the OnShow hook will catch the FriendsFrame being opened.
			-- ============================================================================
			
			-- Flag to bypass hook when user explicitly wants Blizzard's frame
			BFL.AllowBlizzardFriendsFrame = false
			
			-- ============================================================================
			-- CRITICAL: Remove FriendsFrame from UIPanel system
			-- ============================================================================
			-- By removing FriendsFrame from UIPanelWindows, we can use Hide() in combat
			-- without taint issues. ShowUIPanel/HideUIPanel are protected in combat,
			-- but direct Show()/Hide() calls work fine for non-UIPanel frames.
			-- ============================================================================
			if UIPanelWindows and UIPanelWindows["FriendsFrame"] then
				-- Store original settings in case user wants Blizzard's frame
				BFL.OriginalFriendsFrameUIPanelSettings = UIPanelWindows["FriendsFrame"]
				-- Remove from UIPanel system
				UIPanelWindows["FriendsFrame"] = nil
				BFL:DebugPrint("|cff00ff00[BFL]|r FriendsFrame removed from UIPanel system (combat-safe)")
			end
			
			-- Store original function for "Show Blizzard's Friendlist" option
			if _G.ToggleFriendsFrame then
				BFL.OriginalToggleFriendsFrame = _G.ToggleFriendsFrame
				
				-- Replace global with our version (taint-safe, not a protected function)
				_G.ToggleFriendsFrame = function(tabIndex)
					-- Allow original if explicitly requested
					if BFL.AllowBlizzardFriendsFrame then
						BFL:DebugPrint("[BFL] ToggleFriendsFrame: Allowing Blizzard (explicit)")
						return BFL.OriginalToggleFriendsFrame(tabIndex)
					end
					
					BFL:DebugPrint("[BFL] ToggleFriendsFrame: Opening BetterFriendlist, tabIndex: " .. tostring(tabIndex))
					
					-- Toggle our frame with the requested tab (combat-safe, our frame is not protected)
					if _G.ToggleBetterFriendsFrame then
						_G.ToggleBetterFriendsFrame(tabIndex)
					end
				end
				BFL:DebugPrint("|cff00ff00[BFL]|r ToggleFriendsFrame global replaced")
			end
			
			-- Helper function to show Blizzard's FriendsFrame (bypasses our hook)
			-- This is used by "Show Blizzard's Friendlist" menu option
			BFL.ShowBlizzardFriendsFrame = function()
				BFL.AllowBlizzardFriendsFrame = true
				-- Temporarily restore UIPanel settings for proper positioning
				if BFL.OriginalFriendsFrameUIPanelSettings then
					UIPanelWindows["FriendsFrame"] = BFL.OriginalFriendsFrameUIPanelSettings
				end
				if BFL.OriginalToggleFriendsFrame then
					BFL.OriginalToggleFriendsFrame()
				elseif FriendsFrame then
					-- Fallback: Direct Show (combat-safe now that it's not a UIPanel)
					FriendsFrame:Show()
				end
				-- Reset flag and UIPanel settings after a brief delay
				C_Timer.After(0.1, function()
					BFL.AllowBlizzardFriendsFrame = false
				end)
			end
			
			-- Hook ShowFriends for additional coverage (taint-safe)
			if _G.ShowFriends then
				BFL.OriginalShowFriends = _G.ShowFriends
				_G.ShowFriends = function()
					if BFL.AllowBlizzardFriendsFrame then
						return BFL.OriginalShowFriends()
					end
					BFL:DebugPrint("[BFL] ShowFriends: Redirecting to BetterFriendlist")
					if BetterFriendsFrame and not BetterFriendsFrame:IsShown() then
						if _G.ToggleBetterFriendsFrame then
							_G.ToggleBetterFriendsFrame()
						end
					end
				end
			end
			
			-- ============================================================================
			-- CRITICAL: Hook FriendsFrame:OnShow for ElvUI compatibility
			-- ============================================================================
			-- ElvUI and other addons may cache ToggleFriendsFrame at load time.
			-- By hooking OnShow, we intercept the frame REGARDLESS of how it was opened.
			-- Since FriendsFrame is no longer a UIPanel, Hide() is combat-safe.
			-- We detect which tab was requested by checking FriendsFrame's selected tab.
			-- ============================================================================
			if FriendsFrame then
				FriendsFrame:HookScript("OnShow", function(self)
					-- Skip if user explicitly wants Blizzard's frame
					if BFL.AllowBlizzardFriendsFrame then
						BFL:DebugPrint("[BFL] FriendsFrame:OnShow - Allowing (explicit)")
						return
					end
					
					-- Detect which tab was requested by reading Blizzard's selected tab
					-- FRIEND_TAB_FRIENDS=1, FRIEND_TAB_WHO=2, FRIEND_TAB_RAID=3, FRIEND_TAB_QUICK_JOIN=4
					local requestedTab = PanelTemplates_GetSelectedTab(FriendsFrame) or 1
					BFL:DebugPrint("[BFL] FriendsFrame:OnShow - Intercepting, requested tab: " .. tostring(requestedTab))
					
					-- Hide Blizzard's frame immediately (combat-safe since not a UIPanel anymore)
					FriendsFrame:Hide()
					
					-- Open our frame with the requested tab
					if BetterFriendsFrame then
						if _G.ToggleBetterFriendsFrame then
							-- If already shown, just switch tab; otherwise open with tab
							if BetterFriendsFrame:IsShown() then
								PanelTemplates_SetTab(BetterFriendsFrame, requestedTab)
								BetterFriendsFrame_ShowBottomTab(requestedTab)
							else
								_G.ShowBetterFriendsFrame(requestedTab)
							end
						end
					end
				end)
				BFL:DebugPrint("|cff00ff00[BFL]|r FriendsFrame:OnShow hooked for ElvUI compatibility")
			end
		end
	elseif event == "PLAYER_LOGIN" then
		-- Check for native event callbacks (12.0.0+)
		if BetterFriendsFrame and BetterFriendsFrame.RegisterEventCallback then
			BFL.UseNativeCallbacks = true
			BFL:DebugPrint("|cff00ff00[BFL]|r Using native Frame:RegisterEventCallback (12.0.0+)")
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
	if msg == "debug" then
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
	elseif msg == "database" or msg == "db" or msg == "debugdb" then
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
	
	-- Test Notifications
	elseif msg == "testnotify" or msg == "testnotification" then
		local NotificationSystem = BFL.NotificationSystem
		if not NotificationSystem then
			print("|cffff0000BetterFriendlist:|r NotificationSystem module not loaded")
			return
		end
		
		-- Check if Beta features enabled
		if not BetterFriendlistDB.enableBetaFeatures then
			print("|cffff0000BetterFriendlist:|r Beta Features are disabled!")
			print("|cffffcc00Enable Beta Features in:|r ESC > AddOns > BetterFriendlist > General")
			return
		end
		
		print("|cff00ff00BetterFriendlist:|r Triggering 3 test notifications...")
		
		-- Trigger 3 test notifications to demonstrate multi-toast system
		NotificationSystem:ShowNotification("Test Friend 1", "is now online playing World of Warcraft", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		C_Timer.After(0.2, function()
			NotificationSystem:ShowNotification("Test Friend 2", "switched to Warrior", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		end)
		C_Timer.After(0.4, function()
			NotificationSystem:ShowNotification("Test Friend 3", "logged into World of Warcraft", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		end)
		
		print("|cff00ff00Success!|r You should see up to 3 toasts displayed simultaneously.")
		print("|cffffcc00Tip:|r Open Edit Mode (ESC > Edit Mode) to reposition the notification area!")
	
	-- Test Group Notification Rules
	elseif msg == "testgrouprules" or msg == "testgroup" then
		local NotificationSystem = BFL.NotificationSystem
		if not NotificationSystem then
			print("|cffff0000BetterFriendlist:|r NotificationSystem module not loaded")
			return
		end
		
		NotificationSystem:TestGroupRules()
	
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
	
	-- ==========================================
	-- Performance Monitoring Commands (was /bflperf)
	-- ==========================================
	elseif msg == "perf" or msg == "perf report" or msg == "perf show" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:Report()
		else
			print("|cffff0000BetterFriendlist:|r PerformanceMonitor module not loaded")
		end
	elseif msg == "perf reset" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:Reset()
		else
			print("|cffff0000BetterFriendlist:|r PerformanceMonitor module not loaded")
		end
	elseif msg == "perf enable" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:EnableAutoMonitoring()
		else
			print("|cffff0000BetterFriendlist:|r PerformanceMonitor module not loaded")
		end
	elseif msg == "perf memory" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:SampleMemory()
		end
		UpdateAddOnMemoryUsage()
		local memory = GetAddOnMemoryUsage("BetterFriendlist") or 0
		print(string.format("|cff00ff00BetterFriendlist Memory:|r %.2f KB", memory))
	
	-- ==========================================
	-- Quick Join Commands (was /bflqj)
	-- ==========================================
	elseif msg:match("^qj") or msg:match("^quickjoin") then
		local QuickJoin = BFL:GetModule("QuickJoin")
		if not QuickJoin then
			print("|cffff0000BetterFriendlist:|r QuickJoin module not loaded")
			return
		end
		
		-- Pass the full arguments to the QuickJoin handler
		-- Extract everything after "qj " or "quickjoin "
		local fullArgs = msg:match("^qj%s*(.*)") or msg:match("^quickjoin%s*(.*)") or ""
		SlashCmdList["BFLQUICKJOIN"](fullArgs)
	
	-- ==========================================
	-- Raid Frame Commands (was /bflmock)
	-- ==========================================
	elseif msg:match("^raid") then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if not RaidFrame then
			print("|cffff0000BetterFriendlist:|r RaidFrame module not loaded")
			return
		end
		
		-- Pass the full arguments to the RaidFrame handler
		local fullArgs = msg:match("^raid%s*(.*)") or ""
		SlashCmdList["BFLRAIDFRAME"](fullArgs)
	
	-- Legacy mock command (backwards compatibility)
	elseif msg == "mock" or msg == "mockraid" then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame then
			RaidFrame:CreateMockRaidData()
		else
			print("|cffff0000BetterFriendlist:|r RaidFrame module not loaded")
		end
	
	-- ==========================================
	-- Preview Mode Commands (for screenshots)
	-- ==========================================
	elseif msg:match("^preview") then
		local PreviewMode = BFL:GetModule("PreviewMode")
		if PreviewMode then
			local fullArgs = msg:match("^preview%s*(.*)") or ""
			PreviewMode:HandleCommand(fullArgs)
		else
			print("|cffff0000BetterFriendlist:|r PreviewMode module not loaded")
		end
	
	-- ==========================================
	-- Test Commands (was /bfltest)
	-- ==========================================
	elseif msg == "test" or msg == "test activity" then
		if SlashCmdList["ACTIVITYTRACKER_TEST"] then
			SlashCmdList["ACTIVITYTRACKER_TEST"]("activity")
		else
			print("|cffff0000BetterFriendlist:|r ActivityTracker Tests not loaded")
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
	print("  |cffffffff/bfl debug|r - Toggle debug output")
	print("  |cffffffff/bfl database|r - Show database state")
		print("  |cffffffff/bfl activity|r - Show activity tracking data")
		print("  |cffffffff/bfl stats|r - Show friend network statistics")
		print("  |cffffffff/bfl testnotify|r - Test notification system (3 toasts)")
		print("  |cffffffff/bfl testgrouprules|r - Test group notification rules")
		print("")
		print("|cffffcc00Quick Join Commands:|r")
		print("  |cffffffff/bfl qj mock|r - Create comprehensive test data")
		print("  |cffffffff/bfl qj mock dungeon|r - Dungeon/M+ groups only")
		print("  |cffffffff/bfl qj mock pvp|r - PvP groups only")
		print("  |cffffffff/bfl qj mock raid|r - Raid groups only")
		print("  |cffffffff/bfl qj mock stress|r - 50 groups for scrollbar testing")
		print("  |cffffffff/bfl qj event add|remove|update|r - Simulate events")
		print("  |cffffffff/bfl qj clear|r - Remove all test groups")
		print("  |cffffffff/bfl qj list|r - List all mock groups")
		print("")
		print("|cffffcc00Mock Commands:|r")
		print("  |cffffffff/bfl mock|r - Create mock raid (legacy, same as /bfl raid mock)")
		print("  |cffffffff/bfl invite|r - Add one mock friend invite")
		print("  |cffffffff/bfl clearinvites|r - Remove all mock invites")
		print("")
		print("|cffffcc00Preview Mode (Screenshots):|r")
		print("  |cffffffff/bfl preview|r - Enable full preview mode")
		print("  |cffffffff/bfl preview off|r - Disable preview mode")
		print("  |cff888888(Shows mock Friends, Groups, Raid, QuickJoin, WHO)|r")
		print("")
		print("|cffffcc00Raid Frame Commands:|r")
		print("  |cffffffff/bfl raid mock|r - Create 25-player mock raid")
		print("  |cffffffff/bfl raid mock full|r - Create 40-player raid")
		print("  |cffffffff/bfl raid mock small|r - Create 10-player raid")
		print("  |cffffffff/bfl raid mock mythic|r - Create 20-player mythic raid")
		print("  |cffffffff/bfl raid event readycheck|r - Simulate ready check")
		print("  |cffffffff/bfl raid event rolechange|r - Simulate role changes")
		print("  |cffffffff/bfl raid event move|r - Shuffle group assignments")
		print("  |cffffffff/bfl raid clear|r - Remove mock data")
		print("")
		print("|cffffcc00Performance Monitoring:|r")
		print("  |cffffffff/bfl perf|r - Show performance stats")
		print("  |cffffffff/bfl perf enable|r - Enable performance tracking")
		print("  |cffffffff/bfl perf reset|r - Reset statistics")
		print("  |cffffffff/bfl perf memory|r - Show memory usage")
		print("")
		print("|cffffcc00Test Commands:|r")
		print("  |cffffffff/bfl test|r - Run ActivityTracker tests")
		print("")
		print("|cff20ff20For more help, see:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r")
	end
end
