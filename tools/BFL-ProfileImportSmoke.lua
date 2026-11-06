-- Run with Lua 5.4: lua tools/BFL-ProfileImportSmoke.lua <repository root>
-- Loads production code. No game, user SavedVariables, or native bindings touched.
local root = assert(arg[1], "repository root required"):gsub("[\\/]$", "")
local assertions = 0
local function check(value, message)
	assertions = assertions + 1
	assert(value, message)
end
local BFL = { modules = {}, VERSION = "3.0.1", Version = "3.0.1", IsMainline = true, UI = { CONSTANTS = { MAX_RECURSION_DEPTH = 10 } } }
BFL.L = setmetatable({}, { __index = function(_, key) return key end })
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
BFL.DebugPrint = function() end
function BFL:ForceRefreshFriendsList() end
function BFL:RegisterEventCallback() end
function BFL.GetNumWoWFriends() return 0 end
function BFL:NormalizeWoWFriendName(name) return name end
local env = setmetatable({
	loadstring = function() error("profile input must never execute") end,
	setfenv = function() error("profile input must never execute") end,
	BNGetNumFriends = function() return 0 end,
	GetNormalizedRealmName = function() return "SmokeRealm" end,
}, { __index = _G })
function env.wipe(target) for key in pairs(target) do target[key] = nil end; return target end
function env.CopyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = env.CopyTable(child) end; return result
end
local function loadProduction(path)
	return assert(loadfile(root .. "/" .. path, "t", env))("BetterFriendlist", BFL)
end
loadProduction("Utils/Encoding.lua")
loadProduction("Utils/ProfileCodec.lua")
loadProduction("Modules/Database.lua")
loadProduction("Modules/Groups.lua")
loadProduction("Modules/FilterSortRegistry.lua")
loadProduction("Modules/Settings.lua")
local codec, DB, Groups, Registry, Settings = BFL.ProfileCodec, BFL.modules.DB, BFL.modules.Groups, BFL.modules.FilterSortRegistry, BFL.modules.Settings
local nativeEncode = BFL.Base64Encode
-- Hex is a supported production transport, independent of a host's native APIs.
BFL.Base64Encode = function() return nil end
local function hex(source) return "BFL1:" .. source:gsub(".", function(char) return string.format("%02x", char:byte()) end) end
local function importData(value)
	return Settings:ImportSettings(hex(assert(Settings:SerializeTable(value))))
end
local function reset()
	env.BetterFriendlistDB = {}
	DB:Initialize()
	local db = env.BetterFriendlistDB
	db.bnetUIDMigrationDone_v2, db.wowUIDMigrationDone_v1, db.wowUIDMigrationDone_v2, db.colorSnapshotMigrationDone = true, true, true, true
	db.enableBetaFeatures = true
	db.customGroups.old = { name = "Existing group", collapsed = true, order = 4 }
	db.friendGroups["bnet_Smoke#1234"] = { "old" }
	db.groupColors.old = { r = .1, g = .2, b = .3, a = .4 }
	db.groupCountColors.old = { r = .2, g = .3, b = .4, a = .5 }
	db.groupArrowColors.old = { r = .3, g = .4, b = .5, a = .6 }
	db.groupStates.old = true
	db.groupOrder = { "favorites", "old", "nogroup" }
	db.appearanceOnboardingVersion, db.appearanceOnboardingResume = 8, true
	db.knownCharacters = { contacts = { private = "local association" } }
	db.socialKeybindMigrationVersion, db.socialKeybindMigrated, db.socialKeybindMigratedKeys = "local-binding-version", true, { "P", "O" }
	db.lastInvitedAccounts, db.preferredGameAccounts = { ["bnet_Smoke#1234"] = 111 }, { ["bnet_Smoke#1234"] = 222 }
	db.noteSyncPendingWrites = { ["bnet_Smoke#1234"] = true }
	Groups:Initialize(); Registry:Initialize()
	BFL.modules.NoteSync, BFL.FriendsUI = nil, nil
	return db
end
local function exportedData()
	return assert(Settings:DeserializeTable(assert(Settings:DecodeString(assert(Settings:ExportSettings())))))
end

