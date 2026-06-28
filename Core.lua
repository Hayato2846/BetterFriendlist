-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 2.6.4 - June 2026
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

local function HasGlobalFunction(name)
	return type(_G[name]) == "function"
end

local function HasNamespaceFunction(namespaceName, functionName)
	local namespace = _G[namespaceName]
	return type(namespace) == "table" and type(namespace[functionName]) == "function"
end

local function DetectUICapabilities()
	return {
		ModernScrollBox = HasGlobalFunction("CreateScrollBoxListLinearView")
			and HasGlobalFunction("CreateDataProvider")
			and HasNamespaceFunction("ScrollUtil", "InitScrollBoxListWithScrollBar"),
		ModernMenu = HasNamespaceFunction("MenuUtil", "CreateContextMenu")
			or HasNamespaceFunction("Menu", "ModifyMenu"),
		RecentAllies = HasNamespaceFunction("C_RecentAllies", "IsSystemEnabled"),
		EditMode = BFL.IsRetail
			and (HasNamespaceFunction("C_EditMode", "GetLayouts") or type(EditModeManagerFrame) == "table"),
		ModernDropdown = type(DropdownButtonMixin) == "table"
			and type(DropdownButtonMixin.SetupMenu) == "function",
		ModernColorPicker = type(ColorPickerFrame) == "table"
			and type(ColorPickerFrame.SetupColorPickerAndShow) == "function",
	}
end

BFL.Capabilities = DetectUICapabilities()

-- Public feature flags prefer real client capabilities where the API is self-contained.
-- ScrollBox remains a validated-default flag because some BFL frames still need
-- frame-level parent/anchor checks before Classic can safely use the modern path.
BFL.HasModernScrollBox = BFL.IsRetail and BFL.Capabilities.ModernScrollBox -- ScrollBox API (Retail 10.0+)
BFL.HasModernMenu = BFL.Capabilities.ModernMenu -- MenuUtil, Menu.ModifyMenu
BFL.HasRecentAllies = (BFL.IsTWW or BFL.IsMidnight) and BFL.HasModernScrollBox and BFL.Capabilities.RecentAllies -- C_RecentAllies (TWW 11.0.7+)
BFL.HasEditMode = BFL.IsRetail and BFL.Capabilities.EditMode -- Edit Mode API (Retail 10.0+)
BFL.HasModernDropdown = BFL.Capabilities.ModernDropdown -- WowStyle1DropdownTemplate
BFL.HasModernColorPicker = true -- ColorPickerFrame:SetupColorPickerAndShow on supported Retail and Classic clients

BFL.CanUseModernScrollBox = BFL.Capabilities.ModernScrollBox
BFL.CanUseModernMenu = BFL.Capabilities.ModernMenu
BFL.CanUseModernDropdown = BFL.Capabilities.ModernDropdown

local CORE_ATLAS_AVAILABILITY = {}

local function CoreHasAtlas(atlasName)
	if not atlasName or not (C_Texture and type(C_Texture.GetAtlasInfo) == "function") then
		return false
	end
	if CORE_ATLAS_AVAILABILITY[atlasName] ~= nil then
		return CORE_ATLAS_AVAILABILITY[atlasName]
	end
	local ok, info = pcall(C_Texture.GetAtlasInfo, atlasName)
	local available = ok and info ~= nil
	CORE_ATLAS_AVAILABILITY[atlasName] = available
	return available
end

local function CoreTrySetAtlas(texture, atlasName, useAtlasSize)
	if not (texture and texture.SetAtlas and CoreHasAtlas(atlasName)) then
		return false
	end
	local ok = pcall(texture.SetAtlas, texture, atlasName, useAtlasSize)
	return ok == true
end

local function CoreSetClassicTopLeftCornerTexture(texture)
	if not texture then
		return
	end

	if texture.SetTexture then
		texture:SetTexture("Interface\\FrameGeneral\\UI-Frame")
	end
	if texture.SetTexCoord then
		texture:SetTexCoord(0.63281250, 0.88281250, 0.28125000, 0.53125000)
	end
	if texture.SetSize then
		texture:SetSize(33, 33)
	end
end

local function CoreSetPoint(frame, ...)
	if frame and frame.SetPoint then
		frame:SetPoint(...)
	end
end

local function CoreClearPoints(frame)
	if frame and frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
end

local function CoreSetShown(frame, shown)
	if frame and frame.SetShown then
		frame:SetShown(shown)
	elseif frame then
		if shown and frame.Show then
			frame:Show()
		elseif not shown and frame.Hide then
			frame:Hide()
		end
	end
end

local function CoreUpdateClassicSimpleTopLeftPatch(frame, shown)
	if not (frame and frame.CreateTexture) then
		return
	end

	if not frame.BFL_SimpleModeTopLeftCorner then
		frame.BFL_SimpleModeTopLeftCorner = frame:CreateTexture(nil, "OVERLAY", nil, 2)
	end

	local patch = frame.BFL_SimpleModeTopLeftCorner
	CoreSetClassicTopLeftCornerTexture(patch)
	CoreClearPoints(patch)
	CoreSetPoint(patch, "TOPLEFT", frame, "TOPLEFT", -6, 1)
	if patch.SetAlpha then
		patch:SetAlpha(1)
	end
	if patch.SetVertexColor then
		patch:SetVertexColor(1, 1, 1, 1)
	end
	CoreSetShown(patch, shown)
end

local function CoreApplyClassicButtonFramePortraitLayout(frame, shouldShowPortrait)
	if not (BFL.IsClassic and frame) then
		return false
	end

	local hasButtonFramePieces = frame.TopLeftCorner and frame.TopBorder and frame.LeftBorder and frame.TopRightCorner
	if not hasButtonFramePieces then
		return false
	end

	local templateFunc = shouldShowPortrait and ButtonFrameTemplate_ShowPortrait or ButtonFrameTemplate_HidePortrait
	if type(templateFunc) == "function" and frame.portrait and frame.PortraitFrame then
		pcall(templateFunc, frame)
	end

	if shouldShowPortrait and frame.PortraitFrame then
		CoreSetShown(frame.PortraitFrame, true)
		CoreSetShown(frame.TopLeftCorner, false)
		CoreUpdateClassicSimpleTopLeftPatch(frame, false)

		CoreClearPoints(frame.TopBorder)
		CoreSetPoint(frame.TopBorder, "TOPLEFT", frame.PortraitFrame, "TOPRIGHT", 0, -10)
		CoreSetPoint(frame.TopBorder, "TOPRIGHT", frame.TopRightCorner, "TOPLEFT", 0, 0)

		CoreClearPoints(frame.LeftBorder)
		CoreSetPoint(frame.LeftBorder, "TOPLEFT", frame.PortraitFrame, "BOTTOMLEFT", 8, 0)
		if frame.BotLeftCorner then
			CoreSetPoint(frame.LeftBorder, "BOTTOMLEFT", frame.BotLeftCorner, "TOPLEFT", 0, 0)
		end
	else
		CoreSetShown(frame.PortraitFrame, false)
		CoreSetShown(frame.TopLeftCorner, true)

		CoreClearPoints(frame.TopLeftCorner)
		CoreSetClassicTopLeftCornerTexture(frame.TopLeftCorner)
		CoreSetPoint(frame.TopLeftCorner, "TOPLEFT", frame, "TOPLEFT", -6, 1)
		if frame.TopLeftCorner.SetAlpha then
			frame.TopLeftCorner:SetAlpha(1)
		end
		if frame.TopLeftCorner.SetVertexColor then
			frame.TopLeftCorner:SetVertexColor(1, 1, 1, 1)
		end
		CoreUpdateClassicSimpleTopLeftPatch(frame, true)

		CoreClearPoints(frame.TopBorder)
		CoreSetPoint(frame.TopBorder, "TOPLEFT", frame.TopLeftCorner, "TOPRIGHT", 0, 0)
		CoreSetPoint(frame.TopBorder, "TOPRIGHT", frame.TopRightCorner, "TOPLEFT", 0, 0)

		CoreClearPoints(frame.LeftBorder)
		CoreSetPoint(frame.LeftBorder, "TOPLEFT", frame.TopLeftCorner, "BOTTOMLEFT", 0, 0)
		if frame.BotLeftCorner then
			CoreSetPoint(frame.LeftBorder, "BOTTOMLEFT", frame.BotLeftCorner, "TOPLEFT", 0, 0)
		end
	end

	if frame.portrait and frame.PortraitButton then
		frame.portrait:SetShown(false)
	end

	return true
