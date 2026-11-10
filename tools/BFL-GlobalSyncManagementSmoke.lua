-- lua tools/BFL-GlobalSyncManagementSmoke.lua <repo>
-- Real local database actions, settings callbacks and availability transitions; mocked widgets/APIs.
local repo = arg[1] or "."
local checks, mutations = 0, 0
local function check(value, message)
	checks = checks + 1; assert(value, message)
end
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source
end
local modules, widgets, titleEnabled, legacyEnabled = {}, {}, false, true
local secret = {}
local BFL = { L = {}, IsMainline = true }
BFL.Modules = modules
function BFL:GetModule(name) return modules[name] end
function BFL:IsSecret(value) return value == secret end
function BFL:RegisterLocale() end
BFL.AreRegionalUniqueNamesEnabled = function() return true end
local rosterReads = 0
BFL.GetNumWoWFriends = function() rosterReads = rosterReads + 1; return 0 end
BFL.CanUseWoWFriendList = function() return legacyEnabled end
BFL.DebugPrint = function() end
local function nativeMutation() mutations = mutations + 1; error("unexpected native friend mutation") end
BFL.AddFriend, BFL.RemoveFriend, BFL.SetFriendNotes = nativeMutation, nativeMutation, nativeMutation
local env = setmetatable({
	BFL = BFL, InCombatLockdown = function() return false end,
	C_BattleNet = { AreTitleFriendsEnabled = function() return titleEnabled end },
	BNGetNumFriends = function() return 0 end,
	GetNormalizedRealmName = function() return "Realm" end,
	UnitNameUnmodified = function() return "MyCharacter" end,
	time = function() return 100 end,
}, { __index = _G })
assert(loadfile(repo .. "/Modules/GlobalSync.lua", "t", env))("BetterFriendlist", BFL)
local sync = modules.GlobalSync
local function reset()
	widgets = {}
	titleEnabled, legacyEnabled = false, true
	local active, deleted = { notes = "private saved note", lastSeen = 10 }, { notes = "old note", deleted = true }
	local otherFaction = { notes = "keep this faction" }
	env.BetterFriendlistDB = { enableGlobalSync = true, enableGlobalSyncDeletion = true, globalFriendsMigrated = true,
		GlobalFriends = { Alliance = { ["Retail-Realm"] = active, ["Old-Realm"] = deleted },
			Horde = { ["Retail-Realm"] = otherFaction } }, knownCharacters = { localCharacter = {} } }
	return active, deleted, otherFaction
end

local active, deleted = reset()
local graph, characters = env.BetterFriendlistDB.GlobalFriends, env.BetterFriendlistDB.knownCharacters
local events, shows, hooks = {}, 0, 0
BFL.RegisterEventCallback = function(_, event, callback, _, gate)
	events[event] = { callback = callback, gate = gate }
end
BFL.ShowFriends = function() shows = shows + 1 end
env.C_FriendList = { AddFriend = nativeMutation }
env.hooksecurefunc = function() hooks = hooks + 1 end
env.GetRealmName = function() return "Realm" end
env.UnitFactionGroup = function() return "Alliance" end
local function ownedTimer(callback)
	local value = { callback = callback }
	function value:Cancel() self.cancelled = true end
	return value
end
env.C_Timer = {
	NewTicker = function(_, callback) return ownedTimer(callback) end,
	NewTimer = function(_, callback) return ownedTimer(callback) end,
}

titleEnabled = true
sync:Initialize()
check(not sync:IsAvailable() and not events.FRIENDLIST_UPDATE and shows == 0 and hooks == 0,
	"Title Friends startup installed hooks or requested the legacy roster")
sync:OnFriendListUpdate()
sync:PerformSync()
sync:ExportFriends("Alliance", "Realm")
sync:OnFriendNoteUpdated("Retail-Realm", "changed note")
sync:OnFriendRemoved("Retail-Realm")
sync:DeleteStoredFriend("Alliance", "Retail-Realm")
sync:SetStoredFriendNote("Alliance", "Retail-Realm", "changed note")
check(not sync:RestoreStoredFriend("Alliance", "Retail-Realm") and sync:ClearStoredEntries() == 0
	and not sync.updateTimer and rosterReads == 0 and mutations == 0
	and graph.Alliance["Retail-Realm"] == active and active.notes == "private saved note" and not active.deleted,
	"Title Friends mode scheduled work, read the roster, or changed stored entries")

