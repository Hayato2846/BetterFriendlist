-- Lua 5.4: lua tools/BFL-KnownCharactersSmoke.lua <repo>
-- Complete production module, real menu/editor callbacks, settings and privacy
-- paths. Mocks cannot certify Blizzard's native taint/protected execution model.
local repo = assert(arg[1])
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb")); local value = file:read("*a"); file:close(); return (value:gsub("\r\n", "\n"))
end
local function between(source, first, last)
	local a = assert(source:find(first, 1, true), first)
	local b = assert(source:find(last, a + #first, true), last)
	return source:sub(a, b - 1)
end
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function equal(value, expected, message) check(value == expected, message .. ": " .. tostring(value)) end
local secret = setmetatable({}, { __index = function() error("Secret indexed") end,
	__pairs = function() error("Secret enumerated") end, __len = function() error("Secret measured") end,
	__concat = function() error("Secret concatenated") end, __tostring = function() error("Secret formatted") end })
local combat, streamer, preview, region, reads, creates = false, false, false, 3, 0, 0
local BFL = { L = {}, modules = {}, IsMainline = true }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale() end
function BFL:IsSecret(value) return rawequal(value, secret) end
BFL.DebugPrint = function() end
BFL.StreamerMode = { IsActive = function() return streamer end }
BFL.modules.PreviewMode = { IsComponentEnabled = function() return preview end }
local callbacks = {}
function BFL:RegisterEventCallback(event, callback) callbacks[event] = callback end
local env = setmetatable({ BFL = BFL, BFL_LOCALE_ENUS = BFL.L, BetterFriendlistDB = {}, WOW_PROJECT_ID = 1,
	GetCurrentRegion = function() reads = reads + 1; return region end,
	GetServerTime = function() reads = reads + 1; return 1700000000 end,
	InCombatLockdown = function() return combat end, date = os.date, CANCEL = "Cancel",
	C_PartyInfo = setmetatable({}, { __index = function() error("Protected social action requested") end }),
}, { __index = _G })
env._G = env
local function execute(source, label) return assert(load(source, "@" .. label, "t", env))("BetterFriendlist", BFL) end
execute(read("Locales/enUS.lua"), "locales")
local known = execute(read("Modules/KnownCharacters.lua"), "KnownCharacters")
known:Initialize()
local friend = { type = "bnet", battleTag = "Ada#1234", bnetAccountID = 42 }
local function game(name, realm)
	return { characterName = name or "Ada", realmName = realm or "Home", isOnline = true,
		clientProgram = "WoW", wowProjectID = env.WOW_PROJECT_ID, regionID = region }
end
local account = { battleTag = "Ada#1234", bnetAccountID = 42, gameAccountInfo = game() }
check(not known:IsEnabled(), "Feature defaults off")
known:ObserveAccount(account)
check(not known:AddManual(friend, "Other-Home"), "Disabled features reject edits")
equal(known:GetTooltipLines(friend), nil, "Disabled features add no tooltip data")
equal(next(env.BetterFriendlistDB), nil, "Disabled features do not create private records")
equal(reads, 0, "Disabled features issue no metadata reads")
check(known:SetSetting("enabled", true), "Feature enables explicitly")
check(not known:AddManual(friend, "OnlyName"), "Unqualified names never guess a realm")
for _, name in ipairs({ secret, "Name|Hlink-Home", "Name\n-Home", "Name:Home", string.rep("x", 129) }) do
	check(not known:AddManual(friend, name), "Unreadable, encoded or oversized names are rejected")
end
check(known:AddManual(friend, "Manual-Black Rock"), "Manual realm-qualified identities are accepted")
check(known:AddManual(friend, "manual-BlackRock"), "Manual entries deduplicate canonical identities")
equal(#known:GetEntries(friend), 1, "Case/realm-space variants do not duplicate characters")
known:ObserveAccount(account)
equal(#known:GetEntries(friend), 1, "Automatic observation remains separately opt-in")
known:SetSetting("observeBattleNet", true)
known:ObserveAccount(account, { game("Other", "Home") })
equal(#known:GetEntries(friend), 2, "Independently indexed game-account rows are never treated as association proof")
known:ObserveAccount({ battleTag = "Ada#1234", gameAccountInfo = game("Other", "Home") })
equal(#known:GetEntries(friend), 3, "A later atomic primary snapshot adds another observed character")
local text = table.concat(known:GetTooltipLines(friend), "\n")
check(text:find("manual", 1, true) and text:find("last observed", 1, true), "Manual and dated observed sources remain distinct")
local nativeName = account.gameAccountInfo.characterName
equal(nativeName, "Ada", "Native game snapshots stay untouched")
known:AddManual(friend, "Ada-Home")
known:ObserveAccount(account)
local manualFound = false
for _, entry in ipairs(known:GetEntries(friend)) do if entry.name == "Ada-Home" then manualFound = entry.source == "manual" end end
check(manualFound, "Observation never overwrites an explicit manual source")
for _, invalid in ipairs({ secret, {}, { battleTag = secret, gameAccountInfo = game() },
	{ battleTag = "", bnetAccountID = 42, gameAccountInfo = game() },
	{ battleTag = "Ada#1234", gameAccountInfo = secret }, { _isMock = true, battleTag = "Ada#1234", gameAccountInfo = game("Fake") } }) do
	known:ObserveAccount(invalid)
end
equal(#known:GetEntries(friend), 3, "Secret snapshots and session-ID-only identities cannot authorize observation")
for _, field in ipairs({ "isOnline", "clientProgram", "characterName", "realmName", "regionID", "wowProjectID" }) do
	local bad = game("Hidden"); bad[field] = secret
	known:ObserveAccount({ battleTag = "Ada#1234", gameAccountInfo = bad })
end
local otherProject, otherRegion = game("WrongProject"), game("WrongRegion")
otherProject.wowProjectID, otherRegion.regionID = 2, 5
known:ObserveAccount(account, { otherProject, otherRegion })
equal(#known:GetEntries(friend), 3, "Secret and cross-region/project identities never enter current-client associations")
local hidden = game("HiddenOffline"); hidden.isAppearOffline = true
known:ObserveAccount({ battleTag = "Ada#1234", gameAccountInfo = hidden })
known:ObserveAccount({ battleTag = "Ada#1234", appearOffline = true, gameAccountInfo = game("HiddenAccount") })
known:ObserveAccount({ battleTag = "Ada#1234", isFriend = false, gameAccountInfo = game("RemovedFriend") })
equal(#known:GetEntries(friend), 3, "Appear-offline and explicitly non-friend snapshots are not observed")
local getTime, getRegion = env.GetServerTime, env.GetCurrentRegion
env.GetServerTime = function() return secret end
known:ObserveAccount({ battleTag = "Ada#1234", gameAccountInfo = game("SecretTime") })
env.GetServerTime = function() error("Unavailable clock") end
known:ObserveAccount({ battleTag = "Ada#1234", gameAccountInfo = game("ErrorTime") })
env.GetServerTime = getTime
env.GetCurrentRegion = function() return secret end
known:ObserveAccount(account)
equal(known:ResolveIdentity(friend), nil, "Secret region results never enter identity formatting")
env.GetCurrentRegion = getRegion
equal(#known:GetEntries(friend), 3, "Unusable time/region APIs cannot create an association")
local active = BFL.StreamerMode.IsActive
BFL.StreamerMode.IsActive = function() return secret end
equal(known:GetTooltipLines(friend), nil, "An unreadable privacy state fails closed")
BFL.StreamerMode.IsActive = function() error("Privacy unavailable") end
equal(known:GetTooltipLines(friend), nil, "Privacy API errors do not expose private characters")
BFL.StreamerMode.IsActive = active
for i = 1, 17 do check(known:AddManual(friend, "Alt" .. i .. "-Home"), "Manual entries fit within the bounded contact") end
check(not known:AddManual(friend, "Overflow-Home"), "Character storage is capped at 20")
equal(#known:GetEntries(friend), 20, "A full contact stays bounded")
known:SetSetting("maxTooltipCharacters", 3)
equal(#known:GetTooltipLines(friend), 5, "Tooltip has a title, three entries and a bounded remainder count")
known:SetSetting("maxTooltipCharacters", 100)
equal(#known:GetTooltipLines(friend), 12, "Tooltip limits clamp to ten")
check(not known:SetSetting("maxTooltipCharacters", secret) and not known:SetSetting("enabled", secret), "Secret settings never enter comparison or storage")
region = 5; equal(#known:GetEntries(friend), 0, "Regions have separate identity scopes"); region = 3
env.WOW_PROJECT_ID = 2; equal(#known:GetEntries(friend), 0, "Classic and Retail identities stay separate"); env.WOW_PROJECT_ID = 1
streamer = true
local previousReads = reads
known:ObserveAccount(account)
equal(#known:GetEntries(friend), 0, "Streamer Mode hides private associations")
check(not known:AddManual(friend, "Blocked-Home"), "Streamer Mode blocks edits")
equal(reads, previousReads, "Streamer Mode prevents new observations before metadata reads")
streamer, preview = false, true
known:ObserveAccount(account); equal(known:GetTooltipLines(friend), nil, "Preview data never becomes private observed history")
preview = false
combat = true
check(not known:AddManual(friend, "Combat-Home"), "No combat-time manual editor mutations")
check(not known:ShowDialog(friend), "Combat never opens or queues an editor")
known:ObserveAccount(account)
check(known:GetTooltipLines(friend) ~= nil, "Read-only local tooltips remain usable in combat")
equal(creates, 0, "Combat needs no frame creation")
combat = false
known:Remove(friend, "Ada-Home")
known:ObserveAccount(account)
equal(#known:GetEntries(friend), 19, "Removing an observation blocks automatic re-addition")
known:ClearContact(friend); known:ObserveAccount(account)
equal(#known:GetEntries(friend), 0, "Forgetting a contact remains effective across native events")
known:ClearAll()
check(not known:GetStore(false).observeBattleNet, "Deleting all data revokes automatic-observation consent")
equal(next(known:GetStore(false).contacts), nil, "Deleting all data removes all links and tombstones")
known:SetSetting("observeBattleNet", true)
local hoveredFriend = { type = "bnet", battleTag = "Hover#1234", knownCharacterPrimary = game("Hovered"), gameAccountInfo = game("UnverifiedPreferred") }
check(known:GetTooltipLines(hoveredFriend) ~= nil, "Opted-in hovering can use the existing native snapshot immediately, without a refresh request")
local hoveredEntries = known:GetEntries(hoveredFriend)
equal(#hoveredEntries, 1, "A preferred-account selection cannot inject an extra observed identity")
equal(hoveredEntries[1].name, "Hovered-Home", "Hover observation uses only the captured atomic primary character")
known:ClearAll()

local main = { type = "wow", name = "Main-Home" }
local alt = { type = "wow", name = "Alt-Home" }
check(known:AddManual(main, "Alt-Home"), "WoW-only contacts support explicit links without Battle.net")
equal(#known:GetEntries(alt), 2, "An explicitly linked character can resolve its known group")
known:AddManual({ battleTag = "Other#5678" }, "Alt-Home")
equal(#known:GetEntries(alt), 0, "Ambiguous reverse matches never guess the owning contact")
known:ClearAll()
BFL.IsForever = true; env.WOW_PROJECT_ID = 18
BFL.AreRegionalUniqueNamesEnabled = function() return true end
check(known:AddManual({ type = "wow", name = "Ada-Lovelace" }, "Other Surname"), "Forever accepts regional full-name identities")
equal(#known:GetEntries({ type = "wow", name = "Ada Lovelace" }), 2, "Forever surname separators normalize without inventing a realm")
BFL.IsForever = false; env.WOW_PROJECT_ID = 1
BFL.AreRegionalUniqueNamesEnabled = function() return false end
known:ClearAll()

-- Real addon-owned editor/menu callbacks, with secure/native frame mutations forbidden.
local function widget()
	local object = { scripts = {}, shown = false, text = "" }
	for _, method in ipairs({ "SetSize", "SetWidth", "SetFrameStrata", "SetClampedToScreen", "SetJustifyH", "SetAutoFocus", "SetMaxLetters", "SetFocus", "ClearFocus" }) do object[method] = function() end end
	function object:SetPoint(_, relative) check(relative ~= env.FriendsTooltip, "Editor never anchors to a native/protected tooltip") end
	function object:SetText(value) self.text = value end
	function object:GetText() return self.text end
	function object:CreateFontString() return widget() end
	function object:SetScript(event, callback) self.scripts[event] = callback end
	function object:Show() self.shown = true end
	function object:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
	function object:SetShown(value) self.shown = value end
	function object:SetAttribute() error("Protected attribute mutation") end
	return object
end
env.UIParent = {}
env.CreateFrame = function(kind, name, parent, template)
	check(not combat, "Editor creation stays outside combat")
	check(template ~= "SecureActionButtonTemplate", "Editor has no secure action template")
	creates = creates + 1
	local object = widget(); object.parent = parent
	if kind == "Frame" then equal(parent, env.UIParent, "Editor parent is independent UIParent"); object.TitleText, object.CloseButton = widget(), widget() end
	return object
end
check(known:ShowDialog(friend), "The manual editor opens outside combat")
known.dialog.editBox:SetText("Editor-Home")
known.dialog.save.scripts.OnClick()
equal(#known:GetEntries(friend), 1, "Editor Save links only local data")
equal(known.dialog.editBox.text, "", "Closing erases typed identity text")
check(not known.dialog.shown and known.dialog.friend == nil, "Closing discards the captured contact")
local linked = { type = "wow", name = "Editor-Home" }
local linkedRoot = { CreateButton = function(self, _, callback) self.callback = callback end }
check(known:PopulateMenu(linkedRoot, linked), "A linked WoW character can manage the existing Battle.net group")
local linkedItems
BFL.OpenSimpleContextMenu = function(_, _, items) linkedItems = items end
linkedRoot.callback(); linkedItems[2].func()
known.dialog.editBox:SetText("LinkedAgain-Home"); known.dialog.save.scripts.OnClick()
equal(#known:GetEntries(friend), 2, "The editor preserves a stable BattleTag even when entered via a WoW reverse match")
known:ShowDialog(friend); combat = true; callbacks.PLAYER_REGEN_DISABLED()
check(not known.dialog.shown, "Combat entry hides only the addon-owned editor")
combat = false
local root = { CreateButton = function(self, _, callback) self.callback = callback end }
check(known:PopulateMenu(root, friend), "Own friend menus expose known characters")
local menuBlock = between(read("BetterFriendlist.lua"), '\t\t\t\tlocal KnownCharacters = BFL:GetModule("KnownCharacters")', '\t\t\t\tlocal ContactMemory = BFL:GetModule("ContactMemory")')
env.isOwnMenu, env.friendData = false, secret
env.rootDescription = setmetatable({}, { __index = function() error("Native/protected menu mutated") end })
execute(menuBlock, "Native menu exclusion")
env.isOwnMenu = true
execute(menuBlock, "Opaque own-menu snapshot exclusion")
env.friendData, env.rootDescription = friend, root
root.callback = nil
execute(menuBlock, "Own-menu integration")
check(root.callback ~= nil, "The real BFL menu integration appends known characters only for own readable contexts")
local items
BFL.OpenSimpleContextMenu = function(_, _, value) items = value end
root.callback()
equal(items[2].text, BFL.L.KC_ADD, "Menu contains an explicit Link action")
streamer = true
items[2].func()
check(not known.dialog.shown, "A stale menu cannot reopen private UI after Streamer Mode activates")
streamer = false
-- The actual StreamerMode entry point must scrub an already-open editor and
-- addon-owned tooltip text, not merely prevent future additions.
known:ShowDialog(friend)
env.FriendsTooltip = { KnownCharacterLines = { widget(), widget() } }
for _, line in ipairs(env.FriendsTooltip.KnownCharacterLines) do line:SetText("Private"); line:Show() end
local ownMenuClosed, classicMenuClosed = 0, 0
local ownMenu = { GetOwnerRegion = function() return known.menuOwner end,
	Close = function() ownMenuClosed = ownMenuClosed + 1 end }
env.Menu = { GetManager = function() return { GetOpenMenu = function() return ownMenu end } end }
env.BFLKnownCharactersMenu = {}
env.UIDROPDOWNMENU_OPEN_MENU = env.BFLKnownCharactersMenu
env.CloseDropDownMenus = function() classicMenuClosed = classicMenuClosed + 1 end
env.StreamerMode = BFL.StreamerMode
local streamerSource = read("Modules/StreamerMode.lua")
local streamerStart = assert(streamerSource:find("function StreamerMode:UpdateState()", 1, true))
execute(streamerSource:sub(streamerStart), "Streamer privacy callback")
streamer = true; env.StreamerMode:UpdateState()
check(not known.dialog.shown, "Actual StreamerMode state changes close the editor")
equal(ownMenuClosed, 1, "Streamer Mode closes its own character-management menu through the public menu API")
equal(classicMenuClosed, 1, "Streamer Mode closes only its own legacy dropdown")
check(not known.menuOwner.shown, "Streamer Mode hides the addon-owned menu owner")
ownMenu.GetOwnerRegion = function() return env.UIParent end
env.UIDROPDOWNMENU_OPEN_MENU = {}
known:HideSurfaces()
equal(ownMenuClosed, 1, "Closing private surfaces never touches a foreign modern menu")
equal(classicMenuClosed, 1, "Closing private surfaces never touches a foreign Classic dropdown")
for _, line in ipairs(env.FriendsTooltip.KnownCharacterLines) do check(not line.shown and line.text == "", "Actual StreamerMode state changes scrub visible addon-owned character lines") end
streamer = false
known:SetSetting("enabled", false)
check(known:ShowDialog(nil, true), "Private data can be erased even with the feature disabled")
known.dialog.save.scripts.OnClick()
equal(next(known:GetStore(false).contacts), nil, "The real confirmation callback forgets all data")

local controls, groups = {}, {}
known:RegisterSettingsDesignerControls({ RegisterGroup = function(_, _, data) groups[data.id] = data end,
	RegisterControl = function(_, _, data) controls[data.id] = data end })
equal(controls["knownCharacters.enabled"].default, false, "Settings have an opt-in master toggle")
equal(controls["knownCharacters.observeBattleNet"].default, false, "Observation has a separate opt-in control")
for _, control in pairs(controls) do
	check(not control.key and control.getValue ~= nil or control.type == "button", "Nested settings use callbacks, not dotted DB keys")
	equal(control.groupTitle, BFL.L.KC_TITLE, "Every control preserves its localized section title")
end
controls["knownCharacters.enabled"].setValue(true)
check(known:IsEnabled(), "The production settings setter enables the feature")
-- The legacy settings UI is the default, so configuration cannot depend on
-- enabling Settings Center beta. Exercise its real registration and callbacks.
known:SetSetting("enabled", false)
known:SetSetting("maxTooltipCharacters", 3)
local legacy, frames, parent = {}, {}, {}
local function component(kind, host, config)
	equal(host, parent, "Legacy controls stay inside the addon-owned settings host")
	local control = config or {}; control.kind = kind
	legacy[#legacy + 1] = control
	return control
end
local components = {
	CreateSpacer = function(_, host) return component("spacer", host) end,
	CreateHeader = function(_, host, text) return component("header", host, { text = text }) end,
	CreateCheckbox = function(_, host, config) return component("toggle", host, config) end,
	CreateSlider = function(_, host, text, min, max, initial, formatter, callback)
		return component("slider", host, { label = text, min = min, max = max, initialValue = initial,
			formatter = formatter, callback = callback, SetStep = function(self, step) self.step = step end })
	end,
	CreateButton = function(_, host, text, callback, tooltip)
		return component("button", host, { label = text, callback = callback, tooltip = tooltip })
	end,
}
local oldReads, oldCreates = reads, creates
known:RegisterLegacyControls(parent, components, frames)
equal(reads, oldReads, "Rendering legacy settings performs no native account/metadata reads")
equal(creates, oldCreates, "Registration uses existing settings components, never the manual editor")
equal(#frames, 6, "Legacy settings expose the complete section")
equal(legacy[2].text, BFL.L.KC_TITLE, "Legacy section has a localized title")
equal(legacy[3].initialValue, false, "Legacy master reflects opt-in state")
equal(legacy[4].initialValue, false, "Legacy observation remains independently opt-in")
equal(legacy[5].step, 1, "Legacy tooltip limits use integer steps")
equal(legacy[5].initialValue, 3, "Legacy tooltip limit starts at three")
local originalRefresh = BFL.ForceRefreshFriendsList
BFL.ForceRefreshFriendsList = function() error("Local settings must not trigger protected/layout refreshes") end
combat = true
legacy[3].callback(true); legacy[4].callback(true); legacy[5].callback(7)
check(known:IsEnabled(), "Legacy master callback enables local state even in combat")
equal(known:GetStore(false).maxTooltipCharacters, 7, "Legacy limit callback persists the requested integer")
equal(known:GetStore(false).observeBattleNet, true, "Legacy observation callback changes only explicit consent")
legacy[5].callback(secret)
equal(known:GetStore(false).maxTooltipCharacters, 7, "Legacy callbacks reject opaque settings values")
legacy[6].callback()
check(not known.dialog.shown, "Legacy erase confirmation cannot open in combat")
combat = false
legacy[6].callback(); known.dialog.save.scripts.OnClick()
equal(known:GetStore(false).observeBattleNet, false, "Legacy erase callback revokes automatic observation")
BFL.ForceRefreshFriendsList = originalRefresh
local legacyIntegration = between(read("Modules/Settings.lua"), '\tlocal KnownCharacters = BFL:GetModule("KnownCharacters")\n', '\tComponents:AnchorChain(allFrames, -5)')
env.tab, env.Components, env.allFrames = parent, components, {}
execute(legacyIntegration, "Legacy settings integration")
equal(#env.allFrames, 6, "The default settings tab actually registers the known-character section")
known:SetSetting("maxTooltipCharacters", 3)
known:SetSetting("observeBattleNet", true)
known:ObserveAccount(account)
known:ClearContact(friend)
local resumeRoot = { CreateButton = function(self, _, callback) self.callback = callback end }
known:PopulateMenu(resumeRoot, friend); resumeRoot.callback()
local resume
for _, item in ipairs(items) do if item.text == BFL.L.KC_RESUME then resume = item.func end end
check(resume ~= nil, "A blocked contact exposes an explicit observation-resume action")
resume(); known:ObserveAccount(account)
equal(#known:GetEntries(friend), 1, "Only an explicit resume allows a forgotten contact to be observed again")
known:ClearAll()

-- Bounded cleanup of malformed/SavedVariables data before it becomes visible.
local store = known:GetStore(false)
store.contacts = { ["b:wow:1:3:ada#1234"] = { characters = {
	{ name = "Readable-Home", source = "manual" }, secret, { name = secret, source = "manual" },
	{ name = "Hidden-Home", source = secret }, { name = "HiddenTime-Home", source = "observed", lastSeen = secret },
} }, ["b:wow:1:3:not-a-stable-tag"] = { characters = {} } }
known.validatedStore = nil
equal(#known:GetEntries(friend), 1, "Malformed loaded sources, names and timestamps are dropped before tooltip use")
check(known:GetStore(false).contacts["b:wow:1:3:not-a-stable-tag"] == nil, "Loaded owner keys must contain a stable valid identity")
known:ClearAll()
store = known:GetStore(false)
for i = 1, 250 do
	local characters = {}
	for j = 1, 25 do characters["x" .. j] = { name = "Character" .. j .. "-Home", source = "manual" } end
	store.contacts["b:wow:1:3:tag" .. i .. "#1234"] = { characters = characters }
end
known.validatedStore = nil
store = known:GetStore(false)
local count = 0
for _, group in pairs(store.contacts) do
	count = count + 1
	local size = 0; for _ in pairs(group.characters) do size = size + 1 end
	check(size <= 20, "Loaded character collections are bounded")
end
check(count <= 200, "Loaded contacts are capped at 200")
known:ClearContact({ battleTag = "Unrecorded#9999" })
local afterCount = 0; for _ in pairs(store.contacts) do afterCount = afterCount + 1 end
check(afterCount <= 200, "Forgetting an unknown contact cannot create unbounded suppression tombstones")

-- Run actual export/import source: private data is excluded BEFORE deep-copy,
-- and a foreign profile cannot inject links or enable automatic collection.
env.Settings, env.L = {}, BFL.L
local copied, serialized
local db = { InternalDeepCopy = function(_, value) check(value.knownCharacters == nil, "Private data is excluded before deep-copy"); copied = value; return value end }
env.GetDB = function() return db end
env.Settings.SerializeTable = function(_, value) serialized = value; return "payload" end
env.Settings.EncodeString = function(_, value) return value end
execute(between(read("Modules/Settings.lua"), "function Settings:ExportSettings()", "-- Import settings from string"), "Profile export")
env.Settings:ExportSettings()
check(copied and serialized and serialized.knownCharacters == nil, "Exported profiles contain no private associations or collection preferences")
local privateStore = env.BetterFriendlistDB.knownCharacters
env.importData = { exportVersion = 3, knownCharacters = { enabled = true, observeBattleNet = true, contacts = { stolen = true } }, harmless = 7 }
env.wipe = function(value) for key in pairs(value) do value[key] = nil end end
execute(between(read("Modules/Settings.lua"), "\t-- Handle V3 (Everything)", "\telse\n\t\t-- Legacy V1/V2 Import Logic") .. "\nend", "Profile import privacy boundary")
equal(env.BetterFriendlistDB.knownCharacters, privateStore, "Profile import preserves local private data instead of replacing it")
check(privateStore.observeBattleNet == false, "A foreign profile cannot silently grant observation consent")
equal(env.BetterFriendlistDB.harmless, 7, "Normal profile imports remain functional")
io.write("[OK] Known characters smoke: " .. assertions .. " assertions (production module/callbacks, mocked engine; live taint QA required)\n")
