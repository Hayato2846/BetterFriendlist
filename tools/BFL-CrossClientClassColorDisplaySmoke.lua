-- lua tools/BFL-CrossClientClassColorDisplaySmoke.lua <repo> <WoW UI source>
-- Reproduces the user's Forever payload: Retail class ID only, no class name,
-- no token, and neither native color source knows the unsupported class.
local repo, native = assert(arg[1]), assert(arg[2])
local function read(path)
	local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close(); return text
end
local function fixture(path, boundary, body)
	local source = read(repo .. "/tools/" .. path)
	local stop = assert(source:find(boundary, 1, true))
	assert(load(source:sub(1, stop - 1) .. body, "@" .. path .. ":cross-client-class-colors", "t", _G))()
end

fixture("BFL-FriendsListStartupSmoke.lua", "-- A layout switch replaces the view", [=[
local variants = {
	{ 6, "DEATHKNIGHT", "ffc41e3a" }, { 10, "MONK", "ff00ff98" },
	{ 12, "DEMONHUNTER", "ffa330c9" }, { 13, "EVOKER", "ff33937f" },
}
for _, modern in ipairs({ false, true }) do
	for _, variant in ipairs(variants) do
		local snapshot = normal("Color#1234")
		local game = snapshot.gameAccountInfo
		game.wowProjectID, game.classID, game.className = 1, variant[1], nil
		game.classFilename, game.classFileName, game.classFile = nil, nil, nil
		game.characterName, game.characterLevel = "Retail" .. variant[2], 90
		local context = setup({ snapshot }, { modern = modern, colorClassNames = true })
		local env, BFL, list = context.env, context.BFL, context.list
		env.C_ClassColor = { GetClassColor = function() return nil end }
		env.C_CreatureInfo = { GetClassInfo = function() return nil end }
		env.GetClassInfo = function() return nil end
		check(env.RAID_CLASS_COLORS[variant[2]] == nil, "fixture omits the native unsupported class color")
		list:UpdateFriendsList()
		local friend = assert(list.friendsList[1])
		equal(friend.className, nil, "ingestion does not invent an unavailable localized class name")
		equal(BFL.ClassUtils:GetClassFileForFriend(friend), variant[2], "production row resolves the Retail class ID")
		local expected = "|c" .. variant[3] .. "(" .. game.characterName .. ")|r"
		check(list:GetDisplayName(friend):find(expected, 1, true), "name formatter colors ID-only cross-client characters")
		check(list:GetFormattedButtonText(friend):find(expected, 1, true), "actual rendered row preserves the cross-client color")
		check(list:BuildAccountDisplay(game).text:find("|c" .. variant[3] .. game.characterName .. "|r", 1, true), "account picker uses the same fallback color")
		check(env.RAID_CLASS_COLORS[variant[2]] == nil, "rendering never adds fallback colors to Blizzard globals")

		local broker = read("Modules/Broker.lua")
		local function between(source, first, last)
			local a = assert(source:find(first, 1, true)); return source:sub(a, assert(source:find(last, a + #first, true)) - 1)
		end
		env.GetDB = function() return BFL.modules.DB end
		env.GetFriendGameName = function() return "World of Warcraft" end
		env.GetClassColorForFriend = function(value) return BFL.ClassUtils:GetClassColorForFriend(value) end
		local brokerName = assert(load(between(broker, "local function GetDisplayLocation(", "local function GetFriendsList()")
			.. between(broker, "local function ReplaceTokenCaseInsensitive(", "-- Helper: Get colored level text")
			.. "\nreturn GetFriendDisplayName", "@production cross-client broker", "t", env))()
		env.BetterFriendlistDB.colorClassNames = true
		check(brokerName(friend):find(expected, 1, true), "broker name formatter colors the ID-only character")
		assert(load(read("Utils/BrokerUtils.lua"), "@production broker utilities", "t", env))("BetterFriendlist", BFL)
		equal(BFL.BrokerUtils.ClassColorTextByFile(variant[2], "Test"), "|c" .. variant[3] .. "Test|r", "broker class column uses the shared color")
		equal(BFL.BrokerUtils.C(variant[2], "Test"), "|c" .. variant[3] .. "Test|r", "broker class label uses the shared color")
		list.settingsCache.colorClassNames = false
		check(not list:GetDisplayName(friend):find("|c" .. variant[3], 1, true), "disabling class colors still disables the name color")
		local palette = BFL.ClassColors[variant[2]]
		env.C_ClassColor.GetClassColor = function() return { r = palette.r, g = palette.g, b = palette.b } end
		list.settingsCache.colorClassNames = true
		list.displayNameCache, friend._cache_text_line1 = {}, nil
		check(list:GetDisplayName(friend):find(expected, 1, true), "native RGB-only colors retain their hue without colorStr")
		check(list:BuildAccountDisplay(game).text:find("|c" .. variant[3] .. game.characterName .. "|r", 1, true), "picker derives hex from a native RGB-only color")
		friend.friendLevel, list.settingsCache.nameFormatString = 3, "%name%"
		check(list:GetDisplayName(friend):find("|c" .. variant[3] .. game.characterName .. "|r", 1, true), "name-only Title layout derives hex for native RGB colors")
	end
end
io.write("[OK] cross-client class color production display: " .. assertions .. " checks\n")
]=])

fixture("BFL-TitleFriendTooltipSmoke.lua", "local game = { gameAccountID", [=[
for _, variant in ipairs({ { 6, "ffc41e3a" }, { 10, "ff00ff98" }, { 12, "ffa330c9" }, { 13, "ff33937f" } }) do
	local game = { gameAccountID = 101, isOnline = true, clientProgram = "WoW", wowProjectID = 1,
		classID = variant[1], className = nil, characterName = "RetailFriend", characterLevel = 90,
		areaName = "King's Rest", realmName = "Retail Realm", richPresence = "King's Rest" }
	env.C_ClassColor = { GetClassColor = function() return nil end }
	env.C_CreatureInfo = { GetClassInfo = function() return nil end }
	env.GetClassInfo = function() return nil end
	local friend = { type = "bnet", index = 1, bnetAccountID = 42, friendLevel = 1,
		accountName = "Account", battleTag = "Account#1234", connected = true,
		gameAccountInfo = game, totalGameAccounts = 1 }
	env.BetterFriendsList_Button_OnEnter({ friendIndex = 1, friendData = friend })
	check(env.FriendsTooltipGameAccount1Name.text:find("|c" .. variant[2] .. "RetailFriend|r", 1, true), "actual tooltip mouseover colors class-ID-only Retail friend")
	local palette = BFL.ClassUtils:GetClassColorForFriend(game)
	env.C_ClassColor.GetClassColor = function() return { r = palette.r, g = palette.g, b = palette.b } end
	env.BetterFriendsList_Button_OnEnter({ friendIndex = 1, friendData = friend })
	check(env.FriendsTooltipGameAccount1Name.text:find("|c" .. variant[2] .. "RetailFriend|r", 1, true), "tooltip derives hex for a native RGB color without methods or colorStr")
end
io.write("[OK] cross-client class color tooltip mouseovers: " .. count .. " checks\n")
]=])
