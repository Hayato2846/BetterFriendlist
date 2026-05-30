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
	artworkVisibility = 1.0,
}

local DARK_SETTING_MIN = {
	windowOpacity = 0.15,
	popupOpacity = 0.15,
	listOpacity = 0.05,
	controlOpacity = 0.05,
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

function ThemePalette:GetDefaultDarkSettings()
	return Copy(DEFAULT_DARK_SETTINGS)
end

function ThemePalette:GetDefaultCustomTheme()
	return {}
end

function ThemePalette:NormalizeDarkSettings(settings)
	settings = type(settings) == "table" and settings or {}
	local result = Copy(DEFAULT_DARK_SETTINGS)

	result.accentColor = NormalizeColor(settings.accentColor, DEFAULT_DARK_SETTINGS.accentColor)
	for key, defaultValue in pairs(DEFAULT_DARK_SETTINGS) do
		if key ~= "accentColor" then
			result[key] = Clamp(settings[key], DARK_SETTING_MIN[key] or 0, 1)
			if result[key] == nil then
				result[key] = defaultValue
			end
		end
	end

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

function ThemePalette:NormalizeSavedSettings(db)
	if type(db) ~= "table" then
		return
	end

	db.darkThemeSettings = self:NormalizeDarkSettings(db.darkThemeSettings)
	db.customTheme = self:NormalizeCustomTheme(db.customTheme)
end

function ThemePalette:GetDarkSettings()
	local DB = BFL:GetModule("DB")
	local settings
	if DB and DB.Get then
		settings = DB:Get("darkThemeSettings")
	elseif BetterFriendlistDB then
		settings = BetterFriendlistDB.darkThemeSettings
	end

	return self:NormalizeDarkSettings(settings)
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

function ThemePalette:SetDarkSetting(key, value)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	local settings = self:GetDarkSettings()
	if key == "accentColor" then
		settings[key] = NormalizeColor(value, DEFAULT_DARK_SETTINGS.accentColor)
	elseif DEFAULT_DARK_SETTINGS[key] ~= nil then
		settings[key] = Clamp(value, 0, 1) or DEFAULT_DARK_SETTINGS[key]
	end
	DB:Set("darkThemeSettings", settings)
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
	local settings = self:GetDarkSettings()
	return (defaultAlpha or 0) * (settings.artworkVisibility or 1)
end

function ThemePalette:ApplyToColors(colors, baseColors)
	if type(colors) ~= "table" or type(baseColors) ~= "table" then
		return
	end

	for key, value in pairs(baseColors) do
		colors[key] = CopyArray(value)
	end

	local settings = self:GetDarkSettings()
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	if theme ~= "dark" and theme ~= "custom" then
		return
	end

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
