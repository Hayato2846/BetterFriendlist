-- Modules/SettingsDesigner.lua
-- LibSettingsDesigner integration for the modern BetterFriendlist settings center.

local ADDON_NAME, BFL = ...
local SettingsDesigner = BFL:RegisterModule("SettingsDesigner", {})

local L = BFL.L or _G.BFL_L or {}
local Designer = BFL.LibSettingsDesigner
local Config = Designer and Designer.Config
local ConfigUI = Designer and Designer.UI
local Components = BFL.SettingsComponents

local APP_ID = "BetterFriendlist"
local ASSET_ROOT = "Interface\\AddOns\\BetterFriendlist\\Libs\\LibSettingsDesigner\\Assets\\"
local SETTINGS_ICON_ROOT = "Interface\\AddOns\\BetterFriendlist\\Textures\\SettingsCenter\\"
local ADDON_ICON = SETTINGS_ICON_ROOT .. "avatar-transparent.tga"

local SETTINGS_ICON_TEXTURES = {
	["dashboard"] = ADDON_ICON,
	["bfl-avatar"] = ADDON_ICON,
	["bfl-friends"] = SETTINGS_ICON_ROOT .. "nav-friends.tga",
	["bfl-appearance"] = SETTINGS_ICON_ROOT .. "nav-appearance.tga",
	["bfl-groups"] = SETTINGS_ICON_ROOT .. "nav-groups.tga",
	["bfl-social"] = SETTINGS_ICON_ROOT .. "nav-social.tga",
	["bfl-broker-sync"] = SETTINGS_ICON_ROOT .. "nav-broker-sync.tga",
	["bfl-privacy"] = SETTINGS_ICON_ROOT .. "nav-privacy.tga",
	["bfl-advanced"] = SETTINGS_ICON_ROOT .. "nav-advanced.tga",
	["bfl-help"] = SETTINGS_ICON_ROOT .. "nav-help.tga",
	["bfl-friends-display"] = SETTINGS_ICON_ROOT .. "page-friends-display.tga",
	["bfl-friends-formatting"] = SETTINGS_ICON_ROOT .. "page-friends-formatting.tga",
	["bfl-friends-behavior"] = SETTINGS_ICON_ROOT .. "page-friends-behavior.tga",
	["bfl-appearance-theme"] = SETTINGS_ICON_ROOT .. "page-appearance-theme.tga",
	["bfl-appearance-fonts"] = SETTINGS_ICON_ROOT .. "page-appearance-fonts.tga",
	["bfl-appearance-frame"] = SETTINGS_ICON_ROOT .. "page-appearance-frame.tga",
	["bfl-groups-builtins"] = SETTINGS_ICON_ROOT .. "page-groups-builtins.tga",
	["bfl-groups-headers"] = SETTINGS_ICON_ROOT .. "page-groups-headers.tga",
	["bfl-groups-order"] = SETTINGS_ICON_ROOT .. "page-groups-order.tga",
	["bfl-social-who"] = SETTINGS_ICON_ROOT .. "page-social-who.tga",
	["bfl-social-raid"] = SETTINGS_ICON_ROOT .. "page-social-raid.tga",
	["bfl-social-auto-raid-assist"] = SETTINGS_ICON_ROOT .. "page-social-auto-raid-assist.tga",
	["bfl-social-guild"] = SETTINGS_ICON_ROOT .. "page-social-guild.tga",
	["bfl-broker-friends"] = SETTINGS_ICON_ROOT .. "page-broker-friends.tga",
	["bfl-broker-guild"] = SETTINGS_ICON_ROOT .. "page-broker-guild.tga",
	["bfl-broker-sync-page"] = SETTINGS_ICON_ROOT .. "page-broker-sync.tga",
	["bfl-privacy-streamer"] = SETTINGS_ICON_ROOT .. "page-privacy-streamer.tga",
	["bfl-privacy-whisper"] = SETTINGS_ICON_ROOT .. "page-privacy-whisper.tga",
	["bfl-advanced-tools"] = SETTINGS_ICON_ROOT .. "page-advanced-tools.tga",
	["bfl-advanced-beta"] = SETTINGS_ICON_ROOT .. "page-advanced-beta.tga",
	["bfl-help-page"] = SETTINGS_ICON_ROOT .. "page-help.tga",
	["bfl-stat-settings"] = SETTINGS_ICON_ROOT .. "stat-settings.tga",
	["bfl-stat-customized"] = SETTINGS_ICON_ROOT .. "stat-customized.tga",
	["bfl-stat-enabled"] = SETTINGS_ICON_ROOT .. "stat-enabled.tga",
	["bfl-stat-new"] = ADDON_ICON,
}

local SETTINGS_CATEGORY_ICON_TEXTURES = {
	friends = SETTINGS_ICON_TEXTURES["bfl-friends"],
	appearance = SETTINGS_ICON_TEXTURES["bfl-appearance"],
	groups = SETTINGS_ICON_TEXTURES["bfl-groups"],
	social = SETTINGS_ICON_TEXTURES["bfl-social"],
	broker = SETTINGS_ICON_TEXTURES["bfl-broker-sync"],
	privacy = SETTINGS_ICON_TEXTURES["bfl-privacy"],
	advanced = SETTINGS_ICON_TEXTURES["bfl-advanced"],
	help = SETTINGS_ICON_TEXTURES["bfl-help"],
}

local app
local REGISTERED_GROUP_TITLES = {}

local function LocaleValue(key)
	local locale = BFL.L or _G.BFL_L or L
	local value = locale and locale[key]
	if value == key then
		return nil
	end
	return value
end

local DesignerLocale = setmetatable({}, {
	__index = function(_, key)
		return LocaleValue(key)
	end,
})

local function T(key, fallback)
	local value = LocaleValue(key)
	if value ~= nil and value ~= "" then
		return value
	end
	return fallback or key
end

local function GetDBModule()
	return BFL and BFL:GetModule("DB")
end

local function GetProfile()
	if type(BetterFriendlistDB) ~= "table" then
		BetterFriendlistDB = {}
	end
	return BetterFriendlistDB
end

local function GetDB(key, default)
	local DB = GetDBModule()
	if DB and DB.Get then
		return DB:Get(key, default)
	end
	if type(BetterFriendlistDB) ~= "table" then
		return default
	end
	local db = BetterFriendlistDB
	if db[key] ~= nil then
		return db[key]
	end
	return default
end

local function BumpSettingsVersion()
	if BFL.SettingsVersion then
		BFL.SettingsVersion = BFL.SettingsVersion + 1
	end
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.InvalidateSettingsCache then
		FriendsList:InvalidateSettingsCache()
	end
end

local function SetDB(key, value, after)
	local DB = GetDBModule()
	if DB and DB.Set then
		DB:Set(key, value)
	else
		GetProfile()[key] = value
		BumpSettingsVersion()
	end
	if after then
		after(value)
	end
end

local function CallSettings(methodName, ...)
	local Settings = BFL:GetModule("Settings")
	if Settings and type(Settings[methodName]) == "function" then
		Settings[methodName](Settings, ...)
		return true
	end
	return false
end

local function SetViaSettings(key, value, methodName, after)
	if methodName and CallSettings(methodName, value) then
		if after then
			after(value)
		end
		return
	end
	SetDB(key, value, after)
end

local function RefreshFriends()
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.InvalidateSettingsCache then
		FriendsList:InvalidateSettingsCache()
	end
	if BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

local function RefreshGuild()
	local GuildFrame = BFL:GetModule("GuildFrame")
	if GuildFrame and GuildFrame.Refresh then
		GuildFrame:Refresh()
	end
	if CallSettings("RefreshGuildTabVisibility") then
		return
	end
	RefreshFriends()
end

local function RefreshBrokerTooltips()
	local Broker = BFL:GetModule("Broker")
	if Broker and Broker.RefreshTooltip then
		Broker:RefreshTooltip()
	end
	local GuildBroker = BFL:GetModule("GuildBroker")
	if GuildBroker and GuildBroker.RefreshTooltip then
		GuildBroker:RefreshTooltip()
	end
end

local function RefreshFonts()
	if BFL.ApplyTabFonts then
		BFL:ApplyTabFonts()
	end
	RefreshFriends()
end

local function RefreshFrameSize(width, height)
	local FrameSettings = BFL:GetModule("FrameSettings")
	if FrameSettings and FrameSettings.ApplySize then
		FrameSettings:ApplySize(width, height)
	else
		RefreshFriends()
	end
end

local function RefreshSkin()
	if SettingsDesigner and SettingsDesigner.ApplySkin then
		SettingsDesigner:ApplySkin("setting-change")
	end
end

local function GetAddOnVersion()
	local getter = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
	if getter then
		local ok, version = pcall(getter, ADDON_NAME, "Version")
		if ok and version then
			return version
		end
	end
	return BFL.Version or "Unknown"
end

local function SplitVersionBadge(version)
	version = tostring(version or "")
	local value, badge = version:match("^([^-]+)%-(.+)$")
	if value and badge then
		return value, badge
	end
	return version, nil
end

local function GetChangelogModule()
	return BFL:GetModule("Changelog")
end

local function GetChangelogInfoEntries()
	local Changelog = GetChangelogModule()
	if Changelog and type(Changelog.GetSettingsCenterEntries) == "function" then
		local entries = Changelog:GetSettingsCenterEntries(10)
		if type(entries) == "table" and #entries > 0 then
			return entries
		end
	end
	return {
		{ type = "text", text = T("SETTINGS_CENTER_CHANGELOG_EMPTY", "No release notes available.") },
	}
end

local function GetSupportLinks()
	local fallbackLinks = {
		{ id = "discord", url = "https://discord.gg/dpaV8vh3w3" },
		{ id = "github", url = "https://github.com/Hayato2846/BetterFriendlist/issues" },
		{ id = "kofi", url = "https://ko-fi.com/hayato2846" },
	}
	local Changelog = GetChangelogModule()
	local links = Changelog and type(Changelog.GetSupportLinks) == "function" and Changelog:GetSupportLinks() or fallbackLinks
	local labelKeys = {
		discord = { "SETTINGS_CENTER_SUPPORT_DISCORD", "Discord" },
		github = { "SETTINGS_CENTER_SUPPORT_GITHUB", "GitHub Issues" },
		kofi = { "SETTINGS_CENTER_SUPPORT_KOFI", "Ko-fi" },
	}
	local result = {}
	for _, link in ipairs(type(links) == "table" and links or fallbackLinks) do
		local id = tostring(link.id or "")
		local labelData = labelKeys[id] or { nil, link.label or id }
		result[#result + 1] = {
			id = id,
			url = link.url,
			label = labelData[1] and T(labelData[1], labelData[2]) or labelData[2],
		}
	end
	return result
end

