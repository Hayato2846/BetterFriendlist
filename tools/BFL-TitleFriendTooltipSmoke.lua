-- Lua 5.4: lua tools/BFL-TitleFriendTooltipSmoke.lua <repo> <WoW UI source>
-- Runs the full production friend tooltip and Blizzard's real line measurements.
-- FontStrings/C APIs are mocked; final rendering still needs in-game QA.
local repo = assert(arg[1], "repository root is required")
local sourceRoot = assert(arg[2], "WoW UI source root is required")
local function read(root, path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local text = file:read("*a")
	file:close()
	return text
end
local count = 0
local function check(value, message) count = count + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function widget(width)
	local object = { points = {}, width = width or 176, text = "", shown = false }
	function object:SetPoint(...)
		local point = { ... }
		for index, previous in ipairs(self.points) do
			if previous[1] == point[1] then self.points[index] = point; return end
		end
		self.points[#self.points + 1] = point
	end
	function object:GetPoint(index) return table.unpack(self.points[index or 1]) end
	function object:GetNumPoints() return #self.points end
	function object:ClearAllPoints() self.points = {} end
	function object:SetText(value) self.text = value or "" end
	function object:SetTextColor(...) self.color = { ... } end
	function object:GetHeight() return self.height or 14 end
	function object:GetWidth() return self.width end
	function object:GetStringWidth() return #self.text * 4 end
	function object:SetHeight(value) self.height = value end
	function object:SetWidth(value) self.width = value end
	function object:Show() self.shown = true end
	function object:Hide()
		self.shown = false
		if self.onHide then self.onHide(self) end
	end
	function object:HookScript(event, callback) if event == "OnHide" then self.onHide = callback end end
	function object:IsShown() return self.shown end
	function object:SetParent(value) self.parent = value end
	function object:EnableMouse() end
	function object:SetJustifyH() end
	function object:SetJustifyV() end
	function object:SetFontObject() end
	function object:SetWordWrap() end
	function object:SetNonSpaceWrap() end
	function object:CreateFontString() return widget() end
	return object
end
local BFL = { modules = {}, L = { FRIEND_TYPE_WOW = "WoW friend", FRIEND_TYPE_BATTLETAG = "BattleTag friend",
	FRIEND_TYPE_REAL_ID = "Real ID friend" }, IsClassic = false, HasSecretValues = true }
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
local secret = setmetatable({}, { __index = function() error("Secret metadata must not be inspected") end })
function BFL:IsSecret(value) return value == secret end
function BFL:GetSafeAccountName(account, tag) return self:IsSecret(account) and tag or account or tag or "Unknown" end
local env = setmetatable({ BFL = BFL, UIParent = widget(), CreateFrame = function() return widget() end,
	SlashCmdList = {}, StaticPopupDialogs = {},
	unpack = table.unpack, max = math.max, UNKNOWN = "Unknown", playerFactionGroup = "Alliance",
	Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 } },
	BNET_CLIENT_WOW = "WoW", BNET_CLIENT_APP = "App", BNET_CLIENT_CLNT = "BSAp",
	WOW_PROJECT_ID = 18, WOW_PROJECT_CLASSIC = 2, FRIENDS_BUTTON_TYPE_BNET = 1, FRIENDS_BUTTON_TYPE_WOW = 2,
	FRIENDS_TOOLTIP_MAX_WIDTH = 200, FRIENDS_TOOLTIP_MARGIN_WIDTH = 24, FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS = 4,
	FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE = "%s · %d %s %s", FRIENDS_LEVEL_TEMPLATE = "Level %d %s",
	BNET_FRIEND_TOOLTIP_ZONE_AND_REALM = "Zone: %s\nRealm: %s", BNET_FRIEND_TOOLTIP_ZONE_AND_REGION = "Zone: %s\nRegion: %s",
	FRIENDS_LIST_OFFLINE = "Offline", CANNOT_COOPERATE_LABEL = "*", FRIENDS_TOOLTIP_TOO_MANY_CHARACTERS = "+%d characters",
	FRIENDS_BNET_NAME_COLOR = { r = 0.51, g = 0.77, b = 1 }, FRIENDS_GRAY_COLOR = { r = 0.5, g = 0.5, b = 0.5 },
	RAID_CLASS_COLORS = { ROGUE = { r = 1, g = 245/255, b = 105/255, colorStr = "fffff569" } }, BetterFriendlistDB = { colorClassNames = true },
	BFL_Tooltip = widget(),
}, { __index = _G })
env._G = env
env.FriendsTooltip = widget(200)
for _, name in ipairs({ "Header", "NoteText", "NoteIcon", "BroadcastText", "BroadcastIcon", "LastOnline",
	"OtherGameAccounts", "GameAccountMany" }) do
	env["FriendsTooltip" .. name] = widget()
	env["FriendsTooltip" .. name]:SetPoint("TOPLEFT", env.FriendsTooltip, "TOPLEFT", 12, -12)
