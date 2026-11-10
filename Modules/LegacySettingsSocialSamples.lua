
local _, BFL = ...
local L = BFL.L
local Samples = {}
BFL.LegacySettingsSocialSamples = Samples

function Samples:CharacterName(key)
	local name = L[key]
	if BFL.IsForever then
		return name .. " " .. L.SETTINGS_LEGACY_SAMPLE_SURNAME
	end
	return name
end

local function GetPeople()
	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 60
	local playerLevel = UnitLevel and UnitLevel("player") or maxLevel
	local classes = LOCALIZED_CLASS_NAMES_MALE or LOCALIZED_CLASS_NAMES_FEMALE or {}
	return {
		{ name = Samples:CharacterName("SETTINGS_LEGACY_SAMPLE_ONLINE"), class = "MAGE", className = classes.MAGE,
			level = math.max(1, math.min(maxLevel - 1, playerLevel - 8)), role = "DAMAGER" },
		{ name = Samples:CharacterName("SETTINGS_LEGACY_SAMPLE_LONG"), class = "WARRIOR", className = classes.WARRIOR,
			level = maxLevel, role = "TANK" },
		{ name = Samples:CharacterName("SETTINGS_LEGACY_SAMPLE_OFFLINE"), class = "DRUID", className = classes.DRUID,
			level = math.max(1, math.min(maxLevel, playerLevel + 4)), role = "HEALER" },
	}
end

