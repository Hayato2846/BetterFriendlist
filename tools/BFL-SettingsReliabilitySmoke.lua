-- Lua 5.4: lua tools/BFL-SettingsReliabilitySmoke.lua <repo>
-- Regression gate for persistence, native tag acknowledgements and live settings.
-- Isolated profiles and production registrations; no WoW or SavedVariables access.
-- Custom editors, native rendering and actual server delivery are not simulated.
local root = arg[1] or "."
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local BFL = { modules = {}, VERSION = "3.0.2-dev", IsMainline = true, IsRetail = true,
	UI = { CONSTANTS = { MAX_RECURSION_DEPTH = 10 } } }
BFL.Modules = BFL.modules
BFL.L = setmetatable({}, { __index = function(_, key) return key end })
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale() end
BFL.DebugPrint = function() end
function BFL:ForceRefreshFriendsList() end
local events = {}
function BFL:RegisterEventCallback(event, callback, priority)
	events[event] = events[event] or {}; events[event][#events[event] + 1] = { callback, priority }
end
function BFL.GetNumWoWFriends() return 0 end
function BFL:NormalizeWoWFriendName(name) return name end
function BFL:IsSecret() return false end
local env = setmetatable({ SlashCmdList = {}, StaticPopupDialogs = {},
	BNGetNumFriends = function() return 0 end, GetNormalizedRealmName = function() return "AuditRealm" end,
	C_Timer = { After = function() end }, BFL_LOCALE_ENUS = BFL.L,
	StaticPopup_Show = function() return {} end, WOW_PROJECT_ID = 1,
	GetCurrentRegion = function() return 1 end, GetTime = function() return 10 end, time = os.time,
	GetLocale = function() return "enUS" end,
}, { __index = _G })
env._G = env
function env.wipe(target) for key in pairs(target) do target[key] = nil end; return target end
function env.CopyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = env.CopyTable(child) end; return result
end
function env.strtrim(value) return value:match("^%s*(.-)%s*$") end
local function execute(path) return assert(loadfile(root .. "/" .. path, "t", env))("BetterFriendlist", BFL) end
execute("Locales/enUS.lua")
execute("Utils/Encoding.lua")
execute("Utils/ProfileCodec.lua")
execute("Utils/ClassicCompat.lua")
execute("Utils/FontManager.lua")
execute("Modules/ThemePalette.lua")
execute("Modules/ThemeManager.lua")
execute("Modules/Database.lua")
execute("Modules/Groups.lua")
execute("Modules/FilterSortRegistry.lua")
execute("Modules/Settings.lua")
execute("Modules/FriendTags.lua")
execute("Modules/ContactMemory.lua")
execute("Modules/KnownCharacters.lua")
execute("Modules/AutoRaidAssist.lua")
execute("Modules/FrameSettings.lua")
env.BetterFriendlistDB = { taintFreeWhisper = true }
BFL.modules.DB:Initialize()
equal(env.BetterFriendlistDB.taintFreeWhisper, nil, "upgrading removes the retired whisper setting")
local oldWhisperBackup = assert(BFL.modules.DB:PrepareImportedProfile({
	exportVersion = 3, customGroups = {}, friendGroups = {}, taintFreeWhisper = true,
}))
equal(oldWhisperBackup.taintFreeWhisper, nil, "full backups cannot restore the retired whisper setting")
BFL.modules.FrameSettings:Initialize()
execute("Libs/LibSettingsDesigner/LibSettingsDesignerConfig.lua")
BFL.LibSettingsDesigner.UI = { GetFrame = function() end }
local controls = {}
local Config = BFL.LibSettingsDesigner.Config
local registerApp = Config.RegisterAddOn
function Config:RegisterAddOn(...)
	local result = registerApp(self, ...)
	local registerControl = result.RegisterControl
	function result:RegisterControl(page, data)
		local control = registerControl(self, page, data)
		controls[#controls + 1] = control
		return control
	end
	return result
end
execute("Modules/SettingsDesigner.lua")
local app = assert(BFL.modules.SettingsDesigner:Register())
BFL.modules.ContactMemory:RegisterSettingsDesignerControls(app)
equal(app:GetPage("privacy.whisper"), nil, "Settings Center has no retired Whisper page")
io.write(string.format("Registered %d controls through production LibSettingsDesigner\n", #controls))
local passes, failures, errors = 0, 0, 0
for _, control in ipairs(controls) do
	if control.type == "toggle" and control.id ~= "enableSettingsCenterBeta" and control.id ~= "syncGroupsToNote" and control.id ~= "useUIPanelSystem" then
		for _, value in ipairs({ true, false, true, false }) do
			local ok, err = pcall(control.setValue, value)
			if not ok then
				errors = errors + 1
				io.write("[NEEDS CONTEXT] " .. control.id .. ": " .. tostring(err) .. "\n")
				break
			end
			local actual = app:GetControlValue(control)
			if actual ~= value then
				failures = failures + 1
				io.write(string.format("[READBACK] %s set=%s got=%s\n", control.id, tostring(value), tostring(actual)))
			else passes = passes + 1 end
		end
	end
end
io.write(string.format("Toggle roundtrips: %d passed, %d mismatches, %d callbacks need native context\n", passes, failures, errors))
assert(failures == 0 and errors == 0, "toggle persistence regressed")

-- Supply only addon-owned frame geometry for size/scale persistence.
BFL.MainFrame = { SetSize = function() end, SetScale = function() end }
local valuePasses, valueFailures, valueErrors = 0, 0, 0
for _, control in ipairs(controls) do
	local values
	if control.type == "slider" then values = { control.min, control.max, control.default }
	elseif control.type == "input" then values = { control.numeric and 123 or "Audit value", control.default }
	elseif control.type == "dropdown" then
		local ok, choices, order = pcall(function()
			if control.listFunc then return control.listFunc() end
			return control.list, control.orderList
		end)
		if ok and type(choices) == "table" then
			values = {}
			if type(order) == "table" then for _, value in ipairs(order) do values[#values + 1] = value end
			else for value in pairs(choices) do values[#values + 1] = value end end
		end
	end
	for _, value in ipairs(values or {}) do
		local ok, err = pcall(control.setValue, value)
		if not ok then valueErrors = valueErrors + 1; io.write("[NEEDS CONTEXT] " .. control.id .. ": " .. tostring(err) .. "\n"); break end
		local actual = app:GetControlValue(control)
		if actual ~= value then
			valueFailures = valueFailures + 1
			io.write(string.format("[READBACK] %s set=%s got=%s\n", control.id, tostring(value), tostring(actual)))
		else valuePasses = valuePasses + 1 end
	end
end
io.write(string.format("Slider/dropdown/input roundtrips: %d passed, %d mismatches, %d callbacks need context\n", valuePasses, valueFailures, valueErrors))
assert(valueFailures == 0 and valueErrors == 0, "value persistence regressed")
local colorPasses, flagPasses, colorErrors = 0, 0, 0
for _, control in ipairs(controls) do
	if control.type == "colorpicker" and control.setColor and control.getColor then
		local ok, err = pcall(function()
			control.setColor(nil, .23, .45, .67, .89)
			local r, g, b = control.getColor()
			assert(math.abs(r - .23) < .001 and math.abs(g - .45) < .001 and math.abs(b - .67) < .001, "color readback mismatch")
		end)
		if ok then colorPasses = colorPasses + 1 else colorErrors = colorErrors + 1; io.write("[COLOR CONTEXT] " .. control.id .. ": " .. tostring(err) .. "\n") end
	elseif control.type == "multidropdown" and control.setSelectedFunc and control.getSelection then
		for _, flag in ipairs(control.orderList or {}) do
			if flag ~= "NONE" then
				for _, selected in ipairs({ true, false }) do
					control.setSelectedFunc(flag, selected)
					assert((control.getSelection()[flag] == true) == selected, "font flag readback mismatch: " .. control.id)
					flagPasses = flagPasses + 1
				end
			end
		end
	end
end
io.write(string.format("Color roundtrips: %d; font flag roundtrips: %d\n", colorPasses, flagPasses))
assert(colorErrors == 0, "color persistence regressed")
BFL.MainFrame = nil

local function findControl(id)
	for _, control in ipairs(controls) do if control.id == id then return control end end
	error("Missing control " .. id)
end

-- Native tag writes are asynchronous: retain the old readable API snapshot
-- until an explicit server acknowledgement is simulated.
env.Enum = { BattleNetFriendTag = { Raiding = 2 } }
env.C_BattleNet = { AreFriendTagsEnabled = function() return true end, SetFriendTags = function() end,
	GetFriendAccountInfo = function() end }
local tags = BFL.modules.FriendTags
tags:Initialize()
assert(tags:AreBlizzardTagsEnabled(), "Native tag fixture must exercise the real enabled path")
local timers = {}
env.C_Timer.After = function(delay, callback) timers[#timers + 1] = { delay = delay, callback = callback } end
local friend = { type = "bnet", uid = "bnet_Audit#1234", battleTag = "Audit#1234", bnetAccountID = 42, friendTags = { 2 } }
assert(tags:SetBlizzardTagsForFriend(friend, {}, { userInitiated = true }))
local afterRemove = tags:GetBlizzardTagIdSetForFriend(friend)
equal(afterRemove["blizzard:raiding"], nil, "final native tag removal takes effect before acknowledgement")
friend.friendTags = {}
assert(tags:SetBlizzardTagsForFriend(friend, { ["blizzard:raiding"] = true }, { userInitiated = true }))
BFL.modules.FriendsList = { GetLastBNetFriendInfoEventTagsChanged = function() return false end }
for _, entry in ipairs(events.BN_FRIEND_INFO_CHANGED or {}) do if entry[2] == 85 then entry[1](99) end end
local afterOtherFriend = tags:GetBlizzardTagIdSetForFriend(friend)
equal(afterOtherFriend["blizzard:raiding"], true, "unrelated friend events preserve the pending edit")
local uid = tags:GetFriendUID(friend)
local other = { type = "bnet", uid = "bnet_Other#1234", battleTag = "Other#1234", bnetAccountID = 43, friendTags = {} }
assert(tags:SetBlizzardTagsForFriend(other, { ["blizzard:pvp"] = true }, { userInitiated = true }))
for _, entry in ipairs(events.BN_FRIEND_INFO_CHANGED or {}) do if entry[2] == 85 then entry[1](nil) end end
equal(tags:GetBlizzardTagIdSetForFriend(other)["blizzard:pvp"], true, "unknown events do not discard another pending account")
timers[1].callback()
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:raiding"], true, "an obsolete removal timeout cannot undo the newer addition")
friend.friendTags = { 2 }
tags:InvalidateFriendAssignment(friend)
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:raiding"], true, "matching native snapshot acknowledges the edit")
equal(tags.pendingBlizzardTagSets[uid], nil, "acknowledged native write releases its pending set")
equal(tags:GetBlizzardTagIdSetForFriend(other)["blizzard:pvp"], true, "one acknowledgement leaves the other account intact")

assert(tags:SetBlizzardTagsForFriend(friend, { ["blizzard:pvp"] = true }, { userInitiated = true }))
local olderWrite = timers[#timers]
assert(tags:SetBlizzardTagsForFriend(friend, {}, { userInitiated = true }))
local latestWrite = timers[#timers]
olderWrite.callback()
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:pvp"], nil, "rapid toggles keep the latest empty selection")
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:raiding"], nil, "old server state cannot restore a removed tag while pending")
equal(latestWrite.delay, 10, "unacknowledged optimistic display is bounded")
latestWrite.callback()
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:raiding"], true, "missing server acknowledgement eventually restores authoritative data")

assert(tags:SetBlizzardTagsForFriend(friend, {}, { userInitiated = true }))
local beforeImport = timers[#timers]
tags:OnDatabaseImported()
assert(tags:SetBlizzardTagsForFriend(friend, { ["blizzard:pvp"] = true }, { userInitiated = true }))
beforeImport.callback()
equal(tags:GetBlizzardTagIdSetForFriend(friend)["blizzard:pvp"], true, "a callback predating import cannot clear a new pending edit")
BFL.modules.FriendsList = nil

-- Compare the two settings surfaces' notification contracts without drawing UI.
local streamerUpdates = 0
BFL.modules.StreamerMode = { UpdateState = function() streamerUpdates = streamerUpdates + 1 end }
findControl("showStreamerModeButton").setValue(false)
findControl("streamerModeHeaderText").setValue("Audit header")
equal(streamerUpdates, 2, "both Settings Center privacy controls update StreamerMode immediately")

local db = BFL.modules.DB

-- Actual Broker formatter and the production settings callback at a fixed clock.
execute("Utils/BrokerUtils.lua")
env.CreateFrame = function()
	return { SetSize = function() end, EnableMouse = function() end, SetFrameStrata = function() end, Hide = function() end }
end
local brokerFile = assert(io.open(root .. "/Modules/Broker.lua", "rb"))
local brokerSource = brokerFile:read("*a"); brokerFile:close()
brokerSource = brokerSource:gsub("return Broker%s*$", "return function(value) dataObject = value end")
local setDataObject = assert(load(brokerSource, "@production Broker audit", "t", env))("BetterFriendlist", BFL)
local brokerObject = {}
setDataObject(brokerObject)
db:Set("brokerShowGroups", false)
db:Set("brokerShowLabel", false)
db:Set("brokerShowTotal", true)
BFL.modules.Broker:UpdateBrokerText(true)
local before = brokerObject.text
local scheduled = 0
env.C_Timer.After = function() scheduled = scheduled + 1 end
findControl("brokerShowTotal").setValue(false)
equal(before, "0/0", "broker fixture starts with totals")
equal(brokerObject.text, "0", "Settings Center broker updates bypass the background throttle")

-- The real guild module keeps active filter/sort state apart from the DB.
execute("Modules/GuildFrame.lua")
db:Set("guildTabFilterMode", "online")
db:Set("guildTabSortMode", "rank")
local guild = BFL.modules.GuildFrame
guild:Initialize()
findControl("guildTabFilterMode").setValue("offline")
findControl("guildTabSortMode").setValue("name")
equal(guild.filterMode, "offline", "Settings Center updates the active guild filter")
equal(guild.sortMode, "name", "Settings Center updates the active guild sort")
guild:SetFilter("offline")
guild:SetSort("name", true)
assert(guild.filterMode == "offline" and guild.sortMode == "name", "Legacy's live guild setters must apply the same values")

-- Execute the real legacy UI wiring, capturing native-independent callbacks.
local settingsFile = assert(io.open(root .. "/Modules/Settings.lua", "rb"))
local settingsSource = settingsFile:read("*a"):gsub("\r\n", "\n"); settingsFile:close()
local function between(source, first, last)
	local start = assert(source:find(first, 1, true), first)
	return source:sub(start, assert(source:find(last, start + #first, true), last) - 1)
end
local captured = {}
local function capture(_, _, label, _, callback)
	local control = { label = label, callback = callback, SetTooltip = function() end }
	captured[#captured + 1] = control
	return control
end
env.BFL, env.DB, env.self, env.L, env.tab, env.allFrames = BFL, db, BFL.modules.Settings, BFL.L, {}, {}
env.Components = { CreateCheckbox = capture, CreateInput = capture,
	CreateDropdown = function(_, _, label, _, _, callback) return capture(nil, nil, label, nil, callback) end }
local function legacyCallback(section, first, last)
	captured = {}
	local start = assert(settingsSource:find(section, 1, true))
	local source = settingsSource:sub(start)
	assert(load(between(source, first, last), "@production legacy settings wiring", "t", env))()
	assert(#captured == 1, "expected exactly one real legacy control")
	return captured[1].callback
end
local legacyStreamer = legacyCallback("function Settings:RefreshStreamerTab()", "local enableToggle =", "\n\t-- Header: Privacy Options")
local legacyHeader = legacyCallback("function Settings:RefreshStreamerTab()", "local headerBox =", "\n\t-- 3. Name Formatting")
for _, value in ipairs({ true, false, true }) do
	local beforeUpdates = streamerUpdates
	legacyStreamer(value)
	equal(db:Get("showStreamerModeButton"), value, "legacy streamer checkbox persists immediately")
	equal(streamerUpdates, beforeUpdates + 1, "legacy streamer checkbox applies immediately")
	findControl("showStreamerModeButton").setValue(not value)
	equal(streamerUpdates, beforeUpdates + 2, "switching settings surfaces applies immediately")
end
legacyHeader("Legacy header")
equal(db:Get("streamerModeHeaderText"), "Legacy header", "legacy header input uses the shared callback")
findControl("streamerModeHeaderText").setValue("Settings Center header")
equal(db:Get("streamerModeHeaderText"), "Settings Center header", "Settings Center header input uses the same callback")

captured = {}
local guildStart = assert(settingsSource:find("function Settings:RefreshGuildTab()", 1, true))
local guildSettings = settingsSource:sub(guildStart)
assert(load(between(guildSettings, "local filterOptions =", "local visualRow ="), "@production legacy guild dropdowns", "t", env))()
equal(#captured, 2, "both actual legacy guild dropdown callbacks were captured")
for _, pair in ipairs({ { "all", "level" }, { "offline", "name" }, { "online", "rank" } }) do
	captured[1].callback(pair[1]); captured[2].callback(pair[2])
	equal(guild.filterMode, pair[1], "legacy guild filter changes the active state")
	equal(guild.sortMode, pair[2], "legacy guild sort changes the active state")
	equal(db:Get("guildTabFilterMode"), pair[1], "legacy guild filter persists")
	equal(db:Get("guildTabSortMode"), pair[2], "legacy guild sort persists")
	findControl("guildTabFilterMode").setValue("all")
	findControl("guildTabSortMode").setValue("class")
	equal(guild.filterMode, "all", "Settings Center remains live after a legacy change")
	equal(guild.sortMode, "class", "Settings Center sort remains live after a legacy change")
end

local legacyTotals = legacyCallback("function Settings:RefreshBrokerTab()", "local showTotal =", "\n\t\tshowTotal:SetTooltip")
for _, value in ipairs({ true, false, true, false }) do
	legacyTotals(value)
	equal(brokerObject.text, value and "0/0" or "0", "legacy broker totals apply within the same 100ms window")
	findControl("brokerShowTotal").setValue(not value)
	equal(brokerObject.text, value and "0" or "0/0", "Settings Center broker totals apply in the same window")
end

-- The Guild Broker has a separate throttle; verify both real settings paths.
local guildBrokerFile = assert(io.open(root .. "/Modules/GuildBroker.lua", "rb"))
local guildBrokerSource = guildBrokerFile:read("*a"); guildBrokerFile:close()
guildBrokerSource = guildBrokerSource:gsub("return GuildBroker%s*$", "return function(value) dataObject = value end")
local setGuildObject = assert(load(guildBrokerSource, "@production GuildBroker audit", "t", env))("BetterFriendlist", BFL)
local guildObject = {}; setGuildObject(guildObject)
env.IsInGuild = function() return true end
BFL.modules.GuildBroker.GetGuildCounts = function() return 3, 6 end
BFL.modules.GuildBroker.RequestApplicantCountUpdate = function() end
db:Set("guildBrokerShowLabel", false); db:Set("guildBrokerShowApplicants", false); db:Set("guildBrokerExcludeSelf", false)
local legacyGuildTotals = legacyCallback("function Settings:RefreshBrokerTab()", "local guildShowTotal =", "\n\t\ttable.insert(allFrames, guildShowTotal)")
for _, value in ipairs({ true, false, true, false }) do
	legacyGuildTotals(value)
	equal(guildObject.text, value and "3/6" or "3", "legacy Guild Broker totals apply immediately")
	findControl("guildBrokerShowTotal").setValue(not value)
	equal(guildObject.text, value and "3" or "3/6", "Settings Center Guild Broker totals apply immediately")
end

-- With a healthy hidden guild tab, visual settings must invalidate warm rows
-- before the next show; ordinary Refresh deliberately keeps these caches.
BFL.IsGuildTabEnabled = function() return true end
for _, key in ipairs({ "guildTabShowClassIcons", "guildTabUseNicknames" }) do
	guild._displayListDirty, guild._retailScrollBoxDirty, guild._retailScrollBoxVisualDirty = false, false, false
	findControl(key).setValue(false)
	equal(guild._displayListDirty, true, "guild settings invalidate nickname sorting/display structure")
	equal(guild._retailScrollBoxVisualDirty, true, "guild settings invalidate the visible row cache")
end
io.write("[OK] Live settings/tag regressions: " .. checks .. " checks, plus persistence roundtrips\n")
