-- Lua 5.4: lua tools/BFL-NoteSyncSettingsSmoke.lua <repo>
-- Runs real SettingsDesigner toggle dispatch and the shared Settings callback.
local repo = arg[1] or "."
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local text = file:read("*a"); file:close(); return text:gsub("\r\n", "\n")
end
local function between(text, first, last)
	local start = assert(text:find(first, 1, true), first)
	return text:sub(start, assert(text:find(last, start + #first, true), last) - 1)
end
local checks, calls, refreshes, wizardShows = 0, {}, 0, 0
local function equal(actual, expected, message)
	checks = checks + 1; assert(actual == expected, message)
end
local profile, Settings, dialogs, shown, control = { syncGroupsToNote = false }, {}, {}, nil, nil
local NoteSync = { SetEnabled = function(self, value)
	calls[#calls + 1] = value
	if value then self:CancelWork(); profile.syncGroupsToNote = true
	else self:Disable() end
end }
local modules = { Settings = Settings, NoteSync = NoteSync,
	SettingsDesigner = { RefreshNoteSyncState = function() refreshes = refreshes + 1 end } }
function Settings:RefreshAdvancedTab() refreshes = refreshes + 1 end
local BFL = { GetModule = function(_, name) return modules[name] end }
local DB = { Set = function(_, key, value) profile[key] = value end }
modules.DB = DB
BFL.NoteCleanupWizard = { Show = function() wizardShows = wizardShows + 1 end }
local env = setmetatable({ BFL = BFL, Settings = Settings, NoteSync = NoteSync, L = {}, StaticPopupDialogs = dialogs,
	StaticPopup_Show = function(name) shown = name end,
	GetDBModule = function() return DB end,
	GetGroupTitle = function() return "notes" end,
	T = function(_, fallback) return fallback end,
	app = { RegisterControl = function(_, _, data) control = data end },
}, { __index = _G })
local syncSource = read("Modules/NoteSync.lua")
local lifecycle = between(syncSource, "function NoteSync:CancelWork()", "function NoteSync:ResetPendingWrites()")
	.. between(syncSource, "function NoteSync:Disable()", "function NoteSync:Enable(")
assert(load(lifecycle, "@production note-sync disable lifecycle", "t", env))()
local settings = read("Modules/Settings.lua")
assert(load(between(settings, "function Settings:InvalidatePendingNoteSyncConfirmation()", "-- Refresh Advanced Tab"),
	"@production shared note-sync setting", "t", env))()
local designer = read("Modules/SettingsDesigner.lua")
local source = between(designer, "local function SetDB(key, value, after)", "local function RefreshFriends()")
	.. between(designer, "local function AddToggle(pageID, data)", "local function AddDropdown(pageID, data)")
local registration
for line in designer:gmatch("[^\r\n]+") do
	if line:find('key = "syncGroupsToNote"', 1, true) then registration = line; break end
end
assert(load(source .. assert(registration), "@production SettingsDesigner toggle", "t", env))()
control.setValue(true)
equal(#calls, 0, "The settings-center toggle cannot write notes before confirmation")
equal(profile.syncGroupsToNote, false, "The setting is unchanged while confirmation is pending")
equal(shown, "BETTERFRIENDLIST_SYNC_GROUPS_CONFIRM", "Both surfaces show the existing enable confirmation")
dialogs[shown].OnCancel()
equal(#calls, 0, "Cancel never starts sync")
control.setValue(true)
dialogs[shown].OnAccept()
equal(#calls, 1, "Accept calls the shared import-before-write lifecycle exactly once")
equal(calls[1], true, "Accept enables via NoteSync SetEnabled")
equal(profile.syncGroupsToNote, true, "Accepted enable updates the backing setting")
equal(refreshes, 4, "Cancel and accept each refresh both settings surfaces")
control.setValue(false)
equal(#calls, 2, "Disabling uses the cancellation lifecycle")
equal(calls[2], false, "Disable passes false to NoteSync")
equal(profile.syncGroupsToNote, false, "Disabled state is stored before cleanup is offered")
equal(shown, "BETTERFRIENDLIST_SYNC_GROUPS_DISABLE", "Cleanup is offered only after disabling")
dialogs[shown].OnAccept()
equal(wizardShows, 1, "Cleanup still opens after the real Disable increments the work version")
local legacyAnchor = settings:find("local syncNoteToggle = Components:CreateCheckbox(", 1, true)
local legacySource = between(settings:sub(legacyAnchor), "\t\tfunction(checked)", "\n\t)\n\tsyncNoteToggle:SetTooltip(")
local legacyCallback = assert(load("return " .. legacySource, "@production legacy toggle", "t", env))()
legacyCallback(true)
equal(#calls, 2, "Legacy toggle also waits for confirmation")
dialogs[shown].OnAccept()
equal(#calls, 3, "Legacy accept uses the same NoteSync lifecycle")
control.setValue(true)
local staleEnable = dialogs[shown].OnAccept
control.setValue(false)
local afterDisable = #calls
staleEnable()
equal(#calls, afterDisable, "An obsolete enable confirmation cannot override a later disable")
equal(profile.syncGroupsToNote, false, "The latest disabled choice stays authoritative")
control.setValue(true)
local beforeImport = dialogs[shown].OnAccept
Settings:InvalidatePendingNoteSyncConfirmation()
beforeImport()
equal(#calls, afterDisable, "A committed import invalidates old enable confirmations")
control.setValue(true)
local beforeWorkReset = dialogs[shown].OnAccept
NoteSync.workVersion = (NoteSync.workVersion or 0) + 1
beforeWorkReset()
equal(#calls, afterDisable, "Resetting sync work also invalidates old confirmations")
io.write("[OK] Note sync settings smoke: " .. checks .. " checks passed\n")
