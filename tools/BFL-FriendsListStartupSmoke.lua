-- Lua 5.4: lua tools/BFL-FriendsListStartupSmoke.lua <repo> [--reproduce]
-- Loads the complete production module: startup, updates, sorting and display
-- rows are real. Blizzard C APIs, frame geometry and painting are mocked.
local repo = assert(arg[1], "repository root is required")
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local content = file:read("*a"); file:close(); return content
end
local source = read("Modules/FriendsList.lua")
if arg[2] == "--reproduce" then
	-- Restore only the old guard in memory, never in the working tree.
	local replacements
	source, replacements = source:gsub("if IsBNetFriendIdentityReady%(firstInfo%) then",
		"if firstInfo and firstInfo.battleTag and firstInfo.battleTag ~= \"\" then", 1)
	assert(replacements == 1, "production readiness guard anchor missing")
end
local mainSource = read("BetterFriendlist.lua")
local uidStart = assert(mainSource:find("function GetFriendUID(", 1, true))
local uidEnd = assert(mainSource:find("-- DISPLAY MANAGEMENT", uidStart, true))
local globalUIDSource = mainSource:sub(uidStart, uidEnd - 1)
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function game(online)
	return { isOnline = online, clientProgram = "WoW", wowProjectID = 18, characterName = "Ada Lovelace",
		characterLevel = 0, realmID = 100, realmName = "Home", areaName = "Elwynn", factionName = "Alliance",
		isInCurrentRegion = true, playerGuid = "Player-42", gameAccountID = 123, classID = 1, regionID = 3 }
end
local function title(id, online)
	return { bnetAccountID = id or 42, accountName = "Ada Lovelace", battleTag = "", friendLevel = 3,
		gameAccountInfo = game(online ~= false), friendTags = {} }
end
local function normal(tag)
	return { bnetAccountID = 43, accountName = "Other friend", battleTag = tag, friendLevel = 1,
		gameAccountInfo = game(true), friendTags = {} }
