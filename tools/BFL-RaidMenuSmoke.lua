-- Lua 5.4: lua tools/BFL-RaidMenuSmoke.lua <repo> <Retail UI source>
-- Tests BFL's route and Blizzard's menu handler with mocked frames and roster.
local repo, retail = assert(arg[1]), assert(arg[2])

local function read(path)
	local file = assert(io.open(path, "rb"))
	local text = file:read("*a")
	file:close()
	return text
end

local function between(text, start, finish)
	local first = assert(text:find(start, 1, true))
	local last = assert(text:find(finish, first + #start, true))
	return text:sub(first, last - 1)
end

local combat, delegatedMenu, delegatedUnit = false
local roster = { "Ada", "Grace" }
local BFL = { HasSecretValues = true }
function BFL:IsSecret() return false end
function BFL:GetModule() return nil end
local env = setmetatable({
	BFL = BFL,
	RaidFrame = {},
	RAID_MEMBERS_TO_DISPLAY = 40,
	InCombatLockdown = function() return combat end,
	UnitExists = function(unit) return unit == "raid1" or unit == "raid2" end,
	GetRaidRosterInfo = function(index) return roster[index] end,
	IsPendingRaidRosterName = function(name) return not name or name == "" end,
	RegisterStateDriver = function() end,
	UnitPopup_OpenMenu = function(menu, context)
		delegatedMenu, delegatedUnit = menu, context.unit
	end,
}, { __index = _G })
env._G = env
local raidCode = read(repo .. "/Modules/RaidFrame.lua")
local code = between(raidCode, "local RAID_SHORTCUT_MODIFIERS", "--- Apply configured shortcuts")
	.. between(raidCode, "function RaidFrame:HideSecureProxy()", "function RaidFrame:ResolveMemberButton(")
assert(load(code, "@Modules/RaidFrame.lua", "t", env))()

local native = read(retail .. "/Interface/AddOns/Blizzard_RaidUI/Mainline/Blizzard_RaidUI.lua")
assert(load(between(native, "function RaidGroupButton_OpenMenu(", "function RaidGroupButton_OnLoad("),
	"@Blizzard_RaidUI.lua", "t", env))()
local function nativeButton(index, name)
	return {
		id = index,
		unit = "raid" .. index,
		name = name,
		Click = function(self, button)
			assert(button == "RightButton")
			env.RaidGroupButton_OpenMenu(self)
		end,
	}
end

local attributes = {}
local proxy = {
	SetAttribute = function(_, key, value) assert(not combat); attributes[key] = value end,
	Show = function(self) assert(not combat); self.shown = true end,
	Hide = function(self) assert(not combat); self.shown = false end,
	ClearAllPoints = function() assert(not combat) end,
}
local raid = env.RaidFrame
raid.SecureProxy = proxy
function raid:CreateSecureProxy() return proxy end
function raid:PositionSecureProxyForButton() return true end

local loadCount = 0
env.C_AddOns = { LoadAddOn = function(addon)
	assert(addon == "Blizzard_RaidUI")
	loadCount = loadCount + 1
	env.RaidGroupButton1 = nativeButton(1)
	env.RaidGroupButton2 = nativeButton(2)
end }
local row = { unit = "raid2", name = "Grace", groupIndex = 5, slotIndex = 1, memberData = {} }
assert(raid:ShowSecureProxyForButton(row))
assert(loadCount == 1 and proxy.shown)
assert(attributes.type2 == "togglemenu" and attributes.clickbutton2 == nil, "A cold roster can be unnamed")
env.RaidGroupButton1.name = "Ada"
env.RaidGroupButton2.name = "Grace"
assert(raid:ShowSecureProxyForButton(row))
assert(attributes.type2 == "click" and attributes.clickbutton2 == env.RaidGroupButton2)
assert(attributes.unit == "raid2" and proxy.BFL_RaidContextMenuType == "RAID")
attributes.clickbutton2:Click("RightButton")
assert(delegatedMenu == "RAID" and delegatedUnit == "raid2")

-- Classic can use the same native delegate. A missing or stale Blizzard
-- button leaves Classic's visual fallback and Retail's secure proxy fallback.
BFL.HasSecretValues = false
assert(raid:ShowSecureProxyForButton(row) and attributes.clickbutton2 == env.RaidGroupButton2)
raid:HideSecureProxy()
assert(not proxy.shown and attributes.clickbutton2 == nil and proxy.visualButton == nil)
env.RaidGroupButton2.name = "Stale"
assert(not raid:ShowSecureProxyForButton(row))
BFL.HasSecretValues = true
assert(raid:ShowSecureProxyForButton(row))
assert(attributes.type2 == "togglemenu" and attributes.clickbutton2 == nil)
assert(proxy.BFL_RaidContextMenuType == "RAID_PLAYER")

env.RaidGroupButton2.name = "Grace"
env.RaidGroupButton2.HasAccessConstraints = function() return true end
assert(raid:ShowSecureProxyForButton(row) and attributes.type2 == "togglemenu")
env.RaidGroupButton2.HasAccessConstraints = nil

raid:HideSecureProxy()
roster[2] = "New member"
assert(not raid:ShowSecureProxyForButton(row))
roster[2] = "Grace"
row.memberData._isMock = true
assert(not raid:ShowSecureProxyForButton(row))
row.memberData._isMock = nil
combat = true
assert(not raid:ShowSecureProxyForButton(row))
raid:HideSecureProxy()
combat = false

local visual = { SetAttribute = proxy.SetAttribute }
raid:ApplyMemberContextMenuAttributes(visual)
assert(attributes.type2 == nil)
BFL.HasSecretValues = false
raid:ApplyMemberContextMenuAttributes(visual)
assert(attributes.type2 == "togglemenu")
io.write("[OK] Native raid menu delegate, roster identity, protected combat guard, and flavor fallbacks\n")
