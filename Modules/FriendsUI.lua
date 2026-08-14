local ADDON_NAME, BFL = ...

local FriendsUI = BFL:RegisterModule("FriendsUI", {})
BFL.FriendsUI = FriendsUI

local STYLE_MODERN = "modern"
local STYLE_LEGACY = "legacy"
local MODERN_LAYOUT_KEY = "RetailModern"
local LEGACY_LAYOUT_KEY = "Default"
-- Keep one consistent Modern list gutter: content ends 18 px before the shared
-- right edge and the MinimalScrollBar begins 7 px after the content viewport.
-- Moving the gap itself shifts the visible scrollbar without changing row width.
local MODERN_SCROLL_BOX_RIGHT_INSET = 18
local MODERN_SCROLL_BAR_GAP = 7
local MODERN_SCROLL_BAR_WIDTH = 8
local MODERN_TOP_CONTROL_HEIGHT = 29
local MODERN_DIRECTORY_HEADER_HEIGHT = 28
local MODERN_THEMED_SIDE_TAB_WIDTH = 38
local MODERN_THEMED_SIDE_TAB_OFFSET_X = -3
local MODERN_THEMED_MENU_BUTTON_SIZE = 29
local MODERN_PORTRAIT_SIZE = 60
local MODERN_THEMED_PORTRAIT_SIZE = 42
local MODERN_THEMED_PORTRAIT_OFFSET_X = 8
local MODERN_THEMED_PORTRAIT_OFFSET_Y = -6
-- The custom TGAs already carry a gold palette with an average G/R ratio of
-- roughly 0.845. Preserve that luminance and calibrate only the color channels:
-- 0.845 * 0.9704 ~= Blizzard's 0.82 gold ratio. Inactive scales both channels
-- equally, so its hue remains identical without the brown cast from desaturation.
local CUSTOM_TAB_ICON_ACTIVE_COLOR = { 1, 0.9704, 0 }
local CUSTOM_TAB_ICON_INACTIVE_COLOR = { 0.68, 0.659872, 0 }
local LEGACY_HEADER_DROPDOWN_FIELDS = { "QuickFilterDropdown", "PrimarySortDropdown", "SecondarySortDropdown" }
local POPULATED_ONLY_SECTIONS = {
	quick_join = true,
	friend_requests = true,
}

FriendsUI.STYLE_MODERN = STYLE_MODERN
FriendsUI.STYLE_LEGACY = STYLE_LEGACY
FriendsUI.MODERN_LAYOUT_KEY = MODERN_LAYOUT_KEY
FriendsUI.LEGACY_LAYOUT_KEY = LEGACY_LAYOUT_KEY

local SECTION_DEFINITIONS = {
	{
		id = "friends",
		labelKey = "FRIENDS_UI_SECTION_FRIENDS",
		activeAtlas = "friends-icon-tab-friends",
		inactiveAtlas = "friends-icon-tab-friends-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp",
		bottomTab = 1,
		topTab = 1,
	},
	{
		id = "recent_allies",
		labelKey = "FRIENDS_UI_SECTION_RECENT_ALLIES",
		activeAtlas = "friends-icon-tab-recentallies",
		inactiveAtlas = "friends-icon-tab-recentallies-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\clock.blp",
		bottomTab = 1,
		topTab = 2,
	},
	{
		id = "quick_join",
		labelKey = "FRIENDS_UI_SECTION_QUICK_JOIN",
		activeAtlas = "friends-icon-tab-quickjoin",
		inactiveAtlas = "friends-icon-tab-quickjoin-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-plus.blp",
		bottomTab = 4,
	},
	{
		id = "friend_requests",
		labelKey = "FRIENDS_UI_SECTION_REQUESTS",
		activeAtlas = "friends-icon-tab-friendRequest",
		inactiveAtlas = "friends-icon-tab-friendRequest-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\git-pull-request.blp",
	},
	{
		id = "recruit_a_friend",
		labelKey = "FRIENDS_UI_SECTION_RECRUIT_A_FRIEND",
		activeAtlas = "friends-icon-tab-recruitFriends",
		inactiveAtlas = "friends-icon-tab-recruitFriends-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check.blp",
		bottomTab = 1,
		topTab = 3,
	},
	{
		id = "raid",
		labelKey = "FRIENDS_UI_SECTION_RAID",
		activeAtlas = "friends-icon-tab-raid",
		inactiveAtlas = "friends-icon-tab-raid-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp",
		bottomTab = 3,
	},
	{
		id = "guild",
		labelKey = "FRIENDS_UI_SECTION_GUILD",
		activeAtlas = "friends-icon-tab-guild",
		inactiveAtlas = "friends-icon-tab-guild-inactive",
		customTexture = "Interface\\AddOns\\BetterFriendlist\\Icons\\friends-icon-tab-guild.tga",
		iconOffsetX = -4,
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild.blp",
		bottomTab = 1,
		topTab = 4,
	},
	{
		id = "who",
		labelKey = "FRIENDS_UI_SECTION_WHO",
		activeAtlas = "friends-icon-tab-who",
		inactiveAtlas = "friends-icon-tab-who-inactive",
		customTexture = "Interface\\AddOns\\BetterFriendlist\\Icons\\friends-icon-tab-who.tga",
		iconOffsetX = -4,
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user.blp",
		bottomTab = 2,
	},
}

