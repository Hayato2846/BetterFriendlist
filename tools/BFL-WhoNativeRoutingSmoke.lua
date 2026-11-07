-- lua tools/BFL-WhoNativeRoutingSmoke.lua <repo> <Forever UI source>
-- Executes real Core/Who code with native Slash, ItemRef, WhoList and LFG
-- callbacks. This does not emulate the engine's secure execution or networking.
local repo, native = assert(arg[1]), assert(arg[2])
local function readFile(path)
	local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local source = readFile(repo .. "/tools/BFL-WhoOwnershipSmoke.lua")
local stop = assert(source:find('\nfor _, flavor in ipairs', 1, true))
local body = [=[
local s = fixture("forever", true)
local env = s.env
local function loadNative(path, text)
	return assert(load(text or readFile(native .. "/" .. path), "@native/" .. path, "t", env))()
end
env.format, env.tinsert = string.format, table.insert
env.WHO_FRAME_TOTAL_TEMPLATE, env.WHO_FRAME_SHOWN_TEMPLATE = "Total: %d", "Shown: %d"
env.ScrollBoxConstants = { RetainScrollPosition = 1 }
env.CreateDataProvider = function() return { Insert = function() end } end
env.SOUNDKIT = { IG_CHARACTER_INFO_TAB = 1 }; env.PlaySound = function() end
env.UpdateMicroButtons = function() end
env.C_LFGList = { GetPremadeGroupFinderStyle = function() return 1 end }
env.C_LFGInfo = { CanPlayerUsePremadeGroup = function() return true end }
env.C_AddOns = { IsAddOnLoaded = function() return true end }
env.Enum.PremadeGroupFinderStyle = { Disabled = 0, Vanilla = 1 }
env.Enum.GameRule = { IngameWhoListDisabled = 1 }
env.C_GameRules = { IsGameRuleActive = function() return false end }
env.LFGParentFrame = { shown = false, selectedTab = 1, UpdateTabs = function() end }
function env.LFGParentFrame:IsShown() return self.shown end
env.ShowUIPanel = function(frame)
	equal(frame, env.LFGParentFrame, "native LFG manages its own parent")
	s.nativeOpens = s.nativeOpens + 1; frame.shown = true
end
env.HideUIPanel = function(frame)
	equal(frame, env.LFGParentFrame, "native LFG closes only its own parent"); frame.shown = false
end
env.PanelTemplates_SetTab = function(frame, tab) frame.selectedTab = tab end
env.LFGListingFrame, env.LFGBrowseFrame = {}, {}
for _, frame in ipairs({ env.LFGListingFrame, env.LFGBrowseFrame }) do
	function frame:SetShown(value) self.shown = value end
	function frame:IsShown() return self.shown == true end
end
loadNative("Interface/AddOns/Blizzard_GroupFinder_VanillaStyle/Mainline/WhoList.lua")
env.LFGWhoListFrame = s.listener()
local whoFrame = env.LFGWhoListFrame
whoFrame.SetupScrollView, whoFrame.InitFilterMenu = function() end, function() end
whoFrame.WhoFrameTotals = { SetText = function() end }
whoFrame.ScrollBox = { SetDataProvider = function() end }
whoFrame.UpdateWhoList = env.LFGWhoListMixin.UpdateWhoList
local function nativeWidget(script, handler, methods)
	local widget = methods or {}
	widget.IsForbidden = function() return false end
	function widget:HookScript(name, callback)
		equal(name, script, "only the search action is hooked")
		check(not self.postHook, "native search widget is hooked once")
		self.postHook = callback
	end
	function widget:Run()
		handler(self)
		if self.postHook then self.postHook(self) end
	end
	return widget
end
whoFrame.EditBox = nativeWidget("OnEnterPressed", env.WhoFrameEditBoxMixin.OnEnterPressed, {
	GetText = function() return "native LFG query" end, ClearFocus = function() end,
})
whoFrame.WhoSearch = nativeWidget("OnClick", env.WhoSearchMixin.OnClick)
function whoFrame:SetShown(value)
	if self.shown == value then return end
	self.shown = value
	if value then env.LFGWhoListMixin.OnShow(self) else env.LFGWhoListMixin.OnHide(self) end
end
function whoFrame:IsShown() return self.shown == true end
env.LFGWhoListMixin.OnLoad(whoFrame)
env.LFGWhoListFilterUtil.ResetFilters()
local parent = readFile(native .. "/Interface/AddOns/Blizzard_GroupFinder_VanillaStyle/Blizzard_LFGVanilla_ParentFrame.lua")
loadNative("LFG parent callbacks", between(parent, "local LISTING_TAB_INDEX", "function LFGParentFrameMixin:OnLoad()")
	.. between(parent, "function LFGVanilla_ShowFrame(", "function LFGParentFrame_SearchActiveEntry()"))
local game = readFile(native .. "/Interface/AddOns/Blizzard_Game/Shared/Game.lua")
loadNative("Group Finder entry", between(game, "function ToggleGroupFinderFrame(", '\nEventRegistry:RegisterCallback'))
local friends = readFile(native .. "/Interface/AddOns/Blizzard_FriendsFrame/Camelot/FriendsFrame.lua")
loadNative("ShowWhoPanel", between(friends, "function ShowWhoPanel()", "function ToggleFriendsSubPanel("))
local slash = readFile(native .. "/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua")
env.SLASH_COMMAND_CATEGORY = { SOCIAL = 1 }
env.SlashCommandUtil = { CheckAddSlashCommand = function(key, _, callback) env.SlashCmdList[key] = callback end }
loadNative("native /who", between(slash, "SlashCommandUtil.CheckAddSlashCommand(SLASH_COMMAND.WHO,", "SlashCommandUtil.CheckAddSlashCommand(SLASH_COMMAND.CHANNEL,"))
local item = readFile(native .. "/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ItemRefHandlers.lua")
loadNative("Interface/AddOns/Blizzard_SharedXML/LinkUtil.lua")
local processLink = env.LinkUtil.ProcessLink
env.LinkUtil.ProcessLink = function(...)
	local result = processLink(...)
	for _, callback in ipairs(s.linkHooks) do callback(...) end
	return result
end
local chatlinkModified, chatWindow, popup = true, nil, nil
env.IsModifiedClick = function(key) return key == "CHATLINK" and chatlinkModified end
env.StaticPopup_Visible = function(name) if name == popup then return "AddFriend" end end
env.ChatFrameUtil = { GetActiveWindow = function() return chatWindow end, InsertLink = function() end, SendTell = function() end }
env.C_NameUtil = { ReplaceSurnameSeparatorWithLinkSeparator = function(name) return name end }
env.WHO_TAG_EXACT = 'x-'
env.string = setmetatable({ split = function(_, value) return value:match("^([^:]+):?(.*)$") end }, { __index = string })
loadNative("native player-link Who", item:sub(1, assert(item:find("LinkUtil.RegisterLinkHandler(LinkTypes.LevelUpToast,", 1, true)) - 1))
function s:emit()
	self.callbacks.WHO_LIST_UPDATE()
	if whoFrame.registered then env.LFGWhoListMixin.OnEvent(whoFrame, "WHO_LIST_UPDATE") end
end
-- Confirm the native result callback really opens the Group Finder in this fixture.
env.LFGWhoListMixin.OnEvent(whoFrame, "WHO_LIST_UPDATE")
check(s.nativeOpens > 0, "control reproduces native result auto-open")
s.nativeOpens, env.LFGParentFrame.shown, env.LFGParentFrame.selectedTab = 0, false, 1
s.callbacks.ADDON_LOADED("Blizzard_GroupFinder_VanillaStyle")
s.BFL:InstallFriendsFrameRedirects()
-- Do not hide the real addon UI chain behind the fixture's display spy.
-- This runs Core Apply -> production ShowBetterFriendsFrame -> XML OnShow.
env.BetterFriendlistDB = {}
s.BFL.HasModernScrollBox = true
env.ClearTopTabSearchState, env.ConfigureUIPanelAttributes = function() end, function() end
env.BetterFriendsFrame_UpdateRaidTabState = function() return false end
env.BetterFriendsFrame_ShowTab = function() end
env.EventRegistry = { RegisterCallback = function() end, UnregisterCallback = function() end }
local addonWho = { shown = false }
function addonWho:IsShown() return self.shown end
env.BetterFriendsFrame = { WhoFrame = addonWho, shown = false }
function env.BetterFriendsFrame:IsShown() return self.shown end
function env.BetterFriendsFrame:Show() self.shown = true; s.addonOpens = s.addonOpens + 1 end
env.BetterWhoFrame_Update = function() s.who:Update(true) end
local xml = readFile(repo .. "/BetterFriendlist.xml")
local xmlStart = assert(xml:find("-- CRITICAL: Set Who data routing FIRST", 1, true))
local xmlEnd = assert(xml:find("</OnShow>", xmlStart, true))
local onShow = assert(load("local self = ...\n" .. xml:sub(xmlStart, xmlEnd - 1), "@BetterFriendlist.xml Who OnShow", "t", env))
env.BetterFriendsFrame_ShowBottomTab = function(tab)
	env.BetterFriendsFrame.selectedTab = tab
	if tab == 2 and not addonWho.shown then addonWho.shown = true; onShow(addonWho) end
	if tab ~= 2 then addonWho.shown = false end
end
local main = readFile(repo .. "/BetterFriendlist.lua")
loadNative("addon ShowBetterFriendsFrame", between(main, "function ShowBetterFriendsFrame(tabIndex)", "-- Hide the friends frame"))
loadNative("Core addon display target", between(core, "function BFL:ApplyBetterFriendsFrameTarget(", "function BFL:ShowBetterFriendsFrameIgnoreList()"))
function s.BFL:ForceRefreshFriendsList() end
local nativeToggle = env.ToggleGroupFinderFrame
local function resultsStayInBFL(label)
	s:emit(); s:advance(0); s:advance(12); s:emit()
	equal(s.nativeOpens, 0, label .. " results/late results do not open native Who/LFG")
	check(not whoFrame.registered, label .. " cannot re-enable native Who auto-open")
end
env.C_FriendList.SendWho('c-"Rogue"')
resultsStayInBFL("background scan")
check(not env.BetterFriendsFrame.shown and not env.LFGParentFrame.shown, "background sends and results leave both windows closed")
env.ShowBetterFriendsFrame(1)
env.C_FriendList.SendWho('r-"Human"', env.Enum.SocialWhoOrigin.Social)
resultsStayInBFL("background scan with an origin")
equal(env.BetterFriendsFrame.selectedTab, 1, "background searches leave the visible Friends tab selected")
env.BetterFriendsFrame.shown = false

-- An Item origin can be supplied by any addon. An ordinary click or a link
-- being inserted into chat in the same frame must not adopt that send.
env.C_FriendList.SendWho("background item", env.Enum.SocialWhoOrigin.Item)
chatlinkModified = false
env.LinkUtil.ProcessLink("player:Ada-Lovelace", "", { button = "LeftButton" })
check(not env.BetterFriendsFrame.shown, "ordinary player-link clicks do not adopt a preceding background send")
env.C_FriendList.SendWho("background item", env.Enum.SocialWhoOrigin.Item)
chatlinkModified, chatWindow = true, {}
env.LinkUtil.ProcessLink("player:Ada-Lovelace", "", { button = "LeftButton" })
check(not env.BetterFriendsFrame.shown, "pasting a player link into chat does not open Who")
chatWindow, popup = nil, "ADD_FRIEND"
env.C_FriendList.SendWho("background item", env.Enum.SocialWhoOrigin.Item)
env.AddFriendEditBox = { SetText = function() end }
env.LinkUtil.ProcessLink("player:Ada-Lovelace", "", { button = "LeftButton" })
check(not env.BetterFriendsFrame.shown, "pasting a player name into a dialog does not open Who")
popup = nil
s.calls = {}

env.SlashCmdList.WHO("")
equal(#s.calls, 1, "actual native-slash replacement sends once")
check(env.BetterFriendsFrame.shown and addonWho.shown, "explicit /who opens BFL")
resultsStayInBFL("/who")
env.BetterFriendsFrame.shown, addonWho.shown = false, false
env.LinkUtil.ProcessLink("player:Ada-Lovelace", "", { button = "LeftButton" })
equal(s.calls[2][1], "x-Ada-Lovelace", "actual ItemRef callback retains its exact query")
equal(s.calls[2][2], env.Enum.SocialWhoOrigin.Item, "actual ItemRef retains hardware origin")
check(env.BetterFriendsFrame.shown and addonWho.shown, "explicit player-link Who opens BFL")
resultsStayInBFL("player-link/context Who")
env.BetterFriendsFrame.shown, addonWho.shown = false, false
local routingBefore = s.routingWrites or 0
whoFrame.EditBox:Run()
equal(#s.calls, 3, "native Who widget is observed without replay")
equal(s.calls[3].n, 3, "native structured request remains three arguments")
equal(s.routingWrites, routingBefore + 1, "hidden-to-shown BFL Who executes its existing XML routing once")
equal(s.routing, true, "the existing XML OnShow selects Who UI result routing")
resultsStayInBFL("native Who widget")
env.BetterFriendsFrame.shown, addonWho.shown = false, false
whoFrame.WhoSearch:Run()
equal(#s.calls, 4, "native Who search button sends exactly once")
check(env.BetterFriendsFrame.shown and addonWho.shown, "native Who search button opens BFL")
resultsStayInBFL("native Who search button")
local addonOpens = s.addonOpens
env.ToggleGroupFinderFrame()
check(env.LFGParentFrame.shown and env.LFGListingFrame.shown, "normal Group Finder entry still opens Listing")
env.LFGParentFrameTab2_OnClick()
check(env.LFGBrowseFrame.shown and not env.LFGListingFrame.shown, "normal LFG Browse transition remains native")
env.LFGParentFrameTab3_OnClick(); env.LFGParentFrameTab2_OnClick()
check(not whoFrame.registered, "native Who OnShow/OnHide does not re-register the isolated listener")
equal(s.addonOpens, addonOpens, "LFG entry and tab transitions do not open BFL Who")
equal(env.ToggleGroupFinderFrame, nativeToggle, "BFL never replaces the native LFG entry")
env.ToggleGroupFinderFrame()
check(not env.LFGParentFrame.shown, "normal LFG toggle still closes Group Finder")

-- The in-addon temporary-policy test must also run on a Forever host without
-- changing its persistent ownership or losing its already-isolated listeners.
local suite = readFile(repo .. "/Modules/TestSuite.lua")
local first = assert(suite:find('self:RegisterTest("data", "WhoResultListenerIsolation",', 1, true))
local last = assert(suite:find('self:RegisterTest("data", "Forever_WhoUsesLegacyAddonOwnedSearch",', first + 1, true))
local registered
local receiver = { RegisterTest = function(_, _, name, definition)
	assert(name == "WhoResultListenerIsolation"); registered = definition
end }
assert(load("local self = ...\n" .. suite:sub(first, last - 1), "@production in-addon Who listener test", "t", env))(receiver)
local originalPolicy, originalFrames, originalFrameSet = s.who.UsesPersistentNativeWhoIsolation,
	s.who.suspendedNativeWhoListFrames, s.who.suspendedNativeWhoListFrameSet
registered.action({ Assert = function(_, value, message) check(value, message) end,
	AssertEqual = function(_, actual, expected, message) equal(actual, expected, message) end })
equal(s.who.UsesPersistentNativeWhoIsolation, originalPolicy, "in-addon test restores the real Forever ownership policy")
equal(s.who.suspendedNativeWhoListFrames, originalFrames, "in-addon test preserves existing native listener records")
equal(s.who.suspendedNativeWhoListFrameSet, originalFrameSet, "in-addon test preserves existing native listener membership")
io.write(("Native Who routing smoke: %d checks passed\n"):format(assertions))
]=]
assert(load("local native, readFile = ...\n" .. source:sub(1, stop - 1) .. body, "@native Who routing production smoke", "t", _G))(native, readFile)
