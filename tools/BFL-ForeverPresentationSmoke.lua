-- Lua 5.4: lua tools/BFL-ForeverPresentationSmoke.lua <repo> <Forever UI source> [stateless UI source]
-- Runs production changelog/name/tooltip code and actual native invite helpers.
-- Widgets and C APIs are mocked; live rendering and server grouping need in-game QA.
local repo = assert(arg[1], "repository root is required")
local forever = assert(arg[2], "Forever UI source root is required")
local statelessSource = arg[3] or forever
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
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local version = assert(read(repo, "BetterFriendlist.toc"):match("## Version:%s*([^%s]+)"))
local bridgeVersion = read(repo, "!BetterFriendlist_MenuBridge/!BetterFriendlist_MenuBridge.toc"):match("## Version:%s*([^%s]+)")
equal(bridgeVersion, version, "Both addon manifests use the same version")
local BFL = { L = {}, VERSION = version, modules = {}, IsRetail = true, IsForever = true, IsClassic = false }
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale() end
local protectedAccount = setmetatable({}, { __index = function() error("Protected account labels must not be inspected") end })
function BFL:IsSecret(value) return value == protectedAccount end
function BFL:GetSafeAccountName(name, battleTag) return name or battleTag or "Unknown" end
local env = setmetatable({ BFL = BFL, BFL_LOCALE_ENUS = BFL.L, L = BFL.L,
	Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 },
		GameMode = { Standard = 0, Plunderstorm = 1, WoWHack = 2 } },
	StaticPopupDialogs = {}, SlashCmdList = {}, BNET_CLIENT_WOW = "WoW",
	WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
	TRAVEL_PASS_INVITE = "Invite", TRAVEL_PASS_INVITE_CROSS_FACTION = "Cross-faction invite",
	SOCIAL_UI_FRIENDS_LIST_PARTY_BUTTON_OFFLINE_TOOLTIP = "Player Offline",
	SUGGEST_INVITE = "Suggest", REQUEST_INVITE = "Request", SUGGEST_INVITE_CROSS_FACTION = "Cross suggest",
	REQUEST_INVITE_CROSS_FACTION = "Cross request", CROSS_FACTION_INVITE_TOOLTIP = "Cross-faction content: %s",
	FACTION_ALLIANCE = "Alliance", FACTION_HORDE = "Horde", FACTION_NEUTRAL = "Neutral",
	RED_FONT_COLOR = { r = 1, g = 0, b = 0 }, HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 },
	GRAY_FONT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }, FONT_COLOR_CODE_CLOSE = "|r",
	RAID_CLASS_COLORS = { WARRIOR = { r = 199/255, g = 156/255, b = 110/255, colorStr = "ffc79c6e" }, MAGE = { r = 105/255, g = 204/255, b = 240/255, colorStr = "ff69ccf0" }, ROGUE = { r = 1, g = 245/255, b = 105/255, colorStr = "fffff569" } },
}, { __index = _G })
local function execute(content, label)
	return assert(load(content, "@" .. label, "t", env))("BetterFriendlist", BFL)
