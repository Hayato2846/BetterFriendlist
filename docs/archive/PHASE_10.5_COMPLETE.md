# Phase 10.5 Complete: Misc Changes & Bug Fixes

**Status:** ⚠️ Teilweise Abgeschlossen  
**Version:** 0.15  
**Datum:** 9. November 2025

---

## 📋 Übersicht

Phase 10.5 war ein kurzer Bugfix- und Polish-Sprint mit 2 kleineren Feature-Requests:

1. ✅ **Raid UI Dynamic Visibility** - ABGESCHLOSSEN
2. ❌ **Main Tank/Assist Menu Options** - TECHNISCH UNMÖGLICH

---

## ✅ Implementierte Features

### 1. Raid UI Dynamic Visibility

**Problem:**  
Raid Frame zeigte sich auch in Parties (5-man Gruppen), obwohl es nur für Raids (>5 Spieler) gedacht ist.

**Lösung:**
- `BetterFriendlist.xml`: `GROUP_ROSTER_UPDATE` Event zu RaidFrame `OnLoad` hinzugefügt
- `Modules/RaidFrame.lua`: `BetterRaidFrame_Update()` prüft `IsInRaid()` und zeigt/versteckt UI entsprechend
- "You are not in a raid" Placeholder-Text wenn in Party

**Code-Änderungen:**
```xml
<!-- BetterFriendlist.xml Line ~594 -->
<Frame name="BetterRaidFrame" parent="BetterFriendsFrame" hidden="true">
    <Scripts>
        <OnLoad>
            BetterRaidFrame_OnLoad(self)
            self:RegisterEvent("GROUP_ROSTER_UPDATE")  <!-- NEU -->
        </OnLoad>
```

```lua
-- Modules/RaidFrame.lua
function RaidFrame:Update()
    if not IsInRaid() then
        -- Hide all UI, show "Not in Raid" message
        -- ...
    else
        -- Show raid UI
        -- ...
    end
end
```

**Test-Ergebnis:** ✅ Funktioniert perfekt - User bestätigt

---

## ❌ Nicht Implementierbare Features

### 2. Main Tank/Assist Right-Click Menu Options

**Anfrage:**  
"Im Rechtsklick-Menü kann ich zwar Raidlead und Assistant bestimmen aber nicht Main Tank und auch nicht Main Assistant"

**Problem:**  
`SetPartyAssignment()` und `ClearPartyAssignment()` sind **geschützte Funktionen** (`protected functions`) in der WoW API.

**Technische Einschränkungen:**

1. **issecure() Requirement:**
   ```lua
   -- Blizzard Code (UnitPopupSharedButtonMixins.lua:1929)
   local function CanSetRaidRole(contextData, role)
       if not issecure() then  -- ⚠️ CRITICAL CHECK
           return false
       end
       -- ...
   end
   ```

2. **Addon-Code ist NIEMALS secure:**
   - Alle Addon-Aufrufe laufen im "tainted" Kontext
   - `issecure()` gibt immer `false` zurück für Addon-Code
   - Nur Blizzards eigener UI-Code läuft in sicherem Kontext

3. **Protected Function Restrictions:**
   ```lua
   SetPartyAssignment(role, unit)   -- #protected (seit Patch 4.0.1)
   ClearPartyAssignment(role, unit) -- #protected (seit Patch 4.0.1)
   ```

4. **Combat Taint:**
   - Im Kampf sind diese Funktionen **komplett gesperrt**
   - `ADDON_ACTION_FORBIDDEN` Error beim Aufruf
   - Keine Umgehung möglich (Anti-Exploit-System)

**Versuchte Lösungen (alle gescheitert):**

1. ❌ **Attempt 1:** `UnitPopup_OpenMenu("RAID_PLAYER")` + Menu Hook
   - Fehler: `CheckInteractDistance()` im Kampf nicht erlaubt
   
2. ❌ **Attempt 2:** SecureActionButton mit type2="menu"
   - User-Ablehnung: "Bitte nutze sowas NIEMALS WIEDER!" (Taint-Propagation)
   
