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
		function f:EnableMouse(value) self.mouse = value end
		function f:GetHeight() return self.height end
		function f:SetAllPoints(target) self.cover = target end
		function f:GetFrameLevel() return self.level end
		function f:SetFrameLevel(level) self.level = level end
		function f:LockHighlight() self.highlighted = true end
		function f:UnlockHighlight() self.highlighted = false end
		function f:IsEnabled() return true end
		function f:SetButtonState(state, lock) self.buttonState, self.buttonStateLocked = state, lock end
		function f:RegisterForClicks(button) self.click = button end
		function f:RegisterForDrag(button) self.drag = button end
		function f:RegisterEvent(event) self[event] = true end
		function f:SetPassThroughButtons(right, left)
			assert(not combat)
			self.pass, self.passLeft = right, left
		end
		function f:SetPropagateMouseMotion(enabled) assert(not combat); self.motion = enabled end
		function f:CreateFontString()
			local font = {}
			function font:SetJustifyH() end
			function font:SetJustifyV() end
			function font:SetWordWrap(value) self.wrap = value end
			function font:SetAlpha(value) self.alpha = value end
			function font:SetFont(_, size) self.size = size end
			function font:ClearAllPoints() end
			function font:SetPoint() end
			function font:SetFormattedText(format, ...)
				assert(self.size, "SetFormattedText: Font not set")
				self.format, self.args = format, { ... }
			end
			self.font = font
			return font
		end
		return f
	end
	env.CreateFrame = function(_, _, parent, template)
		local f = frame()
		f.parent = parent
		if template then
			equal(template, "InlineHyperlinkFrameTemplate", "the hit frame inherits Blizzard's template")
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
	equal(#frames, 3, "the first render attaches the native click layers")
	local events, hit, catch = table.unpack(frames)
	check(hit.shown and catch.shown, "offline multi-account rows use the same route")
	check(hit.mouse and catch.mouse, "both layers receive mouse input")
	check(hit.cover == row and catch.cover == row, "click layers cover the actual friend row")
	check(hit:GetScript("OnHyperlinkClick") == nativeClick, "BFL leaves Blizzard's hyperlink handler intact")
	equal(hit.pass, nil, "the native template keeps its mouse routing")
	equal(catch.pass, "RightButton", "only right-click passes through the upper layer")
	check(catch.motion and row.level < hit.level and hit.level < catch.level, "mouse motion passes through the upper layer")
	check(row.travelPassButton.level > catch.level, "the invite control keeps its own click target")
	equal(catch.click, "LeftButtonUp", "left click keeps BFL's ordinary release behavior")
	equal(hit.font.wrap, false, "native hyperlink uses one line across the row")
	equal(hit.font.size, row.height + 8, "native hyperlink line is taller than the row")
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
	equal(#frames, 3, "reused rows reuse both click layers")
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
	check(test:HandleUnavailableClick(), "a failed route suppresses the old BFL menu on supported clients")
	equal(messages[#messages], BFL.L.NATIVE_FRIEND_MENU_UNAVAILABLE, "a failed route has a short explanation")

	friend = first
	friends:RenderDisplay()
	combat = true
	events:GetScript("OnEvent")(events, "PLAYER_REGEN_DISABLED")
	check(not hit.shown and not catch.shown, "both layers are suspended as combat begins")
	equal(row.travelPassButton.level, 10, "suspension restores the invite control level")
	combat = false
	events:GetScript("OnEvent")(events, "PLAYER_REGEN_ENABLED")
	check(hit.shown and catch.shown, "native routing resumes as combat ends")
	for _, mode in ipairs({ "streamer", "chat" }) do
		streamer, chatLocked = mode == "streamer", mode == "chat"
		test:UpdateRow(friends, row, friend)
		check(not hit.shown and not catch.shown, "both layers are suspended in " .. mode)
	end
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
		if button == "RightButton" or catch.passLeft == button then
			hit:GetScript("OnHyperlinkClick")(hit, nil, nil, button)
			hit.hooks.OnHyperlinkClick(hit, nil, nil, button)
		else
			down(catch, button)
			up(catch, button)
		end
	end
	local canWhisper = true
	BFL.CanSendWhisper = function() return canWhisper end
	whisperMode = "single"
	test:RefreshClickRouting()
	equal(catch.passLeft, "LeftButton", "single-click mode passes the hardware click directly to Blizzard")
	click("LeftButton")
	equal(nativeWhispers, 1, "one native click opens one whisper")
	equal(nativeSelections, 1, "single click still updates the selection")
	hit:GetScript("OnDragStart")(hit, "LeftButton")
	hit:GetScript("OnDragStop")(hit, "LeftButton")
	equal(callbacks.OnDragStart, 2, "single-click mode preserves row dragging")
	equal(callbacks.OnDragStop, 2, "single-click mode preserves drag release")
	whisperMode = "double"
	test:RefreshClickRouting()
	local previousSelections = callbacks.OnClick
	click("LeftButton")
	equal(nativeWhispers, 1, "the first click selects without whispering")
	equal(callbacks.OnClick, previousSelections + 1, "the first click goes to BFL selection")
	equal(clickTimers[#clickTimers].seconds, 0.3, "the second click has a bounded window")
	catch:GetScript("OnDoubleClick")(catch, "LeftButton")
	equal(callbacks.OnDoubleClick, 1, "native double-click does not run BFL's old whisper callback")
	click("LeftButton")
	equal(nativeWhispers, 2, "the second hardware click opens one whisper")
	equal(catch.passLeft, nil, "native dispatch immediately disarms the double-click window")
	click("LeftButton")
	clickTimers[#clickTimers]:Fire()
	equal(catch.passLeft, nil, "a late second click starts another selection sequence")
	click("LeftButton")
	catch:GetScript("OnLeave")(catch)
	equal(catch.passLeft, nil, "leaving the row cancels the second click")
	click("LeftButton")
	click("RightButton")
	equal(catch.passLeft, nil, "a right click cancels the second click without changing native right-click")
	click("LeftButton")
	friend = second
	friends:RenderDisplay()
	equal(catch.passLeft, nil, "rebinding the row cancels the pending whisper for the previous friend")
	friend = first
	friends:RenderDisplay()
	whisperMode = "single"
	canWhisper = false
	test:RefreshClickRouting()
	equal(catch.passLeft, nil, "a chat restriction prevents the native left-click route")
	canWhisper = true
	whisperMode = nil
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
	test:UpdateBrokerRow(brokerRow, brokerFriend)
	local brokerHit, brokerCatch = frames[#frames - 1], frames[#frames]
	local brokerDown = brokerCatch:GetScript("OnMouseDown")
	local brokerUp = brokerCatch:GetScript("OnMouseUp")
	check(brokerHit.shown and brokerCatch.shown, "the broker uses the native hit area")
	check(brokerHit:GetScript("OnHyperlinkClick") == nativeClick, "the broker keeps Blizzard's hyperlink handler")
	equal(brokerHit.font.size, 9, "a fresh broker row can bind its link before final tooltip layout")
	equal(brokerHit.font.args[1], "Native recipient", "the broker uses the API recipient for the native link")
	equal(brokerHit.font.args[2], 76, "the broker binds the clicked account ID")
	equal(brokerCatch.pass, "RightButton", "the broker right click goes to the native friend menu")
	equal(brokerCatch.passLeft, "LeftButton", "broker left click is independent of the friends list click setting")
	local function brokerClick(button)
		if brokerCatch.shown and (brokerCatch.pass == button or brokerCatch.passLeft == button) then
			brokerHit:GetScript("OnHyperlinkClick")(brokerHit, nil, nil, button)
		else
			brokerDown(brokerCatch, button)
			brokerUp(brokerCatch, button)
		end
	end
	local previousNativeMenus = nativeMenus
	brokerClick("LeftButton")
	brokerClick("RightButton")
	equal(nativeWhispers, 3, "the broker's native left click opens one whisper")
	equal(nativeMenus, previousNativeMenus + 1, "the broker's native right click opens one menu")
	equal(brokerClicks, 0, "native dispatch does not also invoke a broker action")
	brokerCatch:GetScript("OnSizeChanged")(brokerCatch, 250, 27)
	equal(brokerHit.font.size, 35, "the hit area follows LibQTip's final row height")
	brokerRow:Show()
	brokerCatch:GetScript("OnEnter")(brokerCatch)
	check(brokerHover, "the broker preserves tooltip row hover")
	brokerCatch:GetScript("OnLeave")(brokerCatch)
	check(not brokerHover, "leaving the overlay clears hover")
	mouseFocus = brokerCatch
	local menuRow, menuFriend = test:GetMenuFriend({ bnetIDAccount = 76 }, true)
	check(menuRow == brokerRow and menuFriend == brokerFriend, "the broker native menu receives BFL's friend actions")
	equal(test:GetMenuFriend({ bnetIDAccount = 42 }, true), nil, "the broker never extends a different friend's menu")

	local onEvent = events:GetScript("OnEvent")
	alt = true
	onEvent(events, "MODIFIER_STATE_CHANGED")
	equal(brokerCatch.pass, nil, "Alt-click keeps the broker invite action")
	equal(brokerCatch.passLeft, nil, "Alt-left also stays with the broker")
	brokerClick("RightButton")
	equal(brokerClicks, 1, "a captured right-click invokes the broker once")
	alt, shift = false, true
	onEvent(events, "MODIFIER_STATE_CHANGED")
	equal(brokerCatch.passLeft, nil, "Shift-click keeps the broker chat insertion")
	shift = false
	canWhisper = false
	test:RefreshClickRouting()
	equal(brokerCatch.pass, "RightButton", "chat restrictions preserve native right-click for other friend actions")
	equal(brokerCatch.passLeft, nil, "chat restrictions suppress the broker's native whisper")
	brokerClick("LeftButton")
	equal(brokerClicks, 2, "the unavailable left-click is returned to the broker for feedback")
	canWhisper = true
	combat = true
	onEvent(events, "PLAYER_REGEN_DISABLED")
	check(not brokerHit.shown and not brokerCatch.shown, "combat gives the click back to the original broker row")
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(brokerHit.shown and brokerCatch.shown, "broker clicks recover after combat")

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
	check(sendHit.shown and sendCatch.shown, "Send Message uses the native link over the legacy button")
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
	check(not sendHit.shown and not sendCatch.shown, "Send Message respects chat lockdown")
	chatLocked = false
	selected = first
	friends:UpdateSendMessageButton()
	combat = true
	onEvent(events, "PLAYER_REGEN_DISABLED")
	check(not sendHit.shown and not sendCatch.shown, "combat removes the Send Message click target")
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(sendHit.shown and sendCatch.shown, "Send Message recovers after combat")
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
	test:UpdateRow(friends, whoRow, whoRow.info, true)
	local whoHit, whoCatch = frames[#frames - 1], frames[#frames]
	local function pressWho(button)
		whoCatch.scripts.OnMouseDown(whoCatch, button)
		whoCatch.scripts.OnMouseUp(whoCatch, button)
	end
	equal(whoCatch.pass, nil, "Who catches the first left click and keeps the custom right-click menu")
	local beforeWho = nativeWhispers
	pressWho("LeftButton")
	equal(selections, 1, "the first Who click selects")
	equal(nativeWhispers, beforeWho, "selecting a Who result does not open chat")
	equal(whoCatch.pass, "LeftButton", "the next left click goes to Blizzard")
	equal(whoHit.font.args[1], "WhoOne-Realm", "Who targets the complete result name")
	whoHit.scripts.OnHyperlinkClick(whoHit, nil, nil, "LeftButton")
	whoHit.hooks.OnHyperlinkClick(whoHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeWho + 1, "the next click opens exactly one native whisper")
	equal(whoCatch.pass, nil, "the next Who sequence starts with selection again")
	pressWho("RightButton")
	equal(whoMenus, 1, "Who right click still opens its own menu")
	control = true
	test:RefreshClickRouting()
	pressWho("LeftButton")
	equal(whoCatch.pass, nil, "Ctrl search does not arm Whisper")
	control = false
	whoAction = "invite"
	test:RefreshClickRouting()
	pressWho("LeftButton")
	whoCatch.scripts.OnDoubleClick(whoCatch, "LeftButton")
	equal(doubleClicks, 1, "the Invite double click reaches Who's existing handler")
	equal(whoCatch.pass, nil, "Invite keeps the left click on the row")
	whoAction = "whisper"
	test:RefreshClickRouting()
	pressWho("LeftButton")
	whoRow.info = { fullName = "WhoTwo-Realm" }
	test:UpdateRow(friends, whoRow, whoRow.info, true)
	equal(whoCatch.pass, nil, "recycling a result cancels the old Who click sequence")
	equal(whoHit.font.args[1], "WhoTwo-Realm", "the recycled result targets its own name")
	combat = true
	onEvent(events, "PLAYER_REGEN_DISABLED")
	check(not whoHit.shown, "Who drops its native target during combat")
	combat = false
	onEvent(events, "PLAYER_REGEN_ENABLED")
	check(whoHit.shown, "Who restores the current target after combat without a new search")

	test:UpdateBrokerRow(brokerRow, wowBrokerFriend, true)
	equal(brokerCatch.pass, "LeftButton", "Guild Broker only passes its left click to the native link")
	check(not brokerCatch.passLeft, "Guild Broker keeps right-click available to its guild menu")
	local beforeGuildBroker = nativeWhispers
	brokerHit.scripts.OnHyperlinkClick(brokerHit, nil, nil, "LeftButton")
	equal(nativeWhispers, beforeGuildBroker + 1, "Guild Broker left click opens the native whisper")
	mouseFocus = brokerHit
	equal(test:GetMenuFriend({ name = "Example", surname = "Realm" }, false), nil, "a Guild Broker row is not a native friend-menu source")
	alt = true
	test:RefreshBrokerRouting()
	equal(brokerCatch.pass, nil, "Guild Broker keeps its Alt-click invite")
	alt = false
	shift = true
	test:RefreshBrokerRouting()
	equal(brokerCatch.pass, nil, "Guild Broker keeps its Shift-click name insertion")
	shift = false
	brokerRow.hooks.OnHide(brokerRow)
	check(not brokerHit.shown, "releasing a Guild Broker row removes the last native recipient")

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
	check(menuHit.shown and menuCatch.shown and menuCatch.motion, "the menu has separate native click and mouse motion layers")
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
	check(not menuHit.shown and not menuCatch.shown, "both menu layers are removed during chat lockdown")
	chatLocked = false
	menuElement.reset(menuButton)

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
	check(not test:HandleUnavailableClick(), "a missing menu extension API preserves the compatibility path")
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
	env.BFL_FirstSafeText = function(name) return name end
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
		.. between(legacy, "local function BFL_AddNativeFriendMenu(", "\n\t\t\tif Menu and Menu.ModifyMenu then")
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
