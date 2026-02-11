-- Locales/frFR.lua
-- French Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("frFR", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Mode Simple"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"Désactive le portrait du joueur, masque les options de recherche/tri, élargit la fenêtre et déplace les onglets pour une interface compacte."
	L.MENU_CHANGELOG = "Journal des modifications"
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Entrez un nom pour le nouveau groupe :"
	L.DIALOG_CREATE_GROUP_BTN1 = "Créer"
	L.DIALOG_CREATE_GROUP_BTN2 = "Annuler"
	L.DIALOG_RENAME_GROUP_TEXT = "Entrez un nouveau nom pour le groupe :"
	L.DIALOG_RENAME_GROUP_BTN1 = "Renommer"
	L.DIALOG_RENAME_GROUP_BTN2 = "Annuler"
	L.DIALOG_RENAME_GROUP_SETTINGS = "Renommer le groupe '%s' :"
	L.DIALOG_DELETE_GROUP_TEXT =
		"Êtes-vous sûr de vouloir supprimer ce groupe ?\n\n|cffff0000Cela supprimera tous les amis de ce groupe.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Supprimer"
	L.DIALOG_DELETE_GROUP_BTN2 = "Annuler"
	L.DIALOG_DELETE_GROUP_SETTINGS = "Supprimer le groupe '%s' ?\n\nTous les amis seront désaffectés de ce groupe."
	L.DIALOG_RESET_SETTINGS_TEXT = "Réinitialiser tous les paramètres aux valeurs par défaut ?"
	L.DIALOG_RESET_BTN1 = "Réinitialiser"
	L.DIALOG_RESET_BTN2 = "Annuler"
	L.DIALOG_UI_PANEL_RELOAD_TEXT =
		"Modifier les paramètres de hiérarchie UI nécessite un rechargement.\n\nRecharger maintenant ?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Recharger"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Annuler"
	L.MSG_RELOAD_REQUIRED = "Un rechargement est requis pour appliquer correctement ce changement dans Classic."
	L.MSG_RELOAD_NOW = "Recharger l'interface maintenant ?"
	L.RAID_HELP_TITLE = "Aide Liste de Raid"
	L.RAID_HELP_TEXT = "Cliquez pour obtenir de l'aide sur l'utilisation de la liste de raid."
	L.RAID_HELP_MULTISELECT_TITLE = "Sélection Multiple"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Maintenez Ctrl et Clic Gauche pour sélectionner plusieurs joueurs.\nUne fois sélectionnés, faites-les glisser vers n'importe quel groupe pour les déplacer ensemble."
	L.RAID_HELP_MAINTANK_TITLE = "Tank Principal"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s sur un joueur pour le définir comme Tank Principal.\nUne icône de bouclier apparaîtra à côté de son nom."
	L.RAID_HELP_MAINASSIST_TITLE = "Assistant Principal"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s sur un joueur pour le définir comme Assistant Principal.\nUne icône d'épée apparaîtra à côté de son nom."
	L.RAID_HELP_LEAD_TITLE = "Chef de Raid"
	L.RAID_HELP_LEAD_TEXT = "%s sur un joueur pour le promouvoir Chef de Raid."
	L.RAID_HELP_PROMOTE_TITLE = "Assistant"
	L.RAID_HELP_PROMOTE_TEXT = "%s sur un joueur pour le promouvoir/rétrograder comme Assistant."
	L.RAID_HELP_DRAGDROP_TITLE = "Glisser-Déposer"
	L.RAID_HELP_DRAGDROP_TEXT =
		"Faites glisser n'importe quel joueur pour le déplacer entre les groupes.\nVous pouvez aussi déplacer plusieurs joueurs sélectionnés à la fois.\nLes emplacements vides peuvent être utilisés pour échanger les positions."
	L.RAID_HELP_COMBAT_TITLE = "Verrouillage en Combat"
	L.RAID_HELP_COMBAT_TEXT =
		"Les joueurs ne peuvent pas être déplacés pendant le combat.\nC'est une restriction de Blizzard pour éviter les erreurs."
	L.RAID_INFO_UNAVAILABLE = "Info non disponible"
	L.RAID_NOT_IN_RAID = "Pas en raid"
	L.RAID_NOT_IN_RAID_DETAILS = "Vous n'êtes pas actuellement dans un groupe de raid."
	L.RAID_CREATE_BUTTON = "Créer un Raid"
	L.GROUP = "Groupe"
	L.ALL = "Tous"
	L.UNKNOWN_ERROR = "Erreur inconnue"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Pas assez d'espace : %d joueurs sélectionnés, %d places libres dans le Groupe %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "%d joueurs déplacés vers le Groupe %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Échec du déplacement de %d joueurs"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "Vous devez être chef de raid ou assistant pour lancer un appel."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "Vous n'avez pas d'instances de raid enregistrées."
	L.RAID_ERROR_LOAD_RAID_INFO = "Erreur : Impossible de charger la fenêtre Info Raid."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s échangés"
	L.RAID_ERROR_SWAP_FAILED = "Échange échoué : %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s déplacé vers le Groupe %d"
	L.RAID_ERROR_MOVE_FAILED = "Déplacement échoué : %s"
	L.DIALOG_MIGRATE_TEXT =
		"Migrer les groupes d'amis de FriendGroups vers BetterFriendlist ?\n\nCeci va :\n• Créer tous les groupes à partir des notes BNet\n• Assigner les amis à leurs groupes\n• Optionnellement nettoyer les notes\n\n|cffff0000Attention : Ceci ne peut pas être annulé !|r"
	L.DIALOG_MIGRATE_BTN1 = "Migrer et Nettoyer Notes"
	L.DIALOG_MIGRATE_BTN2 = "Migrer Seulement"
	L.DIALOG_MIGRATE_BTN3 = "Annuler"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "Général"
	L.SETTINGS_TAB_FONTS = "Polices"
	L.SETTINGS_TAB_GROUPS = "Groupes"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Paramètres En-tête"
	L.SETTINGS_GROUP_FONT_HEADER = "Police En-tête Groupe"
	L.SETTINGS_GROUP_COLOR_HEADER = "Couleurs En-tête Groupe"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Hériter de la couleur du groupe"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Hériter de la couleur du groupe"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clic droit pour hériter du groupe"
	L.SETTINGS_INHERIT_TOOLTIP = "(Hérité du groupe)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Ordre des Groupes"
	L.SETTINGS_GROUP_COUNT_COLOR = "Couleur Compteur"
	L.SETTINGS_GROUP_ARROW_COLOR = "Couleur Flèche"
	L.SETTINGS_TAB_APPEARANCE = "Apparence"
	L.SETTINGS_TAB_ADVANCED = "Avancé"
	L.SETTINGS_ADVANCED_DESC = "Options avancées et outils"
	L.SETTINGS_TAB_STATISTICS = "Statistiques"
	L.SETTINGS_SHOW_BLIZZARD = "Afficher l'option Liste d'Amis Blizzard"
	L.SETTINGS_COMPACT_MODE = "Mode Compact"
	L.SETTINGS_LOCK_WINDOW = "Verrouiller la fenêtre"
	L.SETTINGS_LOCK_WINDOW_DESC = "Verrouille la fenêtre pour empêcher tout déplacement accidentel."
	L.SETTINGS_FONT_SIZE = "Taille de Police"
	L.SETTINGS_FONT_COLOR = "Couleur de la police"
	L.SETTINGS_FONT_SIZE_SMALL = "Petit (Compact, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normal (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Grand (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Colorer Noms de Classe"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Masquer Groupes Vides"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Compteur En-tête Groupe"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Choisir comment afficher les compteurs d'amis"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Filtrés / Total (Défaut)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "En ligne / Total"
	L.SETTINGS_HEADER_COUNT_BOTH = "Filtrés / En ligne / Total"
	L.SETTINGS_SHOW_FACTION_ICONS = "Afficher Icônes Faction"
	L.SETTINGS_SHOW_REALM_NAME = "Afficher Nom du Royaume"
	L.SETTINGS_GRAY_OTHER_FACTION = "Griser Autre Faction"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Afficher Mobile comme Absent (AFK)"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Afficher Texte Mobile"
	L.SETTINGS_HIDE_MAX_LEVEL = "Masquer Niveau Max"
	L.SETTINGS_ACCORDION_GROUPS = "Groupes Accordéon (un seul ouvert à la fois)"
	L.SETTINGS_SHOW_FAVORITES = "Afficher Groupe Favoris"
	L.SETTINGS_SHOW_GROUP_FMT = "Afficher le groupe %s"
	L.SETTINGS_SHOW_GROUP_DESC_FMT = "Afficher ou masquer le groupe %s dans votre liste d'amis"
	L.SETTINGS_GROUP_COLOR = "Couleur du Groupe"
	L.SETTINGS_RENAME_GROUP = "Renommer Groupe"
	L.SETTINGS_DELETE_GROUP = "Supprimer Groupe"
	L.SETTINGS_DELETE_GROUP_DESC = "Supprimer ce groupe et désaffecter tous les amis"
	L.SETTINGS_EXPORT_TITLE = "Exporter Configuration"
	L.SETTINGS_EXPORT_INFO =
		"Copiez le texte ci-dessous et sauvegardez-le. Vous pouvez l'importer sur un autre personnage."
	L.SETTINGS_EXPORT_BTN = "Tout Sélectionner"
	L.BUTTON_EXPORT = "Exporter"
	L.SETTINGS_IMPORT_TITLE = "Importer Configuration"
	L.SETTINGS_IMPORT_INFO =
		"Collez votre chaîne d'exportation ci-dessous et cliquez sur Importer.\n\n|cffff0000Attention : Ceci remplacera TOUS vos groupes et affectations !|r"
	L.SETTINGS_IMPORT_BTN = "Importer"
	L.SETTINGS_IMPORT_CANCEL = "Annuler"
	L.SETTINGS_RESET_DEFAULT = "Réinitialiser aux Défauts"
	L.SETTINGS_RESET_SUCCESS = "Configuration réinitialisée !"
	L.SETTINGS_GROUP_ORDER_SAVED = "Ordre des groupes sauvegardé !"
	L.SETTINGS_MIGRATION_COMPLETE = "Migration Terminée !"
	L.SETTINGS_MIGRATION_FRIENDS = "Amis traités :"
	L.SETTINGS_MIGRATION_GROUPS = "Groupes créés :"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Affectations réalisées :"
	L.SETTINGS_NOTES_CLEANED = "Notes nettoyées !"
	L.SETTINGS_NOTES_PRESERVED = "Notes conservées (nettoyage manuel possible)."
	L.SETTINGS_EXPORT_SUCCESS = "Exportation terminée ! Copiez le texte."
	L.SETTINGS_IMPORT_SUCCESS = "Importation réussie ! Groupes et affectations restaurés."
	L.SETTINGS_IMPORT_FAILED = "Erreur d'importation !\n\n"
	L.STATS_TOTAL_FRIENDS = "Total Amis : %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00En ligne : %d (%d%%)|r  |  |cff808080Hors ligne : %d (%d%%)|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net : %d|r  |  |cffffd700WoW : %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Demandes d'ami (%d)"
	L.INVITE_BUTTON_ACCEPT = "Accepter"
	L.INVITE_BUTTON_DECLINE = "Refuser"
	L.INVITE_TAP_TEXT = "Appuyez pour accepter ou refuser"
	L.INVITE_MENU_DECLINE = "Refuser"
	L.INVITE_MENU_REPORT = "Signaler Joueur"
	L.INVITE_MENU_BLOCK = "Bloquer Invitations"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Tous les Amis"
	L.FILTER_ONLINE_ONLY = "En ligne uniq."
	L.FILTER_OFFLINE_ONLY = "Hors ligne uniq."
	L.FILTER_WOW_ONLY = "WoW uniq."
	L.FILTER_BNET_ONLY = "Battle.net uniq."
	L.FILTER_HIDE_AFK = "Masquer AFK/NPD"
	L.FILTER_RETAIL_ONLY = "Retail uniq."
	L.FILTER_TOOLTIP = "Filtre rapide : %s"
	L.SORT_STATUS = "Statut"
	L.SORT_NAME = "Nom (A-Z)"
	L.SORT_LEVEL = "Niveau"
	L.SORT_ZONE = "Zone"
	L.SORT_ACTIVITY = "Activité Récente"
	L.SORT_GAME = "Jeu"
	L.SORT_FACTION = "Faction"
	L.SORT_GUILD = "Guilde"
	L.SORT_CLASS = "Classe"
	L.SORT_REALM = "Royaume"
	L.SORT_CHANGED = "Tri changé pour : %s"
	L.SORT_NONE = "Aucun"
	L.SORT_PRIMARY_LABEL = "Tri Principal"
	L.SORT_SECONDARY_LABEL = "Tri Secondaire"
	L.SORT_PRIMARY_DESC = "Choisissez comment la liste d'amis est triée."
	L.SORT_SECONDARY_DESC = "Tri secondaire lorsque les valeurs principales sont égales."

	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Groupes"
	L.MENU_CREATE_GROUP = "Créer Groupe"
	L.MENU_REMOVE_ALL_GROUPS = "Retirer de tous les groupes"
	L.MENU_RENAME_GROUP = "Renommer Groupe"
	L.MENU_DELETE_GROUP = "Supprimer Groupe"
	L.MENU_INVITE_GROUP = "Inviter Tout le Groupe"
	L.MENU_COLLAPSE_ALL = "Tout Réduire"
	L.MENU_EXPAND_ALL = "Tout Développer"
	L.MENU_SETTINGS = "Paramètres"
	L.MENU_SET_BROADCAST = "Définir Message Diffusion"
	L.MENU_IGNORE_LIST = "Gérer Liste Ignorés"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "Plus de groupes..."
	L.GROUPS_DIALOG_TITLE = "Groupes pour %s"
	L.MENU_COPY_CHARACTER_NAME = "Copier le nom du personnage"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "Copier le nom du personnage"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Lâcher pour ajouter au groupe"
	L.TOOLTIP_HOLD_SHIFT = "Maintenir Maj pour garder dans autres groupes"
	L.TOOLTIP_DRAG_HERE = "Glisser amis ici pour ajouter"
	L.TOOLTIP_ERROR = "Erreur"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "Pas de comptes de jeu disponibles"
	L.TOOLTIP_NO_INFO = "Pas assez d'infos disponibles"
	L.TOOLTIP_RENAME_GROUP = "Renommer Groupe"
	L.TOOLTIP_RENAME_DESC = "Clic pour renommer ce groupe"
	L.TOOLTIP_GROUP_COLOR = "Couleur du Groupe"
	L.TOOLTIP_GROUP_COLOR_DESC = "Clic pour changer la couleur"
	L.TOOLTIP_DELETE_GROUP = "Supprimer Groupe"
	L.TOOLTIP_DELETE_DESC = "Supprimer ce groupe et désaffecter tous les amis"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d ami(s) invité(s) au groupe."
	L.MSG_NO_FRIENDS_AVAILABLE = "Aucun ami en ligne disponible à inviter."
	L.MSG_INVITE_CONVERT_RAID = "Conversion du groupe en raid..."
	L.MSG_INVITE_RAID_FULL = "Raid complet (%d/40). Invitations arrêtées."
	L.MSG_GROUP_DELETED = "Groupe '%s' supprimé"
	L.MSG_IGNORE_LIST_EMPTY = "Votre liste d'ignorés est vide."
	L.MSG_IGNORE_LIST_COUNT = "Liste Ignorés (%d joueurs) :"
	L.MSG_MIGRATION_ALREADY_DONE = "Migration déjà effectuée. Utilisez '/bfl migrate force' pour réessayer."
	L.MSG_MIGRATION_STARTING = "Démarrage migration FriendGroups..."
	L.MSG_GROUP_ORDER_SAVED = "Ordre des groupes sauvegardé !"
	L.MSG_SETTINGS_RESET = "Paramètres réinitialisés !"
	L.MSG_EXPORT_FAILED = "Exportation échouée : %s"
	L.MSG_IMPORT_SUCCESS = "Importation réussie ! Groupes restaurés."
	L.MSG_IMPORT_FAILED = "Importation échouée : %s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "Base de données non disponible !"
	L.ERROR_SETTINGS_NOT_INIT = "Cadre non initialisé !"
	L.ERROR_MODULES_NOT_LOADED = "Modules non disponibles !"
	L.ERROR_GROUPS_MODULE = "Module Groupes non disponible !"
	L.ERROR_SETTINGS_MODULE = "Module Paramètres non disponible !"
	L.ERROR_FRIENDSLIST_MODULE = "Module FriendList non disponible"
	L.ERROR_FAILED_DELETE_GROUP = "Échec suppression groupe - modules non chargés"
	L.ERROR_FAILED_DELETE = "Échec suppression groupe : %s"
	L.ERROR_MIGRATION_FAILED = "Échec migration - modules non chargés !"
	L.ERROR_GROUP_NAME_EMPTY = "Le nom du groupe ne peut être vide"
	L.ERROR_GROUP_EXISTS = "Le groupe existe déjà"
	L.ERROR_INVALID_GROUP_NAME = "Nom de groupe invalide"
	L.ERROR_GROUP_NOT_EXIST = "Le groupe n'existe pas"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Impossible de renommer groupes intégrés"
	L.ERROR_INVALID_GROUP_ID = "ID groupe invalide"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Impossible de supprimer groupes intégrés"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Amis"
	L.GROUP_FAVORITES = "Favoris"
	L.GROUP_INGAME = "En Jeu"
	L.GROUP_NO_GROUP = "Sans Groupe"
	L.ONLINE_STATUS = "En ligne"
	L.OFFLINE_STATUS = "Hors ligne"
	L.STATUS_MOBILE = "Mobile"
	L.STATUS_IN_APP = "Dans l'application Blizzard"
	L.UNKNOWN_GAME = "Jeu Inconnu"
	L.BUTTON_ADD_FRIEND = "Ajouter Ami"
	L.BUTTON_SEND_MESSAGE = "Envoyer Msg"
	L.EMPTY_TEXT = "Vide"
	L.LEVEL_FORMAT = "Niv %d"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Fonctions Bêta"
	L.SETTINGS_BETA_FEATURES_DESC =
		"Active des fonctions expérimentales en développement. Elles peuvent changer ou être retirées."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Activer Fonctions Bêta"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Active fonctions expérimentales (Notifs, etc.)"
	L.SETTINGS_BETA_FEATURES_WARNING =
		"Attention : Les fonctions bêta peuvent contenir des bugs. À utiliser à vos risques."
	L.SETTINGS_BETA_FEATURES_LIST = "Fonctions Bêta disponibles :"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Fonctions Bêta |cff00ff00ACTIVÉES|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Fonctions Bêta |cffff0000DÉSACTIVÉES|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Onglets Bêta visibles dans Paramètres"
	L.SETTINGS_BETA_TABS_HIDDEN = "Onglets Bêta masqués"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Activer Synchro Globale d'Amis"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Synchronise votre liste d'amis WoW sur tous les personnages de ce compte."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Synchro Globale"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Activer Suppression"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC =
		"Permettre à la synchro de supprimer des amis si retirés de la base de données."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Base de Données Amis Synchronisés"

	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================

	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================

	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Taille Cadre (Mode Édition)"
	L.SETTINGS_FRAME_SIZE_INFO = "Taille par défaut préférée pour nouveaux mises en page."
	L.SETTINGS_FRAME_WIDTH = "Largeur :"
	L.SETTINGS_FRAME_HEIGHT = "Hauteur :"
	L.SETTINGS_FRAME_RESET_SIZE = "Réinit. à 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Appliquer mtn"
	L.SETTINGS_FRAME_RESET_ALL = "Réinit. toutes mises en page"

	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Amis"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Clic Gauche : Ouvrir"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Clic Droit : Paramètres"
	L.BROKER_SETTINGS_ENABLE = "Activer Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON = "Afficher Icône"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Niveau Détail Tooltip"
	L.BROKER_SETTINGS_CLICK_ACTION = "Action Clic Gauche"
	L.BROKER_SETTINGS_LEFT_CLICK = "Action Clic Gauche"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Action Clic Droit"
	L.BROKER_ACTION_TOGGLE = "Basculer BetterFriendlist"
	L.BROKER_ACTION_FRIENDS = "Ouvrir Liste Amis"
	L.BROKER_ACTION_SETTINGS = "Ouvrir Paramètres"
	L.BROKER_ACTION_OPEN_BNET = "Ouvrir App Battle.net"
	L.BROKER_ACTION_NONE = "Rien"
	L.BROKER_SETTINGS_INFO = "S'intègre avec Bazooka, ChocolateBar, TitanPanel."
	L.BROKER_FILTER_CHANGED = "Filtre changé : %s"

	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "Amis WoW"
	L.BROKER_HEADER_BNET = "Amis Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Aucun ami WoW en ligne"
	L.BROKER_NO_FRIENDS_ONLINE = "Aucun ami en ligne"
	L.BROKER_TOTAL_ONLINE = "Total : %d en ligne / %d amis"
	L.BROKER_FILTER_LABEL = "Filtre : "
	L.BROKER_SORT_LABEL = "Tri : "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Actions Ami ---"
	L.BROKER_HINT_CLICK_WHISPER = "Clic Ami :"
	L.BROKER_HINT_WHISPER = " Chuchoter • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Clic-Droit :"
	L.BROKER_HINT_CONTEXT_MENU = " Menu Contextuel"
	L.BROKER_HINT_ALT_CLICK = "Alt+Clic :"
	L.BROKER_HINT_INVITE = " Inviter/Rejoindre • "
	L.BROKER_HINT_SHIFT_CLICK = "Maj+Clic :"
	L.BROKER_HINT_COPY = " Copier dans Chat"
	L.BROKER_HINT_ICON_ACTIONS = "--- Actions Icône ---"
	L.BROKER_HINT_LEFT_CLICK = "Clic Gauche :"
	L.BROKER_HINT_TOGGLE = " Basculer Fenêtre"
	L.BROKER_HINT_RIGHT_CLICK = "Clic Droit :"
	L.BROKER_HINT_SETTINGS = " Paramètres • "
	L.BROKER_HINT_MIDDLE_CLICK = "Clic Milieu :"
	L.BROKER_HINT_CYCLE_FILTER = " Changer Filtre"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Treat Mobile as Offline
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Traiter Mobile comme Hors ligne"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Affiche les amis sur App Mobile dans le groupe Hors ligne"

	-- Feature 3: Show Notes as Name
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Afficher Notes comme Nom"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Affiche la note de l'ami au lieu de son nom"

	-- Feature 4: Window Scale
	L.SETTINGS_WINDOW_SCALE = "Échelle Fenêtre"
	L.SETTINGS_WINDOW_SCALE_DESC = "Échelle de toute la fenêtre (50%% - 200%%)"

	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Afficher Libellé 'Amis :'"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Afficher Total"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Séparer Compteurs WoW/BNet"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Config Générale"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Intégration Data Broker"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interaction"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Mode d'Emploi"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Addons Testés"
	L.BROKER_SETTINGS_INSTRUCTIONS =
		"• Installez un addon d'affichage (Bazooka, TitanPanel)\n• Activez Data Broker ci-dessus (reload requis)\n• Le bouton apparaîtra dans votre barre"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Colonnes Tooltip"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Colonnes Tooltip"
	L.BROKER_COLUMN_NAME = "Nom"
	L.BROKER_COLUMN_LEVEL = "Niveau"
	L.BROKER_COLUMN_CHARACTER = "Personnage"
	L.BROKER_COLUMN_GAME = "Jeu / App"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "Royaume"
	L.BROKER_COLUMN_FACTION = "Faction"
	L.BROKER_COLUMN_NOTES = "Notes"

	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Affiche le nom (RealID ou Perso)"
	L.BROKER_COLUMN_LEVEL_DESC = "Affiche le niveau"
	L.BROKER_COLUMN_CHARACTER_DESC = "Affiche nom et icône classe"
	L.BROKER_COLUMN_GAME_DESC = "Affiche jeu ou app"
	L.BROKER_COLUMN_ZONE_DESC = "Affiche zone actuelle"
	L.BROKER_COLUMN_REALM_DESC = "Affiche le royaume"
	L.BROKER_COLUMN_FACTION_DESC = "Affiche icône faction"
	L.BROKER_COLUMN_NOTES_DESC = "Affiche les notes"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Alliés Récents non dispo sur cette version."
	L.EDIT_MODE_NOT_AVAILABLE = "Mode Édition non dispo sur Classic. Utilisez /bfl position."
	L.CLASSIC_COMPATIBILITY_INFO = "Mode compatibilité Classic."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Fonction non dispo sur Classic."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Fermer à l'ouverture Guilde"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "Ferme la liste d'amis quand la Guilde s'ouvre"
	L.SETTINGS_HIDE_GUILD_TAB = "Masquer Onglet Guilde"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "Masque l'onglet Guilde de la liste d'amis"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "Respecter Hiérarchie UI"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Évite chevauchements avec autres fenêtres. Requiert /reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 min"
	L.LASTONLINE_MINUTES = "%d min"
	L.LASTONLINE_HOURS = "%d h"
	L.LASTONLINE_DAYS = "%d jours"
	L.LASTONLINE_MONTHS = "%d mois"
	L.LASTONLINE_YEARS = "%d ans"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "UI Guilde Classique Désactivée"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist a désactivé l'intégration Guilde Classique.\n\nL'onglet Guilde ouvrira l'interface moderne."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist : Utilisez '/bfl migrate help' pour l'aide."
	L.LOADED_MESSAGE = "BetterFriendlist chargé avec succès."
	L.DEBUG_ENABLED = "Debug ACTIVÉ"
	L.DEBUG_DISABLED = "Debug DÉSACTIVÉ"
	L.CONFIG_RESET = "Config réinitialisée."
	L.SEARCH_PLACEHOLDER = "Rechercher..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Guilde"
	L.TAB_RAID = "Raid"
	L.TAB_QUICK_JOIN = "Rejoindre"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "En ligne"
	L.FILTER_SEARCH_OFFLINE = "Hors ligne"
	L.FILTER_SEARCH_MOBILE = "Mobile"
	L.FILTER_SEARCH_AFK = "ABS"
	L.FILTER_SEARCH_DND = "Occupé"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "NPD"

	-- Groups
	L.MIGRATION_CHECK = "Vérification migration..."
	L.MIGRATION_RESULT = "%d groupes et %d affectations migrés."
	L.MIGRATION_BNET_UPDATED = "Affectations BNet mises à jour."
	L.MIGRATION_BNET_REASSIGN = "Veuillez réaffecter vos amis BNet."
	L.MIGRATION_BNET_REASON = "(Raison : bnetAccountID temporaire)"
	L.MIGRATION_WOW_RESULT = "%d affectations WoW migrées."
	L.MIGRATION_WOW_FORMAT = "(Format : Personnage-Royaume)"
	L.MIGRATION_WOW_FAIL = "Impossible de migrer (royaume manquant)."
	L.MIGRATION_SMART_MIGRATING = "Migration groupe : %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Sélection multiple effacée - entrée en combat"

	-- Quick Join
	L.LEADER_LABEL = "Chef :"
	L.MEMBERS_LABEL = "Membres :"
	L.AVAILABLE_ROLES = "Rôles Dispo"
	L.NO_AVAILABLE_ROLES = "Aucun rôle dispo"
	L.AUTO_ACCEPT_TOOLTIP = "Ce groupe acceptera automatiquement."
	L.MOCK_JOIN_REQUEST_SENT = "Demande test envoyée"
	L.QUICK_JOIN_NO_GROUPS = "Aucun groupe disponible"
	L.UNKNOWN_GROUP = "Groupe Inconnu"
	L.UNKNOWN = "Inconnu"
	L.NO_QUEUE = "Pas de File"
	L.LFG_ACTIVITY = "Activité LFG"
	L.ACTIVITY_DUNGEON = "Donjon"
	L.ACTIVITY_RAID = "Raid"
	L.ACTIVITY_PVP = "JcJ"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "Importer Config"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "Exporter Config"
	L.DIALOG_DELETE_GROUP_TITLE = "Supprimer groupe"
	L.DIALOG_RENAME_GROUP_TITLE = "Renommer groupe"
	L.DIALOG_CREATE_GROUP_TITLE = "Créer groupe"

	-- Tooltips
	L.TOOLTIP_LAST_CONTACT = "Dernier contact :"
	L.TOOLTIP_AGO = ""
	L.TOOLTIP_AGO_PREFIX = "il y a "
	L.TOOLTIP_LAST_ONLINE = "Dernière fois : %s"

	-- Notifications
	L.YES = "OUI"
	L.NO = "NON"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Aperçu %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Aperçu pour positionnement"
	L.EDITMODE_FRAME_WIDTH = "Largeur Cadre"
	L.EDITMODE_FRAME_HEIGHT = "Hauteur Cadre"

	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT = "Réinit. tous les designs ?\n\nImpossible d'annuler !"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Tout Réinit."
	L.MSG_LAYOUTS_RESET = "Designs réinitialisés. Utilisez /editmode."
	L.DIALOG_TRIGGER_TITLE = "Créer Déclencheur Groupe"
	L.DIALOG_TRIGGER_INFO = "Notifier quand X amis d'un groupe sont en ligne."
	L.DIALOG_TRIGGER_SELECT_GROUP = "Choisir Groupe :"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Min Amis En Ligne :"
	L.DIALOG_TRIGGER_CREATE = "Créer"
	L.DIALOG_TRIGGER_CANCEL = "Annuler"
	L.ERROR_SELECT_GROUP = "Sélectionnez un groupe"
	L.MSG_TRIGGER_CREATED = "Déclencheur créé : %d+ amis de '%s'"
	L.ERROR_NO_GROUPS = "Pas de groupes dispo."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Définir Surnom pour %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "Tous"
	L.FILTER_ONLINE = "En Ligne"
	L.FILTER_OFFLINE = "Hors Ligne"
	L.FILTER_WOW = "WoW"
	L.FILTER_BNET = "BNet"
	L.FILTER_HIDE_AFK = "Masquer AFK"
	L.FILTER_RETAIL = "Retail"
	L.TOOLTIP_QUICK_FILTER = "Filtre Rapide : %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Rechargement requis.\n\nRecharger ?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Recharger"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Annuler"
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Activer/Désactiver Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Afficher Icône"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "Basculer icône BetterFriendlist"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Afficher Libellé"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Basculer libellé 'Amis :'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Afficher Total"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Afficher nbre total amis"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Diviser Compteurs"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Compteurs séparés WoW/BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "Icône WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Afficher Icône WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "Icône WoW près des amis WoW"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "Icône BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Afficher Icône BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "Icône BNet près des amis BNet"
	L.BROKER_SETTINGS_CLICK_ACTION = "Action Clic"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Mode Tooltip"
	L.STATUS_ENABLED = "|cff00ff00Activé|r"
	L.STATUS_DISABLED = "|cffff0000Désactivé|r"
	L.BROKER_WOW_FRIENDS = "Amis WoW :"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Synchro Glob."
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Activer synchro amis"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Afficher Supprimés"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Afficher Amis Supprimés"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Montre les amis supprimés"
	L.TOOLTIP_RESTORE_FRIEND = "Restaurer Ami"
	L.TOOLTIP_DELETE_FRIEND = "Supprimer Ami"
	L.POPUP_EDIT_NOTE_TITLE = "Éditer Note"
	L.BUTTON_SAVE = "Sauver"
	L.BUTTON_CANCEL = "Annuler"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Amis : "
	L.BROKER_ONLINE_TOTAL = "%d en ligne / %d total"
	L.BROKER_CURRENT_FILTER = "Filtre Actuel :"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Clic Milieu : Changer Filtre"
	L.BROKER_AND_MORE = "  ... et %d plus"
	L.BROKER_WHISPER_AGO = " (chuchotement il y a %s)"
	L.BROKER_TOTAL_LABEL = "Total :"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d en ligne / %d amis"
	L.MENU_CHANGE_COLOR = "Changer Couleur"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Erreur affichage tooltip|r"
	L.STATUS_LABEL = "Statut :"
	L.STATUS_AWAY = "Absent"
	L.STATUS_DND_FULL = "Ne Pas Déranger"
	L.GAME_LABEL = "Jeu :"
	L.REALM_LABEL = "Royaume :"
	L.CLASS_LABEL = "Classe :"
	L.FACTION_LABEL = "Faction :"
	L.ZONE_LABEL = "Zone :"
	L.NOTE_LABEL = "Note :"
	L.BROADCAST_LABEL = "Diffusion :"
	L.ACTIVE_SINCE_FMT = "(Actif depuis : %s)"
	L.HINT_RIGHT_CLICK_OPTIONS = "Clic-droit pour options"
	L.HEADER_ADD_FRIEND = "|cffffd700Ajouter %s à %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Vérif migration - Total :"
	L.MIGRATION_DEBUG_BNET = "Vérif migration - BNet ancien :"
	L.MIGRATION_DEBUG_WOW = "Vérif migration - WoW sans royaume :"
	L.ERROR_INVALID_PARAMS = "Paramètres invalides"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Ne plus ignorer"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE = "Système Alliés Récents non dispo."
	L.RECENT_ALLIES_INVITE = "Inviter"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Joueur hors ligne"
	L.RECENT_ALLIES_PIN_EXPIRES = "Pin expire dans %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Niveau %d %s"
	L.RECENT_ALLIES_NOTE = "Note : %s"
	L.RECENT_ALLIES_ACTIVITY = "Activité Récente :"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Parrainez un Ami"
	L.RAF_RECRUITMENT = "Recrutement"
	L.RAF_NO_RECRUITS_DESC = "Vous n'avez pas encore parrainé d'amis."
	L.RAF_PENDING_RECRUIT = "Recrue En Attente"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Vous avez gagné :"
	L.RAF_NEXT_REWARD_AFTER = "Prochaine récomp. après %d/%d mois"
	L.RAF_FIRST_REWARD = "Première Récomp. :"
	L.RAF_NEXT_REWARD = "Prochaine Récomp. :"
	L.RAF_REWARD_MOUNT = "Monture"
	L.RAF_REWARD_TITLE_DEFAULT = "Titre"
	L.RAF_REWARD_TITLE_FMT = "Titre : %s"
	L.RAF_REWARD_GAMETIME = "Temps de Jeu"
	L.RAF_MONTH_COUNT = "%d Mois abonnés"
	L.RAF_CLAIM_REWARD = "Réclamer"
	L.RAF_VIEW_ALL_REWARDS = "Voir Tout"
	L.RAF_ACTIVE_RECRUIT = "Actif"
	L.RAF_TRIAL_RECRUIT = "Essai"
	L.RAF_INACTIVE_RECRUIT = "Inactif"
	L.RAF_OFFLINE = "Hors ligne"
	L.RAF_TOOLTIP_DESC = "Jusqu'à %d mois"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d mois"
	L.RAF_ACTIVITY_DESCRIPTION = "Activité filleul pour %s"
	L.RAF_REWARDS_LABEL = "Récompenses"
	L.RAF_YOU_EARNED_LABEL = "Gagné :"
	L.RAF_CLICK_TO_CLAIM = "Clic pour réclamer"
	L.RAF_LOADING = "Chargement..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== Récompenses Parrainage ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Actuel"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Ancien v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Mois gagnés : %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Recrues : %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Récompenses Dispo :"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Réclamé]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Réclamable]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Abordable]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Verrouillé]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d mois)"
	L.RAF_CHAT_MORE_REWARDS = "    ... et %d autres"
	L.RAF_CHAT_USE_UI = "|cff00ff00Utilisez l'interface jeu pour détails.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00Parrainage :|r Temps de jeu dispo."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "Afficher le message de bienvenue"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC =
		"Affiche le message de chargement de l'addon dans le chat lors de la connexion."
	L.SETTINGS_TAB_DATABROKER = "Data Broker"
	L.MSG_GROUP_RENAMED = "Groupe renommé à '%s'"
	L.ERROR_RENAME_FAILED = "Échec renommage"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Ordre groupes sauvé : %s"
	L.ERROR_EXPORT_SERIALIZE = "Échec sérialisation"
	L.ERROR_IMPORT_EMPTY = "Chaîne vide"
	L.ERROR_IMPORT_DECODE = "Échec décodage"
	L.ERROR_IMPORT_DESERIALIZE = "Échec désérialisation"
	L.ERROR_EXPORT_VERSION = "Version export non supportée"
	L.ERROR_EXPORT_STRUCTURE = "Structure export invalide"

	-- Statistics
	L.STATS_NO_HEALTH_DATA = "Sans données santé"
	L.STATS_NO_CLASS_DATA = "Sans données classe"
	L.STATS_NO_LEVEL_DATA = "Sans données niveau"
	L.STATS_NO_REALM_DATA = "Sans données royaume"
	L.STATS_NO_GAME_DATA = "Sans données jeu"
	L.STATS_NO_MOBILE_DATA = "Sans données mobile"
	L.STATS_SAME_REALM = "Même Roy. : %d (%d%%)  |  Autres : %d (%d%%)"
	L.STATS_TOP_REALMS = "\nTop Royaumes :"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic : %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile : %d"
	L.STATS_GAME_OTHER = "\nAutre : %d"
	L.STATS_MOBILE_DESKTOP = "PC : %d (%d%%)\nMobile : %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Avec Notes : %d (%d%%)\nFavoris : %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max (80) : %d\n70-79 : %d\n60-69 : %d\n<60 : %d\nMoyenne : %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Actif : %d (%d%%)|r\n|cffffd700Moyen : %d (%d%%)|r\n|cffffaa00Délaissé : %d (%d%%)|r\n|cffff6600Stagnant : %d (%d%%)|r\n|cffff0000Inactif : %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s : %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffAlliance : %d|r\n|cffff0000Horde : %d|r"
	L.STATS_REALM_FMT = "\n%d. %s : %d"
	L.TOOLTIP_MOVE_DOWN = "Descendre"
	L.TOOLTIP_MOVE_DOWN_DESC = "Descendre le groupe"
	L.TOOLTIP_MOVE_UP = "Monter"
	L.TOOLTIP_MOVE_UP_DESC = "Monter le groupe"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "Ami pas sur WoW"
	L.TRAVEL_PASS_WOW_CLASSIC = "Ami est sur WoW Classic."
	L.TRAVEL_PASS_WOW_MAINLINE = "Ami est sur WoW."
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Version différente"
	L.TRAVEL_PASS_NO_INFO = "Info insuffisante"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Région différente"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "Pas de comptes jeu"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Afficher Liste Blizzard"
	L.MENU_COMBAT_LOCKED = "Impossible en combat"
	L.MENU_SET_NICKNAME = "Définir Surnom"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Config BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Rechercher..."
	L.RAF_NEXT_REWARD_HELP = "Info RAF"
	L.WHO_LEVEL_FORMAT = "Niveau %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Alliés Récents"
	L.CONTACTS_MENU_NAME = "Menu Contacts"
	L.BATTLENET_UNAVAILABLE = "BNet Non Dispo"
	L.BATTLENET_BROADCAST = "Diffusion"
	L.FRIENDS_LIST_ENTER_TEXT = "Msg Diffusion..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Rechercher joueurs..."
	L.RAF_SPLASH_SCREEN_TITLE = "Parrainage"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "Parrainez vos amis !"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Info Récompenses"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Format Nom"
	L.SETTINGS_NAME_FORMAT_DESC =
		"Personnaliser affichage :\n|cffFFD100%name%|r - Nom Compte\n|cffFFD100%note%|r - Note\n|cffFFD100%nickname%|r - Surnom\n|cffFFD100%battletag%|r - BattleTag Court"
	L.SETTINGS_NAME_FORMAT_LABEL = "Format :"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Format Nom"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Entrez une chaîne de format."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"Ce paramètre est désactivé car l'addon 'FriendListColors' gère les couleurs/formats de noms."

	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "Groupe 'En Jeu'"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Groupe auto amis en jeu"
	L.SETTINGS_INGAME_MODE_WOW = "WoW Uniq. (Même Version)"
	L.SETTINGS_INGAME_MODE_ANY = "Tout Jeu"
	L.SETTINGS_INGAME_MODE_LABEL = "   Mode :"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Mode Groupe En Jeu"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Choisir quels amis inclure."

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Options Affichage"
	L.SETTINGS_BEHAVIOR_HEADER = "Comportement"
	L.SETTINGS_GROUP_MANAGEMENT = "Gestion Groupes"
	L.SETTINGS_FONT_SETTINGS = "Réglages Police"
	L.SETTINGS_GROUP_ORDER = "Ordre Groupes"
	L.SETTINGS_MIGRATION_HEADER = "Migration FriendGroups"
	L.SETTINGS_MIGRATION_DESC = "Migrer depuis FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migrer"
	L.SETTINGS_MIGRATE_TOOLTIP = "Importer"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "Partager config."
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Attention : Import remplace TOUT !|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Exporter"
	L.SETTINGS_IMPORT_TOOLTIP = "Importer"

	-- Statistics
	L.STATS_HEADER = "Statistiques"
	L.STATS_DESC = "Résumé du réseau"
	L.STATS_OVERVIEW_HEADER = "Résumé"
	L.STATS_HEALTH_HEADER = "Santé"
	L.STATS_CLASSES_HEADER = "Top 5 Classes"
	L.STATS_REALMS_HEADER = "Royaumes"
	L.STATS_ORGANIZATION_HEADER = "Organisation"
	L.STATS_LEVELS_HEADER = "Niveaux"
	L.STATS_GAMES_HEADER = "Jeu"
	L.STATS_MOBILE_HEADER = "Mobile vs PC"
	L.STATS_FACTIONS_HEADER = "Factions"
	L.STATS_REFRESH_BTN = "Rafraîchir"
	L.STATS_REFRESH_TOOLTIP = "Mettre à jour"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters

	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Masque groupes vides"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Affiche icônes faction"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Affiche nom royaume"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Griser faction opposée"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Mobile comme AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Masque niveau si max"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Affiche bouton Blizzard"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Visibilité Favoris"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "Un seul groupe ouvert"
	L.SETTINGS_COMPACT_MODE_DESC = "Boutons compacts"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Activer Skin ElvUI"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Requiert ElvUI."
	L.DIALOG_ELVUI_RELOAD_TEXT = "Rechargement requis.\nRecharger ?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Oui"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "Non"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "BD non init."
	L.CORE_SHOW_BLIZZARD_ENABLED = "Option Blizzard |cff20ff20ON|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Option Blizzard |cffff0000OFF|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Debug non dispo"
	L.CORE_DB_MODULE_NOT_AVAIL = "Module BD non dispo"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Suivi Activité ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Amis actifs : %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "Fonctions Bêta désactivées !"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Activer :|r ECHAP > AddOns > BetterFriendlist"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Stats non chargées"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Statistiques ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Résumé :|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE =
		"  Total : |cffffffff%d|r  On : |cff00ff00%d|r (%.0f%%)  Off : |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet : |cff0099ff%d|r  |  WoW : |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Santé :|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Actif : |cff00ff00%d|r (%.0f%%)  Moyen : |cffffd700%d|r (%.0f%%)"
	L.CORE_STATS_HEALTH_STALE = "  Stagnant : |cffff6600%d|r (%.0f%%)  Dormant : |cffff0000%d|r (%.0f%%)"
	L.CORE_STATS_NO_HEALTH_DATA = "  Sans données"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Classes :|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Niveaux :|r"
	L.CORE_STATS_LEVEL_BREAKDOWN =
		"  Max : |cffffffff%d|r  70+ : |cffffffff%d|r  60+ : |cffffffff%d|r  <60 : |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Moyenne : |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Royaumes :|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Même : |cffffffff%d|r  |  Autre : |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Top :"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Factions :|r"
	L.CORE_STATS_FACTION_DATA = "  Alliance : |cff0080ff%d|r  |  Horde : |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Jeu :|r"
	L.CORE_STATS_GAME_WOW = "  Retail : |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic : |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4 : |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS : |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC : |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  App : |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Autres : |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Mobile vs PC :|r"
	L.CORE_STATS_MOBILE_DATA = "  PC : |cffffffff%d|r (%.0f%%)  Mobile : |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Orga :|r"
	L.CORE_STATS_ORG_DATA = "  Notes : |cffffffff%d|r  Fav : |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Config non chargée"
	L.CORE_MOCK_INVITES_ENABLED = "Inv. Test |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Ajout inv. test |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Astuce :|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Inv. test effacées"
	L.CORE_NO_MOCK_INVITES = "Sans inv. test"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Monitor non chargé"
	L.CORE_MEMORY_USAGE = "Mémoire : %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "QuickJoin non chargé"
	L.CORE_RAIDFRAME_NOT_LOADED = "RaidFrame non chargé"
	L.CORE_PREVIEW_MODE_NOT_LOADED = "PreviewMode non chargé"
	L.CORE_ACTIVITY_TEST_NOT_LOADED = "ActivityTests non chargé"
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Compat. Classic ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Version Client :|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Type Détecté :|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00The War Within|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffffRetail|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Disponibilité :|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox : %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menú Moderne : %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Alliés Récents : %s"
	L.CORE_FEATURE_EDIT_MODE = "  Mode Édition : %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown Moderne : %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker Moderne : %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Couche Compat :|r %s"
	L.CORE_COMPAT_ACTIVE = "|cff00ff00Actif|r"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000Non Chargé|r"
	L.CORE_CHANGELOG_RESET = "Changelog reset."
	L.CORE_CHANGELOG_NOT_LOADED = "Changelog non chargé"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Debug UI Panel ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard FriendsFrame :|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000Pas de config stockée|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00BetterFriendsFrame attrs :|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00Dans UIPanelWindows :|r |cff00ff00OUI|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00Dans UIPanelWindows :|r |cffff0000NON|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800AVIS :|r FriendsFrame encore dans UIPanelWindows !"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Config Actuelle :|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BetterFriendlist v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Commandes :|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Basculer fenêtre"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/bfl settings|r - Ouvrir config"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/bfl help|r - Aide"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Ouvrir le journal des changements"
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - Réinit. position fenêtre"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Debug :|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/bfl debug|r - Basculer debug"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Voir BD"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Voir activité"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Voir stats"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Test règles"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join :|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Données test"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Donjon"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Raid"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Stress test"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - Sim évènements"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Nettoyer test"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - Lister groupes"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock :|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Créer Raid test"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Ajouter invite"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Nettoyer invites"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Mode Preview :|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - Activer"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Désactiver"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Données fausses pour screenshots)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame :|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - Créer 25j"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - Créer 40j"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - Créer 10j"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - Créer 20j"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - Sim ReadyCheck"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Sim Role"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Sim Mouvement"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Nettoyer"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Performances :|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Afficher stats"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Activer"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Reset"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Mémoire"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Tests :|r"
	L.CORE_HELP_TEST_ACTIVITY = "  |cffffffff/bfl test|r - Tests Activité"
	L.TESTSUITE_PERFY_HELP = "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"
	L.TESTSUITE_PERFY_STARTING = "Starting Perfy stress test for %d seconds"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Perfy stress test already running"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Perfy addon not loaded (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Perfy slash command not available"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy stress action failed: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy stress test finished"
	L.TESTSUITE_PERFY_ABORTED = "Perfy stress test stopped: %s"
	L.CORE_HELP_LINK = "|cff20ff20Aide :|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Chargé. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Accepté inv. test %s"
	L.MOCK_INVITE_DECLINED = "Refusé inv. test %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Stats reset"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Rapport Performance ===|r"
	L.PERF_QJ_OPS = "|cffffd700Opérations QuickJoin :|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Opérations Amis :|r"
	L.PERF_MEMORY = "|cffffd700Utilisation Mémoire :|r"
	L.PERF_TARGETS = "|cffffd700Cibles :|r"
	L.PERF_AUTO_ENABLED = "Auto-monitor |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Créé raid 25j"
	L.RAID_MOCK_CREATED_40 = "Créé raid 40j"
	L.RAID_MOCK_CREATED_10 = "Créé raid 10j"
	L.RAID_MOCK_CREATED_MYTHIC = "Créé raid 20j (Mythique)"
	L.RAID_MOCK_STRESS = "Stress test : 40j rapide"
	L.RAID_WARN_CPU = "|cffff8800Avis :|r Usage CPU élevé prévu"
	L.RAID_NO_MOCK_DATA = "Pas de données test. '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Simulation Ready Check..."
	L.RAID_MOCK_CLEARED = "Données test effacées"
	L.RAID_EVENT_COMMANDS = "|cff00ff00Commandes Évents Raid :|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Gestion :|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Configurer mock"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - Lister info"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Stress test"
	L.RAID_HELP_EVENTS = "|cffffcc00Simulation :|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Config Raid :|r"
	L.RAID_INFO_HEADER = "|cff00ff00Info Mock Raid :|r"
	L.RAID_NO_MOCK_ACTIVE = "Pas de mock actif"
	L.RAID_DYN_UPDATES = "Mises à jour dyn : %s"
	L.RAID_UPDATE_INTERVAL = "Intervalle : %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Mock actif : %s"
	L.RAID_DYN_UPDATES_STATUS = "  Dyn : %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Intervalle : %.1f s"
	L.RAID_MEMBERS_STATUS = "  Membres : %d"
	L.RAID_TOTAL_MEMBERS = "  Total : %d"
	L.RAID_COMPOSITION = "  Comp : %d T, %d H, %d D"
	L.RAID_STATUS = "  Statut : %d off, %d mort"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Créé groupes test icônes"
	L.QJ_MOCK_CREATED_STRESS = "Créé 50 groupes test"
	L.QJ_SIM_ADDED = "Sim : Groupe ajouté"
	L.QJ_SIM_REMOVED = "Sim : Groupe supprimé"
	L.QJ_ERR_NO_GROUPS_REMOVE = "Pas de groupes à supprimer"
	L.QJ_ERR_NO_GROUPS_UPDATE = "Pas de groupes à mettre à jour"
	L.QJ_EVENT_COMMANDS = "|cff00ff00Commandes Évents QJ :|r"
	L.QJ_LIST_HEADER = "|cff00ff00Groupes QJ Mock :|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00Config QJ :|r"
	L.QJ_EXT_FOOTER = "|cff888888Mock en vert.|r"
	L.QJ_SIM_UPDATED_FMT = "Sim : %s mis à jour"
	L.QJ_ADDED_GROUP_FMT = "Ajouté : %s"
	L.QJ_NO_GROUPS_HINT = "Pas de groupes mock."
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Test icônes"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config :|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Configurer"

	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Reset avertissement Guilde. Reload."
	L.CMD_RESET_HEADER = "Commandes Reset :"
	L.CMD_RESET_HELP_WARNING = "Reset avertissement Guilde"

	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "   GitHub Issues"
	L.CHANGELOG_SUPPORT = "   Support"
	L.CHANGELOG_HEADER_COMMUNITY = "Communauté et Support :"
	L.CHANGELOG_HEADER_VERSION = "Version %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "Nouvelle Mise à Jour !"
	L.CHANGELOG_TOOLTIP_CLICK = "Clic pour voir les Changements"
	L.CHANGELOG_POPUP_DISCORD = "Rejoindre Discord"
	L.CHANGELOG_POPUP_GITHUB = "Signaler Bugs"
	L.CHANGELOG_POPUP_SUPPORT = "Soutenir Développement"
	L.CHANGELOG_TITLE = "Changements BetterFriendlist"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Niveau Max"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Groupe %d"
	L.RAID_CONVERT_TO_PARTY = "Convertir en Groupe"
	L.RAID_CONVERT_TO_RAID = "Convertir en Raid"
	L.RAID_MUST_BE_LEADER = "Vous devez être chef pour faire cela"
	L.RAID_CONVERT_TOO_MANY = "Le groupe compte trop de joueurs pour un groupe"
	L.RAID_ERR_NOT_IN_GROUP = "Vous n'êtes pas dans un groupe"

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6ms = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3ms = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Alerte Perf"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf :|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver. Jeu :|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Mobile"
	L.RAF_RECRUITMENT = "Parrainage"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Colore les noms d'amis dans leur couleur de classe"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Contour Police"
	L.SETTINGS_FONT_SHADOW = "Ombre Police"
	L.SETTINGS_FONT_OUTLINE_NONE = "Aucun"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Contour"
	L.SETTINGS_FONT_OUTLINE_THICK = "Contour Épais"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Monochrome"
	L.SETTINGS_GROUP_COUNT_COLOR = "Couleur Compteur"
	L.SETTINGS_GROUP_ARROW_COLOR = "Couleur Flèche"
	L.TOOLTIP_EDIT_NOTE = "Modifier la note"
	L.MENU_SHOW_SEARCH = "Afficher la recherche"
	L.MENU_QUICK_FILTER = "Filtre rapide"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Activer l'Icône Favori"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "Affiche une icône étoile sur le bouton ami pour les favoris."
	L.SETTINGS_FAVORITE_ICON_STYLE = "Icône de favori"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC = "Choisissez quelle icône est utilisée pour les favoris."
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "Icône BFL"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "Icône Blizzard"
	L.SETTINGS_SHOW_FACTION_BG = "Afficher Fond de Faction"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "Affiche la couleur de la faction comme fond pour le bouton ami."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "Raid"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "Activer Raccourcis"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"Active ou désactive tous les raccourcis souris personnalisés sur la fenêtre de raid."
	L.SETTINGS_RAID_SHORTCUTS_TITLE = "Raccourcis Raid"
	L.SETTINGS_RAID_ACTION_MASS_MOVE = "Déplacement Masse"
	L.SETTINGS_RAID_ACTION_MAIN_TANK = "Définir Tank Principal"
	L.SETTINGS_RAID_ACTION_MAIN_ASSIST = "Définir Assistant Principal"
	L.SETTINGS_RAID_ACTION_RAID_LEAD = "Définir Chef de Raid"
	L.SETTINGS_RAID_ACTION_PROMOTE = "Promouvoir Assistant"
	L.SETTINGS_RAID_ACTION_TARGET = "Cibler Unité"
	L.SETTINGS_RAID_ACTION_DEMOTE = "Rétrograder Assistant"
	L.SETTINGS_RAID_ACTION_KICK = "Retirer du Groupe"
	L.SETTINGS_RAID_ACTION_INVITE = "Inviter au Groupe"
	L.SETTINGS_RAID_MODIFIER_NONE = "Aucun"
	L.SETTINGS_RAID_MODIFIER_SHIFT = "Maj"
	L.SETTINGS_RAID_MODIFIER_CTRL = "Ctrl"
	L.SETTINGS_RAID_MODIFIER_ALT = "Alt"
	L.SETTINGS_RAID_MOUSE_LEFT = "Clic Gauche"
	L.SETTINGS_RAID_MOUSE_RIGHT = "Clic Droit"
	L.SETTINGS_RAID_MOUSE_MIDDLE = "Clic Milieu"

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "Mode Streamer"
	L.STREAMER_MODE_DESC = "Options de confidentialité pour la diffusion en direct."
	L.SETTINGS_ENABLE_STREAMER_MODE = "Afficher le Bouton Mode Streamer"
	L.STREAMER_MODE_ENABLE_DESC = "Affiche un bouton dans le cadre principal pour basculer le Mode Streamer."
	L.STREAMER_MODE_HIDDEN_NAME = "Format de Nom Masqué"
	L.STREAMER_MODE_HEADER_TEXT = "Texte d'En-tête Personnalisé"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"Texte à afficher dans l'en-tête Battle.net lorsque le Mode Streamer est actif (p. ex., 'Mode Direct')."
	L.STREAMER_MODE_BUTTON_TOOLTIP = "Basculer le Mode Streamer"
	L.STREAMER_MODE_BUTTON_DESC = "Cliquez pour activer/désactiver le mode confidentiel."
	L.SETTINGS_PRIVACY_OPTIONS = "Options de Confidentialité"
	L.SETTINGS_STREAMER_NAME_FORMAT = "Valeurs de Nom"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC = "Choisissez comment les noms s'affichent en Mode Streamer."
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "Forçer BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME = "Forçer Surnom"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "Forçer Note"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "Utiliser Couleur d'En-tête Violette"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"Change le fond de l'en-tête Battle.net en violet Twitch lorsque le Mode Streamer est actif."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26) - PARTIAL
	-- ========================================
	L.SETTINGS_RAID_DESC = "Configurez les raccourcis souris pour la gestion des raids et des groupes."
	L.SETTINGS_RAID_MODIFIER_LABEL = "Mod :"
	L.SETTINGS_RAID_BUTTON_LABEL = "Btn :"
	L.SETTINGS_RAID_WARNING = "Remarque : Les raccourcis sont des actions sécurisées (hors combat uniquement)."
	L.SETTINGS_RAID_ERROR_RESERVED = "Cette combinaison est réservée."

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "Dimensions de la Fenêtre"
	L.SETTINGS_FRAME_SCALE = "Échelle:"
	L.SETTINGS_FRAME_WIDTH = "Largeur:"
	L.SETTINGS_FRAME_HEIGHT = "Hauteur:"
	L.SETTINGS_FRAME_WIDTH_DESC = "Ajuste la largeur de la fenêtre"
	L.SETTINGS_FRAME_HEIGHT_DESC = "Ajuste la hauteur de la fenêtre"
	L.SETTINGS_FRAME_SCALE_DESC = "Ajuste l'échelle de la fenêtre"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "Alignement de l'En-tête du Groupe"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC = "Définit l'alignement du texte du nom du groupe"
	L.SETTINGS_ALIGN_LEFT = "Gauche"
	L.SETTINGS_ALIGN_CENTER = "Centre"
	L.SETTINGS_ALIGN_RIGHT = "Droite"
	L.SETTINGS_SHOW_GROUP_ARROW = "Afficher la Flèche de Réduction"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC = "Affiche ou masque l'icône de flèche pour réduire les groupes"
	L.SETTINGS_GROUP_ARROW_ALIGN = "Alignement de la Flèche de Réduction"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC = "Défini l'alignement de l'icône de flèche dérouler/réduire"
	L.SETTINGS_FONT_FACE = "Police"
	L.SETTINGS_COLOR_GROUP_COUNT = "Couleur du Compteur de Groupe"
	L.SETTINGS_COLOR_GROUP_ARROW = "Couleur de la Flèche de Réduction"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Hériter de la Couleur du Groupe"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Hériter de la Couleur du Groupe"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Paramètres de l'En-tête du Groupe"
	L.SETTINGS_GROUP_FONT_HEADER = "Police de l'En-tête du Groupe"
	L.SETTINGS_GROUP_COLOR_HEADER = "Couleurs de l'En-tête du Groupe"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clic droit pour hériter du Groupe"
	L.SETTINGS_INHERIT_TOOLTIP = "(Hérité du Groupe)"

	-- Misc
	L.TOOLTIP_AGO_PREFIX = ""
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "Liste Globale Ignorée"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "Paramètres du Nom de l'Ami"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "Paramètres d'Information de l'Ami"
	L.SETTINGS_FONT_TABS_TITLE = "Texte des Onglets"
	L.SETTINGS_FONT_RAID_TITLE = "Texte du Nom du Raid"
	L.SETTINGS_FONT_SIZE_NUM = "Taille de la Police"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "Synchronisation des notes de groupe"
	L.SETTINGS_SYNC_GROUPS_NOTE = "Synchroniser les groupes dans les notes d'amis"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"Ecrit les affectations de groupe dans les notes d'amis au format FriendGroups (Note#Groupe1#Groupe2). Permet de partager les groupes entre comptes ou avec les utilisateurs de FriendGroups."
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"Activer la synchronisation des notes de groupe ?\n\n|cffff8800Attention :|r Les notes BattleNet sont limitees a 127 caracteres, les notes d'amis WoW a 48 caracteres. Les groupes depassant la limite seront ignores dans la note mais resteront dans la base de donnees.\n\nLes notes existantes seront mises a jour. Continuer ?"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "Activer"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "Annuler"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"La synchronisation des notes de groupe a ete desactivee.\n\nVoulez-vous ouvrir l'Assistant de Nettoyage des Notes pour supprimer les suffixes de groupe de vos notes d'amis ?"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "Ouvrir l'Assistant"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "Conserver les Notes"
	L.MSG_SYNC_GROUPS_STARTED = "Synchronisation des groupes dans les notes d'amis..."
	L.MSG_SYNC_GROUPS_COMPLETE = "Synchronisation terminee. Mis a jour : %d, Ignores (limite) : %d"
	L.MSG_SYNC_GROUPS_PROGRESS = "Synchronisation des notes : %d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT = "Limite de note atteinte pour %s - certains groupes ignores"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "Assistant de Nettoyage des Notes"
	L.WIZARD_DESC =
		"Supprimez les donnees FriendGroups (#Groupe1#Groupe2) des notes d'amis. Verifiez les notes nettoyees avant d'appliquer."
	L.WIZARD_BTN = "Nettoyage des Notes"
	L.WIZARD_BTN_TOOLTIP = "Ouvrir l'assistant pour nettoyer les donnees FriendGroups des notes d'amis"
	L.WIZARD_HEADER = "Nettoyage des Notes"
	L.WIZARD_HEADER_DESC =
		"Supprimez les suffixes FriendGroups des notes d'amis. Sauvegardez d'abord, puis verifiez et appliquez les modifications."
	L.WIZARD_COL_ACCOUNT = "Nom de Compte"
	L.WIZARD_COL_BATTLETAG = "BattleTag"
	L.WIZARD_COL_NOTE = "Note Actuelle"
	L.WIZARD_COL_CLEANED = "Note Nettoyee"
	L.WIZARD_SEARCH_PLACEHOLDER = "Rechercher..."
	L.WIZARD_BACKUP_BTN = "Sauvegarder les Notes"
	L.WIZARD_BACKUP_DONE = "Sauvegarde effectuee !"
	L.WIZARD_BACKUP_TOOLTIP = "Enregistrer toutes les notes d'amis actuelles dans la base de donnees comme sauvegarde."
	L.WIZARD_BACKUP_SUCCESS = "Notes sauvegardees pour %d amis."
	L.WIZARD_APPLY_BTN = "Appliquer le Nettoyage"
	L.WIZARD_APPLY_TOOLTIP =
		"Reecrire les notes nettoyees. Seules les notes differentes de l'original seront mises a jour."
	L.WIZARD_APPLY_CONFIRM =
		"Appliquer les notes nettoyees a tous les amis ?\n\n|cffff8800Les notes actuelles seront ecrasees. Assurez-vous d'avoir cree une sauvegarde !|r"
	L.WIZARD_APPLY_SUCCESS = "%d notes mises a jour avec succes."
	L.WIZARD_APPLY_PROGRESS_FMT = "Progression : %d/%d | %d reussis | %d echoues"
	L.WIZARD_STATUS_FMT = "Affichage de %d sur %d amis | %d avec donnees de groupe | %d modifications en attente"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "Voir la sauvegarde"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"Ouvrir le visualiseur de sauvegarde pour voir toutes les notes sauvegardees et les comparer avec les notes actuelles."
	L.WIZARD_BACKUP_VIEWER_TITLE = "Visualiseur de sauvegarde"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"Consultez vos notes d'amis sauvegardees et comparez-les avec les notes actuelles. Vous pouvez restaurer les notes originales si necessaire."
	L.WIZARD_COL_BACKED_UP = "Note sauvegardee"
	L.WIZARD_COL_CURRENT = "Note actuelle"
	L.WIZARD_RESTORE_BTN = "Restaurer la sauvegarde"
	L.WIZARD_RESTORE_TOOLTIP =
		"Restaure les notes originales depuis la sauvegarde. Seules les notes differentes de la sauvegarde seront mises a jour."
	L.WIZARD_RESTORE_CONFIRM =
		"Restaurer toutes les notes depuis la sauvegarde ?\n\n|cffff8800Cela ecrasera les notes actuelles avec les versions sauvegardees.|r"
	L.WIZARD_RESTORE_SUCCESS = "%d notes restaurees avec succes."
	L.WIZARD_NO_BACKUP =
		"Aucune sauvegarde trouvee. Utilisez d'abord l'Assistant de nettoyage des notes pour en creer une."
	L.WIZARD_BACKUP_STATUS_FMT = "Affichage de %d sur %d entrees | %d modifiees depuis la sauvegarde | Sauvegarde : %s"
end)
