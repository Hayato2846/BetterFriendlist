-- Run with Lua 5.4: lua tools/BFL-ForeverFilterSmoke.lua <repo>
-- Executes the real registry, quick-filter menu, list filter and broker paths.
local repoRoot = assert(arg[1], "repository root argument is required")
local separator = package.config:sub(1, 1)
local function read(path)
	local file = assert(io.open(repoRoot .. separator .. path:gsub("/", separator), "rb"))
	local source = file:read("*a")
	file:close()
	return source
end
local function between(source, first, last)
	local start = assert(source:find(first, 1, true), "missing source anchor: " .. first)
	local finish = assert(source:find(last, start + #first, true), "missing source anchor: " .. last)
	return source:sub(start, finish - 1)
end
local BFL = { L = { FILTER_FOREVER = "WoW Forever Only" }, modules = {}, BrokerUtils = {} }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
local env = setmetatable({ BFL = BFL, SlashCmdList = {}, BetterFriendlistDB = {}, BNET_CLIENT_WOW = "WoW",
	WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = 18, unpack = table.unpack }, { __index = _G })
env.GetTime = function() return 100 end
env.wipe = function(target) for key in pairs(target) do target[key] = nil end; return target end
local function execute(source, name)
	return assert(load(source, "@" .. name, "t", env))("BetterFriendlist", BFL)
end
execute(read("Utils/ClassicCompat.lua"), "ClassicCompat")
execute(read("Utils/FriendNotes.lua"), "FriendNotes")
execute(read("Modules/FilterSortRegistry.lua"), "FilterSortRegistry")
local registry = BFL.modules.FilterSortRegistry
local suite = execute(read("Modules/TestSuite.lua"), "TestSuite")
local tests = {}
function suite:RegisterTest(_, name, test) tests[name] = test end
suite:RegisterForeverQuickFilterTests()
suite:RegisterBuiltinQuickFilterMultiAccountTest()
local assertions = 0
local V = {}
function V:Assert(value, message) assertions = assertions + 1; assert(value, message) end
function V:AssertEqual(actual, expected, message)
	self:Assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
tests.Registry_ForeverQuickFilterContracts.action(V)
tests.Registry_BuiltinFilters_MatchSecondaryBNetGameAccount.action(V)
env.BetterFriendlistDB = { quickFilter = "forever" }
BFL.IsForever = true
registry:InvalidateCaches()

-- Test the real modern menu and selection, with lightweight descriptions.
execute(read("Modules/QuickFilters.lua"), "QuickFilters")
local quickFilters = BFL.modules.QuickFilters
local menu
menu = function()
	local root = { children = {}, radios = {} }
	function root:SetTag() end
	function root:SetMinimumWidth() end
	function root:SetMaximumWidth() end
	function root:CreateTitle() end
	function root:CreateButton(label) local child = menu(); child.label = label; self.children[#self.children + 1] = child; return child end
	function root:CreateRadio(label, selected, select, id) self.radios[#self.radios + 1] = { label = label, selected = selected, select = select, id = id } end
	return root
end
local root = menu()
quickFilters:PopulateMenu(root)
local foreverRadio
for _, radio in ipairs(root.children[1].radios) do if radio.id == "forever" then foreverRadio = radio end end
V:Assert(foreverRadio ~= nil, "The existing quick-filter submenu exposes Forever")
V:Assert(foreverRadio.label:find("WoW Forever Only", 1, true), "The submenu uses the localized label")
V:Assert(foreverRadio.selected("forever"), "The menu reflects a restored Forever selection")
env.BetterFriendlistDB.quickFilter = "all"
foreverRadio.select("forever")
V:AssertEqual(env.BetterFriendlistDB.quickFilter, "forever", "Selecting Forever saves the stable ID")
V:AssertEqual(quickFilters:GetFilterText(), "WoW Forever Only", "The header/tooltip label reflects Forever")

-- Exercise the list's actual predicate without search UI dependencies.
env.FriendsList = { filterMode = "forever" }
env.GetFilterSortRegistry = function() return registry end
local friendsSource = read("Modules/FriendsList.lua")
execute(between(friendsSource, "function FriendsList:PassesFilters(", "function FriendsList:"), "FriendsList filter")

-- Test fresh broker counts: focused Retail, secondary Forever, offline and App.
local focused = { clientProgram = "WoW", wowProjectID = 1, isOnline = true }
local secondary = { clientProgram = "WoW", wowProjectID = 18, isOnline = true }
local allAccounts = {
	{ focused, secondary },
	{ { clientProgram = "WoW", wowProjectID = 18, isOnline = false } },
	{ { clientProgram = "App", isOnline = true } },
}
env.C_BattleNet = {
	GetFriendNumGameAccounts = function(index) return #allAccounts[index] end,
	GetFriendGameAccountInfo = function(index, accountIndex) return allAccounts[index][accountIndex] end,
}
BFL.GetBNetFriendInfo = function(index) return { bnetAccountID = index, gameAccountInfo = allAccounts[index][1] } end
BFL.IsBattleNetFriendsListEnabled = function() return true end
BFL.GetNumWoWFriends = function() return 2 end
BFL.GetWoWFriendInfoByIndex = function(index) return { connected = index == 1 } end
env.BNConnected = function() return true end
env.BNGetNumFriends = function() return #allAccounts end
local brokerSource = read("Modules/Broker.lua")
env.CreateFrame = function()
	return { SetSize = function() end, EnableMouse = function() end, SetFrameStrata = function() end, Hide = function() end }
end
local getCounts, isBrokerFriendOnline, getFilterAccounts = execute(between(brokerSource, "-- Modules/Broker.lua", "-- Broker Text Update") .. "\nreturn GetFilteredFriendCounts, IsPreviewFriendOnline, GetBNetFilterGameAccounts", "Broker fresh counts")
local wowOnline, wowTotal, bnetOnline, bnetTotal = getCounts()
V:AssertEqual(wowOnline, 1, "Broker includes local online Forever friends")
V:AssertEqual(wowTotal, 2, "Broker preserves unfiltered WoW totals")
V:AssertEqual(bnetOnline, 1, "Broker counts a secondary Forever login, not App/offline accounts")
V:AssertEqual(bnetTotal, 3, "Broker preserves unfiltered Battle.net totals")
local multi = { type = "bnet", connected = true, gameAccountInfo = focused, gameAccounts = allAccounts[1] }
V:Assert(env.FriendsList:PassesFilters(multi), "FriendsList agrees with the broker for multi-login presence")
V:Assert(not env.FriendsList:PassesFilters({ type = "bnet", connected = true, gameAccountInfo = allAccounts[3][1] }), "FriendsList rejects App-only presence")

-- The grouped tooltip must use the same evaluator for the new built-in.
local tooltipFilter = execute("return function(groupedFriends, sample)\nlocal settings = sample and sample.settings or BetterFriendlistDB\n"
	.. between(brokerSource, "\t\t-- Apply current filter (to online friends only)", "\t\t-- Apply current sort mode")
	.. "\nreturn groupedFriends\nend", "Broker grouped tooltip filter")
local grouped = tooltipFilter({ nogroup = { multi, { type = "bnet", connected = true, gameAccountInfo = focused } } })
V:AssertEqual(#grouped.nogroup, 1, "Broker tooltip rejects Retail-only and retains secondary Forever")
V:Assert(grouped.nogroup[1] == multi, "Filtering retains the original contact and preferred account")
local sampleGrouped = tooltipFilter({ nogroup = { multi, { type = "bnet", connected = true, gameAccountInfo = focused } } },
	{ settings = { quickFilter = "all" } })
V:AssertEqual(#sampleGrouped.nogroup, 2, "A settings sample can compare the All Friends filter")
V:AssertEqual(env.BetterFriendlistDB.quickFilter, "forever", "The sample filter leaves the live setting intact")

local mobile = { type = "bnet", connected = false, client = "BSAp",
	gameAccountInfo = { clientProgram = "BSAp", isOnline = true }, gameAccounts = { secondary } }
env.BetterFriendlistDB.treatMobileAsOffline = true
V:Assert(isBrokerFriendOnline(mobile, true), "The grouped tooltip retains active Forever behind a focused mobile app")
V:AssertEqual(#getFilterAccounts(1), 2, "Fresh account collection retains all logins without rewriting the focused account")
local oldCountAPI = env.C_BattleNet.GetFriendNumGameAccounts
env.C_BattleNet.GetFriendNumGameAccounts = function() error("temporarily unavailable") end
V:AssertEqual(getFilterAccounts(1), nil, "Failed enumeration uses the safe focused-account fallback")
env.C_BattleNet.GetFriendNumGameAccounts = function() return "unknown" end
V:AssertEqual(getFilterAccounts(1), nil, "Invalid enumeration counts do not trigger iteration")
env.C_BattleNet.GetFriendNumGameAccounts = nil
env.BNGetNumFriendGameAccounts = oldCountAPI
V:AssertEqual(#getFilterAccounts(1), 2, "Legacy count APIs remain usable with the compatibility wrapper")
env.C_BattleNet.GetFriendNumGameAccounts = oldCountAPI
env.BNGetNumFriendGameAccounts = nil

-- Retail/Classic do not treat local WoW friends as Forever; BNet can still match.
env.WOW_PROJECT_ID, env.WOW_PROJECT_CAMELOT, BFL.IsForever = 1, nil, false
registry:InvalidateCaches()
wowOnline, _, bnetOnline = getCounts()
V:AssertEqual(wowOnline, 0, "Retail local friends do not leak into Forever counts")
V:AssertEqual(bnetOnline, 1, "Retail can still filter Battle.net Forever friends")
env.WOW_PROJECT_ID = 2
registry:InvalidateCaches()
wowOnline, _, bnetOnline = getCounts()
V:AssertEqual(wowOnline, 0, "Classic local friends do not leak into Forever counts")
V:AssertEqual(bnetOnline, 1, "Classic can still filter Battle.net Forever friends")
env.BetterFriendlistDB.enableBetaFeatures = true
env.BetterFriendlistDB.quickFilterVisibility.forever = false
registry:InvalidateCaches()
V:AssertEqual(registry:NormalizeQuickFilterId("forever"), "all", "A hidden filter uses the standard selection fallback")
V:Assert(not isBrokerFriendOnline({ type = "wow", connected = false }, false), "A hidden Forever filter never marks offline fallback friends online")
-- Live Basic uses the same builder as its preview even with QTip installed.
local acquired, activated, anchored
local rows = {}
local tt = {
	ScrollFrame = { ClearAllPoints = function() end, SetPoint = function() end },
	Clear = function() end,
	GetScript = function() end,
	SetScript = function() end,
	SetFrameStrata = function() end,
	SetMaxHeight = function() end,
	SmartAnchorTo = function(_, anchor) anchored = anchor end,
	UpdateLayout = function() end,
	Show = function() end,
}
function tt:AddRow(...)
	local texts = { ... }
	rows[#rows + 1] = texts
	return { GetCell = function()
		return { SetTextColor = function() end, SetColSpan = function() end }
	end }
end
env.fixtureQTip = { AcquireTooltip = function(_, key, columns)
	acquired = { key, columns }
	return tt
end }
BFL.BrokerUtils.DismissActiveBrokerTooltip = function() end
BFL.BrokerUtils.SetActiveBrokerTooltip = function(active) activated = active end
local route = execute(
	between(brokerSource, "-- Modules/Broker.lua", "-- Broker Text Update")
	.. "\nLQT = fixtureQTip\nlocal SetupTooltipAutoHide = function() end\nlocal ApplyElvUISkin = function() end\n"
	.. between(brokerSource, "local function CreateBasicTooltip(gameTooltip, sample)", "-- Advanced Tooltip")
	.. between(brokerSource, "local RenderBasicQTipTooltip", "local function CreateLibQTipTooltip")
	.. between(brokerSource, "local function CreateLibQTipTooltip", "\n\tlocal settings = sample and sample.settings or BetterFriendlistDB")
	.. "\nreturn 'advanced'\nend\n"
	.. between(brokerSource, "function RenderBasicQTipTooltip(parent, sample)", "function Broker:RenderSettingsSample")
	.. "\nreturn CreateLibQTipTooltip", "Broker live Basic routing")
env.BetterFriendlistDB.brokerTooltipMode = "basic"
local anchor = {}
V:AssertEqual(route(anchor), tt, "Basic mode uses the live QTip instance")
V:AssertEqual(acquired[2], 2, "Basic QTip has only the summary columns")
V:AssertEqual(anchored, anchor, "the live Basic tooltip stays anchored to the Broker")
V:AssertEqual(activated, tt, "the live Basic tooltip joins the same active lifecycle")
V:Assert(#rows >= 5, "the Basic tooltip renders the summary, counts and filter")
env.BetterFriendlistDB.brokerTooltipMode = "advanced"
V:AssertEqual(route(anchor), "advanced", "Advanced retains the existing grouped-tooltip path")
io.write("[OK] Forever filter smoke: " .. assertions .. " assertions, including real menu, list, broker count and tooltip paths\n")
