# Phase 10.5 Testing Checklist

**Datum:** 9. November 2025  
**Version:** v0.15 (Phase 10.5)  
**Tester:** _________

---

## ✅ Test 1: Debug Print System

### Setup
1. Starte WoW und logge dich ein
2. Öffne Chat-Fenster

### Test Steps

**1.1 Standard-Verhalten (Debug OFF)**
- [ ] Addon lädt → Nur Version Print erscheint: `BetterFriendlist v0.15 loaded successfully!`
- [ ] KEIN weiterer Debug-Spam im Chat
- [ ] Nur EINE Version-Nachricht (nicht 2×)

**1.2 Debug aktivieren**
- [ ] Führe aus: `/bfl print`
- [ ] Erwartung: `BetterFriendlist: Debug printing ENABLED`
- [ ] (Optional: Teste `/bfl` ohne Parameter → Zeigt Help-Text)

**1.3 Nach Reload mit Debug ON**
- [ ] Führe aus: `/reload`
- [ ] Addon lädt → Version Print + möglicherweise Debug-Prints erscheinen
- [ ] Öffne Friends Frame → Wenn Debug-Prints erscheinen = ✅

**1.4 Debug deaktivieren**
- [ ] Führe aus: `/bfl print`
- [ ] Erwartung: `BetterFriendlist: Debug printing DISABLED`
- [ ] Führe aus: `/reload`
- [ ] Kein Debug-Spam mehr = ✅

**1.5 Persistenz prüfen**
- [ ] Debug ON aktivieren: `/bfl print`
- [ ] Logout komplett
- [ ] Login wieder
- [ ] Debug sollte immer noch ENABLED sein (Settings bleiben erhalten)

---

## ✅ Test 2: Keybind Hook (O-Taste)

### Setup
1. Schließe alle UI-Frames
2. Stelle sicher, dass BetterFriendlist NICHT geöffnet ist

### Test Steps

