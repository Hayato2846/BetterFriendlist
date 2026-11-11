-- lua tools/BFL-LegacySettingsStyleSmoke.lua <repo> <Retail UI source>
-- Production style owner; addon-owned frames and theme lifecycle are mocked.
local root = arg[1] or "."
local uiRoot = assert(arg[2], "Retail UI source root is required")
function GetCurrentEnvironment() return _G end
assert(loadfile(uiRoot .. "/Interface/AddOns/Blizzard_SharedXML/SecureScrollTemplates.lua"))()
ScrollUtil, ScrollBoxConstants, BaseScrollBoxEvents = {}, { NoScrollInterpolation = true }, { OnScroll = "OnScroll" }
function Saturate(value) return math.max(0, math.min(1, value)) end
local file = assert(io.open(uiRoot .. "/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua", "rb"))
local native = file:read("*a"); file:close()
local first = assert(native:find("function ScrollUtil.InitScrollFrameWithScrollBar(", 1, true))
local last = assert(native:find("function ScrollUtil.EnableSnapToInterval(", first, true))
assert(load(native:sub(first, last - 1), "@native ScrollUtil.InitScrollFrameWithScrollBar"))()
local function float32(value) return (string.unpack("f", string.pack("f", value))) end
unpack = table.unpack
local theme, modern, hasAtlas = "blizzard", false, true
local modules, checks = {}, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local palettes = {
	blizzard = { background = { .04, .04, .04, 1 }, border = { 1, 1, 1, 1 } },
	dark = { background = { .07, .08, .09, .8 }, border = { .25, .26, .27, .6 } },
	custom = { background = { .12, .10, .07, .9 }, border = { .6, .4, .2, .7 } },
}
local BFL = { IsMainline = true, HasModernScrollBox = true }
function BFL:RegisterModule(name, module) modules[name] = module; return module end
function BFL:GetModule(name) return modules[name] end
function BFL:GetEffectiveTheme() return theme end
function BFL.HasAtlas() return hasAtlas end
function BFL.SetTextureOrAtlas(texture, atlas) texture.atlas, texture.height = atlas, 180; return true end
local function region(parent)
	local r = { shown = true, alpha = 1, textures = {}, scripts = {}, hooks = {}, points = {}, parent = parent }
	function r:GetParent() return self.parent end
	function r:GetName() return "MockSettings" end
	function r:SetScript(event, callback) self.scripts[event] = callback end
	function r:GetScript(event) return self.scripts[event] end
	function r:HookScript(event, callback)
		self.hooks[event] = self.hooks[event] or {}
		table.insert(self.hooks[event], callback)
	end
	function r:RunScript(event, ...)
		if self.scripts[event] then self.scripts[event](self, ...) end
		for _, callback in ipairs(self.hooks[event] or {}) do callback(self, ...) end
	end
	function r:SetShown(value)
		local changed = self.shown ~= value
		self.shown = value
		if changed then self:RunScript(value and "OnShow" or "OnHide") end
	end
	function r:IsShown() return self.shown end
	function r:Hide() self:SetShown(false) end
	function r:Show() self:SetShown(true) end
	function r:SetAllPoints(target) self.allPoints = target end
	function r:SetPoint(point, ...) self.points[point] = { ... } end
	function r:ClearAllPoints() self.points = {} end
	function r:SetHeight(value) self.height = float32(value) end
	function r:GetHeight() return self.height or 0 end
	function r:SetWidth(value) self.width = value end
	function r:SetAlpha(value) self.alpha = value end
	function r:SetColorTexture(...) self.color = { ... } end
	function r:SetVertexColor(...) self.vertex = { ... } end
	function r:SetTexelSnappingBias() end
	function r:SetSnapToPixelGrid() end
	function r:SetText(value) self.textValue = value end
	function r:SetJustifyH() end
	function r:SetEnabled(value) self.enabled = value end
	function r:Enable() self:SetEnabled(true) end
	function r:Disable() self:SetEnabled(false) end
	function r:EnableMouseWheel(value) self.mouseWheel = value end
	function r:SetBackdropBorderColor(...) self.border = { ... } end
	function r:CreateTexture()
		local texture = region(self)
		self.textures[#self.textures + 1] = texture
		return texture
	end
	function r:CreateFontString() return region(self) end
	function r:GetVerticalScrollRange() return math.max(0, self.Content:GetHeight() - self:GetHeight()) end
	function r:GetVerticalScroll() return self.offset or 0 end
	function r:SetVerticalScroll(offset)
		offset = float32(math.max(0, math.min(self:GetVerticalScrollRange(), offset)))
		local changed = self:GetVerticalScroll() ~= offset
		self.offset = offset
		if changed then self:RunScript("OnVerticalScroll", offset) end
	end
	function r:SetMinMaxValues(low, high) self.low, self.high = low, high; self:SetValue(self:GetValue()) end
	function r:GetMinMaxValues() return self.low or 0, self.high or 0 end
	function r:GetValue() return self.value or 0 end
	function r:SetValue(value)
		value = math.max(self.low or 0, math.min(self.high or 0, value))
		local changed = self:GetValue() ~= value
		self.value = value
		if changed then self:RunScript("OnValueChanged", value) end
	end
	function r:SetHideIfUnscrollable(value) self.hideIfUnscrollable = value end
	function r:RegisterCallback(event, callback, owner)
		assert(not self.callback, "modern scrollbar registered more than once")
		self.callback, self.callbackOwner = callback, owner
	end
	function r:SetScrollPercentage(value)
		self.percentage = Saturate(value)
		-- The native scrollbar dispatches even when the percentage is unchanged.
		if self.callback then self.callback(self.callbackOwner, self.percentage) end
	end
	function r:SetVisibleExtentPercentage(value)
		self.visibleExtent = value
		if self.hideIfUnscrollable then self:SetShown(value < 1) end
	end
	function r:SetPanExtentPercentage(value) self.panExtent = value end
	function r:ScrollStepInDirection(direction) self:SetScrollPercentage((self.percentage or 0) + direction * self.panExtent) end
	return r
end
function CreateFrame(kind, name, parent, template)
	local result = region(parent)
	result.template = template
	return result
end
assert(loadfile(root .. "/Modules/SettingsComponents.lua"))("BetterFriendlist", BFL)
local function window()
	local frame = region()
	frame.Bg, frame.MainInset, frame.ButtonSeparator, frame.CategoryList = region(frame), region(frame), region(frame), region(frame)
	frame.MainInset:SetBackdropBorderColor(.4, .4, .4, .8)
	local scroll = region(frame)
	frame.ContentScrollFrame = scroll
	scroll:SetHeight(400)
	scroll.Content = region(scroll)
	scroll.Content:SetHeight(2000)

	return frame
end
BetterFriendlistSettingsFrame = window()
modules.FriendsUI = {
	IsModernActive = function() return modern end,
	GetModernThemeColors = function(_, selected) return palettes[selected] end,
}
local themeCalls, skinCalls, showCalls = 0, 0, 0
modules.ThemeManager = { ApplyCurrentTheme = function() themeCalls = themeCalls + 1; return true end }
modules.DarkTheme = { SkinSettingsFrame = function()
	skinCalls = skinCalls + 1
	local frame = BetterFriendlistSettingsFrame
	frame.Bg:SetShown(false)
	frame.MainInset:SetBackdropBorderColor(.2, .3, .4, .5)
	for _, texture in ipairs(frame.textures) do texture:SetAlpha(0) end
end }
modules.SettingsDesigner = setmetatable({}, { __index = function() error("Settings Center was touched") end })
function hooksecurefunc(owner, method, callback)
	local original = assert(owner[method])
	owner[method] = function(...)
		local results = table.pack(original(...))
		callback(...)
		return table.unpack(results, 1, results.n)
	end
end
local settingsFile = assert(io.open(root .. "/Modules/Settings.lua", "rb"))
local settingsSource = settingsFile:read("*a"); settingsFile:close()
local helperFirst = assert(settingsSource:find("local function HasSettingsScrollOverflow(", 1, true))
local helperLast = assert(settingsSource:find("local function SetDeleteIconTexture(", helperFirst, true))
local settingsEnv = setmetatable({ Settings = {} }, { __index = _G })
assert(load(settingsSource:sub(helperFirst, helperLast - 1), "@production settings scrollbar visibility", "t", settingsEnv))()
modules.Settings = settingsEnv.Settings
assert(loadfile(root .. "/Modules/LegacySettingsStyle.lua"))("BetterFriendlist", BFL)
local style = modules.LegacySettingsStyle
local frame = BetterFriendlistSettingsFrame
frame.scripts.OnShow = function() showCalls = showCalls + 1 end
style:Initialize()
check(#frame.textures == 0 and frame.Bg.shown, "initial Legacy appearance stays untouched")
modern = true
frame:RunScript("OnShow")
local surfaces = frame.BFL_ModernSettingsBackgrounds
check(showCalls == 1, "native OnShow is preserved")
check(surfaces and #frame.textures == 4, "Modern creates one shared surface, two fades and a navigation divider")
check(surfaces.body.allPoints == frame.Bg, "background stays within native border bounds")
check(surfaces.body.color[1] == palettes.blizzard.background[1], "Modern uses the Changelog palette")
check(not frame.Bg.shown and frame.MainInset.border[4] == 0, "Modern has no Legacy rock or second inner rim")
check(not frame.ButtonSeparator.shown, "no extra bottom rim splits the Modern surface")
check(surfaces.navigationDivider.shown and surfaces.navigationDivider.width == 1, "navigation has a subtle vertical separation")
check(surfaces.navigationDivider.points.TOPLEFT[1] == frame.CategoryList, "vertical separation follows dynamic sidebar width")
local scroll = frame.ContentScrollFrame
local scrollbar = scroll.ScrollBar
check(scrollbar.template == "MinimalScrollBar" and scrollbar.shown, "settings use the native minimal scrollbar")
modules.Settings:UpdateLegacySettingsScrollbar(scroll)
check(scroll.ScrollBar == scrollbar, "refreshing keeps the original minimal scrollbar")
scrollbar:SetScrollPercentage(.75)
check(scroll:GetVerticalScroll() == 1200, "dragging the modern thumb scrolls the existing content")
scroll:RunScript("OnMouseWheel", 1)
check(scroll:GetVerticalScroll() == 1170, "modern mouse wheel uses the native 30-point pan extent")
scroll:SetHeight(432.71435546875)
scroll.Content:SetHeight(2467.1259765625)
scroll:RunScript("OnScrollRangeChanged", 0, scroll:GetVerticalScrollRange())
scrollbar:SetScrollPercentage(.37123456789)
check(math.abs(scroll:GetVerticalScroll() / scroll:GetVerticalScrollRange() - scrollbar.percentage) < .000001,
	"fractional scroll measurements converge without callback recursion")
scroll.Content:SetHeight(scroll:GetHeight())
scroll:RunScript("OnScrollRangeChanged", 0, 0)
check(not scrollbar.shown, "short categories have no scrollbar")
scroll.Content:SetHeight(2000)
scroll:RunScript("OnScrollRangeChanged", 0, scroll:GetVerticalScrollRange())
check(scrollbar.shown, "switching to a longer category restores the modern scrollbar")
local page = region(scroll.Content)
local header1 = BFL.SettingsComponents:CreateHeader(page, "First")
local option = region(page); option:SetHeight(24)
local header2 = BFL.SettingsComponents:CreateHeader(page, "Second")
local sections = { header1, option, header2 }
BFL.SettingsComponents:AnchorChain(sections, -5)
check(not header1.BFL_SectionDivider and header2.BFL_SectionDivider.shown, "only section transitions get a horizontal divider")
check(header2.BFL_SectionDivider.atlas == "perks-divider-short" and header2:GetHeight() == 29,
	"same ornament as FriendsFrame without changing row heights")
check(header2.BFL_SectionDivider.points.TOPLEFT[4] == 7, "divider stays in the gap above its heading")
BFL.SettingsComponents:AnchorChain(sections, -5)
check(#header2.textures == 1, "repeated layout reuses its divider")
local outside = region(region())
local outside1 = BFL.SettingsComponents:CreateHeader(outside, "Outside first")
local outside2 = BFL.SettingsComponents:CreateHeader(outside, "Outside second")
BFL.SettingsComponents:AnchorChain({ outside1, outside2 }, -5)
check(not outside2.BFL_SectionDivider, "Settings Center and other component consumers get no legacy decoration")
check(surfaces.topFade.shown and surfaces.bottomFade.shown, "Blizzard Modern uses FriendsFrame artwork")
check(surfaces.topFade.height == 140 and surfaces.bottomFade.height == 140, "fade height matches the Changelog")
check(surfaces.topFade.points.TOPLEFT[1] == surfaces.body and surfaces.bottomFade.points.BOTTOMRIGHT[1] == surfaces.body,
	"all decorative artwork follows the inner surface")
for _ = 1, 8 do style:Refresh() end
check(#frame.textures == 4, "refreshing does not allocate more textures")
modern = false
check(modules.ThemeManager:ApplyCurrentTheme(), "original theme result is preserved")
check(themeCalls == 1 and frame.Bg.shown and frame.MainInset.border[4] == .8, "live Legacy switch restores native texture and rim")
check(not surfaces.body.shown and not surfaces.topFade.shown and frame.ButtonSeparator.shown, "Legacy restores all affected surfaces")
check(not surfaces.navigationDivider.shown and not header2.BFL_SectionDivider.shown, "Legacy hides both modern divider types")
check(scroll.ScrollBar == scrollbar and scrollbar.shown, "Legacy keeps the same minimal scrollbar")
scrollbar:SetScrollPercentage(.25)
local oldOffset = scroll:GetVerticalScroll()
scroll:RunScript("OnMouseWheel", -1)
check(scroll:GetVerticalScroll() > oldOffset, "mouse wheel works after switching layouts")
scroll:SetVerticalScroll(400)
modern = true
style:Refresh()
check(scroll:GetVerticalScroll() == 400, "switching layouts preserves the current offset")
modern, theme = true, "dark"
modules.DarkTheme:SkinSettingsFrame()
check(skinCalls == 1 and surfaces.body.shown and surfaces.body.alpha == 1, "deferred skinning cannot dim the Modern surface")
check(surfaces.body.color[3] == palettes.dark.background[3], "Dark uses its own palette")
check(frame.MainInset.border[4] == .5 and not frame.Bg.shown, "flat theme retains ownership of its native chrome")
check(not surfaces.topFade.shown and not surfaces.bottomFade.shown, "flat themes do not use Blizzard ornamentation")
check(header2.BFL_SectionDivider.shown and header2.BFL_SectionDivider.vertex[1] == palettes.dark.border[1],
	"section dividers follow the theme border palette")
check(surfaces.navigationDivider.color[1] == palettes.dark.border[1], "navigation divider follows the same palette")
theme = "custom"
modules.ThemeManager:ApplyCurrentTheme()
check(surfaces.body.color[1] == palettes.custom.background[1], "custom colors refresh immediately")
theme = "elvui"
modules.ThemeManager:ApplyCurrentTheme()
check(not surfaces.body.shown and not frame.Bg.shown and not frame.ButtonSeparator.shown, "external skins retain ownership")
theme, modern = "blizzard", false
modules.ThemeManager:ApplyCurrentTheme()
check(frame.Bg.shown and frame.MainInset.border[4] == .8, "returning to Blizzard Legacy restores its chrome")
BetterFriendlistSettingsFrame = window()
frame, hasAtlas, modern = BetterFriendlistSettingsFrame, false, true
style:Refresh()
surfaces = frame.BFL_ModernSettingsBackgrounds
check(surfaces.body.shown and not surfaces.topFade.shown and not surfaces.bottomFade.shown, "missing atlases retain a readable surface")
local fallbackPage = region(frame.ContentScrollFrame.Content)
local fallbackFirst = BFL.SettingsComponents:CreateHeader(fallbackPage, "Fallback first")
local fallbackSecond = BFL.SettingsComponents:CreateHeader(fallbackPage, "Fallback second")
BFL.SettingsComponents:AnchorChain({ fallbackFirst, fallbackSecond }, -5)
check(fallbackSecond.BFL_SectionDivider.height == 1, "missing divider atlas uses a thin compatible fallback")
local originalDivider = fallbackSecond.BFL_SectionDivider
fallbackPage.parent = region()
style:Refresh()
check(not originalDivider.shown, "reparented sections do not carry legacy decoration into another window")
BetterFriendlistSettingsFrame = window()
local nativeScrollUtil = ScrollUtil
ScrollUtil = nil
style:Refresh()
local fallbackScroll = BetterFriendlistSettingsFrame.ContentScrollFrame
check(not fallbackScroll.ScrollBar, "clients without the native scrollbar still use the mouse wheel")
fallbackScroll:RunScript("OnMouseWheel", -1)
check(fallbackScroll:GetVerticalScroll() == 30, "wheel fallback moves content")
ScrollUtil = nativeScrollUtil
BetterFriendlistSettingsFrame = window()
BFL.IsMainline = false
modules.FriendsUI = nil
style:Refresh()
check(#BetterFriendlistSettingsFrame.textures == 0 and BetterFriendlistSettingsFrame.Bg.shown,
	"Classic without FriendsUI keeps its existing Legacy settings window")
local comparison = {}
local calls = {}
local flatActive = true
modules.SkinEngine = { IsActive = function() return flatActive end }
function modules.DarkTheme:SkinSettingsComparison(engine, review)
	check(engine == modules.SkinEngine and review == comparison, "flat themes pass the current comparison to the shared skin")
	calls[#calls + 1] = "flat"
end
modules.ElvUISkin = { SkinSettingsComparison = function(_, review)
	check(review == comparison, "ElvUI receives the active comparison")
	calls[#calls + 1] = "elvui"
end }
modules.EllesmereUISkin = { SkinSettingsComparison = function(_, review)
	check(review == comparison, "EllesmereUI receives the active comparison")
	calls[#calls + 1] = "ellesmereui"
end }
theme = "dark"
style:SkinComparison(comparison)
theme = "custom"
style:SkinComparison(comparison)
flatActive = false
for _, selection in ipairs({ "elvui", "ellesmereui", "blizzard" }) do
	theme = selection
	style:SkinComparison(comparison)
end
check(table.concat(calls, ",") == "flat,flat,elvui,ellesmereui", "only the current skin touches the comparison")
-- Exercise the adapters with the real skin modules and instrumented widgets.
function BFL.IsModernDropdown(widget) return widget.modernDropdown == true end
local picker, input, scrollBar = region(), region(), region()
function input:GetObjectType() return "EditBox" end
function input:IsObjectType(kind) return kind == "EditBox" end
function picker:GetObjectType() return self.modernDropdown and "DropdownButton" or "Frame" end
local fakeComparison = {
	comparisonPicker = picker, comparisonEditor = input,
	hoverHelp = { scroll = { ScrollBar = scrollBar } },
}

assert(loadfile(root .. "/Modules/EllesmereUISkin.lua"))("BetterFriendlist", BFL)
local eui = modules.EllesmereUISkin
function eui:IsSkinEnabled() return true end
picker.modernDropdown = true
local euiPicker, euiInput, euiScroll
eui.facade = {
	Dropdown = function(widget) euiPicker = widget end,
	EditBox = function(widget) euiInput = widget end,
	ScrollBar = function(widget, keepSteppers) if keepSteppers then euiScroll = widget end end,
}
eui:SkinSettingsComparison(fakeComparison)
check(euiPicker == picker and euiInput == input and euiScroll == scrollBar,
	"EllesmereUI skins the live comparison selector, editor and scrollbar with steppers")

assert(loadfile(root .. "/Modules/ElvUISkin.lua"))("BetterFriendlist", BFL)
local elv = modules.ElvUISkin
function elv:IsSkinEnabled() return true end
function elv:IsModernFriendsUIActive() return false end
local elvModern, elvClassic, elvInput
function elv:SkinModernDropdown(_, widget) elvModern = widget end
function elv:SkinModernEditBox(_, widget) elvInput = widget end
elv.ElvUISkinProxy = { HandleDropDownBox = function(_, widget) elvClassic = widget end }
elv:SkinSettingsComparison(fakeComparison)
picker.modernDropdown = false
elv:SkinSettingsComparison(fakeComparison)
check(elvModern == picker and elvClassic == picker and elvInput == input,
	"ElvUI skins both Modern and Classic comparison dropdowns and the input")

assert(loadfile(root .. "/Modules/DarkTheme.lua"))("BetterFriendlist", BFL)
local dark = modules.DarkTheme
local laneRow, hiddenRow = region(), region()
hiddenRow:Hide()
fakeComparison.comparisonLanes = { region() }
fakeComparison.comparisonLanes[1].widgets = { laneRow, hiddenRow }
local darkControls, darkRows = {}, {}
dark:SkinSettingsComparison({
	SkinControl = function(_, widget) darkControls[widget] = true end,
	SkinRow = function(_, widget) darkRows[widget] = true end,
}, fakeComparison)
check(darkControls[picker] and darkControls[input] and darkRows[laneRow] and not darkRows[hiddenRow],
	"Dark and Custom skin active controls and visible samples")
io.write("PASS: legacy settings appearance, theme restoration, missing atlases and Classic fallback (" .. checks .. " checks)\n")
