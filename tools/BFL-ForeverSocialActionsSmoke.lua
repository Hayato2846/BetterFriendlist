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
local regional, connected, titleEnabled = true, true, true
env.RegionalUniqueNamesEnabled = function() return regional end
env.BNFeaturesEnabledAndConnected = function() return connected end
env.BNGetInfo = function() return nil, "MyTag#1234", nil, nil, nil, nil, true end
env.C_AddOns = { IsAddOnLoaded = function() return true end }
local sentTitles, sentAccounts, addedLegacy, errors = {}, {}, {}, {}
env.C_BattleNet = {
	AreTitleFriendsEnabled = function() return titleEnabled end,
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
env.AddFriendInfoFrame.InfoContainer = { RightTextContainer = option() }
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
