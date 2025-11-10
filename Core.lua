-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 1.0 - November 2025
-- Complete replacement for WoW Friends frame with modular architecture

-- Create addon namespace
local ADDON_NAME, BFL = ...
BFL.Version = "1.2.5-alpha"

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

-- Register initial events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == ADDON_NAME then
			-- Initialize database
			if BFL.DB then
				BFL.DB:Initialize()
			end
			
			-- Load debug flag from DB
			if BetterFriendlistDB then
				BFL.debugPrintEnabled = BetterFriendlistDB.debugPrintEnabled or false
			end
			
			-- Initialize all modules
			for name, module in pairs(BFL.Modules) do
				if module.Initialize then
					module:Initialize()
				end
			end
			
			print("|cff00ff00BetterFriendlist v" .. BFL.Version .. "|r loaded successfully!")
		end
	elseif event == "PLAYER_LOGIN" then
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
	
	-- Settings
	elseif msg == "settings" or msg == "config" or msg == "options" then
		-- Open settings tab (BottomTab 4)
		if _G.BetterFriendsFrame_ShowBottomTab then
			_G.BetterFriendsFrame_ShowBottomTab(5) -- Settings is tab 5
			if not _G.BetterFriendsFrame:IsShown() then
				_G.ToggleBetterFriendsFrame()
			end
		else
			print("|cffff0000BetterFriendlist:|r Settings not loaded yet")
		end
	
	-- Help (or any other unrecognized command)
	else
		print("|cff00ff00=== BetterFriendlist v" .. BFL.Version .. " ===|r")
		print("")
		print("|cffffcc00Main Commands:|r")
		print("  |cffffffff/bfl|r - Toggle BetterFriendlist frame")
		print("  |cffffffff/bfl settings|r - Open settings panel")
		print("  |cffffffff/bfl help|r - Show this help")
		print("")
		print("|cffffcc00Debug Commands:|r")
		print("  |cffffffff/bfl debug print|r - Toggle debug output")
		print("  |cffffffff/bfl debug|r - Show database state")
		print("")
		print("|cffffcc00Quick Join Commands:|r")
		print("  |cffffffff/bflqj mock|r - Create 3 test groups")
		print("  |cffffffff/bflqj clear|r - Remove test groups")
		print("  |cffffffff/bflqj list|r - List all mock groups")
		print("  |cffffffff/bflqj disable|r - Use real Social Queue data")
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
