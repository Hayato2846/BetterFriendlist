-- LibSettingsDesigner
-- License: https://raw.githubusercontent.com/R41z0r/LibSettingsDesigner/main/LICENSE.md
-- Do not remove this notice from redistributed copies.

local addonName, addon = ...
addon = addon or _G[addonName] or {}
addon.LibSettingsDesigner = addon.LibSettingsDesigner or {}

local MINOR = 2
local lib = addon.LibSettingsDesigner.UI or {}
addon.LibSettingsDesigner.UI = lib
lib.MINOR = MINOR
lib._Internal = lib._Internal or {}

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local C_Texture = _G.C_Texture
local MenuUtil = _G.MenuUtil
local ColorPickerFrame = _G.ColorPickerFrame
local StaticPopupDialogs = _G.StaticPopupDialogs
local StaticPopup_Show = _G.StaticPopup_Show

local WINDOW_WIDTH = 1080
local WINDOW_HEIGHT = 700
local SIDEBAR_WIDTH = 236
local CONTENT_WIDTH = 790
local PAGE_RIGHT_WIDTH = 248
local PAGE_RIGHT_WIDTH_MIN = 190
local PAGE_LEFT_WIDTH_MIN = 560
local PAGE_LEFT_WIDTH_IDEAL = 620
local PAGE_GAP = 16
local PAGE_LAYOUT = {
	contentPad = 10,
	scrollbarGutter = 26, -- reserved, visible gutter between settings column and side panel
	columnInset = 5, -- keep section borders away from the scroll clipping edge
	scrollbarOffset = 8,
	detailNavHeight = 30,
	detailNavGap = 8,
	scrollInset = 8,
	scrollBottomPad = 20,
	sidePanelTopOffset = 48,
	windowMinWidth = 1080,
	windowMinHeight = 640,
}
local GRID_GAP = 12
local STATUS_TILE_HEIGHT = 72
local STATUS_ICON_SIZE = 30
local STATUS_TILE_PAD_X = 16
local STATUS_TEXT_LEFT = 58
local PAGE_CARD_HEIGHT = 112
local PAGE_CARD_PAD_X = 18
local PAGE_CARD_ICON_SIZE = 42
local PAGE_CARD_TEXT_GAP = 18
local PAGE_CARD_TEXT_LEFT = PAGE_CARD_PAD_X + PAGE_CARD_ICON_SIZE + PAGE_CARD_TEXT_GAP
local BOOLEAN_ROW_HEIGHT = 68
local STACKED_ROW_HEIGHT = 106
local SLIDER_ROW_HEIGHT = 88
local SLIDER_ROW_HEIGHT_COMPACT = 72
local COMPLEX_ROW_HEIGHT = 92
local ROW_INSET = 14
local SCROLL_CONTENT_INSET = 2
local FIELD_CONTROL_LEFT = 18
local FIELD_CONTROL_WIDTH_MIN = 260
local FIELD_CONTROL_WIDTH_MAX = 340
local SLIDER_SCALE_LABEL_WIDTH = 32
local SLIDER_SCALE_GAP = 12

local FONT_TITLE = "GameFontNormalLarge"
local FONT_HERO = "GameFontNormalHuge2"
local FONT_HEADER = "GameFontNormal"
local FONT_TEXT = "GameFontHighlight"
local FONT_MUTED = "GameFontDisableSmall"

lib.DEFAULT_DASHBOARD_INTRO = "Review settings, quick actions, and configuration pages."

lib.LOCALES = {
	enUS = {
		configCenterAbout = "About",
		configCenterSections = "Sections",
		configCenterAdvancedSettingDesc = "Open the related editor or action for this setting.",
		configCenterButtonFallbackDesc = "Run this action.",
		configCenterChange = "Change",
		configCenterChanged = "changed",
		configCenterCheckboxDropdownFallbackDesc = "Enable this setting and choose its related option.",
		configCenterColorFallbackDesc = "Choose a color for this setting.",
		configCenterConfigure = "Configure",
		configCenterConfirmDefaultsDesc = "This will restore all settings on %s to their defaults.",
		configCenterConfirmDefaultsTitle = "Reset this page to default values?",
		configCenterControlDropdown = "Dropdown",
		configCenterControlSlider = "Slider",
		configCenterCurrent = "Current",
		configCenterDashboard = "Dashboard",
		configCenterDensityComfortable = "Comfortable",
		configCenterDensityCompact = "Compact",
		configCenterDropdownFallbackDesc = "Choose one of the available options.",
		configCenterInputFallbackDesc = "Enter the value used by this setting.",
		configCenterLockWindow = "Lock Window",
		configCenterLockWindowDesc = "Prevents the settings window from being moved by mouse drags.",
		configCenterMultiDropdownFallbackDesc = "Choose one or more options.",
		configCenterNoResults = "No settings found.",
		configCenterAdd = "Add",
		configCenterBack = "Back",
		configCenterCancel = "Cancel",
		configCenterDefaults = "Defaults",
		configCenterDisabled = "Disabled",
		configCenterEnabled = "Enabled",
		configCenterKeyBindings = "Key Bindings",
		configCenterNew = "New",
		configCenterNotes = "Notes",
		configCenterNone = "None",
		configCenterOkay = "OK",
		configCenterOpenButton = "Open",
		configCenterOpen = "Open Settings",
		configCenterOpenDesc = "Opens the modern settings center.",
		configCenterPreview = "Preview",
		configCenterRemove = "Remove",
		configCenterReloadRequired = "Reload Required",
		configCenterReloadRequiredDesc = "One or more changed settings require a UI reload.",
		configCenterReloadUI = "Reload UI",
		configCenterResetColor = "Reset color",
		configCenterSearchPlaceholder = "Search settings",
		configCenterSetting = "setting",
		configCenterSettings = "settings",
		configCenterSliderFallbackDesc = "Adjust this value.",
		configCenterSound = "Sound",
		configCenterStatus = "Status",
		configCenterTitle = "Settings",
		configCenterUnlockWindow = "Unlock Window",
	},
	deDE = {
		configCenterAbout = "Überblick",
		configCenterSections = "Abschnitte",
		configCenterAdvancedSettingDesc = "Öffnet den zugehörigen Editor oder die Aktion für diese Einstellung.",
		configCenterButtonFallbackDesc = "Führe diese Aktion aus.",
		configCenterChange = "Ändern",
		configCenterChanged = "geändert",
		configCenterCheckboxDropdownFallbackDesc = "Aktiviere diese Einstellung und wähle die zugehörige Option.",
		configCenterColorFallbackDesc = "Wähle eine Farbe für diese Einstellung.",
		configCenterConfigure = "Konfigurieren",
		configCenterConfirmDefaultsDesc = "Dadurch werden alle Einstellungen auf %s auf ihre Standardwerte zurückgesetzt.",
		configCenterConfirmDefaultsTitle = "Diese Seite auf Standardwerte zurücksetzen?",
		configCenterControlDropdown = "Dropdown",
		configCenterControlSlider = "Schieberegler",
		configCenterCurrent = "Aktuell",
		configCenterDashboard = "Dashboard",
		configCenterDensityComfortable = "Komfortabel",
		configCenterDensityCompact = "Kompakt",
		configCenterDropdownFallbackDesc = "Wähle eine der verfügbaren Optionen.",
		configCenterInputFallbackDesc = "Gib den Wert für diese Einstellung ein.",
		configCenterLockWindow = "Fenster sperren",
		configCenterLockWindowDesc = "Verhindert, dass das Einstellungsfenster per Maus verschoben wird.",
		configCenterMultiDropdownFallbackDesc = "Wähle eine oder mehrere Optionen.",
		configCenterNoResults = "Keine Einstellungen gefunden.",
		configCenterAdd = "Hinzufügen",
		configCenterBack = "Zurück",
		configCenterCancel = "Abbrechen",
		configCenterDefaults = "Standardwerte",
		configCenterDisabled = "Deaktiviert",
		configCenterEnabled = "Aktiviert",
		configCenterKeyBindings = "Tastenbelegungen",
		configCenterNew = "Neu",
		configCenterNotes = "Notizen",
		configCenterNone = "Keine",
		configCenterOkay = "OK",
		configCenterOpenButton = "Öffnen",
		configCenterOpen = "Einstellungen öffnen",
		configCenterOpenDesc = "Öffnet das moderne Einstellungscenter.",
		configCenterPreview = "Vorschau",
		configCenterRemove = "Entfernen",
		configCenterReloadRequired = "Reload erforderlich",
		configCenterReloadRequiredDesc = "Eine oder mehrere geänderte Einstellungen erfordern ein Neuladen der Benutzeroberfläche.",
		configCenterReloadUI = "UI neu laden",
		configCenterResetColor = "Farbe zurücksetzen",
		configCenterSearchPlaceholder = "Einstellungen suchen",
		configCenterSetting = "Einstellung",
		configCenterSettings = "Einstellungen",
		configCenterSliderFallbackDesc = "Passe diesen Wert an.",
		configCenterSound = "Sound",
		configCenterStatus = "Status",
		configCenterTitle = "Einstellungen",
		configCenterUnlockWindow = "Fenster entsperren",
	},
	esES = {
		configCenterAbout = "Acerca de",
		configCenterSections = "Secciones",
		configCenterAdvancedSettingDesc = "Abre el editor o la acción relacionada con este ajuste.",
		configCenterButtonFallbackDesc = "Ejecuta esta acción.",
		configCenterChange = "Cambiar",
		configCenterChanged = "cambiados",
		configCenterCheckboxDropdownFallbackDesc = "Activa este ajuste y elige su opción relacionada.",
		configCenterColorFallbackDesc = "Elige un color para este ajuste.",
		configCenterConfigure = "Configurar",
		configCenterConfirmDefaultsDesc = "Esto restaurará todos los ajustes de %s a sus valores predeterminados.",
		configCenterConfirmDefaultsTitle = "¿Restablecer esta página a los valores predeterminados?",
		configCenterControlDropdown = "Desplegable",
		configCenterControlSlider = "Deslizador",
		configCenterCurrent = "Actual",
		configCenterDashboard = "Panel",
		configCenterDensityComfortable = "Cómodo",
		configCenterDensityCompact = "Compacto",
		configCenterDropdownFallbackDesc = "Elige una de las opciones disponibles.",
		configCenterInputFallbackDesc = "Introduce el valor usado por este ajuste.",
		configCenterLockWindow = "Bloquear ventana",
		configCenterLockWindowDesc = "Impide mover la ventana de ajustes arrastrándola con el ratón.",
		configCenterMultiDropdownFallbackDesc = "Elige una o más opciones.",
		configCenterNoResults = "No se encontraron ajustes.",
		configCenterAdd = "Añadir",
		configCenterBack = "Atrás",
		configCenterCancel = "Cancelar",
		configCenterDefaults = "Predeterminados",
		configCenterDisabled = "Desactivado",
		configCenterEnabled = "Activado",
		configCenterKeyBindings = "Asignaciones de teclas",
		configCenterNew = "Nuevo",
		configCenterNotes = "Notas",
		configCenterNone = "Ninguno",
		configCenterOkay = "Aceptar",
		configCenterOpenButton = "Abrir",
		configCenterOpen = "Abrir ajustes",
		configCenterOpenDesc = "Abre el centro de ajustes moderno.",
		configCenterPreview = "Vista previa",
		configCenterRemove = "Eliminar",
		configCenterReloadRequired = "Se requiere recarga",
		configCenterReloadRequiredDesc = "Uno o más ajustes cambiados requieren recargar la interfaz.",
		configCenterReloadUI = "Recargar interfaz",
		configCenterResetColor = "Restablecer color",
		configCenterSearchPlaceholder = "Buscar ajustes",
		configCenterSetting = "ajuste",
		configCenterSettings = "ajustes",
		configCenterSliderFallbackDesc = "Ajusta este valor.",
		configCenterSound = "Sonido",
		configCenterStatus = "Estado",
		configCenterTitle = "Ajustes",
		configCenterUnlockWindow = "Desbloquear ventana",
	},
	esMX = {
		configCenterAbout = "Acerca de",
		configCenterSections = "Secciones",
		configCenterAdvancedSettingDesc = "Abre el editor o la acción relacionada con este ajuste.",
		configCenterButtonFallbackDesc = "Ejecuta esta acción.",
		configCenterChange = "Cambiar",
		configCenterChanged = "cambiados",
		configCenterCheckboxDropdownFallbackDesc = "Activa este ajuste y elige su opción relacionada.",
		configCenterColorFallbackDesc = "Elige un color para este ajuste.",
		configCenterConfigure = "Configurar",
		configCenterConfirmDefaultsDesc = "Esto restaurará todos los ajustes de %s a sus valores predeterminados.",
		configCenterConfirmDefaultsTitle = "¿Restablecer esta página a los valores predeterminados?",
		configCenterControlDropdown = "Desplegable",
		configCenterControlSlider = "Deslizador",
		configCenterCurrent = "Actual",
		configCenterDashboard = "Panel",
		configCenterDensityComfortable = "Cómodo",
		configCenterDensityCompact = "Compacto",
		configCenterDropdownFallbackDesc = "Elige una de las opciones disponibles.",
		configCenterInputFallbackDesc = "Introduce el valor usado por este ajuste.",
		configCenterLockWindow = "Bloquear ventana",
		configCenterLockWindowDesc = "Impide mover la ventana de ajustes arrastrándola con el ratón.",
		configCenterMultiDropdownFallbackDesc = "Elige una o más opciones.",
		configCenterNoResults = "No se encontraron ajustes.",
		configCenterAdd = "Añadir",
		configCenterBack = "Atrás",
		configCenterCancel = "Cancelar",
		configCenterDefaults = "Predeterminados",
		configCenterDisabled = "Desactivado",
		configCenterEnabled = "Activado",
		configCenterKeyBindings = "Asignaciones de teclas",
		configCenterNew = "Nuevo",
		configCenterNotes = "Notas",
		configCenterNone = "Ninguno",
		configCenterOkay = "Aceptar",
		configCenterOpenButton = "Abrir",
		configCenterOpen = "Abrir ajustes",
		configCenterOpenDesc = "Abre el centro de ajustes moderno.",
		configCenterPreview = "Vista previa",
		configCenterRemove = "Eliminar",
		configCenterReloadRequired = "Se requiere recarga",
		configCenterReloadRequiredDesc = "Uno o más ajustes cambiados requieren recargar la interfaz.",
		configCenterReloadUI = "Recargar interfaz",
		configCenterResetColor = "Restablecer color",
		configCenterSearchPlaceholder = "Buscar ajustes",
		configCenterSetting = "ajuste",
		configCenterSettings = "ajustes",
		configCenterSliderFallbackDesc = "Ajusta este valor.",
		configCenterSound = "Sonido",
		configCenterStatus = "Estado",
		configCenterTitle = "Ajustes",
		configCenterUnlockWindow = "Desbloquear ventana",
	},
	frFR = {
		configCenterAbout = "À propos",
		configCenterSections = "Sections",
		configCenterAdvancedSettingDesc = "Ouvre l’éditeur ou l’action associé à ce réglage.",
		configCenterButtonFallbackDesc = "Exécute cette action.",
		configCenterChange = "Modifier",
		configCenterChanged = "modifiés",
		configCenterCheckboxDropdownFallbackDesc = "Activez ce réglage et choisissez l’option associée.",
		configCenterColorFallbackDesc = "Choisissez une couleur pour ce réglage.",
		configCenterConfigure = "Configurer",
		configCenterConfirmDefaultsDesc = "Tous les réglages de %s seront restaurés à leurs valeurs par défaut.",
		configCenterConfirmDefaultsTitle = "Réinitialiser cette page aux valeurs par défaut ?",
		configCenterControlDropdown = "Menu déroulant",
		configCenterControlSlider = "Curseur",
		configCenterCurrent = "Actuel",
		configCenterDashboard = "Tableau de bord",
		configCenterDensityComfortable = "Confort",
		configCenterDensityCompact = "Compact",
		configCenterDropdownFallbackDesc = "Choisissez une des options disponibles.",
		configCenterInputFallbackDesc = "Saisissez la valeur utilisée par ce réglage.",
		configCenterLockWindow = "Verrouiller la fenêtre",
		configCenterLockWindowDesc = "Empêche le déplacement de la fenêtre de réglages avec la souris.",
		configCenterMultiDropdownFallbackDesc = "Choisissez une ou plusieurs options.",
		configCenterNoResults = "Aucun réglage trouvé.",
		configCenterAdd = "Ajouter",
		configCenterBack = "Retour",
		configCenterCancel = "Annuler",
		configCenterDefaults = "Par défaut",
		configCenterDisabled = "Désactivé",
		configCenterEnabled = "Activé",
		configCenterKeyBindings = "Raccourcis clavier",
		configCenterNew = "Nouveau",
		configCenterNotes = "Notes",
		configCenterNone = "Aucun",
		configCenterOkay = "OK",
		configCenterOpenButton = "Ouvrir",
		configCenterOpen = "Ouvrir les réglages",
		configCenterOpenDesc = "Ouvre le centre de réglages moderne.",
		configCenterPreview = "Aperçu",
		configCenterRemove = "Supprimer",
		configCenterReloadRequired = "Rechargement requis",
		configCenterReloadRequiredDesc = "Un ou plusieurs réglages modifiés nécessitent de recharger l'interface.",
		configCenterReloadUI = "Recharger l'interface",
		configCenterResetColor = "Réinitialiser la couleur",
		configCenterSearchPlaceholder = "Rechercher des réglages",
		configCenterSetting = "réglage",
		configCenterSettings = "réglages",
		configCenterSliderFallbackDesc = "Ajustez cette valeur.",
		configCenterSound = "Son",
		configCenterStatus = "État",
		configCenterTitle = "Réglages",
		configCenterUnlockWindow = "Déverrouiller la fenêtre",
	},
	itIT = {
		configCenterAbout = "Informazioni",
		configCenterSections = "Sezioni",
		configCenterAdvancedSettingDesc = "Apre l’editor o l’azione collegata a questa impostazione.",
		configCenterButtonFallbackDesc = "Esegui questa azione.",
		configCenterChange = "Cambia",
		configCenterChanged = "modificate",
		configCenterCheckboxDropdownFallbackDesc = "Attiva questa impostazione e scegli l’opzione correlata.",
		configCenterColorFallbackDesc = "Scegli un colore per questa impostazione.",
		configCenterConfigure = "Configura",
		configCenterConfirmDefaultsDesc = "Questo ripristinerà tutte le impostazioni di %s ai valori predefiniti.",
		configCenterConfirmDefaultsTitle = "Ripristinare questa pagina ai valori predefiniti?",
		configCenterControlDropdown = "Menu a discesa",
		configCenterControlSlider = "Cursore",
		configCenterCurrent = "Attuale",
		configCenterDashboard = "Panoramica",
		configCenterDensityComfortable = "Comoda",
		configCenterDensityCompact = "Compatta",
		configCenterDropdownFallbackDesc = "Scegli una delle opzioni disponibili.",
		configCenterInputFallbackDesc = "Inserisci il valore usato da questa impostazione.",
		configCenterLockWindow = "Blocca finestra",
		configCenterLockWindowDesc = "Impedisce di spostare la finestra delle impostazioni trascinandola con il mouse.",
		configCenterMultiDropdownFallbackDesc = "Scegli una o più opzioni.",
		configCenterNoResults = "Nessuna impostazione trovata.",
		configCenterAdd = "Aggiungi",
		configCenterBack = "Indietro",
		configCenterCancel = "Annulla",
		configCenterDefaults = "Predefiniti",
		configCenterDisabled = "Disabilitato",
		configCenterEnabled = "Abilitato",
		configCenterKeyBindings = "Tasti rapidi",
		configCenterNew = "Nuovo",
		configCenterNotes = "Note",
		configCenterNone = "Nessuno",
		configCenterOkay = "OK",
		configCenterOpenButton = "Apri",
		configCenterOpen = "Apri impostazioni",
		configCenterOpenDesc = "Apre il centro impostazioni moderno.",
		configCenterPreview = "Anteprima",
		configCenterRemove = "Rimuovi",
		configCenterReloadRequired = "Ricaricamento richiesto",
		configCenterReloadRequiredDesc = "Una o più impostazioni modificate richiedono il ricaricamento dell'interfaccia.",
		configCenterReloadUI = "Ricarica UI",
		configCenterResetColor = "Reimposta colore",
		configCenterSearchPlaceholder = "Cerca impostazioni",
		configCenterSetting = "impostazione",
		configCenterSettings = "impostazioni",
		configCenterSliderFallbackDesc = "Regola questo valore.",
		configCenterSound = "Suono",
		configCenterStatus = "Stato",
		configCenterTitle = "Impostazioni",
		configCenterUnlockWindow = "Sblocca finestra",
	},
	koKR = {
		configCenterAbout = "정보",
		configCenterSections = "섹션",
		configCenterAdvancedSettingDesc = "이 설정과 관련된 편집기 또는 동작을 엽니다.",
		configCenterButtonFallbackDesc = "이 동작을 실행합니다.",
		configCenterChange = "변경",
		configCenterChanged = "변경됨",
		configCenterCheckboxDropdownFallbackDesc = "이 설정을 활성화하고 관련 옵션을 선택합니다.",
		configCenterColorFallbackDesc = "이 설정에 사용할 색상을 선택합니다.",
		configCenterConfigure = "구성",
		configCenterConfirmDefaultsDesc = "%s의 모든 설정을 기본값으로 복원합니다.",
		configCenterConfirmDefaultsTitle = "이 페이지를 기본값으로 초기화할까요?",
		configCenterControlDropdown = "드롭다운",
		configCenterControlSlider = "슬라이더",
		configCenterCurrent = "현재",
		configCenterDashboard = "대시보드",
		configCenterDensityComfortable = "여유",
		configCenterDensityCompact = "간결",
		configCenterDropdownFallbackDesc = "사용 가능한 옵션 중 하나를 선택합니다.",
		configCenterInputFallbackDesc = "이 설정에서 사용할 값을 입력합니다.",
		configCenterLockWindow = "창 잠금",
		configCenterLockWindowDesc = "마우스 드래그로 설정 창을 이동하지 못하게 합니다.",
		configCenterMultiDropdownFallbackDesc = "하나 이상의 옵션을 선택합니다.",
		configCenterNoResults = "설정을 찾을 수 없습니다.",
		configCenterAdd = "추가",
		configCenterBack = "뒤로",
		configCenterCancel = "취소",
		configCenterDefaults = "기본값",
		configCenterDisabled = "비활성화됨",
		configCenterEnabled = "활성화됨",
		configCenterKeyBindings = "단축키",
		configCenterNew = "신규",
		configCenterNotes = "메모",
		configCenterNone = "없음",
		configCenterOkay = "확인",
		configCenterOpenButton = "열기",
		configCenterOpen = "설정 열기",
			configCenterOpenDesc = "최신 설정 센터를 엽니다.",
			configCenterPreview = "미리보기",
			configCenterRemove = "제거",
			configCenterReloadRequired = "다시 불러오기 필요",
			configCenterReloadRequiredDesc = "변경된 하나 이상의 설정은 UI 다시 불러오기가 필요합니다.",
			configCenterReloadUI = "UI 다시 불러오기",
			configCenterResetColor = "색상 초기화",
		configCenterSearchPlaceholder = "설정 검색",
		configCenterSetting = "설정",
		configCenterSettings = "설정",
		configCenterSliderFallbackDesc = "이 값을 조정합니다.",
		configCenterSound = "소리",
		configCenterStatus = "상태",
		configCenterTitle = "설정",
		configCenterUnlockWindow = "창 잠금 해제",
	},
	ptBR = {
		configCenterAbout = "Sobre",
		configCenterSections = "Seções",
		configCenterAdvancedSettingDesc = "Abre o editor ou a ação relacionada a esta configuração.",
		configCenterButtonFallbackDesc = "Executa esta ação.",
		configCenterChange = "Alterar",
		configCenterChanged = "alteradas",
		configCenterCheckboxDropdownFallbackDesc = "Ative esta configuração e escolha a opção relacionada.",
		configCenterColorFallbackDesc = "Escolha uma cor para esta configuração.",
		configCenterConfigure = "Configurar",
		configCenterConfirmDefaultsDesc = "Isso restaurará todas as configurações de %s para os valores padrão.",
		configCenterConfirmDefaultsTitle = "Restaurar esta página para os valores padrão?",
		configCenterControlDropdown = "Menu suspenso",
		configCenterControlSlider = "Controle deslizante",
		configCenterCurrent = "Atual",
		configCenterDashboard = "Painel",
		configCenterDensityComfortable = "Confortável",
		configCenterDensityCompact = "Compacto",
		configCenterDropdownFallbackDesc = "Escolha uma das opções disponíveis.",
		configCenterInputFallbackDesc = "Digite o valor usado por esta configuração.",
		configCenterLockWindow = "Bloquear janela",
		configCenterLockWindowDesc = "Impede que a janela de configurações seja movida ao arrastar com o mouse.",
		configCenterMultiDropdownFallbackDesc = "Escolha uma ou mais opções.",
		configCenterNoResults = "Nenhuma configuração encontrada.",
		configCenterAdd = "Adicionar",
		configCenterBack = "Voltar",
		configCenterCancel = "Cancelar",
		configCenterDefaults = "Padrões",
		configCenterDisabled = "Desativado",
		configCenterEnabled = "Ativado",
		configCenterKeyBindings = "Atalhos de teclado",
		configCenterNew = "Novo",
		configCenterNotes = "Notas",
		configCenterNone = "Nenhum",
		configCenterOkay = "OK",
		configCenterOpenButton = "Abrir",
		configCenterOpen = "Abrir configurações",
			configCenterOpenDesc = "Abre a central moderna de configurações.",
			configCenterPreview = "Prévia",
			configCenterRemove = "Remover",
			configCenterReloadRequired = "Recarga necessária",
			configCenterReloadRequiredDesc = "Uma ou mais configurações alteradas exigem recarregar a interface.",
			configCenterReloadUI = "Recarregar interface",
			configCenterResetColor = "Redefinir cor",
		configCenterSearchPlaceholder = "Buscar configurações",
		configCenterSetting = "configuração",
		configCenterSettings = "configurações",
		configCenterSliderFallbackDesc = "Ajuste este valor.",
		configCenterSound = "Som",
		configCenterStatus = "Status",
		configCenterTitle = "Configurações",
		configCenterUnlockWindow = "Desbloquear janela",
	},
	ruRU = {
		configCenterAbout = "Описание",
		configCenterSections = "Разделы",
		configCenterAdvancedSettingDesc = "Открывает связанный редактор или действие для этой настройки.",
		configCenterButtonFallbackDesc = "Выполнить это действие.",
		configCenterChange = "Изменить",
		configCenterChanged = "изменено",
		configCenterCheckboxDropdownFallbackDesc = "Включите этот параметр и выберите связанную опцию.",
		configCenterColorFallbackDesc = "Выберите цвет для этого параметра.",
		configCenterConfigure = "Настроить",
		configCenterConfirmDefaultsDesc = "Все настройки на странице %s будут восстановлены по умолчанию.",
		configCenterConfirmDefaultsTitle = "Сбросить эту страницу к значениям по умолчанию?",
		configCenterControlDropdown = "Выпадающий список",
		configCenterControlSlider = "Ползунок",
		configCenterCurrent = "Текущее",
		configCenterDashboard = "Панель",
		configCenterDensityComfortable = "Удобно",
		configCenterDensityCompact = "Компактно",
		configCenterDropdownFallbackDesc = "Выберите один из доступных вариантов.",
		configCenterInputFallbackDesc = "Введите значение для этого параметра.",
		configCenterLockWindow = "Закрепить окно",
		configCenterLockWindowDesc = "Запрещает перемещать окно настроек перетаскиванием мышью.",
		configCenterMultiDropdownFallbackDesc = "Выберите один или несколько вариантов.",
		configCenterNoResults = "Настройки не найдены.",
		configCenterAdd = "Добавить",
		configCenterBack = "Назад",
		configCenterCancel = "Отмена",
		configCenterDefaults = "По умолчанию",
		configCenterDisabled = "Отключено",
		configCenterEnabled = "Включено",
		configCenterKeyBindings = "Назначения клавиш",
		configCenterNew = "Новое",
		configCenterNotes = "Заметки",
		configCenterNone = "Нет",
		configCenterOkay = "OK",
		configCenterOpenButton = "Открыть",
		configCenterOpen = "Открыть настройки",
			configCenterOpenDesc = "Открывает современный центр настроек.",
			configCenterPreview = "Предпросмотр",
			configCenterRemove = "Удалить",
			configCenterReloadRequired = "Требуется перезагрузка",
			configCenterReloadRequiredDesc = "Для одного или нескольких измененных параметров требуется перезагрузка интерфейса.",
			configCenterReloadUI = "Перезагрузить UI",
			configCenterResetColor = "Сбросить цвет",
		configCenterSearchPlaceholder = "Поиск настроек",
		configCenterSetting = "настройка",
		configCenterSettings = "настройки",
		configCenterSliderFallbackDesc = "Измените это значение.",
		configCenterSound = "Звук",
		configCenterStatus = "Статус",
		configCenterTitle = "Настройки",
		configCenterUnlockWindow = "Открепить окно",
	},
	zhCN = {
		configCenterAbout = "关于",
		configCenterSections = "分区",
		configCenterAdvancedSettingDesc = "打开与此设置相关的编辑器或操作。",
		configCenterButtonFallbackDesc = "执行此操作。",
		configCenterChange = "更改",
		configCenterChanged = "已更改",
		configCenterCheckboxDropdownFallbackDesc = "启用此设置并选择相关选项。",
		configCenterColorFallbackDesc = "为此设置选择颜色。",
		configCenterConfigure = "配置",
		configCenterConfirmDefaultsDesc = "这会将 %s 上的所有设置恢复为默认值。",
		configCenterConfirmDefaultsTitle = "将此页面重置为默认值？",
		configCenterControlDropdown = "下拉菜单",
		configCenterControlSlider = "滑块",
		configCenterCurrent = "当前",
		configCenterDashboard = "仪表盘",
		configCenterDensityComfortable = "舒适",
		configCenterDensityCompact = "紧凑",
		configCenterDropdownFallbackDesc = "选择一个可用选项。",
		configCenterInputFallbackDesc = "输入此设置使用的值。",
		configCenterLockWindow = "锁定窗口",
		configCenterLockWindowDesc = "防止通过鼠标拖动移动设置窗口。",
		configCenterMultiDropdownFallbackDesc = "选择一个或多个选项。",
		configCenterNoResults = "未找到设置。",
		configCenterAdd = "添加",
		configCenterBack = "返回",
		configCenterCancel = "取消",
		configCenterDefaults = "默认值",
		configCenterDisabled = "已禁用",
		configCenterEnabled = "已启用",
		configCenterKeyBindings = "按键绑定",
		configCenterNew = "新",
		configCenterNotes = "备注",
		configCenterNone = "无",
		configCenterOkay = "确定",
		configCenterOpenButton = "打开",
		configCenterOpen = "打开设置",
			configCenterOpenDesc = "打开现代设置中心。",
			configCenterPreview = "预览",
			configCenterRemove = "移除",
			configCenterReloadRequired = "需要重载",
			configCenterReloadRequiredDesc = "一个或多个已更改的设置需要重载界面。",
			configCenterReloadUI = "重载界面",
			configCenterResetColor = "重置颜色",
		configCenterSearchPlaceholder = "搜索设置",
		configCenterSetting = "设置",
		configCenterSettings = "设置",
		configCenterSliderFallbackDesc = "调整此值。",
		configCenterSound = "声音",
		configCenterStatus = "状态",
		configCenterTitle = "设置",
		configCenterUnlockWindow = "解锁窗口",
	},
	zhTW = {
		configCenterAbout = "關於",
		configCenterSections = "區段",
		configCenterAdvancedSettingDesc = "開啟與此設定相關的編輯器或動作。",
		configCenterButtonFallbackDesc = "執行此動作。",
		configCenterChange = "變更",
		configCenterChanged = "已變更",
		configCenterCheckboxDropdownFallbackDesc = "啟用此設定並選擇相關選項。",
		configCenterColorFallbackDesc = "為此設定選擇顏色。",
		configCenterConfigure = "設定",
		configCenterConfirmDefaultsDesc = "這會將 %s 上的所有設定還原為預設值。",
		configCenterConfirmDefaultsTitle = "將此頁面重設為預設值？",
		configCenterControlDropdown = "下拉選單",
		configCenterControlSlider = "滑桿",
		configCenterCurrent = "目前",
		configCenterDashboard = "儀表板",
		configCenterDensityComfortable = "舒適",
		configCenterDensityCompact = "精簡",
		configCenterDropdownFallbackDesc = "選擇一個可用選項。",
		configCenterInputFallbackDesc = "輸入此設定使用的值。",
		configCenterLockWindow = "鎖定視窗",
		configCenterLockWindowDesc = "防止透過滑鼠拖曳移動設定視窗。",
		configCenterMultiDropdownFallbackDesc = "選擇一個或多個選項。",
		configCenterNoResults = "找不到設定。",
		configCenterAdd = "新增",
		configCenterBack = "返回",
		configCenterCancel = "取消",
		configCenterDefaults = "預設值",
		configCenterDisabled = "已停用",
		configCenterEnabled = "已啟用",
		configCenterKeyBindings = "按鍵綁定",
		configCenterNew = "新增",
		configCenterNotes = "備註",
		configCenterNone = "無",
		configCenterOkay = "確定",
		configCenterOpenButton = "開啟",
		configCenterOpen = "開啟設定",
			configCenterOpenDesc = "開啟現代設定中心。",
			configCenterPreview = "預覽",
			configCenterRemove = "移除",
			configCenterReloadRequired = "需要重新載入",
			configCenterReloadRequiredDesc = "一個或多個已變更的設定需要重新載入介面。",
			configCenterReloadUI = "重新載入介面",
			configCenterResetColor = "重設顏色",
		configCenterSearchPlaceholder = "搜尋設定",
		configCenterSetting = "設定",
		configCenterSettings = "設定",
		configCenterSliderFallbackDesc = "調整此值。",
		configCenterSound = "音效",
		configCenterStatus = "狀態",
		configCenterTitle = "設定",
		configCenterUnlockWindow = "解除鎖定視窗",
	},
}

local PANEL_BORDER = { 0.64, 0.55, 0.36, 0.60 }
local TOPBAR_BG = { 0.052, 0.058, 0.063, 0.96 }
local CONTENT_BG = { 0.040, 0.047, 0.055, 0.90 }
local CARD_BG = { 0.065, 0.068, 0.070, 0.92 }
local CARD_BG_HOVER = { 0.125, 0.100, 0.055, 0.96 }
local CARD_BORDER = { 0.58, 0.49, 0.32, 0.48 }
local CARD_BORDER_HOVER = { 0.95, 0.72, 0.30, 0.80 }
local DASHBOARD_CARD_BG = { 0.075, 0.082, 0.086, 0.92 }
local DASHBOARD_CARD_BG_HOVER = { 0.125, 0.100, 0.055, 0.96 }
local DASHBOARD_CARD_BORDER = { 0.50, 0.42, 0.28, 0.38 }
local DETAIL_SECTION_BG = { 0.055, 0.060, 0.065, 0.88 }
local DETAIL_COLORS = {
	columnBg = { 0.040, 0.047, 0.055, 0.84 },
	columnBorder = { 0.58, 0.50, 0.34, 0.50 },
	sectionBorder = { 0.58, 0.50, 0.34, 0.55 },
	sectionHeaderBg = { 0.095, 0.085, 0.060, 0.94 },
}
local ROW_BG = { 0.060, 0.068, 0.074, 0.46 }
local ROW_BORDER = { 0.54, 0.46, 0.30, 0.24 }
local ROW_HOVER_BG = { 0.125, 0.100, 0.055, 0.60 }
local ROW_HOVER_BORDER = { 0.95, 0.73, 0.32, 0.58 }
local ROW_SEPARATOR = { 0.68, 0.54, 0.30, 0.32 }
local SELECTED_BG = { 0.150, 0.115, 0.055, 0.98 }
local SIDEBAR_BG = { 0.030, 0.034, 0.038, 0.45 }
local DISABLED_CONTROL_BG = { 0.032, 0.033, 0.034, 0.72 }
local DISABLED_CONTROL_BORDER = { 0.18, 0.18, 0.17, 0.46 }
local DISABLED_ROW_BG = { 0.035, 0.038, 0.042, 0.36 }
local DISABLED_ROW_BORDER = { 0.20, 0.19, 0.17, 0.22 }
local TEXT = {
	main = { 0.94, 0.91, 0.84, 1.00 },
	muted = { 0.70, 0.67, 0.60, 1.00 },
	subtle = { 0.55, 0.53, 0.48, 1.00 },
	disabled = { 0.38, 0.36, 0.33, 1.00 },
	gold = { 1.00, 0.82, 0.36, 1.00 },
	topbarGold = { 1.00, 0.84, 0.36, 1.00 },
}
local GREEN = { 0.36, 0.82, 0.36 }

function lib.CopyThemeColor(color)
	if type(color) ~= "table" then
		return nil
	end
	return { color[1] or color.r or 0, color[2] or color.g or 0, color[3] or color.b or 0, color[4] or color.a or 1 }
end

function lib.CopyThemeColorMap(colors)
	local copy = {}
	for key, value in pairs(colors) do
		copy[key] = lib.CopyThemeColor(value)
	end
	return copy
end