titleEnabled, legacyEnabled = false, false
check(not sync:IsAvailable(), "The legacy roster must also be enabled")
titleEnabled, legacyEnabled = secret, true
check(not sync:IsAvailable(), "An unreadable Title Friends flag enabled sync")
titleEnabled = false
events.LEGACY_FRIEND_SYSTEM_STATUS_UPDATED.callback()
check(sync:IsAvailable() and events.FRIENDLIST_UPDATE.gate.active and shows == 1 and hooks == 1,
	"Legacy sync did not initialize after the mode changed")
sync:ProcessAddQueue({ { key = "Retail-Realm", name = "Retail-Realm", faction = "Alliance" } })
local disabledUpdate, disabledAdd = assert(sync.updateTimer), assert(sync.addQueueTicker)
titleEnabled = true
events.GAME_RULES_CHANGED.callback()
check(disabledUpdate.cancelled and disabledAdd.cancelled and not events.FRIENDLIST_UPDATE.gate.active,
	"Queued legacy work survived switching to Title Friends")
disabledUpdate.callback()
disabledAdd.callback(disabledAdd)
check(rosterReads == 0 and mutations == 0, "A stale callback ran legacy work in Title Friends mode")
titleEnabled = false
events.LEGACY_FRIEND_SYSTEM_STATUS_UPDATED.callback()
check(sync:IsAvailable() and events.FRIENDLIST_UPDATE.gate.active and shows == 2 and hooks == 1,
	"Returning to legacy mode did not resume sync or duplicated native hooks")
sync:CancelSync()
sync:DeleteStoredFriend("Alliance", "Retail-Realm")
check(active.deleted and mutations == 0, "Legacy Delete Friend did not keep the sync tombstone")

-- Bulk removal preserves the shared graph, counts tombstones and cancels only
-- addon-owned work. Even a stale cancelled callback cannot use a refilled DB.
active, deleted = reset()
graph = env.BetterFriendlistDB.GlobalFriends
local alliance, horde = graph.Alliance, graph.Horde
local contacts, backup = { contacts = { private = { privateNote = "keep contact" } } }, { private = { originalNote = "keep backup" } }
env.BetterFriendlistDB.contactMemory, env.BetterFriendlistDB.noteBackup = contacts, backup
characters = env.BetterFriendlistDB.knownCharacters
sync.pendingRestores, sync.attemptedAdds = { [active] = true }, { ["Retail-Realm"] = {} }
local restoreRefs, attemptRefs = sync.pendingRestores, sync.attemptedAdds
local titleRecord = { titleFaction = "Alliance", ruleset = "PVE", notes = "preserved" }
alliance["Former-Title"] = titleRecord
titleEnabled = false
sync:ProcessAddQueue({ { key = "Retail-Realm", name = "Retail-Realm", faction = "Alliance" } })
sync:OnFriendListUpdate()
local queuedAdd, queuedUpdate = sync.addQueueTicker, sync.updateTimer
sync.pendingIndexRemoval, sync.deletionSnapshot, sync.syncDeferred = {}, {}, true
check(sync:GetStoredEntryCount() == 3, "entry count excluded tombstones or another faction")
check(sync:ClearStoredEntries() == 3, "bulk removal returned the wrong number of deleted entries")
check(env.BetterFriendlistDB.GlobalFriends == graph and graph.Alliance == alliance and graph.Horde == horde
	and alliance["Former-Title"] == titleRecord and next(alliance) == "Former-Title" and not next(horde), "bulk removal replaced shared graph/faction references or left records")
check(not next(restoreRefs) and not next(attemptRefs), "bulk removal retained addon retry references")
check(queuedAdd.cancelled and queuedUpdate.cancelled and not sync.addQueueTicker and not sync.updateTimer and not sync.processingQueue,
	"bulk removal retained a running add/update timer")
check(not sync.pendingIndexRemoval and not sync.deletionSnapshot and not sync.syncDeferred,
	"bulk removal retained deferred deletion state")
