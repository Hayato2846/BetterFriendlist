-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 2.3.6 - February 2026
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
local tocVersion = select(4, GetBuildInfo()) -- Returns TOC version (e.g., 110205)
BFL.TOCVersion = tocVersion

-- Classic Versions (check first - more specific)
BFL.IsClassicEra = (tocVersion < 20000) -- Classic Era (1.x)
BFL.IsTBCClassic = (tocVersion >= 20000 and tocVersion < 30000) -- TBC Classic (2.x) - legacy
BFL.IsWrathClassic = (tocVersion >= 30000 and tocVersion < 40000) -- Wrath Classic (3.x) - legacy
BFL.IsCataClassic = (tocVersion >= 40000 and tocVersion < 50000) -- Cata Classic (4.x) - legacy
BFL.IsMoPClassic = (tocVersion >= 50000 and tocVersion < 60000) -- MoP Classic (5.x)
BFL.IsClassic = BFL.IsClassicEra or BFL.IsMoPClassic or BFL.IsCataClassic or BFL.IsWrathClassic or BFL.IsTBCClassic

-- Retail Expansions
BFL.IsRetail = (tocVersion >= 100000) -- Dragonflight+ (10.x+)
BFL.IsTWW = (tocVersion >= 110200 and tocVersion < 120000) -- The War Within (11.x)
BFL.IsMidnight = (tocVersion >= 120000) -- Midnight (12.x+)

-- Feature Flags (detect what APIs are available)
BFL.HasModernScrollBox = BFL.IsRetail -- ScrollBox API (Retail 10.0+)
BFL.HasModernMenu = BFL.IsRetail -- MenuUtil, Menu.ModifyMenu (Retail 11.0+)
BFL.HasRecentAllies = BFL.IsTWW or BFL.IsMidnight -- C_RecentAllies (TWW 11.0.7+)
BFL.HasEditMode = BFL.IsRetail -- Edit Mode API (Retail 10.0+)
BFL.HasModernDropdown = BFL.IsRetail -- WowStyle1DropdownTemplate (Retail 10.0+)
BFL.HasModernColorPicker = BFL.IsRetail -- ColorPickerFrame:SetupColorPickerAndShow (Retail 10.1+)

-- Feature Detection (detect available APIs for optional features)
BFL.UseClassID = false -- 11.2.7+ classID optimization
BFL.HasSecretValues = false -- 12.0.0+ Secret Values API
BFL.UseNativeCallbacks = false -- 12.0.0+ Frame:RegisterEventCallback

-- Mock Friend Invites System (for testing)
BFL.MockFriendInvites = {
	enabled = false,
	invites = {},
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
	-- BFL:DebugPrint(string.format("|cff00ff00BetterFriendlist:|r TOC %d (%s)", tocVersion, versionName))

	if BFL.UseClassID then
		-- BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Using classID optimization (11.2.7+)")
	end
	if BFL.HasSecretValues then
		-- BFL:DebugPrint("|cff00ff00BetterFriendlist:|r Secret Values API detected (12.0.0+)")
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

-- Check if current execution path is restricted (Combat or secure execution)
function BFL:IsActionRestricted()
	if InCombatLockdown() then
		return true
	end
	if C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive and Enum.AddOnRestrictionType then
		for _, restrictionType in pairs(Enum.AddOnRestrictionType) do
			if C_RestrictedActions.IsAddOnRestrictionActive(restrictionType) then
				return true
			end
		end
	end
	return false
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
		if frame.PortraitContainer then
			frame.PortraitContainer:SetShown(shouldShowPortrait)
		end
		if frame.portrait then
			frame.portrait:SetShown(shouldShowPortrait)
		end
		if frame.PortraitButton then
			frame.PortraitButton:SetShown(shouldShowPortrait)
		end
		if frame.PortraitIcon then
			frame.PortraitIcon:SetShown(shouldShowPortrait)
		end
		if frame.PortraitMask then
			frame.PortraitMask:SetShown(shouldShowPortrait)
		end
		if frame.SetPortraitShown then
			frame:SetPortraitShown(shouldShowPortrait)
		end

		-- Also hide Global Portrait (Usually the Icon)
		local globalPortraitName = frame:GetName() .. "Portrait"
		local globalPortrait = _G[globalPortraitName]
		if globalPortrait then
			globalPortrait:SetShown(shouldShowPortrait)
		end

		-- DEEP SEARCH (The "Find that Ring" Way)
		-- We scan the frame regions AND immediate children's regions

		local function ProcessRegions(objectToScan, depthName)
			if not objectToScan then
				return
			end

			local objectName = (objectToScan.GetName and objectToScan:GetName()) or "Anonymous"

			local subRegions = { objectToScan:GetRegions() }
			for i, region in ipairs(subRegions) do
				if region:IsObjectType("Texture") then
					local regionName = region:GetName()
					local texture = region:GetTexture()
					local atlas = region:GetAtlas()

					-- Strategy 1: SWAP the structural corner (The "Hole" for the portrait)

					local isTargetCorner = false
					local matchReason = "None"

					-- Check Retail Atlas
					if
						atlas
						and (atlas == "UI-Frame-PortraitMetal-CornerTopLeft" or atlas == "UI-Frame-Metal-CornerTopLeft")
					then
						isTargetCorner = true
						matchReason = "Atlas=" .. atlas
					end

					-- Check Classic Texture Path
					if BFL.IsClassic and type(texture) == "string" then
						local texLower = texture:lower()
						if
							(texLower:find("friendsframe") and texLower:find("topleft"))
							or (texLower:find("ui%-friendsframe%-topleft"))
							or (texLower:find("helpframe") and texLower:find("topleft"))
						then -- Added helpframe check to re-detect our own fix
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
						if
							atlas
							and (
								atlas == "UI-Frame-Portrait"
								or atlas == "UI-Frame-Portrait-Blue"
								or atlas == "player-portrait-frame"
							)
						then
							isRingOverlay = true
							ringMatchReason = "Atlas=" .. atlas
						end

						-- Check Texture Path (Legacy/Classic rings)
						if texture and type(texture) == "string" then
							local texLower = texture:lower()
							if texLower:find("portrait") and not texLower:find("metal") then
								if
									texLower:find("ui%-frame%-portrait") -- Standard
									or texLower:find("ui%-friendsframe%-portrait") -- Classic FriendsFrame
									or texLower:find("portraitring") -- Rare variation
									or texLower:find("player%-portrait") -- Player frame style
								then
									isRingOverlay = true
									ringMatchReason = "TexturePath=" .. texture
								end
							end
						end

						-- Check Texture IDs
						if texture and type(texture) == "number" and (texture == 136453 or texture == 609653) then
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
			local children = { frame:GetChildren() }
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
				header.SecondarySortDropdown,
			}

			for i, elem in ipairs(elementsToHide) do
				if elem then
					elem:SetShown(shouldShow)
				end
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

