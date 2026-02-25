-- Locales/zhCN.lua
-- Chinese Simplified (简体中文) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("zhCN", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"禁用玩家肖像，隐藏搜索/排序选项，拓宽框架并移动选项卡以获得紧凑布局。"
	L.MENU_CHANGELOG = "Changelog"
	L.DIALOG_CREATE_GROUP_TEXT = "输入新分组的名称："
	L.DIALOG_CREATE_GROUP_BTN1 = "创建"
	L.DIALOG_CREATE_GROUP_BTN2 = "取消"
	L.DIALOG_RENAME_GROUP_TEXT = "输入分组的新名称："
	L.DIALOG_RENAME_GROUP_BTN1 = "重命名"
	L.DIALOG_RENAME_GROUP_BTN2 = "取消"
	L.DIALOG_RENAME_GROUP_SETTINGS = "重命名组 '%s'："
	L.DIALOG_DELETE_GROUP_TEXT =
		"确定要删除此分组吗？\n\n|cffff0000这将移除该分组中的所有好友。|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "删除"
	L.DIALOG_DELETE_GROUP_BTN2 = "取消"
	L.DIALOG_DELETE_GROUP_SETTINGS = "删除分组 '%s'？\n\n所有好友将从此分组中移除。"
	L.DIALOG_RESET_SETTINGS_TEXT = "将所有设置重置为默认值？"
	L.DIALOG_RESET_BTN1 = "重置"
	L.DIALOG_RESET_BTN2 = "取消"
	L.DIALOG_UI_PANEL_RELOAD_TEXT = "更改UI层次结构设置需要重新加载界面。\n\n现在重新加载？"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "重新加载"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "取消"
	L.MSG_RELOAD_REQUIRED = "在Classic中，您需要重新加载UI以正确应用此更改。"
	L.MSG_RELOAD_NOW = "现在重新加载UI吗？"
	L.RAID_HELP_TITLE = "团队帮助"
	L.RAID_HELP_TEXT = "点击查看团队名单使用帮助。"
	L.RAID_HELP_MULTISELECT_TITLE = "多选"
	L.RAID_HELP_MULTISELECT_TEXT =
		"按住 Ctrl 键并左键点击选择多个玩家。\n选择后，将它们拖放到任何小队中以一次性移动所有玩家。"
	L.RAID_HELP_MAINTANK_TITLE = "主坦克"
	L.RAID_HELP_MAINTANK_TEXT = "%s - 设置为主坦克。\n其名字旁边将显示坦克图标。"
	L.RAID_HELP_MAINASSIST_TITLE = "主助理"
	L.RAID_HELP_MAINASSIST_TEXT = "%s - 设置为主助理。\n其名字旁边将显示助理图标。"
	L.RAID_HELP_LEAD_TITLE = "团长"
	L.RAID_HELP_LEAD_TEXT = "%s - 提升为团长。"
	L.RAID_HELP_PROMOTE_TITLE = "助理"
	L.RAID_HELP_PROMOTE_TEXT = "%s - 提升/降级为助理。"
	L.RAID_HELP_DRAGDROP_TITLE = "拖放"
	L.RAID_HELP_DRAGDROP_TEXT =
		"拖动任何玩家即可在小队之间移动。\n你也可以同时拖动多个选中的玩家。\n空位可用于交换位置。"
	L.RAID_HELP_COMBAT_TITLE = "战斗锁定"
	L.RAID_HELP_COMBAT_TEXT = "战斗中无法移动玩家。\n这是暴雪的限制以防止错误。"
	L.RAID_INFO_UNAVAILABLE = "团队信息不可用"
	L.RAID_NOT_IN_RAID = "不在团队中"
	L.RAID_NOT_IN_RAID_DETAILS = "您当前不在团队中"
	L.RAID_CREATE_BUTTON = "创建团队"
	L.GROUP = "队伍"
	L.ALL = "全部"
	L.UNKNOWN_ERROR = "未知错误"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "空间不足：选择了 %d 名玩家，队伍 %d 中有 %d 个空位"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "已移动 %d 名玩家到队伍 %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "移动%d名玩家失败"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "你必须是团队领袖或助理才能发起就位确认。"
	L.RAID_ERROR_NO_SAVED_INSTANCES = "没有保存的副本进度。"
	L.RAID_ERROR_LOAD_RAID_INFO = "错误：无法加载团队信息窗口。"
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s 已交换"
	L.RAID_ERROR_SWAP_FAILED = "交换失败：%s"
	L.RAID_MSG_MOVE_SUCCESS = "%s 已移动到队伍 %d"
	L.RAID_ERROR_MOVE_FAILED = "移动失败：%s"
	L.RAID_TOOLS_TITLE = "团队工具"
	L.RAID_TOOLS_SORT_HEADER = "排序"
	L.RAID_TOOLS_SORT_DEFAULT = "排列团队"
	L.RAID_TOOLS_SORT_DEFAULT_DESC = "按选定的排序顺序根据角色安排团队成员"
	L.RAID_TOOLS_SPLIT_HEADER = "分组"
	L.RAID_TOOLS_SPLIT_GROUPS = "均分两半"
	L.RAID_TOOLS_SPLIT_GROUPS_DESC = "将团队分成两个平衡的半组"
	L.RAID_TOOLS_SPLIT_EVENS_ODDS = "奇数/偶数"
	L.RAID_TOOLS_SPLIT_EVENS_ODDS_DESC = "将团队分成奇数 (1, 3, 5) 和偶数 (2, 4, 6) 组"
	L.RAID_TOOLS_SPLIT_BALANCE_DPS = "平衡 DPS"
	L.RAID_TOOLS_UTILITIES_HEADER = "实用工具"
	L.RAID_TOOLS_SETTINGS_HEADER = "选项"
	L.RAID_TOOLS_PROMOTE_TANKS = "提升坦克"
	L.RAID_TOOLS_PROMOTE_TANKS_DESC = "将所有担任坦克角色的玩家设为团队助理"
	L.RAID_TOOLS_STATUS_DONE = "完成！"
	L.RAID_TOOLS_STATUS_SORTING = "排序中..."
	L.RAID_TOOLS_STATUS_PROGRESS = "排序中... (%d/%d)"
	L.RAID_TOOLS_STATUS_ABORTED_COMBAT = "已中止 - 进入战斗"
	L.RAID_TOOLS_STATUS_COOLDOWN = "请稍等..."
	L.RAID_TOOLS_STATUS_PROMOTED = "已提升 %d 个坦克"
	L.RAID_TOOLS_STATUS_NO_TANKS = "没有坦克可提升"
	L.RAID_TOOLS_STATUS_ERROR_COMBAT = "战斗中无法排序"
	L.RAID_TOOLS_STATUS_ERROR_NOT_IN_RAID = "不在团队中"
	L.RAID_TOOLS_STATUS_ERROR_NOT_LEADER = "需要团长或助理"
	L.RAID_TOOLS_STATUS_ERROR_LEADER_ONLY = "需要团长"
	L.RAID_TOOLS_STATUS_DISBANDED = "已取消 - 团队正在解散"
	L.RAID_TOOLS_STATUS_PAUSED_COMBAT = "已暂停 - 战斗中"
	L.RAID_TOOLS_STATUS_RESUMING = "恢复中..."
	L.RAID_TOOLS_SORT_MODE_TMRH = "坦克 > 近战 > 远程 > 治疗"
	L.RAID_TOOLS_SORT_MODE_THMR = "坦克 > 治疗 > 近战 > 远程"
	L.RAID_TOOLS_SORT_MODE_METER = "伤害统计 (DPS 按伤害量排序)"
	L.RAID_TOOLS_STATUS_NO_METER_DATA = "没有可用的伤害统计数据"
	L.RAID_TOOLS_SETTING_SORT_MODE = "排序模式"
	L.RAID_TOOLS_SETTING_GROUP_OFFSET = "保留队伍"
	L.RAID_TOOLS_SETTING_OFFSET_NONE = "无"
	L.RAID_TOOLS_SETTING_GROUP_N = "第%d组"
	L.RAID_TOOLS_SETTING_RESUME_COMBAT = "战斗后自动继续"
	L.DIALOG_MIGRATE_TEXT =
		"从FriendGroups迁移好友分组到BetterFriendlist？\n\n这将会：\n• 从BNet备注创建所有分组\n• 将好友分配到对应分组\n• 可选打开备注清理向导来审查并清理备注\n\n|cffff0000警告：此操作无法撤销！|r"
	L.DIALOG_MIGRATE_BTN1 = "迁移并审查备注"
	L.DIALOG_MIGRATE_BTN2 = "仅迁移"
	L.DIALOG_MIGRATE_BTN3 = "取消"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_FONTS = "字体"
	L.SETTINGS_TAB_GENERAL = "常规"
	L.SETTINGS_TAB_GROUPS = "分组"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "继承群组颜色"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "继承群组颜色"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "右键继承群组颜色"
	L.SETTINGS_INHERIT_TOOLTIP = "(继承自群组)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "外观"
	L.SETTINGS_TAB_ADVANCED = "高级"
	L.SETTINGS_ADVANCED_DESC = "Advanced options and tools."
	L.SETTINGS_TAB_STATISTICS = "统计"
	L.SETTINGS_SHOW_BLIZZARD = "显示暴雪好友列表选项"
	L.SETTINGS_COMPACT_MODE = "紧凑模式"
	L.SETTINGS_LOCK_WINDOW = "锁定窗口"
	L.SETTINGS_LOCK_WINDOW_DESC = "锁定窗口以防止意外移动。"
	L.SETTINGS_FONT_SIZE = "字体大小"
	L.SETTINGS_FONT_COLOR = "字体颜色"
	L.SETTINGS_FONT_SIZE_SMALL = "小 (紧凑, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "正常 (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "大 (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "职业名称着色"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "隐藏空分组"
	L.SETTINGS_HEADER_COUNT_FORMAT = "分组标题计数"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "选择如何在分组标题中显示好友计数"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "已过滤 / 总计 (默认)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "在线 / 总计"
	L.SETTINGS_HEADER_COUNT_BOTH = "已过滤 / 在线 / 总计"
	L.SETTINGS_SHOW_FACTION_ICONS = "显示阵营图标"
	L.SETTINGS_SHOW_REALM_NAME = "显示服务器名称"
	L.SETTINGS_GRAY_OTHER_FACTION = "淡化其他阵营"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "将移动版显示为离开"
	L.SETTINGS_SHOW_MOBILE_TEXT = "显示移动版文本"
	L.SETTINGS_HIDE_MAX_LEVEL = "隐藏最高等级"
	L.SETTINGS_ACCORDION_GROUPS = "手风琴分组（一次打开一个）"
	L.SETTINGS_SHOW_FAVORITES = "显示收藏分组"
	L.SETTINGS_SHOW_GROUP_FMT = "显示%s分组"
	L.SETTINGS_SHOW_GROUP_DESC_FMT = "切换好友列表中%s分组的显示"
	L.SETTINGS_GROUP_COLOR = "分组颜色"
	L.SETTINGS_RENAME_GROUP = "重命名分组"
	L.SETTINGS_DELETE_GROUP = "删除分组"
	L.SETTINGS_DELETE_GROUP_DESC = "删除此分组并取消所有好友的分配"
	L.SETTINGS_EXPORT_TITLE = "导出设置"
	L.SETTINGS_EXPORT_INFO = "复制下面的文本并保存。您可以在其他角色或账户上导入。"
	L.SETTINGS_EXPORT_BTN = "全选"
	L.BUTTON_EXPORT = "导出"
	L.SETTINGS_IMPORT_TITLE = "导入设置"
	L.SETTINGS_IMPORT_INFO =
		"将导出字符串粘贴到下方并点击导入。\n\n|cffff0000警告：这将替换所有分组和分配！|r"
	L.SETTINGS_IMPORT_BTN = "导入"
	L.SETTINGS_IMPORT_CANCEL = "取消"
	L.SETTINGS_RESET_DEFAULT = "重置为默认值"
	L.SETTINGS_RESET_SUCCESS = "设置已重置为默认值！"
	L.SETTINGS_GROUP_ORDER_SAVED = "分组顺序已保存！"
	L.SETTINGS_MIGRATION_COMPLETE = "迁移完成！"
	L.SETTINGS_MIGRATION_FRIENDS = "已处理好友："
	L.SETTINGS_MIGRATION_GROUPS = "已创建分组："
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "已创建分配："
	L.SETTINGS_NOTES_CLEANED = "备注已清理！"
	L.SETTINGS_NOTES_PRESERVED = "备注已保留（您可以手动清理）。"
	L.SETTINGS_EXPORT_SUCCESS = "导出完成！从对话框复制文本。"
	L.SETTINGS_IMPORT_SUCCESS = "导入成功！所有分组和分配已恢复。"
	L.SETTINGS_IMPORT_FAILED = "导入失败！\n\n"
	L.STATS_TOTAL_FRIENDS = "总好友数：%d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00在线：%d|r  |  |cff808080离线：%d|r"
	L.STATS_BNET_WOW = "|cff0070dd战网：%d|r  |  |cffffd700魔兽世界：%d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "好友请求（%d）"
	L.INVITE_BUTTON_ACCEPT = "接受"
	L.INVITE_BUTTON_DECLINE = "拒绝"
	L.INVITE_TAP_TEXT = "点击以接受或拒绝"
	L.INVITE_MENU_DECLINE = "拒绝"
	L.INVITE_MENU_REPORT = "举报玩家"
	L.INVITE_MENU_BLOCK = "屏蔽邀请"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "所有好友"
	L.FILTER_ONLINE_ONLY = "仅在线"
	L.FILTER_OFFLINE_ONLY = "仅离线"
	L.FILTER_WOW_ONLY = "仅魔兽世界"
	L.FILTER_BNET_ONLY = "仅战网"
	L.FILTER_HIDE_AFK = "隐藏暂离/请勿打扰"
	L.FILTER_RETAIL_ONLY = "仅正式服"
	L.FILTER_TOOLTIP = "快速筛选：%s"
	L.SORT_STATUS = "状态"
	L.SORT_NAME = "姓名 (A-Z)"
	L.SORT_LEVEL = "等级"
	L.SORT_ZONE = "区域"
	L.SORT_GAME = "游戏"
	L.SORT_FACTION = "阵营"
	L.SORT_GUILD = "公会"
	L.SORT_CLASS = "职业"
	L.SORT_REALM = "服务器"
	L.SORT_CHANGED = "排序已更改为：%s"
	L.SORT_NONE = "None"
	L.SORT_PRIMARY_LABEL = "Primary Sort"
	L.SORT_SECONDARY_LABEL = "Secondary Sort"
	L.SORT_PRIMARY_DESC = "选择如何对好友列表进行排序。"
	L.SORT_SECONDARY_DESC = "当主值相等时按此排序。"

	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "分组"
	L.MENU_CREATE_GROUP = "创建分组"
	L.MENU_REMOVE_ALL_GROUPS = "从所有分组移除"
	L.MENU_REMOVE_RECENTLY_ADDED = "从最近添加中移除"
	L.MENU_CLEAR_ALL_RECENTLY_ADDED = "清除所有最近添加"
	L.MENU_ADD_ALL_TO_GROUP = "将全部添加到分组"
	L.MENU_RENAME_GROUP = "重命名分组"
	L.MENU_DELETE_GROUP = "删除分组"
	L.MENU_INVITE_GROUP = "邀请全部到队伍"
	L.MENU_COLLAPSE_ALL = "折叠所有分组"
	L.MENU_EXPAND_ALL = "展开所有分组"
	L.MENU_SETTINGS = "设置"
	L.MENU_SET_BROADCAST = "设置广播消息"
	L.MENU_IGNORE_LIST = "管理屏蔽列表"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "More Groups..."
	L.MENU_SWITCH_GAME_ACCOUNT = "切换游戏账号"
	L.MENU_DEFAULT_FOCUS = "默认（Blizzard）"
	L.GROUPS_DIALOG_TITLE = "Groups for %s"
	L.MENU_COPY_CHARACTER_NAME = "复制角色名称"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "复制角色名称"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "释放以添加到分组"
	L.TOOLTIP_HOLD_SHIFT = "按住 Shift 以保留在其他分组中"
	L.TOOLTIP_DRAG_HERE = "将好友拖到此处添加"
	L.TOOLTIP_ERROR = "错误"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "没有可用的游戏账户"
	L.TOOLTIP_NO_INFO = "可用信息不足"
	L.TOOLTIP_RENAME_GROUP = "重命名分组"
	L.TOOLTIP_RENAME_DESC = "点击以重命名此分组"
	L.TOOLTIP_GROUP_COLOR = "分组颜色"
	L.TOOLTIP_GROUP_COLOR_DESC = "点击以更改此分组的颜色"
	L.TOOLTIP_DELETE_GROUP = "删除分组"
	L.TOOLTIP_DELETE_DESC = "删除此分组并取消所有好友的分配"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "已邀请 %d 位好友到队伍。"
	L.MSG_NO_FRIENDS_AVAILABLE = "没有在线好友可邀请。"
	L.MSG_GROUP_DELETED = "分组 '%s' 已删除"
	L.MSG_IGNORE_LIST_EMPTY = "您的屏蔽列表为空。"
	L.MSG_IGNORE_LIST_COUNT = "屏蔽列表（%d 位玩家）："
	L.MSG_MIGRATION_ALREADY_DONE = "迁移已完成。使用 '/bfl migrate force' 重新运行。"
	L.MSG_MIGRATION_STARTING = "开始从 FriendGroups 迁移..."
	L.MSG_GROUP_ORDER_SAVED = "分组顺序已保存！"
	L.MSG_SETTINGS_RESET = "设置已重置为默认值！"
	L.MSG_EXPORT_FAILED = "导出失败：%s"
	L.MSG_IMPORT_SUCCESS = "导入成功！所有分组和分配已恢复。"
	L.MSG_IMPORT_FAILED = "导入失败：%s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "数据库不可用！"
	L.ERROR_SETTINGS_NOT_INIT = "框架未初始化！"
	L.ERROR_MODULES_NOT_LOADED = "模块不可用！"
	L.ERROR_GROUPS_MODULE = "分组模块不可用！"
	L.ERROR_SETTINGS_MODULE = "设置模块不可用！"
	L.ERROR_FRIENDSLIST_MODULE = "好友列表模块不可用"
	L.ERROR_FAILED_DELETE_GROUP = "删除分组失败 - 模块未加载"
	L.ERROR_FAILED_DELETE = "删除分组失败：%s"
	L.ERROR_MIGRATION_FAILED = "迁移失败 - 模块未加载！"
	L.ERROR_GROUP_NAME_EMPTY = "分组名称不能为空"
	L.ERROR_GROUP_EXISTS = "分组已存在"
	L.ERROR_INVALID_GROUP_NAME = "无效的分组名称"
	L.ERROR_GROUP_NOT_EXIST = "分组不存在"
	L.ERROR_CANNOT_RENAME_BUILTIN = "无法重命名内置分组"
	L.ERROR_INVALID_GROUP_ID = "无效的分组 ID"
	L.ERROR_CANNOT_DELETE_BUILTIN = "无法删除内置分组"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "好友"
	L.GROUP_FAVORITES = "收藏"
	L.GROUP_INGAME = "In Game"
	L.GROUP_NO_GROUP = "无分组"
	L.GROUP_RECENTLY_ADDED = "最近添加"
	L.ONLINE_STATUS = "在线"
	L.OFFLINE_STATUS = "离线"
	L.STATUS_MOBILE = "移动版"
	L.STATUS_IN_APP = "在程序中"
	L.UNKNOWN_GAME = "未知游戏"
	L.BUTTON_ADD_FRIEND = "添加好友"
	L.BUTTON_SEND_MESSAGE = "发送消息"
	L.EMPTY_TEXT = "空"
	L.LEVEL_FORMAT = "%d 级"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "测试功能"
	L.SETTINGS_BETA_FEATURES_DESC = "启用实验性功能"
	L.SETTINGS_BETA_FEATURES_ENABLE = "启用测试功能"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "启用实验性功能（通知等）"
	L.SETTINGS_BETA_FEATURES_WARNING =
		"警告：测试功能可能包含错误、性能问题或不完整的功能。使用风险自负。"
	L.SETTINGS_BETA_FEATURES_LIST = "当前可用的测试功能："
	L.SETTINGS_BETA_FEATURES_ENABLED = "测试功能 |cff00ff00已启用|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "测试功能 |cffff0000已禁用|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "测试标签页现在在设置中可见"
	L.SETTINGS_BETA_TABS_HIDDEN = "测试标签页现在已隐藏"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "启用全局好友同步"
	L.SETTINGS_GLOBAL_SYNC_DESC = "在所有角色间同步设置"
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "全局好友同步"
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
	L.SETTINGS_FRAME_SIZE_HEADER = "默认框架大小 (编辑模式)"
	L.SETTINGS_FRAME_SIZE_INFO = "设置新编辑模式布局的首选默认大小。"
	L.SETTINGS_FRAME_WIDTH = "宽度:"
	L.SETTINGS_FRAME_HEIGHT = "高度:"
	L.SETTINGS_FRAME_RESET_SIZE = "重置为 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "应用到当前布局"
	L.SETTINGS_FRAME_RESET_ALL = "重置所有布局"

	-- ========================================
	-- DATA BROKER
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "好友"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "左键: 切换BetterFriendlist"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "右键: 设置"
	L.BROKER_SETTINGS_ENABLE = "启用数据代理"
	L.BROKER_SETTINGS_SHOW_ICON = "显示图标"
	L.BROKER_SETTINGS_SHOW_TEXT = "Show Text"
	L.BROKER_SETTINGS_SHOW_TOTAL = "显示总数"
	L.BROKER_SETTINGS_SHOW_ONLINE = "Show Online Count"
	L.BROKER_SETTINGS_SHOW_BNET = "Show Battle.net Count"
	L.BROKER_SETTINGS_SHOW_WOW = "Show WoW Count"
	L.BROKER_SETTINGS_TEXT_FORMAT = "Text Format"
	L.BROKER_SETTINGS_TEXT_FORMAT_DESC = "Choose how the text is displayed on the broker"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Tooltip Detail Level"
	L.BROKER_SETTINGS_CLICK_ACTION = "Left Click Action"
	L.BROKER_FILTER_CHANGED = "过滤器已更改为：%s"
	L.BROKER_FORMAT_FULL = "Full (Online: 5 | BNet: 3 | WoW: 2)"
	L.BROKER_FORMAT_COMPACT = "Compact (5 Online)"
	L.BROKER_FORMAT_MINIMAL = "Minimal (5)"
	L.BROKER_FORMAT_ICON = "Icon Only"
	L.BROKER_TOOLTIP_MODE_NONE = "None"
	L.BROKER_TOOLTIP_MODE_SIMPLE = "Simple (Counts only)"
	L.BROKER_TOOLTIP_MODE_FULL = "Full (List friends)"
	L.BROKER_ACTION_TOGGLE = "Toggle Window"
	L.BROKER_ACTION_SETTINGS = "打开设置"
	L.BROKER_COLUMN_NAME = "角色"
	L.BROKER_COLUMN_STATUS = "Status"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "服务器"
	L.BROKER_COLUMN_NOTES = "备注"
	L.BROKER_COLUMN_NAME_DESC = "Display friend names"
	L.BROKER_COLUMN_STATUS_DESC = "Display online status/game"
	L.BROKER_COLUMN_ZONE_DESC = "Display current zone"
	L.BROKER_COLUMN_REALM_DESC = "Display realm name"
	L.BROKER_COLUMN_NOTES_DESC = "显示好友备注"

	-- Broker
	L.BROKER_SETTINGS_LEFT_CLICK = "左键动作"
	L.BROKER_SETTINGS_RIGHT_CLICK = "右键动作"
	L.BROKER_ACTION_OPEN_BNET = "Open BNet App"
	L.BROKER_ACTION_NONE = "None"
	L.BROKER_SETTINGS_INFO =
		"BetterFriendlist integrates with Data Broker display addons like Bazooka, ChocolateBar, and TitanPanel."
	L.BROKER_HEADER_WOW = "WoW好友"
	L.BROKER_HEADER_BNET = "Battle.Net好友"
	L.BROKER_NO_WOW_ONLINE = "  没有在线WoW好友"
	L.BROKER_NO_FRIENDS_ONLINE = "没有在线好友"
	L.BROKER_TOTAL_ONLINE = "总计: %d 在线 / %d 好友"
	L.BROKER_FILTER_LABEL = "过滤器："
	L.BROKER_SORT_LABEL = "排序: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- 好友行动作 ---"
	L.BROKER_HINT_CLICK_WHISPER = "点击好友:"
	L.BROKER_HINT_WHISPER = " 密语 • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "右键:"
	L.BROKER_HINT_CONTEXT_MENU = " 右键菜单"
	L.BROKER_HINT_ALT_CLICK = "Alt+点击:"
	L.BROKER_HINT_INVITE = " 邀请/加入 • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+点击:"
	L.BROKER_HINT_COPY = " 复制到聊天"
	L.BROKER_HINT_ICON_ACTIONS = "--- 代理图标动作 ---"
	L.BROKER_HINT_LEFT_CLICK = "左键:"
	L.BROKER_HINT_TOGGLE = " 切换BetterFriendlist"
	L.BROKER_HINT_RIGHT_CLICK = "右键:"
	L.BROKER_HINT_SETTINGS = " 设置 • "
	L.BROKER_HINT_MIDDLE_CLICK = "中键:"
	L.BROKER_HINT_CYCLE_FILTER = " 切换过滤器"
	L.BROKER_SETTINGS_SHOW_LABEL = "显示标签"
	L.BROKER_SETTINGS_SHOW_GROUPS = "分离WoW和BNet好友计数"
	L.BROKER_SETTINGS_HEADER_GENERAL = "常规设置"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "数据代理集成"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "交互"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "使用方法"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "已测试的显示插件"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Install a Data Broker display addon\n• Enable Data Broker above"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "提示框列"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "提示框列"
	L.BROKER_COLUMN_LEVEL = "等级"
	L.BROKER_COLUMN_CHARACTER = "角色"
	L.BROKER_COLUMN_GAME = "游戏 / 应用"
	L.BROKER_COLUMN_FACTION = "阵营"
	L.BROKER_COLUMN_LEVEL_DESC = "显示角色等级"
	L.BROKER_COLUMN_CHARACTER_DESC = "显示角色名和职业图标"
	L.BROKER_COLUMN_GAME_DESC = "显示好友正在玩的游戏或应用"
	L.BROKER_COLUMN_FACTION_DESC = "Display the faction icon"
	L.BROKER_ACTION_FRIENDS = "Friends"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: 将手机用户视为离线
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "将手机用户视为离线"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "将使用手机应用的好友显示在离线组中"

	-- Feature 3: 显示备注作为名称
	L.SETTINGS_SHOW_NOTES_AS_NAME = "显示备注作为好友名称"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "当有备注时，显示好友备注作为他们的名称"

	-- Feature 4: 窗口缩放
	L.SETTINGS_WINDOW_SCALE = "窗口缩放"
	L.SETTINGS_WINDOW_SCALE_DESC = "缩放整个窗口（50%% - 200%%）"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "最近的盟友在Classic中不可用"
	L.EDIT_MODE_NOT_AVAILABLE = "编辑模式在Classic中不可用"
	L.CLASSIC_COMPATIBILITY_INFO = "正在Classic兼容模式下运行"
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "此功能在Classic中不可用"
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "打开公会时关闭 BetterFriendlist"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "点击公会标签时自动关闭 BetterFriendlist"
	L.SETTINGS_HIDE_GUILD_TAB = "隐藏公会标签"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "从好友列表中隐藏公会标签"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "遵守UI层级"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC =
		"防止BetterFriendlist在其他UI窗口(角色、法术书等)上方打开。需要/reload。"

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 m"
	L.LASTONLINE_MINUTES = "%d m"
	L.LASTONLINE_HOURS = "%d h"
	L.LASTONLINE_DAYS = "%d d"
	L.LASTONLINE_MONTHS = "%d mo"
	L.LASTONLINE_YEARS = "%d y"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "Classic Guild UI Disabled"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist has disabled the Classic Guild UI because only the modern Blizzard Guild UI is compatible with BetterFriendlist.\n\nThe Guild tab now opens the modern Blizzard Guild UI."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Use '/bfl migrate help' for help."
	L.LOADED_MESSAGE = "BetterFriendlist loaded."
	L.DEBUG_ENABLED = "Debug ENABLED"
	L.DEBUG_DISABLED = "Debug DISABLED"
	L.CONFIG_RESET = "Config reset."
	L.SEARCH_PLACEHOLDER = "搜索好友..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "公会"
	L.TAB_RAID = "Raid"
	L.TAB_QUICK_JOIN = "Quick Join"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Online"
	L.FILTER_SEARCH_OFFLINE = "Offline"
	L.FILTER_SEARCH_MOBILE = "移动端"
	L.FILTER_SEARCH_AFK = "暂离"
	L.FILTER_SEARCH_DND = "请勿打扰"

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
	L.LEADER_LABEL = "队长:"
	L.MEMBERS_LABEL = "成员:"
	L.AVAILABLE_ROLES = "可用角色"
	L.NO_AVAILABLE_ROLES = "No roles"
	L.AUTO_ACCEPT_TOOLTIP = "Auto Accept"
	L.MOCK_JOIN_REQUEST_SENT = "Mock Request Sent"
	L.QUICK_JOIN_NO_GROUPS = "No groups"
	L.UNKNOWN_GROUP = "未知队伍"
	L.UNKNOWN = "未知"
	L.NO_QUEUE = "无队列"
	L.LFG_ACTIVITY = "寻求组队活动"
	L.ACTIVITY_DUNGEON = "地下城"
	L.ACTIVITY_RAID = "团队"
	L.ACTIVITY_PVP = "PvP"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "导入设置"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "导出设置"
	L.DIALOG_DELETE_GROUP_TITLE = "Delete Group"
	L.DIALOG_RENAME_GROUP_TITLE = "Rename Group"
	L.DIALOG_CREATE_GROUP_TITLE = "Create Group"

	-- Tooltips
	L.TOOLTIP_LAST_ONLINE = "最后上线: %s"

	-- Notifications
	L.YES = "YES"
	L.NO = "NO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "预览 %d"
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
	L.DIALOG_TRIGGER_CREATE = "创建"
	L.DIALOG_TRIGGER_CANCEL = "取消"
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
	L.FILTER_INGAME = "游戏中"
	L.TOOLTIP_QUICK_FILTER = "Filter: %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Reload required.\n\nReload?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Reload"
	L.BROKER_SETTINGS_RELOAD_CANCEL = "取消"
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
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "显示WoW图标"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "WoW Friends Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "BNet Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "显示BNet图标"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "BNet Friends Icon"
	L.STATUS_ENABLED = "|cff00ff00Enabled|r"
	L.STATUS_DISABLED = "|cffff0000已禁用|r"
	L.BROKER_WOW_FRIENDS = "WoW好友:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Global Sync"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Enable Friend Sync"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "显示已删除"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "显示已删除的好友"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Show deleted in list"
	L.TOOLTIP_RESTORE_FRIEND = "Restore"
	L.TOOLTIP_DELETE_FRIEND = "Delete"
	L.POPUP_EDIT_NOTE_TITLE = "编辑备注"
	L.BUTTON_SAVE = "保存"
	L.BUTTON_CANCEL = "取消"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "好友: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d tot"
	L.BROKER_CURRENT_FILTER = "Filter:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "中键点击: 切换过滤器"
	L.BROKER_AND_MORE = "  ... and %d others"
	L.BROKER_TOTAL_LABEL = "总计:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d friends"
	L.MENU_CHANGE_COLOR = "更改颜色"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Tooltip Error|r"
	L.STATUS_LABEL = "状态:"
	L.STATUS_AWAY = "离开"
	L.STATUS_DND_FULL = "Do Not Disturb"
	L.GAME_LABEL = "游戏:"
	L.REALM_LABEL = "服务器:"
	L.CLASS_LABEL = "职业："
	L.FACTION_LABEL = "阵营:"
	L.ZONE_LABEL = "区域:"
	L.NOTE_LABEL = "备注:"
	L.BROADCAST_LABEL = "Msg:"
	L.ACTIVE_SINCE_FMT = "活跃时间：%s"
	L.HINT_RIGHT_CLICK_OPTIONS = "Right-Click Options"
	L.HEADER_ADD_FRIEND = "|cffffd700将%s添加到%s|r"

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
	L.RECENT_ALLIES_INVITE = "邀请"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Player offline"
	L.RECENT_ALLIES_PIN_EXPIRES = "固定将在%s后过期"
	L.RECENT_ALLIES_LEVEL_RACE = "Lvl %d %s"
	L.RECENT_ALLIES_NOTE = "Note: %s"
	L.RECENT_ALLIES_ACTIVITY = "最近活动:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "战友招募"
	L.RAF_RECRUITMENT = "招募"
	L.RAF_NO_RECRUITS_DESC = "No recruits."
	L.RAF_PENDING_RECRUIT = "Pending"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Earned:"
	L.RAF_NEXT_REWARD_AFTER = "Next in %d/%d months"
	L.RAF_FIRST_REWARD = "First:"
	L.RAF_NEXT_REWARD = "Next:"
	L.RAF_REWARD_MOUNT = "Mount"
	L.RAF_REWARD_TITLE_DEFAULT = "头衔"
	L.RAF_REWARD_TITLE_FMT = "Title: %s"
	L.RAF_REWARD_GAMETIME = "Game Time"
	L.RAF_MONTH_COUNT = "%d Months"
	L.RAF_CLAIM_REWARD = "Claim"
	L.RAF_VIEW_ALL_REWARDS = "View All"
	L.RAF_ACTIVE_RECRUIT = "活跃"
	L.RAF_TRIAL_RECRUIT = "试用版"
	L.RAF_INACTIVE_RECRUIT = "不活跃"
	L.RAF_OFFLINE = "Offline"
	L.RAF_TOOLTIP_DESC = "最多%d个月"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d months"
	L.RAF_ACTIVITY_DESCRIPTION = "Activity for %s"
	L.RAF_REWARDS_LABEL = "Rewards"
	L.RAF_YOU_EARNED_LABEL = "Earned:"
	L.RAF_CLICK_TO_CLAIM = "Click to claim"
	L.RAF_LOADING = "加载中..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== RAF ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Current"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Legacy v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Months: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  新兵: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Rewards Avail:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[已领取]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Claimable]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[可获取]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[已锁定]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d个月)"
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
	L.STATS_TOP_REALMS = "\n热门服务器:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\n其他: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Notes: %d (%d%%)\nFavorites: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max: %d\n70-79: %d\n60-69: %d\n<60: %d\nAvg: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Active: %d (%d%%)|r\n|cffffd700Med: %d (%d%%)|r\n|cffffaa00Old: %d (%d%%)|r\n|cffff6600Stale: %d (%d%%)|r\n|cffff0000Inactive: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ff联盟: %d|r\n|cffff0000部落: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "向下移动"
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
	L.TRAVEL_PASS_DIFFERENT_FACTION = "Opposite faction"
	L.TRAVEL_PASS_QUEST_SESSION = "Cannot invite during a quest session"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Show Blizzard List"
	L.MENU_COMBAT_LOCKED = "Combat Locked"
	L.MENU_SET_NICKNAME = "设置昵称"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "BetterFriendlist设置"
	L.SEARCH_FRIENDS_INSTRUCTION = "Search..."
	L.SEARCH_RECENT_ALLIES_INSTRUCTION = "Search recent allies..."
	L.SEARCH_RAF_INSTRUCTION = "Search recruited friends..."
	L.RAF_NEXT_REWARD_HELP = "RAF Info"
	L.WHO_LEVEL_FORMAT = "Level %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "最近队友"
	L.CONTACTS_MENU_NAME = "联系人菜单"
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
		"使用标记自定义显示:\n|cffFFD100%name%|r - 账户名\n|cffFFD100%battletag%|r - 战网昵称\n|cffFFD100%nickname%|r - 备注名\n|cffFFD100%note%|r - 备注\n|cffFFD100%character%|r - 角色名\n|cffFFD100%realm%|r - 服务器名\n|cffFFD100%level%|r - 等级\n|cffFFD100%zone%|r - 区域\n|cffFFD100%class%|r - 职业\n|cffFFD100%game%|r - 游戏"
	L.SETTINGS_NAME_FORMAT_LABEL = "预设:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Name Format"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Enter format."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"由于插件 'FriendListColors' 正在管理名字颜色/格式，此设置已禁用。"

	-- Name Format Preset Labels (Phase 22)
	L.NAME_PRESET_DEFAULT = "名称 (角色)"
	L.NAME_PRESET_BATTLETAG = "战网昵称 (角色)"
	L.NAME_PRESET_NICKNAME = "备注名 (角色)"
	L.NAME_PRESET_NAME_ONLY = "仅名称"
	L.NAME_PRESET_CHARACTER = "仅角色"
	L.NAME_PRESET_CUSTOM = "自定义..."
	L.SETTINGS_NAME_FORMAT_CUSTOM_LABEL = "自定义格式:"

	-- Info Format Section (Phase 22)
	L.SETTINGS_INFO_FORMAT_HEADER = "好友信息格式"
	L.SETTINGS_INFO_FORMAT_LABEL = "预设:"
	L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL = "自定义格式:"
	L.SETTINGS_INFO_FORMAT_TOOLTIP = "Custom Info Format"
	L.SETTINGS_INFO_FORMAT_DESC =
		"使用标记自定义信息行:\n|cffFFD100%level%|r - 角色等级\n|cffFFD100%zone%|r - 当前区域\n|cffFFD100%class%|r - 职业名称\n|cffFFD100%game%|r - 游戏名称\n|cffFFD100%realm%|r - 服务器名称\n|cffFFD100%status%|r - AFK/DND/在线\n|cffFFD100%lastonline%|r - 上次在线\n|cffFFD100%name%|r - 账户名\n|cffFFD100%battletag%|r - 战网昵称\n|cffFFD100%nickname%|r - 备注名\n|cffFFD100%note%|r - 备注\n|cffFFD100%character%|r - 角色名"
	L.INFO_PRESET_DEFAULT = "Default (Level, Zone)"
	L.INFO_PRESET_ZONE = "Zone Only"
	L.INFO_PRESET_LEVEL = "Level Only"
	L.INFO_PRESET_CLASS_ZONE = "Class, Zone"
	L.INFO_PRESET_LEVEL_CLASS_ZONE = "Level Class, Zone"
	L.INFO_PRESET_GAME = "Game Name"
	L.INFO_PRESET_DISABLED = "Disabled (Hide Info)"
	L.INFO_PRESET_CUSTOM = "Custom..."
	L.SETTINGS_SHOW_INGAME_GROUP = "'In Game' Group"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Group in-game friends"
	L.SETTINGS_INGAME_MODE_WOW = "WoW Only"
	L.SETTINGS_INGAME_MODE_ANY = "Any Game"
	L.SETTINGS_INGAME_MODE_LABEL = "   模式:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Mode"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Choose friends."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT = "   持续时间单位："
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_DESC = "选择好友在最近添加分组中保留的时间单位。"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE = "   持续时间值："
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_DESC =
		"好友在最近添加分组中保留多少天/小时/分钟后被移除。"
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_TOOLTIP = "持续时间单位"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_TOOLTIP = "持续时间值"
	L.SETTINGS_DURATION_DAYS = "天"
	L.SETTINGS_DURATION_HOURS = "小时"
	L.SETTINGS_DURATION_MINUTES = "分钟"

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Display Options"
	L.SETTINGS_BEHAVIOR_HEADER = "Behavior"
	L.SETTINGS_GROUP_MANAGEMENT = "Group Management"
	L.SETTINGS_FONT_SETTINGS = "Font"
	L.SETTINGS_GROUP_ORDER = "分组顺序"
	L.SETTINGS_MIGRATION_HEADER = "FriendGroups Migration"
	L.SETTINGS_MIGRATION_DESC = "Migrate from FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migrate"
	L.SETTINGS_MIGRATE_TOOLTIP = "Import"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "将设置导出为字符串"
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
	L.CORE_CLASSIC_COMPAT_HEADER = "|cff00ff00=== Compat ===|r"
	L.CORE_CLIENT_VERSION = "|cffffcc00Ver Client:|r"
	L.CORE_DETECTED_FLAVOR = "|cffffcc00Flavor:|r"
	L.CORE_FLAVOR_CLASSIC_ERA = "  |cffffcc00Classic Era|r"
	L.CORE_FLAVOR_MOP = "  |cff00ffffPandaria|r"
	L.CORE_FLAVOR_TWW = "  |cff00ff00TWW|r"
	L.CORE_FLAVOR_MIDNIGHT = "  |cff8800ffMidnight|r"
	L.CORE_FLAVOR_RETAIL = "  |cffffffff正式服|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Avail:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menu Mod: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Allies Rec: %s"
	L.CORE_FEATURE_EDIT_MODE = "  编辑模式: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Compat:|r %s"
	L.CORE_COMPAT_ACTIVE = "Classic兼容模式已激活"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000未加载|r"
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
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - 重置窗口位置"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Open changelog window"
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
	L.TESTSUITE_PERFY_HELP = "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"
	L.TESTSUITE_PERFY_STARTING = "Starting Perfy stress test for %d seconds"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Perfy stress test already running"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Perfy addon not loaded (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Perfy slash command not available"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy stress action failed: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy stress test finished"
	L.TESTSUITE_PERFY_ABORTED = "Perfy stress test stopped: %s"
	L.CORE_HELP_LINK = "|cff20ff20Help:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. 已加载. Discord: /bfl discord"
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
	L.RAID_MEMBERS_STATUS = "  成员: %d"
	L.RAID_TOTAL_MEMBERS = "  Tot: %d"
	L.RAID_COMPOSITION = "团队配置"
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
	L.CHANGELOG_GITHUB = "   GitHub问题"
	L.CHANGELOG_SUPPORT = "   支持"
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
	L.PERF_FPS_60 = "  ✓ <16.6毫秒 = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3毫秒 = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Warning"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "移动版"
	L.RAF_RECRUITMENT = "战友招募"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "用职业颜色显示好友名字"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "字体轮廓"
	L.SETTINGS_FONT_SHADOW = "字体阴影"
	L.SETTINGS_FONT_OUTLINE_NONE = "无"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "轮廓"
	L.SETTINGS_FONT_OUTLINE_THICK = "粗轮廓"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "单色"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "编辑备注"
	L.MENU_SHOW_SEARCH = "显示搜索"
	L.MENU_QUICK_FILTER = "快速筛选"

	-- Multi-Game-Account
	L.MENU_INVITE_CHARACTER = "邀请角色..."
	L.INVITE_ACCOUNT_PICKER_TITLE = "邀请角色"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "启用收藏图标"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "在好友按钮上显示星星图标以标记收藏。"
	L.SETTINGS_FAVORITE_ICON_STYLE = "收藏图标"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC = "选择用于收藏的图标。"
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "BFL 图标"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "暴雪图标"
	L.SETTINGS_SHOW_FACTION_BG = "显示阵营背景"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "将阵营颜色显示为好友按钮的背景。"

	-- Multi-Game-Account Settings
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "显示多账号徽章"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC = "为同时在线多个游戏账号的好友显示徽章。"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "显示多账号信息"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC =
		"当好友同时登录多个账号时，附加一份在线角色的简短列表。"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS = "提示框：最大游戏账号数"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS_DESC = "提示框中显示的额外游戏账号最大数量。"
	L.INFO_MULTI_ACCOUNT_PREFIX = "x%d Accounts"
	L.INFO_MULTI_ACCOUNT_REMAINDER = " (+%d)"

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "主播模式"
	L.STREAMER_MODE_DESC = "直播或录制的隐私选项。"
	L.SETTINGS_ENABLE_STREAMER_MODE = "显示主播模式按钮"
	L.STREAMER_MODE_ENABLE_DESC = "在主框中显示一个扫推主播模式的按钮。"
	L.STREAMER_MODE_HIDDEN_NAME = "隐藏名称格式"
	L.STREAMER_MODE_HEADER_TEXT = "自定义标题文本"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"主播模式活跃时在 Battle.net 标题中显示的文本（例如，'主播模式'）。"
	L.STREAMER_MODE_BUTTON_TOOLTIP = "切换主播模式"
	L.STREAMER_MODE_BUTTON_DESC = "点击以启用/禁用隐私模式。"
	L.SETTINGS_PRIVACY_OPTIONS = "隐私选项"
	L.SETTINGS_STREAMER_NAME_FORMAT = "名称值"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC = "选择如何在主播模式中显示名称。"
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "强制使用 BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME = "强制使用昵称"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "强制使用备注"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "使用紫色标题颜色"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"主播模式活跃时将 Battle.net 标题背景改为 Twitch 紫色。"

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "团队"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "启用快捷键"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC = "启用或禁用团队框上的所有自定义鼠标快捷键。"
	L.SETTINGS_RAID_SHORTCUTS_TITLE = "团队快捷键"
	L.SETTINGS_RAID_ACTION_MASS_MOVE = "批量移动"
	L.SETTINGS_RAID_ACTION_TARGET = "标的单位"
	L.SETTINGS_RAID_ACTION_MAIN_TANK = "设置主坦克"
	L.SETTINGS_RAID_ACTION_MAIN_ASSIST = "设置主助理"
	L.SETTINGS_RAID_ACTION_RAID_LEAD = "设置团队领袖"
	L.SETTINGS_RAID_ACTION_PROMOTE = "提升助理"
	L.SETTINGS_RAID_ACTION_DEMOTE = "降级助理"
	L.SETTINGS_RAID_ACTION_KICK = "从队伍中移除"
	L.SETTINGS_RAID_ACTION_INVITE = "邀请加入队伍"
	L.SETTINGS_RAID_MODIFIER_NONE = "否"
	L.SETTINGS_RAID_MODIFIER_SHIFT = "Shift"
	L.SETTINGS_RAID_MODIFIER_CTRL = "Ctrl"
	L.SETTINGS_RAID_MODIFIER_ALT = "Alt"
	L.SETTINGS_RAID_MOUSE_LEFT = "左键点击"
	L.SETTINGS_RAID_MOUSE_RIGHT = "右键点击"
	L.SETTINGS_RAID_MOUSE_MIDDLE = "中键点击"
	L.SETTINGS_RAID_DESC = "配置团队与队伍管理所需的鼠标快捷键。"
	L.SETTINGS_RAID_MODIFIER_LABEL = "修改键："
	L.SETTINGS_RAID_BUTTON_LABEL = "按钮："
	L.SETTINGS_RAID_WARNING = "注意：快捷键是安全操作（仅限非战斗状态）。"
	L.SETTINGS_RAID_ERROR_RESERVED = "此组合已保留。"

	-- ========================================
	-- WHO FRAME SETTINGS
	-- ========================================
	L.SETTINGS_TAB_WHO = "查找"
	L.WHO_SETTINGS_DESC = "配置查找搜索结果的外观和行为。"
	L.WHO_SETTINGS_VISUAL_HEADER = "外观"
	L.WHO_SETTINGS_CLASS_ICONS = "显示职业图标"
	L.WHO_SETTINGS_CLASS_ICONS_DESC = "在玩家名称旁边显示职业图标。"
	L.WHO_SETTINGS_CLASS_COLORS = "职业颜色名称"
	L.WHO_SETTINGS_CLASS_COLORS_DESC = "按职业着色玩家名称。"
	L.WHO_SETTINGS_LEVEL_COLORS = "等级难度颜色"
	L.WHO_SETTINGS_LEVEL_COLORS_DESC = "根据与你等级的相对难度着色等级。"
	L.WHO_SETTINGS_ZEBRA = "交替行背景"
	L.WHO_SETTINGS_ZEBRA_DESC = "显示微妙的交替行背景以提高可读性。"
	L.WHO_SETTINGS_BEHAVIOR_HEADER = "行为"
	L.WHO_SETTINGS_DOUBLE_CLICK = "双击操作"
	L.WHO_DOUBLE_CLICK_WHISPER = "密语"
	L.WHO_DOUBLE_CLICK_INVITE = "邀请加入队伍"
	L.WHO_RESULTS_SHOWING = "显示 %d / %d 位玩家"
	L.WHO_NO_RESULTS = "未找到玩家"
	L.WHO_TOOLTIP_HINT_CLICK = "点击选择"
	L.WHO_TOOLTIP_HINT_DBLCLICK = "双击密语"
	L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE = "双击邀请"
	L.WHO_TOOLTIP_HINT_CTRL_FORMAT = "Ctrl+点击搜索%s"
	L.WHO_TOOLTIP_HINT_ALT_FORMAT = "Alt+点击将%s添加到搜索构建器"
	L.WHO_TOOLTIP_HINT_RIGHTCLICK = "右键查看选项"
	L.WHO_SEARCH_PENDING = "搜索中..."
	L.WHO_SEARCH_TIMEOUT = "无响应，请重试。"

	-- ========================================
	-- WHO SEARCH BUILDER
	-- ========================================
	L.WHO_BUILDER_TITLE = "搜索构建器"
	L.WHO_BUILDER_NAME = "名字"
	L.WHO_BUILDER_GUILD = "公会"
	L.WHO_BUILDER_ZONE = "区域"
	L.WHO_BUILDER_CLASS = "职业"
	L.WHO_BUILDER_RACE = "种族"
	L.WHO_BUILDER_LEVEL = "等级"
	L.WHO_BUILDER_LEVEL_TO = "至"
	L.WHO_BUILDER_ALL_CLASSES = "所有职业"
	L.WHO_BUILDER_ALL_RACES = "所有种族"
	L.WHO_BUILDER_PREVIEW = "预览:"
	L.WHO_BUILDER_PREVIEW_EMPTY = "填写字段以构建搜索"
	L.WHO_BUILDER_SEARCH = "搜索"
	L.WHO_BUILDER_RESET = "重置"
	L.WHO_BUILDER_TOOLTIP = "打开搜索构建器"
	L.WHO_BUILDER_DOCK_TOOLTIP = "停靠搜索构建器"
	L.WHO_BUILDER_UNDOCK_TOOLTIP = "取消停靠搜索构建器"

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "窗口尺寸"
	L.SETTINGS_FRAME_SCALE = "缩放:"
	L.SETTINGS_FRAME_WIDTH = "宽度:"
	L.SETTINGS_FRAME_HEIGHT = "高度:"
	L.SETTINGS_FRAME_WIDTH_DESC = "调整窗口宽度"
	L.SETTINGS_FRAME_HEIGHT_DESC = "调整窗口高度"
	L.SETTINGS_FRAME_SCALE_DESC = "调整窗口缩放"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "群组标题对齐"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC = "设置群组名称文字的对齐方式"
	L.SETTINGS_ALIGN_LEFT = "左对齐"
	L.SETTINGS_ALIGN_CENTER = "居中"
	L.SETTINGS_ALIGN_RIGHT = "右对齐"
	L.SETTINGS_SHOW_GROUP_ARROW = "显示折叠箭头"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC = "显示或隐藏用于折叠群组的箭头图标"
	L.SETTINGS_GROUP_ARROW_ALIGN = "折叠箭头对齐"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC = "设置收起/展开箭头图标的对齐方式"
	L.SETTINGS_FONT_FACE = "字体"
	L.SETTINGS_COLOR_GROUP_COUNT = "群组计数颜色"
	L.SETTINGS_COLOR_GROUP_ARROW = "折叠箭头颜色"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "继承群组颜色"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "继承群组颜色"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "群组标题设置"
	L.SETTINGS_GROUP_FONT_HEADER = "群组标题字体"
	L.SETTINGS_GROUP_COLOR_HEADER = "群组标题颜色"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "右键单击以继承群组"
	L.SETTINGS_INHERIT_TOOLTIP = "（从群组继承）"

	-- Misc
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "全局忽略列表"
	L.IGNORE_LIST_ENHANCEQOL_IGNORE = "EnhanceQoL 忽略列表"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "好友名称设置"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "好友信息设置"
	L.SETTINGS_FONT_TABS_TITLE = "标签文本"
	L.SETTINGS_FONT_RAID_TITLE = "团队名称文本"
	L.SETTINGS_FONT_SIZE_NUM = "字体大小"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "分组备注同步"
	L.SETTINGS_SYNC_GROUPS_NOTE = "将分组同步到好友备注"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"以FriendGroups格式(备注#分组1#分组2)将分组信息写入好友备注。可在账号间或与FriendGroups用户共享分组。"
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"启用分组备注同步？\n\n|cffff8800警告：|r 战网备注限制为127个字符，魔兽世界好友备注限制为48个字符。超出字符限制的分组将在备注中跳过，但仍保存在数据库中。\n\n现有备注将被更新。是否继续？"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "启用"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "取消"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"分组备注同步已禁用。\n\n是否打开备注清理向导，从好友备注中移除分组后缀？"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "打开清理向导"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "保留备注"
	L.MSG_SYNC_GROUPS_STARTED = "正在将分组同步到好友备注..."
	L.MSG_SYNC_GROUPS_COMPLETE = "分组备注同步完成。已更新：%d，已跳过（限制）：%d"
	L.MSG_SYNC_GROUPS_PROGRESS = "同步备注中：%d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT = "%s 的备注已达上限 - 部分分组已跳过"

	-- ========================================
	-- MESSAGES (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.MSG_INVITE_CONVERT_RAID = "正在将队伍转换为团队..."
	L.MSG_INVITE_RAID_FULL = "团队已满(%d/40)。已停止邀请。"

	-- ========================================
	-- SETTINGS (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "显示欢迎消息"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC = "登录时在聊天中显示插件加载的消息。"

	-- ========================================
	-- RAID CONVERSION / MOCK (Phase 21+)
	-- ========================================
	L.RAID_GROUP_NAME = "队伍 %d"
	L.RAID_CONVERT_TO_PARTY = "转换为队伍"
	L.RAID_CONVERT_TO_RAID = "转换为团队"
	L.RAID_MUST_BE_LEADER = "你必须是领导者才能这样做"
	L.RAID_CONVERT_TOO_MANY = "队伍中有太多玩家无法形成队伍"
	L.RAID_ERR_NOT_IN_GROUP = "你不在队伍中"
	L.MOCK_INVITE_ACCEPTED = "接受来自 %s 的模拟邀请"
	L.MOCK_INVITE_DECLINED = "拒绝来自 %s 的模拟邀请"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "备注清理向导"
	L.WIZARD_DESC =
		"从好友备注中移除 FriendGroups 数据（#分组1#分组2）。在应用之前查看清理后的备注。"
	L.WIZARD_BTN = "备注清理"
	L.WIZARD_BTN_TOOLTIP = "打开向导以清理好友备注中的 FriendGroups 数据"
	L.WIZARD_HEADER = "备注清理"
	L.WIZARD_HEADER_DESC =
		"从好友备注中移除 FriendGroups 后缀。先备份您的备注，然后查看并应用更改。"
	L.WIZARD_COL_ACCOUNT = "账号名称"
	L.WIZARD_COL_BATTLETAG = "战网昵称"
	L.WIZARD_COL_NOTE = "当前备注"
	L.WIZARD_COL_CLEANED = "清理后备注"
	L.WIZARD_SEARCH_PLACEHOLDER = "搜索..."
	L.WIZARD_BACKUP_BTN = "备份备注"
	L.WIZARD_BACKUP_DONE = "已备份！"
	L.WIZARD_BACKUP_TOOLTIP = "将所有当前好友备注保存到数据库作为备份。"
	L.WIZARD_BACKUP_SUCCESS = "已备份 %d 位好友的备注。"
	L.WIZARD_APPLY_BTN = "应用清理"
	L.WIZARD_APPLY_TOOLTIP = "将清理后的备注写回。仅更新与原始备注不同的备注。"
	L.WIZARD_APPLY_CONFIRM =
		"将清理后��备注应用到所有好友？\n\n|cffff8800当前备注将被覆盖。��确保您已先创建备份！|r"
	L.WIZARD_APPLY_SUCCESS = "成功更新 %d 条备注。"
	L.WIZARD_APPLY_PROGRESS_FMT = "进度: %d/%d | %d ��功 | %d 失败"
	L.WIZARD_STATUS_FMT = "显示 %d / %d 位好友 | %d 包含分组数据 | %d 待更改"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "查看备份"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"打开备份查看器，查看所有已备份的备注并与当前备注进行对比。"
	L.WIZARD_BACKUP_VIEWER_TITLE = "备注备份查看器"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"查看已备份的好友备注并与当前备注进行比较。如有需要，可以恢复原始备注。"
	L.WIZARD_COL_BACKED_UP = "已备份备注"
	L.WIZARD_COL_CURRENT = "当前备注"
	L.WIZARD_RESTORE_BTN = "恢复备份"
	L.WIZARD_RESTORE_TOOLTIP = "从备份恢复原始备注。仅更新与备份不同的��注。"
	L.WIZARD_RESTORE_CONFIRM = "从备份恢复所有备注？\n\n|cffff8800当前备注将被备份版本覆盖。|r"
	L.WIZARD_RESTORE_SUCCESS = "已成功恢复 %d 条备注。"
	L.WIZARD_NO_BACKUP = "未找到备注备份。请先使用备注清理向导创建备份。"
	L.WIZARD_BACKUP_STATUS_FMT = "显示 %d/%d 条记录 | %d 条自备份后已更改 | 备份时间: %s"
end)
