# FriendGroups Migration - Debug Guide

## Debug Logs aktiviert!

Die Migration-Funktion wurde mit umfangreichen Debug-Logs ausgestattet, um Probleme bei der Migration zu identifizieren.

## Wie man debuggt

### 1. Migration durchführen
1. Öffne BetterFriendlist Settings (ESC → Interface → AddOns → BetterFriendlist)
2. Gehe zum **Advanced** Tab
3. Klicke auf **"Migrate from FriendGroups"**
4. Wähle eine Option (empfohlen: "Migrate Only" für ersten Test)

### 2. Chat-Log lesen

Die Migration gibt jetzt detaillierte Informationen aus:

#### **Cyan-farbige Debug-Logs** (`|cff00ffff`)
Zeigen den Ablauf der Migration:
```
BetterFriendlist Debug: Starting migration...
BetterFriendlist Debug: DB module: OK
BetterFriendlist Debug: Groups module: OK
BetterFriendlist Debug: Processing 42 BattleNet friends...
```

#### **Grüne Erfolgs-Logs** (`|cff00ff00`)
Zeigen erfolgreiche Operationen:
```
BetterFriendlist Debug: SUCCESS - Assignment count: 1
BetterFriendlist: Successfully migrated 42 friends into 8 groups (156 total assignments).
```

#### **Rote Fehler-Logs** (`|cffff0000`)
Zeigen Probleme:
```
BetterFriendlist Debug: FAILED to create group: TestGroup
BetterFriendlist Debug: ERROR - No groupId for: TestGroup
```

### 3. Wichtige Log-Abschnitte

#### **A. Friend Processing**
Für jeden Freund mit Gruppendaten siehst du:
```
BetterFriendlist Debug: Friend: PlayerName#1234
BetterFriendlist Debug:   BNet ID: 12345678
BetterFriendlist Debug:   UID: bnet_12345678
BetterFriendlist Debug:   Note: Best healer!#Raid Team#Guild
BetterFriendlist Debug:     Parsing note: Best healer!#Raid Team#Guild
BetterFriendlist Debug:     Split into 3 parts
BetterFriendlist Debug:     Found group: Raid Team
BetterFriendlist Debug:     Found group: Guild
BetterFriendlist Debug:     Actual note: Best healer!
BetterFriendlist Debug:     Total groups found: 2
BetterFriendlist Debug:   Parsed groups: Raid Team, Guild
```

#### **B. Group Creation**
Für jede neue Gruppe:
```
BetterFriendlist Debug:   Created group: Raid Team with ID: group_abc123
```

#### **C. Friend Assignment**
Für jede Zuweisung:
```
BetterFriendlist Debug:   Assigning bnet_12345678 to group group_abc123
BetterFriendlist Debug:   SUCCESS - Assignment count: 1
```

#### **D. Database State**
Am Ende der Migration:
```
BetterFriendlist Debug: Checking database state...
BetterFriendlist Debug: BetterFriendlistDB exists
BetterFriendlist Debug:   Group: group_abc123 = Raid Team
BetterFriendlist Debug:   Group: group_def456 = Guild
BetterFriendlist Debug: Total groups in DB: 2
BetterFriendlist Debug:   Friend: bnet_12345678 in 2 groups: group_abc123, group_def456
BetterFriendlist Debug: Total friends in DB: 1
```

### 4. Datenbank überprüfen

Nach der Migration kannst du jederzeit den Befehl verwenden:
```
/bfl debug
```

Dies zeigt:
- **CUSTOM GROUPS**: Alle erstellten Gruppen mit IDs
- **FRIEND ASSIGNMENTS**: Alle Freunde und ihre Gruppenzuordnungen
- **GROUP ORDER**: Reihenfolge der Gruppen

