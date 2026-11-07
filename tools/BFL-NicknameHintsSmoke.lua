-- lua tools/BFL-NicknameHintsSmoke.lua <repository root>
-- Real modules and locale switching; native rendering is mocked.
local root = assert(arg[1], "repository root required")
SlashCmdList = {}
unpack = table.unpack
local BFL = { Modules = {}, IsMainline = true }
local theme, modernStyle = "blizzard", false
local fontScale = 1
function BFL:GetEffectiveTheme() return theme end
function BFL.HasAtlas() return true end
function BFL.SetTextureOrAtlas(texture, atlas) texture.atlas = atlas; return true end
function BFL:RegisterModule(name, module) self.Modules[name] = module; return module end
function BFL:GetModule(name) return self.Modules[name] end
function BFL:GetThemeAccentColor() return 1, .82, 0, 1 end
function BFL.SetOwnedBackdrop(frame, backdrop) frame.backdrop = backdrop end
function BFL:ForceRefreshFriendsList() self.refreshes = (self.refreshes or 0) + 1 end
function GetLocale() return "enUS" end
function wipe(t) for key in pairs(t) do t[key] = nil end end
local function loadFile(path) return assert(loadfile(root .. "/" .. path))("BetterFriendlist", BFL) end
loadFile("Locales/Locales.lua")
local locales = { "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }
for _, locale in ipairs(locales) do loadFile("Locales/" .. locale .. ".lua") end

local function equal(actual, expected, message)
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function contains(text, value, message)
	assert(text and text:find(value, 1, true), message)
end
local function frame()
	local f = { shown = true, width = 360, scripts = {} }
	function f:SetPoint(...)
		self.point = { ... }
		self.points = self.points or {}
		self.points[self.point[1]] = self.point
	end
	function f:SetParent(value) self.parent = value end
	function f:GetParent() return self.parent end
	function f:SetClipsChildren(value) self.clipsChildren = value end
	function f:GetName() return self.name or "MockFrame" end
	function f:ClearAllPoints() self.point, self.points, self.allPoints = nil, nil, nil end
	function f:SetClampedToScreen(value) self.clamped = value end
	function f:GetRegions() return unpack(self.nativeRegions or {}) end
	function f:GetObjectType() return "Texture" end
	function f:GetFrameLevel() return self.level or 1 end
	function f:SetFrameLevel(value) self.level = value end
	function f:GetTop() return self.top end
	function f:GetLeft() return self.left or 0 end
	function f:GetRight() return self:GetLeft() + self:GetWidth() end
	function f:GetBottom() return (self.top or self:GetHeight()) - self:GetHeight() end
	function f:GetEffectiveScale() return self.scale or (self.parent and self.parent:GetEffectiveScale()) or 1 end
	function f:IsVisible() return self.shown end
	function f:ClearBackdrop() self.backdrop = nil end
	function f:SetAllPoints(target) self.allPoints = target or self.parent end
	function f:EnableMouse(value) self.mouse = value end
	function f:EnableMouseWheel(value) self.mouseWheel = value end
	function f:Enable() self.enabled = true end
	function f:Disable() self.enabled = false end
	function f:SetEnabled(value) self.enabled = value end
	function f:SetOrientation(value) self.orientation = value end
	function f:SetThumbTexture(value) self.thumb = frame(); self.thumb.texture = value end
	function f:GetThumbTexture() return self.thumb end
	function f:SetScrollChild(child) self.scrollChild = child end
	function f:GetVerticalScroll() return self.offset or 0 end
	function f:GetVerticalScrollRange() return math.max(0, self.scrollChild:GetHeight() - self:GetHeight()) end
	function f:UpdateScrollChildRect()
		if self.scripts.OnScrollRangeChanged then self.scripts.OnScrollRangeChanged(self, 0, self:GetVerticalScrollRange()) end
	end
	function f:SetVerticalScroll(value)
		local changed = self.offset ~= value
		self.offset = value
		if changed and self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
	end
	function f:SetMinMaxValues(low, high) self.low, self.high = low, high end
	function f:GetMinMaxValues() return self.low or 0, self.high or 0 end
	function f:GetValue() return self.value or 0 end
	function f:SetValue(value)
		value = math.max(self.low or 0, math.min(self.high or 0, value))
		local changed = self.value ~= value
		self.value = value
		if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
	end
	function f:SetBackdropColor(...) self.background = { ... } end
	function f:SetBackdropBorderColor(...) self.border = { ... } end
	function f:SetTexture(value) self.texture = value end
	function f:SetHorizTile(value) self.horizTile = value end
	function f:SetVertTile(value) self.vertTile = value end
	function f:SetTexCoord(...) self.coords = { ... } end
	function f:SetVertexColor(...) self.color = { ... } end
	function f:SetColorTexture(...) self.color = { ... } end
	function f:SetTextColor(...) self.color = { ... } end
	function f:SetFontObject(value) self.fontObject = value end
	function f:SetJustifyH() end
	function f:SetJustifyV() end
	function f:SetWordWrap() end
	function f:SetNonSpaceWrap() end
	function f:SetMaxLines(value) self.maxLines = value end
	function f:SetText(value) self.text = value end
	function f:GetTextWidth() return #(self.text or "") * 7 end
	function f:GetStringWidth() return utf8.len(self.text or "") * 6.5 * fontScale end
	function f:GetStringHeight()
		assert(self.explicitWidth, "measure text with an explicit width, not unresolved frame anchors")
		equal(self.height, 0, "reset text height before measuring to avoid ellipsis")
		local line, lines = "", {}
		local maxChars = math.max(1, math.floor(self.width / (6.5 * fontScale)))
		for word in (self.text or ""):gmatch("%S+") do
			while utf8.len(word) > maxChars do
				if line ~= "" then lines[#lines + 1], line = line, "" end
				local boundary = utf8.offset(word, maxChars + 1)
				lines[#lines + 1], word = word:sub(1, boundary - 1), word:sub(boundary)
			end
			local candidate = line == "" and word or (line .. " " .. word)
			if utf8.len(candidate) * 6.5 * fontScale > self.width and line ~= "" then
				lines[#lines + 1], line = line, word
			else line = candidate end
		end
		lines[#lines + 1] = line
		self.wrapped = table.concat(lines, "\n")
		return #lines * 14 * fontScale
	end
	function f:SetSize(width, height) self.width, self.height = width, height end
	function f:SetWidth(value) self.width, self.explicitWidth = value, true end
	function f:GetWidth() return self.width end
	function f:GetHeight() return self.height end
	function f:SetHeight(value) self.height = value end
	function f:SetAlpha(value) self.alpha = value end
	function f:SetScript(event, callback) self.scripts[event] = callback end
	function f:HookScript(event, callback) self.scripts[event] = callback end
	function f:Show() self.shown = true end
	function f:SetShown(value) self.shown = value end
	function f:Hide()
		self.shown = false
		if self.scripts.OnHide then self.scripts.OnHide(self) end
	end
	function f:IsShown() return self.shown end
	function f:CreateFontString() return frame() end
	function f:CreateTexture() return frame() end
	return f
end
local mockLayout = "ButtonFrameTemplateNoPortrait"
local inheritedLayout = "PortraitFrameTemplate"
local function ApplyNativeArt(border)
	for _, name in ipairs({ "TopLeftCorner", "TopRightCorner", "TopEdge", "BottomLeftCorner", "BottomRightCorner", "BottomEdge", "LeftEdge", "RightEdge" }) do
		border[name] = frame()
		border[name].atlas = "native-" .. name
	end
	-- Atlas rectangles include broad transparent gutters. Their widths must
	-- never set the length of the ledge or the cutout.
	border.LeftEdge.width, border.TopLeftCorner.width = 96, 96
	border.BottomLeftCorner:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", -8, -8)
	border.BottomRightCorner:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 2, -8)
	border.BottomEdge:SetPoint("BOTTOMLEFT", border.BottomLeftCorner, "BOTTOMRIGHT", 0, 0)
	border.BottomEdge:SetPoint("BOTTOMRIGHT", border.BottomRightCorner, "BOTTOMLEFT", 0, 0)
end
NineSliceUtil = {
	GetLayout = function(layout) return (layout == mockLayout or layout == inheritedLayout) and {} end,
	ApplyLayoutByName = function(skin, layout)
		equal(layout, mockLayout, "the contour uses the same layout as the Blizzard frame")
		ApplyNativeArt(skin)
	end,
}
function CreateFrame(_, name, parent, template)
	local f = frame()
	f.parent, f.template, f.name = parent, template, name
	if template and template:find("ButtonFrameTemplate", 1, true) then
		f.Bg, f.Inset, f.NineSlice, f.TitleContainer, f.CloseButton = frame(), frame(), frame(), frame(), frame()
		f.NineSlice.level = 2
		local border = f.NineSlice
		-- Blizzard's HidePortrait changes the art but leaves this getter alone.
		border.GetFrameLayoutType = function() return inheritedLayout end
		ApplyNativeArt(border)
		border:SetAllPoints(f)
		f.TitleContainer.level = 510
		f.TitleContainer.TitleText = frame()
		f.nativeRegions = { f.Bg, frame() }
	end
	return f
end
BetterFriendsFrame = frame()
BetterFriendsFrame.top = 900
UIParent = frame()
UIParent.top, UIParent.height, UIParent.width = 1000, 1000, 1280
local values, names, guildNames = {}, {}, {}
local DB = BFL:RegisterModule("DB", {})
function DB:Get(key, fallback) if values[key] ~= nil then return values[key] end; return fallback end
function DB:GetNameFormatString() return values.name or "%name% (%character%)" end
function DB:GetInfoFormatString() return values.info end
function DB:GetNickname(uid) return names[uid] end
function DB:SetNickname(uid, value) names[uid] = value end
function DB:SetGuildNickname(uid, value) guildNames[uid] = value end
function DB:GetGuildNickname(uid) return guildNames[uid] end
local center, opened = false, nil
local Settings = BFL:RegisterModule("Settings", {})
function Settings:IsSettingsCenterEnabled() return center end
function Settings:ShowSettingsCenter(page, control) opened = { page, control }; return true end
function Settings:ShowLegacy(category, section) opened = { category, section } end
BFL.StreamerMode = { IsActive = function() return values.streamer end }
local GuildFrame = BFL:RegisterModule("GuildFrame", {})
function GuildFrame:IsEnabled() return values.guildEnabled ~= false end
function GuildFrame:Refresh() end
local FriendsUI = BFL:RegisterModule("FriendsUI", {})
function FriendsUI:IsModernActive() return modernStyle end
function FriendsUI:AnchorAuxiliaryWindow(window, offset)
	window.dockOffset = offset
	window:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", modernStyle and 36 or 8, offset)
end
loadFile("Modules/FeatureHints.lua")
loadFile("Modules/NicknameHints.lua")
local hints = BFL:GetModule("FeatureHints")
local nicknames = BFL:GetModule("NicknameHints")

for _, locale in ipairs(locales) do
	BFL:SetLocale(locale)
	values = { brokerEnabled = true, streamer = true }
	for _, useCenter in ipairs({ false, true }) do
		center = useCenter
		local text, page, control, category = nicknames:GetGuidance("friends", "bnet_Example#1234")
		equal(page, "friends.formatting", "friends page")
		equal(control, "nameFormatPreset", "friends control")
		equal(category, 1, "legacy General category")
		contains(text, "%nickname%", "literal nickname token survives formatting in " .. locale)
		contains(text, BFL.L.NAME_PRESET_NICKNAME, "exact preset label in " .. locale)
		contains(text, BFL.L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME, "exact streamer label in " .. locale)
		contains(text, BFL.L.BROKER_COLUMN_NICKNAME, "exact broker label in " .. locale)
		contains(text, useCenter and BFL.L.SETTINGS_CENTER_PAGE_FRIENDS_FORMATTING or BFL.L.SETTINGS_TAB_GENERAL,
			"active UI path in " .. locale)
		values.guildTabUseNicknames, values.guildBrokerEnabled = false, true
		local guildText = nicknames:GetGuidance("guild")
		contains(guildText, BFL.L.SETTINGS_GUILD_USE_NICKNAMES, "guild setting in " .. locale)
		contains(guildText, useCenter and BFL.L.SETTINGS_CENTER_PAGE_BROKER_GUILD or BFL.L.GUILD_BROKER_SETTINGS_HEADER,
			"correct guild broker section in " .. locale)
	end
end
BFL:SetLocale("enUS")
assert(next(BFL.MissingKeys) == nil, "guidance must not rely on missing locale keys")
values = { name = "%NiCkNaMe% (%character%)" }
equal(nicknames:GetGuidance("friends"), nil, "nickname name format suppresses hint")
values = { info = "%nickname%" }
equal(nicknames:GetGuidance("friends"), nil, "visible nickname info suppresses hint")
values.compactMode = true
assert(nicknames:GetGuidance("friends"), "hidden compact info must not suppress hint")
values = { streamer = true, streamerModeNameFormat = "nickname" }
equal(nicknames:GetGuidance("friends", "bnet_Test#1234"), nil, "active BNet streamer nickname suppresses hint")
assert(nicknames:GetGuidance("friends", "wow_Test-Realm"), "streamer setting does not mask a WoW friend")
values.streamer = false
assert(nicknames:GetGuidance("friends", "bnet_Test#1234"), "inactive streamer setting does not suppress hint")
values = { name = "%nickname%" }
FriendListColorsAPI = { Format = function() end }
contains(nicknames:GetGuidance("friends"), "FriendListColors", "external formatter overrides name preset")
FriendListColorsAPI = nil
values = { guildBrokerEnabled = true }
local _, page, control = nicknames:GetGuidance("guild")
equal(page, "broker.guild", "only missing guild broker display")
equal(control, "guildBroker.columns.order", "broker columns have a shared reorder control")
values.guildBrokerShowColNickname = true
equal(nicknames:GetGuidance("guild"), nil, "enabled guild displays suppress hint")
values.guildEnabled, values.guildTabUseNicknames = false, false
equal(nicknames:GetGuidance("guild"), nil, "unavailable guild tab is not recommended")

values = {}
nicknames:OnNicknameSaved("", nil)
nicknames:OnNicknameSaved("   ", nil)
nicknames:OnNicknameSaved("Same", "Same")
equal(hints.frame, nil, "deletion, whitespace and unchanged saves do not show a badge")
nicknames:OnNicknameSaved("New", nil, "friends")
assert(hints.frame:IsShown(), "saved hidden nickname shows a badge")
equal(hints.frame.mouse, true, "badge body can pause dismissal on hover")
assert(hints.frame.clamped, "badge stays on screen")
local badge = hints.frame
badge.scripts.OnUpdate(badge, 18.5)
equal(badge.alpha, .5, "badge fades after 18 seconds")
badge.open.scripts.OnEnter()
badge.scripts.OnUpdate(badge, 100)
assert(badge:IsShown(), "hovering settings button pauses dismissal")
badge.open.scripts.OnLeave()
badge.scripts.OnUpdate(badge, 4.1)
equal(badge:IsShown(), false, "badge expires automatically")
nicknames:OnNicknameSaved("Another", nil, "friends")
equal(badge:IsShown(), false, "no repeat hint within a session")
hints.shown = nil
center = false
nicknames:OnNicknameSaved("New", nil, "friends")
center = true
badge.open.scripts.OnClick()
equal(opened[1], "friends.formatting", "click uses currently active Settings Center")
equal(opened[2], "nameFormatPreset", "click focuses exact control")
equal(badge:IsShown(), false, "opening settings dismisses badge")
hints.shown = nil
nicknames:OnNicknameSaved("New", nil, "friends")
center = false
badge.open.scripts.OnClick()
equal(opened[1], 1, "click uses currently active legacy General category")
hints.shown = nil
nicknames:OnNicknameSaved("New", nil, "friends")
BetterFriendsFrame:Hide()
equal(badge:IsShown(), false, "closing friends hides badge permanently")
BetterFriendsFrame:Show()

-- Exercise both real friend-popup callbacks, without adding side effects to DB setters.
StaticPopupDialogs, ACCEPT, CANCEL = {}, "Accept", "Cancel"
loadFile("Modules/MenuSystem.lua")
BFL:GetModule("MenuSystem"):Initialize()
local popup = StaticPopupDialogs.BETTER_FRIENDLIST_SET_NICKNAME
local input = { GetText = function() return "Saved" end, GetParent = function() return frame() end }
for _, accept in ipairs({ function(data) popup.OnAccept({ EditBox = input }, data) end,
	function(data) popup.EditBoxOnEnterPressed(input, data) end }) do
	hints.shown = nil
	accept({ uid = "wow_Test-Realm" })
	equal(names["wow_Test-Realm"], "Saved", "popup still persists nickname")
	assert(badge:IsShown(), "accept and Enter both show guidance")
	badge:Hide()
end
-- Guild menus are also reachable through the broker while the friends window is closed.
loadFile("Modules/GuildActions.lua")
local actions = BFL:GetModule("GuildActions")
function actions:GetFullName() return "Guildmate-Realm" end
function actions:GetDisplayName() return "Guildmate" end
function StaticPopup_Show() end
values = { guildBrokerEnabled = true }
BetterFriendsFrame:Hide()
actions:SetNicknameDialog({})
local guildPopup = StaticPopupDialogs.BFL_GUILD_SET_NICKNAME
for _, accept in ipairs({ function() guildPopup.OnAccept({ EditBox = input }) end,
	function() guildPopup.EditBoxOnEnterPressed(input) end }) do
	hints.shown = nil
	accept()
	equal(guildNames["Guildmate-Realm"], "Saved", "guild popup persists nickname")
	assert(badge:IsShown(), "guild accept and Enter both show guidance")
	equal(badge.parent, UIParent, "closed friends window does not hide broker guidance")
	equal(hints.entries[1].page, "broker.guild", "guild broker action opens its own settings")
	badge:Hide()
end
hints.shown = nil
guildPopup.OnAlt()
equal(guildNames["Guildmate-Realm"], nil, "guild remove action still clears nickname")
equal(badge:IsShown(), false, "guild remove does not show a hint")

-- Long translations and expanded content must size themselves instead of clipping.
BetterFriendsFrame:Show()
for _, locale in ipairs(locales) do
	BFL:SetLocale(locale)
	for _, useCenter in ipairs({ false, true }) do
		center = useCenter
		values = { brokerEnabled = true, streamer = true }
		hints.shown = nil
		nicknames:OnNicknameSaved("New", nil, "friends", "bnet_Test#1234")
		equal(#hints.entries, 4, "all applicable destinations remain available")
		equal(badge.rows[2].shown, false, "secondary destinations start collapsed")
		local collapsed = badge:GetHeight()
		assert(collapsed < 270, "collapsed notice stays compact in " .. locale)
		badge.more.scripts.OnClick()
		equal(badge:GetHeight(), collapsed, "expanded options keep the summary height")
		assert(badge.details:IsShown() and badge.rows[4].shown, "details reveal all additional destinations")
		equal(badge.rows[4].parent, badge.details.scrollContent, "details own the additional rows")
		local entry = hints.entries[4]
		badge.rows[4].scripts.OnClick()
		equal(opened[1], useCenter and entry.page or entry.category, "each destination opens its own page")
	end
end
BFL:SetLocale("enUS")
values = {}
hints.shown = nil
nicknames:OnNicknameSaved("New", nil, "friends")
local engine = BFL:RegisterModule("SkinEngine", {
	IsActive = function() return true end,
	colors = { popup = { .08, .12, .18, .6 }, text = { .8, .9, 1, 1 }, borderSoft = { .2, .3, .4, 1 } },
})
theme = "custom"
hints:RefreshAppearance()
equal(badge.background[1], .08, "notice uses theme popup color")
equal(badge.background[4], .94, "floating notice keeps a readable surface")
equal(badge.border[3], .4, "notice uses theme border color")
equal(badge.rows[1].description.color[3], 1, "notice uses theme text color")
BFL.Modules.SkinEngine = nil

-- Style follows the applied FriendsUI layout independently from the selected theme.
for _, selectedTheme in ipairs({ "blizzard", "custom" }) do
	theme = selectedTheme
	for _, useModern in ipairs({ false, true, false }) do
		modernStyle = useModern
		hints:RefreshAppearance()
		equal(badge.modern, useModern, "badge follows live Modern/Legacy switch")
		equal(badge.icon.shown, useModern, "Modern uses an inline header; Legacy uses its title bar")
		equal(badge.point[1], "TOPLEFT", "without side tabs, the notice aligns with the window top")
		equal(badge.point[4], 0, "notice docks flush with the friends window")
		equal(badge.Bg.shown, not useModern and selectedTheme == "blizzard", "Legacy restores the native window texture")
		equal(badge.Inset.shown, not useModern and selectedTheme == "blizzard", "Legacy uses the native inset")
		equal(badge.NineSlice.shown, selectedTheme == "blizzard", "flat themes retain their border treatment")
		equal(badge.CloseButton.shown, selectedTheme == "blizzard", "native styles use the matching title-bar close button")
		if useModern then
			equal(badge.topFade.atlas, "friends-frame-toptexbg", "same upper texture as FriendsFrame")
			equal(badge.bottomFade.atlas, "friends-frame-bottomtexbg", "same lower texture as FriendsFrame")
			equal(badge.modernDivider.atlas, "perks-divider-short", "same ornamental divider as FriendsFrame")
		end
		equal(badge.bodySurface.shown, useModern and selectedTheme == "blizzard",
			"the compact backing supplements Modern while Legacy uses the native texture")
		if useModern and selectedTheme == "blizzard" then
			equal(badge.bodySurface.points.TOPLEFT[2], badge.Bg, "the Modern backing follows the native background")
			equal(badge.bodySurface.points.TOPLEFT[4], -2, "the Modern backing follows the closer left bevel")
		else
			equal(badge.bodySurface.allPoints, badge.Bg, "backing follows the native background, excluding transparent border gutters")
		end
		for _, edge in ipairs({ "TOPLEFT", "TOPRIGHT" }) do
			equal(badge.topFade.points[edge][2], badge.bodySurface, "upper artwork stays inside the native background bounds")
			equal(badge.topFade.points[edge][3], edge, "upper artwork follows the matching background edge")
		end
		for _, edge in ipairs({ "BOTTOMLEFT", "BOTTOMRIGHT" }) do
			equal(badge.bottomFade.points[edge][2], badge.bodySurface, "lower artwork stays inside the native background bounds")
			equal(badge.bottomFade.points[edge][3], edge, "lower artwork follows the matching background edge")
		end
		equal(badge.bodySurface.color[4], 1, "native backing is opaque behind border and footer")
		for _, row in ipairs(badge.rows) do
			assert(not row.background and not row.highlight, "options do not paint separate text blocks")
			assert(row.BFL_DarkInvisibleOverlayButton, "theme skinning cannot add blocks to text hit areas")
			if row.shown then equal(row.description.point[2], 0, "option text aligns with the outer content padding") end
		end
	end
end
equal(badge.template, "ButtonFrameTemplate,BackdropTemplate", "same shell template as the friends window")
equal(badge:GetWidth(), 280, "notice is narrower than the original card")
equal(badge.title, badge.TitleContainer.TitleText, "real native title is populated")
assert(badge.TitleContainer.shown and badge.title.shown, "native title stays visible")
assert(badge.content:GetFrameLevel() > badge.NineSlice:GetFrameLevel(), "content renders above the native border")
badge.level, badge.NineSlice.level = 600, 601
hints:RefreshAppearance()
assert(badge.content:GetFrameLevel() > 601 and badge.TitleContainer:GetFrameLevel() > badge.content:GetFrameLevel(),
	"reparenting or skinning cannot bury the content or title below the shell")
badge.level, badge.NineSlice.level = 1, 2
hints:RefreshAppearance()
equal(badge.rows[1].parent, badge.scrollContent, "message uses the scrollable foreground content layer")
equal(badge.open.parent, badge.content, "footer actions use the foreground content layer")
equal(badge.rows[1].heading.shown, false, "collapsed notice avoids repeating the setting heading")

-- Tab array order can differ from display order, and hidden tabs do not count.
local hiddenTab, lowerTab, firstTab = frame(), frame(), frame()
hiddenTab.top, hiddenTab.shown = 890, false
lowerTab.top, firstTab.top = 700, 778
lowerTab.left, firstTab.left = BetterFriendsFrame:GetRight(), BetterFriendsFrame:GetRight()
lowerTab.width, firstTab.width = 74, 68
FriendsUI.sideTabs = { hiddenTab, lowerTab, firstTab }
hints:RefreshAppearance()
equal(badge.point[1], "TOPLEFT", "notice stays aligned with the friends title bar")
equal(badge.point[2], BetterFriendsFrame, "horizontal docking follows the friends window")
equal(badge.point[4], 0, "docking does not reserve the width of the tab rail")
equal(badge.point[5], 0, "title lines form a single horizontal line")
assert(badge.dockPlan.bottom >= firstTab.top + 8, "summary and its border clear the first visible tab")
badge.more.scripts.OnClick()
equal(badge.details.point[2], badge, "details move with the compact badge")
equal(badge.details.point[3], "BOTTOMLEFT", "details connect to the bottom edge")
equal(badge.details.point[4], lowerTab.width + 2, "details use a narrow gap after the widest visible tab")
equal(badge.details.point[5], 0, "detail surface touches the summary")
equal(badge.details.point[4] + badge.details:GetWidth(), badge:GetWidth(), "the whole expanded card shares one right edge")
assert(badge.outline.lines[3].shown and badge.outline.lines[3]:GetHeight() == badge:GetHeight() + badge.details:GetHeight(),
	"the flat theme draws one continuous right edge")
equal(badge.outline.lines[5]:GetWidth(), badge.details.point[4], "the flat ledge stops at the tab cutout")
equal(-badge.outline.lines[5].point[5], badge:GetHeight() + badge.details.stepDrop - 1, "the flat ledge fills the band above the tabs")
equal(badge.outline.mouse, false, "the decorative silhouette cannot capture tab clicks")
theme, modernStyle = "blizzard", true
hints:RefreshAppearance()
local outline = badge.NineSlice
equal(badge.details.bottomFade.atlas, badge.bottomFade.atlas, "native Modern artwork continues to the bottom")
assert(badge.details.bottomFade.shown and not badge.bottomFade.shown, "only the extended bottom has a background fade")
assert(outline.shown and outline.TopEdge.shown, "the native header keeps its original art")
assert(outline.RightEdge.shown and outline.BottomRightCorner.shown and not outline.LeftEdge.shown,
	"the outer right uses one uninterrupted native edge")
equal(outline.points.BOTTOMRIGHT[2], badge.details, "the native right edge reaches the bottom of the detail area")
assert(not badge.outline.shown, "native layout uses the native frame thickness")
local headerClip, upper, lower = unpack(badge.nativeBorderClips)
equal(outline.points.TOPLEFT[4], -2, "the Retail outline closes the extra gap beside the friends window")
equal(headerClip.skin.points.TOPLEFT[4], -2, "the Retail title and side art use the same alignment")
equal(headerClip.skin.layoutType, mockLayout, "expanded header uses the no-portrait border despite the inherited layout type")
equal(headerClip.skin.TopLeftCorner.atlas, outline.TopLeftCorner.atlas, "the expanded top-left corner matches the compact card")
assert(headerClip.shown and upper.shown and lower.shown and headerClip.clipsChildren and upper.clipsChildren and lower.clipsChildren,
	"the thick native art is drawn through independent header and body clips")
equal(headerClip.points.BOTTOMRIGHT[2], badge, "the header clip spans the full card width instead of stopping at the notch")
assert(headerClip.skin.TopLeftCorner.shown and not upper.skin.TopLeftCorner.shown and not outline.TopLeftCorner.shown,
	"only the full-width clip draws the wide corner and its section of the title bar")
equal(upper.points.BOTTOMRIGHT[2], badge.details, "the ledge clip follows the notch")
equal(upper.points.BOTTOMRIGHT[4], 3, "the ledge meets the closer native edge")
equal(lower.points.TOPLEFT[2], badge.details, "the inner edge follows the notch")
equal(badge.dockPlan.left + badge.details.indent + lower.points.TOPLEFT[4], lowerTab:GetRight() - 2,
	"the Retail frame uses only the transparent end of the rail")
equal(lower.mouse, false, "the decorative edge cannot capture a tab click")
equal(badge.details.bodySurface.points.TOPLEFT[4], 1, "the backing starts underneath the Retail border")
local detailAnchor, detailWidth = badge.details.point[4], badge.details:GetWidth()
BFL.IsForever = true
hints:RefreshAppearance()
equal(badge.dockPlan.left + badge.details.indent + lower.points.TOPLEFT[4], lowerTab:GetRight() - 5,
	"the Forever frame accounts for its wider transparent gutter")
equal(headerClip.skin.points.TOPLEFT[4], -1, "the Forever header's left art matches the top gap")
equal(upper.skin.points.TOPLEFT[4], -1, "the Forever shelf aligns with the shifted header art")
equal(outline.points.TOPLEFT[4], -1, "the Forever title segments share one left origin")
equal(badge.point[4], 0, "only the visible left border moves")
equal(badge.details.point[4], detailAnchor, "the Forever trim does not move the tab-facing hit area")
equal(badge.details:GetWidth(), detailWidth, "the trim does not change the content layout")
equal(badge.details.bodySurface.points.TOPLEFT[4], -2, "the backing follows the Forever border")
BFL.IsForever = nil
hints:RefreshAppearance()
equal(lower.points.TOPLEFT[5], 4 - badge.details.stepDrop, "the upright follows the lowered gold ledge")
assert(lower.skin:GetFrameLevel() > upper.skin:GetFrameLevel(), "the vertical edge covers the seam")
equal(badge.bodySurface.points.TOPLEFT[2], badge.Bg, "the expanded backing uses the compact native background origin")
equal(badge.bodySurface.points.BOTTOMRIGHT[5], -badge.details.stepDrop, "the backing fills the space behind the lowered ledge")
equal(badge.details.bodySurface.points.TOPLEFT[5], badge.bodySurface.points.BOTTOMRIGHT[5],
	"summary and detail backings meet without overlapping")
equal(badge.details.viewport.point[5], -badge.details.stepDrop - 6, "the first detail starts below the ledge")
badge.elapsed = badge.displaySeconds
badge.scripts.OnUpdate(badge, .5)
equal(badge.alpha, .5, "the expanded hint fades as one frame")
equal(badge.details.bodySurface.points.TOPLEFT[5], badge.bodySurface.points.BOTTOMRIGHT[5],
	"the backings remain disjoint during the fade")
badge.elapsed = 0
badge:SetAlpha(1)
equal(upper.skin.BottomEdge.atlas, outline.BottomEdge.atlas, "the ledge uses the original thick bottom edge")
equal(lower.skin.LeftEdge.atlas, outline.LeftEdge.atlas, "the inner edge uses the original thick side texture")
assert(upper.skin.BottomEdge.shown and lower.skin.LeftEdge.shown and lower.skin.BottomLeftCorner.shown,
	"the notch and lower-left corner retain the native pieces")
assert(not lower.skin.TopEdge.shown and not lower.skin.BottomRightCorner.shown,
	"the lower rectangle cannot draw another header or right corner")
assert(not badge.progress.shown and badge.details.progress.shown, "only the bottom of the whole card shows the timer")
local header = outline.TopEdge
outline.TopEdge = nil
hints:RefreshAppearance()
assert(not outline.shown and badge.outline.lines[1].shown, "missing native art falls back to a complete outline")
assert(not headerClip.shown and not upper.shown and not lower.shown, "falling back also hides the native clips")
outline.TopEdge = header
lowerTab.shown = false
badge.scripts.OnUpdate(badge, .25)
equal(badge.details.point[4], firstTab.width + 2, "visible rail changes reflow an open notice")
firstTab.shown = false
badge.scripts.OnUpdate(badge, .25)
equal(badge.point[5], 0, "hidden or reordered tabs do not move the notice")
equal(badge.details.point[4], 0, "details grow straight down without a visible rail")
modernStyle = false
hints:RefreshAppearance()
assert(badge.bodySurface.horizTile and badge.details.bodySurface.horizTile and not badge.Bg.shown and not badge.Inset.shown,
	"expanded Legacy uses the texture directly on each backing, with no duplicate native fill")
assert(not headerClip.shown and not upper.shown and not lower.shown and outline.LeftEdge.shown and outline.BottomEdge.shown,
	"without tabs the complete native frame grows straight down")
badge.more.scripts.OnClick()
assert(not badge.outline.shown and outline.LeftEdge.shown and outline.RightEdge.shown and outline.BottomEdge.shown,
	"collapse restores the native body border")
equal(outline.allPoints, badge, "collapse restores the compact native frame bounds")
equal(outline.BottomRightCorner.point[2], outline, "collapse restores the native bottom right corner")
equal(outline.BottomLeftCorner.point[2], outline, "collapse restores the native bottom left corner")
equal(outline.BottomEdge.points.BOTTOMLEFT[2], outline.BottomLeftCorner, "collapse restores the native bottom edge")
assert(badge.progress.shown and not badge.details.progress.shown, "collapse returns the timer to the compact card")
FriendsUI.sideTabs = nil
-- Classic and older clients can omit the Modern atlases entirely.
theme, modernStyle = "blizzard", true
badge.hasTopFade, badge.hasBottomFade, badge.hasModernDivider = false, false, false
hints:RefreshAppearance()
assert(not badge.topFade.shown and not badge.bottomFade.shown,
	"unavailable artwork stays hidden")
assert(badge.divider.shown, "missing atlas retains the plain divider")

-- The offline preview still works after automatic hints are exhausted.
values = { name = "%nickname%", info = "%nickname%", compactMode = true, brokerEnabled = false }
hints.shown = { ["nickname.friends"] = true, ["nickname.guild"] = true }
local shownBefore = hints.shown
local namesBefore, guildNamesBefore = next(names), next(guildNames)
local opens = 0
function ToggleBetterFriendsFrame() opens = opens + 1; BetterFriendsFrame:Show() end
BetterFriendsFrame:Hide()
equal(SLASH_BFLNICKNAMEHINT1, nil, "nickname preview has no slash alias")
equal(SlashCmdList.BFLNICKNAMEHINT, nil, "nickname preview has no slash handler")
for _, useModern in ipairs({ false, true, false }) do
	modernStyle = useModern
	badge:Hide()
	nicknames:ShowPreview()
	assert(badge:IsShown(), "preview repeats regardless of settings and hint history")
	equal(badge.modern, useModern, "preview follows currently selected interface style")
	equal(#hints.entries, 4, "preview includes every display option for layout testing")
	assert(badge:GetFrameLevel() > BetterFriendsFrame:GetFrameLevel() + 2, "notice renders above its own anchor")
	assert(badge.mouse, "notice hover works while retaining a non-modal card")
	badge.scripts.OnEnter()
	local timer = badge.elapsed
	badge.scripts.OnUpdate(badge, .5)
	equal(badge.elapsed, timer, "hovering card gutters pauses dismissal")
	badge.scripts.OnLeave()
	equal(hints.shown, shownBefore, "preview preserves the normal once-per-session history")
	badge.elapsed = 12
	nicknames:ShowPreview()
	equal(badge.elapsed, 0, "repeating the preview restarts the visible hint")
end
equal(opens, 1, "preview opens a closed friends window without toggling an open one")
equal(values.name, "%nickname%", "preview leaves the name setting untouched")
equal(values.compactMode, true, "preview leaves compact mode untouched")
equal(values.brokerEnabled, false, "preview leaves broker integration untouched")
equal(next(names), namesBefore, "preview does not create a nickname")
equal(next(guildNames), guildNamesBefore, "preview does not create a guild nickname")

-- The collapsed message must explain why it appears before offering a setting.
local savedValues = values
for _, reason in ipairs({ { "enUS", "not shown" }, { "deDE", "noch nicht angezeigt" } }) do
	BFL:SetLocale(reason[1])
	nicknames:ShowPreview()
	contains(badge.rows[1].description.text, reason[2], "collapsed notice explains that nickname display is disabled")
	values = { guildTabUseNicknames = false }
	contains(nicknames:GetGuidance("guild"), reason[2], "guild guidance explains its missing display")
	values = { guildBrokerEnabled = true }
	contains(nicknames:GetGuidance("guild"), reason[2], "broker-only guidance explains its missing display")
end
values = savedValues
BFL:SetLocale("enUS")

-- Native frame measurements can differ slightly from SetWidth, especially at fractional scales.
-- Limit calls so the old recursive layout fails here instead of hanging the test process.
local getWidth, layoutBadge = badge.GetWidth, hints.LayoutBadge
for _, error in ipairs({ 0.000030517578125, -0.000030517578125, 0.001, -0.001 }) do
	local layoutCalls = 0
	function badge:GetWidth() return getWidth(self) + error end
	function hints:LayoutBadge()
		layoutCalls = layoutCalls + 1
		assert(layoutCalls <= 4, "nickname layout did not terminate with native width rounding")
		return layoutBadge(self)
	end
	local precisionOK, precisionError = pcall(function()
		nicknames:ShowPreview()
		badge.more.scripts.OnClick()
		badge.more.scripts.OnClick()
		hints:RefreshAppearance()
	end)
	badge.GetWidth, hints.LayoutBadge = getWidth, layoutBadge
	assert(precisionOK, precisionError)
	equal(layoutCalls, 4, "preview, expand, collapse and restyle each need one layout pass despite rounding")
end

-- Native size/skin callbacks can fire synchronously from a setter. Reflow must not reenter itself.
local setWidth, sizeCallbacks = badge.SetWidth, 0
function badge:SetWidth(width)
	sizeCallbacks = sizeCallbacks + 1
	assert(sizeCallbacks == 1, "native size callback reentered nickname layout")
	setWidth(self, width)
	hints:RefreshAppearance()
end
local callbackOK, callbackError = pcall(nicknames.ShowPreview, nicknames)
badge.SetWidth = setWidth
assert(callbackOK, callbackError)
assert(not badge.layoutInProgress, "reentrant callback does not leave layout locked")

-- Hover may run while native widgets move or hide. It must never start another layout.
function hints:LayoutBadge() error("hover started a recursive nickname layout") end
for _, surface in ipairs({ badge, badge.more, badge.viewport, badge.scrollbar }) do
	surface.scripts.OnEnter()
	surface.scripts.OnLeave()
end
hints.LayoutBadge = layoutBadge

-- Small native coordinate jitter must not trigger a reflow every OnUpdate.
local getBounds = hints.GetDockBounds
function hints:GetDockBounds()
	local bounds = getBounds(self)
	bounds.parentTop = badge.layoutBounds.parentTop + 0.000030517578125
	return bounds
end
function hints:LayoutBadge() error("native coordinate jitter repeatedly relaid out the notice") end
badge.scripts.OnUpdate(badge, .25)
hints.GetDockBounds, hints.LayoutBadge = getBounds, layoutBadge
io.write("PASS: native size rounding, synchronous callbacks and hover cannot recurse into nickname layout\n")

-- Expanded notices keep the same top edge; long content uses the real native scroll handlers.
local layoutCases, scrollCases, pagedCases, loweredShelfCases = 0, 0, 0, 0
local function near(actual, expected, message)
	assert(math.abs(actual - expected) < .001, message .. ": " .. tostring(actual) .. " vs " .. tostring(expected))
end
local rail = frame()
rail.parent, rail.width, rail.height = BetterFriendsFrame, 68, 60
FriendsUI.sideTabs = { rail }
for _, locale in ipairs(locales) do
	BFL:SetLocale(locale)
	for _, selectedTheme in ipairs({ "blizzard", "custom" }) do
		theme = selectedTheme
		for _, useModern in ipairs({ false, true }) do
			modernStyle = useModern
			for scenario = 1, 3 do
				fontScale = ({ 1, 1.4, 1.8 })[scenario]
				BetterFriendsFrame.scale = ({ 1, .85, 1.4 })[scenario]
				UIParent.height, UIParent.width = ({ 1000, 650, 420 })[scenario], ({ 1280, 1024, 800 })[scenario]
				UIParent.top = UIParent.height
				BetterFriendsFrame.top = scenario == 2 and 260 or UIParent.top / BetterFriendsFrame.scale - 18
				BetterFriendsFrame.left = scenario == 2 and UIParent.width / BetterFriendsFrame.scale - BetterFriendsFrame.width - 190 or 12
				rail.left, rail.top, rail.shown = BetterFriendsFrame:GetRight(), BetterFriendsFrame.top - 122, useModern
				nicknames:ShowPreview()
				local top, left = badge.dockPlan.top, badge.dockPlan.left
				local collapsedHeight = badge:GetHeight()
				near(top, BetterFriendsFrame.top, "notice aligns with the main title bar")
				badge.more.scripts.OnClick()
				near(badge.dockPlan.top, top, "expanding must not move the card up")
				near(badge.dockPlan.left, left, "expanding must not move the card sideways")
				local bounds = hints:GetDockBounds()
				assert(badge.dockPlan.left >= bounds.left and badge.dockPlan.left + badge:GetWidth() <= bounds.right,
					"expanded notice stays inside the screen horizontally")
				assert(badge.dockPlan.bottom >= bounds.bottom and badge.dockPlan.top <= bounds.top,
					"expanded notice stays inside the screen vertically")
				assert(badge:GetHeight() <= badge.dockPlan.maxHeight + .001, "height respects available room below the title bar")
				local function clearOfRail(x, y, w, h)
					return not useModern or x + w <= rail.left or x >= rail:GetRight()
						or y - h >= rail.top or y <= rail:GetBottom()
				end
				assert(clearOfRail(left, top, badge:GetWidth(), badge:GetHeight()), "the badge cannot cover a visible tab")
				if badge.details:IsShown() then
					near(badge:GetHeight(), collapsedHeight, "detail list leaves the entire summary in place")
					local x, y = left + badge.details.point[4], badge.dockPlan.bottom
					near(x + badge.details:GetWidth(), left + badge:GetWidth(), "the whole card shares its right edge at every scale")
					assert(x + badge.details:GetWidth() <= bounds.right and y - badge.details:GetHeight() >= bounds.bottom,
						"details stay inside the screen")
					assert(clearOfRail(x, y, badge.details:GetWidth(), badge.details:GetHeight()), "details cannot cover a visible tab")
					assert(-badge.details.viewport.point[5] >= badge.details.stepDrop + 6,
						"the first heading clears the shoulder at every tested scale")
					if useModern and selectedTheme == "blizzard" and badge.details.indent > 0 then
						local innerClip = badge.nativeBorderClips[3]
						near(x + innerClip.points.TOPLEFT[4], bounds.tabRight - 2,
							"the native border only enters the transparent tab gutter at every tested scale")
						local shelf = badge.nativeBorderClips[2]
						assert(y + shelf.points.BOTTOMRIGHT[5] >= bounds.tabTop + .999,
							"the native shelf clears the first tab even when its artwork reaches the clip")
						if badge.details.stepDrop > 0 then loweredShelfCases = loweredShelfCases + 1 end
					end
					equal(badge.rows[1].parent, badge.scrollContent, "details leave the reason visible in the badge")
				else
					assert(badge.pager:IsShown(), "limited room uses inline paging")
					equal(badge.pageNumber.text, "1/3", "pager starts at the first additional option")
					equal(badge.previous.enabled, false, "previous stops at the first option")
					equal(badge.rows[1].shown, false, "fallback shows one option at a time")
					badge.next.scripts.OnClick()
					badge.next.scripts.OnClick()
					equal(badge.pageNumber.text, "3/3", "pager reaches the final option")
					equal(badge.next.enabled, false, "next stops at the final option")
					equal(badge.rows[4].parent, badge.scrollContent, "last option is reachable in the compact card")
					assert(clearOfRail(left, top, badge:GetWidth(), badge:GetHeight()), "paging stays clear of the tabs")
					pagedCases = pagedCases + 1
				end
				for _, action in ipairs({ badge.open, badge.more }) do
					local actionBottom = -action.point[5] + action:GetHeight()
					assert(actionBottom <= badge:GetHeight() - 9, "footer action is fully visible")
				end
				for _, row in ipairs(badge.rows) do
					if row.shown then
						for _, text in ipairs({ row.heading, row.description, row.path }) do
							if text.shown then
								assert(-text.point[3] + text:GetHeight() <= row:GetHeight() - 2, "text stays inside its option bounds")
								assert(text.point[2] + text:GetWidth() <= row:GetWidth(), "option text stays inside the shared surface")
							end
						end
					end
				end
				local panel = badge.details:IsShown() and badge.details or badge
				if panel.scrollRange > 0 then
					scrollCases = scrollCases + 1
					assert(panel.scrollbar.shown, "overflow has a visible scrollbar")
					equal(panel.scrollbar:GetWidth(), 8, "overflow uses a slim scrollbar")
					panel.viewport.scripts.OnMouseWheel(panel.viewport, -1)
					assert(panel.viewport:GetVerticalScroll() > 0, "mouse wheel scrolls the clipped content")
					panel.scrollbar:SetValue(panel.scrollRange)
					near(panel.viewport:GetVerticalScroll(), panel.scrollRange, "scrollbar reaches the end")
					local last = badge.rows[#hints.entries]
					local lastBottom = -last.point[5] + last:GetHeight() - panel.viewport:GetVerticalScroll()
					assert(lastBottom <= panel.viewport:GetHeight() + .001, "last option and its full path remain reachable")
					panel.scrollbar.scripts.OnEnter()
					local timer = badge.elapsed
					badge.scripts.OnUpdate(badge, .5)
					near(badge.elapsed, timer, "scrollbar interaction pauses auto-dismiss")
					panel.scrollbar.scripts.OnLeave()
				end
				badge.more.scripts.OnClick()
				near(badge.dockPlan.top, top, "collapsing retains the same title line")
				equal(badge.viewport:GetVerticalScroll(), 0, "collapsing clears stale scroll offsets")
				assert(not badge.details:IsShown() and not badge.pager:IsShown(), "collapsing hides either expansion layout")
				layoutCases = layoutCases + 1
			end
		end
	end
end
assert(scrollCases > 0, "matrix must exercise actual overflow")
assert(pagedCases > 0, "matrix must exercise compact paging")
assert(loweredShelfCases > 0, "matrix must exercise reclaiming the space above the tabs")
-- The reported screenshot has the first tab 122 UI units below the title
-- and a rail about 55 units wide. The English primary message should fit.
fontScale, BetterFriendsFrame.scale, theme, modernStyle = .85, 1, "blizzard", true
UIParent.top, UIParent.height, UIParent.width = 700, 700, 640
BetterFriendsFrame.top, BetterFriendsFrame.left, BetterFriendsFrame.width = 690, 0, 320
rail.top, rail.left, rail.width, rail.shown = 568, BetterFriendsFrame:GetRight(), 55, true
BFL:SetLocale("enUS")
center = false
nicknames:ShowPreview()
badge.more.scripts.OnClick()
assert(badge.details:IsShown() and not badge.scrollbar:IsShown(), "the reported rail geometry fits the full primary message")
assert(-badge.rows[1].path.point[3] + badge.rows[1].path:GetHeight() <= badge.viewport:GetHeight(),
	"the primary settings path is fully visible")
BetterFriendsFrame.width, rail.width = 360, 68
fontScale, BetterFriendsFrame.scale, theme, modernStyle = 1, 1, "blizzard", true
UIParent.top, UIParent.height, UIParent.width = 650, 650, 760
BetterFriendsFrame.top, BetterFriendsFrame.left = 620, 200
rail.top, rail.left, rail.shown = 498, BetterFriendsFrame:GetRight(), true
BFL:SetLocale("enUS")
center = true
nicknames:ShowPreview()
badge.more.scripts.OnClick()
assert(badge.pager:IsShown(), "a visible rail with too little width beside it uses the pager")
badge.next.scripts.OnClick()
badge.previous.scripts.OnClick()
equal(badge.pageNumber.text, "1/3", "previous returns to the first option")
badge.next.scripts.OnClick()
local selected = hints.entries[3]
badge.open.scripts.OnClick()
equal(opened[1], selected.page, "pager settings action opens the visible option")
equal(opened[2], selected.control, "pager settings action preserves its control target")
assert(not badge:IsShown(), "opening a paged option dismisses the badge")
FriendsUI.sideTabs = nil

-- A second feature uses the production card without any nickname state or wording.
BFL:SetLocale("enUS")
hints:Hide()
local callbacks = 0
local feature = {
	id = "smoke.feature.a", title = BFL.L.SETTINGS_SMOOTH_SCROLLING,
	entries = { { text = BFL.L.SETTINGS_SMOOTH_SCROLLING_DESC,
		onClick = function() callbacks = callbacks + 1 end } },
	actionText = BFL.L.SETTINGS_SMOOTH_SCROLLING,
}
assert(hints:Show(feature), "another feature can use the shared card")
equal(badge.title.text, feature.title, "title comes from the feature")
equal(badge.icon.texture, "Interface\\AddOns\\BetterFriendlist\\Icons\\info.blp", "generic default icon has no nickname dependency")
assert(hints:IsShown(feature.id), "feature identity belongs to the shared service")
local other = { id = "smoke.feature.b", title = feature.title, entries = feature.entries }
assert(not hints:Show(other) and not hints.shown[other.id], "busy card does not consume another feature's session hint")
hints:Hide(other.id)
assert(hints:IsShown(feature.id), "one feature cannot dismiss another feature's card")
badge.open.scripts.OnClick()
equal(callbacks, 1, "feature action executes once")
assert(not hints:IsShown(), "feature action dismisses the card")
assert(not hints:Show(feature), "automatic hints are once per feature per session")
assert(hints:Show(other), "another feature has its own session limit")
feature.oncePerSession, feature.replace = false, true
assert(hints:Show(feature), "explicit previews can replace the current card")
equal(hints.id, feature.id, "preview replaces all active feature content")
hints:Hide()
local informational = {
	id = "smoke.information", title = feature.title, duration = 2,
	entries = { { text = BFL.L.SETTINGS_SMOOTH_SCROLLING_DESC } },
}
assert(hints:Show(informational), "plain guidance does not need an action")
assert(not badge.open.shown and not badge.more.shown and not badge.hasFooter,
	"plain guidance has no empty settings action or options footer")
badge.scripts.OnUpdate(badge, 2.5)
equal(badge.alpha, .5, "each feature can choose its own visible duration")
badge.scripts.OnUpdate(badge, .6)
assert(not hints:IsShown(), "custom duration still fades and dismisses normally")
local anchor = frame()
anchor.top, anchor.left, anchor.width = 800, 20, 300
informational.id, informational.anchor = "smoke.anchor", anchor
assert(hints:Show(informational), "feature can choose an addon-owned anchor")
equal(badge.parent, anchor, "generic docking uses the supplied anchor")
anchor:Hide()
assert(not hints:IsShown(), "closing a custom anchor permanently dismisses its hint")
informational.id = "smoke.hidden-anchor"
assert(not hints:Show(informational) and not hints.shown[informational.id], "hidden anchors do not consume guidance")

-- Both the popup and the note editor share guidance after a saved change.
do
	BetterFriendlistDB = {}
	loadFile("Modules/ContactMemory.lua")
	local notes = BFL:GetModule("ContactMemory")
	notes:Initialize()
	notes:SetEnabled(true)
	BetterFriendsFrame:Show()
	BFL:SetLocale("enUS")

	local key = "player:Example-Realm"
	local noteText = "Visible note"
	local notePopup = StaticPopupDialogs.BFL_CONTACT_MEMORY_SET_NOTE
	local popupFrame = frame()
	local editBox = { GetText = function() return noteText end, GetParent = function() return popupFrame end }
	popupFrame.EditBox, popupFrame.data = editBox, { contactKey = key }
	local function Accept()
		notePopup.OnAccept(popupFrame, popupFrame.data)
	end
	Accept()
	equal(notes:GetContact(key).privateNote, noteText, "the visible note still saves")
	assert(not hints:IsShown(), "enabled tooltip display produces no hint")
	values.streamer = true
	noteText = "Hidden only while streaming"
	Accept()
	assert(not hints:IsShown(), "streamer-only suppression produces no tooltip-setting hint")
	values.streamer = false

	notes:SetSetting("showTooltipSection", false)
	noteText = "  Hidden only while streaming  "
	Accept()
	assert(not hints:IsShown(), "unchanged normalized text produces no hint")
	assert(notes:SetPrivateNote(key, "Direct write"))
	assert(not hints:IsShown(), "model-only writes produce no hint")
	center = false
	noteText = "A private note"
	Accept()
	assert(hints:IsShown("privateNotes.tooltips"), "the popup hints after saving hidden text")
	equal(notes:GetContact(key).privateNote, noteText, "the note is saved before guidance appears")
	equal(hints.entries[1].path, BFL.L.CONTACT_MEMORY_TITLE .. " > " .. BFL.L.CONTACT_MEMORY_SETTINGS_TOOLTIPS,
		"legacy path names the note setting")
	assert(not hints.entries[1].text:find(noteText, 1, true), "guidance contains no private text")
	badge.open.scripts.OnClick()
	equal(opened[1], 14, "legacy opens Private Notes")
	equal(opened[2], "privateNotesTooltips", "legacy scrolls to the tooltip checkbox")

	noteText = "Another edit"
	Accept()
	assert(not hints:IsShown(), "the hint only appears once per session")
	hints.shown = nil
	center = true
	noteText = "Entered note"
	notePopup.EditBoxOnEnterPressed(editBox)
	assert(hints:IsShown("privateNotes.tooltips"), "Enter uses the same save guidance")
	equal(notes:GetContact(key).privateNote, noteText, "Enter saves the note")
	contains(hints.entries[1].path, BFL.L.SETTINGS_CENTER_CATEGORY_PRIVACY, "Settings Center includes the privacy category")
	badge.open.scripts.OnClick()
	equal(opened[1], "privacy.notes", "Settings Center opens Private Notes")
	equal(opened[2], "contactMemory.showTooltipSection", "Settings Center focuses the exact toggle")

	local createFrame = CreateFrame
	local buttons = {}
	CreateFrame = function(kind, name, parent, template)
		local widget = createFrame(kind, name, parent, template)
		for _, method in ipairs({ "SetFrameStrata", "SetMovable", "RegisterForDrag", "SetMultiLine",
			"SetAutoFocus", "SetTextInsets", "SetNormalFontObject", "SetHighlightFontObject" }) do
			widget[method] = function() end
		end
		function widget:GetText() return self.text end
		if kind == "Button" then buttons[#buttons + 1] = widget end
		return widget
	end
	local dialog = notes:EnsureNoteDialog()
	CreateFrame = createFrame
	local save = assert(buttons[3]).scripts.OnClick
	hints.shown = nil
	dialog.contactKey = key
	dialog.editBox:SetText("Edited in the note window")
	save()
	assert(hints:IsShown("privateNotes.tooltips"), "the multiline editor shows the same hint")
	equal(notes:GetContact(key).privateNote, "Edited in the note window", "the editor saves before closing")
	hints:Hide()
	hints.shown = nil
	dialog.contactKey = key
	dialog.editBox:SetText("  ")
	save()
	equal(notes:GetContact(key), nil, "blank text still clears the note")
	assert(not hints:IsShown(), "clearing a note produces no hint")
end
io.write("PASS: private-note save callbacks, tooltip gating, session deduplication and both settings links\n")
do
	loadFile("Modules/NewGroupHints.lua")
	loadFile("Modules/Dialogs.lua")
	local groups = BFL:RegisterModule("Groups", {})
	local friends = BFL:RegisterModule("FriendsList", {})
	local quickFilters = BFL:RegisterModule("QuickFilters", {})
	local selectedTags, member, assignedUID = {}, nil, nil
	function groups:ValidateGroupName(name) return name ~= "" end
	function groups:Create(name) return true, "custom_" .. name end
	function groups:ToggleFriendInGroup(uid) assignedUID = uid; return true end
	function friends:SyncGroups() end
	function friends:ResolveFriendByUID() return member end
	function friends:PassesFilters(friend) return friend.matches end
	function quickFilters:GetActiveTagFilterDefinitions() return selectedTags end
	function quickFilters:ResetFilters() selectedTags, friends.filterMode = {}, "all" end
	function BFL:ClearFriendsListSearch() friends.searchText = "" end
	local file = assert(io.open(root .. "/Modules/FriendsList.lua", "rb"))
	local source = file:read("*a")
	file:close()
	local create = assert(source:find("function FriendsList:CreateGroup(", 1, true))
	local nextSection = assert(source:find("-- Rename a group", create, true))
	assert(load(source:sub(create, nextSection - 1), "@production group creation", "t", {
		FriendsList = friends, BFL = BFL, GetGroups = function() return groups end,
	}))()

	local popup = StaticPopupDialogs.BETTER_FRIENDLIST_CREATE_GROUP
	local assignedPopup = StaticPopupDialogs.BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND
	local dialog = { data = "bnet_test", Hide = function(self) self.hidden = true end }
	dialog.EditBox = { GetText = function() return "Example" end, GetParent = function() return dialog end }
	local function Reset()
		hints:Hide()
		hints.shown = nil
		friends.searchText, friends.filterMode = "", "all"
		selectedTags, values.hideEmptyGroups = {}, false
	end
	Reset()
	popup.OnAccept(dialog)
	assert(not hints:IsShown(), "visible new group needs no hint")
	values.hideEmptyGroups, center = true, false
	popup.EditBoxOnEnterPressed(dialog.EditBox)
	assert(hints:IsShown() and dialog.hidden, "Enter saves an empty hidden group")
	badge.open.scripts.OnClick()
	equal(opened[1], 1, "Legacy opens General")
	equal(opened[2], "hideEmptyGroups", "Legacy navigates to the visibility checkbox")
	center, hints.shown = true, nil
	popup.OnAccept(dialog)
	badge.open.scripts.OnClick()
	equal(opened[1], "groups.builtins", "Settings Center opens built-in groups")
	equal(opened[2], "hideEmptyGroups", "Settings Center focuses the visibility toggle")

	Reset()
	friends.searchText = "example query"
	popup.OnAccept(dialog)
	equal(hints.entries[1].text, BFL.L.NEW_GROUP_HINT_SEARCH, "search reason is explicit")
	equal(badge.open.label.text, BFL.L.NEW_GROUP_HINT_SHOW_ALL .. "  >", "view reset has its own action label")
	badge.open.scripts.OnClick()
	equal(friends.searchText, "", "the action clears the search")
	Reset()
	friends.filterMode, selectedTags = "online", { { id = "tag" } }
	popup.OnAccept(dialog)
	equal(hints.entries[1].text, BFL.L.NEW_GROUP_HINT_FILTER, "filter reason is explicit")
	badge.open.scripts.OnClick()
	equal(friends.filterMode, "all", "the action resets the quick filter")
	equal(#selectedTags, 0, "the action also clears tag filters")

	Reset()
	values.hideEmptyGroups, friends.searchText, friends.filterMode = true, "example", "online"
	popup.OnAccept(dialog)
	equal(#hints.entries, 2, "independent blockers both get actions")
	equal(hints.entries[2].text, BFL.L.NEW_GROUP_HINT_SEARCH_FILTER, "combined view reason is explicit")
	hints:OpenEntry(hints.entries[2])
	equal(values.hideEmptyGroups, true, "clearing the view keeps the persistent visibility preference")
	Reset()
	values.hideEmptyGroups, member = true, { connected = true, matches = true }
	assignedPopup.EditBoxOnEnterPressed(dialog.EditBox)
	equal(assignedUID, dialog.data, "Enter keeps the assigned friend from popup data")
	assert(not hints:IsShown(), "assigned visible online friend makes the new group visible")
	member.connected = false
	assignedPopup.OnAccept(dialog, dialog.data)
	assert(hints:IsShown("newGroup.empty"), "assigned offline friend still leaves the group hidden")
end
io.write("PASS: new group creation, assigned friends, combined blockers and actionable settings/search/filter links\n")

do
	hints:Hide()
	hints.shown = nil
	loadFile("Modules/FavoriteHints.lua")
	local favorites = BFL:GetModule("FavoriteHints")
	ADD_FAVORITE_STATUS = "Add Favorite"
	local add, remove = { text = ADD_FAVORITE_STATUS }, { text = "Remove Favorite" }
	local menu = {}
	function menu:EnumerateElementDescriptions() return ipairs({ remove, add }) end
	function menu:AddMenuResponseCallback(callback) self.respond = callback end
	BFL.Compat = { GetMenuElementText = function(element) return element.text end }
	function BFL:IsSecret() return false end
	favorites:ObserveMenu(menu)
	for _, state in ipairs({ {}, { true, false }, { false, true }, { true, true } }) do
		values.showFavoritesGroup, values.enableFavoriteIcon = state[1], state[2]
		menu.respond(nil, add)
		assert(not hints:IsShown(), "either visible favorite indicator suppresses guidance")
	end
	values.showFavoritesGroup, values.enableFavoriteIcon = false, false
	menu.respond(nil, remove)
	assert(not hints:IsShown(), "removing a favorite produces no hint")
	menu.respond(nil, { text = ADD_FAVORITE_STATUS })
	assert(not hints:IsShown(), "a different element with the same text is not the observed action")

	for _, useCenter in ipairs({ false, true }) do
		center, hints.shown = useCenter, nil
		menu.respond(nil, add)
		assert(hints:IsShown("favorites.visibility"), "marking a hidden favorite shows guidance")
		contains(hints.entries[1].path,
			useCenter and BFL.L.SETTINGS_CENTER_PAGE_GROUPS_BUILTINS or BFL.L.SETTINGS_GROUP_MANAGEMENT,
			"the first breadcrumb matches the active UI")
		contains(hints.entries[2].path,
			useCenter and BFL.L.SETTINGS_CENTER_PAGE_FRIENDS_DISPLAY or BFL.L.SETTINGS_DISPLAY_OPTIONS,
			"the second breadcrumb matches the active UI")
		badge.open.scripts.OnClick()
		equal(opened[1], useCenter and "groups.builtins" or 1, "favorite group opens in the active settings UI")
		equal(opened[2], "showFavoritesGroup", "favorite group focuses its own toggle")
		menu.respond(nil, add)
		assert(not hints:IsShown(), "the hint follows the shared session limit")

		hints.shown = nil
		menu.respond(nil, add)
		badge.more.scripts.OnClick()
		if badge.pager:IsShown() then badge.open.scripts.OnClick() else badge.rows[2].scripts.OnClick() end
		equal(opened[1], useCenter and "friends.display" or 1, "favorite icon opens in the active settings UI")
		equal(opened[2], "enableFavoriteIcon", "favorite icon focuses its own toggle")
	end
end
io.write("PASS: favorite hints after marking, both visibility toggles and both settings UIs\n")
io.write("PASS: independent feature IDs, busy handling, previews, custom actions, durations and anchors\n")
io.write("PASS: " .. layoutCases .. " expanded layouts, " .. scrollCases .. " scroll cases, " .. pagedCases .. " paged layouts\n")
io.write("PASS: nickname guidance, all 11 locales, both settings UIs, display detection, dismissal and friend/guild popup callbacks\n")
