-- Lua 5.4: lua tools/BFL-ForeverSocialActionsSmoke.lua <repo> <Forever UI source> <Classic UI source>
-- Exercises production copy/remove menus and native Add Friend delegation.
-- Mocks cannot verify Blizzard's secure execution or a live server lookup.
local repo = assert(arg[1], "repository root is required")
local forever = assert(arg[2], "Forever UI source root is required")
local classic = assert(arg[3], "Classic UI source root is required")
local function read(root, path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local content = file:read("*a")
	file:close()
	return content
end
local function between(source, first, last)
	local start = assert(source:find(first, 1, true), "missing anchor: " .. first)
	local finish = assert(source:find(last, start + #first, true), "missing anchor: " .. last)
	return source:sub(start, finish - 1)
end
local BFL = { L = {}, modules = {}, IsRetail = true }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale() end
local secret = setmetatable({}, { __tostring = function() error("secret inspected") end })
function BFL:IsSecret(value) return rawequal(value, secret) end
local env = setmetatable({ BFL = BFL, L = BFL.L, BFL_LOCALE_ENUS = BFL.L, SlashCmdList = {},
	StaticPopupDialogs = {}, FULL_PLAYER_NAME = "%s-%s", SEND_REQUEST = "Send Request", CANCEL = "Cancel",
	CLOSE = "Close", ACCEPT = "Accept", COPY_CHARACTER_NAME = "Copy Character Name",
	REMOVE_TITLE_FRIEND_CONFIRMATION = "WoW friend: %s", BATTLETAG_REMOVE_FRIEND_CONFIRMATION = "BattleTag friend: %s",
	REMOVE_FRIEND_CONFIRMATION = "Real ID friend: %s", ERR_SYSTEM_DISABLED = "Disabled", BATTLENET_UNAVAILABLE = "Disconnected",
	Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = "-" } },
	Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 } },
}, { __index = _G })
local function execute(content, label)
	return assert(load(content, "@" .. label, "t", env))("BetterFriendlist", BFL)
