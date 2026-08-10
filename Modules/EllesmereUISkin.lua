-- Modules/EllesmereUISkin.lua
-- EllesmereUI theme integration through the public third-party skinning API.

local ADDON_NAME, BFL = ...
local EllesmereUISkin = BFL:RegisterModule("EllesmereUISkin", {})

local THEME_ID = "ellesmereui"
local SKIN_REGISTRATION_NAME = "BetterFriendlist"
local EUI_FRIENDS_BACKGROUND = { 0.03, 0.045, 0.05, 1 }
local EUI_FRIENDS_ROW = { 0, 0, 0, 0.10 }
local EUI_FRIENDS_HOVER = { 1, 1, 1, 0.035 }
local EUI_BATTLENET_TEXT = { 0.26, 0.68, 0.94, 1 }

local function SafeCall(api, method, ...)
	local callback = api and api[method]
	if type(callback) ~= "function" then
		return false
	end
	return pcall(callback, ...)
end

local function IsForbidden(frame)
	if not frame or not frame.IsForbidden then
		return false
	end
	local ok, forbidden = pcall(frame.IsForbidden, frame)
	return ok and forbidden == true
end

local function GetObjectType(frame)
	if not frame or not frame.GetObjectType then
		return nil
	end
	local ok, objectType = pcall(frame.GetObjectType, frame)
	return ok and objectType or nil
end

local function GetName(frame)
	if not frame or not frame.GetName then
		return ""
	end
	local ok, name = pcall(frame.GetName, frame)
	return ok and type(name) == "string" and name or ""
end

local function HasFontString(button)
	if not button or not button.GetFontString then
		return false
	end
	local ok, fontString = pcall(button.GetFontString, button)
	return ok and fontString ~= nil
end

local function LooksLikeDropdown(frame, name)
	if BFL.IsModernDropdown and BFL.IsModernDropdown(frame) then
		return true
	end
	name = name or GetName(frame)
	return name:find("Dropdown", 1, true) ~= nil
		or name:find("DropDown", 1, true) ~= nil
		or (frame and frame.Button and (frame.Text or frame.SelectionText or frame.Arrow))
end

local function LooksLikeScrollBar(frame, name)
	name = name or GetName(frame)
	return name:find("ScrollBar", 1, true) ~= nil
		or (frame and (frame.ThumbTexture or frame.ScrollUpButton or frame.ScrollDownButton))
end

local function LooksLikeTab(frame, name)
	name = name or GetName(frame)
	return name:find("BetterFriendsFrameTab", 1, true) ~= nil
		or name:find("BetterFriendsFrameBottomTab", 1, true) ~= nil
		or name:find("BetterFriendlistSettingsFrameTab", 1, true) ~= nil
end

local function LooksLikeCloseButton(frame, name)
	name = name or GetName(frame)
	return name:find("CloseButton", 1, true) ~= nil or name:find("Close", 1, true) ~= nil
end

local function SkinWidget(api, frame)
	if not api or not frame or IsForbidden(frame) then
		return
	end

	local objectType = GetObjectType(frame)
	local name = GetName(frame)
	if LooksLikeScrollBar(frame, name) then
		SafeCall(api, "ScrollBar", frame)
	elseif objectType == "EditBox" then
		SafeCall(api, "EditBox", frame)
	elseif objectType == "CheckButton" then
		SafeCall(api, "Checkbox", frame)
	elseif objectType == "StatusBar" then
		SafeCall(api, "ApplyBarFill", frame)
	elseif LooksLikeDropdown(frame, name) then
		SafeCall(api, "Dropdown", frame)
	elseif objectType == "Button" and LooksLikeTab(frame, name) then
		SafeCall(api, "Tab", frame)
	elseif objectType == "Button" and LooksLikeCloseButton(frame, name) then
		SafeCall(api, "CloseButton", frame)
	elseif objectType == "Button" and HasFontString(frame) then
		-- Friend, guild, raid, and directory rows use child FontStrings instead
		-- of a button label. Restrict the generic pass to actual controls so the
		-- EUI button primitive never paints list-row hit targets.
		SafeCall(api, "Button", frame)
		SafeCall(api, "StateButtonLabel", frame)
	end
