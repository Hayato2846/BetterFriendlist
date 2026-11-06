-- Run with Lua 5.4: lua tools/BFL-SocialCompatibilitySmoke.lua <repo>
-- Exercises production helpers and real menu/name paths without a WoW client.
-- Secret-value sentinels test our guards, not Blizzard's secure execution model.
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

local BFL = { L = {}, modules = {} }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
local env = setmetatable({ BFL = BFL, SlashCmdList = {}, FULL_PLAYER_NAME = "%s-%s" }, { __index = _G })
local function execute(source, name)
	return assert(load(source, "@" .. name, "t", env))("BetterFriendlist", BFL)
end
execute(read("Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
execute(read("Utils/ClassUtils.lua"), "Utils/ClassUtils.lua")
env.WhoFrame = {}
execute(between(read("Modules/WhoFrame.lua"), "function WhoFrame:GetWhoClassFilters()", "function WhoFrame:GetWhoRaceFilters()"), "WHO class filters")
BFL.modules.WhoFrame = env.WhoFrame
local suite = execute(read("Modules/TestSuite.lua"), "Modules/TestSuite.lua")
local tests = {}
function suite:RegisterTest(_, name, test) tests[name] = test end
suite:RegisterForeverSocialCompatibilityTests()
local assertions = 0
local V = {}
function V:Assert(value, message)
	assertions = assertions + 1
	assert(value, message)
end
function V:AssertEqual(actual, expected, message)
	self:Assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
for _, name in ipairs({ "Forever_TitleBlockMetadataContracts", "Forever_WhoClassIDEnumeration",
	"Forever_RegionalDisplayNames", "Forever_SecretFrameStrata" }) do
	tests[name].action(V)
end

-- Execute the account-picker display builder, not a duplicated formatter.
env.FriendsList = {}
env.GetAccountClassFile = function() return "MAGE" end
env.RAID_CLASS_COLORS = { MAGE = { r = 0, g = 1, b = 1, colorStr = "ff00ffff", WrapTextInColorCode = function(_, name) return "|cff00ffff" .. name .. "|r" end } }
env.INVITE_RESTRICTION_NONE = 0
execute(between(read("Modules/FriendsList.lua"), "function FriendsList:IsReadableInviteRecord(", "local function GetInviteRestrictionTextSafe("), "account display and readability guards")
local account = { characterName = "Ada-Lovelace", realmName = "Realm", playerGuid = "Player-200-1",
	gameAccountID = 99, wowProjectID = 18, bflIsInvitable = true }
env.RegionalUniqueNamesEnabled = function() return true end
local display = env.FriendsList:BuildAccountDisplay(account)
V:AssertEqual(display.text, "|cff00ffffAda-Lovelace|r", "Regional picker retains class color and surname")
V:AssertEqual(display.realmName, "Realm", "Picker metadata retains the realm")
V:AssertEqual(display.playerGuid, account.playerGuid, "Display formatting never rewrites GUIDs")
V:AssertEqual(display.gameAccountID, 99, "Display formatting never rewrites account IDs")
V:Assert(display.raw == account and display.isInvitable, "Raw account and invitation capability are retained")
env.RegionalUniqueNamesEnabled = function() return false end
account.characterName = "Ada"
account.wowProjectID = 1
V:AssertEqual(env.FriendsList:BuildAccountDisplay(account).text, "|cff00ffffAda|r - Realm", "Traditional picker keeps realm label")

-- Load the complete QuickJoin module with mocked read-only APIs.
env.GetTime = function() return 0 end
BFL.IsSocialQueueSupported = function() return false end
BFL.IsWoWFriend = function() return false end
env.IsGuildMember = function() return false end
env.C_BattleNet = { GetAccountInfoByGUID = function() return nil end }
env.C_NameUtil = { ReplaceSurnameSeparatorWithLinkSeparator = function(name) return name:gsub("-", "~") end }
local playerName, playerRealm = "Ada-Lovelace", "Realm"
env.GetPlayerInfoByGUID = function() return nil, nil, nil, nil, nil, playerName, playerRealm, 60 end
local linkName, linkDisplay
env.GetPlayerLink = function(name, label) linkName, linkDisplay = name, label; return "link:" .. name end
execute(read("Modules/QuickJoin.lua"), "Modules/QuickJoin.lua")
local quickJoin = BFL.modules.QuickJoin
env.RegionalUniqueNamesEnabled = function() return true end
local name, _, _, link = env.BetterFriendlist_GetRelationshipInfo("Player-200-1")
V:AssertEqual(name, "Ada-Lovelace", "Regional QuickJoin name has no appended realm")
V:AssertEqual(linkName, "Ada~Lovelace", "Regional QuickJoin link converts only the surname separator")
V:AssertEqual(linkDisplay, "Ada-Lovelace", "Regional QuickJoin link keeps the visible surname")
V:AssertEqual(link, "link:Ada~Lovelace", "Regional QuickJoin retains a usable player link")
quickJoin.relationshipCache = {}
env.RegionalUniqueNamesEnabled = function() return false end
playerName = "Ada"
name = env.BetterFriendlist_GetRelationshipInfo("Player-200-1")
V:AssertEqual(name, "Ada-Realm", "Traditional QuickJoin name includes the realm")
V:AssertEqual(linkName, "Ada-Realm", "Traditional QuickJoin link keeps the realm separator")
quickJoin.relationshipCache = {}
playerName, playerRealm = nil, nil
name, _, _, link = env.BetterFriendlist_GetRelationshipInfo("Player-200-1")
V:AssertEqual(name, "", "Unresolved players have no invented name")
V:AssertEqual(link, nil, "Unresolved players do not generate malformed links")

-- Exercise the actual context menu through opening, clicking and confirming.
local currentAccount, failLookup
local blocks, popups = {}, 0
env.Enum = { BattleNetFriendLevel = { Title = 1 } }
env.C_BattleNet = {
	GetAccountInfoByID = function() if failLookup then error("unavailable") end; return currentAccount end,
	SetBlocked = function(id, blocked) blocks[#blocks + 1] = { id = id, blocked = blocked } end,
}
env.BFL_GetBNetAccountInfo = function() return currentAccount end
env.BFL_GetContextDisplayName = function() return "Friend" end
env.StaticPopupDialogs = {}
env.StaticPopup_Show = function() popups = popups + 1 end
local addBlock = execute(between(read("BetterFriendlist.lua"), "local function BFL_AddIgnoreOrBlockButton(", "local function BFL_AddDeleteCommunityMessageButton(") .. "\nreturn BFL_AddIgnoreOrBlockButton", "context block button")
local function menu()
	local root = { buttons = {} }
	function root:CreateButton(text, callback) self.buttons[#self.buttons + 1] = { text = text, callback = callback } end
	addBlock(root, { bnetIDAccount = 42 }, true)
	return root
end
currentAccount = { bnetAccountID = 42, friendLevel = 1 }
V:AssertEqual(#menu().buttons, 0, "Title friends have no Block entry")
currentAccount.friendLevel = nil
V:AssertEqual(#menu().buttons, 0, "Missing modern levels have no Block entry")
currentAccount.friendLevel = 2
local root = menu()
V:AssertEqual(#root.buttons, 1, "Normal friends retain the Block entry")
currentAccount.friendLevel = 1
root.buttons[1].callback()
V:AssertEqual(popups, 0, "Changing to Title while a menu is open prevents the confirmation")
currentAccount.friendLevel = 2
root.buttons[1].callback()
V:AssertEqual(popups, 1, "Eligible friends show the confirmation")
currentAccount.friendLevel = 1
env.StaticPopupDialogs.BFL_CONFIRM_BLOCK_BNET_FRIEND.OnAccept()
V:AssertEqual(#blocks, 0, "Changing to Title while confirmation is open prevents SetBlocked")
currentAccount.friendLevel = 2
env.StaticPopupDialogs.BFL_CONFIRM_BLOCK_BNET_FRIEND.OnAccept()
V:AssertEqual(blocks[1].id, 42, "Eligible confirmation blocks the intended account")
V:Assert(blocks[1].blocked, "Eligible confirmation requests a block")
currentAccount = nil
V:AssertEqual(#menu().buttons, 0, "Disappeared accounts fail closed")
failLookup = true
V:AssertEqual(#menu().buttons, 0, "Lookup errors fail closed")
failLookup = false
env.C_BattleNet.GetAccountInfoByID = nil
env.Enum = {}
currentAccount = { bnetAccountID = 42 }
V:AssertEqual(#menu().buttons, 1, "Legacy account data remains supported")

-- Request menus must use fresh request metadata, not a cached row level.
env.Enum = { BattleNetFriendLevel = { Title = 1 } }
local currentInvite = { inviteID = 42, friendLevel = 2 }
env.C_BattleNet.GetFriendInviteInfo = function() return currentInvite end
env.FriendsUI = {}
execute(between(read("Modules/FriendsUI.lua"), "function FriendsUI:OpenRequestDeclineMenu(", "local function InitializeScaledRequestMenuElement("), "request decline menu")
local requestItems
BFL.OpenSimpleContextMenu = function(_, _, items) requestItems = items end
local requestButton = { inviteID = 42, inviteIndex = 1, friendLevel = 2 }
env.FriendsUI:OpenRequestDeclineMenu(requestButton)
V:AssertEqual(#requestItems, 3, "Eligible request exposes Block Invites")
local blockRequest = requestItems[3].func
local previousBlocks = #blocks
currentInvite.friendLevel = 1
blockRequest()
V:AssertEqual(#blocks, previousBlocks, "Open request menu rechecks a changed Title level")
env.FriendsUI:OpenRequestDeclineMenu(requestButton)
V:AssertEqual(#requestItems, 2, "Fresh Title metadata overrides cached eligible row metadata")
currentInvite.friendLevel = nil
env.FriendsUI:OpenRequestDeclineMenu(requestButton)
V:AssertEqual(#requestItems, 2, "Missing modern request metadata cannot expose Block Invites")
currentInvite.friendLevel, currentInvite.inviteID = 2, 43
blockRequest()
V:AssertEqual(#blocks, previousBlocks, "Recycled request index cannot block a different sender")
env.FriendsUI:OpenRequestDeclineMenu(requestButton)
V:AssertEqual(#requestItems, 2, "Recycled request index cannot expose a block action")
currentInvite.inviteID = 42
blockRequest()
V:AssertEqual(blocks[#blocks].id, 42, "Eligible request blocks the intended sender")
currentInvite = nil
env.FriendsUI:OpenRequestDeclineMenu(requestButton)
V:AssertEqual(#requestItems, 2, "Disappeared requests cannot expose a block action")

-- The modern native-style dropdown also keeps the row's original sender ID.
env.GetInviteInfo = function() return currentInvite end
execute(between(read("Modules/FriendsUI.lua"), "local function InitializeScaledRequestMenuElement(", "function FriendsUI:InitializeRequestCard("), "native-style request dropdown")
local generateMenu
local dropdown = { inviteID = 42, inviteIndex = 1, friendLevel = 2 }
function dropdown:SetupMenu(generator) generateMenu = generator end
env.FriendsUI:SetupRequestDeclineButton(dropdown)
local function requestMenu()
	local root = { buttons = {} }
	function root:CreateButton(text, callback)
		local button = { text = text, callback = callback }
		self.buttons[#self.buttons + 1] = button
		return button
	end
	generateMenu(dropdown, root)
	return root
end
currentInvite = { inviteID = 43, friendLevel = 2 }
V:AssertEqual(#requestMenu().buttons, 2, "Native-style dropdown rejects a recycled sender ID")
currentInvite.inviteID, currentInvite.friendLevel = 42, 1
V:AssertEqual(#requestMenu().buttons, 2, "Native-style dropdown ignores cached normal row levels")
currentInvite = nil
V:AssertEqual(#requestMenu().buttons, 2, "Native-style dropdown rejects disappeared requests")
currentInvite = { inviteID = 42, friendLevel = 2, accountName = "Friend" }
root = requestMenu()
V:AssertEqual(#root.buttons, 3, "Native-style dropdown retains eligible Block Invites")
local previousPopups = popups
currentInvite.friendLevel = 1
root.buttons[3].callback()
V:AssertEqual(popups, previousPopups, "Native-style dropdown rechecks permission before confirming")
currentInvite.friendLevel = 2
local confirmedInviteID
env.StaticPopup_Show = function(_, _, _, inviteID) confirmedInviteID = inviteID end
root.buttons[3].callback()
V:AssertEqual(confirmedInviteID, 42, "Native-style dropdown confirms only the intended sender")
io.write("[OK] Social compatibility smoke: " .. assertions .. " assertions, including actual picker, QuickJoin and context-menu paths\n")
