-- lua tools/BFL-HelpFrameThemeSmoke.lua <repo>
-- Production Help/Settings style dispatch and external-window adapters.
local root, checks, theme = arg[1] or ".", 0, "blizzard"
local function Read(path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local text = file:read("*a"):gsub("\r\n", "\n"); file:close(); return text
end
local function Method(source, owner, name)
	local first = assert(source:find("function " .. owner .. ":" .. name .. "(", 1, true))
	local last = source:find("\nfunction ", first + 1, true) or (#source + 1)
	return source:sub(first, last - 1)
end
local function Check(value, message) checks = checks + 1; assert(value, message) end
local modules, frame = {}, nil
local BFL = {}
function BFL:RegisterModule(name, value) modules[name] = value; return value end
function BFL:GetModule(name) return modules[name] end
function BFL:GetEffectiveTheme() return theme end
assert(loadfile(root .. "/Modules/LegacySettingsStyle.lua"))("BetterFriendlist", BFL)
modules.SkinEngine = {
	IsActive = function() return theme == "dark" or theme == "custom" end,
	SkinFrame = function(_, target) target.styled = true end,
	ClearNativeBackdrop = function(_, target) target.Bg.alpha = 0 end,
	SkinScrollBar = function(_, target) target.styled = true end,
}
modules.DarkTheme = {
	SkinSettingsWindowChrome = function(_, _, target) target.skin = theme end,
	LayoutMainTitleButtons = function() end,
}
local eui = { IsSkinEnabled = function() return theme == "ellesmereui" end }
eui.facade = {
	Shell = function(target) target.skin = "ellesmereui" end,
	Inset = function(target) target.nativeInset = true; target.Bg.alpha = 0 end,
	Panel = function(target) target.panel = true end,
	CloseButton = function(target) target.styled = true end,
}
function eui:SkinScrollBar(target) target.styled = true end
local euiEnv = setmetatable({ EllesmereUISkin = eui, SafeCall = function(api, key, ...) return api[key](...) end }, { __index = _G })
assert(load(Method(Read("Modules/EllesmereUISkin.lua"), "EllesmereUISkin", "SkinSettingsWindow"), "@production EUI window", "t", euiEnv))()
modules.EllesmereUISkin = eui
local elv = {}
local elvEnv = setmetatable({
	ElvUISkin = elv, GetActiveSettingsSkin = function() return {} end,
	CallElvUIHandler = function(_, name, target)
		if name == "HandlePortraitFrame" then target.skin = "elvui" else target.styled = true end
	end,
	EnsureTransparentBackdrop = function(target) target.transparent = true end,
	SkinScrollBar = function(_, target) target.styled = true end,
}, { __index = _G })
assert(load(Method(Read("Modules/ElvUISkin.lua"), "ElvUISkin", "SkinSettingsWindow"), "@production ElvUI window", "t", elvEnv))()
modules.ElvUISkin = elv
local help = {}
local helpEnv = setmetatable({ HelpFrame = help, BFL = BFL }, { __index = _G })
assert(load(Method(Read("Modules/HelpFrame.lua"), "HelpFrame", "RefreshAppearance"), "@production Help appearance", "t", helpEnv))()
help:RefreshAppearance() -- A theme change must not create a closed help window.
for _, nextTheme in ipairs({ "blizzard", "dark", "custom", "elvui", "ellesmereui" }) do
	theme = nextTheme
	frame = { Inset = { Bg = { alpha = 1 } }, ScrollFrame = { ScrollBar = {} }, CloseButton = {} }
	function frame.Inset:StripTextures() self.Bg.alpha = 0 end
	helpEnv.helpFrame = frame
	help:RefreshAppearance()
	help:RefreshAppearance()
	if theme == "blizzard" then
		Check(frame.skin == nil and frame.Inset.Bg.alpha == 1, "Default help chrome changed")
	else
		Check(frame.skin == theme, "Help window did not use its selected theme: " .. theme)
		Check(frame.Inset.Bg.alpha == 0, "Native help inset covers the theme: " .. theme)
		Check(frame.ScrollFrame.ScrollBar.styled, "Help scrollbar skipped the adapter: " .. theme)
	end
	if theme == "ellesmereui" then
		Check(frame.Inset.nativeInset and not frame.Inset.panel, "EUI help uses a nested panel instead of clearing its native inset")
		local ownInset = {}
		eui:SkinSettingsWindow(frame, ownInset, frame.ScrollFrame)
		Check(ownInset.panel, "EUI lost the custom inset treatment used by other BFL dialogs")
	end
end
if arg[2] then
	local file = assert(io.open(arg[2] .. "/EllesmereUIBlizzardSkin_WindowEngine.lua", "rb"))
	local native = file:read("*a"):gsub("\r\n", "\n"); file:close()
	local first = assert(native:find("local function FadeTextures(", 1, true))
	local ending = assert(native:find("WSkin.FadeNineSlice = FadeNineSlice", first, true))
	local insetStart = assert(native:find("function WSkin.Inset(", ending, true))
	local insetEnd = assert(native:find("\nend", insetStart, true)) + 4
	local api = {}
	local nativeEnv = setmetatable({ WSkin=api, Register=function(target) target.registered=true end }, { __index=_G })
	assert(load(native:sub(first, ending - 1) .. native:sub(insetStart, insetEnd), "@actual EUI inset", "t", nativeEnv))()
	local function Texture()
		return { alpha=1, IsObjectType=function(_, kind) return kind == "Texture" end,
			SetAlpha=function(self, value) self.alpha=value end }
	end
	local inset, border, pieces = {}, { alpha=1 }, {}
	for _, key in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
		"TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }) do
		border[key] = Texture(); pieces[#pieces + 1] = border[key]
	end
	function border:IsForbidden() return false end
	function border:GetRegions() return table.unpack(pieces) end
	function border:SetAlpha(value) self.alpha=value end
	inset.Bg, inset.NineSlice = Texture(), border
	function inset:IsForbidden() return false end
	function inset:GetRegions() return self.Bg end
	theme, eui.facade.Inset = "ellesmereui", api.Inset
	frame = { Inset=inset, ScrollFrame={ScrollBar={}}, CloseButton={} }
	helpEnv.helpFrame = frame
	for _ = 1, 2 do
		inset.Bg.alpha, border.alpha = 1, 1
		for _, texture in ipairs(pieces) do texture.alpha=1 end
		help:RefreshAppearance()
		Check(inset.Bg.alpha == 0, "Actual EUI inset leaves Blizzard's background visible")
		Check(border.alpha == 0, "Actual EUI inset leaves the native border container visible")
		for _, texture in ipairs(pieces) do Check(texture.alpha == 0, "Actual EUI inset leaves a native border piece visible") end
		Check(inset.registered, "EUI does not retain its native inset restrip ownership")
	end
end
io.write("[OK] Help window theme dispatch and native inset handling: " .. checks .. " checks\n")