end
execute(read(repo, "Locales/enUS.lua"), "Locales/enUS.lua")
execute(read(repo, "Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")

-- Both settings views share the parsed entries and read state.
local changelogSource = read(repo, "Modules/Changelog.lua")
local parseChangelog = execute(changelogSource .. "\nreturn ParseChangelog", "Modules/Changelog.lua")
local changelog = BFL:GetModule("Changelog")
local entries = changelog:GetEntries()
equal(entries[1].version, version, "The installed entry matches both manifests, including drafts")
local published = {}
for _, entry in ipairs(entries) do if not entry.isDraft then published[entry.version] = entry end end
local released, previous = assert(published["3.0.0"]), assert(published["2.9.2"])
equal(released.date, "2026-11-03", "The new release date is shown")
check(not released.isDraft and #released.blocks > 0, "Released notes keep their content and release state")
equal(previous.version, "2.9.2", "The previous release is preserved")
equal(previous.date, "2026-10-11", "The previous release date is preserved")
local settingsEntries = changelog:GetSettingsCenterEntries(2)
equal(settingsEntries[1].title, "Version " .. version, "Settings Center shows the installed version")
equal(settingsEntries[1].rightText, entries[1].date, "Settings Center preserves the matching draft or release date")
check(not settingsEntries[1].defaultExpanded and not settingsEntries[2].defaultExpanded, "All entries start collapsed")
equal(#changelog:GetSettingsCenterEntries(0), 0, "The entry limit is honored")
equal(#changelog:GetSettingsCenterEntries(1), 1, "A one-entry limit includes the current release")
local fixture = "## [DRAFT]\n- New draft\n## [2.9.1] - 2026-09-27\n- Released note\n## [Unreleased]\n- Future note"
local parsed = parseChangelog(fixture, "2.9.2")
equal(#parsed, 3, "Undated headings do not leak content into the previous release")
equal(parsed[1].version, "2.9.2", "Future draft headings still use the installed version")
check(parsed[1].isDraft and parsed[1].date == BFL.L.SETTINGS_CENTER_CHANGELOG_DRAFT, "Draft parsing remains supported after release promotion")
equal(#parsed[2].blocks, 1, "Release content excludes the following draft")
equal(parsed[3].version, "2.9.2", "Unreleased headings follow the same installed-version rule")
local markdownRelease = between(read(repo, "CHANGELOG.md"), "## [2.9.2]", "## [2.9.1]")
equal(between(changelogSource, "## [2.9.2]", "## [2.9.1]"), markdownRelease, "Embedded release notes match CHANGELOG.md")

local saved = { lastChangelogVersion = entries[3].version }
BFL.modules.DB = {
	Get = function(_, key, default)
		if saved[key] ~= nil then return saved[key] end
		return default
	end,
	Set = function(_, key, value) saved[key] = value end,
}
local newest, older = entries[1].version, entries[2].version
local unread = changelog:GetUnreadVersions()
check(unread[newest] and unread[older] and not unread[entries[3].version], "Legacy read marker preserves older releases")
changelog:MarkVersionRead(newest)
check(changelog:HasUnreadVersions() and changelog:GetUnreadVersions()[older], "Reading the newest leaves the older badge")
changelog:MarkVersionRead(older)
check(not changelog:HasUnreadVersions(), "Reading all pending releases clears the settings badge")
saved.changelogReadState = nil
saved.lastChangelogVersion = "0.0.0"
unread = changelog:GetUnreadVersions()
check(unread[newest] and not unread[older], "First visit only badges the latest release")
changelog:MarkVersionRead(newest)
local nextRelease = { { version = "99.0.0" }, entries[1], entries[2] }
unread = changelog:GetUnreadVersions(nextRelease)
check(unread["99.0.0"] and not unread[newest], "A later update keeps individually read releases read")
saved.changelogReadState = { through = "3.0.3-dev", versions = {} }
unread = changelog:GetUnreadVersions({ { version = "3.0.3" }, { version = "3.0.2" } })
check(unread["3.0.3"] and not unread["3.0.2"], "A release superseding a draft can be marked unread")
BFL.modules.DB = nil

-- Name formatting retains character styling, aliases, privacy and sort behavior.
local nickname, regional, streamer = "", true, false
env.RegionalUniqueNamesEnabled = function() return regional end
BFL.StreamerMode = { IsActive = function() return streamer end }
env.GetDB = function() return { GetNickname = function() return nickname end } end
execute(read(repo, "Utils/ClassUtils.lua"), "Utils/ClassUtils.lua")
env.GetClassFileForFriend = function(value) return BFL.ClassUtils:GetClassFileForFriend(value) end
env.GetRealmName = function() return "Home" end
env.GetNormalizedRealmName = env.GetRealmName
env.strsplit = function(_, value) return value:match("^([^%-]+)%-?(.*)$") end
env.FriendsList = { settingsCache = { nameFormatString = "%name% (%character%)", colorClassNames = false } }
local friendSource = read(repo, "Modules/FriendsList.lua")
execute(between(friendSource, "function FriendsList:GetDisplayLocation(", "local function GetGroups()")
	.. between(friendSource, "local function ReplaceTokenCaseInsensitive(", "-- Info Line Formatting (Phase 22)")
	.. between(friendSource, "function FriendsList:GetDisplayName(", "-- Update \"Send Message\" button state"), "FriendsList display name")
local list = env.FriendsList
local friend = { uid = "title-42", type = "bnet", friendLevel = 3, accountName = "Ada Lovelace",
	characterName = "Ada Lovelace", className = "Warrior", realmName = "Home" }
equal(list:GetDisplayName(friend), "Ada Lovelace", "Title names are not repeated")
equal(list:GetDisplayName(friend), "Ada Lovelace", "The cached title name remains correct")
friend.accountName = "|Kq42|k"
equal(list:GetDisplayName(friend), "Ada Lovelace", "An encoded account label cannot repeat the Title character")
friend.accountName = protectedAccount
equal(list:GetDisplayName(friend), "Ada Lovelace", "A protected account label is not inspected or formatted for Title display")
friend.accountName = nil
equal(list:GetDisplayName(friend), "Ada Lovelace", "A missing Title account label still shows the character")
friend.accountName = "Ada Lovelace"
list.settingsCache.colorClassNames = true
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "The remaining character keeps class coloring")
list.settingsCache.colorClassNames = false
list.settingsCache.nameFormatString = "%NaMe% (%CHARACTER%)"
equal(list:GetDisplayName(friend), "Ada Lovelace", "Tokens remain case insensitive")
list.settingsCache.nameFormatString = "%character% (%name%)"
equal(list:GetDisplayName(friend), "Ada Lovelace", "The reversed redundant pair also collapses")
list.settingsCache.nameFormatString = "%name% (%character%)"
friend.characterName = "Ada-Lovelace"
equal(list:GetDisplayName(friend), "Ada-Lovelace", "Regional space/hyphen labels match without changing the API name")
regional = false
list.displayNameCache = nil
equal(list:GetDisplayName(friend), "Ada-Lovelace", "Title display does not depend on raw account-name equality or regional naming")
regional, friend.characterName = true, "Ada Lovelace"
friend.titleCustomName = "My mage"
equal(list:GetDisplayName(friend), "My mage (Ada Lovelace)", "A distinct Title custom alias is retained")
friend.accountName = "|Kq42|k"
equal(list:GetDisplayName(friend), "My mage (Ada Lovelace)", "A distinct alias survives an encoded account label")
friend.titleCustomName = "Ada Lovelace"
equal(list:GetDisplayName(friend), "Ada Lovelace", "An alias equal to the character is not repeated")
friend.titleCustomName = "Ada-Lovelace"
equal(list:GetDisplayName(friend), "Ada Lovelace", "Regional spelling of the same alias does not repeat the name")
friend.titleCustomName = nil
list.settingsCache.nameFormatString = "%name%"
equal(list:GetDisplayName(friend), "Ada Lovelace", "Name-only Title layouts also use the character rather than the account label")
friend.connected = true
list.settingsCache.colorClassNames = true
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "Online Title names use class color in a name-only layout")
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "The cached name-only Title color is retained")
list.settingsCache.nameFormatString = "  %NaMe%  "
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "Name-only detection is case insensitive and ignores surrounding whitespace")
list.settingsCache.showRealmName, list.settingsCache.showFactionIcons = true, true
friend.realmName, friend.factionName = "OtherRealm", "Alliance"
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "Name-only class color does not introduce realm names or faction icons")
friend.connected = false
equal(list:GetDisplayName(friend), "Ada Lovelace", "Offline transition clears a cached Title class color even if character/class metadata remains")
friend.connected, friend.className, friend.classID = true, nil, 1
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "The production class resolver also supports class-ID-only Title metadata")
friend.classID = 8
equal(list:GetDisplayName(friend), "|cff69ccf0Ada Lovelace|r", "Changed class IDs invalidate the color cache")
friend.classID, friend.className = nil, "Rogue"
equal(list:GetDisplayName(friend), "|cfffff569Ada Lovelace|r", "Changed class names invalidate the color cache")
friend.classFilename = "MAGE"
equal(list:GetDisplayName(friend), "|cff69ccf0Ada Lovelace|r", "Changed class filename takes precedence and invalidates the cache")
friend.classFilename, friend.className = nil, nil
equal(list:GetDisplayName(friend), "Ada Lovelace", "Missing class data does not invent a color")
friend.classID = protectedAccount
equal(list:GetDisplayName(friend), "Ada Lovelace", "Restricted class IDs are not inspected or compared for Title coloring")
equal(list:GetDisplayName(friend), "Ada Lovelace", "Restricted class metadata is also safe on subsequent formatting calls")
friend.classID = nil
friend.className, friend.titleCustomName = "Warrior", "My mage"
equal(list:GetDisplayName(friend), "|cffc79c6eMy mage|r", "Name-only Title aliases keep their text and use the known character class")
friend.titleCustomName = nil
friend.battleTag = "SafeTag#1234"
equal(list:GetDisplayName(friend, true), "SafeTag", "Sorting does not receive display color markup")
streamer = true
equal(list:GetDisplayName(friend), "SafeTag", "Streamer name-only output remains unchanged")
streamer = false
friend.friendLevel, friend.accountName = 1, "Account label"
equal(list:GetDisplayName(friend), "Account label", "Ordinary BattleTag account labels are not class-colored")
friend.friendLevel, friend.accountName, friend.battleTag = 3, "Ada Lovelace", nil
list.settingsCache.colorClassNames = false
equal(list:GetDisplayName(friend), "Ada Lovelace", "Disabled class colors remain disabled in name-only layouts")
list.settingsCache.colorClassNames = nil
equal(list:GetDisplayName(friend), "|cffc79c6eAda Lovelace|r", "The existing default enables class coloring")
list.settingsCache.colorClassNames, list.settingsCache.nameFormatString = false, "%name%"
list.settingsCache.showRealmName, list.settingsCache.showFactionIcons = false, false
friend.realmName, friend.factionName = "Home", nil
nickname = "Raid buddy"
list.settingsCache.nameFormatString = "%nickname% (%character%)"
equal(list:GetDisplayName(friend), "Raid buddy (Ada Lovelace)", "An explicit BFL nickname layout is preserved")
nickname = ""
list.settingsCache.nameFormatString = "%name% (%character%)"
friend.accountName = "Ada Lovelace"
friend.titleCustomName = nil
friend.friendLevel = 1
equal(list:GetDisplayName(friend), "Ada Lovelace (Ada Lovelace)", "BattleTag/Real ID formats are not changed by the Title fix")
friend.friendLevel = 3
equal(list:GetDisplayName(friend), "Ada Lovelace", "Friend-level changes invalidate the cached format")
friend.characterName = nil
equal(list:GetDisplayName(friend), "Ada Lovelace", "Offline Title names remain available")
friend.characterName, friend.battleTag = "Ada Lovelace", "SafeTag#1234"
equal(list:GetDisplayName(friend, true), "SafeTag (Ada Lovelace)", "Sorting retains its safe BattleTag behavior")
streamer = true
equal(list:GetDisplayName(friend), "SafeTag (Ada Lovelace)", "Streamer mode does not expose the account name")
streamer = false
friend.note = "Raid lead"
list.settingsCache.nameFormatString = "%name% (%character%) - %note%"
equal(list:GetDisplayName(friend), "Ada Lovelace - Raid lead", "Other requested name-line tokens are preserved")

