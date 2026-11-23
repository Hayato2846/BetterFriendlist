-- Lua 5.4: lua tools/BFL-ContextMenuSectionsSmoke.lua <repo> <Forever UI source> <Classic UI source>
-- Runs the production menu generator with native queued-description helpers and
-- BFL's real UIDropDownMenu fallback. Widgets and C APIs are mocked, not live QA.
local repo, forever, classic = assert(arg[1]), assert(arg[2]), assert(arg[3])
local function read(root, path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local content = file:read("*a"); file:close(); return content
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
local source = read(repo, "BetterFriendlist.lua")
local function setup(nativeRoot)
	local BFL = { L = {}, IsClassic = not nativeRoot, modules = {} }
	function BFL:RegisterModule(name, module) self.modules[name] = module; return module end
	function BFL:GetModule(name) return self.modules[name] end
	function BFL:IsSecret() return false end
	local env = setmetatable({ BFL = BFL, ADDON_NAME = "BetterFriendlist", UIParent = {}, SlashCmdList = {}, StaticPopupDialogs = {},
		Enum = { BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 } },
		BFL_FirstSafeText = function(...) for index = 1, select("#", ...) do local value = select(index, ...); if value then return value end end end,
		BFL_GetContextFullName = function(context) return context.name end,
		BFL_GetContextDisplayName = function(context) return context.name end,
		BFL_GetContextGUID = function(context) return context.guid end,
		BFL_GetDisplayedInviteTypeSafe = function() return "INVITE" end,
		BFL_GetInviteButtonText = function() return "Invite" end,
		AddGroupsToFriendMenu = function(_, root) root:CreateDivider(); root:CreateTitle("BetterFriendlist"); root:CreateButton("Set Nickname") end,
		CreateFrame = function() return {} end,
	}, { __index = _G })
	local function execute(content, label) return assert(load(content, "@" .. label, "t", env))("BetterFriendlist", BFL) end
	execute(read(repo, "Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
	execute(read(repo, "Modules/NativeFriendMenu.lua"), "Modules/NativeFriendMenu.lua")
	local rows
	if nativeRoot then
		-- Execute the actual native queue, clear and insert functions, not a reimplementation.
		env.RootMenuDescriptionProxyMixin, env.MenuElementDescriptionProxyMixin = {}, {}
		env.Proxies = { ToPrivate = function(_, proxy) return proxy.private end }
		execute(between(read(nativeRoot, "Interface/AddOns/Blizzard_Menu/Menu.lua"),
			"local function ClearQueuedDescriptions(", "\n\t--[["), "Blizzard queued description insertion")
		local function proxy(kind, text)
			local value = setmetatable({ kind = kind, text = text }, { __index = env.RootMenuDescriptionProxyMixin })
			value.private = { proxy = value, items = {}, ToProxy = function(self) return self.proxy end,
				Insert = function(self, item, index) table.insert(self.items, index or #self.items + 1, item); return item end }
			function value:CreateTitle(label) return self:Insert(proxy("title", label)) end
			function value:CreateDivider() return self:Insert(proxy("divider", "")) end
			function value:CreateButton(label, callback)
				local button = proxy("button", label); button.callback = callback; return self:Insert(button)
			end
			function value:SetEnabled(enabled) self.enabled = enabled end
			return value
		end
		env.MenuUtil = { CreateTitle = function(text) return proxy("title", text) end,
			CreateDivider = function() return proxy("divider", "") end }
		local queueTitle, queueDivider = execute(between(read(nativeRoot, "Interface/AddOns/Blizzard_Menu/MenuUtil.lua"),
			"local function QueueDescription(", "MenuUtilPrivate.Utilities =") .. "\nreturn QueueTitle, QueueDivider", "Blizzard queue utilities")
		env.RootMenuDescriptionProxyMixin.QueueTitle, env.RootMenuDescriptionProxyMixin.QueueDivider = queueTitle, queueDivider
		env.MenuUtil.CreateContextMenu = function(owner, generator)
			local root = proxy("root"); generator(owner, root); rows = {}
			for _, item in ipairs(root.private.items) do rows[#rows + 1] = item.proxy end
		end
	else
		env.EasyMenu = function(items)
			rows = {}
			for _, item in ipairs(items) do
				rows[#rows + 1] = { text = item.text, kind = item.isTitle and "title" or (item.text == "" and "divider" or "button"),
					enabled = not item.disabled, callback = item.func }
			end
		end
	end
	for _, helper in ipairs({ "PopoutChat", "SetNote", "SetCustomTitleFriendName", "UpgradeTitleFriend", "RecentAllyNativeButtons",
		"ViewBNetFriends", "DeleteCommunityMessage", "Favorite", "RemoveFriend", "IgnoreOrBlock", "ReportButtons", "PvpReportAfk" }) do
		env["BFL_Add" .. helper .. "Button"] = function() end
	end
	env.BFL_AddRecentAllyNativeButtons, env.BFL_AddReportButtons = function() end, function() end
	env.BFL_AddSetNoteButton = function(root) root:CreateButton("Set Note") end
	env.BFL_AddFavoriteButton = function(root) root:CreateButton("Add to Favorites") end
	env.BFL_AddRemoveFriendButton = function(root) root:CreateButton("Remove Friend") end
	env.BFL_BuildCopyNameHandler = function() return function() end end
	env.BFL_FindBNetFriendData = function()
		return { invitableAccounts = { { playerGuid = "Player-42" } } }, { BuildAccountDisplay = function(_, account) return account end }
	end
	execute(between(source, "local function BFL_AddRafSummonButton(", "local function BFL_AddFavoriteButton(")
		.. between(source, "local function BFL_AddInviteButton(", "local function BFL_GetBNetAccountInfo(")
		.. between(source, "function BFL:OpenBetterFriendlistContextMenu(", "\n\t\t\tif Menu and Menu.ModifyMenu then"), "Production context menu and interaction actions")
	return { BFL = BFL, env = env, rows = function() return rows end, execute = execute }
end
for _, backend in ipairs({ forever, classic, false }) do
	local context = setup(backend)
	for _, fixture in ipairs({
		{ menu = "BN_FRIEND_OFFLINE", level = 3, interact = false },
		{ menu = "BN_FRIEND_OFFLINE", level = 1, interact = false },
		{ menu = "BN_FRIEND_OFFLINE", level = 2, interact = false },
		{ menu = "FRIEND_OFFLINE", interact = false },
		{ menu = "BN_FRIEND", level = 3, interact = true, invite = true },
		{ menu = "FRIEND", interact = true, invite = true },
		{ menu = "BN_FRIEND_OFFLINE", level = 3, houses = true, interact = true },
		{ menu = "FRIEND", who = true, restricted = true, interact = true, invite = true },
	}) do
		context.env.UNIT_VIEW_HOUSES = fixture.houses and "View Houses" or nil
		context.BFL.CanSendWhisper = function() return not fixture.restricted end
		context.BFL.InviteUnit = function() end
		local data = { name = "Ada Lovelace", friendLevel = fixture.level, bnetIDAccount = fixture.level and 42 or nil,
			bflWhoPlayerMenu = fixture.who }
		check(context.BFL:OpenBetterFriendlistContextMenu({}, fixture.menu, data, data.name), "The production context menu opens")
		local titles, buttons, currentSection = {}, {}, nil
		local rows = context.rows()
		for index, row in ipairs(rows) do
			if row.kind == "title" then
				titles[row.text], currentSection = true, row.text
				check(rows[index + 1] and rows[index + 1].kind == "button", "A visible section title always has a following action")
			elseif row.kind == "button" then
				buttons[row.text] = { section = currentSection, enabled = row.enabled }
			elseif index > 1 then
				check(rows[index - 1].kind ~= "divider", "No adjacent dividers are introduced")
			end
		end
		equal(titles.Interact == true, fixture.interact, "Interact appears exactly when it has visible actions")
		check(titles.Other and titles.BetterFriendlist and buttons["Set Note"] and buttons["Remove Friend"], "Other options and BFL actions remain present")
		if fixture.invite then equal(buttons.Invite.section, "Interact", "An online invite retains its section") end
		if fixture.houses then equal(buttons["View Houses"].section, "Interact", "Offline housing keeps Interact when an action really exists") end
		if fixture.who then
			equal(buttons.Whisper.enabled, false, "Who retains its restricted character-whisper action")
		else
			check(not buttons.Whisper, "the fallback friend menu leaves whispering to Blizzard's native menu")
		end
	end
end

for _, backend in ipairs({ forever, classic, false }) do
	local context = setup(backend)
	local BFL, env = context.BFL, context.env
	BFL.HasSecretValues = backend == forever
	BFL.L.MENU_TITLE, BFL.L.MENU_SET_NICKNAME, BFL.L.MENU_GROUPS = "BetterFriendlist", "Set Nickname", "Groups"
	env.L = BFL.L
	BFL:RegisterModule("FriendsList", {})
	local friends = BFL:GetModule("FriendsList")
	local first = { uid = "bnet_Twin#1234", type = "bnet", bnetAccountID = 41, battleTag = "Twin#1234",
		accountName = "Shared Name", gameAccountInfo = { playerGuid = "SharedGUID" } }
	local second = { uid = "bnet_Twin#5678", type = "bnet", bnetAccountID = 42, battleTag = "Twin#5678",
		accountName = "Shared Name", gameAccountInfo = { playerGuid = "SharedGUID" } }
	local character = { uid = "wow_Ada-Realm", type = "wow", name = "Ada-Realm" }
	friends.friendsList = { first, second, character }
	function friends:GetFriendUID(friend) return friend.uid end
	function friends:ResolveFriendByUID(uid) if uid == character.uid then return character end end
	function BFL:NormalizeWoWFriendName(name) return name end
	env.GetFriendsList = function() return friends end
	env.GetGroups = function() end
	env.BFL_AddGroupMembershipButtons = function() end
	env.BetterFriendlistDB = { nicknames = {}, friendGroups = {} }
	env.BFL_FindBNetFriendData = function() end
	context.execute(read(repo, "Utils/FriendNotes.lua"), "FriendNotes")
	context.execute(read(repo, "Utils/FriendActions.lua"), "FriendActions")
	context.execute(read(repo, "Modules/Database.lua"), "Database")
	context.execute(read(repo, "Modules/MenuSystem.lua"), "MenuSystem")
	BFL:GetModule("MenuSystem"):Initialize()
	local db = BFL:GetModule("DB")
	local popup
	env.StaticPopup_Show = function(_, _, _, data) popup = data end
	env.AddGroupsToFriendMenu = context.execute(
		between(source, "local function BFL_IsOwnMenuContext(", "local function BFL_BuildCopyNameHandler(")
		.. between(source, "local function AddGroupsToFriendMenu(", "local function AddRecentAllyOptions(")
		.. "\nreturn AddGroupsToFriendMenu", "Production nickname menu")
	local function Open(menu, data, verified)
		popup = nil
		check(BFL:OpenBetterFriendlistContextMenu({}, menu, data, data.name, verified), "Opens the friend menu")
		for _, row in ipairs(context.rows()) do
			if row.text == "Set Nickname" then
				row.callback()
				return popup
			end
		end
	end
	local function Rename(data, nickname, enterPressed)
		local edit = { GetText = function() return nickname end, GetParent = function() return { Hide = function() end } end }
		local dialog = env.StaticPopupDialogs.BETTER_FRIENDLIST_SET_NICKNAME
		if enterPressed then dialog.EditBoxOnEnterPressed(edit, data) else dialog.OnAccept({ EditBox = edit }, data) end
	end
	BFL.ForceRefreshFriendsList = function() end
	local edit = Open("BN_FRIEND", { bnetIDAccount = 41, name = "Shared Name", guid = "SharedGUID" })
	check(edit and edit.uid == first.uid, "An account ID resolves the first contact regardless of shared character GUID")
	Rename(edit, "First alias")
	edit = Open("BN_FRIEND_OFFLINE", { battleTag = second.battleTag, name = "Shared Name", guid = "SharedGUID" })
	check(edit and edit.uid == second.uid, "A full BattleTag resolves the second contact regardless of shared display name")
	Rename(edit, "Second alias", true)
	equal(db:GetNickname(first.uid), "First alias", "Editing the second contact leaves the first nickname in place")
	equal(db:GetNickname(second.uid), "Second alias", "The second nickname is stored under its own BattleTag")
	check(not Open("BN_FRIEND", { bnetIDAccount = 41, battleTag = second.battleTag, name = character.name }),
		"Conflicting account identifiers cannot route a nickname edit")
	check(not Open("BN_FRIEND", { name = character.name, guid = "SharedGUID" }),
		"A Battle.net menu cannot guess the contact from a character name or GUID")
	check(Open("BN_FRIEND_OFFLINE", {}, second).uid == second.uid,
		"A verified BFL row supplies the nickname target even without native context fields")
	check(Open("FRIEND_OFFLINE", { uid = character.uid }).uid == character.uid,
		"A verified BFL-owned UID works for an ungrouped character friend")
	BFL.StreamerMode = { IsActive = function() return true end, GetFriendMenuLabel = function() return "Masked" end }
	local label
	env.StaticPopup_Show = function(_, name, _, data) label, popup = name, data end
	Open("BN_FRIEND", { bnetIDAccount = 41, name = "Shared Name" })
	equal(label, "Masked", "The nickname dialog uses the Streamer Mode label")
end

io.write("[OK] Context menu sections smoke: " .. assertions .. " assertions (native Forever/Classic queue helpers and real legacy fallback; mocked widgets/C APIs)\n")
