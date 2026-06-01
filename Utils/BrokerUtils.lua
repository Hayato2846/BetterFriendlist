-- Utils/BrokerUtils.lua
-- Shared utilities for Data Broker plugins (Friends Broker + Guild Broker)
-- Extracted from Modules/Broker.lua to avoid duplication

local ADDON_NAME, BFL = ...

BFL.BrokerUtils = {}
local BU = BFL.BrokerUtils

-- ========================================
-- Color Wrapper
-- ========================================
local COLOR_TABLE = {
	dkyellow = "ffcc00",
	ltyellow = "ffff99",
	ltblue = "6699ff",
	ltgray = "b0b0b0",
	gray = "808080",
	white = "ffffff",
	green = "00ff00",
	red = "ff0000",
	gold = "ffd700",
}

function BU.C(color, text)
	if not text then
		return ""
	end

	-- Check if it's a class color (try direct match first, then convert from localized name)
	local classColor = RAID_CLASS_COLORS[color]
	if not classColor then
		local classFile = BFL.ClassUtils and BFL.ClassUtils:GetClassFileFromClassName(color)
		if classFile then
			classColor = RAID_CLASS_COLORS[classFile]
		end
	end

	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end

	-- Otherwise use predefined or custom hex
	local hex = COLOR_TABLE[color] or color
	if color == "dkyellow" or color == "ltyellow" or color == "gold" then
		hex = (BFL.GetThemeAccentHex and BFL:GetThemeAccentHex(hex)) or hex
	end
	return "|cff" .. hex .. text .. "|r"
end

-- ========================================
-- Status Icon Helper (AFK/DND/Online)
-- ========================================
function BU.GetStatusIcon(isAFK, isDND, isMobile)
	local showMobileAsAFK = BetterFriendlistDB and BetterFriendlistDB.showMobileAsAFK

	if isAFK or (isMobile and showMobileAsAFK) then
		return "|TInterface\\FriendsFrame\\StatusIcon-Away:12:12:0:0:32:32:5:27:5:27|t"
	elseif isDND then
		return "|TInterface\\FriendsFrame\\StatusIcon-DnD:12:12:0:0:32:32:5:27:5:27|t"
	else
		return "|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:0:32:32:5:27:5:27|t"
	end
end

-- ========================================
-- Faction Icon Helper
-- ========================================
function BU.GetFactionIcon(factionName)
	if not factionName then
		return ""
	end

	if factionName == "Alliance" then
		return "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|t"
	elseif factionName == "Horde" then
		return "|TInterface\\FriendsFrame\\PlusManz-Horde:16:16|t"
	else
		return "" -- Neutral or unknown
	end
end

-- ========================================
-- Class Color Text (from classFile or friend table)
-- ========================================

-- Color text by class file name (e.g., "WARRIOR", "PALADIN")
function BU.ClassColorTextByFile(classFile, text)
	if not text then
		return ""
	end
	local classColor = classFile and RAID_CLASS_COLORS[classFile]
	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end
	return text
end

-- Color text by friend data table (uses ClassUtils for classID/className resolution)
function BU.ClassColorText(friend, text)
	if not text then
		return ""
	end
	local classColor = BFL.ClassUtils and BFL.ClassUtils:GetClassColorForFriend(friend)
	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end
	return text
end

-- ========================================
-- Broker Tooltip Font Helpers
-- ========================================
local function GetBrokerFontSize(sizeOffset)
	local size = BetterFriendlistDB and tonumber(BetterFriendlistDB.brokerFontSize) or 12
	size = size + (sizeOffset or 0)
	return math.max(6, math.floor(size + 0.5))
end

