-- lua tools/BFL-GlobalSyncManagementSmoke.lua <repo>
-- Real local database actions, settings callbacks and popup anchors; mocked widgets/APIs.
local repo = arg[1] or "."
local checks, mutations = 0, 0
local function check(value, message)
	checks = checks + 1; assert(value, message)
end
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source
end
local modules, widgets, titleEnabled = {}, {}, true
local secret = {}
local BFL = { L = {}, IsMainline = true }
BFL.Modules = modules
function BFL:GetModule(name) return modules[name] end
function BFL:IsSecret(value) return value == secret end
function BFL:RegisterLocale() end
BFL.AreRegionalUniqueNamesEnabled = function() return true end
BFL.GetNumWoWFriends = function() return 0 end
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
	titleEnabled = true
	local active, deleted = { notes = "private saved note", lastSeen = 10 }, { notes = "old note", deleted = true }
	local otherFaction = { notes = "keep this faction" }
	env.BetterFriendlistDB = { enableGlobalSync = true, enableGlobalSyncDeletion = true,
		GlobalFriends = { Alliance = { ["Retail-Realm"] = active, ["Old-Realm"] = deleted },
			Horde = { ["Retail-Realm"] = otherFaction } }, knownCharacters = { localCharacter = {} } }
	return active, deleted, otherFaction
end

local active, deleted, otherFaction = reset()
local graph, characters = env.BetterFriendlistDB.GlobalFriends, env.BetterFriendlistDB.knownCharacters
sync.pendingRestores, sync.attemptedAdds = { [active] = true }, { ["Retail-Realm"] = {} }
check(sync:RemoveStoredEntry("Alliance", "Retail-Realm"), "Title Friends cannot remove a saved legacy entry")
check(graph.Alliance["Retail-Realm"] == nil and graph.Alliance["Old-Realm"] == deleted,
	"removing a record removed the wrong same-faction data")
check(graph.Horde["Retail-Realm"] == otherFaction and env.BetterFriendlistDB.knownCharacters == characters,
	"removing a record changed another faction or local character data")
check(not sync.pendingRestores[active] and not sync.attemptedAdds["Retail-Realm"], "removed entry retained local retry state")
check(env.BetterFriendlistDB.enableGlobalSync and env.BetterFriendlistDB.enableGlobalSyncDeletion, "removal changed sync options")
check(sync:RemoveStoredEntry("Alliance", "Old-Realm") and not next(graph.Alliance), "deleted historical record could not be purged")
check(not sync:RemoveStoredEntry("Alliance", "missing"), "missing record reported as removed")
check(not sync:RemoveStoredEntry(secret, "missing") and not sync:RemoveStoredEntry("Alliance", secret), "restricted keys were consumed")
titleEnabled = secret
check(sync:RemoveStoredEntry("Horde", "Retail-Realm"), "local cleanup depends on a readable native capability")
check(mutations == 0, "local cleanup mutated a Blizzard friendship")

reset(); titleEnabled = false
sync:DeleteStoredFriend("Alliance", "Retail-Realm")
check(env.BetterFriendlistDB.GlobalFriends.Alliance["Retail-Realm"].deleted == true,
	"legacy Delete Friend no longer retains the sync tombstone")
check(mutations == 0, "legacy deletion touched a friend absent from the local roster")

-- Add All snapshots names; a later X must also prevent that queued prompt.
reset(); env.BetterFriendlistDB.GlobalFriends.Horde = {}
local prompts, nextInvite = 0, nil
BFL.RequestTitleFriendInviteConfirmation = function() prompts = prompts + 1; return nil end
env.C_Timer = { After = function(_, callback) nextInvite = callback end }
sync.titleInviteBatch = { names = { "Retail-Realm" }, index = 1 }
assert(sync:RemoveStoredEntry("Alliance", "Retail-Realm"))
sync:AdvanceTitleInvites()
check(prompts == 0 and nextInvite, "removing the final saved copy left a native invitation queued")
nextInvite()
check(sync.titleInviteBatch == nil, "removed invite candidate kept its batch busy")
reset(); assert(sync:RemoveStoredEntry("Alliance", "Retail-Realm"))
sync.titleInviteBatch = { names = { "Retail-Realm" }, index = 1 }
sync:AdvanceTitleInvites()
check(prompts == 1, "removing one faction suppressed an existing saved copy in another faction")

-- Bulk removal preserves the shared graph, counts tombstones and cancels only
-- addon-owned work. Even a stale cancelled callback cannot use a refilled DB.
active, deleted, otherFaction = reset()
graph = env.BetterFriendlistDB.GlobalFriends
local alliance, horde = graph.Alliance, graph.Horde
local contacts, backup = { contacts = { private = { privateNote = "keep contact" } } }, { private = { originalNote = "keep backup" } }
env.BetterFriendlistDB.contactMemory, env.BetterFriendlistDB.noteBackup = contacts, backup
characters = env.BetterFriendlistDB.knownCharacters
local function ownedTimer(callback)
	local value = { callback = callback }
	function value:Cancel() self.cancelled = true end
	return value
