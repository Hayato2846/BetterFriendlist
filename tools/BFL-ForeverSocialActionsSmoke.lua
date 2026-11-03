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
local dialogShown = false
local inviteDialog = env.BattleNetInviteFrame
local closeHook, sendHook, nextPrompt
inviteDialog.IsShown = function() return dialogShown end
inviteDialog.HookScript = function(_, _, callback) closeHook = callback end
inviteDialog.SendButton = { HookScript = function(_, _, callback) sendHook = callback end }
inviteDialog.InviteeName = { GetText = function() return pendingName end }
env.C_Timer.After = function(_, callback) nextPrompt = callback end
local function CloseInvite(confirmed)
	if confirmed then pendingCallback() end
	dialogShown = false
	closeHook(inviteDialog)
	if confirmed then sendHook() end
	local callback = nextPrompt
	nextPrompt = nil
	return callback
end
local originalConfirm = env.BattleNetInviteFrame.ShowInviteConfirmation
env.BattleNetInviteFrame.ShowInviteConfirmation = function(...)
	dialogShown = true
	originalConfirm(...)
end
local lastPrompt = pendingName
before = #sentTitles
sync:PerformSync()
equal(pendingName, lastPrompt, "Title Friends background sync opens no dialog")
equal(#sentTitles, before, "Title Friends background sync sends no invitations")
check(sync:RestoreStoredFriend("Alliance", "Grace-Hopper"), "A database action opens Blizzard confirmation")
equal(pendingName, "Grace-Hopper", "Blizzard receives the full Forever name")
stored["Katherine-Johnson"] = {}
check(not sync:RestoreStoredFriend("Alliance", "Katherine-Johnson"), "A second click cannot replace a pending confirmation")
equal(pendingName, "Grace-Hopper", "The original confirmation keeps its target")
equal(#sentTitles, before, "Opening a confirmation never sends an invitation")
titleEnabled = secret
check(not sync:RestoreStoredFriend("Alliance", "Katherine-Johnson"), "An unreadable Title Friends flag prevents friend actions")
titleEnabled = true
CloseInvite(false)()
stored["Ada-Lovelace"] = {}
env.BNGetNumFriends = function() return 1 end
env.C_BattleNet.GetFriendAccountInfo = function()
	return { friendLevel = 3, gameAccountInfo = { characterName = "Katherine-Johnson" } }
end
stored["Alan-Turing"] = {}
local pending = sync:GetPendingTitleFriends()
equal(table.concat(pending, ","), "Alan-Turing,Grace-Hopper",
	"Only missing, non-deleted friends other than the current character are listed")
check(sync:StartTitleInvites(pending), "Add All opens the first native confirmation")
equal(pendingName, "Alan-Turing", "First candidate opens without sending")
equal(#sentTitles, before, "The queue opens dialogs without sending invitations")
local advance = CloseInvite(true)
equal(pendingName, "Alan-Turing", "The second dialog waits for the first click and hide handlers")
advance()
equal(pendingName, "Grace-Hopper", "The second candidate opens after the first dialog closes")
equal(#sentTitles, before + 1, "Only the native confirmation sent an invitation")
CloseInvite(false)()
equal(table.concat(sync:GetPendingTitleFriends(), ","), "Grace-Hopper",
	"A cancelled invite remains in the list while a confirmed request is suppressed for the session")
env.BNGetNumFriends, env.C_BattleNet.GetFriendAccountInfo = nil, nil
env.BattleNetInviteFrame.ShowInviteConfirmation = originalConfirm
env.BetterFriendlistDB, env.C_ChatInfo, env.C_Timer = nil, nil, nil

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
local replaceCopy = execute(between(legacy, "local function BFL_ReplaceCopyNameButton(", "\n\t\t\t-- Legacy BFL-owned UnitPopup wrapper") .. "\nreturn BFL_ReplaceCopyNameButton", "multi-account copy menu")
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
io.write("[OK] Forever social actions smoke: " .. assertions .. " assertions, including native Forever/Classic Add Friend and actual menu callbacks\n")