function BU.GetBrokerFontObject(sizeOffset)
	local fontName = BetterFriendlistDB and BetterFriendlistDB.brokerFont or "Friz Quadrata TT"
	local fontSize = GetBrokerFontSize(sizeOffset)

	if BFL.FontManager and BFL.FontManager.ResolveFontPath and BFL.FontManager.GetOrCreateFontFamily then
		local fontPath = BFL.FontManager:ResolveFontPath(fontName)
		if fontPath then
			local useCustomNonLatinFont = BetterFriendlistDB and BetterFriendlistDB.brokerUseCustomFontForNonLatin == true
			local fontFlags = BetterFriendlistDB and BetterFriendlistDB.brokerFontFlags or "SLUG"
			local fontObject = BFL.FontManager:GetOrCreateFontFamily(
				fontPath,
				fontSize,
				fontFlags,
				false,
				useCustomNonLatinFont
			)
			if fontObject then
				return fontObject
			end
		end
	end

	return (sizeOffset and sizeOffset > 0) and "GameTooltipHeaderText" or "GameTooltipText"
end

function BU.ApplyBrokerFontToFontString(fontString, sizeOffset)
	local valueType = type(fontString)
	if (valueType == "table" or valueType == "userdata") and fontString.SetFontObject then
		pcall(fontString.SetFontObject, fontString, BU.GetBrokerFontObject(sizeOffset))
	end
end

function BU.ApplyBrokerFontToCell(cell, sizeOffset)
	local valueType = type(cell)
	if (valueType == "table" or valueType == "userdata") and cell.SetFontObject then
		pcall(cell.SetFontObject, cell, BU.GetBrokerFontObject(sizeOffset))
		if cell.OnContentChanged then
			pcall(cell.OnContentChanged, cell)
		end
	end
end

function BU.ApplyBrokerFontToRow(row, sizeOffset)
	if not row then
		return
	end

	if row.Cells then
		for _, cell in pairs(row.Cells) do
			BU.ApplyBrokerFontToCell(cell, sizeOffset)
		end
	end

	if row.ColSpanCells then
		for _, cell in pairs(row.ColSpanCells) do
			BU.ApplyBrokerFontToCell(cell, sizeOffset)
		end
	end
end

function BU.ApplyBrokerFontToTooltip(tt, sizeOffset)
	if not tt or not tt.Rows then
		return
	end

	for _, row in pairs(tt.Rows) do
		BU.ApplyBrokerFontToRow(row, sizeOffset)
	end
end

-- ========================================
-- Broker Tooltip Appearance Helpers
-- ========================================
local DEFAULT_BROKER_SEPARATOR_COLOR = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }
local DEFAULT_BROKER_SEPARATOR_HEIGHT = 1
local DEFAULT_BROKER_TOOLTIP_BACKGROUND = { r = 0, g = 0, b = 0, a = 0.85 }