-- Execute Blizzard's real stateless helpers (not a reimplementation).
for _, key in ipairs({ "NOT_LEADER", "NOT_ALLIED", "DIFFERENT_REALM", "NO_INFO", "NOT_WOW", "WRONG_PROJECT",
	"WRONG_PROJECT_MAINLINE_OVERRIDE", "WRONG_PROJECT_CLASSIC_OVERRIDE", "MOBILE", "DIFFERENT_REGION", "QUEST_SESSION", "GAME_MODE" }) do
	env["ERR_TRAVEL_PASS_" .. key] = key
end
local crossFaction, questSession, activeMode, playerFaction = false, false, 0, "Alliance"
env.C_Glue = { IsOnGlueScreen = function() return false end }
env.C_GameRules = { IsCharacterlessLoginActive = function() return false end, GetActiveGameMode = function() return activeMode end }
env.C_PartyInfo = { CanFormCrossFactionParties = function() return crossFaction end }
env.C_QuestSession = { Exists = function() return questSession end }
env.UnitFactionGroup = function() return playerFaction end
env.GetRealmID = function() return 100 end
env.GetDisplayedInviteType = function() return "INVITE" end
env.max = math.max
env.EnumUtil = { MakeEnum = function(...)
	local result = {}; for index, name in ipairs({ ... }) do result[name] = index - 1 end; return result
end }
env.table = setmetatable({ count = function(value) local count = 0; for _ in pairs(value) do count = count + 1 end; return count end }, { __index = table })
env.assertsafe = assert
local function account(overrides)
	local value = { clientProgram = "WoW", wowProjectID = 18, factionName = "Alliance", realmID = 200, gameAccountID = 99,
		isInCurrentRegion = true, classID = 1, playerGuid = "Player-42", isOnline = true }
	for key, data in pairs(overrides or {}) do value[key] = data end
	return value
