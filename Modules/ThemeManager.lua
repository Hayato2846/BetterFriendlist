-- Modules/ThemeManager.lua
-- Theme selection and application orchestration for BetterFriendlist

local ADDON_NAME, BFL = ...
local ThemeManager = BFL:RegisterModule("ThemeManager", {})

local VALID_THEMES = {}
local THEME_DEFINITIONS = {}
local effectiveThemeCache
local effectiveThemeCacheStored
local effectiveThemeCacheAvailable

BFL.THEMES = {
	BLIZZARD = "blizzard",
	DARK = "dark",
	CUSTOM = "custom",
	ELVUI = "elvui",
	ELLESMEREUI = "ellesmereui",
}

local function IsElvUIAvailable()
	return BFL.IsElvUIAvailable and BFL:IsElvUIAvailable()
end

local function IsEllesmereUIAvailable()
	return BFL.IsEllesmereUIAvailable and BFL:IsEllesmereUIAvailable()
end

local function RegisterThemeDefinition(theme, options)
	if type(theme) ~= "string" or theme == "" then
		return false
	end

	options = type(options) == "table" and options or {}
	VALID_THEMES[theme] = true
	THEME_DEFINITIONS[theme] = {
		id = theme,
		order = tonumber(options.order) or 1000,
		labelKey = options.labelKey,
		label = options.label,
		onboardingDescriptionKey = options.onboardingDescriptionKey,
		isAvailable = options.isAvailable,
		requiresReload = options.requiresReload == true,
		previewable = options.previewable ~= false,
	}
	return true
end

RegisterThemeDefinition("blizzard", {
	order = 100,
	labelKey = "SETTINGS_THEME_BLIZZARD",
	onboardingDescriptionKey = "ONBOARDING_THEME_BLIZZARD_DESC",
})
RegisterThemeDefinition("dark", {
	order = 200,
	labelKey = "SETTINGS_THEME_DARK",
	onboardingDescriptionKey = "ONBOARDING_THEME_DARK_DESC",
})
RegisterThemeDefinition("custom", {
	order = 300,
	labelKey = "SETTINGS_THEME_CUSTOM",
	onboardingDescriptionKey = "ONBOARDING_THEME_CUSTOM_DESC",
})
RegisterThemeDefinition("elvui", {
	order = 900,
	labelKey = "SETTINGS_THEME_ELVUI",
	onboardingDescriptionKey = "ONBOARDING_THEME_ELVUI_DESC",
	isAvailable = IsElvUIAvailable,
	requiresReload = true,
	previewable = false,
})
RegisterThemeDefinition("ellesmereui", {
	order = 910,
	labelKey = "SETTINGS_THEME_ELLESMEREUI",
	onboardingDescriptionKey = "ONBOARDING_THEME_ELLESMEREUI_DESC",
	isAvailable = IsEllesmereUIAvailable,
	requiresReload = true,
	previewable = false,
})

local function NormalizeTheme(theme)
	if VALID_THEMES[theme] then
		return theme
	end
	return "blizzard"
end

local function AreThemeFeaturesEnabled()
	return true
end

local function ShouldUseLegacyElvUISkinSetting()
	return not AreThemeFeaturesEnabled()
end

local function ShouldShowLegacyElvUISkinSetting()
	return ShouldUseLegacyElvUISkinSetting() and IsElvUIAvailable()
end

local function IsLegacyElvUISkinEnabled()
	if not BetterFriendlistDB then
		return false
	end
	return BetterFriendlistDB.enableElvUISkin == true or BetterFriendlistDB.theme == "elvui"
end

local function GetStoredTheme()
	if not BetterFriendlistDB then
		return "blizzard"
	end

	if ShouldUseLegacyElvUISkinSetting() then
		return IsLegacyElvUISkinEnabled() and "elvui" or "blizzard"
	end

	if BetterFriendlistDB.theme == nil then
		return BetterFriendlistDB.enableElvUISkin == true and "elvui" or "blizzard"
	end

	return NormalizeTheme(BetterFriendlistDB.theme)
end

local function IsStoredThemeAvailable(theme)
	if theme == "elvui" then
		return IsElvUIAvailable() == true
	end
	if theme == "ellesmereui" then
		return IsEllesmereUIAvailable() == true
	end
	return true
end

local function InvalidateEffectiveThemeCache()
	effectiveThemeCache = nil
	effectiveThemeCacheStored = nil
	effectiveThemeCacheAvailable = nil
end

