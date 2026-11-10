
local _, BFL = ...
local Catalog = {}
BFL.LegacySettingsCatalog = Catalog

local helpOnlyPages = {
	friendTabs = true,
	automatic = true,
	theme = true,
	guild = true,
	contacts = true,
}

local helpOnlySections = {
	SETTINGS_GROUP_ORDER = true,
	FRIEND_TAGS_SETTINGS_SEARCH = true,
	FRIEND_TAGS_SETTINGS_GROUPS = true,
	SETTINGS_FRAME_DIMENSIONS_HEADER = true,
	SETTINGS_RAID_SHORTCUTS_TITLE = true,
}

local helpOnlySettings = {
	SETTINGS_FRIENDS_UI_STYLE = true,
	SETTINGS_SMOOTH_SCROLLING = true,
	SETTINGS_USE_UI_PANEL_SYSTEM = true,
	SETTINGS_SIMPLE_MODE = true,
	SETTINGS_SIMPLE_MODE_SHOW_SEARCH = true,
	SETTINGS_SYNC_GROUPS_NOTE = true,
	SETTINGS_EXTERNAL_MENU_BRIDGE = true,
	BROKER_SETTINGS_CLICK_ACTION = true,
	GUILD_BROKER_SETTINGS_CLICK_ACTION = true,
}

function Catalog.ShowIndividualPreview(route, section, key, comparison)
	return comparison ~= nil and not (
		helpOnlyPages[route] or helpOnlySections[section] or helpOnlySettings[key]
		or comparison.helpOnly
	)
end