end
local accounts = { account() }
env.C_BattleNet = { GetFriendNumGameAccounts = function() return #accounts end,
	GetFriendGameAccountInfo = function(_, index) return accounts[index] end }
execute(read(statelessSource, "Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsListConstants.lua"), "Blizzard invite constants")
execute(read(statelessSource, "Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsListUtil.lua"), "Blizzard stateless invite helpers")
local nativeUtil = env.FriendsListUtil

-- Compare the native hidden-frame helpers with BFL's stateless replacement.
local nativeFrame = read(forever, "Interface/AddOns/Blizzard_FriendsFrame/Camelot/FriendsFrame.lua")
execute(between(nativeFrame, "local INVITE_RESTRICTION_NO_GAME_ACCOUNTS =", "local FriendListEntries =")
	.. "\nlocal playerFactionGroup, playerRealmID\n"
	.. "local function CanInviteByGameMode() return true end\n"
	.. between(nativeFrame, "function FriendsFrame_GetDisplayedInviteTypeAndGuid(", "local inviteTypeToButtonText ="), "Blizzard cached frame helpers")
equal(env.FriendsFrame_GetDisplayedInviteTypeAndGuid(1), "INVITE_CROSS_FACTION", "Native hidden-frame cache reproduces the false cross-faction invite")
-- Newer Forever builds read faction and realm inside the restriction check.
-- The native displayed-invite helper above still uses the hidden frame's cache.
local nativeRestriction = between(nativeFrame, "function FriendsFrame_GetInviteRestriction(", "function FriendsFrame_GetInviteRestrictionText(")
local readsCurrentFaction = nativeRestriction:find('UnitFactionGroup("player")', 1, true) ~= nil
equal(env.FriendsFrame_GetInviteRestrictionText(env.FriendsFrame_GetInviteRestriction(1)),
	readsCurrentFaction and "" or "NOT_ALLIED", "Native faction restriction matches the source build")
