-- Modern FriendsFrame surfaces for the legacy XML settings window only.
local ADDON_NAME, BFL = ...
local LegacySettingsStyle = BFL:RegisterModule("LegacySettingsStyle", {})

function LegacySettingsStyle:RefreshPreview(preview, modern, palette)
	if not preview then return end
	local surface = preview.BFL_ModernSettingsSurface
	local windowBorder = preview.BFL_PreviewWindowBorder
	if windowBorder then
		preview.NineSlice:SetShown(BFL:GetEffectiveTheme() == "blizzard")
	end
	if not modern and not surface then return end
	if not surface then
		surface = preview:CreateTexture(nil, "BACKGROUND", nil, -1)
		surface:SetPoint("TOPLEFT", 0, -28)
		surface:SetPoint("BOTTOMRIGHT")
		preview.BFL_ModernSettingsSurface = surface
	end

	if not windowBorder then
		if preview.Bg then preview.Bg:SetShown(not modern) end
		if preview.NineSlice then preview.NineSlice:SetShown(not modern) end
	end
	surface:SetShown(modern)
	if modern then surface:SetColorTexture(unpack(palette.surface)) end
end

function LegacySettingsStyle:OnSectionsLaidOut(frames)
	local frame = _G.BetterFriendlistSettingsFrame
	local content = frame and frame.ContentScrollFrame and frame.ContentScrollFrame.Content
	local page = frames[1] and frames[1]:GetParent()
	if not content or not page or page:GetParent() ~= content then return end
	-- Keep only the current layout per page; rebuilt controls hide their predecessors.
	self.sectionGroups = self.sectionGroups or {}
	self.sectionGroups[page] = frames
	self:Refresh()
end

function LegacySettingsStyle:RefreshSections(modern, palette)
	local frame = _G.BetterFriendlistSettingsFrame
	local content = frame and frame.ContentScrollFrame and frame.ContentScrollFrame.Content
	for page, frames in pairs(self.sectionGroups or {}) do
		local inLegacyWindow = page:GetParent() == content
		local first = true
		for _, header in ipairs(frames) do
			if header.BFL_SettingsSectionHeader and header:IsShown() then
				local shown = modern and inLegacyWindow and not first
				local divider = header.BFL_SectionDivider
				if shown and not divider then
					divider = header:CreateTexture(nil, "ARTWORK")
					divider:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 7)
					divider:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 7)
					divider:SetTexelSnappingBias(0)
					divider:SetSnapToPixelGrid(false)
					if BFL.HasAtlas("perks-divider-short") and BFL.SetTextureOrAtlas(divider, "perks-divider-short") then
						divider:SetHeight(3)
					else
						divider:SetColorTexture(1, 1, 1, 0.28)
						divider:SetHeight(1)
					end
					header.BFL_SectionDivider = divider
				end
				if divider then
					divider:SetShown(shown)
					if shown then
						divider:SetAlpha(1)
						divider:SetVertexColor(unpack(palette.border))
					end
				end
				first = false
			end
		end
		if not inLegacyWindow then self.sectionGroups[page] = nil end
	end
end

local function ThemeSurface(parent)
	local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	return frame
end

local function ColorSurface(frame, background, border)
	frame:SetBackdropColor(unpack(background))
	frame:SetBackdropBorderColor(unpack(border))
end

