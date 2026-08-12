-- Modules/AppearanceOnboarding.lua
-- One-time Retail 12.1 interface-style and theme onboarding.

local ADDON_NAME, BFL = ...
local AppearanceOnboarding = BFL:RegisterModule("AppearanceOnboarding", {})

local ONBOARDING_VERSION = 1
local STYLE_MODERN = "modern"
local STYLE_LEGACY = "legacy"
local TOTAL_STEPS = 3
local CARD_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	tile = false,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
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

local function CreateBackdropFrame(frameType, parent)
	local template = BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame(frameType or "Frame", nil, parent, template)
	if frame.SetBackdrop then
		frame:SetBackdrop(CARD_BACKDROP)
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

function AppearanceOnboarding:CreateFlatButton(parent, width, height, onClick)
	local button = CreateBackdropFrame("Button", parent)
	button:SetSize(width, height)
	button.BFL_Enabled = true
	button.Label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	button.Label:SetPoint("CENTER")
	button.Label:SetJustifyH("CENTER")
	button:SetScript("OnClick", function(control)
		if control.BFL_Enabled ~= false and onClick then
			onClick()
		end
	end)
	button:SetScript("OnEnter", function(control)
		control.BFL_Hovered = true
		self:RefreshFlatButton(control)
	end)
	button:SetScript("OnLeave", function(control)
		control.BFL_Hovered = nil
		self:RefreshFlatButton(control)
	end)
	return button
end

function AppearanceOnboarding:SetFlatButtonEnabled(button, enabled)
	if not button then
		return
	end
	button.BFL_Enabled = enabled == true
	button:SetEnabled(enabled == true)
	self:RefreshFlatButton(button)
end

function AppearanceOnboarding:RefreshFlatButton(button)
	if not button then
		return
	end
	local palette = self.palette or self:GetPalette()
	local enabled = button.BFL_Enabled ~= false
	local background = button.BFL_Hovered and enabled and palette.hover or palette.card
	local border = button.BFL_Primary and palette.accent or palette.border
	if button.BFL_Primary and enabled then
		background = button.BFL_Hovered and WithAlpha(palette.accent, 0.32) or WithAlpha(palette.accent, 0.20)
	end
	SetBackdropColors(button, background, border)
	SetFontColor(button.Label, enabled and palette.text or palette.disabledText)
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
	card.Title:SetPoint("TOPLEFT", 18, -16)
	card.Title:SetPoint("TOPRIGHT", -142, -16)
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
	card.Badge:SetPoint("BOTTOMLEFT", 18, 13)
	card.Badge:SetJustifyH("LEFT")
	card.Badge:Hide()
	card.Check = card:CreateTexture(nil, "OVERLAY")
	card.Check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	card.Check:SetSize(32, 32)
	card.Check:SetPoint("TOPRIGHT", -8, -7)
	card.Check:Hide()
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

