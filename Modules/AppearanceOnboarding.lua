-- Modules/AppearanceOnboarding.lua
-- One-time Retail 12.1 interface-style and theme onboarding.

local ADDON_NAME, BFL = ...
local AppearanceOnboarding = BFL:RegisterModule("AppearanceOnboarding", {})

local ONBOARDING_VERSION = 2
local STYLE_MODERN = "modern"
local STYLE_LEGACY = "legacy"
local TOTAL_STEPS = 4
local CARD_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = false,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local PREVIEW_BACKDROP = {
	bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 10,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

BFL.APPEARANCE_ONBOARDING_VERSION = ONBOARDING_VERSION

local function GetL()
	return BFL.L or _G.BFL_L or {}
end

local function SafeFormat(template, ...)
	local ok, text = pcall(string.format, template or "", ...)
	return ok and text or tostring(template or "")
end

local function CopyColor(color, fallback, alpha)
	local source = type(color) == "table" and color or fallback
	local result = {
		tonumber(source and (source[1] or source.r)) or 1,
		tonumber(source and (source[2] or source.g)) or 1,
		tonumber(source and (source[3] or source.b)) or 1,
		tonumber(source and (source[4] or source.a)) or 1,
	}
	if alpha ~= nil then
		result[4] = alpha
	end
	return result
end

local function WithAlpha(color, alpha)
	return { color[1], color[2], color[3], alpha }
end

local function UnpackColor(color)
	return color[1], color[2], color[3], color[4]
end

local function CreateBackdropFrame(frameType, parent, backdrop)
	local template = BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame(frameType or "Frame", nil, parent, template)
	if frame.SetBackdrop then
		frame:SetBackdrop(backdrop or CARD_BACKDROP)
	else
		frame.BFL_Background = frame:CreateTexture(nil, "BACKGROUND")
		frame.BFL_Background:SetAllPoints()
	end
	return frame
end

local function SetBackdropColors(frame, background, border)
	if frame.SetBackdropColor then
		frame:SetBackdropColor(UnpackColor(background))
		frame:SetBackdropBorderColor(UnpackColor(border))
	elseif frame.BFL_Background then
		frame.BFL_Background:SetColorTexture(UnpackColor(background))
	end
end

local function SetFontColor(fontString, color)
	if fontString and fontString.SetTextColor then
		fontString:SetTextColor(UnpackColor(color))
	end
end

local function IsValidStyle(style)
	return style == STYLE_MODERN or style == STYLE_LEGACY
end

function AppearanceOnboarding:EvaluateEligibility(context)
	context = context or {}
	if context.isRetail ~= true then
		return false, "client"
	end
	if (tonumber(context.completedVersion) or 0) >= (tonumber(context.requiredVersion) or ONBOARDING_VERSION) then
		return false, "complete"
	end
	if context.sessionDeferred == true then
		return false, "deferred"
	end
	if context.playerLoggedIn ~= true then
		return false, "login"
	end
	if context.frameShown ~= true then
		return false, "frame"
	end
	if context.socialUIEnabled ~= true and context.forceModern ~= true then
		return false, "social-ui"
	end
	if context.inCombat == true then
		return false, "combat"
	end
	return true
end

function AppearanceOnboarding:IsComplete()
	local DB = BFL:GetModule("DB")
	local completedVersion = DB and DB:Get("appearanceOnboardingVersion", 0)
		or (BetterFriendlistDB and BetterFriendlistDB.appearanceOnboardingVersion)
		or 0
	return (tonumber(completedVersion) or 0) >= ONBOARDING_VERSION
end

function AppearanceOnboarding:IsSocialUIEnabled()
	local FriendsUI = BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsSocialUIEnabled and FriendsUI:IsSocialUIEnabled() == true
end

local function SetNativeButtonText(button, text)
	if button and button.SetText then
		button:SetText(text or "")
	end
end

local function SetNativeButtonEnabled(button, enabled)
	if not button then
		return
	end
	button.BFL_Enabled = enabled == true
	button:SetEnabled(enabled == true)
end

function AppearanceOnboarding:IsModernForceEnabled()
	local FriendsUI = BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernForceEnabled and FriendsUI:IsModernForceEnabled() == true
end

function AppearanceOnboarding:IsModernStyleAvailable()
	return self:IsSocialUIEnabled() or self:IsModernForceEnabled()
end

function AppearanceOnboarding:IsInCombat()
	return InCombatLockdown and InCombatLockdown() == true
end

function AppearanceOnboarding:GetPalette()
	local accent = { 1, 0.82, 0, 1 }
	if BFL.GetThemeAccentColor then
		accent = { BFL:GetThemeAccentColor(1, 0.82, 0, 1) }
	end

	local SkinEngine = BFL:GetModule("SkinEngine")
	local colors = SkinEngine and SkinEngine.colors
	if SkinEngine and SkinEngine.IsActive and SkinEngine:IsActive() and type(colors) == "table" then
		return {
			window = CopyColor(colors.panel, { 0.03, 0.03, 0.035, 0.98 }, 0.98),
			card = CopyColor(colors.panelSoft, { 0.06, 0.06, 0.07, 0.92 }, 0.92),
			hover = CopyColor(colors.controlHover, { 0.10, 0.10, 0.11, 0.96 }, 0.96),
			selected = CopyColor(colors.rowDown or colors.accentState, { accent[1], accent[2], accent[3], 0.18 }),
			border = CopyColor(colors.borderSoft, { 0.28, 0.28, 0.30, 0.75 }),
			accent = CopyColor(colors.accent or colors.gold, accent),
			text = CopyColor(colors.text, { 0.95, 0.95, 0.95, 1 }),
			disabledText = CopyColor(colors.disabledText, { 0.50, 0.50, 0.52, 1 }),
		}
	end

	return {
		window = { 0.045, 0.032, 0.020, 0.98 },
		card = { 0.105, 0.078, 0.045, 0.94 },
		hover = { 0.16, 0.12, 0.065, 0.98 },
		selected = { accent[1], accent[2], accent[3], 0.16 },
		border = { 0.48, 0.36, 0.15, 0.88 },
		accent = accent,
		text = { 1, 0.96, 0.88, 1 },
		disabledText = { 0.54, 0.50, 0.44, 1 },
	}
end

function AppearanceOnboarding:CreateNavigationButton(parent, width, height, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, height)
	button.BFL_Enabled = true
	button:SetScript("OnClick", function(control)
		if control.BFL_Enabled ~= false and onClick then
			onClick()
		end
	end)
	return button
end

function AppearanceOnboarding:SetNavigationButtonEnabled(button, enabled)
	if not button then
		return
	end
	SetNativeButtonEnabled(button, enabled)
end

function AppearanceOnboarding:CreateChoiceCard(parent, height, onClick)
	local card = CreateBackdropFrame("Button", parent)
	card:SetHeight(height)
	card:SetScript("OnClick", function(control)
		if control.BFL_Available ~= false and not self:IsInCombat() and onClick then
			onClick(control.BFL_Value)
		end
	end)
	card:SetScript("OnEnter", function(control)
		control.BFL_Hovered = true
		self:RefreshChoiceCard(control)
	end)
	card:SetScript("OnLeave", function(control)
		control.BFL_Hovered = nil
		self:RefreshChoiceCard(control)
	end)

	card.Title = card:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	card.SelectControl = CreateFrame("CheckButton", nil, card, "UIRadioButtonTemplate")
	card.SelectControl:SetPoint("TOPLEFT", 15, -16)
	card.SelectControl:SetScript("OnClick", function()
		if card.BFL_Available ~= false and not self:IsInCombat() and onClick then
			onClick(card.BFL_Value)
		end
	end)

	card.Title:SetPoint("TOPLEFT", 42, -14)
	card.Title:SetPoint("TOPRIGHT", -188, -16)
	card.Title:SetJustifyH("LEFT")
	card.Title:SetMaxLines(1)
	card.Description = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	card.Description:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -8)
	card.Description:SetPoint("TOPRIGHT", card.Title, "BOTTOMRIGHT", 0, -8)
	card.Description:SetJustifyH("LEFT")
	card.Description:SetJustifyV("TOP")
	card.Description:SetWordWrap(true)
	card.Description:SetMaxLines(4)
	card.Badge = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	card.Badge:SetPoint("BOTTOMLEFT", 42, 13)
	card.Badge:SetJustifyH("LEFT")
	card.Badge:Hide()
	card.Accent = card:CreateTexture(nil, "ARTWORK")
	card.Accent:SetTexture("Interface\\Buttons\\WHITE8X8")
	card.Accent:SetWidth(4)
	card.Accent:SetPoint("TOPLEFT", 1, -1)
	card.Accent:SetPoint("BOTTOMLEFT", 1, 1)
	card.Accent:Hide()
	return card