lib.DEFAULT_COLORS = lib.CopyThemeColorMap({
	panelBorder = PANEL_BORDER,
	topbarBg = TOPBAR_BG,
	topbarBorder = { 0.52, 0.39, 0.19, 0.52 },
	contentBg = CONTENT_BG,
	cardBg = CARD_BG,
	cardBgHover = CARD_BG_HOVER,
	cardBorder = CARD_BORDER,
	cardBorderHover = CARD_BORDER_HOVER,
	dashboardCardBg = DASHBOARD_CARD_BG,
	dashboardCardBgHover = DASHBOARD_CARD_BG_HOVER,
	dashboardCardBorder = DASHBOARD_CARD_BORDER,
	detailSectionBg = DETAIL_SECTION_BG,
	detailColumnBg = DETAIL_COLORS.columnBg,
	detailColumnBorder = DETAIL_COLORS.columnBorder,
	detailSectionBorder = DETAIL_COLORS.sectionBorder,
	detailSectionHeaderBg = DETAIL_COLORS.sectionHeaderBg,
	rowBg = ROW_BG,
	rowBorder = ROW_BORDER,
	rowHoverBg = ROW_HOVER_BG,
	rowHoverBorder = ROW_HOVER_BORDER,
	rowSeparator = ROW_SEPARATOR,
	selectedBg = SELECTED_BG,
	sidebarBg = SIDEBAR_BG,
	frameBg = { 0.035, 0.038, 0.043, 0.96 },
	overlayTint = { 0.72, 0.78, 0.84, 1.00 },
	buttonBg = { 0.070, 0.065, 0.055, 0.92 },
	buttonBorder = CARD_BORDER,
	buttonHoverBg = CARD_BG_HOVER,
	buttonHoverBorder = CARD_BORDER_HOVER,
	buttonTopbarBg = { 0.100, 0.090, 0.070, 0.88 },
	buttonTopbarBorder = { 0.46, 0.36, 0.18, 0.70 },
	buttonTopbarHoverBg = { 0.165, 0.135, 0.080, 0.98 },
	searchBg = { 0.035, 0.034, 0.032, 0.95 },
	searchBorder = { 0.30, 0.28, 0.22, 0.90 },
	disabledControlBg = DISABLED_CONTROL_BG,
	disabledControlBorder = DISABLED_CONTROL_BORDER,
	disabledRowBg = DISABLED_ROW_BG,
	disabledRowBorder = DISABLED_ROW_BORDER,
	textMain = TEXT.main,
	textMuted = TEXT.muted,
	textSubtle = TEXT.subtle,
	textDisabled = TEXT.disabled,
	accent = TEXT.gold,
	topbarAccent = TEXT.topbarGold,
	success = GREEN,
})
lib.ThemeColors = lib.CopyThemeColorMap(lib.DEFAULT_COLORS)

lib.COLOR_ALIASES = {
	background = "frameBg",
	overlay = "overlayTint",
	panel = "contentBg",
	panelBorder = "panelBorder",
	topbarBorder = "topbarBorder",
	content = "contentBg",
	sidebar = "sidebarBg",
	card = "cardBg",
	cardHover = "cardBgHover",
	cardBorder = "cardBorder",
	cardHoverBorder = "cardBorderHover",
	row = "rowBg",
	rowBorder = "rowBorder",
	rowHover = "rowHoverBg",
	rowHoverBorder = "rowHoverBorder",
	button = "buttonBg",
	buttonBorder = "buttonBorder",
	buttonHover = "buttonHoverBg",
	buttonHoverBorder = "buttonHoverBorder",
	search = "searchBg",
	searchBorder = "searchBorder",
	selected = "selectedBg",
	text = "textMain",
	mutedText = "textMuted",
	subtleText = "textSubtle",
	disabledText = "textDisabled",
	accent = "accent",
	topbarText = "topbarAccent",
	green = "success",
}

function lib.ReadAppThemeColors(app)
	local opts = app and app.opts
	local colors = opts and (opts.colors or opts.colorTable or opts.themeColors)
	if type(colors) == "function" then
		local ok, result = pcall(colors, app)
		colors = ok and result or nil
	end
	return type(colors) == "table" and colors or nil
end

function lib.ApplyThemeColorValue(target, source, sourceKey, targetKey)
	local value = source[sourceKey]
	if value ~= nil then
		target[targetKey or sourceKey] = lib.CopyThemeColor(value)
	end
end

function lib.ResolveThemeColors(app)
	local colors = lib.CopyThemeColorMap(lib.DEFAULT_COLORS)
	local overrides = lib.ReadAppThemeColors(app)
	if overrides then
		for key in pairs(lib.DEFAULT_COLORS) do
			lib.ApplyThemeColorValue(colors, overrides, key)
		end
		for alias, key in pairs(lib.COLOR_ALIASES) do
			lib.ApplyThemeColorValue(colors, overrides, alias, key)
		end
	end
	return colors
end

function lib.ApplyThemeColors(app)
	local colors = lib.ResolveThemeColors(app)
	PANEL_BORDER = colors.panelBorder
	TOPBAR_BG = colors.topbarBg
	CONTENT_BG = colors.contentBg
	CARD_BG = colors.cardBg
	CARD_BG_HOVER = colors.cardBgHover
	CARD_BORDER = colors.cardBorder
	CARD_BORDER_HOVER = colors.cardBorderHover
	DASHBOARD_CARD_BG = colors.dashboardCardBg
	DASHBOARD_CARD_BG_HOVER = colors.dashboardCardBgHover
	DASHBOARD_CARD_BORDER = colors.dashboardCardBorder
	DETAIL_SECTION_BG = colors.detailSectionBg
	DETAIL_COLORS.columnBg = colors.detailColumnBg
	DETAIL_COLORS.columnBorder = colors.detailColumnBorder
	DETAIL_COLORS.sectionBorder = colors.detailSectionBorder
	DETAIL_COLORS.sectionHeaderBg = colors.detailSectionHeaderBg
	ROW_BG = colors.rowBg
	ROW_BORDER = colors.rowBorder
	ROW_HOVER_BG = colors.rowHoverBg
	ROW_HOVER_BORDER = colors.rowHoverBorder
	ROW_SEPARATOR = colors.rowSeparator
	SELECTED_BG = colors.selectedBg
	SIDEBAR_BG = colors.sidebarBg
	lib.ThemeColors = colors
	DISABLED_CONTROL_BG = colors.disabledControlBg
	DISABLED_CONTROL_BORDER = colors.disabledControlBorder
	DISABLED_ROW_BG = colors.disabledRowBg
	DISABLED_ROW_BORDER = colors.disabledRowBorder
	TEXT.main = colors.textMain
	TEXT.muted = colors.textMuted
	TEXT.subtle = colors.textSubtle
	TEXT.disabled = colors.textDisabled
	TEXT.gold = colors.accent
	TEXT.topbarGold = colors.topbarAccent
	GREEN = colors.success
end

function lib.CopyThemeInset(insets)
	insets = type(insets) == "table" and insets or {}
	return {
		left = tonumber(insets.left) or tonumber(insets[1]) or 3,
		right = tonumber(insets.right) or tonumber(insets[2]) or 3,
		top = tonumber(insets.top) or tonumber(insets[3]) or 3,
		bottom = tonumber(insets.bottom) or tonumber(insets[4]) or 3,
	}
end

function lib.CopyThemeBorder(style)
	if type(style) ~= "table" then
		return nil
	end
	return {
		bgFile = style.bgFile or style.backgroundFile or "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = style.edgeFile or style.borderFile or style.file or "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = style.tile ~= false,
		tileSize = tonumber(style.tileSize) or 16,
		edgeSize = tonumber(style.edgeSize) or tonumber(style.size) or 12,
		insets = lib.CopyThemeInset(style.insets),
	}
end

lib.DEFAULT_BORDER_STYLE = lib.CopyThemeBorder({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
})

lib.BORDER_KEYS = {
	"default",
	"panel",
	"topbar",
	"content",
	"sidebar",
	"card",
	"dashboardCard",
	"detailSection",
	"detailColumn",
	"row",
	"button",
	"topbarButton",
	"search",
	"control",
	"toggle",
	"toggleKnob",
	"swatch",
	"reorderItem",
}

lib.BORDER_ALIASES = {
	background = "panel",
	frame = "panel",
	buttons = "button",
	topbarButtons = "topbarButton",
	checkbox = "toggle",
	checkboxes = "toggle",
	switch = "toggle",
	switchKnob = "toggleKnob",
	dropdown = "button",
	input = "control",
	color = "swatch",
	colorSwatch = "swatch",
	dashboard = "dashboardCard",
	detail = "detailSection",
}

function lib.ReadAppThemeBorders(app)
	local opts = app and app.opts
	local theme = opts and opts.theme
	local borders = opts and (opts.borders or opts.themeBorders or opts.borderAssets)
	if not borders and type(theme) == "table" then
		borders = theme.borders or theme.border or theme.borderAssets
	end
	if type(borders) == "function" then
		local ok, result = pcall(borders, app)
		borders = ok and result or nil
	end
	return type(borders) == "table" and borders or nil
end

function lib.ResolveThemeBorders(app)
	local overrides = lib.ReadAppThemeBorders(app)
	local defaultStyle = lib.CopyThemeBorder(overrides and (overrides.default or overrides.all)) or lib.CopyThemeBorder(lib.DEFAULT_BORDER_STYLE)
	local borders = {}
	for _, key in ipairs(lib.BORDER_KEYS) do
		borders[key] = lib.CopyThemeBorder(defaultStyle)
	end
	if overrides then
		for _, key in ipairs(lib.BORDER_KEYS) do
			local value = overrides[key]
			if type(value) == "table" then
				borders[key] = lib.CopyThemeBorder(value)
			end
		end
		for alias, key in pairs(lib.BORDER_ALIASES) do
			local value = overrides[alias]
			if type(value) == "table" then
				borders[key] = lib.CopyThemeBorder(value)
			end
		end
	end
	return borders
end

function lib.ApplyThemeBorders(app)
	lib.ThemeBorders = lib.ResolveThemeBorders(app)
end

lib.ThemeBorders = lib.ResolveThemeBorders(nil)

local ASSET = {
	fallback = "Interface\\Icons\\INV_Misc_Gear_01",
	statusEnabled = "Interface\\RaidFrame\\ReadyCheck-Ready",
	statusProfile = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	statusVersionAtlas = "worldquest-tracker-questmarker",
	statusNewAtlas = "collections-icon-favorites",
}
local ICON_TEXTURES = {
	actionbar = "Interface\\Icons\\INV_Sword_04",
	actiontracker = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
	addonprofile = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	advanced = "Interface\\Icons\\INV_Misc_Gear_01",
	auction = "Interface\\Icons\\INV_Misc_Coin_01",
	autosell = "Interface\\Icons\\INV_Misc_Coin_02",
	bags = "Interface\\Icons\\INV_Misc_Bag_08",
	bagscategories = "Interface\\Icons\\INV_Misc_Bag_10",
	bars = "Interface\\Icons\\INV_Misc_Desecrated_PlateBelt",
	bank = "Interface\\Icons\\INV_Misc_Bag_10",
	buff = "Interface\\Icons\\Spell_Holy_BlessingOfKings",
	castbar = "Interface\\Icons\\Spell_Nature_TimeStop",
	chat = "Interface\\Icons\\INV_Letter_15",
	chatbubbles = "Interface\\Icons\\INV_Letter_15",
	chathistory = "Interface\\Icons\\INV_Misc_Note_03",
	chatwindow = "Interface\\Icons\\INV_Letter_15",
	combat = "Interface\\Icons\\Ability_Warrior_BattleShout",
	combatlogging = "Interface\\Icons\\INV_Misc_Note_05",
	community = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
	container = "Interface\\Icons\\INV_Box_01",
	containeractions = "Interface\\Icons\\INV_Box_01",
	crafting = "Interface\\Icons\\Trade_BlackSmithing",
	data = "Interface\\Icons\\INV_Misc_Note_05",
	death = "Interface\\Icons\\Ability_Creature_Cursed_02",
	diagnostics = "Interface\\Icons\\INV_Gizmo_02",
	dialogs = "Interface\\Icons\\INV_Misc_Note_06",
	dialogsconfirmations = "Interface\\Icons\\INV_Misc_Note_06",
	cooldown = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	cooldownpanels = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	dashboard = "Interface\\Icons\\INV_Misc_Gear_01",
	dungeons = "Interface\\Icons\\INV_Misc_Map_01",
	economy = "Interface\\Icons\\INV_Misc_Coin_01",
	focus = "Interface\\Icons\\Ability_Hunter_SniperShot",
	gameplay = "Interface\\Icons\\Ability_DualWield",
	general = "Interface\\Icons\\INV_Misc_Wrench_01",
	gearupgrades = "Interface\\Icons\\INV_Chest_Plate18",
	goldtracking = "Interface\\Icons\\INV_Misc_Coin_01",
	groupfinder = "Interface\\Icons\\Achievement_GuildPerk_HaveGroupWillTravel",
	help = "Interface\\Icons\\INV_Misc_Book_09",
	importexport = "Interface\\Icons\\INV_Misc_ArrowUp",
	includelists = "Interface\\Icons\\INV_Misc_Note_05",
	instantmessenger = "Interface\\Icons\\INV_Letter_15",
	interface = "Interface\\Icons\\INV_Misc_Monitor_01",
	loot = "Interface\\Icons\\INV_Misc_Bag_08",
	mailbox = "Interface\\Icons\\INV_Letter_16",
	map = "Interface\\Icons\\INV_Misc_Map_01",
	markers = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
	macros = "Interface\\Icons\\INV_Misc_Note_05",
	mouseaccessibility = "Interface\\Icons\\INV_Misc_Mouse_01",
	movementinput = "Interface\\Icons\\INV_Boots_Plate_01",
	mover = "Interface\\Icons\\Ability_Hunter_MasterMarksman",
	nameplate = "Interface\\Icons\\INV_Misc_Tournaments_banner_Human",
	popups = "Interface\\Icons\\INV_Misc_Note_01",
	privateaura = "Interface\\Icons\\Spell_Arcane_PrismaticCloak",
	privacy = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
	profiles = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	questing = "Interface\\Icons\\INV_Misc_Note_04",
	reset = "Interface\\Icons\\Ability_Hunter_MasterMarksman",
	resource = "Interface\\Icons\\INV_Misc_Food_100",
	repair = "Interface\\Icons\\Trade_BlackSmithing",
	settingspage = "Interface\\Icons\\INV_Misc_Gear_01",
	skinner = "Interface\\Icons\\INV_Misc_EngGizmos_17",
	social = "Interface\\Icons\\INV_Letter_15",
	sound = "Interface\\Icons\\INV_Misc_Note_01",
	support = "Interface\\Icons\\INV_Misc_QuestionMark",
	system = "Interface\\Icons\\INV_Gizmo_01",
	systemdebug = "Interface\\Icons\\INV_Gizmo_02",
	talentreminder = "Interface\\Icons\\Ability_Marksmanship",
	teleports = "Interface\\Icons\\Spell_Arcane_TeleportDalaran",
	tooltip = "Interface\\Icons\\INV_Misc_Note_03",
	unitframes = "Interface\\Icons\\INV_Misc_GroupLooking",
	uiutilities = "Interface\\Icons\\INV_Misc_Wrench_01",
	vendor = "Interface\\Icons\\INV_Misc_Coin_02",
	vendorsservices = "Interface\\Icons\\INV_Misc_Coin_02",
	visibility = "Interface\\Icons\\Ability_Stealth",
}

local CATEGORY_ICON_KEYS = {
	advanced = "advanced",
	dashboard = "dashboard",
	economy = "economy",
	gameplay = "gameplay",
	general = "general",
	interface = "interface",
	profiles = "profiles",
	social = "social",
	sound = "sound",
}

local frames = lib.frames or {}
lib.frames = frames

local BASIC_FRAME_BORDER_REGIONS = {
	"TopBorder",
	"BottomBorder",
	"LeftBorder",
	"RightBorder",
	"TopLeftCorner",
	"TopRightCorner",
	"BotLeftCorner",
	"BotRightCorner",
	"InsetBorderTop",
	"InsetBorderBottom",
	"InsetBorderLeft",
	"InsetBorderRight",
	"InsetBorderTopLeft",
	"InsetBorderTopRight",
	"InsetBorderBottomLeft",
	"InsetBorderBottomRight",
}

local function setBasicFrameBorderAlpha(frame, alpha)
	for _, key in ipairs(BASIC_FRAME_BORDER_REGIONS) do
		local region = frame[key]
		if region and region.SetAlpha then
			region:SetAlpha(alpha)
		end
	end
end

local function getThemeBorder(styleOrKey)
	if type(styleOrKey) == "table" then
		return lib.CopyThemeBorder(styleOrKey) or lib.ThemeBorders.default
	end
	local key = tostring(styleOrKey or "default")
	return lib.ThemeBorders[key] or lib.ThemeBorders.default or lib.DEFAULT_BORDER_STYLE
end

local function applyBackdropDefinition(frame, styleOrKey)
	if not frame or not frame.SetBackdrop then
		return
	end
	local style = getThemeBorder(styleOrKey)
	frame:SetBackdrop({
		bgFile = style.bgFile,
		edgeFile = style.edgeFile,
		tile = style.tile,
		tileSize = style.tileSize,
		edgeSize = style.edgeSize,
		insets = lib.CopyThemeInset(style.insets),
	})
end

local function applyBackdrop(frame, bg, border, styleOrKey)
	if not frame.SetBackdrop then
		if frame.Bg and frame.Bg.SetColorTexture then
			frame.Bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
		end
		if frame.InsetBg and frame.InsetBg.SetColorTexture then
			frame.InsetBg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
		end
		for _, key in ipairs(BASIC_FRAME_BORDER_REGIONS) do
			local region = frame[key]
			if region and region.SetVertexColor then
				region:SetVertexColor(border[1], border[2], border[3], border[4])
			end
		end
		return
	end
	frame._LibSettingsDesignerBorderStyleKey = type(styleOrKey) == "string" and styleOrKey or frame._LibSettingsDesignerBorderStyleKey
	frame._LibSettingsDesignerBorderStyle = type(styleOrKey) == "table" and styleOrKey or frame._LibSettingsDesignerBorderStyle
	applyBackdropDefinition(frame, styleOrKey or frame._LibSettingsDesignerBorderStyleKey or frame._LibSettingsDesignerBorderStyle or "default")
	frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
	frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

local function getAssetRoot(app)
	local opts = app and app.opts
	local root = opts and opts.assetRoot
	if type(root) ~= "string" or root == "" then
		local addonFolder = opts and (opts.addonFolder or opts.folder) or nil
		root = "Interface\\AddOns\\"
			.. tostring(addonFolder or (app and app.id) or "LibSettingsDesigner")
			.. "\\libs\\LibSettingsDesigner\\Assets\\"
	end
	local last = root:sub(-1)
	if last ~= "\\" and last ~= "/" then
		root = root .. "\\"
	end
	return root
end

local function getLibAssetPath(app, fileName)
	return getAssetRoot(app) .. fileName
end

local function createAssetArrow(parent, app, size, family, direction)
	local arrow = parent:CreateTexture(nil, "OVERLAY")
	arrow:SetSize(size or 14, size or 14)
	local prefix = family == "collapse" and "LibSettingsDesigner_Collapse" or "LibSettingsDesigner_Dropdown"
	local suffix = direction == "right" and "Right"
		or direction == "left" and "Left"
		or direction == "up" and "Up"
		or "Down"
	local fileName = prefix .. suffix .. ".tga"
	arrow:SetTexture(getLibAssetPath(app, fileName))
	arrow:SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], TEXT.gold[4] or 1)
	return arrow
end

local function createDropdownArrow(parent, app, size)
	return createAssetArrow(parent, app, size, "dropdown", "down")
end

local function createCollapseArrow(parent, app, size, collapsed)
	return createAssetArrow(parent, app, size, "collapse", collapsed and "right" or "down")
end

local function applyWindowBorder(frame, app)
	if not frame or frame.WindowBorder then
		return
	end
	local borderPath = getAssetRoot(app) .. "PanelBorder_"
	local cornerSize = 58
	local edgeThickness = 58
	local cornerOffset = 10
	local rightOffset = cornerOffset + 6
	local parts = {}

	local function makePart(key, subLevel)
		local texture = frame:CreateTexture(nil, "BORDER", nil, subLevel or 0)
		texture:SetTexture(borderPath .. key .. ".tga")
		texture:SetAlpha(1)
		parts[key] = texture
		return texture
	end

	local tl = makePart("tl", 1)
	tl:SetSize(cornerSize, cornerSize)
	tl:SetPoint("TOPLEFT", frame, "TOPLEFT", -cornerOffset, cornerOffset)

	local tr = makePart("tr", 1)
	tr:SetSize(cornerSize, cornerSize)
	tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", rightOffset, cornerOffset)

	local bl = makePart("bl", 1)
	bl:SetSize(cornerSize, cornerSize)
	bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -cornerOffset, -cornerOffset)

	local br = makePart("br", 1)
	br:SetSize(cornerSize, cornerSize)
	br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rightOffset, -cornerOffset)

	local top = makePart("t", 0)
	top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
	top:SetHeight(edgeThickness)
	top:SetHorizTile(true)

	local bottom = makePart("b", 0)
	bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
	bottom:SetHeight(edgeThickness)
	bottom:SetHorizTile(true)

	local left = makePart("l", 0)
	left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
	left:SetWidth(edgeThickness)
	left:SetVertTile(true)

	local right = makePart("r", 0)
	right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
	right:SetWidth(edgeThickness)
	right:SetVertTile(true)

	frame.WindowBorder = parts
	setBasicFrameBorderAlpha(frame, 0)
end

local function setBackdropColor(frame, color)
	frame:SetBackdropColor(color[1], color[2], color[3], color[4])
end

local function setBackdropBorderColor(frame, color)
	if frame and frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
	end
end

local function setFrameBackdrop(frame, bg, border, styleOrKey)
	if styleOrKey or frame._LibSettingsDesignerBorderStyleKey or frame._LibSettingsDesignerBorderStyle then
		applyBackdropDefinition(frame, styleOrKey or frame._LibSettingsDesignerBorderStyleKey or frame._LibSettingsDesignerBorderStyle)
	end
	setBackdropColor(frame, bg)
	setBackdropBorderColor(frame, border)
	if frame and frame.SetBorderColor then
		frame:SetBorderColor(border)
	end
end

local function setTextColor(fontString, color)
	if fontString and color then
		fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
	end
end

function lib.IsButtonActuallyEnabled(button)
	if not button or type(button.IsEnabled) ~= "function" then
		return true
	end
	local ok, enabled = pcall(button.IsEnabled, button)
	if not ok then
		return true
	end
	return enabled == true or enabled == 1
end

function lib.IsWidgetDisabled(widget)
	if not widget then
		return false
	end
	if widget._eqolDisabled == true then
		return true
	end
	local owner = widget._eqolOwner or widget._eqolOwnerRow
	if owner and owner._eqolDisabled == true then
		return true
	end
	return not lib.IsButtonActuallyEnabled(widget)
end

function lib.ApplyFlatButtonVisual(button)
	if not button then return end
	if lib.IsWidgetDisabled(button) then
		setFrameBackdrop(button, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER)
		if button.Text then setTextColor(button.Text, TEXT.disabled) end
		if button.Icon and button.Icon.SetAlpha then button.Icon:SetAlpha(0.45) end
		if button.Arrow and button.Arrow.SetVertexColor then
			button.Arrow:SetVertexColor(TEXT.disabled[1], TEXT.disabled[2], TEXT.disabled[3], TEXT.disabled[4] or 1)
			button.Arrow:SetAlpha(0.55)
		end
		return
	end
	if button.selected then
		setFrameBackdrop(button, SELECTED_BG, CARD_BORDER_HOVER)
	else
			setFrameBackdrop(
				button,
				button._eqolNormalBg or lib.ThemeColors.buttonBg,
				button._eqolNormalBorder or lib.ThemeColors.buttonBorder
			)
	end
	if button.Text then setTextColor(button.Text, TEXT.main) end
	if button.Icon and button.Icon.SetAlpha then button.Icon:SetAlpha(1) end
	if button.Arrow and button.Arrow.SetVertexColor then
		button.Arrow:SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], TEXT.gold[4] or 1)
		button.Arrow:SetAlpha(1)
	end
end

local function getEffectiveScale(frame)
	if frame and frame.GetEffectiveScale then
		local scale = frame:GetEffectiveScale()
		if scale and scale > 0 then
			return scale
		end
	end
	if UIParent and UIParent.GetEffectiveScale then
		local scale = UIParent:GetEffectiveScale()
		if scale and scale > 0 then
			return scale
		end
	end
	return 1
end

local function snap(frame, value)
	local numberValue = tonumber(value) or 0
	local scale = getEffectiveScale(frame)
	return math.floor((numberValue * scale) + 0.5) / scale
end

local function snapPoint(frame, point, relativeTo, relativePoint, x, y)
	frame:SetPoint(point, relativeTo, relativePoint, snap(relativeTo or frame, x or 0), snap(relativeTo or frame, y or 0))
end

local function snapSize(frame, width, height)
	frame:SetSize(snap(frame, width or 0), snap(frame, height or 0))
end

local function getPixelSize(frame)
	return 1 / getEffectiveScale(frame)
end

local function preparePixelTexture(texture)
	if texture.SetSnapToPixelGrid then
		texture:SetSnapToPixelGrid(false)
	end
	if texture.SetTexelSnappingBias then
		texture:SetTexelSnappingBias(0)
	end
end

local function setPixelBorderColor(frame, color)
	if not frame or not color then
		return
	end
	local px = getPixelSize(frame)
	for _, texture in ipairs({ frame.BorderTop, frame.BorderBottom, frame.BorderLeft, frame.BorderRight }) do
		if texture then
			texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
		end
	end
	if frame.BorderTop then frame.BorderTop:SetHeight(px) end
	if frame.BorderBottom then frame.BorderBottom:SetHeight(px) end
	if frame.BorderLeft then frame.BorderLeft:SetWidth(px) end
	if frame.BorderRight then frame.BorderRight:SetWidth(px) end
end

local function createPixelBorder(frame, borderColor)
	if frame.BorderTop then
		setPixelBorderColor(frame, borderColor)
		return
	end
	frame.BorderTop = frame:CreateTexture(nil, "OVERLAY", nil, 1)
	frame.BorderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.BorderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	preparePixelTexture(frame.BorderTop)

	frame.BorderBottom = frame:CreateTexture(nil, "OVERLAY", nil, 1)
	frame.BorderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.BorderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	preparePixelTexture(frame.BorderBottom)

	frame.BorderLeft = frame:CreateTexture(nil, "OVERLAY", nil, 1)
	frame.BorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.BorderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	preparePixelTexture(frame.BorderLeft)

	frame.BorderRight = frame:CreateTexture(nil, "OVERLAY", nil, 1)
	frame.BorderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.BorderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	preparePixelTexture(frame.BorderRight)

	frame.SetBorderColor = frame.SetBorderColor or setPixelBorderColor
	setPixelBorderColor(frame, borderColor)
end

local function applyHoverState(frame, normalBg, hoverBg, normalBorder, hoverBorder)
	frame:SetScript("OnEnter", function(self)
		if self._eqolDisabled then
			return
		end
		setFrameBackdrop(self, hoverBg or CARD_BG_HOVER, hoverBorder or CARD_BORDER_HOVER)
	end)
	frame:SetScript("OnLeave", function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_ROW_BG, DISABLED_ROW_BORDER)
			return
		end
		setFrameBackdrop(self, normalBg or CARD_BG, normalBorder or CARD_BORDER)
	end)
end

local getControlType

local function styleInlineSettingRow(row)
	applyBackdrop(row, ROW_BG, ROW_BORDER, "row")
	createPixelBorder(row, ROW_BORDER)
	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		if self._eqolDisabled then
			return
		end
		setFrameBackdrop(self, ROW_HOVER_BG, ROW_HOVER_BORDER)
		if self.SetBorderColor then self:SetBorderColor(ROW_HOVER_BORDER) end
	end)
	row:SetScript("OnLeave", function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_ROW_BG, DISABLED_ROW_BORDER)
			if self.SetBorderColor then self:SetBorderColor(DISABLED_ROW_BORDER) end
			return
		end
		setFrameBackdrop(self, ROW_BG, ROW_BORDER)
		if self.SetBorderColor then self:SetBorderColor(ROW_BORDER) end
	end)
	row.Separator = row:CreateTexture(nil, "BACKGROUND")
	preparePixelTexture(row.Separator)
	row.Separator:SetColorTexture(ROW_SEPARATOR[1], ROW_SEPARATOR[2], ROW_SEPARATOR[3], ROW_SEPARATOR[4])
	row.Separator:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", ROW_INSET, 0)
	row.Separator:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -ROW_INSET, 0)
	row.Separator:SetHeight(getPixelSize(row))
end

local function getControlLayoutType(control)
	local controlType = getControlType(control)
	if controlType == "toggle" or controlType == "checkbox" then
		return "boolean"
	end
	if controlType == "slider" or controlType == "dropdown" or controlType == "sounddropdown"
		or controlType == "multidropdown"
		or controlType == "checkboxdropdown"
		or controlType == "input" or controlType == "colorpicker" then
		return "stacked"
	end
	return "complex"
end

local function hasUsefulDescription(control)
	return type(control and control.description) == "string" and control.description:gsub("%s+", "") ~= ""
end

function lib.IsCompactDensity(state)
	return state and state.density == "compact"
end

local function getSettingRowHeight(control, state)
	local layoutType = getControlLayoutType(control)
	local controlType = getControlType(control)
	if controlType == "custom" and type(control.getHeight) == "function" then
		local ok, height = pcall(control.getHeight, state and state.app, control, state)
		if ok and tonumber(height) then
			return math.max(44, tonumber(height))
		end
	elseif controlType == "custom" then
		return tonumber(control.height or control.rowHeight) or 220
	end
	if lib.IsCompactDensity(state) then
		if layoutType == "boolean" then
			return 44
		end
		if controlType == "slider" then
			return 66
		end
		if controlType == "colorpalette" then
			return lib.GetColorOverridesRowHeight(control, state and state.app)
		end
		if controlType == "reorderlist" then
			return lib.GetReorderListRowHeight(control)
		end
		if layoutType == "stacked" then
			return 62
		end
		return 64
	end
	if layoutType == "boolean" then
		return BOOLEAN_ROW_HEIGHT
	end
	if controlType == "slider" then
		return hasUsefulDescription(control) and SLIDER_ROW_HEIGHT or SLIDER_ROW_HEIGHT_COMPACT
	end
	if controlType == "colorpalette" then
		return lib.GetColorOverridesRowHeight(control, state and state.app)
	end
	if controlType == "reorderlist" then
		return lib.GetReorderListRowHeight(control)
	end
	if layoutType == "stacked" then
		return STACKED_ROW_HEIGHT
	end
	return COMPLEX_ROW_HEIGHT
end

local function getFieldControlWidth(rowWidth)
	return math.max(FIELD_CONTROL_WIDTH_MIN, math.min(FIELD_CONTROL_WIDTH_MAX, (tonumber(rowWidth) or 0) - 36))
end

local function getSliderControlWidth(rowWidth, labelWidth, sliderGap)
	local available = (tonumber(rowWidth) or 0)
		- (FIELD_CONTROL_LEFT * 2)
		- ((labelWidth or 0) * 2)
		- ((sliderGap or 0) * 2)
	return math.max(
		120,
		available
	)
end

