-- Modules/ThemeManager.lua
-- Theme selection and application orchestration for BetterFriendlist

local ADDON_NAME, BFL = ...
local ThemeManager = BFL:RegisterModule("ThemeManager", {})

local VALID_THEMES = {
	blizzard = true,
	dark = true,
	elvui = true,
}

BFL.THEMES = {
	BLIZZARD = "blizzard",
	DARK = "dark",
	ELVUI = "elvui",
}

local function NormalizeTheme(theme)
	if VALID_THEMES[theme] then
		return theme
	end
	return "blizzard"
end

local function AreThemeFeaturesEnabled()
	return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

local function GetStoredTheme()
	if not BetterFriendlistDB then
		return "blizzard"
	end

	if BetterFriendlistDB.theme == nil then
		return BetterFriendlistDB.enableElvUISkin == true and "elvui" or "blizzard"
	end

	return NormalizeTheme(BetterFriendlistDB.theme)
end

function BFL:AreThemeFeaturesEnabled()
	return AreThemeFeaturesEnabled()
end

function BFL:GetEffectiveTheme()
	local theme = GetStoredTheme()
	if theme ~= "blizzard" and not AreThemeFeaturesEnabled() then
		return "blizzard"
	end
	if theme == "elvui" and (not BFL.IsElvUIAvailable or not BFL:IsElvUIAvailable()) then
		return "blizzard"
	end
	return theme
end

function BFL:IsThemeActive(theme)
	return self:GetEffectiveTheme() == NormalizeTheme(theme)
end

function BFL:UsesFlatTheme()
	local theme = self:GetEffectiveTheme()
	return theme == "dark" or theme == "elvui"
end

function ThemeManager:Initialize()
	if not self.eventCallbacksRegistered then
		self.eventCallbacksRegistered = true
		BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
			self:ApplyPendingTheme()
		end, 80)
	end

	self:InstallStaticPopupHook()
	self:ApplyCurrentTheme("initialize")
end

function ThemeManager:OnPlayerLogin()
	self:ApplyCurrentTheme("player-login")
end

function ThemeManager:IsValidTheme(theme)
	return VALID_THEMES[theme] == true
end

function ThemeManager:GetStoredTheme()
	return GetStoredTheme()
end

function ThemeManager:GetEffectiveTheme()
	return BFL:GetEffectiveTheme()
end

function ThemeManager:SetTheme(theme, reason)
	theme = NormalizeTheme(theme)
	if theme ~= "blizzard" and not AreThemeFeaturesEnabled() then
		theme = "blizzard"
	end

	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("theme", theme)
	elseif BetterFriendlistDB then
		BetterFriendlistDB.theme = theme
	end

	self:ApplyCurrentTheme(reason or "set-theme")
end

function ThemeManager:ApplyCurrentTheme(reason)
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
		if theme == "dark" then
			DarkTheme:Apply(reason)
		else
			DarkTheme:Remove(reason)
		end
	end

	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end

	return true
end

function ThemeManager:ApplyPendingTheme()
	if not self.pendingThemeApply then
		return
	end
	self:ApplyCurrentTheme(self.pendingThemeReason or "combat-ended")
end

function ThemeManager:ShowReloadDialog()
	local L = BFL.L or _G.BFL_L
	StaticPopupDialogs["BFL_ELVUI_RELOAD"] = {
		text = (L and L.DIALOG_ELVUI_RELOAD_TEXT) or "Changing ElvUI Skin settings requires a UI Reload.\nReload now?",
		button1 = (L and L.DIALOG_ELVUI_RELOAD_BTN1) or "Yes",
		button2 = (L and L.DIALOG_ELVUI_RELOAD_BTN2) or "No",
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("BFL_ELVUI_RELOAD")
end

local function IsBetterFriendlistPopup(which)
	if type(which) ~= "string" then
		return false
	end

	return which:sub(1, 4) == "BFL_"
		or which:sub(1, 18) == "BETTER_FRIENDLIST"
		or which:sub(1, 16) == "BETTERFRIENDLIST"
end

function ThemeManager:SkinStaticPopup(which)
	if not IsBetterFriendlistPopup(which) or not BFL:IsThemeActive("dark") then
		return
	end

	local Engine = BFL:GetModule("SkinEngine")
	if not Engine then
		return
	end

	for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
		local popup = _G["StaticPopup" .. i]
		if popup and popup:IsShown() and popup.which == which then
			Engine:SkinFrame(popup, "popup")
			Engine:SkinTree(popup, 3)
		end
	end
end

function ThemeManager:InstallStaticPopupHook()
	if self.staticPopupHooked or not hooksecurefunc or not StaticPopup_Show then
		return
	end

	self.staticPopupHooked = true
	hooksecurefunc("StaticPopup_Show", function(which)
		if not IsBetterFriendlistPopup(which) or not BFL:IsThemeActive("dark") then
			return
		end

		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				self:SkinStaticPopup(which)
			end)
		else
			self:SkinStaticPopup(which)
		end
	end)
end

return ThemeManager