Beispiel-Output:
```
BetterFriendlist Debug: =================================
BetterFriendlist Debug: DATABASE STATE
BetterFriendlist Debug: =================================

BetterFriendlist Debug: CUSTOM GROUPS:
BetterFriendlist Debug:   [group_abc123] = Raid Team
BetterFriendlist Debug:   [group_def456] = Guild Members
BetterFriendlist Debug: Total groups: 2

BetterFriendlist Debug: FRIEND ASSIGNMENTS:
BetterFriendlist Debug:   bnet_12345678 -> [group_abc123, group_def456]
BetterFriendlist Debug:   wow_Thrall -> [group_abc123]
BetterFriendlist Debug: Total friends: 2
BetterFriendlist Debug: Total assignments: 3

BetterFriendlist Debug: GROUP ORDER:
BetterFriendlist Debug: Using default order (nil)
BetterFriendlist Debug: =================================
```

## Häufige Probleme und Lösungen

### Problem 1: "No groups created"
**Symptome:**
```
BetterFriendlist Debug: Total groups in DB: 0
```

**Mögliche Ursachen:**
- Keine Friends haben Gruppen in ihren Notizen
- Notizen haben falsches Format (kein `#` Zeichen)
- Nur `[Favorites]` oder `[No Group]` in Notizen (werden übersprungen)

**Lösung:**
- Prüfe eine Notiz manuell: `/dump C_BattleNet.GetFriendAccountInfo(1).note`
- Format sollte sein: `Text#Gruppe1#Gruppe2`

### Problem 2: "Groups created but no assignments"
**Symptome:**
```
BetterFriendlist Debug: Total groups in DB: 5
BetterFriendlist Debug: Total friends in DB: 0
```

**Mögliche Ursachen:**
- UID-Generierung fehlgeschlagen
- `DB:AddFriendToGroup()` gibt `false` zurück

**Lösung:**
- Suche nach roten Fehlermeldungen im Chat
- Prüfe ob "FAILED" bei Assignments erscheint
- Notiere die exakte Fehlermeldung

### Problem 3: "Groups in DB but not visible in UI"
**Symptome:**
- Debug zeigt Gruppen und Zuordnungen
- Friend List zeigt keine Gruppen

**Mögliche Ursachen:**
- Display-Update fehlgeschlagen
- UID-Format passt nicht zu Runtime-Format

**Lösung:**
```
/reload
/bfl debug
```
- Prüfe ob nach Reload die Daten noch da sind
- Vergleiche UIDs im Debug mit aktuellen Friends

### Problem 4: "Parse findet keine Gruppen"
**Symptome:**
```
BetterFriendlist Debug:     Total groups found: 0
```

**Mögliche Ursachen:**
- Notiz hat kein `#` Zeichen
- Nur Leerzeichen nach `#`
- Andere Delimiter verwendet

**Lösung:**
- Prüfe Notiz-Format manuell
- FriendGroups verwendet `#` als Delimiter

## Test-Szenarien

### Minimaler Test
1. Erstelle einen Test-Friend (oder wähle einen bestehenden)
2. Setze Notiz auf: `Test#TestGroup`
3. Führe Migration durch
4. Prüfe Logs auf "Created group: TestGroup"
5. Prüfe mit `/bfl debug` ob Gruppe und Assignment existieren

### Export der Logs
1. Installiere ein Chat-Copy-Addon (z.B. Prat, WIM)
2. Oder mache Screenshots vom Chat
3. Sende Logs an: https://github.com/Hayato2846/BetterFriendlist/issues

## Weitere Befehle

```lua
-- Zeige ersten Friend mit Notiz
/dump C_BattleNet.GetFriendAccountInfo(1)

-- Zeige alle Gruppen
/dump BetterFriendlistDB.customGroups

-- Zeige alle Friend-Zuordnungen
/dump BetterFriendlistDB.friendGroups

-- Zeige einen spezifischen Friend
/dump BetterFriendlistDB.friendGroups["bnet_12345678"]
```

## Support

Wenn die Migration nicht funktioniert:
1. Führe `/bfl debug` aus und mache Screenshot
2. Kopiere alle Cyan/Grün/Roten Meldungen aus dem Chat
3. Öffne ein Issue auf GitHub mit den Logs
4. Gib an: Anzahl Friends, Anzahl mit Gruppen, Beispiel-Notiz

---

*Erstellt: 2025-10-28*