local SECTION_BY_ID = {}
local DEFAULT_SECTION_ORDER = {}
for _, definition in ipairs(SECTION_DEFINITIONS) do
	SECTION_BY_ID[definition.id] = definition
	DEFAULT_SECTION_ORDER[#DEFAULT_SECTION_ORDER + 1] = definition.id
end

local CONTACT_CHROME = {
	friends = { filterBar = true, friendsFilter = true, sort = true, action = "add_friend" },
	recent_allies = { filterBar = true, recentFilter = true, action = "add_friend" },
	friend_requests = { action = "add_friend" },
	quick_join = { action = "quick_join" },
	guild = { filterBar = true, action = "guild_actions" },
	who = { filterBar = true, action = "who_actions" },
}

local FRIENDS_RESTRICTED_SECTIONS = {
	friends = true,
	recent_allies = true,
	quick_join = true,
	friend_requests = true,
	recruit_a_friend = true,
}

local function GetL()
	return BFL.L or _G.BFL_L or {}
end

local function GetDB()
	local DB = BFL:GetModule("DB")
	return DB and DB:Get() or BetterFriendlistDB
end

local function SetDBValue(key, value)
	local DB = BFL:GetModule("DB")
	if DB and DB.Set then
		DB:Set(key, value)
	elseif BetterFriendlistDB then
		BetterFriendlistDB[key] = value
		if BFL.SettingsVersion then
			BFL.SettingsVersion = BFL.SettingsVersion + 1
		end
	end
end

local function CopyMap(source)
	local copy = {}
	for key, value in pairs(type(source) == "table" and source or {}) do
		copy[key] = value
	end
	return copy
end

local function IsFrame(frame)
	return frame and frame.GetObjectType ~= nil
end

local function IsLayoutFrame(frame)
	return IsFrame(frame)
		and frame.GetNumPoints ~= nil
		and frame.GetPoint ~= nil
		and frame.GetParent ~= nil
		and frame.SetParent ~= nil
		and frame.GetFrameLevel ~= nil
		and frame.SetFrameLevel ~= nil
end

local function SafeShow(frame, shown)
	if not IsFrame(frame) then
		return
	end
	if shown then
		frame:Show()
	else
		frame:Hide()
	end
end

-- Runtime Modern buttons keep the visual/lifecycle handlers supplied by
-- SharedButtonTemplate. UIPanelButtonTemplate uses Left/Middle/Right while
-- Retail 12.1's SharedButtonTemplate uses Left/Center/Right, so copying its
-- OnShow or mouse-state scripts corrupts the ThreeSlice button and errors on
-- the missing Middle region. Only forward BFL's application click handler;
-- hover behavior stays with the concrete template.
local STYLE_BUTTON_RUNTIME_SCRIPTS = {
	"OnClick",
	"OnEnter",
	"OnLeave",
}

local function CopyButtonRuntimeState(source, target)
	if not (source and target) then
		return
	end
	if source.GetText and target.SetText then
		target:SetText(source:GetText() or "")
	end
	if source.IsEnabled and target.SetEnabled then
		target:SetEnabled(source:IsEnabled())
	end
	if source.IsShown and target.SetShown then
		target:SetShown(source:IsShown())
	end
	target.tooltip = source.tooltip
end

local function EnsureModernActionButton(owner, key)
	if not (owner and owner[key]) then
		return nil
	end
	local legacyKey = "BFL_Legacy" .. key
	local modernKey = "BFL_Modern" .. key
	if not owner[legacyKey] then
		owner[legacyKey] = owner[key]
	end
	local legacyButton = owner[legacyKey]
	local modernButton = owner[modernKey]
	if not modernButton then
		local ok, created = pcall(CreateFrame, "Button", nil, legacyButton:GetParent(), "SharedButtonTemplate")
		if not ok or not created then
			return legacyButton
		end
		modernButton = created
		modernButton.BFL_TemplateScripts = {}
		for _, scriptType in ipairs(STYLE_BUTTON_RUNTIME_SCRIPTS) do
			modernButton.BFL_TemplateScripts[scriptType] = modernButton:GetScript(scriptType)
		end
		modernButton:SetID(legacyButton:GetID() or 0)
		if modernButton.SetMotionScriptsWhileDisabled then
			modernButton:SetMotionScriptsWhileDisabled(true)
		end
		owner[modernKey] = modernButton
	end

	-- Scripts can be installed by modules after XML OnLoad. Refresh them on every
	-- style application so the runtime Modern proxy never keeps stale handlers.
	for _, scriptType in ipairs(STYLE_BUTTON_RUNTIME_SCRIPTS) do
		local legacyScript = legacyButton:GetScript(scriptType)
		local templateScript = modernButton.BFL_TemplateScripts and modernButton.BFL_TemplateScripts[scriptType]
		-- UIPanelButtonTemplate and SharedButtonTemplate use incompatible tooltip
		-- mixins. Only the application click handler belongs to BFL; hover scripts
		-- must stay with the concrete visual template that owns the button.
		modernButton:SetScript(scriptType, scriptType == "OnClick" and (legacyScript or templateScript) or templateScript)
	end
	CopyButtonRuntimeState(owner[key], modernButton)
	legacyButton:Hide()
	owner[key] = modernButton
	return modernButton
end

local function RestoreLegacyActionButton(owner, key)
	if not owner then
		return nil
	end
	local legacyButton = owner["BFL_Legacy" .. key]
	local modernButton = owner["BFL_Modern" .. key]
	if not legacyButton then
		return owner[key]
	end
	if modernButton then
		CopyButtonRuntimeState(modernButton, legacyButton)
		modernButton:Hide()
	end
	owner[key] = legacyButton
	return legacyButton
end

local function ConfigureModernReadyCheckButton(button, legacyButton)
	if not button then
		return
	end

	if not button.Icon then
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("CENTER")
		button.Icon = icon
	end
	button.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\user-check.blp")
	button.Icon:SetSize(14, 14)
	button:SetText("")

	-- Keep the SharedButtonTemplate hover animation, then layer the established
	-- Ready Check tooltip behavior on top without copying SquareIconButton
	-- lifecycle scripts onto the incompatible ThreeSlice template.
	button.BFL_ReadyCheckTooltipOnEnter = legacyButton and legacyButton:GetScript("OnEnter") or nil
	button.BFL_ReadyCheckTooltipOnLeave = legacyButton and legacyButton:GetScript("OnLeave") or nil
	if not button.BFL_ReadyCheckTooltipHooked then
		button:HookScript("OnEnter", function(self)
			if self.BFL_ReadyCheckTooltipOnEnter then
				self:BFL_ReadyCheckTooltipOnEnter()
			end
		end)
		button:HookScript("OnLeave", function(self)
			if self.BFL_ReadyCheckTooltipOnLeave then
				self:BFL_ReadyCheckTooltipOnLeave()
			end
		end)
		button.BFL_ReadyCheckTooltipHooked = true
	end
	if not button.BFL_ReadyCheckIconStateHooked then
		local function refreshIconState(readyCheckButton)
			if FriendsUI.RefreshModernReadyCheckIconColor then
				FriendsUI:RefreshModernReadyCheckIconColor(readyCheckButton)
			end
		end
		button:HookScript("OnEnable", refreshIconState)
		button:HookScript("OnDisable", refreshIconState)
		button.BFL_ReadyCheckIconStateHooked = true
	end
end

local function CaptureRegionState(region)
	if not (region and region.GetNumPoints and region.GetPoint) then
		return nil
	end
	local state = {
		region = region,
		points = {},
		width = region.GetWidth and region:GetWidth() or nil,
		height = region.GetHeight and region:GetHeight() or nil,
		shown = region.IsShown and region:IsShown() or nil,
		alpha = region.GetAlpha and region:GetAlpha() or nil,
		font = region.GetFont and { region:GetFont() } or nil,
		justifyH = region.GetJustifyH and region:GetJustifyH() or nil,
		justifyV = region.GetJustifyV and region:GetJustifyV() or nil,
	}
	for index = 1, region:GetNumPoints() do
		state.points[index] = { region:GetPoint(index) }
	end
	return state
end

local function RestoreRegionState(state)
	local region = state and state.region
	if not region then
		return
	end
	region:ClearAllPoints()
	for _, point in ipairs(state.points or {}) do
		region:SetPoint(unpack(point))
	end
	if state.width and state.height and state.width > 0 and state.height > 0 and region.SetSize then
		region:SetSize(state.width, state.height)
	end
	if state.font and state.font[1] and region.SetFont then
		region:SetFont(unpack(state.font))
	end
	if state.justifyH and region.SetJustifyH then
		region:SetJustifyH(state.justifyH)
	end
	if state.justifyV and region.SetJustifyV then
		region:SetJustifyV(state.justifyV)
	end
	if state.alpha ~= nil and region.SetAlpha then
		region:SetAlpha(state.alpha)
	end
	if state.shown ~= nil and region.SetShown then
		region:SetShown(state.shown)
	end
end

local function ApplyAtlasTexture(texture, atlas, fallback)
	if not texture then
		return
	end
	if BFL.SetTextureOrAtlas then
		BFL.SetTextureOrAtlas(texture, atlas, fallback, true)
	elseif fallback then
		texture:SetTexture(fallback)
	end
end

local MODERN_BLIZZARD_THEME_COLORS = {
	background = { 0.04, 0.04, 0.04, 1 },
	surface = { 0.12, 0.09, 0.07, 0.34 },
	inset = { 0, 0, 0, 0 },
	control = { 1, 1, 1, 1 },
	border = { 1, 1, 1, 1 },
	accent = { 1, 0.82, 0, 1 },
	text = { 1, 1, 1, 1 },
	disabledText = { 0.5, 0.5, 0.5, 1 },
	hover = { 1, 1, 1, 1 },
	selected = { 1, 1, 1, 1 },
	scrollThumb = { 1, 1, 1, 1 },
	icon = { 1, 0.82, 0, 1 },
}

local MODERN_ELVUI_THEME_COLORS = {
	background = { 0.055, 0.055, 0.055, 0.96 },
	surface = { 0.055, 0.055, 0.055, 0.42 },
	inset = { 0, 0, 0, 0 },
	control = { 1, 1, 1, 1 },
	border = { 1, 1, 1, 1 },
	accent = { 1, 0.82, 0, 1 },
	text = { 1, 1, 1, 1 },
	disabledText = { 0.5, 0.5, 0.5, 1 },
	hover = { 1, 1, 1, 1 },
	selected = { 1, 1, 1, 1 },
	scrollThumb = { 1, 1, 1, 1 },
	icon = { 1, 0.82, 0, 1 },
}

local MODERN_WHITE = { 1, 1, 1, 1 }
local REAL_ID_WARNING_BLIZZARD_BACKGROUND = { 0, 0, 0, 0.85 }
local ATLAS_TINT_CACHE = setmetatable({}, { __mode = "k" })
local OPAQUE_THEME_COLOR_CACHE = setmetatable({}, { __mode = "k" })
local REAL_ID_WARNING_COLOR_CACHE = setmetatable({}, { __mode = "k" })

local function CopyThemeColor(color, fallback)
	color = type(color) == "table" and color or fallback
	fallback = fallback or { 1, 1, 1, 1 }
	return {
		color and (color[1] or color.r) or fallback[1],
		color and (color[2] or color.g) or fallback[2],
		color and (color[3] or color.b) or fallback[3],
		color and (color[4] ~= nil and color[4] or color.a) or fallback[4],
	}
end

local function OpaqueThemeColor(color)
	color = color or MODERN_BLIZZARD_THEME_COLORS.accent
	local r, g, b = color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1
	local cached = OPAQUE_THEME_COLOR_CACHE[color]
	if cached and cached[1] == r and cached[2] == g and cached[3] == b then
		return cached
	end
	cached = { r, g, b, 1 }
	OPAQUE_THEME_COLOR_CACHE[color] = cached
	return cached
end

local function ApplyTextureColor(texture, color)
	if texture and texture.SetVertexColor and color then
		texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
	end
end

local function ApplySolidTextureColor(texture, color)
	if texture and texture.SetColorTexture and color then
		texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
	end
end

local function ResolveRealIDWarningBackground(palette, theme)
	if theme == "blizzard" or type(palette) ~= "table" then
		return REAL_ID_WARNING_BLIZZARD_BACKGROUND
	end

	-- Theme content backgrounds are intentionally translucent so the main
	-- window shell can remain visible. The Real ID notice is a modal privacy
	-- warning and needs an independently opaque surface, matching Blizzard's
	-- DIALOG overlay rather than the normal content wash.
	local source = palette.panel or palette.background or REAL_ID_WARNING_BLIZZARD_BACKGROUND
	local r = source[1] or source.r or 0
	local g = source[2] or source.g or 0
	local b = source[3] or source.b or 0
	local a = math.max(source[4] ~= nil and source[4] or source.a or 1, 0.94)
	local cached = REAL_ID_WARNING_COLOR_CACHE[source]
	if cached and cached[1] == r and cached[2] == g and cached[3] == b and cached[4] == a then
		return cached
	end
	cached = { r, g, b, a }
	REAL_ID_WARNING_COLOR_CACHE[source] = cached
	return cached
end

local function ApplyModernOwnedSurface(frame, color, shown)
	if not (frame and frame.CreateTexture) then
		return
	end
	local surface = frame.BFL_ModernThemeSurface
	if not surface then
		surface = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		surface:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		surface:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		frame.BFL_ModernThemeSurface = surface
	end
	ApplySolidTextureColor(surface, color)
	surface:SetShown(shown == true)
end

local function ApplyThemedFontColor(owner, fontString, color, themed)
	if not (themed and owner and fontString and color) then
		return
	end
	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.SetFontColor then
		SkinEngine:SetFontColor(owner, fontString, color[1], color[2], color[3], color[4] or 1)
	elseif fontString.SetTextColor then
		fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
	end
end

local function GetAtlasTint(color)
	color = color or MODERN_BLIZZARD_THEME_COLORS.surface
	local cached = ATLAS_TINT_CACHE[color]
	if
		cached
		and cached._sourceR == color[1]
		and cached._sourceG == color[2]
		and cached._sourceB == color[3]
	then
		return cached
	end
	-- Blizzard atlases already contain light and shadow information. Mixing the
	-- requested surface toward white preserves that relief while BFL's owned
	-- flat-color layers carry the actual theme color.
	local tint = {
		0.52 + (color[1] or 0) * 0.48,
		0.52 + (color[2] or 0) * 0.48,
		0.52 + (color[3] or 0) * 0.48,
		1,
	}
	tint._sourceR, tint._sourceG, tint._sourceB = color[1], color[2], color[3]
	ATLAS_TINT_CACHE[color] = tint
	return tint
end

local function SetTextureDesaturated(texture, desaturated)
	if texture and texture.SetDesaturated then
		texture:SetDesaturated(desaturated == true)
	end
end

local function ApplyModernAtlasColor(texture, color, themed)
	if not texture then
		return
	end
	SetTextureDesaturated(texture, themed)
	ApplyTextureColor(texture, themed and GetAtlasTint(color) or MODERN_BLIZZARD_THEME_COLORS.control)
end

local function GetControlFontString(control)
	if not control then
		return nil
	end
	return control.Text
		or control.TextRegion
		or control.SelectionText
		or (control.GetFontString and control:GetFontString())
end

local function ApplyModernControlTheme(control, palette, themed)
	if not control then
		return
	end
	if themed and not palette.externalControls then
		local SkinEngine = BFL:GetModule("SkinEngine")
		if SkinEngine and SkinEngine.StyleBackdrop then
			SkinEngine:StyleBackdrop(control, palette.control, palette.border)
		end
	end
	ApplyThemedFontColor(control, GetControlFontString(control), palette.text, themed)
end

function FriendsUI:RefreshModernReadyCheckIconColor(button)
	button = button
		or (BetterFriendsFrame and BetterFriendsFrame.RaidFrame and BetterFriendsFrame.RaidFrame.ControlPanel
			and BetterFriendsFrame.RaidFrame.ControlPanel.ReadyCheckButton)
	if not (button and button.Icon and self:IsModernActive()) then
		return
	end

	local palette, themed = self:GetModernThemeColors()
	local enabled = true
	if button.IsEnabled then
		local enabledState = button:IsEnabled()
		enabled = enabledState ~= false and enabledState ~= nil and enabledState ~= 0
	end
	local color
	if enabled then
		color = themed and OpaqueThemeColor(palette.accent) or MODERN_BLIZZARD_THEME_COLORS.control
	else
		local disabledFont = button.GetDisabledFontObject and button:GetDisabledFontObject()
		if disabledFont and disabledFont.GetTextColor then
			local r, g, b, a = disabledFont:GetTextColor()
			color = { r, g, b, a or 1 }
		elseif GRAY_FONT_COLOR then
			local r, g, b, a = GRAY_FONT_COLOR:GetRGBA()
			color = { r, g, b, a or 1 }
		else
			color = palette.disabledText
		end
	end

	SetTextureDesaturated(button.Icon, themed or not enabled)
	ApplyTextureColor(button.Icon, color)
	button.Icon:SetAlpha(1)
end

local function SetModernSideTabGlowTheme(tab, palette, themed)
	if not tab then
		return
	end
	local nativeAnimation = tab.TabGlowAnimation
	local themeAnimation = tab.ThemeGlowAnimation
	local requested = tab.BFL_RequestGlowActive == true
	if themed then
		if nativeAnimation and nativeAnimation.IsPlaying and nativeAnimation:IsPlaying() then
			nativeAnimation:Stop()
		end
		if tab.ThemeGlow then
			ApplySolidTextureColor(tab.ThemeGlow, palette.accent)
			tab.ThemeGlow:SetShown(requested)
		end
		if requested and themeAnimation and themeAnimation.Play and (not themeAnimation.IsPlaying or not themeAnimation:IsPlaying()) then
			themeAnimation:Play()
		elseif not requested and themeAnimation and themeAnimation.Stop then
			themeAnimation:Stop()
		end
	else
		if themeAnimation and themeAnimation.Stop then
			themeAnimation:Stop()
		end
		if tab.ThemeGlow then
			tab.ThemeGlow:Hide()
		end
		if requested and nativeAnimation and nativeAnimation.Play and (not nativeAnimation.IsPlaying or not nativeAnimation:IsPlaying()) then
			nativeAnimation:Play()
		elseif not requested and nativeAnimation and nativeAnimation.Stop then
			nativeAnimation:Stop()
			if tab.TabGlow and tab.TabGlow.SetAlpha then
				tab.TabGlow:SetAlpha(0)
			end
		end
	end
end

local function ApplyModernSideTabTheme(tab, palette, themed, selected)
	if not tab then
		return
	end
	local SkinEngine = BFL:GetModule("SkinEngine")
	if themed and SkinEngine and SkinEngine.IsActive and SkinEngine:IsActive() then
		tab.BFL_DarkManagedSelection = selected == true
		tab.BFL_DarkTabButton = true
		tab.BFL_DarkPreserveTabBackgroundOnPress = true
		SkinEngine:SetFrameSize(tab, MODERN_THEMED_SIDE_TAB_WIDTH, tab:GetHeight())
		local countShown = tab.Count and tab.Count.IsShown and tab.Count:IsShown()
		if tab.Icon then
			SkinEngine:SetRegionPoints(tab, tab.Icon, {
				{ "CENTER", tab, "CENTER", 0, countShown and 5 or 0 },
			})
		end
		if tab.Count then
			SkinEngine:SetRegionPoints(tab, tab.Count, {
				{ "BOTTOM", tab, "BOTTOM", 0, 6 },
			})
		end
		SkinEngine:SkinButton(tab, {
			variant = "tab",
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
			textureAlpha = 0,
		})
		-- Keep the Retail icon and count, but replace the complete native
		-- common-sidetab shell with SkinEngine's flat, reversible backdrop.
		SkinEngine:ClearTextureObject(tab, tab.Background, 0)
		SkinEngine:ClearTextureObject(tab, tab.SelectedTexture, 0)
		SkinEngine:ClearTextureObject(tab, tab.HighlightTexture, 0)
		SkinEngine:ClearTextureObject(tab, tab.TabGlow, 0)
		tab.BFL_DarkButtonStateKey = nil
		SkinEngine:ApplyButtonState(tab)
	else
		tab.BFL_DarkManagedSelection = nil
		tab.BFL_DarkPreserveTabBackgroundOnPress = nil
		if tab.SetChecked then
			tab:SetChecked(selected == true)
		elseif tab.SelectedTexture then
			tab.SelectedTexture:SetShown(selected == true)
		end
		if tab.HighlightTexture then
			tab.HighlightTexture:SetShown(BFL:IsRegionMouseOver(tab))
		end
		ApplyModernAtlasColor(tab.Background, palette.control, false)
		ApplyModernAtlasColor(tab.SelectedTexture, palette.control, false)
		ApplyModernAtlasColor(tab.HighlightTexture, palette.accent, false)
		ApplyModernAtlasColor(tab.TabGlow, palette.accent, false)
	end
	SetModernSideTabGlowTheme(tab, palette, themed)
end

function FriendsUI:GetModernThemeColors(theme)
	theme = theme or self.currentTheme or (BFL.GetEffectiveTheme and BFL:GetEffectiveTheme()) or "blizzard"
	if theme == "elvui" then
		return MODERN_ELVUI_THEME_COLORS, false
	end
	if theme == "ellesmereui" then
		local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
		local colorVersion = EllesmereUISkin
			and EllesmereUISkin.GetPaletteVersion
			and EllesmereUISkin:GetPaletteVersion()
			or 0
		if
			self.modernThemeColors
			and self.modernThemeColorsTheme == theme
			and self.modernThemeColorsVersion == colorVersion
		then
			return self.modernThemeColors, true
		end
		local colors = EllesmereUISkin and EllesmereUISkin.GetPalette and EllesmereUISkin:GetPalette()
		if type(colors) ~= "table" then
			return MODERN_BLIZZARD_THEME_COLORS, false
		end
		self.modernThemeColors = colors
		self.modernThemeColorsTheme = theme
		self.modernThemeColorsVersion = colorVersion
		return colors, true
	end
	if theme ~= "dark" and theme ~= "custom" then
		return MODERN_BLIZZARD_THEME_COLORS, false
	end

	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.RefreshThemeColors and SkinEngine.activeTheme ~= theme then
		SkinEngine:RefreshThemeColors()
	end
	local colorVersion = SkinEngine and SkinEngine.themeColorVersion or 0
	if self.modernThemeColors and self.modernThemeColorsTheme == theme and self.modernThemeColorsVersion == colorVersion then
		return self.modernThemeColors, true
	end
	local colors = SkinEngine and SkinEngine.colors or {}
	local resolved = {
		background = CopyThemeColor(colors.panel, { 0, 0, 0, 0.68 }),
		surface = CopyThemeColor(colors.panelSoft, { 0.03, 0.03, 0.034, 0.42 }),
		inset = CopyThemeColor(colors.inset, { 0, 0, 0, 0.42 }),
		control = CopyThemeColor(colors.control, { 0.055, 0.055, 0.06, 0.42 }),
		border = CopyThemeColor(colors.borderSoft, { 0.22, 0.22, 0.24, 0.58 }),
		accent = CopyThemeColor(colors.accent, { 1, 0.82, 0, 0.62 }),
		text = CopyThemeColor(colors.text, { 0.92, 0.92, 0.92, 1 }),
		disabledText = CopyThemeColor(colors.disabledText, { 0.45, 0.45, 0.46, 0.85 }),
		hover = CopyThemeColor(colors.rowHover, { 1, 0.82, 0, 0.10 }),
		selected = CopyThemeColor(colors.rowDown, { 1, 0.82, 0, 0.14 }),
		scrollThumb = CopyThemeColor(colors.scrollThumb, { 0.42, 0.42, 0.44, 0.78 }),
		icon = CopyThemeColor(colors.icon, { 1, 0.82, 0, 0.90 }),
	}
	self.modernThemeColors = resolved
	self.modernThemeColorsTheme = theme
	self.modernThemeColorsVersion = colorVersion
	return resolved, true
end

function FriendsUI:GetModernHeaderControlOffsetY()
	local palette = self:GetModernThemeColors()
	return tonumber(palette and palette.headerControlOffsetY) or 4
end

local function ApplyModernSearchBoxVisual(searchBox)
	if not searchBox then
		return
	end
	local _, themed = FriendsUI:GetModernThemeColors()

	-- Guild and Who historically added a second character-select search atlas
	-- on top of SearchBoxTemplate. Keep only the same chrome Friends uses.
	SafeShow(searchBox.Backdrop, false)
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		SafeShow(searchBox[key], true)
	end
	if searchBox.searchIcon then
		if BFL.SetTextureOrAtlas then
			-- SearchBoxTemplate explicitly uses useAtlasSize=false. The general
			-- icon helper uses true and would expand this atlas to its native
			-- dimensions instead of the intended 10 x 10 search glyph.
			BFL.SetTextureOrAtlas(
				searchBox.searchIcon,
				"common-search-magnifyingglass",
				"Interface\\AddOns\\BetterFriendlist\\Icons\\search",
				false
			)
		else
			searchBox.searchIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\search")
		end
		searchBox.searchIcon:ClearAllPoints()
		searchBox.searchIcon:SetSize(10, 10)
		searchBox.searchIcon:SetPoint("LEFT", searchBox, "LEFT", themed and 3 or 1, -1)
	end

	if searchBox.Instructions then
		searchBox.Instructions:SetFontObject("BetterFriendlistFontDisable")
		searchBox.Instructions:SetJustifyH("LEFT")
		searchBox.Instructions:SetMaxLines(1)
		searchBox.Instructions:ClearAllPoints()
		searchBox.Instructions:SetPoint("LEFT", searchBox, "LEFT", themed and 19 or 16, -1)
		searchBox.Instructions:SetPoint("RIGHT", searchBox, "RIGHT", -20, -1)
	end

	-- Reapply the shared BFL edit-box surface after the legacy overlay was
	-- removed. SkinEditBox is a no-op when the dark theme is inactive.
	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.SkinEditBox then
		SkinEngine:SkinEditBox(searchBox)
	end
end

local function ConstrainDropdownText(dropdown, leftInset, rightInset, fontReduction)
	local text = dropdown and (dropdown.Text or dropdown.TextRegion or dropdown.SelectionText)
	if not text then
		return
	end

	text:ClearAllPoints()
	text:SetPoint("LEFT", dropdown, "LEFT", leftInset or 5, 0)
	text:SetPoint("RIGHT", dropdown, "RIGHT", rightInset or -20, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	if text.SetWordWrap then
		text:SetWordWrap(false)
	end
	if text.SetNonSpaceWrap then
		text:SetNonSpaceWrap(true)
	end
	if text.SetMaxLines then
		text:SetMaxLines(1)
	end
	if fontReduction and text.GetFont and text.SetFont then
		if not dropdown.BFLOriginalDropdownFont then
			dropdown.BFLOriginalDropdownFont = { text:GetFont() }
		end
		local fontPath, fontSize, fontFlags = unpack(dropdown.BFLOriginalDropdownFont)
		if fontPath and fontSize then
			text:SetFont(fontPath, math.max(10, fontSize - fontReduction), fontFlags)
		end
	end
end

local function ConstrainModernDropdownText(dropdown, fontReduction, defaultLeftInset)
	local _, themed = FriendsUI:GetModernThemeColors()
	local leftInset = defaultLeftInset or 5
	ConstrainDropdownText(
		dropdown,
		themed and math.max(1, leftInset - 1) or leftInset,
		themed and -24 or -20,
		fontReduction
	)
end

local function ApplySectionIcon(texture, definition, selected)
	if not texture or not definition then
		return
	end
	local palette, themed = FriendsUI:GetModernThemeColors()
	if definition.customTexture then
		texture:SetTexture(definition.customTexture)
		texture:SetSize(32, 32)
		texture:SetTexCoord(0, 1, 0, 1)
		-- Custom tabs use one source texture for both states while Blizzard tabs
		-- have separate active/inactive atlases. Recreate that luminance step after
		-- desaturation so EUI's accent remains pure instead of mixing with the
		-- source artwork's baked gold.
		texture:SetDesaturated(themed)
		local color = themed and palette.accent
			or (selected and CUSTOM_TAB_ICON_ACTIVE_COLOR or CUSTOM_TAB_ICON_INACTIVE_COLOR)
		local multiplier = themed and not selected and (tonumber(palette.customTabInactiveMultiplier) or 1) or 1
		texture:SetVertexColor(color[1] * multiplier, color[2] * multiplier, color[3] * multiplier, 1)
		return
	end
	ApplyAtlasTexture(texture, selected and definition.activeAtlas or definition.inactiveAtlas, definition.fallback)
	texture:SetDesaturated(themed)
	local color = themed and palette.accent or MODERN_BLIZZARD_THEME_COLORS.control
	texture:SetVertexColor(color[1], color[2], color[3], 1)
end

function FriendsUI:ApplyFriendTabIcon(texture, sectionID, selected)
	local definition = SECTION_BY_ID[sectionID]
	if not definition then
		return false
	end
	ApplySectionIcon(texture, definition, selected == true)
	return true
end

function FriendsUI:HideModernLegacyHeaderDropdowns(header)
	if not header then
		return
	end

	for _, field in ipairs(LEGACY_HEADER_DROPDOWN_FIELDS) do
		local dropdown = header[field]
		if dropdown then
			if not dropdown._bflModernVisibilityGuardInstalled and dropdown.HookScript then
				dropdown._bflModernVisibilityGuardInstalled = true
				dropdown:HookScript("OnShow", function(control)
					local ui = BFL.FriendsUI or BFL:GetModule("FriendsUI")
					if ui and ui.IsModernActive and ui:IsModernActive() then
						control:Hide()
					end
				end)
			end
			SafeShow(dropdown, false)
		end
	end
end

local function AreFriendsDisabled()
	if not (C_SocialRestrictions and C_SocialRestrictions.IsFriendsDisabled) then
		return false
	end
	local ok, disabled = pcall(C_SocialRestrictions.IsFriendsDisabled)
	return ok and disabled == true
end

function FriendsUI:AreFriendsDisabled()
	return AreFriendsDisabled()
end

local function GetFriendInviteCount()
	if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
		return #BFL.MockFriendInvites.invites
	end
	if BNGetNumFriendInvites then
		local ok, count = pcall(BNGetNumFriendInvites)
		if ok then
			return tonumber(count) or 0
		end
	end
	return 0
end

function FriendsUI:GetDefaultRequestedStyle(isRetail)
	if isRetail == nil then
		isRetail = BFL.IsRetail == true
	end
	return isRetail and STYLE_MODERN or STYLE_LEGACY
end

function FriendsUI:ResolveRequestedStyle(storedStyle, isRetail, onboardingVersion, requiredOnboardingVersion)
	if storedStyle == STYLE_MODERN or storedStyle == STYLE_LEGACY then
		return storedStyle
	end
	if isRetail == true and (tonumber(onboardingVersion) or 0) < (tonumber(requiredOnboardingVersion) or 1) then
		return STYLE_LEGACY
	end
	return self:GetDefaultRequestedStyle(isRetail)
end

function FriendsUI:ComputeEffectiveStyle(requestedStyle, isRetail, socialUIAvailable, forceModern)
	if requestedStyle ~= STYLE_MODERN then
		return STYLE_LEGACY
	end
	if isRetail ~= true or (socialUIAvailable ~= true and forceModern ~= true) then
		return STYLE_LEGACY
	end
	return STYLE_MODERN
end

function FriendsUI:IsSocialUIAvailable()
	return BFL.IsRetail == true
		and C_SocialUI ~= nil
		and type(C_SocialUI.IsSystemEnabled) == "function"
end

function FriendsUI:IsSocialUIEnabled()
	if not self:IsSocialUIAvailable() then
		return false
	end
	local ok, enabled = pcall(C_SocialUI.IsSystemEnabled)
	return ok and enabled == true
end

function FriendsUI:IsModernForceEnabled()
	if not BFL.IsRetail then
		return false
	end
	local db = GetDB()
	return db and db.forceModernFriendsUI == true or false
end

-- Modern is BFL-owned. Blizzard may remotely disable its SocialUI frame while
-- leaving the 12.1 social backends enabled, so API presence is the capability
-- gate while IsSocialUIEnabled remains reserved for native-frame integration.
function FriendsUI:IsModernStyleSelectable()
	return self:IsSocialUIAvailable()
end

function FriendsUI:GetModernUnavailableReason()
	if self:IsModernStyleSelectable() then
		return nil
	end
	return L.SETTINGS_FRIENDS_UI_MODERN_UNAVAILABLE
		or "This client does not provide Blizzard's Social UI API. Modern is unavailable."
end

function FriendsUI:GetRequestedStyle()
	local db = GetDB()
	local style = db and db.friendsFrameStyle
	local onboardingVersion = db and db.appearanceOnboardingVersion or 0
	return self:ResolveRequestedStyle(
		style,
		BFL.IsRetail == true,
		onboardingVersion,
		BFL.APPEARANCE_ONBOARDING_VERSION or 1
	)
end

function FriendsUI:GetEffectiveStyle()
	return self:ComputeEffectiveStyle(
		self:GetRequestedStyle(),
		BFL.IsRetail == true,
		self:IsSocialUIAvailable(),
		self:IsModernForceEnabled()
	)
end

function FriendsUI:GetAppliedStyle()
	return self.appliedStyle or self:GetEffectiveStyle()
end

function FriendsUI:IsModernActive()
	return self:GetAppliedStyle() == STYLE_MODERN
end

function FriendsUI:GetLayoutKeyForStyle(style)
	return style == STYLE_MODERN and MODERN_LAYOUT_KEY or LEGACY_LAYOUT_KEY
end

function FriendsUI:GetLayoutKey()
	return self:GetLayoutKeyForStyle(self:GetAppliedStyle())
end

function FriendsUI:ShouldShowInvitesInline(style)
	return (style or self:GetAppliedStyle()) ~= STYLE_MODERN
end

function FriendsUI:GetSectionDefinitions()
	return SECTION_DEFINITIONS
end

function FriendsUI:NormalizeFriendTabOrder(order)
	local normalized = {}
	local seen = {}
	for _, sectionID in ipairs(type(order) == "table" and order or {}) do
		if SECTION_BY_ID[sectionID] and not seen[sectionID] then
			seen[sectionID] = true
			normalized[#normalized + 1] = sectionID
		end
	end
	for _, sectionID in ipairs(DEFAULT_SECTION_ORDER) do
		if not seen[sectionID] then
			seen[sectionID] = true
			normalized[#normalized + 1] = sectionID
		end
	end
	return normalized
end

function FriendsUI:GetFriendTabOrder()
	local db = GetDB()
	return self:NormalizeFriendTabOrder(db and db.modernFriendTabOrder)
end

function FriendsUI:SetFriendTabOrder(order)
	SetDBValue("modernFriendTabOrder", self:NormalizeFriendTabOrder(order))
	self:RefreshFriendTabSettings()
end

function FriendsUI:MoveFriendTab(fromIndex, toIndex)
	local order = self:GetFriendTabOrder()
	fromIndex = tonumber(fromIndex)
	toIndex = tonumber(toIndex)
	if not (fromIndex and toIndex and order[fromIndex]) then
		return false
	end
	toIndex = math.max(1, math.min(#order, toIndex))
	local sectionID = table.remove(order, fromIndex)
	table.insert(order, toIndex, sectionID)
	self:SetFriendTabOrder(order)
	return true
end

function FriendsUI:IsFriendTabVisible(sectionID)
	if not SECTION_BY_ID[sectionID] then
		return false
	end
	local db = GetDB()
	local visibility = db and db.modernFriendTabVisibility
	return type(visibility) ~= "table" or visibility[sectionID] ~= false
end

function FriendsUI:SetFriendTabVisible(sectionID, visible)
	if not SECTION_BY_ID[sectionID] then
		return false
	end
	local db = GetDB()
	local visibility = CopyMap(db and db.modernFriendTabVisibility)
	visibility[sectionID] = visible == true
	SetDBValue("modernFriendTabVisibility", visibility)
	self:RefreshFriendTabSettings()
	return true
end

function FriendsUI:IsFriendTabPopulatedOnly(sectionID)
	if not POPULATED_ONLY_SECTIONS[sectionID] then
		return false
	end
	local db = GetDB()
	local settings = db and db.modernFriendTabPopulatedOnly
	return type(settings) == "table" and settings[sectionID] == true
end

function FriendsUI:SetFriendTabPopulatedOnly(sectionID, enabled)
	if not POPULATED_ONLY_SECTIONS[sectionID] then
		return false
	end
	local db = GetDB()
	local settings = CopyMap(db and db.modernFriendTabPopulatedOnly)
	settings[sectionID] = enabled == true
	SetDBValue("modernFriendTabPopulatedOnly", settings)
	self:RefreshFriendTabSettings()
	return true
end

function FriendsUI:GetFriendTabSettingsEntries()
	local L = GetL()
	local entries = {}
	for _, sectionID in ipairs(self:GetFriendTabOrder()) do
		local definition = SECTION_BY_ID[sectionID]
		entries[#entries + 1] = {
			id = sectionID,
			key = sectionID,
			label = L[definition.labelKey] or sectionID,
			activeAtlas = definition.activeAtlas,
			inactiveAtlas = definition.inactiveAtlas,
			customTexture = definition.customTexture,
			fallback = definition.fallback,
		}
	end
	return entries
end

function FriendsUI:GetSectionForLegacyTabs(bottomTab, topTab)
	bottomTab = tonumber(bottomTab) or 1
	topTab = tonumber(topTab) or 1
	if bottomTab == 2 then
		return "who"
	elseif bottomTab == 3 then
		return "raid"
	elseif bottomTab == 4 then
		return "quick_join"
	elseif topTab == 2 then
		return "recent_allies"
	elseif topTab == 3 then
		return "recruit_a_friend"
	elseif topTab == 4 then
		return "guild"
	end
	return "friends"
end

function FriendsUI:GetSectionForSocialTab(tabType)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	local mapping = {
		[tab.Friends] = "friends",
		[tab.RecentAllies] = "recent_allies",
		[tab.QuickJoin] = "quick_join",
		[tab.FriendRequests] = "friend_requests",
		[tab.RecruitAFriend] = "recruit_a_friend",
		[tab.RaidList] = "raid",
	}
	return mapping[tabType]
end

function FriendsUI:GetSocialTabForSection(sectionID)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	local mapping = {
		friends = tab.Friends,
		recent_allies = tab.RecentAllies,
		quick_join = tab.QuickJoin,
		friend_requests = tab.FriendRequests,
		recruit_a_friend = tab.RecruitAFriend,
		raid = tab.RaidList,
	}
	return mapping[sectionID]
end

function FriendsUI:GetCapabilities()
	local bnetSupported = not BFL.IsBattleNetFriendsListSupported or BFL.IsBattleNetFriendsListSupported()
	local bnetEnabled = not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled()
	local recentEnabled = false
	if BFL.IsRetail and C_RecentAllies then
		if C_RecentAllies.IsSystemEnabled then
			local ok, enabled = pcall(C_RecentAllies.IsSystemEnabled)
			recentEnabled = ok and enabled == true
		elseif C_RecentAllies.IsRecentAlliesEnabled then
			local ok, enabled = pcall(C_RecentAllies.IsRecentAlliesEnabled)
			recentEnabled = ok and enabled == true
		end
	end
	local quickJoinEnabled = BFL.IsSocialQueueSupported and BFL.IsSocialQueueSupported()
	if quickJoinEnabled and BFL.IsSocialQueueEnabled then
		quickJoinEnabled = BFL.IsSocialQueueEnabled()
	end
	local rafEnabled = BFL.IsRAFSystemSupported and BFL.IsRAFSystemSupported()
	if rafEnabled and BFL.IsRAFSystemEnabled then
		rafEnabled = BFL.IsRAFSystemEnabled()
	end
	local rafPreviewEnabled = BFL.IsRAFPreviewActive and BFL:IsRAFPreviewActive()
	return {
		-- The Friends section also contains character friends and must remain
		-- reachable when Battle.net friends are unavailable.
		friends = true,
		recent_allies = recentEnabled,
		quick_join = quickJoinEnabled == true,
		friend_requests = bnetSupported and bnetEnabled,
		recruit_a_friend = rafPreviewEnabled == true or rafEnabled == true,
		raid = BFL.IsRetail == true and not self:AreRaidGroupsDisabled(),
		guild = BFL.IsGuildTabEnabled and BFL:IsGuildTabEnabled() or false,
		who = true,
	}
end

function FriendsUI:AreRaidGroupsDisabled()
	local gameRule = Enum and Enum.GameRule and Enum.GameRule.DisableRaidGroups
	if not (gameRule and C_GameRules and C_GameRules.IsGameRuleActive) then
		return false
	end
	local ok, disabled = pcall(C_GameRules.IsGameRuleActive, gameRule)
	return ok and disabled == true
end

function FriendsUI:ShouldShowSection(sectionID, capabilities, counts)
	capabilities = capabilities or self:GetCapabilities()
	if capabilities[sectionID] ~= true then
		return false
	end
	if not self:IsModernActive() then
		return true
	end
	if not self:IsFriendTabVisible(sectionID) then
		return false
	end
	if self:IsFriendTabPopulatedOnly(sectionID) then
		local count = counts and counts[sectionID]
		if count == nil then
			count = self:GetSectionCount(sectionID)
		end
		return (tonumber(count) or 0) > 0
	end
	return true
end

function FriendsUI:BuildAvailableSectionIDs(capabilities, counts)
	capabilities = capabilities or self:GetCapabilities()
	local result = {}
	local order = self:IsModernActive() and self:GetFriendTabOrder() or DEFAULT_SECTION_ORDER
	for _, sectionID in ipairs(order) do
		if self:ShouldShowSection(sectionID, capabilities, counts) then
			result[#result + 1] = sectionID
		end
	end
	return result
end

function FriendsUI:IsSectionAvailable(sectionID)
	local capabilities = self:GetCapabilities()
	return self:ShouldShowSection(sectionID, capabilities)
end

local function CaptureFrameState(frame)
	if not IsLayoutFrame(frame) then
		return nil
	end
	local points = {}
	for index = 1, frame:GetNumPoints() do
		points[index] = { frame:GetPoint(index) }
	end
	return {
		frame = frame,
		parent = frame:GetParent(),
		points = points,
		width = frame:GetWidth(),
		height = frame:GetHeight(),
		shown = frame:IsShown(),
		alpha = frame:GetAlpha(),
		frameLevel = frame:GetFrameLevel(),
	}
end

local function RestoreFrameState(state, restoreShown)
	if not state or not IsLayoutFrame(state.frame) then
		return
	end
	local frame = state.frame
	frame:SetParent(state.parent)
	frame:ClearAllPoints()
	for _, point in ipairs(state.points) do
		frame:SetPoint(unpack(point))
	end
	if #state.points <= 1 and state.width and state.height and state.width > 0 and state.height > 0 then
		frame:SetSize(state.width, state.height)
	end
	frame:SetAlpha(state.alpha or 1)
	if state.frameLevel then
		frame:SetFrameLevel(state.frameLevel)
	end
	if restoreShown then
		SafeShow(frame, state.shown)
	end
end

function FriendsUI:CaptureLegacyLayout()
	if self.legacyState or not BetterFriendsFrame then
		return
	end
	local frame = BetterFriendsFrame
	local fields = {
		"Inset",
		"ScrollFrame",
		"MinimalScrollBar",
		"RecentAlliesFrame",
		"RecruitAFriendFrame",
		"QuickJoinFrame",
		"WhoFrame",
		"RaidFrame",
		"GuildFrame",
		"AddFriendButton",
		"SendMessageButton",
		"RecruitmentButton",
		"FriendsTabHeader",
		"BottomTab1",
		"BottomTab2",
		"BottomTab3",
		"BottomTab4",
		"StreamerModeButton",
		"HelpButton",
		"IgnoreListWindow",
	}
	local state = { frames = {}, regions = {}, title = frame.TitleText and frame.TitleText:GetText() }
	for _, field in ipairs(fields) do
		state.frames[field] = CaptureFrameState(frame[field])
	end
	local nestedFrames = {
		["recentAllies.scrollBox"] = frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBox,
		["recentAllies.scrollBar"] = frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar,
		["recruitAFriend.scrollBox"] = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList and frame.RecruitAFriendFrame.RecruitList.ScrollBox,
		["recruitAFriend.scrollBar"] = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList and frame.RecruitAFriendFrame.RecruitList.ScrollBar,
		["quickJoin.scrollBar"] = frame.QuickJoinFrame and frame.QuickJoinFrame.ContentInset and frame.QuickJoinFrame.ContentInset.ScrollBar,
		["who.scrollBox"] = frame.WhoFrame and frame.WhoFrame.ScrollBox,
		["who.scrollBar"] = frame.WhoFrame and frame.WhoFrame.ScrollBar,
		["who.editBox"] = frame.WhoFrame and frame.WhoFrame.EditBox,
		["who.listInset"] = frame.WhoFrame and frame.WhoFrame.ListInset,
		["who.nameHeader"] = frame.WhoFrame and frame.WhoFrame.NameHeader,
		["who.columnDropdown"] = frame.WhoFrame and frame.WhoFrame.ColumnDropdown,
		["who.levelHeader"] = frame.WhoFrame and frame.WhoFrame.LevelHeader,
		["who.classHeader"] = frame.WhoFrame and frame.WhoFrame.ClassHeader,
		["who.refreshButton"] = frame.WhoFrame and frame.WhoFrame.WhoButton,
		["who.addFriendButton"] = frame.WhoFrame and frame.WhoFrame.AddFriendButton,
		["who.groupInviteButton"] = frame.WhoFrame and frame.WhoFrame.GroupInviteButton,
		["guild.scrollBox"] = frame.GuildFrame and frame.GuildFrame.ScrollBox,
		["guild.scrollBar"] = frame.GuildFrame and frame.GuildFrame.ScrollBar,
		["guild.searchBox"] = frame.GuildFrame and frame.GuildFrame.SearchBox,
		["guild.filterDropdown"] = frame.GuildFrame and frame.GuildFrame.FilterDropdown,
		["guild.sortDropdown"] = frame.GuildFrame and frame.GuildFrame.SortDropdown,
		["guild.actionsButton"] = frame.GuildFrame and frame.GuildFrame.ActionsButton,
		["guild.listInset"] = frame.GuildFrame and frame.GuildFrame.ListInset,
	}
	for key, nestedFrame in pairs(nestedFrames) do
		state.frames[key] = CaptureFrameState(nestedFrame)
	end
	local header = frame.FriendsTabHeader
	if header then
		state.searchInstruction = header.SearchBox
			and header.SearchBox.Instructions
			and header.SearchBox.Instructions:GetText()
		for _, field in ipairs({ "StatusDropdown", "BattlenetFrame", "SearchBox", "QuickFilterDropdown", "PrimarySortDropdown", "SecondarySortDropdown" }) do
			state.frames["header." .. field] = CaptureFrameState(header[field])
		end
		local bnetFrame = header.BattlenetFrame
		for _, field in ipairs({ "ContactsMenuButton", "SettingsButton", "BroadcastFrame" }) do
			state.frames["bnet." .. field] = CaptureFrameState(bnetFrame and bnetFrame[field])
		end
	end
	if frame.portrait and frame.portrait.GetTexture then
		state.portraitTexture = frame.portrait:GetTexture()
	end
	local regionMap = {
		["title"] = (frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText,
		["header.searchIcon"] = header and header.SearchBox and header.SearchBox.searchIcon,
		["header.searchInstructions"] = header and header.SearchBox and header.SearchBox.Instructions,
		["header.statusText"] = header and header.StatusDropdown
			and (header.StatusDropdown.Text or header.StatusDropdown.TextRegion or header.StatusDropdown.SelectionText),
		["who.searchIcon"] = frame.WhoFrame and frame.WhoFrame.EditBox and frame.WhoFrame.EditBox.searchIcon,
		["who.searchInstructions"] = frame.WhoFrame and frame.WhoFrame.EditBox and frame.WhoFrame.EditBox.Instructions,
		["who.searchBackdrop"] = frame.WhoFrame and frame.WhoFrame.EditBox and frame.WhoFrame.EditBox.Backdrop,
		["who.totals"] = frame.WhoFrame and frame.WhoFrame.ListInset and frame.WhoFrame.ListInset.Totals,
		["guild.searchIcon"] = frame.GuildFrame and frame.GuildFrame.SearchBox and frame.GuildFrame.SearchBox.searchIcon,
		["guild.searchInstructions"] = frame.GuildFrame and frame.GuildFrame.SearchBox and frame.GuildFrame.SearchBox.Instructions,
		["guild.searchBackdrop"] = frame.GuildFrame and frame.GuildFrame.SearchBox and frame.GuildFrame.SearchBox.Backdrop,
	}
	for key, region in pairs(regionMap) do
		state.regions[key] = CaptureRegionState(region)
	end
	self.legacyState = state
end

function FriendsUI:ApplyModernActionButtonTemplates()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	local who = frame.WhoFrame
	if who then
		EnsureModernActionButton(who, "WhoButton")
		EnsureModernActionButton(who, "AddFriendButton")
		EnsureModernActionButton(who, "GroupInviteButton")
	end
	local raid = frame.RaidFrame
	local control = raid and raid.ControlPanel
	if control then
		EnsureModernActionButton(control, "RaidInfoButton")
		local readyCheck = EnsureModernActionButton(control, "ReadyCheckButton")
		ConfigureModernReadyCheckButton(readyCheck, control.BFL_LegacyReadyCheckButton)
	end
	if raid then
		EnsureModernActionButton(raid, "RaidToolsButton")
		EnsureModernActionButton(raid, "ConvertToRaidButton")
	end
end

function FriendsUI:RestoreLegacyActionButtonTemplates()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	local who = frame.WhoFrame
	if who then
		RestoreLegacyActionButton(who, "WhoButton")
		RestoreLegacyActionButton(who, "AddFriendButton")
		RestoreLegacyActionButton(who, "GroupInviteButton")
	end
	local raid = frame.RaidFrame
	local control = raid and raid.ControlPanel
	if control then
		RestoreLegacyActionButton(control, "RaidInfoButton")
		RestoreLegacyActionButton(control, "ReadyCheckButton")
	end
	if raid then
		RestoreLegacyActionButton(raid, "RaidToolsButton")
		RestoreLegacyActionButton(raid, "ConvertToRaidButton")
	end
end

function FriendsUI:CreateModernRoot()
	if self.root or not BetterFriendsFrame or not BFL.IsRetail then
		return self.root
	end
	local root = CreateFrame("Frame", nil, BetterFriendsFrame, "BFLModernFriendsRootTemplate")
	root:SetAllPoints(BetterFriendsFrame)
	root:SetFrameLevel(BetterFriendsFrame:GetFrameLevel() + 1)
	root.PortraitOverlay:SetFrameLevel(root:GetFrameLevel() + 20)
	root:Hide()
	self.root = root
	local portraitButton = root.PortraitOverlay.HitButton
	portraitButton.BFL_DarkInvisibleOverlayButton = true
	portraitButton.Glow = root.PortraitOverlay.Glow
	portraitButton:EnableMouse(true)
	portraitButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	portraitButton:SetScript("OnClick", function()
		local Changelog = BFL:GetModule("Changelog")
		if Changelog and Changelog.ToggleChangelog then
			Changelog:ToggleChangelog()
		end
	end)
	portraitButton:SetScript("OnEnter", function(button)
		local Changelog = BFL:GetModule("Changelog")
		if Changelog and Changelog.OnPortraitEnter then
			Changelog:OnPortraitEnter(button)
		end
	end)
	portraitButton:SetScript("OnLeave", function()
		BFL_Tooltip:Hide()
	end)
	local Changelog = BFL:GetModule("Changelog")
	if Changelog and Changelog.CheckVersion then
		Changelog:CheckVersion()
	end

	if root.FilterBar.SortButton.SetupMenu then
		root.FilterBar.SortButton:SetupMenu(function(_, rootDescription)
			self:PopulateSortMenu(rootDescription)
		end)
	else
		root.FilterBar.SortButton:SetScript("OnClick", function(button)
			self:OpenSortMenu(button)
		end)
	end
	root.FilterBar.SortButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetText(GetL().FRIENDS_UI_SORT_TOOLTIP or "Sorting")
		GameTooltip:Show()
	end)
	root.FilterBar.SortButton:SetScript("OnLeave", GameTooltip_Hide)
	self:RefreshSortButtonText()

	local filterDropdown = root.FilterBar.FilterDropdown
	local QuickFilters = BFL:GetModule("QuickFilters")
	if filterDropdown and QuickFilters and QuickFilters.InitDropdown then
		QuickFilters:InitDropdown(filterDropdown)
		filterDropdown._bflModernInitialized = true
	end
	local recentFilterDropdown = root.FilterBar.RecentFilterDropdown
	local RecentAllies = BFL:GetModule("RecentAllies")
	if recentFilterDropdown and RecentAllies and RecentAllies.InitializeFilterDropdown then
		RecentAllies:InitializeFilterDropdown(recentFilterDropdown)
	end

	local menuButton = root.BattleNetBar.MenuButton
	menuButton:SetScript("OnClick", function(button)
		BetterFriendsFrame_ShowContactsMenu(button)
	end)
	menuButton:SetScript("OnEnter", function(button)
		BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(BFL_Tooltip, CONTACTS_MENU_NAME or "Menu")
		BFL_Tooltip:Show()
	end)
	menuButton:SetScript("OnLeave", BFL_Tooltip_Hide)
	menuButton:SetScript("OnMouseDown", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(1, -1)
		end
	end)
	menuButton:SetScript("OnMouseUp", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(-1, 1)
		end
	end)

	local addFriendButton = root.BottomActionBar.AddFriendButton
	addFriendButton:SetText(ADD_NEW_FRIEND or ADD_FRIEND or "Add Friend")
	addFriendButton:SetScript("OnClick", function()
		self:PerformContactAction()
	end)
	addFriendButton:HookScript("OnEnter", function(button)
		local chrome = self:GetContactChrome(self.selectedSection or "friends")
		if not button:IsEnabled() and chrome.action == "add_friend" then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 6, 0)
			GameTooltip_AddErrorLine(GameTooltip, ADDING_FRIENDS_DISABLED or "Adding friends is currently disabled.")
			GameTooltip:Show()
		elseif not button:IsEnabled() and chrome.action == "quick_join" and button.tooltip then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 6, 0)
			GameTooltip_AddErrorLine(GameTooltip, button.tooltip)
			GameTooltip:Show()
		end
	end)
	addFriendButton:HookScript("OnLeave", GameTooltip_Hide)

	local copyBattleTagButton = root.BattleNetBar.CopyBattleTagButton
	copyBattleTagButton:SetScript("OnClick", function()
		self:CopyBattleTag()
	end)
	copyBattleTagButton:SetScript("OnMouseDown", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(1, -1)
		end
		if button.HighlightTexture and button.HighlightTexture.AdjustPointsOffset then
			button.HighlightTexture:AdjustPointsOffset(1, -1)
		end
	end)
	copyBattleTagButton:SetScript("OnMouseUp", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(-1, 1)
		end
		if button.HighlightTexture and button.HighlightTexture.AdjustPointsOffset then
			button.HighlightTexture:AdjustPointsOffset(-1, 1)
		end
	end)
	copyBattleTagButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetText(GetL().FRIENDS_UI_COPY_BATTLETAG or "Copy BattleTag")
		GameTooltip:Show()
	end)
	copyBattleTagButton:SetScript("OnLeave", GameTooltip_Hide)

	self:CreateNavigationTabs()
	self:InitializeRequestsScrollBox()
	return root
end

function FriendsUI:CreateNavigationTabs()
	if self.sideTabs or not self.root then
		return
	end
	self.sideTabs = {}
	for index, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = CreateFrame("Button", nil, self.root, "BFLModernSideTabTemplate")
		tab.sectionID = definition.id
		tab.activeAtlas = definition.activeAtlas
		tab.inactiveAtlas = definition.inactiveAtlas
		tab.fallbackTexture = definition.fallback
		local onClick = function(button)
			self:SelectSection(button.sectionID)
		end
		if tab.SetCustomOnMouseUpHandler then
			tab:SetCustomOnMouseUpHandler(function(button, mouseButton, upInside)
				if mouseButton == "LeftButton" and upInside then
					onClick(button)
				end
			end)
		else
			tab:SetScript("OnClick", onClick)
		end
		tab:SetScript("OnEnter", function(button)
			local _, themed = self:GetModernThemeColors()
			if not themed and button.HighlightTexture then
				button.HighlightTexture:Show()
			end
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(button.tooltipText or button.sectionID)
			if button.disabledReason then
				GameTooltip:AddLine(button.disabledReason, 1, 0.82, 0, true)
			end
			GameTooltip:Show()
		end)
		tab:SetScript("OnLeave", function(button)
			local _, themed = self:GetModernThemeColors()
			if not themed and button.HighlightTexture then
				button.HighlightTexture:Hide()
			end
			GameTooltip_Hide()
		end)
		self.sideTabs[index] = tab
		definition.tab = tab
	end
end

function FriendsUI:IsStoryRaidActive()
	if not (DifficultyUtil and DifficultyUtil.InStoryRaid) then
		return false
	end
	local ok, active = pcall(DifficultyUtil.InStoryRaid)
	return ok and active == true
end

function FriendsUI:GetQuickJoinCount()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.GetAllGroups then
		local ok, groups = pcall(QuickJoin.GetAllGroups, QuickJoin)
		if ok and type(groups) == "table" then
			return #groups
		end
	end
	if C_SocialQueue and C_SocialQueue.GetAllGroups then
		local ok, groups = pcall(C_SocialQueue.GetAllGroups)
		if ok and type(groups) == "table" then
			return #groups
		end
	end
	return 0
end

function FriendsUI:GetSectionCount(sectionID, inviteCount, quickJoinCount)
	if sectionID == "friend_requests" then
		return inviteCount == nil and GetFriendInviteCount() or inviteCount
	elseif sectionID == "quick_join" then
		return quickJoinCount == nil and self:GetQuickJoinCount() or quickJoinCount
	end
	return 0
end

function FriendsUI:ShouldStartRequestGlow(newInvite, selectedSection)
	return newInvite == true and (selectedSection or self.selectedSection) ~= "friend_requests"
end

function FriendsUI:LayoutNavigationTabs(sectionIDs, themed)
	if not self.sideTabs then
		return
	end
	if themed == nil then
		local palette
		palette, themed = self:GetModernThemeColors()
		themed = themed and not palette.preserveNativeSideTabs
	end
	local orderedSections = sectionIDs
	if not orderedSections then
		orderedSections = {}
		for _, sectionID in ipairs(self:GetFriendTabOrder()) do
			local definition = SECTION_BY_ID[sectionID]
			local tab = definition and definition.tab
			if tab and tab.IsShown and tab:IsShown() then
				orderedSections[#orderedSections + 1] = sectionID
			end
		end
	end
	local previous
	for _, sectionID in ipairs(orderedSections) do
		local definition = SECTION_BY_ID[sectionID]
		local tab = definition and definition.tab
		if tab then
			tab:ClearAllPoints()
			if previous then
				tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -3)
			else
				tab:SetPoint(
					"TOPLEFT",
					BetterFriendsFrame,
					"TOPRIGHT",
					themed and MODERN_THEMED_SIDE_TAB_OFFSET_X or 0,
					-122
				)
			end
			previous = tab
		end
	end
end

function FriendsUI:RefreshNavigation()
	local modernActive = self:IsModernActive()
	if modernActive then
		self:HideLegacyTabs()
	end
	if not self.sideTabs then
		return
	end
	local capabilities = self:GetCapabilities()
	local counts = {
		friend_requests = self:GetSectionCount("friend_requests"),
		quick_join = self:GetSectionCount("quick_join"),
	}
	local availableSections = self:BuildAvailableSectionIDs(capabilities, counts)
	local visibleSections = {}
	for _, sectionID in ipairs(availableSections) do
		visibleSections[sectionID] = true
	end
	local L = GetL()
	for _, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = definition.tab
		local available = visibleSections[definition.id] == true
		tab.tooltipText = L[definition.labelKey] or definition.id
		tab.disabledReason = nil
		tab:SetEnabled(available)
		tab:SetShown(available)
		local selected = self.selectedSection == definition.id
		if tab.SelectedTexture then
			tab.SelectedTexture:SetShown(selected)
		end
		local icon = tab.Icon or tab.icon
		ApplySectionIcon(icon, definition, selected)
		if tab.Count then
			local count = counts[definition.id] or 0
			tab.Count:SetShown(count > 0)
			tab.Count:SetText(count > 0 and count or "")
			if tab.Icon then
				tab.Icon:ClearAllPoints()
				tab.Icon:SetPoint("CENTER", tab, "CENTER", definition.iconOffsetX or -2, count > 0 and 5 or 0)
			end
		end
		if definition.id == "raid" and available and self:IsStoryRaidActive() then
			tab:SetEnabled(false)
			tab.disabledReason = L.FRIENDS_UI_RAID_STORY_DISABLED or "Unavailable during a Story raid."
		end
	end
	local palette, themed = self:GetModernThemeColors()
	self:LayoutNavigationTabs(availableSections, themed and not palette.preserveNativeSideTabs)
	if
		modernActive
		and self.selectedSection
		and not visibleSections[self.selectedSection]
		and availableSections[1]
		and not self.refreshingFriendTabSelection
	then
		self.refreshingFriendTabSelection = true
		self:SelectSection(availableSections[1])
		self.refreshingFriendTabSelection = false
		return
	end
	-- Navigation refreshes happen for counters, availability changes, and every
	-- Modern section switch. The frame palette and content geometry are already
	-- applied by ThemeManager/ApplyModernContentLayout; rerunning ApplyTheme here
	-- recursively laid out and re-skinned the whole visible UI for a tab update.
	if modernActive then
		self:RefreshModernSideTabSelection()
	elseif self.root and self.root:IsShown() then
		self:ApplyTheme(self.currentTheme)
	end
end

function FriendsUI:RefreshModernSideTabSelection()
	if not (self:IsModernActive() and self.sideTabs) then
		return
	end

	local _, themed = self:GetModernThemeColors()
	local SkinEngine = themed and BFL:GetModule("SkinEngine") or nil
	local useSkinEngine = SkinEngine and SkinEngine.IsActive and SkinEngine:IsActive()

	-- LargeSideTabButtonTemplate handles MouseDown before BFL switches the
	-- section. Refresh the native selection and hover textures for every theme
	-- immediately afterwards. External skins such as ElvUI reuse those layers;
	-- without this final pass, a legacy top/bottom-tab update can leave a second
	-- side tab highlighted. Dark/Custom then refresh their managed backdrop too.
	for _, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = definition.tab
		if tab then
			local selected = self.selectedSection == definition.id
			if tab.SelectedTexture then
				tab.SelectedTexture:SetShown(selected)
			end
			if tab.HighlightTexture then
				tab.HighlightTexture:SetShown(BFL:IsRegionMouseOver(tab))
			end
			if useSkinEngine then
				tab.BFL_DarkManagedSelection = selected
				tab.BFL_DarkButtonStateKey = nil
				SkinEngine:ApplyButtonState(tab)
				if tab.BFL_DarkBackdrop then
					tab.BFL_DarkBackdrop:Show()
				end
			end
		end
	end
end

function FriendsUI:RefreshFriendTabSettings()
	if not self:IsModernActive() or not self.sideTabs then
		return
	end
	self:RefreshNavigation()
end

function FriendsUI:StartRequestGlow()
	local definition = SECTION_BY_ID.friend_requests
	local tab = definition and definition.tab
	if not tab or self.selectedSection == "friend_requests" then
		return
	end
	tab.BFL_RequestGlowActive = true
	local palette, themed = self:GetModernThemeColors()
	if themed and not palette.preserveNativeSideTabs and tab.ThemeGlowAnimation then
		SetModernSideTabGlowTheme(tab, palette, true)
	elseif tab.SetTabGlowAnimationPlaying then
		tab:SetTabGlowAnimationPlaying(true)
	elseif tab.TabGlowAnimation and tab.TabGlowAnimation.Play then
		tab.TabGlowAnimation:Play()
	end
end

function FriendsUI:StopRequestGlow()
	local definition = SECTION_BY_ID.friend_requests
	local tab = definition and definition.tab
	if not tab then
		return
	end
	tab.BFL_RequestGlowActive = nil
	if tab.SetTabGlowAnimationPlaying then
		tab:SetTabGlowAnimationPlaying(false)
	elseif tab.TabGlowAnimation and tab.TabGlowAnimation.Stop then
		tab.TabGlowAnimation:Stop()
	end
	if tab.ThemeGlowAnimation and tab.ThemeGlowAnimation.Stop then
		tab.ThemeGlowAnimation:Stop()
	end
	if tab.ThemeGlow then
		tab.ThemeGlow:Hide()
	end
end

function FriendsUI:RefreshBattleTag()
	if not (self.root and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader) then
		return
	end
	local header = BetterFriendsFrame.FriendsTabHeader
	local bnetFrame = header.BattlenetFrame
	if bnetFrame and bnetFrame.Tag then
		local PreviewMode = BFL:GetModule("PreviewMode")
		local battleTag = PreviewMode
			and PreviewMode.GetPreviewBattleTag
			and PreviewMode:GetPreviewBattleTag()
		if not battleTag and BNGetInfo then
			local ok, _, realBattleTag = pcall(BNGetInfo)
			battleTag = ok and realBattleTag or nil
		end
		if battleTag then
			self.battleTag = battleTag
			local _, themed = self:GetModernThemeColors()
			local StreamerMode = BFL.StreamerMode or BFL:GetModule("StreamerMode")
			local streamerActive = StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive()
			local displayBattleTag = streamerActive
				and BetterFriendlistDB
				and BetterFriendlistDB.streamerModeHeaderText
				or battleTag
			local marker = not streamerActive and displayBattleTag:find("#", 1, true)
			local display = themed and displayBattleTag
				or (
					marker
						and (
							displayBattleTag:sub(1, marker - 1)
							.. "|cff416380"
							.. displayBattleTag:sub(marker)
							.. "|r"
						)
						or displayBattleTag
				)
			bnetFrame.Tag:SetText(display)
		end
	end
end

function FriendsUI:CopyBattleTag()
	self:RefreshBattleTag()
	local value = self.battleTag
	if not value or value == "" then
		return
	end
	local Changelog = BFL:GetModule("Changelog")
	if Changelog and Changelog.ShowCopyDialog then
		Changelog:ShowCopyDialog(value, GetL().FRIENDS_UI_COPY_BATTLETAG or "Copy BattleTag")
	end
end

function FriendsUI:RefreshSortButtonText()
	local button = self.root and self.root.FilterBar and self.root.FilterBar.SortButton
	if not button then
		return
	end
	local FriendsList = BFL:GetModule("FriendsList")
	local Registry = BFL:GetModule("FilterSortRegistry")
	local text = SORT or (SORT_BY or GetL().RAID_TOOLS_SORT_HEADER or "Sort"):gsub(":%s*$", "")
	if FriendsList and Registry and Registry.GetSorterIcon and Registry.FormatIcon then
		local primary = Registry:FormatIcon(Registry:GetSorterIcon(FriendsList.sortMode), 11)
		text = string.format("%s (%s", text, primary)
		if FriendsList.secondarySort and FriendsList.secondarySort ~= "none" then
			local secondary = Registry:FormatIcon(Registry:GetSorterIcon(FriendsList.secondarySort), 11)
			text = string.format("%s %s", text, secondary)
		end
		text = text .. ")"
	end
	if BFL.SetDropdownText then
		BFL.SetDropdownText(button, text)
	elseif button.SetText then
		button:SetText(text)
	end
	ConstrainModernDropdownText(button, 1)
end

function FriendsUI:LayoutBattleTagActions()
	local root = self.root
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	local bnetFrame = header and header.BattlenetFrame
	local tag = bnetFrame and bnetFrame.Tag
	if not (root and tag) then
		return
	end
	local headerControlOffsetY = self:GetModernHeaderControlOffsetY()

	if header.StatusDropdown then
		header.StatusDropdown:ClearAllPoints()
		header.StatusDropdown:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
	end
	if root.BattleNetBar.MenuButton then
		root.BattleNetBar.MenuButton:ClearAllPoints()
		root.BattleNetBar.MenuButton:SetPoint("RIGHT", root.BattleNetBar, "RIGHT", -8, headerControlOffsetY)
	end

	local copyButton = root.BattleNetBar.CopyBattleTagButton
	copyButton:ClearAllPoints()
	copyButton:SetPoint("LEFT", tag, "RIGHT", 8, 0)
	copyButton:SetFrameLevel(root.BattleNetBar:GetFrameLevel() + 4)

	local streamerButton = frame.StreamerModeButton
	if streamerButton then
		streamerButton:SetParent(root.BattleNetBar)
		streamerButton:ClearAllPoints()
		streamerButton:SetPoint("RIGHT", bnetFrame, "RIGHT", -7, 0)
		streamerButton:SetSize(20, 20)
		streamerButton:SetFrameLevel(root.BattleNetBar:GetFrameLevel() + 4)
	end
	if bnetFrame then
		bnetFrame:ClearAllPoints()
		bnetFrame:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
		bnetFrame:SetPoint("RIGHT", root.BattleNetBar.MenuButton, "LEFT", -7, headerControlOffsetY)
	end
end

function FriendsUI:GetSortMenuItems()
	local FriendsList = BFL:GetModule("FriendsList")
	local Registry = BFL:GetModule("FilterSortRegistry")
	if not FriendsList or not Registry then
		return nil
	end
	local L = GetL()
	local primary = {
		type = "submenu",
		text = L.SORT_PRIMARY_LABEL or "Primary sort",
		items = {},
	}
	local secondary = {
		type = "submenu",
		text = L.SORT_SECONDARY_LABEL or "Secondary sort",
		items = {
			{
				type = "radio",
				text = L.SORT_NONE or NONE or "None",
				value = "none",
				checked = function(value)
					return FriendsList.secondarySort == value
				end,
				func = function(value)
					FriendsList:SetSecondarySortMode(value)
					self:RefreshSortButtonText()
				end,
			},
		},
	}
	for _, sorter in ipairs(Registry:GetVisibleSorters()) do
		local sorterText = sorter.name
		if Registry.FormatIcon and sorter.icon then
			sorterText = Registry:FormatIcon(sorter.icon, 16) .. " " .. sorterText
		end
		primary.items[#primary.items + 1] = {
			type = "radio",
			text = sorterText,
			value = sorter.id,
			checked = function(value)
				return FriendsList.sortMode == value
			end,
			func = function(value)
				FriendsList:SetSortMode(value)
				self:RefreshSortButtonText()
			end,
		}
		if sorter.id ~= FriendsList.sortMode then
			secondary.items[#secondary.items + 1] = {
				type = "radio",
				text = sorterText,
				value = sorter.id,
				checked = function(value)
					return FriendsList.secondarySort == value
				end,
				func = function(value)
					FriendsList:SetSecondarySortMode(value)
					self:RefreshSortButtonText()
				end,
			}
		end
	end
	return { primary, secondary }
end

function FriendsUI:PopulateSortMenu(rootDescription)
	local items = self:GetSortMenuItems()
	if items and BFL.PopulateSimpleMenu then
		return BFL.PopulateSimpleMenu(rootDescription, items)
	end
	return false
end

function FriendsUI:OpenSortMenu(anchor)
	local items = self:GetSortMenuItems()
	if items and BFL.OpenSimpleContextMenu then
		return BFL.OpenSimpleContextMenu(anchor, "BFL_ModernSortMenu", items)
	end
	return false
end

local function GetInviteInfo(index)
	if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
		return BFL.MockFriendInvites.invites[index]
	end
	if BFL.GetBNetFriendInviteInfo then
		return BFL.GetBNetFriendInviteInfo(index)
	end
	if BNGetFriendInviteInfo then
		return BNGetFriendInviteInfo(index)
	end
	return nil
end

function FriendsUI:NormalizeInvite(index)
	local raw = GetInviteInfo(index)
	if type(raw) == "table" then
		return {
			inviteIndex = index,
			inviteID = raw.inviteID or raw.id,
			accountName = raw.accountName or raw.name or UNKNOWN,
			friendLevel = raw.friendLevel,
			creationTimestamp = raw.creationTimestamp or raw.createdAt,
		}
	end
	local inviteID, accountName, isBattleTag, creationTimestamp = GetInviteInfo(index)
	if inviteID == nil then
		return nil
	end
	return {
		inviteIndex = index,
		inviteID = inviteID,
		accountName = accountName or UNKNOWN,
		friendLevel = isBattleTag,
		creationTimestamp = creationTimestamp,
	}
end

function FriendsUI:GetFriendLevelLabel(friendLevel)
	local L = GetL()
	local level = Enum and Enum.BattleNetFriendLevel
	if level then
		if friendLevel == level.RealID then
			return L.FRIENDS_UI_REQUEST_REAL_ID or "Real ID"
		elseif friendLevel == level.BattleTag then
			return L.FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag"
		elseif friendLevel == level.Title then
			return L.FRIENDS_UI_REQUEST_TITLE or "World of Warcraft"
		end
	end
	if friendLevel == false or friendLevel == 0 then
		return L.FRIENDS_UI_REQUEST_REAL_ID or "Real ID"
	end
	return L.FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag"
end

function FriendsUI:IsRealIDInvite(friendLevel)
	local level = Enum and Enum.BattleNetFriendLevel
	return level and friendLevel == level.RealID or false
end

function FriendsUI:IsTitleInvite(friendLevel)
	local level = Enum and Enum.BattleNetFriendLevel
	return level and friendLevel == level.Title or false
end

function FriendsUI:InitializeRequestHeader(button, elementData)
	if button and button.ButtonText then
		button.ButtonText:SetText(elementData.headerText or "")
	end
end

function FriendsUI:RemoveMockInvite(inviteID, accepted)
	local mockInvites = BFL.MockFriendInvites
	if not (mockInvites and mockInvites.enabled) then
		return false
	end
	for index, invite in ipairs(mockInvites.invites or {}) do
		if invite.inviteID == inviteID then
			table.remove(mockInvites.invites, index)
			return true
		end
	end
	return false
end

function FriendsUI:OpenRequestDeclineMenu(button)
	if not (button and button.inviteID and BFL.OpenSimpleContextMenu) then
		return
	end
	local inviteID = button.inviteID
	local accountName = button.accountName
	local items = {
		{
			text = BFL.L.DECLINE or DECLINE or "Decline",
			func = function()
				if not self:RemoveMockInvite(inviteID, false) and BNDeclineFriendInvite then
					BNDeclineFriendInvite(inviteID)
				end
				self:RefreshRequests()
			end,
		},
	}
	if not (BFL.MockFriendInvites and BFL.MockFriendInvites.enabled) then
		items[#items + 1] = {
			text = REPORT_PLAYER or "Report Player",
			func = function()
				if C_ReportSystem and C_ReportSystem.OpenReportPlayerDialog then
					C_ReportSystem.OpenReportPlayerDialog(
						C_ReportSystem.ReportType.InappropriateBattleNetName,
						accountName
					)
				end
			end,
		}
		items[#items + 1] = {
			text = BLOCK_INVITES or "Block Invites",
			func = function()
				if BNSetBlocked then
					BNSetBlocked(inviteID, true)
				end
			end,
		}
	end
	BFL.OpenSimpleContextMenu(button, "BFL_ModernFriendRequestDeclineDropdown", items)
end

local function InitializeScaledRequestMenuElement(description)
	if description and description.AddInitializer and SocialUIUtil
		and SocialUIUtil.InitializeUserScaledDropdownButton
	then
		description:AddInitializer(SocialUIUtil.InitializeUserScaledDropdownButton)
	end
end

function FriendsUI:SetupRequestDeclineButton(declineButton)
	if not declineButton or declineButton._bflRequestMenuInitialized then
		return
	end
	declineButton._bflRequestMenuInitialized = true

	if not declineButton.SetupMenu then
		declineButton:SetScript("OnClick", function(button)
			self:OpenRequestDeclineMenu(button)
		end)
		return
	end

	declineButton:SetupMenu(function(dropdown, rootDescription)
		if rootDescription.SetTag then
			rootDescription:SetTag("MENU_FRIEND_REQUESTS_DECLINE")
		end

		local decline = rootDescription:CreateButton(DECLINE or BFL.L.DECLINE or "Decline", function()
			if StaticPopup_Hide then
				StaticPopup_Hide("CONFIRM_BLOCK_INVITES")
			end
			if not self:RemoveMockInvite(dropdown.inviteID, false) and BNDeclineFriendInvite then
				BNDeclineFriendInvite(dropdown.inviteID)
			end
			self:RefreshRequests()
		end)
		InitializeScaledRequestMenuElement(decline)

		if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
			return
		end

		local report = rootDescription:CreateButton(REPORT_PLAYER or "Report Player", function()
			local inviteInfo = C_BattleNet
				and C_BattleNet.GetFriendInviteInfo
				and C_BattleNet.GetFriendInviteInfo(dropdown.inviteIndex)
			local bnetIDAccount = inviteInfo and inviteInfo.inviteID or dropdown.inviteID
			local accountName = inviteInfo and inviteInfo.accountName or dropdown.accountName
			if PlayerLocation and ReportInfo and ReportFrame and Enum and Enum.ReportType then
				local playerLocation = PlayerLocation:CreateFromBattleNetID(bnetIDAccount)
				local reportInfo = ReportInfo:CreateReportInfoFromType(Enum.ReportType.Friend)
				ReportFrame:InitiateReport(reportInfo, accountName, playerLocation, bnetIDAccount ~= nil)
			end
		end)
		InitializeScaledRequestMenuElement(report)

		local modeSupportsStaticPopups = not (C_Glue and C_Glue.IsOnGlueScreen and C_Glue.IsOnGlueScreen())
		if modeSupportsStaticPopups then
			local block = rootDescription:CreateButton(BLOCK_INVITES or "Block Invites", function()
				local inviteInfo = C_BattleNet
					and C_BattleNet.GetFriendInviteInfo
					and C_BattleNet.GetFriendInviteInfo(dropdown.inviteIndex)
				local inviteID = inviteInfo and inviteInfo.inviteID or dropdown.inviteID
				local accountName = inviteInfo and inviteInfo.accountName or dropdown.accountName
				if StaticPopup_Show then
					StaticPopup_Show("CONFIRM_BLOCK_INVITES", accountName, nil, inviteID)
				elseif BNSetBlocked then
					BNSetBlocked(inviteID, true)
				end
			end)
			InitializeScaledRequestMenuElement(block)
		end
	end)
end

function FriendsUI:InitializeRequestCard(button, elementData)
	button.inviteIndex = elementData.inviteIndex
	button.inviteID = elementData.inviteID
	button.accountName = elementData.accountName
	button.Name:SetText(elementData.accountName or UNKNOWN)
	button.FriendType:SetText(self:GetFriendLevelLabel(elementData.friendLevel))
	local age
	if elementData.creationTimestamp and SecondsToTime then
		age = SecondsToTime(math.max(0, time() - elementData.creationTimestamp))
	end
	button.RequestTimestamp:SetText(age and string.format(GetL().FRIENDS_UI_REQUEST_RECEIVED or "%s ago", age) or "")
	button.AcceptButton:SetText(ACCEPT or GetL().ACCEPT or "Accept")
	button.AcceptButton:SetScript("OnClick", function()
		if self:RemoveMockInvite(button.inviteID, true) then
			-- The deterministic preview fixture is local and must never call the live API.
		elseif BNAcceptFriendInvite and button.inviteID then
			BNAcceptFriendInvite(button.inviteID)
		end
		self:RefreshRequests()
	end)
	button.DeclineButton.inviteIndex = button.inviteIndex
	button.DeclineButton.inviteID = button.inviteID
	button.DeclineButton.accountName = button.accountName
	self:SetupRequestDeclineButton(button.DeclineButton)
	ApplyAtlasTexture(button.Background, self:IsTitleInvite(elementData.friendLevel) and "friends-card-default" or "friends-card-battleNet")
	self:StyleRequestCard(button)
end

function FriendsUI:InitializeRequestsScrollBox()
	if self.requestsInitialized or not (self.root and BFL.HasModernScrollBox) then
		return
	end
	local requests = self.root.RequestsFrame
	local view = CreateScrollBoxListLinearView()
	view:SetElementFactory(function(factory, elementData)
		if elementData and elementData.headerText then
			factory("BFLModernFriendRequestHeaderTemplate", function(button, data)
				self:InitializeRequestHeader(button, data)
			end)
		elseif elementData and elementData.isSpacer then
			factory("BFLModernFriendRequestSpacerTemplate")
		else
			factory("BFLModernFriendRequestCardTemplate", function(button, data)
				self:InitializeRequestCard(button, data)
			end)
		end
	end)
	view:SetElementExtentCalculator(function(_, elementData)
		local function Scale(value)
			if TextSizeManager and TextSizeManager.GetScaledValue then
				return TextSizeManager:GetScaledValue(value)
			end
			return value
		end
		if elementData and elementData.headerText then
			return Scale(24)
		elseif elementData and elementData.isSpacer then
			return Scale(2)
		end
		return Scale(70)
	end)
	BFL.InitScrollBoxListWithScrollBar(requests.ScrollBox, requests.ScrollBar, view)
	self.requestsView = view
	self.requestsInitialized = true
	requests.EmptyLabel:SetText(GetL().FRIENDS_UI_REQUESTS_EMPTY or "No pending friend requests")
	local warning = requests.RealIDWarning
	local scrollableWarningText = warning.ScrollableWarningText
	local warningScrollBox = scrollableWarningText and scrollableWarningText.GetScrollBox and scrollableWarningText:GetScrollBox()
	if
		warningScrollBox
		and warning.ScrollBar
		and ScrollUtil
		and ScrollUtil.RegisterScrollBoxWithScrollBar
		and not warning.BFL_ScrollBoxRegistered
	then
		ScrollUtil.RegisterScrollBoxWithScrollBar(warningScrollBox, warning.ScrollBar)
		warning.BFL_ScrollBoxRegistered = true
	end
	if warningScrollBox and warningScrollBox.SetEdgeFadeLength then
		warningScrollBox:SetEdgeFadeLength(10)
	end
	local warningText = scrollableWarningText and scrollableWarningText.GetFontString and scrollableWarningText:GetFontString()
	warning.Text = warningText
	if warningText and warningText.SetJustifyH then
		warningText:SetJustifyH("CENTER")
	end
	if scrollableWarningText and scrollableWarningText.SetText then
		scrollableWarningText:SetText(
		SOCIAL_UI_FRIEND_REQUESTS_REAL_ID_WARNING
			or GetL().FRIENDS_UI_REAL_ID_WARNING
			or "Real ID requests reveal your real name."
		)
	end
	if warningText and warningText.SetTextColor then
		warningText:SetTextColor(1, 1, 1, 1)
	end
	ApplyAtlasTexture(warning.PlayerIcon, "friends-icon-addFriend", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-plus.blp")
	ApplyAtlasTexture(warning.BattleNetIcon, "friends-icon-addFriend-logo-battleNet", "Interface\\AddOns\\BetterFriendlist\\Icons\\star.blp")
	warning.ContinueButton:SetText(CONTINUE or GetL().CONTINUE or "Continue")
	warning:EnableMouse(true)
	if warning.EnableMouseWheel then
		warning:EnableMouseWheel(true)
	end
	if not warning.BFL_OverlayLayoutHooked then
		warning.BFL_OverlayLayoutHooked = true
		warning:HookScript("OnShow", function()
			self:LayoutRealIDWarning()
		end)
	end
	warning.ContinueButton:SetScript("OnClick", function()
		if SetCVar then
			SetCVar("pendingInviteInfoShown", "1")
		end
		warning:Hide()
		self:LayoutRequestsFrame()
	end)
end

function FriendsUI:GetContactChrome(sectionID)
	return CONTACT_CHROME[sectionID] or {}
end

function FriendsUI:IsSimpleModeEnabled()
	local db = GetDB()
	return db and db.simpleMode == true
end

function FriendsUI:IsSimpleModeContactSection(sectionID)
	return self:IsSimpleModeEnabled() and (sectionID == "friends" or sectionID == "recent_allies")
end

function FriendsUI:ShouldShowSimpleModeSearch(sectionID)
	if not self:IsSimpleModeContactSection(sectionID) then
		return false
	end
	local db = GetDB()
	return not db or db.simpleModeShowSearch ~= false
end

function FriendsUI:DoesSimpleModeHideFilterBar(sectionID)
	-- Legacy Simple Mode compacts the Contacts surface, while directory tools
	-- such as Who and Guild keep their own task-specific controls available. A
	-- user-enabled compact search keeps only the shared search row.
	return self:IsSimpleModeContactSection(sectionID) and not self:ShouldShowSimpleModeSearch(sectionID)
end

function FriendsUI:PerformContactAction()
	local chrome = self:GetContactChrome(self.selectedSection or "friends")
	if chrome.action == "quick_join" then
		local QuickJoin = BFL:GetModule("QuickJoin")
		if QuickJoin and QuickJoin.JoinQueue then
			QuickJoin:JoinQueue()
		end
	elseif chrome.action == "add_friend" and AddFriendFrame_Show then
		AddFriendFrame_Show()
	elseif chrome.action == "guild_actions" and _G.BFL_GuildFrame_ShowActionsMenu then
		_G.BFL_GuildFrame_ShowActionsMenu(self.root and self.root.BottomActionBar.AddFriendButton)
	end
end

function FriendsUI:ShouldReserveModernActionFooter(sectionID, chrome)
	chrome = chrome or self:GetContactChrome(sectionID)
	-- RAF keeps Blizzard's dedicated Recruitment button instead of using the
	-- shared BottomActionBar button. Its list still needs the same 60 px footer
	-- reservation or the final recruit card is laid out behind that button.
	return chrome.action ~= nil or sectionID == "recruit_a_friend"
end

function FriendsUI:ApplyContactChrome(sectionID, header)
	if not self.root then
		return self:GetContactChrome(sectionID)
	end
	local root = self.root
	local chrome = self:GetContactChrome(sectionID)
	local simpleModeContacts = self:IsSimpleModeContactSection(sectionID)
	local showFilterBar = chrome.filterBar == true and not self:DoesSimpleModeHideFilterBar(sectionID)
	local showFilterControls = showFilterBar and not simpleModeContacts
	-- RAF owns a dedicated SocialUIActionButtonTemplate proxy. Keep the shared
	-- footer surface visible for that proxy without exposing the shared action.
	local showActionBar = self:ShouldReserveModernActionFooter(sectionID, chrome)
	local showSharedSearch = sectionID == "friends" or sectionID == "recent_allies"

	root.FilterBar:SetShown(showFilterBar)
	SafeShow(header and header.SearchBox, showFilterBar and showSharedSearch)
	self:HideModernLegacyHeaderDropdowns(header)
	SafeShow(root.FilterBar.FilterDropdown, showFilterControls and chrome.friendsFilter == true)
	SafeShow(root.FilterBar.RecentFilterDropdown, showFilterControls and chrome.recentFilter == true)
	SafeShow(root.FilterBar.SortButton, showFilterControls and chrome.sort == true)

	root.TopDivider:ClearAllPoints()
	if showFilterBar then
		root.TopDivider:SetPoint("TOPLEFT", root.FilterBar, "BOTTOMLEFT", 5, -3)
		root.TopDivider:SetPoint("TOPRIGHT", root.FilterBar, "BOTTOMRIGHT", -5, -3)
	else
		root.TopDivider:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 5, -9)
		root.TopDivider:SetPoint("TOPRIGHT", root.BattleNetBar, "BOTTOMRIGHT", -5, -9)
	end

	root.BottomActionBar:SetShown(showActionBar)
	root.BottomDivider:SetShown(showActionBar)
		local actionButton = root.BottomActionBar.AddFriendButton
		if actionButton then
			actionButton:SetShown(chrome.action ~= nil and chrome.action ~= "who_actions")
			if chrome.action == "quick_join" then
				actionButton:SetText(JOIN_QUEUE or "Join Queue")
				local QuickJoin = BFL:GetModule("QuickJoin")
				if QuickJoin and QuickJoin.UpdateJoinButtonState then
					QuickJoin:UpdateJoinButtonState()
				else
					actionButton:SetEnabled(false)
				end
				if AreFriendsDisabled() then
					actionButton:SetEnabled(false)
				end
		elseif chrome.action == "add_friend" then
			local label = sectionID == "recent_allies" and SOCIAL_UI_RECENT_ALLIES_ADD_FRIEND_BUTTON_LABEL
				or sectionID == "friend_requests" and SOCIAL_UI_FRIEND_REQUESTS_ADD_FRIEND_BUTTON_LABEL
				or SOCIAL_UI_FRIENDS_LIST_ADD_FRIEND_BUTTON_LABEL
			actionButton:SetText(label or ADD_NEW_FRIEND or ADD_FRIEND or "Add Friend")
			actionButton:SetEnabled(not AreFriendsDisabled())
		elseif chrome.action == "guild_actions" then
			actionButton:SetText(GetL().GUILD_ACTIONS_MENU or "Guild Actions")
			local GuildFrame = BFL:GetModule("GuildFrame")
			actionButton:SetEnabled(not GuildFrame or not GuildFrame.IsInGuild or GuildFrame:IsInGuild())
		end
	end
	return chrome, showFilterBar
end

function FriendsUI:ApplyFriendsRestrictionState(sectionID)
	if not (self.root and BetterFriendsFrame) then
		return false
	end

	local restricted = FRIENDS_RESTRICTED_SECTIONS[sectionID] == true and AreFriendsDisabled()
	local label = self.root.FriendsDisabledText
	if label then
		if restricted then
			local definition = SECTION_BY_ID[sectionID]
			local tabName = definition and (GetL()[definition.labelKey] or definition.id) or ""
			label:SetText(SOCIAL_TAB_UNAVAILABLE and SOCIAL_TAB_UNAVAILABLE:format(tabName) or tabName)
		end
		label:SetShown(restricted)
	end

	if not restricted then
		return false
	end

	local frame = BetterFriendsFrame
	if sectionID == "friends" then
		SafeShow(frame.ScrollFrame, false)
		SafeShow(frame.MinimalScrollBar, false)
	elseif sectionID == "recent_allies" then
		SafeShow(frame.RecentAlliesFrame, false)
	elseif sectionID == "quick_join" then
		SafeShow(frame.QuickJoinFrame, false)
	elseif sectionID == "friend_requests" then
		SafeShow(self.root.RequestsFrame, false)
	elseif sectionID == "recruit_a_friend" then
		SafeShow(frame.RecruitAFriendFrame, false)
		SafeShow(frame.RecruitmentButton, false)
	end
	return true
end

local function SetModernHeaderHeight(button, height)
	if not button then
		return
	end
	button:SetHeight(height)
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		local texture = button[key]
		if texture then
			texture:SetHeight(height)
		end
	end
end

local function ApplyModernDirectoryHeaderVisual(button)
	if not button then
		return
	end
	for _, key in ipairs({ "Left", "Middle", "Right", "Background" }) do
		SafeShow(button[key], false)
	end
	if button.NineSlice then
		button.NineSlice:Hide()
	end
	if not button.BFL_ModernHeaderBackground then
		local texture = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		texture:SetAllPoints()
		ApplyAtlasTexture(texture, "common-button-list-collapseExpand")
		button.BFL_ModernHeaderBackground = texture
	end
	local palette, themed = FriendsUI:GetModernThemeColors()
	ApplyModernAtlasColor(button.BFL_ModernHeaderBackground, palette.surface, themed)
	button.BFL_ModernHeaderBackground:SetAlpha(1)
	button.BFL_ModernHeaderBackground:Show()
	button.BFL_ModernHeaderTone = themed and true or nil
	SafeShow(button.BFL_DarkBackdrop, false)
end

function FriendsUI:ApplyModernDirectoryGeometry(sectionID)
	local frame = BetterFriendsFrame
	local root = self.root
	if not (frame and root) then
		return
	end

	local guild = frame.GuildFrame
	local guildActive = sectionID == "guild"
	if guild then
		SafeShow(guild.SearchBox, guildActive)
		SafeShow(guild.FilterDropdown, guildActive)
		SafeShow(guild.SortDropdown, guildActive)
		SafeShow(guild.ActionsButton, false)
		if guildActive then
			if guild.SortDropdown then
				guild.SortDropdown:ClearAllPoints()
				guild.SortDropdown:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
				guild.SortDropdown:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
				ConstrainModernDropdownText(guild.SortDropdown, 1)
			end
			if guild.FilterDropdown then
				guild.FilterDropdown:ClearAllPoints()
				guild.FilterDropdown:SetPoint(
					"RIGHT",
					guild.SortDropdown or root.FilterBar,
					guild.SortDropdown and "LEFT" or "RIGHT",
					guild.SortDropdown and -7 or -7,
					0
				)
				guild.FilterDropdown:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
				ConstrainModernDropdownText(guild.FilterDropdown, 1)
			end
			if guild.SearchBox then
				guild.SearchBox:ClearAllPoints()
				guild.SearchBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
				guild.SearchBox:SetPoint(
					"RIGHT",
					guild.FilterDropdown or guild.SortDropdown or root.FilterBar,
					"LEFT",
					-7,
					0
				)
				guild.SearchBox:SetHeight(MODERN_TOP_CONTROL_HEIGHT)
				ApplyModernSearchBoxVisual(guild.SearchBox)
				if guild.SearchBox.Instructions then
					guild.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
				end
			end
			if guild.ListInset then
				SafeShow(guild.ListInset.Bg, false)
				SafeShow(guild.ListInset.NineSlice, false)
			end
			SafeShow(guild.HeaderDivider, false)
			local GuildFrame = BFL:GetModule("GuildFrame")
			if GuildFrame and GuildFrame.UpdateLayout then
				GuildFrame:UpdateLayout()
			end
		end
	end

	local who = frame.WhoFrame
	local whoActive = sectionID == "who"
	if who then
		SafeShow(who.EditBox, whoActive)
		SafeShow(who.WhoButton, whoActive)
		SafeShow(who.AddFriendButton, whoActive)
		SafeShow(who.GroupInviteButton, whoActive)
		if whoActive then
			who.WhoButton:ClearAllPoints()
			who.WhoButton:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
			who.WhoButton:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
			who.EditBox:ClearAllPoints()
			who.EditBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
			who.EditBox:SetPoint("RIGHT", who.WhoButton, "LEFT", -7, 0)
			who.EditBox:SetHeight(MODERN_TOP_CONTROL_HEIGHT)
			ApplyModernSearchBoxVisual(who.EditBox)
			if who.EditBox.Instructions then
				who.EditBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end

			who.ListInset:ClearAllPoints()
			who.ListInset:SetAllPoints(who)
			SafeShow(who.ListInset.Bg, false)
			SafeShow(who.ListInset.NineSlice, false)
			local WhoFrame = BFL:GetModule("WhoFrame")
			if WhoFrame and WhoFrame.ApplyModernSearchBuilderLayout then
				WhoFrame:ApplyModernSearchBuilderLayout()
			end
			local builderOffset = who.BFL_ModernBuilderHeight or 0
			who.NameHeader:ClearAllPoints()
			who.NameHeader:SetPoint("TOPLEFT", who.ListInset, "TOPLEFT", 4, -2 - builderOffset)
			SetModernHeaderHeight(who.NameHeader, MODERN_DIRECTORY_HEADER_HEIGHT)
			ApplyModernDirectoryHeaderVisual(who.NameHeader)
			who.ColumnDropdown:ClearAllPoints()
			who.ColumnDropdown:SetPoint("TOPLEFT", who.NameHeader, "TOPRIGHT", -1, 0)
			SetModernHeaderHeight(who.ColumnDropdown, MODERN_DIRECTORY_HEADER_HEIGHT)
			ApplyModernDirectoryHeaderVisual(who.ColumnDropdown)
			who.LevelHeader:ClearAllPoints()
			who.LevelHeader:SetPoint("TOPLEFT", who.ColumnDropdown, "TOPRIGHT", -1, 0)
			SetModernHeaderHeight(who.LevelHeader, MODERN_DIRECTORY_HEADER_HEIGHT)
			ApplyModernDirectoryHeaderVisual(who.LevelHeader)
			who.ClassHeader:ClearAllPoints()
			who.ClassHeader:SetPoint("TOPLEFT", who.LevelHeader, "TOPRIGHT", -1, 0)
			SetModernHeaderHeight(who.ClassHeader, MODERN_DIRECTORY_HEADER_HEIGHT)
			ApplyModernDirectoryHeaderVisual(who.ClassHeader)

			who.ListInset.Totals:ClearAllPoints()
			who.ListInset.Totals:SetPoint("BOTTOMLEFT", who.ListInset, "BOTTOMLEFT", 8, 6)
			who.ListInset.Totals:SetPoint("BOTTOMRIGHT", who.ListInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 6)

			local buttonGap = 7
			who.AddFriendButton:ClearAllPoints()
			who.AddFriendButton:SetPoint("RIGHT", root.BottomActionBar, "CENTER", -buttonGap / 2, 0)
			who.AddFriendButton:SetSize(140, 30)
			who.GroupInviteButton:ClearAllPoints()
			who.GroupInviteButton:SetPoint("LEFT", root.BottomActionBar, "CENTER", buttonGap / 2, 0)
			who.GroupInviteButton:SetSize(140, 30)

			if WhoFrame and WhoFrame.UpdateResponsiveLayout then
				WhoFrame._lastLayoutWidth = nil
				WhoFrame:UpdateResponsiveLayout()
			end
		end
	end
end

local function GetModernRaidTextWidth(region, fallback)
	if region and region.GetStringWidth then
		local width = region:GetStringWidth()
		if width and width > 0 then
			return width
		end
	end
	return fallback or 0
end

local RAID_MEMBER_COUNT_ICON_TEXTURE = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"

local function NormalizeModernRaidMemberCountText(memberCount)
	if not memberCount then
		return
	end
	local countText = tostring(memberCount:GetText() or ""):match("(%d+/%d+)$")
	if countText then
		memberCount:SetText(countText)
	end
end

local function NormalizeLegacyRaidMemberCountText(memberCount)
	if not memberCount then
		return
	end
	local text = tostring(memberCount:GetText() or "")
	if text ~= "" and not text:find("|T", 1, true) then
		memberCount:SetText("|T" .. RAID_MEMBER_COUNT_ICON_TEXTURE .. ":16:16|t " .. text)
	end
end

local function SizeCompactModernRaidButton(button, minWidth, maxWidth)
	if not button then
		return
	end
	local fontString = button.GetFontString and button:GetFontString()
	local textWidth = GetModernRaidTextWidth(fontString, minWidth - 28)
	local width = math.max(minWidth, math.min(maxWidth, math.ceil(textWidth + 28)))
	button:SetSize(width, 24)
end

function FriendsUI:ApplyModernSectionTopChrome(sectionID)
	if not self.root then
		return
	end
	-- The native fade supplies the warm SocialUI color transition in every
	-- section. Raid only removes BFL's additional contact-list divider.
	SafeShow(self.root.TopFade, true)
	SafeShow(self.root.TopDivider, sectionID ~= "raid")
end

function FriendsUI:ApplyModernRaidGeometry()
	local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	local control = raid and raid.ControlPanel
	if not control then
		return
	end

	control:ClearAllPoints()
	control:SetPoint("TOPLEFT", raid, "TOPLEFT", 0, 0)
	control:SetPoint("TOPRIGHT", raid, "TOPRIGHT", 0, 0)
	control:SetHeight(32)

	local helpButton = BetterFriendsFrame.HelpButton
	if helpButton then
		helpButton:SetParent(control)
		helpButton:ClearAllPoints()
		helpButton:SetSize(24, 24)
		helpButton:SetFrameLevel(control:GetFrameLevel() + 5)
		if helpButton.Icon then
			helpButton.Icon:SetSize(17, 17)
		end
	end

	local assist = control.EveryoneAssistCheckbox
	if assist then
		assist:ClearAllPoints()
		assist:SetPoint("TOPLEFT", control, "TOPLEFT", 8, -4)
		assist:SetSize(24, 24)
	end
	local assistIcon = control.EveryoneAssistIcon
	if assistIcon then
		ApplyAtlasTexture(assistIcon, "friends-icon-raidAssist")
		assistIcon:SetSize(17, 15)
		assistIcon:ClearAllPoints()
		assistIcon:SetPoint("LEFT", assist, "RIGHT", 2, 0)
		assistIcon:Show()
	end
	local assistLabel = control.EveryoneAssistLabel
	if assistLabel then
		assistLabel:ClearAllPoints()
		assistLabel:SetPoint("LEFT", assistIcon or assist, "RIGHT", 2, 0)
		assistLabel:SetJustifyH("LEFT")
		assistLabel:SetText(ALL_ASSIST_LABEL_SHORT or ALL or "All")
		if GameFontNormalMed1 then
			assistLabel:SetFontObject(GameFontNormalMed1)
		end
		assistLabel:Show()
	end
	if helpButton then
		helpButton:SetPoint("LEFT", assistLabel or assist, "RIGHT", 4, 0)
	end

	SafeShow(control.TankFrame, false)
	SafeShow(control.HealerFrame, false)
	SafeShow(control.DamagerFrame, false)
	SafeShow(control.RoleSummary, true)

	local readyCheckWidth = 28
	local utilityButtonHeight = 28
	local rightPadding = 4
	local panelWidth = control:GetWidth()
	if not panelWidth or panelWidth <= 0 then
		panelWidth = raid:GetWidth() or 400
	end
	local narrowLayout = panelWidth < 400
	local utilityGap = narrowLayout and 2 or 4
	local assistLabelWidth = GetModernRaidTextWidth(assistLabel, 20)
	local leftSectionEnd = 8 + 24 + 2 + 17 + 2 + assistLabelWidth + (helpButton and 28 or 0)
	local readyCheckVisible = control.ReadyCheckButton and control.ReadyCheckButton:IsShown()
	local combatIconVisible = control.CombatIcon and control.CombatIcon:IsShown()
	local utilityWidth = 0
	if readyCheckVisible then
		utilityWidth = readyCheckWidth + utilityGap
	elseif combatIconVisible then
		utilityWidth = 16 + utilityGap
	end
	NormalizeModernRaidMemberCountText(control.MemberCount)
	local memberWidth = GetModernRaidTextWidth(control.MemberCount, 32)
	local outerGap = narrowLayout and 2 or 6
	local roleToMemberCountGap = narrowLayout and 2 or 6
	-- RoleCountNoScriptsTemplate is 125 px wide, while its visible role cells end
	-- at DamagerIcon's right edge (114 px from the frame's left edge). Measure
	-- the visible block instead of its transparent trailing template padding.
	local roleVisibleWidth = 114
	local centerWidth = roleVisibleWidth
		+ roleToMemberCountGap
		+ memberWidth
	local centerStart = leftSectionEnd + outerGap
	-- Keep the complete left sequence stable. Only Raid Info flexes between its
	-- preferred and minimum text-safe width when the frame approaches 380 px.
	local raidInfoSpace = panelWidth
		- rightPadding
		- utilityWidth
		- (centerStart + centerWidth + outerGap)
	local raidInfoWidth = math.max(80, math.min(88, math.floor(raidInfoSpace + 0.5)))

	if control.RoleSummary then
		control.RoleSummary:ClearAllPoints()
		control.RoleSummary:SetPoint("LEFT", control, "LEFT", centerStart, 0)
		control.RoleSummary:Show()
	end
	if control.MemberCount then
		local damagerIcon = control.RoleSummary and control.RoleSummary.DamagerIcon
		control.MemberCount:ClearAllPoints()
		control.MemberCount:SetPoint("LEFT", damagerIcon or control.RoleSummary, "RIGHT", roleToMemberCountGap, 0)
		control.MemberCount:SetJustifyH("LEFT")
		control.MemberCount:Show()
	end

	if control.RaidInfoButton then
		control.RaidInfoButton:ClearAllPoints()
		control.RaidInfoButton:SetPoint("TOPRIGHT", control, "TOPRIGHT", -rightPadding, -2)
		control.RaidInfoButton:SetSize(raidInfoWidth, utilityButtonHeight)
	end
	if control.ReadyCheckButton then
		control.ReadyCheckButton:ClearAllPoints()
		control.ReadyCheckButton:SetPoint("TOPRIGHT", control.RaidInfoButton, "TOPLEFT", -utilityGap, 0)
		control.ReadyCheckButton:SetSize(readyCheckWidth, utilityButtonHeight)
		if not control.ReadyCheckButton.BFL_ModernRaidGeometryHooked then
			control.ReadyCheckButton:HookScript("OnShow", function()
				if FriendsUI:IsModernActive() then
					FriendsUI:ApplyModernRaidGeometry()
				end
			end)
			control.ReadyCheckButton.BFL_ModernRaidGeometryHooked = true
		end
	end
	if control.CombatIcon then
		control.CombatIcon:ClearAllPoints()
		control.CombatIcon:SetPoint("CENTER", control.RaidInfoButton, "LEFT", -(utilityGap + 8), -1)
	end

	local groupsInset = raid.GroupsInset
	if groupsInset then
		groupsInset:ClearAllPoints()
		groupsInset:SetPoint("TOPLEFT", control, "BOTTOMLEFT", 0, 0)
		groupsInset:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", 0, 31)
		SafeShow(groupsInset.Bg, false)
		SafeShow(groupsInset.NineSlice, false)
		SafeShow(groupsInset.backdrop, false)
		SafeShow(groupsInset.BFL_DarkBackdrop, false)
		if groupsInset.SetBackdrop then
			groupsInset:SetBackdrop(nil)
		end
		local container = groupsInset.GroupsContainer
		if container then
			container:ClearAllPoints()
			container:SetPoint("TOPLEFT", groupsInset, "TOPLEFT", 9, -7)
			container:SetPoint("BOTTOMRIGHT", groupsInset, "BOTTOMRIGHT", -9, 0)
		end
	end

	SizeCompactModernRaidButton(raid.RaidToolsButton, 72, 110)
	SizeCompactModernRaidButton(raid.ConvertToRaidButton, 120, 180)
	if raid.RaidToolsButton then
		raid.RaidToolsButton:ClearAllPoints()
		raid.RaidToolsButton:SetPoint("BOTTOMLEFT", raid, "BOTTOMLEFT", 8, 5)
	end
	if raid.ConvertToRaidButton then
		raid.ConvertToRaidButton:ClearAllPoints()
		raid.ConvertToRaidButton:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -8, 5)
	end

	if not raid.BFL_ModernRaidResizeHooked then
		raid:HookScript("OnSizeChanged", function()
			if not FriendsUI:IsModernActive() then
				return
			end
			FriendsUI:ApplyModernRaidGeometry()
			local RaidFrame = BFL:GetModule("RaidFrame")
			if RaidFrame and RaidFrame.UpdateGroupLayout then
				RaidFrame._lastLayoutWidth = nil
				RaidFrame._lastLayoutHeight = nil
				RaidFrame:UpdateGroupLayout()
			end
		end)
		raid.BFL_ModernRaidResizeHooked = true
	end
end

function FriendsUI:RestoreLegacyRaidGeometry()
	local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	local control = raid and raid.ControlPanel
	if not control then
		return
	end
	control:ClearAllPoints()
	control:SetPoint("TOPLEFT", raid, "TOPLEFT", 14, -8)
	control:SetPoint("TOPRIGHT", raid, "TOPRIGHT", -14, -8)
	control:SetHeight(48)
	local helpButton = BetterFriendsFrame.HelpButton
	if helpButton then
		helpButton:SetParent(BetterFriendsFrame)
		helpButton:SetSize(24, 24)
		if helpButton.Icon then
			helpButton.Icon:SetSize(18, 18)
		end
	end
	local StreamerMode = BFL:GetModule("StreamerMode")
	if StreamerMode and StreamerMode.UpdateAdjacentButtonAnchors then
		StreamerMode:UpdateAdjacentButtonAnchors()
	end
	SafeShow(control.EveryoneAssistIcon, false)
	SafeShow(control.TankFrame, false)
	SafeShow(control.HealerFrame, false)
	SafeShow(control.DamagerFrame, false)
	SafeShow(control.RoleSummary, true)
	NormalizeLegacyRaidMemberCountText(control.MemberCount)
	if control.RaidInfoButton then
		control.RaidInfoButton:SetSize(90, 22)
	end
	local groupsInset = raid.GroupsInset
	if groupsInset then
		groupsInset:ClearAllPoints()
		groupsInset:SetPoint("TOPLEFT", control, "BOTTOMLEFT", -4, 10)
		groupsInset:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -2, 21)
		SafeShow(groupsInset.Bg, true)
		SafeShow(groupsInset.NineSlice, true)
		local container = groupsInset.GroupsContainer
		if container then
			container:ClearAllPoints()
			container:SetPoint("TOPLEFT", groupsInset, "TOPLEFT", 10, -2)
			container:SetPoint("BOTTOMRIGHT", groupsInset, "BOTTOMRIGHT", -10, 2)
		end
	end
	if raid.ConvertToRaidButton then
		raid.ConvertToRaidButton:ClearAllPoints()
		raid.ConvertToRaidButton:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -2, -1)
		raid.ConvertToRaidButton:SetSize(150, 21)
	end
	if raid.RaidToolsButton then
		raid.RaidToolsButton:ClearAllPoints()
		raid.RaidToolsButton:SetPoint("TOPLEFT", raid.GroupsInset, "BOTTOMLEFT", -2, -1)
		raid.RaidToolsButton:SetSize(150, 21)
	end