-- 12.0.0+ Secret Values compatibility
-- Check if a value is a "secret" (cannot be inspected, compared, or iterated by tainted code)
-- Returns false on Classic and pre-12.0 clients where issecretvalue does not exist
function BFL:IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

-- Count table entries (for non-sequential tables)
function BFL:TableCount(tbl)
	if not tbl then
		return 0
	end
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
		priority = priority,
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
		-- Fast path: Until BNet data is fully loaded (battleTags available),
		-- bypass debounce for instant population on login/reload.
		-- Once data is ready, switch to debounced mode for burst protection.
		local FriendsList = self:GetModule("FriendsList")
		local bnetReady = FriendsList and FriendsList.bnetDataReady

		if not bnetReady then
			-- Immediate execution for initial data population (login/reload)
			-- Cancel any pending debounce timer from a previous rapid fire
			if self.pendingUpdateTicker then
				self.pendingUpdateTicker:Cancel()
				self.pendingUpdateTicker = nil
			end
			if self.callbackTicker then
				self.callbackTicker:Cancel()
				self.callbackTicker = nil
			end

			local callbacks = self.EventCallbacks[event]
			if callbacks then
				for _, entry in ipairs(callbacks) do
					if entry and entry.callback then
						local success, err = pcall(entry.callback)
						if not success then
							BFL:DebugPrint("|cffff0000BFL Error in FRIENDLIST_UPDATE callback:|r " .. tostring(err))
						end
					end
				end
			end
			return
		end

		-- Debounce: Cancel pending update
		if self.pendingUpdateTicker then
			self.pendingUpdateTicker:Cancel()
		end

		-- Schedule new update (0.2s delay to coalesce rapid updates)
		self.pendingUpdateTicker = C_Timer.NewTimer(0.2, function()
			self.pendingUpdateTicker = nil

			-- Cancel any previously running callback ticker to prevent double execution
			if self.callbackTicker then
				self.callbackTicker:Cancel()
				self.callbackTicker = nil
			end

			-- Run all callbacks immediately (staggering is unnecessary with only a few callbacks)
			local callbacks = self.EventCallbacks[event]
			if callbacks then
				for _, entry in ipairs(callbacks) do
					if entry and entry.callback then
						local success, err = pcall(entry.callback)
						if not success then
							BFL:DebugPrint("|cffff0000BFL Error in FRIENDLIST_UPDATE callback:|r " .. tostring(err))
						end
					end
				end
			end
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

--------------------------------------------------------------------------
-- Accent / Diacritics Normalization (Fuzzy Search)
--------------------------------------------------------------------------
-- Maps accented UTF-8 characters to their ASCII base form.
-- Used for accent-insensitive search so that "Hayato" matches "Hâyato".
-- WoW character names commonly use Latin Extended-A/B and Latin-1 Supplement
-- accented characters. We map each known multi-byte UTF-8 sequence to its
-- base ASCII character. The table is built once at load time.

do
	-- Map of accented character -> base ASCII character
	-- Covers Latin-1 Supplement (U+00C0-U+00FF) and Latin Extended-A (U+0100-U+017F)
	local ACCENT_MAP = {
		-- Uppercase Latin-1 Supplement
		["\195\128"] = "a", -- À
		["\195\129"] = "a", -- Á
		["\195\130"] = "a", -- Â
		["\195\131"] = "a", -- Ã
		["\195\132"] = "a", -- Ä
		["\195\133"] = "a", -- Å
		["\195\134"] = "ae", -- Æ
		["\195\135"] = "c", -- Ç
		["\195\136"] = "e", -- È
		["\195\137"] = "e", -- É
		["\195\138"] = "e", -- Ê
		["\195\139"] = "e", -- Ë
		["\195\140"] = "i", -- Ì
		["\195\141"] = "i", -- Í
		["\195\142"] = "i", -- Î
		["\195\143"] = "i", -- Ï
		["\195\144"] = "d", -- Ð
		["\195\145"] = "n", -- Ñ
		["\195\146"] = "o", -- Ò
		["\195\147"] = "o", -- Ó
		["\195\148"] = "o", -- Ô
		["\195\149"] = "o", -- Õ
		["\195\150"] = "o", -- Ö
		["\195\152"] = "o", -- Ø
		["\195\153"] = "u", -- Ù
		["\195\154"] = "u", -- Ú
		["\195\155"] = "u", -- Û
		["\195\156"] = "u", -- Ü
		["\195\157"] = "y", -- Ý
		["\195\158"] = "th", -- Þ
		["\195\159"] = "ss", -- ß
		-- Lowercase Latin-1 Supplement
		["\195\160"] = "a", -- à
		["\195\161"] = "a", -- á
		["\195\162"] = "a", -- â
		["\195\163"] = "a", -- ã
		["\195\164"] = "a", -- ä
		["\195\165"] = "a", -- å
		["\195\166"] = "ae", -- æ
		["\195\167"] = "c", -- ç
		["\195\168"] = "e", -- è
		["\195\169"] = "e", -- é
		["\195\170"] = "e", -- ê
		["\195\171"] = "e", -- ë
		["\195\172"] = "i", -- ì
		["\195\173"] = "i", -- í
		["\195\174"] = "i", -- î
		["\195\175"] = "i", -- ï
		["\195\176"] = "d", -- ð
		["\195\177"] = "n", -- ñ
		["\195\178"] = "o", -- ò
		["\195\179"] = "o", -- ó
		["\195\180"] = "o", -- ô
		["\195\181"] = "o", -- õ
		["\195\182"] = "o", -- ö
		["\195\184"] = "o", -- ø
		["\195\185"] = "u", -- ù
		["\195\186"] = "u", -- ú
		["\195\187"] = "u", -- û
		["\195\188"] = "u", -- ü
		["\195\189"] = "y", -- ý
		["\195\190"] = "th", -- þ
		["\195\191"] = "y", -- ÿ
		-- Latin Extended-A (U+0100-U+017F) - common in WoW names
		["\196\128"] = "a", -- Ā
		["\196\129"] = "a", -- ā
		["\196\130"] = "a", -- Ă
		["\196\131"] = "a", -- ă
		["\196\132"] = "a", -- Ą
		["\196\133"] = "a", -- ą
		["\196\134"] = "c", -- Ć
		["\196\135"] = "c", -- ć
		["\196\136"] = "c", -- Ĉ
		["\196\137"] = "c", -- ĉ
		["\196\138"] = "c", -- Ċ
		["\196\139"] = "c", -- ċ
		["\196\140"] = "c", -- Č
		["\196\141"] = "c", -- č
		["\196\142"] = "d", -- Ď
		["\196\143"] = "d", -- ď
		["\196\144"] = "d", -- Đ
		["\196\145"] = "d", -- đ
		["\196\146"] = "e", -- Ē
		["\196\147"] = "e", -- ē
		["\196\148"] = "e", -- Ĕ
		["\196\149"] = "e", -- ĕ
		["\196\150"] = "e", -- Ė
		["\196\151"] = "e", -- ė
		["\196\152"] = "e", -- Ę
		["\196\153"] = "e", -- ę
		["\196\154"] = "e", -- Ě
		["\196\155"] = "e", -- ě
		["\196\156"] = "g", -- Ĝ
		["\196\157"] = "g", -- ĝ
		["\196\158"] = "g", -- Ğ
		["\196\159"] = "g", -- ğ
		["\196\160"] = "g", -- Ġ
		["\196\161"] = "g", -- ġ
		["\196\162"] = "g", -- Ģ
		["\196\163"] = "g", -- ģ
		["\196\164"] = "h", -- Ĥ
		["\196\165"] = "h", -- ĥ
		["\196\166"] = "h", -- Ħ
		["\196\167"] = "h", -- ħ
		["\196\168"] = "i", -- Ĩ
		["\196\169"] = "i", -- ĩ
		["\196\170"] = "i", -- Ī
		["\196\171"] = "i", -- ī
		["\196\172"] = "i", -- Ĭ
		["\196\173"] = "i", -- ĭ
		["\196\174"] = "i", -- Į
		["\196\175"] = "i", -- į
		["\196\176"] = "i", -- İ
		["\196\177"] = "i", -- ı
		["\196\180"] = "j", -- Ĵ
		["\196\181"] = "j", -- ĵ
		["\196\182"] = "k", -- Ķ
		["\196\183"] = "k", -- ķ
		["\196\185"] = "l", -- Ĺ
		["\196\186"] = "l", -- ĺ
		["\196\187"] = "l", -- Ļ
		["\196\188"] = "l", -- ļ
		["\196\189"] = "l", -- Ľ
		["\196\190"] = "l", -- ľ
		["\196\191"] = "l", -- Ŀ
		["\197\128"] = "l", -- ŀ
		["\197\129"] = "l", -- Ł
		["\197\130"] = "l", -- ł
		["\197\131"] = "n", -- Ń
		["\197\132"] = "n", -- ń
		["\197\133"] = "n", -- Ņ
		["\197\134"] = "n", -- ņ
		["\197\135"] = "n", -- Ň
		["\197\136"] = "n", -- ň
		["\197\137"] = "n", -- ŉ
		["\197\138"] = "n", -- Ŋ
		["\197\139"] = "n", -- ŋ
		["\197\140"] = "o", -- Ō
		["\197\141"] = "o", -- ō
		["\197\142"] = "o", -- Ŏ
		["\197\143"] = "o", -- ŏ
		["\197\144"] = "o", -- Ő
		["\197\145"] = "o", -- ő
		["\197\146"] = "oe", -- Œ
		["\197\147"] = "oe", -- œ
		["\197\148"] = "r", -- Ŕ
		["\197\149"] = "r", -- ŕ
		["\197\150"] = "r", -- Ŗ
		["\197\151"] = "r", -- ŗ
		["\197\152"] = "r", -- Ř
		["\197\153"] = "r", -- ř
		["\197\154"] = "s", -- Ś
		["\197\155"] = "s", -- ś
		["\197\156"] = "s", -- Ŝ
		["\197\157"] = "s", -- ŝ
		["\197\158"] = "s", -- Ş
		["\197\159"] = "s", -- ş
		["\197\160"] = "s", -- Š
		["\197\161"] = "s", -- š
		["\197\162"] = "t", -- Ţ
		["\197\163"] = "t", -- ţ
		["\197\164"] = "t", -- Ť
		["\197\165"] = "t", -- ť
		["\197\166"] = "t", -- Ŧ
		["\197\167"] = "t", -- ŧ
		["\197\168"] = "u", -- Ũ
		["\197\169"] = "u", -- ũ
		["\197\170"] = "u", -- Ū
		["\197\171"] = "u", -- ū
		["\197\172"] = "u", -- Ŭ
		["\197\173"] = "u", -- ŭ
		["\197\174"] = "u", -- Ů
		["\197\175"] = "u", -- ů
		["\197\176"] = "u", -- Ű
		["\197\177"] = "u", -- ű
		["\197\178"] = "u", -- Ų
		["\197\179"] = "u", -- ų
		["\197\180"] = "w", -- Ŵ
		["\197\181"] = "w", -- ŵ
		["\197\182"] = "y", -- Ŷ
		["\197\183"] = "y", -- ŷ
		["\197\184"] = "y", -- Ÿ
		["\197\185"] = "z", -- Ź
		["\197\186"] = "z", -- ź
		["\197\187"] = "z", -- Ż
		["\197\188"] = "z", -- ż
		["\197\189"] = "z", -- Ž
		["\197\190"] = "z", -- ž
	}

	-- Build a gsub pattern that matches any 2-byte UTF-8 sequence in our map
	-- UTF-8 2-byte: first byte 0xC0-0xDF (\195-\197 for our range), second byte 0x80-0xBF
	local UTF8_ACCENT_PATTERN = "[\195-\197][\128-\191]"

	--- Strip accents/diacritics from a string, returning a plain ASCII-lowercase version.
	-- Both the search term and the target text should be normalized before comparison.
	-- @param text string The input text (may contain accented characters)
	-- @return string The normalized lowercase string with accents replaced by base characters
	function BFL:StripAccents(text)
		if not text or text == "" then
			return text
		end
		-- Replace accented characters with their base form, then lowercase
		local result = text:gsub(UTF8_ACCENT_PATTERN, function(char)
			return ACCENT_MAP[char] or char
		end)
		return result:lower()
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
		RaidFrame:UpdateGroupLayout()
	end

	-- Refresh QuickFilter Dropdown (if it exists)
	-- This ensures the dropdown icon updates when filter changes externally (e.g. via Broker)
	local QuickFilters = self:GetModule("QuickFilters")
	if
		QuickFilters
		and BetterFriendsFrame
		and BetterFriendsFrame.FriendsTabHeader
		and BetterFriendsFrame.FriendsTabHeader.QuickFilterDropdown
	then
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
			local DB = BFL:GetModule("DB")
			if DB then
				DB:Initialize()
			end

			-- Load debug flag from DB
			if BetterFriendlistDB then
				BFL.debugPrintEnabled = BetterFriendlistDB.debugPrintEnabled or false
			end

			-- Restore real data if preview mode was active during /reload
			local PreviewMode = BFL:GetModule("PreviewMode")
			if PreviewMode and PreviewMode.RestorePersistedState then
				PreviewMode:RestorePersistedState()
			end

			-- Detect optional features (version-specific APIs)
			DetectOptionalFeatures()

			-- Initialize all modules
			for name, module in pairs(BFL.Modules) do
				if name ~= "DB" and module.Initialize then
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

			-- Version-aware success message
			local versionSuffix = BFL.IsMidnight and " (Midnight)"
				or (BFL.IsClassicEra and " (Classic Era)")
				or (BFL.IsMoPClassic and " (MoP Classic)")
				or (BFL.IsCataClassic and " (Cata Classic)")
				or (BFL.IsWrathClassic and " (Wrath Classic)")
				or (BFL.IsTBCClassic and " (TBC Classic)")
				or " (TWW)"

			-- Check if welcome message is enabled (default: true)
			local showWelcome = true
			if BetterFriendlistDB and BetterFriendlistDB.showWelcomeMessage ~= nil then
				showWelcome = BetterFriendlistDB.showWelcomeMessage
			end

			if showWelcome then
				print(string.format(BFL.L.CORE_LOADED, BFL.VERSION, versionSuffix))
			end

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
-- Shared Helper: GetDragGhost
--------------------------------------------------------------------------
-- Reusable ghost frame for drag operations (friend list, raid frame, settings)
local DragGhost = nil
function BFL:GetDragGhost()
	if not DragGhost then
		DragGhost = CreateFrame("Frame", nil, UIParent)
		DragGhost:SetFrameStrata("TOOLTIP")
		DragGhost:EnableMouse(false) -- Ensure ghost doesn't block mouse events
		DragGhost.bg = DragGhost:CreateTexture(nil, "BACKGROUND")
		DragGhost.bg:SetAllPoints()
		DragGhost.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)

		-- Color Strip
		DragGhost.stripe = DragGhost:CreateTexture(nil, "ARTWORK")
		DragGhost.stripe:SetPoint("TOPLEFT")
		DragGhost.stripe:SetPoint("BOTTOMLEFT")
		DragGhost.stripe:SetWidth(6)

		DragGhost.text = DragGhost:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
		DragGhost.text:SetPoint("CENTER", 3, 0) -- Slight offset for stripe
	end
	return DragGhost
