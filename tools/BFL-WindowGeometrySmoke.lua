-- lua tools/BFL-WindowGeometrySmoke.lua <repo>
-- Geometry/persistence across distinct frame scales and relative anchors.
local root = arg[1] or "."
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1
	assert(math.abs(actual - expected) < 0.001, message .. ": " .. tostring(actual))
end
local BFL = { modules = {} }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
local env = setmetatable({ InCombatLockdown = function() return false end }, { __index = _G })
env.UIParent = {
	GetSize = function() return 1600, 900 end,
	GetWidth = function() return 1600 end,
	GetHeight = function() return 900 end,
	GetEffectiveScale = function() return 0.8 end,
}
local function Load(path) return assert(loadfile(root .. "/" .. path, "t", env))("BetterFriendlist", BFL) end
Load("Utils/WindowGeometry.lua")
Load("Modules/FrameSettings.lua")
local geometry = BFL.WindowGeometry
local function Window(left, bottom, width, height, ratio)
	local frame = { left = left, bottom = bottom, width = width, height = height, ratio = ratio or 1 }
	function frame:GetRect() return self.left, self.bottom, self.width, self.height end
	function frame:GetWidth() return self.width end
	function frame:GetHeight() return self.height end
	function frame:GetEffectiveScale() return self.ratio * 0.8 end
	function frame:GetPoint() return "CENTER", {}, "CENTER", 987, 654 end
	function frame:ClearAllPoints() end
	function frame:IsProtected() return false end
	function frame:GetAlpha() return 1 end
	function frame:IsShown() return true end
	function frame:SetClampedToScreen() end
	function frame:SetClampRectInsets(...) self.insets = { ... } end
	function frame:SetPoint(point, relative, relativePoint, x, y)
		if relative == env.UIParent then
			assert(point == "TOPLEFT")
			self.left = x
			self.bottom = y - self.height + (relativePoint == "TOPLEFT" and 900 / self.ratio or 0)
		else
			local left, bottom, width, height = BFL.WindowGeometry:GetRect(relative)
			self.left = (left + (relativePoint == "TOPRIGHT" and width or 0)) / self.ratio + x
			if point == "TOPRIGHT" then self.left = self.left - self.width end
			self.bottom = (bottom + height) / self.ratio + y - self.height
		end
	end
	return frame
end
for _, ratio in ipairs({ 0.5, 1, 1.5 }) do
	local window = Window(0, 0, 600 / ratio, 500 / ratio, ratio)
	local owner = Window(1100, 200, 400, 650)
	assert(geometry:Dock(window, owner, 30, 0))
	local x, y, w, h = geometry:GetRect(window)
	equal(x, 470, "right-edge owner uses available left side")
	equal(y + h, 850, "dock top uses screen coordinates")
	owner.left = 10
	geometry:Dock(window, owner, 30, 0)
	x = geometry:GetRect(window)
	equal(x, 440, "moving away from the edge restores right docking")
	local module = BFL.modules.FrameSettings
	module.db = { mainFramePosition = {} }
	BFL.MainFrame = window
	module:SavePosition()
	window.left, window.bottom = 0, 0
	module:ApplyPosition()
	local restoredX, restoredY = geometry:GetRect(window)
	equal(restoredX, x, "save captures screen position instead of a stale relative anchor")
	equal(restoredY, y, "saved top position survives reopening")
	module.db.useUIPanelSystem = true
	local position = module.db.mainFramePosition.Shared
	window.left = 123
	module:SavePosition()
	assert(module.db.mainFramePosition.Shared == position, "UIPanel overwrote the floating position")
	module:ApplyPosition()
	equal(window.left, 123, "UIPanel keeps ownership of its position")