end

function FriendsUI:ApplyModernQuickJoinGeometry(sectionID)
	local quickJoinFrame = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	local contentInset = quickJoinFrame and quickJoinFrame.ContentInset
	if not contentInset then
		return
	end
	local modernQuickJoin = sectionID == "quick_join"
	contentInset:ClearAllPoints()
	contentInset:SetAllPoints(quickJoinFrame)
	contentInset:SetAlpha(1)
	SafeShow(contentInset.Bg, not modernQuickJoin)
	SafeShow(contentInset.NineSlice, not modernQuickJoin)
	local joinButton = contentInset.JoinQueueButton
	if joinButton then
		joinButton:SetShown(not modernQuickJoin)
	end
	if contentInset.ScrollBoxContainer then
		contentInset.ScrollBoxContainer:ClearAllPoints()
		contentInset.ScrollBoxContainer:SetPoint("TOPLEFT", contentInset, "TOPLEFT", 0, 0)
		contentInset.ScrollBoxContainer:SetPoint("BOTTOMRIGHT", contentInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 0)
	end
end

function FriendsUI:RestoreLegacyQuickJoinGeometry()
	local quickJoinFrame = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	local contentInset = quickJoinFrame and quickJoinFrame.ContentInset
	if not contentInset then
		return
	end
	contentInset:ClearAllPoints()
	contentInset:SetPoint("TOPLEFT", quickJoinFrame, "TOPLEFT", 0, 80)
	contentInset:SetPoint("BOTTOMRIGHT", quickJoinFrame, "BOTTOMRIGHT", 0, 0)
	contentInset:SetAlpha(1)
	SafeShow(contentInset.Bg, true)
	SafeShow(contentInset.NineSlice, true)
	SafeShow(contentInset.JoinQueueButton, true)
	if contentInset.ScrollBoxContainer then
		contentInset.ScrollBoxContainer:ClearAllPoints()
		contentInset.ScrollBoxContainer:SetPoint("TOPLEFT", contentInset, "TOPLEFT", 4, -4)
		contentInset.ScrollBoxContainer:SetPoint("BOTTOMRIGHT", contentInset, "BOTTOMRIGHT", -24, 4)
	end
