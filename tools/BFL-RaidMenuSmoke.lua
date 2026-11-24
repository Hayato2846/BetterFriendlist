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
local unitNames, events = {}, {}
local secret = {}
local BFL = { HasSecretValues = true }
function BFL:IsSecret(value) return value == secret end
function BFL:GetModule() return nil end
function BFL:RegisterEventCallback(event, callback) events[event] = callback end
BFL.AreRegionalUniqueNamesEnabled = function() return false end
local env = setmetatable({
	BFL = BFL,
	RaidFrame = {},
	RAID_MEMBERS_TO_DISPLAY = 40,
	InCombatLockdown = function() return combat end,
	UnitExists = function(unit) return unit == "raid1" or unit == "raid2" end,
	GetRaidRosterInfo = function(index) return roster[index], 0, 1 end,
	UnitFullName = function(unit)
		local name = unitNames[unit]
		return name and name[1], name and name[2]
	end,
	UnitName = function() return "Unknown" end,
	IsInRaid = function() return true end,
	IsInGroup = function() return true end,
	GetNumGroupMembers = function() return #roster end,
	wipe = function(items) for key in pairs(items) do items[key] = nil end end,
	RegisterStateDriver = function() end,
	UnitPopup_OpenMenu = function(menu, context)
		delegatedMenu, delegatedUnit = menu, context.unit
	end,
}, { __index = _G })
env._G = env
local core = read(repo .. "/Core.lua")
assert(load(between(core, "function BFL:IsPendingRaidRosterName(", "-- Get a safe"), "@Core.lua", "t", env))()
local raidCode = read(repo .. "/Modules/RaidFrame.lua")
local code = between(raidCode, "local function IsPendingRaidRosterName(", "local function SafeSetFont(")
	.. between(raidCode, "local function GetUnitRosterName(", "-- CONSTANTS")
	.. between(raidCode, "local SORT_MODE_GROUP =", "-- Tab modes")
	.. between(raidCode, "function RaidFrame:RegisterEvents(", "-- ROSTER MANAGER")
	.. between(raidCode, "function RaidFrame:UpdateRaidMembers(", "-- MEMBER BUTTON MANAGEMENT")
	.. between(raidCode, "local RAID_SHORTCUT_MODIFIERS", "--- Apply configured shortcuts")
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

-- A name can arrive through the unit API before the raid roster catches up.
local refreshed = 0
raid.raidMembers = {}
function raid:OnRaidRosterUpdate()
	refreshed = refreshed + 1
	self:UpdateRaidMembers()
end
raid:RegisterEvents()
roster[2] = "Unknown"
raid:UpdateRaidMembers()
assert(raid.raidMembers[2].pendingName and raid.raidMembers[2].name == "Unknown")
local nameUpdate = assert(events.UNIT_NAME_UPDATE, "A name event alone must refresh the raid roster")
nameUpdate("target")
nameUpdate(secret)
assert(refreshed == 0, "Unrelated or restricted event tokens are ignored")
unitNames.raid2 = { secret, "OtherRealm" }
nameUpdate("raid2")
assert(raid.raidMembers[2].pendingName, "A restricted unit name cannot become an actionable raid name")
unitNames.raid2 = { "Grace", "OtherRealm" }
nameUpdate("raid2")
local resolved = raid.raidMembers[2]
assert(resolved.name == "Grace-OtherRealm" and not resolved.pendingName)
row.name, row.pendingName = resolved.name, resolved.pendingName
BFL.HasSecretValues = true
assert(raid:ShowSecureProxyForButton(row), "The menu can use the resolved unit even while the raid roster says Unknown")
assert(attributes.type2 == "togglemenu" and attributes.clickbutton2 == nil, "A stale Blizzard button is never clicked")
unitNames.raid2 = { "New member", "OtherRealm" }
assert(not raid:ShowSecureProxyForButton(row), "A change of unit identity invalidates the old row")
unitNames.raid2 = { "Grace", "OtherRealm" }
roster[2], env.RaidGroupButton2.name = resolved.name, resolved.name
assert(raid:ShowSecureProxyForButton(row) and attributes.clickbutton2 == env.RaidGroupButton2)

local getRosterInfo = env.GetRaidRosterInfo
env.GetRaidRosterInfo = function(index)
	if index == 1 then return "Ada", 2, 2, 80, "Mage", "MAGE" end
end
raid.displayList = {}
nameUpdate("raid2")
resolved = raid.raidMembers[2]
assert(resolved and resolved.name == "Grace-OtherRealm" and not resolved.pendingName,
	"A nil roster entry can resolve from a readable unit name")