end

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

	-- Discord Popup
	elseif msg == "discord" then
		local Changelog = BFL:GetModule("Changelog")
		if Changelog then
			Changelog:ShowDiscordPopup()
		else
			print(
				"|cffff0000BetterFriendlist:|r " .. (BFL.L.CORE_CHANGELOG_NOT_LOADED or "Changelog module not loaded")
			)
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
	-- Test Suite Commands (for QA/Development)
	-- ==========================================
	elseif msg:match("^test") then
		local TestSuite = BFL:GetModule("TestSuite")
		if TestSuite then
			local fullArgs = msg:match("^test%s*(.*)") or ""
			TestSuite:HandleCommand(fullArgs)
		else
			print("|cffff0000BetterFriendlist:|r TestSuite module not loaded")
		end

	-- Switch Locale (Debug)
	elseif msg:match("^locale%s+") then
		local newLocale = msg:match("^locale%s+(%S+)")
		if newLocale then
			if BFL.SetLocale then
				BFL:SetLocale(newLocale)
			else
				print("|cffff0000BFL:|r SetLocale function not found!")
			end
		end

	-- Test Translations (Encoding Check)
	elseif msg == "testlocales" or msg == "testencoding" or msg == "testenc" then
		-- BFL:DebugPrint(
		--     "|cff00ff00BetterFriendlist:|r " .. (BFL.L.CORE_HELP_TEST_LOCALES or "Testing Localization Encoding...")
		-- )
		-- BFL:DebugPrint("Locale: " .. GetLocale())
		-- List of strings with special characters to test
		local testKeys = {
			"DIALOG_DELETE_GROUP_TEXT", -- é, ê, û
			"CORE_STATISTICS_HEADER", -- é
			"SETTINGS_BETA_FEATURES_ENABLED", -- é, È
			"DIALOG_MIGRATE_TEXT", -- é, è
			"FILTER_SEARCH_ONLINE", -- varies by locale
			"STATUS_AFK", -- varies
		}

		for _, key in ipairs(testKeys) do
			if BFL.L[key] then
				-- BFL:DebugPrint(string.format("|cffffcc00%s:|r %s", key, BFL.L[key]))
			else
				-- BFL:DebugPrint(string.format("|cffff0000Missing:|r %s", key))
			end
		end
		-- BFL:DebugPrint("|cff00ff00End of Test|r")

		-- Reset Frame Position
	elseif msg == "reset" then
		local FrameSettings = BFL:GetModule("FrameSettings")
		if FrameSettings then
			FrameSettings:ResetDefaults()
		else
			print("|cffff0000BetterFriendlist:|r FrameSettings module not loaded.")
		end

	-- Reset Changelog Version
	elseif msg == "reset_changelog" then
		local DB = BFL:GetModule("DB")
		if DB then
			DB:Set("lastChangelogVersion", "0.0.0")
			print(
				"|cff00ff00BetterFriendlist:|r "
					.. (BFL.L.CHANGELOG_RESET_SUCCESS or "Changelog version reset successfully.")
			)

			-- Update indicator immediately if module is loaded
			local Changelog = BFL:GetModule("Changelog")
			if Changelog then
				Changelog:CheckVersion()
			end
		end

	-- Help (or any other unrecognized command)
	elseif msg == "changelog" or msg == "changes" then
		local Changelog = BFL:GetModule("Changelog")
		if Changelog then
			Changelog:Show()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_CHANGELOG_NOT_LOADED)
		end

	-- ==========================================
	-- Debug Trace Command: /bfl trace <name>
	-- Traces a friend through the entire data pipeline to find where they get lost
	-- ==========================================
	elseif msg:match("^trace%s+") then
		local searchName = msg:match("^trace%s+(.+)")
		if not searchName or searchName == "" then
			print("|cffff0000BFL Trace:|r Usage: /bfl trace <name or battletag>")
			return
		end

		searchName = searchName:lower()
		local P = function(text)
			print("|cff00ccff[BFL Trace]|r " .. text)
		end

		P("=== TRACING: '" .. searchName .. "' ===")

		-- STEP 1: Check WoW API directly
		P("")
		P("|cffffcc00STEP 1: WoW API Data|r")
		local foundInAPI = false
		local matchedFriend = nil
		local matchedUID = nil

		-- Check BNet friends
		if BNGetNumFriends then
			local numBNet = BNGetNumFriends()
			P("  BNet friends total: " .. tostring(numBNet))
			for i = 1, numBNet do
				local info = C_BattleNet.GetFriendAccountInfo(i)
				if info then
					local nameMatch = (info.accountName and info.accountName:lower():find(searchName, 1, true))
						or (info.battleTag and info.battleTag:lower():find(searchName, 1, true))
						or (
							info.gameAccountInfo
							and info.gameAccountInfo.characterName
							and info.gameAccountInfo.characterName:lower():find(searchName, 1, true)
						)
					if nameMatch then
						foundInAPI = true
						local uid = info.battleTag and ("bnet_" .. info.battleTag)
							or ("bnet_" .. tostring(info.bnetAccountID))
						matchedUID = uid
						P(
							"  |cff00ff00FOUND|r BNet["
								.. i
								.. "]: "
								.. tostring(info.accountName)
								.. " | Tag: "
								.. tostring(info.battleTag)
								.. " | Online: "
								.. tostring(info.gameAccountInfo and info.gameAccountInfo.isOnline)
								.. " | Fav: "
								.. tostring(info.isFavorite)
						)
						P("    UID: " .. uid)
						P("    bnetAccountID: " .. tostring(info.bnetAccountID) .. " (session-only!)")
						if info.gameAccountInfo then
							P(
								"    Game: "
									.. tostring(info.gameAccountInfo.clientProgram)
									.. " | Char: "
									.. tostring(info.gameAccountInfo.characterName)
									.. " | Realm: "
									.. tostring(info.gameAccountInfo.realmName)
							)
						end
					end
				end
			end
		end

		-- Check WoW friends
		local numWoW = C_FriendList.GetNumFriends() or 0
		P("  WoW friends total: " .. tostring(numWoW))
		for i = 1, numWoW do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if info and info.name and info.name:lower():find(searchName, 1, true) then
				foundInAPI = true
				local normalized = BFL:NormalizeWoWFriendName(info.name)
				local uid = normalized and ("wow_" .. normalized) or nil
				matchedUID = uid
				P(
					"  |cff00ff00FOUND|r WoW["
						.. i
						.. "]: "
						.. tostring(info.name)
						.. " | Online: "
						.. tostring(info.connected)
						.. " | UID: "
						.. tostring(uid)
				)
			end
		end

		if not foundInAPI then
			P("  |cffff0000NOT FOUND in WoW API!|r This friend may not exist or the name doesn't match.")
		end

		-- STEP 2: Check FriendsList module data
		P("")
		P("|cffffcc00STEP 2: FriendsList Module (self.friendsList)|r")
		local FriendsList = BFL:GetModule("FriendsList")
		local foundInModule = false
		if FriendsList and FriendsList.friendsList then
			P("  friendsList count: " .. #FriendsList.friendsList)
			for idx, friend in ipairs(FriendsList.friendsList) do
				local nameMatch = false
				if friend.type == "bnet" then
					nameMatch = (friend.accountName and friend.accountName:lower():find(searchName, 1, true))
						or (friend.battleTag and friend.battleTag:lower():find(searchName, 1, true))
						or (friend.characterName and friend.characterName:lower():find(searchName, 1, true))
				else
					nameMatch = (friend.name and friend.name:lower():find(searchName, 1, true))
				end
				if nameMatch then
					foundInModule = true
					matchedUID = friend.uid
					P(
						"  |cff00ff00FOUND|r ["
							.. idx
							.. "] type="
							.. tostring(friend.type)
							.. " | uid="
							.. tostring(friend.uid)
							.. " | connected="
							.. tostring(friend.connected)
							.. " | displayName="
							.. tostring(friend.displayName)
					)
				end
			end
			if not foundInModule then
				P("  |cffff0000NOT FOUND in friendsList!|r Friend exists in API but not in module data.")
			end
		else
			P("  |cffff0000FriendsList module not loaded or friendsList is nil!|r")
		end

		-- STEP 3: Check Database group membership
		P("")
		P("|cffffcc00STEP 3: Database (BetterFriendlistDB.friendGroups)|r")
		if matchedUID then
			if BetterFriendlistDB and BetterFriendlistDB.friendGroups then
				local entry = BetterFriendlistDB.friendGroups[matchedUID]
				if entry then
					P("  |cffff8800friendGroups[" .. matchedUID .. "] = {" .. table.concat(entry, ", ") .. "}|r")
					-- Check if these groups actually exist
					local Groups = BFL:GetModule("Groups")
					if Groups then
						local allGroups = Groups:GetAll()
						for _, gid in ipairs(entry) do
							local exists = allGroups[gid] ~= nil
							if exists then
								P(
									"    Group '"
										.. gid
										.. "': |cff00ff00EXISTS|r ("
										.. tostring(allGroups[gid].name)
										.. ")"
								)
							else
								P("    Group '" .. gid .. "': |cffff0000GHOST GROUP - DOES NOT EXIST!|r")
								P("    |cffff0000^^^ THIS IS THE BUG! Friend is assigned to a deleted group!|r")
							end
						end
					end
				else
					P("  |cff00ff00friendGroups[" .. matchedUID .. "] = nil|r (correctly in 'No Group')")
				end
			else
				P("  |cffff0000BetterFriendlistDB.friendGroups is nil!|r")
			end
		else
			P("  Cannot check - no UID resolved.")
			-- Dump ALL friendGroups entries that contain the search name
			if BetterFriendlistDB and BetterFriendlistDB.friendGroups then
				P("  Searching all friendGroups keys for partial match...")
				for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
					if uid:lower():find(searchName, 1, true) then
						P("  |cffff8800FOUND KEY: " .. uid .. " = {" .. table.concat(groups, ", ") .. "}|r")
					end
				end
			end
		end

		-- STEP 4: Check filter state
		P("")
		P("|cffffcc00STEP 4: Current Filter State|r")
		if FriendsList then
			P("  filterMode: " .. tostring(FriendsList.filterMode))
			P("  searchText: '" .. tostring(FriendsList.searchText) .. "'")
			P("  quickFilter (DB): " .. tostring(BetterFriendlistDB and BetterFriendlistDB.quickFilter))

			-- Test PassesFilters on the matched friend
			if foundInModule then
				for _, friend in ipairs(FriendsList.friendsList) do
					local nameMatch = false
					if friend.type == "bnet" then
						nameMatch = (friend.accountName and friend.accountName:lower():find(searchName, 1, true))
							or (friend.battleTag and friend.battleTag:lower():find(searchName, 1, true))
					else
						nameMatch = (friend.name and friend.name:lower():find(searchName, 1, true))
					end
					if nameMatch then
						local passes = FriendsList:PassesFilters(friend)
						P("  PassesFilters: " .. tostring(passes))
						if not passes then
							P("  |cffff0000^^^ FILTERED OUT! This is why the friend is hidden!|r")
							if FriendsList.filterMode == "online" and not friend.connected then
								P("  |cffff8800Reason: Filter is 'online' but friend is OFFLINE|r")
							end
						end
						break
					end
				end
			end
		end

		-- STEP 5: Check BuildDisplayList output
		P("")
		P("|cffffcc00STEP 5: Display List (BuildDisplayList)|r")
		if FriendsList and FriendsList.cachedDisplayList then
			local foundInDisplay = false
			local totalFriendEntries = 0
			for _, entry in ipairs(FriendsList.cachedDisplayList) do
				if entry.buttonType == 1 then -- BUTTON_TYPE_FRIEND
					totalFriendEntries = totalFriendEntries + 1
					if entry.friend and entry.friend.uid == matchedUID then
						foundInDisplay = true
						P("  |cff00ff00FOUND in display list!|r Group: " .. tostring(entry.groupId))
					end
				end
			end
			P("  Total friend entries in display list: " .. totalFriendEntries)
			if not foundInDisplay then
				P("  |cffff0000NOT in display list!|r")
			end
		else
			P("  |cffff8800No cached display list available.|r")
		end

		-- STEP 6: Check ScrollBox DataProvider
		P("")
		P("|cffffcc00STEP 6: ScrollBox DataProvider|r")
		if FriendsList and FriendsList.scrollBox then
			local provider = FriendsList.scrollBox:GetDataProvider()
			if provider then
				local foundInProvider = false
				local providerCount = 0
				for _, data in provider:Enumerate() do
					if data.buttonType == 1 and data.friend then
						providerCount = providerCount + 1
						if data.friend.uid == matchedUID then
							foundInProvider = true
							P("  |cff00ff00FOUND in DataProvider!|r Group: " .. tostring(data.groupId))
						end
					end
				end
				P("  Total friend entries in DataProvider: " .. providerCount)
				if not foundInProvider then
					P("  |cffff0000NOT in DataProvider!|r")
				end
			else
				P("  |cffff8800No DataProvider set!|r")
			end
		else
			P("  |cffff8800ScrollBox not available.|r")
		end

		-- STEP 7: Check for ghost groups in entire DB
		P("")
		P("|cffffcc00STEP 7: Ghost Group Scan (all friends)|r")
		if BetterFriendlistDB and BetterFriendlistDB.friendGroups then
			local Groups = BFL:GetModule("Groups")
			-- Use Groups.groups (ALL groups including hidden builtins) not GetAll() (which filters)
			local allGroups = Groups and Groups.groups or {}
			local ghostCount = 0
			for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
				if type(groups) == "table" then
					for _, gid in ipairs(groups) do
						if not allGroups[gid] then
							ghostCount = ghostCount + 1
							P(
								"  |cffff0000GHOST:|r "
									.. uid
									.. " → group '"
									.. tostring(gid)
									.. "' (does not exist!)"
							)
						end
					end
				end
			end
			if ghostCount == 0 then
				P("  |cff00ff00No ghost groups found.|r")
			else
				P("  |cffff0000Total ghost entries: " .. ghostCount .. "|r")
				P("  |cffff8800Run /bfl fixghosts to clean up ghost group entries.|r")
			end
		end

		P("")
		P("=== TRACE COMPLETE ===")

	-- ==========================================
	-- Fix Ghost Groups Command: /bfl fixghosts
	-- Removes friendGroups entries pointing to non-existent groups
	-- ==========================================
	elseif msg == "fixghosts" then
		local P = function(text)
			print("|cff00ccff[BFL Fix]|r " .. text)
		end
		local Groups = BFL:GetModule("Groups")
		-- Use Groups.groups (ALL groups including hidden builtins) not GetAll() (which filters)
		local allGroups = Groups and Groups.groups or {}

		if not BetterFriendlistDB or not BetterFriendlistDB.friendGroups then
			P("|cffff0000No friendGroups data found.|r")
			return
		end

		local fixedCount = 0
		local removedFriends = 0

		for uid, groups in pairs(BetterFriendlistDB.friendGroups) do
			if type(groups) == "table" then
				for i = #groups, 1, -1 do
					if not allGroups[groups[i]] then
						P("Removed ghost group '" .. tostring(groups[i]) .. "' from " .. uid)
						table.remove(groups, i)
						fixedCount = fixedCount + 1
					end
				end
				-- Clean up empty entries
				if #groups == 0 then
					BetterFriendlistDB.friendGroups[uid] = nil
					removedFriends = removedFriends + 1
				end
			end
		end

		if fixedCount > 0 then
			P(
				"|cff00ff00Fixed "
					.. fixedCount
					.. " ghost entries, cleaned "
					.. removedFriends
					.. " empty friend entries.|r"
			)
			P("Refreshing friends list...")
			BFL:ForceRefreshFriendsList()
		else
			P("|cff00ff00No ghost groups found. Database is clean.|r")
		end
	else
		print(string.format(BFL.L.CORE_HELP_TITLE, BFL.VERSION))
		print("")
		print(BFL.L.CORE_HELP_MAIN_COMMANDS)
		print(BFL.L.CORE_HELP_CMD_TOGGLE)
		print(BFL.L.CORE_HELP_CMD_SETTINGS)
		print(BFL.L.CORE_HELP_CMD_HELP)
		print(BFL.L.CORE_HELP_CMD_CHANGELOG)
		print(BFL.L.CORE_HELP_CMD_RESET)
		print("")
		print(BFL.L.CORE_HELP_LINK)
	end
end