end

function FriendsUI:LayoutRequestsFrame()
	if not self.root then
		return
	end
	local requests = self.root.RequestsFrame
	requests.ScrollBox:ClearAllPoints()
	requests.ScrollBar:ClearAllPoints()
	requests.ScrollBar:SetWidth(MODERN_SCROLL_BAR_WIDTH)
	requests.ScrollBox:SetPoint("TOPLEFT", requests, "TOPLEFT", 0, 0)
	requests.ScrollBox:SetPoint("BOTTOMRIGHT", requests, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 0)
	requests.ScrollBar:SetPoint("TOPLEFT", requests.ScrollBox, "TOPRIGHT", MODERN_SCROLL_BAR_GAP, 0)
	requests.ScrollBar:SetPoint("BOTTOMLEFT", requests.ScrollBox, "BOTTOMRIGHT", MODERN_SCROLL_BAR_GAP, 0)
	self:LayoutRealIDWarning()
end

function FriendsUI:LayoutRealIDWarning()
	local requests = self.root and self.root.RequestsFrame
	local warning = requests and requests.RealIDWarning
	if not warning then
		return
	end

	-- Blizzard's 12.1 FriendRequestsListRealIDWarningTemplate is a DIALOG
	-- overlay. Keep the complete warning, including its BACKGROUND layer,
	-- above recycled request cards and their buttons.
	if warning.SetFrameStrata then
		warning:SetFrameStrata("DIALOG")
	end
	if warning.SetFrameLevel then
		local contentLevel = requests.GetFrameLevel and requests:GetFrameLevel() or 0
		for _, content in ipairs({ requests.ScrollBox, requests.ScrollBar }) do
			if content and content.GetFrameLevel then
				contentLevel = math.max(contentLevel, content:GetFrameLevel() or 0)
			end
		end
		warning:SetFrameLevel(contentLevel + 10)
	end
	if warning.Background then
		if warning.Background.SetDrawLayer then
			warning.Background:SetDrawLayer("BACKGROUND", 0)
		end
		warning.Background:Show()
	end
end

function FriendsUI:GetRealIDWarningBackgroundColor(palette, theme)
	return ResolveRealIDWarningBackground(palette, theme or self.currentTheme or "blizzard")
end

function FriendsUI:ApplyRealIDWarningTheme(palette, theme)
	local warning = self.root and self.root.RequestsFrame and self.root.RequestsFrame.RealIDWarning
	if not (warning and warning.Background) then
		return
	end
	self:LayoutRealIDWarning()
	local color = self:GetRealIDWarningBackgroundColor(palette, theme)
	ApplySolidTextureColor(warning.Background, color)
	warning.BFL_RealIDWarningBackgroundColor = color
end

local function AnchorModernScrollBar(scrollBar, scrollBox, topOffset, bottomOffset, width)
	if not (scrollBar and scrollBox) then
		return
	end
	scrollBar:ClearAllPoints()
	if width and width > 0 then
		scrollBar:SetWidth(width)
	end
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", MODERN_SCROLL_BAR_GAP, topOffset or 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", MODERN_SCROLL_BAR_GAP, bottomOffset or 0)
end

function FriendsUI:GetModernScrollBarLeftInset()
	return MODERN_SCROLL_BOX_RIGHT_INSET - MODERN_SCROLL_BAR_GAP
end

function FriendsUI:GetModernScrollBoxRightInset()
	return MODERN_SCROLL_BOX_RIGHT_INSET
end

function FriendsUI:GetModernScrollBarGap()
	return MODERN_SCROLL_BAR_GAP
end

function FriendsUI:GetAuxiliaryWindowOffset()
	-- LargeSideTabButtonTemplate protrudes from the main frame's right edge.
	-- Leave the complete tab rail plus a small visual gap unobstructed.
	return self:IsModernActive() and 68 or 5
end

function FriendsUI:AnchorAuxiliaryWindow(window, topOffset)
	if not (window and BetterFriendsFrame) then
		return false
	end
	window:ClearAllPoints()
	window:SetPoint(
		"TOPLEFT",
		BetterFriendsFrame,
		"TOPRIGHT",
		self:GetAuxiliaryWindowOffset(),
		topOffset or 0
	)
	return true
end

function FriendsUI:GetBroadcastFrame()
	local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
	local battleNetFrame = header and header.BattlenetFrame
	return battleNetFrame and battleNetFrame.BroadcastFrame
end

function FriendsUI:RefreshBroadcastFrameAnchor()
	local broadcastFrame = self:GetBroadcastFrame()
	if not broadcastFrame then
		return false
	end

	if self:IsModernActive() then
		return self:AnchorAuxiliaryWindow(broadcastFrame, 0)
	end

	local legacyState = self.legacyState
		and self.legacyState.frames
		and self.legacyState.frames["bnet.BroadcastFrame"]
	if legacyState then
		RestoreFrameState(legacyState, false)
		return true
	end
	return false
end

function FriendsUI:InstallBroadcastFrameAnchorHook()
	local broadcastFrame = self:GetBroadcastFrame()
	if not (broadcastFrame and broadcastFrame.HookScript) then
		return false
	end
	if not broadcastFrame.BFL_ModernAnchorHooked then
		broadcastFrame.BFL_ModernAnchorHooked = true
		broadcastFrame:HookScript("OnShow", function()
			self:RefreshBroadcastFrameAnchor()
		end)
	end
	return self:RefreshBroadcastFrameAnchor()
end

function FriendsUI:ApplyFriendsFriendsFrameTheme(frame)
	frame = frame or _G.FriendsFriendsFrame
	if not frame then
		return false
	end
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or self.currentTheme or "blizzard"
	if theme == "dark" or theme == "custom" then
		local engine = BFL:GetModule("SkinEngine")
		local DarkTheme = BFL:GetModule("DarkTheme")
		if engine and engine.IsActive and engine:IsActive() and DarkTheme and DarkTheme.SkinCreatedFrame then
			DarkTheme:SkinCreatedFrame(frame)
			return true
		end
	elseif theme == "elvui" then
		local ElvUISkin = BFL:GetModule("ElvUISkin")
		return ElvUISkin and ElvUISkin.SkinFriendsFriendsFrame and ElvUISkin:SkinFriendsFriendsFrame(frame) == true
	elseif theme == "ellesmereui" then
		local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
		return EllesmereUISkin
			and EllesmereUISkin.SkinFriendsFriendsFrame
			and EllesmereUISkin:SkinFriendsFriendsFrame(frame) == true
	end
	return theme == "blizzard"
end

function FriendsUI:RefreshFriendsFriendsFrame()
	local frame = _G.FriendsFriendsFrame
	if not frame then
		return false
	end
	self:AnchorAuxiliaryWindow(frame, 0)
	self:ApplyFriendsFriendsFrameTheme(frame)
	return true
end

function FriendsUI:InstallFriendsFriendsFrameHook()
	local frame = _G.FriendsFriendsFrame
	if frame and frame.HookScript and not frame.BFL_FriendsFriendsOnShowHooked then
		frame.BFL_FriendsFriendsOnShowHooked = true
		frame:HookScript("OnShow", function()
			self:RefreshFriendsFriendsFrame()
		end)
	end
	if type(_G.FriendsFriendsFrame_Show) == "function" and hooksecurefunc and not self.friendsFriendsShowHookInstalled then
		hooksecurefunc("FriendsFriendsFrame_Show", function()
			self:RefreshFriendsFriendsFrame()
		end)
		self.friendsFriendsShowHookInstalled = true
	end
	return self:RefreshFriendsFriendsFrame()
end

function FriendsUI:ApplyModernScrollBarGeometry()
	local frame = BetterFriendsFrame
	if not (self.root and frame) then
		return
	end

	local referenceWidth = MODERN_SCROLL_BAR_WIDTH

	AnchorModernScrollBar(frame.MinimalScrollBar, frame.ScrollFrame, nil, nil, referenceWidth)

	local recentAllies = frame.RecentAlliesFrame
	if recentAllies and recentAllies.ScrollBox then
		recentAllies.ScrollBox:ClearAllPoints()
		recentAllies.ScrollBox:SetPoint("TOPLEFT", recentAllies, "TOPLEFT", 4, -2)
		recentAllies.ScrollBox:SetPoint("BOTTOMRIGHT", recentAllies, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, -2)
		AnchorModernScrollBar(recentAllies.ScrollBar, recentAllies.ScrollBox, nil, nil, referenceWidth)
	end

	local recruitList = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList
	if recruitList and recruitList.ScrollBox then
		recruitList.ScrollBox:ClearAllPoints()
		recruitList.ScrollBox:SetPoint("TOPLEFT", recruitList.Header, "BOTTOMLEFT", 0, -3)
		recruitList.ScrollBox:SetPoint("BOTTOMRIGHT", recruitList, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 1)
		AnchorModernScrollBar(recruitList.ScrollBar, recruitList.ScrollBox, nil, nil, referenceWidth)
	end

	local quickJoinInset = frame.QuickJoinFrame and frame.QuickJoinFrame.ContentInset
	if quickJoinInset then
		AnchorModernScrollBar(quickJoinInset.ScrollBar, quickJoinInset.ScrollBoxContainer, nil, nil, referenceWidth)
	end

	local who = frame.WhoFrame
	if who and who.ScrollBox then
		who.ScrollBox:ClearAllPoints()
		-- Header widths are calculated from this exact left edge. Keeping the
		-- ScrollBox flush with NameHeader makes every row column share the same
		-- horizontal origin instead of shifting all cells seven pixels right.
		who.ScrollBox:SetPoint("TOPLEFT", who.NameHeader, "BOTTOMLEFT", 0, -2)
		who.ScrollBox:SetPoint(
			"BOTTOMRIGHT",
			who.ListInset,
			"BOTTOMRIGHT",
			-MODERN_SCROLL_BOX_RIGHT_INSET,
			24
		)
		-- Include the column-header and totals bands so Who uses the same full
		-- vertical scrollbar rail as the Friends list.
		AnchorModernScrollBar(who.ScrollBar, who.ScrollBox, 26, -24, referenceWidth)
	end

	local guild = frame.GuildFrame
	if guild and guild.ScrollBox then
		guild.ScrollBox:ClearAllPoints()
		guild.ScrollBox:SetPoint("TOPLEFT", guild.ListInset, "TOPLEFT", 4, -4)
		guild.ScrollBox:SetPoint("BOTTOMRIGHT", guild.ListInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 4)
		AnchorModernScrollBar(guild.ScrollBar, guild.ScrollBox, nil, nil, referenceWidth)
	end

	self:LayoutRequestsFrame()
end

function FriendsUI:RefreshRequests(newInvite)
	local count = GetFriendInviteCount()
	if self.root and self.requestsInitialized then
		local dataProvider = CreateDataProvider()
		local hasRealID = false
		local headerFormat = SOCIAL_UI_FRIEND_REQUESTS_RECEIVED_HEADER or "Friend Requests Received (%d)"
		dataProvider:Insert({ headerText = string.format(headerFormat, count) })
		dataProvider:Insert({ isSpacer = true })
		for index = 1, count do
			local info = self:NormalizeInvite(index)
			if info then
				dataProvider:Insert(info)
				hasRealID = hasRealID or self:IsRealIDInvite(info.friendLevel)
			end
		end
		self.root.RequestsFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
		self.root.RequestsFrame.EmptyLabel:SetShown(count == 0)
		local warningSeen = GetCVarBool and GetCVarBool("pendingInviteInfoShown")
		local realIDEnabled = false
		if BNGetInfo then
			local ok, _, _, _, _, _, _, enabled = pcall(BNGetInfo)
			realIDEnabled = ok and enabled == true
		end
		self.root.RequestsFrame.RealIDWarning:SetShown(hasRealID and realIDEnabled and not warningSeen)
		self:LayoutRequestsFrame()
	end
	if count == 0 then
		self:StopRequestGlow()
	elseif self:ShouldStartRequestGlow(newInvite) then
		self:StartRequestGlow()
	end
	self:RefreshNavigation()
end

function FriendsUI:HideAllContentFrames()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	for _, field in ipairs({ "ScrollFrame", "MinimalScrollBar", "RecentAlliesFrame", "RecruitAFriendFrame", "QuickJoinFrame", "WhoFrame", "RaidFrame", "GuildFrame", "SortFrame", "AddFriendButton", "SendMessageButton", "RecruitmentButton" }) do
		SafeShow(frame[field], false)
	end
end

function FriendsUI:HideLegacyTabs()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	for _, field in ipairs({ "BottomTab1", "BottomTab2", "BottomTab3", "BottomTab4" }) do
		SafeShow(frame[field], false)
	end
	local header = frame.FriendsTabHeader
	if header then
		for _, field in ipairs({ "Tab1", "Tab2", "Tab3", "Tab4" }) do
			SafeShow(header[field], false)
		end
	end
end

function FriendsUI:UpdateLegacyRecruitmentButtonVisibility()
	if self:IsModernActive() or not BetterFriendsFrame then
		return
	end
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	local bottomSelection = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(frame) or frame.selectedTab or 1
	local topSelection = header and PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(header)
		or (header and header.selectedTab)
		or 1
	local capabilities = self:GetCapabilities()
	local shouldShow = bottomSelection == 1
		and topSelection == 3
		and capabilities.recruit_a_friend == true
		and frame.RecruitAFriendFrame
		and frame.RecruitAFriendFrame:IsShown()

	-- RAF swaps the action button object for Modern. Its proxy state must never
	-- leak back into Legacy when another top tab is active.
	SafeShow(frame.bflModernRecruitmentButton, false)
	SafeShow(frame.RecruitmentButton, shouldShow == true)
end

function FriendsUI:RestoreLegacyTabs(resetSelection)
	local frame = BetterFriendsFrame
	if not (frame and BFL.IsRetail) then
		return
	end

	-- Bottom tabs are part of the Legacy frame contract. Modern hides them, but
	-- a live style switch must rebuild the same registry and visibility that a
	-- cold Legacy load gets instead of relying on the pre-Modern shown state.
	frame.Tabs = {
		frame.BottomTab1,
		frame.BottomTab2,
		frame.BottomTab3,
		frame.BottomTab4,
	}
	PanelTemplates_SetNumTabs(frame, 4)
	for _, tab in ipairs(frame.Tabs) do
		if tab then
			tab:Show()
		end
	end
	local bottomSelection = resetSelection and 1 or (PanelTemplates_GetSelectedTab(frame) or frame.selectedTab or 1)
	if bottomSelection < 1 or bottomSelection > 4 then
		bottomSelection = 1
	end
	PanelTemplates_SetTab(frame, bottomSelection)
	PanelTemplates_UpdateTabs(frame)

	local header = frame.FriendsTabHeader
	if not header then
		return
	end
	local capabilities = self:GetCapabilities()
	local visibleTopTabs = {
		[1] = true,
		[2] = capabilities.recent_allies == true,
		[3] = capabilities.recruit_a_friend == true,
		[4] = capabilities.guild == true,
	}
	header.Tabs = { header.Tab1, header.Tab2, header.Tab3, header.Tab4 }
	PanelTemplates_SetNumTabs(header, 4)

	local previousVisibleTab
	for index = 1, 4 do
		local tab = header["Tab" .. index]
		if tab then
			tab:ClearAllPoints()
			if index == 1 then
				tab:SetPoint("TOPLEFT", header, "TOPLEFT", 18, -95)
			elseif previousVisibleTab then
				tab:SetPoint("TOPLEFT", previousVisibleTab, "TOPRIGHT", 3, 0)
			end
			tab:SetShown(visibleTopTabs[index] == true)
			if visibleTopTabs[index] then
				previousVisibleTab = tab
			end
		end
	end

	local topSelection = resetSelection and 1 or (PanelTemplates_GetSelectedTab(header) or header.selectedTab or 1)
	if not visibleTopTabs[topSelection] then
		topSelection = 1
	end
	PanelTemplates_SetTab(header, topSelection)
	PanelTemplates_UpdateTabs(header)
	-- Some PanelTemplates variants show every registered tab during their update.
	-- Reapply the capability mask and compact chain after the visual refresh.
	previousVisibleTab = nil
	for index = 1, 4 do
		local tab = header["Tab" .. index]
		if tab then
			tab:ClearAllPoints()
			if index == 1 then
				tab:SetPoint("TOPLEFT", header, "TOPLEFT", 18, -95)
			elseif previousVisibleTab then
				tab:SetPoint("TOPLEFT", previousVisibleTab, "TOPRIGHT", 3, 0)
			end
			tab:SetShown(visibleTopTabs[index] == true)
			if visibleTopTabs[index] then
				previousVisibleTab = tab
			end
		end
	end
	if BFL.ApplyTabFonts then
		-- PanelTemplates_UpdateTabs may have resized the tabs even when the font
		-- signature is unchanged. Force the Legacy compact-chain pass to run.
		if BFL._tabFontCache then
			BFL._tabFontCache.signature = nil
		end
		BFL:ApplyTabFonts()
	end
	self:UpdateLegacyRecruitmentButtonVisibility()
end

-- BetterFriendlist.xml v2.7.0 places the shared Legacy content inset directly
-- below the first top tab. Modern mode temporarily repurposes this region, so
-- restore the XML contract verbatim when returning to Legacy. Anchoring the
-- inset to the main frame instead moves every Legacy search, tab, and list.
function FriendsUI:RestoreLegacyMainInsetLayout()
	if self:IsModernActive() or not BetterFriendsFrame then
		return
	end
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	local firstTab = header and header.Tab1
	if not (frame.Inset and firstTab) then
		return
	end

	frame.Inset:ClearAllPoints()
	frame.Inset:SetPoint("TOPLEFT", firstTab, "BOTTOMLEFT", -4, 1)
	frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 26)

	if frame.ScrollFrame then
		frame.ScrollFrame:ClearAllPoints()
		frame.ScrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
		frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 2)
	end
end

function FriendsUI:SynchronizeModernBottomFade()
	if not BFL.IsRetail then
		return false
	end
	local root = self.root
	local frame = BetterFriendsFrame
	local background = frame and (frame.Bg or frame)
	local topFade = root and root.TopFade
	local bottomFade = root and root.BottomFade
	if not (background and topFade and bottomFade) then
		return false
	end

	-- The two SocialUI atlases intentionally have different native widths.  The
	-- visual edge of the bottom atlas must therefore take its width from the
	-- rendered top fade, rather than from its own atlas dimensions.
	local topWidth = topFade:GetWidth() or 0
	if topWidth <= 0 then
		return false
	end

	bottomFade:ClearAllPoints()
	bottomFade:SetPoint("BOTTOM", background, "BOTTOM")
	bottomFade:SetWidth(topWidth)
	return true
end

function FriendsUI:QueueModernBottomFadeSync()
	local root = self.root
	if not (root and C_Timer and C_Timer.After) or root._bottomFadeSyncPending then
		return
	end
	root._bottomFadeSyncPending = true
	C_Timer.After(0, function()
		root._bottomFadeSyncPending = nil
		if self.root == root then
			self:SynchronizeModernBottomFade()
		end
	end)
end

function FriendsUI:ApplyModernRootGeometry()
	if not (self.root and BetterFriendsFrame) then
		return
	end
	local root = self.root
	local frame = BetterFriendsFrame
	local background = frame.Bg or frame
	local _, themed = self:GetModernThemeColors()
	local headerControlOffsetY = self:GetModernHeaderControlOffsetY()

	root.BattleNetBar:ClearAllPoints()
	root.BattleNetBar:SetPoint("TOPLEFT", background, "TOPLEFT", -3, -1)
	root.BattleNetBar:SetPoint("TOPRIGHT", background, "TOPRIGHT", 3, -1)
	local menuButtonSize = themed and MODERN_THEMED_MENU_BUTTON_SIZE or 34
	root.BattleNetBar.MenuButton:SetSize(menuButtonSize, menuButtonSize)
	root.BattleNetBar.MenuButton:ClearAllPoints()
	root.BattleNetBar.MenuButton:SetPoint("RIGHT", root.BattleNetBar, "RIGHT", -8, headerControlOffsetY)

	root.ContentBackground:ClearAllPoints()
	root.ContentBackground:SetPoint("TOP", root.BattleNetBar, "BOTTOM", 0, 5)
	root.ContentBackground:SetPoint("LEFT", frame, "LEFT", 4, 0)
	root.ContentBackground:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
	root.ContentBackground:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
	root.FadeMask:ClearAllPoints()
	-- Both native fades use this exact mask. This is the actual region clipping
	-- mechanism; SetClipsChildren does not clip textures in a frame's own layer.
	root.FadeMask:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 0)
	root.FadeMask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)

	-- Keep Blizzard's native top fade centered. Bottom follows its rendered
	-- width, shares its mask, and uses Blizzard's Bg-relative anchor.
	root.TopFade:ClearAllPoints()
	root.TopFade:SetPoint("TOP", root.BattleNetBar, "BOTTOM", 0, 5)
	self:SynchronizeModernBottomFade()
	-- Anchors resolve after the current layout pass. Repeat once so a newly
	-- created root never retains the bottom atlas' wider native width.
	self:QueueModernBottomFadeSync()

	root.FilterBar:ClearAllPoints()
	root.FilterBar:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 0, 5)
	root.FilterBar:SetPoint("TOPRIGHT", root.BattleNetBar, "BOTTOMRIGHT", 0, 5)
	root.FilterBar.SortButton:ClearAllPoints()
	root.FilterBar.SortButton:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
	root.FilterBar.SortButton:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
	root.FilterBar.FilterDropdown:ClearAllPoints()
	root.FilterBar.FilterDropdown:SetPoint("RIGHT", root.FilterBar.SortButton, "LEFT", -7, 0)
	root.FilterBar.FilterDropdown:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
	-- The dropdown arrow is baked into the native background atlas, so the
	-- one-pixel shorter control reduces it together with the text and icon.
	ConstrainModernDropdownText(root.FilterBar.FilterDropdown, 1)
	root.FilterBar.RecentFilterDropdown:ClearAllPoints()
	root.FilterBar.RecentFilterDropdown:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
	root.FilterBar.RecentFilterDropdown:SetSize(92, MODERN_TOP_CONTROL_HEIGHT)
	ConstrainModernDropdownText(root.FilterBar.RecentFilterDropdown, 1)
	self:RefreshSortButtonText()

	root.BottomActionBar:ClearAllPoints()
	root.BottomActionBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	root.BottomActionBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	root.TopDivider:ClearAllPoints()
	root.TopDivider:SetSize(400, 3)
	root.TopDivider:SetPoint("TOPLEFT", root.FilterBar, "BOTTOMLEFT", 5, -3)
	root.TopDivider:SetPoint("TOPRIGHT", root.FilterBar, "BOTTOMRIGHT", -5, -3)
	root.BottomDivider:ClearAllPoints()
	root.BottomDivider:SetHeight(3)
	root.BottomDivider:SetPoint("BOTTOMLEFT", root.BottomActionBar, "TOPLEFT", 5, -6)
	root.BottomDivider:SetPoint("BOTTOMRIGHT", root.BottomActionBar, "TOPRIGHT", -5, -6)

	root.RequestsFrame:ClearAllPoints()
	root.RequestsFrame:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 8, -3)
	root.RequestsFrame:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -8, 8)
end

function FriendsUI:ApplyModernPortrait()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	local db = GetDB()
	local simpleMode = db and db.simpleMode == true
	local palette, themed = self:GetModernThemeColors()
	local flatTheme = BFL.UsesFlatTheme and BFL:UsesFlatTheme() == true
	local showNativePortraitChrome = not simpleMode and not flatTheme
	frame._bflModernPortraitChromeShown = showNativePortraitChrome
	-- PortraitFrame can restore its native portrait and corner artwork whenever
	-- the panel is shown. Reapply this state on every Modern layout pass rather
	-- than caching only the setting transition.
	if frame.SetPortraitShown then
		frame:SetPortraitShown(showNativePortraitChrome)
	end

	-- ButtonFrameTemplate_HidePortrait also moves Bg, Inset and
	-- TitleContainer. Modern owns the Contacts control-row compaction
	-- separately, so keep the frame geometry untouched here and exchange the
	-- integrated portrait corner artwork directly.
	local topLeftCorner = frame.NineSlice and frame.NineSlice.TopLeftCorner
	if topLeftCorner and topLeftCorner.SetAtlas then
		pcall(
			topLeftCorner.SetAtlas,
			topLeftCorner,
			showNativePortraitChrome and "UI-Frame-PortraitMetal-CornerTopLeft" or "UI-Frame-Metal-CornerTopLeft",
			true
		)
	end

	-- The native portrait TitleContainer is intentionally asymmetric. Anchor
	-- only its text to the actual frame so the title remains centered at every
	-- width and in both Simple Mode states without moving Battle.net chrome.
	local titleText = (frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText
	if titleText then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -5)
		titleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -72, -5)
		titleText:SetJustifyH("CENTER")
	end

	-- Parent-layer portrait regions render below child frames and would be cut
	-- by the Battle.net bar. Modern therefore owns a child-frame portrait layer.
	SafeShow(frame.portrait, false)
	SafeShow(frame.PortraitIcon, false)
	SafeShow(frame.PortraitMask, false)
	-- The visible Modern portrait is the interactive changelog button. Keeping
	-- the legacy button active underneath creates a second, differently placed
	-- hit rect (especially for EUI's lower logo offset) and makes only parts of
	-- the artwork clickable.
	SafeShow(frame.PortraitButton, false)
	-- External flat skins own a compact BFL logo and must not inherit the
	-- high-level PortraitFrame container restored by Blizzard's OnShow path.
	if frame.PortraitContainer then
		SafeShow(frame.PortraitContainer, showNativePortraitChrome)
		if frame.PortraitContainer.SetAlpha then
			frame.PortraitContainer:SetAlpha(showNativePortraitChrome and 1 or 0)
		end
	end
	local portrait = self.root and self.root.PortraitOverlay
	if portrait then
		portrait:ClearAllPoints()
		if themed then
			-- Flat themes use the established compact square; EUI supplies a lower
			-- offset so the BFL mark sits inside its Battle.net header strip.
			local portraitOffsetX = tonumber(palette and palette.portraitOffsetX)
				or MODERN_THEMED_PORTRAIT_OFFSET_X
			local portraitOffsetY = tonumber(palette and palette.portraitOffsetY)
				or MODERN_THEMED_PORTRAIT_OFFSET_Y
			local portraitSize = tonumber(palette and palette.portraitSize) or MODERN_THEMED_PORTRAIT_SIZE
			portrait:SetPoint(
				"TOPLEFT",
				frame,
				"TOPLEFT",
				portraitOffsetX,
				portraitOffsetY
			)
			portrait:SetSize(portraitSize, portraitSize)
			if portrait.Icon then
				portrait.Icon:SetSize(portraitSize, portraitSize)
				if portrait.Mask and portrait.Icon.RemoveMaskTexture and not portrait.BFL_ModernSquarePortrait then
					portrait.Icon:RemoveMaskTexture(portrait.Mask)
				end
			end
			SafeShow(portrait.Mask, false)
			portrait.BFL_ModernSquarePortrait = true
		else
			portrait:SetPoint("TOPLEFT", self.root, "TOPLEFT", -5, 7)
			portrait:SetSize(MODERN_PORTRAIT_SIZE, MODERN_PORTRAIT_SIZE)
			if portrait.Icon then
				portrait.Icon:SetSize(MODERN_PORTRAIT_SIZE, MODERN_PORTRAIT_SIZE)
				if portrait.Mask and portrait.Icon.AddMaskTexture and portrait.BFL_ModernSquarePortrait then
					portrait.Icon:AddMaskTexture(portrait.Mask)
				end
			end
			if portrait.Mask then
				portrait.Mask:SetSize(MODERN_PORTRAIT_SIZE, MODERN_PORTRAIT_SIZE)
			end
			SafeShow(portrait.Mask, true)
			portrait.BFL_ModernSquarePortrait = nil
		end
		SafeShow(portrait, not simpleMode)
	end
	-- PortraitFrame restores NineSlice artwork whenever it updates portrait
	-- visibility. Reassert the flat Modern theme shell after that native pass.
	if BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
		local SkinEngine = BFL:GetModule("SkinEngine")
		if SkinEngine and SkinEngine.IsActive and SkinEngine:IsActive() then
			SkinEngine:StripButtonFrameArtwork(frame, 0)
		end
	end
end

function FriendsUI:ApplyModernContentLayout(sectionID, skipNavigationRefresh)
	if not (self.root and BetterFriendsFrame) then
		return
	end
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	local headerControlOffsetY = self:GetModernHeaderControlOffsetY()
	self:ApplyModernRootGeometry()
	self:HideLegacyTabs()
	if header then
		if header.StatusDropdown then
			header.StatusDropdown:SetParent(self.root.BattleNetBar)
			header.StatusDropdown:ClearAllPoints()
			header.StatusDropdown:SetPoint("LEFT", self.root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
			header.StatusDropdown:SetSize(54, MODERN_TOP_CONTROL_HEIGHT)
			ConstrainModernDropdownText(header.StatusDropdown, nil, 4)
		end
		local bnetFrame = header.BattlenetFrame
		if bnetFrame then
			bnetFrame:SetParent(self.root.BattleNetBar)
			bnetFrame:ClearAllPoints()
			bnetFrame:SetPoint("LEFT", self.root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
			bnetFrame:SetPoint("RIGHT", self.root.BattleNetBar.MenuButton, "LEFT", -7, headerControlOffsetY)
			bnetFrame:Show()
			SafeShow(bnetFrame.Background, not (BFL.UsesFlatTheme and BFL:UsesFlatTheme()))
			SafeShow(bnetFrame.ContactsMenuButton, false)
			SafeShow(self.root.BattleNetBar.MenuButton, true)
			SafeShow(bnetFrame.SettingsButton, false)
		end
		if header.StatusDropdown and bnetFrame then
			header.StatusDropdown:SetFrameLevel(bnetFrame:GetFrameLevel() + 1)
		end
		self:LayoutBattleTagActions()
		self:HideModernLegacyHeaderDropdowns(header)
		local filterDropdown = self.root.FilterBar.FilterDropdown
		local QuickFilters = BFL:GetModule("QuickFilters")
		if filterDropdown and not filterDropdown._bflModernInitialized and QuickFilters and QuickFilters.InitDropdown then
			QuickFilters:InitDropdown(filterDropdown)
			filterDropdown._bflModernInitialized = true
		end
		if header.SearchBox and (sectionID == "friends" or sectionID == "recent_allies") then
			local simpleModeSearch = self:ShouldShowSimpleModeSearch(sectionID)
			local searchRightControl = sectionID == "recent_allies" and self.root.FilterBar.RecentFilterDropdown or filterDropdown
			header.SearchBox:SetParent(self.root.FilterBar)
			header.SearchBox:ClearAllPoints()
			header.SearchBox:SetPoint("LEFT", self.root.FilterBar, "LEFT", 15, 0)
			if simpleModeSearch then
				header.SearchBox:SetPoint("RIGHT", self.root.FilterBar, "RIGHT", -7, 0)
			else
				header.SearchBox:SetPoint("RIGHT", searchRightControl, "LEFT", -7, 0)
			end
			header.SearchBox:SetHeight(MODERN_TOP_CONTROL_HEIGHT)
			ApplyModernSearchBoxVisual(header.SearchBox)
			if header.SearchBox.Instructions then
				header.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end
		end
	end
	local chrome, showFilter = self:ApplyContactChrome(sectionID, header)
	local reserveActionFooter = self:ShouldReserveModernActionFooter(sectionID, chrome)
	local raidLayout = sectionID == "raid"
	self:ApplyModernSectionTopChrome(sectionID)
	SafeShow(frame.AddFriendButton, false)
	SafeShow(frame.SendMessageButton, false)
	SafeShow(frame.RecruitmentButton, sectionID == "recruit_a_friend")

	if frame.Inset then
		frame.Inset:ClearAllPoints()
		if raidLayout then
			-- Match SocialUI's native raid content frame: it begins directly below
			-- the Battle.net bar and extends to the background's bottom edge.
			frame.Inset:SetPoint("TOPLEFT", self.root.BattleNetBar, "BOTTOMLEFT", 0, 5)
			frame.Inset:SetPoint("BOTTOMRIGHT", frame.Bg or frame, "BOTTOMRIGHT", 0, 0)
		elseif showFilter then
			frame.Inset:SetPoint("TOPLEFT", self.root.FilterBar, "BOTTOMLEFT", 8, -10)
			if reserveActionFooter then
				frame.Inset:SetPoint("BOTTOMRIGHT", self.root.BottomActionBar, "TOPRIGHT", -8, 1)
			else
				frame.Inset:SetPoint("BOTTOMRIGHT", frame.Bg or frame, "BOTTOMRIGHT", -8, 8)
			end
		else
			local background = frame.Bg or frame
			frame.Inset:SetPoint("TOPLEFT", self.root.TopDivider, "BOTTOMLEFT", 3, -7)
			if reserveActionFooter then
				frame.Inset:SetPoint("BOTTOMRIGHT", self.root.BottomActionBar, "TOPRIGHT", -8, 1)
			else
				frame.Inset:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -8, 8)
			end
		end
		frame.Inset:SetAlpha(0)
		frame.Inset:Show()
	end
	if frame.ScrollFrame then
		frame.ScrollFrame:ClearAllPoints()
		frame.ScrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -2)
		frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, -2)
	end
	for _, field in ipairs({ "RecentAlliesFrame", "RecruitAFriendFrame", "QuickJoinFrame", "WhoFrame", "RaidFrame", "GuildFrame" }) do
		local child = frame[field]
		if child then
			child:SetFrameLevel(self.root:GetFrameLevel() + 2)
			child:ClearAllPoints()
			child:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT")
			child:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT")
		end
	end
	self:ApplyModernDirectoryGeometry(sectionID)
	self:ApplyModernQuickJoinGeometry(sectionID)
	if frame.ScrollFrame then
		frame.ScrollFrame:SetFrameLevel(self.root:GetFrameLevel() + 2)
	end
	if frame.MinimalScrollBar then
		frame.MinimalScrollBar:SetFrameLevel(self.root:GetFrameLevel() + 3)
	end
	self.root.RequestsFrame:ClearAllPoints()
	self.root.RequestsFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT")
	self.root.RequestsFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT")
	self.root.RequestsFrame:SetShown(sectionID == "friend_requests")
	self:AnchorAuxiliaryWindow(frame.IgnoreListWindow, 0)
	self:ApplyModernRaidGeometry()
	if sectionID == "raid" then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame and RaidFrame.UpdateGroupLayout then
			RaidFrame._lastLayoutWidth = nil
			RaidFrame._lastLayoutHeight = nil
			RaidFrame:UpdateGroupLayout()
		end
	end
	self:ApplyModernScrollBarGeometry()
	self:ApplyFriendsRestrictionState(sectionID)
	if frame.TitleText then
		local definition = SECTION_BY_ID[sectionID]
		frame.TitleText:SetText(definition and (GetL()[definition.labelKey] or definition.id) or "BetterFriendlist")
	end
	if not skipNavigationRefresh then
		self:RefreshNavigation()
	end

	-- Native tab setup can create controls or restore atlas artwork after the
	-- global theme pass.  Re-skin only the visible Modern content once its final
	-- geometry and visibility are known; this keeps Guild/Who/RAF correct on the
	-- first visit without touching the Legacy layout.
	if BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
		local SkinEngine = BFL:GetModule("SkinEngine")
		local DarkTheme = BFL:GetModule("DarkTheme")
		if
			SkinEngine
			and SkinEngine.IsActive
			and SkinEngine:IsActive()
			and DarkTheme
			and DarkTheme.SkinModernVisibleMainContent
		then
			DarkTheme:SkinModernVisibleMainContent(SkinEngine, frame)
		end
	end
