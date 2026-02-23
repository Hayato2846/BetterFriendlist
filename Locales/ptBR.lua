-- Locales/ptBR.lua
-- Portuguese (Brazil) Localization

local ADDON_NAME, BFL = ...
BFL:RegisterLocale("ptBR", function()
	local L = BFL_LOCALE
	L.SETTINGS_SIMPLE_MODE = "Simple Mode"
	L.SETTINGS_SIMPLE_MODE_DESC =
		"Desativa o retrato do jogador, oculta opções de pesquisa/ordenação, amplia o quadro e desloca as abas para um layout compacto."
	L.MENU_CHANGELOG = "Histórico de Alterações"
	-- ========================================
	-- DIALOGS & POPUPS
	-- ========================================
	L.DIALOG_CREATE_GROUP_TEXT = "Digite um nome para o novo grupo:"
	L.DIALOG_CREATE_GROUP_BTN1 = "Criar"
	L.DIALOG_CREATE_GROUP_BTN2 = "Cancelar"
	L.DIALOG_RENAME_GROUP_TEXT = "Digite um novo nome para o grupo:"
	L.DIALOG_RENAME_GROUP_BTN1 = "Renomear"
	L.DIALOG_RENAME_GROUP_BTN2 = "Cancelar"
	L.DIALOG_RENAME_GROUP_SETTINGS = "Renomear grupo '%s':"
	L.DIALOG_DELETE_GROUP_TEXT =
		"Tem certeza de que deseja excluir este grupo?\n\n|cffff0000Isso removerá todos os amigos deste grupo.|r"
	L.DIALOG_DELETE_GROUP_BTN1 = "Excluir"
	L.DIALOG_DELETE_GROUP_BTN2 = "Cancelar"
	L.DIALOG_DELETE_GROUP_SETTINGS = "Excluir grupo '%s'?\n\nTodos os amigos serão desatribuídos deste grupo."
	L.DIALOG_RESET_SETTINGS_TEXT = "Redefinir todas as configurações para os valores padrão?"
	L.DIALOG_RESET_BTN1 = "Redefinir"
	L.DIALOG_RESET_BTN2 = "Cancelar"
	L.DIALOG_UI_PANEL_RELOAD_TEXT =
		"Alterar a configuração de hierarquia da IU requer um recarregamento da interface.\n\nRecarregar agora?"
	L.DIALOG_UI_PANEL_RELOAD_BTN1 = "Recarregar"
	L.DIALOG_UI_PANEL_RELOAD_BTN2 = "Cancelar"
	L.MSG_RELOAD_REQUIRED = "É necessário recarregar para aplicar esta alteração corretamente no Classic."
	L.MSG_RELOAD_NOW = "Recarregar IU agora?"
	L.RAID_HELP_TITLE = "Ajuda de raide"
	L.RAID_HELP_TEXT = "Clique para obter ajuda sobre a lista de raide."
	L.RAID_HELP_MULTISELECT_TITLE = "Seleção múltipla"
	L.RAID_HELP_MULTISELECT_TEXT =
		"Segure Ctrl e clique com o botão esquerdo para selecionar vários jogadores.\nUma vez selecionados, arraste e solte-os em qualquer grupo para movê-los todos de uma vez."
	L.RAID_HELP_MAINTANK_TITLE = "Tanque principal"
	L.RAID_HELP_MAINTANK_TEXT =
		"%s em um jogador para defini-lo como tanque principal.\nUm ícone de tanque aparecerá ao lado de seu nome."
	L.RAID_HELP_MAINASSIST_TITLE = "Assistente principal"
	L.RAID_HELP_MAINASSIST_TEXT =
		"%s em um jogador para defini-lo como assistente principal.\nUm ícone de assistente aparecerá ao lado de seu nome."
	L.RAID_HELP_LEAD_TITLE = "Líder da Raide"
	L.RAID_HELP_LEAD_TEXT = "%s em um jogador para promovê-lo a Líder da Raide."
	L.RAID_HELP_PROMOTE_TITLE = "Assistente"
	L.RAID_HELP_PROMOTE_TEXT = "%s em um jogador para promover/rebaixar a Assistente."
	L.RAID_HELP_DRAGDROP_TITLE = "Arrastar e soltar"
	L.RAID_HELP_DRAGDROP_TEXT =
		"Arraste qualquer jogador para movê-lo entre grupos.\nVocê também pode arrastar vários jogadores selecionados de uma vez.\nEspaços vazios podem ser usados para trocar posições."
	L.RAID_HELP_COMBAT_TITLE = "Bloqueio de combate"
	L.RAID_HELP_COMBAT_TEXT =
		"Os jogadores não podem ser movidos durante o combate.\nEsta é uma restrição da Blizzard."
	L.RAID_INFO_UNAVAILABLE = "Nenhuma informação disponível"
	L.RAID_NOT_IN_RAID = "Não está em Raide"
	L.RAID_NOT_IN_RAID_DETAILS = "Você não está atualmente em um grupo de raide"
	L.RAID_CREATE_BUTTON = "Criar Raide"
	L.GROUP = "Grupo"
	L.ALL = "Todos"
	L.UNKNOWN_ERROR = "Erro desconhecido"
	L.RAID_ERROR_NOT_ENOUGH_SPACE = "Espaço insuficiente: %d jogadores selecionados, %d vagas livres no Grupo %d"
	L.RAID_MSG_BULK_MOVE_SUCCESS = "Movidos %d jogadores para o Grupo %d"
	L.RAID_ERROR_BULK_MOVE_FAILED = "Falha ao mover %d jogadores"
	L.RAID_ERROR_READY_CHECK_PERMISSION = "Você deve ser líder ou assistente para checagem de prontidão."
	L.RAID_ERROR_NO_SAVED_INSTANCES = "Nenhuma instância salva."
	L.RAID_ERROR_LOAD_RAID_INFO = "Erro: Não foi possível carregar Info de Raide."
	L.RAID_MSG_SWAP_SUCCESS = "%s <-> %s trocados"
	L.RAID_ERROR_SWAP_FAILED = "Troca falhou: %s"
	L.RAID_MSG_MOVE_SUCCESS = "%s movido para o Grupo %d"
	L.RAID_ERROR_MOVE_FAILED = "Movimento falhou: %s"
	L.DIALOG_MIGRATE_TEXT =
		"Migrar grupos do FriendGroups para BetterFriendlist?\n\nIsso irá:\n• Criar grupos das notas BNet\n• Atribuir amigos aos grupos\n• Opcionalmente abrir o Assistente de Limpeza para revisar e limpar notas\n\n|cffff0000Aviso: Irreversível!|r"
	L.DIALOG_MIGRATE_BTN1 = "Migrar e Revisar Notas"
	L.DIALOG_MIGRATE_BTN2 = "Apenas Migrar"
	L.DIALOG_MIGRATE_BTN3 = "Cancelar"

	-- ========================================
	-- SETTINGS PANEL
	-- ========================================
	L.SETTINGS_TAB_GENERAL = "Geral"
	L.SETTINGS_TAB_FONTS = "Fontes"
	L.SETTINGS_TAB_GROUPS = "Grupos"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Header Settings"
	L.SETTINGS_GROUP_FONT_HEADER = "Group Header Font"
	L.SETTINGS_GROUP_COLOR_HEADER = "Group Header Colors"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Herdar cor do grupo"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Herdar cor do grupo"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clique com o botão direito para herdar do grupo"
	L.SETTINGS_INHERIT_TOOLTIP = "(Herdado do grupo)"
	L.SETTINGS_GROUP_ORDER_HEADER = "Group Order"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.SETTINGS_TAB_APPEARANCE = "Aparência"
	L.SETTINGS_TAB_ADVANCED = "Avançado"
	L.SETTINGS_ADVANCED_DESC = "Opções avançadas e ferramentas"
	L.SETTINGS_TAB_STATISTICS = "Estatísticas"
	L.SETTINGS_SHOW_BLIZZARD = "Mostrar opção da lista Blizzard"
	L.SETTINGS_COMPACT_MODE = "Modo Compacto"
	L.SETTINGS_LOCK_WINDOW = "Bloquear Janela"
	L.SETTINGS_LOCK_WINDOW_DESC = "Bloqueia a janela para evitar movimentos acidentais."
	L.SETTINGS_FONT_SIZE = "Tamanho da Fonte"
	L.SETTINGS_FONT_COLOR = "Cor da Fonte"
	L.SETTINGS_FONT_SIZE_SMALL = "Pequena (Compacto, 10px)"
	L.SETTINGS_FONT_SIZE_NORMAL = "Normal (12px)"
	L.SETTINGS_FONT_SIZE_LARGE = "Grande (14px)"
	L.SETTINGS_COLOR_CLASS_NAMES = "Colorir Nomes de Classe"
	L.SETTINGS_HIDE_EMPTY_GROUPS = "Ocultar Grupos Vazios"
	L.SETTINGS_HEADER_COUNT_FORMAT = "Contador Cabeçalho"
	L.SETTINGS_HEADER_COUNT_FORMAT_DESC = "Escolha como mostrar contadores de amigos"
	L.SETTINGS_HEADER_COUNT_VISIBLE = "Filtrado / Total (Padrão)"
	L.SETTINGS_HEADER_COUNT_ONLINE = "Online / Total"
	L.SETTINGS_HEADER_COUNT_BOTH = "Filtrado / Online / Total"
	L.SETTINGS_SHOW_FACTION_ICONS = "Mostrar Ícones Facção"
	L.SETTINGS_SHOW_REALM_NAME = "Mostrar Nome Reino"
	L.SETTINGS_GRAY_OTHER_FACTION = "Atenuar Outra Facção"
	L.SETTINGS_SHOW_MOBILE_AS_AFK = "Mostrar Móvel como AFK"
	L.SETTINGS_SHOW_MOBILE_TEXT = "Mostrar Texto Móvel"
	L.SETTINGS_HIDE_MAX_LEVEL = "Ocultar Nível Máximo"
	L.SETTINGS_ACCORDION_GROUPS = "Grupos Sanfona (um aberto)"
	L.SETTINGS_SHOW_FAVORITES = "Mostrar Grupo Favoritos"
	L.SETTINGS_SHOW_GROUP_FMT = "Mostrar grupo %s"
	L.SETTINGS_SHOW_GROUP_DESC_FMT = "Alternar visibilidade do grupo %s na sua lista de amigos"
	L.SETTINGS_GROUP_COLOR = "Cor do Grupo"
	L.SETTINGS_RENAME_GROUP = "Renomear Grupo"
	L.SETTINGS_DELETE_GROUP = "Excluir Grupo"
	L.SETTINGS_DELETE_GROUP_DESC = "Excluir grupo e remover amigos"
	L.SETTINGS_EXPORT_TITLE = "Exportar Configuração"
	L.SETTINGS_EXPORT_INFO = "Copie o texto abaixo e salve-o."
	L.SETTINGS_EXPORT_BTN = "Selecionar Tudo"
	L.BUTTON_EXPORT = "Exportar"
	L.SETTINGS_IMPORT_TITLE = "Importar Configuração"
	L.SETTINGS_IMPORT_INFO =
		"Cole a string de exportação e clique Importar.\n\n|cffff0000Aviso: Substituirá TODOS os grupos!|r"
	L.SETTINGS_IMPORT_BTN = "Importar"
	L.SETTINGS_IMPORT_CANCEL = "Cancelar"
	L.SETTINGS_RESET_DEFAULT = "Redefinir Padrões"
	L.SETTINGS_RESET_SUCCESS = "Configurações redefinidas!"
	L.SETTINGS_GROUP_ORDER_SAVED = "Ordem dos grupos salva!"
	L.SETTINGS_MIGRATION_COMPLETE = "Migração Concluída!"
	L.SETTINGS_MIGRATION_FRIENDS = "Amigos processados:"
	L.SETTINGS_MIGRATION_GROUPS = "Grupos criados:"
	L.SETTINGS_MIGRATION_ASSIGNMENTS = "Atribuições:"
	L.SETTINGS_NOTES_CLEANED = "Notas limpas!"
	L.SETTINGS_NOTES_PRESERVED = "Notas preservadas."
	L.SETTINGS_EXPORT_SUCCESS = "Exportação concluída!"
	L.SETTINGS_IMPORT_SUCCESS = "Importação bem-sucedida!"
	L.SETTINGS_IMPORT_FAILED = "Falha Importação!\n\n"
	L.STATS_TOTAL_FRIENDS = "Total Amigos: %d"
	L.STATS_ONLINE_OFFLINE = "|cff00ff00Online: %d (%d%%)|r  |  |cff808080Offline: %d (%d%%)|r"
	L.STATS_BNET_WOW = "|cff0070ddBattle.net: %d|r  |  |cffffd700WoW: %d|r"

	-- ========================================
	-- FRIEND REQUESTS
	-- ========================================
	L.INVITE_HEADER = "Solicitações (%d)"
	L.INVITE_BUTTON_ACCEPT = "Aceitar"
	L.INVITE_BUTTON_DECLINE = "Recusar"
	L.INVITE_TAP_TEXT = "Toque para aceitar ou recusar"
	L.INVITE_MENU_DECLINE = "Recusar"
	L.INVITE_MENU_REPORT = "Denunciar"
	L.INVITE_MENU_BLOCK = "Bloquear"

	-- ========================================
	-- FILTERS & SORTING
	-- ========================================
	L.FILTER_ALL_FRIENDS = "Todos os Amigos"
	L.FILTER_ONLINE_ONLY = "Apenas Online"
	L.FILTER_OFFLINE_ONLY = "Apenas Offline"
	L.FILTER_WOW_ONLY = "Apenas WoW"
	L.FILTER_BNET_ONLY = "Apenas Battle.net"
	L.FILTER_HIDE_AFK = "Ocultar AFK/DND"
	L.FILTER_RETAIL_ONLY = "Apenas Retail"
	L.FILTER_TOOLTIP = "Filtro Rápido: %s"
	L.SORT_STATUS = "Status"
	L.SORT_NAME = "Nome (A-Z)"
	L.SORT_LEVEL = "Nível"
	L.SORT_ZONE = "Zona"
	L.SORT_GAME = "Jogo"
	L.SORT_FACTION = "Facção"
	L.SORT_GUILD = "Guilda"
	L.SORT_CLASS = "Classe"
	L.SORT_REALM = "Reino"
	L.SORT_CHANGED = "Ordenação: %s"
	L.SORT_NONE = "Nenhum"
	L.SORT_PRIMARY_LABEL = "Primary Sort"
	L.SORT_SECONDARY_LABEL = "Secondary Sort"
	L.SORT_PRIMARY_DESC = "Escolha como a lista de amigos é classificada."
	L.SORT_SECONDARY_DESC = "Classifique por isto quando os valores primários são iguais."

	-- ========================================
	-- MENUS & CONTEXT MENUS
	-- ========================================
	L.MENU_GROUPS = "Grupos"
	L.MENU_CREATE_GROUP = "Criar Grupo"
	L.MENU_REMOVE_ALL_GROUPS = "Remover de Todos"
	L.MENU_REMOVE_RECENTLY_ADDED = "Remover de Adicionados recentemente"
	L.MENU_CLEAR_ALL_RECENTLY_ADDED = "Limpar todos os adicionados recentemente"
	L.MENU_ADD_ALL_TO_GROUP = "Adicionar todos ao grupo"
	L.MENU_RENAME_GROUP = "Renomear Grupo"
	L.MENU_DELETE_GROUP = "Excluir Grupo"
	L.MENU_INVITE_GROUP = "Convidar Grupo"
	L.MENU_COLLAPSE_ALL = "Recolher Todos"
	L.MENU_EXPAND_ALL = "Expandir Todos"
	L.MENU_SETTINGS = "Configurações"
	L.MENU_SET_BROADCAST = "Definir Transmissão"
	L.MENU_IGNORE_LIST = "Lista Ignorados"
	L.MENU_BETTERFRIENDLIST_TITLE = "BetterFriendList"
	L.MENU_MORE_GROUPS = "Mais grupos..."
	L.MENU_SWITCH_GAME_ACCOUNT = "Trocar conta de jogo"
	L.MENU_DEFAULT_FOCUS = "Padrão (Blizzard)"
	L.GROUPS_DIALOG_TITLE = "Grupos para %s"
	L.MENU_COPY_CHARACTER_NAME = "Copiar nome do personagem"
	L.COPY_CHARACTER_NAME_POPUP_TITLE = "Copiar nome do personagem"

	-- ========================================
	-- TOOLTIPS
	-- ========================================
	L.TOOLTIP_DROP_TO_ADD = "Solte para adicionar"
	L.TOOLTIP_HOLD_SHIFT = "Segure Shift para manter em outros"
	L.TOOLTIP_DRAG_HERE = "Arraste amigos aqui"
	L.TOOLTIP_ERROR = "Erro"
	L.TOOLTIP_NO_GAME_ACCOUNTS = "Sem conta de jogo"
	L.TOOLTIP_NO_INFO = "Info insuficiente"
	L.TOOLTIP_RENAME_GROUP = "Renomear Grupo"
	L.TOOLTIP_RENAME_DESC = "Clique para renomear"
	L.TOOLTIP_GROUP_COLOR = "Cor do Grupo"
	L.TOOLTIP_GROUP_COLOR_DESC = "Clique para mudar cor"
	L.TOOLTIP_DELETE_GROUP = "Excluir Grupo"
	L.TOOLTIP_DELETE_DESC = "Excluir grupo e amigos"

	-- ========================================
	-- STATUS MESSAGES
	-- ========================================
	L.MSG_INVITE_COUNT = "%d amigo(s) convidado(s)."
	L.MSG_NO_FRIENDS_AVAILABLE = "Nenhum amigo online para convidar."
	L.MSG_INVITE_CONVERT_RAID = "Convertendo grupo em raide..."
	L.MSG_INVITE_RAID_FULL = "Raide cheia (%d/40). Convites parados."
	L.MSG_GROUP_DELETED = "Grupo '%s' excluído"
	L.MSG_IGNORE_LIST_EMPTY = "Lista vazia."
	L.MSG_IGNORE_LIST_COUNT = "Ignorados (%d):"
	L.MSG_MIGRATION_ALREADY_DONE = "Migração já feita. Use '/bfl migrate force'."
	L.MSG_MIGRATION_STARTING = "Iniciando migração..."
	L.MSG_GROUP_ORDER_SAVED = "Ordem salva!"
	L.MSG_SETTINGS_RESET = "Configurações redefinidas!"
	L.MSG_EXPORT_FAILED = "Export falhou: %s"
	L.MSG_IMPORT_SUCCESS = "Import sucesso!"
	L.MSG_IMPORT_FAILED = "Import falhou: %s"

	-- ========================================
	-- ERRORS & WARNINGS
	-- ========================================
	L.ERROR_DB_NOT_AVAILABLE = "Banco não disponível!"
	L.ERROR_SETTINGS_NOT_INIT = "Frame não iniciado!"
	L.ERROR_MODULES_NOT_LOADED = "Módulos não carregados!"
	L.ERROR_GROUPS_MODULE = "Módulo Grupos indisp!"
	L.ERROR_SETTINGS_MODULE = "Módulo Config indisp!"
	L.ERROR_FRIENDSLIST_MODULE = "Módulo FriendList indisp"
	L.ERROR_FAILED_DELETE_GROUP = "Falha exclusão grupo"
	L.ERROR_FAILED_DELETE = "Exclusão falhou: %s"
	L.ERROR_MIGRATION_FAILED = "Migração falhou!"
	L.ERROR_GROUP_NAME_EMPTY = "Nome grupo vazio"
	L.ERROR_GROUP_EXISTS = "Grupo existe"
	L.ERROR_INVALID_GROUP_NAME = "Nome inválido"
	L.ERROR_GROUP_NOT_EXIST = "Grupo não existe"
	L.ERROR_CANNOT_RENAME_BUILTIN = "Não pode renomear padrão"
	L.ERROR_INVALID_GROUP_ID = "ID grupo inválido"
	L.ERROR_CANNOT_DELETE_BUILTIN = "Não pode excluir padrão"

	-- ========================================
	-- MISC UI ELEMENTS
	-- ========================================
	L.TAB_FRIENDS = "Amigos"
	L.GROUP_FAVORITES = "Favoritos"
	L.GROUP_INGAME = "No Jogo"
	L.GROUP_NO_GROUP = "Sem Grupo"
	L.GROUP_RECENTLY_ADDED = "Adicionados recentemente"
	L.ONLINE_STATUS = "Online"
	L.OFFLINE_STATUS = "Offline"
	L.STATUS_MOBILE = "Móvel"
	L.STATUS_IN_APP = "No App"
	L.UNKNOWN_GAME = "Jogo Desconhecido"
	L.BUTTON_ADD_FRIEND = "Adic. Amigo"
	L.BUTTON_SEND_MESSAGE = "Mensagem"
	L.EMPTY_TEXT = "Vazio"
	L.LEVEL_FORMAT = "Nível %d"

	-- ========================================
	-- BETA FEATURES (Advanced Tab)
	-- ========================================
	L.SETTINGS_BETA_FEATURES_TITLE = "Recursos Beta"
	L.SETTINGS_BETA_FEATURES_DESC = "Ativar recursos experimentais."
	L.SETTINGS_BETA_FEATURES_ENABLE = "Ativar Beta"
	L.SETTINGS_BETA_FEATURES_TOOLTIP = "Ativar experimental"
	L.SETTINGS_BETA_FEATURES_WARNING = "Aviso: Possíveis bugs."
	L.SETTINGS_BETA_FEATURES_LIST = "Recursos Beta disponíveis:"
	L.SETTINGS_BETA_FEATURES_ENABLED = "Beta |cff00ff00ATIVADO|r"
	L.SETTINGS_BETA_FEATURES_DISABLED = "Beta |cffff0000DESATIVADO|r"
	L.SETTINGS_BETA_TABS_VISIBLE = "Abas Beta visíveis"
	L.SETTINGS_BETA_TABS_HIDDEN = "Abas Beta ocultas"

	-- Global Friend Sync
	L.SETTINGS_GLOBAL_SYNC_ENABLE = "Ativar Sync Global"
	L.SETTINGS_GLOBAL_SYNC_DESC = "Sincronizar lista de amigos na conta."
	L.SETTINGS_GLOBAL_SYNC_FEATURE = "Sync Global"
	L.SETTINGS_GLOBAL_SYNC_DELETION = "Ativar Exclusão"
	L.SETTINGS_GLOBAL_SYNC_DELETION_DESC = "Permitir exclusão na sincronização."
	L.SETTINGS_GLOBAL_SYNC_HEADER = "Banco de Dados Sync"

	-- ========================================
	-- NOTIFICATIONS TAB
	-- ========================================

	-- ========================================
	-- NOTIFICATION MESSAGES
	-- ========================================

	-- ========================================
	-- EDIT MODE FRAME SIZE (PHASE 5)
	-- ========================================
	L.SETTINGS_FRAME_SIZE_HEADER = "Tamanho Frame (Edit Mode)"
	L.SETTINGS_FRAME_SIZE_INFO = "Tamanho padrão."
	L.SETTINGS_FRAME_WIDTH = "Largura:"
	L.SETTINGS_FRAME_HEIGHT = "Altura:"
	L.SETTINGS_FRAME_RESET_SIZE = "Reset 415x570"
	L.SETTINGS_FRAME_APPLY_NOW = "Aplicar Agora"
	L.SETTINGS_FRAME_RESET_ALL = "Reset Tudo"

	-- ========================================
	-- DATA BROKER (STABLE FEATURE)
	-- ========================================
	L.BROKER_TITLE = "BetterFriendlist"
	L.BROKER_TOOLTIP_HEADER = "Amigos"
	L.BROKER_TOOLTIP_FOOTER_LEFT = "Clique Esq: Abrir"
	L.BROKER_TOOLTIP_FOOTER_RIGHT = "Clique Dir: Config"
	L.BROKER_SETTINGS_ENABLE = "Ativar Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON = "Mostrar Ícone"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Detalhe Tooltip"
	L.BROKER_SETTINGS_CLICK_ACTION = "Ação Clique Esq"
	L.BROKER_SETTINGS_LEFT_CLICK = "Ação Clique Esq"
	L.BROKER_SETTINGS_RIGHT_CLICK = "Ação Clique Dir"
	L.BROKER_ACTION_TOGGLE = "Alternar Janela"
	L.BROKER_ACTION_FRIENDS = "Abrir Lista Amigos"
	L.BROKER_ACTION_SETTINGS = "Abrir Config"
	L.BROKER_ACTION_OPEN_BNET = "Abrir App BNet"
	L.BROKER_ACTION_NONE = "Nenhum"
	L.BROKER_SETTINGS_INFO = "Integração Bazooka, TitanPanel, etc."
	L.BROKER_FILTER_CHANGED = "Filtro: %s"

	-- Broker Tooltip Strings
	L.BROKER_HEADER_WOW = "Amigos WoW"
	L.BROKER_HEADER_BNET = "Amigos Battle.Net"
	L.BROKER_NO_WOW_ONLINE = "  Sem amigos WoW online"
	L.BROKER_NO_FRIENDS_ONLINE = "Sem amigos online"
	L.BROKER_TOTAL_ONLINE = "Total: %d online / %d amigos"
	L.BROKER_FILTER_LABEL = "Filtro: "
	L.BROKER_SORT_LABEL = "Ordem: "
	L.BROKER_HINT_FRIEND_ACTIONS = "--- Ações Amigo ---"
	L.BROKER_HINT_CLICK_WHISPER = "Clique Amigo:"
	L.BROKER_HINT_WHISPER = " Sussurrar • "
	L.BROKER_HINT_RIGHT_CLICK_MENU = "Clique-Dir:"
	L.BROKER_HINT_CONTEXT_MENU = " Menu"
	L.BROKER_HINT_ALT_CLICK = "Alt+Clique:"
	L.BROKER_HINT_INVITE = " Convidar • "
	L.BROKER_HINT_SHIFT_CLICK = "Shift+Clique:"
	L.BROKER_HINT_COPY = " Copiar"
	L.BROKER_HINT_ICON_ACTIONS = "--- Ações Ícone ---"
	L.BROKER_HINT_LEFT_CLICK = "Clique Esq:"
	L.BROKER_HINT_TOGGLE = " Alternar"
	L.BROKER_HINT_RIGHT_CLICK = "Clique Dir:"
	L.BROKER_HINT_SETTINGS = " Config • "
	L.BROKER_HINT_MIDDLE_CLICK = "Clique Meio:"
	L.BROKER_HINT_CYCLE_FILTER = " Mudar Filtro"

	-- ========================================
	-- FEATURE REQUESTS (CurseForge User Feedback)
	-- ========================================
	-- Feature 1: Treat Mobile as Offline
	L.SETTINGS_TREAT_MOBILE_OFFLINE = "Tratar Mobile como Offline"
	L.SETTINGS_TREAT_MOBILE_OFFLINE_DESC = "Mostra amigos mobile no grupo Offline"

	-- Feature 3: Show Notes as Name
	L.SETTINGS_SHOW_NOTES_AS_NAME = "Mostrar Notas como Nome"
	L.SETTINGS_SHOW_NOTES_AS_NAME_DESC = "Usa nota do amigo como nome"

	-- Feature 4: Window Scale
	L.SETTINGS_WINDOW_SCALE = "Escala Janela"
	L.SETTINGS_WINDOW_SCALE_DESC = "Escala interface (50%% - 200%%)"

	-- Data Broker Settings
	L.BROKER_SETTINGS_SHOW_LABEL = "Mostrar Rótulo"
	L.BROKER_SETTINGS_SHOW_TOTAL = "Mostrar Total"
	L.BROKER_SETTINGS_SHOW_GROUPS = "Dividir Contagem"
	L.BROKER_SETTINGS_HEADER_GENERAL = "Config Geral"
	L.BROKER_SETTINGS_HEADER_INTEGRATION = "Integração"
	L.BROKER_SETTINGS_HEADER_INTERACTION = "Interação"
	L.BROKER_SETTINGS_HEADER_INSTRUCTIONS = "Instruções"
	L.BROKER_SETTINGS_HEADER_COMPATIBILITY = "Testado Com"
	L.BROKER_SETTINGS_INSTRUCTIONS = "• Instale addon broker (Bazooka)\n• Ative Data Broker"
	L.BROKER_SETTINGS_HEADER_COLUMNS = "Colunas Tooltip"
	L.BROKER_SETTINGS_COLUMNS_HEADER = "Colunas Tooltip"
	L.BROKER_COLUMN_NAME = "Nome"
	L.BROKER_COLUMN_LEVEL = "Nível"
	L.BROKER_COLUMN_CHARACTER = "Personagem"
	L.BROKER_COLUMN_GAME = "Jogo / App"
	L.BROKER_COLUMN_ZONE = "Zona"
	L.BROKER_COLUMN_REALM = "Reino"
	L.BROKER_COLUMN_FACTION = "Facção"
	L.BROKER_COLUMN_NOTES = "Notas"

	-- Broker Column Tooltips
	L.BROKER_COLUMN_NAME_DESC = "Mostra nome"
	L.BROKER_COLUMN_LEVEL_DESC = "Mostra nível"
	L.BROKER_COLUMN_CHARACTER_DESC = "Mostra personagem"
	L.BROKER_COLUMN_GAME_DESC = "Mostra jogo"
	L.BROKER_COLUMN_ZONE_DESC = "Mostra zona"
	L.BROKER_COLUMN_REALM_DESC = "Mostra reino"
	L.BROKER_COLUMN_FACTION_DESC = "Mostra facção"
	L.BROKER_COLUMN_NOTES_DESC = "Mostra notas"

	-- ========================================
	-- CLASSIC COMPATIBILITY
	-- ========================================
	L.RECENT_ALLIES_NOT_AVAILABLE = "Aliados Recentes indisponível."
	L.EDIT_MODE_NOT_AVAILABLE = "Edit Mode indisponível."
	L.CLASSIC_COMPATIBILITY_INFO = "Modo Compatibilidade Classic."
	L.FEATURE_NOT_AVAILABLE_CLASSIC = "Função indisponível no Classic."
	L.SETTINGS_CLOSE_ON_GUILD_TAB = "Fechar na Guilda"
	L.SETTINGS_CLOSE_ON_GUILD_TAB_DESC = "Fecha amigos ao abrir guilda"
	L.SETTINGS_HIDE_GUILD_TAB = "Ocultar Aba Guilda"
	L.SETTINGS_HIDE_GUILD_TAB_DESC = "Oculta aba guilda da lista"
	L.SETTINGS_USE_UI_PANEL_SYSTEM = "Usar Sistema Painel UI"
	L.SETTINGS_USE_UI_PANEL_SYSTEM_DESC = "Evita sobreposição. Requer reload."

	-- ========================================
	-- LAST ONLINE TIME FORMATS
	-- ========================================
	L.LASTONLINE_SECS = "< 1 min"
	L.LASTONLINE_MINUTES = "%d min"
	L.LASTONLINE_HOURS = "%d h"
	L.LASTONLINE_DAYS = "%d d"
	L.LASTONLINE_MONTHS = "%d meses"
	L.LASTONLINE_YEARS = "%d anos"

	-- ========================================
	-- GUILD UI WARNING
	-- ========================================
	L.CLASSIC_GUILD_UI_WARNING_TITLE = "UI Guilda Clássica Desativada"
	L.CLASSIC_GUILD_UI_WARNING_TEXT =
		"BetterFriendlist desativou a UI Guilda Clássica.\n\nAba Guilda abrirá interface moderna."

	-- ========================================
	-- AUDITED MISSING STRINGS
	-- ========================================
	-- Core
	L.SLASH_CMD_HELP = "BetterFriendlist: Use '/bfl migrate help' para ajuda."
	L.LOADED_MESSAGE = "BetterFriendlist carregado."
	L.DEBUG_ENABLED = "Debug ATIVADO"
	L.DEBUG_DISABLED = "Debug DESATIVADO"
	L.CONFIG_RESET = "Config reset."
	L.SEARCH_PLACEHOLDER = "Buscar..."

	-- Tabs (FriendsList)
	L.TAB_GUILD = "Guilda"
	L.TAB_RAID = "Raide"
	L.TAB_QUICK_JOIN = "Entrar"

	-- Filters (FriendsList)
	L.FILTER_SEARCH_ONLINE = "Online"
	L.FILTER_SEARCH_OFFLINE = "Offline"
	L.FILTER_SEARCH_MOBILE = "Móvel"
	L.FILTER_SEARCH_AFK = "AUS"
	L.FILTER_SEARCH_DND = "Não perturbe"

	-- Status (FriendsList)
	L.STATUS_AFK = "AFK"
	L.STATUS_DND = "DND"

	-- Groups
	L.MIGRATION_CHECK = "Verificar migração..."
	L.MIGRATION_RESULT = "Migrou %d grupos e %d atribuições."
	L.MIGRATION_BNET_UPDATED = "Atribuições BNet atualizadas."
	L.MIGRATION_BNET_REASSIGN = "Reatribuir BNet."
	L.MIGRATION_BNET_REASON = "(Motivo: ID BNet temporário)"
	L.MIGRATION_WOW_RESULT = "Migrou %d atribuições WoW."
	L.MIGRATION_WOW_FORMAT = "(Formato: Personagem-Reino)"
	L.MIGRATION_WOW_FAIL = "Impossível migrar (reino faltante)."
	L.MIGRATION_SMART_MIGRATING = "Migrando: %s -> %s"

	-- RaidFrame
	L.MSG_MULTI_SELECTION_CLEARED = "Seleção múltipla limpa - combate"

	-- Quick Join
	L.LEADER_LABEL = "Líder:"
	L.MEMBERS_LABEL = "Membros:"
	L.AVAILABLE_ROLES = "Funções Disp"
	L.NO_AVAILABLE_ROLES = "Sem função"
	L.AUTO_ACCEPT_TOOLTIP = "Aceitar auto."
	L.MOCK_JOIN_REQUEST_SENT = "Pedido teste enviado"
	L.QUICK_JOIN_NO_GROUPS = "Sem grupos"
	L.UNKNOWN_GROUP = "Grupo Desconhecido"
	L.UNKNOWN = "Desconhecido"
	L.NO_QUEUE = "Sem Fila"
	L.LFG_ACTIVITY = "Atividade LFG"
	L.ACTIVITY_DUNGEON = "Masmorra"
	L.ACTIVITY_RAID = "Raide"
	L.ACTIVITY_PVP = "PvP"

	-- Settings Dialogs
	L.DIALOG_IMPORT_SETTINGS_TITLE = "Importar Config"
	L.DIALOG_EXPORT_SETTINGS_TITLE = "Exportar Config"
	L.DIALOG_DELETE_GROUP_TITLE = "Excluir grupo"
	L.DIALOG_RENAME_GROUP_TITLE = "Renomear grupo"
	L.DIALOG_CREATE_GROUP_TITLE = "Criar grupo"

	-- Tooltips
	L.TOOLTIP_LAST_ONLINE = "Último online: %s"

	-- Notifications
	L.YES = "SIM"
	L.NO = "NÃO"

	-- Notification Templates (Defaults)

	L.EDITMODE_PREVIEW_NAME = "Prévia %d"
	L.EDITMODE_PREVIEW_MESSAGE = "Prévia posição"
	L.EDITMODE_FRAME_WIDTH = "Largura"
	L.EDITMODE_FRAME_HEIGHT = "Altura"

	-- Dialogs (Notifications Trigger)
	L.DIALOG_RESET_LAYOUTS_TEXT = "Reset layout?\n\nIrreversível!"
	L.DIALOG_RESET_LAYOUTS_BTN1 = "Reset"
	L.MSG_LAYOUTS_RESET = "Layouts resetados."
	L.DIALOG_TRIGGER_TITLE = "Criar Gatilho"
	L.DIALOG_TRIGGER_INFO = "Notificar se X amigos online."
	L.DIALOG_TRIGGER_SELECT_GROUP = "Grupo:"
	L.DIALOG_TRIGGER_MIN_FRIENDS = "Min Amigos:"
	L.DIALOG_TRIGGER_CREATE = "Criar"
	L.DIALOG_TRIGGER_CANCEL = "Cancelar"
	L.ERROR_SELECT_GROUP = "Selecione grupo"
	L.MSG_TRIGGER_CREATED = "Gatilho criado: %d+ '%s'"
	L.ERROR_NO_GROUPS = "Sem grupos."

	-- Menus
	L.MENU_SET_NICKNAME_FMT = "Definir Apelido %s"

	-- ========================================
	-- PHASE 3 LOCALIZATION (Broker & Global Sync)
	-- ========================================
	-- Filter (QuickFilters)
	L.FILTER_ALL = "Todos"
	L.FILTER_ONLINE = "Online"
	L.FILTER_OFFLINE = "Offline"
	L.FILTER_WOW = "WoW"
	L.FILTER_BNET = "BNet"
	L.FILTER_HIDE_AFK = "Sem AFK"
	L.FILTER_RETAIL = "Retail"
	L.TOOLTIP_QUICK_FILTER = "Filtro: %s"

	-- Settings (Broker)
	L.BROKER_SETTINGS_RELOAD_TEXT = "Recarregar necessário.\n\nRecarregar?"
	L.BROKER_SETTINGS_RELOAD_BTN = "Recarr."
	L.BROKER_SETTINGS_RELOAD_CANCEL = "Canc."
	L.BROKER_SETTINGS_ENABLE_TOOLTIP = "Ativar Data Broker"
	L.BROKER_SETTINGS_SHOW_ICON_TITLE = "Mostrar Ícone"
	L.BROKER_SETTINGS_SHOW_ICON_TOOLTIP = "Ícone BFL"
	L.BROKER_SETTINGS_SHOW_LABEL_TITLE = "Mostrar Rótulo"
	L.BROKER_SETTINGS_SHOW_LABEL_TOOLTIP = "Rótulo 'Amigos'"
	L.BROKER_SETTINGS_SHOW_TOTAL_TITLE = "Mostrar Total"
	L.BROKER_SETTINGS_SHOW_TOTAL_TOOLTIP = "Número total"
	L.BROKER_SETTINGS_SHOW_GROUPS_TITLE = "Dividir"
	L.BROKER_SETTINGS_SHOW_GROUPS_TOOLTIP = "Separar WoW/BNet"
	L.BROKER_SETTINGS_SHOW_WOW_ICON = "Ícone WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TITLE = "Mostrar Ícone WoW"
	L.BROKER_SETTINGS_SHOW_WOW_ICON_TOOLTIP = "Ícone amigos WoW"
	L.BROKER_SETTINGS_SHOW_BNET_ICON = "Ícone BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TITLE = "Mostrar Ícone BNet"
	L.BROKER_SETTINGS_SHOW_BNET_ICON_TOOLTIP = "Ícone amigos BNet"
	L.BROKER_SETTINGS_CLICK_ACTION = "Ação Clique"
	L.BROKER_SETTINGS_TOOLTIP_MODE = "Modo Tooltip"
	L.STATUS_ENABLED = "|cff00ff00Ativado|r"
	L.STATUS_DISABLED = "|cffff0000Desativado|r"
	L.BROKER_WOW_FRIENDS = "Amigos WoW:"

	-- Settings (Global Sync)
	L.SETTINGS_TAB_GLOBAL_SYNC = "Sync Global"
	L.SETTINGS_GLOBAL_SYNC_ENABLE_TOOLTIP = "Ativar sync amigos"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED = "Mostrar Excluídos"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TITLE = "Mostrar Amigos Excluídos"
	L.SETTINGS_GLOBAL_SYNC_SHOW_DELETED_TOOLTIP = "Mostra excluídos na lista"
	L.TOOLTIP_RESTORE_FRIEND = "Restaurar"
	L.TOOLTIP_DELETE_FRIEND = "Excluir"
	L.POPUP_EDIT_NOTE_TITLE = "Editar Nota"
	L.BUTTON_SAVE = "Salvar"
	L.BUTTON_CANCEL = "Canc."

	-- Broker (Additional)
	L.BROKER_LABEL_FRIENDS = "Amigos: "
	L.BROKER_ONLINE_TOTAL = "%d online / %d tot"
	L.BROKER_CURRENT_FILTER = "Filtro:"
	L.BROKER_HINT_CYCLE_FILTER_FULL = "Clique Meio: Ciclar Filtro"
	L.BROKER_AND_MORE = "  ... e %d outros"
	L.BROKER_TOTAL_LABEL = "Total:"
	L.BROKER_ONLINE_FRIENDS_COUNT = "%d online / %d amigos"
	L.MENU_CHANGE_COLOR = "Mudar Cor"
	L.ERROR_TOOLTIP_DISPLAY = "|cffff0000Erro tooltip|r"
	L.STATUS_LABEL = "Status:"
	L.STATUS_AWAY = "Ausente"
	L.STATUS_DND_FULL = "Não Perturbe"
	L.GAME_LABEL = "Jogo:"
	L.REALM_LABEL = "Reino:"
	L.CLASS_LABEL = "Classe:"
	L.FACTION_LABEL = "Facção:"
	L.ZONE_LABEL = "Zona:"
	L.NOTE_LABEL = "Nota:"
	L.BROADCAST_LABEL = "Msg:"
	L.ACTIVE_SINCE_FMT = "(Ativo desde: %s)"
	L.HINT_RIGHT_CLICK_OPTIONS = "Clique-dir opções"
	L.HEADER_ADD_FRIEND = "|cffffd700Adic. %s a %s|r"

	-- Groups (Additional)
	L.MIGRATION_DEBUG_TOTAL = "Debug Migra - Total:"
	L.MIGRATION_DEBUG_BNET = "Debug Migra - BNet velho:"
	L.MIGRATION_DEBUG_WOW = "Debug Migra - WoW sem reino:"
	L.ERROR_INVALID_PARAMS = "Parâmetros inválidos"

	-- Ignore List
	L.IGNORE_LIST_UNIGNORE = "Não ignorar"

	-- ========================================
	-- RECENT ALLIES (Retail 11.0.7+)
	-- ========================================
	L.RECENT_ALLIES_SYSTEM_UNAVAILABLE = "Aliados Recentes indisp."
	L.RECENT_ALLIES_INVITE = "Convidar"
	L.RECENT_ALLIES_PLAYER_OFFLINE = "Jogador offline"
	L.RECENT_ALLIES_PIN_EXPIRES = "Pin expira em %s"
	L.RECENT_ALLIES_LEVEL_RACE = "Nv %d %s"
	L.RECENT_ALLIES_NOTE = "Nota: %s"
	L.RECENT_ALLIES_ACTIVITY = "Atividade Recente:"

	-- ========================================
	-- RECRUIT A FRIEND (RAF)
	-- ========================================
	L.RECRUIT_A_FRIEND = "Recrute um Amigo"
	L.RAF_RECRUITMENT = "Recrutamento"
	L.RAF_NO_RECRUITS_DESC = "Sem recrutados."
	L.RAF_PENDING_RECRUIT = "Pendente"
	L.RAF_RECRUIT_NAME_MULTIPLE = "%s (%d)"
	L.RAF_RECRUITED_FRIENDS_COUNT = "%d / %d"
	L.RAF_YOU_HAVE_EARNED = "Ganhou:"
	L.RAF_NEXT_REWARD_AFTER = "Próxima em %d/%d meses"
	L.RAF_FIRST_REWARD = "Primeira:"
	L.RAF_NEXT_REWARD = "Próxima:"
	L.RAF_REWARD_MOUNT = "Montaria"
	L.RAF_REWARD_TITLE_DEFAULT = "Título"
	L.RAF_REWARD_TITLE_FMT = "Título: %s"
	L.RAF_REWARD_GAMETIME = "Tempo de Jogo"
	L.RAF_MONTH_COUNT = "%d Meses"
	L.RAF_CLAIM_REWARD = "Resgatar"
	L.RAF_VIEW_ALL_REWARDS = "Ver Tudo"
	L.RAF_ACTIVE_RECRUIT = "Ativo"
	L.RAF_TRIAL_RECRUIT = "Teste"
	L.RAF_INACTIVE_RECRUIT = "Inativo"
	L.RAF_OFFLINE = "Offline"
	L.RAF_TOOLTIP_DESC = "Até %d meses"
	L.RAF_TOOLTIP_MONTH_COUNT = "%d / %d meses"
	L.RAF_ACTIVITY_DESCRIPTION = "Atividade para %s"
	L.RAF_REWARDS_LABEL = "Recompensas"
	L.RAF_YOU_EARNED_LABEL = "Ganhou:"
	L.RAF_CLICK_TO_CLAIM = "Clique para resgatar"
	L.RAF_LOADING = "Carregando..."
	L.RAF_CHAT_HEADER = "|cff00ff00=== RAF ===|r"
	L.RAF_CHAT_CURRENT_VERSION = "RAF Atual"
	L.RAF_CHAT_LEGACY_VERSION = "RAF Antigo v%s"
	L.RAF_CHAT_MONTHS_EARNED = "  Meses: %d"
	L.RAF_CHAT_RECRUITS_COUNT = "  Recrutas: %d"
	L.RAF_CHAT_AVAILABLE_REWARDS = "  Recomp Disp:"
	L.RAF_CHAT_REWARD_CLAIMED = "|cff00ff00[Pego]|r"
	L.RAF_CHAT_REWARD_CAN_CLAIM = "|cffffff00[Pegável]|r"
	L.RAF_CHAT_REWARD_AFFORDABLE = "|cffff9900[Acessível]|r"
	L.RAF_CHAT_REWARD_LOCKED = "|cff666666[Travado]|r"
	L.RAF_CHAT_REWARD_FMT = "    - %s %s (%d meses)"
	L.RAF_CHAT_MORE_REWARDS = "    ... e %d outros"
	L.RAF_CHAT_USE_UI = "|cff00ff00Use UI para detalhes.|r"
	L.RAF_GAME_TIME_MESSAGE = "|cff00ff00RAF:|r Tempo jogo disponível."

	-- ========================================
	-- SETTINGS (Additional)
	-- ========================================
	L.SETTINGS_SHOW_WELCOME_MESSAGE = "Mostrar mensagem de boas-vindas"
	L.SETTINGS_SHOW_WELCOME_MESSAGE_DESC = "Mostra a mensagem de carregamento do addon no chat ao entrar."
	L.SETTINGS_TAB_DATABROKER = "Data Broker"
	L.MSG_GROUP_RENAMED = "Grupo renomeado '%s'"
	L.ERROR_RENAME_FAILED = "Renomear falhou"
	L.SETTINGS_GROUP_ORDER_SAVED_DEBUG = "Ord. grupos: %s"
	L.ERROR_EXPORT_SERIALIZE = "Err. serialização"
	L.ERROR_IMPORT_EMPTY = "String vazia"
	L.ERROR_IMPORT_DECODE = "Err. decodificação"
	L.ERROR_IMPORT_DESERIALIZE = "Err. desserialização"
	L.ERROR_EXPORT_VERSION = "Versão não suportada"
	L.ERROR_EXPORT_STRUCTURE = "Estrutura inválida"

	-- Statistics
	L.STATS_NO_HEALTH_DATA = "Sem dados saúde"
	L.STATS_NO_CLASS_DATA = "Sem dados classe"
	L.STATS_NO_LEVEL_DATA = "Sem dados nível"
	L.STATS_NO_REALM_DATA = "Sem dados reino"
	L.STATS_NO_GAME_DATA = "Sem dados jogo"
	L.STATS_NO_MOBILE_DATA = "Sem dados mobile"
	L.STATS_SAME_REALM = "Mesmo Reino: %d (%d%%)  |  Outros: %d (%d%%)"
	L.STATS_TOP_REALMS = "\nTop Reinos:"
	L.STATS_GAME_WOW = "WoW: %d"
	L.STATS_GAME_CLASSIC = "\nClassic: %d"
	L.STATS_GAME_DIABLO = "\nDiablo IV: %d"
	L.STATS_GAME_HEARTHSTONE = "\nHearthstone: %d"
	L.STATS_GAME_MOBILE = "\nMobile: %d"
	L.STATS_GAME_OTHER = "\nOutros: %d"
	L.STATS_MOBILE_DESKTOP = "PC: %d (%d%%)\nMobile: %d (%d%%)"
	L.STATS_NOTES_FAVORITES = "Notas: %d (%d%%)\nFavoritos: %d (%d%%)"
	L.STATS_MAX_LEVEL = "Max: %d\n70-79: %d\n60-69: %d\n<60: %d\nMédia: %.1f"
	L.STATS_HEALTH_FMT =
		"|cff00ff00Ativo: %d (%d%%)|r\n|cffffd700Médio: %d (%d%%)|r\n|cffffaa00Velho: %d (%d%%)|r\n|cffff6600Parado: %d (%d%%)|r\n|cffff0000Inativo: %d (%d%%)|r"
	L.STATS_CLASS_FMT = "%d. %s: %d (%d%%)"
	L.STATS_FACTION_DISTRIBUTION = "|cff0080ffAliança: %d|r\n|cffff0000Horda: %d|r"
	L.STATS_REALM_FMT = "\n%d. %s: %d"
	L.TOOLTIP_MOVE_DOWN = "Mover Baixo"
	L.TOOLTIP_MOVE_DOWN_DESC = "Mover grupo baixo"
	L.TOOLTIP_MOVE_UP = "Mover Cima"
	L.TOOLTIP_MOVE_UP_DESC = "Mover grupo cima"

	-- TRAVEL PASS
	L.TRAVEL_PASS_NOT_WOW = "Amigo não WoW"
	L.TRAVEL_PASS_WOW_CLASSIC = "Amigo WoW Classic."
	L.TRAVEL_PASS_WOW_MAINLINE = "Amigo WoW."
	L.TRAVEL_PASS_DIFFERENT_VERSION = "Versão diferente"
	L.TRAVEL_PASS_NO_INFO = "Info insuficiente"
	L.TRAVEL_PASS_DIFFERENT_REGION = "Região diferente"
	L.TRAVEL_PASS_NO_GAME_ACCOUNTS = "Sem conta jogo"
	L.TRAVEL_PASS_DIFFERENT_FACTION = "O amigo está na facção oposta"
	L.TRAVEL_PASS_QUEST_SESSION = "Não é possível convidar durante uma sessão de missão"

	-- MENUS (Additional)
	L.MENU_TITLE = "BetterFriendlist"
	L.MENU_SHOW_BLIZZARD = "Mostrar Lista Blizzard"
	L.MENU_COMBAT_LOCKED = "Travado combate"
	L.MENU_SET_NICKNAME = "Definir Apelido"

	-- ========================================
	-- XML LOCALIZATION KEYS
	-- ========================================
	L.SETTINGS_TITLE = "Config BetterFriendlist"
	L.SEARCH_FRIENDS_INSTRUCTION = "Buscar..."
	L.SEARCH_RECENT_ALLIES_INSTRUCTION = "Buscar aliados recentes..."
	L.SEARCH_RAF_INSTRUCTION = "Buscar amigos recrutados..."
	L.RAF_NEXT_REWARD_HELP = "Info RAF"
	L.WHO_LEVEL_FORMAT = "Nível %d"
	L.CONTACTS_RECENT_ALLIES_TAB_NAME = "Aliados Recentes"
	L.CONTACTS_MENU_NAME = "Menu Contatos"
	L.BATTLENET_UNAVAILABLE = "BNet Indisp"
	L.BATTLENET_BROADCAST = "Difusão"
	L.FRIENDS_LIST_ENTER_TEXT = "Msg..."
	L.WHO_LIST_SEARCH_INSTRUCTIONS = "Buscar..."
	L.RAF_SPLASH_SCREEN_TITLE = "RAF"
	L.RAF_SPLASH_SCREEN_DESCRIPTION = "Recrute amigos!"
	L.RAF_NEXT_REWARD_HELP_TEXT = "Info Recomp"

	-- ========================================
	-- MISSING SETTINGS KEYS
	-- ========================================
	-- Name Formatting
	L.SETTINGS_NAME_FORMAT_HEADER = "Formato Nome"
	L.SETTINGS_NAME_FORMAT_DESC =
		"Use tokens para personalizar a exibicao:\n|cffFFD100%name%|r - Nome da conta\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Apelido\n|cffFFD100%note%|r - Nota\n|cffFFD100%character%|r - Nome do personagem\n|cffFFD100%realm%|r - Nome do reino\n|cffFFD100%level%|r - Nivel\n|cffFFD100%zone%|r - Zona\n|cffFFD100%class%|r - Classe\n|cffFFD100%game%|r - Jogo"
	L.SETTINGS_NAME_FORMAT_LABEL = "Modelo:"
	L.SETTINGS_NAME_FORMAT_TOOLTIP = "Formato Nome"
	L.SETTINGS_NAME_FORMAT_TOOLTIP_DESC = "Insira formato."
	L.SETTINGS_NAME_FORMAT_DISABLED_FRIENDLISTCOLORS =
		"Esta configuração está desabilitada porque o addon 'FriendListColors' está gerenciando cores/formatos de nomes."

	-- Name Format Preset Labels (Phase 22)
	L.NAME_PRESET_DEFAULT = "Nome (Personagem)"
	L.NAME_PRESET_BATTLETAG = "BattleTag (Personagem)"
	L.NAME_PRESET_NICKNAME = "Apelido (Personagem)"
	L.NAME_PRESET_NAME_ONLY = "Somente Nome"
	L.NAME_PRESET_CHARACTER = "Somente Personagem"
	L.NAME_PRESET_CUSTOM = "Personalizado..."
	L.SETTINGS_NAME_FORMAT_CUSTOM_LABEL = "Formato personalizado:"

	-- Info Format Section (Phase 22)
	L.SETTINGS_INFO_FORMAT_HEADER = "Formatacao de info de amigos"
	L.SETTINGS_INFO_FORMAT_LABEL = "Modelo:"
	L.SETTINGS_INFO_FORMAT_CUSTOM_LABEL = "Formato personalizado:"
	L.SETTINGS_INFO_FORMAT_TOOLTIP = "Formato de Info Personalizado"
	L.SETTINGS_INFO_FORMAT_DESC =
		"Use tokens para personalizar a linha de info:\n|cffFFD100%level%|r - Nivel do personagem\n|cffFFD100%zone%|r - Zona atual\n|cffFFD100%class%|r - Nome da classe\n|cffFFD100%game%|r - Nome do jogo\n|cffFFD100%realm%|r - Nome do reino\n|cffFFD100%status%|r - AFK/DND/Online\n|cffFFD100%lastonline%|r - Ultimo acesso\n|cffFFD100%name%|r - Nome da conta\n|cffFFD100%battletag%|r - BattleTag\n|cffFFD100%nickname%|r - Apelido\n|cffFFD100%note%|r - Nota\n|cffFFD100%character%|r - Nome do personagem"
	L.INFO_PRESET_DEFAULT = "Padrao (Nivel, Zona)"
	L.INFO_PRESET_ZONE = "Somente Zona"
	L.INFO_PRESET_LEVEL = "Somente Nivel"
	L.INFO_PRESET_CLASS_ZONE = "Classe, Zona"
	L.INFO_PRESET_LEVEL_CLASS_ZONE = "Nivel Classe, Zona"
	L.INFO_PRESET_GAME = "Nome do jogo"
	L.INFO_PRESET_DISABLED = "Desativado (Ocultar info)"
	L.INFO_PRESET_CUSTOM = "Personalizado..."

	-- In-Game Group
	L.SETTINGS_SHOW_INGAME_GROUP = "Grupo 'No Jogo'"
	L.SETTINGS_SHOW_INGAME_GROUP_DESC = "Agrupa amigos no jogo"
	L.SETTINGS_INGAME_MODE_WOW = "Apenas WoW"
	L.SETTINGS_INGAME_MODE_ANY = "Qualquer Jogo"
	L.SETTINGS_INGAME_MODE_LABEL = "   Modo:"
	L.SETTINGS_INGAME_MODE_TOOLTIP = "Modo"
	L.SETTINGS_INGAME_MODE_TOOLTIP_DESC = "Escolha amigos."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT = "   Unidade de duração:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_DESC =
		"Escolha a unidade de tempo para quanto tempo os amigos permanecem no grupo Adicionados recentemente."
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE = "   Valor da duração:"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_DESC =
		"Quantos dias/horas/minutos os amigos permanecem no grupo Adicionados recentemente antes de serem removidos."
	L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT_TOOLTIP = "Unidade de duração"
	L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE_TOOLTIP = "Valor da duração"
	L.SETTINGS_DURATION_DAYS = "Dias"
	L.SETTINGS_DURATION_HOURS = "Horas"
	L.SETTINGS_DURATION_MINUTES = "Minutos"

	-- Headers & Titles
	L.SETTINGS_DISPLAY_OPTIONS = "Opções Exibição"
	L.SETTINGS_BEHAVIOR_HEADER = "Comportamento"
	L.SETTINGS_GROUP_MANAGEMENT = "Gestão Grupos"
	L.SETTINGS_FONT_SETTINGS = "Fonte"
	L.SETTINGS_GROUP_ORDER = "Ordem Grupos"
	L.SETTINGS_MIGRATION_HEADER = "Migração FriendGroups"
	L.SETTINGS_MIGRATION_DESC = "Migrar do FriendGroups."
	L.SETTINGS_MIGRATE_BTN = "Migrar"
	L.SETTINGS_MIGRATE_TOOLTIP = "Importar"
	L.SETTINGS_EXPORT_HEADER = "Export / Import"
	L.SETTINGS_EXPORT_DESC = "Compartilhar config."
	L.SETTINGS_EXPORT_WARNING = "|cffff0000Aviso: Sobrescreve!|r"
	L.SETTINGS_EXPORT_TOOLTIP = "Exportar"
	L.SETTINGS_IMPORT_TOOLTIP = "Importar"

	-- Statistics
	L.STATS_HEADER = "Estatísticas"
	L.STATS_DESC = "Sumário"
	L.STATS_OVERVIEW_HEADER = "Sumário"
	L.STATS_HEALTH_HEADER = "Saúde"
	L.STATS_CLASSES_HEADER = "Top 5 Classes"
	L.STATS_REALMS_HEADER = "Reinos"
	L.STATS_ORGANIZATION_HEADER = "Org"
	L.STATS_LEVELS_HEADER = "Níveis"
	L.STATS_GAMES_HEADER = "Jogos"
	L.STATS_MOBILE_HEADER = "Móvel vs PC"
	L.STATS_FACTIONS_HEADER = "Facções"
	L.STATS_REFRESH_BTN = "Atualizar"
	L.STATS_REFRESH_TOOLTIP = "Atualizar dados"

	-- Notifications (Detailed)

	-- Quiet Hours & Filters

	-- Notification Toggles

	-- Missing Descriptions
	L.SETTINGS_HIDE_EMPTY_GROUPS_DESC = "Ocultar vazios"
	L.SETTINGS_SHOW_FACTION_ICONS_DESC = "Mostrar ícones facção"
	L.SETTINGS_SHOW_REALM_NAME_DESC = "Mostrar reino"
	L.SETTINGS_GRAY_OTHER_FACTION_DESC = "Atenuar outros"
	L.SETTINGS_SHOW_MOBILE_AS_AFK_DESC = "Mobile como AFK"
	L.SETTINGS_HIDE_MAX_LEVEL_DESC = "Ocultar nv max"
	L.SETTINGS_SHOW_BLIZZARD_DESC = "Mostrar bot Blizzard"
	L.SETTINGS_SHOW_FAVORITES_DESC = "Mostrar Favoritos"
	L.SETTINGS_ACCORDION_GROUPS_DESC = "Um aberto"
	L.SETTINGS_COMPACT_MODE_DESC = "Compacto"

	-- ElvUI & UI Panel
	L.SETTINGS_ENABLE_ELVUI_SKIN = "Ativar Skin ElvUI"
	L.SETTINGS_ENABLE_ELVUI_SKIN_DESC = "Requer ElvUI."
	L.DIALOG_ELVUI_RELOAD_TEXT = "Recarregar necessário.\nRecarregar?"
	L.DIALOG_ELVUI_RELOAD_BTN1 = "Sim"
	L.DIALOG_ELVUI_RELOAD_BTN2 = "Não"

	-- ========================================
	-- CORE LOCALIZATION STRINGS (PHASE 16)
	-- ========================================
	L.CORE_DB_NOT_INIT = "DB não init."
	L.CORE_SHOW_BLIZZARD_ENABLED = "Opção Blizzard |cff20ff20ON|r"
	L.CORE_SHOW_BLIZZARD_DISABLED = "Opção Blizzard |cffff0000OFF|r"
	L.CORE_DEBUG_DB_NOT_AVAIL = "Debug indisp"
	L.CORE_DB_MODULE_NOT_AVAIL = "Módulo DB indisp"
	L.CORE_ACTIVITY_TRACKING_HEADER = "|cff00ff00=== Atividade ===|r"
	L.CORE_ACTIVITY_TOTAL_FRIENDS = "Amigos ativos: %d"
	L.CORE_BETA_FEATURES_DISABLED_MSG = "Beta desativado!"
	L.CORE_BETA_ENABLE_HINT = "|cffffcc00Ativar:|r ESC > AddOns > BFL"
	L.CORE_STATISTICS_MODULE_NOT_LOADED = "Stats não carregadas"
	L.CORE_STATISTICS_HEADER = "|cff00ff00=== Estatísticas ===|r"
	L.CORE_STATS_OVERVIEW = "|cffffcc00Sumário:|r"
	L.CORE_STATS_TOTAL_ONLINE_OFFLINE =
		"  Tot: |cffffffff%d|r  On: |cff00ff00%d|r (%.0f%%)  Off: |cffaaaaaa%d|r (%.0f%%)"
	L.CORE_STATS_BNET_WOW = "  BNet: |cff0099ff%d|r  |  WoW: |cffffd700%d|r"
	L.CORE_STATS_FRIENDSHIP_HEALTH = "|cffffcc00Saúde:|r"
	L.CORE_STATS_HEALTH_ACTIVE = "  Ativo: |cff00ff00%d|r  Médio: |cffffd700%d|r"
	L.CORE_STATS_HEALTH_STALE = "  Velho: |cffff6600%d|r  Dormiente: |cffff0000%d|r"
	L.CORE_STATS_NO_HEALTH_DATA = "  Sem dados"
	L.CORE_STATS_CLASS_DISTRIBUTION = "|cffffcc00Classes:|r"
	L.CORE_STATS_LEVEL_DISTRIBUTION = "|cffffcc00Níveis:|r"
	L.CORE_STATS_LEVEL_BREAKDOWN =
		"  Max: |cffffffff%d|r  70+: |cffffffff%d|r  60+: |cffffffff%d|r  <60: |cffffffff%d|r"
	L.CORE_STATS_AVG_LEVEL = "  Média: |cffffffff%.1f|r"
	L.CORE_STATS_REALM_CLUSTERS = "|cffffcc00Reinos:|r"
	L.CORE_STATS_REALM_BREAKDOWN = "  Mesmo: |cffffffff%d|r  |  Outro: |cffffffff%d|r"
	L.CORE_STATS_TOP_REALMS = "  Top:"
	L.CORE_STATS_FACTION_SPLIT = "|cffffcc00Facções:|r"
	L.CORE_STATS_FACTION_DATA = "  Ali: |cff0080ff%d|r  |  Horda: |cffff0000%d|r"
	L.CORE_STATS_GAME_DISTRIBUTION = "|cffffcc00Jogos:|r"
	L.CORE_STATS_GAME_WOW = "  Retail: |cffffffff%d|r"
	L.CORE_STATS_GAME_CLASSIC = "  Classic: |cffffffff%d|r"
	L.CORE_STATS_GAME_DIABLO = "  D4: |cffffffff%d|r"
	L.CORE_STATS_GAME_HEARTHSTONE = "  HS: |cffffffff%d|r"
	L.CORE_STATS_GAME_STARCRAFT = "  SC: |cffffffff%d|r"
	L.CORE_STATS_GAME_MOBILE = "  App: |cffffffff%d|r"
	L.CORE_STATS_GAME_OTHER = "  Outros: |cffffffff%d|r"
	L.CORE_STATS_MOBILE_VS_DESKTOP = "|cffffcc00Mobile vs PC:|r"
	L.CORE_STATS_MOBILE_DATA = "  PC: |cffffffff%d|r (%.0f%%)  Mobile: |cffffffff%d|r (%.0f%%)"
	L.CORE_STATS_ORGANIZATION = "|cffffcc00Org:|r"
	L.CORE_STATS_ORG_DATA = "  Notas: |cffffffff%d|r  Fav: |cffffffff%d|r"
	L.CORE_SETTINGS_NOT_LOADED = "Config não carregada"
	L.CORE_MOCK_INVITES_ENABLED = "Inv. Teste |cff00ff00ON|r"
	L.CORE_MOCK_INVITE_ADDED = "Adic inv. teste |cffffffff%s|r"
	L.CORE_MOCK_INVITE_TIP = "|cffffcc00Dica:|r /bfl clearinvites"
	L.CORE_MOCK_INVITES_CLEARED = "Limpo"
	L.CORE_NO_MOCK_INVITES = "Sem convites"
	L.CORE_PERF_MONITOR_NOT_LOADED = "Monitor não carreg."
	L.CORE_MEMORY_USAGE = "Mem: %.2f KB"
	L.CORE_QUICKJOIN_NOT_LOADED = "QJ não carreg."
	L.CORE_RAIDFRAME_NOT_LOADED = "RaidFrame não carreg."
	L.CORE_PREVIEW_MODE_NOT_LOADED = "Preview não carreg."
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
	L.CORE_COMPAT_ACTIVE = "|cff00ff00Ativo|r"
	L.CORE_COMPAT_NOT_LOADED = "|cffff0000Não Carregado|r"
	L.CORE_CHANGELOG_RESET = "Changelog reset."
	L.CORE_CHANGELOG_NOT_LOADED = "Changelog não carregado"
	L.CORE_DEBUG_PANEL_HEADER = "|cff00ff00=== Debug ===|r"
	L.CORE_DEBUG_BLIZZARD_SETTINGS = "|cffffcc00Blizzard:|r"
	L.CORE_DEBUG_NO_STORED = "|cffff0000Sem settings|r"
	L.CORE_DEBUG_BFL_ATTRS = "|cffffcc00BFL attrs:|r"
	L.CORE_DEBUG_UIPANEL_YES = "|cffffcc00Em UIPanel:|r |cff00ff00SIM|r"
	L.CORE_DEBUG_UIPANEL_NO = "|cffffcc00Em UIPanel:|r |cffff0000NÃO|r"
	L.CORE_DEBUG_FRIENDSFRAME_WARNING = "|cffff8800AVISO:|r FriendsFrame no UIPanel!"
	L.CORE_DEBUG_CURRENT_SETTING = "|cffffcc00Setting:|r %s"
	L.CORE_HELP_TITLE = "|cff00ff00=== BFL v%s ===|r"
	L.CORE_HELP_MAIN_COMMANDS = "|cffffcc00Comandos:|r"
	L.CORE_HELP_CMD_TOGGLE = "  |cffffffff/bfl|r - Alternar"
	L.CORE_HELP_CMD_SETTINGS = "  |cffffffff/bfl settings|r - Config"
	L.CORE_HELP_CMD_HELP = "  |cffffffff/bfl help|r - Ajuda"
	L.CORE_HELP_CMD_CHANGELOG = "  |cffffffff/bfl changelog|r - Abrir registro de alterações"
	L.CORE_HELP_CMD_RESET = "  |cffffffff/bfl reset|r - Redefinir posição da janela"
	L.CORE_HELP_DEBUG_COMMANDS = "|cffffcc00Debug:|r"
	L.CORE_HELP_CMD_DEBUG = "  |cffffffff/bfl debug|r - Alternar debug"
	L.CORE_HELP_CMD_DATABASE = "  |cffffffff/bfl database|r - Ver DB"
	L.CORE_HELP_CMD_ACTIVITY = "  |cffffffff/bfl activity|r - Ver atividade"
	L.CORE_HELP_CMD_STATS = "  |cffffffff/bfl stats|r - Ver stats"
	L.CORE_HELP_CMD_TESTGROUP = "  |cffffffff/bfl testgrouprules|r - Teste regras"
	L.CORE_HELP_QJ_COMMANDS = "|cffffcc00Quick Join:|r"
	L.CORE_HELP_QJ_MOCK = "  |cffffffff/bfl qj mock|r - Mock"
	L.CORE_HELP_QJ_DUNGEON = "  |cffffffff/bfl qj mock dungeon|r - Masmorra"
	L.CORE_HELP_QJ_PVP = "  |cffffffff/bfl qj mock pvp|r - PvP"
	L.CORE_HELP_QJ_RAID = "  |cffffffff/bfl qj mock raid|r - Raide"
	L.CORE_HELP_QJ_STRESS = "  |cffffffff/bfl qj mock stress|r - Stress"
	L.CORE_HELP_QJ_EVENT = "  |cffffffff/bfl qj event|r - Eventos"
	L.CORE_HELP_QJ_CLEAR = "  |cffffffff/bfl qj clear|r - Limpar"
	L.CORE_HELP_QJ_LIST = "  |cffffffff/bfl qj list|r - Lista"
	L.CORE_HELP_MOCK_COMMANDS = "|cffffcc00Mock:|r"
	L.CORE_HELP_MOCK_OLD = "  |cffffffff/bfl mock|r - Criar raide"
	L.CORE_HELP_INVITE = "  |cffffffff/bfl invite|r - Convite"
	L.CORE_HELP_CLEARINVITES = "  |cffffffff/bfl clearinvites|r - Limpar convites"
	L.CORE_HELP_PREVIEW_COMMANDS = "|cffffcc00Preview:|r"
	L.CORE_HELP_PREVIEW_ON = "  |cffffffff/bfl preview|r - On"
	L.CORE_HELP_PREVIEW_OFF = "  |cffffffff/bfl preview off|r - Off"
	L.CORE_HELP_PREVIEW_DESC = "  |cff888888(Dados falsos)|r"
	L.CORE_HELP_RAID_COMMANDS = "|cffffcc00Raid Frame:|r"
	L.CORE_HELP_RAID_MOCK = "  |cffffffff/bfl raid mock|r - 25j"
	L.CORE_HELP_RAID_FULL = "  |cffffffff/bfl raid mock full|r - 40j"
	L.CORE_HELP_RAID_SMALL = "  |cffffffff/bfl raid mock small|r - 10j"
	L.CORE_HELP_RAID_MYTHIC = "  |cffffffff/bfl raid mock mythic|r - 20j"
	L.CORE_HELP_RAID_READY = "  |cffffffff/bfl raid event readycheck|r - RC Sim"
	L.CORE_HELP_RAID_ROLE = "  |cffffffff/bfl raid event rolechange|r - Função Sim"
	L.CORE_HELP_RAID_MOVE = "  |cffffffff/bfl raid event move|r - Mov. Sim"
	L.CORE_HELP_RAID_CLEAR = "  |cffffffff/bfl raid clear|r - Limpar"
	L.CORE_HELP_PERF_COMMANDS = "|cffffcc00Perf:|r"
	L.CORE_HELP_PERF_SHOW = "  |cffffffff/bfl perf|r - Show"
	L.CORE_HELP_PERF_ENABLE = "  |cffffffff/bfl perf enable|r - Ativar"
	L.CORE_HELP_PERF_RESET = "  |cffffffff/bfl perf reset|r - Reset"
	L.CORE_HELP_PERF_MEM = "  |cffffffff/bfl perf memory|r - Memória"
	L.CORE_HELP_TEST_COMMANDS = "|cffffcc00Teste:|r"
	L.TESTSUITE_PERFY_HELP = "  |cffffffff/bfl test perfy [seconds]|r - Run Perfy stress test"
	L.TESTSUITE_PERFY_STARTING = "Starting Perfy stress test for %d seconds"
	L.TESTSUITE_PERFY_ALREADY_RUNNING = "Perfy stress test already running"
	L.TESTSUITE_PERFY_MISSING_ADDON = "Perfy addon not loaded (!!!Perfy)"
	L.TESTSUITE_PERFY_MISSING_SLASH = "Perfy slash command not available"
	L.TESTSUITE_PERFY_ACTION_FAILED = "Perfy stress action failed: %s"
	L.TESTSUITE_PERFY_DONE = "Perfy stress test finished"
	L.TESTSUITE_PERFY_ABORTED = "Perfy stress test stopped: %s"
	L.CORE_HELP_LINK = "|cff20ff20Ajuda:|r |cff00ccffhttps://github.com/Hayato2846/BetterFriendlist|r"
	L.CORE_LOADED = "|cff00ff00BetterFriendlist v%s%s|r. Carregado. Discord: /bfl discord"
	L.MOCK_INVITE_ACCEPTED = "Aceitou %s"
	L.MOCK_INVITE_DECLINED = "Recusou %s"

	-- Performance Monitor
	L.PERF_STATS_RESET = "Stats reset"
	L.PERF_REPORT_HEADER = "|cff00ff00=== Perf ===|r"
	L.PERF_QJ_OPS = "|cffffd700QJ Ops:|r"
	L.PERF_FRIENDS_OPS = "|cffffd700Amigos Ops:|r"
	L.PERF_MEMORY = "|cffffd700Memória:|r"
	L.PERF_TARGETS = "|cffffd700Alvo:|r"
	L.PERF_AUTO_ENABLED = "Auto-monitor |cff00ff00ON|r"

	-- RaidFrame
	L.RAID_MOCK_CREATED_25 = "Criado 25j"
	L.RAID_MOCK_CREATED_40 = "Criado 40j"
	L.RAID_MOCK_CREATED_10 = "Criado 10j"
	L.RAID_MOCK_CREATED_MYTHIC = "Criado 20j (M)"
	L.RAID_MOCK_STRESS = "Stress test"
	L.RAID_WARN_CPU = "|cffff8800Aviso:|r CPU alta"
	L.RAID_NO_MOCK_DATA = "Sem dados. '/bfl raid mock'"
	L.RAID_SIM_READY_CHECK = "Sim Ready Check..."
	L.RAID_MOCK_CLEARED = "Limpo"
	L.RAID_EVENT_COMMANDS = "|cff00ff00Eventos Raid:|r"
	L.RAID_HELP_MANAGEMENT = "|cffffcc00Gestão:|r"
	L.RAID_CMD_CONFIG = "  |cffffffff/bfl raid config|r - Config"
	L.RAID_CMD_LIST = "  |cffffffff/bfl raid list|r - Lista"
	L.RAID_CMD_STRESS = "  |cffffffff/bfl raid mock stress|r - Stress"
	L.RAID_HELP_EVENTS = "|cffffcc00Sim:|r"
	L.RAID_CONFIG_HEADER = "|cff00ff00Config Raid:|r"
	L.RAID_INFO_HEADER = "|cff00ff00Info Mock:|r"
	L.RAID_NO_MOCK_ACTIVE = "Sem mock"
	L.RAID_DYN_UPDATES = "Updates: %s"
	L.RAID_UPDATE_INTERVAL = "Int: %.1f s"
	L.RAID_MOCK_ENABLED_STATUS = "  Mock: %s"
	L.RAID_DYN_UPDATES_STATUS = "  Dyn: %s"
	L.RAID_UPDATE_INTERVAL_STATUS = "  Int: %.1f s"
	L.RAID_MEMBERS_STATUS = "  Membros: %d"
	L.RAID_TOTAL_MEMBERS = "  Tot: %d"
	L.RAID_COMPOSITION = "  Comp: %d T, %d H, %d D"
	L.RAID_STATUS = "  Status: %d off, %d mortos"

	-- QuickJoin
	L.QJ_MOCK_CREATED_FALLBACK = "Criado teste ícones"
	L.QJ_MOCK_CREATED_STRESS = "Criado teste 50"
	L.QJ_SIM_ADDED = "Sim: Adicionado"
	L.QJ_SIM_REMOVED = "Sim: Removido"
	L.QJ_ERR_NO_GROUPS_REMOVE = "Nada para remover"
	L.QJ_ERR_NO_GROUPS_UPDATE = "Nada para atualizar"
	L.QJ_EVENT_COMMANDS = "|cff00ff00Eventos QJ:|r"
	L.QJ_LIST_HEADER = "|cff00ff00Grupos QJ:|r"
	L.QJ_CONFIG_HEADER = "|cff00ff00Config QJ:|r"
	L.QJ_EXT_FOOTER = "|cff888888Mock verdes.|r"
	L.QJ_SIM_UPDATED_FMT = "Sim: %s atual."
	L.QJ_ADDED_GROUP_FMT = "Adicionado: %s"
	L.QJ_NO_GROUPS_HINT = "Sem grupos."
	L.QJ_MOCK_ICONS_HELP = "  |cffffcc00/bfl qj mock icons|r - Ícones"
	L.HELP_HEADER_CONFIGURATION = "|cffffcc00Config:|r"
	L.QJ_CMD_CONFIG_HELP = "  |cffffcc00/bfl qj config|r - Config"

	-- BetterFriendlist.lua
	L.CMD_RESET_FILTER_SUCCESS = "Reset Guild UI warning."
	L.CMD_RESET_HEADER = "Reset:"
	L.CMD_RESET_HELP_WARNING = "Reset Guild warning"

	-- Changelog.lua
	L.CHANGELOG_DISCORD = "   Discord"
	L.CHANGELOG_GITHUB = "   GitHub Issues"
	L.CHANGELOG_SUPPORT = "   Suporte"
	L.CHANGELOG_HEADER_COMMUNITY = "Comunidade:"
	L.CHANGELOG_HEADER_VERSION = "Ver %s"
	L.CHANGELOG_TOOLTIP_UPDATE = "Nova Versão!"
	L.CHANGELOG_TOOLTIP_CLICK = "Clique para detalhes"
	L.CHANGELOG_POPUP_DISCORD = "Discord"
	L.CHANGELOG_POPUP_GITHUB = "Bugs"
	L.CHANGELOG_POPUP_SUPPORT = "Suporte"
	L.CHANGELOG_TITLE = "Changelog"

	-- FriendsList.lua
	L.FRIEND_MAX_LEVEL = "Nv Max"

	-- RaidFrame.lua
	L.RAID_GROUP_NAME = "Grupo %d"
	L.RAID_CONVERT_TO_PARTY = "Converter para Grupo"
	L.RAID_CONVERT_TO_RAID = "Converter para Raide"
	L.RAID_MUST_BE_LEADER = "Você deve ser o líder para fazer isso."
	L.RAID_CONVERT_TOO_MANY = "Não é possível converter para grupo: muitos membros."
	L.RAID_ERR_NOT_IN_GROUP = "Você não está em um grupo."

	-- PerformanceMonitor.lua
	L.PERF_FPS_60 = "  ✓ <16.6ms = 60 FPS"
	L.PERF_FPS_30 = "  ✓ <33.3ms = 30 FPS"
	L.PERF_WARNING = "  ✗ >50ms = Aviso"

	-- ClassicCompat.lua
	L.PERF_HEADER_PREFIX = "|cff00ff00Perf:|r"
	L.COMPAT_GAME_VERSION = "|cffffcc00Ver:|r"
	-- ========================================
	-- MISSING KEYS (Auto-Added)
	-- ========================================
	L.MOBILE_STATUS = "Móvel"
	L.RAF_RECRUITMENT = "Recrute um Amigo"
	L.SETTINGS_COLOR_CLASS_NAMES_DESC = "Colore nomes de amigos na cor de sua classe"

	-- Font Outline/Shadow Settings
	L.SETTINGS_FONT_OUTLINE = "Font Outline"
	L.SETTINGS_FONT_SHADOW = "Font Shadow"
	L.SETTINGS_FONT_OUTLINE_NONE = "None"
	L.SETTINGS_FONT_OUTLINE_NORMAL = "Outline"
	L.SETTINGS_FONT_OUTLINE_THICK = "Contorno Espesso"
	L.SETTINGS_FONT_OUTLINE_MONOCHROME = "Monochrome"
	L.SETTINGS_GROUP_COUNT_COLOR = "Count Color"
	L.SETTINGS_GROUP_ARROW_COLOR = "Arrow Color"
	L.TOOLTIP_EDIT_NOTE = "Editar nota"
	L.MENU_SHOW_SEARCH = "Mostrar busca"
	L.MENU_QUICK_FILTER = "Filtro rápido"

	-- Multi-Game-Account
	L.MENU_INVITE_CHARACTER = "Convidar personagem..."
	L.INVITE_ACCOUNT_PICKER_TITLE = "Convidar personagem"

	-- Favorites & Faction Settings
	L.SETTINGS_ENABLE_FAVORITE_ICON = "Habilitar Ícone de Favorito"
	L.SETTINGS_ENABLE_FAVORITE_ICON_DESC = "Mostra um ícone de estrela no botão do amigo para favoritos."
	L.SETTINGS_FAVORITE_ICON_STYLE = "Ícone de Favorito"
	L.SETTINGS_FAVORITE_ICON_STYLE_DESC = "Escolha qual ícone é usado para favoritos."
	L.SETTINGS_FAVORITE_ICON_OPTION_BFL = "Ícone BFL"
	L.SETTINGS_FAVORITE_ICON_OPTION_BLIZZARD = "Ícone Blizzard"
	L.SETTINGS_SHOW_FACTION_BG = "Mostrar Fundo da Facção"
	L.SETTINGS_SHOW_FACTION_BG_DESC = "Mostra a cor da facção como fundo para o botão do amigo."

	-- Multi-Game-Account Settings
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE = "Mostrar emblema multi-conta"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_BADGE_DESC = "Exibe um emblema em amigos com várias contas de jogo online."
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO = "Mostrar info multi-conta"
	L.SETTINGS_SHOW_MULTI_ACCOUNT_INFO_DESC =
		"Adiciona uma lista curta de personagens online quando um amigo tem várias contas ativas."
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS = "Tooltip: Máx. contas de jogo"
	L.SETTINGS_TOOLTIP_MAX_ACCOUNTS_DESC = "Número máximo de contas de jogo adicionais mostradas no tooltip."
	L.INFO_MULTI_ACCOUNT_PREFIX = "x%d Accounts"
	L.INFO_MULTI_ACCOUNT_REMAINDER = " (+%d)"

	-- ========================================
	-- RAID SHORTCUTS (Phase 26)
	-- ========================================
	L.SETTINGS_TAB_RAID = "Raid"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS = "Enable Shortcuts"
	L.SETTINGS_RAID_ENABLE_SHORTCUTS_DESC =
		"Habilita ou desabilita todos os atalhos personalizados do mouse no Quadro de Raide."
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
	L.STREAMER_MODE_TITLE = "Modo Streamer"
	L.STREAMER_MODE_DESC = "Opções de privacidade para transmissão ou gravação."
	L.SETTINGS_ENABLE_STREAMER_MODE = "Mostrar Botão Modo Streamer"
	L.STREAMER_MODE_ENABLE_DESC = "Mostra um botão no quadro principal para alternar o Modo Streamer."
	L.STREAMER_MODE_HIDDEN_NAME = "Formato de Nome Oculto"
	L.STREAMER_MODE_HEADER_TEXT = "Texto de Cabeçalho Personalizado"
	L.STREAMER_MODE_HEADER_TEXT_DESC =
		"Texto a ser exibido no cabeçalho Battle.net quando o Modo Streamer está ativo (p. ex., 'Modo Stream')."
	L.STREAMER_MODE_BUTTON_TOOLTIP = "Alternar Modo Streamer"
	L.STREAMER_MODE_BUTTON_DESC = "Clique para habilitar/desabilitar o modo de privacidade."
	L.SETTINGS_PRIVACY_OPTIONS = "Opções de Privacidade"
	L.SETTINGS_STREAMER_NAME_FORMAT = "Valores de Nome"
	L.SETTINGS_STREAMER_NAME_FORMAT_DESC = "Escolha como os nomes são exibidos no Modo Streamer."
	L.SETTINGS_STREAMER_NAME_FORMAT_BATTLENET = "Forçar BattleTag"
	L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME = "Forçar Apelido"
	L.SETTINGS_STREAMER_NAME_FORMAT_NOTE = "Forçar Nota"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER = "Usar Cor de Cabeçalho Roxo"
	L.SETTINGS_STREAMER_USE_PURPLE_HEADER_DESC =
		"Muda o fundo do cabeçalho Battle.net para roxo Twitch quando o Modo Streamer está ativo."

	-- ========================================
	-- RAID SHORTCUTS (Phase 26) - PARTIAL
	-- ========================================
	L.SETTINGS_RAID_DESC = "Configure atalhos do mouse para gerenciamento de raide e grupo."
	L.SETTINGS_RAID_MODIFIER_LABEL = "Mod:"
	L.SETTINGS_RAID_BUTTON_LABEL = "Btn:"
	L.SETTINGS_RAID_WARNING = "Nota: Os atalhos são ações seguras (apenas fora de combate)."
	L.SETTINGS_RAID_ERROR_RESERVED = "Esta combinação é reservada."

	-- ========================================
	-- WHO FRAME SETTINGS
	-- ========================================
	L.SETTINGS_TAB_WHO = "Quem"
	L.WHO_SETTINGS_DESC = "Configure a aparência e o comportamento dos resultados de busca Quem."
	L.WHO_SETTINGS_VISUAL_HEADER = "Visual"
	L.WHO_SETTINGS_CLASS_ICONS = "Mostrar ícones de classe"
	L.WHO_SETTINGS_CLASS_ICONS_DESC = "Exibe ícones de classe ao lado dos nomes dos jogadores."
	L.WHO_SETTINGS_CLASS_COLORS = "Nomes coloridos por classe"
	L.WHO_SETTINGS_CLASS_COLORS_DESC = "Colore os nomes dos jogadores pela sua classe."
	L.WHO_SETTINGS_LEVEL_COLORS = "Cores de dificuldade de nível"
	L.WHO_SETTINGS_LEVEL_COLORS_DESC = "Colore os níveis pela dificuldade relativa ao seu nível."
	L.WHO_SETTINGS_ZEBRA = "Fundo de linhas alternadas"
	L.WHO_SETTINGS_ZEBRA_DESC = "Mostra fundos de linhas alternadas sutis para melhor legibilidade."
	L.WHO_SETTINGS_BEHAVIOR_HEADER = "Comportamento"
	L.WHO_SETTINGS_DOUBLE_CLICK = "Ação de duplo clique"
	L.WHO_DOUBLE_CLICK_WHISPER = "Sussurrar"
	L.WHO_DOUBLE_CLICK_INVITE = "Convidar para grupo"
	L.WHO_RESULTS_SHOWING = "%d de %d jogadores exibidos"
	L.WHO_NO_RESULTS = "Nenhum jogador encontrado"
	L.WHO_TOOLTIP_HINT_CLICK = "Clique para selecionar"
	L.WHO_TOOLTIP_HINT_DBLCLICK = "Duplo clique para sussurrar"
	L.WHO_TOOLTIP_HINT_DBLCLICK_INVITE = "Duplo clique para convidar"
	L.WHO_TOOLTIP_HINT_CTRL_FORMAT = "Ctrl+Clique para buscar %s"
	L.WHO_TOOLTIP_HINT_RIGHTCLICK = "Clique direito para opções"
	L.WHO_SEARCH_PENDING = "Pesquisando..."
	L.WHO_SEARCH_TIMEOUT = "Sem resposta. Tente novamente."

	-- ========================================
	-- WHO SEARCH BUILDER
	-- ========================================
	L.WHO_BUILDER_TITLE = "Construtor de busca"
	L.WHO_BUILDER_NAME = "Nome"
	L.WHO_BUILDER_GUILD = "Guilda"
	L.WHO_BUILDER_ZONE = "Zona"
	L.WHO_BUILDER_CLASS = "Classe"
	L.WHO_BUILDER_RACE = "Raça"
	L.WHO_BUILDER_LEVEL = "Nível"
	L.WHO_BUILDER_LEVEL_TO = "a"
	L.WHO_BUILDER_ALL_CLASSES = "Todas as classes"
	L.WHO_BUILDER_ALL_RACES = "Todas as raças"
	L.WHO_BUILDER_PREVIEW = "Visualização:"
	L.WHO_BUILDER_PREVIEW_EMPTY = "Preencha os campos para construir uma busca"
	L.WHO_BUILDER_SEARCH = "Buscar"
	L.WHO_BUILDER_RESET = "Redefinir"
	L.WHO_BUILDER_TOOLTIP = "Abrir construtor de busca"
	L.WHO_BUILDER_DOCK_TOOLTIP = "Ancorar construtor de busca"
	L.WHO_BUILDER_UNDOCK_TOOLTIP = "Desancorar construtor de busca"

	-- ========================================
	-- FRAME DIMENSIONS (Phase 21) - RESTORED
	-- ========================================
	L.SETTINGS_FRAME_DIMENSIONS_HEADER = "Dimensões do Quadro"
	L.SETTINGS_FRAME_SCALE = "Escala:"
	L.SETTINGS_FRAME_WIDTH = "Largura:"
	L.SETTINGS_FRAME_HEIGHT = "Altura:"
	L.SETTINGS_FRAME_WIDTH_DESC = "Ajusta a largura do quadro"
	L.SETTINGS_FRAME_HEIGHT_DESC = "Ajusta a altura do quadro"
	L.SETTINGS_FRAME_SCALE_DESC = "Ajusta a escala do quadro"

	-- Group Headers (Phase 21)
	L.SETTINGS_GROUP_HEADER_ALIGN = "Alinhamento do Cabeçalho do Grupo"
	L.SETTINGS_GROUP_HEADER_ALIGN_DESC = "Define o alinhamento do texto do nome do grupo"
	L.SETTINGS_ALIGN_LEFT = "Esquerda"
	L.SETTINGS_ALIGN_CENTER = "Centro"
	L.SETTINGS_ALIGN_RIGHT = "Direita"
	L.SETTINGS_SHOW_GROUP_ARROW = "Mostrar Seta de Recolhimento"
	L.SETTINGS_SHOW_GROUP_ARROW_DESC = "Mostra ou oculta o ícone de seta para recolher grupos"
	L.SETTINGS_GROUP_ARROW_ALIGN = "Alinhamento da Seta de Recolhimento"
	L.SETTINGS_GROUP_ARROW_ALIGN_DESC = "Define o alinhamento do ícone de seta retrair/expandir"
	L.SETTINGS_FONT_FACE = "Fonte"
	L.SETTINGS_COLOR_GROUP_COUNT = "Cor do Contador de Grupo"
	L.SETTINGS_COLOR_GROUP_ARROW = "Cor da Seta de Recolhimento"
	L.SETTINGS_INHERIT_GROUP_COUNT_COLOR = "Herdar Cor do Grupo"
	L.SETTINGS_INHERIT_GROUP_ARROW_COLOR = "Herdar Cor do Grupo"
	L.SETTINGS_GROUP_HEADER_SETTINGS = "Configurações do Cabeçalho do Grupo"
	L.SETTINGS_GROUP_FONT_HEADER = "Fonte do Cabeçalho do Grupo"
	L.SETTINGS_GROUP_COLOR_HEADER = "Cores do Cabeçalho do Grupo"
	L.TOOLTIP_RIGHT_CLICK_INHERIT = "Clique com o botão direito para herdar do Grupo"
	L.SETTINGS_INHERIT_TOOLTIP = "(Herdado do Grupo)"

	-- Misc
	L.IGNORE_LIST_GLOBAL_IGNORE_LIST = "Lista Global de Ignorados"
	L.IGNORE_LIST_ENHANCEQOL_IGNORE = "Lista de Ignorados do EnhanceQoL"

	-- ========================================
	-- FONT SETTINGS (Phase 22)
	-- ========================================
	L.SETTINGS_FRIEND_NAME_SETTINGS = "Configurações de Nome de Amigo"
	L.SETTINGS_FRIEND_INFO_SETTINGS = "Configurações de Informações de Amigo"
	L.SETTINGS_FONT_TABS_TITLE = "Texto das Abas"
	L.SETTINGS_FONT_RAID_TITLE = "Texto do Nome do Raid"
	L.SETTINGS_FONT_SIZE_NUM = "Tamanho da Fonte"

	-- ========================================
	-- NOTE SYNC (Group to Note Sync)
	-- ========================================
	L.SETTINGS_SYNC_GROUPS_NOTE_HEADER = "Sincronizar Notas de Grupo"
	L.SETTINGS_SYNC_GROUPS_NOTE = "Sincronizar grupos na nota do amigo"
	L.SETTINGS_SYNC_GROUPS_NOTE_DESC =
		"Escreve as atribuicoes de grupo nas notas de amigos no formato FriendGroups (Nota#Grupo1#Grupo2). Permite compartilhar grupos entre contas ou com usuarios do FriendGroups."
	L.DIALOG_SYNC_GROUPS_CONFIRM_TEXT =
		"Ativar sincronizacao de notas de grupo?\n\n|cffff8800Aviso:|r As notas do BattleNet sao limitadas a 127 caracteres, as notas de amigos WoW a 48 caracteres. Grupos que excederem o limite serao ignorados na nota, mas permanecerao no banco de dados.\n\nAs notas existentes serao atualizadas. Continuar?"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN1 = "Ativar"
	L.DIALOG_SYNC_GROUPS_CONFIRM_BTN2 = "Cancelar"
	L.DIALOG_SYNC_GROUPS_DISABLE_TEXT =
		"A sincronizacao de notas de grupo foi desativada.\n\nGostaria de abrir o Assistente de Limpeza de Notas para remover os sufixos de grupo das notas dos seus amigos?"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN1 = "Abrir Assistente"
	L.DIALOG_SYNC_GROUPS_DISABLE_BTN2 = "Manter Notas"
	L.MSG_SYNC_GROUPS_STARTED = "Sincronizando grupos nas notas de amigos..."
	L.MSG_SYNC_GROUPS_COMPLETE = "Sincronizacao concluida. Atualizados: %d, Ignorados (limite): %d"
	L.MSG_SYNC_GROUPS_PROGRESS = "Sincronizando notas: %d / %d"
	L.MSG_SYNC_GROUPS_NOTE_LIMIT = "Limite de nota atingido para %s - alguns grupos ignorados"

	-- ========================================
	-- NOTE CLEANUP WIZARD
	-- ========================================
	L.WIZARD_TITLE = "Assistente de Limpeza de Notas"
	L.WIZARD_DESC =
		"Remova dados do FriendGroups (#Grupo1#Grupo2) das notas de amigos. Revise as notas limpas antes de aplicar."
	L.WIZARD_BTN = "Limpeza de Notas"
	L.WIZARD_BTN_TOOLTIP = "Abrir o assistente para limpar dados do FriendGroups das notas de amigos"
	L.WIZARD_HEADER = "Limpeza de Notas"
	L.WIZARD_HEADER_DESC =
		"Remova os sufixos do FriendGroups das notas de amigos. Faca um backup primeiro, depois revise e aplique as alteracoes."
	L.WIZARD_COL_ACCOUNT = "Nome da Conta"
	L.WIZARD_COL_BATTLETAG = "BattleTag"
	L.WIZARD_COL_NOTE = "Nota Atual"
	L.WIZARD_COL_CLEANED = "Nota Limpa"
	L.WIZARD_SEARCH_PLACEHOLDER = "Pesquisar..."
	L.WIZARD_BACKUP_BTN = "Backup das Notas"
	L.WIZARD_BACKUP_DONE = "Backup feito!"
	L.WIZARD_BACKUP_TOOLTIP = "Salvar todas as notas de amigos atuais no banco de dados como backup."
	L.WIZARD_BACKUP_SUCCESS = "Backup feito para %d amigos."
	L.WIZARD_APPLY_BTN = "Aplicar Limpeza"
	L.WIZARD_APPLY_TOOLTIP = "Reescrever as notas limpas. Apenas notas diferentes do original serao atualizadas."
	L.WIZARD_APPLY_CONFIRM =
		"Aplicar notas limpas a todos os amigos?\n\n|cffff8800As notas atuais serao sobrescritas. Certifique-se de ter criado um backup primeiro!|r"
	L.WIZARD_APPLY_SUCCESS = "%d notas atualizadas com sucesso."
	L.WIZARD_APPLY_PROGRESS_FMT = "Progresso: %d/%d | %d com sucesso | %d falharam"
	L.WIZARD_STATUS_FMT = "Mostrando %d de %d amigos | %d com dados de grupo | %d alteracoes pendentes"

	-- Note Cleanup Wizard: Backup Viewer
	L.WIZARD_VIEW_BACKUP_BTN = "Ver backup"
	L.WIZARD_VIEW_BACKUP_TOOLTIP =
		"Abrir o visualizador de backup para ver todas as notas salvas e compara-las com as atuais."
	L.WIZARD_BACKUP_VIEWER_TITLE = "Visualizador de backup de notas"
	L.WIZARD_BACKUP_VIEWER_DESC =
		"Visualize as notas de amigos salvas e compare-as com as notas atuais. Voce pode restaurar as notas originais se necessario."
	L.WIZARD_COL_BACKED_UP = "Nota salva"
	L.WIZARD_COL_CURRENT = "Nota atual"
	L.WIZARD_RESTORE_BTN = "Restaurar backup"
	L.WIZARD_RESTORE_TOOLTIP =
		"Restaura as notas originais do backup. Apenas notas diferentes do backup serao atualizadas."
	L.WIZARD_RESTORE_CONFIRM =
		"Restaurar todas as notas do backup?\n\n|cffff8800Isso sobrescrevera as notas atuais com as versoes salvas.|r"
	L.WIZARD_RESTORE_SUCCESS = "%d notas restauradas com sucesso."
	L.WIZARD_NO_BACKUP =
		"Nenhum backup de notas encontrado. Use o Assistente de limpeza de notas primeiro para criar um."
	L.WIZARD_BACKUP_STATUS_FMT = "Exibindo %d de %d entradas | %d alteradas desde o backup | Backup: %s"
end)
