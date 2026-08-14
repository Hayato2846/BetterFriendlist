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
local BFL_PORTRAIT_TEXTURE = "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon"
local EUI_PORTRAIT_OFFSET_X = 6
local EUI_PORTRAIT_OFFSET_Y = -25
local EUI_PORTRAIT_SIZE = 42
local EUI_LEGACY_PORTRAIT_OFFSET_X = 15
local EUI_LEGACY_PORTRAIT_OFFSET_Y = -21
local EUI_LEGACY_PORTRAIT_SIZE = 34
local LEGACY_SETTINGS_REFRESH_METHODS = {
	"RefreshThemeTab",
	"RefreshFriendTabsTab",
	"RefreshGeneralTab",
	"RefreshContactMemoryTab",
	"RefreshFriendTagsTab",
	"RefreshGuildTab",
	"RefreshFontsTab",
	"RefreshGroupsTab",
	"RefreshAdvancedTab",
	"RefreshFilterSortTab",
	"RefreshBrokerTab",
	"RefreshGlobalSyncTab",
	"RefreshStreamerTab",
	"RefreshRaidTab",
	"RefreshWhoTab",
}

local function SafeCall(api, method, ...)
	local callback = api and api[method]
	if type(callback) ~= "function" then
		return false
	end
	return pcall(callback, ...)
end

local function RefreshCheckboxAccent(api, checkbox)
	if not checkbox then
		return
	end
	local r, g, b = 0.047, 0.824, 0.616
	if api and type(api.GetAccentColor) == "function" then
		local ok, accentR, accentG, accentB = pcall(api.GetAccentColor)
		if ok and tonumber(accentR) and tonumber(accentG) and tonumber(accentB) then
			r, g, b = accentR, accentG, accentB
		end
	end
	for _, texture in ipairs({
		checkbox.GetCheckedTexture and checkbox:GetCheckedTexture(),
		checkbox.GetDisabledCheckedTexture and checkbox:GetDisabledCheckedTexture(),
	}) do
		if texture.SetDesaturated then
			texture:SetDesaturated(true)
		end
		if texture.SetVertexColor then
			texture:SetVertexColor(r, g, b, 1)
		end
	end
end

local function SkinCheckbox(api, checkbox)
	if not checkbox then
		return
	end
	SafeCall(api, "Checkbox", checkbox)
	RefreshCheckboxAccent(api, checkbox)
	if not checkbox.BFL_EllesmereAccentCheckHooks and checkbox.HookScript then
		checkbox.BFL_EllesmereAccentCheckHooks = true
		local function RefreshAccent()
			RefreshCheckboxAccent(api, checkbox)
		end
		for _, event in ipairs({ "OnShow", "OnClick", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }) do
			checkbox:HookScript(event, RefreshAccent)
		end
	end
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

local function GetFontString(button)
	if not button or not button.GetFontString then
		return nil
	end
	local ok, fontString = pcall(button.GetFontString, button)
	return ok and fontString or nil
end

local function HideNativeTabLabel(tab)
	local label = tab and (tab.Text or GetFontString(tab))
	if label and label.SetAlpha then
		label:SetAlpha(0)
	end
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
	if objectType == "EditBox" then
		SafeCall(api, "EditBox", frame)
	elseif objectType == "CheckButton" then
		SkinCheckbox(api, frame)
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
		headerControlOffsetY = 0,
		portraitOffsetX = EUI_PORTRAIT_OFFSET_X,
		portraitOffsetY = EUI_PORTRAIT_OFFSET_Y,
		portraitSize = EUI_PORTRAIT_SIZE,
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
	-- FriendsUI deliberately rebuilds the native card, faction, hover, and
	-- locked-selection layers for every recycled-row update. These four visual
	-- values therefore must remain a cheap dynamic pass; caching them by palette
	-- version leaves the native card visible as soon as the row is reused.
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
	-- Action controls are few and this function only runs in a coalesced frame
	-- skin pass. Let EUI's idempotent facade validate its owned surface each time;
	-- a palette/object marker cannot detect a native mixin rebuilding the same
	-- button's regions or an external skin removing its generated backdrop.
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

function EllesmereUISkin:IsModernInterfaceActive()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() == true or false
end