-- The values are SavedVariables keys. A region points at a native sample widget field.
Catalog.comparisons = {
	rows = {
		SETTINGS_COLOR_CLASS_NAMES = { "colorClassNames", "Name", sampleOverrides = {
			nameFormatPreset = "character", fontColorFriendName = { r = 0.95, g = 0.95, b = 0.95, a = 1 },
			grayOtherFaction = false,
		} },
		SETTINGS_SHOW_FACTION_ICONS = { "showFactionIcons", "Name", friend = 2, prerequisite = { "nameFormatPreset", "character" } },
		SETTINGS_SHOW_FACTION_BG = { "showFactionBg", friend = 2 },
		SETTINGS_GRAY_OTHER_FACTION = { "grayOtherFaction", "Name", friend = 2 },
		SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = { "showMultiAccountBadge", "gameAccountBadge", prerequisite = { "showGameIcon", true } },
		SETTINGS_SHOW_MULTI_ACCOUNT_INFO = { "showMultiAccountInfo", "multiAccountRow", sampleOverrides = { compactMode = false, infoFormatPreset = "default" } },
		SETTINGS_SHOW_RULESET_NAME = { "showRealmName", "Info", prerequisite = { "infoFormatPreset", "default" } },
		SETTINGS_SHOW_REALM_NAME = { "showRealmName", "Name", friend = 2, prerequisite = { "nameFormatPreset", "character" } },
		SETTINGS_HIDE_MAX_LEVEL = { "hideMaxLevel", "Info", friend = 2, prerequisite = { "infoFormatPreset", "default" } },
		SETTINGS_SHOW_MOBILE_AS_AFK = { "showMobileAsAFK", "status", friend = 3, prerequisite = { "treatMobileAsOffline", false } },
		SETTINGS_TREAT_MOBILE_OFFLINE = { "treatMobileAsOffline", "status", friend = 3, prerequisite = { "showMobileAsAFK", false } },
		SETTINGS_SHOW_GAME_ICON = { "showGameIcon", "gameIcon" },
		SETTINGS_COLOR_LEVEL_BY_DIFFICULTY = { "colorLevelByDifficulty", "Info", prerequisite = { "infoFormatPreset", "default" } },
		SETTINGS_ENABLE_FAVORITE_ICON = { "enableFavoriteIcon", "favoriteIcon" },
		SETTINGS_FAVORITE_ICON_STYLE = { "favoriteIconStyle", "favoriteIcon", prerequisite = { "enableFavoriteIcon", true } },
		SETTINGS_NAME_FORMAT_HEADER = { "nameFormatPreset", "Name" },
		SETTINGS_NAME_FORMAT_TOOLTIP = { "nameFormatCustom", "Name", prerequisite = { "nameFormatPreset", "custom" }, examples = { "%nickname% (%character%)", "%character% · %realm%" } },
		SETTINGS_INFO_FORMAT_HEADER = { "infoFormatPreset", "Info" },
		SETTINGS_INFO_FORMAT_TOOLTIP = { "infoFormatCustom", "Info", prerequisite = { "infoFormatPreset", "custom" }, examples = { "%level%, %zone%", "%class%, %realm%" } },
		SETTINGS_COMPACT_MODE = { "compactMode", sampleOverrides = {
			nameFormatPreset = "character", infoFormatPreset = "zone", showRealmName = false,
			showFactionIcons = false, enableFavoriteIcon = false, showMultiAccountBadge = false, showMultiAccountInfo = false,
		} },
	},
	behavior = {
		SETTINGS_SHOW_BLIZZARD = { "showBlizzardOption", outcome = "blizzardMenu" },
		SETTINGS_FRIENDLIST_CLICK_WHISPER = { "friendListClickWhisperEnabled", outcome = "whisper" },
		SETTINGS_FRIENDLIST_CLICK_WHISPER_MODE = { "friendListClickWhisperMode", outcome = "whisper",
			prerequisite = { "friendListClickWhisperEnabled", true } },
	},
	rowFonts = {
		SETTINGS_FRIEND_NAME_SETTINGS = {
			SETTINGS_FONT = { "fontFriendName", "Name" },
			SETTINGS_FONT_SIZE_NUM = { "fontSizeFriendName", "Name" },
			SETTINGS_FONT_FLAGS = { "fontOutlineFriendName", "Name" },
			SETTINGS_FONT_COLOR = { "fontColorFriendName", "Name", sampleOverrides = { colorClassNames = false, nameFormatPreset = "character" } },
		},
		SETTINGS_FRIEND_INFO_SETTINGS = {
			SETTINGS_FONT = { "fontFriendInfo", "Info", prerequisite = { "infoFormatPreset", "default" } },
			SETTINGS_FONT_SIZE_NUM = { "fontSizeFriendInfo", "Info", prerequisite = { "infoFormatPreset", "default" } },
			SETTINGS_FONT_FLAGS = { "fontOutlineFriendInfo", "Info", prerequisite = { "infoFormatPreset", "default" } },
			SETTINGS_FONT_COLOR = { "fontColorFriendInfo", "Info", prerequisite = { "infoFormatPreset", "default" } },
		},
	},
	automatic = {
		GROUP_FAVORITES = { "showFavoritesGroup", group = "favorites" },
		GROUP_INGAME = { "enableInGameGroup", group = "ingame" },
		GROUP_RECENTLY_ADDED = { "enableRecentlyAddedGroup", group = "recentlyadded" },
		SETTINGS_INGAME_MODE_LABEL = { "inGameGroupMode", group = "ingame", prerequisite = { "enableInGameGroup", true } },
		SETTINGS_RECENTLY_ADDED_DURATION_UNIT = { "recentlyAddedDurationUnit", group = "recentlyadded", prerequisite = { "enableRecentlyAddedGroup", true } },
		SETTINGS_RECENTLY_ADDED_DURATION_VALUE = { "recentlyAddedDurationValue", group = "recentlyadded", prerequisite = { "enableRecentlyAddedGroup", true }, examples = { 7, 9 } },
		SETTINGS_HIDE_EMPTY_GROUPS = { "hideEmptyGroups", group = "recentlyadded", prerequisite = { "enableRecentlyAddedGroup", true } },
		SETTINGS_ACCORDION_GROUPS = { "accordionGroups", group = true, prerequisite = { "showFavoritesGroup", true } },
		SORT_PRIMARY_LABEL = { "primarySort", group = true },
		SORT_SECONDARY_LABEL = { "secondarySort", group = true },
		SETTINGS_QUICK_FILTER = { "quickFilter", group = true },
	},
	headers = {
		SETTINGS_HEADER_COUNT_FORMAT = { "headerCountFormat", group = "bfl_settings_group" },
		SETTINGS_GROUP_HEADER_ALIGN = { "groupHeaderAlign", group = "bfl_settings_group" },
		SETTINGS_GROUP_ARROW_ALIGN = { "groupArrowAlign", group = "bfl_settings_group" },
		SETTINGS_SHOW_GROUP_ARROW = { "showGroupArrow", group = "bfl_settings_group" },
		SETTINGS_GROUP_FONT_HEADER = {
			SETTINGS_FONT = { "fontGroupHeader", group = "bfl_settings_group" },
			SETTINGS_FONT_SIZE_NUM = { "fontSizeGroupHeader", group = "bfl_settings_group" },
			SETTINGS_FONT_FLAGS = { "fontOutlineGroupHeader", group = "bfl_settings_group" },
		},
	},
	stream = {
		SETTINGS_ENABLE_STREAMER_MODE = { "showStreamerModeButton", header = "streamer", region = "streamer" },
		SETTINGS_LEGACY_TASK_STREAM = { "streamerModeActive", header = "streamer", region = "tag" },
		STREAMER_MODE_HEADER_TEXT = { "streamerModeHeaderText", header = "streamer", region = "tag", examples = { "@Aster" } },
		SETTINGS_STREAMER_NAME_FORMAT = { "streamerModeNameFormat", "Name", streamer = true },
	},
	layout = {
		SETTINGS_FRIENDS_UI_STYLE = { "friendsFrameStyle", header = "layout", region = "search" },
		SETTINGS_ENABLE_ELVUI_SKIN = { "enableElvUISkin", theme = true, themeToggle = true },
		SETTINGS_FRAME_WIDTH = { "width", geometry = true, examples = { 410, 650 }, inputRange = { 380, 800 } },
		SETTINGS_FRAME_HEIGHT = { "height", geometry = true, examples = { 675, 950 }, inputRange = { 400, 1200 } },
		SETTINGS_FRAME_SCALE = { "windowScale", geometry = true, examples = { 1, 1.5 }, inputRange = { 0.5, 2, true } },
		SETTINGS_LOCK_WINDOW = { "lockWindow", geometry = true },
		SETTINGS_USE_UI_PANEL_SYSTEM = { "useUIPanelSystem", geometry = true, binary = true },
		SETTINGS_SMOOTH_SCROLLING = { "enableSmoothScrolling", geometry = true },
		SETTINGS_SIMPLE_MODE = { "simpleMode", header = "layout", region = "legacyPortrait" },
		SETTINGS_SIMPLE_MODE_SHOW_SEARCH = { "simpleModeShowSearch", header = "layout", region = "search", prerequisite = { "simpleMode", true } },
	},
	raid = {
		SETTINGS_RAID_ENABLE_READY_CHECK_BUTTON = { "enableReadyCheckButton", social = "raidActions", raid = "ready" },
		AUTO_RAID_ASSIST_ENABLE = { "enabled", social = "raidActions", raid = "autoAssist" },
	},
	contacts = {
		CONTACT_MEMORY_SETTINGS_ENABLE = { "enabled", privacy = "notes" },
		CONTACT_MEMORY_SETTINGS_TOOLTIPS = { "showTooltipSection", privacy = "notes" },
		CONTACT_MEMORY_SETTINGS_HIDE_STREAMER = { "hideInStreamerMode", privacy = "notes" },
	},
	knownCharacters = {
		KC_ENABLE = { "enabled", privacy = "characters" },
		KC_AUTO = { "observeBattleNet", privacy = "characters" },
		KC_LIMIT = { "maxTooltipCharacters", privacy = "characters" },
	},
	tags = {
		FRIEND_TAGS_ENABLE = { "enabled", "friendTagRow", friend = 2, tags = true },
		FRIEND_TAGS_SHOW_TOOLTIP_CHIPS = { "showTooltipChips", tags = true, outcome = "tooltip", binary = true },
		FRIEND_TAGS_SHOW_BROKER_CHIPS = { "showBrokerChips", tags = true, outcome = "broker", binary = true },
		FRIEND_TAGS_MAX_TOOLTIP_CHIPS = { "maxTooltipChips", tags = true, outcome = "tooltip" },
		FRIEND_TAGS_SEARCH_BLIZZARD = { "includeBlizzardTagsInSearch", tags = true, outcome = "search", binary = true },
		FRIEND_TAGS_SEARCH_CUSTOM = { "includeCustomTagsInSearch", tags = true, outcome = "search", binary = true },
		FRIEND_TAGS_SHOW_MENU_COUNTS = { "showMenuTagCounts", tags = true, outcome = "menu", binary = true },
		FRIEND_TAGS_SETTINGS_DYNAMIC_GROUPS = { "enableDynamicTagGroups", tags = true, tagGroups = true, binary = true },
		FRIEND_TAGS_HIDE_DYNAMIC_GROUP_TAG = { "hideDynamicGroupTagChip", tags = true, tagGroups = true, binary = true, friend = 2 },
		FRIEND_TAGS_HIDE_ALL_DYNAMIC_GROUP_TAGS = { "hideAllDynamicGroupTagChips", tags = true, tagGroups = true, binary = true, friend = 2 },
		FRIEND_TAGS_PRIORITIZE_DYNAMIC_GROUPS = { "prioritizeDynamicTagGroups", tags = true, tagGroups = true, binary = true },
		FRIEND_TAGS_DYNAMIC_GROUP_HEADER_STYLE = { "dynamicTagGroupHeaderStyle", tags = true, tagGroups = true },
		FRIEND_TAGS_SHOW_ROW_CHIPS = { "showRowChips", "friendTagRow", friend = 2, tags = true, binary = true },
		FRIEND_TAGS_STREAMER_MODE = { "showTagsInStreamerMode", "friendTagRow", friend = 2, tags = true, binary = true, streamer = true },
		FRIEND_TAGS_FULL_WIDTH_ROWS = { "fullWidthTagRows", "friendTagRow", friend = 2, tags = true, binary = true },
		FRIEND_TAGS_SETTINGS_COMPACT_MODE = { "compactRowMode", "friendTagRow", friend = 2, tags = true, prerequisite = { "compactMode", true } },
		FRIEND_TAGS_MAX_ROW_CHIPS = { "maxRowChips", "friendTagRow", friend = 2, tags = true },
		FRIEND_TAGS_CHIPS_PER_LINE = { "chipsPerLine", "friendTagRow", friend = 2, tags = true },
		FRIEND_TAGS_CHIP_ICON_SIZE = { "chipIconSize", "friendTagRow", friend = 2, tags = true },
		FRIEND_TAGS_CHIP_FONT_SIZE = { "chipFontSize", "friendTagRow", friend = 2, tags = true },
		SETTINGS_FONT = { "chipFont", "friendTagRow", friend = 2, tags = true },
		SETTINGS_FONT_FLAGS = { "chipFontFlags", "friendTagRow", friend = 2, tags = true },
	},
	sync = {
		SETTINGS_GLOBAL_SYNC_ENABLE = { "enableGlobalSync", outcome = "globalSync" },
		SETTINGS_GLOBAL_SYNC_DELETION = { "enableGlobalSyncDeletion", outcome = "globalSync" },
		SETTINGS_GLOBAL_SYNC_SHOW_DELETED = { "showDeletedFriends", outcome = "globalSync" },
	},
	backups = {
		SETTINGS_SYNC_GROUPS_NOTE = { "syncGroupsToNote", outcome = "groupNotes" },
		SETTINGS_EXTERNAL_MENU_BRIDGE = { "externalMenuBridgeEnabled", outcome = "menuBridge" },
	},
	help = {
		SETTINGS_SHOW_WELCOME_MESSAGE = { "showWelcomeMessage", outcome = "welcome" },
		SETTINGS_DEBUG_PRINT = { "debugPrintEnabled", outcome = "debug" },
		SETTINGS_BETA_FEATURES_ENABLE = { "enableBetaFeatures", outcome = "beta" },
		SETTINGS_ENABLE_SETTINGS_CENTER = { "enableSettingsCenterBeta", outcome = "settingsEntry" },
	},
	broker = {
		BROKER_SETTINGS_ENABLE = { "brokerEnabled", brokerLine = true },
		BROKER_SETTINGS_CLICK_ACTION = { "brokerClickAction", outcome = "brokerClick" },
		BROKER_SETTINGS_TOOLTIP_MODE = { "brokerTooltipMode", brokerTooltip = true },
		BROKER_SETTINGS_FONT_NON_LATIN = { "brokerUseCustomFontForNonLatin", brokerTooltip = true },
		BROKER_SETTINGS_FONT = { "brokerFont", brokerTooltip = true },
		BROKER_SETTINGS_FONT_SIZE = { "brokerFontSize", brokerTooltip = true },
		SETTINGS_FONT_FLAGS = { "brokerFontFlags", brokerTooltip = true },
		BROKER_SETTINGS_SEPARATOR_COLOR = { "brokerSeparatorColor", brokerTooltip = true },
		BROKER_SETTINGS_SHOW_HINTS = { "brokerShowHints", brokerTooltip = true },
		BROKER_SETTINGS_SHOW_CLASS_ICONS = { "brokerShowClassIcons", brokerTooltip = true },
		BROKER_SETTINGS_GROUP_HEADER_ALIGN = { "brokerGroupHeaderAlign", brokerTooltip = true },
		BROKER_SETTINGS_NICKNAME_COLOR = { "brokerNicknameColor", brokerTooltip = true, prerequisite = { "brokerShowColNickname", true } },
		BROKER_SETTINGS_CHARACTER_COLOR = { "brokerCharacterColor", brokerTooltip = true, prerequisite = { "brokerShowColCharacter", true } },
		BROKER_SETTINGS_ZONE_COLOR = { "brokerZoneColor", brokerTooltip = true, prerequisite = { "brokerShowColZone", true } },
		BROKER_SETTINGS_REALM_COLOR = { "brokerRealmColor", brokerTooltip = true, prerequisite = { "brokerShowColRealm", true } },
		BROKER_SETTINGS_NOTES_COLOR = { "brokerNotesColor", brokerTooltip = true, prerequisite = { "brokerShowColNotes", true } },
		BROKER_SETTINGS_SHOW_ICON = { "brokerShowIcon", brokerLine = true },
		BROKER_SETTINGS_SHOW_LABEL = { "brokerShowLabel", brokerLine = true },
		BROKER_SETTINGS_SHOW_TOTAL = { "brokerShowTotal", brokerLine = true },
		BROKER_SETTINGS_SHOW_GROUPS = { "brokerShowGroups", brokerLine = true },
		BROKER_SETTINGS_SHOW_WOW_ICON = { "brokerShowWoWIcon", brokerLine = true, prerequisite = { "brokerShowGroups", true } },
		BROKER_SETTINGS_SHOW_BNET_ICON = { "brokerShowBNetIcon", brokerLine = true, prerequisite = { "brokerShowGroups", true } },
	},
	guildBroker = {
		GUILD_BROKER_SETTINGS_ENABLE = { "guildBrokerEnabled", brokerLine = true },
		GUILD_BROKER_SETTINGS_CLICK_ACTION = { "guildBrokerClickAction", outcome = "brokerClick", valueAliases = { guild_frame = "guild_tab" } },
		GUILD_BROKER_NICKNAME_USE_CLASS_COLOR = { "guildBrokerNicknameColor", brokerTooltip = true, guildNicknameClassColor = true },
		GUILD_BROKER_SETTINGS_NICKNAME_COLOR = { "guildBrokerNicknameColor", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_SHOW_HINTS = { "guildBrokerShowHints", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_GROUP_MODE = { "guildBrokerGroupMode", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_FILTER = { "guildBrokerFilter", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_MAX_ROWS = { "guildBrokerMaxRows", brokerTooltip = true, helpOnly = true },
		GUILD_BROKER_SETTINGS_HIDE_LEVEL_AT_MAX = { "guildBrokerHideLevelAtMax", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_SHOW_CLASS_ICONS = { "guildBrokerShowClassIcons", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_SORT_MODE = { "guildBrokerSortMode", brokerTooltip = true },
		GUILD_BROKER_SETTINGS_RANK_COLOR = { "guildBrokerRankColor", brokerTooltip = true, prerequisite = { "guildBrokerShowColRank", true } },
		GUILD_BROKER_SETTINGS_ZONE_COLOR = { "guildBrokerZoneColor", brokerTooltip = true, prerequisite = { "guildBrokerShowColZone", true } },
		GUILD_BROKER_SETTINGS_NOTE_COLOR = { "guildBrokerNoteColor", brokerTooltip = true, prerequisite = { "guildBrokerShowColNote", true } },
		GUILD_BROKER_SETTINGS_OFFICER_NOTE_COLOR = { "guildBrokerOfficerNoteColor", brokerTooltip = true, prerequisite = { "guildBrokerShowColOfficerNote", true } },
		GUILD_BROKER_SETTINGS_SHOW_ICON = { "guildBrokerShowIcon", brokerLine = true },
		GUILD_BROKER_SETTINGS_SHOW_LABEL = { "guildBrokerShowLabel", brokerLine = true },
		GUILD_BROKER_SETTINGS_SHOW_TOTAL = { "guildBrokerShowTotal", brokerLine = true },
		GUILD_BROKER_SETTINGS_SHOW_APPLICANTS = { "guildBrokerShowApplicants", brokerLine = true },
		GUILD_BROKER_SETTINGS_EXCLUDE_SELF = { "guildBrokerExcludeSelf", brokerLine = true },
	},
	who = {
		WHO_SETTINGS_DOUBLE_CLICK = { "whoDoubleClickAction", social = "who" },
		WHO_HISTORY_ENABLED = { "whoSearchHistoryEnabled", outcome = "whoHistory" },
		SETTINGS_LEGACY_WHO_HISTORY_LIMIT = { "whoSearchHistoryMax", outcome = "whoHistory",
			prerequisite = { "whoSearchHistoryEnabled", true }, examples = { 3, 8 } },
		WHO_SETTINGS_CLASS_ICONS = { "whoShowClassIcons", social = "who" },
		WHO_SETTINGS_CLASS_COLORS = { "whoClassColorNames", social = "who" },
		WHO_SETTINGS_LEVEL_COLORS = { "whoLevelColors", social = "who" },
		WHO_SETTINGS_ZEBRA = { "whoZebraStripes", social = "who" },
		SETTINGS_WHO_ZEBRA_STRIPE_STRENGTH = { "whoZebraStripeStrength", social = "who", prerequisite = { "whoZebraStripes", true } },
	},
	guild = {
		SETTINGS_ENABLE_GUILD_TAB = { "enableGuildTab", social = "guild" },
		SETTINGS_GUILD_SHOW_CLASS_ICONS = { "guildTabShowClassIcons", social = "guild", region = "classIcon" },
		SETTINGS_GUILD_USE_NICKNAMES = { "guildTabUseNicknames", social = "guild", region = "nameText" },
		SETTINGS_GUILD_DEFAULT_FILTER = { "guildTabFilterMode", social = "guild" },
		SETTINGS_GUILD_DEFAULT_SORT = { "guildTabSortMode", social = "guild" },
	},
	raidFonts = {
		SETTINGS_FONT = { "fontRaidName", social = "raidFonts" },
		SETTINGS_FONT_SIZE_NUM = { "fontSizeRaidName", social = "raidFonts" },
		SETTINGS_FONT_FLAGS = { "fontOutlineRaidName", social = "raidFonts" },
	},
}

Catalog.guides = {
	SETTINGS_SIMPLE_MODE = "SETTINGS_GUIDE_SIMPLE_MODE",
	SETTINGS_SIMPLE_MODE_SHOW_SEARCH = "SETTINGS_GUIDE_SIMPLE_SEARCH",
	SETTINGS_FRAME_WIDTH = "SETTINGS_GUIDE_FRAME_WIDTH",
	SETTINGS_FRAME_HEIGHT = "SETTINGS_GUIDE_FRAME_HEIGHT",
	SETTINGS_FRAME_SCALE = "SETTINGS_GUIDE_FRAME_SCALE",
	SETTINGS_LOCK_WINDOW = "SETTINGS_GUIDE_FRAME_LOCK",
	SETTINGS_THEME_DROPDOWN = "SETTINGS_GUIDE_THEME_CHOICE",
	SETTINGS_THEME_CUSTOM_TEXT = "SETTINGS_GUIDE_THEME_CUSTOM_TEXT",
	SETTINGS_THEME_CUSTOM_DISABLED_TEXT = "SETTINGS_GUIDE_THEME_CUSTOM_DISABLED",
	SETTINGS_THEME_CUSTOM_HOVER = "SETTINGS_GUIDE_THEME_CUSTOM_HOVER",
	SETTINGS_THEME_CUSTOM_SELECTED = "SETTINGS_GUIDE_THEME_CUSTOM_SELECTED",
	SETTINGS_THEME_BROKER_TOOLTIP_RESET = "SETTINGS_GUIDE_THEME_BROKER_RESET",
	SETTINGS_ENABLE_GUILD_TAB = "SETTINGS_GUIDE_GUILD_TAB",
	SETTINGS_GUILD_DEFAULT_FILTER = "SETTINGS_GUIDE_GUILD_FILTER",
	SETTINGS_GUILD_DEFAULT_SORT = "SETTINGS_GUIDE_GUILD_SORT",
	SETTINGS_GUILD_SHOW_CLASS_ICONS = "SETTINGS_GUIDE_GUILD_ICONS",
	SETTINGS_GUILD_USE_NICKNAMES = "SETTINGS_GUIDE_GUILD_NICKNAMES",
	CONTACT_MEMORY_SETTINGS_ENABLE = "SETTINGS_GUIDE_PRIVATE_NOTES",
	CONTACT_MEMORY_SETTINGS_TOOLTIPS = "SETTINGS_GUIDE_PRIVATE_TOOLTIPS",
	CONTACT_MEMORY_SETTINGS_HIDE_STREAMER = "SETTINGS_GUIDE_PRIVATE_STREAMER",
	SETTINGS_SYNC_GROUPS_NOTE = "SETTINGS_GUIDE_GROUP_NOTE_SYNC",
	SETTINGS_EXTERNAL_MENU_BRIDGE = "SETTINGS_GUIDE_MENU_BRIDGE",
	BROKER_SETTINGS_CLICK_ACTION = "SETTINGS_GUIDE_BROKER_CLICK",
	GUILD_BROKER_SETTINGS_CLICK_ACTION = "SETTINGS_GUIDE_GUILD_BROKER_CLICK",
	FRIEND_TAGS_PRIORITIZE_DYNAMIC_GROUPS = "SETTINGS_GUIDE_TAG_GROUP_PRIORITY",
	FRIEND_TAGS_DYNAMIC_GROUP_HEADER_STYLE = "SETTINGS_GUIDE_TAG_GROUP_HEADER",
	AUTO_RAID_ASSIST_ENABLE = "SETTINGS_GUIDE_AUTO_RAID_ASSIST",
	SETTINGS_GLOBAL_SYNC_ENABLE = "SETTINGS_GUIDE_GLOBAL_SYNC",
	SETTINGS_GLOBAL_SYNC_DELETION = "SETTINGS_GUIDE_GLOBAL_SYNC",
	GROUP_FAVORITES = "SETTINGS_GUIDE_FAVORITES_GROUP",
	GROUP_INGAME = "SETTINGS_GUIDE_INGAME_GROUP",
	GROUP_RECENTLY_ADDED = "SETTINGS_GUIDE_RECENT_GROUP",
	SETTINGS_INGAME_MODE_LABEL = "SETTINGS_GUIDE_INGAME_GROUP",
	SETTINGS_RECENTLY_ADDED_DURATION_UNIT = "SETTINGS_GUIDE_RECENT_DURATION",
	SETTINGS_RECENTLY_ADDED_DURATION_VALUE = "SETTINGS_GUIDE_RECENT_DURATION",
	SETTINGS_QUICK_FILTER = "SETTINGS_GUIDE_QUICK_FILTER",
	SORT_PRIMARY_LABEL = "SETTINGS_GUIDE_SORT_ORDER",
	SORT_SECONDARY_LABEL = "SETTINGS_GUIDE_SORT_ORDER",
	SETTINGS_COLOR_CLASS_NAMES = "SETTINGS_GUIDE_CLASS_COLOR",
	SETTINGS_SHOW_FACTION_ICONS = "SETTINGS_GUIDE_FACTION_ICON",
	SETTINGS_SHOW_FACTION_BG = "SETTINGS_GUIDE_FACTION_BG",
	SETTINGS_GRAY_OTHER_FACTION = "SETTINGS_GUIDE_OTHER_FACTION",
	SETTINGS_SHOW_RULESET_NAME = "SETTINGS_GUIDE_RULESET",
	SETTINGS_SHOW_REALM_NAME = "SETTINGS_GUIDE_REALM",
	SETTINGS_NAME_FORMAT_HEADER = "SETTINGS_GUIDE_NAME_PRESET",
	SETTINGS_NAME_FORMAT_TOOLTIP = "SETTINGS_GUIDE_NAME_FORMAT",
	SETTINGS_INFO_FORMAT_HEADER = "SETTINGS_GUIDE_INFO_PRESET",
	SETTINGS_INFO_FORMAT_TOOLTIP = "SETTINGS_GUIDE_INFO_FORMAT",
	SETTINGS_HIDE_MAX_LEVEL = "SETTINGS_GUIDE_MAX_LEVEL",
	SETTINGS_COLOR_LEVEL_BY_DIFFICULTY = "SETTINGS_GUIDE_DIFFICULTY",
	SETTINGS_COMPACT_MODE = "SETTINGS_GUIDE_COMPACT",
	SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "SETTINGS_GUIDE_ACCOUNT_BADGE",
	SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "SETTINGS_GUIDE_ACCOUNT_ROW",
	SETTINGS_SHOW_MOBILE_AS_AFK = "SETTINGS_GUIDE_MOBILE_AFK",
	SETTINGS_TREAT_MOBILE_OFFLINE = "SETTINGS_GUIDE_MOBILE_OFFLINE",
	SETTINGS_SHOW_GAME_ICON = "SETTINGS_GUIDE_GAME_ICON",
	SETTINGS_ENABLE_FAVORITE_ICON = "SETTINGS_GUIDE_FAVORITE_MARK",
	SETTINGS_FAVORITE_ICON_STYLE = "SETTINGS_GUIDE_FAVORITE_STYLE",
	SETTINGS_HIDE_EMPTY_GROUPS = "SETTINGS_GUIDE_EMPTY_GROUPS",
	SETTINGS_ACCORDION_GROUPS = "SETTINGS_GUIDE_ACCORDION",
	SETTINGS_HEADER_COUNT_FORMAT = "SETTINGS_GUIDE_GROUP_COUNT",
	SETTINGS_LEGACY_TASK_STREAM = "SETTINGS_GUIDE_STREAM_ACTIVE",
	WHO_SETTINGS_DOUBLE_CLICK = "SETTINGS_GUIDE_WHO_CLICK",
	BROKER_SETTINGS_TOOLTIP_MODE = "SETTINGS_GUIDE_BROKER_MODE",
	BUTTON_EXPORT = "SETTINGS_GUIDE_BACKUP_EXPORT",
	SETTINGS_IMPORT_BTN = "SETTINGS_GUIDE_BACKUP_IMPORT",
}

-- Existing localized descriptions also cover controls shared with the beta UI.
Catalog.guideDescriptions = {
	SETTINGS_ENABLE_STREAMER_MODE = "STREAMER_MODE_ENABLE_DESC",
	WHO_HISTORY_ENABLED = "SETTINGS_LEGACY_WHO_HISTORY_DESC",
	SETTINGS_INGAME_MODE_LABEL = "SETTINGS_INGAME_MODE_TOOLTIP_DESC",
	SETTINGS_FONT_SIZE_NUM = "SETTINGS_FONT_SIZE_TOOLTIP",
	SORT_PRIMARY_LABEL = "SETTINGS_PRIMARY_SORT_DESC",
	SORT_SECONDARY_LABEL = "SETTINGS_SECONDARY_SORT_DESC",
	FRIEND_TAGS_EDITOR_OPEN = "FRIEND_TAGS_EDITOR_DESC",
	FRIEND_TAGS_SYNC_LOCAL_BUTTON = "FRIEND_TAGS_SYNC_LOCAL_DESC",
	FRIEND_TAGS_MAX_ROW_CHIPS = "FRIEND_TAGS_SETTINGS_MAX_ROW_CHIPS_DESC",
	FRIEND_TAGS_MAX_TOOLTIP_CHIPS = "FRIEND_TAGS_SETTINGS_MAX_TOOLTIP_CHIPS_DESC",
	KC_ENABLE = "KC_DESC",
	KC_CLEAR_ALL = "KC_CLEAR_CONFIRM",
	SETTINGS_MIGRATE_BTN = "SETTINGS_MIGRATE_TOOLTIP",
	WIZARD_BTN = "WIZARD_BTN_TOOLTIP",
	WIZARD_VIEW_BACKUP_BTN = "WIZARD_VIEW_BACKUP_TOOLTIP",
	SETTINGS_THEME_RESET_DARK = "SETTINGS_RESET_THEME_DESC",
	SETTINGS_THEME_RESET_CUSTOM = "SETTINGS_RESET_CUSTOM_COLORS_DESC",
	CHANGELOG_TITLE = "SETTINGS_CENTER_PAGE_CHANGELOG_DESC",
	SETTINGS_CENTER_HELP_SUPPORT = "SETTINGS_CENTER_PAGE_SUPPORT_LINKS_DESC",
}

Catalog.guidePageContext = {
	rows = "SETTINGS_CENTER_PAGE_FRIENDS_DISPLAY_DESC",
	rowFonts = "SETTINGS_CENTER_PAGE_APPEARANCE_FONTS_DESC",
	behavior = "SETTINGS_CENTER_PAGE_FRIENDS_BEHAVIOR_DESC",
	friendTabs = "SETTINGS_FRIEND_TABS_ORDER_DESC",
	automatic = "SETTINGS_CENTER_PAGE_GROUPS_BUILTINS_DESC",
	headers = "SETTINGS_CENTER_PAGE_GROUPS_HEADERS_DESC",
	tags = "FRIEND_TAGS_SETTINGS_DESC",
	filters = "FILTER_BUILDER_DESC",
	layout = "SETTINGS_CENTER_PAGE_APPEARANCE_FRAME_DESC",
	theme = "SETTINGS_CENTER_PAGE_APPEARANCE_THEME_DESC",
	who = "WHO_SETTINGS_DESC",
	guild = "SETTINGS_GUILD_DESC",
	raid = "SETTINGS_RAID_DESC",
	raidFonts = "SETTINGS_CENTER_PAGE_APPEARANCE_FONTS_DESC",
	stream = "STREAMER_MODE_DESC",
	contacts = "CONTACT_MEMORY_SETTINGS_ENABLE_DESC",
	knownCharacters = "KC_DESC",
	backups = "SETTINGS_EXPORT_DESC",
	sync = "SETTINGS_GLOBAL_SYNC_DESC",
	broker = "SETTINGS_CENTER_CARD_BROKER_DESC",
	guildBroker = "GUILD_BROKER_SETTINGS_ENABLE_DESC",
	help = "SETTINGS_ADVANCED_DESC",
}

Catalog.guideSectionContext = {
	SETTINGS_GROUP_ORDER = "SETTINGS_GUIDE_GROUP_ORDER",
	SETTINGS_FRIEND_TABS_ORDER = "SETTINGS_FRIEND_TABS_ORDER_DESC",
	SETTINGS_MIGRATION_HEADER = "SETTINGS_MIGRATION_DESC",
	SETTINGS_SYNC_GROUPS_NOTE_HEADER = "SETTINGS_SYNC_GROUPS_NOTE_DESC",
	WIZARD_HEADER = "WIZARD_HEADER_DESC",
	SETTINGS_RAID_SHORTCUTS_TITLE = "SETTINGS_GUIDE_RAID_SHORTCUT",
	AUTO_RAID_ASSIST_TITLE = "AUTO_RAID_ASSIST_DESC",
	SETTINGS_BETA_FEATURES_TITLE = "SETTINGS_BETA_FEATURES_DESC",
	BROKER_SETTINGS_COLUMNS_HEADER = "SETTINGS_CENTER_BROKER_COLUMN_ORDER_VISIBILITY_DESC",
	BROKER_SETTINGS_COLUMN_COLORS = "SETTINGS_CENTER_BROKER_COLUMN_COLORS_DESC",
	GUILD_BROKER_SETTINGS_COLUMNS = "SETTINGS_CENTER_BROKER_COLUMN_ORDER_VISIBILITY_DESC",
	GUILD_BROKER_SETTINGS_COLUMN_COLORS = "SETTINGS_CENTER_BROKER_COLUMN_COLORS_DESC",
}

Catalog.guideFontSections = {
	SETTINGS_FRIEND_NAME_SETTINGS = true,
	SETTINGS_FRIEND_INFO_SETTINGS = true,
	SETTINGS_FONT_TABS_TITLE = true,
	SETTINGS_FONT_RAID_TITLE = true,
	SETTINGS_GROUP_FONT_HEADER = true,
}

Catalog.categories = {
	{ "home", "SETTINGS_LEGACY_HOME" },
	{ "friends", "SETTINGS_CENTER_CATEGORY_FRIENDS", "rows", "rowFonts", "behavior", "friendTabs" },
	{ "groups", "SETTINGS_LEGACY_GROUPS", "automatic", "headers", "tags", "filters" },
	{ "appearance", "SETTINGS_TAB_APPEARANCE", "layout", "theme" },
	{ "social", "SETTINGS_LEGACY_SOCIAL", "who", "guild", "raid", "raidFonts" },
	{ "privacy", "SETTINGS_CENTER_CATEGORY_PRIVACY", "stream", "contacts", "knownCharacters" },
	{ "data", "SETTINGS_LEGACY_DATA", "backups", "sync", "broker", "guildBroker" },
	{ "help", "SETTINGS_CENTER_CATEGORY_HELP", "help" },
}

-- Existing tab numbers are part of the external routing contract.
Catalog.tabs = {
	"GeneralTab", "FontsTab", "GroupsTab", "AdvancedTab", "BrokerTab", "GlobalSyncTab",
	"StreamerTab", "RaidTab", "WhoTab", "ThemeTab", "FilterSortTab", "GuildTab",
	"FriendTagsTab", "ContactMemoryTab", "FriendTabsTab",
}

Catalog.pages = {
	rows = { 1, "SETTINGS_DISPLAY_OPTIONS", sample = "friends" },
	rowFonts = { 2, "SETTINGS_TAB_FONTS", sample = "friends" },
	behavior = { 1, "SETTINGS_BEHAVIOR_HEADER" },
	friendTabs = { 15, "SETTINGS_CENTER_PAGE_FRIEND_TABS", sample = "friendTabs" },
	automatic = { 1, "SETTINGS_GROUP_MANAGEMENT", sample = "groups" },
	headers = { 3, "SETTINGS_TAB_GROUPS", sample = "groups" },
	tags = { 13, "SETTINGS_TAB_FRIEND_TAGS", sample = "friends" },
	filters = { 11, "SETTINGS_TAB_FILTER_SORT", sample = "filters" },
	layout = { 1, "SETTINGS_FRIENDS_UI_STYLE_HEADER", sample = "friends" },
	theme = { 10, "SETTINGS_TAB_THEME", sample = "friends" },
	who = { 9, "SETTINGS_TAB_WHO", sample = "who" },
	guild = { 12, "SETTINGS_TAB_GUILD", sample = "guild" },
	raid = { 8, "SETTINGS_TAB_RAID" },
	raidFonts = { 2, "SETTINGS_FONT_RAID_TITLE", sample = "raidFonts" },
	stream = { 7, "STREAMER_MODE_TITLE", sample = "friends" },
	contacts = { 14, "CONTACT_MEMORY_TITLE" },
	knownCharacters = { 14, "KC_TITLE" },
	backups = { 4, "SETTINGS_EXPORT_HEADER" },
	sync = { 6, "SETTINGS_TAB_GLOBAL_SYNC" },
	broker = { 5, "SETTINGS_TAB_DATABROKER", sample = "broker" },
	guildBroker = { 5, "GUILD_BROKER_SETTINGS_HEADER", sample = "guildBroker" },
	help = { 4, "SETTINGS_CENTER_CATEGORY_HELP" },
}

Catalog.tabRoutes = {
	"rows", "rowFonts", "headers", "backups", "broker", "sync", "stream", "raid", "who", "theme",
	"filters", "guild", "tags", "contacts", "friendTabs",
}

Catalog.sections = {
	SETTINGS_FRIENDS_UI_STYLE_HEADER = "layout",
	SETTINGS_FRAME_DIMENSIONS_HEADER = "layout",
	SETTINGS_GROUP_MANAGEMENT = "automatic",
	SETTINGS_BEHAVIOR_HEADER = "behavior",
	SETTINGS_FONT_RAID_TITLE = "raidFonts",
	SETTINGS_BETA_FEATURES_TITLE = "help",
	SETTINGS_LEGACY_DIAGNOSTICS = "help",
	KC_TITLE = "knownCharacters",
	SETTINGS_THEME_BROKER_TOOLTIP_HEADER = "theme",
	GUILD_BROKER_SETTINGS_HEADER = "guildBroker",
	GUILD_BROKER_SETTINGS_COLUMN_COLORS = "guildBroker",
	GUILD_BROKER_SETTINGS_COLUMNS = "guildBroker",
}

Catalog.details = {
	SETTINGS_GROUP_FONT_HEADER = true,
	FRIEND_TAGS_SETTINGS_SEARCH = true,
	FRIEND_TAGS_SETTINGS_GROUPS = true,
	SETTINGS_THEME_CUSTOM_HEADER = true,
	SETTINGS_THEME_DARK_HEADER = true,
	BROKER_SETTINGS_FONT_HEADER = true,
	BROKER_SETTINGS_COLUMNS_HEADER = true,
	BROKER_SETTINGS_COLUMN_COLORS = true,
	GUILD_BROKER_SETTINGS_COLUMN_COLORS = true,
	GUILD_BROKER_SETTINGS_COLUMNS = true,
	SETTINGS_SYNC_GROUPS_NOTE_HEADER = true,
	WIZARD_HEADER = true,
	SETTINGS_EXTERNAL_MENU_BRIDGE = true,
}

Catalog.links = {
	hideEmptyGroups = "automatic",
	showFavoritesGroup = "automatic",
	enableFavoriteIcon = "rows",
	friendInfoFormatting = "rows",
	friendTagsVisibility = "tags",
	friendTagsCompact = "tags",
	privateNotesTooltips = "contacts",
	betaFeatures = "help",
}

-- Search terms refer to localized labels. The alias strings contain terms players
-- use for the task, while previous labels and descriptions remain searchable.
Catalog.aliases = {
	SETTINGS_SHOW_REALM_NAME = "SETTINGS_LEGACY_REALM_TERMS",
	SETTINGS_SHOW_RULESET_NAME = "SETTINGS_LEGACY_REALM_TERMS",
	SETTINGS_HIDE_EMPTY_GROUPS = "SETTINGS_LEGACY_EMPTY_TERMS",
	BUTTON_EXPORT = "SETTINGS_LEGACY_BACKUP_TERMS",
	SETTINGS_STREAMER_NAME_FORMAT = "SETTINGS_LEGACY_STREAM_TERMS",
	SETTINGS_NAME_FORMAT_HEADER = "SETTINGS_NAME_FORMAT_LABEL",
	SETTINGS_NAME_FORMAT_TOOLTIP = "SETTINGS_NAME_FORMAT_CUSTOM_LABEL",
	SETTINGS_INFO_FORMAT_HEADER = "SETTINGS_INFO_FORMAT_LABEL",
	SETTINGS_INFO_FORMAT_TOOLTIP = "SETTINGS_INFO_FORMAT_CUSTOM_LABEL",
	FILTER_BUILDER_ADD_FILTER = "FILTER_BUILDER_CREATE_FILTER_TITLE",
	FILTER_BUILDER_ADD_SORTER = "FILTER_BUILDER_CREATE_SORTER_TITLE",
	KC_ENABLE = "KC_DESC",
}

Catalog.filterSearchModes = {
	FILTER_BUILDER_FILTERS = "filter",
	FILTER_BUILDER_ADD_FILTER = "filter",
	FILTER_BUILDER_SORTERS = "sorter",
	FILTER_BUILDER_ADD_SORTER = "sorter",
	FILTER_BUILDER_ADD_SORT_STEP = "sorter",
}

Catalog.homeTargets = {
	CHANGELOG_TITLE = "releaseTitle",
	SETTINGS_CENTER_HELP_SUPPORT = "support",
}

-- Editing a sort step requires a custom sorter.
Catalog.searchFallbacks = {
	FILTER_BUILDER_ADD_SORT_STEP = { "FILTER_BUILDER_ADD_SORTER", "SETTINGS_TAB_FILTER_SORT" },
}

Catalog.themeSections = {
	SETTINGS_THEME_DARK_HEADER = "dark",
	SETTINGS_THEME_CUSTOM_HEADER = "custom",
}

-- Index by native tab section and localized control label. Dynamic editor
-- records are indexed by their entry point, without including player data.
Catalog.search = {
	theme = {
		SETTINGS_THEME_HEADER = {
			"SETTINGS_THEME_HEADER",
			"SETTINGS_THEME_DROPDOWN",
		},
		SETTINGS_THEME_DARK_HEADER = {
			"SETTINGS_THEME_DARK_HEADER",
			"SETTINGS_THEME_ACCENT_COLOR",
			"SETTINGS_THEME_RESET_DARK",
		},
		SETTINGS_THEME_CUSTOM_HEADER = {
			"SETTINGS_THEME_CUSTOM_HEADER",
			"SETTINGS_THEME_CUSTOM_BACKGROUND",
			"SETTINGS_THEME_CUSTOM_SURFACE",
			"SETTINGS_THEME_CUSTOM_INSET",
			"SETTINGS_THEME_CUSTOM_CONTROL",
			"SETTINGS_THEME_CUSTOM_BORDER",
			"SETTINGS_THEME_CUSTOM_ACCENT",
			"SETTINGS_THEME_CUSTOM_TEXT",
			"SETTINGS_THEME_CUSTOM_DISABLED_TEXT",
			"SETTINGS_THEME_CUSTOM_HOVER",
			"SETTINGS_THEME_CUSTOM_SELECTED",
			"SETTINGS_THEME_CUSTOM_SCROLL_THUMB",
			"SETTINGS_THEME_CUSTOM_ICON",
			"SETTINGS_THEME_RESET_CUSTOM",
		},
		SETTINGS_THEME_BROKER_TOOLTIP_HEADER = {
			"SETTINGS_THEME_BROKER_TOOLTIP_HEADER",
			"SETTINGS_THEME_BROKER_TOOLTIP_BACKGROUND",
			"SETTINGS_THEME_BROKER_TOOLTIP_OPACITY",
			"SETTINGS_THEME_BROKER_TOOLTIP_RESET",
		},
	},
	friendTabs = {
		SETTINGS_FRIEND_TABS_ORDER = {
			"SETTINGS_FRIEND_TABS_ORDER",
			"FRIENDS_UI_SECTION_FRIENDS",
			"FRIENDS_UI_SECTION_RECENT_ALLIES",
			"FRIENDS_UI_SECTION_QUICK_JOIN",
			"FRIENDS_UI_SECTION_REQUESTS",
			"FRIENDS_UI_SECTION_RECRUIT_A_FRIEND",
			"FRIENDS_UI_SECTION_RAID",
			"FRIENDS_UI_SECTION_GUILD",
			"FRIENDS_UI_SECTION_WHO",
			"SETTINGS_FRIEND_TABS_REQUESTS_POPULATED_ONLY",
			"SETTINGS_FRIEND_TABS_QUICK_JOIN_POPULATED_ONLY",
		},
	},
	layout = {
		SETTINGS_FRIENDS_UI_STYLE_HEADER = {
			"SETTINGS_FRIENDS_UI_STYLE_HEADER",
			"SETTINGS_FRIENDS_UI_STYLE",
			"SETTINGS_SMOOTH_SCROLLING",
		},
		SETTINGS_DISPLAY_OPTIONS = {
			"SETTINGS_ENABLE_ELVUI_SKIN",
		},
		SETTINGS_BEHAVIOR_HEADER = {
			"SETTINGS_USE_UI_PANEL_SYSTEM",
			"SETTINGS_SIMPLE_MODE",
			"SETTINGS_SIMPLE_MODE_SHOW_SEARCH",
		},
		SETTINGS_FRAME_DIMENSIONS_HEADER = {
			"SETTINGS_FRAME_DIMENSIONS_HEADER",
			"SETTINGS_FRAME_WIDTH",
			"SETTINGS_FRAME_HEIGHT",
			"SETTINGS_FRAME_SCALE",
			"SETTINGS_LOCK_WINDOW",
		},
	},
	rows = {
		SETTINGS_LEGACY_ROWS_IDENTITY = { "SETTINGS_LEGACY_ROWS_IDENTITY" },
		SETTINGS_LEGACY_ROWS_STATUS = { "SETTINGS_LEGACY_ROWS_STATUS" },
		SETTINGS_LEGACY_ROWS_FAVORITES = { "SETTINGS_LEGACY_ROWS_FAVORITES" },
		SETTINGS_DISPLAY_OPTIONS = {
			"SETTINGS_DISPLAY_OPTIONS",
			"SETTINGS_COLOR_CLASS_NAMES",
			"SETTINGS_SHOW_FACTION_ICONS",
			"SETTINGS_SHOW_FACTION_BG",
			"SETTINGS_GRAY_OTHER_FACTION",
			"SETTINGS_SHOW_MULTI_ACCOUNT_BADGE",
			"SETTINGS_SHOW_MULTI_ACCOUNT_INFO",
			"SETTINGS_SHOW_RULESET_NAME",
			"SETTINGS_SHOW_REALM_NAME",
			"SETTINGS_HIDE_MAX_LEVEL",
			"SETTINGS_SHOW_MOBILE_AS_AFK",
			"SETTINGS_TREAT_MOBILE_OFFLINE",
			"SETTINGS_SHOW_GAME_ICON",
			"SETTINGS_COLOR_LEVEL_BY_DIFFICULTY",
			"SETTINGS_ENABLE_FAVORITE_ICON",
			"SETTINGS_FAVORITE_ICON_STYLE",
		},
		SETTINGS_NAME_FORMAT_HEADER = {
			"SETTINGS_NAME_FORMAT_HEADER",
			"SETTINGS_NAME_FORMAT_TOOLTIP",
		},
		SETTINGS_INFO_FORMAT_HEADER = {
			"SETTINGS_INFO_FORMAT_HEADER",
			"SETTINGS_INFO_FORMAT_TOOLTIP",
		},
		SETTINGS_BEHAVIOR_HEADER = {
			"SETTINGS_COMPACT_MODE",
		},
	},
	behavior = {
		SETTINGS_DISPLAY_OPTIONS = {
			"SETTINGS_SHOW_BLIZZARD",
		},
		SETTINGS_BEHAVIOR_HEADER = {
			"SETTINGS_BEHAVIOR_HEADER",
			"SETTINGS_FRIENDLIST_CLICK_WHISPER",
			"SETTINGS_FRIENDLIST_CLICK_WHISPER_MODE",
		},
	},
	automatic = {
		SETTINGS_GROUP_MANAGEMENT = {
			"SETTINGS_GROUP_MANAGEMENT",
			"SORT_PRIMARY_LABEL",
			"SORT_SECONDARY_LABEL",
			"SETTINGS_QUICK_FILTER",
			"SETTINGS_INGAME_MODE_LABEL",
			"SETTINGS_RECENTLY_ADDED_DURATION_UNIT",
			"SETTINGS_RECENTLY_ADDED_DURATION_VALUE",
			"GROUP_FAVORITES",
			"GROUP_INGAME",
			"GROUP_RECENTLY_ADDED",
		},
		SETTINGS_DISPLAY_OPTIONS = {
			"SETTINGS_HIDE_EMPTY_GROUPS",
		},
		SETTINGS_BEHAVIOR_HEADER = {
			"SETTINGS_ACCORDION_GROUPS",
		},
	},
	contacts = {
		CONTACT_MEMORY_TITLE = {
			"CONTACT_MEMORY_TITLE",
			"CONTACT_MEMORY_SETTINGS_ENABLE",
			"CONTACT_MEMORY_SETTINGS_TOOLTIPS",
			"CONTACT_MEMORY_SETTINGS_HIDE_STREAMER",
		},
	},
	knownCharacters = {
		KC_TITLE = {
			"KC_TITLE",
			"KC_ENABLE",
			"KC_AUTO",
			"KC_LIMIT",
			"KC_CLEAR_ALL",
		},
	},
	tags = {
		SETTINGS_TAB_FRIEND_TAGS = {
			"SETTINGS_TAB_FRIEND_TAGS",
			"FRIEND_TAGS_ENABLE",
			"FRIEND_TAGS_EDITOR_OPEN",
		},
		FRIEND_TAGS_SETTINGS_VISIBILITY = {
			"FRIEND_TAGS_SETTINGS_VISIBILITY",
			"FRIEND_TAGS_SHOW_ROW_CHIPS",
			"FRIEND_TAGS_SHOW_TOOLTIP_CHIPS",
			"FRIEND_TAGS_SHOW_BROKER_CHIPS",
			"FRIEND_TAGS_STREAMER_MODE",
			"FRIEND_TAGS_FULL_WIDTH_ROWS",
			"FRIEND_TAGS_SETTINGS_COMPACT_MODE",
			"FRIEND_TAGS_MAX_ROW_CHIPS",
			"FRIEND_TAGS_CHIPS_PER_LINE",
			"FRIEND_TAGS_CHIP_ICON_SIZE",
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"FRIEND_TAGS_CHIP_FONT_SIZE",
			"FRIEND_TAGS_MAX_TOOLTIP_CHIPS",
		},
		FRIEND_TAGS_SETTINGS_SEARCH = {
			"FRIEND_TAGS_SETTINGS_SEARCH",
			"FRIEND_TAGS_SEARCH_BLIZZARD",
			"FRIEND_TAGS_SEARCH_CUSTOM",
			"FRIEND_TAGS_SHOW_MENU_COUNTS",
		},
		FRIEND_TAGS_SETTINGS_GROUPS = {
			"FRIEND_TAGS_SETTINGS_GROUPS",
			"FRIEND_TAGS_SETTINGS_DYNAMIC_GROUPS",
			"FRIEND_TAGS_HIDE_DYNAMIC_GROUP_TAG",
			"FRIEND_TAGS_HIDE_ALL_DYNAMIC_GROUP_TAGS",
			"FRIEND_TAGS_PRIORITIZE_DYNAMIC_GROUPS",
			"FRIEND_TAGS_DYNAMIC_GROUP_HEADER_STYLE",
			"FRIEND_TAGS_SYNC_LOCAL_BUTTON",
		},
	},
	guild = {
		SETTINGS_TAB_GUILD = {
			"SETTINGS_TAB_GUILD",
			"SETTINGS_ENABLE_GUILD_TAB",
		},
		SETTINGS_GUILD_ROSTER_HEADER = {
			"SETTINGS_GUILD_ROSTER_HEADER",
			"SETTINGS_GUILD_DEFAULT_FILTER",
			"SETTINGS_GUILD_DEFAULT_SORT",
			"SETTINGS_GUILD_SHOW_CLASS_ICONS",
			"SETTINGS_GUILD_USE_NICKNAMES",
		},
	},
	rowFonts = {
		SETTINGS_FRIEND_NAME_SETTINGS = {
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"SETTINGS_FRIEND_NAME_SETTINGS",
			"SETTINGS_FONT_SIZE_NUM",
			"SETTINGS_FONT_COLOR",
		},
		SETTINGS_FRIEND_INFO_SETTINGS = {
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"SETTINGS_FRIEND_INFO_SETTINGS",
			"SETTINGS_FONT_SIZE_NUM",
			"SETTINGS_FONT_COLOR",
		},
		SETTINGS_FONT_TABS_TITLE = {
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"SETTINGS_FONT_TABS_TITLE",
			"SETTINGS_FONT_SIZE_NUM",
		},
	},
	raidFonts = {
		SETTINGS_FONT_RAID_TITLE = {
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"SETTINGS_FONT_RAID_TITLE",
			"SETTINGS_FONT_SIZE_NUM",
		},
	},
	headers = {
		SETTINGS_GROUP_HEADER_SETTINGS = {
			"SETTINGS_GROUP_HEADER_SETTINGS",
			"SETTINGS_HEADER_COUNT_FORMAT",
			"SETTINGS_GROUP_HEADER_ALIGN",
			"SETTINGS_GROUP_ARROW_ALIGN",
			"SETTINGS_SHOW_GROUP_ARROW",
		},
		SETTINGS_GROUP_FONT_HEADER = {
			"SETTINGS_FONT",
			"SETTINGS_FONT_FLAGS",
			"SETTINGS_GROUP_FONT_HEADER",
			"SETTINGS_FONT_SIZE_NUM",
		},
		SETTINGS_GROUP_ORDER = {
			"SETTINGS_GROUP_ORDER",
		},
	},
	backups = {
		SETTINGS_TAB_ADVANCED = {
			"SETTINGS_TAB_ADVANCED",
		},
		SETTINGS_MIGRATION_HEADER = {
			"SETTINGS_MIGRATION_HEADER",
			"SETTINGS_MIGRATE_BTN",
		},
		SETTINGS_EXPORT_HEADER = {
			"SETTINGS_EXPORT_HEADER",
			"BUTTON_EXPORT",
			"SETTINGS_IMPORT_BTN",
		},
		SETTINGS_SYNC_GROUPS_NOTE_HEADER = {
			"SETTINGS_SYNC_GROUPS_NOTE_HEADER",
			"SETTINGS_SYNC_GROUPS_NOTE",
		},
		WIZARD_HEADER = {
			"WIZARD_HEADER",
			"WIZARD_BTN",
			"WIZARD_VIEW_BACKUP_BTN",
		},
		SETTINGS_EXTERNAL_MENU_BRIDGE = {
			"SETTINGS_EXTERNAL_MENU_BRIDGE",
		},
	},
	help = {
		SETTINGS_BETA_FEATURES_TITLE = {
			"SETTINGS_BETA_FEATURES_TITLE",
			"SETTINGS_BETA_FEATURES_ENABLE",
			"SETTINGS_ENABLE_SETTINGS_CENTER",
		},
		_page = {
			"CHANGELOG_TITLE",
			"SETTINGS_CENTER_HELP_SUPPORT",
		},
		SETTINGS_LEGACY_DIAGNOSTICS = {
			"SETTINGS_LEGACY_DIAGNOSTICS",
			"SETTINGS_SHOW_WELCOME_MESSAGE",
			"SETTINGS_DEBUG_PRINT",
		},
	},
	filters = {
		SETTINGS_TAB_FILTER_SORT = {
			"SETTINGS_TAB_FILTER_SORT",
			"FILTER_BUILDER_FILTERS",
			"FILTER_BUILDER_SORTERS",
			"FILTER_BUILDER_ADD_FILTER",
			"FILTER_BUILDER_ADD_SORTER",
			"FILTER_BUILDER_ADD_SORT_STEP",
		},
	},
	broker = {
		BROKER_SETTINGS_HEADER_INTEGRATION = {
			"BROKER_SETTINGS_HEADER_INTEGRATION",
			"BROKER_SETTINGS_ENABLE",
			"BROKER_SETTINGS_TOOLTIP_MODE",
			"BROKER_SETTINGS_CLICK_ACTION",
		},
		BROKER_SETTINGS_FONT_HEADER = {
			"SETTINGS_FONT_FLAGS",
			"BROKER_SETTINGS_FONT_HEADER",
			"BROKER_SETTINGS_FONT",
			"BROKER_SETTINGS_FONT_SIZE",
			"BROKER_SETTINGS_FONT_NON_LATIN",
		},
		BROKER_SETTINGS_APPEARANCE_HEADER = {
			"BROKER_SETTINGS_APPEARANCE_HEADER",
			"BROKER_SETTINGS_SEPARATOR_COLOR",
			"BROKER_SETTINGS_SHOW_ICON",
			"BROKER_SETTINGS_SHOW_LABEL",
			"BROKER_SETTINGS_SHOW_TOTAL",
			"BROKER_SETTINGS_SHOW_GROUPS",
			"BROKER_SETTINGS_SHOW_WOW_ICON",
			"BROKER_SETTINGS_SHOW_BNET_ICON",
			"BROKER_SETTINGS_SHOW_HINTS",
			"BROKER_SETTINGS_SHOW_CLASS_ICONS",
			"BROKER_SETTINGS_GROUP_HEADER_ALIGN",
		},
		BROKER_SETTINGS_COLUMN_COLORS = {
			"BROKER_SETTINGS_COLUMN_COLORS",
			"BROKER_SETTINGS_NICKNAME_COLOR",
			"BROKER_SETTINGS_CHARACTER_COLOR",
			"BROKER_SETTINGS_ZONE_COLOR",
			"BROKER_SETTINGS_REALM_COLOR",
			"BROKER_SETTINGS_RULESET_COLOR",
			"BROKER_SETTINGS_NOTES_COLOR",
		},
		BROKER_SETTINGS_COLUMNS_HEADER = {
			"BROKER_SETTINGS_COLUMNS_HEADER",
			"BROKER_COLUMN_NICKNAME",
			"BROKER_COLUMN_NAME",
			"BROKER_COLUMN_STATUS",
			"BROKER_COLUMN_LEVEL",
			"BROKER_COLUMN_CHARACTER",
			"BROKER_COLUMN_GAME",
			"BROKER_COLUMN_ZONE",
			"BROKER_COLUMN_REALM",
			"BROKER_COLUMN_RULESET",
			"BROKER_COLUMN_NOTES",
		},
	},
	guildBroker = {
		GUILD_BROKER_SETTINGS_HEADER = {
			"GUILD_BROKER_SETTINGS_HEADER",
			"GUILD_BROKER_SETTINGS_ENABLE",
			"GUILD_BROKER_SETTINGS_SHOW_ICON",
			"GUILD_BROKER_SETTINGS_SHOW_LABEL",
			"GUILD_BROKER_SETTINGS_SHOW_TOTAL",
			"GUILD_BROKER_SETTINGS_SHOW_APPLICANTS",
			"GUILD_BROKER_SETTINGS_SHOW_HINTS",
			"GUILD_BROKER_SETTINGS_CLICK_ACTION",
			"GUILD_BROKER_SETTINGS_GROUP_MODE",
			"GUILD_BROKER_SETTINGS_FILTER",
			"GUILD_BROKER_SETTINGS_MAX_ROWS",
			"GUILD_BROKER_SETTINGS_HIDE_LEVEL_AT_MAX",
			"GUILD_BROKER_SETTINGS_SHOW_CLASS_ICONS",
			"GUILD_BROKER_SETTINGS_EXCLUDE_SELF",
			"GUILD_BROKER_SETTINGS_SORT_MODE",
		},
		GUILD_BROKER_SETTINGS_COLUMN_COLORS = {
			"GUILD_BROKER_SETTINGS_COLUMN_COLORS",
			"GUILD_BROKER_NICKNAME_USE_CLASS_COLOR",
			"GUILD_BROKER_SETTINGS_NICKNAME_COLOR",
			"GUILD_BROKER_SETTINGS_RANK_COLOR",
			"GUILD_BROKER_SETTINGS_ZONE_COLOR",
			"GUILD_BROKER_SETTINGS_NOTE_COLOR",
			"GUILD_BROKER_SETTINGS_OFFICER_NOTE_COLOR",
		},
		GUILD_BROKER_SETTINGS_COLUMNS = {
			"GUILD_BROKER_SETTINGS_COLUMNS",
			"GUILD_BROKER_COL_NICKNAME",
			"GUILD_BROKER_COL_NAME",
			"GUILD_BROKER_COL_LEVEL",
			"GUILD_BROKER_COL_CLASS",
			"GUILD_BROKER_COL_PROFESSIONS",
			"GUILD_BROKER_COL_RANK",
			"GUILD_BROKER_COL_ZONE",
			"GUILD_BROKER_COL_NOTE",
			"GUILD_BROKER_COL_OFFICER_NOTE",
			"GUILD_BROKER_COL_LAST_ONLINE",
		},
	},
	sync = {
		SETTINGS_TAB_GLOBAL_SYNC = {
			"SETTINGS_TAB_GLOBAL_SYNC",
			"BUTTON_DELETE_ALL",
			"SETTINGS_GLOBAL_SYNC_ENABLE",
			"SETTINGS_GLOBAL_SYNC_DELETION",
			"SETTINGS_GLOBAL_SYNC_SHOW_DELETED",
		},
		SETTINGS_GLOBAL_SYNC_HEADER = {
			"SETTINGS_GLOBAL_SYNC_HEADER",
		},
	},
	stream = {
		STREAMER_MODE_TITLE = {
			"STREAMER_MODE_TITLE",
			"SETTINGS_ENABLE_STREAMER_MODE",
		},
		SETTINGS_PRIVACY_OPTIONS = {
			"SETTINGS_PRIVACY_OPTIONS",
			"SETTINGS_LEGACY_TASK_STREAM",
			"STREAMER_MODE_HEADER_TEXT",
			"SETTINGS_STREAMER_NAME_FORMAT",
		},
	},
	raid = {
		SETTINGS_TAB_RAID = {
			"SETTINGS_TAB_RAID",
			"SETTINGS_RAID_ENABLE_READY_CHECK_BUTTON",
		},
		SETTINGS_RAID_SHORTCUTS_TITLE = {
			"SETTINGS_RAID_SHORTCUTS_TITLE",
		},
		AUTO_RAID_ASSIST_TITLE = {
			"AUTO_RAID_ASSIST_TITLE",
			"AUTO_RAID_ASSIST_ENABLE",
		},
	},
	who = {
		SETTINGS_TAB_WHO = {
			"SETTINGS_TAB_WHO",
		},
		WHO_SETTINGS_VISUAL_HEADER = {
			"WHO_SETTINGS_VISUAL_HEADER",
			"WHO_SETTINGS_CLASS_ICONS",
			"WHO_SETTINGS_CLASS_COLORS",
			"WHO_SETTINGS_LEVEL_COLORS",
			"WHO_SETTINGS_ZEBRA",
			"SETTINGS_WHO_ZEBRA_STRIPE_STRENGTH",
		},
		WHO_SETTINGS_BEHAVIOR_HEADER = {
			"WHO_SETTINGS_BEHAVIOR_HEADER",
			"WHO_SETTINGS_DOUBLE_CLICK",
			"WHO_HISTORY_ENABLED",
			"SETTINGS_LEGACY_WHO_HISTORY_LIMIT",
		},
	},
}

if BFL.IsForever then
	table.insert(Catalog.search.who.WHO_SETTINGS_BEHAVIOR_HEADER, 3, "WHO_SETTINGS_OPEN_ON_CHAT_SHIFT_CLICK")
end

local themeSliderKeys = {
	"SETTINGS_THEME_WINDOW_OPACITY",
	"SETTINGS_THEME_POPUP_OPACITY",
	"SETTINGS_THEME_LIST_OPACITY",
	"SETTINGS_THEME_CONTROL_OPACITY",
	"SETTINGS_THEME_HOVER_STRENGTH",
	"SETTINGS_THEME_SELECTION_STRENGTH",
	"SETTINGS_THEME_BORDER_STRENGTH",
	"SETTINGS_THEME_ARTWORK_VISIBILITY",
}
for section in pairs(Catalog.themeSections) do
	for _, key in ipairs(themeSliderKeys) do
		table.insert(Catalog.search.theme[section], key)
	end
end
