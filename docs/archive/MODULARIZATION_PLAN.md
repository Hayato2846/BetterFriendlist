# BetterFriendlist - Modularisierungsplan

## 📋 Übersicht

Dieser Plan beschreibt die Umstrukturierung von BetterFriendlist in ein modulares System, das:
- ✅ Bestehende Funktionalität bewahrt
- ✅ Wartbarkeit verbessert
- ✅ Vorbereitung für IMPLEMENTATION_ROADMAP.md (Raid, Quick Join, RAF)
- ✅ Integration mit SETTINGS_ROADMAP.md
- ✅ Klare Separation of Concerns

---

## 🎯 Aktuelle Situation

### Bestehende Dateien
```
BetterFriendlist/
├── Core.lua                          (~200 Zeilen - AceAddon Framework)
├── BetterFriendlist.lua              (~5100+ Zeilen - MONOLITH!)
├── BetterFriendlist.xml              (UI Definitions)
├── BetterFriendlist_Tooltip.lua      (Tooltip System)
├── BetterFriendlist_Settings.lua     (Settings UI - Phase 1-3 complete)
├── BetterFriendlist_Settings.xml
├── Modules/
│   ├── Database.lua                  (SavedVariables Management)
│   └── Groups.lua                    (Group Management)
└── DEBUG_UID_Check.lua               (Debug Tool)
```

### Problem: BetterFriendlist.lua ist monolithisch!

**Enthält alles:**
- Friends List Logic (~1500 Zeilen)
- WHO Frame System (~700 Zeilen)  ← **Gerade fertiggestellt (Phase 1)**
- Ignore List Window (~200 Zeilen)
- Recent Allies Frame (~400 Zeilen)
- Menu System (~300 Zeilen)
- Event Handlers (~500 Zeilen)
- UI Initialization (~800 Zeilen)
- Dropdown/Filter Logic (~400 Zeilen)
- Button Pools & Display (~600 Zeilen)

**Konsequenzen:**
- Schwer zu navigieren (5100+ Zeilen)
- Merge-Konflikte bei mehreren Features
- Schwer zu testen (alles gekoppelt)
- Keine klare API-Grenze
- Zukünftige Features (Raid, Quick Join) würden es noch schlimmer machen

---

## 🏗️ Ziel-Architektur

### Neue Modul-Struktur
```
BetterFriendlist/
├── Core.lua                          (Kern-Framework, Event Dispatcher)
├── BetterFriendlist.toc              (Load Order Definition)
│
├── Modules/
│   ├── Database.lua                  (✅ Existiert - SavedVariables)
│   ├── Groups.lua                    (✅ Existiert - Group Management)
│   ├── FriendsList.lua               (🆕 Friends List Core Logic)
│   ├── WhoFrame.lua                  (🆕 WHO Frame System)
│   ├── IgnoreList.lua                (🆕 Ignore List Window)
│   ├── RecentAllies.lua              (🆕 Recent Allies Frame)
│   ├── MenuSystem.lua                (🆕 Context Menus & Dropdowns)
│   ├── QuickFilters.lua              (🆕 Quick Filter Logic)
│   ├── RaidFrame.lua                 (📋 Zukunft - Phase 2)
│   ├── QuickJoin.lua                 (📋 Zukunft - Phase 3)
│   └── RecruitAFriend.lua            (📋 Zukunft - Phase 4)
│
├── UI/
│   ├── BetterFriendlist.xml          (Main Frame Definition)
│   ├── BetterFriendlist.lua          (UI Glue Code - REDUZIERT!)
│   ├── Tooltip.lua                   (Tooltip System)
│   ├── Settings.lua                  (Settings UI)
│   └── Settings.xml
│
└── Utils/
    ├── FontManager.lua               (🆕 Font Size & Scaling)
    └── ColorManager.lua              (🆕 Group Colors)
```

---

## 📦 Modul-Definitionen

### 1. **Modules/FriendsList.lua** (🆕)
**Verantwortlich für:** Friends List Core Logic