end
local owner = Window(700, 10, 400, 400)
local window = Window(0, 0, 1000, 700)
geometry:Dock(window, owner, 20, 0)
local x, y = geometry:GetRect(window)
equal(x, 596, "a window without room on either side remains reachable")
equal(y, 4, "low docks are clamped above the screen bottom")
owner.left = 1150
window.width = 600
geometry:Dock(window, owner, 20, 0, 70)
x = geometry:GetRect(window)
equal(x, 480, "left-side tabs receive their own clearance")
for _, ratio in ipairs({ 0.5, 1, 1.5 }) do
	local panel = Window(0, 0, 300 / ratio, 450 / ratio, ratio)
	local anchor = Window(700, 200, 400, 600)
	geometry:Dock(panel, anchor, 20, 0, 70, "left")
	equal(geometry:GetRect(panel), 330, "left preference wins when both sides have space")
	anchor.left = 20
	geometry:Dock(panel, anchor, 20, 0, 70, "left")
	equal(geometry:GetRect(panel), 440, "left preference falls back right at the screen edge")
end
local module = BFL.modules.FrameSettings
do
	local previousMain, previousDB, previousUI = BFL.MainFrame, module.db, BFL.modules.FriendsUI
	for _, ratio in ipairs({ 0.5, 1, 1.5 }) do
		for _, railWidth in ipairs({ 30, 40, 64 }) do
			local main = Window(0, 100 / ratio, 400, 500, ratio)
			local side, protected, combat = "left", false, false
			function main:SetClampedToScreen() end
			function main:SetClampRectInsets(...) self.insets = { ... } end
			function main:AdjustPointsOffset(dx, dy)
				self.left, self.bottom = self.left + dx, self.bottom + dy
				self.offsets = (self.offsets or 0) + 1
			end
			function main:IsProtected() return protected end
			local tab = Window(0, 0, railWidth, 60, ratio)
			function tab:GetRect()
				return main.left + (side == "left" and -railWidth - 4 or main.width + 4),
					main.bottom + main.height - 200, self.width, self.height
			end
			BFL.MainFrame, module.db = main, { useUIPanelSystem = false }
			BFL.modules.FriendsUI = { sideTabs = { tab }, IsModernActive = function() return true end }
			env.InCombatLockdown = function() return combat end
			module:ApplyClamping()
			local left = geometry:GetRect(tab)
			equal(left, 0, "new left rail moves fully on screen immediately")
			local settled = main.left
			module:ApplyClamping()
			equal(main.left, settled, "repeated clamping does not make the window drift")
			side, main.left = "right", 1600 / ratio - main.width
			module:ApplyClamping()
			local tx, _, tw = geometry:GetRect(tab)
			equal(tx + tw, 1600, "new right rail moves fully on screen immediately")
			protected, combat, side, main.left = true, true, "left", 0
			local writes = main.offsets
			module:ApplyClamping()
			equal(main.offsets, writes, "protected layout is not adjusted in combat")
			combat = false
			module.db.useUIPanelSystem = true
			module:ApplyClamping()
			equal(geometry:GetRect(tab), 0, "UIPanel-owned anchors also keep their rail visible")
		end
	end
	local eager = Window(0, 100, 400, 500)
	local eagerTab = Window(0, 0, 64, 60)
	function eagerTab:GetRect() return eager.left - 68, eager.bottom + 300, self.width, self.height end
	function eager:SetClampRectInsets(leftInset) self.left = math.max(self.left, -leftInset) end
	function eager:AdjustPointsOffset() error("native clamping was applied a second time") end
	BFL.MainFrame, BFL.modules.FriendsUI = eager, { sideTabs={eagerTab}, IsModernActive=function() return true end }
	module:ApplyClamping()
	equal(eager.left, 68, "already-applied native clamping is not repeated")
	local legacy = Window(100, 0, 400, 500)
	local bottomTab = Window(0, 0, 100, 26)
	function bottomTab:GetRect() return legacy.left, legacy.bottom - 26, self.width, self.height end
	function legacy:AdjustPointsOffset(dx, dy) self.left, self.bottom = self.left + dx, self.bottom + dy end
	legacy.BottomTab1 = bottomTab
	BFL.MainFrame, BFL.modules.FriendsUI = legacy, { IsModernActive=function() return false end }
	module:ApplyClamping()
	local _, tabBottom = geometry:GetRect(bottomTab)
	equal(tabBottom, 0, "Legacy bottom tabs stay fully above the screen bottom")
	equal(legacy.left, 100, "Legacy clamping preserves a valid horizontal position")
	env.InCombatLockdown = function() return false end
	BFL.MainFrame, module.db, BFL.modules.FriendsUI = previousMain, previousDB, previousUI