local info, restrictionText = BFL.GetBNetInviteTooltipInfo(1)
equal(info.inviteType, "INVITE", "Stateless helper reads the actual player faction")
equal(restrictionText, "", "Same-faction Forever account is not blocked")
env.FriendsFrame_GetDisplayedInviteTypeAndGuid = function() error("BFL must not use cached native faction data") end
env.FriendsFrame_GetInviteRestriction = env.FriendsFrame_GetDisplayedInviteTypeAndGuid

local tooltip = { lines = {} }
function tooltip:SetOwner() end
function tooltip:SetText(text) self.lines = { { text = text } }; self.shown = false end
function tooltip:AddLine(text, red, green, blue) self.lines[#self.lines + 1] = { text = text, red = red, green = green, blue = blue } end
function tooltip:Show() self.shown = true end
env.BFL_Tooltip = tooltip
env.BNGetNumFriends = function() return 1 end
BFL.IsBattleNetFriendsListEnabled = function() return true end
BFL.GetBNetFriendInfo = function() return { bnetAccountID = 42 } end
local mainSource = read(repo, "BetterFriendlist.lua")
execute(between(mainSource, "local BFL_INVITE_RESTRICTION_NONE =", "-- Display state")
	.. between(mainSource, "local CLASS_ID_TO_GAME_MODE =", "-- Multi-Game-Account Invite Picker")
	.. between(mainSource, "local inviteTypeToButtonText =", "-- Button OnClick Handler (matching Blizzard"), "BFL travel pass tooltip")
local button = { friendData = { type = "bnet", bnetAccountID = 42, friendLevel = 3, connected = true } }
local function showTooltip()
	env.BetterFriendsList_TravelPassButton_OnEnter(button)
	check(tooltip.shown, "Tooltip is shown")
	return tooltip.lines
end
local function hasLine(text)
	for _, line in ipairs(tooltip.lines) do if line.text == text then return true end end
	return false
end
env.GameTooltip_AddHighlightLine = function(target, text) target:AddLine(text, 1, 1, 1) end
env.GameTooltip_AddErrorLine = function(target, text) target:AddLine(text, 1, 0, 0) end
env.FriendsListSocialCardPartyButtonMixin = {}
local nativeCards = read(statelessSource, "Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsListTemplates.lua")
execute(between(nativeCards, "local function AddOfflineErrorToTooltip(", "function FriendsListSocialCardPartyButtonMixin:OnClick("),
	"Blizzard party-button tooltip builder")
tooltip.lines = {}
env.FriendsListSocialCardPartyButtonMixin.BuildTooltip({ friendIndex = 1, isOnline = false }, tooltip)
equal(#tooltip.lines, 2, "Blizzard's actual offline builder produces a heading and one reason")
equal(tooltip.lines[2].text, "Player Offline", "The BFL fixture matches Blizzard's actual offline message")
-- Offline takes precedence over stale game presence, faction and queue data.
local onlineInfo = BFL.GetBNetFriendInfo
for _, friendLevel in ipairs({ 1, 2, 3 }) do
	button.friendData.friendLevel, button.friendData.connected = friendLevel, false
	accounts = {}
	equal(#showTooltip(), 2, "Offline BattleTag/Real ID/Title tooltip keeps its title and error")
	equal(tooltip.lines[1].text, "Invite", "Offline title remains Invite to Group")
	equal(tooltip.lines[2].text, "Player Offline", "Offline uses Blizzard's localized party-button message")
	check(tooltip.lines[2].red == 1 and tooltip.lines[2].green == 0 and tooltip.lines[2].blue == 0,
		"Offline reason is red")
end
-- A disappeared index must not replace the useful offline reason with Error.
BFL.GetBNetFriendInfo = function() return nil end
showTooltip()
check(hasLine("Player Offline"), "Offline does not require a currently resolvable Battle.net index")
button.friendData.type = "wow"
showTooltip()
check(hasLine("Player Offline") and tooltip.lines[1].text == "Invite", "Offline WoW friends use the same tooltip")
button.friendData.connected = true
equal(#showTooltip(), 1, "Online WoW tooltip does not retain an offline reason")
button.friendData.type = "bnet"
showTooltip()
check(hasLine("NO_INFO") and not hasLine("Error"), "A temporarily missing account has a localized information reason")
BFL.GetBNetFriendInfo = onlineInfo
button.friendData.friendLevel, accounts = 3, { account() }
equal(#showTooltip(), 1, "Same-faction Title friend has no false restriction or Retail content hint")
equal(tooltip.lines[1].text, "Invite", "Same-faction Title friend has the normal invite label")
playerFaction = "Horde"
showTooltip()
check(hasLine("NOT_ALLIED"), "An actual opposing faction remains blocked in Forever")
check(not hasLine("Cross-faction content: Alliance"), "Forever does not promise Retail cross-faction content")
playerFaction = "Alliance"
accounts[1].factionName = "Horde"
crossFaction = true
BFL.IsForever, env.WOW_PROJECT_ID, accounts[1].wowProjectID = false, 1, 1
showTooltip()
check(hasLine("Cross-faction content: Horde") and not hasLine("NOT_ALLIED"), "Retail cross-faction hints remain supported when allowed")
questSession = true
showTooltip()
check(hasLine("QUEST_SESSION"), "Real Quest Session restrictions remain supported")
questSession, crossFaction = false, false
BFL.IsForever, env.WOW_PROJECT_ID = true, 18
for _, fixture in ipairs({
	{ { wowProjectID = 2 }, "WRONG_PROJECT_CLASSIC_OVERRIDE" },
	{ { wowProjectID = 1 }, "WRONG_PROJECT_MAINLINE_OVERRIDE" },
	{ { wowProjectID = 99 }, "WRONG_PROJECT" },
	{ { realmID = 0 }, "NO_INFO" },
	{ { isInCurrentRegion = false }, "DIFFERENT_REGION" },
	{ { classID = 14 }, "GAME_MODE" },
	{ { clientProgram = "App" }, "NOT_WOW" },
}) do
	accounts = { account(fixture[1]) }; showTooltip()
	check(hasLine(fixture[2]), "Native restriction is preserved: " .. fixture[2])
end
accounts = { account({ factionName = "Horde", playerGuid = "Bad" }), account({ playerGuid = "Good" }) }
equal(#showTooltip(), 1, "One eligible account wins over a restricted second account")

-- Use the real SocialQueue builder for activities, roles and auto-accept.
local queues, socialEnabled = {}, true
local members = { { guid = "Good" } }
for index = 1, 8 do members[#members + 1] = { guid = "Member" .. index } end
BFL.IsMainline = true
env.C_SocialQueue = {
	IsSystemSupported = function() return true end, IsSystemEnabled = function() return socialEnabled end,
	GetGroupForPlayer = function(guid) equal(guid, "Good", "Queue details use the displayed invite target"); return "Group42" end,
	GetGroupMembers = function() return members end, GetGroupQueues = function() return queues end,
}
env.SocialQueueUtil_HasRelationshipWithLeader = function(group) equal(group, "Group42", "Leader lookup uses the group GUID"); return true end
env.SocialQueueUtil_GetRelationshipInfo = function(guid) return guid, "|cffffffff" end
env.SocialQueueUtil_GetQueueName = function(data, format) return format:format(data.name) end
env.GameTooltip_AddNormalLine = function(target, text) target:AddLine(text) end
env.GameTooltip_AddDisabledLine = env.GameTooltip_AddNormalLine
env.GameTooltip_AddColoredLine = env.GameTooltip_AddNormalLine
env.SOCIAL_QUEUE_QUEUED_FOR_STANDALONE, env.SOCIAL_QUEUE_ALSO_IN_GROUP, env.SOCIAL_QUEUE_AND_MORE = "Queued for", "Also in group", "And more"
env.INLINE_TANK_ICON, env.INLINE_HEALER_ICON, env.INLINE_DAMAGER_ICON = "Tank", "Heal", "DPS"
env.QUICK_JOIN_TOOLTIP_AVAILABLE_ROLES_FORMAT, env.QUICK_JOIN_TOOLTIP_AVAILABLE_ROLES = "%s: %s", "Roles"
env.QUICK_JOIN_TOOLTIP_NO_AVAILABLE_ROLES, env.QUICK_JOIN_IS_AUTO_ACCEPT_TOOLTIP = "No roles", "Auto accept"
local socialSource = read(statelessSource, "Interface/AddOns/Blizzard_UIPanels_Game/Shared/SocialQueue.lua")
execute(between(socialSource, "function SocialQueueUtil_SetTooltip(", "function SocialQueueUtil_GetRelationshipInfo("),
	"Blizzard SocialQueue tooltip builder")
env.GetDisplayedInviteType = function() return "REQUEST_INVITE" end
showTooltip()
check(hasLine("Member7|r") == false and hasLine("|cffffffffMember7|r") and hasLine("And more"),
	"Legacy group-member details retain the seven-member limit without queued activities")
queues = { { queueData = { queueType = "lfg", name = "A dungeon" }, needTank = true, isAutoAccept = true } }
showTooltip()
check(hasLine("Queued for") and hasLine("- A dungeon") and hasLine("Roles: Tank") and hasLine("Auto accept"),
	"Request-to-join includes native activity, role and auto-accept details")
check(hasLine("Also in group") and hasLine("And more"), "Non-listing queues also show bounded group members")
queues = { { queueData = { queueType = "lfglist", lfgListID = 77 }, needHealer = true } }
env.C_LFGList = { HasSearchResultInfo = function(id) equal(id, 77, "Listing ID reaches the native queue builder"); return true end }
env.LFGListUtil_SetSearchEntryTooltip = function(target) target:AddLine("Listing with members") end
showTooltip()
check(hasLine("Listing with members") and not hasLine("Also in group"), "Premade listings do not duplicate their group members")
socialEnabled = false
equal(#showTooltip(), 1, "Disabled SocialQueue does not expose activity/group details")
socialEnabled = true
env.GetDisplayedInviteType = function() return "INVITE" end
equal(#showTooltip(), 1, "A normal invite does not show request-to-join queue details")
env.GetDisplayedInviteType = function() return "SUGGEST_INVITE" end
showTooltip()
equal(tooltip.lines[1].text, "Suggest", "Suggested invites retain the correct action label")
env.GetDisplayedInviteType = function() return "INVITE" end
env.C_SocialQueue = nil

local emptyInfo = BFL.GetBNetInviteTooltipInfo
-- The compatibility tooltip uses the same complete eligibility method as the
-- real list when stateless native tooltip helpers are unavailable.
env.GetFriendsList = function() return env.FriendsList end
local listSource = read(repo, "Modules/FriendsList.lua")
execute(between(listSource, "local INVITE_RESTRICTION_NONE =", "-- Helper Functions")
	.. between(listSource, "function FriendsList:IsReadableInviteRecord(", "function FriendsList:BuildAccountDisplay("),
	"production fallback invite eligibility")
env.FriendsListUtil = nil
equal(BFL.GetBNetInviteTooltipInfo(1), nil, "Clients without stateless helpers use the compatibility fallback")
equal(env.FriendsList:GetGameAccountInviteRestriction(accounts[2]), 0, "The fallback fixture's second account remains eligible")
equal(#showTooltip(), 1, "Fallback reads current faction and accepts a valid second account (" .. tostring(tooltip.lines[2] and tooltip.lines[2].text) .. ")")
accounts = { account({ classID = 14 }) }
showTooltip()
check(hasLine("GAME_MODE"), "The compatibility tooltip also reports an incompatible game mode")
accounts = { account({ factionName = "Horde" }) }
showTooltip()
check(hasLine(BFL.L.TRAVEL_PASS_DIFFERENT_FACTION), "Fallback keeps a real Forever faction restriction")
check(not hasLine("Cross-faction content: Horde"), "Fallback hides unsupported cross-faction content")
BFL.IsClassic, BFL.IsForever, env.WOW_PROJECT_ID = true, false, 2
accounts = { account({ wowProjectID = 2, realmID = 100 }) }
equal(#showTooltip(), 1, "Classic fallback accepts a same-faction same-realm friend")
accounts[1].realmID = 200
showTooltip()
check(hasLine("DIFFERENT_REALM"), "Classic fallback keeps the same-realm requirement")
accounts[1].realmID, accounts[1].factionName, crossFaction = 100, "Horde", true
showTooltip()
check(hasLine(BFL.L.TRAVEL_PASS_DIFFERENT_FACTION), "Classic fallback does not bypass the faction restriction")
env.FriendsListUtil = { GetBattleNetFriendInviteInfo = function() error("Unavailable API") end,
	GetGameAccountPartyInviteRestriction = nativeUtil.GetGameAccountPartyInviteRestriction,
	GetBattleNetFriendPartyInviteRestrictionText = nativeUtil.GetBattleNetFriendPartyInviteRestrictionText }
equal(emptyInfo(1), nil, "Unavailable native data falls back safely")
io.write("[OK] Forever presentation smoke: " .. assertions .. " assertions passed (mocked C APIs/widgets; no live game QA)\n")
