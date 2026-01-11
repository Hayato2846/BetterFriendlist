-- Locales/enUS.lua
-- English (US) Localization

local L = BFL_LOCALE

if GetLocale() == "enUS" then
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Enter a name for the new group:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Create"
	L.DIALOG_CREATE_GROUP_BTN2 = "Cancel"
	L.DIALOG_RENAME_GROUP_TEXT = "Enter a new name for the group:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Rename"
	L.DIALOG_RENAME_GROUP_BTN2 = "Cancel"
	L.DIALOG_DELETE_GROUP_TEXT = "Are you sure you want to delete this group?\n\n|cffff0000This will remove all friends from this group.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Delete"
	L.DIALOG_DELETE_GROUP_BTN2 = "Cancel"
	L.DIALOG_DELETE_GROUP_SETTINGS = "Delete group '%s'?\n\nAll friends will be unassigned from this group."
	L.DIALOG_RESET_SETTINGS_TEXT = "Reset all settings to defaults?"
	L.DIALOG_RESET_BTN1 = "Reset"
	L.DIALOG_RESET_BTN2 = "Cancel"
	L.DIALOG_UI_PANEL_RELOAD_TEXT = "Changing the UI Hierarchy setting requires a UI reload.\n\nReload now?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Reload"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Cancel"
	L.RAID_HELP_TITLE = "Raid Roster Help"
	L.RAID_HELP_TEXT = "Click for help on using the raid roster."
	L.RAID_HELP_MULTISELECT_TITLE = "Multi-Selection"
	L.RAID_HELP_MULTISELECT_TEXT = "Hold Ctrl and left-click to select multiple players.\nOnce selected, drag and drop them into any group to move them all at once."
	L.RAID_HELP_MAINTANK_TITLE = "Main Tank"
	L.RAID_HELP_MAINTANK_TEXT = "Shift + Right-Click on a player to set them as Main Tank.\nA tank icon will appear next to their name."
	L.RAID_HELP_MAINASSIST_TITLE = "Main Assist"
	L.RAID_HELP_MAINASSIST_TEXT = "Ctrl + Right-Click on a player to set them as Main Assist.\nAn assist icon will appear next to their name."
	L.RAID_HELP_DRAGDROP_TITLE = "Drag & Drop"
	L.RAID_HELP_DRAGDROP_TEXT = "Drag any player to move them between groups.\nYou can also drag multiple selected players at once.\nEmpty slots can be used to swap positions."
	L.RAID_HELP_COMBAT_TITLE = "Combat Lock"
	L.RAID_HELP_COMBAT_TEXT = "Players cannot be moved during combat.\nThis is a Blizzard restriction to prevent errors."
	L.RAID_INFO_UNAVAILABLE = "No info available"
	L.RAID_NOT_IN_RAID = "Not in Raid"
	L.RAID_NOT_IN_RAID_DETAILS = "You are not currently in a raid group."
	L.RAID_CREATE_BUTTON = "Create Raid"
	L.GROUP = "Group"
	L.ALL = "All"
	L.UNKNOWN_ERROR = "Unknown error"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Not enough space: %d players selected, %d free slots in Group %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Moved %d players to Group %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Failed to move %d players"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "You must be the raid leader or assistant to initiate a ready check."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "You have no saved raid instances."
	L.RAID_ERROR_LOAD_RAID_INFO = "Error: Could not load Raid Info frame."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s swapped"
	L.RAID_ERROR_SWAP_FAILED = "Swap failed: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s moved to Group %d"
	L.RAID_ERROR_MOVE_FAILED = "Move failed: %s"
	L.DIALOG_MIGRATE_TEXT = "Migrate friend groups from FriendGroups to BetterFriendlist?\n\nThis will:\n• Create all groups from BNet notes\n• Assign friends to their groups\n• Optionally clean up notes\n\n|cffff0000Warning: This cannot be undone!|r"
	L.DIALOG_MIGRATE_BTN1 = "Migrate & Clean Notes"
	L.DIALOG_MIGRATE_BTN2 = "Migrate Only"
	L.DIALOG_MIGRATE_BTN3 = "Cancel"
	
	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "General"
	L.SETTINGS_TAB_GROUPS = "Groups"
	L.SETTINGS_TAB_APPEARANCE = "Appearance"
	L.SETTINGS_TAB_ADVANCED = "Advanced"
	L.SETTINGS_TAB_STATISTICS = "Statistics"
	L.SETTINGS_SHOW_BLIZZARD = "Show Blizzard's Friends List Option"
	L.SETTINGS_COMPACT_MODE = "Compact Mode"
	L.SETTINGS_FONT_SIZE = "Font Size"
	L.SETTINGS_FONT_SIZE_SMALL = "Small (Compact, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normal (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Large (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Color Class Names"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Hide Empty Groups"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Group Header Counts"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Choose how friend counts are displayed in group headers"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Filtered / Total (Default)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "Online / Total"
	L.SETTINGS_HEADER_COUNT_BOTH = "Filtered (Online) / Total"
	L.SETTINGS_SHOW_FACTION_ICONS = "Show Faction Icons"
	L.SETTINGS_SHOW_REALM_NAME = "Show Realm Name"
	L.SETTINGS_GRAY_OTHER_FACTION = "Gray Out Other Faction"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Show Mobile as AFK"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Show Mobile Text"
	L.SETTINGS_HIDE_MAX_LEVEL = "Hide Max Level"
	L.SETTINGS_ACCORDION_GROUPS = "Accordion Groups (one open at a time)"
	L.SETTINGS_SHOW_FAVORITES = "Show Favorites Group"
	L.SETTINGS_GROUP_COLOR = "Group Color"
	L.SETTINGS_RENAME_GROUP = "Rename Group"
	L.SETTINGS_DELETE_GROUP = "Delete Group"
	L.SETTINGS_DELETE_GROUP_DESC = "Remove this group and unassign all friends"
	L.SETTINGS_EXPORT_TITLE = "Export Settings"
	L.SETTINGS_EXPORT_INFO = "Copy the text below and save it. You can import it on another character or account."
	L.SETTINGS_EXPORT_BTN = "Select All"
	L.SETTINGS_IMPORT_TITLE = "Import Settings"
	L.SETTINGS_IMPORT_INFO = "Paste your export string below and click Import.\n\n|cffff0000Warning: This will replace ALL your groups and assignments!|r"
	L.SETTINGS_IMPORT_BTN = "Import"
	L.SETTINGS_IMPORT_CANCEL = "Cancel"
	L.SETTINGS_RESET_DEFAULT = "Reset to Defaults"
	L.SETTINGS_RESET_SUCCESS = "Settings reset to defaults!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Group order saved!"
	L.SETTINGS_MIGRATION_COMPLETE = "Migration Complete!"
	L.SETTINGS_MIGRATION_FRIENDS = "Friends processed:"
	L.SETTINGS_MIGRATION_GROUPS = "Groups created:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Assignments made:"
	L.SETTINGS_NOTES_CLEANED = "Notes cleaned up!"
	L.SETTINGS_NOTES_PRESERVED = "Notes preserved (you can clean them manually)."
	L.SETTINGS_EXPORT_SUCCESS = "Export complete! Copy the text from the dialog."
	L.SETTINGS_IMPORT_SUCCESS = "Import successful! All groups and assignments have been restored."
	L.SETTINGS_IMPORT_FAILED = "Import Failed!\n\n"
	L.STATS_TOTAL_FRIENDS = "Total Friends: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00Online: %d|r  |  |cff808080Offline: %d|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"
	
	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Friend Requests (%d)"
	L.INVITE_BUTTON_ACCEPT = "Accept"
	L.INVITE_BUTTON_DECLINE = "Decline"
	L.INVITE_TAP_TEXT = "Tap to accept or decline"
	L.INVITE_MENU_DECLINE = "Decline"
	L.INVITE_MENU_REPORT = "Report Player"
	L.INVITE_MENU_BLOCK = "Block Invites"
	
	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "All Friends"
	L.FILTER_ONLINE_ONLY = "Online Only"
	L.FILTER_OFFLINE_ONLY = "Offline Only"
	L.FILTER_WOW_ONLY = "WoW Only"
	L.FILTER_BNET_ONLY = "Battle.net Only"
	L.FILTER_HIDE_AFK = "Hide AFK/DND"
	L.FILTER_RETAIL_ONLY = "Retail Only"
	L.FILTER_TOOLTIP = "Quick Filter: %s"
	L.SORT_STATUS = "Status"
	L.SORT_NAME = "Name (A-Z)"
	L.SORT_LEVEL = "Level"
	L.SORT_ZONE = "Zone"
	L.SORT_ACTIVITY = "Recent Activity"
	L.SORT_GAME = "Game"
	L.SORT_FACTION = "Faction"
	L.SORT_GUILD = "Guild"
	L.SORT_CLASS = "Class"
	L.SORT_REALM = "Realm"
	L.SORT_CHANGED = "Sort changed to: %s"
	
	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Groups"
	L.MENU_CREATE_GROUP = "Create Group"
	L.MENU_REMOVE_ALL_GROUPS = "Remove from All Groups"
	L.MENU_RENAME_GROUP = "Rename Group"
	L.MENU_DELETE_GROUP = "Delete Group"
	L.MENU_INVITE_GROUP = "Invite All to Party"
	L.MENU_COLLAPSE_ALL = "Collapse All Groups"
	L.MENU_EXPAND_ALL = "Expand All Groups"
	L.MENU_SETTINGS = "Settings"
	L.MENU_SET_BROADCAST = "Set Broadcast Message"
	L.MENU_IGNORE_LIST = "Manage Ignore List"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	
	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Drop to add to group"
	L.TOOLTIP_HOLD_SHIFT = "Hold Shift to keep in other groups"
	L.TOOLTIP_DRAG_HERE = "Drag friends here to add them"
	L.TOOLTIP_ERROR = "Error"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "No game accounts available"
	L.TOOLTIP_NO_INFO = "Not enough information available"
	L.TOOLTIP_RENAME_GROUP = "Rename Group"
	L.TOOLTIP_RENAME_DESC = "Click to rename this group"
	L.TOOLTIP_GROUP_COLOR = "Group Color"
	L.TOOLTIP_GROUP_COLOR_DESC = "Click to change the color of this group"
	L.TOOLTIP_DELETE_GROUP = "Delete Group"
	L.TOOLTIP_DELETE_DESC = "Remove this group and unassign all friends"
	
	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "Invited %d friend(s) to party."
	L.MSG_NO_FRIENDS_AVAILABLE = "No online friends available to invite."
	L.MSG_GROUP_DELETED = "Group '%s' deleted"
	L.MSG_IGNORE_LIST_EMPTY = "Your ignore list is empty."
	L.MSG_IGNORE_LIST_COUNT = "Ignore List (%d players):"
	L.MSG_MIGRATION_ALREADY_DONE = "Migration already completed. Use '/bfl migrate force' to re-run."
	L.MSG_MIGRATION_STARTING = "Starting FriendGroups migration..."
	L.MSG_GROUP_ORDER_SAVED = "Group order saved!"
	L.MSG_SETTINGS_RESET = "Settings reset to defaults!"
	L.MSG_EXPORT_FAILED = "Export failed: %s"
	L.MSG_IMPORT_SUCCESS = "Import successful! All groups and assignments have been restored."
	L.MSG_IMPORT_FAILED = "Import failed: %s"
	
	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "Database not available!"
	L.ERROR_SETTINGS_NOT_INIT = "Frame not initialized!"
	L.ERROR_MODULES_NOT_LOADED = "Modules not available!"
	L.ERROR_GROUPS_MODULE = "Groups module not available!"
	L.ERROR_SETTINGS_MODULE = "Settings module not available!"
	L.ERROR_FRIENDSLIST_MODULE = "FriendsList module not available"
	L.ERROR_FAILED_DELETE_GROUP = "Failed to delete group - modules not loaded"
	L.ERROR_FAILED_DELETE = "Failed to delete group: %s"
	L.ERROR_MIGRATION_FAILED = "Migration failed - modules not loaded!"
	L.ERROR_GROUP_NAME_EMPTY = "Group name cannot be empty"
	L.ERROR_GROUP_EXISTS = "Group already exists"
	L.ERROR_INVALID_GROUP_NAME = "Invalid group name"
	L.ERROR_GROUP_NOT_EXIST = "Group does not exist"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Cannot rename built-in groups"
	L.ERROR_INVALID_GROUP_ID = "Invalid group ID"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Cannot delete built-in groups"
	
	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Friends"
	L.GROUP_FAVORITES = "Favorites"
	L.GROUP_NO_GROUP = "No Group"
	L.ONLINE_STATUS = "Online"
	L.OFFLINE_STATUS = "Offline"
	L.MOBILE_STATUS = "Mobile"
	L.BUTTON_ADD_FRIEND = "Add Friend"
	L.BUTTON_SEND_MESSAGE = "Send Message"
	L.EMPTY_TEXT = "Empty"
	L.LEVEL_FORMAT = "Lvl %d"
	
	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Beta Features"
	L.SETTINGS_BETA_FEATURES_DESC = "Enable experimental features that are still in development. These features may change or be removed in future versions."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Enable Beta Features"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Enables experimental features (Notifications, etc.)"
	L.SETTINGS_BETA_FEATURES_WARNING = "Warning: Beta features may contain bugs, performance issues, or incomplete functionality. Use at your own risk."
	L.SETTINGS_BETA_FEATURES_LIST = "Currently available Beta Features:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Beta Features |cff00ff00ENABLED|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Beta Features |cffff0000DISABLED|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Beta tabs are now visible in Settings"
	L.SETTINGS_BETA_TABS_HIDDEN = "Beta tabs are now hidden"
	
	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Enable Global Friend Sync"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Synchronize your WoW friends list across all characters on this account."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Global Friend Sync"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Enable Deletion"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC = "Allow the sync process to remove friends from your list if they are removed from the database."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Synced Friends Database"
	
	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================
	L.SETTINGS_NOTIFICATIONS_TITLE = "Notifications"
	L.SETTINGS_NOTIFICATIONS_DESC = "Configure smart friend notifications. Get alerts when friends come online."
	L.SETTINGS_NOTIFICATIONS_DISPLAY_HEADER = "Notification Display"
	L.SETTINGS_NOTIFICATIONS_DISPLAY_MODE = "Display Mode:"
	L.SETTINGS_NOTIFICATIONS_MODE_TOAST = "Toast Notification"
	L.SETTINGS_NOTIFICATIONS_MODE_CHAT = "Chat Message Only"
	L.SETTINGS_NOTIFICATIONS_MODE_DISABLED = "Disabled"
	L.SETTINGS_NOTIFICATIONS_MODE_DESC = "|cffffcc00Toast Notification:|r Shows a compact notification when friends come online\n|cffffcc00Chat Message Only:|r No popup, only messages in chat\n|cffffcc00Disabled:|r No notifications at all"
	L.SETTINGS_NOTIFICATIONS_TEST_BUTTON = "Test Notification"
	L.SETTINGS_NOTIFICATIONS_SOUND_HEADER = "Sound Settings"
	L.SETTINGS_NOTIFICATIONS_SOUND_ENABLE = "Play sound with notifications"
	L.SETTINGS_NOTIFICATIONS_SOUND_ENABLED = "Notification sounds |cff00ff00ENABLED|r"
	L.SETTINGS_NOTIFICATIONS_SOUND_DISABLED = "Notification sounds |cffff0000DISABLED|r"
	L.SETTINGS_NOTIFICATIONS_COMING_SOON = "Coming Soon"
	L.SETTINGS_NOTIFICATIONS_FUTURE_FEATURES = "• Per-friend notification rules\n• Group triggers (X friends from group Y online)\n• Quiet hours (combat, instance, schedule)\n• Custom notification messages\n• Offline notifications"
	L.SETTINGS_NOTIFICATIONS_QUIET_HOURS = "|cffffcc00Automatic Quiet Hours:|r\n• During combat (no distractions)\n• Future: Instance detection, manual DND, scheduled hours"
	
	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================
	L.NOTIFICATION_MODE_CHANGED = "Notification mode set to %s"
	L.NOTIFICATION_TEST_MESSAGE = "This is a test notification"
	L.NOTIFICATION_FRIEND_ONLINE = "%s is now online"
	L.NOTIFICATION_FRIEND_PLAYING = "%s is now online [playing %s]"
	L.NOTIFICATION_SYSTEM_UNAVAILABLE = "Notification system not available"
	L.NOTIFICATION_BETA_REQUIRED = "Beta Features must be enabled to use notifications"
	L.NOTIFICATION_BETA_ENABLE_HINT = "→ Enable in Settings > Advanced > Beta Features"
	
	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Default Frame Size (Edit Mode)"
	L.SETTINGS_FRAME_SIZE_INFO = "Set your preferred default size for new Edit Mode layouts."
	L.SETTINGS_FRAME_WIDTH = "Width:"
	L.SETTINGS_FRAME_HEIGHT = "Height:"
	L.SETTINGS_FRAME_RESET_SIZE = "Reset to 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Apply to Current Layout"
	L.SETTINGS_FRAME_RESET_ALL = "Reset All Layouts to Default"
	
	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Friends"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Left Click: Toggle BetterFriendlist"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Right Click: Settings"
	L.BROKER_SETTINGS_ENABLE = "Enable Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON = "Show Icon"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Tooltip Detail Level"
	L.BROKER_SETTINGS_CLICK_ACTION = "Left Click Action"
	L.BROKER_SETTINGS_LEFT_CLICK = "Left Click Action"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Right Click Action"
	L.BROKER_ACTION_TOGGLE = "Toggle BetterFriendlist"
	L.BROKER_ACTION_FRIENDS = "Open Friends Frame"
	L.BROKER_ACTION_SETTINGS = "Open Settings"
	L.BROKER_ACTION_OPEN_BNET = "Open Battle.net App"
	L.BROKER_ACTION_NONE = "Do Nothing"
	L.BROKER_SETTINGS_INFO = "BetterFriendlist integrates with Data Broker display addons like Bazooka, ChocolateBar, and TitanPanel. Enable this feature to show friend counts and quick access in your display addon."
	L.BROKER_FILTER_CHANGED = "Filter changed to: %s"
	
	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "WoW Friends"
	L.BROKER_HEADER_BNET = "Battle.Net Friends"
	L.BROKER_NO_WOW_ONLINE = "  No WoW friends online"
	L.BROKER_NO_FRIENDS_ONLINE = "No friends online"
	L.BROKER_TOTAL_ONLINE = "Total: %d online / %d friends"
	L.BROKER_FILTER_LABEL = "Filter: "
	L.BROKER_SORT_LABEL = "Sort: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Friend Line Actions ---"
	L.BROKER_HINT_CLICK_WHISPER = "Click Friend:"
	L.BROKER_HINT_WHISPER = " Whisper • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Right-Click:"
	L.BROKER_HINT_CONTEXT_MENU = " Context Menu"
	L.BROKER_HINT_ALT_CLICK = "Alt+Click:"
	L.BROKER_HINT_INVITE = " Invite/Join • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Click:"
	L.BROKER_HINT_COPY = " Copy to Chat"
	L.BROKER_HINT_ICON_ACTIONS = "--- Broker Icon Actions ---"
	L.BROKER_HINT_LEFT_CLICK = "Left Click:"
	L.BROKER_HINT_TOGGLE = " Toggle BetterFriendlist"
	L.BROKER_HINT_RIGHT_CLICK = "Right Click:"
	L.BROKER_HINT_SETTINGS = " Settings • "
	L.BROKER_HINT_MIDDLE_CLICK = "Middle Click:"
	L.BROKER_HINT_CYCLE_FILTER = " Cycle Filter"
	
	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Treat Mobile as Offline
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Treat Mobile users as Offline"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Display friends using the Mobile App in the Offline group"
	
	-- Feature 3: Show Notes as Name
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Show Notes as Friend Name"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Display friend notes as their name when available"
	
	-- Feature 4: Window Scale
	L.SETTINGS_WINDOW_SCALE = "Window Scale"
	L.SETTINGS_WINDOW_SCALE_DESC = "Scale the entire window (50%% - 200%%)"
	
	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Show Label 'Friends:'"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Show Total Count"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Split WoW and BNet Friend Counts"
	L.BROKER_SETTINGS_HEADER_GENERAL = "General Settings"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Data Broker Integration"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interaction"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "How to Use"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Tested Display Addons"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Install a Data Broker display addon (Bazooka, ChocolateBar, or TitanPanel)\n• Enable Data Broker above (UI reload will be prompted)\n• The BetterFriendlist button will appear in your display addon\n• Hover for tooltip, left-click to open, right-click for settings, middle-click to cycle filters"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Tooltip Columns"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Tooltip Columns"
	L.BROKER_COLUMN_NAME = "Name"
	L.BROKER_COLUMN_LEVEL = "Level"
	L.BROKER_COLUMN_CHARACTER = "Character"
	L.BROKER_COLUMN_GAME = "Game / App"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "Realm"
	L.BROKER_COLUMN_FACTION = "Faction"
	L.BROKER_COLUMN_NOTES = "Notes"
	
	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Display the friend's name (RealID or Character Name)"
	L.BROKER_COLUMN_LEVEL_DESC = "Display the character's level"
	L.BROKER_COLUMN_CHARACTER_DESC = "Display the character name and class icon"
	L.BROKER_COLUMN_GAME_DESC = "Display the game or app the friend is playing"
	L.BROKER_COLUMN_ZONE_DESC = "Display the zone the friend is currently in"
	L.BROKER_COLUMN_REALM_DESC = "Display the realm the character is on"
	L.BROKER_COLUMN_FACTION_DESC = "Display the faction icon (Alliance/Horde)"
	L.BROKER_COLUMN_NOTES_DESC = "Display friend notes"
	
	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Recent Allies is not available in this version."
	L.EDIT_MODE_NOT_AVAILABLE = "Edit Mode is not available in Classic. Use /bfl position to move the frame."
	L.CLASSIC_COMPATIBILITY_INFO = "BetterFriendlist is running in Classic compatibility mode."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "This feature is not available in Classic."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Close BetterFriendlist when opening Guild"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "Automatically close BetterFriendlist when you click the Guild tab"
	L.SETTINGS_HIDE_GUILD_TAB = "Hide Guild Tab"
L.SETTINGS_HIDE_GUILD_TAB_DESC = "Hide the Guild tab from the friends list"
L.SETTINGS_USE_UI_PANEL_SYSTEM = "Respect UI Hierarchy"
L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Prevent BetterFriendlist from opening over other UI windows (Character, Spellbook, etc.). Requires /reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 min"
	L.LASTONLINE_MINUTES = "%d min"
	L.LASTONLINE_HOURS = "%d hr"
	L.LASTONLINE_DAYS = "%d days"
	L.LASTONLINE_MONTHS = "%d months"
	L.LASTONLINE_YEARS = "%d years"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "Classic Guild UI Disabled"
	L.CLASSIC_GUILD_UI_WARNING_TEXT = "BetterFriendlist has disabled the Classic Guild UI setting as only Blizzard's modern Guild UI is compatible with BetterFriendlist.\n\nThe Guild tab now opens Blizzard's modern Guild UI."
end