function EllesmereUISkin:ApplyAccentIcon(icon)
	if not icon then
		return
	end
	local r, g, b = self:GetAccentColor()
	if icon.SetDesaturated then
		icon:SetDesaturated(true)
	end
	if icon.SetVertexColor then
		icon:SetVertexColor(r, g, b, 1)
	end
	if icon.SetAlpha then
		icon:SetAlpha(1)
	end
end

function EllesmereUISkin:SkinCheckbox(checkbox)
	if not self:IsSkinEnabled() or not checkbox then
		return
	end
	SkinCheckbox(self.facade, checkbox)
end

function EllesmereUISkin:SkinIconButton(button)
	if not self:IsSkinEnabled() or not button then
		return
	end
	self:SkinActionButton(button, { "Icon" })
	self:ApplyAccentIcon(button.Icon)
	if not button.BFL_EllesmereAccentIconHooks and button.HookScript then
		button.BFL_EllesmereAccentIconHooks = true
		local function RefreshAccentIcon()
			self:ApplyAccentIcon(button.Icon)
		end
		for _, event in ipairs({ "OnShow", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnEnable", "OnDisable" }) do
			button:HookScript(event, RefreshAccentIcon)
		end
	end
end

function EllesmereUISkin:RefreshLegacyTabLabel(tab)
	if not self:IsSkinEnabled() or self:IsModernInterfaceActive() then
		return
	end
	HideNativeTabLabel(tab)
end

function EllesmereUISkin:SkinLegacyTab(tab)
	if not self:IsSkinEnabled() or not tab then
		return
	end
	SafeCall(self.facade, "Tab", tab)
	-- EUI creates its own label. BFL's font refresh can recolor the original
	-- Blizzard label afterwards, so keep that source label transparent instead
	-- of relying on the color chosen during the first skin pass.
	self:RefreshLegacyTabLabel(tab)
	if not tab.BFL_EllesmereNativeLabelHooks and tab.HookScript then
		tab.BFL_EllesmereNativeLabelHooks = true
		local function RefreshTabLabel()
			self:RefreshLegacyTabLabel(tab)
		end
		for _, event in ipairs({ "OnShow", "OnEnable", "OnDisable", "OnClick" }) do
			tab:HookScript(event, RefreshTabLabel)
		end
	end
end

function EllesmereUISkin:SkinLegacyPortrait(frame)
	local portraitButton = frame and frame.PortraitButton
	if not self:IsSkinEnabled() or not portraitButton or not portraitButton.CreateTexture then
		return
	end
	portraitButton:ClearAllPoints()
	portraitButton:SetPoint(
		"TOPLEFT",
		frame,
		"TOPLEFT",
		EUI_LEGACY_PORTRAIT_OFFSET_X,
		EUI_LEGACY_PORTRAIT_OFFSET_Y
	)
	portraitButton:SetSize(EUI_LEGACY_PORTRAIT_SIZE, EUI_LEGACY_PORTRAIT_SIZE)
	local icon = portraitButton.BFL_EllesmerePortraitIcon
	if not icon then
		-- EUI's Shell primitive intentionally fades direct textures on the main
		-- frame. Parent the themed copy to the portrait button so subsequent EUI
		-- shell refreshes cannot make the Legacy BFL logo disappear again.
		icon = portraitButton:CreateTexture(nil, "OVERLAY", nil, 7)
		portraitButton.BFL_EllesmerePortraitIcon = icon
		icon:SetTexture(BFL_PORTRAIT_TEXTURE)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", portraitButton, "TOPLEFT", 0, 0)
	icon:SetSize(EUI_LEGACY_PORTRAIT_SIZE, EUI_LEGACY_PORTRAIT_SIZE)
	if icon.SetDesaturated then
		icon:SetDesaturated(false)
	end
	if icon.SetVertexColor then
		icon:SetVertexColor(1, 1, 1, 1)
	end
	if icon.SetAlpha then
		icon:SetAlpha(1)
	end
	if icon.Show then
		icon:Show()
	end
end

function EllesmereUISkin:SetLegacyPortraitShown(frame, shown)
	local portraitButton = frame and frame.PortraitButton
	local icon = portraitButton and portraitButton.BFL_EllesmerePortraitIcon
	if icon and icon.SetShown then
		icon:SetShown(shown == true)
	elseif icon and shown and icon.Show then
		icon:Show()
	elseif icon and icon.Hide then
		icon:Hide()
	end
end

function EllesmereUISkin:SkinFooterActionButton(button)
	self:SkinActionButton(button)
end

function EllesmereUISkin:SkinRequestedActionControls(frame)
	if not self:IsSkinEnabled() or not frame then
		return
	end
	local raf = frame.RecruitAFriendFrame
	local raid = frame.RaidFrame
	local raidControl = raid and raid.ControlPanel
	local who = frame.WhoFrame

	self:SkinActionButton(frame.RecruitmentButton)
	self:SkinActionButton(raf and raf.RewardClaiming and raf.RewardClaiming.ClaimOrViewRewardButton)
	self:SkinActionButton(raidControl and raidControl.RaidInfoButton)
	self:SkinIconButton(raidControl and raidControl.ReadyCheckButton)
	self:SkinActionButton(raid and raid.RaidToolsButton)
	self:SkinActionButton(raid and raid.ConvertToRaidButton)
	self:SkinActionButton(who and who.WhoButton)
	self:SkinActionButton(who and who.AddFriendButton)
	self:SkinActionButton(who and who.GroupInviteButton)
end

function EllesmereUISkin:SkinTabSearchFields(frame)
	if not self:IsSkinEnabled() or not frame then
		return
	end
	local header = frame.FriendsTabHeader
	local guild = frame.GuildFrame
	local who = frame.WhoFrame
	SafeCall(self.facade, "EditBox", header and header.SearchBox)
	SafeCall(self.facade, "EditBox", guild and guild.SearchBox)
	SafeCall(self.facade, "EditBox", who and who.EditBox)
end

function EllesmereUISkin:SkinLegacyChrome(frame)
	if not self:IsSkinEnabled() or not frame or self:IsModernInterfaceActive() then
		return
	end
	local api = self.facade
	local header = frame.FriendsTabHeader
	local battleNet = header and header.BattlenetFrame
	local guild = frame.GuildFrame
	local who = frame.WhoFrame

	-- Legacy controls are deliberately allowlisted. List rows, group headers,
	-- scrollbars, and the native tab backgrounds are not traversed generically.
	self:SkinTabSearchFields(frame)
	SafeCall(api, "Dropdown", header and header.StatusDropdown)
	SafeCall(api, "Dropdown", header and header.QuickFilterDropdown)
	SafeCall(api, "Dropdown", header and header.PrimarySortDropdown)
	SafeCall(api, "Dropdown", header and header.SecondarySortDropdown)
	self:SkinIconButton(battleNet and battleNet.ContactsMenuButton)
	self:SkinIconButton(battleNet and battleNet.SettingsButton)

	self:SkinActionButton(frame.AddFriendButton)
	self:SkinActionButton(frame.SendMessageButton)
	self:SkinActionButton(guild and guild.ActionsButton)
	SafeCall(api, "Dropdown", who and who.ColumnDropdown)
	self:SkinRequestedActionControls(frame)
end

function EllesmereUISkin:SkinLegacyInviteButtons(button)
	if not self:IsSkinEnabled() or self:IsModernInterfaceActive() or not button then
		return
	end
	self:SkinActionButton(button.AcceptButton)
	self:SkinActionButton(button.DeclineButton)
end

function EllesmereUISkin:SkinModernChrome(frame, FriendsUI)
	if not self:IsSkinEnabled() or not frame or not FriendsUI then
		return
	end
	local api = self.facade
	local root = FriendsUI.root
	local header = frame.FriendsTabHeader
	local guild = frame.GuildFrame
	local who = frame.WhoFrame
	if not root then
		return
	end
	-- This pass is already coalesced by ScheduleMainFrameRefresh. Do not cache it
	-- by object identity: Blizzard restores template artwork and button state on
	-- the same control instances during tab changes and frame reopen.
	self:SkinTabSearchFields(frame)
	SafeCall(api, "Dropdown", header and header.StatusDropdown)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.FilterDropdown)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.RecentFilterDropdown)
	SafeCall(api, "Dropdown", root.FilterBar and root.FilterBar.SortButton)
	SafeCall(api, "Dropdown", guild and guild.FilterDropdown)
	SafeCall(api, "Dropdown", guild and guild.SortDropdown)
	SafeCall(api, "Dropdown", who and who.ColumnDropdown)
	SafeCall(api, "Button", root.BattleNetBar and root.BattleNetBar.MenuButton, { "Icon" })
	self:SkinFooterActionButton(root.BottomActionBar and root.BottomActionBar.AddFriendButton)
	self:SkinActionButton(
		root.RequestsFrame and root.RequestsFrame.RealIDWarning and root.RequestsFrame.RealIDWarning.ContinueButton
	)

	-- Keep the EUI pass intentionally allowlisted. Row hit targets, group
	-- headers, invite buttons, and side-tab backgrounds remain native in Modern.
	self:SkinRequestedActionControls(frame)
