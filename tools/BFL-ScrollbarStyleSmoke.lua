local root = arg[1] or "."
local references = (arg[2] or "C:/Users/hofer/Documents/BFL/references"):gsub("[/\\]+$", "") .. "/"
local checks, modules, theme = 0, {}, "custom"
local colors = { custom = { .1, .8, .65 }, dark = { .9, .7, .2 }, ellesmereui = { .2, .6, .9 } }
local BFL = {}
function BFL:RegisterModule(name, value) modules[name] = value; return value end
function BFL:GetModule(name) return modules[name] end
function BFL:GetEffectiveTheme() return theme end
function BFL:GetThemeAccentColor() return table.unpack(colors[theme] or { 1, .82, 0 }) end
modules.ElvUISkin = { ElvUIEngine = { media = { rgbvaluecolor = { .75, .15, .45 } } } }
function CreateFromMixins(...)
	local result = {}
	for _, mixin in ipairs({ ... }) do for key, value in pairs(mixin) do result[key] = value end end
	return result
end
function hooksecurefunc(owner, method, callback)
	local original = owner[method]
	owner[method] = function(...) original(...); callback(...) end
end
TextureKitConstants = { UseAtlasSize = true }
ScrollBarMixin = { OnLoad = function() end }
UIParent = {}
local function check(value, message) checks = checks + 1; assert(value, message) end
local function texture(parent)
	local t = { color = { 1, 1, 1, .8 }, desaturated = false, parent = parent, writes = 0 }
	function t:GetParent() return self.parent end
	function t:IsProtected() return self.protected or false end
	function t:IsForbidden() return self.forbidden or false end
	function t:CanBeAccessedInContext() return self.access ~= false end
	function t:GetVertexColor() return table.unpack(self.color) end
	function t:SetVertexColor(...) assert(not self.protected and not self.forbidden and self.access ~= false); self.writes = self.writes + 1; self.color = { ... } end
	function t:IsDesaturated() return self.desaturated end
	function t:SetDesaturated(value) self.desaturated = value end
	t.SetAtlas = function(self, atlas) self.atlas = atlas end
	function t:SetShown(value) self.shown = value end
	function t:AdjustPointsOffset() end
	function t:ClearPointsOffset() end
	return t
end
local function widget(mixin, parent)
	local w = CreateFromMixins(mixin or {})
	w.enabled, w.hooks = true, {}
	w.parent = parent or UIParent
	function w:GetParent() assert(not self.protected and not self.forbidden and self.access ~= false); return self.parent end
	function w:SetParent(value) self.parent = value end
	function w:IsProtected() return self.protected or false end
	function w:IsForbidden() return self.forbidden or false end
	function w:CanBeAccessedInContext() return self.access ~= false end
	function w:HasScript(event) return event == "OnShow" or type(self[event]) == "function" end
	function w:HookScript(event, callback)
		assert(self:HasScript(event), "unsupported native frame script: " .. event)
		self.hooks[event] = self.hooks[event] or {}
		table.insert(self.hooks[event], callback)
	end
	function w:IsEnabled() return self.enabled end
	function w:DesaturateHierarchy(value)
		for _, key in ipairs({ "Texture", "Begin", "Middle", "End", "Overlay" }) do
			if self[key] then self[key]:SetDesaturated(value == 1) end
		end
	end
	function w:SetEnabled(enabled)
		if self.enabled == enabled then return end
		self.enabled = enabled
		local event = enabled and "OnEnable" or "OnDisable"
		if self[event] then self[event](self) end
		for _, callback in ipairs(self.hooks[event] or {}) do callback(self) end
	end
	return w
end
assert(loadfile(root .. "/Modules/ScrollbarStyle.lua"))("BetterFriendlist", BFL)
local style = modules.ScrollbarStyle
local function matches(t, c)
	return math.abs(t.color[1] - c[1]) < .0001 and math.abs(t.color[2] - c[2]) < .0001
		and math.abs(t.color[3] - c[3]) < .0001
