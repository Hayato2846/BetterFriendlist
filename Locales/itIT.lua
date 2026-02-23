-- Locales/itIT.lua
-- Italian Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("itIT", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"Disabilita il ritratto del giocatore, nasconde le opzioni di ricerca/ordinamento, allarga il frame e sposta le schede per un layout compatto."
	L.MENU_CHANGELOG = "Registro Modifiche"
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Inserisci un nome per il nuovo gruppo:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Crea"
	L.DIALOG_CREATE_GROUP_BTN2 = "Annulla"
	L.DIALOG_RENAME_GROUP_TEXT = "Inserisci un nuovo nome per il gruppo:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Rinomina"
	L.DIALOG_RENAME_GROUP_BTN2 = "Annulla"
	L.DIALOG_RENAME_GROUP_SETTINGS = "Rinomina gruppo '%s':"
	L.DIALOG_DELETE_GROUP_TEXT =
		"Sei sicuro di voler eliminare questo gruppo?\n\n|cffff0000Questo rimuoverà tutti gli amici da questo gruppo.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Elimina"
	L.DIALOG_DELETE_GROUP_BTN2 = "Annulla"
	L.DIALOG_DELETE_GROUP_SETTINGS = "Eliminare gruppo '%s'?\n\nTutti gli amici verranno rimossi da questo gruppo."
	L.DIALOG_RESET_SETTINGS_TEXT = "Ripristinare tutte le impostazioni ai valori predefiniti?"
	L.DIALOG_RESET_BTN1 = "Ripristina"
	L.DIALOG_RESET_BTN2 = "Annulla"
	L.DIALOG_UI_PANEL_RELOAD_TEXT = "Modificare la gerarchia UI richiede un ricaricamento.\n\nRicaricare ora?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Ricarica"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Annulla"
	L.MSG_RELOAD_REQUIRED = "È necessario ricaricare per applicare correttamente questa modifica in Classic."
	L.MSG_RELOAD_NOW = "Ricaricare l'UI ora?"
	L.RAID_HELP_TITLE = "Aiuto Elenco Incursione"
	L.RAID_HELP_TEXT = "Clicca per aiuto sull'uso dell'elenco incursione."
	L.RAID_HELP_MULTISELECT_TITLE = "Selezione Multipla"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Tieni premuto Ctrl e clicca col sinistro per selezionare più giocatori.\nUna volta selezionati, trascinali in qualsiasi gruppo per spostarli insieme."
	L.RAID_HELP_MAINTANK_TITLE = "Difensore Principale"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s su un giocatore per impostarlo come Difensore Principale.\nUn'icona scudo apparirà accanto al nome."
	L.RAID_HELP_MAINASSIST_TITLE = "Assistente Principale"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s su un giocatore per impostarlo come Assistente Principale.\nUn'icona spada apparirà accanto al nome."
	L.RAID_HELP_LEAD_TITLE = "Capo Incursione"
	L.RAID_HELP_LEAD_TEXT = "%s su un giocatore per promuoverlo a Capo Incursione."
	L.RAID_HELP_PROMOTE_TITLE = "Assistente"
	L.RAID_HELP_PROMOTE_TEXT = "%s su un giocatore per promuovere/degradare come Assistente."
	L.RAID_HELP_DRAGDROP_TITLE = "Trascina e Rilascia"
	L.RAID_HELP_DRAGDROP_TEXT =
		"Trascina qualsiasi giocatore per spostarlo tra i gruppi.\nPuoi anche trascinare più giocatori selezionati.\nGli slot vuoti possono essere usati per scambiare posizioni."
	L.RAID_HELP_COMBAT_TITLE = "Blocco in Combattimento"
	L.RAID_HELP_COMBAT_TEXT =
		"I giocatori non possono essere spostati durante il combattimento.\nQuesta è una restrizione Blizzard."
	L.RAID_INFO_UNAVAILABLE = "Info non disponibile"
	L.RAID_NOT_IN_RAID = "Non in incursione"
	L.RAID_NOT_IN_RAID_DETAILS = "Non sei attualmente in un gruppo di incursione"
	L.RAID_CREATE_BUTTON = "Crea Incursione"
	L.GROUP = "Gruppo"
	L.ALL = "Tutti"
	L.UNKNOWN_ERROR = "Errore sconosciuto"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Spazio insufficiente: %d giocatori selezionati, %d posti liberi nel Gruppo %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Spostati %d giocatori nel Gruppo %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Spostamento fallito per %d giocatori"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "Devi essere capo incursione o assistente per l'appello."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "Nessuna istanza salvata."
	L.RAID_ERROR_LOAD_RAID_INFO = "Errore: Impossibile caricare Info Incursione."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s scambiati"
	L.RAID_ERROR_SWAP_FAILED = "Scambio fallito: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s spostato nel Gruppo %d"
	L.RAID_ERROR_MOVE_FAILED = "Spostamento fallito: %s"
	L.DIALOG_MIGRATE_TEXT =
		"Migrare gruppi da FriendGroups a BetterFriendlist?\n\nQuesto:\n• Creerà gruppi dalle note BNet\n• Assegnerà amici ai gruppi\n• Opzionalmente aprirà la Procedura Guidata per verificare e pulire le note\n\n|cffff0000Attenzione: Non si può annullare!|r"
	L.DIALOG_MIGRATE_BTN1 = "Migra e Verifica Note"
	L.DIALOG_MIGRATE_BTN2 = "Solo Migra"
	L.DIALOG_MIGRATE_BTN3 = "Annulla"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "Generale"
	L.SETTINGS_TAB_FONTS = "Font"
	L.SETTINGS_TAB_GROUPS = "Gruppi"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Eredita colore dal gruppo"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Eredita colore dal gruppo"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clic destro per ereditare dal gruppo"
	L.SETTINGS_INHERIT_TOOLTIP = "(Ereditato dal gruppo)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "Aspetto"
	L.SETTINGS_TAB_ADVANCED = "Avanzate"
	L.SETTINGS_ADVANCED_DESC = "Opzioni avanzate e strumenti"
	L.SETTINGS_TAB_STATISTICS = "Statistiche"
	L.SETTINGS_SHOW_BLIZZARD = "Mostra opzione Elenco Amici Blizzard"
	L.SETTINGS_COMPACT_MODE = "Modalità Compatta"
	L.SETTINGS_LOCK_WINDOW = "Blocca finestra"
	L.SETTINGS_LOCK_WINDOW_DESC = "Blocca la finestra per evitare spostamenti accidentali."
	L.SETTINGS_FONT_SIZE = "Dimensione Carattere"
	L.SETTINGS_FONT_COLOR = "Colore carattere"
	L.SETTINGS_FONT_SIZE_SMALL = "Piccolo (Compatto, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normale (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Grande (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Colora Nomi Classe"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Nascondi Gruppi Vuoti"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Contatore Intestazione"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Scegli come mostrare i contatori amici"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Filtrati / Totale (Default)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "Online / Totale"
	L.SETTINGS_HEADER_COUNT_BOTH = "Filtrati / Online / Totale"
	L.SETTINGS_SHOW_FACTION_ICONS = "Mostra Icone Fazione"
	L.SETTINGS_SHOW_REALM_NAME = "Mostra Nome Reame"
	L.SETTINGS_GRAY_OTHER_FACTION = "Grigio Altra Fazione"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Mostra Mobile come Assente (AFK)"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Mostra Testo Mobile"
	L.SETTINGS_HIDE_MAX_LEVEL = "Nascondi Livello Max"
	L.SETTINGS_ACCORDION_GROUPS = "Gruppi a Fisarmonica (uno aperto alla volta)"
	L.SETTINGS_SHOW_FAVORITES = "Mostra Gruppo Preferiti"
	L.SETTINGS_SHOW_GROUP_FMT = "Mostra gruppo %s"
	L.SETTINGS_SHOW_GROUP_DESC_FMT = "Mostra o nasconde il gruppo %s nella lista amici"
	L.SETTINGS_GROUP_COLOR = "Colore Gruppo"
	L.SETTINGS_RENAME_GROUP = "Rinomina Gruppo"
	L.SETTINGS_DELETE_GROUP = "Elimina Gruppo"
	L.SETTINGS_DELETE_GROUP_DESC = "Elimina questo gruppo e rimuove tutti gli amici"
	L.SETTINGS_EXPORT_TITLE = "Esporta Configurazione"
	L.SETTINGS_EXPORT_INFO = "Copia il testo qui sotto e salvalo."
	L.SETTINGS_EXPORT_BTN = "Seleziona Tutto"
	L.BUTTON_EXPORT = "Esporta"
	L.SETTINGS_IMPORT_TITLE = "Importa Configurazione"
	L.SETTINGS_IMPORT_INFO =
		"Incolla la stringa di esportazione e clicca Importa.\n\n|cffff0000Attenzione: Sovrascriverà TUTTI i gruppi!|r"
	L.SETTINGS_IMPORT_BTN = "Importa"
	L.SETTINGS_IMPORT_CANCEL = "Annulla"
	L.SETTINGS_RESET_DEFAULT = "Ripristina Default"
	L.SETTINGS_RESET_SUCCESS = "Impostazioni ripristinate!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Ordine gruppi salvato!"
	L.SETTINGS_MIGRATION_COMPLETE = "Migrazione Completata!"
	L.SETTINGS_MIGRATION_FRIENDS = "Amici processati:"
	L.SETTINGS_MIGRATION_GROUPS = "Gruppi creati:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Assegnazioni:"
	L.SETTINGS_NOTES_CLEANED = "Note pulite!"
	L.SETTINGS_NOTES_PRESERVED = "Note preservate."
	L.SETTINGS_EXPORT_SUCCESS = "Esportazione completata!"
	L.SETTINGS_IMPORT_SUCCESS = "Importazione riuscita!"
	L.SETTINGS_IMPORT_FAILED = "Errore Importazione!\n\n"
	L.STATS_TOTAL_FRIENDS = "Totale Amici: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00Online: %d (%d%%)|r  |  |cff808080Offline: %d (%d%%)|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Richieste Amicizia (%d)"
	L.INVITE_BUTTON_ACCEPT = "Accetta"
	L.INVITE_BUTTON_DECLINE = "Rifiuta"
	L.INVITE_TAP_TEXT = "Tocca per accettare o rifiutare"
	L.INVITE_MENU_DECLINE = "Rifiuta"
	L.INVITE_MENU_REPORT = "Segnala Giocatore"
	L.INVITE_MENU_BLOCK = "Blocca Inviti"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Tutti gli Amici"
	L.FILTER_ONLINE_ONLY = "Solo Online"
	L.FILTER_OFFLINE_ONLY = "Solo Offline"
	L.FILTER_WOW_ONLY = "Solo WoW"
	L.FILTER_BNET_ONLY = "Solo Battle.net"
	L.FILTER_HIDE_AFK = "Nascondi AFK/DND"
	L.FILTER_RETAIL_ONLY = "Solo Retail"
	L.FILTER_TOOLTIP = "Filtro Rapido: %s"
	L.SORT_STATUS = "Stato"
	L.SORT_NAME = "Nome (A-Z)"
	L.SORT_LEVEL = "Livello"
	L.SORT_ZONE = "Zona"
	L.SORT_GAME = "Gioco"
	L.SORT_FACTION = "Fazione"
	L.SORT_GUILD = "Gilda"
	L.SORT_CLASS = "Classe"
	L.SORT_REALM = "Reame"
	L.SORT_CHANGED = "Ordinamento: %s"
	L.SORT_NONE = "Nessuno"
	L.SORT_PRIMARY_LABEL = "Primary Sort"
	L.SORT_SECONDARY_LABEL = "Secondary Sort"
	L.SORT_PRIMARY_DESC = "Scegli come ordinare la lista amici."
	L.SORT_SECONDARY_DESC = "Ordina per questo quando i valori primari sono uguali."

	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Gruppi"
	L.MENU_CREATE_GROUP = "Crea Gruppo"
	L.MENU_REMOVE_ALL_GROUPS = "Rimuovi da Tutti i Gruppi"
	L.MENU_REMOVE_RECENTLY_ADDED = "Rimuovi da Aggiunti di recente"
	L.MENU_CLEAR_ALL_RECENTLY_ADDED = "Cancella tutti gli aggiunti di recente"
	L.MENU_ADD_ALL_TO_GROUP = "Aggiungi tutti al gruppo"
	L.MENU_RENAME_GROUP = "Rinomina Gruppo"
	L.MENU_DELETE_GROUP = "Elimina Gruppo"
	L.MENU_INVITE_GROUP = "Invita Tutto il Gruppo"
	L.MENU_COLLAPSE_ALL = "Comprimi Tutti"
	L.MENU_EXPAND_ALL = "Espandi Tutti"
	L.MENU_SETTINGS = "Impostazioni"
	L.MENU_SET_BROADCAST = "Imposta Messaggio Diffusione"
	L.MENU_IGNORE_LIST = "Gestisci Ignorati"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "Altri gruppi..."
	L.MENU_SWITCH_GAME_ACCOUNT = "Cambia account di gioco"
	L.MENU_DEFAULT_FOCUS = "Predefinito (Blizzard)"
	L.GROUPS_DIALOG_TITLE = "Gruppi per %s"
	L.MENU_COPY_CHARACTER_NAME = "Copia nome personaggio"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "Copia nome personaggio"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Rilascia per aggiungere al gruppo"
	L.TOOLTIP_HOLD_SHIFT = "Tieni Shift per mantenere in altri gruppi"
	L.TOOLTIP_DRAG_HERE = "Trascina amici qui"
	L.TOOLTIP_ERROR = "Errore"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "Nessun account di gioco"
	L.TOOLTIP_NO_INFO = "Info insufficienti"
	L.TOOLTIP_RENAME_GROUP = "Rinomina Gruppo"
	L.TOOLTIP_RENAME_DESC = "Clicca per rinominare"
	L.TOOLTIP_GROUP_COLOR = "Colore Gruppo"
	L.TOOLTIP_GROUP_COLOR_DESC = "Clicca per cambiare colore"
	L.TOOLTIP_DELETE_GROUP = "Elimina Gruppo"
	L.TOOLTIP_DELETE_DESC = "Elimina gruppo e amici"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d amico/i invitato/i."
	L.MSG_NO_FRIENDS_AVAILABLE = "Nessun amico online da invitare."
	L.MSG_INVITE_CONVERT_RAID = "Conversione del gruppo in incursione..."
	L.MSG_INVITE_RAID_FULL = "Incursione piena (%d/40). Inviti interrotti."
	L.MSG_GROUP_DELETED = "Gruppo '%s' eliminato"
	L.MSG_IGNORE_LIST_EMPTY = "Lista ignorati vuota."
	L.MSG_IGNORE_LIST_COUNT = "Lista Ignorati (%d giocatori):"
	L.MSG_MIGRATION_ALREADY_DONE = "Migrazione già fatta. Usa '/bfl migrate force'."
	L.MSG_MIGRATION_STARTING = "Avvio migrazione..."
	L.MSG_GROUP_ORDER_SAVED = "Ordine salvato!"
	L.MSG_SETTINGS_RESET = "Impostazioni ripristinate!"
	L.MSG_EXPORT_FAILED = "Export fallito: %s"
	L.MSG_IMPORT_SUCCESS = "Import riuscito!"
	L.MSG_IMPORT_FAILED = "Import fallito: %s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "Database non disponibile!"
	L.ERROR_SETTINGS_NOT_INIT = "Frame non inizializzato!"
	L.ERROR_MODULES_NOT_LOADED = "Moduli non caricati!"
	L.ERROR_GROUPS_MODULE = "Modulo Gruppi non disponibile!"
	L.ERROR_SETTINGS_MODULE = "Modulo Impostazioni non disponibile!"
	L.ERROR_FRIENDSLIST_MODULE = "Modulo FriendList non disponibile"
	L.ERROR_FAILED_DELETE_GROUP = "Fallimento eliminazione gruppo"
	L.ERROR_FAILED_DELETE = "Eliminazione fallita: %s"
	L.ERROR_MIGRATION_FAILED = "Migrazione fallita!"
	L.ERROR_GROUP_NAME_EMPTY = "Nome gruppo vuoto"
	L.ERROR_GROUP_EXISTS = "Gruppo esistente"
	L.ERROR_INVALID_GROUP_NAME = "Nome invalido"
	L.ERROR_GROUP_NOT_EXIST = "Gruppo non esiste"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Impossibile rinominare gruppi base"
	L.ERROR_INVALID_GROUP_ID = "ID gruppo invalido"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Impossibile eliminare gruppi base"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Amici"
	L.GROUP_FAVORITES = "Preferiti"
	L.GROUP_INGAME = "In Gioco"
	L.GROUP_NO_GROUP = "Nessun Gruppo"
	L.GROUP_RECENTLY_ADDED = "Aggiunti di recente"
	L.ONLINE_STATUS = "Online"
	L.OFFLINE_STATUS = "Offline"
	L.STATUS_MOBILE = "Mobile"
	L.STATUS_IN_APP = "In App"
	L.UNKNOWN_GAME = "Gioco Sconosciuto"
	L.BUTTON_ADD_FRIEND = "Aggiungi Amico"
	L.BUTTON_SEND_MESSAGE = "Invia Messaggio"
	L.EMPTY_TEXT = "Vuoto"
	L.LEVEL_FORMAT = "Liv %d"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Funzioni Beta"
	L.SETTINGS_BETA_FEATURES_DESC = "Abilita funzioni sperimentali."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Abilita Beta"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Abilita funzioni sperimentali"
	L.SETTINGS_BETA_FEATURES_WARNING = "Attenzione: Possibili bug."
	L.SETTINGS_BETA_FEATURES_LIST = "Funzioni Beta disponibili:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Funzioni Beta |cff00ff00ABILITATE|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Funzioni Beta |cffff0000DISABILITATE|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Schede Beta visibili"
	L.SETTINGS_BETA_TABS_HIDDEN = "Schede Beta nascoste"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Abilita Sincronizzazione Globale"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Sincronizza lista amici su tutti i personaggi."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Sincronizzazione Globale"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Abilita Eliminazione"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC = "Consenti eliminazione amici dalla sincronizzazione."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Database Amici Sincronizzato"

	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================

	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================

	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Dimensione Frame (Edit Mode)"
	L.SETTINGS_FRAME_SIZE_INFO = "Dimensione default."
	L.SETTINGS_FRAME_WIDTH = "Larghezza:"
	L.SETTINGS_FRAME_HEIGHT = "Altezza:"
	L.SETTINGS_FRAME_RESET_SIZE = "Reset a 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Applica ora"
	L.SETTINGS_FRAME_RESET_ALL = "Reset tutto"

	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Amici"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Clic Sx: Apri"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Clic Dx: Impostazioni"
	L.BROKER_SETTINGS_ENABLE = "Abilita Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON = "Mostra Icona"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Dettaglio Tooltip"
	L.BROKER_SETTINGS_CLICK_ACTION = "Azione Clic Sx"
	L.BROKER_SETTINGS_LEFT_CLICK = "Azione Clic Sx"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Azione Clic Dx"
	L.BROKER_ACTION_TOGGLE = "Alterna BetterFriendlist"
	L.BROKER_ACTION_FRIENDS = "Apri Lista Amici"
	L.BROKER_ACTION_SETTINGS = "Apri Impostazioni"
	L.BROKER_ACTION_OPEN_BNET = "Apri BNet App"
	L.BROKER_ACTION_NONE = "Niente"
	L.BROKER_SETTINGS_INFO = "Integrazione con Bazooka, TitanPanel, etc."
	L.BROKER_FILTER_CHANGED = "Filtro cambiato: %s"

	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "Amici WoW"
	L.BROKER_HEADER_BNET = "Amici Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Nessun amico WoW online"
	L.BROKER_NO_FRIENDS_ONLINE = "Nessun amico online"
	L.BROKER_TOTAL_ONLINE = "Totale: %d online / %d amici"
	L.BROKER_FILTER_LABEL = "Filtro: "
	L.BROKER_SORT_LABEL = "Ordine: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Azioni Amico ---"
	L.BROKER_HINT_CLICK_WHISPER = "Clic Amico:"
	L.BROKER_HINT_WHISPER = " Sussurra • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Clic-Dx:"
	L.BROKER_HINT_CONTEXT_MENU = " Menu"
	L.BROKER_HINT_ALT_CLICK = "Alt+Clic:"
	L.BROKER_HINT_INVITE = " Invita • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Clic:"
	L.BROKER_HINT_COPY = " Copia"
	L.BROKER_HINT_ICON_ACTIONS = "--- Azioni Icona ---"
	L.BROKER_HINT_LEFT_CLICK = "Clic Sx:"
	L.BROKER_HINT_TOGGLE = " Alterna"
	L.BROKER_HINT_RIGHT_CLICK = "Clic Dx:"
	L.BROKER_HINT_SETTINGS = " Impostazioni • "
	L.BROKER_HINT_MIDDLE_CLICK = "Clic Centro:"
	L.BROKER_HINT_CYCLE_FILTER = " Cambia Filtro"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Treat Mobile as Offline
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Tratta Mobile come Offline"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Mostra amici mobile in gruppo Offline"

	-- Feature 3: Show Notes as Name
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Mostra Note come Nome"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Usa note amico come nome"

	-- Feature 4: Window Scale
	L.SETTINGS_WINDOW_SCALE = "Scala Finestra"
	L.SETTINGS_WINDOW_SCALE_DESC = "Scala interfaccia (50%% - 200%%)"

	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Mostra Etichetta"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Mostra Totale"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Dividi Conteggi"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Config Generale"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Integrazione"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interazione"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Istruzioni"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Testato Con"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Installa addon broker (Bazooka)\n• Abilita Data Broker"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Colonne Tooltip"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Colonne Tooltip"
	L.BROKER_COLUMN_NAME = "Nome"
	L.BROKER_COLUMN_LEVEL = "Livello"
	L.BROKER_COLUMN_CHARACTER = "Personaggio"
	L.BROKER_COLUMN_GAME = "Gioco / App"
	L.BROKER_COLUMN_ZONE = "Zona"
	L.BROKER_COLUMN_REALM = "Reame"
	L.BROKER_COLUMN_FACTION = "Fazione"
	L.BROKER_COLUMN_NOTES = "Note"

	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Mostra nome"
	L.BROKER_COLUMN_LEVEL_DESC = "Mostra livello"
	L.BROKER_COLUMN_CHARACTER_DESC = "Mostra personaggio"
	L.BROKER_COLUMN_GAME_DESC = "Mostra gioco"
	L.BROKER_COLUMN_ZONE_DESC = "Mostra zona"
	L.BROKER_COLUMN_REALM_DESC = "Mostra reame"
	L.BROKER_COLUMN_FACTION_DESC = "Mostra fazione"
	L.BROKER_COLUMN_NOTES_DESC = "Mostra note"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Alleati Recenti non disponibile."
	L.EDIT_MODE_NOT_AVAILABLE = "Edit Mode non disponibile."
	L.CLASSIC_COMPATIBILITY_INFO = "Modalità compatibilità Classic."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Funzione non disponibile in Classic."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Chiudi su Gilda"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "Chiudi lista amici quando apri gilda"
	L.SETTINGS_HIDE_GUILD_TAB = "Nascondi Tab Gilda"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "Nascondi tab gilda dalla lista amici"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "Usa Sistema Pannelli UI"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Evita sovrapposizioni. Richiede reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 min"
	L.LASTONLINE_MINUTES = "%d min"
	L.LASTONLINE_HOURS = "%d h"
	L.LASTONLINE_DAYS = "%d g"
	L.LASTONLINE_MONTHS = "%d mesi"
	L.LASTONLINE_YEARS = "%d anni"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "UI Gilda Classica Disabilitata"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist ha disabilitato l'UI Gilda Classica.\n\nIl tab Gilda aprirà l'interfaccia moderna."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Usa '/bfl migrate help' per aiuto."
	L.LOADED_MESSAGE = "BetterFriendlist caricato."
	L.DEBUG_ENABLED = "Debug ABILITATO"
	L.DEBUG_DISABLED = "Debug DISABILITATO"
	L.CONFIG_RESET = "Impostazioni reset."
	L.SEARCH_PLACEHOLDER = "Cerca..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Gilda"
	L.TAB_RAID = "Incursione"
	L.TAB_QUICK_JOIN = "Unisciti"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Online"
	L.FILTER_SEARCH_OFFLINE = "Offline"
	L.FILTER_SEARCH_MOBILE = "Mobile"
	L.FILTER_SEARCH_AFK = "AFD"
	L.FILTER_SEARCH_DND = "Non disturbare"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "DND"

	-- Groups
	L.MIGRATION_CHECK = "Verifica migrazione..."
	L.MIGRATION_RESULT = "Migrati %d gruppi e %d assegnazioni."
	L.MIGRATION_BNET_UPDATED = "Assegnazioni BNet aggiornate."
	L.MIGRATION_BNET_REASSIGN = "Riassegna amici BNet."
	L.MIGRATION_BNET_REASON = "(Motivo: ID BNet temporanei)"
	L.MIGRATION_WOW_RESULT = "Migrate %d assegnazioni WoW."
	L.MIGRATION_WOW_FORMAT = "(Formato: Personaggio-Reame)"
	L.MIGRATION_WOW_FAIL = "Impossibile migrare (reame mancante)."
	L.MIGRATION_SMART_MIGRATING = "Migrazione: %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Selezione multipla pulita - combattimento"

	-- Quick Join
	L.LEADER_LABEL = "Capo:"
	L.MEMBERS_LABEL = "Membri:"
	L.AVAILABLE_ROLES = "Ruoli Disponibili"
	L.NO_AVAILABLE_ROLES = "Nessun ruolo"
	L.AUTO_ACCEPT_TOOLTIP = "Accettazione auto."
	L.MOCK_JOIN_REQUEST_SENT = "Richiesta prova inviata"
	L.QUICK_JOIN_NO_GROUPS = "Nessun gruppo"
	L.UNKNOWN_GROUP = "Gruppo Sconosciuto"
	L.UNKNOWN = "Sconosciuto"
	L.NO_QUEUE = "No Coda"
	L.LFG_ACTIVITY = "Attività LFG"
	L.ACTIVITY_DUNGEON = "Spedizione"
	L.ACTIVITY_RAID = "Incursione"
	L.ACTIVITY_PVP = "PvP"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "Importa Config"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "Esporta Config"
	L.DIALOG_DELETE_GROUP_TITLE = "Elimina gruppo"
	L.DIALOG_RENAME_GROUP_TITLE = "Rinomina gruppo"
	L.DIALOG_CREATE_GROUP_TITLE = "Crea gruppo"

	-- Tooltips
	L.TOOLTIP_LAST_ONLINE = "Ultimo online: %s"

	-- Notifications
	L.YES = "SÌ"
	L.NO = "NO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Anteprima %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Anteprima posizionamento"
	L.EDITMODE_FRAME_WIDTH = "Larghezza"
	L.EDITMODE_FRAME_HEIGHT = "Altezza"

	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT = "Reset layout?\n\nIrreversibile!"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Reset"
	L.MSG_LAYOUTS_RESET = "Layout resettati."
	L.DIALOG_TRIGGER_TITLE = "Crea Trigger"
	L.DIALOG_TRIGGER_INFO = "Notifica X amici online."
	L.DIALOG_TRIGGER_SELECT_GROUP = "Gruppo:"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Min Amici:"
	L.DIALOG_TRIGGER_CREATE = "Crea"
	L.DIALOG_TRIGGER_CANCEL = "Annulla"
	L.ERROR_SELECT_GROUP = "Seleziona gruppo"
	L.MSG_TRIGGER_CREATED = "Trigger creato: %d+ '%s'"
	L.ERROR_NO_GROUPS = "No gruppi."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Imposta Soprannome %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "Tutti"
	L.FILTER_ONLINE = "Online"
	L.FILTER_OFFLINE = "Offline"
	L.FILTER_WOW = "WoW"
	L.FILTER_BNET = "BNet"
	L.FILTER_HIDE_AFK = "No AFK"
	L.FILTER_RETAIL = "Retail"
	L.TOOLTIP_QUICK_FILTER = "Filtro: %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Ricarica richiesta.\n\nRicaricare?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Ricarica"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Annulla"
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Abilita Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Mostra Icona"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "Icona BFL"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Mostra Etichetta"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Etichetta 'Amici'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Mostra Totale"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Numero totale"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Dividi"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Separa WoW/BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "Icona WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Mostra Icona WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "Icona per amici WoW"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "Icona BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Mostra Icona BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "Icona per amici BNet"
	L.BROKER_SETTINGS_CLICK_ACTION = "Azione Clic"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Mode Tooltip"
	L.STATUS_ENABLED = "|cff00ff00Abilitato|r"
	L.STATUS_DISABLED = "|cffff0000Disabilitato|r"
	L.BROKER_WOW_FRIENDS = "Amici WoW:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Sync Globale"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Abilita sync amici"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Mostra Eliminati"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Mostra Amici Eliminati"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Mostra eliminati nella lista"
	L.TOOLTIP_RESTORE_FRIEND = "Ripristina"
	L.TOOLTIP_DELETE_FRIEND = "Elimina"
	L.POPUP_EDIT_NOTE_TITLE = "Edita Nota"
	L.BUTTON_SAVE = "Salva"
	L.BUTTON_CANCEL = "Annulla"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Amici: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d tot"
	L.BROKER_CURRENT_FILTER = "Filtro:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Clic Centro: Cicla Filtro"
	L.BROKER_AND_MORE = "  ... e %d altri"
	L.BROKER_TOTAL_LABEL = "Totale:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d amici"
	L.MENU_CHANGE_COLOR = "Cambia Colore"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Errore tooltip|r"
	L.STATUS_LABEL = "Stato:"
	L.STATUS_AWAY = "Assente"
	L.STATUS_DND_FULL = "Non Disturbare"
	L.GAME_LABEL = "Gioco:"
	L.REALM_LABEL = "Reame:"
	L.CLASS_LABEL = "Classe:"
	L.FACTION_LABEL = "Fazione:"
	L.ZONE_LABEL = "Zona:"
	L.NOTE_LABEL = "Nota:"
	L.BROADCAST_LABEL = "Messaggio:"
	L.ACTIVE_SINCE_FMT = "(Attivo da: %s)"
	L.HINT_RIGHT_CLICK_OPTIONS = "Clic-dx opzioni"
	L.HEADER_ADD_FRIEND = "|cffffd700Aggiungi %s a %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Debug Migraz. - Totale:"
	L.MIGRATION_DEBUG_BNET = "Debug Migraz. - BNet vecchio:"
	L.MIGRATION_DEBUG_WOW = "Debug Migraz. - WoW no reame:"
	L.ERROR_INVALID_PARAMS = "Parametri invalidi"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Non ignorare"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE = "Alleati Recenti non disp."
	L.RECENT_ALLIES_INVITE = "Invita"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Giocatore offline"
	L.RECENT_ALLIES_PIN_EXPIRES = "Pin scade in %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Liv %d %s"
	L.RECENT_ALLIES_NOTE = "Nota: %s"
	L.RECENT_ALLIES_ACTIVITY = "Attività Recente:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Recluta un Amico"
	L.RAF_RECRUITMENT = "Reclutamento"
	L.RAF_NO_RECRUITS_DESC = "Nessun reclutato."
	L.RAF_PENDING_RECRUIT = "In Attesa"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Hai guadagnato:"
	L.RAF_NEXT_REWARD_AFTER = "Prossima in %d/%d mesi"
	L.RAF_FIRST_REWARD = "Prima:"
	L.RAF_NEXT_REWARD = "Prossima:"
	L.RAF_REWARD_MOUNT = "Cavalcatura"
	L.RAF_REWARD_TITLE_DEFAULT = "Titolo"
	L.RAF_REWARD_TITLE_FMT = "Titolo: %s"
	L.RAF_REWARD_GAMETIME = "Tempo di Gioco"
	L.RAF_MONTH_COUNT = "%d Mesi"
	L.RAF_CLAIM_REWARD = "Riscatta"
	L.RAF_VIEW_ALL_REWARDS = "Vedi Tutto"
	L.RAF_ACTIVE_RECRUIT = "Attivo"
	L.RAF_TRIAL_RECRUIT = "Prova"
	L.RAF_INACTIVE_RECRUIT = "Inattivo"
	L.RAF_OFFLINE = "Offline"
	L.RAF_TOOLTIP_DESC = "Fino a %d mesi"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d mesi"
	L.RAF_ACTIVITY_DESCRIPTION = "Attività per %s"
	L.RAF_REWARDS_LABEL = "Ricompense"
	L.RAF_YOU_EARNED_LABEL = "Guadagnato:"
	L.RAF_CLICK_TO_CLAIM = "Clicca per riscattare"
	L.RAF_LOADING = "Caricamento..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== RAF ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Attuale"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Vecchio v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Mesi: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Reclute: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Ricompense Disp:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Preso]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Prendibile]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Accessibile]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Bloccato]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d mesi)"
	L.RAF_CHAT_MORE_REWARDS = "    ... e %d altri"
	L.RAF_CHAT_USE_UI = "|cff00ff00Usa UI per dettagli.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00RAF:|r Tempo gioco disponibile."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "Mostra messaggio di benvenuto"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC =
		"Mostra il messaggio di caricamento dell'addon nella chat al momento del login."
	L.SETTINGS_TAB_DATABROKER = "Data Broker"
	L.MSG_GROUP_RENAMED = "Gruppo rinominato '%s'"
	L.ERROR_RENAME_FAILED = "Rinomina fallita"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Ord. gruppi: %s"
	L.ERROR_EXPORT_SERIALIZE = "Err. serializzazione"
	L.ERROR_IMPORT_EMPTY = "Stringa vuota"
	L.ERROR_IMPORT_DECODE = "Err. decodifica"
	L.ERROR_IMPORT_DESERIALIZE = "Err. deserializzazione"
	L.ERROR_EXPORT_VERSION = "Versione non supportata"
	L.ERROR_EXPORT_STRUCTURE = "Struttura invalida"

	-- Statistics
	L.STATS_NO_HEALTH_DATA = "No dati salute"
	L.STATS_NO_CLASS_DATA = "No dati classe"
	L.STATS_NO_LEVEL_DATA = "No dati livello"
	L.STATS_NO_REALM_DATA = "No dati reame"
	L.STATS_NO_GAME_DATA = "No dati gioco"
	L.STATS_NO_MOBILE_DATA = "No dati mobile"
	L.STATS_SAME_REALM = "Stesso Reame: %d (%d%%)  |  Altri: %d (%d%%)"
	L.STATS_TOP_REALMS = "\nTop Reami:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\nAltro: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Note: %d (%d%%)\nPreferiti: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max: %d\n70-79: %d\n60-69: %d\n<60: %d\nMedia: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Attivo: %d (%d%%)|r\n|cffffd700Medio: %d (%d%%)|r\n|cffffaa00Stantio: %d (%d%%)|r\n|cffff6600Stagnante: %d (%d%%)|r\n|cffff0000Inattivo: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffAlliance: %d|r\n|cffff0000Horde: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "Sposta Giù"
	L.TOOLTIP_MOVE_DOWN_DESC = "Sposta gruppo giù"
	L.TOOLTIP_MOVE_UP = "Sposta Su"
	L.TOOLTIP_MOVE_UP_DESC = "Sposta gruppo su"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "Amico non su WoW"
	L.TRAVEL_PASS_WOW_CLASSIC = "Amico su WoW Classic."
	L.TRAVEL_PASS_WOW_MAINLINE = "Amico su WoW."
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Versione differente"
	L.TRAVEL_PASS_NO_INFO = "Info insufficienti"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Regione differente"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "No account gioco"
	L.TRAVEL_PASS_DIFFERENT_FACTION = "L'amico è nell'altra fazione"
	L.TRAVEL_PASS_QUEST_SESSION = "Impossibile invitare durante una sessione di missioni"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Mostra Lista Blizzard"
	L.MENU_COMBAT_LOCKED = "Bloccato in combattimento"
	L.MENU_SET_NICKNAME = "Imposta Soprannome"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Config BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Cerca..."
	L.SEARCH_RECENT_ALLIES_INSTRUCTION = "Cerca alleati recenti..."
	L.SEARCH_RAF_INSTRUCTION = "Cerca amici reclutati..."
	L.RAF_NEXT_REWARD_HELP = "Info RAF"
	L.WHO_LEVEL_FORMAT = "Livello %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Alleati Recenti"
	L.CONTACTS_MENU_NAME = "Menu Contatti"
	L.BATTLENET_UNAVAILABLE = "BNet Non Disp"
	L.BATTLENET_BROADCAST = "Diffusione"
	L.FRIENDS_LIST_ENTER_TEXT = "Msg..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Cerca..."
	L.RAF_SPLASH_SCREEN_TITLE = "RAF"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "Recluta amici!"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Info Ricompense"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Formato Nome"
	L.SETTINGS_NAME_FORMAT_DESC =
		"Usa i token per personalizzare la visualizzazione:\n|cffFFD100%name%|r - Nome account\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Soprannome\n|cffFFD100%note%|r - Nota\n|cffFFD100%character%|r - Nome personaggio\n|cffFFD100%realm%|r - Nome reame\n|cffFFD100%level%|r - Livello\n|cffFFD100%zone%|r - Zona\n|cffFFD100%class%|r - Classe\n|cffFFD100%game%|r - Gioco"
	L.SETTINGS_NAME_FORMAT_LABEL = "Modello:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Formato Nome"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Inserisci formato."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"Questa impostazione è disabilitata perché l'addon 'FriendListColors' gestisce i colori/formati dei nomi."

	-- Name Format Preset Labels (Phase 22)
	L.NAME_PRESET_DEFAULT = "Nome (Personaggio)"
	L.NAME_PRESET_BATTLETAG = "BattleTag (Personaggio)"
	L.NAME_PRESET_NICKNAME = "Soprannome (Personaggio)"
	L.NAME_PRESET_NAME_ONLY = "Solo Nome"
	L.NAME_PRESET_CHARACTER = "Solo Personaggio"
	L.NAME_PRESET_CUSTOM = "Personalizzato..."
	L.SETTINGS_NAME_FORMAT_CUSTOM_LABEL = "Formato personalizzato:"

	-- Info Format Section (Phase 22)
	L.SETTINGS_INFO_FORMAT_HEADER = "Formattazione info amici"
	L.SETTINGS_INFO_FORMAT_LABEL = "Modello:"
	L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL = "Formato personalizzato:"
	L.SETTINGS_INFO_FORMAT_TOOLTIP = "Formato Info Personalizzato"
	L.SETTINGS_INFO_FORMAT_DESC =
		"Usa i token per personalizzare la riga info:\n|cffFFD100%level%|r - Livello personaggio\n|cffFFD100%zone%|r - Zona attuale\n|cffFFD100%class%|r - Nome classe\n|cffFFD100%game%|r - Nome gioco\n|cffFFD100%realm%|r - Nome reame\n|cffFFD100%status%|r - AFK/DND/Online\n|cffFFD100%lastonline%|r - Ultimo accesso\n|cffFFD100%name%|r - Nome account\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Soprannome\n|cffFFD100%note%|r - Nota\n|cffFFD100%character%|r - Nome personaggio"
	L.INFO_PRESET_DEFAULT = "Predefinito (Livello, Zona)"
	L.INFO_PRESET_ZONE = "Solo Zona"
	L.INFO_PRESET_LEVEL = "Solo Livello"
	L.INFO_PRESET_CLASS_ZONE = "Classe, Zona"
	L.INFO_PRESET_LEVEL_CLASS_ZONE = "Livello Classe, Zona"
	L.INFO_PRESET_GAME = "Nome del gioco"
	L.INFO_PRESET_DISABLED = "Disattivato (Nascondi info)"
	L.INFO_PRESET_CUSTOM = "Personalizzato..."

	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "Gruppo 'In Gioco'"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Raggruppa amici in gioco"
	L.SETTINGS_INGAME_MODE_WOW = "Solo WoW"
	L.SETTINGS_INGAME_MODE_ANY = "Qualsiasi Gioco"
	L.SETTINGS_INGAME_MODE_LABEL = "   Mode:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Modalità"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Scegli amici."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT = "   Unità di durata:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_DESC =
		"Scegli l'unità di tempo per quanto tempo gli amici rimangono nel gruppo Aggiunti di recente."
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE = "   Valore durata:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_DESC =
		"Quanti giorni/ore/minuti gli amici rimangono nel gruppo Aggiunti di recente prima di essere rimossi."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_TOOLTIP = "Unità di durata"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_TOOLTIP = "Valore durata"
	L.SETTINGS_DURATION_DAYS = "Giorni"
	L.SETTINGS_DURATION_HOURS = "Ore"
	L.SETTINGS_DURATION_MINUTES = "Minuti"

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Opzioni Visualizzazione"
	L.SETTINGS_BEHAVIOR_HEADER = "Comportamento"
	L.SETTINGS_GROUP_MANAGEMENT = "Gestione Gruppi"
	L.SETTINGS_FONT_SETTINGS = "Font"
	L.SETTINGS_GROUP_ORDER = "Ordine Gruppi"
	L.SETTINGS_MIGRATION_HEADER = "Migrazione FriendGroups"
	L.SETTINGS_MIGRATION_DESC = "Migra da FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migra"
	L.SETTINGS_MIGRATE_TOOLTIP = "Importa"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "Condividi config."
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Attenzione: Sovrascrive!|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Esporta"
	L.SETTINGS_IMPORT_TOOLTIP = "Importa"

	-- Statistics
	L.STATS_HEADER = "Statistiche"
	L.STATS_DESC = "Sommario"
	L.STATS_OVERVIEW_HEADER = "Sommario"
	L.STATS_HEALTH_HEADER = "Salute"
	L.STATS_CLASSES_HEADER = "Top 5 Classi"
	L.STATS_REALMS_HEADER = "Reami"
	L.STATS_ORGANIZATION_HEADER = "Org"
	L.STATS_LEVELS_HEADER = "Livelli"
	L.STATS_GAMES_HEADER = "Giochi"
	L.STATS_MOBILE_HEADER = "Mobile vs PC"
	L.STATS_FACTIONS_HEADER = "Fazioni"
	L.STATS_REFRESH_BTN = "Aggiorna"
	L.STATS_REFRESH_TOOLTIP = "Aggiorna dati"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters

	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Nascondi vuoti"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Mostra icone fazione"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Mostra reame"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Grigio altra fazione"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Mobile come AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Nascondi liv max"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Mostra btn Blizzard"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Mostra Preferiti"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "Uno aperto"
	L.SETTINGS_COMPACT_MODE_DESC = "Compatto"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Abilita Skin ElvUI"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Richiede ElvUI."
	L.DIALOG_ELVUI_RELOAD_TEXT = "Ricarica richiesta.\nRicaricare?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Sì"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "No"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "DB non init."
	L.CORE_SHOW_BLIZZARD_ENABLED = "Opzione Blizzard |cff20ff20ON|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Opzione Blizzard |cffff0000OFF|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Debug non disp"
	L.CORE_DB_MODULE_NOT_AVAIL = "Modulo DB non disp"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Attività ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Amici attivi: %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "Beta disabilitata!"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Abilita:|r ESC > AddOns > BFL"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Stats non caricate"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Statistiche ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Sommario:|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE =
		"  Tot: |cffffffff%d|r  On: |cff00ff00%d|r (%.0f%%)  Off: |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet: |cff0099ff%d|r  |  WoW: |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Salute:|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Attivo: |cff00ff00%d|r  Medio: |cffffd700%d|r"
	L.CORE_STATS_HEALTH_STALE = "  Stantio: |cffff6600%d|r  Dormiente: |cffff0000%d|r"
	L.CORE_STATS_NO_HEALTH_DATA = "  No dati"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Classi:|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Livelli:|r"
	L.CORE_STATS_LEVEL_BREAKDOWN =
		"  Max: |cffffffff%d|r  70+: |cffffffff%d|r  60+: |cffffffff%d|r  <60: |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Media: |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Reami:|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Stesso: |cffffffff%d|r  |  Altro: |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Top:"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Fazioni:|r"
	L.CORE_STATS_FACTION_DATA = "  Ally: |cff0080ff%d|r  |  Horde: |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Giochi:|r"
	L.CORE_STATS_GAME_WOW = "  Retail: |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic: |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4: |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS: |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC: |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  App: |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Altri: |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Mobile vs PC:|r"
	L.CORE_STATS_MOBILE_DATA = "  PC: |cffffffff%d|r (%.0f%%)  Mobile: |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Org:|r"
	L.CORE_STATS_ORG_DATA = "  Note: |cffffffff%d|r  Fav: |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Config non caricata"
	L.CORE_MOCK_INVITES_ENABLED = "Inv. Test |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Agg inv. test |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Tip:|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Pulito"
	L.CORE_NO_MOCK_INVITES = "No inviti"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Monitor non carc."
	L.CORE_MEMORY_USAGE = "Mem: %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "QJ non carc."
	L.CORE_RAIDFRAME_NOT_LOADED = "RaidFrame non carc."
	L.CORE_PREVIEW_MODE_NOT_LOADED = "Preview non carc."
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Compat ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Ver Client:|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Tipo:|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00TWW|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffffRetail|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Disp:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menu Mod: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Alliés Rec: %s"
	L.CORE_FEATURE_EDIT_MODE = "  Edit Mode: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Compat:|r %s"
	L.CORE_COMPAT_ACTIVE = "|cff00ff00Attivo|r"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000Non Caricato|r"
	L.CORE_CHANGELOG_RESET = "Changelog reset."
	L.CORE_CHANGELOG_NOT_LOADED = "Changelog non caricato"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Debug ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard:|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000No settings|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00BFL attrs:|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00In UIPanel:|r |cff00ff00SÌ|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00In UIPanel:|r |cffff0000NO|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800AVVISO:|r FriendsFrame in UIPanel!"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Setting:|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BFL v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Comandi:|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Toggle"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/bfl settings|r - Config"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/bfl help|r - Aiuto"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Apri registro modifiche"
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - Ripristina posizione finestra"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Debug:|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/bfl debug|r - Toggle debug"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Vedi DB"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Vedi attività"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Vedi stats"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Test regole"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join:|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Mock"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Dungeon"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Raid"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Stress"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - Eventi"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Pulisci"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - Lista"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock:|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Crea raid"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Invito"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Pulisci inviti"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Preview:|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - On"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Off"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Dati falsi)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame:|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - 25j"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - 40j"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - 10j"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - 20j"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - RC Sim"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Ruolo Sim"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Mossa Sim"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Pulisci"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Perf:|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Show"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Abilita"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Reset"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Memoria"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Test:|r"
	L.TESTSUITE_PERFY_HELP = "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"
	L.TESTSUITE_PERFY_STARTING = "Starting Perfy stress test for %d seconds"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Perfy stress test already running"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Perfy addon not loaded (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Perfy slash command not available"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy stress action failed: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy stress test finished"
	L.TESTSUITE_PERFY_ABORTED = "Perfy stress test stopped: %s"
	L.CORE_HELP_LINK = "|cff20ff20Aiuto:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Caricato. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Accettato %s"
	L.MOCK_INVITE_DECLINED = "Rifiutato %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Stats reset"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Perf ===|r"
	L.PERF_QJ_OPS = "|cffffd700QJ Ops:|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Friends Ops:|r"
	L.PERF_MEMORY = "|cffffd700Memoria:|r"
	L.PERF_TARGETS = "|cffffd700Target:|r"
	L.PERF_AUTO_ENABLED = "Auto-monitor |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Creato 25j"
	L.RAID_MOCK_CREATED_40 = "Creato 40j"
	L.RAID_MOCK_CREATED_10 = "Creato 10j"
	L.RAID_MOCK_CREATED_MYTHIC = "Creato 20j (M)"
	L.RAID_MOCK_STRESS = "Stress test"
	L.RAID_WARN_CPU = "|cffff8800Avviso:|r CPU alta"
	L.RAID_NO_MOCK_DATA = "No dati. '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Sim Ready Check..."
	L.RAID_MOCK_CLEARED = "Pulito"
	L.RAID_EVENT_COMMANDS = "|cff00ff00Eventi Raid:|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Gestione:|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Config"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - Lista"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Stress"
	L.RAID_HELP_EVENTS = "|cffffcc00Sim:|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Config Raid:|r"
	L.RAID_INFO_HEADER = "|cff00ff00Info Mock:|r"
	L.RAID_NO_MOCK_ACTIVE = "No mock"
	L.RAID_DYN_UPDATES = "Updates: %s"
	L.RAID_UPDATE_INTERVAL = "Int: %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Mock: %s"
	L.RAID_DYN_UPDATES_STATUS = "  Dyn: %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Int: %.1f s"
	L.RAID_MEMBERS_STATUS = "  Membri: %d"
	L.RAID_TOTAL_MEMBERS = "  Tot: %d"
	L.RAID_COMPOSITION = "  Comp: %d T, %d H, %d D"
	L.RAID_STATUS = "  Stato: %d off, %d morti"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Creato test icone"
	L.QJ_MOCK_CREATED_STRESS = "Creato test 50"
	L.QJ_SIM_ADDED = "Sim: Aggiunto"
	L.QJ_SIM_REMOVED = "Sim: Rimosso"
	L.QJ_ERR_NO_GROUPS_REMOVE = "Niente da rimuovere"
	L.QJ_ERR_NO_GROUPS_UPDATE = "Niente da aggiornare"
	L.QJ_EVENT_COMMANDS = "|cff00ff00Eventi QJ:|r"
	L.QJ_LIST_HEADER = "|cff00ff00Gruppi QJ:|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00Config QJ:|r"
	L.QJ_EXT_FOOTER = "|cff888888Mock verdi.|r"
	L.QJ_SIM_UPDATED_FMT = "Sim: %s agg."
	L.QJ_ADDED_GROUP_FMT = "Aggiunto: %s"
	L.QJ_NO_GROUPS_HINT = "No gruppi."
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Icone"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config:|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Config"

	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Reset Guild UI warning."
	L.CMD_RESET_HEADER = "Reset:"
	L.CMD_RESET_HELP_WARNING = "Reset Guild warning"

	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "   GitHub Issues"
	L.CHANGELOG_SUPPORT = "   Supporto"
	L.CHANGELOG_HEADER_COMMUNITY = "Community:"
	L.CHANGELOG_HEADER_VERSION = "Ver %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "Nuova Versione!"
	L.CHANGELOG_TOOLTIP_CLICK = "Clicca per dettagli"
	L.CHANGELOG_POPUP_DISCORD = "Discord"
	L.CHANGELOG_POPUP_GITHUB = "Bugs"
	L.CHANGELOG_POPUP_SUPPORT = "Supporto"
	L.CHANGELOG_TITLE = "Changelog"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Liv Max"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Gruppo %d"
	L.RAID_CONVERT_TO_PARTY = "Converti a Gruppo"
	L.RAID_CONVERT_TO_RAID = "Converti a Incursione"
	L.RAID_MUST_BE_LEADER = "Devi essere il capo per farlo"
	L.RAID_CONVERT_TOO_MANY = "Il gruppo ha troppi giocatori per un gruppo"
	L.RAID_ERR_NOT_IN_GROUP = "Non sei in un gruppo"

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6ms = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3ms = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Avviso"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Mobile"
	L.RAF_RECRUITMENT = "Invita un Amico"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Colora i nomi degli amici nel colore della loro classe"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Font Outline"
	L.SETTINGS_FONT_SHADOW = "Font Shadow"
	L.SETTINGS_FONT_OUTLINE_NONE = "None"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Outline"
	L.SETTINGS_FONT_OUTLINE_THICK = "Contorno Spesso"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Monochrome"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "Modifica nota"
	L.MENU_SHOW_SEARCH = "Mostra ricerca"
	L.MENU_QUICK_FILTER = "Filtro rapido"

	-- Multi-Game-Account
	L.MENU_INVITE_CHARACTER = "Invita personaggio..."
	L.INVITE_ACCOUNT_PICKER_TITLE = "Invita personaggio"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Abilita Icona Preferito"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "Mostra un'icona stella sul pulsante amico per i preferiti."
	L.SETTINGS_FAVORITE_ICON_STYLE = "Icona preferiti"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC = "Scegli quale icona usare per i preferiti."
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "Icona BFL"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "Icona Blizzard"
	L.SETTINGS_SHOW_FACTION_BG = "Mostra Sfondo Fazione"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "Mostra il colore della fazione come sfondo per il pulsante amico."

	-- Multi-Game-Account Settings
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "Mostra badge multi-account"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC = "Mostra un badge sugli amici con più account di gioco online."
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "Mostra info multi-account"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC =
		"Aggiunge un breve elenco di personaggi online quando un amico ha più account attivi."
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS = "Tooltip: Account di gioco max"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS_DESC = "Numero massimo di account di gioco aggiuntivi mostrati nel tooltip."
	L.INFO_MULTI_ACCOUNT_PREFIX = "x%d Accounts"
	L.INFO_MULTI_ACCOUNT_REMAINDER = " (+%d)"

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "Raid"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "Enable Shortcuts"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"Abilita o disabilita tutti i tasti scorciatoia personalizzati del mouse sul Frame Incursione."
	L.SETTINGS_RAID_SHORTCUTS_TITLE = "Raid Shortcuts"
	L.SETTINGS_RAID_ACTION_MASS_MOVE = "Mass Move"
	L.SETTINGS_RAID_ACTION_MAIN_TANK = "Set Main Tank"
	L.SETTINGS_RAID_ACTION_MAIN_ASSIST = "Set Main Assist"
	L.SETTINGS_RAID_ACTION_RAID_LEAD = "Set Raid Leader"
	L.SETTINGS_RAID_ACTION_PROMOTE = "Promote Assistant"
	L.SETTINGS_RAID_ACTION_TARGET = "Target Unit"
	L.SETTINGS_RAID_ACTION_DEMOTE = "Demote Assistant"
	L.SETTINGS_RAID_ACTION_KICK = "Remove from Group"
	L.SETTINGS_RAID_ACTION_INVITE = "Invite to Group"
	L.SETTINGS_RAID_MODIFIER_NONE = "None"
	L.SETTINGS_RAID_MODIFIER_SHIFT = "Shift"
	L.SETTINGS_RAID_MODIFIER_CTRL = "Ctrl"
	L.SETTINGS_RAID_MODIFIER_ALT = "Alt"
	L.SETTINGS_RAID_MOUSE_LEFT = "Left Click"
	L.SETTINGS_RAID_MOUSE_RIGHT = "Right Click"
	L.SETTINGS_RAID_MOUSE_MIDDLE = "Middle Click"

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "Modalità Streamer"
	L.STREAMER_MODE_DESC = "Opzioni di privacy per lo streaming o la registrazione."
	L.SETTINGS_ENABLE_STREAMER_MODE = "Mostra Pulsante Modalità Streamer"
	L.STREAMER_MODE_ENABLE_DESC =
		"Mostra un pulsante nel frame principale per attivare/disattivare la Modalità Streamer."
	L.STREAMER_MODE_HIDDEN_NAME = "Formato Nome Nascosto"
	L.STREAMER_MODE_HEADER_TEXT = "Testo Intestazione Personalizzato"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"Testo da visualizzare nell'intestazione Battle.net quando la Modalità Streamer è attiva (p. es., 'Modalità Stream')."
	L.STREAMER_MODE_BUTTON_TOOLTIP = "Attiva/Disattiva Modalità Streamer"
	L.STREAMER_MODE_BUTTON_DESC = "Clicca per abilitare/disabilitare la modalità privacy."
	L.SETTINGS_PRIVACY_OPTIONS = "Opzioni di Privacy"
	L.SETTINGS_STREAMER_NAME_FORMAT = "Valori Nome"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC = "Scegli come vengono visualizzati i nomi in Modalità Streamer."
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "Forza BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME = "Forza Soprannome"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "Forza Nota"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "Usa Colore Intestazione Viola"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"Cambia lo sfondo dell'intestazione Battle.net al viola Twitch quando la Modalità Streamer è attiva."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26) - PARTIAL
	-- ========================================
	L.SETTINGS_RAID_DESC = "Configura i tasti scorciatoia del mouse per la gestione delle incursioni e dei gruppi."
	L.SETTINGS_RAID_MODIFIER_LABEL = "Mod:"
	L.SETTINGS_RAID_BUTTON_LABEL = "Btn:"
	L.SETTINGS_RAID_WARNING = "Nota: Gli scorciatoia sono azioni sicure (solo fuori dal combattimento)."
	L.SETTINGS_RAID_ERROR_RESERVED = "Questa combinazione è riservata."

	-- ========================================
	-- WHO FRAME SETTINGS
	-- ========================================
	L.SETTINGS_TAB_WHO = "Chi"
	L.WHO_SETTINGS_DESC = "Configura l'aspetto e il comportamento dei risultati di ricerca Chi."
	L.WHO_SETTINGS_VISUAL_HEADER = "Aspetto"
	L.WHO_SETTINGS_CLASS_ICONS = "Mostra icone classe"
	L.WHO_SETTINGS_CLASS_ICONS_DESC = "Visualizza le icone classe accanto ai nomi dei giocatori."
	L.WHO_SETTINGS_CLASS_COLORS = "Nomi colorati per classe"
	L.WHO_SETTINGS_CLASS_COLORS_DESC = "Colora i nomi dei giocatori in base alla loro classe."
	L.WHO_SETTINGS_LEVEL_COLORS = "Colori difficoltà livello"
	L.WHO_SETTINGS_LEVEL_COLORS_DESC = "Colora i livelli in base alla difficoltà relativa al tuo livello."
	L.WHO_SETTINGS_ZEBRA = "Sfondo righe alternate"
	L.WHO_SETTINGS_ZEBRA_DESC = "Mostra sfondi di righe alternate per migliorare la leggibilità."
	L.WHO_SETTINGS_BEHAVIOR_HEADER = "Comportamento"
	L.WHO_SETTINGS_DOUBLE_CLICK = "Azione doppio clic"
	L.WHO_DOUBLE_CLICK_WHISPER = "Sussurra"
	L.WHO_DOUBLE_CLICK_INVITE = "Invita nel gruppo"
	L.WHO_RESULTS_SHOWING = "%d di %d giocatori mostrati"
	L.WHO_NO_RESULTS = "Nessun giocatore trovato"
	L.WHO_TOOLTIP_HINT_CLICK = "Clic per selezionare"
	L.WHO_TOOLTIP_HINT_DBLCLICK = "Doppio clic per sussurrare"
	L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE = "Doppio clic per invitare"
	L.WHO_TOOLTIP_HINT_CTRL_FORMAT = "Ctrl+Clic per cercare %s"
	L.WHO_TOOLTIP_HINT_ALT_FORMAT = "Alt+Clic per aggiungere %s al costruttore di ricerca"
	L.WHO_TOOLTIP_HINT_RIGHTCLICK = "Clic destro per opzioni"
	L.WHO_SEARCH_PENDING = "Ricerca..."
	L.WHO_SEARCH_TIMEOUT = "Nessuna risposta. Riprova."

	-- ========================================
	-- WHO SEARCH BUILDER
	-- ========================================
	L.WHO_BUILDER_TITLE = "Costruttore di ricerca"
	L.WHO_BUILDER_NAME = "Nome"
	L.WHO_BUILDER_GUILD = "Gilda"
	L.WHO_BUILDER_ZONE = "Zona"
	L.WHO_BUILDER_CLASS = "Classe"
	L.WHO_BUILDER_RACE = "Razza"
	L.WHO_BUILDER_LEVEL = "Livello"
	L.WHO_BUILDER_LEVEL_TO = "a"
	L.WHO_BUILDER_ALL_CLASSES = "Tutte le classi"
	L.WHO_BUILDER_ALL_RACES = "Tutte le razze"
	L.WHO_BUILDER_PREVIEW = "Anteprima:"
	L.WHO_BUILDER_PREVIEW_EMPTY = "Compila i campi per costruire una ricerca"
	L.WHO_BUILDER_SEARCH = "Cerca"
	L.WHO_BUILDER_RESET = "Reimposta"
	L.WHO_BUILDER_TOOLTIP = "Apri il costruttore di ricerca"
	L.WHO_BUILDER_DOCK_TOOLTIP = "Ancora il costruttore di ricerca"
	L.WHO_BUILDER_UNDOCK_TOOLTIP = "Sgancia il costruttore di ricerca"

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "Dimensioni del Riquadro"
	L.SETTINGS_FRAME_SCALE = "Scala:"
	L.SETTINGS_FRAME_WIDTH = "Larghezza:"
	L.SETTINGS_FRAME_HEIGHT = "Altezza:"
	L.SETTINGS_FRAME_WIDTH_DESC = "Regola la larghezza del riquadro"
	L.SETTINGS_FRAME_HEIGHT_DESC = "Regola l'altezza del riquadro"
	L.SETTINGS_FRAME_SCALE_DESC = "Regola la scala del riquadro"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "Allineamento dell'Intestazione del Gruppo"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC = "Imposta l'allineamento del testo del nome del gruppo"
	L.SETTINGS_ALIGN_LEFT = "Sinistra"
	L.SETTINGS_ALIGN_CENTER = "Centro"
	L.SETTINGS_ALIGN_RIGHT = "Destra"
	L.SETTINGS_SHOW_GROUP_ARROW = "Mostra Freccia di Compressione"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC = "Mostra o nascondi l'icona della freccia per comprimere i gruppi"
	L.SETTINGS_GROUP_ARROW_ALIGN = "Allineamento della Freccia di Compressione"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC = "Imposta l'allineamento dell'icona della freccia comprimi/espandi"
	L.SETTINGS_FONT_FACE = "Carattere"
	L.SETTINGS_COLOR_GROUP_COUNT = "Colore del Contatore del Gruppo"
	L.SETTINGS_COLOR_GROUP_ARROW = "Colore della Freccia di Compressione"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Eredita il Colore dal Gruppo"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Eredita il Colore dal Gruppo"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Impostazioni dell'Intestazione del Gruppo"
	L.SETTINGS_GROUP_FONT_HEADER = "Carattere dell'Intestazione del Gruppo"
	L.SETTINGS_GROUP_COLOR_HEADER = "Colori dell'Intestazione del Gruppo"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clic destro per ereditare dal Gruppo"
	L.SETTINGS_INHERIT_TOOLTIP = "(Ereditato dal Gruppo)"

	-- Misc
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "Elenco Ignorati Globale"
	L.IGNORE_LIST_ENHANCEQOL_IGNORE = "Elenco Ignorati EnhanceQoL"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "Impostazioni Nome Amico"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "Impostazioni Informazioni Amico"
	L.SETTINGS_FONT_TABS_TITLE = "Testo Schede"
	L.SETTINGS_FONT_RAID_TITLE = "Testo Nome Raid"
	L.SETTINGS_FONT_SIZE_NUM = "Dimensione Font"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "Sincronizzazione note gruppo"
	L.SETTINGS_SYNC_GROUPS_NOTE = "Sincronizza gruppi nelle note amico"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"Scrive le assegnazioni dei gruppi nelle note degli amici nel formato FriendGroups (Nota#Gruppo1#Gruppo2). Permette di condividere i gruppi tra account o con gli utenti di FriendGroups."
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"Attivare la sincronizzazione delle note di gruppo?\n\n|cffff8800Attenzione:|r Le note BattleNet sono limitate a 127 caratteri, le note amici WoW a 48 caratteri. I gruppi che superano il limite verranno saltati nella nota ma rimarranno nel database.\n\nLe note esistenti verranno aggiornate. Continuare?"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "Attiva"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "Annulla"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"La sincronizzazione delle note di gruppo e stata disattivata.\n\nVuoi aprire la Procedura Guidata di Pulizia delle Note per rimuovere i suffissi di gruppo dalle note dei tuoi amici?"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "Apri Procedura Guidata"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "Mantieni Note"
	L.MSG_SYNC_GROUPS_STARTED = "Sincronizzazione gruppi nelle note amici..."
	L.MSG_SYNC_GROUPS_COMPLETE = "Sincronizzazione completata. Aggiornati: %d, Saltati (limite): %d"
	L.MSG_SYNC_GROUPS_PROGRESS = "Sincronizzazione note: %d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT = "Limite nota raggiunto per %s - alcuni gruppi saltati"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "Procedura Pulizia Note"
	L.WIZARD_DESC =
		"Rimuovi i dati di FriendGroups (#Gruppo1#Gruppo2) dalle note degli amici. Controlla le note pulite prima di applicare."
	L.WIZARD_BTN = "Pulizia Note"
	L.WIZARD_BTN_TOOLTIP = "Apri la procedura per pulire i dati di FriendGroups dalle note degli amici"
	L.WIZARD_HEADER = "Pulizia Note"
	L.WIZARD_HEADER_DESC =
		"Rimuovi i suffissi di FriendGroups dalle note degli amici. Esegui un backup prima, poi controlla e applica le modifiche."
	L.WIZARD_COL_ACCOUNT = "Nome Account"
	L.WIZARD_COL_BATTLETAG = "BattleTag"
	L.WIZARD_COL_NOTE = "Nota Attuale"
	L.WIZARD_COL_CLEANED = "Nota Pulita"
	L.WIZARD_SEARCH_PLACEHOLDER = "Cerca..."
	L.WIZARD_BACKUP_BTN = "Backup Note"
	L.WIZARD_BACKUP_DONE = "Backup completato!"
	L.WIZARD_BACKUP_TOOLTIP = "Salva tutte le note degli amici attuali nel database come backup."
	L.WIZARD_BACKUP_SUCCESS = "Backup completato per %d amici."
	L.WIZARD_APPLY_BTN = "Applica Pulizia"
	L.WIZARD_APPLY_TOOLTIP = "Riscrivi le note pulite. Solo le note diverse dall'originale verranno aggiornate."
	L.WIZARD_APPLY_CONFIRM =
		"Applicare le note pulite a tutti gli amici?\n\n|cffff8800Le note attuali verranno sovrascritte. Assicurati di aver creato un backup prima!|r"
	L.WIZARD_APPLY_SUCCESS = "%d note aggiornate con successo."
	L.WIZARD_APPLY_PROGRESS_FMT = "Progresso: %d/%d | %d riusciti | %d falliti"
	L.WIZARD_STATUS_FMT = "Visualizzando %d di %d amici | %d con dati di gruppo | %d modifiche in sospeso"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "Visualizza backup"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"Apri il visualizzatore di backup per vedere tutte le note salvate e confrontarle con quelle attuali."
	L.WIZARD_BACKUP_VIEWER_TITLE = "Visualizzatore backup note"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"Visualizza le note degli amici salvate e confrontale con le note attuali. Puoi ripristinare le note originali se necessario."
	L.WIZARD_COL_BACKED_UP = "Nota salvata"
	L.WIZARD_COL_CURRENT = "Nota attuale"
	L.WIZARD_RESTORE_BTN = "Ripristina backup"
	L.WIZARD_RESTORE_TOOLTIP =
		"Ripristina le note originali dal backup. Verranno aggiornate solo le note diverse dal backup."
	L.WIZARD_RESTORE_CONFIRM =
		"Ripristinare tutte le note dal backup?\n\n|cffff8800Questo sovrascrivera le note attuali con le versioni salvate.|r"
	L.WIZARD_RESTORE_SUCCESS = "%d note ripristinate con successo."
	L.WIZARD_NO_BACKUP = "Nessun backup trovato. Usa prima la Procedura guidata di pulizia note per crearne uno."
	L.WIZARD_BACKUP_STATUS_FMT = "Mostrando %d di %d voci | %d modificate dal backup | Backup: %s"
end)