local function CreateThemeSample(parent)
	local panel = ThemeSurface(parent)
	panel.titleSurface = ThemeSurface(panel)
	panel.titleSurface:SetPoint("TOPLEFT", 1, -1)
	panel.titleSurface:SetPoint("TOPRIGHT", -1, -1)
	panel.titleSurface:SetHeight(24)
	panel.title = panel.titleSurface:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	panel.title:SetPoint("TOPLEFT", 9, -7)
	panel.title:SetText("BetterFriendlist")

	panel.avatar = panel:CreateTexture(nil, "ARTWORK")
	panel.avatar:SetSize(18, 18)
	panel.avatar:SetPoint("LEFT", panel.title, "RIGHT", 8, 0)
	panel.avatar:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")

	panel.inset = ThemeSurface(panel)
	panel.inset:SetPoint("TOPLEFT", 8, -26)
	panel.inset:SetPoint("BOTTOMRIGHT", -8, 8)

	local rows = {}
	for index, name in ipairs({ "SETTINGS_LEGACY_SAMPLE_ONLINE", "SETTINGS_LEGACY_SAMPLE_OFFLINE" }) do
		local row = ThemeSurface(panel.inset)
		row:SetPoint("TOPLEFT", 5, -5 - (index - 1) * 21)
		row:SetPoint("TOPRIGHT", -20, -5 - (index - 1) * 21)
		row:SetHeight(20)
		row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.label:SetPoint("LEFT", 6, 0)
		row.label:SetText(BFL.L[name])
		rows[index] = row
	end
	panel.rows = rows

	panel.thumb = panel.inset:CreateTexture(nil, "ARTWORK")
	panel.thumb:SetSize(6, 24)
	panel.thumb:SetPoint("TOPRIGHT", -6, -6)
	panel.icon = rows[1]:CreateTexture(nil, "ARTWORK")
	panel.icon:SetSize(13, 13)
	panel.icon:SetPoint("RIGHT", -6, 0)
	BFL.SetTextureOrAtlas(panel.icon, "common-icon-checkmark", "Interface\\Buttons\\UI-CheckBox-Check")

	panel.control = ThemeSurface(panel.inset)
	panel.control:SetPoint("BOTTOMLEFT", 5, 5)
	panel.control:SetPoint("BOTTOMRIGHT", -5, 5)
	panel.control:SetHeight(20)
	panel.control.label = panel.control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	panel.control.label:SetPoint("CENTER")
	panel.control.label:SetText(SEARCH or "")
	return panel
end

function LegacySettingsStyle:RenderThemeComparison(lane, guide, value, width, top)
	local theme = type(guide.theme) == "string" and guide.theme or value
	local palette = BFL:GetModule("ThemePalette")
	local engine = BFL:GetModule("SkinEngine")
	local colors = {}
	local settings = palette:GetThemeSettings(theme)
	local custom = palette:GetCustomTheme()
	if guide.paletteSettings then settings[guide[1]] = value end
	if guide.paletteColors then custom[guide[1]] = value end

	palette:ApplyToColors(colors, engine.defaultColors, { theme = theme, settings = settings, customTheme = custom })
	local flat = theme == "dark" or theme == "custom"
	if not flat then
		local friends = BFL:GetModule("FriendsUI")
		local external = friends and friends.GetModernThemeColors(setmetatable({}, { __index = friends }), theme)
		if external then
			colors.panel, colors.panelSoft, colors.inset = external.background, external.surface, external.inset
			if theme ~= "blizzard" then
				colors.gold, colors.text, colors.disabledText = external.accent, external.text, external.disabledText
				colors.icon, colors.scrollThumb = external.icon, external.scrollThumb
				if theme == "elvui" then
					local elvui = BFL:GetModule("ElvUISkin")
					colors.control, colors.border = elvui:GetSettingsSampleBackdropColors()
					colors.controlBorder, colors.borderSoft = colors.border, colors.border
					colors.panel = colors.control
				elseif theme == "ellesmereui" then
					colors.control, colors.borderSoft = external.control, external.border
					colors.controlBorder, colors.border = external.border, external.border
					colors.rowHover, colors.rowDown = external.hover, external.selected
				end
			end
		end
	end

	local panel = lane.themeSample or CreateThemeSample(lane)
	lane.themeSample = panel
	local popup = guide.brokerBackground or guide[1] == "popupOpacity"
	local background = popup and colors.popup or colors.panel
	if guide.brokerBackground then
		local broker = BFL.BrokerUtils
		local base = broker.ResolveBrokerTooltipBackground(theme) or broker.GetBrokerTooltipFallbackBackground(theme)
		if guide[1] == "opacity" then
			background = { base.r, base.g, base.b, value }
		else
			background = { value.r, value.g, value.b, base.a }
		end
	end
	local row = panel.rows
	local color = guide[1] == "disabledTextColor" and colors.controlDisabled or colors.control
	ColorSurface(panel, background, colors.border)
	ColorSurface(panel.titleSurface, colors.panelSoft, colors.borderSoft)
	ColorSurface(panel.inset, colors.inset, colors.borderSoft)
	ColorSurface(row[1], colors.rowHover, colors.divider)
	ColorSurface(row[2], colors.rowDown, colors.divider)
	ColorSurface(panel.control, color, colors.controlBorder)
	panel.title:SetTextColor(unpack(colors.gold))
	row[1].label:SetTextColor(unpack(colors.text))
	row[2].label:SetTextColor(unpack(colors.text))
	panel.control.label:SetTextColor(unpack(guide[1] == "disabledTextColor" and colors.disabledText or colors.text))
	panel.thumb:SetColorTexture(unpack(colors.scrollThumb))
	panel.icon:SetVertexColor(unpack(colors.icon))
	panel.avatar:SetAlpha(flat and settings.avatarVisibility or 1)
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", lane, "TOPLEFT", 0, -top)
	panel:SetSize(width, 105)
	panel:Show()
	return top + panel:GetHeight() + 8