local function ShowSupportURL(label, url)
	local Changelog = GetChangelogModule()
	if Changelog and type(Changelog.ShowCopyDialog) == "function" then
		Changelog:ShowCopyDialog(url, label)
		return
	end
	local editBoxWidth = 350
	StaticPopupDialogs["BFL_SETTINGS_CENTER_COPY_URL"] = {
		text = label or T("SETTINGS_CENTER_SUPPORT_COPY_LINKS", "Copy Links"),
		button1 = CLOSE or "Close",
		hasEditBox = true,
		editBoxWidth = editBoxWidth,
		OnShow = function(self)
			self.EditBox:SetText(url or "")
			self.EditBox:SetFocus()
			self.EditBox:HighlightText()
			if BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
				BFL.BrokerUtils.FixCopyStaticPopupLayout(self, editBoxWidth)
			end
		end,
		EditBoxOnEnterPressed = function(self)
			self:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	local dialog = StaticPopup_Show("BFL_SETTINGS_CENTER_COPY_URL")
	if dialog and BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
		BFL.BrokerUtils.FixCopyStaticPopupLayout(dialog, editBoxWidth)
	end
end

local function RestoreAfterExternalFrame(externalFrame)
	if SettingsDesigner.HideUntilExternalFrameHidden then
		SettingsDesigner:HideUntilExternalFrameHidden(externalFrame)
	end
end

local function CallSettingsDialog(methodName, frameKey, globalName)
	local Settings = BFL:GetModule("Settings")
	if not (Settings and type(Settings[methodName]) == "function") then
		return false
	end
	Settings[methodName](Settings)
	local externalFrame = (frameKey and Settings[frameKey]) or (globalName and _G[globalName])
	RestoreAfterExternalFrame(externalFrame)
	return true
end

local function ShowNoteCleanupFrame(methodName, globalName)
	local NoteCleanupWizard = BFL.NoteCleanupWizard
	if not (NoteCleanupWizard and type(NoteCleanupWizard[methodName]) == "function") then
		return false
	end
	NoteCleanupWizard[methodName](NoteCleanupWizard)
	RestoreAfterExternalFrame(globalName and _G[globalName])
	return true
end

local function GetWindowState()
	local db = GetProfile()
	if type(db.settingsCenterWindow) ~= "table" then
		db.settingsCenterWindow = { width = 1080, height = 700, locked = false, density = "compact" }
	end
	if db.settingsCenterWindow.density ~= "compact" and db.settingsCenterWindow.density ~= "comfortable" then
		db.settingsCenterWindow.density = "compact"
	end
	return db.settingsCenterWindow
end

local NEW_TAGS = {
	["advanced.beta"] = true,
	["appearance.theme"] = true,
	["broker.sync"] = true,
	["enableSettingsCenterBeta"] = true,
	["enableGuildTab"] = true,
	["externalMenuBridgeEnabled"] = true,
	["groups.order"] = true,
	["groups.quickfilter.editor"] = true,
	["privacy.whisper"] = true,
	["social.guild"] = true,
	["syncGroupsToNote"] = true,
	["taintFreeWhisper"] = true,
}

local function GetSeenNewTags()
	local db = GetProfile()
	if type(db.settingsCenterSeenNewTags) ~= "table" then
		db.settingsCenterSeenNewTags = {}
	end
	return db.settingsCenterSeenNewTags
end

local function IsNewTagActive(tagID)
	tagID = tostring(tagID or "")
	return NEW_TAGS[tagID] == true and GetSeenNewTags()[tagID] ~= true
end

local function MarkNewTagSeen(tagID)
	tagID = tostring(tagID or "")
	if tagID ~= "" and NEW_TAGS[tagID] == true then
		GetSeenNewTags()[tagID] = true
	end
end

local function MarkPageNewTagsSeen(page, pageApp)
	if not page then
		return
	end
	MarkNewTagSeen(page.newTagID)
	if pageApp and pageApp.GetPageControls then
		for _, control in ipairs(pageApp:GetPageControls(page) or {}) do
			MarkNewTagSeen(control.newTagID)
		end
	end
end

local function GetThemeOptions()
	local options = {
		blizzard = T("SETTINGS_THEME_BLIZZARD", "Blizzard"),
		dark = T("SETTINGS_THEME_DARK", "Dark"),
		custom = T("SETTINGS_THEME_CUSTOM", "Custom"),
	}
	local order = { "blizzard", "dark", "custom" }
	-- Dark and Custom are standard Theme page choices.
	-- They are listed directly instead of being injected by Beta Features.
	-- Theme tuning visibility follows the selected theme below.
	-- ElvUI remains conditional on the addon being loaded.
	if BFL.IsElvUIAvailable and BFL:IsElvUIAvailable() then
		options.elvui = T("SETTINGS_THEME_ELVUI", "ElvUI")
		order[#order + 1] = "elvui"
	end
	return options, order
end

local function GetFontOptions()
	local options = {
		["Friz Quadrata TT"] = "Friz Quadrata TT",
		["Arial Narrow"] = "Arial Narrow",
		["Skurri"] = "Skurri",
		["Morpheus"] = "Morpheus",
	}
	if _G.LibStub then
		local LSM = _G.LibStub("LibSharedMedia-3.0", true)
		if LSM and LSM.HashTable then
			local fonts = LSM:HashTable("font")
			if type(fonts) == "table" then
				for name in pairs(fonts) do
					options[name] = name
				end
			end
		end
	end
	local order = {}
	for name in pairs(options) do
		order[#order + 1] = name
	end
	table.sort(order)
	return options, order
end

local function GetFontFlagOptions()
	return {
		NONE = T("SETTINGS_FONT_OUTLINE_NONE", "None"),
		OUTLINE = T("SETTINGS_FONT_OUTLINE_NORMAL", "Outline"),
		THICKOUTLINE = T("SETTINGS_FONT_OUTLINE_THICK", "Thick Outline"),
		MONOCHROME = T("SETTINGS_FONT_OUTLINE_MONOCHROME", "Monochrome"),
		SLUG = T("SETTINGS_FONT_FLAG_SLUG", "Slug Rendering"),
	}, { "NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "SLUG" }
end

local function GetFontFlagSelection(key)
	local flags = GetDB(key, "")
	if BFL.FontManager and BFL.FontManager.GetFontFlagSet then
		local set = BFL.FontManager:GetFontFlagSet(flags)
		if next(set) == nil then
			set.NONE = true
		end
		return set
	end
	local selection = {}
	for token in tostring(flags or ""):gmatch("[^,]+") do
		token = token:gsub("^%s+", ""):gsub("%s+$", "")
		if token ~= "" and token ~= "NONE" then
			selection[token] = true
		end
	end
	if next(selection) == nil then
		selection.NONE = true
	end
	return selection
end

local function SetFontFlagSelection(key, value, selected)
	local selection = GetFontFlagSelection(key)
	selection.NONE = nil
	if value == "NONE" then
		selection = {}
	elseif selected then
		selection[value] = true
		if value == "OUTLINE" then
			selection.THICKOUTLINE = nil
		elseif value == "THICKOUTLINE" then
			selection.OUTLINE = nil
		end
	else
		selection[value] = nil
	end
	local flags = BFL.FontManager and BFL.FontManager.SerializeFontFlags
		and BFL.FontManager:SerializeFontFlags(selection)
		or ""
	SetDB(key, flags, RefreshFonts)
end

local function ColorValue(key, default)
	local color = GetDB(key, default)
	if type(color) ~= "table" then
		color = default or { r = 1, g = 1, b = 1, a = 1 }
	end
	return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

local function SetColorValue(key, r, g, b, a, after)
	SetDB(key, { r = r or 1, g = g or 1, b = b or 1, a = a or 1 }, after)
end

local function ClearDB(key, after)
	SetDB(key, nil, after)
end

local function CopyTable(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = CopyTable(child)
	end
	return result
end

local function AsColor(color, fallback)
	fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
	if type(color) ~= "table" then
		color = fallback
	end
	local r = color.r ~= nil and color.r or color[1]
	local g = color.g ~= nil and color.g or color[2]
	local b = color.b ~= nil and color.b or color[3]
	local a = color.a ~= nil and color.a or color[4]
	return r or fallback.r or fallback[1] or 1,
		g or fallback.g or fallback[2] or 1,
		b or fallback.b or fallback[3] or 1,
		a ~= nil and a or fallback.a or fallback[4] or 1
end

local function ToColorTable(r, g, b, a)
	return { r = r or 1, g = g or 1, b = b or 1, a = a ~= nil and a or 1 }
end

local function ToColorArray(r, g, b, a)
	return { r or 1, g or 1, b or 1, a ~= nil and a or 1 }
end

local function CopyColorArray(color, fallback, alpha)
	local r, g, b, a = AsColor(color, fallback)
	return { r, g, b, alpha ~= nil and alpha or a }
end

local function ColorWithAlpha(color, fallback, alpha)
	local r, g, b = AsColor(color, fallback)
	return { r, g, b, alpha }
end

local function BuildSettingsCenterColorMap(source)
	source = type(source) == "table" and source or {}
	local accent = source.accent or { 1.0, 0.82, 0.0, 0.9 }
	local panel = source.panel or { 0.035, 0.038, 0.043, 0.96 }
	local surface = source.surface or source.panelSoft or panel
	local inset = source.inset or panel
	local control = source.control or surface
	local controlHover = source.controlHover or source.rowHover or surface
	local rowHover = source.rowHover or controlHover
	local selected = source.selected or source.rowDown or source.accentState or accent
	local border = source.border or { 0.34, 0.34, 0.36, 0.82 }
	local borderSoft = source.borderSoft or border
	local borderMuted = source.borderMuted or borderSoft
	local borderHover = source.borderHover or source.controlBorderHover or accent
	local text = source.text or { 0.92, 0.92, 0.92, 1 }

	return {
		frameBg = CopyColorArray(panel, nil, 0.96),
		overlayTint = ColorWithAlpha(accent, nil, 0.50),
		topbarBg = CopyColorArray(surface, panel, 0.88),
		topbarBorder = CopyColorArray(borderSoft, border),
		contentBg = CopyColorArray(inset, panel, 0.82),
		sidebarBg = CopyColorArray(inset, panel, 0.72),
		panelBorder = CopyColorArray(borderSoft, border),
		cardBg = CopyColorArray(surface, panel, 0.74),
		cardBgHover = CopyColorArray(controlHover, surface, 0.82),
		cardBorder = CopyColorArray(borderMuted, border),
		cardBorderHover = CopyColorArray(borderHover, accent),
		dashboardCardBg = CopyColorArray(surface, panel, 0.72),
		dashboardCardBgHover = CopyColorArray(controlHover, surface, 0.82),
		dashboardCardBorder = CopyColorArray(borderMuted, border),
		detailSectionBg = CopyColorArray(inset, panel, 0.84),
		detailColumnBg = CopyColorArray(inset, panel, 0.76),
		detailColumnBorder = CopyColorArray(borderMuted, border),
		detailSectionBorder = CopyColorArray(borderSoft, border),
		detailSectionHeaderBg = CopyColorArray(surface, panel, 0.86),
		rowBg = CopyColorArray(control, surface, 0.52),
		rowBorder = CopyColorArray(borderMuted, border),
		rowHoverBg = CopyColorArray(rowHover, controlHover, 0.62),
		rowHoverBorder = CopyColorArray(borderHover, accent),
		rowSeparator = CopyColorArray(source.divider or borderMuted, borderMuted),
		selectedBg = CopyColorArray(selected, accent, 0.22),
		buttonBg = CopyColorArray(control, surface, 0.72),
		buttonBorder = CopyColorArray(source.controlBorder or borderSoft, borderSoft),
		buttonHoverBg = CopyColorArray(controlHover, surface, 0.84),
		buttonHoverBorder = CopyColorArray(borderHover, accent),
		buttonTopbarBg = CopyColorArray(control, surface, 0.70),
		buttonTopbarBorder = CopyColorArray(source.controlBorder or borderSoft, borderSoft),
		buttonTopbarHoverBg = CopyColorArray(controlHover, surface, 0.84),
		searchBg = CopyColorArray(inset, panel, 0.82),
		searchBorder = CopyColorArray(source.controlBorder or borderSoft, borderSoft),
		disabledControlBg = CopyColorArray(source.controlDisabled or control, control, 0.34),
		disabledControlBorder = CopyColorArray(source.controlBorderDisabled or borderMuted, borderMuted),
		disabledRowBg = CopyColorArray(source.controlDisabled or control, control, 0.30),
		disabledRowBorder = CopyColorArray(borderMuted, border),
		textMain = CopyColorArray(text),
		textMuted = ColorWithAlpha(text, nil, 0.74),
		textSubtle = ColorWithAlpha(text, nil, 0.56),
		textDisabled = CopyColorArray(source.disabledText or text, text),
		accent = CopyColorArray(accent),
		topbarAccent = CopyColorArray(accent),
		success = CopyColorArray(source.success or { 0.36, 0.82, 0.36, 1 }),
	}
end

local function GetBlizzardSettingsCenterColors()
	return BuildSettingsCenterColorMap({
		accent = { 1.00, 0.82, 0.00, 1 },
		panel = { 0.035, 0.038, 0.043, 0.96 },
		surface = { 0.075, 0.082, 0.086, 0.92 },
		inset = { 0.030, 0.034, 0.038, 0.72 },
		control = { 0.070, 0.065, 0.055, 0.92 },
		controlHover = { 0.125, 0.100, 0.055, 0.96 },
		rowHover = { 0.125, 0.100, 0.055, 0.60 },
		selected = { 0.150, 0.115, 0.055, 0.98 },
		border = { 0.58, 0.49, 0.32, 0.48 },
		borderSoft = { 0.52, 0.39, 0.19, 0.52 },
		borderMuted = { 0.42, 0.34, 0.20, 0.24 },
		borderHover = { 0.95, 0.72, 0.30, 0.80 },
		text = { 0.94, 0.91, 0.84, 1 },
		disabledText = { 0.38, 0.36, 0.33, 1 },
	})
end

local function GetElvUISettingsCenterColors()
	local E = BFL.GetElvUIEngine and BFL:GetElvUIEngine(false)
	local media = type(E) == "table" and type(E.media) == "table" and E.media or {}
	local backdrop = media.backdropfadecolor or media.backdropcolor or { 0.06, 0.06, 0.06, 0.94 }
	local surface = media.backdropcolor or backdrop
	local border = media.bordercolor or { 0.31, 0.31, 0.31, 1 }
	local accent = media.rgbvaluecolor or media.valuecolor or { 0.09, 0.74, 0.82, 1 }
	local text = media.normalFontColor or { 0.86, 0.86, 0.86, 1 }

	return BuildSettingsCenterColorMap({
		accent = accent,
		panel = backdrop,
		surface = surface,
		inset = backdrop,
		control = surface,
		controlHover = ColorWithAlpha(accent, nil, 0.18),
		rowHover = ColorWithAlpha(accent, nil, 0.16),
		selected = ColorWithAlpha(accent, nil, 0.22),
		border = border,
		borderSoft = border,
		borderMuted = ColorWithAlpha(border, nil, 0.50),
		borderHover = accent,
		controlBorder = border,
		text = text,
		disabledText = { 0.45, 0.45, 0.45, 0.85 },
		success = { 0.36, 0.82, 0.36, 1 },
	})
end

local function GetBFLThemeSettingsCenterColors()
	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.RefreshThemeColors then
		pcall(SkinEngine.RefreshThemeColors, SkinEngine)
	end
	local colors = SkinEngine and SkinEngine.colors
	if type(colors) ~= "table" then
		return GetBlizzardSettingsCenterColors()
	end

	return BuildSettingsCenterColorMap({
		accent = colors.gold or colors.accent,
		panel = colors.panel,
		surface = colors.panelSoft,
		inset = colors.inset,
		control = colors.control,
		controlHover = colors.controlHover,
		rowHover = colors.rowHover,
		selected = colors.rowDown or colors.accentState,
		border = colors.border,
		borderSoft = colors.borderSoft,
		borderMuted = colors.borderMuted,
		borderHover = colors.controlBorderHover,
		controlBorder = colors.controlBorder,
		controlDisabled = colors.controlDisabled,
		controlBorderDisabled = colors.controlBorderDisabled,
		divider = colors.divider,
		text = colors.text,
		disabledText = colors.disabledText,
	})
end

local function GetSettingsCenterThemeColors()
	local currentTheme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or GetDB("theme", "blizzard")
	local elvUIAvailable = BFL.IsElvUIAvailable and BFL:IsElvUIAvailable()
	if elvUIAvailable and (currentTheme == "elvui" or GetDB("enableElvUISkin", false) == true) then
		return GetElvUISettingsCenterColors()
	elseif currentTheme == "dark" or currentTheme == "custom" then
		return GetBFLThemeSettingsCenterColors()
	end
	return GetBlizzardSettingsCenterColors()
end

local function RefreshGroups()
	local Groups = BFL:GetModule("Groups")
	if Groups and Groups.Initialize then
		Groups:Initialize()
	end
	RefreshFriends()
end

local function RefreshRaidButtons()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if RaidFrame and RaidFrame.UpdateAllMemberButtons then
		RaidFrame:UpdateAllMemberButtons()
	end
end

local function RefreshBrokerDisplays()
	local Broker = BFL:GetModule("Broker")
	if Broker then
		if Broker.UpdateText then
			Broker:UpdateText()
		elseif Broker.UpdateBrokerText then
			Broker:UpdateBrokerText()
		end
		if Broker.RefreshTooltip then
			Broker:RefreshTooltip()
		end
	end
	local GuildBroker = BFL:GetModule("GuildBroker")
	if GuildBroker then
		if GuildBroker.UpdateText then
			GuildBroker:UpdateText()
		elseif GuildBroker.UpdateBrokerText then
			GuildBroker:UpdateBrokerText()
		end
		if GuildBroker.RefreshTooltip then
			GuildBroker:RefreshTooltip()
		end
	end
end

local function ApplyThemeChange()
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme("settings-designer")
	end
	RefreshSkin()
	RefreshBrokerDisplays()
end

local THEME_SETTING_LABELS = {
	accentColor = { "SETTINGS_THEME_ACCENT_COLOR", "Accent Color" },
	windowOpacity = { "SETTINGS_THEME_WINDOW_OPACITY", "Window Opacity" },
	popupOpacity = { "SETTINGS_THEME_POPUP_OPACITY", "Popup Opacity" },
	listOpacity = { "SETTINGS_THEME_LIST_OPACITY", "List Opacity" },
	controlOpacity = { "SETTINGS_THEME_CONTROL_OPACITY", "Control Opacity" },
	hoverStrength = { "SETTINGS_THEME_HOVER_STRENGTH", "Hover Strength" },
	selectionStrength = { "SETTINGS_THEME_SELECTION_STRENGTH", "Selection Strength" },
	borderStrength = { "SETTINGS_THEME_BORDER_STRENGTH", "Border Strength" },
	avatarVisibility = { "SETTINGS_THEME_AVATAR_VISIBILITY", "Avatar Visibility" },
}

local THEME_SLIDER_MIN = {
	windowOpacity = 0.15,
	popupOpacity = 0.15,
	listOpacity = 0.05,
	controlOpacity = 0.05,
}

local CUSTOM_COLOR_DEFINITIONS = {
	{ key = "backgroundColor", labelKey = "SETTINGS_THEME_CUSTOM_BACKGROUND", label = "Background", token = "panel" },
	{ key = "surfaceColor", labelKey = "SETTINGS_THEME_CUSTOM_SURFACE", label = "Surface", token = "panelSoft" },
	{ key = "insetColor", labelKey = "SETTINGS_THEME_CUSTOM_INSET", label = "Inset & List", token = "inset" },
	{ key = "controlColor", labelKey = "SETTINGS_THEME_CUSTOM_CONTROL", label = "Control", token = "control" },
	{ key = "borderColor", labelKey = "SETTINGS_THEME_CUSTOM_BORDER", label = "Border", token = "border" },
	{ key = "accentColor", labelKey = "SETTINGS_THEME_CUSTOM_ACCENT", label = "Accent", token = "accent" },
	{ key = "textColor", labelKey = "SETTINGS_THEME_CUSTOM_TEXT", label = "Control Text", token = "text" },
	{ key = "disabledTextColor", labelKey = "SETTINGS_THEME_CUSTOM_DISABLED_TEXT", label = "Disabled Text", token = "disabledText" },
	{ key = "hoverColor", labelKey = "SETTINGS_THEME_CUSTOM_HOVER", label = "Hover", token = "rowHover" },
	{ key = "selectedColor", labelKey = "SETTINGS_THEME_CUSTOM_SELECTED", label = "Selected & Pressed", token = "rowDown" },
	{ key = "scrollThumbColor", labelKey = "SETTINGS_THEME_CUSTOM_SCROLL_THUMB", label = "Scrollbar Thumb", token = "scrollThumb" },
	{ key = "iconColor", labelKey = "SETTINGS_THEME_CUSTOM_ICON", label = "Icon Tint", token = "icon" },
}

local FRIEND_BROKER_COLUMNS = {
	{ key = "Nickname", labelKey = "BROKER_COL_NICKNAME", fallback = "Nickname", default = false },
	{ key = "Name", labelKey = "BROKER_COL_NAME", fallback = "Name", default = true },
	{ key = "Status", labelKey = "BROKER_COL_STATUS", fallback = "Status", default = false },
	{ key = "Level", labelKey = "BROKER_COL_LEVEL", fallback = "Level", default = true },
	{ key = "Character", labelKey = "BROKER_COL_CHARACTER", fallback = "Character", default = true },
	{ key = "Game", labelKey = "BROKER_COL_GAME", fallback = "Game", default = true },
	{ key = "Zone", labelKey = "BROKER_COL_ZONE", fallback = "Zone", default = true },
	{ key = "Realm", labelKey = "BROKER_COL_REALM", fallback = "Realm", default = true },
	{ key = "Notes", labelKey = "BROKER_COL_NOTES", fallback = "Notes", default = true },
}

local GUILD_BROKER_COLUMNS = {
	{ key = "Nickname", labelKey = "GUILD_BROKER_COL_NICKNAME", fallback = "Nickname", default = false },
	{ key = "Name", labelKey = "GUILD_BROKER_COL_NAME", fallback = "Name", default = true },
	{ key = "Level", labelKey = "GUILD_BROKER_COL_LEVEL", fallback = "Level", default = true },
	{ key = "Class", labelKey = "GUILD_BROKER_COL_CLASS", fallback = "Class", default = true },
	{ key = "Professions", labelKey = "GUILD_BROKER_COL_PROFESSIONS", fallback = "Professions", default = false },
	{ key = "Rank", labelKey = "GUILD_BROKER_COL_RANK", fallback = "Rank", default = true },
	{ key = "Zone", labelKey = "GUILD_BROKER_COL_ZONE", fallback = "Zone", default = true },
	{ key = "Note", labelKey = "GUILD_BROKER_COL_NOTE", fallback = "Public Note", default = false },
	{ key = "OfficerNote", labelKey = "GUILD_BROKER_COL_OFFICER_NOTE", fallback = "Officer Note", default = false },
	{ key = "LastOnline", labelKey = "GUILD_BROKER_COL_LAST_ONLINE", fallback = "Last Online", default = true },
}

local BROKER_COLOR_ENTRIES = {
	{ key = "brokerNicknameColor", label = T("BROKER_SETTINGS_NICKNAME_COLOR", "Nickname Color") },
	{ key = "brokerCharacterColor", label = T("BROKER_SETTINGS_CHARACTER_COLOR", "Character Color") },
	{ key = "brokerZoneColor", label = T("BROKER_SETTINGS_ZONE_COLOR", "Zone Color") },
	{ key = "brokerRealmColor", label = T("BROKER_SETTINGS_REALM_COLOR", "Realm Color") },
	{ key = "brokerNotesColor", label = T("BROKER_SETTINGS_NOTES_COLOR", "Notes Color") },
}

local GUILD_BROKER_COLOR_ENTRIES = {
	{ key = "guildBrokerRankColor", label = T("GUILD_BROKER_SETTINGS_RANK_COLOR", "Rank Color") },
	{ key = "guildBrokerZoneColor", label = T("GUILD_BROKER_SETTINGS_ZONE_COLOR", "Zone Color") },
	{ key = "guildBrokerNoteColor", label = T("GUILD_BROKER_SETTINGS_NOTE_COLOR", "Public Note Color") },
	{ key = "guildBrokerOfficerNoteColor", label = T("GUILD_BROKER_SETTINGS_OFFICER_NOTE_COLOR", "Officer Note Color") },
}

local RAID_SHORTCUT_ACTIONS = {
	{ key = "mainTank", labelKey = "SETTINGS_RAID_ACTION_MAIN_TANK", fallback = "Set Main Tank", defaultModifier = "SHIFT", defaultButton = "RightButton" },
	{ key = "mainAssist", labelKey = "SETTINGS_RAID_ACTION_MAIN_ASSIST", fallback = "Set Main Assist", defaultModifier = "CTRL", defaultButton = "RightButton" },
	{ key = "lead", labelKey = "SETTINGS_RAID_ACTION_RAID_LEAD", fallback = "Set Raid Leader", defaultModifier = "ALT", defaultButton = "LeftButton" },
	{ key = "promote", labelKey = "SETTINGS_RAID_ACTION_PROMOTE", fallback = "Promote Assistant", defaultModifier = "ALT", defaultButton = "RightButton" },
}

local RAID_MODIFIERS = {
	NONE = T("SETTINGS_RAID_SHORTCUT_MOD_NONE", "No Modifier"),
	SHIFT = "Shift",
	CTRL = "Ctrl",
	ALT = "Alt",
	["SHIFT-CTRL"] = "Shift + Ctrl",
	["SHIFT-ALT"] = "Shift + Alt",
	["CTRL-ALT"] = "Ctrl + Alt",
}
local RAID_MODIFIER_ORDER = { "NONE", "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT" }
local RAID_BUTTONS = {
	LeftButton = T("SETTINGS_RAID_SHORTCUT_BUTTON_LEFT", "Left Button"),
	RightButton = T("SETTINGS_RAID_SHORTCUT_BUTTON_RIGHT", "Right Button"),
	Button3 = T("SETTINGS_RAID_SHORTCUT_BUTTON_MIDDLE", "Middle Button"),
	Button4 = T("SETTINGS_RAID_SHORTCUT_BUTTON_4", "Button 4"),
	Button5 = T("SETTINGS_RAID_SHORTCUT_BUTTON_5", "Button 5"),
}
local RAID_BUTTON_ORDER = { "LeftButton", "RightButton", "Button3", "Button4", "Button5" }

local function IsReservedRaidShortcut(modifier, button)
	modifier = modifier or "NONE"
	return (modifier == "NONE" and (button == "LeftButton" or button == "RightButton"))
		or (modifier == "CTRL" and button == "LeftButton")
end

local function GetRaidShortcut(actionKey)
	local shortcuts = GetDB("raidShortcuts", {})
	if type(shortcuts) ~= "table" then
		shortcuts = {}
	end
	if type(shortcuts[actionKey]) ~= "table" then
		shortcuts[actionKey] = {}
	end
	return shortcuts, shortcuts[actionKey]
end

local function GetRaidShortcutValue(action, field)
	local _, shortcut = GetRaidShortcut(action.key)
	local fallback = field == "modifier" and action.defaultModifier or action.defaultButton
	return shortcut[field] or fallback
end

local function SetRaidShortcutValue(action, field, value)
	local shortcuts, shortcut = GetRaidShortcut(action.key)
	shortcut[field] = value
	if IsReservedRaidShortcut(shortcut.modifier, shortcut.button) then
		if field == "modifier" then
			shortcut.button = "Button3"
		else
			shortcut.modifier = "SHIFT"
		end
	end
	SetDB("raidShortcuts", shortcuts, RefreshRaidButtons)
end

local function GetRaidModifierOptionsFor(action)
	local currentButton = GetRaidShortcutValue(action, "button")
	local options, order = {}, {}
	for _, modifier in ipairs(RAID_MODIFIER_ORDER) do
		if not IsReservedRaidShortcut(modifier, currentButton) then
			options[modifier] = RAID_MODIFIERS[modifier]
			order[#order + 1] = modifier
		end
	end
	return options, order
end

local function GetRaidButtonOptionsFor(action)
	local currentModifier = GetRaidShortcutValue(action, "modifier")
	local options, order = {}, {}
	for _, button in ipairs(RAID_BUTTON_ORDER) do
		if not IsReservedRaidShortcut(currentModifier, button) then
			options[button] = RAID_BUTTONS[button]
			order[#order + 1] = button
		end
	end
	return options, order
end

local function GetGroupLabel(groupId, groupInfo)
	if groupInfo and groupInfo.name then
		return groupInfo.name
	end
	if groupId == "favorites" then
		return T("GROUP_FAVORITES", "Favorites")
	elseif groupId == "nogroup" then
		return T("GROUP_NO_GROUP", "No Group")
	elseif groupId == "online" then
		return FRIENDS_LIST_ONLINE or "Online"
	elseif groupId == "offline" then
		return FRIENDS_LIST_OFFLINE or "Offline"
	end
	return tostring(groupId or "")
end

local function BuildGroupEntries()
	local Groups = BFL:GetModule("Groups")
	local allGroups = Groups and Groups.GetAll and Groups:GetAll() or {}
	local savedOrder = GetDB("groupOrder", {})
	local entries, seen = {}, {}
	local function addGroup(groupId)
		if groupId and not seen[groupId] and allGroups[groupId] then
			seen[groupId] = true
			entries[#entries + 1] = {
				id = groupId,
				key = groupId,
				label = GetGroupLabel(groupId, allGroups[groupId]),
				icon = SETTINGS_ICON_TEXTURES["bfl-groups-order"],
			}
		end
	end
	if type(savedOrder) == "table" then
		for _, groupId in ipairs(savedOrder) do
			addGroup(groupId)
		end
	end
	if allGroups.favorites then
		addGroup("favorites")
	end
	local customIds = {}
	for groupId, groupInfo in pairs(allGroups) do
		if not seen[groupId] and groupId ~= "nogroup" and groupId ~= "favorites" then
			customIds[#customIds + 1] = groupId
		end
	end
	table.sort(customIds, function(a, b)
		return GetGroupLabel(a, allGroups[a]) < GetGroupLabel(b, allGroups[b])
	end)
	for _, groupId in ipairs(customIds) do
		addGroup(groupId)
	end
	if allGroups.nogroup then
		addGroup("nogroup")
	end
	return entries
end

local function MoveGroupEntry(fromIndex, toIndex)
	local entries = BuildGroupEntries()
	local entry = table.remove(entries, fromIndex)
	if not entry then
		return
	end
	table.insert(entries, toIndex, entry)
	local order = {}
	for _, groupEntry in ipairs(entries) do
		order[#order + 1] = groupEntry.id
	end
	SetDB("groupOrder", order, RefreshGroups)
end

local function GetGroupColor(storageKey, groupId, fallback)
	local colors = GetDB(storageKey, {})
	local color = type(colors) == "table" and colors[groupId] or nil
	return AsColor(color, fallback or { r = 1, g = 0.82, b = 0, a = 1 })
end

local function SetGroupColor(storageKey, groupId, r, g, b, a)
	local colors = CopyTable(GetDB(storageKey, {})) or {}
	colors[groupId] = ToColorTable(r, g, b, a)
	SetDB(storageKey, colors, RefreshGroups)
end

local function ApplyCustomBackdrop(frame, bg, border)
	if not (frame and frame.SetBackdrop) then
		return
	end
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	local background = bg or { 0.020, 0.018, 0.014, 0.62 }
	local outline = border or { 0.45, 0.34, 0.12, 0.55 }
	frame:SetBackdropColor(background[1], background[2], background[3], background[4])
	frame:SetBackdropBorderColor(outline[1], outline[2], outline[3], outline[4])
end

local function SetFontStringColor(fontString, r, g, b, a)
	if fontString and fontString.SetTextColor then
		fontString:SetTextColor(r or 1, g or 0.82, b or 0, a or 1)
	end
end

local function GetThemeAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

local function CreateFlatActionButton(parent, text, width, height)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 64, height or 24)
	ApplyCustomBackdrop(button, { 0.030, 0.026, 0.018, 0.90 }, { 0.48, 0.34, 0.10, 0.72 })
	button.Text = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormalSmall")
	button.Text:SetPoint("LEFT", button, "LEFT", 8, 0)
	button.Text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
	button.Text:SetJustifyH("CENTER")
	button.Text:SetWordWrap(false)
	button.Text:SetText(text or "")
	button:SetScript("OnEnter", function(owner)
		ApplyCustomBackdrop(owner, { 0.085, 0.070, 0.035, 0.95 }, { 0.92, 0.72, 0.20, 0.95 })
		SetFontStringColor(owner.Text, 1, 0.92, 0.45, 1)
	end)
	button:SetScript("OnLeave", function(owner)
		ApplyCustomBackdrop(owner, { 0.030, 0.026, 0.018, 0.90 }, { 0.48, 0.34, 0.10, 0.72 })
		SetFontStringColor(owner.Text, 1, 0.82, 0, 1)
	end)
	return button
end

local function SetSettingsTooltip(owner, title, text)
	if not owner then
		return
	end
	owner:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title or "", 1, 0.82, 0)
		if text and text ~= "" then
			GameTooltip:AddLine(text, 0.82, 0.78, 0.68, true)
		end
		GameTooltip:Show()
	end)
	owner:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function OpenGroupColorPicker(storageKey, groupId, swatch)
	local r, g, b, a = GetGroupColor(storageKey, groupId)
	local function Update(r, g, b, nextA)
		local alpha = nextA ~= nil and nextA or a or 1
		SetGroupColor(storageKey, groupId, r, g, b, alpha)
		if swatch and swatch.Color then
			swatch.Color:SetColorTexture(r, g, b, alpha)
		end
	end
	if BFL.ShowColorPicker then
		BFL.ShowColorPicker(r, g, b, a, Update)
	end
end

local function CreateGroupColorSwatch(parent, storageKey, groupId, label)
	local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
	swatch:SetSize(30, 22)
	ApplyCustomBackdrop(swatch, { 0.010, 0.010, 0.010, 0.90 }, { 0.28, 0.22, 0.10, 0.70 })
	swatch.Color = swatch:CreateTexture(nil, "ARTWORK")
	swatch.Color:SetPoint("TOPLEFT", swatch, "TOPLEFT", 3, -3)
	swatch.Color:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -3, 3)
	local r, g, b, a = GetGroupColor(storageKey, groupId)
	swatch.Color:SetColorTexture(r, g, b, a or 1)
	swatch:SetScript("OnClick", function()
		OpenGroupColorPicker(storageKey, groupId, swatch)
	end)
	SetSettingsTooltip(swatch, label, T("SETTINGS_CENTER_GROUP_COLOR_SWATCH_DESC", "Click to change this color."))
	return swatch
end

local bflDropdownCounter = 0

local function BuildDropdownEntries(options, order)
	local labels, values = {}, {}
	options = type(options) == "table" and options or {}
	order = type(order) == "table" and order or nil
	local seen = {}
	if order then
		for _, value in ipairs(order) do
			if options[value] ~= nil then
				labels[#labels + 1] = tostring(options[value])
				values[#values + 1] = value
				seen[value] = true
			end
		end
	end
	for value, label in pairs(options) do
		if not seen[value] then
			labels[#labels + 1] = tostring(label)
			values[#values + 1] = value
		end
	end
	return { labels = labels, values = values }
end

local function GetDropdownLabel(entries, value)
	for index, entryValue in ipairs(entries.values or {}) do
		if entryValue == value then
			return entries.labels and entries.labels[index] or tostring(value or "")
		end
	end
	return entries.labels and entries.labels[1] or tostring(value or "")
end

local function CreateSettingsDropdown(parent, entries, selectedValue, onSelectionCallback, width)
	width = width or 260
	entries = entries or { labels = {}, values = {} }
	local dropdown

	local function UpdateText(value)
		local text = GetDropdownLabel(entries, value)
		BFL.SetDropdownText(dropdown, text)
	end

	dropdown = Components and Components.CreateModernDropdown
		and Components:CreateModernDropdown(parent, width, "BetterFriendlistFontHighlightSmall")
		or nil
	if not dropdown then
		bflDropdownCounter = bflDropdownCounter + 1
		local dropdownName = "BFLSettingsCenterDropdown" .. tostring(bflDropdownCounter)
		if BFL.CreateDropdown then
			dropdown = BFL.CreateDropdown(parent, dropdownName, math.max(80, width - 30), { forceLegacy = true })
		else
			dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
		end
		dropdown:SetSize(width + 24, 24)
		BFL.InitializeDropdown(dropdown, {
			labels = entries.labels or {},
			values = entries.values or {},
			getSelectionText = function(value)
				return GetDropdownLabel(entries, value)
			end,
		}, function(value)
			return selectedValue == value
		end, function(value)
			selectedValue = value
			if onSelectionCallback then
				onSelectionCallback(value)
			end
			UpdateText(value)
		end)
		BFL.SetDropdownWidth(dropdown, math.max(80, width - 30))
		BFL.JustifyDropdownText(dropdown, "LEFT")
	else
		BFL.InitializeDropdown(dropdown, {
			labels = entries.labels or {},
			values = entries.values or {},
			getSelectionText = function(value)
				return GetDropdownLabel(entries, value)
			end,
		}, function(value)
			return selectedValue == value
		end, function(value)
			selectedValue = value
			if onSelectionCallback then
				onSelectionCallback(value)
			end
			UpdateText(value)
		end, 300)
	end

	UpdateText(selectedValue)
	return dropdown
end

local function RefreshSettingsCenter(state)
	if state and state.RenderContent then
		state:RenderContent()
	end
end

local function GetGroupOrderPageHeight()
	local count = #BuildGroupEntries()
	return 92 + (math.max(count, 1) * 34)
end

local function RenderGroupOrderCustomPage(parent, _, _, state)
	if not parent then
		return nil
	end
	local frames = {}
	local entryRows = {}
	local entries = BuildGroupEntries()
	local y = -14
	local draggingRow

	local function Track(frame)
		frames[#frames + 1] = frame
		return frame
	end

	local function SetGroupOrderRowBackdrop(row, mode)
		if not row then
			return
		end
		local alpha = (row.orderIndex or 0) % 2 == 0 and 0.48 or 0.66
		if mode == "target" then
			ApplyCustomBackdrop(row, { 0.095, 0.074, 0.025, 0.92 }, { 0.96, 0.74, 0.16, 0.96 })
		elseif mode == "hover" then
			ApplyCustomBackdrop(row, { 0.060, 0.050, 0.025, 0.76 }, { 0.68, 0.50, 0.14, 0.82 })
		else
			ApplyCustomBackdrop(row, { 0.026, 0.023, 0.018, alpha }, { 0.16, 0.13, 0.08, 0.48 })
		end
	end

	local function GetDropTargetIndex(activeRow)
		if not MouseIsOver then
			return nil
		end
		for _, row in ipairs(entryRows) do
			if row ~= activeRow and row:IsVisible() and MouseIsOver(row) then
				return row.orderIndex
			end
		end
		return nil
	end

	local function UpdateDropTargetHighlights(activeRow)
		for _, row in ipairs(entryRows) do
			if row ~= activeRow and row:IsVisible() then
				SetGroupOrderRowBackdrop(row, MouseIsOver and MouseIsOver(row) and "target" or nil)
			end
		end
	end

	local function StartGroupOrderDrag(row, label)
		if #entries <= 1 then
			return
		end
		draggingRow = row
		GameTooltip:Hide()
		row:SetAlpha(0.18)

		local ghost = BFL.GetDragGhost and BFL:GetDragGhost()
		if ghost then
			local accentR, accentG, accentB = GetThemeAccentColor(1, 0.82, 0)
			ghost.text:SetText(label or "")
			ghost.text:SetTextColor(accentR, accentG, accentB)
			ghost.stripe:SetColorTexture(accentR, accentG, accentB)
			ghost:SetSize(math.max(180, ghost.text:GetStringWidth() + 55), row:GetHeight())
			ghost:Show()

			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			ghost:ClearAllPoints()
			ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
			ghost:SetScript("OnUpdate", function(g)
				local cX, cY = GetCursorPosition()
				local s = UIParent:GetEffectiveScale()
				g:ClearAllPoints()
				g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cX / s, cY / s)
			end)
		end

		row:SetScript("OnUpdate", function(activeRow)
			UpdateDropTargetHighlights(activeRow)
		end)
	end

	local function StopGroupOrderDrag(row)
		local ghost = BFL.GetDragGhost and BFL:GetDragGhost()
		if ghost then
			ghost:Hide()
			ghost:SetScript("OnUpdate", nil)
			ghost:ClearAllPoints()
		end

		row:SetAlpha(1)
		row:SetScript("OnUpdate", nil)
		local targetIndex = GetDropTargetIndex(row)
		draggingRow = nil

		for _, entryRow in ipairs(entryRows) do
			SetGroupOrderRowBackdrop(entryRow)
		end

		if targetIndex and targetIndex ~= row.orderIndex then
			MoveGroupEntry(row.orderIndex, targetIndex)
			RefreshSettingsCenter(state)
		end
	end

	local function CreateSection(title, height)
		local section = Track(CreateFrame("Frame", nil, parent, "BackdropTemplate"))
		section:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
		section:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
		section:SetHeight(height)
		ApplyCustomBackdrop(section, { 0.010, 0.010, 0.010, 0.48 }, { 0.40, 0.30, 0.10, 0.52 })
		local header = section:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
		header:SetPoint("TOPLEFT", section, "TOPLEFT", 14, -12)
		header:SetPoint("RIGHT", section, "RIGHT", -14, 0)
		header:SetHeight(18)
		header:SetJustifyH("LEFT")
		header:SetText(title)
		y = y - height - 12
		return section
	end

	local sectionHeight = 58 + (math.max(#entries, 1) * 34)
	local orderSection = CreateSection(T("SETTINGS_GROUP_ORDER", "Group Order"), sectionHeight)
	local columns = {
		{ text = T("SETTINGS_GROUP_COLOR", "Group Color"), x = -260 },
		{ text = T("SETTINGS_GROUP_COUNT_COLOR", "Count Color"), x = -178 },
		{ text = T("SETTINGS_GROUP_ARROW_COLOR", "Arrow Color"), x = -96 },
	}
	for _, column in ipairs(columns) do
		local label = orderSection:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
		label:SetPoint("TOPRIGHT", orderSection, "TOPRIGHT", column.x + 24, -14)
		label:SetWidth(78)
		label:SetJustifyH("CENTER")
		label:SetText(column.text)
	end
	if #entries == 0 then
		local empty = orderSection:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
		empty:SetPoint("TOPLEFT", orderSection, "TOPLEFT", 14, -42)
		empty:SetText(T("SETTINGS_CENTER_GROUP_ORDER_EMPTY", "No groups available."))
	else
		for index, entry in ipairs(entries) do
			local row = Track(CreateFrame("Button", nil, orderSection, "BackdropTemplate"))
			entryRows[#entryRows + 1] = row
			row.orderIndex = index
			row.entryId = entry.id
			row:SetPoint("TOPLEFT", orderSection, "TOPLEFT", 12, -38 - ((index - 1) * 34))
			row:SetPoint("RIGHT", orderSection, "RIGHT", -12, 0)
			row:SetHeight(30)
			row:EnableMouse(true)
			row:RegisterForDrag("LeftButton")
			SetGroupOrderRowBackdrop(row)

			local dragHandle = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
			dragHandle:SetPoint("LEFT", row, "LEFT", 10, 0)
			dragHandle:SetWidth(18)
			dragHandle:SetJustifyH("CENTER")
			dragHandle:SetText(":::")
			dragHandle:SetTextColor(1, 0.82, 0, #entries > 1 and 0.75 or 0.28)

			local orderText = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
			orderText:SetPoint("LEFT", dragHandle, "RIGHT", 4, 0)
			orderText:SetWidth(26)
			orderText:SetJustifyH("RIGHT")
			orderText:SetText(index)

			local name = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlightSmall")
			name:SetPoint("LEFT", orderText, "RIGHT", 12, 0)
			name:SetPoint("RIGHT", row, "RIGHT", -340, 0)
			name:SetJustifyH("LEFT")
			name:SetWordWrap(false)
			name:SetText(entry.label or entry.id)

			local groupSwatch = CreateGroupColorSwatch(row, "groupColors", entry.id, T("SETTINGS_GROUP_COLOR", "Group Color"))
			groupSwatch:SetPoint("RIGHT", row, "RIGHT", -260, 0)
			local countSwatch = CreateGroupColorSwatch(row, "groupCountColors", entry.id, T("SETTINGS_GROUP_COUNT_COLOR", "Count Color"))
			countSwatch:SetPoint("RIGHT", row, "RIGHT", -178, 0)
			local arrowSwatch = CreateGroupColorSwatch(row, "groupArrowColors", entry.id, T("SETTINGS_GROUP_ARROW_COLOR", "Arrow Color"))
			arrowSwatch:SetPoint("RIGHT", row, "RIGHT", -96, 0)

			local up = CreateFlatActionButton(row, "^", 28, 22)
			up:SetPoint("RIGHT", row, "RIGHT", -16, 0)
			up:SetEnabled(index > 1)
			up:SetAlpha(index > 1 and 1 or 0.35)
			up:SetScript("OnClick", function()
				MoveGroupEntry(index, index - 1)
				RefreshSettingsCenter(state)
			end)

			local down = CreateFlatActionButton(row, "v", 28, 22)
			down:SetPoint("RIGHT", up, "LEFT", -6, 0)
			down:SetEnabled(index < #entries)
			down:SetAlpha(index < #entries and 1 or 0.35)
			down:SetScript("OnClick", function()
				MoveGroupEntry(index, index + 1)
				RefreshSettingsCenter(state)
			end)

			row:SetScript("OnDragStart", function(selfRow)
				StartGroupOrderDrag(selfRow, entry.label or entry.id)
			end)
			row:SetScript("OnDragStop", function(selfRow)
				StopGroupOrderDrag(selfRow)
			end)
			row:SetScript("OnEnter", function(selfRow)
				if not draggingRow then
					SetGroupOrderRowBackdrop(selfRow, "hover")
					GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
					GameTooltip:SetText(entry.label or "", 1, 0.82, 0)
					if entry.id and entry.id ~= "" then
						GameTooltip:AddLine(entry.id, 0.82, 0.78, 0.68, true)
					end
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function(selfRow)
				if not draggingRow then
					SetGroupOrderRowBackdrop(selfRow)
				end
				GameTooltip:Hide()
			end)
		end
	end

	return {
		Release = function()
			if draggingRow then
				local ghost = BFL.GetDragGhost and BFL:GetDragGhost()
				if ghost then
					ghost:Hide()
					ghost:SetScript("OnUpdate", nil)
					ghost:ClearAllPoints()
				end
				draggingRow = nil
			end
			for _, frame in ipairs(frames) do
				if frame.Hide then
					frame:Hide()
				end
				if frame.SetParent then
					frame:SetParent(nil)
				end
			end
		end,
	}
end

local function GetColumnLabel(column)
	return T(column.labelKey, column.fallback)
end

local function BuildColumnEntries(columns, orderKey, iconKey)
	local savedOrder = GetDB(orderKey, {})
	local columnByKey, seen, entries = {}, {}, {}
	for _, column in ipairs(columns) do
		columnByKey[column.key] = column
	end
	local function addColumn(key)
		local column = columnByKey[key]
		if column and not seen[key] then
			seen[key] = true
			entries[#entries + 1] = {
				id = key,
				key = key,
				label = GetColumnLabel(column),
				icon = SETTINGS_ICON_TEXTURES[iconKey] or SETTINGS_ICON_TEXTURES["bfl-broker-sync"],
			}
		end
	end
	if type(savedOrder) == "table" then
		for _, key in ipairs(savedOrder) do
			addColumn(key)
		end
	end
	for _, column in ipairs(columns) do
		addColumn(column.key)
	end
	return entries
end

local function MoveColumnEntry(columns, orderKey, fromIndex, toIndex)
	local entries = BuildColumnEntries(columns, orderKey)
	local entry = table.remove(entries, fromIndex)
	if not entry then
		return
	end
	table.insert(entries, toIndex, entry)
	local order = {}
	for _, column in ipairs(entries) do
		order[#order + 1] = column.id
	end
	SetDB(orderKey, order, RefreshBrokerDisplays)
end

local function GetColumnVisibilitySelection(columns, prefix)
	local selection = {}
	for _, column in ipairs(columns) do
		if GetDB(prefix .. column.key, column.default ~= false) == true then
			selection[column.key] = true
		end
	end
	return selection
end

local function SetColumnVisibility(columns, prefix, value, selected)
	for _, column in ipairs(columns) do
		if column.key == value then
			SetDB(prefix .. column.key, selected == true, RefreshBrokerDisplays)
			return
		end
	end
end

local function GetOptionalArrayColor(key, fallback)
	return AsColor(GetDB(key), fallback or { r = 1, g = 1, b = 1, a = 1 })
end

local function SetOptionalArrayColor(key, r, g, b, a)
	SetDB(key, ToColorArray(r, g, b, a), RefreshBrokerDisplays)
end

local function GetThemePalette()
	return BFL:GetModule("ThemePalette")
end

local function GetCustomColorFallback(key)
	local token
	for _, definition in ipairs(CUSTOM_COLOR_DEFINITIONS) do
		if definition.key == key then
			token = definition.token
			break
		end
	end
	local SkinEngine = BFL:GetModule("SkinEngine")
	local color = token and SkinEngine and SkinEngine.defaultColors and SkinEngine.defaultColors[token]
	return ToColorTable(AsColor(color, { r = 1, g = 0.82, b = 0, a = 1 }))
end

local function GetThemeSettings(theme)
	local ThemePalette = GetThemePalette()
	if ThemePalette and ThemePalette.GetThemeSettings then
		return ThemePalette:GetThemeSettings(theme) or {}
	end
	return GetDB(theme == "custom" and "customThemeSettings" or "darkThemeSettings", {})
end

local function GetThemeSetting(theme, key)
	local settings = GetThemeSettings(theme)
	return type(settings) == "table" and settings[key] or nil
end

local function SetThemeSetting(theme, key, value)
	local ThemePalette = GetThemePalette()
	if ThemePalette and ThemePalette.SetThemeSetting then
		ThemePalette:SetThemeSetting(theme, value ~= nil and key or key, value)
		ApplyThemeChange()
		return
	end
	local dbKey = theme == "custom" and "customThemeSettings" or "darkThemeSettings"
	local settings = CopyTable(GetDB(dbKey, {})) or {}
	settings[key] = value
	SetDB(dbKey, settings, ApplyThemeChange)
end

local function GetCustomThemeColor(key)
	local fallback = GetCustomColorFallback(key)
	local ThemePalette = GetThemePalette()
	if ThemePalette and ThemePalette.GetCustomColor then
		return AsColor(ThemePalette:GetCustomColor(key, fallback), fallback)
	end
	local customTheme = GetDB("customTheme", {})
	return AsColor(type(customTheme) == "table" and customTheme[key] or nil, fallback)
end

local function SetCustomThemeColor(key, r, g, b, a)
	local ThemePalette = GetThemePalette()
	if ThemePalette and ThemePalette.SetCustomColor then
		ThemePalette:SetCustomColor(key, ToColorTable(r, g, b, a))
		ApplyThemeChange()
		return
	end
	local customTheme = CopyTable(GetDB("customTheme", {})) or {}
	customTheme[key] = ToColorTable(r, g, b, a)
	SetDB("customTheme", customTheme, ApplyThemeChange)
end

local function RememberGroupTitle(pageID, groupID, title)
	if not (pageID and groupID and title) then
		return
	end
	REGISTERED_GROUP_TITLES[pageID] = REGISTERED_GROUP_TITLES[pageID] or {}
	REGISTERED_GROUP_TITLES[pageID][groupID] = title
end

local function GetGroupTitle(pageID, groupID)
	local pageGroups = pageID and REGISTERED_GROUP_TITLES[pageID]
	return pageGroups and groupID and pageGroups[groupID] or nil
end

local function AddGroup(pageID, id, title, order)
	RememberGroupTitle(pageID, id, title)
	app:RegisterGroup(pageID, { id = id, title = title, order = order })
end

local function RegisterPage(data)
	if data and data.newTagID and not data.onOpen then
		data.onOpen = MarkPageNewTagsSeen
	end
	app:RegisterPage(data)
end

local function AddToggle(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id or data.key,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "toggle",
		label = data.label,
		description = data.desc,
		default = data.default,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		refreshOnChange = data.refreshOnChange,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getValue = data.getValue,
		setValue = function(value)
			if data.setValue then
				data.setValue(value == true)
			else
				SetViaSettings(data.key, value == true, data.method, data.after)
			end
			if data.skinRefresh then
				RefreshSkin()
			end
		end,
	})
end

local function AddDropdown(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id or data.key,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = data.type or "dropdown",
		label = data.label,
		description = data.desc,
		list = data.list,
		listFunc = data.listFunc,
		orderList = data.orderList,
		default = data.default,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		refreshOnChange = data.refreshOnChange,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getValue = data.getValue,
		setValue = function(value)
			if data.setValue then
				data.setValue(value)
			else
				SetViaSettings(data.key, value, data.method, data.after)
			end
			if data.skinRefresh then
				RefreshSkin()
			end
		end,
	})
end

local function AddSlider(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id or data.key,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "slider",
		label = data.label,
		description = data.desc,
		min = data.min,
		max = data.max,
		step = data.step,
		default = data.default,
		formatter = data.formatter,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getValue = data.getValue,
		setValue = function(value)
			local numeric = tonumber(value) or data.default or data.min or 0
			if data.integer then
				numeric = math.floor(numeric + 0.5)
			end
			if data.setValue then
				data.setValue(numeric)
			else
				SetDB(data.key, numeric, data.after)
			end
			if data.skinRefresh then
				RefreshSkin()
			end
		end,
	})
end

local function AddInput(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id or data.key,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "input",
		label = data.label,
		description = data.desc,
		default = data.default,
		maxChars = data.maxChars,
		inputWidth = data.inputWidth,
		numeric = data.numeric,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getValue = data.getValue,
		setValue = function(value)
			if data.numeric then
				value = tonumber(value) or data.default or 0
			end
			if data.setValue then
				data.setValue(value)
			else
				SetDB(data.key, value, data.after)
			end
		end,
	})
end

local function AddColor(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id or data.key,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "colorpicker",
		label = data.label,
		description = data.desc,
		default = data.default,
		hasOpacity = data.hasOpacity,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getColor = data.getColor or function()
			return ColorValue(data.key, data.default)
		end,
		setColor = function(_, r, g, b, a)
			if data.setColor then
				data.setColor(r, g, b, a)
			else
				SetColorValue(data.key, r, g, b, a, data.after)
			end
			if data.skinRefresh then
				RefreshSkin()
			end
		end,
	})
end

local function AddMultiDropdown(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id,
		key = data.key,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "multidropdown",
		label = data.label,
		description = data.desc,
		options = data.options,
		list = data.list,
		listFunc = data.listFunc,
		orderList = data.orderList,
		default = data.default or {},
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getSelection = data.getSelection,
		setSelectedFunc = function(value, selected)
			if data.setSelectedFunc then
				data.setSelectedFunc(value, selected)
			end
			if data.after then
				data.after()
			end
		end,
	})
end

local function AddColorOverrides(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "colorpalette",
		label = data.label,
		description = data.desc,
		entries = data.entries,
		hasOpacity = data.hasOpacity,
		colorizeLabel = data.colorizeLabel,
		hasOverride = data.hasOverride,
		clearColor = data.clearColor,
		getInheritedColor = data.getInheritedColor,
		getDefaultColor = data.getDefaultColor,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		getColor = data.getColor,
		setColor = function(key, r, g, b, a)
			if data.setColor then
				data.setColor(key, r, g, b, a)
			end
			if data.skinRefresh then
				RefreshSkin()
			end
		end,
	})
end

local function AddReorderList(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "reorderlist",
		label = data.label,
		description = data.desc,
		getEntries = data.getEntries,
		moveEntry = data.moveEntry,
		removeEntry = data.removeEntry,
		addEntry = data.addEntry,
		showAddButton = data.showAddButton,
		showRemoveButton = data.showRemoveButton,
		showEntryID = data.showEntryID,
		entryToggle = data.entryToggle,
		rowActions = data.rowActions,
		addButtonText = data.addButtonText,
		addPopupTitle = data.addPopupTitle,
		addPopupText = data.addPopupText,
		emptyText = data.emptyText,
		formatOptions = data.formatOptions,
		formatOrder = data.formatOrder,
		setEntryFormat = data.setEntryFormat,
		order = data.order,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		trackCustomized = data.trackCustomized,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
	})
end

local function AddFontFlags(pageID, key, group, order, parentCheck)
	local list, orderList = GetFontFlagOptions()
	app:RegisterControl(pageID, {
		id = key,
		key = key,
		groupID = group,
		groupTitle = GetGroupTitle(pageID, group),
		type = "multidropdown",
		label = T("SETTINGS_FONT_FLAGS", "Font Flags:"),
		description = T(
			"SETTINGS_FONT_FLAGS_TOOLTIP",
			"Choose one or more rendering flags for this font. Slug is applied only on clients that support it."
		),
		options = list,
		orderList = orderList,
		default = { SLUG = true },
		order = order,
		parentCheck = parentCheck,
		getSelection = function()
			return GetFontFlagSelection(key)
		end,
		setSelectedFunc = function(value, selected)
			SetFontFlagSelection(key, value, selected)
		end,
	})
end

local function AddButton(pageID, data)
	app:RegisterControl(pageID, {
		id = data.id,
		groupID = data.group,
		groupTitle = data.groupTitle or GetGroupTitle(pageID, data.group),
		type = "button",
		label = data.label,
		description = data.desc,
		buttonText = data.buttonText or T("SETTINGS_CENTER_OPEN", "Open"),
		order = data.order,
		visibleWhen = data.visibleWhen,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		hiddenWhen = data.hiddenWhen,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		trackCustomized = false,
		requiresReload = data.requiresReload,
		reloadReason = data.reloadReason,
		onClick = data.onClick,
	})
end

local function OpenFilterSortEditorPage(kind, entryID, templateID)
	kind = kind == "sorter" and "sorter" or "filter"
	local focusID
	if templateID then
		focusID = "create-" .. kind .. ":" .. tostring(templateID)
	elseif entryID then
		focusID = kind .. ":" .. tostring(entryID)
	else
		focusID = "create-" .. kind
	end
	SettingsDesigner:Show("groups.quickfilter.entry", focusID)
end

local function OpenFilterSortManagerPage(kind)
	SettingsDesigner:Show("groups.quickfilter", kind == "sorter" and "sorter" or "filter")
end

local function RenderFilterSortOverviewPage(parent, _, _, state, focusID)
	local Settings = BFL:GetModule("Settings")
	if not Settings or not Settings.RenderFilterSortEditor then
		return nil
	end
	return Settings:RenderFilterSortEditor(parent, {
		focusID = focusID,
		anchorFrame = parent,
		inlineEditor = true,
		settingsCenter = true,
		viewMode = "overview",
		openEditorPage = OpenFilterSortEditorPage,
		openManagerPage = OpenFilterSortManagerPage,
		requestLayout = function()
			RefreshSettingsCenter(state)
		end,
	})
end

local function RenderFilterSortEntryPage(parent, _, _, state, focusID)
	local Settings = BFL:GetModule("Settings")
	if not Settings or not Settings.RenderFilterSortEditor then
		return nil
	end
	return Settings:RenderFilterSortEditor(parent, {
		focusID = focusID,
		anchorFrame = parent,
		inlineEditor = true,
		settingsCenter = true,
		viewMode = "editor",
		openEditorPage = OpenFilterSortEditorPage,
		openManagerPage = OpenFilterSortManagerPage,
		requestLayout = function()
			RefreshSettingsCenter(state)
		end,
	})
end

local function GetFilterSortCustomPageHeight()
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.GetFilterSortEditorPageHeight then
		return Settings:GetFilterSortEditorPageHeight()
	end
	return 840
end

local function GetFilterSortManagerSettingCount()
	local Registry = BFL:GetModule("FilterSortRegistry")
	if not Registry then
		return 0
	end
	local filterCount = #(Registry:GetQuickFilters(true) or {})
	local sorterCount = #(Registry:GetSorters(true) or {})
	return filterCount + sorterCount
end

local function RenderGlobalSyncCustomPage(parent, _, _, state, focusID)
	local Settings = BFL:GetModule("Settings")
	if not Settings or not Settings.RenderGlobalSyncEditor then
		return nil
	end
	return Settings:RenderGlobalSyncEditor(parent, {
		focusID = focusID,
		anchorFrame = state and state.frame,
	})
end

local function IsBetaEnabled()
	return GetDB("enableBetaFeatures", false) == true
end

local function GetFriendTagsModule()
	local FriendTags = BFL:GetModule("FriendTags")
	if FriendTags and FriendTags.NormalizeDB then
		FriendTags:NormalizeDB()
	end
	return FriendTags
end

local function GetFriendTagSetting(key, default)
	local FriendTags = GetFriendTagsModule()
	if FriendTags and FriendTags.GetSetting then
		return FriendTags:GetSetting(key, default)
	end
	local db = GetProfile()
	db.friendTagSettings = db.friendTagSettings or {}
	local value = db.friendTagSettings[key]
	if value == nil then
		return default
	end
	return value
end

local function SetFriendTagSetting(key, value)
	local FriendTags = GetFriendTagsModule()
	if FriendTags and FriendTags.SetSetting then
		FriendTags:SetSetting(key, value, RefreshFriends)
		return
	end
	local db = GetProfile()
	db.friendTagSettings = db.friendTagSettings or {}
	db.friendTagSettings[key] = value
	BumpSettingsVersion()
	RefreshFriends()
end

local function IsContactMemoryEnabledForFriendTags()
	if not IsBetaEnabled() then
		return false
	end
	local ContactMemory = BFL:GetModule("ContactMemory")
	return ContactMemory and ContactMemory.IsEnabled and ContactMemory:IsEnabled()
end

local function IsFriendTagsEnabled()
	local FriendTags = GetFriendTagsModule()
	return FriendTags and FriendTags.IsEnabled and FriendTags:IsEnabled()
end

local function OpenFriendTagEditor(tagId)
	local Editor = BFL:GetModule("FriendTagEditor")
	if Editor and Editor.Show then
		Editor:Show(tagId)
	end
end

local function BuildFriendTagEntries()
	local FriendTags = GetFriendTagsModule()
	local entries = {}
	if not (FriendTags and FriendTags.GetAllTagDefinitions) then
		return entries
	end
	for _, def in ipairs(FriendTags:GetAllTagDefinitions()) do
		local profile = FriendTags:GetChipProfile(def)
		entries[#entries + 1] = {
			id = def.id,
			key = def.id,
			label = (def.name or def.id)
				.. "  "
				.. (def.source == "blizzard" and T("FRIEND_TAGS_SOURCE_BLIZZARD", "Blizzard") or T("FRIEND_TAGS_SOURCE_CUSTOM", "Custom")),
			icon = profile and profile.icon or def.icon or "Interface\\AddOns\\BetterFriendlist\\Icons\\tag",
			source = def.source,
			visible = profile and profile.visible ~= false,
		}
	end
	return entries
end

local function MoveFriendTagEntry(fromIndex, toIndex)
	local FriendTags = GetFriendTagsModule()
	if not (FriendTags and FriendTags.SetChipProfile) then
		return
	end
	local entries = BuildFriendTagEntries()
	if fromIndex < 1 or fromIndex > #entries or toIndex < 1 or toIndex > #entries then
		return
	end
	local moved = table.remove(entries, fromIndex)
	table.insert(entries, toIndex, moved)
	for index, entry in ipairs(entries) do
		FriendTags:SetChipProfile(entry.id, { order = index * 10 }, RefreshFriends)
	end
end

local function SyncKnownBlizzardTags()
	local FriendTags = GetFriendTagsModule()
	if FriendTags and FriendTags.HandoffKnownLocalBlizzardTags then
		FriendTags:HandoffKnownLocalBlizzardTags(RefreshFriends)
	end
end

local function SetSettingsCenterBetaEnabled(value)
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.OnSettingsCenterBetaChanged then
		Settings:OnSettingsCenterBetaChanged(value == true)
	else
		SetDB("enableSettingsCenterBeta", value == true)
	end
end

local function IsThemeCustomizationVisible()
	return true
end

local function IsGuildTabAvailable()
	if BFL.GetGuildTabCapability then
		local capability = BFL:GetGuildTabCapability()
		return capability and capability.canShowSetting == true
	end
	return true
end

local function IsGuildTabVisible()
	if not IsBetaEnabled() then
		return false
	end
	return IsGuildTabAvailable()
end

-- Theme Customization is no longer a Retail-only beta card.
-- Appearance owns the standard Theme page entry point.
-- Other helpers below continue to model real beta-only pages.
local function OpenSettingsPage(pageID, focusControlID)
	return function()
		SettingsDesigner:Show(pageID, focusControlID)
	end
end

local function OpenSettingsCategory(categoryID)
	return function()
		local frame = ConfigUI and ConfigUI.GetFrame and ConfigUI:GetFrame(APP_ID)
		local state = frame and frame._LibSettingsDesignerState
		if state and state.SetCategory then
			state:SetCategory(categoryID)
			return
		end
		SettingsDesigner:Show()
		frame = ConfigUI and ConfigUI.GetFrame and ConfigUI:GetFrame(APP_ID)
		state = frame and frame._LibSettingsDesignerState
		if state and state.SetCategory then
			state:SetCategory(categoryID)
		end
	end
end

local function AddBetaFeatureLink(data)
	AddButton("advanced.beta", {
		id = "betaFeature." .. data.id,
		group = "available",
		label = data.label,
		desc = data.desc,
		buttonText = T("SETTINGS_CENTER_OPEN", "Open"),
		order = data.order,
		visibleWhen = data.visibleWhen,
		isEnabled = function()
			if not IsBetaEnabled() then
				return false
			end
			if data.isEnabled then
				return data.isEnabled()
			end
			return true
		end,
		keywords = data.keywords,
		searchtags = data.searchtags,
		newTagID = data.newTagID,
		onClick = OpenSettingsPage(data.pageID, data.focusControlID),
	})
end

local function PercentFormatter(value)
	return string.format("%d%%", math.floor(((tonumber(value) or 0) * 100) + 0.5))
end

local function ThemeVisible(theme)
	return function()
		return GetDB("theme", "blizzard") == theme
	end
end

local function RegisterThemeTuning(theme, title, baseOrder)
	local visible = ThemeVisible(theme)
	local groupID = theme .. "Tuning"
	AddGroup("appearance.theme", groupID, title, baseOrder)
	AddColor("appearance.theme", {
		id = theme .. ".accentColor",
		group = groupID,
		label = T(THEME_SETTING_LABELS.accentColor[1], THEME_SETTING_LABELS.accentColor[2]),
		default = theme == "dark" and { r = 1, g = 0.82, b = 0, a = 1 } or { r = 0.18, g = 0.88, b = 0.82, a = 1 },
		order = baseOrder + 1,
		visibleWhen = visible,
		getColor = function()
			return AsColor(GetThemeSetting(theme, "accentColor"), theme == "dark" and { r = 1, g = 0.82, b = 0, a = 1 } or { r = 0.18, g = 0.88, b = 0.82, a = 1 })
		end,
		setColor = function(r, g, b, a)
			SetThemeSetting(theme, "accentColor", ToColorTable(r, g, b, a))
		end,
		skinRefresh = true,
	})
	local sliderKeys = {
		"windowOpacity",
		"popupOpacity",
		"listOpacity",
		"controlOpacity",
		"hoverStrength",
		"selectionStrength",
		"borderStrength",
		"avatarVisibility",
	}
	for index, key in ipairs(sliderKeys) do
		local label = THEME_SETTING_LABELS[key]
		AddSlider("appearance.theme", {
			id = theme .. "." .. key,
			group = groupID,
			label = T(label[1], label[2]),
			min = THEME_SLIDER_MIN[key] or 0,
			max = 1,
			step = 0.01,
			default = GetThemeSetting(theme, key) or 0,
			formatter = PercentFormatter,
			order = baseOrder + 10 + index,
			visibleWhen = visible,
			getValue = function()
				return GetThemeSetting(theme, key) or 0
			end,
			setValue = function(value)
				SetThemeSetting(theme, key, value)
			end,
			skinRefresh = true,
		})
	end
	AddButton("appearance.theme", {
		id = theme .. ".reset",
		group = groupID,
		label = T("SETTINGS_RESET_THEME", "Reset Theme"),
		desc = T("SETTINGS_RESET_THEME_DESC", "Restore this theme's visual tuning defaults."),
		buttonText = RESET or "Reset",
		order = baseOrder + 30,
		visibleWhen = visible,
		onClick = function()
			local ThemePalette = GetThemePalette()
			if theme == "dark" and ThemePalette and ThemePalette.ResetDarkSettings then
				ThemePalette:ResetDarkSettings()
			elseif theme == "custom" and ThemePalette and ThemePalette.ResetCustomSettings then
				ThemePalette:ResetCustomSettings()
			end
			ApplyThemeChange()
		end,
	})
end

local function RegisterCustomPaletteControls()
	local visible = ThemeVisible("custom")
	local entries = {}
	for _, definition in ipairs(CUSTOM_COLOR_DEFINITIONS) do
		entries[#entries + 1] = {
			key = definition.key,
			label = T(definition.labelKey, definition.label),
		}
	end
	AddGroup("appearance.theme", "customPalette", T("SETTINGS_THEME_CUSTOM_COLORS", "Custom Colors"), 400)
	AddColorOverrides("appearance.theme", {
		id = "customTheme.palette",
		group = "customPalette",
		label = T("SETTINGS_THEME_CUSTOM_COLORS", "Custom Colors"),
		desc = T("SETTINGS_THEME_CUSTOM_COLORS_DESC", "Set the palette tokens used by the Custom theme."),
		entries = entries,
		hasOpacity = true,
		order = 410,
		visibleWhen = visible,
		getColor = GetCustomThemeColor,
		setColor = SetCustomThemeColor,
		skinRefresh = true,
	})
	AddButton("appearance.theme", {
		id = "customTheme.palette.reset",
		group = "customPalette",
		label = T("SETTINGS_RESET_CUSTOM_COLORS", "Reset Custom Colors"),
		desc = T("SETTINGS_RESET_CUSTOM_COLORS_DESC", "Restore the Custom theme color palette."),
		buttonText = RESET or "Reset",
		order = 420,
		visibleWhen = visible,
		onClick = function()
			local ThemePalette = GetThemePalette()
			if ThemePalette and ThemePalette.ResetCustomTheme then
				ThemePalette:ResetCustomTheme()
			else
				SetDB("customTheme", {}, ApplyThemeChange)
			end
			ApplyThemeChange()
		end,
	})
end

local function RegisterRaidShortcutControls()
	AddGroup("social.raid", "shortcuts", T("SETTINGS_RAID_SHORTCUTS_TITLE", "Raid Shortcuts"), 200)
	for index, action in ipairs(RAID_SHORTCUT_ACTIONS) do
		local enabledKey = "raidShortcutEnabled_" .. action.key
		AddDropdown("social.raid", {
			id = "raidShortcut." .. action.key .. ".modifier",
			group = "shortcuts",
			label = string.format("%s: %s", T(action.labelKey, action.fallback), T("SETTINGS_RAID_SHORTCUT_MODIFIER", "Modifier")),
			listFunc = function()
				return GetRaidModifierOptionsFor(action)
			end,
			default = action.defaultModifier,
			order = 200 + (index * 10),
			parentCheck = function()
				return GetDB(enabledKey, true) == true
			end,
			getValue = function()
				return GetRaidShortcutValue(action, "modifier")
			end,
			setValue = function(value)
				SetRaidShortcutValue(action, "modifier", value)
			end,
			refreshOnChange = true,
		})
		AddDropdown("social.raid", {
			id = "raidShortcut." .. action.key .. ".button",
			group = "shortcuts",
			label = string.format("%s: %s", T(action.labelKey, action.fallback), T("SETTINGS_RAID_SHORTCUT_BUTTON", "Mouse Button")),
			listFunc = function()
				return GetRaidButtonOptionsFor(action)
			end,
			default = action.defaultButton,
			order = 205 + (index * 10),
			parentCheck = function()
				return GetDB(enabledKey, true) == true
			end,
			getValue = function()
				return GetRaidShortcutValue(action, "button")
			end,
			setValue = function(value)
				SetRaidShortcutValue(action, "button", value)
			end,
			refreshOnChange = true,
		})
	end
end

local function RegisterGroupOrderControls()
	AddGroup("groups.order", "order", T("SETTINGS_GROUP_ORDER", "Group Order"), 100)
	AddReorderList("groups.order", {
		id = "groups.order.list",
		group = "order",
		label = T("SETTINGS_GROUP_ORDER", "Group Order"),
		desc = T("SETTINGS_CENTER_GROUP_ORDER_DESC", "Move groups to define the order used by the Friendlist and Note Sync."),
		order = 100,
		getEntries = BuildGroupEntries,
		moveEntry = MoveGroupEntry,
		emptyText = T("SETTINGS_CENTER_GROUP_ORDER_EMPTY", "No groups available."),
	})
	local entries = BuildGroupEntries()
	AddGroup("groups.order", "colors", T("SETTINGS_COLORS", "Colors"), 200)
	AddColorOverrides("groups.order", {
		id = "groups.colors.header",
		group = "colors",
		label = T("SETTINGS_GROUP_COLOR", "Group Color"),
		desc = T("SETTINGS_GROUP_COLOR_DESC", "Customize group header colors."),
		entries = entries,
		hasOpacity = true,
		order = 200,
		getColor = function(groupId)
			return GetGroupColor("groupColors", groupId)
		end,
		setColor = function(groupId, r, g, b, a)
			SetGroupColor("groupColors", groupId, r, g, b, a)
		end,
	})
	AddColorOverrides("groups.order", {
		id = "groups.colors.count",
		group = "colors",
		label = T("SETTINGS_GROUP_COUNT_COLOR", "Count Color"),
		desc = T("SETTINGS_GROUP_COUNT_COLOR_DESC", "Customize group count text colors."),
		entries = entries,
		hasOpacity = true,
		order = 210,
		getColor = function(groupId)
			return GetGroupColor("groupCountColors", groupId)
		end,
		setColor = function(groupId, r, g, b, a)
			SetGroupColor("groupCountColors", groupId, r, g, b, a)
		end,
	})
	AddColorOverrides("groups.order", {
		id = "groups.colors.arrow",
		group = "colors",
		label = T("SETTINGS_GROUP_ARROW_COLOR", "Arrow Color"),
		desc = T("SETTINGS_GROUP_ARROW_COLOR_DESC", "Customize group arrow colors."),
		entries = entries,
		hasOpacity = true,
		order = 220,
		getColor = function(groupId)
			return GetGroupColor("groupArrowColors", groupId)
		end,
		setColor = function(groupId, r, g, b, a)
			SetGroupColor("groupArrowColors", groupId, r, g, b, a)
		end,
	})
end

local function RegisterSortingControls()
	AddGroup("groups.sorting", "defaults", T("SETTINGS_CENTER_SORTING_DEFAULTS", "Friend List Defaults"), 100)
	AddDropdown("groups.sorting", {
		key = "quickFilter",
		group = "defaults",
		label = T("SETTINGS_QUICK_FILTER", "QuickFilter"),
		desc = T("SETTINGS_QUICK_FILTER_DESC", "Choose the default friend list filter."),
		listFunc = GetQuickFilterOptions,
		default = "all",
		order = 100,
		getValue = function()
			return GetDB("quickFilter", "all")
		end,
		setValue = SetFriendFilter,
	})
	AddDropdown("groups.sorting", {
		key = "primarySort",
		group = "defaults",
		label = T("SETTINGS_PRIMARY_SORT", "Primary Sort"),
		desc = T("SETTINGS_PRIMARY_SORT_DESC", "Choose the primary friend list sorting mode."),
		listFunc = function()
			return GetSorterOptions(false)
		end,
		default = "status",
		order = 110,
		getValue = function()
			return GetDB("primarySort", "status")
		end,
		setValue = SetFriendPrimarySort,
		refreshOnChange = true,
	})
	AddDropdown("groups.sorting", {
		key = "secondarySort",
		group = "defaults",
		label = T("SETTINGS_SECONDARY_SORT", "Secondary Sort"),
		desc = T("SETTINGS_SECONDARY_SORT_DESC", "Choose the secondary sorting mode used within primary sort groups."),
		listFunc = function()
			return GetSorterOptions(true)
		end,
		default = "name",
		order = 120,
		getValue = function()
			return GetDB("secondarySort", "name")
		end,
		setValue = SetFriendSecondarySort,
	})
	AddGroup("groups.sorting", "editor", T("SETTINGS_CENTER_PAGE_QUICKFILTER_EDITOR", "QuickFilter & Sorter Editor"), 200)
	AddButton("groups.sorting", {
		id = "groups.sorting.openEditor",
		group = "editor",
		label = T("SETTINGS_CENTER_PAGE_QUICKFILTER_EDITOR", "QuickFilter & Sorter Editor"),
		desc = T("SETTINGS_CENTER_QUICKFILTER_EDITOR_DESC", "Create, order, preview, and edit custom QuickFilters and sorters."),
		buttonText = T("SETTINGS_CENTER_OPEN_EDITOR", "Open Editor"),
		order = 200,
		visibleWhen = IsBetaEnabled,
		onClick = OpenSettingsPage("groups.quickfilter"),
		newTagID = "groups.quickfilter.editor",
	})
end

local function RegisterBrokerColumnControls(pageID, groupID, columns, options)
	AddReorderList(pageID, {
		id = options.orderID,
		group = groupID,
		label = options.orderLabel,
		desc = options.orderDesc,
		order = options.order,
		parentCheck = options.parentCheck,
		showAddButton = false,
		showRemoveButton = false,
		showEntryID = false,
		getEntries = function()
			return BuildColumnEntries(columns, options.orderKey, options.iconKey)
		end,
		moveEntry = function(fromIndex, toIndex)
			MoveColumnEntry(columns, options.orderKey, fromIndex, toIndex)
		end,
		entryToggle = {
			getValue = function(entryID)
				local selection = GetColumnVisibilitySelection(columns, options.visibilityPrefix)
				return selection[entryID] == true
			end,
			setValue = function(entryID, _, visible)
				SetColumnVisibility(columns, options.visibilityPrefix, entryID, visible)
			end,
		},
	})
end

local function RegisterBrokerColorControls(pageID, groupID, entries, order, parentCheck)
	AddColorOverrides(pageID, {
		id = groupID .. ".colors",
		group = groupID,
		label = T("BROKER_SETTINGS_COLUMN_COLORS", "Column Colors"),
		desc = T("SETTINGS_CENTER_BROKER_COLUMN_COLORS_DESC", "Set column text colors. Use the reset button to inherit the default color."),
		entries = entries,
		hasOpacity = false,
		order = order,
		parentCheck = parentCheck,
		getColor = GetOptionalArrayColor,
		setColor = SetOptionalArrayColor,
		hasOverride = function(key)
			return GetDB(key) ~= nil
		end,
		clearColor = function(key)
			ClearDB(key, RefreshBrokerDisplays)
		end,
		getDefaultColor = function()
			return 1, 1, 1, 1
		end,
	})
end

local function GetFilterSortRegistry()
	return BFL:GetModule("FilterSortRegistry")
end

local function GetQuickFilterOptions()
	local Registry = GetFilterSortRegistry()
	local options, order = {}, {}
	if Registry and Registry.GetVisibleQuickFilters then
		for _, entry in ipairs(Registry:GetVisibleQuickFilters()) do
			options[entry.id] = entry.name or entry.id
			order[#order + 1] = entry.id
		end
	end
	if next(options) == nil then
		options.all = ALL or "All"
		order[1] = "all"
	end
	return options, order
end

local function GetSorterOptions(includeNone)
	local Registry = GetFilterSortRegistry()
	local options, order = {}, {}
	if includeNone then
		options.none = T("SORT_NONE", "None")
		order[#order + 1] = "none"
	end
	if Registry and Registry.GetVisibleSorters then
		for _, entry in ipairs(Registry:GetVisibleSorters()) do
			options[entry.id] = entry.name or entry.id
			order[#order + 1] = entry.id
		end
	end
	if next(options) == nil then
		options.status = STATUS or "Status"
		order[1] = "status"
	end
	return options, order
end

local function SetFriendFilter(value)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.SetFilterMode then
		FriendsList:SetFilterMode(value)
	else
		SetDB("quickFilter", value, RefreshFriends)
	end
end

local function SetFriendPrimarySort(value)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.SetSortMode then
		FriendsList:SetSortMode(value)
	else
		SetDB("primarySort", value, RefreshFriends)
	end
end

local function SetFriendSecondarySort(value)
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.SetSecondarySortMode then
		FriendsList:SetSecondarySortMode(value)
	else
		SetDB("secondarySort", value, RefreshFriends)
	end
end

local function GetSortingDefaultsPageHeight()
	return IsBetaEnabled() and 334 or 268
end

local function RenderSortingDefaultsCustomPage(parent, _, _, state, focusID)
	if not parent then
		return nil
	end
	local frames = {}
	local y = -14

	local function Track(frame)
		frames[#frames + 1] = frame
		return frame
	end

	local function CreateInfoBlock(text)
		local block = Track(CreateFrame("Frame", nil, parent, "BackdropTemplate"))
		block:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
		block:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
		block:SetHeight(52)
		ApplyCustomBackdrop(block, { 0.015, 0.013, 0.010, 0.54 }, { 0.34, 0.26, 0.10, 0.54 })
		local label = block:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
		label:SetPoint("TOPLEFT", block, "TOPLEFT", 14, -11)
		label:SetPoint("BOTTOMRIGHT", block, "BOTTOMRIGHT", -14, 10)
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
		label:SetWordWrap(true)
		label:SetText(text or "")
		y = y - 62
		return block
	end

	local function CreateDropdownRow(controlID, labelText, descText, entries, selectedValue, onSelection)
		local row = Track(CreateFrame("Frame", nil, parent, "BackdropTemplate"))
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
		row:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
		row:SetHeight(56)
		local isFocused = focusID == controlID
		ApplyCustomBackdrop(
			row,
			isFocused and { 0.060, 0.048, 0.020, 0.80 } or { 0.020, 0.018, 0.014, 0.62 },
			isFocused and { 0.92, 0.72, 0.20, 0.90 } or { 0.28, 0.22, 0.10, 0.58 }
		)

		local label = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlightSmall")
		label:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -9)
		label:SetPoint("RIGHT", row, "RIGHT", -310, 0)
		label:SetHeight(18)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		label:SetText(labelText or "")

		local desc = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
		desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
		desc:SetPoint("RIGHT", label, "RIGHT", 0, 0)
		desc:SetHeight(18)
		desc:SetJustifyH("LEFT")
		desc:SetWordWrap(false)
		desc:SetText(descText or "")

		local dropdown = CreateSettingsDropdown(row, entries, selectedValue, function(value)
			if onSelection then
				onSelection(value)
			end
			RefreshSettingsCenter(state)
		end, 268)
		dropdown:SetPoint("RIGHT", row, "RIGHT", -14, 0)
		y = y - 62
		return row
	end

	local function CreateEditorRow()
		local row = Track(CreateFrame("Frame", nil, parent, "BackdropTemplate"))
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
		row:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
		row:SetHeight(56)
		ApplyCustomBackdrop(row, { 0.018, 0.016, 0.012, 0.62 }, { 0.36, 0.28, 0.10, 0.58 })

		local label = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlightSmall")
		label:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -9)
		label:SetPoint("RIGHT", row, "RIGHT", -180, 0)
		label:SetHeight(18)
		label:SetJustifyH("LEFT")
		label:SetText(T("SETTINGS_CENTER_PAGE_QUICKFILTER_EDITOR", "QuickFilter & Sorter Editor"))

		local desc = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontDisableSmall")
		desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
		desc:SetPoint("RIGHT", label, "RIGHT", 0, 0)
		desc:SetHeight(18)
		desc:SetJustifyH("LEFT")
		desc:SetWordWrap(false)
		desc:SetText(T("SETTINGS_CENTER_QUICKFILTER_EDITOR_DESC", "Create, order, preview, and edit custom QuickFilters and sorters."))

		local button = CreateFlatActionButton(row, T("SETTINGS_CENTER_OPEN_EDITOR", "Open Editor"), 124, 24)
		button:SetPoint("RIGHT", row, "RIGHT", -14, 0)
		button:SetScript("OnClick", OpenSettingsPage("groups.quickfilter"))
		y = y - 66
		return row
	end

	CreateInfoBlock(T("SETTINGS_CENTER_PAGE_GROUPS_SORTING_DESC", "Sets the default QuickFilter and sorters used by the Friendlist."))

	local filterOptions, filterOrder = GetQuickFilterOptions()
	CreateDropdownRow(
		"quickFilter",
		T("SETTINGS_QUICK_FILTER", "QuickFilter"),
		T("SETTINGS_QUICK_FILTER_DESC", "Choose the default friend list filter."),
		BuildDropdownEntries(filterOptions, filterOrder),
		GetDB("quickFilter", "all"),
		SetFriendFilter
	)

	local primaryOptions, primaryOrder = GetSorterOptions(false)
	CreateDropdownRow(
		"primarySort",
		T("SETTINGS_PRIMARY_SORT", "Primary Sort"),
		T("SETTINGS_PRIMARY_SORT_DESC", "Choose the primary friend list sorting mode."),
		BuildDropdownEntries(primaryOptions, primaryOrder),
		GetDB("primarySort", "status"),
		SetFriendPrimarySort
	)

	local secondaryOptions, secondaryOrder = GetSorterOptions(true)
	CreateDropdownRow(
		"secondarySort",
		T("SETTINGS_SECONDARY_SORT", "Secondary Sort"),
		T("SETTINGS_SECONDARY_SORT_DESC", "Choose the secondary sorting mode used within primary sort groups."),
		BuildDropdownEntries(secondaryOptions, secondaryOrder),
		GetDB("secondarySort", "name"),
		SetFriendSecondarySort
	)

	if IsBetaEnabled() then
		CreateEditorRow()
	end

	return {
		Release = function()
			for _, frame in ipairs(frames) do
				if frame.Hide then
					frame:Hide()
				end
				if frame.SetParent then
					frame:SetParent(nil)
				end
			end
		end,
	}
end

local function MainFrameSize(layoutKey, field, fallback)
	local size = GetDB("mainFrameSize", {})
	local layout = type(size) == "table" and size[layoutKey or "default"] or nil
	if type(layout) == "table" and layout[field] ~= nil then
		return layout[field]
	end
	return GetDB(field == "width" and "defaultFrameWidth" or "defaultFrameHeight", fallback)
end

local function RegisterCategories()
	app:RegisterCategory({ id = "friends", title = T("SETTINGS_CENTER_CATEGORY_FRIENDS", "Friendlist"), iconKey = "bfl-friends", order = 100 })
	app:RegisterCategory({ id = "appearance", title = T("SETTINGS_CENTER_CATEGORY_APPEARANCE", "Appearance"), iconKey = "bfl-appearance", order = 200 })
	app:RegisterCategory({ id = "groups", title = T("SETTINGS_CENTER_CATEGORY_GROUPS_SORTING", "Groups & Sorting"), iconKey = "bfl-groups", order = 300 })
	app:RegisterCategory({ id = "social", title = T("SETTINGS_CENTER_CATEGORY_SOCIAL", "Social Tools"), iconKey = "bfl-social", order = 400 })
	app:RegisterCategory({ id = "broker", title = T("SETTINGS_CENTER_CATEGORY_BROKER_SYNC", "Broker & Sync"), iconKey = "bfl-broker-sync", order = 500 })
	app:RegisterCategory({ id = "privacy", title = T("SETTINGS_CENTER_CATEGORY_PRIVACY", "Privacy"), iconKey = "bfl-privacy", order = 600 })
	app:RegisterCategory({ id = "advanced", title = T("SETTINGS_TAB_ADVANCED", "Advanced"), iconKey = "bfl-advanced", order = 700 })
	app:RegisterCategory({ id = "help", title = T("SETTINGS_CENTER_CATEGORY_HELP", HELP_LABEL or "Help"), iconKey = "bfl-help", order = 900 })
end

local function RegisterFriendsPages()
	RegisterPage({
		id = "friends.display",
		category = "friends",
		title = T("SETTINGS_CENTER_PAGE_FRIENDS_DISPLAY", "Display"),
		description = T("SETTINGS_CENTER_PAGE_FRIENDS_DISPLAY_DESC", "Controls visible friend row details and list state."),
		iconKey = "bfl-friends-display",
		order = 100,
	})
	AddGroup("friends.display", "rows", T("SETTINGS_CENTER_GROUP_ROWS", "Rows"), 100)
	AddToggle("friends.display", { key = "colorClassNames", group = "rows", label = T("SETTINGS_COLOR_CLASS_NAMES", "Color Class Names"), desc = T("SETTINGS_COLOR_CLASS_NAMES_DESC", "Color character names by class."), default = true, order = 100, method = "OnColorClassNamesChanged" })
	AddToggle("friends.display", { key = "showFactionIcons", group = "rows", label = T("SETTINGS_SHOW_FACTION_ICONS", "Show Faction Icons"), desc = T("SETTINGS_SHOW_FACTION_ICONS_DESC", "Display Alliance/Horde icons next to character names."), default = false, order = 110, method = "OnShowFactionIconsChanged" })
	AddToggle("friends.display", { key = "showFactionBg", group = "rows", label = T("SETTINGS_SHOW_FACTION_BG", "Show Faction Background"), desc = T("SETTINGS_SHOW_FACTION_BG_DESC", "Show faction color as background for friend buttons."), default = false, order = 120, after = RefreshFriends })
	AddToggle("friends.display", { key = "grayOtherFaction", group = "rows", label = T("SETTINGS_GRAY_OTHER_FACTION", "Gray Out Other Faction"), desc = T("SETTINGS_GRAY_OTHER_FACTION_DESC", "Dim characters from the other faction."), default = false, order = 130, method = "OnGrayOtherFactionChanged" })
	AddToggle("friends.display", { key = "showMultiAccountBadge", group = "rows", label = T("SETTINGS_SHOW_MULTI_ACCOUNT_BADGE", "Show Multi-Account Badge"), desc = T("SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC", "Display a badge for friends with multiple online game accounts."), default = true, order = 140, after = RefreshFriends })
	AddToggle("friends.display", { key = "showMultiAccountInfo", group = "rows", label = T("SETTINGS_SHOW_MULTI_ACCOUNT_INFO", "Show Multi-Account Info"), desc = T("SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC", "Append multi-account details to the info line."), default = true, order = 150, after = RefreshFriends })
	AddToggle("friends.display", { key = "showRealmName", group = "rows", label = T("SETTINGS_SHOW_REALM_NAME", "Show Realm Name"), desc = T("SETTINGS_SHOW_REALM_NAME_DESC", "Display the realm name for friends on different servers."), default = false, order = 160, method = "OnShowRealmNameChanged" })
	AddToggle("friends.display", { key = "hideMaxLevel", group = "rows", label = T("SETTINGS_HIDE_MAX_LEVEL", "Hide Max Level"), desc = T("SETTINGS_HIDE_MAX_LEVEL_DESC", "Do not display level number for characters at max level."), default = false, order = 170, method = "OnHideMaxLevelChanged" })
	AddToggle("friends.display", { key = "showMobileAsAFK", group = "rows", label = T("SETTINGS_SHOW_MOBILE_AS_AFK", "Show Mobile as AFK"), desc = T("SETTINGS_SHOW_MOBILE_AS_AFK_DESC", "Display AFK status icon for friends on mobile."), default = false, order = 180, method = "OnShowMobileAsAFKChanged" })
	AddToggle("friends.display", { key = "treatMobileAsOffline", group = "rows", label = T("SETTINGS_TREAT_MOBILE_OFFLINE", "Treat Mobile users as Offline"), desc = T("SETTINGS_TREAT_MOBILE_OFFLINE_DESC", "Move mobile-only friends into the offline group."), default = false, order = 190, method = "OnTreatMobileAsOfflineChanged" })
	AddToggle("friends.display", { key = "showWelcomeMessage", group = "rows", label = T("SETTINGS_SHOW_WELCOME_MESSAGE", "Show Welcome Message"), desc = T("SETTINGS_SHOW_WELCOME_MESSAGE_DESC", "Show a chat welcome message after login."), default = true, order = 200 })
	AddToggle("friends.display", { key = "showBlizzardOption", group = "rows", label = T("SETTINGS_SHOW_BLIZZARD", "Show Blizzard's Friendlist Option"), desc = T("SETTINGS_SHOW_BLIZZARD_DESC", "Shows the original Blizzard Friends button in the social menu."), default = false, order = 210, method = "OnShowBlizzardOptionChanged" })
	AddToggle("friends.display", { key = "showGameIcon", group = "rows", label = T("SETTINGS_SHOW_GAME_ICON", "Show Game Icon"), desc = T("SETTINGS_SHOW_GAME_ICON_DESC", "Display game icons next to Battle.net friends."), default = true, order = 220, after = RefreshFriends })
	AddToggle("friends.display", { key = "colorLevelByDifficulty", group = "rows", label = T("SETTINGS_COLOR_LEVEL_BY_DIFFICULTY", "Color Levels by Difficulty"), desc = T("SETTINGS_COLOR_LEVEL_BY_DIFFICULTY_DESC", "Color level text by difficulty relative to your character."), default = true, order = 230, after = RefreshFriends })
	AddToggle("friends.display", { key = "showNoteIcon", group = "rows", label = T("SETTINGS_SHOW_NOTE_ICON", "Show Note Icon"), desc = T("SETTINGS_SHOW_NOTE_ICON_DESC", "Display an icon when a friend has a note."), default = false, order = 240, after = RefreshFriends })

	AddGroup("friends.display", "favorites", T("SETTINGS_FAVORITE_ICON_STYLE", "Favorite Icon"), 200)
	AddToggle("friends.display", { key = "enableFavoriteIcon", group = "favorites", label = T("SETTINGS_ENABLE_FAVORITE_ICON", "Enable Favorite Icon"), desc = T("SETTINGS_ENABLE_FAVORITE_ICON_DESC", "Display a star icon on the friend button for favorites."), default = true, order = 300, after = RefreshFriends, refreshOnChange = true })
	AddDropdown("friends.display", {
		key = "favoriteIconStyle",
		group = "favorites",
		label = T("SETTINGS_FAVORITE_ICON_STYLE", "Favorite Icon"),
		desc = T("SETTINGS_FAVORITE_ICON_STYLE_DESC", "Choose which icon is used for favorites."),
		list = { bfl = T("SETTINGS_FAVORITE_ICON_OPTION_BFL", "BFL Icon"), blizzard = T("SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD", "Blizzard Icon") },
		orderList = { "bfl", "blizzard" },
		default = "bfl",
		order = 310,
		parentCheck = function() return GetDB("enableFavoriteIcon", true) == true end,
		after = RefreshFriends,
	})

	RegisterPage({
		id = "friends.formatting",
		category = "friends",
		title = T("SETTINGS_CENTER_PAGE_FRIENDS_FORMATTING", "Name & Info"),
		description = T("SETTINGS_CENTER_PAGE_FRIENDS_FORMATTING_DESC", "Controls how names and secondary info are rendered."),
		iconKey = "bfl-friends-formatting",
		order = 110,
	})
	AddGroup("friends.formatting", "names", T("SETTINGS_NAME_FORMAT_HEADER", "Name Formatting"), 100)
	AddDropdown("friends.formatting", {
		key = "nameFormatPreset",
		group = "names",
		label = T("SETTINGS_NAME_FORMAT_LABEL", "Preset:"),
		desc = T("SETTINGS_NAME_FORMAT_DESC", "Choose the primary name format used in the friends list."),
		list = {
			default = T("SETTINGS_NAME_FORMAT_DEFAULT", "Default"),
			battletag = T("SETTINGS_NAME_FORMAT_BATTLETAG", "BattleTag"),
			nickname = T("SETTINGS_NAME_FORMAT_NICKNAME", "Nickname"),
			name_nickname = T("SETTINGS_NAME_FORMAT_NAME_NICKNAME", "Name (Nickname)"),
			name_note = T("SETTINGS_NAME_FORMAT_NAME_NOTE", "Name (Note)"),
			name_battletag = T("SETTINGS_NAME_FORMAT_NAME_BATTLETAG", "Name (BattleTag)"),
			custom = T("SETTINGS_NAME_FORMAT_CUSTOM", "Custom"),
		},
		orderList = { "default", "battletag", "nickname", "name_nickname", "name_note", "name_battletag", "custom" },
		default = "default",
		order = 100,
		after = RefreshFriends,
		refreshOnChange = true,
	})
	AddInput("friends.formatting", { key = "nameFormatCustom", group = "names", label = T("SETTINGS_NAME_FORMAT_CUSTOM_LABEL", "Custom Format:"), desc = T("SETTINGS_NAME_FORMAT_TOOLTIP", "Custom Name Format"), default = "%name%", inputWidth = 280, maxChars = 80, order = 110, visibleWhen = function() return GetDB("nameFormatPreset", "default") == "custom" end, after = RefreshFriends })

	AddGroup("friends.formatting", "info", T("SETTINGS_INFO_FORMAT_HEADER", "Friend Info Formatting"), 200)
	AddDropdown("friends.formatting", {
		key = "infoFormatPreset",
		group = "info",
		label = T("SETTINGS_INFO_FORMAT_LABEL", "Preset:"),
		desc = T("SETTINGS_INFO_FORMAT_DESC", "Choose the secondary info line format."),
		list = {
			default = T("SETTINGS_INFO_FORMAT_DEFAULT", "Default"),
			zone = ZONE or "Zone",
			level = LEVEL or "Level",
			class_zone = T("SETTINGS_INFO_FORMAT_CLASS_ZONE", "Class, Zone"),
			level_class_zone = T("SETTINGS_INFO_FORMAT_LEVEL_CLASS_ZONE", "Level, Class, Zone"),
			game = T("SETTINGS_INFO_FORMAT_GAME", "Game"),
			disabled = T("SETTINGS_INFO_FORMAT_DISABLED", "Disabled"),
			custom = T("SETTINGS_INFO_FORMAT_CUSTOM", "Custom"),
		},
		orderList = { "default", "zone", "level", "class_zone", "level_class_zone", "game", "disabled", "custom" },
		default = "default",
		order = 200,
		after = RefreshFriends,
		refreshOnChange = true,
	})
	AddInput("friends.formatting", { key = "infoFormatCustom", group = "info", label = T("SETTINGS_INFO_FORMAT_CUSTOM_LABEL", "Custom Format:"), desc = T("SETTINGS_INFO_FORMAT_TOOLTIP", "Custom Info Format"), default = "%level%, %zone%", inputWidth = 280, maxChars = 80, order = 210, visibleWhen = function() return GetDB("infoFormatPreset", "default") == "custom" end, after = RefreshFriends })

	RegisterPage({
		id = "friends.behavior",
		category = "friends",
		title = T("SETTINGS_CENTER_PAGE_FRIENDS_BEHAVIOR", "Behavior"),
		description = T("SETTINGS_CENTER_PAGE_FRIENDS_BEHAVIOR_DESC", "Controls compact mode, window behavior, and click actions."),
		iconKey = "bfl-friends-behavior",
		order = 120,
	})
	AddGroup("friends.behavior", "list", T("SETTINGS_GROUP_MANAGEMENT", "Group Management"), 100)
	AddToggle("friends.behavior", { key = "accordionGroups", group = "list", label = T("SETTINGS_ACCORDION_GROUPS", "Accordion Groups"), desc = T("SETTINGS_ACCORDION_GROUPS_DESC", "Only one group can be expanded at a time."), default = false, order = 100, method = "OnAccordionGroupsChanged" })
	AddToggle("friends.behavior", { key = "compactMode", group = "list", label = T("SETTINGS_COMPACT_MODE", "Compact Mode"), desc = T("SETTINGS_COMPACT_MODE_DESC", "Use compact friend row spacing."), default = false, order = 110, method = "OnCompactModeChanged" })
	AddToggle("friends.behavior", { key = "simpleMode", group = "list", label = T("SETTINGS_SIMPLE_MODE", "Simple Mode"), desc = T("SETTINGS_SIMPLE_MODE_DESC", "Use a simplified Friends frame layout."), default = false, order = 120, method = "OnSimpleModeChanged", refreshOnChange = true })
	AddToggle("friends.behavior", { key = "simpleModeShowSearch", group = "list", label = T("SETTINGS_SIMPLE_MODE_SHOW_SEARCH", "Show Search in Simple Mode"), desc = T("SETTINGS_SIMPLE_MODE_SHOW_SEARCH_DESC", "Keep the search field visible while Simple Mode is enabled."), default = true, order = 130, parentCheck = function() return GetDB("simpleMode", false) end, after = RefreshFriends })
	AddToggle("friends.behavior", { key = "useUIPanelSystem", group = "list", label = T("SETTINGS_USE_UI_PANEL_SYSTEM", "Respect UI Hierarchy"), desc = T("SETTINGS_USE_UI_PANEL_SYSTEM_DESC", "Use Blizzard panel behavior for the BetterFriendlist frame."), default = false, order = 140, method = "OnUseUIPanelSystemChanged" })
	AddGroup("friends.behavior", "clicks", T("SETTINGS_CENTER_GROUP_CLICKS", "Click Actions"), 200)
	AddToggle("friends.behavior", { key = "friendListClickWhisperEnabled", group = "clicks", label = T("SETTINGS_FRIEND_CLICK_WHISPER", "Click to Whisper"), desc = T("SETTINGS_FRIEND_CLICK_WHISPER_DESC", "Allow friend row clicks to start whispers."), default = false, order = 200, method = "OnFriendListClickWhisperEnabledChanged", refreshOnChange = true })
	AddDropdown("friends.behavior", {
		key = "friendListClickWhisperMode",
		group = "clicks",
		label = T("SETTINGS_FRIEND_CLICK_WHISPER_MODE", "Whisper Trigger"),
		desc = T("SETTINGS_FRIEND_CLICK_WHISPER_MODE_DESC", "Choose whether whisper starts on single or double click."),
		list = { single = T("SETTINGS_CLICK_SINGLE", "Single Click"), double = T("SETTINGS_CLICK_DOUBLE", "Double Click") },
		orderList = { "double", "single" },
		default = "double",
		order = 210,
		parentCheck = function() return GetDB("friendListClickWhisperEnabled", false) == true end,
		method = "OnFriendListClickWhisperModeChanged",
	})
end

local function RegisterAppearancePages()
	RegisterPage({ id = "appearance.theme", category = "appearance", title = T("SETTINGS_CENTER_PAGE_APPEARANCE_THEME", "Theme"), description = T("SETTINGS_CENTER_PAGE_APPEARANCE_THEME_DESC", "Controls the BetterFriendlist visual theme."), iconKey = "bfl-appearance-theme", order = 100, newTagID = "appearance.theme" })
	AddGroup("appearance.theme", "theme", T("SETTINGS_THEME_HEADER", "Theme"), 100)
	AddDropdown("appearance.theme", {
		key = "theme",
		group = "theme",
		label = T("SETTINGS_THEME_DROPDOWN", "Theme"),
		desc = T("SETTINGS_THEME_DROPDOWN_DESC", "Choose the visual theme."),
		listFunc = GetThemeOptions,
		default = "blizzard",
		order = 100,
		method = "OnThemeChanged",
		refreshOnChange = true,
		skinRefresh = true,
		newTagID = "appearance.theme",
	})
	AddToggle("appearance.theme", { key = "enableElvUISkin", group = "theme", label = T("SETTINGS_ENABLE_ELVUI_SKIN", "Enable ElvUI Skin"), desc = T("SETTINGS_ENABLE_ELVUI_SKIN_DESC", "Use ElvUI styling when ElvUI is loaded."), default = false, order = 110, visibleWhen = function() return BFL.IsElvUIAvailable and BFL:IsElvUIAvailable() and not IsThemeCustomizationVisible() end, method = "OnLegacyElvUISkinChanged", skinRefresh = true })
	RegisterThemeTuning("dark", T("SETTINGS_THEME_DARK", "Dark"), 200)
	RegisterThemeTuning("custom", T("SETTINGS_THEME_CUSTOM", "Custom"), 300)
	RegisterCustomPaletteControls()

	RegisterPage({ id = "appearance.fonts", category = "appearance", title = T("SETTINGS_CENTER_PAGE_APPEARANCE_FONTS", "Fonts"), description = T("SETTINGS_CENTER_PAGE_APPEARANCE_FONTS_DESC", "Controls friend list, tab, raid, and group header fonts."), iconKey = "bfl-appearance-fonts", order = 110 })
	local fontGroups = {
		{ id = "friendName", title = T("SETTINGS_FONT_FRIEND_NAME_TITLE", "Friend Name Text"), font = "fontFriendName", size = "fontSizeFriendName", flags = "fontOutlineFriendName", shadow = "fontShadowFriendName", color = "fontColorFriendName", defaultSize = 12, defaultColor = { r = 0.510, g = 0.773, b = 1.0, a = 1 }, order = 100 },
		{ id = "friendInfo", title = T("SETTINGS_FONT_FRIEND_INFO_TITLE", "Friend Info Text"), font = "fontFriendInfo", size = "fontSizeFriendInfo", flags = "fontOutlineFriendInfo", shadow = "fontShadowFriendInfo", color = "fontColorFriendInfo", defaultSize = 10, defaultColor = { r = 0.510, g = 0.510, b = 0.510, a = 1 }, order = 200 },
		{ id = "tabs", title = T("SETTINGS_FONT_TABS_TITLE", "Tabs Text"), font = "fontTabText", size = "fontSizeTabText", flags = "fontOutlineTabText", shadow = "fontShadowTabText", color = "fontColorTabText", defaultSize = 12, defaultColor = { r = 1.0, g = 0.82, b = 0.0, a = 1 }, order = 300 },
		{ id = "raid", title = T("SETTINGS_FONT_RAID_TITLE", "Raid Name Text"), font = "fontRaidName", size = "fontSizeRaidName", flags = "fontOutlineRaidName", shadow = "fontShadowRaidName", color = "fontColorRaidName", defaultSize = 12, defaultColor = { r = 1.0, g = 0.82, b = 0.0, a = 1 }, order = 400 },
		{ id = "groupHeader", title = T("SETTINGS_GROUP_FONT_HEADER", "Group Header Font"), font = "fontGroupHeader", size = "fontSizeGroupHeader", flags = "fontOutlineGroupHeader", shadow = "fontShadowGroupHeader", color = nil, defaultSize = 12, order = 500 },
	}
	for _, group in ipairs(fontGroups) do
		AddGroup("appearance.fonts", group.id, group.title, group.order)
		AddDropdown("appearance.fonts", { key = group.font, group = group.id, label = T("SETTINGS_FONT", "Font:"), desc = T("SETTINGS_FONT_TOOLTIP", "Choose a font."), listFunc = GetFontOptions, default = "Friz Quadrata TT", order = group.order + 1, after = RefreshFonts })
		AddSlider("appearance.fonts", { key = group.size, group = group.id, label = T("SETTINGS_FONT_SIZE_NUM", "Font Size:"), desc = T("SETTINGS_FONT_SIZE_TOOLTIP", "Set the font size."), min = 8, max = 24, step = 1, default = group.defaultSize, integer = true, order = group.order + 2, after = RefreshFonts })
		AddFontFlags("appearance.fonts", group.flags, group.id, group.order + 3)
		AddToggle("appearance.fonts", { key = group.shadow, group = group.id, label = T("SETTINGS_FONT_SHADOW", "Shadow"), desc = T("SETTINGS_FONT_SHADOW_TOOLTIP", "Draw a shadow behind this text."), default = false, order = group.order + 4, after = RefreshFonts })
		if group.color then
			AddColor("appearance.fonts", { key = group.color, group = group.id, label = T("SETTINGS_FONT_COLOR", "Font Color"), desc = T("SETTINGS_FONT_COLOR_TOOLTIP", "Set the text color."), default = group.defaultColor, hasOpacity = true, order = group.order + 5, after = RefreshFonts })
		end
	end

	RegisterPage({ id = "appearance.frame", category = "appearance", title = T("SETTINGS_CENTER_PAGE_APPEARANCE_FRAME", "Frame"), description = T("SETTINGS_CENTER_PAGE_APPEARANCE_FRAME_DESC", "Controls BetterFriendlist frame dimensions, scale, and movement."), iconKey = "bfl-appearance-frame", order = 120 })
	AddGroup("appearance.frame", "size", T("SETTINGS_FRAME_DIMENSIONS_HEADER", "Frame Dimensions"), 100)
	AddSlider("appearance.frame", { id = "defaultFrameWidth", key = "defaultFrameWidth", group = "size", label = T("SETTINGS_FRAME_WIDTH", "Width:"), min = 380, max = 800, step = 5, default = 415, integer = true, order = 100, getValue = function() return MainFrameSize("default", "width", 415) end, setValue = function(value) SetDB("defaultFrameWidth", value); RefreshFrameSize(value, nil) end })
	AddSlider("appearance.frame", { id = "defaultFrameHeight", key = "defaultFrameHeight", group = "size", label = T("SETTINGS_FRAME_HEIGHT", "Height:"), min = 400, max = 1200, step = 5, default = 570, integer = true, order = 110, getValue = function() return MainFrameSize("default", "height", 570) end, setValue = function(value) SetDB("defaultFrameHeight", value); RefreshFrameSize(nil, value) end })
	AddSlider("appearance.frame", { key = "windowScale", group = "size", label = T("SETTINGS_FRAME_SCALE", "Scale:"), min = 0.5, max = 2.0, step = 0.05, default = 1.0, formatter = function(value) return string.format("%d%%", math.floor((tonumber(value) or 1) * 100 + 0.5)) end, order = 120, after = RefreshFriends })
	AddToggle("appearance.frame", { key = "lockWindow", group = "size", label = T("SETTINGS_LOCK_WINDOW", "Lock Window"), desc = T("SETTINGS_LOCK_WINDOW_DESC", "Prevent the BetterFriendlist frame from being moved."), default = false, order = 130, after = function(value) local FrameSettings = BFL:GetModule("FrameSettings"); if FrameSettings and FrameSettings.ApplyLock then FrameSettings:ApplyLock(value) end end })
end

local function RegisterFriendTagsControls()
	RegisterPage({
		id = "groups.friendtags",
		category = "groups",
		title = T("SETTINGS_CENTER_PAGE_FRIEND_TAGS", "Friend Tags & Chips"),
		description = T("SETTINGS_CENTER_PAGE_FRIEND_TAGS_DESC", "Controls friend tags, Blizzard-compatible tags, and row chips."),
		iconKey = "bfl-groups-order",
		mainToggleID = "friendTags.enabled",
		order = 135,
		visibleWhen = IsBetaEnabled,
		newTagID = "friend-tags",
	})

	AddGroup("groups.friendtags", "general", T("FRIEND_TAGS_SETTINGS_GENERAL", "Friend Tags"), 100)
	AddToggle("groups.friendtags", {
		id = "friendTags.enabled",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_ENABLE", "Friend Tags"),
		desc = T("FRIEND_TAGS_SETTINGS_ENABLE_DESC", "Adds Blizzard-compatible and custom tags for friends."),
		default = true,
		order = 100,
		parentCheck = IsContactMemoryEnabledForFriendTags,
		getValue = function()
			return GetFriendTagSetting("enabled", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("enabled", value == true)
		end,
		refreshOnChange = true,
	})
	AddToggle("groups.friendtags", {
		id = "friendTags.showRowChips",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_ROW_CHIPS", "Show Row Chips"),
		desc = T("FRIEND_TAGS_SETTINGS_ROW_CHIPS_DESC", "Show friend tags as compact chips below the friend info line."),
		default = true,
		order = 110,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("showRowChips", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("showRowChips", value == true)
		end,
		refreshOnChange = true,
	})
	AddSlider("groups.friendtags", {
		id = "friendTags.maxRowChips",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_MAX_ROW_CHIPS", "Maximum Row Chips"),
		desc = T("FRIEND_TAGS_SETTINGS_MAX_ROW_CHIPS_DESC", "Limits how many tags are shown in each friend row before using a +count chip."),
		min = 1,
		max = 4,
		step = 1,
		default = 3,
		integer = true,
		order = 120,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("maxRowChips", 3)
		end,
		setValue = function(value)
			SetFriendTagSetting("maxRowChips", value)
		end,
	})
	AddDropdown("groups.friendtags", {
		id = "friendTags.compactRowMode",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_COMPACT_MODE", "Compact Row Chips"),
		desc = T("FRIEND_TAGS_SETTINGS_COMPACT_MODE_DESC", "Controls how friend tags are shown when Compact Mode is enabled."),
		list = {
			hidden = T("FRIEND_TAGS_COMPACT_HIDDEN", "Hidden"),
			icon_only = T("FRIEND_TAGS_COMPACT_ICON_ONLY", "Icon Only"),
			chip_line = T("FRIEND_TAGS_COMPACT_CHIP_LINE", "Chip Line"),
		},
		orderList = { "icon_only", "chip_line", "hidden" },
		default = "icon_only",
		order = 125,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("compactRowMode", "icon_only")
		end,
		setValue = function(value)
			SetFriendTagSetting("compactRowMode", value or "icon_only")
		end,
	})
	AddToggle("groups.friendtags", {
		id = "friendTags.showTooltipChips",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_TOOLTIPS", "Show in Tooltips"),
		desc = T("FRIEND_TAGS_SETTINGS_TOOLTIPS_DESC", "Include friend tags in Notes & Tags tooltip sections."),
		default = true,
		order = 130,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("showTooltipChips", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("showTooltipChips", value == true)
		end,
	})
	AddSlider("groups.friendtags", {
		id = "friendTags.maxTooltipChips",
		group = "general",
		label = T("FRIEND_TAGS_SETTINGS_MAX_TOOLTIP_CHIPS", "Maximum Tooltip Tags"),
		desc = T("FRIEND_TAGS_SETTINGS_MAX_TOOLTIP_CHIPS_DESC", "Limits how many tags are listed in Notes & Tags tooltips."),
		min = 1,
		max = 12,
		step = 1,
		default = 8,
		integer = true,
		order = 140,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("maxTooltipChips", 8)
		end,
		setValue = function(value)
			SetFriendTagSetting("maxTooltipChips", value)
		end,
	})

	AddGroup("groups.friendtags", "search", T("FRIEND_TAGS_SETTINGS_SEARCH", "Search & Privacy"), 200)
	AddToggle("groups.friendtags", {
		id = "friendTags.includeBlizzardTagsInSearch",
		group = "search",
		label = T("FRIEND_TAGS_SETTINGS_SEARCH_BLIZZARD", "Search Blizzard Tags"),
		desc = T("FRIEND_TAGS_SETTINGS_SEARCH_BLIZZARD_DESC", "Let friend list search match Blizzard-compatible tags."),
		default = true,
		order = 200,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("includeBlizzardTagsInSearch", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("includeBlizzardTagsInSearch", value == true)
		end,
	})
	AddToggle("groups.friendtags", {
		id = "friendTags.includeCustomTagsInSearch",
		group = "search",
		label = T("FRIEND_TAGS_SETTINGS_SEARCH_CUSTOM", "Search Custom Tags"),
		desc = T("FRIEND_TAGS_SETTINGS_SEARCH_CUSTOM_DESC", "Let friend list search match BetterFriendlist custom tags."),
		default = true,
		order = 210,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("includeCustomTagsInSearch", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("includeCustomTagsInSearch", value == true)
		end,
	})
	AddToggle("groups.friendtags", {
		id = "friendTags.showTagsInStreamerMode",
		group = "search",
		label = T("FRIEND_TAGS_SETTINGS_STREAMER", "Show in Streamer Mode"),
		desc = T("FRIEND_TAGS_SETTINGS_STREAMER_DESC", "Keep friend tags visible while Streamer Mode is active."),
		default = false,
		order = 220,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("showTagsInStreamerMode", false) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("showTagsInStreamerMode", value == true)
		end,
	})
	AddToggle("groups.friendtags", {
		id = "friendTags.showBrokerChips",
		group = "search",
		label = T("FRIEND_TAGS_SETTINGS_BROKER", "Show in Broker Tooltips"),
		desc = T("FRIEND_TAGS_SETTINGS_BROKER_DESC", "Allow broker integrations to include friend tags where supported."),
		default = true,
		order = 230,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("showBrokerChips", true) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("showBrokerChips", value == true)
		end,
	})

	AddGroup("groups.friendtags", "groups", T("FRIEND_TAGS_SETTINGS_GROUPS", "Dynamic Tag Groups"), 300)
	AddToggle("groups.friendtags", {
		id = "friendTags.enableDynamicTagGroups",
		group = "groups",
		label = T("FRIEND_TAGS_SETTINGS_DYNAMIC_GROUPS", "Show Dynamic Tag Groups"),
		desc = T("FRIEND_TAGS_SETTINGS_DYNAMIC_GROUPS_DESC", "Shows optional tag-based groups without changing existing custom groups."),
		default = false,
		order = 300,
		parentCheck = IsFriendTagsEnabled,
		getValue = function()
			return GetFriendTagSetting("enableDynamicTagGroups", false) == true
		end,
		setValue = function(value)
			SetFriendTagSetting("enableDynamicTagGroups", value == true)
		end,
		refreshOnChange = true,
	})

	AddGroup("groups.friendtags", "editor", T("FRIEND_TAGS_SETTINGS_EDITOR", "Tag Editor"), 400)
	AddButton("groups.friendtags", {
		id = "friendTags.openEditor",
		group = "editor",
		label = T("FRIEND_TAGS_EDITOR_TITLE", "Friend Tags & Chips"),
		desc = T("FRIEND_TAGS_EDITOR_DESC", "Edit chip labels, icons, colors, visibility, custom tags, and order."),
		buttonText = T("FRIEND_TAGS_EDITOR_OPEN", "Open Editor"),
		order = 400,
		parentCheck = IsFriendTagsEnabled,
		onClick = function()
			OpenFriendTagEditor()
		end,
	})
	AddButton("groups.friendtags", {
		id = "friendTags.syncLocalBlizzard",
		group = "editor",
		label = T("FRIEND_TAGS_SYNC_LOCAL_TITLE", "Sync Local Blizzard-compatible Tags"),
		desc = T("FRIEND_TAGS_SYNC_LOCAL_DESC", "Transfers locally stored 12.0.7 Blizzard-compatible tags for currently known Battle.net friends to Blizzard when the 12.1 API is available."),
		buttonText = T("FRIEND_TAGS_SYNC_LOCAL_BUTTON", "Sync Known Friends"),
		order = 410,
		parentCheck = function()
			local FriendTags = GetFriendTagsModule()
			return IsFriendTagsEnabled() and FriendTags and FriendTags.AreBlizzardTagsEnabled and FriendTags:AreBlizzardTagsEnabled()
		end,
		onClick = SyncKnownBlizzardTags,
	})
	AddReorderList("groups.friendtags", {
		id = "friendTags.tagList",
		group = "editor",
		label = T("FRIEND_TAGS_SETTINGS_TAG_LIST", "Tags"),
		desc = T("FRIEND_TAGS_SETTINGS_TAG_LIST_DESC", "Change tag order, visibility, and open the full chip editor."),
		order = 430,
		getEntries = BuildFriendTagEntries,
		moveEntry = MoveFriendTagEntry,
		emptyText = T("FRIEND_TAGS_SETTINGS_TAG_LIST_EMPTY", "No tags available."),
		entryToggle = {
			getValue = function(tagId)
				local FriendTags = GetFriendTagsModule()
				local profile = FriendTags and FriendTags:GetChipProfile(tagId)
				return profile and profile.visible ~= false
			end,
			setValue = function(tagId, _, value)
				local FriendTags = GetFriendTagsModule()
				if FriendTags then
					FriendTags:SetChipProfile(tagId, { visible = value == true }, RefreshFriends)
				end
			end,
		},
		rowActions = {
			{
				id = "edit",
				label = T("FRIEND_TAGS_EDITOR_EDIT", "Edit"),
				onClick = function(tagId)
					OpenFriendTagEditor(tagId)
				end,
			},
			{
				id = "reset",
				label = T("FRIEND_TAGS_EDITOR_RESET", "Reset"),
				onClick = function(tagId)
					local FriendTags = GetFriendTagsModule()
					if FriendTags then
						FriendTags:ResetChipProfile(tagId, RefreshFriends)
					end
				end,
			},
			{
				id = "delete",
				label = T("FRIEND_TAGS_EDITOR_DELETE", "Delete"),
				visibleWhen = function(entry)
					return entry and entry.source == "custom"
				end,
				onClick = function(tagId)
					local FriendTags = GetFriendTagsModule()
					if FriendTags then
						FriendTags:DeleteCustomTag(tagId, RefreshFriends)
					end
				end,
			},
		},
	})
end

local function RegisterGroupsPages()
	RegisterPage({ id = "groups.builtins", category = "groups", title = T("SETTINGS_CENTER_PAGE_GROUPS_BUILTINS", "Built-In Groups"), description = T("SETTINGS_CENTER_PAGE_GROUPS_BUILTINS_DESC", "Controls automatic BetterFriendlist groups."), iconKey = "bfl-groups-builtins", order = 100 })
	AddGroup("groups.builtins", "builtin", T("SETTINGS_GROUP_MANAGEMENT", "Group Management"), 100)
	AddToggle("groups.builtins", { key = "showFavoritesGroup", group = "builtin", label = string.format(T("SETTINGS_SHOW_GROUP_FMT", "Show %s Group"), T("GROUP_FAVORITES", "Favorites")), default = true, order = 100, method = "OnShowFavoritesGroupChanged" })
	AddToggle("groups.builtins", { key = "hideEmptyGroups", group = "builtin", label = T("SETTINGS_HIDE_EMPTY_GROUPS", "Hide Empty Groups"), desc = T("SETTINGS_HIDE_EMPTY_GROUPS_DESC", "Automatically hides groups that have no online members."), default = false, order = 110, method = "OnHideEmptyGroupsChanged" })
	AddToggle("groups.builtins", { key = "enableInGameGroup", group = "builtin", label = T("SETTINGS_ENABLE_IN_GAME_GROUP", "Enable In-Game Group"), desc = T("SETTINGS_ENABLE_IN_GAME_GROUP_DESC", "Show a dynamic group for friends currently in game."), default = false, order = 120, method = "OnEnableInGameGroupChanged", refreshOnChange = true })
	AddDropdown("groups.builtins", { key = "inGameGroupMode", group = "builtin", label = T("SETTINGS_IN_GAME_GROUP_MODE", "In-Game Group Mode"), list = { same_game = T("SETTINGS_IN_GAME_GROUP_SAME_GAME", "Same WoW Version"), any_game = T("SETTINGS_IN_GAME_GROUP_ANY_GAME", "Any Battle.net Game") }, orderList = { "same_game", "any_game" }, default = "same_game", order = 130, parentCheck = function() return GetDB("enableInGameGroup", false) end, method = "OnInGameGroupModeChanged" })
	AddToggle("groups.builtins", { key = "enableRecentlyAddedGroup", group = "builtin", label = T("SETTINGS_ENABLE_RECENTLY_ADDED_GROUP", "Enable Recently Added Group"), desc = T("SETTINGS_ENABLE_RECENTLY_ADDED_GROUP_DESC", "Track recently discovered friends in a temporary group."), default = false, order = 140, method = "OnEnableRecentlyAddedGroupChanged", refreshOnChange = true })
	AddDropdown("groups.builtins", { key = "recentlyAddedDurationUnit", group = "builtin", label = T("SETTINGS_RECENTLY_ADDED_DURATION_UNIT", "Recently Added Unit"), list = { minutes = T("SETTINGS_RECENTLY_ADDED_MINUTES", "Minutes"), hours = T("SETTINGS_RECENTLY_ADDED_HOURS", "Hours"), days = T("SETTINGS_RECENTLY_ADDED_DAYS", "Days") }, orderList = { "minutes", "hours", "days" }, default = "days", order = 150, parentCheck = function() return GetDB("enableRecentlyAddedGroup", false) end, method = "OnRecentlyAddedDurationUnitChanged" })
	AddSlider("groups.builtins", { key = "recentlyAddedDurationValue", group = "builtin", label = T("SETTINGS_RECENTLY_ADDED_DURATION_VALUE", "Recently Added Duration"), min = 1, max = 30, step = 1, default = 7, integer = true, order = 160, parentCheck = function() return GetDB("enableRecentlyAddedGroup", false) end, setValue = function(value) SetViaSettings("recentlyAddedDurationValue", value, "OnRecentlyAddedDurationValueChanged") end })

	RegisterPage({ id = "groups.headers", category = "groups", title = T("SETTINGS_CENTER_PAGE_GROUPS_HEADERS", "Headers"), description = T("SETTINGS_CENTER_PAGE_GROUPS_HEADERS_DESC", "Controls group header counts, arrows, and alignment."), iconKey = "bfl-groups-headers", order = 110 })
	AddGroup("groups.headers", "headers", T("SETTINGS_GROUP_HEADER_SETTINGS", "Group Header Settings"), 100)
	AddDropdown("groups.headers", { key = "headerCountFormat", group = "headers", label = T("SETTINGS_HEADER_COUNT_FORMAT", "Count Format"), list = { visible = T("SETTINGS_HEADER_COUNT_VISIBLE", "Visible"), online = T("SETTINGS_HEADER_COUNT_ONLINE", "Online"), both = T("SETTINGS_HEADER_COUNT_BOTH", "Visible / Online") }, orderList = { "visible", "online", "both" }, default = "visible", order = 100, after = RefreshFriends })
	AddDropdown("groups.headers", { key = "groupHeaderAlign", group = "headers", label = T("SETTINGS_GROUP_HEADER_ALIGN", "Header Alignment"), list = { LEFT = T("ALIGN_LEFT", "Left"), CENTER = T("ALIGN_CENTER", "Center"), RIGHT = T("ALIGN_RIGHT", "Right") }, orderList = { "LEFT", "CENTER", "RIGHT" }, default = "LEFT", order = 110, after = RefreshFriends })
	AddToggle("groups.headers", { key = "showGroupArrow", group = "headers", label = T("SETTINGS_SHOW_GROUP_ARROW", "Show Group Arrow"), default = true, order = 120, after = RefreshFriends, refreshOnChange = true })
	AddDropdown("groups.headers", { key = "groupArrowAlign", group = "headers", label = T("SETTINGS_GROUP_ARROW_ALIGN", "Arrow Alignment"), list = { LEFT = T("ALIGN_LEFT", "Left"), CENTER = T("ALIGN_CENTER", "Center"), RIGHT = T("ALIGN_RIGHT", "Right") }, orderList = { "LEFT", "CENTER", "RIGHT" }, default = "LEFT", order = 130, parentCheck = function() return GetDB("showGroupArrow", true) end, after = RefreshFriends })

	RegisterPage({
		id = "groups.order",
		category = "groups",
		title = T("SETTINGS_CENTER_PAGE_GROUPS_ORDER", "Group Order"),
		description = T("SETTINGS_CENTER_GROUP_ORDER_DESC", "Controls custom group order and group header colors."),
		layout = "custom",
		iconKey = "bfl-groups-order",
		order = 120,
		newTagID = "groups.order",
		searchEntries = {
			{ id = "groups.order.order", label = T("SETTINGS_GROUP_ORDER", "Group Order"), keywords = { "group", "order", "sort" }, newTagID = "groups.order" },
			{ id = "groups.order.colors", label = T("SETTINGS_COLORS", "Colors"), keywords = { "group", "color", "count", "arrow" }, newTagID = "groups.order" },
		},
		getHeight = GetGroupOrderPageHeight,
		render = RenderGroupOrderCustomPage,
	})

	RegisterPage({
		id = "groups.sorting",
		category = "groups",
		title = T("SETTINGS_CENTER_PAGE_GROUPS_SORTING", "Default Sorting & Filters"),
		description = T("SETTINGS_CENTER_PAGE_GROUPS_SORTING_DESC", "Sets the default QuickFilter and sorters used by the Friendlist."),
		layout = "custom",
		iconKey = "bfl-groups-order",
		order = 130,
		newTagID = "groups.quickfilter.editor",
		searchEntries = {
			{ id = "groups.sorting.quickFilter", label = T("SETTINGS_QUICK_FILTER", "QuickFilter"), keywords = { "default", "filter", "quickfilter" }, focusID = "quickFilter" },
			{ id = "groups.sorting.primarySort", label = T("SETTINGS_PRIMARY_SORT", "Primary Sort"), keywords = { "default", "sort", "primary" }, focusID = "primarySort" },
			{ id = "groups.sorting.secondarySort", label = T("SETTINGS_SECONDARY_SORT", "Secondary Sort"), keywords = { "default", "sort", "secondary" }, focusID = "secondarySort" },
		},
		getHeight = GetSortingDefaultsPageHeight,
		render = RenderSortingDefaultsCustomPage,
	})
	RegisterSortingControls()
	RegisterFriendTagsControls()
	RegisterPage({
		id = "groups.quickfilter",
		category = "groups",
		title = T("SETTINGS_CENTER_PAGE_QUICKFILTER_EDITOR", "QuickFilter & Sorter Editor"),
		description = T("SETTINGS_CENTER_QUICKFILTER_EDITOR_DESC", "Create, order, preview, and edit custom QuickFilters and sorters."),
		layout = "custom",
		iconKey = "bfl-groups-order",
		order = 140,
		visibleWhen = IsBetaEnabled,
		newTagID = "groups.quickfilter.editor",
		getSettingCount = GetFilterSortManagerSettingCount,
		searchEntries = {
			{ id = "groups.quickfilter.filters", label = T("FILTER_BUILDER_FILTERS", "QuickFilters"), keywords = { "filter", "quickfilter", "rule builder" }, focusID = "filter", newTagID = "groups.quickfilter.editor" },
			{ id = "groups.quickfilter.sorters", label = T("FILTER_BUILDER_SORTERS", "Sorters"), keywords = { "sort", "sorter", "sorting" }, focusID = "sorter" },
		},
		getHeight = GetFilterSortCustomPageHeight,
		render = RenderFilterSortOverviewPage,
	})
	RegisterPage({
		id = "groups.quickfilter.entry",
		category = "groups",
		title = T("SETTINGS_CENTER_PAGE_QUICKFILTER_ENTRY", "Edit QuickFilter / Sorter"),
		description = T("SETTINGS_CENTER_PAGE_QUICKFILTER_ENTRY_DESC", "Edit the selected QuickFilter or sorter with full-width controls."),
		layout = "custom",
		iconKey = "bfl-groups-order",
		order = 145,
		visibleWhen = IsBetaEnabled,
		newTagID = "groups.quickfilter.editor",
		settingCount = 1,
		searchEntries = {
			{ id = "groups.quickfilter.createFilter", label = T("FILTER_BUILDER_CREATE_FILTER_TITLE", "Create QuickFilter"), keywords = { "new", "create", "filter" }, focusID = "create-filter" },
			{ id = "groups.quickfilter.createSorter", label = T("FILTER_BUILDER_CREATE_SORTER_TITLE", "Create Sorter"), keywords = { "new", "create", "sorter" }, focusID = "create-sorter" },
		},
		getHeight = GetFilterSortCustomPageHeight,
		render = RenderFilterSortEntryPage,
	})
end

local function RegisterSocialPages()
	RegisterPage({ id = "social.who", category = "social", title = T("SETTINGS_CENTER_PAGE_SOCIAL_WHO", "Who"), iconKey = "bfl-social-who", order = 100 })
	AddGroup("social.who", "who", T("SETTINGS_TAB_WHO", "Who"), 100)
	AddToggle("social.who", { key = "whoShowClassIcons", group = "who", label = T("SETTINGS_WHO_SHOW_CLASS_ICONS", "Show Class Icons"), default = true, order = 100, after = RefreshFriends })
	AddToggle("social.who", { key = "whoClassColorNames", group = "who", label = T("SETTINGS_WHO_CLASS_COLOR_NAMES", "Color Names by Class"), default = true, order = 110, after = RefreshFriends })
	AddToggle("social.who", { key = "whoLevelColors", group = "who", label = T("SETTINGS_WHO_LEVEL_COLORS", "Color Levels"), default = true, order = 120, after = RefreshFriends })
	AddToggle("social.who", { key = "whoZebraStripes", group = "who", label = T("SETTINGS_WHO_ZEBRA_STRIPES", "Alternating Rows"), default = true, order = 130, after = RefreshFriends })
	AddDropdown("social.who", { key = "whoDoubleClickAction", group = "who", label = T("SETTINGS_WHO_DOUBLE_CLICK_ACTION", "Double-Click Action"), list = { whisper = WHISPER or "Whisper", invite = INVITE or "Invite", inspect = INSPECT or "Inspect" }, orderList = { "whisper", "invite", "inspect" }, default = "whisper", order = 140 })

	RegisterPage({ id = "social.raid", category = "social", title = T("SETTINGS_CENTER_PAGE_SOCIAL_RAID", "Raid"), iconKey = "bfl-social-raid", mainToggleID = "enableReadyCheckButton", order = 110 })
	AddGroup("social.raid", "raid", T("SETTINGS_RAID_SHORTCUTS_TITLE", "Raid Shortcuts"), 100)
	AddToggle("social.raid", { key = "enableReadyCheckButton", group = "raid", label = T("SETTINGS_RAID_ENABLE_READY_CHECK_BUTTON", "Enable Ready Check Button"), desc = T("SETTINGS_RAID_ENABLE_READY_CHECK_BUTTON_DESC", "Show a compact ready check button next to Raid Info in the Raid tab."), default = false, order = 100, after = RefreshFriends })
	AddToggle("social.raid", { key = "raidShortcutEnabled_mainTank", group = "raid", label = T("SETTINGS_RAID_ACTION_MAIN_TANK", "Set Main Tank"), default = true, order = 110 })
	AddToggle("social.raid", { key = "raidShortcutEnabled_mainAssist", group = "raid", label = T("SETTINGS_RAID_ACTION_MAIN_ASSIST", "Set Main Assist"), default = true, order = 120 })
	AddToggle("social.raid", { key = "raidShortcutEnabled_lead", group = "raid", label = T("SETTINGS_RAID_ACTION_RAID_LEAD", "Set Raid Leader"), default = true, order = 130 })
	AddToggle("social.raid", { key = "raidShortcutEnabled_promote", group = "raid", label = T("SETTINGS_RAID_ACTION_PROMOTE", "Promote Assistant"), default = true, order = 140 })
	RegisterRaidShortcutControls()

	local AutoRaidAssist = BFL:GetModule("AutoRaidAssist")
	if AutoRaidAssist and AutoRaidAssist.RegisterSettingsDesignerControls then
		AutoRaidAssist:RegisterSettingsDesignerControls(app, {
			pageID = "social.raid",
			groupID = "autoAssist",
			groupOrder = 200,
			order = 200,
		})
	end

	RegisterPage({
		id = "social.raid.autoAssist",
		category = "social",
		title = T("AUTO_RAID_ASSIST_TITLE", "Auto Raid Assist"),
		description = T(
			"AUTO_RAID_ASSIST_DESC",
			"Automatically promote selected friends and characters to raid assistant when they join your raid."
		),
		iconKey = "bfl-social-auto-raid-assist",
		mainToggleID = "autoRaidAssist.enabled.detail",
		order = 115,
		newTagID = "raid-auto-assist",
		keywords = { "raid", "assistant", "assist", "promote", "battletag", "nickname", "character", "realm" },
	})
	if AutoRaidAssist and AutoRaidAssist.RegisterSettingsDesignerControls then
		AutoRaidAssist:RegisterSettingsDesignerControls(app, {
			pageID = "social.raid.autoAssist",
			groupID = "autoAssistDetails",
			groupOrder = 100,
			order = 100,
			enabledControlID = "autoRaidAssist.enabled.detail",
			includeManageButton = false,
			includeEditor = true,
			editorOrder = 110,
		})
	end

	local function BuildGuildOptionList(options, fallbackList, fallbackOrder)
		local list = {}
		local orderList = {}
		if type(options) == "table" then
			for _, option in ipairs(options) do
				if option.value ~= nil then
					list[option.value] = option.text or tostring(option.value)
					orderList[#orderList + 1] = option.value
				end
			end
		end
		if #orderList == 0 then
			return fallbackList, fallbackOrder
		end
		return list, orderList
	end

	local guildActions = BFL:GetModule("GuildActions")
	local guildFilterList, guildFilterOrder = BuildGuildOptionList(
		guildActions and guildActions.GetFilterOptions and guildActions:GetFilterOptions(),
		{ online = FRIENDS_LIST_ONLINE or "Online", all = ALL or "All", offline = FRIENDS_LIST_OFFLINE or "Offline" },
		{ "online", "all", "offline" }
	)
	local guildSortList, guildSortOrder = BuildGuildOptionList(
		guildActions and guildActions.GetSortOptions and guildActions:GetSortOptions(),
		{ rank = RANK or "Rank", name = NAME or "Name", level = LEVEL or "Level", class = CLASS or "Class", zone = ZONE or "Zone", nickname = T("GUILD_NICKNAME", "Nickname"), status = STATUS or "Status", lastonline = LASTONLINE or "Last Online" },
		{ "rank", "name", "level", "class", "zone", "nickname", "status", "lastonline" }
	)

	RegisterPage({ id = "social.guild", category = "social", title = T("SETTINGS_CENTER_PAGE_SOCIAL_GUILD", GUILD or "Guild"), iconKey = "bfl-social-guild", mainToggleID = "enableGuildTab", order = 120, visibleWhen = IsGuildTabVisible, newTagID = "social.guild" })
	AddGroup("social.guild", "guild", T("SETTINGS_GUILD_ROSTER_HEADER", "Roster Defaults"), 100)
	AddToggle("social.guild", { key = "enableGuildTab", group = "guild", label = T("SETTINGS_ENABLE_GUILD_TAB", "Enable Guild Tab"), desc = T("SETTINGS_ENABLE_GUILD_TAB_DESC", "Show the BetterFriendlist Guild tab."), default = false, order = 100, method = "OnEnableGuildTabChanged", refreshOnChange = true, newTagID = "enableGuildTab" })
	AddDropdown("social.guild", { key = "guildTabFilterMode", group = "guild", label = T("SETTINGS_GUILD_DEFAULT_FILTER", "Default Filter"), list = guildFilterList, orderList = guildFilterOrder, default = "online", order = 110, after = RefreshGuild })
	AddDropdown("social.guild", { key = "guildTabSortMode", group = "guild", label = T("SETTINGS_GUILD_DEFAULT_SORT", "Default Sort"), list = guildSortList, orderList = guildSortOrder, default = "rank", order = 120, after = RefreshGuild })
	AddToggle("social.guild", { key = "guildTabShowClassIcons", group = "guild", label = T("SETTINGS_GUILD_SHOW_CLASS_ICONS", "Show Class Icons"), default = true, order = 130, after = RefreshGuild })
	AddToggle("social.guild", { key = "guildTabUseNicknames", group = "guild", label = T("SETTINGS_GUILD_USE_NICKNAMES", "Use BFL Guild Nicknames"), default = true, order = 140, after = RefreshGuild })
end

local function RegisterBrokerPages()
	RegisterPage({ id = "broker.friends", category = "broker", title = T("SETTINGS_CENTER_PAGE_BROKER_FRIENDS", "Friends Broker"), iconKey = "bfl-broker-friends", mainToggleID = "brokerEnabled", order = 100 })
	AddGroup("broker.friends", "integration", T("BROKER_SETTINGS_HEADER_INTEGRATION", "Data Broker Integration"), 100)
	AddToggle("broker.friends", { key = "brokerEnabled", group = "integration", label = T("BROKER_SETTINGS_ENABLE", "Enable Data Broker"), desc = T("BROKER_SETTINGS_ENABLE_TOOLTIP", "Enable/Disable Data Broker integration."), default = false, order = 100, requiresReload = true, reloadReason = T("SETTINGS_CENTER_RELOAD_REQUIRED", "This change requires a UI reload.\n\nReload now?"), refreshOnChange = true })
	AddToggle("broker.friends", { key = "brokerShowIcon", group = "integration", label = T("BROKER_SETTINGS_SHOW_ICON", "Show Icon"), default = true, order = 110, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.friends", { key = "brokerShowLabel", group = "integration", label = T("BROKER_SETTINGS_SHOW_LABEL", "Show Label"), default = true, order = 120, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.friends", { key = "brokerShowTotal", group = "integration", label = T("BROKER_SETTINGS_SHOW_TOTAL", "Show Total Count"), default = true, order = 130, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.friends", { key = "brokerShowGroups", group = "integration", label = T("BROKER_SETTINGS_SHOW_GROUPS", "Split WoW and BNet Friend Counts"), default = false, order = 140, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.friends", { key = "brokerShowWoWIcon", group = "integration", label = T("BROKER_SETTINGS_SHOW_WOW_ICON", "Show WoW Icon"), default = true, order = 145, parentCheck = function() return GetDB("brokerEnabled", false) and GetDB("brokerShowGroups", false) end, after = RefreshBrokerDisplays })
	AddToggle("broker.friends", { key = "brokerShowBNetIcon", group = "integration", label = T("BROKER_SETTINGS_SHOW_BNET_ICON", "Show Battle.net Icon"), default = true, order = 146, parentCheck = function() return GetDB("brokerEnabled", false) and GetDB("brokerShowGroups", false) end, after = RefreshBrokerDisplays })
	AddDropdown("broker.friends", { key = "brokerTooltipMode", group = "integration", label = T("BROKER_SETTINGS_TOOLTIP_MODE", "Tooltip Mode"), list = { basic = T("BROKER_TOOLTIP_BASIC", "Basic"), advanced = T("BROKER_TOOLTIP_ADVANCED", "Advanced") }, orderList = { "basic", "advanced" }, default = "advanced", order = 150, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	local brokerClickActions = { toggle = T("BROKER_CLICK_TOGGLE", "Toggle Friends"), friends = T("BROKER_CLICK_FRIENDS", "Open Friends"), settings = T("BROKER_CLICK_SETTINGS", "Open Settings") }
	local brokerClickActionOrder = { "toggle", "friends", "settings" }
	AddDropdown("broker.friends", { key = "brokerClickAction", group = "integration", label = T("BROKER_SETTINGS_CLICK_ACTION", "Click Action"), list = brokerClickActions, orderList = brokerClickActionOrder, default = "toggle", order = 160, parentCheck = function() return GetDB("brokerEnabled", false) end })
	AddToggle("broker.friends", { key = "brokerShowHints", group = "integration", label = T("BROKER_SETTINGS_SHOW_HINTS", "Show Tooltip Hints"), default = true, order = 170, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.friends", { key = "brokerShowClassIcons", group = "integration", label = T("BROKER_SETTINGS_SHOW_CLASS_ICONS", "Show Class Icons"), default = false, order = 180, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddDropdown("broker.friends", { key = "brokerGroupHeaderAlign", group = "integration", label = T("BROKER_SETTINGS_GROUP_HEADER_ALIGN", "Group Name Alignment"), list = { LEFT = T("ALIGN_LEFT", "Left"), CENTER = T("ALIGN_CENTER", "Center"), RIGHT = T("ALIGN_RIGHT", "Right") }, orderList = { "LEFT", "CENTER", "RIGHT" }, default = "LEFT", order = 190, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddGroup("broker.friends", "tooltip", T("BROKER_SETTINGS_TOOLTIP_HEADER", "Tooltip"), 200)
	AddDropdown("broker.friends", { key = "brokerFont", group = "tooltip", label = T("SETTINGS_FONT", "Font:"), desc = T("SETTINGS_FONT_TOOLTIP", "Choose a font."), listFunc = GetFontOptions, default = "Friz Quadrata TT", order = 200, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddSlider("broker.friends", { key = "brokerFontSize", group = "tooltip", label = T("SETTINGS_FONT_SIZE_NUM", "Font Size:"), min = 8, max = 24, step = 1, default = 12, integer = true, order = 210, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddFontFlags("broker.friends", "brokerFontFlags", "tooltip", 220, function() return GetDB("brokerEnabled", false) end)
	AddToggle("broker.friends", { key = "brokerUseCustomFontForNonLatin", group = "tooltip", label = T("BROKER_SETTINGS_USE_CUSTOM_FONT_NON_LATIN", "Use Custom Font for Non-Latin"), default = false, order = 230, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddColor("broker.friends", { key = "brokerSeparatorColor", group = "tooltip", label = T("BROKER_SETTINGS_SEPARATOR_COLOR", "Separator Color"), default = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }, hasOpacity = true, order = 240, parentCheck = function() return GetDB("brokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddGroup("broker.friends", "columns", T("BROKER_SETTINGS_COLUMNS_HEADER", "Tooltip Columns"), 300)
	RegisterBrokerColumnControls("broker.friends", "columns", FRIEND_BROKER_COLUMNS, {
		visibilityPrefix = "brokerShowCol",
		orderID = "broker.columns.order",
		orderLabel = T("BROKER_SETTINGS_COLUMN_ORDER", "Column Order"),
		orderDesc = T("SETTINGS_CENTER_BROKER_COLUMN_ORDER_VISIBILITY_DESC", "Move columns to change their display order and use the checkboxes to show or hide them."),
		orderKey = "brokerColumnOrder",
		iconKey = "bfl-broker-friends",
		order = 300,
		parentCheck = function() return GetDB("brokerEnabled", false) end,
	})
	RegisterBrokerColorControls("broker.friends", "columns", BROKER_COLOR_ENTRIES, 320, function() return GetDB("brokerEnabled", false) end)

	RegisterPage({ id = "broker.guild", category = "broker", title = T("SETTINGS_CENTER_PAGE_BROKER_GUILD", "Guild Broker"), iconKey = "bfl-broker-guild", mainToggleID = "guildBrokerEnabled", order = 110 })
	AddGroup("broker.guild", "guildBroker", T("GUILD_BROKER_SETTINGS_HEADER", "Guild Plugin"), 100)
	AddToggle("broker.guild", { key = "guildBrokerEnabled", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_ENABLE", "Enable Guild Broker"), desc = T("GUILD_BROKER_SETTINGS_ENABLE_DESC", "Show guild member data in your Data Broker display addon."), default = false, order = 100, requiresReload = true, reloadReason = T("SETTINGS_CENTER_RELOAD_REQUIRED", "This change requires a UI reload.\n\nReload now?"), refreshOnChange = true })
	AddToggle("broker.guild", { key = "guildBrokerShowIcon", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_ICON", "Show Icon"), default = true, order = 110, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerShowLabel", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_LABEL", "Show Label"), default = true, order = 120, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerShowTotal", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_TOTAL", "Show Total Count"), default = true, order = 130, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerShowApplicants", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_APPLICANTS", "Show Applicant Count"), default = true, order = 140, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerShowHints", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_HINTS", "Show Hints"), default = true, order = 145, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddDropdown("broker.guild", { key = "guildBrokerTooltipMode", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_TOOLTIP_MODE", "Tooltip Mode"), list = { basic = T("BROKER_TOOLTIP_BASIC", "Basic"), advanced = T("BROKER_TOOLTIP_ADVANCED", "Advanced") }, orderList = { "basic", "advanced" }, default = "advanced", order = 150, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerDisplays })
	AddDropdown("broker.guild", { key = "guildBrokerClickAction", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_CLICK_ACTION", "Left Click Action"), list = { guild_tab = T("GUILD_BROKER_ACTION_GUILD_FRAME", "Open Guild Tab"), settings = T("GUILD_BROKER_ACTION_SETTINGS", "Open Settings") }, orderList = { "guild_tab", "settings" }, default = "guild_tab", order = 160, parentCheck = function() return GetDB("guildBrokerEnabled", false) end })
	AddDropdown("broker.guild", { key = "guildBrokerGroupMode", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_GROUP_MODE", "Group Mode"), list = { none = NONE or "None", by_rank = RANK or "Rank", by_class = CLASS or "Class" }, orderList = { "none", "by_rank", "by_class" }, default = "none", order = 170, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddDropdown("broker.guild", { key = "guildBrokerFilter", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_FILTER", "Default Filter"), list = { all = ALL or "All", online = FRIENDS_LIST_ONLINE or "Online" }, orderList = { "online", "all" }, default = "online", order = 180, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddSlider("broker.guild", { key = "guildBrokerMaxRows", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_MAX_ROWS", "Maximum Rows"), desc = T("GUILD_BROKER_SETTINGS_MAX_ROWS_DESC", "Limit tooltip rows for large guilds."), min = 25, max = 200, step = 5, default = 100, integer = true, order = 190, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerHideLevelAtMax", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_HIDE_LEVEL_AT_MAX", "Hide Level at Max"), default = false, order = 200, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerShowClassIcons", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SHOW_CLASS_ICONS", "Show Class Icons"), default = false, order = 210, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddToggle("broker.guild", { key = "guildBrokerExcludeSelf", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_EXCLUDE_SELF", "Exclude Yourself"), default = false, order = 220, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddDropdown("broker.guild", { key = "guildBrokerSortMode", group = "guildBroker", label = T("GUILD_BROKER_SETTINGS_SORT_MODE", "Sort Mode"), list = { name = NAME or "Name", rank = RANK or "Rank", level = LEVEL or "Level", class = CLASS or "Class", zone = ZONE or "Zone", nickname = T("GUILD_NICKNAME", "Nickname") }, orderList = { "name", "rank", "level", "class", "zone", "nickname" }, default = "name", order = 230, parentCheck = function() return GetDB("guildBrokerEnabled", false) end, after = RefreshBrokerTooltips })
	AddGroup("broker.guild", "guildColumns", T("GUILD_BROKER_SETTINGS_COLUMNS", "Tooltip Columns"), 300)
	RegisterBrokerColumnControls("broker.guild", "guildColumns", GUILD_BROKER_COLUMNS, {
		visibilityPrefix = "guildBrokerShowCol",
		orderID = "guildBroker.columns.order",
		orderLabel = T("GUILD_BROKER_SETTINGS_COLUMN_ORDER", "Column Order"),
		orderDesc = T("SETTINGS_CENTER_BROKER_COLUMN_ORDER_VISIBILITY_DESC", "Move columns to change their display order and use the checkboxes to show or hide them."),
		orderKey = "guildBrokerColumnOrder",
		iconKey = "bfl-broker-guild",
		order = 300,
		parentCheck = function() return GetDB("guildBrokerEnabled", false) end,
	})
	AddToggle("broker.guild", {
		id = "guildBrokerNicknameUseClassColor",
		group = "guildColumns",
		label = T("GUILD_BROKER_SETTINGS_NICKNAME_CLASS_COLOR", "Nickname Uses Class Color"),
		default = true,
		order = 320,
		parentCheck = function() return GetDB("guildBrokerEnabled", false) end,
		getValue = function()
			return GetDB("guildBrokerNicknameColor") == nil
		end,
		setValue = function(value)
			if value then
				ClearDB("guildBrokerNicknameColor", RefreshBrokerDisplays)
			else
				SetDB("guildBrokerNicknameColor", { 1, 1, 1 }, RefreshBrokerDisplays)
			end
		end,
		refreshOnChange = true,
	})
	AddColor("broker.guild", {
		id = "guildBrokerNicknameColor",
		group = "guildColumns",
		label = T("GUILD_BROKER_SETTINGS_NICKNAME_COLOR", "Nickname Color"),
		default = { r = 1, g = 1, b = 1, a = 1 },
		order = 330,
		parentCheck = function() return GetDB("guildBrokerEnabled", false) end,
		visibleWhen = function() return GetDB("guildBrokerNicknameColor") ~= nil end,
		getColor = function()
			return GetOptionalArrayColor("guildBrokerNicknameColor")
		end,
		setColor = function(r, g, b, a)
			SetOptionalArrayColor("guildBrokerNicknameColor", r, g, b, a)
		end,
	})
	RegisterBrokerColorControls("broker.guild", "guildColumns", GUILD_BROKER_COLOR_ENTRIES, 340, function() return GetDB("guildBrokerEnabled", false) end)

	RegisterPage({ id = "broker.sync", category = "broker", title = T("SETTINGS_CENTER_PAGE_SYNC", "Sync"), iconKey = "bfl-broker-sync-page", mainToggleID = "enableGlobalSync", order = 120, newTagID = "broker.sync" })
	AddGroup("broker.sync", "global", T("SETTINGS_TAB_GLOBAL_SYNC", "Global Friend Sync"), 100)
	AddToggle("broker.sync", { key = "enableGlobalSync", group = "global", label = T("SETTINGS_GLOBAL_SYNC_ENABLE", "Enable Global Friend Sync"), desc = T("SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP", "Automatically sync friends from other realms to this character."), default = false, order = 100, after = function(value) local GlobalSync = BFL:GetModule("GlobalSync"); if value and GlobalSync and GlobalSync.OnFriendListUpdate then GlobalSync:OnFriendListUpdate() end end, refreshOnChange = true })
	AddToggle("broker.sync", { key = "enableGlobalSyncDeletion", group = "global", label = T("SETTINGS_GLOBAL_SYNC_DELETION", "Enable Deletion"), desc = T("SETTINGS_GLOBAL_SYNC_DELETION_DESC", "Allow Global Sync to remove friends marked as deleted."), default = false, order = 110, parentCheck = function() return GetDB("enableGlobalSync", false) end })
	AddGroup("broker.sync", "notes", T("SETTINGS_SYNC_GROUPS_HEADER", "Group Note Sync"), 200)
	AddToggle("broker.sync", { key = "syncGroupsToNote", group = "notes", label = T("SETTINGS_SYNC_GROUPS_NOTE", "Sync Groups to Friend Note"), desc = T("SETTINGS_SYNC_GROUPS_NOTE_DESC", "Write group assignments into friend notes using FriendGroups format."), default = false, order = 200, newTagID = "syncGroupsToNote", after = function(value) if value then local NoteSync = BFL:GetModule("NoteSync"); if NoteSync and NoteSync.SyncAllFriends then NoteSync:SyncAllFriends() end else ShowNoteCleanupFrame("Show", "BetterFriendlistNoteCleanupWizard") end end })
	RegisterPage({
		id = "broker.sync.database",
		category = "broker",
		title = T("SETTINGS_CENTER_PAGE_SYNC_DATABASE", "Synced Friends Database"),
		description = T("SETTINGS_CENTER_GLOBAL_SYNC_DATABASE_DESC", "Inspect, restore, remove, and edit synced friend records."),
		layout = "custom",
		iconKey = "bfl-broker-sync-page",
		order = 130,
		newTagID = "broker.sync.database",
		searchEntries = {
			{ id = "broker.sync.database.restore", label = T("TOOLTIP_RESTORE_FRIEND", "Restore Friend"), keywords = { "restore", "deleted", "sync", "friend" }, focusID = "restore" },
			{ id = "broker.sync.database.delete", label = T("TOOLTIP_DELETE_FRIEND", "Delete Friend"), keywords = { "delete", "remove", "sync", "friend" }, focusID = "delete" },
			{ id = "broker.sync.database.note", label = T("TOOLTIP_EDIT_NOTE", "Edit Note"), keywords = { "note", "edit", "sync", "friend" }, focusID = "note" },
		},
		getHeight = function()
			return 620
		end,
		render = RenderGlobalSyncCustomPage,
	})
end

local function RegisterPrivacyPages()
	RegisterPage({ id = "privacy.streamer", category = "privacy", title = T("SETTINGS_CENTER_PAGE_PRIVACY_STREAMER", "Streamer Mode"), iconKey = "bfl-privacy-streamer", mainToggleID = "showStreamerModeButton", order = 100 })
	AddGroup("privacy.streamer", "streamer", T("SETTINGS_TAB_STREAMER", "Streamer Mode"), 100)
	AddToggle("privacy.streamer", { key = "showStreamerModeButton", group = "streamer", label = T("SETTINGS_ENABLE_STREAMER_MODE", "Show Streamer Mode Button"), default = true, order = 100, after = RefreshFriends })
	AddInput("privacy.streamer", { key = "streamerModeHeaderText", group = "streamer", label = T("SETTINGS_STREAMER_HEADER_TEXT", "Header Text"), default = "Streamer Mode", inputWidth = 260, maxChars = 32, order = 110, after = RefreshFriends })
	AddDropdown("privacy.streamer", { key = "streamerModeNameFormat", group = "streamer", label = T("SETTINGS_STREAMER_NAME_FORMAT", "Name Formatting"), desc = T("SETTINGS_STREAMER_NAME_FORMAT_DESC", "Choose how names are displayed in Streamer Mode."), list = { battletag = T("SETTINGS_STREAMER_NAME_FORMAT_BATTLENET", "Force BattleTag"), nickname = T("SETTINGS_STREAMER_NAME_FORMAT_NICKNAME", "Force Nickname"), note = T("SETTINGS_STREAMER_NAME_FORMAT_NOTE", "Force Note") }, orderList = { "battletag", "nickname", "note" }, default = "battletag", order = 120, after = RefreshFriends })

	RegisterPage({ id = "privacy.whisper", category = "privacy", title = T("SETTINGS_CENTER_PAGE_PRIVACY_WHISPER", "Whisper"), iconKey = "bfl-privacy-whisper", mainToggleID = "taintFreeWhisper", order = 110, newTagID = "privacy.whisper" })
	AddGroup("privacy.whisper", "whisper", T("SETTINGS_TAINT_FREE_WHISPER", "Taint-Free Whisper"), 100)
	AddToggle("privacy.whisper", { key = "taintFreeWhisper", group = "whisper", label = T("SETTINGS_TAINT_FREE_WHISPER", "Taint-Free Whisper"), desc = T("SETTINGS_TAINT_FREE_WHISPER_DESC", "Use a custom whisper box to avoid tainting Blizzard chat."), default = false, order = 100, newTagID = "taintFreeWhisper" })
end

local function RegisterAdvancedPages()
	RegisterPage({ id = "advanced.tools", category = "advanced", title = T("SETTINGS_CENTER_PAGE_ADVANCED_TOOLS", "Tools"), iconKey = "bfl-advanced-tools", order = 100 })
	AddGroup("advanced.tools", "migration", T("SETTINGS_MIGRATION_HEADER", "FriendGroups Migration"), 100)
	AddButton("advanced.tools", { id = "migration.friendgroups", group = "migration", label = T("SETTINGS_MIGRATE_BTN", "Migrate FriendGroups"), desc = T("SETTINGS_MIGRATE_TOOLTIP", "Import groups from the FriendGroups addon."), buttonText = T("SETTINGS_MIGRATE_BTN", "Migrate"), order = 100, onClick = function() CallSettings("ShowMigrationDialog") end })
	AddGroup("advanced.tools", "importexport", T("SETTINGS_EXPORT_HEADER", "Export / Import Settings"), 200)
	AddButton("advanced.tools", { id = "export.settings", group = "importexport", label = T("BUTTON_EXPORT", "Export"), desc = T("SETTINGS_EXPORT_TOOLTIP", "Export your groups and friend assignments."), buttonText = T("BUTTON_EXPORT", "Export"), order = 200, onClick = function() CallSettingsDialog("ShowExportDialog", "exportFrame", "BetterFriendlistExportFrame") end })
	AddButton("advanced.tools", { id = "import.settings", group = "importexport", label = T("SETTINGS_IMPORT_BTN", "Import"), desc = T("SETTINGS_IMPORT_TOOLTIP", "Import groups and friend assignments."), buttonText = T("SETTINGS_IMPORT_BTN", "Import"), order = 210, onClick = function() CallSettingsDialog("ShowImportDialog", "importFrame", "BetterFriendlistImportFrame") end })
	AddGroup("advanced.tools", "cleanup", T("WIZARD_HEADER", "Note Cleanup"), 300)
	AddButton("advanced.tools", { id = "cleanup.notes", group = "cleanup", label = T("WIZARD_BTN", "Note Cleanup Wizard"), desc = T("WIZARD_DESC", "Clean up FriendGroups-style suffixes from friend notes."), buttonText = T("WIZARD_BTN", "Note Cleanup Wizard"), order = 300, onClick = function() ShowNoteCleanupFrame("Show", "BetterFriendlistNoteCleanupWizard") end })
	AddButton("advanced.tools", { id = "cleanup.backups", group = "cleanup", label = T("WIZARD_BACKUP_VIEWER", "Backup Viewer"), desc = T("WIZARD_BACKUP_VIEWER_DESC", "Review and restore note cleanup backups."), buttonText = T("WIZARD_BACKUP_VIEWER", "Backup Viewer"), order = 310, onClick = function() ShowNoteCleanupFrame("ShowBackupViewer", "BetterFriendlistNoteBackupViewer") end })

	RegisterPage({ id = "advanced.beta", category = "advanced", title = T("SETTINGS_CENTER_PAGE_ADVANCED_BETA", "Beta Features"), iconKey = "bfl-advanced-beta", mainToggleID = "enableBetaFeatures", order = 110, newTagID = "advanced.beta" })
	AddGroup("advanced.beta", "beta", T("SETTINGS_BETA_FEATURES_TITLE", "Beta Features"), 100)
	AddToggle("advanced.beta", { key = "enableBetaFeatures", group = "beta", label = T("SETTINGS_BETA_FEATURES_ENABLE", "Enable Beta Features"), desc = T("SETTINGS_BETA_FEATURES_TOOLTIP", "Shows experimental BetterFriendlist features."), default = false, order = 100, refreshOnChange = true, skinRefresh = true, newTagID = "advanced.beta" })
	AddToggle("advanced.beta", { key = "enableSettingsCenterBeta", group = "beta", label = T("SETTINGS_ENABLE_SETTINGS_CENTER", "New Settings Center (Beta)"), desc = T("SETTINGS_ENABLE_SETTINGS_CENTER_DESC", "Use the new LibSettingsDesigner Settings Center instead of the classic settings window."), default = false, order = 105, setValue = SetSettingsCenterBetaEnabled, skinRefresh = true, newTagID = "enableSettingsCenterBeta" })
	AddToggle("advanced.beta", { key = "externalMenuBridgeEnabled", group = "beta", label = T("SETTINGS_EXTERNAL_MENU_BRIDGE", "External Menu Bridge"), desc = T("SETTINGS_EXTERNAL_MENU_BRIDGE_DESC", "Add supported addon actions to supported BFL context menus."), default = false, order = 110, visibleWhen = function() return IsBetaEnabled() and BFL.HasSecretValues == true end, newTagID = "externalMenuBridgeEnabled" })
	AddToggle("advanced.beta", { key = "debugPrintEnabled", group = "beta", label = T("SETTINGS_DEBUG_PRINT", "Debug Prints"), desc = T("SETTINGS_DEBUG_PRINT_DESC", "Enable verbose BetterFriendlist debug output."), default = false, order = 120, after = function(value) BFL.debugPrintEnabled = value == true end })
	AddGroup("advanced.beta", "available", T("SETTINGS_BETA_FEATURES_LIST", "Currently available Beta Features:"), 200)
	AddBetaFeatureLink({
		id = "quickfilterEditor",
		label = T("SETTINGS_CENTER_PAGE_QUICKFILTER_EDITOR", "QuickFilter & Sorter Editor"),
		desc = T("SETTINGS_CENTER_QUICKFILTER_EDITOR_DESC", "Create, order, preview, and edit custom QuickFilters and sorters."),
		pageID = "groups.quickfilter",
		order = 200,
		keywords = { "beta", "quickfilter", "sorter", "filter", "editor" },
		newTagID = "groups.quickfilter.editor",
	})
	-- Theme Customization used to be listed here while Dark/Custom were beta.
	-- It is now a standard Appearance page and must not be advertised as beta.
	-- Keep QuickFilter, Guild, and Menu Bridge in this beta list.
	-- The Appearance > Theme page is always reachable from Appearance.
	-- Dark and Custom tuning visibility is handled by selected theme.
	-- ElvUI remains conditional through the main theme dropdown.
	-- This preserves the beta dashboard as a list of real beta features.
	-- Retail and Classic share the same Theme page entry point.
	-- The legacy ElvUI checkbox remains hidden after migration.
	-- Saved Dark and Custom selections persist independently from Beta Features.
	-- Do not re-add Theme Customization to advanced.beta.
	AddBetaFeatureLink({
		id = "guildTab",
		label = T("SETTINGS_ENABLE_GUILD_TAB", "Guild Roster Tab (Beta)"),
		desc = T("SETTINGS_ENABLE_GUILD_TAB_DESC", "Shows the Guild roster tab with supported roster and guild-management actions."),
		pageID = "social.guild",
		order = 220,
		visibleWhen = IsGuildTabAvailable,
		keywords = { "beta", "guild", "roster", "tab" },
		newTagID = "social.guild",
	})
	AddBetaFeatureLink({
		id = "externalMenuBridge",
		label = T("SETTINGS_EXTERNAL_MENU_BRIDGE", "External AddOn Menu Bridge (Beta)"),
		desc = T("SETTINGS_EXTERNAL_MENU_BRIDGE_DESC", "Adds compatible AddOn actions to supported BetterFriendlist context menus."),
		pageID = "advanced.beta",
		focusControlID = "externalMenuBridgeEnabled",
		order = 230,
		visibleWhen = function() return BFL.HasSecretValues == true end,
		keywords = { "beta", "context", "menu", "addon", "bridge" },
		newTagID = "externalMenuBridgeEnabled",
	})

end

local function BuildSupportActionEntries()
	local entries = {
		{ type = "text", text = T("SETTINGS_CENTER_SUPPORT_INTRO", "Use these links for support, bug reports, feature requests, or supporting development.") },
	}
	for _, link in ipairs(GetSupportLinks()) do
		local label = link.label
		local url = link.url
		entries[#entries + 1] = {
			type = "button",
			text = label,
			width = 180,
			onClick = function()
				ShowSupportURL(label, url)
			end,
		}
	end
	return entries
end

local function BuildSupportCopyEntries()
	local entries = {}
	for _, link in ipairs(GetSupportLinks()) do
		entries[#entries + 1] = {
			type = "text",
			text = string.format("%s: %s", link.label, link.url or ""),
		}
	end
	return entries
end

local function RegisterHelpPages()
	RegisterPage({ id = "help.changelog", category = "help", title = T("SETTINGS_CENTER_PAGE_CHANGELOG", "Changelog"), description = T("SETTINGS_CENTER_PAGE_CHANGELOG_DESC", "Recent BetterFriendlist release notes."), layout = "info", iconKey = "bfl-help-page", order = 80, content = {
		{
			title = T("SETTINGS_CENTER_CHANGELOG_RELEASE_NOTES", "Release Notes"),
			entries = GetChangelogInfoEntries(),
		},
	} })

	RegisterPage({ id = "help.support", category = "help", title = T("SETTINGS_CENTER_PAGE_SUPPORT_LINKS", "Support Links"), description = T("SETTINGS_CENTER_PAGE_SUPPORT_LINKS_DESC", "Discord, GitHub issues, and Ko-fi."), layout = "info", iconKey = "bfl-help-page", order = 90, content = {
		{
			title = T("SETTINGS_CENTER_HELP_SUPPORT", "Support"),
			entries = BuildSupportActionEntries(),
		},
		{
			title = T("SETTINGS_CENTER_SUPPORT_COPY_LINKS", "Copy Links"),
			entries = BuildSupportCopyEntries(),
		},
	} })

	RegisterPage({ id = "help.about", category = "help", title = T("SETTINGS_CENTER_PAGE_HELP", "Help"), layout = "info", iconKey = "bfl-help-page", order = 100, content = {
		{
			title = T("SETTINGS_CENTER_HELP_SLASH_COMMANDS", "Slash Commands"),
			entries = {
				{ type = "command", commands = { "/bfl settings" }, desc = T("SETTINGS_CENTER_HELP_COMMAND_SETTINGS", "Open the settings center.") },
				{ type = "command", commands = { "/bfl changelog" }, desc = T("SETTINGS_CENTER_HELP_COMMAND_CHANGELOG", "Open the standalone changelog window.") },
				{ type = "command", commands = { "/bfl discord" }, desc = T("SETTINGS_CENTER_HELP_COMMAND_DISCORD", "Show the Discord invite URL.") },
			},
		},
		{
			title = T("SETTINGS_CENTER_HELP_SUPPORT", "Support"),
			entries = {
				{ type = "text", text = T("SETTINGS_CENTER_HELP_SUPPORT_TEXT", "For bug reports, include your BetterFriendlist version, WoW version, active client, and reproduction steps.") },
				{ type = "button", text = T("SETTINGS_CENTER_PAGE_SUPPORT_LINKS", "Support Links"), width = 180, onClick = function() SettingsDesigner:Show("help.support") end },
			},
		},
	} })
end

local function BuildDashboard()
	local versionValue, versionBadge = SplitVersionBadge(GetAddOnVersion())
	return {
		hero = {
			title = T("SETTINGS_CENTER_TITLE", "BetterFriendlist Settings"),
			subtitle = T("SETTINGS_CENTER_DASHBOARD_DESC", "Task-based settings for friends, appearance, social tools, broker plugins, sync, and privacy."),
			icon = ADDON_ICON,
		},
		cards = {
			{ title = T("SETTINGS_CENTER_CATEGORY_FRIENDS", "Friendlist"), description = T("SETTINGS_CENTER_CARD_FRIENDS_DESC", "Display, formatting, and behavior."), iconKey = "bfl-friends", onClick = OpenSettingsCategory("friends") },
			{ title = T("SETTINGS_CENTER_CATEGORY_APPEARANCE", "Appearance"), description = T("SETTINGS_CENTER_CARD_APPEARANCE_DESC", "Theme, fonts, and frame layout."), iconKey = "bfl-appearance", onClick = OpenSettingsCategory("appearance") },
			{ title = T("SETTINGS_CENTER_CATEGORY_GROUPS_SORTING", "Groups & Sorting"), description = T("SETTINGS_CENTER_CARD_GROUPS_DESC", "Built-in groups, headers, order, and filters."), iconKey = "bfl-groups", onClick = OpenSettingsCategory("groups") },
			{ title = T("SETTINGS_CENTER_CATEGORY_BROKER_SYNC", "Broker & Sync"), description = T("SETTINGS_CENTER_CARD_BROKER_DESC", "Data Broker plugins and sync tools."), iconKey = "bfl-broker-sync", onClick = OpenSettingsCategory("broker") },
			{ title = T("SETTINGS_CENTER_PAGE_HELP", "Help"), description = T("SETTINGS_CENTER_CARD_HELP_DESC", "Slash commands, support notes, and links."), iconKey = "bfl-help", pageID = "help.about" },
			{ title = T("SETTINGS_CENTER_PAGE_SUPPORT_LINKS", "Support Links"), description = T("SETTINGS_CENTER_CARD_SUPPORT_DESC", "Community, bug reports, and support links."), iconKey = "bfl-help", pageID = "help.support" },
		},
		status = {
			title = T("SETTINGS_CENTER_DASHBOARD", "Dashboard"),
			tiles = function(_, stats)
				local customizable = tonumber(stats.customizable or stats.controls) or 0
				local customized = tonumber(stats.customized) or 0
				local tiles = {
					{ title = T("SETTINGS_CENTER_CUSTOMIZED", "Customized"), value = tostring(customized) .. " / " .. tostring(customizable), icon = SETTINGS_ICON_TEXTURES["bfl-stat-customized"] },
				}
				local newCount = tonumber(stats.newControls) or 0
				if newCount > 0 then
					tiles[#tiles + 1] = { title = T("SETTINGS_CENTER_NEW", "New"), value = tostring(newCount), badge = "tag:new", icon = SETTINGS_ICON_TEXTURES["bfl-stat-new"], searchQuery = "tag:new" }
				end
				tiles[#tiles + 1] = { title = T("SETTINGS_CENTER_VERSION", "Version"), value = versionValue, badge = versionBadge, icon = SETTINGS_ICON_TEXTURES["bfl-stat-settings"], onClick = function(state) if state and state.SetPage then state:SetPage("help.changelog") end end }
				return tiles
			end,
		},
		features = {
			enabledTitle = T("SETTINGS_CENTER_ENABLED_FEATURES", "Enabled"),
			customizedTitle = T("SETTINGS_CENTER_CUSTOMIZED", "Customized"),
			enabledBadge = ENABLED or T("SETTINGS_CENTER_ENABLED_FEATURES", "Enabled"),
			customizedBadge = T("SETTINGS_CENTER_CHANGED", "Changed"),
			limit = 5,
		},
		newEntries = {
			title = T("SETTINGS_CENTER_NEW", "New"),
			limit = 5,
		},
	}
end

function SettingsDesigner:Register()
	if self.registered then
		return app
	end
	if not Config or not ConfigUI then
		BFL:DebugPrint("LibSettingsDesigner is not available.")
		return nil
	end

	app = Config:RegisterAddOn(APP_ID, {
		title = T("SETTINGS_CENTER_TITLE", "BetterFriendlist Settings"),
		settingsTitle = T("SETTINGS_CENTER_TITLE", "BetterFriendlist Settings"),
		dashboardTitle = T("SETTINGS_CENTER_DASHBOARD", "Dashboard"),
		addonFolder = "BetterFriendlist",
		assetRoot = ASSET_ROOT,
		icon = ADDON_ICON,
		iconTextures = SETTINGS_ICON_TEXTURES,
		categoryIconTextures = SETTINGS_CATEGORY_ICON_TEXTURES,
		colors = GetSettingsCenterThemeColors,
		showDensityButton = true,
		density = "compact",
		topbar = {
			titleActions = {
				{
					id = "reload-ui",
					label = RELOADUI or T("BROKER_SETTINGS_RELOAD_BTN", "Reload Now"),
					visible = function(actionApp)
						return (actionApp and type(actionApp.IsReloadPending) == "function" and actionApp:IsReloadPending()) == true
					end,
					tooltip = function(actionApp)
						if actionApp and type(actionApp.GetReloadPendingReason) == "function" then
							return actionApp:GetReloadPendingReason()
						end
						return T("SETTINGS_CENTER_RELOAD_REQUIRED", "This change requires a UI reload.\n\nReload now?")
					end,
					pulse = true,
					onClick = function()
						if ReloadUI then
							ReloadUI()
						end
					end,
				},
			},
		},
		subnav = {
			enabled = true,
		},
		db = GetProfile,
		locale = DesignerLocale,
		version = GetAddOnVersion,
		getSize = function()
			local window = GetWindowState()
			return window.width, window.height
		end,
		setSize = function(width, height)
			local window = GetWindowState()
			window.width = width
			window.height = height
		end,
		getLocked = function()
			return GetWindowState().locked == true
		end,
		setLocked = function(locked)
			GetWindowState().locked = locked == true
		end,
		getDensity = function()
			return GetWindowState().density
		end,
		setDensity = function(density)
			if density == "compact" or density == "comfortable" then
				GetWindowState().density = density
			end
		end,
		getReloadPending = function()
			return SettingsDesigner.reloadPending == true
		end,
		setReloadPending = function(pending, reason)
			SettingsDesigner.reloadPending = pending == true
			SettingsDesigner.reloadReason = SettingsDesigner.reloadPending and reason or nil
		end,
		getReloadPendingReason = function()
			return SettingsDesigner.reloadReason or T("SETTINGS_CENTER_RELOAD_REQUIRED", "This change requires a UI reload.\n\nReload now?")
		end,
		isNewTag = function(tagID)
			return IsNewTagActive(tagID)
		end,
		blizzardSettingsRoot = true,
		blizzardSettingsTitle = "BetterFriendlist",
		openSettings = function()
			local Settings = BFL:GetModule("Settings")
			if Settings and Settings.Show then
				Settings:Show()
			else
				SettingsDesigner:Show()
			end
		end,
		dashboard = BuildDashboard,
	})

	RegisterCategories()
	RegisterFriendsPages()
	RegisterAppearancePages()
	RegisterGroupsPages()
	RegisterSocialPages()
	RegisterBrokerPages()
	RegisterPrivacyPages()
	RegisterAdvancedPages()
	RegisterHelpPages()

	self.registered = true
	self.app = app
	return app
end

function SettingsDesigner:Initialize()
	self:Register()
end

function SettingsDesigner:Show(pageID, focusControlID)
	local registeredApp = self:Register()
	if not registeredApp or not ConfigUI then
		return nil
	end
	local frame = ConfigUI:Open(registeredApp, pageID, focusControlID)
	self:ApplySkin("open")
	return frame
end

function SettingsDesigner:Hide()
	if not ConfigUI or not app then
		return
	end
	local frame = ConfigUI:GetFrame(app)
	if frame then
		frame:Hide()
	end
end

function SettingsDesigner:IsShown()
	if not ConfigUI or not app then
		return false
	end
	local frame = ConfigUI:GetFrame(app)
	return frame and frame:IsShown() == true
end

function SettingsDesigner:GetFrame()
	if not ConfigUI then
		return nil
	end
	return ConfigUI:GetFrame(app or APP_ID)
end

function SettingsDesigner:OpenLegacyTab(tabID)
	self:Hide()
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.ShowLegacy then
		Settings:ShowLegacy(tabID)
	end
end

local function SetBackdrop(frame, bg, border)
	if not frame or not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	if bg then
		frame:SetBackdropColor(bg.r or bg[1] or 0, bg.g or bg[2] or 0, bg.b or bg[3] or 0, bg.a or bg[4] or 1)
	end
	if border then
		frame:SetBackdropBorderColor(border.r or border[1] or 1, border.g or border[2] or 1, border.b or border[3] or 1, border.a or border[4] or 1)
	end
end

local function SkinText(frame, color)
	if not frame then
		return
	end
	local regions = { frame:GetRegions() }
	for _, region in ipairs(regions) do
		if region and region.SetTextColor and region.GetObjectType and region:GetObjectType() == "FontString" then
			region:SetTextColor(color.r, color.g, color.b, color.a or 1)
		end
	end
end

function SettingsDesigner:HideUntilExternalFrameHidden(externalFrame)
	if not (externalFrame and externalFrame.HookScript) then
		return
	end
	local frame = self:GetFrame()
	if not (frame and frame.IsShown and frame:IsShown()) then
		return
	end
	local state = frame._LibSettingsDesignerState
	local restorePageID = state and state.view == "page" and state.selectedPageID or nil
	frame:Hide()
	externalFrame.BFL_SettingsCenterRestorePageID = restorePageID
	if externalFrame.BFL_SettingsCenterRestoreHooked then
		return
	end
	externalFrame.BFL_SettingsCenterRestoreHooked = true
	externalFrame:HookScript("OnHide", function(owner)
		local pageID = owner.BFL_SettingsCenterRestorePageID
		owner.BFL_SettingsCenterRestorePageID = nil
		if SettingsDesigner and SettingsDesigner.Show then
			SettingsDesigner:Show(pageID)
		end
	end)
end

local function IsSettingsCenterTexture(texture)
	if not texture or not texture.GetTexture then
		return false
	end
	local source = texture:GetTexture()
	if type(source) ~= "string" then
		return false
	end
	return source:find("BetterFriendlist\\Textures\\SettingsCenter", 1, true) ~= nil
		or source:find("BetterFriendlist/Textures/SettingsCenter", 1, true) ~= nil
		or source:find("Textures\\SettingsCenter", 1, true) ~= nil
		or source:find("Textures/SettingsCenter", 1, true) ~= nil
end

local function PolishIconTexture(texture)
	if not IsSettingsCenterTexture(texture) then
		return
	end
	if texture.SetTexelSnappingBias then
		pcall(texture.SetTexelSnappingBias, texture, 0)
	end
	if texture.SetSnapToPixelGrid then
		pcall(texture.SetSnapToPixelGrid, texture, false)
	end
end

local function PolishSettingsIcons(frame, visited)
	if not frame or visited and visited[frame] then
		return
	end
	visited = visited or {}
	visited[frame] = true

	if frame.GetRegions then
		for _, region in ipairs({ frame:GetRegions() }) do
			if region and region.GetObjectType and region:GetObjectType() == "Texture" then
				PolishIconTexture(region)
			end
		end
	end

	if frame.GetChildren then
		for _, child in ipairs({ frame:GetChildren() }) do
			PolishSettingsIcons(child, visited)
		end
	end
end

function SettingsDesigner:PolishIcons()
	PolishSettingsIcons(self:GetFrame())
end

function SettingsDesigner:ScheduleIconPolish()
	self:PolishIcons()
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if SettingsDesigner:IsShown() then
				SettingsDesigner:PolishIcons()
			end
		end)
		C_Timer.After(0.15, function()
			if SettingsDesigner:IsShown() then
				SettingsDesigner:PolishIcons()
			end
		end)
	end
end

function SettingsDesigner:ApplySkin(reason)
	local frame = self:GetFrame()
	if not frame then
		return
	end
	if ConfigUI and ConfigUI.ApplyThemeColors and (app or self.app) then
		pcall(ConfigUI.ApplyThemeColors, app or self.app)
	end
	if ConfigUI and ConfigUI.ApplyThemeBorders and (app or self.app) then
		pcall(ConfigUI.ApplyThemeBorders, app or self.app)
	end
	if ConfigUI and ConfigUI.RefreshTopbarForApp and (app or self.app) then
		pcall(ConfigUI.RefreshTopbarForApp, app or self.app)
	end
	self:ScheduleIconPolish()

	local currentTheme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or GetDB("theme", "blizzard")
	if currentTheme == "blizzard" then
		return
	end

	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.GetPalette and SkinEngine.SkinTree then
		local palette = SkinEngine:GetPalette()
		if palette then
			SetBackdrop(frame, palette.windowBg or palette.background or { 0.05, 0.05, 0.05, 0.96 }, palette.border or { 0.7, 0.55, 0.25, 0.75 })
			if frame.TopBar then
				SetBackdrop(frame.TopBar, palette.headerBg or palette.surface or { 0.08, 0.08, 0.08, 0.96 }, palette.border)
			end
			if frame.Sidebar then
				SetBackdrop(frame.Sidebar, palette.insetBg or palette.surface or { 0.03, 0.03, 0.03, 0.92 }, palette.border)
			end
			if frame.ContentShell then
				SetBackdrop(frame.ContentShell, palette.insetBg or palette.surface or { 0.04, 0.04, 0.04, 0.92 }, palette.border)
			end
			pcall(SkinEngine.SkinTree, SkinEngine, frame, 2)
			return
		end
	end

	SetBackdrop(frame, { 0.035, 0.033, 0.03, 0.96 }, { 0.70, 0.55, 0.25, 0.85 })
	if frame.TopBar then
		SetBackdrop(frame.TopBar, { 0.055, 0.052, 0.047, 0.98 }, { 0.70, 0.55, 0.25, 0.60 })
	end
	if frame.Sidebar then
		SetBackdrop(frame.Sidebar, { 0.025, 0.024, 0.022, 0.96 }, { 0.45, 0.36, 0.18, 0.50 })
	end
	if frame.ContentShell then
		SetBackdrop(frame.ContentShell, { 0.030, 0.029, 0.026, 0.94 }, { 0.45, 0.36, 0.18, 0.50 })
	end
	SkinText(frame, { r = 0.92, g = 0.88, b = 0.78, a = 1 })
end

function SettingsDesigner:ApplyElvUISkin(E, S)
	local frame = self:GetFrame()
	if not frame or not E or not S then
		return
	end
	if not (GetDB("enableElvUISkin", false) == true or GetDB("theme", "blizzard") == "elvui") then
		return
	end

	if S.HandleFrame then
		pcall(S.HandleFrame, S, frame, true)
	end
	local candidates = {
		frame.TopBar,
		frame.Sidebar,
		frame.ContentShell,
		frame.SearchBox,
		frame.SearchShell,
		frame.ResetButton,
		frame.LockButton,
		frame.DensityButton,
	}
	for _, candidate in ipairs(candidates) do
		if candidate and S.HandleFrame then
			pcall(S.HandleFrame, S, candidate, true)
		end
		if candidate and candidate.GetObjectType and candidate:GetObjectType() == "Button" and S.HandleButton then
			pcall(S.HandleButton, S, candidate)
		end
	end
end