end
for index = 1, 4 do
	local name, info = widget(), widget(168)
	env["FriendsTooltipGameAccount" .. index .. "Name"] = name
	env["FriendsTooltipGameAccount" .. index .. "Info"] = info
	name:SetPoint("LEFT", env.FriendsTooltip, "LEFT", 12, 0)
	name:SetPoint("TOP", env.FriendsTooltipHeader, "BOTTOM", 0, -4)
	info:SetPoint("LEFT", env.FriendsTooltip, "LEFT", 20, 0)
	info:SetPoint("TOP", name, "BOTTOM", 0, -4)
end
local function execute(text, label)
	return assert(load(text, "@" .. label, "t", env))("BetterFriendlist", BFL)
end
execute(read(repo, "Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
execute(read(repo, "Data/ClassColors.lua"), "Data/ClassColors.lua")
execute(read(repo, "Utils/ClassUtils.lua"), "Utils/ClassUtils.lua")
local nativePath, nativeSource
for _, path in ipairs({ "Interface/AddOns/Blizzard_FriendsFrame/Camelot/FriendsFrame.lua",
	"Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsFrame.lua",
	"Interface/AddOns/Blizzard_UIPanels_Game/Classic/FriendsFrame.lua" }) do
	local file = io.open(sourceRoot .. "/" .. path, "rb")
	if file then nativeSource = file:read("*a"); file:close(); nativePath = path; break end
end
assert(nativeSource, "native friend tooltip source is required")
local start = assert(nativeSource:find("function FriendsFrameTooltip_SetLine(", 1, true))
local finish = assert(nativeSource:find("\nend", start, true)) + #"\nend"
execute(nativeSource:sub(start, finish), nativePath .. " (native line measurement)")
BFL.modules.FriendsList = {
	ResolveBNetFriendIndex = function() return 1 end,
	ResolveWoWFriendIndex = function() return 1 end,
	GetDisplayName = function() return "Masked friend" end,
}
BFL.modules.ContactMemory = { GetTooltipSummaryForFriend = function(_, friend)
	if friend.tags then return { title = "Notes & Tags", tagsText = friend.tags } end
end }
local nativeEnters = 0
env.FriendsListButtonMixin = { OnEnter = function(self)
	nativeEnters = nativeEnters + 1
	env.FriendsTooltip.height, env.FriendsTooltip.maxWidth = 0, 0
	env.FriendsFrameTooltip_SetLine(env.FriendsTooltipHeader, nil, self.friendData.name)
	env.FriendsFrameTooltip_SetLine(env.FriendsTooltipGameAccount1Name, nil, "Level 7 Rogue")
end }
local showSafe, proxy = execute(read(repo, "BetterFriendlist_Tooltip.lua")
	.. "\nreturn ShowSafeRetailBNetTooltip, proxyButton", "BetterFriendlist_Tooltip.lua")
local game = { gameAccountID = 101, isOnline = true, clientProgram = "WoW", wowProjectID = 18,
	characterName = "Raizor Shadowstalke", characterLevel = 7, raceName = "Human", className = "Rogue",
	factionName = "Alliance", realmID = 100, isInCurrentRegion = true, realmName = "Classic Beta PvE 2",
	areaName = "Elwynn Forest", richPresence = "In the world" }
local friend = { type = "bnet", index = 1, bnetAccountID = 42, friendLevel = 3,
	accountName = game.characterName, characterName = game.characterName, connected = true,
	gameAccountInfo = game, totalGameAccounts = 1, note = "ABC", tags = "DPS, Healer, Tank" }
local button = { friendIndex = 1, friendData = friend }
local header, name, info = env.FriendsTooltipHeader, env.FriendsTooltipGameAccount1Name, env.FriendsTooltipGameAccount1Info
local function show() env.BetterFriendsList_Button_OnEnter(button) end
local function nameOccurrences()
	local occurrences = 0
	for _, line in ipairs({ header, name, info }) do
		if line:IsShown() then
			local _, matches = line.text:gsub(game.characterName, "")
			occurrences = occurrences + matches
		end
	end
	return occurrences
end
show()
equal(env.FriendsTooltip.BFLFriendTypeLine.text, "WoW friend", "Title type appears in the addon-owned tooltip line")
equal(nameOccurrences(), 1, "An online Title character appears only once")
check(not header:IsShown(), "The redundant Title account header is hidden")
check(name:IsShown() and name.text:find("|cfffff569Raizor Shadowstalke|r", 1, true), "The retained character uses class color")
check(name.text:find("7 Human Rogue", 1, true), "Level, race and class remain available")
equal(info.text, "Elwynn Forest", "Forever hides the realm when its ruleset is unknown")
equal(env.FriendsTooltipNoteText.text, "ABC", "The friend note remains available")
equal(env.FriendsTooltip.ContactMemoryLines[2].text, "DPS, Healer, Tank", "Friend tags remain available")
local point, relative, relativePoint, x, y = name:GetPoint(1)
equal(point, "TOPLEFT", "The remaining line starts at the header position")
equal(relative, env.FriendsTooltip, "The line no longer depends on a hidden header's height")
equal(x, 12, "Native left padding is retained")
equal(y, -12, "Native top padding is retained")
local titleHeight = env.FriendsTooltip.height
for _ = 1, 5 do
	proxy:OnEnter()
	equal(nameOccurrences(), 1, "Broadcast refresh cannot restore the redundant header")
	equal(env.FriendsTooltip.height, titleHeight, "Repeated refresh does not accumulate tooltip height")
end
for _, account in ipairs({ "|Kq42|k", secret }) do
	friend.accountName = account
	show()
	equal(nameOccurrences(), 1, "Title character display does not depend on account labels")
	check(not header:IsShown(), "Encoded/restricted account labels do not create a header")
end
friend.accountName, friend.titleCustomName = game.characterName, "Raid buddy"
show()
equal(nameOccurrences(), 1, "The requested Title tooltip keeps just the character, even with a custom alias")
friend.titleCustomName = nil
env.BetterFriendlistDB.colorClassNames = false
show()
check(not name.text:find("|c", 1, true), "Disabled class coloring remains disabled")
equal(nameOccurrences(), 1, "Disabling colors does not reintroduce duplicate names")
env.BetterFriendlistDB.colorClassNames = true
game.className = secret
show()
check(not name.text:find("|c", 1, true), "Restricted class metadata does not invent a color")
game.className = "Rogue"
game.areaName = nil
show()
equal(nameOccurrences(), 1, "Rich-presence Title tooltips also omit the account header")
equal(name.text, "|cfffff569Raizor Shadowstalke|r", "Rich-presence names retain class color")
equal(info.text, "In the world", "Rich presence remains available")
game.areaName = "Elwynn Forest"
friend.connected, game.isOnline = false, false
show()
check(header:IsShown() and not name:IsShown(), "Offline Title tooltips show only their account fallback")
equal(header.text, game.characterName, "Offline Title names remain available")
equal(header.color[1], 0.5, "Offline Title names stay gray")
check(not header.text:find("|c", 1, true), "Offline names do not retain online class markup")
equal(env.FriendsTooltipLastOnline.text, "Offline", "Offline status remains available")
friend.connected, game.isOnline = true, true
show()
equal(nameOccurrences(), 1, "Reconnecting restores one class-colored Title name")
friend.gameAccountInfo = nil
show()
check(header:IsShown() and not name:IsShown(), "Missing game data keeps a usable header fallback")
friend.gameAccountInfo = game
for _, level in ipairs({ 1, 2 }) do
	friend.friendLevel = level
	show()
	check(header:IsShown() and name:IsShown(), "BattleTag and Real ID keep both native lines")
	equal(nameOccurrences(), 2, "Non-Title friends are not deduplicated merely because the labels match")
	equal(header.color[3], 1, "Ordinary online account headers retain Battle.net blue")
	point, relative = name:GetPoint(1)
	equal(point, "LEFT", "The original character-line anchors are restored")
	local topPoint, topRelative, bottomPoint, _, gap = name:GetPoint(2)
	equal(topPoint, "TOP", "The native vertical anchor is restored")
	equal(topRelative, header, "Normal character details sit below the header")
	equal(gap, -4, "The native header gap is restored")
	equal(env.FriendsTooltip.height, titleHeight + header:GetHeight(), "The Title tooltip has no blank header space")
end
friend.friendLevel = 3
show()
button.friendData = { type = "wow", index = 1, name = "Other rogue", connected = true }
show()
equal(nativeEnters, 1, "WoW friends still use the native tooltip path")
equal(name:GetPoint(1), "LEFT", "A following native tooltip does not inherit the Title layout")
equal(header.text, "Other rogue", "A following native tooltip keeps its header")
button.friendData = friend
show()
check(not header:IsShown(), "Returning to a Title friend restores the compact layout")
env.BetterFriendsList_Button_OnLeave(button)
equal(name:GetPoint(1), "LEFT", "Leaving restores anchors for tooltips opened outside BFL")
check(not env.FriendsTooltip:IsShown(), "Leaving still hides the friend tooltip")
check(not env.FriendsTooltip.BFLFriendTypeLine:IsShown(), "Leaving clears the addon-owned friend type")
check(not env.FriendsTooltip.ContactMemoryLines[1]:IsShown(), "Leaving clears addon-owned contact memory")
env.FriendsTooltip:Show()
check(not env.FriendsTooltip.BFLFriendTypeLine:IsShown(), "A foreign native hover cannot resurrect the previous friend type")
show()
env.FriendsTooltip:Hide()
check(not env.FriendsTooltip.BFLFriendTypeLine:IsShown(), "Parent hide also clears additions without an OnLeave event")
env.Enum.BattleNetFriendLevel = nil
show()
check(header:IsShown() and name:IsShown(), "Clients without Title friend capability retain ordinary BNet behavior")
-- Exercise the actual KnownCharacters model through the complete production
-- tooltip renderer and Blizzard's native line-measurement helper.
env.GetCurrentRegion = function() return 3 end
BFL.L.KC_TITLE, BFL.L.KC_MANUAL, BFL.L.KC_MORE = "Known characters", "%s (manual)", "%d more known characters"
local known = execute(read(repo, "Modules/KnownCharacters.lua"), "KnownCharacters")
known:SetSetting("enabled", true)
known:SetSetting("maxTooltipCharacters", 2)
friend.battleTag = "Ada#1234"
for _, fullName in ipairs({ "One-Home", "Two-Home", "Three-Home", "Four-Home" }) do check(known:AddManual(friend, fullName), "Tooltip fixture links a manual character") end
show()
local knownLines = env.FriendsTooltip.KnownCharacterLines
equal(#knownLines, 4, "Native tooltip has a title, two characters and a remainder count")
equal(knownLines[1].text, BFL.L.KC_TITLE, "Known characters has its own localized section")
check(knownLines[4].text:find("2", 1, true), "The remainder reports known characters, not a complete alt total")
local knownHeight = env.FriendsTooltip.height
for _ = 1, 3 do show(); equal(env.FriendsTooltip.height, knownHeight, "Repeated known-character refresh never accumulates height") end
env.BetterFriendsList_Button_OnLeave(button)
for _, line in ipairs(knownLines) do check(not line:IsShown() and line.text == "", "Tooltip leave scrubs every addon-owned known-character line") end
show()
BFL.StreamerMode = { IsActive = function() return true end }
known:HideSurfaces()
for _, line in ipairs(knownLines) do check(not line:IsShown(), "Streamer privacy cleanup immediately hides known-character lines") end
show()
for _, line in ipairs(knownLines) do check(not line:IsShown(), "Streamer refresh cannot repopulate known-character lines") end
BFL.StreamerMode = nil
known:ClearContact(friend)
show()
for _, line in ipairs(knownLines) do check(not line:IsShown(), "Deleted character links cannot reappear in recycled tooltips") end
-- The Classic dispatch must append exactly once via its secure post-hook and
-- remove additions again when Blizzard reuses the frame for a foreign button.
BFL.IsClassic = true
local classicHooks = 0
env.FriendsFrameTooltip_Show = function(nativeButton)
	env.FriendsTooltip.height, env.FriendsTooltip.maxWidth = 0, 0
	env.FriendsFrameTooltip_SetLine(header, nil, nativeButton.friendData and "Own friend" or "Foreign friend")
end
env.hooksecurefunc = function(functionName, callback)
	classicHooks = classicHooks + 1
	local original = env[functionName]
	env[functionName] = function(...)
		original(...)
		callback(...)
	end
end
execute(read(repo, "BetterFriendlist_Tooltip.lua"), "Classic tooltip dispatch")
known:AddManual(friend, "Classic-Home")
show()
check(knownLines[1]:IsShown() and knownLines[2].text:find("Classic-Home", 1, true), "Classic native tooltip post-hook includes actual known-character data")
local classicHeight = env.FriendsTooltip.height
show()
equal(env.FriendsTooltip.height, classicHeight, "Classic refresh adds the section only once")
equal(classicHooks, 1, "Classic retains one secure post-hook, without replacing native scripts")
env.FriendsFrameTooltip_Show({})
for _, line in ipairs(knownLines) do check(not line:IsShown(), "Foreign Classic tooltips cannot retain known-character text") end
io.write("[OK] Title friend tooltip smoke: " .. count .. " assertions passed (" .. nativePath .. "; mocked widgets, no live QA)\n")