end

function EllesmereUISkin:RefreshMainFrame(reason, frame)
	if not self:IsSkinEnabled() then
		return false
	end
	self.lastApplyReason = reason
	self:SkinMainFrame(frame)
	return true
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
	self:SkinIgnoreListWindow(_G.BetterFriendsFrame and _G.BetterFriendsFrame.IgnoreListWindow)

	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
		SafeCall(self.facade, "Panel", WhoFrame.builderFlyout)
		SafeCall(self.facade, "Panel", WhoFrame.builderDockedContainer, { inset = true })
		SkinWidgetTree(self.facade, WhoFrame.builderFlyout, 5)
		SkinWidgetTree(self.facade, WhoFrame.builderDockedContainer, 5)
	end
end

function EllesmereUISkin:RefreshModernPortraitCorner(frame)
	if not self:IsSkinEnabled() or not frame or not self:IsModernInterfaceActive() then
		return false
	end
	-- PortraitFrameMixin rebuilds the top-left NineSlice when
	-- SetPortraitShown() runs. EUI's Shell primitive is intentionally
	-- idempotent and therefore does not re-fade that newly restored artwork on
	-- a cached shell. Use the dedicated visual-only primitive for this dynamic
	-- layer instead of rebuilding the entire shell and all of its controls.
	SafeCall(self.facade, "FadeNineSlice", frame.NineSlice)
	for _, region in ipairs({
		frame.portrait,
		frame.PortraitIcon,
		frame.PortraitMask,
	}) do
		if region and region.SetAlpha then
			region:SetAlpha(0)
		end
	end
	if frame.PortraitContainer and frame.PortraitContainer.SetAlpha then
		frame.PortraitContainer:SetAlpha(0)
	end
	return true