end

-- Feature Detection (detect available APIs for optional features)
BFL.UseClassID = false -- 11.2.7+ classID optimization
BFL.HasSecretValues = issecretvalue ~= nil -- 12.0.0+ Secret Values API
BFL.UseNativeCallbacks = false -- 12.0.0+ Frame:RegisterEventCallback

local SOCIAL_BINDING = "TOGGLESOCIAL"
local BFL_SOCIAL_BINDING = "BETTERFRIENDLIST_TOGGLE"
local SOCIAL_BINDING_MIGRATION_VERSION = "2.5.6-social-keybind-v1"
local CLASSIC_GUILD_UI_CVAR = "useClassicGuildUI"

_G.BINDING_NAME_BETTERFRIENDLIST_TOGGLE = "Toggle BetterFriendlist"

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

local function ShouldForceSeparateClassicGuildWindow()
	return BFL.IsClassicEra or BFL.IsTBCClassic or BFL.IsWrathClassic or BFL.IsCataClassic
end

local function EnsureSeparateClassicGuildWindow()
	if not ShouldForceSeparateClassicGuildWindow() then
		return
	end

	local getCVarBool = (C_CVar and C_CVar.GetCVarBool) or GetCVarBool
	local setCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
	if not (getCVarBool and setCVar) then
		return
	end

	local ok, useClassicGuildUI = pcall(getCVarBool, CLASSIC_GUILD_UI_CVAR)
	if not ok or useClassicGuildUI ~= true then
		return
	end

	local setOk = pcall(setCVar, CLASSIC_GUILD_UI_CVAR, "0")
	if not setOk then
		return
	end

	if FriendsFrame_UpdateGuildTabVisibility then
		pcall(FriendsFrame_UpdateGuildTabVisibility)
	end
	if UpdateMicroButtons then
		pcall(UpdateMicroButtons)
	end
end

-- Module registry
BFL.Modules = {}

-- Event callback registry
BFL.EventCallbacks = {}

--------------------------------------------------------------------------
-- Debug Print System
--------------------------------------------------------------------------
-- All debug prints are gated behind /bfl debug
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

local function ClampColorComponent(value, fallback)
	value = tonumber(value)
	if value == nil then
		return fallback
	end
	if value < 0 then
		return 0
	end
	if value > 1 then
		return 1
	end
	return value
end

local function ColorComponentToHex(value)
	value = ClampColorComponent(value, 1)
	return math.floor((value * 255) + 0.5)
end

function BFL:GetThemeAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	fallbackR = fallbackR ~= nil and fallbackR or 1
	fallbackG = fallbackG ~= nil and fallbackG or 0.82
	fallbackB = fallbackB ~= nil and fallbackB or 0
	fallbackA = fallbackA ~= nil and fallbackA or 1

	if self.UsesDarkSkinTheme and self:UsesDarkSkinTheme() then
		local SkinEngine = self.GetModule and self:GetModule("SkinEngine")
		local color = SkinEngine and SkinEngine.colors and (SkinEngine.colors.gold or SkinEngine.colors.accent)
		if color then
			return ClampColorComponent(color[1], fallbackR),
				ClampColorComponent(color[2], fallbackG),
				ClampColorComponent(color[3], fallbackB),
				ClampColorComponent(fallbackA, color[4] or 1)
		end
	end

	return fallbackR, fallbackG, fallbackB, fallbackA
end

function BFL:GetThemeAccentHex(fallbackHex)
	local theme = self.GetEffectiveTheme and self:GetEffectiveTheme() or "blizzard"
	if theme == "dark" or theme == "custom" then
		local r, g, b = self:GetThemeAccentColor()
		return string.format("%02x%02x%02x", ColorComponentToHex(r), ColorComponentToHex(g), ColorComponentToHex(b))
	end

	return fallbackHex or "ffcc00"
end

function BFL:GetThemeAccentColorCode(fallbackHex)
	return "|cff" .. self:GetThemeAccentHex(fallbackHex)
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

function BFL:HasGuildRosterBaseAPI()
	return IsInGuild ~= nil
		and GetNumGuildMembers ~= nil
		and self.GuildRoster ~= nil
		and self.GetGuildRosterInfo ~= nil
end

function BFL:GetGuildTabCapability()
	local clientSupported = self.IsRetail == true
	local hasBaseRosterAPI = false
	if clientSupported then
		local provider = self.GetModule and self:GetModule("GuildRosterData")
		if provider and provider.HasBaseRosterAPI then
			hasBaseRosterAPI = provider:HasBaseRosterAPI() == true
		else
			hasBaseRosterAPI = self:HasGuildRosterBaseAPI()
		end
	end

	local betaEnabled = BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
	local settingEnabled = BetterFriendlistDB and BetterFriendlistDB.enableGuildTab == true

	return {
		betaEnabled = betaEnabled,
		settingEnabled = settingEnabled,
		clientSupported = clientSupported,
		hasBaseRosterAPI = hasBaseRosterAPI,
		canShowSetting = clientSupported and hasBaseRosterAPI,
		canShowRoster = clientSupported and betaEnabled and settingEnabled and hasBaseRosterAPI,
	}
end

function BFL:IsGuildTabEnabled()
	local capability = self:GetGuildTabCapability()
	return capability and capability.canShowRoster == true
end

function BFL:UpdateBindingGlobals()
	local L = self.L or _G.BFL_L
	_G.BINDING_NAME_BETTERFRIENDLIST_TOGGLE = (L and L.KEYBIND_TOGGLE_BETTERFRIENDLIST) or "Toggle BetterFriendlist"
end