end
for _, flavor in ipairs({ "live", "forever", "classic", "classic_ptr", "classic_era", "classic_anniversary" }) do
	local path = references .. "wow-ui-source-" .. flavor .. "/Interface/AddOns/"
	assert(loadfile(path .. "Blizzard_SharedXMLBase/ButtonStateBehavior.lua"))()
	assert(loadfile(path .. "Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.lua"))()
	assert(loadfile(path .. "Blizzard_SharedXML/Shared/Scroll/TrimScrollBar.lua"))()
	for _, trim in ipairs({ false, true }) do
		local owner = widget()
		local back = widget(trim and WowTrimScrollBarStepperMixin or MinimalScrollBarStepperScriptsMixin)
		back.Texture, back.Overlay = texture(back), texture(back)
		back.normalTexture, back.upTexture, back.downTexture, back.overTexture, back.disabledTexture = "up", "up", "down", "hover", "disabled"
		back:OnLoad()
		back.Texture:SetVertexColor(.7, .4, .2, .8)
		local forward = widget(trim and WowTrimScrollBarStepperMixin or MinimalScrollBarStepperScriptsMixin)
		forward.Texture, forward.Overlay = texture(forward), texture(forward)
		forward.normalTexture, forward.upTexture, forward.downTexture, forward.overTexture, forward.disabledTexture = "up", "up", "down", "hover", "disabled"
		forward:OnLoad()
		forward:OnButtonStateChanged()
		local thumb = widget(trim and WowScrollBarThumbScriptsMixin or MinimalScrollBarThumbScriptsMixin)
		thumb.Begin, thumb.Middle, thumb.End = texture(thumb), texture(thumb), texture(thumb)
		for _, state in ipairs({ "up", "over", "down", "disabled" }) do
			for _, part in ipairs({ "Begin", "Middle", "End" }) do thumb[state .. part .. "Texture"] = state .. part end
		end
		thumb:OnLoad()
		local bar = widget(nil, owner)
		bar.Track, bar.Back, bar.Forward = widget(), back, forward
		bar.Track.Begin, bar.Track.Middle, bar.Track.End, bar.Track.Thumb = texture(bar.Track), texture(bar.Track), texture(bar.Track), thumb
		bar.Track.parent, back.parent, forward.parent, thumb.parent = bar, bar, bar, bar.Track
		function bar:GetThumb() return self.Track.Thumb end
		back:SetEnabled(false)
		theme = "custom"
		check(not style:Apply(bar) and not next(bar.hooks), "an unregistered scrollbar acquired hooks")
		for _, flag in ipairs({ "protected", "forbidden", "access" }) do
			bar[flag] = flag ~= "access"
			check(not style:Register(bar, owner) and not next(bar.hooks), "unsafe scrollbar registered: " .. flag)
			bar[flag] = nil
		end
		owner.protected = true
		check(not style:Register(bar, owner), "protected owner registered")
		owner.protected = false
		FriendsFriendsFrame = owner
		check(not style:Register(bar, owner), "shared FriendsFriendsFrame registered")
		FriendsFriendsFrame, StaticPopup1 = nil, owner
		check(not style:Register(bar, owner), "shared popup registered")
		StaticPopup1 = nil
		owner.GetOwnerRegion, owner.SetMenuDescription = function() end, function() end
		check(not style:Register(bar, owner), "pooled menu proxy registered")
		owner.GetOwnerRegion, owner.SetMenuDescription = nil, nil
		check(style:Register(bar, owner), "BFL-created scrollbar registration was rejected")
		check(matches(thumb.Middle, colors.custom) and matches(forward.Texture, colors.custom), "active scrollbar did not receive Custom accent")
		check(matches(back.Texture, { 1, 1, 1 }) and back.Texture.desaturated, "disabled Back received the accent")
		check(thumb.Middle.atlas == "upMiddle" and forward.Texture.atlas == "up", "native scrollbar artwork was replaced")
		back:SetEnabled(true)
		check(matches(back.Texture, colors.custom) and back.Texture.desaturated, "native OnEnable cleared the accent desaturation")
		back:OnEnter(); back:OnMouseDown(); back:OnMouseUp(); back:OnLeave()
		check(matches(back.Texture, colors.custom), "hover or press lost the accent")
		forward:SetEnabled(false)
		check(matches(forward.Texture, { 1, 1, 1 }) and forward.Texture.desaturated, "scrolling to the end left Forward accented")
		for _, nextTheme in ipairs({ "dark", "ellesmereui", "elvui" }) do
			theme = nextTheme
			style:Refresh()
			local expected = colors[theme] or modules.ElvUISkin.ElvUIEngine.media.rgbvaluecolor
			check(matches(thumb.Middle, expected) and matches(back.Texture, expected), "external theme or Dark uses the wrong accent")
			check(matches(forward.Texture, { 1, 1, 1 }), "theme change accented a disabled arrow")
		end
		theme = "blizzard"
		style:Refresh()
		check(matches(thumb.Middle, { 1, 1, 1 }) and not thumb.Middle.desaturated, "Blizzard thumb was not restored")
		check(matches(back.Texture, { .7, .4, .2 }) and not back.Texture.desaturated, "Blizzard arrow did not recover its original tint and enabled desaturation")
		for _ = 1, 5 do style:Apply(bar) end
		check(#back.hooks.OnEnable == 1, "reapplication duplicated state hooks")
		check(not style:Apply({}), "a legacy scrollbar was treated as modern")
		theme = "custom"
		style:Apply(bar)
		local writes = thumb.Middle.writes
		bar.access = false
		style:Apply(bar); style:RefreshWidget(thumb)
		check(thumb.Middle.writes == writes, "context-denied callback wrote to a scrollbar")
		bar.access, owner.protected = true, true
		style:Apply(bar); style:RefreshWidget(thumb)
		check(thumb.Middle.writes == writes, "protected ancestor was ignored")
		owner.protected = false
		style:Apply(bar)
		check(thumb.Middle.writes > writes, "access recovery lost the BFL registration")
		thumb.Middle.protected = true
		writes = thumb.Middle.writes
		style:RefreshWidget(thumb)
		check(thumb.Middle.writes == writes, "protected texture was modified")
		thumb.Middle.protected = false
		bar:SetParent(widget())
		check(not style.bars[bar] and matches(thumb.Middle, { 1, 1, 1 }), "ownership loss did not retire and clean up the scrollbar")
		thumb.Middle:SetVertexColor(.3, .4, .5, .8)
		writes = thumb.Middle.writes
		style:Refresh(); style:RefreshWidget(thumb)
		check(thumb.Middle.writes == writes and matches(thumb.Middle, { .3, .4, .5 }), "retired callbacks recolored a foreign owner")
		check(not style:Register(bar, owner), "a retired instance was silently re-registered")
	end
end
io.write("PASS: native scrollbar accents, disabled arrows and restoration across six source flavors (" .. checks .. " checks)\n")
