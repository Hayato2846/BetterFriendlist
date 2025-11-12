-- Locales/deDE.lua
-- German (Deutsch) Localization

local L = BFL_LOCALE

if GetLocale() == "deDE" then
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Gib einen Namen für die neue Gruppe ein:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Erstellen"
	L.DIALOG_CREATE_GROUP_BTN2 = "Abbrechen"
	L.DIALOG_RENAME_GROUP_TEXT = "Gib einen neuen Namen für die Gruppe ein:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Umbenennen"
	L.DIALOG_RENAME_GROUP_BTN2 = "Abbrechen"
	L.DIALOG_DELETE_GROUP_TEXT = "Möchtest du diese Gruppe wirklich löschen?\n\n|cffff0000Alle Freunde werden aus dieser Gruppe entfernt.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Löschen"
	L.DIALOG_DELETE_GROUP_BTN2 = "Abbrechen"
	L.DIALOG_DELETE_GROUP_SETTINGS = "Gruppe '%s' löschen?\n\nAlle Freunde werden aus dieser Gruppe entfernt."
	L.DIALOG_RESET_SETTINGS_TEXT = "Alle Einstellungen auf Standard zurücksetzen?"
	L.DIALOG_RESET_BTN1 = "Zurücksetzen"
	L.DIALOG_RESET_BTN2 = "Abbrechen"
	L.DIALOG_MIGRATE_TEXT = "Freundesgruppen von FriendGroups zu BetterFriendlist migrieren?\n\nDies wird:\n• Alle Gruppen aus BNet-Notizen erstellen\n• Freunde ihren Gruppen zuweisen\n• Optional Notizen aufräumen\n\n|cffff0000Warnung: Dies kann nicht rückgängig gemacht werden!|r"
	L.DIALOG_MIGRATE_BTN1 = "Migrieren & Notizen aufräumen"
	L.DIALOG_MIGRATE_BTN2 = "Nur Migrieren"
	L.DIALOG_MIGRATE_BTN3 = "Abbrechen"
	
	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "Allgemein"
	L.SETTINGS_TAB_GROUPS = "Gruppen"
	L.SETTINGS_TAB_APPEARANCE = "Aussehen"
	L.SETTINGS_TAB_ADVANCED = "Erweitert"
	L.SETTINGS_TAB_STATISTICS = "Statistiken"
	L.SETTINGS_SHOW_BLIZZARD = "Blizzards Freundeslisten-Option anzeigen"
	L.SETTINGS_COMPACT_MODE = "Kompakt-Modus"
	L.SETTINGS_FONT_SIZE = "Schriftgröße"
	L.SETTINGS_FONT_SIZE_SMALL = "Klein (Kompakt, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normal (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Groß (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Klassennamen färben"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Leere Gruppen ausblenden"
	L.SETTINGS_SHOW_FACTION_ICONS = "Fraktions-Symbole anzeigen"
	L.SETTINGS_SHOW_REALM_NAME = "Realm-Namen anzeigen"
	L.SETTINGS_GRAY_OTHER_FACTION = "Andere Fraktion ausgrauen"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Mobil als AFK anzeigen"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Mobil-Text anzeigen"
	L.SETTINGS_HIDE_MAX_LEVEL = "Max-Level ausblenden"
	L.SETTINGS_ACCORDION_GROUPS = "Akkordeon-Gruppen (nur eine offen)"
	L.SETTINGS_SHOW_FAVORITES = "Favoriten-Gruppe anzeigen"
	L.SETTINGS_GROUP_COLOR = "Gruppenfarbe"
	L.SETTINGS_RENAME_GROUP = "Gruppe umbenennen"
	L.SETTINGS_DELETE_GROUP = "Gruppe löschen"
	L.SETTINGS_DELETE_GROUP_DESC = "Entfernt diese Gruppe und hebt alle Zuweisungen auf"
	L.SETTINGS_EXPORT_TITLE = "Einstellungen exportieren"
	L.SETTINGS_EXPORT_INFO = "Kopiere den Text unten und speichere ihn. Du kannst ihn auf einem anderen Charakter oder Account importieren."
	L.SETTINGS_EXPORT_BTN = "Alles auswählen"
	L.SETTINGS_IMPORT_TITLE = "Einstellungen importieren"
	L.SETTINGS_IMPORT_INFO = "Füge deinen Export-String unten ein und klicke auf Importieren.\n\n|cffff0000Warnung: Dies ersetzt ALLE deine Gruppen und Zuweisungen!|r"
	L.SETTINGS_IMPORT_BTN = "Importieren"
	L.SETTINGS_IMPORT_CANCEL = "Abbrechen"
	L.SETTINGS_RESET_DEFAULT = "Auf Standard zurücksetzen"
	L.SETTINGS_RESET_SUCCESS = "Einstellungen auf Standard zurückgesetzt!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Gruppenreihenfolge gespeichert!"
	L.SETTINGS_MIGRATION_COMPLETE = "Migration abgeschlossen!"
	L.SETTINGS_MIGRATION_FRIENDS = "Freunde verarbeitet:"
	L.SETTINGS_MIGRATION_GROUPS = "Gruppen erstellt:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Zuweisungen erstellt:"
	L.SETTINGS_NOTES_CLEANED = "Notizen aufgeräumt!"
	L.SETTINGS_NOTES_PRESERVED = "Notizen behalten (du kannst sie manuell aufräumen)."
	L.SETTINGS_EXPORT_SUCCESS = "Export abgeschlossen! Kopiere den Text aus dem Dialog."
	L.SETTINGS_IMPORT_SUCCESS = "Import erfolgreich! Alle Gruppen und Zuweisungen wurden wiederhergestellt."
	L.SETTINGS_IMPORT_FAILED = "Import fehlgeschlagen!\n\n"
	L.STATS_TOTAL_FRIENDS = "Freunde gesamt: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00Online: %d|r  |  |cff808080Offline: %d|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"
	
	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Freundesanfragen (%d)"
	L.INVITE_BUTTON_ACCEPT = "Annehmen"
	L.INVITE_BUTTON_DECLINE = "Ablehnen"
	L.INVITE_TAP_TEXT = "Tippe zum Annehmen oder Ablehnen"
	L.INVITE_MENU_DECLINE = "Ablehnen"
	L.INVITE_MENU_REPORT = "Spieler melden"
	L.INVITE_MENU_BLOCK = "Anfragen blockieren"
	
	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Alle Freunde"
	L.FILTER_ONLINE_ONLY = "Nur Online"
	L.FILTER_OFFLINE_ONLY = "Nur Offline"
	L.FILTER_WOW_ONLY = "Nur WoW"
	L.FILTER_BNET_ONLY = "Nur Battle.net"
	L.FILTER_HIDE_AFK = "AFK/DND ausblenden"
	L.FILTER_RETAIL_ONLY = "Nur Retail"
	L.FILTER_TOOLTIP = "Schnellfilter: %s"
	L.SORT_STATUS = "Status"
	L.SORT_NAME = "Name (A-Z)"
	L.SORT_LEVEL = "Stufe"
	L.SORT_ZONE = "Zone"
	L.SORT_ACTIVITY = "Letzte Aktivität"
	L.SORT_CHANGED = "Sortierung geändert auf: %s"
	
	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Gruppen"
	L.MENU_CREATE_GROUP = "Gruppe erstellen"
	L.MENU_REMOVE_ALL_GROUPS = "Aus allen Gruppen entfernen"
	L.MENU_RENAME_GROUP = "Gruppe umbenennen"
	L.MENU_DELETE_GROUP = "Gruppe löschen"
	L.MENU_INVITE_GROUP = "Alle in Gruppe einladen"
	L.MENU_COLLAPSE_ALL = "Alle Gruppen einklappen"
	L.MENU_EXPAND_ALL = "Alle Gruppen ausklappen"
	L.MENU_SETTINGS = "Einstellungen"
	L.MENU_SET_BROADCAST = "Broadcast-Nachricht setzen"
	L.MENU_IGNORE_LIST = "Ignorierliste verwalten"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	
	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Ablegen um zur Gruppe hinzuzufügen"
	L.TOOLTIP_HOLD_SHIFT = "Umschalt halten um in anderen Gruppen zu behalten"
	L.TOOLTIP_DRAG_HERE = "Ziehe Freunde hierher um sie hinzuzufügen"
	L.TOOLTIP_ERROR = "Fehler"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "Keine Spiel-Accounts verfügbar"
	L.TOOLTIP_NO_INFO = "Nicht genügend Informationen verfügbar"
	L.TOOLTIP_RENAME_GROUP = "Gruppe umbenennen"
	L.TOOLTIP_RENAME_DESC = "Klicke um diese Gruppe umzubenennen"
	L.TOOLTIP_GROUP_COLOR = "Gruppenfarbe"
	L.TOOLTIP_GROUP_COLOR_DESC = "Klicke um die Farbe dieser Gruppe zu ändern"
	L.TOOLTIP_DELETE_GROUP = "Gruppe löschen"
	L.TOOLTIP_DELETE_DESC = "Entfernt diese Gruppe und hebt alle Zuweisungen auf"
	
	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d Freund(e) in Gruppe eingeladen."
	L.MSG_NO_FRIENDS_AVAILABLE = "Keine Online-Freunde zum Einladen verfügbar."
	L.MSG_GROUP_DELETED = "Gruppe '%s' gelöscht"
	L.MSG_IGNORE_LIST_EMPTY = "Deine Ignorierliste ist leer."
	L.MSG_IGNORE_LIST_COUNT = "Ignorierliste (%d Spieler):"
	L.MSG_MIGRATION_ALREADY_DONE = "Migration bereits abgeschlossen. Nutze '/bfl migrate force' zum erneuten Ausführen."
	L.MSG_MIGRATION_STARTING = "Starte FriendGroups-Migration..."
	L.MSG_GROUP_ORDER_SAVED = "Gruppenreihenfolge gespeichert!"
	L.MSG_SETTINGS_RESET = "Einstellungen auf Standard zurückgesetzt!"
	L.MSG_EXPORT_FAILED = "Export fehlgeschlagen: %s"
	L.MSG_IMPORT_SUCCESS = "Import erfolgreich! Alle Gruppen und Zuweisungen wurden wiederhergestellt."
	L.MSG_IMPORT_FAILED = "Import fehlgeschlagen: %s"
	
	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "Datenbank nicht verfügbar!"
	L.ERROR_SETTINGS_NOT_INIT = "Frame nicht initialisiert!"
	L.ERROR_MODULES_NOT_LOADED = "Module nicht verfügbar!"
	L.ERROR_GROUPS_MODULE = "Gruppen-Modul nicht verfügbar!"
	L.ERROR_SETTINGS_MODULE = "Einstellungs-Modul nicht verfügbar!"
	L.ERROR_FRIENDSLIST_MODULE = "Freundeslisten-Modul nicht verfügbar"
	L.ERROR_FAILED_DELETE_GROUP = "Gruppe konnte nicht gelöscht werden - Module nicht geladen"
	L.ERROR_FAILED_DELETE = "Gruppe konnte nicht gelöscht werden: %s"
	L.ERROR_MIGRATION_FAILED = "Migration fehlgeschlagen - Module nicht geladen!"
	L.ERROR_GROUP_NAME_EMPTY = "Gruppenname darf nicht leer sein"
	L.ERROR_GROUP_EXISTS = "Gruppe existiert bereits"
	L.ERROR_INVALID_GROUP_NAME = "Ungültiger Gruppenname"
	L.ERROR_GROUP_NOT_EXIST = "Gruppe existiert nicht"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Integrierte Gruppen können nicht umbenannt werden"
	L.ERROR_INVALID_GROUP_ID = "Ungültige Gruppen-ID"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Integrierte Gruppen können nicht gelöscht werden"
	
	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Freunde"
	L.GROUP_FAVORITES = "Favoriten"
	L.GROUP_NO_GROUP = "Keine Gruppe"
	L.ONLINE_STATUS = "Online"
	L.OFFLINE_STATUS = "Offline"
	L.MOBILE_STATUS = "Mobil"
	L.BUTTON_ADD_FRIEND = "Freund hinzufügen"
	L.BUTTON_SEND_MESSAGE = "Nachricht senden"
	L.EMPTY_TEXT = "Leer"
	L.LEVEL_FORMAT = "Stufe %d"
end