local function RefreshClassicBlizzardPortraitVisibility(reason)
	if not (BFL.IsClassic and BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() == "blizzard") then
		return
	end
	if type(BFL.UpdatePortraitVisibility) ~= "function" then
		return
	end

	BFL:UpdatePortraitVisibility(reason or "theme-manager-blizzard")
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if
				BFL.IsClassic
				and BFL.GetEffectiveTheme
				and BFL:GetEffectiveTheme() == "blizzard"
				and type(BFL.UpdatePortraitVisibility) == "function"
			then
				BFL:UpdatePortraitVisibility((reason or "theme-manager-blizzard") .. "-deferred")
			end
		end)
	end
end

function BFL:AreThemeFeaturesEnabled()
	return AreThemeFeaturesEnabled()
end

function BFL:ShouldUseLegacyElvUISkinSetting()
	return ShouldUseLegacyElvUISkinSetting()
end

function BFL:ShouldShowLegacyElvUISkinSetting()
	return ShouldShowLegacyElvUISkinSetting()
end

function BFL:GetEffectiveTheme()
	local storedTheme = GetStoredTheme()
	if
		effectiveThemeCache == nil
		or effectiveThemeCacheStored ~= storedTheme
	then
		local available = IsStoredThemeAvailable(storedTheme)
		effectiveThemeCacheStored = storedTheme
		effectiveThemeCacheAvailable = available
		effectiveThemeCache = available and storedTheme or "blizzard"
	end
	return effectiveThemeCache
end

function BFL:IsThemeActive(theme)
	return self:GetEffectiveTheme() == NormalizeTheme(theme)
end

function BFL:IsElvUISkinActive()
	local ElvUISkin = self.GetModule and self:GetModule("ElvUISkin")
	if ElvUISkin and ElvUISkin.IsSkinEnabled then
		return ElvUISkin:IsSkinEnabled() == true
	end

	return self:IsThemeActive("elvui") or IsLegacyElvUISkinEnabled()
end

function BFL:IsEllesmereUISkinActive()
	local EllesmereUISkin = self.GetModule and self:GetModule("EllesmereUISkin")
	return EllesmereUISkin
		and EllesmereUISkin.IsSkinEnabled
		and EllesmereUISkin:IsSkinEnabled() == true
		or false
end

function BFL:UsesFlatTheme()
	local theme = self:GetEffectiveTheme()
	return theme == "dark" or theme == "custom" or theme == "ellesmereui"
end

function BFL:IsThemeAvatarHidden(theme)
	theme = theme or self:GetEffectiveTheme()
	if theme ~= "dark" and theme ~= "custom" and theme ~= "elvui" and theme ~= "ellesmereui" then return false end
	local DB = self:GetModule("DB")
	return not DB or DB:Get("hideThemeAvatar", true) ~= false
end

function BFL:UsesDarkSkinTheme()
	local theme = self:GetEffectiveTheme()
	return theme == "dark" or theme == "custom"
end

function ThemeManager:Initialize()
	if not self.eventCallbacksRegistered then
		self.eventCallbacksRegistered = true
		BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
			self:ApplyPendingTheme()
		end, 80)
	end

	self:ApplyCurrentTheme("initialize")
end

function ThemeManager:OnPlayerLogin()
	self:ApplyCurrentTheme("player-login")
end

function ThemeManager:IsValidTheme(theme)
	return VALID_THEMES[theme] == true
end

function ThemeManager:RegisterTheme(theme, options)
	-- Theme modules register at file load so database normalization, Settings,
	-- and the one-time appearance onboarding all consume the same catalog.
	return RegisterThemeDefinition(theme, options)
end

function ThemeManager:GetThemeDefinition(theme)
	return THEME_DEFINITIONS[theme]
end

function ThemeManager:IsThemeAvailable(theme)
	local definition = THEME_DEFINITIONS[theme]
	if not definition or not VALID_THEMES[theme] then
		return false
	end
	if type(definition.isAvailable) ~= "function" then
		return true
	end
	local ok, available = pcall(definition.isAvailable)
	return ok and available == true
end

