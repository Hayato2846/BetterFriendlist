-- Modules/ThemePalette.lua
-- Resolves Dark and Custom theme color tokens for the BFL skin engine

local ADDON_NAME, BFL = ...
local ThemePalette = BFL:RegisterModule("ThemePalette", {})

local DEFAULT_DARK_SETTINGS = {
	accentColor = { r = 1.0, g = 0.82, b = 0.0, a = 1 },
	windowOpacity = 0.68,
	popupOpacity = 0.78,
	listOpacity = 0.42,
	controlOpacity = 0.42,
	hoverStrength = 0.10,
	selectionStrength = 0.14,
	borderStrength = 0.82,
	avatarVisibility = 1.0,
}

local DEFAULT_CUSTOM_SETTINGS = {
	accentColor = { r = 0.18, g = 0.88, b = 0.82, a = 1 },
	windowOpacity = 0.68,
	popupOpacity = 0.78,
	listOpacity = 0.42,
	controlOpacity = 0.42,
	hoverStrength = 0.10,
	selectionStrength = 0.14,
	borderStrength = 0.82,
	avatarVisibility = 1.0,
}

local THEME_SETTING_MIN = {
	windowOpacity = 0.15,
	popupOpacity = 0.15,
	listOpacity = 0.05,
	controlOpacity = 0.05,
}

local THEME_SETTING_DB_KEYS = {
	dark = "darkThemeSettings",
	custom = "customThemeSettings",
}

local THEME_SETTING_DEFAULTS = {
	dark = DEFAULT_DARK_SETTINGS,
	custom = DEFAULT_CUSTOM_SETTINGS,
}

local DEFAULT_BROKER_SEPARATOR_COLOR = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }

local BROKER_TOOLTIP_THEME_ORDER = {
	"blizzard",
	"dark",
	"custom",
	"elvui",
}

local BROKER_TOOLTIP_THEME_KEYS = {
	blizzard = true,
	dark = true,
	custom = true,
	elvui = true,
}

local CUSTOM_COLOR_KEYS = {
	backgroundColor = true,
	surfaceColor = true,
	insetColor = true,
	controlColor = true,
	borderColor = true,
	accentColor = true,
	textColor = true,
	disabledTextColor = true,
	hoverColor = true,
	selectedColor = true,
	scrollThumbColor = true,
	iconColor = true,
}

local function Clamp(value, minValue, maxValue)
	value = tonumber(value)
	if value == nil then
		return nil
	end
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function Copy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, child in pairs(value) do
		result[key] = Copy(child)
	end
	return result
end

local function CopyArray(color)
	if type(color) ~= "table" then
		return nil
	end
	return { color[1] or 1, color[2] or 1, color[3] or 1, color[4] ~= nil and color[4] or 1 }
end

local function NormalizeColor(color, fallback)
	if type(color) ~= "table" then
		return fallback and Copy(fallback) or nil
	end

	local r = Clamp(color.r ~= nil and color.r or color[1], 0, 1)
	local g = Clamp(color.g ~= nil and color.g or color[2], 0, 1)
	local b = Clamp(color.b ~= nil and color.b or color[3], 0, 1)
	local a = Clamp(color.a ~= nil and color.a or color[4], 0, 1)

	if fallback then
		r = r ~= nil and r or fallback.r or fallback[1] or 1
		g = g ~= nil and g or fallback.g or fallback[2] or 1
		b = b ~= nil and b or fallback.b or fallback[3] or 1
		a = a ~= nil and a or fallback.a or fallback[4] or 1
	end

	if r == nil or g == nil or b == nil then
		return fallback and Copy(fallback) or nil
	end

	return { r = r, g = g, b = b, a = a ~= nil and a or 1 }
end

local function ToArray(color, fallback)
	color = NormalizeColor(color, fallback)
	if not color then
		return fallback and CopyArray(fallback) or nil
	end
	return { color.r, color.g, color.b, color.a ~= nil and color.a or 1 }
end

local function WithAlpha(color, alpha)
	local result = CopyArray(color)
	if result then
		result[4] = Clamp(alpha, 0, 1) or result[4] or 1
	end
	return result
end

local function WithRGBAndAlpha(rgb, alpha)
	local result = ToArray(rgb)
	if result then
		result[4] = Clamp(alpha, 0, 1) or result[4] or 1
	end
	return result
