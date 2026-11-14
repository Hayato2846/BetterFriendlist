-- Measure the production badge with Blizzard's actual menu compositor on six clients.
local root, references = assert(arg[1]), assert(arg[2])
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a"):gsub("\r\n", "\n"); file:close()
	return source
end
local BFL = {}
function BFL:RegisterModule(_, module) self.badge = module; return module end
local label, owner
local env = setmetatable({
	GameFontHighlight = { GetFont = function() return "Fonts/test.ttf", 12, "" end },
	GameFontNormal_NoShadow = { GetFont = function() return "Fonts/test.ttf", 12, "" end },
	CreateFrame = function() error("A pooled menu must not receive persistent BFL children") end,
	MenuTemplates = { AttachNewFeatureFrame = function(button)
		check(button == owner, "badge attached to another row")
		return label
	end },
}, { __index = _G })
assert(loadfile(root .. "/Modules/NewFeatureBadge.lua", "t", env))("BetterFriendlist", BFL)
local onLoad = assert(read(root .. "/UI/NewFeatureBadge.xml"):match('<OnLoad inherit="append">(.-)</OnLoad>'))
local initializeLabel = assert(load(onLoad, "BFL menu label OnLoad", "t", env))
for _, flavor in ipairs({ "live", "forever", "classic", "classic_ptr", "classic_era", "classic_anniversary" }) do
	local source = read(references .. "/wow-ui-source-" .. flavor .. "/Interface/AddOns/Blizzard_Menu/Menu.lua")
	local implementation = assert(source:match("(local function MeasureExtents%(regions%).-\nend)"), flavor .. ": native menu measurement missing")
	local measure = assert(load(implementation .. "\nreturn MeasureExtents", flavor, "t", { math = math, ipairs = ipairs }))()
	for _, menuScale in ipairs({ .5, .8, 1, 1.5 }) do
		for _, position in ipairs({ { 50, 80 }, { 400, 400 }, { 1000, 850 } }) do
			for _, textWidth in ipairs({ 50, 210 }) do
				local x, y = position[1], position[2]
				local text = { GetRect = function() return x, y, textWidth, 16 end }
				owner = { fontString = text }
				-- Native GetRect returns coordinates in each region's effective scale.
				-- Seed a reused pooled attachment with the old independent scale.
				label = { scale = .8 }
				local function fontString()
					return { SetFont = function(self, _, size) self.fontSize = size end }
				end
				label.Label, label.BGLabel = fontString(), fontString()
				function owner:AttachTemplate(template)
					check(template == "BFLNewFeatureLabelMenuTemplate", "small lettering leaks into the shared Blizzard pool")
					env.self = label
					initializeLabel()
					return label
				end
				function label:SetScale(value) self.scale = value end
				function label:EnableMouse(value) self.mouse = value end
				function label:ClearAllPoints() self.anchor = nil end
				function label:GetTextWidth() return 24 end
				function label:SetPoint(point, relative, relativePoint, dx, dy)
					self.anchor = { point, relative, relativePoint, dx, dy }
				end
				function label:GetRect()
					local effective = menuScale * self.scale
					local cx = (x + textWidth) * menuScale + self.anchor[4] * effective
					local cy = (y + 8) * menuScale + self.anchor[5] * effective
					return cx / effective - 20, cy / effective - 10, 40, 20
				end
				local description = { AddInitializer = function(self, callback) self.initialize = callback end }
				BFL.badge:AttachToMenu(description)
				description.initialize(owner)
				description.initialize(owner)
				check(math.abs(label.Label.fontSize - 9.6) < .001 and label.Label.fontSize == label.BGLabel.fontSize, "pooled badge lettering shrinks repeatedly or its shadow differs")
				local width, height = measure({ text, label })
				check(height == 20, flavor .. ": scaled New label inflates row at y=" .. y .. " to " .. height)
				check(width > textWidth and width < textWidth + 64, flavor .. ": badge inflates menu width")
				check(label.mouse == false and not label.BFL_DarkManagedSubtree, "pooled label received input or BFL skin state")
			end
		end
	end
end
io.write(string.format("PASS: native menu badge bounds across six clients, positions, scales and long labels (%d checks)\n", checks))
