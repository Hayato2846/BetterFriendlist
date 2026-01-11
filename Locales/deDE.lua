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
	L.DIALOG_UI_PANEL_RELOAD_TEXT = "Das Ändern der UI-Hierarchie-Einstellung erfordert ein UI-Neuladen.\n\nJetzt neu laden?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Neu laden"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Abbrechen"
	L.RAID_HELP_TITLE = "Schlachtzug-Hilfe"
	L.RAID_HELP_TEXT = "Klicken für Hilfe zur Schlachtzugsliste."
	L.RAID_HELP_MULTISELECT_TITLE = "Mehrfachauswahl"
	L.RAID_HELP_MULTISELECT_TEXT = "Halten Sie Strg und klicken Sie links, um mehrere Spieler auszuwählen.\nZiehen Sie sie dann per Drag & Drop in eine beliebige Gruppe, um alle auf einmal zu verschieben."
	L.RAID_HELP_MAINTANK_TITLE = "Haupttank"
	L.RAID_HELP_MAINTANK_TEXT = "Umschalt + Rechtsklick auf einen Spieler, um ihn als Haupttank festzulegen.\nEin Tank-Symbol erscheint neben seinem Namen."
	L.RAID_HELP_MAINASSIST_TITLE = "Hauptassistent"
	L.RAID_HELP_MAINASSIST_TEXT = "Strg + Rechtsklick auf einen Spieler, um ihn als Hauptassistent festzulegen.\nEin Assistenten-Symbol erscheint neben seinem Namen."
	L.RAID_HELP_DRAGDROP_TITLE = "Ziehen & Ablegen"
	L.RAID_HELP_DRAGDROP_TEXT = "Ziehen Sie einen Spieler, um ihn zwischen Gruppen zu verschieben.\nSie können auch mehrere ausgewählte Spieler auf einmal ziehen.\nLeere Slots können zum Tauschen von Positionen verwendet werden."
	L.RAID_HELP_COMBAT_TITLE = "Kampfsperre"
	L.RAID_HELP_COMBAT_TEXT = "Spieler können während des Kampfes nicht verschoben werden.\nDies ist eine Blizzard-Beschränkung zur Fehlervermeidung."
	L.RAID_INFO_UNAVAILABLE = "Keine Info verfügbar"
	L.RAID_NOT_IN_RAID = "Nicht im Schlachtzug"
	L.RAID_NOT_IN_RAID_DETAILS = "Du bist in keiner Schlachtzugsgruppe."
	L.RAID_CREATE_BUTTON = "Schlachtzug erstellen"
	L.GROUP = "Gruppe"
	L.ALL = "Alle"
	L.UNKNOWN_ERROR = "Unbekannter Fehler"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Nicht genügend Platz: %d Spieler ausgewählt, %d freie Plätze in Gruppe %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "%d Spieler in Gruppe %d verschoben"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Verschieben von %d Spielern fehlgeschlagen"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "Du musst Schlachtzugsleiter oder Assistent sein, um einen Bereitschaftscheck zu starten."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "Du hast keine gespeicherten Schlachtzugsinstanzen."
	L.RAID_ERROR_LOAD_RAID_INFO = "Fehler: Konnte Schlachtzugsinfo-Fenster nicht laden."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s getauscht"
	L.RAID_ERROR_SWAP_FAILED = "Tausch fehlgeschlagen: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s in Gruppe %d verschoben"
	L.RAID_ERROR_MOVE_FAILED = "Verschieben fehlgeschlagen: %s"
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
	L.SETTINGS_HEADER_COUNT_FORMAT = "Gruppenkopf-Zähler"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Wähle, wie Freundeszahlen in Gruppenköpfen angezeigt werden"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Gefiltert / Gesamt (Standard)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "Online / Gesamt"
	L.SETTINGS_HEADER_COUNT_BOTH = "Gefiltert (Online) / Gesamt"
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
	L.SORT_GAME = "Spiel"
	L.SORT_FACTION = "Fraktion"
	L.SORT_GUILD = "Gilde"
	L.SORT_CLASS = "Klasse"
	L.SORT_REALM = "Realm"
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
	
	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Beta-Funktionen"
	L.SETTINGS_BETA_FEATURES_DESC = "Aktiviere experimentelle Funktionen, die sich noch in Entwicklung befinden. Diese Funktionen können sich in zukünftigen Versionen ändern oder entfernt werden."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Beta-Funktionen aktivieren"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Aktiviert experimentelle Funktionen (Benachrichtigungen, etc.)"
	L.SETTINGS_BETA_FEATURES_WARNING = "Warnung: Beta-Funktionen können Bugs, Performance-Probleme oder unvollständige Funktionalität enthalten. Nutzung auf eigenes Risiko."
	L.SETTINGS_BETA_FEATURES_LIST = "Derzeit verfügbare Beta-Funktionen:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Beta-Funktionen |cff00ff00AKTIVIERT|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Beta-Funktionen |cffff0000DEAKTIVIERT|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Beta-Tabs sind nun sichtbar in den Einstellungen"
	L.SETTINGS_BETA_TABS_HIDDEN = "Beta-Tabs sind nun ausgeblendet"
	
	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================
	L.SETTINGS_NOTIFICATIONS_TITLE = "Benachrichtigungen"
	L.SETTINGS_NOTIFICATIONS_DESC = "Konfiguriere intelligente Freunde-Benachrichtigungen. Erhalte Benachrichtigungen, wenn Freunde online kommen."
	L.SETTINGS_NOTIFICATIONS_DISPLAY_HEADER = "Benachrichtigungs-Anzeige"
	L.SETTINGS_NOTIFICATIONS_DISPLAY_MODE = "Anzeigemodus:"
	L.SETTINGS_NOTIFICATIONS_MODE_TOAST = "Toast-Benachrichtigung"
	L.SETTINGS_NOTIFICATIONS_MODE_CHAT = "Nur Chat-Nachricht"
	L.SETTINGS_NOTIFICATIONS_MODE_DISABLED = "Deaktiviert"
	L.SETTINGS_NOTIFICATIONS_MODE_DESC = "|cffffcc00Toast-Benachrichtigung:|r Zeigt eine kompakte Benachrichtigung, wenn Freunde online kommen\n|cffffcc00Nur Chat-Nachricht:|r Kein Popup, nur Nachrichten im Chat\n|cffffcc00Deaktiviert:|r Keine Benachrichtigungen"
	L.SETTINGS_NOTIFICATIONS_TEST_BUTTON = "Benachrichtigung testen"
	L.SETTINGS_NOTIFICATIONS_SOUND_HEADER = "Sound-Einstellungen"
	L.SETTINGS_NOTIFICATIONS_SOUND_ENABLE = "Sound bei Benachrichtigungen abspielen"
	L.SETTINGS_NOTIFICATIONS_SOUND_ENABLED = "Benachrichtigungs-Sounds |cff00ff00AKTIVIERT|r"
	L.SETTINGS_NOTIFICATIONS_SOUND_DISABLED = "Benachrichtigungs-Sounds |cffff0000DEAKTIVIERT|r"
	L.SETTINGS_NOTIFICATIONS_COMING_SOON = "Demnächst verfügbar"
	L.SETTINGS_NOTIFICATIONS_FUTURE_FEATURES = "• Benachrichtigungsregeln pro Freund\n• Gruppen-Trigger (X Freunde aus Gruppe Y online)\n• Ruhezeiten (Kampf, Instanz, Zeitplan)\n• Individuelle Benachrichtigungsnachrichten\n• Offline-Benachrichtigungen"
	L.SETTINGS_NOTIFICATIONS_QUIET_HOURS = "|cffffcc00Automatische Ruhezeiten:|r\n• Während des Kampfes (keine Ablenkung)\n• Zukünftig: Instanz-Erkennung, manueller DND, geplante Zeiten"
	
	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================
	L.NOTIFICATION_MODE_CHANGED = "Benachrichtigungsmodus auf %s gesetzt"
	L.NOTIFICATION_TEST_MESSAGE = "Dies ist eine Test-Benachrichtigung"
	L.NOTIFICATION_FRIEND_ONLINE = "%s ist jetzt online"
	L.NOTIFICATION_FRIEND_PLAYING = "%s ist jetzt online [spielt %s]"
	L.NOTIFICATION_SYSTEM_UNAVAILABLE = "Benachrichtigungssystem nicht verfügbar"
	L.NOTIFICATION_BETA_REQUIRED = "Beta-Funktionen müssen aktiviert sein, um Benachrichtigungen zu nutzen"
	L.NOTIFICATION_BETA_ENABLE_HINT = "→ Aktiviere sie in Einstellungen > Erweitert > Beta-Funktionen"	
	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Standard-Fenstergröße (Bearbeitungsmodus)"
	L.SETTINGS_FRAME_SIZE_INFO = "Legen Sie Ihre bevorzugte Standardgröße für neue Bearbeitungsmodus-Layouts fest."
	L.SETTINGS_FRAME_WIDTH = "Breite:"
	L.SETTINGS_FRAME_HEIGHT = "Höhe:"
	L.SETTINGS_FRAME_RESET_SIZE = "Auf 415x570 zurücksetzen"
	L.SETTINGS_FRAME_APPLY_NOW = "Auf aktuelles Layout anwenden"
	L.SETTINGS_FRAME_RESET_ALL = "Alle Layouts zurücksetzen"
	
	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Freunde"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Linksklick: BetterFriendlist öffnen/schließen"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Rechtsklick: Einstellungen"
	L.BROKER_SETTINGS_ENABLE = "Data Broker aktivieren"
	L.BROKER_SETTINGS_SHOW_ICON = "Icon anzeigen"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Tooltip-Detailstufe"
	L.BROKER_SETTINGS_CLICK_ACTION = "Linksklick-Aktion"
	L.BROKER_ACTION_TOGGLE = "BetterFriendlist umschalten"
	L.BROKER_ACTION_FRIENDS = "Freundesliste öffnen"
	L.BROKER_ACTION_SETTINGS = "Einstellungen öffnen"
	L.BROKER_SETTINGS_INFO = "BetterFriendlist integriert sich in Data Broker Anzeige-Addons wie Bazooka, ChocolateBar und TitanPanel. Aktiviere diese Funktion, um Freundeszahlen und Schnellzugriff in deinem Anzeige-Addon zu sehen."
	L.BROKER_FILTER_CHANGED = "Filter geändert auf: %s"
	
	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "WoW Freunde"
	L.BROKER_HEADER_BNET = "Battle.Net Freunde"
	L.BROKER_NO_WOW_ONLINE = "  Keine WoW-Freunde online"
	L.BROKER_NO_FRIENDS_ONLINE = "Keine Freunde online"
	L.BROKER_TOTAL_ONLINE = "Gesamt: %d online / %d Freunde"
	L.BROKER_FILTER_LABEL = "Filter: "
	L.BROKER_SORT_LABEL = "Sortierung: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Freund-Aktionen ---"
	L.BROKER_HINT_CLICK_WHISPER = "Klick auf Freund:"
	L.BROKER_HINT_WHISPER = " Flüstern • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Rechtsklick:"
	L.BROKER_HINT_CONTEXT_MENU = " Kontextmenü"
	L.BROKER_HINT_ALT_CLICK = "Alt+Klick:"
	L.BROKER_HINT_INVITE = " Einladen/Beitreten • "
	L.BROKER_HINT_SHIFT_CLICK = "Umschalt+Klick:"
	L.BROKER_HINT_COPY = " In Chat kopieren"
	L.BROKER_HINT_ICON_ACTIONS = "--- Broker Icon Aktionen ---"
	L.BROKER_HINT_LEFT_CLICK = "Linksklick:"
	L.BROKER_HINT_TOGGLE = " BetterFriendlist umschalten"
	L.BROKER_HINT_RIGHT_CLICK = "Rechtsklick:"
	L.BROKER_HINT_SETTINGS = " Einstellungen • "
	L.BROKER_HINT_MIDDLE_CLICK = "Mittelklick:"
	L.BROKER_HINT_CYCLE_FILTER = " Filter durchschalten"
	
	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Label 'Freunde:' anzeigen"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Gesamtanzahl anzeigen"
	L.BROKER_SETTINGS_SHOW_GROUPS = "WoW und BNet Zähler trennen"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Allgemeine Einstellungen"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Data Broker Integration"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interaktion"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Anleitung"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Getestete Anzeige-Addons"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Installiere ein Data Broker Anzeige-Addon (Bazooka, ChocolateBar oder TitanPanel)\n• Aktiviere Data Broker oben (UI Reload wird abgefragt)\n• Der BetterFriendlist Button erscheint in deinem Anzeige-Addon\n• Mouseover für Tooltip, Linksklick zum Öffnen, Rechtsklick für Einstellungen, Mittelklick zum Filter wechseln"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Tooltip Spalten"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Tooltip Spalten"
	L.BROKER_COLUMN_NAME = "Name"
	L.BROKER_COLUMN_LEVEL = "Stufe"
	L.BROKER_COLUMN_CHARACTER = "Charakter"
	L.BROKER_COLUMN_GAME = "Spiel / App"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "Realm"
	L.BROKER_COLUMN_FACTION = "Fraktion"
	L.BROKER_COLUMN_NOTES = "Notizen"
	
	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Zeigt den Namen des Freundes (RealID oder Charaktername)"
	L.BROKER_COLUMN_LEVEL_DESC = "Zeigt die Stufe des Charakters"
	L.BROKER_COLUMN_CHARACTER_DESC = "Zeigt den Charakternamen und das Klassensymbol"
	L.BROKER_COLUMN_GAME_DESC = "Zeigt das Spiel oder die App, die der Freund spielt"
	L.BROKER_COLUMN_ZONE_DESC = "Zeigt die Zone, in der sich der Freund befindet"
	L.BROKER_COLUMN_REALM_DESC = "Zeigt den Realm des Charakters"
	L.BROKER_COLUMN_FACTION_DESC = "Zeigt das Fraktionssymbol (Allianz/Horde)"
	L.BROKER_COLUMN_NOTES_DESC = "Zeigt Freundesnotizen an"
	
	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Mobile als Offline behandeln
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Mobile-Nutzer als Offline anzeigen"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Freunde mit Mobile-App in der Offline-Gruppe anzeigen"
	
	-- Feature 3: Notizen als Name anzeigen
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Notizen als Freundesnamen anzeigen"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Zeigt Freundesnotizen als Namen an, wenn vorhanden"
	
	-- Feature 4: Fenster-Skalierung
	L.SETTINGS_WINDOW_SCALE = "Fenster-Skalierung"
	L.SETTINGS_WINDOW_SCALE_DESC = "Skaliert das gesamte Fenster (50%% - 200%%)"
	
	-- ========================================
	-- CLASSIC KOMPATIBILITÄT
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Letzte Verbündete ist in dieser Version nicht verfügbar."
	L.EDIT_MODE_NOT_AVAILABLE = "Der Bearbeitungsmodus ist in Classic nicht verfügbar. Verwende /bfl position um das Fenster zu verschieben."
	L.CLASSIC_COMPATIBILITY_INFO = "BetterFriendlist läuft im Classic-Kompatibilitätsmodus."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Diese Funktion ist in Classic nicht verfügbar."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "BetterFriendlist beim Öffnen der Gilde schließen"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "BetterFriendlist automatisch schließen, wenn du auf den Gilden-Tab klickst"
	L.SETTINGS_HIDE_GUILD_TAB = "Gilden-Tab ausblenden"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "Versteckt den Gilden-Tab aus der Freundesliste"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "UI-Hierarchie respektieren"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Verhindert, dass sich BetterFriendlist über andere UI-Fenster öffnet (Charakter, Zauberbuch, etc.). Erfordert /reload."
	
	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 Min"
	L.LASTONLINE_MINUTES = "%d Min"
	L.LASTONLINE_HOURS = "%d Std"
	L.LASTONLINE_DAYS = "%d Tage"
	L.LASTONLINE_MONTHS = "%d Monate"
	L.LASTONLINE_YEARS = "%d Jahre"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "Klassisches Gildenfenster deaktiviert"
	L.CLASSIC_GUILD_UI_WARNING_TEXT = "BetterFriendlist hat die Klassisches Gildenfenster Einstellung deaktiviert, da nur Blizzards modernes Gildenfenster mit BetterFriendlist kompatibel ist.\n\nDer Gilden-Tab öffnet nun Blizzards modernes Gildenfenster."
	
	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Globalen Freundes-Sync aktivieren"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Synchronisiert Freunde automatisch zwischen verknüpften Realms (z.B. Blackhand <-> Mal'Ganis)."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Globaler Freundes-Sync (Verknüpfte Realms)"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Löschen erlauben"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC = "Erlaubt dem Synchronisierungsprozess, Freunde von deiner Liste zu entfernen, wenn sie aus der Datenbank entfernt wurden."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Synchronisierte Freundes-Datenbank"
end