end

local function CreatePreviewTexture(parent, left, top, width, height)
	local texture = parent:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	texture:SetPoint("TOPLEFT", left, top)
	texture:SetSize(width, height)
	return texture
end

local function AddPreviewPiece(preview, role, left, top, width, height)
	local texture = CreatePreviewTexture(preview, left, top, width, height)
	texture.BFL_PreviewRole = role
	preview.Pieces[#preview.Pieces + 1] = texture
	return texture
end

function AppearanceOnboarding:CreateStyleDiagram(card, style)
	local preview = CreateBackdropFrame("Frame", card, PREVIEW_BACKDROP)
	preview:SetSize(154, 112)
	preview:SetPoint("RIGHT", -18, 0)
	card.Diagram = preview
	preview.Pieces = {}
	-- These diagrams deliberately mirror the live structures rather than only
	-- suggesting a generic list: Modern has right-side navigation, while Legacy
	-- has top content tabs and bottom section tabs.
	if style == STYLE_MODERN then
		AddPreviewPiece(preview, "accent", 8, -8, 22, 17)
		AddPreviewPiece(preview, "control", 34, -8, 88, 17)
		AddPreviewPiece(preview, "control", 8, -29, 114, 12)
		for index = 1, 3 do
			AddPreviewPiece(preview, index == 1 and "selected" or "row", 8, -47 - ((index - 1) * 18), 114, 14)
		end
		for index = 1, 5 do
			AddPreviewPiece(preview, index == 1 and "accent" or "tab", 127, -8 - ((index - 1) * 20), 18, 18)
		end
		AddPreviewPiece(preview, "control", 36, -101, 58, 6)
	else
		AddPreviewPiece(preview, "accent", 8, -8, 22, 17)
		AddPreviewPiece(preview, "control", 34, -8, 112, 17)
		AddPreviewPiece(preview, "control", 8, -29, 138, 12)
		for index = 1, 3 do
			AddPreviewPiece(preview, index == 1 and "accent" or "tab", 8 + ((index - 1) * 46), -45, 43, 11)
		end
		for index = 1, 3 do
			AddPreviewPiece(preview, index == 1 and "selected" or "row", 8, -60 - ((index - 1) * 15), 138, 12)
		end
		for index = 1, 4 do
			AddPreviewPiece(preview, index == 1 and "accent" or "tab", 8 + ((index - 1) * 35), -102, 32, 7)
		end
	end
	return preview
end

function AppearanceOnboarding:RefreshStyleDiagram(card)
	if not card or not card.Diagram then
		return
	end
	local palette = self.palette or self:GetPalette()
	SetBackdropColors(card.Diagram, WithAlpha(palette.window, 0.82), palette.border)
	for _, texture in ipairs(card.Diagram.Pieces or {}) do
		local role = texture.BFL_PreviewRole
		local color = role == "accent" and WithAlpha(palette.accent, 0.88)
			or role == "selected" and WithAlpha(palette.accent, 0.28)
			or role == "row" and WithAlpha(palette.text, 0.17)
			or role == "tab" and WithAlpha(palette.text, 0.30)
			or WithAlpha(palette.text, 0.22)
		texture:SetColorTexture(UnpackColor(color))
	end
end

function AppearanceOnboarding:RefreshChoiceCard(card)
	if not card then
		return
	end
	local palette = self.palette or self:GetPalette()
	local selected = card.BFL_Kind == "style" and self.selectedStyle == card.BFL_Value
		or card.BFL_Kind == "theme" and self.selectedTheme == card.BFL_Value
	local available = card.BFL_Available ~= false and not self:IsInCombat()
	local background = selected and palette.selected or (card.BFL_Hovered and available and palette.hover or palette.card)
	local border = selected and palette.accent or palette.border
	SetBackdropColors(card, background, border)
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine.IsActive and engine:IsActive() and card.BFL_DarkBackdrop then
		engine:StyleBackdrop(card, background, border)
	end
	card.Accent:SetColorTexture(UnpackColor(palette.accent))
	card.Accent:SetShown(selected)
	card.SelectControl:SetChecked(selected)
	card.SelectControl:SetEnabled(available)
	SetFontColor(card.Title, available and palette.text or palette.disabledText)
	SetFontColor(card.Description, available and WithAlpha(palette.text, 0.78) or palette.disabledText)
	SetFontColor(card.Badge, palette.accent)
	self:RefreshStyleDiagram(card)
end

function AppearanceOnboarding:BuildStyleStep(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel.Cards = {}

	local definitions = {
		{
			value = STYLE_MODERN,
			titleKey = "SETTINGS_FRIENDS_UI_STYLE_MODERN",
			title = "Modern (Retail 12.1)",
			descriptionKey = "ONBOARDING_STYLE_MODERN_DESC",
			description = "Side navigation, modern friend cards, and the complete Retail 12.1 SocialUI experience.",
			badgeKey = "ONBOARDING_RECOMMENDED",
			badge = "Recommended",
		},
		{
			value = STYLE_LEGACY,
			titleKey = "SETTINGS_FRIENDS_UI_STYLE_LEGACY",
			title = "Legacy",
			descriptionKey = "ONBOARDING_STYLE_LEGACY_DESC",
			description = "The familiar BetterFriendlist layout with its established tabs and workflows.",
		},
	}

	for index, definition in ipairs(definitions) do
		local card = self:CreateChoiceCard(panel, 154, function(value)
			self:SelectStyle(value)
		end)
		local yOffset = -((index - 1) * 166)
		card:SetPoint("TOPLEFT", 0, yOffset)
		card:SetPoint("TOPRIGHT", 0, yOffset)
		card.BFL_Kind = "style"
		card.BFL_Value = definition.value
		card.BFL_Available = true
		card.BFL_TitleKey = definition.titleKey
		card.BFL_TitleFallback = definition.title
		card.BFL_DescriptionKey = definition.descriptionKey
		card.BFL_DescriptionFallback = definition.description
		if definition.badgeKey then
			card.BFL_BadgeKey = definition.badgeKey
			card.BFL_BadgeFallback = definition.badge
			card.Badge:Show()
		end
		self:CreateStyleDiagram(card, definition.value)
		panel.Cards[#panel.Cards + 1] = card
	end

	self.stylePanel = panel
	self.styleCards = panel.Cards
end

function AppearanceOnboarding:BuildThemeStep(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel.Cards = {}
	self.themePanel = panel
	self.themeCards = panel.Cards
end

function AppearanceOnboarding:RebuildThemeCards()
	if not self.themePanel then
		return
	end
	for _, card in ipairs(self.themeCards or {}) do
		card:Hide()
		card:SetParent(nil)
	end
	wipe(self.themeCards)

	local ThemeManager = BFL:GetModule("ThemeManager")
	local themes = ThemeManager and ThemeManager.GetAvailableThemeIDs and ThemeManager:GetAvailableThemeIDs() or { "blizzard" }
	local locale = GetL()
	local cardHeight = 86
	local spacing = 8
	local columns = #themes > 4 and 2 or 1
	for index, theme in ipairs(themes) do
		local card = self:CreateChoiceCard(self.themePanel, cardHeight, function(value)
			self:SelectTheme(value)
		end)
		local column = (index - 1) % columns
		local row = math.floor((index - 1) / columns)
		card:SetPoint("TOPLEFT", column == 0 and 0 or 253, -(row * (cardHeight + spacing)))
		card:SetPoint("TOPRIGHT", column == 0 and (columns == 1 and 0 or -253) or 0, -(row * (cardHeight + spacing)))
		card.BFL_Kind = "theme"
		card.BFL_Value = theme
		card.BFL_Available = true
		card.Title:ClearAllPoints()
		card.SelectControl:ClearAllPoints()
		card.SelectControl:SetPoint("TOPLEFT", 12, -11)
		card.Title:SetPoint("TOPLEFT", 38, -10)
		card.Title:SetPoint("TOPRIGHT", -44, -11)
		card.Description:ClearAllPoints()
		card.Description:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -5)
		card.Description:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 24)
		card.Description:SetMaxLines(3)
		card.Badge:ClearAllPoints()
		card.Badge:SetPoint("BOTTOMRIGHT", -12, 8)
		card.Badge:SetJustifyH("RIGHT")
		card.Title:SetText(ThemeManager and ThemeManager.GetThemeLabel and ThemeManager:GetThemeLabel(theme) or theme)
		card.Description:SetText(
			ThemeManager and ThemeManager.GetThemeOnboardingDescription
				and ThemeManager:GetThemeOnboardingDescription(theme)
				or SafeFormat(locale.ONBOARDING_THEME_GENERIC_DESC or "Preview the %s theme on your BetterFriendlist.", theme)
		)
		local definition = ThemeManager and ThemeManager.GetThemeDefinition and ThemeManager:GetThemeDefinition(theme)
		if definition and definition.requiresReload then
			card.Badge:SetText(locale.ONBOARDING_RELOAD_BADGE or "Reload required")
			card.Badge:Show()
		end
		self.themeCards[#self.themeCards + 1] = card
	end

end

function AppearanceOnboarding:CreateLayoutOption(parent, yOffset, key, titleKey, descriptionKey)
	local card = CreateBackdropFrame("Button", parent)
	card:SetHeight(118)
	card:SetPoint("TOPLEFT", 0, yOffset)
	card:SetPoint("TOPRIGHT", 0, yOffset)
	card.BFL_LayoutKey = key

	card.Check = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
	card.Check:SetPoint("TOPLEFT", 12, -13)
	card.Title = card:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	card.Title:SetPoint("TOPLEFT", 50, -18)
	card.Title:SetPoint("TOPRIGHT", -18, -18)
	card.Title:SetJustifyH("LEFT")
	card.Description = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	card.Description:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -9)
	card.Description:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -18, 15)
	card.Description:SetJustifyH("LEFT")
	card.Description:SetJustifyV("TOP")
	card.Description:SetWordWrap(true)
	card.Description:SetMaxLines(4)

	local function SetValue(value)
		self:SelectLayoutMode(key, value == true)
	end
	card.Check:SetScript("OnClick", function(control)
		SetValue(control:GetChecked() == true)
	end)
	card:SetScript("OnClick", function()
		local selected = key == "simpleMode" and self.selectedSimpleMode or self.selectedCompactMode
		SetValue(not selected)
	end)
	card:SetScript("OnEnter", function(control)
		control.BFL_Hovered = true
		self:RefreshLayoutOption(control)
	end)
	card:SetScript("OnLeave", function(control)
		control.BFL_Hovered = nil
		self:RefreshLayoutOption(control)
	end)

	card.BFL_TitleKey = titleKey
	card.BFL_DescriptionKey = descriptionKey
	card.BFL_TitleFallback = key == "simpleMode" and "Simple Mode" or "Compact Mode"
	card.BFL_DescriptionFallback = key == "simpleMode"
		and "Use a simplified Friends frame layout."
		or "Reduce friend-row height to fit more entries on screen."
	return card
end

function AppearanceOnboarding:BuildLayoutStep(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel.Cards = {
		self:CreateLayoutOption(panel, 0, "simpleMode", "SETTINGS_SIMPLE_MODE", "SETTINGS_SIMPLE_MODE_DESC"),
		self:CreateLayoutOption(panel, -132, "compactMode", "SETTINGS_COMPACT_MODE", "SETTINGS_COMPACT_MODE_DESC"),
	}
	self.layoutPanel = panel
	self.layoutCards = panel.Cards
end

function AppearanceOnboarding:RefreshLayoutOption(card)
	if not card then
		return
	end
	local palette = self.palette or self:GetPalette()
	local selected = card.BFL_LayoutKey == "simpleMode" and self.selectedSimpleMode == true
		or card.BFL_LayoutKey == "compactMode" and self.selectedCompactMode == true
	local background = selected and palette.selected or (card.BFL_Hovered and palette.hover or palette.card)
	local border = selected and palette.accent or palette.border
	SetBackdropColors(card, background, border)
	local engine = BFL:GetModule("SkinEngine")
	if engine and engine.IsActive and engine:IsActive() and card.BFL_DarkBackdrop then
		engine:StyleBackdrop(card, background, border)
	end
	card.Check:SetChecked(selected)
	SetFontColor(card.Title, palette.text)
	SetFontColor(card.Description, WithAlpha(palette.text, 0.78))
end

function AppearanceOnboarding:CreateSummaryRow(parent, yOffset)
	local row = CreateBackdropFrame("Frame", parent)
	row:SetHeight(64)
	row:SetPoint("TOPLEFT", 0, yOffset)
	row:SetPoint("TOPRIGHT", 0, yOffset)
	row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.Label:SetPoint("LEFT", 18, 0)
	row.Label:SetWidth(155)
	row.Label:SetJustifyH("LEFT")
	row.Value = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	row.Value:SetPoint("LEFT", row.Label, "RIGHT", 10, 0)
	row.Value:SetPoint("RIGHT", -18, 0)
	row.Value:SetJustifyH("RIGHT")
	return row
end

function AppearanceOnboarding:BuildSummaryStep(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel.StyleRow = self:CreateSummaryRow(panel, 0)
	panel.ThemeRow = self:CreateSummaryRow(panel, -68)
	panel.SimpleModeRow = self:CreateSummaryRow(panel, -136)
	panel.CompactModeRow = self:CreateSummaryRow(panel, -204)
	panel.ChangeLater = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	panel.ChangeLater:SetPoint("TOPLEFT", panel.CompactModeRow, "BOTTOMLEFT", 10, -22)
	panel.ChangeLater:SetPoint("TOPRIGHT", panel.CompactModeRow, "BOTTOMRIGHT", -10, -22)
	panel.ChangeLater:SetJustifyH("CENTER")
	panel.ChangeLater:SetWordWrap(true)
	panel.ReloadNote = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	panel.ReloadNote:SetPoint("TOPLEFT", panel.ChangeLater, "BOTTOMLEFT", 0, -24)
	panel.ReloadNote:SetPoint("TOPRIGHT", panel.ChangeLater, "BOTTOMRIGHT", 0, -24)
	panel.ReloadNote:SetJustifyH("CENTER")
	panel.ReloadNote:SetWordWrap(true)
	panel.ReloadNote:Hide()
	self.summaryPanel = panel
end

function AppearanceOnboarding:BuildFooter(frame)
	self.backButton = self:CreateNavigationButton(frame, 108, 26, function()
		self:PreviousStep()
	end)
	self.backButton:SetPoint("BOTTOMLEFT", 14, 5)
	self.laterButton = self:CreateNavigationButton(frame, 138, 26, function()
		self:Defer()
	end)
	self.laterButton:SetPoint("BOTTOMRIGHT", -174, 5)
	self.primaryButton = self:CreateNavigationButton(frame, 154, 26, function()
		self:ActivatePrimaryAction()
	end)
	self.primaryButton:SetPoint("BOTTOMRIGHT", -14, 5)
	self.primaryButton.BFL_Primary = true
	self.combatNotice = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	self.combatNotice:SetPoint("BOTTOM", frame, "BOTTOM", 0, 35)
	self.combatNotice:SetWidth(450)
	self.combatNotice:SetJustifyH("CENTER")
	self.combatNotice:Hide()
end

function AppearanceOnboarding:OnFrameLoad(frame)
	self.frame = frame
	frame:SetMovable(false)
	if ButtonFrameTemplate_ShowPortrait then
		ButtonFrameTemplate_ShowPortrait(frame)
	end
	if ButtonFrameTemplate_ShowButtonBar then
		ButtonFrameTemplate_ShowButtonBar(frame)
	end
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end
	if frame.SetPortraitToAsset then
		frame:SetPortraitToAsset("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	elseif frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	end
	if frame.SetPortraitTexCoord then
		frame:SetPortraitTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	frame.CloseButton:SetScript("OnClick", function()
		self:Defer()
	end)
	self:BuildStyleStep(frame.Content)
	self:BuildThemeStep(frame.Content)
	self:BuildLayoutStep(frame.Content)
	self:BuildSummaryStep(frame.Content)
	self:BuildFooter(frame)
	if BFL.AddUniqueUISpecialFrame then
		BFL:AddUniqueUISpecialFrame("BFLAppearanceOnboardingFrame")
	end
	self:RefreshLocalizedText()
	self:ApplySkin("frame-load")
end

function AppearanceOnboarding:RefreshLocalizedText()
	if not self.frame then
		return
	end
	local locale = GetL()
	for _, card in ipairs(self.styleCards or {}) do
		card.Title:SetText(locale[card.BFL_TitleKey] or card.BFL_TitleFallback)
		card.Description:SetText(locale[card.BFL_DescriptionKey] or card.BFL_DescriptionFallback)
		if card.BFL_BadgeKey then
			card.Badge:SetText(locale[card.BFL_BadgeKey] or card.BFL_BadgeFallback)
		end
	end
	for _, card in ipairs(self.layoutCards or {}) do
		card.Title:SetText(locale[card.BFL_TitleKey] or card.BFL_TitleFallback)
		card.Description:SetText(locale[card.BFL_DescriptionKey] or card.BFL_DescriptionFallback)
	end
	SetNativeButtonText(self.backButton, locale.ONBOARDING_BACK or "Back")
	SetNativeButtonText(self.laterButton, locale.ONBOARDING_LATER or "Decide later")
	self.combatNotice:SetText(locale.ONBOARDING_COMBAT_WAIT or "Finish combat to continue setup.")
	self.summaryPanel.StyleRow.Label:SetText(locale.ONBOARDING_SUMMARY_STYLE or "Interface style")
	self.summaryPanel.ThemeRow.Label:SetText(locale.ONBOARDING_SUMMARY_THEME or "Theme")
	self.summaryPanel.SimpleModeRow.Label:SetText(locale.SETTINGS_SIMPLE_MODE or "Simple Mode")
	self.summaryPanel.CompactModeRow.Label:SetText(locale.SETTINGS_COMPACT_MODE or "Compact Mode")
	self.summaryPanel.ChangeLater:SetText(
		locale.ONBOARDING_CHANGE_LATER or "You can change all of these choices at any time in BetterFriendlist Settings."
	)
	self:RefreshStep()
end

function AppearanceOnboarding:GetStyleLabel(style)
	local locale = GetL()
	if style == STYLE_MODERN then
		return locale.SETTINGS_FRIENDS_UI_STYLE_MODERN or "Modern (Retail 12.1)"
	end
	return locale.SETTINGS_FRIENDS_UI_STYLE_LEGACY or "Legacy"
end

function AppearanceOnboarding:GetThemeLabel(theme)
	local ThemeManager = BFL:GetModule("ThemeManager")
	return ThemeManager and ThemeManager.GetThemeLabel and ThemeManager:GetThemeLabel(theme) or tostring(theme or "")
end

function AppearanceOnboarding:NeedsReload()
	if not self.snapshot or not self.selectedTheme or self.selectedTheme == self.snapshot.theme then
		return false
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	return ThemeManager
		and ThemeManager.ThemeSelectionRequiresReload
		and ThemeManager:ThemeSelectionRequiresReload(self.snapshot.theme, self.selectedTheme)
		or false
end

function AppearanceOnboarding:RefreshSummary()
	if not self.summaryPanel then
		return
	end
	local locale = GetL()
	self.summaryPanel.StyleRow.Value:SetText(self:GetStyleLabel(self.selectedStyle))
	self.summaryPanel.ThemeRow.Value:SetText(self:GetThemeLabel(self.selectedTheme))
	self.summaryPanel.SimpleModeRow.Value:SetText(self.selectedSimpleMode and (YES or "Enabled") or (NO or "Disabled"))
	self.summaryPanel.CompactModeRow.Value:SetText(self.selectedCompactMode and (YES or "Enabled") or (NO or "Disabled"))
	self.summaryPanel.ReloadNote:SetText(
		locale.ONBOARDING_RELOAD_NOTE or "This theme change will offer a UI reload after confirmation."
	)
	self.summaryPanel.ReloadNote:SetShown(self:NeedsReload())
end

function AppearanceOnboarding:RefreshStep()
	if not self.frame then
		return
	end
	local locale = GetL()
	local step = self.currentStep or 1
	self.frame.StepText:SetText(SafeFormat(locale.ONBOARDING_STEP_FORMAT or "Step %d of %d", step, TOTAL_STEPS))
	if step == 1 then
		self.frame.TitleContainer.TitleText:SetText(locale.ONBOARDING_WELCOME_TITLE or "Welcome to the new BetterFriendlist")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_WELCOME_DESC
				or "Retail 12.1 brings a fundamentally redesigned friendlist. Choose the interface that feels right for you."
		)
	elseif step == 2 then
		self.frame.TitleContainer.TitleText:SetText(locale.ONBOARDING_THEME_TITLE or "Make BetterFriendlist yours")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_THEME_DESC
				or "Choose a visual theme. Available themes are detected dynamically and most can be previewed immediately."
		)
	elseif step == 3 then
		self.frame.TitleContainer.TitleText:SetText(locale.ONBOARDING_LAYOUT_TITLE or "Shape your friendlist")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_LAYOUT_DESC
				or "Choose a simplified frame layout and denser friend rows. Both options can be combined."
		)
	else
		self.frame.TitleContainer.TitleText:SetText(locale.ONBOARDING_SUMMARY_TITLE or "Your BetterFriendlist is ready")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_SUMMARY_DESC
				or "Confirm your interface style, theme, and layout options to finish setup."
		)
	end

	self.stylePanel:SetShown(step == 1)
	self.themePanel:SetShown(step == 2)
	self.layoutPanel:SetShown(step == 3)
	self.summaryPanel:SetShown(step == 4)
	self.backButton:SetShown(step > 1)
	SetNativeButtonText(
		self.primaryButton,
		step == 4 and (locale.ONBOARDING_CONFIRM or "Use this setup") or (locale.ONBOARDING_NEXT or "Next")
	)
	local modernStyleAvailable = self:IsModernStyleAvailable()
	local selectedStyleAvailable = self.selectedStyle ~= STYLE_MODERN or modernStyleAvailable
	local canContinue = step == 1 and IsValidStyle(self.selectedStyle)
		or step == 2 and self.selectedTheme ~= nil
		or step == 3
		or step == 4 and IsValidStyle(self.selectedStyle) and self.selectedTheme ~= nil
	canContinue = canContinue and selectedStyleAvailable and not self:IsInCombat()
	self:SetNavigationButtonEnabled(self.primaryButton, canContinue)
	self.combatNotice:SetShown(self:IsInCombat())
	self:RefreshSummary()
	for _, card in ipairs(self.styleCards or {}) do
		card.BFL_Available = card.BFL_Value ~= STYLE_MODERN or modernStyleAvailable
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.themeCards or {}) do
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.layoutCards or {}) do
		self:RefreshLayoutOption(card)
	end
	self:ApplySkin("step")