end

function EllesmereUISkin:SkinIgnoreListWindow(frame)
	if not self:IsSkinEnabled() or not frame then
		return false
	end
	local api = self.facade
	SafeCall(api, "Shell", frame)
	SafeCall(api, "Inset", frame.Inset)
	-- EUI intentionally keeps BFL's native scrollbar treatment.
	self:SkinActionButton(frame.UnignorePlayerButton)
	self:SkinIconButton(frame.GlobalIgnoreListButton)
	self:SkinIconButton(frame.EnhanceQoLIgnoreButton)
	return true
end

function EllesmereUISkin:SkinAppearanceOnboarding(frame, onboarding)
	if not self:IsSkinEnabled() or not frame then
		return false
	end
	local api = self.facade
	SafeCall(api, "Shell", frame)
	SafeCall(api, "Inset", frame.MainInset)
	SafeCall(api, "CloseButton", frame.CloseButton)
	if frame.PortraitContainer then
		frame.PortraitContainer:Hide()
	end
	if frame.portrait then
		frame.portrait:Hide()
	end
	for _, button in ipairs({ onboarding.backButton, onboarding.laterButton, onboarding.primaryButton }) do
		SafeCall(api, "Button", button)
		SafeCall(api, "StateButtonLabel", button)
	end
	for _, card in ipairs(onboarding.styleCards or {}) do
		if card.SetBackdrop then
			card:SetBackdrop(nil)
		end
		SafeCall(api, "Panel", card, { inset = true })
		SkinCheckbox(api, card.SelectControl)
		if card.Diagram.SetBackdrop then
			card.Diagram:SetBackdrop(nil)
		end
		SafeCall(api, "Panel", card.Diagram, { inset = true })
	end
	for _, card in ipairs(onboarding.themeCards or {}) do
		if card.SetBackdrop then
			card:SetBackdrop(nil)
		end
		SafeCall(api, "Panel", card, { inset = true })
		SkinCheckbox(api, card.SelectControl)
	end
	for _, card in ipairs(onboarding.layoutCards or {}) do
		if card.SetBackdrop then
			card:SetBackdrop(nil)
		end
		SafeCall(api, "Panel", card, { inset = true })
		SkinCheckbox(api, card.Check)
	end
	for _, row in ipairs({
		onboarding.summaryPanel and onboarding.summaryPanel.StyleRow,
		onboarding.summaryPanel and onboarding.summaryPanel.ThemeRow,
		onboarding.summaryPanel and onboarding.summaryPanel.SimpleModeRow,
		onboarding.summaryPanel and onboarding.summaryPanel.CompactModeRow,
	}) do
		if row and row.SetBackdrop then
			row:SetBackdrop(nil)
		end
		SafeCall(api, "Panel", row, { inset = true })
	end
	return true