end
env.C_Timer.NewTicker = function(_, callback) return ownedTimer(callback) end
env.C_Timer.NewTimer = function(_, callback) return ownedTimer(callback) end
sync.processingQueue, sync.updateTimer, sync.activeTitlePrompt = false, nil, nil
sync.pendingRestores, sync.attemptedAdds, sync.requestedTitleFriends = { [active] = true }, { ["Retail-Realm"] = {} }, { previous = true }
local restoreRefs, attemptRefs, requestRefs = sync.pendingRestores, sync.attemptedAdds, sync.requestedTitleFriends
titleEnabled = false
sync:ProcessAddQueue({ { key = "Retail-Realm", name = "Retail-Realm", faction = "Alliance" } })
sync:OnFriendListUpdate()
local queuedAdd, queuedUpdate = sync.addQueueTicker, sync.updateTimer
local openPrompt = { name = "Already Open", dialog = { Hide = nativeMutation, SetScript = nativeMutation } }
sync.activeTitlePrompt = openPrompt
sync.titleInviteBatch = { names = { "Retail-Realm" }, index = 1 }
sync.pendingIndexRemoval, sync.deletionSnapshot, sync.syncDeferred = {}, {}, true
check(sync:GetStoredEntryCount() == 3, "entry count excluded tombstones or another faction")
check(sync:ClearStoredEntries() == 3, "bulk removal returned the wrong number of deleted entries")
check(env.BetterFriendlistDB.GlobalFriends == graph and graph.Alliance == alliance and graph.Horde == horde
	and not next(alliance) and not next(horde), "bulk removal replaced shared graph/faction references or left records")
check(not next(restoreRefs) and not next(attemptRefs) and not next(requestRefs), "bulk removal retained addon retry references")
check(queuedAdd.cancelled and queuedUpdate.cancelled and not sync.addQueueTicker and not sync.updateTimer and not sync.processingQueue,
	"bulk removal retained a running add/update timer")
check(not sync.titleInviteBatch and not sync.pendingIndexRemoval and not sync.deletionSnapshot and not sync.syncDeferred,
	"bulk removal retained queued invitations or deferred deletion state")
check(sync.activeTitlePrompt == openPrompt, "bulk removal changed an already open Blizzard confirmation")
local promptsBeforeClear = prompts
sync:AdvanceTitleInvites()
check(prompts == promptsBeforeClear, "cleared title batch opened another native invitation")
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
check(sync:ClearStoredEntries() == 1, "bulk removal depends on readable native capability flags")
env.BetterFriendlistDB.GlobalFriends = nil
check(sync:GetStoredEntryCount() == 0 and sync:ClearStoredEntries() == 0, "missing database was not treated as empty")
local sharedFaction = { shared = { notes = "shared saved entry" } }
env.BetterFriendlistDB.GlobalFriends = { Alliance = sharedFaction, Horde = sharedFaction }
check(sync:GetStoredEntryCount() == 2 and sync:ClearStoredEntries() == 2 and not next(sharedFaction),
	"shared faction tables changed the counted result or retained entries")
sync.activeTitlePrompt = nil

-- Minimal addon-owned widgets capture actual callback wiring and anchor parameters.
local widgetMethods = {}
function widgetMethods:SetScript(event, callback) self.scripts[event] = callback end
function widgetMethods:HookScript(event, callback) self.hooks[event] = callback end
function widgetMethods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function widgetMethods:ClearAllPoints() self.points = {} end
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
env.CreateFrame = function(kind, _, parent, template) return widget(kind, parent, template) end
env.BFL_Tooltip = { SetOwner = function() end, SetText = function(_, text) env.tooltipText = text end,
	AddLine = function(_, text) env.tooltipDesc = text end, Show = function() end, Hide = function() end }
local Settings, host = {}, widget("Frame")
function Settings:GetGlobalSyncTabHost() return host end
local DB = { Get = function(_, key, fallback)
	local value = env.BetterFriendlistDB[key]; if value == nil then return fallback end; return value
end }
local Components = {}
for _, method in ipairs({ "CreateHeader", "CreateLabel", "CreateCheckbox", "CreateSpacer" }) do
	Components[method] = function(_, parent) return widget("Control", parent) end
end
function Components:AnchorChain() end
env.Settings, env.Components, env.L, env.BFL_LOCALE_ENUS = Settings, Components, BFL.L, BFL.L
env.GetDB = function() return DB end
env.HideComponentList = function(tab)
	for _, frame in ipairs(tab.components or {}) do frame:Hide() end