end

function AppearanceOnboarding:ApplySkin()
	if not self.frame then
		return
	end
	self.palette = self:GetPalette()
	local palette = self.palette
	self.frame.HeaderDivider:SetColorTexture(UnpackColor(WithAlpha(palette.accent, 0.36)))
	SetFontColor(self.frame.StepText, palette.accent)
	SetFontColor(self.frame.Subtitle, WithAlpha(palette.text, 0.84))
	SetFontColor(self.combatNotice, palette.accent)
	for _, card in ipairs(self.styleCards or {}) do
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.themeCards or {}) do
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.layoutCards or {}) do
		self:RefreshLayoutOption(card)
	end
	for _, row in ipairs({
		self.summaryPanel and self.summaryPanel.StyleRow,
		self.summaryPanel and self.summaryPanel.ThemeRow,
		self.summaryPanel and self.summaryPanel.SimpleModeRow,
		self.summaryPanel and self.summaryPanel.CompactModeRow,
	}) do
		if row then
			SetBackdropColors(row, palette.card, palette.border)
			SetFontColor(row.Label, WithAlpha(palette.text, 0.70))
			SetFontColor(row.Value, palette.accent)
		end
	end
	if self.summaryPanel then
		SetFontColor(self.summaryPanel.ChangeLater, WithAlpha(palette.text, 0.78))
		SetFontColor(self.summaryPanel.ReloadNote, palette.accent)
	end

	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	if theme == "dark" or theme == "custom" then
		local engine = BFL:GetModule("SkinEngine")
		if engine and engine.IsActive and engine:IsActive() then
			engine:SkinFrame(self.frame, "popup", { stripTextures = true, textureAlpha = 0.04 })
			engine:StripButtonFrameArtwork(self.frame)
			engine:SkinFrame(self.frame.Inset, "inset", { stripTextures = true })
			for _, button in ipairs({ self.backButton, self.laterButton, self.primaryButton }) do
				engine:SkinButton(button)
			end
			for _, card in ipairs(self.styleCards or {}) do
				engine:SkinFrame(card, "panel")
				engine:ClearNativeBackdrop(card)
				card.SelectControl.BFL_DarkCompactCheckButton = true
				engine:SkinCheckButton(card.SelectControl)
				engine:SkinFrame(card.Diagram, "inset")
				engine:ClearNativeBackdrop(card.Diagram)
				self:RefreshChoiceCard(card)
			end
			for _, card in ipairs(self.themeCards or {}) do
				engine:SkinFrame(card, "panel")
				engine:ClearNativeBackdrop(card)
				card.SelectControl.BFL_DarkCompactCheckButton = true
				engine:SkinCheckButton(card.SelectControl)
				self:RefreshChoiceCard(card)
			end
			for _, card in ipairs(self.layoutCards or {}) do
				engine:SkinFrame(card, "panel")
				engine:ClearNativeBackdrop(card)
				card.Check.BFL_DarkCompactCheckButton = true
				engine:SkinCheckButton(card.Check)
				self:RefreshLayoutOption(card)
			end
			for _, row in ipairs({
				self.summaryPanel and self.summaryPanel.StyleRow,
				self.summaryPanel and self.summaryPanel.ThemeRow,
				self.summaryPanel and self.summaryPanel.SimpleModeRow,
				self.summaryPanel and self.summaryPanel.CompactModeRow,
			}) do
				if row then
					engine:SkinFrame(row, "panel")
					engine:ClearNativeBackdrop(row)
				end
			end
		end
	elseif theme == "elvui" then
		local ElvUISkin = BFL:GetModule("ElvUISkin")
		if ElvUISkin and ElvUISkin.SkinAppearanceOnboarding then
			ElvUISkin:SkinAppearanceOnboarding(self.frame, self)
		end
	elseif theme == "ellesmereui" then
		local EllesmereUISkin = BFL:GetModule("EllesmereUISkin")
		if EllesmereUISkin and EllesmereUISkin.SkinAppearanceOnboarding then
			EllesmereUISkin:SkinAppearanceOnboarding(self.frame, self)
		end
	end