end

local function ScaleAlpha(color, scale)
	local result = CopyArray(color)
	if result then
		result[4] = Clamp((result[4] or 1) * (scale or 1), 0, 1) or result[4]
	end
	return result
end

local function Lighten(color, amount)
	color = CopyArray(color)
	if not color then
		return nil
	end
	amount = Clamp(amount or 0, 0, 1) or 0
	color[1] = color[1] + (1 - color[1]) * amount
	color[2] = color[2] + (1 - color[2]) * amount
	color[3] = color[3] + (1 - color[3]) * amount
	return color
end

local function Darken(color, amount)
	color = CopyArray(color)
	if not color then
		return nil
	end
	amount = Clamp(amount or 0, 0, 1) or 0
	color[1] = color[1] * (1 - amount)
	color[2] = color[2] * (1 - amount)
	color[3] = color[3] * (1 - amount)
	return color
end

local function MixColor(color, target, amount)
	color = NormalizeColor(color, target)
	target = NormalizeColor(target, color)
	if not color or not target then
		return nil
	end

	amount = Clamp(amount or 0.5, 0, 1) or 0.5
	return {
		r = color.r + (target.r - color.r) * amount,
		g = color.g + (target.g - color.g) * amount,
		b = color.b + (target.b - color.b) * amount,
		a = color.a ~= nil and color.a or target.a or 1,
	}
end

function ThemePalette:GetDefaultDarkSettings()
	return Copy(DEFAULT_DARK_SETTINGS)
end

function ThemePalette:GetDefaultCustomSettings()
	return Copy(DEFAULT_CUSTOM_SETTINGS)
end

function ThemePalette:GetDefaultCustomTheme()
	return {}
end

function ThemePalette:GetDefaultBrokerSeparatorColor()
	return Copy(DEFAULT_BROKER_SEPARATOR_COLOR)
end

local function NormalizeThemeSettings(settings, defaults)
	settings = type(settings) == "table" and settings or {}
	local result = Copy(defaults)

	local legacyAvatarVisibility = settings.avatarVisibility
	if legacyAvatarVisibility == nil and settings.artworkVisibility ~= nil then
		legacyAvatarVisibility = settings.artworkVisibility
	end

	result.accentColor = NormalizeColor(settings.accentColor, defaults.accentColor)
	for key, defaultValue in pairs(defaults) do
		if key ~= "accentColor" then
			local value = key == "avatarVisibility" and legacyAvatarVisibility or settings[key]
			result[key] = Clamp(value, THEME_SETTING_MIN[key] or 0, 1)
			if result[key] == nil then
				result[key] = defaultValue
			end
		end
	end

	return result
end

function ThemePalette:NormalizeDarkSettings(settings)
	return NormalizeThemeSettings(settings, DEFAULT_DARK_SETTINGS)
end

function ThemePalette:NormalizeCustomSettings(settings)
	return NormalizeThemeSettings(settings, DEFAULT_CUSTOM_SETTINGS)
end

function ThemePalette:GetCustomSettingsInspiredByDark(settings)
	local dark = self:NormalizeDarkSettings(settings)
	local result = self:NormalizeCustomSettings(dark)
	result.accentColor = MixColor(dark.accentColor, DEFAULT_CUSTOM_SETTINGS.accentColor, 0.58)
	result.listOpacity = Clamp((dark.listOpacity or DEFAULT_CUSTOM_SETTINGS.listOpacity) + 0.03, 0.05, 1)
		or DEFAULT_CUSTOM_SETTINGS.listOpacity
	result.controlOpacity = Clamp((dark.controlOpacity or DEFAULT_CUSTOM_SETTINGS.controlOpacity) + 0.03, 0.05, 1)
		or DEFAULT_CUSTOM_SETTINGS.controlOpacity
	result.hoverStrength = Clamp((dark.hoverStrength or DEFAULT_CUSTOM_SETTINGS.hoverStrength) + 0.02, 0, 1)
		or DEFAULT_CUSTOM_SETTINGS.hoverStrength
	result.selectionStrength = Clamp((dark.selectionStrength or DEFAULT_CUSTOM_SETTINGS.selectionStrength) + 0.02, 0, 1)
		or DEFAULT_CUSTOM_SETTINGS.selectionStrength
	result.borderStrength = Clamp((dark.borderStrength or DEFAULT_CUSTOM_SETTINGS.borderStrength) - 0.05, 0, 1)
		or DEFAULT_CUSTOM_SETTINGS.borderStrength
	return result