check(env.BetterFriendlistDB.contactMemory == contacts and env.BetterFriendlistDB.noteBackup == backup
	and env.BetterFriendlistDB.knownCharacters == characters, "bulk removal changed private contact data or note backups")
check(env.BetterFriendlistDB.enableGlobalSync and env.BetterFriendlistDB.enableGlobalSyncDeletion,
	"bulk removal changed Global Sync options")
alliance["Retail-Realm"] = active
queuedAdd.callback(queuedAdd)
local originalPerform, deferredRuns = sync.PerformSync, 0
sync.PerformSync = function() deferredRuns = deferredRuns + 1 end
queuedUpdate.callback()
sync.PerformSync = originalPerform
check(mutations == 0 and deferredRuns == 0, "cancelled work acted on a newly refilled database")
check(sync:ClearStoredEntries() == 1 and sync:ClearStoredEntries() == 0 and sync:GetStoredEntryCount() == 0,
	"bulk removal was not safe on an empty database")
titleEnabled = secret
alliance["Unreadable-Client"] = { notes = "local-only cleanup" }
check(sync:ClearStoredEntries() == 0 and alliance["Unreadable-Client"], "unreadable flags allowed local changes")
titleEnabled = false
env.BetterFriendlistDB.GlobalFriends = nil
check(sync:GetStoredEntryCount() == 0 and sync:ClearStoredEntries() == 0, "missing database was not treated as empty")
local sharedFaction = { shared = { notes = "shared saved entry" } }
env.BetterFriendlistDB.GlobalFriends = { Alliance = sharedFaction, Horde = sharedFaction }
check(sync:GetStoredEntryCount() == 2 and sync:ClearStoredEntries() == 2 and not next(sharedFaction),
	"shared faction tables changed the counted result or retained entries")

-- Minimal addon-owned widgets capture actual callback wiring and anchor parameters.
local widgetMethods = {}
function widgetMethods:SetScript(event, callback) self.scripts[event] = callback end
function widgetMethods:HookScript(event, callback) self.hooks[event] = callback end
function widgetMethods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function widgetMethods:ClearAllPoints() self.points = {} end
function widgetMethods:SetAllPoints(target) self.allPoints = target end
function widgetMethods:SetSize(width, height) self.width, self.height = width, height end
function widgetMethods:SetHeight(height) self.height = height end
function widgetMethods:SetText(text) self.text = text end
function widgetMethods:GetParent() return self.parent end
function widgetMethods:GetTop() return self.top end
function widgetMethods:GetBottom() return self.bottom end
function widgetMethods:GetEffectiveScale() return self.scale or (self.parent and self.parent:GetEffectiveScale()) or 1 end
function widgetMethods:IsShown() return self.shown end
function widgetMethods:IsVisible() return self.shown end
function widgetMethods:IsEnabled() return self.enabled ~= false end
function widgetMethods:SetShown(shown) self.shown = shown end
function widgetMethods:SetEnabled(enabled) self.enabled = enabled end
function widgetMethods:Show() self.shown = true end
function widgetMethods:Hide()
	local wasShown = self.shown; self.shown = false
	if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