end

local function SkinWidgetTree(api, root, maxDepth, currentDepth, visited)
	if not root or IsForbidden(root) then
		return
	end
	currentDepth = currentDepth or 0
	maxDepth = maxDepth or 6
	visited = visited or setmetatable({}, { __mode = "k" })
	if visited[root] or currentDepth > maxDepth then
		return
	end
	visited[root] = true

	SkinWidget(api, root)
	if not root.GetChildren then
		return
	end
	local children = { root:GetChildren() }
	for _, child in ipairs(children) do
		SkinWidgetTree(api, child, maxDepth, currentDepth + 1, visited)
	end
end

local function IsBFLPopup(which)
	return type(which) == "string"
		and (
			which:sub(1, 4) == "BFL_"
			or which:sub(1, 18) == "BETTER_FRIENDLIST"
			or which:sub(1, 16) == "BETTERFRIENDLIST"
		)
end

local function Color(r, g, b, a)
	return { r or 0, g or 0, b or 0, a ~= nil and a or 1 }
end

function EllesmereUISkin:IsAvailable()
	local api = self.facade
	if type(api) ~= "table" or tonumber(api.apiVersion) == nil or tonumber(api.apiVersion) < 1 then
		return false
	end
	-- EUI can enable a third-party skin live, but removal is explicitly
	-- reload-bound. Once the facade was dispatched, keep the theme available
	-- for this session so BFL does not restore Blizzard surfaces underneath an
	-- EUI shell while the user is still waiting for that reload.
	return self.facadeActivated == true
end

function EllesmereUISkin:IsSkinEnabled()
	return self:IsAvailable() and BFL.IsThemeActive and BFL:IsThemeActive(THEME_ID)
end

function EllesmereUISkin:GetPaletteVersion()
	return self.paletteVersion or 0
end

function EllesmereUISkin:GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	local api = self.facade
	if self:IsAvailable() and type(api.GetAccentColor) == "function" then
		local ok, r, g, b = pcall(api.GetAccentColor)
		if ok and tonumber(r) and tonumber(g) and tonumber(b) then
			return r, g, b, fallbackA ~= nil and fallbackA or 1
		end
	end
	return fallbackR or 0.047, fallbackG or 0.824, fallbackB or 0.616, fallbackA ~= nil and fallbackA or 1
end

function EllesmereUISkin:GetPanelColor(fallbackR, fallbackG, fallbackB, fallbackA)
	local api = self.facade
	if self:IsAvailable() and type(api.GetPanelColor) == "function" then
		local ok, r, g, b, a = pcall(api.GetPanelColor)
		if ok and tonumber(r) and tonumber(g) and tonumber(b) then
			return r, g, b, tonumber(a) or fallbackA or 0.94
		end
	end
	return fallbackR or 0.035, fallbackG or 0.035, fallbackB or 0.04, fallbackA or 0.94
end