end
module.db = { settingsWindowSize = { width = 1170, height = 800 } }
local settings = Window(0, 0, 1170, 800, 2)
settings.CategoryList = { SetWidth = function() end }
function settings:GetParent() return { GetEffectiveScale = function() return 1.6 end } end
function settings:SetScale(scale) self.ratio = 2 * scale end
function settings:SetSize(width, height) self.width, self.height = width, height end
function settings:SetResizeBounds(_, _, maxWidth, maxHeight) self.maxWidth, self.maxHeight = maxWidth, maxHeight end
module:FitSettingsWindow(settings)
assert(settings.width * settings.ratio <= 1576.001 and settings.height * settings.ratio <= 858.001,
	"Settings extends off screen at a larger inherited scale")
equal(module.db.settingsWindowSize.width, 1170, "fitting a smaller screen preserves the preferred size")
equal(settings.height, 520, "Settings retains its minimum usable height when scaled to fit")
do
	local previousMain, previousDB = BFL.MainFrame, module.db
	local liveMain = Window(0, 0, 400, 400)
	function liveMain:GetScale() return self.ratio end
	function liveMain:SetScale(value) self.ratio = value end
	local liveSettings = Window(0, 0, 1170, 800)
	liveSettings.CategoryList = { SetWidth = function() end }
	function liveSettings:GetParent() return liveMain end
	function liveSettings:SetScale(value) self.localScale = value end
	function liveSettings:GetEffectiveScale() return (self.localScale or 1) * liveMain:GetEffectiveScale() end
	function liveSettings:SetSize(width, height) self.width, self.height = width, height end
	function liveSettings:SetResizeBounds() end
	BFL.MainFrame = liveMain
	BFL.modules.LegacySettingsReview = { active = true, frame = liveSettings }
	local anchors = 0
	BFL.modules.Settings = { RefreshVisibleWindowAnchor = function() anchors = anchors + 1 end }
	for _, preferred in ipairs({ { width = 1170, height = 800 }, { width = 760, height = 620 } }) do
		module.db = { windowScale = 1, settingsWindowSize = { width = preferred.width, height = preferred.height } }
		liveMain:SetScale(1)
		module:FitSettingsWindow(liveSettings)
		for _, scale in ipairs({ 1.5, 0.75, 2, 1 }) do
			local previousAnchors = anchors
			module:ApplyScale(scale)
			local ratio = geometry:GetRatio(liveSettings)
			assert(liveSettings.width * ratio <= 1576.01 and liveSettings.height * ratio <= 858.01,
				"Changing BFL scale with Settings open leaves the window off screen")
			equal(anchors, previousAnchors + 1, "live scale changes refresh the settings anchor once")
			equal(preferred.width, module.db.settingsWindowSize.width, "fitting preserves the preferred width")
			equal(preferred.height, module.db.settingsWindowSize.height, "fitting preserves the preferred height")
		end
		equal(liveSettings.width, preferred.width, "returning to scale one restores the preferred width")
		equal(liveSettings.height, preferred.height, "returning to scale one restores the preferred height")
	end
	local previousAnchors = anchors
	env.InCombatLockdown = function() return true end
	function liveMain:IsProtected() return true end
	module:ApplyScale(1.5)
	equal(liveMain:GetScale(), 1, "protected scale changes wait until combat ends")
	equal(anchors, previousAnchors, "deferred changes do not resize or reanchor settings")
	assert(module.scaleRefreshAfterCombat, "The protected scale change was not queued")
	env.InCombatLockdown = function() return false end
	env.C_Timer = { After = function(_, callback) callback() end }
	module.db.useUIPanelSystem = true
	module:QueueScaleRefresh(true)
	equal(liveMain:GetScale(), 1.5, "queued scale changes apply after combat")
	equal(anchors, previousAnchors + 1, "queued scale changes fit and reanchor settings once")
	assert(not module.scaleRefreshAfterCombat, "The completed scale change is still marked pending")
	BFL.modules.LegacySettingsReview.active = false
	previousAnchors = anchors
	module:ApplyScale(1)
	equal(anchors, previousAnchors, "closed settings are not resized or reanchored")
	BFL.modules.LegacySettingsReview, BFL.modules.Settings = nil, nil
	BFL.MainFrame, module.db = previousMain, previousDB