end
assert(loadfile(repo .. "/Locales/enUS.lua", "t", env))("BetterFriendlist", BFL)
local componentSource = read("Modules/SettingsComponents.lua")
local componentFirst = assert(componentSource:find("function Components:CreateButton(parent, text, onClick, tooltip)", 1, true))
local componentLast = assert(componentSource:find("-- DOUBLE CHECKBOX ROW", componentFirst, true))
env.FIELD_WIDTH = 180
assert(load(componentSource:sub(componentFirst, componentLast - 1), "@production settings button", "t", env))()
local settingsSource = read("Modules/Settings.lua")
local first = assert(settingsSource:find("function Settings:ShowGlobalSyncDeleteAllConfirmation()", 1, true))
local last = assert(settingsSource:find("-- Refresh Streamer Mode Tab", first, true))
env.StaticPopupDialogs = {}
local shownPopup
env.StaticPopup_Show = function(name) shownPopup = name end
assert(load(settingsSource:sub(first, last - 1), "@production Global Sync settings", "t", env))()
local function rowButtons()
	local rows = {}
	for _, value in ipairs(widgets) do
		if value.kind == "Button" and value.template == "UIPanelButtonTemplate" and value.parent.parent == host then
			local row = value.parent
			rows[row] = rows[row] or {}; rows[row][value.text] = value
		end
	end
	return rows
end
reset(); Settings.showDeletedFriends = true
Settings:RefreshGlobalSyncTab()
local rowCount, remove, add = 0
for _, row in pairs(rowButtons()) do
	rowCount = rowCount + 1
	check(row.X and row["+"], "Title database row lacks separate remove and invite buttons")
	remove, add = row.X, row["+"]
end
check(rowCount == 3, "historical entries disappeared with Show Deleted checked")
remove.scripts.OnEnter(remove)
check(env.tooltipText == BFL.L.TOOLTIP_REMOVE_SYNC_ENTRY and env.tooltipDesc == BFL.L.TOOLTIP_REMOVE_SYNC_ENTRY_DESC,
	"remove tooltip does not explain local-only scope")
local invites = 0
function sync:StartTitleInvites() invites = invites + 1; return true end
add.scripts.OnClick(add)
check(invites == 1, "Title + no longer routes through the existing invite flow")
widgets = {}; remove.scripts.OnClick(remove)
rowCount = 0; for _ in pairs(rowButtons()) do rowCount = rowCount + 1 end
check(rowCount == 2 and mutations == 0 and invites == 1, "X did not refresh the list or changed a Blizzard friendship")

reset(); titleEnabled = false; widgets = {}
Settings:RefreshGlobalSyncTab()
for _, row in pairs(rowButtons()) do check(not row["+"] and (row.X or row.R), "legacy row actions were replaced with Title actions") end

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
check(bulkButton:IsShown() and bulkButton:IsEnabled(), "Title Friends database lacks the bulk removal action")

-- Load the whole production popup and open it from the actual globe callback.
reset()
env.BetterFriendsFrame = widget("Frame")
env.BetterFriendsFrame.bottom, env.BetterFriendsFrame.scale = 100, .8
env.BetterFriendsFrame.AddFriendButton = widget("Button", env.BetterFriendsFrame)
env.BetterFriendsFrame.AddFriendButton.top = 120
local modernButton = widget("Button", env.BetterFriendsFrame)
modernButton.top, modernButton.scale = 200, .6
local modern = false
modules.FriendsUI = { root = { BottomActionBar = { AddFriendButton = modernButton } },
	IsModernActive = function() return modern end, GetSelectedSection = function() return "friends" end }
assert(loadfile(repo .. "/Modules/GlobalSyncUI.lua", "t", env))("BetterFriendlist", BFL)
for _, useModern in ipairs({ false, true }) do
	modern = useModern; sync:RefreshTitleFriendUI()
	local anchor = modern and modernButton or env.BetterFriendsFrame.AddFriendButton
	local globe = assert(anchor.BFL_TitleSyncButton)
	globe.top = modern and 200 or 140; globe.scale = modern and .6 or .8
	globe.scripts.OnClick(globe)
	local panel = sync.titleFriendMenu
	local point = panel.points[1]
	check(point[1] == "BOTTOM" and point[2] == env.BetterFriendsFrame and point[3] == "BOTTOM" and point[4] == 0,
		"invite list is not horizontally centered on the friend list")
	local expectedY = globe.top * globe:GetEffectiveScale() / .8 - 100 + 6
	check(math.abs(point[5] - expectedY) < .000001, "centering changed the footer height across UI scales")
	check(panel.width == 320 and panel.height == 224 and panel.shown, "centering changed popup size or visibility")
	panel:Hide()
end
local pendingBefore = sync:GetPendingTitleFriends()
for faction, entries in pairs(env.BetterFriendlistDB.GlobalFriends) do
	for key in pairs(entries) do assert(sync:RemoveStoredEntry(faction, key)) end
end
sync:RefreshTitleFriendUI()
check(#pendingBefore > 0 and #sync:GetPendingTitleFriends() == 0, "removed saved entries remain in the invite candidates")
check(not sync.titleFriendMenu.shown and mutations == 0, "empty invite database retained the popup or changed Blizzard friends")
io.write("[OK] Global Sync management smoke: " .. checks .. " checks (production callbacks, mocked engine)\n")