function EllesmereUISkin:GetPalette()
	local panelR, panelG, panelB, panelA = self:GetPanelColor()
	local accentR, accentG, accentB = self:GetAccentColor()
	local panel = Color(panelR, panelG, panelB, panelA)
	local accent = Color(accentR, accentG, accentB, 0.90)
	local border = { 1, 1, 1, 0.14 }

	return {
		-- EUI owns the actual window shell. BFL's Modern textures are only
		-- translucent content washes so the selected EUI shell style remains
		-- visible instead of being covered by a second opaque skin.
		background = Color(
			EUI_FRIENDS_BACKGROUND[1],
			EUI_FRIENDS_BACKGROUND[2],
			EUI_FRIENDS_BACKGROUND[3],
			0.30
		),
		surface = Color(0, 0, 0, 0.12),
		inset = Color(0, 0, 0, 0.16),
		control = Color(panelR, panelG, panelB, math.max(panelA or 0.94, 0.94)),
		border = border,
		accent = accent,
		text = { 0.90, 0.90, 0.90, 1 },
		disabledText = { 0.50, 0.50, 0.50, 0.88 },
		hover = Color(1, 1, 1, 0.05),
		selected = Color(accentR, accentG, accentB, 0.12),
		scrollThumb = { 1, 1, 1, 0.40 },
		icon = Color(accentR, accentG, accentB, 0.95),
		battleTagText = EUI_BATTLENET_TEXT,
		externalShell = true,
		externalControls = true,
		skinFriendCardSurface = true,
		preserveNativeSideTabs = true,
		preserveNativeGroupHeaders = true,
		preserveNativeInviteButtons = true,
		transparentBattleNetBar = true,
		portraitOffsetX = 8,
		portraitOffsetY = -31,
		portraitSize = 42,
		customTabInactiveMultiplier = 0.68,
		panel = panel,
		panelSoft = Color(0, 0, 0, 0.12),
		controlHover = Color(1, 1, 1, 0.05),
		rowHover = EUI_FRIENDS_HOVER,
		rowDown = Color(accentR, accentG, accentB, 0.12),
		borderSoft = { 1, 1, 1, 0.12 },
		borderMuted = { 1, 1, 1, 0.08 },
		borderHover = accent,
		controlBorder = { 1, 1, 1, 0.25 },
		divider = { 1, 1, 1, 0.08 },
	}
end

function EllesmereUISkin:SkinModernFriendCard(button)
	if not self:IsSkinEnabled() or not button then
		return
	end

	-- EUIFriends uses a restrained 10% black tile rather than Blizzard's
	-- sculpted friends-card atlas. Exchange only the visible surface and hover
	-- treatment; BFL continues to own row geometry, fonts, and action buttons.
	if button.CardBackground then
		button.CardBackground:SetAlpha(0)
	end
	if button.ThemeTint then
		button.ThemeTint:Hide()
	end
	if button.background and button.background.SetColorTexture then
		button.background:SetColorTexture(unpack(EUI_FRIENDS_ROW))
		button.background:Show()
	end
	local highlight = button.highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
	if highlight and highlight.SetColorTexture then
		highlight:SetColorTexture(unpack(EUI_FRIENDS_HOVER))
		highlight:SetDesaturated(false)
		highlight:SetVertexColor(1, 1, 1, 1)
		highlight:SetAlpha(1)
	end
end

local function HideNativeButtonChrome(button)
	if not button then
		return
	end
	for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
		local callback = button[getter]
		local texture = callback and callback(button)
		if texture and texture.SetAlpha then
			texture:SetAlpha(0)
		end
	end
	-- Retail's SharedButtonTemplate calls its middle slice "Center" while the
	-- public EUI primitive also supports the older "Middle" name. Suppress both
	-- on every state transition so Blizzard cannot repaint red atlas slices over
	-- the EUI button after the facade's idempotent first pass.
	for _, key in ipairs({
		"Left",
		"Middle",
		"Center",
		"Right",
		"LeftSeparator",
		"RightSeparator",
		"NormalTexture",
		"PushedTexture",
		"DisabledTexture",
		"HighlightTexture",
	}) do
		local texture = button[key]
		if texture and texture.SetAlpha then
			texture:SetAlpha(0)
		end
	end
end