**Funktionen:**
```lua
-- Public API
BFL.FriendsList = BFL:NewModule("FriendsList")

function FriendsList:UpdateFriendsList()
function FriendsList:BuildDisplayList()
function FriendsList:GetDisplayListCount()
function FriendsList:ToggleGroup(groupId)
function FriendsList:CreateGroup(groupName)
function FriendsList:RenameGroup(groupId, newName)
function FriendsList:DeleteGroup(groupId)
function FriendsList:ToggleFriendInGroup(friendUID, groupId)
function FriendsList:IsFriendInGroup(friendUID, groupId)
function FriendsList:RemoveFriendFromGroup(friendUID, groupId)
function FriendsList:GetFriendUID(friend)
function FriendsList:SyncGroups()

-- Internal
local function GetGroupColorCode(groupId)
local function BuildDisplayList()
local function GetLastOnlineText(accountInfo)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~135-1900

**Dependencies:**
- `BFL:GetModule("DB")` - Database
- `BFL:GetModule("Groups")` - Group Management

---

### 2. **Modules/WhoFrame.lua** (🆕)
**Verantwortlich für:** WHO Frame System (Phase 1 COMPLETE)

**Funktionen:**
```lua
-- Public API
BFL.WhoFrame = BFL:NewModule("WhoFrame")

function WhoFrame:Initialize()
function WhoFrame:SendWhoRequest(text)
function WhoFrame:Update(forceRebuild)
function WhoFrame:SortByColumn(sortType)
function WhoFrame:SetSelectedButton(button)

-- Mixins (remain global for XML)
WhoFrameEditBoxMixin = {}
WhoFrameColumnDropdownMixin = {}

-- Button Callbacks (remain global for XML)
function BetterWhoFrame_InitButton(button, elementData)
function BetterWhoListButton_OnClick(button, mouseButton)
function BetterWhoListButton_SetSelected(button, selected)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~3100-3700

**Dependencies:**
- None (standalone)

**Critical:** Global functions müssen global bleiben für XML OnClick/OnLoad!

---

### 3. **Modules/IgnoreList.lua** (🆕)
**Verantwortlich für:** Ignore List Window

**Funktionen:**
```lua
-- Public API
BFL.IgnoreList = BFL:NewModule("IgnoreList")

function IgnoreList:Initialize()
function IgnoreList:Update()
function IgnoreList:GetSelected()
function IgnoreList:Unignore()
function IgnoreList:Toggle()
function IgnoreList:Show()

-- Callbacks (remain global for XML)
function BetterIgnoreListWindow_OnLoad(self)
function IgnoreList_InitButton(button, elementData)
function BetterIgnoreListButton_OnClick(self)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~3700-3885

---

### 4. **Modules/RecentAllies.lua** (🆕)
**Verantwortlich für:** Recent Allies Frame

**Funktionen:**
```lua
-- Public API
BFL.RecentAllies = BFL:NewModule("RecentAllies")

function RecentAllies:Initialize()
function RecentAllies:Refresh(retainScrollPosition)
function RecentAllies:BuildDataProvider()

-- Callbacks (remain global for XML)
function BetterRecentAlliesFrame_OnLoad(self)
function BetterRecentAlliesFrame_OnShow(self)
function BetterRecentAlliesFrame_OnHide(self)
function BetterRecentAlliesEntry_Initialize(button, elementData)
function BetterRecentAlliesEntry_OnEnter(button)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~3886-4250

---

### 5. **Modules/MenuSystem.lua** (🆕)
**Verantwortlich für:** Context Menus & Dropdowns

**Funktionen:**
```lua
-- Public API
BFL.MenuSystem = BFL:NewModule("MenuSystem")

function MenuSystem:Initialize()
function MenuSystem:ShowFriendDropdown(name, connected, ...)
function MenuSystem:ShowBNDropdown(name, connected, ...)
function MenuSystem:ShowContactsMenu(button)
function MenuSystem:InitializeStatusDropdown()
function MenuSystem:InitializeSortDropdown()

-- Internal
local function AddGroupsToFriendMenu(owner, rootDescription, contextData)
local function FilterWhoPlayerMenu(rootDescription, contextData)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~2100-2480, 3039-3100

**Dependencies:**
- `BFL:GetModule("Groups")` - For group menu creation

---

### 6. **Modules/QuickFilters.lua** (🆕)
**Verantwortlich für:** Quick Filter Buttons Logic

**Funktionen:**
```lua
-- Public API
BFL.QuickFilters = BFL:NewModule("QuickFilters")