for sortMode = 1, 4 do
	raid.sortMode = sortMode
	raid:BuildDisplayList()
	assert(#raid.displayList == 2, "Sorting tolerates a member whose roster metadata is still missing")
end
unitNames.raid2 = { "Grace", secret }
nameUpdate("raid2")
assert(#raid.raidMembers == 1, "A nil roster slot with no readable full name is skipped")
env.GetRaidRosterInfo = getRosterInfo

env.IsInRaid = function() return false end
env.GetNumSubgroupMembers = function() return 1 end
env.UnitExists = function(unit) return unit == "party1" or unit == "player" end
env.UnitLevel = function() return 80 end
env.UnitClass = function() return "Mage", "MAGE" end
env.UnitGroupRolesAssigned = function() return "DAMAGER" end
env.UnitIsGroupLeader = function() return false end
env.GetRealZoneText = function() return "Zone" end
env.UnitIsConnected = function() return true end
env.UnitIsDead = function() return false end
local names = { player = secret, party1 = secret }
env.UnitName = function(unit) return names[unit] end
unitNames.party1 = { secret, "OtherRealm" }
nameUpdate("party1")
for _, member in ipairs(raid.raidMembers) do
	assert(member.pendingName and member.name == "Unknown", "Secret party names become safe placeholders")
end
raid.sortMode = 1
raid:BuildDisplayList()
assert(#raid.displayList == 2, "Pending party names are safe to sort")
names.player = "Ada"
unitNames.party1 = { "Grace", "OtherRealm" }
nameUpdate("party1")
assert(raid.raidMembers[1].name == "Ada" and not raid.raidMembers[1].pendingName)
assert(raid.raidMembers[2].name == "Grace-OtherRealm" and not raid.raidMembers[2].pendingName,
	"A pending party name recovers when the unit name is readable")
names.party1 = "Grace"
nameUpdate("party1")
assert(raid.raidMembers[2].name == "Grace", "Readable party names keep their existing format")
local callbacks = read(repo .. "/UI/RaidFrameCallbacks.lua")
assert(load(between(callbacks, "function BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(",
	"function BetterRaidFrame_EveryoneAssistCheckbox_OnClick("), "@UI/RaidFrameCallbacks.lua", "t", env))()
local windowShown, raidShown, controlUpdates, now = false, true, 0, 10
env.BetterFriendsFrame = {
	IsShown = function() return windowShown end,
	RaidFrame = { IsShown = function() return raidShown end },
}
env.GetTime = function() return now end
env.BetterRaidFrame_UpdateControlPanelButtons = function() controlUpdates = controlUpdates + 1 end
local checkbox = {}
env.BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(checkbox)
assert(controlUpdates == 0, "Roster events skip the raid panel while the main window is closed")
windowShown, raidShown = true, false
env.BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(checkbox)
assert(controlUpdates == 0, "Roster events skip the hidden Raid tab")
raidShown = true
env.BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(checkbox)
assert(controlUpdates == 1, "Roster events still refresh a visible Raid tab")
checkbox.clickCooldown = now
env.BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(checkbox)
assert(controlUpdates == 1, "Visible Raid tab still waits for the server after a checkbox click")
now = now + 1
env.BetterRaidFrame_EveryoneAssistCheckbox_OnEvent(checkbox)
assert(controlUpdates == 2, "Visible Raid tab resumes updates after the click cooldown")

env.GetRaidFrame = function() return raid end
env.IsInRaid = function() return true end
env.IsInStoryModeRaid = function() return false end
env.IsInGroup = env.IsInRaid
BFL.L = {}
BFL.IsSocialActionRestricted = function() return false end
BFL.IsRaidListEnabled = function() return true end
local raidReads, rowUpdates, layoutUpdates, buttonUpdates = 0, 0, 0, 0
env.GetNumGroupMembers = function() raidReads = raidReads + 1; return 10 end
env.GetNumSavedRaidLockouts = function() raidReads = raidReads + 1; return 1 end
raid.UpdateAllMemberButtons = function() rowUpdates = rowUpdates + 1 end
raid.UpdateControlPanelLayout = function() layoutUpdates = layoutUpdates + 1 end
raid.CanControlRaid = function() return true end
local button = {
	Enable = function() buttonUpdates = buttonUpdates + 1 end,
	Disable = function() buttonUpdates = buttonUpdates + 1 end,
	SetText = function() end,
}
env.BetterFriendsFrame.RaidFrame.ControlPanel = { RaidInfoButton = button }
env.BetterFriendsFrame.RaidFrame.ConvertToRaidButton = button
assert(load("local L = BFL.L\n" .. between(raidCode, "local function IsRaidFrameVisible()", "function RaidFrame:ShouldDisplayMainTankAndAssist()")
	.. between(raidCode, "function RaidFrame:UpdateConvertButton()", "--- Handle Convert Button Click"), "@raid convert update", "t", env))()
assert(load(between(callbacks, "function BetterRaidFrame_Update()", "-- Update Control Panel Buttons"), "@legacy raid update", "t", env))()
assert(load(between(callbacks, "function BetterRaidFrame_UpdateRaidInfoButton()", "-- RAID MEMBER BUTTON CALLBACKS"), "@raid info update", "t", env))()
for _, visibility in ipairs({ { false, true }, { true, false }, { true, true } }) do
	windowShown, raidShown = table.unpack(visibility)
	env.BetterRaidFrame_Update()
	env.BetterRaidFrame_UpdateRaidInfoButton()
	events.PLAYER_REGEN_ENABLED()
	if not (windowShown and raidShown) then
		assert(raidReads == 0 and rowUpdates == 0 and layoutUpdates == 0 and buttonUpdates == 0,
			"Legacy raid events and combat transitions do no work for hidden windows")
	end
end
assert(raidReads == 3 and rowUpdates == 1 and layoutUpdates == 1 and buttonUpdates == 2,
	"Visible Raid updates its list, layout, lockout and convert controls")
io.write("[OK] Native raid menu, roster names, protected combat, and control panel visibility\n")