end

function EllesmereUISkin:SkinMainFrame(frame)
	frame = frame or _G.BetterFriendsFrame
	if not self:IsSkinEnabled() or not frame then
		return
	end
	local api = self.facade
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local modern = self:IsModernInterfaceActive()
	local who = frame.WhoFrame
	local guild = frame.GuildFrame
	local raid = frame.RaidFrame
	local quickJoin = frame.QuickJoinFrame
	local paletteVersion = self:GetPaletteVersion()
	local previous = frame.BFL_EllesmereMainShellSkinState
	local staticChromeUnchanged = modern
		and previous
		and previous.paletteVersion == paletteVersion
		and previous.inset == frame.Inset
		and previous.closeButton == frame.CloseButton
		and previous.whoInset == (who and who.ListInset)
		and previous.guildInset == (guild and guild.ListInset)
		and previous.raidInset == (raid and raid.GroupsInset)
		and previous.quickJoinInset == (quickJoin and quickJoin.ContentInset)
	if not staticChromeUnchanged then
		SafeCall(api, "Shell", frame, { bottomBar = 80, noBorder = true })
		SafeCall(api, "Inset", frame.Inset)
		SafeCall(api, "CloseButton", frame.CloseButton)
		SafeCall(api, "Inset", who and who.ListInset)
		SafeCall(api, "Inset", guild and guild.ListInset)
		SafeCall(api, "Inset", raid and raid.GroupsInset)
		SafeCall(api, "Inset", quickJoin and quickJoin.ContentInset)
		if modern then
			frame.BFL_EllesmereMainShellSkinState = {
				paletteVersion = paletteVersion,
				inset = frame.Inset,
				closeButton = frame.CloseButton,
				whoInset = who and who.ListInset,
				guildInset = guild and guild.ListInset,
				raidInset = raid and raid.GroupsInset,
				quickJoinInset = quickJoin and quickJoin.ContentInset,
			}
		end
	end
	-- Same-object native reinitialization is invisible to the static shell key.
	-- Fade only the native NineSlice layers on every coalesced refresh while the
	-- expensive facade Shell/Inset construction remains cached.
	local function FadeNativeSurface(nativeSurface)
		if nativeSurface then
			SafeCall(api, "FadeNineSlice", nativeSurface)
		end
	end
	FadeNativeSurface(frame.NineSlice)
	FadeNativeSurface(frame.Inset and (frame.Inset.NineSlice or frame.Inset))
	FadeNativeSurface(who and who.ListInset and (who.ListInset.NineSlice or who.ListInset))
	FadeNativeSurface(guild and guild.ListInset and (guild.ListInset.NineSlice or guild.ListInset))
	FadeNativeSurface(raid and raid.GroupsInset and (raid.GroupsInset.NineSlice or raid.GroupsInset))
	FadeNativeSurface(quickJoin and quickJoin.ContentInset and (quickJoin.ContentInset.NineSlice or quickJoin.ContentInset))
	if modern then
		-- PortraitFrameMixin can restore the native portrait ring late in its
		-- OnShow chain. Keep the focused EUI refresh responsible for restoring
		-- BFL's compact logo as well as the main-frame shell.
		if FriendsUI.ApplyModernPortrait then
			FriendsUI:ApplyModernPortrait()
		end
		self:RefreshModernPortraitCorner(frame)
		self:SetLegacyPortraitShown(frame, false)
	else
		self:SkinLegacyPortrait(frame)
		for index = 1, 4 do
			self:SkinLegacyTab(_G["BetterFriendsFrameTab" .. index])
			self:SkinLegacyTab(_G["BetterFriendsFrameBottomTab" .. index])
		end
	end

	if modern then
		self:SkinModernChrome(frame, FriendsUI)
	else
		self:SkinLegacyChrome(frame)
	end
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