end

function ThemePalette:NormalizeCustomTheme(customTheme)
	local result = {}
	if type(customTheme) ~= "table" then
		return result
	end

	for key in pairs(CUSTOM_COLOR_KEYS) do
		local color = NormalizeColor(customTheme[key])
		if color then
			result[key] = color
		end
	end

	return result
end

local function NormalizeBrokerTooltipTheme(theme)
	return BROKER_TOOLTIP_THEME_KEYS[theme] and theme or "blizzard"
end

function ThemePalette:NormalizeBrokerSeparatorColor(color)
	return NormalizeColor(color, DEFAULT_BROKER_SEPARATOR_COLOR)
end

function ThemePalette:GetDefaultBrokerTooltipThemeSettings()
	local result = {}
	for _, theme in ipairs(BROKER_TOOLTIP_THEME_ORDER) do
		result[theme] = {}
	end
	return result
end

function ThemePalette:NormalizeBrokerTooltipThemeSettings(settings)
	settings = type(settings) == "table" and settings or {}
	local result = self:GetDefaultBrokerTooltipThemeSettings()

	for _, theme in ipairs(BROKER_TOOLTIP_THEME_ORDER) do
		local source = type(settings[theme]) == "table" and settings[theme] or {}
		local normalized = result[theme]

		local backgroundColor = NormalizeColor(source.backgroundColor)
		if backgroundColor then
			normalized.backgroundColor = backgroundColor
		end

		local opacity = Clamp(source.opacity, 0, 1)
		if opacity ~= nil then
			normalized.opacity = opacity
		end
	end

	return result
end

function ThemePalette:NormalizeSavedSettings(db)
	if type(db) ~= "table" then
		return
	end

	db.darkThemeSettings = self:NormalizeDarkSettings(db.darkThemeSettings)
	db.customThemeSettings = self:NormalizeCustomSettings(db.customThemeSettings)
	db.blizzardThemeSettings = nil
	db.customTheme = self:NormalizeCustomTheme(db.customTheme)
	db.brokerSeparatorColor = self:NormalizeBrokerSeparatorColor(db.brokerSeparatorColor)
	db.brokerTooltipThemeSettings = self:NormalizeBrokerTooltipThemeSettings(db.brokerTooltipThemeSettings)
end

function ThemePalette:GetThemeSettings(theme)
	theme = THEME_SETTING_DB_KEYS[theme] and theme or "dark"
	local DB = BFL:GetModule("DB")
	local dbKey = THEME_SETTING_DB_KEYS[theme]
	local settings
	if DB and DB.Get then
		settings = DB:Get(dbKey)
	elseif BetterFriendlistDB then
		settings = BetterFriendlistDB[dbKey]
	end

	if theme == "custom" then
		return self:NormalizeCustomSettings(settings)
	end

	return self:NormalizeDarkSettings(settings)
end

function ThemePalette:GetDarkSettings()
	return self:GetThemeSettings("dark")
end

function ThemePalette:GetCustomSettings()
	return self:GetThemeSettings("custom")
end

function ThemePalette:GetCustomTheme()
	local DB = BFL:GetModule("DB")
	local customTheme
	if DB and DB.Get then
		customTheme = DB:Get("customTheme")
	elseif BetterFriendlistDB then
		customTheme = BetterFriendlistDB.customTheme
	end

	return self:NormalizeCustomTheme(customTheme)
end

function ThemePalette:GetBrokerTooltipThemeSettings(theme)
	theme = NormalizeBrokerTooltipTheme(theme)
	local DB = BFL:GetModule("DB")
	local settings
	if DB and DB.Get then
		settings = DB:Get("brokerTooltipThemeSettings")
	elseif BetterFriendlistDB then
		settings = BetterFriendlistDB.brokerTooltipThemeSettings
	end

	settings = self:NormalizeBrokerTooltipThemeSettings(settings)
	return Copy(settings[theme] or {})
