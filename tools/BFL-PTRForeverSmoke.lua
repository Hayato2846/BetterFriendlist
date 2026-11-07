-- Lua 5.4: lua tools/BFL-PTRForeverSmoke.lua <repo>
-- Runs production guards, normalization, query storage and UI callbacks.
-- Secret sentinels are regressions checks, not proof of Blizzard secure access.
local repo = assert(arg[1], "repository root required")
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local content = file:read("*a"); file:close(); return content
end
local function between(source, first, last)
	local start = assert(source:find(first, 1, true), first)
	local finish = assert(source:find(last, start + #first, true), last)
	return source:sub(start, finish - 1)
end
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function equal(actual, expected, message) check(actual == expected, message) end
local secret = setmetatable({}, {
	__index = function() error("secret indexed") end,
	__tostring = function() error("secret formatted") end,
	__concat = function() error("secret concatenated") end,
	__lt = function() error("secret compared") end,
	__sub = function() error("secret subtracted") end,
})
local restricted, inCombat, mutationCount = false, false, 0
local BFL = { modules = {}, L = {}, IsRetail = true, IsMainline = true }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale() end
function BFL:IsSecret(value) return rawequal(value, secret) end
function BFL:IsActionRestricted() return restricted end
function BFL:IsGameRuleActive() return false end
local env = setmetatable({ BFL = BFL, BFL_LOCALE_ENUS = BFL.L, SlashCmdList = {},
	InCombatLockdown = function() return inCombat end,
	UNKNOWN = "Unknown", UNKNOWNOBJECT = "Unknown object", GetServerTime = function() return 1000 end,
	SecondsToTime = function(seconds) return tostring(seconds) .. "s" end,
	Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 } },
	C_FriendList = {}, C_PartyInfo = {}, C_BattleNet = {},
	UnitExists = function(unit) return unit == "raid1" end,
	UnitFullName = function() return "Ada", "OtherRealm" end,
	GetNormalizedRealmName = function() return "MyRealm" end,
}, { __index = _G })
env._G = env
local function execute(source, label) return assert(load(source, "@" .. label, "t", env))("BetterFriendlist", BFL) end
execute(read("Locales/enUS.lua"), "locales")
execute(read("Utils/ClassicCompat.lua"), "compatibility")

local lfgUnlocked = false
env.C_SocialQueue = { IsSystemSupported = function() return true end, IsSystemEnabled = function() return true end }
env.Enum.PremadeGroupFinderStyle = { Vanilla = 1 }
env.C_LFGList = { GetPremadeGroupFinderStyle = function() return 1 end }
env.C_LFGInfo = {
	CanPlayerUseGroupFinder = function() return true end,
	CanPlayerUsePremadeGroup = function() return lfgUnlocked, "Requires level 10" end,
}
check(BFL.IsSocialQueueEnabled(), "Mainline without the Forever gate keeps its own Quick Join availability")
BFL.IsForever = true
local canUse, reason = BFL.GetQuickJoinGroupFinderAccess()
check(not canUse and reason == "Requires level 10", "Forever uses the native premade gate and localized reason")
check(not BFL.IsSocialQueueEnabled(), "The Forever social queue is hidden while Group Finder is locked")
lfgUnlocked = true
check(BFL.IsSocialQueueEnabled(), "Forever Quick Join becomes available when the native gate opens")
env.C_LFGList.GetPremadeGroupFinderStyle = function() return 2 end
env.C_LFGInfo.CanPlayerUseGroupFinder = function() return secret end
check(not BFL.IsSocialQueueEnabled(), "Unreadable Group Finder availability fails closed")
env.C_SocialQueue, env.C_LFGList, env.C_LFGInfo, BFL.IsForever = nil, nil, nil, nil