end

-- Refresh the Modern configuration-dependent geometry without rebuilding the
-- complete interface style.  Settings callbacks use this contract when a
-- visibility-affecting option changes; the friend-list render hot path must
-- not be responsible for repairing unrelated frame geometry.
function FriendsUI:RefreshModernConfigurationLayout(reason)
	if not (self:IsModernActive() and self.root and BetterFriendsFrame) then
		return false
	end

	self:ApplyModernPortrait()
	self:ApplyModernContentLayout(self:GetSelectedSection() or "friends", true)
	self:RefreshModernSideTabSelection()
	self.lastModernConfigurationLayoutReason = reason
	return true
end

function FriendsUI:ApplyModernLayout()
	local root = self:CreateModernRoot()
	if not root or not BetterFriendsFrame then
		return
	end
	self:CaptureLegacyLayout()
	self:ApplyModernActionButtonTemplates()
	root:Show()
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	local headerControlOffsetY = self:GetModernHeaderControlOffsetY()
	if BFL.FrameInitializer and BFL.FrameInitializer.InitializeStatusDropdown then
		BFL.FrameInitializer:InitializeStatusDropdown(frame)
	end
	self:ApplyModernRootGeometry()
	self:HideLegacyTabs()
	if header then
		for _, field in ipairs({ "Tab1", "Tab2", "Tab3", "Tab4", "PrimarySortDropdown", "SecondarySortDropdown", "SettingsButton" }) do
			SafeShow(header[field], false)
		end
		if header.StatusDropdown then
			header.StatusDropdown:SetParent(root.BattleNetBar)
			header.StatusDropdown:ClearAllPoints()
			header.StatusDropdown:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
			header.StatusDropdown:SetSize(54, MODERN_TOP_CONTROL_HEIGHT)
			ConstrainModernDropdownText(header.StatusDropdown, nil, 4)
			header.StatusDropdown:Show()
		end
		if header.BattlenetFrame then
			local bnetFrame = header.BattlenetFrame
			bnetFrame:SetParent(root.BattleNetBar)
			bnetFrame:ClearAllPoints()
			bnetFrame:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, headerControlOffsetY)
			bnetFrame:SetPoint("RIGHT", root.BattleNetBar.MenuButton, "LEFT", -7, headerControlOffsetY)
			bnetFrame:Show()
			SafeShow(bnetFrame.Background, not (BFL.UsesFlatTheme and BFL:UsesFlatTheme()))
			SafeShow(bnetFrame.ContactsMenuButton, false)
			SafeShow(root.BattleNetBar.MenuButton, true)
			SafeShow(bnetFrame.SettingsButton, false)
		end
		if header.StatusDropdown and header.BattlenetFrame then
			header.StatusDropdown:SetFrameLevel(header.BattlenetFrame:GetFrameLevel() + 1)
		end
		self:InstallBroadcastFrameAnchorHook()
		self:LayoutBattleTagActions()
		self:HideModernLegacyHeaderDropdowns(header)
		local filterDropdown = root.FilterBar.FilterDropdown
		local QuickFilters = BFL:GetModule("QuickFilters")
		if filterDropdown and not filterDropdown._bflModernInitialized and QuickFilters and QuickFilters.InitDropdown then
			QuickFilters:InitDropdown(filterDropdown)
			filterDropdown._bflModernInitialized = true
		end
		if header.SearchBox then
			header.SearchBox:SetParent(root.FilterBar)
			header.SearchBox:ClearAllPoints()
			header.SearchBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
			header.SearchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -7, 0)
			header.SearchBox:SetHeight(MODERN_TOP_CONTROL_HEIGHT)
			ApplyModernSearchBoxVisual(header.SearchBox)
			if header.SearchBox.Instructions then
				header.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end
		end
	end
	self:ApplyModernPortrait()
	self:RefreshBattleTag()
	self:ApplyModernContentLayout(self.selectedSection or "friends")
	self:RefreshRequests(false)
end

function FriendsUI:RestoreLegacyLayout()
	if not BetterFriendsFrame then
		return
	end
	SafeShow(self.root, false)
	self:RestoreLegacyActionButtonTemplates()
	self:RestoreLegacyQuickJoinGeometry()
	if self.legacyState then
		for _, state in pairs(self.legacyState.frames) do
			RestoreFrameState(state, true)
		end
		if BetterFriendsFrame.portrait and self.legacyState.portraitTexture then
			BetterFriendsFrame.portrait:SetTexture(self.legacyState.portraitTexture)
		end
		if BetterFriendsFrame.TitleText then
			BetterFriendsFrame.TitleText:SetText(self.legacyState.title or "BetterFriendlist")
		end
		for _, state in pairs(self.legacyState.regions or {}) do
			RestoreRegionState(state)
		end
		local header = BetterFriendsFrame.FriendsTabHeader
		if header and header.SearchBox and header.SearchBox.Instructions and self.legacyState.searchInstruction then
			header.SearchBox.Instructions:SetText(self.legacyState.searchInstruction)
		end
	end
	self:InstallBroadcastFrameAnchorHook()
	SafeShow(self.root and self.root.PortraitOverlay, false)
	self:RestoreLegacyTabs(false)
	self:RestoreLegacyMainInsetLayout()
	local who = BetterFriendsFrame.WhoFrame
	if who then
		for _, headerButton in ipairs({ who.NameHeader, who.ColumnDropdown, who.LevelHeader, who.ClassHeader }) do
			if headerButton then
				for _, key in ipairs({ "Left", "Middle", "Right" }) do
					local texture = headerButton[key]
					if texture then
						texture:SetHeight(35)
						local left, right = key == "Left" and 0 or key == "Middle" and 0.078125 or 0.90625,
							key == "Left" and 0.078125 or key == "Middle" and 0.90625 or 1
						texture:SetTexCoord(left, right, 0, 1)
						texture:SetDesaturated(false)
						texture:SetVertexColor(1, 1, 1, 1)
						texture:Show()
					end
				end
				headerButton.BFL_ModernHeaderTone = nil
				SafeShow(headerButton.Background, true)
				SafeShow(headerButton.NineSlice, true)
				if headerButton.BFL_ModernHeaderBackground then
					headerButton.BFL_ModernHeaderBackground:SetDesaturated(false)
					headerButton.BFL_ModernHeaderBackground:SetVertexColor(1, 1, 1, 1)
					headerButton.BFL_ModernHeaderBackground:Hide()
				end
			end
		end
		SafeShow(who.ListInset and who.ListInset.Bg, true)
		SafeShow(who.ListInset and who.ListInset.NineSlice, true)
		SafeShow(who.EditBox and who.EditBox.Backdrop, true)
	end
	local guild = BetterFriendsFrame.GuildFrame
	if guild then
		SafeShow(guild.ListInset and guild.ListInset.Bg, true)
		SafeShow(guild.ListInset and guild.ListInset.NineSlice, true)
		SafeShow(guild.HeaderDivider, true)
		local GuildFrame = BFL:GetModule("GuildFrame")
		if GuildFrame and GuildFrame.UpdateLayout then
			GuildFrame._lastLayoutWidth = nil
			GuildFrame:UpdateLayout()
		end
		-- Guild's XML OnLoad can run while the saved style is Modern. Rebuild
		-- the v2.7.0 rail explicitly so a cold Modern -> Legacy switch does not
		-- inherit the narrow SocialUI gutter captured during startup.
		if guild.ScrollBox and guild.ListInset then
			guild.ScrollBox:ClearAllPoints()
			guild.ScrollBox:SetPoint("TOPLEFT", guild.ListInset, "TOPLEFT", 4, -4)
			guild.ScrollBox:SetPoint("BOTTOMRIGHT", guild.ListInset, "BOTTOMRIGHT", -22, 2)
		end
		if guild.ScrollBar and guild.ScrollBox then
			guild.ScrollBar:ClearAllPoints()
			guild.ScrollBar:SetWidth(22)
			guild.ScrollBar:SetPoint("TOPLEFT", guild.ScrollBox, "TOPRIGHT", 0, 0)
			guild.ScrollBar:SetPoint("BOTTOMLEFT", guild.ScrollBox, "BOTTOMRIGHT", 0, 0)
		end
	end
	self:RestoreLegacyRaidGeometry()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if RaidFrame and RaidFrame.UpdateGroupLayout then
		RaidFrame._lastLayoutWidth = nil
		RaidFrame._lastLayoutHeight = nil
		RaidFrame._lastLayoutModern = nil
		RaidFrame:UpdateGroupLayout()
		RaidFrame:UpdateControlPanel()
	end
	if BFL.UpdatePortraitVisibility then
		BFL:UpdatePortraitVisibility()
	end
	if BFL.FrameInitializer and BFL.FrameInitializer.InitializeStatusDropdown then
		BFL.FrameInitializer:InitializeStatusDropdown(BetterFriendsFrame)
	end
	if BFL.FrameInitializer and BFL.FrameInitializer.InitializeSortDropdowns then
		BFL.FrameInitializer:InitializeSortDropdowns(BetterFriendsFrame)
	end
	local QuickFilters = BFL:GetModule("QuickFilters")
	local header = BetterFriendsFrame.FriendsTabHeader
	if QuickFilters and QuickFilters.InitDropdown and header and header.QuickFilterDropdown then
		QuickFilters:InitDropdown(header.QuickFilterDropdown)
	end
	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame and WhoFrame.RestoreLegacySearchBuilderLayout then
		WhoFrame:RestoreLegacySearchBuilderLayout()
	end
	if WhoFrame and WhoFrame.UpdateResponsiveLayout then
		WhoFrame._lastLayoutWidth = nil
		WhoFrame:UpdateResponsiveLayout()
	end
end

function FriendsUI:GetSelectedSection()
	if self.selectedSection then
		return self.selectedSection
	end
	if BetterFriendsFrame then
		local bottom = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
		local header = BetterFriendsFrame.FriendsTabHeader
		local top = header and PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(header) or 1
		return self:GetSectionForLegacyTabs(bottom, top)
	end
	return "friends"
end

function FriendsUI:SelectSection(sectionID)
	if not SECTION_BY_ID[sectionID] then
		sectionID = "friends"
	end
	if not self:IsSectionAvailable(sectionID) or (sectionID == "raid" and self:IsStoryRaidActive()) then
		sectionID = self:BuildAvailableSectionIDs()[1] or "friends"
	end
	if not self:IsModernActive() and sectionID == "friend_requests" then
		sectionID = "friends"
	end
	self.selectedSection = sectionID
	self.selectingSection = true
	if self:IsModernActive() and sectionID == "friend_requests" then
		self:HideAllContentFrames()
		self:StopRequestGlow()
		self:RefreshRequests(false)
	else
		local definition = SECTION_BY_ID[sectionID]
		if definition and definition.bottomTab and BetterFriendsFrame_ShowBottomTab then
			BetterFriendsFrame_ShowBottomTab(definition.bottomTab)
		end
		if definition and definition.topTab and BetterFriendsFrame_ShowTab then
			BetterFriendsFrame_ShowTab(definition.topTab)
		end
	end
	self.selectingSection = false
	if self:IsModernActive() then
		self:ApplyModernContentLayout(sectionID)
	end
	return sectionID
end

function FriendsUI:ToggleSection(sectionID)
	if not BetterFriendsFrame then
		return
	end
	if BetterFriendsFrame:IsShown() and self:GetSelectedSection() == sectionID then
		BetterFriendsFrame:Hide()
		return
	end
	if not BetterFriendsFrame:IsShown() then
		if ShowUIPanel then
			ShowUIPanel(BetterFriendsFrame)
		else
			BetterFriendsFrame:Show()
		end
	end
	self:SelectSection(sectionID)
end

function FriendsUI:OnTextScaleUpdated()
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.OnTextScaleUpdated then
		FriendsList:OnTextScaleUpdated()
	end
	local RecentAllies = BFL:GetModule("RecentAllies")
	if RecentAllies and RecentAllies.OnTextScaleUpdated then
		RecentAllies:OnTextScaleUpdated()
	end
	local RAF = BFL:GetModule("RAF")
	if RAF and RAF.OnTextScaleUpdated then
		RAF:OnTextScaleUpdated()
	end
	if self.requestsInitialized then
		self:RefreshRequests(false)
		self:LayoutRealIDWarning()
	end
	if self:IsModernActive() then
		self:ApplyModernContentLayout(self:GetSelectedSection() or "friends", true)
	end
	self:RefreshFriendsFriendsFrame()
end

function FriendsUI:HideOwnedSideWindows()
	local broadcastFrame = self:GetBroadcastFrame()
	if broadcastFrame and broadcastFrame:IsShown() then
		if broadcastFrame.HideFrame then
			broadcastFrame:HideFrame()
		else
			broadcastFrame:Hide()
		end
	end

	local ignoreWindow = BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow
	if ignoreWindow and ignoreWindow:IsShown() then
		ignoreWindow:Hide()
	end

	if RaidInfoFrame and RaidInfoFrame:IsShown() and RaidInfoFrame:GetParent() == BetterFriendsFrame then
		RaidInfoFrame:Hide()
	end

	self.activeSocialSideWindowType = nil
end

function FriendsUI:HideSocialUIReplacement()
	self:HideOwnedSideWindows()
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		if HideBetterFriendsFrame then
			HideBetterFriendsFrame()
		else
			BetterFriendsFrame:Hide()
		end
	end
end

function FriendsUI:OpenSocialUISection(sectionID)
	sectionID = self:GetSectionForSocialTab(sectionID) or sectionID or "friends"
	if not BetterFriendsFrame then
		return false
	end
	if not BetterFriendsFrame:IsShown() then
		if ShowUIPanel then
			ShowUIPanel(BetterFriendsFrame)
		else
			BetterFriendsFrame:Show()
		end
	end
	self:SelectSection(sectionID)
	return true
end

function FriendsUI:ToggleSocialUIReplacement()
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		self:HideSocialUIReplacement()
	else
		self:HideOwnedSideWindows()
		self:OpenSocialUISection(self:GetSelectedSection() or "friends")
	end
end

function FriendsUI:ShowSocialSideWindow(sideWindowType)
	local sideTypes = _G.SocialUISideWindowType
	if not sideTypes then
		return false
	end

	self:HideOwnedSideWindows()
	local opened = false
	local function TrackWindow(window)
		if not (window and window.HookScript) then
			return
		end
		window.BFL_SocialSideWindowType = sideWindowType
		if not window.BFL_SocialSideWindowHideHooked then
			window.BFL_SocialSideWindowHideHooked = true
			window:HookScript("OnHide", function(hiddenWindow)
				if self.activeSocialSideWindowType == hiddenWindow.BFL_SocialSideWindowType then
					self.activeSocialSideWindowType = nil
				end
			end)
		end
	end
	if sideWindowType == sideTypes.BattleNetBroadcastFrame then
		local broadcastFrame = self:GetBroadcastFrame()
		if broadcastFrame then
			self:AnchorAuxiliaryWindow(broadcastFrame, 0)
			if broadcastFrame.ShowFrame then
				broadcastFrame:ShowFrame()
			else
				broadcastFrame:Show()
			end
			TrackWindow(broadcastFrame)
			opened = true
		end
	elseif sideWindowType == sideTypes.IgnoreListFrame then
		local ignoreWindow = BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow
		if ignoreWindow then
			self:AnchorAuxiliaryWindow(ignoreWindow, 0)
			ignoreWindow:Show()
			TrackWindow(ignoreWindow)
			opened = true
		end
	elseif sideWindowType == sideTypes.RaidInfoFrame then
		if not RaidInfoFrame and C_AddOns and C_AddOns.LoadAddOn then
			pcall(C_AddOns.LoadAddOn, "Blizzard_RaidUI")
		end
		local raidButton = BetterFriendsFrame
			and BetterFriendsFrame.RaidFrame
			and BetterFriendsFrame.RaidFrame.ControlPanel
			and BetterFriendsFrame.RaidFrame.ControlPanel.RaidInfoButton
		if raidButton and BetterRaidFrame_RaidInfoButton_OnClick then
			BetterRaidFrame_RaidInfoButton_OnClick(raidButton)
			opened = RaidInfoFrame and RaidInfoFrame:IsShown() or false
			if opened then
				TrackWindow(RaidInfoFrame)
			end
		end
	elseif sideWindowType == sideTypes.BattleNetUnavailableNoticeFrame then
		-- BFL exposes the same state inline in the Battle.net header. Keeping the
		-- main frame open is the BFL equivalent of Blizzard's separate notice.
		opened = true
	end

	if opened then
		self.activeSocialSideWindowType = sideWindowType
	end
	return opened
end

function FriendsUI:ToggleSocialSectionAndSideWindow(tabType, sideWindowType)
	local sectionID = self:GetSectionForSocialTab(tabType) or "friends"
	local alreadyOpen = BetterFriendsFrame
		and BetterFriendsFrame:IsShown()
		and self:GetSelectedSection() == sectionID
		and self.activeSocialSideWindowType == sideWindowType
	if alreadyOpen then
		self:HideSocialUIReplacement()
		return
	end

	self:OpenSocialUISection(sectionID)
	self:ShowSocialSideWindow(sideWindowType)
end

function FriendsUI:SetStyle(style)
	if style ~= STYLE_MODERN and style ~= STYLE_LEGACY then
		return false
	end
	if style == STYLE_MODERN and not self:IsModernStyleSelectable() and not self:IsModernForceEnabled() then
		return false
	end
	local FrameSettings = BFL:GetModule("FrameSettings")
	if FrameSettings and FrameSettings.SavePosition then
		FrameSettings:SavePosition()
	end
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("friendsFrameStyle", style)
	elseif BetterFriendlistDB then
		BetterFriendlistDB.friendsFrameStyle = style
	end
	self:ApplyEffectiveStyle("setting")
	return true
end

function FriendsUI:SetModernForceEnabled(enabled)
	if not BFL.IsRetail then
		return false
	end
	enabled = enabled == true
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("forceModernFriendsUI", enabled)
		if enabled then
			DB:Set("friendsFrameStyle", STYLE_MODERN)
		end
	elseif BetterFriendlistDB then
		BetterFriendlistDB.forceModernFriendsUI = enabled
		if enabled then
			BetterFriendlistDB.friendsFrameStyle = STYLE_MODERN
		end
	end
	self:ApplyEffectiveStyle("force-modern")
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.RefreshGeneralTab then
		Settings:RefreshGeneralTab()
	end
	local SettingsDesigner = BFL:GetModule("SettingsDesigner")
	if SettingsDesigner and SettingsDesigner.RefreshFriendsUIAvailability then
		SettingsDesigner:RefreshFriendsUIAvailability()
	end
	local AppearanceOnboarding = BFL:GetModule("AppearanceOnboarding")
	if AppearanceOnboarding and AppearanceOnboarding.OnModernAvailabilityChanged then
		AppearanceOnboarding:OnModernAvailabilityChanged("force-modern")
	end
	return true
end

function FriendsUI:RefreshEffectiveStyleOnShow()
	local effective = self:GetEffectiveStyle()
	if self.appliedStyle ~= effective then
		return self:ApplyEffectiveStyle("show-style-change")
	end

	-- The frame hierarchy and selected section survive Hide/Show. Reapplying the
	-- complete style here needlessly rebuilds controls, refreshes the friend
	-- provider, and asks every theme integration to reskin all of its windows.
	-- Refresh only the visual state which Blizzard's frame templates can restore.
	if effective == STYLE_MODERN then
		-- Blizzard can restore child visibility, anchors, and template artwork
		-- while the frame is hidden.  Reassert only the selected section's
		-- configuration-dependent layout instead of rebuilding the entire style.
		self:RefreshModernConfigurationLayout("frame-show")
		-- ElvUI does not use BFL's flat-theme palette and therefore owns its own
		-- portrait suppression. EUI schedules its focused facade pass from the
		-- frame's OnShow hook; Dark and Custom need no work beyond the portrait.
		local theme = (BFL.GetEffectiveTheme and BFL:GetEffectiveTheme()) or self.currentTheme
		if theme == "elvui" then
			local ElvUISkin = BFL:GetModule("ElvUISkin")
			if ElvUISkin and ElvUISkin.RefreshModernSkin then
				ElvUISkin:RefreshModernSkin()
			end
		elseif theme == "ellesmereui" then
			local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
			if EllesmereUISkin and EllesmereUISkin.RefreshModernPortraitCorner then
				EllesmereUISkin:RefreshModernPortraitCorner(BetterFriendsFrame)
			end
		end
	else
		self:RestoreLegacyTabs(false)
		local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
		if EllesmereUISkin and EllesmereUISkin.RefreshMainFrame then
			EllesmereUISkin:RefreshMainFrame("friends-ui-show")
		end
	end
	return true
end

function FriendsUI:ApplyEffectiveStyle(reason)
	local effective = self:GetEffectiveStyle()
	if InCombatLockdown and InCombatLockdown() then
		self.pendingStyle = effective
		return false
	end
	local selected = self:GetSelectedSection()
	if self.appliedStyle and self.appliedStyle ~= effective then
		local previousFrameSettings = BFL:GetModule("FrameSettings")
		if previousFrameSettings and previousFrameSettings.SavePosition then
			previousFrameSettings:SavePosition()
		end
	end
	self.appliedStyle = effective
	self.pendingStyle = nil
	if effective == STYLE_MODERN then
		self:ApplyModernLayout()
	else
		self:RestoreLegacyLayout()
	end
	-- RAF replaces action buttons according to the active style. Run it only
	-- after the frame hierarchy has been restored so Legacy can never mistake
	-- the Modern inset for the main frame owner.
	local RAF = BFL:GetModule("RAF")
	local rafFrame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
	if RAF and RAF.ApplyFrameStyle and rafFrame then
		RAF:ApplyFrameStyle(rafFrame)
	end
	if RAF and RAF.AnchorRewardsFrame and RecruitAFriendRewardsFrame and RecruitAFriendRewardsFrame:IsShown() then
		RAF:AnchorRewardsFrame()
	end
	local FrameSettings = BFL:GetModule("FrameSettings")
	if FrameSettings and FrameSettings.ApplySettings then
		FrameSettings:ApplySettings()
	end
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.ApplyFriendsUIStyle then
		QuickJoin:ApplyFriendsUIStyle()
	end
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.OnFriendsUIStyleChanged then
		FriendsList:OnFriendsUIStyleChanged(effective, reason)
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme()
	end
	self:SelectSection(selected)
	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
		if effective == STYLE_LEGACY then
			if WhoFrame.RestoreLegacyLayout then
				WhoFrame:RestoreLegacyLayout()
			end
		end
		if WhoFrame.RefreshActionButtonState then
			WhoFrame:RefreshActionButtonState()
		end
	end
	if effective == STYLE_LEGACY then
		self:RestoreLegacyTabs(false)
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.UpdateSearchBoxState then
			FriendsList:UpdateSearchBoxState()
		end
		if FriendsList and FriendsList.UpdateScrollBoxExtent then
			FriendsList:UpdateScrollBoxExtent()
		end
	end
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.RefreshVisibleWindowAnchor then
		Settings:RefreshVisibleWindowAnchor()
	end
	return true
end

function FriendsUI:OnLegacyTabSelected()
	if self.selectingSection then
		return
	end
	local bottom = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
	local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
	local top = header and PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(header) or 1
	self.selectedSection = self:GetSectionForLegacyTabs(bottom, top)
	if self:IsModernActive() then
		self:ApplyModernContentLayout(self.selectedSection)
	else
		-- Bottom-tab changes hide and show the header as a whole. Rebuild its
		-- capability mask afterwards so Guild does not disappear when returning
		-- to Contacts, and keep RAF's action button tied to the selected top tab.
		self:RestoreLegacyTabs(false)
	end
end

function FriendsUI:InstallTabHooks()
	if self.tabHooksInstalled or not hooksecurefunc then
		return
	end
	if BetterFriendsFrame_ShowTab then
		hooksecurefunc("BetterFriendsFrame_ShowTab", function()
			self:OnLegacyTabSelected()
		end)
	end
	if BetterFriendsFrame_ShowBottomTab then
		hooksecurefunc("BetterFriendsFrame_ShowBottomTab", function()
			self:OnLegacyTabSelected()
		end)
	end
	self.tabHooksInstalled = true
end

function FriendsUI:InstallSocialUIRedirects()
	if self.redirectsInstalled and self.socialUIRedirectControl == _G.SocialUIControl then
		return
	elseif self.redirectsInstalled then
		self:RestoreSocialUIRedirects()
	end
	if not (BFL.IsRetail and self:IsSocialUIAvailable()) then
		return
	end
	if not _G.SocialUIControl then
		return
	end
	self.redirectsInstalled = true
	self.originalToggleSocialUI = _G.ToggleSocialUI
	self.originalSocialUIControl = {}
	if SocialUIControl then
		for _, key in ipairs({ "Toggle", "OpenToTab", "ToggleToTab", "ToggleToTabAndSideWindow", "Hide" }) do
			self.originalSocialUIControl[key] = SocialUIControl[key]
		end
	end
	self.socialUIRedirectControl = SocialUIControl
	self.socialUIRedirectFunctions = {}
	self.socialUIRedirectFunctions.ToggleSocialUI = function()
		self:ToggleSocialUIReplacement()
	end
	_G.ToggleSocialUI = self.socialUIRedirectFunctions.ToggleSocialUI
	if SocialUIControl then
		self.socialUIRedirectFunctions.Toggle = function()
			self:ToggleSocialUIReplacement()
		end
		self.socialUIRedirectFunctions.OpenToTab = function(tabType)
			self:HideOwnedSideWindows()
			self:OpenSocialUISection(tabType)
		end
		self.socialUIRedirectFunctions.ToggleToTab = function(tabType)
			self:HideOwnedSideWindows()
			self:ToggleSection(self:GetSectionForSocialTab(tabType) or "friends")
		end
		self.socialUIRedirectFunctions.ToggleToTabAndSideWindow = function(tabType, sideWindowType)
			self:ToggleSocialSectionAndSideWindow(tabType, sideWindowType)
		end
		self.socialUIRedirectFunctions.Hide = function()
			self:HideSocialUIReplacement()
		end
		SocialUIControl.Toggle = self.socialUIRedirectFunctions.Toggle
		SocialUIControl.OpenToTab = self.socialUIRedirectFunctions.OpenToTab
		SocialUIControl.ToggleToTab = self.socialUIRedirectFunctions.ToggleToTab
		SocialUIControl.ToggleToTabAndSideWindow = self.socialUIRedirectFunctions.ToggleToTabAndSideWindow
		SocialUIControl.Hide = self.socialUIRedirectFunctions.Hide
	end
end

function FriendsUI:RestoreSocialUIRedirects()
	if not self.redirectsInstalled then
		return
	end
	local redirects = self.socialUIRedirectFunctions or {}
	if _G.ToggleSocialUI == redirects.ToggleSocialUI then
		_G.ToggleSocialUI = self.originalToggleSocialUI
	end
	local control = self.socialUIRedirectControl
	if control and self.originalSocialUIControl then
		for _, key in ipairs({ "Toggle", "OpenToTab", "ToggleToTab", "ToggleToTabAndSideWindow", "Hide" }) do
			if control[key] == redirects[key] then
				control[key] = self.originalSocialUIControl[key]
			end
		end
	end
	self.redirectsInstalled = false
	self.originalToggleSocialUI = nil
	self.originalSocialUIControl = nil
	self.socialUIRedirectControl = nil
	self.socialUIRedirectFunctions = nil
end

function FriendsUI:EnsureSocialUIRedirects()
	if not BFL.IsRetail then
		return
	end
	if not self:IsSocialUIAvailable() then
		self:RestoreSocialUIRedirects()
		return
	end
	if not _G.SocialUIControl and C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_SocialUIShared")
	end
	self:InstallSocialUIRedirects()
end

function FriendsUI:GetBlizzardSocialTab(sectionID)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	return self:GetSocialTabForSection(sectionID) or tab.Friends
end

function FriendsUI:OpenLoadedBlizzardSocialUI(frame, tabType)
	if not frame then
		return false
	end
	if frame:IsShown() then
		if tabType and frame.SelectTab then
			frame:SelectTab(tabType)
		end
		return true
	end
	if tabType and frame.SetDeferredOpenTab then
		frame:SetDeferredOpenTab(tabType)
	end
	local originalControl = self.originalSocialUIControl
	if originalControl and originalControl.Toggle then
		originalControl.Toggle()
		return true
	end
	if ShowUIPanel then
		ShowUIPanel(frame)
	elseif frame.Show then
		frame:Show()
	end
	return true
end

function FriendsUI:OpenBlizzardSocialUI(sectionID)
	if not _G.SocialUIFrame and C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_SocialUI")
	end
	local tabType = self:GetBlizzardSocialTab(sectionID or self:GetSelectedSection())
	return self:OpenLoadedBlizzardSocialUI(_G.SocialUIFrame, tabType)
end

function FriendsUI:RefreshModernThemeRows()
	if not self:IsModernActive() then
		return
	end

	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.scrollBox and FriendsList.scrollBox.ForEachFrame then
		FriendsList.scrollBox:ForEachFrame(function(row)
			if row.CardBackground then
				self:StyleFriendCard(row)
			elseif row.HeaderText then
				self:StyleGroupHeader(row)
			end
		end)
	end

	local requests = self.root and self.root.RequestsFrame
	if requests and requests.ScrollBox and requests.ScrollBox.ForEachFrame then
		requests.ScrollBox:ForEachFrame(function(row)
			if row.Background then
				self:StyleRequestCard(row)
			elseif row.ButtonText then
				self:StyleRequestHeader(row)
			end
		end)
	end

	local recent = BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame
	if recent and recent.ScrollBox and recent.ScrollBox.ForEachFrame then
		local _, themed = self:GetModernThemeColors()
		local SkinEngine = BFL:GetModule("SkinEngine")
		recent.ScrollBox:ForEachFrame(function(row)
			if row.PartyButton then
				row.PartyButton.BFL_DarkForceFlatButton = themed and true or nil
				if themed and SkinEngine and SkinEngine.RefreshRow then
					SkinEngine:RefreshRow(row)
				end
			elseif row.Text and row.Background then
				local RecentAllies = BFL:GetModule("RecentAllies")
				if RecentAllies and RecentAllies.InitializeHeader then
					RecentAllies:InitializeHeader(row, row.elementData or { headerText = row.Text:GetText() })
				end
			end
		end)
	end

	local quickJoin = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	local quickJoinScrollBox = quickJoin
		and quickJoin.ContentInset
		and quickJoin.ContentInset.ScrollBox
	if quickJoinScrollBox and quickJoinScrollBox.ForEachFrame then
		quickJoinScrollBox:ForEachFrame(function(row)
			self:StyleQuickJoinCard(row)
		end)
	end
end

function FriendsUI:ApplyModernVisibleControlTheme(palette, themed)
	if not BetterFriendsFrame then
		return
	end

	local frame = BetterFriendsFrame
	local raf = frame.RecruitAFriendFrame
	local who = frame.WhoFrame
	local raid = frame.RaidFrame
	local quickJoin = frame.QuickJoinFrame
	local guild = frame.GuildFrame
	local WhoFrame = BFL:GetModule("WhoFrame")
	local builder = WhoFrame and WhoFrame.builder
	local controls = {
		frame.RecruitmentButton,
		raf and raf.RewardClaiming and raf.RewardClaiming.ClaimOrViewRewardButton,
		raf and raf.RecruitList and raf.RecruitList.Header,
		raf and raf.SplashFrame and raf.SplashFrame.OKButton,
		who and who.EditBox,
		who and who.ColumnDropdown,
		who and who.WhoButton,
		who and who.AddFriendButton,
		who and who.GroupInviteButton,
		raid and raid.ControlPanel and raid.ControlPanel.RaidInfoButton,
		raid and raid.ControlPanel and raid.ControlPanel.ReadyCheckButton,
		raid and raid.ConvertToRaidButton,
		raid and raid.RaidToolsButton,
		quickJoin and quickJoin.ContentInset and quickJoin.ContentInset.JoinQueueButton,
		guild and guild.SearchBox,
		guild and guild.FilterDropdown,
		guild and guild.SortDropdown,
		guild and guild.NameHeader,
		guild and guild.RankHeader,
		guild and guild.LevelHeader,
		guild and guild.ZoneHeader,
		guild and guild.ILvlHeader,
		guild and guild.FilterAll,
		guild and guild.FilterOnline,
		guild and guild.FilterOffline,
		guild and guild.ActionsButton,
		guild and guild.InvitePlayerButton,
		builder and builder.nameInput,
		builder and builder.guildInput,
		builder and builder.zoneInput,
		builder and builder.levelMin,
		builder and builder.levelMax,
		builder and builder.classDropdown,
		builder and builder.raceDropdown,
		builder and builder.searchBtn,
		builder and builder.resetBtn,
	}
	for _, control in pairs(controls) do
		ApplyModernControlTheme(control, palette, themed)
	end

	for _, searchBox in pairs({
		who and who.EditBox,
		guild and guild.SearchBox,
		builder and builder.nameInput,
		builder and builder.guildInput,
		builder and builder.zoneInput,
	}) do
		if searchBox then
			ApplyThemedFontColor(searchBox, searchBox.Instructions, palette.disabledText, themed)
			ApplyTextureColor(
				searchBox.searchIcon,
				themed and OpaqueThemeColor(palette.accent) or MODERN_BLIZZARD_THEME_COLORS.control
			)
		end
	end
	if builder then
		for _, fontString in ipairs({
			builder.levelLabel,
			builder.levelToLabel,
			builder.previewLabel,
			builder.previewText,
		}) do
			ApplyThemedFontColor(WhoFrame.builderFlyout, fontString, palette.text, themed)
		end
		for _, row in ipairs(builder.fieldRows or {}) do
			ApplyThemedFontColor(WhoFrame.builderFlyout, row.label, palette.text, themed)
		end
		for _, dropdown in ipairs(builder.dropdowns or {}) do
			ApplyThemedFontColor(WhoFrame.builderFlyout, dropdown.BFL_ModernBuilderLabel, palette.text, themed)
		end
	end

	local rewardPanel = raf and raf.RewardClaiming
	if rewardPanel and rewardPanel.Background then
		ApplyModernAtlasColor(rewardPanel.Background, palette.surface, themed)
		if themed then
			local SkinEngine = BFL:GetModule("SkinEngine")
			if SkinEngine and SkinEngine.StyleBackdrop then
				SkinEngine:StyleBackdrop(rewardPanel, palette.surface, palette.border)
			end
		end
		ApplyThemedFontColor(rewardPanel, rewardPanel.MonthCount, palette.text, themed)
		ApplyThemedFontColor(rewardPanel, rewardPanel.EarnInfo, palette.text, themed)
		ApplyThemedFontColor(rewardPanel, rewardPanel.NextRewardName, palette.accent, themed)
	end
	local recruitHeader = raf and raf.RecruitList and raf.RecruitList.Header
	if recruitHeader then
		ApplyThemedFontColor(recruitHeader, recruitHeader.RecruitedFriends, palette.accent, themed)
		ApplyThemedFontColor(recruitHeader, recruitHeader.Count, palette.text, themed)
	end

	local groups = raid and raid.GroupsInset and raid.GroupsInset.GroupsContainer
	if groups then
		for index = 1, 8 do
			local group = groups["Group" .. index]
			if group then
				ApplyModernAtlasColor(group.Background, palette.surface, themed)
				ApplyThemedFontColor(group, group.GroupTitle, palette.text, themed)
			end
		end
	end
	if raid then
		ApplyThemedFontColor(raid, raid.NotInRaid, palette.disabledText, themed)
		local control = raid.ControlPanel
		if control then
			ApplyThemedFontColor(control, control.EveryoneAssistLabel, palette.text, themed)
			ApplyThemedFontColor(control, control.MemberCount, palette.text, themed)
			for _, roleFrame in pairs({ control.TankFrame, control.HealerFrame, control.DamagerFrame }) do
				ApplyThemedFontColor(roleFrame, roleFrame and roleFrame.Count, palette.text, themed)
			end
			self:RefreshModernReadyCheckIconColor(control.ReadyCheckButton)
		end
	end
	local quickJoinContent = quickJoin and quickJoin.ContentInset
	ApplyThemedFontColor(
		quickJoinContent,
		quickJoinContent and quickJoinContent.NoGroupsText,
		palette.disabledText,
		themed
	)
	local helpIcon = frame.HelpButton and frame.HelpButton.Icon
	if helpIcon then
		SetTextureDesaturated(helpIcon, themed)
		ApplyTextureColor(
			helpIcon,
			themed and OpaqueThemeColor(palette.accent) or MODERN_BLIZZARD_THEME_COLORS.control
		)
	end
