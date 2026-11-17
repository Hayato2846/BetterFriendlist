-- Lua 5.4: lua tools/BFL-BlizzardDiagnosticsSmoke.lua <repo>
-- Production DB migrations, staged imports and Settings confirmation callbacks.
-- Profiles, popup widgets and client APIs are isolated mocks; live taint needs QA.
local root = arg[1] or "."
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function read(path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local text = file:read("*a"); file:close(); return text
end
local function between(source, first, last)
	local start = assert(source:find(first, 1, true))
	return source:sub(start, assert(source:find(last, start + #first, 1), last) - 1)
end
local function fixture(flavor)
	local BFL = { modules = {}, VERSION = "3.1.4", IsMainline = flavor == "retail" or flavor == "forever",
		IsForever = flavor == "forever", IsClassic = flavor:match("^classic") ~= nil,
		UI = { CONSTANTS = { MAX_RECURSION_DEPTH = 10 } } }
	BFL.L = setmetatable({}, { __index = function(_, key) return key end })
	function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
	function BFL:GetModule(name) return self.modules[name] end
	BFL.DebugPrint = function() end
	function BFL:ForceRefreshFriendsList() end
	function BFL:RegisterEventCallback() end
	function BFL.GetNumWoWFriends() return 0 end
	function BFL:NormalizeWoWFriendName(name) return name end
	local env = setmetatable({ StaticPopupDialogs = {}, CANCEL = "Cancel",
		BNGetNumFriends = function() return 0 end, GetNormalizedRealmName = function() return "TestRealm" end,
		InCombatLockdown = function() return false end,
	}, { __index = _G })
	env._G = env
	function env.wipe(target) for key in pairs(target) do target[key] = nil end end
	function env.CopyTable(value)
		if type(value) ~= "table" then return value end
		local copy = {}; for key, child in pairs(value) do copy[key] = env.CopyTable(child) end; return copy
	end
	local shown
	env.StaticPopup_Show = function(key) shown = key; return {} end
	env.StaticPopup_Hide = function(key) if shown == key then shown = nil end end
	for _, path in ipairs({ "Utils/Encoding.lua", "Utils/ProfileCodec.lua", "Modules/Database.lua", "Modules/Groups.lua", "Modules/Settings.lua" }) do
		assert(loadfile(root .. "/" .. path, "t", env))("BetterFriendlist", BFL)
	end
	local DB, settings = BFL.modules.DB, BFL.modules.Settings
	local function initialize(profile) env.BetterFriendlistDB = profile; DB:Initialize(); return profile end
	local function dialog() return assert(env.StaticPopupDialogs[assert(shown, "confirmation is missing")]) end
	return BFL, env, DB, settings, initialize, dialog
end
for _, flavor in ipairs({ "retail", "forever", "classic", "classic_era", "classic_anniversary" }) do
	local BFL, env, DB, settings, initialize, dialog = fixture(flavor)
	local profile = initialize({ version = "3.1.3", showBlizzardOption = true, compactMode = true })
	equal(profile.showBlizzardOption, false, flavor .. " upgrade disables diagnostic access")
	equal(profile.blizzardDiagnosticsMigrationVersion, 1, flavor .. " upgrade records the one-time migration")
	equal(profile.compactMode, true, flavor .. " upgrade preserves unrelated preferences")
	profile.showBlizzardOption = true
	DB:Initialize()
	equal(profile.showBlizzardOption, true, flavor .. " a later opt-in survives another login")
	local fresh = initialize({})
	equal(fresh.showBlizzardOption, false, flavor .. " fresh profiles start disabled")
	equal(fresh.blizzardDiagnosticsMigrationVersion, 1, flavor .. " fresh profiles record the migration")
	settings:OnShowBlizzardOptionChanged(true)
	equal(fresh.showBlizzardOption, false, flavor .. " requesting activation cannot enable before confirmation")
	local pending = dialog()
	equal(pending.hideOnEscape, true, flavor .. " Escape can dismiss the warning")
	pending.OnCancel()
	equal(fresh.showBlizzardOption, false, flavor .. " cancel leaves diagnostic access disabled")
	settings:OnShowBlizzardOptionChanged(true)
	dialog().OnAccept()
	equal(fresh.showBlizzardOption, true, flavor .. " explicit acceptance enables the option")
	DB:Initialize()
	equal(fresh.showBlizzardOption, true, flavor .. " accepted activation is not reset on reload")
	settings:OnShowBlizzardOptionChanged(false)
	equal(fresh.showBlizzardOption, false, flavor .. " disabling needs no confirmation")
	settings:OnShowBlizzardOptionChanged(true)
	local stale = dialog()
	settings:OnShowBlizzardOptionChanged(false)
	stale.OnAccept()
	equal(fresh.showBlizzardOption, false, flavor .. " a superseded warning cannot re-enable the option")
	settings:OnShowBlizzardOptionChanged(true)
	stale = dialog()
	settings:InvalidatePendingBlizzardOptionConfirmation()
	stale.OnAccept()
	equal(fresh.showBlizzardOption, false, flavor .. " an invalidated confirmation cannot apply")
	settings:OnShowBlizzardOptionChanged(true)
	stale = dialog()
	local replacement = initialize({})
	stale.OnAccept()
	equal(replacement.showBlizzardOption, false, flavor .. " a warning cannot enable a replacement profile")
	local oldImport = assert(DB:PrepareImportedProfile({ exportVersion = 3, version = "3.1.3",
		showBlizzardOption = true, customGroups = {}, friendGroups = {} }))
	equal(oldImport.showBlizzardOption, false, flavor .. " an old backup cannot silently restore diagnostic access")
	equal(oldImport.blizzardDiagnosticsMigrationVersion, 1, flavor .. " an old backup is marked migrated")
	local newImport = assert(DB:PrepareImportedProfile({ exportVersion = 3, version = "3.1.4",
		showBlizzardOption = true, blizzardDiagnosticsMigrationVersion = 1, customGroups = {}, friendGroups = {} }))
	equal(newImport.showBlizzardOption, true, flavor .. " a migrated backup retains the later user choice")
	-- Run the actual contacts-menu generator in each supported presentation.
	local menuSource = between(read("BetterFriendlist.lua"), "function BetterFriendsFrame_ShowContactsMenu(button)", "-- Show Ignore List")
	assert(load("local BFL, L, GetDB, AddContactsMenuDecoration = ...\n" .. menuSource,
		"@production contacts menu", "t", env))(BFL, BFL.L, function() return DB end, function() end)
	env.BNFeaturesEnabled = function() return false end
	local menuEntries, nativeOpens = {}, 0
	BFL.ShowBlizzardFriendsFrame = function() nativeOpens = nativeOpens + 1 end
	BFL.CreateContextMenu = function(button, generator)
		menuEntries = {}
		generator(button, { SetTag = function() end, CreateButton = function(_, title, callback)
			local entry = { callback = callback, SetEnabled = function() end }
			menuEntries[title] = entry; return entry
		end })
	end
	for _, style in ipairs(BFL.IsMainline and { "modern", "legacy" } or { "legacy" }) do
		BFL.FriendsUI = { IsModernActive = function() return style == "modern" end }
		env.BetterFriendsFrame_ShowContactsMenu({})
		equal(menuEntries[BFL.L.MENU_SHOW_BLIZZARD], nil, flavor .. " " .. style .. " hides native access while disabled")
		settings:OnShowBlizzardOptionChanged(true)
		env.BetterFriendsFrame_ShowContactsMenu({})
		equal(menuEntries[BFL.L.MENU_SHOW_BLIZZARD], nil, flavor .. " " .. style .. " keeps the entry hidden during confirmation")
		dialog().OnAccept()
		env.BetterFriendsFrame_ShowContactsMenu({})
		local native = assert(menuEntries[BFL.L.MENU_SHOW_BLIZZARD], "accepted access is missing from the menu")
		native.callback()
		equal(nativeOpens > 0, true, flavor .. " " .. style .. " accepted menu reaches native access")
		settings:OnShowBlizzardOptionChanged(false)
	end
	-- These legacy slash entrypoints must use the same warning, not direct DB writes.
	local slash = between(read("Core.lua"), '\telseif msg == "show" or msg == "hide" or msg == "toggle" then', '\n\t-- Settings')
	local invoke = assert(load("local BFL, msg = ...\nif false then\n" .. slash .. "\nend", "@production diagnostics slash", "t", env))
	invoke(BFL, "show")
	equal(replacement.showBlizzardOption, false, flavor .. " slash show waits for consent")
	dialog().OnAccept()
	equal(replacement.showBlizzardOption, true, flavor .. " slash show accepts the shared warning")
	invoke(BFL, "hide")
	equal(replacement.showBlizzardOption, false, flavor .. " slash hide disables immediately")
	invoke(BFL, "toggle")
	equal(replacement.showBlizzardOption, false, flavor .. " slash toggle waits for consent when enabling")
	dialog().OnAccept(); invoke(BFL, "toggle")
	equal(replacement.showBlizzardOption, false, flavor .. " slash toggle disables immediately when enabled")
	-- An in-place import must invalidate an outstanding confirmation, too.
	settings:OnShowBlizzardOptionChanged(true); stale = dialog()
	BFL.Base64Encode = function() return nil end
	local backup = assert(settings:SerializeTable({ exportVersion = 3, version = "3.1.3",
		showBlizzardOption = true, customGroups = {}, friendGroups = {} }))
	local imported, errorMessage = settings:ImportSettings("BFL1:" .. backup:gsub(".", function(char) return string.format("%02x", char:byte()) end))
	equal(imported, true, flavor .. " the old backup imports successfully: " .. tostring(errorMessage))
	stale.OnAccept()
	equal(replacement.showBlizzardOption, false, flavor .. " a pre-import popup cannot enable the imported profile")
end
local catalogBFL = {}
assert(loadfile(root .. "/Data/LegacySettingsCatalog.lua"))("BetterFriendlist", catalogBFL)
local catalog = catalogBFL.LegacySettingsCatalog
local found = false
for _, key in ipairs(catalog.search.advanced.SETTINGS_LEGACY_DIAGNOSTICS) do if key == "SETTINGS_SHOW_BLIZZARD" then found = true end end
equal(found, true, "the search target lives in Advanced / Diagnostics")
for _, section in pairs(catalog.search.behavior) do
	for _, key in ipairs(section) do equal(key == "SETTINGS_SHOW_BLIZZARD", false, "Behavior has no diagnostic access target") end
end
io.write(("Blizzard diagnostics smoke: %d checks passed (production migration/import/confirmation; mocked client)\n"):format(checks))
