-- Actual FriendsUI docking, including preference, live reflow and protected/mover ownership.
local root = arg[1] or "."
local file = assert(io.open(root .. "/Modules/FriendsUI.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n"); file:close()
local checks, combat, side = 0, false, "left"
local BFL, FriendsUI = {}, {}
function BFL:GetModule() return nil end
local env = setmetatable({ FriendsUI = FriendsUI, BFL = BFL }, { __index = _G })
local function Equal(actual, expected, message)
	checks = checks + 1
	assert(math.abs(actual - expected) < .001, message .. ": " .. tostring(actual))
end
env.InCombatLockdown = function() return combat end
env.UIParent = { GetEffectiveScale = function() return .8 end, GetSize = function() return 1600, 900 end,
	GetWidth = function() return 1600 end, GetHeight = function() return 900 end }
assert(loadfile(root .. "/Utils/WindowGeometry.lua", "t", env))("BetterFriendlist", BFL)
local geometry = BFL.WindowGeometry
local function Window(left, bottom, width, height, ratio)
	local window = { left=left, bottom=bottom, width=width, height=height, ratio=ratio or 1, scripts={} }
	function window:GetRect() return self.left, self.bottom, self.width, self.height end
	function window:GetEffectiveScale() return self.ratio * .8 end
	function window:GetWidth() return self.width end
	function window:GetHeight() return self.height end
	function window:GetSize() return self.width, self.height end
	function window:IsShown() return self.shown ~= false end
	function window:IsProtected() return self.protected == true end
	function window:HookScript(event, callback) self.scripts[event] = callback end
	function window:ClearAllPoints() assert(not (combat and self.protected), "protected anchor cleared in combat") end
	function window:SetPoint(point, relative, relativePoint, x, y)
		assert(not (combat and self.protected), "protected anchor set in combat")
		self.writes = (self.writes or 0) + 1
		self.moverAtWrite = self.mover and self.mover.isApplying
		if relative == env.UIParent then
			self.left, self.bottom = x, y - self.height
		else
			local rx, ry, rw, rh = geometry:GetRect(relative)
			self.left = (rx + (relativePoint:find("RIGHT") and rw or 0)) / self.ratio + x
			if point:find("RIGHT") then self.left = self.left - self.width end
			self.bottom = (ry + rh) / self.ratio + y - self.height
		end
	end
	return window
end
function FriendsUI:GetSideTabPosition() return side end
function FriendsUI:IsModernActive() return true end
function FriendsUI:HasVisibleModernSideTabs() return true end
function FriendsUI:GetRaidInfoMoverRuntimeState(window) return window.mover end
for _, name in ipairs({ "GetAuxiliaryWindowOffset", "AnchorAuxiliaryWindow", "RefreshAuxiliaryWindowAnchors" }) do
	local start = source:find("function FriendsUI:" .. name .. "(", 1, true)
	if start then
		local finish = source:find("\nfunction ", start + 1, true) or #source + 1
		assert(load(source:sub(start, finish - 1), name, "t", env))()
	end
end
for _, ratio in ipairs({ .5, 1, 1.5 }) do
	local owner = Window(650, 200, 400, 600)
	local panel = Window(0, 0, 300 / ratio, 400 / ratio, ratio)
	env.BetterFriendsFrame = owner
	side = "left"
	assert(FriendsUI:AnchorAuxiliaryWindow(panel, 0))
	Equal(geometry:GetRect(panel), 282, "all auxiliary windows prefer the configured left rail")
	owner.left = 0
	assert(panel.scripts.OnUpdate, "auxiliary windows have no live docking refresh")
	panel.scripts.OnUpdate()
	Equal(geometry:GetRect(panel), 405, "moving to the left edge reflows the open window right")
	owner.left = 650
	side = "right"
	panel.scripts.OnUpdate()
	Equal(geometry:GetRect(panel), 1118, "changing the rail side reflows an open window")
	side = "left"
	if FriendsUI.RefreshAuxiliaryWindowAnchors then FriendsUI:RefreshAuxiliaryWindowAnchors() end
	Equal(geometry:GetRect(panel), 282, "a side change can refresh visible docked windows immediately")
	panel.protected, combat = true, true
	local writes = panel.writes
	owner.left = 0
	panel.scripts.OnUpdate()
	Equal(panel.writes, writes, "live docking preserves protected frames in combat")
	combat = false
	panel.scripts.OnUpdate()
	Equal(geometry:GetRect(panel), 405, "protected docking resumes after combat")
	panel.protected = false
	panel.mover = { isApplying = false }
	owner.left = 650
	FriendsUI:AnchorAuxiliaryWindow(panel, 0)
	assert(panel.moverAtWrite == true and panel.mover.isApplying == false,
		"screen-aware docking lost the scoped RaidInfo mover re-entry guard")
	checks = checks + 1
end
io.write(string.format("PASS: auxiliary window side preference and live docking (%d checks)\n", checks))