end

function FriendsUI:ApplyTheme(theme)
	if not self.root then
		return
	end
	self.currentTheme = theme or self.currentTheme or "blizzard"
	local palette, themed = self:GetModernThemeColors(self.currentTheme)
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	local modernActive = self:IsModernActive()
	local battleNetDisplay = header and header.BattlenetFrame
	local SkinEngine = BFL:GetModule("SkinEngine")
	if modernActive and themed and not palette.externalShell and SkinEngine and SkinEngine.StyleBackdrop and frame then
		SkinEngine:StyleBackdrop(frame, palette.background, palette.border)
	end

	ApplyTextureColor(self.root.ContentBackground, palette.background)
	local contentInsetTint = self.root.ContentInsetTint
	if not contentInsetTint then
		contentInsetTint = self.root:CreateTexture(nil, "BACKGROUND", nil, 1)
		self.root.ContentInsetTint = contentInsetTint
	end
	if BetterFriendsFrame and BetterFriendsFrame.Inset then
		contentInsetTint:ClearAllPoints()
		contentInsetTint:SetPoint("TOPLEFT", BetterFriendsFrame.Inset, "TOPLEFT")
		contentInsetTint:SetPoint("BOTTOMRIGHT", BetterFriendsFrame.Inset, "BOTTOMRIGHT")
	end
	ApplySolidTextureColor(contentInsetTint, palette.inset)
	SafeShow(contentInsetTint, themed)
	if self.root.FilterBar and self.root.FilterBar.Background then
		ApplySolidTextureColor(self.root.FilterBar.Background, palette.surface)
		SafeShow(self.root.FilterBar.Background, themed)
	end
	if self.root.BattleNetBar and self.root.BattleNetBar.Background then
		ApplyModernAtlasColor(self.root.BattleNetBar.Background, palette.surface, themed)
		SafeShow(self.root.BattleNetBar.Background, not themed)
	end
	if battleNetDisplay and battleNetDisplay.Background then
		ApplyModernAtlasColor(battleNetDisplay.Background, palette.control, modernActive and themed)
		SafeShow(battleNetDisplay.Background, not (modernActive and themed and palette.transparentBattleNetBar))
	end
	if themed then
		ApplySolidTextureColor(self.root.TopFade, palette.surface)
		ApplySolidTextureColor(self.root.BottomFade, palette.surface)
	else
		ApplyAtlasTexture(self.root.TopFade, "friends-frame-toptexbg")
		ApplyAtlasTexture(self.root.BottomFade, "friends-frame-bottomtexbg")
		SetTextureDesaturated(self.root.TopFade, false)
		SetTextureDesaturated(self.root.BottomFade, false)
		ApplyTextureColor(self.root.TopFade, MODERN_BLIZZARD_THEME_COLORS.control)
		ApplyTextureColor(self.root.BottomFade, MODERN_BLIZZARD_THEME_COLORS.control)
	end
	ApplyTextureColor(self.root.TopDivider, themed and palette.border or MODERN_BLIZZARD_THEME_COLORS.border)
	ApplyTextureColor(self.root.BottomDivider, themed and palette.border or MODERN_BLIZZARD_THEME_COLORS.border)

	if modernActive then
		ApplyModernOwnedSurface(self.root.BattleNetBar, palette.surface, false)
		SafeShow(self.root.BattleNetBar.BFL_DarkBackdrop, false)
		ApplyModernOwnedSurface(battleNetDisplay, palette.control, themed and not palette.externalControls)
		ApplyModernControlTheme(header and header.StatusDropdown, palette, themed)
		ApplyModernControlTheme(header and header.SearchBox, palette, themed)
		if themed and not palette.externalControls and SkinEngine and SkinEngine.StyleBackdrop then
			SkinEngine:StyleBackdrop(battleNetDisplay, palette.control, palette.border)
		end
	end
	ApplyModernControlTheme(self.root.FilterBar and self.root.FilterBar.FilterDropdown, palette, themed)
	ApplyModernControlTheme(self.root.FilterBar and self.root.FilterBar.RecentFilterDropdown, palette, themed)
	ApplyModernControlTheme(self.root.FilterBar and self.root.FilterBar.SortButton, palette, themed)
	ApplyModernControlTheme(self.root.BottomActionBar and self.root.BottomActionBar.AddFriendButton, palette, themed)
	ApplyModernControlTheme(self.root.BattleNetBar and self.root.BattleNetBar.MenuButton, palette, themed)
	ApplyModernControlTheme(
		self.root.RequestsFrame and self.root.RequestsFrame.RealIDWarning and self.root.RequestsFrame.RealIDWarning.ContinueButton,
		palette,
		themed
	)
	if modernActive then
		local StreamerMode = BFL.StreamerMode or BFL:GetModule("StreamerMode")
		local streamerActive = StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive()
		if not streamerActive then
			self:RefreshBattleTag()
		end
		ApplyThemedFontColor(
			battleNetDisplay,
			battleNetDisplay and battleNetDisplay.Tag,
			palette.battleTagText or MODERN_WHITE,
			themed
		)
		ApplyThemedFontColor(
			battleNetDisplay,
			battleNetDisplay and battleNetDisplay.UnavailableLabel,
			palette.disabledText,
			themed
		)
		ApplyThemedFontColor(
			header and header.SearchBox,
			header and header.SearchBox and header.SearchBox.Instructions,
			palette.disabledText,
			themed
		)
	end
	ApplyTextureColor(
		header and header.SearchBox and header.SearchBox.searchIcon,
		modernActive and themed and OpaqueThemeColor(palette.accent) or MODERN_BLIZZARD_THEME_COLORS.control
	)
	local menuIcon = self.root.BattleNetBar and self.root.BattleNetBar.MenuButton and self.root.BattleNetBar.MenuButton.Icon
	SetTextureDesaturated(menuIcon, themed)
	ApplyTextureColor(menuIcon, themed and OpaqueThemeColor(palette.accent) or MODERN_BLIZZARD_THEME_COLORS.control)
	local copyButton = self.root.BattleNetBar and self.root.BattleNetBar.CopyBattleTagButton
	local copyColor = themed and MODERN_WHITE or MODERN_BLIZZARD_THEME_COLORS.control
	for _, texture in ipairs({
		copyButton and copyButton.Icon,
		copyButton and (copyButton.HighlightTexture or (copyButton.GetHighlightTexture and copyButton:GetHighlightTexture())),
	}) do
		SetTextureDesaturated(texture, themed)
		ApplyTextureColor(texture, copyColor)
	end
	local StreamerMode = BFL.StreamerMode or BFL:GetModule("StreamerMode")
	if modernActive and StreamerMode and StreamerMode.ApplyToggleButtonVisualState then
		StreamerMode:ApplyToggleButtonVisualState()
	end
	self:ApplyModernVisibleControlTheme(palette, modernActive and themed)

	local warning = self.root.RequestsFrame and self.root.RequestsFrame.RealIDWarning
	self:ApplyRealIDWarningTheme(palette, self.currentTheme)
	ApplyThemedFontColor(self.root, self.root.FriendsDisabledText, palette.disabledText, themed)
	ApplyThemedFontColor(self.root.RequestsFrame, self.root.RequestsFrame and self.root.RequestsFrame.EmptyLabel, palette.disabledText, themed)
	ApplyThemedFontColor(warning, warning and warning.Text, palette.text, themed)
	local skinSideTabs = themed and not palette.preserveNativeSideTabs
	for _, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = definition.tab
		if tab then
			local selected = self.selectedSection == definition.id
			ApplyModernSideTabTheme(tab, skinSideTabs and palette or MODERN_BLIZZARD_THEME_COLORS, skinSideTabs, selected)
			ApplySectionIcon(tab.Icon or tab.icon, definition, selected)
			ApplyThemedFontColor(tab, tab.Count, palette.accent, skinSideTabs)
		end
	end
	self:LayoutNavigationTabs(nil, skinSideTabs)
	self:RefreshModernThemeRows()
	if self:IsModernActive() and BetterFriendsFrame then
		self:ApplyModernPortrait()
		self:ApplyModernContentLayout(self.selectedSection or "friends", true)
	end
	if modernActive and self.currentTheme == "elvui" then
		-- ThemeManager applies BFL's geometry after ElvUI's addon callback. Let
		-- ElvUI own the final visual pass without recursively re-running themes.
		local ElvUISkin = BFL:GetModule("ElvUISkin")
		if ElvUISkin and ElvUISkin.RefreshModernSkin then
			ElvUISkin:RefreshModernSkin()
		end
	end
	self:RefreshFriendsFriendsFrame()
end

function FriendsUI:StyleFriendCard(button)
	if not self:IsModernActive() or not button then
		return
	end
	local friend = button.friendData
	local db = GetDB()
	local palette, themed = self:GetModernThemeColors()
	local faction = friend and (friend.factionName or (friend.gameAccountInfo and friend.gameAccountInfo.factionName))
	local factionTint
	if friend and friend.connected and db and db.showFactionBg then
		if faction == "Alliance" or faction == "Allianz" then
			factionTint = { 0.03, 0.30, 0.85 }
		elseif faction == "Horde" then
			factionTint = { 0.85, 0.03, 0.03 }
		end
	end
	local atlas = "friends-card-default"
	if friend and friend.connected == false then
		atlas = "friends-card-disabled"
	elseif friend and friend.type == "bnet" then
		local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
		atlas = titleLevel and friend.friendLevel == titleLevel and "friends-card-default" or "friends-card-battleNet"
	end
	if button.CardBackground then
		ApplyAtlasTexture(button.CardBackground, atlas)
		local tint = themed and GetAtlasTint(palette.surface) or { 1, 1, 1, 1 }
		SetTextureDesaturated(button.CardBackground, themed)
		ApplyTextureColor(button.CardBackground, tint)
		-- Keep the faction color behind Blizzard's card surface. The surface
		-- remains dominant and therefore preserves contrast for ARTWORK text.
		button.CardBackground:SetAlpha(factionTint and (themed and 0.68 or 0.76) or 1)
	end
	if button.FactionTintMask then
		ApplyAtlasTexture(button.FactionTintMask, atlas)
	end
	if button.ThemeTintMask then
		ApplyAtlasTexture(button.ThemeTintMask, atlas)
	end
	if button.ThemeTint then
		if themed then
			ApplySolidTextureColor(button.ThemeTint, palette.surface)
			button.ThemeTint:Show()
		else
			button.ThemeTint:Hide()
		end
	end
	if button.FactionTint then
		if factionTint then
			if button.FactionTint.SetBlendMode then
				button.FactionTint:SetBlendMode("BLEND")
			end
			button.FactionTint:SetColorTexture(factionTint[1], factionTint[2], factionTint[3], 1)
			button.FactionTint:SetAlpha(1)
			button.FactionTint:Show()
		else
			button.FactionTint:Hide()
		end
	end
	if button.background then
		-- Modern faction color is clipped into the native card silhouette above.
		-- Never cover it with the legacy flat-color compatibility region.
		button.background:SetColorTexture(0, 0, 0, 0)
	end
	local highlight = button.highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
	if highlight then
		highlight:SetDesaturated(themed)
		ApplyTextureColor(highlight, themed and palette.selected or MODERN_BLIZZARD_THEME_COLORS.selected)
	end
	local actionButton = button.travelPassButton
	if actionButton then
		local skinInviteButton = themed and not palette.preserveNativeInviteButtons
		actionButton.BFL_DarkForceFlatButton = skinInviteButton and true or nil
		actionButton.friendData = friend
		actionButton.friendIndex = friend and friend.index or nil
		actionButton:SetSize(34, 34)
		actionButton:ClearAllPoints()
		actionButton:SetPoint("RIGHT", button, "RIGHT", -4, 0)
		ApplyAtlasTexture(actionButton.NormalTexture, "common-button-tertiary-square-normal")
		ApplyAtlasTexture(actionButton.PushedTexture, "common-button-tertiary-square-pressed")
		ApplyAtlasTexture(actionButton.DisabledTexture, "common-button-tertiary-square-normal")
		ApplyAtlasTexture(actionButton.HighlightTexture, "common-button-tertiary-square-normal")
		SetTextureDesaturated(actionButton.NormalTexture, skinInviteButton)
		SetTextureDesaturated(actionButton.PushedTexture, skinInviteButton)
		SetTextureDesaturated(actionButton.DisabledTexture, skinInviteButton)
		SetTextureDesaturated(actionButton.HighlightTexture, skinInviteButton)
		local controlTint = skinInviteButton and GetAtlasTint(palette.control) or MODERN_BLIZZARD_THEME_COLORS.control
		ApplyTextureColor(actionButton.NormalTexture, controlTint)
		ApplyTextureColor(actionButton.PushedTexture, skinInviteButton and GetAtlasTint(palette.selected) or controlTint)
		ApplyTextureColor(actionButton.DisabledTexture, controlTint)
		ApplyTextureColor(actionButton.HighlightTexture, skinInviteButton and palette.hover or MODERN_BLIZZARD_THEME_COLORS.control)

		local isInGroup = false
		local playerGUID = friend and (friend.guid or (friend.gameAccountInfo and friend.gameAccountInfo.playerGuid))
		if playerGUID and C_SocialQueue and C_SocialQueue.IsSystemSupported and C_SocialQueue.GetGroupForPlayer then
			local supported = C_SocialQueue.IsSystemSupported()
			if supported then
				local ok, group = pcall(C_SocialQueue.GetGroupForPlayer, playerGUID)
				isInGroup = ok and group ~= nil
			end
		end
		local enabled = friend and friend.connected == true and (friend.type ~= "bnet" or friend.canInvite == true)
		actionButton:SetEnabled(enabled == true)
		if actionButton.ActionIcon then
			local atlas = isInGroup and "friends-icon-friendsInGroup" or "friends-icon-friendsAvailable"
			if not enabled then
				atlas = atlas .. "-dis"
			end
			ApplyAtlasTexture(actionButton.ActionIcon, atlas)
			SetTextureDesaturated(actionButton.ActionIcon, skinInviteButton)
			ApplyTextureColor(
				actionButton.ActionIcon,
				skinInviteButton and (enabled and OpaqueThemeColor(palette.accent) or palette.disabledText)
					or MODERN_BLIZZARD_THEME_COLORS.control
			)
		end
		actionButton:Show()
		if button.gameIcon then
			button.gameIcon:SetSize(20, 20)
			button.gameIcon:ClearAllPoints()
			button.gameIcon:SetPoint("RIGHT", actionButton, "LEFT", -6, 1)
		end
	end
	-- FriendsList owns row height and the top-down text stack. Modern styling
	-- must not replace that calculated extent with the old 70/46px presets.
	if palette.skinFriendCardSurface then
		local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
		if EllesmereUISkin and EllesmereUISkin.SkinModernFriendCard then
			EllesmereUISkin:SkinModernFriendCard(button)
		end
	end
end

function FriendsUI:StyleQuickJoinCard(button)
	if not button then
		return
	end

	local modern = self:IsModernActive()
	local background = button.Background
	local highlight = button.Highlight
	local selected = button.Selected
	button.BFL_ModernQuickJoinCard = modern and true or nil

	if not modern then
		-- The Retail Legacy layout intentionally keeps BFL's compact flat card.
		-- Restore it explicitly after a live switch away from Modern.
		if background then
			background:ClearAllPoints()
			background:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
			background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			background:SetColorTexture(0.1, 0.1, 0.1, 0.5)
			SetTextureDesaturated(background, false)
			ApplyTextureColor(background, MODERN_BLIZZARD_THEME_COLORS.control)
			background:Show()
		end
		for _, texture in ipairs({ highlight, selected }) do
			if texture then
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
				texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
				texture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
				texture:SetTexCoord(0, 1, 0, 1)
				SetTextureDesaturated(texture, false)
			end
		end
		ApplyTextureColor(highlight, MODERN_BLIZZARD_THEME_COLORS.control)
		ApplyTextureColor(selected, MODERN_BLIZZARD_THEME_COLORS.accent)
		if highlight then
			highlight:SetAlpha(0.5)
		end
		if selected then
			selected:SetAlpha(0.8)
		end
		return
	end

	-- Retail 12.1 SocialUI uses a dedicated Quick Join card rather than a flat
	-- row. Reuse that same silhouette so Quick Join belongs to the Friends and
	-- Recent Allies visual family while keeping BFL's richer card contents.
	local palette, themed = self:GetModernThemeColors()
	if background then
		background:ClearAllPoints()
		background:SetAllPoints(button)
		ApplyAtlasTexture(background, "friends-card-quickJoin")
		ApplyModernAtlasColor(background, palette.surface, themed)
		background:SetAlpha(1)
		background:Show()
	end
	for _, texture in ipairs({ highlight, selected }) do
		if texture then
			texture:ClearAllPoints()
			texture:SetAllPoints(button)
			ApplyAtlasTexture(texture, "friends-card-quickJoin-selected")
			SetTextureDesaturated(texture, themed)
		end
	end
	ApplyTextureColor(
		highlight,
		themed and palette.hover or MODERN_BLIZZARD_THEME_COLORS.selected
	)
	ApplyTextureColor(
		selected,
		themed and palette.selected or MODERN_BLIZZARD_THEME_COLORS.selected
	)
	if highlight then
		highlight:SetAlpha(themed and 1 or 0.5)
	end
	if selected then
		selected:SetAlpha(1)
	end
	-- A row may already own a Legacy dark backdrop during a live style switch.
	-- The native card is the Modern surface, so never cover it with that flat row.
	SafeShow(button.BFL_DarkBackdrop, false)
end

function FriendsUI:StyleGroupHeader(button)
	if not self:IsModernActive() or not button then
		return
	end
	button:SetHeight(24)
	local palette, themed = self:GetModernThemeColors()
	local skinGroupHeader = themed and not palette.preserveNativeGroupHeaders
	local collapsed = button.elementData and button.elementData.collapsed == true
	SafeShow(button.RightArrow, false)
	SafeShow(button.DownArrow, false)
	if button.CollapseButton then
		SafeShow(button.CollapseButton, button._bflCollapseButtonShown ~= false)
		if
			button.CollapseButton.UpdateCollapsedState
			and button._bflCollapseButtonState ~= collapsed
		then
			button.CollapseButton:UpdateCollapsedState(collapsed)
		end
	end
	-- Text geometry is resolved once by FriendsList. Re-anchoring CountText to
	-- both HeaderText and CollapseButton here would recreate the constrained
	-- FontFamily layout that can hang Retail 12.1 with many group headers.
	-- Preserve Blizzard's complete collapse/expand atlas, but multiply it into
	-- the restrained dark tone used before the flat replacement. Dark/Custom
	-- suppresses only the gold click highlight; the normal texture stays visible.
	local nativeTone = skinGroupHeader and GetAtlasTint(palette.surface) or MODERN_BLIZZARD_THEME_COLORS.control
	local normal = button:GetNormalTexture()
	if normal then
		normal:SetDesaturated(skinGroupHeader)
		ApplyTextureColor(normal, nativeTone)
		normal:SetAlpha(1)
	end
	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetDesaturated(false)
		highlight:SetVertexColor(1, 1, 1, 1)
		highlight:SetAlpha(skinGroupHeader and 0 or 0.4)
	end
	local pushed = button:GetPushedTexture()
	if pushed then
		pushed:SetDesaturated(skinGroupHeader)
		ApplyTextureColor(pushed, nativeTone)
		pushed:SetAlpha(1)
	end
	if button.ThemeTint then
		button.ThemeTint:Hide()
	end
end

function FriendsUI:StyleRequestCard(button)
	if not button or not button.Background then
		return
	end
	local palette, themed = self:GetModernThemeColors()
	ApplyThemedFontColor(button, button.RequestTimestamp, palette.text, themed)
	ApplyThemedFontColor(button, button.Name, palette.text, themed)
	ApplyThemedFontColor(button, button.FriendType, palette.disabledText, themed)
	SetTextureDesaturated(button.Background, themed)
	ApplyTextureColor(button.Background, themed and GetAtlasTint(palette.surface) or MODERN_BLIZZARD_THEME_COLORS.control)
	if button.ThemeTintMask then
		ApplyAtlasTexture(button.ThemeTintMask, "friends-card-battleNet")
	end
	if button.ThemeTint then
		if themed then
			ApplySolidTextureColor(button.ThemeTint, palette.surface)
			button.ThemeTint:Show()
		else
			button.ThemeTint:Hide()
		end
	end
	local accept = button.AcceptButton
	if accept then
		SetTextureDesaturated(accept.NormalTexture or (accept.GetNormalTexture and accept:GetNormalTexture()), themed)
		SetTextureDesaturated(accept.PushedTexture or (accept.GetPushedTexture and accept:GetPushedTexture()), themed)
		SetTextureDesaturated(accept.HighlightTexture or (accept.GetHighlightTexture and accept:GetHighlightTexture()), themed)
		local controlTint = themed and GetAtlasTint(palette.control) or MODERN_BLIZZARD_THEME_COLORS.control
		ApplyTextureColor(accept.NormalTexture or (accept.GetNormalTexture and accept:GetNormalTexture()), controlTint)
		ApplyTextureColor(
			accept.PushedTexture or (accept.GetPushedTexture and accept:GetPushedTexture()),
			themed and GetAtlasTint(palette.selected) or controlTint
		)
		ApplyTextureColor(
			accept.HighlightTexture or (accept.GetHighlightTexture and accept:GetHighlightTexture()),
			themed and palette.hover or MODERN_BLIZZARD_THEME_COLORS.control
		)
	end
	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	if highlight then
		highlight:SetDesaturated(themed)
		ApplyTextureColor(highlight, themed and palette.selected or MODERN_BLIZZARD_THEME_COLORS.selected)
	end
end

function FriendsUI:StyleRequestHeader(button)
	if not button then
		return
	end
	local palette, themed = self:GetModernThemeColors()
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	SetTextureDesaturated(normal, themed)
	ApplyTextureColor(normal, themed and GetAtlasTint(palette.surface) or MODERN_BLIZZARD_THEME_COLORS.control)
	ApplyThemedFontColor(button, button.ButtonText, palette.text, themed)
end