function QuickFilters:Initialize()
function QuickFilters:InitializeDropdown()
function QuickFilters:SetFilter(mode)
function QuickFilters:UpdateButtons()

-- Global for XML callbacks
function BetterFriendsFrame_InitQuickFilterDropdown()
function BetterFriendsFrame_SetQuickFilter(mode)
function BetterFriendsFrame_UpdateQuickFilterButtons()
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~591-692

**Dependencies:**
- `BFL:GetModule("FriendsList")` - To trigger list rebuild

---

### 7. **Utils/FontManager.lua** (🆕)
**Verantwortlich für:** Font Sizing & Scaling

**Funktionen:**
```lua
BFL.FontManager = {}

function FontManager:GetButtonHeight()
function FontManager:GetFontSizeMultiplier()
function FontManager:ApplyFontSize(fontString)
function FontManager:GetCompactMode()
function FontManager:SetCompactMode(enabled)
function FontManager:SetFontSize(size) -- "small", "normal", "large"
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~53-92

**Dependencies:**
- `BFL:GetModule("DB")` - Read settings

---

### 8. **Utils/ColorManager.lua** (🆕)
**Verantwortlich für:** Group Color Management

**Funktionen:**
```lua
BFL.ColorManager = {}

function ColorManager:GetGroupColor(groupId)
function ColorManager:GetGroupColorCode(groupId)
function ColorManager:SetGroupColor(groupId, r, g, b)
function ColorManager:ResetGroupColor(groupId)
function ColorManager:GetDefaultColor(groupId)
```

**Extrahiert aus:** BetterFriendlist.lua Zeilen ~486-504

**Dependencies:**
- `BFL:GetModule("DB")` - Read/write color settings

---

### 9. **UI/BetterFriendlist.lua** (REDUZIERT!)
**Verantwortlich für:** UI Glue Code & Initialization

**Verbleibende Funktionen:**
```lua
-- Frame Lifecycle
function BetterFriendsFrame_OnLoad(self)
function BetterFriendsFrame_OnShow(self)
function BetterFriendsFrame_OnHide(self)
function BetterFriendsFrame_OnEvent(self, event, ...)

-- Public Toggle Functions
function ShowBetterFriendsFrame()
function HideBetterFriendsFrame()
function ToggleBetterFriendsFrame()

-- Tab System
function InitializeTabs()
function BetterFriendsFrame_ShowTab(tabIndex)
function BetterFriendsFrame_ShowBottomTab(tabIndex)

-- Display Wrapper
function BetterFriendsFrame_UpdateDisplay()

-- Button Callbacks (XML bindings)
function BetterFriendsList_Button_OnClick(button, mouseButton)
function BetterFriendsList_Button_OnEnter(button)
function BetterFriendsList_Button_OnLeave(button)