end
local main = Window(100, 100, 400, 600)
local insets
function main:SetClampedToScreen(enabled) assert(enabled, "main frame lost screen clamping") end
function main:SetClampRectInsets(...) insets = { ... } end
local leftTab, rightTab = Window(60, 500, 40, 50), Window(500, 450, 35, 50)
function leftTab:IsShown() return true end
function rightTab:IsShown() return true end
BFL.MainFrame = main
BFL.modules.FriendsUI = { sideTabs = { leftTab, rightTab }, IsModernActive = function() return true end }
module:ApplyClamping()
equal(insets[1], -40, "the native clamp includes left-side tabs")
equal(insets[2], 35, "the native clamp includes right-side tabs")
leftTab.Background = Window(58, 497, 45, 60)
rightTab.Background = Window(499, 447, 39, 60)
rightTab.HighlightTexture = Window(400, 450, 200, 60)
function rightTab.HighlightTexture:GetAlpha() return 0 end
module:ApplyClamping()
equal(insets[1], -42, "clamping includes visible native tab artwork")
equal(insets[2], 38, "transparent theme artwork does not reserve extra space")
BFL.modules.FriendsUI.IsModernActive = function() return false end
module:ApplyClamping()
equal(insets[1], 0, "Legacy ignores the hidden Modern rail")
env.UIParent.GetWidth = function() return 8000 end
local wide = Window(0, 0, 800, 600, 0.5)
BFL.MainFrame = wide
module.db = { mainFramePosition = { Shared = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 12600, y = -30 } } }
module:ApplyPosition()
local wideX = geometry:GetRect(wide)
equal(wideX, 6300, "wide screens preserve valid offsets above 5000")
env.UIParent.GetWidth = function() return 1600 end
env.GetLocale = function() return "enUS" end
env._G = env
Load("Utils/FontManager.lua")
local fonts = {}
local database = {}
function database:Get(key, fallback) if fonts[key] ~= nil then return fonts[key] end; return fallback end
function database:Set(key, value) fonts[key] = value end
BFL.modules.DB = database
local function Font(path, size)
	return { GetFont = function() return path, size, "" end,
		SetFont = function(_, newPath, newSize) path, size = newPath, newSize; return true end,
		GetStringWidth = function() return size * 15 end, GetStringHeight = function() return size end }
end
local titleFont, actionFont = Font("native-title.ttf", 12), Font("native-action.ttf", 13)
local action = { width = 160, height = 30, GetFontString = function() return actionFont end }
function action:GetWidth() return self.width end
function action:GetHeight() return self.height end
function action:SetSize(width, height) self.width, self.height = width, height end
function action:HookScript(event, callback) self.scripts = self.scripts or {}; self.scripts[event] = callback end
env.BetterFriendsFrame = { TitleContainer = { TitleText = titleFont }, BottomActionBar = { AddFriendButton = action } }
BFL.FontManager:RefreshWindowFonts()
fonts.fontSizeWindowTitle, fonts.fontSizeActionButton = 18, 24
BFL.FontManager:RefreshWindowFonts()
local _, titleSize = titleFont:GetFont()
local _, actionSize = actionFont:GetFont()
equal(titleSize, 18, "window titles update independently")
equal(actionSize, 24, "the visible Modern action button receives its font option")
actionFont:SetFont("native-action.ttf", 13)
action.scripts.OnEnter()
_, actionSize = actionFont:GetFont()
equal(actionSize, 24, "hover retains the selected button font")
actionFont:SetFont("native-action.ttf", 13)
action.scripts.OnDisable()
_, actionSize = actionFont:GetFont()
equal(actionSize, 24, "disabled state retains the selected button font")
assert(action.width >= 384, "a larger action font clips in its original button width")
BFL.FontManager:ResetWindowFont("WindowTitle")
_, titleSize = titleFont:GetFont()
equal(titleSize, 12, "reset restores the title's actual native size")
_, actionSize = actionFont:GetFont()
equal(actionSize, 24, "resetting titles preserves action fonts")
BFL.FontManager:ResetWindowFont("ActionButton")
local actionPath
actionPath, actionSize = actionFont:GetFont()
assert(actionPath == "native-action.ttf", "reset replaced the button's native font face")
equal(actionSize, 13, "reset restores the button's distinct native size")
equal(action.width, 160, "reset restores the button's original geometry")
local combat, onRegen = true
env.InCombatLockdown = function() return combat end
function action:IsProtected() return true end
function BFL:RegisterEventCallback(event, callback)
	assert(event == "PLAYER_REGEN_ENABLED")
	onRegen = callback