execute(read("Modules/GuildRosterData.lua"), "guild roster")
local guildRoster = BFL:GetModule("GuildRosterData")
local protectedTable = setmetatable({}, {
	__index = function() error("protected table read") end,
})
local clubMemberIDs = secret
local clubLookups = 0
env.issecrettable = function(value) return rawequal(value, protectedTable) end
env.C_Club = {
	GetGuildClubId = function() return 10 end,
	GetClubMembers = function() return clubMemberIDs end,
	GetMemberInfo = function(_, id)
		clubLookups = clubLookups + 1
		if id == 1 then
			return protectedTable
		end
		return { name = "Ada-OtherRealm", guid = secret, memberId = secret, profession1ID = 164 }
	end,
}
BFL.HasSecretValues = true
local guildMembers = { { fullName = "Ada-OtherRealm", name = "Ada", guid = "" } }
equal(guildRoster:EnrichRosterWithClubInfo(guildMembers), guildMembers, "Secret club list preserves the base roster")
check(guildMembers[1].clubId == nil and guildRoster.clubMemberSnapshotCache == nil,
	"Secret club list is skipped without caching a failed snapshot")
clubMemberIDs = protectedTable
check(guildRoster:GetClubMemberSnapshot() == nil, "Tables with protected contents cannot be iterated")
clubMemberIDs = { secret, 1, 2 }
guildRoster:EnrichRosterWithClubInfo(guildMembers)
equal(clubLookups, 2, "Only readable member IDs are passed to the club API")
equal(guildMembers[1].memberId, 2, "A secret profile member ID falls back to the readable list ID")
equal(guildMembers[1].profession1ID, 164, "A readable profile still enriches the roster")
equal(guildMembers[1].guid, "", "A secret profile GUID stays out of the roster")
env.C_Club, env.issecrettable, BFL.HasSecretValues = nil, nil, nil

local dropdown = {
	SetupMenu = function() end,
	SetSelectionText = function(self, callback) self.selectionText = callback end,
	SetSelectionTranslator = function() error("A combined filter must not use per-selection translation") end,
}
BFL.InitializeDropdown(dropdown, { getCombinedSelectionText = function() return "Online" end })
equal(dropdown.selectionText({ { data = "online" }, { data = "all_professions" } }), "Online",
	"The guild dropdown summarizes the complete selection once")

check(BFL.IsRaidListSupported() and BFL.IsRaidListEnabled() and BFL.CanPromoteToLeader(), "Older clients retain existing capabilities")
for _, key in ipairs({ "IsRaidListSupported", "IsRaidListEnabled", "CanPromoteToLeader" }) do
	env.C_PartyInfo[key] = function() return false end
	check(not BFL[key](), key .. " respects disabled state")
	env.C_PartyInfo[key] = function() return secret end
	check(not BFL[key](), key .. " rejects secret state")
	env.C_PartyInfo[key] = function() error("unavailable") end
	check(not BFL[key](), key .. " fails closed on API error")
	env.C_PartyInfo[key] = function() return true end
end
env.C_BattleNet.AreRealIDFriendsEnabled = function() return false end
check(not BFL.AreRealIDFriendsEnabled(), "Modern Real ID capability wins")
env.C_BattleNet.AreRealIDFriendsEnabled = nil
env.BNGetInfo = function() return nil, nil, nil, nil, nil, nil, true end
check(BFL.AreRealIDFriendsEnabled(), "Legacy Real ID uses the seventh return")
equal(BFL.GetBNetFriendLevelLabel(secret), nil, "Secret levels have no badge")
equal(BFL.GetBNetFriendLevelLabel(999), nil, "Unknown levels are not guessed")
equal(BFL.GetBNetFriendLevelLabel(3), BFL.L.FRIEND_TYPE_WOW, "Title friends have the WoW badge")
check(not BFL.IsTitleFriend(secret), "A secret account is never indexed for Title metadata")
for _, entry in ipairs({ { accountInfo = secret }, { friendLevel = secret },
	{ friendLevel = 3, connected = secret }, { friendLevel = 3, isOnline = secret },
	{ friendLevel = 3, gameAccountInfo = secret }, { friendLevel = 3, gameAccountInfo = { isOnline = secret } } }) do
	check(not BFL.IsOfflineTitleFriend(entry), "Unreadable Title metadata never enters offline comparisons")
