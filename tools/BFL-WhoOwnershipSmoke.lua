-- Lua 5.4: lua tools/BFL-WhoOwnershipSmoke.lua <repo> [Forever UI source]
-- Runs the production Who module and Core entrypoint installers. Native
-- fixtures follow Gethe forever 1.60.1.70790 Camelot/FriendsFrame.lua,
-- GroupFinder_VanillaStyle/Mainline/WhoList.lua and Shared/SlashCommands.lua.
-- Mocks verify routing/ownership; protected execution and taint need live QA.
local repo = arg[1] or "."
local nativeRoot = arg[2]
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
local core, module = read("Core.lua"), read("Modules/WhoFrame.lua")
local function fixture(flavor, lateNative)
	local state = { now = 100, calls = {}, timers = {}, callbacks = {}, nativeOpens = 0, addonOpens = 0, hints = 0, hooks = {}, linkHooks = {} }
	local BFL = { modules = {}, L = {}, IsMainline = flavor ~= "classic", IsForever = flavor == "forever", HasSecretValues = flavor ~= "classic" }
	function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
	function BFL:GetModule(name) return self.modules[name] end
	function BFL:RegisterEventCallback(event, callback) state.callbacks[event] = callback end
	function BFL:IsGameRuleActive() return state.disabled == true end
	function BFL:IsFriendsTabAllowed() return not state.disabled end
	function BFL:HandleFriendsFrameRedirect() state.addonOpens = state.addonOpens + 1; return true end
	function BFL:ApplyBetterFriendsFrameTarget(tab)
		equal(tab, 2, "Who opens only the addon Who tab")
		state.addonOpens = state.addonOpens + 1
	end
	function BFL:IsSecret(value) return rawequal(value, state.secret) end
	BFL.IsSocialActionRestricted = function() return state.restricted == true end
	local function timer(delay, callback)
		local value = { at = state.now + delay, callback = callback }
		function value:Cancel() self.cancelled = true end
		state.timers[#state.timers + 1] = value; return value
	end
	function state:advance(seconds)
		local target = self.now + seconds
		while true do
			local selected
			for _, value in ipairs(self.timers) do
				if not value.cancelled and not value.fired and value.at <= target
					and (not selected or value.at < selected.at) then selected = value end
			end
			if not selected then break end
			self.now = selected.at; selected.fired = true; selected.callback()
		end
		self.now = target
	end
	local function listener()
		local frame = { registered = true }
		function frame:IsEventRegistered(event) equal(event, "WHO_LIST_UPDATE", "only Who registration is inspected"); return self.registered end
		function frame:RegisterEvent(event) equal(event, "WHO_LIST_UPDATE", "only Who is restored"); self.registered = true end
		function frame:UnregisterEvent(event) equal(event, "WHO_LIST_UPDATE", "only Who is suspended"); self.registered = false end
		function frame:HookScript() end
		function frame:IsShown() return false end
		function frame:IsForbidden() return self.forbidden == true end
		function frame:HasAnyForbiddenAspects(aspect)
			equal(aspect, 16, "event access checks only the EventRegistrations aspect")
			if self.aspectError then error("aspect access denied") end
			return self.forbiddenEvents or false
		end
		for _, name in ipairs({ "Hide", "Show", "SetScript", "SetAttribute" }) do
			frame[name] = function() error("addon mutated native frame: " .. name) end
		end
		return frame
	end
	state.listener = listener
	local env = setmetatable({ BFL = BFL, LOCALIZED_CLASS_NAMES_MALE = {}, LOCALIZED_CLASS_NAMES_FEMALE = {},
		GetTime = function() return state.now end,
		C_Timer = { NewTimer = timer, After = timer },
		Enum = { SocialWhoOrigin = { Social = 1, Chat = 2, Item = 3 }, ForbiddenAspect = { EventRegistrations = 16 } },
		SLASH_COMMAND = { WHO = "WHO" }, SlashCmdList = {},
		C_SocialUI = { IsSystemEnabled = function() return state.socialUI == true end },
		FriendsFrame = listener(),
		Kiosk = { IsEnabled = function() return false end },
		InCombatLockdown = function() return state.restricted == true end,
		RunNextFrame = function(callback) timer(0, callback) end,
		NormalizeFriendsFrameTab = function(tab) return tab or 1 end,
		NormalizeFriendsSubPanel = function(tab) return tab end,
		WhoFrameEditBoxMixin = {}, WhoFrameColumnDropdownMixin = {},
		LinkUtil = { ProcessLink = function() end },
	}, { __index = _G })
	env._G = env
	state.env, state.BFL = env, BFL
	env.C_FriendList = {
		GetNumWhoResults = function() return 0, 0 end, GetWhoInfo = function() end,
		SetWhoToUi = function(value)
			if state.routeError then error("routing rejected") end
			state.routing = value; state.routingWrites = (state.routingWrites or 0) + 1
		end,
	}
	-- Preserve the native function identity: secure hooks execute after its body.
	env.C_FriendList.SendWho = function(...)
		if state.sendError then error("send rejected") end
		state.calls[#state.calls + 1] = table.pack(...)
		if state.synchronousResult then state:emit() end
		for _, callback in ipairs(state.hooks) do callback(...) end
	end
	env.hooksecurefunc = function(owner, key, callback)
		if owner == env.LinkUtil then
			equal(key, "ProcessLink", "only the explicit link dispatcher is observed")
			state.linkHooks[#state.linkHooks + 1] = callback
		else
			equal(owner, env.C_FriendList, "the native request API is observed")
			equal(key, "SendWho", "no native visibility function is hooked")
			state.hooks[#state.hooks + 1] = callback
		end
	end
	local nativeSend, nativeMixin = env.C_FriendList.SendWho, env.WhoFrameEditBoxMixin
	local who = assert(load(module, "@Modules/WhoFrame.lua", "t", env))("BetterFriendlist", BFL)
	state.who = who
	equal(env.C_FriendList.SendWho, nativeSend, "module loading never replaces native SendWho")
	equal(env.WhoFrameEditBoxMixin, nativeMixin, "module loading preserves the native Who mixin")
	-- Only addon widgets are omitted; all request, event, timer and observer logic is production.
	who.SetSelectedButton = function() end
	who.ShowThrottleHint = function() state.hints = state.hints + 1 end
	if not lateNative then env.LFGWhoListFrame = listener() end
	who:Initialize()
	equal(env.C_FriendList.SendWho, nativeSend, "observer leaves native SendWho unchanged")
	who:InstallNativeWhoRequestObserver()
	equal(#state.hooks, 1, "observer installation is idempotent")
	equal(#state.linkHooks, flavor == "forever" and 1 or 0, "only Forever observes the link dispatcher")
	function state:emit()
		self.callbacks.WHO_LIST_UPDATE()
		if self.env.LFGWhoListFrame and self.env.LFGWhoListFrame.registered then self.nativeOpens = self.nativeOpens + 1 end
	end
	-- Native Forever ShowWhoPanel targets LFGParentFrame tab 3. Its slash handler
	-- calls ShowWhoPanel only for an empty query and otherwise sends directly.
	env.ShowWhoPanel = function() state.nativeOpens = state.nativeOpens + 1; state.nativeTab = 3 end
	env.WhoFrame_GetDefaultWhoCommand = function() return "default zone" end
	env.WhoFrameEditBox = { SetText = function(_, value) state.nativeQuery = value end }
	env.SlashCmdList.WHO = function(message)
		if state.disabled then return end
		if message == "" then message = env.WhoFrame_GetDefaultWhoCommand(); env.ShowWhoPanel() end
		env.WhoFrameEditBox:SetText(message)
		env.C_FriendList.SendWho(message, env.Enum.SocialWhoOrigin.Chat)
	end
	env.ToggleFriendsFrame = function() end
	local function execute(source)
		return assert(load(source, "@Core.lua Who entrypoints", "t", env))("BetterFriendlist", BFL)
	end
	execute(between(core, "function BFL.ResolveNativeWhoInterception(", "function BFL:IsFriendsTabAllowed("))
	execute(between(core, "local function StoreOriginalFriendsFrameFunction(", "function BFL:GetBetterFriendsFrameBottomTab()")
		.. between(core, "function BFL:InstallWhoSlashRedirect()", "-- Update Portrait Visibility"))
	state.nativePanel, state.nativeSlash = env.ShowWhoPanel, env.SlashCmdList.WHO
	return state
end

for _, flavor in ipairs({ "forever", "retail", "classic" }) do
	local s = fixture(flavor)
	s.BFL:InstallFriendsFrameRedirects()
	check(s.env.ShowWhoPanel ~= s.nativePanel, flavor .. " routes ShowWhoPanel to BFL")
	equal(s.env.SlashCmdList.WHO == s.nativeSlash, flavor == "classic", flavor .. " slash installation policy")
	s.env.ShowWhoPanel()
	equal(s.addonOpens, 1, flavor .. " opens BFL Who")
	equal(s.nativeOpens, 0, flavor .. " does not open native Who")
end

for _, origin in ipairs({ "own", "slash-empty", "slash-text", "background", "background-chat", "background-item", "background-social", "background-secret" }) do
	local s = fixture("forever")
	s.BFL:InstallFriendsFrameRedirects()
	local opaque = setmetatable({}, { __index = function() error("secret indexed") end, __tostring = function() error("secret formatted") end })
	s.secret = opaque
	if origin == "own" then
		check(s.who:SendWhoRequest("owned", 1), "BFL query submits")
	elseif origin == "slash-empty" then
		s.env.SlashCmdList.WHO("")
		equal(s.calls[1][1], "default zone", "empty /who retains native default syntax")
	elseif origin == "slash-text" then
		s.env.SlashCmdList.WHO('n-"Ada"')
		equal(s.calls[1][1], 'n-"Ada"', "/who keeps the exact user query")
	elseif origin == "background-chat" then
		s.nativeSlash("native query")
	elseif origin == "background-item" then
		s.env.C_FriendList.SendWho(opaque, s.env.Enum.SocialWhoOrigin.Item, opaque)
		equal(s.calls[1][1], opaque, "observer never reads native query values")
		equal(s.calls[1][3], opaque, "observer preserves native structured arguments")
	elseif origin == "background-social" then
		s.env.C_FriendList.SendWho("background query with origin", s.env.Enum.SocialWhoOrigin.Social)
	elseif origin == "background-secret" then
		s.env.C_FriendList.SendWho("background query with secret origin", opaque)
	else
		s.env.C_FriendList.SendWho("background query")
	end
	equal(#s.calls, 1, origin .. " sends exactly once")
	equal(s.routingWrites or 0, (origin == "own" or origin == "slash-empty" or origin == "slash-text") and 1 or 0,
		origin .. " standalone observer adds no routing call (real XML chain is tested separately)")
	local userSlash = origin == "slash-empty" or origin == "slash-text"
	equal(s.addonOpens, userSlash and 1 or 0, origin .. " only opens BFL from the installed slash command")
	if origin:match("^background") then
		check(not s.who.lastWhoSendTime, origin .. " does not start the BFL cooldown")
	end
	equal(s.who.whoPending == true, origin == "own" or origin == "slash-empty" or origin == "slash-text", origin .. " tracks only requests BFL actually dispatches")
	check(not s.env.LFGWhoListFrame.registered, origin .. " isolates native auto-open")
	s:emit(); s:advance(0)
	equal(s.nativeOpens, 0, origin .. " results never open native Who/LFG")
	check(not s.env.LFGWhoListFrame.registered, origin .. " completion cannot expose native auto-open")
	s:advance(20); s:emit()
	equal(s.nativeOpens, 0, origin .. " duplicate/late results stay isolated")
	equal(s.addonOpens, userSlash and 1 or 0, origin .. " duplicate/late results do not open BFL")
end

local s = fixture("forever")
s.who:SendWhoRequest("owned timeout", 1)
s:advance(9)
equal(s.hints, 1, "query times out once")
check(not s.env.LFGWhoListFrame.registered and not s.who.whoPending, "timeout retains persistent isolation")
s:emit(); s:advance(0)
equal(s.nativeOpens, 0, "late result after timeout cannot open native Who/LFG")
local opens = s.addonOpens
s:emit(); equal(s.addonOpens, opens, "passive duplicate results do not reopen BFL")

s = fixture("forever", true)
s.env.LFGWhoListFrame = s.listener()
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
check(not s.env.LFGWhoListFrame.registered, "late load isolates Who without a pending query")
s.env.C_FriendList.SendWho("native after late load", 1)
s:emit(); equal(s.nativeOpens, 0, "late-loaded results stay in BFL")
s.callbacks.ADDONS_UNLOADING()
check(s.env.LFGWhoListFrame.registered and s.env.FriendsFrame.registered, "unload restores original registrations")

for _, flavor in ipairs({ "forever", "retail" }) do
	s = fixture(flavor)
	s.who:SendWhoRequest("first", 1)
	local oldTimeout = s.who.whoTimeoutTimer
	s:emit(); s.now = s.now + 6
	s.who:SendWhoRequest("second", 1)
	local newTimeout, guard = s.who.whoTimeoutTimer, s.who.nativeWhoRequestGuard
	s:advance(0); oldTimeout.callback()
	equal(s.who.nativeWhoRequestGuard, guard, flavor .. " stale completion preserves current ownership")
	equal(s.who.whoTimeoutTimer, newTimeout, flavor .. " old timer cannot discard current timer")
	check(s.who.whoPending and not s.env.LFGWhoListFrame.registered, flavor .. " old callbacks cannot release current lock")
	s:advance(8)
	equal(s.env.LFGWhoListFrame.registered, flavor ~= "forever", flavor .. " timeout listener policy")
end

for _, failure in ipairs({ "sendError", "routeError", "falseReturn" }) do
	s = fixture("forever")
	local dispatch = s.who.DispatchWhoRequest
	if failure == "falseReturn" then s.who.DispatchWhoRequest = function() return false end else s[failure] = true end
	local ok, result = pcall(s.who.SendWhoRequest, s.who, "owned", 1)
	equal(ok, failure == "falseReturn", failure .. " preserves failure contract")
	if ok then equal(result, false, "false dispatch remains false") end
	check(not s.who.nativeWhoSendInProgress and not s.who.nativeWhoRequestGuard, failure .. " clears its dispatch marker")
	check(not s.env.LFGWhoListFrame.registered and not s.who.whoPending, failure .. " keeps late native results isolated")
	s.sendError, s.routeError = nil, nil
	s.who.DispatchWhoRequest = dispatch
	s.env.C_FriendList.SendWho("native after failure", 1)
	equal(#s.calls, 1, failure .. " next native request sends once")
	equal(s.addonOpens, 0, failure .. " an unrelated native request cannot open BFL")
	s:advance(6)
	s.BFL:InstallFriendsFrameRedirects()
	check(s.env.SlashCmdList.WHO("user after failure"), failure .. " the next explicit BFL query still submits")
	equal(s.addonOpens, 1, failure .. " the next explicit BFL query opens Who")
end

s = fixture("forever")
s.synchronousResult = true
s.env.C_FriendList.SendWho("synchronous event", 3)
equal(s.nativeOpens, 0, "persistent isolation covers an event inside native SendWho")
equal(s.addonOpens, 0, "a synchronous background result does not open BFL")
s:advance(0)
check(not s.env.LFGWhoListFrame.registered, "synchronous completion cannot restore native auto-open")
check(not s.who.whoPending and not s.who.whoTimeoutTimer, "post-hook cannot turn an already delivered result into pending work")
s:advance(9); equal(s.hints, 0, "synchronous native results cannot produce a false timeout")

s = fixture("forever", true)
local frame = s.listener(); s.env.LFGWhoListFrame = frame
frame.forbiddenEvents = true
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
check(frame.registered, "forbidden EventRegistrations are not modified")
frame.forbiddenEvents, frame.forbidden = false, true
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
check(frame.registered, "fully forbidden frames are not modified")
frame.forbidden, frame.aspectError = false, true
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
check(frame.registered, "aspect errors cannot trigger fallback mutation")
frame.aspectError = false
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
check(not frame.registered, "later permitted access can isolate Who")
frame.forbiddenEvents = true
s.who:RestoreNativeWhoListUpdates()
check(not frame.registered and s.who.suspendedNativeWhoListFrameSet[frame], "denied restore retains original registration")
frame.forbiddenEvents = false
s.who:RestoreNativeWhoListUpdates()
check(frame.registered, "restore recovers after aspect restriction lifts")

s = fixture("forever")
s.restricted = true
equal(s.who:SendWhoRequest("owned", 1), false, "restricted BFL query is rejected")
equal(#s.calls, 0, "restricted BFL request cannot reach native API")
s.env.C_FriendList.SendWho("native secure request", 3)
equal(#s.calls, 1, "observer never replays/restricts native successful sends")
equal(s.routingWrites or 0, 0, "standalone observer adds no routing call")
s.BFL:InstallFriendsFrameRedirects()
s.BFL.OriginalOpenFriendsFrame = function() end
s.BFL.ShowBlizzardFriendsFrame()
s.env.C_FriendList.SendWho("explicit native bypass", 1)
check(s.env.LFGWhoListFrame.registered, "explicit native bypass restores original registrations")
local bypassOpens = s.addonOpens
s.env.C_FriendList.SendWho("native bypass again", 1)
equal(s.addonOpens, bypassOpens, "native bypass never opens BFL")
s:advance(0.1)
check(not s.env.LFGWhoListFrame.registered, "ending the native bypass isolates even a synchronous background result")
s:emit()
equal(s.nativeOpens, 0, "background results after the bypass do not open native LFG")
io.write(("Who ownership smoke: %d checks passed\n"):format(assertions))
