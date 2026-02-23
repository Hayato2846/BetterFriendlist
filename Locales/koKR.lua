-- Locales/koKR.lua
-- Korean (한국어) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("koKR", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"플레이어 초상화를 비활성화하고 검색/정렬 옵션을 숨기며 프레임을 넓히고 탭을 이동하여 컴팩트 레이아웃을 만듭니다."
	L.MENU_CHANGELOG = "Changelog"
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "새 그룹의 이름을 입력하세요:"
	L.DIALOG_CREATE_GROUP_BTN1 = "생성"
	L.DIALOG_CREATE_GROUP_BTN2 = "취소"
	L.DIALOG_RENAME_GROUP_TEXT = "그룹의 새 이름을 입력하세요:"
	L.DIALOG_RENAME_GROUP_BTN1 = "이름 변경"
	L.DIALOG_RENAME_GROUP_BTN2 = "취소"
	L.DIALOG_RENAME_GROUP_SETTINGS = "그룹 '%s' 이름 변경:"
	L.DIALOG_DELETE_GROUP_TEXT =
		"이 그룹을 삭제하시겠습니까?\n\n|cffff0000이 그룹의 모든 친구가 제거됩니다.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "삭제"
	L.DIALOG_DELETE_GROUP_BTN2 = "취소"
	L.DIALOG_DELETE_GROUP_SETTINGS =
		"'%s' 그룹을 삭제하시겠습니까?\n\n모든 친구가 이 그룹에서 제거됩니다."
	L.DIALOG_RESET_SETTINGS_TEXT = "모든 설정을 기본값으로 재설정하시겠습니까?"
	L.DIALOG_RESET_BTN1 = "재설정"
	L.DIALOG_RESET_BTN2 = "취소"
	L.DIALOG_UI_PANEL_RELOAD_TEXT =
		"UI 계층 구조 설정 변경은 UI 재로드가 필요합니다.\n\n지금 재로드하시겠습니까?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "재로드"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "취소"
	L.MSG_RELOAD_REQUIRED =
		"Classic에서 이 변경 사항을 올바르게 적용하려면 UI를 다시 불러와야 합니다."
	L.MSG_RELOAD_NOW = "지금 UI를 다시 불러오시겠습니까?"
	L.RAID_HELP_TITLE = "공격대 도움말"
	L.RAID_HELP_TEXT = "공격대 명단 사용법에 대한 도움말을 보려면 클릭하세요."
	L.RAID_HELP_MULTISELECT_TITLE = "다중 선택"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Ctrl을 누른 채 왼쪽 클릭으로 여러 플레이어를 선택하세요.\n선택한 후 어떤 그룹으로든 끌어다 놓으면 모두 한번에 이동합니다."
	L.RAID_HELP_MAINTANK_TITLE = "주 방어 탱커"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s - 플레이어를 주 방어 탱커로 설정합니다.\n이름 옆에 탱커 아이콘이 나타납니다."
	L.RAID_HELP_MAINASSIST_TITLE = "주 지원"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s - 플레이어를 주 지원으로 설정합니다.\n이름 옆에 지원 아이콘이 나타납니다."
	L.RAID_HELP_LEAD_TITLE = "공격대장"
	L.RAID_HELP_LEAD_TEXT = "%s - 플레이어를 공격대장으로 승급."
	L.RAID_HELP_PROMOTE_TITLE = "부공격대장"
	L.RAID_HELP_PROMOTE_TEXT = "%s - 플레이어를 부공격대장 승급/강등."
	L.RAID_HELP_DRAGDROP_TITLE = "끌어다 놓기"
	L.RAID_HELP_DRAGDROP_TEXT =
		"플레이어를 끌어 그룹 간에 이동하세요.\n선택한 여러 플레이어를 한번에 끌어다 놓을 수도 있습니다.\n빈 슬롯을 사용하여 위치를 교환할 수 있습니다."
	L.RAID_HELP_COMBAT_TITLE = "전투 잠금"
	L.RAID_HELP_COMBAT_TEXT =
		"전투 중에는 플레이어를 이동할 수 없습니다.\n이는 오류를 방지하기 위한 Blizzard의 제한 사항입니다."
	L.RAID_INFO_UNAVAILABLE = "Raid information unavailable"
	L.RAID_NOT_IN_RAID = "Not in a raid"
	L.RAID_NOT_IN_RAID_DETAILS = "현재 공격대 그룹에 속해 있지 않습니다"
	L.RAID_CREATE_BUTTON = "Create Raid"
	L.GROUP = "그룹"
	L.ALL = "All"
	L.UNKNOWN_ERROR = "알 수 없는 오류"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Not enough space: %d players selected, %d free spots in Group %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Moved %d players to Group %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "%d명의 플레이어 이동 실패"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "You must be leader or assistant to ready check."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "No saved instances."
	L.RAID_ERROR_LOAD_RAID_INFO = "Error: Could not load Raid Info."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s swapped"
	L.RAID_ERROR_SWAP_FAILED = "Swap failed: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s moved to Group %d"
	L.RAID_ERROR_MOVE_FAILED = "Move failed: %s"
	L.DIALOG_MIGRATE_TEXT =
		"FriendGroups에서 BetterFriendlist로 친구 그룹을 마이그레이션하시겠습니까?\n\n다음을 수행합니다:\n• BNet 메모에서 모든 그룹 생성\n• 친구를 그룹에 할당\n• 선택적으로 메모 정리 마법사를 열어 메모를 검토 및 정리\n\n|cffff0000경고: 이 작업은 취소할 수 없습니다!|r"
	L.DIALOG_MIGRATE_BTN1 = "마이그레이션 및 메모 검토"
	L.DIALOG_MIGRATE_BTN2 = "마이그레이션만"
	L.DIALOG_MIGRATE_BTN3 = "취소"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_FONTS = "글꼴"
	L.SETTINGS_TAB_GENERAL = "일반"
	L.SETTINGS_TAB_GROUPS = "그룹"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "그룹 색상 상속"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "그룹 색상 상속"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "그룹에서 상속하려면 오른쪽 클릭"
	L.SETTINGS_INHERIT_TOOLTIP = "(그룹에서 상속됨)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "외형"
	L.SETTINGS_TAB_ADVANCED = "고급"
	L.SETTINGS_ADVANCED_DESC = "Advanced options and tools."
	L.SETTINGS_TAB_STATISTICS = "통계"
	L.SETTINGS_SHOW_BLIZZARD = "블리자드 친구 목록 옵션 표시"
	L.SETTINGS_COMPACT_MODE = "압축 모드"
	L.SETTINGS_LOCK_WINDOW = "창 잠금"
	L.SETTINGS_LOCK_WINDOW_DESC = "실수로 이동하는 것을 방지하기 위해 창을 잠급니다."
	L.SETTINGS_FONT_SIZE = "글꼴 크기"
	L.SETTINGS_FONT_COLOR = "글꼴 색상"
	L.SETTINGS_FONT_SIZE_SMALL = "작게 (압축, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "보통 (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "크게 (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "직업 이름 색상"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "빈 그룹 숨기기"
	L.SETTINGS_HEADER_COUNT_FORMAT = "그룹 헤더 카운트"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "그룹 헤더에 친구 수를 표시하는 방법을 선택하세요"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "필터링됨 / 전체 (기본값)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "온라인 / 전체"
	L.SETTINGS_HEADER_COUNT_BOTH = "필터링됨 / 온라인 / 전체"
	L.SETTINGS_SHOW_FACTION_ICONS = "진영 아이콘 표시"
	L.SETTINGS_SHOW_REALM_NAME = "서버 이름 표시"
	L.SETTINGS_GRAY_OTHER_FACTION = "다른 진영 흐리게"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "모바일을 자리 비움으로 표시"
	L.SETTINGS_SHOW_MOBILE_TEXT = "모바일 텍스트 표시"
	L.SETTINGS_HIDE_MAX_LEVEL = "최대 레벨 숨기기"
	L.SETTINGS_ACCORDION_GROUPS = "아코디언 그룹 (한 번에 하나만 열림)"
	L.SETTINGS_SHOW_FAVORITES = "즐겨찾기 그룹 표시"
	L.SETTINGS_SHOW_GROUP_FMT = "%s 그룹 표시"
	L.SETTINGS_SHOW_GROUP_DESC_FMT = "친구 목록에서 %s 그룹 표시 여부"
	L.SETTINGS_GROUP_COLOR = "그룹 색상"
	L.SETTINGS_RENAME_GROUP = "그룹 이름 변경"
	L.SETTINGS_DELETE_GROUP = "그룹 삭제"
	L.SETTINGS_DELETE_GROUP_DESC = "이 그룹을 삭제하고 모든 친구 할당 해제"
	L.SETTINGS_EXPORT_TITLE = "설정 내보내기"
	L.SETTINGS_EXPORT_INFO =
		"아래 텍스트를 복사하여 저장하세요. 다른 캐릭터나 계정으로 가져올 수 있습니다."
	L.SETTINGS_EXPORT_BTN = "모두 선택"
	L.BUTTON_EXPORT = "내보내기"
	L.SETTINGS_IMPORT_TITLE = "설정 가져오기"
	L.SETTINGS_IMPORT_INFO =
		"내보내기 문자열을 아래에 붙여넣고 가져오기를 클릭하세요.\n\n|cffff0000경고: 모든 그룹과 할당이 대체됩니다!|r"
	L.SETTINGS_IMPORT_BTN = "가져오기"
	L.SETTINGS_IMPORT_CANCEL = "취소"
	L.SETTINGS_RESET_DEFAULT = "기본값으로 재설정"
	L.SETTINGS_RESET_SUCCESS = "설정이 기본값으로 재설정되었습니다!"
	L.SETTINGS_GROUP_ORDER_SAVED = "그룹 순서가 저장되었습니다!"
	L.SETTINGS_MIGRATION_COMPLETE = "마이그레이션 완료!"
	L.SETTINGS_MIGRATION_FRIENDS = "처리된 친구:"
	L.SETTINGS_MIGRATION_GROUPS = "생성된 그룹:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "생성된 할당:"
	L.SETTINGS_NOTES_CLEANED = "메모가 정리되었습니다!"
	L.SETTINGS_NOTES_PRESERVED = "메모가 보존되었습니다 (수동으로 정리할 수 있습니다)."
	L.SETTINGS_EXPORT_SUCCESS = "내보내기 완료! 대화 상자에서 텍스트를 복사하세요."
	L.SETTINGS_IMPORT_SUCCESS = "가져오기 성공! 모든 그룹과 할당이 복원되었습니다."
	L.SETTINGS_IMPORT_FAILED = "가져오기 실패!\n\n"
	L.STATS_TOTAL_FRIENDS = "총 친구: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00온라인: %d|r  |  |cff808080오프라인: %d|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "친구 요청 (%d)"
	L.INVITE_BUTTON_ACCEPT = "수락"
	L.INVITE_BUTTON_DECLINE = "거절"
	L.INVITE_TAP_TEXT = "탭하여 수락 또는 거절"
	L.INVITE_MENU_DECLINE = "거절"
	L.INVITE_MENU_REPORT = "플레이어 신고"
	L.INVITE_MENU_BLOCK = "초대 차단"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "모든 친구"
	L.FILTER_ONLINE_ONLY = "온라인만"
	L.FILTER_OFFLINE_ONLY = "오프라인만"
	L.FILTER_WOW_ONLY = "WoW만"
	L.FILTER_BNET_ONLY = "Battle.net만"
	L.FILTER_HIDE_AFK = "자리 비움/방해 금지 숨기기"
	L.FILTER_RETAIL_ONLY = "리테일만"
	L.FILTER_TOOLTIP = "빠른 필터: %s"
	L.SORT_STATUS = "상태"
	L.SORT_NAME = "이름 (가-하)"
	L.SORT_LEVEL = "레벨"
	L.SORT_ZONE = "지역"
	L.SORT_GAME = "게임"
	L.SORT_FACTION = "진영"
	L.SORT_GUILD = "길드"
	L.SORT_CLASS = "직업"
	L.SORT_REALM = "서버"
	L.SORT_CHANGED = "정렬 변경: %s"
	L.SORT_NONE = "None"
	L.SORT_PRIMARY_LABEL = "Primary Sort"
	L.SORT_SECONDARY_LABEL = "Secondary Sort"
	L.SORT_PRIMARY_DESC = "친구 목록을 어떻게 정렬할지 선택하세요."
	L.SORT_SECONDARY_DESC = "기본 값이 같을 때 이 기준으로 정렬합니다."

	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "그룹"
	L.MENU_CREATE_GROUP = "그룹 생성"
	L.MENU_REMOVE_ALL_GROUPS = "모든 그룹에서 제거"
	L.MENU_RENAME_GROUP = "그룹 이름 변경"
	L.MENU_DELETE_GROUP = "그룹 삭제"
	L.MENU_INVITE_GROUP = "모두 그룹에 초대"
	L.MENU_COLLAPSE_ALL = "모든 그룹 접기"
	L.MENU_EXPAND_ALL = "모든 그룹 펼치기"
	L.MENU_SETTINGS = "설정"
	L.MENU_SET_BROADCAST = "방송 메시지 설정"
	L.MENU_IGNORE_LIST = "차단 목록 관리"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "More Groups..."
	L.MENU_SWITCH_GAME_ACCOUNT = "게임 계정 전환"
	L.MENU_DEFAULT_FOCUS = "기본값 (Blizzard)"
	L.GROUPS_DIALOG_TITLE = "Groups for %s"
	L.MENU_COPY_CHARACTER_NAME = "캐릭터 이름 복사"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "캐릭터 이름 복사"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "놓아서 그룹에 추가"
	L.TOOLTIP_HOLD_SHIFT = "다른 그룹에 유지하려면 Shift를 누르세요"
	L.TOOLTIP_DRAG_HERE = "친구를 여기로 드래그하여 추가"
	L.TOOLTIP_ERROR = "오류"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "사용 가능한 게임 계정 없음"
	L.TOOLTIP_NO_INFO = "사용 가능한 정보 부족"
	L.TOOLTIP_RENAME_GROUP = "그룹 이름 변경"
	L.TOOLTIP_RENAME_DESC = "클릭하여 이 그룹 이름 변경"
	L.TOOLTIP_GROUP_COLOR = "그룹 색상"
	L.TOOLTIP_GROUP_COLOR_DESC = "클릭하여 이 그룹의 색상 변경"
	L.TOOLTIP_DELETE_GROUP = "그룹 삭제"
	L.TOOLTIP_DELETE_DESC = "이 그룹을 삭제하고 모든 친구 할당 해제"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d명의 친구를 그룹에 초대했습니다."
	L.MSG_NO_FRIENDS_AVAILABLE = "초대할 수 있는 온라인 친구가 없습니다."
	L.MSG_GROUP_DELETED = "'%s' 그룹이 삭제되었습니다"
	L.MSG_IGNORE_LIST_EMPTY = "차단 목록이 비어 있습니다."
	L.MSG_IGNORE_LIST_COUNT = "차단 목록 (%d명):"
	L.MSG_MIGRATION_ALREADY_DONE =
		"마이그레이션이 이미 완료되었습니다. 다시 실행하려면 '/bfl migrate force'를 사용하세요."
	L.MSG_MIGRATION_STARTING = "FriendGroups에서 마이그레이션 시작 중..."
	L.MSG_GROUP_ORDER_SAVED = "그룹 순서가 저장되었습니다!"
	L.MSG_SETTINGS_RESET = "설정이 기본값으로 재설정되었습니다!"
	L.MSG_EXPORT_FAILED = "내보내기 실패: %s"
	L.MSG_IMPORT_SUCCESS = "가져오기 성공! 모든 그룹과 할당이 복원되었습니다."
	L.MSG_IMPORT_FAILED = "가져오기 실패: %s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "데이터베이스를 사용할 수 없습니다!"
	L.ERROR_SETTINGS_NOT_INIT = "프레임이 초기화되지 않았습니다!"
	L.ERROR_MODULES_NOT_LOADED = "모듈을 사용할 수 없습니다!"
	L.ERROR_GROUPS_MODULE = "그룹 모듈을 사용할 수 없습니다!"
	L.ERROR_SETTINGS_MODULE = "설정 모듈을 사용할 수 없습니다!"
	L.ERROR_FRIENDSLIST_MODULE = "친구 목록 모듈을 사용할 수 없습니다"
	L.ERROR_FAILED_DELETE_GROUP = "그룹 삭제 실패 - 모듈이 로드되지 않음"
	L.ERROR_FAILED_DELETE = "그룹 삭제 실패: %s"
	L.ERROR_MIGRATION_FAILED = "마이그레이션 실패 - 모듈이 로드되지 않음!"
	L.ERROR_GROUP_NAME_EMPTY = "그룹 이름은 비워둘 수 없습니다"
	L.ERROR_GROUP_EXISTS = "그룹이 이미 존재합니다"
	L.ERROR_INVALID_GROUP_NAME = "잘못된 그룹 이름"
	L.ERROR_GROUP_NOT_EXIST = "그룹이 존재하지 않습니다"
	L.ERROR_CANNOT_RENAME_BUILTIN = "기본 그룹의 이름을 변경할 수 없습니다"
	L.ERROR_INVALID_GROUP_ID = "잘못된 그룹 ID"
	L.ERROR_CANNOT_DELETE_BUILTIN = "기본 그룹을 삭제할 수 없습니다"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "친구"
	L.GROUP_FAVORITES = "즐겨찾기"
	L.GROUP_INGAME = "In Game"
	L.GROUP_NO_GROUP = "그룹 없음"
	L.ONLINE_STATUS = "온라인"
	L.OFFLINE_STATUS = "오프라인"
	L.STATUS_MOBILE = "모바일"
	L.STATUS_IN_APP = "In App"
	L.UNKNOWN_GAME = "알 수 없는 게임"
	L.BUTTON_ADD_FRIEND = "친구 추가"
	L.BUTTON_SEND_MESSAGE = "메시지 보내기"
	L.EMPTY_TEXT = "비어 있음"
	L.LEVEL_FORMAT = "레벨 %d"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "베타 기능"
	L.SETTINGS_BETA_FEATURES_DESC = "실험적 기능 활성화"
	L.SETTINGS_BETA_FEATURES_ENABLE = "베타 기능 활성화"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "실험적 기능 활성화 (알림 등)"
	L.SETTINGS_BETA_FEATURES_WARNING =
		"경고: 베타 기능에는 버그, 성능 문제 또는 불완전한 기능이 포함될 수 있습니다. 본인의 책임하에 사용하십시오."
	L.SETTINGS_BETA_FEATURES_LIST = "현재 사용 가능한 베타 기능:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "베타 기능 |cff00ff00활성화됨|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "베타 기능 |cffff0000비활성화됨|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "베타 탭이 설정에 표시됩니다"
	L.SETTINGS_BETA_TABS_HIDDEN = "베타 탭이 숨겨졌습니다"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "전역 친구 동기화 활성화"
	L.SETTINGS_GLOBAL_SYNC_DESC = "모든 캐릭터 간 설정 동기화"
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "전역 친구 동기화"
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
	L.SETTINGS_FRAME_SIZE_HEADER = "기본 프레임 크기 (편집 모드)"
	L.SETTINGS_FRAME_SIZE_INFO =
		"새로운 편집 모드 레이아웃을 위한 선호 기본 크기를 설정하세요."
	L.SETTINGS_FRAME_WIDTH = "너비:"
	L.SETTINGS_FRAME_HEIGHT = "높이:"
	L.SETTINGS_FRAME_RESET_SIZE = "415x570으로 재설정"
	L.SETTINGS_FRAME_APPLY_NOW = "현재 레이아웃에 적용"
	L.SETTINGS_FRAME_RESET_ALL = "모든 레이아웃 재설정"

	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "친구"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "좌클릭: BetterFriendlist 토글"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "우클릭: 설정"
	L.BROKER_SETTINGS_ENABLE = "데이터 브로커 활성화"
	L.BROKER_SETTINGS_SHOW_ICON = "아이콘 표시"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Tooltip Detail Level"
	L.BROKER_SETTINGS_CLICK_ACTION = "Left Click Action"
	L.BROKER_SETTINGS_LEFT_CLICK = "좌클릭 동작"
	L.BROKER_SETTINGS_RIGHT_CLICK = "우클릭 동작"
	L.BROKER_ACTION_TOGGLE = "BetterFriendlist 전환"
	L.BROKER_ACTION_FRIENDS = "친구 목록 열기"
	L.BROKER_ACTION_SETTINGS = "설정 열기"
	L.BROKER_ACTION_OPEN_BNET = "Open BNet App"
	L.BROKER_ACTION_NONE = "None"
	L.BROKER_SETTINGS_INFO =
		"BetterFriendlist는 Bazooka, ChocolateBar, TitanPanel과 같은 데이터 브로커 표시 애드온과 통합됩니다. 이 기능을 활성화하여 표시 애드온에서 친구 수와 빠른 액세스를 표시하세요."
	L.BROKER_FILTER_CHANGED = "필터 변경: %s"

	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "WoW 친구"
	L.BROKER_HEADER_BNET = "Battle.Net 친구"
	L.BROKER_NO_WOW_ONLINE = "  온라인 WoW 친구 없음"
	L.BROKER_NO_FRIENDS_ONLINE = "온라인 친구 없음"
	L.BROKER_TOTAL_ONLINE = "총: %d 온라인 / %d 친구"
	L.BROKER_FILTER_LABEL = "필터: "
	L.BROKER_SORT_LABEL = "정렬: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- 친구 줄 동작 ---"
	L.BROKER_HINT_CLICK_WHISPER = "친구 클릭:"
	L.BROKER_HINT_WHISPER = " 귓속말 • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "우클릭:"
	L.BROKER_HINT_CONTEXT_MENU = " 상황별 메뉴"
	L.BROKER_HINT_ALT_CLICK = "Alt+클릭:"
	L.BROKER_HINT_INVITE = " 초대/참가 • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+클릭:"
	L.BROKER_HINT_COPY = " 채팅에 복사"
	L.BROKER_HINT_ICON_ACTIONS = "--- 브로커 아이콘 동작 ---"
	L.BROKER_HINT_LEFT_CLICK = "좌클릭:"
	L.BROKER_HINT_TOGGLE = " BetterFriendlist 토글"
	L.BROKER_HINT_RIGHT_CLICK = "우클릭:"
	L.BROKER_HINT_SETTINGS = " 설정 • "
	L.BROKER_HINT_MIDDLE_CLICK = "가운데 클릭:"
	L.BROKER_HINT_CYCLE_FILTER = " 필터 순환"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: 모바일 사용자를 오프라인으로 표시
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "모바일 사용자를 오프라인으로 표시"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "모바일 앱을 사용하는 친구를 오프라인 그룹에 표시"

	-- Feature 3: 메모를 이름으로 표시
	L.SETTINGS_SHOW_NOTES_AS_NAME = "메모를 친구 이름으로 표시"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "사용 가능한 경우 친구 메모를 이름으로 표시"

	-- Feature 4: 창 크기 조절
	L.SETTINGS_WINDOW_SCALE = "창 크기 조절"
	L.SETTINGS_WINDOW_SCALE_DESC = "전체 창 크기 조절 (50%% - 200%%)"

	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "레이블 표시"
	L.BROKER_SETTINGS_SHOW_TOTAL = "총 수 표시"
	L.BROKER_SETTINGS_SHOW_GROUPS = "WoW 및 BNet 친구 수 분리"
	L.BROKER_SETTINGS_HEADER_GENERAL = "일반 설정"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "데이터 브로커 통합"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "상호작용"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "사용 방법"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "테스트된 표시 애드온"
	L.BROKER_SETTINGS_INSTRUCTIONS =
		"• 데이터 브로커 표시 애드온 설치(Bazooka, ChocolateBar 또는 TitanPanel)\n• 위의 데이터 브로커 활성화(UI 다시 로드 안내됨)\n• BetterFriendlist 버튼이 표시 애드온에 나타남\n• 호버로 도구 설명 표시, 좌클릭으로 열기, 우클릭으로 설정, 가운데 클릭으로 필터 순환"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "도구 설명 열"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "도구 설명 열"
	L.BROKER_COLUMN_NAME = "Name"
	L.BROKER_COLUMN_LEVEL = "레벨"
	L.BROKER_COLUMN_CHARACTER = "캐릭터"
	L.BROKER_COLUMN_GAME = "게임 / 앱"
	L.BROKER_COLUMN_ZONE = "Zone"
	L.BROKER_COLUMN_REALM = "서버"
	L.BROKER_COLUMN_FACTION = "진영"
	L.BROKER_COLUMN_NOTES = "메모"

	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "친구 이름 표시 (RealID 또는 캐릭터명)"
	L.BROKER_COLUMN_LEVEL_DESC = "캐릭터 레벨 표시"
	L.BROKER_COLUMN_CHARACTER_DESC = "캐릭터 이름과 직업 아이콘 표시"
	L.BROKER_COLUMN_GAME_DESC = "친구가 플레이 중인 게임 또는 앱 표시"
	L.BROKER_COLUMN_ZONE_DESC = "친구가 위치한 지역 표시"
	L.BROKER_COLUMN_REALM_DESC = "캐릭터의 서버 표시"
	L.BROKER_COLUMN_FACTION_DESC = "진영 아이콘 표시 (얼라이언스/호드)"
	L.BROKER_COLUMN_NOTES_DESC = "친구 메모 표시"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "최근 동맹은 Classic에서 사용할 수 없습니다"
	L.EDIT_MODE_NOT_AVAILABLE = "편집 모드는 Classic에서 사용할 수 없습니다"
	L.CLASSIC_COMPATIBILITY_INFO = "Classic 호환 모드로 실행 중"
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "이 기능은 Classic에서 사용할 수 없습니다"
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "길드 열 때 BetterFriendlist 닫기"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "길드 탭을 클릭할 때 BetterFriendlist를 자동으로 닫습니다"
	L.SETTINGS_HIDE_GUILD_TAB = "길드 탭 숨기기"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "친구 목록에서 길드 탭을 숨깁니다"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "UI 계층 구조 준수"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC =
		"BetterFriendlist가 다른 UI 창(캐릭터, 주문서 등) 위에 열리지 않도록 합니다. /reload 필요."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1분"
	L.LASTONLINE_MINUTES = "%d분"
	L.LASTONLINE_HOURS = "%d시간"
	L.LASTONLINE_DAYS = "%d일"
	L.LASTONLINE_MONTHS = "%d개월"
	L.LASTONLINE_YEARS = "%d년"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "클래식 길드 UI 비활성화됨"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist는 Blizzard의 최신 길드 UI만 BetterFriendlist와 호환되므로 클래식 길드 UI 설정을 비활성화했습니다.\n\n길드 탭은 이제 Blizzard의 최신 길드 UI를 엽니다."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Use '/bfl migrate help' for help."
	L.LOADED_MESSAGE = "BetterFriendlist loaded."
	L.DEBUG_ENABLED = "Debug ENABLED"
	L.DEBUG_DISABLED = "Debug DISABLED"
	L.CONFIG_RESET = "Config reset."
	L.SEARCH_PLACEHOLDER = "친구 검색..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "길드"
	L.TAB_RAID = "Raid"
	L.TAB_QUICK_JOIN = "Quick Join"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Online"
	L.FILTER_SEARCH_OFFLINE = "Offline"
	L.FILTER_SEARCH_MOBILE = "모바일"
	L.FILTER_SEARCH_AFK = "자리 비움"
	L.FILTER_SEARCH_DND = "다른 용무 중"

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
	L.LEADER_LABEL = "리더:"
	L.MEMBERS_LABEL = "멤버:"
	L.AVAILABLE_ROLES = "사용 가능한 역할"
	L.NO_AVAILABLE_ROLES = "No roles"
	L.AUTO_ACCEPT_TOOLTIP = "Auto Accept"
	L.MOCK_JOIN_REQUEST_SENT = "Mock Request Sent"
	L.QUICK_JOIN_NO_GROUPS = "No groups"
	L.UNKNOWN_GROUP = "알 수 없는 그룹"
	L.UNKNOWN = "알 수 없음"
	L.NO_QUEUE = "대기열 없음"
	L.LFG_ACTIVITY = "던전 찾기 활동"
	L.ACTIVITY_DUNGEON = "던전"
	L.ACTIVITY_RAID = "공격대"
	L.ACTIVITY_PVP = "PvP"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "설정 가져오기"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "설정 내보내기"
	L.DIALOG_DELETE_GROUP_TITLE = "Delete Group"
	L.DIALOG_RENAME_GROUP_TITLE = "Rename Group"
	L.DIALOG_CREATE_GROUP_TITLE = "Create Group"

	-- Tooltips
	L.TOOLTIP_LAST_ONLINE = "마지막 온라인: %s"

	-- Notifications
	L.YES = "YES"
	L.NO = "NO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "미리보기 %d"
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
	L.DIALOG_TRIGGER_CREATE = "생성"
	L.DIALOG_TRIGGER_CANCEL = "취소"
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
	L.BROKER_SETTINGS_RELOAD_CANCEL = "취소"
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
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "WoW 아이콘 표시"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "WoW Friends Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "BNet Icon"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "BNet 아이콘 표시"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "BNet Friends Icon"
	L.STATUS_ENABLED = "|cff00ff00Enabled|r"
	L.STATUS_DISABLED = "|cffff0000비활성화됨|r"
	L.BROKER_WOW_FRIENDS = "WoW 친구:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Global Sync"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Enable Friend Sync"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "삭제됨 표시"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "삭제된 친구 표시"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Show deleted in list"
	L.TOOLTIP_RESTORE_FRIEND = "Restore"
	L.TOOLTIP_DELETE_FRIEND = "Delete"
	L.POPUP_EDIT_NOTE_TITLE = "메모 편집"
	L.BUTTON_SAVE = "저장"
	L.BUTTON_CANCEL = "취소"

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "친구: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d tot"
	L.BROKER_CURRENT_FILTER = "Filter:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "가운데 클릭: 필터 순환"
	L.BROKER_AND_MORE = "  ... and %d others"
	L.BROKER_TOTAL_LABEL = "총:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d friends"
	L.MENU_CHANGE_COLOR = "색상 변경"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Tooltip Error|r"
	L.STATUS_LABEL = "상태:"
	L.STATUS_AWAY = "자리 비움"
	L.STATUS_DND_FULL = "Do Not Disturb"
	L.GAME_LABEL = "게임:"
	L.REALM_LABEL = "서버:"
	L.CLASS_LABEL = "직업:"
	L.FACTION_LABEL = "진영:"
	L.ZONE_LABEL = "지역:"
	L.NOTE_LABEL = "메모:"
	L.BROADCAST_LABEL = "Msg:"
	L.ACTIVE_SINCE_FMT = "활성화: %s"
	L.HINT_RIGHT_CLICK_OPTIONS = "Right-Click Options"
	L.HEADER_ADD_FRIEND = "|cffffd700%s을(를) %s에 추가|r"

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
	L.RECENT_ALLIES_INVITE = "초대"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Player offline"
	L.RECENT_ALLIES_PIN_EXPIRES = "핀 %s 후 만료"
	L.RECENT_ALLIES_LEVEL_RACE = "Lvl %d %s"
	L.RECENT_ALLIES_NOTE = "Note: %s"
	L.RECENT_ALLIES_ACTIVITY = "최근 활동:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "친구 초대"
	L.RAF_RECRUITMENT = "친구 초대"
	L.RAF_NO_RECRUITS_DESC = "No recruits."
	L.RAF_PENDING_RECRUIT = "Pending"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Earned:"
	L.RAF_NEXT_REWARD_AFTER = "Next in %d/%d months"
	L.RAF_FIRST_REWARD = "First:"
	L.RAF_NEXT_REWARD = "Next:"
	L.RAF_REWARD_MOUNT = "Mount"
	L.RAF_REWARD_TITLE_DEFAULT = "칭호"
	L.RAF_REWARD_TITLE_FMT = "Title: %s"
	L.RAF_REWARD_GAMETIME = "Game Time"
	L.RAF_MONTH_COUNT = "%d Months"
	L.RAF_CLAIM_REWARD = "Claim"
	L.RAF_VIEW_ALL_REWARDS = "View All"
	L.RAF_ACTIVE_RECRUIT = "활성"
	L.RAF_TRIAL_RECRUIT = "체험판"
	L.RAF_INACTIVE_RECRUIT = "비활성"
	L.RAF_OFFLINE = "Offline"
	L.RAF_TOOLTIP_DESC = "최대 %d개월"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d months"
	L.RAF_ACTIVITY_DESCRIPTION = "Activity for %s"
	L.RAF_REWARDS_LABEL = "Rewards"
	L.RAF_YOU_EARNED_LABEL = "Earned:"
	L.RAF_CLICK_TO_CLAIM = "Click to claim"
	L.RAF_LOADING = "로딩 중..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== RAF ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Current"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Legacy v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Months: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  신병: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Rewards Avail:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[수령함]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Claimable]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[구매 가능]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[잠김]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d개월)"
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
	L.STATS_TOP_REALMS = "\n상위 서버:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\n기타: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Notes: %d (%d%%)\nFavorites: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max: %d\n70-79: %d\n60-69: %d\n<60: %d\nAvg: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Active: %d (%d%%)|r\n|cffffd700Med: %d (%d%%)|r\n|cffffaa00Old: %d (%d%%)|r\n|cffff6600Stale: %d (%d%%)|r\n|cffff0000Inactive: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ff얼라이언스: %d|r\n|cffff0000호드: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "아래로 이동"
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
	L.MENU_SET_NICKNAME = "별명 설정"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "BetterFriendlist 설정"
	L.SEARCH_FRIENDS_INSTRUCTION = "Search..."
	L.SEARCH_RECENT_ALLIES_INSTRUCTION = "Search recent allies..."
	L.SEARCH_RAF_INSTRUCTION = "Search recruited friends..."
	L.RAF_NEXT_REWARD_HELP = "RAF Info"
	L.WHO_LEVEL_FORMAT = "Level %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "최근 동맹"
	L.CONTACTS_MENU_NAME = "연락처 메뉴"
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
		"토큰을 사용하여 표시를 사용자 정의하세요:\n|cffFFD100%name%|r - 계정 이름\n|cffFFD100%battletag%|r - 배틀태그\n|cffFFD100%nickname%|r - 별명\n|cffFFD100%note%|r - 메모\n|cffFFD100%character%|r - 캐릭터 이름\n|cffFFD100%realm%|r - 서버 이름\n|cffFFD100%level%|r - 레벨\n|cffFFD100%zone%|r - 지역\n|cffFFD100%class%|r - 직업\n|cffFFD100%game%|r - 게임"
	L.SETTINGS_NAME_FORMAT_LABEL = "프리셋:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Name Format"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Enter format."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"이 설정은 'FriendListColors' 애드온이 이름 색상/형식을 관리하고 있어서 비활성화되었습니다."

	-- Name Format Preset Labels (Phase 22)
	L.NAME_PRESET_DEFAULT = "이름 (캐릭터)"
	L.NAME_PRESET_BATTLETAG = "배틀태그 (캐릭터)"
	L.NAME_PRESET_NICKNAME = "별명 (캐릭터)"
	L.NAME_PRESET_NAME_ONLY = "이름만"
	L.NAME_PRESET_CHARACTER = "캐릭터만"
	L.NAME_PRESET_CUSTOM = "사용자 정의..."
	L.SETTINGS_NAME_FORMAT_CUSTOM_LABEL = "사용자 정의 형식:"

	-- Info Format Section (Phase 22)
	L.SETTINGS_INFO_FORMAT_HEADER = "친구 정보 형식"
	L.SETTINGS_INFO_FORMAT_LABEL = "프리셋:"
	L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL = "사용자 정의 형식:"
	L.SETTINGS_INFO_FORMAT_TOOLTIP = "Custom Info Format"
	L.SETTINGS_INFO_FORMAT_DESC =
		"토큰을 사용하여 정보 줄을 사용자 정의하세요:\n|cffFFD100%level%|r - 캐릭터 레벨\n|cffFFD100%zone%|r - 현재 지역\n|cffFFD100%class%|r - 직업 이름\n|cffFFD100%game%|r - 게임 이름\n|cffFFD100%realm%|r - 서버 이름\n|cffFFD100%status%|r - AFK/DND/온라인\n|cffFFD100%lastonline%|r - 마지막 접속\n|cffFFD100%name%|r - 계정 이름\n|cffFFD100%battletag%|r - 배틀태그\n|cffFFD100%nickname%|r - 별명\n|cffFFD100%note%|r - 메모\n|cffFFD100%character%|r - 캐릭터 이름"
	L.INFO_PRESET_DEFAULT = "Default (Level, Zone)"
	L.INFO_PRESET_ZONE = "Zone Only"
	L.INFO_PRESET_LEVEL = "Level Only"
	L.INFO_PRESET_CLASS_ZONE = "Class, Zone"
	L.INFO_PRESET_LEVEL_CLASS_ZONE = "Level Class, Zone"
	L.INFO_PRESET_GAME = "Game Name"
	L.INFO_PRESET_DISABLED = "Disabled (Hide Info)"
	L.INFO_PRESET_CUSTOM = "Custom..."

	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "'In Game' Group"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Group in-game friends"
	L.SETTINGS_INGAME_MODE_WOW = "WoW Only"
	L.SETTINGS_INGAME_MODE_ANY = "Any Game"
	L.SETTINGS_INGAME_MODE_LABEL = "   모드:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Mode"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Choose friends."

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Display Options"
	L.SETTINGS_BEHAVIOR_HEADER = "Behavior"
	L.SETTINGS_GROUP_MANAGEMENT = "Group Management"
	L.SETTINGS_FONT_SETTINGS = "Font"
	L.SETTINGS_GROUP_ORDER = "그룹 순서"
	L.SETTINGS_MIGRATION_HEADER = "FriendGroups Migration"
	L.SETTINGS_MIGRATION_DESC = "Migrate from FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migrate"
	L.SETTINGS_MIGRATE_TOOLTIP = "Import"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "설정을 문자열로 내보내기"
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
	L.SETTINGS_SHOW_BLIZZARD_DESC = "블리자드 버튼 표시"
	L.SETTINGS_SHOW_FAVORITES_DESC = "즐겨찾기 표시"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "한 번에 하나만 열기"
	L.SETTINGS_COMPACT_MODE_DESC = "압축"

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
	L.CORE_FLAVOR_RETAIL = "  |cffffffff정식 버전|r"
	L.CORE_FEATURE_AVAILABILITY = "|cffffcc00Avail:|r"
	L.CORE_FEATURE_MODERN_SCROLLBOX = "  ScrollBox: %s"
	L.CORE_FEATURE_MODERN_MENU = "  Menu Mod: %s"
	L.CORE_FEATURE_RECENT_ALLIES = "  Allies Rec: %s"
	L.CORE_FEATURE_EDIT_MODE = "  편집 모드: %s"
	L.CORE_FEATURE_MODERN_DROPDOWN = "  Dropdown: %s"
	L.CORE_FEATURE_MODERN_COLORPICKER = "  ColorPicker: %s"
	L.CORE_COMPAT_LAYER = "|cffffcc00Compat:|r %s"
	L.CORE_COMPAT_ACTIVE = "Classic 호환 모드 활성"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000로드되지 않음|r"
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
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - 창 위치 초기화"
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
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. 로드됨. Discord: /bfl discord"
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
	L.RAID_MEMBERS_STATUS = "  멤버: %d"
	L.RAID_TOTAL_MEMBERS = "  Tot: %d"
	L.RAID_COMPOSITION = "공격대 구성"
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
	L.CHANGELOG_GITHUB = "   GitHub 이슈"
	L.CHANGELOG_SUPPORT = "   지원"
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
	L.PERF_FPS_60 = "  ✓ <16.6ms = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3ms = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Warning"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "모바일"
	L.RAF_RECRUITMENT = "친구 초대"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "직업 이름을 직업 색상으로 표시"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "글꼴 윤곽"
	L.SETTINGS_FONT_SHADOW = "글꼴 그림자"
	L.SETTINGS_FONT_OUTLINE_NONE = "없음"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "윤곽"
	L.SETTINGS_FONT_OUTLINE_THICK = "두꺼운 윤곽"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "단색"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "메모 편집"
	L.MENU_SHOW_SEARCH = "검색 표시"
	L.MENU_QUICK_FILTER = "빠른 필터"

	-- Multi-Game-Account
	L.MENU_INVITE_CHARACTER = "캐릭터 초대..."
	L.INVITE_ACCOUNT_PICKER_TITLE = "캐릭터 초대"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "즐겨찾기 아이콘 사용"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "즐겨찾기 친구 버튼에 별 아이콘을 표시합니다."
	L.SETTINGS_FAVORITE_ICON_STYLE = "즐겨찾기 아이콘"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC = "즐겨찾기에 사용할 아이콘을 선택합니다."
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "BFL 아이콘"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "블리자드 아이콘"
	L.SETTINGS_SHOW_FACTION_BG = "진영 배경 표시"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "친구 버튼의 배경으로 진영 색상을 표시합니다."

	-- Multi-Game-Account Settings
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "멀티 계정 배지 표시"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC =
		"여러 게임 계정이 온라인인 친구에게 배지를 표시합니다."
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "멀티 계정 정보 표시"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC =
		"친구가 여러 계정에 접속 중일 때 온라인 캐릭터 목록을 짧게 추가합니다."
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS = "툴팁: 최대 게임 계정 수"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS_DESC = "툴팁에 표시되는 추가 게임 계정의 최대 수입니다."
	L.INFO_MULTI_ACCOUNT_PREFIX = "x%d Accounts"
	L.INFO_MULTI_ACCOUNT_REMAINDER = " (+%d)"

	-- ========================================
	-- STREAMER MODE (Phase 24)
	-- ========================================
	L.STREAMER_MODE_TITLE = "스트리머 모드"
	L.STREAMER_MODE_DESC = "스트리밍 또는 녹화를 위한 개인정보 보호 옵션."
	L.SETTINGS_ENABLE_STREAMER_MODE = "스트리머 모드 버튼 표시"
	L.STREAMER_MODE_ENABLE_DESC = "메인 프레임에 스트리머 모드를 토글하는 버튼을 표시합니다."
	L.STREAMER_MODE_HIDDEN_NAME = "숨겨진 이름 형식"
	L.STREAMER_MODE_HEADER_TEXT = "사용자 정의 헤더 텍스트"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"스트리머 모드가 활성화되었을 때 Battle.net 헤더에 표시할 텍스트(예: 'Stream Mode')."
	L.STREAMER_MODE_BUTTON_TOOLTIP = "스트리머 모드 토글"
	L.STREAMER_MODE_BUTTON_DESC = "클릭하여 개인정보 보호 모드를 활성화/비활성화합니다."
	L.SETTINGS_PRIVACY_OPTIONS = "개인정보 보호 옵션"
	L.SETTINGS_STREAMER_NAME_FORMAT = "이름 값"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC = "스트리머 모드에서 이름을 표시하는 방식을 선택합니다."
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "BattleTag 강제"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME = "별명 강제"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "메모 강제"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "보라색 헤더 색상 사용"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"스트리머 모드가 활성화되었을 때 Battle.net 헤더 배경을 트위치 보라색으로 변경합니다."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "공격대"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "단축키 활성화"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"공격대 프레임의 모든 사용자 정의 마우스 단축키를 활성화하거나 비활성화합니다."
	L.SETTINGS_RAID_SHORTCUTS_TITLE = "공격대 단축키"
	L.SETTINGS_RAID_ACTION_MASS_MOVE = "일괄 이동"
	L.SETTINGS_RAID_ACTION_TARGET = "대상 설정"
	L.SETTINGS_RAID_ACTION_MAIN_TANK = "주 탱커 설정"
	L.SETTINGS_RAID_ACTION_MAIN_ASSIST = "주 보조자 설정"
	L.SETTINGS_RAID_ACTION_RAID_LEAD = "공격대 리더 설정"
	L.SETTINGS_RAID_ACTION_PROMOTE = "보조자 승격"
	L.SETTINGS_RAID_ACTION_DEMOTE = "보조자 강등"
	L.SETTINGS_RAID_ACTION_KICK = "그룹에서 제거"
	L.SETTINGS_RAID_ACTION_INVITE = "그룹에 초대"
	L.SETTINGS_RAID_MODIFIER_NONE = "없음"
	L.SETTINGS_RAID_MODIFIER_SHIFT = "Shift"
	L.SETTINGS_RAID_MODIFIER_CTRL = "Ctrl"
	L.SETTINGS_RAID_MODIFIER_ALT = "Alt"
	L.SETTINGS_RAID_MOUSE_LEFT = "좌클릭"
	L.SETTINGS_RAID_MOUSE_RIGHT = "우클릭"
	L.SETTINGS_RAID_MOUSE_MIDDLE = "중앙클릭"
	L.SETTINGS_RAID_DESC = "공격대 및 그룹 관리를 위한 마우스 단축키를 구성합니다."
	L.SETTINGS_RAID_MODIFIER_LABEL = "모드:"
	L.SETTINGS_RAID_BUTTON_LABEL = "버튼:"
	L.SETTINGS_RAID_WARNING = "주의: 단축키는 보안 작업입니다(전투 중에만 해제됨)."
	L.SETTINGS_RAID_ERROR_RESERVED = "이 조합은 예약된 것입니다."

	-- ========================================
	-- WHO FRAME SETTINGS
	-- ========================================
	L.SETTINGS_TAB_WHO = "누구"
	L.WHO_SETTINGS_DESC = "누구 검색 결과의 모양과 동작을 설정합니다."
	L.WHO_SETTINGS_VISUAL_HEADER = "시각"
	L.WHO_SETTINGS_CLASS_ICONS = "직업 아이콘 표시"
	L.WHO_SETTINGS_CLASS_ICONS_DESC = "플레이어 이름 옆에 직업 아이콘을 표시합니다."
	L.WHO_SETTINGS_CLASS_COLORS = "직업 색상 이름"
	L.WHO_SETTINGS_CLASS_COLORS_DESC = "플레이어 이름을 직업별로 색상을 지정합니다."
	L.WHO_SETTINGS_LEVEL_COLORS = "레벨 난이도 색상"
	L.WHO_SETTINGS_LEVEL_COLORS_DESC = "내 레벨 대비 난이도에 따라 레벨에 색상을 지정합니다."
	L.WHO_SETTINGS_ZEBRA = "교대 행 배경"
	L.WHO_SETTINGS_ZEBRA_DESC = "가독성을 위해 번갈아 행 배경을 표시합니다."
	L.WHO_SETTINGS_BEHAVIOR_HEADER = "동작"
	L.WHO_SETTINGS_DOUBLE_CLICK = "더블클릭 동작"
	L.WHO_DOUBLE_CLICK_WHISPER = "귀솏말"
	L.WHO_DOUBLE_CLICK_INVITE = "그룹 초대"
	L.WHO_RESULTS_SHOWING = "%d명 중 %d명 표시"
	L.WHO_NO_RESULTS = "플레이어를 찾을 수 없습니다"
	L.WHO_TOOLTIP_HINT_CLICK = "클릭하여 선택"
	L.WHO_TOOLTIP_HINT_DBLCLICK = "더블클릭으로 귀속말"
	L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE = "더블클릭으로 초대"
	L.WHO_TOOLTIP_HINT_CTRL = "Ctrl+클릭으로 열 값 검색"
	L.WHO_TOOLTIP_HINT_RIGHTCLICK = "우클릭으로 옵션"

	-- ========================================
	-- WHO SEARCH BUILDER
	-- ========================================
	L.WHO_BUILDER_TITLE = "검색 빌더"
	L.WHO_BUILDER_NAME = "이름"
	L.WHO_BUILDER_GUILD = "길드"
	L.WHO_BUILDER_ZONE = "지역"
	L.WHO_BUILDER_CLASS = "직업"
	L.WHO_BUILDER_RACE = "종족"
	L.WHO_BUILDER_LEVEL = "레벨"
	L.WHO_BUILDER_LEVEL_TO = "~"
	L.WHO_BUILDER_ALL_CLASSES = "모든 직업"
	L.WHO_BUILDER_ALL_RACES = "모든 종족"
	L.WHO_BUILDER_PREVIEW = "미리보기:"
	L.WHO_BUILDER_PREVIEW_EMPTY = "검색을 구성하려면 필드를 입력하세요"
	L.WHO_BUILDER_SEARCH = "검색"
	L.WHO_BUILDER_RESET = "초기화"
	L.WHO_BUILDER_TOOLTIP = "검색 빌더 열기"

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "프레임 크기"
	L.SETTINGS_FRAME_SCALE = "크기:"
	L.SETTINGS_FRAME_WIDTH = "너비:"
	L.SETTINGS_FRAME_HEIGHT = "높이:"
	L.SETTINGS_FRAME_WIDTH_DESC = "프레임 너비 조정"
	L.SETTINGS_FRAME_HEIGHT_DESC = "프레임 높이 조정"
	L.SETTINGS_FRAME_SCALE_DESC = "프레임 크기 조정"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "그룹 헤더 정렬"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC = "그룹 이름 텍스트의 정렬 설정"
	L.SETTINGS_ALIGN_LEFT = "왼쪽"
	L.SETTINGS_ALIGN_CENTER = "가운데"
	L.SETTINGS_ALIGN_RIGHT = "오른쪽"
	L.SETTINGS_SHOW_GROUP_ARROW = "축소 화살표 표시"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC = "그룹을 축소하는 화살표 아이콘 표시/숨김"
	L.SETTINGS_GROUP_ARROW_ALIGN = "축소 화살표 정렬"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC = "축소/확장 화살표 아이콘의 정렬 설정"
	L.SETTINGS_FONT_FACE = "글꼴"
	L.SETTINGS_COLOR_GROUP_COUNT = "그룹 개수 색상"
	L.SETTINGS_COLOR_GROUP_ARROW = "축소 화살표 색상"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "그룹에서 색상 상속"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "그룹에서 색상 상속"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "그룹 헤더 설정"
	L.SETTINGS_GROUP_FONT_HEADER = "그룹 헤더 글꼴"
	L.SETTINGS_GROUP_COLOR_HEADER = "그룹 헤더 색상"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "그룹에서 상속받으려면 우클릭"
	L.SETTINGS_INHERIT_TOOLTIP = "(그룹에서 상속됨)"

	-- Misc
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "전역 무시 목록"
	L.IGNORE_LIST_ENHANCEQOL_IGNORE = "EnhanceQoL 무시 목록"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "친구 이름 설정"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "친구 정보 설정"
	L.SETTINGS_FONT_TABS_TITLE = "탭 텍스트"
	L.SETTINGS_FONT_RAID_TITLE = "공격대 이름 텍스트"
	L.SETTINGS_FONT_SIZE_NUM = "글꼴 크기"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "그룹 메모 동기화"
	L.SETTINGS_SYNC_GROUPS_NOTE = "그룹을 친구 메모에 동기화"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"FriendGroups 형식(메모#그룹1#그룹2)으로 그룹 할당을 친구 메모에 작성합니다. 계정 간 또는 FriendGroups 사용자와 그룹을 공유할 수 있습니다."
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"그룹 메모 동기화를 활성화하시겠습니까?\n\n|cffff8800경고:|r 배틀넷 메모는 127자, WoW 친구 메모는 48자로 제한됩니다. 글자 수 제한을 초과하는 그룹은 메모에서 생략되지만 데이터베이스에는 유지됩니다.\n\n기존 메모가 업데이트됩니다. 계속하시겠습니까?"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "활성화"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "취소"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"그룹 메모 동기화가 비활성화되었습니다.\n\n메모 정리 마법사를 열어 친구 메모에서 그룹 접미사를 제거하시겠습니까?"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "정리 마법사 열기"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "메모 유지"
	L.MSG_SYNC_GROUPS_STARTED = "그룹을 친구 메모에 동기화 중..."
	L.MSG_SYNC_GROUPS_COMPLETE = "그룹 메모 동기화 완료. 업데이트: %d, 건너뜀(제한): %d"
	L.MSG_SYNC_GROUPS_PROGRESS = "메모 동기화 중: %d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT = "%s의 메모 제한 도달 - 일부 그룹 건너뜀"

	-- ========================================
	-- MESSAGES (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.MSG_INVITE_CONVERT_RAID = "파티를 공격대로 전환 중..."
	L.MSG_INVITE_RAID_FULL = "공격대가 가득 찼습니다 (%d/40). 초대를 중단했습니다."

	-- ========================================
	-- SETTINGS (Phase 22 - Asian/Cyrillic)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "환영 메시지 표시"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC =
		"로그인할 때 애드온 로드된 메시지를 채팅에 표시합니다."

	-- ========================================
	-- RAID CONVERSION / MOCK (Phase 21+)
	-- ========================================
	L.RAID_GROUP_NAME = "그룹 %d"
	L.RAID_CONVERT_TO_PARTY = "파티로 변환"
	L.RAID_CONVERT_TO_RAID = "공격대로 변환"
	L.RAID_MUST_BE_LEADER = "이를 수행하려면 리더여야 합니다"
	L.RAID_CONVERT_TOO_MANY = "그룹에 파티에 대해 너무 많은 플레이어가 있습니다"
	L.RAID_ERR_NOT_IN_GROUP = "당신은 그룹에 속해 있지 않습니다"
	L.MOCK_INVITE_ACCEPTED = "%s의 모의 초대를 수락했습니다"
	L.MOCK_INVITE_DECLINED = "%s의 모의 초대를 거절했습니다"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "메모 정리 마법사"
	L.WIZARD_DESC =
		"친구 메모에서 FriendGroups 데이터(#그룹1#그룹2)를 제거합니다. 적용하기 전에 정리된 메모를 확인하세요."
	L.WIZARD_BTN = "메모 정리"
	L.WIZARD_BTN_TOOLTIP = "친구 메모에서 FriendGroups 데이터를 정리하는 마법사 열기"
	L.WIZARD_HEADER = "메모 정리"
	L.WIZARD_HEADER_DESC =
		"친구 메모에서 FriendGroups 접미사를 제거합니다. 먼저 백업한 다음 변경 사항을 검토하고 적용하세요."
	L.WIZARD_COL_ACCOUNT = "계정 이름"
	L.WIZARD_COL_BATTLETAG = "배틀태그"
	L.WIZARD_COL_NOTE = "현재 메모"
	L.WIZARD_COL_CLEANED = "정리된 메모"
	L.WIZARD_SEARCH_PLACEHOLDER = "검색..."
	L.WIZARD_BACKUP_BTN = "메모 백업"
	L.WIZARD_BACKUP_DONE = "백업 완료!"
	L.WIZARD_BACKUP_TOOLTIP = "모든 현재 친구 메모를 데이터베이스에 백업으로 저장합니다."
	L.WIZARD_BACKUP_SUCCESS = "%d명의 친구 메모를 백업했습니다."
	L.WIZARD_APPLY_BTN = "정리 적용"
	L.WIZARD_APPLY_TOOLTIP =
		"정리된 메모를 다시 기록합니다. 원본과 다른 메모만 업데이트됩니다."
	L.WIZARD_APPLY_CONFIRM =
		"모든 친구에게 정리된 메모를 적용하시겠습니까?\n\n|cffff8800현재 메모가 덮어쓰기됩니다. 먼저 백업을 만들었는지 확인하세요!|r"
	L.WIZARD_APPLY_SUCCESS = "%d개의 메모가 성공적으로 업데이트되었습니다."
	L.WIZARD_APPLY_PROGRESS_FMT = "진행: %d/%d | %d 성공 | %d 실패"
	L.WIZARD_STATUS_FMT = "%d / %d 친구 표시 중 | %d 그룹 데이터 포함 | %d 변경 대기 중"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "백업 보기"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"백업 뷰어를 열어 저장된 모든 메모를 현재 메모와 비교합니다."
	L.WIZARD_BACKUP_VIEWER_TITLE = "메모 백업 뷰어"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"백업된 친구 메모를 현재 메모와 비교하여 확인합니다. 필요한 경우 원래 메모를 복원할 수 있습니다."
	L.WIZARD_COL_BACKED_UP = "백업된 메모"
	L.WIZARD_COL_CURRENT = "현재 메모"
	L.WIZARD_RESTORE_BTN = "백업 복원"
	L.WIZARD_RESTORE_TOOLTIP =
		"백업에서 원래 메모를 복원합니다. 백업과 다른 메모만 업데이트됩니다."
	L.WIZARD_RESTORE_CONFIRM =
		"백업에서 모든 메모를 복원��시겠습니까?\n\n|cffff8800현재 메모가 백업된 버전으로 ��어씌����니다.|r"
	L.WIZARD_RESTORE_SUCCESS = "%d개의 메모가 성공적으로 복원되었습니다."
	L.WIZARD_NO_BACKUP =
		"메모 백업을 찾을 수 없습니다. 먼저 메모 정리 마법사를 사용하여 백업을 만드세요."
	L.WIZARD_BACKUP_STATUS_FMT = "%d/%d개 표시 | 백업 이후 %d개 변경 | 백업: %s"
end)