function EllesmereUISkin:ScheduleMainFrameRefresh(reason)
	if not self:IsSkinEnabled() or self.mainFrameRefreshScheduled then
		return
	end
	self.mainFrameRefreshScheduled = true
	local function RefreshScheduled()
		self.mainFrameRefreshScheduled = nil
		self:RefreshMainFrame(reason or "deferred-main-frame")
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, RefreshScheduled)
	else
		RefreshScheduled()
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
	local function HookMainFrameObject(object, label, methodName)
		if object and type(object[methodName]) == "function" then
			hooksecurefunc(object, methodName, function()
				self:ScheduleMainFrameRefresh(label .. ":" .. methodName)
			end)
		end
	end

	HookMainFrameObject(BFL:GetModule("FriendsUI"), "FriendsUI", "ApplyModernContentLayout")
	HookObject(BFL:GetModule("Changelog"), "Changelog", "CreateChangelogWindow")
	HookObject(BFL.HelpFrame, "HelpFrame", "CreateFrame")
	HookObject(BFL:GetModule("Settings"), "Settings", "CreateExportFrame")
	HookObject(BFL:GetModule("Settings"), "Settings", "CreateImportFrame")
	HookObject(BFL.NoteCleanupWizard, "NoteCleanupWizard", "CreateWizardFrame")
	HookObject(BFL.NoteCleanupWizard, "NoteCleanupWizard", "CreateBackupViewerFrame")
	HookObject(BFL:GetModule("RaidTools"), "RaidTools", "CreateFrame")
	HookObject(BFL:GetModule("WhoFrame"), "WhoFrame", "CreateSearchBuilder")
	HookObject(BFL:GetModule("WhoFrame"), "WhoFrame", "ToggleSearchBuilder")
	local Settings = BFL:GetModule("Settings")
	if Settings then
		for _, methodName in ipairs(LEGACY_SETTINGS_REFRESH_METHODS) do
			if type(Settings[methodName]) == "function" then
				hooksecurefunc(Settings, methodName, function()
					-- Legacy settings pages destroy/recreate their controls on every
					-- refresh. Skin the completed page synchronously so native green
					-- checkmarks or dropdown chrome never become the final state.
					self:SkinLegacySettings()
				end)
			end
		end
	end
	if type(BFL.ApplyTabVisualState) == "function" then
		hooksecurefunc(BFL, "ApplyTabVisualState", function(_, tab)
			-- BFL reapplies font objects and colors after PanelTemplates changes
			-- selection. Run after that final refresh so the original Blizzard
			-- label cannot reappear beside EUI's replacement label.
			self:RefreshLegacyTabLabel(tab)
		end)
	end

	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and type(FriendsList.UpdateInviteButton) == "function" then
		hooksecurefunc(FriendsList, "UpdateInviteButton", function(_, button)
			self:SkinLegacyInviteButtons(button)
		end)
	end

	if _G.BetterFriendsFrame and _G.BetterFriendsFrame.HookScript then
		_G.BetterFriendsFrame:HookScript("OnShow", function()
			-- The full Apply pass also traverses Settings, auxiliary windows, and
			-- popups. OnShow needs only the main frame. Defer this small pass so it
			-- runs after Blizzard's PortraitFrame hooks and coalesces with any layout
			-- refresh scheduled during the same frame.
			self:ScheduleMainFrameRefresh("main-frame-show")
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