local function MakeInert(row)
	for _, script in ipairs({ "OnClick", "OnDoubleClick", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp" }) do
		row:SetScript(script, nil)
	end
	row:EnableMouse(false)
end

local function GetRow(scene, index, template, setup)
	local row = scene.rows[index]
	if not row then
		row = CreateFrame("Button", nil, scene, template)
		if setup then
			setup(row)
		end
		MakeInert(row)
		scene.rows[index] = row
	end
	return row
end

function Samples:ShowLegacyTabFonts(parent, width, y)
	local scene = parent.legacyTabFonts
	if not scene then
		scene = CreateFrame("Frame", nil, parent)
		local template = BFL.IsClassic and "CharacterFrameTabButtonTemplate" or "PanelTabButtonTemplate"
		-- Classic's template and panel helpers resolve the slices by global name.
		scene.selected = CreateFrame("Button", BFL.IsClassic and "BFLSettingsSampleSelectedTab" or nil, scene, template)
		scene.selected:SetText(BFL.IsClassic and FRIENDS or CONTACTS_TAB_TITLE)
		scene.selected:SetPoint("TOPLEFT", 3, 0)
		scene.other = CreateFrame("Button", BFL.IsClassic and "BFLSettingsSampleOtherTab" or nil, scene, template)
		scene.other:SetText(WHO)
		scene.other:SetPoint("LEFT", scene.selected, "RIGHT", -8, 0)
		MakeInert(scene.selected)
		MakeInert(scene.other)
		parent.legacyTabFonts = scene
	end
	scene:ClearAllPoints()
	scene:SetPoint("TOPLEFT", 8, -y)
	scene:SetWidth(width)
	local maxTabWidth = (width + 2) / 2
	BFL:ApplyLegacyTabSampleFont(scene.selected, true, maxTabWidth)
	BFL:ApplyLegacyTabSampleFont(scene.other, false, maxTabWidth)
	scene:SetHeight(math.max(scene.selected:GetHeight(), scene.other:GetHeight()) + 6)
	scene:Show()
	return scene:GetHeight()
end

local function PlaceRow(row, width, y)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 0, -y)
	row:SetWidth(width)
	row:Show()
	return y + row:GetHeight()
end

local whoColumns = {
	{ key = "name", label = function() return NAME end },
	{ key = "variable", label = function() return ZONE end },
	{ key = "level", label = function() return LEVEL_ABBR or LEVEL end },
	{ key = "class", label = function() return CLASS end },
}

local function RenderWho(scene, width, db, _, _, variant)
	local WhoFrame = BFL:GetModule("WhoFrame")
	scene.renderer = scene.renderer or setmetatable({}, { __index = WhoFrame })
	local renderer = scene.renderer
	renderer.GetSetting = function(_, key, default) return db:Get(key, default) end
	local friendsUI = BFL:GetModule("FriendsUI")
	local modern = friendsUI and friendsUI:IsModernActive()
	local style = modern and "modern" or "legacy"
	local columns = WhoFrame:GetResultColumnWidths(width - 8, 70)
	scene.columnStyles = scene.columnStyles or {}
	scene.columnStyles[style] = scene.columnStyles[style] or {}
	local headers = scene.columnStyles[style]
	if scene.columns and scene.columns ~= headers then
		for _, header in ipairs(scene.columns) do header:Hide() end
	end
	scene.columns = headers
	local x = 4
	for index, column in ipairs(whoColumns) do
		local header = headers[index]
		if not header then
			if modern and column.key == "variable" then
				header = CreateFrame("DropdownButton", nil, scene, "WowStyle1DropdownTemplate")
				if header.Arrow then header.Arrow:EnableMouse(false) end
			elseif modern then
				header = CreateFrame("Button", nil, scene)
				header:SetNormalFontObject(BetterFriendlistFontHighlightSmall)
			else
				header = CreateFrame("Button", nil, scene,
					BFL.IsClassic and "ColumnDisplayButtonTemplate" or "ColumnDisplayButtonNoScriptsTemplate")
			end
			header:SetText(column.label() or "")
			MakeInert(header)
			headers[index] = header
		end
		header:SetPoint("TOPLEFT", x, 0)
		header:SetWidth(columns[column.key])
		if modern then friendsUI:StyleModernWhoHeader(header) end
		header:Show()
		x = x + columns[column.key] - 1
	end

	local y = headers[1]:GetHeight() + 3
	for index, person in ipairs(GetPeople()) do
		local row = GetRow(scene, index, "BetterWhoListButtonTemplate")
		y = PlaceRow(row, width, y)
		renderer:InitButton(row, {
			index = index,
			dataIndex = index,
			info = {
				fullName = person.name,
				filename = person.class,
				classStr = person.className,
				level = person.level,
				area = L.SETTINGS_LEGACY_SAMPLE_ZONE,
			},
		}, columns)
	end
	if scene.actionHint then scene.actionHint:Hide() end
	if variant and variant[1] == "whoDoubleClickAction" then
		local action = db:Get("whoDoubleClickAction", "whisper")
		local label = action == "invite" and L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE or L.WHO_TOOLTIP_HINT_DBLCLICK
		scene.actionHint = scene.actionHint or scene:CreateFontString(nil, "ARTWORK", "GameTooltipText")
		scene.actionHint:SetPoint("TOPLEFT", 0, -y - 6)
		scene.actionHint:SetWidth(width)
		scene.actionHint:SetJustifyH("LEFT")
		scene.actionHint:SetText(label)
		scene.actionHint:Show()
		y = y + scene.actionHint:GetStringHeight() + 6
	end
	return y
end

function Samples:GetGuildMembers()
	local people = GetPeople()
	local members = {}
	for index, person in ipairs(people) do
		members[index] = {
			settingsSample = true,
			_isMock = true,
			name = person.name,
			fullName = person.name .. "-" .. L.SETTINGS_LEGACY_SAMPLE_REALM,
			sampleNickname = index == 1 and people[3].name or nil,
			classFile = person.class,
			className = person.className,
			level = person.level,
			rank = index == 2 and GUILD_RANK0_DESC or GUILD_RANK4_DESC,
			rankIndex = index == 2 and 0 or 4,
			zone = L.SETTINGS_LEGACY_SAMPLE_ZONE,
			online = index ~= 3,
			lastOnlineHours = index == 3 and 4 or 0,
		}
	end
	return members
end

function Samples:BuildGuildBrokerSample(comparison)
	local members = self:GetGuildMembers()
	members[1].note = L.SETTINGS_LEGACY_SAMPLE_ZONE
	members[1].professions = "|TInterface\\Icons\\Trade_Alchemy:14:14:0:0|t"
	members[1].isAFK = true
	members[2].officerNote = L.SETTINGS_LEGACY_SAMPLE_REALM
	if comparison then
		members[2].sampleNickname = members[1].name
		members[2].zone = L.SETTINGS_LEGACY_SAMPLE_REALM
		for _, member in ipairs(members) do
			member.note = member.note or L.SETTINGS_LEGACY_SAMPLE_ZONE
			member.officerNote = member.officerNote or L.SETTINGS_LEGACY_SAMPLE_REALM
			member.professions = member.professions or members[1].professions
		end
	end
	local exampleCount = #members
	for index = exampleCount + 1, comparison and exampleCount or 210 do
		local example = members[(index - 1) % exampleCount + 1]
		local member = {}
		for key, value in pairs(example) do member[key] = value end
		member.fullName = member.name .. "-" .. L.SETTINGS_LEGACY_SAMPLE_REALM .. index
		members[index] = member
	end
	return {
		guildName = L.SETTINGS_LEGACY_SAMPLE_REALM,
		playerFullName = members[2].fullName,
		members = members,
		rowBudget = 3,
	}
end

local function RenderGuild(scene, width, db, _, _, variant)
	local GuildFrame = BFL:GetModule("GuildFrame")
	scene.renderer = scene.renderer or setmetatable({
		sortReversed = {},
		searchText = "",
		professionFilterID = false,
		selectedMember = false,
	}, { __index = GuildFrame })
	if variant and variant[1] == "enableGuildTab" and not db:Get("enableGuildTab", false) then
		for _, row in ipairs(scene.rows) do row:Hide() end
		return 0
	end
	local renderer = scene.renderer
	renderer.settingsSampleDB = db
	renderer.filterMode = db:Get("guildTabFilterMode", "online")
	renderer.sortMode = db:Get("guildTabSortMode", "rank")
	renderer.rowContentWidth = width

	local members = {}
	for _, member in ipairs(Samples:GetGuildMembers()) do
		if renderer:PassesFilter(member) then
			members[#members + 1] = member
		end
	end
	renderer:SortMembers(members)

	local y = 0
	for index, member in ipairs(members) do
		local row = GetRow(scene, index, "BFL_GuildMemberButtonTemplate", function(button)
			renderer:SetupMemberButton(button, true)
		end)
		y = PlaceRow(row, width, y)
		renderer:UpdateMemberButton(row, member, index)
	end
	for index = #members + 1, #scene.rows do
		scene.rows[index]:Hide()
	end
	return y
end

local function BindingText(choices, value)
	for index, option in ipairs(choices.values) do
		if value == option then return choices.labels[index] end
	end
	return value
end

local function RenderReadyCheckControl(scene, width, raid, friendsUI, modern, enabled)
	scene.raidControls = scene.raidControls or {}
	local control = scene.raidControls[modern and "modern" or "legacy"]
	if not control then
		control = CreateFrame("Frame", nil, scene)
		local background = control:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		background:SetColorTexture(0.12, 0.10, 0.08, 0.64)
		control.TopFade = background

		local assist = CreateFrame("CheckButton", nil, control, "UICheckButtonTemplate")
		assist:SetSize(24, 24)
		assist:SetPoint("LEFT", 6, 0)
		assist:Disable()
		MakeInert(assist)
		control.assist = assist
		local crown = control:CreateTexture(nil, "ARTWORK")
		crown:SetPoint("LEFT", assist, "RIGHT", 2, 0)
		crown:SetSize(17, 15)
		if not (modern and BFL.SetTextureOrAtlas(crown, "friends-icon-raidAssist")) then
			crown:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
		end
		control.crown = crown
		local assistLabel = control:CreateFontString(nil, "OVERLAY", "GameFontDisable")
		assistLabel:SetPoint("LEFT", crown, "RIGHT", 2, 0)
		assistLabel:SetText(ALL_ASSIST_LABEL_SHORT or ALL or "")
		control.assistLabel = assistLabel

		local roles = CreateFrame("Frame", nil, control, "RoleCountNoScriptsTemplate")
		roles:SetSize(125, 24)
		raid:ApplyRoleCountDisplay(roles, 1, 1, 3)
		control.roles = roles
		local members = control:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		members:SetPoint("LEFT", roles, "RIGHT", -5, 0)
		members:SetText("5/40")
		control.members = members

		local info = CreateFrame("Button", nil, control, modern and "SharedButtonTemplate" or "UIPanelButtonTemplate")
		info:SetPoint("RIGHT", -5, 0)
		info:SetText(RAID_INFO or L.RAID_INFO or "Raid Info")
		info:SetHeight(modern and 28 or 22)
		MakeInert(info)
		control.info = info
		local ready = CreateFrame("Button", nil, control, "BetterRaidReadyCheckVisualTemplate")
		ready.BFL_SettingsIconButton = true
		ready:SetSize(modern and 28 or 22, modern and 28 or 22)
		ready:SetPoint("RIGHT", info, "LEFT", modern and -4 or -5, 0)
		MakeInert(ready)
		control.ready = ready
		local highlight = control:CreateTexture(nil, "ARTWORK", nil, 4)
		highlight:SetPoint("TOPLEFT", ready, "TOPLEFT", -3, 3)
		highlight:SetPoint("BOTTOMRIGHT", ready, "BOTTOMRIGHT", 3, -3)
		local review = BFL:GetModule("LegacySettingsReview")
		if not (review and review:ApplyModernSettingSelection(highlight, 0.75)) then
			highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			highlight:SetBlendMode("ADD")
			highlight:SetVertexColor(1, 0.82, 0.25, 0.45)
		end
		control.highlight = highlight
		scene.raidControls[modern and "modern" or "legacy"] = control
	end
	for _, other in pairs(scene.raidControls) do other:SetShown(other == control) end
	scene.ready = control.ready

	if modern then
		local palette, themed = friendsUI:GetModernThemeColors()
		friendsUI:ApplyModernContactSurfaceTheme(control, palette, themed)
	end
	local style = BFL:GetModule("LegacySettingsStyle")
	if style then style:SkinActions({ control.info, control.ready }) end
	local size = math.min(width, 415)
	control:SetSize(size, modern and 36 or 32)
	control:SetPoint("TOP")
	local infoText = control.info:GetFontString()
	local infoWidth = math.max(modern and 88 or 90, (infoText and infoText:GetStringWidth() or 0) + 14)
	control.info:SetWidth(math.max(1, math.min(size - 41, infoWidth)))
	local assistWidth = 50 + control.assistLabel:GetStringWidth()
	local rolesAndActionsWidth = 177 + control.info:GetWidth() + 32
	local showAssist = size >= assistWidth + rolesAndActionsWidth
	control.assist:SetShown(showAssist)
	control.crown:SetShown(showAssist)
	control.assistLabel:SetShown(showAssist)
	local showRoles = size >= rolesAndActionsWidth
	control.roles:SetShown(showRoles)
	control.members:SetShown(showRoles)
	control.roles:ClearAllPoints()
	control.roles:SetPoint("LEFT", showAssist and assistWidth or 8, 0)
	local shown, available = raid:ResolveReadyCheckButtonState(enabled, true, true, true, false, false)
	raid:ApplyReadyCheckVisualState(control.ready, shown, available)
	control.highlight:SetShown(shown)
	return control:GetHeight()
end

local function RenderRaid(scene, width, db, _, _, guide)
	local RaidFrame = BFL:GetModule("RaidFrame")
	local friendsUI = BFL:GetModule("FriendsUI")
	local modern = friendsUI and friendsUI:IsModernActive()
	local action = guide and guide.raid
	local active = action and db:Get(guide[1])
	if action == "ready" then
		if scene.group then scene.group:Hide() end
		if scene.binding then scene.binding:Hide() end
		return RenderReadyCheckControl(scene, width, RaidFrame, friendsUI, modern, active)
	end
	for _, control in pairs(scene.raidControls or {}) do control:Hide() end
	scene.renderer = scene.renderer or setmetatable({
		fontCacheVersion = false,
		everyoneIsAssistant = false,
	}, { __index = RaidFrame })
	local renderer = scene.renderer
	renderer.fontCacheVersion = false
	renderer:CacheFontSettings(db)

	if not scene.group then
		scene.group = CreateFrame("Frame", nil, scene, "BetterRaidGroupSurfaceTemplate")
		scene.group:SetPoint("TOP")
		scene.group.rows = {}
	end
	local group = scene.group
	group:Show()
	local effect = action and active ~= false
	local top = 0

	if action and guide.modifiers and effect then
		if not scene.binding then
			scene.binding = scene:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			scene.binding:SetPoint("TOPLEFT", 4, -2)
			scene.binding:SetPoint("TOPRIGHT", -4, -2)
		end
		local mod = guide[1] == "modifier" and active or guide.mod
		local button = guide[1] == "button" and active or guide.button
		local chord = BindingText(guide.buttons, button)
		if mod ~= "NONE" then chord = BindingText(guide.modifiers, mod) .. " + " .. chord end
		scene.binding:SetText(chord)
		scene.binding:Show()
		top = scene.binding:GetStringHeight() + 7
	elseif scene.binding then
		scene.binding:Hide()
	end
	group:ClearAllPoints()
	group:SetPoint("TOP", scene, "TOP", 0, -top)
	group.GroupTitle:SetText(L.RAID_GROUP_NAME:format(1))
	local people = GetPeople()
	people[4] = { name = Samples:CharacterName("SETTINGS_LEGACY_SAMPLE_FOURTH"), class = "PALADIN", role = "HEALER" }
	people[5] = { name = Samples:CharacterName("SETTINGS_LEGACY_SAMPLE_FIFTH"), class = "HUNTER", role = "DAMAGER" }
	local groupWidth = math.min(width, 235)
	local rowHeight = math.max(20, renderer.fontCache.name.size + 4)
	local gap = modern and 1 or 2
	local visible = action and 2 or #people
	local height = 20 + visible * rowHeight + (visible - 1) * gap + (modern and 4 or 0)
	group:SetSize(groupWidth, height)
	for index = 1, visible do
		local person = people[index]
		local row = GetRow(group, index, "BetterRaidMemberVisualTemplate")
		group["Slot" .. index] = row
		renderer:UpdateMemberButton(row, {
			_isMock = true,
			name = person.name,
			classFileName = person.class,
			level = person.level or (BFL.GetMaxLevel and BFL.GetMaxLevel() or 60),
			online = index ~= 5,
			combatRole = person.role,
			rank = index == 1 and effect and (action == "lead" and 2 or (action == "promote" or action == "autoAssist") and 1) or (index == 2 and not (effect and action == "lead") and 2 or 0),
			role = index == 1 and effect and (action == "mainTank" and "MAINTANK" or action == "mainAssist" and "MAINASSIST") or nil,
		}, true)
	end
	renderer:LayoutGroupVisuals(group, groupWidth, rowHeight, 20, gap, modern, true)
	for index = visible + 1, #group.rows do group.rows[index]:Hide() end
	return top + height
end

local tabSampleStates = {
	{ title = "SETTINGS_LEGACY_TABS_IDLE", counts = { friend_requests = 0, quick_join = 0 } },
	{ title = "SETTINGS_LEGACY_TABS_ACTIVE", counts = { friend_requests = 2, quick_join = 1 } },
}

local function CreateTabRail(parent, title)
	local rail = CreateFrame("Frame", nil, parent)
	rail.tabs = {}
	rail.title = rail:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormalSmall")
	rail.title:SetPoint("TOPLEFT", 4, -3)
	rail.title:SetPoint("TOPRIGHT", -4, -3)
	rail.title:SetJustifyH("LEFT")
	rail.title:SetText(title)
	rail.empty = rail:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontDisableSmall")
	rail.empty:SetPoint("TOPLEFT", 4, -29)
	rail.empty:SetText(NONE)
	return rail
end

local function RenderTabRail(rail, FriendsUI, order, counts, rowHeight, columns)
	for _, tab in pairs(rail.tabs) do
		tab:Hide()
		tab.label:Hide()
	end
	rail.empty:SetShown(#order == 0)

	local rows = math.max(1, math.ceil(#order / columns))
	local columnWidth = rail:GetWidth() / columns
	local elvui = BFL:GetModule("ElvUISkin")
	local skinTabs = elvui and elvui:IsSkinEnabled()
	for index, sectionID in ipairs(order) do
		local tab = rail.tabs[sectionID]
		if not tab then
			local slot = CreateFrame("Frame", nil, rail)
			tab = CreateFrame("Button", nil, slot, "BFLModernSideTabTemplate")
			tab.slot = slot
			tab:SetPoint("RIGHT")
			MakeInert(tab)
			tab.label = rail:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
			tab.label:SetPoint("RIGHT", tab, "LEFT", -6, 0)
			tab.label:SetJustifyH("LEFT")
			tab.label:SetMaxLines(2)
			rail.tabs[sectionID] = tab
		end
		tab.label:SetText(rail.labels[sectionID])
		local column = math.floor((index - 1) / rows)
		local row = (index - 1) % rows
		tab.slot:SetPoint("TOPRIGHT", -6 - (columns - 1 - column) * columnWidth, -24 - row * rowHeight)
		tab.slot:SetSize(1, rowHeight)
		FriendsUI:RenderSettingsNavigationTab(tab, sectionID, counts[sectionID] or 0, index == 1)
		if skinTabs then elvui:SkinModernSideTab(tab) end
		tab:SetScale(rowHeight / (tab:GetHeight() + 3))
		tab:Show()
		tab.label:Show()
		tab.label:SetWidth(math.max(1, columnWidth - tab:GetWidth() * tab:GetScale() - 16))
	end
end

local function RenderTabs(scene, width, db, maxHeight, _, variant)
	local FriendsUI = BFL:GetModule("FriendsUI")
	if not scene.rails then
		scene.rails = {}
		for index, state in ipairs(tabSampleStates) do
			scene.rails[index] = CreateTabRail(scene, L[state.title])
		end
	end

	local capabilities = FriendsUI:GetCapabilities()
	local labels = {}
	for _, entry in ipairs(FriendsUI:GetFriendTabSettingsEntries()) do
		labels[entry.id] = entry.label
	end
	local renderer = FriendsUI
	if variant and variant.order then
		renderer = setmetatable({
			GetFriendTabOrder = function() return db:Get(variant[1]) end,
		}, { __index = FriendsUI })
	elseif variant then
		renderer = setmetatable({}, { __index = FriendsUI })
		local id, key = variant.tab, variant[1]
		local value = db:Get(key)
		function renderer:IsFriendTabVisible(sectionID)
			if sectionID == id then return key ~= "conditional" and value == true or key == "conditional" end
			return FriendsUI:IsFriendTabVisible(sectionID)
		end
		function renderer:IsFriendTabPopulatedOnly(sectionID)
			if sectionID == id and key == "conditional" then return value == true end
			return FriendsUI:IsFriendTabPopulatedOnly(sectionID)
		end
	end
	local columns = maxHeight < 235 and width >= 460 and 2 or 1
	local orders, maxRows = {}, 1
	for index, state in ipairs(tabSampleStates) do
		if variant and variant.tab then
			orders[index] = renderer:ShouldShowSection(variant.tab, capabilities, state.counts) and { variant.tab } or {}
		else
			orders[index] = renderer:BuildAvailableSectionIDs(capabilities, state.counts)
		end
		maxRows = math.max(maxRows, math.ceil(#orders[index] / columns))
	end
	local rowHeight = math.min(58, math.max(10, (maxHeight - 24) / maxRows))
	local height = 24 + maxRows * rowHeight
	local railWidth = (width - 8) / 2
	for index, rail in ipairs(scene.rails) do
		rail.labels = labels
		rail:SetPoint("TOPLEFT", (index - 1) * (railWidth + 8), 0)
		rail:SetSize(railWidth, height)
		RenderTabRail(rail, FriendsUI, orders[index], tabSampleStates[index].counts, rowHeight, columns)
	end
	return height
end

local renderers = {
	who = RenderWho,
	guild = RenderGuild,
	raidFonts = RenderRaid,
	raidActions = RenderRaid,
	friendTabs = RenderTabs,
}

function Samples:Show(kind, parent, width, db, maxHeight, compact, top, variant)
	local render = renderers[kind]
	if not render then
		return nil
	end

	parent.socialSamples = parent.socialSamples or {}
	local scene = parent.socialSamples[kind]
	if not scene then
		scene = CreateFrame("Frame", nil, parent)
		scene.rows = {}
		parent.socialSamples[kind] = scene
	end
	scene:ClearAllPoints()
	scene:SetPoint("TOPLEFT", top and 0 or 8, -(top or 35))
	scene:SetWidth(width)
	scene:SetHeight(math.max(1, render(scene, width, db, maxHeight, compact, variant)))
	scene:Show()
	return (top or 35) + scene:GetHeight() + 7
end

function Samples:Hide(parent)
	if parent.legacyTabFonts then parent.legacyTabFonts:Hide() end
	for _, scene in pairs(parent.socialSamples or {}) do
		if scene.viewport then scene.viewport:SetVerticalScroll(0) end
		scene:Hide()
	end
end
