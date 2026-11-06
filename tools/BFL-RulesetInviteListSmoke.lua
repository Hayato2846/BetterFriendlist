-- lua tools/BFL-RulesetInviteListSmoke.lua <repo>
-- Real list ingestion, eligibility, menu models and bulk invite dispatch.
-- Engine APIs/rendering are mocked; no live invitations are sent.
local repo = arg[1] or "."
local file = assert(io.open(repo .. "/tools/BFL-FriendsListStartupSmoke.lua", "rb"))
local fixture = file:read("*a"); file:close()
-- Complete the engine fixture's existing game-mode enum so its native gate is
-- exercised when a fresh account changes mode after collection.
fixture = fixture:gsub("GameMode = { Standard = 0 }", "GameMode = { Standard = 0, Plunderstorm = 1, WoWHack = 2 }", 1)
local boundary = assert(fixture:find("-- A layout switch replaces the view", 1, true))
local cases = [=[
local function ga(id, ruleset, overrides)
	local value = { isOnline = true, clientProgram = "WoW", wowProjectID = 18, realmID = 100,
		realmName = "CAMWOW EU5 Realm 9 " .. (ruleset or "PvP"), characterName = "Ada Lovelace",
		characterLevel = 16, classID = 1, factionName = "Alliance", isInCurrentRegion = true,
		playerGuid = "Player-18-" .. id, gameAccountID = id, areaName = "Elwynn" }
	for key, field in pairs(overrides or {}) do value[key] = field end
	return value
end
local function scenario(accounts, options)
	options = options or {}
	local snapshot = title()
	snapshot.gameAccountInfo = accounts[1]
	local c = setup({ snapshot }, { modern = true, classic = options.classic })
	local env, BFL, list = c.env, c.BFL, c.list
	BFL.IsForever = options.forever ~= false
	env.WOW_PROJECT_ID = options.project or 18
	env.Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
	env.RegionalUniqueNamesEnabled = function() return BFL.IsForever end
	env.GetRealmName = function() return options.playerRealm or "CAMWOW EU5 Realm 1 PvP" end
	env.GetNormalizedRealmName = function() return env.GetRealmName():gsub("%s+", "") end
	env.C_PartyInfo.CanFormCrossFactionParties = function() return options.crossFaction == true end
	env.GetNumGroupMembers = function() return options.grouped and 1 or 0 end
	env.IsInRaid = function() return false end
	env.UnitNameUnmodified = function(unit) if options.grouped and unit == "party1" then return "Ada", "Byron" end end
	env.UnitName = env.UnitNameUnmodified
	local clock = 100
	env.GetTime = function() clock = clock + 1; return clock end
	c.sent, c.fresh, c.current = {}, 0, {}
	for _, account in ipairs(accounts) do c.current[account.gameAccountID] = account end
	env.C_BattleNet.GetFriendNumGameAccounts = function() return #accounts end
	env.C_BattleNet.GetFriendGameAccountInfo = function(_, index) return accounts[index] end
	env.C_BattleNet.GetGameAccountInfoByID = function(id) c.fresh = c.fresh + 1; return c.current[id] end
	env.C_BattleNet.InviteFriend = function(id) c.sent[#c.sent + 1] = id end
	BFL.modules.DB.GetPreferredGameAccount = function() return options.preferred end
	list:UpdateFriendsList()
	c.friend = assert(list.friendsList[1]); c.friend.isFavorite = true
	return c
end
local function copy(value) local result = {}; for key, field in pairs(value) do result[key] = field end; return result end

local blocked = scenario({ ga(1, "PvE") })
check(not blocked.friend.canInvite, "Known Ruleset mismatch disables the friend")
equal(blocked.friend.numInvitableAccounts, 0, "Ruleset mismatch cannot enter eligible accounts")
equal(blocked.friend.inviteRestriction, 14, "Ruleset uses the BFL-owned restriction ID")
local display = blocked.list:BuildAccountDisplay(blocked.friend.gameAccountInfo)
check(not display.isInvitable and display.restriction == 14, "Account model stays disabled")
equal(display.restrictionText, blocked.BFL.L.INVITE_RESTRICTION_RULESET,
	"Ruleset restriction uses the concise localized invite message")
local entries = blocked.list:GetInviteAccountEntries(blocked.friend)
equal(#entries, 1, "A single blocked account remains visible in the invite menu model")
equal(entries[1].restrictionText, display.restrictionText, "Menu uses the exact detail reason")
equal(blocked.fresh, 0, "Building data and menu models performs no fresh target API reads")

local staleMetadata = copy(blocked.friend.gameAccountInfo)
staleMetadata.bflIsInvitable, staleMetadata.bflRestriction = true, 0
local pure = blocked.list:BuildAccountDisplay(staleMetadata)
check(not pure.isInvitable and pure.restriction == 14, "Pure Ruleset check overrides stale eligible metadata")
check(staleMetadata.bflIsInvitable and staleMetadata.bflRestriction == 0, "Display model does not rewrite caller metadata")
equal(pure.gameAccountID, staleMetadata.gameAccountID, "Display model preserves game account identity")
equal(pure.playerGuid, staleMetadata.playerGuid, "Display model preserves character identity")
local recoveredMetadata = copy(blocked.friend.gameAccountInfo)
recoveredMetadata.realmName = "UnrecognizedRealm"
local recoveredDisplay = blocked.list:BuildAccountDisplay(recoveredMetadata)
check(recoveredDisplay.isInvitable and recoveredDisplay.restrictionText == nil,
	"Cached Ruleset-only metadata cannot turn a now-unknown Ruleset into a new block")
check(not recoveredMetadata.bflIsInvitable and recoveredMetadata.bflRestriction == 14,
	"Model recovery leaves native snapshot metadata untouched")

local noProject = ga(1, "PvE"); noProject.wowProjectID = nil
local missingProject = scenario({ noProject })
check(not missingProject.friend.canInvite and missingProject.friend.inviteRestriction == 14,
	"Known mismatch is checked in the missing-project native branch")
for _, realm in ipairs({ "PvP", "UnrecognizedRealm" }) do
	local c = scenario({ ga(1, realm) })
	check(c.friend.canInvite, "Same or unknown Ruleset adds no new restriction")
end
local faction = scenario({ ga(1, "PvP", { factionName = "Horde" }) }, { crossFaction = true })
check(not faction.friend.canInvite and faction.friend.inviteRestriction == 2,
	"Forever factions must match even when the general native capability is true")
local unknownFaction = scenario({ ga(1, "PvP", { factionName = "" }) }, { crossFaction = true })
check(unknownFaction.friend.canInvite, "Unreadable/empty optional faction adds no invented known-faction mismatch")
local partial = ga(1, "PvP"); partial.isOnline = nil
equal(blocked.list:GetGameAccountInviteRestriction(partial), 4, "Missing native online evidence cannot create eligible accounts")
partial.isOnline, partial.gameAccountID = true, 1.5
equal(blocked.list:GetGameAccountInviteRestriction(partial), 4, "Invalid account IDs cannot create eligible accounts")

local mixed = scenario({ ga(1, "PvE"), ga(2, "PvP"), ga(3, "PvP", { factionName = "Horde" }),
	ga(4, "PvP", { wowProjectID = 1 }) }, { crossFaction = true })
check(mixed.friend.canInvite, "A compatible secondary login keeps the friend invitable")
equal(mixed.friend.numInvitableAccounts, 1, "Only the compatible secondary login is eligible")
equal(mixed.friend.invitableAccounts[1].gameAccountID, 2, "Primary mismatch cannot enter the eligible list")
entries = mixed.list:GetInviteAccountEntries(mixed.friend)
equal(#entries, 2, "Invite model exposes eligible plus Ruleset-blocked accounts only")
equal(entries[1].gameAccountID, 2, "Eligible entry retains its identity")
equal(entries[2].gameAccountID, 1, "Blocked primary appears exactly once")
check(not entries[2].isInvitable and entries[2].restrictionText ~= nil, "Blocked alternate carries hover detail")
equal(mixed.list:GetInvitableCount("favorites"), 1, "Bulk count finds the eligible secondary")
mixed.list:InviteGroupToParty("favorites")
equal(table.concat(mixed.sent, ","), "2", "Bulk dispatch sends only the fresh eligible secondary")
equal(mixed.fresh, 1, "Bulk dispatch refreshes the selected account once")

local allBlocked = scenario({ ga(1, "PvE"), ga(2, "RP") })
equal(#allBlocked.list:GetInviteAccountEntries(allBlocked.friend), 2, "All Ruleset-blocked accounts remain visible")
equal(allBlocked.list:GetInvitableCount("favorites"), 0, "Bulk count excludes known mismatches")
allBlocked.list:InviteGroupToParty("favorites")
equal(#allBlocked.sent, 0, "Bulk action cannot bypass a known Ruleset restriction")

-- Native gates are checked on the fresh record, beyond the new policy helper.
for _, mutation in ipairs({ { realmName = "CAMWOW EU5 Realm 9 PvE" }, { factionName = "Horde" },
	{ playerGuid = "Player-Other" }, { isOnline = false }, { isInCurrentRegion = false }, { realmID = 0 },
	{ classID = 14 }, { wowProjectID = 1 }, { clientProgram = "App" }, { gameAccountID = 99 } }) do
	local c = scenario({ ga(1, "PvP") })
	local fresh = copy(c.current[1]); for key, value in pairs(mutation) do fresh[key] = value end
	c.current[1] = fresh
	c.list:InviteGroupToParty("favorites")
	equal(#c.sent, 0, "Freshly incompatible or rebound account sends no invite: " .. next(mutation))
end
local recover = scenario({ ga(1, "PvP") })
recover.current[1] = nil
recover.list:InviteGroupToParty("favorites")
equal(#recover.sent, 0, "Missing fresh account does not replay cached eligibility")
recover.current[1] = ga(1, "UnknownRealm")
recover.list:InviteGroupToParty("favorites")
equal(table.concat(recover.sent, ","), "1", "A fresh unknown Ruleset recovers without a false block")

local names = scenario({ ga(1, "PvP") }, { grouped = true })
check(names.list:IsRegionalInviteTargetInGroup("Ada Byron"), "Complete native surname matches the grouped member")
check(not names.list:IsRegionalInviteTargetInGroup("Ada-Lovelace"), "Same first name cannot mask a different surname")
equal(names.list:GetInvitableCount("favorites"), 1, "Bulk count does not collapse two different Ada identities")
names.list:InviteGroupToParty("favorites")
equal(table.concat(names.sent, ","), "1", "Full identity match permits the distinct character")
local preferred = scenario({ ga(1, "PvP"), ga(2, "PvE") }, { preferred = 2 })
equal(preferred.friend.gameAccountInfo.gameAccountID, 2, "Saved display focus can remain an incompatible account")
equal(preferred.list:GetInvitableCount("favorites"), 1, "Saved incompatible focus does not hide an eligible login")
preferred.list:InviteGroupToParty("favorites")
equal(table.concat(preferred.sent, ","), "1", "Bulk invite never blindly follows incompatible saved focus")

local restricted = setmetatable({}, { __index = function() error("secret table indexed") end,
	__pairs = function() error("secret table iterated") end, __len = function() error("secret table measured") end })
blocked.env.issecrettable = function(value) return rawequal(value, restricted) end
equal(#blocked.list:GetInviteAccountEntries(restricted), 0, "Restricted friend container is skipped")
equal(#blocked.list:GetInviteAccountEntries({ invitableAccounts = restricted, gameAccounts = restricted,
	gameAccountInfo = restricted }), 0, "Restricted account containers are skipped")
check(not blocked.list:BuildAccountDisplay(restricted).isInvitable, "Restricted account model is disabled")
local secretAccount = ga(1, "PvP", { playerGuid = protectedAccount })
local secretState = scenario({ secretAccount })
check(not secretState.friend.canInvite, "Restricted target identity disables data-layer eligibility")
secretAccount.playerGuid = "Player-18-1"
secretState.list:UpdateFriendsList()
check(secretState.list.friendsList[1].canInvite, "Readable identity recovers on the normal friend refresh")

-- Run the actual TravelPass model-to-widget branch with painting mocked.
local travelStart = assert(source:find("\t\t-- Handle TravelPass button for Battle.net friends", 1, true))
local travelEnd = assert(source:find("\t\t-- Text handled by optimized shared cache", travelStart, true))
blocked.env.SetTravelPassButtonTextures = function(button, atlas) button.atlas = atlas end
local applyTravel = assert(load("return function(button, friend)\n" .. source:sub(travelStart, travelEnd - 1)
	.. "\nend", "@production TravelPass rendering", "t", blocked.env))()
local function button()
	return { travelPassButton = { Enable = function(self) self.enabled = true end,
		Disable = function(self) self.enabled = false end, Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end } }
end
local rulesetButton, factionButton = button(), button()
applyTravel(rulesetButton, blocked.friend); applyTravel(factionButton, faction.friend)
check(not rulesetButton.travelPassButton.enabled and rulesetButton.travelPassButton.shown,
	"Ruleset-mismatched TravelPass stays visible and disabled")
equal(rulesetButton.travelPassButton.atlas, factionButton.travelPassButton.atlas,
	"Ruleset mismatch uses the same disabled art family as faction mismatch")

-- Focus selection stays usable, while its label explains invite incompatibility.
local focus = scenario({ ga(1, "PvP"), ga(2, "PvE") })
local capturedItems
focus.BFL.OpenSimpleContextMenu = function(_, _, items) capturedItems = items end
focus.BFL.GetClientEmbeddedIcon = function() return "" end
focus.list:ShowGameAccountPicker({}, focus.friend)
local foundDetail = false
for _, item in ipairs(capturedItems) do
	if item.value == 2 then foundDetail = item.text:find(focus.list:BuildAccountDisplay(focus.current[2]).restrictionText, 1, true) ~= nil end
end
check(foundDetail, "Account focus picker includes the exact Ruleset detail")
local rowBuilder
for index = 1, 30 do
	local name, value = debug.getupvalue(focus.list.UpdateMultiAccountRow, index)
	if not name then break end
	if name == "BuildMultiAccountRowData" then rowBuilder = value end
end
local rowData = assert(rowBuilder)(focus.list, focus.friend)
equal(rowData.entries[1].restrictionText, focus.list:BuildAccountDisplay(focus.current[2]).restrictionText,
	"Multi-account row model carries the exact Ruleset detail")

local retail = scenario({ ga(1, "PvE", { wowProjectID = 1, factionName = "Horde" }) },
	{ forever = false, project = 1, crossFaction = true })
check(retail.friend.canInvite, "Retail retains native cross-faction capability behavior")
equal(#retail.list:GetInviteAccountEntries(retail.friend), 1, "Retail retains its existing eligible menu list")
retail.list:InviteGroupToParty("favorites")
equal(table.concat(retail.sent, ","), "1", "Retail bulk selection remains the primary account")
equal(retail.fresh, 0, "Retail gains no Forever refresh policy")
local classic = scenario({ ga(1, "PvE", { wowProjectID = 2 }) },
	{ forever = false, project = 2, classic = true })
check(classic.friend.canInvite, "Classic same-realm native eligibility is unchanged")
local classicForeign = scenario({ ga(1, "PvP", { wowProjectID = 2, realmID = 200 }) },
	{ forever = false, project = 2, classic = true })
check(not classicForeign.friend.canInvite and classicForeign.friend.inviteRestriction == 3,
	"Classic native cross-realm restriction remains unchanged")
io.write("[OK] Ruleset invite list: " .. assertions .. " checks (production module; mocked APIs/widgets)\n")
]=]
arg = { repo }
assert(load(fixture:sub(1, boundary - 1) .. cases, "@Ruleset invite list production smoke"))()
