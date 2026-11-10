
local _, BFL = ...
local L = BFL.L
local Catalog = BFL.LegacySettingsCatalog
local Review = BFL:RegisterModule("LegacySettingsReview", {})

local function Text(key)
	return L[key] or key
end

-- Lua's lower only folds ASCII on the supported WoW clients.
local upper = "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖŒÙÚÛÜÝŸАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
local lower = "àáâãäåæçèéêëìíîïñòóôõöœùúûüýÿабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local folded = {}
local utf8Letter = "[\\194-\\244][\\128-\\191]+"
local nextLower = lower:gmatch(utf8Letter)
for letter in upper:gmatch(utf8Letter) do
	folded[letter] = nextLower()
end

local function Normalize(value)
	local text = (value or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
	return (text:gsub("^%s+", ""):gsub("%s+$", ""):lower():gsub(utf8Letter, folded))
end

local function OptionalText(key)
	return BFL_LOCALE[key] or BFL_LOCALE_ENUS[key]
end

local function Label(parent, font, value)
	local label = parent:CreateFontString(nil, "ARTWORK", font)
	label:SetText(value)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(true)
	return label
end

local function ReviewIcon(parent, name, size)
	local icon = parent:CreateTexture(nil, "ARTWORK")
	icon:SetSize(size, size)
	icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\" .. name)
	icon:SetDesaturated(true)
	return icon
end

local function TextLink(parent, text, action, compact)
	local link = CreateFrame("Button", nil, parent)
	link.BFL_DarkNoButtonChrome = true
	local normal = compact and "BetterFriendlistFontNormalSmall" or "BetterFriendlistFontNormal"
	local hover = compact and "BetterFriendlistFontHighlightSmall" or "BetterFriendlistFontHighlight"
	link.label = Label(link, normal, text)
	link.label:SetWordWrap(false)
	link:SetFontString(link.label)
	link:SetNormalFontObject(normal)
	link:SetHighlightFontObject(hover)
	link.label:ClearAllPoints()
	link.label:SetPoint("LEFT")
	link:SetHeight(24)
	link:SetScript("OnClick", action)
	return link
end

local function NavigationRow(parent, text, action, indent, compact)
	local template = OptionsListButton_OnLoad and "OptionsListButtonTemplate"
	local row = CreateFrame("Button", nil, parent, template)
	if template then
		row:RegisterForClicks("LeftButtonUp")
		row:SetScript("OnEnter", nil)
		row:SetScript("OnLeave", nil)
	end
	row.BFL_DarkNoButtonChrome = true
	row:SetHeight(32)
	row:SetScript("OnClick", action)

	row.normalFont = compact and "BetterFriendlistFontHighlightSmall" or "BetterFriendlistFontHighlight"
	row.selectedFont = compact and "BetterFriendlistFontNormalSmall" or "BetterFriendlistFontNormal"
	row.labelInset = indent or 10
	if row.Text then
		row.Text:Hide()
	end
	row.label = Label(row, row.normalFont, text)
	row.label:SetPoint("LEFT", row.labelInset, 0)
	row.label:SetPoint("RIGHT", -8, 0)
	row.label:SetHeight(28)
	row.label:SetMaxLines(2)
	row.BFL_SearchLabels = { text }

	if template then
		row:GetHighlightTexture():SetVertexColor(1, 0.82, 0.3, 0.20)
	else
		local hover = row:CreateTexture(nil, "BACKGROUND")
		hover:SetAllPoints()
		hover:SetColorTexture(1, 1, 1, 0.07)
		row:SetHighlightTexture(hover)
	end

	row.legacySelection = row:CreateTexture(nil, "BACKGROUND")
	row.legacySelection:SetAllPoints()
	row.legacySelection:SetColorTexture(1, 0.82, 0.3, 0.12)
	row.legacySelection:Hide()

	row.selection = row:CreateTexture(nil, "BACKGROUND")
	row.selection:SetPoint("TOPLEFT", 2, -2)
	row.selection:SetPoint("BOTTOMRIGHT", -2, 2)
	row.selection:Hide()

	row.marker = row:CreateTexture(nil, "ARTWORK")
	row.marker:SetPoint("TOPLEFT", 0, -4)
	row.marker:SetPoint("BOTTOMLEFT", 0, 4)
	row.marker:SetWidth(2)
	row.marker:SetColorTexture(1, 0.82, 0.3, 0.9)
	row.marker:Hide()
	return row
end

function Review:ApplyModernSettingSelection(texture, alpha)
	local ui = BFL:GetModule("FriendsUI")
	if ui and ui:IsModernActive() and BFL.SetTextureOrAtlas(texture, "friends-card-selected") then
		texture:SetVertexColor(1, 1, 1, alpha or 0.75)
		texture:SetBlendMode("ADD")
		return true
	end
	return false
end

local function LayoutNavigationSelection(row)
	local modern = row.selected and Review:ApplyModernSettingSelection(row.selection)
	local legacy = row.selected and not modern
	row.selection:SetShown(modern)
	row.legacySelection:SetShown(legacy)
	row.marker:SetShown(legacy)
end

local function SelectNavigationRow(row, selected, parentSelected)
	row.selected = selected
	LayoutNavigationSelection(row)
	row.label:SetFontObject((selected or parentSelected) and row.selectedFont or row.normalFont)
	row.label:SetJustifyH("LEFT")
end

local function PositionContentRow(row, parent)
	row:ClearAllPoints()
	row:SetPoint("LEFT", parent, "LEFT", 8, 0)
	row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
end

local function TopText(parent, font, text, left, top)
	local label = Label(parent, font, text)
	label:SetPoint("TOPLEFT", left, -top)
	return label
end

local function ReadPoints(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = { frame:GetPoint(i) }
	end
	return points
end

local function RestorePoints(frame, points)
	frame:ClearAllPoints()
	for _, point in ipairs(points) do
		frame:SetPoint(unpack(point))
	end
end

local function GetRouteCategory(route)
	for _, category in ipairs(Catalog.categories) do
		for i = 3, #category do
			if category[i] == route then
				return category
			end
		end
	end
	return Catalog.categories[1]
end

local function BuildFriends(renderer, mixedGames, queueExamples, allTags)
	local realm = Text("SETTINGS_LEGACY_SAMPLE_REALM")
	local zone = Text("SETTINGS_LEGACY_SAMPLE_ZONE")
	local samples = BFL.LegacySettingsSocialSamples
	local aster = samples:CharacterName("SETTINGS_LEGACY_SAMPLE_ONLINE")
	local evergreen = samples:CharacterName("SETTINGS_LEGACY_SAMPLE_LONG")
	local clover = samples:CharacterName("SETTINGS_LEGACY_SAMPLE_OFFLINE")
	local classes = LOCALIZED_CLASS_NAMES_FEMALE or LOCALIZED_CLASS_NAMES_MALE or {}
	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 60
	local playerLevel = (UnitEffectiveLevel and UnitEffectiveLevel("player")) or (UnitLevel and UnitLevel("player")) or maxLevel
	-- A non-trivial level makes the difficulty color visible even when max-level numbers are hidden.
	local sampleLevel = math.max(1, math.min(maxLevel - 1, playerLevel + 3))
	local faction = UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
	local opposite = faction == "Horde" and "Alliance" or "Horde"
	local project = BFL.IsForever and (WOW_PROJECT_CAMELOT or 18) or WOW_PROJECT_ID
	local wow = BNET_CLIENT_WOW or "WoW"
	local gameName = WORLD_OF_WARCRAFT or "World of Warcraft"

	local function WoWAccount(id, name, classFile, classID, level, characterFaction)
		return {
			gameAccountID = id,
			isOnline = true,
			clientProgram = wow,
			characterName = name,
			className = classes[classFile] or classFile,
			classFilename = classFile,
			classID = classID,
			characterLevel = level,
			factionName = characterFaction,
			areaName = zone,
			realmName = BFL.IsForever and "PVE" or realm,
			wowProjectID = project,
			gameName = gameName,
			_previewTitleIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-wow",
		}
	end

	local main = WoWAccount(1, aster, "MAGE", 8, sampleLevel, faction)
	local alt = WoWAccount(2, clover, "DRUID", 11, maxLevel, faction)
	local friends = {
		{
			type = "bnet", connected = true, battleTag = Text("SETTINGS_LEGACY_SAMPLE_ONLINE") .. "#1234", accountName = Text("SETTINGS_LEGACY_SAMPLE_ONLINE") .. " " .. Text("SETTINGS_LEGACY_SAMPLE_OFFLINE"),
			characterName = main.characterName, level = main.characterLevel, className = main.className,
			classFilename = main.classFilename, classID = main.classID, factionName = main.factionName,
			realmName = main.realmName, areaName = main.areaName, gameName = gameName,
			gameAccountInfo = main, gameAccountID = main.gameAccountID, gameAccounts = { main, alt }, numGameAccounts = 2,
			isFavorite = true, sampleNickname = clover, note = zone, canInvite = true, _isMock = true,
		},
		{
			type = "wow", connected = true, name = evergreen .. "-" .. realm, characterName = evergreen,
			level = maxLevel, className = classes.WARRIOR or "Warrior", classFilename = "WARRIOR",
			classID = 1, factionName = opposite, realmName = BFL.IsForever and "PVP" or realm,
			area = zone, wowProjectID = project, sampleTags = true, sampleTagLimit = not allTags and 3 or nil, sampleNickname = aster, note = zone,
		},
		{
			type = "bnet", connected = true, battleTag = Text("SETTINGS_LEGACY_SAMPLE_LONG") .. "#1234", accountName = evergreen,
			gameName = L.STATUS_MOBILE, sampleNickname = evergreen, _isMock = true,
			gameAccountInfo = {
				isOnline = true, clientProgram = "BSAp",
				_previewTitleIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-battlenet",
			},
		},
		{
			type = "bnet", connected = false, battleTag = Text("SETTINGS_LEGACY_SAMPLE_OFFLINE") .. "#1234", accountName = clover,
			lastOnlineTime = time() - 86400, sampleNickname = clover,
		},
	}

	if mixedGames then
		local account = {
			isOnline = true, clientProgram = "WTCG",
			_previewTitleIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\title-icon-hearthstone",
		}
		friends[#friends + 1] = {
			type = "bnet", connected = true, accountName = clover, battleTag = Text("SETTINGS_LEGACY_SAMPLE_ONLINE") .. "#5678",
			gameName = "Hearthstone", gameAccountInfo = account, gameAccounts = { account },
			_isMock = true,
		}
	end
	if queueExamples then
		local account = WoWAccount(3, clover, "DRUID", 11, math.max(1, maxLevel - 5), faction)
		friends[1].sampleQueueStatus = "inqueue"
		friends[1].isAFK = true
		friends[2].isDND = true
		friends[#friends + 1] = {
			type = "bnet", connected = true, accountName = clover, battleTag = Text("SETTINGS_LEGACY_SAMPLE_OFFLINE") .. "#5678",
			characterName = account.characterName, level = account.characterLevel, className = account.className,
			classFilename = account.classFilename, classID = account.classID, factionName = account.factionName,
			realmName = account.realmName, areaName = account.areaName, gameName = gameName,
			gameAccountInfo = account, sampleQueueStatus = "availableforqueue", _isMock = true,
		}
	end

	local entries = {}
	for index, friend in ipairs(friends) do
		friend.uid = "bfl_settings_example_" .. index
		renderer:ApplyMobileFriendState(friend, friend.gameAccountInfo)
		entries[index] = {
			friend = friend,
			uid = friend.uid,
			isFavorite = friend.isFavorite,
			addedAge = index == 4 and 2 * 3600 or index == 2 and 8 * 86400 or nil,
		}
	end
	return entries
end

local function BuildFriendsBrokerSample(renderer)
	local friends = {}
	for _, entry in ipairs(BuildFriends(renderer, false)) do
		local friend = entry.friend
		if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp" then break end
		friend.id = entry.uid
		friend.settingsSample = true
		if friend.gameAccountInfo then
			friend.client = friend.gameAccountInfo.clientProgram
			friend.area = friend.gameAccountInfo.areaName
		end
		friend.fullName = friend.name
		friends[#friends + 1] = friend
	end
	friends[1].isAFK = true
	return {
		friends = friends,
		groups = {
			favorites = { name = Text("GROUP_FAVORITES"), color = { r = 1, g = 0.82, b = 0 } },
			nogroup = { name = Text("GROUP_NO_GROUP"), color = { r = 0.65, g = 0.65, b = 0.65 } },
		},
		groupOrder = { "favorites", "nogroup" },
	}
end

function Review:RenderBrokerSample(width)
	local titleContainer = self.previewShell.TitleContainer
	local scene = self.brokerSample
	if not scene then
		scene = CreateFrame("Frame", nil, self.preview)
		scene:SetAllPoints(self.preview)
		scene.display = Label(titleContainer or scene, "BetterFriendlistFontHighlightSmall", "")
		scene.display:SetWordWrap(false)
		scene.display:SetJustifyH("CENTER")
		scene.display:SetPoint("TOPLEFT", scene, "TOPLEFT", 8, -1)
		scene.display:SetPoint("TOPRIGHT", scene, "TOPRIGHT", -8, -1)
		scene.display:SetHeight(22)
		scene.summary = Label(scene, "BetterFriendlistFontHighlightSmall", "")
		scene.summary:SetJustifyH("CENTER")
		scene.surface = CreateFrame("Frame", nil, scene)
		scene.surface:SetPoint("TOP", scene, "TOP", 0, -29)
		scene.surface:SetSize(width, 1)
		scene.summary:SetPoint("TOP", scene.surface, "BOTTOM", 0, -4)
		self.brokerSample = scene
	end
	scene:Show()
	self.previewTitle:Hide()
	self.previewRule:SetShown(not titleContainer)
	if titleContainer then titleContainer:Show() end
	scene.display:Show()

	local guild = self.sample == "guildBroker"
	local broker = BFL:GetModule(guild and "GuildBroker" or "Broker")
	local sample
	if guild then
		self.guildBrokerSampleData = self.guildBrokerSampleData or BFL.LegacySettingsSocialSamples:BuildGuildBrokerSample()
		sample = self.guildBrokerSampleData
	else
		sample = BuildFriendsBrokerSample(self.sampleContext)
	end
	sample.tooltip = scene.tooltip
	local tt, label, icon, summary = broker:RenderSettingsSample(scene.surface, sample)
	scene.tooltip = tt
	if not tt then
		return
	end

	scene.display:SetText((icon and ("|T" .. icon .. ":16:16|t  ") or "") .. label)
	scene.summary:SetWidth(width)
	scene.summary:SetText(summary or "")
	scene.summary:SetShown(summary ~= nil)
	local previewHeight = math.min(270, self.sampleHeightLimit)
	local summaryHeight = summary and (scene.summary:GetStringHeight() + 4) or 0
	local tooltipWidth, tooltipHeight = tt:GetWidth(), tt:GetHeight()
	local maxTooltipHeight = math.max(1, previewHeight - 29 - 7 - summaryHeight)
	local scale = math.min(1, width / math.max(1, tooltipWidth), maxTooltipHeight / math.max(1, tooltipHeight))
	tt:SetScale(scale)
	scene.surface:SetSize(tooltipWidth * scale, tooltipHeight * scale)
	self.preview:SetHeight(previewHeight)
end

local sampleGroups = {
	{ id = "favorites", label = "GROUP_FAVORITES", count = 1, total = 1 },
	{ id = "ingame", label = "GROUP_INGAME", count = 1, online = 2, total = 3, collapsed = true },
	{ id = "recentlyadded", label = "GROUP_RECENTLY_ADDED", count = 1, total = 1 },
	{ id = "nogroup", label = "GROUP_NO_GROUP", count = 0, total = 0 },
}

local function BuildGroups(db, friends, automatic, targetID, renderer)
	local Groups = BFL:GetModule("Groups")
	local colors = db:Get("groupColors") or {}
	local countColors = db:Get("groupCountColors") or {}
	local arrowColors = db:Get("groupArrowColors") or {}
	local hideEmpty = db:Get("hideEmptyGroups", false)
	local order = {}
	for index, id in ipairs(db:Get("groupOrder") or {}) do
		order[id] = index
	end
	local enabled = {
		favorites = db:Get("showFavoritesGroup", true),
		ingame = db:Get("enableInGameGroup", false),
		recentlyadded = db:Get("enableRecentlyAddedGroup", false),
		nogroup = true,
	}
	local groupNames = db:Get("builtinGroupOverrides") or {}
	local registry = automatic and BFL:GetModule("FilterSortRegistry")
	local filter = db:Get("quickFilter", "all")
	-- Queue filters depend on native Battle.net result snapshots.
	if (filter == "inqueue" or filter == "availableforqueue") and not (friends[1] and friends[1].friend.sampleQueueStatus) then
		filter = "all"
	end
	local sortPlan = registry and registry:CreateSortPlan(db:Get("primarySort", "status"), db:Get("secondarySort", "name"))
	local recent = automatic and BFL:GetModule("RecentlyAdded")
	local duration = recent and recent:GetDurationSeconds(db) or 0
	local mode = db:Get("inGameGroupMode", "same_game")
	local accordion = automatic and db:Get("accordionGroups", false)
	local data = {}
	local hiddenEmpty = false

	local function GetMembers(id)
		local members, total, online, visibleOnline = {}, 0, 0, 0
		for _, entry in ipairs(friends) do
			local friend = entry.friend
			local matches = id == "bfl_settings_group"
				or (id == "favorites" and friend.isFavorite)
				or (id == "ingame" and renderer:IsFriendInGameForGroup(friend, mode))
				or (id == "recentlyadded" and recent and entry.addedAge and recent:IsWithinDuration(entry.addedAge, duration))
			if matches then
				total = total + 1
				if friend.connected then
					online = online + 1
				end
				if not registry or registry:EvaluateQuickFilter(filter, friend) then
					members[#members + 1] = entry
					if friend.connected then
						visibleOnline = visibleOnline + 1
					end
				end
			end
		end
		if sortPlan then
			table.sort(members, function(a, b)
				return registry:CompareFriendsWithSortPlan(a.friend, b.friend, sortPlan)
			end)
		end
		return members, total, online, visibleOnline
	end
	local function Add(group, index)
		local id = group.id
		local style = Groups and Groups:Get(id)
		local configuredName = groupNames[id] and groupNames[id].name
		local color = colors[id] or (style and style.color) or (Groups and Groups:GetBuiltinDefaultColor(id))
		local total = group.total
		local online = group.online or group.count
		local count = group.count
		local members
		local collapsed = group.collapsed == true or (accordion and #data > 0)
		if automatic then
			local visibleOnline
			members, total, online, visibleOnline = GetMembers(id)
			count = #members
			if hideEmpty and visibleOnline == 0 then
				hiddenEmpty = true
				return
			elseif count == 0 and filter ~= "all" then
				return
			end
		elseif count > 0 then
			members = { friends[group.friendIndex or 1] }
		end
		collapsed = collapsed or count == 0
		data[#data + 1] = {
			groupId = id,
			name = configuredName or group.name or Text(group.label),
			count = count,
			onlineCount = online,
			totalCount = total,
			collapsed = collapsed,
			order = order[id] or (1000 + index),
			sampleColors = {
				color = color,
				countColor = countColors[id] or (style and style.countColor) or color,
				arrowColor = arrowColors[id] or (style and style.arrowColor) or color,
			},
			exampleFriends = not collapsed and members or nil,
		}
	end
	if automatic then
		Add({ id = "bfl_settings_group", label = "SETTINGS_LEGACY_SAMPLE_ZONE", count = 1, total = 1 }, 0)
	end
	local shownTarget = false
	for index, group in ipairs(sampleGroups) do
		local id = group.id
		if id == targetID or (automatic and enabled[id]) or (not automatic and (id ~= "recentlyadded" or enabled[id])) then
			if group.total == 0 and hideEmpty and id ~= targetID then
				hiddenEmpty = true
			else
				Add(group, index)
				shownTarget = shownTarget or id == targetID
			end
		end
	end
	if targetID and not shownTarget then
		local target = Groups and Groups:Get(targetID)
		if target then
			Add({ id = targetID, name = target.name, count = 1, total = 1, friendIndex = 2 }, 5)
		end
	end
	if #data == 0 and not automatic then
		-- Keep a representative non-empty header when all automatic groups are off.
		Add({ id = "bfl_settings_group", label = "SETTINGS_LEGACY_SAMPLE_ZONE", count = 1, total = 1, friendIndex = 2 }, 6)
	end
	table.sort(data, function(a, b) return a.order < b.order end)
	return data, hiddenEmpty
end

function Review:PreviewGroup(groupId)
	if self.active and self.sample == "groups" then
		self.sampleGroupID = groupId
		if self.sampleViewport then self.sampleViewport:SetVerticalScroll(0) end
		self:QueueSample()
	end
end

function Review:RenderHeaderSample(width, sampleDB, sampleTop, sampleStreamer)
	local friendsUI = BFL:GetModule("FriendsUI")
	local modern = friendsUI and friendsUI:IsModernActive()
	if sampleDB and sampleDB:Get("sampleInterfaceStyle") then
		modern = sampleDB:Get("sampleInterfaceStyle") == "modern"
	end
	local db = sampleDB or BFL:GetModule("DB")
	local simple = db:Get("simpleMode", false)
	local buttonShown = db:Get("showStreamerModeButton", true)
	local streamer = BFL:GetModule("StreamerMode")
	local streamerActive = sampleStreamer
	if streamerActive == nil then
		streamerActive = self.sampleContext.settingsSampleStreamerMode or streamer:IsActive() == true
	end
	local scene = self.headerSample
	if not scene then
		scene = CreateFrame("Frame", nil, sampleDB and self or self.preview)
		scene.title = Label(scene, "BetterFriendlistFontNormal", "BetterFriendlist")
		scene.title:SetWordWrap(false)
		scene.tag = CreateFrame("Frame", nil, scene, "BFLBattleNetTagVisualTemplate")
		scene.tag.Tag:SetWordWrap(false)
		scene.tag.Tag:SetMaxLines(1)
		scene.streamer = CreateFrame("Button", nil, scene, "BFLStreamerModeButtonVisualTemplate")
		scene.streamer:EnableMouse(false)
		scene.searchRow = CreateFrame("Frame", nil, scene)
		scene.search = CreateFrame("EditBox", nil, scene.searchRow, "SearchBoxTemplate")
		scene.search:SetAutoFocus(false)
		scene.search:EnableMouse(false)
		scene.legacyPortrait = scene:CreateTexture(nil, "ARTWORK")
		scene.legacyPortrait:SetSize(42, 42)
		scene.legacyPortrait:SetPoint("TOPLEFT", 0, 0)
		if SetPortraitToTexture then
			SetPortraitToTexture(scene.legacyPortrait, "Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
		end
		self.headerSample = scene
	end
	scene:ClearAllPoints()
	scene:SetPoint("TOPLEFT", sampleTop and 0 or 8, -(sampleTop or 35))
	if modern and not scene.native then
		local native = CreateFrame("Frame", nil, scene, "ButtonFrameTemplate")
		native.BFL_DarkManagedSubtree = true
		native:SetPoint("TOPLEFT")
		native:SetPoint("TOPRIGHT")
		if native.Inset then native.Inset:Hide() end
		if native.CloseButton then native.CloseButton:SetScript("OnClick", nil) end
		native:EnableMouse(false)
		local title = native.TitleContainer and native.TitleContainer.TitleText or native.TitleText
		if title then title:SetText("BetterFriendlist") end

		local surface = CreateFrame("Frame", nil, native, "BFLModernFriendsSurfaceTemplate")
		surface:SetAllPoints(native)
		local mask = surface:CreateMaskTexture()
		mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetPoint("TOPLEFT", native, "TOPLEFT", 4, 0)
		mask:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", -4, 4)
		surface.TopFade:AddMaskTexture(mask)
		surface.BottomFade:AddMaskTexture(mask)
		scene.topSurface = surface

		local bar = CreateFrame("Frame", nil, surface, "BFLModernBattleNetBarSurfaceTemplate")
		local background = native.Bg or native
		bar:SetPoint("TOPLEFT", background, "TOPLEFT", -3, -1)
		bar:SetPoint("TOPRIGHT", background, "TOPRIGHT", 3, -1)
		bar.MenuButton:EnableMouse(false)
		bar.CopyBattleTagButton:EnableMouse(false)
		scene.native = native
		scene.battleNet = bar
		scene.PortraitOverlay = CreateFrame("Frame", nil, native, "BFLModernPortraitVisualTemplate")
		scene.PortraitOverlay:SetFrameLevel(bar:GetFrameLevel() + 1)

		scene.StatusDropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
		scene.StatusDropdown:EnableMouse(false)
		if scene.StatusDropdown.Arrow then scene.StatusDropdown.Arrow:EnableMouse(false) end
		-- Keep the status icon separate from the dropdown artwork replaced by the skin.
		local statusOverlay = CreateFrame("Frame", nil, scene.StatusDropdown)
		statusOverlay:SetAllPoints()
		local statusIcon = statusOverlay:CreateTexture(nil, "OVERLAY")
		BFL.SetTextureOrAtlas(statusIcon, "friends-status-busy", "Interface\\FriendsFrame\\StatusIcon-DnD")
		statusIcon:SetSize(19, 19)
		statusIcon:SetPoint("CENTER", scene.StatusDropdown, "LEFT", 19, 0)
		scene.statusIcon = statusIcon

		scene.sort = CreateFrame("DropdownButton", nil, scene.searchRow, "WowStyle1FilterDropdownTemplate")
		scene.sort.resizeToText = false
		scene.sort:SetSize(92, 29)
		scene.sort:SetPoint("RIGHT", -7, 0)
		scene.sort:EnableMouse(false)
		BFL.SetDropdownText(scene.sort, SORT or (SORT_BY or L.RAID_TOOLS_SORT_HEADER):gsub(":%s*$", ""))
		scene.filter = CreateFrame("DropdownButton", nil, scene.searchRow, "WowStyle1FilterDropdownTemplate")
		scene.filter.resizeToText = false
		scene.filter:SetSize(92, 29)
		scene.filter:SetPoint("RIGHT", scene.sort, "LEFT", -7, 0)
		scene.filter:EnableMouse(false)
		BFL.SetDropdownText(scene.filter, FILTER or "")
	end

	scene:SetWidth(width)
	scene.title:ClearAllPoints()
	scene.title:SetPoint("TOPLEFT", simple and 4 or 50, -3)
	scene.title:SetPoint("TOPRIGHT", -29, -3)
	scene.title:SetShown(not modern)
	scene.legacyPortrait:SetShown(not modern and not simple)
	if scene.native then scene.native:SetShown(modern == true) end

	local tag = scene.tag
	local toggle = scene.streamer
	local streamerText = db:Get("streamerModeHeaderText", L.STREAMER_MODE_TITLE)
	local sampleTag = L.SETTINGS_LEGACY_SAMPLE_ONLINE .. "#1234"
	if modern then
		local native, bar = scene.native, scene.battleNet
		tag:SetParent(bar)
		scene.BattlenetFrame = tag
		tag.Tag:SetText(friendsUI:FormatBattleTagDisplay(sampleTag, streamerActive, streamerText))
		tag.Tag:SetWidth(math.min(tag.Tag:GetUnboundedStringWidth() + 1, math.max(1, width - 210)))
		friendsUI:ApplyModernPortrait(native, scene, simple)
		friendsUI:LayoutBattleTagActions(bar, scene, toggle)
		local palette, themed = friendsUI:GetModernThemeColors()
		friendsUI:ApplyBattleNetHeaderTheme(bar, tag, scene.StatusDropdown, palette, themed)
		friendsUI:ApplyModernContactSurfaceTheme(scene.topSurface, palette, themed)
		local engine = themed and not palette.externalShell and BFL:GetModule("SkinEngine")
		local dark = engine and engine:IsActive() and BFL:GetModule("DarkTheme")
		if dark then
			if not (native.BFL_DarkBackdrop and native.BFL_DarkBackdrop:IsShown()) then
				dark:SkinModernFrameShell(engine, native)
			end
			engine:StyleBackdrop(native, palette.background, palette.border)
		end
		-- The theme hooks the close button for hover feedback. Keep the sample inert.
		if native.CloseButton then native.CloseButton:EnableMouse(false) end
		tag.Tag:SetTextColor(unpack(themed and (palette.battleTagText or palette.text) or { 0.345, 0.667, 0.867 }))
	else
		tag:SetParent(scene)
		tag:ClearAllPoints()
		tag:SetWidth(math.min(width - 12, BFL.IsClassic and 160 or 190))
		tag.Tag:SetWidth(math.max(1, tag:GetWidth() - 12))
		tag:SetPoint("TOP", scene, "TOP", 0, -25)
		tag.Tag:SetText(streamerActive and streamerText or sampleTag)
		tag.Tag:SetTextColor(0.345, 0.667, 0.867)
		tag.Background:Show()
		toggle:SetParent(scene)
		toggle:ClearAllPoints()
		toggle:SetSize(24, 24)
		toggle:SetPoint("TOPRIGHT", -4, 2)
	end
	tag:SetShown(modern or not simple)
	toggle:SetShown(buttonShown)
	streamer:ApplyToggleButtonVisualState(toggle, streamerActive)

	local showSearch = not simple or db:Get("simpleModeShowSearch", true)
	scene.searchRow:SetShown(showSearch)
	if scene.filter then
		scene.filter:SetShown(modern and not simple)
		scene.sort:SetShown(modern and not simple)
	end
	if modern then
		scene.searchRow:SetParent(scene.topSurface)
		scene.searchRow:SetHeight(50)
		friendsUI:ConstrainModernDropdownText(scene.filter, 1)
		friendsUI:ConstrainModernDropdownText(scene.sort, 1)
		friendsUI:LayoutModernContactTopSurface(scene.topSurface, scene.native, scene.battleNet, scene.searchRow)
		friendsUI:LayoutModernContactBottomFade(scene.topSurface, scene.native)
		friendsUI:LayoutModernContactSearch(scene.search, scene.searchRow, scene.filter, simple)
		-- The Battle.net strip starts 22 pixels below the title. The search row
		-- overlaps the bottom 5 pixels, where the native content fade begins.
		scene:SetHeight(22 + scene.battleNet:GetHeight() + (showSearch and scene.searchRow:GetHeight() - 5 or 0))
	else
		local y = simple and 23 or 57
		scene.searchRow:SetParent(scene)
		scene.searchRow:ClearAllPoints()
		scene.searchRow:SetPoint("TOPLEFT", 0, -y)
		scene.searchRow:SetPoint("TOPRIGHT", 0, -y)
		scene.searchRow:SetHeight(28)
		scene.search:ClearAllPoints()
		scene.search:SetPoint("LEFT", 8, 0)
		scene.search:SetPoint("RIGHT", -4, 0)
		scene.search:SetHeight(simple and 22 or 28)
		if scene.search.Instructions then scene.search.Instructions:SetText(SEARCH or "") end
		scene:SetHeight(y + (showSearch and scene.searchRow:GetHeight() or 0))
	end
	if sampleDB and scene.native then scene.native:SetHeight(scene:GetHeight()) end
	scene:Show()
	return scene:GetHeight() + 5, modern and scene.native or nil
end

local function PrepareFilterSamples(data)
	for index, item in ipairs(data) do
		local friend = item.friend
		friend.settingsSample = true
		friend.index = index
		friend.sampleGroupIDs = { friend.isFavorite and "favorites" or "nogroup" }
		friend.sampleRecentlyAdded = index == 2 and 1 or nil
		if friend.sampleTags then
			local tags = BFL:GetModule("FriendTags")
			if tags and tags:CanDisplayTags("search") then
				local labels, sources = {}, {}
				for _, tag in ipairs(tags:GetAllTagDefinitions()) do
					if tags:ShouldIncludeTagOnSurface(tag, "search") then
						labels[#labels + 1] = tag.name
						if tag.source then sources[tag.source] = true end
					end
				end
				friend.sampleTagText = table.concat(labels, " ")
				friend.sampleTagCount = #labels
				friend.sampleTagSource = sources.blizzard and (sources.custom and "blizzard custom" or "blizzard")
					or (sources.custom and "custom" or "")
			end
		end
	end
end

function Review:ApplyFilterSample(data, db)
	local Registry = BFL:GetModule("FilterSortRegistry")
	local tab = self.content.FilterSortTab
	local sorting = tab and tab.bflBuilderKind == "sorter"
	local primary = db:Get("primarySort", Registry.FALLBACK_PRIMARY_SORT)
	local secondary = db:Get("secondarySort", Registry.FALLBACK_SECONDARY_SORT)
	local filter = Registry.FALLBACK_FILTER
	local label
	if sorting then
		primary = tab.bflSelectedSorterId or primary
		label = Registry:GetSorterText(primary)
	else
		filter = tab and tab.bflSelectedFilterId or filter
		label = Registry:GetQuickFilterText(filter)
	end

	PrepareFilterSamples(data)
	local results = {}
	for _, item in ipairs(data) do
		if sorting or Registry:EvaluateQuickFilter(filter, item.friend) then
			results[#results + 1] = item
		end
	end
	local plan = Registry:CreateSortPlan(primary, secondary, sorting)
	table.sort(results, function(a, b) return Registry:CompareFriendsWithSortPlan(a.friend, b.friend, plan) end)

	local title = self.filterSampleLabel
	if not title then
		title = TopText(self.preview, "BetterFriendlistFontNormalSmall", "", 8, 35)
		title:SetPoint("TOPRIGHT", -8, -35)
		title:SetMaxLines(1)
		self.filterSampleLabel = title
	end
	title:SetText(label)
	title:Show()
	local note = not sorting and string.format(L.FILTER_BUILDER_PREVIEW_COUNT, #results, #data) or nil
	return results, note
end

function Review:ReleaseSample()
	if self.sampleTimer then
		self.sampleTimer:Cancel()
		self.sampleTimer = nil
	end
	for _, widget in pairs(self.sampleWidgets) do
		widget:Hide()
		widget:ClearAllPoints()
		widget.elementData = nil
		widget.friendData = nil
	end
	if self.favoriteHighlight then self.favoriteHighlight:Hide() end
	if self.sampleContext then
		wipe(self.sampleContext.displayNameCache)
		self.sampleContext.settingsSampleStreamerMode = nil
	end
	if self.brokerSample then
		BFL.BrokerUtils.ReleaseSettingsTooltip(self.brokerSample.tooltip)
		self.brokerSample.tooltip = nil
		self.brokerSample.display:Hide()
		self.brokerSample:Hide()
		self.previewTitle:Show()
		self.previewRule:Show()
		if self.previewShell.TitleContainer then self.previewShell.TitleContainer:Hide() end
	end
	self.guildBrokerSampleData = nil
	BFL.LegacySettingsSocialSamples:Hide(self.preview)
	if self.headerSample then self.headerSample:Hide() end
	if self.filterSampleLabel then self.filterSampleLabel:Hide() end
	if self.sampleViewport then
		self.sampleViewport:SetVerticalScroll(0)
		self.sampleViewport:Hide()
	end
	self.preview:Hide()
	self.previewShell:Show()
end

function Review:GetSampleViewport()
	if not self.sampleViewport then
		local viewport = self.settings:CreateSettingsScrollFrame(self.preview)
		local rows = CreateFrame("Frame", nil, viewport)
		viewport:SetScrollChild(rows)
		self.sampleViewport = viewport
		self.sampleRows = rows
	end
	return self.sampleViewport, self.sampleRows
end

function Review:RenderSample()
	local FriendsList = BFL:GetModule("FriendsList")
	local db = BFL:GetModule("DB")
	if not (self.sample and FriendsList and db and self.preview:IsShown()) then
		return
	end
	local width = math.max(1, self.preview:GetWidth() - 16)
	if self.sample == "broker" or self.sample == "guildBroker" then
		self.previewNote:Hide()
		self.sampleNext:Hide()
		if self.sample == "broker" then
			self.sampleContext = self.sampleContext or FriendsList:CreateSettingsSampleContext(self.preview)
			self.sampleContext:UpdateSettingsCache()
		end
		self:RenderBrokerSample(width)
		return
	end
	local maxSocialHeight = math.max(50, self.sampleHeightLimit - 42)
	local socialHeight = BFL.LegacySettingsSocialSamples:Show(self.sample, self.preview, width, db, maxSocialHeight, self.singleSample)
	if socialHeight then
		self.sampleNext:Hide()
		self.previewNote:Hide()
		self.preview:SetHeight(socialHeight)
		return
	end
	self.sampleContext = self.sampleContext or FriendsList:CreateSettingsSampleContext(self.preview)
	self.sampleContext.settingsSampleStreamerMode = self.route == "stream" and true or nil
	self.sampleContext:UpdateSettingsCache()
	local previewFilters = self.sample == "filters"
	local data = BuildFriends(self.sampleContext, self.route == "automatic" or previewFilters, previewFilters, self.route == "tags")
	local hiddenEmpty
	local filterNote
	if self.sample == "groups" then
		data, hiddenEmpty = BuildGroups(db, data, self.route == "automatic", self.sampleGroupID, self.sampleContext)
	end
	local y = 35
	if self.sample == "filters" then
		data, filterNote = self:ApplyFilterSample(data, db)
		y = y + 19
	end
	local nativeFrame, frameInset
	if self.route == "layout" or self.route == "stream" then
		local headerHeight
		headerHeight, nativeFrame = self:RenderHeaderSample(width)
		y = y + headerHeight
		frameInset = nativeFrame and 8
		if frameInset then width = math.max(1, width - frameInset * 2) end
	end
	self.previewShell:SetShown(not nativeFrame)
	if self.route == "rowFonts" then
		local friendsUI = BFL:GetModule("FriendsUI")
		if not friendsUI or not friendsUI:IsModernActive() then
			y = y + BFL.LegacySettingsSocialSamples:ShowLegacyTabFonts(self.preview, width, y)
		elseif self.preview.legacyTabFonts then
			self.preview.legacyTabFonts:Hide()
		end
	end
	local note = filterNote
	if #data == 0 and not filterNote then
		note = L.SETTINGS_LEGACY_NO_RESULTS
	elseif hiddenEmpty then
		note = L.SETTINGS_LEGACY_SAMPLE_EMPTY_HIDDEN
	elseif self.route == "rows" then
		local format, disabled, isDefault = db:GetInfoFormatString()
		if disabled or (not isDefault and not (format and format:lower():find("%level%", 1, true))) then
			note = L.SETTINGS_LEGACY_SAMPLE_LEVEL_HINT
		end
	end
	self.previewNote:SetText(note or "")
	self.previewNote:SetWidth(width)
	self.previewNote:SetShown(note ~= nil)
	local noteHeight = note and (self.previewNote:GetStringHeight() + 6) or 0
	local heightLimit = math.max(42, self.sampleHeightLimit - y - noteHeight - 7 - (frameInset or 0))
	local entryHeights, totalHeight = {}, 0
	for index, entry in ipairs(data) do
		local height = self.sampleContext:GetSettingsSampleRowHeight(index, entry, width)
		for _, example in ipairs(entry.exampleFriends or {}) do
			height = height + self.sampleContext:GetSettingsSampleRowHeight(index, example, width)
		end
		entryHeights[index] = height
		totalHeight = totalHeight + height
	end

	local single = self.singleSample or (not self.sampleDocked and totalHeight > heightLimit)
	local selection = math.max(1, math.min(self.sampleIndex, #data))
	if single and self.sampleGroupID then
		for index, entry in ipairs(data) do
			if entry.groupId == self.sampleGroupID then
				selection = index
				break
			end
		end
	end
	local first = single and selection or 1
	if single and self.route == "rows" and self.favoriteHovered then first = 1 end
	local last = single and math.min(first, #data) or #data
	local sceneHeight = single and (entryHeights[first] or 0) or totalHeight
	local rowWidth = sceneHeight > heightLimit and math.max(1, width - 20) or width
	self.sampleNext:SetShown(single and #data > 1)
	self.sampleNext.label:SetText(string.format("%d / %d  ›", first, #data))

	local viewport, rows = self:GetSampleViewport()
	local viewportParent = nativeFrame and self.headerSample.topSurface or self.preview
	if viewport:GetParent() ~= viewportParent then
		viewport:SetParent(viewportParent)
		if viewport.ScrollBar then viewport.ScrollBar:SetParent(viewportParent) end
	end
	local rowY, indexUsed = 0, 0
	local function PlaceSampleRow(entry)
		indexUsed = indexUsed + 1
		local widget = self.sampleContext:RenderSettingsSample(rows, self.sampleWidgets, indexUsed, entry, rowWidth)
		widget:ClearAllPoints()
		widget:SetPoint("TOPLEFT", 0, -rowY)
		widget.BFL_SettingsSampleData = entry
		widget:Show()
		rowY = rowY + widget:GetHeight()
	end
	for index = first, last do
		local entry = data[index]
		PlaceSampleRow(entry)
		for _, example in ipairs(entry.exampleFriends or {}) do PlaceSampleRow(example) end
	end
	for index = indexUsed + 1, #self.sampleWidgets do
		self.sampleWidgets[index]:Hide()
	end
	local viewportHeight = math.min(rowY, heightLimit)
	viewport:ClearAllPoints()
	viewport:SetPoint("TOPLEFT", self.preview, "TOPLEFT", 8 + (frameInset or 0), -y)
	viewport:SetSize(rowWidth, math.max(1, viewportHeight))
	viewport.BFL_SettingsContentHeight = rowY
	rows:SetSize(rowWidth, math.max(1, rowY))
	viewport:SetShown(indexUsed > 0)
	viewport:UpdateScrollChildRect()
	viewport:SetVerticalScroll(math.min(viewport:GetVerticalScroll(), viewport:GetVerticalScrollRange()))
	self.settings:UpdateLegacySettingsScrollbar(viewport)
	y = y + viewportHeight
	if nativeFrame then
		y = y + frameInset
		nativeFrame:SetHeight(y - 35)
	end
	self.previewNote:ClearAllPoints()
	self.previewNote:SetPoint("TOPLEFT", 8, -y - 3)
	self.previewNote:SetPoint("TOPRIGHT", -8, -y - 3)
	self.preview:SetHeight(y + noteHeight + 7)
	if single then
		self.sampleIndex = selection
		self.sampleCount = #data
	end
end

local function DisableSampleMouse(frame, viewport)
	if not frame or frame == viewport or (viewport and frame == viewport.ScrollBar) or not frame:IsShown() then
		return
	end
	frame:EnableMouse(false)
	for _, child in ipairs({ frame:GetChildren() }) do
		DisableSampleMouse(child, viewport)
	end
end

function Review:KeepSamplesPassive()
	local viewport = self.sampleViewport
	DisableSampleMouse(self.headerSample, viewport)
	if viewport and viewport:IsShown() then DisableSampleMouse(self.sampleRows) end
	DisableSampleMouse(self.preview.legacyTabFonts)
	DisableSampleMouse((self.preview.socialSamples or {})[self.sample])
	for _, lane in ipairs(self.comparisonLanes or {}) do DisableSampleMouse(lane) end
end

function Review:QueueSample()
	if not self.active then return end
	if not (self.sample and self.preview:IsVisible()) then
		if self.guideEntry then self:QueueComparison() end
		return
	end
	if self.sampleTimer then return end
	self.sampleTimer = C_Timer.NewTimer(0, function()
		self.sampleTimer = nil
		self:RenderSample()
		local style = BFL:GetModule("LegacySettingsStyle")
		if style then style:SkinPreview(self) end
		-- Skins can install mouse handlers on native widgets. Keep the examples
		-- inert after styling while preserving the sample picker and scrollbar.
		self:KeepSamplesPassive()
		self:LayoutSettingHelp()
		self:RefreshHeight()
	end)
end

function Review:RefreshHeight()
	if not self.active or not self.frame:IsShown() then
		return
	end
	local height
	if self.pageFrame:IsShown() then
		if self.home and self.home:IsShown() then
			local top, notesTop = self.pageFrame:GetTop(), self.home.notes:GetTop()
			height = (top and notesTop and top - notesTop or 0) + self.home.notes:GetHeight() + 12
		else
			height = self.listHeight or 0
		end
	elseif self.route then
		height = self.controlsHeight or 0
	end
	if height then
		self.scroll.BFL_SettingsContentHeight = height
		self.content:SetHeight(math.max(height, self.scroll:GetHeight()))
		self.scroll:UpdateScrollChildRect()
		self.settings:UpdateLegacySettingsScrollbar(self.scroll)
	end
end

function Review:Layout()
	if not self.active then
		return
	end
	local inset = self.frame.MainInset
	local width = inset:GetWidth()
	if width < 100 then
		return
	end
	local top = -42
	self:LayoutSupport(width)
	local navHeight = math.min(33, math.max(26, (self.sidebar:GetHeight() - 8) / #self.visibleNavRows))
	for index, row in ipairs(self.visibleNavRows) do
		local y = 2 - (index - 1) * navHeight
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("TOPRIGHT", 0, y)
		row:SetHeight(navHeight)
		row.label:ClearAllPoints()
		row.label:SetPoint("LEFT", row.labelInset, 0)
		row.label:SetWidth(math.max(1, self.sidebar:GetWidth() - row.labelInset - 8))
		if row.selected then
			LayoutNavigationSelection(row)
		end
	end
	local broker = self.sample == "broker" or self.sample == "guildBroker"
	local docked = self.sample and not broker and width >= 815
	local hasGuides = self.guideRows and #self.guideRows > 0
	local helpBeside = hasGuides and width >= 815
	local helpStacked = hasGuides and not helpBeside
	local stackedSpace = inset:GetHeight() + top - 198
	-- Keep the font picker and both raid control strips visible in the stacked layout.
	local guideHeight = math.min(220, math.floor(stackedSpace * 0.54))
	if self.route == "rowFonts" then
		guideHeight = 280
	elseif self.route == "raid" then
		guideHeight = 250
	end
	local helpHeight = math.min(math.max(86, guideHeight),
		math.max(86, stackedSpace - (self.sample and 100 or 0)))
	local dockWidth = (docked or helpBeside) and math.min(432, width - 484) or 0
	self.sampleDocked = docked
	self.helpStacked = helpStacked
	self.helpVisible = helpBeside or helpStacked

	-- A stacked preview leaves space for the scroll gap and three settings rows.
	self.sampleHeightLimit = inset:GetHeight() + top - (docked and 46 or 198)
	if docked and helpBeside then
		self.sampleHeightLimit = math.max(100, self.sampleHeightLimit - 224)
	elseif helpStacked and self.sample then
		self.sampleHeightLimit = math.max(72, stackedSpace - helpHeight - 4)
	end
	self.singleSample = self.sample and not docked and self.frame:GetHeight() < (helpStacked and 640 or 480)
	self.scroll:ClearAllPoints()
	local sideBySide = docked or helpBeside
	self.scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", sideBySide and -(dockWidth + 38) or -25, 41)
	if self.sample then
		self.preview:ClearAllPoints()
		self.preview:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -12, top)
		if docked then
			self.preview:SetWidth(dockWidth)
			self.scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, top)
		else
			self.preview:SetWidth(width - 24)
			self.scroll:SetPoint("TOPLEFT", self.preview, "BOTTOMLEFT", -4, -6)
		end
		self.preview:Show()
		self:QueueSample()
	elseif self.home and self.home:IsShown() then
		self.home:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, top)
		self.home:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -25, top)
		self.scroll:SetPoint("TOPLEFT", self.home.rule, "BOTTOMLEFT", -12, -4)
	else
		self.scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, top)
	end
	if self.helpVisible then
		local help = self.hoverHelp
		help:ClearAllPoints()
		if self.sample then
			help:SetPoint("TOPRIGHT", self.preview, "BOTTOMRIGHT", 0, -8)
		else
			help:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -12, top)
		end
		help:SetWidth(helpBeside and dockWidth or width - 24)
		if helpStacked then
			help:SetHeight(helpHeight)
			self.scroll:SetPoint("TOPLEFT", help, "BOTTOMLEFT", -4, -6)
		end
	end
	self.content:SetWidth(math.max(1, width - (sideBySide and (dockWidth + 46) or 33)))
	self:LayoutSettingHelp()
	if self.home and self.home:IsShown() then
		self:LayoutHome()
	end
	self:RefreshHeight()
end

local function HideTabFrames(content)
	for _, tabName in ipairs(Catalog.tabs) do
		if content[tabName] then
			content[tabName]:Hide()
		end
	end
end

function Review:ResetScroll()
	self.scroll:UpdateScrollChildRect()
	self.scroll:SetVerticalScroll(0)
end

function Review:ClearFocus()
	self.focusedRow = nil
	self.highlight:Hide()
	self.highlight:ClearAllPoints()
	self.focused = nil
	if self.focusTimer then
		self.focusTimer:Cancel()
		self.focusTimer = nil
	end
end

function Review:Focus(frame, settingRow, settingKey)
	if not frame then
		return
	end
	self:ClearFocus()
	self.focused = frame
	self.focusTimer = C_Timer.NewTimer(0, function()
		self.focusTimer = nil
		if not (self.active and frame:IsVisible()) then
			return
		end
		self:RefreshHeight()
		self.scroll:UpdateScrollChildRect()
		local target = settingRow or frame
		local top, targetTop, targetBottom = self.content:GetTop(), target:GetTop(), target:GetBottom()
		if top and targetTop and targetBottom then
			local offset = self.scroll:GetVerticalScroll()
			local height = self.scroll:GetHeight()
			local first, last = top - targetTop, top - targetBottom
			local margin = 12
			if settingRow then
				local context = math.min(110, height * 0.25)
				offset = math.min(first - margin, math.max(first - context, last - height + margin))
			elseif first < offset + margin then
				offset = first - margin
			elseif last > offset + height - margin then
				offset = math.min(first - margin, last - height + margin)
			end
			local range = self.scroll:GetVerticalScrollRange()
			if settingRow and self.scroll.BFL_SettingsContentHeight then
				range = math.min(range, math.max(0, self.scroll.BFL_SettingsContentHeight - height))
			end
			self.scroll:SetVerticalScroll(math.min(range, math.max(0, offset)))
		end
		local highlight = self.highlight
		if settingRow then
			if not self:ApplyModernSettingSelection(highlight) then
				highlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
				highlight:SetTexCoord(0, 1, 0, 1)
				highlight:SetVertexColor(0.510, 0.773, 1, 0.65)
				highlight:SetBlendMode("ADD")
			end
			highlight:SetPoint("TOPLEFT", settingRow, "TOPLEFT", -8, 3)
			highlight:SetPoint("BOTTOMRIGHT", settingRow, "BOTTOMRIGHT", 8, -3)
		else
			highlight:SetBlendMode("BLEND")
			highlight:SetVertexColor(1, 1, 1, 1)
			highlight:SetColorTexture(1, 0.8, 0.25, 0.9)
			highlight:SetWidth(2)
			highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 0)
			highlight:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -4, 0)
		end
		highlight:Show()
		self.focusedRow = settingRow
		if settingRow then
			local slot
			for index, entry in pairs(settingRow.BFL_SettingGuide or {}) do
				if entry[3] == settingKey then slot = index; break end
			end
			self:ShowSettingHelp(settingRow, slot)
		end
	end)
end

local function FindLabel(row, label, depth)
	for _, value in pairs(row.BFL_SearchLabels or {}) do
		if Normalize(value) == label then
			return row
		end
	end
	if row.GetText and Normalize(row:GetText()) == label then
		return row
	end
	if row.nameText and Normalize(row.nameText:GetText()) == label then
		return row
	end
	if depth < 2 and row.GetChildren then
		for _, child in ipairs({ row:GetChildren() }) do
			local match = child:IsShown() and FindLabel(child, label, depth + 1)
			if match then
				return match
			end
		end
	end
	return false
end

local function FindVisibleControl(review, key, section)
	local label = Normalize(Text(key))
	for _, row in ipairs(review.controlRows or {}) do
		if row:IsVisible() and review.controlSections[row] == section then
			local match = FindLabel(row, label, 0)
			if match then return match, row end
		end
	end
end

local function Stack(frames, parent)
	local height = 6
	for index, frame in ipairs(frames) do
		-- Change only the vertical anchor. Controls retain their own width and insets.
		local points = ReadPoints(frame)
		frame:ClearAllPoints()
		for _, point in ipairs(points) do
			if point[1] ~= "TOP" then
				frame:SetPoint(unpack(point))
			end
		end
		local previous = frames[index - 1]
		local gap = previous and frame.BFL_SettingsSectionHeader and 12 or 4
		height = height + frame:GetHeight() + gap
		if previous then
			frame:SetPoint("TOP", previous, "BOTTOM", 0, -gap)
		else
			frame:SetPoint("TOP", parent, "TOP", 0, -6)
		end
	end
	return height + 8
end

local friendRowSections = {
	{ id = "identity", title = "SETTINGS_LEGACY_ROWS_IDENTITY" },
	{ id = "names", section = "SETTINGS_NAME_FORMAT_HEADER" },
	{ id = "info", section = "SETTINGS_INFO_FORMAT_HEADER" },
	{ id = "details" },
	{ id = "status", title = "SETTINGS_LEGACY_ROWS_STATUS" },
	{ id = "favorites", title = "SETTINGS_LEGACY_ROWS_FAVORITES" },
}

function Review:ArrangeFriendControls(tab, rows)
	local grouped = { identity = {}, names = {}, info = {}, details = {}, status = {}, favorites = {} }
	for _, row in ipairs(rows) do
		local section = self.controlSections[row]
		local key = row.BFL_FriendRowSection
			or (section == "SETTINGS_NAME_FORMAT_HEADER" and "names")
			or (section == "SETTINGS_INFO_FORMAT_HEADER" and "info")
		if key and (row.BFL_SettingsSectionHeader or row.BFL_SearchLabels or row:GetHeight() > 12) then
			table.insert(grouped[key], row)
		else
			row:Hide()
		end
	end

	self.friendSectionRows = self.friendSectionRows or {}
	local ordered = {}
	for _, section in ipairs(friendRowSections) do
		local controls = grouped[section.id]
		if #controls > 0 then
			if section.title then
				local header = self.friendSectionRows[section.id]
				if not header then
					header = BFL.SettingsComponents:CreateHeader(tab, Text(section.title), section.title)
					self.friendSectionRows[section.id] = header
				end
				header:Show()
				self.sectionRows[section.title] = header
				ordered[#ordered + 1] = header
			end
			for _, row in ipairs(controls) do
				ordered[#ordered + 1] = row
			end
		end
	end
	self.sectionRows.SETTINGS_DISPLAY_OPTIONS = self.friendSectionRows.identity
	return ordered
end

local function IsFavoriteGuide(entries)
	for _, entry in ipairs(entries or {}) do
		if entry[3] == "SETTINGS_ENABLE_FAVORITE_ICON" or entry[3] == "SETTINGS_FAVORITE_ICON_STYLE" then
			return true
		end
	end
	return false
end

local function SampleSettings(db, overrides)
	return setmetatable({
		Get = function(_, key, default)
			if overrides[key] ~= nil then return overrides[key] end
			return db:Get(key, default)
		end,
	}, { __index = db })
end

local function FindChoice(choices, value)
	for index, candidate in ipairs(choices and choices.values or {}) do
		if value == candidate then return choices.labels[index] end
	end
end

local function GetAlternate(guide, control, current, default)
	local choices = control.BFL_ComparisonChoices
	if default ~= current and FindChoice(choices, default) then
		for index, value in ipairs(choices.values) do
			if value == default and (not choices.isOptionEnabled or choices.isOptionEnabled(value, index)) then return value end
		end
	end
	for index, value in ipairs(choices and choices.values or {}) do
		if value ~= current and (not choices.isOptionEnabled or choices.isOptionEnabled(value, index)) then
			return value
		end
	end
	local range = control.BFL_ComparisonRange
	if range then
		if type(default) == "number" and default ~= current and default >= range[1] and default <= range[2] then return default end
		return current ~= range[2] and range[2] or range[1]
	end
	if guide.examples then
		for _, value in ipairs(guide.examples) do
			if tostring(value) ~= tostring(current) then return value end
		end
	end
	if control.colorButton and type(current) == "table" then
		local alternate = current.b == 1 and { r = 1, g = 0.7, b = 0.2 } or { r = 0.2, g = 0.8, b = 1 }
		alternate.a = current.a or 1
		return alternate
	end
end

function Review:GetComparison()
	local entry = self.guideEntry
	if not (entry and entry.showComparison) then return end
	local guide = entry[4]
	local row = self.guideRow
	local control = guide and guide.control or row
	local db = BFL:GetModule("DB")
	if not (guide and control and db) then return end
	local current
	if guide.read then
		current = guide.read()
	elseif guide.orderFrom then
		current = guide.orderFrom
	elseif guide.theme == true then
		current = BFL:GetEffectiveTheme()
	elseif guide[1] == "friendsFrameStyle" then
		current = BFL:GetModule("FriendsUI"):GetEffectiveStyle()
	elseif guide.tags then
		local tags = BFL:GetModule("FriendTags")
		if not tags then return end
		current = tags:GetSetting(guide[1])
	else
		current = db:Get(guide[1])
	end
	if guide.valueAliases then current = guide.valueAliases[current] or current end
	if guide.binary or control.checkBox then return guide, control, db, false, true, true end
	local choices = control.BFL_ComparisonChoices
	if choices then
		if current == nil and control.BFL_ComparisonIsSelected then
			for _, value in ipairs(choices.values or {}) do
				if control.BFL_ComparisonIsSelected(value) then
					current = value
					break
				end
			end
		end
	elseif control.BFL_ComparisonRange and control.GetValue then
		current = control:GetValue()
	elseif control.Input and not guide.read then
		current = control.Input:GetText()
	elseif control.colorButton then
		current = control.currentColor
	end
	if current == nil then return end
	local alternate = self.comparisonValue
	if alternate == nil then alternate = GetAlternate(guide, control, current, db:GetScalarDefault(guide[1])) end
	if alternate == current then alternate = GetAlternate(guide, control, current, db:GetScalarDefault(guide[1])) end
	if alternate ~= nil then return guide, control, db, current, alternate, false end
end

function Review:QueueComparison()
	if self.comparisonTimer then return end
	self.comparisonTimer = C_Timer.NewTimer(0, function()
		self.comparisonTimer = nil
		if self.active then self:LayoutSettingHelp() end
	end)
end

function Review:InvalidateEditorRuleComparison()
	local guide = self.guideEntry and self.guideEntry[4]
	if guide and guide.filterEditor and guide.patch then
		if self.pinnedGuideID then
			self.comparisonValue = nil
			return
		end
		self.guideRow, self.guideEntry, self.guideEntries, self.comparisonValue = nil, nil, nil, nil
		self.markComparison = nil
	end
end

local function ReleaseComparisonTooltip(lane)
	if not lane.tooltip then return end
	BFL.BrokerUtils.ReleaseSettingsTooltip(lane.tooltip)
	lane.tooltip = nil
end

function Review:ComparisonLane(index, content)
	self.comparisonLanes = self.comparisonLanes or {}
	local lane = self.comparisonLanes[index]
	if not lane then
		lane = CreateFrame("Frame", nil, content)
		lane.title = Label(lane, "BetterFriendlistFontHighlightSmall", "")
		lane.title:SetPoint("TOPLEFT")
		lane.widgets = {}
		lane.tooltipKey = "BFLSettingsCompare" .. index
		lane.renderer = BFL:GetModule("FriendsList"):CreateSettingsSampleContext(lane)
		self.comparisonLanes[index] = lane
	end
	return lane
end

local brokerComparisonColumns = {
	brokerShowClassIcons = "Character",
	brokerNicknameColor = "Nickname",
	brokerCharacterColor = "Character",
	brokerZoneColor = "Zone",
	brokerRealmColor = "Realm",
	brokerNotesColor = "Notes",
	guildBrokerHideLevelAtMax = "Level",
	guildBrokerRankColor = "Rank",
	guildBrokerNicknameColor = "Nickname",
	guildBrokerZoneColor = "Zone",
	guildBrokerNoteColor = "Note",
	guildBrokerOfficerNoteColor = "OfficerNote",
}

local guildSortColumns = {
	name = "Name", rank = "Rank", level = "Level", class = "Class", zone = "Zone", nickname = "Nickname",
}

function Review:RenderComparisonTooltip(lane, settings, width, top, guide)
	if not lane.tooltipSurface then
		lane.tooltipSurface = CreateFrame("Frame", nil, lane)
		lane.tooltipSummary = Label(lane, "BetterFriendlistFontHighlightSmall", "")
	end
	local surface = lane.tooltipSurface
	surface:ClearAllPoints()
	surface:SetPoint("TOP", lane, "TOP", 0, -top)
	surface:SetSize(width, 1)
	surface:Show()
	local guild = self.route == "guildBroker"
	local key = guide[1]
	local hints = key == "brokerShowHints" or key == "guildBrokerShowHints"
	local groupAlignment = key == "brokerGroupHeaderAlign"
	local groups = groupAlignment or key == "brokerSeparatorColor" or key == "brokerTooltipMode"
		or key == "guildBrokerGroupMode"
	local summary = key == "guildBrokerFilter"
	local columns = {}
	local targetColumn = brokerComparisonColumns[key] or guide.identity
	if guide.columnSetting then
		local _, _, _, _, alternate = self:GetComparison()
		columns[guide.order[alternate or guide.orderFrom]] = true
	elseif targetColumn then
		if key ~= "brokerShowClassIcons" then
			columns[targetColumn == "Name" and (guild and "Class" or "Character") or "Name"] = true
		end
	else
		columns.Name = true
		if not guild and not hints then columns.Character = true end
	end
	if targetColumn then columns[targetColumn] = true end
	if key == "guildBrokerSortMode" then
		local _, _, _, current, alternate = self:GetComparison()
		columns[guildSortColumns[current] or "Name"] = true
		columns[guildSortColumns[alternate] or "Name"] = true
	end
	if key == "guildBrokerFilter" then columns.LastOnline = true end

	local sampleOptions = {}
	local prefix = guild and "guildBrokerShowCol" or "brokerShowCol"
	for column in pairs(columns) do
		local setting = prefix .. column
		if key ~= setting then sampleOptions[setting] = true end
	end
	if key == "brokerTooltipMode" then sampleOptions.brokerShowHints = false end
	if guild then
		sampleOptions.guildBrokerExcludeSelf = false
		if key ~= "guildBrokerFilter" then sampleOptions.guildBrokerFilter = "all" end
	else
		sampleOptions.quickFilter = "all"
	end

	local sample
	if guild then
		lane.guildSample = lane.guildSample or BFL.LegacySettingsSocialSamples:BuildGuildBrokerSample(true)
		sample = lane.guildSample
	else
		lane.renderer:UpdateSettingsCache()
		sample = BuildFriendsBrokerSample(lane.renderer)
		if key == "brokerUseCustomFontForNonLatin" then
			local friend = sample.friends[1]
			friend.gameAccountInfo.characterName = "青柳"
			friend.characterName = "青柳"
			friend.gameAccountInfo.areaName = "森林"
			friend.area = "森林"
		end
	end
	sample.settings = setmetatable(sampleOptions, { __index = settings })
	sample.comparison = {
		width = width, columns = columns, hints = hints, groups = groups, groupAlignment = groupAlignment,
		summary = summary, rowBudget = guild and (groups and 2 or 3) or 1,
	}
	sample.tooltip, sample.tooltipKey = lane.tooltip, lane.tooltipKey
	local broker = BFL:GetModule(guild and "GuildBroker" or "Broker")
	local tooltip, _, _, summaryText = broker:RenderSettingsSample(surface, sample)
	lane.tooltip = tooltip
	sample.tooltip, sample.settings, sample.comparison = nil, nil, nil
	if not tooltip then return top end
	local tooltipWidth, tooltipHeight = tooltip:GetSize()
	surface:SetSize(tooltipWidth, tooltipHeight)
	local label = lane.tooltipSummary
	label:SetShown(summaryText ~= nil)
	if summaryText then
		label:ClearAllPoints()
		label:SetPoint("TOP", surface, "BOTTOM", 0, -4)
		label:SetJustifyH("CENTER")
		label:SetWidth(width)
		label:SetText(summaryText)
	end
	return top + tooltipHeight + (summaryText and label:GetStringHeight() + 4 or 0) + 10
end

local function RenderOutcomeLines(lane, lines, width, top)
	local content = lane.outcomeSample
	if not content then
		content = CreateFrame("Frame", nil, lane, "BackdropTemplate")
		content:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
		content.lines = {}
		lane.outcomeSample = content
	end

	local colors = BFL:GetModule("SkinEngine").colors
	content:SetBackdropColor(unpack(colors.popup))
	content:SetBackdropBorderColor(unpack(colors.borderSoft))
	content:ClearAllPoints()
	content:SetPoint("TOPLEFT", lane, "TOPLEFT", 0, -top)
	content:SetWidth(width)
	local height = 8
	for index, text in ipairs(lines) do
		local line = content.lines[index] or Label(content, "GameTooltipText", "")
		content.lines[index] = line
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -height)
		line:SetWidth(width - 16)
		line:SetText(text)
		line:SetTextColor(unpack(index == 1 and colors.gold or colors.text))
		line:Show()
		height = height + line:GetStringHeight() + 3
	end
	for index = #lines + 1, #content.lines do content.lines[index]:Hide() end
	content:SetHeight(height + 4)
	content:Show()
	return top + content:GetHeight() + 8
end

local function GetPrivacyComparisonLines(guide, value)
	local sample = BFL.LegacySettingsSocialSamples
	local lines = { sample:CharacterName("SETTINGS_LEGACY_SAMPLE_ONLINE") }
	local key = guide[1]
	if guide.privacy == "notes" then
		local memory = BFL:GetModule("ContactMemory")
		local streamer = key == "hideInStreamerMode"
		if streamer then lines[1] = "Aster#1234" end
		local shown = streamer and memory:IsPrivateNoteVisible(value, true) or not streamer and value
		if shown then
			memory:AddTooltipSummaryLines({
				AddLine = function(_, text)
					if text ~= "" and text ~= " " then lines[#lines + 1] = text end
				end,
			}, { title = Text("CONTACT_MEMORY_TOOLTIP_TITLE"), note = Text("SETTINGS_COMPARE_SAMPLE_NOTE") })
		end
	elseif key ~= "enabled" or value then
		local characters = BFL:GetModule("KnownCharacters")
		local count = key == "maxTooltipCharacters" and value or 4
		local entries = {}
		for index, name in ipairs({ "SETTINGS_LEGACY_SAMPLE_LONG", "SETTINGS_LEGACY_SAMPLE_OFFLINE", "SETTINGS_LEGACY_SAMPLE_FOURTH",
			"SETTINGS_LEGACY_SAMPLE_FIFTH", "SETTINGS_LEGACY_SAMPLE_ONLINE" }) do
			if index ~= 1 or key ~= "observeBattleNet" or value then
				entries[#entries + 1] = { name = sample:CharacterName(name), source = index == 1 and "observed" or "manual",
					lastSeen = time() - 2 * 3600 }
			end
		end
		for _, line in ipairs(characters:FormatTooltipLines(entries, count)) do
			lines[#lines + 1] = line
		end
	end

	return lines
end

local function GetOutcomeComparisonLines(guide, settings, value)
	local name = BFL.LegacySettingsSocialSamples:CharacterName("SETTINGS_LEGACY_SAMPLE_ONLINE")
	local kind = guide.outcome
	if guide.tags then
		local tags = BFL:GetModule("FriendTags")
		local tagSettings = setmetatable({ enabled = true, [guide[1]] = value }, { __index = tags:GetSettings() })
		if guide[1] == "maxTooltipChips" then tagSettings.showTooltipChips = true end
		local customName = Text("SETTINGS_LEGACY_SAMPLE_ZONE")
		local examples = tags:CreateSettingsTagExamples(customName, guide[1] == "maxTooltipChips")
		local heading = name
		if kind == "broker" then heading = Text("BROKER_TITLE") .. "  ·  " .. name end
		if kind == "search" then
			local target = guide[1] == "includeBlizzardTagsInSearch" and examples[1] or examples[#examples]
			heading = (SEARCH or Text("MENU_SHOW_SEARCH")) .. "  ·  " .. target.name
			return { heading, tags:GetSettingsSampleTagText(kind, tagSettings, { target }) and name or NONE }
		end
		return { heading, tags:GetSettingsSampleTagText(kind, tagSettings, examples) }
	elseif kind == "blizzardMenu" then
		local lines = { "BetterFriendlist", Text("MENU_SETTINGS") }
		if value then lines[#lines + 1] = Text("MENU_SHOW_BLIZZARD") end
		return lines
	elseif kind == "whisper" then
		local list = setmetatable({ settingsSampleDB = settings }, { __index = BFL:GetModule("FriendsList") })
		local mode = list:GetClickWhisperMode()
		local action = mode and Text("WHO_DOUBLE_CLICK_WHISPER") or Text("WHO_TOOLTIP_HINT_CLICK")
		local binding = mode == "single" and "SETTINGS_FRIENDLIST_CLICK_WHISPER_MODE_SINGLE"
			or "SETTINGS_FRIENDLIST_CLICK_WHISPER_MODE_DOUBLE"
		return { name, mode and Text(binding) .. " - " .. action or action }
	elseif kind == "whoHistory" then
		local queries = {}
		for index = 1, BFL:GetModule("WhoSearches"):GetHistoryLimitCap() do
			queries[index] = ("n-%q %d-%d"):format(name, index, index + 5)
		end
		local lines = { Text("WHO_RECENT_SEARCHES") }
		for _, query in ipairs(BFL:GetModule("WhoSearches"):GetSettingsHistorySample(settings, queries)) do
			lines[#lines + 1] = query
		end
		return lines
	elseif kind == "globalSync" then
		local realm = Text("SETTINGS_LEGACY_SAMPLE_REALM")
		local other = BFL.LegacySettingsSocialSamples:CharacterName("SETTINGS_LEGACY_SAMPLE_LONG")
		local key = guide[1]
		if key == "showDeletedFriends" then
			return { Text("SETTINGS_GLOBAL_SYNC_HEADER"), name .. "  ·  " .. realm,
				value and (other .. "  ·  " .. realm .. "  ·  " .. Text("SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE")) or nil }
		elseif key == "enableGlobalSyncDeletion" then
			return { Text("SETTINGS_GLOBAL_SYNC_HEADER"), other .. "  →  " .. (value and Text("DIALOG_REMOVE_FRIEND_CONFIRMATION"):format(other) or realm) }
		end
		return { Text("SETTINGS_GLOBAL_SYNC_HEADER"), name .. "  ·  " .. realm,
			other .. "  →  " .. (value and Text("BUTTON_ADD_FRIEND") or Text("STATUS_DISABLED")) }
	elseif kind == "groupNotes" then
		local note = Text("SETTINGS_COMPARE_SAMPLE_NOTE")
		if value then
			note = BFL:GetModule("NoteSync"):BuildNoteWithGroups(note, { Text("GROUP_FAVORITES") }, 127)
		end
		return { name, note }
	elseif kind == "menuBridge" then
		return { name, Text("WHO_DOUBLE_CLICK_WHISPER"), value and Text("SETTINGS_EXTERNAL_MENU_BRIDGE") or nil }
	elseif kind == "welcome" then
		local lines = { CHAT or Text("SETTINGS_SHOW_WELCOME_MESSAGE") }
		if value then lines[2] = Text("CORE_LOADED"):format(BFL.VERSION, "") end
		return lines
	elseif kind == "debug" then
		return { CHAT or Text("SETTINGS_DEBUG_PRINT"), value and Text("DEBUG_ENABLED") or nil }
	elseif kind == "beta" then
		local lines = { Text("MENU_SETTINGS") }
		if value then
			lines[2] = Text("SETTINGS_TAB_FILTER_SORT")
			if BFL.IsRetail then lines[3] = Text("SETTINGS_ENABLE_GUILD_TAB") end
		end
		return lines
	elseif kind == "settingsEntry" then
		return { Text("MENU_SETTINGS"), value and Text("SETTINGS_ENABLE_SETTINGS_CENTER") or Text("SETTINGS_LEGACY_HOME_INTRO") }
	elseif kind == "filterOrder" then
		local lines = { Text("SETTINGS_TAB_FILTER_SORT") }
		local entries = {}
		for _, entry in ipairs(guide.menuEntries) do entries[entry.id] = entry end
		for _, id in ipairs(settings:Get("menuOrder")) do
			local entry = entries[id]
			if entry.visible or id == guide.order[guide.orderFrom] then
				lines[#lines + 1] = BFL.FormatIcon(entry.icon, 16) .. "  " .. entry.name
			end
		end
		return lines
	elseif kind == "filterMenu" then
		local entry = guide.readEntry and guide.readEntry() or guide.entry
		local name = guide[1] == "name" and value or entry.name
		local icon = guide[1] == "icon" and value or entry.icon
		if guide.fallbackName and not name:find("%S") then name = guide.fallbackName end
		return { Text("SETTINGS_TAB_FILTER_SORT"), BFL.FormatIcon(icon, 16) .. "  " .. name }
	elseif kind == "brokerClick" then
		local labels = {
			toggle = "BROKER_CLICK_TOGGLE", friends = "BROKER_CLICK_FRIENDS", settings = "BROKER_CLICK_SETTINGS",
			guild_tab = "GUILD_BROKER_ACTION_GUILD_FRAME", guild_frame = "GUILD_BROKER_ACTION_GUILD_FRAME",
		}
		return { Text(guide[1] == "guildBrokerClickAction" and "GUILD_BROKER_TITLE" or "BROKER_TITLE"), Text(labels[value]) }
	end
	return GetPrivacyComparisonLines(guide, value)
end

local function BuildTagGroupComparison(renderer, entry, tags, settings)
	local data = {}
	local sampleTags = tags:CreateSettingsTagExamples()
	local first, second = sampleTags[1], sampleTags[2]
	entry.friend.settingsTagDefinitions = { first, second }
	if not settings.enableDynamicTagGroups then return { entry } end

	local groups, groupByTag = {}, {}
	for _, tag in ipairs({ first, second }) do
		local id = "tag:" .. tag.id
		groupByTag[tag.id] = id
		groups[id] = { groupId = id, name = tag.name, tagProfile = tag.chipProfile, virtualTagGroup = true,
			count = 1, onlineCount = 1, totalCount = 1, collapsed = false }
	end
	local matching = {}
	renderer:AppendDynamicTagGroups(entry.friend.settingsTagDefinitions, groupByTag, groups, {}, matching,
		settings.prioritizeDynamicTagGroups)
	for _, id in ipairs(matching) do
		local friendRow = {}
		for key, value in pairs(entry) do friendRow[key] = value end
		friendRow.groupId = id
		groups[id].exampleFriends = { friendRow }
		data[#data + 1] = groups[id]
	end
	return data
end

function Review:RenderComparisonLane(lane, guide, db, value, width, top)
	local overrides = { [guide[1]] = value }
	for key, sampleValue in pairs(guide.sampleOverrides or {}) do overrides[key] = sampleValue end
	if guide.order then
		local order = { unpack(guide.order) }
		table.insert(order, value, table.remove(order, guide.orderFrom))
		overrides[guide[1]] = order
		if guide.columnSetting then overrides[guide.columnSetting] = true end
	end
	if self.route == "guildBroker" and type(value) == "table" and value.r ~= nil then
		-- The color controls return named components, while Guild Broker uses RGB arrays.
		overrides[guide[1]] = { value.r, value.g, value.b }
	end
	if guide[1] == "guildBrokerNicknameColor" then
		if guide.guildNicknameClassColor then
			-- False shadows an inherited custom color and requests class coloring.
			if value then
				overrides[guide[1]] = false
			else
				overrides[guide[1]] = { 1, 1, 1 }
			end
		end
		overrides.guildBrokerShowColNickname = true
	end
	local prerequisite = guide.prerequisite
	if prerequisite then overrides[prerequisite[1]] = prerequisite[2] end
	if guide.group and guide.group ~= true then overrides.quickFilter = "all" end
	if guide.group == "recentlyadded" and guide[1] ~= "hideEmptyGroups" then
		overrides.hideEmptyGroups = false
		if guide[1] == "enableRecentlyAddedGroup" then
			overrides.recentlyAddedDurationUnit, overrides.recentlyAddedDurationValue = "days", 7
		end
	end
	local settings = SampleSettings(db, overrides)
	local samples = BFL.LegacySettingsSocialSamples
	samples:Hide(lane)
	if lane.headerSample then lane.headerSample:Hide() end
	if lane.brokerDisplay then lane.brokerDisplay:Hide() end
	if lane.themeSample then lane.themeSample:Hide() end
	if lane.geometrySample then lane.geometrySample:Hide() end
	if lane.outcomeSample then lane.outcomeSample:Hide() end
	if lane.filterMenuLine then lane.filterMenuLine:Hide() end
	if not guide.brokerTooltip then
		ReleaseComparisonTooltip(lane)
		if lane.tooltipSurface then lane.tooltipSurface:Hide(); lane.tooltipSummary:Hide() end
	end
	if guide.privacy or guide.outcome then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		return RenderOutcomeLines(lane, GetOutcomeComparisonLines(guide, settings, value), width, top)
	end
	if guide.geometry then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		return BFL:GetModule("LegacySettingsStyle"):RenderGeometryComparison(lane, guide, value, width, top)
	end
	if guide.theme then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		if guide.themeToggle then value = value and "elvui" or "blizzard" end
		return BFL:GetModule("LegacySettingsStyle"):RenderThemeComparison(lane, guide, value, width, top)
	end
	if guide.brokerTooltip then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		if self.route == "broker" and guide[1] ~= "brokerTooltipMode" then overrides.brokerTooltipMode = "advanced" end
		return self:RenderComparisonTooltip(lane, setmetatable(overrides, { __index = db:Get() }), width, top, guide)
	end
	if guide.brokerLine then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		local broker = BFL:GetModule(self.route == "guildBroker" and "GuildBroker" or "Broker")
		local visualSettings = setmetatable(overrides, { __index = db:Get() })
		local display, icon = broker:RenderSettingsDisplaySample(visualSettings, Text("SETTINGS_LEGACY_SAMPLE_REALM"))
		if value == false and (guide[1] == "brokerEnabled" or guide[1] == "guildBrokerEnabled") then
			display, icon = Text("STATUS_DISABLED"), nil
		end
		lane.brokerDisplay = lane.brokerDisplay or Label(lane, "BetterFriendlistFontHighlightSmall", "")
		lane.brokerDisplay:SetPoint("TOPLEFT", 0, -top)
		lane.brokerDisplay:SetWidth(width)
		lane.brokerDisplay:SetText((icon and ("|T" .. icon .. ":16:16|t  ") or "") .. display)
		lane.brokerDisplay:Show()
		return top + lane.brokerDisplay:GetStringHeight() + 10
	end
	if guide.header then
		if guide[1] == "friendsFrameStyle" then overrides.sampleInterfaceStyle = value end
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		local streamerActive = guide.header == "streamer"
			and (guide[1] ~= "streamerModeActive" or value == true)
		return top + Review.RenderHeaderSample(lane, width, settings, top, streamerActive) + 5
	end
	if guide.social then
		for _, widget in ipairs(lane.widgets) do widget:Hide() end
		return samples:Show(guide.social, lane, width, settings, 220, true, top, guide)
	end
	local renderer = lane.renderer
	renderer.settingsSampleDB = settings
	renderer.settingsSampleStreamerMode = guide.streamer
	local tags = guide.tags and BFL:GetModule("FriendTags")
	if tags then
		local tagOverrides = { [guide[1]] = value }
		if guide[1] ~= "enabled" then tagOverrides.enabled = true end
		if guide[1] ~= "showRowChips" then tagOverrides.showRowChips = true end
		if guide[1] == "chipsPerLine" then tagOverrides.maxRowChips = 20 end
		if guide.tagGroups then
			if guide[1] ~= "enableDynamicTagGroups" then tagOverrides.enableDynamicTagGroups = true end
			if guide[1] ~= "prioritizeDynamicTagGroups" then tagOverrides.prioritizeDynamicTagGroups = false end
			if guide[1] ~= "hideDynamicGroupTagChip" then tagOverrides.hideDynamicGroupTagChip = false end
			if guide[1] ~= "hideAllDynamicGroupTagChips" then tagOverrides.hideAllDynamicGroupTagChips = false end
		end
		renderer.settingsSampleTagSettings = setmetatable(tagOverrides, { __index = tags:GetSettings() })
		if guide[1] ~= "compactRowMode" then overrides.compactMode = false end
		overrides.infoFormatPreset = "default"
	end
	renderer.settingsCacheVersion = false
	wipe(renderer.displayNameCache)
	renderer:UpdateSettingsCache()

	local filterExample = guide.filterEditor or guide[1] == "quickFilter"
	local friends = BuildFriends(renderer, guide.group ~= nil or guide.filterEditor ~= nil, filterExample, guide.tags)
	if filterExample then PrepareFilterSamples(friends) end
	local data = { friends[guide.friend or 1] }
	if guide.tagGroups then
		data = BuildTagGroupComparison(renderer, friends[2], tags, renderer.settingsSampleTagSettings)
	elseif guide.filterEditor then
		local registry = BFL:GetModule("FilterSortRegistry")
		local secondary = db:Get("secondarySort", registry.FALLBACK_SECONDARY_SORT)
		data = {}
		local ast, chain
		if guide.patch then
			ast, chain = guide.patch(value)
		end
		if guide.filterEditor == "sorter" then
			local plan = chain and registry:CreateSettingsSortPlan(chain, secondary)
				or registry:CreateSortPlan(value and guide.entryID or registry.FALLBACK_PRIMARY_SORT, secondary, true)
			data = friends
			table.sort(data, function(a, b) return registry:CompareFriendsWithSortPlan(a.friend, b.friend, plan) end)
		else
			for _, item in ipairs(friends) do
				local included
				if ast then
					included = registry:EvaluateSettingsFilterAST(ast, item.friend)
				else
					included = not value or registry:EvaluateQuickFilter(guide.entryID, item.friend)
				end
				if included then data[#data + 1] = item end
			end
		end
	elseif guide.groupOrder then
		local groups = { unpack(guide.groupOrder) }
		local moved = table.remove(groups, guide.read())
		table.insert(groups, value, moved)
		data = {}
		for index, name in ipairs(groups) do
			data[index] = { groupId = "bfl_settings_group", name = index .. ". " .. name, count = 1,
				onlineCount = 1, totalCount = 1, collapsed = true }
		end
	elseif guide.groupEditorName then
		local colors = setmetatable({ [guide[1]] = value }, { __index = guide.groupEditorColors })
		data = { { groupId = "bfl_settings_group", name = guide.groupEditorName, count = 4,
			onlineCount = 7, totalCount = 10, collapsed = true, sampleColors = colors } }
	elseif guide.group then
		if self.route == "headers" then
			data = { {
				groupId = "bfl_settings_group", name = Text("SETTINGS_LEGACY_SAMPLE_ZONE"),
				count = 4, onlineCount = 7, totalCount = 10, collapsed = true,
			} }
		else
			local groups = BuildGroups(settings, friends, true, nil, renderer)
			data = {}
			for _, group in ipairs(groups) do
				if (guide.group == true and group.groupId ~= "nogroup") or group.groupId == guide.group then
					data[#data + 1] = group
				end
			end
		end
	end

	local count = 0
	local function Place(entry)
		count = count + 1
		local widget = renderer:RenderSettingsSample(lane, lane.widgets, count, entry, width)
		widget:ClearAllPoints()
		widget:SetPoint("TOPLEFT", 0, -top)
		widget:Show()
		top = top + widget:GetHeight()
	end
	if lane.filterMenuLine then lane.filterMenuLine:Hide() end
	if guide.entry and guide.filterEditor then
		local label = lane.filterMenuLine or Label(lane, "GameTooltipText", "")
		lane.filterMenuLine = label
		label:SetPoint("TOPLEFT", 0, -top)
		label:SetWidth(width)
		label:SetText(value and (BFL.FormatIcon(guide.entry.icon, 16) .. "  " .. guide.entry.name) or Text("STATUS_DISABLED"))
		label:Show()
		top = top + label:GetStringHeight() + 5
	end
	for _, entry in ipairs(data) do
		Place(entry)
		for _, member in ipairs(entry.exampleFriends or {}) do Place(member) end
	end
	for index = count + 1, #lane.widgets do lane.widgets[index]:Hide() end
	if count == 0 then
		lane.empty = lane.empty or Label(lane, "BetterFriendlistFontHighlightSmall", NONE)
		lane.empty:SetPoint("TOPLEFT", 0, -top)
		lane.empty:SetWidth(width)
		lane.empty:Show()
		top = top + lane.empty:GetStringHeight()
	elseif lane.empty then
		lane.empty:Hide()
	end
	renderer.settingsSampleDB = nil
	renderer.settingsSampleTagSettings = nil
	return top + 10
end

function Review:SetComparisonValue(value)
	self.comparisonValue = value
	self:QueueComparison()
end

function Review:LayoutComparisonEditor(control, guide, value, width, y)
	local components = BFL.SettingsComponents
	local content = self.hoverHelp.content
	local caption = Text("SETTINGS_COMPARE_ALTERNATE")
	local range = control.BFL_ComparisonRange
	local editor, reset
	if range then
		editor = self.comparisonSlider or components:CreateSlider(content, caption, 0, 1, 0, tostring, function(value)
			if not self.comparisonEditorUpdating then self:SetComparisonValue(value) end
		end, 140)
		self.comparisonSlider = editor
		reset = function()
			local min, max, format = range[1], range[2], range[3]
			local step = control.Slider.stepSize or 1
			if step <= 0 then step = 1 end
			editor.Slider:Init(value, min, max, math.max(1, math.floor((max - min) / step + 0.5)), {})
			editor.ValueLabel:SetText(format(value))
		end
	elseif control.Input and guide.examples then
		editor = self.comparisonInput or components:CreateInput(content, caption, "", function(value)
			if self.comparisonEditorUpdating or self.comparisonInput ~= self.comparisonEditor then return end
			local entry = self.guideEntry and self.guideEntry[4]
			if not (entry and entry.examples and self.comparisonInput.BFL_ComparisonEntry == self.guideEntry) then return end
			if entry.parse then
				value = entry.parse(value)
				if value == nil then return end
			elseif type(entry.examples[1]) == "number" then
				value = tonumber(value)
				if not value then return end
				local bounds = entry.inputRange
				if bounds then
					value = math.max(bounds[1], math.min(bounds[2], value))
					if not bounds[3] then value = math.floor(value + 0.5) end
				else
					value = math.max(1, math.floor(value))
				end
				self.comparisonInput.Input:SetText(tostring(value))
			end
			self:SetComparisonValue(value)
		end, math.min(260, math.floor(width * 0.56)))
		self.comparisonInput = editor
		reset = function() editor.Input:SetText(tostring(value)) end
	elseif guide.icon then
		editor = self.comparisonIcon
		if not editor then
			editor = components:CreateButton(content, Text("ICON_SELECTOR_TITLE"), function()
				local entry = self.guideEntry
				self.comparisonIconEntry = entry
				BFL.ShowIconSelector(editor, editor.BFL_ComparisonIcon, function(icon)
					if self.comparisonEditor ~= editor or self.guideEntry ~= entry then return end
					self.comparisonIconEntry = nil
					self:SetComparisonValue(icon)
				end, { anchorFrame = self.frame })
			end)
			self.comparisonIcon = editor
		end
		reset = function() editor.BFL_ComparisonIcon = value end
	elseif control.colorButton and type(value) == "table" then
		editor = self.comparisonColor
		if not editor then
			editor = components:CreateColorPicker(content, caption, value)
			self.comparisonColor = editor
			editor.colorButton:SetScript("OnClick", function()
				if not BFL.ShowColorPicker then return end
				local entry = self.guideEntry
				local initial = editor.currentColor
				local function Apply(r, g, b, a)
					if self.comparisonEditor ~= editor or self.guideEntry ~= entry then return end
					editor:SetColor(r, g, b, a)
					self:SetComparisonValue({ r = r, g = g, b = b, a = a })
				end
				BFL.ShowColorPicker(initial.r, initial.g, initial.b, initial.a or 1, Apply, Apply)
			end)
		end
		reset = function() editor:SetColor(value.r, value.g, value.b, value.a or 1) end
	end
	if self.comparisonEditor and self.comparisonEditor ~= editor then
		self.comparisonEditorUpdating = true
		self.comparisonEditor:Hide()
		self.comparisonEditorUpdating = false
	end
	self.comparisonEditor = editor
	if not editor then return y end
	if editor.BFL_ComparisonEntry ~= self.guideEntry then
		self.comparisonEditorUpdating = true
		reset()
		self.comparisonEditorUpdating = false
		editor.BFL_ComparisonEntry = self.guideEntry
	elseif range then
		editor.ValueLabel:SetText(range[3](value))
	elseif guide.icon then
		reset()
	end
	editor:ClearAllPoints()
	editor:SetPoint("TOPLEFT", 0, -y)
	editor:SetWidth(width)
	editor:Show()
	return y + editor:GetHeight() + 8
end

function Review:RenderSettingComparison(width, top)
	local guide, control, db, current, alternate, binary = self:GetComparison()
	if not guide then
		for _, lane in ipairs(self.comparisonLanes or {}) do
			ReleaseComparisonTooltip(lane)
			lane:Hide()
		end
		if self.comparisonPicker then self.comparisonPicker:Hide() end
		if self.comparisonEditor then
			local editor = self.comparisonEditor
			self.comparisonEditor = nil
			editor:Hide()
		end
		return top
	end
	local content = self.hoverHelp.content
	local choices = control.BFL_ComparisonChoices
	local range = control.BFL_ComparisonRange
	local function ValueText(value)
		if range then return range[3](value) end
		if choices and choices.getSelectionText and value == current then return choices.getSelectionText() end
		if guide.icon or type(value) == "table" then return "" end
		return FindChoice(choices, value) or tostring(value)
	end
	local bottom = top

	local picker = self.comparisonPicker
	if not binary and choices then
		local pickerWidth = math.max(40, math.min(width - 16, 260))
		picker = picker or BFL.SettingsComponents:CreateModernDropdown(content, pickerWidth)
			or BFL.CreateDropdown(content, nil, pickerWidth)
		self.comparisonPicker = picker
		picker.BFL_ComparisonSelection = alternate
		local options = { labels = {}, values = {} }
		for index, value in ipairs(choices.values or {}) do
			if value ~= current and (not choices.isOptionEnabled or choices.isOptionEnabled(value, index)) then
				options.labels[#options.labels + 1] = choices.labels[index]
				options.values[#options.values + 1] = value
			end
		end
		if #options.values > 0 then
			local activeRow, activeEntry = self.guideRow, self.guideEntry
			if picker.BFL_ComparisonRow ~= activeRow or picker.BFL_ComparisonEntry ~= activeEntry or picker.BFL_ComparisonCurrent ~= current then
				picker.BFL_ComparisonRow, picker.BFL_ComparisonEntry, picker.BFL_ComparisonCurrent = activeRow, activeEntry, current
				BFL.InitializeDropdown(picker, options, function(value)
					return value == picker.BFL_ComparisonSelection
				end, function(value)
					if self.guideRow ~= activeRow or self.guideEntry ~= activeEntry then return end
					self.comparisonValue = value
					self:QueueComparison()
				end, 240)
			end
			BFL.SetDropdownWidth(picker, pickerWidth)
			picker:ClearAllPoints()
			picker:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -bottom)
			picker:Show()
			BFL.SetDropdownText(picker, ValueText(alternate))
			bottom = bottom + picker:GetHeight() + 8
		else
			picker:Hide()
		end
	elseif picker then
		picker:Hide()
	end
	if not binary then
		bottom = self:LayoutComparisonEditor(control, guide, alternate, width, bottom)
	elseif self.comparisonEditor then
		local editor = self.comparisonEditor
		self.comparisonEditor = nil
		editor:Hide()
	end

	local key = guide[1]
	local pairBrokerExcerpts = guide.brokerTooltip
		and key ~= "brokerShowHints" and key ~= "guildBrokerShowHints"
		and key ~= "brokerTooltipMode" and key ~= "guildBrokerFilter"
	local minimumPairWidth = pairBrokerExcerpts and 374 or 490
	local stack = width < minimumPairWidth or guide.header or guide.social
		or (guide.brokerTooltip and not pairBrokerExcerpts) or guide.theme or guide.geometry or guide.privacy or guide.filterEditor
	local laneWidth = stack and width or math.floor((width - 10) / 2)
	top = bottom
	for index, value in ipairs({ current, alternate }) do
		local lane = self:ComparisonLane(index, content)
		lane:ClearAllPoints()
		lane:SetPoint("TOPLEFT", content, "TOPLEFT", stack and 0 or (index - 1) * (laneWidth + 10), -(stack and bottom or top))
		lane:SetWidth(laneWidth)
		lane:Show()
		lane.title:SetWidth(laneWidth)
		local title = Text(binary and (index == 1 and "STATUS_DISABLED" or "STATUS_ENABLED")
			or (index == 1 and "SETTINGS_COMPARE_CURRENT" or "SETTINGS_COMPARE_ALTERNATE"))
		local label = not binary and ValueText(value)
		if binary then title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
		lane.title:SetText(label and label ~= "" and (title .. " · " .. label) or title)
		local height = self:RenderComparisonLane(lane, guide, db, value, laneWidth, lane.title:GetStringHeight() + 5)
		lane:SetHeight(height)
		DisableSampleMouse(lane)
		bottom = stack and bottom + height or math.max(bottom, top + height)
	end

	return bottom
end

function Review:UpdateComparisonHighlight()
	local guide = self.guideEntry and self.guideEntry[4]
	local marker = self.favoriteHighlight
	local widget
	if guide and self.markComparison and not (guide.header or guide.social or guide.theme
		or guide.geometry or guide.privacy or guide.outcome or guide.tagGroups or guide.groupOrder or guide.groupEditorName
		or guide.brokerTooltip or guide.brokerLine)
	then
		for _, candidate in ipairs(self.sampleWidgets) do
			local data = candidate.BFL_SettingsSampleData
			if candidate:IsVisible() and data then
				if (guide.group and (guide.group == true and data.groupId or guide.group == data.groupId))
					or (not guide.group and data.uid == "bfl_settings_example_" .. (guide.friend or 1)) then
					widget = candidate
					break
				end
			end
		end
	end
	if not widget and guide and self.markComparison and self.brokerSample then
		if guide.brokerLine then widget = self.brokerSample.display end
		if guide.brokerTooltip then widget = self.brokerSample.surface end
	end
	if not widget and guide and self.markComparison and guide.header and self.headerSample then
		local scene = self.headerSample
		local region = scene[guide.region]
		widget = region and region:IsVisible() and region or scene
	end
	if not widget and guide and self.markComparison and guide.social then
		local scene = self.preview.socialSamples and self.preview.socialSamples[guide.social]
		if scene and scene:IsVisible() then
			local tabID = guide.tab or guide[1] == "friendTabOrder" and guide.identity
			if tabID then
				for _, rail in ipairs(scene.rails) do
					local tab = rail.tabs[tabID]
					if tab and tab:IsVisible() then widget = tab; break end
				end
			else
				local row = scene.rows[1]
				widget = scene.group or (row and guide.region and row[guide.region]) or scene.actionHint or row
			end
		end
	end
	if not widget then
		if marker then marker:Hide() end
		return
	end
	if not marker then
		marker = CreateFrame("Frame", nil, self.preview, "BackdropTemplate")
		marker.selection = marker:CreateTexture(nil, "BACKGROUND")
		marker.selection:SetAllPoints()
		marker:EnableMouse(false)
		self.favoriteHighlight = marker
	end
	local widgetFrame = widget.GetFrameLevel and widget or widget:GetParent()
	marker:SetParent(widgetFrame:GetParent())
	local field = guide[2]
	local region = field and widget[field]
	marker:ClearAllPoints()
	if field == "gameAccountBadge" and widget.gameIcon then
		-- The badge is overlaid on the game icon and extends beyond its bottom right.
		marker:SetPoint("TOPLEFT", widget.gameIcon, "TOPLEFT", -3, 3)
		marker:SetPoint("BOTTOMRIGHT", widget.gameIcon, "BOTTOMRIGHT", 7, -7)
	elseif region and region:IsShown() and region:GetWidth() > 0 then
		marker:SetPoint("TOPLEFT", region, "TOPLEFT", -2, 2)
		marker:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 2, -2)
	elseif field == "favoriteIcon" then
		local lane = self.comparisonLanes and self.comparisonLanes[2]
		local example = lane and lane.widgets[1] and lane.widgets[1].favoriteIcon
		local _, _, relativePoint, x, y
		if example and example:IsShown() then _, _, relativePoint, x, y = example:GetPoint(1) end
		if not (relativePoint and widget.Name) then marker:Hide(); return end
		local width, height = example:GetSize()
		marker:SetPoint("TOPLEFT", widget.Name, relativePoint, math.min(x, math.max(0, widget.Name:GetWidth() - width)) - 3, y + 3)
		marker:SetSize(width + 6, height + 6)
	else
		marker:SetPoint("TOPLEFT", widget)
		marker:SetPoint("BOTTOMRIGHT", widget)
	end
	marker:SetFrameLevel(widgetFrame:GetFrameLevel() + 1)
	local modern = self:ApplyModernSettingSelection(marker.selection)
	marker.selection:SetShown(modern)
	if marker.modern ~= modern then
		marker.modern = modern
		if modern then
			marker:SetBackdrop(nil)
		else
			marker:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
			marker:SetBackdropColor(1, 0.82, 0.3, 0.12)
			marker:SetBackdropBorderColor(1, 0.82, 0.3, 0.9)
		end
	end
	marker:Show()
end

function Review:SetFavoriteHovered(hovered)
	if self.favoriteHovered == hovered then return end
	self.favoriteHovered = hovered
	if self.sample == "friends" and self.sampleNext:IsShown() then self:QueueSample() end
end

function Review:UpdateSettingHelpPinButton()
	local button = self.hoverHelp.pinButton
	button:SetText(Text(self.pinnedGuideID and "SETTINGS_GUIDE_UNPIN" or "SETTINGS_GUIDE_PIN"))
	button:SetWidth(button.label:GetStringWidth() + 8)
	button:SetShown(self.guideEntry ~= nil)
end

function Review:LayoutSettingHelp()
	local help = self.hoverHelp
	if not self.helpVisible then
		help:Hide()
		return
	end
	if not self.helpStacked then
		local available = (help:GetTop() or 0) - (self.support:GetTop() or 0) - 6
		help:SetHeight(math.max(68, available))
	end
	self:UpdateSettingHelpPinButton()
	if self.pinnedGuideID then self:UpdatePinnedSettingHighlight() end
	local width = math.max(1, help:GetWidth() - 34)
	local entries = self.guideEntries or { { nil, Text("SETTINGS_GUIDE_PROMPT") } }
	local y = 1
	for index, entry in ipairs(entries) do
		local card = help.sections[index]
		if not card then
			card = {
				title = Label(help.content, "BetterFriendlistFontNormal", ""),
				body = Label(help.content, "BetterFriendlistFontHighlight", ""),
			}
			help.sections[index] = card
		end
		card.title:SetText(entry[1] or "")
		card.title:SetWidth(width)
		card.title:SetPoint("TOPLEFT", 0, -y)
		card.title:SetShown(entry[1] ~= nil)
		if entry[1] then y = y + card.title:GetStringHeight() + 7 end
		card.body:SetText(entry[2])
		card.body:SetWidth(width)
		card.body:SetPoint("TOPLEFT", 0, -y)
		card.body:Show()
		y = y + card.body:GetStringHeight() + 17
	end
	for index = #entries + 1, #help.sections do
		help.sections[index].title:Hide()
		help.sections[index].body:Hide()
	end
	y = self:RenderSettingComparison(width, y)
	self:UpdateComparisonHighlight()
	local style = BFL:GetModule("LegacySettingsStyle")
	if self.guideEntry and self.guideEntry.showComparison and style then
		style:SkinComparison(self)
		self:KeepSamplesPassive()
	end
	help.scroll.BFL_SettingsContentHeight = y
	help.content:SetSize(width, y)
	help.scroll:UpdateScrollChildRect()
	self.settings:UpdateLegacySettingsScrollbar(help.scroll)
	help:Show()
end

function Review:ShowSettingHelp(row, slot, highlightPreview)
	if self.pinnedGuideID then return end
	local entry = row.BFL_SettingGuide and row.BFL_SettingGuide[slot or 1]
	if not entry then return end
	self.markComparison = highlightPreview ~= false
	if self.guideRow ~= row or self.guideEntry ~= entry then
		self.guideRow, self.guideEntry = row, entry
		self.guideEntries = { entry }
		self.comparisonValue = nil
		self:SetFavoriteHovered(self.route == "rows" and IsFavoriteGuide(self.guideEntries))
		self:LayoutSettingHelp()
		self.hoverHelp.scroll:SetVerticalScroll(0)
	else
		self:UpdateComparisonHighlight()
	end
end

function Review:ToggleSettingHelpPin(row, slot)
	local entry = row and row.BFL_SettingGuide and row.BFL_SettingGuide[slot]
	if not entry then return end
	local wasPinned = self.pinnedGuideID and self.guideRow == row and self.guideEntry == entry
	self.pinnedGuideID = nil
	if not wasPinned then
		self:ClearFocus()
		self:ShowSettingHelp(row, slot, self.route ~= "friendTabs")
		self.pinnedGuideID = entry[5]
		self:UpdatePinnedSettingHighlight()
	elseif self.hoverTint then
		self.hoverTint:Hide()
	end
	self:UpdateSettingHelpPinButton()
end

function Review:FindGuideRow(owner)
	while not BFL:IsSecret(owner) and owner and owner ~= self.scroll do
		if (owner.IsForbidden and owner:IsForbidden()) or not owner.GetParent then return end
		if self.guideRowsByFrame[owner] then return owner end
		owner = owner:GetParent()
	end
end

function Review:GetHoveredGuideRow(forPin)
	if not (self.active and self.hoverHelp:IsShown() and BFL:IsRegionMouseOver(self.scroll)) then return end
	-- A control inside a row can own mouse focus. Walk to the row before
	-- falling back to its hit rectangle for the label and the empty space.
	local focus
	if GetMouseFoci then
		local foci = GetMouseFoci()
		if foci and not BFL:IsSecret(foci) and not (issecrettable and issecrettable(foci)) then focus = foci[1] end
	elseif GetMouseFocus then
		focus = GetMouseFocus()
	end
	local row = self:FindGuideRow(focus)
	-- The row label and background pin the help. Let its controls own their clicks.
	if forPin and row and (focus ~= row or not row.GetScript or row:GetScript("OnMouseDown") or row:GetScript("OnMouseUp")
		or (row:IsObjectType("Button") and row:GetScript("OnClick"))) then return end
	if not row then
		if BFL:IsSecret(focus) then return end
		local overBackground = not focus or focus == UIParent or focus == self.frame or focus == self.frame.MainInset
		while not BFL:IsSecret(focus) and focus and focus ~= self.scroll and not overBackground do
			if (focus.IsForbidden and focus:IsForbidden()) or not focus.GetParent then return end
			focus = focus:GetParent()
		end
		if not overBackground and (BFL:IsSecret(focus) or focus ~= self.scroll) then return end
		for _, candidate in ipairs(self.guideRows) do
			if candidate:IsVisible() and BFL:IsRegionMouseOver(candidate) then
				row = candidate
				break
			end
		end
	end
	if row and row:IsVisible() then return row end
end

function Review:GetGuideSlot(row)
	local count = row.BFL_SettingSlotCount or 1
	if count == 1 then return 1 end
	if row.BFL_SettingSlotRects then
		for slot, rect in ipairs(row.BFL_SettingSlotRects) do
			if BFL:IsRegionMouseOver(rect) then return slot end
		end
		if row.BFL_SettingsExactSlots then return end
	end
	local left = row:GetLeft()
	if not left then return 1 end
	local x = GetCursorPosition() / row:GetEffectiveScale() - left
	for slot = 1, count - 1 do
		if x < self:GetGuideBoundary(row, slot, count) then return slot end
	end
	return count
end

function Review:GetGuideBoundary(row, slot, count)
	if slot == 0 then return -6 end
	if slot == count then return row:GetWidth() + 6 end
	local labels = row.BFL_SettingGridLabels
	if labels and row.LeftCheckbox and labels[2] then
		local left, checkRight, labelLeft = row:GetLeft(), row.LeftCheckbox:GetRight(), labels[2]:GetLeft()
		if left and checkRight and labelLeft then return (checkRight + labelLeft) / 2 - left end
	end
	local controls = row.BFL_SettingSlotControls
	if controls and controls[slot] and controls[slot + 1] then
		local left, first, second = row:GetLeft(), controls[slot]:GetRight(), controls[slot + 1]:GetLeft()
		if left and first and second then return (first + second) / 2 - left end
	end
	return row:GetWidth() * slot / count
end

function Review:IsHelpInteractionLocked(ignoreMouseDown)
	local activeInput = self.guideRow and self.guideRow.Input
	local comparisonInput = self.comparisonEditor and self.comparisonEditor.Input
	local iconPicker = BetterFriendlistIconSelectorFrame
	return BFL.BrokerUtils.IsMenuOpen() or iconPicker and iconPicker:IsShown()
		or comparisonInput and comparisonInput:IsVisible() and comparisonInput:HasFocus()
		or activeInput and activeInput:HasFocus()
		or not ignoreMouseDown and self.guideRow and IsMouseButtonDown and IsMouseButtonDown("LeftButton")
		or ColorPickerFrame and ColorPickerFrame:IsShown()
end

function Review:HandleSettingHelpClick(event, button)
	if button ~= "LeftButton" or not (self.active and self.guideRowsByFrame and self.hoverHelp:IsVisible()) then return end
	local press = self.pinPress
	self.pinPress = nil
	if self:IsHelpInteractionLocked(true) then return end
	local row = self:GetHoveredGuideRow(true)
	local slot = row and self:GetGuideSlot(row)
	local entry = slot and row.BFL_SettingGuide[slot]
	if not entry then return end
	local x, y = GetCursorPosition()
	if event == "GLOBAL_MOUSE_DOWN" then
		self.pinPress = { row = row, slot = slot, x = x, y = y }
	elseif press and press.row == row and press.slot == slot and math.abs(x - press.x) <= 6 and math.abs(y - press.y) <= 6 then
		self:ToggleSettingHelpPin(row, slot)
	end
end

function Review:UpdateSettingHelpHover()
	if self.pinnedGuideID or not self.guideRowsByFrame then return end
	local locked = self:IsHelpInteractionLocked()
	local row = not locked and self:GetHoveredGuideRow()
	local tint = self.hoverTint
	if not row then
		if tint then tint:Hide() end
		if not locked and not BFL:IsRegionMouseOver(self.hoverHelp) and not self.focusedRow then
			self.markComparison = false
			self:SetFavoriteHovered(false)
			self:UpdateComparisonHighlight()
		end
		return
	end
	local slot = self:GetGuideSlot(row)
	if not slot then
		if tint then tint:Hide() end
		return
	end
	local highlight = self.route ~= "friendTabs"
	self:ShowSettingHelp(row, slot, highlight)
	if not highlight or self.focusedRow == row or not row.BFL_SettingGuide[slot] then
		if tint then tint:Hide() end
		return
	end
	self:ShowSettingHelpHighlight(row, slot)
end

function Review:UpdatePinnedSettingHighlight()
	local row = self.guideRow
	for slot, entry in pairs(row and row.BFL_SettingGuide or {}) do
		if entry == self.guideEntry then
			self:ShowSettingHelpHighlight(row, slot, true)
			return
		end
	end
	if self.hoverTint then self.hoverTint:Hide() end
end

function Review:ShowSettingHelpHighlight(row, slot, pinned)
	local tint = self.hoverTint
	if not tint then
		tint = CreateFrame("Frame", nil, self.content)
		tint:EnableMouse(false)
		local fill = tint:CreateTexture(nil, "BACKGROUND")
		fill:SetAllPoints()
		tint.fill = fill
		self.hoverTint = tint
	end
	if not self:ApplyModernSettingSelection(tint.fill, pinned and 0.75 or 0.45) then
		local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0.30)
		tint.fill:SetBlendMode("BLEND")
		tint.fill:SetVertexColor(1, 1, 1, 1)
		tint.fill:SetColorTexture(r, g, b, pinned and 0.16 or 0.08)
	end
	tint:ClearAllPoints()
	local count = row.BFL_SettingSlotCount or 1
	local rect = row.BFL_SettingSlotRects and row.BFL_SettingSlotRects[slot]
	local label = row.BFL_SettingGridLabels and row.BFL_SettingGridLabels[slot]
	local check = label and (slot == 1 and row.LeftCheckbox or row.RightCheckbox)
	if rect then
		tint:SetPoint("TOPLEFT", rect, "TOPLEFT", -3, 2)
		tint:SetPoint("BOTTOMRIGHT", rect, "BOTTOMRIGHT", 3, -2)
	elseif check then
		local checkInset = check.BFL_SettingsCheckboxBorderInset or 0
		tint:SetPoint("TOPLEFT", label, "LEFT", -6, row:GetHeight() / 2 + 2)
		tint:SetPoint("BOTTOMRIGHT", check, "RIGHT", 4 - checkInset, -row:GetHeight() / 2 - 2)
	else
		tint:SetPoint("TOPLEFT", row, "TOPLEFT", self:GetGuideBoundary(row, slot - 1, count), 2)
		tint:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", self:GetGuideBoundary(row, slot, count) - row:GetWidth(), -2)
	end
	tint:SetFrameLevel(row:GetFrameLevel())
	tint:Show()
end

local function GetGuideDescription(key)
	if not key then return end
	return OptionalText(Catalog.guideDescriptions[key])
		or OptionalText(key .. "_DESC")
		or OptionalText(key .. "_TOOLTIP_DESC")
		or OptionalText(key .. "_TOOLTIP")
end

function Review:BindSettingHelp(row, guideKeys, section)
	-- Static labels are FontStrings, including on clients that expose HookScript
	-- on those regions. Only interactive frame rows participate in hover help.
	if not row:IsObjectType("Frame") or row.BFL_SettingsSectionHeader then return end
	row.BFL_SettingGuide = nil
	local labels = row.BFL_SearchLabels
		or { row.GetText and row:GetText() or row.nameText and row.nameText:GetText() }
	local slotCount = row.BFL_SettingSlotCount or 1
	local sectionContext = OptionalText(Catalog.guideSectionContext[section])
	if Catalog.guideFontSections[section] then
		sectionContext = Text("SETTINGS_GUIDE_FONT_SCOPE"):format(Text(section))
	end
	local pageContext = OptionalText(Catalog.guidePageContext[self.route])
	local entries = {}
	for slot = 1, slotCount do
		local label = labels[slot]
		if type(label) == "string" and label ~= "" then
			local key = row.BFL_SettingHelpKey or guideKeys[Normalize(label)]
			if slotCount == 1 and not key then
				for alias = 2, #labels do
					key = guideKeys[Normalize(labels[alias])]
					if key then break end
				end
			end
			local comparison = row.BFL_Comparison and row.BFL_Comparison[slot]
			local guide = comparison and comparison.help or key and Catalog.guides[key]
			local description = guide and Text(guide) or row.BFL_SettingDescriptions and row.BFL_SettingDescriptions[slot]
			if not description or Normalize(description) == Normalize(label) then
				description = GetGuideDescription(key)
			end
			if description and Normalize(description) == Normalize(label) then description = nil end
			if not description then
				description = sectionContext or pageContext
			elseif not guide and sectionContext and description ~= sectionContext then
				description = description .. "\n\n" .. sectionContext
			end
			local choices = row.BFL_SettingChoices
			if not guide and key ~= "SETTINGS_FONT_FLAGS" and choices and #choices >= 2 and #choices <= 6 then
				local alternatives = Text("SETTINGS_GUIDE_CHOICES"):format(table.concat(choices, " · "))
				description = description and (description .. "\n\n" .. alternatives) or alternatives
			end
			if description then
				local routeComparisons = Catalog.comparisons[self.route]
				local sectionComparisons = routeComparisons and routeComparisons[section]
				comparison = comparison or routeComparisons and (routeComparisons[key] or sectionComparisons and sectionComparisons[key])
				if comparison and (slot == 1 and row.LeftCheckbox or slot == 2 and row.RightCheckbox) then
					comparison = setmetatable({ binary = true }, { __index = comparison })
				end
				local exactID = row.BFL_SettingIdentities and row.BFL_SettingIdentities[slot]
				local stableKey = exactID or comparison and comparison.identity or row.BFL_SettingIdentity or key or Normalize(label)
				local id = table.concat({ self.route, section or "", stableKey, exactID and "control" or slot }, "/")
				entries[slot] = {
					label, description, key, comparison, id,
					showComparison = Catalog.ShowIndividualPreview(self.route, section, key, comparison),
				}
			end
		end
	end
	if not next(entries) then return end
	row.BFL_SettingGuide = entries
	for slot, entry in pairs(entries) do
		local control = entry[4] and entry[4].control
		local input = control and control.Input
		if input and not input.BFL_ComparisonFocusBound then
			input.BFL_ComparisonFocusBound = true
			input:HookScript("OnEditFocusGained", function()
				if self.active and self.guideRowsByFrame and self.guideRowsByFrame[row] then self:ShowSettingHelp(row, slot) end
			end)
		end
	end
	if row.Input and not row.BFL_ComparisonFocusBound then
		row.BFL_ComparisonFocusBound = true
		row.Input:HookScript("OnEditFocusGained", function()
			if self.active and self.guideRowsByFrame and self.guideRowsByFrame[row] then self:ShowSettingHelp(row) end
		end)
	end
end

function Review:OnBuilt(tab)
	local route = self.route
	local page = route and Catalog.pages[route]
	if not page or tab ~= self.content[Catalog.tabs[page[1]]] then
		return
	end
	if self.focused then
		self:ClearFocus()
	end

	local main, details = {}, {}
	local section
	self.controlRows = {}
	self.controlSections = {}
	self.sectionRows = {}
	self.anchorRows = {}
	local guideKeys = {}
	for _, keys in pairs(Catalog.search[route] or {}) do
		for _, key in ipairs(keys) do
			guideKeys[Normalize(Text(key))] = key
		end
	end
	for _, row in ipairs(tab.components or {}) do
		section = row.BFL_LegacySectionKey or section
		local destination = row.BFL_LegacyRoute or Catalog.sections[section] or Catalog.tabRoutes[page[1]]
		if destination == route then
			local isDetail = Catalog.details[section]
			local rows = isDetail and details or main
			rows[#rows + 1] = row
			if row.BFL_LegacyAvailable == nil then
				row.BFL_LegacyAvailable = row:IsShown()
			end
			row:SetShown(row.BFL_LegacyAvailable and (not isDetail or self.detailsOpen))
			if row.BFL_LegacySectionKey then
				self.sectionRows[section] = row
			end
			if row.BFL_LegacyAnchor then
				self.anchorRows[row.BFL_LegacyAnchor] = row
			end
			self.controlRows[#self.controlRows + 1] = row
			self.controlSections[row] = section
			self:BindSettingHelp(row, guideKeys, section)
			for _, child in ipairs(row.BFL_ReviewChildren or {}) do
				self.controlRows[#self.controlRows + 1] = child
				self.controlSections[child] = section
				self:BindSettingHelp(child, guideKeys, section)
			end
		else
			row:Hide()
		end
	end

	for _, header in pairs(self.friendSectionRows or {}) do
		header:Hide()
	end
	if route == "rows" then
		main = self:ArrangeFriendControls(tab, main)
	end

	if route == "help" then
		for _, button in ipairs(self.helpButtons) do
			button:SetParent(tab)
			PositionContentRow(button, tab)
			button:Show()
			self:BindSettingHelp(button, guideKeys)
			table.insert(main, 1, button)
		end
	end
	if #details > 0 then
		self.detailsButton:SetParent(tab)
		PositionContentRow(self.detailsButton, tab)
		self.detailsButton.label:SetText(Text("SETTINGS_LEGACY_MORE"))
		self.detailsButton.chevron:SetRotation(self.detailsOpen and -math.pi / 2 or 0)
		self.detailsButton:Show()
		main[#main + 1] = self.detailsButton
		if self.detailsOpen then
			for _, row in ipairs(details) do
				main[#main + 1] = row
			end
		end
	else
		self.detailsButton:Hide()
	end
	local shown = {}
	self.guideRows = {}
	self.guideRowsByFrame = {}
	for _, row in ipairs(main) do
		if row:IsShown() then
			shown[#shown + 1] = row
			if row.BFL_SettingGuide then
				self.guideRows[#self.guideRows + 1] = row
				self.guideRowsByFrame[row] = true
			end
			for _, child in ipairs(row.BFL_ReviewChildren or {}) do
				if child.BFL_SettingGuide then
					self.guideRows[#self.guideRows + 1] = child
					self.guideRowsByFrame[child] = true
				end
			end
		end
	end
	if self.guideEntry then
		local activeID = self.guideEntry[5]
		local resolved
		for _, row in ipairs(self.guideRows) do
			for _, entry in pairs(row.BFL_SettingGuide) do
				if row:IsShown() and entry[5] == activeID then
					self.guideRow, self.guideEntry, self.guideEntries = row, entry, { entry }
					resolved = true
					break
				end
			end
			if resolved then break end
		end
		if not resolved then
			self.guideRow, self.guideEntry, self.guideEntries, self.comparisonValue = nil, nil, nil, nil
			self.pinnedGuideID = nil
			if self.hoverTint then self.hoverTint:Hide() end
			self:SetFavoriteHovered(false)
		end
	end
	self.controlsHeight = Stack(shown, tab)
	local style = BFL:GetModule("LegacySettingsStyle")
	if style then style:OnSectionsLaidOut(shown) end
	self:Layout()
	if not self.guideEntry then
		for _, row in ipairs(self.guideRows) do
			if row.Input and row.Input:HasFocus() then
				self:ShowSettingHelp(row)
				break
			end
		end
	end
end

function Review:UpdateNavigation(category)
	local pages = {}
	for index = 3, #category do
		local route = category[index]
		local _, reason = self.settings:GetLegacyTabAvailability(Catalog.pages[route][1])
		if reason ~= "client" then
			pages[#pages + 1] = route
		end
	end

	local expanded = #pages > 1
	local visible = self.visibleNavRows
	wipe(visible)
	for _, row in ipairs(self.subButtons) do
		row:Hide()
	end
	for index, row in ipairs(self.navButtons) do
		local current = Catalog.categories[index] == category and not self.searchActive
		SelectNavigationRow(row, current and not expanded, current and expanded)
		visible[#visible + 1] = row
		if current and expanded then
			for pageIndex, route in ipairs(pages) do
				local subRow = self.subButtons[pageIndex]
				subRow.route = route
				subRow.label:SetText(Text(Catalog.pages[route][2]))
				SelectNavigationRow(subRow, route == self.route)
				subRow:Show()
				visible[#visible + 1] = subRow
			end
		end
	end
end

function Review:UpdateAvailability()
	if not self.active then return end
	if self.searchActive then
		self:ShowResults(self.search:GetText())
	elseif self.route then
		local _, reason = self.settings:GetLegacyTabAvailability(Catalog.pages[self.route][1])
		if reason == "client" then
			self:ShowHome()
		else
			self:UpdateNavigation(GetRouteCategory(self.route))
			self:Layout()
		end
	end
end

function Review:ShowPageFrame()
	HideTabFrames(self.content)
	self.settings:ClearFilterSortPreview(true)
	self.settings:HideFilterSortEditorPanel()
	self.pageFrame:Show()
	self.message:Show()
	if self.home then
		self.home:Hide()
		self.home.release:Hide()
	end
	self.listHeight = 37
	for _, button in ipairs(self.listButtons) do
		button.settingHit = nil
		button:Hide()
	end
end

local categoryIcons = {
	friends = "user", groups = "users", appearance = "layers", social = "users",
	privacy = "shield", data = "database", help = "help-circle",
}

function Review:ListButton(index, text, action, path, route)
	local row = self.listButtons[index]
	if not row then
		row = NavigationRow(self.pageFrame, text, action, 8)
		row.chevron = ReviewIcon(row, "chevron-right", 16)
		row.chevron:SetPoint("RIGHT", -10, 0)
		row.chevron:SetVertexColor(0.92, 0.76, 0.45)
		row.icon = ReviewIcon(row, "settings", 20)
		row.icon:SetPoint("LEFT", 11, 0)
		row.icon:SetVertexColor(1, 0.82, 0.3)
		row.path = Label(row, "BetterFriendlistFontDisableSmall", "")
		row.path:SetPoint("TOPLEFT", 42, -26)
		row.path:SetPoint("TOPRIGHT", -36, -26)
		row.path:SetHeight(16)
		row.path:SetWordWrap(false)
		row.divider = row:CreateTexture(nil, "BACKGROUND")
		row.divider:SetPoint("BOTTOMLEFT")
		row.divider:SetPoint("BOTTOMRIGHT")
		row.divider:SetHeight(1)
		row.divider:SetColorTexture(1, 1, 1, 0.08)
		self.listButtons[index] = row
	end

	local label = row.label
	label:SetText(text)
	row:SetScript("OnClick", action)
	local category = route and GetRouteCategory(route)
	row.icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\" .. (category and categoryIcons[category[1]] or "settings"))
	label:SetHeight(path and 20 or 27)
	label:SetPoint("LEFT", 42, path and 8 or 0)
	label:SetPoint("RIGHT", -36, path and 8 or 0)
	row.path:SetText(path or "")
	row.path:SetShown(path ~= nil)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 8, -self.listHeight)
	row:SetPoint("TOPRIGHT", -8, -self.listHeight)
	local height = path and 45 or 35
	row:SetHeight(height)
	self.listHeight = self.listHeight + height
	row:Show()
	return row
end

function Review:ClearPage()
	if self.comparisonIconEntry then
		self.comparisonIconEntry = nil
		if BetterFriendlistIconSelectorFrame then BetterFriendlistIconSelectorFrame:Hide() end
	end
	self:ClearFocus()
	if self.hoverHelp then self.hoverHelp:Hide() end
	self.guideEntries = nil
	self.pinnedGuideID, self.pinPress = nil, nil
	self.favoriteHovered = false
	self.guideRow, self.guideEntry, self.comparisonValue, self.markComparison = nil, nil, nil, nil
	if self.hoverTint then self.hoverTint:Hide() end
	if self.comparisonTimer then
		self.comparisonTimer:Cancel()
		self.comparisonTimer = nil
	end
	if self.comparisonEditor then
		self.comparisonEditorUpdating = true
		self.comparisonEditor:Hide()
		self.comparisonEditorUpdating = false
		self.comparisonEditor = nil
	end
	if self.comparisonPicker then
		self.comparisonPicker.BFL_ComparisonRow, self.comparisonPicker.BFL_ComparisonEntry = nil, nil
		self.comparisonPicker:Hide()
	end
	for _, lane in ipairs(self.comparisonLanes or {}) do
		ReleaseComparisonTooltip(lane)
		lane:Hide()
		for _, widget in ipairs(lane.widgets) do
			widget:Hide()
			widget.elementData, widget.friendData = nil, nil
		end
		wipe(lane.renderer.displayNameCache)
		BFL.LegacySettingsSocialSamples:Hide(lane)
	end
	self.guideRows = nil
	self.guideRowsByFrame = nil
	self:ReleaseSample()
	self.detailsButton:Hide()
	for _, header in pairs(self.friendSectionRows or {}) do
		header:Hide()
	end
	for _, button in ipairs(self.helpButtons) do
		button:Hide()
	end
	self.pageFrame:Hide()
	if self.home then self.home:Hide() end
	self.route = nil
	self.controlsHeight = nil
	self.sample = nil
	self.sampleGroupID = nil
	self.controlRows = {}
	self.controlSections = {}
	self.sectionRows = {}
	self.anchorRows = {}
end

function Review:ClearSearch()
	self.searchActive = false
	self.clearingSearch = true
	self.search:SetText("")
	self.search:ClearFocus()
	self.clearingSearch = nil
end

local homeTasks = {
	{ route = "rows", title = "SETTINGS_LEGACY_TASK_FRIENDS", desc = "SETTINGS_LEGACY_TASK_FRIENDS_DESC" },
	{ route = "automatic", title = "SETTINGS_LEGACY_TASK_GROUPS", desc = "SETTINGS_LEGACY_TASK_GROUPS_DESC" },
	{ route = "stream", title = "SETTINGS_LEGACY_TASK_STREAM", desc = "SETTINGS_LEGACY_TASK_STREAM_DESC" },
}

local function CreateTaskCardBorder(card)
	local pieces = {}
	-- Sample the corners and straight runs from the same outline, so their
	-- stroke profile and pixel rounding agree where the pieces meet.
	local near, far = 12 / 32, 20 / 32
	local function AddPiece(left, right, top, bottom)
		local piece = card:CreateTexture(nil, "BORDER")
		piece:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\Skinning\\task-card-edge.tga")
		piece:SetTexCoord(left, right, top, bottom)
		if piece.SetSnapToPixelGrid then piece:SetSnapToPixelGrid(false) end
		if piece.SetTexelSnappingBias then piece:SetTexelSnappingBias(0) end
		if piece.SetRoundLayoutToNearestPixel then piece:SetRoundLayoutToNearestPixel(true) end
		pieces[#pieces + 1] = piece
		return piece
	end

	local corners = {
		TOPLEFT = AddPiece(0, near, 0, near),
		TOPRIGHT = AddPiece(far, 1, 0, near),
		BOTTOMLEFT = AddPiece(0, near, far, 1),
		BOTTOMRIGHT = AddPiece(far, 1, far, 1),
	}
	for point, corner in pairs(corners) do
		corner:SetPoint(point)
	end

	local function AnchorEdge(edge, from, fromPoint, to, toPoint)
		edge:SetPoint(from, corners[from], fromPoint)
		edge:SetPoint(to, corners[to], toPoint)
		return edge
	end

	card.borderCorners = corners
	card.borderEdges = {
		top = AnchorEdge(AddPiece(near, far, 0, near), "TOPLEFT", "TOPRIGHT", "TOPRIGHT", "TOPLEFT"),
		bottom = AnchorEdge(AddPiece(near, far, far, 1), "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", "BOTTOMLEFT"),
		left = AnchorEdge(AddPiece(0, near, near, far), "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", "TOPLEFT"),
		right = AnchorEdge(AddPiece(far, 1, near, far), "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", "TOPRIGHT"),
	}
	return pieces
end

function Review:CreateHome()
	local home = CreateFrame("Frame", nil, self.frame.MainInset)
	home:SetHeight(1)
	home.BFL_AccentTextures = {}
	home.BFL_AccentFontStrings = {}
	home.BFL_SecondaryAccentFontStrings = {}

	home.title = TopText(home, "BetterFriendlistFontLarge", "BetterFriendlist", 12, 14)
	home.version = Label(home, "BetterFriendlistFontDisableSmall", string.format(L.CHANGELOG_HEADER_VERSION, BFL.VERSION))
	home.version:SetPoint("LEFT", home.title, "RIGHT", 12, 0)
	home.intro = Label(home, "BetterFriendlistFontHighlight", Text("SETTINGS_LEGACY_HOME_WELCOME"))
	home.intro:SetPoint("TOPLEFT", home.title, "BOTTOMLEFT", 0, -10)

	home.taskArea = CreateFrame("Frame", nil, home)
	home.taskArea:SetPoint("RIGHT", home, "RIGHT", -12, 0)
	home.tasks = {}
	for index, task in ipairs(homeTasks) do
		local card = CreateFrame("Button", nil, home.taskArea)
		card.BFL_DarkNoButtonChrome = true
		local border = CreateTaskCardBorder(card)
		local function SetBorderColor(r, g, b, a)
			for _, piece in ipairs(border) do
				piece:SetVertexColor(r, g, b, a)
			end
		end
		SetBorderColor(1, 1, 1, 0.16)
		card:HookScript("OnEnter", function()
			SetBorderColor(1, 0.82, 0.3, 0.40)
		end)
		card:HookScript("OnLeave", function()
			SetBorderColor(1, 1, 1, 0.16)
		end)
		card.title = Label(card, "BetterFriendlistFontNormal", Text(task.title))
		card.desc = Label(card, "BetterFriendlistFontHighlightSmall", Text(task.desc))
		card:SetScript("OnClick", function() self:Navigate(task.route) end)
		home.tasks[index] = card
	end

	local changelog = BFL:GetModule("Changelog")
	local rule = home:CreateTexture(nil, "ARTWORK")
	rule:SetPoint("TOPLEFT", home.taskArea, "BOTTOMLEFT", 0, -12)
	rule:SetPoint("RIGHT", home, "RIGHT", -12, 0)
	rule:SetHeight(1)
	rule:SetColorTexture(1, 1, 1, 0.14)
	home.rule = rule
	home.release = CreateFrame("Frame", nil, self.pageFrame)
	home.release:SetAllPoints()
	home.releaseTitle = Label(home.release, "BetterFriendlistFontNormalLarge", Text("SETTINGS_CENTER_PAGE_CHANGELOG"))
	home.releaseTitle:SetPoint("TOPLEFT", 12, -8)
	home.notes = CreateFrame("Frame", nil, home.release)
	home.notes:SetPoint("TOPLEFT", home.releaseTitle, "BOTTOMLEFT", 0, -6)
	home.notes:SetPoint("RIGHT", -8, 0)
	home.notes:SetHeight(1)
	self.home = home

	home.entries = changelog:CreateReleaseEntries(home.notes, home, function() self:RefreshHeight() end)
end

function Review:LayoutHome()
	local home = self.home
	local width = self.content:GetWidth() - 24
	home.intro:SetWidth(width)
	local columns = width >= 570 and 3 or 1
	local compact = columns == 1 and self.frame:GetHeight() < 520
	home.intro:SetShown(not compact)
	home.taskArea:SetPoint("TOPLEFT", compact and home.title or home.intro, "BOTTOMLEFT", 0, compact and -8 or -14)
	local gap = compact and 6 or 8
	local cardWidth = (width - gap * (columns - 1)) / columns
	-- The outline is 2 of the 12 source pixels in each slice. Keep at least
	-- six screen pixels per slice so the straight runs never drop below one.
	local borderSize = PixelUtil and PixelUtil.GetNearestPixelSize
		and PixelUtil.GetNearestPixelSize(7, home.taskArea:GetEffectiveScale(), 6) or 7
	local y = 0
	for first = 1, #home.tasks, columns do
		local height = 0
		for index = first, math.min(#home.tasks, first + columns - 1) do
			local card = home.tasks[index]
			card:ClearAllPoints()
			card:SetPoint("TOPLEFT", (index - first) * (cardWidth + gap), -y)
			card:SetWidth(cardWidth)
			for _, corner in pairs(card.borderCorners) do
				corner:SetSize(borderSize, borderSize)
			end
			local edges = card.borderEdges
			edges.top:SetHeight(borderSize)
			edges.bottom:SetHeight(borderSize)
			edges.left:SetWidth(borderSize)
			edges.right:SetWidth(borderSize)
			local textWidth = cardWidth - 28
			card.title:SetPoint("TOPLEFT", 14, compact and -7 or -11)
			card.desc:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, compact and -2 or -4)
			card.title:SetWidth(textWidth)
			card.desc:SetWidth(textWidth)
			local titleHeight = math.max(card.title:GetStringHeight(), card.title:GetUnboundedStringWidth() > textWidth and 30 or 16)
			local minDescHeight = columns == 1 and (card.desc:GetUnboundedStringWidth() > textWidth and 27 or 17) or 35
			local descHeight = math.max(card.desc:GetStringHeight(), minDescHeight)
			card.title:SetHeight(titleHeight)
			card.desc:SetHeight(descHeight)
			card.title:SetJustifyV("TOP")
			card.desc:SetJustifyV("TOP")
			height = math.max(height, titleHeight + descHeight + (compact and 19 or 27))
		end
		for index = first, math.min(#home.tasks, first + columns - 1) do
			home.tasks[index]:SetHeight(height)
		end
		y = y + height + gap
	end
	home.taskArea:SetHeight(y - gap)
	BFL:GetModule("Changelog"):ApplySurfaceAccent(home)
end

function Review:ShowHome(section)
	self:ClearSearch()
	self:ClearPage()
	self:UpdateNavigation(Catalog.categories[1])
	self:ShowPageFrame()
	if not self.home then
		self:CreateHome()
	end
	self.message:Hide()
	self.home:Show()
	self.home.release:Show()
	BFL:GetModule("Changelog"):RefreshReleaseBadges(self.home.entries)
	self:Layout()
	self:ResetScroll()
	if section then
		self:Focus(self.home[section])
	end
end

function Review:Navigate(route, hit)
	local homeTarget = route == "help" and hit and Catalog.homeTargets[hit.key]
	if homeTarget == "support" then
		self:ShowHome()
		self.supportButtons[1]:Click()
		return
	end
	if homeTarget then
		self:ShowHome(homeTarget)
		return
	end
	local page = Catalog.pages[route]
	if not page then
		self:ShowHome()
		return
	end
	local enabled, reason = self.settings:GetLegacyTabAvailability(page[1])
	local requiredTheme = route == "theme" and hit and Catalog.themeSections[hit.section]
	local themeRequirement
	if requiredTheme then
		local theme = BFL:GetEffectiveTheme()
		if requiredTheme and theme ~= requiredTheme then
			themeRequirement = Text(requiredTheme == "dark" and "SETTINGS_THEME_DARK" or "SETTINGS_THEME_CUSTOM")
		end
		if themeRequirement then enabled, reason = false, "theme" end
	end
	if enabled and route == "rowFonts" and hit and hit.section == "SETTINGS_FONT_TABS_TITLE" then
		local friendsUI = BFL:GetModule("FriendsUI")
		if friendsUI and friendsUI:IsModernActive() then
			enabled, reason = false, "legacy"
		end
	end
	if reason == "client" then
		self:ShowHome()
		return
	end
	self:ClearSearch()
	self:ClearPage()
	self.route = route
	self.detailsOpen = hit and Catalog.details[hit.section] == true or false
	if not enabled then
		self:UpdateNavigation(GetRouteCategory(route))
		self:ShowPageFrame()
		local prerequisite = reason == "beta" and "SETTINGS_LEGACY_NEEDS_BETA"
			or (reason == "legacy" and "SETTINGS_LEGACY_NEEDS_CLASSIC_TABS" or "SETTINGS_LEGACY_NEEDS_MODERN")
		self.message:SetText(themeRequirement and Text("SETTINGS_LEGACY_NEEDS_THEME"):format(themeRequirement) or Text(prerequisite))
		if reason == "theme" then
			self:ListButton(1, Text("SETTINGS_THEME_DROPDOWN"), function() self:Navigate("theme") end)
		elseif reason == "beta" then
			self:ListButton(1, Text("SETTINGS_BETA_FEATURES_TITLE"), function() self:Navigate("help") end)
		else
			self:ListButton(1, Text("SETTINGS_FRIENDS_UI_STYLE_HEADER"), function() self:Navigate("layout") end)
		end
		self:Layout()
		self:ResetScroll()
		return
	end

	self.sample, self.sampleIndex = page.sample, 1
	local filterMode = route == "filters" and hit and Catalog.filterSearchModes[hit.key]
	if filterMode then
		local filterTab = self.content.FilterSortTab
		filterTab.bflBuilderKind = filterMode
		filterTab.bflFilterSortCreate = nil
	end
	self:UpdateNavigation(GetRouteCategory(route))
	self:Layout()
	self.settings:SelectCategory(page[1])
	self:RefreshHeight()
	self:ResetScroll()

	if hit then
		local frame = hit.anchor and self.anchorRows[hit.anchor]
		local row
		if not frame and hit.key then
			frame, row = FindVisibleControl(self, hit.key, hit.section)
			local fallback = Catalog.searchFallbacks[hit.key]
			if not frame and fallback then
				frame, row = FindVisibleControl(self, fallback[1], fallback[2])
			end
			if not frame and route == "help" then
				local label = Normalize(Text(hit.key))
				for _, button in ipairs(self.helpButtons) do
					if FindLabel(button, label, 0) then
						frame = button
						break
					end
				end
			end
		end
		frame = frame or self.sectionRows[hit.section]
		self:Focus(frame, row or frame, hit.key)
	end
end

function Review:OpenLegacyRoute(tab, anchor)
	local route = Catalog.links[anchor] or Catalog.tabRoutes[tab or 1]
	local section = anchor == "friendInfoFormatting" and "SETTINGS_INFO_FORMAT_HEADER" or nil
	self:Navigate(route, anchor and { anchor = anchor, section = section } or nil)
end

local function Matches(words, text)
	for _, word in ipairs(words) do
		if not text:find(word, 1, true) then
			return false
		end
	end
	return #words > 0
end

local function SearchLabelScore(words, query, label)
	local name = Normalize(label):gsub("%s+", " ")
	if name == query then return 50 end
	if not Matches(words, name) then return 0 end
	local tokens = " " .. name:gsub("%p", " ")
	for _, word in ipairs(words) do
		if not tokens:find(" " .. word, 1, true) then return 20 end
	end
	return 30
end

local MAX_SEARCH_SELECTIONS = 128
local MAX_SEARCH_USES = 10
local MAX_LEARNED_QUERY_BYTES = 128

function Review:OpenSearchResult(query, hit)
	local db = BFL:GetModule("DB")
	if db and #query <= MAX_LEARNED_QUERY_BYTES then
		local history = db:Get("settingsSearchSelections")
		if type(history) ~= "table" then
			history = {}
			db:Set("settingsSearchSelections", history)
		end
		local uses = 0
		for index, selection in ipairs(history) do
			if type(selection) == "table" and selection.query == query and selection.id == hit.id then
				uses = tonumber(selection.uses) or 0
				table.remove(history, index)
				break
			end
		end
		table.insert(history, 1, { query = query, id = hit.id, uses = math.min(uses + 1, MAX_SEARCH_USES) })
		while #history > MAX_SEARCH_SELECTIONS do table.remove(history) end
	end
	self:Navigate(hit.route, hit)
end

function Review:SubmitSearch(editBox)
	editBox:ClearFocus()
	local first, second = self.listButtons[1], self.listButtons[2]
	if self.searchActive and first and first.settingHit and first:IsShown()
		and not (second and second.settingHit and second:IsShown()) then
		first:Click()
	end
end

function Review:ShowResults(query)
	self.searchActive = true
	self:ClearPage()
	self:UpdateNavigation(Catalog.categories[1])
	self:ShowPageFrame()
	local words = {}
	for word in Normalize(query):gmatch("%S+") do
		words[#words + 1] = word
	end
	query = table.concat(words, " ")
	local uses = {}
	local db = BFL:GetModule("DB")
	local history = db and db:Get("settingsSearchSelections")
	if type(history) == "table" then
		for _, selection in ipairs(history) do
			if type(selection) == "table" and selection.query == query and type(selection.id) == "string" then
				uses[selection.id] = math.max(0, math.min(tonumber(selection.uses) or 0, MAX_SEARCH_USES))
			end
		end
	end
	local hits = {}
	local currentTheme = BFL:GetEffectiveTheme()
	for _, category in ipairs(Catalog.categories) do
		for index = 3, #category do
			local route = category[index]
			local page = Catalog.pages[route]
			local _, reason = self.settings:GetLegacyTabAvailability(page[1])
			if reason ~= "client" then
				local pageLabel = Text(page[2])
				local categoryLabel = Text(category[2])
				local path = categoryLabel .. " / " .. pageLabel
				local pageScore = SearchLabelScore(words, query, pageLabel)
				pageScore = pageScore > 0 and pageScore + 5 or (Matches(words, Normalize(path)) and 5 or 0)
				for section, keys in pairs(Catalog.search[route] or {}) do
					local sectionName = section ~= page[2] and OptionalText(section) or nil
					for _, key in ipairs(keys) do
						local label = Text(key)
						local localizedDescription = OptionalText(key .. "_DESC") or OptionalText(key .. "_TOOLTIP_DESC") or ""
						local alias = Catalog.aliases[key] and Text(Catalog.aliases[key]) or ""
						if route == "automatic" and (key == "GROUP_FAVORITES" or key == "GROUP_INGAME" or key == "GROUP_RECENTLY_ADDED") then
							alias = Text("SETTINGS_SHOW_GROUP_FMT"):format(label)
						end
						local context = sectionName and section ~= key and sectionName or ""
						local terms = Normalize(table.concat({ label, localizedDescription, alias, context }, " "))
						local ruleset = key == "SETTINGS_SHOW_RULESET_NAME" or key == "BROKER_COLUMN_RULESET"
							or key == "BROKER_SETTINGS_RULESET_COLOR"
						local realm = key == "SETTINGS_SHOW_REALM_NAME" or key == "BROKER_COLUMN_REALM"
							or key == "BROKER_SETTINGS_REALM_COLOR"
						local wrongClient = (ruleset and not BFL.IsForever) or (realm and BFL.IsForever)
						if not wrongClient and Matches(words, terms) then
							local score = math.max(10, SearchLabelScore(words, query, label))
							local theme = Catalog.themeSections[section]
							if theme == currentTheme then score = score + 1 end
							if key == page[2] and section == key then
								pageScore = math.max(pageScore, score)
							else
								local id = route .. "/" .. section .. "/" .. key
								local hitPath = context ~= "" and (path .. " / " .. context) or path
								hits[#hits + 1] = {
									id = id, route = route, key = key, section = section, label = label, path = hitPath,
									score = score + ((not theme or theme == currentTheme) and (uses[id] or 0) * 2 or 0),
								}
							end
						end
					end
				end
				if pageScore > 0 then
					hits[#hits + 1] = {
						id = route, route = route, label = pageLabel, path = categoryLabel,
						score = pageScore + (uses[route] or 0) * 2,
					}
				end
			end
		end
	end
	table.sort(hits, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.label ~= b.label then
			return a.label < b.label
		end
		return a.id < b.id
	end)
	self.message:SetText(Text(#hits > 0 and "SETTINGS_LEGACY_RESULTS" or "SETTINGS_LEGACY_NO_RESULTS"))
	for i, hit in ipairs(hits) do
		local button = self:ListButton(i, hit.label, function()
			self:OpenSearchResult(query, hit)
		end, hit.path, hit.route)
		button.settingHit = hit
	end
	self:Layout()
	self:ResetScroll()
end

function Review:LayoutSupport(width)
	local changelog = BFL:GetModule("Changelog")
	local friendsUI = BFL.IsMainline and BFL:GetModule("FriendsUI")
	local style = friendsUI and friendsUI:IsModernActive() and "modern" or "legacy"
	local buttons = self.supportStyles[style]
	if not buttons then
		buttons = changelog:CreateSupportButtons(self.support, self.support, style == "modern")
		self.supportStyles[style] = buttons
		local settingsStyle = BFL:GetModule("LegacySettingsStyle")
		if settingsStyle then settingsStyle:SkinActions(buttons) end
	end
	if self.supportButtons and self.supportButtons ~= buttons then
		for _, button in ipairs(self.supportButtons) do button:Hide() end
	end
	self.supportButtons = buttons
	local maxWidth = (width - 40) / #buttons
	local offset = 0
	for index = #buttons, 1, -1 do
		local button = buttons[index]
		local buttonWidth = math.min(maxWidth, math.max(76, button:GetFontString():GetUnboundedStringWidth() + 37))
		button:SetPoint("RIGHT", -offset, 0)
		button:SetSize(buttonWidth, 25)
		button:Show()
		offset = offset + buttonWidth + 7
	end
	self.support:Show()
	changelog:ApplySurfaceAccent(self.support)
end

function Review:Create(frame, settings)
	self.frame, self.settings = frame, settings
	self.scroll = frame.ContentScrollFrame
	self.content = self.scroll.Content
	self.sidebar = CreateFrame("Frame", nil, frame.CategoryList)
	self.sidebar:SetAllPoints()
	self.navButtons = {}
	self.subButtons = {}
	self.visibleNavRows = {}
	for index, category in ipairs(Catalog.categories) do
		self.navButtons[index] = NavigationRow(self.sidebar, Text(category[2]), function()
			if not self.route or GetRouteCategory(self.route) ~= category then
				self:Navigate(category[3])
			end
		end)
	end
	for index = 1, 4 do
		self.subButtons[index] = NavigationRow(self.sidebar, "", function(row)
			if row.route ~= self.route or self.pageFrame:IsShown() then
				self:Navigate(row.route)
			end
		end, 24, true)
		self.subButtons[index]:Hide()
	end

	local inset = frame.MainInset
	self.support = CreateFrame("Frame", nil, inset)
	self.support.BFL_AccentTextures = {}
	self.support:SetPoint("BOTTOMLEFT", 10, 4)
	self.support:SetPoint("BOTTOMRIGHT", -12, 4)
	self.support:SetHeight(31)
	self.supportStyles = {}
	self.search = CreateFrame("EditBox", nil, inset, "SearchBoxTemplate")
	self.search:SetAutoFocus(false)
	self.search:SetJustifyH("LEFT")
	-- Match the placeholder anchors from SearchBoxTemplate.
	self.search:SetTextInsets(16, 20, 0, 0)
	self.search:SetPoint("TOPLEFT", 14, -8)
	self.search:SetPoint("TOPRIGHT", -12, -8)
	self.search:SetHeight(24)
	self.search:SetFrameLevel(self.scroll:GetFrameLevel() + 3)
	if self.search.Instructions then
		self.search.Instructions:SetText(Text("SETTINGS_LEGACY_SEARCH"))
	end
	self.search:HookScript("OnEnterPressed", function(editBox)
		self:SubmitSearch(editBox)
	end)
	self.search:HookScript("OnTextChanged", function(editBox)
		if not self.active or self.clearingSearch then
			return
		end
		local query = editBox:GetText() or ""
		if Normalize(query) ~= "" then
			self:ShowResults(query)
		elseif self.searchActive then
			self:ShowHome()
		end
	end)

	self.pageFrame = CreateFrame("Frame", nil, self.content)
	self.pageFrame:SetAllPoints()
	self.message = Label(self.pageFrame, "BetterFriendlistFontHighlight", "")
	self.message:SetPoint("TOPLEFT", 8, -8)
	self.message:SetPoint("TOPRIGHT", -8, -8)
	self.listButtons = {}
	self.detailsButton = NavigationRow(self.content, "", function()
		self.detailsOpen = not self.detailsOpen
		local page = Catalog.pages[self.route]
		self:OnBuilt(self.content[Catalog.tabs[page[1]]])
	end, 33)
	self.detailsButton:SetHeight(36)
	self.detailsButton.BFL_SettingsSectionHeader = true
	self.detailsButton.label:SetFontObject("BetterFriendlistFontNormal")
	self.detailsButton:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
	self.detailsButton.chevron = ReviewIcon(self.detailsButton, "chevron-right", 16)
	self.detailsButton.chevron:SetPoint("LEFT", 11, 0)
	self.detailsButton.chevron:SetVertexColor(0.92, 0.76, 0.45)

	self.helpButtons = {
		TextLink(self.content, Text("SETTINGS_CENTER_HELP_SUPPORT"), function()
			self.supportButtons[1]:Click()
		end),
		TextLink(self.content, Text("CHANGELOG_TITLE"), function()
			self:ShowHome("releaseTitle")
		end),
	}
	self.helpButtons[1].BFL_SearchLabels = { Text("SETTINGS_CENTER_HELP_SUPPORT") }
	self.helpButtons[2].BFL_SearchLabels = { Text("CHANGELOG_TITLE") }
	for _, button in ipairs(self.helpButtons) do
		button:Hide()
	end

	local highlight = self.content:CreateTexture(nil, "OVERLAY")
	highlight:Hide()
	self.highlight = highlight

	local previewTemplate = BFL.IsMainline and "ButtonFrameBaseTemplate" or "InsetFrameTemplate"
	self.preview = CreateFrame("Frame", nil, inset)
	self.preview.BFL_DarkManagedSubtree = true
	-- A complete Friends Frame sample brings its own chrome.
	local shell = CreateFrame("Frame", nil, self.preview, previewTemplate)
	self.previewShell = shell
	shell:SetAllPoints(self.preview)
	shell:SetFrameLevel(math.max(0, self.preview:GetFrameLevel() - 1))
	if BFL.IsMainline then
		ButtonFrameTemplate_HidePortrait(shell)
		shell.BFL_PreviewWindowBorder = true
		shell.Bg:Hide()
		shell.TopTileStreaks:Hide()
		shell.TitleContainer:Hide()
		shell.CloseButton:Hide()
	end
	self.preview:SetHeight(125)
	self.preview:Hide()
	local help = CreateFrame("Frame", nil, inset)
	self.hoverHelp = help
	local helpTitle = TopText(help, "BetterFriendlistFontNormal", Text("SETTINGS_GUIDE_TITLE"), 14, 12)
	help.pinButton = TextLink(help, Text("SETTINGS_GUIDE_PIN"), function()
		local row = self.guideRow
		for slot, entry in pairs(row and row.BFL_SettingGuide or {}) do
			if entry == self.guideEntry then self:ToggleSettingHelpPin(row, slot); break end
		end
	end, true)
	help.pinButton:SetPoint("RIGHT", help, "TOPRIGHT", -14, -20)
	help.pinButton:Hide()
	help:SetScript("OnEvent", function(_, event, button)
		self:HandleSettingHelpClick(event, button)
	end)
	help:SetScript("OnShow", function(frame)
		BFL.Compat.RegisterEvent(frame, "GLOBAL_MOUSE_DOWN")
		BFL.Compat.RegisterEvent(frame, "GLOBAL_MOUSE_UP")
	end)
	help:SetScript("OnHide", function(frame)
		frame:UnregisterAllEvents()
		self.pinPress = nil
	end)
	local divider = help:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", helpTitle, "BOTTOMLEFT", 0, -6)
	divider:SetPoint("RIGHT", -14, 0)
	divider:SetHeight(1)
	divider:SetColorTexture(1, 1, 1, 0.16)
	help.scroll = self.settings:CreateSettingsScrollFrame(help)
	help.scroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -9)
	help.scroll:SetPoint("BOTTOMRIGHT", -17, 6)
	help.content = CreateFrame("Frame", nil, help.scroll)
	help.content:SetSize(1, 1)
	help.scroll:SetScrollChild(help.content)
	help.sections = {}
	local hoverElapsed = 0
	help:SetScript("OnUpdate", function(_, elapsed)
		hoverElapsed = hoverElapsed + elapsed
		if hoverElapsed >= 0.04 then
			hoverElapsed = 0
			self:UpdateSettingHelpHover()
		end
	end)
	hooksecurefunc(BFL_Tooltip, "Show", function(tooltip)
		if self.active and self.guideRowsByFrame and self.hoverHelp:IsShown() then
			local row = self:FindGuideRow(tooltip:GetOwner())
			if row and row:IsVisible() then
				tooltip:Hide()
				if not self:IsHelpInteractionLocked() then
					self:ShowSettingHelp(row, self:GetGuideSlot(row), self.route ~= "friendTabs")
				end
			end
		end
	end)
	help:Hide()
	self.previewTitle = Label(self.preview, "BetterFriendlistFontNormal", Text("SETTINGS_LEGACY_SAMPLE"))
	self.previewTitle:SetPoint("TOPLEFT", 8, -8)
	self.previewTitle:SetPoint("TOPRIGHT", -75, -8)
	local previewRule = self.preview:CreateTexture(nil, "ARTWORK")
	previewRule:SetPoint("TOPLEFT", 8, -28)
	previewRule:SetPoint("TOPRIGHT", -8, -28)
	previewRule:SetHeight(1)
	previewRule:SetColorTexture(1, 1, 1, 0.16)
	self.previewRule = previewRule
	self.previewNote = Label(self.preview, "BetterFriendlistFontHighlightSmall", Text("SETTINGS_LEGACY_SAMPLE_EMPTY_HIDDEN"))
	self.sampleNext = NavigationRow(self.preview, "", function()
		self.sampleGroupID = nil
		self.sampleIndex = self.sampleIndex % self.sampleCount + 1
		if self.sampleViewport then self.sampleViewport:SetVerticalScroll(0) end
		self:QueueSample()
	end, 8, true)
	self.sampleNext:SetSize(66, 23)
	self.sampleNext:SetPoint("TOPRIGHT", -5, -5)
	self.sampleNext.label:SetPoint("RIGHT", -4, 0)
	self.sampleNext.label:SetJustifyH("RIGHT")
	self.sampleNext:Hide()
	self.sampleWidgets = {}

	inset:HookScript("OnSizeChanged", function() self:Layout() end)
	frame:HookScript("OnHide", function(owner)
		-- The friends window can hide its child without closing settings.
		if self.active and owner:IsShown() then
			self:ReleaseSample()
		else
			self:Deactivate()
		end
	end)
	frame:HookScript("OnShow", function()
		if self.active then self:Layout() end
	end)
end

function Review:Open(frame, settings, tab, anchor)
	if self.active then
		if tab or anchor then
			self:OpenLegacyRoute(tab, anchor)
		else
			self:ShowHome()
		end
		return
	end
	local original = {}
	for _, child in ipairs({ frame.CategoryList:GetChildren() }) do
		if child ~= self.sidebar and child:IsShown() then
			original[#original + 1] = child
			child:Hide()
		end
	end
	if not self.frame then
		self:Create(frame, settings)
	end
	self.saved = {
		categories = original,
		width = frame:GetWidth(),
		height = frame:GetHeight(),
		sidebar = frame.CategoryList:GetWidth(),
		contentWidth = self.content:GetWidth(),
		scrollPoints = ReadPoints(self.scroll),
	}
	local width = math.min(1170, UIParent:GetWidth() - 24)
	local height = math.min(800, UIParent:GetHeight() - 42)
	frame:SetSize(width, height)
	frame.CategoryList:SetWidth(width < 800 and 156 or 174)
	self.active = true
	self.sidebar:Show()
	self.search:Show()
	if tab or anchor then
		self:OpenLegacyRoute(tab, anchor)
	else
		self:ShowHome()
	end
	settings:RefreshVisibleWindowAnchor()
	local style = BFL:GetModule("LegacySettingsStyle")
	if style then style:Refresh() end
end

function Review:Deactivate()
	if not self.active then
		return
	end
	self.active = nil
	self:ClearPage()
	self.search:Hide()
	self.support:Hide()
	self.sidebar:Hide()
	local saved = self.saved
	self.frame:SetSize(saved.width, saved.height)
	self.frame.CategoryList:SetWidth(saved.sidebar)
	self.content:SetWidth(saved.contentWidth)
	self.scroll.BFL_SettingsContentHeight = nil
	RestorePoints(self.scroll, saved.scrollPoints)
	for _, button in ipairs(saved.categories) do
		button:Show()
	end
	self.saved = nil
end