end
fonts.fontSizeActionButton = 24
BFL.FontManager:RefreshWindowFonts()
equal(action.width, 160, "protected button layout remains untouched in combat")
assert(onRegen, "protected font layout has no recovery callback")
combat = false
onRegen()
equal(action.width, 384, "protected button layout recovers after combat")
combat = true
BFL.FontManager:ResetWindowFont("ActionButton")
equal(action.width, 384, "reset defers protected layout in combat")
combat = false
onRegen()
equal(action.width, 160, "reset retains native geometry until combat recovery")
actionFont:SetFont("theme-native.ttf", 15)
BFL.FontManager:RefreshWindowFonts()
_, actionSize = actionFont:GetFont()
equal(actionSize, 15, "default font settings leave external theme fonts in control")
do
	local owner = Window(40, 60, 400, 650, 1.15)
	BFL.MainFrame, env.BetterFriendsFrame = owner, owner
	local function SettingsWindow()
		local frame = Window(0, 0, 780, 600)
		frame.parent = owner
		frame.strata, frame.level = "HIGH", 3
		frame.CategoryList = { SetWidth = function() end }
		function frame:GetParent() return self.parent end
		function frame:SetParent(parent)
			self.parent = parent
			self.strata, self.level = "MEDIUM", 1
		end
		function frame:GetFrameStrata() return self.strata end
		function frame:SetFrameStrata(strata) self.strata = strata end
		function frame:GetFrameLevel() return self.level end
		function frame:SetFrameLevel(level) self.level = level end
		function frame:SetScale(scale) self.ratio = scale * self.parent:GetEffectiveScale() / env.UIParent:GetEffectiveScale() end
		function frame:SetSize(width, height) self.width, self.height = width, height end
		function frame:SetResizeBounds() end
		function frame:SetMovable(movable) self.movable = movable end
		return frame
	end
	local first = SettingsWindow()
	module.db = { settingsWindowDetached = true, settingsWindowSize = { width = 780, height = 600 } }
	BFL.modules.DB = { Set = function(_, key, value) module.db[key] = value end }
	assert(module:ApplySettingsWindowAttachment(first) and first:GetParent() == env.UIParent and first.movable,
		"Detaching makes Settings independently movable")
	assert(first:GetFrameStrata() == "HIGH", "Detaching loses the Settings strata")
	equal(first:GetFrameLevel(), 3, "Detaching loses the Settings frame level")
	geometry:SetTopLeft(first, 136, 811)
	module:SaveSettingsWindowPosition(first)
	local saved = module.db.settingsWindowPosition
	local reopened = SettingsWindow()
	owner.left = 1110
	assert(module:ApplySettingsWindowAttachment(reopened), "Saved attachment mode survives rebuilding the window")
	local x, y, _, height = geometry:GetRect(reopened)
	equal(x, 136, "A new Settings window restores its independent x coordinate")
	equal(y + height, 811, "A new Settings window restores its independent top coordinate")
	module.db.settingsWindowDetached = false
	assert(not module:ApplySettingsWindowAttachment(reopened) and reopened:GetParent() == owner and not reopened.movable,
		"Reattaching restores the friends list as parent")
	assert(reopened:GetFrameStrata() == "HIGH", "Reattaching loses the Settings strata")
	equal(reopened:GetFrameLevel(), 3, "Reattaching loses the Settings frame level")
	assert(module.db.settingsWindowPosition == saved, "Reattaching overwrites the last independent position")
end
io.write(string.format("PASS: window docking, position persistence and fonts (%d checks)\n", checks))