local BROKER_TOOLTIP_THEME_KEYS = {
	blizzard = true,
	dark = true,
	custom = true,
	elvui = true,
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

local function CopyColor(color)
	if type(color) ~= "table" then
		return nil
	end
	return {
		r = color.r ~= nil and color.r or color[1] or 1,
		g = color.g ~= nil and color.g or color[2] or 1,
		b = color.b ~= nil and color.b or color[3] or 1,
		a = color.a ~= nil and color.a or color[4] or 1,
	}
end

local function NormalizeColor(color, fallback)
	if type(color) ~= "table" then
		return fallback and CopyColor(fallback) or nil
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
		return fallback and CopyColor(fallback) or nil
	end

	return { r = r, g = g, b = b, a = a ~= nil and a or 1 }
end

local function IsUsableTooltipBackground(color)
	return color and ((color.a or 0) > 0.001)
end

local function NormalizeTooltipTheme(theme)
	return BROKER_TOOLTIP_THEME_KEYS[theme] and theme or "blizzard"
end

local function GetEffectiveTooltipTheme()
	local theme = BFL and BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	return NormalizeTooltipTheme(theme)
end

function BU.GetDefaultBrokerSeparatorColor()
	return CopyColor(DEFAULT_BROKER_SEPARATOR_COLOR)
end

function BU.GetBrokerSeparatorColor()
	local color = BetterFriendlistDB and BetterFriendlistDB.brokerSeparatorColor
	local Palette = BFL and BFL.GetModule and BFL:GetModule("ThemePalette")
	if Palette and Palette.NormalizeBrokerSeparatorColor then
		return Palette:NormalizeBrokerSeparatorColor(color)
	end
	return NormalizeColor(color, DEFAULT_BROKER_SEPARATOR_COLOR)
end

function BU.GetBrokerSeparatorHeight()
	return DEFAULT_BROKER_SEPARATOR_HEIGHT
end

local function GetPixelAlignedBrokerSeparatorHeight(region)
	local height = BU.GetBrokerSeparatorHeight()
	if PixelUtil and PixelUtil.GetNearestPixelSize and region and region.GetEffectiveScale then
		local scaleOk, scale = pcall(region.GetEffectiveScale, region)
		if scaleOk and scale then
			local ok, alignedHeight = pcall(PixelUtil.GetNearestPixelSize, height, scale, height)
			if ok and alignedHeight and alignedHeight > 0 then
				return alignedHeight
			end
		end
	end
	return height
end

function BU.ApplyBrokerSeparatorColor(texture)
	if not texture or not texture.SetColorTexture then
		return nil
	end

	local color = BU.GetBrokerSeparatorColor()
	texture:SetColorTexture(color.r, color.g, color.b, color.a or 1)
	return color
end

function BU.ApplyBrokerFooterSeparatorStyle(texture)
	if not texture then
		return nil
	end

	if texture.SetHeight then
		texture:SetHeight(GetPixelAlignedBrokerSeparatorHeight(texture))
	end
	return BU.ApplyBrokerSeparatorColor(texture)
end

local function GetStoredBrokerTooltipSettings(theme)
	theme = NormalizeTooltipTheme(theme)
	local Palette = BFL and BFL.GetModule and BFL:GetModule("ThemePalette")
	if Palette and Palette.GetBrokerTooltipThemeSettings then
		return Palette:GetBrokerTooltipThemeSettings(theme)
	end

	local allSettings = BetterFriendlistDB and BetterFriendlistDB.brokerTooltipThemeSettings
	local settings = type(allSettings) == "table" and allSettings[theme] or nil
	settings = type(settings) == "table" and settings or {}
	return {
		backgroundColor = NormalizeColor(settings.backgroundColor),
		opacity = Clamp(settings.opacity, 0, 1),
	}
end

local function GetBackdropColor(object)
	if not object or not object.GetBackdropColor then
		return nil
	end

	local ok, r, g, b, a = pcall(object.GetBackdropColor, object)
	if not ok or r == nil then
		return nil
	end
	if type(r) == "table" then
		return NormalizeColor(r, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
	end
	return NormalizeColor({ r = r, g = g, b = b, a = a }, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
end

local function GetNineSliceCenterColor(nineSlice)
	if not nineSlice or not nineSlice.GetCenterColor then
		return nil
	end

	local ok, r, g, b, a = pcall(nineSlice.GetCenterColor, nineSlice)
	if not ok or r == nil then
		return nil
	end
	if type(r) == "table" then
		return NormalizeColor(r, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
	end
	return NormalizeColor({ r = r, g = g, b = b, a = a }, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
end

local function CaptureTooltipBackground(tt)
	if not tt then
		return nil
	end

	local color = GetBackdropColor(tt.BFL_DarkBackdrop)
	if IsUsableTooltipBackground(color) then
		return color
	end

	color = GetBackdropColor(tt.backdrop)
	if IsUsableTooltipBackground(color) then
		return color
	end

	color = GetBackdropColor(tt.Backdrop)
	if IsUsableTooltipBackground(color) then
		return color
	end

	color = GetBackdropColor(tt)
	if IsUsableTooltipBackground(color) then
		return color
	end

	color = GetNineSliceCenterColor(tt.NineSlice)
	if IsUsableTooltipBackground(color) then
		return color
	end

	return nil
end

local function ApplyBackdropColor(object, color)
	if not object or not color then
		return false
	end

	local applied = false
	if object.SetBackdropColor then
		local ok = pcall(object.SetBackdropColor, object, color.r, color.g, color.b, color.a or 1)
		applied = ok or applied
	end
	if object.bg and object.bg.SetColorTexture then
		local ok = pcall(object.bg.SetColorTexture, object.bg, color.r, color.g, color.b, color.a or 1)
		applied = ok or applied
	end
	if object.SetColorTexture then
		local ok = pcall(object.SetColorTexture, object, color.r, color.g, color.b, color.a or 1)
		applied = ok or applied
	end
	return applied
end

local function ApplyTooltipBackground(tt, color)
	if not tt or not color then
		return false
	end

	local applied = false
	applied = ApplyBackdropColor(tt.BFL_DarkBackdrop, color) or applied
	applied = ApplyBackdropColor(tt.backdrop, color) or applied
	applied = ApplyBackdropColor(tt.Backdrop, color) or applied
	applied = ApplyBackdropColor(tt, color) or applied

	if tt.NineSlice and tt.NineSlice.SetCenterColor then
		local ok = pcall(tt.NineSlice.SetCenterColor, tt.NineSlice, color.r, color.g, color.b, color.a or 1)
		applied = ok or applied
	end

	return applied
end

local function GetSkinEnginePopupColor(theme)
	theme = NormalizeTooltipTheme(theme)
	local Engine = BFL and BFL.GetModule and BFL:GetModule("SkinEngine")
	local baseColors = Engine and Engine.defaultColors
	if type(baseColors) ~= "table" then
		return nil
	end

	if theme == "dark" or theme == "custom" then
		local Palette = BFL and BFL.GetModule and BFL:GetModule("ThemePalette")
		if Palette and Palette.ApplyToColors then
			local colors = {}
			Palette:ApplyToColors(colors, baseColors)
			return NormalizeColor(colors.popup, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
		end
	end

	return NormalizeColor(baseColors.popup, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
end

function BU.GetBrokerTooltipFallbackBackground(theme, tt)
	theme = NormalizeTooltipTheme(theme or GetEffectiveTooltipTheme())

	local current = CaptureTooltipBackground(tt)
	if current then
		return current
	end

	if theme == "dark" or theme == "custom" then
		return GetSkinEnginePopupColor(theme) or CopyColor(DEFAULT_BROKER_TOOLTIP_BACKGROUND)
	end

	current = CaptureTooltipBackground(GameTooltip)
	if current then
		return current
	end

	if theme == "elvui" then
		local E = BU.GetElvUIEngine and BU.GetElvUIEngine()
		local media = E and E.media
		local elvUIColor = media and (media.backdropfadecolor or media.backdropcolor)
		return NormalizeColor(elvUIColor, DEFAULT_BROKER_TOOLTIP_BACKGROUND)
	end

	return GetSkinEnginePopupColor(theme) or CopyColor(DEFAULT_BROKER_TOOLTIP_BACKGROUND)
end

function BU.ResolveBrokerTooltipBackground(theme, currentColor)
	theme = NormalizeTooltipTheme(theme or GetEffectiveTooltipTheme())
	local settings = GetStoredBrokerTooltipSettings(theme)
	if not settings.backgroundColor and settings.opacity == nil then
		return nil
	end

	local fallback = NormalizeColor(currentColor) or BU.GetBrokerTooltipFallbackBackground(theme)
	local color = settings.backgroundColor and NormalizeColor(settings.backgroundColor, fallback) or CopyColor(fallback)
	if settings.opacity ~= nil then
		color.a = settings.opacity
	end
	return color
end

function BU.ApplyBrokerTooltipThemeBackground(tt)
	if not tt then
		return nil
	end

	local current = CaptureTooltipBackground(tt)
	local color = BU.ResolveBrokerTooltipBackground(GetEffectiveTooltipTheme(), current)
	if not color then
		return nil
	end

	if not tt.bflBrokerBackgroundApplied then
		tt.bflBrokerOriginalBackground = current
	end
	tt.bflBrokerBackgroundApplied = true
	ApplyTooltipBackground(tt, color)
	return color
end

function BU.RestoreBrokerTooltipBackground(tt)
	if not tt or not tt.bflBrokerBackgroundApplied then
		return
	end

	if tt.bflBrokerOriginalBackground then
		ApplyTooltipBackground(tt, tt.bflBrokerOriginalBackground)
	end
	tt.bflBrokerOriginalBackground = nil
	tt.bflBrokerBackgroundApplied = nil
end

-- ========================================
-- Broker Tooltip Layout Helpers
-- ========================================
function BU.AddTooltipSeparator(tt, r, g, b, a)
	if not tt or not tt.AddSeparator then
		return nil
	end

	local color = BU.GetBrokerSeparatorColor()
	r = r ~= nil and r or color.r
	g = g ~= nil and g or color.g
	b = b ~= nil and b or color.b
	a = a ~= nil and a or color.a

	return tt:AddSeparator(BU.GetBrokerSeparatorHeight(), r or 0.3, g or 0.3, b or 0.3, a or 0.5)
end

-- ========================================
-- Menu Open Detection
-- ========================================
function BU.IsMenuOpen()
	if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU:IsShown() then
		return true
	end
	if _G.Lib_UIDROPDOWNMENU_OPEN_MENU and _G.Lib_UIDROPDOWNMENU_OPEN_MENU:IsShown() then
		return true
	end

	if Menu and Menu.GetManager then
		local manager = Menu.GetManager()
		if manager and manager.GetOpenMenu then
			local openMenu = manager:GetOpenMenu()
			if openMenu and openMenu.IsShown and openMenu:IsShown() then
				return true
			end
		end
	end

	return false
end

-- ========================================
-- Active Broker Tooltip Tracking
-- ========================================
-- Prevents overlapping tooltips when hovering between Friends and Guild plugins.
-- Each plugin registers its tooltip on creation and dismisses the previous one.

local activeBrokerEntry = nil -- { tooltip, detailTooltipRef, LQT }

function BU.DismissActiveBrokerTooltip()
	if not activeBrokerEntry then
		return
	end
	local entry = activeBrokerEntry
	activeBrokerEntry = nil -- clear first to prevent re-entry

	-- Release detail tooltip if present
	local dt = entry.detailTooltipRef and entry.detailTooltipRef()
	if dt and entry.LQT and dt.Key then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, dt)
	else
		BU.HideBrokerDetailTooltip(dt)
	end

	-- Release main tooltip
	if entry.tooltip and entry.LQT then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, entry.tooltip)
	end
end

function BU.SetActiveBrokerTooltip(tt, LQT, detailTooltipRef)
	activeBrokerEntry = { tooltip = tt, LQT = LQT, detailTooltipRef = detailTooltipRef }
end

function BU.ClearActiveBrokerTooltip(tt)
	if not activeBrokerEntry then
		return
	end

	if not tt or activeBrokerEntry.tooltip == tt then
		activeBrokerEntry = nil
	end
end

function BU.ScheduleBrokerTooltipRelease(LQT, tt)
	if not LQT or not tt or not tt.Key then
		return
	end

	if not C_Timer or not C_Timer.After then
		return
	end

	local releaseKey = tt.Key
	if tt.bflReleaseScheduled == releaseKey then
		return
	end

	tt.bflReleaseScheduled = releaseKey
	C_Timer.After(0, function()
		if tt.bflReleaseScheduled == releaseKey then
			tt.bflReleaseScheduled = nil
		end

		if tt.Key == releaseKey and (not tt.IsShown or not tt:IsShown()) then
			pcall(LQT.ReleaseTooltip, LQT, tt)
		end
	end)
end

function BU.GetOrCreateBrokerDetailTooltip(name)
	local tt = _G[name]
	if not tt then
		tt = CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate")
	end
	tt:SetClampedToScreen(true)
	return tt
end

function BU.AnchorBrokerDetailTooltip(tt, owner, mainTooltip)
	if not tt or not owner then
		return
	end

	tt:SetOwner(owner, "ANCHOR_NONE")
	tt:ClearAllPoints()
	tt:SetFrameStrata("TOOLTIP")

	if mainTooltip and mainTooltip.GetFrameLevel and tt.SetFrameLevel then
		tt:SetFrameLevel((mainTooltip:GetFrameLevel() or 0) + 50)
	end

	local ownerCenter = owner.GetCenter and owner:GetCenter()
	local screenWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth()
	if ownerCenter and screenWidth and ownerCenter > (screenWidth * 0.55) then
		tt:SetPoint("TOPRIGHT", owner, "TOPLEFT", -8, 2)
	else
		tt:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 2)
	end
end

function BU.HideBrokerDetailTooltip(tt)
	if not tt then
		return
	end
	if tt.ClearLines then
		tt:ClearLines()
	end
	if tt.Hide then
		tt:Hide()
	end
end

-- ========================================
-- ElvUI Tooltip Skin Helpers
-- ========================================

--- Get the ElvUI engine object (cached check)
function BFL:GetElvUIEngine(requireInitialized)
	if type(_G.ElvUI) ~= "table" then
		return nil
	end

	local ok, E = pcall(function()
		return select(1, unpack(_G.ElvUI))
	end)
	if not ok or type(E) ~= "table" or type(E.GetModule) ~= "function" then
		return nil
	end
	if requireInitialized and not E.initialized then
		return nil
	end
	return E
end

function BFL:IsElvUIAvailable()
	return self:GetElvUIEngine(false) ~= nil
end

function BU.GetElvUIEngine()
	return BFL.GetElvUIEngine and BFL:GetElvUIEngine(true) or nil
end

--- Apply ElvUI skin to a LibQTip tooltip (mirrors ElvUI TT:SetStyle)
function BU.ApplyElvUISkin(tt)
	if not tt then return end

	if BFL and BFL.UsesDarkSkinTheme and BFL:UsesDarkSkinTheme() then
		local Engine = BFL:GetModule("SkinEngine")
		if Engine then
			Engine:SkinTooltip(tt)
		end
		BU.ApplyBrokerTooltipThemeBackground(tt)
		return
	end

	local E = BU.GetElvUIEngine()
	local wantSkin = BFL and BFL.IsThemeActive and BFL:IsThemeActive("elvui")
	if E and wantSkin then
		-- Hide default NineSlice backdrop (same as ElvUI TT:SetStyle)
		if tt.NineSlice then tt.NineSlice:SetAlpha(0) end

		-- Apply ElvUI template directly on the tooltip frame
		if tt.SetTemplate then
			tt:SetTemplate("Transparent")
		end

		tt.bflElvUISkinned = true
	end

	BU.ApplyBrokerTooltipThemeBackground(tt)
end

--- Remove ElvUI skin from a LibQTip tooltip (restore default appearance)
function BU.RemoveElvUISkin(tt)
	if not tt then return end

	BU.RestoreBrokerTooltipBackground(tt)

	if tt.bflDarkSkinned and BFL then
		local Engine = BFL:GetModule("SkinEngine")
		if Engine then
			Engine:RestoreFrame(tt)
		end
	end

	if not tt.bflElvUISkinned then return end

	-- Restore NineSlice visibility
	if tt.NineSlice then
		tt.NineSlice:SetAlpha(1)
		NineSlicePanelMixin.OnLoad(tt.NineSlice)
		if GameTooltip.layoutType then
			tt.NineSlice:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())
			tt.NineSlice:SetBorderColor(GameTooltip.NineSlice:GetBorderColor())
		end
	end

	-- Remove ElvUI's flat backdrop
	if tt.SetBackdrop then
		tt:SetBackdrop(nil)
	end

	-- Hide ElvUI inner/outer border frames
	if tt.iborder then tt.iborder:Hide() end
	if tt.oborder then tt.oborder:Hide() end

	-- Hide old CreateBackdrop child frame
	if tt.backdrop then tt.backdrop:Hide() end

	-- Remove from ElvUI's frame update tracking
	local E = BU.GetElvUIEngine()
	if E and E.frames then
		E.frames[tt] = nil
	end

	tt.bflElvUISkinned = nil
end

-- ========================================
-- Tooltip Auto-Hide (Custom timer with menu detection)
-- ========================================
-- detailTooltipRef: optional function that returns the detail tooltip to check for mouse-over
function BU.SetupTooltipAutoHide(tt, anchorFrame, LQT, detailTooltipRef)
	tt:SetAutoHideDelay(nil) -- Disable LibQTip's built-in auto-hide

	if not tt.bflTimer then
		tt.bflTimer = CreateFrame("Frame", nil, tt)
	end

	local timer = tt.bflTimer
	timer.hideTimer = 0
	timer.checkTimer = 0
	timer.menuOpenTimer = 0

	timer:SetScript("OnUpdate", function(self, elapsed)
		self.checkTimer = self.checkTimer + elapsed
		if self.checkTimer < 0.1 then
			return
		end

		local checkInterval = self.checkTimer
		self.checkTimer = 0

		local isOver = (tt.IsMouseOver and tt:IsMouseOver())

		if not isOver and anchorFrame and anchorFrame.IsMouseOver and anchorFrame:IsMouseOver() then
			isOver = true
		end

		-- Check detail tooltip if provided
		local dt = detailTooltipRef and detailTooltipRef()
		if
			not isOver
			and dt
			and dt.IsShown
			and dt:IsShown()
			and dt.IsMouseOver
			and dt:IsMouseOver()
		then
			isOver = true
		end

		if isOver then
			self.hideTimer = 0
			self.menuOpenTimer = 0
		else
			if BU.IsMenuOpen() then
				self.hideTimer = 0

				self.menuOpenTimer = (self.menuOpenTimer or 0) + checkInterval
				if self.menuOpenTimer > 2.0 then
					if LQT then
						pcall(function()
							LQT:ReleaseTooltip(tt)
						end)
					end
					self:SetScript("OnUpdate", nil)
				end
			else
				self.hideTimer = self.hideTimer + checkInterval
				self.menuOpenTimer = 0

				if self.hideTimer >= 0.25 then
					if LQT then
						pcall(function()
							LQT:ReleaseTooltip(tt)
						end)
					end
					self:SetScript("OnUpdate", nil)
				end
			end
		end
	end)
end

-- ========================================
-- Last Online Formatting
-- ========================================
function BU.FormatLastOnline(years, months, days, hours)
	if not years and not months and not days and not hours then
		return ""
	end

	local L = BFL.L

	years = years or 0
	months = months or 0
	days = days or 0
	hours = hours or 0

	if years > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_YEARS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_YEARS, years)
		end
		return string.format("%dy", years)
	elseif months > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_MONTHS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_MONTHS, months)
		end
		return string.format("%dmo", months)
	elseif days > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_DAYS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_DAYS, days)
		end
		return string.format("%dd", days)
	elseif hours > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_HOURS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_HOURS, hours)
		end
		return string.format("%dh", hours)
	else
		if L and L.GUILD_BROKER_LAST_ONLINE_NOW then
			return L.GUILD_BROKER_LAST_ONLINE_NOW
		end
		return "Online"
	end
