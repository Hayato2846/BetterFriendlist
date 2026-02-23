-- Locales/ruRU.lua
-- Russian (Русский) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("ruRU", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Упрощённый режим"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"Отключает портрет игрока, скрывает параметры поиска/сортировки, расширяет фрейм и смещает вкладки для компактного макета"
	L.MENU_CHANGELOG = "Список изменений"
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
		"Удалить группу '%s'?\n\nВсе друзья будут исключены из этой группы"
	L.DIALOG_RESET_SETTINGS_TEXT =
		"Сбросить все настройки к значениям по умолчанию?"
	L.DIALOG_RESET_BTN1 = "Сбросить"
	L.DIALOG_RESET_BTN2 = "Отмена"
	L.DIALOG_UI_PANEL_RELOAD_TEXT =
		"Изменение настройки иерархии UI требует перезагрузки интерфейса.\n\nПерезагрузить сейчас?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Перезагрузить"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Отмена"
	L.MSG_RELOAD_REQUIRED =
		"Для корректного применения этого изменения в Classic требуется перезагрузка"
	L.MSG_RELOAD_NOW = "Перезагрузить интерфейс сейчас?"
	L.RAID_HELP_TITLE = "Справка по рейду"
	L.RAID_HELP_TEXT = "Нажмите для справки по списку рейда"
	L.RAID_HELP_MULTISELECT_TITLE = "Множественный выбор"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Удерживайте Ctrl и кликните левой кнопкой, чтобы выбрать нескольких игроков.\nПосле выбора перетащите их в любую группу, чтобы переместить всех сразу."
	L.RAID_HELP_MAINTANK_TITLE = "Главный танк"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s на игроке, чтобы назначить его главным танком.\nРядом с его именем появится значок танка."
	L.RAID_HELP_MAINASSIST_TITLE = "Главный помощник"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s на игроке, чтобы назначить его главным помощником.\nРядом с его именем появится значок помощника."
	L.RAID_HELP_LEAD_TITLE = "Лидер рейда"
	L.RAID_HELP_LEAD_TEXT = "%s на игроке, чтобы назначить Лидером Рейда"
	L.RAID_HELP_PROMOTE_TITLE = "Помощник"
	L.RAID_HELP_PROMOTE_TEXT = "%s на игроке, чтобы назначить/снять Помощником"
	L.RAID_HELP_DRAGDROP_TITLE = "Перетаскивание"
	L.RAID_HELP_DRAGDROP_TEXT =
		"Перетащите любого игрока, чтобы переместить его между группами.\nВы также можете перетащить нескольких выбранных игроков одновременно.\nПустые слоты можно использовать для обмена позициями."
	L.RAID_HELP_COMBAT_TITLE = "Блокировка в бою"
	L.RAID_HELP_COMBAT_TEXT =
		"Игроков нельзя перемещать во время боя.\nЭто ограничение Blizzard для предотвращения ошибок."
	L.RAID_INFO_UNAVAILABLE = "Информация недоступна"
	L.RAID_NOT_IN_RAID = "Не в рейде"
	L.RAID_NOT_IN_RAID_DETAILS =
		"Вы в данный момент не состоите в рейдовой группе"
	L.RAID_CREATE_BUTTON = "Создать рейд"
	L.GROUP = "Группа"
	L.ALL = "Все"
	L.UNKNOWN_ERROR = "Неизвестная ошибка"
	L.RAID_ERROR_NOT_ENOUGH_SPACE =
		"Недостаточно места: выбрано %d игроков, %d свободных мест в Группе %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Перемещено %d игроков в Группу %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Не удалось переместить %d игроков"
	L.RAID_ERROR_READY_CHECK_PERMISSION =
		"Вы должны быть лидером рейда или помощником, чтобы начать проверку готовности"
	L.RAID_ERROR_NO_SAVED_INSTANCES = "У вас нет сохраненных рейдовых подземелий"
	L.RAID_ERROR_LOAD_RAID_INFO =
		"Ошибка: Не удалось загрузить окно информации о рейде"
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s поменялись местами"
	L.RAID_ERROR_SWAP_FAILED = "Обмен не удался: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s перемещен в Группу %d"
	L.RAID_ERROR_MOVE_FAILED = "Перемещение не удалось: %s"
	L.DIALOG_MIGRATE_TEXT =
		"Перенести группы друзей из FriendGroups в BetterFriendlist?\n\nЭто сделает:\n Создание всех групп из заметок BNet\n Назначение друзей в их группы\n Опционально открыть Мастер Очистки для проверки и очистки заметок\n\n|cffff0000Внимание: Это действие нельзя отменить!|r"
	L.DIALOG_MIGRATE_BTN1 = "Перенести и проверить заметки"
	L.DIALOG_MIGRATE_BTN2 = "Только перенести"
	L.DIALOG_MIGRATE_BTN3 = "Отмена"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_FONTS = "Шрифты"
	L.SETTINGS_TAB_GENERAL = "Основные"
	L.SETTINGS_TAB_GROUPS = "Группы"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Настройка заголовков"
	L.SETTINGS_GROUP_FONT_HEADER = "Шрифт заголовка группы"
	L.SETTINGS_GROUP_COLOR_HEADER = "Цвет заголовка группы"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Наследовать цвет группы"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Наследовать цвет группы"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "ПКМ, чтобы унаследовать от группы"
	L.SETTINGS_INHERIT_TOOLTIP = "(Унаследовано от группы)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Порядок групп"
	L.SETTINGS_GROUP_COUNT_COLOR = "Цвет счётчика"
	L.SETTINGS_GROUP_ARROW_COLOR = "Цвет стрелки"
	L.SETTINGS_TAB_APPEARANCE = "Внешний вид"
	L.SETTINGS_TAB_ADVANCED = "Расширенные"
	L.SETTINGS_ADVANCED_DESC = "Расширенные опции и инструменты"
	L.SETTINGS_TAB_STATISTICS = "Статистика"
	L.SETTINGS_SHOW_BLIZZARD = "Показать опцию списка друзей Blizzard"
	L.SETTINGS_COMPACT_MODE = "Компактный режим"
	L.SETTINGS_LOCK_WINDOW = "Закрепить окно"
	L.SETTINGS_LOCK_WINDOW_DESC =
		"Блокирует окно для предотвращения случайного перемещения"
	L.SETTINGS_FONT_SIZE = "Размер шрифта"
	L.SETTINGS_FONT_COLOR = "Цвет шрифта"
	L.SETTINGS_FONT_SIZE_SMALL = "Маленький (Компактный, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Обычный (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Большой (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Окрасить имена классов"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Скрыть пустые группы"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Счётчики в заголовке группы"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC =
		"Выберите, как отображать количество друзей в заголовках групп"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Отфильтровано / Всего (По умолчанию)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "В сети / Всего"
	L.SETTINGS_HEADER_COUNT_BOTH = "Отфильтровано / В сети / Всего"
	L.SETTINGS_SHOW_FACTION_ICONS = "Показать иконки фракций"
	L.SETTINGS_SHOW_REALM_NAME = "Показать название сервера"
	L.SETTINGS_GRAY_OTHER_FACTION = "Затемнить другую фракцию"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Показать мобильных как AFK"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Показыть текст мобильных"
	L.SETTINGS_HIDE_MAX_LEVEL = "Скрыть максимальный уровень"
	L.SETTINGS_ACCORDION_GROUPS = "Открывать одну группу за раз"
	L.SETTINGS_SHOW_FAVORITES = "Показать группу Избранных"
	L.SETTINGS_SHOW_GROUP_FMT = "Показать группу %s"
	L.SETTINGS_SHOW_GROUP_DESC_FMT =
		"Переключить видимость группы %s в списке друзей"
	L.SETTINGS_GROUP_COLOR = "Цвет группы"
	L.SETTINGS_RENAME_GROUP = "Переименовать группу"
	L.SETTINGS_DELETE_GROUP = "Удалить группу"
	L.SETTINGS_DELETE_GROUP_DESC = "Удалить эту группу и исключить всех друзей"
	L.SETTINGS_EXPORT_TITLE = "Экспорт настроек"
	L.SETTINGS_EXPORT_INFO =
		"Скопируйте текст ниже и сохраните его. Вы можете импортировать его на другом персонаже или аккаунте."
	L.SETTINGS_EXPORT_BTN = "Выбрать всё"
	L.BUTTON_EXPORT = "Экспорт"
	L.SETTINGS_IMPORT_TITLE = "Импорт настроек"
	L.SETTINGS_IMPORT_INFO =
		"Вставьте вашу строку экспорта ниже и нажмите Импорт.\n\n|cffff0000Внимание: Это заменит ВСЕ ваши группы и назначения!|r"
	L.SETTINGS_IMPORT_BTN = "Импорт"
	L.SETTINGS_IMPORT_CANCEL = "Отмена"
	L.SETTINGS_RESET_DEFAULT = "Сбросить по умолчанию"
	L.SETTINGS_RESET_SUCCESS = "Настройки сброшены к значениям по умолчанию!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Порядок групп сохранён!"
	L.SETTINGS_MIGRATION_COMPLETE = "Миграция завершена!"
	L.SETTINGS_MIGRATION_FRIENDS = "Обработано друзей:"
	L.SETTINGS_MIGRATION_GROUPS = "Создано групп:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Создано назначений:"
	L.SETTINGS_NOTES_CLEANED = "Заметки очищены!"
	L.SETTINGS_NOTES_PRESERVED =
		"Заметки сохранены (вы можете очистить их вручную)"
	L.SETTINGS_EXPORT_SUCCESS =
		"Экспорт успешно завершён! Скопируйте текст из диалога"
	L.SETTINGS_IMPORT_SUCCESS =
		"Импорт успешно завершён! Все группы и назначения восстановлены"
	L.SETTINGS_IMPORT_FAILED = "Импорт не удался!\n\n"
	L.STATS_TOTAL_FRIENDS = "Всего друзей: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00В сети: %d|r  |  |cff808080Не в сети: %d|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Запросы в друзья (%d)"
	L.INVITE_BUTTON_ACCEPT = "Принять"
	L.INVITE_BUTTON_DECLINE = "Отклонить"
	L.INVITE_TAP_TEXT = "Нажмите, чтобы принять или отклонить"
	L.INVITE_MENU_DECLINE = "Отклонить"
	L.INVITE_MENU_REPORT = "Пожаловаться на игрока"
	L.INVITE_MENU_BLOCK = "Блокировать приглашения"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Все друзья"
	L.FILTER_ONLINE_ONLY = "Только в сети"
	L.FILTER_OFFLINE_ONLY = "Только не в сети"
	L.FILTER_WOW_ONLY = "Только WoW"
	L.FILTER_BNET_ONLY = "Только Battle.net"
	L.FILTER_HIDE_AFK = "Скрыть AFK/DND"
	L.FILTER_RETAIL_ONLY = "Только основная версия"
	L.FILTER_TOOLTIP = "Быстрый Фильтр: %s"
	L.SORT_STATUS = "Статус"
	L.SORT_NAME = "Имя (А-Я)"
	L.SORT_LEVEL = "Уровень"
	L.SORT_ZONE = "Зона"
	L.SORT_GAME = "Игра"
	L.SORT_FACTION = "Фракция"
	L.SORT_GUILD = "Гильдия"
	L.SORT_CLASS = "Класс"
	L.SORT_REALM = "Сервер"
	L.SORT_CHANGED = "Сортировка изменена на: %s"
	L.SORT_NONE = "Отсутствует"
	L.SORT_PRIMARY_LABEL = "Первичная сортировка"
	L.SORT_SECONDARY_LABEL = "Вторичная сортировка"
	L.SORT_PRIMARY_DESC = "Выберите, как будет отсортирован список друзей"
	L.SORT_SECONDARY_DESC =
		"Сортировать по этому, когда основные значения равны"
	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Группы"
	L.MENU_CREATE_GROUP = "Создать группу"
	L.MENU_REMOVE_ALL_GROUPS = "Удалить из всех групп"
	L.MENU_REMOVE_RECENTLY_ADDED = "Убрать из Недавно добавленных"
	L.MENU_CLEAR_ALL_RECENTLY_ADDED = "Очистить всех недавно добавленных"
	L.MENU_ADD_ALL_TO_GROUP = "Добавить всех в группу"
	L.MENU_RENAME_GROUP = "Переименовать группу"
	L.MENU_DELETE_GROUP = "Удалить группу"
	L.MENU_INVITE_GROUP = "Пригласить всех в группу"
	L.MENU_COLLAPSE_ALL = "Свернуть все группы"
	L.MENU_EXPAND_ALL = "Развернуть все группы"
	L.MENU_SETTINGS = "Настройки"
	L.MENU_SET_BROADCAST = "Установить объявление"
	L.MENU_IGNORE_LIST = "Управление списком игнорирования"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "Больше групп..."
	L.MENU_SWITCH_GAME_ACCOUNT = "Сменить игровой аккаунт"
	L.MENU_DEFAULT_FOCUS = "По умолчанию (Blizzard)"
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
	L.TOOLTIP_RENAME_GROUP = "Переименовать группу"
	L.TOOLTIP_RENAME_DESC = "Нажмите, чтобы переименовать эту группу"
	L.TOOLTIP_GROUP_COLOR = "Цвет Группы"
	L.TOOLTIP_GROUP_COLOR_DESC = "Нажмите, чтобы изменить цвет этой группы"
	L.TOOLTIP_DELETE_GROUP = "Удалить группу"
	L.TOOLTIP_DELETE_DESC = "Удалить эту группу и исключить всех друзей"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "Друзей приглашено в группу: %d"
	L.MSG_NO_FRIENDS_AVAILABLE = "Нет друзей в сети для приглашения"
	L.MSG_GROUP_DELETED = "Группа '%s' удалена"
	L.MSG_IGNORE_LIST_EMPTY = "Ваш список игнорирования пуст"
	L.MSG_IGNORE_LIST_COUNT = "Список Игнорирования (%d игроков):"
	L.MSG_MIGRATION_ALREADY_DONE =
		"Миграция уже завершена. Используйте '/bfl migrate force' для повторного запуска."
	L.MSG_MIGRATION_STARTING = "Начало миграции из FriendGroups..."
	L.MSG_GROUP_ORDER_SAVED = "Порядок групп сохранён!"
	L.MSG_SETTINGS_RESET = "Настройки сброшены к значениям по умолчанию!"
	L.MSG_EXPORT_FAILED = "Экспорт не удался: %s"
	L.MSG_IMPORT_SUCCESS =
		"Импорт успешно завершён! Все группы и назначения восстановлены"
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
	L.GROUP_INGAME = "В игре"
	L.GROUP_NO_GROUP = "Без группы"
	L.GROUP_RECENTLY_ADDED = "Недавно добавленные"
	L.ONLINE_STATUS = "В сети"
	L.OFFLINE_STATUS = "Не в сети"
	L.STATUS_MOBILE = "Мобильный"
	L.STATUS_IN_APP = "В приложении"
	L.UNKNOWN_GAME = "Неизвестная игра"
	L.BUTTON_ADD_FRIEND = "Добавить друга"
	L.BUTTON_SEND_MESSAGE = "Отправить сообщение"
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
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Включить удаление"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC =
		"Разрешить процессу синхронизации удалять друзей из вашего списка, если они были удалены из базы данных"
	L.SETTINGS_GLOBAL_SYNC_HEADER = "База данных синхронизированных друзей"

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
		"Установите предпочтительный размер по умолчанию для новых раскладок режима редактирования"
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
	L.BROKER_SETTINGS_SHOW_TEXT = "Показать текст"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Показать общее количество"
	L.BROKER_SETTINGS_SHOW_ONLINE = "Показать кол-во онлайн"
	L.BROKER_SETTINGS_SHOW_BNET = "Показать кол-во Battle.net"
	L.BROKER_SETTINGS_SHOW_WOW = "Показать кол-во WoW"
	L.BROKER_SETTINGS_TEXT_FORMAT = "Формат текста"
	L.BROKER_SETTINGS_TEXT_FORMAT_DESC =
		"Выбрать способ отображения текста в брокере"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Уровень детализации в тултипе"
	L.BROKER_SETTINGS_CLICK_ACTION = "Действие левой кнопки"
	L.BROKER_FILTER_CHANGED = "Фильтр изменён на: %s"
	L.BROKER_FORMAT_FULL = "Полный (В сети: 5 | BNet: 3 | WoW: 2)"
	L.BROKER_FORMAT_COMPACT = "Компактный (5 в сети)"
	L.BROKER_FORMAT_MINIMAL = "Минимальный (5)"
	L.BROKER_FORMAT_ICON = "Только иконки"
	L.BROKER_TOOLTIP_MODE_NONE = "Ничего"
	L.BROKER_TOOLTIP_MODE_SIMPLE = "Простой (Только кол-во)"
	L.BROKER_TOOLTIP_MODE_FULL = "Полный (Список друзей)"
	L.BROKER_ACTION_TOGGLE = "Переключить окно"
	L.BROKER_ACTION_SETTINGS = "Открыть настройки"
	L.BROKER_COLUMN_NAME = "Персонаж"
	L.BROKER_COLUMN_STATUS = "Статус"
	L.BROKER_COLUMN_ZONE = "Зона"
	L.BROKER_COLUMN_REALM = "Сервер"
	L.BROKER_COLUMN_NOTES = "Заметки"
	L.BROKER_COLUMN_NAME_DESC = "Показывать имена друзей"
	L.BROKER_COLUMN_STATUS_DESC = "Показывать онлайн статус/игру"
	L.BROKER_COLUMN_ZONE_DESC = "Показывать текущую зону"
	L.BROKER_COLUMN_REALM_DESC = "Показывать название игрового мира"
	L.BROKER_COLUMN_NOTES_DESC = "Показывать заметки о друге"

	-- Broker
	L.BROKER_SETTINGS_LEFT_CLICK = "Действие левой кнопки"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Действие правой кнопки"
	L.BROKER_ACTION_OPEN_BNET = "Открыть приложение BNet"
	L.BROKER_ACTION_NONE = "Ничего"
	L.BROKER_SETTINGS_INFO =
		"BetterFriendlist интегрируется с брокерами данных, такими как Bazooka, ChocolateBar and Titan Panel"
	L.BROKER_HEADER_WOW = "Друзья WoW"
	L.BROKER_HEADER_BNET = "Друзья Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Нет друзей WoW в сети"
	L.BROKER_NO_FRIENDS_ONLINE = "Нет друзей в сети"
	L.BROKER_TOTAL_ONLINE = "Всего: %d в сети / %d друзей"
	L.BROKER_FILTER_LABEL = "Фильтр: "
	L.BROKER_SORT_LABEL = "Сортировка: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Действия с другом ---"
	L.BROKER_HINT_CLICK_WHISPER = "Щелкнуть друга:"
	L.BROKER_HINT_WHISPER = " Шёпот  "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Правая кнопка:"
	L.BROKER_HINT_CONTEXT_MENU = " Контекстное меню"
	L.BROKER_HINT_ALT_CLICK = "Alt+Клик:"
	L.BROKER_HINT_INVITE = " Пригласить/Присоединиться  "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Клик:"
	L.BROKER_HINT_COPY = " Копировать в чат"
	L.BROKER_HINT_ICON_ACTIONS = "--- Действия иконки брокера данных ---"
	L.BROKER_HINT_LEFT_CLICK = "Левая кнопка:"
	L.BROKER_HINT_TOGGLE = " Переключить BetterFriendlist"
	L.BROKER_HINT_RIGHT_CLICK = "Правая кнопка:"
	L.BROKER_HINT_SETTINGS = " Настройки  "
	L.BROKER_HINT_MIDDLE_CLICK = "Средняя кнопка:"
	L.BROKER_HINT_CYCLE_FILTER = " Переключить фильтр"
	L.BROKER_SETTINGS_SHOW_LABEL = "Показать метку"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Разделить счётчики друзей WoW и BNet"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Основные настройки"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Интеграция брокера данных"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Взаимодействие"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Как использовать"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Протестированные аддоны отображения"
	L.BROKER_SETTINGS_INSTRUCTIONS =
		" Установить аддон брокера данных\n Включить указанный аддон брокера данных"
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
	L.BROKER_COLUMN_FACTION_DESC = "Показывать иконку фракции"
	L.BROKER_ACTION_FRIENDS = "Друзья"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Показывать Мобильных как Оффлайн
	L.SETTINGS_TREAT_MOBILE_OFFLINE =
		"Показать мобильных пользователей как оффлайн"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC =
		"Показывать друзей с мобильного приложения в группе оффлайн"

	-- Feature 3: Показывать Заметки как Имя
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Показать заметки как имя друга"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC =
		"Показать заметки друзей как их имя, если указаны"

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
	L.SLASH_CMD_HELP = "BetterFriendlist: Используйте '/bfl migrate help' для помощи"
	L.LOADED_MESSAGE = "BetterFriendlist загружен"
	L.DEBUG_ENABLED = "Отладка ВКЛЮЧЕНА"
	L.DEBUG_DISABLED = "Отладка ВЫКЛЮЧЕНА"
	L.CONFIG_RESET = "Конфигурация сброшена"
	L.SEARCH_PLACEHOLDER = "Поиск друзей..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Гильдия"
	L.TAB_RAID = "Рейд"
	L.TAB_QUICK_JOIN = "Быстро присоединиться"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "В сети"
	L.FILTER_SEARCH_OFFLINE = "Не в сети"
	L.FILTER_SEARCH_MOBILE = "Мобильный"
	L.FILTER_SEARCH_AFK = "АФК"
	L.FILTER_SEARCH_DND = "Не беспокоить"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "DND"

	-- Groups
	L.MIGRATION_CHECK = "Верификация миграции..."
	L.MIGRATION_RESULT = "Мигрировано %d групп и %d привязок."
	L.MIGRATION_BNET_UPDATED = "Обновлены привязки BNet."
	L.MIGRATION_BNET_REASSIGN = "Перепривязан BNet."
	L.MIGRATION_BNET_REASON = "(Причина: Временный BNet ID)."
	L.MIGRATION_WOW_RESULT = "Мигрировано %d привязок WoW."
	L.MIGRATION_WOW_FORMAT = "(Формат: Персонаж-Сервер)"
	L.MIGRATION_WOW_FAIL = "Миграция не удалась (сервер отсутствует)."
	L.MIGRATION_SMART_MIGRATING = "Миграция: %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Мульти выбор очищен - режим боя"

	-- Quick Join
	L.LEADER_LABEL = "Лидер:"
	L.MEMBERS_LABEL = "Участники:"
	L.AVAILABLE_ROLES = "Доступные роли"
	L.NO_AVAILABLE_ROLES = "Нет ролей"
	L.AUTO_ACCEPT_TOOLTIP = "Авто-принятие"
	L.MOCK_JOIN_REQUEST_SENT = "Имитация запроса отправлена"
	L.QUICK_JOIN_NO_GROUPS = "Нет групп"
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
	L.DIALOG_DELETE_GROUP_TITLE = "Удалить Группу"
	L.DIALOG_RENAME_GROUP_TITLE = "Переименовать Группу"
	L.DIALOG_CREATE_GROUP_TITLE = "Создать Группу"

	-- Tooltips
	L.TOOLTIP_LAST_ONLINE = "Последний раз в сети: %s"

	-- Notifications
	L.YES = "ДА"
	L.NO = "НЕТ"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Предпросмотр %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Предпросмотр Позиции"
	L.EDITMODE_FRAME_WIDTH = "Ширина"
	L.EDITMODE_FRAME_HEIGHT = "Высота"

	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT =
		"Сбросить расположение?\n\nЭто действие нельзя отменить!"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Сбросить"
	L.MSG_LAYOUTS_RESET = "Расположение сброшено"
	L.DIALOG_TRIGGER_TITLE = "Создать триггер"
	L.DIALOG_TRIGGER_SELECT_GROUP = "Группа:"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Минимум друзей:"
	L.DIALOG_TRIGGER_CREATE = "Создать"
	L.DIALOG_TRIGGER_CANCEL = "Отмена"
	L.ERROR_SELECT_GROUP = "Выбор группы"
	L.MSG_TRIGGER_CREATED = "Триггер создан: %d+ '%s'"
	L.ERROR_NO_GROUPS = "Нет групп."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Добавить псевдоним %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "Все"
	L.FILTER_ONLINE = "В сети"
	L.FILTER_OFFLINE = "Не в сети"
	L.FILTER_WOW = "WoW"
	L.FILTER_BNET = "BNet"
	L.FILTER_HIDE_AFK = "Не AFK"
	L.FILTER_RETAIL = "Основная версия"
	L.TOOLTIP_QUICK_FILTER = "Фильтр: %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT =
		"Требуется перезагрузка интерфейса.\n\nПерезагрузить?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Перезагрузка"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Отмена"
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Включить брокер данных"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Показать Иконку"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "Иконка BFL"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Показать пометку"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Пометка 'Друзья'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Показать всего"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Кол-во всего"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Кол-во разделено"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Разделить WoW/BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "Иконка WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Показать иконку WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "Иконка друзей WoW"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "Иконка BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Показать иконку BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "Иконка друзей BNet"
	L.STATUS_ENABLED = "|cff00ff00Включено|r"
	L.STATUS_DISABLED = "|cffff0000Отключено|r"
	L.BROKER_WOW_FRIENDS = "Друзей WoW:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Глобальная сихронизация"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Включить глобальную синхронизацию"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Показать удалённых"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Показать удалённых друзей"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Показать удалённых в списке"
	L.TOOLTIP_RESTORE_FRIEND = "Восстановить"
	L.TOOLTIP_DELETE_FRIEND = "Удалить"
	L.POPUP_EDIT_NOTE_TITLE = "Редактировать заметку"
	L.BUTTON_SAVE = "Сохранить"
	L.BUTTON_CANCEL = "Отмена"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Друзья: "
	L.BROKER_ONLINE_TOTAL = "%d в сети / %d всего"
	L.BROKER_CURRENT_FILTER = "Фильтр:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Средняя кнопка: переключить фильтр"
	L.BROKER_AND_MORE = "  ... и остальных: %d"
	L.BROKER_TOTAL_LABEL = "Всего:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d в сети / %d друзей"
	L.MENU_CHANGE_COLOR = "Изменить цвет"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Ошибка тултипа|r"
	L.STATUS_LABEL = "Статус:"
	L.STATUS_AWAY = "Отошел"
	L.STATUS_DND_FULL = "Не Беспокоить"
	L.GAME_LABEL = "Игра:"
	L.REALM_LABEL = "Сервер:"
	L.CLASS_LABEL = "Класс:"
	L.FACTION_LABEL = "Фракция:"
	L.ZONE_LABEL = "Зона:"
	L.NOTE_LABEL = "Заметка:"
	L.BROADCAST_LABEL = "Сбщ:"
	L.ACTIVE_SINCE_FMT = "Активен с: %s"
	L.HINT_RIGHT_CLICK_OPTIONS = "Опции по клику правой кнопки"
	L.HEADER_ADD_FRIEND = "|cffffd700Добавить %s в %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Отладка Миграции - Всего:"
	L.MIGRATION_DEBUG_BNET = "Отладка Миграции - BNet старый:"
	L.MIGRATION_DEBUG_WOW = "Отладка Миграции - WoW без игрового мира:"
	L.ERROR_INVALID_PARAMS = "Недопустимые параметры"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Достать из игнора"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE =
		"Информация о недавних союзниках недоступна"
	L.RECENT_ALLIES_INVITE = "Пригласить"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Игрок не в сети"
	L.RECENT_ALLIES_PIN_EXPIRES = "Закрепление истекает через %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Лвл %d %s"
	L.RECENT_ALLIES_NOTE = "Заметка: %s"
	L.RECENT_ALLIES_ACTIVITY = "Недавняя активность:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Пригласи друга"
	L.RAF_RECRUITMENT = "Набор друзей"
	L.RAF_NO_RECRUITS_DESC = "Рекрутов нет."
	L.RAF_PENDING_RECRUIT = "В ожидании"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Получено:"
	L.RAF_NEXT_REWARD_AFTER = "Следующий через %d/%d месяцев"
	L.RAF_FIRST_REWARD = "Первый:"
	L.RAF_NEXT_REWARD = "Последний:"
	L.RAF_REWARD_MOUNT = "Маунт"
	L.RAF_REWARD_TITLE_DEFAULT = "Титул"
	L.RAF_REWARD_TITLE_FMT = "Титул: %s"
	L.RAF_REWARD_GAMETIME = "Игровое вреия"
	L.RAF_MONTH_COUNT = "%d месяцев"
	L.RAF_CLAIM_REWARD = "Получить"
	L.RAF_VIEW_ALL_REWARDS = "Посмотреть все"
	L.RAF_ACTIVE_RECRUIT = "Активен"
	L.RAF_TRIAL_RECRUIT = "Пробная версия"
	L.RAF_INACTIVE_RECRUIT = "Неактивен"
	L.RAF_OFFLINE = "Не в сети"
	L.RAF_TOOLTIP_DESC = "До %d месяцев"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d месяцев"
	L.RAF_ACTIVITY_DESCRIPTION = "Активен %s"
	L.RAF_REWARDS_LABEL = "Награды"
	L.RAF_YOU_EARNED_LABEL = "Получено:"
	L.RAF_CLICK_TO_CLAIM = "Кликнуть, чтобы забрать"
	L.RAF_LOADING = "Загрузка..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== Программа Пригласи Друга ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "Текущая программа"
	L.RAF_CHAT_LEGACY_VERSION = "Старая программа v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Месяцев: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Новобранцев: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Доступно наград:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Получено]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Можно получить]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Доступно]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Заблокировано]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d месяцев)"
	L.RAF_CHAT_MORE_REWARDS = "    ... и %d других"
	L.RAF_CHAT_USE_UI = "|cff00ff00Используйте UI для информации.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00RAF:|r Игровое время доступно."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_TAB_DATABROKER = "Брокер данных"
	L.MSG_GROUP_RENAMED = "Переименовано групп '%s'"
	L.ERROR_RENAME_FAILED = "Не удалось переименовать"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Порядок Групп: %s"
	L.ERROR_EXPORT_SERIALIZE = "Ошибка Сериализации"
	L.ERROR_IMPORT_EMPTY = "Очистить строку"
	L.ERROR_IMPORT_DECODE = "Расшифровка ошибки"
	L.ERROR_IMPORT_DESERIALIZE = "Ошибка десериализации"
	L.ERROR_EXPORT_VERSION = "Версия не поддерживается"
	L.ERROR_EXPORT_STRUCTURE = "Недопустимая структура"

	-- Statistics
	L.STATS_NO_HEALTH_DATA = "Нет данных о здоровье"
	L.STATS_NO_CLASS_DATA = "Нет данных о классе"
	L.STATS_NO_LEVEL_DATA = "Нет данных об уровне"
	L.STATS_NO_REALM_DATA = "Нет данных о сервере"
	L.STATS_NO_GAME_DATA = "Нет данных об игре"
	L.STATS_NO_MOBILE_DATA = "Нет данных о мобильной версии"
	L.STATS_SAME_REALM = "Тот же сервер: %d (%d%%)  |  Другие: %d (%d%%)"
	L.STATS_TOP_REALMS = "\nТоп серверов:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\nДругие: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Заметки: %d (%d%%)\nИзбранное: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Макс: %d\n70-79: %d\n60-69: %d\n<60: %d\nСреднее: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Активно: %d (%d%%)|r\n|cffffd700Средн: %d (%d%%)|r\n|cffffaa00Старые: %d (%d%%)|r\n|cffff6600Не актуально: %d (%d%%)|r\n|cffff0000Неактивные: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffАльянс: %d|r\n|cffff0000Орда: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "Переместить ниже"
	L.TOOLTIP_MOVE_DOWN_DESC = "Переместить группу ниже"
	L.TOOLTIP_MOVE_UP = "Переместить выше"
	L.TOOLTIP_MOVE_UP_DESC = "Переместить группу выше"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "Друг не в WoW"
	L.TRAVEL_PASS_WOW_CLASSIC = "Друг в WoW Classic"
	L.TRAVEL_PASS_WOW_MAINLINE = "Друг в WoW"
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Другая версия"
	L.TRAVEL_PASS_NO_INFO = "Информация недоступна"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Другой регион"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "Нет игрового аккаунта"
	L.TRAVEL_PASS_DIFFERENT_FACTION = "Противоположная фракция"
	L.TRAVEL_PASS_QUEST_SESSION = "Нельзя пригласить во время квестовой сессии"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Показать список Blizzard"
	L.MENU_COMBAT_LOCKED = "Заблокировано в режиме боя"
	L.MENU_SET_NICKNAME = "Установить псевдоним"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Настройки BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Поиск..."
	L.SEARCH_RECENT_ALLIES_INSTRUCTION = "Поиск недавних союзников..."
	L.SEARCH_RAF_INSTRUCTION = "Поиск приглашённых..."
	L.RAF_NEXT_REWARD_HELP = "Информация о программе Пригласи Друга"
	L.WHO_LEVEL_FORMAT = "Уровень %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Недавние союзники"
	L.CONTACTS_MENU_NAME = "Меню контактов"
	L.BATTLENET_UNAVAILABLE = "BNet Недоступен"
	L.BATTLENET_BROADCAST = "Объявление"
	L.FRIENDS_LIST_ENTER_TEXT = "Сбщ..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Поиск..."
	L.RAF_SPLASH_SCREEN_TITLE = "Пригласи Друга"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "Пригласи Друга!"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Инфо о наградах"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Формат имени"
	L.SETTINGS_NAME_FORMAT_DESC =
		"Используйте токены для настройки отображения:\n|cffFFD100%name%|r - Имя аккаунта\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Псевдоним\n|cffFFD100%note%|r - Заметка\n|cffFFD100%character%|r - Имя персонажа\n|cffFFD100%realm%|r - Название сервера\n|cffFFD100%level%|r - Уровень\n|cffFFD100%zone%|r - Зона\n|cffFFD100%class%|r - Класс\n|cffFFD100%game%|r - Игра"
	L.SETTINGS_NAME_FORMAT_LABEL = "Шаблон:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Формат имени"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Указать формат"
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"Эта настройка отключена, потому что аддон 'FriendListColors' управляет цветом/форматом имён"
	-- Name Format Preset Labels (Phase 22)
	L.NAME_PRESET_DEFAULT = "Имя (Персонаж)"
	L.NAME_PRESET_BATTLETAG = "BattleTag (Персонаж)"
	L.NAME_PRESET_NICKNAME = "Псевдоним (Персонаж)"
	L.NAME_PRESET_NAME_ONLY = "Только имя"
	L.NAME_PRESET_CHARACTER = "Только персонаж"
	L.NAME_PRESET_CUSTOM = "Свой формат..."
	L.SETTINGS_NAME_FORMAT_CUSTOM_LABEL = "Свой формат:"

	-- Info Format Section (Phase 22)
	L.SETTINGS_INFO_FORMAT_HEADER = "Формат информации о друзьях"
	L.SETTINGS_INFO_FORMAT_LABEL = "Шаблон:"
	L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL = "Свой формат:"
	L.SETTINGS_INFO_FORMAT_TOOLTIP = "Пользовательский формат информации"
	L.SETTINGS_INFO_FORMAT_DESC =
		"Используйте токены для настройки информационной строки:\n|cffFFD100%level%|r - Уровень персонажа\n|cffFFD100%zone%|r - Текущая зона\n|cffFFD100%class%|r - Название класса\n|cffFFD100%game%|r - Название игры\n|cffFFD100%realm%|r - Название сервера\n|cffFFD100%status%|r - AFK/DND/Онлайн\n|cffFFD100%lastonline%|r - Был в сети\n|cffFFD100%name%|r - Имя аккаунта\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Псевдоним\n|cffFFD100%note%|r - Заметка\n|cffFFD100%character%|r - Имя персонажа"
	L.INFO_PRESET_DEFAULT = "По умолчанию (Уровень, Зона)"
	L.INFO_PRESET_ZONE = "Только зона"
	L.INFO_PRESET_LEVEL = "Только уровень"
	L.INFO_PRESET_CLASS_ZONE = "Класс, Зона"
	L.INFO_PRESET_LEVEL_CLASS_ZONE = "Уровень Класс, Зона"
	L.INFO_PRESET_GAME = "Название игры"
	L.INFO_PRESET_DISABLED = "Отключено (Скрыть Информацию)"
	L.INFO_PRESET_CUSTOM = "Свой..."
	L.SETTINGS_SHOW_INGAME_GROUP = "Группа 'В игре'"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Группа друзей в игре"
	L.SETTINGS_INGAME_MODE_WOW = "Только WoW"
	L.SETTINGS_INGAME_MODE_ANY = "Любая игра"
	L.SETTINGS_INGAME_MODE_LABEL = "   Режим:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Режим"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Выбрать друзей"
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT = "   Единица времени:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_DESC =
		"Выберите единицу времени, определяющую как долго друзья остаются в группе Недавно добавленные."
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE = "   Значение длительности:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_DESC =
		"Сколько дней/часов/минут друзья остаются в группе Недавно добавленные перед удалением."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_TOOLTIP = "Единица времени"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_TOOLTIP = "Значение длительности"
	L.SETTINGS_DURATION_DAYS = "Дни"
	L.SETTINGS_DURATION_HOURS = "Часы"
	L.SETTINGS_DURATION_MINUTES = "Минуты"

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Параметры отображения"
	L.SETTINGS_BEHAVIOR_HEADER = "Поведение"
	L.SETTINGS_GROUP_MANAGEMENT = "Управление группами"
	L.SETTINGS_FONT_SETTINGS = "Шрифт"
	L.SETTINGS_GROUP_ORDER = "Порядок групп"
	L.SETTINGS_MIGRATION_HEADER = "Миграция FriendGroups"
	L.SETTINGS_MIGRATION_DESC = "Мигрировать из аддона FriendGroups"
	L.SETTINGS_MIGRATE_BTN = "Миграция"
	L.SETTINGS_MIGRATE_TOOLTIP = "Импорт"
	L.SETTINGS_EXPORT_HEADER = "Экспорт / Импорт"
	L.SETTINGS_EXPORT_DESC = "Экспортировать настроек в строку"
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Внимание: Данные перезапишутся!|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Экспорт"
	L.SETTINGS_IMPORT_TOOLTIP = "Импорт"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Синхронизация между персонажами"

	-- Statistics
	L.STATS_HEADER = "Статистика"
	L.STATS_DESC = "Сводка"
	L.STATS_OVERVIEW_HEADER = "Сводка"
	L.STATS_HEALTH_HEADER = "Здоровье"
	L.STATS_CLASSES_HEADER = "Топ 5 Классов"
	L.STATS_REALMS_HEADER = "Сервера"
	L.STATS_ORGANIZATION_HEADER = "Орг"
	L.STATS_LEVELS_HEADER = "Уровни"
	L.STATS_GAMES_HEADER = "Игры"
	L.STATS_MOBILE_HEADER = "Mobile vs PC"
	L.STATS_FACTIONS_HEADER = "Фракции"
	L.STATS_REFRESH_BTN = "Обновить"
	L.STATS_REFRESH_TOOLTIP = "Обновить статистику"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters

	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Скрывать пустые"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Показывать иконки фракций"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Показывать сервер"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Затемнять остальные"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Показывать мобильных как AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Скрывать максимальный лвл"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Показывать кнопку Blizzard"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Показывать Избранное"
	L.SETTINGS_ACCORDION_GROUPS_DESC =
		"Открытие одной группы сворачивает остальные"
	L.SETTINGS_COMPACT_MODE_DESC = "Уменьшает список"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Включить скин ElvUI"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Требуется ElvUI"
	L.DIALOG_ELVUI_RELOAD_TEXT =
		"Требуется перезагрузка интерфейса.\nПерезагрузить?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Да"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "Нет"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "БД не инициализирована"
	L.CORE_SHOW_BLIZZARD_ENABLED = "Пераметр Blizzard |cff20ff20ON|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Пераметр Blizzard |cffff0000OFF|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Отладка недоступна"
	L.CORE_DB_MODULE_NOT_AVAIL = "Модуль БД недоступен"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Активность ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Активно друзей: %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "Бета отключена!"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Enable:|r ESC > AddOns > BFL"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Статистика не загружена"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Статистика ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Сводка:|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE =
		"  Tot: |cffffffff%d|r  Онл: |cff00ff00%d|r (%.0f%%)  Оффл: |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet: |cff0099ff%d|r  |  WoW: |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Здоровье:|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Активно: |cff00ff00%d|r  Средн: |cffffd700%d|r"
	L.CORE_STATS_HEALTH_STALE = "  Старый: |cffff6600%d|r  Спящий: |cffff0000%d|r"
	L.CORE_STATS_NO_HEALTH_DATA = "  Нет данных"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Классы:|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Уровни:|r"
	L.CORE_STATS_LEVEL_BREAKDOWN =
		"  Макс: |cffffffff%d|r  70+: |cffffffff%d|r  60+: |cffffffff%d|r  <60: |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Средн: |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Сервера:|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Тот же: |cffffffff%d|r  |  Другие: |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Топ:"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Фракции:|r"
	L.CORE_STATS_FACTION_DATA = "  Альянс: |cff0080ff%d|r  |  Орда: |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Игры:|r"
	L.CORE_STATS_GAME_WOW = "  Основная версия: |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic: |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4: |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS: |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC: |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  Приложение: |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Другое: |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Mobile vs PC:|r"
	L.CORE_STATS_MOBILE_DATA = "  PC: |cffffffff%d|r (%.0f%%)  Mobile: |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Org:|r"
	L.CORE_STATS_ORG_DATA = "  Заметки: |cffffffff%d|r  Избр: |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Конфигурация не загружена"
	L.CORE_MOCK_INVITES_ENABLED = "Имитация приглашений |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Добавлено имит. приглашений |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Подсказка:|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Очищено"
	L.CORE_NO_MOCK_INVITES = "Нет приглашений"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Монитор ресурсов не загружен"
	L.CORE_MEMORY_USAGE = "Память: %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "Быстрое приглашение не загружено"
	L.CORE_RAIDFRAME_NOT_LOADED = "РейдФрейм не загружен"
	L.CORE_PREVIEW_MODE_NOT_LOADED = "Предпросмотр не загружен"
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Совместимость ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Версия Клиента:|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Тип:|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00TWW|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffffОсновная версия|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Доступно:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  СкроллБокс: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Режим Меню: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Последние союзники: %s"
	L.CORE_FEATURE_EDIT_MODE = "  Режим редактирования: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Выпадающий список: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  Выбор Цвета: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Совместимость:|r %s"
	L.CORE_COMPAT_ACTIVE = "Режим совместимости Classic активен"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000Не загружено|r"
	L.CORE_CHANGELOG_RESET = "Список изменений сброшен"
	L.CORE_CHANGELOG_NOT_LOADED = "Список изменений не загружен"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Отладка ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard:|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000Нет параметров|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00Атрибуты BFL:|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00В UIPanel:|r |cff00ff00YES|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00В UIPanel:|r |cffff0000NO|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800WARN:|r FriendsFrame в UIPanel!"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Параметр:|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BFL v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Команды:|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Переключить"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/параметры bfl|r - Конфиг"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/помощь bfl|r - Помощь"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/список изменений bfl|r - Open changelog window"
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - Сбросить позицию окна"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Отладка:|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/отладка bfl|r - Включить отладку"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Показать БД"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Показать активность"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Показать статистику"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Проверить правила групп"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join:|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Имитация"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Подземелье"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Рейд"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Стресс"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - События"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Очистить"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - Список"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock:|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Создать рейд"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Пригласить"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Очистить приглашения"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Preview:|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - Вкл"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Выкл"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Fake Data)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame:|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - 25ппл"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - 40ппл"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - 10ппл"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - 20ппл"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - Проверка готовности"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Проверка ролей"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Переместить"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Очистить"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Perf:|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Показать"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Включить"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Сбросить"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Память"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Test:|r"
	L.TESTSUITE_PERFY_HELP =
		"  |cffffffff/bfl test perfy [seconds]|r - Запуск стресс-тест производительности"
	L.TESTSUITE_PERFY_STARTING = "Запуск стресс-теста Perfy на %d секунд"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Стресс-тест Perfy уже запущен"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Аддон Perfy недоступен (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Слэш-команды Perfy недоступны"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy стресс-тест не удался: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy стресс-тест завершён"
	L.TESTSUITE_PERFY_ABORTED = "Perfy стресс-тест остановлен: %s"
	L.CORE_HELP_LINK = "|cff20ff20Help:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Загружено. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Принято %s"
	L.MOCK_INVITE_DECLINED = "Отклонено %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Сброс статистики"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Perf ===|r"
	L.PERF_QJ_OPS = "|cffffd700QJ Ops:|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Friends Ops:|r"
	L.PERF_MEMORY = "|cffffd700Память:|r"
	L.PERF_TARGETS = "|cffffd700Цель:|r"
	L.PERF_AUTO_ENABLED = "Авто-монитор ресурсов |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Создан 25ппл"
	L.RAID_MOCK_CREATED_40 = "Создан 40ппл"
	L.RAID_MOCK_CREATED_10 = "Создан 10ппл"
	L.RAID_MOCK_CREATED_MYTHIC = "Создан 20ппл (Эпохальный)"
	L.RAID_MOCK_STRESS = "Стресс-тест"
	L.RAID_WARN_CPU = "|cffff8800Warn:|r Чрезмерное использование CPU"
	L.RAID_NO_MOCK_DATA = "Нет данных. '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Симулировать проверку готовности..."
	L.RAID_MOCK_CLEARED = "Очищено"
	L.RAID_EVENT_COMMANDS = "|cff00ff00События рейда:|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Управл:|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Конфиг"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - Список"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Стресс"
	L.RAID_HELP_EVENTS = "|cffffcc00Sim:|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Raid Config:|r"
	L.RAID_INFO_HEADER = "|cff00ff00Mock Info:|r"
	L.RAID_NO_MOCK_ACTIVE = "Не имитация"
	L.RAID_DYN_UPDATES = "Обновления: %s"
	L.RAID_UPDATE_INTERVAL = "Интервал: %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Имитация: %s"
	L.RAID_DYN_UPDATES_STATUS = "  Динамич: %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Интервал: %.1f s"
	L.RAID_MEMBERS_STATUS = "  Участники: %d"
	L.RAID_TOTAL_MEMBERS = "  Всего: %d"
	L.RAID_COMPOSITION = "Состав рейда"
	L.RAID_STATUS = "  Стаус: %d не в сети, %d мертвы"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Создан тест групп иконок"
	L.QJ_MOCK_CREATED_STRESS = "Создано 50 симуляций групп"
	L.QJ_SIM_ADDED = "Сим: Добавлено"
	L.QJ_SIM_REMOVED = "Сим: Удалено"
	L.QJ_ERR_NO_GROUPS_REMOVE = "Нечего удалить"
	L.QJ_ERR_NO_GROUPS_UPDATE = "Нечего обновить"
	L.QJ_EVENT_COMMANDS = "|cff00ff00QJ События:|r"
	L.QJ_LIST_HEADER = "|cff00ff00QJ Группы:|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00QJ Конфиг:|r"
	L.QJ_EXT_FOOTER = "|cff888888Тест зелёный.|r"
	L.QJ_SIM_UPDATED_FMT = "Сим: %s обновл"
	L.QJ_ADDED_GROUP_FMT = "Добавлено: %s"
	L.QJ_NO_GROUPS_HINT = "Нет групп"
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Иконки"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config:|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Конфиг"

	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Сброшены уведомления интерфейса гильдии"
	L.CMD_RESET_HEADER = "Сброшено:"
	L.CMD_RESET_HELP_WARNING = "Сброс уведомлений гильдии"

	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "  Баги в GitHub"
	L.CHANGELOG_SUPPORT = "   Поддержка"
	L.CHANGELOG_HEADER_COMMUNITY = "Сообщество:"
	L.CHANGELOG_HEADER_VERSION = "Версия %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "Новая версия!"
	L.CHANGELOG_TOOLTIP_CLICK = "Подробности"
	L.CHANGELOG_POPUP_DISCORD = "Discord"
	L.CHANGELOG_POPUP_GITHUB = "Баги"
	L.CHANGELOG_POPUP_SUPPORT = "Поддержка"
	L.CHANGELOG_TITLE = "Список изменений"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Макс лвл"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Группа %d"

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6мс = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3мс = 30 FPS"
	L.PERF_WARNING = "   >50мс = Предупреждение"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Мобильный"
	L.RAF_RECRUITMENT = "Пригласи друга"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Окрашивать имена друзей в цвет их класса"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Контур шрифта"
	L.SETTINGS_FONT_SHADOW = "Тень шрифта"
	L.SETTINGS_FONT_OUTLINE_NONE = "Нет"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Контур"
	L.SETTINGS_FONT_OUTLINE_THICK = "Толстый контур"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Монохромный"
	L.SETTINGS_GROUP_COUNT_COLOR = "Цвет счётчика"
	L.SETTINGS_GROUP_ARROW_COLOR = "Цвет стрелки"
	L.TOOLTIP_EDIT_NOTE = "Редактировать заметку"
	L.MENU_SHOW_SEARCH = "Показать поиск"
	L.MENU_QUICK_FILTER = "Быстрый фильтр"

	-- Multi-Game-Account
	L.MENU_INVITE_CHARACTER = "Пригласить персонажа..."
	L.INVITE_ACCOUNT_PICKER_TITLE = "Пригласить персонажа"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Включить значок избранного"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC =
		"Показывать значок звезды на кнопке друга для группы избранных"
	L.SETTINGS_FAVORITE_ICON_STYLE = "Значок избранного"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC =
		"Выбрать, какой значок использовать для избранных"
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "Значок BFL"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "Значок Blizzard"
	L.SETTINGS_SHOW_FACTION_BG = "Показать фон фракции"
	L.SETTINGS_SHOW_FACTION_BG_DESC =
		"Показывать цвет фракции в качестве фона для кнопки друга"

	-- Multi-Game-Account Settings
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "Значок мульти-аккаунта"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC =
		"Показывать значок у друзей с несколькими игровыми аккаунтами онлайн."
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "Показывать инфо мульти-аккаунта"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC =
		"Добавляет краткий список онлайн-персонажей, если у друга активно несколько аккаунтов."
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS = "Подсказка: Макс. игровых аккаунтов"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS_DESC =
		"Максимальное количество дополнительных игровых аккаунтов в подсказке."
	L.INFO_MULTI_ACCOUNT_PREFIX = "x%d Accounts"
	L.INFO_MULTI_ACCOUNT_REMAINDER = " (+%d)"

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "Режим Стримера"
	L.STREAMER_MODE_DESC =
		"Варианты конфиденциальности для потоковой трансляции или записи"
	L.SETTINGS_ENABLE_STREAMER_MODE =
		"Показать кнопку режима потоковой трансляции"
	L.STREAMER_MODE_ENABLE_DESC =
		"Показывает кнопку в главном фрейме для переключения режима потоковой трансляции"
	L.STREAMER_MODE_HIDDEN_NAME = "Скрытый формат имени"
	L.STREAMER_MODE_HEADER_TEXT = "Пользовательский текст заголовка"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"Текст для отображения в заголовке Battle.net при активном режиме потоковой трансляции (например, 'Режим Стримера')"
	L.STREAMER_MODE_BUTTON_TOOLTIP = "Переключить режим потоковой трансляции"
	L.STREAMER_MODE_BUTTON_DESC =
		"Нажмите для включения/отключения режима конфиденциальности"
	L.SETTINGS_PRIVACY_OPTIONS = "Варианты конфиденциальности"
	L.SETTINGS_STREAMER_NAME_FORMAT = "Значения имен"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC =
		"Выберите, как отображаются имена в режиме потоковой трансляции"
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "Принудительное использование BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME =
		"Принудительное использование псевдонима"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "Принудительное использование заметки"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "Использовать фиолетовый цвет заголовка"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"Измените фон заголовка Battle.net на фиолетовый Twitch при активном режиме потоковой трансляции"

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "Рейд"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "Включить сочетания клавиш"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"Включить или отключить все пользовательские сочетания клавиш мыши на экране рейда"
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
		"Настройте сочетания клавиш мыши для управления рейдом и группой"
	L.SETTINGS_RAID_MODIFIER_LABEL = "Мод:"
	L.SETTINGS_RAID_BUTTON_LABEL = "Кнп:"
	L.SETTINGS_RAID_WARNING =
		"Примечание: Сочетания клавиш - это защищенные действия (только вне боя)"
	L.SETTINGS_RAID_ERROR_RESERVED = "Это сочетание зарезервировано"

	-- ========================================
	-- WHO FRAME SETTINGS
	-- ========================================
	L.SETTINGS_TAB_WHO = "Кто"
	L.WHO_SETTINGS_DESC =
		"Настройте внешний вид и поведение результатов поиска Кто."
	L.WHO_SETTINGS_VISUAL_HEADER = "Внешний вид"
	L.WHO_SETTINGS_CLASS_ICONS = "Показывать иконки классов"
	L.WHO_SETTINGS_CLASS_ICONS_DESC =
		"Отображать иконки классов рядом с именами игроков."
	L.WHO_SETTINGS_CLASS_COLORS = "Цветные имена по классу"
	L.WHO_SETTINGS_CLASS_COLORS_DESC = "Окрашивать имена игроков в цвет их класса."
	L.WHO_SETTINGS_LEVEL_COLORS = "Цвета сложности уровня"
	L.WHO_SETTINGS_LEVEL_COLORS_DESC =
		"Окрашивать уровни по сложности относительно вашего уровня."
	L.WHO_SETTINGS_ZEBRA = "Чередующиеся фоны строк"
	L.WHO_SETTINGS_ZEBRA_DESC =
		"Показывать чередующиеся фоны строк для удобства чтения."
	L.WHO_SETTINGS_BEHAVIOR_HEADER = "Поведение"
	L.WHO_SETTINGS_DOUBLE_CLICK = "Действие двойного щелчка"
	L.WHO_DOUBLE_CLICK_WHISPER = "Шепот"
	L.WHO_DOUBLE_CLICK_INVITE = "Пригласить в группу"
	L.WHO_RESULTS_SHOWING = "Показано %d из %d игроков"
	L.WHO_NO_RESULTS = "Игроки не найдены"
	L.WHO_TOOLTIP_HINT_CLICK = "Нажмите для выбора"
	L.WHO_TOOLTIP_HINT_DBLCLICK = "Двойной щелчок для шепота"
	L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE = "Двойной щелчок для приглашения"
	L.WHO_TOOLTIP_HINT_CTRL_FORMAT = "Ctrl+клик: поиск %s"
	L.WHO_TOOLTIP_HINT_RIGHTCLICK = "Правый клик для опций"
	L.WHO_SEARCH_PENDING = "Поиск..."
	L.WHO_SEARCH_TIMEOUT = "Нет ответа. Попробуйте снова."

	-- ========================================
	-- WHO SEARCH BUILDER
	-- ========================================
	L.WHO_BUILDER_TITLE = "Конструктор поиска"
	L.WHO_BUILDER_NAME = "Имя"
	L.WHO_BUILDER_GUILD = "Гильдия"
	L.WHO_BUILDER_ZONE = "Зона"
	L.WHO_BUILDER_CLASS = "Класс"
	L.WHO_BUILDER_RACE = "Раса"
	L.WHO_BUILDER_LEVEL = "Уровень"
	L.WHO_BUILDER_LEVEL_TO = "до"
	L.WHO_BUILDER_ALL_CLASSES = "Все классы"
	L.WHO_BUILDER_ALL_RACES = "Все расы"
	L.WHO_BUILDER_PREVIEW = "Предпросмотр:"
	L.WHO_BUILDER_PREVIEW_EMPTY = "Заполните поля для составления запроса"
	L.WHO_BUILDER_SEARCH = "Поиск"
	L.WHO_BUILDER_RESET = "Сброс"
	L.WHO_BUILDER_TOOLTIP = "Открыть конструктор поиска"
	L.WHO_BUILDER_DOCK_TOOLTIP = "Прикрепить конструктор поиска"
	L.WHO_BUILDER_UNDOCK_TOOLTIP = "Открепить конструктор поиска"

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "Размеры окна"
	L.SETTINGS_FRAME_SCALE = "Масштаб:"
	L.SETTINGS_FRAME_WIDTH = "Ширина:"
	L.SETTINGS_FRAME_HEIGHT = "Высота:"
	L.SETTINGS_FRAME_WIDTH_DESC = "Отрегулировать ширину окна"
	L.SETTINGS_FRAME_HEIGHT_DESC = "Отрегулировать высоту окна"
	L.SETTINGS_FRAME_SCALE_DESC = "Отрегулировать масштаб окна"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "Выравнивание заголовка группы"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC =
		"Установить выравнивание текста имени группы"
	L.SETTINGS_ALIGN_LEFT = "Слева"
	L.SETTINGS_ALIGN_CENTER = "По центру"
	L.SETTINGS_ALIGN_RIGHT = "Справа"
	L.SETTINGS_SHOW_GROUP_ARROW = "Показать стрелку сворачивания"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC =
		"Показать или скрыть значок стрелки для сворачивания групп"
	L.SETTINGS_GROUP_ARROW_ALIGN = "Выравнивание стрелки сворачивания"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC =
		"Установить выравнивание значка стрелки сворачивания/разворачивания"
	L.SETTINGS_FONT_FACE = "Шрифт"
	L.SETTINGS_COLOR_GROUP_COUNT = "Цвет счётчика группы"
	L.SETTINGS_COLOR_GROUP_ARROW = "Цвет стрелки сворачивания"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Унаследовать цвет из группы"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Унаследовать цвет из группы"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Параметры заголовка группы"
	L.SETTINGS_GROUP_FONT_HEADER = "Шрифт заголовка группы"
	L.SETTINGS_GROUP_COLOR_HEADER = "Цвета заголовка группы"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Правый клик для наследования из группы"
	L.SETTINGS_INHERIT_TOOLTIP = "(Унаследовано из группы)"

	-- Misc
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "Глобальный список игнора"
	L.IGNORE_LIST_ENHANCEQOL_IGNORE = "Список игнора EnhanceQoL"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "Настройки имени друга"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "Настройки информации о друге"
	L.SETTINGS_FONT_TABS_TITLE = "Текст вкладок"
	L.SETTINGS_FONT_RAID_TITLE = "Текст имени рейда"
	L.SETTINGS_FONT_SIZE_NUM = "Размер шрифта"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "Синхронизация заметок групп"
	L.SETTINGS_SYNC_GROUPS_NOTE = "Синхронизировать группы в заметки друзей"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"Записывает назначения групп в заметки друзей в формате FriendGroups (Заметка#Группа1#Группа2). Позволяет делиться группами между аккаунтами или с пользователями FriendGroups"
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
	L.MSG_INVITE_RAID_FULL = "Рейд полон (%d/40). Приглашения остановлены"

	-- ========================================
	-- SETTINGS (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "Показать приветственное сообщение"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC =
		"Показывать сообщение загрузки аддона в чат при входе"

	-- ========================================
	-- RAID CONVERSION / MOCK (Phase 21+)
	-- ========================================
	L.RAID_GROUP_NAME = "Группа %d"
	L.RAID_CONVERT_TO_PARTY = "Преобразовать в группу"
	L.RAID_CONVERT_TO_RAID = "Преобразовать в рейд"
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
		"Удалить данные FriendGroups (#Группа1#Группа2) из заметок друзей. Проверьте очищенные заметки перед применением."
	L.WIZARD_BTN = "Очистка заметок"
	L.WIZARD_BTN_TOOLTIP =
		"Открыть мастер очистки данных FriendGroups из заметок друзей"
	L.WIZARD_HEADER = "Очистка заметок"
	L.WIZARD_HEADER_DESC =
		"Удалить суффиксы FriendGroups из заметок друзей. Сначала создайте резервную копию, затем проверьте и примените изменения."
	L.WIZARD_COL_ACCOUNT = "Имя аккаунта"
	L.WIZARD_COL_BATTLETAG = "BattleTag"
	L.WIZARD_COL_NOTE = "Текущая заметка"
	L.WIZARD_COL_CLEANED = "Очищенная заметка"
	L.WIZARD_SEARCH_PLACEHOLDER = "Поиск..."
	L.WIZARD_BACKUP_BTN = "Резервная копия"
	L.WIZARD_BACKUP_DONE = "Сохранено!"
	L.WIZARD_BACKUP_TOOLTIP =
		"Сохранить все текущие заметки друзей в базу данных как резервную копию"
	L.WIZARD_BACKUP_SUCCESS = "Создана резервная копия заметок для %d друзей"
	L.WIZARD_APPLY_BTN = "Применить очистку"
	L.WIZARD_APPLY_TOOLTIP =
		"Записать очищенные заметки обратно. Будут обновлены только заметки, отличающиеся от оригинала."
	L.WIZARD_APPLY_CONFIRM =
		"Применить очищенные заметки ко всем друзьям?\n\n|cffff8800Текущие заметки будут перезаписаны. Убедитесь, что вы создали резервную копию!|r"
	L.WIZARD_APPLY_SUCCESS = "%d заметок успешно обновлено"
	L.WIZARD_APPLY_PROGRESS_FMT = "Прогресс: %d/%d | %d успешно | %d ошибок"
	L.WIZARD_STATUS_FMT =
		"Показано %d из %d друзей | %d с данными групп | %d ожидающих изменений"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "Просмотр резервной копии"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"Откройте просмотр резервных копий, чтобы увидеть все сохраненные заметки и сравнить их с текущими"
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
	L.WIZARD_RESTORE_SUCCESS = "%d заметок успешно восстановлено"
	L.WIZARD_NO_BACKUP =
		"Резервная копия заметок не найдена. Сначала используйте Мастер очистки заметок для создания копии."
	L.WIZARD_BACKUP_STATUS_FMT =
		"Показано %d из %d записей | %d изменено после резервного копирования | Копия: %s"
end)