function AppearanceOnboarding:CreateStyleDiagram(card, style)
	local preview = CreateBackdropFrame("Frame", card)
	preview:SetSize(104, 88)
	preview:SetPoint("RIGHT", -18, 0)
	card.Diagram = preview
	preview.Pieces = {}
	if style == STYLE_MODERN then
		for index = 1, 3 do
			preview.Pieces[#preview.Pieces + 1] = CreatePreviewTexture(preview, 8, -10 - ((index - 1) * 22), 12, 15)
		end
		for index = 1, 3 do
			preview.Pieces[#preview.Pieces + 1] = CreatePreviewTexture(preview, 28, -10 - ((index - 1) * 22), 67, 15)
		end
	else
		for index = 1, 3 do
			preview.Pieces[#preview.Pieces + 1] = CreatePreviewTexture(preview, 8 + ((index - 1) * 29), -9, 25, 10)
		end
		for index = 1, 3 do
			preview.Pieces[#preview.Pieces + 1] = CreatePreviewTexture(preview, 8, -27 - ((index - 1) * 18), 87, 12)
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
	for index, texture in ipairs(card.Diagram.Pieces or {}) do
		local useAccent = card.BFL_Value == STYLE_MODERN and index <= 3
		local color = useAccent and WithAlpha(palette.accent, 0.82) or WithAlpha(palette.text, 0.38)
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
	card.Accent:SetColorTexture(UnpackColor(palette.accent))
	card.Accent:SetShown(selected)
	card.Check:SetVertexColor(UnpackColor(palette.accent))
	card.Check:SetShown(selected)
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
		local card = self:CreateChoiceCard(panel, 142, function(value)
			self:SelectStyle(value)
		end)
		local yOffset = -((index - 1) * 154)
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
	local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 0, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", -26, 0)
	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(420)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	panel.ScrollFrame = scrollFrame
	panel.ScrollChild = scrollChild
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
	local cardHeight = 96
	local spacing = 10
	for index, theme in ipairs(themes) do
		local card = self:CreateChoiceCard(self.themePanel.ScrollChild, cardHeight, function(value)
			self:SelectTheme(value)
		end)
		local yOffset = -((index - 1) * (cardHeight + spacing))
		card:SetPoint("TOPLEFT", 0, yOffset)
		card:SetPoint("TOPRIGHT", 0, yOffset)
		card.BFL_Kind = "theme"
		card.BFL_Value = theme
		card.BFL_Available = true
		card.Title:ClearAllPoints()
		card.Title:SetPoint("TOPLEFT", 18, -16)
		card.Title:SetPoint("TOPRIGHT", -48, -16)
		card.Description:ClearAllPoints()
		card.Description:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -8)
		card.Description:SetPoint("TOPRIGHT", card.Title, "BOTTOMRIGHT", 0, -8)
		card.Description:SetMaxLines(3)
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

	local height = math.max(1, (#themes * (cardHeight + spacing)) - spacing)
	self.themePanel.ScrollChild:SetHeight(height)
	self.themePanel.ScrollFrame:SetVerticalScroll(0)
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
	panel.ThemeRow = self:CreateSummaryRow(panel, -78)
	panel.ChangeLater = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	panel.ChangeLater:SetPoint("TOPLEFT", panel.ThemeRow, "BOTTOMLEFT", 10, -26)
	panel.ChangeLater:SetPoint("TOPRIGHT", panel.ThemeRow, "BOTTOMRIGHT", -10, -26)
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
	self.backButton = self:CreateFlatButton(frame, 108, 36, function()
		self:PreviousStep()
	end)
	self.backButton:SetPoint("BOTTOMLEFT", 31, 22)
	self.laterButton = self:CreateFlatButton(frame, 138, 36, function()
		self:Defer()
	end)
	self.laterButton:SetPoint("BOTTOM", 0, 22)
	self.primaryButton = self:CreateFlatButton(frame, 154, 36, function()
		self:ActivatePrimaryAction()
	end)
	self.primaryButton:SetPoint("BOTTOMRIGHT", -31, 22)
	self.primaryButton.BFL_Primary = true
	self.combatNotice = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	self.combatNotice:SetPoint("BOTTOM", frame, "BOTTOM", 0, 63)
	self.combatNotice:SetWidth(450)
	self.combatNotice:SetJustifyH("CENTER")
	self.combatNotice:Hide()
end

function AppearanceOnboarding:OnFrameLoad(frame)
	self.frame = frame
	frame:SetMovable(false)
	frame.CloseButton:SetScript("OnClick", function()
		self:Defer()
	end)
	self:BuildStyleStep(frame.Content)
	self:BuildThemeStep(frame.Content)
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
	self.backButton.Label:SetText(locale.ONBOARDING_BACK or "Back")
	self.laterButton.Label:SetText(locale.ONBOARDING_LATER or "Decide later")
	self.combatNotice:SetText(locale.ONBOARDING_COMBAT_WAIT or "Finish combat to continue setup.")
	self.summaryPanel.StyleRow.Label:SetText(locale.ONBOARDING_SUMMARY_STYLE or "Interface style")
	self.summaryPanel.ThemeRow.Label:SetText(locale.ONBOARDING_SUMMARY_THEME or "Theme")
	self.summaryPanel.ChangeLater:SetText(
		locale.ONBOARDING_CHANGE_LATER or "You can change both choices at any time in BetterFriendlist Settings."
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
		self.frame.Title:SetText(locale.ONBOARDING_WELCOME_TITLE or "Welcome to the new BetterFriendlist")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_WELCOME_DESC
				or "Retail 12.1 brings a fundamentally redesigned friendlist. Choose the interface that feels right for you."
		)
	elseif step == 2 then
		self.frame.Title:SetText(locale.ONBOARDING_THEME_TITLE or "Make BetterFriendlist yours")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_THEME_DESC
				or "Choose a visual theme. Available themes are detected dynamically and most can be previewed immediately."
		)
	else
		self.frame.Title:SetText(locale.ONBOARDING_SUMMARY_TITLE or "Your BetterFriendlist is ready")
		self.frame.Subtitle:SetText(
			locale.ONBOARDING_SUMMARY_DESC or "Confirm your interface style and theme to finish setup."
		)
	end

	self.stylePanel:SetShown(step == 1)
	self.themePanel:SetShown(step == 2)
	self.summaryPanel:SetShown(step == 3)
	self.backButton:SetShown(step > 1)
	self.primaryButton.Label:SetText(step == 3 and (locale.ONBOARDING_CONFIRM or "Use this setup") or (locale.ONBOARDING_NEXT or "Next"))
	local modernStyleAvailable = self:IsModernStyleAvailable()
	local selectedStyleAvailable = self.selectedStyle ~= STYLE_MODERN or modernStyleAvailable
	local canContinue = step == 1 and IsValidStyle(self.selectedStyle)
		or step == 2 and self.selectedTheme ~= nil
		or step == 3 and IsValidStyle(self.selectedStyle) and self.selectedTheme ~= nil
	canContinue = canContinue and selectedStyleAvailable and not self:IsInCombat()
	self:SetFlatButtonEnabled(self.primaryButton, canContinue)
	self.combatNotice:SetShown(self:IsInCombat())
	self:RefreshSummary()
	for _, card in ipairs(self.styleCards or {}) do
		card.BFL_Available = card.BFL_Value ~= STYLE_MODERN or modernStyleAvailable
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.themeCards or {}) do
		self:RefreshChoiceCard(card)
	end
	self:ApplySkin("step")
end

function AppearanceOnboarding:ApplySkin()
	if not self.frame then
		return
	end
	self.palette = self:GetPalette()
	local palette = self.palette
	SetBackdropColors(self.frame, palette.window, palette.border)
	self.frame.AccentBar:SetColorTexture(UnpackColor(palette.accent))
	self.frame.HeaderDivider:SetColorTexture(UnpackColor(WithAlpha(palette.accent, 0.36)))
	SetFontColor(self.frame.Title, palette.text)
	SetFontColor(self.frame.StepText, palette.accent)
	SetFontColor(self.frame.Subtitle, WithAlpha(palette.text, 0.84))
	SetFontColor(self.combatNotice, palette.accent)
	for _, button in ipairs({ self.backButton, self.laterButton, self.primaryButton }) do
		self:RefreshFlatButton(button)
	end
	for _, card in ipairs(self.styleCards or {}) do
		self:RefreshChoiceCard(card)
	end
	for _, card in ipairs(self.themeCards or {}) do
		self:RefreshChoiceCard(card)
	end
	for _, row in ipairs({ self.summaryPanel and self.summaryPanel.StyleRow, self.summaryPanel and self.summaryPanel.ThemeRow }) do
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
		completedVersion = BetterFriendlistDB.appearanceOnboardingVersion,
	}
	self.selectedStyle = IsValidStyle(self.snapshot.style) and self.snapshot.style or nil
	self.selectedTheme = ThemeManager and ThemeManager.IsThemeAvailable and ThemeManager:IsThemeAvailable(storedTheme)
		and storedTheme
		or nil
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
			V:Assert(self.stylePanel and self.themePanel and self.summaryPanel, "All onboarding steps exist")
			V:Assert(self.primaryButton and self.laterButton and self.backButton, "Onboarding exposes bounded navigation")
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
