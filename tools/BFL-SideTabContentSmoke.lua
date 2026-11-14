-- lua tools/BFL-SideTabContentSmoke.lua <repo>
-- Exercise the production icon painter after skins hide/re-layer its regions.
local root = arg[1] or "."
local file = assert(io.open(root .. "/Modules/FriendsUI.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n"); file:close()
local first = assert(source:find("local function ApplySectionIcon(", 1, true))
local last = assert(source:find("\nend", first, true)) + 4
local checks, theme, enabled = 0, "blizzard", true
local palette = { accent = { .2, .7, .4 }, control = { 1, 1, 1 } }
local env = setmetatable({
	FriendsUI = { GetModernThemeColors = function() return palette, theme ~= "blizzard" and theme ~= "elvui" end },
	MODERN_BLIZZARD_THEME_COLORS = palette,
	CUSTOM_TAB_ICON_ACTIVE_COLOR = { 1, .8, 0 }, CUSTOM_TAB_ICON_INACTIVE_COLOR = { .7, .6, 0 },
	ApplyAtlasTexture = function(texture, atlas) texture.atlas = atlas; texture.shown = false end,
}, { __index = _G })
local paint = assert(load(source:sub(first, last) .. "\nreturn ApplySectionIcon", "@production tab painter", "t", env))()
for _, nextTheme in ipairs({ "blizzard", "dark", "custom", "elvui", "ellesmereui" }) do
	theme = nextTheme
	for _, custom in ipairs({ false, true }) do
		for _, nextEnabled in ipairs({ false, true }) do
			enabled = nextEnabled
			local texture = { shown = false, alpha = 0, layer = "BACKGROUND" }
			function texture:SetTexture(value) self.texture = value; self.shown = false end
			function texture:SetSize(w, h) self.width, self.height = w, h end
			function texture:SetTexCoord(...) self.coords = { ... } end
			function texture:SetDesaturated(value) self.desaturated = value end
			function texture:SetVertexColor(...) self.color = { ... } end
			function texture:SetAlpha(value) self.alpha = value end
			function texture:SetDrawLayer(layer, level) self.layer, self.level = layer, level end
			function texture:Show() self.shown = true end
			local definition = { customTexture = custom and "BFL-icon", activeAtlas = "active", inactiveAtlas = "inactive",
				tab = { Icon = texture, IsEnabled = function() return enabled end } }
			paint(texture, definition, true)
			assert(texture.shown, theme .. ": skin-hidden tab icon was not shown")
			assert(texture.layer == "OVERLAY" and texture.level >= 4, theme .. ": mirrored shell can cover the icon")
			assert(texture.alpha == (enabled and 1 or .5), theme .. ": disabled state was lost")
			assert(custom and texture.texture == "BFL-icon" or not custom and texture.atlas == "active", theme .. ": section art changed")
			checks = checks + 4
		end
	end
end
io.write("[OK] Side-tab content restoration across five themes: " .. checks .. " checks\n")
