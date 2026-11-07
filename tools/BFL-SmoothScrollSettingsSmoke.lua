-- lua tools/BFL-SmoothScrollSettingsSmoke.lua <repo>
-- Runs production settings routing for both settings surfaces; native motion is tested separately.
local repo = arg[1] or "."
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source:gsub("\r\n", "\n")
end
local function between(source, first, last)
	local start = assert(source:find(first, 1, true), first)
	return source:sub(start, assert(source:find(last, start + #first, true), last) - 1)
end
local profile, writes, applied = {}, 0, 0
local DB = { Get = function(_, key, fallback)
	local value = profile[key]; if value == nil then return fallback end; return value
end, Set = function(_, key, value) profile[key] = value; writes = writes + 1 end }
local Settings, control = {}, nil
local modules = { DB = DB, Settings = Settings, FriendsList = { ApplyScrollInterpolation = function()
	applied = applied + 1
end } }
local BFL = { IsMainline = true, GetModule = function(_, name) return modules[name] end }
local env = setmetatable({ BFL = BFL, Settings = Settings,
	GetDB = function() return DB end, GetDBModule = function() return DB end,
	L = { SETTINGS_SMOOTH_SCROLLING = "Smooth", SETTINGS_SMOOTH_SCROLLING_DESC = "Animated scrolling" },
	GetGroupTitle = function() return "interface" end,
	app = { RegisterControl = function(_, _, registered) control = registered end },
}, { __index = _G })
local settingsSource = read("Modules/Settings.lua")
assert(load(between(settingsSource, "function Settings:OnSmoothScrollingChanged(", "-- Callback for ShowBlizzardOption checkbox"),
	"@production smooth-scroll setting callback", "t", env))()
local designerSource = read("Modules/SettingsDesigner.lua")
local routing = between(designerSource, "local function SetDB(key, value, after)", "local function RefreshFriends()")
	.. between(designerSource, "local function AddToggle(pageID, data)", "local function AddDropdown(pageID, data)")
local registration
for line in designerSource:gmatch("[^\r\n]+") do
	if line:find('key = "enableSmoothScrolling"', 1, true) then registration = line; break end
end
assert(load(routing .. assert(registration), "@production settings-center scroll control", "t", env))()
check(control.default == false and control.visibleWhen(), "Mainline smooth scrolling is not an opt-in setting")
control.setValue(true)
check(profile.enableSmoothScrolling == true and writes == 1 and applied == 1, "enable does not persist and apply exactly once")
control.setValue(false)
check(profile.enableSmoothScrolling == false and writes == 2 and applied == 2, "disable does not immediately apply without a reload")
BFL.IsMainline = false
check(not control.visibleWhen(), "Classic exposes Mainline interpolation settings")
control.setValue(true)
check(profile.enableSmoothScrolling == false and writes == 2 and applied == 2, "Classic setting callback changed scroll state")
BFL.IsMainline = true

-- Actual legacy General-page checkbox and its shared callback.
local checkbox
env.tab, env.allFrames = {}, {}
env.Components = { CreateCheckbox = function(_, _, label, value, callback)
	checkbox = { label = label, value = value, callback = callback, SetTooltip = function() end }
	return checkbox
end }
local fragment = between(settingsSource, "\t\t\tlocal smoothScroll = Components:CreateCheckbox(", "\n\t\tend\n\t\ttable.insert(allFrames, Components:CreateSpacer(tab))")
env.self, env.DB = Settings, DB
assert(load(fragment, "@production legacy smooth-scroll checkbox", "t", env))()
check(checkbox.value == false, "legacy checkbox does not reflect the disabled default")
checkbox.callback(true)
check(profile.enableSmoothScrolling == true and writes == 3 and applied == 3, "legacy enable bypassed shared live setting")
checkbox.callback(false)
check(profile.enableSmoothScrolling == false and writes == 4 and applied == 4, "legacy disable bypassed shared live setting")
modules.FriendsList = nil
Settings:OnSmoothScrollingChanged(true)
check(profile.enableSmoothScrolling == true, "setting cannot be saved before the list is initialized")
io.write("[OK] Smooth-scroll settings smoke: " .. checks .. " checks (production callbacks)\n")