end

function ThemePalette:SetBrokerTooltipThemeSetting(theme, key, value)
	theme = NormalizeBrokerTooltipTheme(theme)
	if key ~= "backgroundColor" and key ~= "opacity" then
		return
	end

	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local settings = self:NormalizeBrokerTooltipThemeSettings(DB:Get("brokerTooltipThemeSettings"))
	local themeSettings = settings[theme]
	if key == "backgroundColor" then
		themeSettings.backgroundColor = NormalizeColor(value)
	else
		themeSettings.opacity = Clamp(value, 0, 1)
	end
	DB:Set("brokerTooltipThemeSettings", settings)
end

function ThemePalette:ResetBrokerTooltipThemeSettings(theme)
	theme = NormalizeBrokerTooltipTheme(theme)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local settings = self:NormalizeBrokerTooltipThemeSettings(DB:Get("brokerTooltipThemeSettings"))
	settings[theme] = {}
	DB:Set("brokerTooltipThemeSettings", settings)
end

function ThemePalette:SetThemeSetting(theme, key, value)
	if not THEME_SETTING_DB_KEYS[theme] then
		return
	end
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local defaults = THEME_SETTING_DEFAULTS[theme] or DEFAULT_DARK_SETTINGS
	local settings = self:GetThemeSettings(theme)
	if key == "accentColor" then
		settings[key] = NormalizeColor(value, defaults.accentColor)
	elseif defaults[key] ~= nil then
		settings[key] = Clamp(value, 0, 1) or defaults[key]
	end
	DB:Set(THEME_SETTING_DB_KEYS[theme], settings)
end

function ThemePalette:SetDarkSetting(key, value)
	self:SetThemeSetting("dark", key, value)
end

function ThemePalette:SetCustomSetting(key, value)
	self:SetThemeSetting("custom", key, value)
end

function ThemePalette:SetCustomColor(key, color)
	if not CUSTOM_COLOR_KEYS[key] then
		return
	end

	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local customTheme = self:GetCustomTheme()
	local normalized = NormalizeColor(color)
	if normalized then
		customTheme[key] = normalized
	else
		customTheme[key] = nil
	end
	DB:Set("customTheme", customTheme)
end

function ThemePalette:ResetDarkSettings()
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("darkThemeSettings", self:GetDefaultDarkSettings())
	end
end

function ThemePalette:ResetCustomSettings()
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("customThemeSettings", self:GetDefaultCustomSettings())
	end
end

function ThemePalette:ResetCustomTheme()
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("customTheme", {})
	end
end

function ThemePalette:GetCustomColor(key, fallback)
	local customTheme = self:GetCustomTheme()
	return ToArray(customTheme[key], fallback)
end

function ThemePalette:GetResolvedCustomColor(key, fallback)
	return self:GetCustomColor(key, fallback)
end

function ThemePalette:GetArtworkAlpha(defaultAlpha)
	return defaultAlpha or 0
end

function ThemePalette:GetAvatarVisibility(theme)
	theme = theme or (BFL.GetEffectiveTheme and BFL:GetEffectiveTheme()) or "blizzard"
	if theme == "blizzard" then
		return 1
	end
	local settings = self:GetThemeSettings(theme)
	return settings.avatarVisibility or 1
end

function ThemePalette:GetAvatarAlpha(defaultAlpha, theme)
	return (defaultAlpha or 1) * self:GetAvatarVisibility(theme)
end

local function IsSimpleModeEnabled()
	local DB = BFL and BFL.GetModule and BFL:GetModule("DB")
	if DB and DB.Get then
		return DB:Get("simpleMode", false) == true
	end
	return BetterFriendlistDB and BetterFriendlistDB.simpleMode == true
end

local function SetObjectShown(object, shown)
	if not object then
		return
	end
	if object.SetShown then
		object:SetShown(shown == true)
	elseif shown and object.Show then
		object:Show()
	elseif not shown and object.Hide then
		object:Hide()
	end
end