function lib.GetSliderScaleLabelWidth(control)
	local minText = lib.FormatControlValue(control, control and control.min)
	local maxText = lib.FormatControlValue(control, control and control.max)
	local length = math.max(#tostring(minText or ""), #tostring(maxText or ""))
	return math.max(SLIDER_SCALE_LABEL_WIDTH, math.min(76, length * 7 + 10))
end

local function getAddonIcon(app)
	return app and app.opts and app.opts.icon or ICON_TEXTURES.dashboard or ASSET.fallback
end

local function getAppIconTexture(app, key)
	local textures = app and app.opts and app.opts.iconTextures
	if type(textures) == "table" and textures[key] then
		return textures[key]
	end
	return ICON_TEXTURES[key] or ASSET.fallback
end

local function getAppCategoryIconTexture(app, categoryID)
	local textures = app and app.opts and app.opts.categoryIconTextures
	if type(textures) == "table" and textures[categoryID] then
		return textures[categoryID]
	end
	return nil
end

local function resolveCategoryIcon(app, category)
	local appIcon = category and getAppCategoryIconTexture(app, category.id)
	if appIcon then
		return appIcon
	end
	if category and category.icon then
		return category.icon
	end
	if category and category.iconAtlas then
		return category.iconAtlas, true
	end
	local iconKey = category and CATEGORY_ICON_KEYS[category.id]
	return getAppIconTexture(app, iconKey or "advanced")
end

local function resolvePageIcon(app, page)
	if page and page.icon then
		return page.icon
	end
	if page and page.iconAtlas then
		return page.iconAtlas, true
	end
	if page and page.iconKey then
		return getAppIconTexture(app, page.iconKey)
	end
	return getAppIconTexture(app, "advanced")
end

local function createIcon(parent, source, size, isAtlas)
	local icon = parent:CreateTexture(nil, "OVERLAY")
	icon:SetSize(size or 24, size or 24)
	if isAtlas and source and icon.SetAtlas then
		local hasAtlas = type(source) == "string"
			and (not C_Texture or not C_Texture.GetAtlasInfo or C_Texture.GetAtlasInfo(source))
		local ok = hasAtlas and pcall(icon.SetAtlas, icon, source, false)
		if ok then
			return icon
		end
		source = ASSET.fallback
	end
	icon:SetTexture(source or ASSET.fallback)
	return icon
end

local function createIconPlate(parent, source, size, isAtlas)
	local plate = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	plate:SetSize(size or 42, size or 42)
	applyBackdrop(plate, { 0.015, 0.015, 0.018, 0.80 }, { 0.55, 0.42, 0.18, 0.75 }, "card")
	plate.Icon = createIcon(plate, source, (size or 42) - 6, isAtlas)
	plate.Icon:SetPoint("CENTER")
	return plate
end

local function clearFrameList(list)
	for _, frame in ipairs(list) do
		frame:Hide()
		frame:SetParent(nil)
	end
	for i = #list, 1, -1 do
		list[i] = nil
	end
end

function lib.ReleaseCustomHandle(state, key)
	if not (state and state.customHandles and key) then
		return
	end
	local entry = state.customHandles[key]
	state.customHandles[key] = nil
	local handle = type(entry) == "table" and entry.handle or entry
	local owner = type(entry) == "table" and entry.owner or nil
	if owner and type(owner.release) == "function" then
		pcall(owner.release, handle, state.app, owner, state)
	elseif type(handle) == "table" and type(handle.Release) == "function" then
		pcall(handle.Release, handle, state.app, owner, state)
	end
end

function lib.ReleaseAllCustomHandles(state)
	if not (state and state.customHandles) then
		return
	end
	for key, handle in pairs(state.customHandles) do
		local _ = handle
		lib.ReleaseCustomHandle(state, key)
	end
end

local function trackFrame(list, frame)
	list[#list + 1] = frame
	return frame
end

local createText

function createText(parent, template, text, color, justify)
	local textFrame = CreateFrame("Frame", nil, parent)
	textFrame.Text = textFrame:CreateFontString(nil, "OVERLAY", template or FONT_TEXT)
	textFrame.Text:SetAllPoints(textFrame)
	textFrame.Text:SetJustifyH(justify or "LEFT")
	textFrame.Text:SetJustifyV("TOP")
	textFrame.Text:SetWordWrap(true)
	textFrame.Text:SetText(text or "")
	setTextColor(textFrame.Text, color)
	return textFrame
end

local function createContentFrame(state, height)
	local frame = trackFrame(state.contentFrames, CreateFrame("Frame", nil, state.content, "BackdropTemplate"))
	local snappedY = snap(state.content, state.y)
	frame._LibSettingsDesignerContentY = snappedY
	snapPoint(frame, "TOPLEFT", state.content, "TOPLEFT", 0, snappedY)
	snapPoint(frame, "TOPRIGHT", state.content, "TOPRIGHT", 0, snappedY)
	frame:SetHeight(snap(frame, height))
	state.y = snap(state.content, state.y - height)
	return frame
end

local function createSidebarFrame(state, height)
	local frame = trackFrame(state.sidebarFrames, CreateFrame("Button", nil, state.frame.Sidebar, "BackdropTemplate"))
	frame:SetPoint("TOPLEFT", state.frame.Sidebar, "TOPLEFT", 0, state.sidebarY)
	frame:SetPoint("TOPRIGHT", state.frame.Sidebar, "TOPRIGHT", 0, state.sidebarY)
	frame:SetHeight(height)
	state.sidebarY = state.sidebarY - height
	return frame
end

local function getLibLocale()
	local locale = _G.GetLocale and _G.GetLocale() or "enUS"
	return lib.LOCALES[locale] or lib.LOCALES.enUS
end

local function getLocale(app)
	local appLocale = app and app.opts and app.opts.locale or nil
	local libLocale = getLibLocale()
	if type(appLocale) ~= "table" then
		return libLocale
	end
	return setmetatable({}, {
		__index = function(_, key)
			if libLocale[key] ~= nil then
				return libLocale[key]
			end
			if appLocale[key] ~= nil then
				return appLocale[key]
			end
			return lib.LOCALES.enUS[key]
		end,
	})
end

local function getSettingCountText(app, count)
	local L = getLocale(app)
	local label = count == 1 and (L["configCenterSetting"] or "setting") or (L["configCenterSettings"] or "settings")
	return tostring(count) .. " " .. label
end

local function getVisiblePageControls(app, page)
	if app and type(app.GetPageControls) == "function" then
		return app:GetPageControls(page)
	end
	local controls = {}
	for _, control in ipairs((page and page.controls) or {}) do
		if not app or not app.IsControlVisible or app:IsControlVisible(control) then
			controls[#controls + 1] = control
		end
	end
	return controls
end

function lib.GetPageSettingCount(app, page)
	if app and type(app.GetPageSettingCount) == "function" then
		return app:GetPageSettingCount(page)
	end
	return #getVisiblePageControls(app, page)
end

function lib.GetPageCustomizedCount(app, page)
	if app and type(app.GetPageCustomizedCount) == "function" then
		return app:GetPageCustomizedCount(page)
	end
	local count = 0
	for _, control in ipairs(getVisiblePageControls(app, page)) do
		if app and type(app.IsControlCustomized) == "function" and app:IsControlCustomized(control) then
			count = count + 1
		end
	end
	return count
end

function lib.GetCategoryCustomizedCount(app, categoryID)
	if app and type(app.GetCategoryCustomizedCount) == "function" then
		return app:GetCategoryCustomizedCount(categoryID)
	end
	local count = 0
	if app and type(app.GetPages) == "function" then
		for _, page in ipairs(app:GetPages(categoryID)) do
			count = count + lib.GetPageCustomizedCount(app, page)
		end
	end
	return count
end

function lib.GetGroupCustomizedCount(app, group)
	local count = 0
	for _, control in ipairs((group and group.controls) or {}) do
		if app and type(app.IsControlVisible) == "function" and type(app.IsControlCustomized) == "function"
			and app:IsControlVisible(control)
			and app:IsControlCustomized(control)
		then
			count = count + 1
		end
	end
	return count
end

local function getAppTitle(app)
	return (app and app.opts and app.opts.title) or (app and app.id) or "Settings"
end

local function getPagePath(app, page)
	local category = page and app.categoriesByID[page.category or ""]
	if category and page then
		return (category.title or category.id) .. " > " .. (page.title or page.id)
	end
	return page and (page.title or page.id) or ""
end

local function getControlPath(app, control)
	return getPagePath(app, app:GetPage(control.pageID))
end

local function normalizePageLookupText(page)
	return tostring((page and page.id or "") .. " " .. (page and page.title or "")):lower():gsub("[^%w]+", "")
end

local function normalizeLookupKey(value)
	return tostring(value or ""):lower():gsub("[^%w]+", "")
end

function lib.GetBestPageFallback(lookup, fallbackTable)
	local bestKey, bestValue
	for keyword, value in pairs(fallbackTable or {}) do
		local normalizedKey = normalizeLookupKey(keyword)
		if normalizedKey ~= "" and lookup:find(normalizedKey, 1, true) and (not bestKey or #normalizedKey > #bestKey) then
			bestKey = normalizedKey
			bestValue = value
		end
	end
	return bestValue
end

local function getPageDescriptionLocaleKey(app, page)
	if page and page.descriptionKey and page.descriptionKey ~= "" then
		return page.descriptionKey
	end
	local keys = app and app.opts and (app.opts.pageDescriptionKeys or app.opts.pageDescriptionLocaleKeys)
	if type(keys) ~= "table" then
		return nil
	end
	local candidates = {
		page and page.pageKey,
		page and page.newTagID,
		page and page.key,
		page and page.id,
	}
	for _, candidate in ipairs(candidates) do
		if candidate and keys[candidate] then
			return keys[candidate]
		end
		local normalized = normalizeLookupKey(candidate)
		if normalized ~= "" and keys[normalized] then
			return keys[normalized]
		end
	end
	return lib.GetBestPageFallback(normalizePageLookupText(page), keys)
end

local function getPageDescription(app, page)
	if page and page.description and page.description ~= "" then
		return page.description
	end
	local L = getLocale(app)
	local localeKey = getPageDescriptionLocaleKey(app, page)
	if localeKey and L[localeKey] and L[localeKey] ~= "" then
		return L[localeKey]
	end
	if page then
		return getSettingCountText(app, #getVisiblePageControls(app, page))
	end
	return ""
end

function lib.StripColorCodes(text)
	text = tostring(text or "")
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	return text
end

function lib.CompactDescription(text)
	text = lib.StripColorCodes(text)
	text = text:gsub("\\\n", "\n")
	text = text:gsub("[%s\r\n]+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	if #text <= 118 then
		return text
	end
	local sentence = text:match("^(.-[%.%!%?])%s+")
	if sentence and #sentence >= 24 and #sentence <= 118 then
		return sentence
	end
	return text:sub(1, 115):gsub("%s+%S*$", "") .. "..."
end

function lib.GetDensityLabel(app, density)
	local L = getLocale(app)
	if density == "compact" then
		return L["configCenterDensityCompact"] or "Compact"
	end
	return L["configCenterDensityComfortable"] or "Comfortable"
end

function lib.GetConfiguredDensity(app)
	local opts = app and app.opts
	local density
	if opts and type(opts.getDensity) == "function" then
		local ok, value = pcall(opts.getDensity, app)
		if ok then
			density = value
		end
	end
	if density ~= "compact" and density ~= "comfortable" then
		density = opts and opts.density
	end
	if type(density) == "function" then
		local ok, value = pcall(density, app)
		if ok then
			density = value
		end
	end
	if density == "compact" or density == "comfortable" then
		return density
	end
	return nil
end

function lib.ShouldShowDensityButton(app)
	local opts = app and app.opts
	if opts and type(opts.showDensityButton) == "function" then
		local ok, value = pcall(opts.showDensityButton, app)
		if ok then
			return value ~= false
		end
	end
	return not (opts and opts.showDensityButton == false)
end

function lib.UpdateDensityButton(frame, state)
	if not frame or not frame.DensityButton then
		return
	end
	frame.DensityButton:SetShown(lib.ShouldShowDensityButton(state and state.app))
	local label = lib.GetDensityLabel(state and state.app, state and state.density)
	frame.DensityButton.Text:SetText(label)
end

local function getTopbarOptions(app)
	local opts = app and app.opts
	local topbar = opts and (opts.topbar or opts.header or opts.topBar)
	return type(topbar) == "table" and topbar or {}
end

local function resolveTopbarOption(app, key, defaultValue)
	local topbar = getTopbarOptions(app)
	local value = topbar[key]
	if type(value) == "function" then
		local ok, result = pcall(value, app)
		if ok then
			value = result
		else
			value = nil
		end
	end
	if value == nil then
		return defaultValue
	end
	return value
end

local function isTopbarActionVisible(action, app, state)
	if type(action) ~= "table" then
		return false
	end
	if action.hidden == true or action.visible == false then
		return false
	end
	local visible = action.isVisible or action.visibleWhen or action.visible
	if type(visible) == "function" then
		local ok, result = pcall(visible, app, action, state)
		return ok and result ~= false
	end
	return true
end

local function isTopbarActionEnabled(action, app, state)
	local enabled = action.isEnabled or action.enabledWhen or action.enabled
	if type(enabled) == "function" then
		local ok, result = pcall(enabled, app, action, state)
		return not ok or result ~= false
	end
	return enabled ~= false and action.disabled ~= true
end

local function getTopbarActionText(action, app, state)
	local text = action.label or action.text or action.title or action.id or ""
	if type(text) == "function" then
		local ok, result = pcall(text, app, action, state)
		if ok then
			text = result
		else
			text = ""
		end
	end
	return lib.NormalizeTextValue(text)
end

local function getTopbarActionTooltip(action, app, state)
	local tooltip = action.tooltip or action.description or action.desc
	if type(tooltip) == "function" then
		local ok, result = pcall(tooltip, app, action, state)
		if ok then
			tooltip = result
		else
			tooltip = nil
		end
	end
	return tooltip
end

local function getTopbarActionIcon(app, action)
	if action.icon then
		return action.icon
	end
	if action.iconKey then
		return getAppIconTexture(app, action.iconKey)
	end
	return nil
end

local function getTopbarActions(app, slot)
	local topbar = getTopbarOptions(app)
	local actions
	if slot == "title" then
		actions = topbar.titleActions or topbar.leftActions
	else
		actions = topbar.actions or topbar.rightActions
	end
	if type(actions) == "function" then
		local ok, result = pcall(actions, app, slot)
		actions = ok and result or nil
	end
	if type(actions) ~= "table" then
		return {}
	end
	return actions
end

local function addTopbarMenuEntry(rootDescription, entry, app, action, state)
	if type(entry) ~= "table" then
		return
	end
	if entry.hidden == true or entry.visible == false then
		return
	end
	local visible = entry.isVisible or entry.visibleWhen or entry.visible
	if type(visible) == "function" then
		local ok, result = pcall(visible, app, action, state, entry)
		if not ok or result == false then
			return
		end
	end
	if entry.divider and rootDescription.CreateDivider then
		rootDescription:CreateDivider()
		return
	end
	local text = lib.NormalizeTextValue(entry.label or entry.text or entry.title or entry.id)
	local children = entry.children or entry.entries or entry.menu
	if type(children) == "table" and rootDescription.CreateButton then
		local childRoot = rootDescription:CreateButton(text)
		for _, child in ipairs(children) do
			addTopbarMenuEntry(childRoot, child, app, action, state)
		end
		return
	end
	if entry.checked ~= nil or entry.isSelected or entry.setSelected then
		local isSelected = function()
			if type(entry.isSelected) == "function" then
				local ok, result = pcall(entry.isSelected, app, action, state, entry)
				return ok and result == true
			end
			if type(entry.checked) == "function" then
				local ok, result = pcall(entry.checked, app, action, state, entry)
				return ok and result == true
			end
			return entry.checked == true
		end
		local setSelected = function()
			if type(entry.setSelected) == "function" then
				pcall(entry.setSelected, app, action, state, entry)
			elseif type(entry.onClick) == "function" then
				pcall(entry.onClick, app, action, state, entry)
			end
		end
		if rootDescription.CreateCheckbox then
			rootDescription:CreateCheckbox(text, isSelected, setSelected)
		end
	elseif rootDescription.CreateButton then
		rootDescription:CreateButton(text, function()
			if type(entry.onClick) == "function" then
				pcall(entry.onClick, app, action, state, entry)
			end
		end)
	end
end

local function openTopbarActionMenu(button, action, app, state)
	if not MenuUtil or type(MenuUtil.CreateContextMenu) ~= "function" then
		return
	end
	MenuUtil.CreateContextMenu(button, function(owner, rootDescription)
		if type(action.menu) == "function" then
			pcall(action.menu, rootDescription, owner, app, action, state)
		elseif type(action.buildMenu) == "function" then
			pcall(action.buildMenu, rootDescription, owner, app, action, state)
		elseif type(action.setupMenu) == "function" then
			pcall(action.setupMenu, rootDescription, owner, app, action, state)
		else
			local entries = action.menu or action.menuItems or action.entries
			if type(entries) == "table" then
				for _, entry in ipairs(entries) do
					addTopbarMenuEntry(rootDescription, entry, app, action, state)
				end
			end
		end
	end)
end

local function topbarActionHasMenu(action)
	return type(action) == "table" and (
		type(action.menu) == "function"
			or type(action.buildMenu) == "function"
			or type(action.setupMenu) == "function"
			or type(action.menu) == "table"
			or type(action.menuItems) == "table"
			or type(action.entries) == "table"
	)
end

function lib.RefreshTopbar(frame, state)
	if not frame or not state then
		return
	end
	local app = state.app
	local topbar = getTopbarOptions(app)
	local titleWidth = tonumber(topbar.titleWidth) or 320
	if frame.Title then
		frame.Title:SetWidth(titleWidth)
	end
	lib.UpdateDensityButton(frame, state)
	local allActionButtons = {}
	local function configureActionButton(button, action)
		local label = getTopbarActionText(action, app, state)
		local icon = getTopbarActionIcon(app, action)
		local iconOnly = action.iconOnly == true or (icon and label == "")
		local width = tonumber(action.width) or (iconOnly and 32) or math.min(150, math.max(74, (#label * 7) + (icon and 36 or 24)))
		button._eqolTopbarAction = action
		button._eqolTopbarState = state
		button:SetSize(width, tonumber(action.height) or 28)
		button.Text:SetText(iconOnly and "" or label)
		if icon and not button.Icon then
			button.Icon = createIcon(button, icon, 18, action.iconAtlas == true)
			button.Icon:SetPoint("LEFT", button, "LEFT", iconOnly and 7 or 8, 0)
		end
		if button.Icon then
			button.Icon:SetShown(icon ~= nil)
			if icon then
				if action.iconAtlas == true and button.Icon.SetAtlas then
					pcall(button.Icon.SetAtlas, button.Icon, icon, false)
				else
					button.Icon:SetTexture(icon)
				end
			end
		end
		local enabled = isTopbarActionEnabled(action, app, state)
		button._eqolDisabled = not enabled
		button:SetEnabled(enabled)
		setFrameBackdrop(button, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		setTextColor(button.Text, TEXT.topbarGold)
		button:SetShown(true)
		return width
	end
	local function refreshSlot(slot, anchorFrame, leftGap)
		local buttons = slot == "title" and frame.TopbarTitleActionButtons or frame.TopbarActionButtons
		local previous = anchorFrame
		for index, action in ipairs(getTopbarActions(app, slot)) do
			local button = buttons[index]
			if button then
				allActionButtons[#allActionButtons + 1] = button
			end
			if button and isTopbarActionVisible(action, app, state) then
				configureActionButton(button, action)
				button:ClearAllPoints()
				button:SetPoint("LEFT", previous, previous == anchorFrame and "RIGHT" or "RIGHT", previous == anchorFrame and leftGap or 8, 0)
				previous = button
			elseif button then
				button._eqolTopbarAction = nil
				button._eqolTopbarState = nil
				button:Hide()
			end
		end
		for index = #getTopbarActions(app, slot) + 1, #buttons do
			buttons[index]:Hide()
		end
		return previous
	end
	refreshSlot("title", frame.Title, 12)
	local rightAnchor = frame.TopBar
	local rightPoint = "RIGHT"
	local rightOffset = -12
	local function placeRight(button)
		if not button or not button:IsShown() then
			return
		end
		button:ClearAllPoints()
		button:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
		rightAnchor = button
		rightPoint = "LEFT"
		rightOffset = -12
	end
	if frame.SearchShell then
		frame.SearchShell:SetShown(resolveTopbarOption(app, "showSearch", true) ~= false)
	end
	if frame.ResetButton then
		frame.ResetButton:SetShown(resolveTopbarOption(app, "showDefaults", true) ~= false)
	end
	if frame.DensityButton then
		frame.DensityButton:SetShown(resolveTopbarOption(app, "showDensity", true) ~= false and lib.ShouldShowDensityButton(app))
	end
	if frame.LockButton then
		frame.LockButton:SetShown(resolveTopbarOption(app, "showLock", true) ~= false)
	end
	placeRight(frame.ResetButton)
	placeRight(frame.DensityButton)
	placeRight(frame.LockButton)
	placeRight(frame.SearchShell)
	local rightButtons = frame.TopbarActionButtons
	for index, action in ipairs(getTopbarActions(app, "right")) do
		local button = rightButtons[index]
		if button then
			allActionButtons[#allActionButtons + 1] = button
		end
		if button and isTopbarActionVisible(action, app, state) then
			configureActionButton(button, action)
			button:ClearAllPoints()
			button:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
			rightAnchor = button
			rightPoint = "LEFT"
			rightOffset = -8
		elseif button then
			button._eqolTopbarAction = nil
			button._eqolTopbarState = nil
			button:Hide()
		end
	end
	for index = #getTopbarActions(app, "right") + 1, #rightButtons do
		rightButtons[index]:Hide()
	end
	for _, button in ipairs(allActionButtons) do
		local action = button._eqolTopbarAction
		button:SetScript("OnUpdate", action and action.pulse and function(self, elapsed)
			self._eqolTopbarPulse = (self._eqolTopbarPulse or 0) + (elapsed or 0)
			self:SetAlpha(0.74 + (0.26 * ((math.sin(self._eqolTopbarPulse * 4) + 1) * 0.5)))
		end or nil)
		if not (action and action.pulse) then
			button._eqolTopbarPulse = nil
			button:SetAlpha(1)
		end
	end
end

function lib.RefreshTopbarForApp(app)
	local frame = lib.GetFrame and lib:GetFrame(app)
	if frame and frame._LibSettingsDesignerState then
		lib.RefreshTopbar(frame, frame._LibSettingsDesignerState)
	end
end

function lib.GetPageAboutText(app, page)
	return getPageDescription(app, page)
end

function lib.EstimateTextHeight(text, width, lineHeight, minHeight)
	text = lib.StripColorCodes(text)
	text = text:gsub("\\\n", "\n")
	local charsPerLine = math.max(18, math.floor((tonumber(width) or 170) / 6.2))
	local lines = 0
	for paragraph in tostring(text or ""):gmatch("([^\n]*)\n?") do
		if paragraph == "" then
			lines = lines + 1
		else
			lines = lines + math.max(1, math.ceil(#paragraph / charsPerLine))
		end
	end
	return math.max(minHeight or 1, lines * (lineHeight or 13))
end

function lib.NormalizeNoteList(control)
	local notes = {}
	local function add(note)
		if not note then return end
		if type(note) == "string" then
			note = { text = note }
		elseif type(note) ~= "table" then
			return
		end
		local visibleFunc = note.visible or note.condition
		if type(visibleFunc) == "function" then
			local ok, visible = pcall(visibleFunc, control)
			if not ok or visible == false then return end
		end
		if type(note.text) == "string" and note.text:gsub("%s+", "") ~= "" then
			notes[#notes + 1] = note
		elseif type(note.blocks) == "table" then
			for _, block in ipairs(note.blocks) do
				if type(block) == "table" and ((type(block.text) == "string" and block.text:gsub("%s+", "") ~= "") or block.image or block.texture) then
					notes[#notes + 1] = note
					return
				end
			end
		end
	end
	add(control and control.note)
	add(control and control.richNote)
	local controlNotes = control and control.notes
	if type(controlNotes) == "string" then
		controlNotes = { { text = controlNotes } }
	elseif type(controlNotes) ~= "table" then
		controlNotes = {}
	end
	for _, note in ipairs(controlNotes) do
		add(note)
	end
	for _, note in ipairs(control and control.richNotes or {}) do
		add(note)
	end
	table.sort(notes, function(a, b)
		return (tonumber(a.order) or 0) < (tonumber(b.order) or 0)
	end)
	return notes
end

function lib.AddNoteText(panel, text, color, y, width, template)
	local cleanText = tostring(text or ""):gsub("\\\n", "\n")
	local inset = panel.NoteInset or 10
	local frame = createText(panel, template or FONT_TEXT, cleanText, type(color) == "table" and color or TEXT.muted)
	frame:SetWidth(width)
	if frame.Text and frame.Text.SetWidth then frame.Text:SetWidth(width) end
	local measuredHeight = frame.Text and frame.Text.GetStringHeight and frame.Text:GetStringHeight()
	local height = math.max(1, math.ceil(tonumber(measuredHeight) or lib.EstimateTextHeight(cleanText, width, 15, 18)))
	frame:SetPoint("TOPLEFT", panel, "TOPLEFT", inset, y)
	frame:SetPoint("RIGHT", panel, "RIGHT", -inset, 0)
	frame:SetHeight(height)
	return y - height - 6
end

function lib.RenderNoteBlock(panel, block, y, width)
	if type(block) == "string" then
		return lib.AddNoteText(panel, block, TEXT.main, y, width)
	end
	if type(block) ~= "table" then
		return y
	end
	if block.type == "spacer" then
		return y - (tonumber(block.height) or 8)
	end
	local texturePath = block.image or block.texture
	if texturePath then
		local inset = panel.NoteInset or 10
		local imageWidth = math.min(width, tonumber(block.width) or width)
		local imageHeight = tonumber(block.height) or math.floor(imageWidth * 0.56)
		local tex = panel:CreateTexture(nil, "ARTWORK")
		tex:SetTexture(texturePath)
		tex:SetPoint("TOPLEFT", panel, "TOPLEFT", inset, y)
		tex:SetSize(imageWidth, imageHeight)
		panel.Textures = panel.Textures or {}
		panel.Textures[#panel.Textures + 1] = tex
		return y - imageHeight - 6
	end
	if block.title then
		y = lib.AddNoteText(panel, block.title, TEXT.gold, y, width, FONT_TEXT)
	end
	if block.text then
		y = lib.AddNoteText(panel, block.text, block.color or TEXT.muted, y, width, block.font)
	end
	return y
end

local function getNoteImageWidth(note)
	local width = 0
	for _, block in ipairs(note and note.blocks or {}) do
		if type(block) == "table" and (block.image or block.texture) then
			width = math.max(width, tonumber(block.width) or 0)
		end
	end
	return width
end

local function getControlNotePanelWidth(control, notes)
	local baseWidth = tonumber(control and control.noteWidth) or 286
	local imageWidth = 0
	for _, note in ipairs(notes or {}) do
		imageWidth = math.max(imageWidth, getNoteImageWidth(note))
	end
	if imageWidth > 0 then
		return math.min(532, math.max(baseWidth, imageWidth + 20))
	end
	return baseWidth
end

function lib.HideControlNotePanel(state)
	if state and state.notePanel then
		state.notePanel:Hide()
	end
end

function lib.GetControlHoverNotes(state, control)
	local notes = lib.NormalizeNoteList(control)
	if lib.IsCompactDensity(state) and hasUsefulDescription(control) then
		local exists = false
		for _, note in ipairs(notes) do
			if note.text == control.description then
				exists = true
				break
			end
		end
		if not exists then
			notes[#notes + 1] = { text = control.description, order = -1000 }
		end
	end
	table.sort(notes, function(a, b)
		return (tonumber(a.order) or 0) < (tonumber(b.order) or 0)
	end)
	return notes
end

function lib.ShowControlNotePanel(state, row, control)
	local notes = lib.GetControlHoverNotes(state, control)
	if #notes == 0 or not state or not state.frame or not row then
		return
	end
	local panel = state.notePanel
	if not panel then
		panel = CreateFrame("Frame", nil, state.frame, "BackdropTemplate")
		panel:SetFrameStrata("TOOLTIP")
		panel:SetFrameLevel((state.frame:GetFrameLevel() or 1) + 50)
		state.notePanel = panel
	end
	panel:ClearAllPoints()
	panel:Hide()
	for _, child in ipairs({ panel:GetChildren() }) do
		child:Hide()
		child:SetParent(nil)
	end
	if panel.Textures then
		for _, texture in ipairs(panel.Textures) do
			texture:Hide()
		end
	end
	panel.Textures = {}
	applyBackdrop(panel, CARD_BG, { 0, 0, 0, 0 }, "card")
	createPixelBorder(panel, CARD_BORDER_HOVER)

	panel.NoteInset = 10
	local width = getControlNotePanelWidth(control, notes)
	local textWidth = width - (panel.NoteInset * 2)
	local y = -panel.NoteInset
	local L = getLocale(state and state.app)
	local label = L["configCenterNotes"] or "Notes"
	if label then
		y = lib.AddNoteText(panel, label, TEXT.gold, y, textWidth, FONT_HEADER)
	end
	for _, note in ipairs(notes) do
		if note.title then
			y = lib.AddNoteText(panel, note.title, TEXT.gold, y, textWidth, FONT_TEXT)
		end
		if note.text then
			y = lib.AddNoteText(panel, note.text, note.color or TEXT.main, y, textWidth, note.font)
		end
		for _, block in ipairs(note.blocks or {}) do
			y = lib.RenderNoteBlock(panel, block, y, textWidth)
		end
	end
	if y < -panel.NoteInset then
		y = y + 6
	end
	local height = math.max(40, math.abs(y) + panel.NoteInset)
	snapSize(panel, width, height)
	snapPoint(panel, "TOPLEFT", row, "TOPRIGHT", 12, 0)
	panel:Show()
end

function lib.AttachControlNoteHover(row, state, control)
	local notes = lib.GetControlHoverNotes(state, control)
	if #notes == 0 then
		return
	end
	row:SetScript("OnEnter", function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_ROW_BG, DISABLED_ROW_BORDER)
			if self.SetBorderColor then self:SetBorderColor(DISABLED_ROW_BORDER) end
			return
		end
		setFrameBackdrop(self, ROW_HOVER_BG, ROW_HOVER_BORDER)
		if self.SetBorderColor then self:SetBorderColor(ROW_HOVER_BORDER) end
		lib.ShowControlNotePanel(state, self, control)
	end)
	row:SetScript("OnLeave", function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_ROW_BG, DISABLED_ROW_BORDER)
			if self.SetBorderColor then self:SetBorderColor(DISABLED_ROW_BORDER) end
		else
			setFrameBackdrop(self, ROW_BG, ROW_BORDER)
			if self.SetBorderColor then self:SetBorderColor(ROW_BORDER) end
		end
		lib.HideControlNotePanel(state)
	end)
end

local function getPageCardDescription(app, page)
	local L = getLocale(app)
	if page and page.description and page.description ~= "" then
		return page.description
	end
	local localeKey = getPageDescriptionLocaleKey(app, page)
	if localeKey then
		return L[localeKey] or ""
	end
	return ""
end

function getControlType(control)
	local controlType = tostring(control and (control.type or control.sType) or "text"):lower()
	if controlType == "checkbox" then
		return "toggle"
	elseif controlType == "scrolldropdown" then
		return "dropdown"
	elseif controlType == "coloroverrides" or controlType == "coloroverride" then
		return "colorpalette"
	end
	return controlType
end

function lib.GetFallbackControlDescription(app, control)
	local L = getLocale(app)
	local controlType = getControlType(control)
	if controlType == "slider" then
		return L["configCenterSliderFallbackDesc"] or "Adjust this value."
	elseif controlType == "dropdown" or controlType == "sounddropdown" then
		return L["configCenterDropdownFallbackDesc"] or "Choose one of the available options."
	elseif controlType == "multidropdown" then
		return L["configCenterMultiDropdownFallbackDesc"] or "Choose one or more options."
	elseif controlType == "checkboxdropdown" then
		return L["configCenterCheckboxDropdownFallbackDesc"] or "Enable this setting and choose its related option."
	elseif controlType == "input" then
		return L["configCenterInputFallbackDesc"] or "Enter the value used by this setting."
	elseif controlType == "colorpicker" or controlType == "colorpalette" then
		return L["configCenterColorFallbackDesc"] or "Choose a color for this setting."
	elseif controlType == "button" then
		return L["configCenterButtonFallbackDesc"] or "Run this action."
	elseif controlType == "reorderlist" then
		return control.description or ""
	end
	return ""
end

local function callFormatter(formatter, value, control)
	if type(formatter) ~= "function" then
		return nil
	end
	local ok, text = pcall(formatter, value, control)
	if ok and text ~= nil then
		return tostring(text)
	end
	ok, text = pcall(formatter, value)
	if ok and text ~= nil then
		return tostring(text)
	end
	return nil
end

function lib.FormatControlValue(control, value)
	local text = callFormatter(control.valueFormatter or control.formatter, value, control)
	if not text then
		if type(value) == "number" then
			text = string.format("%.2f", value):gsub("(%..-)0+$", "%1"):gsub("%.$", "")
		elseif type(value) == "boolean" then
			local L = getLibLocale()
			text = value and (L["configCenterEnabled"] or "Enabled") or (L["configCenterDisabled"] or "Disabled")
		elseif value ~= nil then
			text = tostring(value)
		else
			text = ""
		end
	end
	if control.suffix and text ~= "" then
		text = text .. tostring(control.suffix)
	end
	return text
end

local function getOptionLabel(option, key)
	if type(option) == "table" then
		return option.text or option.label or option.name or option.title or option[2] or option.value or option.key or key
	end
	return option
end

local function getOptionValue(option, key, arrayEntry)
	if type(option) == "table" then
		local value = option.value
		if value == nil then value = option.key end
		if value == nil then value = option[1] end
		if value ~= nil then return value end
	end
	if arrayEntry and type(option) == "string" then
		return option
	end
	return key
end

local function snapshotArray(list)
	if type(list) ~= "table" then return nil end
	local snapshot = {}
	for index = 1, #list do
		snapshot[index] = list[index]
	end
	return snapshot
end

local function getControlOptions(control)
	local list = control.values or control.options or control.list
	local optionfunc = control.optionfunc or control.listFunc
	local optionOrder
	if type(optionfunc) == "function" then
		local ok, result, resultOrder = pcall(optionfunc)
		if ok and type(result) == "table" then
			list = result
			if type(resultOrder) == "table" then
				optionOrder = resultOrder
			end
		end
	end
	local options = {}
	local order = snapshotArray(type(optionOrder) == "table" and optionOrder
		or type(control.orderList) == "table" and control.orderList
		or type(control.order) == "table" and control.order)
	local seen
	if type(list) ~= "table" then
		return options
	end
	if not order and #list > 0 then
		for index, option in ipairs(list) do
			options[#options + 1] = {
				value = getOptionValue(option, index, false),
				label = tostring(getOptionLabel(option, index) or index),
			}
		end
		return options
	end
	if order then
		seen = {}
		for _, key in ipairs(order) do
			if key ~= "_order" and list[key] ~= nil then
				local option = list[key]
				options[#options + 1] = {
					value = getOptionValue(option, key, false),
					label = tostring(getOptionLabel(option, key) or key),
				}
				seen[key] = true
			end
		end
	end
	for key, option in pairs(list) do
		if key ~= "_order" and (not seen or not seen[key]) then
			options[#options + 1] = {
				value = getOptionValue(option, key, false),
				label = tostring(getOptionLabel(option, key) or key),
			}
		end
	end
	if not order then
		table.sort(options, function(a, b)
			return tostring(a.label) < tostring(b.label)
		end)
	end
	return options
end

local function getDropdownValueText(control, value)
	for _, option in ipairs(getControlOptions(control)) do
		if tostring(option.value) == tostring(value) then
			return option.label
		end
	end
	return lib.FormatControlValue(control, value)
end

function lib.GetCheckboxDropdownOptions(control)
	return getControlOptions({
		values = control.dropdownValues
			or control.dropdownOptions
			or control.dropdownList
			or control.values
			or control.options
			or control.list,
		optionfunc = control.dropdownOptionfunc
			or control.dropdownListFunc
			or control.optionfunc
			or control.listFunc,
		orderList = control.dropdownOrder or control.orderList,
		order = control.dropdownOrder or control.order,
	})
end

function lib.GetCheckboxDropdownValue(app, control)
	if control.dropdownSetting and control.dropdownSetting.GetValue then
		local ok, value = pcall(control.dropdownSetting.GetValue, control.dropdownSetting)
		if ok then
			return value
		end
	end
	if type(control.dropdownGet) == "function" then
		local ok, value = pcall(control.dropdownGet)
		if ok then
			return value
		end
		ok, value = pcall(control.dropdownGet, control)
		if ok then
			return value
		end
	end
	local db = app.opts and app.opts.db and app.opts.db()
	if type(db) == "table" and control.dropdownKey ~= nil then
		return db[control.dropdownKey]
	end
	return control.dropdownDefault
end

function lib.SetCheckboxDropdownValue(app, control, value)
	if control.dropdownSetting and control.dropdownSetting.SetValue then
		local ok = pcall(control.dropdownSetting.SetValue, control.dropdownSetting, value)
		if ok then
			return true
		end
	end
	if type(control.dropdownSet) == "function" then
		local ok = pcall(control.dropdownSet, value)
		if ok then
			return true
		end
		ok = pcall(control.dropdownSet, nil, value)
		if ok then
			return true
		end
	end
	local db = app.opts and app.opts.db and app.opts.db()
	if type(db) == "table" and control.dropdownKey ~= nil then
		db[control.dropdownKey] = value
		return true
	end
	return false
end

function lib.GetCheckboxDropdownText(app, control)
	local dropdownControl = {
		values = control.dropdownValues
			or control.dropdownOptions
			or control.dropdownList
			or control.values
			or control.options
			or control.list,
		optionfunc = control.dropdownOptionfunc
			or control.dropdownListFunc
			or control.optionfunc
			or control.listFunc,
		orderList = control.dropdownOrder or control.orderList,
		order = control.dropdownOrder or control.order,
		formatter = control.dropdownFormatter or control.formatter,
		valueFormatter = control.dropdownValueFormatter or control.valueFormatter,
		suffix = control.dropdownSuffix,
	}
	return getDropdownValueText(dropdownControl, lib.GetCheckboxDropdownValue(app, control))
end

function lib.CopySelectionMap(selection)
	local copy = {}
	if type(selection) ~= "table" then
		return copy
	end
	if #selection > 0 then
		for index = 1, #selection do
			local value = selection[index]
			if value ~= nil and type(value) ~= "boolean" then
				copy[value] = true
			end
		end
	end
	for key, value in pairs(selection) do
		if value and (type(key) == "string" or type(key) == "number") then
			copy[key] = true
		end
	end
	return copy
end

function lib.IsMultiOptionSelected(selection, value)
	if type(selection) ~= "table" then
		return false
	end
	return selection[value] == true or selection[tostring(value)] == true
end

function lib.SetMultiOptionSelected(selection, value, selected)
	if selected then
		selection[value] = true
	else
		selection[value] = nil
		selection[tostring(value)] = nil
	end
end

function lib.GetPerOptionSelection(control)
	local selection = {}
	if type(control.isSelectedFunc) ~= "function" then
		return selection
	end
	for _, option in ipairs(getControlOptions(control)) do
		local ok, selected = pcall(control.isSelectedFunc, option.value)
		if ok and selected == true then
			selection[option.value] = true
		end
	end
	return selection
end

function lib.GetMultiSelection(app, control)
	if control.selectionSource == "perOption" then
		return lib.GetPerOptionSelection(control)
	end
	local value = app:GetControlValue(control)
	if type(value) == "table" then
		return lib.CopySelectionMap(value)
	end
	if type(control.isSelectedFunc) == "function" then
		return lib.GetPerOptionSelection(control)
	end
	return {}
end

function lib.GetMultiSummary(app, control)
	local selection = lib.GetMultiSelection(app, control)
	if type(control.summary) == "function" then
		local ok, text = pcall(control.summary, selection, control)
		if ok and text ~= nil and text ~= "" then
			return tostring(text)
		end
		ok, text = pcall(control.summary, selection)
		if ok and text ~= nil and text ~= "" then
			return tostring(text)
		end
	end

	local labels = {}
	for _, option in ipairs(getControlOptions(control)) do
		if lib.IsMultiOptionSelected(selection, option.value) then
			labels[#labels + 1] = option.label
			if #labels >= 2 then
				break
			end
		end
	end
	local selectedCount = 0
	for _, option in ipairs(getControlOptions(control)) do
		if lib.IsMultiOptionSelected(selection, option.value) then
			selectedCount = selectedCount + 1
		end
	end
	if selectedCount == 0 then
		local L = getLibLocale()
		return control.customDefaultText or L["configCenterNone"] or "None"
	end
	if selectedCount > #labels then
		return table.concat(labels, ", ") .. " +" .. tostring(selectedCount - #labels)
	end
	return table.concat(labels, ", ")
end

function lib.GetColorOverridesRowHeight(control, app)
	local count = 0
	if type(control.entries) == "table" then
		count = #control.entries
	elseif type(control.entries) == "function" then
		local ok, entries = pcall(control.entries, app, control)
		count = ok and type(entries) == "table" and #entries or 2
	end
	if count <= 0 then
		return COMPLEX_ROW_HEIGHT
	end
	return math.max(COMPLEX_ROW_HEIGHT, 78 + (math.ceil(count / 2) * 36))
end

lib.ReorderList = lib.ReorderList or {}

function lib.GetReorderListRowHeight(control)
	local explicitHeight = tonumber(control and control.rowHeight)
	if explicitHeight then return explicitHeight end
	local entries = lib.ReorderList.GetEntries and lib.ReorderList.GetEntries(control) or {}
	return math.max(220, 104 + (#entries * 32))
end

function lib.NormalizeTextValue(text, fallback)
	if text == nil then
		return fallback or ""
	end
	local textType = type(text)
	if textType == "string" or textType == "number" or textType == "boolean" then
		return tostring(text)
	end
	return fallback or ""
end

local function makeFlatButton(parent, text, width, height, iconSource, iconIsAtlas)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 120, height or 26)
	button._eqolOwner = parent
	button._eqolNormalBg = lib.ThemeColors.buttonBg
	button._eqolNormalBorder = lib.ThemeColors.buttonBorder
	applyBackdrop(button, button._eqolNormalBg, button._eqolNormalBorder, "button")
	local leftInset = 10
	if iconSource then
		button.Icon = createIcon(button, iconSource, math.min((height or 26) - 8, 18), iconIsAtlas)
		button.Icon:SetPoint("LEFT", button, "LEFT", 8, 0)
		leftInset = 30
	end
	button.Text = button:CreateFontString(nil, "OVERLAY", FONT_TEXT)
	button.Text:SetPoint("LEFT", button, "LEFT", leftInset, 0)
	button.Text:SetPoint("RIGHT", button, "RIGHT", -10, 0)
	button.Text:SetJustifyH("CENTER")
	button.Text:SetJustifyV("MIDDLE")
	button.Text:SetText(lib.NormalizeTextValue(text))
	setTextColor(button.Text, TEXT.main)
	button._eqolApplyVisual = lib.ApplyFlatButtonVisual
	button._eqolOnEnter = function(self)
		if lib.IsWidgetDisabled(self) then
			lib.ApplyFlatButtonVisual(self)
			return
		end
		setFrameBackdrop(self, lib.ThemeColors.buttonHoverBg, lib.ThemeColors.buttonHoverBorder)
	end
	button._eqolOnLeave = function(self)
		lib.ApplyFlatButtonVisual(self)
	end
	button:SetScript("OnEnter", button._eqolOnEnter)
	button:SetScript("OnLeave", button._eqolOnLeave)
	return button
end

local function refreshControlRow(app, control, row)
	local enabled = app:IsControlEnabled(control)
	row._eqolDisabled = not enabled
	row:SetAlpha(enabled and 1 or 0.54)
	if enabled then
		setFrameBackdrop(row, ROW_BG, ROW_BORDER)
		if row.SetBorderColor then row:SetBorderColor(ROW_BORDER) end
	else
		setFrameBackdrop(row, DISABLED_ROW_BG, DISABLED_ROW_BORDER)
		if row.SetBorderColor then row:SetBorderColor(DISABLED_ROW_BORDER) end
	end
	if row.check then
		row.check._eqolDisabled = not enabled
		if row.check.SetEnabled then
			row.check:SetEnabled(enabled)
		elseif enabled and row.check.Enable then
			row.check:Enable()
		elseif row.check.Disable then
			row.check:Disable()
		end
		if row.check.SetChecked then
			row.check:SetChecked(app:GetControlValue(control) == true)
		end
		if row.check.EnableMouse then
			row.check:EnableMouse(true)
		end
		if row.check._eqolOnLeave then
			row.check._eqolOnLeave(row.check)
		elseif not enabled then
			setFrameBackdrop(row.check, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER)
		end
	end
	if row.slider then
		local value = tonumber(app:GetControlValue(control)) or tonumber(control.default) or tonumber(control.min) or 0
		if row.slider.SetEnabled then
			row.slider:SetEnabled(enabled)
		elseif enabled and row.slider.Enable then
			row.slider:Enable()
		elseif row.slider.Disable then
			row.slider:Disable()
		end
		row.slider.updating = true
		row.slider:SetValue(value)
		if row.slider.SyncVisual then
			row.slider:SyncVisual(value)
		end
		row.slider.updating = false
	end
	if row.editBox then
		local editEnabled = enabled and not control.readOnly
		if row.editBox.SetEnabled then
			row.editBox:SetEnabled(editEnabled)
		elseif editEnabled and row.editBox.Enable then
			row.editBox:Enable()
		elseif row.editBox.Disable then
			row.editBox:Disable()
		end
		row.editBox:SetText(lib.FormatControlValue(control, app:GetControlValue(control)))
	end
	if row.value then
		if row.refreshValue then
			row.refreshValue()
		elseif getControlType(control) == "multidropdown" then
			row.value.Text:SetText(lib.GetMultiSummary(app, control))
		elseif getControlType(control) == "checkboxdropdown" then
			row.value.Text:SetText(lib.GetCheckboxDropdownText(app, control))
		elseif getControlType(control) == "dropdown" or getControlType(control) == "sounddropdown" then
			local value = app:GetControlValue(control)
			row.value.Text:SetText(getDropdownValueText(control, value))
		else
			local value = app:GetControlValue(control)
			row.value.Text:SetText(lib.FormatControlValue(control, value))
		end
		setTextColor(row.value.Text, enabled and TEXT.main or TEXT.disabled)
	end
	for _, buttonKey in ipairs({
		"configureButton",
		"dropdownButton",
		"multiDropdownButton",
		"colorButton",
		"swatch",
		"actionButton",
		"sliderDecreaseButton",
		"sliderIncreaseButton",
	}) do
		local button = row[buttonKey]
		if button then
			button._eqolDisabled = not enabled
			if button.SetEnabled then
				button:SetEnabled(enabled)
			elseif enabled and button.Enable then
				button:Enable()
			elseif button.Disable then
				button:Disable()
			end
			if button.EnableMouse then
				button:EnableMouse(enabled)
			end
			if button._eqolApplyVisual then
				button._eqolApplyVisual(button)
			elseif enabled then
				setFrameBackdrop(
					button,
					button.selected and SELECTED_BG or lib.ThemeColors.buttonBg,
					button.selected and CARD_BORDER_HOVER or lib.ThemeColors.buttonBorder
				)
				if button.Text then setTextColor(button.Text, TEXT.main) end
			else
				setFrameBackdrop(button, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER)
				if button.Text then setTextColor(button.Text, TEXT.disabled) end
			end
		end
	end
	if row.swatch and type(control.getColor) == "function" then
		local key = control.key or control.id
		local ok, r, g, b, a = pcall(control.getColor, key)
		if ok then
			row.swatch.Texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
			if row.hexText then
				row.hexText.Text:SetText(
					string.format(
						"#%02X%02X%02X",
						math.floor(((r or 1) * 255) + 0.5),
						math.floor(((g or 1) * 255) + 0.5),
						math.floor(((b or 1) * 255) + 0.5)
					)
				)
			end
		end
	end
	if row.refreshControls then
		row.refreshControls()
	end
end

function lib.RefreshVisibleRows(state)
	if not state then
		return
	end
	if type(state.controlRows) == "table" then
		for _, entry in ipairs(state.controlRows) do
			if entry.row and entry.control then
				refreshControlRow(state.app, entry.control, entry.row)
			end
		end
	end
	if type(state.groupCountHeaders) == "table" then
		for _, entry in ipairs(state.groupCountHeaders) do
			if entry.header and entry.group and entry.chip then
				local count = lib.GetGroupCustomizedCount(state.app, entry.group)
				local shown = count > 0
				entry.chip:SetShown(shown)
				if shown then
					local width = math.max(30, (#tostring(count) * 9) + 18)
					entry.chip:SetSize(width, 20)
					if entry.chip.Text then
						entry.chip.Text:SetText(tostring(count))
					end
				end
				if entry.header.Text then
					entry.header.Text:ClearAllPoints()
					entry.header.Text:SetPoint("LEFT", entry.header, "LEFT", 14, 0)
					entry.header.Text:SetPoint("RIGHT", entry.header, "RIGHT", shown and -78 or -34, 0)
				end
			end
		end
	end
	lib.RefreshTopbar(state.frame, state)
end

local updateScrollFrameVisibility

local function setScrollHeight(state)
	local height = math.max(1, math.abs(state.y) + 24)
	state.content:SetHeight(height)
	updateScrollFrameVisibility(state.frame.Scroll)
end

local function getScrollBar(scrollFrame)
	if not scrollFrame then return nil end
	return scrollFrame.ScrollBar or _G[scrollFrame:GetName() and (scrollFrame:GetName() .. "ScrollBar") or ""]
end

function lib.SetContentScrollTop(state)
	local scrollFrame = state and state.frame and state.frame.Scroll
	if not scrollFrame then
		return
	end
	scrollFrame:SetVerticalScroll(0)
	local scrollBar = getScrollBar(scrollFrame)
	if scrollBar and scrollBar.SetValue then
		scrollBar:SetValue(0)
	end
end

function lib.SetContentScroll(state, value)
	local scrollFrame = state and state.frame and state.frame.Scroll
	if not scrollFrame then
		return
	end
	local range = scrollFrame.GetVerticalScrollRange and scrollFrame:GetVerticalScrollRange() or 0
	local target = math.max(0, math.min(tonumber(value) or 0, range or 0))
	scrollFrame:SetVerticalScroll(target)
	local scrollBar = getScrollBar(scrollFrame)
	if scrollBar and scrollBar.SetValue then
		scrollBar:SetValue(target)
	end
end

function lib.GetContentScroll(state)
	local scrollFrame = state and state.frame and state.frame.Scroll
	if not scrollFrame or not scrollFrame.GetVerticalScroll then
		return 0
	end
	return scrollFrame:GetVerticalScroll() or 0
end

function lib.QueueContentScroll(state, value)
	lib.SetContentScroll(state, value)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			lib.SetContentScroll(state, value)
		end)
	end
end

local function updateContentMetrics(state)
	local shellWidth = state.frame.ContentShell and state.frame.ContentShell:GetWidth() or 0
	local fallbackWidth = CONTENT_WIDTH
	local usableShellWidth = math.max(1, math.floor(shellWidth > 0 and shellWidth or fallbackWidth))
	local query = state.frame.SearchBox and state.frame.SearchBox:GetText() or ""
	local useSearchView = query ~= ""
	local useSidePanel = state.view == "page" and not useSearchView
	local useContentGutter = useSearchView or state.view == "category" or state.view == "dashboard"
	local useDetachedScrollbar = useSidePanel or useContentGutter
	local pageRightWidth = 0
	local leftOuterWidth = usableShellWidth - (PAGE_LAYOUT.contentPad * 2)
	local leftScrollWidth = leftOuterWidth
	if useSidePanel then
		local availableWidth = usableShellWidth - (PAGE_LAYOUT.contentPad * 2)
		local idealRightWidth = availableWidth - PAGE_LEFT_WIDTH_IDEAL - PAGE_GAP - PAGE_LAYOUT.scrollbarGutter
		pageRightWidth = math.min(PAGE_RIGHT_WIDTH, math.max(PAGE_RIGHT_WIDTH_MIN, idealRightWidth))
		if availableWidth - pageRightWidth - PAGE_GAP - PAGE_LAYOUT.scrollbarGutter < PAGE_LEFT_WIDTH_MIN then
			pageRightWidth = availableWidth - PAGE_LEFT_WIDTH_MIN - PAGE_GAP - PAGE_LAYOUT.scrollbarGutter
		end
		pageRightWidth = math.max(PAGE_RIGHT_WIDTH_MIN, math.floor(pageRightWidth))
		leftOuterWidth = math.max(PAGE_LEFT_WIDTH_MIN, availableWidth - pageRightWidth - PAGE_GAP)
		leftScrollWidth = math.max(PAGE_LEFT_WIDTH_MIN, leftOuterWidth - PAGE_LAYOUT.scrollbarGutter)
	end
	state.sidePanelMode = useSidePanel and "right" or nil
	state.pageRightWidth = pageRightWidth
	state.pageGap = useSidePanel and PAGE_GAP or 0
	state.pageLeftOuterWidth = leftOuterWidth
	local pageViewportWidth = leftScrollWidth
	state.pageSectionWidth = math.max(1, pageViewportWidth - (PAGE_LAYOUT.columnInset * 2) - 18)
	if state.frame.Scroll and state.frame.ContentShell then
		state.frame.Scroll:ClearAllPoints()
		local scrollTopOffset = PAGE_LAYOUT.contentPad
		local scrollBottomOffset = PAGE_LAYOUT.contentPad
		if state.view == "page" and useSidePanel then
			scrollTopOffset = PAGE_LAYOUT.contentPad
				+ PAGE_LAYOUT.detailNavHeight
				+ PAGE_LAYOUT.detailNavGap
				+ PAGE_LAYOUT.scrollInset
			scrollBottomOffset = PAGE_LAYOUT.scrollBottomPad
		end
		state.frame.Scroll:SetPoint(
			"TOPLEFT",
			state.frame.ContentShell,
			"TOPLEFT",
			PAGE_LAYOUT.contentPad,
			-scrollTopOffset
		)
		if state.view == "page" and useSidePanel then
			state.frame.Scroll:SetPoint(
				"BOTTOMRIGHT",
				state.frame.ContentShell,
				"BOTTOMRIGHT",
				-(PAGE_LAYOUT.contentPad + pageRightWidth + PAGE_GAP + PAGE_LAYOUT.scrollbarGutter),
				scrollBottomOffset
			)
		elseif useContentGutter then
			state.frame.Scroll:SetPoint(
				"BOTTOMRIGHT",
				state.frame.ContentShell,
				"BOTTOMRIGHT",
				-(PAGE_LAYOUT.contentPad + PAGE_LAYOUT.scrollbarGutter),
				scrollBottomOffset
			)
		else
			state.frame.Scroll:SetPoint(
				"BOTTOMRIGHT",
				state.frame.ContentShell,
				"BOTTOMRIGHT",
				-PAGE_LAYOUT.contentPad,
				scrollBottomOffset
			)
		end
		local scrollBar = getScrollBar(state.frame.Scroll)
		if scrollBar and scrollBar.ClearAllPoints and scrollBar.SetPoint then
			scrollBar:ClearAllPoints()
			if useDetachedScrollbar then
				scrollBar:SetPoint("TOPLEFT", state.frame.Scroll, "TOPRIGHT", PAGE_LAYOUT.scrollbarOffset, 0)
				scrollBar:SetPoint("BOTTOMLEFT", state.frame.Scroll, "BOTTOMRIGHT", PAGE_LAYOUT.scrollbarOffset, 0)
			else
				scrollBar:SetPoint("TOPRIGHT", state.frame.Scroll, "TOPRIGHT", -2, -16)
				scrollBar:SetPoint("BOTTOMRIGHT", state.frame.Scroll, "BOTTOMRIGHT", -2, 16)
			end
			if scrollBar.SetWidth then scrollBar:SetWidth(12) end
		end
	end
	local width
	if state.view == "page" and useSidePanel then
		width = pageViewportWidth
	elseif useContentGutter then
		width = usableShellWidth - (PAGE_LAYOUT.contentPad * 2) - PAGE_LAYOUT.scrollbarGutter
	else
		width = usableShellWidth - (PAGE_LAYOUT.contentPad * 2)
	end
	local minimumWidth = state.view == "page" and PAGE_LEFT_WIDTH_MIN or 640
	width = snap(state.frame.ContentShell or state.frame, math.max(minimumWidth, math.floor(width)))
	state.contentWidth = width
	state.pageLeftWidth = width
	state.content:SetWidth(width)
end

local function skinScrollFrame(scrollFrame)
	if not scrollFrame then return end
	local scrollBar = getScrollBar(scrollFrame)
	local up = scrollFrame.ScrollBar and scrollFrame.ScrollBar.ScrollUpButton or scrollFrame.ScrollUpButton
	local down = scrollFrame.ScrollBar and scrollFrame.ScrollBar.ScrollDownButton or scrollFrame.ScrollDownButton
	local buttons = {}
	if scrollBar then
		up = up or scrollBar.ScrollUpButton or scrollBar.Back
		down = down or scrollBar.ScrollDownButton or scrollBar.Forward
		if scrollBar.SetAlpha then scrollBar:SetAlpha(0.72) end
		local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
		if thumb and thumb.SetAlpha then thumb:SetAlpha(0.90) end
		for _, key in ipairs({ "Track", "Background", "BG", "Middle", "Top", "Bottom" }) do
			local region = scrollBar[key]
			if region and region.SetAlpha then region:SetAlpha(0.24) end
		end
	end
	buttons[1] = up
	buttons[2] = down
	if scrollBar then
		buttons[3] = scrollBar.Back
		buttons[4] = scrollBar.Forward
		buttons[5] = scrollBar.ScrollUpButton
		buttons[6] = scrollBar.ScrollDownButton
	end
	for _, button in ipairs(buttons) do
		if button and button.Hide then
			button:Hide()
			if button.SetAlpha then button:SetAlpha(0) end
			if button.EnableMouse then button:EnableMouse(false) end
			if button.HookScript then
				button:HookScript("OnShow", function(self) self:Hide() end)
			end
		end
	end
	if scrollFrame.EnableMouseWheel then
		scrollFrame:EnableMouseWheel(true)
	end
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local range = self.GetVerticalScrollRange and self:GetVerticalScrollRange() or 0
		if not range or range <= 0 then
			return
		end
		local step = self._LibSettingsDesignerScrollStep or 64
		local current = self.GetVerticalScroll and self:GetVerticalScroll() or 0
		local target = math.max(0, math.min(range, current - ((delta or 0) * step)))
		self:SetVerticalScroll(target)
		local bar = getScrollBar(self)
		if bar and bar.SetValue then
			bar:SetValue(target)
		end
	end)
end

updateScrollFrameVisibility = function(scrollFrame)
	if not scrollFrame then return end
	local scrollBar = getScrollBar(scrollFrame)
	if not scrollBar or not scrollBar.SetShown then return end
	local range = scrollFrame.GetVerticalScrollRange and scrollFrame:GetVerticalScrollRange() or 0
	local shown = range and range > 1
	scrollBar:SetShown(shown)
	if scrollFrame._LibSettingsDesignerScrollRail and scrollFrame._LibSettingsDesignerScrollRail.SetShown then
		scrollFrame._LibSettingsDesignerScrollRail:SetShown(shown)
	end
end

function lib.ScrollToControlRow(state, controlID)
	if not controlID or not state.frame or not state.frame.Scroll then
		return
	end
	for _, entry in ipairs(state.controlRows or {}) do
		local control = entry.control
		local row = entry.row
		if control and row and (control.id == controlID or control.key == controlID) then
			local y = row._LibSettingsDesignerContentY
			if y then
				local scrollFrame = state.frame.Scroll
				local range = scrollFrame.GetVerticalScrollRange and scrollFrame:GetVerticalScrollRange() or 0
				local target = math.max(0, math.min(range or 0, -y - 16))
				scrollFrame:SetVerticalScroll(target)
				local scrollBar = getScrollBar(scrollFrame)
				if scrollBar and scrollBar.SetValue then
					scrollBar:SetValue(target)
				end
			end
			return
		end
	end
end

function lib.FocusPendingControl(state)
	local controlID = state.pendingFocusControlID
	if not controlID then
		return
	end
	state.pendingFocusControlID = nil
	if _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0, function()
			lib.ScrollToControlRow(state, controlID)
		end)
	else
		lib.ScrollToControlRow(state, controlID)
	end
end

local function clearContent(state)
	lib.ReleaseAllCustomHandles(state)
	clearFrameList(state.contentFrames)
	state.controlRows = {}
	state.y = -2
end

local function clearFixedContent(state)
	if state.frame and state.frame.Scroll then
		state.frame.Scroll._LibSettingsDesignerScrollRail = nil
	end
	clearFrameList(state.fixedFrames)
end

local function clearSidebar(state)
	clearFrameList(state.sidebarFrames)
	state.sidebarY = -6
end

local function addSectionTitle(state, title, subtitle)
	local height = subtitle and 58 or 34
	local frame = createContentFrame(state, height)
	local titleText = createText(frame, FONT_TITLE, title or "", TEXT.gold)
	titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	titleText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
	titleText:SetHeight(24)
	if subtitle and subtitle ~= "" then
		local subText = createText(frame, FONT_MUTED, subtitle, TEXT.muted)
		subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -6)
		subText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
		subText:SetHeight(24)
	end
	state.y = state.y - 8
	return frame
end

local function addInfoCard(state, title, lines, height)
	local card = createContentFrame(state, height or 96)
	applyBackdrop(card, CARD_BG, CARD_BORDER, "card")

	local titleText = createText(card, FONT_HEADER, title or "", TEXT.gold)
	titleText:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
	titleText:SetPoint("RIGHT", card, "RIGHT", -14, 0)
	titleText:SetHeight(20)

	local body = createText(card, FONT_MUTED, table.concat(lines or {}, "\n"), TEXT.muted)
	body:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
	body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 12)
	state.y = state.y - 12
	return card
end

local function createGridRow(state, height)
	local row = trackFrame(state.contentFrames, CreateFrame("Frame", nil, state.content, "BackdropTemplate"))
	row.contentWidth = math.max(1, (state.contentWidth or CONTENT_WIDTH) - (SCROLL_CONTENT_INSET * 2))
	row._LibSettingsDesignerContentY = state.y
	snapPoint(row, "TOPLEFT", state.content, "TOPLEFT", SCROLL_CONTENT_INSET, state.y)
	snapPoint(row, "TOPRIGHT", state.content, "TOPRIGHT", -SCROLL_CONTENT_INSET, state.y)
	row:SetHeight(snap(row, height))
	state.y = snap(state.content, state.y - height - GRID_GAP)
	return row
end

local function createGridCard(state, row, index, columns, height)
	local rowWidth = row.contentWidth or state.contentWidth or CONTENT_WIDTH
	local width = math.floor((rowWidth - ((columns - 1) * GRID_GAP)) / columns)
	local card = CreateFrame("Button", nil, row, "BackdropTemplate")
	snapSize(card, width, height)
	snapPoint(card, "TOPLEFT", row, "TOPLEFT", (index - 1) * (width + GRID_GAP), 0)
	applyBackdrop(card, CARD_BG, CARD_BORDER, "card")
	card:EnableMouse(true)
	return card, width
end

local function createPageLeftFrame(state, height)
	local frame = trackFrame(state.contentFrames, CreateFrame("Frame", nil, state.content, "BackdropTemplate"))
	frame._LibSettingsDesignerContentY = state.y
	snapPoint(frame, "TOPLEFT", state.content, "TOPLEFT", PAGE_LAYOUT.columnInset, state.y)
	snapSize(frame, state.pageSectionWidth or state.pageLeftWidth or 420, height)
	state.y = snap(state.content, state.y - height)
	return frame
end

local function addStatusChip(parent, text, color, width)
	local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	chip:SetSize(width or 86, 20)
	applyBackdrop(chip, { 0.02, 0.05, 0.025, 0.86 }, { color[1], color[2], color[3], 0.45 }, "card")
	chip.Text = chip:CreateFontString(nil, "OVERLAY", FONT_MUTED)
	chip.Text:SetAllPoints(chip)
	chip.Text:SetJustifyH("CENTER")
	chip.Text:SetText(text or "")
	setTextColor(chip.Text, color)
	return chip
end

function lib.CreateNewBadge(parent, app)
	local ok, badge = pcall(CreateFrame, "Frame", nil, parent, "NewFeatureLabelNoAnimateTemplate")
	if not ok or not badge then
		ok, badge = pcall(CreateFrame, "Frame", nil, parent, "NewFeatureLabelTemplate")
	end
	if ok and badge then
		badge:SetScale(0.78)
		badge:SetShown(true)
		return badge
	end
	local L = getLocale(app)
	local chip = addStatusChip(parent, L["configCenterNew"] or "New", TEXT.gold, 54)
	return chip
end

function lib.SetSearchQuery(state, query)
	if not (state and state.frame and state.frame.SearchBox) then
		return
	end
	state.frame.SearchBox:SetText(query or "")
	state.frame.SearchBox:ClearFocus()
end

local function getDashboardIconSize()
	return 48, 48
end

local function createDashboardIcon(parent, iconSource)
	local icon = parent:CreateTexture(nil, "OVERLAY")
	local width, height = getDashboardIconSize()
	icon:SetSize(width, height)
	icon:SetTexture(iconSource or ASSET.fallback)
	return icon
end

local function applyDashboardCardBackground(card, bgColor)
	applyBackdrop(card, bgColor, DASHBOARD_CARD_BORDER, "dashboardCard")
end

local function setDashboardCardBorder(card, borderColor)
	createPixelBorder(card, borderColor)
end

local function styleRaisedTile(tile, interactive)
	applyDashboardCardBackground(tile, DASHBOARD_CARD_BG)
	setDashboardCardBorder(tile, DASHBOARD_CARD_BORDER)
	if interactive then
		tile:EnableMouse(true)
		tile:SetScript("OnEnter", function(self)
			applyDashboardCardBackground(self, DASHBOARD_CARD_BG_HOVER)
			setDashboardCardBorder(self, CARD_BORDER_HOVER)
		end)
		tile:SetScript("OnLeave", function(self)
			applyDashboardCardBackground(self, DASHBOARD_CARD_BG)
			setDashboardCardBorder(self, DASHBOARD_CARD_BORDER)
		end)
	end
end

local function addDashboardCard(row, index, title, description, iconSource, onClick)
	local card = createGridCard({ contentWidth = row.contentWidth or CONTENT_WIDTH }, row, index, 2, 108)
	styleRaisedTile(card, onClick ~= nil)
	if onClick then
		card:SetScript("OnMouseUp", onClick)
	end
	local icon = createDashboardIcon(card, iconSource)
	icon:SetPoint("LEFT", card, "LEFT", 24, 0)

	local titleText = createText(card, FONT_TITLE, title or "", TEXT.main)
	titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 18, -6)
	titleText:SetPoint("RIGHT", card, "RIGHT", -18, 0)
	titleText:SetHeight(24)

	local desc = createText(card, FONT_TEXT, description or "", TEXT.muted)
	desc:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -7)
	desc:SetPoint("RIGHT", card, "RIGHT", -18, 0)
	desc:SetHeight(42)
	desc.Text:SetWordWrap(true)
	return card
end

function lib.GetDashboardOptions(app)
	local dashboard = app and app.opts and app.opts.dashboard
	local defined = dashboard ~= nil
	if type(dashboard) == "function" then
		local ok, result = pcall(dashboard, app)
		if ok then
			dashboard = result
		else
			dashboard = nil
		end
	end
	if type(dashboard) ~= "table" then
		dashboard = {}
	end
	dashboard._defined = defined
	return dashboard
end

local function addDashboardHero(state, title, subtitle, iconSource)
	local hero = createContentFrame(state, 138)

	local titleText = createText(hero, FONT_HERO, title or "", TEXT.main)
	titleText:SetPoint("TOPLEFT", hero, "TOPLEFT", 4, -10)
	titleText:SetPoint("RIGHT", hero, "RIGHT", -146, 0)
	titleText:SetHeight(42)

	local subText = createText(hero, FONT_TEXT, subtitle or "", TEXT.muted)
	subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -9)
	subText:SetPoint("RIGHT", hero, "RIGHT", -166, 0)
	subText:SetHeight(48)

	local icon = createDashboardIcon(hero, iconSource or getAppIconTexture(state.app, "dashboard"))
	icon:SetSize(92, 92)
	icon:SetPoint("RIGHT", hero, "RIGHT", -36, -4)
	icon:SetAlpha(0.90)
	state.y = state.y - 8
	return hero
end

local function addDashboardStatusTile(parent, index, iconSource, iconAtlas, title, value, badge, action)
	local width = math.floor((parent.tileWidth or 160))
	local tile = CreateFrame(action and "Button" or "Frame", nil, parent, "BackdropTemplate")
	tile:SetSize(width, STATUS_TILE_HEIGHT)
	tile:SetPoint("TOPLEFT", parent, "TOPLEFT", 14 + ((index - 1) * (width + GRID_GAP)), -44)
	styleRaisedTile(tile, action ~= nil)
	if action then
		tile:SetScript("OnMouseUp", action)
	end

	local icon = tile:CreateTexture(nil, "OVERLAY")
	icon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	icon:SetPoint("LEFT", tile, "LEFT", STATUS_TILE_PAD_X, 0)
	if iconAtlas and icon.SetAtlas then
		local hasAtlas = not C_Texture or not C_Texture.GetAtlasInfo or C_Texture.GetAtlasInfo(iconAtlas)
		local ok = hasAtlas and pcall(icon.SetAtlas, icon, iconAtlas, false)
		if not ok then
			icon:SetTexture(iconSource or ASSET.fallback)
		end
	else
		icon:SetTexture(iconSource or ASSET.fallback)
	end

	local titleText = createText(tile, FONT_MUTED, title or "", TEXT.gold)
	titleText:SetPoint("TOPLEFT", tile, "TOPLEFT", STATUS_TEXT_LEFT, -13)
	titleText:SetPoint("RIGHT", tile, "RIGHT", badge and -68 or -12, 0)
	titleText:SetHeight(18)
	titleText.Text:SetWordWrap(false)
	titleText.Text:SetJustifyV("MIDDLE")

	if badge and badge ~= "" then
		local badgeFrame = addStatusChip(tile, badge, TEXT.gold, 54)
		badgeFrame:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -10, -10)
	end

	local valueText = createText(tile, FONT_TITLE, tostring(value or ""), TEXT.main)
	valueText:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", STATUS_TEXT_LEFT, 12)
	valueText:SetPoint("RIGHT", tile, "RIGHT", -12, 0)
	valueText:SetHeight(24)
	valueText.Text:SetJustifyV("MIDDLE")
	return tile
end

local function addDashboardStatusPanel(state, stats, statusConfig)
	local app = state.app
	statusConfig = type(statusConfig) == "table" and statusConfig or {}
	local tiles = statusConfig.tiles
	if type(tiles) == "function" then
		local ok, result = pcall(tiles, app, stats)
		tiles = ok and result or nil
	end
	if type(tiles) ~= "table" or #tiles == 0 then
		return nil
	end

	local panel = createContentFrame(state, 130)
	applyBackdrop(panel, DETAIL_SECTION_BG, DASHBOARD_CARD_BORDER, "dashboardCard")
	local L = getLocale(app)
	local title = createText(panel, FONT_TITLE, statusConfig.title or (L["configCenterStatus"] or "Status"), TEXT.gold)
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -13)
	title:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
	title:SetHeight(24)

	local innerWidth = (state.contentWidth or CONTENT_WIDTH) - 28
	panel.tileWidth = math.floor((innerWidth - ((#tiles - 1) * GRID_GAP)) / math.max(#tiles, 1))
	for index, tile in ipairs(tiles) do
		local action
		if tile.searchQuery then
			action = function() lib.SetSearchQuery(state, tile.searchQuery) end
		elseif type(tile.onClick) == "function" then
			action = function() tile.onClick(state, app, stats) end
		end
		addDashboardStatusTile(panel, index, tile.icon, tile.atlas, tile.title, tile.value, tile.badge, action)
	end
	state.y = state.y - 12
	return panel
end

local function setDropdownMenuScrollMode(rootDescription, control, optionCount)
	if not (rootDescription and rootDescription.SetScrollMode) then
		return
	end
	local height = tonumber(control and control.menuHeight)
	if not height and (tonumber(optionCount) or 0) > 12 then
		height = 320
	end
	if height then
		rootDescription:SetScrollMode(height)
	end
end

function lib.PlaySoundDropdownPreview(control, optionOrValue, optionLabel)
	if not control or optionOrValue == nil then
		return
	end
	local option
	local value
	if type(optionOrValue) == "table" then
		option = optionOrValue
		value = option.value
	else
		value = optionOrValue
		option = {
			value = value,
			label = optionLabel,
		}
	end
	if value == nil or value == "" then
		return
	end
	if type(control.previewSoundFunc) == "function" then
		local ok = pcall(control.previewSoundFunc, value, option, control)
		if ok then
			return
		end
	end

	local sound
	if type(control.soundResolver) == "function" then
		local ok, resolved = pcall(control.soundResolver, value, option, control)
		if ok and resolved then
			sound = resolved
		else
			ok, resolved = pcall(control.soundResolver, value)
			if ok and resolved then
				sound = resolved
			end
		end
	end
	if not sound and _G.LibStub then
		local lsm = _G.LibStub("LibSharedMedia-3.0", true)
		if lsm then
			sound = lsm:Fetch("sound", value, true)
		end
	end
	sound = sound or value

	local channel
	if type(control.getPlaybackChannel) == "function" then
		local ok, result = pcall(control.getPlaybackChannel, control)
		if ok then
			channel = result
		end
	end
	channel = channel or control.playbackChannel

	local soundID = tonumber(sound)
	if soundID and _G.PlaySound then
		_G.PlaySound(soundID, channel or "Master")
	elseif type(sound) == "string" and sound ~= "" and _G.PlaySoundFile then
		if channel and channel ~= "" then
			_G.PlaySoundFile(sound, channel)
		else
			_G.PlaySoundFile(sound)
		end
	end
end

local function resetSoundPreviewButton(button)
	local preview = button and button.LibSettingsDesignerSoundPreview
	if not preview then return end
	preview.LibSettingsDesignerControl = nil
	preview.LibSettingsDesignerOption = nil
	preview.LibSettingsDesignerSoundValue = nil
	preview.LibSettingsDesignerSoundLabel = nil
	if preview.Icon then
		preview.Icon:SetVertexColor(0.78, 0.72, 0.62, 1)
	end
	if _G.GameTooltip and _G.GameTooltip.GetOwner and _G.GameTooltip:GetOwner() == preview then
		_G.GameTooltip:Hide()
	end
	preview:Hide()
end

local function ensureSoundPreviewButton(button)
	if not button then return nil end
	local preview = button.LibSettingsDesignerSoundPreview
	if preview then return preview end

	preview = CreateFrame("Button", nil, button)
	preview:SetSize(18, 18)
	preview:SetFrameLevel((button:GetFrameLevel() or 1) + 2)
	preview:SetMotionScriptsWhileDisabled(true)
	if preview.SetMouseClickEnabled then preview:SetMouseClickEnabled(true) end
	if preview.SetPropagateMouseClicks then preview:SetPropagateMouseClicks(false) end
	if preview.SetPropagateMouseMotion then preview:SetPropagateMouseMotion(false) end
	local icon = preview:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture("Interface\\Common\\VoiceChat-Speaker")
	icon:SetVertexColor(0.78, 0.72, 0.62, 1)
	preview.Icon = icon
	preview:SetScript("OnEnter", function(self)
		if self.Icon then self.Icon:SetVertexColor(1, 0.82, 0.35, 1) end
		if _G.GameTooltip then
			local L = getLibLocale()
			local soundText = L["configCenterSound"] or "Sound"
			_G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			_G.GameTooltip:SetText(self.LibSettingsDesignerSoundLabel or self.LibSettingsDesignerSoundValue or L["configCenterPreview"] or soundText or "Preview")
			local tooltip = self.LibSettingsDesignerControl and self.LibSettingsDesignerControl.previewTooltip
			if tooltip and tooltip ~= "" then
				_G.GameTooltip:AddLine(tooltip, 1, 1, 1, true)
			elseif soundText then
				_G.GameTooltip:AddLine(soundText, 1, 1, 1, true)
			end
			_G.GameTooltip:Show()
		end
	end)
	preview:SetScript("OnLeave", function(self)
		if self.Icon then self.Icon:SetVertexColor(0.78, 0.72, 0.62, 1) end
		if _G.GameTooltip then
			_G.GameTooltip:Hide()
		end
	end)
	preview:SetScript("OnClick", function(self, mouseButton)
		if mouseButton and mouseButton ~= "LeftButton" then return end
		if self.StopPropagation then self:StopPropagation() end
		lib.PlaySoundDropdownPreview(self.LibSettingsDesignerControl, self.LibSettingsDesignerSoundValue, self.LibSettingsDesignerSoundLabel)
	end)
	button.LibSettingsDesignerSoundPreview = preview
	if button.HookScript and not button.LibSettingsDesignerSoundPreviewOnHideHooked then
		button:HookScript("OnHide", resetSoundPreviewButton)
		button.LibSettingsDesignerSoundPreviewOnHideHooked = true
	end
	return preview
end

function lib.AttachSoundPreviewInitializer(description, control, option)
	if not (description and description.AddInitializer) then
		return
	end
	local soundValue = option and option.value
	local soundLabel = option and option.label
	description:AddInitializer(function(button)
		resetSoundPreviewButton(button)
		if soundValue == nil or soundValue == "" then return end
		local preview = ensureSoundPreviewButton(button)
		if not preview then return end
		preview:ClearAllPoints()
		preview:SetPoint("RIGHT", button, "RIGHT", -8, 0)
		preview:SetFrameLevel((button:GetFrameLevel() or 1) + 2)
		preview.LibSettingsDesignerControl = control
		preview.LibSettingsDesignerSoundValue = soundValue
		preview.LibSettingsDesignerSoundLabel = soundLabel
		preview.LibSettingsDesignerOption = nil
		if preview.Icon then preview.Icon:SetVertexColor(0.78, 0.72, 0.62, 1) end
		preview:Show()
	end)
	if description.AddResetter then
		description:AddResetter(resetSoundPreviewButton)
	end
end

function lib.AttachSoundPreviewCleanupInitializer(description)
	if not (description and description.AddInitializer) then
		return
	end
	description:AddInitializer(resetSoundPreviewButton)
	if description.AddResetter then
		description:AddResetter(resetSoundPreviewButton)
	end
end

local function addConfigureFallback(row, app, control, text, opts)
	opts = opts or {}
	if not (control and control.type == "keybind") then
		return nil
	end
	local L = getLocale(app)
	local button = makeFlatButton(
		row,
		text or L["configCenterConfigure"] or "Configure",
		opts.width or 138,
		26,
		getAppIconTexture(app, "advanced")
	)
	if opts.point then
		button:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		button:SetPoint("RIGHT", row, "RIGHT", -14, 0)
	end
	row.configureButton = button
	button._eqolNormalBg = { 0.100, 0.087, 0.064, 0.95 }
	button._eqolNormalBorder = { 0.50, 0.39, 0.20, 0.78 }
	setFrameBackdrop(button, button._eqolNormalBg, button._eqolNormalBorder)
	button:SetScript("OnClick", function()
		if not app:IsControlEnabled(control) then
			return
		end
		if app.opts and type(app.opts.openLegacySettings) == "function" then
			app.opts.openLegacySettings(control)
		end
	end)
	return button
end

local function commitInputValue(app, control, editBox, row)
	if not app:IsControlEnabled(control) then
		return
	end
	local value = editBox:GetText() or ""
	if control.numeric then
		value = tonumber(value)
		if value == nil then
			value = tonumber(control.default) or 0
		end
		if control.clampToRange then
			if control.min and value < control.min then value = control.min end
			if control.max and value > control.max then value = control.max end
		end
	end
	app:SetControlValue(control, value)
	lib.RefreshVisibleRows(row._state)
end

local function addSliderWidget(row, app, control, opts)
	opts = opts or {}
	local valueText = opts.valueText
	if not valueText then
		valueText = createText(row, FONT_TEXT, "", TEXT.gold, "RIGHT")
		valueText:SetPoint("RIGHT", row, "RIGHT", -14, 10)
		valueText:SetSize(62, 18)
	end
	row.value = valueText
	local sliderWidth = math.max(120, tonumber(opts.width) or 220)
	local trackHeight = 4
	local sliderHitHeight = 22
	local thumbWidth = 12
	local thumbHeight = 16
	local minValue = tonumber(control.min) or 0
	local maxValue = tonumber(control.max) or 1
	if maxValue < minValue then
		minValue, maxValue = maxValue, minValue
	end
	local step = tonumber(control.step) or 1
	local showStepButtons = opts.stepButtons ~= false and step and step > 0
	local stepButtonSize = 18
	local stepButtonGap = 6

	local function clamp(value)
		value = tonumber(value) or minValue
		if value < minValue then value = minValue end
		if value > maxValue then value = maxValue end
		return value
	end

	local function normalize(value)
		value = clamp(value)
		if step and step > 0 then
			value = minValue + (math.floor(((value - minValue) / step) + 0.5) * step)
			value = clamp(value)
		end
		return value
	end

	local container = CreateFrame("Frame", nil, row)
	container:SetSize(sliderWidth, sliderHitHeight)
	if opts.point then
		container:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		container:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, 10)
	end

	local function createStepButton(text)
		local button = CreateFrame("Button", nil, container, "BackdropTemplate")
		button:SetSize(stepButtonSize, stepButtonSize)
		applyBackdrop(button, { 0.045, 0.042, 0.036, 0.90 }, { 0.42, 0.34, 0.20, 0.42 }, "control")
		button.Text = button:CreateFontString(nil, "OVERLAY", FONT_TEXT)
		button.Text:SetAllPoints(button)
		button.Text:SetJustifyH("CENTER")
		button.Text:SetJustifyV("MIDDLE")
		button.Text:SetText(text)
		setTextColor(button.Text, TEXT.muted)
		button._eqolApplyVisual = function(self)
			if self._eqolDisabled then
				applyBackdrop(self, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER, "control")
				if self.Text then setTextColor(self.Text, TEXT.disabled) end
			else
				applyBackdrop(self, { 0.045, 0.042, 0.036, 0.90 }, { 0.42, 0.34, 0.20, 0.42 }, "control")
				if self.Text then setTextColor(self.Text, TEXT.muted) end
			end
		end
		button:SetScript("OnEnter", function(self)
			if self._eqolDisabled then
				return
			end
			applyBackdrop(self, { 0.105, 0.082, 0.045, 0.92 }, { TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.62 }, "control")
			if self.Text then setTextColor(self.Text, TEXT.gold) end
		end)
		button:SetScript("OnLeave", function(self)
			if self._eqolApplyVisual then
				self:_eqolApplyVisual()
			end
		end)
		return button
	end

	local decreaseButton
	local increaseButton
	if showStepButtons then
		decreaseButton = createStepButton("<")
		decreaseButton:SetPoint("LEFT", container, "LEFT", 0, 0)
		increaseButton = createStepButton(">")
		increaseButton:SetPoint("RIGHT", container, "RIGHT", 0, 0)
		row.sliderDecreaseButton = decreaseButton
		row.sliderIncreaseButton = increaseButton
	end

	local track = CreateFrame("Frame", nil, row)
	local trackWidth = showStepButtons and math.max(80, sliderWidth - ((stepButtonSize + stepButtonGap) * 2)) or sliderWidth
	track:SetSize(trackWidth, sliderHitHeight)
	if showStepButtons then
		track:SetPoint("LEFT", decreaseButton, "RIGHT", stepButtonGap, 0)
		track:SetPoint("RIGHT", increaseButton, "LEFT", -stepButtonGap, 0)
	else
		track:SetPoint("LEFT", container, "LEFT", 0, 0)
		track:SetPoint("RIGHT", container, "RIGHT", 0, 0)
	end

	local bar = track:CreateTexture(nil, "BACKGROUND")
	bar:SetPoint("LEFT", track, "LEFT", 0, 0)
	bar:SetPoint("RIGHT", track, "RIGHT", 0, 0)
	bar:SetHeight(trackHeight)
	bar:SetColorTexture(0.075, 0.070, 0.060, 0.95)
	local fill = track:CreateTexture(nil, "ARTWORK")
	fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
	fill:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.78)

	local slider = CreateFrame("Slider", nil, row)
	slider:SetOrientation("HORIZONTAL")
	slider:SetPoint("LEFT", track, "LEFT", 0, 0)
	slider:SetPoint("RIGHT", track, "RIGHT", 0, 0)
	slider:SetHeight(sliderHitHeight)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
	if slider.SetThumbTexture then
		slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
	end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if thumb then
		thumb:SetSize(thumbWidth, thumbHeight)
		if thumb.SetColorTexture then
			thumb:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 1)
		else
			thumb:SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 1)
		end
	end

	function slider.SyncVisual(_, value)
		value = normalize(value)
		local span = maxValue - minValue
		local percent = span ~= 0 and ((value - minValue) / span) or 0
		percent = math.max(0, math.min(1, percent))
		local barWidth = bar:GetWidth()
		if not barWidth or barWidth <= 0 then
			barWidth = trackWidth
		end
		local fillWidth = barWidth * percent
		if fillWidth <= 0.5 then
			fill:Hide()
		else
			fill:Show()
			fill:SetWidth(fillWidth)
		end
		valueText.Text:SetText(lib.FormatControlValue(control, value))
	end

	local function commitSliderValue(value)
		value = normalize(value)
		app:SetControlValue(control, value)
		slider.updating = true
		slider:SetValue(value)
		slider.updating = false
		slider:SyncVisual(value)
		lib.RefreshVisibleRows(row._state)
	end

	local valueEdit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	valueEdit:SetSize(96, 22)
	valueEdit:SetPoint("CENTER", valueText, "CENTER", 0, 0)
	valueEdit:SetAutoFocus(false)
	valueEdit:Hide()
	row.sliderValueEdit = valueEdit

	local function closeValueEdit(commit)
		if commit and app:IsControlEnabled(control) then
			commitSliderValue(tonumber(valueEdit:GetText()))
		end
		valueEdit:Hide()
		valueText:Show()
	end

	local function openValueEdit()
		if not app:IsControlEnabled(control) then
			return
		end
		valueText:Hide()
		valueEdit:SetText(tostring(app:GetControlValue(control) or minValue))
		valueEdit:Show()
		valueEdit:SetFocus()
		valueEdit:HighlightText()
	end

	valueText:EnableMouse(true)
	valueText:SetScript("OnMouseUp", openValueEdit)
	valueEdit:SetScript("OnEnterPressed", function() closeValueEdit(true) end)
	valueEdit:SetScript("OnEscapePressed", function() closeValueEdit(false) end)
	valueEdit:SetScript("OnEditFocusLost", function(self)
		if self:IsShown() then
			closeValueEdit(true)
		end
	end)

	slider:SetScript("OnValueChanged", function(self, rawValue)
		local value = normalize(rawValue)
		self:SyncVisual(value)
		if self.updating or self.normalizing then
			return
		end
		if math.abs((tonumber(rawValue) or value) - value) > 0.0001 then
			self.normalizing = true
			self:SetValue(value)
			self.normalizing = false
		end
		app:SetControlValue(control, value)
		lib.RefreshVisibleRows(row._state)
	end)

	local function adjustByStep(direction)
		if not app:IsControlEnabled(control) then
			return
		end
		local current = tonumber(app:GetControlValue(control)) or tonumber(control.default) or minValue
		commitSliderValue(current + ((step or 1) * direction))
	end

	if decreaseButton then
		decreaseButton:SetScript("OnClick", function()
			adjustByStep(-1)
		end)
	end
	if increaseButton then
		increaseButton:SetScript("OnClick", function()
			adjustByStep(1)
		end)
	end

	slider.Track = track
	slider.Bar = bar
	slider.Fill = fill
	slider.ScaleLeftAnchor = container
	slider.ScaleRightAnchor = container
	row.slider = slider
	row.sliderContainer = container
	row.sliderTrack = track
	row.sliderBar = bar
	row.sliderFill = fill
	return slider
end

local function addDropdownWidget(row, app, control, opts)
	opts = opts or {}
	local options = opts.options or getControlOptions(control)
	if #options == 0 or not MenuUtil or not MenuUtil.CreateContextMenu then
		addConfigureFallback(row, app, control, nil, opts.configure)
		return
	end
	local button = makeFlatButton(row, "", opts.width or 220, 26)
	if opts.point then
		button:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		button:SetPoint("RIGHT", row, "RIGHT", -14, 0)
	end
	row.dropdownButton = button
	row.value = createText(button, FONT_TEXT, "", TEXT.main, "LEFT")
	row.value:SetPoint("LEFT", button, "LEFT", 10, 0)
	row.value:SetPoint("RIGHT", button, "RIGHT", -22, 0)
	row.value:SetHeight(20)
	row.value.Text:SetJustifyH("LEFT")
	row.value.Text:SetJustifyV("MIDDLE")
	local arrow = createDropdownArrow(button, app, 12)
	button.Arrow = arrow
	arrow:SetPoint("RIGHT", button, "RIGHT", -8, 0)
	button:SetScript("OnClick", function(owner)
		if not app:IsControlEnabled(control) then
			return
		end
		MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
			local menuOptions = opts.options or getControlOptions(control)
			setDropdownMenuScrollMode(rootDescription, control, #menuOptions)
			local function getCurrentValue()
				if opts.getValue then
					return opts.getValue()
				end
				return app:GetControlValue(control)
			end
			for _, option in ipairs(menuOptions) do
				local radio = rootDescription:CreateRadio(option.label, function(value)
					return tostring(getCurrentValue()) == tostring(value)
				end, function(value)
					if opts.setValue then
						opts.setValue(value)
					else
						app:SetControlValue(control, value)
					end
					if control.refreshOnChange and row._state then
						C_Timer.After(0, function()
							if row._state and row._state.frame and row._state.frame:IsShown() then
								row._state:RenderContent()
							end
						end)
					else
						lib.RefreshVisibleRows(row._state)
					end
				end, option.value)
				if getControlType(control) == "sounddropdown" then
					lib.AttachSoundPreviewInitializer(radio, control, option)
				else
					lib.AttachSoundPreviewCleanupInitializer(radio)
				end
			end
		end)
	end)
	return button
end

local function addMultiDropdownWidget(row, app, control, opts)
	opts = opts or {}
	local options = getControlOptions(control)
	if #options == 0 or not MenuUtil or not MenuUtil.CreateContextMenu then
		addConfigureFallback(row, app, control, nil, opts.configure)
		return
	end

	local button = makeFlatButton(row, "", opts.width or 260, 26)
	if opts.point then
		button:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		button:SetPoint("RIGHT", row, "RIGHT", -14, 0)
	end
	row.multiDropdownButton = button
	row.value = createText(button, FONT_TEXT, "", TEXT.main, "LEFT")
	row.value:SetPoint("LEFT", button, "LEFT", 10, 0)
	row.value:SetPoint("RIGHT", button, "RIGHT", -22, 0)
	row.value:SetHeight(20)
	row.value.Text:SetJustifyH("LEFT")
	row.value.Text:SetJustifyV("MIDDLE")
	local arrow = createDropdownArrow(button, app, 12)
	button.Arrow = arrow
	arrow:SetPoint("RIGHT", button, "RIGHT", -8, 0)

	local function refreshSummary()
		row.value.Text:SetText(lib.GetMultiSummary(app, control))
	end

	button:SetScript("OnClick", function(owner)
		if not app:IsControlEnabled(control) then
			return
		end
		MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
			local menuOptions = getControlOptions(control)
			setDropdownMenuScrollMode(rootDescription, control, #menuOptions)
			for _, option in ipairs(menuOptions) do
				local function isSelected(value)
					return lib.IsMultiOptionSelected(lib.GetMultiSelection(app, control), value)
				end
				local function setSelected(value)
					local selection = lib.CopySelectionMap(lib.GetMultiSelection(app, control))
					local selected = not lib.IsMultiOptionSelected(selection, value)
					lib.SetMultiOptionSelected(selection, value, selected)
					if type(control.setSelectedFunc) == "function" then
						local ok = pcall(control.setSelectedFunc, value, selected, option)
						if not ok then
							app:SetControlValue(control, selection)
						end
					else
						app:SetControlValue(control, selection)
					end
					if type(control.callback) == "function" then
						pcall(control.callback, option)
					end
					if control.refreshOnChange and row._state then
						C_Timer.After(0, function()
							if row._state and row._state.frame and row._state.frame:IsShown() then
								row._state:RenderContent()
							end
						end)
					else
						lib.RefreshVisibleRows(row._state)
					end
					refreshSummary()
				end
				local check = rootDescription:CreateCheckbox(option.label, isSelected, setSelected, option.value)
				lib.AttachSoundPreviewCleanupInitializer(check)
			end
		end)
	end)
	refreshSummary()
	return button
end

local function addInputWidget(row, app, control, opts)
	opts = opts or {}
	local editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	editBox:SetSize(opts.width or math.min(tonumber(control.inputWidth) or 178, 220), control.multiline and 48 or 26)
	if opts.point then
		editBox:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		editBox:SetPoint("RIGHT", row, "RIGHT", -14, 0)
	end
	editBox:SetAutoFocus(false)
	local fractionalNumeric = false
	if control.numeric == true then
		local minValue = tonumber(control.min)
		local maxValue = tonumber(control.max)
		local stepValue = tonumber(control.step)
		local defaultValue = tonumber(control.default)
		fractionalNumeric = (minValue and minValue ~= math.floor(minValue))
			or (maxValue and maxValue ~= math.floor(maxValue))
			or (stepValue and stepValue ~= math.floor(stepValue))
			or (defaultValue and defaultValue ~= math.floor(defaultValue))
	end
	editBox:SetNumeric(control.numeric == true and not fractionalNumeric)
	if fractionalNumeric then
		local allowNegative = tonumber(control.min) and tonumber(control.min) < 0
		editBox:SetScript("OnTextChanged", function(self, userInput)
			if not userInput or self._eqolSanitizingText then
				return
			end
			local text = self:GetText() or ""
			local result = {}
			local hasDecimal = false
			local hasSign = false
			for index = 1, #text do
				local char = text:sub(index, index)
				if char:match("%d") then
					result[#result + 1] = char
				elseif (char == "." or char == ",") and not hasDecimal then
					hasDecimal = true
					result[#result + 1] = "."
				elseif char == "-" and allowNegative and not hasSign and #result == 0 then
					hasSign = true
					result[#result + 1] = char
				end
			end
			local sanitized = table.concat(result)
			if sanitized ~= text then
				self._eqolSanitizingText = true
				local cursorPosition = self:GetCursorPosition()
				self:SetText(sanitized)
				self:SetCursorPosition(math.min(cursorPosition, #sanitized))
				self._eqolSanitizingText = nil
			end
		end)
	end
	if control.maxChars then editBox:SetMaxLetters(control.maxChars) end
	if control.readOnly then editBox:SetEnabled(false) end
	editBox:SetScript("OnEnterPressed", function(self)
		commitInputValue(app, control, self, row)
		self:ClearFocus()
	end)
	editBox:SetScript("OnEditFocusLost", function(self)
		commitInputValue(app, control, self, row)
	end)
	row.editBox = editBox
	return editBox
end

local function addToggleWidget(row, app, control, opts)
	opts = opts or {}
	local switch = CreateFrame("Button", nil, row, "BackdropTemplate")
	switch._eqolOwner = row
	switch:SetSize(48, 24)
	if opts.point then
		switch:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		switch:SetPoint("RIGHT", row, "RIGHT", -16, 0)
	end
	applyBackdrop(switch, { 0.050, 0.046, 0.038, 0.95 }, CARD_BORDER, "toggle")

	switch.Knob = CreateFrame("Frame", nil, switch, "BackdropTemplate")
	switch.Knob:SetSize(18, 18)
	applyBackdrop(switch.Knob, { 0.62, 0.58, 0.49, 1.00 }, { 0.92, 0.82, 0.58, 0.80 }, "toggleKnob")

	function switch:SetChecked(checked)
		self.checked = checked == true
		self.Knob:ClearAllPoints()
		if self.checked then
			setFrameBackdrop(self, { 0.105, 0.205, 0.095, 0.96 }, { GREEN[1], GREEN[2], GREEN[3], 0.70 })
			setFrameBackdrop(self.Knob, { 0.78, 0.92, 0.66, 1.00 }, { GREEN[1], GREEN[2], GREEN[3], 0.85 })
			self.Knob:SetPoint("RIGHT", self, "RIGHT", -3, 0)
		else
			setFrameBackdrop(self, { 0.050, 0.046, 0.038, 0.95 }, CARD_BORDER)
			setFrameBackdrop(self.Knob, { 0.62, 0.58, 0.49, 1.00 }, { 0.92, 0.82, 0.58, 0.80 })
			self.Knob:SetPoint("LEFT", self, "LEFT", 3, 0)
		end
	end

	function switch:GetChecked()
		return self.checked == true
	end

	switch._eqolOnEnter = function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER)
			return
		end
		setBackdropBorderColor(self, CARD_BORDER_HOVER)
	end
	switch._eqolOnLeave = function(self)
		if self._eqolDisabled then
			setFrameBackdrop(self, DISABLED_CONTROL_BG, DISABLED_CONTROL_BORDER)
			return
		end
		self:SetChecked(self.checked)
	end
	switch:SetScript("OnEnter", switch._eqolOnEnter)
	switch:SetScript("OnLeave", switch._eqolOnLeave)
	switch:SetScript("OnClick", function(self)
		if not app:IsControlEnabled(control) then
			self:SetChecked(app:GetControlValue(control) == true)
			return
		end
		app:SetControlValue(control, not self:GetChecked())
		if control.refreshOnChange and row._state then
			C_Timer.After(0, function()
				if row._state and row._state.frame and row._state.frame:IsShown() then
					row._state:RenderContent()
				end
			end)
		else
			lib.RefreshVisibleRows(row._state)
		end
	end)

	row.check = switch
	return switch
end

local function addColorWidget(row, app, control, opts)
	opts = opts or {}
	local L = getLocale(app)
	if type(control.getColor) ~= "function" or type(control.setColor) ~= "function" or not ColorPickerFrame then
		addConfigureFallback(row, app, control, nil, opts.configure)
		return
	end
	local currentLabel = createText(row, FONT_TEXT, opts.currentText or (L["configCenterCurrent"] or "Current") .. ":", TEXT.main)
	if opts.point then
		currentLabel:SetPoint(opts.point[1], opts.point[2], opts.point[3], opts.point[4], opts.point[5])
	else
		currentLabel:SetPoint("LEFT", row, "LEFT", FIELD_CONTROL_LEFT, -29)
	end
	currentLabel:SetSize(58, 26)
	currentLabel.Text:SetJustifyV("MIDDLE")

	local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
	swatch._eqolOwner = row
	swatch:SetSize(34, 24)
	swatch:SetPoint("LEFT", currentLabel, "RIGHT", 8, 0)
	applyBackdrop(swatch, { 0.02, 0.02, 0.02, 0.92 }, CARD_BORDER, "swatch")
	swatch.Texture = swatch:CreateTexture(nil, "OVERLAY")
	swatch.Texture:SetPoint("TOPLEFT", swatch, "TOPLEFT", 4, -4)
	swatch.Texture:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -4, 4)
	row.swatch = swatch
	row.hexText = createText(row, FONT_TEXT, "", TEXT.gold)
	row.hexText:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
	row.hexText:SetSize(80, 26)
	row.hexText.Text:SetJustifyV("MIDDLE")

	local button = makeFlatButton(row, L["configCenterChange"] or "Change", 92, 26)
	button:SetPoint("LEFT", row.hexText, "RIGHT", 10, 0)
	row.colorButton = button
	local function openPicker()
		if not app:IsControlEnabled(control) then
			return
		end
		local key = control.key or control.id
		local ok, r, g, b, a = pcall(control.getColor, key)
		if not ok then
			r, g, b, a = 1, 1, 1, 1
		end
		r, g, b, a = r or 1, g or 1, b or 1, a or 1
		local function applyColor()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			local na = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or a
			control.setColor(key, nr, ng, nb, na)
			lib.RefreshVisibleRows(row._state)
		end
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow({
				r = r,
				g = g,
				b = b,
				opacity = a,
				hasOpacity = control.hasOpacity,
				swatchFunc = applyColor,
				opacityFunc = applyColor,
				cancelFunc = function(previous)
					if previous then control.setColor(key, previous.r, previous.g, previous.b, previous.opacity) end
					lib.RefreshVisibleRows(row._state)
				end,
			})
		else
			ColorPickerFrame.func = applyColor
			ColorPickerFrame.opacityFunc = applyColor
			ColorPickerFrame.hasOpacity = control.hasOpacity
			ColorPickerFrame.opacity = a
			ColorPickerFrame.previousValues = { r = r, g = g, b = b, opacity = a }
			ColorPickerFrame.cancelFunc = function(previous)
				if previous then control.setColor(key, previous.r, previous.g, previous.b, previous.opacity) end
				lib.RefreshVisibleRows(row._state)
			end
			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame:Show()
		end
	end
	button:SetScript("OnClick", openPicker)
	swatch:SetScript("OnClick", openPicker)
	return button
end

local function addColorOverridesWidget(row, app, control, opts)
	opts = opts or {}
	local L = getLocale(app)
	local entries = {}
	if type(control.entries) == "function" then
		local ok, result = pcall(control.entries, app, control)
		entries = ok and type(result) == "table" and result or {}
	elseif type(control.entries) == "table" then
		entries = control.entries
	end
	local hasColorCallbacks = type(control.getColor) == "function" and type(control.setColor) == "function"
	if #entries == 0 or not hasColorCallbacks or not ColorPickerFrame then
		addConfigureFallback(row, app, control, nil, opts.configure)
		return
	end

	row.colorOverrideSwatches = {}
	local columnGap = 14
	local rowHeight = 30
	local startX = FIELD_CONTROL_LEFT
	local startY = opts.startY or -58
	local availableWidth = math.max(300, (opts.width or row:GetWidth() or 560) - (startX * 2))
	local columnWidth = math.floor((availableWidth - columnGap) / 2)

	for index, entry in ipairs(entries) do
		local column = (index - 1) % 2
		local line = math.floor((index - 1) / 2)
		local item = CreateFrame("Button", nil, row, "BackdropTemplate")
		item:SetSize(columnWidth, rowHeight)
		item:SetPoint(
			"TOPLEFT",
			row,
			"TOPLEFT",
			startX + (column * (columnWidth + columnGap)),
			startY - (line * 36)
		)
		setFrameBackdrop(item, { 0.045, 0.040, 0.032, 0.70 }, { 0.20, 0.16, 0.10, 0.45 })

		item.Text = item:CreateFontString(nil, "OVERLAY", FONT_MUTED)
		item.Text:SetPoint("LEFT", item, "LEFT", 8, 0)
		item.Text:SetPoint("RIGHT", item, "RIGHT", type(control.clearColor) == "function" and -108 or -42, 0)
		item.Text:SetJustifyH("LEFT")
		item.Text:SetText(entry.label or entry.key or "?")
		setTextColor(item.Text, TEXT.subtle)

		item.Swatch = CreateFrame("Button", nil, item, "BackdropTemplate")
		item.Swatch:SetSize(24, 20)
		item.Swatch:SetPoint("RIGHT", item, "RIGHT", -8, 0)
		applyBackdrop(item.Swatch, { 0.02, 0.02, 0.02, 0.92 }, CARD_BORDER, "swatch")
		item.Swatch.Texture = item.Swatch:CreateTexture(nil, "OVERLAY")
		item.Swatch.Texture:SetPoint("TOPLEFT", item.Swatch, "TOPLEFT", 4, -4)
		item.Swatch.Texture:SetPoint("BOTTOMRIGHT", item.Swatch, "BOTTOMRIGHT", -4, 4)
		item.Reset = makeFlatButton(item, "", 24, 20)
		item.Reset:SetPoint("RIGHT", item.Swatch, "LEFT", -6, 0)
		item.Reset:SetShown(type(control.clearColor) == "function")
		item.Reset.Icon = item.Reset:CreateTexture(nil, "OVERLAY")
		item.Reset.Icon:SetSize(14, 14)
		item.Reset.Icon:SetPoint("CENTER")
		item.Reset.Icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
		item.Reset:SetScript("OnEnter", function(self)
			if _G.GameTooltip then
				_G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				_G.GameTooltip:SetText(L["configCenterResetColor"] or "Reset color")
				_G.GameTooltip:Show()
			end
		end)
		item.Reset:SetScript("OnLeave", function()
			if _G.GameTooltip then
				_G.GameTooltip:Hide()
			end
		end)

		local function openPicker()
			if not app:IsControlEnabled(control) then
				return
			end
			local ok, r, g, b, a = pcall(control.getColor, entry.key)
			if (not ok or r == nil) and type(control.getInheritedColor) == "function" then
				ok, r, g, b, a = pcall(control.getInheritedColor, entry.key, entry, app, control)
			end
			if (not ok or r == nil) and type(control.getDefaultColor) == "function" then
				ok, r, g, b, a = pcall(control.getDefaultColor, entry.key, entry, app, control)
			end
			if not ok then
				r, g, b, a = 1, 1, 1, 1
			end
			r, g, b, a = r or 1, g or 1, b or 1, a or 1
			local function applyColor()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or a
				control.setColor(entry.key, nr, ng, nb, control.hasOpacity and na or nil)
				lib.RefreshVisibleRows(row._state)
			end
			ColorPickerFrame:SetupColorPickerAndShow({
				r = r,
				g = g,
				b = b,
				opacity = a,
				hasOpacity = control.hasOpacity,
				swatchFunc = applyColor,
				opacityFunc = applyColor,
					cancelFunc = function(previous)
						if previous then
							control.setColor(
								entry.key,
								previous.r,
								previous.g,
								previous.b,
								control.hasOpacity and previous.opacity or nil
							)
						end
						lib.RefreshVisibleRows(row._state)
					end,
				})
			end

		item:SetScript("OnClick", openPicker)
		item.Swatch:SetScript("OnClick", openPicker)
		item.Reset:SetScript("OnClick", function()
			if not app:IsControlEnabled(control) or type(control.clearColor) ~= "function" then
				return
			end
			control.clearColor(entry.key, entry, app, control)
			lib.RefreshVisibleRows(row._state)
		end)
		row.colorOverrideSwatches[#row.colorOverrideSwatches + 1] = item
	end

	row.refreshControls = function()
		local enabled = app:IsControlEnabled(control)
		if type(control.entries) == "function" then
			local ok, result = pcall(control.entries, app, control)
			if ok and type(result) == "table" and #result ~= #entries then
				if row._state then
					row._state:RenderContent()
				end
				return
			elseif ok and type(result) == "table" then
				entries = result
			end
		end
		for index, item in ipairs(row.colorOverrideSwatches or {}) do
			local entry = entries[index]
			local hasOverride = true
			if type(control.hasOverride) == "function" then
				local okOverride, override = pcall(control.hasOverride, entry.key, entry, app, control)
				hasOverride = okOverride and override == true
			end
			local ok, r, g, b, a = pcall(control.getColor, entry.key)
			if (not ok or r == nil) and type(control.getInheritedColor) == "function" then
				ok, r, g, b, a = pcall(control.getInheritedColor, entry.key, entry, app, control)
			end
			if (not ok or r == nil) and type(control.getDefaultColor) == "function" then
				ok, r, g, b, a = pcall(control.getDefaultColor, entry.key, entry, app, control)
			end
			if not ok then
				r, g, b, a = 1, 1, 1, 1
			end
			item:SetAlpha(enabled and 1 or 0.55)
			if item.EnableMouse then item:EnableMouse(enabled) end
			if item.Swatch and item.Swatch.EnableMouse then item.Swatch:EnableMouse(enabled) end
			if item.Reset and item.Reset.SetShown then
				item.Reset:SetShown(type(control.clearColor) == "function" and hasOverride)
			end
			item.Swatch.Texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
			item.Swatch:SetAlpha(hasOverride and 1 or 0.62)
			if control.colorizeLabel and enabled then
				item.Text:SetTextColor(r or TEXT.subtle[1], g or TEXT.subtle[2], b or TEXT.subtle[3], 1)
			else
				setTextColor(item.Text, TEXT.subtle)
			end
		end
	end
	row.refreshControls()
end

function lib.ReorderList.EnsurePopup()
	if StaticPopupDialogs.LIB_SETTINGS_DESIGNER_REORDER_LIST_ADD then return end
	local L = getLibLocale()
	StaticPopupDialogs.LIB_SETTINGS_DESIGNER_REORDER_LIST_ADD = {
		text = "%s",
		button1 = L["configCenterAdd"] or "Add",
		button2 = L["configCenterCancel"] or "Cancel",
		hasEditBox = true,
		editBoxWidth = 180,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnShow = function(self, data)
			if data and data.title and self.text then self.text:SetText(data.title) end
			local editBox = self.editBox or self.EditBox
			if editBox then
				editBox:SetText("")
				editBox:SetNumeric(data and data.numeric == true)
				editBox:SetMaxLetters(data and data.maxLetters or 12)
				editBox:SetFocus()
			end
		end,
		OnAccept = function(self, data)
			local editBox = self.editBox or self.EditBox
			local text = editBox and editBox:GetText() or ""
			if data and type(data.onAccept) == "function" then data.onAccept(text) end
		end,
	}
end

function lib.ReorderList.CallControl(control, name, ...)
	local func = control and control[name]
	if type(func) ~= "function" then return nil end
	local ok, result, extra = pcall(func, ...)
	if ok then return result, extra end
	return nil
end

function lib.ReorderList.GetEntries(control)
	local entries = lib.ReorderList.CallControl(control, "getEntries")
	if type(entries) == "table" then return entries end
	return {}
end

function lib.ReorderList.GetEntryID(entry, index)
	return entry and (entry.id or entry.key or entry.value or entry.currencyID) or index
end

function lib.ReorderList.GetEntryLabel(control, entry, index)
	if type(control and control.formatEntryLabel) == "function" then
		local ok, label = pcall(control.formatEntryLabel, entry, index, control)
		if ok and label ~= nil then
			return tostring(label)
		end
	end
	if type(entry) ~= "table" then return tostring(entry or index) end
	local label = entry.label or entry.text or entry.name or entry.title
	local id = lib.ReorderList.GetEntryID(entry, index)
	local showID = entry.showID
	if showID == nil then
		showID = control and control.showEntryID
	end
	if showID == nil then
		showID = true
	end
	if showID and id ~= nil and label and label ~= "" and tostring(id) ~= tostring(label) then
		return ("%s (%s)"):format(label, tostring(id))
	end
	return label or tostring(id or index)
end

function lib.ReorderList.GetEntryIcon(entry)
	if type(entry) ~= "table" then return nil end
	return entry.icon or entry.iconFileID or entry.texture
end

function lib.ReorderList.GetEntryFormatKey(entry)
	if type(entry) ~= "table" then return nil end
	return entry.formatKey or entry.format or entry.mode
end

function lib.ReorderList.GetFormatLabel(control, formatKey)
	local options = type(control.formatOptions) == "table" and control.formatOptions or nil
	if options and options[formatKey] then return tostring(options[formatKey]) end
	return tostring(formatKey or "")
end

function lib.ReorderList.GetFormatOrder(control)
	if type(control.formatOrder) == "table" then return control.formatOrder end
	local order = {}
	if type(control.formatOptions) == "table" then
		for key in pairs(control.formatOptions) do order[#order + 1] = key end
		table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
	end
	return order
end

function lib.ReorderList.RefreshRows(row, control)
	if control and control.refreshOnChange and row and row._state then
		row._state:RenderContent()
	else
		lib.RefreshVisibleRows(row and row._state)
	end
end

function lib.StoreCustomHandle(state, key, owner, handle)
	if not (state and key) then
		return
	end
	state.customHandles = state.customHandles or {}
	state.customHandles[key] = {
		owner = owner,
		handle = handle,
	}
end

function lib.RenderCustomOwner(state, parent, owner, key)
	if not (state and parent and owner and key) then
		return nil
	end
	local handle
	if type(owner.render) == "function" then
		local ok, result = pcall(owner.render, parent, state.app, owner, state, state.pendingCustomFocusID)
		if ok then
			handle = result
		end
	elseif type(owner.onRender) == "function" then
		local ok, result = pcall(owner.onRender, parent, state.app, owner, state, state.pendingCustomFocusID)
		if ok then
			handle = result
		end
	end
	if handle ~= nil then
		lib.StoreCustomHandle(state, key, owner, handle)
	end
	if type(owner.refresh) == "function" then
		pcall(owner.refresh, handle, state.app, owner, state)
	elseif type(handle) == "table" and type(handle.Refresh) == "function" then
		pcall(handle.Refresh, handle, state.app, owner, state)
	end
	return handle
end

function lib.AddReorderListWidget(row, app, control, opts)
	opts = opts or {}
	local L = getLocale(app)
	local top = opts.startY or -56
	local canAdd = control.showAddButton
	if canAdd == nil then
		canAdd = type(control.addEntry) == "function"
	end
	local canRemove = control.showRemoveButton
	if canRemove == nil then
		canRemove = type(control.removeEntry) == "function"
	end
	local hasRowActions = type(control.rowActions) == "table" and #control.rowActions > 0
	local hasEntryToggle = type(control.entryToggle) == "table"
	local addButton = makeFlatButton(row, control.addButtonText or (L["configCenterAdd"] or "Add"), 92, 24)
	addButton:SetPoint("TOPLEFT", row, "TOPLEFT", FIELD_CONTROL_LEFT, top)
	addButton:SetShown(canAdd)
	row.actionButton = addButton
	addButton:SetScript("OnClick", function()
		if not app:IsControlEnabled(control) then return end
		lib.ReorderList.EnsurePopup()
		StaticPopup_Show("LIB_SETTINGS_DESIGNER_REORDER_LIST_ADD", control.addPopupText or control.addPopupTitle or "", nil, {
			title = control.addPopupTitle or control.addPopupText or control.label,
			numeric = control.numeric == true,
			maxLetters = control.maxChars,
			onAccept = function(text)
				lib.ReorderList.CallControl(control, "addEntry", text)
				lib.ReorderList.RefreshRows(row, control)
			end,
		})
	end)

	local status = createText(row, FONT_MUTED, "", TEXT.muted)
	if canAdd then
		status:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
	else
		status:SetPoint("LEFT", row, "LEFT", FIELD_CONTROL_LEFT, 0)
	end
	status:SetPoint("RIGHT", row, "RIGHT", -14, 0)
	status:SetHeight(24)

	row.reorderRows = row.reorderRows or {}
	local function refreshRows()
		local enabled = app:IsControlEnabled(control)
		local entries = lib.ReorderList.GetEntries(control)
		status.Text:SetText(#entries == 0 and (control.emptyText or L["configCenterNone"] or "None") or "")
		for index, entry in ipairs(entries) do
			local item = row.reorderRows[index]
			if not item then
				item = CreateFrame("Button", nil, row, "BackdropTemplate")
				item:SetHeight(28)
				item:RegisterForDrag("LeftButton")
				item:EnableMouse(true)
				item.Icon = item:CreateTexture(nil, "ARTWORK")
				item.Icon:SetSize(18, 18)
				item.Icon:SetPoint("LEFT", item, "LEFT", 8, 0)
				item.Text = item:CreateFontString(nil, "OVERLAY", FONT_TEXT)
				item.Text:SetPoint("LEFT", item.Icon, "RIGHT", 8, 0)
				item.Text:SetPoint("RIGHT", item, "RIGHT", -296, 0)
				item.Text:SetJustifyH("LEFT")
				item.Toggle = CreateFrame("Button", nil, item, "BackdropTemplate")
				item.Toggle:SetSize(42, 22)
				applyBackdrop(item.Toggle, { 0.050, 0.046, 0.038, 0.95 }, CARD_BORDER, "toggle")
				item.Toggle.Knob = CreateFrame("Frame", nil, item.Toggle, "BackdropTemplate")
				item.Toggle.Knob:SetSize(14, 14)
				applyBackdrop(item.Toggle.Knob, { 0.62, 0.58, 0.49, 1.00 }, { 0.92, 0.82, 0.58, 0.80 }, "toggleKnob")
				item.Format = makeFlatButton(item, "", 128, 22)
				item.Format:SetPoint("RIGHT", item, "RIGHT", -160, 0)
				item.MoveUp = makeFlatButton(item, "", 24, 22)
				item.MoveUp:SetPoint("RIGHT", item, "RIGHT", -128, 0)
				item.MoveUp.Arrow = createAssetArrow(item.MoveUp, app, 12, "dropdown", "up")
				item.MoveUp.Arrow:SetPoint("CENTER")
				item.MoveDown = makeFlatButton(item, "", 24, 22)
				item.MoveDown:SetPoint("RIGHT", item, "RIGHT", -98, 0)
				item.MoveDown.Arrow = createAssetArrow(item.MoveDown, app, 12, "dropdown", "down")
				item.MoveDown.Arrow:SetPoint("CENTER")
				item.Remove = makeFlatButton(item, L["configCenterRemove"] or "Remove", 84, 22)
				item.Remove:SetPoint("RIGHT", item, "RIGHT", -8, 0)
				item.Actions = makeFlatButton(item, "...", 44, 22)
				item.Actions:SetPoint("RIGHT", item, "RIGHT", -8, 0)
				row.reorderRows[index] = item
			end
			item:ClearAllPoints()
			item:SetPoint("TOPLEFT", row, "TOPLEFT", FIELD_CONTROL_LEFT, top - 34 - ((index - 1) * 32))
			item:SetPoint("RIGHT", row, "RIGHT", -14, 0)
			applyBackdrop(item, { 0.045, 0.040, 0.032, 0.80 }, { 0.20, 0.16, 0.10, 0.45 }, "reorderItem")
			item._eqolIndex = index
			item._eqolEntryID = lib.ReorderList.GetEntryID(entry, index)
			item.Icon:SetTexture(lib.ReorderList.GetEntryIcon(entry) or 134400)
			item.Text:SetText(lib.ReorderList.GetEntryLabel(control, entry, index))
			setTextColor(item.Text, enabled and TEXT.main or TEXT.disabled)
			item:SetAlpha(enabled and 1 or 0.52)
			item:EnableMouse(enabled)
			item.Format:SetShown(type(control.formatOptions) == "table")
			item.Toggle:SetShown(hasEntryToggle)
			item.Remove:SetShown(canRemove)
			item.Actions:SetShown(hasRowActions)
			item.Text:ClearAllPoints()
			item.Text:SetPoint("LEFT", item.Icon, "RIGHT", 8, 0)
			if hasEntryToggle then
				item.Toggle:ClearAllPoints()
				item.Toggle:SetPoint("LEFT", item.Icon, "RIGHT", 8, 0)
				item.Text:SetPoint("LEFT", item.Toggle, "RIGHT", 8, 0)
			end
			local rightInset = -8
			if hasRowActions then
				rightInset = rightInset - 54
			end
			if canRemove then
				rightInset = rightInset - 92
			end
			if type(control.moveEntry) == "function" then
				rightInset = rightInset - 60
			end
			if type(control.formatOptions) == "table" then
				rightInset = rightInset - 136
			end
			if type(control.formatOptions) == "table" then
				item.Text:SetPoint("RIGHT", item, "RIGHT", rightInset, 0)
			elseif type(control.moveEntry) == "function" then
				item.Text:SetPoint("RIGHT", item, "RIGHT", rightInset, 0)
			else
				item.Text:SetPoint("RIGHT", item, "RIGHT", rightInset, 0)
			end
			item.Actions:ClearAllPoints()
			item.Actions:SetPoint("RIGHT", item, "RIGHT", -8, 0)
			item.Remove:ClearAllPoints()
			item.Remove:SetPoint("RIGHT", item, "RIGHT", hasRowActions and -60 or -8, 0)
			item.MoveDown:ClearAllPoints()
			item.MoveDown:SetPoint("RIGHT", item, "RIGHT", (canRemove and -150 or -60) - (hasRowActions and 54 or 0), 0)
			item.MoveUp:ClearAllPoints()
			item.MoveUp:SetPoint("RIGHT", item, "RIGHT", (canRemove and -180 or -90) - (hasRowActions and 54 or 0), 0)
			item.Format:ClearAllPoints()
			item.Format:SetPoint("RIGHT", item, "RIGHT", (canRemove and -212 or -122) - (hasRowActions and 54 or 0) - (type(control.moveEntry) == "function" and 60 or 0), 0)
			if hasEntryToggle then
				local toggle = control.entryToggle
				local checked = false
				if type(toggle.getValue) == "function" then
					local ok, value = pcall(toggle.getValue, item._eqolEntryID, entry, app, control)
					checked = ok and value == true
				elseif entry.visible ~= nil then
					checked = entry.visible == true
				elseif entry.enabled ~= nil then
					checked = entry.enabled == true
				end
				setFrameBackdrop(item.Toggle, checked and { 0.105, 0.205, 0.095, 0.96 } or { 0.050, 0.046, 0.038, 0.95 }, checked and { GREEN[1], GREEN[2], GREEN[3], 0.70 } or CARD_BORDER, "toggle")
				item.Toggle.Knob:ClearAllPoints()
				item.Toggle.Knob:SetPoint(checked and "RIGHT" or "LEFT", item.Toggle, checked and "RIGHT" or "LEFT", checked and -4 or 4, 0)
				item.Toggle:SetScript("OnClick", function()
					if not app:IsControlEnabled(control) then return end
					if type(toggle.setValue) == "function" then
						toggle.setValue(item._eqolEntryID, entry, not checked, app, control)
						lib.ReorderList.RefreshRows(row, control)
					end
				end)
			end
			item.Format.Text:SetText(lib.ReorderList.GetFormatLabel(control, lib.ReorderList.GetEntryFormatKey(entry)))
			item.MoveUp:SetShown(type(control.moveEntry) == "function")
			item.MoveDown:SetShown(type(control.moveEntry) == "function")
			item.MoveUp._eqolDisabled = not enabled or index <= 1
			item.MoveDown._eqolDisabled = not enabled or index >= #entries
			if item.MoveUp.SetEnabled then item.MoveUp:SetEnabled(not item.MoveUp._eqolDisabled) end
			if item.MoveDown.SetEnabled then item.MoveDown:SetEnabled(not item.MoveDown._eqolDisabled) end
			lib.ApplyFlatButtonVisual(item.MoveUp)
			lib.ApplyFlatButtonVisual(item.MoveDown)
			item.Format:SetScript("OnClick", function(owner)
				if not app:IsControlEnabled(control) then return end
				if not MenuUtil or not MenuUtil.CreateContextMenu then return end
				local entryID = item._eqolEntryID
				MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
					rootDescription:SetTag("LIB_SETTINGS_DESIGNER_REORDER_FORMAT")
					for _, key in ipairs(lib.ReorderList.GetFormatOrder(control)) do
						rootDescription:CreateRadio(lib.ReorderList.GetFormatLabel(control, key), function() return lib.ReorderList.GetEntryFormatKey(entry) == key end, function()
							lib.ReorderList.CallControl(control, "setEntryFormat", entryID, key)
							lib.RefreshVisibleRows(row._state)
						end)
					end
				end)
			end)
			item.MoveUp:SetScript("OnClick", function()
				if item.MoveUp._eqolDisabled or not app:IsControlEnabled(control) then return end
				lib.ReorderList.CallControl(control, "moveEntry", item._eqolIndex, item._eqolIndex - 1)
				lib.ReorderList.RefreshRows(row, control)
			end)
			item.MoveDown:SetScript("OnClick", function()
				if item.MoveDown._eqolDisabled or not app:IsControlEnabled(control) then return end
				lib.ReorderList.CallControl(control, "moveEntry", item._eqolIndex, item._eqolIndex + 1)
				lib.ReorderList.RefreshRows(row, control)
			end)
			item.Remove:SetScript("OnClick", function()
				if not app:IsControlEnabled(control) then return end
				lib.ReorderList.CallControl(control, "removeEntry", item._eqolEntryID)
				lib.ReorderList.RefreshRows(row, control)
			end)
			item.Actions:SetScript("OnClick", function(owner)
				if not app:IsControlEnabled(control) then return end
				if not MenuUtil or not MenuUtil.CreateContextMenu then return end
				local entryID = item._eqolEntryID
				MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
					rootDescription:SetTag("LIB_SETTINGS_DESIGNER_REORDER_ACTIONS")
					for _, action in ipairs(control.rowActions or {}) do
						local visible = true
						if type(action.visibleWhen) == "function" then
							local ok, result = pcall(action.visibleWhen, entry, entryID, app, control)
							visible = ok and result ~= false
						end
						if visible and type(action.onClick) == "function" then
							rootDescription:CreateButton(action.label or action.title or action.id or "Action", function()
								action.onClick(entryID, entry, item, app, control)
								lib.ReorderList.RefreshRows(row, control)
							end)
						end
					end
				end)
			end)
			item:SetScript("OnDragStart", function(self)
				if not app:IsControlEnabled(control) then return end
				row._eqolDragIndex = self._eqolIndex
				setFrameBackdrop(self, SELECTED_BG, CARD_BORDER_HOVER)
			end)
			item:SetScript("OnDragStop", function()
				local fromIndex = row._eqolDragIndex
				row._eqolDragIndex = nil
				if not fromIndex then return end
				for targetIndex, target in ipairs(row.reorderRows or {}) do
					if target:IsShown() and target.MouseIsOver and target:MouseIsOver() then
						if targetIndex ~= fromIndex then lib.ReorderList.CallControl(control, "moveEntry", fromIndex, targetIndex) end
						break
					end
				end
				lib.ReorderList.RefreshRows(row, control)
			end)
			item:Show()
		end
		for index = #entries + 1, #(row.reorderRows or {}) do
			row.reorderRows[index]:Hide()
		end
	end
	row.refreshControls = refreshRows
	refreshRows()
end

local function addSettingRow(state, control, pathText, parent, yOffset, width)
	local app = state.app
	local L = getLocale(app)
	local _ = pathText
	local controlType = getControlType(control)
	local layoutType = getControlLayoutType(control)
	local compact = lib.IsCompactDensity(state)
	local rowHeight = getSettingRowHeight(control, state)
	local rowWidth = width or parent and (parent:GetWidth() - 24) or state.pageLeftWidth or state.contentWidth or 620
	local row
	if parent then
		row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		snapPoint(row, "TOPLEFT", parent, "TOPLEFT", 12, yOffset or -42)
		snapSize(row, rowWidth, rowHeight)
		if parent._LibSettingsDesignerContentY then
			row._LibSettingsDesignerContentY = parent._LibSettingsDesignerContentY + (yOffset or -42)
		end
	else
		row = createContentFrame(state, rowHeight)
		rowWidth = row:GetWidth() > 0 and row:GetWidth() or rowWidth
	end
	row._state = state
	state.controlRows = state.controlRows or {}
	state.controlRows[#state.controlRows + 1] = { row = row, control = control }
	styleInlineSettingRow(row)

	local textLeft = 16
	if control.icon or control.iconAtlas then
		local rowIcon = createIcon(row, control.icon or control.iconAtlas, 18, control.iconAtlas ~= nil)
		rowIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -14)
		textLeft = 42
	end

	local title = createText(row, FONT_TEXT, control.label or control.id, TEXT.main)
	title:SetPoint("TOPLEFT", row, "TOPLEFT", textLeft, -12)
	title:SetHeight(20)

	local descText
	if controlType == "slider" then
		descText = lib.CompactDescription(control.description)
	elseif control.description and control.description ~= "" then
		descText = lib.CompactDescription(control.description)
	elseif layoutType == "complex" then
		descText = L["configCenterAdvancedSettingDesc"] or "Open the related editor or action for this setting."
	elseif layoutType == "stacked" or controlType == "button" or controlType == "colorpalette" then
		descText = lib.GetFallbackControlDescription(app, control)
	else
		descText = ""
	end
	local desc = createText(row, FONT_MUTED, descText or "", TEXT.muted)
	desc.Text:SetWordWrap(true)
	if compact then
		desc:Hide()
	end
	local hasNewBadge = lib.IsControlNew(app, control)

	if layoutType == "boolean" then
		if compact then
			title:ClearAllPoints()
			title:SetPoint("LEFT", row, "LEFT", textLeft, 0)
			title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -88, 0)
			title:SetHeight(20)
		else
			title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -88, 0)
			desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
			desc:SetPoint("RIGHT", row, "RIGHT", -88, 0)
			desc:SetHeight(30)
		end
		addToggleWidget(row, app, control)
	elseif layoutType == "stacked" then
		local valueWidth = controlType == "slider" and 96 or 0
		if valueWidth > 0 then
			title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -178 or -(valueWidth + 18), 0)
		else
			title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		end

		local controlWidth = getFieldControlWidth(rowWidth)
		if controlType == "slider" then
			local hasDescription = hasUsefulDescription(control)
			if hasDescription and not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(22)
			else
				desc:Hide()
			end
			local valueText = createText(row, FONT_TEXT, "", TEXT.gold, "RIGHT")
			valueText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -18, -12)
			valueText:SetSize(valueWidth, 20)
			local hasRangeLabels = control.min ~= nil or control.max ~= nil
			local labelWidth = hasRangeLabels and lib.GetSliderScaleLabelWidth(control) or 0
			local sliderGap = hasRangeLabels and SLIDER_SCALE_GAP or 0
			local sliderY = compact and 8 or 10
			local sliderWidth = getSliderControlWidth(rowWidth, labelWidth, sliderGap)
			local slider = addSliderWidget(row, app, control, {
				point = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT + labelWidth + sliderGap, sliderY },
				width = sliderWidth,
				valueText = valueText,
			})
			if hasRangeLabels then
				local minLabel = createText(row, FONT_MUTED, lib.FormatControlValue(control, control.min), TEXT.subtle, "RIGHT")
				minLabel:SetPoint("RIGHT", slider.ScaleLeftAnchor or slider, "LEFT", -sliderGap, 0)
				minLabel:SetSize(labelWidth, 18)
				minLabel.Text:SetJustifyH("RIGHT")
				minLabel.Text:SetJustifyV("MIDDLE")
				local maxLabel = createText(row, FONT_MUTED, lib.FormatControlValue(control, control.max), TEXT.subtle, "LEFT")
				maxLabel:SetPoint("LEFT", slider.ScaleRightAnchor or slider, "RIGHT", sliderGap, 0)
				maxLabel:SetSize(labelWidth, 18)
				maxLabel.Text:SetJustifyH("LEFT")
				maxLabel.Text:SetJustifyV("MIDDLE")
			end
		elseif controlType == "dropdown" or controlType == "sounddropdown" then
			if not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(32)
			end
			local controlPoint = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, compact and 8 or 15 }
			addDropdownWidget(row, app, control, {
				point = controlPoint,
				width = controlWidth,
				configure = {
					point = controlPoint,
					width = 150,
				},
			})
		elseif controlType == "multidropdown" then
			if not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(32)
			end
			local controlPoint = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, compact and 8 or 15 }
			addMultiDropdownWidget(row, app, control, {
				point = controlPoint,
				width = controlWidth,
				configure = {
					point = controlPoint,
					width = 150,
				},
			})
		elseif controlType == "checkboxdropdown" then
			title:SetPoint("RIGHT", row, "RIGHT", -88, 0)
			if not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(32)
			end
			addToggleWidget(row, app, control, {
				point = { "TOPRIGHT", row, "TOPRIGHT", -16, -12 },
			})
			local controlPoint = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, compact and 8 or 15 }
			addDropdownWidget(row, app, control, {
				point = controlPoint,
				width = controlWidth,
				options = lib.GetCheckboxDropdownOptions(control),
				getValue = function()
					return lib.GetCheckboxDropdownValue(app, control)
				end,
				setValue = function(value)
					lib.SetCheckboxDropdownValue(app, control, value)
				end,
				configure = {
					point = controlPoint,
					width = 150,
				},
			})
			row.refreshValue = function()
				row.value.Text:SetText(lib.GetCheckboxDropdownText(app, control))
			end
		elseif controlType == "input" then
			if not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(32)
			end
			local controlPoint = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, compact and 8 or 15 }
			addInputWidget(row, app, control, {
				point = controlPoint,
				width = controlWidth,
			})
		elseif controlType == "colorpicker" then
			if not compact then
				desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
				desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
				desc:SetHeight(32)
			end
			local controlPoint = { "BOTTOMLEFT", row, "BOTTOMLEFT", FIELD_CONTROL_LEFT, compact and 8 or 15 }
			addColorWidget(row, app, control, {
				point = controlPoint,
				configure = {
					point = controlPoint,
					width = 150,
				},
			})
		end
	elseif controlType == "colorpalette" then
		title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		desc.Text:SetText(control.description or "")
		desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
		desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
		desc:SetHeight(control.description and control.description ~= "" and 24 or 1)
		addColorOverridesWidget(row, app, control, {
			width = rowWidth,
			startY = control.description and control.description ~= "" and -68 or -48,
			configure = {
				point = { "BOTTOMRIGHT", row, "BOTTOMRIGHT", -14, 14 },
				width = 150,
			},
		})
	elseif controlType == "reorderlist" then
		title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		if not compact then
			desc.Text:SetText(control.description or "")
			desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
			desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
			desc:SetHeight(control.description and control.description ~= "" and 24 or 1)
		end
		lib.AddReorderListWidget(row, app, control, {
			startY = control.description and control.description ~= "" and -68 or -48,
		})
	elseif controlType == "custom" then
		title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		desc.Text:SetText(control.description or "")
		desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
		desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
		desc:SetHeight(control.description and control.description ~= "" and 24 or 1)
		local top = control.description and control.description ~= "" and -68 or -48
		local container = CreateFrame("Frame", nil, row, "BackdropTemplate")
		container:SetPoint("TOPLEFT", row, "TOPLEFT", FIELD_CONTROL_LEFT, top)
		container:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -14, 14)
		container._LibSettingsDesignerControl = control
		lib.RenderCustomOwner(state, container, control, "control:" .. tostring(control.id or control.key))
	elseif controlType == "button" then
		title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		if not compact then
			desc.Text:SetText(control.description or "")
			desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
			desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
			desc:SetHeight(control.description and control.description ~= "" and 36 or 1)
		end
		local button = makeFlatButton(row, control.buttonText or (L["configCenterOkay"] or "OK"), 112, 26)
		button:SetPoint(compact and "RIGHT" or "BOTTOMRIGHT", row, compact and "RIGHT" or "BOTTOMRIGHT", -14, compact and 0 or 14)
		row.actionButton = button
		button:SetScript("OnClick", function()
			if not app:IsControlEnabled(control) then
				return
			end
			if type(control.onClick) == "function" then
				control.onClick()
			elseif type(control.setValue) == "function" then
				control.setValue()
			end
			if control.refreshOnChange then
				lib.RefreshVisibleRows(row._state)
			end
		end)
	else
		title:SetPoint("RIGHT", row, "RIGHT", hasNewBadge and -154 or -18, 0)
		if not compact then
			desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
			desc:SetPoint("RIGHT", row, "RIGHT", -18, 0)
			desc:SetHeight(36)
		end
		if controlType == "keybind" then
			addConfigureFallback(row, app, control, control.buttonText, {
				point = compact and { "RIGHT", row, "RIGHT", -14, 0 } or { "BOTTOMRIGHT", row, "BOTTOMRIGHT", -14, 14 },
				width = 150,
			})
			local badge = addStatusChip(row, L["configCenterKeyBindings"] or "Key Bindings", TEXT.muted, 92)
			badge:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", textLeft, 15)
		end
	end

	if hasNewBadge then
		local newBadge = lib.CreateNewBadge(row)
		newBadge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -118, -8)
	end

	refreshControlRow(app, control, row)
	lib.AttachControlNoteHover(row, state, control)
	if not parent then
		state.y = snap(state.content, state.y - 10)
	end
	return row
end

local function resetCurrentPage(state)
	if state.view ~= "page" or not state.selectedPageID then
		return
	end
	local page = state.app:GetPage(state.selectedPageID)
	if not page then
		return
	end
	for _, control in ipairs(getVisiblePageControls(state.app, page)) do
		local default, hasDefault
		if type(state.app.GetControlDefault) == "function" then
			default, hasDefault = state.app:GetControlDefault(control)
		else
			default, hasDefault = control.default, control.default ~= nil
		end
		if hasDefault then
			state.app:SetControlValue(control, default)
		end
	end
	state:RenderContent()
end

local function confirmResetCurrentPage(state)
	if state.view ~= "page" or not state.selectedPageID then
		return
	end
	local page = state.app:GetPage(state.selectedPageID)
	if not page then
		return
	end
	local L = getLocale(state.app)
	if not StaticPopupDialogs or not StaticPopup_Show then
		resetCurrentPage(state)
		return
	end
	StaticPopupDialogs.LIB_SETTINGS_DESIGNER_CENTER_RESET_DEFAULTS = StaticPopupDialogs.LIB_SETTINGS_DESIGNER_CENTER_RESET_DEFAULTS or {
		button1 = L["configCenterOkay"] or "OK",
		button2 = L["configCenterCancel"] or "Cancel",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnAccept = function(_, data)
			if data and data.state then
				resetCurrentPage(data.state)
			end
		end,
	}
	local dialog = StaticPopupDialogs.LIB_SETTINGS_DESIGNER_CENTER_RESET_DEFAULTS
	dialog.text = (L["configCenterConfirmDefaultsTitle"] or "Reset this page to default values?")
		.. "\n\n"
		.. (L["configCenterConfirmDefaultsDesc"] or "This will restore all settings on %s to their defaults."):format(
			page.title or page.id
		)
	StaticPopup_Show("LIB_SETTINGS_DESIGNER_CENTER_RESET_DEFAULTS", nil, nil, { state = state })
end

local function addPageCard(state, page, row, index, columns)
	local controlCount = lib.GetPageSettingCount(state.app, page)
	local customizedCount = lib.GetPageCustomizedCount(state.app, page)
	local card = row and createGridCard(state, row, index, columns or 2, PAGE_CARD_HEIGHT)
		or createContentFrame(state, PAGE_CARD_HEIGHT)
	styleRaisedTile(card, true)
	card:SetScript("OnMouseUp", function()
		state:SetPage(page.id)
	end)

	local iconSource, iconIsAtlas = resolvePageIcon(state.app, page)
	local icon = createIconPlate(card, iconSource, PAGE_CARD_ICON_SIZE, iconIsAtlas)
	icon:SetPoint("LEFT", card, "LEFT", PAGE_CARD_PAD_X, 0)

	local textLeft = PAGE_CARD_TEXT_LEFT
	local rightInset = PAGE_CARD_PAD_X

	local title = createText(card, FONT_HEADER, page.title or page.id, TEXT.main)
	title:SetPoint("TOPLEFT", card, "TOPLEFT", textLeft, -24)
	local hasNewBadge = lib.IsPageOrChildNew(state.app, page)
	title:SetPoint("RIGHT", card, "RIGHT", hasNewBadge and -82 or -rightInset, 0)
	title:SetHeight(22)
	if hasNewBadge then
		local newBadge = lib.CreateNewBadge(card)
		newBadge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -18)
	end

	local desc = getPageCardDescription(state.app, page)
	local descText = createText(card, FONT_MUTED, desc, TEXT.muted)
	descText:SetPoint("TOPLEFT", card, "TOPLEFT", textLeft, -50)
	descText:SetPoint("RIGHT", card, "RIGHT", -rightInset, 0)
	descText:SetHeight(32)
	descText.Text:SetWordWrap(true)
	if descText.Text.SetMaxLines then
		descText.Text:SetMaxLines(2)
	end

	local metaText = getSettingCountText(state.app, controlCount)
	local meta = createText(card, FONT_MUTED, metaText, TEXT.gold)
	meta:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", textLeft, 14)
	meta:SetSize(92, 16)
	meta:SetHeight(16)
	if customizedCount > 0 then
		local L = getLocale(state.app)
		local changedText = tostring(customizedCount) .. " " .. (L["configCenterChanged"] or "changed")
		local changed = createText(card, FONT_MUTED, changedText, GREEN)
		changed:SetPoint("LEFT", meta, "RIGHT", 8, 0)
		changed:SetPoint("RIGHT", card, "RIGHT", -rightInset, 0)
		changed:SetHeight(16)
	end
	if not row then
		state.y = state.y - 10
	end
end

local function isPageMasterToggle(page, control)
	if not page or not control then
		return false
	end
	if control.isMainToggle == true or control.uiRole == "mainToggle" then
		return true
	end
	return page.mainToggleID ~= nil and page.mainToggleID == control.id
end

function lib._Internal.collectEnabledFeaturePages(app, limit)
	local result = {}
	local seen = {}
	for _, control in ipairs(app.controls or {}) do
		local page = app:GetPage(control.pageID)
		if (not app.IsControlVisible or app:IsControlVisible(control))
			and page
			and isPageMasterToggle(page, control)
			and app:GetControlValue(control) == true
			and not seen[page.id]
		then
			result[#result + 1] = page
			seen[page.id] = true
			if limit and #result >= limit then break end
		end
	end
	return result
end

function lib._Internal.collectCustomizedPages(app, limit)
	local result = {}
	local pages = app and type(app.GetPages) == "function" and app:GetPages() or (app and app.pages) or {}
	for _, page in ipairs(pages) do
		if lib.GetPageCustomizedCount(app, page) > 0 then
			result[#result + 1] = page
			if limit and #result >= limit then break end
		end
	end
	return result
end

function lib.IsNewTagActive(app, tagID)
	if app and type(app.IsNewTagActive) == "function" then
		return app:IsNewTagActive(tagID)
	end
	local resolver = app and app.opts and app.opts.isNewTag
	if type(resolver) ~= "function" or not tagID then
		return false
	end
	local ok, result = pcall(resolver, tagID)
	return ok and result == true
end

function lib.IsPageNew(app, page)
	if app and type(app.IsPageNew) == "function" then
		return app:IsPageNew(page)
	end
	return page and page.newTagID and lib.IsNewTagActive(app, page.newTagID) or false
end

function lib.IsControlNew(app, control)
	if app and type(app.IsControlNew) == "function" then
		return app:IsControlNew(control)
	end
	if control and control.newTagID and lib.IsNewTagActive(app, control.newTagID) then
		return true
	end
	return false
end

function lib.IsPageOrChildNew(app, page)
	if lib.IsPageNew(app, page) then
		return true
	end
	for _, control in ipairs(getVisiblePageControls(app, page)) do
		if lib.IsControlNew(app, control) then
			return true
		end
	end
	return false
end

function lib.IsCategoryNew(app, categoryID)
	if not (app and categoryID) then
		return false
	end
	for _, page in ipairs(app:GetPages(categoryID)) do
		if lib.IsPageOrChildNew(app, page) then
			return true
		end
	end
	return false
end

function lib._Internal.collectNewEntries(app, limit)
	local result = {}
	local seen = {}
	for _, control in ipairs(app.controls or {}) do
		if (not app.IsControlVisible or app:IsControlVisible(control)) and lib.IsControlNew(app, control) and not seen[control.id] then
			result[#result + 1] = {
				title = control.label or control.id,
				pageID = control.pageID,
			}
			seen[control.id] = true
			if limit and #result >= limit then return result end
		end
	end
	return result
end

function lib._Internal.addDashboardNewPanel(state, parent, entries, width, titleText)
	local app = state.app
	local L = getLocale(app)
	local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	panel:SetSize(width, 250)
	applyBackdrop(panel, CARD_BG, CARD_BORDER, "card")

	local title = createText(panel, FONT_HEADER, titleText or L["configCenterSettings"] or "Settings", TEXT.gold)
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
	title:SetPoint("RIGHT", panel, "RIGHT", -92, 0)
	title:SetHeight(20)
	local openNewButton = makeFlatButton(panel, (getLocale(state.app)["configCenterOpenButton"] or "Open"), 74, 24)
	openNewButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)
	openNewButton:SetScript("OnClick", function()
		lib.SetSearchQuery(state, "tag:new")
	end)

	for index, entry in ipairs(entries) do
		local row = CreateFrame("Button", nil, panel)
		row:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -46 - ((index - 1) * 38))
		row:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
		row:SetHeight(26)
		row:SetScript("OnClick", function()
			if entry.pageID then state:SetPage(entry.pageID) end
		end)

		local icon = row:CreateTexture(nil, "OVERLAY")
		icon:SetSize(15, 15)
		icon:SetPoint("LEFT", row, "LEFT", 0, 0)
		if icon.SetAtlas then
			local ok = pcall(icon.SetAtlas, icon, ASSET.statusNewAtlas, false)
			if not ok then icon:SetTexture("Interface\\Common\\ReputationStar") end
		else
			icon:SetTexture("Interface\\Common\\ReputationStar")
		end

		local label = createText(row, FONT_TEXT, entry.title or "", TEXT.main)
		label:SetPoint("LEFT", icon, "RIGHT", 10, 0)
		label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		label:SetHeight(22)
	end
	return panel
end

function lib.AddDashboardCards(state, cards)
	if type(cards) ~= "table" or #cards == 0 then
		return
	end
	for index = 1, #cards, 2 do
		local row = createGridRow(state, 108)
		for column = 1, 2 do
			local card = cards[index + column - 1]
			if card then
				local onClick = card.onClick
				if not onClick and card.pageID then
					onClick = function()
						state:SetPage(card.pageID)
					end
				end
				addDashboardCard(
					row,
					column,
					card.title,
					card.description or card.desc,
					card.icon or getAppIconTexture(state.app, card.iconKey or "advanced"),
					onClick
				)
			end
		end
	end
end

function lib._Internal.renderDashboard(state)
	local app = state.app
	local L = getLocale(app)
	local stats = app:GetStats()
	local dashboard = lib.GetDashboardOptions(app)
	local hero = type(dashboard.hero) == "table" and dashboard.hero or {}
	lib._Internal.addContentScrollbarRail(state)
	addDashboardHero(
		state,
		hero.title or L["configCenterTitle"] or (getAppTitle(app) .. " Settings"),
		hero.subtitle or hero.description or lib.DEFAULT_DASHBOARD_INTRO,
		hero.icon or (hero.iconKey and getAppIconTexture(app, hero.iconKey))
	)

	lib.AddDashboardCards(state, dashboard.cards)

	if dashboard.status == true or type(dashboard.status) == "table" then
		addDashboardStatusPanel(state, stats, dashboard.status == true and {} or dashboard.status)
	end

	if not dashboard._defined or (dashboard.features == nil and dashboard.newEntries == nil) then
		return
	end

	local featureConfig = type(dashboard.features) == "table" and dashboard.features or {}
	local enabledPages = {}
	local customizedPages = {}
	if dashboard.features ~= nil and dashboard.features ~= false then
		enabledPages = lib._Internal.collectEnabledFeaturePages(app, featureConfig.limit or 5)
		customizedPages = #enabledPages == 0 and lib._Internal.collectCustomizedPages(app, 5) or {}
	end
	local featurePages = #enabledPages > 0 and enabledPages or customizedPages
	local featureBadgeText = #enabledPages > 0 and (featureConfig.enabledBadge or L["configCenterEnabled"] or "")
		or (featureConfig.customizedBadge or "")
	local featureTitleText = #enabledPages > 0 and (featureConfig.enabledTitle or L["configCenterSettings"] or "Settings")
		or (featureConfig.customizedTitle or L["configCenterSettings"] or "Settings")
	local newConfig = type(dashboard.newEntries) == "table" and dashboard.newEntries or {}
	local newEntries = (dashboard.newEntries == nil or dashboard.newEntries == false) and {}
		or lib._Internal.collectNewEntries(app, newConfig.limit or 3)
	local hasFeaturePanel = dashboard.features ~= nil and dashboard.features ~= false
	local hasNewPanel = #newEntries > 0
	if not hasFeaturePanel and not hasNewPanel then
		return
	end
	local panelRow = createContentFrame(state, 250)
	local panelWidth = state.contentWidth or CONTENT_WIDTH
	local newPanelWidth = hasNewPanel and hasFeaturePanel and math.floor((panelWidth - GRID_GAP) * 0.48)
		or panelWidth
	local enabledWidth = hasNewPanel and (panelWidth - newPanelWidth - GRID_GAP) or panelWidth
	if hasNewPanel then
		lib._Internal.addDashboardNewPanel(state, panelRow, newEntries, newPanelWidth, newConfig.title)
	end
	if not hasFeaturePanel then
		return
	end
	local enabledPanel = CreateFrame("Frame", nil, panelRow, "BackdropTemplate")
	if hasNewPanel then
		enabledPanel:SetPoint("TOPRIGHT", panelRow, "TOPRIGHT", 0, 0)
	else
		enabledPanel:SetPoint("TOPLEFT", panelRow, "TOPLEFT", 0, 0)
	end
	enabledPanel:SetSize(enabledWidth, 250)
	applyBackdrop(enabledPanel, CARD_BG, CARD_BORDER, "card")
	local enabledTitle = createText(
		enabledPanel,
		FONT_HEADER,
		featureTitleText,
		TEXT.gold
	)
	enabledTitle:SetPoint("TOPLEFT", enabledPanel, "TOPLEFT", 14, -12)
	enabledTitle:SetPoint("RIGHT", enabledPanel, "RIGHT", -14, 0)
	enabledTitle:SetHeight(20)
	if #featurePages == 0 then
		local emptyText = createText(enabledPanel, FONT_MUTED, L["configCenterNoResults"] or "No settings found.", TEXT.muted)
		emptyText:SetPoint("TOPLEFT", enabledTitle, "BOTTOMLEFT", 0, -12)
		emptyText:SetPoint("BOTTOMRIGHT", enabledPanel, "BOTTOMRIGHT", -14, 14)
	else
		for index, page in ipairs(featurePages) do
			local mini = CreateFrame("Button", nil, enabledPanel, "BackdropTemplate")
			mini:SetPoint("TOPLEFT", enabledPanel, "TOPLEFT", 14, -38 - ((index - 1) * 39))
			mini:SetPoint("RIGHT", enabledPanel, "RIGHT", -14, 0)
			mini:SetHeight(34)
			applyBackdrop(mini, CARD_BG, CARD_BORDER, "card")
			applyHoverState(mini, CARD_BG, CARD_BG_HOVER, CARD_BORDER, CARD_BORDER_HOVER)
			mini:SetScript("OnClick", function() state:SetPage(page.id) end)
			local iconSource, iconIsAtlas = resolvePageIcon(app, page)
			local icon = createIcon(mini, iconSource, 20, iconIsAtlas)
			icon:SetPoint("LEFT", mini, "LEFT", 9, 0)
			local label = createText(mini, FONT_TEXT, page.title or page.id, TEXT.main)
			label:SetPoint("LEFT", icon, "RIGHT", 9, 0)
			label:SetPoint("RIGHT", mini, "RIGHT", -96, 0)
			label:SetHeight(18)
			local badgeColor = #enabledPages > 0 and GREEN or TEXT.gold
			local badge = addStatusChip(mini, featureBadgeText, badgeColor, 92)
			badge:SetPoint("RIGHT", mini, "RIGHT", -8, 0)
		end
	end
	state.y = state.y - 14
end

function lib._Internal.renderCategoryOverview(state, categoryID)
	local app = state.app
	local category = app.categoriesByID[categoryID]
	if not category then
		lib._Internal.renderDashboard(state)
		return
	end
	lib._Internal.addContentScrollbarRail(state)
	addSectionTitle(state, category.title or category.id, category.description)
	local pages = app:GetPages(categoryID)
	if #pages == 0 then
		addInfoCard(state, app.opts.title or app.id, { getLocale(app)["configCenterNoResults"] or "No settings found." }, 72)
		return
	end
	for index = 1, #pages, 2 do
		local row = createGridRow(state, PAGE_CARD_HEIGHT)
		addPageCard(state, pages[index], row, 1, 2)
		if pages[index + 1] then
			addPageCard(state, pages[index + 1], row, 2, 2)
		end
	end
end

function lib._Internal.collectPageGroups(app, page, mainToggle)
	local L = getLocale(app)
	local groups = {}
	local groupsByID = {}
	for _, group in ipairs(page.groups or {}) do
		local entry = {
			id = group.id,
			title = group.title or group.id,
			order = group.order,
			controls = {},
			collapsed = group.collapsed,
		}
		groups[#groups + 1] = entry
		groupsByID[group.id] = entry
	end
	for _, control in ipairs(page.controls or {}) do
		if control ~= mainToggle and (not app.IsControlVisible or app:IsControlVisible(control)) then
			local groupID = control.groupID or "settings"
			local entry = groupsByID[groupID]
			if not entry then
				entry = {
					id = groupID,
					title = control.groupTitle or (L["configCenterTitle"] or "Settings"),
					order = 100000,
					controls = {},
				}
				groups[#groups + 1] = entry
				groupsByID[groupID] = entry
			end
			entry.controls[#entry.controls + 1] = control
		end
	end
	for index = #groups, 1, -1 do
		if #groups[index].controls == 0 then
			table.remove(groups, index)
		end
	end
	table.sort(groups, function(a, b)
		local ao = tonumber(a.order) or 1000
		local bo = tonumber(b.order) or 1000
		if ao ~= bo then return ao < bo end
		return tostring(a.title) < tostring(b.title)
	end)
	local _ = app
	return groups
end

function lib._Internal.addPageLeftColumnShell(state)
	if state.sidePanelMode ~= "right" or not state.frame.ContentShell then
		return nil
	end
	local shell = trackFrame(state.fixedFrames, CreateFrame("Frame", nil, state.frame.ContentShell, "BackdropTemplate"))
	shell:SetPoint(
		"TOPLEFT",
		state.frame.ContentShell,
		"TOPLEFT",
		PAGE_LAYOUT.contentPad,
		-(PAGE_LAYOUT.contentPad + PAGE_LAYOUT.detailNavHeight + PAGE_LAYOUT.detailNavGap)
	)
	shell:SetPoint(
		"BOTTOMRIGHT",
		state.frame.ContentShell,
		"BOTTOMRIGHT",
		-(PAGE_LAYOUT.contentPad + (state.pageRightWidth or PAGE_RIGHT_WIDTH) + PAGE_GAP + PAGE_LAYOUT.scrollbarGutter),
		PAGE_LAYOUT.contentPad
	)
	applyBackdrop(shell, DETAIL_COLORS.columnBg, DETAIL_COLORS.columnBorder, "detailColumn")
	if state.frame.Scroll and shell.SetFrameLevel and state.frame.Scroll.GetFrameLevel then
		shell:SetFrameLevel(math.max(0, (state.frame.Scroll:GetFrameLevel() or 1) - 1))
	end
	return shell
end

function lib._Internal.addContentScrollbarRail(state)
	if not state.frame.ContentShell or not state.frame.Scroll then
		return nil
	end
	local rail = trackFrame(state.fixedFrames, CreateFrame("Frame", nil, state.frame.ContentShell, "BackdropTemplate"))
	rail:SetPoint("TOPLEFT", state.frame.Scroll, "TOPRIGHT", PAGE_LAYOUT.scrollbarOffset, 0)
	rail:SetPoint("BOTTOMLEFT", state.frame.Scroll, "BOTTOMRIGHT", PAGE_LAYOUT.scrollbarOffset, 0)
	rail:SetWidth(12)
	applyBackdrop(rail, { 0.038, 0.034, 0.026, 0.58 }, { 0.48, 0.38, 0.22, 0.54 }, "detailColumn")
	if state.frame.Scroll and rail.SetFrameLevel and state.frame.Scroll.GetFrameLevel then
		rail:SetFrameLevel(math.max(0, (state.frame.Scroll:GetFrameLevel() or 1) - 1))
	end
	state.frame.Scroll._LibSettingsDesignerScrollRail = rail
	return rail
end

function lib._Internal.addPageFixedHeader(state, category, pagePath)
	if state.sidePanelMode ~= "right" or not state.frame.ContentShell then
		return nil
	end
	local header = trackFrame(state.fixedFrames, CreateFrame("Frame", nil, state.frame.ContentShell, "BackdropTemplate"))
	header:SetPoint(
		"TOPLEFT",
		state.frame.ContentShell,
		"TOPLEFT",
		PAGE_LAYOUT.contentPad + PAGE_LAYOUT.columnInset,
		-(PAGE_LAYOUT.contentPad + 2)
	)
	header:SetSize(state.pageSectionWidth or state.pageLeftWidth or 420, PAGE_LAYOUT.detailNavHeight)
	if state.frame.Scroll and header.SetFrameLevel and state.frame.Scroll.GetFrameLevel then
		header:SetFrameLevel((state.frame.Scroll:GetFrameLevel() or 1) + 2)
	end

	local L = getLocale(state.app)
	local backLabel = lib.NormalizeTextValue(L["configCenterBack"], "Back")
	local backButton = makeFlatButton(header, backLabel, 104, 28)
	backButton:SetPoint("LEFT", header, "LEFT", 0, 0)
	setFrameBackdrop(backButton, { 0.120, 0.105, 0.075, 0.95 }, { 0.55, 0.42, 0.18, 0.82 })
	setTextColor(backButton.Text, TEXT.topbarGold)
	backButton:SetScript("OnEnter", function(self) setFrameBackdrop(self, CARD_BG_HOVER, CARD_BORDER_HOVER) end)
	backButton:SetScript("OnLeave", function(self)
		setFrameBackdrop(self, { 0.120, 0.105, 0.075, 0.95 }, { 0.55, 0.42, 0.18, 0.82 })
	end)
	backButton:SetScript("OnClick", function()
		if category and category.id then
			state:SetCategory(category.id, true)
		else
			state:SetDashboard(true)
		end
	end)

	local breadcrumb = createText(header, FONT_MUTED, pagePath, TEXT.subtle)
	breadcrumb:SetPoint("LEFT", backButton, "RIGHT", 12, 0)
	breadcrumb:SetPoint("RIGHT", header, "RIGHT", -4, 0)
	breadcrumb:SetHeight(20)
	breadcrumb.Text:SetJustifyV("MIDDLE")
	return header
end

function lib._Internal.resolvePagePanelOption(app, page, key, alternateKey, ...)
	local value
	if page then
		value = page[key]
		if value == nil and alternateKey then
			value = page[alternateKey]
		end
	end
	local opts = app and app.opts
	if value == nil and opts then
		value = opts[key]
		if value == nil and alternateKey then
			value = opts[alternateKey]
		end
	end
	if type(value) == "function" then
		local ok, result = pcall(value, app, page, ...)
		value = ok and result or nil
	end
	return value
end

function lib._Internal.shouldShowPageSubnav(state, page, groups)
	if not groups or #groups <= 1 then
		return false
	end
	local app = state and state.app
	local subnav = page and (page.subnav or page.subnavigation) or nil
	if subnav == nil and app and app.opts then
		subnav = app.opts.subnav or app.opts.subnavigation
	end
	if type(subnav) == "table" then
		local enabled = subnav.enabled
		if type(enabled) == "function" then
			local ok, result = pcall(enabled, app, page, groups, state)
			enabled = ok and result or nil
		end
		return enabled == true
	end
	if type(subnav) == "function" then
		local ok, result = pcall(subnav, app, page, groups, state)
		return ok and result == true
	end
	local visible = lib._Internal.resolvePagePanelOption(app, page, "showSubnav", "showSubnavigation", groups, state)
	if visible ~= nil then
		return visible == true
	end
	return false
end

function lib._Internal.addPageSubnav(state, panel, page, groups, y, availableHeight)
	if not lib._Internal.shouldShowPageSubnav(state, page, groups) then
		return y
	end

	local app = state.app
	local L = getLocale(app)
	local panelWidth = state.pageRightWidth or PAGE_RIGHT_WIDTH
	local divider = panel:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, y)
	divider:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
	divider:SetHeight(1)
	divider:SetColorTexture(DETAIL_COLORS.sectionBorder[1], DETAIL_COLORS.sectionBorder[2], DETAIL_COLORS.sectionBorder[3], 0.56)
	y = y - 14

	local title = createText(panel, FONT_MUTED, L["configCenterSections"] or "Sections", TEXT.gold)
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, y)
	title:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
	title:SetHeight(18)
	title.Text:SetJustifyV("MIDDLE")
	y = y - 26

	local rowHeight = 24
	local rowGap = 4
	local maxRows = math.max(0, math.floor(((availableHeight or 0) - 28) / (rowHeight + rowGap)))
	maxRows = math.min(#groups, maxRows > 0 and maxRows or #groups)
	for index = 1, maxRows do
		local group = groups[index]
		local button = trackFrame(state.fixedFrames, CreateFrame("Button", nil, panel, "BackdropTemplate"))
		button:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
		button:SetSize(panelWidth - 20, rowHeight)
		applyBackdrop(button, { 0.060, 0.054, 0.040, 0.78 }, { 0.28, 0.24, 0.16, 0.52 }, "card")
		button.Text = createText(button, FONT_MUTED, group.title or group.id, TEXT.muted)
		button.Text:SetPoint("LEFT", button, "LEFT", 9, 0)
		button.Text:SetPoint("RIGHT", button, "RIGHT", -9, 0)
		button.Text:SetHeight(rowHeight)
		button.Text.Text:SetJustifyV("MIDDLE")
		if button.Text.Text.SetMaxLines then
			button.Text.Text:SetMaxLines(1)
		end
		button:SetScript("OnEnter", function(self)
			setFrameBackdrop(self, CARD_BG_HOVER, CARD_BORDER_HOVER)
			setTextColor(self.Text and self.Text.Text, TEXT.main)
		end)
		button:SetScript("OnLeave", function(self)
			setFrameBackdrop(self, { 0.060, 0.054, 0.040, 0.78 }, { 0.28, 0.24, 0.16, 0.52 })
			setTextColor(self.Text and self.Text.Text, TEXT.muted)
		end)
		button:SetScript("OnClick", function()
			state:SetPage(page.id, group.id)
		end)
		y = y - (rowHeight + rowGap)
	end
	return y
end

function lib._Internal.addPageSidePanel(state, page, category, groups)
	local L = getLocale(state.app)
	local _ = category
	local aboutTextValue = lib.GetPageAboutText(state.app, page)
	local aboutHeight = lib.EstimateTextHeight(aboutTextValue, (state.pageRightWidth or PAGE_RIGHT_WIDTH) - 28, 13, 58)
	local showSubnav = lib._Internal.shouldShowPageSubnav(state, page, groups)
	local subnavRows = showSubnav and math.min(#groups, 8) or 0
	local subnavHeight = showSubnav and (46 + (subnavRows * 28)) or 0
	local shellHeight = state.frame.ContentShell and state.frame.ContentShell:GetHeight() or 0
	local maxPanelHeight = shellHeight > 0 and math.max(180, shellHeight - PAGE_LAYOUT.sidePanelTopOffset - PAGE_LAYOUT.contentPad) or 420
	local panelHeight = math.max(148, math.min(maxPanelHeight, aboutHeight + 52 + subnavHeight))
	local panel = trackFrame(state.fixedFrames, CreateFrame("Frame", nil, state.frame.ContentShell, "BackdropTemplate"))
	panel:SetPoint(
		"TOPRIGHT",
		state.frame.ContentShell,
		"TOPRIGHT",
		-PAGE_LAYOUT.contentPad,
		-PAGE_LAYOUT.sidePanelTopOffset
	)
	panel:SetSize(state.pageRightWidth or PAGE_RIGHT_WIDTH, panelHeight)
	applyBackdrop(panel, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")

	local aboutTitle = createText(panel, FONT_HEADER, L["configCenterAbout"] or "About", TEXT.gold)
	aboutTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -14)
	aboutTitle:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
	aboutTitle:SetHeight(20)

	local aboutText = createText(panel, FONT_MUTED, aboutTextValue, TEXT.muted)
	aboutText:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -8)
	aboutText:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
	aboutText:SetHeight(aboutHeight)
	lib._Internal.addPageSubnav(state, panel, page, groups, -(aboutHeight + 50), panelHeight - (aboutHeight + 50))
	return panel
end

function lib._Internal.addGroupSection(state, group, pagePath)
	local collapsed = state.collapsedGroups and state.collapsedGroups[group.id] == true
	local controlsHeight = 0
	local customizedCount = lib.GetGroupCustomizedCount(state.app, group)
	if not collapsed then
		for _, control in ipairs(group.controls) do
			controlsHeight = controlsHeight + getSettingRowHeight(control, state)
		end
	end
	local rowGap = collapsed and 0 or math.max(#group.controls - 1, 0) * 2
	local height = collapsed and 40 or (46 + controlsHeight + rowGap + 14)
	local section = createPageLeftFrame(state, height)
	applyBackdrop(section, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")
	createPixelBorder(section, DETAIL_COLORS.sectionBorder)

	local header = CreateFrame("Button", nil, section, "BackdropTemplate")
	header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
	header:SetHeight(40)
	applyBackdrop(header, DETAIL_COLORS.sectionHeaderBg, { 0, 0, 0, 0 }, "detailSection")
	header.Text = header:CreateFontString(nil, "OVERLAY", FONT_HEADER)
	header.Text:SetPoint("LEFT", header, "LEFT", 14, 0)
	header.Text:SetPoint("RIGHT", header, "RIGHT", customizedCount > 0 and -78 or -34, 0)
	header.Text:SetJustifyH("LEFT")
	header.Text:SetText(group.title or group.id)
	setTextColor(header.Text, TEXT.main)
	local width = math.max(30, (#tostring(customizedCount) * 9) + 18)
	local chip = addStatusChip(header, tostring(customizedCount), TEXT.gold, width)
	chip:SetPoint("RIGHT", header, "RIGHT", -36, 0)
	chip:SetShown(customizedCount > 0)
	state.groupCountHeaders = state.groupCountHeaders or {}
	state.groupCountHeaders[#state.groupCountHeaders + 1] = {
		header = header,
		chip = chip,
		group = group,
	}
	header.Chevron = createCollapseArrow(header, state.app, 12, collapsed)
	header.Chevron:SetPoint("RIGHT", header, "RIGHT", -14, 0)
	header:SetScript("OnClick", function()
		state.collapsedGroups[group.id] = not collapsed
		state:RenderContent()
	end)
	local headerLine = header:CreateTexture(nil, "OVERLAY")
	preparePixelTexture(headerLine)
	headerLine:SetColorTexture(ROW_SEPARATOR[1], ROW_SEPARATOR[2], ROW_SEPARATOR[3], 0.42)
	headerLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(getPixelSize(header))
	headerLine:SetShown(not collapsed)

	if not collapsed then
		local y = -46
		for index, control in ipairs(group.controls) do
			local rowHeight = getSettingRowHeight(control, state)
			local rowWidth = (state.pageSectionWidth or state.pageLeftWidth or 420) - 24
			local row = addSettingRow(state, control, pagePath, section, y, rowWidth)
			if index == #group.controls and row.Separator then
				row.Separator:Hide()
			end
			y = y - rowHeight - 2
		end
	end
	state.y = state.y - 12
	return section
end

function lib.GetInfoPageCommandText(entry)
	if type(entry) ~= "table" then
		return ""
	end
	local commands = type(entry.commands) == "table" and entry.commands or {}
	local commandText = table.concat(commands, ", ")
	if entry.usage and entry.usage ~= "" then
		commandText = commandText .. entry.usage
	end
	local text = ("|cff00ff98%s|r %s"):format(commandText, entry.desc or "")
	if entry.note and entry.note ~= "" then
		text = ("%s |cff909090- %s|r"):format(text, entry.note)
	end
	return text
end

function lib.IsInfoPageWrappedButton(block, entry)
	if type(entry) ~= "table" or (entry.type or "text") ~= "button" then
		return false
	end
	if entry.inline == true or entry.wrap == true then
		return true
	end
	local layout = type(block) == "table" and (block.buttonLayout or block.buttonsLayout or block.buttonFlow) or nil
	layout = tostring(layout or ""):lower()
	return layout == "wrap" or layout == "horizontal" or layout == "inline"
end

function lib.GetInfoPageButtonMetrics(block, entry)
	local buttonWidth = tonumber(entry and entry.width) or tonumber(block and block.buttonWidth) or 180
	local buttonHeight = tonumber(entry and entry.height) or tonumber(block and block.buttonHeight) or 28
	local gap = tonumber(entry and entry.gap) or tonumber(block and block.buttonGap) or 10
	local rowGap = tonumber(entry and entry.rowGap) or tonumber(block and block.buttonRowGap) or 10
	return buttonWidth, buttonHeight, gap, rowGap
end

function lib.GetInfoPageButtonAlign(block)
	local align = tostring((type(block) == "table" and (block.buttonAlign or block.buttonsAlign or block.alignButtons)) or "left"):lower()
	if align == "center" or align == "middle" then
		return "center"
	end
	if align == "right" or align == "end" then
		return "right"
	end
	return "left"
end

function lib.GetInfoPageWrappedButtonRunHeight(entries, startIndex, width, block)
	local contentWidth = math.max(120, (tonumber(width) or 0) - 28)
	local index = startIndex
	local rows = 0
	local currentWidth = 0
	local rowHeight = 0
	local totalHeight = 0
	while index <= #entries and lib.IsInfoPageWrappedButton(block, entries[index]) do
		local buttonWidth, buttonHeight, gap, rowGap = lib.GetInfoPageButtonMetrics(block, entries[index])
		local nextWidth = currentWidth > 0 and (currentWidth + gap + buttonWidth) or buttonWidth
		if currentWidth > 0 and nextWidth > contentWidth then
			totalHeight = totalHeight + rowHeight + (rows > 0 and rowGap or 0)
			rows = rows + 1
			currentWidth = buttonWidth
			rowHeight = buttonHeight
		else
			currentWidth = nextWidth
			rowHeight = math.max(rowHeight, buttonHeight)
		end
		index = index + 1
	end
	if currentWidth > 0 then
		totalHeight = totalHeight + rowHeight + (rows > 0 and select(4, lib.GetInfoPageButtonMetrics(block, entries[startIndex])) or 0)
	end
	return totalHeight + 12, index
end

function lib.GetInfoPageBlockHeight(block, width, state, path)
	if type(block) ~= "table" then
		return 0
	end
	local height = block.title and 42 or 16
	local entries = block.entries or block.blocks or {}
	local index = 1
	while index <= #entries do
		local entry = entries[index]
		if lib.IsInfoPageWrappedButton(block, entry) then
			local runHeight, nextIndex = lib.GetInfoPageWrappedButtonRunHeight(entries, index, width, block)
			height = height + runHeight
			index = nextIndex
		else
			height = height + lib.GetInfoPageEntryHeight(entry, width, state, tostring(path or "block") .. "." .. tostring(index), 0)
			index = index + 1
		end
	end
	return math.max(64, height + 12)
end

function lib.GetInfoPageExpandableKey(entry, path)
	if type(entry) ~= "table" then
		return tostring(path or "entry")
	end
	return tostring(entry.id or entry.key or entry.tag or entry.title or entry.label or path or "entry")
end

function lib.IsInfoPageEntryExpanded(state, entry, path)
	if type(entry) ~= "table" then
		return false
	end
	local key = lib.GetInfoPageExpandableKey(entry, path)
	local store = state and state.expandedInfoEntries
	if store and store[key] ~= nil then
		return store[key] == true
	end
	if entry.collapsed == true then
		return false
	end
	return entry.expanded == true or entry.defaultExpanded == true
end

function lib.GetInfoPageExpandableTitle(entry)
	if type(entry) ~= "table" then
		return ""
	end
	return entry.title or entry.label or entry.text or ""
end

function lib.GetInfoPageExpandableBody(entry)
	if type(entry) ~= "table" then
		return nil
	end
	if entry.body ~= nil then
		return entry.body
	end
	if entry.desc ~= nil then
		return entry.desc
	end
	if (entry.title or entry.label) and entry.text ~= nil then
		return entry.text
	end
	return nil
end

function lib.GetInfoPageEntryHeight(entry, width, state, path, depth)
	depth = tonumber(depth) or 0
	if type(entry) == "string" then
		return lib.EstimateTextHeight(entry, width, 15, 22) + 8
	end
	if type(entry) ~= "table" then
		return 0
	end
	local entryType = entry.type or "text"
	if entryType == "spacer" then
		return tonumber(entry.height) or 10
	end
	if entryType == "button" then
		return (tonumber(entry.height) or 28) + 12
	end
	if entryType == "command" then
		return lib.EstimateTextHeight(lib.GetInfoPageCommandText(entry), width, 15, 24) + 8
	end
	if entryType == "image" or entry.image or entry.texture then
		return (tonumber(entry.height) or 180) + 10
	end
	if entryType == "expandable" or entryType == "collapsible" or entryType == "collapse" then
		local height = tonumber(entry.headerHeight) or 34
		if lib.IsInfoPageEntryExpanded(state, entry, path) then
			local childWidth = math.max(120, width - 24)
			local text = lib.GetInfoPageExpandableBody(entry)
			if text and text ~= "" then
				height = height + lib.EstimateTextHeight(text, childWidth, 15, 22) + 8
			end
			for index, child in ipairs(entry.entries or entry.blocks or {}) do
				height = height + lib.GetInfoPageEntryHeight(child, childWidth, state, tostring(path or "entry") .. "." .. tostring(index), depth + 1)
			end
			height = height + 4
		end
		return height + 4
	end
	return lib.EstimateTextHeight(entry.text or entry.desc or entry.title or "", width, 15, 22) + 8
end

function lib.ToggleInfoPageEntry(state, entry, path)
	if not state or type(entry) ~= "table" then
		return
	end
	state.expandedInfoEntries = state.expandedInfoEntries or {}
	local key = lib.GetInfoPageExpandableKey(entry, path)
	state.expandedInfoEntries[key] = not lib.IsInfoPageEntryExpanded(state, entry, path)
	if state.SaveCurrentContentScroll then
		state:SaveCurrentContentScroll()
	end
	if state.GetContentScrollKey then
		state.restoreContentScrollKey = state:GetContentScrollKey()
		state.resetContentScroll = true
	end
	state:RenderContent()
end

function lib.RenderInfoPageEntry(state, section, entry, y, width, path, depth)
	depth = tonumber(depth) or 0
	local x = 14 + (depth * 18)
	local entryWidth = math.max(120, width - (depth * 18))
	if type(entry) == "string" then
		local textHeight = lib.EstimateTextHeight(entry, entryWidth, 15, 22)
		local text = createText(section, FONT_TEXT, entry, TEXT.muted)
		text:SetPoint("TOPLEFT", section, "TOPLEFT", x, y)
		text:SetPoint("RIGHT", section, "RIGHT", -14, 0)
		text:SetHeight(textHeight)
		return y - textHeight - 8
	end
	if type(entry) ~= "table" then
		return y
	end
	local entryType = entry.type or "text"
	if entryType == "spacer" then
		return y - (tonumber(entry.height) or 10)
	end
	if entryType == "button" then
		local L = getLocale(state.app)
		local button = makeFlatButton(section, entry.text or entry.label or (L["configCenterOkay"] or "OK"), tonumber(entry.width) or 190, tonumber(entry.height) or 28, entry.icon, entry.iconAtlas == true)
		button:SetPoint("TOPLEFT", section, "TOPLEFT", x, y)
		button:SetScript("OnClick", function()
			if type(entry.onClick) == "function" then
				entry.onClick(entry, state.app)
			end
		end)
		return y - 40
	end
	if entryType == "command" then
		local text = lib.GetInfoPageCommandText(entry)
		local textHeight = lib.EstimateTextHeight(text, entryWidth - 12, 15, 24)
		local line = createText(section, FONT_TEXT, text, TEXT.main)
		line:SetPoint("TOPLEFT", section, "TOPLEFT", x + 12, y)
		line:SetPoint("RIGHT", section, "RIGHT", -14, 0)
		line:SetHeight(textHeight)
		return y - textHeight - 8
	end
	if entryType == "image" or entry.image or entry.texture then
		local imageWidth = math.min(entryWidth, tonumber(entry.width) or entryWidth)
		local imageHeight = tonumber(entry.height) or math.floor(imageWidth * 0.56)
		local image = section:CreateTexture(nil, "ARTWORK")
		image:SetTexture(entry.image or entry.texture)
		image:SetPoint("TOPLEFT", section, "TOPLEFT", x, y)
		image:SetSize(imageWidth, imageHeight)
		return y - imageHeight - 10
	end
	if entryType == "expandable" or entryType == "collapsible" or entryType == "collapse" then
		local expanded = lib.IsInfoPageEntryExpanded(state, entry, path)
		local headerHeight = tonumber(entry.headerHeight) or 34
		local header = CreateFrame("Button", nil, section, "BackdropTemplate")
		header:SetPoint("TOPLEFT", section, "TOPLEFT", x, y)
		header:SetPoint("RIGHT", section, "RIGHT", -14, 0)
		header:SetHeight(headerHeight)
		applyBackdrop(header, entry.headerBg or DETAIL_COLORS.sectionHeaderBg, { 0, 0, 0, 0 }, "detailSection")
		header.Chevron = createCollapseArrow(header, state.app, 12, not expanded)
		header.Chevron:SetPoint("LEFT", header, "LEFT", 10, 0)
		header.Text = header:CreateFontString(nil, "OVERLAY", FONT_HEADER)
		header.Text:SetPoint("LEFT", header.Chevron, "RIGHT", 10, 0)
		local rightInset = (entry.rightText or entry.date) and -160 or -14
		header.Text:SetPoint("RIGHT", header, "RIGHT", rightInset, 0)
		header.Text:SetJustifyH("LEFT")
		header.Text:SetText(lib.GetInfoPageExpandableTitle(entry))
		setTextColor(header.Text, entry.titleColor or TEXT.gold)
		local rightTextValue = entry.rightText or entry.date
		if rightTextValue then
			header.RightText = header:CreateFontString(nil, "OVERLAY", FONT_TEXT)
			header.RightText:SetPoint("RIGHT", header, "RIGHT", -12, 0)
			header.RightText:SetWidth(140)
			header.RightText:SetJustifyH("RIGHT")
			header.RightText:SetText(tostring(rightTextValue))
			setTextColor(header.RightText, entry.rightColor or TEXT.gold)
		end
		header:SetScript("OnEnter", function(button)
			setFrameBackdrop(button, { 0.16, 0.12, 0.065, 0.58 }, { 0, 0, 0, 0 })
		end)
		header:SetScript("OnLeave", function(button)
			setFrameBackdrop(button, entry.headerBg or DETAIL_COLORS.sectionHeaderBg, { 0, 0, 0, 0 })
		end)
		header:SetScript("OnClick", function()
			lib.ToggleInfoPageEntry(state, entry, path)
		end)
		y = y - headerHeight - 4
		if expanded then
			local childWidth = math.max(120, entryWidth - 24)
			local body = lib.GetInfoPageExpandableBody(entry)
			if body and body ~= "" then
				local textHeight = lib.EstimateTextHeight(body, childWidth, 15, 22)
				local text = createText(section, entry.font or FONT_TEXT, body, entry.color or TEXT.muted)
				text:SetPoint("TOPLEFT", section, "TOPLEFT", x + 24, y)
				text:SetPoint("RIGHT", section, "RIGHT", -14, 0)
				text:SetHeight(textHeight)
				y = y - textHeight - 8
			end
			for index, child in ipairs(entry.entries or entry.blocks or {}) do
				y = lib.RenderInfoPageEntry(state, section, child, y, childWidth, tostring(path or "entry") .. "." .. tostring(index), depth + 1)
			end
			y = y - 4
		end
		return y
	end
	local textValue = entry.text or entry.desc or entry.title or ""
	local text = createText(section, entry.font or FONT_TEXT, textValue, entry.color or TEXT.muted)
	local textHeight = lib.EstimateTextHeight(textValue, entryWidth, 15, 22)
	text:SetPoint("TOPLEFT", section, "TOPLEFT", x, y)
	text:SetPoint("RIGHT", section, "RIGHT", -14, 0)
	text:SetHeight(textHeight)
	return y - textHeight - 8
end

function lib.RenderInfoPageWrappedButtonRun(state, section, entries, startIndex, y, width, block)
	local contentWidth = math.max(120, (tonumber(width) or 0) - 28)
	local x = 14
	local index = startIndex
	local rows = {}
	local currentRow
	while index <= #entries and lib.IsInfoPageWrappedButton(block, entries[index]) do
		local entry = entries[index]
		local buttonWidth, buttonHeight, gap, entryRowGap = lib.GetInfoPageButtonMetrics(block, entry)
		local projectedWidth = currentRow and (currentRow.width + gap + buttonWidth) or buttonWidth
		if currentRow and projectedWidth > contentWidth then
			rows[#rows + 1] = currentRow
			currentRow = nil
		end
		if not currentRow then
			currentRow = { entries = {}, width = 0, height = 0, rowGap = entryRowGap }
		end
		currentRow.entries[#currentRow.entries + 1] = {
			entry = entry,
			width = buttonWidth,
			height = buttonHeight,
			gap = #currentRow.entries > 0 and gap or 0,
		}
		currentRow.width = currentRow.width > 0 and (currentRow.width + gap + buttonWidth) or buttonWidth
		currentRow.height = math.max(currentRow.height, buttonHeight)
		currentRow.rowGap = math.max(currentRow.rowGap or 0, entryRowGap)
		index = index + 1
	end
	if currentRow then
		rows[#rows + 1] = currentRow
	end
	local align = lib.GetInfoPageButtonAlign(block)
	for rowIndex, row in ipairs(rows) do
		local rowOffset = 0
		if align == "center" then
			rowOffset = math.max(0, (contentWidth - row.width) / 2)
		elseif align == "right" then
			rowOffset = math.max(0, contentWidth - row.width)
		end
		local currentX = rowOffset
		for _, item in ipairs(row.entries) do
			currentX = currentX + item.gap
			local entry = item.entry
			local L = getLocale(state.app)
			local button = makeFlatButton(section, entry.text or entry.label or (L["configCenterOkay"] or "OK"), item.width, item.height, entry.icon, entry.iconAtlas == true)
			button:SetPoint("TOPLEFT", section, "TOPLEFT", x + currentX, y)
			button:SetScript("OnClick", function()
				if type(entry.onClick) == "function" then
					entry.onClick(entry, state.app)
				end
			end)
			currentX = currentX + item.width
		end
		y = y - row.height - (rowIndex < #rows and row.rowGap or 12)
	end
	return y, index
end

function lib.RenderInfoPageBlock(state, block)
	if type(block) ~= "table" then
		return nil
	end
	local width = state.pageSectionWidth or state.pageLeftWidth or 420
	local sectionWidth = math.max(240, width - 28)
	local blockIndex = state.infoPageBlockIndex or 0
	state.infoPageBlockIndex = blockIndex + 1
	local blockPath = tostring(state.selectedPageID or "page") .. "." .. tostring(state.infoPageBlockIndex)
	local height = lib.GetInfoPageBlockHeight(block, sectionWidth, state, blockPath)
	local section = createPageLeftFrame(state, height)
	applyBackdrop(section, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")
	createPixelBorder(section, DETAIL_COLORS.sectionBorder)

	local y = -14
	if block.title then
		local title = createText(section, FONT_HEADER, block.title, TEXT.gold)
		title:SetPoint("TOPLEFT", section, "TOPLEFT", 14, y)
		title:SetPoint("RIGHT", section, "RIGHT", -14, 0)
		title:SetHeight(22)
		y = y - 32
	end

	local entries = block.entries or block.blocks or {}
	local index = 1
	while index <= #entries do
		local entry = entries[index]
		if lib.IsInfoPageWrappedButton(block, entry) then
			y, index = lib.RenderInfoPageWrappedButtonRun(state, section, entries, index, y, sectionWidth, block)
		else
			y = lib.RenderInfoPageEntry(state, section, entry, y, sectionWidth, blockPath .. "." .. tostring(index), 0)
			index = index + 1
		end
	end
	state.y = state.y - 12
	return section
end

function lib.RenderInfoPage(state, page, pagePath)
	local app = state.app
	local category = app.categoriesByID[page.category or ""]
	if state.sidePanelMode == "right" then
		lib._Internal.addPageLeftColumnShell(state)
		lib._Internal.addPageFixedHeader(state, category, pagePath)
		lib._Internal.addContentScrollbarRail(state)
		lib._Internal.addPageSidePanel(state, page, category, nil)
	end

	local header = createPageLeftFrame(state, 74)
	local iconSource, iconIsAtlas = resolvePageIcon(app, page)
	local icon = createIconPlate(header, iconSource, 54, iconIsAtlas)
	icon:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -10)
	local title = createText(header, FONT_TITLE, page.title or page.id, TEXT.main)
	title:SetPoint("LEFT", icon, "RIGHT", 16, 0)
	title:SetPoint("RIGHT", header, "RIGHT", -6, 0)
	title:SetHeight(30)
	state.y = state.y - 8

	local blocks = page.content or page.blocks or page.infoBlocks
	if type(blocks) ~= "table" or #blocks == 0 then
		local empty = createPageLeftFrame(state, 72)
		applyBackdrop(empty, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")
		local emptyText = createText(empty, FONT_MUTED, getLocale(app)["configCenterNoResults"] or "No settings found.", TEXT.muted)
		emptyText:SetPoint("TOPLEFT", empty, "TOPLEFT", 14, -14)
		emptyText:SetPoint("BOTTOMRIGHT", empty, "BOTTOMRIGHT", -14, 14)
	else
		state.infoPageBlockIndex = 0
		for _, block in ipairs(blocks) do
			lib.RenderInfoPageBlock(state, block)
		end
	end
end

function lib.RenderCustomPage(state, page, pagePath)
	local app = state.app
	local category = app.categoriesByID[page.category or ""]
	if state.sidePanelMode == "right" then
		lib._Internal.addPageLeftColumnShell(state)
		lib._Internal.addPageFixedHeader(state, category, pagePath)
		lib._Internal.addContentScrollbarRail(state)
		lib._Internal.addPageSidePanel(state, page, category, nil)
	end

	local header = createPageLeftFrame(state, 74)
	local iconSource, iconIsAtlas = resolvePageIcon(app, page)
	local icon = createIconPlate(header, iconSource, 54, iconIsAtlas)
	icon:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -10)
	local title = createText(header, FONT_TITLE, page.title or page.id, TEXT.main)
	title:SetPoint("LEFT", icon, "RIGHT", 16, 0)
	title:SetPoint("RIGHT", header, "RIGHT", -6, 0)
	title:SetHeight(30)
	state.y = state.y - 8

	local height
	if type(page.getHeight) == "function" then
		local ok, result = pcall(page.getHeight, app, page, state)
		height = ok and tonumber(result) or nil
	end
	height = height or tonumber(page.height or page.pageHeight) or math.max(260, (state.frame.Scroll and state.frame.Scroll:GetHeight() or 520) - 96)
	local section = createPageLeftFrame(state, height)
	applyBackdrop(section, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")
	createPixelBorder(section, DETAIL_COLORS.sectionBorder)
	lib.RenderCustomOwner(state, section, page, "page:" .. tostring(page.id))
end

function lib._Internal.renderPage(state, pageID)
	local app = state.app
	local page = app:GetPage(pageID)
	if not page then
		lib._Internal.renderDashboard(state)
		return
	end
	local category = app.categoriesByID[page.category or ""]
	local pagePath = getPagePath(app, page)
	if page.layout == "custom" or page.type == "custom" or type(page.render) == "function" then
		lib.RenderCustomPage(state, page, pagePath)
		return
	end
	if page.layout == "info" or page.type == "info" or page.content or page.infoBlocks then
		lib.RenderInfoPage(state, page, pagePath)
		return
	end

	local groups = lib._Internal.collectPageGroups(app, page, nil)
	if state.sidePanelMode == "right" then
		lib._Internal.addPageLeftColumnShell(state)
		lib._Internal.addPageFixedHeader(state, category, pagePath)
		lib._Internal.addContentScrollbarRail(state)
		lib._Internal.addPageSidePanel(state, page, category, groups)
	end

	local header = createPageLeftFrame(state, 74)
	local iconSource, iconIsAtlas = resolvePageIcon(app, page)
	local icon = createIconPlate(header, iconSource, 54, iconIsAtlas)
	icon:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -10)
	local title = createText(header, FONT_TITLE, page.title or page.id, TEXT.main)
	title:SetPoint("LEFT", icon, "RIGHT", 16, 0)
	title:SetPoint("RIGHT", header, "RIGHT", -6, 0)
	title:SetHeight(30)
	state.y = state.y - 8

	local groupsStartY = state.y
	if #groups == 0 then
		local empty = createPageLeftFrame(state, 72)
		applyBackdrop(empty, DETAIL_SECTION_BG, DETAIL_COLORS.sectionBorder, "detailSection")
		local emptyLabel = getLocale(app)["configCenterNoResults"] or "No settings found."
		local emptyText = createText(empty, FONT_MUTED, emptyLabel, TEXT.muted)
		emptyText:SetPoint("TOPLEFT", empty, "TOPLEFT", 14, -14)
		emptyText:SetPoint("BOTTOMRIGHT", empty, "BOTTOMRIGHT", -14, 14)
	else
		for _, group in ipairs(groups) do
			lib._Internal.addGroupSection(state, group, pagePath)
		end
	end
	if state.sidePanelMode == "right" then
		state.y = math.min(state.y, groupsStartY - 230)
	end
end

function lib._Internal.renderSearch(state, query)
	local app = state.app
	local L = getLocale(app)
	local results = app:GetSearchResults(query, 80)
	lib._Internal.addContentScrollbarRail(state)
	addSectionTitle(state, (L["configCenterSearchPlaceholder"] or "Search settings") .. ": " .. query)
	if #results == 0 then
		addInfoCard(state, L["configCenterNoResults"] or "No settings found.", {}, 64)
		return
	end
	for _, control in ipairs(results) do
		if control._pageResult then
			local page = app:GetPage(control.pageID)
			local card = createContentFrame(state, 102)
			styleRaisedTile(card, true)
			card:SetScript("OnMouseUp", function()
				state:SetPage(control.pageID, control.focusID)
			end)

			local iconSource, iconIsAtlas = resolvePageIcon(app, page)
			local icon = createIconPlate(card, iconSource, PAGE_CARD_ICON_SIZE, iconIsAtlas)
			icon:SetPoint("LEFT", card, "LEFT", 18, 0)

			local badge = lib.CreateNewBadge(card)
			badge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -100, -16)

			local title = createText(card, FONT_HEADER, control.label or (page and page.title) or control.id, TEXT.main)
			title:SetPoint("TOPLEFT", card, "TOPLEFT", 76, -18)
			title:SetPoint("RIGHT", card, "RIGHT", -182, 0)
			title:SetHeight(20)

			local desc = createText(card, FONT_MUTED, control.description or "", TEXT.muted)
			desc:SetPoint("TOPLEFT", card, "TOPLEFT", 76, -42)
			desc:SetPoint("RIGHT", card, "RIGHT", -104, 0)
			desc:SetHeight(28)
			if desc.Text.SetMaxLines then
				desc.Text:SetMaxLines(2)
			end

			local path = createText(card, FONT_MUTED, getPagePath(app, page), TEXT.subtle)
			path:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 76, 10)
			path:SetPoint("RIGHT", card, "RIGHT", -104, 0)
			path:SetHeight(16)
			path.Text:SetJustifyV("MIDDLE")

			local openButton = makeFlatButton(card, (L["configCenterOpenButton"] or "Open"), 74, 24)
			openButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 8)
			openButton:SetScript("OnClick", function()
				state:SetPage(control.pageID, control.focusID)
			end)
			state.y = state.y - 8
		else
			local rowHeight = getSettingRowHeight(control, state)
			local card = createContentFrame(state, rowHeight + 52)
			applyBackdrop(card, CARD_BG, CARD_BORDER, "card")
			createPixelBorder(card, CARD_BORDER)

			local rowWidth = (state.contentWidth or CONTENT_WIDTH) - 24
			local row = addSettingRow(state, control, nil, card, -10, rowWidth)
			if row.Separator then
				row.Separator:Hide()
			end

			local path = createText(card, FONT_MUTED, getControlPath(app, control), TEXT.subtle)
			path:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 10)
			path:SetPoint("RIGHT", card, "RIGHT", -104, 0)
			path:SetHeight(16)
			path.Text:SetJustifyV("MIDDLE")

			local openButton = makeFlatButton(card, (L["configCenterOpenButton"] or "Open"), 74, 24)
			openButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 8)
			openButton:SetScript("OnClick", function()
				state:SetPage(control.pageID, control.id)
			end)
			state.y = state.y - 8
		end
	end
end

local StateMixin = {}

function StateMixin:RenderContent()
	updateContentMetrics(self)
	clearContent(self)
	clearFixedContent(self)
	self.groupCountHeaders = {}
	local query = self.frame.SearchBox:GetText() or ""
	if query ~= "" then
		self.resetSearchScroll = self.lastSearchQuery ~= query
		self.lastSearchQuery = query
		lib._Internal.renderSearch(self, query)
	elseif self.view == "category" then
		self.lastSearchQuery = nil
		lib._Internal.renderCategoryOverview(self, self.selectedCategoryID)
	elseif self.view == "page" then
		self.lastSearchQuery = nil
		lib._Internal.renderPage(self, self.selectedPageID)
	else
		self.lastSearchQuery = nil
		lib._Internal.renderDashboard(self)
	end
	setScrollHeight(self)
	if self.resetContentScroll then
		if not self.pendingFocusControlID then
			if self.restoreContentScrollKey and self.scrollPositions then
				lib.QueueContentScroll(self, self.scrollPositions[self.restoreContentScrollKey] or 0)
			else
				lib.SetContentScrollTop(self)
			end
		end
		self.resetContentScroll = nil
		self.restoreContentScrollKey = nil
	end
	if self.resetSearchScroll and self.frame and self.frame.Scroll then
		lib.SetContentScrollTop(self)
		self.resetSearchScroll = nil
	end
	lib.FocusPendingControl(self)
	self.pendingCustomFocusID = nil
	self:RefreshSidebarNewBadges()
	self:RefreshSidebarSelection()
end

function StateMixin:RequestLayout()
	self.resetContentScroll = true
	self:RenderContent()
end

function StateMixin:RefreshSidebarNewBadges()
	for _, row in pairs(self.sidebarRows or {}) do
		if row.categoryID and row.Text then
			local isNewCategory = lib.IsCategoryNew(self.app, row.categoryID)
			if isNewCategory and not row.NewBadge then
				row.NewBadge = lib.CreateNewBadge(row)
				row.NewBadge:SetPoint("RIGHT", row, "RIGHT", -10, 0)
			end
			if row.NewBadge and row.NewBadge.SetShown then
				row.NewBadge:SetShown(isNewCategory)
			end
			row.Text:ClearAllPoints()
			row.Text:SetPoint("LEFT", row.Icon, "RIGHT", 10, 0)
			row.Text:SetPoint("RIGHT", row, "RIGHT", isNewCategory and -64 or -12, 0)
		end
	end
end

function StateMixin:RefreshSidebarSelection()
	for _, row in pairs(self.sidebarRows or {}) do
		local selected = false
		if row.view == "dashboard" then
			selected = self.view == "dashboard"
		elseif row.categoryID then
			selected = self.selectedCategoryID == row.categoryID and self.view ~= "dashboard"
		end
		row.selected = selected
		setFrameBackdrop(row, selected and SELECTED_BG or SIDEBAR_BG, selected and CARD_BORDER_HOVER or { 0.42, 0.34, 0.20, 0.16 })
		setTextColor(row.Text, selected and TEXT.gold or TEXT.main)
		if row.Accent then row.Accent:SetShown(selected) end
	end
end

function StateMixin:RenderSidebar()
	clearSidebar(self)
	self.sidebarRows = {}
	local frame = self.frame
	local L = getLocale(self.app)

	local dashboard = createSidebarFrame(self, 44)
	applyBackdrop(dashboard, SIDEBAR_BG, { 0.42, 0.34, 0.20, 0.16 }, "sidebar")
	dashboard.Accent = dashboard:CreateTexture(nil, "OVERLAY")
	dashboard.Accent:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.85)
	dashboard.Accent:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 0, -6)
	dashboard.Accent:SetPoint("BOTTOMLEFT", dashboard, "BOTTOMLEFT", 0, 6)
	dashboard.Accent:SetWidth(2)
	dashboard.Icon = createIcon(dashboard, getAppIconTexture(self.app, "dashboard"), 22, false)
	dashboard.Icon:SetPoint("LEFT", dashboard, "LEFT", 12, 0)
	dashboard.Text = dashboard:CreateFontString(nil, "OVERLAY", FONT_TEXT)
	dashboard.Text:SetPoint("LEFT", dashboard.Icon, "RIGHT", 10, 0)
	dashboard.Text:SetPoint("RIGHT", dashboard, "RIGHT", -12, 0)
	dashboard.Text:SetJustifyH("LEFT")
	dashboard.Text:SetText((self.app.opts and self.app.opts.dashboardTitle) or L["configCenterDashboard"] or "Dashboard")
	dashboard.view = "dashboard"
	dashboard:SetScript("OnEnter", function(row)
		if not row.selected then
			setFrameBackdrop(row, { 0.105, 0.082, 0.045, 0.72 }, { 0.85, 0.62, 0.25, 0.52 })
		end
	end)
	dashboard:SetScript("OnLeave", function(row)
		setFrameBackdrop(
			row,
			row.selected and SELECTED_BG or SIDEBAR_BG,
			row.selected and CARD_BORDER_HOVER or { 0.42, 0.34, 0.20, 0.16 }
		)
	end)
	dashboard:SetScript("OnClick", function()
		frame.SearchBox:SetText("")
		self:SetDashboard()
	end)
	self.sidebarRows.dashboard = dashboard

	for _, category in ipairs(self.app:GetCategories()) do
		if category.hidden ~= true and category.visible ~= false then
			local isNewCategory = lib.IsCategoryNew(self.app, category.id)
			local row = createSidebarFrame(self, 44)
			applyBackdrop(row, SIDEBAR_BG, { 0.42, 0.34, 0.20, 0.16 }, "sidebar")
			row.Accent = row:CreateTexture(nil, "OVERLAY")
			row.Accent:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.85)
			row.Accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -6)
			row.Accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 6)
			row.Accent:SetWidth(2)
			local iconSource, iconIsAtlas = resolveCategoryIcon(self.app, category)
			row.Icon = createIcon(row, iconSource, 22, iconIsAtlas)
			row.Icon:SetPoint("LEFT", row, "LEFT", 12, 0)
			row.Text = row:CreateFontString(nil, "OVERLAY", FONT_TEXT)
			row.Text:SetPoint("LEFT", row.Icon, "RIGHT", 10, 0)
			row.Text:SetPoint("RIGHT", row, "RIGHT", isNewCategory and -64 or -12, 0)
			row.Text:SetJustifyH("LEFT")
			row.Text:SetText(category.title or category.id)
			if isNewCategory then
				row.NewBadge = lib.CreateNewBadge(row)
				row.NewBadge:SetPoint("RIGHT", row, "RIGHT", -10, 0)
			end
			row.categoryID = category.id
			row:SetScript("OnEnter", function(sidebarRow)
				if not sidebarRow.selected then
					setFrameBackdrop(sidebarRow, { 0.105, 0.082, 0.045, 0.72 }, { 0.85, 0.62, 0.25, 0.52 })
				end
			end)
			row:SetScript("OnLeave", function(sidebarRow)
				setFrameBackdrop(
					sidebarRow,
					sidebarRow.selected and SELECTED_BG or SIDEBAR_BG,
					sidebarRow.selected and CARD_BORDER_HOVER or { 0.42, 0.34, 0.20, 0.16 }
				)
			end)
			row:SetScript("OnClick", function()
				frame.SearchBox:SetText("")
				self:SetCategory(category.id)
			end)
			self.sidebarRows[category.id] = row
		end
	end
	frame.Sidebar:SetHeight(math.max(1, math.abs(self.sidebarY) + 8))
	updateScrollFrameVisibility(frame.SidebarScroll)
	self:RefreshSidebarSelection()
end

function StateMixin:GetContentScrollKey()
	if self.view == "dashboard" then
		return "dashboard"
	end
	if self.view == "category" and self.selectedCategoryID then
		return "category:" .. tostring(self.selectedCategoryID)
	end
	if self.view == "page" and self.selectedPageID then
		return "page:" .. tostring(self.selectedPageID)
	end
	return nil
end

function StateMixin:SaveCurrentContentScroll()
	if self.frame and self.frame.SearchBox and self.frame.SearchBox:GetText() ~= "" then
		return
	end
	local key = self:GetContentScrollKey()
	if not key then
		return
	end
	self.scrollPositions = self.scrollPositions or {}
	self.scrollPositions[key] = lib.GetContentScroll(self)
end

function StateMixin:SetDashboard(restoreScroll)
	self.resetContentScroll = true
	self.restoreContentScrollKey = restoreScroll and "dashboard" or nil
	self.view = "dashboard"
	self.selectedPageID = nil
	self:RenderContent()
end

function StateMixin:SetCategory(categoryID, restoreScroll)
	self.resetContentScroll = true
	self.restoreContentScrollKey = restoreScroll and ("category:" .. tostring(categoryID)) or nil
	self.view = "category"
	self.selectedCategoryID = categoryID
	self.selectedPageID = nil
	self:RenderContent()
end

function lib.FindFirstControlInGroup(page, groupID)
	if not page or not groupID then
		return nil
	end
	for _, control in ipairs(page.controls or {}) do
		if control.groupID == groupID then
			return control
		end
	end
	return nil
end

function StateMixin:ResolveFocusControlID(page, focusID)
	if not page or not focusID then
		return nil, nil
	end
	local focusKey = tostring(focusID)
	local control = self.app.controlsByID and self.app.controlsByID[focusKey]
	if control and control.pageID == page.id then
		return control.id, control.groupID
	end
	for _, entry in ipairs(page.controls or {}) do
		if entry.id == focusKey or entry.key == focusKey then
			return entry.id, entry.groupID
		end
	end
	local group = page.groupsByID and page.groupsByID[focusKey]
	if not group then
		local normalizedFocus = normalizeLookupKey(focusKey)
		for _, entry in ipairs(page.groups or {}) do
			local normalizedGroup = normalizeLookupKey(entry.id or entry.title)
			if normalizedGroup == normalizedFocus or normalizedGroup:find(normalizedFocus, 1, true) == 1 then
				group = entry
				break
			end
		end
	end
	if group and group.id then
		control = lib.FindFirstControlInGroup(page, group.id)
		return control and control.id or nil, group.id
	end
	return nil, nil
end

function StateMixin:SetPage(pageID, focusControlID)
	local page = self.app:GetPage(pageID)
	if not page or (self.app.IsPageVisible and not self.app:IsPageVisible(page)) then
		local categoryID = page and page.category or self.selectedCategoryID
		if categoryID then
			self:SetCategory(categoryID)
		else
			self:SetDashboard()
		end
		return
	end
	self:SaveCurrentContentScroll()
	self.resetContentScroll = true
	self.view = "page"
	self.selectedPageID = pageID
	if page then
		self.selectedCategoryID = page.category
	end
	if focusControlID then
		local resolvedControlID, groupID = self:ResolveFocusControlID(page, focusControlID)
		if groupID and self.collapsedGroups then
			self.collapsedGroups[groupID] = nil
		end
		if resolvedControlID then
			self.pendingFocusControlID = resolvedControlID
		else
			self.pendingCustomFocusID = focusControlID
		end
	end
	if self.frame.SearchBox:GetText() ~= "" then
		self.suppressSearchRender = true
		self.frame.SearchBox:SetText("")
		self.suppressSearchRender = nil
	end
	if type(page.onOpen) == "function" then
		pcall(page.onOpen, page, self.app, self)
	end
	self:RenderContent()
end

function StateMixin:SetDensity(density)
	density = density == "compact" and "compact" or "comfortable"
	if self.density == density then
		return
	end
	self:SaveCurrentContentScroll()
	self.density = density
	if self.app and self.app.opts and type(self.app.opts.setDensity) == "function" then
		pcall(self.app.opts.setDensity, density, self.app)
	end
	lib._densityByApp = lib._densityByApp or {}
	lib._densityByApp[self.app.id or self.app.title or "default"] = density
	lib.RefreshTopbar(self.frame, self)
	self.restoreContentScrollKey = self:GetContentScrollKey()
	self.resetContentScroll = true
	self:RenderContent()
end

function lib.GetStoredFrameSize(app)
	if app and app.opts and type(app.opts.getSize) == "function" then
		local ok, width, height = pcall(app.opts.getSize)
		if ok then
			width = tonumber(width)
			height = tonumber(height)
			if width and height then
				return width, height
			end
		end
	end
	local savedSize = lib._sizeByApp and lib._sizeByApp[app.id or app.title or "default"]
	return savedSize and tonumber(savedSize.width), savedSize and tonumber(savedSize.height)
end

function lib.SaveFrameSize(app, width, height)
	width = math.max(PAGE_LAYOUT.windowMinWidth, tonumber(width) or WINDOW_WIDTH)
	height = math.max(PAGE_LAYOUT.windowMinHeight, tonumber(height) or WINDOW_HEIGHT)
	lib._sizeByApp = lib._sizeByApp or {}
	lib._sizeByApp[app.id or app.title or "default"] = { width = width, height = height }
	if app and app.opts and type(app.opts.setSize) == "function" then
		pcall(app.opts.setSize, width, height)
	end
end

function lib.IsFrameLocked(app)
	if app and app.opts and type(app.opts.getLocked) == "function" then
		local ok, locked = pcall(app.opts.getLocked)
		if ok then
			return locked == true
		end
	end
	local saved = lib._lockedByApp and lib._lockedByApp[app.id or app.title or "default"]
	return saved == true
end

function lib.SaveFrameLocked(app, locked)
	locked = locked == true
	lib._lockedByApp = lib._lockedByApp or {}
	lib._lockedByApp[app.id or app.title or "default"] = locked
	if app and app.opts and type(app.opts.setLocked) == "function" then
		pcall(app.opts.setLocked, locked)
	end
end

function lib.ApplyFrameLocked(frame, app)
	if not frame then return end
	local L = getLocale(app)
	local locked = lib.IsFrameLocked(app)
	frame._eqolLocked = locked
	if frame.SetMovable then
		frame:SetMovable(not locked)
	end
	if frame.LockButton and frame.LockButton.Text then
		frame.LockButton.Text:SetText(locked and (L["configCenterUnlockWindow"] or "Unlock Window") or (L["configCenterLockWindow"] or "Lock Window"))
	end
end

local function initializeState(frame, app)
	local appKey = app.id or app.title or "default"
	local density
	if app and app.opts and type(app.opts.getDensity) == "function" then
		local ok, value = pcall(app.opts.getDensity, app)
		if ok and (value == "compact" or value == "comfortable") then
			density = value
		end
	end
	density = density or (lib._densityByApp and lib._densityByApp[appKey]) or lib.GetConfiguredDensity(app) or "comfortable"
	local state = {
		app = app,
		frame = frame,
		content = frame.Content,
		contentFrames = {},
		fixedFrames = {},
		sidebarFrames = {},
		sidebarRows = {},
		collapsedGroups = {},
		expandedInfoEntries = {},
		scrollPositions = {},
		contentWidth = CONTENT_WIDTH,
		view = "dashboard",
		selectedCategoryID = nil,
		selectedPageID = nil,
		density = density,
		y = -2,
		sidebarY = -6,
	}
	for key, value in pairs(StateMixin) do
		state[key] = value
	end
	return state
end

local function createFrame(app)
	local L = getLocale(app)
	local name = (app.id or "LibSettingsDesigner") .. "ConfigCenterFrame"
	local outerInsetLeft = 17.5
	local outerInsetRight = 10
	local outerInsetY = 21
	local topInset = 19
	local topBarHeight = 48
	local contentGap = 12
	local contentTop = topInset + topBarHeight + contentGap
	local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	lib.ApplyThemeColors(app)
	lib.ApplyThemeBorders(app)
	local storedWidth, storedHeight = lib.GetStoredFrameSize(app)
	local savedWidth = math.max(PAGE_LAYOUT.windowMinWidth, storedWidth or WINDOW_WIDTH)
	local savedHeight = math.max(PAGE_LAYOUT.windowMinHeight, storedHeight or WINDOW_HEIGHT)
	frame:SetSize(savedWidth, savedHeight)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(1000)
	frame:SetMovable(true)
	if frame.SetResizable then
		frame:SetResizable(true)
	end
	if frame.SetResizeBounds then
		frame:SetResizeBounds(PAGE_LAYOUT.windowMinWidth, PAGE_LAYOUT.windowMinHeight, math.max(PAGE_LAYOUT.windowMinWidth, (UIParent:GetWidth() or WINDOW_WIDTH) - 80), math.max(PAGE_LAYOUT.windowMinHeight, (UIParent:GetHeight() or WINDOW_HEIGHT) - 80))
	elseif frame.SetMinResize and frame.SetMaxResize then
		frame:SetMinResize(PAGE_LAYOUT.windowMinWidth, PAGE_LAYOUT.windowMinHeight)
		frame:SetMaxResize(math.max(PAGE_LAYOUT.windowMinWidth, (UIParent:GetWidth() or WINDOW_WIDTH) - 80), math.max(PAGE_LAYOUT.windowMinHeight, (UIParent:GetHeight() or WINDOW_HEIGHT) - 80))
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if self._eqolLocked then return end
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
	frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 10)
	frame.bg:SetColorTexture(
		lib.ThemeColors.frameBg[1],
		lib.ThemeColors.frameBg[2],
		lib.ThemeColors.frameBg[3],
		lib.ThemeColors.frameBg[4]
	)
	frame.MaterialOverlay = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
	frame.MaterialOverlay:SetPoint("TOPLEFT", frame.bg, "TOPLEFT", 0, 0)
	frame.MaterialOverlay:SetPoint("BOTTOMRIGHT", frame.bg, "BOTTOMRIGHT", 0, 0)
	frame.MaterialOverlay:SetTexture(getLibAssetPath(app, "LibSettingsDesigner_BackgroundDark.tga"))
	frame.MaterialOverlay:SetVertexColor(
		lib.ThemeColors.overlayTint[1],
		lib.ThemeColors.overlayTint[2],
		lib.ThemeColors.overlayTint[3],
		lib.ThemeColors.overlayTint[4] or 1
	)
	frame.MaterialOverlay:SetBlendMode("BLEND")
	frame.MaterialOverlay:SetAlpha(0.08)
	applyWindowBorder(frame, app)
	if frame.CloseButton then
		frame.CloseButton:Hide()
		if frame.CloseButton.HookScript then
			frame.CloseButton:HookScript("OnShow", function(self) self:Hide() end)
		end
	end
	frame:Hide()

	frame.TopBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.TopBar:SetPoint("TOPLEFT", frame, "TOPLEFT", outerInsetLeft, -topInset)
	frame.TopBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -outerInsetRight, -topInset)
	frame.TopBar:SetHeight(topBarHeight)
	applyBackdrop(frame.TopBar, TOPBAR_BG, lib.ThemeColors.topbarBorder, "topbar")

	frame.TopBarAccent = frame.TopBar:CreateTexture(nil, "OVERLAY")
	frame.TopBarAccent:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.38)
	frame.TopBarAccent:SetPoint("BOTTOMLEFT", frame.TopBar, "BOTTOMLEFT", 10, 0)
	frame.TopBarAccent:SetPoint("BOTTOMRIGHT", frame.TopBar, "BOTTOMRIGHT", -10, 0)
	frame.TopBarAccent:SetHeight(1)

	frame.HeaderIcon = createIcon(frame.TopBar, getAddonIcon(app), 32, false)
	frame.HeaderIcon:SetPoint("LEFT", frame.TopBar, "LEFT", 12, 0)

	frame.Title = frame.TopBar:CreateFontString(nil, "OVERLAY", FONT_TITLE)
	frame.Title:SetPoint("LEFT", frame.HeaderIcon, "RIGHT", 10, 0)
	frame.Title:SetWidth(320)
	frame.Title:SetJustifyH("LEFT")
	frame.Title:SetText(app.opts and app.opts.settingsTitle or L["configCenterTitle"] or (getAppTitle(app) .. " Settings"))
	frame.Title:SetShadowColor(0, 0, 0, 0.95)
	frame.Title:SetShadowOffset(1, -1)
	setTextColor(frame.Title, TEXT.topbarGold)

	local function createTopbarActionButton()
		local button = makeFlatButton(frame.TopBar, "", 32, 28)
		button:Hide()
		setFrameBackdrop(button, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		setTextColor(button.Text, TEXT.topbarGold)
		button:SetScript("OnEnter", function(self)
			setFrameBackdrop(self, lib.ThemeColors.buttonTopbarHoverBg, lib.ThemeColors.buttonHoverBorder, "topbarButton")
			local action = self._eqolTopbarAction
			local tooltip = action and getTopbarActionTooltip(action, app, self._eqolTopbarState)
			if tooltip and _G.GameTooltip then
				_G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
				_G.GameTooltip:SetText(getTopbarActionText(action, app, self._eqolTopbarState))
				_G.GameTooltip:AddLine(tooltip, 1, 1, 1, true)
				_G.GameTooltip:Show()
			end
		end)
		button:SetScript("OnLeave", function(self)
			setFrameBackdrop(self, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
			if _G.GameTooltip then
				_G.GameTooltip:Hide()
			end
		end)
		button:SetScript("OnClick", function(self)
			local action = self._eqolTopbarAction
			local state = self._eqolTopbarState
			if not action then
				return
			end
			if topbarActionHasMenu(action) then
				openTopbarActionMenu(self, action, app, state)
			elseif type(action.onClick) == "function" then
				pcall(action.onClick, app, action, state, self)
				lib.RefreshTopbar(frame, state)
			end
		end)
		button:SetScript("OnHide", function(self)
			self._eqolTopbarPulse = nil
			self:SetAlpha(1)
		end)
		return button
	end
	frame.TopbarTitleActionButtons = {}
	frame.TopbarActionButtons = {}
	for i = 1, 8 do
		frame.TopbarTitleActionButtons[i] = createTopbarActionButton()
		frame.TopbarActionButtons[i] = createTopbarActionButton()
	end

	frame.CustomCloseButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
	frame.CustomCloseButton:SetSize(32, 32)
	frame.CustomCloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 16, 10)
	frame.CustomCloseButton.NormalTexture = frame.CustomCloseButton:CreateTexture(nil, "ARTWORK")
	frame.CustomCloseButton.NormalTexture:SetAllPoints(frame.CustomCloseButton)
	frame.CustomCloseButton.NormalTexture:SetTexture(getLibAssetPath(app, "LibSettingsDesigner_CloseButton.tga"))
	frame.CustomCloseButton.HoverTexture = frame.CustomCloseButton:CreateTexture(nil, "OVERLAY")
	frame.CustomCloseButton.HoverTexture:SetAllPoints(frame.CustomCloseButton)
	frame.CustomCloseButton.HoverTexture:SetTexture(getLibAssetPath(app, "LibSettingsDesigner_CloseButtonHover.tga"))
	frame.CustomCloseButton.HoverTexture:Hide()
	frame.CustomCloseButton:SetScript("OnEnter", function(self)
		self.HoverTexture:Show()
	end)
	frame.CustomCloseButton:SetScript("OnLeave", function(self)
		self.HoverTexture:Hide()
	end)
	frame.CustomCloseButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame.ResetButton = makeFlatButton(frame.TopBar, L["configCenterDefaults"] or "Defaults", 104, 28)
	frame.ResetButton:SetPoint("RIGHT", frame.TopBar, "RIGHT", -12, 0)
	setFrameBackdrop(frame.ResetButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
	setTextColor(frame.ResetButton.Text, TEXT.topbarGold)
	frame.ResetButton:SetScript("OnEnter", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarHoverBg, lib.ThemeColors.buttonHoverBorder, "topbarButton")
	end)
	frame.ResetButton:SetScript("OnLeave", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
	end)

	frame.LockButton = makeFlatButton(frame.TopBar, L["configCenterLockWindow"] or "Lock Window", 138, 28)
	frame.LockButton:SetPoint("RIGHT", frame.ResetButton, "LEFT", -12, 0)
	setFrameBackdrop(frame.LockButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
	setTextColor(frame.LockButton.Text, TEXT.topbarGold)
	frame.LockButton:SetScript("OnEnter", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarHoverBg, lib.ThemeColors.buttonHoverBorder, "topbarButton")
		if _G.GameTooltip then
			_G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
			_G.GameTooltip:SetText(L["configCenterLockWindowDesc"] or "Prevents the settings window from being moved by touch or mouse drags.")
			_G.GameTooltip:Show()
		end
	end)
	frame.LockButton:SetScript("OnLeave", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		if _G.GameTooltip then
			_G.GameTooltip:Hide()
		end
	end)
	frame.LockButton:SetScript("OnClick", function()
		lib.SaveFrameLocked(app, not lib.IsFrameLocked(app))
		lib.ApplyFrameLocked(frame, app)
	end)

	frame.DensityButton = makeFlatButton(frame.TopBar, L["configCenterDensityComfortable"] or "Comfortable", 118, 28)
	frame.DensityButton:SetPoint("RIGHT", frame.ResetButton, "LEFT", -12, 0)
	setFrameBackdrop(frame.DensityButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
	setTextColor(frame.DensityButton.Text, TEXT.topbarGold)
	frame.DensityButton:SetScript("OnEnter", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarHoverBg, lib.ThemeColors.buttonHoverBorder, "topbarButton")
	end)
	frame.DensityButton:SetScript("OnLeave", function(self)
		setFrameBackdrop(self, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
	end)
	frame.DensityButton:SetShown(lib.ShouldShowDensityButton(app))
	frame.LockButton:ClearAllPoints()
	if lib.ShouldShowDensityButton(app) then
		frame.LockButton:SetPoint("RIGHT", frame.DensityButton, "LEFT", -12, 0)
	else
		frame.LockButton:SetPoint("RIGHT", frame.ResetButton, "LEFT", -12, 0)
	end

	frame.SearchShell = CreateFrame("Frame", nil, frame.TopBar, "BackdropTemplate")
	frame.SearchShell:SetSize(286, 28)
	frame.SearchShell:SetPoint(
		"RIGHT",
		frame.LockButton,
		"LEFT",
		-12,
		0
	)
	applyBackdrop(frame.SearchShell, lib.ThemeColors.searchBg, lib.ThemeColors.searchBorder, "search")

	frame.SearchIcon = frame.SearchShell:CreateTexture(nil, "OVERLAY")
	frame.SearchIcon:SetSize(15, 15)
	frame.SearchIcon:SetPoint("LEFT", frame.SearchShell, "LEFT", 10, 0)
	if frame.SearchIcon.SetAtlas then
		local ok = pcall(frame.SearchIcon.SetAtlas, frame.SearchIcon, "common-search-magnifyingglass", false)
		if not ok then
			frame.SearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
		end
	else
		frame.SearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
	end
	frame.SearchIcon:SetAlpha(0.72)

	frame.SearchBox = CreateFrame("EditBox", nil, frame.SearchShell, "InputBoxTemplate")
	frame.SearchBox:SetPoint("LEFT", frame.SearchShell, "LEFT", 0, 0)
	frame.SearchBox:SetPoint("RIGHT", frame.SearchShell, "RIGHT", -24, 0)
	frame.SearchBox:SetHeight(28)
	frame.SearchBox:SetAutoFocus(false)
	if frame.SearchBox.SetTextInsets then
		frame.SearchBox:SetTextInsets(34, 4, 0, 0)
	end
	for _, regionKey in ipairs({ "Left", "Middle", "Right", "LeftTex", "MiddleTex", "RightTex" }) do
		local region = frame.SearchBox[regionKey]
		if region and region.SetAlpha then
			region:SetAlpha(0)
		end
	end
	frame.SearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	frame.SearchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

	frame.SearchPlaceholder = frame.SearchShell:CreateFontString(nil, "OVERLAY", FONT_MUTED)
	frame.SearchPlaceholder:SetPoint("LEFT", frame.SearchBox, "LEFT", 34, 1)
	frame.SearchPlaceholder:SetPoint("RIGHT", frame.SearchBox, "RIGHT", -30, 1)
	frame.SearchPlaceholder:SetJustifyH("LEFT")
	frame.SearchPlaceholder:SetText((L["configCenterSearchPlaceholder"] or "Search settings") .. "...")
	setTextColor(frame.SearchPlaceholder, TEXT.subtle)

	frame.SearchClearButton = CreateFrame("Button", nil, frame.SearchShell)
	frame.SearchClearButton:SetSize(14, 14)
	frame.SearchClearButton:SetPoint("RIGHT", frame.SearchShell, "RIGHT", -7, 0)
	frame.SearchClearButton:SetFrameLevel(frame.SearchBox:GetFrameLevel() + 5)
	frame.SearchClearButton:RegisterForClicks("LeftButtonUp")
	frame.SearchClearButton.Icon = frame.SearchClearButton:CreateTexture(nil, "OVERLAY")
	frame.SearchClearButton.Icon:SetAllPoints(frame.SearchClearButton)
	if frame.SearchClearButton.Icon.SetAtlas then
		if not pcall(frame.SearchClearButton.Icon.SetAtlas, frame.SearchClearButton.Icon, "common-search-clearbutton", false) then
			frame.SearchClearButton.Icon:SetTexture("Interface\\Common\\VoiceChat-Muted")
		end
	else
		frame.SearchClearButton.Icon:SetTexture("Interface\\Common\\VoiceChat-Muted")
	end
	frame.SearchClearButton.Icon:SetAlpha(0.70)
	frame.SearchClearButton:SetScript("OnEnter", function(self)
		self.Icon:SetAlpha(1)
	end)
	frame.SearchClearButton:SetScript("OnLeave", function(self)
		self.Icon:SetAlpha(0.70)
	end)
	frame.SearchClearButton:SetScript("OnClick", function()
		frame.SearchBox:SetText("")
		frame.SearchBox:ClearFocus()
	end)
	frame.SearchClearButton:Hide()

	frame.SidebarShell = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.SidebarShell:SetPoint("TOPLEFT", frame, "TOPLEFT", outerInsetLeft, -contentTop)
	frame.SidebarShell:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", outerInsetLeft, outerInsetY)
	frame.SidebarShell:SetWidth(SIDEBAR_WIDTH)
	applyBackdrop(frame.SidebarShell, SIDEBAR_BG, PANEL_BORDER, "sidebar")

	frame.SidebarScroll = CreateFrame("ScrollFrame", nil, frame.SidebarShell, "UIPanelScrollFrameTemplate")
	frame.SidebarScroll:SetPoint("TOPLEFT", frame.SidebarShell, "TOPLEFT", 8, -8)
	frame.SidebarScroll:SetPoint("BOTTOMRIGHT", frame.SidebarShell, "BOTTOMRIGHT", -28, 8)
	frame.SidebarScroll._LibSettingsDesignerScrollStep = 44
	skinScrollFrame(frame.SidebarScroll)

	frame.Sidebar = CreateFrame("Frame", nil, frame.SidebarScroll)
	frame.Sidebar:SetWidth(SIDEBAR_WIDTH - 44)
	frame.Sidebar:SetHeight(1)
	frame.Sidebar:SetPoint("TOPLEFT", frame.SidebarScroll, "TOPLEFT", 0, 0)
	frame.SidebarScroll:SetScrollChild(frame.Sidebar)

	frame.ResizeGrip = CreateFrame("Button", nil, frame)
	frame.ResizeGrip:SetSize(22, 22)
	frame.ResizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 17, -12)
	frame.ResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	frame.ResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
	frame.ResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	if frame.ResizeGrip:GetNormalTexture() then
		frame.ResizeGrip:GetNormalTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.62)
	end
	if frame.ResizeGrip:GetHighlightTexture() then
		frame.ResizeGrip:GetHighlightTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.92)
	end
	if frame.ResizeGrip:GetPushedTexture() then
		frame.ResizeGrip:GetPushedTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.82)
	end
	frame.ResizeGrip:SetScript("OnEnter", function(self)
		if self:GetNormalTexture() then
			self:GetNormalTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.82)
		end
	end)
	frame.ResizeGrip:SetScript("OnLeave", function(self)
		if self:GetNormalTexture() then
			self:GetNormalTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.62)
		end
	end)
	frame.ResizeGrip:SetScript("OnMouseDown", function(self)
		self._eqolResizing = true
		self._eqolStartWidth = frame:GetWidth()
		self._eqolStartHeight = frame:GetHeight()
		self._eqolLastWidth = self._eqolStartWidth
		self._eqolLastHeight = self._eqolStartHeight
		self._eqolRenderElapsed = 0
		local cursorX, cursorY = GetCursorPosition()
		local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
		self._eqolStartCursorX = cursorX / scale
		self._eqolStartCursorY = cursorY / scale
		self._eqolAnchorLeft = frame:GetLeft()
		self._eqolAnchorTop = frame:GetTop()
		if self._eqolAnchorLeft and self._eqolAnchorTop then
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self._eqolAnchorLeft, self._eqolAnchorTop)
		end
	end)
	frame.ResizeGrip:SetScript("OnMouseUp", function(self)
		self._eqolResizing = nil
		lib.SaveFrameSize(app, frame:GetWidth(), frame:GetHeight())
		if frame._LibSettingsDesignerState then
			frame._LibSettingsDesignerState:RenderContent()
		end
	end)
	frame.ResizeGrip:SetScript("OnHide", function(self)
		self._eqolResizing = nil
	end)
	frame.ResizeGrip:SetScript("OnUpdate", function(self, elapsed)
		if not self._eqolResizing then
			return
		end
		self._eqolRenderElapsed = (self._eqolRenderElapsed or 0) + (elapsed or 0)
		if self._eqolRenderElapsed < 0.04 then
			return
		end
		self._eqolRenderElapsed = 0
		local cursorX, cursorY = GetCursorPosition()
		local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
		cursorX = cursorX / scale
		cursorY = cursorY / scale
		local width = math.max(PAGE_LAYOUT.windowMinWidth, (self._eqolStartWidth or WINDOW_WIDTH) + (cursorX - (self._eqolStartCursorX or cursorX)))
		local height = math.max(PAGE_LAYOUT.windowMinHeight, (self._eqolStartHeight or WINDOW_HEIGHT) - (cursorY - (self._eqolStartCursorY or cursorY)))
		if width ~= self._eqolLastWidth or height ~= self._eqolLastHeight then
			self._eqolLastWidth = width
			self._eqolLastHeight = height
			frame:SetSize(width, height)
			if frame._LibSettingsDesignerState then
				updateContentMetrics(frame._LibSettingsDesignerState)
			end
		end
	end)

	frame.ContentShell = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.ContentShell:SetPoint("TOPLEFT", frame.SidebarShell, "TOPRIGHT", 8, 0)
	frame.ContentShell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -outerInsetRight, outerInsetY)
	applyBackdrop(frame.ContentShell, CONTENT_BG, PANEL_BORDER, "content")

	frame.Scroll = CreateFrame("ScrollFrame", nil, frame.ContentShell, "UIPanelScrollFrameTemplate")
	frame.Scroll:SetPoint("TOPLEFT", frame.ContentShell, "TOPLEFT", 12, -12)
	frame.Scroll:SetPoint("BOTTOMRIGHT", frame.ContentShell, "BOTTOMRIGHT", -14, 12)
	frame.Scroll._LibSettingsDesignerScrollStep = 64
	skinScrollFrame(frame.Scroll)

	frame.Content = CreateFrame("Frame", nil, frame.Scroll)
	frame.Content:SetWidth(CONTENT_WIDTH)
	frame.Content:SetHeight(1)
	frame.Content:SetPoint("TOPLEFT", frame.Scroll, "TOPLEFT", 0, 0)
	frame.Scroll:SetScrollChild(frame.Content)

	local state = initializeState(frame, app)
	frame._LibSettingsDesignerState = state
	updateContentMetrics(state)
	frame:SetScript("OnHide", function()
		lib.ReleaseAllCustomHandles(state)
	end)

	frame.SearchBox:SetScript("OnTextChanged", function()
		if frame.SearchPlaceholder then
			frame.SearchPlaceholder:SetShown(frame.SearchBox:GetText() == "")
		end
		if frame.SearchClearButton then
			frame.SearchClearButton:SetShown(frame.SearchBox:GetText() ~= "")
		end
		if state.suppressSearchRender then
			return
		end
		state:RenderContent()
	end)
	frame.ResetButton:SetScript("OnClick", function()
		confirmResetCurrentPage(state)
	end)
	frame.DensityButton:SetScript("OnClick", function()
		if lib.ShouldShowDensityButton(app) then
			state:SetDensity(lib.IsCompactDensity(state) and "comfortable" or "compact")
		end
	end)
	lib.RefreshTopbar(frame, state)
	lib.ApplyFrameLocked(frame, app)
	frame:SetScript("OnSizeChanged", function()
		lib.SaveFrameSize(app, frame:GetWidth(), frame:GetHeight())
		if frame:IsShown() and not (frame.ResizeGrip and frame.ResizeGrip._eqolResizing) then
			state:RenderContent()
		end
	end)

	state:RenderSidebar()
	state:RenderContent()
	return frame
