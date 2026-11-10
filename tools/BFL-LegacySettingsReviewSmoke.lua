
-- Verify stable task routes and search keys against the real locale files.
local root = (arg[1] or "."):gsub("[/\\]$", "")
local BFL = {}
function GetLocale() return "enUS" end
function wipe(target)
	for key in pairs(target) do
		target[key] = nil
	end
	return target
end
local function Load(path)
	return assert(loadfile(root .. "/" .. path))("BetterFriendlist", BFL)
end

local function Read(path)
	local file = assert(io.open(root .. "/" .. path, "rb"))
	local text = file:read("*a")
	file:close()
	return text
end

for _, layout in ipairs({ "BetterFriendlist.xml", "BetterFriendlist_Classic.xml" }) do
	local xml = Read(layout)
	for _, module in ipairs({ "LegacySettingsReview", "LegacySettingsSocialSamples", "Changelog" }) do
		for font in Read("Modules/" .. module .. ".lua"):gmatch('"(BetterFriendlist[%w_]*Font[%w_]*)"') do
			assert(xml:find('<Font name="' .. font .. '"', 1, true), layout .. ": missing " .. font .. " used by " .. module)
		end
	end
end

Load("Locales/Locales.lua")
local locales = { "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }
for _, locale in ipairs(locales) do
	Load("Locales/" .. locale .. ".lua")
end
Load("Data/LegacySettingsCatalog.lua")
local catalog = BFL.LegacySettingsCatalog
local pages, keys, hits = {}, {}, {}
for _, category in ipairs(catalog.categories) do
	keys[category[2]] = true
	for index = 3, #category do
		local route = category[index]
		assert(not pages[route], "Duplicate navigation route " .. route)
		local page = assert(catalog.pages[route], "Missing page for " .. route)
		assert(catalog.tabs[page[1]], "Missing native tab for " .. route)
		keys[page[2]] = true
		pages[route] = true
	end
end
for route in pairs(catalog.pages) do
	assert(pages[route], "Unreachable route " .. route)
end
for number, tab in ipairs(catalog.tabs) do
	local route = assert(catalog.tabRoutes[number], "Missing old route for " .. tab)
	assert(catalog.pages[route][1] == number, "Old route opens the wrong native tab " .. tab)
end
local settings = assert(io.open(root .. "/Modules/Settings.lua", "rb"))
local source = settings:read("*a")
settings:close()
for anchor in source:gmatch('RegisterLegacySection%(self, "([^"]+)"') do
	assert(pages[catalog.links[anchor]], "Unmapped legacy anchor " .. anchor)
end
for route, sections in pairs(catalog.search) do
	assert(pages[route], "Search has an unreachable route " .. route)
	for section, labels in pairs(sections) do
		for _, key in ipairs(labels) do
			local id = route .. "/" .. section .. "/" .. key
			assert(not hits[id], "Duplicate search ID " .. id)
			hits[id] = true
			keys[key] = true
		end
	end
end
for key, alias in pairs(catalog.aliases) do
	assert(keys[key], "Alias without a search destination " .. key)
	keys[alias] = true
end
for _, key in pairs(catalog.guides) do keys[key] = true end
for key in source:gmatch('"(SETTINGS_COMPARE_[A-Z_]+)"') do keys[key] = true end
keys.SETTINGS_COMPARE_CURRENT, keys.SETTINGS_COMPARE_ALTERNATE = true, true
keys.SETTINGS_COMPARE_SAMPLE_NOTE = true
for route, comparisons in pairs(catalog.comparisons) do
	assert(pages[route], "Comparison has an unreachable route " .. route)
	for key, descriptor in pairs(comparisons) do
		assert(keys[key], "Comparison without a catalog key " .. route .. "/" .. key)
		if not descriptor[1] then
			assert(catalog.search[route][key], "Comparison without a catalog section " .. route .. "/" .. key)
			for settingKey, item in pairs(descriptor) do
				assert(keys[settingKey] and type(item[1]) == "string", route .. "/" .. key .. "/" .. settingKey)
			end
		end
	end
end
for _, locale in ipairs(locales) do
	BFL:SetLocale(locale)
	for key in pairs(keys) do
		local value = BFL.L[key]
		assert(type(value) == "string" and value ~= "" and value ~= key, locale .. ": " .. key)
	end
end

local review
function BFL:RegisterModule(_, module)
	review = module
	return module
end
function BFL:GetEffectiveTheme() return "custom" end
Load("Modules/LegacySettingsReview.lua")
local function NoOp() end
local function CheckComparison(route, section, key, expected, helpOnly)
	local comparison = { "setting", helpOnly = helpOnly }
	local row = {
		IsObjectType = function(_, kind) return kind == "Frame" end,
		BFL_SearchLabels = { "Setting" },
		BFL_SettingDescriptions = { "Setting help" },
		BFL_Comparison = { comparison },
	}
	review.route = route
	review:BindSettingHelp(row, { setting = key }, section)
	local entry = assert(row.BFL_SettingGuide and row.BFL_SettingGuide[1], "Missing row help for " .. key)
	assert(entry[2] ~= "" and entry[4] == comparison, "Lost help or main preview target for " .. key)
	assert(entry.showComparison == expected, "Unexpected individual preview policy for " .. route .. "/" .. key)
	if not expected then
		review.guideEntry, review.guideRow = entry, row
		assert(review:GetComparison() == nil, "Help-only settings must not render a comparison")
		review.guideEntry, review.guideRow = nil, nil
	end
end

BFL:SetLocale("enUS")
local comparisonCases = {
	{ "friendTabs", "SETTINGS_FRIEND_TABS_ORDER", "FRIENDS_UI_SECTION_FRIENDS" },
	{ "automatic", "SETTINGS_BEHAVIOR_HEADER", "SETTINGS_ACCORDION_GROUPS" },
	{ "automatic", "SETTINGS_GROUP_MANAGEMENT", "GROUP_FAVORITES" },
	{ "automatic", "SETTINGS_GROUP_MANAGEMENT", "SETTINGS_RECENTLY_ADDED_DURATION_VALUE" },
	{ "headers", "SETTINGS_GROUP_ORDER", "SETTINGS_GROUP_ORDER" },
	{ "headers", "SETTINGS_GROUP_ORDER", "SETTINGS_GROUP_COLOR" },
	{ "headers", "SETTINGS_GROUP_ORDER", "SETTINGS_GROUP_COUNT_COLOR" },
	{ "headers", "SETTINGS_GROUP_ORDER", "SETTINGS_GROUP_ARROW_COLOR" },
	{ "tags", "FRIEND_TAGS_SETTINGS_SEARCH", "FRIEND_TAGS_SEARCH_BLIZZARD" },
	{ "tags", "FRIEND_TAGS_SETTINGS_GROUPS", "FRIEND_TAGS_SETTINGS_DYNAMIC_GROUPS" },
	{ "layout", "SETTINGS_FRIENDS_UI_STYLE_HEADER", "SETTINGS_FRIENDS_UI_STYLE" },
	{ "layout", "SETTINGS_FRIENDS_UI_STYLE_HEADER", "SETTINGS_SMOOTH_SCROLLING" },
	{ "layout", "SETTINGS_BEHAVIOR_HEADER", "SETTINGS_USE_UI_PANEL_SYSTEM" },
	{ "layout", "SETTINGS_BEHAVIOR_HEADER", "SETTINGS_SIMPLE_MODE" },
	{ "layout", "SETTINGS_BEHAVIOR_HEADER", "SETTINGS_SIMPLE_MODE_SHOW_SEARCH" },
	{ "layout", "SETTINGS_FRAME_DIMENSIONS_HEADER", "SETTINGS_FRAME_WIDTH" },
	{ "layout", "SETTINGS_FRAME_DIMENSIONS_HEADER", "SETTINGS_LOCK_WINDOW" },
	{ "theme", "SETTINGS_THEME_HEADER", "SETTINGS_THEME_DROPDOWN" },
	{ "guild", "SETTINGS_GUILD_ROSTER_HEADER", "SETTINGS_GUILD_DEFAULT_FILTER" },
	{ "raid", "SETTINGS_RAID_SHORTCUTS_TITLE", "SETTINGS_RAID_SHORTCUTS_TITLE" },
	{ "contacts", "CONTACT_MEMORY_TITLE", "CONTACT_MEMORY_SETTINGS_ENABLE" },
	{ "backups", "SETTINGS_SYNC_GROUPS_NOTE_HEADER", "SETTINGS_SYNC_GROUPS_NOTE" },
	{ "backups", "SETTINGS_EXTERNAL_MENU_BRIDGE", "SETTINGS_EXTERNAL_MENU_BRIDGE" },
	{ "broker", "BROKER_SETTINGS_HEADER", "BROKER_SETTINGS_CLICK_ACTION" },
	{ "guildBroker", "GUILD_BROKER_SETTINGS_HEADER", "GUILD_BROKER_SETTINGS_CLICK_ACTION" },
	{ "headers", "SETTINGS_GROUP_FONT_HEADER", "SETTINGS_FONT_SIZE_NUM", true },
	{ "tags", "FRIEND_TAGS_SETTINGS_VISIBILITY", "FRIEND_TAGS_SHOW_ROW_CHIPS", true },
	{ "raid", "SETTINGS_TAB_RAID", "SETTINGS_RAID_ENABLE_READY_CHECK_BUTTON", true },
	{ "raid", "AUTO_RAID_ASSIST_TITLE", "AUTO_RAID_ASSIST_ENABLE", true },
	{ "knownCharacters", "KC_TITLE", "KC_ENABLE", true },
	{ "broker", "BROKER_SETTINGS_HEADER", "BROKER_SETTINGS_TOOLTIP_MODE", true },
	{ "guildBroker", "GUILD_BROKER_SETTINGS_HEADER", "GUILD_BROKER_SETTINGS_SHOW_APPLICANTS", true },
}
for _, case in ipairs(comparisonCases) do
	CheckComparison(case[1], case[2], case[3], case[4] == true)
end
for _, key in ipairs({ "FILTER_BUILDER_FILTERS", "FILTER_BUILDER_NAME", "FILTER_BUILDER_ICON", "FILTER_BUILDER_GROUP", "FILTER_BUILDER_TEMPLATE" }) do
	CheckComparison("filters", "SETTINGS_TAB_FILTER_SORT", key, false, true)
	CheckComparison("filters", "SETTINGS_TAB_FILTER_SORT", key, true)
end

review.ClearPage, review.UpdateNavigation, review.ShowPageFrame = NoOp, NoOp, NoOp
review.Layout, review.ResetScroll = NoOp, NoOp
review.message = { SetText = NoOp }
review.settings = { GetLegacyTabAvailability = function() return true end }
local storedSearch
local searchDB = {
	Get = function() return storedSearch end,
	Set = function(_, _, history) storedSearch = history end,
}
function BFL:GetModule(name)
	if name == "DB" then return searchDB end
end
function review:ListButton(index, _, action)
	self.results[index] = { IsShown = function() return true end, Click = action }
	return self.results[index]
end

local function Search(query)
	review.results = {}
	review.listButtons = review.results
	review:ShowResults(query)
	return review.results
end

local function FindResult(query, key)
	for _, button in ipairs(Search(query)) do
		if button.settingHit.key == key then return button.settingHit end
	end
end

for _, locale in ipairs(locales) do
	BFL:SetLocale(locale)
	local L = BFL.L
	local format = FindResult(L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL, "SETTINGS_INFO_FORMAT_TOOLTIP")
	assert(format and format.section == "SETTINGS_INFO_FORMAT_HEADER", locale .. ": old info label")
	local known = FindResult(L.KC_AUTO, "KC_AUTO")
	assert(known and known.route == "knownCharacters" and known.section == "KC_TITLE", locale .. ": known characters")
	local theme = FindResult(L.SETTINGS_THEME_WINDOW_OPACITY, "SETTINGS_THEME_WINDOW_OPACITY")
	assert(theme and theme.section == "SETTINGS_THEME_CUSTOM_HEADER", locale .. ": active theme must rank first")
end

BFL:SetLocale("enUS")
local tagHits = Search("Tag")
assert(tagHits[1].settingHit.id == "tags", "Friend Tags page should lead results for Tag")
for index = 2, #tagHits do
	assert(tagHits[index].settingHit.label ~= tagHits[1].settingHit.label, "page and opening heading are one result")
end
local opened
function review:Navigate(_, hit) opened = hit end
local nameColorID = "rowFonts/SETTINGS_FRIEND_NAME_SETTINGS/SETTINGS_FONT_COLOR"
local focused = true
local editBox = { ClearFocus = function() focused = false end }
local fontHits = Search("Font")
assert(#fontHits > 1 and not storedSearch, "typing alone does not populate history")
review:SubmitSearch(editBox)
assert(not focused and not opened and not storedSearch, "Enter with several hits just blurs the search")
for _ = 1, 10 do
	for _, button in ipairs(Search(" Font ")) do
		if button.settingHit.id == nameColorID then button:Click(); break end
	end
end
assert(opened and opened.id == nameColorID and #storedSearch == 1 and storedSearch[1].uses == 10)
assert(Search("FONT")[1].settingHit.id == nameColorID, "repeated choices move the exact setting up")
assert(Search("Tag")[1].settingHit.id == "tags", "history is scoped to the search term")

local single = Search("Friend Tags")[1]
review.listButtons = { single }
focused = true
review:SubmitSearch(editBox)
assert(not focused and opened.id == "tags" and storedSearch[1].query == "friend tags", "Enter opens and records a sole result")
opened, focused = nil, true
assert(#Search("there is no setting with this phrase") == 0)
review:SubmitSearch(editBox)
assert(not focused and not opened and #storedSearch == 2, "Enter with no hits just blurs the search")

local function SampleFrame(...)
	local children = { ... }
	return {
		mouseEnabled = true,
		IsShown = function() return true end,
		IsVisible = function() return true end,
		EnableMouse = function(frame, enabled) frame.mouseEnabled = enabled end,
		GetChildren = function() return table.unpack(children) end,
	}
end

local render
C_Timer = {
	NewTimer = function(_, callback)
		render = callback
		return {}
	end,
}
local dropdownArrow, friendAction, whoColumn = SampleFrame(), SampleFrame(), SampleFrame()
review.sampleNext = SampleFrame()
review.sampleRows = SampleFrame(SampleFrame(friendAction))
review.sampleViewport = SampleFrame(review.sampleRows)
review.sampleViewport.ScrollBar = SampleFrame()
review.headerSample = SampleFrame(SampleFrame(dropdownArrow), review.sampleViewport, review.sampleViewport.ScrollBar)
review.preview = SampleFrame(review.headerSample, review.sampleNext)
review.preview.legacyTabFonts = SampleFrame(SampleFrame())
review.preview.socialSamples = { friends = SampleFrame(whoColumn) }
review.active, review.sample = true, "friends"
review.RenderSample, review.LayoutSettingHelp, review.RefreshHeight = NoOp, NoOp, NoOp
function BFL:GetModule(name)
	if name == "LegacySettingsStyle" then
		return {
			SkinPreview = function()
				-- The skin can add mouse handlers after the native sample is built.
				dropdownArrow:EnableMouse(true)
				friendAction:EnableMouse(true)
				whoColumn:EnableMouse(true)
			end,
		}
	end
end
for _ = 1, 2 do
	review:QueueSample()
	render()
	assert(not dropdownArrow.mouseEnabled and not friendAction.mouseEnabled and not whoColumn.mouseEnabled,
		"Decorative examples must ignore clicks after skinning")
	assert(review.sampleNext.mouseEnabled and review.sampleViewport.mouseEnabled
		and review.sampleViewport.ScrollBar.mouseEnabled, "The sample picker and scrolling must stay interactive")
end

local count = 0
for _ in pairs(hits) do
	count = count + 1
end
io.write(("PASS: %d settings search targets, %d native tab routes, %d locales\n"):format(count, #catalog.tabs, #locales))
