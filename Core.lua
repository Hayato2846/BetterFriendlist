-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 2.2.9 - February 2026
-- Complete replacement for WoW Friends frame with modular architecture

-- Create addon namespace
local ADDON_NAME, BFL = ...

-- Version will be loaded dynamically from TOC file in ADDON_LOADED
BFL.VERSION = "Unknown"

-- Make BFL globally accessible for tooltip and other legacy files
_G.BFL = BFL

--------------------------------------------------------------------------
-- Version Detection (Retail & Classic)
--------------------------------------------------------------------------
local tocVersion = select(4, GetBuildInfo())  -- Returns TOC version (e.g., 110205)
BFL.TOCVersion = tocVersion

-- Classic Versions (check first - more specific)
BFL.IsClassicEra = (tocVersion < 20000)                         -- Classic Era (1.x)
BFL.IsTBCClassic = (tocVersion >= 20000 and tocVersion < 30000)   -- TBC Classic (2.x) - legacy
BFL.IsWrathClassic = (tocVersion >= 30000 and tocVersion < 40000) -- Wrath Classic (3.x) - legacy
BFL.IsCataClassic = (tocVersion >= 40000 and tocVersion < 50000) -- Cata Classic (4.x) - legacy
BFL.IsMoPClassic = (tocVersion >= 50000 and tocVersion < 60000) -- MoP Classic (5.x)
BFL.IsClassic = BFL.IsClassicEra or BFL.IsMoPClassic or BFL.IsCataClassic or BFL.IsWrathClassic or BFL.IsTBCClassic

-- Retail Expansions
BFL.IsRetail = (tocVersion >= 100000)                           -- Dragonflight+ (10.x+)
BFL.IsTWW = (tocVersion >= 110200 and tocVersion < 120000)      -- The War Within (11.x)
BFL.IsMidnight = (tocVersion >= 120000)                         -- Midnight (12.x+)

-- Feature Flags (detect what APIs are available)
BFL.HasModernScrollBox = BFL.IsRetail                           -- ScrollBox API (Retail 10.0+)
BFL.HasModernMenu = BFL.IsRetail                                -- MenuUtil, Menu.ModifyMenu (Retail 11.0+)
BFL.HasRecentAllies = BFL.IsTWW or BFL.IsMidnight               -- C_RecentAllies (TWW 11.0.7+)
BFL.HasEditMode = BFL.IsRetail                                  -- Edit Mode API (Retail 10.0+)
BFL.HasModernDropdown = BFL.IsRetail                            -- WowStyle1DropdownTemplate (Retail 10.0+)
BFL.HasModernColorPicker = BFL.IsRetail                         -- ColorPickerFrame:SetupColorPickerAndShow (Retail 10.1+)

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
	local versionName = BFL.IsMidnight and "Midnight (12.x)" or "The War Within (11.x)"
	BFL:DebugPrint(string.format("|cff00ff00BetterFriendlist:|r TOC %d (%s)", tocVersion, versionName))
	
	if BFL.UseClassID then
		BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Using classID optimization (11.2.7+)")
	end
	if BFL.HasSecretValues then
		BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Secret Values API detected (12.0.0+)")
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
		print("|cff00ff00BetterFriendlist:|r " .. BFL.L.DEBUG_ENABLED)
	else
		print("|cff00ff00BetterFriendlist:|r " .. BFL.L.DEBUG_DISABLED)
	end
end