function EllesmereUISkin:SkinActionButton(button, keepKeys)
	if not self:IsSkinEnabled() or not button then
		return
	end
	SafeCall(self.facade, "Button", button, keepKeys)
	SafeCall(self.facade, "StateButtonLabel", button)
	HideNativeButtonChrome(button)
	if not button.BFL_EllesmereChromeHooks then
		button.BFL_EllesmereChromeHooks = true
		for _, event in ipairs({ "OnShow", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnEnable", "OnDisable" }) do
			button:HookScript(event, HideNativeButtonChrome)
		end
	end
end

function EllesmereUISkin:SkinFooterActionButton(button)
	self:SkinActionButton(button)
end

function EllesmereUISkin:SkinModernChrome(frame, FriendsUI)
	if not self:IsSkinEnabled() or not frame or not FriendsUI then
		return
	end
	local api = self.facade
	local root = FriendsUI.root
	local header = frame.FriendsTabHeader
	if not root then
		return
	end

	SafeCall(api, "Dropdown", header and header.StatusDropdown)
	SafeCall(api, "EditBox", header and header.SearchBox)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.FilterDropdown)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.RecentFilterDropdown)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.SortButton)
	SafeCall(api, "Button", root.BattleNetBar and root.BattleNetBar.MenuButton, { "Icon" })
	self:SkinFooterActionButton(root.BottomActionBar and root.BottomActionBar.AddFriendButton)

	-- Keep the EUI pass intentionally allowlisted. These are the visible RAF,
	-- Raid, and Who action controls requested by the integration; row hit targets,
	-- group headers, invite buttons, and side-tab backgrounds remain native.
	local raf = frame.RecruitAFriendFrame
	local raid = frame.RaidFrame
	local raidControl = raid and raid.ControlPanel
	local who = frame.WhoFrame
	self:SkinActionButton(frame.RecruitmentButton)
	self:SkinActionButton(raf and raf.RewardClaiming and raf.RewardClaiming.ClaimOrViewRewardButton)
	self:SkinActionButton(raidControl and raidControl.RaidInfoButton)
	self:SkinActionButton(raidControl and raidControl.ReadyCheckButton, { "Icon" })
	self:SkinActionButton(raid and raid.RaidToolsButton)
	self:SkinActionButton(raid and raid.ConvertToRaidButton)
	self:SkinActionButton(who and who.WhoButton)
	self:SkinActionButton(who and who.AddFriendButton)
	self:SkinActionButton(who and who.GroupInviteButton)
	SafeCall(api, "ScrollBar", frame.MinimalScrollBar)
	SafeCall(api, "ScrollBar", root.RequestsFrame and root.RequestsFrame.ScrollBar)
end

function EllesmereUISkin:SkinSettingsCenter(frame)
	local api = self.facade
	if not self:IsSkinEnabled() or not frame then
		return
	end
	SafeCall(api, "Shell", frame)
	SafeCall(api, "Panel", frame.TopBar, { noBorder = true })
	SafeCall(api, "Panel", frame.Sidebar, { inset = true })
	SafeCall(api, "Panel", frame.ContentShell, { inset = true })
	SafeCall(api, "EditBox", frame.SearchBox)
	SafeCall(api, "Button", frame.ResetButton)
	SafeCall(api, "Button", frame.LockButton)
	SafeCall(api, "Button", frame.DensityButton)
end

function EllesmereUISkin:SkinTooltip(tooltip)
	if not self:IsSkinEnabled() or not tooltip then
		return
	end
	SafeCall(self.facade, "Panel", tooltip, { inset = true })
	tooltip.bflEllesmereUISkinned = true
end

function EllesmereUISkin:SkinStaticPopups()
	if not self:IsSkinEnabled() then
		return
	end
	for index = 1, STATICPOPUP_NUMDIALOGS or 4 do
		local popup = _G["StaticPopup" .. index]
		if popup and popup.IsShown and popup:IsShown() and IsBFLPopup(popup.which) then
			SafeCall(self.facade, "Panel", popup)
			SkinWidgetTree(self.facade, popup, 3)
		end
	end
end

function EllesmereUISkin:SkinLegacySettings()
	local frame = _G.BetterFriendlistSettingsFrame
	if not self:IsSkinEnabled() or not frame then
		return
	end
	SafeCall(self.facade, "Shell", frame)
	for index = 1, 10 do
		SafeCall(self.facade, "Tab", _G["BetterFriendlistSettingsFrameTab" .. index])
	end
	SkinWidgetTree(self.facade, frame, 6)
