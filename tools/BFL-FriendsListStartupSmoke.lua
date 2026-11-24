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
local coreSource = read("Core.lua")
local eventStart = assert(coreSource:find("function BFL:FireEventCallbacks(", 1, true))
local eventEnd = assert(coreSource:find("-- Normalize a WoW friend identity.", eventStart, true))
local eventSource = coreSource:sub(eventStart, eventEnd - 1)
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
	BFL.EventCallbacks = {}
	function BFL:RegisterEventCallback(event, callback)
		eventCallbacks[event] = callback
		self.EventCallbacks[event] = { { callback = callback } }
	end
	function BFL:NormalizeWoWFriendName(name, playerRealm)
		return self.NormalizePlayerIdentityName(name, nil, playerRealm)
	end
	BFL.FontManager = { ResolveFontPath = function() return "TestFont" end, GetFontFlags = function() return "" end }
	local settings = { quickFilter = "all", primarySort = "status", secondarySort = "name", colorClassNames = options.colorClassNames == true,
		showFactionIcons = options.showFactionIcons == true, compactMode = options.compact == true,
		enableSmoothScrolling = options.smoothScrolling }
	BFL.modules.DB = {
		Get = function(_, key, fallback) if not key then return settings end; if settings[key] ~= nil then return settings[key] end; return fallback end,
		Set = function(_, key, value) settings[key] = value end,
		GetNameFormatString = function() return options.nameFormat or "%name% (%character%)" end,
		GetInfoFormatString = function() return "%zone%" end,
		IsInfoDisabled = function() return false end,
		GetNickname = function() return "" end,
		GetFriendGroups = function() return {} end,
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
		RAID_CLASS_COLORS = { WARRIOR = { r = 199/255, g = 156/255, b = 110/255, colorStr = "ffc79c6e" }, MAGE = { r = 105/255, g = 204/255, b = 240/255, colorStr = "ff69ccf0" } },
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
	execute(read("Data/ClassColors.lua"), "Data/ClassColors.lua")
	execute(read("Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
	execute(read("Utils/FriendNotes.lua"), "Utils/FriendNotes.lua")
	execute(read("Utils/FriendActions.lua"), "Utils/FriendActions.lua")
	execute(read("Modules/KnownCharacters.lua"), "Modules/KnownCharacters.lua")
	execute(read("Utils/ClassUtils.lua"), "Utils/ClassUtils.lua")
	execute(read("Modules/FilterSortRegistry.lua"), "Modules/FilterSortRegistry.lua")
	execute(globalUIDSource, "BetterFriendlist global UID helper")
	execute(eventSource, "Core event dispatcher")
	execute(source, "Modules/FriendsList.lua")
	local list = BFL.FriendsList
	local paints = 0
	list.RenderClassicButtons = function() paints = paints + 1 end -- Painting only; real rows are in classicDisplayList.
	if options.modern then
		local provider
		list.scrollBox = { GetDataProvider = function() return provider end, GetWidth = function() return 396 end,
			SetDataProvider = function(_, nextProvider) provider = nextProvider; paints = paints + 1 end }
		env.CreateDataProvider = function()
			local value = { rows = {} }
			function value:Insert(row) self.rows[#self.rows + 1] = row end
			function value:Enumerate() return ipairs(self.rows) end
			return value
		end
	end
	list:Initialize()
	return { list = list, BFL = BFL, accounts = accounts, env = env, hooks = hooks, events = eventCallbacks, timers = timers, execute = execute,
		setShown = function(value) shown = value end, paints = function() return paints end,
		rows = function() return options.modern and list.scrollBox:GetDataProvider().rows or list.classicDisplayList end,
	}
end
do
	local context = setup({})
	context.BFL.modules.DB.GetNickname = function(_, uid)
		if uid == "bnet_43" then return "Shared keyword" end
	end
	context.BFL.NativeFriendsSearch = {
		Matches = function(_, friend, text)
			return friend.bnetAccountID == 42 and text == "shared keyword"
		end,
	}
	context.list:SetSearchText("shared keyword", true)
	check(context.list:PassesFilters({ type = "bnet", bnetAccountID = 42 }), "A Blizzard-only match is included")
	check(context.list:PassesFilters({ type = "bnet", bnetAccountID = 43, uid = "bnet_43" }), "A BFL nickname match is included")
	check(context.list:PassesFilters({ type = "bnet", bnetAccountID = 44, note = "Shared keyword" }), "A BFL note match is included")
	check(not context.list:PassesFilters({ type = "bnet", bnetAccountID = 45 }), "A friend matching neither search is filtered")
end
local brokerSource = read("Modules/Broker.lua"):gsub("return Broker%s*$", "")
local function LoadBroker(context, testEntry)
	context.BFL.BrokerUtils = {}
	context.env.CreateFrame = function()
		local function noop() end
		return { Hide = noop, SetSize = noop, EnableMouse = noop, SetFrameStrata = noop }
	end
	return context.execute(brokerSource .. testEntry, "Broker")
end
do
	local context = setup({})
	local BFL = context.BFL
	BFL.QTip = {}
	local setTooltip = LoadBroker(context, "\ndataObject = {}; return function(frame) tooltip = frame end")
	local broker = BFL.Broker
	local timers = {}
	context.env.C_Timer.After = function(_, callback) timers[#timers + 1] = callback end
	local textUpdates = 0
	broker.UpdateBrokerText = function() textUpdates = textUpdates + 1 end
	local function FlushTimers()
		while #timers > 0 do
			local callback = table.remove(timers, 1)
			callback()
		end
	end

	broker:ScheduleBrokerTextUpdate(false)
	broker:ScheduleBrokerTextUpdate(false)
	equal(#timers, 1, "Broker text updates coalesce without a tooltip")
	FlushTimers()
	equal(textUpdates, 1, "Broker text updates with the tooltip closed")

	local filterTooltip = { bflBrokerFilterOpen = true, IsShown = function() return true end }
	setTooltip(filterTooltip)
	BFL.BrokerUtils.IsMenuOpen = function() return true end
	broker:ScheduleBrokerTextUpdate(false)
	broker:ScheduleObservedTooltipRefresh()
	FlushTimers()
	equal(textUpdates, 2, "An open filter menu does not block Broker text updates")
	check(filterTooltip.bflBrokerFilterDirty, "An open filter menu keeps the tooltip refresh pending")
end
do
	local context = setup({})
	local groupId = "tag:raid"
	local states = { [groupId] = true }
	context.env.BetterFriendlistDB.groupStates = states
	context.list.RenderDisplay = function() end
	local marker = 'groupRow:SetScript("OnMouseUp", function(frame, button)'
	local first = assert(brokerSource:find(marker, 1, true))
	local last = assert(brokerSource:find("\n\t\t\t\t\t\tend)", first, true))
	local installClick = context.execute("return function(groupRow, groupInfo, roster, Broker, groupId)\n"
		.. brokerSource:sub(first, last + #"\n\t\t\t\t\t\tend)") .. "\nend", "Broker group click")
	local click, renderedStates = nil, {}
	local row = { SetScript = function(_, _, callback) click = callback end }
	local broker = { RefreshTooltip = function() renderedStates[#renderedStates + 1] = states[groupId] end }
	installClick(row, { virtualTagGroup = true }, context.list, broker, groupId)
	click(row, "LeftButton")
	equal(renderedStates[1], false, "Clicking a collapsed tag group redraws the expanded tooltip")
	click(row, "LeftButton")
	equal(renderedStates[2], true, "Clicking an expanded tag group redraws the collapsed tooltip")
end
-- CustomNames v1.2.3a fires no Add/Update callback for an unlinked BattleTag.
do
	local tag = "42Solo#1234"
	local otherTag = "42Solo#5678"
	local otherAccount = normal(otherTag)
	otherAccount.bnetAccountID = 44
	local context = setup({ normal(tag), otherAccount }, { modern = true })
	local BFL, env, list = context.BFL, context.env, context.list
	local callbacks, aliases = {}, {}
	local customNames = {
		RegisterCallback = function(_, event, callback) callbacks[event] = callback end,
		Get = function(name) return aliases[name] or name end,
		Set = function(name, alias)
			if alias == "Rejected" then return false end
			local old = aliases[name]
			aliases[name] = alias
			if not alias and old then callbacks.Name_Removed("Name_Removed", name) end
			return true
		end,
	}
	env.LibStub = setmetatable({ GetLibrary = function() end }, {
		__call = function(_, name) if name == "CustomNames" then return customNames end end,
	})
	local installedHooks = 0
	env.hooksecurefunc = function(object, method, hook)
		local original = object[method]
		object[method] = function(...)
			local result = original(...)
			hook(...)
			return result
		end
		installedHooks = installedHooks + 1
	end
	function BFL:ScheduleFriendsListRefresh(reason) list:ScheduleRefresh(reason) end
	env.BetterFriendlistDB.colorClassNames = false
	env.BetterFriendlistDB.nicknames = { bnet_44 = "Unverified previous-session alias" }
	env.C_BattleNet.GetAccountInfoByID = function(id) if id == 44 then return otherAccount end end
	context.execute(read("Modules/Database.lua"), "Database")
	local db = BFL.DB
	db:Initialize()
	equal(installedHooks, 1, "CustomNames Set receives one post-hook")
	equal(aliases[otherTag], nil, "CustomNames never receives a numeric legacy key matched to a new account")
	equal(db:GetNickname("bnet_44"), nil, "BFL doesn't display an old alias under a new contact's account ID")
	db:Initialize()
	equal(installedHooks, 1, "Repeated initialization retains the same post-hook")
	db:Set("nameFormatPreset", "nickname")
	equal(db:GetLibKey("bnet_" .. tag), tag, "Digit-prefixed BattleTags are not mistaken for numeric account IDs")

	-- Track a real Broker refresh with mocked QTip drawing and the production name formatter.
	local brokerName, nicknameColumn, otherBrokerNickname
	local releases = 0
	BFL.QTip = { ReleaseTooltip = function() releases = releases + 1 end }
	local openBroker = LoadBroker(context, [[
return function(friend, anchor, paint)
	CreateLibQTipTooltip = function(nextAnchor)
		paint(GetFriendDisplayName(friend), GetBrokerNickname(friend), GetBrokerNickname({
			id = "bnet_42Solo#5678", type = "bnet", battleTag = "42Solo#5678",
		}))
		return { anchorFrame = nextAnchor, IsShown = function() return true end, IsMouseOver = anchor.IsMouseOver }
	end
	tooltip = CreateLibQTipTooltip(anchor)
end
]])
	local function DrainTimers()
		local count = 0
		while #context.timers > 0 do
			local timer = table.remove(context.timers, 1)
			if not timer.cancelled then timer.callback() end
			count = count + 1
			assert(count <= 40, "Unexpected timer loop")
		end
	end

	local hovered = true
	local function OpenBroker()
		openBroker({ id = "bnet_" .. tag, type = "bnet", battleTag = tag, accountName = "Other friend" },
			{ IsMouseOver = function() return hovered end }, function(name, nickname, otherNickname)
				brokerName, nicknameColumn, otherBrokerNickname = name, nickname, otherNickname
			end)
	end
	local function VisibleFriendName(battleTag) return list:ResolveFriendByUID("bnet_" .. (battleTag or tag)).displayName end
	list:UpdateFriendsList()
	db:SetNickname("bnet_" .. otherTag, "Other alias")
	DrainTimers()
	OpenBroker()

	local function CheckAlias(expected)
		check(VisibleFriendName():find(expected, 1, true), "Roster displays " .. expected)
		check(brokerName:find(expected, 1, true), "Broker name displays " .. expected)
		equal(nicknameColumn, expected, "Broker nickname column uses the current alias")
		check(VisibleFriendName(otherTag):find("Other alias", 1, true), "Roster keeps the other same-name account's alias")
		equal(otherBrokerNickname, "Other alias", "Broker keeps the other same-name account's alias")
		equal(env.BetterFriendlistDB.nicknames[tag], expected, "BFL keeps the confirmed alias for offline use")
	end

	check(customNames.Set(tag, "First alias"), "Unlinked BattleTag creation succeeds")
	DrainTimers()
	CheckAlias("First alias")
	equal(releases, 1, "Creation refreshes the already shown broker tooltip")

	local paints = context.paints()
	customNames.Set(tag, "Intermediate alias")
	customNames.Set(tag, "Latest alias")
	DrainTimers()
	CheckAlias("Latest alias")
	equal(context.paints(), paints + 1, "A burst of alias changes rebuilds the visible list once")
	equal(releases, 2, "A burst of alias changes refreshes the visible broker once")

	local version = BFL.NicknameCacheVersion
	equal(customNames.Set(tag, "Rejected"), false, "Post-hook preserves unsuccessful writes")
	DrainTimers()
	equal(BFL.NicknameCacheVersion, version, "A rejected write does not invalidate nicknames")
	CheckAlias("Latest alias")

	check(customNames.Set(tag, nil), "Nickname removal succeeds through the existing callback")
	DrainTimers()
	check(not VisibleFriendName():find("Latest alias", 1, true), "Removal clears the roster nickname")
	equal(nicknameColumn, "", "Removal clears the visible broker nickname")
	equal(env.BetterFriendlistDB.nicknames[tag], nil, "Removal clears the stored BFL alias")

	hovered = false
	context.setShown(false)
	customNames.Set(tag, "After reopening")
	DrainTimers()
	equal(releases, 3, "An unobserved broker tooltip does no work")
	context.setShown(true)
	context.hooks.OnShow()
	DrainTimers()
	hovered = true
	OpenBroker()
	CheckAlias("After reopening")
end

-- Both menu slots expose the new sorters and use the same order in the roster and Broker.
do
	local contacts = { normal("Beta#1234"), normal("PvP#1234"), normal("Alpha#1234") }
	local rules = { "PVE", "PVP", "PVE" }
	for index, contact in ipairs(contacts) do
		contact.bnetAccountID = index + 10
		contact.gameAccountInfo.realmName = "Realm " .. rules[index]
	end

	local context = setup(contacts, { modern = true })
	local BFL, list = context.BFL, context.list
	function BFL:ScheduleFriendsListRefresh(reason) list:ScheduleRefresh(reason) end
	local names = { ["bnet_Beta#1234"] = "Beta", ["bnet_PvP#1234"] = "Alpha", ["bnet_Alpha#1234"] = "Alpha" }
	BFL.modules.DB.GetNickname = function(_, uid) return names[uid] end
	context.execute(read("Modules/FriendsUI.lua"), "FriendsUI")
	BFL.FriendsUI.appliedStyle = "table"
	local function SelectModern(slot, id)
		for _, option in ipairs(BFL.FriendsUI:GetSortMenuItems()[slot].items) do
			if option.value == id then option.func(id); return true end
		end
		return false
	end
	local function SelectLegacy(slot, id)
		local options = {}
		list:PopulateSortMenu({ CreateRadio = function(_, _, _, select, value) options[value] = select end }, slot)
		if options[id] then options[id](id); return true end
		return false
	end

	local createBrokerComparator = LoadBroker(context, "\nreturn GetRosterComparator")
	local function AssertOrder(expectedSecond, expectedThird)
		list:UpdateFriendsList()
		equal(list.friendsList[1].battleTag, "Alpha#1234", "Both sort keys resolve the first contact")
		equal(list.friendsList[2].battleTag, expectedSecond, "FriendsList honors the primary and secondary choices")
		equal(list.friendsList[3].battleTag, expectedThird, "FriendsList resolves remaining ties")
		local brokerFriends = {}
		for index, contact in ipairs(contacts) do
			brokerFriends[index] = { id = "bnet_" .. contact.battleTag, gameAccountInfo = contact.gameAccountInfo, connected = true }
		end
		table.sort(brokerFriends, createBrokerComparator(BFL.modules.DB:Get()))
		equal(brokerFriends[1].id, "bnet_Alpha#1234", "Broker resolves aliases using its own contact record")
		equal(brokerFriends[2].id, "bnet_" .. expectedSecond, "Broker matches the order selected in the friend list")
	end

	check(SelectModern(1, "ruleset") and SelectModern(2, "nickname"), "Modern offers Ruleset primary and Nickname secondary")
	AssertOrder("Beta#1234", "PvP#1234")
	check(SelectModern(1, "nickname") and SelectModern(2, "ruleset"), "Modern offers Nickname primary and Ruleset secondary")
	AssertOrder("PvP#1234", "Beta#1234")
	check(SelectLegacy("primary", "ruleset") and SelectLegacy("secondary", "nickname"), "Legacy offers Ruleset primary and Nickname secondary")
	AssertOrder("Beta#1234", "PvP#1234")
	check(SelectLegacy("primary", "nickname") and SelectLegacy("secondary", "ruleset"), "Legacy offers Nickname primary and Ruleset secondary")
	AssertOrder("PvP#1234", "Beta#1234")

	local registry = BFL:GetModule("FilterSortRegistry")
	context.env.BetterFriendlistDB.enableBetaFeatures = true
	local custom = registry:CreateCustomSorter("faction")
	list:SetTertiarySortEnabled(true)
	local menu = BFL.FriendsUI:GetSortMenuItems()
	local tertiary = {}
	for _, option in ipairs(menu[3].items) do tertiary[#tertiary + 1] = option.value end
	local expected = {}
	for _, option in ipairs(menu[2].items) do
		if option.value ~= list.secondarySort then expected[#expected + 1] = option.value end
	end
	equal(table.concat(tertiary, ","), table.concat(expected, ","), "Modern tertiary offers the remaining secondary choices in order")
	local legacy = {}
	list:PopulateSortMenu({ CreateRadio = function(_, _, _, _, id) legacy[#legacy + 1] = id end }, "tertiary")
	equal(table.concat(legacy, ","), table.concat(expected, ","), "Legacy tertiary offers the same choices as Modern")
	check(SelectLegacy("tertiary", custom), "Tertiary accepts a visible custom sorter")
	check(SelectModern(2, custom), "A tertiary criterion can be moved to secondary")
	equal(BFL.modules.DB:Get("tertiarySort"), "none", "Moving a criterion to secondary clears the conflicting tertiary selection")
	check(SelectModern(3, "ruleset") and SelectModern(1, "ruleset"), "A tertiary criterion can be moved to primary")
	equal(BFL.modules.DB:Get("tertiarySort"), "none", "Moving a criterion to primary clears the conflicting tertiary selection")
end
-- A layout switch replaces the view without rebinding the animated scroll pair.
for _, preference in ipairs({ {}, { value = false }, { value = true } }) do
	local context = setup({}, { smoothScrolling = preference.value })
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
			equal(box.interpolate, preference.value == true, "Saved interpolation preference applies before Blizzard binds the ScrollBox")
			equal(bar.interpolate, preference.value == true, "Saved interpolation preference applies before Blizzard binds the scroll bar")
			bindings = bindings + 1
			box:SetView(view)
		end,
	}
	context.BFL.HasModernScrollBox = true
	context.list:InitializeScrollBox()
	equal(scrollBox.interpolate, preference.value == true, "Smooth scrolling requires explicit opt-in")
	equal(scrollBar.interpolate, preference.value == true, "Both native scroll controls share the preference")
	equal(bindings, 1, "The scroll pair is bound on first initialization")
	local firstView = scrollBox.view
	context.list:InitializeScrollBox()
	check(scrollBox.view ~= firstView, "A layout switch replaces the scroll view")
	equal(bindings, 1, "A layout switch keeps the existing scroll binding")
	equal(scrollBox.interpolate, preference.value == true, "The interpolation preference survives the layout switch")
	equal(scrollBar.interpolate, preference.value == true, "The bar preference survives the layout switch")
	context.BFL.modules.DB:Set("enableSmoothScrolling", true)
	equal(context.list:ApplyScrollInterpolation(), true, "Preference can be enabled live")
	context.BFL.modules.DB:Set("enableSmoothScrolling", false)
	equal(context.list:ApplyScrollInterpolation(), false, "Preference can be disabled live")
	check(not scrollBox.interpolate and not scrollBar.interpolate, "Live disable immediately restores stepped scrolling")
	equal(bindings, 1, "Live preference changes do not rebind native callbacks")
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
	local context = setup({ account }, { modern = modern, showFactionIcons = true })
	local seasonIcon = "|TTimerunningIcon:12:12|t"
	context.env.TimerunningUtil = { AddSmallIcon = function(name) return seasonIcon .. name end }
	context.list:UpdateFriendsList()
	local friend = context.list.friendsList[1]
	local initial = context.list:GetDisplayName(friend)
	check(initial:find("PlusManz-", 1, true) and not initial:find("(", 1, true), "The default Title name keeps its faction icon without parentheses")
	friend.timerunningSeasonID = 1
	equal(context.list:GetDisplayName(friend), initial:gsub("Ada Lovelace", seasonIcon .. "Ada Lovelace"),
		"The Title name cache updates when the character gains a Timerunning icon")
	friend.timerunningSeasonID = nil
	equal(context.list:GetDisplayName(friend), initial, "The Title name cache drops the old Timerunning icon")
end
for _, modern in ipairs({ false, true }) do
	local account = title()
	account.accountName = "Raizor Spellweaver"
	account.gameAccountInfo.characterName = account.accountName
	for _, format in ipairs({ "%nickname% (%character%)", "%battletag% (%character%)" }) do
		local context = setup({ account }, { modern = modern, nameFormat = format, showFactionIcons = true, colorClassNames = true })
		context.list:UpdateFriendsList()
		local line = context.list:GetFormattedButtonText(context.list.friendsList[1])
		check(line:find("PlusManz-", 1, true), "The Title character keeps its faction icon in the rendered row")
		check(line:find("|cffc79c6e", 1, true), "The Title character keeps its class color in the rendered row")
		local _, occurrences = line:gsub("Raizor Spellweaver", "")
		check(occurrences == 1 and not line:find("(", 1, true), "A missing nickname or BattleTag must not repeat a Title character: " .. line)
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
do
	local large = {}
	for index = 1, 150 do large[index] = title(index) end
	local context = setup(large, { modern = true })
	local reads = 0
	local getAccount = context.BFL.GetBNetFriendInfo
	context.BFL.GetBNetFriendInfo = function(index)
		reads = reads + 1
		return getAccount(index)
	end

	context.list:UpdateFriendsList()
	local firstTimer
	for index, timer in ipairs(context.timers) do
		if timer.delay == 0 then firstTimer = index; break end
	end
	check(firstTimer ~= nil, "Start a chunked roster update")
	context.timers[firstTimer].callback()
	check(reads > 0 and reads < #large, "Only the first slice has read accounts")
	local readsAtClose = reads
	context.setShown(false)
	context.timers[firstTimer + 1].callback()
	equal(reads, readsAtClose, "A closed frame cancels the rest of the roster reads")
	check(context.list.chunkedFriendsListUpdate == nil and #context.list.friendsList == 0,
		"Cancellation releases the worker and keeps the previous snapshot")

	context.setShown(true)
	context.hooks.OnShow()
	local timerIndex = firstTimer + 2
	while timerIndex <= #context.timers do
		check(timerIndex < firstTimer + 100, "Reopen completes in bounded next-frame work")
		local timer = context.timers[timerIndex]
		if not timer.cancelled and timer.delay == 0 then timer.callback() end
		timerIndex = timerIndex + 1
	end
	equal(visibleCount(context), #large, "Reopening publishes a complete roster")
end
do
	local context = setup({})
	local list, BFL = context.list, context.BFL
	local db = BFL:GetModule("DB")
	local registry = BFL:GetModule("FilterSortRegistry")
	BFL.ScheduleFriendsListRefresh = function() end
	local reads = 0
	db.GetNickname = function(_, uid)
		reads = reads + 1
		return uid
	end
	local function Friend(name, ruleset, faction, favorite)
		return { type = "bnet", uid = name, battleTag = name .. "#2345", connected = true,
			isFavorite = favorite == true, factionName = faction,
			gameAccountInfo = { clientProgram = "WoW", wowProjectID = 18, isOnline = true,
				richPresence = "Forever - " .. ruleset .. " - Elwynn" } }
	end
	local rows = {
		Friend("Ally PvP", "PvP", "Alliance"),
		Friend("Ally Horde", "Normal", "Horde"),
		Friend("Zed", "Normal", "Alliance", true),
		Friend("Ally", "Normal", "Alliance"),
	}
	list.sortMode, list.secondarySort = "ruleset", "faction"
	list.friendsList = rows
	db:Set("tertiarySort", "nickname")
	list:ApplySort()
	equal(reads, 0, "an opt-out never evaluates a third sort key")
	equal(rows[1].uid, "Zed", "existing favorite priority is preserved with third sort off")
	list:SetTertiarySortEnabled(true)
	list:ApplySort()
	equal(reads, 2, "third-stage nickname lookup is limited to the tied pair")
	equal(rows[1].uid, "Ally", "third sort breaks a tie after ruleset and faction")
	equal(rows[2].uid, "Zed", "implicit favorites follow the three explicit criteria")
	equal(rows[3].uid, "Ally Horde", "faction takes precedence over nickname")
	equal(rows[4].uid, "Ally PvP", "ruleset takes precedence over faction")
	equal(registry:NormalizeTertiarySorterId("faction", "ruleset", "faction"), "none", "a duplicate selection is inactive")
	equal(registry:NormalizeTertiarySorterId("missing"), "none", "an invalid selection never silently takes effect")

	local comparatorStart = assert(brokerSource:find("local function GetRosterComparator", 1, true))
	local comparatorEnd = assert(brokerSource:find("-- ========================================", comparatorStart, true))
	local comparatorFactory = context.execute(
		"local function GetFilterSortRegistry() return BFL:GetModule('FilterSortRegistry') end\n"
			.. brokerSource:sub(comparatorStart, comparatorEnd - 1) .. "\nreturn GetRosterComparator", "broker comparator")
	local brokerOptions = { primarySort = "ruleset", secondarySort = "faction", tertiarySort = "nickname", enableTertiarySort = true }
	local reverse = { rows[4], rows[3], rows[2], rows[1] }
	table.sort(reverse, comparatorFactory(brokerOptions))
	for index, friend in ipairs(rows) do equal(reverse[index], friend, "broker and friends list share the three-stage order") end
	list:SetTertiarySortEnabled(false)
	equal(db:Get("tertiarySort"), "nickname", "disabling the feature retains the configured third sort")
	list:ApplySort()
	equal(rows[1].uid, "Zed", "disabling the feature restores the previous sort rules")
end
-- The conditional status is usable by itself and can be colored as a custom field.
do
	local context = setup({})
	local list = context.list
	list.settingsCache.infoFormatPreset = "custom"
	list.settingsCache.infoFormatString = "%statusonline%"
	local friend = { type = "wow", name = "Testfriend", uid = "wow_Testfriend", connected = true }
	equal(list:FormatInfoLine(friend), "", "Ordinary online presence has no conditional status")
	friend.afk = true
	equal(list:FormatInfoLine(friend), "AFK", "AFK appears in the conditional status field")
	friend.afk, friend.dnd = false, true
	list.settingsCache.friendFormatColors = { statusonline = { r = 1, g = 0, b = 0 } }
	equal(list:FormatInfoLine(friend), "|cffff0000DND|r", "Custom color applies to the conditional status")
	list.settingsCache.infoFormatString = "[ %statusonline% ]"
	equal(list:FormatInfoLine(friend), "|cffff0000[ DND ]|r", "An info field's brackets and spaces share its custom color")
	list.settingsCache.infoFormatString = "%statusonline%"
	friend.connected = false
	equal(list:FormatInfoLine(friend), "", "Offline presence clears the conditional status")
end
-- Status events still update the broker counter while both roster views are closed.
do
	local context = setup({ normal("Alpha#1234"), title(42) })
	local BFL, env, list = context.BFL, context.env, context.list
	local settings = env.BetterFriendlistDB
	settings.brokerEnabled = true
	settings.enableTertiarySort, settings.tertiarySort = true, "nickname"
	BFL.modules.DB:Set("enableTertiarySort", true)
	BFL.modules.DB:Set("tertiarySort", "nickname")
	function BFL:RegisterEventCallback(event, callback, _, gate)
		self.EventCallbacks[event] = self.EventCallbacks[event] or {}
		table.insert(self.EventCallbacks[event], { callback = callback, gate = gate })
	end
	local dataObject, countReads = nil, 0
	env.LibStub = { GetLibrary = function()
		return { NewDataObject = function(_, _, definition) dataObject = definition; return definition end }
	end }
	BFL.QTip = {}
	BFL.GetNumOnlineWoWFriends = function() countReads = countReads + 1; return 0 end
	env.GetTime = function() return 100 end
	env.BNConnected = function() return true end
	local setTooltip = LoadBroker(context, "\nreturn function(frame) tooltip = frame; brokerTooltipEventGate.active = frame ~= nil end")
	BFL.Broker:Initialize()
	check(dataObject, "Broker registered its display object")
	check(countReads > 0, "Broker initialized its count display")
	list:UpdateFriendsList()
	context.setShown(false)
	local sortCalls = 0
	env.table = setmetatable({ sort = function(...)
		sortCalls = sortCalls + 1
		return table.sort(...)
	end }, { __index = table })

	local timerIndex = 1
	local function FlushTimers()
		while timerIndex <= #context.timers do
			assert(timerIndex <= 40, "Unexpected timer loop")
			local timer = context.timers[timerIndex]
			if not timer.cancelled then timer.callback() end
			timerIndex = timerIndex + 1
		end
	end
	local initialCountReads = countReads
	BFL:FireEventCallbacks("BN_FRIEND_INFO_CHANGED", 1)
	FlushTimers()
	equal(countReads, initialCountReads, "Presence detail changes leave the unfiltered closed broker on its fast path")

	for _, event in ipairs({ "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE" }) do
		BFL:FireEventCallbacks(event, 1, false)
	end
	local tooltipShown = true
	setTooltip({ IsShown = function() return tooltipShown end, IsMouseOver = function() return tooltipShown end })
	BFL.Broker:ScheduleObservedTooltipRefresh(true)
	tooltipShown = false
	local startingCountReads = countReads
	FlushTimers()
	check(countReads > startingCountReads, "The closed broker still refreshes its count display")
	settings.quickFilter, settings.brokerShowLabel = "hideafk", false
	BFL.Broker:ScheduleBrokerTextUpdate()
	FlushTimers()
	equal(dataObject.text, "2/2", "The filtered label starts with two active friends")
	context.accounts[1].isAFK = true
	BFL:FireEventCallbacks("BN_FRIEND_INFO_CHANGED", 1)
	FlushTimers()
	equal(dataObject.text, "1/2", "A status change updates the filtered label with both views closed")
	equal(sortCalls, 0, "Closing both views prevents sorting after friend events and a pending tooltip refresh")
	context.setShown(true)
	context.hooks.OnShow()
	check(sortCalls > 0, "Reopening sorts the pending roster")
end
-- Character additions bypass both timers without expediting status events.
for _, classic in ipairs({ false, true }) do
	local context = setup({ normal("Existing#1234") }, { classic = classic, modern = not classic })
	context.env.RegionalUniqueNamesEnabled = function() return false end
	context.BFL.IsForever = false
	local characterFriends = {}
	context.env.C_FriendList.GetNumFriends = function() return #characterFriends end
	context.env.C_FriendList.GetFriendInfoByIndex = function(index) return characterFriends[index] end
	context.list:UpdateFriendsList()

	context.BFL:FireEventCallbacks("FRIENDLIST_UPDATE")
	local status = context.timers[#context.timers]
	equal(status.delay, 0.2, "An ordinary status event still waits for the Core debounce")
	characterFriends[1] = { name = "Newfriend", connected = true, level = 30, className = "Warrior", area = "Elwynn" }
	context.BFL:FireEventCallbacks("FRIENDLIST_UPDATE")
	local addition = context.timers[#context.timers]
	check(status.cancelled, "A new character friend supersedes the pending status debounce")
	equal(addition.delay, 0, "A confirmed character addition dispatches the callbacks next frame")
	context.BFL:FireEventCallbacks("FRIENDLIST_UPDATE")
	equal(context.timers[#context.timers], addition, "Event bursts do not postpone the queued addition")
	addition.callback()

	local rosterRefresh = context.timers[#context.timers]
	equal(rosterRefresh.delay, 0, "The confirmed character addition also bypasses the list's status timer")
	rosterRefresh.callback()
	equal(visibleCount(context), 2, "The new character is visible through the production render path")
end

-- Accepted Battle.net and Title invitations publish when the roster has the friend.
for _, friend in ipairs({ normal("New#1234"), title(42) }) do
	local context = setup({ title(99) }, { modern = true })
	context.list:UpdateFriendsList()
	context.list:OnFriendListUpdate()
	local status = context.timers[#context.timers]
	equal(status.delay, 0.1, "The list batches ordinary status updates")
	context.BFL:FireEventCallbacks("BN_FRIEND_INVITE_REMOVED")
	local requestRefresh = context.timers[#context.timers]
	equal(requestRefresh.delay, 0.05, "An invite disappearing alone keeps the ordinary fallback")
	equal(visibleCount(context), 1, "The invite event alone does not invent a friend")

	context.accounts[2] = friend
	local previousPaints = context.paints()
	context.BFL:FireEventCallbacks("BN_FRIEND_LIST_SIZE_CHANGED")
	local rosterRefresh = context.timers[#context.timers]
	check(status.cancelled and requestRefresh.cancelled, "The confirmed roster change subsumes pending refreshes")
	equal(rosterRefresh.delay, 0, "Both friend types refresh the next frame after the size change")
	equal(context.paints(), previousPaints, "A synchronous accept event cannot rebuild the list in its responder")
	context.BFL:FireEventCallbacks("BN_FRIEND_INVITE_REMOVED")
	context.BFL:FireEventCallbacks("BN_FRIEND_LIST_SIZE_CHANGED")
	equal(context.timers[#context.timers], rosterRefresh, "Coalesced invite and size events share one refresh")
	rosterRefresh.callback()
	equal(visibleCount(context), 2, "The accepted Battle.net or Title friend is visible")
	equal(context.paints(), previousPaints + 1, "One roster change produces one display update")
end

do
	local options = { count = 1 }
	local context = setup({ normal("Existing#1234") }, options)
	context.list:UpdateFriendsList()
	options.count = 2
	context.BFL:FireEventCallbacks("BN_FRIEND_LIST_SIZE_CHANGED")
	context.timers[#context.timers].callback()
	equal(visibleCount(context), 1, "A reported addition without data retains the complete old list")
	local retry = context.timers[#context.timers]
	equal(retry.delay, 0.2, "An incomplete snapshot keeps the bounded retry")
	context.accounts[2] = title()
	retry.callback()
	equal(visibleCount(context), 2, "A Title friend appears once its account record is available")
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
-- These are the same fixture situations used by the settings comparisons.
for _, classic in ipairs({ false, true }) do
	local context = setup({}, { classic = classic })
	local list, project = context.list, context.env.WOW_PROJECT_ID
	local function Match(program, mode, projectID)
		return list:IsFriendInGameForGroup({ type = "bnet", connected = true,
			gameAccountInfo = { isOnline = true, clientProgram = program, wowProjectID = projectID } }, mode)
	end
	check(list:IsFriendInGameForGroup({ type = "wow", connected = true }, "same_game"), "online character friend belongs to In-Game")
	check(not list:IsFriendInGameForGroup({ type = "wow", connected = false }, "any_game"), "offline character friend stays out of In-Game")
	check(Match("WoW", "same_game", project), "same WoW flavor appears in WoW Only")
	check(not Match("WoW", "same_game", project + 1), "different WoW flavor stays out of WoW Only")
	check(not Match("WTCG", "same_game", project) and Match("WTCG", "any_game"), "other games appear only in Any Game")
	check(not Match("App", "any_game") and not Match("BSAp", "any_game"), "Battle.net desktop and mobile app stay out of Any Game")

	local mappings = { a = "tag:a", b = "tag:b" }
	local groups = { ["tag:a"] = {}, ["tag:b"] = {} }
	local tags = { { id = "b" }, { id = "a" } }
	local matched, prioritized = {}, {}
	list:AppendDynamicTagGroups(tags, mappings, groups, {}, matched, false)
	list:AppendDynamicTagGroups(tags, mappings, groups, {}, prioritized, true)
	equal(table.concat(matched, ","), "tag:b,tag:a", "multiple matches follow the supplied tag order")
	equal(table.concat(prioritized, ","), "tag:b", "the first matching group wins when prioritized")
end

do
	local context = setup({}, { modern = true })
	local list, env, BFL = context.list, context.env, context.BFL
	local groupId = "tag:test"
	local first, second = { name = "First" }, { name = "Second" }
	local header = { buttonType = 2, groupId = groupId, collapsed = true, count = 2 }
	local nextHeader = { buttonType = 2, groupId = "tag:next" }
	local createProvider = env.CreateDataProvider
	env.CreateDataProvider = function()
		local provider = createProvider()
		function provider:Enumerate() return ipairs(self.rows) end
		return provider
	end
	local provider = env.CreateDataProvider()
	provider:Insert(header)
	provider:Insert(nextHeader)
	list.scrollBox:SetDataProvider(provider)
	list.groupedFriends = { [groupId] = { first, second } }
	env.BetterFriendlistDB.groupStates = { [groupId] = true }
	BFL.SettingsVersion = 5
	BFL.ForceRefreshFriendsList = function() error("Toggling a tag group must not reload friends") end
	local function Toggle()
		list:ToggleGroup(groupId)
		return context.rows()
	end
	local rows = Toggle()
	equal(#rows, 4, "Expanding inserts only the displayed members")
	equal(rows[2].friend, first, "Expanding preserves the filtered sort order")
	equal(rows[3].friend, second, "The second filtered friend follows the first")
	equal(rows[4], nextHeader, "Expanding preserves the next group")
	equal(header.collapsed, false, "Expanding updates the header")
	rows = Toggle()
	equal(#rows, 2, "Collapsing removes the tag group's rows")
	equal(rows[2], nextHeader, "Collapsing leaves the next group untouched")
	equal(env.BetterFriendlistDB.groupStates[groupId], true, "The collapsed state persists")
	equal(#Toggle(), 4, "Repeated toggles keep the member cache usable")
	equal(BFL.SettingsVersion, 5, "A display-only toggle does not invalidate settings")
	list.scrollBox = nil
	local rendered = false
	list.RenderDisplay = function(self)
		check(self.lastBuildSignature == nil, "The fallback invalidates the display cache")
		rendered = true
	end
	list:ToggleGroup(groupId)
	check(rendered, "The fallback redraws without reloading friends")
end

-- Dynamic tag groups classify presence independently from the list filter.
for _,project in ipairs({1,18,2,5,11,14,19}) do
	local context=setup({})
	context.env.WOW_PROJECT_ID=project
	local list=context.list
	local function friend(client,id,online)
		return {type="bnet",connected=online~=false,gameAccountInfo={clientProgram=client,wowProjectID=id,isOnline=online~=false}}
	end
	local mode="same_flavor_online"
	check(list:PassesDynamicTagGroupFilter(friend("WoW",project),mode),"same flavor qualifies on each supported project")
	check(not list:PassesDynamicTagGroupFilter(friend("WoW",project+100),mode),"another flavor goes to the default group")
	check(not list:PassesDynamicTagGroupFilter(friend("WoW",nil),mode),"missing flavor metadata is not guessed")
	check(not list:PassesDynamicTagGroupFilter(friend("WoW",project,false),mode),"offline same-flavor friends do not qualify")
	check(list:PassesDynamicTagGroupFilter({type="wow",connected=true},mode),"online local WoW friends use the current flavor")
	check(not list:PassesDynamicTagGroupFilter({type="wow",connected=false},mode),"offline local friends fall back")
	for _,client in ipairs({"App","BSAp","CLNT"}) do
		local app=friend(client)
		check(list:PassesDynamicTagGroupFilter(app,mode),"online app-only contacts qualify")
		app.gameAccounts={{clientProgram="WTCG",isOnline=true}}
		check(not list:PassesDynamicTagGroupFilter(app,mode),"a parallel app session does not admit another game")
		app.gameAccounts[2]={clientProgram="WoW",wowProjectID=project,isOnline=true}
		check(list:PassesDynamicTagGroupFilter(app,mode),"an additional online matching WoW account qualifies")
	end
	check(not list:PassesDynamicTagGroupFilter(friend("WTCG"),mode),"other online games do not qualify")
	check(list:PassesDynamicTagGroupFilter(friend("WTCG"),"all"),"default preserves all online games")
	check(list:PassesDynamicTagGroupFilter(friend("WoW",project,false),"all"),"default preserves offline contacts")
	local hidden=friend("App");hidden.gameAccounts=protectedAccount
	check(not list:PassesDynamicTagGroupFilter(hidden,mode),"restricted account lists cannot prove app-only presence")
	hidden=friend("WoW",project);hidden.gameAccountInfo.wowProjectID=protectedAccount
	check(not list:PassesDynamicTagGroupFilter(hidden,mode),"secret project IDs are never compared")
end

for _,modern in ipairs({false,true}) do
	local context=setup({}, {modern=modern})
	local list,BFL=context.list,context.BFL
	local preference={enableDynamicTagGroups=true,dynamicTagGroupFilter="all"}
	local definitions={{id="custom:a",name="A",order=1},{id="custom:b",name="B",order=2}}
	BFL.modules.FriendTags={
		IsEnabled=function()return true end,
		GetSetting=function(_,key,fallback)if preference[key]~=nil then return preference[key] end;return fallback end,
		GetAllTagDefinitions=function()return definitions end,
		GetChipProfile=function(_,tag)return {visible=true,order=tag.order} end,
		ShouldIncludeTagOnSurface=function()return true end,
		CanDisplayTags=function(_,surface)return surface=="group" end,
		GetChipLabel=function(_,tag)return tag.name end,
		GetTagsForFriend=function()return definitions end,
	}
	local tagSource = read("Modules/FriendTags.lua")
	local first = assert(tagSource:find("function FriendTags:GetDynamicGroups(", 1, true))
	local last = assert(tagSource:find("function FriendTags:GetTagIdsForFriend(", first, true))
	context.env.FriendTags = BFL.modules.FriendTags
	context.execute("local EMPTY_TABLE = {}\n" .. tagSource:sub(first, last - 1), "dynamic tag groups")
	local function record(id,client,project,online)
		return {uid="bnet_"..id,type="bnet",battleTag=id,accountName=id,connected=online,
			gameAccountInfo={clientProgram=client,wowProjectID=project,isOnline=online}}
	end
	list.friendsList={record("Same","WoW",18,true),record("Other","WoW",1,true),record("App","App",nil,true),
		record("Game","WTCG",nil,true),record("Offline","WoW",18,false)}
	local function render()
		BFL.SettingsVersion=(BFL.SettingsVersion or 0)+1
		list:RenderDisplay(true)
	end
	render()
	equal(#list:GetFriendsForGroup("tag:custom:a"),5,"default keeps all tagged friends")
	preference.dynamicTagGroupFilter="same_flavor_online";render()
	equal(#list:GetFriendsForGroup("tag:custom:a"),2,"restricted tag groups contain only matching WoW and app contacts")
	equal(#list:GetFriendsForGroup("tag:custom:b"),2,"multiple matching tags remain available")
	equal(#list:GetFriendsForGroup("nogroup"),3,"other flavors, games and offline contacts remain reachable in Friends")
	for _,row in ipairs(context.rows()) do
		if row.groupId=="tag:custom:a" and not row.friend then
			equal(row.totalCount,2,"tag totals follow the grouping rule")
			equal(row.onlineCount,2,"tag online totals follow the same rule")
		end
	end
	list.groupedFriends,list.cachedGroupedFriends=nil,nil
	equal(#list:GetFriendsForGroup("tag:custom:a"),2,"uncached group expansion uses the same eligibility rule")
	equal(#list:GetFriendsForGroup("nogroup"),3,"uncached Friends membership matches rendered membership")
	list.friendsList[2].gameAccountInfo.wowProjectID=18;render()
	equal(#list:GetFriendsForGroup("tag:custom:a"),3,"changing flavor moves a friend back into tag groups")
	list.friendsList[1].connected=false;render()
	equal(#list:GetFriendsForGroup("nogroup"),3,"going offline moves the friend into Friends")
	preference.dynamicTagGroupFilter="all";render()
	equal(#list:GetFriendsForGroup("tag:custom:a"),5,"turning the option off restores all assignments")

	context.execute(read("Modules/Groups.lua"), "Modules/Groups.lua")
	local normalGroup = { id = "nogroup", name = "Friends", builtin = true }
	BFL.Groups.groups = { nogroup = normalGroup }
	local states, refreshes = {}, 0
	context.env.BetterFriendlistDB.groupStates = states
	BFL.modules.DB.SetGroupState = function(_, id, collapsed) states[id] = collapsed end
	local renderDisplay = list.RenderDisplay
	list.RenderDisplay = function(self, ...)
		refreshes = refreshes + 1
		return renderDisplay(self, ...)
	end
	list.GetInvitableCount = function() return 0 end
	local function ClickGroupMenu(group, label)
		local button = {
			dropHighlight = {},
			SetScript = function(self, script, callback) self[script] = callback end,
			RegisterForClicks = function() end,
			Show = function() end,
		}
		local menu
		BFL.OpenSimpleContextMenu = function(_, _, items)
			menu = type(items) == "function" and items() or items
		end
		group.groupId, group.count = group.id, 0
		list:UpdateGroupHeaderButton(button, group)
		button:OnClick("RightButton")
		for _, item in ipairs(assert(menu)) do
			if item.text == label then
				item.func()
				return
			end
		end
		error("Missing group menu action: " .. label)
	end
	local tagGroupId = "tag:custom:a"
	ClickGroupMenu(normalGroup, BFL.L.MENU_COLLAPSE_ALL)
	equal(refreshes, 1, "Collapse All redraws once for all group types")
	check(normalGroup.collapsed and states.nogroup and states[tagGroupId] and states["tag:custom:b"],
		"Collapse All persists ordinary and dynamic group state")
	local function CountTagGroupRows()
		local count = 0
		for _, row in ipairs(context.rows()) do
			if row.groupId == tagGroupId and row.friend then count = count + 1 end
		end
		return count
	end
	equal(CountTagGroupRows(), 0, "Collapsed tag group hides friend rows")
	local tagGroups = BFL.modules.FriendTags:GetDynamicGroups()
	local tagGroup = tagGroups[1]
	ClickGroupMenu(tagGroup, BFL.L.MENU_EXPAND_ALL)
	equal(refreshes, 2, "Expand All from a tag header redraws once")
	check(normalGroup.collapsed == false and states.nogroup == false and states[tagGroupId] == false
		and states["tag:custom:b"] == false, "Expand All opens ordinary and dynamic groups")
	equal(CountTagGroupRows(), 5, "Expanded tag group shows its friends again")

	preference.enableDynamicTagGroups=false;render()
	equal(#list:GetFriendsForGroup("nogroup"),5,"disabling dynamic groups restores ordinary grouping")
	ClickGroupMenu(normalGroup, BFL.L.MENU_COLLAPSE_ALL)
	check(normalGroup.collapsed and states[tagGroupId] == false, "Disabled dynamic groups keep their saved state")
end
do
	local context=setup({})
	local reviewSource=read("Modules/LegacySettingsReview.lua")
	local first=assert(reviewSource:find("local function BuildTagGroupComparison",1,true))
	local last=assert(reviewSource:find("function Review:RenderComparisonLane",first,true))
	local env=setmetatable({Text=function(key)return key end},{__index=_G})
	local compare=assert(load(reviewSource:sub(first,last-1).."\nreturn BuildTagGroupComparison","@tag grouping comparison","t",env))()
	local tags={CreateSettingsTagExamples=function()return {{id="a",name="A"},{id="b",name="B"}} end}
	local entry={friend={type="bnet",connected=false,uid="example"}}
	local options={enableDynamicTagGroups=true,dynamicTagGroupFilter="same_flavor_online"}
	local result=compare(context.list,entry,tags,options)
	equal(result[1].groupId,"nogroup","filtered comparison shows the default group")
	equal(result[1].onlineCount,0,"offline comparison never counts a contact as online")
	options.dynamicTagGroupFilter="all"
	result=compare(context.list,entry,tags,options)
	equal(#result,2,"All Contacts comparison preserves both matching tags")
	equal(result[1].onlineCount,0,"unfiltered comparison has correct offline totals")
end
io.write("[OK] FriendsList startup smoke: " .. assertions .. " assertions (complete production module; mocked C APIs/widgets)\n")