end
check(BFL.IsOfflineTitleFriend({ friendLevel = 3, gameAccountInfo = { isOnline = false } }), "Readable offline Title metadata remains available")
local lastName
local function mutate(name) mutationCount = mutationCount + 1; lastName = name end
for _, key in ipairs({ "PromoteToLeader", "PromoteToAssistant", "DemoteAssistant", "ConvertToRaid", "ConvertToParty", "InviteUnit" }) do env.C_PartyInfo[key] = mutate end
env.C_BattleNet.SetBlocked = mutate
local function attemptActions()
	BFL.PromoteToLeader("raid1"); BFL.PromoteToAssistant("raid1"); BFL.DemoteAssistant("raid1")
	BFL.ConvertToRaid(); BFL.ConvertToParty(); BFL.SetBNetBlocked(42, true)
end
inCombat = true; attemptActions(); equal(mutationCount, 0, "Combat prevents restricted social mutations")
inCombat, restricted = false, true; attemptActions(); equal(mutationCount, 0, "Active addon restrictions prevent mutations")
restricted = false
env.C_PartyInfo.CanPromoteToLeader = function() return false end
check(not BFL.PromoteToLeader("raid1"), "Leader promotion checks permission at execution")
equal(mutationCount, 0, "Denied promotion never invokes the mutation")
env.C_PartyInfo.CanPromoteToLeader = function() return true end
check(BFL.PromoteToLeader("raid1"), "Explicit unrestricted promotion remains callable")
equal(lastName, "Ada-OtherRealm", "Promotion preserves the exact cross-realm identity")
local before = mutationCount
BFL.PromoteToLeader(secret); BFL.PromoteToAssistant(secret); BFL.DemoteAssistant(secret)
BFL.SetBNetBlocked(secret, true); BFL.SetBNetBlocked(42, secret); BFL.InviteUnit(secret)
equal(mutationCount, before, "Secret action arguments never reach a C API")
env.UnitFullName = function() return secret, "Realm" end
check(not BFL.PromoteToLeader("raid1"), "Secret unit lookup fails closed")
equal(mutationCount, before, "Secret unit names cannot be promoted")
env.UnitFullName = function() return "Ada", "OtherRealm" end
local unitExists = env.UnitExists
for _, lookup in ipairs({ function() return secret end, function() error("lookup unavailable") end, function() return nil end }) do
	env.UnitExists = lookup
	check(not BFL.PromoteToLeader("raid1"), "Unreadable unit existence must not become a raw unit-token mutation")
end
env.UnitExists = unitExists
BFL.SetBNetBlocked(0, true); BFL.SetBNetBlocked(-1, true); BFL.SetBNetBlocked(0/0, true); BFL.SetBNetBlocked(math.huge, true)
equal(mutationCount, before, "Invalid account IDs never reach the native setter")
inCombat = true
check(BFL.InviteUnit("Ada"), "Readable invite targets keep the existing combat-capable API path")
inCombat = false
before = mutationCount

env.FriendTags = {}
env.IsSecret = function(value) return BFL:IsSecret(value) end
local tagsDB = { friendBlizzardTags = {} }
function env.FriendTags:GetFriendUID() return "bnet_42" end
function env.FriendTags:BuildSupportedBlizzardTagPayload() return { raiding = true }, { 1 } end
function env.FriendTags:NormalizeDB() return tagsDB end
function env.FriendTags:AreBlizzardTagsEnabled() return true end
env.CopySet = function(value) local result = {}; for k, v in pairs(value) do result[k] = v end; return result end
env.RefreshFriendAssignment = function() end
env.C_BattleNet.SetFriendTags = mutate
local tagSource = read("Modules/FriendTags.lua")
execute(between(tagSource, "function FriendTags:TrackPendingBlizzardTags(", "function FriendTags:GetBlizzardTagIdSetForFriend(")
	.. between(tagSource, "function FriendTags:SetBlizzardTagsForFriend(", "function FriendTags:GetLocalBlizzardHandoffInfo("), "Native tag mutation")
check(not env.FriendTags:SetBlizzardTagsForFriend({ type = "bnet", bnetAccountID = secret }, {}, { userInitiated = true }), "Secret tag account IDs are rejected before identity lookup")
check(not env.FriendTags:SetBlizzardTagsForFriend({ type = "bnet", bnetAccountID = 42 }, {}, {}), "Native tags require the existing explicit-user gate")
equal(mutationCount, before, "Rejected tag changes do not call the C API")
check(env.FriendTags:SetBlizzardTagsForFriend({ type = "bnet", bnetAccountID = 42 }, {}, { userInitiated = true }), "Readable user-initiated tags keep their native API path")
equal(mutationCount, before + 1, "A valid tag change invokes the mutation once")
before = mutationCount