function FriendsUI:RegisterTests()
	if self.testsRegistered then
		return
	end
	local TestSuite = BFL:GetModule("TestSuite")
	if not TestSuite or not TestSuite.RegisterTest then
		return
	end
	self.testsRegistered = true
	TestSuite:RegisterTest("ui", "FriendsUI_Defaults", {
		action = function(V)
			V:AssertEqual(self:GetDefaultRequestedStyle(true), STYLE_MODERN, "Retail defaults to Modern")
			V:AssertEqual(self:GetDefaultRequestedStyle(false), STYLE_LEGACY, "Classic defaults to Legacy")
			V:AssertEqual(
				self:ResolveRequestedStyle(nil, true, 0, 1),
				STYLE_LEGACY,
				"Retail stays on Legacy until the interface onboarding is confirmed"
			)
			V:AssertEqual(
				self:ResolveRequestedStyle(nil, true, 1, 1),
				STYLE_MODERN,
				"Completed Retail profiles retain the platform default fallback"
			)
			V:AssertEqual(
				self:ResolveRequestedStyle(STYLE_MODERN, true, 0, 1),
				STYLE_MODERN,
				"A stored Modern preference is preserved while onboarding is pending"
			)
			V:AssertEqual(
				self:ResolveRequestedStyle(STYLE_LEGACY, true, 1, 1),
				STYLE_LEGACY,
				"A stored Legacy preference is preserved after onboarding"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernThemePalette", {
		action = function(V)
			local palette = self:GetModernThemeColors(BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard")
			for _, key in ipairs({
				"background",
				"surface",
				"inset",
				"control",
				"border",
				"accent",
				"text",
				"disabledText",
				"hover",
				"selected",
				"scrollThumb",
				"icon",
			}) do
				local color = palette and palette[key]
				V:Assert(type(color) == "table" and #color == 4, "Modern theme resolves the " .. key .. " color token")
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernThemeSurfaceState", {
		condition = function()
			return self:IsModernActive() and self.root and self.root.ContentBackground
		end,
		action = function(V)
			self:ApplyTheme(BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard")
			local flatTheme = BFL.UsesFlatTheme and BFL:UsesFlatTheme()
			V:Assert(self.root.ContentInsetTint ~= nil, "Modern theme owns a dedicated inset surface")
			V:AssertEqual(
				self.root.ContentInsetTint:IsShown(),
				flatTheme == true,
				"Modern inset tint is shown for flat themes"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernThemeChrome", {
		condition = function()
			return self:IsModernActive() and self.root and self.root.BottomActionBar
		end,
		action = function(V)
			local themed = BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme()
			if not themed then
				return
			end
			local addFriendButton = self.root.BottomActionBar.AddFriendButton
			local frame = BetterFriendsFrame
			V:Assert(
				frame and frame.BFL_DarkBackdrop and frame.BFL_DarkBackdrop:IsShown(),
				"Modern Dark/Custom replaces the complete main-window shell"
			)
			local frameEdge = frame and frame.NineSlice and (frame.NineSlice.TopEdge or frame.NineSlice.TopLeftCorner)
			V:Assert(
				not frameEdge or frameEdge:GetAlpha() == 0,
				"Modern Dark/Custom suppresses native ButtonFrame NineSlice artwork"
			)
			V:Assert(
				not self.root.BattleNetBar.BFL_DarkBackdrop or not self.root.BattleNetBar.BFL_DarkBackdrop:IsShown(),
				"Modern themed Battle.net bar leaves the overall header transparent"
			)
			V:Assert(
				not self.root.BattleNetBar.BFL_ModernThemeSurface
					or not self.root.BattleNetBar.BFL_ModernThemeSurface:IsShown(),
				"Modern themed Battle.net bar suppresses its owned surface"
			)
			V:Assert(
				not self.root.BattleNetBar.Background or not self.root.BattleNetBar.Background:IsShown(),
				"Modern themed Battle.net bar suppresses the native info background"
			)
			local battleNetDisplay = frame and frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame
			V:Assert(
				battleNetDisplay
					and battleNetDisplay.BFL_ModernThemeSurface
					and battleNetDisplay.BFL_ModernThemeSurface:IsShown(),
				"Modern BattleTag display owns an opaque themed surface"
			)
			V:Assert(
				not battleNetDisplay.Background or not battleNetDisplay.Background:IsShown(),
				"Modern themed BattleTag display suppresses the native atlas"
			)
			V:AssertEqual(
				self.root.BattleNetBar.MenuButton:GetHeight(),
				battleNetDisplay:GetHeight(),
				"Modern themed menu and BattleTag display share one horizontal control line"
			)
			V:Assert(
				addFriendButton.BFL_DarkBackdrop and addFriendButton.BFL_DarkBackdrop:IsShown(),
				"Modern Add Friend uses the themed control backdrop"
			)
			V:Assert(
				not addFriendButton.Center or addFriendButton.Center:GetAlpha() == 0,
				"Modern ThreeSlice center artwork does not bleed through the themed button"
			)
			local friendsTab = SECTION_BY_ID.friends and SECTION_BY_ID.friends.tab
			V:Assert(
				friendsTab and friendsTab.BFL_DarkBackdrop and friendsTab.BFL_DarkBackdrop:IsShown(),
				"Modern side tabs use the flat themed surface"
			)
			V:Assert(
				friendsTab and friendsTab.Background and friendsTab.Background:GetAlpha() == 0,
				"Modern side tabs suppress native common-sidetab artwork"
			)
			V:Assert(
				friendsTab and friendsTab.Icon and friendsTab.Icon:GetAlpha() > 0,
				"Modern side-tab icons remain visible after chrome replacement"
			)
			V:AssertEqual(
				friendsTab and friendsTab:GetWidth(),
				MODERN_THEMED_SIDE_TAB_WIDTH,
				"Modern themed side tabs use the compact width"
			)
			local firstTab
			for _, sectionID in ipairs(self:GetFriendTabOrder()) do
				local candidate = SECTION_BY_ID[sectionID] and SECTION_BY_ID[sectionID].tab
				if candidate and candidate:IsShown() then
					firstTab = candidate
					break
				end
			end
			local tabPoint, tabRelativeTo, tabRelativePoint, tabX = firstTab and firstTab:GetPoint(1)
			V:Assert(
				firstTab
					and tabPoint == "TOPLEFT"
					and tabRelativeTo == frame
					and tabRelativePoint == "TOPRIGHT"
					and tabX == MODERN_THEMED_SIDE_TAB_OFFSET_X,
				"Modern themed side tabs close the gap to the main frame"
			)
			local iconPoint, iconRelativeTo, iconRelativePoint, iconX = friendsTab.Icon:GetPoint(1)
			V:Assert(
				iconPoint == "CENTER"
					and iconRelativeTo == friendsTab
					and iconRelativePoint == "CENTER"
					and iconX == 0,
				"Modern side-tab icons are centered in the compact surface"
			)
			local header = frame and frame.FriendsTabHeader
			V:AssertEqual(
				header and header.SearchBox and header.SearchBox:GetHeight(),
				self.root.FilterBar.FilterDropdown:GetHeight(),
				"Modern Friends search and filter controls share one height"
			)
			local searchIconPoint, searchIconRelativeTo, searchIconRelativePoint, searchIconX =
				header.SearchBox.searchIcon:GetPoint(1)
			local instructionPoint, instructionRelativeTo, instructionRelativePoint, instructionX =
				header.SearchBox.Instructions:GetPoint(1)
			V:Assert(
				searchIconPoint == "LEFT" and searchIconX == 3 and instructionPoint == "LEFT" and instructionX == 19,
				"Modern themed search glyph and placeholder use the corrected right-shifted inset"
			)
			local filterText = GetControlFontString(self.root.FilterBar.FilterDropdown)
			local filterLeftPoint, filterLeftRelativeTo, filterLeftRelativePoint, filterLeftX =
				filterText and filterText:GetPoint(1)
			local filterRightPoint, filterRightRelativeTo, filterRightRelativePoint, filterRightX =
				filterText and filterText:GetPoint(2)
			V:Assert(
				filterLeftPoint == "LEFT"
					and filterLeftX == 4
					and filterRightPoint == "RIGHT"
					and filterRightX == -24,
				"Modern themed dropdown content is centered inside the arrow-free area"
			)
			local copyButton = self.root.BattleNetBar.CopyBattleTagButton
			local palette = self:GetModernThemeColors()
			local copyR, copyG, copyB = copyButton.Icon:GetVertexColor()
			V:Assert(
				copyButton.Icon:IsDesaturated()
					and math.abs(copyR - 1) < 0.001
					and math.abs(copyG - 1) < 0.001
					and math.abs(copyB - 1) < 0.001,
				"Modern themed Copy BattleTag icon is white"
			)
			local tagR, tagG, tagB = battleNetDisplay.Tag:GetTextColor()
			V:Assert(
				math.abs(tagR - 1) < 0.001
					and math.abs(tagG - 1) < 0.001
					and math.abs(tagB - 1) < 0.001,
				"Modern themed BattleTag text is white"
			)
			local searchR, searchG, searchB = header.SearchBox.searchIcon:GetVertexColor()
			V:Assert(
				math.abs(searchR - palette.accent[1]) < 0.001
					and math.abs(searchG - palette.accent[2]) < 0.001
					and math.abs(searchB - palette.accent[3]) < 0.001,
				"Modern BFL search icon uses the accent color"
			)
			local streamerIcon = frame.StreamerModeButton and frame.StreamerModeButton.Icon
			local streamerR, streamerG, streamerB = streamerIcon and streamerIcon:GetVertexColor()
			V:Assert(
				streamerIcon
					and streamerIcon:IsDesaturated()
					and math.abs(streamerR - palette.accent[1]) < 0.001
					and math.abs(streamerG - palette.accent[2]) < 0.001
					and math.abs(streamerB - palette.accent[3]) < 0.001,
				"Modern themed Streamer Mode icon uses the accent color"
			)
			local scrollBar = frame.MinimalScrollBar
			local trackR, trackG, trackB = scrollBar.Track.Begin:GetVertexColor()
			V:Assert(
				scrollBar
					and not scrollBar.BFL_DarkScrollBarSkinned
					and scrollBar.BFL_ModernDarkToneApplied
					and scrollBar.Track
					and scrollBar.Track.Begin
					and scrollBar.Track.Begin:IsDesaturated()
					and trackR < 0.5
					and trackG < 0.5
					and trackB < 0.5,
				"Modern themed scrollbars retain native chrome with a restrained dark tone"
			)
			local friendRow
			local groupHeader
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList and FriendsList.scrollBox and FriendsList.scrollBox.ForEachFrame then
				FriendsList.scrollBox:ForEachFrame(function(row)
					if row.travelPassButton then
						friendRow = friendRow or row
					elseif row.HeaderText then
						groupHeader = groupHeader or row
					end
				end)
			end
			if friendRow then
				V:Assert(
					friendRow.travelPassButton.BFL_DarkForceFlatButton
						and friendRow.travelPassButton.BFL_DarkBorderlessIconButton
						and friendRow.travelPassButton.BFL_DarkBackdrop
						and friendRow.travelPassButton.BFL_DarkBackdrop:IsShown()
						and friendRow.travelPassButton:GetNormalTexture():GetAlpha() == 0,
					"Modern themed Invite action uses the borderless icon skin"
				)
			end
			local recent = frame and frame.RecentAlliesFrame
			if recent and recent.ScrollBox and recent.ScrollBox.ForEachFrame then
				recent.ScrollBox:ForEachFrame(function(row)
					if row.PartyButton then
						V:Assert(
							row.PartyButton.BFL_DarkForceFlatButton
								and row.PartyButton.BFL_DarkBorderlessIconButton
								and row.PartyButton:GetNormalTexture():GetAlpha() == 0,
							"Modern Recent Allies Invite action uses the borderless icon skin"
						)
					end
				end)
			end
			if groupHeader then
				local groupNormal = groupHeader:GetNormalTexture()
				local groupR, groupG, groupB = groupNormal:GetVertexColor()
				V:Assert(
					groupNormal:GetAlpha() == 1
						and groupNormal:IsDesaturated()
						and groupR < 1
						and groupG < 1
						and groupB < 1
						and groupHeader:GetHighlightTexture():GetAlpha() == 0,
					"Modern themed group headers retain a visible darkened native texture without gold click corners"
				)
			end
			local raf = frame and frame.RecruitAFriendFrame
			local reward = raf and raf.RewardClaiming
			if raf and raf:IsShown() and reward then
				V:Assert(
					reward.BFL_DarkBackdrop and reward.BFL_DarkBackdrop:IsShown(),
					"Visible RAF reward panel uses the themed surface"
				)
				V:Assert(
					not reward.Background or reward.Background:GetAlpha() == 0,
					"Visible RAF reward panel suppresses native background artwork"
				)
				local recruitHeader = raf.RecruitList and raf.RecruitList.Header
				if recruitHeader then
					V:Assert(
						recruitHeader.BFL_DarkBackdrop and recruitHeader.BFL_DarkBackdrop:IsShown(),
						"Visible RAF list header uses the themed surface"
					)
					V:Assert(
						not recruitHeader.Background or recruitHeader.Background:GetAlpha() == 0,
						"Visible RAF list header suppresses its native stone divider"
					)
				end
			end
			local quickJoin = frame and frame.QuickJoinFrame
			local quickJoinContent = quickJoin and quickJoin.ContentInset
			if quickJoin and quickJoin:IsShown() and quickJoinContent then
				local listSurface = quickJoinContent.ScrollBoxContainer or quickJoinContent.ScrollBox
				V:Assert(
					(not quickJoinContent.BFL_DarkBackdrop or not quickJoinContent.BFL_DarkBackdrop:IsShown())
						and (not listSurface or not listSurface.BFL_DarkBackdrop or not listSurface.BFL_DarkBackdrop:IsShown()),
					"Modern themed Quick Join does not draw a private content border"
				)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernBlizzardSideTabState", {
		condition = function()
			local _, themed = self:GetModernThemeColors()
			return self:IsModernActive() and self.sideTabs and not themed
		end,
		action = function(V)
			self:ApplyTheme("blizzard")
			local frame = BetterFriendsFrame
			local raf = frame and frame.RecruitAFriendFrame
			local who = frame and frame.WhoFrame
			local raid = frame and frame.RaidFrame
			local quickJoin = frame and frame.QuickJoinFrame
			local WhoFrame = BFL:GetModule("WhoFrame")
			local builder = WhoFrame and WhoFrame.builder
			local actionButtons = {
				["shared bottom action"] = self.root.BottomActionBar and self.root.BottomActionBar.AddFriendButton,
				["Battle.net menu"] = self.root.BattleNetBar and self.root.BattleNetBar.MenuButton,
				["Real ID warning"] = self.root.RequestsFrame
					and self.root.RequestsFrame.RealIDWarning
					and self.root.RequestsFrame.RealIDWarning.ContinueButton,
				["RAF recruitment"] = frame and frame.RecruitmentButton,
				["RAF reward"] = raf and raf.RewardClaiming and raf.RewardClaiming.ClaimOrViewRewardButton,
				["RAF splash"] = raf and raf.SplashFrame and raf.SplashFrame.OKButton,
				["Who refresh"] = who and who.WhoButton,
				["Who add friend"] = who and who.AddFriendButton,
				["Who group invite"] = who and who.GroupInviteButton,
				["Raid info"] = raid and raid.ControlPanel and raid.ControlPanel.RaidInfoButton,
				["Raid ready check"] = raid and raid.ControlPanel and raid.ControlPanel.ReadyCheckButton,
				["Raid tools"] = raid and raid.RaidToolsButton,
				["Raid conversion"] = raid and raid.ConvertToRaidButton,
				["Quick Join action"] = quickJoin and quickJoin.ContentInset and quickJoin.ContentInset.JoinQueueButton,
				["Who builder search"] = builder and builder.searchBtn,
				["Who builder reset"] = builder and builder.resetBtn,
			}
			for label, button in pairs(actionButtons) do
				if label == "RAF recruitment" and frame and button == frame.bflModernRecruitmentButton then
					V:AssertEqual(button.baseWidth, 160, "Modern RAF recruitment keeps Blizzard's 160 px base width")
					V:AssertEqual(button.maxWidth, 400, "Modern RAF recruitment keeps Blizzard's 400 px maximum width")
					V:AssertEqual(
						button:GetParent(),
						self.root.BottomActionBar,
						"Modern RAF recruitment belongs to the visible Modern action footer"
					)
					V:Assert(
						button:GetFrameLevel() > self.root.BottomActionBar:GetFrameLevel(),
						"Modern RAF recruitment renders above the Modern action footer"
					)
					V:AssertEqual(
						button.buttonArtKit,
						"128-RedButton",
						"Blizzard theme keeps the native red SocialUI action-button art kit"
					)
					if button.GetScaledDesiredWidth then
						local expectedWidth = button:GetScaledDesiredWidth()
						V:Assert(
							math.abs(button:GetWidth() - expectedWidth) < 0.5,
							"Modern RAF recruitment keeps its scaled native width after preview text and disabled updates"
						)
					end
				end
				if button.Left and button.Center and button.Right and button.UpdateButton then
					V:Assert(
						not button.BFL_DarkBackdrop or not button.BFL_DarkBackdrop:IsShown(),
						"Blizzard " .. label .. " hides the Dark/Custom backdrop"
					)
					for sliceName, slice in pairs({ Left = button.Left, Center = button.Center, Right = button.Right }) do
						local r, g, b = slice:GetVertexColor()
						V:Assert(
							slice:GetAlpha() == 1
								and not slice:IsDesaturated()
								and math.abs(r - 1) < 0.001
								and math.abs(g - 1) < 0.001
								and math.abs(b - 1) < 0.001,
							"Blizzard " .. label .. " restores its native " .. sliceName .. " slice"
						)
					end
				end
			end
			for _, definition in ipairs(SECTION_DEFINITIONS) do
				local tab = definition.tab
				if tab and tab:IsShown() then
					local selected = self.selectedSection == definition.id
					V:AssertEqual(
						tab.SelectedTexture and tab.SelectedTexture:IsShown(),
						selected,
						"Blizzard side tabs expose the selected texture only for the active section"
					)
					V:AssertEqual(
						tab.HighlightTexture and tab.HighlightTexture:IsShown(),
						BFL:IsRegionMouseOver(tab),
						"Blizzard side-tab hover follows the actual mouse state"
					)
					if tab.BFL_RequestGlowActive ~= true then
						V:Assert(
							not tab.TabGlowAnimation:IsPlaying() and tab.TabGlow:GetAlpha() == 0,
							"Blizzard side tabs clear stale native glow animation state"
						)
					end
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CapabilityFallback", {
		action = function(V)
			V:AssertEqual(
				self:IsModernStyleSelectable(),
				self:IsSocialUIAvailable(),
				"Modern selection follows SocialUI API presence, not Blizzard's runtime frame switch"
			)
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, true, true), STYLE_MODERN, "Modern requires the Retail SocialUI API")
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, true, false), STYLE_LEGACY, "Missing SocialUI API falls back")
			V:AssertEqual(
				self:ComputeEffectiveStyle(STYLE_MODERN, true, false, true),
				STYLE_MODERN,
				"Retail developer override can force Modern without the SocialUI API"
			)
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, false, true), STYLE_LEGACY, "Classic remains Legacy")
			V:AssertEqual(
				self:ComputeEffectiveStyle(STYLE_MODERN, false, false, true),
				STYLE_LEGACY,
				"Developer override never enables Modern on Classic"
			)
			V:AssertEqual(
				self:ComputeEffectiveStyle(STYLE_LEGACY, true, true, true),
				STYLE_LEGACY,
				"Requested Legacy wins over the developer override"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_NativeQueueFilterFallback", {
		action = function(V)
			local Registry = BFL:GetModule("FilterSortRegistry")
			if not Registry then
				V:Skip("Filter registry is unavailable")
				return
			end
			local originalState = Registry.nativeQueueFilterState
			Registry.nativeQueueFilterState = {
				id = "inqueue",
				valid = true,
				matches = { [2] = true },
			}
			local matchesBattleNet = Registry:EvaluateNativeQueueFilter("inqueue", { type = "bnet", index = 2 })
			local excludesBattleNet = not Registry:EvaluateNativeQueueFilter("inqueue", { type = "bnet", index = 1 })
			local excludesCharacterFriend = not Registry:EvaluateNativeQueueFilter("inqueue", { type = "wow", index = 2 })
			Registry.nativeQueueFilterState.valid = false
			local preservesListOnRestrictedResult = Registry:EvaluateNativeQueueFilter("inqueue", { type = "bnet", index = 1 })
			Registry.nativeQueueFilterState = originalState
			V:Assert(matchesBattleNet, "Native queue result includes matching Battle.net indices")
			V:Assert(excludesBattleNet, "Native queue result excludes unmatched Battle.net indices")
			V:Assert(excludesCharacterFriend, "Native queue result does not replace BFL's character-friend provider")
			V:Assert(preservesListOnRestrictedResult, "Restricted or nil native results fall back to an unfiltered list")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_RecentAlliesLegacyGroups", {
		action = function(V)
			local RecentAllies = BFL:GetModule("RecentAllies")
			if not RecentAllies or not RecentAllies.PartitionByPinAndLegacyState then
				V:Skip("Recent Allies is unavailable")
				return
			end
			local legacy, pinned, other = RecentAllies:PartitionByPinAndLegacyState({
				{ id = "other", stateData = {} },
				{ id = "pinned", stateData = { pinExpirationDate = 1 } },
				{ id = "legacy", stateData = { pinExpirationDate = 1, isConvertedLegacyFriend = true } },
				{ id = "nil-state" },
			})
			V:AssertEqual(legacy[1].id, "legacy", "Converted Legacy friends own the first Recent Allies group")
			V:AssertEqual(pinned[1].id, "pinned", "Pinned allies own the second Recent Allies group")
			V:AssertEqual(other[1].id, "other", "Unpinned allies remain in the final Recent Allies group")
			V:AssertEqual(#other, 2, "Missing stateData safely behaves like a normal ally")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SectionOrder", {
		action = function(V)
			V:AssertEqual(
				table.concat(self:NormalizeFriendTabOrder({}), ","),
				"friends,recent_allies,quick_join,friend_requests,recruit_a_friend,raid,guild,who",
				"Default section order must match SocialUI"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_FriendTabPreferences", {
		action = function(V)
			local db = GetDB()
			if not db then
				V:Skip("Database is unavailable")
				return
			end
			local originalOrder = db.modernFriendTabOrder
			local originalVisibility = db.modernFriendTabVisibility
			local originalPopulatedOnly = db.modernFriendTabPopulatedOnly
			local originalStyle = self.appliedStyle
			local ok, err = pcall(function()
				self.appliedStyle = STYLE_MODERN
				db.modernFriendTabOrder = { "who", "friends", "who", "unknown" }
				db.modernFriendTabVisibility = { raid = false }
				db.modernFriendTabPopulatedOnly = { friend_requests = true, quick_join = true }
				local all = {}
				for _, definition in ipairs(SECTION_DEFINITIONS) do
					all[definition.id] = true
				end
				local sections = self:BuildAvailableSectionIDs(all, {
					friend_requests = 0,
					quick_join = 2,
				})
				V:AssertEqual(
					table.concat(sections, ","),
					"who,friends,recent_allies,quick_join,recruit_a_friend,guild",
					"Order, general visibility, and populated-only visibility compose without layout gaps"
				)
				V:AssertEqual(
					table.concat(self:NormalizeFriendTabOrder({ "raid", "raid", "invalid" }), ","),
					"raid,friends,recent_allies,quick_join,friend_requests,recruit_a_friend,guild,who",
					"Saved tab order is deduplicated and completed with new tabs"
				)
			end)
			db.modernFriendTabOrder = originalOrder
			db.modernFriendTabVisibility = originalVisibility
			db.modernFriendTabPopulatedOnly = originalPopulatedOnly
			self.appliedStyle = originalStyle
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_LegacyTabMapping", {
		action = function(V)
			V:AssertEqual(self:GetSectionForLegacyTabs(1, 2), "recent_allies", "Top tab 2 maps to Recent Allies")
			V:AssertEqual(self:GetSectionForLegacyTabs(4, 1), "quick_join", "Bottom tab 4 maps to Quick Join")
			V:AssertEqual(self:GetSectionForLegacyTabs(2, 1), "who", "Bottom tab 2 maps to Who")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SeparateInviteProvider", {
		action = function(V)
			V:Assert(self:ShouldShowInvitesInline(STYLE_LEGACY), "Legacy keeps invites inline")
			V:Assert(not self:ShouldShowInvitesInline(STYLE_MODERN), "Modern uses the request provider")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SeparateFrameGeometry", {
		action = function(V)
			V:AssertEqual(self:GetLayoutKeyForStyle(STYLE_LEGACY), LEGACY_LAYOUT_KEY, "Legacy uses the Default geometry")
			V:AssertEqual(self:GetLayoutKeyForStyle(STYLE_MODERN), MODERN_LAYOUT_KEY, "Modern uses separate Retail geometry")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernScrollBarGrid", {
		action = function(V)
			V:AssertEqual(self:GetModernScrollBoxRightInset(), 18, "Modern section content leaves an 18 px scrollbar gutter")
			V:AssertEqual(self:GetModernScrollBarGap(), 7, "Modern scrollbars sit 7 px beyond their content viewport")
			V:AssertEqual(self:GetModernScrollBarLeftInset(), 11, "Every Modern scrollbar shares the Friends X position")
			if self:IsModernActive() and BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame then
				self:ApplyModernScrollBarGeometry()
				local friends = BetterFriendsFrame.ScrollFrame
				local recent = BetterFriendsFrame.RecentAlliesFrame.ScrollBox
				local anchoredScrollBars = {
					{ BetterFriendsFrame.MinimalScrollBar, friends, "Friends" },
					{ BetterFriendsFrame.RecentAlliesFrame.ScrollBar, recent, "Recent Allies" },
				}
				local recruitList = BetterFriendsFrame.RecruitAFriendFrame
					and BetterFriendsFrame.RecruitAFriendFrame.RecruitList
				if recruitList then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						recruitList.ScrollBar,
						recruitList.ScrollBox,
						"Recruit A Friend",
					}
				end
				local quickJoinInset = BetterFriendsFrame.QuickJoinFrame
					and BetterFriendsFrame.QuickJoinFrame.ContentInset
				if quickJoinInset then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						quickJoinInset.ScrollBar,
						quickJoinInset.ScrollBoxContainer,
						"Quick Join",
					}
				end
				if BetterFriendsFrame.WhoFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						BetterFriendsFrame.WhoFrame.ScrollBar,
						BetterFriendsFrame.WhoFrame.ScrollBox,
						"Who",
					}
				end
				if BetterFriendsFrame.GuildFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						BetterFriendsFrame.GuildFrame.ScrollBar,
						BetterFriendsFrame.GuildFrame.ScrollBox,
						"Guild",
					}
				end
				if self.root and self.root.RequestsFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						self.root.RequestsFrame.ScrollBar,
						self.root.RequestsFrame.ScrollBox,
						"Friend Requests",
					}
				end
				for _, entry in ipairs(anchoredScrollBars) do
					local scrollBar, scrollBox, label = entry[1], entry[2], entry[3]
					if scrollBar and scrollBox then
						V:AssertEqual(
							scrollBar:GetWidth(),
							BetterFriendsFrame.MinimalScrollBar:GetWidth(),
							label .. " scrollbar uses the Friends rail width"
						)
						local topLeftAnchor
						for pointIndex = 1, scrollBar:GetNumPoints() do
							local point, relativeTo, relativePoint, xOffset = scrollBar:GetPoint(pointIndex)
							if point == "TOPLEFT" then
								topLeftAnchor = { relativeTo, relativePoint, xOffset }
								break
							end
						end
						V:Assert(topLeftAnchor ~= nil, label .. " scrollbar has a top-left anchor")
						if topLeftAnchor then
							V:Assert(
								topLeftAnchor[1] == scrollBox,
								label .. " scrollbar anchors to its content viewport"
							)
							V:AssertEqual(
								topLeftAnchor[2],
								"TOPRIGHT",
								label .. " scrollbar follows the viewport's right edge"
							)
							V:AssertEqual(
								topLeftAnchor[3],
								7,
								label .. " scrollbar is visibly shifted 7 px beyond the viewport"
							)
						end
					end
				end
				V:Assert(
					friends and recent and math.abs(friends:GetHeight() - recent:GetHeight()) < 0.5,
					"Friends and Recent Allies scroll viewports use the same height"
				)
				if quickJoinInset and self.root and self.root.RequestsFrame then
					local requests = self.root.RequestsFrame
					self:ApplyModernQuickJoinGeometry("quick_join")
					self:LayoutRequestsFrame()
					V:Assert(
						math.abs(quickJoinInset.ScrollBoxContainer:GetHeight() - requests.ScrollBox:GetHeight()) < 0.5,
						"Quick Join and Friend Requests use the same full-height scroll viewport"
					)
					self:ApplyModernQuickJoinGeometry(self.selectedSection)
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernRAFFooterReservation", {
		action = function(V)
			V:Assert(
				self:ShouldReserveModernActionFooter("recruit_a_friend"),
				"Modern Recruit A Friend reserves the action footer for its Recruitment button"
			)
			V:Assert(
				not self:ShouldReserveModernActionFooter("raid"),
				"Modern sections without bottom actions keep the full content height"
			)
			local frame = BetterFriendsFrame
			local recruitmentButton = frame and frame.bflModernRecruitmentButton
			if self.root and recruitmentButton then
				V:AssertEqual(
					recruitmentButton:GetParent(),
					self.root.BottomActionBar,
					"Every Modern theme keeps RAF recruitment on the shared footer layer"
				)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernRequestLevels", {
		action = function(V)
			local levels = Enum and Enum.BattleNetFriendLevel
			if not levels then
				V:Skip("BattleNet friend levels are unavailable")
				return
			end
			V:AssertEqual(self:GetFriendLevelLabel(levels.BattleTag), GetL().FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag", "BattleTag request label")
			V:AssertEqual(self:GetFriendLevelLabel(levels.RealID), GetL().FRIENDS_UI_REQUEST_REAL_ID or "Real ID", "Real ID request label")
			V:AssertEqual(self:GetFriendLevelLabel(levels.Title), GetL().FRIENDS_UI_REQUEST_TITLE or "World of Warcraft", "Title request label")
			V:Assert(self:IsTitleInvite(levels.Title), "Title requests use the WoW card surface")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernAuxiliarySpacing", {
		action = function(V)
			if self:IsModernActive() then
				V:AssertEqual(self:GetAuxiliaryWindowOffset(), 68, "Modern auxiliary windows clear the side-tab rail")
			else
				V:AssertEqual(self:GetAuxiliaryWindowOffset(), 5, "Legacy auxiliary windows retain their original gap")
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernSimplePortraitReopen", {
		condition = function()
			return self:IsModernActive()
				and self.root
				and self.root.PortraitOverlay
				and BetterFriendsFrame
				and BetterFriendsFrame.NineSlice
				and BetterFriendsFrame.NineSlice.TopLeftCorner
		end,
		action = function(V)
			local db = GetDB()
			if not db then
				V:Skip("Database is unavailable")
				return
			end
			local frame = BetterFriendsFrame
			local topLeftCorner = frame.NineSlice.TopLeftCorner
			local originalSimpleMode = db.simpleMode
			local ok, err = pcall(function()
				db.simpleMode = true
				for pass = 1, 2 do
					-- Simulate PortraitFrame restoring its artwork while the panel opens.
					if frame.SetPortraitShown then
						frame:SetPortraitShown(true)
					end
					ApplyAtlasTexture(topLeftCorner, "UI-Frame-PortraitMetal-CornerTopLeft")
					self.root.PortraitOverlay:Show()
					self:ApplyModernPortrait()
					V:Assert(not self.root.PortraitOverlay:IsShown(), "Modern Simple Mode hides its portrait overlay on pass " .. pass)
					if frame.portrait then
						V:Assert(not frame.portrait:IsShown(), "Modern Simple Mode re-hides the native portrait on pass " .. pass)
					end
					if topLeftCorner.GetAtlas then
						V:AssertEqual(topLeftCorner:GetAtlas(), "UI-Frame-Metal-CornerTopLeft", "Modern Simple Mode restores the non-portrait corner on pass " .. pass)
					end
				end
				db.simpleMode = false
				self:ApplyModernPortrait()
				V:AssertEqual(
					self.root.PortraitOverlay.HitButton:GetObjectType(),
					"Button",
					"Every Modern theme uses the visible portrait as its interaction target"
				)
				V:Assert(self.root.PortraitOverlay.HitButton:IsMouseEnabled(), "Modern portrait accepts mouse input")
				V:Assert(self.root.PortraitOverlay.HitButton:GetScript("OnClick") ~= nil, "Modern portrait opens the changelog")
				V:Assert(
					not frame.PortraitButton or not frame.PortraitButton:IsShown(),
					"Modern hides the differently positioned legacy portrait hit rect"
				)
				if BFL.UsesFlatTheme and BFL:UsesFlatTheme() then
					local point, relativeTo, relativePoint, x, y = self.root.PortraitOverlay:GetPoint(1)
					V:AssertEqual(self.root.PortraitOverlay:GetWidth(), MODERN_THEMED_PORTRAIT_SIZE, "Modern flat-theme portrait uses the compact square width")
					V:AssertEqual(self.root.PortraitOverlay:GetHeight(), MODERN_THEMED_PORTRAIT_SIZE, "Modern flat-theme portrait uses the compact square height")
					V:Assert(
						point == "TOPLEFT"
							and relativeTo == frame
							and relativePoint == "TOPLEFT"
							and x == MODERN_THEMED_PORTRAIT_OFFSET_X
							and y == MODERN_THEMED_PORTRAIT_OFFSET_Y
							and not self.root.PortraitOverlay.Mask:IsShown(),
						"Modern flat-theme portrait is square and contained by the main frame"
					)
					V:Assert(
						frame._bflModernPortraitChromeShown == false
							and (not frame.PortraitContainer or not frame.PortraitContainer:IsShown()),
						"Modern flat themes keep Blizzard's native portrait ring suppressed"
					)
				end
			end)
			db.simpleMode = originalSimpleMode
			self:ApplyModernPortrait()
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernSimpleModeChrome", {
		condition = function()
			return self:IsModernActive() and self.root and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
		end,
		action = function(V)
			local db = GetDB()
			if not db then
				V:Skip("Database is unavailable")
				return
			end
			local previousSection = self.selectedSection or "friends"
			local originalSimpleMode = db.simpleMode
			local originalSimpleModeShowSearch = db.simpleModeShowSearch
			local ok, err = pcall(function()
				self.selectedSection = "friends"
				local Settings = BFL:GetModule("Settings")
				V:AssertNotNil(Settings, "Settings module should drive the real Simple Mode path")
				Settings:OnSimpleModeChanged(true)
				Settings:OnSimpleModeShowSearchChanged(false)
				local header = BetterFriendsFrame.FriendsTabHeader
				local insetPoint, insetRelativeTo, insetRelativePoint, insetX, insetY = BetterFriendsFrame.Inset:GetPoint(1)
				V:Assert(not self.root.FilterBar:IsShown(), "Modern Simple Mode hides the Contacts filter bar")
				V:Assert(not header.SearchBox:IsShown(), "Modern Simple Mode hides Contacts search")
				V:Assert(not self.root.FilterBar.FilterDropdown:IsShown(), "Modern Simple Mode hides Quick Filter")
				V:Assert(not self.root.FilterBar.SortButton:IsShown(), "Modern Simple Mode hides Sort")
				V:Assert(
					insetPoint == "TOPLEFT"
						and insetRelativeTo == self.root.TopDivider
						and insetRelativePoint == "BOTTOMLEFT"
						and insetX == 3
						and insetY == -7,
					"Modern Simple Mode expands the Contacts list into the hidden control row"
				)
				Settings:OnSimpleModeShowSearchChanged(true)
				local searchPoint, searchRelativeTo, searchRelativePoint, searchX = header.SearchBox:GetPoint(2)
				V:Assert(self.root.FilterBar:IsShown(), "Modern Simple Mode can retain its compact search row")
				V:Assert(header.SearchBox:IsShown(), "Modern Simple Mode search option shows Contacts search")
				V:Assert(not self.root.FilterBar.FilterDropdown:IsShown(), "Modern Simple Mode search keeps Quick Filter in the menu")
				V:Assert(not self.root.FilterBar.SortButton:IsShown(), "Modern Simple Mode search keeps Sort in the menu")
				V:Assert(
					searchPoint == "RIGHT"
						and searchRelativeTo == self.root.FilterBar
						and searchRelativePoint == "RIGHT"
						and searchX == -7,
					"Modern Simple Mode search expands across the hidden filter controls"
				)
				self.selectedSection = "who"
				self:RefreshModernConfigurationLayout("test-directory")
				V:Assert(self.root.FilterBar:IsShown(), "Modern Simple Mode preserves directory-specific controls")
			end)
			db.simpleMode = originalSimpleMode
			db.simpleModeShowSearch = originalSimpleModeShowSearch
			self.selectedSection = previousSection
			self:RefreshModernConfigurationLayout("test-restore")
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_StatusSelectionAlignment", {
		condition = function()
			local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
			local dropdown = header and header.StatusDropdown
			return BFL.IsRetail
				and BFL.FrameInitializer
				and BFL.FrameInitializer.AlignStatusDropdownSelection
				and dropdown
				and (dropdown.Text or dropdown.TextRegion or dropdown.SelectionText)
		end,
		action = function(V)
			local dropdown = BetterFriendsFrame.FriendsTabHeader.StatusDropdown
			local text = dropdown.Text or dropdown.TextRegion or dropdown.SelectionText
			V:Assert(BFL.FrameInitializer:AlignStatusDropdownSelection(dropdown), "Retail status selection exposes alignable text")
			local leftPoint, leftRelativeTo, leftRelativePoint, leftX, leftY = text:GetPoint(1)
			local rightPoint, rightRelativeTo, rightRelativePoint, rightX, rightY = text:GetPoint(2)
			V:Assert(
				leftPoint == "LEFT"
					and leftRelativeTo == dropdown
					and leftRelativePoint == "LEFT"
					and leftX == 4
					and leftY == 0
					and rightPoint == "RIGHT"
					and rightRelativeTo == dropdown
					and rightRelativePoint == "RIGHT"
					and rightX == -20
					and rightY == 0,
				"Retail status selection uses the centered Modern inset contract in both UI styles"
			)
			V:AssertEqual(text:GetJustifyH(), "CENTER", "Retail status selection is horizontally centered")
			V:AssertEqual(text:GetJustifyV(), "MIDDLE", "Retail status selection is vertically centered")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernRaidChrome", {
		condition = function()
			local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
			return self:IsModernActive() and raid and raid.ControlPanel and raid.GroupsInset
		end,
		action = function(V)
			local raid = BetterFriendsFrame.RaidFrame
			local control = raid.ControlPanel
			self:ApplyModernRaidGeometry()
			V:Assert(control.EveryoneAssistIcon:IsShown(), "Modern Raid shows Blizzard's separate assist icon")
			V:Assert(control.RoleSummary:IsShown(), "Modern Raid uses BFL's compact combined role summary")
			local PreviewMode = BFL:GetModule("PreviewMode")
			if PreviewMode and PreviewMode.IsComponentEnabled and PreviewMode:IsComponentEnabled("raid") then
				local roleSummary = control.RoleSummary
				for _, countRegion in ipairs({ roleSummary.TankCount, roleSummary.HealerCount, roleSummary.DamagerCount }) do
					if countRegion then
						V:Assert(#tostring(countRegion:GetText() or "") >= 2, "Raid preview role counts always use two digits")
					end
				end
			end
			V:Assert(not control.TankFrame:IsShown() and not control.HealerFrame:IsShown() and not control.DamagerFrame:IsShown(), "Modern Raid hides the expanded role counters")
			V:AssertEqual(control:GetHeight(), 32, "Modern Raid uses the compact control row")
			V:Assert(
				control.RaidInfoButton:GetWidth() >= 80 and control.RaidInfoButton:GetWidth() <= 88,
				"Modern Raid Info flexes only within its text-safe width range"
			)
			V:AssertEqual(control.RaidInfoButton:GetHeight(), 28, "Modern Raid Info uses the compact utility height")
			V:AssertEqual(control.ReadyCheckButton, control.BFL_ModernReadyCheckButton, "Modern Raid Ready Check uses its runtime Shared button")
			V:AssertEqual(control.ReadyCheckButton:GetWidth(), 28, "Modern Raid Ready Check uses a compact square icon-button width")
			V:AssertEqual(control.ReadyCheckButton:GetHeight(), control.RaidInfoButton:GetHeight(), "Modern Raid Ready Check matches Raid Info height")
			local _, controlCenterY = control:GetCenter()
			for label, region in pairs({
				["Assist All"] = control.EveryoneAssistCheckbox,
				["Raid Help"] = BetterFriendsFrame.HelpButton,
				["role counts"] = control.RoleSummary,
				["member count"] = control.MemberCount,
				["Ready Check"] = control.ReadyCheckButton,
				["Raid Info"] = control.RaidInfoButton,
			}) do
				local _, regionCenterY = region:GetCenter()
				V:Assert(
					controlCenterY and regionCenterY and math.abs(regionCenterY - controlCenterY) < 0.5,
					"Modern Raid " .. label .. " shares the control-row centerline"
				)
			end
			V:Assert(control.ReadyCheckButton.Icon ~= nil, "Modern Raid Ready Check keeps its action icon")
			local readyR, readyG, readyB = control.ReadyCheckButton.Icon:GetVertexColor()
			local palette, themed = self:GetModernThemeColors()
			if themed then
				local expectedColor = palette.accent
				if not control.ReadyCheckButton:IsEnabled() then
					local disabledFont = control.ReadyCheckButton:GetDisabledFontObject()
					if disabledFont and disabledFont.GetTextColor then
						local r, g, b = disabledFont:GetTextColor()
						expectedColor = { r, g, b }
					else
						expectedColor = palette.disabledText
					end
				end
				V:Assert(
					math.abs(readyR - expectedColor[1]) < 0.001
						and math.abs(readyG - expectedColor[2]) < 0.001
						and math.abs(readyB - expectedColor[3]) < 0.001,
					"Modern BFL Ready Check icon follows its enabled or disabled text color"
				)
			end
			local readyPoint, readyRelativeTo, readyRelativePoint, readyX = control.ReadyCheckButton:GetPoint(1)
			V:Assert(
				readyPoint == "TOPRIGHT"
					and readyRelativeTo == control.RaidInfoButton
					and readyRelativePoint == "TOPLEFT"
					and (readyX == -2 or readyX == -4),
				"Modern Raid Ready Check owns a non-overlapping slot before Raid Info"
			)
			V:Assert(
				not tostring(control.MemberCount:GetText() or ""):find("|T", 1, true),
				"Modern Raid member count contains text only and no icon"
			)
			local countPoint, countRelativeTo, countRelativePoint, countX = control.MemberCount:GetPoint(1)
			V:Assert(
				countPoint == "LEFT"
					and countRelativeTo == control.RoleSummary.DamagerIcon
					and countRelativePoint == "RIGHT"
					and (countX == 2 or countX == 6),
				"Modern Raid member count follows the final visible role cell"
			)
			local helpRight = BetterFriendsFrame.HelpButton:GetRight()
			local roleLeft = control.RoleSummary:GetLeft()
			V:Assert(helpRight and roleLeft and (roleLeft - helpRight) >= 2, "Modern Raid role counts do not overlap Raid Help")
			if control.ReadyCheckButton:IsShown() then
				local memberRight = control.MemberCount:GetRight()
				local readyLeft = control.ReadyCheckButton:GetLeft()
				V:Assert(
					memberRight and readyLeft and (readyLeft - memberRight) >= 2,
					"Modern Raid leaves a visible gap between member count and Ready Check"
				)
			end
			local helpPoint, helpRelativeTo, helpRelativePoint = BetterFriendsFrame.HelpButton:GetPoint(1)
			V:AssertEqual(helpPoint, "LEFT", "Modern Raid help follows Assist All horizontally")
			V:AssertEqual(helpRelativeTo, control.EveryoneAssistLabel, "Modern Raid help sits directly after the Assist All label")
			V:AssertEqual(helpRelativePoint, "RIGHT", "Modern Raid help uses the Assist All label's right edge")
			V:Assert(not raid.GroupsInset.Bg or not raid.GroupsInset.Bg:IsShown(), "Modern Raid has no shared group inset background")
			V:AssertEqual(raid.RaidToolsButton:GetHeight(), raid.ConvertToRaidButton:GetHeight(), "Modern Raid footer buttons share one baseline and height")
			V:Assert(math.abs(raid.RaidToolsButton:GetBottom() - raid.ConvertToRaidButton:GetBottom()) < 0.5, "Modern Raid footer buttons share one baseline")
			local RaidFrame = BFL:GetModule("RaidFrame")
			RaidFrame._lastLayoutWidth = nil
			RaidFrame._lastLayoutHeight = nil
			RaidFrame:UpdateGroupLayout()
			local firstGroup = raid.GroupsInset.GroupsContainer.Group1
			local firstSlot = firstGroup.Slot1
			local lastSlot = firstGroup.Slot5
			RaidFrame:InitializeMemberButtons()
			V:Assert(firstSlot._bflRankTooltip ~= nil, "Raid rank icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(firstSlot._bflMainTankTooltip ~= nil, "Main Tank icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(firstSlot._bflMainAssistTooltip ~= nil, "Main Assist icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(not firstSlot.Background:IsShown(), "Modern Raid member rows do not restore the legacy black background")
			if firstSlot.memberData and firstSlot.memberData._isMock then
				V:Assert(firstSlot.ClassColorTint:IsShown(), "Raid preview rows expose their class-color background tint")
				if firstSlot.memberData.rank == 2 and firstSlot.RankIcon.GetAtlas then
					V:AssertEqual(firstSlot.RankIcon:GetAtlas(), "friends-icon-raidLead", "Raid leader uses the 12.1 SocialUI atlas")
				elseif firstSlot.memberData.rank == 1 and firstSlot.RankIcon.GetAtlas then
					V:AssertEqual(firstSlot.RankIcon:GetAtlas(), "friends-icon-raidAssist", "Raid assistant uses the 12.1 SocialUI atlas")
				end
			else
				V:Assert(not firstSlot.ClassColorTint:IsShown(), "Live Modern Raid rows use the group card background")
			end
			local _, groupLabelSize = firstGroup.GroupTitle:GetFont()
			local _, nativeLabelSize = GameFontHighlight:GetFont()
			V:Assert(groupLabelSize and nativeLabelSize and math.abs(groupLabelSize - nativeLabelSize) < 0.01, "Modern Raid group labels use the native GameFontHighlight size")
			local groupBottom = firstGroup:GetBottom()
			local slotBottom = lastSlot:GetBottom()
			V:Assert(groupBottom and slotBottom and slotBottom >= groupBottom + 3, "Modern Raid keeps the fifth member slot inside the group card")
			local groupTop = firstGroup:GetTop()
			local firstSlotTop = firstSlot:GetTop()
			V:Assert(
				groupTop and firstSlotTop and math.abs((groupTop - firstSlotTop) - 20) < 0.5,
				"Modern Raid starts members 20 px below the group top"
			)
			local previousSection = self.selectedSection or "friends"
			self:ApplyModernSectionTopChrome("raid")
			V:Assert(self.root.TopFade:IsShown() and not self.root.TopDivider:IsShown(), "Modern Raid keeps the shared top fade without BFL's divider")
			self:ApplyModernSectionTopChrome(previousSection)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CustomTabIconColors", {
		condition = function()
			return self:IsModernActive() and SECTION_BY_ID.guild.tab and SECTION_BY_ID.who.tab
		end,
		action = function(V)
			for _, sectionID in ipairs({ "guild", "who" }) do
				local definition = SECTION_BY_ID[sectionID]
				local icon = definition.tab.Icon or definition.tab.icon
				ApplySectionIcon(icon, definition, true)
				local activeR, activeG, activeB = icon:GetVertexColor()
				V:Assert(not icon:IsDesaturated(), sectionID .. " icon preserves its source luminance")
				V:Assert(math.abs(activeR - CUSTOM_TAB_ICON_ACTIVE_COLOR[1]) < 0.01
					and math.abs(activeG - CUSTOM_TAB_ICON_ACTIVE_COLOR[2]) < 0.01
					and math.abs(activeB - CUSTOM_TAB_ICON_ACTIVE_COLOR[3]) < 0.01, sectionID .. " selected icon calibrates its source palette to Blizzard gold")
				ApplySectionIcon(icon, definition, false)
				local inactiveR, inactiveG, inactiveB = icon:GetVertexColor()
				V:Assert(math.abs(inactiveR - CUSTOM_TAB_ICON_INACTIVE_COLOR[1]) < 0.01
					and math.abs(inactiveG - CUSTOM_TAB_ICON_INACTIVE_COLOR[2]) < 0.01
					and math.abs(inactiveB - CUSTOM_TAB_ICON_INACTIVE_COLOR[3]) < 0.01, sectionID .. " inactive icon uses Blizzard's muted gold")
			end
			self:RefreshNavigation()
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernLegacyDropdownGuard", {
		condition = function()
			return self:IsModernActive() and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
		end,
		action = function(V)
			local header = BetterFriendsFrame.FriendsTabHeader
			self:HideModernLegacyHeaderDropdowns(header)
			for _, field in ipairs(LEGACY_HEADER_DROPDOWN_FIELDS) do
				local dropdown = header[field]
				if dropdown then
					dropdown:Show()
					V:Assert(not dropdown:IsShown(), "Modern guard keeps legacy " .. field .. " hidden")
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ContactChrome", {
		action = function(V)
			local friends = self:GetContactChrome("friends")
			local recent = self:GetContactChrome("recent_allies")
			local requests = self:GetContactChrome("friend_requests")
			local quickJoin = self:GetContactChrome("quick_join")
			V:Assert(friends.filterBar and friends.friendsFilter and friends.sort, "Friends keeps search, quick filters, and sorting")
			V:Assert(recent.filterBar and recent.recentFilter and not recent.sort, "Recent Allies gets its 12.1 search filters")
			V:AssertEqual(requests.action, "add_friend", "Friend Requests keeps the Add Friend action")
			V:AssertEqual(quickJoin.action, "quick_join", "Quick Join owns the shared action button")
			V:AssertEqual(self:GetContactChrome("guild").action, "guild_actions", "Guild uses the shared Modern action bar")
			V:AssertEqual(self:GetContactChrome("who").action, "who_actions", "Who uses the shared Modern action bar")
			V:Assert(self:GetContactChrome("raid").action == nil, "Raid does not inherit orphaned contact chrome")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernDirectoryChrome", {
		condition = function()
			return self:IsModernActive()
				and BetterFriendsFrame
				and BetterFriendsFrame.GuildFrame
				and BetterFriendsFrame.WhoFrame
		end,
		action = function(V)
			local previousSection = self.selectedSection or "friends"
			self:ApplyModernContentLayout("guild", true)
			local guild = BetterFriendsFrame.GuildFrame
			V:Assert(guild.SearchBox:IsShown(), "Guild exposes search in the shared 12.1 header row")
			V:AssertEqual(guild.SearchBox.searchIcon:GetWidth(), 10, "Guild keeps Blizzard's 10 px search glyph")
			V:AssertEqual(guild.SearchBox.searchIcon:GetHeight(), 10, "Guild search glyph keeps its aspect ratio")
			V:Assert(
				not guild.SearchBox.Backdrop or not guild.SearchBox.Backdrop:IsShown(),
				"Guild removes its legacy character-select search overlay"
			)
			V:Assert(guild.FilterDropdown:IsShown() and guild.SortDropdown:IsShown(), "Guild exposes Modern filter and sort controls")
			V:AssertEqual(guild.SearchBox:GetHeight(), guild.FilterDropdown:GetHeight(), "Guild search and filter share one height")
			V:AssertEqual(guild.SearchBox:GetHeight(), guild.SortDropdown:GetHeight(), "Guild search and sort share one height")
			V:Assert(not guild.ActionsButton:IsShown(), "Guild replaces the embedded Legacy action button")
			V:Assert(not guild.ListInset.Bg or not guild.ListInset.Bg:IsShown(), "Guild removes the Legacy list inset background")

			self:ApplyModernContentLayout("who", true)
			local who = BetterFriendsFrame.WhoFrame
			V:Assert(who.EditBox:IsShown() and who.WhoButton:IsShown(), "Who moves search and refresh into the shared header row")
			V:AssertEqual(who.EditBox:GetHeight(), who.WhoButton:GetHeight(), "Who search and Refresh share one height")
			V:AssertEqual(who.EditBox.searchIcon:GetWidth(), 10, "Who keeps Blizzard's 10 px search glyph")
			V:AssertEqual(who.EditBox.searchIcon:GetHeight(), 10, "Who search glyph keeps its aspect ratio")
			V:Assert(
				not who.EditBox.Backdrop or not who.EditBox.Backdrop:IsShown(),
				"Who removes its legacy character-select search overlay"
			)
			V:AssertEqual(who.NameHeader:GetHeight(), 28, "Who preserves Blizzard's native column-header height")
			V:AssertEqual(who.ColumnDropdown:GetHeight(), who.NameHeader:GetHeight(), "Who dropdown matches the native column buttons")
			for _, headerButton in ipairs({ who.NameHeader, who.ColumnDropdown, who.LevelHeader, who.ClassHeader }) do
				V:Assert(
					headerButton.BFL_ModernHeaderBackground
						and headerButton.BFL_ModernHeaderBackground:IsShown()
						and (not headerButton.Left or not headerButton.Left:IsShown())
						and (not headerButton.Middle or not headerButton.Middle:IsShown())
						and (not headerButton.Right or not headerButton.Right:IsShown()),
					"Who column buttons retain the original Modern header surface"
				)
			end
			if BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
				for _, headerButton in ipairs({ who.NameHeader, who.ColumnDropdown, who.LevelHeader, who.ClassHeader }) do
					local background = headerButton.BFL_ModernHeaderBackground
					local backgroundR, backgroundG, backgroundB = background:GetVertexColor()
					V:Assert(
						headerButton.BFL_ModernHeaderTone
							and background:IsShown()
							and background:IsDesaturated()
							and backgroundR < 1
							and backgroundG < 1
							and backgroundB < 1
							and (not headerButton.BFL_DarkBackdrop or not headerButton.BFL_DarkBackdrop:IsShown()),
						"Who themed column headers darken the original Modern surface"
					)
				end
				local listBackdrop = who.ListInset and who.ListInset.BFL_DarkBackdrop
				V:Assert(
					not listBackdrop or not listBackdrop:IsShown(),
					"Who results stay borderless in the Modern themed layout"
				)
				local WhoFrame = BFL:GetModule("WhoFrame")
				local toggleIcon = WhoFrame and WhoFrame.builderToggle and WhoFrame.builderToggle.icon
				if toggleIcon then
					local palette = self:GetModernThemeColors()
					local toggleR, toggleG, toggleB = toggleIcon:GetVertexColor()
					V:Assert(
						math.abs(toggleR - palette.accent[1]) < 0.001
							and math.abs(toggleG - palette.accent[2]) < 0.001
							and math.abs(toggleB - palette.accent[3]) < 0.001,
						"Who Search Builder BFL icon uses the accent color"
					)
				end
			end
			V:Assert(not who.ListInset.Bg or not who.ListInset.Bg:IsShown(), "Who removes the Legacy list inset background")
			V:AssertEqual(who.AddFriendButton:GetHeight(), 30, "Who uses the shared action-row button height")
			local WhoFrame = BFL:GetModule("WhoFrame")
			local flyout = WhoFrame and WhoFrame.builderFlyout
			if flyout and who.ListInset then
				local leftMargin = flyout:GetLeft() - who.ListInset:GetLeft()
				local rightMargin = who.ListInset:GetRight() - flyout:GetRight()
				V:Assert(
					math.abs(leftMargin - rightMargin) < 0.5,
					"Who Search Builder is centered across the full list width"
				)
				V:Assert(
					not flyout.BFL_ModernLeftLine:IsShown() and not flyout.BFL_ModernRightLine:IsShown(),
					"Embedded Who Search Builder does not draw a popup border"
				)
				if BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
					local palette = self:GetModernThemeColors()
					local headerR, headerG, headerB = flyout.BFL_ModernHeader:GetColorTexture()
					V:Assert(
						math.abs(headerR - palette.control[1]) < 0.001
							and math.abs(headerG - palette.control[2]) < 0.001
							and math.abs(headerB - palette.control[3]) < 0.001,
						"Who Search Builder header follows the Dark/Custom control color"
					)
					for _, button in ipairs({ WhoFrame.builder.searchBtn, WhoFrame.builder.resetBtn }) do
						V:Assert(
							button.BFL_DarkBackdrop
								and button.BFL_DarkBackdrop:IsShown()
								and (not button.Center or button.Center:GetAlpha() == 0),
							"Who Search Builder action buttons use complete themed chrome"
						)
					end
					for _, input in ipairs({
						WhoFrame.builder.nameInput,
						WhoFrame.builder.guildInput,
						WhoFrame.builder.zoneInput,
						WhoFrame.builder.levelMin,
						WhoFrame.builder.levelMax,
					}) do
						V:Assert(input.BFL_DarkBackdrop and input.BFL_DarkBackdrop:IsShown(), "Who Search Builder fields use themed chrome")
					end
				end
				V:Assert(
					WhoFrame.builder.nameInput.searchIcon ~= nil
						and WhoFrame.builder.nameInput.Instructions:GetText()
							== (GetL().WHO_BUILDER_NAME_PLACEHOLDER or "Search for character name"),
					"Who Search Builder uses localized search fields"
				)
				local inputLeft = WhoFrame.builder.nameInput:GetLeft()
				local inputRight = WhoFrame.builder.nameInput:GetRight()
				local dropdownLeft = WhoFrame.builder.classDropdown:GetLeft()
				local dropdownRight = WhoFrame.builder.classDropdown:GetRight()
				V:Assert(
					inputLeft
						and dropdownLeft
						and math.abs((inputLeft - dropdownLeft) - 8) < 0.5
						and inputRight
						and dropdownRight
						and math.abs(inputRight - dropdownRight) < 0.5,
					"Who dropdown chrome compensates for SearchBoxTemplate's 8 px visual inset"
				)
			end
			self:ApplyModernContentLayout(previousSection, true)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_RecentAlliesSearchContract", {
		condition = function()
			local RecentAllies = BFL:GetModule("RecentAllies")
			return RecentAllies and RecentAllies.BuildSearchInfo ~= nil
		end,
		action = function(V)
			local RecentAllies = BFL:GetModule("RecentAllies")
			local originalFilters = RecentAllies.selectedFilters
			local originalSearch = RecentAllies.searchText
			local ok, err = pcall(function()
				RecentAllies.selectedFilters = { online = true, roleplaying = true }
				RecentAllies.searchText = "ally"
				local info = RecentAllies:BuildSearchInfo()
				V:AssertEqual(info.searchText, "ally", "Recent Allies forwards the search text")
				V:Assert(info.isOnline and not info.isAFK and not info.isDND and not info.isOffline, "Recent Allies supplies every required status field")
				local rolePlaying = Enum and Enum.RecentAlliesFriendTag and Enum.RecentAlliesFriendTag.RolePlaying
				V:AssertEqual(#info.interests, rolePlaying ~= nil and 1 or 0, "Missing PTR enum values are not forwarded")
				if rolePlaying == nil then
					for _, option in ipairs(RecentAllies:GetAvailableInterestOptions()) do
						V:Assert(option.id ~= "roleplaying", "Missing PTR enum values are not offered in the menu")
					end
				end
			end)
			RecentAllies.selectedFilters = originalFilters
			RecentAllies.searchText = originalSearch
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CapabilityGates", {
		action = function(V)
			local originalStyle = self.appliedStyle
			self.appliedStyle = STYLE_LEGACY
			local sections = self:BuildAvailableSectionIDs({
				friends = true,
				friend_requests = true,
				raid = true,
				who = true,
			})
			self.appliedStyle = originalStyle
			V:AssertEqual(table.concat(sections, ","), "friends,friend_requests,raid,who", "Unavailable systems must be omitted without changing order")
			V:AssertEqual(
				self:GetCapabilities().raid,
				BFL.IsRetail == true and not self:AreRaidGroupsDisabled(),
				"Raid availability follows the Retail DisableRaidGroups game rule"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SocialTabMapping", {
		condition = function()
			return _G.SocialUITabType ~= nil
		end,
		action = function(V)
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.Friends), "friends", "Social Friends maps to BFL Friends")
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.FriendRequests), "friend_requests", "Social requests map to BFL requests")
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.RaidList), "raid", "Social Raid maps to BFL Raid")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_BlizzardSocialTabFallback", {
		condition = function()
			return _G.SocialUITabType ~= nil
		end,
		action = function(V)
			V:AssertEqual(self:GetBlizzardSocialTab("quick_join"), SocialUITabType.QuickJoin, "Mapped sections retain their Blizzard tab")
			V:AssertEqual(self:GetBlizzardSocialTab("guild"), SocialUITabType.Friends, "Guild falls back to Blizzard Friends")
			V:AssertEqual(self:GetBlizzardSocialTab("who"), SocialUITabType.Friends, "Who falls back to Blizzard Friends")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_BlizzardSocialUIBypass", {
		action = function(V)
			local originalControl = self.originalSocialUIControl
			local toggleCalls = 0
			local deferredTab
			local selectedTab
			self.originalSocialUIControl = {
				Toggle = function()
					toggleCalls = toggleCalls + 1
				end,
				OpenToTab = function()
					error("The redirected OpenToTab path must not be used")
				end,
			}
			local hiddenFrame = {
				IsShown = function()
					return false
				end,
				SetDeferredOpenTab = function(_, tabType)
					deferredTab = tabType
				end,
			}
			local visibleFrame = {
				IsShown = function()
					return true
				end,
				SelectTab = function(_, tabType)
					selectedTab = tabType
				end,
			}
			local ok, err = pcall(function()
				V:Assert(self:OpenLoadedBlizzardSocialUI(hiddenFrame, 101), "Hidden Blizzard SocialUI opens")
				V:AssertEqual(deferredTab, 101, "Hidden Blizzard SocialUI receives the deferred tab")
				V:AssertEqual(toggleCalls, 1, "Hidden Blizzard SocialUI uses Blizzard's original Toggle")
				V:Assert(self:OpenLoadedBlizzardSocialUI(visibleFrame, 202), "Visible Blizzard SocialUI updates in place")
				V:AssertEqual(selectedTab, 202, "Visible Blizzard SocialUI selects the requested tab")
				V:AssertEqual(toggleCalls, 1, "Visible Blizzard SocialUI is not toggled closed")
			end)
			self.originalSocialUIControl = originalControl
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CountersAndGlow", {
		action = function(V)
			V:AssertEqual(self:GetSectionCount("friend_requests", 4, 7), 4, "Requests use the invite counter")
			V:AssertEqual(self:GetSectionCount("quick_join", 4, 7), 7, "Quick Join uses the group counter")
			V:AssertEqual(self:GetSectionCount("friends", 4, 7), 0, "Uncounted sections stay empty")
			V:Assert(self:ShouldStartRequestGlow(true, "friends"), "A new request glows outside the requests section")
			V:Assert(not self:ShouldStartRequestGlow(true, "friend_requests"), "The selected requests section does not glow")
			V:Assert(not self:ShouldStartRequestGlow(false, "friends"), "Refreshes without a new request do not start a glow")
			V:Assert(FRIENDS_RESTRICTED_SECTIONS.quick_join, "Quick Join follows the native friends restriction")
			V:Assert(FRIENDS_RESTRICTED_SECTIONS.friend_requests, "Friend Requests follow the native friends restriction")
			for _, sectionID in ipairs({ "quick_join", "friend_requests" }) do
				local tab = SECTION_BY_ID[sectionID] and SECTION_BY_ID[sectionID].tab
				if tab and tab.Count then
					local drawLayer = tab.Count:GetDrawLayer()
					V:AssertEqual(drawLayer, "ARTWORK", sectionID .. " badge matches Blizzard's draw layer")
					V:AssertEqual(tab.Count:GetWidth(), 32, sectionID .. " badge matches Blizzard's width")
					V:AssertEqual(tab.Count:GetHeight(), 18, sectionID .. " badge matches Blizzard's height")
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_LiveStyleSwitch", {
		condition = function()
			return BetterFriendsFrame ~= nil
				and self:IsSocialUIAvailable()
				and not (InCombatLockdown and InCombatLockdown())
		end,
		setup = function()
			self.testOriginalStyle = self:GetRequestedStyle()
			self.testOriginalSection = self:GetSelectedSection()
			self.testOriginalPositions = {}
			local control = BetterFriendsFrame.RaidFrame and BetterFriendsFrame.RaidFrame.ControlPanel
			self.testReadyCheckWasShown = control
				and control.ReadyCheckButton
				and control.ReadyCheckButton:IsShown()
			local db = GetDB()
			for _, key in ipairs({ LEGACY_LAYOUT_KEY, MODERN_LAYOUT_KEY, "Shared" }) do
				local position = db and db.mainFramePosition and db.mainFramePosition[key]
				self.testOriginalPositions[key] = position and {
					point = position.point,
					relativePoint = position.relativePoint,
					x = position.x,
					y = position.y,
				} or false
			end
		end,
		action = function(V)
			V:Assert(self:SetStyle(STYLE_LEGACY), "Legacy style switch should succeed")
			V:AssertEqual(self:GetAppliedStyle(), STYLE_LEGACY, "Legacy applies without reload")

			for index = 1, 4 do
				local tab = BetterFriendsFrame["BottomTab" .. index]
				V:Assert(tab and tab:IsShown(), "Legacy bottom tab " .. index .. " is restored after a live switch")
			end
			local header = BetterFriendsFrame.FriendsTabHeader
			local mainInset = BetterFriendsFrame.Inset
			if header and header.Tab1 and mainInset then
				local insetTopPoint, insetTopRelativeTo, insetTopRelativePoint, insetTopX, insetTopY = mainInset:GetPoint(1)
				local insetBottomPoint, insetBottomRelativeTo, insetBottomRelativePoint, insetBottomX, insetBottomY =
					mainInset:GetPoint(2)
				V:Assert(
					insetTopPoint == "TOPLEFT"
						and insetTopRelativeTo == header.Tab1
						and insetTopRelativePoint == "BOTTOMLEFT"
						and insetTopX == -4
						and insetTopY == 1
						and insetBottomPoint == "BOTTOMRIGHT"
						and insetBottomRelativeTo == BetterFriendsFrame
						and insetBottomRelativePoint == "BOTTOMRIGHT"
						and insetBottomX == -6
						and insetBottomY == 26,
					"Legacy restores the v2.7.0 shared inset below the top tabs"
				)
			end
			local legacyHeight = BetterFriendsFrame:GetHeight()
			V:Assert(
				legacyHeight and math.abs(legacyHeight - math.floor(legacyHeight + 0.5)) < 0.001,
				"Legacy frame height is normalized to a whole pixel"
			)

			local header = BetterFriendsFrame.FriendsTabHeader
			if header and header.Tab4 and header.Tab4:IsShown() then
				local previousVisible = header.Tab3 and header.Tab3:IsShown() and header.Tab3
					or (header.Tab2 and header.Tab2:IsShown() and header.Tab2)
					or header.Tab1
				local point, relativeTo, relativePoint, xOffset = header.Tab4:GetPoint(1)
				V:AssertEqual(relativeTo, previousVisible, "Guild top tab skips unavailable RAF without leaving a gap")
				V:Assert(
					point == "TOPLEFT" and relativePoint == "TOPRIGHT",
					"Guild top tab follows Blizzard's top-edge anchor chain"
				)
				V:AssertEqual(xOffset, 3, "Guild top tab uses Blizzard's standard horizontal spacing")
				V:Assert(header.Tab4:GetWidth() <= 160, "Guild top tab keeps its compact Legacy width")
			end

			self:SelectSection("friends")
			V:Assert(
				not BetterFriendsFrame.RecruitmentButton:IsShown(),
				"Legacy Recruitment stays hidden outside the RAF top tab"
			)
			if BetterFriendsFrame_ShowBottomTab then
				BetterFriendsFrame_ShowBottomTab(2)
				BetterFriendsFrame_ShowBottomTab(1)
				if self:GetCapabilities().guild then
					V:Assert(header and header.Tab4 and header.Tab4:IsShown(), "Guild top tab survives bottom-tab round trips")
				end
				V:Assert(
					not BetterFriendsFrame.RecruitmentButton:IsShown(),
					"Bottom-tab round trips do not leak the Recruitment button"
				)
			end

			local who = BetterFriendsFrame.WhoFrame
			if who then
				V:Assert(not self.root:IsShown(), "Legacy keeps the Modern root hidden")
				V:Assert(who.WhoButton ~= who.BFL_ModernWhoButton, "Legacy Who refresh restores the UIPanel button")
				V:Assert(who.AddFriendButton ~= who.BFL_ModernAddFriendButton, "Legacy Who Add Friend restores the UIPanel button")
				V:Assert(who.GroupInviteButton ~= who.BFL_ModernGroupInviteButton, "Legacy Who Group Invite restores the UIPanel button")
				V:AssertEqual(who.WhoButton:GetHeight(), 21, "Legacy Who refresh keeps the v2.7.0 height")
				V:AssertEqual(who.AddFriendButton:GetHeight(), 21, "Legacy Who Add Friend keeps the v2.7.0 height")
				V:AssertEqual(who.GroupInviteButton:GetHeight(), 21, "Legacy Who Group Invite keeps the v2.7.0 height")
				V:Assert(who.WhoButton:IsMouseEnabled(), "Legacy Who refresh accepts mouse input after a style switch")
				V:Assert(
					not who.BFL_ModernWhoButton or not who.BFL_ModernWhoButton:IsShown(),
					"Legacy hides the Modern Who refresh proxy"
				)
				if BetterFriendsFrame.NineSlice then
					local borderLevel = BetterFriendsFrame.NineSlice:GetFrameLevel()
					V:Assert(who.WhoButton:GetFrameLevel() > borderLevel, "Legacy Who refresh stays above the main frame border")
					V:Assert(who.AddFriendButton:GetFrameLevel() > borderLevel, "Legacy Who Add Friend stays above the main frame border")
					V:Assert(who.GroupInviteButton:GetFrameLevel() > borderLevel, "Legacy Who Group Invite stays above the main frame border")
				end
				V:Assert(who.WhoButton:GetScript("OnClick") ~= nil, "Legacy Who refresh retains its click handler")
				local insetPoint, insetRelativeTo, insetRelativePoint, insetX, insetY = who.ListInset:GetPoint(1)
				local listBottomPoint, listBottomRelativeTo, listBottomRelativePoint, listBottomX, listBottomY =
					who.ListInset:GetPoint(2)
				V:Assert(
					insetPoint == "TOPLEFT"
						and insetRelativeTo == BetterFriendsFrame.Inset
						and insetRelativePoint == "TOPLEFT"
						and insetX == 0
						and insetY == 40
						and listBottomPoint == "BOTTOMRIGHT"
						and listBottomRelativeTo == BetterFriendsFrame.Inset
						and listBottomRelativePoint == "BOTTOMRIGHT"
						and listBottomX == 0
						and listBottomY == 0,
					"Legacy Who restores the v2.7.0 list inset anchor"
				)
				if who.EditBox then
					local searchPoint, searchRelativeTo, searchRelativePoint, searchX, searchY = who.EditBox:GetPoint(1)
					local searchRightPoint, searchRightRelativeTo, searchRightRelativePoint, searchRightX, searchRightY =
						who.EditBox:GetPoint(2)
					V:Assert(
						searchPoint == "BOTTOMLEFT"
							and searchRelativeTo == who.ListInset
							and searchRelativePoint == "BOTTOMLEFT"
							and searchX == 35
							and searchY == 15
							and searchRightPoint == "BOTTOMRIGHT"
							and searchRightRelativeTo == who.ListInset
							and searchRightRelativePoint == "BOTTOMRIGHT"
							and searchRightX == -20
							and searchRightY == 15
							and who.EditBox:GetHeight() == 20,
						"Legacy Who restores the live 2.7.0 search extent"
					)
					for _, key in ipairs({ "Left", "Middle", "Right" }) do
						V:Assert(not who.EditBox[key] or not who.EditBox[key]:IsShown(), "Legacy Who hides Modern SearchBox chrome")
					end
					V:Assert(not who.EditBox.Backdrop or who.EditBox.Backdrop:IsShown(), "Legacy Who restores the v2.7.0 search backdrop")
					if who.EditBox.Instructions then
						V:AssertEqual(who.EditBox.Instructions:GetMaxLines(), 2, "Legacy Who restores the two-line search instructions")
						V:AssertEqual(
							who.EditBox.Instructions:GetText(),
							who.EditBox.instructionText or WHO_LIST_SEARCH_INSTRUCTIONS or "",
							"Legacy Who restores its original search placeholder"
						)
					end
				end
				if who.ScrollBox and who.ListInset and who.ListInset.Totals then
					local scrollTopPoint, scrollTopRelativeTo, scrollTopRelativePoint, scrollTopX, scrollTopY =
						who.ScrollBox:GetPoint(1)
					local scrollBottomPoint, scrollBottomRelativeTo, scrollBottomRelativePoint, scrollBottomX, scrollBottomY =
						who.ScrollBox:GetPoint(2)
					V:Assert(
						scrollTopPoint == "TOPLEFT"
							and scrollTopRelativeTo == who.ListInset
							and scrollTopRelativePoint == "TOPLEFT"
							and scrollTopX == 4
							and scrollTopY == -4
							and scrollBottomPoint == "BOTTOMRIGHT"
							and scrollBottomRelativeTo == who.ListInset.Totals
							and scrollBottomRelativePoint == "TOPRIGHT"
							and scrollBottomX == -4
							and scrollBottomY == 2,
						"Legacy Who list consumes the v2.7.0 vertical extent"
					)
				end
			end

			local raid = BetterFriendsFrame.RaidFrame
			local control = raid and raid.ControlPanel
			if raid and control then
				V:Assert(control.RaidInfoButton ~= control.BFL_ModernRaidInfoButton, "Legacy Raid Info restores the UIPanel button")
				V:Assert(control.ReadyCheckButton ~= control.BFL_ModernReadyCheckButton, "Legacy Ready Check restores the SquareIcon button")
				V:Assert(raid.RaidToolsButton ~= raid.BFL_ModernRaidToolsButton, "Legacy Raid Tools restores the UIPanel button")
				V:Assert(raid.ConvertToRaidButton ~= raid.BFL_ModernConvertToRaidButton, "Legacy Raid conversion restores the UIPanel button")
				V:AssertEqual(control.RaidInfoButton:GetHeight(), 22, "Legacy Raid Info keeps the v2.7.0 height")
				V:AssertEqual(control.ReadyCheckButton:GetHeight(), 22, "Legacy Ready Check keeps the v2.7.0 height")
				V:AssertEqual(raid.RaidToolsButton:GetHeight(), 21, "Legacy Raid Tools keeps the v2.7.0 height")
				V:AssertEqual(raid.ConvertToRaidButton:GetHeight(), 21, "Legacy Raid conversion keeps the v2.7.0 height")
				if control.ReadyCheckButton and control.EveryoneAssistLabel then
					control.ReadyCheckButton:Show()
					local RaidFrame = BFL:GetModule("RaidFrame")
					if RaidFrame and RaidFrame.UpdateControlPanelLayout then
						RaidFrame:UpdateControlPanelLayout()
					end
					V:Assert(control.EveryoneAssistLabel:IsShown(), "Retail Legacy keeps Assist All visible beside Ready Check")
					local readyPoint, readyRelativeTo, readyRelativePoint, readyX = control.ReadyCheckButton:GetPoint(1)
					V:Assert(
						readyPoint == "RIGHT"
							and readyRelativeTo == control.RaidInfoButton
							and readyRelativePoint == "LEFT"
							and readyX == -5,
						"Retail Legacy keeps Ready Check in its dedicated slot before Raid Info"
					)
					if control.MemberCount and control.RoleSummary then
						local countPoint, countRelativeTo, countRelativePoint, countX = control.MemberCount:GetPoint(1)
						V:Assert(
							countPoint == "LEFT"
								and countRelativeTo == control.RoleSummary
								and countRelativePoint == "RIGHT"
								and countX == -3,
							"Retail Legacy shifts the member count left of the Ready Check slot"
						)
					end
					control.ReadyCheckButton:SetShown(self.testReadyCheckWasShown == true)
				end
			end

			local guild = BetterFriendsFrame.GuildFrame
			if guild and guild.ScrollBox and guild.ScrollBar then
				V:AssertEqual(guild.ScrollBar:GetWidth(), 22, "Legacy Guild restores the v2.7.0 scrollbar width")
				local point, relativeTo, relativePoint, xOffset = guild.ScrollBar:GetPoint(1)
				V:Assert(
					point == "TOPLEFT" and relativeTo == guild.ScrollBox and relativePoint == "TOPRIGHT" and xOffset == 0,
					"Legacy Guild scrollbar restores the v2.7.0 rail anchor"
				)
			end

			local WhoFrame = BFL:GetModule("WhoFrame")
			if WhoFrame and WhoFrame.builderFlyout then
				V:AssertEqual(WhoFrame.builderStyle, "legacy", "Legacy rebuilds the Who Search Builder with Legacy controls")
				V:Assert(
					not (WhoFrame.builder and WhoFrame.builder.nameInput and WhoFrame.builder.nameInput.searchIcon),
					"Legacy Who Search Builder does not retain Modern SearchBox chrome"
				)
			end

			V:Assert(self:SetStyle(STYLE_MODERN), "Modern style switch should succeed")
			V:AssertEqual(self:GetAppliedStyle(), STYLE_MODERN, "Modern applies without reload")
			if self.legacyState then
				V:Assert(
					self.legacyState.frames["who.totals"] == nil,
					"Who totals FontString is captured as a region, never as a frame"
				)
			end
			if who then
				V:AssertEqual(who.WhoButton, who.BFL_ModernWhoButton, "Modern Who uses only its runtime Shared button")
				V:AssertEqual(who.AddFriendButton, who.BFL_ModernAddFriendButton, "Modern Who Add Friend uses only its runtime Shared button")
				V:AssertEqual(who.GroupInviteButton, who.BFL_ModernGroupInviteButton, "Modern Who Group Invite uses only its runtime Shared button")
				V:Assert(who.WhoButton:IsMouseEnabled(), "Modern Who refresh accepts mouse input after a style switch")
				V:Assert(
					not who.BFL_LegacyWhoButton:IsShown(),
					"Modern hides the Legacy Who refresh button"
				)
				V:AssertEqual(
					who.WhoButton:GetScript("OnEnter"),
					who.WhoButton.BFL_TemplateScripts and who.WhoButton.BFL_TemplateScripts.OnEnter,
					"Modern Who Refresh keeps the SharedButtonTemplate tooltip handler"
				)
				V:Assert(
					who.WhoButton:GetScript("OnShow") ~= who.BFL_LegacyWhoButton:GetScript("OnShow"),
					"Modern Who Refresh keeps the SharedButtonTemplate OnShow handler"
				)
				V:Assert(
					who.WhoButton:GetScript("OnMouseDown") ~= who.BFL_LegacyWhoButton:GetScript("OnMouseDown"),
					"Modern Who Refresh keeps the ThreeSlice mouse-state handler"
				)
				V:Assert(
					who.WhoButton.Center ~= nil and who.WhoButton.Middle == nil,
					"Modern Who Refresh uses the Retail 12.1 ThreeSlice region contract"
				)
				local rowPoint, rowRelativeTo, rowRelativePoint, rowX = who.ScrollBox:GetPoint(1)
				V:Assert(
					rowPoint == "TOPLEFT"
						and rowRelativeTo == who.NameHeader
						and rowRelativePoint == "BOTTOMLEFT"
						and rowX == 0,
					"Modern Who rows share the column header's horizontal origin"
				)
			end
			if raid and control then
				V:AssertEqual(control.RaidInfoButton, control.BFL_ModernRaidInfoButton, "Modern Raid Info keeps its runtime Shared button")
				V:AssertEqual(control.ReadyCheckButton, control.BFL_ModernReadyCheckButton, "Modern Raid Ready Check keeps its runtime Shared button")
				V:AssertEqual(raid.RaidToolsButton, raid.BFL_ModernRaidToolsButton, "Modern Raid Tools keeps its runtime Shared button")
				V:AssertEqual(raid.ConvertToRaidButton, raid.BFL_ModernConvertToRaidButton, "Modern Raid conversion keeps its runtime Shared button")
			end
		end,
		teardown = function()
			local control = BetterFriendsFrame
				and BetterFriendsFrame.RaidFrame
				and BetterFriendsFrame.RaidFrame.ControlPanel
			if control and control.ReadyCheckButton then
				control.ReadyCheckButton:SetShown(self.testReadyCheckWasShown == true)
			end
			self:SetStyle(self.testOriginalStyle or self:GetDefaultRequestedStyle())
			self:SelectSection(self.testOriginalSection or "friends")
			local db = GetDB()
			if db and db.mainFramePosition then
				for key, position in pairs(self.testOriginalPositions or {}) do
					db.mainFramePosition[key] = position or nil
				end
			end
			self.testOriginalStyle = nil
			self.testOriginalSection = nil
			self.testOriginalPositions = nil
			self.testReadyCheckWasShown = nil
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SocialRedirects", {
		condition = function()
			return self.redirectsInstalled and _G.SocialUIControl ~= nil
		end,
		action = function(V)
			local originalToggleSocialUI = self.originalToggleSocialUI
			local originalControl = self.originalSocialUIControl
			local redirects = {
				toggleSocialUI = _G.ToggleSocialUI ~= originalToggleSocialUI,
				toggle = SocialUIControl.Toggle ~= originalControl.Toggle,
				openToTab = SocialUIControl.OpenToTab ~= originalControl.OpenToTab,
				toggleToTab = SocialUIControl.ToggleToTab ~= originalControl.ToggleToTab,
				toggleToTabAndSideWindow = SocialUIControl.ToggleToTabAndSideWindow ~= originalControl.ToggleToTabAndSideWindow,
				hide = SocialUIControl.Hide ~= originalControl.Hide,
				ownsAvailableSocialUI = not self:IsSocialUIAvailable() or self.redirectsInstalled,
			}
			self:RestoreSocialUIRedirects()
			local restores = {
				toggleSocialUI = _G.ToggleSocialUI == originalToggleSocialUI,
			}
			for _, key in ipairs({ "Toggle", "OpenToTab", "ToggleToTab", "ToggleToTabAndSideWindow", "Hide" }) do
				restores[key] = SocialUIControl[key] == originalControl[key]
			end
			self:InstallSocialUIRedirects()
			local reinstalled = self.redirectsInstalled
			V:Assert(redirects.toggleSocialUI, "ToggleSocialUI is redirected")
			V:Assert(redirects.toggle, "SocialUI Toggle is redirected")
			V:Assert(redirects.openToTab, "SocialUI OpenToTab is redirected")
			V:Assert(redirects.toggleToTab, "SocialUI ToggleToTab is redirected")
			V:Assert(redirects.toggleToTabAndSideWindow, "SocialUI tab plus side-window routing is redirected")
			V:Assert(redirects.hide, "SocialUI Hide is redirected")
			V:Assert(redirects.ownsAvailableSocialUI, "SocialUI API presence keeps BFL as the entry point regardless of Blizzard's runtime switch")
			V:Assert(restores.toggleSocialUI, "ToggleSocialUI restores symmetrically")
			for _, key in ipairs({ "Toggle", "OpenToTab", "ToggleToTab", "ToggleToTabAndSideWindow", "Hide" }) do
				V:Assert(restores[key], "SocialUI " .. key .. " restores symmetrically")
			end
			V:Assert(reinstalled, "SocialUI redirects reinstall after a restore or addon reload")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernPreviewBattleTag", {
		condition = function()
			local PreviewMode = BFL:GetModule("PreviewMode")
			return self:IsModernActive()
				and self.root
				and BetterFriendsFrame
				and BetterFriendsFrame.FriendsTabHeader
				and BetterFriendsFrame.FriendsTabHeader.BattlenetFrame
				and PreviewMode
				and not PreviewMode.enabled
		end,
		action = function(V)
			local PreviewMode = BFL:GetModule("PreviewMode")
			local StreamerMode = BFL:GetModule("StreamerMode")
			if StreamerMode and StreamerMode.IsActive and StreamerMode:IsActive() then
				V:Skip("Streamer Mode intentionally owns the BattleTag header")
				return
			end

			local tag = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame.Tag
			local originalText = tag:GetText()
			local originalBattleTag = self.battleTag
			local originalEnabled = PreviewMode.enabled
			local originalProfile = PreviewMode.activeProfile
			local originalComponents = PreviewMode.activeComponents
			local ok, err = pcall(function()
				PreviewMode.enabled = true
				PreviewMode.activeProfile = "battletag"
				PreviewMode.activeComponents = { battletag = true }
				self:RefreshBattleTag()
				V:AssertEqual(
					self.battleTag,
					PreviewMode.MOCK_BATTLETAG,
					"Modern preview stores the mock BattleTag as the active header value"
				)
				V:Assert(
					tostring(tag:GetText() or ""):find("YourName", 1, true) ~= nil,
					"Modern preview renders the masked BattleTag in the header"
				)
			end)
			PreviewMode.enabled = originalEnabled
			PreviewMode.activeProfile = originalProfile
			PreviewMode.activeComponents = originalComponents
			self.battleTag = originalBattleTag
			tag:SetText(originalText)
			if not ok then
				error(err, 0)
			end
		end,
	})
	TestSuite:RegisterTest("data", "FriendsUI_RealIDWarningThemeBackground", {
		action = function(V)
			local blizzard = self:GetRealIDWarningBackgroundColor(MODERN_BLIZZARD_THEME_COLORS, "blizzard")
			V:AssertEqual(blizzard[4], 0.85, "Blizzard Real ID warning should preserve the native overlay opacity")

			local themed = self:GetRealIDWarningBackgroundColor({
				background = { 0.1, 0.1, 0.1, 0.3 },
				panel = { 0.2, 0.2, 0.2, 0.4 },
			}, "ellesmereui")
			V:AssertEqual(themed[1], 0.2, "Themed Real ID warning should use the theme panel color")
			V:AssertEqual(themed[4], 0.94, "Themed Real ID warning should remain readable over request cards")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_RealIDWarningOverlayLayer", {
		condition = function()
			return self:IsModernActive()
				and self.root
				and self.root.RequestsFrame
				and self.root.RequestsFrame.RealIDWarning
				and self.root.RequestsFrame.ScrollBox
		end,
			action = function(V)
				local requests = self.root.RequestsFrame
				local warning = requests.RealIDWarning
				self:LayoutRealIDWarning()
				V:AssertNotNil(warning.ScrollableWarningText, "Real ID warning should use Blizzard's scrolling text template")
				V:AssertNotNil(warning.ScrollBar, "Real ID warning should provide Blizzard's minimal overflow scrollbar")
				local warningText = warning.ScrollableWarningText:GetFontString()
				V:AssertEqual(warning.Text, warningText, "Theme text styling should target the scrolling warning text")
				V:AssertEqual(warningText:GetJustifyH(), "CENTER", "Real ID warning text should remain centered horizontally")
				V:AssertEqual(warningText:GetJustifyV(), "TOP", "Real ID warning text should begin below the icons")
				V:AssertEqual(warning:GetFrameStrata(), "DIALOG", "Real ID warning should use Blizzard's dialog strata")
			V:Assert(
				warning:GetFrameLevel() > requests.ScrollBox:GetFrameLevel(),
				"Real ID warning should render above recycled request cards"
			)
			local drawLayer = warning.Background:GetDrawLayer()
			V:AssertEqual(drawLayer, "BACKGROUND", "Real ID warning surface should remain behind its own content")
		end,
	})