function ThemePalette:ApplyAvatarVisibility(frame)
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	if theme ~= "blizzard" then
		return
	end

	frame = frame or _G.BetterFriendsFrame
	if not frame then
		return
	end

	local alpha = self:GetAvatarAlpha(1, "blizzard")
	local showAvatar = not IsSimpleModeEnabled() and alpha > 0

	for _, object in ipairs({
		frame.PortraitIcon,
		frame.PortraitMask,
		frame.PortraitButton,
	}) do
		if object then
			if object.SetAlpha then
				object:SetAlpha(alpha)
			end
			SetObjectShown(object, showAvatar)
		end
	end
end

function ThemePalette:ApplyToColors(colors, baseColors)
	if type(colors) ~= "table" or type(baseColors) ~= "table" then
		return
	end

	for key, value in pairs(baseColors) do
		colors[key] = CopyArray(value)
	end

	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	if theme ~= "dark" and theme ~= "custom" then
		return
	end
	local settings = self:GetThemeSettings(theme)

	local accent = ToArray(settings.accentColor, baseColors.accent)
	local accentAlpha = (accent and accent[4]) or 1
	colors.accent = WithAlpha(accent, 0.62 * accentAlpha)
	colors.accentSoft = WithAlpha(accent, 0.22 * accentAlpha)
	colors.accentState = WithAlpha(accent, settings.selectionStrength * accentAlpha)
	colors.gold = WithAlpha(accent, 0.90 * accentAlpha)
	colors.sliderThumb = WithAlpha(accent, 0.92 * accentAlpha)
	colors.scrollThumbHover = WithAlpha(Lighten(accent, 0.22), 0.62 * accentAlpha)
	colors.scrollThumbDown = WithAlpha(accent, 0.86 * accentAlpha)
	colors.icon = WithAlpha(accent, 0.90 * accentAlpha)
	colors.iconHover = WithAlpha(Lighten(accent, 0.35), 1)
	colors.iconDown = WithAlpha(Darken(accent, 0.18), 1)

	colors.panel = WithAlpha(colors.panel, settings.windowOpacity)
	colors.tab = WithAlpha(colors.tab, settings.windowOpacity)
	colors.tabHover = WithAlpha(colors.tabHover, math.min(1, settings.windowOpacity + settings.hoverStrength))
	colors.popup = WithAlpha(colors.popup, settings.popupOpacity)
	colors.inset = WithAlpha(colors.inset, settings.listOpacity)
	colors.scrollTrack = WithAlpha(colors.scrollTrack, math.max(settings.listOpacity, 0.12))
	colors.sliderTrack = WithAlpha(colors.sliderTrack, settings.controlOpacity)
	colors.control = WithAlpha(colors.control, settings.controlOpacity)
	colors.controlHover = WithAlpha(colors.controlHover, math.max(settings.controlOpacity, settings.hoverStrength))
	colors.controlDown = WithAlpha(colors.controlDown, math.max(settings.controlOpacity, settings.selectionStrength))
	colors.controlDisabled = WithAlpha(colors.controlDisabled, math.min(settings.controlOpacity, 0.34))
	colors.rowHover = WithAlpha(accent, settings.hoverStrength)
	colors.rowDown = WithAlpha(accent, settings.selectionStrength)
	colors.border = WithAlpha(colors.border, settings.borderStrength)
	colors.controlBorder = WithAlpha(colors.controlBorder, math.min(1, settings.borderStrength * 0.98))
	colors.controlBorderHover = WithAlpha(accent, math.min(1, settings.borderStrength * 0.64))
	colors.borderSoft = WithAlpha(colors.borderSoft, math.min(1, settings.borderStrength * 0.72))
	colors.borderMuted = WithAlpha(colors.borderMuted, math.min(1, settings.borderStrength * 0.46))
	colors.divider = WithAlpha(colors.divider, math.min(1, settings.borderStrength * 0.50))

	if theme ~= "custom" then
		return
	end

	local customTheme = self:GetCustomTheme()
	local background = ToArray(customTheme.backgroundColor)
	local surface = ToArray(customTheme.surfaceColor)
	local inset = ToArray(customTheme.insetColor)
	local control = ToArray(customTheme.controlColor)
	local border = ToArray(customTheme.borderColor)
	local customAccent = ToArray(customTheme.accentColor)
	local hover = ToArray(customTheme.hoverColor)
	local selected = ToArray(customTheme.selectedColor)
	local scrollThumb = ToArray(customTheme.scrollThumbColor)
	local icon = ToArray(customTheme.iconColor)

	if customAccent then
		accent = customAccent
		colors.accent = WithAlpha(accent, accent[4])
		colors.accentSoft = WithAlpha(accent, math.min(0.35, (accent[4] or 1) * 0.35))
		colors.accentState = WithAlpha(accent, settings.selectionStrength)
		colors.gold = WithAlpha(accent, math.max(0.45, accent[4] or 1))
		colors.sliderThumb = WithAlpha(accent, math.max(0.55, accent[4] or 1))
		colors.scrollThumbDown = WithAlpha(accent, math.max(0.50, accent[4] or 1))
		colors.controlBorderHover = WithAlpha(accent, math.min(1, settings.borderStrength * 0.64))
	end

	if background then
		colors.panel = WithRGBAndAlpha(background, settings.windowOpacity)
		colors.tab = WithRGBAndAlpha(background, settings.windowOpacity)
		colors.tabHover = WithRGBAndAlpha(background, math.min(1, settings.windowOpacity + settings.hoverStrength))
	end
	if surface then
		colors.panelSoft = WithRGBAndAlpha(surface, surface[4])
		colors.popup = WithRGBAndAlpha(surface, settings.popupOpacity)
	end
	if inset then
		colors.inset = WithRGBAndAlpha(inset, settings.listOpacity)
		colors.scrollTrack = WithRGBAndAlpha(inset, math.max(settings.listOpacity, 0.12))
		colors.sliderTrack = WithRGBAndAlpha(inset, settings.controlOpacity)
	end
	if control then
		colors.control = WithRGBAndAlpha(control, settings.controlOpacity)
		colors.controlHover = WithRGBAndAlpha(control, math.max(settings.controlOpacity, settings.hoverStrength))
		colors.controlDown = WithRGBAndAlpha(control, math.max(settings.controlOpacity, settings.selectionStrength))
		colors.controlDisabled = WithRGBAndAlpha(control, math.min(settings.controlOpacity, 0.34))
	end
	if border then
		colors.border = WithRGBAndAlpha(border, settings.borderStrength)
		colors.controlBorder = WithRGBAndAlpha(border, math.min(1, settings.borderStrength * 0.98))
		colors.borderSoft = WithRGBAndAlpha(border, math.min(1, settings.borderStrength * 0.72))
		colors.borderMuted = WithRGBAndAlpha(border, math.min(1, settings.borderStrength * 0.46))
		colors.divider = WithRGBAndAlpha(border, math.min(1, settings.borderStrength * 0.50))
	end
	if hover then
		colors.rowHover = WithRGBAndAlpha(hover, hover[4] or settings.hoverStrength)
		colors.controlHover = WithRGBAndAlpha(hover, math.max(hover[4] or 0, settings.hoverStrength))
		colors.tabHover = WithRGBAndAlpha(hover, math.max(hover[4] or 0, settings.hoverStrength))
	end
	if selected then
		colors.rowDown = WithRGBAndAlpha(selected, selected[4] or settings.selectionStrength)
		colors.controlDown = WithRGBAndAlpha(selected, math.max(selected[4] or 0, settings.selectionStrength))
		colors.accentState = WithRGBAndAlpha(selected, selected[4] or settings.selectionStrength)
	end
	if scrollThumb then
		colors.scrollThumb = WithRGBAndAlpha(scrollThumb, scrollThumb[4] or 0.78)
		colors.scrollThumbHover = WithAlpha(Lighten(scrollThumb, 0.28), math.max(0.55, scrollThumb[4] or 0.90))
		colors.scrollThumbDown = WithAlpha(customAccent or scrollThumb, math.max(0.50, scrollThumb[4] or 0.86))
	end
	if icon then
		colors.icon = WithRGBAndAlpha(icon, icon[4] or 0.90)
		colors.iconHover = WithAlpha(Lighten(icon, 0.35), math.max(0.55, icon[4] or 1))
		colors.iconDown = WithAlpha(Darken(icon, 0.18), math.max(0.55, icon[4] or 1))
	end

	local text = ToArray(customTheme.textColor)
	if text then
		colors.text = text
	end

	local disabledText = ToArray(customTheme.disabledTextColor)
	if disabledText then
		colors.disabledText = disabledText
	end
end

return ThemePalette