-- The complete module loads with APIs absent on Classic as well.
env.LOCALIZED_CLASS_NAMES_MALE, env.LOCALIZED_CLASS_NAMES_FEMALE = {}, {}
local who = execute(read("Modules/WhoFrame.lua"), "WhoFrame")
local calls = {}
who._testFriendListAPI = { GetWhoRaceFilters = function() return {} end,
	SendWho = function(...) calls[#calls + 1] = table.pack(...) end }
check(not who:HasStructuredWhoFilters(), "API presence cannot enable addon-created structured filters")
check(who:DispatchWhoRequest("Ada", 1, { classIDs = { 1 } }), "Text dispatch remains available")
equal(calls[1].n, 2, "Production dispatch keeps the proven two-argument signature")
check(not who:DispatchWhoRequest(secret, 1), "Secret Who input is rejected")
equal(#calls, 1, "Rejected input performs no request")
local testAPI = who._testFriendListAPI
who._testFriendListAPI = nil
local productionCall
env.C_FriendList.SendWho = function(...) productionCall = table.pack(...) end
check(who:DispatchWhoRequest("Ada", 1, { classIDs = { 1 } }), "The non-test production dispatch remains callable")
equal(productionCall.n, 2, "The real C API path also excludes restricted structured payloads")
who._testFriendListAPI = testAPI
local originalAvailable = who.IsAvailable
who.IsAvailable = function() return true end
env.GetTime = function() return 100 end
env.UnitLevel, env.GetRealZoneText, env.GetMaxPlayerLevel = function() return 80 end, function() return secret end, function() return 80 end
inCombat = true
check(not who:SendWhoRequest("Ada", 1), "Restricted Who clicks are rejected before setting pending state")
inCombat = false
check(not who:SendWhoRequest(secret, 1) and not who:SendWhoRequest({}, 1), "Unreadable Who requests are rejected at the boundary")
check(not who.whoPending, "Rejected Who requests never start a stale spinner")
check(not who:SendWhoRequest("", 1), "Generated default queries also reject secret zone metadata")
check(not who.whoPending, "An unreadable default query cannot suspend native listeners or start pending state")
who.IsAvailable = originalAvailable
who.builder = { selectedClass = "Mage", selectedRace = "Human", selectedClasses = { Mage = true }, selectedRaces = { Human = true } }
local query, filters = who:BuildBuilderRequest()
check(query:find('c-"Mage"', 1, true) and query:find('r-"Human"', 1, true), "Text fallback retains every selected filter")
equal(filters, nil, "Text fallback never silently drops filters into a restricted payload")

local values = { whoSearchHistoryEnabled = true, whoSearchHistoryMax = 3 }
local db = BFL:RegisterModule("DB", {})
function db:Get(key, default) if values[key] ~= nil then return values[key] end; return default end
function db:Set(key, value) values[key] = value end
execute(read("Modules/WhoSearches.lua"), "WhoSearches")
local searches = BFL.modules.WhoSearches
check(not searches:Record(secret) and not searches:Save(secret), "Queries never persist secret input")
check(not searches:Save(string.rep("x", 257)), "Queries exceeding the edit box limit are rejected")
for _, value in ipairs({ "A", "B", "C", "D", "B" }) do searches:Record(value) end
equal(table.concat(values.whoSearchHistory, ","), "B,D,C", "History is deduplicated, bounded and most-recent-first")
for i = 1, 12 do check(searches:Save("Preset " .. i), "Each preset is saved") end
check(not searches:Save("Overflow"), "Saved searches have a fixed capacity")
searches:Remove("Preset 1"); check(searches:Save("Replacement"), "Removing a preset makes room")
local editBox = { text = "Ada" }
function editBox:SetText(text) self.text = text end
function editBox:GetText() return self.text end
function editBox:ClearFocus() end
local function field(limit)
	return { text = "", SetText = function(self, value) self.text = limit and value:sub(1, limit) or value end,
		GetText = function(self) return self.text end }
end
who.builder = { nameInput = field(12), guildInput = field(), zoneInput = field(), levelMin = field(3), levelMax = field(3) }
who.builderDocked = true
env.BetterFriendsFrame = { WhoFrame = { EditBox = editBox } }
local beforeWho = #calls
check(searches:Load(editBox, "n-\"Ada\""), "A saved query loads")
equal(editBox.text, 'n-"Ada"', "Loading changes the owned search field")
equal(#calls, beforeWho, "Loading never dispatches a server request")
local exactQuery = '71  n-"LongCharacterName-Realm" c-"Mage" c-"Priest" custom'
check(searches:Load(editBox, exactQuery), "A free-form query loads into the real docked builder")
equal(editBox.text, exactQuery, "Narrow builder fields never truncate the loaded query")
equal(who:BuildBuilderRequest(), exactQuery, "The actual Search path retains the exact imported syntax")
who.builder.nameInput:SetText("Bea"); who:UpdateBuilderPreview()
check(editBox.text:find('n-"Bea"', 1, true) and not editBox.text:find("LongCharacter", 1, true), "An intentional builder edit replaces the preserved query")
local send = who.SendWhoRequest
local dispatched
who.SendWhoRequest = function(_, text) dispatched = text end
who.GetHoveredColumn = function() return "class" end
who._testForeverBuilderDispatch = true
local getText = editBox.GetText
editBox.GetText = function() return "widget-sourced query" end
who:HandleCtrlClick({ info = { classStr = "Mage" } })
equal(dispatched, "widget-sourced query", "Forever Ctrl-click uses the existing widget dispatch path")
who.SendWhoRequest, editBox.GetText, who._testForeverBuilderDispatch = send, getText, nil
check(not searches:Remove(secret), "Removing a saved search rejects secret input before comparisons")
values.whoSearchHistoryMax = 0/0
check(searches:Record("NaN capacity") and #values.whoSearchHistory <= 8, "Corrupt history limits still retain a finite bound")
values.whoSearchHistoryMax = 3
searches:Load(editBox, 'n-"Ada"')
local menu
BFL.OpenSimpleContextMenu = function(_, _, items) menu = items end
searches:OpenMenu({}, editBox)
local historyToggle
for _, item in ipairs(menu) do if item.type == "checkbox" then historyToggle = item end end
historyToggle.func()
equal(#values.whoSearchHistory, 0, "Disabling history clears private query data")
check(not searches:Record("Secret preference"), "Disabled history has no persistence side effect")
values.whoSearchPresets = { string.rep("名", 64) }
searches:OpenMenu({}, editBox)
check(utf8.len(menu[3].text) == 25, "Long wide-character menu labels stay bounded and valid UTF-8")
equal(menu[3].tooltip, values.whoSearchPresets[1], "The complete query remains available in the tooltip")
menu[3].children[1].func()
equal(editBox.text, values.whoSearchPresets[1], "Truncated menu labels still load the entire query")
equal(#calls, beforeWho, "Menu callbacks never dispatch a server request")

execute(read("Modules/RecentAllies.lua"), "RecentAllies")
local recent = BFL.modules.RecentAllies
local raw = { characterData = { guid = "Player-1", name = "Ada", fullName = "Ada-Realm", classID = 8, level = secret },
	stateData = { isOnline = true, currentLocation = secret, pinExpirationDate = secret },
	interactionData = { note = secret, interactions = {
		{ description = "Older", timestamp = 100, contextData = { locationName = "Dungeon", activityDifficultyLevel = 10 } },
		secret, { description = secret }, { description = "Newest", timestamp = 900 },
		{ description = "Unknown time", timestamp = secret },
	} } }
local safe = recent:NormalizeList({ secret, raw })
equal(#safe, 1, "Secret records are discarded without indexing")
equal(safe[1].characterData.level, 0, "Secret level uses an inert display value")
equal(safe[1].stateData.currentLocation, nil, "Secret location is discarded")
equal(safe[1].stateData.pinExpirationDate, nil, "Secret pin date never enters arithmetic")
equal(safe[1].interactionData.note, nil, "Secret notes never reach formatting")
local activities = safe[1].interactionData.interactions
equal(#activities, 3, "Only readable interactions remain")
equal(activities[1].description, "Newest", "History displays most-recent-first")
equal(activities[3].timestamp, nil, "Unknown timestamps do not participate in arithmetic")
check(recent:GetInteractionText(activities[2]):find("Dungeon", 1, true), "Activity context uses readable fields")
equal(raw.interactionData.interactions[1].description, "Older", "Native result tables are not rewritten")
raw.characterData.guid = secret
local menusOpened = 0
BFL.OpenContextMenu = function() menusOpened = menusOpened + 1 end
recent:OpenMenu({ elementData = raw })
equal(menusOpened, 0, "Secret identity never reaches the native menu")
local preview = recent:NormalizeAlly({ _isMock = true, characterData = { name = "Preview", fullName = "Preview-Realm", guid = "Player-Preview-1" }, stateData = { isOnline = true } })
check(preview._isMock, "The normalizer preserves the inert preview marker")
recent:OpenMenu({ elementData = preview })
equal(menusOpened, 0, "Preview identities never reach native menus")
local lastMenu, menuName
BFL.OpenContextMenu = function(_, kind, context) lastMenu, menuName = kind, context.name end
env.UnitPopupMenus = { RECENT_ALLY = {} }
recent:OpenMenu({ elementData = safe[1] })
equal(lastMenu, "RECENT_ALLY", "Registered Recent Ally menus keep their native note/pin actions")
env.UnitPopupMenus.RECENT_ALLY = nil
recent:OpenMenu({ elementData = safe[1] })
equal(lastMenu, "FRIEND", "Missing Recent Ally menus retain the legacy fallback")
local fullNameOnly = recent:NormalizeAlly({ characterData = { fullName = "Only-Realm", guid = "Player-2" } })
recent:OpenMenu({ elementData = fullNameOnly })
equal(menuName, "Only-Realm", "Menus always have a readable name even when only fullName is available")
local tooltip = { rows = {} }
function tooltip:AddDoubleLine(left, right) self.rows[#self.rows + 1] = { left, right } end
env.GameTooltip_AddBlankLineToTooltip = function() end
env.GameTooltip_AddNormalLine = function() end
env.GameTooltip_AddHighlightLine = function(_, text) tooltip.rows[#tooltip.rows + 1] = { text } end
recent:AddActivityTooltipLines(tooltip, activities)
equal(#tooltip.rows, 3, "All readable short-history activities appear in the tooltip")
equal(tooltip.rows[1][2], "100s", "Timeline age uses the sanitized timestamp")

local function widget()
	local object = { scripts = {}, text = "" }
	for _, method in ipairs({ "SetSize", "SetPoint", "SetClampedToScreen", "SetFrameStrata", "EnableMouse",
		"SetBackdrop", "SetBackdropColor", "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetWidth", "ClearAllPoints" }) do
		object[method] = function() end
	end
	function object:SetText(text) self.text = text end
	function object:GetText() return self.text end
	function object:SetHeight(height) self.height = height end
	function object:GetStringHeight() return #self.text end
	function object:SetVerticalScroll(offset) self.offset = offset end
	function object:SetEnabled(enabled) self.enabled = enabled end
	function object:SetScrollChild(child) self.child = child end
	function object:CreateFontString() return widget() end
	function object:SetScript(event, callback) self.scripts[event] = callback end
	function object:Show() self.visible = true end
	function object:Hide() self.visible = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
	return object
end
env.CreateFrame = function(_, _, parent, template)
	check(template ~= "SecureActionButtonTemplate", "History uses no secure action templates")
	local result = widget()
	result.parent = parent
	function result:SetPoint(...)
		self.point = { ... }
		check(self.point[2] ~= env.BetterFriendsFrame, "History never anchors to the protected social frame")
	end
	return result
end
env.date = os.date
env.UIParent = { GetEffectiveScale = function() return 1 end }
env.BetterFriendsFrame = { RecentAlliesFrame = {}, GetRight = function() error("Protected coordinates must not be read in combat") end }
inCombat = true
recent:ShowActivityHistory({ elementData = safe[1] })
inCombat = false
equal(recent.activityFrame.parent, env.UIParent, "The history display is outside the protected parent hierarchy")
check(recent.activityFrame.visible, "A row opens the read-only activity window")
check(recent.activityFrame.text.text:find("Newest", 1, true) and recent.activityFrame.text.text:find("Older", 1, true), "The scroll surface includes the complete history")
equal(recent.activityFrame.scroll.offset, 0, "A new history starts at the top")
recent.activityFrame:Hide()
equal(recent.activityFrame.text.text, "", "Closing discards displayed activity data")
equal(recent.activityFrame.title.text, "", "Closing discards the displayed identity")
recent.activityFrame = nil
env.BetterFriendsFrame.GetRight = function() return 800 end
env.BetterFriendsFrame.GetTop = function() return 600 end
env.BetterFriendsFrame.GetEffectiveScale = function() return 1 end
env.UIParent.GetEffectiveScale = function() return 2 end
recent:ShowActivityHistory({ elementData = safe[1] })
equal(recent.activityFrame.point[2], env.UIParent, "Out-of-combat placement also anchors only to UIParent")
equal(recent.activityFrame.point[4], 408, "History placement translates the source UI scale")
equal(recent.activityFrame.point[5], 300, "History placement translates vertical coordinates")
recent.activityFrame:Hide()

-- Exercise the real recycled-row click closure, including disabled programmatic clicks.
local setupInvite = execute("return function(self, button, elementData)\nlocal stateData, characterData = elementData.stateData, elementData.characterData\n"
	.. between(read("Modules/RecentAllies.lua"), "\t-- Enable/disable party button", "\t-- Setup party button tooltip") .. "\nend", "Recent ally invite callback")
local row = { elementData = preview, PartyButton = widget() }
setupInvite(recent, row, preview)
check(not row.PartyButton.enabled, "Preview invite buttons are disabled")
before = mutationCount
row.PartyButton.scripts.OnClick()
equal(mutationCount, before, "Even a synthetic preview click cannot invite")
row.elementData = safe[1]
row.PartyButton.scripts.OnClick()
equal(mutationCount, before + 1, "A recycled row invites its current readable identity")
row.elementData = { characterData = { fullName = secret }, stateData = { isOnline = true } }
row.PartyButton.scripts.OnClick()
equal(mutationCount, before + 1, "A recycled row never retains the previous action target")
before = mutationCount

env.FriendsUI = {}
env.GetL = function() return BFL.L end
local invite = { inviteID = 42, accountName = secret, creationTimestamp = secret, friendLevel = secret }
env.C_BattleNet.GetFriendInviteInfo = function() return invite end
execute(between(read("Modules/FriendsUI.lua"), "local function GetInviteInfo(index)", "function FriendsUI:InitializeRequestHeader("), "Request metadata")
local normalized = env.FriendsUI:NormalizeInvite(1)
equal(normalized.accountName, "Unknown", "Secret request names have an inert label")
equal(normalized.creationTimestamp, nil, "Secret request times never enter age arithmetic")
equal(normalized.friendLevel, nil, "Secret request types are not guessed")
invite.inviteID = secret
equal(env.FriendsUI:NormalizeInvite(1), nil, "A secret request ID cannot create action controls")
equal(env.FriendsUI:GetFriendLevelLabel(secret), "Unknown", "Secret friend types are not compared")
check(not env.FriendsUI:IsRealIDInvite(secret) and not env.FriendsUI:IsTitleInvite(secret), "Secret requests do not enter type-specific paths")
env.Enum.BattleNetFriendLevel.Title = nil
check(not BFL.IsTitleFriend({}), "Missing Classic Title metadata never classifies an empty account as Title")
check(not env.FriendsUI:IsTitleInvite(nil), "Missing Classic Title enum is not an unknown invite match")
equal(env.FriendsUI:GetFriendLevelLabel(nil), "Unknown", "Missing enum fields never invent a request label")
local getInvite = BFL.GetBNetFriendInviteInfo
BFL.GetBNetFriendInviteInfo = function() return 123, "Real ID", false, 100 end
equal(env.FriendsUI:NormalizeInvite(1).friendLevel, 2, "Legacy tuple metadata maps to the current enum")
env.Enum.BattleNetFriendLevel = nil
normalized = env.FriendsUI:NormalizeInvite(1)
check(env.FriendsUI:IsRealIDInvite(normalized.friendLevel), "Legacy Real ID requests retain the privacy warning")
equal(env.FriendsUI:GetFriendLevelLabel(normalized.friendLevel), BFL.L.FRIENDS_UI_REQUEST_REAL_ID, "Legacy Real ID labels remain available")
BFL.GetBNetFriendInviteInfo = getInvite

-- Exercise the actual combat deferral before any frame calls are possible.
env.FriendsUI = {}
execute(between(read("Modules/FriendsUI.lua"), "function FriendsUI:OnGameRulesChanged()", "function FriendsUI:ShouldShowSection("), "Raid availability refresh")
inCombat = true
env.BetterFriendsFrame = setmetatable({}, { __index = function() error("Frame touched in combat") end })
env.FriendsUI:OnGameRulesChanged()
check(env.FriendsUI.pendingNavigationRefresh, "Raid availability changes are deferred during combat")
equal(mutationCount, before, "Reading, local storage and display perform no extra mutations")
local navigations, selections = 0, 0
env.BetterFriendsFrame = { IsShown = function() return true end }
function env.FriendsUI:RefreshNavigation() navigations = navigations + 1 end
function env.FriendsUI:GetSelectedSection() return "raid" end
function env.FriendsUI:IsSectionAvailable() return false end
function env.FriendsUI:BuildAvailableSectionIDs() return { "friends" } end
function env.FriendsUI:SelectSection(section) equal(section, "friends", "Unavailable Raid tab falls back to Friends"); selections = selections + 1 end
local regen
function BFL:RegisterEventCallback(event, callback) equal(event, "PLAYER_REGEN_ENABLED", "Production regen callback is registered"); regen = callback end
execute("local self = FriendsUI\n" .. between(read("Modules/FriendsUI.lua"), '\tBFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()', '\tBFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", function()'), "Navigation combat drain")
inCombat = false
regen()
equal(navigations, 1, "Combat end drains the deferred navigation transaction once")
equal(selections, 1, "Combat end selects only the available fallback")
check(not env.FriendsUI.pendingNavigationRefresh, "Combat end clears the pending navigation flag")

env.RaidFrame, env.L = {}, BFL.L
env.IsPendingRaidRosterName = function() return false end
env.UnitIsGroupAssistant = function() return false end
values.raidShortcuts = { promote = { button = "LeftButton", modifier = "CTRL" } }
execute(between(read("Modules/RaidFrame.lua"), "function RaidFrame:HandleShortcutClick(", "--- Legacy monolithic proxy"), "Raid shortcut click")
local nativeAssistant = BFL.PromoteToAssistant
BFL.PromoteToAssistant = function() return false end
check(not env.RaidFrame:HandleShortcutClick({ unit = "raid1", name = "Ada" }, "LeftButton", "CTRL"), "Rejected promotions never report shortcut success")
BFL.PromoteToAssistant = nativeAssistant
inCombat = true
check(not env.RaidFrame:HandleShortcutClick(setmetatable({}, { __index = function() error("Protected row accessed in combat") end }), "LeftButton", "CTRL"), "Combat shortcuts return before accessing the protected row")
inCombat = false

inCombat, BFL.IsMainline, BFL.IsRetail = false, false, false
env.C_PartyInfo, env.C_BattleNet = nil, nil
env.PromoteToLeader, env.ConvertToRaid = mutate, mutate
check(BFL.PromoteToLeader("Ada-Realm"), "Classic keeps the guarded legacy promotion fallback")
check(BFL.ConvertToRaid(), "Classic keeps the guarded legacy conversion fallback")
check(BFL.IsRaidListSupported() and BFL.IsRaidListEnabled(), "Classic does not call absent Mainline-only APIs")
io.write("[OK] PTR/Forever social smoke: " .. assertions .. " assertions; live secure execution still requires client QA\n")