end

function AppearanceOnboarding:AnchorFrame()
	local frame = self.frame
	if not (frame and UIParent and BetterFriendsFrame) then
		return
	end
	frame:ClearAllPoints()
	local frameWidth = frame:GetWidth() or 520
	local parentWidth = UIParent:GetWidth() or 0
	local mainLeft = BetterFriendsFrame:GetLeft()
	local mainRight = BetterFriendsFrame:GetRight()
	local offset = 8
	local FriendsUI = BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.GetAuxiliaryWindowOffset then
		offset = FriendsUI:GetAuxiliaryWindowOffset()
	end
	if mainRight and parentWidth > 0 and mainRight + offset + frameWidth <= parentWidth - 8 then
		frame:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", offset, 0)
	elseif mainLeft and mainLeft - frameWidth >= 8 then
		frame:SetPoint("TOPRIGHT", BetterFriendsFrame, "TOPLEFT", -8, 0)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function AppearanceOnboarding:ScheduleTryShow(reason)
	if self.tryShowScheduled then
		return
	end
	self.tryShowScheduled = true
	local function Run()
		self.tryShowScheduled = nil
		self:TryShow(reason)
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, Run)
	else
		Run()
	end
end

function AppearanceOnboarding:TryShow(reason)
	if self.active or not self.frame or not BetterFriendsFrame then
		return false
	end
	local DB = BFL:GetModule("DB")
	local eligible, blockedReason = self:EvaluateEligibility({
		isRetail = BFL.IsRetail == true,
		completedVersion = DB and DB:Get("appearanceOnboardingVersion", 0) or 0,
		requiredVersion = ONBOARDING_VERSION,
		sessionDeferred = self.sessionDeferred,
		playerLoggedIn = self.playerLoggedIn,
		frameShown = BetterFriendsFrame:IsShown() == true,
		socialUIEnabled = self:IsSocialUIEnabled(),
		forceModern = self:IsModernForceEnabled(),
		inCombat = self:IsInCombat(),
	})
	if not eligible then
		self.pendingShow = blockedReason == "combat" and true or nil
		return false
	end
	self.pendingShow = nil
	return self:Begin(reason)