end

local function refreshFrameTheme(frame, app)
	if not frame then
		return
	end
	lib.ApplyThemeColors(app)
	lib.ApplyThemeBorders(app)
	if frame.bg and frame.bg.SetColorTexture then
		frame.bg:SetColorTexture(
			lib.ThemeColors.frameBg[1],
			lib.ThemeColors.frameBg[2],
			lib.ThemeColors.frameBg[3],
			lib.ThemeColors.frameBg[4]
		)
	end
	if frame.MaterialOverlay and frame.MaterialOverlay.SetVertexColor then
		frame.MaterialOverlay:SetVertexColor(
			lib.ThemeColors.overlayTint[1],
			lib.ThemeColors.overlayTint[2],
			lib.ThemeColors.overlayTint[3],
			lib.ThemeColors.overlayTint[4] or 1
		)
	end
	if frame.TopBar then
		setFrameBackdrop(frame.TopBar, TOPBAR_BG, lib.ThemeColors.topbarBorder, "topbar")
	end
	if frame.ResetButton then
		setFrameBackdrop(frame.ResetButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		setTextColor(frame.ResetButton.Text, TEXT.topbarGold)
	end
	if frame.LockButton then
		setFrameBackdrop(frame.LockButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		setTextColor(frame.LockButton.Text, TEXT.topbarGold)
	end
	if frame.DensityButton then
		setFrameBackdrop(frame.DensityButton, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
		setTextColor(frame.DensityButton.Text, TEXT.topbarGold)
	end
	if frame.TopbarTitleActionButtons then
		for _, button in ipairs(frame.TopbarTitleActionButtons) do
			setFrameBackdrop(button, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
			setTextColor(button.Text, TEXT.topbarGold)
		end
	end
	if frame.TopbarActionButtons then
		for _, button in ipairs(frame.TopbarActionButtons) do
			setFrameBackdrop(button, lib.ThemeColors.buttonTopbarBg, lib.ThemeColors.buttonTopbarBorder, "topbarButton")
			setTextColor(button.Text, TEXT.topbarGold)
		end
	end
	if frame.SearchShell then
		setFrameBackdrop(frame.SearchShell, lib.ThemeColors.searchBg, lib.ThemeColors.searchBorder, "search")
	end
	if frame.SidebarShell then
		setFrameBackdrop(frame.SidebarShell, SIDEBAR_BG, PANEL_BORDER, "sidebar")
	end
	if frame.ContentShell then
		setFrameBackdrop(frame.ContentShell, CONTENT_BG, PANEL_BORDER, "content")
	end
	if frame.Title then
		setTextColor(frame.Title, TEXT.topbarGold)
	end
	if frame.TopBarAccent and frame.TopBarAccent.SetColorTexture then
		frame.TopBarAccent:SetColorTexture(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.38)
	end
	if frame.SearchPlaceholder then
		setTextColor(frame.SearchPlaceholder, TEXT.subtle)
	end
	if frame.ResizeGrip then
		if frame.ResizeGrip:GetNormalTexture() then
			frame.ResizeGrip:GetNormalTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.62)
		end
		if frame.ResizeGrip:GetHighlightTexture() then
			frame.ResizeGrip:GetHighlightTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.92)
		end
		if frame.ResizeGrip:GetPushedTexture() then
			frame.ResizeGrip:GetPushedTexture():SetVertexColor(TEXT.gold[1], TEXT.gold[2], TEXT.gold[3], 0.82)
		end
	end
end

function lib.ResolveOpenTarget(app, pageID, focusControlID)
	if not pageID or pageID == "dashboard" or app:GetPage(pageID) then
		return pageID, focusControlID
	end
	local text = tostring(pageID)
	local bestPageID, bestFocus
	for id in pairs(app.pagesByID or {}) do
		if text == id or text:find(id .. ".", 1, true) == 1 then
			local focus = text:sub(#id + 2)
			if focus ~= "" and (not bestPageID or #id > #bestPageID) then
				bestPageID = id
				bestFocus = focus
			end
		end
	end
	if bestPageID then
		return bestPageID, focusControlID or bestFocus
	end
	return pageID, focusControlID
end

function lib:Open(appOrID, pageID, focusControlID)
	local _ = self
	local config = addon.LibSettingsDesigner and addon.LibSettingsDesigner.Config
	local app = type(appOrID) == "table" and appOrID or (config and config:GetAddOn(appOrID))
	if not app then
		return nil
	end
	lib.ApplyThemeColors(app)
	lib.ApplyThemeBorders(app)
	local frame = frames[app.id]
	if not frame then
		frame = createFrame(app)
		frames[app.id] = frame
	else
		refreshFrameTheme(frame, app)
		frame._LibSettingsDesignerState:RenderSidebar()
	end
	local state = frame._LibSettingsDesignerState
	pageID, focusControlID = lib.ResolveOpenTarget(app, pageID, focusControlID)
	if pageID and pageID ~= "dashboard" then
		state:SetPage(pageID, focusControlID)
	elseif not pageID then
		state:RenderContent()
	else
		state:SetDashboard()
	end
	lib.ApplyFrameLocked(frame, app)
	frame:Show()
	return frame
end

function lib.GetFrame(_, appOrID)
	local config = addon.LibSettingsDesigner and addon.LibSettingsDesigner.Config
	local app = type(appOrID) == "table" and appOrID or (config and config:GetAddOn(appOrID))
	if not app then
		return nil
	end
	return frames[app.id]
end

function lib:Toggle(appOrID, pageID, focusControlID)
	local config = addon.LibSettingsDesigner and addon.LibSettingsDesigner.Config
	local app = type(appOrID) == "table" and appOrID or (config and config:GetAddOn(appOrID))
	if not app then
		return nil
	end
	local frame = frames[app.id]
	if frame and frame:IsShown() then
		frame:Hide()
		return frame
	end
	return self:Open(app, pageID, focusControlID)
end
