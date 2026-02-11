-- Locales/ruRU.lua
-- Russian (Русский) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("ruRU", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"Отключает портрет игрока, скрывает параметры поиска/сортировки, расширяет фрейм и смещает вкладки для компактного макета."
	L.MENU_CHANGELOG = "Changelog"
	L.DIALOG_CREATE_GROUP_TEXT = "Введите название для новой группы:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Создать"
	L.DIALOG_CREATE_GROUP_BTN2 = "Отмена"
	L.DIALOG_RENAME_GROUP_TEXT = "Введите новое название для группы:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Переименовать"
	L.DIALOG_RENAME_GROUP_BTN2 = "Отмена"
	L.DIALOG_RENAME_GROUP_SETTINGS = "Переименовать группу '%s':"
	L.DIALOG_DELETE_GROUP_TEXT =
		"Вы уверены, что хотите удалить эту группу?\n\n|cffff0000Это удалит всех друзей из этой группы.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Удалить"
	L.DIALOG_DELETE_GROUP_BTN2 = "Отмена"
	L.DIALOG_DELETE_GROUP_SETTINGS =
		"Удалить группу '%s'?\n\nВсе друзья будут исключены из этой группы."
	L.DIALOG_RESET_SETTINGS_TEXT =
		"Сбросить все настройки к значениям по умолчанию?"
	L.DIALOG_RESET_BTN1 = "Сбросить"
	L.DIALOG_RESET_BTN2 = "Отмена"
	L.DIALOG_UI_PANEL_RELOAD_TEXT =
		"Изменение настройки иерархии UI требует перезагрузки интерфейса.\n\nПерезагрузить сейчас?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Перезагрузить"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Отмена"
	L.MSG_RELOAD_REQUIRED =
		"Для корректного применения этого изменения в Classic требуется перезагрузка."
	L.MSG_RELOAD_NOW = "Перезагрузить интерфейс сейчас?"
	L.RAID_HELP_TITLE = "Справка по рейду"
	L.RAID_HELP_TEXT = "Нажмите для справки по списку рейда."
	L.RAID_HELP_MULTISELECT_TITLE = "Множественный выбор"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Удерживайте Ctrl и щелкните левой кнопкой, чтобы выбрать нескольких игроков.\nПосле выбора перетащите их в любую группу, чтобы переместить всех сразу."
	L.RAID_HELP_MAINTANK_TITLE = "Главный танк"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s на игроке, чтобы назначить его главным танком.\nРядом с его именем появится значок танка."
	L.RAID_HELP_MAINASSIST_TITLE = "Главный помощник"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s на игроке, чтобы назначить его главным помощником.\nРядом с его именем появится значок помощника."
	L.RAID_HELP_LEAD_TITLE = "Лидер рейда"
	L.RAID_HELP_LEAD_TEXT = "%s на игроке, чтобы назначить Лидером Рейда."
	L.RAID_HELP_PROMOTE_TITLE = "Помощник"
	L.RAID_HELP_PROMOTE_TEXT = "%s на игроке, чтобы назначить/снять Помощником."
	L.RAID_HELP_DRAGDROP_TITLE = "Перетаскивание"
	L.RAID_HELP_DRAGDROP_TEXT =
		"Перетащите любого игрока, чтобы переместить его между группами.\nВы также можете перетащить нескольких выбранных игроков одновременно.\nПустые слоты можно использовать для обмена позициями."
	L.RAID_HELP_COMBAT_TITLE = "Блокировка в бою"
	L.RAID_HELP_COMBAT_TEXT =
		"Игроков нельзя перемещать во время боя.\nЭто ограничение Blizzard для предотвращения ошибок."
	L.RAID_INFO_UNAVAILABLE = "Информация недоступна"
	L.RAID_NOT_IN_RAID = "Не в рейде"
	L.RAID_NOT_IN_RAID_DETAILS =
		"Вы в данный момент не состоите в рейдовой группе."
	L.RAID_CREATE_BUTTON = "Создать рейд"
	L.GROUP = "Группа"
	L.ALL = "Все"
	L.UNKNOWN_ERROR = "Неизвестная ошибка"
	L.RAID_ERROR_NOT_ENOUGH_SPACE =
		"Недостаточно места: выбрано %d игроков, %d свободных мест в Группе %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Перемещено %d игроков в Группу %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Не удалось переместить %d игроков"
	L.RAID_ERROR_READY_CHECK_PERMISSION =
		"Вы должны быть лидером рейда или помощником, чтобы начать проверку готовности."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "У вас нет сохраненных рейдовых подземелий."
	L.RAID_ERROR_LOAD_RAID_INFO =
		"Ошибка: Не удалось загрузить окно информации о рейде."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s поменялись местами"
	L.RAID_ERROR_SWAP_FAILED = "Обмен не удался: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s перемещен в Группу %d"
	L.RAID_ERROR_MOVE_FAILED = "Перемещение не удалось: %s"
	L.DIALOG_MIGRATE_TEXT =
		"Перенести группы друзей из FriendGroups в BetterFriendlist?\n\nЭто сделает:\n Создание всех групп из заметок BNet\n Назначение друзей в их группы\n Опционально открыть Мастер Очистки для проверки и очистки заметок\n\n|cffff0000Внимание: Это действие нельзя отменить!|r"
	L.DIALOG_MIGRATE_BTN1 = "Перенести и Проверить Заметки"
	L.DIALOG_MIGRATE_BTN2 = "Только Перенести"
	L.DIALOG_MIGRATE_BTN3 = "Отмена"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_FONTS = "Шрифты"
	L.SETTINGS_TAB_GENERAL = "Основные"
	L.SETTINGS_TAB_GROUPS = "Группы"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Наследовать цвет группы"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Наследовать цвет группы"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "ПКМ, чтобы унаследовать от группы"
	L.SETTINGS_INHERIT_TOOLTIP = "(Унаследовано от группы)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "Внешний вид"
	L.SETTINGS_TAB_ADVANCED = "Расширенные"
	L.SETTINGS_ADVANCED_DESC = "Advanced options and tools."
	L.SETTINGS_TAB_STATISTICS = "Статистика"
	L.SETTINGS_SHOW_BLIZZARD = "Показать опцию списка друзей Blizzard"
	L.SETTINGS_COMPACT_MODE = "Компактный Режим"
	L.SETTINGS_LOCK_WINDOW = "Закрепить окно"
	L.SETTINGS_LOCK_WINDOW_DESC =
		"Блокирует окно для предотвращения случайного перемещения."
	L.SETTINGS_FONT_SIZE = "Размер шрифта"
	L.SETTINGS_FONT_COLOR = "Цвет шрифта"
	L.SETTINGS_FONT_SIZE_SMALL = "Маленький (Компактный, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Обычный (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Большой (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Окрашивать Имена Классов"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Скрывать Пустые Группы"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Счетчики в Заголовке Группы"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC =
		"Выберите, как отображать количество друзей в заголовках групп"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Отфильтровано / Всего (По умолчанию)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "В сети / Всего"
	L.SETTINGS_HEADER_COUNT_BOTH = "Отфильтровано / В сети / Всего"
	L.SETTINGS_SHOW_FACTION_ICONS = "Показывать Иконки Фракций"
	L.SETTINGS_SHOW_REALM_NAME = "Показывать Название Сервера"
	L.SETTINGS_GRAY_OTHER_FACTION = "Затемнять Другую Фракцию"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Показывать Мобильных как AFK"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Показывать Текст Мобильных"
	L.SETTINGS_HIDE_MAX_LEVEL = "Скрывать Максимальный Уровень"
	L.SETTINGS_ACCORDION_GROUPS = "Группы-Аккордеоны (одна открыта за раз)"
	L.SETTINGS_SHOW_FAVORITES = "Показывать Группу Избранных"
	L.SETTINGS_SHOW_GROUP_FMT = "Показывать группу %s"
	L.SETTINGS_SHOW_GROUP_DESC_FMT =
		"Переключить видимость группы %s в списке друзей"
	L.SETTINGS_GROUP_COLOR = "Цвет Группы"
	L.SETTINGS_RENAME_GROUP = "Переименовать Группу"
	L.SETTINGS_DELETE_GROUP = "Удалить Группу"
	L.SETTINGS_DELETE_GROUP_DESC = "Удалить эту группу и исключить всех друзей"
	L.SETTINGS_EXPORT_TITLE = "Экспорт Настроек"
	L.SETTINGS_EXPORT_INFO =
		"Скопируйте текст ниже и сохраните его. Вы можете импортировать его на другом персонаже или аккаунте."
	L.SETTINGS_EXPORT_BTN = "Выбрать Всё"
	L.BUTTON_EXPORT = "Экспорт"
	L.SETTINGS_IMPORT_TITLE = "Импорт Настроек"
	L.SETTINGS_IMPORT_INFO =
		"Вставьте вашу строку экспорта ниже и нажмите Импорт.\n\n|cffff0000Внимание: Это заменит ВСЕ ваши группы и назначения!|r"
	L.SETTINGS_IMPORT_BTN = "Импорт"
	L.SETTINGS_IMPORT_CANCEL = "Отмена"
	L.SETTINGS_RESET_DEFAULT = "Сбросить к Стандартным"
	L.SETTINGS_RESET_SUCCESS = "Настройки сброшены к значениям по умолчанию!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Порядок групп сохранён!"
	L.SETTINGS_MIGRATION_COMPLETE = "Миграция Завершена!"
	L.SETTINGS_MIGRATION_FRIENDS = "Обработано друзей:"
	L.SETTINGS_MIGRATION_GROUPS = "Создано групп:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Создано назначений:"
	L.SETTINGS_NOTES_CLEANED = "Заметки очищены!"
	L.SETTINGS_NOTES_PRESERVED =
		"Заметки сохранены (вы можете очистить их вручную)."
	L.SETTINGS_EXPORT_SUCCESS = "Экспорт завершён! Скопируйте текст из диалога."
	L.SETTINGS_IMPORT_SUCCESS =
		"Импорт успешен! Все группы и назначения восстановлены."
	L.SETTINGS_IMPORT_FAILED = "Импорт Не Удался!\n\n"
	L.STATS_TOTAL_FRIENDS = "Всего Друзей: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00В сети: %d|r  |  |cff808080Не в сети: %d|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Запросы в Друзья (%d)"
	L.INVITE_BUTTON_ACCEPT = "Принять"
	L.INVITE_BUTTON_DECLINE = "Отклонить"
	L.INVITE_TAP_TEXT = "Нажмите, чтобы принять или отклонить"
	L.INVITE_MENU_DECLINE = "Отклонить"
	L.INVITE_MENU_REPORT = "Пожаловаться на Игрока"
	L.INVITE_MENU_BLOCK = "Блокировать Приглашения"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Все Друзья"
	L.FILTER_ONLINE_ONLY = "Только В Сети"
	L.FILTER_OFFLINE_ONLY = "Только Не В Сети"
	L.FILTER_WOW_ONLY = "Только WoW"
	L.FILTER_BNET_ONLY = "Только Battle.net"
	L.FILTER_HIDE_AFK = "Скрыть AFK/DND"
	L.FILTER_RETAIL_ONLY = "Только Retail"
	L.FILTER_TOOLTIP = "Быстрый Фильтр: %s"
	L.SORT_STATUS = "Статус"
	L.SORT_NAME = "Имя (А-Я)"
	L.SORT_LEVEL = "Уровень"
	L.SORT_ZONE = "Зона"
	L.SORT_ACTIVITY = "Недавняя Активность"
	L.SORT_GAME = "Игра"
	L.SORT_FACTION = "Фракция"
	L.SORT_GUILD = "Гильдия"
	L.SORT_CLASS = "Класс"
	L.SORT_REALM = "Сервер"
	L.SORT_CHANGED = "Сортировка изменена на: %s"
	L.SORT_NONE = "None"
	L.SORT_PRIMARY_LABEL = "Primary Sort"
	L.SORT_SECONDARY_LABEL = "Secondary Sort"
	L.SORT_PRIMARY_DESC = "Выберите, как будет отсортирован список друзей."
	L.SORT_SECONDARY_DESC =
		"Сортировать по этому, когда основные значения равны."
	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Группы"
	L.MENU_CREATE_GROUP = "Создать Группу"
	L.MENU_REMOVE_ALL_GROUPS = "Удалить из Всех Групп"
	L.MENU_RENAME_GROUP = "Переименовать Группу"
	L.MENU_DELETE_GROUP = "Удалить Группу"
	L.MENU_INVITE_GROUP = "Пригласить Всех в Группу"
	L.MENU_COLLAPSE_ALL = "Свернуть Все Группы"
	L.MENU_EXPAND_ALL = "Развернуть Все Группы"
	L.MENU_SETTINGS = "Настройки"
	L.MENU_SET_BROADCAST = "Установить Широковещательное Сообщение"
	L.MENU_IGNORE_LIST = "Управление Списком Игнорирования"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "Больше групп..."
	L.GROUPS_DIALOG_TITLE = "Группы для %s"
	L.MENU_COPY_CHARACTER_NAME = "Копировать имя персонажа"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "Копировать имя персонажа"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Отпустите, чтобы добавить в группу"
	L.TOOLTIP_HOLD_SHIFT = "Удерживайте Shift, чтобы сохранить в других группах"
	L.TOOLTIP_DRAG_HERE = "Перетащите друзей сюда, чтобы добавить"
	L.TOOLTIP_ERROR = "Ошибка"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "Нет доступных игровых аккаунтов"
	L.TOOLTIP_NO_INFO = "Недостаточно доступной информации"
	L.TOOLTIP_RENAME_GROUP = "Переименовать Группу"
	L.TOOLTIP_RENAME_DESC = "Нажмите, чтобы переименовать эту группу"
	L.TOOLTIP_GROUP_COLOR = "Цвет Группы"
	L.TOOLTIP_GROUP_COLOR_DESC = "Нажмите, чтобы изменить цвет этой группы"
	L.TOOLTIP_DELETE_GROUP = "Удалить Группу"
	L.TOOLTIP_DELETE_DESC = "Удалить эту группу и исключить всех друзей"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d друг(ов) приглашено в группу."
	L.MSG_NO_FRIENDS_AVAILABLE = "Нет друзей в сети для приглашения."
	L.MSG_GROUP_DELETED = "Группа '%s' удалена"
	L.MSG_IGNORE_LIST_EMPTY = "Ваш список игнорирования пуст."
	L.MSG_IGNORE_LIST_COUNT = "Список Игнорирования (%d игроков):"
	L.MSG_MIGRATION_ALREADY_DONE =
		"Миграция уже завершена. Используйте '/bfl migrate force' для повторного запуска."
	L.MSG_MIGRATION_STARTING = "Начало миграции из FriendGroups..."
	L.MSG_GROUP_ORDER_SAVED = "Порядок групп сохранён!"
	L.MSG_SETTINGS_RESET = "Настройки сброшены к значениям по умолчанию!"
	L.MSG_EXPORT_FAILED = "Экспорт не удался: %s"
	L.MSG_IMPORT_SUCCESS =
		"Импорт успешен! Все группы и назначения восстановлены."
	L.MSG_IMPORT_FAILED = "Импорт не удался: %s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "База данных недоступна!"
	L.ERROR_SETTINGS_NOT_INIT = "Фрейм не инициализирован!"
	L.ERROR_MODULES_NOT_LOADED = "Модули недоступны!"
	L.ERROR_GROUPS_MODULE = "Модуль групп недоступен!"
	L.ERROR_SETTINGS_MODULE = "Модуль настроек недоступен!"
	L.ERROR_FRIENDSLIST_MODULE = "Модуль списка друзей недоступен"
	L.ERROR_FAILED_DELETE_GROUP =
		"Не удалось удалить группу - модули не загружены"
	L.ERROR_FAILED_DELETE = "Не удалось удалить группу: %s"
	L.ERROR_MIGRATION_FAILED = "Миграция не удалась - модули не загружены!"
	L.ERROR_GROUP_NAME_EMPTY = "Название группы не может быть пустым"
	L.ERROR_GROUP_EXISTS = "Группа уже существует"
	L.ERROR_INVALID_GROUP_NAME = "Недопустимое название группы"
	L.ERROR_GROUP_NOT_EXIST = "Группа не существует"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Невозможно переименовать встроенные группы"
	L.ERROR_INVALID_GROUP_ID = "Недопустимый ID группы"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Невозможно удалить встроенные группы"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Друзья"
	L.GROUP_FAVORITES = "Избранные"
	L.GROUP_INGAME = "In Game"
	L.GROUP_NO_GROUP = "Без Группы"
	L.ONLINE_STATUS = "В Сети"
	L.OFFLINE_STATUS = "Не В Сети"
	L.STATUS_MOBILE = "Мобильный"
	L.STATUS_IN_APP = "В Приложении"
	L.UNKNOWN_GAME = "Неизвестная игра"
	L.BUTTON_ADD_FRIEND = "Добавить Друга"
	L.BUTTON_SEND_MESSAGE = "Отправить Сообщение"
	L.EMPTY_TEXT = "Пусто"
	L.LEVEL_FORMAT = "Ур %d"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Бета-функции"
	L.SETTINGS_BETA_FEATURES_DESC = "Включить экспериментальные функции"
	L.SETTINGS_BETA_FEATURES_ENABLE = "Включить бета-функции"
	L.SETTINGS_BETA_FEATURES_TOOLTIP =
		"Включает экспериментальные функции (Уведомления и т.д.)"
	L.SETTINGS_BETA_FEATURES_WARNING =
		"Предупреждение: Бета-функции могут содержать ошибки, проблемы с производительностью или неполную функциональность. Используйте на свой страх и риск."
	L.SETTINGS_BETA_FEATURES_LIST = "Доступные бета-функции:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Бета-функции |cff00ff00ВКЛЮЧЕНЫ|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Бета-функции |cffff0000ВЫКЛЮЧЕНЫ|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Бета-вкладки теперь видны в Настройках"
	L.SETTINGS_BETA_TABS_HIDDEN = "Бета-вкладки теперь скрыты"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Включить глобальную синхронизацию друзей"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Синхронизация настроек между персонажами"
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Глобальная синхронизация друзей"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Enable Deletion"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC =
		"Allow the sync process to remove friends from your list if they are removed from the database."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Synced Friends Database"

	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================

	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================

	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER =
		"Размер фрейма по умолчанию (Режим редактирования)"
	L.SETTINGS_FRAME_SIZE_INFO =
		"Установите предпочтительный размер по умолчанию для новых раскладок режима редактирования."
	L.SETTINGS_FRAME_WIDTH = "Ширина:"
	L.SETTINGS_FRAME_HEIGHT = "Высота:"
	L.SETTINGS_FRAME_RESET_SIZE = "Сбросить до 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Применить к текущей раскладке"
	L.SETTINGS_FRAME_RESET_ALL = "Сбросить все раскладки"

	-- ========================================
	-- DATA BROKER
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Друзья"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Левая кнопка: Переключить BetterFriendlist"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Правая кнопка: Настройки"
	L.BROKER_SETTINGS_ENABLE = "Включить брокер данных"
	L.BROKER_SETTINGS_SHOW_ICON = "Показать иконку"
	L.BROKER_SETTINGS_SHOW_TEXT = "Show Text"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Показать общее количество"
	L.BROKER_SETTINGS_SHOW_ONLINE = "Show Online Count"
	L.BROKER_SETTINGS_SHOW_BNET = "Show Battle.net Count"
	L.BROKER_SETTINGS_SHOW_WOW = "Show WoW Count"
	L.BROKER_SETTINGS_TEXT_FORMAT = "Text Format"
	L.BROKER_SETTINGS_TEXT_FORMAT_DESC = "Choose how the text is displayed on the broker"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Tooltip Detail Level"
	L.BROKER_SETTINGS_CLICK_ACTION = "Left Click Action"
	L.BROKER_FILTER_CHANGED = "Фильтр изменен на: %s"
	L.BROKER_FORMAT_FULL = "Full (Online: 5 | BNet: 3 | WoW: 2)"
	L.BROKER_FORMAT_COMPACT = "Compact (5 Online)"
	L.BROKER_FORMAT_MINIMAL = "Minimal (5)"
	L.BROKER_FORMAT_ICON = "Icon Only"
	L.BROKER_TOOLTIP_MODE_NONE = "None"
	L.BROKER_TOOLTIP_MODE_SIMPLE = "Simple (Counts only)"
	L.BROKER_TOOLTIP_MODE_FULL = "Full (List friends)"
	L.BROKER_ACTION_TOGGLE = "Toggle Window"
	L.BROKER_ACTION_SETTINGS = "Открыть настройки"
	L.BROKER_COLUMN_NAME = "Персонаж"
	L.BROKER_COLUMN_STATUS = "Status"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "Сервер"
	L.BROKER_COLUMN_NOTES = "Заметки"
	L.BROKER_COLUMN_NAME_DESC = "Display friend names"
	L.BROKER_COLUMN_STATUS_DESC = "Display online status/game"
	L.BROKER_COLUMN_ZONE_DESC = "Display current zone"
	L.BROKER_COLUMN_REALM_DESC = "Display realm name"
	L.BROKER_COLUMN_NOTES_DESC = "Показать заметки о друге"

	-- Broker
	L.BROKER_SETTINGS_LEFT_CLICK = "Действие левой кнопки"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Действие правой кнопки"
	L.BROKER_ACTION_OPEN_BNET = "Open BNet App"
	L.BROKER_ACTION_NONE = "None"
	L.BROKER_SETTINGS_INFO =
		"BetterFriendlist integrates with Data Broker display addons like Bazooka, ChocolateBar, and TitanPanel."
	L.BROKER_HEADER_WOW = "Друзья WoW"
	L.BROKER_HEADER_BNET = "Друзья Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Нет друзей WoW в сети"
	L.BROKER_NO_FRIENDS_ONLINE = "Нет друзей в сети"
	L.BROKER_TOTAL_ONLINE = "Всего: %d в сети / %d друзей"
	L.BROKER_FILTER_LABEL = "Фильтр: "
	L.BROKER_SORT_LABEL = "Сортировка: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Действия над другом ---"
	L.BROKER_HINT_CLICK_WHISPER = "Щелкнуть друга:"
	L.BROKER_HINT_WHISPER = " Whisper  "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Правая кнопка:"
	L.BROKER_HINT_CONTEXT_MENU = " Контекстное меню"
	L.BROKER_HINT_ALT_CLICK = "Alt+Щелчок:"
	L.BROKER_HINT_INVITE = " Invite/Join  "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Щелчок:"
	L.BROKER_HINT_COPY = " Копировать в чат"
	L.BROKER_HINT_ICON_ACTIONS = "--- Действия иконки брокера ---"
	L.BROKER_HINT_LEFT_CLICK = "Левая кнопка:"
	L.BROKER_HINT_TOGGLE = " Переключить BetterFriendlist"
	L.BROKER_HINT_RIGHT_CLICK = "Правая кнопка:"
	L.BROKER_HINT_SETTINGS = " Settings  "
	L.BROKER_HINT_MIDDLE_CLICK = "Средняя кнопка:"
	L.BROKER_HINT_CYCLE_FILTER = " Переключить фильтр"
	L.BROKER_SETTINGS_SHOW_LABEL = "Показать метку"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Разделить счетчики друзей WoW и BNet"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Основные настройки"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Интеграция брокера данных"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Взаимодействие"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Как использовать"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Протестированные аддоны отображения"
	L.BROKER_SETTINGS_INSTRUCTIONS = " Install a Data Broker display addon\n Enable Data Broker above"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Колонки подсказки"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Колонки подсказки"
	L.BROKER_COLUMN_LEVEL = "Уровень"
	L.BROKER_COLUMN_CHARACTER = "Персонаж"
	L.BROKER_COLUMN_GAME = "Игра / Приложение"
	L.BROKER_COLUMN_FACTION = "Фракция"
	L.BROKER_COLUMN_LEVEL_DESC = "Показать уровень персонажа"
	L.BROKER_COLUMN_CHARACTER_DESC = "Показать имя персонажа и иконку класса"
	L.BROKER_COLUMN_GAME_DESC =
		"Показать игру или приложение, в котором находится друг"
	L.BROKER_COLUMN_FACTION_DESC = "Display the faction icon"
	L.BROKER_ACTION_FRIENDS = "Friends"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Показывать Мобильных как Оффлайн
	L.SETTINGS_TREAT_MOBILE_OFFLINE =
		"Показывать мобильных пользователей как оффлайн"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC =
		"Отображать друзей с мобильного приложения в группе оффлайн"

	-- Feature 3: Показывать Заметки как Имя
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Показывать заметки как имя друга"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC =
		"Отображает заметки друзей как их имя, когда доступно"

	-- Feature 4: Масштаб Окна
	L.SETTINGS_WINDOW_SCALE = "Масштаб окна"
	L.SETTINGS_WINDOW_SCALE_DESC = "Масштабировать всё окно (50%% - 200%%)"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Недавние союзники недоступны в Classic"
	L.EDIT_MODE_NOT_AVAILABLE = "Режим редактирования недоступен в Classic"
	L.CLASSIC_COMPATIBILITY_INFO = "Работа в режиме совместимости Classic"
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Эта функция недоступна в Classic"
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Закрыть BetterFriendlist при открытии Гильдии"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC =
		"Автоматически закрывать BetterFriendlist при нажатии на вкладку Гильдия"
	L.SETTINGS_HIDE_GUILD_TAB = "Скрыть вкладку Гильдия"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "Скрыть вкладку Гильдия из списка друзей"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "Соблюдать иерархию UI"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC =
		"Предотвращает открытие BetterFriendlist поверх других окон UI (Персонаж, Книга заклинаний и т.д.). Требуется /reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 мин"
	L.LASTONLINE_MINUTES = "%d мин"
	L.LASTONLINE_HOURS = "%d ч"
	L.LASTONLINE_DAYS = "%d дн."
	L.LASTONLINE_MONTHS = "%d мес."
	L.LASTONLINE_YEARS = "%d лет"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "Классический интерфейс гильдии отключен"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist отключил классический интерфейс гильдии, так как только современный интерфейс гильдии Blizzard совместим с BetterFriendlist.\n\nВкладка Гильдия теперь открывает современный интерфейс гильдии Blizzard."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Use '/bfl migrate help' for help."
	L.LOADED_MESSAGE = "BetterFriendlist loaded."
	L.DEBUG_ENABLED = "Debug ENABLED"
	L.DEBUG_DISABLED = "Debug DISABLED"
	L.CONFIG_RESET = "Config reset."
	L.SEARCH_PLACEHOLDER = "Поиск друзей..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Гильдия"
	L.TAB_RAID = "Raid"
	L.TAB_QUICK_JOIN = "Quick Join"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Online"
	L.FILTER_SEARCH_OFFLINE = "Offline"
	L.FILTER_SEARCH_MOBILE = "Мобильные"
	L.FILTER_SEARCH_AFK = "АФК"
	L.FILTER_SEARCH_DND = "Не беспокоить"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "DND"

	-- Groups
	L.MIGRATION_CHECK = "Verifying migration..."
	L.MIGRATION_RESULT = "Migrated %d groups and %d assignments."
	L.MIGRATION_BNET_UPDATED = "Updated BNet assignments."
	L.MIGRATION_BNET_REASSIGN = "Reassigned BNet."
	L.MIGRATION_BNET_REASON = "(Reason: Temp BNet ID)"
	L.MIGRATION_WOW_RESULT = "Migrated %d WoW assignments."
	L.MIGRATION_WOW_FORMAT = "(Format: Char-Realm)"
	L.MIGRATION_WOW_FAIL = "Failed to migrate (missing realm)."
	L.MIGRATION_SMART_MIGRATING = "Migrating: %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Multi selection cleared - combat"

	-- Quick Join
	L.LEADER_LABEL = "Лидер:"
	L.MEMBERS_LABEL = "Участники:"
	L.AVAILABLE_ROLES = "Доступные роли"
	L.NO_AVAILABLE_ROLES = "No roles"
	L.AUTO_ACCEPT_TOOLTIP = "Auto Accept"
	L.MOCK_JOIN_REQUEST_SENT = "Mock Request Sent"
	L.QUICK_JOIN_NO_GROUPS = "No groups"
	L.UNKNOWN_GROUP = "Неизвестная группа"
	L.UNKNOWN = "Неизвестно"
	L.NO_QUEUE = "Нет очереди"
	L.LFG_ACTIVITY = "Активность поиска группы"
	L.ACTIVITY_DUNGEON = "Подземелье"
	L.ACTIVITY_RAID = "Рейд"
	L.ACTIVITY_PVP = "PvP"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "Импорт настроек"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "Экспорт настроек"
	L.DIALOG_DELETE_GROUP_TITLE = "Delete Group"
	L.DIALOG_RENAME_GROUP_TITLE = "Rename Group"
	L.DIALOG_CREATE_GROUP_TITLE = "Create Group"

	-- Tooltips
	L.TOOLTIP_LAST_CONTACT = "Last Contact:"
	L.TOOLTIP_AGO = " назад"
	L.TOOLTIP_LAST_ONLINE = "Последний раз в сети: %s"

	-- Notifications
	L.YES = "YES"
	L.NO = "NO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Предпросмотр %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Preview Position"
	L.EDITMODE_FRAME_WIDTH = "Width"
	L.EDITMODE_FRAME_HEIGHT = "Height"

	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT = "Reset layouts?\n\nIrreversible!"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Reset"
	L.MSG_LAYOUTS_RESET = "Layouts reset."
	L.DIALOG_TRIGGER_TITLE = "Create Trigger"
	L.DIALOG_TRIGGER_SELECT_GROUP = "Group:"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Min Friends:"
	L.DIALOG_TRIGGER_CREATE = "Создать"
	L.DIALOG_TRIGGER_CANCEL = "Отмена"
	L.ERROR_SELECT_GROUP = "Select group"
	L.MSG_TRIGGER_CREATED = "Trigger created: %d+ '%s'"
	L.ERROR_NO_GROUPS = "No groups."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Set Nickname %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "All"
	L.FILTER_ONLINE = "Online"
	L.FILTER_OFFLINE = "Offline"
	L.FILTER_WOW = "WoW"
	L.FILTER_BNET = "BNet"
	L.FILTER_HIDE_AFK = "No AFK"
	L.FILTER_RETAIL = "Retail"
	L.TOOLTIP_QUICK_FILTER = "Filter: %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Reload required.\n\nReload?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Reload"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Отмена"
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Enable Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Show Icon"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "BFL Icon"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Show Label"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Label 'Friends'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Show Total"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Total Count"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Split Count"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Split WoW/BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "WoW Icon"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Показать иконку WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "WoW Friends Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "BNet Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Показать иконку BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "BNet Friends Icon"
	L.STATUS_ENABLED = "|cff00ff00Enabled|r"
	L.STATUS_DISABLED = "|cffff0000Отключено|r"
	L.BROKER_WOW_FRIENDS = "Друзей WoW:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Global Sync"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Enable Friend Sync"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Показать удаленных"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Показать удаленных друзей"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Show deleted in list"
	L.TOOLTIP_RESTORE_FRIEND = "Restore"
	L.TOOLTIP_DELETE_FRIEND = "Delete"
	L.POPUP_EDIT_NOTE_TITLE = "Редактировать заметку"
	L.BUTTON_SAVE = "Сохранить"
	L.BUTTON_CANCEL = "Отмена"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Друзья: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d tot"
	L.BROKER_CURRENT_FILTER = "Filter:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Средняя кнопка: Переключить фильтр"
	L.BROKER_AND_MORE = "  ... and %d others"
	L.BROKER_WHISPER_AGO = " (шепот %s назад)"
	L.BROKER_TOTAL_LABEL = "Всего:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d friends"
	L.MENU_CHANGE_COLOR = "Изменить цвет"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Tooltip Error|r"
	L.STATUS_LABEL = "Статус:"
	L.STATUS_AWAY = "Отошел"
	L.STATUS_DND_FULL = "Do Not Disturb"
	L.GAME_LABEL = "Игра:"
	L.REALM_LABEL = "Сервер:"
	L.CLASS_LABEL = "Класс:"
	L.FACTION_LABEL = "Фракция:"
	L.ZONE_LABEL = "Зона:"
	L.NOTE_LABEL = "Заметка:"
	L.BROADCAST_LABEL = "Msg:"
	L.ACTIVE_SINCE_FMT = "Активен с: %s"
	L.HINT_RIGHT_CLICK_OPTIONS = "Right-Click Options"
	L.HEADER_ADD_FRIEND = "|cffffd700Добавить %s в %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Debug Migrate - Total:"
	L.MIGRATION_DEBUG_BNET = "Debug Migrate - BNet old:"
	L.MIGRATION_DEBUG_WOW = "Debug Migrate - WoW no realm:"
	L.ERROR_INVALID_PARAMS = "Invalid params"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Unignore"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE = "Recent Allies unavailable."
	L.RECENT_ALLIES_INVITE = "Пригласить"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Player offline"
	L.RECENT_ALLIES_PIN_EXPIRES = "Закрепление истекает через %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Lvl %d %s"
	L.RECENT_ALLIES_NOTE = "Note: %s"
	L.RECENT_ALLIES_ACTIVITY = "Недавняя активность:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Приведи друга"
	L.RAF_RECRUITMENT = "Набор друзей"
	L.RAF_NO_RECRUITS_DESC = "No recruits."
	L.RAF_PENDING_RECRUIT = "Pending"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Earned:"
	L.RAF_NEXT_REWARD_AFTER = "Next in %d/%d months"
	L.RAF_FIRST_REWARD = "First:"
	L.RAF_NEXT_REWARD = "Next:"
	L.RAF_REWARD_MOUNT = "Mount"
	L.RAF_REWARD_TITLE_DEFAULT = "Титул"
	L.RAF_REWARD_TITLE_FMT = "Title: %s"
	L.RAF_REWARD_GAMETIME = "Game Time"
	L.RAF_MONTH_COUNT = "%d Months"
	L.RAF_CLAIM_REWARD = "Claim"
	L.RAF_VIEW_ALL_REWARDS = "View All"
	L.RAF_ACTIVE_RECRUIT = "Активен"
	L.RAF_TRIAL_RECRUIT = "Пробная версия"
	L.RAF_INACTIVE_RECRUIT = "Неактивен"
	L.RAF_OFFLINE = "Offline"
	L.RAF_TOOLTIP_DESC = "До %d месяцев"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d months"
	L.RAF_ACTIVITY_DESCRIPTION = "Activity for %s"
	L.RAF_REWARDS_LABEL = "Rewards"
	L.RAF_YOU_EARNED_LABEL = "Earned:"
	L.RAF_CLICK_TO_CLAIM = "Click to claim"
	L.RAF_LOADING = "Загрузка..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== RAF ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Current"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Legacy v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Months: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Новобранцев: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Rewards Avail:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Получено]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Claimable]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Доступно]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Заблокировано]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d месяцев)"
	L.RAF_CHAT_MORE_REWARDS = "    ... and %d others"
	L.RAF_CHAT_USE_UI = "|cff00ff00Use UI for details.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00RAF:|r Game time available."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_TAB_DATABROKER = "Data Broker"
	L.MSG_GROUP_RENAMED = "Group renamed '%s'"
	L.ERROR_RENAME_FAILED = "Rename failed"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Group order: %s"
	L.ERROR_EXPORT_SERIALIZE = "Serialize Error"
	L.ERROR_IMPORT_EMPTY = "Empty String"
	L.ERROR_IMPORT_DECODE = "Decode Error"
	L.ERROR_IMPORT_DESERIALIZE = "Deserialize Error"
	L.ERROR_EXPORT_VERSION = "Version Not Supported"
	L.ERROR_EXPORT_STRUCTURE = "Invalid Structure"

	-- Statistics
	L.STATS_NO_HEALTH_DATA = "No health data"
	L.STATS_NO_CLASS_DATA = "No class data"
	L.STATS_NO_LEVEL_DATA = "No level data"
	L.STATS_NO_REALM_DATA = "No realm data"
	L.STATS_NO_GAME_DATA = "No game data"
	L.STATS_NO_MOBILE_DATA = "No mobile data"
	L.STATS_SAME_REALM = "Same Realm: %d (%d%%)  |  Others: %d (%d%%)"
	L.STATS_TOP_REALMS = "\nТоп серверов:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\nДругие: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Notes: %d (%d%%)\nFavorites: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max: %d\n70-79: %d\n60-69: %d\n<60: %d\nAvg: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Active: %d (%d%%)|r\n|cffffd700Med: %d (%d%%)|r\n|cffffaa00Old: %d (%d%%)|r\n|cffff6600Stale: %d (%d%%)|r\n|cffff0000Inactive: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffАльянс: %d|r\n|cffff0000Орда: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "Переместить вниз"
	L.TOOLTIP_MOVE_DOWN_DESC = "Move group down"
	L.TOOLTIP_MOVE_UP = "Move Up"
	L.TOOLTIP_MOVE_UP_DESC = "Move group up"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "Friend not in WoW"
	L.TRAVEL_PASS_WOW_CLASSIC = "Friend in WoW Classic."
	L.TRAVEL_PASS_WOW_MAINLINE = "Friend in WoW."
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Different Version"
	L.TRAVEL_PASS_NO_INFO = "Info unavailable"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Different Region"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "No game account"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Show Blizzard List"
	L.MENU_COMBAT_LOCKED = "Combat Locked"
	L.MENU_SET_NICKNAME = "Установить псевдоним"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Настройки BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Search..."
	L.RAF_NEXT_REWARD_HELP = "RAF Info"
	L.WHO_LEVEL_FORMAT = "Level %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Недавние союзники"
	L.CONTACTS_MENU_NAME = "Меню контактов"
	L.BATTLENET_UNAVAILABLE = "BNet Unavail"
	L.BATTLENET_BROADCAST = "Broadcast"
	L.FRIENDS_LIST_ENTER_TEXT = "Msg..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Search..."
	L.RAF_SPLASH_SCREEN_TITLE = "RAF"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "Recruit Friends!"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Reward Info"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Name Format"
	L.SETTINGS_NAME_FORMAT_DESC =
		"Customize:\n|cffFFD100%name%|r -Name\n|cffFFD100%note%|r -Note\n|cffFFD100%nickname%|r -Nickname\n|cffFFD100%battletag%|r -Tag"
	L.SETTINGS_NAME_FORMAT_LABEL = "Формат:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Name Format"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Enter format."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"This setting is disabled because the addon 'FriendListColors' is managing name colors/formats."
	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "'In Game' Group"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Group in-game friends"
	L.SETTINGS_INGAME_MODE_WOW = "WoW Only"
	L.SETTINGS_INGAME_MODE_ANY = "Any Game"
	L.SETTINGS_INGAME_MODE_LABEL = "   Режим:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Mode"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Choose friends."

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Display Options"
	L.SETTINGS_BEHAVIOR_HEADER = "Behavior"
	L.SETTINGS_GROUP_MANAGEMENT = "Group Management"
	L.SETTINGS_FONT_SETTINGS = "Font"
	L.SETTINGS_GROUP_ORDER = "Порядок групп"
	L.SETTINGS_MIGRATION_HEADER = "FriendGroups Migration"
	L.SETTINGS_MIGRATION_DESC = "Migrate from FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migrate"
	L.SETTINGS_MIGRATE_TOOLTIP = "Import"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "Экспортировать настройки в строку"
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Warning: Overwrites!|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Export"
	L.SETTINGS_IMPORT_TOOLTIP = "Import"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Synchronize across characters."

	-- Statistics
	L.STATS_HEADER = "Statistics"
	L.STATS_DESC = "Summary"
	L.STATS_OVERVIEW_HEADER = "Summary"
	L.STATS_HEALTH_HEADER = "Health"
	L.STATS_CLASSES_HEADER = "Top 5 Classes"
	L.STATS_REALMS_HEADER = "Realms"
	L.STATS_ORGANIZATION_HEADER = "Org"
	L.STATS_LEVELS_HEADER = "Levels"
	L.STATS_GAMES_HEADER = "Games"
	L.STATS_MOBILE_HEADER = "Mobile vs PC"
	L.STATS_FACTIONS_HEADER = "Factions"
	L.STATS_REFRESH_BTN = "Refresh"
	L.STATS_REFRESH_TOOLTIP = "Refresh Stats"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters

	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Hide Empty"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Show Faction Icons"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Show Realm"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Fade Others"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Mobile as AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Hide Max Lvl"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Show Blizz Btn"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Show Favorites"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "One Open"
	L.SETTINGS_COMPACT_MODE_DESC = "Compact"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Enable ElvUI Skin"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Requires ElvUI."
	L.DIALOG_ELVUI_RELOAD_TEXT = "Reload Required.\nReload?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Yes"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "No"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "DB not init."
	L.CORE_SHOW_BLIZZARD_ENABLED = "Blizzard Option |cff20ff20ON|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Blizzard Option |cffff0000OFF|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Debug unavail"
	L.CORE_DB_MODULE_NOT_AVAIL = "DB Module unavail"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Activity ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Friends Active: %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "Beta Disabled!"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Enable:|r ESC > AddOns > BFL"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Stats not loaded"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Statistics ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Summary:|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE =
		"  Tot: |cffffffff%d|r  On: |cff00ff00%d|r (%.0f%%)  Off: |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet: |cff0099ff%d|r  |  WoW: |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Health:|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Active: |cff00ff00%d|r  Med: |cffffd700%d|r"
	L.CORE_STATS_HEALTH_STALE = "  Old: |cffff6600%d|r  Dormant: |cffff0000%d|r"
	L.CORE_STATS_NO_HEALTH_DATA = "  No Data"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Classes:|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Levels:|r"
	L.CORE_STATS_LEVEL_BREAKDOWN =
		"  Max: |cffffffff%d|r  70+: |cffffffff%d|r  60+: |cffffffff%d|r  <60: |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Avg: |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Realms:|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Same: |cffffffff%d|r  |  Other: |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Top:"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Factions:|r"
	L.CORE_STATS_FACTION_DATA = "  Alli: |cff0080ff%d|r  |  Horde: |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Games:|r"
	L.CORE_STATS_GAME_WOW = "  Retail: |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic: |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4: |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS: |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC: |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  App: |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Other: |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Mobile vs PC:|r"
	L.CORE_STATS_MOBILE_DATA = "  PC: |cffffffff%d|r (%.0f%%)  Mobile: |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Org:|r"
	L.CORE_STATS_ORG_DATA = "  Notes: |cffffffff%d|r  Fav: |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Config not loaded"
	L.CORE_MOCK_INVITES_ENABLED = "Inv. Mock |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Added inv. mock |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Tip:|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Cleared"
	L.CORE_NO_MOCK_INVITES = "No invites"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Monitor not loaded"
	L.CORE_MEMORY_USAGE = "Mem: %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "QJ not loaded"
	L.CORE_RAIDFRAME_NOT_LOADED = "RaidFrame not loaded"
	L.CORE_PREVIEW_MODE_NOT_LOADED = "Preview not loaded"
	L.CORE_ACTIVITY_TEST_NOT_LOADED = "ActivityTest not loaded"
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Compat ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Ver Client:|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Flavor:|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00TWW|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffffОсновная версия|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Avail:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menu Mod: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Allies Rec: %s"
	L.CORE_FEATURE_EDIT_MODE = "  Режим редактирования: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Compat:|r %s"
	L.CORE_COMPAT_ACTIVE = "Режим совместимости Classic активен"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000Не загружено|r"
	L.CORE_CHANGELOG_RESET = "Changelog reset."
	L.CORE_CHANGELOG_NOT_LOADED = "Changelog not loaded"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Debug ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard:|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000No settings|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00BFL attrs:|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00In UIPanel:|r |cff00ff00YES|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00In UIPanel:|r |cffff0000NO|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800WARN:|r FriendsFrame in UIPanel!"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Setting:|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BFL v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Commands:|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Toggle"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/bfl settings|r - Config"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/bfl help|r - Help"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Open changelog window"
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - Сбросить позицию окна"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Debug:|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/bfl debug|r - Toggle debug"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Show DB"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Show Activity"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Show Stats"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Test Rules"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join:|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Mock"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Dungeon"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Raid"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Stress"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - Events"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Clear"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - List"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock:|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Create Raid"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Invite"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Clear Invites"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Preview:|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - On"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Off"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Fake Data)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame:|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - 25p"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - 40p"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - 10p"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - 20p"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - RC Sim"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Role Sim"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Move Sim"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Clear"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Perf:|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Show"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Enable"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Reset"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Memory"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Test:|r"
	L.CORE_HELP_TEST_ACTIVITY = "  |cffffffff/bfl test|r - Test"
	L.TESTSUITE_PERFY_HELP = "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"
	L.TESTSUITE_PERFY_STARTING = "Starting Perfy stress test for %d seconds"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Perfy stress test already running"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Perfy addon not loaded (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Perfy slash command not available"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy stress action failed: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy stress test finished"
	L.TESTSUITE_PERFY_ABORTED = "Perfy stress test stopped: %s"
	L.CORE_HELP_LINK = "|cff20ff20Help:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Загружено. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Accepted %s"
	L.MOCK_INVITE_DECLINED = "Declined %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Stats reset"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Perf ===|r"
	L.PERF_QJ_OPS = "|cffffd700QJ Ops:|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Friends Ops:|r"
	L.PERF_MEMORY = "|cffffd700Memory:|r"
	L.PERF_TARGETS = "|cffffd700Target:|r"
	L.PERF_AUTO_ENABLED = "Auto-monitor |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Created 25p"
	L.RAID_MOCK_CREATED_40 = "Created 40p"
	L.RAID_MOCK_CREATED_10 = "Created 10p"
	L.RAID_MOCK_CREATED_MYTHIC = "Created 20p (M)"
	L.RAID_MOCK_STRESS = "Stress test"
	L.RAID_WARN_CPU = "|cffff8800Warn:|r High CPU"
	L.RAID_NO_MOCK_DATA = "No data. '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Sim Ready Check..."
	L.RAID_MOCK_CLEARED = "Cleared"
	L.RAID_EVENT_COMMANDS = "|cff00ff00Raid Events:|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Mgmt:|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Config"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - List"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Stress"
	L.RAID_HELP_EVENTS = "|cffffcc00Sim:|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Raid Config:|r"
	L.RAID_INFO_HEADER = "|cff00ff00Mock Info:|r"
	L.RAID_NO_MOCK_ACTIVE = "No mock"
	L.RAID_DYN_UPDATES = "Updates: %s"
	L.RAID_UPDATE_INTERVAL = "Int: %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Mock: %s"
	L.RAID_DYN_UPDATES_STATUS = "  Dyn: %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Int: %.1f s"
	L.RAID_MEMBERS_STATUS = "  Участники: %d"
	L.RAID_TOTAL_MEMBERS = "  Tot: %d"
	L.RAID_COMPOSITION = "Состав рейда"
	L.RAID_STATUS = "  Status: %d off, %d dead"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Created icon test"
	L.QJ_MOCK_CREATED_STRESS = "Created test 50"
	L.QJ_SIM_ADDED = "Sim: Added"
	L.QJ_SIM_REMOVED = "Sim: Removed"
	L.QJ_ERR_NO_GROUPS_REMOVE = "Nothing to remove"
	L.QJ_ERR_NO_GROUPS_UPDATE = "Nothing to update"
	L.QJ_EVENT_COMMANDS = "|cff00ff00QJ Events:|r"
	L.QJ_LIST_HEADER = "|cff00ff00QJ Groups:|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00QJ Config:|r"
	L.QJ_EXT_FOOTER = "|cff888888Mock green.|r"
	L.QJ_SIM_UPDATED_FMT = "Sim: %s up."
	L.QJ_ADDED_GROUP_FMT = "Added: %s"
	L.QJ_NO_GROUPS_HINT = "No groups."
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Icons"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config:|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Config"

	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Reset Guild UI warning."
	L.CMD_RESET_HEADER = "Reset:"
	L.CMD_RESET_HELP_WARNING = "Reset Guild warning"

	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "   Проблемы GitHub"
	L.CHANGELOG_SUPPORT = "   Поддержка"
	L.CHANGELOG_HEADER_COMMUNITY = "Community:"
	L.CHANGELOG_HEADER_VERSION = "Ver %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "New Version!"
	L.CHANGELOG_TOOLTIP_CLICK = "Click for details"
	L.CHANGELOG_POPUP_DISCORD = "Discord"
	L.CHANGELOG_POPUP_GITHUB = "Bugs"
	L.CHANGELOG_POPUP_SUPPORT = "Support"
	L.CHANGELOG_TITLE = "Changelog"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Max Lvl"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Group %d"

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6мс = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3мс = 30 FPS"
	L.PERF_WARNING = "   >50ms = Warning"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Мобильный"
	L.RAF_RECRUITMENT = "Приведи друга"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Окрашивает имена друзей в цвет их класса"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Контур шрифта"
	L.SETTINGS_FONT_SHADOW = "Тень шрифта"
	L.SETTINGS_FONT_OUTLINE_NONE = "Нет"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Контур"
	L.SETTINGS_FONT_OUTLINE_THICK = "Толстый контур"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Монохромный"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "Редактировать заметку"
	L.MENU_SHOW_SEARCH = "Показать поиск"
	L.MENU_QUICK_FILTER = "Быстрый фильтр"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Включить значок избранного"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC =
		"Показывает значок звезды на кнопке друга для избранных."
	L.SETTINGS_FAVORITE_ICON_STYLE = "Значок избранного"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC =
		"Выберите, какой значок использовать для избранных."
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "Значок BFL"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "Значок Blizzard"
	L.SETTINGS_SHOW_FACTION_BG = "Показать фон фракции"
	L.SETTINGS_SHOW_FACTION_BG_DESC =
		"Показывает цвет фракции в качестве фона для кнопки друга."

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "Режим Stреймера"
	L.STREAMER_MODE_DESC =
		"Варианты конфиденциальности для потоковой трансляции или записи."
	L.SETTINGS_ENABLE_STREAMER_MODE =
		"Показать кнопку режима потоковой трансляции"
	L.STREAMER_MODE_ENABLE_DESC =
		"Показывает кнопку в главном фрейме для переключения режима потоковой трансляции."
	L.STREAMER_MODE_HIDDEN_NAME = "Скрытый формат имени"
	L.STREAMER_MODE_HEADER_TEXT = "Пользовательский текст заголовка"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"Текст для отображения в заголовке Battle.net при активном режиме потоковой трансляции (например, 'Stream Mode')."
	L.STREAMER_MODE_BUTTON_TOOLTIP = "Переключить режим потоковой трансляции"
	L.STREAMER_MODE_BUTTON_DESC =
		"Нажмите для включения/отключения режима конфиденциальности."
	L.SETTINGS_PRIVACY_OPTIONS = "Варианты конфиденциальности"
	L.SETTINGS_STREAMER_NAME_FORMAT = "Значения имен"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC =
		"Выберите, как отображаются имена в режиме потоковой трансляции."
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "Принудительное использование BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME =
		"Принудительное использование прозвища"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "Принудительное использование заметки"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "Использовать фиолетовый цвет заголовка"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"Измените фон заголовка Battle.net на фиолетовый Twitch при активном режиме потоковой трансляции."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "Рейд"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "Включить сочетания клавиш"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"Включить или отключить все пользовательские сочетания клавиш мыши на экране рейда."
	L.SETTINGS_RAID_SHORTCUTS_TITLE = "Сочетания клавиш рейда"
	L.SETTINGS_RAID_ACTION_MASS_MOVE = "Массовое перемещение"
	L.SETTINGS_RAID_ACTION_TARGET = "Цель подразделения"
	L.SETTINGS_RAID_ACTION_MAIN_TANK = "Назначить главного танка"
	L.SETTINGS_RAID_ACTION_MAIN_ASSIST = "Назначить главного помощника"
	L.SETTINGS_RAID_ACTION_RAID_LEAD = "Назначить лидера рейда"
	L.SETTINGS_RAID_ACTION_PROMOTE = "Повысить помощника"
	L.SETTINGS_RAID_ACTION_DEMOTE = "Понизить помощника"
	L.SETTINGS_RAID_ACTION_KICK = "Удалить из группы"
	L.SETTINGS_RAID_ACTION_INVITE = "Пригласить в группу"
	L.SETTINGS_RAID_MODIFIER_NONE = "Нет"
	L.SETTINGS_RAID_MODIFIER_SHIFT = "Shift"
	L.SETTINGS_RAID_MODIFIER_CTRL = "Ctrl"
	L.SETTINGS_RAID_MODIFIER_ALT = "Alt"
	L.SETTINGS_RAID_MOUSE_LEFT = "Левая кнопка"
	L.SETTINGS_RAID_MOUSE_RIGHT = "Правая кнопка"
	L.SETTINGS_RAID_MOUSE_MIDDLE = "Средняя кнопка"
	L.SETTINGS_RAID_DESC =
		"Настройте сочетания клавиш мыши для управления рейдом и группой."
	L.SETTINGS_RAID_MODIFIER_LABEL = "Мод:"
	L.SETTINGS_RAID_BUTTON_LABEL = "Кнп:"
	L.SETTINGS_RAID_WARNING =
		"Примечание: Сочетания клавиш - это защищенные действия (только вне боя)."
	L.SETTINGS_RAID_ERROR_RESERVED = "Это сочетание зарезервировано."

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "Размеры Окна"
	L.SETTINGS_FRAME_SCALE = "Масштаб:"
	L.SETTINGS_FRAME_WIDTH = "Ширина:"
	L.SETTINGS_FRAME_HEIGHT = "Высота:"
	L.SETTINGS_FRAME_WIDTH_DESC = "Отрегулировать ширину окна"
	L.SETTINGS_FRAME_HEIGHT_DESC = "Отрегулировать высоту окна"
	L.SETTINGS_FRAME_SCALE_DESC = "Отрегулировать масштаб окна"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "Выравнивание Заголовка Группы"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC =
		"Установить выравнивание текста имени группы"
	L.SETTINGS_ALIGN_LEFT = "Слева"
	L.SETTINGS_ALIGN_CENTER = "По центру"
	L.SETTINGS_ALIGN_RIGHT = "Справа"
	L.SETTINGS_SHOW_GROUP_ARROW = "Показать Стрелку Сворачивания"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC =
		"Показать или скрыть значок стрелки для сворачивания групп"
	L.SETTINGS_GROUP_ARROW_ALIGN = "Выравнивание Стрелки Сворачивания"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC =
		"Установить выравнивание значка стрелки сворачивания/разворачива��������������ия"
	L.SETTINGS_FONT_FACE = "Шрифт"
	L.SETTINGS_COLOR_GROUP_COUNT = "Цвет Счётчика Группы"
	L.SETTINGS_COLOR_GROUP_ARROW = "Цвет Стрелки Сворачивания"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Унаследовать Цвет из Группы"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Унаследовать Цвет из Группы"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Параметры Заголовка Группы"
	L.SETTINGS_GROUP_FONT_HEADER = "Шрифт Заголовка Группы"
	L.SETTINGS_GROUP_COLOR_HEADER = "Цвета Заголовка Группы"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Правый клик для наследования из Группы"
	L.SETTINGS_INHERIT_TOOLTIP = "(Унаследовано из Группы)"

	-- Misc
	L.TOOLTIP_AGO_PREFIX = ""
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "Глобальный Список Игнора"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "Настройки Имени Друга"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "Настройки Информации о Друге"
	L.SETTINGS_FONT_TABS_TITLE = "Текст Вкладок"
	L.SETTINGS_FONT_RAID_TITLE = "Текст Имени Рейда"
	L.SETTINGS_FONT_SIZE_NUM = "Размер Шрифта"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "Синхронизация заметок групп"
	L.SETTINGS_SYNC_GROUPS_NOTE = "Синхронизировать группы в заметки друзей"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"Записывает назначения групп в заметки друзей в формате FriendGroups (Заметка#Группа1#Группа2). Позволяет делиться группами между аккаунтами или с пользователями FriendGroups."
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"Включить синхронизацию заметок групп?\n\n|cffff8800Внимание:|r Заметки BattleNet ограничены 127 символами, заметки друзей WoW - 48 символами. Группы, превышающие лимит, будут пропущены в заметке, но сохранятся в базе данных.\n\nСуществующие заметки будут обновлены. Продолжить?"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "Включить"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "Отмена"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"Синхронизация заметок групп отключена.\n\nХотите открыть Мастер очистки заметок, чтобы удалить суффиксы групп из заметок друзей?"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "Открыть мастер очистки"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "Оставить заметки"
	L.MSG_SYNC_GROUPS_STARTED = "Синхронизация групп в заметки друзей..."
	L.MSG_SYNC_GROUPS_COMPLETE =
		"Синхронизация завершена. Обновлено: %d, Пропущено (лимит): %d"
	L.MSG_SYNC_GROUPS_PROGRESS = "Синхронизация заметок: %d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT =
		"Достигнут лимит заметки для %s - некоторые группы пропущены"

	-- ========================================
	-- MESSAGES (Phase 22 - Asian/Cyrillic)
	-- ========================================"
	L.MSG_INVITE_CONVERT_RAID = "Преобразование группы в рейд..."
	L.MSG_INVITE_RAID_FULL = "Рейд полон (%d/40). Приглашения остановлены."

	-- ========================================
	-- SETTINGS (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "Показать приветствующее сообщение"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC =
		"Показывать сообщение загрузки аддона в чат при входе."

	-- ========================================
	-- RAID CONVERSION / MOCK (Phase 21+)
	-- ========================================
	L.RAID_GROUP_NAME = "Группа %d"
	L.RAID_CONVERT_TO_PARTY = "Преобразовать в Группу"
	L.RAID_CONVERT_TO_RAID = "Преобразовать в Рейд"
	L.RAID_MUST_BE_LEADER = "Вы должны быть лидером, чтобы это сделать"
	L.RAID_CONVERT_TOO_MANY = "В группе слишком много игроков для вечеринки"
	L.RAID_ERR_NOT_IN_GROUP = "Вы не в группе"
	L.MOCK_INVITE_ACCEPTED = "Принято тестовое приглашение от %s"
	L.MOCK_INVITE_DECLINED = "Отклонено тестовое приглашение от %s"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "Мастер очистки заметок"
	L.WIZARD_DESC =
		"Удалите данные FriendGroups (#Группа1#Группа2) из заметок друзей. Проверьте очищенные заметки перед применением."
	L.WIZARD_BTN = "Очистка заметок"
	L.WIZARD_BTN_TOOLTIP =
		"Открыть мастер очистки данных FriendGroups из заметок друзей"
	L.WIZARD_HEADER = "Очистка заметок"
	L.WIZARD_HEADER_DESC =
		"Удалите суффиксы FriendGroups из заметок друзей. Сначала создайте резервную копию, затем проверьте и примените изменения."
	L.WIZARD_COL_ACCOUNT = "Имя аккаунта"
	L.WIZARD_COL_BATTLETAG = "BattleTag"
	L.WIZARD_COL_NOTE = "Текущая заметка"
	L.WIZARD_COL_CLEANED = "Очищенная заметка"
	L.WIZARD_SEARCH_PLACEHOLDER = "Поиск..."
	L.WIZARD_BACKUP_BTN = "Резервная копия"
	L.WIZARD_BACKUP_DONE = "Сохранено!"
	L.WIZARD_BACKUP_TOOLTIP =
		"Сохранить все текущие заметки друзей в базу данных как резервную копию."
	L.WIZARD_BACKUP_SUCCESS = "Создана резервная копия заметок для %d друзей."
	L.WIZARD_APPLY_BTN = "Применить очистку"
	L.WIZARD_APPLY_TOOLTIP =
		"Записать очищенные заметки обратно. Будут обновлены только заметки, отличающиеся от оригинала."
	L.WIZARD_APPLY_CONFIRM =
		"Применить очищенные заметки ко всем друзьям?\n\n|cffff8800Текущие заметки будут перезаписаны. Убедитесь, что вы создали резервную копию!|r"
	L.WIZARD_APPLY_SUCCESS = "%d заметок успешно обновлено."
	L.WIZARD_APPLY_PROGRESS_FMT = "Прогресс: %d/%d | %d успешно | %d ошибок"
	L.WIZARD_STATUS_FMT =
		"Показано %d из %d друзей | %d с данными групп | %d ожидающих изменений"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "Просмотр резервной копии"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"Откройте просмотр резервных копий, чтобы увидеть все сохраненные заметки и сравнить их с текущими."
	L.WIZARD_BACKUP_VIEWER_TITLE = "Просмотр резервных копий заметок"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"Просматривайте сохраненные заметки друзей и сравнивайте их с текущими. При необходимости можно восстановить исходные заметки."
	L.WIZARD_COL_BACKED_UP = "Сохраненная заметка"
	L.WIZARD_COL_CURRENT = "Текущая заметка"
	L.WIZARD_RESTORE_BTN = "Восстановить копию"
	L.WIZARD_RESTORE_TOOLTIP =
		"Восстанавливает исходные заметки из резервной копии. Будут обновлены только заметки, отличающиеся от резервной копии."
	L.WIZARD_RESTORE_CONFIRM =
		"Восстановить все заметки из резервной копии?\n\n|cffff8800Текущие заметки будут перезаписаны сохраненными версиями.|r"
	L.WIZARD_RESTORE_SUCCESS = "%d заметок успешно восстановлено."
	L.WIZARD_NO_BACKUP =
		"Резервная копия заметок не найдена. Сначала используйте Мастер очистки заметок для создания копии."
	L.WIZARD_BACKUP_STATUS_FMT =
		"Показано %d из %d записей | %d изменено после резервного копирования | Копия: %s"
end)