local function CollectBindingKeys(action)
	if not GetBindingKey then
		return {}
	end

	local keys = { GetBindingKey(action) }
	local result = {}
	for _, key in ipairs(keys) do
		if key and key ~= "" then
			result[#result + 1] = key
		end
	end
	return result
end

local function ContainsKey(keys, targetKey)
	for _, key in ipairs(keys) do
		if key == targetKey then
			return true
		end
	end
	return false
end

local function IsBindingKeyAssignedToAction(key, action)
	if not key then
		return false
	end
	return ContainsKey(CollectBindingKeys(action), key)
end

local function AddUniqueBindingKey(keys, key)
	if key and key ~= "" and not ContainsKey(keys, key) then
		keys[#keys + 1] = key
	end
end

local function IsBetterFriendlistEnabledForCurrentCharacter()
	if not (C_AddOns and C_AddOns.GetAddOnEnableState and Enum and Enum.AddOnEnableState) then
		return true
	end

	local character = UnitGUID and UnitGUID("player") or nil
	local ok, state
	if character then
		ok, state = pcall(C_AddOns.GetAddOnEnableState, ADDON_NAME, character)
	else
		ok, state = pcall(C_AddOns.GetAddOnEnableState, ADDON_NAME)
	end
	if not ok then
		return true
	end
	if type(state) ~= "number" then
		return true
	end

	return state > Enum.AddOnEnableState.None
end

function BFL:RestoreMigratedSocialKeybindsForAddonDisable()
	if IsBetterFriendlistEnabledForCurrentCharacter() then
		return
	end
	if not BetterFriendlistDB then
		return
	end
	if not (GetBindingKey and SetBinding and SaveBindings and GetCurrentBindingSet) then
		return
	end

	local restoreKeys = {}
	local migratedKeys = BetterFriendlistDB.socialKeybindMigratedKeys
	if type(migratedKeys) == "table" then
		for _, key in ipairs(migratedKeys) do
			if IsBindingKeyAssignedToAction(key, BFL_SOCIAL_BINDING) then
				AddUniqueBindingKey(restoreKeys, key)
			end
		end
	end

	if #restoreKeys == 0 then
		for _, key in ipairs(CollectBindingKeys(BFL_SOCIAL_BINDING)) do
			AddUniqueBindingKey(restoreKeys, key)
		end
	end

	if #restoreKeys == 0 then
		BetterFriendlistDB.socialKeybindMigrated = false
		BetterFriendlistDB.socialKeybindMigrationVersion = nil
		BetterFriendlistDB.socialKeybindMigratedKeys = {}
		return
	end

	local restored = false
	local failedKeys = {}
	for _, key in ipairs(restoreKeys) do
		local ok, result = pcall(SetBinding, key, SOCIAL_BINDING)
		if ok and result then
			restored = true
		else
			failedKeys[#failedKeys + 1] = key
		end
	end

	if restored then
		local ok = pcall(SaveBindings, GetCurrentBindingSet())
		if not ok then
			return
		end
	end

	if #failedKeys > 0 then
		BetterFriendlistDB.socialKeybindMigratedKeys = failedKeys
		return
	end

	BetterFriendlistDB.socialKeybindMigrated = false
	BetterFriendlistDB.socialKeybindMigrationVersion = nil
	BetterFriendlistDB.socialKeybindMigratedKeys = {}
end

function BFL:MigrateSocialKeybindToNativeBinding()
	if not self.HasSecretValues then
		return
	end
	if not BetterFriendlistDB then
		return
	end
	if InCombatLockdown() then
		self.pendingSocialKeybindMigration = true
		return
	end
	if not (GetBindingKey and SetBinding and SaveBindings and GetCurrentBindingSet) then
		return
	end

	local socialKeys = CollectBindingKeys(SOCIAL_BINDING)
	local bflKeys = CollectBindingKeys(BFL_SOCIAL_BINDING)

	if BetterFriendlistDB.socialKeybindMigrationVersion == SOCIAL_BINDING_MIGRATION_VERSION then
		local migratedKeys = BetterFriendlistDB.socialKeybindMigratedKeys
		if type(migratedKeys) == "table" and #migratedKeys > 0 then
			return
		end
		if #socialKeys == 0 and #bflKeys > 0 then
			BetterFriendlistDB.socialKeybindMigrated = true
			BetterFriendlistDB.socialKeybindMigratedKeys = bflKeys
		end
		return
	end

	if #socialKeys == 0 then
		local migratedKeys = {}
		for _, key in ipairs(bflKeys) do
			AddUniqueBindingKey(migratedKeys, key)
		end
		BetterFriendlistDB.socialKeybindMigrated = true
		BetterFriendlistDB.socialKeybindMigrationVersion = SOCIAL_BINDING_MIGRATION_VERSION
		BetterFriendlistDB.socialKeybindMigratedKeys = migratedKeys
		return
	end

	local migratedKeys = {}
	for _, key in ipairs(socialKeys) do
		if not ContainsKey(bflKeys, key) and SetBinding(key, BFL_SOCIAL_BINDING) then
			AddUniqueBindingKey(migratedKeys, key)
			AddUniqueBindingKey(bflKeys, key)
		end
	end

	local remainingSocialKeys = CollectBindingKeys(SOCIAL_BINDING)
	if #remainingSocialKeys > 0 then
		return
	end

	if #migratedKeys > 0 then
		SaveBindings(GetCurrentBindingSet())
	end

	BetterFriendlistDB.socialKeybindMigrated = true
	BetterFriendlistDB.socialKeybindMigrationVersion = SOCIAL_BINDING_MIGRATION_VERSION
	BetterFriendlistDB.socialKeybindMigratedKeys = migratedKeys
end

-- Intercept Blizzard's Social keybind before ToggleFriendsFrame runs.
-- This keeps the default FriendsFrame from opening in the background while
-- preserving the user's actual keybinding configuration.
function BFL:InstallSocialKeybindOverride()
	if self.HasSecretValues then
		if self.socialKeybindOwner then
			ClearOverrideBindings(self.socialKeybindOwner)
		end
		self.pendingSocialKeybindOverride = nil
		return
	end
	if self.installingSocialKeybindOverride then
		return
	end
	if InCombatLockdown() then
		self.pendingSocialKeybindOverride = true
		return
	end

	self.installingSocialKeybindOverride = true

	if self.socialKeybindOwner then
		ClearOverrideBindings(self.socialKeybindOwner)
	else
		self.socialKeybindOwner = CreateFrame("Frame")
	end

	if not self.socialKeybindButton then
		self.socialKeybindButton = CreateFrame("Button", "BetterFriendlistSocialKeybindButton", UIParent)
		self.socialKeybindButton:SetSize(1, 1)
		self.socialKeybindButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
		self.socialKeybindButton:EnableMouse(false)
		self.socialKeybindButton:Show()
		self.socialKeybindButton:SetScript("OnClick", function()
			if _G.ToggleBetterFriendsFrame then
				_G.ToggleBetterFriendsFrame(1)
			end
		end)
	end

	local keys = CollectBindingKeys(SOCIAL_BINDING)
	for _, key in ipairs(keys) do
		SetOverrideBindingClick(self.socialKeybindOwner, true, key, "BetterFriendlistSocialKeybindButton")
	end

	self.pendingSocialKeybindOverride = nil
	self.installingSocialKeybindOverride = nil
end

local function RunNextFrame(callback)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, callback)
	else
		callback()
	end
end

function BFL:AddUniqueUISpecialFrame(frameName)
	if not (frameName and UISpecialFrames) then
		return
	end

	for _, value in ipairs(UISpecialFrames) do
		if value == frameName then
			return
		end
	end

	tinsert(UISpecialFrames, frameName)
end

function BFL:InstallBetterFriendsFrameEscapeHandler()
	if self.betterFriendsFrameEscapeHandlerInstalled or not BetterFriendsFrame then
		return
	end

	self.betterFriendsFrameEscapeHandlerInstalled = true
	self:AddUniqueUISpecialFrame("BetterFriendsFrame")
end

local function NormalizeFriendsFrameTab(tabIndex)
	local tab = tonumber(tabIndex) or 1

	if FRIEND_TAB_FRIENDS and tab == FRIEND_TAB_FRIENDS then
		return 1
	end
	if FRIEND_TAB_WHO and tab == FRIEND_TAB_WHO then
		return 2
	end
	if FRIEND_TAB_RAID and tab == FRIEND_TAB_RAID then
		return 3
	end
	if FRIEND_TAB_QUICK_JOIN and tab == FRIEND_TAB_QUICK_JOIN then
		return 4
	end

	if tab >= 1 and tab <= 4 then
		return tab
	end

	return 1
end

local function NormalizeFriendsSubPanel(panelIndex)
	local tab = tonumber(panelIndex)
	local blizzardHeader = _G.FriendsTabHeader

	if blizzardHeader then
		if blizzardHeader.friendsTabID and tab == blizzardHeader.friendsTabID then
			return 1
		end
		if blizzardHeader.recentAlliesTabID and tab == blizzardHeader.recentAlliesTabID then
			return 2
		end
		if blizzardHeader.recruitAFriendTabID and tab == blizzardHeader.recruitAFriendTabID then
			return 3
		end
	end

	if tab and tab >= 1 and tab <= 4 then
		return tab
	end

	return 1
end

local function StoreOriginalFriendsFrameFunction(name)
	local original = _G[name]
	if not original then
		return nil
	end

	local key = "Original" .. name
	if not BFL[key] then
		BFL[key] = original
	end

	return BFL[key]
end

function BFL:GetBetterFriendsFrameBottomTab()
	if BetterFriendsFrame and PanelTemplates_GetSelectedTab then
		return PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
	end

	return 1
end

function BFL:GetBetterFriendsFrameTopTab()
	if
		BetterFriendsFrame
		and BetterFriendsFrame.FriendsTabHeader
		and PanelTemplates_GetSelectedTab
	then
		return PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader) or 1
	end

	return 1
end

function BFL:IsBetterFriendsRedirectTargetShown(tabIndex, topTabIndex)
	if not (BetterFriendsFrame and BetterFriendsFrame:IsShown()) then
		return false
	end

	local currentTab = self:GetBetterFriendsFrameBottomTab()
	if currentTab ~= tabIndex then
		return false
	end

	if tabIndex == 1 and topTabIndex then
		return self:GetBetterFriendsFrameTopTab() == topTabIndex
	end

	return true
end

function BFL:HideBetterFriendsFrameForRedirect()
	if not BetterFriendsFrame then
		return
	end

	if BetterFriendsFrame.IgnoreListWindow then
		BetterFriendsFrame.IgnoreListWindow:Hide()
	end

	if _G.HideBetterFriendsFrame then
		_G.HideBetterFriendsFrame()
	else
		BetterFriendsFrame:Hide()
	end
end

function BFL:ApplyBetterFriendsFrameTarget(tabIndex, topTabIndex)
	if not BetterFriendsFrame then
		return
	end

	if BetterFriendsFrame.IgnoreListWindow then
		BetterFriendsFrame.IgnoreListWindow:Hide()
	end

	if _G.ShowBetterFriendsFrame then
		_G.ShowBetterFriendsFrame(tabIndex)
	else
		BetterFriendsFrame:Show()
	end

	if
		tabIndex == 1
		and topTabIndex
		and _G.BetterFriendsFrame_ShowTab
		and not self.IsClassic
	then
		_G.BetterFriendsFrame_ShowTab(topTabIndex)
	end
end

function BFL:ShowBetterFriendsFrameIgnoreList()
	if not BetterFriendsFrame then
		return
	end

	if _G.ShowBetterFriendsFrame then
		_G.ShowBetterFriendsFrame(1)
	else
		BetterFriendsFrame:Show()
	end

	if _G.BetterFriendsFrame_ShowIgnoreList then
		_G.BetterFriendsFrame_ShowIgnoreList()
	end
end

function BFL:HandleFriendsFrameRedirect(action, tabIndex, topTabIndex)
	if self.AllowBlizzardFriendsFrame then
		return false
	end

	if FriendsFrame and FriendsFrame:IsShown() then
		self:HideBlizzardFriendsFrameForRedirect()
	end

	if action == "ignore" then
		if
			BetterFriendsFrame
			and BetterFriendsFrame:IsShown()
			and BetterFriendsFrame.IgnoreListWindow
			and BetterFriendsFrame.IgnoreListWindow:IsShown()
		then
			self:HideBetterFriendsFrameForRedirect()
			return true
		end

		self:ShowBetterFriendsFrameIgnoreList()
		return true
	end

	if action == "toggle-any" and BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		self:HideBetterFriendsFrameForRedirect()
		return true
	end

	local targetTab = NormalizeFriendsFrameTab(tabIndex)
	local targetTopTab = topTabIndex and NormalizeFriendsSubPanel(topTabIndex) or nil

	if action == "toggle" and self:IsBetterFriendsRedirectTargetShown(targetTab, targetTopTab) then
		self:HideBetterFriendsFrameForRedirect()
		return true
	end

	self:ApplyBetterFriendsFrameTarget(targetTab, targetTopTab)
	return true
end

function BFL:HideBlizzardFriendsFrameForRedirect()
	if not FriendsFrame then
		return true
	end

	if not FriendsFrame:IsShown() then
		FriendsFrame:SetAlpha(1)
		self.pendingBlizzardFriendsFrameHide = nil
		return true
	end

	FriendsFrame:SetAlpha(0)

	if FriendsFrame.IgnoreListWindow then
		FriendsFrame.IgnoreListWindow:Hide()
	end

	FriendsFrame:Hide()

	if FriendsFrame:IsShown() then
		self.pendingBlizzardFriendsFrameHide = true
		return false
	end

	if UpdateUIPanelPositions then
		pcall(UpdateUIPanelPositions, FriendsFrame)
	end

	FriendsFrame:SetAlpha(1)
	self.pendingBlizzardFriendsFrameHide = nil
	return true
end

function BFL:ConsumeFriendsFrameRedirect(defaultAction, defaultTab, defaultTopTab)
	local request = self.pendingFriendsFrameRedirect
	self.pendingFriendsFrameRedirect = nil

	if request then
		return self:HandleFriendsFrameRedirect(request.action, request.tabIndex, request.topTabIndex)
	end

	return self:HandleFriendsFrameRedirect(defaultAction or "toggle", defaultTab or 1, defaultTopTab)
end

function BFL:QueueFriendsFrameRedirect(action, tabIndex, topTabIndex)
	if self.AllowBlizzardFriendsFrame then
		return
	end

	self.pendingFriendsFrameRedirect = {
		action = action,
		tabIndex = tabIndex,
		topTabIndex = topTabIndex,
	}

	if self.friendsFrameRedirectTimerPending then
		return
	end

	self.friendsFrameRedirectTimerPending = true
	RunNextFrame(function()
		BFL.friendsFrameRedirectTimerPending = nil

		if not BFL.pendingFriendsFrameRedirect or BFL.friendsFrameRedirectOnShowPending then
			return
		end

		if FriendsFrame and FriendsFrame:IsShown() then
			BFL:HideBlizzardFriendsFrameForRedirect()
		end

		BFL:ConsumeFriendsFrameRedirect("show", 1)
	end)
end

function BFL:InstallFriendsFrameRedirects()
	if self.friendsFrameRedirectsInstalled then
		return
	end

	if not (FriendsFrame and _G.ToggleFriendsFrame) then
		self.pendingFriendsFrameRedirectInstall = true
		return
	end

	self.friendsFrameRedirectsInstalled = true
	self.pendingFriendsFrameRedirectInstall = nil
	self.AllowBlizzardFriendsFrame = false

	if not self.HasSecretValues and UIPanelWindows and UIPanelWindows["FriendsFrame"] then
		self.OriginalFriendsFrameUIPanelSettings = UIPanelWindows["FriendsFrame"]
		UIPanelWindows["FriendsFrame"] = nil
	end

	local function installRedirect(name, directHandler)
		local original = StoreOriginalFriendsFrameFunction(name)
		if not original then
			return
		end

		_G[name] = function(...)
			if BFL.AllowBlizzardFriendsFrame then
				return original(...)
			end
			return directHandler(...)
		end
	end

	local function directShow(tabIndex, topTabIndex)
		return BFL:HandleFriendsFrameRedirect("show", tabIndex, topTabIndex)
	end

	local function directToggle(tabIndex, topTabIndex)
		return BFL:HandleFriendsFrameRedirect("toggle", tabIndex, topTabIndex)
	end

	installRedirect("ToggleFriendsFrame", function(tabIndex)
		if tabIndex == nil then
			return BFL:HandleFriendsFrameRedirect("toggle-any", 1)
		end
		return directToggle(tabIndex)
	end)
	installRedirect("OpenFriendsFrame", directShow)
	installRedirect("ShowFriends", function()
		return directShow(1)
	end)
	installRedirect("ShowWhoPanel", function()
		return directShow(2)
	end)
	installRedirect("ToggleFriendsSubPanel", function(panelIndex)
		return directToggle(1, NormalizeFriendsSubPanel(panelIndex))
	end)
	installRedirect("ToggleFriendsPanel", function()
		return directToggle(1, 1)
	end)
	installRedirect("ToggleRecentAlliesPanel", function()
		return directToggle(1, 2)
	end)
	installRedirect("ToggleRafPanel", function()
		return directToggle(1, 3)
	end)
	installRedirect("ToggleQuickJoinPanel", function()
		return directToggle(4)
	end)
	installRedirect("ToggleIgnorePanel", function()
		return BFL:HandleFriendsFrameRedirect("ignore")
	end)

	self.ShowBlizzardFriendsFrame = function()
		BFL.AllowBlizzardFriendsFrame = true

		if _G.HideBetterFriendsFrame and BetterFriendsFrame and BetterFriendsFrame:IsShown() then
			_G.HideBetterFriendsFrame()
		end

		if BFL.OriginalFriendsFrameUIPanelSettings and UIPanelWindows then
			UIPanelWindows["FriendsFrame"] = BFL.OriginalFriendsFrameUIPanelSettings
		end

		if BFL.OriginalOpenFriendsFrame then
			BFL.OriginalOpenFriendsFrame(1)
		elseif BFL.OriginalToggleFriendsFrame then
			BFL.OriginalToggleFriendsFrame(1)
		elseif FriendsFrame then
			FriendsFrame:Show()
		end

		C_Timer.After(0.1, function()
			BFL.AllowBlizzardFriendsFrame = false
		end)
	end

	if FriendsFrame and FriendsFrame.HookScript then
		FriendsFrame:HookScript("OnShow", function(frame)
			if BFL.AllowBlizzardFriendsFrame or BFL._suppressFriendsFrameRedirect then
				return
			end

			local requestedTab = NormalizeFriendsFrameTab(PanelTemplates_GetSelectedTab(FriendsFrame) or 1)
			if PanelTemplates_SetTab then
				PanelTemplates_SetTab(FriendsFrame, 1)
			end

			frame:SetAlpha(0)
			if frame:IsShown() then
				frame:Hide()
			end
			BFL.pendingBlizzardFriendsFrameHide = nil
			BFL.friendsFrameRedirectOnShowPending = true

			RunNextFrame(function()
				BFL.friendsFrameRedirectOnShowPending = nil

				if BFL.AllowBlizzardFriendsFrame or BFL._suppressFriendsFrameRedirect then
					return
				end

				BFL:HideBlizzardFriendsFrameForRedirect()
				BFL:ConsumeFriendsFrameRedirect("toggle", requestedTab)
			end)
		end)
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
		local isElvUIActive = BFL.IsThemeActive and BFL:IsThemeActive("elvui")
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

		local classicButtonFrameLayoutApplied = CoreApplyClassicButtonFramePortraitLayout(frame, shouldShowPortrait)

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
						local isMainButtonFrameCorner = BFL.IsClassic and classicButtonFrameLayoutApplied and parentFrame == frame

						if isMainButtonFrameCorner then
							if not shouldShowPortrait then
								region:Show()
								region:SetAlpha(1)
								region:SetVertexColor(1, 1, 1, 1)
								CoreSetClassicTopLeftCornerTexture(region)
							end
						elseif shouldShowPortrait then
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
								CoreTrySetAtlas(region, "UI-Frame-PortraitMetal-CornerTopLeft", true)
							end
						else
							-- Swap to standard square corner (Closed hole)

							region:Show()
							region:SetAlpha(1)
							region:SetVertexColor(1, 1, 1, 1)

							local appliedAtlas = CoreTrySetAtlas(region, "UI-Frame-Metal-CornerTopLeft", true)
							if not appliedAtlas and BFL.IsClassic then
								CoreSetClassicTopLeftCornerTexture(region)
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
			local isElvUIActive = BFL.IsThemeActive and BFL:IsThemeActive("elvui")
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
			-- Dropdown positioning for Classic Normal Mode is handled by
			-- FriendsList:UpdateSearchBoxState() (above SearchBox, not beside it)
			-- No override needed here.
		end
	end
end

-- Open Configuration
function BFL:OpenConfig()
	local Settings = self:GetModule("Settings")
	if Settings then
		local SettingsDesigner = self:GetModule("SettingsDesigner")
		if SettingsDesigner and SettingsDesigner.IsShown and SettingsDesigner:IsShown() then
			Settings:Hide()
			return
		end

		if _G.BetterFriendlistSettingsFrame and _G.BetterFriendlistSettingsFrame:IsShown() then
			Settings:Hide()
			return
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

function BFL:IsPendingRaidRosterName(name)
	if name == nil or name == "" then
		return true
	end
	if self:IsSecret(name) then
		return true
	end
	local unknownName = UNKNOWN or "Unknown"
	return name == unknownName or name == "Unknown"
end

-- Get a safe (non-secret) account name for string operations.
-- Returns battleTag if accountName is a kString secret, otherwise accountName.
-- Falls back to battleTag or "Unknown" if accountName is nil.
-- NOTE: Must check issecretvalue() BEFORE any boolean test on accountName,
-- because `if secret then` itself throws an error on 12.0.0+ secret values.
function BFL:GetSafeAccountName(accountName, battleTag)
	if self:IsSecret(accountName) then
		return battleTag or "Unknown"
	end
	if accountName then
		return accountName
	end
	return battleTag or "Unknown"
end

-- Safe tostring() that handles kString secret values.
-- Returns "<kString>" if value is secret, otherwise tostring(value).
function BFL:SafeToString(value)
	if self:IsSecret(value) then
		return "<kString>"
	end
	return tostring(value)
end

-- Secure wrappers for Blizzard chat APIs.
-- When BFL (tainted addon code) calls chat APIs directly, the taint propagates
-- into Blizzard's chat frame code, permanently tainting globals like LAST_ACTIVE_CHAT_EDIT_BOX.
-- On 12.0.0+ this causes "attempt to perform arithmetic on a secret number value" errors
-- when FCF_OpenTemporaryWindow later reads the tainted global during UpdateHeader.
-- Fix: On 12.0.0+, use securecallfunction() to call Blizzard APIs in a new secure
-- execution context that does not inherit the caller's taint.

-- Taint-Free Whisper: Inline EditBox integrated into the BFL frame bottom bar.
-- When enabled via Settings > Advanced, this bypasses ChatFrameUtil.SendBNetTell/SendTell entirely.
-- Instead of opening Blizzard's chat, an inline input bar appears at the bottom of the BFL frame,
-- replacing the Add Friend / Send Message buttons temporarily.
do
	local whisperBar
	local stickyWhisper -- persists across bar hide/show for "sticky target" behavior

	local function GetSafeWhisperValue(value)
		if BFL:IsSecret(value) then
			return nil
		end
		if value and value ~= "" then
			return value
		end
		return nil
	end

	local function GetSafeWhisperAccountID(value)
		if BFL:IsSecret(value) then
			return nil
		end
		if type(value) == "number" then
			return value
		end
		if type(value) == "string" then
			return tonumber(value)
		end
		return nil
	end

	local function CallChatAPI(func, ...)
		if not func then
			return nil
		end
		if BFL.HasSecretValues and securecallfunction then
			return securecallfunction(func, ...)
		end
		return func(...)
	end

	local function SendTaintFreeWhisper(bar, text)
		if bar.isBNet then
			local bnetIDAccount = GetSafeWhisperAccountID(bar.bnetIDAccount)
			if not bnetIDAccount then
				return false
			end
			local func = C_BattleNet and C_BattleNet.SendWhisper or BNSendWhisper
			if not func then
				return false
			end
			local success = CallChatAPI(func, bnetIDAccount, text)
			return success ~= false
		end

		local whisperTarget = GetSafeWhisperValue(bar.whisperTarget)
		if not whisperTarget then
			return false
		end
		local func = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
		if not func then
			return false
		end
		CallChatAPI(func, text, "WHISPER", nil, whisperTarget)
		return true
	end

	local function EnsureWhisperBar()
		if whisperBar then return whisperBar end

		-- Defer creation until BetterFriendsFrame exists
		local parent = _G.BetterFriendsFrame
		if not parent then return nil end

		local bar = CreateFrame("Frame", nil, parent)
		bar:SetHeight(25)
		bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 6, 3)
		bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 3)
		bar:SetFrameLevel(parent:GetFrameLevel() + 10)

		-- "To: Name" label
		local toLabel = bar:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
		toLabel:SetPoint("LEFT", bar, "LEFT", 6, 0)
		toLabel:SetJustifyH("LEFT")
		toLabel:SetTextColor(0.6, 0.6, 0.6)
		bar.ToLabel = toLabel

		-- EditBox
		local editBox = CreateFrame("EditBox", nil, bar, "InputBoxTemplate")
		editBox:SetHeight(20)
		editBox:SetPoint("LEFT", toLabel, "RIGHT", 4, 0)
		editBox:SetPoint("RIGHT", bar, "RIGHT", -60, 0)
		editBox:SetAutoFocus(false)
		editBox:SetMaxLetters(255)
		editBox:SetFontObject("BetterFriendlistFontNormal")
		bar.EditBox = editBox

		-- Send button (small, icon-style arrow)
		local sendBtn = CreateFrame("Button", nil, bar)
		sendBtn:SetSize(22, 22)
		sendBtn:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
		sendBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		sendBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
		sendBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		bar.SendButton = sendBtn

		-- Close/cancel button
		local closeBtn = CreateFrame("Button", nil, bar)
		closeBtn:SetSize(22, 22)
		closeBtn:SetPoint("LEFT", sendBtn, "RIGHT", 0, 0)
		closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		bar.CloseButton = closeBtn

		local hiddenByBar = {} -- tracks which elements we hid (to restore on close)

		-- Collect all bottom-area elements across all tabs (built dynamically
		-- because sub-frames like WhoFrame/RaidFrame may not exist at bar creation time)
		local function GetBottomElements()
			local elems = {
				parent.AddFriendButton,
				parent.SendMessageButton,
				parent.RecruitmentButton,
			}
			-- WhoFrame bottom buttons:
			if parent.WhoFrame then
				elems[#elems + 1] = parent.WhoFrame.WhoButton
				elems[#elems + 1] = parent.WhoFrame.AddFriendButton
				elems[#elems + 1] = parent.WhoFrame.GroupInviteButton
			end
			-- RaidFrame bottom buttons:
			if parent.RaidFrame then
				elems[#elems + 1] = parent.RaidFrame.ConvertToRaidButton
				elems[#elems + 1] = parent.RaidFrame.RaidToolsButton
			end
			-- QuickJoinFrame bottom button:
			if parent.QuickJoinFrame and parent.QuickJoinFrame.ScrollFrame then
				elems[#elems + 1] = parent.QuickJoinFrame.ScrollFrame.JoinQueueButton
			end
			return elems
		end

		local function HideBottomElements()
			wipe(hiddenByBar)
			for _, elem in ipairs(GetBottomElements()) do
				if elem and elem:IsShown() then
					hiddenByBar[elem] = true
					elem:Hide()
				end
			end
		end
		bar.HideBottomElements = HideBottomElements

		local function RestoreBottomElements()
			for elem in pairs(hiddenByBar) do
				elem:Show()
			end
			wipe(hiddenByBar)
		end

		local function SoftCloseBar()
			RestoreBottomElements()
			editBox:ClearFocus()
			bar:Hide()
		end

		local function HardCloseBar()
			RestoreBottomElements()
			editBox:ClearFocus()
			bar:Hide()
			editBox:SetText("")
			-- Hard close: clear sticky state (user explicitly closed via X button)
			stickyWhisper = nil
			bar.bnetIDAccount = nil
			bar.whisperTarget = nil
			bar.isBNet = nil
		end

		local function DoSend()
			local text = editBox:GetText()
			if not text or text == "" then
				-- Empty message: soft close while preserving the current target.
				SoftCloseBar()
				return
			end
			if not SendTaintFreeWhisper(bar, text) then
				BFL:DebugPrint("TaintFreeWhisper: Missing safe whisper target")
				editBox:SetFocus()
				return
			end
			-- Close bar after sending while preserving the current target.
			SoftCloseBar()
		end

		editBox:SetScript("OnEnterPressed", DoSend)
		editBox:SetScript("OnEscapePressed", SoftCloseBar)
		sendBtn:SetScript("OnClick", DoSend)
		closeBtn:SetScript("OnClick", HardCloseBar)
		bar:SetScript("OnHide", function()
			-- Soft close: preserve sticky state (tab switch, frame hide)
			editBox:SetText("")
			editBox:ClearFocus()
			wipe(hiddenByBar) -- clear tracking; tab switch handles its own elements
		end)

		-- Tooltip for send button
		sendBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(BFL.L and BFL.L.TAINT_FREE_WHISPER_SEND or "Send")
			GameTooltip:Show()
		end)
		sendBtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Tooltip for close button
		closeBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(BFL.L and BFL.L.TAINT_FREE_WHISPER_CANCEL or "Cancel")
			GameTooltip:Show()
		end)
		closeBtn:SetScript("OnLeave", GameTooltip_Hide)

		bar:Hide()
		whisperBar = bar

		parent:EnableKeyboard(false)

		return bar
	end

	function BFL:OpenTaintFreeWhisper(displayName, whisperTarget, bnetIDAccount, isBNet)
		local safeDisplayName = GetSafeWhisperValue(displayName)
		local safeWhisperTarget = GetSafeWhisperValue(whisperTarget)
		local safeBNetID = GetSafeWhisperAccountID(bnetIDAccount)
		local labelName = safeDisplayName or safeWhisperTarget or UNKNOWN or "Unknown"

		if isBNet then
			if not safeBNetID then
				BFL:DebugPrint("TaintFreeWhisper: Missing safe BNet account ID")
				return
			end
		else
			safeWhisperTarget = safeWhisperTarget or safeDisplayName
			if not safeWhisperTarget then
				BFL:DebugPrint("TaintFreeWhisper: Missing safe character whisper target")
				return
			end
			labelName = safeDisplayName or safeWhisperTarget
		end

		local bar = EnsureWhisperBar()
		if not bar then
			-- Fallback: BFL frame not ready, use standard path
			if isBNet then
				local func = ChatFrameUtil and ChatFrameUtil.SendBNetTell or ChatFrame_SendBNetTell
				if func and safeDisplayName then
					CallChatAPI(func, safeDisplayName)
				end
			else
				local func = ChatFrameUtil and ChatFrameUtil.SendTell or ChatFrame_SendTell
				if func and safeWhisperTarget then
					CallChatAPI(func, safeWhisperTarget)
				end
			end
			return
		end

		local L = BFL.L

		-- Set whisper target info
		bar.bnetIDAccount = safeBNetID
		bar.whisperTarget = safeWhisperTarget
		bar.isBNet = isBNet and true or false

		-- Save sticky state so bar can be restored after tab switch / frame hide
		stickyWhisper = {
			displayName = labelName,
			whisperTarget = safeWhisperTarget,
			bnetIDAccount = safeBNetID,
			isBNet = isBNet and true or false,
		}

		-- Set label
		local titlePattern = L and L.TAINT_FREE_WHISPER_TITLE or "Whisper to %s"
		bar.ToLabel:SetText(string.format(titlePattern, labelName) .. ":")

		-- Auto-open BFL frame if not yet visible (e.g., triggered from Broker tooltip)
		local parent = _G.BetterFriendsFrame
		if parent and not parent:IsShown() then
			if ShowBetterFriendsFrame then
				ShowBetterFriendsFrame(1)
			else
				parent:Show()
			end
		end

		-- Hide bottom elements, show inline bar
		bar.HideBottomElements()

		bar:Show()
		bar.EditBox:SetFocus()
	end

	-- Close the whisper bar externally (e.g., when switching tabs)
	-- Soft close: hide bar but preserve sticky state (tab switch, frame hide)
	function BFL:CloseTaintFreeWhisper(clearSticky)
		if clearSticky then
			stickyWhisper = nil
			if whisperBar then
				whisperBar.bnetIDAccount = nil
				whisperBar.whisperTarget = nil
				whisperBar.isBNet = nil
			end
		end
		if whisperBar and whisperBar:IsShown() then
			whisperBar:Hide()
			-- Note: Do NOT restore bottom elements here.
			-- The tab switch code will show the correct elements for the new tab.
		end
	end

	-- Restore whisper bar from sticky state (e.g., after returning to Friends tab)
	function BFL:RestoreTaintFreeWhisper()
		if not stickyWhisper then return end
		if not BetterFriendlistDB or not BetterFriendlistDB.taintFreeWhisper then
			stickyWhisper = nil
			return
		end
		BFL:OpenTaintFreeWhisper(
			stickyWhisper.displayName,
			stickyWhisper.whisperTarget,
			stickyWhisper.bnetIDAccount,
			stickyWhisper.isBNet
		)
	end
end

function BFL:SecureSendBNetTell(name, bnetIDAccount, displayName)
	local safeName = name
	if BFL:IsSecret(safeName) then
		safeName = nil
	end
	local safeDisplayName = displayName
	if BFL:IsSecret(safeDisplayName) then
		safeDisplayName = nil
	end
	safeDisplayName = safeDisplayName or safeName
	local safeBNetID = bnetIDAccount
	if BFL:IsSecret(safeBNetID) then
		safeBNetID = nil
	elseif type(safeBNetID) == "string" then
		safeBNetID = tonumber(safeBNetID)
	elseif type(safeBNetID) ~= "number" then
		safeBNetID = nil
	end

	-- Taint-Free Whisper: Use custom EditBox popup instead of Blizzard chat
	if BetterFriendlistDB and BetterFriendlistDB.taintFreeWhisper then
		if safeBNetID then
			BFL:OpenTaintFreeWhisper(safeDisplayName, nil, safeBNetID, true)
		else
			BFL:DebugPrint("SecureSendBNetTell: Missing safe BNet account ID")
		end
		return
	end
	if not safeName then return end
	local func = ChatFrameUtil and ChatFrameUtil.SendBNetTell or ChatFrame_SendBNetTell
	if not func then return end
	if BFL.HasSecretValues and securecallfunction then
		securecallfunction(func, safeName)
	else
		func(safeName)
	end
end

function BFL:SecureSendTell(name)
	if BFL:IsSecret(name) then
		return
	end
	if not name then return end
	-- Taint-Free Whisper: Use custom EditBox popup instead of Blizzard chat
	if BetterFriendlistDB and BetterFriendlistDB.taintFreeWhisper then
		BFL:OpenTaintFreeWhisper(name, name, nil, false)
		return
	end
	local func = ChatFrameUtil and ChatFrameUtil.SendTell or ChatFrame_SendTell
	if not func then return end
	if BFL.HasSecretValues and securecallfunction then
		securecallfunction(func, name)
	else
		func(name)
	end
end

function BFL:SecureOpenChat(msg)
	if not msg then return end
	local func = ChatFrameUtil and ChatFrameUtil.OpenChat or ChatFrame_OpenChat
	if not func then return end
	if BFL.HasSecretValues and securecallfunction then
		securecallfunction(func, msg)
	else
		func(msg)
	end
end

-- Secure SetItemRef for 12.0.0+ taint prevention.
function BFL:SecureSetItemRef(link, text, button)
	if not link then return end
	if BFL.HasSecretValues and securecallfunction then
		securecallfunction(SetItemRef, link, text, button)
	else
		SetItemRef(link, text, button)
	end
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
		if FriendsList.CancelScheduledRefresh then
			FriendsList:CancelScheduledRefresh()
		end

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

function BFL:ScheduleFriendsListRefresh(reason, delay, ignoreVisibility)
	local FriendsList = self:GetModule("FriendsList")
	if FriendsList and FriendsList.ScheduleRefresh then
		FriendsList:ScheduleRefresh(reason, delay, ignoreVisibility)
	elseif self.ForceRefreshFriendsList then
		self:ForceRefreshFriendsList()
	end
end

-- Register initial events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
pcall(eventFrame.RegisterEvent, eventFrame, "BINDINGS_LOADED")
pcall(eventFrame.RegisterEvent, eventFrame, "ADDONS_UNLOADING")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == ADDON_NAME then
			-- Get version dynamically from TOC file
			BFL.VERSION = C_AddOns.GetAddOnMetadata("BetterFriendlist", "Version") or "Unknown"

			-- Link Localization
			BFL.L = _G["BFL_L"]
			BFL:UpdateBindingGlobals()

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
			EnsureSeparateClassicGuildWindow()

			-- Initialize all modules
			for name, module in pairs(BFL.Modules) do
				if name ~= "DB" and module.Initialize then
					module:Initialize()
				end
			end

			-- Best Practice: Register LibSharedMedia callbacks (modern approach)
			-- Ensures fonts update immediately if a new font is registered (e.g. by another addon)
			local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
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

			BFL:InstallFriendsFrameRedirects()
			BFL:InstallBetterFriendsFrameEscapeHandler()
		elseif addonName == "Blizzard_FriendsFrame" then
			EnsureSeparateClassicGuildWindow()
			BFL:InstallFriendsFrameRedirects()
		end
	elseif event == "PLAYER_LOGIN" then
		-- Check for native event callbacks (12.0.0+)
		if BetterFriendsFrame and BetterFriendsFrame.RegisterEventCallback then
			BFL.UseNativeCallbacks = true
			-- BFL:DebugPrint("|cff00ff00[BFL]|r Using native Frame:RegisterEventCallback (12.0.0+)")
		end

		EnsureSeparateClassicGuildWindow()
		BFL:InstallSocialKeybindOverride()
		BFL:MigrateSocialKeybindToNativeBinding()
		BFL:InstallFriendsFrameRedirects()
		BFL:InstallBetterFriendsFrameEscapeHandler()

		-- Late initialization for modules that need PLAYER_LOGIN
		for name, module in pairs(BFL.Modules) do
			if module.OnPlayerLogin then
				module:OnPlayerLogin()
			end
		end

		-- Trigger a silent FriendsFrame:Show() so addons that defer their hook
		-- registration to FriendsFrame:OnShow (e.g. ArchonTooltip) get initialized.
		-- IMPORTANT: Deferred to next frame so ALL PLAYER_LOGIN handlers finish first.
		-- ArchonTooltip deliberately hooks FriendsTooltip:Show AFTER RaiderIO (so RaiderIO
		-- sets GameTooltip owner first, then ArchonTooltip appends). If we trigger
		-- FriendsFrame:Show() synchronously during PLAYER_LOGIN, ArchonTooltip registers
		-- before RaiderIO (which also initializes during PLAYER_LOGIN), reversing the
		-- intended hook order and causing ArchonTooltip content to be wiped by RaiderIO.
		-- On 12.0.0+ secret-value clients, avoid opening Blizzard's FriendsFrame
		-- automatically from BFL tainted code. This keeps login-time tooltip
		-- compatibility hooks from becoming a hidden social UI taint source.
		if FriendsFrame and not BFL.HasSecretValues then
			C_Timer.After(0, function()
				BFL._suppressFriendsFrameRedirect = true
				FriendsFrame:SetAlpha(0)
				FriendsFrame:Show()
				C_Timer.After(0, function()
					FriendsFrame:Hide()
					FriendsFrame:SetAlpha(1)
					BFL._suppressFriendsFrameRedirect = nil
				end)
			end)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if BFL.pendingBlizzardFriendsFrameHide then
			BFL:HideBlizzardFriendsFrameForRedirect()
		end
		if BFL.pendingSocialKeybindOverride then
			BFL:InstallSocialKeybindOverride()
		end
		if BFL.pendingSocialKeybindMigration then
			BFL.pendingSocialKeybindMigration = nil
			BFL:MigrateSocialKeybindToNativeBinding()
		end
	elseif event == "UPDATE_BINDINGS" then
		BFL:InstallSocialKeybindOverride()
	elseif event == "BINDINGS_LOADED" then
		BFL:MigrateSocialKeybindToNativeBinding()
	elseif event == "ADDONS_UNLOADING" then
		BFL:RestoreMigratedSocialKeybindsForAddonDisable()
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
			Settings:Show()
		else
			print("|cffff0000BetterFriendlist:|r " .. BFL.L.CORE_SETTINGS_NOT_LOADED)
		end
	elseif msg == "settingslegacy" or msg == "legacysettings" then
		local Settings = BFL:GetModule("Settings")
		if Settings and Settings.ShowLegacy then
			Settings:ShowLegacy()
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
					local nameMatch = (
						info.accountName
						and not BFL:IsSecret(info.accountName)
						and info.accountName:lower():find(searchName, 1, true)
					)
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
								.. BFL:SafeToString(info.accountName)
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
					nameMatch = (friend.accountName and not BFL:IsSecret(friend.accountName) and friend.accountName:lower():find(searchName, 1, true))
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
						nameMatch = (friend.accountName and not BFL:IsSecret(friend.accountName) and friend.accountName:lower():find(searchName, 1, true))
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