end

function LegacySettingsStyle:RenderGeometryComparison(lane, guide, value, width, top)
	local frameSettings = BFL:GetModule("FrameSettings")
	local db = BFL:GetModule("DB")
	local layout = frameSettings:GetLayoutKey()
	local stored = db:Get("mainFrameSize", {})[layout] or {}
	local baseWidth, baseHeight = frameSettings:GetDefaultSize(layout)
	local windowWidth, windowHeight = stored.width or baseWidth, stored.height or baseHeight
	local scale = db:Get("windowScale", 1)
	local key = guide[1]
	if key == "width" then windowWidth = tonumber(value) or windowWidth end
	if key == "height" then windowHeight = tonumber(value) or windowHeight end
	if key == "windowScale" then scale = tonumber(value) or scale end

	local canvas = lane.geometrySample
	if not canvas then
		canvas = ThemeSurface(lane)
		canvas.window = CreateThemeSample(canvas)
		canvas.window:SetClipsChildren(true)
		canvas.cursor = canvas:CreateTexture(nil, "OVERLAY")
		canvas.cursor:SetSize(18, 18)
		BFL.SetTextureOrAtlas(canvas.cursor, "common-icon-lock", "Interface\\Buttons\\LockButton-Locked-Up")
		lane.geometrySample = canvas
	end
	local engine = BFL:GetModule("SkinEngine")
	local colors = engine.colors or engine.defaultColors
	ColorSurface(canvas, colors.inset, colors.borderMuted)
	local ratio = math.min(width / 900, 0.16)
	local window = canvas.window
	window:ClearAllPoints()
	window:SetScale(key == "windowScale" and scale or 1)
	local simulatedWidth = math.max(48, windowWidth * ratio)
	local simulatedHeight = math.max(40, windowHeight * ratio)
	if key == "useUIPanelSystem" and value then
		window:SetPoint("TOPLEFT", canvas, "TOPLEFT", 6, -5)
	elseif key == "lockWindow" and not value then
		window:SetPoint("TOP", canvas, "TOP", 25, -11)
	else
		window:SetPoint("TOP", canvas, "TOP", 0, -5)
	end
	window:SetSize(simulatedWidth, simulatedHeight)
	ColorSurface(window, colors.panel, colors.border)
	ColorSurface(window.inset, colors.inset, colors.borderSoft)
	ColorSurface(window.rows[1], colors.rowHover, colors.divider)
	ColorSurface(window.rows[2], colors.rowDown, colors.divider)
	ColorSurface(window.control, colors.control, colors.controlBorder)
	window.control:Hide()
	window.thumb:Hide()
	window.avatar:Hide()
	window.icon:Hide()
	window.title:SetFontObject("GameFontNormalSmall")
	window.title:SetWidth(math.max(1, simulatedWidth - 14))
	window.title:SetMaxLines(1)
	window.title:SetTextColor(unpack(colors.gold))
	for _, row in ipairs(window.rows) do row.label:SetTextColor(unpack(colors.text)) end
	canvas.cursor:ClearAllPoints()
	canvas.cursor:SetPoint("TOPRIGHT", window, "TOPRIGHT", 5, 4)
	canvas.cursor:SetShown(key == "lockWindow" and value == true)

	if key == "enableSmoothScrolling" then
		window:SetScript("OnUpdate", function(frame)
			local phase = GetTime() % 2
			local offset = phase < 0.8 and 0 or 14
			if value and phase >= 0.8 and phase < 1.2 then
				offset = 14 * ((phase - 0.8) / 0.4)
			end
			for index, row in ipairs(frame.rows) do
				local y = -5 - (index - 1) * 21 + offset
				row:SetPoint("TOPLEFT", 5, y)
				row:SetPoint("TOPRIGHT", -20, y)
			end
		end)
	else
		window:SetScript("OnUpdate", nil)
		for index, row in ipairs(window.rows) do
			row:SetPoint("TOPLEFT", 5, -5 - (index - 1) * 21)
			row:SetPoint("TOPRIGHT", -20, -5 - (index - 1) * 21)
		end
	end

	canvas:ClearAllPoints()
	canvas:SetPoint("TOPLEFT", lane, "TOPLEFT", 0, -top)
	canvas:SetSize(width, (key == "height" and 1200 or windowHeight * (key == "windowScale" and 2 or 1)) * ratio + 20)
	canvas:Show()
	return top + canvas:GetHeight() + 8