end

function AppearanceOnboarding:Begin()
	if self.active or not BetterFriendlistDB then
		return false
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	local storedTheme = BetterFriendlistDB.theme
	if not (ThemeManager and ThemeManager.IsValidTheme and ThemeManager:IsValidTheme(storedTheme)) then
		storedTheme = ThemeManager and ThemeManager.GetStoredTheme and ThemeManager:GetStoredTheme() or "blizzard"
	end
	self.snapshot = {
		style = BetterFriendlistDB.friendsFrameStyle,
		theme = storedTheme,
		enableElvUISkin = BetterFriendlistDB.enableElvUISkin == true,
		simpleMode = BetterFriendlistDB.simpleMode == true,
		compactMode = BetterFriendlistDB.compactMode == true,
		completedVersion = BetterFriendlistDB.appearanceOnboardingVersion,
	}
	self.selectedStyle = IsValidStyle(self.snapshot.style) and self.snapshot.style or nil
	self.selectedTheme = ThemeManager and ThemeManager.IsThemeAvailable and ThemeManager:IsThemeAvailable(storedTheme)
		and storedTheme
		or nil
	self.selectedSimpleMode = self.snapshot.simpleMode
	self.selectedCompactMode = self.snapshot.compactMode
	self.currentStep = 1
	self.active = true
	self.confirmed = false
	self:RebuildThemeCards()
	if not self.selectedTheme then
		local themes = ThemeManager and ThemeManager.GetAvailableThemeIDs and ThemeManager:GetAvailableThemeIDs() or { "blizzard" }
		self.selectedTheme = themes[1]
	end
	self:RefreshLocalizedText()
	self:RefreshStep()
	self:AnchorFrame()
	self.suppressFrameHide = true
	self.frame:Show()
	self.frame:Raise()
	self.suppressFrameHide = nil
	return true