end

function EllesmereUISkin:SkinAuxiliaryWindows()
	if not self:IsSkinEnabled() then
		return
	end
	for _, frameName in ipairs({
		"BetterFriendlistChangelogFrame",
		"BetterFriendlistHelpFrame",
		"BetterFriendlistExportFrame",
		"BetterFriendlistImportFrame",
		"BetterFriendlistNoteCleanupWizard",
		"BetterFriendlistNoteBackupViewer",
		"BetterFriendlistRaidToolsFrame",
		"BetterSavedInstancesFrame",
	}) do
		local frame = _G[frameName]
		SafeCall(self.facade, "Shell", frame)
		SkinWidgetTree(self.facade, frame, 7)
	end

	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
		SafeCall(self.facade, "Panel", WhoFrame.builderFlyout)
		SafeCall(self.facade, "Panel", WhoFrame.builderDockedContainer, { inset = true })
		SkinWidgetTree(self.facade, WhoFrame.builderFlyout, 5)
		SkinWidgetTree(self.facade, WhoFrame.builderDockedContainer, 5)
	end
end

function EllesmereUISkin:SkinMainFrame()
	local frame = _G.BetterFriendsFrame
	if not self:IsSkinEnabled() or not frame then
		return
	end
	local api = self.facade
	SafeCall(api, "Shell", frame, { bottomBar = 80, noBorder = true })
	SafeCall(api, "Inset", frame.Inset)
	SafeCall(api, "CloseButton", frame.CloseButton)
	for index = 1, 4 do
		SafeCall(api, "Tab", _G["BetterFriendsFrameTab" .. index])
		SafeCall(api, "Tab", _G["BetterFriendsFrameBottomTab" .. index])
	end

	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")

	local who = frame.WhoFrame
	local guild = frame.GuildFrame
	local raid = frame.RaidFrame
	local quickJoin = frame.QuickJoinFrame
	SafeCall(api, "Inset", who and who.ListInset)
	SafeCall(api, "Inset", guild and guild.ListInset)
	SafeCall(api, "Inset", raid and raid.GroupsInset)
	SafeCall(api, "Inset", quickJoin and quickJoin.ContentInset)
	self:SkinModernChrome(frame, FriendsUI)
end

function EllesmereUISkin:Apply(reason)
	if not self:IsSkinEnabled() then
		return false
	end
	self.lastApplyReason = reason
	self:SkinMainFrame()
	self:SkinLegacySettings()
	self:SkinAuxiliaryWindows()
	local SettingsDesigner = BFL:GetModule("SettingsDesigner")
	if SettingsDesigner and SettingsDesigner.GetFrame then
		self:SkinSettingsCenter(SettingsDesigner:GetFrame())
	end
	self:SkinStaticPopups()
	return true
end

function EllesmereUISkin:ScheduleApply(reason)
	if self.applyScheduled then
		return
	end
	self.applyScheduled = true
	local function ApplyScheduled()
		self.applyScheduled = nil
		self:Apply(reason or "deferred")
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, ApplyScheduled)
	else
		ApplyScheduled()
	end
end

function EllesmereUISkin:OnLooksChanged()
	self.paletteVersion = (self.paletteVersion or 0) + 1
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI then
		FriendsUI.modernThemeColors = nil
		FriendsUI.modernThemeColorsTheme = nil
		FriendsUI.modernThemeColorsVersion = nil
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme("ellesmereui-looks-changed")
	end
end

