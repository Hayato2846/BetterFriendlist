-- Locales/esES.lua
-- Spanish (EU) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("esES", function()
local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC = "Disables the player portrait, hides search/sort options, widens the frame, and shifts tabs for a compact layout."
	L.MENU_CHANGELOG = "Changelog"
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Introduce un nombre para el nuevo grupo:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Crear"
	L.DIALOG_CREATE_GROUP_BTN2 = "Cancelar"
	L.DIALOG_RENAME_GROUP_TEXT = "Introduce un nuevo nombre para el grupo:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Renombrar"
	L.DIALOG_RENAME_GROUP_BTN2 = "Cancelar"
	L.DIALOG_DELETE_GROUP_TEXT = "¿Estás seguro de que quieres eliminar este grupo?\n\n|cffff0000Esto eliminará todos los amigos de este grupo.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Eliminar"
	L.DIALOG_DELETE_GROUP_BTN2 = "Cancelar"
	L.DIALOG_DELETE_GROUP_SETTINGS = "¿Eliminar grupo '%s'?\n\nTodos los amigos serán desasignados de este grupo."
	L.DIALOG_RESET_SETTINGS_TEXT = "¿Restablecer todos los ajustes a los valores predeterminados?"
	L.DIALOG_RESET_BTN1 = "Restablecer"
	L.DIALOG_RESET_BTN2 = "Cancelar"
	L.DIALOG_UI_PANEL_RELOAD_TEXT = "Cambiar la configuración de jerarquía de IU requiere recargar la interfaz.\n\n¿Recargar ahora?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Recargar"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Cancelar"
	L.MSG_RELOAD_REQUIRED = "Se requiere recargar para aplicar este cambio correctamente en Classic."
	L.MSG_RELOAD_NOW = "¿Recargar IU ahora?"
	L.RAID_HELP_TITLE = "Ayuda de Lista de Banda"
	L.RAID_HELP_TEXT = "Haz clic para obtener ayuda sobre el uso de la lista de banda."
	L.RAID_HELP_MULTISELECT_TITLE = "Selección Múltiple"
	L.RAID_HELP_MULTISELECT_TEXT = "Mantén Ctrl y haz clic izquierdo para seleccionar varios jugadores.\nUna vez seleccionados, arrástralos a cualquier grupo para moverlos a la vez."
	L.RAID_HELP_MAINTANK_TITLE = "Tanque Principal"
	L.RAID_HELP_MAINTANK_TEXT = "Mayús + Clic Derecho en un jugador para establecerlo como Tanque Principal.\nAparecerá un icono de tanque junto a su nombre."
	L.RAID_HELP_MAINASSIST_TITLE = "Asistente Principal"
	L.RAID_HELP_MAINASSIST_TEXT = "Ctrl + Clic Derecho en un jugador para establecerlo como Asistente Principal.\nAparecerá un icono de asistente junto a su nombre."
	L.RAID_HELP_DRAGDROP_TITLE = "Arrastrar y Soltar"
	L.RAID_HELP_DRAGDROP_TEXT = "Arrastra a cualquier jugador para moverlo entre grupos.\nTambién puedes arrastrar varios jugadores seleccionados a la vez.\nLos huecos vacíos se pueden usar para intercambiar posiciones."
	L.RAID_HELP_COMBAT_TITLE = "Bloqueo en Combate"
	L.RAID_HELP_COMBAT_TEXT = "Los jugadores no se pueden mover durante el combate.\nEsta es una restricción de Blizzard para evitar errores."
	L.RAID_INFO_UNAVAILABLE = "Info no disponible"
	L.RAID_NOT_IN_RAID = "No estás en banda"
	L.RAID_NOT_IN_RAID_DETAILS = "No estás actualmente en un grupo de banda."
	L.RAID_CREATE_BUTTON = "Crear Banda"
	L.GROUP = "Grupo"
	L.ALL = "Todos"
	L.UNKNOWN_ERROR = "Error desconocido"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "No hay suficiente espacio: %d jugadores seleccionados, %d huecos libres en el Grupo %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Se movieron %d jugadores al Grupo %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Fallo al mover %d jugadores"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "Debes ser líder de banda o asistente para iniciar una comprobación de listos."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "No tienes instancias de banda guardadas."
	L.RAID_ERROR_LOAD_RAID_INFO = "Error: No se pudo cargar la ventana de Info de Banda."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s intercambiados"
	L.RAID_ERROR_SWAP_FAILED = "Intercambio fallido: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s movido al Grupo %d"
	L.RAID_ERROR_MOVE_FAILED = "Movimiento fallido: %s"
	L.DIALOG_MIGRATE_TEXT = "¿Migrar grupos de amigos de FriendGroups a BetterFriendlist?\n\nEsto hará:\n• Crear todos los grupos a partir de las notas de BNet\n• Asignar amigos a sus grupos\n• Opcionalmente limpiar las notas\n\n|cffff0000Advertencia: ¡Esto no se puede deshacer!|r"
	L.DIALOG_MIGRATE_BTN1 = "Migrar y Limpiar Notas"
	L.DIALOG_MIGRATE_BTN2 = "Solo Migrar"
	L.DIALOG_MIGRATE_BTN3 = "Cancelar"
	
	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "General"
	L.SETTINGS_TAB_FONTS = "Fonts"
	L.SETTINGS_TAB_GROUPS = "Grupos"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Heredar color del grupo"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Heredar color del grupo"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clic derecho para heredar del grupo"
	L.SETTINGS_INHERIT_TOOLTIP = "(Heredado del grupo)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "Apariencia"
	L.SETTINGS_TAB_ADVANCED = "Avanzado"
	L.SETTINGS_ADVANCED_DESC = "Opciones avanzadas y herramientas"
	L.SETTINGS_TAB_STATISTICS = "Estadísticas"
	L.SETTINGS_SHOW_BLIZZARD = "Mostrar opción de Lista de Amigos de Blizzard"
	L.SETTINGS_COMPACT_MODE = "Modo Compacto"
	L.SETTINGS_LOCK_WINDOW = "Bloquear ventana"
	L.SETTINGS_LOCK_WINDOW_DESC = "Bloquea la ventana para evitar movimientos accidentales."
	L.SETTINGS_FONT_SIZE = "Tamaño de Fuente"
	L.SETTINGS_FONT_COLOR = "Color de fuente"
	L.SETTINGS_FONT_SIZE_SMALL = "Pequeña (Compacta, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normal (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Grande (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Colorear Nombres de Clase"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Ocultar Grupos Vacíos"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Recuento en Cabeceras de Grupo"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Elige cómo se muestran los recuentos de amigos en las cabeceras"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Filtrados / Total (Por defecto)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "Conectados / Total"
	L.SETTINGS_HEADER_COUNT_BOTH = "Filtrados (Conectados) / Total"
	L.SETTINGS_SHOW_FACTION_ICONS = "Mostrar Iconos de Facción"
	L.SETTINGS_SHOW_REALM_NAME = "Mostrar Nombre del Reino"
	L.SETTINGS_GRAY_OTHER_FACTION = "Atenuar Otra Facción"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Mostrar Móvil como Ausente (AFK)"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Mostrar Texto de Móvil"
	L.SETTINGS_HIDE_MAX_LEVEL = "Ocultar Nivel Máximo"
	L.SETTINGS_ACCORDION_GROUPS = "Grupos en Acordeón (uno abierto a la vez)"
	L.SETTINGS_SHOW_FAVORITES = "Mostrar Grupo Favoritos"
	L.SETTINGS_GROUP_COLOR = "Color del Grupo"
	L.SETTINGS_RENAME_GROUP = "Renombrar Grupo"
	L.SETTINGS_DELETE_GROUP = "Borrar Grupo"
	L.SETTINGS_DELETE_GROUP_DESC = "Eliminar este grupo y desasignar todos los amigos"
	L.SETTINGS_EXPORT_TITLE = "Exportar Configuración"
	L.SETTINGS_EXPORT_INFO = "Copia el texto de abajo y guárdalo. Puedes importarlo en otro personaje o cuenta."
	L.SETTINGS_EXPORT_BTN = "Seleccionar Todo"
L.BUTTON_EXPORT = "Exportar"
	L.SETTINGS_IMPORT_TITLE = "Importar Configuración"
	L.SETTINGS_IMPORT_INFO = "Pega tu cadena de exportación abajo y haz clic en Importar.\n\n|cffff0000Advertencia: ¡Esto reemplazará TODOS tus grupos y asignaciones!|r"
	L.SETTINGS_IMPORT_BTN = "Importar"
	L.SETTINGS_IMPORT_CANCEL = "Cancelar"
	L.SETTINGS_RESET_DEFAULT = "Restablecer a Predeterminados"
	L.SETTINGS_RESET_SUCCESS = "¡Configuración restablecida!"
	L.SETTINGS_GROUP_ORDER_SAVED = "¡Orden de grupos guardado!"
	L.SETTINGS_MIGRATION_COMPLETE = "¡Migración Completada!"
	L.SETTINGS_MIGRATION_FRIENDS = "Amigos procesados:"
	L.SETTINGS_MIGRATION_GROUPS = "Grupos creados:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Asignaciones realizadas:"
	L.SETTINGS_NOTES_CLEANED = "¡Notas limpiadas!"
	L.SETTINGS_NOTES_PRESERVED = "Notas conservadas (puedes limpiarlas manualmente)."
	L.SETTINGS_EXPORT_SUCCESS = "¡Exportación completa! Copia el texto del diálogo."
	L.SETTINGS_IMPORT_SUCCESS = "¡Importación exitosa! Todos los grupos y asignaciones han sido restaurados."
	L.SETTINGS_IMPORT_FAILED = "¡Error en la Importación!\n\n"
	L.STATS_TOTAL_FRIENDS = "Total Amigos: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00Conectados: %d (%d%%)|r  |  |cff808080Desconectados: %d (%d%%)|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"
	
	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Solicitudes de Amistad (%d)"
	L.INVITE_BUTTON_ACCEPT = "Aceptar"
	L.INVITE_BUTTON_DECLINE = "Rechazar"
	L.INVITE_TAP_TEXT = "Toca para aceptar o rechazar"
	L.INVITE_MENU_DECLINE = "Rechazar"
	L.INVITE_MENU_REPORT = "Reportar Jugador"
	L.INVITE_MENU_BLOCK = "Bloquear Invitaciones"
	
	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Todos los Amigos"
	L.FILTER_ONLINE_ONLY = "Solo Conectados"
	L.FILTER_OFFLINE_ONLY = "Solo Desconectados"
	L.FILTER_WOW_ONLY = "Solo WoW"
	L.FILTER_BNET_ONLY = "Solo Battle.net"
	L.FILTER_HIDE_AFK = "Ocultar AFK/ND"
	L.FILTER_RETAIL_ONLY = "Solo Retail"
	L.FILTER_TOOLTIP = "Filtro Rápido: %s"
	L.SORT_STATUS = "Estado"
	L.SORT_NAME = "Nombre (A-Z)"
	L.SORT_LEVEL = "Nivel"
	L.SORT_ZONE = "Zona"
	L.SORT_ACTIVITY = "Actividad Reciente"
	L.SORT_GAME = "Juego"
	L.SORT_FACTION = "Facción"
	L.SORT_GUILD = "Hermandad"
	L.SORT_CLASS = "Clase"
	L.SORT_REALM = "Reino"
	L.SORT_CHANGED = "Orden cambiado a: %s"
	L.SORT_NONE = "Ninguno"
	
	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Grupos"
	L.MENU_CREATE_GROUP = "Crear Grupo"
	L.MENU_REMOVE_ALL_GROUPS = "Eliminar de Todos los Grupos"
	L.MENU_RENAME_GROUP = "Renombrar Grupo"
	L.MENU_DELETE_GROUP = "Borrar Grupo"
	L.MENU_INVITE_GROUP = "Invitar Todos a Grupo"
	L.MENU_COLLAPSE_ALL = "Contraer Todos los Grupos"
	L.MENU_EXPAND_ALL = "Expandir Todos los Grupos"
	L.MENU_SETTINGS = "Configuración"
	L.MENU_SET_BROADCAST = "Establecer Mensaje de Difusión"
	L.MENU_IGNORE_LIST = "Gestionar Lista de Ignorados"
	L.MENU_COPY_CHARACTER_NAME = "Copiar nombre del personaje"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "Copiar nombre del personaje"
	
	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Suelta para añadir al grupo"
	L.TOOLTIP_HOLD_SHIFT = "Mantén Shift para mantener en otros grupos"
	L.TOOLTIP_DRAG_HERE = "Arrastra amigos aquí para añadirlos"
	L.TOOLTIP_ERROR = "Error"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "No hay cuentas de juego disponibles"
	L.TOOLTIP_NO_INFO = "No hay suficiente información disponible"
	L.TOOLTIP_RENAME_GROUP = "Renombrar Grupo"
	L.TOOLTIP_RENAME_DESC = "Clic para renombrar este grupo"
	L.TOOLTIP_GROUP_COLOR = "Color del Grupo"
	L.TOOLTIP_GROUP_COLOR_DESC = "Clic para cambiar el color de este grupo"
	L.TOOLTIP_DELETE_GROUP = "Borrar Grupo"
	L.TOOLTIP_DELETE_DESC = "Eliminar este grupo y desasignar todos los amigos"
	
	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "Invitado(s) %d amigo(s) al grupo."
	L.MSG_NO_FRIENDS_AVAILABLE = "No hay amigos conectados disponibles para invitar."
	L.MSG_GROUP_DELETED = "Grupo '%s' eliminado"
	L.MSG_IGNORE_LIST_EMPTY = "Tu lista de ignorados está vacía."
	L.MSG_IGNORE_LIST_COUNT = "Lista de Ignorados (%d jugadores):"
	L.MSG_MIGRATION_ALREADY_DONE = "Migración ya completada. Usa '/bfl migrate force' para reintentar."
	L.MSG_MIGRATION_STARTING = "Iniciando migración de FriendGroups..."
	L.MSG_GROUP_ORDER_SAVED = "¡Orden de grupos guardado!"
	L.MSG_SETTINGS_RESET = "¡Configuración restablecida!"
	L.MSG_EXPORT_FAILED = "Exportación fallida: %s"
	L.MSG_IMPORT_SUCCESS = "¡Importación exitosa! Todos los grupos y asignaciones restaurados."
	L.MSG_IMPORT_FAILED = "Importación fallida: %s"
	
	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "¡Base de datos no disponible!"
	L.ERROR_SETTINGS_NOT_INIT = "¡Marco no inicializado!"
	L.ERROR_MODULES_NOT_LOADED = "¡Módulos no disponibles!"
	L.ERROR_GROUPS_MODULE = "¡Módulo de Grupos no disponible!"
	L.ERROR_SETTINGS_MODULE = "¡Módulo de Configuración no disponible!"
	L.ERROR_FRIENDSLIST_MODULE = "Módulo FriendList no disponible"
	L.ERROR_FAILED_DELETE_GROUP = "Fallo al borrar grupo - módulos no cargados"
	L.ERROR_FAILED_DELETE = "Fallo al borrar grupo: %s"
	L.ERROR_MIGRATION_FAILED = "¡Fallo en migración - módulos no cargados!"
	L.ERROR_GROUP_NAME_EMPTY = "El nombre del grupo no puede estar vacío"
	L.ERROR_GROUP_EXISTS = "El grupo ya existe"
	L.ERROR_INVALID_GROUP_NAME = "Nombre de grupo inválido"
	L.ERROR_GROUP_NOT_EXIST = "El grupo no existe"
	L.ERROR_CANNOT_RENAME_BUILTIN = "No se pueden renombrar grupos integrados"
	L.ERROR_INVALID_GROUP_ID = "ID de grupo inválido"
	L.ERROR_CANNOT_DELETE_BUILTIN = "No se pueden borrar grupos integrados"
	
	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Amigos"
	L.GROUP_FAVORITES = "Favoritos"
	L.GROUP_INGAME = "En Juego"
	L.GROUP_NO_GROUP = "Sin Grupo"
	L.ONLINE_STATUS = "Conectado"
	L.OFFLINE_STATUS = "Desconectado"
	L.STATUS_MOBILE = "Móvil"
	L.STATUS_IN_APP = "En App"
	L.UNKNOWN_GAME = "Juego Desconocido"
	L.BUTTON_ADD_FRIEND = "Añadir Amigo"
	L.BUTTON_SEND_MESSAGE = "Enviar Mensaje"
	L.EMPTY_TEXT = "Vacío"
	L.LEVEL_FORMAT = "Nvl %d"
	
	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Funciones Beta"
	L.SETTINGS_BETA_FEATURES_DESC = "Habilita funciones experimentales que aún están en desarrollo. Pueden cambiar o eliminarse en el futuro."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Habilitar Funciones Beta"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Habilita funciones experimentales (Notificaciones, etc.)"
	L.SETTINGS_BETA_FEATURES_WARNING = "Aviso: Las funciones beta pueden tener errores o estar incompletas. Úsalas bajo tu propio riesgo."
	L.SETTINGS_BETA_FEATURES_LIST = "Funciones Beta disponibles actualmente:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Funciones Beta |cff00ff00HABILITADAS|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Funciones Beta |cffff0000DESHABILITADAS|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Pestañas Beta ahora visibles en Configuración"
	L.SETTINGS_BETA_TABS_HIDDEN = "Pestañas Beta ahora ocultas"
	
	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Habilitar Sincronización Global de Amigos"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Sincroniza tu lista de amigos de WoW en todos los personajes de esta cuenta."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Sincronización Global"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Habilitar Borrado"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC = "Permitir que la sincronización borre amigos de tu lista si se eliminan de la base de datos."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Base de Datos de Amigos Sincronizados"
	
	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================
	
	
	
	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================
	
	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Tamaño de Marco (Modo Edición)"
	L.SETTINGS_FRAME_SIZE_INFO = "Tamaño predeterminado preferido para nuevos diseños."
	L.SETTINGS_FRAME_WIDTH = "Ancho:"
	L.SETTINGS_FRAME_HEIGHT = "Alto:"
	L.SETTINGS_FRAME_RESET_SIZE = "Restablecer a 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Aplicar al diseño actual"
	L.SETTINGS_FRAME_RESET_ALL = "Restablecer todos los diseños"
	
	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Amigos"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Clic Izq: Abrir BetterFriendlist"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Clic Der: Configuración"
	L.BROKER_SETTINGS_ENABLE = "Habilitar Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON = "Mostrar Icono"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Nivel de Detalle del Tooltip"
	L.BROKER_SETTINGS_CLICK_ACTION = "Acción Clic Izquierdo"
	L.BROKER_SETTINGS_LEFT_CLICK = "Acción Clic Izquierdo"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Acción Clic Derecho"
	L.BROKER_ACTION_TOGGLE = "Alternar BetterFriendlist"
	L.BROKER_ACTION_FRIENDS = "Abrir Lista de Amigos"
	L.BROKER_ACTION_SETTINGS = "Abrir Configuración"
	L.BROKER_ACTION_OPEN_BNET = "Abrir App Battle.net"
	L.BROKER_ACTION_NONE = "Nada"
	L.BROKER_SETTINGS_INFO = "BetterFriendlist se integra con addons como Bazooka, ChocolateBar o TitanPanel. Habilítalo para ver recuentos y acceso rápido."
	L.BROKER_FILTER_CHANGED = "Filtro cambiado a: %s"
	
	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "Amigos WoW"
	L.BROKER_HEADER_BNET = "Amigos Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Ningún amigo de WoW conectado"
	L.BROKER_NO_FRIENDS_ONLINE = "Ningún amigo conectado"
	L.BROKER_TOTAL_ONLINE = "Total: %d online / %d amigos"
	L.BROKER_FILTER_LABEL = "Filtro: "
	L.BROKER_SORT_LABEL = "Orden: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Acciones Amigo ---"
	L.BROKER_HINT_CLICK_WHISPER = "Clic Amigo:"
	L.BROKER_HINT_WHISPER = " Susurrar • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Clic-Dcho:"
	L.BROKER_HINT_CONTEXT_MENU = " Menú Contextual"
	L.BROKER_HINT_ALT_CLICK = "Alt+Clic:"
	L.BROKER_HINT_INVITE = " Invitar/Unirse • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Clic:"
	L.BROKER_HINT_COPY = " Copiar al Chat"
	L.BROKER_HINT_ICON_ACTIONS = "--- Acciones Icono ---"
	L.BROKER_HINT_LEFT_CLICK = "Clic Izq:"
	L.BROKER_HINT_TOGGLE = " Alternar BetterFriendlist"
	L.BROKER_HINT_RIGHT_CLICK = "Clic Der:"
	L.BROKER_HINT_SETTINGS = " Configuración • "
	L.BROKER_HINT_MIDDLE_CLICK = "Clic Central:"
	L.BROKER_HINT_CYCLE_FILTER = " Cambiar Filtro"
	
	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Treat Mobile as Offline
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Tratar Móvil como Desconectado"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Mostrar amigos en la App Móvil en el grupo Offline"
	
	-- Feature 3: Show Notes as Name
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Mostrar Notas como Nombre"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Muestra la nota del amigo en lugar de su nombre"
	
	-- Feature 4: Window Scale
	L.SETTINGS_WINDOW_SCALE = "Escala de Ventana"
	L.SETTINGS_WINDOW_SCALE_DESC = "Escala toda la ventana (50%% - 200%%)"
	
	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Mostrar Etiqueta 'Amigos:'"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Mostrar Recuento Total"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Dividir Recuento WoW/BNet"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Configuración General"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Integración Data Broker"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interacción"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Cómo Usar"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Addons Probados"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Instala un addon de visualización (Bazooka, ChocolateBar o TitanPanel)\n• Habilita Data Broker arriba (requiere recarga)\n• El botón aparecerá en tu addon de visualización\n• Pasa el ratón para ver detalles, clic para abrir"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Columnas del Tooltip"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Columnas del Tooltip"
	L.BROKER_COLUMN_NAME = "Nombre"
	L.BROKER_COLUMN_LEVEL = "Nivel"
	L.BROKER_COLUMN_CHARACTER = "Personaje"
	L.BROKER_COLUMN_GAME = "Juego / App"
	L.BROKER_COLUMN_ZONE = "Zona"
	L.BROKER_COLUMN_REALM = "Reino"
	L.BROKER_COLUMN_FACTION = "Facción"
	L.BROKER_COLUMN_NOTES = "Notas"
	
	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Muestra el nombre del amigo (RealID o Personaje)"
	L.BROKER_COLUMN_LEVEL_DESC = "Muestra el nivel del personaje"
	L.BROKER_COLUMN_CHARACTER_DESC = "Muestra nombre del personaje e icono de clase"
	L.BROKER_COLUMN_GAME_DESC = "Muestra el juego o app"
	L.BROKER_COLUMN_ZONE_DESC = "Muestra la zona actual"
	L.BROKER_COLUMN_REALM_DESC = "Muestra el reino del personaje"
	L.BROKER_COLUMN_FACTION_DESC = "Muestra el icono de facción"
	L.BROKER_COLUMN_NOTES_DESC = "Muestra las notas del amigo"
	
	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Aliados Recientes no disponible en esta versión."
	L.EDIT_MODE_NOT_AVAILABLE = "Modo Edición no disponible en Classic. Usa /bfl position para mover."
	L.CLASSIC_COMPATIBILITY_INFO = "BetterFriendlist en modo compatibilidad Classic."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Función no disponible en Classic."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Cerrar al abrir Hermandad"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "Cierra la lista de amigos al abrir la de Hermandad"
	L.SETTINGS_HIDE_GUILD_TAB = "Ocultar Pestaña Hermandad"
L.SETTINGS_HIDE_GUILD_TAB_DESC = "Oculta la pestaña Hermandad de la lista de amigos"
L.SETTINGS_USE_UI_PANEL_SYSTEM = "Respetar Jerarquía UI"
L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Evita solapamientos con otras ventanas (Personaje, Libro de Hechizos...). Requiere /reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 min"
	L.LASTONLINE_MINUTES = "%d min"
	L.LASTONLINE_HOURS = "%d h"
	L.LASTONLINE_DAYS = "%d días"
	L.LASTONLINE_MONTHS = "%d meses"
	L.LASTONLINE_YEARS = "%d años"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "IU Hermandad Clásica Deshabilitada"
	L.CLASSIC_GUILD_UI_WARNING_TEXT = "BetterFriendlist ha deshabilitado la configuración de IU Hermandad Clásica ya que solo la moderna es compatible.\n\nLa pestaña Hermandad abrirá la interfaz moderna."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Usa '/bfl migrate help' para comandos de migración."
	L.LOADED_MESSAGE = "BetterFriendlist cargado correctamente."
	L.DEBUG_ENABLED = "Depuración HABILITADA"
	L.DEBUG_DISABLED = "Depuración DESHABILITADA"
	L.CONFIG_RESET = "Configuración reiniciada a predeterminados."
	L.SEARCH_PLACEHOLDER = "Buscar..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Hermandad"
	L.TAB_RAID = "Banda"
	L.TAB_QUICK_JOIN = "Unirse"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Conectado"
	L.FILTER_SEARCH_OFFLINE = "Desconectado"
	L.FILTER_SEARCH_MOBILE = "Móvil"
	L.FILTER_SEARCH_AFK = "AUS"
	L.FILTER_SEARCH_DND = "No molestar"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "ND"

	-- Groups
	L.MIGRATION_CHECK = "Comprobando migración..."
	L.MIGRATION_RESULT = "Migrados %d grupos de FriendGroups y %d asignaciones."
	L.MIGRATION_BNET_UPDATED = "Asignaciones BNet actualizadas para usar identificadores persistentes."
	L.MIGRATION_BNET_REASSIGN = "Por favor reasigna tus amigos BNet. Esta es una migración única."
	L.MIGRATION_BNET_REASON = "(Razón: bnetAccountID es temporal y cambia en cada sesión)"
	L.MIGRATION_WOW_RESULT = "Migradas %d asignaciones WoW para incluir nombres de reino."
	L.MIGRATION_WOW_FORMAT = "(Formato actual: Personaje-Reino para identificación consistente)"
	L.MIGRATION_WOW_FAIL = "No se pudieron migrar asignaciones WoW (reino no disponible)."
	L.MIGRATION_SMART_MIGRATING = "Migrando configuración de grupo: %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Selección múltiple limpiada - entraste en combate"

	-- Quick Join
	L.LEADER_LABEL = "Líder:"
	L.MEMBERS_LABEL = "Miembros:"
	L.AVAILABLE_ROLES = "Roles Disponibles"
	L.NO_AVAILABLE_ROLES = "Sin roles disponibles"
	L.AUTO_ACCEPT_TOOLTIP = "Este grupo te aceptará automáticamente."
	L.MOCK_JOIN_REQUEST_SENT = "Solicitud de prueba enviada"
	L.QUICK_JOIN_NO_GROUPS = "No hay grupos disponibles"
	L.UNKNOWN_GROUP = "Grupo Desconocido"
	L.UNKNOWN = "Desconocido"
	L.NO_QUEUE = "Sin Cola"
	L.LFG_ACTIVITY = "Actividad LFG"
	L.ACTIVITY_DUNGEON = "Mazmorra"
	L.ACTIVITY_RAID = "Banda"
	L.ACTIVITY_PVP = "JcJ"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "Importar Configuración"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "Exportar Configuración"
	L.DIALOG_DELETE_GROUP_TITLE = "Borrar grupo"
	L.DIALOG_RENAME_GROUP_TITLE = "Renombrar grupo"
	L.DIALOG_CREATE_GROUP_TITLE = "Crear grupo"

	-- Tooltips
	L.TOOLTIP_LAST_CONTACT = "Último contacto:"
	L.TOOLTIP_AGO = " hace"
	L.TOOLTIP_LAST_ONLINE = "Última vez: %s"

	-- Notifications
	L.YES = "SÍ"
	L.NO = "NO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Vista Previa %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Vista previa para posicionar"
	L.EDITMODE_FRAME_WIDTH = "Ancho del Marco"
	L.EDITMODE_FRAME_HEIGHT = "Alto del Marco"
	
	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT = "¿Restablecer todos los tamaños y posiciones guardados para Modos de Edición?\n\n¡No se puede deshacer!"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Restablecer Todo"
	L.MSG_LAYOUTS_RESET = "Todos los diseños restablecidos. Usa /editmode para reposicionar."
	L.DIALOG_TRIGGER_TITLE = "Crear Disparador de Grupo"
	L.DIALOG_TRIGGER_INFO = "Recibe notificación cuando X amigos de un grupo estén conectados."
	L.DIALOG_TRIGGER_SELECT_GROUP = "Seleccionar Grupo:"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Mínimo Amigos Conectados:"
	L.DIALOG_TRIGGER_CREATE = "Crear"
	L.DIALOG_TRIGGER_CANCEL = "Cancelar"
	L.ERROR_SELECT_GROUP = "Por favor selecciona un grupo"
	L.MSG_TRIGGER_CREATED = "Disparador creado: %d+ amigos de '%s'"
	L.ERROR_NO_GROUPS = "No hay grupos disponibles. Crea uno primero."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Poner Apodo a %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "Todos los Amigos"
	L.FILTER_ONLINE = "Solo Conectados"
	L.FILTER_OFFLINE = "Solo Desconectados"
	L.FILTER_WOW = "Solo WoW"
	L.FILTER_BNET = "Solo Battle.net"
	L.FILTER_HIDE_AFK = "Ocultar AFK/ND"
	L.FILTER_RETAIL = "Solo Retail"
	L.TOOLTIP_QUICK_FILTER = "Filtro Rápido: %s"
	
	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Cambiar esto requiere recargar la UI.\n\n¿Recargar ahora?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Recargar Ahora"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Cancelar"
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Habilitar/Deshabilitar integración Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Mostrar Icono Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "Alternar icono de BetterFriendlist"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Mostrar Etiqueta Broker"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Alternar etiqueta 'Friends:'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Mostrar Total"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Mostrar número total de amigos en texto"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Dividir Recuentos"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Mostrar recuentos separados para WoW y BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "Icono WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Mostrar Icono WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "Icono WoW junto a amigos WoW"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "Icono BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Mostrar Icono BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "Icono BNet junto a amigos BNet"
    L.BROKER_SETTINGS_CLICK_ACTION = "Acción al Clic"
    L.BROKER_SETTINGS_TOOLTIP_MODE = "Modo Tooltip"
    L.STATUS_ENABLED = "|cff00ff00Habilitado|r"
    L.STATUS_DISABLED = "|cffff0000Deshabilitado|r"
    L.BROKER_WOW_FRIENDS = "Amigos WoW:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Sinc. Global"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Habilitar/Deshabilitar sinc. de amigos entre personajes"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Mostrar Borrados"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Mostrar Amigos Borrados"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Muestra amigos que han sido borrados en la lista de sincronización"
	L.TOOLTIP_RESTORE_FRIEND = "Restaurar Amigo"
	L.TOOLTIP_DELETE_FRIEND = "Borrar Amigo"
	L.POPUP_EDIT_NOTE_TITLE = "Editar Nota"
	L.BUTTON_SAVE = "Guardar"
	L.BUTTON_CANCEL = "Cancelar"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Amigos: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d total"
	L.BROKER_CURRENT_FILTER = "Filtro Actual:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Clic Central: Ciclar Filtro"
	L.BROKER_AND_MORE = "  ... y %d más"
	L.BROKER_WHISPER_AGO = " (susurro hace %s)"
	L.BROKER_TOTAL_LABEL = "Total:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d amigos"
	L.MENU_CHANGE_COLOR = "Cambiar Color"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Error mostrando tooltip|r"
	L.STATUS_LABEL = "Estado:"
	L.STATUS_AWAY = "Ausente"
	L.STATUS_DND_FULL = "No Molestar"
	L.GAME_LABEL = "Juego:"
	L.REALM_LABEL = "Reino:"
	L.CLASS_LABEL = "Clase:"
	L.FACTION_LABEL = "Facción:"
	L.ZONE_LABEL = "Zona:"
	L.NOTE_LABEL = "Nota:"
	L.BROADCAST_LABEL = "Difusión:"
	L.ACTIVE_SINCE_FMT = "(Activo desde: %s)"
	L.HINT_RIGHT_CLICK_OPTIONS = "Clic-dcho para opciones"
	L.HEADER_ADD_FRIEND = "|cffffd700Añadir %s a %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Comprobación migración - Total mapeos:"
	L.MIGRATION_DEBUG_BNET = "Comprobación migración - Formato BNet antiguo:"
	L.MIGRATION_DEBUG_WOW = "Comprobación migración - Amigos WoW sin reino:"
	L.ERROR_INVALID_PARAMS = "Parámetros inválidos"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Dejar de Ignorar"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE = "Sistema de Aliados Recientes no disponible."
	L.RECENT_ALLIES_INVITE = "Invitar"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Jugador desconectado"
	L.RECENT_ALLIES_PIN_EXPIRES = "Pin expira en %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Nivel %d %s"
	L.RECENT_ALLIES_NOTE = "Nota: %s"
	L.RECENT_ALLIES_ACTIVITY = "Actividad Reciente:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Recluta a un Amigo"
	L.RAF_RECRUITMENT = "Reclutamiento"
	L.RAF_NO_RECRUITS_DESC = "Aún no has reclutado amigos."
	L.RAF_PENDING_RECRUIT = "Recluta Pendiente"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d Amigos Reclutados"
	L.RAF_YOU_HAVE_EARNED = "Has ganado:"
	L.RAF_NEXT_REWARD_AFTER = "Próxima recompensa tras %d/%d meses"
	L.RAF_FIRST_REWARD = "Primera Recompensa:"
	L.RAF_NEXT_REWARD = "Próxima Recompensa:"
	L.RAF_REWARD_MOUNT = "Montura"
	L.RAF_REWARD_TITLE_DEFAULT = "Título"
	L.RAF_REWARD_TITLE_FMT = "Título: %s"
	L.RAF_REWARD_GAMETIME = "Tiempo de Juego"
	L.RAF_MONTH_COUNT = "%d Meses suscritos por amigos"
	L.RAF_CLAIM_REWARD = "Reclamar Recompensa"
	L.RAF_VIEW_ALL_REWARDS = "Ver Todas las Recompensas"
	L.RAF_ACTIVE_RECRUIT = "Activo"
	L.RAF_TRIAL_RECRUIT = "Prueba"
	L.RAF_INACTIVE_RECRUIT = "Inactivo"
	L.RAF_OFFLINE = "Desconectado"
	L.RAF_TOOLTIP_DESC = "Hasta %d meses"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d meses"
	L.RAF_ACTIVITY_DESCRIPTION = "Actividad de referido para %s"
	L.RAF_REWARDS_LABEL = "Recompensas"
	L.RAF_YOU_EARNED_LABEL = "Ganaste:"
	L.RAF_CLICK_TO_CLAIM = "Clic para reclamar"
	L.RAF_LOADING = "Cargando..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== Recompensas Recluta a un Amigo ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Actual"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Legado v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Meses ganados: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Reclutas: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Recompensas Disponibles:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Reclamado]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Reclamable]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Accesible]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Bloqueado]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d meses)"
	L.RAF_CHAT_MORE_REWARDS = "    ... y %d recompensas más"
	L.RAF_CHAT_USE_UI = "|cff00ff00Usa la interfaz del juego para más detalles.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00Recluta a un Amigo:|r Tiempo de juego disponible. Usa la interfaz de Blizzard."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_TAB_DATABROKER = "Data Broker"
	L.MSG_GROUP_RENAMED = "Grupo renombrado a '%s'"
	L.ERROR_RENAME_FAILED = "Fallo al renombrar grupo"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Orden de grupo guardado: %s"
	L.ERROR_EXPORT_SERIALIZE = "Fallo al serializar datos"
	L.ERROR_IMPORT_EMPTY = "Cadena de importación vacía"
	L.ERROR_IMPORT_DECODE = "Fallo al decodificar cadena (formato inválido)"
	L.ERROR_IMPORT_DESERIALIZE = "Fallo al deserializar datos (cadena corrupta)"
	L.ERROR_EXPORT_VERSION = "Versión de exportación no soportada"
	L.ERROR_EXPORT_STRUCTURE = "Estructura de datos de exportación inválida"
	
	-- Statistics
	L.STATS_NO_HEALTH_DATA = "Sin datos de salud"
	L.STATS_NO_CLASS_DATA = "Sin datos de clase"
	L.STATS_NO_LEVEL_DATA = "Sin datos de nivel"
	L.STATS_NO_REALM_DATA = "Sin datos de reino"
	L.STATS_NO_GAME_DATA = "Sin datos de juego"
	L.STATS_NO_MOBILE_DATA = "Sin datos móviles"
	L.STATS_SAME_REALM = "Mismo Reino: %d (%d%%)  |  Otros Reinos: %d (%d%%)"
	L.STATS_TOP_REALMS = "\nReinos Top:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMóvil: %d"
	L.STATS_GAME_OTHER = "\nOtro: %d"
	L.STATS_MOBILE_DESKTOP = "Escritorio: %d (%d%%)\nMóvil: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Con Notas: %d (%d%%)\nFavoritos: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Máx (80): %d\n70-79: %d\n60-69: %d\n<60: %d\nMedia: %.1f"
	L.STATS_HEALTH_FMT = "|cff00ff00Activo: %d (%d%%)|r\n|cffffd700Regular: %d (%d%%)|r\n|cffffaa00A la deriva: %d (%d%%)|r\n|cffff6600Estancado: %d (%d%%)|r\n|cffff0000Inactivo: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffAlianza: %d|r\n|cffff0000Horda: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "Mover Abajo"
	L.TOOLTIP_MOVE_DOWN_DESC = "Mover este grupo abajo en la lista"
	L.TOOLTIP_MOVE_UP = "Mover Arriba"
	L.TOOLTIP_MOVE_UP_DESC = "Mover este grupo arriba en la lista"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "El amigo no está jugando World of Warcraft"
	L.TRAVEL_PASS_WOW_CLASSIC = "Este amigo está jugando World of Warcraft Classic."
	L.TRAVEL_PASS_WOW_MAINLINE = "Este amigo está jugando World of Warcraft."
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Amigo jugando una versión diferente de WoW"
	L.TRAVEL_PASS_NO_INFO = "No hay suficiente información disponible"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Amigo en una región diferente"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "No hay cuentas de juego disponibles"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendList"
	L.MENU_SHOW_BLIZZARD = "Mostrar Lista Amigos Blizzard"
	L.MENU_COMBAT_LOCKED = "No se puede alternar en combate"
	L.MENU_SET_NICKNAME = "Establecer Apodo"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Configuración BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Buscar amigos..."
	L.RAF_NEXT_REWARD_HELP = "Información sobre recompensas RAF"
	L.WHO_LEVEL_FORMAT = "Nivel %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Aliados Recientes"
	L.CONTACTS_MENU_NAME = "Menú Contactos"
	L.BATTLENET_UNAVAILABLE = "Battle.net No Disponible"
	L.BATTLENET_BROADCAST = "Difusión"
	L.FRIENDS_LIST_ENTER_TEXT = "Introducir mensaje difusión..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Buscar jugadores..."
	L.RAF_SPLASH_SCREEN_TITLE = "Recluta a un Amigo"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "¡Recluta a tus amigos a World of Warcraft!"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Información sobre recompensas RAF"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Formato de Nombre"
	L.SETTINGS_NAME_FORMAT_DESC = "Personaliza cómo se muestran los nombres:\n|cffFFD100%name%|r - Nombre Cuenta (RealID/BattleTag)\n|cffFFD100%note%|r - Nota\n|cffFFD100%nickname%|r - Apodo\n|cffFFD100%battletag%|r - BattleTag Corto"
	L.SETTINGS_NAME_FORMAT_LABEL = "Formato:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Formato de Nombre"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Introduce una cadena de formato usando tokens."

	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "Mostrar Grupo 'En Juego'"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Agrupa automáticamente amigos jugando"
	L.SETTINGS_INGAME_MODE_WOW = "Solo WoW (Misma Era)"
	L.SETTINGS_INGAME_MODE_ANY = "Cualquier Juego"
	L.SETTINGS_INGAME_MODE_LABEL = "   Modo:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Modo Grupo En Juego"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Elige qué amigos incluir:\n\n|cffffffffSolo WoW:|r Muestra versión (Retail/Classic)\n|cffffffffCualquier Juego:|r Cualquier juego Battle.net"

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Opciones Visualización"
	L.SETTINGS_BEHAVIOR_HEADER = "Comportamiento"
	L.SETTINGS_GROUP_MANAGEMENT = "Gestión Grupos"
	L.SETTINGS_FONT_SETTINGS = "Configuración Fuente"
	L.SETTINGS_GROUP_ORDER = "Orden Grupos"
	L.SETTINGS_MIGRATION_HEADER = "Migración FriendGroups"
	L.SETTINGS_MIGRATION_DESC = "Migrar desde el addon FriendGroups. Importará grupos desde notas BattleNet."
	L.SETTINGS_MIGRATE_BTN = "Migrar desde FriendGroups"
	L.SETTINGS_MIGRATE_TOOLTIP = "Importar grupos"
	L.SETTINGS_EXPORT_HEADER = "Exportar / Importar Config"
	L.SETTINGS_EXPORT_DESC = "Comparte tus grupos entre personajes/cuentas."
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Advertencia: ¡Importar reemplazará TODO!|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Exportar configuración"
	L.SETTINGS_IMPORT_TOOLTIP = "Importar configuración"

	-- Statistics
	L.STATS_HEADER = "Estadísticas de Red"
	L.STATS_DESC = "Resumen de tu red de amigos"
	L.STATS_OVERVIEW_HEADER = "Resumen"
	L.STATS_HEALTH_HEADER = "Salud Amistad"
	L.STATS_CLASSES_HEADER = "Top 5 Clases"
	L.STATS_REALMS_HEADER = "Reinos"
	L.STATS_ORGANIZATION_HEADER = "Organización"
	L.STATS_LEVELS_HEADER = "Distribución Niveles"
	L.STATS_GAMES_HEADER = "Distribución Juegos"
	L.STATS_MOBILE_HEADER = "Móvil vs Escritorio"
	L.STATS_FACTIONS_HEADER = "Distribución Facciones"
	L.STATS_REFRESH_BTN = "Refrescar Estadísticas"
	L.STATS_REFRESH_TOOLTIP = "Actualizar datos"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters
	
	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Oculta grupos sin miembros online"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Muestra iconos Alianza/Horda"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Muestra nombre del reino"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Atenúa facción opuesta"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Muestra móvil como AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Oculta nivel si es máximo"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Muestra botón original Blizzard"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Alternar visibilidad Favoritos"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "Solo un grupo expandido a la vez"
	L.SETTINGS_COMPACT_MODE_DESC = "Reduce altura botones"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Habilitar Skin ElvUI"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Habilita skin ElvUI. Requiere ElvUI instalado."
	L.DIALOG_ELVUI_RELOAD_TEXT = "Cambiar Skin ElvUI requiere recarga UI.\n¿Recargar?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Sí"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "No"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "BD no inicializada."
	L.CORE_SHOW_BLIZZARD_ENABLED = "Opción Blizzard |cff20ff20habitada|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Opción Blizzard |cffff0000deshabilitada|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Debug no disponible"
	L.CORE_DB_MODULE_NOT_AVAIL = "Módulo BD no disponible"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Rastreo Actividad ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Amigos con actividad: %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "¡Funciones Beta desactivadas!"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Habilitar:|r ESC > AddOns > BetterFriendlist"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Módulo Estadísticas no cargado"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Estadísticas ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Resumen:|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE = "  Total: |cffffffff%d|r  On: |cff00ff00%d|r (%.0f%%)  Off: |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet: |cff0099ff%d|r  |  WoW: |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Salud Amistad:|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Activo: |cff00ff00%d|r (%.0f%%)  Regular: |cffffd700%d|r (%.0f%%)"
	L.CORE_STATS_HEALTH_STALE = "  Estancado: |cffff6600%d|r (%.0f%%)  Dormant: |cffff0000%d|r (%.0f%%)"
	L.CORE_STATS_NO_HEALTH_DATA = "  Sin datos salud"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Distrib. Clases:|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Distrib. Niveles:|r"
	L.CORE_STATS_LEVEL_BREAKDOWN = "  Máx: |cffffffff%d|r  70+: |cffffffff%d|r  60+: |cffffffff%d|r  <60: |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Media Nivel: |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Reinos:|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Mismo: |cffffffff%d|r  |  Otro: |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Top Reinos:"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Facciones:|r"
	L.CORE_STATS_FACTION_DATA = "  Alianza: |cff0080ff%d|r  |  Horda: |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Distrib. Juegos:|r"
	L.CORE_STATS_GAME_WOW = "  Retail: |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic: |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4: |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS: |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC: |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  App: |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Otros: |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Móvil vs PC:|r"
	L.CORE_STATS_MOBILE_DATA = "  PC: |cffffffff%d|r (%.0f%%)  Móvil: |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Organización:|r"
	L.CORE_STATS_ORG_DATA = "  Notas: |cffffffff%d|r  Fav: |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Config no cargada"
	L.CORE_MOCK_INVITES_ENABLED = "Inv. Prueba |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Añadida inv. prueba |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Tip:|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Inv. prueba borradas"
	L.CORE_NO_MOCK_INVITES = "Sin inv. prueba"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Monitor Rend. no cargado"
	L.CORE_MEMORY_USAGE = "Memoria: %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "QuickJoin no cargado"
	L.CORE_RAIDFRAME_NOT_LOADED = "RaidFrame no cargado"
	L.CORE_PREVIEW_MODE_NOT_LOADED = "PreviewMode no cargado"
	L.CORE_ACTIVITY_TEST_NOT_LOADED = "ActivityTests no cargado"
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Compat. Classic ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Versión Cliente:|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Sabor Detectado:|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00The War Within|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffffRetail|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Disponibilidad:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menú Moderno: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Aliados Recientes: %s"
	L.CORE_FEATURE_EDIT_MODE = "  Modo Edición: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown Moderno: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker Moderno: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Capa Compat:|r %s"
	L.CORE_COMPAT_ACTIVE = "|cff00ff00Activo|r"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000No Cargado|r"
	L.CORE_CHANGELOG_RESET = "Changelog reseteado."
	L.CORE_CHANGELOG_NOT_LOADED = "Changelog no cargado"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Debug UI Panel ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard FriendsFrame:|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000Sin settings almacenados|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00BetterFriendsFrame attrs:|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00En UIPanelWindows:|r |cff00ff00SÍ|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00En UIPanelWindows:|r |cffff0000NO|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800AVISO:|r FriendsFrame sigue en UIPanelWindows!"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Setting Actual:|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BetterFriendlist v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Comandos:|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Alternar ventana"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/bfl settings|r - Abrir config"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/bfl help|r - Ayuda"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Abrir registro de cambios"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Debug:|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/bfl debug|r - Alternar debug"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Ver BD"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Ver actividad"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Ver estadísticas"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Probar reglas grupo"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join:|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Crear datos prueba"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Solo Mazmorra"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - Solo PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Solo Banda"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Stress test"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - Simular eventos"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Limpiar prueba"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - Listar grupos"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock:|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Crear banda prueba"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Añadir invitación"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Limpiar invitaciones"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Modo Preview:|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - Activar preview"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Desactivar preview"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Muestra datos falsos para screenshots)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame:|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - Crear 25j"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - Crear 40j"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - Crear 10j"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - Crear 20j"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - Sim ReadyCheck"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Sim Role"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Sim Mover"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Limpiar"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Rendimiento:|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Mostrar stats"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Activar"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Reset"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Memoria"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Tests:|r"
	L.CORE_HELP_TEST_ACTIVITY = "  |cffffffff/bfl test|r - Tests Actividad"
	L.CORE_HELP_LINK = "|cff20ff20Ayuda:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Cargado. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Aceptada inv. prueba %s"
	L.MOCK_INVITE_DECLINED = "Rechazada inv. prueba %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Estadísticas reiniciadas"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Informe Rendimiento ===|r"
	L.PERF_QJ_OPS = "|cffffd700Operaciones QuickJoin:|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Operaciones Friends:|r"
	L.PERF_MEMORY = "|cffffd700Uso Memoria:|r"
	L.PERF_TARGETS = "|cffffd700Objetivos:|r"
	L.PERF_AUTO_ENABLED = "Auto-monitor |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Creada raid 25j"
	L.RAID_MOCK_CREATED_40 = "Creada raid 40j"
	L.RAID_MOCK_CREATED_10 = "Creada raid 10j"
	L.RAID_MOCK_CREATED_MYTHIC = "Creada raid 20j (Mítica)"
	L.RAID_MOCK_STRESS = "Stress test: 40j rápido"
	L.RAID_WARN_CPU = "|cffff8800Aviso:|r Alto uso CPU esperado"
	L.RAID_NO_MOCK_DATA = "Sin datos prueba. Usa '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Simulando Ready Check..."
	L.RAID_MOCK_CLEARED = "Datos prueba borrados"
	L.RAID_EVENT_COMMANDS = "|cff00ff00Comandos Evento Raid:|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Gestión:|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Configurar mock"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - Listar info"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Stress test"
	L.RAID_HELP_EVENTS = "|cffffcc00Simulación:|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Config Raid:|r"
	L.RAID_INFO_HEADER = "|cff00ff00Info Mock Raid:|r"
	L.RAID_NO_MOCK_ACTIVE = "Sin mock activo"
	L.RAID_DYN_UPDATES = "Updates dinámicos: %s"
	L.RAID_UPDATE_INTERVAL = "Intervalo: %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Mock activo: %s"
	L.RAID_DYN_UPDATES_STATUS = "  Dinámico: %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Intervalo: %.1f s"
	L.RAID_MEMBERS_STATUS = "  Miembros: %d"
	L.RAID_TOTAL_MEMBERS = "  Total: %d"
	L.RAID_COMPOSITION = "  Comp: %d T, %d H, %d D"
	L.RAID_STATUS = "  Estado: %d off, %d muerto"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Creados grupos test iconos"
	L.QJ_MOCK_CREATED_STRESS = "Creados 50 grupos prueba"
	L.QJ_SIM_ADDED = "Sim: Grupo añadido"
	L.QJ_SIM_REMOVED = "Sim: Grupo borrado"
	L.QJ_ERR_NO_GROUPS_REMOVE = "No hay grupos para borrar"
	L.QJ_ERR_NO_GROUPS_UPDATE = "No hay grupos para actualizar"
	L.QJ_EVENT_COMMANDS = "|cff00ff00Comandos Evento QJ:|r"
	L.QJ_LIST_HEADER = "|cff00ff00Grupos QJ Mock:|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00Config QJ:|r"
	L.QJ_EXT_FOOTER = "|cff888888Mock son verdes.|r"
	L.QJ_SIM_UPDATED_FMT = "Sim: %s actualizado"
	L.QJ_ADDED_GROUP_FMT = "Añadido: %s"
	L.QJ_NO_GROUPS_HINT = "Sin grupos mock."
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Test iconos"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config:|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Configurar"
	
	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Reset aviso Guild UI. Saldrá al recargar."
	L.CMD_RESET_HEADER = "Comandos Reset:"
	L.CMD_RESET_HELP_WARNING = "Resetear aviso Guild UI"
	
	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "   GitHub Issues"
	L.CHANGELOG_SUPPORT = "   Soporte"
	L.CHANGELOG_HEADER_COMMUNITY = "Comunidad y Soporte:"
	L.CHANGELOG_HEADER_VERSION = "Versión %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "¡Nueva Actualización!"
	L.CHANGELOG_TOOLTIP_CLICK = "Clic para ver Cambios"
	L.CHANGELOG_POPUP_DISCORD = "Únete a nuestro Discord"
	L.CHANGELOG_POPUP_GITHUB = "Reportar Bugs"
	L.CHANGELOG_POPUP_SUPPORT = "Apoyar Desarrollo"
	L.CHANGELOG_TITLE = "Cambios BetterFriendlist"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Nivel Máx"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Grupo %d"

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6ms = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3ms = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Aviso Rendimiento"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Rendimiento:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver. Juego:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Móvil"
	L.RAF_RECRUITMENT = "Recluta a un Amigo"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Colorea los nombres de los amigos en su color de clase"


	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Font Outline"
	L.SETTINGS_FONT_SHADOW = "Font Shadow"
	L.SETTINGS_FONT_OUTLINE_NONE = "None"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Outline"
	L.SETTINGS_FONT_OUTLINE_THICK = "Thick Outline"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Monochrome"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "Editar nota"
	L.MENU_SHOW_SEARCH = "Mostrar búsqueda"
	L.MENU_QUICK_FILTER = "Filtro rápido"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Habilitar Icono Favorito"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "Muestra un icono de estrella en el botón del amigo para favoritos."
	L.SETTINGS_SHOW_FACTION_BG = "Mostrar Fondo de Facción"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "Muestra el color de la facción como fondo para el botón del amigo."
end)