end

function LegacySettingsStyle:SkinPreview(review)
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine:IsActive() then
		local dark = BFL:GetModule("DarkTheme")
		if dark then dark:SkinSettingsPreview(engine, review) end
	else
		local elvui = BFL:GetModule("ElvUISkin")
		if elvui then elvui:SkinSettingsReview(review, true) end
		local ellesmere = BFL:GetModule("EllesmereUISkin")
		if ellesmere then ellesmere:SkinSettingsPreview(review.previewShell, review.headerSample) end
	end
end

function LegacySettingsStyle:SkinComparison(review)
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine:IsActive() then
		local dark = BFL:GetModule("DarkTheme")
		if dark then dark:SkinSettingsComparison(engine, review) end
		return
	end
	local theme = BFL:GetEffectiveTheme()
	local skin = theme == "elvui" and BFL:GetModule("ElvUISkin")
		or theme == "ellesmereui" and BFL:GetModule("EllesmereUISkin")
	if skin then skin:SkinSettingsComparison(review) end
end

function LegacySettingsStyle:SkinActions(buttons, editBox)
	local theme = BFL:GetEffectiveTheme()
	local external = theme == "elvui" and BFL:GetModule("ElvUISkin")
		or theme == "ellesmereui" and BFL:GetModule("EllesmereUISkin")
	if external then
		external:SkinSettingsActions(buttons, editBox)
		return
	end
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine:IsActive() then
		for _, button in ipairs(buttons or {}) do engine:SkinButton(button) end
		if editBox then engine:SkinEditBox(editBox) end
	end
end

function LegacySettingsStyle:SkinReleaseHeader(header, modern)
	local theme = BFL:GetEffectiveTheme()
	if theme == "elvui" then
		local elvui = BFL:GetModule("ElvUISkin")
		if elvui then elvui:SkinSettingsReleaseHeader(header, modern) end
	elseif (theme == "dark" or theme == "custom") and not modern then
		local engine = BFL:GetModule("SkinEngine")
		if engine and engine:IsActive() then engine:SkinRow(header) end
	end
end

function LegacySettingsStyle:RefreshScrollbar(frame, theme)
	local settings = BFL:GetModule("Settings")
	local scrollFrame = frame.ContentScrollFrame
	if not (settings and scrollFrame) then return end
	settings:UpdateLegacySettingsScrollbar(scrollFrame)
	local bar = scrollFrame.ScrollBar
	if not bar then return end
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine:IsActive() then engine:SkinScrollBar(bar) end
	if theme == "blizzard" then bar:SetWidth(8) end
end

