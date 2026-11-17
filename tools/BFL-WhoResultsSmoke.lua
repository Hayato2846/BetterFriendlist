-- Lua 5.4: lua tools/BFL-WhoResultsSmoke.lua <repo>
-- Production Who rendering, Core slash routing and XML visibility callbacks.
-- Native APIs and widgets are mocked; networking and secure execution need live QA.
local repo = arg[1] or "."
local function readFile(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local value = file:read("*a")
	file:close()
	return value
end
-- Keep the harness fixed when comparing production code from another checkout.
local testDirectory = assert(arg[0]:match("^(.*[/\\])"), "run the test using its tools/ path")
local fixtureFile = assert(io.open(testDirectory .. "BFL-WhoOwnershipSmoke.lua", "rb"))
local source = fixtureFile:read("*a")
fixtureFile:close()
local stop = assert(source:find("\nfor _, flavor in ipairs", 1, true))
local body = [=[
local xml = readFile("BetterFriendlist.xml")
local scriptStart = assert(xml:find("BetterWhoFrame_OnLoad(self)", 1, true))
local scripts = xml:sub(scriptStart)
local onShow = assert(scripts:match("<OnShow>(.-)</OnShow>"))
local onHide = assert(scripts:match("<OnHide>(.-)</OnHide>"))
local function textWidget()
	return {
		SetText = function(self, value) self.text = value end,
		GetText = function(self) return self.text or "" end,
		Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end,
	}
end
local function renderFixture(flavor)
	local classic = flavor:match("^classic") ~= nil
	local s = fixture(classic and "classic" or flavor)
	local env, who = s.env, s.who
	s.BFL.HasModernScrollBox = not classic
	s.BFL.IsClassic, s.BFL.IsClassicEra = classic, flavor == "classic_era"
	env.format = string.format
	env.EventRegistry = { RegisterCallback = function() end, UnregisterCallback = function() end }
	local data, provider = {}, { rows = {} }
	function provider:GetSize() return #self.rows end
	function provider:Flush() self.rows = {} end
	function provider:Insert(row) self.rows[#self.rows + 1] = row end
	env.CreateDataProvider = function() return provider end
	env.CreateScrollBoxListLinearView = function()
		return { SetElementInitializer = function() end, SetElementExtentCalculator = function() end }
	end
	s.BFL.InitScrollBoxListWithScrollBar = function() end
	local frame = {
		shown = true, IsShown = function(self) return self.shown end,
		EditBox = textWidget(), ListInset = { Totals = textWidget() }, ScrollBar = {},
		ScrollBox = { ClearAllPoints = function() end, SetPoint = function() end,
			SetDataProvider = function() end },
	}
	local parent = { shown = true, WhoFrame = frame, IsShown = function(self) return self.shown end }
	function parent:HookScript(script, callback) self[script] = callback end
	env.BetterFriendsFrame = parent
	env.BetterWhoFrame_Update = function(force) who:Update(force) end
	env.C_FriendList.GetNumWhoResults = function() return #data, #data end
	env.C_FriendList.GetWhoInfo = function(index) return data[index] end
	-- Omit only widget construction/painting, retaining production data and sort logic.
	who.CreateSearchBuilder, who.UpdateResponsiveLayout = function() end, function() end
	who.CreateEmptyState = function(self) self.emptyStateText = textWidget() end
	who.SetLoadingSpinnerShown = function() end
	who.RenderClassicWhoButtons = function() end
	who.InitializeClassicWhoFrame = function(self, owner)
		self.classicWhoFrame, self.classicWhoDataList = owner, {}
		self:CreateEmptyState(owner)
	end
	who:OnLoad(frame)
	who:Initialize()
	local show = assert(load("local self = ...\n" .. onShow, "@WhoFrame XML OnShow", "t", env))
	local hide = assert(load("local self = ...\n" .. onHide, "@WhoFrame XML OnHide", "t", env))
	function s:setShown(shown)
		frame.shown = shown
		if shown then show(frame) else hide(frame) end
	end
	function s:setData(value) data = value end
	function s:rows() return classic and who.classicWhoDataList or provider.rows end
	function s:externalResults(value)
		env.C_FriendList.SetWhoToUi(true)
		env.C_FriendList.SendWho("external lookup", env.Enum.SocialWhoOrigin.Chat)
		data = value
		self:emit()
	end
	s.frame, s.parent = frame, parent
	return s
end
local function row(name, guild, level)
	return { fullName = name, fullGuildName = guild or "", level = level or 50,
		classStr = "Mage", raceStr = "Human", area = "Zone" }
end
local function installUIActions(s)
	local env, who = s.env, s.who
	local main = readFile("BetterFriendlist.lua")
	local wrappers = between(main, "function BetterWhoFrame_Update(forceRebuild)", "-- WHO Frame Invalidate Font Cache")
	assert(load("local GetWhoFrame = ...\n" .. wrappers, "@Who production UI delegates", "t", env))(
		function() return who end)
	local function clickScript(marker)
		for script in xml:gmatch("<OnClick[^>]*>(.-)</OnClick>") do
			if script:find(marker, 1, true) then
				return assert(load("local self = ...\n" .. script, "@Who XML click " .. marker, "t", env))
			end
		end
		error("missing XML click: " .. marker)
	end
	local refresh = clickScript("BetterWhoFrame_SendWhoRequest(text)")
	local headers = {}
	for _, column in ipairs({ "name", "level", "class" }) do
		headers[column] = clickScript('BetterWhoFrame_SortByColumn("' .. column .. '")')
	end
	env.wipe = function(value) for key in pairs(value) do value[key] = nil end end
	env.PlaySound, env.SOUNDKIT = function() end, { IG_MAINMENU_OPTION_CHECKBOX_ON = 1 }
	s.frame.EditBox.ClearFocus = function() end
	env.BetterFriendsFrame_ShowBottomTab = function(tab) s:setShown(tab == 2) end
	function s:clickHeader(column) headers[column]() end
	function s:submit(method, text)
		self.frame.EditBox:SetText(text)
		if method == "enter" then
			env.BetterFriendlistWhoFrameEditBoxMixin.OnEnterPressed(self.frame.EditBox)
		else
			refresh(self.frame.WhoButton)
		end
	end
end
local failures, cases = {}, 0
local function case(name, callback)
	cases = cases + 1
	local ok, message = pcall(callback)
	if not ok then failures[#failures + 1] = name .. ": " .. tostring(message) end
end
local waitTwoSeconds = "You must wait 2 seconds before using /who again."
local waitMoment = "You must wait a moment longer before using /who again."
case("Forever matches the client language and preserves the original text", function()
	local s = renderFixture("forever")
	installUIActions(s)
	-- Translations are fixtures. The client supplies the actual strings at runtime.
	s.env.WHO_COOLDOWN = "Ihr müsst %1$d Sekunden warten, bevor Ihr /who erneut benutzt."
	s.env.WHO_COOLDOWN_SHORT = "Ihr müsst noch einen Moment warten, bevor Ihr /who erneut benutzt."
	local status = s.frame.ListInset.Totals

	s:submit("refresh", "zone search")
	local wait = "Ihr müsst 2 Sekunden warten, bevor Ihr /who erneut benutzt."
	s.callbacks.CHAT_MSG_SYSTEM(wait:gsub("/who", "/say"))
	s.callbacks.CHAT_MSG_SYSTEM(wait:sub(1, -2) .. "!")
	s:advance(0)
	check(s.who.whoPending, "a different command or punctuation does not match the template")
	s.callbacks.CHAT_MSG_SYSTEM(wait)
	s:advance(8)
	equal(status:GetText(), wait, "the localized message with seconds is shown verbatim")
	equal(s.hints, 0, "no timeout follows the localized wait")

	s:submit("enter", "zone search")
	s.callbacks.CHAT_MSG_SYSTEM(s.env.WHO_COOLDOWN_SHORT)
	s:advance(0)
	equal(status:GetText(), s.env.WHO_COOLDOWN_SHORT, "the localized short template matches without formatting")

	s:advance(8)
	s.env.WHO_COOLDOWN = "[/who] Patientez %d secondes (commande 2)."
	s:submit("enter", "zone search")
	wait = "[/who] Patientez 12 secondes (commande 2)."
	s.callbacks.CHAT_MSG_SYSTEM(wait)
	s:advance(0)
	equal(status:GetText(), wait, "punctuation and other digits remain literal")
end)
for _, flavor in ipairs({ "retail", "forever", "classic", "classic_era", "classic_anniversary" }) do
	case(flavor .. " Blizzard Who wait hints", function()
		local s = renderFixture(flavor)
		installUIActions(s)
		local status = s.frame.ListInset.Totals
		s.synchronousSystemMessage = waitTwoSeconds
		s:submit("refresh", "zone search")
		local originalTimer = s.who.whoTimeoutTimer
		s.synchronousSystemMessage = nil
		s:advance(.31)
		equal(status:GetText(), waitTwoSeconds, "synchronous Blizzard hint survives the refresh callback")
		check(originalTimer.cancelled and not s.who.whoPending, "the wait hint ends the pending request")
		s:setShown(false); s:setShown(true)
		s:advance(8)
		equal(status:GetText(), waitTwoSeconds, "reopening or passing the deadline keeps the Blizzard hint")
		equal(s.hints, 0, "the cancelled timeout cannot replace the hint")
		check(not s.who.emptyStateText.shown, "a wait hint is distinct from zero results")

		s:submit("enter", "zone search")
		equal(status:GetText(), "Searching...", "the next attempt clears the previous wait hint")
		s:setShown(false)
		s.callbacks.CHAT_MSG_SYSTEM(waitMoment)
		s:advance(1); s:setShown(true)
		equal(status:GetText(), waitMoment, "a delayed wait hint survives a tab switch")
		s:setData({ row("Recovered") }); s:emit(); s:advance(0)
		equal(#s:rows(), 1, "a later real result replaces the status and rebuilds the list")
		check(status:GetText() ~= waitMoment, "the former wait is cleared from the footer")
	end)
	case(flavor .. " unrelated chat is not a Who response", function()
		local s = renderFixture(flavor)
		installUIActions(s)
		s.callbacks.CHAT_MSG_SYSTEM(waitTwoSeconds)
		check(not s.who.whoWaitMessage, "an idle Who tab ignores waits for other requests")
		s:submit("enter", "zone search")
		s.secret = setmetatable({}, { __index = function() error("secret payload must not be read") end })
		s.callbacks.CHAT_MSG_SYSTEM(s.secret)
		s.callbacks.CHAT_MSG_SYSTEM("Someone quoted: " .. waitTwoSeconds)
		s.callbacks.CHAT_MSG_SYSTEM("You must wait 2 seconds before using another command.")
		s:advance(8)
		equal(s.hints, 1, "the normal timeout applies when no Who reply or matching wait arrives")
		check(not s.who.whoWaitMessage, "unrelated and unreadable messages are never displayed")
	end)
	case(flavor .. " hidden equal-count results", function()
		local s = renderFixture(flavor)
		s:setData({ row("Old") }); s.who:Update(true)
		s:setShown(false); s:externalResults({ row("New") })
		s:setShown(true)
		equal(s:rows()[1].info.fullName, "New", "reopening only Who consumes the hidden result update")
		-- A later ordinary update must retain the new results.
		s.who:Update()
		equal(s:rows()[1].info.fullName, "New", "the refreshed cache remains current")
	end)
	case(flavor .. " parent reopened on Contacts", function()
		local s = renderFixture(flavor)
		s:setData({ row("Old") }); s.who:Update(true)
		s:setShown(false); s.parent.shown = false
		s:externalResults({ row("New") })
		s.parent.shown = true; s.parent:OnShow()
		s:setShown(true)
		equal(s:rows()[1].info.fullName, "New", "Contacts cannot consume Who's pending redraw")
	end)
	case(flavor .. " sorted empty external result", function()
		local s = renderFixture(flavor)
		s:setData({ row("Zulu"), row("Alpha") })
		s.who:SortByColumn("name", true)
		s:externalResults({})
		equal(#s:rows(), 0, "an empty result removes every old sorted row")
		check(s.who.emptyStateText.shown, "an empty result shows the empty-state message")
		s:externalResults({ row("Recovered") })
		equal(s:rows()[1].info.fullName, "Recovered", "results recover after the empty response")
	end)
	case(flavor .. " native guild field", function()
		local s = renderFixture(flavor)
		s:setData({ row("Alpha", "ZuluGuild"), row("Zulu", "AlphaGuild") })
		s.who:SortByColumn("guild")
		equal(s:rows()[1].info.fullGuildName, "AlphaGuild", "ascending sort uses Blizzard's fullGuildName")
		s.who:Update()
		equal(s:rows()[1].info.fullGuildName, "AlphaGuild", "ordinary updates preserve the selected sort")
		s.who:SortByColumn("guild")
		s:setShown(false); s:setShown(true)
		equal(s:rows()[1].info.fullGuildName, "ZuluGuild", "reopening preserves descending direction")
		s:externalResults({ row("Beta", "BetaGuild"), row("Gamma", "GammaGuild") })
		equal(s:rows()[1].info.fullGuildName, "GammaGuild", "new results retain descending sort")
	end)
	case(flavor .. " persistent name sort", function()
		local s = renderFixture(flavor)
		s:setData({ row("Zulu"), row("Alpha") })
		s.who:SortByColumn("name", true)
		equal(s:rows()[1].info.fullName, "Alpha", "the initial ascending name sort applies")
		s.who:Update()
		equal(s:rows()[1].info.fullName, "Alpha", "name sort survives an ordinary refresh")
		s.who:SortByColumn("name")
		s:setShown(false); s:setShown(true)
		equal(s:rows()[1].info.fullName, "Zulu", "descending name sort survives reopening")
		s:externalResults({ row("Beta"), row("Gamma") })
		equal(s:rows()[1].info.fullName, "Gamma", "new results preserve descending name sort")
	end)
	-- These cases enter through the shipped XML/mixin handlers, rather than
	-- fabricating an external request. They delimit what is a user-facing fix.
	for _, column in ipairs({ "name", "level", "class" }) do
		case(flavor .. " UI header persistence: " .. column, function()
			local s = renderFixture(flavor)
			installUIActions(s)
			local alpha, zulu = row("Alpha", "", 10), row("Zulu", "", 20)
			alpha.classStr, zulu.classStr = "Druid", "Warrior"
			s:setData({ alpha, zulu }); s.who:Update(true)
			s:clickHeader(column)
			if s.frame.sortAscending then s:clickHeader(column) end
			equal(s:rows()[1].info.fullName, "Zulu", "the real header selects descending order")
			s:setShown(false); s:setShown(true)
			equal(s:rows()[1].info.fullName, "Zulu", "the XML OnShow preserves the header sort")
			s:submit("enter", "new UI query")
			s:emit()
			equal(s:rows()[1].info.fullName, "Zulu", "an own-search result preserves the header sort")
		end)
	end
	for _, method in ipairs({ "enter", "refresh" }) do
		case(flavor .. " UI own query hidden equal count: " .. method, function()
			local s = renderFixture(flavor)
			installUIActions(s)
			s:setData({ row("Old") }); s.who:Update(true)
			s:submit(method, "New")
			equal(#s:rows(), 0, "the real search action already clears the old cache")
			-- Let the real Enter/Refresh callbacks finish while the response is pending.
			s:advance(0.31); s:setShown(false)
			s:setData({ row("New") }); s:emit(); s:setShown(true)
			equal(s:rows()[1].info.fullName, "New", "own hidden results rebuild even without the defensive fix")
		end)
		case(flavor .. " UI own sorted empty result: " .. method, function()
			local s = renderFixture(flavor)
			installUIActions(s)
			s:setData({ row("Zulu"), row("Alpha") }); s.who:Update(true)
			s:clickHeader("name")
			s:submit(method, "no matching character")
			equal(#s:rows(), 0, "the real search action clears old sorted rows before dispatch")
			s:setData({}); s:emit()
			equal(#s:rows(), 0, "an own empty result cannot retain those cleared rows")
		end)
	end
end
case("Forever external send cannot satisfy BFL's pending request with its wait hint", function()
	local s = renderFixture("forever")
	installUIActions(s)
	s:submit("enter", "zone search")
	s.synchronousSystemMessage = waitMoment
	s.env.C_FriendList.SendWho("external query", s.env.Enum.SocialWhoOrigin.Chat)
	s:advance(1)
	check(s.who.whoPending and not s.who.whoWaitMessage, "the native post-hook prevents misattribution before the deferred callback")
	s:advance(7)
	equal(s.hints, 1, "the genuine BFL timeout remains after an external warning")
end)
case("Forever wait received before the deadline wins over the queued timeout", function()
	local s = renderFixture("forever")
	installUIActions(s)
	s:submit("enter", "zone search")
	local timer = s.who.whoTimeoutTimer
	s.callbacks.CHAT_MSG_SYSTEM(waitMoment)
	timer.callback()
	s:advance(8)
	equal(s.frame.ListInset.Totals:GetText(), waitMoment, "the accepted wait bypasses the no-response notice")
	equal(s.hints, 0, "a queued timeout sees an already received wait")
end)
for _, flavor in ipairs({ "retail", "forever" }) do
	case(flavor .. " slash cooldown", function()
		local s = renderFixture(flavor)
		s.BFL:InstallFriendsFrameRedirects()
		check(s.env.SlashCmdList.WHO("Alpha"), "the first slash query submits")
		s:advance(1)
		check(not s.env.SlashCmdList.WHO("Beta"), "a query during cooldown is rejected")
		equal(#s.calls, 1, "cooldown never sends a second request")
		equal(s.frame.EditBox:GetText(), "Alpha", "rejected slash input cannot replace the submitted query")
		s:advance(4)
		equal(#s.calls, 1, "a timer cannot dispatch a protected request")
		check(s.env.SlashCmdList.WHO("Beta"), "a new hardware action after cooldown submits")
		equal(s.frame.EditBox:GetText(), "Beta", "accepted input replaces the displayed query")
		equal(s.calls[2][1], "Beta", "the submitted and displayed queries match")
		s.BFL.AllowBlizzardFriendsFrame = true
		s.env.SlashCmdList.WHO("Native")
		equal(s.calls[3][1], "Native", "the explicit Blizzard bypass keeps its native handler")
	end)
end
for _, message in ipairs(failures) do io.stderr:write("FAIL: " .. message .. "\n") end
assert(#failures == 0, ("Who results smoke: %d/%d cases failed"):format(#failures, cases))
io.write(("Who results smoke: %d cases, %d checks passed (production Lua/XML; mocked client)\n"):format(cases, assertions))
]=]
assert(load("local readFile = ...\n" .. source:sub(1, stop - 1) .. body,
	"@Who results production smoke", "t", _G))(readFile)