**2.1 Standard Keybind (O-Taste)**
- [ ] Drücke **O** auf Tastatur
- [ ] **BetterFriendsFrame** öffnet sich (nicht Blizzard's FriendsFrame)
- [ ] Drücke **O** nochmal → Frame schließt sich
- [ ] Drücke **O** wieder → Frame öffnet sich erneut

**2.2 Blizzard Frame versteckt**
- [ ] Öffne BetterFriendlist (O-Taste)
- [ ] Prüfe: Blizzard's originaler FriendsFrame ist NICHT sichtbar
- [ ] Nur BetterFriendsFrame ist zu sehen

**2.3 Kein Keybind-Hinweis mehr**
- [ ] Nach Login KEIN Chat-Hinweis über Keybindings
- [ ] Früher: "Please set a keybinding..." → sollte NICHT mehr erscheinen

**2.4 ESC-Taste funktioniert**
- [ ] Öffne BetterFriendlist (O-Taste)
- [ ] Drücke **ESC**
- [ ] Frame schließt sich = ✅

---

## ✅ Test 3: WHO Frame Dropdown

### Setup
1. Öffne BetterFriendlist (O-Taste)
2. Wechsle zum **WHO Tab**

### Test Steps

**3.1 Dropdown Immediate Update**
- [ ] Finde das Dropdown (zeigt "Zone", "Guild" oder "Race")
- [ ] Klicke Dropdown → Wähle "**Guild**"
- [ ] **SOFORT** sollte Dropdown "Guild" anzeigen (nicht "Zone")
- [ ] Klicke nochmal → Wähle "**Race**"
- [ ] **SOFORT** sollte Dropdown "Race" anzeigen
- [ ] Klicke nochmal → Wähle "**Zone**"
- [ ] **SOFORT** sollte Dropdown "Zone" anzeigen

**3.2 Font Color**
- [ ] Prüfe Dropdown-Text: Sollte **WEIß** sein
- [ ] NICHT gelb/gold
- [ ] Vergleiche mit anderen UI-Texten (sollte gleiche Farbe haben)

**3.3 WHO List Update**
- [ ] Wähle "Zone" → Liste zeigt Zone-Spalte
- [ ] Wähle "Guild" → Liste zeigt Guild-Spalte
- [ ] Wähle "Race" → Liste zeigt Race-Spalte
- [ ] Spalte wechselt sofort (kein Delay)

---

## ✅ Test 4: Raid Frame - Assist All Label

### Setup
1. Öffne BetterFriendlist (O-Taste)
2. Wechsle zum **Raid Tab**
3. Erstelle/Join einen Raid (mindestens 2 Spieler)
4. Stelle sicher, dass du Raid Leader bist

### Test Steps

**4.1 Assist All Checkbox Label**
- [ ] Finde die "Everyone is Assistant" Checkbox (oben links im Control Panel)
- [ ] Prüfe: Neben der Checkbox steht **"All {AssistIcon}"**
- [ ] AssistIcon ist die goldene Krone |TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14|t
- [ ] Text ist lesbar und korrekt positioniert (rechts neben Checkbox)

**4.2 Checkbox Functionality**
- [ ] Aktiviere Checkbox → Alle Raid-Mitglieder werden zu Assistants
- [ ] Deaktiviere Checkbox → Nur Leader ist Leader
- [ ] Checkbox ist nur enabled wenn du Raid Leader bist

---

## ✅ Test 5: Raid Frame - Combat Overlay

### Setup
1. Öffne BetterFriendlist → Raid Tab
2. Stelle sicher, dass du in einem Raid bist
3. Bereite einen Kampf vor (z.B. Dummy)

### Test Steps

**5.1 Combat Overlay Erscheint**
- [ ] **BEFORE Combat**: Control Panel ist voll funktional
- [ ] Betrete Combat (attackiere einen Mob/Dummy)
- [ ] **DURING Combat**: Schwarzer Overlay mit 70% Opacity erscheint über Control Panel
- [ ] Text wird angezeigt:
  ```
  {Red X Icon}
  
  Raid controls disabled during combat
  
  Drag & Drop will be available after combat
  ```
- [ ] Text ist gelb/gold und zentriert
- [ ] Overlay blockiert alle Buttons (Ready Check, Convert, etc.)

**5.2 Combat Overlay verschwindet**
- [ ] Verlasse Combat (Mob stirbt / Combat endet)
- [ ] Overlay verschwindet sofort
- [ ] Control Panel ist wieder voll funktional
- [ ] Alle Buttons funktionieren wieder

**5.3 Drag & Drop blockiert**
- [ ] Betrete Combat
- [ ] Versuche Drag & Drop auf Raid Member → **Funktioniert NICHT**
- [ ] Overlay zeigt Warnung
- [ ] Verlasse Combat → Drag & Drop funktioniert wieder

**5.4 Visual Styling**
- [ ] Overlay ist HIGH frameStrata (über allen anderen Elementen)
- [ ] Background: Schwarz, 70% Opacity
- [ ] Icon: Rotes X (ReadyCheck-NotReady)
- [ ] Text: Gelb (#FFD100), gut lesbar
- [ ] Zentriert im Control Panel

---

## ✅ Test 6: Broadcast Dialog

### Setup
1. Öffne BetterFriendlist (O-Taste)
2. Stelle sicher, dass du mit Battle.net eingeloggt bist

### Test Steps

**4.1 Broadcast Dialog öffnen**
- [ ] Klicke auf **Contacts Menu Button** (oben rechts, neben Battle.net Status)
- [ ] Wähle "**Set Broadcast**" (oder ähnlich)
- [ ] Broadcast Dialog öffnet sich = ✅

**4.2 Update Button**
- [ ] Gib Text ein: "Test Broadcast Message 123"
- [ ] Klicke **UPDATE** Button
- [ ] Dialog schließt sich automatisch
- [ ] **KEIN Lua Error** im Chat = ✅
- [ ] Prüfe Battle.net → Broadcast sollte gesetzt sein

**4.3 Enter-Taste**
- [ ] Öffne Broadcast Dialog erneut
- [ ] Gib neuen Text ein: "Test Message 456"
- [ ] Drücke **ENTER** Taste (nicht Button!)
- [ ] Dialog schließt sich automatisch
- [ ] **KEIN Lua Error** = ✅
- [ ] Broadcast sollte aktualisiert sein

**4.4 Cancel Button**
- [ ] Öffne Broadcast Dialog
- [ ] Gib Text ein, aber klicke **CANCEL**
- [ ] Dialog schließt sich
- [ ] Broadcast bleibt unverändert (alter Text) = ✅

**4.5 ESC-Taste**
- [ ] Öffne Broadcast Dialog
- [ ] Drücke **ESC** Taste
- [ ] EditBox verliert Focus, aber Dialog bleibt offen
- [ ] Klicke außerhalb → Dialog schließt sich = ✅

**4.6 Button Styling**
- [ ] Prüfe Update/Cancel Buttons
- [ ] Sollten modernes WoW UI-Design haben
- [ ] Size: ca. 96×22 Pixel (nicht zu klein, nicht zu groß)
- [ ] Sehen aus wie Standard-WoW-Buttons = ✅

---

## 🐛 Bug Testing (Regression)

### Alte Features sollten noch funktionieren

**Friends List**
- [ ] Friends List zeigt korrekt Freunde an
- [ ] Custom Groups funktionieren
- [ ] Drag & Drop zwischen Groups funktioniert

**Raid Frame**
- [ ] Raid Frame zeigt Raid-Mitglieder
- [ ] Drag & Drop zwischen Groups funktioniert
- [ ] Tooltips erscheinen korrekt
- [ ] Context Menu (Rechtsklick) funktioniert

**Quick Join**
- [ ] Quick Join Tab funktioniert
- [ ] Mock-Gruppen können erstellt werden (`/bflqj mock`)

**Ignore List**
- [ ] Ignore List öffnet korrekt

**WHO Frame**
- [ ] WHO Suche funktioniert
- [ ] Whisper Button funktioniert (korrekte Server-Namen)

---

## 📊 Performance Test (Optional)

**Startup Time**
- [ ] Addon lädt ohne merkliche Verzögerung (<1 Sekunde)

**Memory Usage**
- [ ] Führe aus: `/run print(GetAddOnMemoryUsage("BetterFriendlist"))`
- [ ] Sollte <5000 KB sein (idealerweise <3000 KB)

**Frame Opening**
- [ ] Friends Frame öffnet sofort (kein Lag)

---

## ✅ Test Results Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Debug Print System | ⬜ PASS / ⬜ FAIL | ____________ |
| Keybind Hook (O) | ⬜ PASS / ⬜ FAIL | ____________ |
| WHO Dropdown Update | ⬜ PASS / ⬜ FAIL | ____________ |
| WHO Dropdown Font | ⬜ PASS / ⬜ FAIL | ____________ |
| Raid Assist All Label | ⬜ PASS / ⬜ FAIL | ____________ |
| Raid Combat Overlay | ⬜ PASS / ⬜ FAIL | ____________ |
| Combat D&D Blocked | ⬜ PASS / ⬜ FAIL | ____________ |
| Broadcast Update Btn | ⬜ PASS / ⬜ FAIL | ____________ |
| Broadcast Enter Key | ⬜ PASS / ⬜ FAIL | ____________ |
| Broadcast Cancel | ⬜ PASS / ⬜ FAIL | ____________ |
| No Duplicate Version | ⬜ PASS / ⬜ FAIL | ____________ |

---

## 🔥 Known Issues / Found Bugs

_(Hier neue Bugs eintragen, falls gefunden)_

1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

---

## 📝 Tester Notes

_(Hier freie Notizen eintragen)_

___________________________________________
___________________________________________
___________________________________________

---

## ✅ Sign-off

- [ ] Alle kritischen Tests bestanden
- [ ] Keine Lua Errors gefunden
- [ ] Performance akzeptabel
- [ ] Bereit für Commit

**Tester:** _________  
**Datum:** _________  
**Signature:** _________