-- Update Portrait Visibility based on Simple Mode setting
function BFL:UpdatePortraitVisibility(reason)
	reason = reason or "Unknown"

	-- Need to use raw DB access here or get module
	local DB = self:GetModule("DB")
	if not DB then 
		return 
	end
	
	local simpleMode = DB:Get("simpleMode", false)
	local shouldShow = not simpleMode
	local shouldShowPortrait = shouldShow
	
	-- Classic: Hide portrait when ElvUI is active and Simple Mode is disabled
	-- (Changelog will be accessible via Contacts Menu instead to save space)
	if BFL.IsClassic and not simpleMode then
		local isElvUIActive = _G.ElvUI and BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin ~= false
		if isElvUIActive then
			shouldShowPortrait = false
		end
	end

	local frame = BetterFriendsFrame
	
	if frame then
		-- Standard Hiding (The Nice Way)
		-- We print what we find here to see if the frames actually exist
		if frame.PortraitContainer then frame.PortraitContainer:SetShown(shouldShowPortrait) end
		if frame.portrait then frame.portrait:SetShown(shouldShowPortrait) end
		if frame.PortraitButton then frame.PortraitButton:SetShown(shouldShowPortrait) end
		if frame.PortraitIcon then frame.PortraitIcon:SetShown(shouldShowPortrait) end
		if frame.PortraitMask then frame.PortraitMask:SetShown(shouldShowPortrait) end
		if frame.SetPortraitShown then frame:SetPortraitShown(shouldShowPortrait) end
		
		-- Also hide Global Portrait (Usually the Icon)
		local globalPortraitName = frame:GetName() .. "Portrait"
		local globalPortrait = _G[globalPortraitName]
		if globalPortrait then 
			globalPortrait:SetShown(shouldShowPortrait) 
		end

		-- DEEP SEARCH (The "Find that Ring" Way)
		-- We scan the frame regions AND immediate children's regions
		
		local function ProcessRegions(objectToScan, depthName)
			if not objectToScan then return end
			
			local objectName = (objectToScan.GetName and objectToScan:GetName()) or "Anonymous"

			local subRegions = {objectToScan:GetRegions()}
			for i, region in ipairs(subRegions) do
				if region:IsObjectType("Texture") then
					local regionName = region:GetName()
					local texture = region:GetTexture()
					local atlas = region:GetAtlas()
					
					-- Strategy 1: SWAP the structural corner (The "Hole" for the portrait)
					
					local isTargetCorner = false
					local matchReason = "None"
					
					-- Check Retail Atlas
					if atlas and (atlas == "UI-Frame-PortraitMetal-CornerTopLeft" or atlas == "UI-Frame-Metal-CornerTopLeft") then
						isTargetCorner = true
						matchReason = "Atlas=" .. atlas
					end
					
					-- Check Classic Texture Path
					if BFL.IsClassic and type(texture) == "string" then
						local texLower = texture:lower()
						if (texLower:find("friendsframe") and texLower:find("topleft")) or 
						   (texLower:find("ui%-friendsframe%-topleft")) or
						   (texLower:find("helpframe") and texLower:find("topleft")) then -- Added helpframe check to re-detect our own fix
							isTargetCorner = true
							matchReason = "TexturePath=" .. texture
						end
					end
					
					-- Check Explicit Name (Fix for Shared Texture IDs in Classic)
					if regionName and regionName:find("TopLeftCorner") then
						isTargetCorner = true
						matchReason = "RegionName=" .. regionName
					end

					if isTargetCorner then
						local parentFrame = objectToScan
						
						if shouldShowPortrait then
							-- Restore original portrait corner (Open with hole)
							region:Show() -- Ensure visible
							region:SetAlpha(1)
							region:SetVertexColor(1, 1, 1, 1)
							
							if parentFrame.SimpleCornerPatch then
								parentFrame.SimpleCornerPatch:Hide()
							end
							
							if BFL.IsClassic then
								region:SetTexture(374156) -- Original Classic FileID for FriendFrame TopLeft
								region:SetTexCoord(0, 1, 0, 1)
							else
								region:SetAtlas("UI-Frame-PortraitMetal-CornerTopLeft", true)
							end
						else
							-- Swap to standard square corner (Closed hole)
							
							region:Show() 
							region:SetAlpha(1)
							region:SetVertexColor(1, 1, 1, 1)

							if BFL.IsClassic then
								-- Classic workaround: Use Atlas as requested (User prefers this + Reload approach)
								region:SetAtlas("UI-Frame-Metal-CornerTopLeft", true)
							else
								region:SetAtlas("UI-Frame-Metal-CornerTopLeft", true)
							end
							
							if parentFrame.SimpleCornerPatch then
								parentFrame.SimpleCornerPatch:Hide()
							end
						end
					end

					-- Strategy 2: HIDE the overlay ring (The shiny gold/blue circle)
					local isRingOverlay = false
					local ringMatchReason = "None"
					
					-- Safety: If it's the corner, it CANNOT be the ring
					if not isTargetCorner then
						-- Check Explicit Name (Primary Fix)
						if regionName and regionName:find("PortraitFrame") then
							isRingOverlay = true
							ringMatchReason = "RegionName=" .. regionName
						end
						
						-- Check Atlas (Ring Overlays only)
						if atlas and (
							atlas == "UI-Frame-Portrait" or 
							atlas == "UI-Frame-Portrait-Blue" or 
							atlas == "player-portrait-frame"
						) then
							isRingOverlay = true
							ringMatchReason = "Atlas=" .. atlas
						end
						
						-- Check Texture Path (Legacy/Classic rings)
						if texture and type(texture) == "string" then
							local texLower = texture:lower()
							if (texLower:find("portrait") and not texLower:find("metal")) then
								if texLower:find("ui%-frame%-portrait") or        -- Standard
								   texLower:find("ui%-friendsframe%-portrait") or -- Classic FriendsFrame
								   texLower:find("portraitring") or               -- Rare variation
								   texLower:find("player%-portrait")              -- Player frame style
								then
									isRingOverlay = true
									ringMatchReason = "TexturePath=" .. texture
								end
							end
						end

						-- Check Texture IDs
						if texture and type(texture) == "number" and (
							texture == 136453 or 
							texture == 609653 
						) then
							isRingOverlay = true
							ringMatchReason = "FileID=" .. texture
						end
						
						if isRingOverlay then
							region:SetShown(shouldShowPortrait)
							region:SetAlpha(shouldShowPortrait and 1 or 0)
						end
					end
				end
			end
		end

		-- Scan Frame and Children
		ProcessRegions(frame, "MainFrame")
		if frame.GetChildren then
			local children = {frame:GetChildren()}
			for _, child in ipairs(children) do
				local childName = child.GetName and child:GetName()
				-- Skip Settings Frame
				if childName ~= "BetterFriendlistSettingsFrame" then
					ProcessRegions(child, "Child:" .. (childName or "Anonymous"))
				end
			end
		end

		-- Title Adjustment (Layout Fix)
		if frame.TitleContainer then
			local xOffset = shouldShowPortrait and 58 or 5 
			frame.TitleContainer:ClearAllPoints()
			frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -1)
			frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -1)
		end
		
		-- BNet Frame Width Adjustment (Simple Mode Optimization)
		if frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame then
			local bnetFrame = frame.FriendsTabHeader.BattlenetFrame
			local baseWidth = 190 -- Default XML width

			if BFL.IsClassic then
				baseWidth = baseWidth - 40
			end
			
			local extraWidth = shouldShowPortrait and 0 or 45

			-- Further reduce width by 10px for Classic Simple Mode (User Request: Add 20px back from previous -30)
			-- Update: Removed reduction because base is now 55 (matching Classic target)
			if BFL.IsClassic and not shouldShowPortrait then
				extraWidth = extraWidth + 10
			end
			
			local totalWidth = baseWidth + extraWidth
			
			-- Check if ElvUI is active - if yes, don't override the width set by ElvUI skin
			local isElvUIActive = _G.ElvUI and BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin ~= false
			if not (BFL.IsClassic and isElvUIActive) then
				bnetFrame:SetWidth(totalWidth)
			end

			-- Position Adjustment (Centering)
			-- Check if ElvUI is active - if yes, don't override the position set by ElvUI skin
			if not (BFL.IsClassic and isElvUIActive) then
				bnetFrame:ClearAllPoints()
				if BFL.IsClassic and not shouldShowPortrait then
					-- Shift right to center (Default x=10, shifting right by +5 to x=15)
					bnetFrame:SetPoint("TOP", frame.TitleContainer, "TOP", 10, -26)
				else
					-- Restore default XML position
					bnetFrame:SetPoint("TOP", frame.TitleContainer, "TOP", 10, -26)
				end
			end
		end

		-- Search Row & Tab Adjustment (Simple Mode Layout Shift)
		if frame.FriendsTabHeader then
			local header = frame.FriendsTabHeader
			local elementsToHide = {
				-- header.SearchBox, -- Managed by FriendsList module to prevent conflicts
				header.QuickFilterDropdown,
				header.PrimarySortDropdown,
				header.SecondarySortDropdown
			}
			
			for i, elem in ipairs(elementsToHide) do
				if elem then elem:SetShown(shouldShow) end
			end
			
			-- Move Tabs Upwards to fill the gap
			if header.Tab1 then
				header.Tab1:ClearAllPoints()
				local yOffset = -95 -- Default Retail
				if shouldShow then
					if BFL.IsClassic then
						yOffset = -120
					end
				else
					yOffset = -60
				end
				
				header.Tab1:SetPoint("TOPLEFT", header, "TOPLEFT", 18, yOffset)
			end

			-- Classic Layout Adjustments
			-- Skip if ElvUI is active - ElvUI Skin handles positioning
			local isElvUIActive = _G.ElvUI and BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin ~= false
			if BFL.IsClassic and shouldShow and not isElvUIActive then
				if header.PrimarySortDropdown then
					header.PrimarySortDropdown:ClearAllPoints()
					header.PrimarySortDropdown:SetPoint("TOP", header, "TOP", 0, -60)
				end
				
				if header.QuickFilterDropdown and header.PrimarySortDropdown then
					header.QuickFilterDropdown:ClearAllPoints()
					header.QuickFilterDropdown:SetPoint("TOPRIGHT", header.PrimarySortDropdown, "TOPLEFT", 10, 0)
				end
				
				if header.SearchBox then
					-- Managed by FriendsList:UpdateSearchBoxState (Phase 22)
					-- Do not override here to avoid race conditions/jumping
				end
			end
		end
	end