function EllesmereUISkin:OnFacadeReady(api)
	if type(api) ~= "table" or tonumber(api.apiVersion) == nil or tonumber(api.apiVersion) < 1 then
		return
	end
	if type(api.IsEnabled) ~= "function" then
		return
	end
	local enabledOK, enabled = pcall(api.IsEnabled)
	if not enabledOK or enabled ~= true then
		return
	end
	self.facade = api
	self.facadeActivated = true
	self.paletteVersion = (self.paletteVersion or 0) + 1
	self:InstallHooks()
	if not self.looksCallbackRegistered and type(api.OnLooksChanged) == "function" then
		self.looksCallbackRegistered = true
		SafeCall(api, "OnLooksChanged", function()
			self:OnLooksChanged()
		end)
	end

	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.RefreshThemeTab then
		Settings:RefreshThemeTab()
	end
	local SettingsDesigner = BFL:GetModule("SettingsDesigner")
	if SettingsDesigner and SettingsDesigner.RefreshThemeAvailability then
		SettingsDesigner:RefreshThemeAvailability()
	end

	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme("ellesmereui-api-ready")
	end
end

function EllesmereUISkin:RegisterWithEllesmereUI()
	if self.registrationAttempted then
		return self.registrationSucceeded == true
	end
	self.registrationAttempted = true
	local eui = _G.EllesmereUI
	if type(eui) ~= "table" or type(eui.RegisterSkin) ~= "function" then
		return false
	end
	local ok = pcall(eui.RegisterSkin, SKIN_REGISTRATION_NAME, function(api)
		self:OnFacadeReady(api)
	end)
	self.registrationSucceeded = ok == true
	return self.registrationSucceeded
end

function EllesmereUISkin:InstallHooks()
	if self.hooksInstalled or not hooksecurefunc then
		return
	end
	self.hooksInstalled = true

	local function HookObject(object, label, methodName)
		if object and type(object[methodName]) == "function" then
			hooksecurefunc(object, methodName, function()
				self:ScheduleApply(label .. ":" .. methodName)
			end)
		end
	end

	HookObject(BFL:GetModule("FriendsUI"), "FriendsUI", "ApplyModernContentLayout")
	HookObject(BFL:GetModule("FriendsUI"), "FriendsUI", "RefreshModernSideTabSelection")
	HookObject(BFL:GetModule("Changelog"), "Changelog", "CreateChangelogWindow")
	HookObject(BFL.HelpFrame, "HelpFrame", "CreateFrame")
	HookObject(BFL:GetModule("Settings"), "Settings", "CreateExportFrame")
	HookObject(BFL:GetModule("Settings"), "Settings", "CreateImportFrame")
	HookObject(BFL.NoteCleanupWizard, "NoteCleanupWizard", "CreateWizardFrame")
	HookObject(BFL.NoteCleanupWizard, "NoteCleanupWizard", "CreateBackupViewerFrame")
	HookObject(BFL:GetModule("RaidTools"), "RaidTools", "CreateFrame")
	HookObject(BFL:GetModule("WhoFrame"), "WhoFrame", "CreateSearchBuilder")
	HookObject(BFL:GetModule("WhoFrame"), "WhoFrame", "ToggleSearchBuilder")

	if _G.BetterFriendsFrame and _G.BetterFriendsFrame.HookScript then
		_G.BetterFriendsFrame:HookScript("OnShow", function()
			self:ScheduleApply("main-frame-show")
		end)
	end
	if _G.BetterFriendlistSettingsFrame and _G.BetterFriendlistSettingsFrame.HookScript then
		_G.BetterFriendlistSettingsFrame:HookScript("OnShow", function()
			self:ScheduleApply("legacy-settings-show")
		end)
	end
	if type(_G.StaticPopup_Show) == "function" then
		hooksecurefunc("StaticPopup_Show", function(which)
			if IsBFLPopup(which) then
				self:ScheduleApply("static-popup")
			end
		end)
	end
end

function EllesmereUISkin:Initialize()
	self.paletteVersion = self.paletteVersion or 0
	self:RegisterWithEllesmereUI()
end

function EllesmereUISkin:OnPlayerLogin()
	self:ScheduleApply("player-login")
end

function BFL:IsEllesmereUIAvailable()
	local skin = self.GetModule and self:GetModule("EllesmereUISkin")
	return skin and skin.IsAvailable and skin:IsAvailable() == true or false
end

return EllesmereUISkin