3. ❌ **Attempt 3:** Control Panel Buttons (Set MT/Set MA)
   - User-Ablehnung: "Ich finde deinen Ansatz nicht gut"
   
4. ❌ **Attempt 4:** `Menu.ModifyMenu("MENU_UNIT_RAID")` Hook
   - Menü-Items werden korrekt hinzugefügt
   - Fehler beim Klick: `ADDON_ACTION_FORBIDDEN` - `SetPartyAssignment()` nicht erlaubt

**Finale Implementierung:**
```lua
-- Modules/MenuSystem.lua - ENTFERNT
-- Menu.ModifyMenu("MENU_UNIT_RAID", function(owner, rootDescription, contextData)
--     -- Diese Buttons können nicht funktionieren wegen Protected Functions
-- end)
```

**Workarounds für User:**
1. Nutze Blizzards Standard Raid-Frames für Main Tank/Assist
2. Verwende Slash-Commands: `/maintank <name>` und `/mainassist <name>`
3. Nutze andere Raid-Frame-Addons (die haben das gleiche Problem!)

---

## 📊 Code-Änderungen Zusammenfassung

**Dateien geändert:**
1. `BetterFriendlist.xml` - GROUP_ROSTER_UPDATE Event hinzugefügt
2. `Modules/RaidFrame.lua` - IsInRaid() Check in Update()
3. `Modules/MenuSystem.lua` - Main Tank/Assist Code entfernt (war temporär drin)
4. `UI/RaidFrameCallbacks.lua` - Rechtsklick öffnet nur Standard-Menü

**Netto-Code-Änderung:** +15 Zeilen (nur Raid Visibility Feature)

---

## 🧪 Testing

**Getestet:**
- ✅ Party (5 Spieler) → "Not in Raid" Placeholder angezeigt
- ✅ Raid (6+ Spieler) → Raid UI sichtbar
- ✅ Party → Raid Konvertierung → UI erscheint dynamisch
- ✅ Raid → Party Konvertierung → UI verschwindet dynamisch
- ✅ Rechtsklick auf Raid Member → Standard-Menü (ohne Main Tank/Assist)
- ❌ Main Tank/Assist Buttons → Nicht implementierbar (Protected Functions)

**Bugs gefunden & behoben:**
- Keine (außer dass Main Tank/Assist nicht funktioniert - aber das ist eine API-Einschränkung, kein Bug)

---

## 📖 Lessons Learned

1. **Protected Functions sind ein No-Go für Addons:**
   - Immer zuerst WoW API Docs prüfen ob Funktion `#protected` ist
   - `issecure()` Check in Blizzard Code ist ein Red Flag

2. **Combat Restrictions:**
   - Viele Raid-Management-Funktionen sind im Kampf gesperrt
   - Kein Workaround möglich (absichtliches Anti-Exploit-Design)

3. **SecureActionButtons sind gefährlich:**
   - Können Taint in Parent-Frames propagieren
   - Nur für Protected Functions verwenden wenn absolut nötig
   - Besser: User auf Blizzard UI verweisen

4. **User-Kommunikation:**
   - Wichtig zu erklären WARUM etwas nicht geht
   - Technische Einschränkungen sind keine Bugs
   - Alternative Workarounds anbieten

---

## 🎯 Nächste Schritte

**Phase 10.5 ist abgeschlossen** (soweit möglich).

**Nächste Priorität:**
- **Phase 10**: Final Integration & Testing
- Version Bump: 0.15 → 1.0 (wenn Phase 10 komplett)

---

## 📝 Notizen

**Main Tank/Assist Feature Request:**  
Dieses Feature kann **niemals** implementiert werden, solange Blizzard die API-Einschränkungen beibehält. Es ist ein fundamentales Problem mit der WoW Protected Function API.

**Alternative für User:**
- Blizzard's Standard Raid-Frames verwenden
- `/maintank` und `/mainassist` Slash-Commands
- Andere Raid-Management-Addons (die haben alle das gleiche Problem!)

---

**Abschlussstatus:**  
Phase 10.5 = ✅ 50% Erfolg (1 von 2 Features implementiert)  
Der nicht-implementierte Teil ist eine API-Einschränkung, kein Fehler unsererseits.