function ThemeManager:GetAvailableThemeIDs()
	local themes = {}
	for theme in pairs(THEME_DEFINITIONS) do
		if self:IsThemeAvailable(theme) then
			themes[#themes + 1] = theme
		end
	end
	table.sort(themes, function(left, right)
		local leftDefinition = THEME_DEFINITIONS[left] or {}
		local rightDefinition = THEME_DEFINITIONS[right] or {}
		local leftOrder = tonumber(leftDefinition.order) or 1000
		local rightOrder = tonumber(rightDefinition.order) or 1000
		if leftOrder ~= rightOrder then
			return leftOrder < rightOrder
		end
		return left < right
	end)
	return themes
end

local function GetThemeLocalizationToken(theme)
	return tostring(theme or ""):gsub("[^%w]", "_"):upper()
end

local function ResolveLocalizedText(locale, key)
	local value = locale and locale[key]
	-- BFL's locale table returns the requested key when a translation is
	-- missing. Do not mistake that diagnostic fallback for user-facing copy.
	if type(value) == "string" and value ~= "" and value ~= key then
		return value
	end
	return nil
end

function ThemeManager:GetThemeLabel(theme)
	local definition = THEME_DEFINITIONS[theme] or {}
	local locale = BFL.L or _G.BFL_L or {}
	local labelKey = definition.labelKey or ("SETTINGS_THEME_" .. GetThemeLocalizationToken(theme))
	return ResolveLocalizedText(locale, labelKey) or definition.label or tostring(theme or "")
end

function ThemeManager:GetThemeOnboardingDescription(theme)
	local definition = THEME_DEFINITIONS[theme] or {}
	local locale = BFL.L or _G.BFL_L or {}
	local descriptionKey = definition.onboardingDescriptionKey
		or ("ONBOARDING_THEME_" .. GetThemeLocalizationToken(theme) .. "_DESC")
	local description = ResolveLocalizedText(locale, descriptionKey)
	if description then
		return description
	end
	local fallback = ResolveLocalizedText(locale, "ONBOARDING_THEME_GENERIC_DESC")
		or "Preview the %s theme on your BetterFriendlist."
	local ok, text = pcall(string.format, fallback, self:GetThemeLabel(theme))
	return ok and text or fallback
end

function ThemeManager:GetThemeOptions()
	local options = {}
	local order = self:GetAvailableThemeIDs()
	for _, theme in ipairs(order) do
		options[theme] = self:GetThemeLabel(theme)
	end
	return options, order
end

function ThemeManager:ThemeSelectionRequiresReload(previousTheme, nextTheme)
	local previous = THEME_DEFINITIONS[previousTheme]
	local nextDefinition = THEME_DEFINITIONS[nextTheme]
	return (previous and previous.requiresReload == true)
		or (nextDefinition and nextDefinition.requiresReload == true)
end

function ThemeManager:CanPreviewTheme(theme, previousTheme)
	local definition = THEME_DEFINITIONS[theme]
	return definition ~= nil
		and definition.previewable ~= false
		and not self:ThemeSelectionRequiresReload(previousTheme, theme)
end

function ThemeManager:GetStoredTheme()
	return GetStoredTheme()
end

function ThemeManager:GetEffectiveTheme()
	return BFL:GetEffectiveTheme()
end

function ThemeManager:SetTheme(theme, reason)
	theme = NormalizeTheme(theme)

	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("theme", theme)
		DB:Set("enableElvUISkin", theme == "elvui")
	elseif BetterFriendlistDB then
		BetterFriendlistDB.theme = theme
		BetterFriendlistDB.enableElvUISkin = theme == "elvui"
	end

	InvalidateEffectiveThemeCache()
	self:ApplyCurrentTheme(reason or "set-theme")
end

function ThemeManager:ApplyCurrentTheme(reason)
	InvalidateEffectiveThemeCache()
	local theme = BFL:GetEffectiveTheme()

	if InCombatLockdown and InCombatLockdown() then
		self.pendingThemeApply = true
		self.pendingThemeReason = reason or "combat"
		return false
	end

	self.pendingThemeApply = nil
	self.pendingThemeReason = nil

	local DarkTheme = BFL:GetModule("DarkTheme")
	if DarkTheme then
		if BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
			DarkTheme:Apply(reason)
		else
			DarkTheme:Remove(reason)
		end
	end

	local ThemePalette = BFL:GetModule("ThemePalette")
	if ThemePalette and ThemePalette.ApplyAvatarVisibility then
		ThemePalette:ApplyAvatarVisibility()
	end

	if BFL.ApplyTabFonts then
		BFL:ApplyTabFonts()
	end
	if theme == "blizzard" and BFL.RefreshMainTabVisualState then
		BFL:RefreshMainTabVisualState()
	end
	if theme == "blizzard" then
		local Settings = BFL:GetModule("Settings")
		if Settings and Settings.RefreshCategoryVisualState then
			Settings:RefreshCategoryVisualState()
		end
	end

	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
	RefreshClassicBlizzardPortraitVisibility(reason or "theme-manager")

	local Changelog = BFL:GetModule("Changelog")
	if Changelog and Changelog.RefreshAccentColors then
		Changelog:RefreshAccentColors()
	end
	if BFL.HelpFrame and BFL.HelpFrame.RefreshAccentColors then
		BFL.HelpFrame:RefreshAccentColors()
	end
	local RaidTools = BFL:GetModule("RaidTools")
	if RaidTools and RaidTools.RefreshAccentColors then
		RaidTools:RefreshAccentColors()
	end
	local GuildFrame = BFL:GetModule("GuildFrame")
	if GuildFrame and GuildFrame.RefreshMemberInfoPanelAccent then
		GuildFrame:RefreshMemberInfoPanelAccent()
	end
	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame and WhoFrame.RefreshAccentColors then
		WhoFrame:RefreshAccentColors()
	end
	local SettingsDesigner = BFL:GetModule("SettingsDesigner")
	if SettingsDesigner and SettingsDesigner.ApplySkin then
		SettingsDesigner:ApplySkin(reason or "theme-manager")
	end

	local ElvUISkin = BFL:GetModule("ElvUISkin")
	local friendsUITheme = theme
	if ElvUISkin then
		local useElvUISkin = (ElvUISkin.IsSkinEnabled and ElvUISkin:IsSkinEnabled()) or theme == "elvui"
		if useElvUISkin and ElvUISkin.RegisterSkin then
			friendsUITheme = "elvui"
			ElvUISkin:RegisterSkin()
		elseif ElvUISkin.HideClassicMainFrameShell then
			ElvUISkin:HideClassicMainFrameShell()
		end
	end

	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.ApplyTheme then
		FriendsUI:ApplyTheme(friendsUITheme)
	end
	local tagEditor = BFL:GetModule("FriendTagEditor")
	if tagEditor then tagEditor:RefreshAppearance() end
	local iconSelector = BFL:GetModule("IconSelector")
	if iconSelector then iconSelector:RefreshAppearance() end
	local FeatureHints = BFL:GetModule("FeatureHints")
	if FeatureHints and FeatureHints.RefreshAppearance then
		FeatureHints:RefreshAppearance()
	end
	local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
	if theme == "ellesmereui" and EllesmereUISkin and EllesmereUISkin.Apply then
		EllesmereUISkin:Apply(reason or "theme-manager")
	end
	local IgnoreList = BFL:GetModule("IgnoreList")
	local ignoreWindow = _G.BetterFriendsFrame and _G.BetterFriendsFrame.IgnoreListWindow
	if IgnoreList and IgnoreList.ApplyTheme and ignoreWindow and ignoreWindow:IsShown() then
		IgnoreList:ApplyTheme(ignoreWindow)
	end
	local AppearanceOnboarding = BFL:GetModule("AppearanceOnboarding")
	if AppearanceOnboarding and AppearanceOnboarding.ApplySkin then
		AppearanceOnboarding:ApplySkin(reason or "theme-manager")
	end
	local dialogs = BFL:GetModule("Dialogs")
	if dialogs and dialogs.RefreshInputDialogTheme then dialogs:RefreshInputDialogTheme() end
	if theme == "blizzard" then
		-- DarkTheme restores registered controls before module-specific theme and
		-- layout refreshes run. Finalize native button atlases afterwards so no
		-- later owner/state update can leave a partial ThreeSlice or stale font.
		local SkinEngine = BFL:GetModule("SkinEngine")
		if SkinEngine and SkinEngine.FinalizeNativeButtonRestore then
			SkinEngine:FinalizeNativeButtonRestore()
		end
	end

	local scrollbarStyle = BFL:GetModule("ScrollbarStyle")
	if scrollbarStyle then scrollbarStyle:Refresh() end
	return true
end

function ThemeManager:InvalidateEffectiveTheme()
	InvalidateEffectiveThemeCache()
end

function ThemeManager:ApplyPendingTheme()
	if not self.pendingThemeApply then
		return
	end
	self:ApplyCurrentTheme(self.pendingThemeReason or "combat-ended")
end

function ThemeManager:ShowReloadDialog(options)
	options = type(options) == "table" and options or nil
	local onReloadAccepted = options and options.onReloadAccepted
	local onReloadCancelled = options and options.onReloadCancelled
	local L = BFL.L or _G.BFL_L
	StaticPopupDialogs["BFL_EXTERNAL_THEME_RELOAD"] = {
		text = (L and L.SETTINGS_CENTER_RELOAD_REQUIRED)
			or "This change requires a UI reload.\n\nReload now?",
		button1 = (L and L.DIALOG_UI_PANEL_RELOAD_BTN1) or "Reload",
		button2 = (L and L.DIALOG_UI_PANEL_RELOAD_BTN2) or "Cancel",
		OnAccept = function()
			if onReloadAccepted then
				onReloadAccepted()
			end
			ReloadUI()
		end,
		OnCancel = function()
			if onReloadCancelled then
				onReloadCancelled()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	return StaticPopup_Show("BFL_EXTERNAL_THEME_RELOAD")
end

-- Blizzard StaticPopup slots are shared. Only Dialogs-owned frames are themed.

return ThemeManager