end

-- Open Configuration
function BFL:OpenConfig()
	local Settings = self:GetModule("Settings")
	if Settings then
		-- Check if settings frame is already shown
		if _G.BetterFriendlistSettingsFrame and _G.BetterFriendlistSettingsFrame:IsShown() then
			Settings:Hide()
			return
		end

		-- Ensure main frame is visible first
		if _G.BetterFriendsFrame and not _G.BetterFriendsFrame:IsShown() then
			if _G.ToggleBetterFriendsFrame then
				_G.ToggleBetterFriendsFrame()
			end
		end
		Settings:Show()
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
	
	-- Special handling for FRIENDLIST_UPDATE to prevent "script ran too long" errors
	-- This event can fire multiple times rapidly and trigger heavy processing in multiple modules
	if event == "FRIENDLIST_UPDATE" then
		-- Debounce: Cancel pending update
		if self.pendingUpdateTicker then
			self.pendingUpdateTicker:Cancel()
		end
		
		-- Schedule new update (0.2s delay to coalesce rapid updates)
		self.pendingUpdateTicker = C_Timer.NewTimer(0.2, function()
			self.pendingUpdateTicker = nil
			
			-- Run callbacks staggered to prevent frame freeze
			local callbacks = self.EventCallbacks[event]
			if not callbacks then return end
			
			local index = 1
			local numCallbacks = #callbacks
			
			-- Process one callback every 0.05s
			C_Timer.NewTicker(0.05, function(timer)
				if index > numCallbacks then
					timer:Cancel()
					return
				end
				
				local entry = callbacks[index]
				if entry and entry.callback then
					-- Use pcall to prevent one error from stopping the chain
					local success, err = pcall(entry.callback)
					if not success then
						BFL:DebugPrint("|cffff0000BFL Error in FRIENDLIST_UPDATE callback:|r " .. tostring(err))
					end
				end
				index = index + 1
			end)
		end)
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
function BFL:NormalizeWoWFriendName(name, playerRealm)
	if not name or name == "" then
		return nil
	end
	
	-- If name already contains realm separator, it's already normalized
	if string.find(name, "-") then
		return name
	end
	
	-- Name has no realm - append current player's realm
	-- Using GetNormalizedRealmName() which returns the connected realm name
	-- Optimization: Allow passing playerRealm to avoid repeated API calls in loops
	local realm = playerRealm or GetNormalizedRealmName()
	if realm and realm ~= "" then
		return name .. "-" .. realm
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
		-- Update font cache (colors, sizes, etc) in case settings changed
		if FriendsList.UpdateFontCache then
			FriendsList:UpdateFontCache()
		end

		-- Clear pending update flag to prevent overwriting our forced refresh
		FriendsList:ClearPendingUpdate()
		
		-- Force immediate data update from WoW API
		-- This ensures we have the latest friend data before rendering
		FriendsList:UpdateFriendsList()
	end
	
	-- Refresh WhoFrame font cache if loaded
	local WhoFrame = self:GetModule("WhoFrame")
	if WhoFrame then
		WhoFrame:InvalidateFontCache()
		-- If WhoFrame is visible, trigger update
		if BetterFriendsFrame and BetterFriendsFrame.WhoFrame and BetterFriendsFrame.WhoFrame:IsShown() then
			if _G.BetterWhoFrame_Update then
				_G.BetterWhoFrame_Update(true)
			end
		end
	end
	
	-- Refresh RaidFrame if loaded and visible
	local RaidFrame = self:GetModule("RaidFrame")
	if RaidFrame and BetterFriendsFrame and BetterFriendsFrame.RaidFrame and BetterFriendsFrame.RaidFrame:IsShown() then
		RaidFrame:UpdateAllMemberButtons()
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

			-- Best Practice: Register LibSharedMedia callbacks (modern approach)
			-- Ensures fonts update immediately if a new font is registered (e.g. by another addon)
			local LSM = LibStub("LibSharedMedia-3.0", true)
			if LSM then
				local function OnMediaUpdate(event, mediaType, key)
					if mediaType == LSM.MediaType.FONT then
						if BFL.ForceRefreshFriendsList then
							BFL:ForceRefreshFriendsList()
						end
					end
				end
				LSM.RegisterCallback("BetterFriendlist", "LibSharedMedia_Registered", OnMediaUpdate)
				LSM.RegisterCallback("BetterFriendlist", "LibSharedMedia_SetGlobal", OnMediaUpdate)
			end
			
			-- Initialize NotificationSystem (cooldown timer, etc.)
			-- Note: Initialize() calls RegisterEvents() internally if Beta is enabled
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
			
			-- Version-aware success message
			local versionSuffix = BFL.IsMidnight and " (Midnight)" 
				or (BFL.IsClassicEra and " (Classic Era)")
				or (BFL.IsMoPClassic and " (MoP Classic)")
				or (BFL.IsCataClassic and " (Cata Classic)")
				or (BFL.IsWrathClassic and " (Wrath Classic)")
				or (BFL.IsTBCClassic and " (TBC Classic)")
				or " (TWW)"
			print(string.format(BFL.L.CORE_LOADED, BFL.VERSION, versionSuffix))
			
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
				-- BFL:DebugPrint("|cff00ff00[BFL]|r FriendsFrame removed from UIPanel system (combat-safe)")
			end
			
			-- Store original function for "Show Blizzard's Friendlist" option
			if _G.ToggleFriendsFrame then
				BFL.OriginalToggleFriendsFrame = _G.ToggleFriendsFrame
				
				-- Replace global with our version (taint-safe, not a protected function)
				_G.ToggleFriendsFrame = function(tabIndex)
					-- Allow original if explicitly requested
					if BFL.AllowBlizzardFriendsFrame then
						-- BFL:DebugPrint("[BFL] ToggleFriendsFrame: Allowing Blizzard (explicit)")
						return BFL.OriginalToggleFriendsFrame(tabIndex)
					end
					
					-- BFL:DebugPrint("[BFL] ToggleFriendsFrame: Opening BetterFriendlist, tabIndex: " .. tostring(tabIndex))
					
					-- Toggle our frame with the requested tab (combat-safe, our frame is not protected)
					if _G.ToggleBetterFriendsFrame then
						_G.ToggleBetterFriendsFrame(tabIndex)
					end
				end
				-- BFL:DebugPrint("|cff00ff00[BFL]|r ToggleFriendsFrame global replaced")
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
					-- BFL:DebugPrint("[BFL] ShowFriends: Redirecting to BetterFriendlist")
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
						-- BFL:DebugPrint("[BFL] FriendsFrame:OnShow - Allowing (explicit)")
						return
					end
					
					-- Detect which tab was requested by reading Blizzard's selected tab
					-- FRIEND_TAB_FRIENDS=1, FRIEND_TAB_WHO=2, FRIEND_TAB_RAID=3, FRIEND_TAB_QUICK_JOIN=4
					local requestedTab = PanelTemplates_GetSelectedTab(FriendsFrame) or 1
					-- BFL:DebugPrint("[BFL] FriendsFrame:OnShow - Intercepting, requested tab: " .. tostring(requestedTab))
					
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
				-- BFL:DebugPrint("|cff00ff00[BFL]|r FriendsFrame:OnShow hooked for ElvUI compatibility")
			end
		end
	elseif event == "PLAYER_LOGIN" then
		-- Check for native event callbacks (12.0.0+)
		if BetterFriendsFrame and BetterFriendsFrame.RegisterEventCallback then
			BFL.UseNativeCallbacks = true
			-- BFL:DebugPrint("|cff00ff00[BFL]|r Using native Frame:RegisterEventCallback (12.0.0+)")
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
	
	-- Update Portrait Visibility on Login
	if event == "PLAYER_LOGIN" then
		-- Hook OnShow to ensure portrait visibility persists despite template resets
		-- ButtonFrameTemplate can reset portrait visibility on show, so we re-apply our rules every time
		if BetterFriendsFrame then
			BetterFriendsFrame:HookScript("OnShow", function()
				BFL:UpdatePortraitVisibility("OnShow")
			end)
		end
		
		-- Initial update
		BFL:UpdatePortraitVisibility("PLAYER_LOGIN")
	end
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

	-- Debug Corner (Diagnostic tool for Classic corner issues)
	elseif msg == "debugcorner" then
		local frame = BetterFriendsFrame
		if not frame then BFL:DebugPrint("Frame not found"); return end

		-- Check the original XML region
		local regionName = "BetterFriendsFrameTopLeftCorner"
		local region = _G[regionName]
		if region then
			BFL:DebugPrint("Original Region: " .. regionName)
			BFL:DebugPrint("  IsShown: " .. tostring(region:IsShown()))
			local w, h = region:GetSize()
			BFL:DebugPrint("  Size: " .. tostring(w) .. "x" .. tostring(h))
			local tex = region:GetTexture()
			BFL:DebugPrint("  Texture: " .. tostring(tex))
			BFL:DebugPrint("  Alpha: " .. tostring(region:GetAlpha()))
			local layer, sub = region:GetDrawLayer()
			BFL:DebugPrint("  Layer: " .. tostring(layer) .. " (" .. tostring(sub) .. ")")
			local nPoints = region:GetNumPoints()
			BFL:DebugPrint("  NumPoints: " .. nPoints)
			if nPoints > 0 then
				local point, relTo, relPoint, x, y = region:GetPoint(1)
				local relName = (relTo and relTo.GetName) and relTo:GetName() or tostring(relTo)
				BFL:DebugPrint("  Point 1: " .. tostring(point) .. " -> " .. relName .. " [" .. tostring(x) .. ", " .. tostring(y) .. "]")
			end
		else
			BFL:DebugPrint("Original Region (" .. regionName .. ") not found in global namespace")
		end

		-- Check our custom patch
		if frame.SimpleCornerPatch then
			BFL:DebugPrint("Patch Region (SimpleCornerPatch) found on frame")
			local p = frame.SimpleCornerPatch
			BFL:DebugPrint("  IsShown: " .. tostring(p:IsShown()))
			local w, h = p:GetSize()
			BFL:DebugPrint("  Size: " .. tostring(w) .. "x" .. tostring(h))
			local tex = p:GetTexture()
			BFL:DebugPrint("  Texture: " .. tostring(tex))
			local r, g, b, a = p:GetVertexColor()
			BFL:DebugPrint(string.format("  VertexColor: %.2f, %.2f, %.2f, %.2f", r or 0, g or 0, b or 0, a or 1))
			local layer, sub = p:GetDrawLayer()
			BFL:DebugPrint("  Layer: " .. tostring(layer) .. " (" .. tostring(sub) .. ")")
			
			local nPoints = p:GetNumPoints()
			if nPoints > 0 then
				local point, relTo, relPoint, x, y = p:GetPoint(1)
				local relName = (relTo and relTo.GetName) and relTo:GetName() or tostring(relTo)
				BFL:DebugPrint("  Point 1: " .. tostring(point) .. " -> " .. relName .. " [" .. tostring(x) .. ", " .. tostring(y) .. "]")
			else
				BFL:DebugPrint("  WARNING: Patch has NO points set!")
			end
		else
			BFL:DebugPrint("Patch Region (SimpleCornerPatch) NOT found on frame")
		end
		BFL:DebugPrint("------------------------")

	-- Missing Locales tool
	elseif msg == "missing" then
		if BFL.ShowMissingLocalesFrame then
			BFL:ShowMissingLocalesFrame()
		else
			print("|cffff0000BetterFriendlist:|r Missing Locales tool not available.")
		end
	
	-- Legacy commands (from old BetterFriendlist.lua slash handler)
	elseif msg == "show" then
		if BFL.DB then
			BFL.DB:Set("showBlizzardOption", true)
			print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_SHOW_BLIZZARD_ENABLED)
		end
	elseif msg == "hide" then
		if BFL.DB then
			BFL.DB:Set("showBlizzardOption", false)
			print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_SHOW_BLIZZARD_DISABLED)
		end
	elseif msg == "toggle" then
		if BFL.DB then
			local current = BFL.DB:Get("showBlizzardOption", false)
			BFL.DB:Set("showBlizzardOption", not current)
			if not current then
				print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_SHOW_BLIZZARD_ENABLED)
			else
				print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_SHOW_BLIZZARD_DISABLED)
			end
		end
	elseif msg == "database" or msg == "db" or msg == "debugdb" then
		if _G.BetterFriendlistSettings_DebugDatabase then
			_G.BetterFriendlistSettings_DebugDatabase()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_DEBUG_DB_NOT_AVAIL)
		end
	
	-- Debug Activity Tracking
	elseif msg == "activity" or msg == "debugactivity" then
		local DB = BFL:GetModule("DB")
		if not DB then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_DB_MODULE_NOT_AVAIL)
			return
		end
		
		local friendActivity = DB:Get("friendActivity") or {}
		local count = 0
		for _ in pairs(friendActivity) do count = count + 1 end
		
		BFL:DebugPrint(BFL.L.CORE_ACTIVITY_TRACKING_HEADER)
		BFL:DebugPrint(string.format(BFL.L.CORE_ACTIVITY_TOTAL_FRIENDS, count))
		BFL:DebugPrint("")
		
		for friendUID, activities in pairs(friendActivity) do
			BFL:DebugPrint("|cffffcc00" .. friendUID .. "|r")
			if activities.lastWhisper then
				BFL:DebugPrint(string.format("  lastWhisper: %d (%s ago)", activities.lastWhisper, SecondsToTime(time() - activities.lastWhisper)))
			end
			if activities.lastGroup then
				BFL:DebugPrint(string.format("  lastGroup: %d (%s ago)", activities.lastGroup, SecondsToTime(time() - activities.lastGroup)))
			end
			if activities.lastTrade then
				BFL:DebugPrint(string.format("  lastTrade: %d (%s ago)", activities.lastTrade, SecondsToTime(time() - activities.lastTrade)))
			end
		end
	
	-- Test Notifications
	elseif msg == "testnotify" or msg == "testnotification" then
		local NotificationSystem = BFL.NotificationSystem
		if not NotificationSystem then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_NOTIFICATION_MODULE_NOT_LOADED)
			return
		end
		
		-- Check if Beta features enabled
		if not BetterFriendlistDB.enableBetaFeatures then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_BETA_FEATURES_DISABLED_MSG)
			print(BFL.L.CORE_BETA_ENABLE_HINT)
			return
		end
		
		print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_TRIGGERING_TEST_NOTIFICATIONS)
		
		-- Trigger 3 test notifications to demonstrate multi-toast system
		NotificationSystem:ShowNotification("Test Friend 1", "is now online playing World of Warcraft", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		C_Timer.After(0.2, function()
			NotificationSystem:ShowNotification("Test Friend 2", "switched to Warrior", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		end)
		C_Timer.After(0.4, function()
			NotificationSystem:ShowNotification("Test Friend 3", "logged into World of Warcraft", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
		end)
		
		print(BFL.L.CORE_TEST_NOTIFICATIONS_SUCCESS)
		print(BFL.L.CORE_TEST_NOTIFICATIONS_TIP)
	
	-- Test Group Notification Rules
	elseif msg == "testgrouprules" or msg == "testgroup" then
		local NotificationSystem = BFL.NotificationSystem
		if not NotificationSystem then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_NOTIFICATION_MODULE_NOT_LOADED)
			return
		end
		
		NotificationSystem:TestGroupRules()
	
	-- Statistics
	elseif msg == "stats" or msg == "statistics" then
		local Statistics = BFL:GetModule("Statistics")
		if not Statistics then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_STATISTICS_MODULE_NOT_LOADED)
			return
		end
		
		local stats = Statistics:GetStatistics()
		BFL:DebugPrint(BFL.L.CORE_STATISTICS_HEADER)
		BFL:DebugPrint("")
		
		-- Overview
		BFL:DebugPrint(BFL.L.CORE_STATS_OVERVIEW)
		BFL:DebugPrint(string.format(BFL.L.CORE_STATS_TOTAL_ONLINE_OFFLINE, 
			stats.totalFriends, 
			stats.onlineFriends, (stats.onlineFriends / math.max(stats.totalFriends, 1)) * 100,
			stats.offlineFriends, (stats.offlineFriends / math.max(stats.totalFriends, 1)) * 100))
		BFL:DebugPrint(string.format(BFL.L.CORE_STATS_BNET_WOW, stats.bnetFriends, stats.wowFriends))
		BFL:DebugPrint("")
		
		-- Friendship Health
		BFL:DebugPrint(BFL.L.CORE_STATS_FRIENDSHIP_HEALTH)
		local totalHealthFriends = stats.totalFriends - (stats.friendshipHealth.unknown or 0)
		if totalHealthFriends > 0 then
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_HEALTH_ACTIVE,
				stats.friendshipHealth.active, (stats.friendshipHealth.active / totalHealthFriends) * 100,
				stats.friendshipHealth.regular, (stats.friendshipHealth.regular / totalHealthFriends) * 100,
				stats.friendshipHealth.drifting, (stats.friendshipHealth.drifting / totalHealthFriends) * 100))
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_HEALTH_STALE,
				stats.friendshipHealth.stale, (stats.friendshipHealth.stale / totalHealthFriends) * 100,
				stats.friendshipHealth.dormant, (stats.friendshipHealth.dormant / totalHealthFriends) * 100))
		else
			BFL:DebugPrint(BFL.L.CORE_STATS_NO_HEALTH_DATA)
		end
		BFL:DebugPrint("")
		
		-- Class Distribution (Top 5)
		local topClasses = Statistics:GetTopClasses(5)
		if #topClasses > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_CLASS_DISTRIBUTION)
			for i, class in ipairs(topClasses) do
				local pct = (class.count / math.max(stats.totalFriends, 1)) * 100
				BFL:DebugPrint(string.format("  %d. %s: |cffffffff%d|r (%.0f%%)", i, class.name, class.count, pct))
			end
			BFL:DebugPrint("")
		end
		
		-- Level Distribution
		if stats.levelDistribution.leveledFriends > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_LEVEL_DISTRIBUTION)
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_LEVEL_BREAKDOWN,
				stats.levelDistribution.maxLevel,
				stats.levelDistribution.ranges[1].count,
				stats.levelDistribution.ranges[2].count,
				stats.levelDistribution.ranges[3].count))
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_AVG_LEVEL, stats.levelDistribution.average))
			BFL:DebugPrint("")
		end
		
		-- Realm Clusters
		local topRealms = Statistics:GetTopRealms(5)
		if #topRealms > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_REALM_CLUSTERS)
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_REALM_BREAKDOWN,
				stats.realmDistribution.sameRealm, (stats.realmDistribution.sameRealm / math.max(stats.totalFriends, 1)) * 100,
				stats.realmDistribution.otherRealms, (stats.realmDistribution.otherRealms / math.max(stats.totalFriends, 1)) * 100))
			BFL:DebugPrint(BFL.L.CORE_STATS_TOP_REALMS)
			for i, realm in ipairs(topRealms) do
				BFL:DebugPrint(string.format("    %d. %s: |cffffffff%d|r", i, realm.name, realm.count))
			end
			BFL:DebugPrint("")
		end
		
		-- Faction Split
		if stats.factionCounts.alliance > 0 or stats.factionCounts.horde > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_FACTION_SPLIT)
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_FACTION_DATA,
				stats.factionCounts.alliance, stats.factionCounts.horde))
			BFL:DebugPrint("")
		end
		
		-- Game Distribution
		local totalGamePlayers = stats.gameCounts.wow + stats.gameCounts.classic + stats.gameCounts.diablo + 
		                         stats.gameCounts.hearthstone + stats.gameCounts.starcraft + stats.gameCounts.mobile + stats.gameCounts.other
		if totalGamePlayers > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_GAME_DISTRIBUTION)
			if stats.gameCounts.wow > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_WOW, stats.gameCounts.wow))
			end
			if stats.gameCounts.classic > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_CLASSIC, stats.gameCounts.classic))
			end
			if stats.gameCounts.diablo > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_DIABLO, stats.gameCounts.diablo))
			end
			if stats.gameCounts.hearthstone > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_HEARTHSTONE, stats.gameCounts.hearthstone))
			end
			if stats.gameCounts.starcraft > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_STARCRAFT, stats.gameCounts.starcraft))
			end
			if stats.gameCounts.mobile > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_MOBILE, stats.gameCounts.mobile))
			end
			if stats.gameCounts.other > 0 then
				BFL:DebugPrint(string.format(BFL.L.CORE_STATS_GAME_OTHER, stats.gameCounts.other))
			end
			BFL:DebugPrint("")
		end
		
		-- Mobile vs Desktop
		if stats.mobileVsDesktop.desktop > 0 or stats.mobileVsDesktop.mobile > 0 then
			BFL:DebugPrint(BFL.L.CORE_STATS_MOBILE_VS_DESKTOP)
			BFL:DebugPrint(string.format(BFL.L.CORE_STATS_MOBILE_DATA,
				stats.mobileVsDesktop.desktop, (stats.mobileVsDesktop.desktop / math.max(stats.onlineFriends, 1)) * 100,
				stats.mobileVsDesktop.mobile, (stats.mobileVsDesktop.mobile / math.max(stats.onlineFriends, 1)) * 100))
			BFL:DebugPrint("")
		end
		
		-- Notes and Favorites
		BFL:DebugPrint(BFL.L.CORE_STATS_ORGANIZATION)
		BFL:DebugPrint(string.format(BFL.L.CORE_STATS_ORG_DATA,
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
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_SETTINGS_NOT_LOADED)
		end
	
	-- Mock Friend Invites
	elseif msg == "invite" or msg == "invites" or msg == "mockinvite" or msg == "mockinvites" then
		-- Enable mock system if not already enabled
		if not BFL.MockFriendInvites.enabled then
			BFL.MockFriendInvites.enabled = true
			print("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_MOCK_INVITES_ENABLED)
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
		
		print(string.format("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_MOCK_INVITE_ADDED, battleTag, #BFL.MockFriendInvites.invites))
		print(BFL.L.CORE_MOCK_INVITE_TIP)
		
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
			print(string.format("|cff00ff00BetterFriendlist:|r " .. BFL.L.CORE_MOCK_INVITES_CLEARED, count))
			
			-- Force immediate refresh
			if count > 0 then
				BFL:ForceRefreshFriendsList()
			end
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_NO_MOCK_INVITES)
		end
	
	-- ==========================================
	-- Performance Monitoring Commands (was /bflperf)
	-- ==========================================
	elseif msg == "perf" or msg == "perf report" or msg == "perf show" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:Report()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_PERF_MONITOR_NOT_LOADED)
		end
	elseif msg == "perf reset" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:Reset()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_PERF_MONITOR_NOT_LOADED)
		end
	elseif msg == "perf enable" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:EnableAutoMonitoring()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_PERF_MONITOR_NOT_LOADED)
		end
	elseif msg == "perf memory" then
		local PerformanceMonitor = BFL:GetModule("PerformanceMonitor")
		if PerformanceMonitor then
			PerformanceMonitor:SampleMemory()
		end
		UpdateAddOnMemoryUsage()
		local memory = GetAddOnMemoryUsage("BetterFriendlist") or 0
		print(string.format("|cff00ff00BetterFriendlist " .. BFL.L.CORE_MEMORY_USAGE .. "|r", memory))
	
	-- ==========================================
	-- Quick Join Commands (was /bflqj)
	-- ==========================================
	elseif msg:match("^qj") or msg:match("^quickjoin") then
		local QuickJoin = BFL:GetModule("QuickJoin")
		if not QuickJoin then
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_QUICKJOIN_NOT_LOADED)
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
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_RAIDFRAME_NOT_LOADED)
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
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_RAIDFRAME_NOT_LOADED)
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
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_PREVIEW_MODE_NOT_LOADED)
		end
	
	-- ==========================================
	-- Test Commands (was /bfltest)
	-- ==========================================
	elseif msg == "test" or msg == "test activity" then
		if SlashCmdList["ACTIVITYTRACKER_TEST"] then
			SlashCmdList["ACTIVITYTRACKER_TEST"]("activity")
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_ACTIVITY_TEST_NOT_LOADED)
		end
	
	-- ==========================================
	-- Classic Compatibility Info
	-- ==========================================
	elseif msg == "compat" or msg == "compatibility" or msg == "classic" then
		BFL:DebugPrint(BFL.L.CORE_CLASSIC_COMPAT_HEADER)
		BFL:DebugPrint("")
		BFL:DebugPrint(BFL.L.CORE_CLIENT_VERSION)
		BFL:DebugPrint(string.format("  Interface Version: |cffffffff%d|r", select(4, GetBuildInfo())))
		BFL:DebugPrint(string.format("  Build: |cffffffff%s|r", select(1, GetBuildInfo())))
		BFL:DebugPrint("")
		BFL:DebugPrint(BFL.L.CORE_DETECTED_FLAVOR)
		if BFL.IsClassicEra then
			BFL:DebugPrint(BFL.L.CORE_FLAVOR_CLASSIC_ERA)
		elseif BFL.IsMoPClassic then
			BFL:DebugPrint(BFL.L.CORE_FLAVOR_MOP)
		elseif BFL.IsTWW then
			BFL:DebugPrint(BFL.L.CORE_FLAVOR_TWW)
		elseif BFL.IsMidnight then
			BFL:DebugPrint(BFL.L.CORE_FLAVOR_MIDNIGHT)
		else
			BFL:DebugPrint(BFL.L.CORE_FLAVOR_RETAIL)
		end
		BFL:DebugPrint("")
		BFL:DebugPrint(BFL.L.CORE_FEATURE_AVAILABILITY)
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_MODERN_SCROLLBOX, BFL.HasModernScrollBox and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_MODERN_MENU, BFL.HasModernMenu and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_RECENT_ALLIES, BFL.HasRecentAllies and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_EDIT_MODE, BFL.HasEditMode and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_MODERN_DROPDOWN, BFL.HasModernDropdown and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint(string.format(BFL.L.CORE_FEATURE_MODERN_COLORPICKER, BFL.HasModernColorPicker and "|cff00ff00Yes|r" or "|cffff0000No|r"))
		BFL:DebugPrint("")
		if BFL.Compat then
			BFL:DebugPrint(string.format(BFL.L.CORE_COMPAT_LAYER, BFL.L.CORE_COMPAT_ACTIVE))
		else
			BFL:DebugPrint(string.format(BFL.L.CORE_COMPAT_LAYER, BFL.L.CORE_COMPAT_NOT_LOADED))
		end
	
	-- Use internal reset function
	elseif msg == "reset_changelog" or msg == "resetchangelog" then
		local DB = BFL:GetModule("DB")
		local Changelog = BFL:GetModule("Changelog")
		if DB and Changelog then
			DB:Set("lastChangelogVersion", "0.0.0")
			Changelog:CheckVersion()
			print("|cff00ff00BetterFriendlist:|r " .. (BFL.L.CORE_CHANGELOG_RESET or "Changelog reset."))
		else
			print("|cffff0000BetterFriendlist:|r " .. (BFL.L.MSG_SETTINGS_RESET or "Could not reset changelog.")) 
		end

	-- TEMPORARY: Reset Font Colors (Phase 20)
	elseif msg == "resetcolors" then
		local DB = BFL:GetModule("DB")
		if DB then
			DB:ResetFontColors()
		else
			print("|cffff0000BetterFriendlist:|r Database module not loaded.")
		end

	-- Debug: Check UIPanelWindows settings
	elseif msg == "checkpanel" or msg == "panel" then
		BFL:DebugPrint(BFL.L.CORE_DEBUG_PANEL_HEADER)
		BFL:DebugPrint("")
		
		-- Check Blizzard FriendsFrame original settings (stored)
		if BFL.OriginalFriendsFrameUIPanelSettings then
			BFL:DebugPrint(BFL.L.CORE_DEBUG_BLIZZARD_SETTINGS)
			local sortedKeys = {}
			for k in pairs(BFL.OriginalFriendsFrameUIPanelSettings) do
				table.insert(sortedKeys, k)
			end
			table.sort(sortedKeys)
			for _, k in ipairs(sortedKeys) do
				local v = BFL.OriginalFriendsFrameUIPanelSettings[k]
				if k == "pushable" then
					BFL:DebugPrint(string.format("  %s: |cff00ff00%s|r  <-- BLIZZARD VALUE", k, tostring(v)))
				else
					BFL:DebugPrint(string.format("  %s: |cffffffff%s|r", k, tostring(v)))
				end
			end
			BFL:DebugPrint("")
		else
			BFL:DebugPrint(BFL.L.CORE_DEBUG_NO_STORED)
			BFL:DebugPrint("")
		end
		
		-- Check current BetterFriendsFrame attributes
		if BetterFriendsFrame then
			BFL:DebugPrint(BFL.L.CORE_DEBUG_BFL_ATTRS)
			local attrs = {
				"UIPanelLayout-defined",
				"UIPanelLayout-enabled",
				"UIPanelLayout-area",
				"UIPanelLayout-pushable",
				"UIPanelLayout-whileDead"
			}
			for _, attr in ipairs(attrs) do
				local val = BetterFriendsFrame:GetAttribute(attr)
				BFL:DebugPrint(string.format("  %s: |cffffffff%s|r", attr, tostring(val)))
			end
			BFL:DebugPrint("")
		end
		
		-- Check if in UIPanelWindows
		if UIPanelWindows then
			if UIPanelWindows["BetterFriendsFrame"] then
				BFL:DebugPrint(BFL.L.CORE_DEBUG_UIPANEL_YES)
				for k, v in pairs(UIPanelWindows["BetterFriendsFrame"]) do
					BFL:DebugPrint(string.format("  %s: |cffffffff%s|r", k, tostring(v)))
				end
			else
				BFL:DebugPrint(BFL.L.CORE_DEBUG_UIPANEL_NO)
			end
			BFL:DebugPrint("")
			
			if UIPanelWindows["FriendsFrame"] then
				BFL:DebugPrint(BFL.L.CORE_DEBUG_FRIENDSFRAME_WARNING)
			end
		end
		
		-- Check current setting
		local DB = BFL:GetModule("DB")
		if DB then
			local setting = DB:Get("useUIPanelSystem")
			BFL:DebugPrint(string.format(BFL.L.CORE_DEBUG_CURRENT_SETTING, setting and BFL.L.STATUS_ENABLED or BFL.L.STATUS_DISABLED))
		end

	-- Localization Switching
	elseif msg:match("^loc") or msg:match("^setloc") or msg:match("^setlocale") then
		local newLocale = msg:match("^loc%s+(%w+)") or msg:match("^setloc%s+(%w+)") or msg:match("^setlocale%s+(%w+)")
		if newLocale then
			if BFL.SetLocale then
				BFL:SetLocale(newLocale)
			else
				print("|cffff0000BetterFriendlist:|r Localization system update required.")
			end
		else
			print("Usage: /bfl loc <locale> (e.g. /bfl loc frFR)")
		end

	-- Test Translations (Encoding Check)
	elseif msg == "testlocales" or msg == "testencoding" or msg == "testenc" then
		BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. (BFL.L.CORE_HELP_TEST_LOCALES or "Testing Localization Encoding..."))
		BFL:DebugPrint("Locale: " .. GetLocale())
		
		-- List of strings with special characters to test
		local testKeys = {
			"DIALOG_DELETE_GROUP_TEXT", -- é, ê, û
			"NOTIFICATIONS_SET_MSG_BLACKLIST", -- é, à
			"CORE_STATISTICS_HEADER", -- é
			"SETTINGS_BETA_FEATURES_ENABLED", -- é, È
			"DIALOG_MIGRATE_TEXT", -- é, è
			"FILTER_SEARCH_ONLINE", -- varies by locale
			"STATUS_AFK" -- varies
		}
		
		for _, key in ipairs(testKeys) do
			if BFL.L[key] then
				BFL:DebugPrint(string.format("|cffffcc00%s:|r %s", key, BFL.L[key]))
			else
				BFL:DebugPrint(string.format("|cffff0000Missing:|r %s", key))
			end
		end
		BFL:DebugPrint("|cff00ff00End of Test|r")

	-- Help (or any other unrecognized command)
	elseif msg == "changelog" or msg == "changes" then
		local Changelog = BFL:GetModule("Changelog")
		if Changelog then
			Changelog:Show()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_CHANGELOG_NOT_LOADED)
		end

	else
		print(string.format(BFL.L.CORE_HELP_TITLE, BFL.VERSION))
		print("")
		print(BFL.L.CORE_HELP_MAIN_COMMANDS)
		print(BFL.L.CORE_HELP_CMD_TOGGLE)
		print(BFL.L.CORE_HELP_CMD_SETTINGS)
		print(BFL.L.CORE_HELP_CMD_HELP)
		print(BFL.L.CORE_HELP_CMD_CHANGELOG)
		print("")
		print(BFL.L.CORE_HELP_LINK)
	end
end