function LegacySettingsStyle:Refresh()
	local frame = _G.BetterFriendlistSettingsFrame
	if not (frame and frame.Bg and frame.MainInset) then return end
	local FriendsUI = BFL.IsMainline and BFL:GetModule("FriendsUI")
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	local supportedTheme = theme == "blizzard" or theme == "dark" or theme == "custom"
	local modern = not not (FriendsUI and FriendsUI:IsModernActive() and supportedTheme)
	local palette = modern and FriendsUI:GetModernThemeColors(theme)
	local review = BFL:GetModule("LegacySettingsReview")
	local shell = review and review.previewShell
	if shell then
		local themedPreview = FriendsUI and (theme == "blizzard" or theme == "ellesmereui")
			and (FriendsUI:IsModernActive() or shell.BFL_PreviewWindowBorder)
		local previewPalette = themedPreview and FriendsUI:GetModernThemeColors(theme)
		self:RefreshPreview(shell, themedPreview, previewPalette)
		if review.active then
			local elvui = BFL:GetModule("ElvUISkin")
			if elvui and theme == "elvui" then elvui:SkinSettingsReview(review, false) end
			self:SkinActions(review.supportButtons)
			if review.home and review.home:IsShown() then
				BFL:GetModule("Changelog"):RefreshReleaseBadges(review.home.entries)
			end
			review:QueueSample()
		end
	end
	self:RefreshScrollbar(frame, theme)
	if not modern and not frame.BFL_ModernSettingsBackgrounds then return end

	local backgrounds = frame.BFL_ModernSettingsBackgrounds
	if modern and not backgrounds then
		local body = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
		-- The native background accounts for transparent gutters in the outer border.
		body:SetAllPoints(frame.Bg)
		local topFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
		topFade:SetPoint("TOPLEFT", body, "TOPLEFT")
		topFade:SetPoint("TOPRIGHT", body, "TOPRIGHT")
		local bottomFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
		bottomFade:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT")
		bottomFade:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")
		local navigationDivider
		if frame.CategoryList then
			navigationDivider = frame:CreateTexture(nil, "ARTWORK")
			navigationDivider:SetWidth(1)
			navigationDivider:SetTexelSnappingBias(0)
			navigationDivider:SetSnapToPixelGrid(false)
			navigationDivider:SetPoint("TOPLEFT", frame.CategoryList, "TOPRIGHT", 5, 0)
			navigationDivider:SetPoint("BOTTOMLEFT", frame.CategoryList, "BOTTOMRIGHT", 5, 0)
		end
		local function LoadFade(texture, atlas)
			local loaded = BFL.HasAtlas(atlas) and BFL.SetTextureOrAtlas(texture, atlas, nil, true)
			if loaded then texture:SetHeight(math.min(texture:GetHeight(), 140)) end
			return loaded
		end
		backgrounds = {
			body = body, topFade = topFade, bottomFade = bottomFade,
			navigationDivider = navigationDivider,
			hasTopFade = LoadFade(topFade, "friends-frame-toptexbg"),
			hasBottomFade = LoadFade(bottomFade, "friends-frame-bottomtexbg"),
		}
		frame.BFL_ModernSettingsBackgrounds = backgrounds
	end

	-- The outer window supplies the native border, as in the Modern changelog.
	if theme == "blizzard" then
		frame.Bg:SetShown(not modern)
		frame.MainInset:SetBackdropBorderColor(0.4, 0.4, 0.4, modern and 0 or 0.8)
	end
	if frame.ButtonSeparator and supportedTheme then frame.ButtonSeparator:SetShown(not modern) end
	backgrounds.body:SetShown(modern)
	local useAtlas = modern and theme == "blizzard"
	backgrounds.topFade:SetShown(useAtlas and backgrounds.hasTopFade or false)
	backgrounds.bottomFade:SetShown(useAtlas and backgrounds.hasBottomFade or false)
	self:RefreshSections(modern, palette)
	if backgrounds.navigationDivider then
		backgrounds.navigationDivider:SetShown(modern)
		if modern then
			local border = palette.border
			backgrounds.navigationDivider:SetColorTexture(border[1], border[2], border[3], theme == "blizzard" and 0.25 or border[4])
			backgrounds.navigationDivider:SetAlpha(1)
		end
	end
	if modern then
		backgrounds.body:SetColorTexture(unpack(palette.background))
		-- A theme refresh can have dimmed existing artwork before this owner pass.
		backgrounds.body:SetAlpha(1)
		backgrounds.topFade:SetAlpha(1)
		backgrounds.bottomFade:SetAlpha(1)
	end
end

function LegacySettingsStyle:Initialize()
	if self.initialized then return end
	self.initialized = true
	local Components = BFL.SettingsComponents
	if Components then
		hooksecurefunc(Components, "AnchorChain", function(_, frames) self:OnSectionsLaidOut(frames) end)
	end
	local frame = _G.BetterFriendlistSettingsFrame
	if frame then frame:HookScript("OnShow", function() self:Refresh() end) end
	-- All targets are addon-owned methods. Reapply after theme restoration and
	-- deferred legacy-control skinning, without touching the Settings Center.
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		hooksecurefunc(ThemeManager, "ApplyCurrentTheme", function() self:Refresh() end)
	end
	local DarkTheme = BFL:GetModule("DarkTheme")
	if DarkTheme and DarkTheme.SkinSettingsFrame then
		hooksecurefunc(DarkTheme, "SkinSettingsFrame", function() self:Refresh() end)
	end
	self:Refresh()
end