local function widget(kind, parent, template)
	local value = { kind = kind, parent = parent, template = template, scripts = {}, hooks = {}, points = {}, shown = true }
	setmetatable(value, { __index = function(_, key)
		if widgetMethods[key] then return widgetMethods[key] end
		if key:match("^Set") or key == "EnableMouse" then return function() end end
		return nil
	end })
	widgets[#widgets + 1] = value; return value
end
function widgetMethods:CreateTexture() return widget("Texture", self) end
function widgetMethods:CreateFontString() return widget("FontString", self) end
function widgetMethods:SetIcon(path) self.Icon.texture = path end
function widgetMethods:GetHighlightTexture()
	self.highlight = self.highlight or self:CreateTexture()
	return self.highlight
end
env.IconButtonMixin = {
	OnMouseDown = function(self) self.Icon:SetPoint("CENTER", self, "CENTER", 1, -1) end,
	OnMouseUp = function(self) self.Icon:SetPoint("CENTER", self, "CENTER") end,
}
env.CreateFrame = function(kind, _, parent, template)
	local frame = widget(kind, parent, template)
	if template == "CommonSquareIconButtonTemplate" then
		frame.Icon = frame:CreateTexture()
		frame.Icon:SetPoint("CENTER", frame, "CENTER")
	end
	return frame
end
env.BFL_Tooltip = { SetOwner = function() end, SetText = function(_, text) env.tooltipText = text end,
	AddLine = function(_, text) env.tooltipDesc = text end, Show = function() end, Hide = function() end }
local Settings, host = {}, widget("Frame")
function Settings:GetGlobalSyncTabHost() return host end
local DB = { Get = function(_, key, fallback)
	local value = env.BetterFriendlistDB[key]; if value == nil then return fallback end; return value
end, Set = function(_, key, value) env.BetterFriendlistDB[key] = value end }
local Components = {}
for _, method in ipairs({ "CreateHeader", "CreateLabel", "CreateCheckbox", "CreateSpacer" }) do
	Components[method] = function(_, parent) return widget("Control", parent) end
end
function Components:AnchorChain() end
function Components:CreateCheckbox(parent, label, checked, onChange)
	local control = widget("Control", parent)
	control.text, control.checked, control.onChange = label, checked, onChange
	return control
end
env.Settings, env.Components, env.L, env.BFL_LOCALE_ENUS = Settings, Components, BFL.L, BFL.L
env.GetDB = function() return DB end
env.NotifyLegacyReviewTabBuilt = function() end
env.HideComponentList = function(tab)
	for _, frame in ipairs(tab.components or {}) do frame:Hide() end
end
assert(loadfile(repo .. "/Locales/enUS.lua", "t", env))("BetterFriendlist", BFL)
local componentSource = read("Modules/SettingsComponents.lua")
local templateFirst = assert(componentSource:find("function Components:GetActionButtonTemplate(", 1, true))
local templateLast = assert(componentSource:find("local function ResizeActionButton(", templateFirst, true))
assert(load(componentSource:sub(templateFirst, templateLast - 1), "@production settings button template", "t", env))()
local componentFirst = assert(componentSource:find("function Components:CreateButton(parent, text, onClick, tooltip)", 1, true))
local componentLast = assert(componentSource:find("-- DOUBLE CHECKBOX ROW", componentFirst, true))
env.FIELD_WIDTH = 180
assert(load(componentSource:sub(componentFirst, componentLast - 1), "@production settings button", "t", env))()
local settingsSource = read("Modules/Settings.lua")
local availabilityFirst = assert(settingsSource:find("local function IsTabAvailableForClient(", 1, true))
local availabilityLast = assert(settingsSource:find("function Settings:ShowLegacyReview()", availabilityFirst, true))
env.TAB_DEFINITIONS = { { id = 1 }, { id = 6 } }
assert(load(settingsSource:sub(availabilityFirst, availabilityLast - 1), "@production settings availability", "t", env))()
reset()
check(Settings:GetLegacyTabAvailability(6), "legacy friend list must expose Global Sync")
titleEnabled = true
local visible, reason = Settings:GetLegacyTabAvailability(6)
check(not visible and reason == "client", "Title Friends must hide Global Sync")
check(Settings:GetLegacyTabAvailability(1), "Title Friends must leave other settings accessible")
titleEnabled, legacyEnabled = false, false
check(not Settings:GetLegacyTabAvailability(6), "unavailable native friend list must hide Global Sync")
local first = assert(settingsSource:find("function Settings:ShowGlobalSyncDeleteAllConfirmation()", 1, true))
local last = assert(settingsSource:find("-- Refresh Streamer Mode Tab", first, true))
env.StaticPopupDialogs = {}
local shownPopup
env.StaticPopup_Show = function(name) shownPopup = name end
assert(load(settingsSource:sub(first, last - 1), "@production Global Sync settings", "t", env))()
local function rowButtons()
	local rows = {}
	for _, value in ipairs(widgets) do
		if value.kind == "Button" and value.template == "CommonSquareIconButtonTemplate" and value.parent.parent == host then
			rows[#rows + 1] = value
		end
	end
	return rows
end
reset(); Settings.showDeletedFriends = true
Settings:RefreshGlobalSyncTab()
local actions = rowButtons()
local hasDelete, hasRestore
for _, action in ipairs(actions) do
	hasDelete = hasDelete or action.Icon.texture:match("\\x%.blp$")
	hasRestore = hasRestore or action.Icon.texture:match("\\rotate%-ccw%.blp$")
	action.scripts.OnMouseDown(action)
	action.scripts.OnMouseUp(action)
	local anchor = action.Icon.points[#action.Icon.points]
	check(anchor[1] == "CENTER" and anchor[2] == action and anchor[3] == "CENTER"
		and (anchor[4] or 0) == 0 and (anchor[5] or 0) == 0, "Action icon must return to center on mouse release")
end
check(#actions == 3 and hasDelete and hasRestore, "Global Sync should show both delete and restore actions")

local function deleteAllButton()
	for index = #widgets, 1, -1 do
		local value = widgets[index]
		if value.parent == host and value.text == BFL.L.BUTTON_DELETE_ALL then return value end
	end
	error("Delete All button missing")
end
-- Exercise the actual always-visible button and BFL confirmation callbacks.
reset(); titleEnabled = false; env.BetterFriendlistDB.enableGlobalSync = false
Settings:RefreshGlobalSyncTab()
local bulkButton, beforeClear = deleteAllButton(), env.BetterFriendlistDB.GlobalFriends
check(bulkButton:IsShown() and bulkButton:IsEnabled(), "Delete All requires enabled legacy sync or Title Friends")
bulkButton.scripts.OnClick(bulkButton)
local dialog = assert(env.StaticPopupDialogs.BFL_GLOBAL_SYNC_DELETE_ALL)
check(shownPopup == "BFL_GLOBAL_SYNC_DELETE_ALL" and dialog.text == BFL.L.GLOBAL_SYNC_DELETE_ALL_CONFIRM
	and dialog.button1 == BFL.L.BUTTON_DELETE_ALL and dialog.button2 == BFL.L.BUTTON_CANCEL,
	"Delete All did not use the localized BFL confirmation")
check(env.BetterFriendlistDB.GlobalFriends == beforeClear and sync:GetStoredEntryCount() == 3,
	"opening Delete All confirmation deleted saved entries")
if dialog.OnCancel then dialog.OnCancel() end
check(sync:GetStoredEntryCount() == 3 and mutations == 0, "cancelled confirmation changed the database or Blizzard friends")
local staleAccept = dialog.OnAccept
env.BetterFriendlistDB.GlobalFriends = { Alliance = { Imported = { notes = "keep newer profile" } }, Horde = {} }
staleAccept()
check(sync:GetStoredEntryCount() == 1, "stale confirmation deleted a newly imported database")
Settings:RefreshGlobalSyncTab(); bulkButton = deleteAllButton(); bulkButton.scripts.OnClick(bulkButton)
dialog = env.StaticPopupDialogs.BFL_GLOBAL_SYNC_DELETE_ALL
dialog.OnAccept()
check(sync:GetStoredEntryCount() == 0 and not deleteAllButton():IsEnabled() and mutations == 0,
	"accepted confirmation did not clear locally and disable its empty-state button")
shownPopup = nil
Settings:ShowGlobalSyncDeleteAllConfirmation()
check(shownPopup == nil, "empty database opened a destructive confirmation")
reset(); Settings:RefreshGlobalSyncTab(); bulkButton = deleteAllButton()
bulkButton.scripts.OnClick(bulkButton)
local disabledAccept = assert(env.StaticPopupDialogs.BFL_GLOBAL_SYNC_DELETE_ALL.OnAccept)
titleEnabled = true
disabledAccept()
check(sync:GetStoredEntryCount() == 3 and not bulkButton:IsShown(), "Disabling legacy mode allowed an open dialog to clear the database")
shownPopup = nil
Settings:ShowGlobalSyncDeleteAllConfirmation()
check(shownPopup == nil, "Title Friends exposed the legacy clear dialog")
io.write("[OK] Global Sync management smoke: " .. checks .. " checks (production callbacks, mocked engine)\n")