end
local protectedAccount = setmetatable({}, { __index = function() error("Protected account labels must not be inspected") end })
local function setup(accounts, options)
	options = options or {}
	local BFL = { L = {}, modules = {}, IsRetail = not options.classic, IsMainline = not options.classic,
		IsForever = not options.classic, IsClassic = options.classic == true, HasModernScrollBox = options.modern == true }
	function BFL:RegisterModule(name, module) self.modules[name] = module; self[name] = module; return module end
	function BFL:GetModule(name) return self.modules[name] end
	function BFL:RegisterLocale() end
	function BFL:IsSecret(value) return value == protectedAccount end
	function BFL:StripAccents(text) return text:lower() end
	function BFL:GetSafeAccountName(name, tag) return name or tag or "Unknown" end
	local timers, eventCallbacks, hooks = {}, {}, {}
	function BFL:RegisterEventCallback(event, callback) eventCallbacks[event] = callback end
	BFL.FontManager = { ResolveFontPath = function() return "TestFont" end, GetFontFlags = function() return "" end }
	local settings = { quickFilter = "all", primarySort = "status", secondarySort = "name", colorClassNames = options.colorClassNames == true,
		showFactionIcons = options.showFactionIcons == true, compactMode = options.compact == true }
	BFL.modules.DB = {
		Get = function(_, key, fallback) if not key then return settings end; if settings[key] ~= nil then return settings[key] end; return fallback end,
		Set = function(_, key, value) settings[key] = value end,
		GetNameFormatString = function() return options.nameFormat or "%name% (%character%)" end,
		GetInfoFormatString = function() return "%zone%" end,
		IsInfoDisabled = function() return false end,
		GetNickname = function() return "" end,
	}
	local shown = true
	local frame = { IsShown = function() return shown end, GetWidth = function() return 440 end,
		HookScript = function(_, name, callback) hooks[name] = callback end }
	local env = setmetatable({ BFL = BFL, BFL_LOCALE_ENUS = BFL.L, BetterFriendsFrame = frame,
		BetterFriendlistDB = { friendGroups = {}, knownCharacters = options.knownCharacters }, SlashCmdList = {}, StaticPopupDialogs = {},
		Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 }, GameMode = { Standard = 0 } },
		BNET_CLIENT_WOW = "WoW", WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
		UnitFactionGroup = function() return "Alliance" end, GetRealmID = function() return 100 end,
		GetNormalizedRealmName = function() return "Home" end, GetRealmName = function() return "Home" end,
		GetCurrentRegion = function() return 3 end, GetServerTime = function() return 1700000000 end,
		GetCVarBool = function() return false end, BNGetNumFriendInvites = function() return 0 end,
		C_PartyInfo = { CanFormCrossFactionParties = function() return false end },
		C_QuestSession = { Exists = function() return false end },
		C_GameRules = { GetActiveGameMode = function() return 0 end },
		RegionalUniqueNamesEnabled = function() return not options.classic end,
		RAID_CLASS_COLORS = { WARRIOR = { colorStr = "ffc79c6e" }, MAGE = { colorStr = "ff69ccf0" } },
		wipe = function(value) for key in pairs(value) do value[key] = nil end; return value end,
		strtrim = function(value) return value:match("^%s*(.-)%s*$") end,
		strsplit = function(delimiter, value)
			local first, last = value:find(delimiter, 1, true)
			if first then return value:sub(1, first - 1), value:sub(last + 1) end
			return value
		end,
	}, { __index = _G })
	env._G = env
	env.C_Timer = {
		After = function(delay, callback) timers[#timers + 1] = { delay = delay, callback = callback } end,
		NewTimer = function(delay, callback)
			local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
			timers[#timers + 1] = timer; return timer
		end,
	}
	env.C_BattleNet = {
		GetFriendAccountInfo = function(index) return accounts[index] end,
		GetFriendNumGameAccounts = function(index) return accounts[index].gameAccountInfo.isOnline and 1 or 0 end,
		GetFriendGameAccountInfo = function(index) return accounts[index].gameAccountInfo end,
		AreTitleFriendCustomNamesEnabled = function() return true end,
		GetCustomTitleFriendName = function(id) return options.aliases and options.aliases[id] end,
	}
	env.BNGetNumFriends = function() return options.count or #accounts, #accounts, 0 end
	env.C_FriendList = { GetNumFriends = function() return 0 end }
	local function execute(content, label) return assert(load(content, "@" .. label, "t", env))("BetterFriendlist", BFL) end
	execute(read("Locales/enUS.lua"), "Locales/enUS.lua")
	execute(read("Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
	execute(read("Modules/KnownCharacters.lua"), "Modules/KnownCharacters.lua")
	execute(read("Utils/ClassUtils.lua"), "Utils/ClassUtils.lua")
	execute(read("Modules/FilterSortRegistry.lua"), "Modules/FilterSortRegistry.lua")
	execute(globalUIDSource, "BetterFriendlist global UID helper")
	execute(source, "Modules/FriendsList.lua")
	local list = BFL.FriendsList
	local paints = 0
	list.RenderClassicButtons = function() paints = paints + 1 end -- Painting only; real rows are in classicDisplayList.
	if options.modern then
		local provider
		list.scrollBox = { GetDataProvider = function() return provider end, GetWidth = function() return 396 end,
			SetDataProvider = function(_, nextProvider) provider = nextProvider; paints = paints + 1 end }
		env.CreateDataProvider = function()
			local value = { rows = {} }; function value:Insert(row) self.rows[#self.rows + 1] = row end; return value
		end
	end
	list:Initialize()
	return { list = list, BFL = BFL, accounts = accounts, env = env, hooks = hooks, events = eventCallbacks, timers = timers,
		setShown = function(value) shown = value end, paints = function() return paints end,
		rows = function() return options.modern and list.scrollBox:GetDataProvider().rows or list.classicDisplayList end,
	}
end
-- A layout switch replaces the view without rebinding the animated scroll pair.
do
	local context = setup({})
	local bindings = 0
	local function ScrollControl()
		return {
			SetInterpolateScroll = function(self, enabled) self.interpolate = enabled end,
			SetView = function(self, view) self.view = view end,
		}
	end
	local scrollBox, scrollBar = ScrollControl(), ScrollControl()
	context.env.BetterFriendsFrame.ScrollFrame = { ScrollBox = scrollBox }
	context.env.BetterFriendsFrame.MinimalScrollBar = scrollBar
	context.env.CreateScrollBoxListLinearView = function()
		return { SetElementFactory = function() end, SetElementExtentCalculator = function() end }
	end
	context.env.ScrollUtil = {
		InitScrollBoxListWithScrollBar = function(box, bar, view)
			check(box.interpolate and bar.interpolate, "Interpolation is enabled before Blizzard binds the pair")
			bindings = bindings + 1
			box:SetView(view)
		end,
	}
	context.BFL.HasModernScrollBox = true
	context.list:InitializeScrollBox()
	check(scrollBox.interpolate and scrollBar.interpolate, "Both native scroll controls opt into interpolation")
	equal(bindings, 1, "The scroll pair is bound on first initialization")
	local firstView = scrollBox.view
	context.list:InitializeScrollBox()
	check(scrollBox.view ~= firstView, "A layout switch replaces the scroll view")
	equal(bindings, 1, "A layout switch keeps the existing scroll binding")
	check(scrollBox.interpolate and scrollBar.interpolate, "Interpolation survives the layout switch")
end

local function visibleCount(context)
	local count = 0
	for _, row in ipairs(context.rows() or {}) do if row.friend then count = count + 1 end end
	return count
end
if arg[2] == "--reproduce" then
	local context = setup({ title() })
	for _ = 1, 5 do context.list:UpdateFriendsList() end
	equal(#context.list.friendsList, 0, "Old first-Title guard keeps the entire list empty")
	equal(context.list.bnetIncompleteRetryAttempts, 5, "Every attempt defers without a Lua error")
	equal(context.paints(), 0, "The old guard never reaches the rendering path")
	io.write("[REPRODUCED] Complete FriendsList module: first Title account with empty BattleTag blocks all five updates without a Lua error\n")
	return
end
for _, modern in ipairs({ false, true }) do
	for _, fixtures in ipairs({ { title() }, { title(42, false) }, { title(), normal("Other#1234") }, { normal("Other#1234"), title() }, { title(), title(44, false) } }) do
		local context = setup(fixtures, { modern = modern })
		context.list:UpdateFriendsList()
		equal(#context.list.friendsList, #fixtures, "All available friends reach the production data list")
		equal(visibleCount(context), #fixtures, "Production sorting/group/filter/render reaches the visible rows")
		check(context.list.bnetDataReady, "A complete Title-first snapshot is ready immediately")
		equal(context.list.bnetIncompleteRetryAttempts, 0, "Complete identities do not enter the retry loop")
		check(context.paints() > 0, "The UI backend receives the completed rows")
	end
end
for _, modern in ipairs({ false, true }) do
	for _, fixture in ipairs({
		{ accountName = "|Kq42|k", expected = "Ada Lovelace" },
		{ accountName = protectedAccount, expected = "Ada Lovelace" },
		{ accountName = "|Kq42|k", alias = "My mage", expected = "My mage (Ada Lovelace)" },
		{ accountName = "|Kq42|k", alias = "Ada Lovelace", expected = "Ada Lovelace" },
		{ accountName = "|Kq42|k", offline = true, expected = "|Kq42|k" },
	}) do
		local account = title(42, not fixture.offline)
		account.accountName = fixture.accountName
		local context = setup({ account }, { modern = modern, aliases = { [42] = fixture.alias } })
		context.list:UpdateFriendsList()
		equal(visibleCount(context), 1, "Encoded/protected Title labels still reach the visible list")
		equal(context.list.friendsList[1].displayName, fixture.expected, "The complete module formats Title names and aliases correctly")
		for _, row in ipairs(context.rows()) do
			if row.friend then equal(row.friend.displayName, fixture.expected, "The UI backend receives the nonduplicated Title display name") end
		end
	end
end
for _, modern in ipairs({ false, true }) do
	local account = title()
	local context = setup({ account }, { modern = modern, nameFormat = "%name%", colorClassNames = true })
	local function refresh(expected, message, expectedButtonText)
		context.list:UpdateFriendsList()
		equal(visibleCount(context), 1, "Class-colored name-only Titles reach the visible list")
		local friend = context.list.friendsList[1]
		equal(friend.displayName, expected, message .. " (production data/display path)")
		equal(context.list:GetFormattedButtonText(friend), expectedButtonText or expected, message .. " (production UI text)")
	end
	refresh("|cffc79c6eAda Lovelace|r", "Online Title uses its class-ID color")
	account.gameAccountInfo.isOnline = false
	refresh("Ada Lovelace", "Offline Title remains gray", "|cff7f7f7fAda Lovelace|r")
	account.gameAccountInfo.isOnline, account.gameAccountInfo.classID = true, 8
	refresh("|cff69ccf0Ada Lovelace|r", "Reconnected Title uses its current class color")
end
for _, modern in ipairs({ false, true }) do
	local account = title()
	account.accountName = "Private Real-ID name"
	local context = setup({ account }, { modern = modern, aliases = { [42] = "Private title alias" } })
	context.BFL.StreamerMode = { IsActive = function() return true end }
	context.list:UpdateFriendsList()
	local friend = context.list.friendsList[1]
	equal(friend.displayName, "Ada Lovelace", "Streamer Title fallback uses just the character")
	for _, row in ipairs(context.rows()) do
		if row.friend then equal(row.friend.displayName, "Ada Lovelace", "The list renders the safe Title fallback") end
	end

	local menuContext = { bnetIDAccount = 42, name = account.accountName }
	local displayedTitle
	context.BFL.HasSecretValues = true
	context.BFL.OpenBetterFriendlistContextMenu = function(_, _, _, data)
		displayedTitle = data.bfl_streamerDisplayName
		return true
	end
	context.BFL.OpenContextMenu(nil, "BN_FRIEND", menuContext)
	equal(displayedTitle, "Ada Lovelace", "BFL prepares the masked title before opening its own context menu")
	context.BFL.OpenContextMenu(nil, "BN_FRIEND_OFFLINE", { bnetIDAccount = 99, name = account.accountName })
	equal(displayedTitle, "Unknown", "An unmatched BNet menu cannot fall back to its raw account name")
	equal(menuContext.name, account.accountName, "Whisper routing keeps its original target")

	context.list.settingsCache.nameFormatString = "%name%"
	friend.battleTag = "SafeTag#1234"
	equal(context.list:GetDisplayName(friend), "SafeTag", "A readable BattleTag still takes priority")
	friend.battleTag = protectedAccount
	equal(context.list:GetDisplayName(friend), "Ada Lovelace", "An unreadable BattleTag uses the safe Title fallback")
	friend.characterName = protectedAccount
	equal(context.list:GetDisplayName(friend), "Unknown", "An unreadable character never falls back to the Real-ID name")
	friend.characterName, friend.battleTag, friend.friendLevel = "Ada Lovelace", "", 2
	equal(context.list:GetDisplayName(friend), "Unknown", "The fallback is limited to Title friends")
end
local delayed = setup({ normal("") })
delayed.list:UpdateFriendsList()
equal(#delayed.list.friendsList, 0, "Incomplete normal BattleTag data still waits")
check(not delayed.list.bnetDataReady and delayed.list.bnetIncompleteRetryAttempts == 1, "Normal login identity protection stays active")
delayed.accounts[1].battleTag = "Other#1234"
delayed.events.FRIENDLIST_UPDATE()
equal(visibleCount(delayed), 1, "The real friend-list event recovers after normal data arrives")
local missing = setup({ title(), nil }, { count = 2 })
missing.list:UpdateFriendsList()
equal(missing.paints(), 0, "Missing account records do not publish a partial snapshot")
missing.accounts[2] = normal("Other#1234")
missing.list:UpdateFriendsList()
equal(visibleCount(missing), 2, "Missing account records recover once available")
local nilTag = title()
nilTag.battleTag = nil
local nilTagContext = setup({ nilTag })
nilTagContext.list:UpdateFriendsList()
equal(visibleCount(nilTagContext), 1, "An omitted Title BattleTag is as valid as an empty one")
equal(nilTagContext.list.friendsList[1].uid, "bnet_42", "Title identity continues to use the existing account-ID key")
local absentID = title()
absentID.bnetAccountID = nil
local absentIDContext = setup({ absentID })
absentIDContext.list:UpdateFriendsList()
check(not absentIDContext.list.bnetDataReady and absentIDContext.paints() == 0, "A Title account without an identity still waits")
absentID.bnetAccountID = 42
absentIDContext.events.FRIENDLIST_UPDATE()
equal(visibleCount(absentIDContext), 1, "Title startup recovers when its account ID arrives")
local opened = setup({ normal("Other#1234") })
opened.setShown(false)
opened.list:UpdateFriendsList()
equal(opened.paints(), 0, "Hidden updates defer rendering")
opened.setShown(true)
opened.hooks.OnShow()
equal(visibleCount(opened), 1, "Opening the frame reads the real dirty flag and fills the list")
local classic = setup({ normal("Classic#1234") }, { classic = true })
classic.env.WOW_PROJECT_ID, classic.accounts[1].gameAccountInfo.wowProjectID = 2, 2
classic.list:UpdateFriendsList()
equal(visibleCount(classic), 1, "Classic normal-friend startup remains supported")
local empty = setup({})
empty.list:UpdateFriendsList()
check(not empty.list.bnetDataReady, "Initial zero counts still allow server data to arrive")
for _, timer in ipairs(empty.timers) do if timer.delay == 1 then timer.callback(); break end end
check(empty.list.bnetDataReady and empty.paints() > 0, "The zero-friend fallback eventually renders without an endless wait")
empty.accounts[1] = title()
empty.events.FRIENDLIST_UPDATE()
for _, timer in ipairs(empty.timers) do if not timer.cancelled and timer.delay == 0.1 then timer.callback() end end
-- A ready list debounces events; call its scheduled update timer as the client does.
for _, timer in ipairs(empty.timers) do if not timer.cancelled and timer.delay == 0.05 then timer.callback() end end
equal(visibleCount(empty), 1, "A Title friend arriving after the zero-count fallback is displayed")
for _, modern in ipairs({ false, true }) do
	local large = {}
	for index = 1, 150 do large[index] = title(index) end
	local chunked = setup(large, { modern = modern })
	chunked.list:UpdateFriendsList()
	local timerIndex = 1
	while timerIndex <= #chunked.timers do
		check(timerIndex < 100, "Chunked startup finishes in bounded next-frame work")
		local timer = chunked.timers[timerIndex]
		if not timer.cancelled and timer.delay == 0 then timer.callback() end
		timerIndex = timerIndex + 1
	end
	equal(#chunked.list.friendsList, 150, "Large Title-first lists finish collection")
	equal(visibleCount(chunked), 150, "Large Title-first lists reach all visible rows")
	check(chunked.list.chunkedFriendsListUpdate == nil, "The chunked worker completes")
end
-- Faction decoration belongs to the rendered row, not the presence of a
-- particular name-format token. Run the real Modern/Legacy text path.
for _, modern in ipairs({ false, true }) do
	for _, format in ipairs({ "%name%", "%battletag%", "%name% (%character%)", "%character%" }) do
		for _, compact in ipairs({ false, true }) do
			local context = setup({ normal("Other#1234") }, { modern = modern, nameFormat = format,
				showFactionIcons = true, compact = compact })
			context.list:UpdateFriendsList()
			local text = context.list:GetFormattedButtonText(context.list.friendsList[1])
			local _, icons = text:gsub("PlusManz%-Alliance", "")
			equal(icons, 1, "Enabled faction icons appear exactly once for every name preset and row style")
		end
	end
end
local factionContext = setup({ normal("Other#1234") }, { modern = true, showFactionIcons = true })
factionContext.list:UpdateFriendsList()
local factionFriend = factionContext.list.friendsList[1]
local oldName = factionContext.list:GetDisplayName(factionFriend)
local oldText = factionContext.list:GetFormattedButtonText(factionFriend)
check(oldName:find("PlusManz-Alliance", 1, true) and oldText:find("PlusManz-Alliance", 1, true), "Both faction-sensitive caches are populated before switching faction")
factionFriend.factionName, factionFriend.gameAccountInfo.factionName = "Horde", "Horde"
local changedName = factionContext.list:GetDisplayName(factionFriend)
check(changedName:find("PlusManz-Horde", 1, true) and not changedName:find("PlusManz-Alliance", 1, true), "Faction changes invalidate the persistent name cache")
check(factionContext.list:GetFormattedButtonText(factionFriend):find("PlusManz-Horde", 1, true), "Faction changes also invalidate rendered row text")
check(not factionContext.list:GetDisplayName(factionFriend, true):find("PlusManz", 1, true), "Sorting never receives faction markup")
for _, faction in ipairs({ "Neutral", "", protectedAccount }) do
	factionFriend.factionName, factionFriend.gameAccountInfo.factionName = faction, faction
	local text = factionContext.list:GetFormattedButtonText(factionFriend)
	check(not text:find("PlusManz", 1, true), "Unknown or secret factions never produce a guessed icon")
end
factionFriend.factionName, factionFriend.gameAccountInfo.factionName = nil, "Alliance"
check(factionContext.list:GetFormattedButtonText(factionFriend):find("PlusManz-Alliance", 1, true), "Readable nested faction metadata is a valid fallback")
factionFriend.gameAccountInfo = protectedAccount
factionFriend.factionName = nil
check(not factionContext.list:GetFriendFactionIcon(factionFriend):find("PlusManz", 1, true), "Secret game-account tables are never indexed for faction display")
factionFriend.gameAccountInfo = game(true)
factionFriend.factionName = "Alliance"
factionContext.env.FriendListColorsAPI = { Format = function() return "External name" end }
local BFL = factionContext.BFL
BFL.SettingsVersion = (BFL.SettingsVersion or 1) + 1
local externalText = factionContext.list:GetFormattedButtonText(factionFriend)
check(externalText:find("External name", 1, true) and externalText:find("PlusManz-Alliance", 1, true), "External name formatters do not silently disable the faction setting")
factionContext.env.FriendListColorsAPI.Format = function() return "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|tExternal name" end
BFL.SettingsVersion = BFL.SettingsVersion + 1
local _, externalIcons = factionContext.list:GetFormattedButtonText(factionFriend):gsub("PlusManz%-Alliance", "")
equal(externalIcons, 1, "An external formatter's existing faction icon is not duplicated")
factionContext.env.FriendListColorsAPI = nil
local wowFriend = { type = "wow", uid = "wow_Ada-Home", name = "Ada-Home", connected = true }
check(not factionContext.list:GetFriendFactionIcon(wowFriend):find("PlusManz", 1, true), "WoW friends without faction metadata are not assigned the player's faction")
wowFriend.factionName, wowFriend.characterName = "Alliance", "Ada"
local wowName = factionContext.list:GetFormattedButtonText(wowFriend)
local _, wowIcons = wowName:gsub("PlusManz%-Alliance", "")
equal(wowIcons, 1, "A WoW row with known faction metadata also has only one icon")
factionContext.env.InCombatLockdown = function() return true end
BFL.SettingsVersion = BFL.SettingsVersion + 1
check(factionContext.list:GetFormattedButtonText(wowFriend):find("PlusManz-Alliance", 1, true), "Read-only row formatting needs no protected action or combat-time mutation")
local classicIcons = setup({ normal("Classic#1234") }, { classic = true, showFactionIcons = true, nameFormat = "%name%" })
classicIcons.env.WOW_PROJECT_ID, classicIcons.accounts[1].gameAccountInfo.wowProjectID = 2, 2
classicIcons.list:UpdateFriendsList()
check(classicIcons.list:GetFormattedButtonText(classicIcons.list.friendsList[1]):find("PlusManz-Alliance", 1, true), "Classic uses the same metadata-only, legacy-texture fallback")
for _, state in ipairs({ { enabled = false, online = true }, { enabled = true, online = false } }) do
	local context = setup({ normal("Other#1234") }, { showFactionIcons = state.enabled, nameFormat = "%name%" })
	context.accounts[1].gameAccountInfo.isOnline = state.online
	context.list:UpdateFriendsList()
	check(not context.list:GetFormattedButtonText(context.list.friendsList[1]):find("PlusManz", 1, true), "Disabled or unavailable live faction data leaves no stale icon")
end
for _, classic in ipairs({ false, true }) do
	local snapshot = normal("Known#1234")
	if classic then snapshot.gameAccountInfo.characterName, snapshot.gameAccountInfo.wowProjectID = "Ada", 2 end
	local context = setup({ snapshot }, { classic = classic,
		knownCharacters = { enabled = true, observeBattleNet = true, maxTooltipCharacters = 3, contacts = {} } })
	if classic then context.env.WOW_PROJECT_ID = 2 end
	context.list:UpdateFriendsList()
	local entries = context.BFL.modules.KnownCharacters:GetEntries(context.list.friendsList[1])
	equal(#entries, 1, "The actual Retail/Classic collection path passes its native account snapshot to KnownCharacters")
	equal(entries[1].source, "observed", "Production collection stores an observed, not guessed, association")
end
io.write("[OK] FriendsList startup smoke: " .. assertions .. " assertions (complete production module; mocked C APIs/widgets)\n")