-- Real serializer output, including Lua 5.1 escaped LF/CR/NUL and all byte values.
local bytes = {}; for index = 0, 255 do bytes[#bytes + 1] = string.char(index) end
local strings = { "Ümlaut 中文 한국어", "quote\" slash\\\n\r\0", table.concat(bytes) }
for _, value in ipairs(strings) do
	local parsed = assert(Settings:DeserializeTable(assert(Settings:SerializeTable({ [17] = value, ["name"] = value, [false] = true }))))
	check(parsed[17] == value and parsed.name == value and parsed[false] == true, "serializer strings must roundtrip losslessly")
end
local literal = assert(Settings:DeserializeTable([[{ legacy="a\000b\255\n\r\"\\", number=-1.25e+3, [2]=0xFF, flag=false, empty=nil }]]))
check(literal.legacy == "a\0b\255\n\r\"\\" and literal.number == -1250 and literal[2] == 255 and literal.flag == false, "historical Lua literals remain readable")
for _, source in ipairs({
	"(function() while true do end end)()", "{x=(function() _G.profileOwned=true return 1 end)()}",
	"{x=error('must not execute')}", "{x=1+2}", "{x=1,x=2}", "{[{}]=1}", "{[nil]=1}",
	"{x=1e999}", "{x='unterminated}", "{x='bad\\999'}", "{};while true do end", "false",
}) do check(Settings:DeserializeTable(source) == nil, "reject executable/malformed input: " .. source) end
check(env.profileOwned == nil and _G.profileOwned == nil, "input has no executable side effect")
local maxBytes, maxNodes = codec.MAX_BYTES, codec.MAX_NODES
codec.MAX_BYTES = 64
check(Settings:DeserializeTable("{" .. string.rep(" ", 64) .. "}") == nil, "reject oversized decoded text")
codec.MAX_BYTES = maxBytes
codec.MAX_NODES = 10
check(Settings:DeserializeTable("{1,2,3,4,5,6,7,8,9,10,11}") == nil, "bound pathological field counts")
codec.MAX_NODES = maxNodes
check(Settings:DeserializeTable(string.rep("{x=", 42) .. "0" .. string.rep("}", 42)) == nil, "bound input nesting")

local db = reset()
check(db.enableSmoothScrolling == false, "upgrading a profile defaults to immediate scrolling")
local scrollDefaults = exportedData()
scrollDefaults.enableSmoothScrolling = nil
db.enableSmoothScrolling = true
check(importData(scrollDefaults) and db.enableSmoothScrolling == false, "older full backups restore the immediate-scroll default")
scrollDefaults.enableSmoothScrolling = true
local scrollApplications = 0
BFL.modules.FriendsList = { ApplyScrollInterpolation = function() scrollApplications = scrollApplications + 1 end }
check(importData(scrollDefaults) and db.enableSmoothScrolling == true and scrollApplications == 1,
	"explicit opt-in in a full backup is applied to the running friend list")
BFL.modules.FriendsList = nil
local exported = exportedData()
for key in pairs(codec.LOCAL_KEYS) do check(exported[key] == nil, "exclude installation-local " .. key) end
db.contactMemory.contacts["bnet:Smoke#1234"] = { privateNote = "private note" }
db.noteBackup = { ["Smoke#1234"] = { originalNote = "old note", accountName = "Real Name", battleTag = "Smoke#1234", isBNet = true } }
db.GlobalFriends = { Alliance = { ["Friend-SmokeRealm"] = { notes = "global note" } }, Horde = {} }
exported = exportedData()
check(exported.contactMemory.contacts["bnet:Smoke#1234"].privateNote == "private note", "full backup retains private notes")
check(exported.noteBackup["Smoke#1234"].accountName == "Real Name", "full backup retains note backup identities")
check(exported.GlobalFriends.Alliance["Friend-SmokeRealm"].notes == "global note", "full backup retains global friend notes")
local locals = {}; for key in pairs(codec.LOCAL_KEYS) do locals[key] = db[key]; exported[key] = "foreign local state" end
exported.unknownFutureSetting = { value = "preserve future settings" }
check(importData(exported), "valid full backup imports")
for key in pairs(codec.LOCAL_KEYS) do check(db[key] == locals[key], "preserve destination local reference " .. key) end
check(db.unknownFutureSetting.value == "preserve future settings", "preserve unknown future data-only settings")
check(Groups.groups.old.color.r == .1 and Groups.groups.old.color.a == .4 and Groups.groups.old.countColor.r == .2 and Groups.groups.old.arrowColor.r == .3, "preserve independent colors and alpha")
check(Groups.groups.old.collapsed and Groups.groups.old.order == 2, "preserve collapse and explicit order")

-- Real editor/registry APIs create a supported depth-five filter; export/import
-- must preserve both its AST and visible filtering behavior.
reset()
local id = Registry:CreateCustomQuickFilter()
local ast = { type = "condition", field = "online", op = "is", value = true }
for _ = 1, 4 do ast = { type = "group", op = "AND", children = { ast } } end
check(Registry:UpdateCustomQuickFilter(id, { name = "Nested online only", ast = ast }), "save supported nested filter")
check(not Registry:EvaluateQuickFilter(id, { type = "wow", connected = false }), "nested filter excludes offline before export")
check(Settings:ImportSettings(assert(Settings:ExportSettings())), "normal exported profile imports")
check(not Registry:EvaluateQuickFilter(id, { type = "wow", connected = false }), "nested filter still excludes offline after import")
check(Registry:EvaluateQuickFilter(id, { type = "wow", connected = true }), "nested filter retains online matches")

-- Invalid shapes, versions, references and transports cannot touch live state.
db = reset()
local dbRef, groupsRef, assignmentsRef = db, db.customGroups, db.friendGroups
local function rejected(source, expected)
	local ok, err = Settings:ImportSettings(hex(source))
	check(not ok and (expected == nil or err == expected), "invalid profile returns a useful error")
	check(env.BetterFriendlistDB == dbRef and db.customGroups == groupsRef and db.friendGroups == assignmentsRef and db.customGroups.old.name == "Existing group", "failed import preserves original DB references")
end
rejected("{exportVersion=3}", "ERROR_EXPORT_STRUCTURE")
rejected("{exportVersion=3,customGroups=false,friendGroups={}}", "ERROR_EXPORT_STRUCTURE")
rejected("{customGroups={broken=false},friendGroups={}}", "ERROR_EXPORT_STRUCTURE")
rejected("{version='2',customGroups={},friendGroups={}}", "ERROR_IMPORT_VERSION")
rejected("{exportVersion=4,customGroups={},friendGroups={}}", "ERROR_IMPORT_VERSION")
rejected("{exportVersion='3',customGroups={},friendGroups={}}", "ERROR_IMPORT_VERSION")
rejected("{customGroups={favorites={name='reserved'}},friendGroups={}}", "ERROR_EXPORT_STRUCTURE")
local corrupt = exportedData(); corrupt.groupStates = false
check(not importData(corrupt), "reject corrupt group state type")
corrupt = exportedData(); corrupt.friendGroups["bnet_Smoke#1234"] = { false }
check(not importData(corrupt), "reject corrupt group assignment element")
corrupt = exportedData(); corrupt.groupColors.old.r = "red"
check(not importData(corrupt), "reject corrupt color component")
for _, transport in ipairs({ "BFL1:7", "BFL1:zz", "BFL7:e30=", "BFL3:e=30", "BFL3:abcd=", "BFL3:***=" }) do
	check(not Settings:ImportSettings(transport), "reject invalid transport " .. transport)
end

-- Older full profiles receive new defaults and the existing supported migration.
local old = exportedData()
old.customQuickFilters, old.customSorters, old.groupStates, old.friendTagSettings, old.nameFormatPreset = nil, nil, nil, nil, nil
old.nameDisplayFormat, old.primarySort, old.secondarySort = "%nickname%", "activity", "activity"
old.raidToolsSortMode, old.raidToolsGroupOffset, old.version = "meter", 2, "2.3.0"
old.GlobalFriends = { Alliance = { ["OldRealm - Owner"] = { OldFriend = { notes = "legacy global note", guid = "old-guid" } } } }
old.globalFriendsMigrated, old.fontFlagsMigratedToPerFont, old.fontUseSlugRendering = nil, nil, false
old.fontOutlineFriendName = "OUTLINE,SLUG"
check(importData(old), "legitimate older full profile imports with defaults")
check(type(db.customQuickFilters) == "table" and type(db.groupStates) == "table" and db.friendTagSettings.enabled, "fill newer defaults before refresh")
check(db.nameFormatPreset == "nickname" and db.primarySort == "status" and db.secondarySort == "name", "migrate older naming and removed sort modes")
check(db.raidToolsSortMode == "tmrh" and db.raidToolsBalanceDps and db.raidToolsPreserveGroups[2], "migrate older raid settings")
check(db.version == "2.3.0", "retain source version for future version migrations")
check(db.GlobalFriends.Alliance["OldFriend-OldRealm"].notes == "legacy global note" and db.globalFriendsMigrated, "flatten legacy global friend storage before synchronization")
check(db.fontOutlineFriendName == "OUTLINE" and db.fontFlagsMigratedToPerFont and db.fontUseSlugRendering == nil, "migrate old per-font rendering flags before refresh")

reset()
local legacy = { customGroups = { raid = { name = "Raid", color = { r = .1, g = .2, b = .3, a = .5 } } }, friendGroups = { ["bnet_Smoke#1234"] = { "raid", "missing", "favorites", "raid" } } }
check(importData(legacy), "V1 backup imports")
check(Groups.groups.raid.color.r == .1 and Groups.groups.raid.color.a == .5 and Groups.groups.raid.countColor.r == .1, "V1 stored custom color becomes effective")
check(#env.BetterFriendlistDB.friendGroups["bnet_Smoke#1234"] == 1, "remove ghost, built-in and duplicate assignments")
legacy.version, legacy.nameDisplayFormat, legacy.windowScale = 2, "%battletag%", 1.25
legacy.enableElvUISkin = true
check(importData(legacy), "V2 backup imports")
check(env.BetterFriendlistDB.nameFormatPreset == "battletag" and env.BetterFriendlistDB.windowScale == 1.25, "V2 settings and name migration apply")
check(env.BetterFriendlistDB.theme == "elvui", "V2 legacy ElvUI preference overrides destination theme")

-- Geometry is consumed later when the main window opens, not necessarily by
-- the import refresh. Exercise those real deferred consumers after rejection.
reset()
loadProduction("Modules/FrameSettings.lua")
local frameSettings, measured, anchored = BFL.modules.FrameSettings, nil, nil
frameSettings.db = env.BetterFriendlistDB
BFL.MainFrame = {
	SetSize = function(_, width, height) measured = { width, height } end,
	ClearAllPoints = function() end,
	SetPoint = function(_, point, _, relativePoint, x, y) anchored = { point, relativePoint, x, y } end,
}
local originalSizes, originalPositions = frameSettings.db.mainFrameSize, frameSettings.db.mainFramePosition
for _, malformed in ipairs({
	{ mainFrameSize = { Default = 1 } },
	{ mainFrameSize = { RetailModern = { width = "410", height = 675 } } },
	{ mainFrameSize = { Default = { width = 410 } } },
	{ mainFramePosition = { Shared = 1 } },
	{ mainFramePosition = { Shared = { point = "TOP", x = {} } } },
	{ mainFramePosition = { Default = { point = "INVALID" } } },
	{ mainFramePosition = { Shared = { point = "CENTER", relativePoint = false } } },
	{ settingsCenterWindow = { width = 0, height = 700 } },
	{ changelogWindowSize = { width = 600, height = 500, x = {} } },
}) do
	local geometry = exportedData()
	for key, value in pairs(malformed) do geometry[key] = value end
	check(not importData(geometry), "reject malformed geometry before deferred frame use")
	check(frameSettings.db.mainFrameSize == originalSizes and frameSettings.db.mainFramePosition == originalPositions, "rejected geometry preserves live map references")
end
frameSettings:ApplySize(); frameSettings:ApplyPosition()
check(measured[1] == 415 and measured[2] == 570 and anchored[1] == "CENTER", "real FrameSettings remains usable after rejected geometry")
local geometry = exportedData()
geometry.friendsFrameStyle = "legacy"
geometry.mainFrameSize = { Default = { width = 501.2, height = 601.4 }, RetailModern = { width = 410.25, height = 675.75 } }
geometry.mainFramePosition = { Default = { point = "TOPLEFT", relativePoint = "BOTTOMRIGHT", x = 12.5, y = -3 }, RetailModern = { point = "CENTER", x = 7, y = 8 } }
check(importData(geometry), "valid old per-layout positions and current sizes import")
frameSettings:ApplySize(); frameSettings:ApplyPosition()
check(measured[1] == 501 and measured[2] == 601, "real Legacy sizing consumes imported dimensions safely")
check(anchored[1] == "TOPLEFT" and anchored[2] == "BOTTOMRIGHT" and anchored[3] == 12.5 and anchored[4] == -3, "real position consumer uses migrated imported anchors")
check(frameSettings.db.mainFrameSize.RetailModern.width == 410.25 and frameSettings.db.mainFramePosition.Default == nil, "preserve Modern fractional sizes and finish shared-position migration")
BFL.MainFrame = nil

-- A late consumer failure restores original nested references, loaded groups,
-- filters and pending note work; successful imports invoke the commit hook once.
db = reset()
local localJournal, oldGroup = db.noteSyncPendingWrites, Groups.groups.old
local hookCalls, failureCalls = 0, 0
local canceledConfirmations, originalCancel = 0, Settings.InvalidatePendingNoteSyncConfirmation
Settings.InvalidatePendingNoteSyncConfirmation = function() canceledConfirmations = canceledConfirmations + 1 end
BFL.modules.NoteSync = { isImporting = false, OnDatabaseImported = function()
	check(canceledConfirmations == 1, "invalidate stale enable confirmation before scheduling imported sync")
	hookCalls = hookCalls + 1
end }
BFL.FriendsUI = { RefreshModernConfigurationLayout = function()
	check(BFL.modules.NoteSync.isImporting, "note writes suspended during refresh/rollback")
	failureCalls = failureCalls + 1; if failureCalls == 1 then error("late UI refresh failure") end
end }
local incoming = exportedData(); incoming.customGroups = { new = { name = "New group" } }; incoming.friendGroups = {}
local oldCustom, oldAssignments = db.customGroups, db.friendGroups
local success, err = importData(incoming)
check(not success and err == "ERROR_IMPORT_APPLY", "late consumer failure returns rollback error")
check(db.customGroups == oldCustom and db.friendGroups == oldAssignments and Groups.groups.old == oldGroup and Groups.groups.new == nil, "rollback restores original DB and group references")
check(db.noteSyncPendingWrites == localJournal and hookCalls == 0 and not BFL.modules.NoteSync.isImporting, "rollback preserves pending local work and import guard")
check(canceledConfirmations == 0, "failed imports preserve the prior valid enable confirmation")
check(importData(incoming) and hookCalls == 1, "only a successful transaction calls note-sync import hook")
check(canceledConfirmations == 1, "successful imports invalidate stale enable intent once")
Settings.InvalidatePendingNoteSyncConfirmation = originalCancel

reset()
db = env.BetterFriendlistDB
db.unknownCycle = {}; db.unknownCycle.self = db.unknownCycle
check(Settings:ExportSettings() == nil, "cyclic nonlocal graph fails export without recursive copy")
db.unknownCycle = nil; db.knownCharacters.self = db.knownCharacters
check(Settings:ExportSettings() ~= nil, "excluded local graph is never copied or serialized")
BFL.Base64Encode = nativeEncode
reset()
check(Settings:ImportSettings(assert(Settings:ExportSettings())), "production Base64 fallback transport roundtrips a complete profile")

-- Both Guild Broker color pickers save positional RGB values. Those settings
-- must survive a full Retail/Forever backup without changing their shape.
local guildColorKeys = { "guildBrokerNicknameColor", "guildBrokerRankColor", "guildBrokerZoneColor", "guildBrokerNoteColor", "guildBrokerOfficerNoteColor" }
db = reset()
for _, key in ipairs(guildColorKeys) do db[key] = { .25, .5, .75 } end
local guildBackup = assert(Settings:ExportSettings())
db = reset()
check(Settings:ImportSettings(guildBackup), "full backup with all custom Guild Broker colors imports")
for _, key in ipairs(guildColorKeys) do
	check(db[key][1] == .25 and db[key][2] == .5 and db[key][3] == .75 and db[key].r == nil, "preserve positional " .. key)
end
for _, key in ipairs(guildColorKeys) do
	for _, color in ipairs({ { .2, .3 }, { "red", .3, .4 }, { -.1, .3, .4 }, { .2, 1.1, .4 }, { .2, .3, .4, false }, { r = .2, g = .3, b = .4 } }) do
		local invalid = exportedData(); invalid[key] = color
		local original = db[key]
		check(not importData(invalid) and db[key] == original, "reject malformed " .. key .. " without replacing live data")
	end
end

-- Global Sync is game-local. Full restore is allowed only when a new backup
-- positively identifies the same running flavor; old strings remain importable.
local flavorFlags = { "IsForever", "IsMainline", "IsRetail", "IsClassic", "IsClassicEra", "IsTBCClassic", "IsWrathClassic", "IsCataClassic", "IsMoPClassic" }
local function flavor(name, channel)
	for _, key in ipairs(flavorFlags) do BFL[key] = false end
	if name == "retail" or name == "forever" then BFL.IsMainline, BFL.IsRetail = true, true end
	if name == "forever" then BFL.IsForever = true end
	local classic = { ["classic-era"] = "IsClassicEra", ["classic-tbc"] = "IsTBCClassic", ["classic-wrath"] = "IsWrathClassic", ["classic-cata"] = "IsCataClassic", ["classic-mists"] = "IsMoPClassic" }
	if classic[name] then BFL.IsClassic, BFL[classic[name]] = true, true end
	env.IsBetaBuild = function() return channel == "beta" end
	env.IsPublicTestClient = function() return channel == "beta" or channel == "test" end
end
local flavorNames = { "retail", "forever", "classic-era", "classic-tbc", "classic-wrath", "classic-cata", "classic-mists" }
local backups = {}
for _, name in ipairs(flavorNames) do
	flavor(name); db = reset()
	db.GlobalFriends = { Alliance = { [name] = { notes = "source note", deleted = true, deletedTime = 42 } }, Horde = {} }
	db.globalFriendsMigrated, db.enableGlobalSync, db.enableGlobalSyncDeletion = true, true, true
	db.exportFlavor = "spoofedSavedVariable"
	backups[name] = assert(Settings:ExportSettings())
	check(exportedData().exportFlavor == name, "export derives " .. name .. " from runtime instead of SavedVariables")
end
for _, destination in ipairs(flavorNames) do
	for _, source in ipairs(flavorNames) do
		flavor(destination); db = reset()
		db.GlobalFriends = { Alliance = {}, Horde = { destination = { notes = "keep destination", deleted = false } } }
		db.globalFriendsMigrated, db.enableGlobalSync, db.enableGlobalSyncDeletion = true, false, false
		local localFriends = db.GlobalFriends
		check(Settings:ImportSettings(backups[source]), source .. " profile imports in " .. destination)
		if source == destination then
			check(db.GlobalFriends ~= localFriends and db.GlobalFriends.Alliance[source].notes == "source note"
				and db.GlobalFriends.Alliance[source].deletedTime == 42 and db.enableGlobalSync and db.enableGlobalSyncDeletion,
				"same-flavor full restore retains friend records/tombstones/options")
		else
			check(db.GlobalFriends == localFriends and db.GlobalFriends.Horde.destination.notes == "keep destination"
				and db.globalFriendsMigrated and not db.enableGlobalSync and not db.enableGlobalSyncDeletion,
				"cross-flavor import preserves the exact destination graph and options")
		end
		check(db.exportFlavor == nil, "transport flavor metadata is never installed as a setting")
	end
end

flavor("retail"); db = reset()
db.contactMemory.contacts["bnet:Cross#1234"] = { privateNote = "portable private note" }
db.noteBackup = { ["Cross#1234"] = { isBNet = true, battleTag = "Cross#1234", originalNote = "portable recovery note" } }
db.windowScale = 1.25
local crossPrivate = assert(Settings:ExportSettings())
flavor("forever"); db = reset()
db.GlobalFriends = { Alliance = {}, Horde = {} }; local destinationGlobal = db.GlobalFriends
check(Settings:ImportSettings(crossPrivate) and db.windowScale == 1.25 and db.GlobalFriends == destinationGlobal,
	"Retail-to-Forever still transfers normal settings while preserving Global Sync")
check(db.contactMemory.contacts["bnet:Cross#1234"].privateNote == "portable private note"
	and db.noteBackup["Cross#1234"].originalNote == "portable recovery note", "cross-flavor full backup still includes the requested private notes/recovery data")

flavor("retail"); db = reset()
local unmarked = exportedData()
unmarked.exportFlavor = nil
unmarked.GlobalFriends = { Alliance = { foreign = { notes = "must not transfer" } } }
unmarked.globalFriendsMigrated, unmarked.enableGlobalSync, unmarked.enableGlobalSyncDeletion = true, true, true
db.GlobalFriends = { Horde = { localFriend = { notes = "local recovery" } } }
db.globalFriendsMigrated, db.enableGlobalSync, db.enableGlobalSyncDeletion = false, false, false
local localFriends = db.GlobalFriends
check(importData(unmarked), "old unmarked V3 backup remains importable")
check(db.GlobalFriends == localFriends and db.globalFriendsMigrated == false and not db.enableGlobalSync
	and not db.enableGlobalSyncDeletion, "unmarked backup cannot overwrite or migrate destination Global Sync")
unmarked.exportFlavor, unmarked.GlobalFriends = "forever", "foreign shape is ignored"
check(importData(unmarked) and db.GlobalFriends == localFriends, "foreign Global Sync shape is never consumed by the destination")
unmarked.exportFlavor = "retail"
check(not importData(unmarked) and db.GlobalFriends == localFriends, "matching flavor still validates its Global Sync schema atomically")
unmarked.GlobalFriends, unmarked.globalFriendsMigrated = {}, "invalid marker"
check(not importData(unmarked), "matching flavor validates migration marker before mutation")
unmarked.exportFlavor = true
check(not importData(unmarked), "reject invalid flavor metadata type")
unmarked.exportFlavor, unmarked.globalFriendsMigrated = nil, true
check(importData({ version = 2, customGroups = {}, friendGroups = {}, enableGlobalSync = true, enableGlobalSyncDeletion = true }), "legacy V2 backup remains importable")
check(db.GlobalFriends == localFriends and not db.enableGlobalSync and not db.enableGlobalSyncDeletion, "legacy V2 preserves local Global Sync options")
db.GlobalFriends, db.globalFriendsMigrated = nil, nil
check(importData(unmarked) and db.GlobalFriends == nil and db.globalFriendsMigrated == nil, "unmarked backup preserves a destination with no stored Global Sync graph")

for _, channel in ipairs({ "beta", "test" }) do
	flavor("retail", channel); db = reset()
	local testBackup = assert(Settings:ExportSettings())
	check(exportedData().exportFlavor == "retail:" .. channel, "test/beta exports identify their channel")
	flavor("retail"); db = reset(); db.GlobalFriends = { Horde = {} }; localFriends = db.GlobalFriends
	check(Settings:ImportSettings(testBackup) and db.GlobalFriends == localFriends, "test/beta state never replaces production Global Sync")
end
flavor("retail"); db = reset()
env.IsBetaBuild = function() error("build state unavailable") end
check(codec:GetCurrentFlavor() == nil, "unknown build state never grants flavor restore authority")
localFriends = db.GlobalFriends
unmarked.exportFlavor = "retail"
check(importData(unmarked) and db.GlobalFriends == localFriends, "unavailable build state keeps the destination Global Sync graph")
env.IsBetaBuild, env.IsPublicTestClient = nil, nil
flavor("unknown")
check(codec:GetCurrentFlavor() == nil, "unknown client family never guesses Retail")
flavor("retail")
io.write("PASS: " .. assertions .. " profile import/export assertions\n")