end

function AppearanceOnboarding:SelectStyle(style)
	if not IsValidStyle(style) or self:IsInCombat() then
		return false
	end
	if style == STYLE_MODERN and not self:IsModernStyleAvailable() then
		return false
	end
	self.selectedStyle = style
	local FriendsUI = BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.SetStyle then
		FriendsUI:SetStyle(style)
	end
	self:AnchorFrame()
	self:RefreshStep()
	return true
end

function AppearanceOnboarding:SelectTheme(theme)
	if self:IsInCombat() then
		return false
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if not (ThemeManager and ThemeManager.IsThemeAvailable and ThemeManager:IsThemeAvailable(theme)) then
		return false
	end
	self.selectedTheme = theme
	if ThemeManager.CanPreviewTheme and ThemeManager:CanPreviewTheme(theme, self.snapshot and self.snapshot.theme) then
		ThemeManager:SetTheme(theme, "appearance-onboarding-preview")
	end
	self:RefreshStep()
	return true
end

function AppearanceOnboarding:SelectLayoutMode(key, enabled)
	if self:IsInCombat() or (key ~= "simpleMode" and key ~= "compactMode") then
		return false
	end
	if key == "simpleMode" then
		self.selectedSimpleMode = enabled == true
	else
		self.selectedCompactMode = enabled == true
	end
	local Settings = BFL:GetModule("Settings")
	if key == "simpleMode" and Settings and Settings.OnSimpleModeChanged then
		Settings:OnSimpleModeChanged(self.selectedSimpleMode)
	elseif key == "compactMode" and Settings and Settings.OnCompactModeChanged then
		Settings:OnCompactModeChanged(self.selectedCompactMode)
	elseif BetterFriendlistDB then
		BetterFriendlistDB[key] = enabled == true
	end
	self:AnchorFrame()
	self:RefreshStep()
	return true