end

function FriendsUI:Initialize()
	if not BFL.IsRetail then
		self.appliedStyle = STYLE_LEGACY
		return
	end
	pcall(function()
		BFL:RegisterEventCallback("SOCIAL_UI_SYSTEM_STATUS_UPDATED", function()
			self:EnsureSocialUIRedirects()
			self:ApplyEffectiveStyle("social-ui-status")
			local Settings = BFL:GetModule("Settings")
			if Settings and Settings.RefreshGeneralTab then
				Settings:RefreshGeneralTab()
			end
			local SettingsDesigner = BFL:GetModule("SettingsDesigner")
			if SettingsDesigner and SettingsDesigner.RefreshFriendsUIAvailability then
				SettingsDesigner:RefreshFriendsUIAvailability()
			end
		end, 10)
	end)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if self.pendingStyle then
			self:ApplyEffectiveStyle("combat-ended")
		end
	end, 10)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", function()
		self:RefreshRequests(false)
	end, 20)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_ADDED", function()
		self:RefreshRequests(true)
	end, 20)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_REMOVED", function()
		self:RefreshRequests(false)
	end, 20)
	BFL:RegisterEventCallback("BN_INFO_CHANGED", function()
		self:RefreshBattleTag()
	end, 20)
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function()
		self:RefreshNavigation()
	end, 80)
	if EventRegistry and EventRegistry.RegisterCallback and not self.textScaleCallbackRegistered then
		EventRegistry:RegisterCallback("TextSizeManager.OnTextScaleUpdated", self.OnTextScaleUpdated, self)
		self.textScaleCallbackRegistered = true
	end
	BFL:RegisterEventCallback("ADDON_LOADED", function(loadedAddOn)
		if loadedAddOn == "Blizzard_SocialUI" or loadedAddOn == "Blizzard_SocialUIShared" then
			self:InstallSocialUIRedirects()
		elseif loadedAddOn == "Blizzard_FriendsFrame" then
			self:InstallFriendsFriendsFrameHook()
		end
	end, 80)
	C_Timer.After(0, function()
		self:InstallTabHooks()
		self:EnsureSocialUIRedirects()
		self:InstallFriendsFriendsFrameHook()
		if BetterFriendsFrame then
			BetterFriendsFrame:HookScript("OnShow", function()
				self:RefreshEffectiveStyleOnShow()
			end)
		end
		self:ApplyEffectiveStyle("initialize")
	end)
end

function FriendsUI:OnPlayerLogin()
	if BFL.IsRetail then
		self:ApplyEffectiveStyle("player-login")
		self:RegisterTests()
	end
end