-- Button Pool (keep hier - UI-specific)
local function GetOrCreateFriendButton(index)
local function GetOrCreateHeaderButton(index)
local function ResetButtonPool()
```

**Reduziert von:** ~5100 Zeilen → ~1500 Zeilen

---

## 🔄 Migrations-Strategie

### Phase 1: Vorbereitung (Keine Breaking Changes)
**Ziel:** Setup ohne Funktionalität zu brechen

**Schritte:**
1. ✅ Erstelle `Utils/` Ordner
2. ✅ Erstelle `Modules/FontManager.lua` (leere Shell)
3. ✅ Erstelle `Modules/ColorManager.lua` (leere Shell)
4. ✅ Update `.toc` mit neuen Dateien
5. ✅ Test: Addon lädt ohne Errors

**Estimated Time:** 30 Minuten

---

### Phase 2: FontManager & ColorManager Migration
**Ziel:** Kleine, isolierte Module zuerst

**Schritte:**
1. ✅ Implementiere `FontManager:GetButtonHeight()`
2. ✅ Implementiere `FontManager:GetFontSizeMultiplier()`
3. ✅ Implementiere `FontManager:ApplyFontSize()`
4. ✅ Ersetze alle Aufrufe in BetterFriendlist.lua
5. ✅ Implementiere `ColorManager:GetGroupColor()`
6. ✅ Implementiere `ColorManager:GetGroupColorCode()`
7. ✅ Ersetze alle Aufrufe in BetterFriendlist.lua
8. ✅ Test: Fonts und Colors funktionieren

**Estimated Time:** 1-2 Stunden

---

### Phase 3: WhoFrame Migration ⭐ PRIORITÄT
**Ziel:** WHO Frame isolieren (gerade fertiggestellt!)

**Schritte:**
1. ✅ Erstelle `Modules/WhoFrame.lua`
2. ✅ Kopiere WHO Frame Code (~700 Zeilen)
3. ✅ Wrap in `BFL.WhoFrame = BFL:NewModule("WhoFrame")`
4. ✅ Behalte globale Funktionen für XML (OnLoad, OnClick, etc.)
5. ✅ Update `.toc` - lade WhoFrame.lua
6. ✅ Lösche WHO Frame Code aus BetterFriendlist.lua
7. ✅ Test: WHO Frame funktioniert identisch

**Critical:** Globale Funktionen MÜSSEN global bleiben!
```lua
-- MUSS GLOBAL sein für XML
function BetterWhoFrame_InitButton(button, elementData)
function BetterWhoListButton_OnClick(button, mouseButton)
WhoFrameEditBoxMixin = {}
WhoFrameColumnDropdownMixin = {}
```

**Estimated Time:** 2-3 Stunden

---

### Phase 4: IgnoreList & RecentAllies Migration
**Ziel:** Weitere eigenständige Frames isolieren

**Schritte:**
1. ✅ Erstelle `Modules/IgnoreList.lua`
2. ✅ Kopiere Ignore List Code (~200 Zeilen)
3. ✅ Wrap in Modul-Struktur
4. ✅ Erstelle `Modules/RecentAllies.lua`
5. ✅ Kopiere Recent Allies Code (~400 Zeilen)
6. ✅ Wrap in Modul-Struktur
7. ✅ Update `.toc`
8. ✅ Lösche Code aus BetterFriendlist.lua
9. ✅ Test: Ignore List & Recent Allies funktionieren

**Estimated Time:** 2-3 Stunden

---

### Phase 5: MenuSystem & QuickFilters Migration
**Ziel:** Menu-Logik isolieren

**Schritte:**
1. ✅ Erstelle `Modules/MenuSystem.lua`
2. ✅ Kopiere Menu Code (~300 Zeilen)
3. ✅ Erstelle `Modules/QuickFilters.lua`
4. ✅ Kopiere Filter Code (~100 Zeilen)
5. ✅ Update `.toc`
6. ✅ Lösche Code aus BetterFriendlist.lua
7. ✅ Test: Menus & Filters funktionieren

**Estimated Time:** 2 Stunden

---

### Phase 6: FriendsList Migration ⭐ GROSS
**Ziel:** Friends List Core isolieren

**Schritte:**
1. ✅ Erstelle `Modules/FriendsList.lua`
2. ✅ Kopiere Friends List Code (~1500 Zeilen)
3. ✅ Wrap in Modul-API
4. ✅ Update alle Referenzen in BetterFriendlist.lua
5. ✅ Update `.toc`
6. ✅ Lösche Code aus BetterFriendlist.lua
7. ✅ Test: Friends List funktioniert vollständig

**Estimated Time:** 4-5 Stunden

---

### Phase 7: UI/BetterFriendlist.lua Cleanup
**Ziel:** Haupt-Datei auf Glue Code reduzieren

**Schritte:**
1. ✅ Verschiebe BetterFriendlist.lua → UI/BetterFriendlist.lua
2. ✅ Lösche alle migrierten Funktionen
3. ✅ Behalte nur UI Callbacks & Frame Lifecycle
4. ✅ Behalte Button Pool (UI-spezifisch)
5. ✅ Update `.toc` Pfade
6. ✅ Test: Vollständige Funktionalität

**Result:** BetterFriendlist.lua reduziert von ~5100 → ~1500 Zeilen!

**Estimated Time:** 2-3 Stunden

---

## 📋 Neue .toc Load Order

```toc
## Interface: 110205
## Title: BetterFriendlist
## Notes: A complete replacement for the default WoW friends list
## Author: YourName
## Version: 0.2
## SavedVariables: BetterFriendlistDB

# Core Framework
Core.lua