end

function AppearanceOnboarding:ActivatePrimaryAction()
	if self:IsInCombat() then
		return
	end
	if self.currentStep == 1 then
		if not IsValidStyle(self.selectedStyle) then
			return
		end
		self.currentStep = 2
	elseif self.currentStep == 2 then
		if not self.selectedTheme then
			return
		end
		self.currentStep = 3
	elseif self.currentStep == 3 then
		self.currentStep = 4
	else
		self:Commit()
		return
	end
	self:RefreshStep()
end

function AppearanceOnboarding:PreviousStep()
	if self.currentStep and self.currentStep > 1 then
		self.currentStep = self.currentStep - 1
		self:RefreshStep()
	end
end

function AppearanceOnboarding:RestoreSnapshot(skipVisualRefresh)
	local snapshot = self.snapshot
	if not (snapshot and BetterFriendlistDB) then
		return
	end
	BetterFriendlistDB.friendsFrameStyle = snapshot.style
	BetterFriendlistDB.theme = snapshot.theme
	BetterFriendlistDB.enableElvUISkin = snapshot.enableElvUISkin
	BetterFriendlistDB.simpleMode = snapshot.simpleMode
	BetterFriendlistDB.compactMode = snapshot.compactMode
	BetterFriendlistDB.appearanceOnboardingVersion = snapshot.completedVersion
	if skipVisualRefresh then
		return
	end
	if BFL.SettingsVersion then
		BFL.SettingsVersion = BFL.SettingsVersion + 1
	end
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.InvalidateSettingsCache then
		FriendsList:InvalidateSettingsCache()
	end
	local FriendsUI = BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.ApplyEffectiveStyle then
		FriendsUI:ApplyEffectiveStyle("appearance-onboarding-rollback")
	end
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.OnSimpleModeChanged then
		Settings:OnSimpleModeChanged(snapshot.simpleMode == true)
	end
	if Settings and Settings.OnCompactModeChanged then
		Settings:OnCompactModeChanged(snapshot.compactMode == true)
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme("appearance-onboarding-rollback")
	end
end

function AppearanceOnboarding:HideFrame()
	if self.frame and self.frame:IsShown() then
		self.suppressFrameHide = true
		self.frame:Hide()
		self.suppressFrameHide = nil
	end
end

function AppearanceOnboarding:Defer()
	if not self.active then
		self:HideFrame()
		return
	end
	self.sessionDeferred = true
	self.active = false
	self:RestoreSnapshot(false)
	self.snapshot = nil
	self:HideFrame()
end

function AppearanceOnboarding:Commit()
	if not self.active or self:IsInCombat() or not IsValidStyle(self.selectedStyle) or not self.selectedTheme then
		return false
	end
	if self.selectedStyle == STYLE_MODERN and not self:IsModernStyleAvailable() then
		return false
	end
	local needsReload = self:NeedsReload()
	local FriendsUI = BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.SetStyle then
		FriendsUI:SetStyle(self.selectedStyle)
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.SetTheme then
		ThemeManager:SetTheme(self.selectedTheme, "appearance-onboarding-confirm")
	end
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.OnSimpleModeChanged then
		Settings:OnSimpleModeChanged(self.selectedSimpleMode == true)
	else
		BetterFriendlistDB.simpleMode = self.selectedSimpleMode == true
	end
	if Settings and Settings.OnCompactModeChanged then
		Settings:OnCompactModeChanged(self.selectedCompactMode == true)
	else
		BetterFriendlistDB.compactMode = self.selectedCompactMode == true
	end
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("appearanceOnboardingVersion", ONBOARDING_VERSION)
	else
		BetterFriendlistDB.appearanceOnboardingVersion = ONBOARDING_VERSION
	end
	self.confirmed = true
	self.active = false
	self.snapshot = nil
	self:HideFrame()
	if needsReload and ThemeManager and ThemeManager.ShowReloadDialog then
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				ThemeManager:ShowReloadDialog()
			end)
		else
			ThemeManager:ShowReloadDialog()
		end
	end
	return true