end
execute(read(repo, "Locales/enUS.lua"), "Locales/enUS.lua")
execute(read(repo, "Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
execute(read(repo, "Modules/Dialogs.lua"), "Modules/Dialogs.lua")
execute(read(forever, "Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua"), "Blizzard Camelot NameUtil")
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local regional, connected, titleEnabled, realIDEnabled = true, true, true, true
env.RegionalUniqueNamesEnabled = function() return regional end
env.BNFeaturesEnabledAndConnected = function() return connected end
env.BNGetInfo = function() return nil, "MyTag#1234", nil, nil, nil, nil, true end
env.C_AddOns = { IsAddOnLoaded = function() return true end }
local sentTitles, sentAccounts, addedLegacy, errors = {}, {}, {}, {}
env.C_BattleNet = {
	AreTitleFriendsEnabled = function() return titleEnabled end,
	AreRealIDFriendsEnabled = function() return realIDEnabled end,
	GetFriendLevelFromInviteText = function(text)
		return text:find("@", 1, true) and env.Enum.BattleNetFriendLevel.RealID or env.Enum.BattleNetFriendLevel.Title
	end,
	SendTitleFriendInviteByName = function(name) sentTitles[#sentTitles + 1] = name end,
}
env.BNSendFriendInvite = function(name) sentAccounts[#sentAccounts + 1] = name end
env.C_FriendList = { IsLegacyFriendSystemEnabled = function() return not titleEnabled end,
	AddFriend = function(name) addedLegacy[#addedLegacy + 1] = name end }
env.UIErrorsFrame = { AddExternalErrorMessage = function(_, message) errors[#errors + 1] = message end }

equal(BFL.GetCopyCharacterName("Ada-Lovelace", "Realm"), "Ada-Lovelace", "Forever copy omits the realm")
equal(BFL.GetCopyCharacterName("Ada", "Realm", "Lovelace"), "Ada-Lovelace", "Separate context surnames are kept")
equal(BFL.GetCopyCharacterName(secret, "Realm"), nil, "Secret copy names are rejected")
local originalNameUtil = env.NameUtil
env.NameUtil = nil
equal(BFL.GetCopyCharacterName("Ada", "Realm", "Lovelace"), "Ada-Lovelace", "Copy fallback does not drop the surname")
env.NameUtil = originalNameUtil
regional = false
equal(BFL.GetCopyCharacterName("Ada", "Realm"), "Ada-Realm", "Retail/Classic copy keeps realm information")
equal(BFL.GetCopyCharacterName("Ada-Realm", "Realm"), "Ada-Realm", "A full traditional name is not duplicated")
equal(BFL.GetCopyCharacterName("Ada", nil), "Ada", "Missing realms have no dangling separator")
regional = true

equal(BFL.GetBNetRemoveFriendPrompt({ friendLevel = 3, isBattleTagFriend = false }, "Alias"), "WoW friend: Alias", "Title wording overrides legacy flags")
equal(BFL.GetBNetRemoveFriendPrompt({ friendLevel = 1 }, "Alias"), "BattleTag friend: Alias", "BattleTag wording follows the friend level")
equal(BFL.GetBNetRemoveFriendPrompt({ friendLevel = 2 }, "Alias"), "Real ID friend: Alias", "Real ID wording is kept for actual Real ID friends")
equal(BFL.GetBNetRemoveFriendPrompt({}, "Alias"), "Remove Alias from your friends list?", "Unknown type uses neutral localized wording")
equal(BFL.GetBNetRemoveFriendPrompt({ isBattleTagFriend = false }, "Alias"), "Remove Alias from your friends list?", "Incomplete modern metadata does not guess Real ID")
equal(BFL.GetBNetRemoveFriendPrompt({ friendLevel = secret }, "Alias"), "Remove Alias from your friends list?", "Secret levels use neutral wording")
equal(BFL.GetBNetRemoveFriendPrompt(nil, secret), nil, "Secret display names are rejected")
local modernEnum = env.Enum
env.Enum = nil
equal(BFL.GetBNetRemoveFriendPrompt({ isBattleTagFriend = true }, "Alias"), "BattleTag friend: Alias", "Legacy BattleTag metadata remains supported")
equal(BFL.GetBNetRemoveFriendPrompt({ isBattleTagFriend = false }, "Alias"), "Real ID friend: Alias", "Legacy Real ID metadata remains supported")
env.Enum = modernEnum

-- Run Blizzard's actual opening, initialization, text and accept handlers.
-- Only widgets and C APIs are mocked; server lookup remains an in-game test.
execute(read(forever, "Interface/AddOns/Blizzard_AddFriend/AddFriendTemplates.lua"), "Blizzard Add Friend")
local function widget()
	local value = { visible = false }
	function value:SetText(text) self.text = text end
	function value:GetText() return self.text or "" end
	function value:SetAlpha() end
	function value:SetVertexColor() end
	function value:SetTextColor() end
	function value:Show() self.visible = true end
	function value:Hide() self.visible = false end
	function value:SetFocus() self.focused = true end
	function value:Enable() self.enabled = true end
	function value:Disable() self.enabled = false end
	function value:IsEnabled() return self.enabled end
	function value:SetEnabled(enabled) self.enabled = enabled end
	function value:SetShown(shown) self.visible = shown end
	return value
end
local function option()
	return { Title = widget(), Description = widget(), IconHolder = { SecondaryIcon = widget(), FriendIcon = widget() } }
end
env.AddFriendFrame = setmetatable(widget(), { __index = env.AddFriendFrameMixin })
function env.AddFriendFrame:Layout() end
env.AddFriendEntryFrame = widget()
env.AddFriendEntryFrame.OptionsContainer = { LeftTextContainer = option(), RightTextContainer = option(), OrLabel = widget() }
env.AddFriendInfoFrame = widget()
env.AddFriendInfoFrame.InfoContainer = { LeftTextContainer = option(), RightTextContainer = option() }
env.AddFriendFrame.InfoFrame = env.AddFriendInfoFrame
env.AddFriendFrame.EntryFrame = { EditBoxContainer = { ErrorMessage = widget() } }
env.AddFriendNameEditBox, env.AddFriendNameEditBoxFill, env.AddFriendEntryFrameAcceptButton = widget(), widget(), widget()
function env.AddFriendNameEditBox:SetText(text)
	self.text = text
	env.AddFriendNameEditBox_OnTextChanged(self, false)
end
env.AutoCompleteEditBox_OnTextChanged = function() return false end
env.AutoCompleteEditBox_OnEnterPressed = function() return false end
env.C_Glue, env.InGlue = { IsOnGlueScreen = function() return false end }, function() return false end
local targetName, infoShown = nil, true
env.GetUnitName = function() return targetName end
env.UnitIsHumanPlayer, env.UnitIsPlayer = function() return targetName ~= nil end, function() return targetName ~= nil end
env.UnitCanCooperate = function() return true end
env.C_FriendList.GetFriendInfo = function() end
env.GetCVarBool = function() return infoShown end
env.SOUNDKIT, env.PlaySound = { U_CHAT_SCROLL_BUTTON = 1, IG_MAINMENU_OPEN = 2 }, function() end
local nativeOpens, shownPopup, popupArgs = 0, nil, nil
local dialog = { EditBox = widget() }
env.StaticPopup_Show = function(id, ...) shownPopup, popupArgs = id, { ... }; return dialog end
env.StaticPopupSpecial_Show = function(frame)
	nativeOpens = nativeOpens + 1
	frame:Show()
	if frame.OnShow then frame:OnShow() end
end
env.StaticPopupSpecial_Hide = function(frame) frame:Hide() end
local nativeShow, nativeAccept = env.AddFriendFrame_Show, env.AddFriendFrame_Accept
check(env.StaticPopupDialogs.BFL_ADD_FRIEND == nil, "No BFL-owned Add Friend popup is registered")
check(BFL.SendFriendRequestByName == nil and BFL.NormalizeFriendInviteName == nil, "No custom typed-input rewriting or submission remains")
check(BFL.ShowAddFriendDialog(), "Forever delegates to Blizzard's opener")
equal(nativeOpens, 1, "Blizzard's actual frame opens once")
check(env.AddFriendEntryFrame.visible and env.AddFriendFrame.BNconnected, "Blizzard initializes the entry frame and connection state")
check(env.AddFriendNameEditBox.focused and not env.AddFriendEntryFrameAcceptButton:IsEnabled(), "Native input is focused and empty submission is disabled")
env.AddFriendNameEditBox:SetText("Ada Lovelace")
check(env.AddFriendEntryFrameAcceptButton:IsEnabled(), "Native typing enables submission")
equal(#sentTitles, 0, "Typing does not send a request")
env.AddFriendFrame_Accept()
equal(sentTitles[1], "Ada Lovelace", "Native Title submission preserves First Last, including the space")
check(not env.AddFriendFrame.visible, "Native acceptance closes the native input")
for _, name in ipairs({ "Ada-Lovelace", "Tag#1234", "ada@example.com" }) do
	BFL.ShowAddFriendDialog()
	env.AddFriendNameEditBox:SetText(name)
	env.AddFriendFrame_Accept()
end
equal(sentTitles[2], "Ada-Lovelace", "Native canonical character spelling is not rewritten")
equal(sentAccounts[1], "Tag#1234", "Native BattleTag handling is preserved")
equal(sentAccounts[2], "ada@example.com", "Native email handling is preserved")
realIDEnabled = false
BFL.ShowAddFriendDialog()
env.AddFriendNameEditBox:SetText("ada@example.com")
check(not env.AddFriendEntryFrameAcceptButton:IsEnabled(), "The native dialog disables Real ID input when unavailable")
check(env.AddFriendFrame.EntryFrame.EditBoxContainer.ErrorMessage.visible, "The native dialog shows its Real ID restriction")
env.AddFriendNameEditBox:SetText("Tag#1234")
check(env.AddFriendEntryFrameAcceptButton:IsEnabled(), "BattleTag input remains usable without Real ID")
check(not env.AddFriendFrame.EntryFrame.EditBoxContainer.ErrorMessage.visible, "The native restriction clears for allowed input")
realIDEnabled = true
equal(env.AddFriendFrame_Show, nativeShow, "BFL does not replace Blizzard's opener")
equal(env.AddFriendFrame_Accept, nativeAccept, "BFL does not hook or replace Blizzard's submit handler")
local nameXML = read(forever, "Interface/AddOns/Blizzard_AddFriend/AddFriendTemplates.xml")
local nativeEnter = between(nameXML, "<OnEnterPressed>", "</OnEnterPressed>"):sub(#"<OnEnterPressed>" + 1)
local function enter() assert(load("return function(self) " .. nativeEnter .. " end", "@Blizzard Add Friend Enter", "t", env))()(env.AddFriendNameEditBox) end
BFL.ShowAddFriendDialog()
enter()
equal(#sentTitles, 2, "Native Enter on empty input sends nothing")
env.AddFriendNameEditBox:SetText("Grace Hopper")
enter()
equal(sentTitles[3], "Grace Hopper", "Native Enter preserves the space spelling too")
infoShown = false
BFL.ShowAddFriendDialog()
check(env.AddFriendInfoFrame.visible and not env.AddFriendEntryFrame.visible, "Blizzard's first-use information page is retained")
env.AddFriendFrame:ShowEntry()
check(env.AddFriendEntryFrame.visible, "Blizzard switches from information to entry normally")
infoShown, connected = true, false
BFL.ShowAddFriendDialog()
equal(errors[#errors], "Disconnected", "Disconnected Forever accounts receive Blizzard's error")
connected = true

-- Load-on-demand still opens Blizzard's frame, never a BFL substitute.
env.AddFriendFrame_Show = nil
local loaded, loadedName = false, nil
env.C_AddOns = { IsAddOnLoaded = function() return loaded end, LoadAddOn = function(name)
	loadedName, loaded, env.AddFriendFrame_Show = name, true, nativeShow
end }
check(BFL.ShowAddFriendDialog(), "The native addon can load on demand")
equal(loadedName, "Blizzard_AddFriend", "The correct Mainline addon is loaded")
env.AddFriendFrame_Show, loaded = nil, false
env.C_AddOns.LoadAddOn = function() end
check(not BFL.ShowAddFriendDialog(), "Missing native Forever UI does not fall back to a legacy friend request")
env.AddFriendFrame_Show = nativeShow
env.C_AddOns = { IsAddOnLoaded = function() return true end }

-- Classic exposes a different native opener; use its real callback and accept.
local classicFriends = read(classic, "Interface/AddOns/Blizzard_UIPanels_Game/Classic/FriendsFrame.lua")
execute(between(classicFriends, "function FriendsFrameAddFriendButton_OnClick(self)", "function FriendsFrameSendMessageButton_OnClick(self)"), "Blizzard Classic opener")
execute(between(classicFriends, "function AddFriendFrame_Accept()", "function AddFriendFrame_IsValidBattlenetName("), "Blizzard Classic accept")
env.AddFriendNoteEditBox = widget()
env.AddFriendEntryFrame_Collapse = function(clear) if clear then env.AddFriendNameEditBox:SetText("") end end
env.AddFriendFrame_ShowEntry = function() env.AddFriendFrame.BNconnected = connected end
env.AddFriendFrame_ShowInfo = function() end
BFL.IsRetail, regional, titleEnabled, env.AddFriendFrame_Show = false, false, false, nil
local before = nativeOpens
check(BFL.ShowAddFriendDialog(), "Classic delegates to its native button callback")
equal(nativeOpens, before + 1, "Classic keeps the advanced native dialog")
env.AddFriendNameEditBox:SetText("Ada-Realm")
env.AddFriendFrame_Accept()
equal(addedLegacy[1], "Ada-Realm", "Native Classic accept keeps the realm-qualified identity")
targetName = "Grace-Realm"
BFL.ShowAddFriendDialog()
equal(addedLegacy[2], "Grace-Realm", "Classic retains Blizzard's direct target-add behavior")
targetName, env.FriendsFrameAddFriendButton_OnClick = nil, nil
check(BFL.ShowAddFriendDialog(), "A legacy client without either opener uses Blizzard's popup")
equal(shownPopup, "ADD_FRIEND", "Only Blizzard's legacy popup is used as fallback")
BFL.IsRetail, regional, titleEnabled = true, true, true
env.AddFriendFrame_Show, env.AddFriendFrame_Accept = nativeShow, nativeAccept

-- Unit/menu requests still retain their separate Blizzard confirmation path.
env.GenerateClosure = function(callback, ...)
	local arguments = { ... }
	return function() return callback(table.unpack(arguments)) end
end
local pendingName, pendingLevel, pendingCallback
env.BattleNetInviteFrame = setmetatable({ ShowInviteConfirmation = function(_, name, level, callback)
	pendingName, pendingLevel, pendingCallback = name, level, callback
end }, { __index = env.BattleNetInviteFrameMixin })
env.EventRegistry = { TriggerEvent = function(_, event, name)
	equal(event, "BattleNetInviteFrame.TitleFriendInviteByNameRequested", "Unit requests retain Blizzard's confirmation event")
	env.BattleNetInviteFrame:OnTitleFriendInviteByNameRequested(name)
end }
check(BFL.SendTitleFriendInviteByName("Ada-Lovelace"), "Context requests retain their native confirmation")
equal(pendingName, "Ada-Lovelace", "Context identity is passed unchanged")
equal(pendingLevel, 3, "Context confirmation requests Title friendship")
before = #sentTitles
pendingCallback()
equal(#sentTitles, before + 1, "Confirming sends one context request")
equal(sentTitles[#sentTitles], "Ada-Lovelace", "Context request keeps its canonical identity")

-- Global Friend Sync uses the complete Forever name for saved and live entries.
BFL.Modules = BFL.modules
execute(read(repo, "Modules/GlobalSync.lua"), "Global Friend Sync")
local sync = BFL:GetModule("GlobalSync")
local rows, tick, delayed = {}, nil, nil
local clock, locked, failedAdd = 100, false, false
env.time = function() return clock end
env.GetNormalizedRealmName = function() return "MyRealm" end
env.UnitName = function() return "Ada", "Lovelace" end
env.UnitFactionGroup = function() return "Alliance" end
env.C_ChatInfo = { InChatMessagingLockdown = function() return locked end }
env.C_Timer = {
	NewTimer = function(_, callback) delayed = callback; return {} end,
	NewTicker = function(_, callback)
		tick = function() callback({ Cancel = function() end }) end
		return {}
	end,
}
env.C_FriendList.GetNumFriends = function() return #rows end
env.C_FriendList.GetFriendInfoByIndex = function(index) return rows[index] end
env.C_FriendList.AddFriend = function(name)
	if failedAdd then error("blocked") end
	addedLegacy[#addedLegacy + 1] = name
end
env.BetterFriendlistDB = {
	enableGlobalSync = true,
	enableGlobalSyncDeletion = true,
	GlobalFriends = { Alliance = {} },
}
sync.attemptedAdds = {}
local stored = env.BetterFriendlistDB.GlobalFriends.Alliance
regional, titleEnabled = true, false
check(not sync:ShouldAddFriend("Ada-Lovelace"), "Forever rejects the current character including surname")
check(sync:ShouldAddFriend("Ada-Byron"), "A different surname is a different character")
rows = { { name = "Grace-Hopper", notes = secret, guid = secret } }
sync:ExportFriends("Alliance", "MyRealm")
equal(stored["Grace-Hopper"].notes, nil, "A secret note stays out of the database")
equal(stored["Grace-Hopper"].guid, nil, "A secret GUID stays out of the database")
equal(select(2, sync:GetFriendNameAndRealm("Grace-Hopper")), nil, "The surname is not a realm")
rows = { secret }
sync:ImportFriends("Alliance", "MyRealm")
equal(tick, nil, "A restricted roster cannot be treated as an empty list")
rows = {}
sync:ImportFriends("Alliance", "MyRealm")
locked = true
tick()
equal(sync.attemptedAdds["Grace-Hopper"], nil, "A queue paused by lockdown does not consume the attempt")
locked, failedAdd = false, true
sync:ImportFriends("Alliance", "MyRealm")
tick()
equal(sync.attemptedAdds["Grace-Hopper"], nil, "A blocked native call does not consume the attempt")
failedAdd = false
sync:ImportFriends("Alliance", "MyRealm")
tick()
equal(addedLegacy[#addedLegacy], "Grace-Hopper", "Retry sends the full Forever name unchanged")
rows = { { name = "Grace-Hopper" }, { name = "Ada-Byron" } }
sync:ExportFriends("Alliance", "MyRealm")
sync:ReconcileIndexRemoval("MyRealm")
local hooks = {}
env.hooksecurefunc = function(_, key, callback) hooks[key] = callback end
env.C_FriendList.RemoveFriendByIndex = function() end
local nativeRemoveByIndex = env.C_FriendList.RemoveFriendByIndex
sync:HookDeletionAPIs()
equal(env.C_FriendList.RemoveFriendByIndex, nativeRemoveByIndex, "Global Sync leaves Blizzard's removal function in place")
hooks.RemoveFriendByIndex(2)
rows = { secret }
sync:ReconcileIndexRemoval("MyRealm")
check(not stored["Ada-Byron"].deleted, "A protected snapshot cannot confirm an index removal")
rows = { { name = "Grace-Hopper" } }
sync:ReconcileIndexRemoval("MyRealm")
check(stored["Ada-Byron"].deleted and not stored["Grace-Hopper"].deleted, "Only the missing full name is marked as deleted")

titleEnabled = true
env.BetterFriendlistDB, env.C_ChatInfo, env.C_Timer = nil, nil, nil

-- Run the production request event callbacks through Blizzard's actual toast handler.
local requestCallbacks = execute(between(read(repo, "Modules/FriendsList.lua"),
	"local EventCallback_BNetInviteListInitialized,", "local function HookScript_OnFrameShow(")
	.. "\nreturn { added = EventCallback_BNetInviteAdded, initialized = EventCallback_BNetInviteListInitialized }",
	"friend request callbacks")
local toastCVars = { showToastWindow = "1", showToastFriendRequest = "1" }
local originalGetCVar, originalGetCVarBool = env.GetCVar, env.GetCVarBool
local originalGameRule, originalFriendsList = BFL.IsGameRuleActive, BFL.FriendsList
env.GetCVar = function(name) return toastCVars[name] end
env.GetCVarBool = function(name) return toastCVars[name] == "1" end
BFL.IsGameRuleActive = function() return false end
BFL.FriendsList = { ScheduleRefresh = function() end }
for _, native in ipairs({ { forever, "Mainline" }, { classic, "Classic" } }) do
	execute(read(native[1], "Interface/AddOns/Blizzard_BNet/" .. native[2] .. "/BNet.lua"), "Blizzard BNet")
	local registered, notifications = false, {}
	env.BNToastFrame = setmetatable({
		IsEventRegistered = function() return registered end,
		AddToast = function(_, kind, count) notifications[#notifications + 1] = { kind, count } end,
	}, { __index = env.BNToastMixin })
	requestCallbacks.added(secret)
	requestCallbacks.initialized(2)
	equal(notifications[1][1], 5, native[2] .. " uses Blizzard's new request toast")
	equal(notifications[2][1], 4, native[2] .. " uses Blizzard's pending request toast")
	equal(notifications[2][2], 2, native[2] .. " preserves the pending count")
	requestCallbacks.initialized(0)
	requestCallbacks.initialized(secret)
	registered = true
	requestCallbacks.added()
	registered, toastCVars.showToastWindow = false, "0"
	requestCallbacks.added()
	toastCVars.showToastWindow, toastCVars.showToastFriendRequest = "1", "0"
	requestCallbacks.added()
	toastCVars.showToastFriendRequest = "1"
	equal(#notifications, 2, native[2] .. " suppresses empty, secret, duplicate and disabled notifications")
end
env.BNToastFrame, env.GetCVar, env.GetCVarBool = nil, originalGetCVar, originalGetCVarBool
BFL.IsGameRuleActive, BFL.FriendsList = originalGameRule, originalFriendsList

-- Exercise the production copy handler for focused accounts and plain contexts.
local legacy = read(repo, "BetterFriendlist.lua")
local buildCopy = execute(between(legacy, "local function BFL_BuildCopyNameHandler(", "local function BFL_ReplaceCopyNameButton(") .. "\nreturn BFL_BuildCopyNameHandler", "copy menu handler")
local account = { gameAccountInfo = { characterName = "Ada-Lovelace", realmName = "Realm" }, battleTag = "Tag#1234" }
env.C_BattleNet.GetAccountInfoByID = function() return account end
function dialog.EditBox:HighlightText() end
function dialog.EditBox:SetScript() end
local function copied(context, wrapper)
	buildCopy(context, wrapper)()
	env.StaticPopupDialogs.BETTERFRIENDLIST_COPY_URL.OnShow(dialog)
	return dialog.EditBox:GetText()
end
equal(copied({ bnetIDAccount = 42 }), "Ada-Lovelace", "Focused account copy omits the realm")
equal(copied({ name = "Ada", surname = "Lovelace", server = "Realm" }), "Ada-Lovelace", "Context copy combines surname, not server")
env.C_FriendList.GetWhoInfo = function() return { fullName = "Ada-Lovelace" } end
equal(copied({ name = "Ada", whoIndex = 1 }, "WHO"), "Ada-Lovelace", "Who copy preserves the full surname")
regional = false
account.gameAccountInfo.characterName = "Ada"
equal(copied({ bnetIDAccount = 42 }), "Ada-Realm", "Traditional focused-account copy keeps the realm")
regional = true
account.gameAccountInfo = nil
equal(copied({ bnetIDAccount = 42 }), "Tag#1234", "Offline BattleTag fallback is not rewritten")

-- Test both replacement and fallback multi-account submenus using real callbacks.
local friends = { friendsList = { { type = "bnet", bnetAccountID = 42, gameAccounts = {
	{ clientProgram = "WoW", characterName = "Ada-Lovelace", realmName = "Realm" },
	{ clientProgram = "WoW", characterName = "Grace-Hopper", realmName = "OtherRealm" },
} } } }
function friends:BuildAccountDisplay(raw) return { text = raw.characterName, raw = raw } end
env.GetFriendsList = function() return friends end
env.BFL_IsOwnMenuContext = function(context) return context.bflOwn == true end
local replaceCopy = execute(between(legacy, "local function BFL_ReplaceCopyNameButton(", "\n\t\t\tlocal function BFL_GetDisplayedInviteTypeSafe(") .. "\nreturn BFL_ReplaceCopyNameButton", "multi-account copy menu")
local function element(text)
	local value = { text = text, children = {} }
	function value:SetResponder(callback) self.callback = callback end
	function value:SetText(label) self.text = label end
	function value:CreateButton(label, callback)
		local child = element(label); child.callback = callback
		self.children[#self.children + 1] = child
		return child
	end
	return value
end
for _, replace in ipairs({ true, false }) do
	local root = element("root")
	local copy = replace and element("Copy Character Name") or nil
	root.elements = copy and { copy } or {}
	function root:EnumerateElementDescriptions() return ipairs(self.elements) end
	replaceCopy(nil, root, { bnetIDAccount = 42, bflOwn = true })
	local submenu = copy or root.children[1]
	equal(#submenu.children, 2, "Multi-account replacement/fallback retains both character choices")
	submenu.children[1].callback()
	env.StaticPopupDialogs.BETTERFRIENDLIST_COPY_URL.OnShow(dialog)
	equal(dialog.EditBox:GetText(), "Ada-Lovelace", "Multi-account choice copies the surname without the realm")
end

-- The actual Remove Friend action uses fresh metadata and keeps the raw ID.
env.BFL_GetBNetAccountInfo = function() return { friendLevel = 2 } end
env.BFL_GetContextDisplayName = function() return "Alias" end
local addRemove = execute(between(legacy, "local function BFL_ShowRemoveWoWFriendPrompt(", "local function BFL_AddIgnoreOrBlockButton(") .. "\nreturn BFL_AddRemoveFriendButton", "remove friend menu")
local root = element("root")
addRemove(root, { bnetIDAccount = 42 }, true)
for _, test in ipairs({ { level = 3, prompt = "WoW friend: Alias" }, { level = 1, prompt = "BattleTag friend: Alias" },
	{ level = 2, prompt = "Real ID friend: Alias" } }) do
	account = { friendLevel = test.level, accountName = "Private Real Name" }
	root.children[1].callback()
	equal(shownPopup, "CONFIRM_REMOVE_BN_FRIEND", "Removal retains Blizzard's confirmation dialog")
	equal(popupArgs[1], test.prompt, "Fresh friend type selects the correct removal wording")
	equal(popupArgs[3], 42, "Removal retains the raw account ID")
end
env.BFL_GetContextFullName = function() return "Ada-Realm" end
env.BFL_HasFriendListContext = function() return true end
root = element("root")
addRemove(root, {}, false)
root.children[1].callback()
equal(shownPopup, "BFL_CONFIRM_REMOVE_WOW_FRIEND", "Legacy WoW removal keeps its separate confirmation")
equal(popupArgs[1], "Remove Ada-Realm from your friends list?", "Legacy WoW confirmation does not call the player a Real ID friend")
local removedName
BFL.RemoveFriend = function(name) removedName = name; return true end
env.StaticPopupDialogs.BFL_CONFIRM_REMOVE_WOW_FRIEND.OnAccept()
equal(removedName, "Ada-Realm", "Legacy removal keeps the raw realm-qualified identity")

-- Modern and Legacy buttons both route through the shared opener.
check(read(repo, "BetterFriendlist.xml"):find("BFL.ShowAddFriendDialog()", 1, true), "Legacy button routes through the shared opener")
check(read(repo, "BetterFriendlist_Classic.xml"):find("BFL.ShowAddFriendDialog()", 1, true), "Classic button routes through the same native opener")
env.FriendsUI = { GetContactChrome = function() return { action = "add_friend" } end }
execute(between(read(repo, "Modules/FriendsUI.lua"), "function FriendsUI:PerformContactAction()", "function FriendsUI:ShouldReserveModernActionFooter("), "Modern contact action")
before = nativeOpens
env.FriendsUI:PerformContactAction()
equal(nativeOpens, before + 1, "Modern contact action opens Blizzard's actual input")

-- Model row input routing while keeping Blizzard's click callback untouched.
do
	local combat, streamer, chatLocked = false, false, false
	local messages, frames = {}, {}
	BFL.IsForever = true
	BFL.StreamerMode = { IsActive = function() return streamer end }
	env.InCombatLockdown = function() return combat end
	env.C_ChatInfo = { InChatMessagingLockdown = function() return chatLocked end }
	env.UIErrorsFrame.AddExternalErrorMessage = function(_, text) messages[#messages + 1] = text end
	env.DEFAULT_CHAT_FRAME = { AddMessage = function() error("The friend menu must not write to chat") end }
	env.STANDARD_TEXT_FONT = "Standard"
	env.Menu = { ModifyMenu = function() end }
	env.MenuUtil = { GetElementText = function() end, SetElementText = function() end }
	env.SetItemRef = function() end
	local mouseFocus
	env.GetMouseFoci = function() return mouseFocus and { mouseFocus } or {} end
	local nativeWhispers, nativeMenus = 0, 0
	local function nativeClick(_, _, _, button)
		if button == "LeftButton" then nativeWhispers = nativeWhispers + 1 end
		if button == "RightButton" then nativeMenus = nativeMenus + 1 end
	end
	local clickTimers = {}
	env.C_Timer = { NewTimer = function(seconds, callback)
		local timer = { seconds = seconds }
		function timer:Cancel() self.cancelled = true end
		function timer:Fire() if not self.cancelled then callback() end end
		clickTimers[#clickTimers + 1] = timer
		return timer
	end }
	local hasNativeHandler = true
	local routingTemplates = read(repo, "UI/NativeFriendMenu.xml")
	local function frame()
		local f = { scripts = {}, hooks = {}, level = 10, height = 40 }
		function f:SetScript(event, callback) self.scripts[event] = callback end
		function f:GetScript(event) return self.scripts[event] end
		function f:HookScript(event, callback) self.hooks[event] = callback; return true end
		function f:Show() self.shown = true end
		function f:Hide() self.shown = false end
		function f:IsShown() return self.shown end
		function f:IsVisible() return self.shown end
		function f:IsMouseOver() return self.underMouse ~= false end
		function f:EnableMouse(value)
			assert(self.template == "InlineHyperlinkFrameTemplate", "only the direct Blizzard link enables mouse input in Lua")
			self.mouse = value
		end
		function f:GetHeight() return self.height end
		function f:SetAllPoints(target) self.cover = target end
		function f:SetClipsChildren(value) self.clips = value end
		function f:GetFrameLevel() return self.level end
		function f:SetFrameLevel(level) self.level = level end
		function f:LockHighlight() self.highlighted = true end
		function f:UnlockHighlight() self.highlighted = false end
		function f:IsEnabled() return true end
		function f:SetButtonState(state, lock) self.buttonState, self.buttonStateLocked = state, lock end
		function f:RegisterForClicks() error("click registration must come from XML") end
		function f:RegisterForDrag(button) self.drag = button end
		function f:RegisterEvent(event) self[event] = true end
		function f:SetPassThroughButtons() error("mouse forwarding must come from XML") end
		function f:SetPropagateMouseMotion() error("mouse motion forwarding must come from XML") end
		function f:CreateFontString()
			local font = { points = {} }
			function font:SetJustifyH() end
			function font:SetJustifyV() end
			function font:SetWordWrap(value) self.wrap = value end
			function font:SetAlpha(value) self.alpha = value end
			function font:SetFont(_, size) self.size = size end
			function font:GetLineHeight() return self.size + 2 end
			function font:SetPoint(point, target, anchor, x, y)
				self.points[point] = { target = target, anchor = anchor, x = x or 0, y = y or 0 }
			end
			function font:SetFormattedText(format, ...)
				assert(self.size, "SetFormattedText: Font not set")
				self.format, self.args = format, { ... }
			end
			self.font = font
			return font
		end
		return f
	end
	local function templateAttributes(template)
		if template == "InlineHyperlinkFrameTemplate" then return { nativeLink = true } end
		local definition = template and routingTemplates:match('<[%w]+ name="' .. template .. '"[^>]+>')
		if not definition then return {} end
		local attributes = templateAttributes(definition:match('inherits="([^"]+)"'))
		for key, value in definition:gmatch('(%w+)="([^"]+)"') do attributes[key] = value end
		return attributes
	end
	env.CreateFrame = function(_, _, parent, template)
		local f = frame()
		f.parent = parent
		f.template = template
		local attrs = templateAttributes(template)
		f.pass, f.passLeft = (attrs.passThroughButtons or ""):match("^(%w+),?%s*(%w*)")
		if f.passLeft == "" then f.passLeft = nil end
		f.motion = attrs.propagateMouseInput == "Motion" or nil
		f.mouse = attrs.enableMouse == "true" or nil
		f.click = attrs.registerForClicks
		if attrs.nativeLink then
			if hasNativeHandler then f:SetScript("OnHyperlinkClick", nativeClick) end
		end
		frames[#frames + 1] = f
		return f
	end

	local friends = BFL:RegisterModule("FriendsList", {})
	function friends:UpdateSendMessageButton() end
	local whisperMode
	function friends:GetClickWhisperMode() return whisperMode end
	function friends:IsReadableInviteRecord(value) return type(value) == "table" and value ~= secret end
	function friends:GetReadableInviteField(value, key)
		if self:IsReadableInviteRecord(value) and not BFL:IsSecret(value[key]) then return value[key] end
	end
	local friendSource = read(repo, "Modules/FriendsList.lua")
	friends.HandleFriendWhisperClick = execute("local FriendsList = {}\n"
		.. between(friendSource, "function FriendsList:HandleFriendWhisperClick(", "-- Replace token case-insensitively")
		.. "\nreturn FriendsList.HandleFriendWhisperClick", "friend click whisper action")
	execute("local StreamerMode = BFL.StreamerMode\nlocal L = BFL.L\n" .. between(read(repo, "Modules/StreamerMode.lua"),
		"function StreamerMode:GetFriendMenuLabel(", "function StreamerMode:ApplyToggleButtonVisualState("), "Streamer Mode menu title")
	local selectionVisual = execute("local FriendsList = {}\n" .. between(read(repo, "Modules/FriendsList.lua"),
		"function FriendsList:SetButtonSelectionVisual(", "function FriendsList:ClearSelection()")
		.. "\nreturn FriendsList.SetButtonSelectionVisual", "selection and hover visual")
	friends.SetButtonSelectionVisual = selectionVisual
	local first = { type = "bnet", accountName = "Example", bnetAccountID = 42, totalGameAccounts = 3, isOnline = false }
	local second = { type = "bnet", bnetAccountID = 91, friendLevel = 3 }
	local row = frame()
	row.travelPassButton = frame()
	env.C_BattleNet.GetAccountInfoByID = function(id)
		equal(id, 91, "the raw-name lookup stays on the clicked account")
		return { accountName = secret }
	end

	execute(read(repo, "Modules/NativeFriendMenu.lua"), "Modules/NativeFriendMenu.lua")
	local test = BFL:GetModule("NativeFriendMenu")
	local friend = first
	function friends:RenderDisplay()
		row.friendData = friend
		test:UpdateRow(friends, row, friend)
	end
	test:Initialize()
	friends:RenderDisplay()
	equal(env.SlashCmdList.BFLNATIVEWHISPER, nil, "the friend menu has no session command")
	equal(#frames, 4, "the first render attaches the native click layers")
	local events, hit, catch, leftCatch = table.unpack(frames)
	check(hit.shown and catch.shown, "offline multi-account rows use the same route")
	check(hit.mouse and catch.mouse, "both layers receive mouse input")
	equal(hit.template, "InlineHyperlinkFrameTemplate", "friend links use Blizzard's template directly")
	check(hit.cover == row and catch.cover == row, "click layers cover the actual friend row")
	check(hit:GetScript("OnHyperlinkClick") == nativeClick, "BFL leaves Blizzard's hyperlink handler intact")
	equal(hit.pass, nil, "the native template keeps its mouse routing")
	equal(catch.pass, "RightButton", "only right-click passes through the upper layer")
	check(catch.motion and row.level < hit.level and hit.level < catch.level, "mouse motion passes through the upper layer")
	check(row.travelPassButton.level > catch.level, "the invite control keeps its own click target")
	equal(catch.click, "LeftButtonUp", "left click keeps BFL's ordinary release behavior")
	equal(hit.font.wrap, false, "native hyperlink uses one line across the row")
	check(hit.clips and hit.cover == row, "the native hyperlink is clipped to its own row")
	local top, bottom = hit.font.points.TOPLEFT, hit.font.points.BOTTOMRIGHT
	check(top.target == hit and top.anchor == "TOPLEFT" and top.y == 0, "the link starts at the row's top edge")
	check(bottom.target == hit and bottom.anchor == "BOTTOMRIGHT" and bottom.y == 0, "the link ends at the row's bottom edge")
	equal(hit.font:GetLineHeight(), row.height, "the hyperlink uses font metrics to fit inside the row")
	row.height = 62
	hit:GetScript("OnSizeChanged")(hit, 350, row.height)
	equal(hit.font:GetLineHeight(), row.height, "the hyperlink follows row height changes after binding")
	equal(hit.font.alpha, 0, "native hyperlink is invisible")
	equal(hit.font.args[2], 42, "the row binds the correct account ID")
	mouseFocus = catch
	check(test:GetMenuFriend({ bnetIDAccount = "42" }, true) == row, "native link matches the active BFL row")
	equal(test:GetMenuFriend({ bnetIDAccount = 91 }, true), nil, "the menu identity must match the current row")
	equal(test:GetMenuFriend({ bnetIDAccount = secret }, true), nil, "secret menu identities are not used")
	equal(test:GetMenuFriend({ bnetIDAccount = 42, chatFrame = {} }, true), nil, "a chat link is not a BFL row")
	equal(test:GetMenuFriend({ bnetIDAccount = 42, friendsList = 1 }, true), nil, "a Blizzard list row is not a BFL row")
	check(hit.font.format:find("BN_WHISPER", 1, true), "the Battle.net link uses Blizzard's Whisper context")
	equal(#messages, 0, "the default route requires no notification")

	local callbacks = {}
	for _, event in ipairs({ "OnEnter", "OnLeave", "OnClick", "OnDoubleClick", "OnDragStart", "OnDragStop" }) do
		row:SetScript(event, function(owner, button)
			check(owner == row, event .. " delegates to the original row")
			callbacks[event] = (callbacks[event] or 0) + 1
		end)
	end
	catch:GetScript("OnEnter")(catch)
	check(row.highlighted, "hover highlights the friend row")
	equal(hit:GetScript("OnHyperlinkLeave"), nil, "leaving an invisible glyph cannot clear row hover")
	equal(callbacks.OnEnter, 1, "the catch layer alone owns hover")
	row:SetScript("OnClick", function(owner, button)
		check(owner == row and button == "LeftButton", "left release reaches the original row")
		callbacks.OnClick = (callbacks.OnClick or 0) + 1
		friends.selectedButton = row
		friends:SetButtonSelectionVisual(row, true)
	end)
	local down, up = catch:GetScript("OnMouseDown"), catch:GetScript("OnMouseUp")
	down(catch, "LeftButton")
	up(catch, "LeftButton")
	equal(callbacks.OnClick, 1, "the first mouse release selects immediately")
	equal(catch:GetScript("OnClick"), nil, "the button cannot dispatch the same selection twice")
	catch:GetScript("OnLeave")(catch)
	check(row.highlighted, "leaving the selected row preserves its highlight")
	friends.selectedButton = nil
	friends:SetButtonSelectionVisual(row, false)
	check(not row.highlighted, "clearing selection after leaving clears the highlight")

	down(catch, "LeftButton")
	for _, event in ipairs({ "OnDoubleClick", "OnDragStart", "OnDragStop" }) do
		catch:GetScript(event)(catch, "LeftButton")
		equal(callbacks[event], 1, event .. " preserves the normal BFL row action")
	end
	up(catch, "LeftButton")
	equal(callbacks.OnClick, 1, "releasing a drag does not select the row")

	down(catch, "LeftButton")
	friend = second
	friends:RenderDisplay()
	up(catch, "LeftButton")
	equal(callbacks.OnClick, 1, "a recycled row cannot inherit a pending left press")
	equal(test:GetMenuFriend({ bnetIDAccount = 42 }, true), nil, "a recycled row does not match the old link")
	equal(#frames, 4, "reused rows reuse their click layers")
	equal(hit.font.args[2], 91, "the recycled row uses the new friend ID")
	check(rawequal(hit.font.args[1], secret), "a secret name goes directly into the native font formatter")
	friend = { type = "wow", name = "Example-Realm" }
	friends:RenderDisplay()
	equal(hit.font.args[1], "Example-Realm", "WoW-only friends use a native player link")
	check(test:GetMenuFriend({ name = "Example", surname = "Realm" }, false) == row, "native name splitting keeps the character identity")
	check(test:GetMenuFriend({ name = "Example", server = "Realm" }, false) == row, "Classic and Retail realm fields resolve the character")
	equal(test:GetMenuFriend({ name = "Example", server = "OtherRealm" }, false), nil, "same-name characters on another realm are distinct")
	test:UpdateRow(friends, row, { type = "bnet", bnetAccountID = secret })
	check(not hit.shown and not catch.shown, "unavailable identity hides both layers")
	local fallbackFriend, fallbackOwner
	env.GetFriendsList = function() return friends end
	env.PlaySound, env.SOUNDKIT = function() end, {}
	function BFL:OpenFriendMenuFallback(owner, target) fallbackOwner, fallbackFriend = owner, target end
	execute(between(legacy, "function BetterFriendsList_Button_OnClick(", "function BetterFriendsList_Button_OnDoubleClick("),
		"friend row fallback click")
	env.BetterFriendsList_Button_OnClick(row, "RightButton")
	check(fallbackOwner == row and fallbackFriend == row.friendData, "a click that misses the link opens the BFL menu for the current row")

	friend = first
	friends:RenderDisplay()
	combat = true
	events:GetScript("OnEvent")(events, "PLAYER_REGEN_DISABLED")
	check(hit.shown and catch.shown and not leftCatch.shown, "combat keeps right-click when click-to-whisper is off")
	equal(catch.pass, "RightButton", "the XML catch frame passes right-click")
	equal(catch.passLeft, nil, "the selection frame keeps left-click with BFL")
	local beforeMessages = #messages
	for _, mode in ipairs({ "single", "double" }) do
		whisperMode = mode
		friends:HandleFriendWhisperClick(friend, mode)
	end
	whisperMode = nil
	equal(#messages, beforeMessages, "combat click actions suppress the whisper error")
	equal(nativeWhispers, 0, "combat click actions do not open chat")
	mouseFocus = catch
	check(test:GetMenuFriend({ bnetIDAccount = 42 }, true) == row, "the fixed frame identifies the clicked friend in combat")
	local combatRow = frame()
	combatRow.friendData = first
	test:UpdateRow(friends, combatRow, first)
	local combatHit, combatCatch = frames[#frames - 2], frames[#frames - 1]
	check(combatHit.shown and combatCatch.shown, "a row first rendered in combat can bind its right-click")
	combat = false
	events:GetScript("OnEvent")(events, "PLAYER_REGEN_ENABLED")
	check(hit.shown and catch.shown, "native routing resumes as combat ends")
	mouseFocus = catch
	streamer = true
	test:UpdateRow(friends, row, friend)
	check(hit.shown and catch.shown, "Streamer Mode keeps the native right-click")
	local title = {}
	function title:AddInitializer(callback) self.initializer = callback end
	local titleRoot = { EnumerateElementDescriptions = function() return ipairs({ title }) end }
	local titleFrame = { fontString = { SetText = function(self, value) self.text = value end } }
	local whisperContext = { name = secret, bnetIDAccount = 42 }
	local originalDB = BFL:GetModule("DB")
	local format, nickname = "battletag", "Friend alias"
	BFL:RegisterModule("DB", { Get = function() return format end, GetNickname = function(_, uid)
		equal(uid, "bnet_Masked#1234", "menu title looks up the existing nickname by stable UID")
		return nickname
	end })
	friend.uid, friend.battleTag, friend.note = "bnet_Masked#1234", "Masked#1234", "Friend note"
	friend.friendLevel = env.Enum.BattleNetFriendLevel.RealID
	for _, example in ipairs({ { "battletag", "Masked" }, { "nickname", "Friend alias" }, { "note", "Friend note" } }) do
		format = example[1]
		test:MaskNativeMenuTitle(titleRoot, friend)
		titleFrame.fontString:SetText(whisperContext.name)
		title.initializer(titleFrame)
		equal(titleFrame.fontString.text, example[2], "the title uses the configured " .. format)
		check(rawequal(whisperContext.name, secret), "the title does not change the native recipient")
	end
	format, nickname = "nickname", ""
	title.initializer = nil
	test:MaskNativeMenuTitle(titleRoot, friend)
	title.initializer(titleFrame)
	equal(titleFrame.fontString.text, "Masked", "a missing nickname falls back to the short BattleTag for Real ID")
	friend.battleTag, friend.characterName = nil, "Character"
	test:MaskNativeMenuTitle(titleRoot, friend)
	title.initializer(titleFrame)
	equal(titleFrame.fontString.text, "Character", "a Real ID friend without a readable tag falls back to the character")
	friend.characterName = nil
	test:MaskNativeMenuTitle(titleRoot, friend)
	title.initializer(titleFrame)
	equal(titleFrame.fontString.text, BFL.L.UNKNOWN, "a Real ID name is kept private even without a tag or character")
	test:MaskNativeMenuTitle(titleRoot, nil, true)
	title.initializer(titleFrame)
	equal(titleFrame.fontString.text, BFL.L.UNKNOWN, "unreadable Battle.net context keeps a BFL row's Real ID name private")
	format = "battletag"
	title.initializer = nil
	test:MaskNativeMenuTitle(titleRoot, { type = "wow", name = "Character-Realm" })
	equal(title.initializer, nil, "a character without a BattleTag keeps Blizzard's character name")
	BFL.modules.DB = originalDB
	mouseFocus = catch
	local chatLink = true
	env.IsModifiedClick = function(mode) return chatLink and mode == "CHATLINK" end
	events.scripts.OnEvent(events, "MODIFIER_STATE_CHANGED")
	check(not hit.shown, "Streamer Mode prevents a modified link click from exposing the name")
	chatLink = false
	events.scripts.OnEvent(events, "MODIFIER_STATE_CHANGED")
	check(hit.shown, "releasing the chat-link modifier restores the menu")
	chatLocked = true
	test:UpdateRow(friends, row, friend)
	check(hit.shown and catch.shown, "chat lockdown keeps the native friend menu link")
	check(test:GetMenuFriend({ bnetIDAccount = 42 }, true) == row, "chat lockdown keeps the native friend context")
	streamer, chatLocked = false, false
	friends:RenderDisplay()
	check(hit.shown and catch.shown, "the native route recovers after restrictions lift")
	BFL.IsForever = false
	BFL.IsMainline = true
	BFL.TOCVersion = 120105
	BFL.VERSION = "3.0.2"
	env.IsPublicTestClient = function() return false end
	friends:RenderDisplay()
	check(hit.shown and catch.shown, "Retail Live 12.1.5 enables native row input in the release build")
	check(test:GetMenuFriend({ bnetIDAccount = "42" }, true) == row, "Retail Live uses the native friend context")
	local nativeSelections = 0
	env.BetterFriendsList_Button_OnClick = function(target, button, skipWhisper)
		check(target == row and button == "LeftButton" and skipWhisper, "native single click selects without the legacy whisper")
		nativeSelections = nativeSelections + 1
	end
	local function click(button)
		local activeCatch = leftCatch.shown and leftCatch or catch
		if activeCatch.pass == button or activeCatch.passLeft == button then
			hit:GetScript("OnHyperlinkClick")(hit, nil, nil, button)
			hit.hooks.OnHyperlinkClick(hit, nil, nil, button)
		else
			down(activeCatch, button)
			up(activeCatch, button)
		end
	end
	local canWhisper = true
	BFL.CanSendWhisper = function() return canWhisper end
	whisperMode = "single"
	chatLocked = true
	test:RefreshClickRouting()
	check(leftCatch.shown and not catch.shown, "single-click mode uses the fixed frame that forwards both clicks")
	equal(leftCatch.passLeft, "LeftButton", "single-click mode passes the hardware click directly to Blizzard")
	combat = true
	events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
	check(leftCatch.shown and not catch.shown, "single-click remains routed in combat")
	click("LeftButton")
	equal(nativeWhispers, 1, "one click reaches the native whisper handler in combat with chat lockdown")
	equal(nativeSelections, 1, "single click still updates the selection")
	hit:GetScript("OnDragStart")(hit, "LeftButton")
	hit:GetScript("OnDragStop")(hit, "LeftButton")
	equal(callbacks.OnDragStart, 2, "single-click mode preserves row dragging")
	equal(callbacks.OnDragStop, 2, "single-click mode preserves drag release")
	streamer = true
	whisperMode = "double"
	test:RefreshClickRouting()
	local previousSelections = callbacks.OnClick
	click("LeftButton")
	equal(nativeWhispers, 1, "the first click selects without whispering")
	equal(callbacks.OnClick, previousSelections + 1, "the first click goes to BFL selection")
	check(leftCatch.shown and not catch.shown, "the first click arms the fixed left-click route in combat with Streamer Mode")
	equal(clickTimers[#clickTimers].seconds, 0.3, "the second click has a bounded window")
	catch:GetScript("OnLeave")(catch)
	check(leftCatch.shown, "switching catch frames does not cancel the pending whisper")
	catch:GetScript("OnDoubleClick")(catch, "LeftButton")
	equal(callbacks.OnDoubleClick, 1, "native double-click does not run BFL's old whisper callback")
	click("LeftButton")
	equal(nativeWhispers, 2, "the second hardware click opens one whisper in combat with Streamer Mode")
	check(catch.shown and not leftCatch.shown, "native dispatch immediately disarms the double-click window")
	click("LeftButton")
	clickTimers[#clickTimers]:Fire()
	check(catch.shown and not leftCatch.shown, "a late second click starts another selection sequence")
	click("LeftButton")
	leftCatch:GetScript("OnLeave")(leftCatch)
	check(catch.shown and not leftCatch.shown, "leaving the row cancels the second click")
	click("LeftButton")
	click("RightButton")
	check(catch.shown and not leftCatch.shown, "a right click cancels the second click without changing native right-click")
	click("LeftButton")
	chatLink = true
	events.scripts.OnEvent(events, "MODIFIER_STATE_CHANGED")
	check(not hit.shown and not leftCatch.shown, "the chat-link modifier hides the armed whisper in Streamer Mode")
	chatLink = false
	events.scripts.OnEvent(events, "MODIFIER_STATE_CHANGED")
	check(catch.shown and not leftCatch.shown, "releasing the modifier starts a new double-click sequence")
	click("LeftButton")
	friend = second
	friends:RenderDisplay()
	check(catch.shown and not leftCatch.shown, "rebinding the row cancels the pending whisper for the previous friend")
	friend = first
	friends:RenderDisplay()
	whisperMode = "single"
	canWhisper = false
	test:RefreshClickRouting()
	check(catch.shown and not leftCatch.shown, "an age restriction still prevents the native left-click route")
	canWhisper, chatLocked = true, false
	whisperMode = nil
	streamer = false
	combat = false
	test:RefreshClickRouting()

	local alt, shift = false, false
	env.IsAltKeyDown = function() return alt end
	env.IsShiftKeyDown = function() return shift end
	local brokerRow = frame()
	brokerRow.height = 1 -- LibQTip starts new rows at one pixel until UpdateLayout.
	local brokerFriend = {
		type = "bnet", bnetAccountID = 76, connected = true,
		accountName = "Display fallback", accountInfo = { accountName = "Native recipient" },
	}
	local brokerHover, brokerClicks = false, 0
	brokerRow:SetScript("OnEnter", function() brokerHover = true end)
	brokerRow:SetScript("OnLeave", function() brokerHover = false end)
	brokerRow:SetScript("OnMouseUp", function(_, button)
		brokerClicks = brokerClicks + 1
		check(button == "LeftButton" or button == "RightButton", "broker forwards the actual mouse button")
	end)
	streamer = true
	test:UpdateBrokerRow(brokerRow, brokerFriend)
	local brokerHit, brokerCatch, brokerLeftCatch, brokerBothCatch = table.unpack(frames, #frames - 3, #frames)
	check(brokerHit.shown and brokerBothCatch.shown, "the broker uses the native hit area")
	equal(brokerHit.template, "InlineHyperlinkFrameTemplate", "broker links use Blizzard's template directly")
	check(brokerHit:GetScript("OnHyperlinkClick") == nativeClick, "the broker keeps Blizzard's hyperlink handler")
	check(brokerHit.font.size > 0 and brokerHit.font.format, "a fresh broker row can bind its link before final tooltip layout")
	equal(brokerHit.font.args[1], "Native recipient", "the broker uses the API recipient for the native link")
	equal(brokerHit.font.args[2], 76, "the broker binds the clicked account ID")
	equal(brokerBothCatch.pass, "RightButton", "the broker right click goes to the native friend menu")
	equal(brokerBothCatch.passLeft, "LeftButton", "broker left click is independent of the friends list click setting")
	local function brokerClick(button)
		local activeCatch = brokerBothCatch.shown and brokerBothCatch
			or (brokerLeftCatch.shown and brokerLeftCatch) or (brokerCatch.shown and brokerCatch)
		if activeCatch and (activeCatch.pass == button or activeCatch.passLeft == button) then
			brokerHit:GetScript("OnHyperlinkClick")(brokerHit, nil, nil, button)
		elseif activeCatch then
			activeCatch:GetScript("OnMouseDown")(activeCatch, button)
			activeCatch:GetScript("OnMouseUp")(activeCatch, button)
		else
			brokerRow:GetScript("OnMouseUp")(brokerRow, button)
		end
	end
	local previousNativeMenus = nativeMenus
	brokerClick("LeftButton")
	brokerClick("RightButton")
	equal(nativeWhispers, 3, "the Friends Broker's left click opens one whisper in Streamer Mode")
	equal(nativeMenus, previousNativeMenus + 1, "the broker's native right click opens one menu")
	equal(brokerClicks, 0, "native dispatch does not also invoke a broker action")
	brokerHit:GetScript("OnSizeChanged")(brokerHit, 250, 27)
	equal(brokerHit.font:GetLineHeight(), 27, "the hit area follows LibQTip's final row height")
	brokerRow:Show()
	brokerBothCatch:GetScript("OnEnter")(brokerBothCatch)
	check(brokerHover, "the broker preserves tooltip row hover")
	brokerBothCatch:GetScript("OnLeave")(brokerBothCatch)
	check(not brokerHover, "leaving the overlay clears hover")
	mouseFocus = brokerBothCatch
	local menuRow, menuFriend = test:GetMenuFriend({ bnetIDAccount = 76 }, true)
	check(menuRow == brokerRow and menuFriend == brokerFriend, "the broker native menu receives BFL's friend actions")
	equal(test:GetMenuFriend({ bnetIDAccount = 42 }, true), nil, "the broker never extends a different friend's menu")

	local onEvent = events:GetScript("OnEvent")
	alt = true
	onEvent(events, "MODIFIER_STATE_CHANGED")
	check(not brokerHit.shown, "Alt-click keeps the broker invite action")
	brokerClick("RightButton")
	equal(brokerClicks, 1, "a captured right-click invokes the broker once")
	alt, shift = false, true
	onEvent(events, "MODIFIER_STATE_CHANGED")
	check(not brokerHit.shown, "Shift-click keeps the broker chat insertion")
	shift = false
	canWhisper = false
	test:RefreshClickRouting()
	check(brokerCatch.shown and not brokerBothCatch.shown, "unavailable whispers still allow the broker's right-click")
	brokerClick("LeftButton")
	equal(brokerClicks, 2, "the unavailable left-click is returned to the broker for feedback")
	canWhisper = true
	combat = true
	onEvent(events, "PLAYER_REGEN_DISABLED")
	check(brokerHit.shown and brokerBothCatch.shown, "combat keeps both broker click paths")
	local beforeCombatBroker = nativeWhispers
	brokerClick("LeftButton")
	equal(nativeWhispers, beforeCombatBroker + 1, "the Friends Broker opens one native whisper in combat with Streamer Mode")
	mouseFocus = brokerBothCatch
	check(test:GetMenuFriend({ bnetIDAccount = 76 }, true) == brokerRow, "combat still resolves the broker recipient")
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(brokerHit.shown and brokerBothCatch.shown, "broker clicks stay active after combat")

	brokerRow.hooks.OnHide(brokerRow)
	check(not brokerHit.shown and not brokerCatch.shown, "a released broker row has no overlay for the next header")
	equal(test:GetMenuFriend({ bnetIDAccount = 76 }, true), nil, "recycled rows do not retain the previous friend")
	local wowBrokerFriend = { type = "wow", name = "Example-Realm", connected = true }
	test:UpdateBrokerRow(brokerRow, wowBrokerFriend)
	equal(brokerHit.font.args[1], wowBrokerFriend.name, "a reused broker row binds the WoW character's full name")
	check(test:GetMenuFriend({ name = "Example", surname = "Realm" }, false) == brokerRow,
		"the reused row extends the WoW character menu")
	brokerRow.hooks.OnHide(brokerRow)
	mouseFocus = catch

	local sendMessage = frame()
	local sendEnters, sendLeaves = 0, 0
	sendMessage:SetScript("OnEnter", function() sendEnters = sendEnters + 1 end)
	sendMessage:SetScript("OnLeave", function() sendLeaves = sendLeaves + 1 end)
	local selected = first
	function friends:UpdateSendMessageButton()
		test:UpdateSendMessage(self, sendMessage, selected)
	end
	friends:UpdateSendMessageButton()
	local sendHit, sendCatch = frames[#frames - 1], frames[#frames]
	local hideSendCatch = sendCatch.Hide
	function sendCatch:Hide()
		local wasShown = self:IsShown()
		hideSendCatch(self)
		if wasShown then self:GetScript("OnHide")(self) end
	end
	check(sendHit.shown and sendCatch.shown, "Send Message uses the native link in Streamer Mode")
	equal(sendHit.template, "InlineHyperlinkFrameTemplate", "Send Message uses Blizzard's template directly")
	equal(sendCatch.pass, "LeftButton", "Send Message passes only the left click to Blizzard")
	equal(sendHit.font.args[2], 42, "Send Message binds the selected Battle.net account")
	check(sendHit:GetScript("OnHyperlinkClick") == nativeClick, "Send Message uses the inherited hardware handler")
	equal(sendCatch.motion, true, "Send Message keeps mouse motion reaching the native link")
	equal(sendHit.motion, nil, "the native link is the last mouse layer")
	equal(sendCatch:GetScript("OnMouseUp"), nil, "Send Message installs no addon mouse-up handler")
	sendCatch:GetScript("OnEnter")(sendCatch)
	check(sendMessage.highlighted, "hovering the native click layer highlights Send Message")
	equal(sendEnters, 1, "the real button receives its hover handler")
	check(events.GLOBAL_MOUSE_DOWN and events.GLOBAL_MOUSE_UP, "Send Message observes hardware press and release")
	onEvent(events, "GLOBAL_MOUSE_DOWN", "LeftButton")
	equal(sendMessage.buttonState, nil, "a click focused elsewhere does not push Send Message")
	mouseFocus = sendHit
	onEvent(events, "GLOBAL_MOUSE_DOWN", "RightButton")
	equal(sendMessage.buttonState, nil, "right clicks do not push Send Message")
	onEvent(events, "GLOBAL_MOUSE_DOWN", "LeftButton")
	equal(sendMessage.buttonState, "PUSHED", "a left press shows the real button's pressed state")
	check(sendMessage.buttonStateLocked, "the pressed state is held until release")
	local whispersBeforeSendMessage = nativeWhispers
	if sendCatch.motion and sendCatch.pass == "LeftButton" then
		sendHit:GetScript("OnHyperlinkClick")(sendHit, nil, nil, "LeftButton")
	end
	equal(nativeWhispers, whispersBeforeSendMessage + 1, "the modeled left click reaches Blizzard while Send Message is highlighted")
	mouseFocus = catch
	onEvent(events, "GLOBAL_MOUSE_UP", "LeftButton")
	equal(sendMessage.buttonState, "NORMAL", "releasing outside resets the press state")
	mouseFocus = sendCatch
	onEvent(events, "GLOBAL_MOUSE_DOWN", "LeftButton")
	equal(sendMessage.buttonState, "PUSHED", "pressing the upper mouse layer also shows the animation")
	selected = wowBrokerFriend
	friends:UpdateSendMessageButton()
	equal(sendHit.font.args[1], selected.name, "changing selection immediately rebinds Send Message")
	check(sendMessage.highlighted, "rebinding a valid recipient preserves hover")
	sendCatch:GetScript("OnLeave")(sendCatch)
	check(not sendMessage.highlighted, "leaving the native click layer clears the highlight")
	equal(sendMessage.buttonState, "NORMAL", "leaving clears the press even before release")
	equal(sendLeaves, 1, "the real button receives its leave handler")
	sendCatch:GetScript("OnEnter")(sendCatch)
	onEvent(events, "GLOBAL_MOUSE_DOWN", "LeftButton")
	selected = { type = "bnet", accountName = "Example", bnetAccountID = 42, connected = false, friendLevel = 3 }
	friends:UpdateSendMessageButton()
	check(not sendHit.shown and not sendCatch.shown, "an offline Title friend cannot be whispered from Send Message")
	check(not sendMessage.highlighted, "hiding the click layer clears the highlight")
	equal(sendMessage.buttonState, "NORMAL", "hiding a pressed click layer releases its button")
	equal(sendLeaves, 2, "hiding forwards leave exactly once")
	selected.connected = true
	friends:UpdateSendMessageButton()
	check(sendHit.shown and sendCatch.shown, "an online Title friend can be whispered")
	chatLocked = true
	friends:UpdateSendMessageButton()
	check(sendHit.shown and sendCatch.shown, "Send Message keeps the native link during chat lockdown")
	chatLocked = false
	selected = first
	friends:UpdateSendMessageButton()
	combat = true
	onEvent(events, "PLAYER_REGEN_DISABLED")
	check(sendHit.shown and sendCatch.shown, "combat keeps the Send Message click target")
	local beforeCombatMessage = nativeWhispers
	sendHit.scripts.OnHyperlinkClick(sendHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeCombatMessage + 1, "Send Message opens the native whisper in combat with Streamer Mode")
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(sendHit.shown and sendCatch.shown, "Send Message remains active after combat")
	selected = nil
	friends:UpdateSendMessageButton()
	check(not sendHit.shown and not sendCatch.shown, "deselecting clears the previous Send Message recipient")

	local whoAction, control = "whisper", false
	env.IsControlKeyDown = function() return control end
	BFL:RegisterModule("WhoFrame", { GetSetting = function() return whoAction end })
	local whoRow = frame()
	whoRow:Show()
	whoRow.info = { fullName = "WhoOne-Realm" }
	local selections, whoMenus, doubleClicks = 0, 0, 0
	whoRow:SetScript("OnClick", function(_, button)
		if button == "LeftButton" then selections = selections + 1 else whoMenus = whoMenus + 1 end
	end)
	whoRow:SetScript("OnDoubleClick", function() doubleClicks = doubleClicks + 1 end)
	combat, streamer = true, true
	test:UpdateRow(friends, whoRow, whoRow.info, true)
	local whoHit, whoCatch, whoLeftCatch = table.unpack(frames, #frames - 2, #frames)
	equal(whoHit.template, "InlineHyperlinkFrameTemplate", "Who links use Blizzard's template directly")
	local function pressWho(button)
		local activeCatch = whoLeftCatch.shown and whoLeftCatch or whoCatch
		activeCatch.scripts.OnMouseDown(activeCatch, button)
		activeCatch.scripts.OnMouseUp(activeCatch, button)
	end
	equal(whoCatch.pass, nil, "Who catches the first left click and keeps the custom right-click menu")
	local beforeWho = nativeWhispers
	pressWho("LeftButton")
	equal(selections, 1, "the first Who click selects")
	equal(nativeWhispers, beforeWho, "selecting a Who result does not open chat")
	check(whoLeftCatch.shown and not whoCatch.shown, "the next Who left click goes to Blizzard in combat with Streamer Mode")
	equal(whoLeftCatch.pass, "LeftButton", "Who still owns right-click while waiting for the second click")
	equal(whoHit.font.args[1], "WhoOne-Realm", "Who targets the complete result name")
	whoHit.scripts.OnHyperlinkClick(whoHit, nil, nil, "LeftButton")
	whoHit.hooks.OnHyperlinkClick(whoHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeWho + 1, "the next click opens exactly one native whisper")
	check(whoCatch.shown and not whoLeftCatch.shown, "the next Who sequence starts with selection again")
	pressWho("RightButton")
	equal(whoMenus, 1, "Who right click still opens its own menu")
	control = true
	test:RefreshClickRouting()
	pressWho("LeftButton")
	check(not whoLeftCatch.shown, "Ctrl search does not arm Whisper")
	control = false
	whoAction = "invite"
	test:RefreshClickRouting()
	pressWho("LeftButton")
	whoCatch.scripts.OnDoubleClick(whoCatch, "LeftButton")
	equal(doubleClicks, 1, "the Invite double click reaches Who's existing handler")
	check(not whoLeftCatch.shown, "Invite keeps the left click on the row")
	whoAction = "whisper"
	test:RefreshClickRouting()
	pressWho("LeftButton")
	whoRow.info = { fullName = "WhoTwo-Realm" }
	test:UpdateRow(friends, whoRow, whoRow.info, true)
	check(whoCatch.shown and not whoLeftCatch.shown, "recycling a result cancels the old Who click sequence")
	equal(whoHit.font.args[1], "WhoTwo-Realm", "the recycled result targets its own name")
	chatLocked = true
	test:RefreshClickRouting()
	check(whoHit.shown, "Who keeps its native target during chat lockdown")
	chatLocked = false
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(whoHit.shown, "Who keeps the current target in Streamer Mode after combat")
	streamer = false

	combat, streamer = true, true
	test:UpdateBrokerRow(brokerRow, wowBrokerFriend, true)
	check(brokerLeftCatch.shown, "Guild Broker keeps its native whisper in combat with Streamer Mode")
	equal(brokerLeftCatch.pass, "LeftButton", "Guild Broker only passes its left click to the native link")
	check(not brokerLeftCatch.passLeft, "Guild Broker keeps right-click available to its guild menu")
	local beforeGuildBroker = nativeWhispers
	brokerHit.scripts.OnHyperlinkClick(brokerHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeGuildBroker + 1, "Guild Broker left click opens the native whisper in Streamer Mode")
	mouseFocus = brokerHit
	equal(test:GetMenuFriend({ name = "Example", surname = "Realm" }, false), nil, "a Guild Broker row is not a native friend-menu source")
	alt = true
	test:RefreshBrokerRouting()
	check(not brokerHit.shown, "Guild Broker keeps its Alt-click invite")
	alt = false
	shift = true
	test:RefreshBrokerRouting()
	check(not brokerHit.shown, "Guild Broker keeps its Shift-click name insertion")
	shift = false
	brokerRow.hooks.OnHide(brokerRow)
	check(not brokerHit.shown, "releasing a Guild Broker row removes the last native recipient")
	combat = false

	local menuButton, menu = frame(), { closes = 0 }
	menuButton.height = 0 -- Blizzard may run initializers before the final layout.
	menuButton:Show()
	menuButton:SetScript("OnEnter", function(button) button.highlighted = true end)
	menuButton:SetScript("OnLeave", function(button) button.highlighted = false end)
	function menu:Close() self.closes = self.closes + 1 end
	local menuElement
	local root = { CreateButton = function(_, label, callback)
		menuElement = { label = label, callback = callback }
		function menuElement:SetEnabled(enabled) self.enabled = enabled end
		function menuElement:AddInitializer(initializer) self.init = initializer end
		function menuElement:AddResetter(resetter) self.reset = resetter end
		return menuElement
	end }
	BFL.PopulateSimpleMenu(root, { { type = "whisper", text = "Whisper", whisperTarget = "GuildOne-Realm" } })
	equal(menuElement.label, "Whisper", "guild action registers a visible menu entry")
	menuElement.init(menuButton, menuElement, menu)
	local menuHit, menuCatch = frames[#frames - 1], frames[#frames]
	check(menuHit.shown and menuCatch.shown and menuCatch.motion, "Guild menu Whisper uses the native link in Streamer Mode")
	equal(menuCatch.pass, "LeftButton", "the menu hover layer passes left clicks through")
	menuCatch.scripts.OnEnter(menuCatch)
	check(menuButton.highlighted, "entering the Whisper hit area highlights the visible menu item")
	menuCatch.scripts.OnLeave(menuCatch)
	check(not menuButton.highlighted, "leaving the Whisper hit area clears the menu highlight")
	equal(menuHit.scripts.OnHyperlinkClick, nativeClick, "the menu link inherits the native handler")
	equal(menuHit.font.args[1], "GuildOne-Realm", "the menu link targets the guild character and realm")
	local beforeGuildMenu = nativeWhispers
	menuHit.scripts.OnHyperlinkClick(menuHit, nil, nil, "LeftButton")
	menuHit.hooks.OnHyperlinkClick(menuHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeGuildMenu + 1, "guild menu Whisper opens Blizzard chat")
	equal(menu.closes, 1, "the menu closes after the native action")
	menuElement.reset(menuButton)
	check(not menuHit.shown and not menuCatch.shown, "the released menu item has no stale click or hover area")
	menuHit.hooks.OnHyperlinkClick(menuHit, nil, nil, "LeftButton")
	equal(menu.closes, 1, "a released menu link cannot act on its old menu")
	test:AddCharacterWhisperMenuItem(root, "GuildTwo-Realm", "Whisper")
	menuElement.init(menuButton, menuElement, menu)
	equal(frames[#frames - 1], menuHit, "a pooled menu item reuses its native link frame")
	equal(frames[#frames], menuCatch, "a pooled menu item reuses its hover frame")
	equal(menuHit.font.args[1], "GuildTwo-Realm", "a pooled menu item uses the new recipient")
	chatLocked = true
	test:RefreshClickRouting()
	check(menuHit.shown and menuCatch.shown, "the menu keeps its native Whisper link during chat lockdown")
	canWhisper = false
	test:RefreshClickRouting()
	check(not menuHit.shown and not menuCatch.shown, "an age restriction still hides the menu Whisper link")
	canWhisper, chatLocked = true, false
	menuElement.reset(menuButton)
	combat, streamer = true, true
	test:AddCharacterWhisperMenuItem(root, "WhoMenu-Realm", "Whisper")
	menuElement.init(menuButton, menuElement, menu)
	check(menuHit.shown and menuCatch.shown, "Who menu Whisper works in combat with Streamer Mode")
	equal(menuHit.font.args[1], "WhoMenu-Realm", "Who menu Whisper binds the selected character")
	local beforeWhoMenu = nativeWhispers
	menuHit.scripts.OnHyperlinkClick(menuHit, nil, nil, "LeftButton")
	menuHit.hooks.OnHyperlinkClick(menuHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeWhoMenu + 1, "Who menu Whisper opens Blizzard chat once")
	menuElement.reset(menuButton)
	test:AddFriendWhisperMenuItem(root, first, false, "Whisper")
	menuElement.init(menuButton, menuElement, menu)
	check(menuHit.shown and menuCatch.shown, "an explicit BFL friend-menu whisper works in combat with Streamer Mode")
	equal(menuHit.font.args[2], first.bnetAccountID, "the fallback whisper still binds the actual Battle.net friend")
	menuElement.reset(menuButton)
	combat, streamer = false, false

	local function createGuildBroker(tooltip)
		local factory = execute("return function(tooltip)\nlocal GuildBroker = {}\n"
			.. between(read(repo, "Modules/GuildBroker.lua"), "function GuildBroker:OpenMemberContextMenu(", "-- ElvUI Tooltip Skin Helpers")
			.. "\nreturn GuildBroker end", "Guild Broker context menu handoff")
		return factory(tooltip)
	end
	local brokerTooltip = frame()
	brokerTooltip:Show()
	local guildBroker = createGuildBroker(brokerTooltip)
	local guildMenuOpened
	BFL:RegisterModule("GuildActions", { ShowMemberMenu = function(_, owner, member)
		check(brokerTooltip:IsShown(), "the broker remains available while constructing its menu")
		check(owner == env.UIParent and member == wowBrokerFriend, "the broker menu owns the intended recipient independently of its tooltip")
		return guildMenuOpened
	end })
	check(not guildBroker:OpenMemberContextMenu(wowBrokerFriend) and brokerTooltip:IsShown(), "a failed menu leaves the broker open")
	guildMenuOpened = true
	check(guildBroker:OpenMemberContextMenu(wowBrokerFriend) and not brokerTooltip:IsShown(), "a successful guild menu replaces the tooltip")

	test:ShowWhisperUnavailable()
	equal(messages[#messages], BFL.L.NATIVE_WHISPER_UNAVAILABLE, "missing links give visible whisper feedback")
	mouseFocus = catch

	for _, build in ipairs({ 120107, 50504, 11509, 20506 }) do
		BFL.TOCVersion, BFL.IsMainline = build, build == 120107
		check(test:IsSupported(), "the native route is capability-based for " .. build)
		friends:RenderDisplay()
		check(hit.shown and catch.shown, "the same click layers are attached for " .. build)
		check(test:GetMenuFriend({ bnetIDAccount = "42" }, true) == row, "the native friend identity resolves for " .. build)
	end
	BFL.IsForever = true
	local modifyMenu = env.Menu.ModifyMenu
	env.Menu.ModifyMenu = nil
	friends:RenderDisplay()
	check(not hit.shown, "a missing menu extension API gives clicks back to the BFL menu")
	env.Menu.ModifyMenu = modifyMenu
	local setItemRef = env.SetItemRef
	env.SetItemRef = nil
	check(not test:IsSupported(), "a missing link dispatcher disables the native route")
	env.SetItemRef = setItemRef
	hasNativeHandler = false
	local incompleteRow = frame()
	local countBefore = #frames
	test:UpdateRow(friends, incompleteRow, first)
	equal(#frames, countBefore + 1, "an incomplete hyperlink template cannot attach an input layer")
	check(not frames[#frames].shown, "an incomplete hyperlink template remains hidden")
	test:UpdateRow(friends, incompleteRow, first)
	equal(#frames, countBefore + 1, "incomplete templates are not recreated on each row refresh")
end

-- The native extension uses the existing Invite slot and keeps Whisper's responder.
do
	local actions = {
		BFL_AddSetNoteButton = "Note",
		BFL_AddSetCustomTitleFriendNameButton = "Title name",
		BFL_AddUpgradeTitleFriendButton = "BattleTag request",
		BFL_AddViewBNetFriendsButton = "View friends",
		BFL_AddFavoriteButton = "Favorite",
		BFL_AddRafSummonButton = "Summon",
		BFL_AddViewHousesButton = "View houses",
		BFL_AddIgnoreOrBlockButton = "Block",
		BFL_AddRemoveFriendButton = "Remove",
		BFL_AddReportButtons = "Report",
	}
	for fn, label in pairs(actions) do
		env[fn] = function(root) root:CreateButton(label) end
	end
	env.BFL_ReplaceCopyNameButton = function(_, root) root:CreateButton("Copy name") end
	env.AddGroupsToFriendMenu = function(_, root, context, verified)
		equal(verified.uid, context.uid, "feature actions receive the verified friend")
		root:CreateButton("BetterFriendlist")
	end
	env.BFL_FirstSafeText = function(...)
		for index = 1, select("#", ...) do
			local value = select(index, ...)
			if not BFL:IsSecret(value) and value and value ~= "" then return value end
		end
	end
	env.MenuUtil = {
		GetElementText = function(entry) return entry.text end,
		SetElementText = function(entry, value) entry.text = value end,
	}
	env.MenuResponse = { Open = "open" }
	env.PARTY_INVITE, env.REQUEST_INVITE = "Invite", "Request to Join"
	env.GetDisplayedInviteType = function(guid) return guid == "request-guid" and "REQUEST_INVITE" or "INVITE" end
	local calls, lastAccount, failure = {}, nil, nil
	env.FriendsFrame_InviteOrRequestToJoin = function(guid, id) calls[#calls + 1] = { guid, id } end
	env.UIErrorsFrame.AddExternalErrorMessage = function(_, reason) failure = reason end
	local allowed = true
	BFL.ValidateForeverInviteTarget = function() return allowed, allowed and nil or "Different ruleset" end
	local friend = { type = "bnet", uid = "bnet_Tag#1234", bnetAccountID = 42, index = 3, accountName = "Friend", connected = true }
	local matching = { text = "Match", playerGuid = "request-guid", gameAccountID = 5, isInvitable = true }
	local blocked = { text = "Mismatch", playerGuid = "invite-guid", gameAccountID = 6, isInvitable = false, restrictionText = "Different ruleset" }
	local entries = { blocked }
	local model = BFL:GetModule("FriendsList")
	function model:GetReadableInviteField(record, key) return record and record[key] end
	function model:GetFriendUID(record) return record.uid end
	function model:GetInviteAccountEntries() return entries end
	function model:SetLastInvitedAccountID(_, id) lastAccount = id end
	env.GetFriendsList = function() return model end

	local function menuElement(text, callback)
		local value = { text = text, callback = callback, enabled = true, children = {} }
		function value:CreateButton(label, handler)
			local entry = menuElement(label, handler)
			self.children[#self.children + 1] = entry
			return entry
		end
		function value:CreateDivider() end
		function value:QueueDivider() end
		function value:QueueTitle() end
		function value:CreateTitle(label) return self:CreateButton(label) end
		function value:SetResponder(handler) self.callback = handler end
		function value:SetEnabled(enabled) self.enabled = enabled end
		function value:SetTooltip(tooltip) self.tooltip = tooltip end
		function value:EnumerateElementDescriptions() return ipairs(self.children) end
		return value
	end
	local function count(root, label)
		local matches = 0
		for _, item in ipairs(root.children) do
			if item.text == label then matches = matches + 1 end
		end
		return matches
	end

	execute(read(repo, "Modules/MenuBridge.lua"), "Modules/MenuBridge.lua")
	local bridge = BFL:GetModule("MenuBridge")
	BFL.HasSecretValues = true
	bridge._testCompanionAddOnLoaded = true
	local nativeTag = "MENU_UNIT_BN_FRIEND"
	local function NativeAddon(_, root) root:CreateButton("Third-party action") end
	bridge:RegisterDynamicModifier(nativeTag, NativeAddon, "NativeAddon")
	local function provider(addonName, label)
		check(bridge:RegisterProvider({
			addonName = addonName, menuTypes = { "BN_FRIEND", "BN_FRIEND_OFFLINE" }, fallbackIfDynamicModifier = true,
			populate = function(_, root, context)
				equal(context.bnetIDAccount, 42, "bridge receives the readable friend identity")
				root:CreateButton(label)
			end,
		}), "bridge provider registers")
	end
	provider("NativeAddon", "Duplicate fallback")
	provider("ProviderOnly", "Explicit provider")
	local populate = execute(
		between(legacy, "local function BFL_GetDisplayedInviteTypeSafe(", "\n\t\t\t-- Multi-Game-Account:")
		.. between(legacy, "local function BFL_FindBNetFriendData(", "local function BFL_GetBNetAccountInfo(")
		.. between(legacy, "function BFL:OpenBetterFriendlistContextMenu(", "local function BFL_CreateFriendMenuContext(")
		.. between(legacy, "local function BFL_CreateFriendMenuContext(", "\n\t\t\tif Menu and Menu.ModifyMenu then")
		.. "\nreturn BFL_AddNativeFriendMenu", "native menu extension")

	local nativeWhisper = function() end
	local row = {}
	local function makeMenu(omitInvite)
		local menu = menuElement("root")
		local whisper = menu:CreateButton("Whisper", nativeWhisper)
		local invite = not omitInvite and menu:CreateButton("Invite", function() error("unguarded native invite") end)
		menu:CreateButton("Report")
		NativeAddon(row, menu)
		populate(menu, nativeTag, row, friend, true)
		check(whisper.callback == nativeWhisper, "Blizzard Whisper's responder stays intact")
		equal(count(menu, "Report"), 1, "existing standard action is not duplicated")
		equal(count(menu, "Note"), 1, "missing list-only action is restored")
		equal(count(menu, "BetterFriendlist"), 1, "BFL feature section appears once")
		equal(count(menu, "Third-party action"), 1, "captured modifier is not replayed in a native menu")
		equal(count(menu, "Duplicate fallback"), 0, "native registrations suppress the same addon's fallback")
		equal(count(menu, "Explicit provider"), 1, "provider-only actions work in the native menu")
		return menu, invite
	end
	local menu, invite = makeMenu()
	equal(count(menu, "Invite"), 1, "ruleset block uses the existing Invite slot")
	equal(invite.enabled, false, "mismatched ruleset disables the native action")
	check(type(invite.tooltip) == "function", "the disabled action carries a restriction tooltip")
	invite.callback()
	equal(#calls, 0, "even direct dispatch cannot send a mismatched invite")

	entries = { matching, blocked }
	menu, invite = makeMenu()
	equal(#invite.children, 2, "the native Invite slot becomes the account picker")
	check(invite.children[1].enabled and not invite.children[2].enabled, "only the matching account can be invited")
	allowed = false
	invite.children[1].callback()
	equal(#calls, 0, "a changed ruleset is rechecked at click time")
	equal(failure, "Different ruleset", "a newly blocked request shows the reason")
	allowed = true
	invite.children[1].callback()
	equal(calls[1][1], "request-guid", "the matching account uses Blizzard's invite/request dispatcher")
	equal(lastAccount, 5, "a successful request preserves the last-account preference")

	entries = { matching }
	menu = makeMenu(true)
	equal(count(menu, "Request to Join"), 1, "a missing native action is appended once with the right label")
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, { bnetIDAccount = 42 }, "BN_FRIEND")
	equal(count(menu, "Third-party action"), 1, "BFL-owned menus still replay captured registrations")
	for _, helper in ipairs({ "BFL_AddPopoutChatButton", "BFL_AddDeleteCommunityMessageButton" }) do
		env[helper] = function() end
	end
	env.BFL_BuildCopyNameHandler = function() return function() end end
	local fallback
	local originalCreateContextMenu = BFL.CreateContextMenu
	BFL.CreateContextMenu = function(owner, generate)
		fallback = menuElement("root")
		generate(owner, fallback)
	end
	BFL:OpenFriendMenuFallback(row, friend)
	equal(count(fallback, "Whisper"), 1, "the fallback restores Whisper")
	equal(count(fallback, "Note"), 1, "the fallback keeps friend list actions")
	equal(count(fallback, "BetterFriendlist"), 1, "the fallback keeps BFL's group section")
	equal(count(fallback, "Third-party action"), 1, "the fallback replays a captured Menu Bridge action once")
	equal(count(fallback, "Duplicate fallback"), 0, "the fallback avoids a duplicate provider action")
	local oldActive = BFL.StreamerMode.IsActive
	BFL.StreamerMode.IsActive = function() return true end
	local oldDB = BFL:GetModule("DB")
	BFL:RegisterModule("DB", { Get = function(_, key, default)
		if key == "streamerModeNameFormat" then return "nickname" end
		return default
	end, GetNickname = function() return "" end })
	friend.friendLevel = env.Enum.BattleNetFriendLevel.RealID
	friend.battleTag = "Masked#1234"
	BFL:OpenFriendMenuFallback(row, friend)
	equal(fallback.children[1].text, "Masked", "the fallback menu uses the short BattleTag when a Real ID friend has no nickname")
	friend.battleTag, friend.characterName = nil, "Character"
	BFL:OpenFriendMenuFallback(row, friend)
	equal(fallback.children[1].text, "Character", "the fallback menu uses the character when the tag is unavailable")
	friend.characterName = nil
	BFL:OpenFriendMenuFallback(row, friend)
	equal(fallback.children[1].text, BFL.L.UNKNOWN, "the fallback menu keeps Real ID private with no tag or character")
	BFL.modules.DB = oldDB
	BFL.StreamerMode.IsActive = oldActive
	BFL.CreateContextMenu = originalCreateContextMenu

	env._G = env
	local profileTarget, showProfile = nil, true
	env.TRP3_API = {
		configuration = { getValue = function(key) return key == "UnitPopups_ShowOpenProfile" and showProfile end },
		loc = { UNIT_POPUPS_OPEN_PROFILE = "Open RP profile" },
		slash = { openProfile = function(name) profileTarget = name end },
	}
	execute(read(repo, "Modules/Compat_TotalRP3.lua"), "Modules/Compat_TotalRP3.lua")
	BFL:GetModule("Compat_TotalRP3"):Initialize()
	local profileLabel, profileContext = "Open RP profile", { name = "Example-Realm" }
	bridge._testCompanionAddOnLoaded = false
	check(not bridge:IsEnabled(), "the capture bridge still requires the companion")
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, profileContext, "FRIEND", "MENU_UNIT_FRIEND")
	equal(count(menu, profileLabel), 1, "TRP3 works without the companion on the native menu")
	menu.children[#menu.children].callback()
	equal(profileTarget, "Example-Realm", "the standalone entry opens the correct profile")
	menu = menuElement("root")
	menu:CreateButton(profileLabel)
	bridge:PopulateMenu(row, menu, profileContext, "FRIEND", "MENU_UNIT_FRIEND")
	equal(count(menu, profileLabel), 1, "a native TRP3 action already on the menu is not duplicated")
	bridge:RegisterDynamicModifier("MENU_UNIT_FRIEND", function() error("must not replay") end, "totalRP3")
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, profileContext, "FRIEND", "MENU_UNIT_FRIEND")
	equal(count(menu, profileLabel), 0, "a native TRP3 registration that runs later suppresses the fallback")
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, profileContext, "FRIEND")
	equal(count(menu, profileLabel), 1, "an owned menu gets the fallback when captured callbacks are unavailable")
	showProfile = false
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, profileContext, "FRIEND")
	equal(count(menu, profileLabel), 0, "the standalone fallback still honors the TRP3 setting")

	bridge:RegisterDynamicModifier("MENU_UNIT_RECENT_ALLY", NativeAddon, "NativeAddon")
	menu = menuElement("root")
	bridge:PopulateMenu(row, menu, profileContext, "RECENT_ALLY")
	equal(count(menu, "Third-party action"), 0, "owned menus never replay callbacks without the companion")
	bridge._testCompanionAddOnLoaded = true
	bridge:PopulateMenu(row, menu, profileContext, "RECENT_ALLY")
	equal(count(menu, "Third-party action"), 1, "Recent Allies still uses the capture bridge with the companion")
end

local updateRow = between(read(repo, "Modules/FriendsList.lua"), "function FriendsList:UpdateFriendButton(", "function FriendsList:OnFriendsUIStyleChanged()")
check(updateRow:find("friendMenu:UpdateRow(self, button, friend)", 1, true), "native routing is installed by the shared friend row update")
io.write("[OK] Forever social actions smoke: " .. assertions .. " assertions, including native friend row routing\n")