# Database & Core Modules
Modules\Database.lua
Modules\Groups.lua

# Utilities
Utils\FontManager.lua
Utils\ColorManager.lua

# Feature Modules
Modules\QuickFilters.lua
Modules\MenuSystem.lua
Modules\FriendsList.lua
Modules\WhoFrame.lua
Modules\IgnoreList.lua
Modules\RecentAllies.lua

# Future Modules (Phase 2-4)
# Modules\RaidFrame.lua
# Modules\QuickJoin.lua
# Modules\RecruitAFriend.lua

# UI Layer
UI\BetterFriendlist.xml
UI\BetterFriendlist.lua
UI\Tooltip.lua

# Settings
UI\Settings.xml
UI\Settings.lua

# Debug Tools
DEBUG_UID_Check.lua
```

---

## 🎯 Integration mit Roadmaps

### IMPLEMENTATION_ROADMAP.md Integration
**Neue Module vorbereitet für:**

1. **Phase 2: Raid Frame** → `Modules/RaidFrame.lua`
   - Eigenständiges Modul
   - Dependencies: Keine
   - Load Order: Nach Core Modules

2. **Phase 3: Quick Join** → `Modules/QuickJoin.lua`
   - Eigenständiges Modul
   - Dependencies: Keine
   - Load Order: Nach Core Modules

3. **Phase 4: RAF** → `Modules/RecruitAFriend.lua`
   - Eigenständiges Modul
   - Dependencies: Keine
   - Load Order: Nach Core Modules

**Vorteil:** Jede Phase kann eigenständig entwickelt werden ohne Merge-Konflikte!

---

### SETTINGS_ROADMAP.md Integration
**Settings System bereits gut strukturiert:**
- ✅ `BetterFriendlist_Settings.lua` (UI)
- ✅ `BetterFriendlist_Settings.xml`

**Neue Module greifen auf Settings zu via:**
```lua
local db = BFL:GetModule("DB")
local compactMode = db:GetSetting("compactMode")
local fontSize = db:GetSetting("fontSize")
```

**Settings Erweiterungen:**
- Phase 4-5: Quick Filters Settings → `QuickFilters:ApplySettings()`
- Phase 4-5: Sort Order Settings → `FriendsList:ApplySortSettings()`
- Phase 6: Visual Settings → `FontManager:ApplySettings()`

---

## ✅ Vorteile der Modularisierung

### 1. **Entwicklung**
- ✅ Klare Verantwortlichkeiten
- ✅ Einfacher zu navigieren (300-700 Zeilen pro Modul statt 5100)
- ✅ Parallele Entwicklung möglich (verschiedene Module)
- ✅ Einfacher zu testen (Module isoliert testbar)

### 2. **Wartbarkeit**
- ✅ Bugs schneller zu finden (klare Modul-Grenzen)
- ✅ Änderungen lokal begrenzt
- ✅ Weniger Merge-Konflikte
- ✅ Code-Reviews fokussierter

### 3. **Erweiterbarkeit**
- ✅ Neue Features (Raid, Quick Join) als eigenständige Module
- ✅ Features können optional deaktiviert werden
- ✅ Klare API-Grenzen zwischen Modulen
- ✅ Dependencies explizit definiert

### 4. **Performance**
- ✅ Code kann lazy-loaded werden (z.B. WHO Frame nur wenn Tab geöffnet)
- ✅ Kleinere Namespaces (weniger globale Pollution)
- ✅ Einfacher zu profilieren (welches Modul ist langsam?)

---

## ⚠️ Risiken & Mitigation

### Risiko 1: Breaking Changes
**Problem:** Global functions werden zu Modul-Funktionen

**Mitigation:**
- ✅ Behalte XML-Callbacks global
- ✅ Verwende Wrapper-Funktionen wenn nötig
- ✅ Teste jede Phase gründlich
- ✅ Erstelle Rollback-Branch vor großen Änderungen

### Risiko 2: Cross-Module Dependencies
**Problem:** Module brauchen Funktionen von anderen Modulen

**Mitigation:**
- ✅ Explizite Dependency-Definition
- ✅ Verwende `BFL:GetModule("ModuleName")` Pattern
- ✅ Avoid circular dependencies
- ✅ Database als zentraler State

### Risiko 3: Performance Overhead
**Problem:** Modul-Aufrufe könnten langsamer sein

**Mitigation:**
- ✅ Cache Modul-Referenzen lokal
- ✅ Vermeide unnötige Modul-Hops
- ✅ Profile vor/nach Modularisierung
- ✅ Optimize hot paths

### Risiko 4: Time Investment
**Problem:** Modularisierung braucht Zeit

**Mitigation:**
- ✅ Phasenweise Migration (jede Phase funktioniert)
- ✅ Kann über mehrere Sessions verteilt werden
- ✅ Quick wins zuerst (FontManager, ColorManager)
- ✅ Große Module (FriendsList) zum Schluss

---

## 📊 Aufwands-Schätzung

| Phase | Modul | Zeilen | Zeit | Priorität |
|-------|-------|--------|------|-----------|
| 1 | Setup | ~50 | 30min | ⭐⭐⭐⭐⭐ |
| 2 | FontManager + ColorManager | ~100 | 1-2h | ⭐⭐⭐⭐ |
| 3 | WhoFrame | ~700 | 2-3h | ⭐⭐⭐⭐⭐ |
| 4 | IgnoreList + RecentAllies | ~600 | 2-3h | ⭐⭐⭐ |
| 5 | MenuSystem + QuickFilters | ~400 | 2h | ⭐⭐⭐ |
| 6 | FriendsList | ~1500 | 4-5h | ⭐⭐⭐⭐⭐ |
| 7 | Cleanup | ~200 | 2-3h | ⭐⭐⭐⭐ |
| **Total** | | **~3550** | **14-18h** | |

**Empfohlene Reihenfolge:**
1. Phase 1 + 2 (Setup + Utils) - **2-3h** - Quick Win!
2. Phase 3 (WhoFrame) - **2-3h** - Isoliert, gerade fertig!
3. Phase 5 (Menus) - **2h** - Niedrige Komplexität
4. Phase 4 (Ignore/Recent) - **2-3h** - Eigenständig
5. Phase 6 (FriendsList) - **4-5h** - Größter Brocken
6. Phase 7 (Cleanup) - **2-3h** - Final polish

---

## 🚀 Nächste Schritte

### Sofort (Next Session):
1. ✅ Erstelle `Utils/` Ordner
2. ✅ Erstelle `Modules/FontManager.lua` (Shell)
3. ✅ Erstelle `Modules/ColorManager.lua` (Shell)
4. ✅ Update `.toc` mit neuen Dateien
5. ✅ Test: Addon lädt

### Kurzfristig (Diese Woche):
1. ✅ Implementiere FontManager vollständig
2. ✅ Implementiere ColorManager vollständig
3. ✅ Migriere WhoFrame Modul
4. ✅ Test: WHO Frame funktioniert

### Mittelfristig (Nächste Woche):
1. ✅ Migriere IgnoreList
2. ✅ Migriere RecentAllies
3. ✅ Migriere MenuSystem
4. ✅ Migriere QuickFilters

### Langfristig (In 2 Wochen):
1. ✅ Migriere FriendsList (größtes Modul)
2. ✅ Cleanup BetterFriendlist.lua
3. ✅ Vollständige Tests
4. ✅ Performance-Profiling

---

## 📝 Success Criteria

**Modularisierung ist erfolgreich wenn:**
1. ✅ Alle bestehenden Features funktionieren identisch
2. ✅ Keine Lua Errors
3. ✅ Performance ist gleich oder besser
4. ✅ Code ist leichter zu navigieren (<1000 Zeilen pro Datei)
5. ✅ Klare API-Grenzen zwischen Modulen
6. ✅ Neue Features (Raid Frame) können einfach hinzugefügt werden
7. ✅ .toc Load Order ist klar und dokumentiert
8. ✅ Tests zeigen keine Regressionen

---

## 🎓 Lessons Learned (To be filled)

*Nach jeder Phase dokumentieren:*
- Was lief gut?
- Was war schwieriger als erwartet?
- Welche Patterns haben funktioniert?
- Was würde ich beim nächsten Mal anders machen?

---

**Status:** 📋 READY FOR IMPLEMENTATION
**Created:** 2025-10-30
**Last Updated:** 2025-10-30
**Version:** 1.0