end

-- ========================================
-- Class Icon Helper (Inline Texture String)
-- ========================================
function BU.GetClassIcon(classFile, size)
	if not classFile or classFile == "" then
		return ""
	end
	size = size or 14
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
	if not coords then
		return ""
	end
	return string.format(
		"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:%d:%d:0:0:256:256:%d:%d:%d:%d|t",
		size, size,
		coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256
	)
end

-- ========================================
-- Chat Name Insert Helper
-- ========================================
function BU.AddNameToEditBox(name, realm)
	if not name then
		return false
	end

	-- Add realm suffix if different from player's realm
	local playerRealm = GetRealmName()
	if realm and realm ~= "" and realm ~= playerRealm then
		name = name .. "-" .. realm
	end

	-- Find active chat editbox and insert name
	local editboxes = {
		ChatEdit_GetActiveWindow(),
		ChatEdit_GetLastActiveWindow(),
	}

	for _, editbox in ipairs(editboxes) do
		if editbox and editbox:IsVisible() and editbox:HasFocus() then
			editbox:Insert(name)
			return true
		end
	end

	-- Fallback: Insert into default chat frame's editbox
	local defaultEditBox = ChatEdit_ChooseBoxForSend()
	if defaultEditBox then
		ChatEdit_ActivateChat(defaultEditBox)
		defaultEditBox:Insert(name)
		return true
	end

	return false
end