end

function AppearanceOnboarding:OnFrameHide()
	if self.suppressFrameHide or not self.active then
		return
	end
	self:Defer()
end

function AppearanceOnboarding:HookMainFrame()
	if self.mainFrameHooked or not BetterFriendsFrame then
		return
	end
	self.mainFrameHooked = true
	BetterFriendsFrame:HookScript("OnShow", function()
		self:ScheduleTryShow("friends-frame-show")
	end)
	BetterFriendsFrame:HookScript("OnHide", function()
		if self.active then
			self:Defer()
		end
	end)
end

function AppearanceOnboarding:OnModernAvailabilityChanged(reason)
	if self.active then
		self:RefreshStep()
	elseif self:IsModernStyleAvailable() then
		self:ScheduleTryShow(reason or "modern-availability")
	end
end

function AppearanceOnboarding:RegisterTests()
	if self.testsRegistered then
		return
	end
	local TestSuite = BFL:GetModule("TestSuite")
	if not TestSuite or not TestSuite.RegisterTest then
		return
	end
	self.testsRegistered = true
	TestSuite:RegisterTest("ui", "AppearanceOnboarding_Eligibility", {
		action = function(V)
			local base = {
				isRetail = true,
				completedVersion = 0,
				requiredVersion = ONBOARDING_VERSION,
				sessionDeferred = false,
				playerLoggedIn = true,
				frameShown = true,
				socialUIEnabled = true,
				forceModern = false,
				inCombat = false,
			}
			local eligible = self:EvaluateEligibility(base)
			V:Assert(eligible, "Eligible Retail profiles receive onboarding")
			base.isRetail = false
			V:Assert(not self:EvaluateEligibility(base), "Classic never receives Retail onboarding")
			base.isRetail = true
			base.completedVersion = ONBOARDING_VERSION
			V:Assert(not self:EvaluateEligibility(base), "Confirmed profiles are not prompted again")
			base.completedVersion = 0
			base.inCombat = true
			V:Assert(not self:EvaluateEligibility(base), "Onboarding waits until combat ends")
			base.inCombat = false
			base.sessionDeferred = true
			V:Assert(not self:EvaluateEligibility(base), "Decide later suppresses the prompt for the current session")
			base.sessionDeferred = false
			base.socialUIEnabled = false
			V:Assert(not self:EvaluateEligibility(base), "Unavailable SocialUI keeps Retail on the safe Legacy fallback")
			base.forceModern = true
			V:Assert(self:EvaluateEligibility(base), "Developer override makes onboarding available while SocialUI is disabled")
			base.isRetail = false
			V:Assert(not self:EvaluateEligibility(base), "Developer override never enables onboarding on Classic")
		end,
	})
	TestSuite:RegisterTest("settings", "AppearanceOnboarding_DynamicThemes", {
		action = function(V)
			local ThemeManager = BFL:GetModule("ThemeManager")
			local options, order = ThemeManager:GetThemeOptions()
			local seen = {}
			V:Assert(#order >= 3, "Theme registry exposes built-in themes")
			for _, theme in ipairs(order) do
				V:Assert(not seen[theme], "Theme registry does not duplicate " .. tostring(theme))
				V:Assert(ThemeManager:IsValidTheme(theme), "Theme registry returns only valid themes")
				V:Assert(ThemeManager:IsThemeAvailable(theme), "Theme registry returns only available themes")
				V:Assert(type(options[theme]) == "string" and options[theme] ~= "", "Every theme has a label")
				seen[theme] = true
			end
		end,
	})
	TestSuite:RegisterTest("ui", "AppearanceOnboarding_FrameContract", {
		action = function(V)
			V:Assert(self.frame ~= nil, "Onboarding XML creates its Retail dialog")
			V:Assert(
				self.frame and self.frame.NineSlice and self.frame.Inset and self.frame.PortraitContainer,
				"Onboarding uses Blizzard's portrait button-frame shell"
			)
			V:Assert(self.stylePanel and self.themePanel and self.layoutPanel and self.summaryPanel, "All onboarding steps exist")
			V:Assert(self.primaryButton and self.laterButton and self.backButton, "Onboarding exposes bounded navigation")
			for _, card in ipairs(self.styleCards or {}) do
				V:Assert(card.SelectControl ~= nil, "Style cards expose a dedicated Blizzard radio control")
				V:Assert(card.Diagram ~= nil, "Style cards retain an isolated interface preview")
			end
			V:Assert(#(self.layoutCards or {}) == 2, "Layout step exposes Simple and Compact Mode")
			for _, card in ipairs(self.layoutCards or {}) do
				V:Assert(card.Check ~= nil, "Layout options use Blizzard checkboxes")
			end
		end,
	})
end

function AppearanceOnboarding:Initialize()
	if not BFL.IsRetail then
		return
	end
	self:HookMainFrame()
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		self:RefreshStep()
		if self.pendingShow then
			self:ScheduleTryShow("combat-ended")
		end
	end, 90)
	BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
		if self.active then
			self:RefreshStep()
		end
	end, 90)
	BFL:RegisterEventCallback("SOCIAL_UI_SYSTEM_STATUS_UPDATED", function()
		if self.active then
			self:RefreshStep()
		else
			self:ScheduleTryShow("social-ui-status")
		end
	end, 90)
	BFL:RegisterEventCallback("ADDONS_UNLOADING", function()
		if self.active and self.snapshot then
			self.active = false
			self:RestoreSnapshot(true)
			self.snapshot = nil
		end
	end, 5)
end

function AppearanceOnboarding:OnPlayerLogin()
	if not BFL.IsRetail then
		return
	end
	self.playerLoggedIn = true
	self:HookMainFrame()
	self:RegisterTests()
	if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
		self:ScheduleTryShow("player-login")
	end
end
