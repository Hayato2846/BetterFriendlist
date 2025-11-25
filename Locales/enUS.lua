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
	L.SETTINGS_BETA_FEATURES_WARNING = "⚠ Warning: Beta features may contain bugs, performance issues, or incomplete functionality. Use at your own risk."
	L.SETTINGS_BETA_FEATURES_LIST = "Currently available Beta Features:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Beta Features |cff00ff00ENABLED|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Beta Features |cffff0000DISABLED|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Beta tabs are now visible in Settings"
	L.SETTINGS_BETA_TABS_HIDDEN = "Beta tabs are now hidden"
	
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
end
